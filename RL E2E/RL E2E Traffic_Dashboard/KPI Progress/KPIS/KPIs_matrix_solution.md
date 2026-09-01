# Power BI 解决方案 — KPIs 矩阵（KPI Progress 子模块一 + 子模块二）

> status: ready
> created: 2026-07-15
> updated: 2026-09-01
> type: 度量值开发 + 可视化构建
> 口径来源: 口径文档/KPI Progress.md 子模块一（KPIs，1~15）与子模块二（Performance Indicators，16~24）
> 维度来源: KPI Progress/KPIS/Dim_ColMetric_KPIs（24 个指标行）
> 参考: KPI Progress/KPI by Platform/KPI by Platform_matrix_solution.md、Category Growth/KPI_Breakdown_matrix_solution、KPI Progress/参考指标/Font Color

---

## 1. 需求理解

实现 KPI Progress 看板中"KPIs"与"Performance Indicators"两个子模块的中国式矩阵（卡片图）效果：

- **列**：指标维度 `Dim_ColMetric_KPIs[Metric_Name]`，共 24 个指标（`Metric_ID` 1~24）
- **行**：本模块为"无分组维度"卡片图，只受筛选器影响；矩阵场景下可省略行字段或仅用单行占位
- **值**：SWITCH 动态路由，按 `Metric_ID` 分发到 Actual / Target / ±Actual vs Target / vs LY
- **口径**：一切以口径文档 KPI Progress.md 子模块一、子模块二为准
- **筛选器**：与 Category Growth/KPI_Breakdown 一致，全看板公用，Currency 断开连接仅作用于金额类指标

---

## 2. 现状分析

### 2.1 数据底表（4 张事实表）

| 对象   | 名称                               | 用途                                                                                       | 日期字段  |
| ------ | ---------------------------------- | ------------------------------------------------------------------------------------------ | --------- |
| 事实表 | a05_e2e_paid_media_summary_d       | 汇总指标实际值（#1/#2/#3分子/#5分子/#6/#7分子/#9分子/#10分子分母/#12分子分母）              | data_date |
| 事实表 | a05_e2e_paid_media_product_data_d    | 第二品类 Acceleration 实际值（#13/#15/#19/#21/#22/#24）                                     | data_date |
| 事实表 | a03_e2e_customer_data_m            | 全店新客实际值（#7分母/#9分母/#16/#18分子）                                                 | data_date |
| 事实表 | a05_e2e_paid_media_fcst_data_m     | 所有 Target 值（#3分母/#5分母/#9Target/#12Target/#15Target/#18Target/#21Target/#24Target） | data_date |

### 2.2 维度表清单

| 维度表                    | 类型     | 连接方式                                                  | 出处                                 |
| ------------------------- | -------- | --------------------------------------------------------- | ------------------------------------ |
| Slicer_Time_Frame         | 断开维度 | SELECTEDVALUE 读取 TimeFrame_ID（时间粒度 Month/Quarter/Year/Day/Week） | 维度复用/Slicer_Time_Frame.sql |
| Slicer_Time_Frame_Min     | 断开维度 | SELECTEDVALUE 读取 TimeFrame_Min                          | 维度复用/Slicer_Time_Frame_Min.sql   |
| Slicer_Time_Frame_Max     | 断开维度 | SELECTEDVALUE 读取 TimeFrame_Max                          | 维度复用/Slicer_Time_Frame_Max.sql   |
| Slicer_Platform_Selection | 1:N 关系 | Platform_ID → 事实表[platform]                           | 维度复用/Slicer_Platform_Selection   |
| Slicer_Store_Name         | 1:N 关系 | Store_ID → 事实表[store_name]                            | 维度复用/Slicer_Store_Name           |
| Slicer_Currency_Selection | 断开维度 | SELECTEDVALUE 读取 Currency_ExchangeRate, Currency_Symbol | 维度复用/Slicer_Currency_Selection   |
| trans_cycle 筛选器        | 1:N 关系 | → 事实表[trans_cycle]（模型自动筛选）                    | 用户需求                             |
| Dim_ColMetric_KPIs        | 断开维度 | SELECTEDVALUE 读取 Metric_ID, Metric_Format               | KPI Progress/KPIS/Dim_ColMetric_KPIs |

### 2.3 指标维度表（Dim_ColMetric_KPIs）24 个指标

| Metric_ID | Metric_Name                                              | Metric_Sort | Metric_Format        | IsCurrencyAmount |
| --------- | -------------------------------------------------------- | ----------- | -------------------- | ---------------- |
| 1         | Media Cost Rate                                          | 10          | percent_1dp          | FALSE            |
| 2         | Media Cost                                               | 20          | currency             | TRUE             |
| 3         | Cost ACH%                                                | 30          | percent_1dp          | FALSE            |
| 4         | Cost vs SLS ACH%                                         | 40          | delta_bp             | FALSE            |
| 5         | SLS ACH%                                                 | 50          | percent_1dp          | FALSE            |
| 6         | SLS DCom                                                 | 60          | currency             | TRUE             |
| 7         | Media Contribution to New Customer Acquisition%          | 70          | percent_1dp          | FALSE            |
| 8         | Media Contribution to New Customer Acquisition% vs LY    | 80          | delta_bp             | FALSE            |
| 9         | Media Contribution to New Customer Acquisition% TRA ACH% | 90          | percent_1dp          | FALSE            |
| 10        | Media Cost Per New Acquisition                           | 100         | currency_decimal_1dp | TRUE             |
| 11        | Media Cost Per New Acquisition vs LY                     | 110         | percent_1dp          | FALSE            |
| 12        | Media Cost Per New Acquisition TRA ACH%                  | 120         | percent_1dp          | FALSE            |
| 13        | ± Acceleration cost MOB% vs. store SLS MOB%             | 130         | percent_1dp          | FALSE            |
| 14        | ± Acceleration cost MOB% vs. store SLS MOB% vs LY       | 140         | delta_bp             | FALSE            |
| 15        | ± Acceleration SLS MOB% vs. store SLS MOB% TRA ACH%     | 150         | percent_1dp          | FALSE            |
| 16        | New Customer No                                          | 160         | integer              | FALSE            |
| 17        | New Customer No vs LY                                    | 170         | percent_1dp          | FALSE            |
| 18        | New Customer No TRA ACH%                                 | 180         | percent_1dp          | FALSE            |
| 19        | Acceleration SLS                                         | 190         | currency             | TRUE             |
| 20        | Acceleration SLS vs LY                                   | 200         | percent_1dp          | FALSE            |
| 21        | Acceleration SLS TRA ACH%                                | 210         | percent_1dp          | FALSE            |
| 22        | Acceleration SLS MOB%                                    | 220         | percent_1dp          | FALSE            |
| 23        | Acceleration SLS MOB% vs LY                              | 230         | delta_bp             | FALSE            |
| 24        | Acceleration SLS MOB% TRA ACH%                           | 240         | percent_1dp          | FALSE            |

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
    │         ├→ [KPIs Target Base Value] （目标基础值）    │
    │         └→ vs LY / TRA ACH% / ±Actual vs Target 派生│
    └────────────────────────────────────────────────────┘
```

### 3.2 度量值模型设计（拆分 Current / vsLP / Target）

```
[KPIs Current Base Value]  ← 本期基础值（Metric_ID 1/2/3/5/6/7/9/10/12/13/15/16/18/19/21/22/24）
[KPIs vsLP Base Value]     ← 去年同期基础值（用于 vs LY 派生）
[KPIs Target Base Value]   ← 目标基础值（TRA ACH% 类指标的 Target，来自 a05_e2e_paid_media_fcst_data_m）
[KPIs Base Value]          ← 总路由（含 vs LY / TRA ACH% ±Actual vs Target / Cost vs SLS ACH% 派生）
[KPIs Cell Value]          ← 对外值 = Base Value
[KPIs Cell Display]        ← 格式化显示文本
[KPIs Cell Font Color]     ← 字体颜色（仅 Cost vs SLS ACH% / SLS DCom / vs LY 指标启用条件色）
[KPIs Cell Background Color] ← 背景色（卡片场景统一白色 #FFFFFF）
[KPIs Cell SVG Icon]       ← SVG 图标（vs LY 类指标）
```

### 3.3 筛选器上下文

| 筛选器                    | 作用方式                                   | DAX 处理                            |
| ------------------------- | ------------------------------------------ | ----------------------------------- |
| Slicer_Time_Frame         | 断开维度，SELECTEDVALUE 读取 TimeFrame_ID  | 判断时间粒度（Day/Week 时部分指标留空） |
| Slicer_Time_Frame_Min     | 断开维度，SELECTEDVALUE 读取 TimeFrame_Min / TimeFrame_Min_LY / First_Fiscal_Month_Min / First_Fiscal_Month_Max / First_Fiscal_Month_Min_LY / First_Fiscal_Month_Max_LY | `data_date >= __TimeMin`（本期）；`TimeFrame_Min_LY` 用于 vs LY；`First_Fiscal_Month_Min/Max` 用于新客 Step2 start_period（本期）；`First_Fiscal_Month_Min_LY/Max_LY` 用于新客 Step2 start_period（vs LY） |
| Slicer_Time_Frame_Max     | 断开维度，SELECTEDVALUE 读取 TimeFrame_Max / TimeFrame_Max_LY | `data_date <= __TimeMax`（本期）；`TimeFrame_Max_LY` 用于 vs LY |
| Slicer_Platform_Selection | 1:N 关系，模型自动筛选                     | 无需显式处理                        |
| Slicer_Store_Name         | 1:N 关系，模型自动筛选                     | 无需显式处理                        |
| trans_cycle               | 1:N 关系，模型自动筛选                     | 无需显式处理                        |
| Slicer_Currency_Selection | 断开维度，SELECTEDVALUE 读取汇率和符号     | 仅在 Cell Value 层换算：金额类指标 ÷ Currency_ExchangeRate（除法，非乘法） |

### 3.4 vs LY 时间偏移规则（财历映射）

直接读取日期表内置 LY 字段，无需 EDATE -12 或 Key 偏移计算：
```
全局 LY 起始日：Slicer_Time_Frame_Min[TimeFrame_Min_LY]
全局 LY 结束日：Slicer_Time_Frame_Max[TimeFrame_Max_LY]
```
说明：日期表已内置财历映射的 LY 字段，vs LP 度量值直接 SELECTEDVALUE 读取即可。

### 3.5 汇率换算规则

汇率换算**仅在 KPIs Cell Value 层处理**，Base Metrics 层（Current/vsLP/Target/Base Value）一律返回原始本币值：

| 指标类型 | 换算方式 | 判断依据 | 涉及 Metric_ID |
| -------- | -------- | -------- | -------------- |
| 金额类 | `DIVIDE([Base Value], Currency_ExchangeRate)`（除法） | `Metric_IsCurrencyAmount = TRUE` | 2, 6, 10, 19 |
| 比率/计数/基点类 | 不换算，直接返回 [Base Value] | `Metric_IsCurrencyAmount = FALSE` | 1, 3, 4, 5, 7, 8, 9, 11, 12, 13, 14, 15, 16, 17, 18, 20, 21, 22, 23, 24 |

### 3.6 Day/Week 留空规则

涉及时间粒度判断的指标在 `Slicer_Time_Frame[TimeFrame_ID] IN {"Day","Week"}` 时返回 BLANK：
- **TRA ACH% 类**：#3/#5/#9/#12/#15/#18/#21/#24（分子或分母涉及时间粒度判断）
- **媒体新客聚合类**：#7/#9/#10/#12（分子分母涉及 MAX+SUM 聚合）
- **新客类**：#16/#17/#18（新客判定依赖完整财月）

---

## 4. 度量值实现

### 4.1 KPIs Current Base Value（本期基础值）

```dax
KPIs Current Base Value = 
// ========================================
// 度量值: KPIs Current Base Value
// Display Folder: Base Metrics
// 用途: 根据 Metric_ID 路由到本期（Current）基础值
// 依赖: 'Dim_ColMetric_KPIs'[Metric_ID],
//        a05_e2e_paid_media_summary_d（汇总指标），
//        a05_e2e_paid_media_product_data_d（第二品类指标），
//        a03_e2e_customer_data_m（全店新客指标）
// 口径来源: KPI Progress.md 子模块一（1~15）、子模块二（16~24）的本期值
// 筛选: customer_type='ALL' AND page_type="1"（汇总表），
//       媒体新客字段用 MAX+SUM 聚合，
//       第二品类用 product_data 表 + mix_msg 筛选，
//       全店新客用 customer_data_m 合并区间筛选
// 汇率: 本度量值返回原始本币值，不在本层换算汇率；
//       汇率换算统一在 KPIs Cell Value 层处理（金额类指标 DIVIDE(__Value, __FXRate)）
// Day/Week: 涉及时间粒度的指标在 Day/Week 时返回 BLANK
// ========================================
    VAR __MetricID = SELECTEDVALUE('Dim_ColMetric_KPIs'[Metric_ID])

    // ── 时间筛选：本期 ──
    VAR __TimeMin = SELECTEDVALUE(Slicer_Time_Frame_Min[TimeFrame_Min])
    VAR __TimeMax = SELECTEDVALUE(Slicer_Time_Frame_Max[TimeFrame_Max])

    // ── 第一财月区间（新客 Step2 的 start_period）──
    //   月=自身 / 季=Q1→01,Q2→04,Q3→07,Q4→10 / 年=01
    //   Slicer_Time_Frame_Min 维度表已扩展 First_Fiscal_Month 系列
    VAR __FirstFiscalMonthMin = SELECTEDVALUE(Slicer_Time_Frame_Min[First_Fiscal_Month_Min])
    VAR __FirstFiscalMonthMax = SELECTEDVALUE(Slicer_Time_Frame_Min[First_Fiscal_Month_Max])

    // ── 时间粒度判断 ──
    VAR __TimeFrameID = SELECTEDVALUE(Slicer_Time_Frame[TimeFrame_ID])
    VAR __IsDayOrWeek = __TimeFrameID IN {"Day", "Week"}

    // ═══════════════════════════════════════
    // 基础聚合：a05_e2e_paid_media_summary_d（ALL 口径）
    // ═══════════════════════════════════════
    // Cost = SUM(cost_amt)，customer_type='ALL', page_type="1"
    VAR __Cost_ALL = 
        CALCULATE(
            SUM('a05_e2e_paid_media_summary_d'[cost_amt]),
            'a05_e2e_paid_media_summary_d'[customer_type] = "ALL",
            'a05_e2e_paid_media_summary_d'[page_type] = "1",
            'a05_e2e_paid_media_summary_d'[data_date] >= __TimeMin,
            'a05_e2e_paid_media_summary_d'[data_date] <= __TimeMax
        )
    // Net Sales = SUM(net_sales_amt)，customer_type='ALL', page_type="1"
    VAR __SLS_ALL = 
        CALCULATE(
            SUM('a05_e2e_paid_media_summary_d'[net_sales_amt]),
            'a05_e2e_paid_media_summary_d'[customer_type] = "ALL",
            'a05_e2e_paid_media_summary_d'[page_type] = "1",
            'a05_e2e_paid_media_summary_d'[data_date] >= __TimeMin,
            'a05_e2e_paid_media_summary_d'[data_date] <= __TimeMax
        )

    // ═══════════════════════════════════════
    // 媒体新客字段聚合：先 MAX 再 SUM（SUMX+SUMMARIZE）
    // 仅支持完整财月/财季/财年，Day/Week 时为空
    // customer_type='ALL', page_type="1"
    // ═══════════════════════════════════════
    // 媒体新客数 = SUM(MAX(media_member_cnt))，按 platform/shop_id/data_month_name 分组
    VAR __MediaNewCustCnt = 
        IF(
            __IsDayOrWeek,
            BLANK(),
            CALCULATE(
                SUMX(
                    SUMMARIZE(
                        'a05_e2e_paid_media_summary_d',
                        'a05_e2e_paid_media_summary_d'[platform],
                        'a05_e2e_paid_media_summary_d'[shop_id],
                        'a05_e2e_paid_media_summary_d'[data_month_name],
                        "__Value", MAX('a05_e2e_paid_media_summary_d'[media_member_cnt])
                    ),
                    [__Value]
                ),
                'a05_e2e_paid_media_summary_d'[customer_type] = "ALL",
                'a05_e2e_paid_media_summary_d'[page_type] = "1",
                'a05_e2e_paid_media_summary_d'[data_date] >= __TimeMin,
                'a05_e2e_paid_media_summary_d'[data_date] <= __TimeMax
            )
        )
    // 媒体新客花费 = SUM(MAX(media_cost_amt))，按 platform/shop_id/data_month_name 分组
    VAR __MediaNewCostAmt = 
        IF(
            __IsDayOrWeek,
            BLANK(),
            CALCULATE(
                SUMX(
                    SUMMARIZE(
                        'a05_e2e_paid_media_summary_d',
                        'a05_e2e_paid_media_summary_d'[platform],
                        'a05_e2e_paid_media_summary_d'[shop_id],
                        'a05_e2e_paid_media_summary_d'[data_month_name],
                        "__Value", MAX('a05_e2e_paid_media_summary_d'[media_cost_amt])
                    ),
                    [__Value]
                ),
                'a05_e2e_paid_media_summary_d'[customer_type] = "ALL",
                'a05_e2e_paid_media_summary_d'[page_type] = "1",
                'a05_e2e_paid_media_summary_d'[data_date] >= __TimeMin,
                'a05_e2e_paid_media_summary_d'[data_date] <= __TimeMax
            )
        )

    // ═══════════════════════════════════════
    // 全店新客数：a03_e2e_customer_data_m
    // 合并区间筛选：data_date ∈ [__FirstFiscalMonthMin, __FirstFiscalMonthMax]
    //   （start_period = 第一财月，是 slicer 区间的子集，合并区间后单一 CALCULATE 即可）
    //   AND net_pay_amt > 0 AND is_member = 0 AND lp_12m_net_pay_amt = 0
    // DISTINCTCOUNT(user_id)
    // Day/Week 时为空
    // ═══════════════════════════════════════
    VAR __TotalNewCustCnt = 
        IF(
            __IsDayOrWeek,
            BLANK(),
            CALCULATE(
                DISTINCTCOUNT('a03_e2e_customer_data_m'[user_id]),
                'a03_e2e_customer_data_m'[data_date] >= __FirstFiscalMonthMin,
                'a03_e2e_customer_data_m'[data_date] <= __FirstFiscalMonthMax,
                'a03_e2e_customer_data_m'[net_pay_amt] > 0,
                'a03_e2e_customer_data_m'[is_member] = 0,
                'a03_e2e_customer_data_m'[lp_12m_net_pay_amt] = 0
            )
        )

    // ═══════════════════════════════════════
    // 第二品类：a05_e2e_paid_media_product_data_d
    // Cost 类分子：mix_msg is NULL AND framework='Acceleration'
    // Cost 类分母：mix_msg is NULL（不限制 framework）
    // SLS 类分子：framework='Acceleration'（不限制 mix_msg）
    // SLS 类分母：全部 framework（不限制 mix_msg）
    // ═══════════════════════════════════════
    // Acceleration Cost 分子 = SUM(cost_amt) WHERE mix_msg IS NULL AND framework='Acceleration'
    VAR __AccelCost_Num = 
        CALCULATE(
            SUM('a05_e2e_paid_media_product_data_d'[cost_amt]),
            ISBLANK('a05_e2e_paid_media_product_data_d'[mix_msg]),
            'a05_e2e_paid_media_product_data_d'[framework] = "Acceleration",
            'a05_e2e_paid_media_product_data_d'[data_date] >= __TimeMin,
            'a05_e2e_paid_media_product_data_d'[data_date] <= __TimeMax
        )
    // Cost 分母 = SUM(cost_amt) WHERE mix_msg IS NULL（不限制 framework）
    VAR __Cost_Den = 
        CALCULATE(
            SUM('a05_e2e_paid_media_product_data_d'[cost_amt]),
            ISBLANK('a05_e2e_paid_media_product_data_d'[mix_msg]),
            'a05_e2e_paid_media_product_data_d'[data_date] >= __TimeMin,
            'a05_e2e_paid_media_product_data_d'[data_date] <= __TimeMax
        )
    // Acceleration SLS 分子 = SUM(net_sales_amt) WHERE framework='Acceleration'
    VAR __AccelSLS_Num = 
        CALCULATE(
            SUM('a05_e2e_paid_media_product_data_d'[net_sales_amt]),
            'a05_e2e_paid_media_product_data_d'[framework] = "Acceleration",
            'a05_e2e_paid_media_product_data_d'[data_date] >= __TimeMin,
            'a05_e2e_paid_media_product_data_d'[data_date] <= __TimeMax
        )
    // SLS 分母 = SUM(net_sales_amt)（全部 framework）
    VAR __SLS_Den = 
        CALCULATE(
            SUM('a05_e2e_paid_media_product_data_d'[net_sales_amt]),
            'a05_e2e_paid_media_product_data_d'[data_date] >= __TimeMin,
            'a05_e2e_paid_media_product_data_d'[data_date] <= __TimeMax
        )

    // ═══════════════════════════════════════
    // 派生指标
    // ═══════════════════════════════════════
    // #1 Media Cost Rate = Cost / SLS × 1.13 / 1.06（比率，不涉及汇率）
    VAR __MediaCostRate = DIVIDE(DIVIDE(__Cost_ALL, __SLS_ALL) * 1.13, 1.06)
    // #7 Media Contribution% = 媒体新客数 / 全店新客数（比率）
    VAR __MediaNewCustContrib = DIVIDE(__MediaNewCustCnt, __TotalNewCustCnt)
    // #10 Media Cost Per New Acquisition = 媒体新客花费 / 媒体新客数（金额，需÷汇率）
    VAR __CostPerNewAcq = DIVIDE(__MediaNewCostAmt, __MediaNewCustCnt)
    // #13 ± Accel Cost MOB% vs Store SLS MOB% = Accel Cost MOB% - Store SLS MOB%
    VAR __AccelCostMOBvsSLS = DIVIDE(__AccelCost_Num, __Cost_Den) - DIVIDE(__AccelSLS_Num, __SLS_Den)
    // #22 Acceleration SLS MOB% = Accel SLS / TTL SLS
    VAR __AccelSLSMOB = DIVIDE(__AccelSLS_Num, __SLS_Den)

    // #3 Cost ACH% Actual = SUM(cost_amt) / Cost Target
    // #5 SLS ACH% Actual = SUM(net_sales_amt) / SLS Target
    // Target 在 KPIs Target Base Value 中计算，此处返回分子用于 Actual 计算
    // #3/#5 的 Actual = Current Base Value / Target Base Value，在 Base Value 中完成

    RETURN
        SWITCH(
            __MetricID,
            // ─── 子模块一：KPIs（1~15）本期值 ───
            1,  __MediaCostRate,                                    // Media Cost Rate（比率，不涉及汇率）
            2,  __Cost_ALL,                                         // Media Cost（金额，汇率在 Cell Value 层处理）
            3,  __Cost_ALL,                                        // Cost ACH% 分子（比率，分子分母均不除汇率，Actual = 分子/Target 在 Base Value 中完成）
            5,  __SLS_ALL,                                         // SLS ACH% 分子（比率，分子分母均不除汇率，Actual = 分子/Target 在 Base Value 中完成）
            6,  __SLS_ALL,                                         // SLS DCom（金额，汇率在 Cell Value 层处理）
            7,  __MediaNewCustContrib,                             // Media Contribution to New Customer Acquisition%（比率）
            10, __CostPerNewAcq,                                   // Media Cost Per New Acquisition（金额，汇率在 Cell Value 层处理）
            13, __AccelCostMOBvsSLS,                               // ± Acceleration cost MOB% vs. store SLS MOB%（比率）
            // ─── 子模块二：Performance Indicators（16~24）本期值 ───
            16, __TotalNewCustCnt,                                 // New Customer No（整数，不涉及汇率）
            19, __AccelSLS_Num,                                   // Acceleration SLS（金额，汇率在 Cell Value 层处理）
            22, __AccelSLSMOB,                                     // Acceleration SLS MOB%（比率）
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
// 依赖: 'Dim_ColMetric_KPIs'[Metric_ID],
//        a05_e2e_paid_media_summary_d,
//        a05_e2e_paid_media_product_data_d,
//        a03_e2e_customer_data_m
// 口径来源: KPI Progress.md 子模块一、二 vs LY 行
// 说明: vs LY 直接读取日期表内置 LY 字段（财历映射），无需 EDATE -12 计算
//       - 全局 LY 起始日：Slicer_Time_Frame_Min[TimeFrame_Min_LY]
//       - 全局 LY 结束日：Slicer_Time_Frame_Max[TimeFrame_Max_LY]
// 汇率: 本度量值返回原始本币值，不在本层换算汇率；
//       汇率换算统一在 KPIs Cell Value 层处理
// Day/Week: 涉及时间粒度的指标在 Day/Week 时返回 BLANK
// ========================================
    VAR __MetricID = SELECTEDVALUE('Dim_ColMetric_KPIs'[Metric_ID])
    // ── 时间筛选：去年同期（直接读取日期表内置 LY 字段）──
    VAR __LPTimeMin = SELECTEDVALUE(Slicer_Time_Frame_Min[TimeFrame_Min_LY])
    VAR __LPTimeMax = SELECTEDVALUE(Slicer_Time_Frame_Max[TimeFrame_Max_LY])
    // ── 第一财月区间（去年同期，新客 Step2 的 start_period）──
    VAR __LPFirstFiscalMonthMin = SELECTEDVALUE(Slicer_Time_Frame_Min[First_Fiscal_Month_Min_LY])
    VAR __LPFirstFiscalMonthMax = SELECTEDVALUE(Slicer_Time_Frame_Min[First_Fiscal_Month_Max_LY])
    // ── 时间粒度判断 ──
    VAR __TimeFrameID = SELECTEDVALUE(Slicer_Time_Frame[TimeFrame_ID])
    VAR __IsDayOrWeek = __TimeFrameID IN {"Day", "Week"}

    // ═══════════════════════════════════════
    // 基础聚合：a05_e2e_paid_media_summary_d（ALL 口径，去年同期）
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

    // ═══════════════════════════════════════
    // 媒体新客字段聚合：先 MAX 再 SUM（去年同期）
    // ═══════════════════════════════════════
    VAR __MediaNewCustCnt = 
        IF(
            __IsDayOrWeek,
            BLANK(),
            CALCULATE(
                SUMX(
                    SUMMARIZE(
                        'a05_e2e_paid_media_summary_d',
                        'a05_e2e_paid_media_summary_d'[platform],
                        'a05_e2e_paid_media_summary_d'[shop_id],
                        'a05_e2e_paid_media_summary_d'[data_month_name],
                        "__Value", MAX('a05_e2e_paid_media_summary_d'[media_member_cnt])
                    ),
                    [__Value]
                ),
                'a05_e2e_paid_media_summary_d'[customer_type] = "ALL",
                'a05_e2e_paid_media_summary_d'[page_type] = "1",
                'a05_e2e_paid_media_summary_d'[data_date] >= __LPTimeMin,
                'a05_e2e_paid_media_summary_d'[data_date] <= __LPTimeMax
            )
        )
    VAR __MediaNewCostAmt = 
        IF(
            __IsDayOrWeek,
            BLANK(),
            CALCULATE(
                SUMX(
                    SUMMARIZE(
                        'a05_e2e_paid_media_summary_d',
                        'a05_e2e_paid_media_summary_d'[platform],
                        'a05_e2e_paid_media_summary_d'[shop_id],
                        'a05_e2e_paid_media_summary_d'[data_month_name],
                        "__Value", MAX('a05_e2e_paid_media_summary_d'[media_cost_amt])
                    ),
                    [__Value]
                ),
                'a05_e2e_paid_media_summary_d'[customer_type] = "ALL",
                'a05_e2e_paid_media_summary_d'[page_type] = "1",
                'a05_e2e_paid_media_summary_d'[data_date] >= __LPTimeMin,
                'a05_e2e_paid_media_summary_d'[data_date] <= __LPTimeMax
            )
        )

    // ═══════════════════════════════════════
    // 全店新客数：a03_e2e_customer_data_m（去年同期）
    // 合并区间筛选：data_date ∈ [__LPFirstFiscalMonthMin, __LPFirstFiscalMonthMax]
    //   （start_period = 去年同期第一财月）
    //   AND net_pay_amt > 0 AND is_member = 0 AND lp_12m_net_pay_amt = 0
    // ═══════════════════════════════════════
    VAR __TotalNewCustCnt = 
        IF(
            __IsDayOrWeek,
            BLANK(),
            CALCULATE(
                DISTINCTCOUNT('a03_e2e_customer_data_m'[user_id]),
                'a03_e2e_customer_data_m'[data_date] >= __LPFirstFiscalMonthMin,
                'a03_e2e_customer_data_m'[data_date] <= __LPFirstFiscalMonthMax,
                'a03_e2e_customer_data_m'[net_pay_amt] > 0,
                'a03_e2e_customer_data_m'[is_member] = 0,
                'a03_e2e_customer_data_m'[lp_12m_net_pay_amt] = 0
            )
        )

    // ═══════════════════════════════════════
    // 第二品类：a05_e2e_paid_media_product_data_d（去年同期）
    // ═══════════════════════════════════════
    VAR __AccelCost_Num = 
        CALCULATE(
            SUM('a05_e2e_paid_media_product_data_d'[cost_amt]),
            ISBLANK('a05_e2e_paid_media_product_data_d'[mix_msg]),
            'a05_e2e_paid_media_product_data_d'[framework] = "Acceleration",
            'a05_e2e_paid_media_product_data_d'[data_date] >= __LPTimeMin,
            'a05_e2e_paid_media_product_data_d'[data_date] <= __LPTimeMax
        )
    VAR __Cost_Den = 
        CALCULATE(
            SUM('a05_e2e_paid_media_product_data_d'[cost_amt]),
            ISBLANK('a05_e2e_paid_media_product_data_d'[mix_msg]),
            'a05_e2e_paid_media_product_data_d'[data_date] >= __LPTimeMin,
            'a05_e2e_paid_media_product_data_d'[data_date] <= __LPTimeMax
        )
    VAR __AccelSLS_Num = 
        CALCULATE(
            SUM('a05_e2e_paid_media_product_data_d'[net_sales_amt]),
            'a05_e2e_paid_media_product_data_d'[framework] = "Acceleration",
            'a05_e2e_paid_media_product_data_d'[data_date] >= __LPTimeMin,
            'a05_e2e_paid_media_product_data_d'[data_date] <= __LPTimeMax
        )
    VAR __SLS_Den = 
        CALCULATE(
            SUM('a05_e2e_paid_media_product_data_d'[net_sales_amt]),
            'a05_e2e_paid_media_product_data_d'[data_date] >= __LPTimeMin,
            'a05_e2e_paid_media_product_data_d'[data_date] <= __LPTimeMax
        )

    // ═══════════════════════════════════════
    // 派生指标（去年同期）
    // ═══════════════════════════════════════
    VAR __MediaNewCustContrib = DIVIDE(__MediaNewCustCnt, __TotalNewCustCnt)
    VAR __CostPerNewAcq = DIVIDE(__MediaNewCostAmt, __MediaNewCustCnt)
    VAR __AccelCostMOBvsSLS = DIVIDE(__AccelCost_Num, __Cost_Den) - DIVIDE(__AccelSLS_Num, __SLS_Den)
    VAR __AccelSLSMOB = DIVIDE(__AccelSLS_Num, __SLS_Den)

    RETURN
        SWITCH(
            __MetricID,
            // ─── vs LY 派生所需的去年同期基础值（按 vs LY 指标 ID 路由）───
            8,  __MediaNewCustContrib,                             // #8 vs LY：媒体新客贡献率（本期 − 同期，bp，比率不涉及汇率）
            11, __CostPerNewAcq,                                   // #11 vs LY：获客成本（本期/同期 − 1，金额，汇率在 Cell Value 层处理）
            14, __AccelCostMOBvsSLS,                               // #14 vs LY：± Accel cost MOB%（本期 − 同期，bp）
            17, __TotalNewCustCnt,                                 // #17 vs LY：新客数量（本期/同期 − 1，整数不涉及汇率）
            20, __AccelSLS_Num,                                    // #20 vs LY：Acceleration SLS（本期/同期 − 1，金额，汇率在 Cell Value 层处理）
            23, __AccelSLSMOB,                                     // #23 vs LY：Acceleration SLS MOB%（本期占比 − 同期占比，bp）
            BLANK()
        )
```

### 4.3 KPIs Target Base Value（目标基础值）

```dax
KPIs Target Base Value = 
// ========================================
// 度量值: KPIs Target Base Value
// Display Folder: Base Metrics
// 用途: 根据 Metric_ID 路由到 TRA ACH% 类指标的 Target 值
// 依赖: 'Dim_ColMetric_KPIs'[Metric_ID], a05_e2e_paid_media_fcst_data_m
// 口径来源: KPI Progress.md 各 TRA ACH% 指标的 Target 行
// 说明:
//   - Target 值来自 a05_e2e_paid_media_fcst_data_m（预测专用表）
//   - 按时间粒度使用不同字段：
//     Month/Quarter → 按 platform/shop_id/data_month_name 分组聚合
//     Year → 按 platform/shop_id/data_year 分组聚合，使用 year_ 前缀字段
//   - #3/#5 Target 固定 100%（即 1）
//   - Day/Week 时返回 BLANK
//   - Target 缺失时返回 BLANK（由 Base Value 层处理展示"-"）
// ========================================
    VAR __MetricID = SELECTEDVALUE('Dim_ColMetric_KPIs'[Metric_ID])

    // ── 时间筛选 ──
    VAR __TimeMin = SELECTEDVALUE(Slicer_Time_Frame_Min[TimeFrame_Min])
    VAR __TimeMax = SELECTEDVALUE(Slicer_Time_Frame_Max[TimeFrame_Max])

    // ── 时间粒度判断 ──
    VAR __TimeFrameID = SELECTEDVALUE(Slicer_Time_Frame[TimeFrame_ID])
    VAR __IsDayOrWeek = __TimeFrameID IN {"Day", "Week"}
    VAR __IsYear = __TimeFrameID = "Year"

    // ═══════════════════════════════════════
    // #3 Cost ACH% Target：固定 100%
    // #5 SLS ACH% Target：固定 100%
    // ═══════════════════════════════════════

    // ═══════════════════════════════════════
    // #9 Media Contribution% TRA ACH% Target
    // Month/Quarter: SUM(media_new_customer_cnt) / SUM(new_customer_cnt)
    // Year: MAX(year_media_new_customer_contribution_rate)
    // ═══════════════════════════════════════
    VAR __Target_MediaContrib = 
        IF(
            __IsDayOrWeek,
            BLANK(),
            IF(
                __IsYear,
                // Year 粒度：按 platform/shop_id/data_year 分组，MAX(year_media_new_customer_contribution_rate)
                CALCULATE(
                    SUMX(
                        SUMMARIZE(
                            'a05_e2e_paid_media_fcst_data_m',
                            'a05_e2e_paid_media_fcst_data_m'[platform],
                            'a05_e2e_paid_media_fcst_data_m'[shop_id],
                            'a05_e2e_paid_media_fcst_data_m'[data_year],
                            "__Value", MAX('a05_e2e_paid_media_fcst_data_m'[year_media_new_customer_contribution_rate])
                        ),
                        [__Value]
                    ),
                    'a05_e2e_paid_media_fcst_data_m'[data_date] >= __TimeMin,
                    'a05_e2e_paid_media_fcst_data_m'[data_date] <= __TimeMax
                ),
                // Month/Quarter 粒度：SUM(media_new_customer_cnt) / SUM(new_customer_cnt)
                CALCULATE(
                    DIVIDE(
                        SUMX(
                            SUMMARIZE(
                                'a05_e2e_paid_media_fcst_data_m',
                                'a05_e2e_paid_media_fcst_data_m'[platform],
                                'a05_e2e_paid_media_fcst_data_m'[shop_id],
                                'a05_e2e_paid_media_fcst_data_m'[data_month_name],
                                "__Cnt", MAX('a05_e2e_paid_media_fcst_data_m'[media_new_customer_cnt])
                            ),
                            [__Cnt]
                        ),
                        SUMX(
                            SUMMARIZE(
                                'a05_e2e_paid_media_fcst_data_m',
                                'a05_e2e_paid_media_fcst_data_m'[platform],
                                'a05_e2e_paid_media_fcst_data_m'[shop_id],
                                'a05_e2e_paid_media_fcst_data_m'[data_month_name],
                                "__Cnt", MAX('a05_e2e_paid_media_fcst_data_m'[new_customer_cnt])
                            ),
                            [__Cnt]
                        )
                    ),
                    'a05_e2e_paid_media_fcst_data_m'[data_date] >= __TimeMin,
                    'a05_e2e_paid_media_fcst_data_m'[data_date] <= __TimeMax
                )
            )
        )

    // ═══════════════════════════════════════
    // #12 Media Cost Per New Acquisition TRA ACH% Target
    // Month/Quarter: SUM(media_new_customer_cost_amt) / SUM(media_new_customer_cnt)
    // Year: MAX(year_cost_per_new_acquisition)
    // ═══════════════════════════════════════
    VAR __Target_CostPerNewAcq = 
        IF(
            __IsDayOrWeek,
            BLANK(),
            IF(
                __IsYear,
                // Year 粒度：MAX(year_cost_per_new_acquisition)
                CALCULATE(
                    SUMX(
                        SUMMARIZE(
                            'a05_e2e_paid_media_fcst_data_m',
                            'a05_e2e_paid_media_fcst_data_m'[platform],
                            'a05_e2e_paid_media_fcst_data_m'[shop_id],
                            'a05_e2e_paid_media_fcst_data_m'[data_year],
                            "__Value", MAX('a05_e2e_paid_media_fcst_data_m'[year_cost_per_new_acquisition])
                        ),
                        [__Value]
                    ),
                    'a05_e2e_paid_media_fcst_data_m'[data_date] >= __TimeMin,
                    'a05_e2e_paid_media_fcst_data_m'[data_date] <= __TimeMax
                ),
                // Month/Quarter 粒度：SUM(media_new_customer_cost_amt) / SUM(media_new_customer_cnt)
                CALCULATE(
                    DIVIDE(
                        SUMX(
                            SUMMARIZE(
                                'a05_e2e_paid_media_fcst_data_m',
                                'a05_e2e_paid_media_fcst_data_m'[platform],
                                'a05_e2e_paid_media_fcst_data_m'[shop_id],
                                'a05_e2e_paid_media_fcst_data_m'[data_month_name],
                                "__Amt", MAX('a05_e2e_paid_media_fcst_data_m'[media_new_customer_cost_amt])
                            ),
                            [__Amt]
                        ),
                        SUMX(
                            SUMMARIZE(
                                'a05_e2e_paid_media_fcst_data_m',
                                'a05_e2e_paid_media_fcst_data_m'[platform],
                                'a05_e2e_paid_media_fcst_data_m'[shop_id],
                                'a05_e2e_paid_media_fcst_data_m'[data_month_name],
                                "__Cnt", MAX('a05_e2e_paid_media_fcst_data_m'[media_new_customer_cnt])
                            ),
                            [__Cnt]
                        )
                    ),
                    'a05_e2e_paid_media_fcst_data_m'[data_date] >= __TimeMin,
                    'a05_e2e_paid_media_fcst_data_m'[data_date] <= __TimeMax
                )
            )
        )

    // ═══════════════════════════════════════
    // #15 ± Accel Cost MOB% vs Store SLS MOB% TRA ACH% Target
    // Month/Quarter: SUM(acceleration_cost_amt)/SUM(cost_amt) - SUM(acceleration_net_sales_amt)/SUM(net_sales_amt)
    // Year: MAX(year_acceleration_cost_rate_vs_net_sales_rate)
    // ═══════════════════════════════════════
    VAR __Target_AccelCostMOB = 
        IF(
            __IsDayOrWeek,
            BLANK(),
            IF(
                __IsYear,
                // Year 粒度：MAX(year_acceleration_cost_rate_vs_net_sales_rate)
                CALCULATE(
                    SUMX(
                        SUMMARIZE(
                            'a05_e2e_paid_media_fcst_data_m',
                            'a05_e2e_paid_media_fcst_data_m'[platform],
                            'a05_e2e_paid_media_fcst_data_m'[shop_id],
                            'a05_e2e_paid_media_fcst_data_m'[data_year],
                            "__Value", MAX('a05_e2e_paid_media_fcst_data_m'[year_acceleration_cost_rate_vs_net_sales_rate])
                        ),
                        [__Value]
                    ),
                    'a05_e2e_paid_media_fcst_data_m'[data_date] >= __TimeMin,
                    'a05_e2e_paid_media_fcst_data_m'[data_date] <= __TimeMax
                ),
                // Month/Quarter 粒度：SUM(acceleration_cost_amt)/SUM(cost_amt) - SUM(acceleration_net_sales_amt)/SUM(net_sales_amt)
                CALCULATE(
                    DIVIDE(
                        SUMX(
                            SUMMARIZE(
                                'a05_e2e_paid_media_fcst_data_m',
                                'a05_e2e_paid_media_fcst_data_m'[platform],
                                'a05_e2e_paid_media_fcst_data_m'[shop_id],
                                'a05_e2e_paid_media_fcst_data_m'[data_month_name],
                                "__Val", MAX('a05_e2e_paid_media_fcst_data_m'[acceleration_cost_amt])
                            ),
                            [__Val]
                        ),
                        SUMX(
                            SUMMARIZE(
                                'a05_e2e_paid_media_fcst_data_m',
                                'a05_e2e_paid_media_fcst_data_m'[platform],
                                'a05_e2e_paid_media_fcst_data_m'[shop_id],
                                'a05_e2e_paid_media_fcst_data_m'[data_month_name],
                                "__Val", MAX('a05_e2e_paid_media_fcst_data_m'[cost_amt])
                            ),
                            [__Val]
                        )
                    )
                    - DIVIDE(
                        SUMX(
                            SUMMARIZE(
                                'a05_e2e_paid_media_fcst_data_m',
                                'a05_e2e_paid_media_fcst_data_m'[platform],
                                'a05_e2e_paid_media_fcst_data_m'[shop_id],
                                'a05_e2e_paid_media_fcst_data_m'[data_month_name],
                                "__Val", MAX('a05_e2e_paid_media_fcst_data_m'[acceleration_net_sales_amt])
                            ),
                            [__Val]
                        ),
                        SUMX(
                            SUMMARIZE(
                                'a05_e2e_paid_media_fcst_data_m',
                                'a05_e2e_paid_media_fcst_data_m'[platform],
                                'a05_e2e_paid_media_fcst_data_m'[shop_id],
                                'a05_e2e_paid_media_fcst_data_m'[data_month_name],
                                "__Val", MAX('a05_e2e_paid_media_fcst_data_m'[net_sales_amt])
                            ),
                            [__Val]
                        )
                    ),
                    'a05_e2e_paid_media_fcst_data_m'[data_date] >= __TimeMin,
                    'a05_e2e_paid_media_fcst_data_m'[data_date] <= __TimeMax
                )
            )
        )

    // ═══════════════════════════════════════
    // #18 New Customer No TRA ACH% Target
    // Month/Quarter: SUM(new_customer_cnt)
    // Year: MAX(year_new_customer_cnt)
    // ═══════════════════════════════════════
    VAR __Target_NewCustNo = 
        IF(
            __IsDayOrWeek,
            BLANK(),
            IF(
                __IsYear,
                // Year 粒度：MAX(year_new_customer_cnt)
                CALCULATE(
                    SUMX(
                        SUMMARIZE(
                            'a05_e2e_paid_media_fcst_data_m',
                            'a05_e2e_paid_media_fcst_data_m'[platform],
                            'a05_e2e_paid_media_fcst_data_m'[shop_id],
                            'a05_e2e_paid_media_fcst_data_m'[data_year],
                            "__Value", MAX('a05_e2e_paid_media_fcst_data_m'[year_new_customer_cnt])
                        ),
                        [__Value]
                    ),
                    'a05_e2e_paid_media_fcst_data_m'[data_date] >= __TimeMin,
                    'a05_e2e_paid_media_fcst_data_m'[data_date] <= __TimeMax
                ),
                // Month/Quarter 粒度：SUM(new_customer_cnt)
                CALCULATE(
                    SUMX(
                        SUMMARIZE(
                            'a05_e2e_paid_media_fcst_data_m',
                            'a05_e2e_paid_media_fcst_data_m'[platform],
                            'a05_e2e_paid_media_fcst_data_m'[shop_id],
                            'a05_e2e_paid_media_fcst_data_m'[data_month_name],
                            "__Value", MAX('a05_e2e_paid_media_fcst_data_m'[new_customer_cnt])
                        ),
                        [__Value]
                    ),
                    'a05_e2e_paid_media_fcst_data_m'[data_date] >= __TimeMin,
                    'a05_e2e_paid_media_fcst_data_m'[data_date] <= __TimeMax
                )
            )
        )

    // ═══════════════════════════════════════
    // #21 Acceleration SLS TRA ACH% Target
    // Month/Quarter: SUM(acceleration_net_sales_amt)
    // Year: MAX(year_acceleration_net_sales_amt)
    // ═══════════════════════════════════════
    VAR __Target_AccelSLS = 
        IF(
            __IsDayOrWeek,
            BLANK(),
            IF(
                __IsYear,
                // Year 粒度：MAX(year_acceleration_net_sales_amt)
                CALCULATE(
                    SUMX(
                        SUMMARIZE(
                            'a05_e2e_paid_media_fcst_data_m',
                            'a05_e2e_paid_media_fcst_data_m'[platform],
                            'a05_e2e_paid_media_fcst_data_m'[shop_id],
                            'a05_e2e_paid_media_fcst_data_m'[data_year],
                            "__Value", MAX('a05_e2e_paid_media_fcst_data_m'[year_acceleration_net_sales_amt])
                        ),
                        [__Value]
                    ),
                    'a05_e2e_paid_media_fcst_data_m'[data_date] >= __TimeMin,
                    'a05_e2e_paid_media_fcst_data_m'[data_date] <= __TimeMax
                ),
                // Month/Quarter 粒度：SUM(acceleration_net_sales_amt)
                CALCULATE(
                    SUMX(
                        SUMMARIZE(
                            'a05_e2e_paid_media_fcst_data_m',
                            'a05_e2e_paid_media_fcst_data_m'[platform],
                            'a05_e2e_paid_media_fcst_data_m'[shop_id],
                            'a05_e2e_paid_media_fcst_data_m'[data_month_name],
                            "__Value", MAX('a05_e2e_paid_media_fcst_data_m'[acceleration_net_sales_amt])
                        ),
                        [__Value]
                    ),
                    'a05_e2e_paid_media_fcst_data_m'[data_date] >= __TimeMin,
                    'a05_e2e_paid_media_fcst_data_m'[data_date] <= __TimeMax
                )
            )
        )

    // ═══════════════════════════════════════
    // #24 Acceleration SLS MOB% TRA ACH% Target
    // Month/Quarter: SUM(acceleration_net_sales_amt) / SUM(net_sales_amt)
    // Year: MAX(year_acceleration_net_sales_rate)
    // ═══════════════════════════════════════
    VAR __Target_AccelSLSMOB = 
        IF(
            __IsDayOrWeek,
            BLANK(),
            IF(
                __IsYear,
                // Year 粒度：MAX(year_acceleration_net_sales_rate)
                CALCULATE(
                    SUMX(
                        SUMMARIZE(
                            'a05_e2e_paid_media_fcst_data_m',
                            'a05_e2e_paid_media_fcst_data_m'[platform],
                            'a05_e2e_paid_media_fcst_data_m'[shop_id],
                            'a05_e2e_paid_media_fcst_data_m'[data_year],
                            "__Value", MAX('a05_e2e_paid_media_fcst_data_m'[year_acceleration_net_sales_rate])
                        ),
                        [__Value]
                    ),
                    'a05_e2e_paid_media_fcst_data_m'[data_date] >= __TimeMin,
                    'a05_e2e_paid_media_fcst_data_m'[data_date] <= __TimeMax
                ),
                // Month/Quarter 粒度：SUM(acceleration_net_sales_amt) / SUM(net_sales_amt)
                CALCULATE(
                    DIVIDE(
                        SUMX(
                            SUMMARIZE(
                                'a05_e2e_paid_media_fcst_data_m',
                                'a05_e2e_paid_media_fcst_data_m'[platform],
                                'a05_e2e_paid_media_fcst_data_m'[shop_id],
                                'a05_e2e_paid_media_fcst_data_m'[data_month_name],
                                "__Val", MAX('a05_e2e_paid_media_fcst_data_m'[acceleration_net_sales_amt])
                            ),
                            [__Val]
                        ),
                        SUMX(
                            SUMMARIZE(
                                'a05_e2e_paid_media_fcst_data_m',
                                'a05_e2e_paid_media_fcst_data_m'[platform],
                                'a05_e2e_paid_media_fcst_data_m'[shop_id],
                                'a05_e2e_paid_media_fcst_data_m'[data_month_name],
                                "__Val", MAX('a05_e2e_paid_media_fcst_data_m'[net_sales_amt])
                            ),
                            [__Val]
                        )
                    ),
                    'a05_e2e_paid_media_fcst_data_m'[data_date] >= __TimeMin,
                    'a05_e2e_paid_media_fcst_data_m'[data_date] <= __TimeMax
                )
            )
        )

    // ═══════════════════════════════════════
    // #3 Cost ACH% Target 分母（Cost Target 值）
    // Month/Quarter: SUM(cost_amt) 按 platform/shop_id/data_month_name
    // Year: SUM(year_cost_amt) 按 platform/shop_id/data_year
    // ═══════════════════════════════════════
    VAR __Target_CostAmt = 
        IF(
            __IsDayOrWeek,
            BLANK(),
            IF(
                __IsYear,
                CALCULATE(
                    SUMX(
                        SUMMARIZE(
                            'a05_e2e_paid_media_fcst_data_m',
                            'a05_e2e_paid_media_fcst_data_m'[platform],
                            'a05_e2e_paid_media_fcst_data_m'[shop_id],
                            'a05_e2e_paid_media_fcst_data_m'[data_year],
                            "__Value", MAX('a05_e2e_paid_media_fcst_data_m'[year_cost_amt])
                        ),
                        [__Value]
                    ),
                    'a05_e2e_paid_media_fcst_data_m'[data_date] >= __TimeMin,
                    'a05_e2e_paid_media_fcst_data_m'[data_date] <= __TimeMax
                ),
                CALCULATE(
                    SUMX(
                        SUMMARIZE(
                            'a05_e2e_paid_media_fcst_data_m',
                            'a05_e2e_paid_media_fcst_data_m'[platform],
                            'a05_e2e_paid_media_fcst_data_m'[shop_id],
                            'a05_e2e_paid_media_fcst_data_m'[data_month_name],
                            "__Value", MAX('a05_e2e_paid_media_fcst_data_m'[cost_amt])
                        ),
                        [__Value]
                    ),
                    'a05_e2e_paid_media_fcst_data_m'[data_date] >= __TimeMin,
                    'a05_e2e_paid_media_fcst_data_m'[data_date] <= __TimeMax
                )
            )
        )

    // ═══════════════════════════════════════
    // #5 SLS ACH% Target 分母（SLS Target 值）
    // Month/Quarter: SUM(net_sales_amt) 按 platform/shop_id/data_month_name
    // Year: SUM(year_net_sales_amt) 按 platform/shop_id/data_year
    // ═══════════════════════════════════════
    VAR __Target_SLSAmt = 
        IF(
            __IsDayOrWeek,
            BLANK(),
            IF(
                __IsYear,
                CALCULATE(
                    SUMX(
                        SUMMARIZE(
                            'a05_e2e_paid_media_fcst_data_m',
                            'a05_e2e_paid_media_fcst_data_m'[platform],
                            'a05_e2e_paid_media_fcst_data_m'[shop_id],
                            'a05_e2e_paid_media_fcst_data_m'[data_year],
                            "__Value", MAX('a05_e2e_paid_media_fcst_data_m'[year_net_sales_amt])
                        ),
                        [__Value]
                    ),
                    'a05_e2e_paid_media_fcst_data_m'[data_date] >= __TimeMin,
                    'a05_e2e_paid_media_fcst_data_m'[data_date] <= __TimeMax
                ),
                CALCULATE(
                    SUMX(
                        SUMMARIZE(
                            'a05_e2e_paid_media_fcst_data_m',
                            'a05_e2e_paid_media_fcst_data_m'[platform],
                            'a05_e2e_paid_media_fcst_data_m'[shop_id],
                            'a05_e2e_paid_media_fcst_data_m'[data_month_name],
                            "__Value", MAX('a05_e2e_paid_media_fcst_data_m'[net_sales_amt])
                        ),
                        [__Value]
                    ),
                    'a05_e2e_paid_media_fcst_data_m'[data_date] >= __TimeMin,
                    'a05_e2e_paid_media_fcst_data_m'[data_date] <= __TimeMax
                )
            )
        )

    RETURN
        SWITCH(
            __MetricID,
            // ─── TRA ACH% 类指标 Target 值 ───
            3,  __Target_CostAmt,                  // #3 Cost ACH%：Cost Target 分母
            5,  __Target_SLSAmt,                   // #5 SLS ACH%：SLS Target 分母
            9,  __Target_MediaContrib,             // #9 Media Contribution% TRA ACH% Target
            12, __Target_CostPerNewAcq,            // #12 Media Cost Per New Acquisition TRA ACH% Target
            15, __Target_AccelCostMOB,             // #15 ± Accel Cost MOB% TRA ACH% Target
            18, __Target_NewCustNo,                // #18 New Customer No TRA ACH% Target
            21, __Target_AccelSLS,                 // #21 Acceleration SLS TRA ACH% Target
            24, __Target_AccelSLSMOB,              // #24 Acceleration SLS MOB% TRA ACH% Target
            BLANK()
        )
```

### 4.4 KPIs Base Value（总路由）

```dax
KPIs Base Value = 
// ========================================
// 度量值: KPIs Base Value
// Display Folder: Base Metrics
// 用途: 总路由，根据 Metric_ID 分发到 Actual / Target / ±Actual vs Target / vs LY / Cost vs SLS ACH%
// 依赖: [KPIs Current Base Value], [KPIs vsLP Base Value], [KPIs Target Base Value]
// 说明:
//   本期值 Metric_ID: 1,2,6,7,10,13,16,19,22
//   TRA ACH% 类（卡片值 = ±Actual vs Target）: 3,5,9,12,15,18,21,24
//   vs LY（增长率/差值）Metric_ID: 8,11,14,17,20,23
//   Cost vs SLS ACH%（派生差值）Metric_ID: 4 = Cost ACH% − SLS ACH%
// TRA ACH% 卡片值（±Actual vs Target，口径文档逐个指标给出公式，非统一）：
//   #3/#5: Actual - Target = DIVIDE(Cur, Tgt) - 1（Actual 本身含除法，Target=100%）
//   #9/#15/#24: Actual - Target（Actual 与 Target 均为比率，差值）
//   #12: Actual / Target - 1（金额增长率）
//   #18/#21: Actual / Target（达成率）
// Day/Week: 涉及时间粒度的 TRA ACH% 指标返回 BLANK
// ========================================
    VAR __MetricID = SELECTEDVALUE('Dim_ColMetric_KPIs'[Metric_ID])

    // ── 时间粒度判断 ──
    VAR __TimeFrameID = SELECTEDVALUE(Slicer_Time_Frame[TimeFrame_ID])
    VAR __IsDayOrWeek = __TimeFrameID IN {"Day", "Week"}

    // ── 修复上下文冲突：vs LY 派生行需读取对应本期和同期的 Metric_ID ──
    // vs LY 行（8/11/14/17/20/23）调用 Current/vsLP 时，需要切换到对应本期指标的 Metric_ID
    //   #8  vs LY（媒体新客贡献率）   → 本期 #7  / 同期 #7
    //   #11 vs LY（获客成本）         → 本期 #10 / 同期 #10
    //   #14 vs LY（± Accel cost MOB%）→ 本期 #13 / 同期 #13
    //   #17 vs LY（新客数量）         → 本期 #16 / 同期 #16
    //   #20 vs LY（Acceleration SLS） → 本期 #19 / 同期 #19
    //   #23 vs LY（Accel SLS MOB%）   → 本期 #22 / 同期 #22
    VAR __IsVSLY = __MetricID IN {8, 11, 14, 17, 20, 23}
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
    VAR __LPValue =
        IF(
            __IsVSLY,
            [KPIs vsLP Base Value],
            BLANK()
        )

    // ── vs LY 派生计算 ──
    // #8/#14/#23 → 当期值 − 同期值（差值，bp 指标）
    // #11/#17/#20 → 当期值 / 同期值 − 1（增长率，百分比）
    VAR __VSLYDiff = __CurrentValue - __LPValue
    VAR __VSLYGrowth =
        IF(
            ISBLANK(__LPValue) || __LPValue = 0,
            BLANK(),
            DIVIDE(__CurrentValue - __LPValue, __LPValue)
        )

    // ═══════════════════════════════════════
    // TRA ACH% 卡片值计算（映射表方式，与 vs LY 风格一致）
    // 卡片值 = ±Actual vs Target（口径文档逐个指标明确给出公式）
    // 汇率不在此层处理，统一在 Cell Value 层按 Metric_IsCurrencyAmount 判断
    // ═══════════════════════════════════════

    // ── TRA ACH% Actual Metric_ID 映射表（派生指标 ID → 本期指标 ID）──
    //   #3/#5 的 Actual = 自身（Current#3/#5 返回分子 SUM，Actual = DIVIDE(Cur, Tgt) 在公式中完成）
    //   #9/#12/#15/#18/#21/#24 的 Actual = 对应非 TRA ACH% 指标（#7/#10/#13/#16/#19/#22）
    VAR __IsTRA = __MetricID IN {3, 5, 9, 12, 15, 18, 21, 24}
    VAR __TRAActualID =
        SWITCH(
            __MetricID,
            9,  7,     // #9  Actual → #7  媒体新客贡献率
            12, 10,    // #12 Actual → #10 获客成本
            15, 13,    // #15 Actual → #13 ± Accel Cost MOB% vs Store SLS MOB%
            18, 16,    // #18 Actual → #16 新客数量
            21, 19,    // #21 Actual → #19 Acceleration SLS
            24, 22,    // #24 Actual → #22 Acceleration SLS MOB%
            __MetricID // #3/#5 用自身（Current#3/#5 返回分子 SUM）
        )

    // ── 统一取 Actual / Target 基础值（Day/Week 时留空）──
    VAR __TRAActual =
        IF(
            __IsDayOrWeek,
            BLANK(),
            CALCULATE(
                [KPIs Current Base Value],
                REMOVEFILTERS('Dim_ColMetric_KPIs'),
                'Dim_ColMetric_KPIs'[Metric_ID] = __TRAActualID
            )
        )
    VAR __TRATarget =
        IF(
            __IsDayOrWeek,
            BLANK(),
            CALCULATE(
                [KPIs Target Base Value],
                REMOVEFILTERS('Dim_ColMetric_KPIs'),
                'Dim_ColMetric_KPIs'[Metric_ID] = __MetricID
            )
        )

    // ── ±Actual vs Target 公式分发（逐个指标，口径文档给出）──
    //   #3/#5:   Actual - Target（Target=100%，Actual 本身=DIVIDE(Cur,Tgt)）→ DIVIDE(Actual, Target) - 1
    //   #9/#15/#24: Actual - Target（差值，bp）
    //   #12:     Actual / Target - 1（增长率，%）
    //   #18/#21: Actual / Target（达成率）
    VAR __TRAValue =
        IF(
            __IsDayOrWeek,
            BLANK(),
            SWITCH(
                __MetricID,
                3,  DIVIDE(__TRAActual, __TRATarget) - 1,   // #3 Cost ACH%
                5,  DIVIDE(__TRAActual, __TRATarget) - 1,   // #5 SLS ACH%
                9,  __TRAActual - __TRATarget,               // #9 Media Contribution% TRA ACH%
                12, DIVIDE(__TRAActual, __TRATarget) - 1,    // #12 Cost Per New Acq TRA ACH%
                15, __TRAActual - __TRATarget,               // #15 ± Accel Cost MOB% TRA ACH%
                18, DIVIDE(__TRAActual, __TRATarget),        // #18 New Customer No TRA ACH%
                21, DIVIDE(__TRAActual, __TRATarget),        // #21 Acceleration SLS TRA ACH%
                24, __TRAActual - __TRATarget,               // #24 Acceleration SLS MOB% TRA ACH%
                BLANK()
            )
        )

    // ── Cost vs SLS ACH% 派生（#4 = #3 Cost ACH% − #5 SLS ACH%，均为 ±Actual vs Target 卡片值）──
    //   #4 = DIVIDE(Cur#3, Tgt#3) - DIVIDE(Cur#5, Tgt#5)（达成率之差，-1 抵消）
    //   注：DAX 变量不可按不同 Metric_ID 重算，#4 需显式取 #3/#5 的 Current/Target
    VAR __CostVsSLSACH =
        IF(
            __IsDayOrWeek,
            BLANK(),
            DIVIDE(
                CALCULATE([KPIs Current Base Value], REMOVEFILTERS('Dim_ColMetric_KPIs'), 'Dim_ColMetric_KPIs'[Metric_ID] = 3),
                CALCULATE([KPIs Target Base Value], REMOVEFILTERS('Dim_ColMetric_KPIs'), 'Dim_ColMetric_KPIs'[Metric_ID] = 3)
            )
            -
            DIVIDE(
                CALCULATE([KPIs Current Base Value], REMOVEFILTERS('Dim_ColMetric_KPIs'), 'Dim_ColMetric_KPIs'[Metric_ID] = 5),
                CALCULATE([KPIs Target Base Value], REMOVEFILTERS('Dim_ColMetric_KPIs'), 'Dim_ColMetric_KPIs'[Metric_ID] = 5)
            )
        )

    RETURN
        SWITCH(
            __MetricID,
            // ─── 本期值（直接返回 Current）───
            1,  __CurrentValue,    // Media Cost Rate
            2,  __CurrentValue,    // Media Cost
            6,  __CurrentValue,    // SLS DCom
            7,  __CurrentValue,    // Media Contribution to New Customer Acquisition%
            10, __CurrentValue,    // Media Cost Per New Acquisition
            13, __CurrentValue,    // ± Acceleration cost MOB% vs. store SLS MOB%
            16, __CurrentValue,    // New Customer No
            19, __CurrentValue,    // Acceleration SLS
            22, __CurrentValue,    // Acceleration SLS MOB%
            // ─── TRA ACH%（卡片值 = ±Actual vs Target，映射表统一分发）───
            3,  __TRAValue,    // Cost ACH% = Actual - Target
            5,  __TRAValue,    // SLS ACH% = Actual - Target
            9,  __TRAValue,    // Media Contribution% TRA ACH% = Actual - Target
            12, __TRAValue,    // Cost Per New Acq TRA ACH% = Actual/Target - 1
            15, __TRAValue,    // ± Accel Cost MOB% TRA ACH% = Actual - Target
            18, __TRAValue,    // New Customer No TRA ACH% = Actual/Target
            21, __TRAValue,    // Acceleration SLS TRA ACH% = Actual/Target
            24, __TRAValue,    // Acceleration SLS MOB% TRA ACH% = Actual - Target
            // ─── 派生差值 ───
            4,  __CostVsSLSACH,    // Cost vs SLS ACH% = Cost ACH% − SLS ACH%（delta_bp）
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

### 4.5 KPIs Cell Value（对外值）

```dax
KPIs Cell Value = 
// ========================================
// 度量值: KPIs Cell Value
// Display Folder: Cell Values
// 用途: 对外暴露的单元格值；金额类指标在此层除以汇率换算为展示币种
// 依赖: [KPIs Base Value], 'Dim_ColMetric_KPIs'[Metric_IsCurrencyAmount],
//       Slicer_Currency_Selection[Currency_ExchangeRate]
// 汇率换算规则（仅在 Cell Value 层处理）:
//   - 金额类指标（Metric_IsCurrencyAmount=TRUE）：DIVIDE([Base Value], __FXRate)
//     涉及 Metric_ID: 2 Media Cost, 6 SLS DCom, 10 Media Cost Per New Acquisition, 19 Acceleration SLS
//   - 比率/计数/基点类指标（Metric_IsCurrencyAmount=FALSE）：直接返回 [Base Value]
// 说明: 切记是除法（÷ 汇率），不是乘法；比率类指标不涉及汇率换算
// ========================================
    VAR __BaseValue = [KPIs Base Value]
    VAR __IsCurrencyAmount = SELECTEDVALUE('Dim_ColMetric_KPIs'[Metric_IsCurrencyAmount], FALSE)
    VAR __FXRate = SELECTEDVALUE(Slicer_Currency_Selection[Currency_ExchangeRate], 1)
    VAR __Value =
        IF(
            __IsCurrencyAmount,
            DIVIDE(__BaseValue, __FXRate),    // 金额类：÷ 汇率
            __BaseValue                        // 比率/计数/基点类：不换算
        )
    RETURN
        __Value
```

### 4.6 KPIs Cell Display（格式化显示）

```dax
KPIs Cell Display = 
// ========================================
// 度量值: KPIs Cell Display
// Display Folder: Formatting
// 用途: 根据 Metric_Format 返回格式化后的文本
// 依赖: [KPIs Cell Value], 'Dim_ColMetric_KPIs'[Metric_Format]
// 格式类型（严格遵循口径文档 KPI Progress.md 数据类型定义）:
//   integer               → 整数千分位：1,000                                      格式串: #,##0
//   currency              → 货币符号 + 千分位整数：¥1,000                           格式串: #,##0
//   currency_decimal_1dp  → 货币符号 + 千分位一位小数：¥1,000.0                    格式串: #,##0.0
//   currency_M_K_Int_0db  → 货币符号 + 整数/M/K 单位（0位小数）：¥999\¥1.5K\¥1.5M
//   percent_1dp           → 百分比一位小数，不含正号：14.5%                         格式串: 0.0%
//   delta_bp              → 增减基点整数，含正负号：+120bp / -80bp
//                           （值×10000 转 bp 的操作在此处实现）
// 说明:
//   - BLANK 显示为 "-"
//   - delta_bp 的正确写法：IF(__Value > 0, "+", "") & FORMAT(__Value * 10000, "#,##0") & "bp"
//   - 货币符号由 Slicer_Currency_Selection[Currency_Symbol] 决定（默认 "¥"）
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
                // ─── 整数与小数 ─────────────────────────────────
                "integer",
                    FORMAT(__Value, "#,##0"),                                             // 1,000
                // ─── 货币格式 ─────────────────────────────────────
                "currency",
                    __CurrencySymbol & FORMAT(__Value, "#,##0"),                          // ¥1,000
                "currency_decimal_1dp",
                    __CurrencySymbol & FORMAT(__Value, "#,##0.0"),                        // ¥1,000.0
                "currency_M_K_Int_0db",
                    IF(
                        __Value < 1000,
                        __CurrencySymbol & FORMAT(__Value, "#,##0"),
                        IF(
                            __Value < 1000000,
                            __CurrencySymbol & FORMAT(__Value / 1000, "#,##0.0") & "K",
                            __CurrencySymbol & FORMAT(__Value / 1000000, "#,##0.0") & "M"
                        )
                    ),                                                                  // ¥999\¥1.5K\¥1.5M
                // ─── 百分比（不含正号）──────────────────────
                "percent_1dp",
                    FORMAT(__Value, "0.0%"),                                             // 14.5%
                // ─── 增减基点（含正负号，值×10000 转 bp）─────
                "delta_bp",
                    IF(__Value > 0, "+", "") & FORMAT(__Value * 10000, "#,##0") & "bp",  // +120bp / -80bp
                // ─── 默认 ─────────────────────────────────
                FORMAT(__Value, "#,##0.00")
            )
        )
```

### 4.7 KPIs Cell Font Color（字体颜色）

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

### 4.8 KPIs Cell Background Color（背景色）

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

### 4.9 KPIs Cell SVG Icon（SVG 图标）

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

| 序号 | 度量值名称                 | Display Folder | 用途                                             |
| ---- | -------------------------- | -------------- | ------------------------------------------------ |
| 1    | KPIs Current Base Value    | Base Metrics   | 本期基础值（原始本币，不换算汇率）               |
| 2    | KPIs vsLP Base Value       | Base Metrics   | 去年同期基础值（读取 TimeFrame_Min_LY/Max_LY，原始本币） |
| 3    | KPIs Target Base Value     | Base Metrics   | 目标基础值（8 个 TRA ACH% 类指标的 Target）      |
| 4    | KPIs Base Value            | Base Metrics   | 总路由（含 TRA ACH% ±Actual vs Target / vs LY / Cost vs SLS 派生，原始本币） |
| 5    | KPIs Cell Value            | Cell Values    | 对外值；金额类指标在此层 ÷ 汇率换算为展示币种    |
| 6    | KPIs Cell Display          | Formatting     | 格式化显示文本                                   |
| 7    | KPIs Cell Font Color       | Formatting     | 字体颜色（仅 8 个指标启用条件色）                |
| 8    | KPIs Cell Background Color | Formatting     | 背景色（统一白色）                               |
| 9    | KPIs Cell SVG Icon         | Formatting     | SVG 图标（仅 6 个 vs LY 指标）                   |

---

## 6. 指标口径来源对照

| Metric_ID | Metric_Name                                              | 数据底表（实际值）                                                 | 数据底表（Target）                        | 计算公式                                               | customer_type | framework / mix_msg 筛选                          | 数据类型             |
| --------- | -------------------------------------------------------- | ------------------------------------------------------------------ | ----------------------------------------- | ------------------------------------------------------ | ------------- | ------------------------------------------------- | -------------------- |
| 1         | Media Cost Rate                                          | a05_e2e_paid_media_summary_d                                       | -                                         | Cost / SLS × 1.13 / 1.06                              | ALL           | -                                                 | percent_1dp          |
| 2         | Media Cost                                               | a05_e2e_paid_media_summary_d                                       | -                                         | SUM(cost_amt)                                         | ALL           | -                                                 | currency             |
| 3         | Cost ACH%                                                | 分子：a05_e2e_paid_media_summary_d；分母：a05_e2e_paid_media_fcst_data_m | a05_e2e_paid_media_fcst_data_m            | SUM(cost_amt) / Cost Target；Target=100%              | ALL           | -                                                 | percent_1dp          |
| 4         | Cost vs SLS ACH%                                         | 派生                                                               | -                                         | Cost ACH% − SLS ACH%                                  | ALL           | -                                                 | delta_bp             |
| 5         | SLS ACH%                                                 | 分子：a05_e2e_paid_media_summary_d；分母：a05_e2e_paid_media_fcst_data_m | a05_e2e_paid_media_fcst_data_m            | SUM(net_sales_amt) / SLS Target；Target=100%          | ALL           | -                                                 | percent_1dp          |
| 6         | SLS DCom                                                 | a05_e2e_paid_media_summary_d                                       | -                                         | SUM(net_sales_amt)                                    | ALL           | -                                                 | currency             |
| 7         | Media Contribution to New Customer Acquisition%          | 分子：a05_e2e_paid_media_summary_d；分母：a03_e2e_customer_data_m | -                                         | MAX+SUM(media_member_cnt) / DISTINCTCOUNT(user_id)    | ALL（分子）   | 媒体新客 MAX+SUM；全店新客合并区间                 | percent_1dp          |
| 8         | Media Contribution to New Customer Acquisition% vs LY    | 同 #7                                                              | -                                         | 当期值 − 同期值（bp）                                 | ALL（分子）   | 同 #7                                             | delta_bp             |
| 9         | Media Contribution to New Customer Acquisition% TRA ACH% | Actual 同 #7；Target：a05_e2e_paid_media_fcst_data_m              | a05_e2e_paid_media_fcst_data_m            | Actual / Target；±Actual vs Target = Actual - Target   | ALL（分子）   | 同 #7                                             | percent_1dp          |
| 10        | Media Cost Per New Acquisition                           | a05_e2e_paid_media_summary_d                                       | -                                         | MAX+SUM(media_cost_amt) / MAX+SUM(media_member_cnt)   | ALL           | 媒体新客字段 MAX+SUM 聚合                         | currency_decimal_1dp |
| 11        | Media Cost Per New Acquisition vs LY                     | 同 #10                                                             | -                                         | 当期值 / 同期值 − 1                                   | ALL           | 同 #10                                            | percent_1dp          |
| 12        | Media Cost Per New Acquisition TRA ACH%                  | Actual 同 #10；Target：a05_e2e_paid_media_fcst_data_m             | a05_e2e_paid_media_fcst_data_m            | Actual / Target；±Actual vs Target = Actual/Target - 1 | ALL           | 媒体新客字段 MAX+SUM 聚合                         | percent_1dp          |
| 13        | ± Acceleration cost MOB% vs. store SLS MOB%             | a05_e2e_paid_media_product_data_d                                    | -                                         | Accel Cost MOB% − Store SLS MOB%                      | ALL           | Cost 分子：mix_msg=NULL AND Accel；SLS 分子：Accel | percent_1dp          |
| 14        | ± Acceleration cost MOB% vs. store SLS MOB% vs LY       | 同 #13                                                             | -                                         | 当期值 − 同期值（bp）                                 | ALL           | 同 #13                                            | delta_bp             |
| 15        | ± Acceleration SLS MOB% vs. store SLS MOB% TRA ACH%     | Actual 同 #13；Target：a05_e2e_paid_media_fcst_data_m             | a05_e2e_paid_media_fcst_data_m            | Actual / Target；±Actual vs Target = Actual - Target   | ALL           | 同 #13                                            | percent_1dp          |
| 16        | New Customer No                                          | a03_e2e_customer_data_m                                            | -                                         | DISTINCTCOUNT(user_id)，合并区间筛选                  | -             | net_pay_amt>0 AND is_member=0 AND lp_12m=0        | integer              |
| 17        | New Customer No vs LY                                    | 同 #16                                                             | -                                         | 当期值 / 同期值 − 1                                   | -             | 同 #16                                            | percent_1dp          |
| 18        | New Customer No TRA ACH%                                 | Actual 同 #16；Target：a05_e2e_paid_media_fcst_data_m             | a05_e2e_paid_media_fcst_data_m            | Actual / Target；±Actual vs Target = Actual - Target   | -             | 同 #16                                            | percent_1dp          |
| 19        | Acceleration SLS                                         | a05_e2e_paid_media_product_data_d                                    | -                                         | SUM(net_sales_amt) WHERE framework='Acceleration'     | ALL           | framework='Acceleration'                           | currency             |
| 20        | Acceleration SLS vs LY                                   | 同 #19                                                             | -                                         | 当期值 / 同期值 − 1                                   | ALL           | framework='Acceleration'                           | percent_1dp          |
| 21        | Acceleration SLS TRA ACH%                                | Actual 同 #19；Target：a05_e2e_paid_media_fcst_data_m             | a05_e2e_paid_media_fcst_data_m            | Actual / Target；±Actual vs Target = Actual - Target   | ALL           | framework='Acceleration'                           | percent_1dp          |
| 22        | Acceleration SLS MOB%                                    | a05_e2e_paid_media_product_data_d                                    | -                                         | Accel SLS / TTL SLS                                   | ALL           | 分子：Accel；分母：全部 framework                  | percent_1dp          |
| 23        | Acceleration SLS MOB% vs LY                              | 同 #22                                                             | -                                         | 当期占比 − 同期占比（bp）                             | ALL           | 同 #22                                            | delta_bp             |
| 24        | Acceleration SLS MOB% TRA ACH%                           | Actual 同 #22；Target：a05_e2e_paid_media_fcst_data_m             | a05_e2e_paid_media_fcst_data_m            | Actual / Target；±Actual vs Target = Actual - Target   | ALL           | 同 #22                                            | percent_1dp          |

---

## 7. 血缘关系图（Lineage Diagram）

```
┌─────────────────────────────────────────────────────────────────────┐
│                        数据源层                                      │
│                                                                     │
│  a05_e2e_paid_media_summary_d（汇总指标事实表）                      │
│  字段: data_date, platform, shop_id, data_month_name,               │
│        customer_type, page_type, cost_amt, net_sales_amt,           │
│        media_member_cnt, media_cost_amt                             │
│                                                                     │
│  a05_e2e_paid_media_product_data_d（第二品类事实表）                    │
│  字段: data_date, platform, shop_id, framework, mix_msg,            │
│        cost_amt, net_sales_amt                                      │
│                                                                     │
│  a03_e2e_customer_data_m（全店新客事实表）                            │
│  字段: data_date, platform, shop_info_id, user_id,                  │
│        net_pay_amt, is_member, lp_12m_net_pay_amt                   │
│                                                                     │
│  a05_e2e_paid_media_fcst_data_m（预测/目标事实表）                   │
│  字段: data_date, platform, shop_id, data_month_name, data_year,    │
│        cost_amt, year_cost_amt, net_sales_amt, year_net_sales_amt,  │
│        media_new_customer_cnt, new_customer_cnt,                    │
│        media_new_customer_cost_amt, year_media_new_customer_...,    │
│        year_cost_per_new_acquisition, acceleration_cost_amt,        │
│        acceleration_net_sales_amt, year_acceleration_cost_rate_..., │
│        year_new_customer_cnt, year_acceleration_net_sales_amt,      │
│        year_acceleration_net_sales_rate                             │
└──────────────────────────────┬──────────────────────────────────────┘
                               │
                               │ 1:N 关系（模型自动筛选）+ 断开维度
                               │
              ┌────────────────┼────────────────┐
              │                │                │
              ▼                ▼                ▼
┌──────────────────┐ ┌──────────────────┐ ┌──────────────────┐
│ Slicer_Platform_  │ │ Slicer_Store_    │ │ Slicer_Time_     │
│ Selection         │ │ Name             │ │ Frame             │
│ (Platform_ID)     │ │ (Store_ID)       │ │ (TimeFrame_ID)   │
└──────────────────┘ └──────────────────┘ └──────────────────┘
                                              │
                    ┌─────────────────────────┤
                    │                         │
                    ▼                         ▼
          ┌──────────────────┐    ┌──────────────────┐
          │ Slicer_Time_     │    │ Slicer_Currency_ │
          │ Frame_Min/Max    │    │ Selection        │
          │ (TimeFrame_Min/  │    │ (ExchangeRate,   │
          │  Max)            │    │  Symbol)         │
          └──────────────────┘    └──────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│                        度量值层                                      │
│                                                                     │
│  ┌─────────────────────────┐   ┌─────────────────────────┐          │
│  │ KPIs Current Base Value │   │ KPIs vsLP Base Value    │          │
│  │ (本期 9+8 个 Metric_ID)  │   │ (同期 6 个 vs LY 派生)   │          │
│  └───────────┬─────────────┘   └───────────┬─────────────┘          │
│              │                              │                        │
│  ┌───────────┴─────────────┐               │                        │
│  │ KPIs Target Base Value  │               │                        │
│  │ (目标 8 个 TRA ACH%)     │               │                        │
│  └───────────┬─────────────┘               │                        │
│              │                              │                        │
│              │    ┌─────────────────────────┘                        │
│              │    │                                                  │
│              ▼    ▼                                                  │
│  ┌─────────────────────────┐                                        │
│  │ KPIs Base Value         │                                        │
│  │ (总路由 + TRA ACH% ±Actual vs Target │                                        │
│  │  + vs LY / Cost vs SLS) │                                        │
│  └───────────┬─────────────┘                                        │
│              │                                                      │
│              ▼                                                      │
│  ┌─────────────────────────┐                                        │
│  │ KPIs Cell Value         │                                        │
│  │ (= Base Value)          │                                        │
│  └───────────┬─────────────┘                                        │
│              │                                                      │
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

### 8.1 TRA ACH% 卡片值结构（卡片值 = ±Actual vs Target）

TRA ACH% 类指标的卡片值 = 口径文档中每个指标明确给出的 ±Actual vs Target 公式（非统一 Actual/Target，逐个不同）：

| Metric_ID | 指标名                                  | Actual 来源        | Target 来源                   | ±Actual vs Target（卡片值） | DAX 实现 |
| --------- | --------------------------------------- | ------------------ | ----------------------------- | --------------------------- | -------- |
| 3         | Cost ACH%                               | SUM(cost_amt) / Cost Target（fcst 表） | 100%（固定）           | Actual - Target             | DIVIDE(Cur#3, Tgt#3) - 1 |
| 5         | SLS ACH%                                | SUM(net_sales_amt) / SLS Target（fcst 表） | 100%（固定）      | Actual - Target             | DIVIDE(Cur#5, Tgt#5) - 1 |
| 9         | Media Contribution% TRA ACH%            | 同 #7              | fcst 表 SUMX+SUMMARIZE       | Actual - Target             | Cur#7 - Tgt#9 |
| 12        | Media Cost Per New Acquisition TRA ACH% | 同 #10             | fcst 表 SUMX+SUMMARIZE       | Actual / Target - 1         | DIVIDE(Cur#10, Tgt#12) - 1 |
| 15        | ± Accel Cost MOB% TRA ACH%              | 同 #13             | fcst 表 SUMX+SUMMARIZE       | Actual - Target             | Cur#13 - Tgt#15 |
| 18        | New Customer No TRA ACH%                | 同 #16             | fcst 表 SUMX+SUMMARIZE       | Actual / Target             | DIVIDE(Cur#16, Tgt#18) |
| 21        | Acceleration SLS TRA ACH%               | 同 #19             | fcst 表 SUMX+SUMMARIZE       | Actual / Target             | DIVIDE(Cur#19, Tgt#21) |
| 24        | Acceleration SLS MOB% TRA ACH%          | 同 #22             | fcst 表 SUMX+SUMMARIZE       | Actual - Target             | Cur#22 - Tgt#24 |

说明：
- 实现方式：映射表 `__TRAActualID`（9→7, 12→10, 15→13, 18→16, 21→19, 24→22, 3→3, 5→5）+ 统一取值 `__TRAActual`/`__TRATarget` + SWITCH 分发公式，与 vs LY 风格一致
- #3/#5 的 Actual 本身 = SUM/Target（含除法），Target=100%，故卡片值 = Actual - 1
- #9/#15/#24 的 Actual 与 Target 均为比率，卡片值 = Actual - Target（差值）
- #12 的 Actual 与 Target 均为金额，卡片值 = Actual/Target - 1（增长率）
- #18/#21 的 Actual 为计数/金额，Target 为目标值，卡片值 = Actual/Target（达成率）
- #4 Cost vs SLS ACH% 派生：DAX 变量不可按不同 Metric_ID 重算，#4 需显式取 #3/#5 的 Current/Target

Target 缺失处理：
- Target 缺失时，Target 及 ±Actual vs Target 展示"-"
- #12 Cost Per New Acquisition 额外处理：Target=0 或汇总后 `media_member_cnt`=0 时，Actual 及 ±Actual vs Target 展示"-"

### 8.2 vs LY 派生计算分类

| Metric_ID | 指标名                               | 派生方式                   | 数据类型    |
| --------- | ------------------------------------ | -------------------------- | ----------- |
| 8         | Media Contribution vs LY             | 当期值 − 同期值（bp）     | delta_bp    |
| 11        | Media Cost Per New Acquisition vs LY | 当期/同期 − 1（%）        | percent_1dp |
| 14        | ± Accel cost MOB% vs LY             | 当期值 − 同期值（bp）     | delta_bp    |
| 17        | New Customer No vs LY                | 当期/同期 − 1（%）        | percent_1dp |
| 20        | Acceleration SLS vs LY               | 当期/同期 − 1（%）        | percent_1dp |
| 23        | Acceleration SLS MOB% vs LY          | 当期占比 − 同期占比（bp） | delta_bp    |

### 8.3 Day/Week 留空规则

涉及时间粒度判断的指标在 `Slicer_Time_Frame[TimeFrame_ID] IN {"Day","Week"}` 时返回 BLANK：

| 指标类别             | Metric_ID                    | 留空原因                                   |
| -------------------- | ---------------------------- | ------------------------------------------ |
| TRA ACH% 类          | 3, 5, 9, 12, 15, 18, 21, 24 | Target 按财月/财季/财年粒度取数             |
| 媒体新客聚合类       | 7, 9, 10, 12                 | media_member_cnt/media_cost_amt 需 MAX+SUM |
| 新客类               | 16, 17, 18                   | 全店新客判定依赖完整财月                    |
| vs LY 派生           | 8, 11, 14, 17, 20, 23        | 间接受上述影响（同期值留空则 vs LY 留空）   |

### 8.4 汇率换算规则

汇率换算**仅在 KPIs Cell Value 层处理**，Base Metrics 层（Current/vsLP/Target/Base Value）一律返回原始本币值，避免比值计算错误。

| 指标类型 | 换算方式 | 判断依据 | 涉及 Metric_ID |
| -------- | -------- | -------- | -------------- |
| 金额类 | `DIVIDE([Base Value], Currency_ExchangeRate)`（除法，非乘法） | `Metric_IsCurrencyAmount = TRUE` | 2, 6, 10, 19 |
| 比率/计数/基点类 | 不换算，直接返回 [Base Value] | `Metric_IsCurrencyAmount = FALSE` | 1, 3, 4, 5, 7, 8, 9, 11, 12, 13, 14, 15, 16, 17, 18, 20, 21, 22, 23, 24 |

### 8.5 第二品类（Acceleration）筛选规则

| 指标类型 | 分子筛选                                          | 分母筛选                     |
| -------- | ------------------------------------------------- | ---------------------------- |
| Cost 类  | `mix_msg IS NULL AND framework = "Acceleration"`  | `mix_msg IS NULL`（不限 framework） |
| SLS 类   | `framework = "Acceleration"`（不限 mix_msg）      | 全部 framework（不限 mix_msg）      |

涉及 Metric_ID：13, 14, 15, 19, 20, 21, 22, 23, 24

### 8.6 媒体新客字段聚合规则

- 字段：`media_member_cnt`、`media_cost_amt`
- 聚合方式：先按 `platform`、`shop_id`、`data_month_name`（包含 `data_year` + `data_month` 属性）取 `MAX`，再对所选财月及平台 `SUM`
- 仅支持完整财月、财季、财年，`Day`/`Week` 时为空
- DAX 实现：`SUMX(SUMMARIZE(..., "__Value", MAX([字段])), [__Value])`
- 涉及 Metric_ID：7, 9, 10, 12

### 8.7 全店新客判定规则

- 数据底表：`a03_e2e_customer_data_m`
- Step1 + Step2 交集（合并区间简化实现）：
  - Step1：在所选时间范围内筛选 `net_pay_amt > 0` 的 `user_id`（`data_date ∈ [__TimeMin, __TimeMax]`，`is_member = 0`，`net_pay_amt > 0`）
  - Step2：缩小顾客范围至 `lp_12m_net_pay_amt = 0`（`data_date ∈ start_period`）
  - start_period = 第一财月，是 slicer 区间的子集，合并区间后单一 CALCULATE 即可
  - **合并区间等价实现**：`data_date ∈ [First_Fiscal_Month_Min, First_Fiscal_Month_Max] AND net_pay_amt > 0 AND is_member = 0 AND lp_12m_net_pay_amt = 0`
- 第一财月区间由 `Slicer_Time_Frame_Min` 维度表提供（`First_Fiscal_Month`、`First_Fiscal_Month_Min`、`First_Fiscal_Month_Max`）：
  - 月 = 自身（如 2026-09 → 2026-09）
  - 季 = Q1→01, Q2→04, Q3→07, Q4→10（如 2026 Q2 → 2026-04）
  - 年 = 01（如 财年 2026 → 2026-01）
- vs LY 时使用 `First_Fiscal_Month_Min_LY` / `First_Fiscal_Month_Max_LY`（去年同期第一财月）
- 聚合方式：`DISTINCTCOUNT(user_id)`
- 涉及 Metric_ID：7, 8, 9, 16, 17, 18

### 8.8 筛选器公用说明

本模块与 Category Growth/KPI_Breakdown 共用筛选器：

- **Slicer_Time_Frame**：断开维度，SELECTEDVALUE 读取 TimeFrame_ID（时间粒度）
- **Slicer_Time_Frame_Min/Max**：断开维度，SELECTEDVALUE 读取本期时间范围（TimeFrame_Min/Max）及 LY 时间范围（TimeFrame_Min_LY/TimeFrame_Max_LY，财历映射）；Slicer_Time_Frame_Min 另提供第一财月系列字段（First_Fiscal_Month_Min/Max 本期、First_Fiscal_Month_Min_LY/Max_LY 去年同期），用于新客 Step2 的 start_period 筛选
- **Slicer_Platform_Selection**：1:N 关系，模型自动筛选，不在 DAX 中写显式筛选
- **Slicer_Store_Name**：1:N 关系，模型自动筛选，不在 DAX 中写显式筛选
- **Slicer_Currency_Selection**：断开维度，**仅在 Cell Value 层换算**：金额类指标（`Metric_IsCurrencyAmount=TRUE`）`DIVIDE([Base Value], Currency_ExchangeRate)`（除法），非金额类指标不受汇率影响
- **trans_cycle**：1:N 关系，模型自动筛选

### 8.9 字体颜色启用清单

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

### 9.1 基础验证

| 验证项     | 方法                                                       |
| ---------- | ---------------------------------------------------------- |
| 矩阵列数   | 确认 24 列（Metric_ID 1~24，无跳号）                       |
| 列排序     | 列按 Metric_Sort 排序（10, 20, 30, ... 240）               |
| 金额类指标 | #2/#6/#10/#19 切换币种时数值变化（RMB÷1 / USD÷7），仅 Cell Value 层换算 |
| vs LY 派生 | #8/#14/#23 为差值（bp）；#11/#17/#20 为增长率（%）         |
| 字体颜色   | 仅 #4/#6/#8/#11/#14/#17/#20/#23 启用条件色，其余为 #252423 |
| SVG 图标   | 仅 #8/#11/#14/#17/#20/#23 显示圆形图标                     |
| Day/Week   | #3/#5/#7/#9/#10/#12/#15/#16/#17/#18/#21/#24 在 Day/Week 时为空 |
| 汇率换算层 | 仅在 Cell Value 层÷汇率（Base Metrics 层返回原始本币值）    |
| vs LY 时间 | 读取 TimeFrame_Min_LY/TimeFrame_Max_LY（财历映射，非 EDATE） |

### 9.2 数据验证 SQL

```sql
-- Media Cost Rate（#1）
SELECT DIVIDE(SUM(cost_amt), SUM(net_sales_amt)) * 1.13 / 1.06 AS MediaCostRate
FROM a05_e2e_paid_media_summary_d
WHERE customer_type='ALL' AND page_type='1'
  AND data_date BETWEEN '__TimeMin' AND '__TimeMax';

-- Media Cost（#2）金额类，Cell Value 层÷汇率（验证时对比 Cell Value）
SELECT SUM(cost_amt) / __FXRate AS MediaCost
FROM a05_e2e_paid_media_summary_d
WHERE customer_type='ALL' AND page_type='1'
  AND data_date BETWEEN '__TimeMin' AND '__TimeMax';

-- Cost ACH%（#3）Actual = SUM(cost_amt) / Cost Target
-- Cost Target 来自 a05_e2e_paid_media_fcst_data_m（SUMX+SUMMARIZE）
SELECT
  SUM(cost_amt) / __CostTarget AS CostACH
FROM a05_e2e_paid_media_summary_d
WHERE customer_type='ALL' AND page_type='1'
  AND data_date BETWEEN '__TimeMin' AND '__TimeMax';

-- Media Contribution to New Customer Acquisition%（#7）
-- 分子：MAX+SUM(media_member_cnt)
-- 分母：DISTINCTCOUNT(user_id) from a03_e2e_customer_data_m
SELECT
  __MediaNewCustCnt / __TotalNewCustCnt AS MediaContrib
-- 分子 SQL（先 MAX 再 SUM）
SELECT
  platform, shop_id, data_month_name,
  MAX(media_member_cnt) AS max_media_member_cnt
FROM a05_e2e_paid_media_summary_d
WHERE customer_type='ALL' AND page_type='1'
  AND data_date BETWEEN '__TimeMin' AND '__TimeMax'
GROUP BY platform, shop_id, data_month_name;
-- 然后对 max_media_member_cnt 做 SUM
-- 分母 SQL
SELECT COUNT(DISTINCT user_id) AS TotalNewCust
FROM a03_e2e_customer_data_m
WHERE data_date BETWEEN '__FirstFiscalMonthMin' AND '__FirstFiscalMonthMax'
  AND net_pay_amt > 0 AND is_member = 0 AND lp_12m_net_pay_amt = 0;

-- ± Accel cost MOB% vs. store SLS MOB%（#13）
-- Cost 分子：mix_msg IS NULL AND framework='Acceleration'
-- Cost 分母：mix_msg IS NULL
-- SLS 分子：framework='Acceleration'
-- SLS 分母：全部 framework
SELECT
  (SUM(CASE WHEN mix_msg IS NULL AND framework='Acceleration' THEN cost_amt END)
   / SUM(CASE WHEN mix_msg IS NULL THEN cost_amt END))
  - (SUM(CASE WHEN framework='Acceleration' THEN net_sales_amt END)
   / SUM(net_sales_amt)) AS AccelCostMOBvsSLS
FROM a05_e2e_paid_media_product_data_d
WHERE data_date BETWEEN '__TimeMin' AND '__TimeMax';

-- New Customer No（#16）
SELECT COUNT(DISTINCT user_id) AS NewCustomerNo
FROM a03_e2e_customer_data_m
WHERE data_date BETWEEN '__FirstFiscalMonthMin' AND '__FirstFiscalMonthMax'
  AND net_pay_amt > 0 AND is_member = 0 AND lp_12m_net_pay_amt = 0;

-- Acceleration SLS（#19）金额类，Cell Value 层÷汇率（验证时对比 Cell Value）
SELECT SUM(net_sales_amt) / __FXRate AS AccelSLS
FROM a05_e2e_paid_media_product_data_d
WHERE framework='Acceleration'
  AND data_date BETWEEN '__TimeMin' AND '__TimeMax';

-- Acceleration SLS MOB%（#22）
SELECT
  SUM(CASE WHEN framework='Acceleration' THEN net_sales_amt END)
  / SUM(net_sales_amt) AS AccelSLSMOB
FROM a05_e2e_paid_media_product_data_d
WHERE data_date BETWEEN '__TimeMin' AND '__TimeMax';
```

### 9.3 Target 验证 SQL

```sql
-- #3 Cost ACH% Target（Month/Quarter 粒度）
-- SUM(cost_amt) 按 platform/shop_id/data_month_name 分组聚合
SELECT
  platform, shop_id, data_month_name,
  MAX(cost_amt) AS cost_target
FROM a05_e2e_paid_media_fcst_data_m
WHERE data_date BETWEEN '__TimeMin' AND '__TimeMax'
GROUP BY platform, shop_id, data_month_name;
-- 然后对 cost_target 做 SUM

-- #3 Cost ACH% Target（Year 粒度）
-- MAX(year_cost_amt) 按 platform/shop_id/data_year 分组聚合
SELECT
  platform, shop_id, data_year,
  MAX(year_cost_amt) AS cost_target
FROM a05_e2e_paid_media_fcst_data_m
WHERE data_date BETWEEN '__TimeMin' AND '__TimeMax'
GROUP BY platform, shop_id, data_year;
-- 然后对 cost_target 做 SUM

-- #9 Media Contribution% Target（Month/Quarter 粒度）
-- SUM(media_new_customer_cnt) / SUM(new_customer_cnt)
SELECT
  SUM(media_new_customer_cnt) / SUM(new_customer_cnt) AS target
FROM a05_e2e_paid_media_fcst_data_m
WHERE data_date BETWEEN '__TimeMin' AND '__TimeMax';

-- #12 Cost Per New Acquisition Target（Month/Quarter 粒度）
-- SUM(media_new_customer_cost_amt) / SUM(media_new_customer_cnt)
SELECT
  SUM(media_new_customer_cost_amt) / SUM(media_new_customer_cnt) AS target
FROM a05_e2e_paid_media_fcst_data_m
WHERE data_date BETWEEN '__TimeMin' AND '__TimeMax';

-- #18 New Customer No Target（Month/Quarter 粒度）
-- SUM(new_customer_cnt)
SELECT SUM(new_customer_cnt) AS target
FROM a05_e2e_paid_media_fcst_data_m
WHERE data_date BETWEEN '__TimeMin' AND '__TimeMax';

-- #18 New Customer No Target（Year 粒度）
-- MAX(year_new_customer_cnt)
SELECT MAX(year_new_customer_cnt) AS target
FROM a05_e2e_paid_media_fcst_data_m
WHERE data_date BETWEEN '__TimeMin' AND '__TimeMax';

-- #21 Acceleration SLS Target（Month/Quarter 粒度）
-- SUM(acceleration_net_sales_amt)
SELECT SUM(acceleration_net_sales_amt) AS target
FROM a05_e2e_paid_media_fcst_data_m
WHERE data_date BETWEEN '__TimeMin' AND '__TimeMax';
```

### 9.4 vs LY 验证

验证 vs LY 值时，将 SQL 中的日期范围替换为 `Slicer_Time_Frame_Min[TimeFrame_Min_LY]` 和 `Slicer_Time_Frame_Max[TimeFrame_Max_LY]` 对应的日期范围（日期表内置财历映射 LY 字段），对比 DAX 计算结果。

注：金额类指标（#2/#6/#10/#19）的 vs LY 派生值在 Cell Value 层会除以汇率，验证 SQL 中的金额也需 ÷ `Currency_ExchangeRate` 后再对比。

### 9.5 Day/Week 留空验证

设置 Slicer_Time_Frame[TimeFrame_ID] 为 "Day" 或 "Week"，验证以下指标返回 BLANK（展示"-"）：
#3, #5, #7, #8, #9, #10, #11, #12, #15, #16, #17, #18, #21, #24
