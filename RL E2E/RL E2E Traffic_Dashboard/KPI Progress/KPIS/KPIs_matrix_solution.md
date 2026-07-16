# Power BI 解决方案 — KPIs 矩阵（KPI Progress 子模块一 + 子模块二）

> status: ready
> created: 2026-07-15
> type: 度量值开发 + 可视化构建
> 口径来源: 口径文档/KPI Progress.md 子模块一（KPIs，1~15）与子模块二（Performance Indicators，16~24）
> 维度来源: KPI Progress/KPIS/Dim_ColMetric_KPIs（24 个指标行）
> 参考: KPI Progress/KPI by Platform/KPI by Platform_matrix_solution.md、Category Growth/KPI_Breakdown_matrix_solution、KPI Progress/参考指标/Font Color

---

## 1. 需求理解

实现 KPI Progress 看板中"KPIs"与"Performance Indicators"两个子模块的中国式矩阵（卡片图）效果：

- **列**：指标维度 `Dim_ColMetric_KPIs[Metric_Name]`，共 24 个指标（`Metric_ID` 1~24）
- **行**：本模块为"无分组维度"卡片图，只受筛选器影响；矩阵场景下可省略行字段或仅用单行占位
- **值**：SWITCH 动态路由，按 `Metric_ID` 分发到 本期 / vs LP / vs LY / TRA ACH%
- **口径**：一切以口径文档 KPI Progress.md 子模块一、子模块二为准
- **筛选器**：与 Category Growth/KPI_Breakdown 一致，全看板公用，Currency 断开连接仅作用于金额类指标

---

## 2. 现状分析

### 2.1 数据底表

| 对象     | 名称                                                                                                                                                     | 出处                                      |
| -------- | -------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------- |
| 事实表   | a05_e2e_paid_media_summary_d                                                                                                                             | 维度复用/a05_e2e_paid_media_summary_d.sql |
| 关键字段 | data_date, platform, store_name, trans_cycle, customer_type, page_type, framework, cost_amt, net_sales_amt, fcst_cost_amt, fcst_net_sales_amt, media_member_cnt, member_cnt, media_cost_amt | 口径文档 KPI Progress.md 子模块一、二     |

### 2.2 维度表清单

| 维度表                    | 类型     | 连接方式                                                  | 出处                                       |
| ------------------------- | -------- | --------------------------------------------------------- | ------------------------------------------ |
| Slicer_Time_Frame_Min     | 断开维度 | SELECTEDVALUE 读取 TimeFrame_Min                          | 维度复用/Slicer_Time_Frame_Min.sql         |
| Slicer_Time_Frame_Max     | 断开维度 | SELECTEDVALUE 读取 TimeFrame_Max                          | 维度复用/Slicer_Time_Frame_Max.sql         |
| Slicer_Platform_Selection | 1:N 关系 | Platform_ID → 事实表[platform]                           | 维度复用/Slicer_Platform_Selection         |
| Slicer_Store_Name         | 1:N 关系 | Store_ID → 事实表[store_name]                            | 维度复用/Slicer_Store_Name                 |
| Slicer_Currency_Selection | 断开维度 | SELECTEDVALUE 读取 Currency_ExchangeRate, Currency_Symbol | 维度复用/Slicer_Currency_Selection         |
| trans_cycle 筛选器        | 1:N 关系 | → 事实表[trans_cycle]（模型自动筛选）                    | 用户需求                                   |
| Dim_ColMetric_KPIs        | 断开维度 | SELECTEDVALUE 读取 Metric_ID, Metric_Format               | KPI Progress/KPIS/Dim_ColMetric_KPIs       |

### 2.3 指标维度表（Dim_ColMetric_KPIs）24 个指标

| Metric_ID | Metric_Name                                            | Metric_Sort | Metric_Format        | IsCurrencyAmount |
| --------- | ------------------------------------------------------ | ----------- | -------------------- | ---------------- |
| 1         | Media Cost Rate                                        | 10          | percent_1dp          | FALSE            |
| 2         | Media Cost                                             | 20          | currency             | TRUE             |
| 3         | Cost ACH%                                              | 30          | percent_1dp          | FALSE            |
| 4         | Cost vs SLS ACH%                                       | 40          | delta_bp             | FALSE            |
| 5         | SLS ACH%                                               | 50          | percent_1dp          | FALSE            |
| 6         | SLS DCom                                               | 60          | currency             | TRUE             |
| 7         | Media Contribution to New Customer Acquisition%        | 70          | percent_1dp          | FALSE            |
| 8         | Media Contribution to New Customer Acquisition% vs LY  | 80          | delta_bp             | FALSE            |
| 9         | Media Contribution to New Customer Acquisition% TRA ACH% | 90          | percent_1dp          | FALSE            |
| 10        | Media Cost Per New Acquisition                         | 100         | currency_decimal_1dp | TRUE             |
| 11        | Media Cost Per New Acquisition vs LY                   | 110         | percent_1dp          | FALSE            |
| 12        | Media Cost Per New Acquisition TRA ACH%                | 120         | percent_1dp          | FALSE            |
| 13        | ± Acceleration cost MOB% vs. store SLS MOB%            | 130         | percent_1dp          | FALSE            |
| 14        | ± Acceleration cost MOB% vs. store SLS MOB% vs LY      | 140         | delta_bp             | FALSE            |
| 15        | ± Acceleration SLS MOB% vs. store SLS MOB% TRA ACH%    | 150         | percent_1dp          | FALSE            |
| 16        | New Customer No                                        | 160         | integer              | FALSE            |
| 17        | New Customer No vs LY                                  | 170         | percent_1dp          | FALSE            |
| 18        | New Customer No TRA ACH%                               | 180         | percent_1dp          | FALSE            |
| 19        | Acceleration SLS                                       | 190         | currency             | TRUE             |
| 20        | Acceleration SLS vs LY                                 | 200         | percent_1dp          | FALSE            |
| 21        | Acceleration SLS TRA ACH%                              | 210         | percent_1dp          | FALSE            |
| 22        | Acceleration SLS MOB%                                  | 220         | percent_1dp          | FALSE            |
| 23        | Acceleration SLS MOB% vs LY                            | 230         | delta_bp             | FALSE            |
| 24        | Acceleration SLS MOB% TRA ACH%                         | 240         | percent_1dp          | FALSE            |

---

## 3. 方案设计

### 3.1 整体架构

```
核心思路：断开维度 + SWITCH 动态路由（Disconnected Dimensions + Dispatch Pattern）

Dim_ColMetric_KPIs（断开维度，列头）
    │
    │  无关系连接，仅通过 SELECTEDVALUE 读取 Metric_ID / Metric_Format
    │
    ▼
    ┌─────────────────── Matrix / 卡片图 视觉对象 ──────────────────┐
    │  列 = 'Dim_ColMetric_KPIs'[Metric_Name]                        │
    │  值 = [KPIs Cell Display]                                      │
    └────────────────────────────────────────────────────────────────┘
           ▲
           │
    SWITCH 动态路由度量值链
    ┌────────────────────────────────────────────────────┐
    │  [KPIs Cell Value]                                   │
    │    └→ [KPIs Base Value]（总路由）                     │
    │         ├→ [KPIs Current Base Value]（本期基础值）    │
    │         ├→ [KPIs vsLP Base Value]   （去年同期值）    │
    │         └→ vs LY / TRA ACH% 派生计算                │
    └────────────────────────────────────────────────────┘
```

### 3.2 度量值模型设计（拆分 Current / vsLP）

```
[KPIs Current Base Value]  ← 本期基础值（Metric_ID 1/2/3/5/6/7/9/10/12/13/15/16/18/19/21/22/24）
[KPIs vsLP Base Value]     ← 去年同期基础值（用于 vs LY 派生）
[KPIs Base Value]          ← 总路由（含 vs LY / TRA ACH% / Cost vs SLS ACH% 派生计算）
[KPIs Cell Value]          ← 对外值 = Base Value
[KPIs Cell Display]        ← 格式化显示文本
[KPIs Cell Font Color]     ← 字体颜色（仅 Cost vs SLS ACH% / SLS DCom / vs LY 指标启用条件色）
[KPIs Cell Background Color] ← 背景色（卡片场景统一白色 #FFFFFF）
[KPIs Cell SVG Icon]       ← SVG 图标（vs LY 类指标）
```

### 3.3 筛选器上下文

| 筛选器                    | 作用方式                                   | DAX 处理                            |
| ------------------------- | ------------------------------------------ | ----------------------------------- |
| Slicer_Time_Frame_Min     | 断开维度，SELECTEDVALUE 读取 TimeFrame_Min | `data_date >= __TimeMin`          |
| Slicer_Time_Frame_Max     | 断开维度，SELECTEDVALUE 读取 TimeFrame_Max | `data_date <= __TimeMax`          |
| Slicer_Platform_Selection | 1:N 关系，模型自动筛选                     | 无需显式处理                        |
| Slicer_Store_Name         | 1:N 关系，模型自动筛选                     | 无需显式处理                        |
| trans_cycle               | 1:N 关系，模型自动筛选                     | 无需显式处理                        |
| Slicer_Currency_Selection | 断开维度，SELECTEDVALUE 读取汇率和符号     | 金额类指标 × Currency_ExchangeRate |

### 3.4 vs LY 时间偏移规则

```
当前时间段：__TimeMin ~ __TimeMax（由 Slicer_Time_Frame_Min/Max 决定）
vs LY 时间段：EDATE(__TimeMin, -12) ~ EDATE(__TimeMax, -12)

示例：
  当前 2025-10-24 ~ 2025-10-31
  vs LY 2024-10-24 ~ 2024-10-31
```

---

## 4. 度量值实现

### 4.1 KPIs Current Base Value（本期基础值）

```dax
KPIs Current Base Value = 
// ========================================
// 度量值: KPIs Current Base Value
// Display Folder: Base Metrics
// 用途: 根据 Metric_ID 路由到本期（Current）基础值
// 依赖: 'Dim_ColMetric_KPIs'[Metric_ID], a05_e2e_paid_media_summary_d
// 口径来源: KPI Progress.md 子模块一（1~15）、子模块二（16~24）的本期值
// 筛选: customer_type='ALL' 或 'NEW'，page_type="1"
// ========================================
    VAR __MetricID = SELECTEDVALUE('Dim_ColMetric_KPIs'[Metric_ID])
    // ── 时间筛选：本期 ──
    VAR __TimeMin = SELECTEDVALUE(Slicer_Time_Frame_Min[TimeFrame_Min])
    VAR __TimeMax = SELECTEDVALUE(Slicer_Time_Frame_Max[TimeFrame_Max])
    // ── 汇率（金额类指标需要乘以汇率）──
    VAR __FXRate = SELECTEDVALUE(Slicer_Currency_Selection[Currency_ExchangeRate], 1)

    // ═══════════════════════════════════════
    // 基础聚合：ALL 口径（customer_type='ALL', page_type="1"）
    // ═══════════════════════════════════════
    // Cost = SUM(cost_amt)
    VAR __Cost_ALL = 
        CALCULATE(
            SUM('a05_e2e_paid_media_summary_d'[cost_amt]),
            'a05_e2e_paid_media_summary_d'[customer_type] = "ALL",
            'a05_e2e_paid_media_summary_d'[page_type] = "1",
            'a05_e2e_paid_media_summary_d'[data_date] >= __TimeMin,
            'a05_e2e_paid_media_summary_d'[data_date] <= __TimeMax
        )
    // 计划 Cost = SUM(fcst_cost_amt)
    VAR __FcstCost_ALL = 
        CALCULATE(
            SUM('a05_e2e_paid_media_summary_d'[fcst_cost_amt]),
            'a05_e2e_paid_media_summary_d'[customer_type] = "ALL",
            'a05_e2e_paid_media_summary_d'[page_type] = "1",
            'a05_e2e_paid_media_summary_d'[data_date] >= __TimeMin,
            'a05_e2e_paid_media_summary_d'[data_date] <= __TimeMax
        )
    // Net Sales = SUM(net_sales_amt)
    VAR __SLS_ALL = 
        CALCULATE(
            SUM('a05_e2e_paid_media_summary_d'[net_sales_amt]),
            'a05_e2e_paid_media_summary_d'[customer_type] = "ALL",
            'a05_e2e_paid_media_summary_d'[page_type] = "1",
            'a05_e2e_paid_media_summary_d'[data_date] >= __TimeMin,
            'a05_e2e_paid_media_summary_d'[data_date] <= __TimeMax
        )
    // 计划 Net Sales = SUM(fcst_net_sales_amt)
    VAR __FcstSLS_ALL = 
        CALCULATE(
            SUM('a05_e2e_paid_media_summary_d'[fcst_net_sales_amt]),
            'a05_e2e_paid_media_summary_d'[customer_type] = "ALL",
            'a05_e2e_paid_media_summary_d'[page_type] = "1",
            'a05_e2e_paid_media_summary_d'[data_date] >= __TimeMin,
            'a05_e2e_paid_media_summary_d'[data_date] <= __TimeMax
        )
    // Acceleration Cost = SUM(cost_amt), framework='Acceleration'
    VAR __AccelCost_ALL = 
        CALCULATE(
            SUM('a05_e2e_paid_media_summary_d'[cost_amt]),
            'a05_e2e_paid_media_summary_d'[customer_type] = "ALL",
            'a05_e2e_paid_media_summary_d'[page_type] = "1",
            'a05_e2e_paid_media_summary_d'[framework] = "Acceleration",
            'a05_e2e_paid_media_summary_d'[data_date] >= __TimeMin,
            'a05_e2e_paid_media_summary_d'[data_date] <= __TimeMax
        )
    // Acceleration SLS = SUM(net_sales_amt), framework='Acceleration'
    VAR __AccelSLS_ALL = 
        CALCULATE(
            SUM('a05_e2e_paid_media_summary_d'[net_sales_amt]),
            'a05_e2e_paid_media_summary_d'[customer_type] = "ALL",
            'a05_e2e_paid_media_summary_d'[page_type] = "1",
            'a05_e2e_paid_media_summary_d'[framework] = "Acceleration",
            'a05_e2e_paid_media_summary_d'[data_date] >= __TimeMin,
            'a05_e2e_paid_media_summary_d'[data_date] <= __TimeMax
        )

    // ═══════════════════════════════════════
    // 基础聚合：NEW 口径（customer_type='NEW', page_type="1"）
    // ═══════════════════════════════════════
    // Media New Customer = SUM(media_member_cnt)
    VAR __MediaNewCust_NEW = 
        CALCULATE(
            SUM('a05_e2e_paid_media_summary_d'[media_member_cnt]),
            'a05_e2e_paid_media_summary_d'[customer_type] = "NEW",
            'a05_e2e_paid_media_summary_d'[page_type] = "1",
            'a05_e2e_paid_media_summary_d'[data_date] >= __TimeMin,
            'a05_e2e_paid_media_summary_d'[data_date] <= __TimeMax
        )
    // Total New Customer = SUM(member_cnt)
    VAR __TotalNewCust_NEW = 
        CALCULATE(
            SUM('a05_e2e_paid_media_summary_d'[member_cnt]),
            'a05_e2e_paid_media_summary_d'[customer_type] = "NEW",
            'a05_e2e_paid_media_summary_d'[page_type] = "1",
            'a05_e2e_paid_media_summary_d'[data_date] >= __TimeMin,
            'a05_e2e_paid_media_summary_d'[data_date] <= __TimeMax
        )
    // Media New Cost = SUM(media_cost_amt)
    VAR __MediaNewCost_NEW = 
        CALCULATE(
            SUM('a05_e2e_paid_media_summary_d'[media_cost_amt]),
            'a05_e2e_paid_media_summary_d'[customer_type] = "NEW",
            'a05_e2e_paid_media_summary_d'[page_type] = "1",
            'a05_e2e_paid_media_summary_d'[data_date] >= __TimeMin,
            'a05_e2e_paid_media_summary_d'[data_date] <= __TimeMax
        )

    // ═══════════════════════════════════════
    // 派生指标
    // ═══════════════════════════════════════
    // Media Cost Rate = Cost / SLS × 1.13 / 1.06
    VAR __MediaCostRate = DIVIDE(__Cost_ALL, __SLS_ALL)
    // Cost ACH% = Cost / 计划 Cost
    VAR __CostACH = DIVIDE(__Cost_ALL, __FcstCost_ALL)
    // SLS ACH% = SLS / 计划 SLS
    VAR __SLSACH = DIVIDE(__SLS_ALL, __FcstSLS_ALL)
    // Acceleration Cost MOB% = Accel Cost / Total Cost
    VAR __AccelCostMOB = DIVIDE(__AccelCost_ALL, __Cost_ALL)
    // Store SLS MOB% = Accel SLS / Total SLS
    VAR __StoreSLSMOB = DIVIDE(__AccelSLS_ALL, __SLS_ALL)
    // ± Acceleration cost MOB% vs. store SLS MOB% = Accel Cost MOB% - Store SLS MOB%
    VAR __AccelCostMOBvsSLS = __AccelCostMOB - __StoreSLSMOB
    // Media Contribution to New Customer Acquisition% = Media New Cust / Total New Cust
    VAR __MediaNewCustContrib = DIVIDE(__MediaNewCust_NEW, __TotalNewCust_NEW)
    // Media Contribution TRA ACH% = 媒体新客贡献率 / 2（目标固定为 2）
    VAR __MediaNewCustContribACH = DIVIDE(__MediaNewCustContrib, 2)
    // Cost Per New Acquisition = Media New Cost / Media New Cust
    VAR __CostPerNewAcq = DIVIDE(__MediaNewCost_NEW, __MediaNewCust_NEW)
    // Cost Per New Acquisition TRA ACH% = Cost Per New Acq / 100（目标固定为 100）
    VAR __CostPerNewAcqACH = DIVIDE(__CostPerNewAcq, 100)
    // Acceleration SLS MOB% = Accel SLS / Total SLS（同 Store SLS MOB%）
    VAR __AccelSLSMOB = DIVIDE(__AccelSLS_ALL, __SLS_ALL)
    // ± Acceleration SLS MOB% vs. store SLS MOB% TRA ACH% = Accel SLS MOB% / 2（目标固定为 2）
    VAR __AccelSLSMOBvsSLS_ACH = DIVIDE(__AccelSLSMOB, 2)
    // New Customer No TRA ACH% = 新客数量 / 1（分子分母暂时固定为 1）
    VAR __NewCustNoACH = DIVIDE(1, 1)
    // Acceleration SLS TRA ACH% = Accel SLS / 10000（目标固定为 10000）
    VAR __AccelSLSACH = DIVIDE(__AccelSLS_ALL, 10000)
    // Acceleration SLS MOB% TRA ACH% = Accel SLS MOB% / 2（目标固定为 2）
    VAR __AccelSLSMOBACH = DIVIDE(__AccelSLSMOB, 2)

    RETURN
        SWITCH(
            __MetricID,
            // ─── 子模块一：KPIs（1~15）本期值 ───
            1,  DIVIDE(__MediaCostRate * 1.13 , 1.06),                       // Media Cost Rate
            2,  __Cost_ALL * __FXRate,                 // Media Cost（金额×汇率）
            3,  __CostACH,                             // Cost ACH%
            // 4 Cost vs SLS ACH% 在 Base Value 中派生（Cost ACH% − SLS ACH%）
            5,  __SLSACH,                              // SLS ACH%
            6,  __SLS_ALL * __FXRate,                  // SLS DCom（金额×汇率）
            7,  __MediaNewCustContrib,                 // Media Contribution to New Customer Acquisition%
            // 8 Media Contribution vs LY 在 Base Value 中派生（本期 − 去年同期，bp）
            9,  __MediaNewCustContribACH,              // Media Contribution TRA ACH%
            10, __CostPerNewAcq * __FXRate,            // Media Cost Per New Acquisition（金额×汇率）
            // 11 Media Cost Per New Acquisition vs LY 在 Base Value 中派生（本期/同期−1）
            12, __CostPerNewAcqACH,                    // Media Cost Per New Acquisition TRA ACH%
            13, __AccelCostMOBvsSLS,                   // ± Acceleration cost MOB% vs. store SLS MOB%
            // 14 ± Accel cost MOB% vs LY 在 Base Value 中派生（本期 − 去年同期，bp）
            15, __AccelSLSMOBvsSLS_ACH,                // ± Acceleration SLS MOB% vs. store SLS MOB% TRA ACH%
            // ─── 子模块二：Performance Indicators（16~24）本期值 ───
            16, 1,                                     // New Customer No（暂时固定为 1，待口径补充）
            // 17 New Customer No vs LY 在 Base Value 中派生（本期/同期−1）
            18, __NewCustNoACH,                        // New Customer No TRA ACH%
            19, __AccelSLS_ALL * __FXRate,             // Acceleration SLS（金额×汇率）
            // 20 Acceleration SLS vs LY 在 Base Value 中派生（本期/同期−1）
            21, __AccelSLSACH,                         // Acceleration SLS TRA ACH%
            22, __AccelSLSMOB,                         // Acceleration SLS MOB%
            // 23 Acceleration SLS MOB% vs LY 在 Base Value 中派生（本期占比 − 去年同期占比，bp）
            24, __AccelSLSMOBACH,                      // Acceleration SLS MOB% TRA ACH%
            BLANK()
        )
```

### 4.2 KPIs vsLP Base Value（去年同期基础值）

```dax
KPIs vsLP Base Value = 
// ========================================
// 度量值: KPIs vsLP Base Value
// Display Folder: Base Metrics
// 用途: 根据 Metric_ID 路由到去年同期（vs LY）基础值，用于派生 vs LY 指标
// 依赖: 'Dim_ColMetric_KPIs'[Metric_ID], a05_e2e_paid_media_summary_d
// 口径来源: KPI Progress.md 子模块一、二 vs LY 行
// 说明: vs LY = 当前时间段往前推一年（EDATE -12 个月）
//       例如：当前 2025-10-24 ~ 2025-10-31，vs LY = 2024-10-24 ~ 2024-10-31
// ========================================
    VAR __MetricID = SELECTEDVALUE('Dim_ColMetric_KPIs'[Metric_ID])
    // ── 时间筛选：去年同期，往前推一年 ──
    VAR __TimeMin = SELECTEDVALUE(Slicer_Time_Frame_Min[TimeFrame_Min])
    VAR __TimeMax = SELECTEDVALUE(Slicer_Time_Frame_Max[TimeFrame_Max])
    VAR __LPTimeMin = EDATE(__TimeMin, -12)
    VAR __LPTimeMax = EDATE(__TimeMax, -12)
    // ── 汇率 ──
    VAR __FXRate = SELECTEDVALUE(Slicer_Currency_Selection[Currency_ExchangeRate], 1)

    // ═══════════════════════════════════════
    // 基础聚合：ALL 口径（去年同期）
    // ═══════════════════════════════════════
    VAR __Cost_ALL = 
        CALCULATE(
            SUM('a05_e2e_paid_media_summary_d'[cost_amt]),
            'a05_e2e_paid_media_summary_d'[customer_type] = "ALL",
            'a05_e2e_paid_media_summary_d'[page_type] = "1",
            'a05_e2e_paid_media_summary_d'[data_date] >= __LPTimeMin,
            'a05_e2e_paid_media_summary_d'[data_date] <= __LPTimeMax
        )
    VAR __SLS_ALL = 
        CALCULATE(
            SUM('a05_e2e_paid_media_summary_d'[net_sales_amt]),
            'a05_e2e_paid_media_summary_d'[customer_type] = "ALL",
            'a05_e2e_paid_media_summary_d'[page_type] = "1",
            'a05_e2e_paid_media_summary_d'[data_date] >= __LPTimeMin,
            'a05_e2e_paid_media_summary_d'[data_date] <= __LPTimeMax
        )
    VAR __AccelCost_ALL = 
        CALCULATE(
            SUM('a05_e2e_paid_media_summary_d'[cost_amt]),
            'a05_e2e_paid_media_summary_d'[customer_type] = "ALL",
            'a05_e2e_paid_media_summary_d'[page_type] = "1",
            'a05_e2e_paid_media_summary_d'[framework] = "Acceleration",
            'a05_e2e_paid_media_summary_d'[data_date] >= __LPTimeMin,
            'a05_e2e_paid_media_summary_d'[data_date] <= __LPTimeMax
        )
    VAR __AccelSLS_ALL = 
        CALCULATE(
            SUM('a05_e2e_paid_media_summary_d'[net_sales_amt]),
            'a05_e2e_paid_media_summary_d'[customer_type] = "ALL",
            'a05_e2e_paid_media_summary_d'[page_type] = "1",
            'a05_e2e_paid_media_summary_d'[framework] = "Acceleration",
            'a05_e2e_paid_media_summary_d'[data_date] >= __LPTimeMin,
            'a05_e2e_paid_media_summary_d'[data_date] <= __LPTimeMax
        )

    // ═══════════════════════════════════════
    // 基础聚合：NEW 口径（去年同期）
    // ═══════════════════════════════════════
    VAR __MediaNewCust_NEW = 
        CALCULATE(
            SUM('a05_e2e_paid_media_summary_d'[media_member_cnt]),
            'a05_e2e_paid_media_summary_d'[customer_type] = "NEW",
            'a05_e2e_paid_media_summary_d'[page_type] = "1",
            'a05_e2e_paid_media_summary_d'[data_date] >= __LPTimeMin,
            'a05_e2e_paid_media_summary_d'[data_date] <= __LPTimeMax
        )
    VAR __TotalNewCust_NEW = 
        CALCULATE(
            SUM('a05_e2e_paid_media_summary_d'[member_cnt]),
            'a05_e2e_paid_media_summary_d'[customer_type] = "NEW",
            'a05_e2e_paid_media_summary_d'[page_type] = "1",
            'a05_e2e_paid_media_summary_d'[data_date] >= __LPTimeMin,
            'a05_e2e_paid_media_summary_d'[data_date] <= __LPTimeMax
        )
    VAR __MediaNewCost_NEW = 
        CALCULATE(
            SUM('a05_e2e_paid_media_summary_d'[media_cost_amt]),
            'a05_e2e_paid_media_summary_d'[customer_type] = "NEW",
            'a05_e2e_paid_media_summary_d'[page_type] = "1",
            'a05_e2e_paid_media_summary_d'[data_date] >= __LPTimeMin,
            'a05_e2e_paid_media_summary_d'[data_date] <= __LPTimeMax
        )

    // ═══════════════════════════════════════
    // 派生指标（去年同期）
    // ═══════════════════════════════════════
    VAR __MediaCostRate =  DIVIDE(DIVIDE(__Cost_ALL, __SLS_ALL) * 1.13 , 1.06)
    VAR __AccelCostMOB = DIVIDE(__AccelCost_ALL, __Cost_ALL)
    VAR __StoreSLSMOB = DIVIDE(__AccelSLS_ALL, __SLS_ALL)
    VAR __AccelCostMOBvsSLS = __AccelCostMOB - __StoreSLSMOB
    VAR __MediaNewCustContrib = DIVIDE(__MediaNewCust_NEW, __TotalNewCust_NEW)
    VAR __CostPerNewAcq = DIVIDE(__MediaNewCost_NEW, __MediaNewCust_NEW)
    VAR __AccelSLSMOB = DIVIDE(__AccelSLS_ALL, __SLS_ALL)

    RETURN
        SWITCH(
            __MetricID,
            // ─── vs LY 派生所需的去年同期基础值（按 vs LY 指标 ID 路由）───
            8,  __MediaNewCustContrib,                 // #8 vs LY：媒体新客贡献率（本期 − 同期，bp）
            11, __CostPerNewAcq,                       // #11 vs LY：获客成本（本期/同期 − 1）
            14, __AccelCostMOBvsSLS,                   // #14 vs LY：± Accel cost MOB%（本期 − 同期，bp）
            17, 1,                                     // #17 vs LY：新客数量（本期/同期 − 1，分子暂时固定 1）
            20, __AccelSLS_ALL * __FXRate,             // #20 vs LY：Acceleration SLS（本期/同期 − 1）
            23, __AccelSLSMOB,                         // #23 vs LY：Acceleration SLS MOB%（本期占比 − 同期占比，bp）
            BLANK()
        )
```

### 4.3 KPIs Base Value（总路由）

```dax
KPIs Base Value = 
// ========================================
// 度量值: KPIs Base Value
// Display Folder: Base Metrics
// 用途: 总路由，根据 Metric_ID 分发到 Current / vs LY / TRA ACH% / 派生差值
// 依赖: [KPIs Current Base Value], [KPIs vsLP Base Value]
// 说明:
//   本期值 Metric_ID: 1,2,3,5,6,7,9,10,12,13,15,16,18,19,21,22,24
//   vs LY（增长率/差值）Metric_ID: 8,11,14,17,20,23
//   Cost vs SLS ACH%（派生差值）Metric_ID: 4 = Cost ACH% − SLS ACH%
// ========================================
    VAR __MetricID = SELECTEDVALUE('Dim_ColMetric_KPIs'[Metric_ID])

    // ── 修复上下文冲突：vs LY 派生行需读取对应本期和同期的 Metric_ID ──
    // vs LY 行（8/11/14/17/20/23）调用 Current/vsLP 时，需要切换到对应本期指标的 Metric_ID
    //   #8  vs LY（媒体新客贡献率）   → 本期 #7  / 同期 #7
    //   #11 vs LY（获客成本）         → 本期 #10 / 同期 #10
    //   #14 vs LY（± Accel cost MOB%）→ 本期 #13 / 同期 #13
    //   #17 vs LY（新客数量）         → 本期 #16 / 同期 #16
    //   #20 vs LY（Acceleration SLS） → 本期 #19 / 同期 #19
    //   #23 vs LY（Accel SLS MOB%）   → 本期 #22 / 同期 #22
    VAR __IsVSLY = __MetricID IN {8, 11, 14, 17, 20, 23}
    // vs LY 行对应的本期指标 ID 映射
    VAR __CurrentMetricID =
        SWITCH(
            __MetricID,
            8,  7,
            11, 10,
            14, 13,
            17, 16,
            20, 19,
            23, 22,
            __MetricID
        )

    // ── 取本期值（vs LY 行需切换 Metric_ID）──
    VAR __CurrentValue =
        IF(
            __IsVSLY,
            CALCULATE(
                [KPIs Current Base Value],
                REMOVEFILTERS('Dim_ColMetric_KPIs'),
                'Dim_ColMetric_KPIs'[Metric_ID] = __CurrentMetricID
            ),
            [KPIs Current Base Value]
        )

    // ── 取去年同期值（vs LY 行需切换 Metric_ID，并在 vsLP 度量里按 vs LY 的 ID 路由）──
    // vsLP 度量内部已按 vs LY 的 Metric_ID（8/11/14/17/20/23）路由返回同期基础值
    VAR __LPValue =
        IF(
            __IsVSLY,
            [KPIs vsLP Base Value],
            BLANK()
        )

    // ── vs LY 派生计算 ──
    // #8/#14/#23 → 当期值 − 同期值（差值，bp 指标，展示时 ×100 转 bp）
    // #11/#17/#20 → 当期值 / 同期值 − 1（增长率，百分比）
    VAR __VSLYDiff = __CurrentValue - __LPValue
    VAR __VSLYGrowth =
        IF(
            ISBLANK(__LPValue) || __LPValue = 0,
            BLANK(),
            DIVIDE(__CurrentValue - __LPValue, __LPValue)
        )

    // ── Cost vs SLS ACH% 派生（#4 = #3 Cost ACH% − #5 SLS ACH%）──
    VAR __CostACH =
        CALCULATE(
            [KPIs Current Base Value],
            REMOVEFILTERS('Dim_ColMetric_KPIs'),
            'Dim_ColMetric_KPIs'[Metric_ID] = 3
        )
    VAR __SLSACH =
        CALCULATE(
            [KPIs Current Base Value],
            REMOVEFILTERS('Dim_ColMetric_KPIs'),
            'Dim_ColMetric_KPIs'[Metric_ID] = 5
        )
    VAR __CostVsSLSACH = __CostACH - __SLSACH

    RETURN
        SWITCH(
            __MetricID,
            // ─── 本期值（直接返回 Current）───
            1,  __CurrentValue,    // Media Cost Rate
            2,  __CurrentValue,    // Media Cost
            3,  __CurrentValue,    // Cost ACH%
            5,  __CurrentValue,    // SLS ACH%
            6,  __CurrentValue,    // SLS DCom
            7,  __CurrentValue,    // Media Contribution to New Customer Acquisition%
            9,  __CurrentValue,    // Media Contribution TRA ACH%
            10, __CurrentValue,    // Media Cost Per New Acquisition
            12, __CurrentValue,    // Media Cost Per New Acquisition TRA ACH%
            13, __CurrentValue,    // ± Acceleration cost MOB% vs. store SLS MOB%
            15, __CurrentValue,    // ± Acceleration SLS MOB% vs. store SLS MOB% TRA ACH%
            16, __CurrentValue,    // New Customer No
            18, __CurrentValue,    // New Customer No TRA ACH%
            19, __CurrentValue,    // Acceleration SLS
            21, __CurrentValue,    // Acceleration SLS TRA ACH%
            22, __CurrentValue,    // Acceleration SLS MOB%
            24, __CurrentValue,    // Acceleration SLS MOB% TRA ACH%
            // ─── 派生差值 ───
            4,  __CostVsSLSACH,    // Cost vs SLS ACH% = Cost ACH% − SLS ACH%
            // ─── vs LY（差值 bp）───
            8,  __VSLYDiff,        // Media Contribution vs LY（本期 − 同期）
            14, __VSLYDiff,        // ± Accel cost MOB% vs LY（本期 − 同期）
            23, __VSLYDiff,        // Acceleration SLS MOB% vs LY（本期占比 − 同期占比）
            // ─── vs LY（增长率 %）───
            11, __VSLYGrowth,      // Media Cost Per New Acquisition vs LY（本期/同期 − 1）
            17, __VSLYGrowth,      // New Customer No vs LY（本期/同期 − 1）
            20, __VSLYGrowth,      // Acceleration SLS vs LY（本期/同期 − 1）
            BLANK()
        )
```

### 4.4 KPIs Cell Value（对外值）

```dax
KPIs Cell Value = 
// ========================================
// 度量值: KPIs Cell Value
// Display Folder: Cell Values
// 用途: 对外暴露的单元格值，等于 Base Value
// 依赖: [KPIs Base Value]
// ========================================
    [KPIs Base Value]
```

### 4.5 KPIs Cell Display（格式化显示）

```dax
KPIs Cell Display = 
// ========================================
// 度量值: KPIs Cell Display
// Display Folder: Formatting
// 用途: 根据 Metric_Format 返回格式化后的文本
// 依赖: [KPIs Cell Value], 'Dim_ColMetric_KPIs'[Metric_Format]
// 格式类型（严格遵循口径文档 KPI Progress.md 数据类型定义）:
//   currency              → 货币符号 + 千分位整数：¥1,000      格式串: #,##0
//   currency_decimal_1dp  → 货币符号 + 千分位一位小数：¥1,000.0  格式串: #,##0.0
//   integer               → 整数千分位：1,000                    格式串: #,##0
//   percent_1dp           → 百分比一位小数，不含正号：14.5%       格式串: #,##0.0%;#,##0.0%;0.0%
//   delta_bp              → 增减基点整数，含正负号：+120bp        格式串: +#,##0bp;-#,##0bp;0bp
//                           （值×100 转 bp 的操作在此处实现）
// ========================================
    VAR __Value = [KPIs Cell Value]
    VAR __Format = SELECTEDVALUE('Dim_ColMetric_KPIs'[Metric_Format])
    VAR __CurrencySymbol = SELECTEDVALUE(Slicer_Currency_Selection[Currency_Symbol], "¥")
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            SWITCH(
                __Format,
                // ─── 货币（符号由币种切片器决定）─────────────
                "currency",
                    __CurrencySymbol & FORMAT(__Value, "#,##0"),                          // ¥1,000
                "currency_decimal_1dp",
                    __CurrencySymbol & FORMAT(__Value, "#,##0.0"),                        // ¥1,000.0
                // ─── 整数 ─────────────────────────────────
                "integer",
                    FORMAT(__Value, "#,##0"),                                             // 1,000
                // ─── 百分比（不含正号）──────────────────────
                "percent_1dp",
                    FORMAT(__Value, "#,##0.0%;#,##0.0%;0.0%"),                            // 14.5%
                // ─── 增减基点（含正负号，值×100 转 bp）─────
                "delta_bp",
                    IF(ROUND(__Value * 100, 0) > 0, "+", "") & FORMAT(__Value * 100, "#,##0bp;-#,##0bp;0bp"), // +120bp
                // ─── 默认 ─────────────────────────────────
                FORMAT(__Value, "#,##0.00")
            )
        )
```

### 4.6 KPIs Cell Font Color（字体颜色）

```dax
KPIs Cell Font Color = 
// ========================================
// 度量值: KPIs Cell Font Color
// Display Folder: Formatting
// 用途: 仅对 Cost vs SLS ACH%、SLS DCom 以及所有 vs LY 指标启用正/负/零三色
//       其余指标统一使用 #252423（近黑）
// 依赖: [KPIs Cell Value], 'Dim_ColMetric_KPIs'[Metric_ID]
// 颜色取值: 正值 #1A9018（绿）/ 负值 #D64550（红）/ 零值 #E1C233（黄）/ 默认 #252423（近黑）
// 启用条件色的 Metric_ID 清单:
//   4  Cost vs SLS ACH%
//   6  SLS DCom
//   8  Media Contribution to New Customer Acquisition% vs LY
//   11 Media Cost Per New Acquisition vs LY
//   14 ± Acceleration cost MOB% vs. store SLS MOB% vs LY
//   17 New Customer No vs LY
//   20 Acceleration SLS vs LY
//   23 Acceleration SLS MOB% vs LY
// ========================================
    VAR __Value = [KPIs Cell Value]
    VAR __MetricID = SELECTEDVALUE('Dim_ColMetric_KPIs'[Metric_ID])
    VAR __EnableColor = __MetricID IN {4, 6, 8, 11, 14, 17, 20, 23}
    RETURN
        SWITCH(
            TRUE(),
            NOT __EnableColor,                 "#252423",   // 其余指标：近黑
            ISBLANK(__Value),                  "#252423",   // 空值：近黑
            __Value > 0,                       "#1A9018",   // 正值：绿
            __Value < 0,                       "#D64550",   // 负值：红
            __Value = 0,                       "#E1C233",   // 零值：黄
            "#252423"                                       // 兜底：近黑
        )
```

### 4.7 KPIs Cell Background Color（背景色）

```dax
KPIs Cell Background Color = 
// ========================================
// 度量值: KPIs Cell Background Color
// Display Folder: Formatting
// 用途: 卡片图/矩阵场景统一背景色
// 说明: 本模块为"无分组维度"卡片图，无总计行区分，统一使用白色 #FFFFFF
// ========================================
    "#FFFFFF"
```

### 4.8 KPIs Cell SVG Icon（SVG 图标）

```dax
KPIs Cell SVG Icon = 
// ========================================
// 度量值: KPIs Cell SVG Icon
// Display Folder: Formatting
// 用途: 仅 vs LY 指标（delta_bp / percent_1dp 增减类）返回 SVG 圆形图标
// 依赖: [KPIs Cell Value], 'Dim_ColMetric_KPIs'[Metric_ID]
// 配置: 需将此度量值的数据类别设为"图像 URL"
// 图标规则:
//   正值 → 绿色圆 #1A9018
//   负值 → 红色圆 #D64550
//   零值 → 黄色圆 #E1C233
// 启用图标 Metric_ID: 8, 11, 14, 17, 20, 23（全部 vs LY 指标）
// ========================================
    VAR __Value = [KPIs Cell Value]
    VAR __MetricID = SELECTEDVALUE('Dim_ColMetric_KPIs'[Metric_ID])
    VAR __NeedsIcon = __MetricID IN {8, 11, 14, 17, 20, 23}
    VAR __GreenSVG =
        "data:image/svg+xml;utf8," &
        "<svg xmlns='http://www.w3.org/2000/svg' width='16' height='16'>" &
        "<circle cx='8' cy='8' r='7' fill='%231A9018'/></svg>"
    VAR __RedSVG =
        "data:image/svg+xml;utf8," &
        "<svg xmlns='http://www.w3.org/2000/svg' width='16' height='16'>" &
        "<circle cx='8' cy='8' r='7' fill='%23D64550'/></svg>"
    VAR __YellowSVG =
        "data:image/svg+xml;utf8," &
        "<svg xmlns='http://www.w3.org/2000/svg' width='16' height='16'>" &
        "<circle cx='8' cy='8' r='7' fill='%23E1C233'/></svg>"
    RETURN
        SWITCH(
            TRUE(),
            NOT __NeedsIcon,                 BLANK(),
            ISBLANK(__Value),                BLANK(),
            __Value > 0,                     __GreenSVG,    // 正值 → 绿
            __Value < 0,                     __RedSVG,      // 负值 → 红
            __Value = 0,                     __YellowSVG,   // 零值 → 黄
            BLANK()
        )
```

---

## 5. 度量值清单与 Display Folder

| 序号 | 度量值名称                  | Display Folder | 用途                                              |
| ---- | --------------------------- | -------------- | ------------------------------------------------- |
| 1    | KPIs Current Base Value     | Base Metrics   | 本期基础值（17 个本期 Metric_ID）                 |
| 2    | KPIs vsLP Base Value        | Base Metrics   | 去年同期基础值（6 个 vs LY 派生所需）             |
| 3    | KPIs Base Value             | Base Metrics   | 总路由（含 vs LY / TRA ACH% / Cost vs SLS 派生）  |
| 4    | KPIs Cell Value             | Cell Values    | 对外值 = Base Value                               |
| 5    | KPIs Cell Display           | Formatting     | 格式化显示文本                                    |
| 6    | KPIs Cell Font Color        | Formatting     | 字体颜色（仅 8 个指标启用条件色）                 |
| 7    | KPIs Cell Background Color  | Formatting     | 背景色（统一白色）                                |
| 8    | KPIs Cell SVG Icon          | Formatting     | SVG 图标（仅 6 个 vs LY 指标）                    |

---

## 6. 指标口径来源对照

| Metric_ID | Metric_Name                                            | 口径文档出处   | 计算公式                                                  | 统计字段                                                            | customer_type | framework           | 数据类型            |
| --------- | ------------------------------------------------------ | -------------- | --------------------------------------------------------- | ------------------------------------------------------------------- | ------------- | ------------------- | ------------------- |
| 1         | Media Cost Rate                                        | 子模块一 §1    | Cost / SLS × 1.13 / 1.06                                  | cost_amt / net_sales_amt                                            | ALL           | -                   | percent_1dp         |
| 2         | Media Cost                                             | 子模块一 §2    | SUM(cost_amt)                                             | cost_amt                                                            | ALL           | -                   | currency            |
| 3         | Cost ACH%                                              | 子模块一 §3    | Cost / 计划 Cost                                          | cost_amt / fcst_cost_amt                                            | ALL           | -                   | percent_1dp         |
| 4         | Cost vs SLS ACH%                                       | 子模块一 §4    | Cost ACH% − SLS ACH%                                      | 派生（#3 − #5）                                                     | ALL           | -                   | delta_bp            |
| 5         | SLS ACH%                                               | 子模块一 §5    | SLS / 计划 SLS                                            | net_sales_amt / fcst_net_sales_amt                                  | ALL           | -                   | percent_1dp         |
| 6         | SLS DCom                                               | 子模块一 §6    | SUM(net_sales_amt)                                        | net_sales_amt                                                       | ALL           | -                   | currency            |
| 7         | Media Contribution to New Customer Acquisition%        | 子模块一 §7    | 媒体新客数 / 全店新客数                                  | media_member_cnt / member_cnt                                       | NEW           | -                   | percent_1dp         |
| 8         | Media Contribution to New Customer Acquisition% vs LY  | 子模块一 §8    | 当期值 − 去年同期值（bp）                                 | 派生（#7 当期 − #7 同期）                                           | NEW           | -                   | delta_bp            |
| 9         | Media Contribution to New Customer Acquisition% TRA ACH% | 子模块一 §9  | 媒体新客贡献率 / 2                                        | media_member_cnt / member_cnt / 2                                   | NEW           | -                   | percent_1dp         |
| 10        | Media Cost Per New Acquisition                         | 子模块一 §10   | 新客花费 / 媒体新客数                                    | media_cost_amt / media_member_cnt                                   | NEW           | -                   | currency_decimal_1dp |
| 11        | Media Cost Per New Acquisition vs LY                   | 子模块一 §11   | 当期值 / 去年同期值 − 1                                   | 派生（#10 当期 / #10 同期 − 1）                                     | NEW           | -                   | percent_1dp         |
| 12        | Media Cost Per New Acquisition TRA ACH%                | 子模块一 §12   | 获客成本 / 100                                            | media_cost_amt / media_member_cnt / 100                             | NEW           | -                   | percent_1dp         |
| 13        | ± Acceleration cost MOB% vs. store SLS MOB%            | 子模块一 §13   | Accel Cost MOB% − Store SLS MOB%                          | cost_amt(Accel)/cost_amt(全部) − net_sales_amt(Accel)/net_sales_amt(全部) | ALL | Acceleration + 全部 | percent_1dp         |
| 14        | ± Acceleration cost MOB% vs. store SLS MOB% vs LY      | 子模块一 §14   | 当期值 − 去年同期值（bp）                                 | 派生（#13 当期 − #13 同期）                                         | ALL           | Acceleration + 全部 | delta_bp            |
| 15        | ± Acceleration SLS MOB% vs. store SLS MOB% TRA ACH%    | 子模块一 §15   | Accel SLS MOB% / 2                                        | net_sales_amt(Accel)/net_sales_amt(全部) / 2                        | ALL           | Acceleration + 全部 | percent_1dp         |
| 16        | New Customer No                                        | 子模块二 §16   | COUNT DISTINCT 买家id（暂时固定 1）                       | 1                                                                   | NEW           | -                   | integer             |
| 17        | New Customer No vs LY                                  | 子模块二 §17   | 当期值 / 去年同期值 − 1                                   | 派生（#16 当期 / #16 同期 − 1）                                     | NEW           | -                   | percent_1dp         |
| 18        | New Customer No TRA ACH%                               | 子模块二 §18   | 新客数量 / 1（目标固定 1）                                | 1 / 1                                                               | NEW           | -                   | percent_1dp         |
| 19        | Acceleration SLS                                       | 子模块二 §19   | SUM(net_sales_amt) framework='Acceleration'               | net_sales_amt                                                       | ALL           | Acceleration        | currency            |
| 20        | Acceleration SLS vs LY                                 | 子模块二 §20   | 当期值 / 去年同期值 − 1                                   | 派生（#19 当期 / #19 同期 − 1）                                     | ALL           | Acceleration        | percent_1dp         |
| 21        | Acceleration SLS TRA ACH%                              | 子模块二 §21   | Accel SLS / 10000                                         | net_sales_amt(Accel) / 10000                                        | ALL           | Acceleration        | percent_1dp         |
| 22        | Acceleration SLS MOB%                                  | 子模块二 §22   | Accel SLS / TTL SLS                                       | net_sales_amt(Accel) / net_sales_amt(全部)                          | ALL           | Acceleration + 全部 | percent_1dp         |
| 23        | Acceleration SLS MOB% vs LY                            | 子模块二 §23   | 当期占比 − 去年同期占比（bp）                             | 派生（#22 当期 − #22 同期）                                         | ALL           | Acceleration + 全部 | delta_bp            |
| 24        | Acceleration SLS MOB% TRA ACH%                         | 子模块二 §24   | Accel SLS MOB% / 2                                        | net_sales_amt(Accel)/net_sales_amt(全部) / 2                        | ALL           | Acceleration + 全部 | percent_1dp         |

---

## 7. 血缘关系图（Lineage Diagram）

```
┌─────────────────────────────────────────────────────────────────────┐
│                        数据源层                                      │
│  a05_e2e_paid_media_summary_d（事实表）                              │
│  字段: data_date, platform, store_name, trans_cycle,                │
│        customer_type, page_type, framework,                         │
│        cost_amt, fcst_cost_amt, net_sales_amt, fcst_net_sales_amt,  │
│        media_member_cnt, member_cnt, media_cost_amt                 │
└──────────────────────────────┬──────────────────────────────────────┘
                               │
                               │ 1:N 关系（模型自动筛选）
                               │
              ┌────────────────┼────────────────┐
              │                │                │
              ▼                ▼                ▼
┌──────────────────┐ ┌──────────────────┐ ┌──────────────────┐
│ Slicer_Platform_  │ │ Slicer_Store_    │ │ trans_cycle     │
│ Selection         │ │ Name             │ │ 筛选器           │
│ (Platform_ID)     │ │ (Store_ID)       │ │ (trans_cycle)   │
└──────────────────┘ └──────────────────┘ └──────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│                        度量值层                                      │
│                                                                     │
│  ┌─────────────────────────┐   ┌─────────────────────────┐          │
│  │ KPIs Current Base Value │   │ KPIs vsLP Base Value    │          │
│  │ (本期 17 个 Metric_ID)   │   │ (同期 6 个 vs LY 派生)   │          │
│  └───────────┬─────────────┘   └───────────┬─────────────┘          │
│              │                              │                        │
│              │    ┌─────────────────────────┘                        │
│              │    │                                                  │
│              ▼    ▼                                                  │
│  ┌─────────────────────────┐   ┌─────────────────────────┐          │
│  │ KPIs Base Value         │   │ Slicer_Time_Frame_Min   │          │
│  │ (总路由 + vs LY/ACH 派生)│◄──│ Slicer_Time_Frame_Max   │          │
│  └───────────┬─────────────┘   │ (断开维度，SELECTEDVALUE)│          │
│              │                  └─────────────────────────┘          │
│              │ EDATE(-12) 用于 vsLP                                  │
│              ▼                                                      │
│  ┌─────────────────────────┐   ┌─────────────────────────┐          │
│  │ KPIs Cell Value         │◄──│ Slicer_Currency_        │          │
│  │ (= Base Value)          │   │ Selection               │          │
│  └───────────┬─────────────┘   │ (断开维度，汇率×金额)    │          │
│              │                  └─────────────────────────┘          │
│              ▼                                                      │
│  ┌─────────────────────────┐   ┌─────────────────────────┐          │
│  │ KPIs Cell Display       │◄──│ 'Dim_ColMetric_KPIs'    │          │
│  │ (格式化文本)             │   │ (断开维度，Metric_Format)│         │
│  └───────────┬─────────────┘   └─────────────────────────┘          │
│              │                                                      │
│              ▼                                                      │
│  ┌─────────────────────────────────────────────────┐                │
│  │  KPIs Cell Font Color                            │                │
│  │  KPIs Cell Background Color                      │                │
│  │  KPIs Cell SVG Icon                              │                │
│  │  (条件格式度量值)                                 │                │
│  └─────────────────────────────────────────────────┘                │
└─────────────────────────────────────────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────────┐
│                        可视化层                                      │
│  卡片图 / Matrix 视觉对象                                            │
│  列: 'Dim_ColMetric_KPIs'[Metric_Name]                              │
│  值: [KPIs Cell Display]                                             │
│  条件格式:                                                           │
│    字体颜色 → [KPIs Cell Font Color]                                │
│    背景色   → [KPIs Cell Background Color]                          │
│    SVG 图标 → [KPIs Cell SVG Icon]（数据类别=图像 URL）              │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 8. 关键设计说明

### 8.1 vs LY 派生计算分类

| Metric_ID | 指标名                              | 派生方式              | 数据类型   |
| --------- | ----------------------------------- | --------------------- | ---------- |
| 8         | Media Contribution vs LY            | 当期值 − 同期值（bp） | delta_bp   |
| 11        | Media Cost Per New Acquisition vs LY | 当期/同期 − 1（%）    | percent_1dp |
| 14        | ± Accel cost MOB% vs LY             | 当期值 − 同期值（bp） | delta_bp   |
| 17        | New Customer No vs LY               | 当期/同期 − 1（%）    | percent_1dp |
| 20        | Acceleration SLS vs LY              | 当期/同期 − 1（%）    | percent_1dp |
| 23        | Acceleration SLS MOB% vs LY         | 当期占比 − 同期占比（bp） | delta_bp   |

### 8.2 暂时固定值指标（待口径补充）

| Metric_ID | 指标名                              | 固定值            | 说明           |
| --------- | ----------------------------------- | ----------------- | -------------- |
| 16        | New Customer No                     | 1                 | 待补充实际口径 |
| 18        | New Customer No TRA ACH%            | 1/1               | 目标固定为 1   |
| 9         | Media Contribution TRA ACH%         | 贡献率 / 2        | 目标固定为 2   |
| 12        | Media Cost Per New Acquisition TRA ACH% | 获客成本 / 100 | 目标固定为 100 |
| 15        | ± Accel SLS MOB% vs store SLS TRA ACH% | MOB% / 2       | 目标固定为 2   |
| 21        | Acceleration SLS TRA ACH%           | Accel SLS / 10000 | 目标固定为 10000 |
| 24        | Acceleration SLS MOB% TRA ACH%      | MOB% / 2          | 目标固定为 2   |

### 8.3 筛选器公用说明

本模块与 Category Growth/KPI_Breakdown 共用筛选器：

- **Slicer_Time_Frame_Min/Max**：断开维度，SELECTEDVALUE 读取时间范围
- **Slicer_Platform_Selection**：1:N 关系，模型自动筛选
- **Slicer_Store_Name**：1:N 关系，模型自动筛选
- **Slicer_Currency_Selection**：断开维度，仅金额类指标（`Metric_IsCurrencyAmount=TRUE`）乘以 `Currency_ExchangeRate`，非金额类指标不受汇率影响
- **trans_cycle**：1:N 关系，模型自动筛选

### 8.4 字体颜色启用清单

仅以下 8 个 Metric_ID 启用正/负/零三色条件格式，其余统一 `#252423`：

- `4` Cost vs SLS ACH%（delta_bp）
- `6` SLS DCom（currency）
- `8` Media Contribution vs LY（delta_bp）
- `11` Media Cost Per New Acquisition vs LY（percent_1dp）
- `14` ± Accel cost MOB% vs LY（delta_bp）
- `17` New Customer No vs LY（percent_1dp）
- `20` Acceleration SLS vs LY（percent_1dp）
- `23` Acceleration SLS MOB% vs LY（delta_bp）

颜色值：正值 `#1A9018` / 负值 `#D64550` / 零值 `#E1C233` / 默认 `#252423`。

---

## 9. 验证方法

### 9.1 占位值验证

| 验证项         | 方法                                                                                       |
| -------------- | ------------------------------------------------------------------------------------------ |
| 矩阵列数       | 确认 24 列（Metric_ID 1~24，无跳号）                                                       |
| 列排序         | 列按 Metric_Sort 排序（10, 20, 30, ... 240）                                               |
| 金额类指标     | #2/#6/#10/#19 切换币种时数值变化（RMB×1 / USD×7）                                          |
| vs LY 派生     | #8/#14/#23 为差值（bp）；#11/#17/#20 为增长率（%）                                          |
| 字体颜色       | 仅 #4/#6/#8/#11/#14/#17/#20/#23 启用条件色，其余为 #252423                                 |
| SVG 图标       | 仅 #8/#11/#14/#17/#20/#23 显示圆形图标                                                     |

### 9.2 数据验证 SQL

```sql
-- Media Cost Rate（#1）
SELECT SUM(cost_amt) * 1.13 / (SUM(net_sales_amt) * 1.06) AS MediaCostRate
FROM a05_e2e_paid_media_summary_d
WHERE customer_type='ALL' AND page_type='1'
  AND data_date BETWEEN '__TimeMin' AND '__TimeMax';

-- Cost ACH%（#3）
SELECT SUM(cost_amt) / SUM(fcst_cost_amt) AS CostACH
FROM a05_e2e_paid_media_summary_d
WHERE customer_type='ALL' AND page_type='1'
  AND data_date BETWEEN '__TimeMin' AND '__TimeMax';

-- SLS ACH%（#5）
SELECT SUM(net_sales_amt) / SUM(fcst_net_sales_amt) AS SLSACH
FROM a05_e2e_paid_media_summary_d
WHERE customer_type='ALL' AND page_type='1'
  AND data_date BETWEEN '__TimeMin' AND '__TimeMax';

-- ± Accel cost MOB% vs. store SLS MOB%（#13）
SELECT
  (SUM(CASE WHEN framework='Acceleration' THEN cost_amt END) / SUM(cost_amt))
  - (SUM(CASE WHEN framework='Acceleration' THEN net_sales_amt END) / SUM(net_sales_amt)) AS AccelCostMOBvsSLS
FROM a05_e2e_paid_media_summary_d
WHERE customer_type='ALL' AND page_type='1'
  AND data_date BETWEEN '__TimeMin' AND '__TimeMax';

-- Acceleration SLS MOB%（#22）
SELECT
  SUM(CASE WHEN framework='Acceleration' THEN net_sales_amt END) / SUM(net_sales_amt) AS AccelSLSMOB
FROM a05_e2e_paid_media_summary_d
WHERE customer_type='ALL' AND page_type='1'
  AND data_date BETWEEN '__TimeMin' AND '__TimeMax';
```

### 9.3 vs LY 验证

验证 vs LY 值时，将 SQL 中的日期范围往前推一年（EDATE -12），对比 DAX 计算结果。
