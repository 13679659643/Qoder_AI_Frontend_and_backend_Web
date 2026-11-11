# 动态行维度、动态指标与联动排序 Demo 解决方案

## 1. 目标与实现范围

在 Power BI Desktop 中使用原生**表格**和四个切片器，实现以下交互，不依赖数据库、Excel、自定义视觉对象或外部服务。

| 控件          | 作用                                         | Demo 选项                             | 选择方式 |
| ------------- | -------------------------------------------- | ------------------------------------- | -------- |
| A：展示行维度 | 改变表格按什么字段分组，而不是筛选某几个成员 | 门店、区域、店铺类型                  | 单选     |
| B：展示指标   | 改变表格展示哪些业务指标列                   | 净销售额、总销售额、净销售额/总销售额 | 多选     |
| C：排序指标   | 决定按哪个业务指标排列当前行                 | 候选受 B 限制                         | 单选     |
| D：排序方向   | 决定业务指标升序或降序                       | 升序、降序                            | 单选     |

例如：A 选“门店”，B 选“净销售额、总销售额”，C 选“总销售额”，D 选“降序”，表格按门店汇总，只展示这两个业务指标，并按总销售额从高到低排列。

### 1.1 Demo 业务口径

- 净销售额：示例事实表 `Net_Sales_Amount` 求和；含一笔负数调整，用于展示净额汇总。
- 总销售额：示例事实表 `Gross_Sales_Amount` 求和。
- 比值：**当前分组净销售额合计 ÷ 当前分组总销售额合计**，不是逐笔或逐门店比值的平均数。
- 金额单位：人民币元，显示两位小数；比值显示一位小数百分比。
- 分母为 0 时比值返回 `BLANK()`，不伪造为 0%。净额为 0、分母非零时返回真实的 0%。
- 同值按当前分组包含的最小 `Store_ID` 升序决胜；该规则对升序、降序一致。
- 排序指标为空的行始终放在末尾。零值行保留，不沿用其他业务模块的零值隐藏规则。
- A 只选择一个行维度，不在本 Demo 中实现多层级展开、各父组内独立排序或行成员多选。

### 1.2 两个必须说明的原生限制

**限制一：DAX 不能直接修改视觉对象的“按哪一列排序、升序还是降序”设置。**

解决方式是在表格里保留一列辅助的“排序序号”，视觉对象始终按它升序。C、D 改变的是序号的计算结果，因此表格的业务行顺序随之改变。这不是新增业务指标，B 中仍然只有三个指标。

不要把辅助列从表格字段区域移除，也不要依赖把宽度缩成 0 的隐藏技巧。用户点击其他业务列头会覆盖视觉排序，此时需重新按“排序序号”升序。

**限制二：筛选 C 的候选项，不等于清除或改写 C 已保存的选择。**

当 B 取消 C 当前选中的指标时，原生切片器可能保留旧选择；部分切片器版本还可能保留显示旧选项。即使开启按钮切片器的 Force selection，也不会自动选中第一个可见项。

本方案采用两层控制：

1. C 视觉筛选度量限制可用候选；正常交互下只能从 B 已选指标中选择。
2. 每次计算实际排序指标时，再验证 C 选择是否属于 B。不属于时，按 B 当前可用指标的固定顺序选择第一个，并通过状态卡说明。

**保证的是：实际用于排序的指标始终来自 B。不能承诺：B 一变化，C 的勾选标记也自动同步为回退项。** 若要求 C 的勾选状态必须强制实时同步，单靠此原生方案不能完整保证，需另外开发能够控制选择状态的自定义交互。

本文件是独立 Demo 的搭建方案，不修改现有业务报表；不包含已经运行的 PBIX。末尾区分了脚本核验与待 Desktop 实测事项。

## 2. 最终页面与架构

推荐使用表格而不是矩阵：本需求只有一个动态分组维度，表格更容易固定辅助排序列，同时保留各指标的原生数值格式。

```text
[A 展示行维度]  [B 展示指标，多选]  [C 排序指标]  [D 排序方向]

[状态卡：当前按“净销售额”降序；同值按分组最小门店 ID 升序]

排序序号 | 门店  | 净销售额 | 总销售额
1        | 门店A |   900.00 | 1,200.00
2        | 门店C |   900.00 | 1,500.00
3        | 门店B |   800.00 | 1,000.00
4        | 门店D |   500.00 |   800.00
5        | 门店E |     0.00 |   200.00
6        | 门店F |     0.00 |     0.00
```

共 6 张表、11 个度量、6 个视觉对象：

| 对象                             | 用途                             | 是否关联事实表 |
| -------------------------------- | -------------------------------- | -------------- |
| `Dim_Demo_Store`               | 门店属性，提供三个可切换的行维度 | 是             |
| `Fact_Demo_Sales`              | 12 条虚构明细记录                | 事实表         |
| `O：Param_Demo_Row`            | A 的行字段参数                   | 否             |
| `O：Param_Demo_Metric`         | B 的度量字段参数                 | 否             |
| `O：Slicer_Demo_SortMetric`    | C 的排序指标选项                 | 否             |
| `O：Slicer_Demo_SortDirection` | D 的排序方向选项                 | 否             |

数据关系只有一条：

```text
Dim_Demo_Store[Store_ID]  1 ────── *  Fact_Demo_Sales[Store_ID]
                           单向
```

四张控制表均断开关系，不在 B 与 C 之间建立双向关系。B 对 C 的限制由度量和视觉交互实现，C 不反向缩小 B 的展示指标集合。

## 3. 创建小型示例数据源

新建空白 Power BI 文件，依次在“建模 → 新建表”中创建以下两张计算表。数据是虚构的静态 Demo 数据，不需要数据源凭据或网关。

### 3.1 门店维度：6 行

```dax
Dim_Demo_Store =
    DATATABLE(
        "Store_ID", INTEGER,
        "Store_Name", STRING,
        "Region", STRING,
        "Store_Type", STRING,
        {
            { 10, "门店A", "华东", "直营店" },
            { 20, "门店B", "华东", "加盟店" },
            { 30, "门店C", "华南", "直营店" },
            { 40, "门店D", "华南", "加盟店" },
            { 50, "门店E", "华北", "直营店" },
            { 60, "门店F", "华北", "加盟店" }
        }
    )
```

`Store_ID` 全局唯一，`Store_Name` 在此 Demo 中也唯一。每家门店只属于一个区域、一种店铺类型，因此任意分组的最小门店 ID 可以作为稳定的同值决胜键。

**不要给 `Store_Name`、`Region`、`Store_Type` 另外设置“按列排序”辅助列。** 后面的排名关系只枚举当前分组字段；额外隐藏排序列可能残留当前行筛选，影响候选集。本方案的行顺序统一交给排序序号度量。

### 3.2 销售事实表：12 行

每行是一条销售或调整记录。数据是一个整体样本，不包含时间分析需求，因此不添加日期字段和日期表。

```dax
Fact_Demo_Sales =
    DATATABLE(
        "Record_ID", INTEGER,
        "Store_ID", INTEGER,
        "Net_Sales_Amount", CURRENCY,
        "Gross_Sales_Amount", CURRENCY,
        {
            { 101, 10,  500, 700 },
            { 102, 10,  400, 500 },
            { 103, 20,  600, 700 },
            { 104, 20,  200, 300 },
            { 105, 30,  450, 700 },
            { 106, 30,  450, 800 },
            { 107, 40,  250, 400 },
            { 108, 40,  250, 400 },
            { 109, 50,  100, 150 },
            { 110, 50, -100,  50 },
            { 111, 60,    0,   0 },
            { 112, 60,    0,   0 }
        }
    )
```

数据特意包含：

- 门店 A、C 的净销售额相同，但总销售额不同，用于验证切换排序指标和同值决胜。
- 门店 E 的净销售额为 0，总销售额非零，用于验证真实 0% 的位置。
- 门店 F 两项金额均为 0，比值为空，用于验证空值在升序、降序时都置后。
- 多个门店共享区域、店铺类型，用于验证 A 切换后的重新分组汇总。

### 3.3 模型设置

1. 在模型视图创建 `Dim_Demo_Store[Store_ID]` 到 `Fact_Demo_Sales[Store_ID]` 的活动关系。
2. 基数选一对多，交叉筛选方向选单向，从维度到事实表。
3. 若自动检测已经建立该关系，不要再建第二条。
4. `Record_ID`、`Store_ID` 为整数，金额列为固定小数类型。
5. ID 字段设为“不汇总”；金额通过下面的显式度量使用，不直接拖入视觉对象。

## 4. 创建三个基础业务指标

以下度量全部创建在 `Fact_Demo_Sales` 表中，后续字段参数通过这个归属表引用它们。每个 DAX 代码块分别通过“新建度量值”创建，不能把多个定义一次性粘贴到一个度量中。

```dax
Demo Net Sales =
    SUM(Fact_Demo_Sales[Net_Sales_Amount])
```

```dax
Demo Gross Sales =
    SUM(Fact_Demo_Sales[Gross_Sales_Amount])
```

```dax
Demo Net Gross Ratio =
    DIVIDE([Demo Net Sales], [Demo Gross Sales])
```

| 度量                     | 模型格式     | Display Folder |
| ------------------------ | ------------ | -------------- |
| `Demo Net Sales`       | `#,##0.00` | `Demo/Base`  |
| `Demo Gross Sales`     | `#,##0.00` | `Demo/Base`  |
| `Demo Net Gross Ratio` | `0.0%`     | `Demo/Base`  |

保持度量返回数值，不使用 `FORMAT()` 将它们转换成文本，避免数值排序和总计行为改变。

## 5. 创建 A、B 字段参数

**必须通过“建模 → 新建参数 → 字段”创建，再编辑生成的 DAX。不要直接用“新建表”粘贴元组三列来替代。** 字段参数需要 Power BI 自动写入的元数据，普通计算表即使数据外观相同也不一定能驱动字段替换。

使用支持字段参数及 `RANK` 函数的较新版本 Power BI Desktop。若找不到字段参数入口，先核对 Desktop 版本及本地模型编辑能力，不使用纯远程实时连接完成本 Demo。

### 5.1 A：行维度字段参数

1. 新建字段参数，名称填 `O：Param_Demo_Row`。
2. 依次选入 `Dim_Demo_Store` 的 `Store_Name`、`Region`、`Store_Type`。
3. 勾选“将切片器添加到此页面”，完成创建。
4. 将参数表公式替换为以下完整表达式。

```dax
O：Param_Demo_Row =
    {
        ("门店", NAMEOF('Dim_Demo_Store'[Store_Name]), 10),
        ("区域", NAMEOF('Dim_Demo_Store'[Region]), 20),
        ("店铺类型", NAMEOF('Dim_Demo_Store'[Store_Type]), 30)
    }
```

创建后，在模型视图按列职责重命名三列，保留原列及元数据，不删除后重建：

| 生成列职责                 | 最终列名       |
| -------------------------- | -------------- |
| 第一列，参数显示名称       | `Row_Label`  |
| 第二列，字段引用，通常隐藏 | `Row_Fields` |
| 第三列，参数顺序，通常隐藏 | `Row_Order`  |

将 `Row_Label` 按 `Row_Order` 排序，切片器字段使用 `O：Param_Demo_Row[Row_Label]`。

A 开启单选，初始选“门店”；关闭全选选项，并隐藏清除选择按钮，避免无筛选状态被字段参数解释为所有字段。

### 5.2 B：展示指标字段参数

1. 新建字段参数，名称填 `O：Param_Demo_Metric`。
2. 依次选入三个显式度量 `Demo Net Sales`、`Demo Gross Sales`、`Demo Net Gross Ratio`。
3. 勾选“将切片器添加到此页面”，完成创建。
4. 将参数表公式替换为以下表达式。

```dax
O：Param_Demo_Metric =
    {
        ("净销售额", NAMEOF('Fact_Demo_Sales'[Demo Net Sales]), 10),
        ("总销售额", NAMEOF('Fact_Demo_Sales'[Demo Gross Sales]), 20),
        ("净销售额/总销售额", NAMEOF('Fact_Demo_Sales'[Demo Net Gross Ratio]), 30)
    }
```

按同样方式重命名三列：

| 生成列职责   | 最终列名          |
| ------------ | ----------------- |
| 参数显示名称 | `Metric_Label`  |
| 字段引用     | `Metric_Fields` |
| 参数顺序     | `Metric_Order`  |

将 `Metric_Label` 按 `Metric_Order` 排序。B 使用 `O：Param_Demo_Metric[Metric_Label]`，关闭单选，关闭“按住 Ctrl 才能多选”，初始选中净销售额、总销售额。

`Metric_Order` 的 10、20、30 同时用作此 Demo 的稳定指标标识，与 C 表一一对应。不要为了改变显示顺序只改 B 或只改 C。

**清除 B 的选择等同于不限制指标，即三个指标全部显示，不是零列。** 本 Demo 不实现“一个业务指标也不显示”的状态。指标列展示位置由字段参数及用户选择顺序管理，本需求只控制行排序，不依赖指标列的点击顺序。

读取字段参数时，本方案只对整数顺序列使用 `VALUES`、`HASONEVALUE`；不直接对参数显示名称列调用 `SELECTEDVALUE`，避免其复合键元数据带来的报错。

## 6. 创建 C、D 控制表

### 6.1 C：排序指标

通过“新建表”创建普通断开参数表：

```dax
O：Slicer_Demo_SortMetric =
    DATATABLE(
        "Metric_ID", INTEGER,
        "Metric_Label", STRING,
        "Metric_Sort", INTEGER,
        {
            { 10, "净销售额", 10 },
            { 20, "总销售额", 20 },
            { 30, "净销售额/总销售额", 30 }
        }
    )
```

`Metric_Label` 按 `Metric_Sort` 排序。C 使用 `O：Slicer_Demo_SortMetric[Metric_Label]`，开启单选，初始选“净销售额”。不与 B 参数表建立关系。

### 6.2 D：排序方向

```dax
O：Slicer_Demo_SortDirection =
    DATATABLE(
        "Direction_ID", STRING,
        "Direction_Label", STRING,
        "Direction_Sort", INTEGER,
        {
            { "ASC", "升序", 10 },
            { "DESC", "降序", 20 }
        }
    )
```

`Direction_Label` 按 `Direction_Sort` 排序。D 使用 `O：Slicer_Demo_SortDirection[Direction_Label]`，开启单选，初始选“降序”。

A、C、D 可使用经典列表/下拉切片器；若改用按钮切片器，为保证严格单选需同时开启 Single select 与 Force selection，但 Force selection 不会修复被 B 排除的旧选择。

## 7. 创建联动与排序度量

以下八个辅助度量也创建在 `Fact_Demo_Sales`，Display Folder 设为 `Demo/Control`。除排序序号和状态卡外，不放入业务表格列区域。

### 7.1 C 候选项是否可用

```dax
Demo Sort Metric Available = 
    VAR __CandidateID =
        SELECTEDVALUE('O：Slicer_Demo_SortMetric'[Metric_ID])
    VAR __AllowedIDs =
        VALUES('O：Param_Demo_Metric'[Metric_Order])
    RETURN
        IF(
            NOT ISBLANK(__CandidateID)
                && __CandidateID IN __AllowedIDs,
            1,
            0
        )
```

将此度量放到 **C 切片器本身**的“此视觉对象上的筛选器”，设置等于 1。不要放到页面级筛选器，也不要误放到主表格上。

这里使用 `VALUES` 即可：C 按自己的候选指标分组，B 是独立的字段参数表，不处于 C 的当前分组中。不需要清除 B 筛选，也不能对 B 使用 `ALL`，否则会把三个指标全部放回候选。

### 7.2 实际生效的排序指标 ID

```dax
Demo Effective Sort Metric ID =
    VAR __AllowedIDs =
        VALUES('O：Slicer_Demo_SortMetric'[Metric_ID])
    VAR __RequestedID =
        SELECTEDVALUE('O：Slicer_Demo_SortMetric'[Metric_ID])
    VAR __RequestedIsAllowed =
        NOT ISBLANK(__RequestedID)
            && __RequestedID IN __AllowedIDs
    RETURN
        IF(
            __RequestedIsAllowed,
            __RequestedID,
            MINX(__AllowedIDs, 'O：Slicer_Demo_SortMetric'[Metric_ID])
        )
```

回退优先级为净销售额 → 总销售额 → 比值，仅在 B 当前包含的指标中选择。

| B 已选                 | C 原选择         | 实际排序指标 |
| ---------------------- | ---------------- | ------------ |
| 净销售额、总销售额     | 总销售额         | 总销售额     |
| 净销售额、总销售额     | 比值，旧选择     | 净销售额     |
| 总销售额               | 净销售额，旧选择 | 总销售额     |
| 比值                   | 未选择           | 比值         |
| 清除 B，三个指标都有效 | 总销售额         | 总销售额     |

不要让排序度量直接使用 C 的 `SELECTEDVALUE` 而跳过本度量，否则旧选择可能继续按 B 未展示的指标排序。

### 7.3 当前行的排序业务值

```dax
Demo Sort Value =
    SWITCH(
        [Demo Effective Sort Metric ID],
        10, [Demo Net Sales],
        20, [Demo Gross Sales],
        30, [Demo Net Gross Ratio],
        BLANK()
    )
```

### 7.4 空值标识

```dax
Demo Sort Blank Flag =
    IF(ISBLANK([Demo Sort Value]), 0, 1)
```

它作为排序的第一关键字：非空为 1、空为 0，始终升序，保证空值不会在业务升序时跑到最前。

### 7.5 将业务方向转换为统一的升序比较值

```dax
Demo Sort Signed Value =
    VAR __Value = [Demo Sort Value]
    VAR __Direction =
        SELECTEDVALUE('O：Slicer_Demo_SortDirection'[Direction_ID], "DESC")
    RETURN
        IF(
            ISBLANK(__Value),
            BLANK(),
            IF(__Direction = "ASC", __Value, -__Value)
        )
```

升序保留原值，降序取相反数；这只影响排序辅助值，不修改表格里的三个业务度量。

### 7.6 同值决胜键

```dax
Demo Row Tie Key =
    MIN(Dim_Demo_Store[Store_ID])
```

门店级为该店 ID，区域级为该区域最小门店 ID，店铺类型级同理。在这份样本中不同分组的该值不同，因此不会出现无法决定顺序的并列。

### 7.7 排序序号

```dax
Demo Row Rank = 
    VAR __OneRowDimension =
        HASONEVALUE('O：Param_Demo_Row'[​Row_Order])
    RETURN
        IF(
            NOT __OneRowDimension,
            BLANK(),
            SWITCH(
                TRUE(),
                ISINSCOPE('Dim_Demo_Store'[Store_Name]),
                    RANK(
                        DENSE,
                        ALLSELECTED('Dim_Demo_Store'[Store_Name]),
                        ORDERBY(
                            [Demo Sort Blank Flag], ASC,
                            [Demo Sort Signed Value], ASC,
                            [Demo Row Tie Key], ASC
                        )
                    ),
                ISINSCOPE('Dim_Demo_Store'[Region]),
                    RANK(
                        DENSE,
                        ALLSELECTED('Dim_Demo_Store'[Region]),
                        ORDERBY(
                            [Demo Sort Blank Flag], ASC,
                            [Demo Sort Signed Value], ASC,
                            [Demo Row Tie Key], ASC
                        )
                    ),
                ISINSCOPE('Dim_Demo_Store'[Store_Type]),
                    RANK(
                        DENSE,
                        ALLSELECTED('Dim_Demo_Store'[Store_Type]),
                        ORDERBY(
                            [Demo Sort Blank Flag], ASC,
                            [Demo Sort Signed Value], ASC,
                            [Demo Row Tie Key], ASC
                        )
                    ),
                BLANK()
            )
        )
```

这是**模型度量**，不是“新建视觉计算”。`ORDERBY` 内的度量在候选行上下文中求值，不要把 `[Demo Sort Signed Value]` 先缓存成当前单行标量，再把该标量用于所有候选。

`ALLSELECTED` 按当前实际分组字段构造候选，保留外部筛选。A 切换字段后对应分支重新计算分组指标，而不是给门店排好名后再把名次累加到区域。

注意：

- 只在表格里放 A 参数提供的**一个**分组字段，不另加门店 ID、区域、店铺类型等静态分组列。
- 不对三个源行字段额外设置隐藏排序列；如未来新增，需要同时改候选关系并重新验证。
- 三个排序关键字已经能唯一决定样本顺序，因此输出为 1、2、3……；这是动态序号，不是配置表的十位步长排序字段。
- 总计行不处于任一实际行字段的作用域中，序号返回空。基础指标总计仍正常显示。
- A 如果被外部操作清空或变成多选，序号返回空；状态卡会提醒。要恢复，重新单选 A，而不是依赖这种非法状态排序。
- 辅助序号本身非空，会让仅比值为空的门店 F 仍然出现在表格中，这是本 Demo 用于验证空值置后的预期行为。

### 7.8 排序状态卡

```dax
Demo Sort Status = 
    VAR __EffectiveID = [Demo Effective Sort Metric ID]
    VAR __RequestedID =
        SELECTEDVALUE('O：Slicer_Demo_SortMetric'[Metric_ID])
    VAR __MetricLabel =
        SWITCH(
            __EffectiveID,
            10, "净销售额",
            20, "总销售额",
            30, "净销售额/总销售额"
        )
    VAR __Direction =
        SELECTEDVALUE('O：Slicer_Demo_SortDirection'[Direction_ID], "DESC")
    VAR __DirectionLabel = IF(__Direction = "ASC", "升序", "降序")
    VAR __Notice =
        SWITCH(
            TRUE(),
            ISBLANK(__RequestedID), "C 未单选，已使用当前展示指标中的首项。",
            __RequestedID <> __EffectiveID, "C 原选择已失效，已使用当前展示指标中的首项；请重新选择 C。",
            ""
        )
    RETURN
        IF(
            NOT HASONEVALUE('O：Param_Demo_Row'[​Row_Order]),
            "请在 A 中单选一个行维度。",
            __Notice
                & "当前按「" & __MetricLabel & "」" & __DirectionLabel
                & "；空值置后，同值按分组最小门店 ID 升序。"
        )
```

此卡片展示的是**实际生效的排序设置**。回退不会修改 C 勾选；如果以后 B 重新包含 C 保留的旧选择，该旧选择可能再次生效，这是按当前状态重新判定的结果。

## 8. 配置视觉对象和交互

### 8.1 主表格字段区域

插入原生“表格”，按以下顺序放入字段：

| 顺序 | 字段                                   | 操作                                          |
| ---- | -------------------------------------- | --------------------------------------------- |
| 1    | `[Demo Row Rank]`                    | 此视觉对象中重命名为“排序序号”，格式整数    |
| 2    | `O：Param_Demo_Row[Row_Label]`       | 作为字段参数使用，实际展开成一个行分组字段    |
| 3    | `O：Param_Demo_Metric[Metric_Label]` | 作为字段参数使用，实际展开成 B 选中的业务度量 |

字段井必须使用已识别的字段参数，不是把第二列的 `NAMEOF` 字符串作为普通文本放入表格。正确效果是看到门店 A、门店 B 等成员及真实金额，而不是看到“门店”“净销售额”作为重复的数据记录。

固定设置：

1. 按“排序序号”**升序**排序一次；以后切换 C、D 不需要修改视觉排序。
2. 将排序序号列保留为正常可见的窄列。
3. 开启总计行，两个金额为合计，比值为合计净额除以合计总额。
4. 关闭业务金额显示单位自动缩放，金额两位小数，比值一位小数百分比。
5. 不新增 TopN、零值隐藏或 `Demo Sort Metric Available = 1` 之类的主表格筛选。
6. 不添加额外静态分组列，不将基础金额列作为隐式度量放入表格。

### 8.2 A、B、C、D 初始状态

| 切片器 | 字段                                              | 设置                         | 初始选中           |
| ------ | ------------------------------------------------- | ---------------------------- | ------------------ |
| A      | `O：Param_Demo_Row[Row_Label]`                  | 单选、关闭全选、隐藏清除按钮 | 门店               |
| B      | `O：Param_Demo_Metric[Metric_Label]`            | 多选、无需 Ctrl              | 净销售额、总销售额 |
| C      | `O：Slicer_Demo_SortMetric[Metric_Label]`       | 单选、视觉筛选 Available = 1 | 净销售额           |
| D      | `O：Slicer_Demo_SortDirection[Direction_Label]` | 单选                         | 降序               |

先设置 B，再选 C，避免初始化时选中 B 未包含的指标。最后保存 PBIX，以保存初始选择；参数表中的某个“默认值”字段本身不会自动完成切片器选中操作。

### 8.3 显式配置“编辑交互”

在“格式 → 编辑交互”中按下表配置。Filter 表示漏斗筛选图标，None 表示不交互图标。

| 来源视觉对象 | A    | B              | C                | D    | 主表格           | 状态卡           |
| ------------ | ---- | -------------- | ---------------- | ---- | ---------------- | ---------------- |
| A            | —   | None           | None             | None | Filter           | Filter           |
| B            | None | —             | **Filter** | None | **Filter** | **Filter** |
| C            | None | **None** | —               | None | **Filter** | **Filter** |
| D            | None | None           | None             | —   | **Filter** | **Filter** |
| 主表格       | None | None           | None             | None | —               | None             |

B 即使已经能控制主表格的指标列，也仍需对 C 和状态卡开启 Filter，否则这些视觉中的度量可能读不到 B 的选择。

C、D 是断开表，选择不会过滤销售事实记录，但其选择必须传入表格和状态卡，才能驱动排序逻辑。不要因为断开关系就关闭它们对表格的交互。

新增一个卡片显示 `[Demo Sort Status]`，开启自动换行，使旧选择失效提示可见。

### 8.4 推荐演示顺序

1. 保持默认设置，展示门店 A、C 净额相同但次序稳定。
2. C 从净销售额切到总销售额，门店 C 移到第一行，B 仍显示两个金额。
3. D 改为升序，门店 F 移到最前，说明不是只更换排序名称。
4. A 改为区域，表格从 6 行变为 3 行，按区域聚合值重新排序。
5. B 增加比值，C 出现比值候选；选择比值并切换 D。
6. A 恢复门店，观察门店 E 的 0% 和门店 F 的空值位置不同。
7. 保持 C 选比值，再在 B 取消比值；状态卡提示回退，表格不得继续按比值排序。必要时在 C 手动选择一个当前可用指标。

## 9. 样本数据与预期结果

### 9.1 门店级汇总

| 门店  | 区域 | 店铺类型 |           净销售额 |           总销售额 |            比值 |
| ----- | ---- | -------- | -----------------: | -----------------: | --------------: |
| 门店A | 华东 | 直营店   |             900.00 |           1,200.00 |           75.0% |
| 门店B | 华东 | 加盟店   |             800.00 |           1,000.00 |           80.0% |
| 门店C | 华南 | 直营店   |             900.00 |           1,500.00 |           60.0% |
| 门店D | 华南 | 加盟店   |             500.00 |             800.00 |           62.5% |
| 门店E | 华北 | 直营店   |               0.00 |             200.00 |            0.0% |
| 门店F | 华北 | 加盟店   |               0.00 |               0.00 |            空白 |
| 总计  | —   | —       | **3,100.00** | **4,700.00** | **66.0%** |

总计比值为 `3100 / 4700 ≈ 65.9574%`，按一位小数显示为 66.0%。

### 9.2 区域与店铺类型汇总

| 分组字段 | 分组成员 | 净销售额 | 总销售额 |  比值 |
| -------- | -------- | -------: | -------: | ----: |
| 区域     | 华东     | 1,700.00 | 2,200.00 | 77.3% |
| 区域     | 华南     | 1,400.00 | 2,300.00 | 60.9% |
| 区域     | 华北     |     0.00 |   200.00 |  0.0% |
| 店铺类型 | 直营店   | 1,800.00 | 2,900.00 | 62.1% |
| 店铺类型 | 加盟店   | 1,300.00 | 1,800.00 | 72.2% |

直营店比值为 `1800 / 2900`，不是门店 A、C、E 比值的平均数。切换到店铺类型后，以净销售额排序与以比值排序，首行会发生变化。

### 9.3 门店级六种排序结果

验证每一行时，B 必须包含 C 对应指标。

| C 指标   | D 方向 | 预期门店顺序               |
| -------- | ------ | -------------------------- |
| 净销售额 | 降序   | A → C → B → D → E → F |
| 净销售额 | 升序   | E → F → D → B → A → C |
| 总销售额 | 降序   | C → A → B → D → E → F |
| 总销售额 | 升序   | F → E → D → B → A → C |
| 比值     | 降序   | B → A → D → C → E → F |
| 比值     | 升序   | E → C → D → A → B → F |

每种情况排序序号都应显示连续的 1～6。D 选择降序时，序号本身仍是升序，不能再将视觉序号排序改成降序。

### 9.4 A 切换后的排序结果

| A        | C        | D    | 预期行顺序           |
| -------- | -------- | ---- | -------------------- |
| 区域     | 净销售额 | 降序 | 华东 → 华南 → 华北 |
| 区域     | 总销售额 | 降序 | 华南 → 华东 → 华北 |
| 区域     | 比值     | 升序 | 华北 → 华南 → 华东 |
| 店铺类型 | 净销售额 | 降序 | 直营店 → 加盟店     |
| 店铺类型 | 比值     | 降序 | 加盟店 → 直营店     |

## 10. 验收清单

### 10.1 正常联动

- [ ] A 依次选择门店、区域、店铺类型，数据行数分别为 6、3、2，指标按当前粒度重新聚合。
- [ ] B 选择两个金额，表格只有两个业务指标列；C 正常候选只有两个金额。
- [ ] C 切换金额指标不会取消 B 中另一个展示指标。
- [ ] B 只选比值，表格仍保留行维度和排序序号；实际排序指标只能是比值。
- [ ] B 清除选择后，三个业务指标全部可用。
- [ ] D 在升序、降序之间切换，行顺序符合第 9 节，而不是只更新状态卡文本。
- [ ] A 改变后仍按排序序号升序；若当前 Desktop 版本重置了视觉排序，需要恢复，并记录该版本行为。

### 10.2 C 旧选择与反向影响

- [ ] B 全选、C 选比值，然后 B 取消比值；实际排序回退到净销售额，状态卡明确提示。
- [ ] B 只保留总销售额、C 保留旧净销售额选择时，实际排序为总销售额。
- [ ] 手动在 C 选择当前有效指标后，失效提示消失。
- [ ] B 重新加入原 C 指标时，验证旧选择是否重新生效，状态卡和表格结果必须一致。
- [ ] 不把“隐藏旧选项”当作“已经清除旧选择”；确认当前切片器类型的真实行为。
- [ ] 点击主表格某行不影响四个控制切片器的选项或选择。

### 10.3 数值和边界

- [ ] 净销售额、总销售额总计始终分别为 3,100.00、4,700.00；A、B、C、D 控制不改变事实数据范围。
- [ ] 总计比值显示 66.0%，不是各行比值相加或简单平均。
- [ ] 门店 E 的净额为 0，比值为 0%；它没有被隐藏。
- [ ] 门店 F 的比值为空，按比值升序或降序都在最后。
- [ ] 门店 A、C 按净额同值时，A 始终在 C 前；E、F 按净额同值时，E 始终在 F 前。
- [ ] 总计行的排序序号为空。
- [ ] A 若被人为清空，状态卡提醒单选；重新选择后恢复排序。
- [ ] 点击业务指标列头改变视觉排序后，重新选择“排序序号升序”能恢复 C、D 驱动的行顺序。

### 10.4 可选的 DAX 查询视图对数

基础模型和三个业务度量创建后，可在 DAX 查询视图执行：

```dax
EVALUATE
SUMMARIZECOLUMNS(
    Dim_Demo_Store[Store_Name],
    "NetSales", [Demo Net Sales],
    "GrossSales", [Demo Gross Sales],
    "NetGrossRatio", [Demo Net Gross Ratio]
)
ORDER BY Dim_Demo_Store[Store_Name] ASC
```

查询用于核对第 9.1 节的业务值，不代表已验证字段参数、切片器交互和视觉排序。后者必须在实际页面操作。

## 11. 排错与使用边界

| 现象                               | 检查项                                                                                |
| ---------------------------------- | ------------------------------------------------------------------------------------- |
| B 选两个指标，C 仍能正常选择三个   | B → C 是否为 Filter；Available 是否放在 C 视觉筛选且等于 1；是否只剩旧选择被保留显示 |
| C 切换导致 B 或表格只剩一个指标    | 是否误建了 B/C 关系，或误用同一个参数表同时承载 B 和 C                                |
| 状态卡变化但表格顺序不变           | 表格是否仍按排序序号升序；C/D → 表格是否开启 Filter                                  |
| 排名全为 1 或每组重新从 1 开始     | 是否额外放了静态分组字段，或给源行字段添加了隐藏排序列，或 A 实际变为多选             |
| 提示字段参数列属于复合键           | 是否直接读取了参数显示名称；按方案改用整数顺序列                                      |
| 表格显示 NAMEOF 字符串而非实际字段 | 是否通过“新建参数 → 字段”创建，是否保留字段参数元数据                              |
| 总计比值不对                       | 是否用了逐行比值平均，或将度量转成文本后另行聚合                                      |
| 比值为空的 F 门店没有显示          | 是否移除了排序序号列，或新增了空值隐藏筛选                                            |
| 比值为空的 F 门店跑到最前          | 是否遗漏 `Demo Sort Blank Flag`，或直接用金额式数值排序而未处理空值                 |
| 改 B 后 C 的勾选没有自动变化       | 原生选择状态限制；检查实际排序与状态卡，不用勾选外观替代有效性校验                    |

本方案不使用动态计算列做排名：计算列只在模型刷新时更新，不能响应切片器。字段参数计算表本身是静态配置，动态部分来自查询时的筛选上下文和度量。

若未来改为多层矩阵、增加行字段、增加外部筛选或隐藏辅助列，必须重新设计和验收，不直接将本 Demo 的单维排名视为通用层级排序算法。

## 12. 性能、验证状态与交付记录

### 12.1 性能与安全

- 事实表 12 行，门店维度 6 行，B/C 各 3 个候选，D 两个选项，适合演示。
- 排名关系最多只有 6 个分组成员；没有事实表逐笔排名或大表笛卡尔积。
- 未测量真实 Desktop 响应时间，不给出未经测试的毫秒级承诺。
- 数据均为虚构数据，不含真实个人信息、生产凭据或业务数据，不连接任何生产系统。

### 12.2 验证状态

- 方案明确了数据、分组、比值、同值决胜、空值置后和无效 C 选择的处理规则。
- 本地脚本已从本文件提取数据，核对 6 家门店、12 条事实记录、6 张表与 11 个度量定义，以及 B/C 指标 ID 10、20、30 的一致性。
- 门店、区域、店铺类型汇总与第 9 节一致；六种门店排序的精确顺序断言全部通过。
- 对 B 的 7 个非空指标子集，分别模拟 C 未选择及三个指标选择，共 28 种状态，实际排序指标属于 B 的断言全部通过；B 清空按三指标全量处理。
- Markdown 代码围栏配对检查通过。上述核验是样本计算和规则模拟，**没有执行 Power BI DAX 引擎**。
- **字段参数元数据、DAX 引擎执行、C 候选与持久选择的界面行为、A 切换是否保留视觉排序，仍需依第 10 节在 Power BI Desktop 实测。**
- 未生成或修改 PBIX，未连接 ClickHouse，未修改原有业务方案。

### 12.3 交付记录

| 版本 | 内容                                                         | 范围                                   |
| ---- | ------------------------------------------------------------ | -------------------------------------- |
| v1.0 | 新建动态行维度、动态指标、受限排序指标及升降序联动 Demo 方案 | 本文件，含 6 张表、11 个度量及验收步骤 |

本次只交付方案文档；实际模型/报表应用后的变更日志路径应在实施时单独确定。

## 13. 技术参考

- [Microsoft Learn：字段参数](https://learn.microsoft.com/en-us/power-bi/create-reports/power-bi-field-parameters)
- [Microsoft Learn：RANK 函数](https://learn.microsoft.com/en-us/dax/rank-function-dax)
- [Microsoft Learn：ALLSELECTED 函数](https://learn.microsoft.com/en-us/dax/allselected-function-dax)
- [Microsoft Learn：视觉对象排序](https://learn.microsoft.com/en-us/power-bi/explore-reports/end-user-change-sort)
- [Microsoft Learn：按钮切片器的单选与隐藏选择限制](https://learn.microsoft.com/en-us/power-bi/visuals/power-bi-visualization-button-slicer#considerations-and-limitations)
- [SQLBI：字段参数与 SELECTEDVALUE 的复合键问题](https://www.sqlbi.com/blog/marco/2022/06/11/using-selectedvalue-with-fields-parameters-in-power-bi/)
