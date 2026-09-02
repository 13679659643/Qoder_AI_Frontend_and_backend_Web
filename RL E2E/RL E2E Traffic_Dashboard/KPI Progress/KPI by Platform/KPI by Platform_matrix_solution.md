# Power BI 中国式报表解决方案 — KPI by Platform 矩阵

> status: updated
> created: 2026-07-14
> updated: 2026-09-01
> complexity: 🟡中等
> type: 度量值开发 + 可视化构建
> 口径来源: 口径文档/KPI Progress.md 子模块五：KPI by Platform
> 参考: Cell Display模板文件.md

---

## 1. 需求理解

实现"KPI by Platform"中国式矩阵效果：

- **行**：店铺维度 Slicer_Store_Name[Store_ID]，复用已有店铺维度表
- **列**：指标维度 'Dim_ColMetric_KPI by Platform'[Metric_Name]，15 个指标（Metric_ID 1~15）
- **值**：SWITCH 动态路由，按 Metric_ID 分发到本期 / vs LP / YOY%
- **口径**：一切以口径文档 KPI Progress.md 子模块五为准
- **特殊要求**：
  - YOY% 行后缀空格数不同（YOY% / YOY % / YOY  % / YOY   % / YOY    %）以区分同名指标
  - 总计行（非 ISINSCOPE）字体黑色 #252423、背景中米色 #E6D9C7
  - 其他行字体深灰 #5F6165、背景白色 #FFFFFF
  - 仅 YOY% 指标显示 SVG 图标（复用 KPI Breakdown Cell SVG Icon 设计）

---

## 2. 现状分析

### 2.1 数据底表

| 对象     | 名称                                                                                                                                                     | 出处                                      |
| -------- | -------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------- |
| 事实表   | a05_e2e_paid_media_summary_d                                                                                                                             | 汇总指标（#31/#32/#34/#35）              |
| 事实表   | a05_e2e_paid_media_product_data_d                                                                                                                        | 第二品类（#33，framework/mix_msg 筛选）   |
| 事实表   | a03_e2e_customer_data_m                                                                                                                                  | 全店新客（#34 分母，DISTINCTCOUNT user_id）|
| 关键字段 | data_date, platform, store_name, trans_cycle, customer_type, page_type, framework, mix_msg, cost_amt, net_sales_amt, media_member_cnt, media_cost_amt, user_id, net_pay_amt, is_member, lp_12m_net_pay_amt | 口径文档 KPI Progress.md 子模块五         |

### 2.2 维度表清单

| 维度表                        | 类型     | 连接方式                                                  | 出处                                       |
| ----------------------------- | -------- | --------------------------------------------------------- | ------------------------------------------ |
| Slicer_Time_Frame             | 断开维度 | SELECTEDVALUE 读取 TimeFrame_ID                          | 维度复用/Slicer_Time_Frame                 |
| Slicer_Time_Frame_Min         | 断开维度 | SELECTEDVALUE 读取 TimeFrame_Min / TimeFrame_Min_LY / First_Fiscal_Month_Min / First_Fiscal_Month_Max / First_Fiscal_Month_Min_LY / First_Fiscal_Month_Max_LY | 维度复用/Slicer_Time_Frame_Min |
| Slicer_Time_Frame_Max         | 断开维度 | SELECTEDVALUE 读取 TimeFrame_Max / TimeFrame_Max_LY       | 维度复用/Slicer_Time_Frame_Max             |
| Slicer_Platform_Selection     | 1:N 关系 | Platform_ID → 事实表[platform]                           | 维度复用/Slicer_Platform_Selection         |
| Slicer_Store_Name             | 1:N 关系 | Store_ID → 事实表[store_name]                            | 维度复用/Slicer_Store_Name                 |
| Slicer_Currency_Selection     | 断开维度 | SELECTEDVALUE 读取 Currency_ExchangeRate, Currency_Symbol | 维度复用/Slicer_Currency_Selection         |
| trans_cycle 筛选器            | 1:N 关系 | → 事实表[trans_cycle]（模型自动筛选）                    | 用户需求                                   |
| Dim_ColMetric_KPI by Platform | 断开维度 | SELECTEDVALUE 读取 Metric_ID, Metric_Format, IsCurrencyAmount | KPI Progress/Dim_ColMetric_KPI by Platform |

### 2.3 指标维度表（Dim_ColMetric_KPI by Platform）15 个指标

| Metric_ID | Metric_Name                                           | Metric_Sort | Metric_Format        | IsCurrencyAmount |
| --------- | ----------------------------------------------------- | ----------- | -------------------- | ---------------- |
| 1         | Media Cost Rate                                       | 10          | percent_1dp          | FALSE            |
| 2         | Media Cost Rate vs LP                                 | 20          | percent_1dp          | FALSE            |
| 3         | YOY%                                                  | 30          | percent_1dp          | FALSE            |
| 4         | Media Cost                                            | 40          | currency             | TRUE             |
| 5         | Media Cost vs LP                                     | 50          | currency             | TRUE             |
| 6         | YOY %                                                 | 60          | percent_1dp          | FALSE            |
| 7         | ± Acceleration cost MOB% vs. store SLS MOB%          | 70         | percent_1dp          | FALSE            |         
| 8        | ± Acceleration cost MOB% vs. store SLS MOB% vs LP    | 80         | percent_1dp          | FALSE            |  
| 9        | YOY  %                                                | 90         | percent_1dp          | FALSE            |
| 10        | Media Contribution to New Customer Acquisition%       | 100         | percent_1dp          | FALSE            |
| 11        | Media Contribution to New Customer Acquisition% vs LP | 110         | percent_1dp          | FALSE            |
| 12        | YOY   %                                               | 120         | percent_1dp          | FALSE            |
| 13        | Cost Per New Acquisition                              | 130         | currency_decimal_1dp | TRUE             |
| 14        | Cost Per New Acquisition vs LP                        | 140         | currency_decimal_1dp | TRUE             |
| 15        | YOY    %                                              | 150         | percent_1dp          | FALSE            |

---

## 3. 方案设计

### 3.1 整体架构

```
核心思路：双维度断开 + SWITCH 动态路由（Disconnected Dimensions + Dispatch Pattern）

Dim_ColMetric_KPI by Platform（断开维度，列头）    Slicer_Store_Name（已有维度，行头，1:N→事实表）
    │                                                      │
    │  无关系连接，仅通过 SELECTEDVALUE 读取                  │  已有关系连接到事实表
    │                                                      │
    ▼                                                      ▼
    ┌─────────────────── Matrix 视觉对象 ──────────────────┐
    │  行 = Slicer_Store_Name[Store_ID]                     │
    │  列 = 'Dim_ColMetric_KPI by Platform'[Metric_Name]    │
    │  值 = [KPI by Platform Cell Display]                  │
    └───────────────────────────────────────────────────────┘
           ▲
           │
    SWITCH 动态路由度量值链
    ┌────────────────────────────────────────────────────┐
    │  [KPI by Platform Cell Value]                        │
    │    └→ [KPI by Platform Base Value]（总路由）          │
    │         ├→ [KPI by Platform Current Base Value]     │
    │         ├→ [KPI by Platform vsLP Base Value]       │
    │         └→ YOY% = (Current - vsLP) / vsLP          │
    │  汇率换算在 Cell Value 层（÷汇率，按 IsCurrencyAmount）│
    └────────────────────────────────────────────────────┘
```

### 3.2 度量值模型设计（拆分 Current / vsLP）

```
[KPI by Platform Current Base Value]  ← 本期基础值（Metric_ID 1/4/7/10/13，不换算汇率）
[KPI by Platform vsLP Base Value]     ← 同期基础值（Metric_ID 2/5/8/11/14，不换算汇率）
[KPI by Platform Base Value]          ← 总路由（含 YOY% 计算，Metric_ID 3/6/9/12/15，Day/Week 留空）
[KPI by Platform Cell Value]         ← 对外值 = Base Value ÷ 汇率（金额类）
[KPI by Platform Cell Display]       ← 格式化显示文本（全拓展类型）
[KPI by Platform Cell Font Color]    ← 字体颜色（总计行 vs 其他行）
[KPI by Platform Cell Background Color] ← 背景色（总计行 vs 其他行）
[KPI by Platform Cell SVG Icon]      ← SVG 图标（仅 YOY% 行）
```

### 3.3 筛选器上下文

| 筛选器                    | 作用方式                                   | DAX 处理                            |
| ------------------------- | ------------------------------------------ | ----------------------------------- |
| Slicer_Time_Frame         | 断开维度，SELECTEDVALUE 读取 TimeFrame_ID  | 判断时间粒度（Day/Week 时部分指标留空） |
| Slicer_Time_Frame_Min     | 断开维度，SELECTEDVALUE 读取 TimeFrame_Min / TimeFrame_Min_LY / First_Fiscal_Month_Min / First_Fiscal_Month_Max / First_Fiscal_Month_Min_LY / First_Fiscal_Month_Max_LY | `data_date >= __TimeMin`（本期）；`TimeFrame_Min_LY` 用于 vs LP；`First_Fiscal_Month_Min/Max` 用于新客 Step2 start_period（本期）；`First_Fiscal_Month_Min_LY/Max_LY` 用于新客 Step2 start_period（vs LP） |
| Slicer_Time_Frame_Max     | 断开维度，SELECTEDVALUE 读取 TimeFrame_Max / TimeFrame_Max_LY | `data_date <= __TimeMax`（本期）；`TimeFrame_Max_LY` 用于 vs LP |
| Slicer_Platform_Selection | 1:N 关系，模型自动筛选                     | 无需显式处理                        |
| Slicer_Store_Name         | 1:N 关系，模型自动筛选                     | 无需显式处理                        |
| trans_cycle               | 1:N 关系，模型自动筛选                     | 无需显式处理                        |
| Slicer_Currency_Selection | 断开维度，SELECTEDVALUE 读取汇率和符号     | **仅在 Cell Value 层换算**：金额类指标 `DIVIDE([Base Value], Currency_ExchangeRate)`（除法），非金额类不受汇率影响 |

### 3.4 vs LP 时间偏移规则（财历映射）

直接读取日期表内置 LY 字段：
- 全局 LY 起始日：`Slicer_Time_Frame_Min[TimeFrame_Min_LY]`
- 全局 LY 结束日：`Slicer_Time_Frame_Max[TimeFrame_Max_LY]`
- 新客 LY 第一财月起止日：`Slicer_Time_Frame_Min[First_Fiscal_Month_Min_LY]` / `Slicer_Time_Frame_Min[First_Fiscal_Month_Max_LY]`
- 无需 EDATE -12 计算

### 3.5 汇率换算规则

换算时机：在 Cell Value 层 `DIVIDE([Base Value], Currency_ExchangeRate)`（除法，非乘法）
- 金额类指标（`IsCurrencyAmount = TRUE`）：#32 Media Cost（Metric_ID=4/5）、#35 Cost Per New Acq（Metric_ID=13/14）需 ÷ 汇率
- 比率/增减百分比类指标（`IsCurrencyAmount = FALSE`）：不涉及汇率换算
- YOY% 为比率，不涉及汇率换算（分子分母本币值抵消）

### 3.6 全店新客判定规则（合并区间）

新客 Step1+Step2 合并区间等价实现：
- Step1：在所选时间范围内筛选 `net_pay_amt > 0` 的 `user_id`（`data_date ∈ [__TimeMin, __TimeMax]`，`is_member = 0`）
- Step2：缩小顾客范围至 `lp_12m_net_pay_amt = 0`（`data_date ∈ start_period`）
- start_period = 第一财月，是 slicer 区间的子集，合并区间后单一 CALCULATE 即可
- **合并区间等价实现**：`data_date ∈ [First_Fiscal_Month_Min, First_Fiscal_Month_Max] AND net_pay_amt > 0 AND is_member = 0 AND lp_12m_net_pay_amt = 0`
- 第一财月映射：月=自身 / 季=Q1→01,Q2→04,Q3→07,Q4→10 / 年=01

### 3.7 媒体新客字段聚合规则（MAX+SUM）

`media_member_cnt` / `media_cost_amt` 先按 `platform`、`shop_id`、`data_month_name`（包含 `data_year` + `data_month` 属性）取 `MAX`，再对所选财月 `SUM`：
- 仅支持完整财月、财季、财年，`Day`/`Week` 时不考虑，为空
- DAX 实现：`SUMX(SUMMARIZE(..., "__Value", MAX([字段])), [__Value])`
- 列引用写法：`[__Value]`，不是字符串 `"__Value"`
- Day/Week 时整个指标无意义，在总路由层 `IF(__IsDayOrWeek, BLANK(), ...)` 统一留空，不细分到分子分母

---

## 4. 度量值实现

### 4.1 KPI by Platform Current Base Value（本期基础值）

```dax
KPI by Platform Current Base Value = 
// ========================================
// 度量值: KPI by Platform Current Base Value
// Display Folder: Base Metrics
// 用途: 根据 Metric_ID 路由到本期（Current）基础值
// 依赖: 'Dim_ColMetric_KPI by Platform'[Metric_ID]
// 口径来源: KPI Progress.md 子模块五（#31~#35 的本期值）
// 筛选: customer_type='ALL', page_type="1"
// 汇率: 不在此层换算，统一在 Cell Value 层处理
// Day/Week: 不在此层判断，统一在总路由层处理
// ========================================
    VAR __MetricID = SELECTEDVALUE('Dim_ColMetric_KPI by Platform'[Metric_ID])

    // ── 时间筛选：本期 ──
    VAR __TimeMin = SELECTEDVALUE(Slicer_Time_Frame_Min[TimeFrame_Min])
    VAR __TimeMax = SELECTEDVALUE(Slicer_Time_Frame_Max[TimeFrame_Max])
    // ── 第一财月区间（新客 Step2 的 start_period）──
    VAR __FirstFiscalMonthMin = SELECTEDVALUE(Slicer_Time_Frame_Min[First_Fiscal_Month_Min])
    VAR __FirstFiscalMonthMax = SELECTEDVALUE(Slicer_Time_Frame_Min[First_Fiscal_Month_Max])

    // ═══════════════════════════════════════
    // 基础聚合：a05_e2e_paid_media_summary_d（ALL 口径）
    // ═══════════════════════════════════════
    // Media Cost = SUM(cost_amt)，customer_type='ALL', page_type="1"
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
    // 第二品类：a05_e2e_paid_media_product_data_d
    // Cost 类分子：mix_msg is NULL AND framework='Acceleration'
    // Cost 类分母：mix_msg is NULL（不限制 framework）
    // SLS 类分子：framework='Acceleration'（不限制 mix_msg）
    // SLS 类分母：全部 framework（不限制 mix_msg）
    // ═══════════════════════════════════════
    // Acceleration Cost 分子（mix_msg is NULL AND framework='Acceleration'）
    VAR __AccelCost_Num = 
        CALCULATE(
            SUM('a05_e2e_paid_media_product_data_d'[cost_amt]),
            'a05_e2e_paid_media_product_data_d'[framework] = "Acceleration",
            ISBLANK('a05_e2e_paid_media_product_data_d'[mix_msg]),
            'a05_e2e_paid_media_product_data_d'[data_date] >= __TimeMin,
            'a05_e2e_paid_media_product_data_d'[data_date] <= __TimeMax
        )
    // Acceleration Cost 分母（mix_msg is NULL，不限制 framework）
    VAR __AccelCost_Den = 
        CALCULATE(
            SUM('a05_e2e_paid_media_product_data_d'[cost_amt]),
            ISBLANK('a05_e2e_paid_media_product_data_d'[mix_msg]),
            'a05_e2e_paid_media_product_data_d'[data_date] >= __TimeMin,
            'a05_e2e_paid_media_product_data_d'[data_date] <= __TimeMax
        )
    // Acceleration SLS 分子（framework='Acceleration'）
    VAR __AccelSLS_Num = 
        CALCULATE(
            SUM('a05_e2e_paid_media_product_data_d'[net_sales_amt]),
            'a05_e2e_paid_media_product_data_d'[framework] = "Acceleration",
            'a05_e2e_paid_media_product_data_d'[data_date] >= __TimeMin,
            'a05_e2e_paid_media_product_data_d'[data_date] <= __TimeMax
        )
    // Acceleration SLS 分母（全部 framework）
    VAR __AccelSLS_Den = 
        CALCULATE(
            SUM('a05_e2e_paid_media_product_data_d'[net_sales_amt]),
            'a05_e2e_paid_media_product_data_d'[data_date] >= __TimeMin,
            'a05_e2e_paid_media_product_data_d'[data_date] <= __TimeMax
        )

    // ═══════════════════════════════════════
    // 媒体新客字段聚合：先 MAX 再 SUM（SUMX+SUMMARIZE）
    // customer_type='ALL', page_type="1"
    // ═══════════════════════════════════════
    // 媒体新客数 = SUM(MAX(media_member_cnt))，按 platform/shop_id/data_month_name 分组
    VAR __MediaNewCustCnt = 
        CALCULATE(
            SUMX(
                SUMMARIZE(
                    'a05_e2e_paid_media_summary_d',
                    'a05_e2e_paid_media_summary_d'[platform],
                    'a05_e2e_paid_media_summary_d'[shop_id],
                    'a05_e2e_paid_media_summary_d'[data_month_name],
                    "__Value", MAX('a05_e2e_paid_media_summary_d'[media_member_cnt])
                ),
                [__Value]    // 列引用写法：[__Value]，不是 "__Value"
            ),
            'a05_e2e_paid_media_summary_d'[customer_type] = "ALL",
            'a05_e2e_paid_media_summary_d'[page_type] = "1",
            'a05_e2e_paid_media_summary_d'[data_date] >= __TimeMin,
            'a05_e2e_paid_media_summary_d'[data_date] <= __TimeMax
        )
    // 媒体新客花费 = SUM(MAX(media_cost_amt))，按 platform/shop_id/data_month_name 分组
    VAR __MediaNewCostAmt = 
        CALCULATE(
            SUMX(
                SUMMARIZE(
                    'a05_e2e_paid_media_summary_d',
                    'a05_e2e_paid_media_summary_d'[platform],
                    'a05_e2e_paid_media_summary_d'[shop_id],
                    'a05_e2e_paid_media_summary_d'[data_month_name],
                    "__Value", MAX('a05_e2e_paid_media_summary_d'[media_cost_amt])
                ),
                [__Value]    // 列引用写法：[__Value]，不是 "__Value"
            ),
            'a05_e2e_paid_media_summary_d'[customer_type] = "ALL",
            'a05_e2e_paid_media_summary_d'[page_type] = "1",
            'a05_e2e_paid_media_summary_d'[data_date] >= __TimeMin,
            'a05_e2e_paid_media_summary_d'[data_date] <= __TimeMax
        )

    // ═══════════════════════════════════════
    // 全店新客数：a03_e2e_customer_data_m
    // 合并区间筛选：data_date ∈ [__FirstFiscalMonthMin, __FirstFiscalMonthMax]
    //   （start_period = 第一财月，是 slicer 区间的子集，合并区间后单一 CALCULATE 即可）
    //   AND net_pay_amt > 0 AND is_member = 0 AND lp_12m_net_pay_amt = 0
    // DISTINCTCOUNT(user_id)
    // ═══════════════════════════════════════
    VAR __TotalNewCustCnt = 
        CALCULATE(
            DISTINCTCOUNT('a03_e2e_customer_data_m'[user_id]),
            'a03_e2e_customer_data_m'[data_date] >= __FirstFiscalMonthMin,
            'a03_e2e_customer_data_m'[data_date] <= __FirstFiscalMonthMax,
            'a03_e2e_customer_data_m'[net_pay_amt] > 0,
            'a03_e2e_customer_data_m'[is_member] = 0,
            'a03_e2e_customer_data_m'[lp_12m_net_pay_amt] = 0
        )

    // ═══════════════════════════════════════
    // 派生指标
    // ═══════════════════════════════════════
    // Media Cost Rate = Cost / SLS × 1.13 / 1.06（口径文档要求）
    VAR __MediaCostRate = DIVIDE(__Cost_ALL * 1.13, __SLS_ALL * 1.06)
    // Acceleration Cost MOB% = Accel Cost / Total Cost
    VAR __AccelCostMOB = DIVIDE(__AccelCost_Num, __AccelCost_Den)
    // Store SLS MOB% = Accel SLS / Total SLS
    VAR __StoreSLSMOB = DIVIDE(__AccelSLS_Num, __AccelSLS_Den)
    // ± Acceleration Cost MOB% vs. Store SLS MOB% = Accel Cost MOB% - Store SLS MOB%
    VAR __AccelCostMOBvsSLS = __AccelCostMOB - __StoreSLSMOB
    // Media Contribution to New Customer Acquisition% = Media New Cust / Total New Cust
    VAR __MediaNewCustContrib = DIVIDE(__MediaNewCustCnt, __TotalNewCustCnt)
    // Cost Per New Acquisition = Media New Cost / Media New Cust
    VAR __CostPerNewAcq = DIVIDE(__MediaNewCostAmt, __MediaNewCustCnt)

    RETURN
        SWITCH(
            __MetricID,
            1,  __MediaCostRate,        // Media Cost Rate（比率，不涉及汇率）
            4,  __Cost_ALL,             // Media Cost（金额，汇率在 Cell Value 层处理）
            7,  __AccelCostMOBvsSLS,   // ± Accel cost MOB% vs. store SLS MOB%（比率）
            10, __MediaNewCustContrib,  // Media Contribution to New Cust%（比率）
            13, __CostPerNewAcq,        // Cost Per New Acq（金额，汇率在 Cell Value 层处理）
            BLANK()
        )
```

### 4.2 KPI by Platform vsLP Base Value（同期基础值）

```dax
KPI by Platform vsLP Base Value = 
// ========================================
// 度量值: KPI by Platform vsLP Base Value
// Display Folder: Base Metrics
// 用途: 根据 Metric_ID 路由到同期（vs LP）基础值
// 依赖: 'Dim_ColMetric_KPI by Platform'[Metric_ID]
// 口径来源: KPI Progress.md 子模块五（#31~#35 的 vs LP 值）
// vs LP 时间偏移：直接读取日期表内置 LY 字段（财历映射），无需 EDATE -12
// 汇率: 不在此层换算，统一在 Cell Value 层处理
// Day/Week: 不在此层判断，统一在总路由层处理
// ========================================
    VAR __MetricID = SELECTEDVALUE('Dim_ColMetric_KPI by Platform'[Metric_ID])

    // ── 时间筛选：去年同期（直接读取日期表内置 LY 字段）──
    VAR __LPTimeMin = SELECTEDVALUE(Slicer_Time_Frame_Min[TimeFrame_Min_LY])
    VAR __LPTimeMax = SELECTEDVALUE(Slicer_Time_Frame_Max[TimeFrame_Max_LY])
    // ── 第一财月区间（去年同期，新客 Step2 的 start_period）──
    VAR __LPFirstFiscalMonthMin = SELECTEDVALUE(Slicer_Time_Frame_Min[First_Fiscal_Month_Min_LY])
    VAR __LPFirstFiscalMonthMax = SELECTEDVALUE(Slicer_Time_Frame_Min[First_Fiscal_Month_Max_LY])

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
    // 第二品类：a05_e2e_paid_media_product_data_d（去年同期）
    // ═══════════════════════════════════════
    VAR __AccelCost_Num = 
        CALCULATE(
            SUM('a05_e2e_paid_media_product_data_d'[cost_amt]),
            'a05_e2e_paid_media_product_data_d'[framework] = "Acceleration",
            ISBLANK('a05_e2e_paid_media_product_data_d'[mix_msg]),
            'a05_e2e_paid_media_product_data_d'[data_date] >= __LPTimeMin,
            'a05_e2e_paid_media_product_data_d'[data_date] <= __LPTimeMax
        )
    VAR __AccelCost_Den = 
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
    VAR __AccelSLS_Den = 
        CALCULATE(
            SUM('a05_e2e_paid_media_product_data_d'[net_sales_amt]),
            'a05_e2e_paid_media_product_data_d'[data_date] >= __LPTimeMin,
            'a05_e2e_paid_media_product_data_d'[data_date] <= __LPTimeMax
        )

    // ═══════════════════════════════════════
    // 媒体新客字段聚合：先 MAX 再 SUM（去年同期）
    // ═══════════════════════════════════════
    VAR __MediaNewCustCnt = 
        CALCULATE(
            SUMX(
                SUMMARIZE(
                    'a05_e2e_paid_media_summary_d',
                    'a05_e2e_paid_media_summary_d'[platform],
                    'a05_e2e_paid_media_summary_d'[shop_id],
                    'a05_e2e_paid_media_summary_d'[data_month_name],
                    "__Value", MAX('a05_e2e_paid_media_summary_d'[media_member_cnt])
                ),
                [__Value]    // 列引用写法：[__Value]，不是 "__Value"
            ),
            'a05_e2e_paid_media_summary_d'[customer_type] = "ALL",
            'a05_e2e_paid_media_summary_d'[page_type] = "1",
            'a05_e2e_paid_media_summary_d'[data_date] >= __LPTimeMin,
            'a05_e2e_paid_media_summary_d'[data_date] <= __LPTimeMax
        )
    VAR __MediaNewCostAmt = 
        CALCULATE(
            SUMX(
                SUMMARIZE(
                    'a05_e2e_paid_media_summary_d',
                    'a05_e2e_paid_media_summary_d'[platform],
                    'a05_e2e_paid_media_summary_d'[shop_id],
                    'a05_e2e_paid_media_summary_d'[data_month_name],
                    "__Value", MAX('a05_e2e_paid_media_summary_d'[media_cost_amt])
                ),
                [__Value]    // 列引用写法：[__Value]，不是 "__Value"
            ),
            'a05_e2e_paid_media_summary_d'[customer_type] = "ALL",
            'a05_e2e_paid_media_summary_d'[page_type] = "1",
            'a05_e2e_paid_media_summary_d'[data_date] >= __LPTimeMin,
            'a05_e2e_paid_media_summary_d'[data_date] <= __LPTimeMax
        )

    // ═══════════════════════════════════════
    // 全店新客数：a03_e2e_customer_data_m（去年同期）
    // 合并区间筛选：data_date ∈ [__LPFirstFiscalMonthMin, __LPFirstFiscalMonthMax]
    //   （start_period = 去年同期第一财月）
    //   AND net_pay_amt > 0 AND is_member = 0 AND lp_12m_net_pay_amt = 0
    // ═══════════════════════════════════════
    VAR __TotalNewCustCnt = 
        CALCULATE(
            DISTINCTCOUNT('a03_e2e_customer_data_m'[user_id]),
            'a03_e2e_customer_data_m'[data_date] >= __LPFirstFiscalMonthMin,
            'a03_e2e_customer_data_m'[data_date] <= __LPFirstFiscalMonthMax,
            'a03_e2e_customer_data_m'[net_pay_amt] > 0,
            'a03_e2e_customer_data_m'[is_member] = 0,
            'a03_e2e_customer_data_m'[lp_12m_net_pay_amt] = 0
        )

    // ═══════════════════════════════════════
    // 派生指标
    // ═══════════════════════════════════════
    VAR __MediaCostRate = DIVIDE(__Cost_ALL * 1.13, __SLS_ALL * 1.06)
    VAR __AccelCostMOB = DIVIDE(__AccelCost_Num, __AccelCost_Den)
    VAR __StoreSLSMOB = DIVIDE(__AccelSLS_Num, __AccelSLS_Den)
    VAR __AccelCostMOBvsSLS = __AccelCostMOB - __StoreSLSMOB
    VAR __MediaNewCustContrib = DIVIDE(__MediaNewCustCnt, __TotalNewCustCnt)
    VAR __CostPerNewAcq = DIVIDE(__MediaNewCostAmt, __MediaNewCustCnt)

    RETURN
        SWITCH(
            __MetricID,
            2,  __MediaCostRate,        // Media Cost Rate vs LP（比率）
            5,  __Cost_ALL,             // Media Cost vs LP（金额，汇率在 Cell Value 层处理）
            8,  __AccelCostMOBvsSLS,   // ± Accel cost MOB% vs. store SLS MOB% vs LP（比率）
            11, __MediaNewCustContrib,  // Media Contribution to New Cust% vs LP（比率）
            14, __CostPerNewAcq,        // Cost Per New Acq vs LP（金额，汇率在 Cell Value 层处理）
            BLANK()
        )
```

### 4.3 KPI by Platform Base Value（总路由）

```dax
KPI by Platform Base Value = 
// ========================================
// 度量值: KPI by Platform Base Value
// Display Folder: Base Metrics
// 用途: 总路由，根据 Metric_ID 分发到 Current / vsLP / YOY%
// 依赖: [KPI by Platform Current Base Value], [KPI by Platform vsLP Base Value]
// 说明: 
//   Metric_ID 1/4/7/10/13 → Current
//   Metric_ID 2/5/8/11/14 → vsLP
//   Metric_ID 3/6/9/12/15 → YOY% (常规同比百分比，含边界判断)
// Day/Week: 涉及 MAX+SUM 聚合的指标（#34/#35 系列 = Metric_ID 10~15）在 Day/Week 时为空
//   在三个结果变量（__CurrentValue/__LP_Value/__YOY_Result）各自内部判断，不细分到分子分母
// ========================================
    VAR __MetricID = SELECTEDVALUE('Dim_ColMetric_KPI by Platform'[Metric_ID])
    VAR __TimeFrameID = SELECTEDVALUE(Slicer_Time_Frame[TimeFrame_ID])
    VAR __IsDayOrWeek = __TimeFrameID IN {"Day", "Week"}

    // 涉及 MAX+SUM 聚合的指标（Day/Week 时无意义）
    // #34 Media Contribution%（10/11/12）、#35 Cost Per New Acq（13/14/15）
    VAR __NeedsFullFiscalPeriod = __MetricID IN {10, 11, 12, 13, 14, 15}
    // Day/Week + 涉及 MAX+SUM 聚合 → 该指标无意义，返回 BLANK
    VAR __NeedsBlank = __IsDayOrWeek && __NeedsFullFiscalPeriod

    VAR __IsYOY = __MetricID IN {3, 6, 9, 12, 15}

    // ── 本期值（含 YOY% 上下文修复 + Day/Week 留空判断）──
    // 修复上下文冲突：矩阵行标题会保留 Metric_Name 等所有列的筛选器，
    // 仅覆盖 Metric_ID 会导致筛选条件冲突，因此需先 REMOVEFILTERS 再应用目标 Metric_ID
    VAR __CurrentValue = 
        IF(
            __NeedsBlank,
            BLANK(),
            IF(
                __IsYOY,
                CALCULATE(
                    [KPI by Platform Current Base Value], 
                    REMOVEFILTERS('Dim_ColMetric_KPI by Platform'), 
                    'Dim_ColMetric_KPI by Platform'[Metric_ID] = __MetricID - 2
                ),
                [KPI by Platform Current Base Value]
            )
        )

    // ── 同期值（含 YOY% 上下文修复 + Day/Week 留空判断）──
    VAR __LP_Value = 
        IF(
            __NeedsBlank,
            BLANK(),
            IF(
                __IsYOY,
                CALCULATE(
                    [KPI by Platform vsLP Base Value], 
                    REMOVEFILTERS('Dim_ColMetric_KPI by Platform'), 
                    'Dim_ColMetric_KPI by Platform'[Metric_ID] = __MetricID - 1
                ),
                [KPI by Platform vsLP Base Value]
            )
        )

    VAR __CurrIsEmpty = ISBLANK(__CurrentValue) || __CurrentValue = 0
    VAR __LPIsEmpty = ISBLANK(__LP_Value) || __LP_Value = 0

    // ── YOY 同比计算（含 Day/Week 留空 + 边界判断）──
    //   Day/Week 无意义时 → BLANK
    //   同期为 0 或空 → 本期为 0 或空返回 BLANK()，本期有值返回 -1 (即 -100%)
    //   本期为 0 或空，同期有值 → -1 (即 -100%)
    //   双方均有值 → (This Year - Last Year) / Last Year
    VAR __YOY_Result =
        IF(
            __NeedsBlank,
            BLANK(),
            IF(
                __LPIsEmpty,
                BLANK(),
                IF(__CurrIsEmpty, -1, DIVIDE(__CurrentValue - __LP_Value, __LP_Value))
            )
        )

    RETURN
        SWITCH(
            __MetricID,
            // ─── 本期值 ───
            1,  __CurrentValue,    // Media Cost Rate
            4,  __CurrentValue,    // Media Cost
            7,  __CurrentValue,    // ± Accel cost MOB% vs. store SLS MOB%
            10, __CurrentValue,    // Media Contribution to New Cust%
            13, __CurrentValue,    // Cost Per New Acquisition
            // ─── vs LP 值 ───
            2,  __LP_Value,       // Media Cost Rate vs LP
            5,  __LP_Value,       // Media Cost vs LP
            8,  __LP_Value,       // ± Accel cost MOB% vs. store SLS MOB% vs LP
            11, __LP_Value,       // Media Contribution to New Cust% vs LP
            14, __LP_Value,       // Cost Per New Acquisition vs LP
            // ─── YOY% 计算 ───
            3,  __YOY_Result,     // YOY% (Media Cost Rate)
            6,  __YOY_Result,     // YOY % (Media Cost)
            9,  __YOY_Result,     // YOY  % (± Accel cost MOB%)
            12, __YOY_Result,     // YOY   % (Media New Cust Contribution%)
            15, __YOY_Result,     // YOY    % (Cost Per New Acq)
            BLANK()
        )
```

### 4.4 KPI by Platform Cell Value（对外值）

```dax
KPI by Platform Cell Value = 
// ========================================
// 度量值: KPI by Platform Cell Value
// Display Folder: Cell Values
// 用途: 对外暴露的单元格值，含汇率换算
// 依赖: [KPI by Platform Base Value], 'Dim_ColMetric_KPI by Platform'[IsCurrencyAmount]
// 汇率换算: 金额类指标 DIVIDE([Base Value], Currency_ExchangeRate)（除法，非乘法）
//   比率/增减百分比类指标不换算
// ========================================
    VAR __BaseValue = [KPI by Platform Base Value]
    VAR __IsCurrencyAmount = SELECTEDVALUE('Dim_ColMetric_KPI by Platform'[IsCurrencyAmount], FALSE)
    VAR __FXRate = SELECTEDVALUE(Slicer_Currency_Selection[Currency_ExchangeRate], 1)
    RETURN
        IF(
            __IsCurrencyAmount,
            DIVIDE(__BaseValue, __FXRate),    // 金额类 ÷ 汇率
            __BaseValue                        // 比率类不换算
        )
```

### 4.5 KPI by Platform Cell Display（格式化显示）

```dax
KPI by Platform Cell Display = 
// ========================================
// 度量值: KPI by Platform Cell Display
// Display Folder: Formatting
// 用途: 按 Metric_Format 单字段格式化显示（全拓展类型）
// 依赖: [KPI by Platform Cell Value],
//       'Dim_ColMetric_KPI by Platform'[Metric_Format],
//       Slicer_Currency_Selection[Currency_Symbol]
// 格式类型（严格遵循口径文档数据类型定义，以 Dim_ColMetric 为准）:
//   integer               → 整数千分位：1,000
//   decimal_1dp           → 小数一位小数千分位：1.5
//   decimal_2dp           → 小数两位小数千分位：1,000.00
//   currency              → 货币符号 + 整数千分位：¥1,000 / $1,000
//   currency_decimal_1dp  → 货币符号 + 一位小数千分位：¥1,000.0 / $1,000.0
//   currency_k            → 货币符号 + 千位缩写：¥1k / $5k
//   currency_M_K_Int_0db  → 货币符号 + 整数/M/K 单位（0位小数）：¥999\¥1.5K\¥1.5M
//   percent_0dp           → 百分比整数，不含正号：15%
//   percent_1dp           → 百分比一位小数：40.5%
//   percent_2dp           → 百分比两位小数：40.50%
//   delta_pct_0dp         → 百分比整数变化，含正号：+15% / -3%
//   delta_pct_1dp         → 百分比一位小数变化，含正号：+14.5% / -3.2%
//   delta_pct_2dp         → 百分比两位小数变化，含正号：+14.50%
//   delta_pts             → 增减基点整数（小数×100 转 pts）：+120pts / -80pts / 0pts
//   integer_pts           → 基点整数（小数×100 转 pts）：120pts / 80pts / 0pts
//   delta_bp              → 增减基点整数（小数×10000 转 bp）：+120bp / -80bp
//   delta_bp_1dp          → 增减基点一位小数（值本身已是基点）：+120.5bp / -80.0bp
// 说明:
//   - BLANK 显示为 "-"
//   - 货币符号由 Slicer_Currency_Selection[Currency_Symbol] 决定（默认 "¥"）
// ========================================
    VAR __Value = [KPI by Platform Cell Value]
    VAR __Format = SELECTEDVALUE('Dim_ColMetric_KPI by Platform'[Metric_Format])
    VAR __CurrencySymbol = SELECTEDVALUE(Slicer_Currency_Selection[Currency_Symbol], "¥")

    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            SWITCH(
                __Format,

    // ─── 1. 整数与小数 ──────────────────────────────────────────
                "integer",
                    FORMAT(__Value, "#,##0"),                                    // 1,000

                "decimal_1dp",
                    FORMAT(__Value, "#,##0.0"),                                  // 1.5

                "decimal_2dp",
                    FORMAT(__Value, "#,##0.00"),                                 // 1,000.00

    // ─── 2. 货币格式 ────────────────────────────────────────────
                "currency",
                    __CurrencySymbol & FORMAT(__Value, "#,##0"),                 // ¥1,000 / $1,000

                "currency_decimal_1dp",
                    __CurrencySymbol & FORMAT(__Value, "#,##0.0"),               // ¥1,000.0 / $1,000.0

                "currency_k",
                    __CurrencySymbol & FORMAT(__Value / 1000, "#,##0") & "k",    // ¥1k / $5k

                "currency_M_K_Int_0db",
                    IF(
                        __Value < 1000,
                        __CurrencySymbol & FORMAT(__Value, "#,##0"),
                        IF(
                            __Value < 1000000,
                            __CurrencySymbol & FORMAT(__Value / 1000, "#,##0.0") & "K",
                            __CurrencySymbol & FORMAT(__Value / 1000000, "#,##0.0") & "M"
                        )
                    ), // ¥999\¥1.5K\¥1.5M

    // ─── 3. 百分比格式（纯显示，不含正负号）───────────────────────
                "percent_0dp",
                    FORMAT(__Value, "#,##0%"),                                   // 15%

                "percent_1dp",
                    FORMAT(__Value, "0.0%"),                                     // 40.5%

                "percent_2dp",
                    FORMAT(__Value, "0.00%"),                                    // 40.50%

    // ─── 4. 增减百分比（Delta %，自动添加正负号）────────────────
                "delta_pct_0dp",
                    IF(__Value > 0, "+", "") & FORMAT(__Value, "#,##0%"),        // +15% / -3%

                "delta_pct_1dp",
                    IF(__Value > 0, "+", "") & FORMAT(__Value, "0.0%"),          // +14.5% / -3.2%

                "delta_pct_2dp",
                    IF(__Value > 0, "+", "") & FORMAT(__Value, "0.00%"),         // +14.50%

    // ─── 5. 增减基点 ───────────────────────────────────────────
    // 5.1 __Value 为小数，需 ×100 转换为 pts（整数），含正号
                "delta_pts",
                    IF(__Value > 0, "+", "") & FORMAT(__Value * 100, "#,##0pts;-#,##0pts;0pts"),
                                                                                 // +120pts / -80pts / 0pts

    // 5.2 __Value 为小数，需 ×100 转换为 pts（整数），不含正号
                "integer_pts",
                    FORMAT(__Value * 100, "#,##0pts;-#,##0pts;0pts"),            // 120pts / -80pts / 0pts

    // 5.3 __Value 为小数，需 ×10000 转换为 bp（整数）
                "delta_bp",
                    IF(__Value > 0, "+", "") & FORMAT(__Value * 10000, "#,##0") & "bp",
                                                                                 // +120bp / -80bp

    // 5.4 __Value 本身已是基点值，保留 1 位小数
                "delta_bp_1dp",
                    IF(__Value > 0, "+", "") & FORMAT(__Value, "#,##0.0") & "bp",// +120.5bp / -80.0bp

    // ─── 默认 ───────────────────────────────────────────────────
                FORMAT(__Value, "#,##0.00")
            )
        )
```

### 4.6 KPI by Platform Cell Font Color（字体颜色）

```dax
KPI by Platform Cell Font Color = 
// ========================================
// 度量值: KPI by Platform Cell Font Color
// Display Folder: Formatting
// 用途: 区别总计行和其他行的字体颜色
// 依赖: ISINSCOPE(Slicer_Store_Name[Store_ID])
// 说明: 总计行（非 ISINSCOPE）→ #252423（黑色）
//       其他行（ISINSCOPE）→ #5F6165（深灰）
// ========================================
    IF(
        ISINSCOPE(Slicer_Store_Name[Store_ID]),
        "#5F6165",    // 非总计行：深灰
        "#252423"     // 总计行：黑色
    )
```

### 4.7 KPI by Platform Cell Background Color（背景色）

```dax
KPI by Platform Cell Background Color = 
// ========================================
// 度量值: KPI by Platform Cell Background Color
// Display Folder: Formatting
// 用途: 区别总计行和其他行的背景颜色
// 依赖: ISINSCOPE(Slicer_Store_Name[Store_ID])
// 说明: 总计行（非 ISINSCOPE）→ #E6D9C7（中米色）
//       其他行（ISINSCOPE）→ #FFFFFF（白色）
// ========================================
    IF(
        ISINSCOPE(Slicer_Store_Name[Store_ID]),
        "#FFFFFF",    // 非总计行：白色
        "#E6D9C7"     // 总计行：中米色
    )
```

### 4.8 KPI by Platform Cell SVG Icon（SVG 图标）

```dax
KPI by Platform Cell SVG Icon = 
// ========================================
// 度量值: KPI by Platform Cell SVG Icon
// Display Folder: Formatting
// 用途: 仅 YOY% 指标返回 SVG 圆形图标
// 依赖: [KPI by Platform Cell Value], 'Dim_ColMetric_KPI by Platform'[Metric_ID]
// 说明: 需将此度量值的数据类别设为"图像 URL"
//       YOY% 的 Metric_ID ∈ {3, 6, 9, 12, 15}
//       正值 → 绿色圆，负值 → 红色圆，零值 → 黄色圆
// ========================================
    VAR __Value = [KPI by Platform Cell Value]
    VAR __MetricID = SELECTEDVALUE('Dim_ColMetric_KPI by Platform'[Metric_ID])
    VAR __NeedsIcon = __MetricID IN {3, 6, 9, 12, 15}
    VAR __GreenSVG =
        "data:image/svg+xml;utf8," &
        "<svg xmlns='http://www.w3.org/2000/svg' width='16' height='16'>" &
        "<circle cx='8' cy='8' r='7' fill='%234CAF50'/></svg>"
    VAR __RedSVG =
        "data:image/svg+xml;utf8," &
        "<svg xmlns='http://www.w3.org/2000/svg' width='16' height='16'>" &
        "<circle cx='8' cy='8' r='7' fill='%23F44336'/></svg>"
    VAR __YellowSVG =
        "data:image/svg+xml;utf8," &
        "<svg xmlns='http://www.w3.org/2000/svg' width='16' height='16'>" &
        "<circle cx='8' cy='8' r='7' fill='%23E1C233'/></svg>"
    RETURN
        SWITCH(
            TRUE(),
            __NeedsIcon && __Value > 0,  __GreenSVG,       // 正值 → 绿色圆
            __NeedsIcon && __Value < 0,  __RedSVG,          // 负值 → 红色圆
            __NeedsIcon && __Value = 0,  __YellowSVG,       // 零值 → 黄色圆
            BLANK()
        )
```

---

## 5. 度量值清单与 Display Folder

| 序号 | 度量值名称                            | Display Folder | 用途                                 |
| ---- | ------------------------------------- | -------------- | ------------------------------------ |
| 1    | KPI by Platform Current Base Value    | Base Metrics   | 本期基础值（Metric_ID 1/4/7/10/13，不换算汇率） |
| 2    | KPI by Platform vsLP Base Value       | Base Metrics   | 同期基础值（Metric_ID 2/5/8/11/14，不换算汇率） |
| 3    | KPI by Platform Base Value            | Base Metrics   | 总路由（含 YOY% 计算，Day/Week 留空） |
| 4    | KPI by Platform Cell Value            | Cell Values    | 对外值 = Base Value ÷ 汇率（金额类） |
| 5    | KPI by Platform Cell Display          | Formatting     | 格式化显示文本（全拓展类型）          |
| 6    | KPI by Platform Cell Font Color       | Formatting     | 字体颜色                             |
| 7    | KPI by Platform Cell Background Color | Formatting     | 背景色                               |
| 8    | KPI by Platform Cell SVG Icon         | Formatting     | SVG 图标（仅 YOY%）                  |

---

## 6. 指标口径来源对照

| Metric_ID | Metric_Name                                 | 口径文档出处 | 计算公式                                | 统计字段                                        | 数据底表                          | customer_type | 涉及汇率 |
| --------- | ------------------------------------------- | ------------ | --------------------------------------- | ----------------------------------------------- | ------------------------------------- | ------------- | -------- |
| 1         | Media Cost Rate                             | 子模块五 §31  | Cost / SLS × 1.13 / 1.06               | cost_amt / net_sales_amt                        | a05_e2e_paid_media_summary_d          | ALL           | 否       |
| 2         | Media Cost Rate vs LP                       | 子模块五 §31  | 同上，vs LY                             | 同上                                            | 同上                                  | ALL           | 否       |
| 3         | YOY%                                        | 子模块五 §31  | (Current - vsLP) / vsLP                 | -                                               | -                                     | -             | 否       |
| 4         | Media Cost                                  | 子模块五 §32  | SUM(cost_amt)                           | cost_amt                                        | a05_e2e_paid_media_summary_d          | ALL           | 是       |
| 5         | Media Cost vs LP                            | 子模块五 §32  | 同上，vs LY                             | 同上                                            | 同上                                  | ALL           | 是       |
| 6         | YOY %                                       | 子模块五 §32  | (Current - vsLP) / vsLP                 | -                                               | -                                     | -             | 否       |
| 7         | ± Accel Cost MOB% vs. Store SLS MOB%       | 子模块五 §33  | Accel Cost MOB% - Store SLS MOB%        | cost_amt / net_sales_amt                        | a05_e2e_paid_media_product_data_d     | ALL           | 否       |
| 8         | ± Accel Cost MOB% vs. Store SLS MOB% vs LP | 子模块五 §33  | 同上，vs LY                             | 同上                                            | 同上                                  | ALL           | 否       |
| 9         | YOY  %                                      | 子模块五 §33  | (Current - vsLP) / vsLP                 | -                                               | -                                     | -             | 否       |
| 10        | Media Contribution to New Cust%            | 子模块五 §34  | 媒体新客数 / 全店新客数                 | MAX+SUM(media_member_cnt) / DISTINCTCOUNT(user_id) | summary_d + customer_data_m           | ALL           | 否       |
| 11        | Media Contribution to New Cust% vs LP      | 子模块五 §34  | 同上，vs LY                             | 同上                                            | 同上                                  | ALL           | 否       |
| 12        | YOY   %                                     | 子模块五 §34  | (Current - vsLP) / vsLP                 | -                                               | -                                     | -             | 否       |
| 13        | Cost Per New Acquisition                    | 子模块五 §35  | 新客花费 / 媒体新客数                   | MAX+SUM(media_cost_amt) / MAX+SUM(media_member_cnt) | a05_e2e_paid_media_summary_d          | ALL           | 是       |
| 14        | Cost Per New Acquisition vs LP             | 子模块五 §35  | 同上，vs LY                             | 同上                                            | 同上                                  | ALL           | 是       |
| 15        | YOY    %                                    | 子模块五 §35  | (Current - vsLP) / vsLP                 | -                                               | -                                     | -             | 否       |

---

## 7. 血缘关系图（Lineage Diagram）

```
┌─────────────────────────────────────────────────────────────────────┐
│                        数据源层                                      │
│  a05_e2e_paid_media_summary_d（汇总指标事实表）                      │
│  字段: data_date, platform, shop_id, store_name, trans_cycle,        │
│        customer_type, page_type, cost_amt, net_sales_amt,            │
│        media_member_cnt, media_cost_amt                              │
│                                                                     │
│  a05_e2e_paid_media_product_data_d（第二品类事实表）                  │
│  字段: data_date, platform, framework, mix_msg,                     │
│        cost_amt, net_sales_amt                                        │
│                                                                     │
│  a03_e2e_customer_data_m（全店新客事实表）                            │
│  字段: data_date, platform, shop_info_id, user_id,                  │
│        net_pay_amt, is_member, lp_12m_net_pay_amt                   │
└──────────────────────────────┬──────────────────────────────────────┘
                               │
                               │ 1:N 关系（模型自动筛选）
                               │
              ┌────────────────┼────────────────┐
              │                │                │
              ▼                ▼                ▼
┌──────────────────┐ ┌──────────────────┐ ┌──────────────────┐
│ Slicer_Platform_  │ │ Slicer_Store_    │ │ trans_cycle      │
│ Selection         │ │ Name             │ │ 筛选器           │
│ (Platform_ID)     │ │ (Store_ID)       │ │ (trans_cycle)    │
└──────────────────┘ └──────────────────┘ └──────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│                        断开维度层                                    │
│  Slicer_Time_Frame（TimeFrame_ID 时间粒度）                          │
│  Slicer_Time_Frame_Min（TimeFrame_Min / TimeFrame_Min_LY /           │
│    First_Fiscal_Month_Min / First_Fiscal_Month_Max /                 │
│    First_Fiscal_Month_Min_LY / First_Fiscal_Month_Max_LY）           │
│  Slicer_Time_Frame_Max（TimeFrame_Max / TimeFrame_Max_LY）          │
│  Slicer_Currency_Selection（Currency_ExchangeRate / Currency_Symbol）│
│  Dim_ColMetric_KPI by Platform（Metric_ID / Metric_Format /          │
│    IsCurrencyAmount）                                                │
└──────────────────────────────┬──────────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────────┐
│                        度量值层                                      │
│                                                                     │
│  ┌─────────────────────────┐   ┌─────────────────────────┐          │
│  │ KPI by Platform         │   │ KPI by Platform         │          │
│  │ Current Base Value      │   │ vsLP Base Value         │          │
│  │ (Metric_ID 1/4/7/10/13) │   │ (Metric_ID 2/5/8/11/14) │         │
│  │ 不换算汇率              │   │ 不换算汇率              │          │
│  └───────────┬─────────────┘   └───────────┬─────────────┘          │
│              │                              │                        │
│              │    ┌─────────────────────────┘                        │
│              │    │                                                  │
│              ▼    ▼                                                  │
│  ┌─────────────────────────┐                                        │
│  │ KPI by Platform         │                                        │
│  │ Base Value              │                                        │
│  │ (总路由 + YOY%)         │                                        │
│  │ Day/Week 留空(#34/#35)  │                                        │
│  └───────────┬─────────────┘                                        │
│              │                                                      │
│              ▼                                                      │
│  ┌─────────────────────────┐   ┌─────────────────────────┐          │
│  │ KPI by Platform         │◄──│ Slicer_Currency_        │          │
│  │ Cell Value              │   │ Selection               │          │
│  │ (÷汇率，金额类)         │   │ (仅 Cell Value 层换算)    │          │
│  └───────────┬─────────────┘   └─────────────────────────┘          │
│              │                                                      │
│              ▼                                                      │
│  ┌─────────────────────────┐                                        │
│  │ KPI by Platform         │   ┌─────────────────────────┐          │
│  │ Cell Display            │◄──│ 'Dim_ColMetric_KPI by   │          │
│  │ (全拓展类型格式化)       │   │ Platform'              │          │
│  └───────────┬─────────────┘   │ (Metric_Format)         │         │
│              │                  └─────────────────────────┘          │
│              ▼                                                      │
│  ┌─────────────────────────────────────────────────┐                │
│  │  KPI by Platform Cell Font Color                 │                │
│  │  KPI by Platform Cell Background Color           │                │
│  │  KPI by Platform Cell SVG Icon                   │                │
│  │  (条件格式度量值)                                 │                │
│  └─────────────────────────────────────────────────┘                │
└─────────────────────────────────────────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────────┐
│                        可视化层                                      │
│  Matrix 视觉对象                                                     │
│  行: Slicer_Store_Name[Store_ID]                                    │
│  列: 'Dim_ColMetric_KPI by Platform'[Metric_Name]                   │
│  值: [KPI by Platform Cell Display]                                  │
│  条件格式:                                                           │
│    字体颜色 → [KPI by Platform Cell Font Color]                     │
│    背景色   → [KPI by Platform Cell Background Color]               │
│    SVG 图标 → [KPI by Platform Cell SVG Icon]（数据类别=图像 URL）   │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 8. Matrix 视觉对象配置

### 8.1 字段配置

| 区域         | 字段                                         |
| ------------ | -------------------------------------------- |
| **行** | Slicer_Store_Name[Store_ID]                  |
| **列** | 'Dim_ColMetric_KPI by Platform'[Metric_Name] |
| **值** | [KPI by Platform Cell Display]               |

### 8.2 排序配置

| 字段                                         | 排序依据    |
| -------------------------------------------- | ----------- |
| Slicer_Store_Name[Store_ID]                  | Store_Sort  |
| 'Dim_ColMetric_KPI by Platform'[Metric_Name] | Metric_Sort |

### 8.3 格式设置

- 关闭"阶梯布局"（Stepped Layout → Off）
- 关闭"行小计"（仅保留总计行用于汇总）
- 关闭"+/-"展开按钮
- 列标题：居中对齐，加粗
- 行标题：左对齐
- 值：居中对齐

### 8.4 条件格式

对 [KPI by Platform Cell Display] 值区域设置：

1. **字体颜色**：
   - 右键值区域 → 条件格式 → 字体颜色
   - 格式样式：字段值
   - 基于字段：[KPI by Platform Cell Font Color]
2. **背景颜色**：
   - 右键值区域 → 条件格式 → 背景颜色
   - 格式样式：字段值
   - 基于字段：[KPI by Platform Cell Background Color]
3. **SVG 图标**（可选）：
   - 将 [KPI by Platform Cell SVG Icon] 度量值的数据类别设为"图像 URL"
   - 在矩阵中单独添加为图像列，或使用自定义视觉对象

---

## 9. 验证方法

### 9.1 矩阵形状验证

| 验证项     | 方法                                                                                         |
| ---------- | -------------------------------------------------------------------------------------------- |
| 矩阵形状   | 确认 6 行（5 个 Store + 1 个总计）× 15 列（15 个 Metric）= 90 个单元格                      |
| 排序       | 行按 Store_Sort 排序；列按 Metric_Sort 排序（10, 20, 30, 40, 50, 60, 70, 80, 90, 100, 110, 120, 130, 140, 150） |
| YOY% 行名  | 确认 5 个 YOY% 行名后缀空格数不同（YOY% / YOY % / YOY  % / YOY   % / YOY    %）              |
| 总计行颜色 | 总计行字体黑色 #252423，背景中米色 #E6D9C7                                                   |
| 其他行颜色 | 其他行字体深灰 #5F6165，背景白色 #FFFFFF                                                     |
| SVG 图标   | 仅 YOY% 行显示圆形图标（正值绿、负值红、零值黄）                                             |
| Day/Week   | #34/#35 系列（Metric_ID 10~15）在 Day/Week 时为空                                           |

### 9.2 数据验证 SQL

```sql
-- Media Cost Rate（#31，比率，不涉及汇率）
SELECT
  SUM(cost_amt) * 1.13 / (SUM(net_sales_amt) * 1.06) AS MediaCostRate
FROM a05_e2e_paid_media_summary_d
WHERE customer_type='ALL' AND page_type='1'
  AND data_date BETWEEN '__TimeMin' AND '__TimeMax'
  AND platform='TM';

-- Media Cost（#32，金额，Cell Value 层÷汇率）
SELECT SUM(cost_amt) / __FXRate AS MediaCost
FROM a05_e2e_paid_media_summary_d
WHERE customer_type='ALL' AND page_type='1'
  AND data_date BETWEEN '__TimeMin' AND '__TimeMax'
  AND platform='TM';

-- ± Accel Cost MOB% vs. Store SLS MOB%（#33，比率，product_data_d 表）
SELECT
  (SUM(CASE WHEN mix_msg IS NULL AND framework='Acceleration' THEN cost_amt END)
   / SUM(CASE WHEN mix_msg IS NULL THEN cost_amt END))
  - (SUM(CASE WHEN framework='Acceleration' THEN net_sales_amt END)
   / SUM(net_sales_amt)) AS AccelCostMOBvsSLS
FROM a05_e2e_paid_media_product_data_d
WHERE data_date BETWEEN '__TimeMin' AND '__TimeMax'
  AND platform='TM';

-- Media Contribution to New Customer Acquisition%（#34，比率）
-- 分子：MAX+SUM(media_member_cnt) from summary_d
-- 分母：DISTINCTCOUNT(user_id) from customer_data_m（合并区间）
SELECT
  __MediaNewCustCnt / __TotalNewCustCnt AS MediaContrib
-- 分子 SQL（先 MAX 再 SUM）
SELECT
  platform, shop_id, data_month_name,
  MAX(media_member_cnt) AS max_media_member_cnt
FROM a05_e2e_paid_media_summary_d
WHERE customer_type='ALL' AND page_type='1'
  AND data_date BETWEEN '__TimeMin' AND '__TimeMax'
  AND platform='TM'
GROUP BY platform, shop_id, data_month_name;
-- 然后对 max_media_member_cnt 做 SUM
-- 分母 SQL（合并区间，第一财月）
SELECT COUNT(DISTINCT user_id) AS TotalNewCust
FROM a03_e2e_customer_data_m
WHERE data_date BETWEEN '__FirstFiscalMonthMin' AND '__FirstFiscalMonthMax'
  AND net_pay_amt > 0 AND is_member = 0 AND lp_12m_net_pay_amt = 0
  AND platform='TM';

-- Cost Per New Acquisition（#35，金额，Cell Value 层÷汇率）
-- 分子：MAX+SUM(media_cost_amt) from summary_d
-- 分母：MAX+SUM(media_member_cnt) from summary_d
SELECT
  (__MediaNewCostAmt / __FXRate) / __MediaNewCustCnt AS CostPerNewAcq
-- 分子 SQL（先 MAX 再 SUM）
SELECT
  platform, shop_id, data_month_name,
  MAX(media_cost_amt) AS max_media_cost_amt
FROM a05_e2e_paid_media_summary_d
WHERE customer_type='ALL' AND page_type='1'
  AND data_date BETWEEN '__TimeMin' AND '__TimeMax'
  AND platform='TM'
GROUP BY platform, shop_id, data_month_name;
-- 然后对 max_media_cost_amt 做 SUM
-- 分母 SQL（同分子，字段换为 media_member_cnt）
```

### 9.3 vs LP 验证

验证 vs LP 值时，将 SQL 中的日期范围替换为 `Slicer_Time_Frame_Min[TimeFrame_Min_LY]` 和 `Slicer_Time_Frame_Max[TimeFrame_Max_LY]` 对应的日期范围（日期表内置财历映射 LY 字段），新客分母用 `First_Fiscal_Month_Min_LY` / `First_Fiscal_Month_Max_LY`，对比 DAX 计算结果。

---

## 10. 关键设计说明

### 10.1 底表与筛选规则

| 指标类型 | 底表 | 筛选条件 |
| -------- | ---- | -------- |
| 汇总指标（#31/#32） | a05_e2e_paid_media_summary_d | customer_type='ALL' AND page_type="1" |
| 第二品类（#33） | a05_e2e_paid_media_product_data_d | Cost 类：mix_msg is NULL；SLS 类：不限 mix_msg；分子 framework='Acceleration' |
| 媒体新客（#34/#35） | a05_e2e_paid_media_summary_d | customer_type='ALL' AND page_type="1"，MAX+SUM 聚合 |
| 全店新客（#34 分母） | a03_e2e_customer_data_m | 合并区间：data_date ∈ [First_Fiscal_Month_Min, First_Fiscal_Month_Max] AND net_pay_amt > 0 AND is_member = 0 AND lp_12m_net_pay_amt = 0 |

### 10.2 汇率换算规则

| 指标类型 | 换算方式 | 判断依据 | 涉及 Metric_ID |
| -------- | -------- | -------- | --------------- |
| 金额类 | `DIVIDE([Base Value], Currency_ExchangeRate)`（除法，非乘法） | `IsCurrencyAmount = TRUE` | 4, 5, 13, 14 |
| 比率/增减百分比类 | 不换算，直接返回 [Base Value] | `IsCurrencyAmount = FALSE` | 1, 2, 3, 6, 7, 8, 9, 10, 11, 12, 15 |

### 10.3 vs LP 时间偏移规则（财历映射）

直接读取日期表内置 LY 字段：
- 全局 LY 起始日：`Slicer_Time_Frame_Min[TimeFrame_Min_LY]`
- 全局 LY 结束日：`Slicer_Time_Frame_Max[TimeFrame_Max_LY]`
- 新客 LY 第一财月：`Slicer_Time_Frame_Min[First_Fiscal_Month_Min_LY]` / `First_Fiscal_Month_Max_LY`
- 无需 EDATE -12 计算

### 10.4 全店新客判定规则（合并区间）

- 数据底表：`a03_e2e_customer_data_m`
- Step1 + Step2 交集（合并区间简化实现）：
  - Step1：在所选时间范围内筛选 `net_pay_amt > 0` 的 `user_id`（`data_date ∈ [__TimeMin, __TimeMax]`，`is_member = 0`）
  - Step2：缩小顾客范围至 `lp_12m_net_pay_amt = 0`（`data_date ∈ start_period`）
  - start_period = 第一财月，是 slicer 区间的子集，合并区间后单一 CALCULATE 即可
  - **合并区间等价实现**：`data_date ∈ [First_Fiscal_Month_Min, First_Fiscal_Month_Max] AND net_pay_amt > 0 AND is_member = 0 AND lp_12m_net_pay_amt = 0`
- 第一财月映射：月=自身 / 季=Q1→01,Q2→04,Q3→07,Q4→10 / 年=01
- vs LY 时使用 `First_Fiscal_Month_Min_LY` / `First_Fiscal_Month_Max_LY`

### 10.5 媒体新客字段聚合规则（MAX+SUM）

- 字段：`media_member_cnt`、`media_cost_amt`
- 聚合方式：先按 `platform`、`shop_id`、`data_month_name` 取 `MAX`，再对所选财月 `SUM`
- 仅支持完整财月、财季、财年，`Day`/`Week` 时为空
- DAX 实现：`SUMX(SUMMARIZE(..., "__Value", MAX([字段])), [__Value])`
- 列引用写法：`[__Value]`，不是字符串 `"__Value"`
- 涉及 Metric_ID：10, 11, 12, 13, 14, 15

### 10.6 Day/Week 留空规则

- 涉及 MAX+SUM 聚合的指标（#34/#35 系列 = Metric_ID 10~15）在 Day/Week 时无意义
- 在总路由层 `IF(__IsDayOrWeek && __NeedsFullFiscalPeriod, BLANK(), ...)` 统一留空
- 不细分到分子分母，避免冗余判断和潜在不一致

### 10.7 Cell Display 全拓展类型

支持 16 种格式类型，便于后续拓展：
- 整数与小数：`integer`、`decimal_1dp`、`decimal_2dp`
- 货币：`currency`、`currency_decimal_1dp`、`currency_k`、`currency_M_K_Int_0db`
- 百分比：`percent_0dp`、`percent_1dp`、`percent_2dp`
- 增减百分比：`delta_pct_0dp`、`delta_pct_1dp`、`delta_pct_2dp`
- 增减基点：`delta_pts`、`integer_pts`、`delta_bp`、`delta_bp_1dp`

### 10.8 性能考量

| 考量项         | 评估                                                                                        |
| -------------- | ------------------------------------------------------------------------------------------- |
| 矩阵规模       | 6 行 × 15 列 = 90 个单元格，规模适中                                                       |
| CALCULATE 调用 | 每个单元格最多触发 5 次基础聚合（Current/vsLP 各 5 个），总计约 450 次                      |
| 时间筛选       | 使用布尔筛选器 `data_date >= __TimeMin`，等价于 `FILTER(ALL(data_date), ...)`，性能良好 |
| 变量复用       | Current 和 vsLP 的基础聚合在各自度量值内定义为变量，避免重复计算                            |
| 优化建议       | 如性能不佳，可将基础聚合提取为独立度量值，利用 Power BI 缓存                                 |
