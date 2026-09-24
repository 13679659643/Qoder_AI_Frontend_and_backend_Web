# KPI Breakdown 动态矩阵完整解决方案——前两层固定排序、第三层指标降序

> 创建日期：2026-09-24
>
> 状态：方案文件已输出；尚未部署到 Power BI，Desktop 视觉行为待验证。
>
> 范围：仅在本目录交付方案和 SQL，不修改上一级原始文件、不修改现有报表。
>
> 原方案：[KPI_Breakdown_matrix_solution](../KPI_Breakdown_matrix_solution)
>
> 配套 SQL：[Brand-Category-Framework排列组合_分层排序.sql](./Brand-Category-Framework排列组合_分层排序.sql)

## 1. 需求口径与交付边界

### 1.1 已确认的排序规则

| 维度 | 在业务第一层或第二层时 | 在业务第三层时 |
|---|---|---|
| Brand | M Polo → W Polo → Lauren → RRL → CW → CL → PL → HM | 当前父节点内按 Cost MOB% Total 降序 |
| Framework | Foundation → Acceleration → Complementary → Other | 当前父节点内按 Cost MOB% Total 降序 |
| Category | 按名称英文字母升序 | 当前父节点内按 Cost MOB% Total 降序 |

| Scenario_Sort | Scenario_Type | 第一层 | 第二层 | 第三层 |
|---|---|---|---|---|
| 1 | Brand->Category->Framework | 品牌重要性 | 品类字母序 | 指标降序 |
| 2 | Brand->Framework->Category | 品牌重要性 | 框架重要性 | 指标降序 |
| 3 | Category->Brand->Framework | 品类字母序 | 品牌重要性 | 指标降序 |
| 4 | Category->Framework->Brand | 品类字母序 | 框架重要性 | 指标降序 |
| 5 | Framework->Brand->Category | 框架重要性 | 品牌重要性 | 指标降序 |
| 6 | Framework->Category->Brand | 框架重要性 | 品类字母序 | 指标降序 |

业务第三层始终是 `[Level 3]`。实际矩阵技术层级是 `Total → Level 1 → Level 2 → Level 3`，最外面的 Total 不占业务维度层数。

### 1.2 本方案明确采用的边界行为

- 每一层只比较同一父节点下的兄弟节点，不将不同父节点的第三层混在一起排序。
- 第三层比较未格式化、未四舍五入的 Cost MOB% Total；精确同值时按第三层标签字母序。
- 第三层空值排在所有非空值之后，包括零值、负值之后；多个空值再按标签字母序。
- Brand / Framework 未知标签排在已知标签之后，再按字母序；空字符串排末。
- 标签不改写；SQL 仅在排序表达式中使用 `LOWER(TRIM(...))` 匹配 `M polo` / `M Polo` 等写法。
- 不新增“无花费就隐藏整行”规则。原显示逻辑中的 `-` 保留，不能因为排序指标为空就删除仍有其他指标的行。
- 平台、Scenario 必须单选；未选、多选或无效场景返回空，不默认为 TM 或某个排列。
- 保留原指标计算口径，包括 Cost MOB% Total 的全局 TTL 分母，不能改成当前父节点的小计分母。

### 1.3 核心技术路线

1. SQL 提供前两层静态序号，以及第三层同值时使用的字母序号。
2. 新增分层排序度量：第一层返回 `-L1_Sort`，第二层返回 `-L2_Sort`，第三层返回动态名次的负值。
3. 新增数值型矩阵度量：普通指标交叉点返回业务数值；最右侧跨列 Grand Total 返回排序分数。
4. 为该数值度量设置动态格式字符串，复用原 Cell Display 的显示文本，保留 bp、%、小数和 `-`。
5. 在矩阵上按最右侧 Grand Total 的数值降序。所有层级共用一个排序入口，DAX 在各层返回不同的依据。

不能只改 SQL 的 `ORDER BY`，也不能把一个隐藏度量放在模型中就认为排序已生效。基准交付保留可见的辅助总计列；隐藏字符仅是后续外观优化，不保证关闭该列后仍保持排序。

## 2. 依赖、模型与实施顺序

### 2.1 复用的已有对象

| 对象 | 本次处理 |
|---|---|
| `'Brand->Category->Framework'` | 用配套 SQL 更新该查询，保留模型表名及原字段名 |
| `a05_e2e_paid_media_summary_d` | 事实表不改动 |
| `Dim_ColMetric_KpiBreakdown` | 继续使用[原列维度定义](../Dim_ColMetric_KpiBreakdown)，不增删其 56 个指标记录 |
| `Slicer_Platform_Selection[Platform_ID]` | 从上游平台切片器读取 TM / JD / RLE / DY，不从指标列猜平台 |
| `Slicer_Time_Frame_Min[TimeFrame_Min]`、`Slicer_Time_Frame_Max[TimeFrame_Max]` | 继续使用原日期切片器 |
| 原六个度量值 | 第 4 节提供完整代码便于对照；已存在且一致时无需重建 |
| 新增五个度量值 | 第 5 节按顺序创建；本次需要接入的新代码 |

配套 SQL 保留原 `platform IN ('JD', 'TM')` 的行字典来源。新增 DAX 保留四平台 ID 映射，但 RLE / DY 独有组合若不在 JD / TM 字典中，仍不会显示；其全量覆盖不在本次排序变更内，不能据此宣称已支持四平台完整行集合。

### 2.2 部署前检查

- 行维度与事实表保持断开，由 Base Value 的场景映射传递行筛选。
- 平台切片器业务键唯一；核对活动关系从 `Slicer_Platform_Selection[Platform_ID]` 单向筛选事实表 `[platform]` 和列维度 `[Platform_ID]`。本文描述的是应满足的配置，不代表已读取到实际模型元数据。
- 日期字段与切片器边界在模型中均为 Date 类型；本次不重定义日期口径。
- 列头仍为 `MetricGroup → MetricName`；其排序沿用 `MetricGroup_Sort`、`MetricName_Sort`。不要清理列维度标签的跨平台尾随空格。
- 平台与 Scenario 的切片器开启单选、关闭“全选”，并确认与此矩阵的交互为“筛选”。
- 原六个度量、字体及图标仍依赖正确的平台关系；新排序取值的显式平台过滤不能替代模型关系核验。
- Power BI 版本须支持模型度量值的动态格式字符串，并有权限创建或修改模型度量。纯在线连接且不能编辑远端模型时，先取得相应模型编辑能力。

### 2.3 操作清单

1. 复制一个测试页面，保留原矩阵用于数值、行集合和格式对照。
2. 执行配套 SQL 更新原行维度查询；核对新增列和类型，刷新模型。
3. 核对第 4 节已有度量；新增第 5 节五个度量。
4. 按第 6 节替换矩阵“值”、设置动态格式及排序入口。
5. 按第 7 节验收六场景、日期/平台切换、空值、同值和折叠展开。
6. 完成实际验证后再决定是否进行辅助列外观隐藏，最后保存报表和书签。

## 3. SQL 输出字段与排序配置

| 字段 | 模型类型 | 用途 |
|---|---|---|
| Scenario_Type | 文本 | 六场景单选；可按 Scenario_Sort 排序 |
| Scenario_Sort | 整数 | 保留旧编号 1～6，避免改变已有依赖 |
| Total、Level 1、Level 2、Level 3 | 文本 | 四级矩阵行字段，保持原值 |
| L1_Sort、L2_Sort | 整数 | 当前层静态顺序，供度量读取，不直接绑定层级标签 |
| L3_Sort | 整数 | 当前父节点内第三层字母序，仅用于动态指标同值/空值的次序 |
| L1_Type、L2_Type、L3_Type | 文本 | 场景映射核对字段，不拖入矩阵行区域 |
| ID_Sort | 整数（64 位） | 静态调试顺序，不是关系键、不是动态指标排名 |

新增排序列从 10 开始、步长 10。Scenario_Sort 为保留旧值的兼容例外。ID_Sort 改为 `ROW_NUMBER() * 10`，不再使用可能发生位数重叠的十进制拼接；增删数据后其值可能改变。

只设置 `Scenario_Type → Scenario_Sort` 的“按列排序”。不要把 Level 1/2/3 分别绑定 L1/L2/L3_Sort 或 ID_Sort：同名标签跨场景、父节点可能对应不同序号，不满足模型全局一对一要求。已有此类绑定应在测试副本中解除。

SQL 是独立完整只读查询，无裸露的“数据样式”示例文本。沿用原查询的反引号、CTE 和窗口函数写法；实际数据库类型与版本未确认，目标环境还需检查语法、排序规则和 BIGINT 导入类型。

## 4. 原指标链完整代码（复用，不改变业务计算）

以下六个度量对应原方案；已存在时复用原对象。代码整理了注释和排版，保留当前执行逻辑，不按旧注释中与代码不一致的 pt / 新客格式说明改口径。

### 4.1 KPI Breakdown Base Value

```dax
KPI Breakdown Base Value =
// ========================================
// 中文名：KPI Breakdown 指标基础值
// Display Folder：KPI Breakdown
// 用途：六场景行映射、日期/渠道筛选及 14 类指标路由。
// 口径：保持原方案；排序逻辑不写入本度量。
// 差异：仅整理说明与排版，数值计算保持原执行逻辑。
// ========================================
    VAR __ScenarioType = SELECTEDVALUE('Brand->Category->Framework'[Scenario_Type])
    VAR __Level1Val = SELECTEDVALUE('Brand->Category->Framework'[Level 1])
    VAR __Level2Val = SELECTEDVALUE('Brand->Category->Framework'[Level 2])
    VAR __Level3Val = SELECTEDVALUE('Brand->Category->Framework'[Level 3])
    VAR __IsTotal = ISINSCOPE('Brand->Category->Framework'[Total])
    VAR __IsLevel1 = ISINSCOPE('Brand->Category->Framework'[Level 1])
    VAR __IsLevel2 = ISINSCOPE('Brand->Category->Framework'[Level 2])
    VAR __IsLevel3 = ISINSCOPE('Brand->Category->Framework'[Level 3])
    VAR __IsTotalRow = __IsTotal && NOT __IsLevel1 && NOT __IsLevel2 && NOT __IsLevel3
    VAR __IsTotalTTL = NOT __IsTotal && NOT __IsLevel1 && NOT __IsLevel2 && NOT __IsLevel3
    VAR __ColID = SELECTEDVALUE(Dim_ColMetric_KpiBreakdown[ColMetric_ID])
    VAR __PlatformID = SELECTEDVALUE(Dim_ColMetric_KpiBreakdown[Platform_ID])
    VAR __MetricNameTrim = TRIM(SELECTEDVALUE(Dim_ColMetric_KpiBreakdown[MetricName]))

    // 渠道 Total 选择三渠道；SLS 两列不施加单渠道筛选。
    VAR __ChannelFilter =
        FILTER(
            VALUES(a05_e2e_paid_media_summary_d[channel]),
            IF(
                __MetricNameTrim = "Total",
                (__PlatformID = "JD" && a05_e2e_paid_media_summary_d[channel] IN {"快车", "触点", "全站推"})
                    || (__PlatformID <> "JD" && a05_e2e_paid_media_summary_d[channel] IN {"直通车", "引力魔方", "全站推"}),
                IF(
                    __MetricNameTrim IN {"Cost% vs SLS%", "SLS%"},
                    TRUE(),
                    a05_e2e_paid_media_summary_d[channel] = __MetricNameTrim
                )
            )
        )
    // 先解析三个源字段的标量值，再构造固定源字段的单列表过滤。
    VAR __BrandFilterVal =
        SWITCH(
            TRUE(),
            __IsLevel1 && __ScenarioType IN {"Brand->Category->Framework", "Brand->Framework->Category"}, __Level1Val,
            __IsLevel2 && __ScenarioType IN {"Category->Brand->Framework", "Framework->Brand->Category"}, __Level2Val,
            __IsLevel3 && __ScenarioType IN {"Category->Framework->Brand", "Framework->Category->Brand"}, __Level3Val,
            BLANK()
        )
    VAR __CategoryFilterVal =
        SWITCH(
            TRUE(),
            __IsLevel1 && __ScenarioType IN {"Category->Brand->Framework", "Category->Framework->Brand"}, __Level1Val,
            __IsLevel2 && __ScenarioType IN {"Brand->Category->Framework", "Framework->Category->Brand"}, __Level2Val,
            __IsLevel3 && __ScenarioType IN {"Brand->Framework->Category", "Framework->Brand->Category"}, __Level3Val,
            BLANK()
        )
    VAR __FrameworkFilterVal =
        SWITCH(
            TRUE(),
            __IsLevel1 && __ScenarioType IN {"Framework->Brand->Category", "Framework->Category->Brand"}, __Level1Val,
            __IsLevel2 && __ScenarioType IN {"Brand->Framework->Category", "Category->Framework->Brand"}, __Level2Val,
            __IsLevel3 && __ScenarioType IN {"Brand->Category->Framework", "Category->Brand->Framework"}, __Level3Val,
            BLANK()
        )
    VAR __L1_Filter =
        FILTER(
            VALUES(a05_e2e_paid_media_summary_d[brand]),
            a05_e2e_paid_media_summary_d[brand] = __BrandFilterVal || __BrandFilterVal = BLANK()
        )
    VAR __L2_Filter =
        FILTER(
            VALUES(a05_e2e_paid_media_summary_d[category]),
            a05_e2e_paid_media_summary_d[category] = __CategoryFilterVal || __CategoryFilterVal = BLANK()
        )
    VAR __L3_Filter =
        FILTER(
            VALUES(a05_e2e_paid_media_summary_d[framework]),
            a05_e2e_paid_media_summary_d[framework] = __FrameworkFilterVal || __FrameworkFilterVal = BLANK()
        )
    VAR __TimeMin = MIN(Slicer_Time_Frame_Min[TimeFrame_Min])
    VAR __TimeMax = MAX(Slicer_Time_Frame_Max[TimeFrame_Max])
    VAR __DateFilter =
        FILTER(
            VALUES(a05_e2e_paid_media_summary_d[data_date]),
            a05_e2e_paid_media_summary_d[data_date] >= __TimeMin
                && a05_e2e_paid_media_summary_d[data_date] <= __TimeMax
        )
    // 分子：保持原 ALL / NEW / NEW+EXISTING 及 page_type 的口径。
    VAR __Cost_ALL =
        CALCULATE(
            SUM(a05_e2e_paid_media_summary_d[cost_amt]),
            a05_e2e_paid_media_summary_d[customer_type] = "ALL",
            a05_e2e_paid_media_summary_d[page_type] = "2",
            a05_e2e_paid_media_summary_d[Total] = "Total",
            __ChannelFilter, __DateFilter, __L1_Filter, __L2_Filter, __L3_Filter
        )
    VAR __NetSales_ALL =
        CALCULATE(
            SUM(a05_e2e_paid_media_summary_d[net_sales_amt]),
            a05_e2e_paid_media_summary_d[customer_type] = "ALL",
            a05_e2e_paid_media_summary_d[page_type] = "1",
            a05_e2e_paid_media_summary_d[Total] = "Total",
            __ChannelFilter, __DateFilter, __L1_Filter, __L2_Filter, __L3_Filter
        )
    VAR __MediaSales_ALL =
        CALCULATE(
            SUM(a05_e2e_paid_media_summary_d[media_sales_amt]),
            a05_e2e_paid_media_summary_d[customer_type] = "ALL",
            a05_e2e_paid_media_summary_d[page_type] = "2",
            a05_e2e_paid_media_summary_d[Total] = "Total",
            __ChannelFilter, __DateFilter, __L1_Filter, __L2_Filter, __L3_Filter
        )
    VAR __Cost_NEW =
        CALCULATE(
            SUM(a05_e2e_paid_media_summary_d[cost_amt]),
            a05_e2e_paid_media_summary_d[customer_type] = "NEW",
            a05_e2e_paid_media_summary_d[page_type] = "2",
            a05_e2e_paid_media_summary_d[Total] = "Total",
            __ChannelFilter, __DateFilter, __L1_Filter, __L2_Filter, __L3_Filter
        )
    VAR __Cost_NewExisting =
        CALCULATE(
            SUM(a05_e2e_paid_media_summary_d[cost_amt]),
            a05_e2e_paid_media_summary_d[customer_type] IN {"NEW", "EXISTING"},
            a05_e2e_paid_media_summary_d[page_type] = "2",
            a05_e2e_paid_media_summary_d[Total] = "Total",
            __ChannelFilter, __DateFilter, __L1_Filter, __L2_Filter, __L3_Filter
        )
    // TTL 分母不施加断开行表映射，但保留日期及其他外部业务筛选。
    VAR __Cost_ALL_TTL =
        CALCULATE(
            SUM(a05_e2e_paid_media_summary_d[cost_amt]),
            a05_e2e_paid_media_summary_d[customer_type] = "ALL",
            a05_e2e_paid_media_summary_d[page_type] = "2",
            a05_e2e_paid_media_summary_d[Total] = "Total",
            FILTER(
                ALLSELECTED(a05_e2e_paid_media_summary_d[channel]),
                (__PlatformID = "JD" && a05_e2e_paid_media_summary_d[channel] IN {"快车", "触点", "全站推"})
                    || (__PlatformID <> "JD" && a05_e2e_paid_media_summary_d[channel] IN {"直通车", "引力魔方", "全站推"})
            ),
            __DateFilter
        )
    VAR __Cost_ALL_Channel_TTL =
        CALCULATE(
            SUM(a05_e2e_paid_media_summary_d[cost_amt]),
            a05_e2e_paid_media_summary_d[customer_type] = "ALL",
            a05_e2e_paid_media_summary_d[page_type] = "2",
            a05_e2e_paid_media_summary_d[Total] = "Total",
            FILTER(
                ALLSELECTED(a05_e2e_paid_media_summary_d[channel]),
                a05_e2e_paid_media_summary_d[channel] = __MetricNameTrim
            ),
            __DateFilter
        )
    VAR __NetSales_ALL_TTL =
        CALCULATE(
            SUM(a05_e2e_paid_media_summary_d[net_sales_amt]),
            a05_e2e_paid_media_summary_d[customer_type] = "ALL",
            a05_e2e_paid_media_summary_d[page_type] = "1",
            a05_e2e_paid_media_summary_d[Total] = "Total",
            __DateFilter
        )
    VAR __CostMOB_Pct = DIVIDE(__Cost_ALL, __Cost_ALL_TTL)
    VAR __NetSales_Pct = DIVIDE(__NetSales_ALL, __NetSales_ALL_TTL)
    VAR __CostVsSLS = IF(__IsTotalRow || __IsTotalTTL, 0, __CostMOB_Pct - __NetSales_Pct)
    VAR __SLS_Pct = IF(__IsTotalRow || __IsTotalTTL, 1, DIVIDE(__NetSales_ALL, __NetSales_ALL_TTL))
    VAR __CostMOB_Total = IF(__IsTotalRow || __IsTotalTTL, 1, DIVIDE(__Cost_ALL, __Cost_ALL_TTL))
    VAR __CostMOB_Channel =
        IF(
            __IsTotalRow || __IsTotalTTL,
            DIVIDE(__Cost_ALL, __Cost_ALL_TTL),
            DIVIDE(__Cost_ALL, __Cost_ALL_Channel_TTL)
        )
    VAR __ROI_Total = DIVIDE(__MediaSales_ALL, __Cost_ALL)
    VAR __ROI_Channel = DIVIDE(__MediaSales_ALL, __Cost_ALL)
    VAR __NewCustCost_Total = DIVIDE(__Cost_NEW, __Cost_NewExisting)
    VAR __NewCustCost_Channel = DIVIDE(__Cost_NEW, __Cost_NewExisting)
    RETURN
        SWITCH(
            TRUE(),
            __ColID IN {1, 15, 29, 43}, __CostVsSLS,
            __ColID IN {2, 16, 30, 44}, __SLS_Pct,
            __ColID IN {3, 17, 31, 45}, __CostMOB_Total,
            __ColID IN {4, 5, 6, 18, 19, 20, 32, 33, 34, 46, 47, 48}, __CostMOB_Channel,
            __ColID IN {7, 21, 35, 49}, __ROI_Total,
            __ColID IN {8, 9, 10, 22, 23, 24, 36, 37, 38, 50, 51, 52}, __ROI_Channel,
            __ColID IN {11, 25, 39, 53}, __NewCustCost_Total,
            __ColID IN {12, 13, 14, 26, 27, 28, 40, 41, 42, 54, 55, 56}, __NewCustCost_Channel,
            BLANK()
        )
// 层级说明：L3 明细施加三维；L2 小计施加前二维；L1 小计施加第一维。
// 显式 Total 行和原生总计行均不施加行映射，保留原 Total 特殊值规则。
```

### 4.2 KPI Breakdown Cell Value

```dax
KPI Breakdown Cell Value =
// 中文名：单元格数值；Display Folder：KPI Breakdown。
// 用途/口径：复用原 Base Value；与原方案无计算差异。
    [KPI Breakdown Base Value]
// 返回原始数值；不要在此加入排序分数或 FORMAT。
```

### 4.3 KPI Breakdown Cell Display

```dax
KPI Breakdown Cell Display =
// ========================================
// 中文名：单元格显示文本
// Display Folder：KPI Breakdown > Formatting
// 用途/口径：复用原显示逻辑；空业务值显示 -，bp 显示时乘 10000。
// 差异：仍返回文本，新矩阵仅在动态格式表达式中调用它。
// ========================================
    VAR __Value = [KPI Breakdown Cell Value]
    VAR __Format = SELECTEDVALUE(Dim_ColMetric_KpiBreakdown[MetricFormat])
    RETURN
        IF(
            ISBLANK(__Value) && ISBLANK(COUNTROWS(Dim_ColMetric_KpiBreakdown)),
            BLANK(),
            IF(
                ISBLANK(__Value),
                "-",
                SWITCH(
                    __Format,
                    "decimal_pt_1", FORMAT(__Value, "#,##0.0pt;-#,##0.0pt;0.0pt"),
                    "percent_1dp", FORMAT(__Value, "#,##0.0%;-#,##0.0%;0.0%"),
                    "decimal_1dp", FORMAT(__Value, "#,##0.0"),
                    "delta_bp", IF(__Value > 0, "+", "") & FORMAT(__Value * 10000, "#,##0") & "bp",
                    "delta_bp_1dp", IF(__Value > 0, "+", "") & FORMAT(__Value * 10000, "#,##0.0") & "bp",
                    "integer_bp", FORMAT(__Value * 10000, "#,##0bp;-#,##0bp;0bp"),
                    FORMAT(__Value, "#,##0.0")
                )
            )
        )
// 这里的 - 是展示占位，不是事实值为零，也不是行有效性的判断条件。
```

当前列维度实际使用 `integer_bp`、`percent_1dp`、`decimal_1dp`。New Customer Cost% 当前使用百分比；以列维度实际配置和执行代码为准，不照旧注释改成普通小数。

### 4.4 KPI Breakdown Cell Font Color

```dax
KPI Breakdown Cell Font Color =
// 中文名：字体颜色；Display Folder：KPI Breakdown > Formatting。
// 用途/口径：保持原 Total 指标列与原生总计行的近黑色；无计算口径差异。
    VAR __IsTotal = ISINSCOPE('Brand->Category->Framework'[Total])
    VAR __IsLevel1 = ISINSCOPE('Brand->Category->Framework'[Level 1])
    VAR __IsLevel2 = ISINSCOPE('Brand->Category->Framework'[Level 2])
    VAR __IsLevel3 = ISINSCOPE('Brand->Category->Framework'[Level 3])
    VAR __IsTotalRow = NOT __IsTotal && NOT __IsLevel1 && NOT __IsLevel2 && NOT __IsLevel3
    VAR __IsTotalMetric = TRIM(SELECTEDVALUE(Dim_ColMetric_KpiBreakdown[MetricName])) = "Total"
    RETURN
        IF(__IsTotalMetric || __IsTotalRow, "#252423", "#5F6165")
// 原生总计要求四个行字段均不在作用域，不能把 L1 折叠行误判为总计。
```

### 4.5 KPI Breakdown Cell SVG Icon

```dax
KPI Breakdown Cell SVG Icon =
// ========================================
// 中文名：Cost% vs SLS% 图标
// Display Folder：KPI Breakdown > Formatting
// 用途/口径：保持原 SVG；仅差异指标显示，正绿/负红/零黄。
// 差异：无；继续按原始业务数值判断，不使用新排序分数。
// ========================================
    VAR __Value = [KPI Breakdown Cell Value]
    VAR __ColID = SELECTEDVALUE(Dim_ColMetric_KpiBreakdown[ColMetric_ID])
    VAR __GreenSVG =
        "data:image/svg+xml;utf8," &
        "<svg xmlns='http://www.w3.org/2000/svg' width='16' height='16'>" &
        "<circle cx='8' cy='8' r='7' fill='%234CAF50'/>" &
        "<path d='M8 12 L8 5 M5 7 L8 4 L11 7' stroke='white' stroke-width='1.8' stroke-linecap='round' stroke-linejoin='round' fill='none'/>" &
        "</svg>"
    VAR __RedSVG =
        "data:image/svg+xml;utf8," &
        "<svg xmlns='http://www.w3.org/2000/svg' width='16' height='16'>" &
        "<circle cx='8' cy='8' r='7' fill='%23F44336'/>" &
        "<path d='M8 4 L8 11 M5 9 L8 12 L11 9' stroke='white' stroke-width='1.8' stroke-linecap='round' stroke-linejoin='round' fill='none'/>" &
        "</svg>"
    VAR __YellowSVG =
        "data:image/svg+xml;utf8," &
        "<svg xmlns='http://www.w3.org/2000/svg' width='16' height='16'>" &
        "<circle cx='8' cy='8' r='7' fill='%23FF9800'/>" &
        "<path d='M4.5 8 L11.5 8' stroke='white' stroke-width='1.8' stroke-linecap='round' stroke-linejoin='round' fill='none'/>" &
        "</svg>"
    RETURN
        SWITCH(
            TRUE(),
            NOT (__ColID IN {1, 15, 29, 43}), BLANK(),
            ISBLANK(__Value), BLANK(),
            __Value > 0, __GreenSVG,
            __Value < 0, __RedSVG,
            __Value = 0, __YellowSVG,
            BLANK()
        )
// 数据类别沿用图像 URL；横向辅助总计没有单一指标 ID，不产生图标。
```

### 4.6 KPI Breakdown Cell Background Color

```dax
KPI Breakdown Cell Background Color =
// 中文名：背景色；Display Folder：KPI Breakdown > Formatting。
// 用途/口径：保持原总计米色、Total 指标浅米色、L3 浅灰的优先级；无计算差异。
    VAR __IsTotal = ISINSCOPE('Brand->Category->Framework'[Total])
    VAR __IsLevel1 = ISINSCOPE('Brand->Category->Framework'[Level 1])
    VAR __IsLevel2 = ISINSCOPE('Brand->Category->Framework'[Level 2])
    VAR __IsLevel3 = ISINSCOPE('Brand->Category->Framework'[Level 3])
    VAR __IsTotalRow = NOT __IsTotal && NOT __IsLevel1 && NOT __IsLevel2 && NOT __IsLevel3
    VAR __IsTotalMetric = TRIM(SELECTEDVALUE(Dim_ColMetric_KpiBreakdown[MetricName])) = "Total"
    RETURN
        SWITCH(
            TRUE(),
            __IsTotalRow, "#E6D9C7",
            NOT __IsTotalRow && __IsTotalMetric, "#FAF6F1",
            __IsLevel3, "#F5F5F5",
            "#FFFFFF"
        )
// 优先级保持原执行代码：L3 的 Total 指标仍优先使用浅米色。
```

## 5. 新增排序及矩阵度量（按顺序创建）

### 5.1 KPI Breakdown Sort Context Valid

```dax
KPI Breakdown Sort Context Valid =
// ========================================
// 中文名：排序上下文有效标志
// Display Folder：KPI Breakdown > Sorting
// 用途：避免平台/场景多选时混排，防止不存在的行字典组合产生排序占位。
// 口径：只校验配置与行字典存在性，不新增事实无数据行过滤。
// 差异：新增；不是按 Cost MOB% 是否非空判定整行可见性。
// ========================================
    VAR __PlatformID = SELECTEDVALUE(Slicer_Platform_Selection[Platform_ID])
    // Scenario 与行字段同表；行路径可能将多选场景交叉筛成单值。
    // 因此除 SELECTEDVALUE 外，还必须检查 Scenario_Type 的直接单值筛选。
    VAR __Scenario = SELECTEDVALUE('Brand->Category->Framework'[Scenario_Type])
    VAR __ValidScenario =
        __Scenario IN {
            "Brand->Category->Framework", "Brand->Framework->Category",
            "Category->Brand->Framework", "Category->Framework->Brand",
            "Framework->Brand->Category", "Framework->Category->Brand"
        }
    RETURN
        IF(
            __PlatformID IN {"TM", "JD", "RLE", "DY"}
                && HASONEFILTER('Brand->Category->Framework'[Scenario_Type])
                && __ValidScenario
                && NOT ISEMPTY('Brand->Category->Framework'),
            1,
            0
        )
// Total/L1/L2/L3 都要求单一场景；缺省不猜测平台或场景。
```

### 5.2 KPI Breakdown Sort Cost MOB Total

```dax
KPI Breakdown Sort Cost MOB Total =
// ========================================
// 中文名：排序专用 Cost MOB% Total 原始值
// Display Folder：KPI Breakdown > Sorting
// 用途：无论当前处于哪个指标列，都读取当前平台的 Cost MOB% Total。
// 口径：复用原 Cell Value；保留日期、父节点、业务筛选，不改 TTL 分母。
// 差异：新增；先保存平台，再清除列维度上下文并锁定唯一指标 ID。
// ========================================
    VAR __PlatformID = SELECTEDVALUE(Slicer_Platform_Selection[Platform_ID])
    VAR __TargetColID =
        SWITCH(__PlatformID, "TM", 3, "JD", 17, "RLE", 31, "DY", 45, BLANK())
    RETURN
        IF(
            [KPI Breakdown Sort Context Valid] = 1 && NOT ISBLANK(__TargetColID),
            CALCULATE(
                [KPI Breakdown Cell Value],
                REMOVEFILTERS(Dim_ColMetric_KpiBreakdown),
                TREATAS({__TargetColID}, Dim_ColMetric_KpiBreakdown[ColMetric_ID]),
                // 显式与已有事实平台筛选取交集，不将不同平台花费混算。
                KEEPFILTERS(TREATAS({__PlatformID}, a05_e2e_paid_media_summary_d[platform]))
            ),
            BLANK()
        )
// 只清列指标上下文；不能清整个行表、日期表或事实表。
// TargetColID 同时确定指标类型与平台，不能只筛 MetricName="Total"。
```

### 5.3 KPI Breakdown Sort Value

```dax
KPI Breakdown Sort Value =
// ========================================
// 中文名：分层统一降序分数
// Display Folder：KPI Breakdown > Sorting
// 用途：L1/L2 固定排序；L3 按 Cost MOB% Total 降序，再按名称升序。
// 口径：空值排所有非空值后；零值有效；不四舍五入、不向占比添加小数扰动。
// 差异：新增动态同级名次，不用 SQL 的 ID_Sort 代替指标排名。
// ========================================
    VAR __IsL1 = ISINSCOPE('Brand->Category->Framework'[Level 1])
    VAR __IsL2 = ISINSCOPE('Brand->Category->Framework'[Level 2])
    VAR __IsL3 = ISINSCOPE('Brand->Category->Framework'[Level 3])
    RETURN
        IF(
            [KPI Breakdown Sort Context Valid] <> 1,
            BLANK(),
            SWITCH(
                TRUE(),
                // 必须从最深层开始判断；在 L3 行上 L1/L2 同时也在作用域。
                __IsL3,
                    VAR __CurrentValue = [KPI Breakdown Sort Cost MOB Total]
                    VAR __CurrentNameSort = SELECTEDVALUE('Brand->Category->Framework'[L3_Sort])
                    // 只释放当前 L3 标签，保留 Scenario、L1、L2 和外部 L3 选择。
                    VAR __Siblings =
                        CALCULATETABLE(
                            VALUES('Brand->Category->Framework'[Level 3]),
                            ALLSELECTED('Brand->Category->Framework'[Level 3])
                        )
                    VAR __ScoredSiblings =
                        ADDCOLUMNS(
                            __Siblings,
                            "@CostMOB", CALCULATE([KPI Breakdown Sort Cost MOB Total]),
                            "@NameSort", CALCULATE(SELECTEDVALUE('Brand->Category->Framework'[L3_Sort]))
                        )
                    VAR __BeforeCount =
                        COUNTROWS(
                            FILTER(
                                __ScoredSiblings,
                                VAR __OtherValue = [@CostMOB]
                                VAR __OtherNameSort = [@NameSort]
                                RETURN
                                    IF(
                                        ISBLANK(__CurrentValue),
                                        // 当前为空：所有非空，以及名称更靠前的空值，都排在前面。
                                        NOT ISBLANK(__OtherValue)
                                            || (ISBLANK(__OtherValue) && __OtherNameSort < __CurrentNameSort),
                                        // 当前非空：排除空值，再按真实指标大小和同值名称顺序比较。
                                        NOT ISBLANK(__OtherValue)
                                            && (
                                                __OtherValue > __CurrentValue
                                                    || (__OtherValue == __CurrentValue && __OtherNameSort < __CurrentNameSort)
                                            )
                                    )
                            )
                        )
                    RETURN
                        IF(ISBLANK(__CurrentNameSort), BLANK(), -(COALESCE(__BeforeCount, 0) + 1)),
                __IsL2,
                    VAR __L2Sort = SELECTEDVALUE('Brand->Category->Framework'[L2_Sort])
                    RETURN IF(ISBLANK(__L2Sort), BLANK(), -__L2Sort),
                __IsL1,
                    VAR __L1Sort = SELECTEDVALUE('Brand->Category->Framework'[L1_Sort])
                    RETURN IF(ISBLANK(__L1Sort), BLANK(), -__L1Sort),
                0
            )
        )
// 返回值示例：L1 的 M Polo=-10、W Polo=-20；L3 第1名=-1、第2名=-2。
// 矩阵统一降序，即 -10 在 -20 前、-1 在 -2 前；不同层之间无需相互比较。
// 没有行层级在作用域的原生总计，以及仅 Total 在作用域的显式总行，都返回0。
```

本度量使用“排在当前项前面的个数 + 1”得到唯一名次，避免依赖 BLANK 被当作 0 的默认排名行为。`L3_Sort` 只参与精确同值时的次序，不改变指标本身。

### 5.4 KPI Breakdown Matrix Value

```dax
KPI Breakdown Matrix Value =
// ========================================
// 中文名：可排序的矩阵数值
// Display Folder：KPI Breakdown
// 用途：业务列承载原数值，横向 Grand Total 承载分层排序分数。
// 口径：业务值不混入排序分数；业务空值用0作显示占位，动态格式显示原 -。
// 差异：新增视觉专用数值包装；不替换原 Cell Value，不用于下游业务计算。
// ========================================
    VAR __IsMetricGroup = ISINSCOPE(Dim_ColMetric_KpiBreakdown[MetricGroup])
    VAR __IsMetricName = ISINSCOPE(Dim_ColMetric_KpiBreakdown[MetricName])
    VAR __IsColumnGrandTotal = NOT __IsMetricGroup && NOT __IsMetricName
    VAR __PlatformID = SELECTEDVALUE(Slicer_Platform_Selection[Platform_ID])
    VAR __ColumnPlatform = SELECTEDVALUE(Dim_ColMetric_KpiBreakdown[Platform_ID])
    RETURN
        IF(
            [KPI Breakdown Sort Context Valid] <> 1,
            BLANK(),
            SWITCH(
                TRUE(),
                __IsColumnGrandTotal, [KPI Breakdown Sort Value],
                __IsMetricName
                    && HASONEVALUE(Dim_ColMetric_KpiBreakdown[ColMetric_ID])
                    && __ColumnPlatform = __PlatformID,
                    COALESCE([KPI Breakdown Cell Value], 0),
                BLANK()
            )
        )
// 横向总计：MetricGroup=FALSE，MetricName=FALSE。
// 普通指标列（包括各分组中的 Total）：MetricGroup=TRUE，MetricName=TRUE。
// 指标组小计：MetricGroup=TRUE，MetricName=FALSE，返回空，不误当排序列。
```

这里用 0 保持原 `-` 占位的行列展示；动态格式仍依据原 Cell Display，故真实零值显示 `0.0%`，业务空值显示 `-`。底层导出时二者的 Matrix Value 都可能为 0，因此业务计算、原始数据导出必须使用原 Cell Value，不能使用这个视觉包装度量。

### 5.5 KPI Breakdown Matrix Format

```dax
KPI Breakdown Matrix Format =
// ========================================
// 中文名：矩阵动态格式字符串
// Display Folder：KPI Breakdown > Formatting
// 用途：保留原业务显示文本，同时让 Matrix Value 的数据类型仍为数值。
// 口径：业务显示来自原 Cell Display；排序分数基准显示整数，便于验收。
// 差异：新增格式表达式；FORMAT 仅用于格式生成链，不把数值度量变成文本。
// ========================================
    VAR __IsMetricGroup = ISINSCOPE(Dim_ColMetric_KpiBreakdown[MetricGroup])
    VAR __IsMetricName = ISINSCOPE(Dim_ColMetric_KpiBreakdown[MetricName])
    VAR __IsColumnGrandTotal = NOT __IsMetricGroup && NOT __IsMetricName
    // 默认显示辅助分数；完成排序验收后，才可改为 TRUE 试验隐藏字符。
    VAR __HideSortScore = FALSE()
    VAR __Quote = UNICHAR(34)
    VAR __BlankLiteral = __Quote & " " & __Quote
    VAR __BlankFormat = __BlankLiteral & ";" & __BlankLiteral & ";" & __BlankLiteral
    RETURN
        IF(
            __IsColumnGrandTotal,
            IF(__HideSortScore, __BlankFormat, "0"),
            IF(
                __IsMetricName && HASONEVALUE(Dim_ColMetric_KpiBreakdown[ColMetric_ID]),
                VAR __Text = [KPI Breakdown Cell Display]
                VAR __EscapedText = SUBSTITUTE(__Text, __Quote, __Quote & __Quote)
                VAR __Literal = __Quote & __EscapedText & __Quote
                // 正/负/零三段均使用原完整文本，避免负值出现重复负号。
                RETURN __Literal & ";" & __Literal & ";" & __Literal,
                __BlankFormat
            )
        )
// 本度量返回格式代码，不能放入矩阵“值”。
// 隐藏格式只隐藏字符，不移除辅助列、表头、列宽或底层排序值。
```

**必须再执行动态格式绑定**：选中 `[KPI Breakdown Matrix Value]` → 度量值工具/属性 → 格式选择“动态”，在“格式字符串表达式”而不是“度量值表达式”输入：

```dax
[KPI Breakdown Matrix Format]
```

例如原文本为 `12.3%`，格式度量返回三段带引号的字面量格式，Matrix Value 仍保存数值 `0.123`；原 `integer_bp` 的乘 10000 只发生在原显示链，不重复缩放原始值。

## 6. Power BI 矩阵配置（不可省略）

### 6.1 字段槽位

| 区域 | 字段/度量及顺序 |
|---|---|
| 行 | `'Brand->Category->Framework'[Total]` → `[Level 1]` → `[Level 2]` → `[Level 3]` |
| 列 | `Dim_ColMetric_KpiBreakdown[MetricGroup]` → `[MetricName]` |
| 值 | 仅 `[KPI Breakdown Matrix Value]` |
| Scenario 切片器 | `'Brand->Category->Framework'[Scenario_Type]`，单选 |
| 平台切片器 | `Slicer_Platform_Selection[Platform_Label]` 或 `[Platform_ID]`，单选 |

把原 `[KPI Breakdown Cell Display]` 从测试矩阵“值”中移出，保留模型中的原度量。不要同时把 Sort Value、Matrix Format 等辅助度量拖入“值”，否则会在每个指标下复制出额外度量列。

字体颜色、背景色继续按字段值绑定原两个颜色度量。已有图标绑定需在替换“值”后重新检查；保留原图标方案。若所用视觉版本不支持原 SVG 条件图标方式，可使用原生规则图标，依据原 Cell Value 的正/负/零判断并限定差异指标，不把 SVG 再拖入本方案唯一的值槽。

### 6.2 总计与排序

1. 行区域维持层次结构，通过“+”展开父节点；不要用“转到层次结构中的下一级”移除父级。后者是另一种浏览语义，不能用于本方案的父内排序验收。
2. 开启跨所有指标的**最右侧列 Grand Total**。不同版本属性面板名称可能不同，以“每行最右侧新增一个跨列总计单元格”为准。
3. 关闭 SLS / Cost MOB% / ROI / New Customer Cost% 的组小计，保持普通指标列；保留第 2 步的最右侧总计。
4. 先保持 `__HideSortScore = FALSE()`，检查最右侧数据：L1/L2 为负静态序号，L3 为 -1、-2……。
5. 点击最右侧总计的数值列头切换为**降序**，确认排序箭头。若使用“…”→排序依据，选该数值度量对应的总计排序入口，不能选行标签。
6. 展开到 L3，逐个父节点确认顺序；切换六个 Scenario、日期及平台，再次确认排序依据没有被切回行字段。
7. 保留显式 Total 行和原生行总计的原业务表现；它们在右侧辅助总计中显示 0，不参与子节点间的排名。

### 6.3 四种 Total 必须区分

| 位置 | 含义 | 该位置的处理 |
|---|---|---|
| 最左侧行中的显式 Total | 行维度顶层 | 普通业务列仍显示原 Total 指标值 |
| 最底部原生总计行 | Power BI 行汇总 | 普通业务列沿用原总计计算 |
| Cost MOB% 分组下的 Total | 一个真实业务指标列 | 仍显示真实 Cost MOB% Total，不显示分数 |
| 最右侧跨所有指标的 Grand Total | 本方案辅助排序入口 | 返回 Sort Value，不是 14 个指标的加总 |

### 6.4 辅助列的外观限制与替代路径

- 基准方案保留最右侧辅助列，可在版本支持时将其标签改为“排序”，避免把它误认为业务总计。
- 完成验收后，可把 `__HideSortScore` 改为 `TRUE()`，以显式空格字面量格式隐藏分数字符；若本机格式不支持则恢复 `FALSE()`。
- 字符隐藏并不删除列宽或表头；可关闭自动列宽后缩窄辅助列，但不得把“完全零占位”写作保证。
- 不使用返回 BLANK 的方式隐藏排序数值，否则可能失去排序依据；不把 `;;;`、格式空串视为已验证的隐藏手段。
- 不保证关闭列 Grand Total 后刷新、切换场景、重开报表仍保持排序；基准验收必须保留该入口。
- 若当前版本不能按该 Grand Total 排序，停止外观调整并记录为阻断项。替代方案是另建无列层级的平铺指标矩阵或评估自定义视觉；这会影响双层列头、许可或维护方式，需要另行确认，不能无声替换当前布局。
- 本方案解决排序逻辑，不承诺像素级完全复刻截图。动态格式显示与实际矩阵排序需在目标 Desktop 版本中联合验证。

## 7. 验证案例与验收清单

### 7.1 层级真值表

| 当前行 | Total | Level 1 | Level 2 | Level 3 | Sort Value |
|---|---|---|---|---|---|
| 原生总计 | F | F | F | F | 0 |
| 显式 Total | T | F | F | F | 0 |
| 第一层节点 | T | T | F | F | -L1_Sort |
| 第二层节点 | T | T | T | F | -L2_Sort |
| 第三层节点 | T | T | T | T | 动态名次的负值 |

### 7.2 具体交叉点示例（模拟数据，不是生产结果）

场景 `Brand->Framework->Category`，只看 `M Polo → Foundation` 内部：

| Level 3 | Cost MOB% Total 原值 | 字母序 L3_Sort | Sort Value | 显示先后 |
|---|---|---|---|---|
| Shirts | 0.18 | 40 | -1 | 1 |
| Accessories | 0.12 | 10 | -2 | 2 |
| Pants | 0.12 | 30 | -3 | 3 |
| Shoes | 0 | 50 | -4 | 4 |
| Socks | -0.01 | 60 | -5 | 5 |
| Bags | BLANK | 20 | -6 | 6 |

同一个场景，M Polo 的 Foundation 与 Acceleration 即使占比为 2% 和 20%，仍是 Foundation 在前，因为它们在第二层。切换到 `Category->Framework->Brand` 后 Brand 位于第三层，必须按占比而不是品牌重要性排序。

### 7.3 实际模型必验项目

| 验证项目 | 预期结果 | 实测状态 |
|---|---|---|
| 六种 Scenario 逐级展开 | 前两层符合第 1 节，第三层各父节点内指标递减 | 待 Desktop 验证 |
| 固定排序列唯一性 | 同场景+当前父节点+当前标签只对应一个当前层序号 | 待模型导入验证 |
| Cost MOB% 取值 | 排序专用原始值与对应业务 Total 列逐行一致 | 待真实数据验证 |
| 切换日期/平台 | 第三层随当前筛选重新排名，前两层重要性不变 | 待 Desktop 验证 |
| 同值/零/负值/空值 | 同值字母序，空值最后，0 不等同 BLANK | 待 Desktop 验证 |
| 原指标全量对照 | 14 列各级业务数值、bp/%格式及颜色与原矩阵一致 | 待真实数据验证 |
| 行集合对照 | 不因辅助分数产生不存在的字典组合，不因无花费丢失有销售的行 | 待 Desktop 验证 |
| 未选/多选 Scenario 或平台 | 返回空；即使某行路径只属于一个所选场景，也不能绕过 Scenario 直接单选检查 | 待 Desktop 验证 |
| 分组 Total 与横向 Grand Total | 前者仍为业务值，后者才是排序分数 | 待 Desktop 验证 |
| 折叠/展开、保存/重开、书签 | 排序依据及方向保持正确 | 待 Desktop 验证 |
| 隐藏格式与列宽 | 不影响排序；不支持时保留可见分数列 | 待 Desktop 验证 |

验证时不要把原始 Level 字段改成同名的计算列，也不要临时将 L3_Sort 放到行区域；新增行字段会改变当前查询的分组和 ALLSELECTED 行为。辅助值需通过度量或单独诊断表查看。

## 8. 已知边界、性能与回退

- 原 Base Value 使用 `FilterVal = BLANK()` 放行未启用维度。本次保持此逻辑；源数据空字符串在 DAX 宽松比较中也可能被当作空而放行，因此空标签行的指标准确性是原方案既有边界。SQL 排末不代表修复了该取数问题，正式验收前应排查源空标签，不自动替换为 Other。
- SQL 区分标签的规则与 Power BI 的大小写/空格等价规则可能不同。同一名称的大小写或尾随空格变体应检查导入后是否合并、是否导致排序列多值；不能直接宣称 SQL 测试等于模型测试。
- 新逻辑只在横向总计上下文调用动态排序，不应在 14 个普通指标列重复执行排名。前两层只读取一个静态序号；第三层遍历当前父节点的兄弟集合，不扫描事实表构造笛卡尔积。
- 若某父节点有 N 个叶项，每项计算同级比较，整体可能接近 O(N²)。大基数父组应使用 Performance Analyzer 对比冷/热查询耗时；本次不提供未经实测的性能提升或耗时保证。
- ALLSELECTED 保留第三层外部选择，但不为任意 Top N、额外行字段、非层级钻取或复杂度量过滤组合提供无条件保证；这些配置需要另行验证。
- 动态格式重用原显示链，不能将 Matrix Format 设为图像 URL，也不能将 Matrix Value 改成文本类型。
- 回退：测试矩阵“值”换回原 Cell Display，恢复原排序设置并移除辅助横向总计；如需回退 SQL，使用上一级原查询。原六个模型度量、原文件和原报表页面均应保留。

## 9. 交付记录与证据范围

### [2026-09-24 15:41] 方案与 SQL——新增六场景分层排序交付

- 新增文件：本方案文档、配套完整 SQL；未修改上一级原方案或原 SQL。
- 新增方案对象：Sort Context Valid、Sort Cost MOB Total、Sort Value、Matrix Value、Matrix Format 共五个度量；原六个度量完整列出供复用。
- 静态规则：Brand/Framework 固定优先级、Category 字母序、L3 动态排名及同值/空值次序。
- 静态核查后补充：Scenario 单选使用 HASONEFILTER 直接筛选检查，避免同表行路径将多选缩为单值而绕过校验。
- SQL 验证：交付 SQL 已在内存 SQLite 模拟源表执行，覆盖六排列、去重、NULL、空字符串、未知标签、大小写/空格变体及较大字典；这不是目标数据库验证。
- 排名比较规则验证：用内存模拟计算核对第 7.2 节六个交叉点，实际得到名次 1～6，覆盖同值、零、负值和空值；这是比较算法验证，不是 DAX 筛选上下文运行验证。
- 尚未执行：实际 Power BI DAX 编译、关系检查、真实指标对账、视觉排序/动态格式/性能验收。IDE 无可用的相关语法诊断插件；文件生成不代表已部署或业务验收通过。

参考：[微软动态格式字符串](https://learn.microsoft.com/en-us/power-bi/create-reports/desktop-dynamic-format-strings)、[按列排序约束](https://learn.microsoft.com/en-us/power-bi/create-reports/desktop-sort-by-column)、[矩阵总计排序思路](https://www.esbrina-ba.com/sorting-a-matrix-by-a-calculation-item-column/)。外部案例只支持技术思路，不能替代本项目目标版本实测。
