# Power Query (M) 常用模式库

> 经过验证的高质量 Power Query 模式，可直接复用。每个模式包含：场景、代码、解释、查询折叠说明。

## 1. 参数化数据源连接

### 场景
通过参数控制数据源连接，方便在开发/测试/生产环境间切换。

### 代码
```m
// 参数定义
// ServerName = "prod-sql-server.database.windows.net"
// DatabaseName = "SalesDB"

let
    Source = Sql.Database(ServerName, DatabaseName),
    Sales_Table = Source{[Schema="dbo", Item="Sales"]}[Data]
in
    Sales_Table
```

### 查询折叠说明
✅ 参数化不影响查询折叠，SQL 语句会在数据源端执行。

---

## 2. 增量加载模式

### 场景
只加载新增或变更的数据，避免全量刷新。

### 代码
```m
let
    // RangeStart 和 RangeEnd 是增量刷新参数（由 Power BI 自动管理）
    Source = Sql.Database(ServerName, DatabaseName),
    Sales = Source{[Schema="dbo", Item="Sales"]}[Data],
    // 增量筛选 — 必须在源端折叠
    Filtered = Table.SelectRows(Sales, each 
        [OrderDate] >= RangeStart and [OrderDate] < RangeEnd
    )
in
    Filtered
```

### 关键要求
- `RangeStart` 和 `RangeEnd` 必须是 DateTime 类型的参数
- 筛选条件必须使用 `>=` 和 `<` 组合
- 筛选步骤必须支持查询折叠（使用原生查询或可折叠的数据源）

### 查询折叠说明
✅ 必须确保筛选条件被折叠到数据源端，否则增量刷新无效。

---

## 3. 自定义日期维度表

### 场景
创建标准的日期维度表，包含完整的日期层级和属性。

### 代码
```m
let
    StartDate = #date(2020, 1, 1),
    EndDate = #date(2030, 12, 31),
    DateCount = Duration.Days(EndDate - StartDate) + 1,
    DateList = List.Dates(StartDate, DateCount, #duration(1, 0, 0, 0)),
    ToTable = Table.FromList(DateList, Splitter.SplitByNothing(), {"Date"}, null, ExtraValues.Error),
    ChangedType = Table.TransformColumnTypes(ToTable, {{"Date", type date}}),
    
    // 添加日期属性
    AddYear = Table.AddColumn(ChangedType, "Year", each Date.Year([Date]), Int64.Type),
    AddQuarter = Table.AddColumn(AddYear, "Quarter", each Date.QuarterOfYear([Date]), Int64.Type),
    AddMonth = Table.AddColumn(AddQuarter, "MonthNumber", each Date.Month([Date]), Int64.Type),
    AddMonthName = Table.AddColumn(AddMonth, "MonthName", each Date.MonthName([Date]), type text),
    AddMonthShort = Table.AddColumn(AddMonthName, "MonthShort", each Text.Start(Date.MonthName([Date]), 3), type text),
    AddWeekOfYear = Table.AddColumn(AddMonthShort, "WeekOfYear", each Date.WeekOfYear([Date]), Int64.Type),
    AddDayOfWeek = Table.AddColumn(AddWeekOfYear, "DayOfWeek", each Date.DayOfWeek([Date], Day.Monday) + 1, Int64.Type),
    AddDayName = Table.AddColumn(AddDayOfWeek, "DayName", each Date.DayOfWeekName([Date]), type text),
    AddIsWeekend = Table.AddColumn(AddDayName, "IsWeekend", each Date.DayOfWeek([Date], Day.Monday) >= 5, type logical),
    
    // 添加排序和显示列
    AddYearMonth = Table.AddColumn(AddIsWeekend, "YearMonth", each [Year] * 100 + [MonthNumber], Int64.Type),
    AddYearQuarter = Table.AddColumn(AddYearMonth, "YearQuarter", each Text.From([Year]) & "Q" & Text.From([Quarter]), type text),
    AddQuarterLabel = Table.AddColumn(AddYearQuarter, "QuarterLabel", each "Q" & Text.From([Quarter]), type text)
in
    AddQuarterLabel
```

### 查询折叠说明
❌ 计算表不支持查询折叠，但日期维度表通常体积很小，无性能影响。

---

## 4. 动态列透视/逆透视

### 场景
处理列数不固定的数据源（如月份列动态增长）。

### 代码
```m
// 动态逆透视：将所有非固定列逆透视为行
let
    Source = Excel.Workbook(File.Contents(FilePath), null, true),
    Sheet = Source{[Item="Sheet1", Kind="Sheet"]}[Data],
    PromotedHeaders = Table.PromoteHeaders(Sheet, [PromoteAllScalars=true]),
    
    // 定义固定列（不参与逆透视的列）
    FixedColumns = {"Product", "Category", "Region"},
    
    // 动态获取所有其他列并逆透视
    AllColumns = Table.ColumnNames(PromotedHeaders),
    DynamicColumns = List.Difference(AllColumns, FixedColumns),
    Unpivoted = Table.UnpivotOtherColumns(PromotedHeaders, FixedColumns, "Period", "Value")
in
    Unpivoted
```

### 查询折叠说明
⚠️ UnpivotOtherColumns 通常会阻断查询折叠，建议在此步骤之前完成所有可折叠的筛选和转换。

---

## 5. 错误处理与数据质量检查

### 场景
在数据加载过程中捕获和处理错误，确保数据质量。

### 代码
```m
// 安全的类型转换（避免因脏数据导致刷新失败）
let
    Source = ...,
    SafeConvert = Table.TransformColumns(Source, {
        {"Amount", each try Number.From(_) otherwise null, type nullable number},
        {"OrderDate", each try Date.From(_) otherwise null, type nullable date}
    }),
    
    // 移除转换失败的行（或标记为异常）
    RemoveErrors = Table.RemoveRowsWithErrors(SafeConvert),
    
    // 数据质量检查 — 添加验证标记
    AddValidation = Table.AddColumn(RemoveErrors, "IsValid", each 
        [Amount] <> null and [Amount] > 0 and [OrderDate] <> null, 
        type logical
    )
in
    AddValidation
```

### 查询折叠说明
❌ try...otherwise 和自定义函数会阻断查询折叠。建议尽量在数据源端处理数据质量。

---

## 6. 文件夹批量导入

### 场景
从文件夹中批量导入多个同结构的文件（CSV/Excel）。

### 代码
```m
let
    Source = Folder.Files(FolderPath),
    FilteredFiles = Table.SelectRows(Source, each Text.EndsWith([Name], ".csv")),
    
    // 定义文件解析函数
    ParseFile = (fileContent as binary) as table =>
        let
            Content = Csv.Document(fileContent, [Delimiter=",", Encoding=65001]),
            Headers = Table.PromoteHeaders(Content, [PromoteAllScalars=true])
        in
            Headers,
    
    // 批量解析并合并
    AddContent = Table.AddColumn(FilteredFiles, "ParsedData", each ParseFile([Content])),
    Expanded = Table.ExpandTableColumn(AddContent, "ParsedData", 
        Table.ColumnNames(AddContent{0}[ParsedData])),
    
    // 清理辅助列
    RemovedColumns = Table.RemoveColumns(Expanded, {"Content", "Name", "Extension", "Date accessed", "Date modified", "Date created", "Attributes", "Folder Path"})
in
    RemovedColumns
```

### 查询折叠说明
❌ 文件夹查询不支持查询折叠，但可以通过筛选文件名/日期减少处理的文件数量。
