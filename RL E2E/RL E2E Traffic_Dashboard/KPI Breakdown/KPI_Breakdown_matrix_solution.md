# Power BI 解决方案 — KPI Breakdown 动态矩阵（Category Growth 板块）

> status: apply
> created: 2026-07-10
> updated: 2026-07-10
> spec: RL E2E/RL E2E Traffic_Dashboard/口径文档/Category Growth.md
> 依赖: Brand-Category-Framework排列组合.sql（行维度表）、Dim_ColMetric_KpiBreakdown（列维度表，已有）
> 参考: RL E2E/RL E2E Traffic_Operation/Keyword/Keyword_YOY_matrix_solution 结构

---

## 1. 指标 SWITCH 分发 — KPI Breakdown Base Value

```dax
KPI Breakdown Base Value =
// ========================================
// 度量值: KPI Breakdown Base Value
// Display Folder: KPI Breakdown
// 用途: 列头 SWITCH 分发器，14 指标统一聚合分发
//
// ════════════════════════════════════════════════════════════════
// TREATAS 动态行筛选原理（维度表与事实表断开连接）
// ════════════════════════════════════════════════════════════════
// Brand-Category-Framework 表与事实表 a05_e2e_paid_media_summary_d 断开连接
// 通过 TREATAS 将维度表的 Level 值作为筛选器传递给事实表对应字段
//
// 多层 TREATAS 在 CALCULATE 中叠加为 AND 关系（取交集）：
//   Level 3 明细行（__IsLevel1/2/3 全部 TRUE）：
//     __L1_Filter = TREATAS({Brand值}, 事实表[brand])        → 生效
//     __L2_Filter = TREATAS({Category值}, 事实表[category])   → 生效
//     __L3_Filter = TREATAS({Framework值}, 事实表[framework]) → 生效
//     → 事实表被 brand + category + framework 三个字段同时筛选（交集）
//       示例 Scenario_Type="Brand->Category->Framework"：
//         Total="Total"、Level 1=Brand 值 → 筛选 brand 字段
//         Level 2=Category 值 → 筛选 category 字段
//         Level 3=Framework 值 → 筛选 framework 字段
//
//   Level 2 小计行（__IsLevel3=FALSE）：
//     __L1_Filter + __L2_Filter 生效
//     __L3_Filter = IF(__IsLevel3, ..., BLANK()) = BLANK() → 被 DAX 忽略
//     → 事实表只被 brand + category 筛选
//       framework 字段不筛选（即保留该 Scenario_Type 下所有 framework 值）
//
//   Level 1 小计行（__IsLevel2/3=FALSE）：
//     __L1_Filter 生效
//     __L2/L3_Filter 返回 BLANK() 被忽略
//     → 事实表只被 brand 筛选
//
//   Total 总计行（__IsTotal/Level1/2/3 全部 FALSE）：
//     三个 Filter 都返回 BLANK() 被忽略
//     → 事实表不施加任何行维度筛选（但仍筛选 Total="Total"、page_type=2 等）
//
// TREATAS + BLANK() 开关机制原理：
//   1) TREATAS({"值"}, column) 返回有效的表筛选器，等价于 column = "值"
//   2) IF(__IsLevel3, TREATAS(...), BLANK()) 当条件为 FALSE 时返回 BLANK()
//   3) CALCULATE 的筛选器参数为 BLANK() 时，DAX 引擎视为无效筛选器并忽略
//   4) 由此实现筛选器开关：层级展开时筛选器生效，未展开时筛选器关闭
//
// Scenario_Type 动态字段映射（6 种排列组合）：
//   'Brand->Category->Framework' → L1=brand,    L2=category,  L3=framework
//   'Brand->Framework->Category' → L1=brand,    L2=framework, L3=category
//   'Category->Brand->Framework' → L1=category, L2=brand,     L3=framework
//   'Category->Framework->Brand' → L1=category, L2=framework, L3=brand
//   'Framework->Brand->Category' → L1=framework,L2=brand,     L3=category
//   'Framework->Category->Brand' → L1=framework,L2=category,  L3=brand
//
// 注：Brand-Category-Framework 表中 Level 1/2/3 的值
//     即从 a05_e2e_paid_media_summary_d 表提取 brand/category/framework 字段
//     排列组合而成，因此 TREATAS 筛选一定能匹配到事实表数据
// ════════════════════════════════════════════════════════════════

    // ── 行上下文：Scenario_Type + Level 值 ──
    VAR __ScenarioType = SELECTEDVALUE('Brand-Category-Framework'[Scenario_Type])
    VAR __Level1Val    = SELECTEDVALUE('Brand-Category-Framework'[Level 1])
    VAR __Level2Val    = SELECTEDVALUE('Brand-Category-Framework'[Level 2])
    VAR __Level3Val    = SELECTEDVALUE('Brand-Category-Framework'[Level 3])

    // ── ISINSCOPE 层级判断（4 级层次：Total > Level 1 > Level 2 > Level 3）──
    // 矩阵层次结构 ISINSCOPE 状态：
    //   Grand Total 行：Total=F, Level1=F, Level2=F, Level3=F → __IsTotalRow=TRUE
    //   Level 1 小计行：Total=T, Level1=T, Level2=F, Level3=F
    //   Level 2 小计行：Total=T, Level1=T, Level2=T, Level3=F
    //   Level 3 明细行：Total=T, Level1=T, Level2=T, Level3=T
    // 总计行判断必须所有层级 ISINSCOPE 都为 FALSE，避免边缘场景误判
    VAR __IsTotal  = ISINSCOPE('Brand-Category-Framework'[Total])
    VAR __IsLevel1 = ISINSCOPE('Brand-Category-Framework'[Level 1])
    VAR __IsLevel2 = ISINSCOPE('Brand-Category-Framework'[Level 2])
    VAR __IsLevel3 = ISINSCOPE('Brand-Category-Framework'[Level 3])
    // 总计行：所有层级（Total + Level 1/2/3）ISINSCOPE 都为 FALSE
    VAR __IsTotalRow = NOT __IsTotal && NOT __IsLevel1 && NOT __IsLevel2 && NOT __IsLevel3

    // ── 列上下文 ──
    VAR __ColID      = SELECTEDVALUE(Dim_ColMetric_KpiBreakdown[ColMetric_ID])
    VAR __PlatformID = SELECTEDVALUE(Dim_ColMetric_KpiBreakdown[Platform_ID])
    VAR __MetricName = SELECTEDVALUE(Dim_ColMetric_KpiBreakdown[MetricName])
    // TRIM 去除平台区分空格，获取逻辑 channel 名
    // TM 无空格 / JD 1空格 / RLE 2空格 / DY 3空格
    VAR __MetricNameTrim = TRIM(__MetricName)

    // ── channel 列表（按平台区分）──
    // TM/RLE/DY → 直通车/引力魔方/全站推
    // JD       → 快车/触点/海投
    // JD 渠道映射：直通车→快车、引力魔方→触点、全站推→海投
    VAR __ChannelList =
        SWITCH(__PlatformID,
            "JD", {"快车", "触点", "海投"},
                       {"直通车", "引力魔方", "全站推"}  // TM/RLE/DY
        )

    // ── channel 筛选器 ──
    // __MetricNameTrim = "Total" → 保留三渠道范围（不施加单 channel 筛选）
    // __MetricNameTrim = 具体渠道 → 筛选 channel = 该渠道
    VAR __ChannelFilter =
        IF(
            __MetricNameTrim = "Total",
            FILTER(VALUES(a05_e2e_paid_media_summary_d[channel]),
                a05_e2e_paid_media_summary_d[channel] IN __ChannelList),
            FILTER(VALUES(a05_e2e_paid_media_summary_d[channel]),
                a05_e2e_paid_media_summary_d[channel] = __MetricNameTrim)
        )

    // ════════════════════════════════════════════════════════════════
    // 行维度 TREATAS 筛选器（根据 Scenario_Type 动态映射）
    // 原理：TREATAS({值}, 事实表[字段]) 等价于 事实表[字段] = 值
    //       当值为 BLANK() 时，TREATAS 被忽略，不产生筛选
    //       多个 TREATAS 在 CALCULATE 中叠加为 AND 关系
    // ════════════════════════════════════════════════════════════════

    // Level 1 筛选器：仅当 __IsLevel1=TRUE 时生效（Level 2/3/Total 行返回 BLANK）
    VAR __L1_Filter =
        IF(__IsLevel1,
            SWITCH(__ScenarioType,
                "Brand->Category->Framework", TREATAS({__Level1Val}, a05_e2e_paid_media_summary_d[brand]),
                "Brand->Framework->Category", TREATAS({__Level1Val}, a05_e2e_paid_media_summary_d[brand]),
                "Category->Brand->Framework", TREATAS({__Level1Val}, a05_e2e_paid_media_summary_d[category]),
                "Category->Framework->Brand", TREATAS({__Level1Val}, a05_e2e_paid_media_summary_d[category]),
                "Framework->Brand->Category", TREATAS({__Level1Val}, a05_e2e_paid_media_summary_d[framework]),
                "Framework->Category->Brand", TREATAS({__Level1Val}, a05_e2e_paid_media_summary_d[framework]),
                BLANK()
            ),
            BLANK()
        )

    // Level 2 筛选器：仅当 __IsLevel2=TRUE 时生效
    VAR __L2_Filter =
        IF(__IsLevel2,
            SWITCH(__ScenarioType,
                "Brand->Category->Framework", TREATAS({__Level2Val}, a05_e2e_paid_media_summary_d[category]),
                "Brand->Framework->Category", TREATAS({__Level2Val}, a05_e2e_paid_media_summary_d[framework]),
                "Category->Brand->Framework", TREATAS({__Level2Val}, a05_e2e_paid_media_summary_d[brand]),
                "Category->Framework->Brand", TREATAS({__Level2Val}, a05_e2e_paid_media_summary_d[framework]),
                "Framework->Brand->Category", TREATAS({__Level2Val}, a05_e2e_paid_media_summary_d[brand]),
                "Framework->Category->Brand", TREATAS({__Level2Val}, a05_e2e_paid_media_summary_d[category]),
                BLANK()
            ),
            BLANK()
        )

    // Level 3 筛选器：仅当 __IsLevel3=TRUE 时生效
    VAR __L3_Filter =
        IF(__IsLevel3,
            SWITCH(__ScenarioType,
                "Brand->Category->Framework", TREATAS({__Level3Val}, a05_e2e_paid_media_summary_d[framework]),
                "Brand->Framework->Category", TREATAS({__Level3Val}, a05_e2e_paid_media_summary_d[category]),
                "Category->Brand->Framework", TREATAS({__Level3Val}, a05_e2e_paid_media_summary_d[framework]),
                "Category->Framework->Brand", TREATAS({__Level3Val}, a05_e2e_paid_media_summary_d[brand]),
                "Framework->Brand->Category", TREATAS({__Level3Val}, a05_e2e_paid_media_summary_d[category]),
                "Framework->Category->Brand", TREATAS({__Level3Val}, a05_e2e_paid_media_summary_d[brand]),
                BLANK()
            ),
            BLANK()
        )

    // ── 公共筛选参数（所有指标共用）──
    // page_type=2、Total='Total' 固定筛选（事实表 Total 字段整列值为 "Total"）
    // data_date 由 Slicer_Time_Frame 断开维度传递（TimeFrame_Min/Max → data_date 字符串筛选）
    VAR __TimeMin = MIN(Slicer_Time_Frame[TimeFrame_Min])
    VAR __TimeMax = MAX(Slicer_Time_Frame[TimeFrame_Max])
    VAR __DateFilter =
        FILTER(VALUES(a05_e2e_paid_media_summary_d[data_date]),
            a05_e2e_paid_media_summary_d[data_date] >= __TimeMin
            && a05_e2e_paid_media_summary_d[data_date] <= __TimeMax)

    // ════════════════════════════════════════════════════════════════
    // 基础聚合变量（分子，施加行维度 + channel + 日期筛选）
    // ════════════════════════════════════════════════════════════════

    // cost_amt（ALL 全客）— Cost MOB% / ROI 分母 / Cost% vs SLS% 分子
    VAR __Cost_ALL =
        CALCULATE(
            SUM(a05_e2e_paid_media_summary_d[cost_amt]),
            a05_e2e_paid_media_summary_d[customer_type] = "ALL",
            a05_e2e_paid_media_summary_d[page_type] = 2,
            a05_e2e_paid_media_summary_d[Total] = "Total",
            __ChannelFilter, __DateFilter,
            __L1_Filter, __L2_Filter, __L3_Filter
        )

    // net_sales_amt（ALL 全客）— SLS% / Cost% vs SLS%
    VAR __NetSales_ALL =
        CALCULATE(
            SUM(a05_e2e_paid_media_summary_d[net_sales_amt]),
            a05_e2e_paid_media_summary_d[customer_type] = "ALL",
            a05_e2e_paid_media_summary_d[page_type] = 2,
            a05_e2e_paid_media_summary_d[Total] = "Total",
            __ChannelFilter, __DateFilter,
            __L1_Filter, __L2_Filter, __L3_Filter
        )

    // media_sales_amt（ALL 全客）— ROI 分子
    VAR __MediaSales_ALL =
        CALCULATE(
            SUM(a05_e2e_paid_media_summary_d[media_sales_amt]),
            a05_e2e_paid_media_summary_d[customer_type] = "ALL",
            a05_e2e_paid_media_summary_d[page_type] = 2,
            a05_e2e_paid_media_summary_d[Total] = "Total",
            __ChannelFilter, __DateFilter,
            __L1_Filter, __L2_Filter, __L3_Filter
        )

    // cost_amt（NEW 新客）— New Customer Cost% 分子
    VAR __Cost_NEW =
        CALCULATE(
            SUM(a05_e2e_paid_media_summary_d[cost_amt]),
            a05_e2e_paid_media_summary_d[customer_type] = "NEW",
            a05_e2e_paid_media_summary_d[page_type] = 2,
            a05_e2e_paid_media_summary_d[Total] = "Total",
            __ChannelFilter, __DateFilter,
            __L1_Filter, __L2_Filter, __L3_Filter
        )

    // cost_amt（NEW+EXISTING）— New Customer Cost% 分母
    VAR __Cost_NewExisting =
        CALCULATE(
            SUM(a05_e2e_paid_media_summary_d[cost_amt]),
            a05_e2e_paid_media_summary_d[customer_type] IN {"NEW", "EXISTING"},
            a05_e2e_paid_media_summary_d[page_type] = 2,
            a05_e2e_paid_media_summary_d[Total] = "Total",
            __ChannelFilter, __DateFilter,
            __L1_Filter, __L2_Filter, __L3_Filter
        )

    // ════════════════════════════════════════════════════════════════
    // TTL 分母变量（移除行维度筛选，保留 channel 范围 + 切片器筛选）
    // 原理：不施加 __L1/L2/L3_Filter，移除分组维度的影响
    // ════════════════════════════════════════════════════════════════

    // TTL cost（ALL，三渠道汇总，移除行维度）— Cost MOB% Total 列分母
    VAR __Cost_ALL_TTL =
        CALCULATE(
            SUM(a05_e2e_paid_media_summary_d[cost_amt]),
            a05_e2e_paid_media_summary_d[customer_type] = "ALL",
            a05_e2e_paid_media_summary_d[page_type] = 2,
            a05_e2e_paid_media_summary_d[Total] = "Total",
            FILTER(ALLSELECTED(a05_e2e_paid_media_summary_d[channel]),
                a05_e2e_paid_media_summary_d[channel] IN __ChannelList),
            __DateFilter
        )

    // TTL cost（ALL，当前渠道，移除行维度）— Cost MOB% 渠道列分母（明细行）
    VAR __Cost_ALL_Channel_TTL =
        CALCULATE(
            SUM(a05_e2e_paid_media_summary_d[cost_amt]),
            a05_e2e_paid_media_summary_d[customer_type] = "ALL",
            a05_e2e_paid_media_summary_d[page_type] = 2,
            a05_e2e_paid_media_summary_d[Total] = "Total",
            FILTER(ALLSELECTED(a05_e2e_paid_media_summary_d[channel]),
                a05_e2e_paid_media_summary_d[channel] = __MetricNameTrim),
            __DateFilter
        )

    // TTL net_sales（ALL，全渠道，移除行维度）— SLS% 分母
    VAR __NetSales_ALL_TTL =
        CALCULATE(
            SUM(a05_e2e_paid_media_summary_d[net_sales_amt]),
            a05_e2e_paid_media_summary_d[customer_type] = "ALL",
            a05_e2e_paid_media_summary_d[page_type] = 2,
            a05_e2e_paid_media_summary_d[Total] = "Total",
            __DateFilter
        )

    // ════════════════════════════════════════════════════════════════
    // 指标计算
    // ════════════════════════════════════════════════════════════════

    // ── Cost% vs SLS%（pt 差值）──
    // 口径：Cost MOB% × 100 − Net Sales% × 100
    // Total 行：始终为 0pt（Cost MOB%=100%，Net Sales%=100%）
    // 明细行：分组 Cost MOB% − 分组 Net Sales%，结果 × 100（单位 pt）
    VAR __CostMOB_Pct  = DIVIDE(__Cost_ALL, __Cost_ALL_TTL)
    VAR __NetSales_Pct = DIVIDE(__NetSales_ALL, __NetSales_ALL_TTL)
    VAR __CostVsSLS =
        IF(__IsTotalRow,
            0,                                              // Total 行 = 0pt
            (__CostMOB_Pct - __NetSales_Pct) * 100          // 明细行：差值 × 100
        )

    // ── SLS%（退后销售额占比）──
    // Total 行 = 100%；明细行 = 分组 sales / TTL sales
    VAR __SLS_Pct =
        IF(__IsTotalRow, 1, DIVIDE(__NetSales_ALL, __NetSales_ALL_TTL))

    // ── Cost MOB% Total（三渠道花费占比）──
    // Total 行 = 100%；明细行 = 分组三渠道 cost / TTL 三渠道 cost
    VAR __CostMOB_Total =
        IF(__IsTotalRow, 1, DIVIDE(__Cost_ALL, __Cost_ALL_TTL))

    // ── Cost MOB% 渠道（直通车/引力魔方/全站推 或 快车/触点/海投）──
    // Total 行：渠道 cost / 三渠道总 cost（分母为三渠道汇总）
    // 明细行：分组渠道 cost / 移除分组渠道 TTL cost（分母为当前渠道 TTL）
    VAR __CostMOB_Channel =
        IF(__IsTotalRow,
            DIVIDE(__Cost_ALL, __Cost_ALL_TTL),              // Total 行：渠道 cost / 三渠道总 cost
            DIVIDE(__Cost_ALL, __Cost_ALL_Channel_TTL)       // 明细行：分组渠道 cost / TTL 渠道 cost
        )

    // ── ROI Total（三渠道 Sales / 三渠道 Cost）──
    // Total 行和明细行口径一致：都是三渠道汇总 sales / 三渠道汇总 cost
    //   Total 行：不施加行维度 → 全 TTL 三渠道 sales / 全 TTL 三渠道 cost
    //   明细行：施加行维度 → 分组三渠道 sales / 分组三渠道 cost
    // TREATAS 自动控制：Total 行 __L1/L2/L3 返回 BLANK → 不筛选行维度
    VAR __ROI_Total = DIVIDE(__MediaSales_ALL, __Cost_ALL)

    // ── ROI 渠道（渠道 Sales / 渠道 Cost）──
    // Total 行和明细行口径一致：都是单渠道 sales / 单渠道 cost
    //   Total 行：不施加行维度 → 全 TTL 渠道 sales / 全 TTL 渠道 cost
    //   明细行：施加行维度 → 分组渠道 sales / 分组渠道 cost
    VAR __ROI_Channel = DIVIDE(__MediaSales_ALL, __Cost_ALL)

    // ── New Customer Cost% Total（三渠道 NEW / 三渠道(NEW+EXISTING)）──
    // Total 行和明细行口径一致：都是三渠道汇总 NEW / 三渠道汇总(NEW+EXISTING)
    VAR __NewCustCost_Total = DIVIDE(__Cost_NEW, __Cost_NewExisting)

    // ── New Customer Cost% 渠道（渠道 NEW / 渠道(NEW+EXISTING)）──
    // Total 行和明细行口径一致：都是单渠道 NEW / 单渠道(NEW+EXISTING)
    VAR __NewCustCost_Channel = DIVIDE(__Cost_NEW, __Cost_NewExisting)

    // ════════════════════════════════════════════════════════════════
    // SWITCH 路由分发（使用 IN 合并平台，TM/RLE/DY 逻辑一致，JD 仅 channel 名不同）
    // channel 映射已由 __ChannelFilter 处理，此处无需区分平台
    // ════════════════════════════════════════════════════════════════
    RETURN
    SWITCH(
        TRUE(),

        // ─── SLS 分组 ───
        // Cost% vs SLS%（TM:1, JD:15, RLE:29, DY:43）
        __ColID IN {1, 15, 29, 43}, __CostVsSLS,
        // SLS%（TM:2, JD:16, RLE:30, DY:44）
        __ColID IN {2, 16, 30, 44}, __SLS_Pct,

        // ─── Cost MOB% 分组 ───
        // Total（TM:3, JD:17, RLE:31, DY:45）
        __ColID IN {3, 17, 31, 45}, __CostMOB_Total,
        // 渠道列（TM:4-6, JD:18-20, RLE:32-34, DY:46-48）
        __ColID IN {4,5,6, 18,19,20, 32,33,34, 46,47,48}, __CostMOB_Channel,

        // ─── ROI 分组 ───
        // Total（TM:7, JD:21, RLE:35, DY:49）
        __ColID IN {7, 21, 35, 49}, __ROI_Total,
        // 渠道列（TM:8-10, JD:22-24, RLE:36-38, DY:50-52）
        __ColID IN {8,9,10, 22,23,24, 36,37,38, 50,51,52}, __ROI_Channel,

        // ─── New Customer Cost% 分组 ───
        // Total（TM:11, JD:25, RLE:39, DY:53）
        __ColID IN {11, 25, 39, 53}, __NewCustCost_Total,
        // 渠道列（TM:12-14, JD:26-28, RLE:40-42, DY:54-56）
        __ColID IN {12,13,14, 26,27,28, 40,41,42, 54,55,56}, __NewCustCost_Channel,

        // ─── 默认 ───
        BLANK()
    )
```

---

## 2. 行路由度量值 — KPI Breakdown Cell Value

```dax
KPI Breakdown Cell Value =
// ========================================
// 度量值: KPI Breakdown Cell Value
// Display Folder: KPI Breakdown
// 用途: 行路由度量值，直接调用 [KPI Breakdown Base Value]
//       ISINSCOPE 判断和 Total 行特殊口径已在 Base Value 中实现
// 依赖: [KPI Breakdown Base Value]
// ========================================

    [KPI Breakdown Base Value]
```

---

## 3. 格式化显示度量值 — KPI Breakdown Cell Display

```dax
KPI Breakdown Cell Display =
// ========================================
// 度量值: KPI Breakdown Cell Display
// Display Folder: KPI Breakdown > Formatting
// 用途: 根据列的 MetricFormat 类型，返回格式化后的文本
//
// 格式类型（与口径文档 Category Growth.md 一致）：
//   decimal_pt_1 → pt 点数1位小数 → Cost% vs SLS%
//                  格式：#,##0.0'pt';-#,##0.0'pt';0.0'pt'（不含正号）
//   percent_1dp  → 百分比1位小数 → SLS% / Cost MOB% 系列
//                  格式：#,##0.0%;#,##0.0%;0.0%
//   decimal_1dp  → 数值1位小数 → ROI / New Customer Cost% 系列
//                  格式：#,##0.0
// 依赖: [KPI Breakdown Cell Value], Dim_ColMetric_KpiBreakdown[MetricFormat]
// ========================================

    VAR __Value  = [KPI Breakdown Cell Value]
    VAR __Format = SELECTEDVALUE(Dim_ColMetric_KpiBreakdown[MetricFormat])

    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            SWITCH(
                __Format,
                // ─── pt 点数（Cost% vs SLS%）──
                "decimal_pt_1", FORMAT(__Value, "#,##0.0'pt';-#,##0.0'pt';0.0'pt'"),
                // ─── 百分比（SLS% / Cost MOB%）──
                "percent_1dp",  FORMAT(__Value, "#,##0.0%;#,##0.0%;0.0%"),
                // ─── 数值（ROI / New Customer Cost%）──
                "decimal_1dp",  FORMAT(__Value, "#,##0.0"),
                // ─── 默认 ───
                FORMAT(__Value, "#,##0.0")
            )
        )
```

---

## 4. 条件格式度量值 — 字体颜色

```dax
KPI Breakdown Cell Font Color =
// ========================================
// 度量值: KPI Breakdown Cell Font Color
// Display Folder: KPI Breakdown > Formatting
// 用途: 根据行层级和列指标返回字体颜色
//
// 颜色规则：
//   - Total 指标列（MetricName TRIM 后 = "Total"）→ #252423（近黑）
//   - 总计行（NOT __IsTotal）→ #252423（近黑）
//   - 其余 → #5F6165（深灰）
//
// 层级判断（4 级层次：Total > Level 1 > Level 2 > Level 3）：
//   总计行判断必须所有层级 ISINSCOPE 都为 FALSE，避免边缘场景误判
//   矩阵只展开到 Level 1 时，Level 2/3 也是 FALSE，不能用 NOT __IsLevel1 && ... 误判
// ========================================

    // ── 行上下文：层级判断（必须包含 Total 层级）──
    VAR __IsTotal  = ISINSCOPE('Brand-Category-Framework'[Total])
    VAR __IsLevel1 = ISINSCOPE('Brand-Category-Framework'[Level 1])
    VAR __IsLevel2 = ISINSCOPE('Brand-Category-Framework'[Level 2])
    VAR __IsLevel3 = ISINSCOPE('Brand-Category-Framework'[Level 3])
    VAR __IsTotalRow = NOT __IsTotal && NOT __IsLevel1 && NOT __IsLevel2 && NOT __IsLevel3

    // ── 列上下文：判断是否为 Total 指标列 ──
    VAR __MetricNameTrim = TRIM(SELECTEDVALUE(Dim_ColMetric_KpiBreakdown[MetricName]))
    VAR __IsTotalMetric  = (__MetricNameTrim = "Total")

    RETURN
        SWITCH(
            TRUE(),
            // Total 指标列 或 总计行 → #252423（近黑）
            __IsTotalMetric || __IsTotalRow, "#252423",
            // 其余 → #5F6165（深灰）
            "#5F6165"
        )
```

---

## 5. 条件格式度量值 — SVG 图标

```dax
KPI Breakdown Cell SVG Icon =
// ========================================
// 度量值: KPI Breakdown Cell SVG Icon
// Display Folder: KPI Breakdown > Formatting
// 用途: 仅 Cost% vs SLS% 指标返回 SVG 圆形图标，其余返回 BLANK
// 配置: 需将此度量值的数据类别设为"图像 URL"
//
// 图标规则：
//   正值（>0）→ 绿色圆形 #1A9018
//   负值（<0）→ 红色圆形 #D64550
//   零值（=0）→ 黄色圆形 #E1C233
// 依赖: [KPI Breakdown Cell Value], Dim_ColMetric_KpiBreakdown[MetricFormat]
// ========================================

    VAR __Value  = [KPI Breakdown Cell Value]
    VAR __Format = SELECTEDVALUE(Dim_ColMetric_KpiBreakdown[MetricFormat])

    // ── 仅 decimal_pt_1 格式（Cost% vs SLS%）显示图标 ──
    VAR __NeedsIcon = (__Format = "decimal_pt_1")

    // ── SVG 图标定义 ──
    VAR __GreenSVG =
        "data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' width='12' height='12' viewBox='0 0 12 12'><circle cx='6' cy='6' r='5' fill='%231A9018'/></svg>"
    VAR __RedSVG =
        "data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' width='12' height='12' viewBox='0 0 12 12'><circle cx='6' cy='6' r='5' fill='%23D64550'/></svg>"
    VAR __YellowSVG =
        "data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' width='12' height='12' viewBox='0 0 12 12'><circle cx='6' cy='6' r='5' fill='%23E1C233'/></svg>"

    RETURN
        SWITCH(
            TRUE(),
            NOT __NeedsIcon,     BLANK(),
            ISBLANK(__Value),    BLANK(),
            __Value > 0,         __GreenSVG,
            __Value < 0,         __RedSVG,
            __Value = 0,         __YellowSVG,
            BLANK()
        )
```

---

## 6. 条件格式度量值 — 行背景色

```dax
KPI Breakdown Cell Background Color =
// ========================================
// 度量值: KPI Breakdown Cell Background Color
// Display Folder: KPI Breakdown > Formatting
// 用途: 根据矩阵行层级和列指标返回背景色
//
// 颜色规则：
//   - 明细行（第四层级 Level 3）→ #F5F5F5（浅灰）
//   - 总计行（Total Row）→ #E6D9C7（中米色），其中 Total 指标列 → #FAF6F1（浅米色）
//   - 其余行（Level 1/2 小计行）→ #FFFFFF（白色），其中 Total 指标列 → #FAF6F1（浅米色）
//
// 层级判断（4 级层次：Total > Level 1 > Level 2 > Level 3）：
//   总计行判断必须所有层级 ISINSCOPE 都为 FALSE，避免边缘场景误判
// ========================================

    // ── 行上下文：层级判断（必须包含 Total 层级）──
    VAR __IsTotal   = ISINSCOPE('Brand-Category-Framework'[Total])
    VAR __IsLevel1  = ISINSCOPE('Brand-Category-Framework'[Level 1])
    VAR __IsLevel2  = ISINSCOPE('Brand-Category-Framework'[Level 2])
    VAR __IsLevel3  = ISINSCOPE('Brand-Category-Framework'[Level 3])
    VAR __IsTotalRow = NOT __IsTotal && NOT __IsLevel1 && NOT __IsLevel2 && NOT __IsLevel3

    // ── 列上下文：判断是否为 Total 指标列 ──
    VAR __MetricNameTrim = TRIM(SELECTEDVALUE(Dim_ColMetric_KpiBreakdown[MetricName]))
    VAR __IsTotalMetric  = (__MetricNameTrim = "Total")

    RETURN
        SWITCH(
            TRUE(),
            // ── 总计行（__IsTotalRow=TRUE）──
            // Total 指标列 → #FAF6F1（浅米色）
            // 其余列 → #E6D9C7（中米色）
            __IsTotalRow && __IsTotalMetric, "#FAF6F1",
            __IsTotalRow,                    "#E6D9C7",
            // ── 明细行（第四层级 Level 3）→ #F5F5F5（浅灰）──
            __IsLevel3, "#F5F5F5",
            // ── 其余行（Level 1/2 小计行）──
            // Total 指标列 → #FAF6F1（浅米色）
            // 其余列 → #FFFFFF（白色）
            __IsTotalMetric, "#FAF6F1",
            "#FFFFFF"
        )
```

---

## 7. 度量值清单与 Display Folder

| # | 度量值名称                                | Display Folder                    | 返回类型 |
|---|------------------------------------------|-----------------------------------|----------|
| 1 | KPI Breakdown Base Value                 | KPI Breakdown                     | 数值 |
| 2 | KPI Breakdown Cell Value                 | KPI Breakdown                     | 数值 |
| 3 | KPI Breakdown Cell Display               | KPI Breakdown > Formatting        | 文本 |
| 4 | KPI Breakdown Cell Font Color            | KPI Breakdown > Formatting        | 颜色代码 |
| 5 | KPI Breakdown Cell SVG Icon              | KPI Breakdown > Formatting        | 图像 URL |
| 6 | KPI Breakdown Cell Background Color      | KPI Breakdown > Formatting        | 颜色代码 |

---

## 8. 指标口径与格式汇总（SPEC: Category Growth.md）

| # | 指标名 | 口径 | 数据类型 | Total 行口径 |
|---|--------|------|----------|--------------|
| 1 | Cost% vs SLS% | Cost MOB% × 100 − Net Sales% × 100 | decimal_pt_1 | 0pt |
| 2 | SLS% | net_sales_amt / TTL net_sales_amt | percent_1dp | 100% |
| 3 | Cost MOB% Total | 三渠道 cost / TTL cost | percent_1dp | 100% |
| 4-6 | Cost MOB% 渠道 | 渠道 cost / TTL cost | percent_1dp | 渠道 cost / 三渠道总 cost |
| 7 | ROI Total | 三渠道 sales / 三渠道 cost | decimal_1dp | 三渠道汇总（不施加分组） |
| 8-10 | ROI 渠道 | 渠道 sales / 渠道 cost | decimal_1dp | 渠道 sales / 渠道 cost |
| 11 | New Customer Cost% Total | 三渠道 NEW / 三渠道(NEW+EXISTING) | decimal_1dp | 三渠道汇总 |
| 12-14 | New Customer Cost% 渠道 | 渠道 NEW / 渠道(NEW+EXISTING) | decimal_1dp | 渠道 NEW / 渠道(NEW+EXISTING) |

**TM/JD channel 映射**：直通车→快车、引力魔方→触点、全站推→海投
