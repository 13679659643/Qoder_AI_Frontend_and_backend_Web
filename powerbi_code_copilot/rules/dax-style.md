---
alwaysApply: true
---

# DAX 编码规范

## 1. 命名约定

### 度量值（Measures）
- 使用清晰的业务语义命名，英文优先
- 前缀/后缀规范：

| 前缀/后缀 | 用途 | 示例 |
|-----------|------|------|
| **无前缀** | 基础聚合度量值 | `Total Sales`, `Order Count`, `Average Price` |
| **KPI_** | 关键绩效指标 | `KPI_SalesGrowth`, `KPI_ProfitMargin` |
| **CAL_** | 复杂计算指标 | `CAL_SalesPerCustomer`, `CAL_AOV` |
| **RATIO_** | 比率指标 | `RATIO_ConversionRate`, `RATIO_Margin` |
| **YTD_** | 本年至今 | `YTD_Sales`, `YTD_Revenue` |
| **MTD_** | 本月至今 | `MTD_Sales`, `MTD_Profit` |
| **PY_** | 去年同期 | `PY_Sales`, `PY_Orders` |
| **% 结尾** | 百分比/比率 | `Profit Margin %`, `YoY Growth %` |
| **Rank 结尾** | 排名 | `Sales Rank`, `Customer Rank` |
| **_ 前缀** | 辅助/内部度量值（隐藏） | `_Base Revenue`, `_Helper Count` |
| **_ Cell Display | 构建中国式报表的时候，行列需要自定义的情况，值返回格式化后的度量，度量命名需要带有矩阵名称 | `KPI Breakdown Cell Display` |

- 禁止使用拼音或中英混拼
- 避免与列名冲突（度量值名称不应与模型中任何列名相同）

### 计算列（Calculated Columns）
- 以 `CC_` 前缀标识（可选，团队约定）
- 命名体现其业务含义

### 表命名规范（Table Naming）

基于 Kimball 维度建模方法论，所有表使用前缀标识其类型：

| 前缀 | 含义 | 示例 | 说明 |
|------|------|------|------|
| **Dim_**_** | 构建行列辅助表 | `Dim_RowKPI_KpiBreakdown`, `Dim_ColMetric_KpiBreakdown` | 构建中国式报表的时候，行列需要自定义的情况，表命名需要带有矩阵名称，不然无法和其他矩阵区分 |
| **Dim_** | 维度表 | `Dim_Date`, `Dim_Customer`, `Dim_Store` | 描述性数据，用于筛选和分组 |
| **Fact_** | 事实表 | `Fact_Sales`, `Fact_Orders` | 度量数据，包含可聚合的数值 |
| **Bridge_** | 桥接表 | `Bridge_SalesTerritory` | 解决多对多关系 |
| **Param_** | 参数表 | `Param_TimeFrame`, `Param_TopN` | 用户选择参数，用于动态计算 |
| **CT_** | 计算表 | `CT_DateRange`, `CT_Scaffold` | DAX DATATABLE/CROSSJOIN 生成的辅助表 |
| **_** | 隐藏辅助表 | `_Measures`, `_Parameters` | 不直接面向用户的内部表 |

表命名原则：
- 使用单数名词（`Dim_Customer` 而非 `Dim_Customers`）
- 禁止使用空格和特殊字符
- 避免使用 DAX 保留字作为表名（如 `Date`、`Value`、`Name` 需加前缀 → `Dim_Date`）

### 列命名规范（Column Naming）

#### 主键与外键
```dax
// 维度表主键 — 使用 Key 或 ID 后缀
Dim_Customer[CustomerKey]        // 代理键（推荐）
Dim_Customer[CustomerID]         // 业务键

// 事实表外键 — 与关联维度表主键同名
Fact_Sales[CustomerKey]          // 关联到 Dim_Customer[CustomerKey]
Fact_Sales[DateKey]              // 关联到 Dim_Date[DateKey]
```

#### 属性列
```dax
// 使用 PascalCase，见名知意
Dim_Product[ProductName]         // 名称
Dim_Product[ProductCategory]     // 类别
Dim_Date[MonthName]              // 月份名称
Dim_Date[IsWeekend]              // 布尔标识用 Is/Has 前缀
Dim_Order[IsActive]              // 是否激活
```

#### 计算列
- 可选添加 `Calc_` 前缀区分（团队约定）
- 命名体现其业务含义

### 变量（VAR）
- 使用 `__` 前缀（双下划线）或清晰的描述性命名
- 示例：`__TotalSales`, `__FilteredTable`, `__CurrentDate`
| 列上下文变量 | `__SelR1`, `__SelR2` | 一级/二级列头 |
| 行上下文变量 | `__Brand`, `__Framework`, `__Category` | 行筛选用变量 |
| 特殊标识变量 | `__IsTotal` | Total 行判断 |

## 2. 格式规范

### 缩进与换行
```dax
// 推荐格式
Revenue YTD = 
    VAR __CurrentDate = MAX('Date'[Date])
    VAR __YTDFilter = 
        FILTER(
            ALL('Date'),
            'Date'[Date] <= __CurrentDate
                && 'Date'[Year] = YEAR(__CurrentDate)
        )
    RETURN
        CALCULATE(
            [Total Revenue],
            __YTDFilter
        )
```

- 每个 VAR 独占一行
- RETURN 与 VAR 同级缩进
- 嵌套函数每层缩进 4 个空格
- 长参数列表每个参数独占一行
- 逻辑运算符（&&, ||）放在行首

### 注释
- 复杂度量值（超过 5 行）必须添加头部注释
特别重要：头部注释放在度量值名称之下
- 注释格式：
```dax

Cell Display = 
// ========================================
// 度量值: Cell Display
// 用途: 根据 KPI 格式类型，返回格式化后的文本
// 依赖: [Cell Value], Dim_KPI[KPI_Format]
// ========================================
    VAR __Value = [Cell Value]
    VAR __Format = SELECTEDVALUE(Dim_KPI[KPI_Format])
    RETURN
        SWITCH(
            __Format,
            "currency",   FORMAT(__Value, "$#,##0") & "k",                           // 货币：$250k
            "percent",    FORMAT(__Value, "#,##0") & "%",                             // 百分比：40%
            "delta_pct",  IF(__Value >= 0, "+", "") & FORMAT(__Value, "#,##0") & "%", // 增减：+14%
            "number",     FORMAT(__Value, "#,##0") & "k",                             // 数值：114k
            FORMAT(__Value, "#,##0")                                                  // 默认
        )
```
DAX本身也需要有必要的注释信息，如：
```dax
"Store_ID", STRING,           // 主键标识，用于唯一标识每个店铺选项
MaxValue < 0, FORMAT(BasePoints, "0") & "bp",  // 负数自带负号
```

## 3. DAX 编写原则

### 性能优先
- 优先使用 VAR 避免重复计算
- 避免嵌套 CALCULATE（超过 2 层需重构）
- 优先使用 REMOVEFILTERS 替代 FILTER(ALL(...))
- 迭代函数（SUMX, AVERAGEX 等）注意迭代表的大小
- 避免在度量值中使用 IF + 大型表迭代

### 上下文清晰
- 明确区分行上下文和筛选器上下文
- CALCULATE 的每个筛选参数必须有明确意图
- 避免不必要的上下文转换
- 使用 SELECTEDVALUE 替代 VALUES（当期望单值时）

### 可维护性
- 复杂计算分解为多个度量值（基础 → 中间 → 最终）
- 使用 Display Folder 组织度量值
- 每个度量值单一职责

## 4. 禁止事项

- ❌ 禁止使用隐式度量值（直接拖字段到视觉对象值区域）
- ❌ 禁止在度量值中硬编码日期或业务参数
- ❌ 禁止使用 EARLIER（用 VAR 替代）
- ❌ 禁止未经验证的 CALCULATE 嵌套
- ❌ 禁止在计算列中引用度量值

## 5. 命名检查清单

### 表命名
- [ ] 使用前缀标识表类型（Dim_、Fact_、Bridge_、Param_、CT_）
- [ ] 表名清晰描述内容，使用单数名词
- [ ] 避免使用空格、特殊字符和 DAX 保留字

### 列命名
- [ ] 主键使用 Key 或 ID 后缀
- [ ] 外键与关联维度表主键同名
- [ ] 布尔列使用 Is/Has 前缀（`IsActive`, `HasDiscount`）
- [ ] 使用 PascalCase，列名见名知意

### 度量值命名
- [ ] 度量值名称准确反映计算内容
- [ ] 复杂度量值使用类型前缀（KPI_、CAL_、RATIO_）
- [ ] 时间智能度量值标识时间范围（YTD_、MTD_、PY_）
- [ ] 避免与列名冲突

### 整体一致性
- [ ] 全项目使用相同的命名风格（PascalCase 或 snake_case，不混用）
- [ ] 命名规范已文档化并团队共享

## 6. 常见命名错误

```dax
// ❌ 错误：使用 DAX 保留字
Date = ...         // Date 是 DAX 函数
Value = ...        // Value 是 DAX 函数
// ✅ 正确：添加前缀
Dim_Date = ...
SalesValue = ...

// ❌ 错误：模糊命名
Data = ...
Calc1 = ...
// ✅ 正确：描述性命名
Customer_Demographics = ...
Revenue_Growth = ...

// ❌ 错误：大小写风格不一致
totalSales = ...
Total_Sales = ...
TOTAL_SALES = ...
// ✅ 正确：统一 PascalCase
TotalSales = ...
```
