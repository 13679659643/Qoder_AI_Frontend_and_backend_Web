# KPIs Overview Target Matrix Solution

> **status**: propose
> **created**: 2026-08-27
> **based**: Overview.md 板块二 Growth Overview-Target Achievement（10 个指标）
> **complexity**: 🔴复杂
> **type**: 度量值开发 + 可视化构建

---

## 0. 需求概述与架构总览

### 0.1 目标

实现 KPIs Overview 目标达成矩阵看板：

- **行**：Actual / Target / ±Actual vs Target（3 行，`DIM_RowKPIs_Overview_Target` 断开维度控制）
- **列**：10 个独立指标（`DIM_ColMetric_Target` 断开维度控制）
- **日期切片器**：`Slicer_Time_Frame`（断开，单选；TimeFrame_ID = Month/Year，始终单个完整财月/财年）

### 0.2 核心设计要点

| # | 要点 | 说明 |
|---|------|------|
| 1 | Target 数据源切换 | Target 改用独立预测表 `a05_e2e_paid_media_fcst_data_m`（不再用 summary_d 的 fcst_ 前缀字段） |
| 2 | 日期驱动方式 | 新增断开日期表 `Slicer_Time_Frame` 作为本方案唯一日期来源 |
| 3 | Dim_Date_Current 关系处理 | 仅 `a05_e2e_paid_media_summary_d`、`a05_e2e_paid_media_product_data_d` 与 Dim_Date_Current 有连接关系，需 `REMOVEFILTERS(Dim_Date_Current)` 后重施加 `data_date` 筛选；`a05_e2e_paid_media_fcst_data_m`、`a03_e2e_customer_data_m` 与 Dim_Date_Current 无连接关系，无需 REMOVEFILTERS |
| 4 | Platform 筛选 | 仅 `a05_e2e_paid_media_fcst_data_m` 在物理层面计算好了 `platform IN {"ALL"}`，始终单选形式（ALL→`="ALL"`，单平台→`=__ChannelID`）；Actual 表（summary_d / product_data_d / a03）用 `FILTER(ALL(<表>[platform]), ...)` 写法，ALL→`IN{"TM","JD"}`，单平台→`=__ChannelID`（避免嵌套 IF 返回表降级为标量） |
| 5 | Target 时间粒度路由 | 根据 `Slicer_Time_Frame[TimeFrame_ID]` 取不同字段：Month 取月度字段，Year 取 year_ 年度字段（同财年 12 行重复，用 SUMMARIZE 去重） |
| 6 | ACH% 类指标（ID 2-6） | Target 固定 100%；Actual = 实际值 / fcst 对应目标值 |
| 7 | ±delta 口径 | ID 1-9 = Actual - Target；ID 10 = Actual / Target - 1；Target 缺失/为 0 → ±delta 展示 "-" |
| 8 | 币种换算 | 仅 ID 10（金额类）在 Cell Value 层 `Value / Currency_ExchangeRate`（除法）；比率类不换算 |

### 0.3 架构链

```
Slicer_Time_Frame（断开，单选）
  └─ SELECTEDVALUE → TimeFrame_ID / TimeFrame_Min / TimeFrame_Max
       │
       ├─ summary_d / product_data_d：REMOVEFILTERS(Dim_Date_Current) → 重施加 data_date ∈ [Min, Max]
       ├─ fcst_data_m：直接筛选 data_date ∈ [Min, Max]（与 Dim_Date_Current 无连接）
       └─ a03_customer_data_m：直接筛选 data_date ∈ [Min, Max]（与 Dim_Date_Current 无连接）

Slicer_Platform_Selection（单选含 ALL）
  ├─ Actual 表（summary_d / product_data_d / a03）：ALL→IN{"TM","JD"}；单平台→=__ChannelID
  └─ Target 表（fcst_data_m）：ALL→IN{"ALL"}；单平台→=__ChannelID

Slicer_Currency_Selection（单选）
  └─ SELECTEDVALUE → Currency_ExchangeRate / Currency_Symbol（仅金额类 ÷ 汇率）

DIM_RowKPIs_Overview_Target（行路由）──→ Cell Value
DIM_ColMetric_Target（列路由）──────→ Actual/Target Base Value

KPIs Overview Target Actual Base Value ── 列 SWITCH（10 列）
KPIs Overview Target Target Base Value ── 列 SWITCH（10 列，fcst 表，SUMMARIZE 去重）
        ▼
KPIs Overview Target Cell Value ── 行路由 + 金额类 ÷ 汇率；±delta 按口径
        ├──→ Cell Display（格式化）
        ├──→ Cell Font Color（仅 ±delta 行三色）
        ├──→ Cell SVG Icon（仅 ±delta 行箭头）
        └──→ Cell Background Color（交替行）
```

### 0.4 指标列对照

| # | 列名 | 格式 | 金额 | Actual 数据源 | Target 数据源 |
|---|------|------|------|--------------|---------------|
| 1 | Cost Rate | percent_1dp | FALSE | summary_d | fcst(rate) |
| 2 | RTB Cost ACH% | percent_1dp | FALSE | summary_d + fcst(amount) | 固定 100% |
| 3 | Cost ACH% | percent_1dp | FALSE | summary_d + fcst(amount) | 固定 100% |
| 4 | Cost ACH%(Exclude Refund) | percent_1dp | FALSE | summary_d + fcst(amount) | 固定 100% |
| 5 | Net Sales ACH% | percent_1dp | FALSE | summary_d + fcst(amount) | 固定 100% |
| 6 | Demand Sales ACH% | percent_1dp | FALSE | summary_d + fcst(amount) | 固定 100% |
| 7 | Acceleration Cost% | percent_1dp | FALSE | product_data_d | fcst(rate) |
| 8 | Acceleration Net Sales% | percent_1dp | FALSE | product_data_d | fcst(rate) |
| 9 | Media Contribution to New Customer% | percent_1dp | FALSE | summary_d(分子) + a03(分母) | fcst(rate) |
| 10 | Cost Per New Acquisition | currency_decimal_1dp | TRUE | summary_d | fcst(amount) |

---

## 1. 行维度 — DIM_RowKPIs_Overview_Target

```dax
DIM_RowKPIs_Overview_Target = 
// ========================================
// 表: DIM_RowKPIs_Overview_Target
// 类型: 断开维度（新建，仅目标达成矩阵使用）
// 用途: 目标达成矩阵行维度（Actual / Target / ±Actual vs Target）
//       Indicator_Type 用于 Cell Value 度量值中的行路由
//       ±Actual vs Target 行启用条件颜色（正/负/零三色）
//       Actual / Target 行统一使用默认颜色 #5f6165
// ========================================
DATATABLE(
    "Indicator_Type",  STRING,    // 行标签（矩阵显示名称）
    "Indicator_Order", INTEGER,   // 排序值（起始10，步长10：10=Actual, 20=Target, 30=±Actual vs Target）
    {
        {"Actual",             10},
        {"Target",             20},
        {"±Actual vs Target",  30}
    }
)
```

> Sort by Column：`[Indicator_Type]` → `[Indicator_Order]`

---

## 2. 列维度 — DIM_ColMetric_Target

```dax
DIM_ColMetric_Target =
// 列维度断开表：10 个指标
// ACH% 类（ID 2-6）Target = 100%，统一 percent_1dp
// 仅 ID 10 为金额类（Metric_IsCurrencyAmount = TRUE）
VAR __Rows =
    UNION(
        // ID 1: Cost Rate — Actual = SUM(cost_amt)/SUM(net_sales_amt)×1.13/1.06；Target = media_cost_rate/year_media_cost_rate
        ROW(
            "Metric_ID", 1, "Metric_Name", "Cost Rate", "Metric_Sort", 10,
            "Metric_Format", "percent_1dp", "Metric_IsCurrencyAmount", FALSE,
            "Metric_ColorPositive", "#1A9018", "Metric_ColorNegative", "#D64550",
            "Metric_ColorZero", "#E1C233", "Metric_ColorDefault", "#5f6165"
        ),
        // ID 2: RTB Cost ACH% — Actual = SUM(cost_amt[RTB])/rtb目标；Target = 100%
        ROW(
            "Metric_ID", 2, "Metric_Name", "RTB Cost ACH%", "Metric_Sort", 20,
            "Metric_Format", "percent_1dp", "Metric_IsCurrencyAmount", FALSE,
            "Metric_ColorPositive", "#1A9018", "Metric_ColorNegative", "#D64550",
            "Metric_ColorZero", "#E1C233", "Metric_ColorDefault", "#5f6165"
        ),
        // ID 3: Cost ACH% — Actual = SUM(cost_amt)/cost目标；Target = 100%
        ROW(
            "Metric_ID", 3, "Metric_Name", "Cost ACH%", "Metric_Sort", 30,
            "Metric_Format", "percent_1dp", "Metric_IsCurrencyAmount", FALSE,
            "Metric_ColorPositive", "#1A9018", "Metric_ColorNegative", "#D64550",
            "Metric_ColorZero", "#E1C233", "Metric_ColorDefault", "#5f6165"
        ),
        // ID 4: Cost ACH%(Exclude Refund) — Actual = (cost_amt-red_packet-rebate)/cost目标；Target = 100%
        ROW(
            "Metric_ID", 4, "Metric_Name", "Cost ACH%(Exclude Refund)", "Metric_Sort", 40,
            "Metric_Format", "percent_1dp", "Metric_IsCurrencyAmount", FALSE,
            "Metric_ColorPositive", "#1A9018", "Metric_ColorNegative", "#D64550",
            "Metric_ColorZero", "#E1C233", "Metric_ColorDefault", "#5f6165"
        ),
        // ID 5: Net Sales ACH% — Actual = SUM(net_sales_amt)/net_sales目标；Target = 100%
        ROW(
            "Metric_ID", 5, "Metric_Name", "Net Sales ACH%", "Metric_Sort", 50,
            "Metric_Format", "percent_1dp", "Metric_IsCurrencyAmount", FALSE,
            "Metric_ColorPositive", "#1A9018", "Metric_ColorNegative", "#D64550",
            "Metric_ColorZero", "#E1C233", "Metric_ColorDefault", "#5f6165"
        ),
        // ID 6: Demand Sales ACH% — Actual = SUM(sales_amt)/sales目标；Target = 100%
        ROW(
            "Metric_ID", 6, "Metric_Name", "Demand Sales ACH%", "Metric_Sort", 60,
            "Metric_Format", "percent_1dp", "Metric_IsCurrencyAmount", FALSE,
            "Metric_ColorPositive", "#1A9018", "Metric_ColorNegative", "#D64550",
            "Metric_ColorZero", "#E1C233", "Metric_ColorDefault", "#5f6165"
        ),
        // ID 7: Acceleration Cost% — Actual = SUM(cost_amt[Acc])/SUM(cost_amt[全部])；基础筛选 mix_msg is NULL；Target = acceleration_cost_rate/year_*
        ROW(
            "Metric_ID", 7, "Metric_Name", "Acceleration Cost%", "Metric_Sort", 70,
            "Metric_Format", "percent_1dp", "Metric_IsCurrencyAmount", FALSE,
            "Metric_ColorPositive", "#1A9018", "Metric_ColorNegative", "#D64550",
            "Metric_ColorZero", "#E1C233", "Metric_ColorDefault", "#5f6165"
        ),
        // ID 8: Acceleration Net Sales% — Actual = SUM(net_sales_amt[Acc])/SUM(net_sales_amt[全部])；无 mix_msg 筛选；Target = acceleration_net_sales_rate/year_*
        ROW(
            "Metric_ID", 8, "Metric_Name", "Acceleration Net Sales%", "Metric_Sort", 80,
            "Metric_Format", "percent_1dp", "Metric_IsCurrencyAmount", FALSE,
            "Metric_ColorPositive", "#1A9018", "Metric_ColorNegative", "#D64550",
            "Metric_ColorZero", "#E1C233", "Metric_ColorDefault", "#5f6165"
        ),
        // ID 9: Media Contribution — Actual = 媒体新客数/全店新客数；Target = media_new_customer_contribution_rate/year_*
        ROW(
            "Metric_ID", 9, "Metric_Name", "Media Contribution to New Customer Acquisition%", "Metric_Sort", 90,
            "Metric_Format", "percent_1dp", "Metric_IsCurrencyAmount", FALSE,
            "Metric_ColorPositive", "#1A9018", "Metric_ColorNegative", "#D64550",
            "Metric_ColorZero", "#E1C233", "Metric_ColorDefault", "#5f6165"
        ),
        // ID 10: Cost Per New Acquisition — Actual = media_cost_amt/media_member_cnt（SUMMARIZE去重）；Target = cost_per_new_acquisition/year_*（金额类）
        ROW(
            "Metric_ID", 10, "Metric_Name", "Cost Per New Acquisition", "Metric_Sort", 100,
            "Metric_Format", "currency_decimal_1dp", "Metric_IsCurrencyAmount", TRUE,
            "Metric_ColorPositive", "#1A9018", "Metric_ColorNegative", "#D64550",
            "Metric_ColorZero", "#E1C233", "Metric_ColorDefault", "#5f6165"
        )
    )
RETURN __Rows
```

> Sort by Column：`[Metric_Name]` → `[Metric_Sort]`

---

## 3. 切片器参数表

### 3.1 日期切片器 Slicer_Time_Frame（本方案新增，断开）

- **数据源**：`维度复用\Slicer_Time_Frame.sql`（仅保留 TimeFrame_ID IN {Month, Year}，单选）
- **关键字段**：
  - `TimeFrame_ID`：时间粒度（Month/Year）
  - `TimeFrame_Value`：展示值（如 2026-10、2026）
  - `TimeFrame_Min / TimeFrame_Max`：所选时间区间起止自然日
- **计算口径**：`data_date ∈ [TimeFrame_Min, TimeFrame_Max]`
- **切片器**：单选，默认当前财月；不存在跨财月/跨财年

### 3.2 平台 Slicer_Platform_Selection

- **复用** TTL 汇总方案（单选含 ALL）
- **Platform 筛选规则**（Actual 表用 FILTER 写法，避免嵌套 IF 返回表降级为标量；Target 表用单选形式）：

| 目标表 | ALL | 单平台 | 写法 |
|--------|-----|--------|------|
| Actual 表（summary_d / product_data_d / a03） | `IN{"TM","JD"}` | `=__ChannelID` | `FILTER(ALL(<表>[platform]), IF(__ChannelID="ALL", [platform] IN {"TM","JD"}, [platform]=__ChannelID))` |
| Target 表（fcst_data_m） | `="ALL"` | `=__ChannelID` | `[platform] = IF(__ChannelID="ALL", "ALL", __ChannelID)` |

### 3.3 币种 Slicer_Currency_Selection

- **复用** TTL 汇总方案
- `Currency_ExchangeRate`（RMB=1, USD=7）
- `Currency_Symbol`
- **换算时机**：Cell Value 层 `Value / Currency_ExchangeRate`（除法），仅金额类指标

### 3.4 数据口径 Slicer_DataCaliber_Selection

- **复用** TTL 汇总方案
- `DataCaliber_ID`（→ trans_cycle 单选）、`DataCaliber_Label`

---

## 4. 关系与数据模型

### 4.1 事实表

| Power BI 表名 | 用途 | 与 Dim_Date_Current 关系 |
|---------------|------|--------------------------|
| `a05_e2e_paid_media_summary_d` | Actual：cost / net_sales / sales / red_packet / rebate / media_member_cnt / media_cost_amt | ✅ 已连接（需 REMOVEFILTERS） |
| `a05_e2e_paid_media_product_data_d` | Actual：Acceleration（framework 维度） | ✅ 已连接（需 REMOVEFILTERS） |
| `a05_e2e_paid_media_fcst_data_m` | Target：预测表（platform 含 ALL，月度行） | ❌ 断开（无需 REMOVEFILTERS） |
| `a03_e2e_customer_data_m` | Actual ID9 分母：全店新客数 | ❌ 断开（无需 REMOVEFILTERS） |
| `Dim_Date_Current` | 看板层日期 | — |
| `Slicer_Time_Frame` | 本方案日期来源（断开） | — |

### 4.2 关系配置

```
已连接关系（Active，看板层）：
    Dim_Date_Current[数据日期] ──── 1:* ────→ a05_e2e_paid_media_summary_d[data_date]
    Dim_Date_Current[数据日期] ──── 1:* ────→ a05_e2e_paid_media_product_data_d[data_date]

断开维度（无关系）：
    Slicer_Time_Frame            ← SELECTEDVALUE → TimeFrame_ID / TimeFrame_Min / TimeFrame_Max
    Slicer_Platform_Selection    ← SELECTEDVALUE → Platform_ID
    Slicer_DataCaliber_Selection ← SELECTEDVALUE → trans_cycle
    Slicer_Currency_Selection    ← SELECTEDVALUE → ExchangeRate / Symbol
    DIM_RowKPIs_Overview_Target  ← SELECTEDVALUE → Indicator_Type
    DIM_ColMetric_Target         ← SELECTEDVALUE → Metric_ID / Metric_IsCurrencyAmount
    a05_e2e_paid_media_fcst_data_m ← 与 Slicer_Platform_Selection / Dim_Date_Current 均断开
    a03_e2e_customer_data_m        ← 与 Dim_Date_Current 断开
```

**日期处理原则**：

| 表 | 与 Dim_Date_Current 关系 | 处理方式 |
|----|--------------------------|----------|
| summary_d | ✅ 已连接 | `REMOVEFILTERS(Dim_Date_Current)` + 重施加 `data_date ∈ [Min, Max]` |
| product_data_d | ✅ 已连接 | `REMOVEFILTERS(Dim_Date_Current)` + 重施加 `data_date ∈ [Min, Max]` |
| fcst_data_m | ❌ 断开 | 直接筛选 `data_date ∈ [Min, Max]`（无需 REMOVEFILTERS） |
| a03_customer_data_m | ❌ 断开 | 直接筛选 `data_date ∈ [Min, Max]`（无需 REMOVEFILTERS） |

### 4.3 Sort by Column

| 表 | 字段 | Sort by Column |
|----|------|----------------|
| DIM_RowKPIs_Overview_Target | Indicator_Type | Indicator_Order |
| DIM_ColMetric_Target | Metric_Name | Metric_Sort |
| Slicer_Platform_Selection | Platform_Label | Platform_Sort |
| Slicer_Time_Frame | TimeFrame_Value | TimeFrame_Sort |
| Slicer_DataCaliber_Selection | DataCaliber_Label | DataCaliber_Sort |
| Slicer_Currency_Selection | Currency_Label | Currency_Sort |

---

## 5. 核心度量值

### 5.1 公共变量约定

每个度量值内部独立声明以下变量：

```dax
// ── 列路由 ──
VAR __SelID = SELECTEDVALUE(DIM_ColMetric_Target[Metric_ID])

// ── 平台筛选 ──
VAR __ChannelID = SELECTEDVALUE(Slicer_Platform_Selection[Platform_ID], "ALL")

// Actual 表平台筛选（FILTER 写法，避免嵌套 IF 返回表被降级为标量）
// ALL→IN{"TM","JD"}；单平台→=__ChannelID
// 每个事实表单独声明一个 __PlatformFilter_<表名> 变量：
VAR __PlatformFilter_summary =
    FILTER(
        ALL(a05_e2e_paid_media_summary_d[platform]),
        IF(
            __ChannelID = "ALL",
            a05_e2e_paid_media_summary_d[platform] IN {"TM", "JD"},
            a05_e2e_paid_media_summary_d[platform] = __ChannelID
        )
    )
VAR __PlatformFilter_product =
    FILTER(
        ALL(a05_e2e_paid_media_product_data_d[platform]),
        IF(
            __ChannelID = "ALL",
            a05_e2e_paid_media_product_data_d[platform] IN {"TM", "JD"},
            a05_e2e_paid_media_product_data_d[platform] = __ChannelID
        )
    )
VAR __PlatformFilter_a03 =
    FILTER(
        ALL(a03_e2e_customer_data_m[platform]),
        IF(
            __ChannelID = "ALL",
            a03_e2e_customer_data_m[platform] IN {"TM", "JD"},
            a03_e2e_customer_data_m[platform] = __ChannelID
        )
    )

// Target 表（fcst_data_m）：platform 已物理算好 ALL，始终单选形式
// ALL→platform="ALL"；单平台→platform=__ChannelID

// ── 数据口径 ──
VAR __TransCycle = SELECTEDVALUE(Slicer_DataCaliber_Selection[DataCaliber_ID], "T+1")

// ── 日期 ──
VAR __TimeFrameID = SELECTEDVALUE(Slicer_Time_Frame[TimeFrame_ID], "Month")
VAR __TimeMin = SELECTEDVALUE(Slicer_Time_Frame[TimeFrame_Min])
VAR __TimeMax = SELECTEDVALUE(Slicer_Time_Frame[TimeFrame_Max])
```

**fcst Target 取数 SUMMARIZE 去重模板**：

```dax
// Month：SUMMARIZE(fcst, [platform], [月度字段]) → SUMX 月度字段
// Year ：SUMMARIZE(fcst, [platform], [year_年度字段]) → SUMX 年度字段（同财年12行去重）
// fcst 表 platform 已物理算好 ALL：ALL→platform="ALL"；单平台→platform=__ChannelID（单选形式）

// 示例（Year）：
VAR __YearTarget =
    CALCULATE(
        SUMX(
            SUMMARIZE(
                'a05_e2e_paid_media_fcst_data_m',
                'a05_e2e_paid_media_fcst_data_m'[platform],
                'a05_e2e_paid_media_fcst_data_m'[year_media_cost_rate]
            ),
            'a05_e2e_paid_media_fcst_data_m'[year_media_cost_rate]
        ),
        'a05_e2e_paid_media_fcst_data_m'[platform] =
            IF(__ChannelID = "ALL", "ALL", __ChannelID),
        'a05_e2e_paid_media_fcst_data_m'[data_date] >= __TimeMin,
        'a05_e2e_paid_media_fcst_data_m'[data_date] <= __TimeMax
    )
```

---

### 5.2 Actual 实际值 — KPIs Overview Target Actual Base Value

```dax
KPIs Overview Target Actual Base Value =
// Actual 行：Metric_ID SWITCH（10 列），日期 = Slicer_Time_Frame[TimeFrame_Min~Max]
// summary_d / product_data_d：REMOVEFILTERS(Dim_Date_Current) 后重施加 data_date
// fcst（ACH%分母）/ a03（ID9分母）：直接筛选 data_date（与 Dim_Date_Current 无连接）
// 平台筛选：Actual 表用 __PlatformFilter_<表>（FILTER 写法）；
//           fcst 表用 platform = IF(__ChannelID="ALL","ALL",__ChannelID)（单选形式）
// ACH% 类（ID 2-6）：Actual = 实际值 / fcst目标值
// ID 9：分子 media_member_cnt 用 SUMMARIZE 去重；分母走 a03 直接筛选 DISTINCTCOUNT

VAR __SelID = SELECTEDVALUE(DIM_ColMetric_Target[Metric_ID])
VAR __ChannelID = SELECTEDVALUE(Slicer_Platform_Selection[Platform_ID], "ALL")

// ── Actual 表平台 FILTER 变量（每表一个，避免嵌套 IF 返回表降级） ──
VAR __PlatformFilter_summary =
    FILTER(
        ALL(a05_e2e_paid_media_summary_d[platform]),
        IF(
            __ChannelID = "ALL",
            a05_e2e_paid_media_summary_d[platform] IN {"TM", "JD"},
            a05_e2e_paid_media_summary_d[platform] = __ChannelID
        )
    )
VAR __PlatformFilter_product =
    FILTER(
        ALL(a05_e2e_paid_media_product_data_d[platform]),
        IF(
            __ChannelID = "ALL",
            a05_e2e_paid_media_product_data_d[platform] IN {"TM", "JD"},
            a05_e2e_paid_media_product_data_d[platform] = __ChannelID
        )
    )
VAR __PlatformFilter_a03 =
    FILTER(
        ALL(a03_e2e_customer_data_m[platform]),
        IF(
            __ChannelID = "ALL",
            a03_e2e_customer_data_m[platform] IN {"TM", "JD"},
            a03_e2e_customer_data_m[platform] = __ChannelID
        )
    )

// ── fcst 表 platform 筛选值（单选形式） ──
// VAR __FcstPlatform = IF(__ChannelID = "ALL", "ALL", __ChannelID)

VAR __TransCycle = SELECTEDVALUE(Slicer_DataCaliber_Selection[DataCaliber_ID], "T+1")
VAR __TimeFrameID = SELECTEDVALUE(Slicer_Time_Frame[TimeFrame_ID], "Month")
VAR __TimeMin = SELECTEDVALUE(Slicer_Time_Frame[TimeFrame_Min])
VAR __TimeMax = SELECTEDVALUE(Slicer_Time_Frame[TimeFrame_Max])

RETURN
SWITCH(
    __SelID,

    // ═══ ID 1: Cost Rate = SUM(cost_amt) / SUM(net_sales_amt) × 1.13 / 1.06 ═══
    1,
    VAR __Cost =
        CALCULATE(
            SUM(a05_e2e_paid_media_summary_d[cost_amt]),
            REMOVEFILTERS(Dim_Date_Current),
            a05_e2e_paid_media_summary_d[data_date] >= __TimeMin,
            a05_e2e_paid_media_summary_d[data_date] <= __TimeMax,
            a05_e2e_paid_media_summary_d[customer_type] = "ALL",
            a05_e2e_paid_media_summary_d[page_type] = "1",
            __PlatformFilter_summary,
            a05_e2e_paid_media_summary_d[trans_cycle] = __TransCycle
        )
    VAR __Net =
        CALCULATE(
            SUM(a05_e2e_paid_media_summary_d[net_sales_amt]),
            REMOVEFILTERS(Dim_Date_Current),
            a05_e2e_paid_media_summary_d[data_date] >= __TimeMin,
            a05_e2e_paid_media_summary_d[data_date] <= __TimeMax,
            a05_e2e_paid_media_summary_d[customer_type] = "ALL",
            a05_e2e_paid_media_summary_d[page_type] = "1",
            __PlatformFilter_summary,
            a05_e2e_paid_media_summary_d[trans_cycle] = __TransCycle
        )
    RETURN DIVIDE(__Cost, __Net) * 1.13 / 1.06,

    // ═══ ID 2: RTB Cost ACH% = SUM(cost_amt[RTB]) / rtb目标(fcst) ═══
    2,
    VAR __CostRTB =
        CALCULATE(
            SUM(a05_e2e_paid_media_summary_d[cost_amt]),
            REMOVEFILTERS(Dim_Date_Current),
            a05_e2e_paid_media_summary_d[data_date] >= __TimeMin,
            a05_e2e_paid_media_summary_d[data_date] <= __TimeMax,
            a05_e2e_paid_media_summary_d[customer_type] = "ALL",
            a05_e2e_paid_media_summary_d[channel_type] = "RTB",
            a05_e2e_paid_media_summary_d[page_type] = "1",
            __PlatformFilter_summary,
            a05_e2e_paid_media_summary_d[trans_cycle] = __TransCycle
        )
    // rtb目标：Month→rtb_cost_amt；Year→year_rtb_cost_amt；fcst 表 platform 单选
    VAR __RtbTarget =
        IF(__TimeFrameID = "Month",
            CALCULATE(
                MAX(a05_e2e_paid_media_fcst_data_m[rtb_cost_amt]),
                a05_e2e_paid_media_fcst_data_m[platform] = IF(__ChannelID = "ALL", "ALL", __ChannelID),
                a05_e2e_paid_media_fcst_data_m[data_date] >= __TimeMin,
                a05_e2e_paid_media_fcst_data_m[data_date] <= __TimeMax
            ),
            CALCULATE(
                MAX(a05_e2e_paid_media_fcst_data_m[year_rtb_cost_amt]),
                a05_e2e_paid_media_fcst_data_m[platform] = IF(__ChannelID = "ALL", "ALL", __ChannelID),
                a05_e2e_paid_media_fcst_data_m[data_date] >= __TimeMin,
                a05_e2e_paid_media_fcst_data_m[data_date] <= __TimeMax
            )
        )
    RETURN DIVIDE(__CostRTB, __RtbTarget),

    // ═══ ID 3: Cost ACH% = SUM(cost_amt) / cost目标(fcst) ═══
    3,
    VAR __Cost =
        CALCULATE(
            SUM(a05_e2e_paid_media_summary_d[cost_amt]),
            REMOVEFILTERS(Dim_Date_Current),
            a05_e2e_paid_media_summary_d[data_date] >= __TimeMin,
            a05_e2e_paid_media_summary_d[data_date] <= __TimeMax,
            a05_e2e_paid_media_summary_d[customer_type] = "ALL",
            a05_e2e_paid_media_summary_d[page_type] = "1",
            __PlatformFilter_summary,
            a05_e2e_paid_media_summary_d[trans_cycle] = __TransCycle
        )
    VAR __CostTarget =
        IF(__TimeFrameID = "Month",
            CALCULATE(
                MAX(a05_e2e_paid_media_fcst_data_m[cost_amt]),
                a05_e2e_paid_media_fcst_data_m[platform] = IF(__ChannelID = "ALL", "ALL", __ChannelID),
                a05_e2e_paid_media_fcst_data_m[data_date] >= __TimeMin,
                a05_e2e_paid_media_fcst_data_m[data_date] <= __TimeMax
            ),
            CALCULATE(
                MAX(a05_e2e_paid_media_fcst_data_m[year_cost_amt]),
                a05_e2e_paid_media_fcst_data_m[platform] = IF(__ChannelID = "ALL", "ALL", __ChannelID),
                a05_e2e_paid_media_fcst_data_m[data_date] >= __TimeMin,
                a05_e2e_paid_media_fcst_data_m[data_date] <= __TimeMax
            )
        )
    RETURN DIVIDE(__Cost, __CostTarget),

    // ═══ ID 4: Cost ACH%(Exclude Refund) = (SUM(cost_amt)-SUM(red_packet)-SUM(rebate)) / cost目标(fcst) ═══
    4,
    VAR __CostEx =
        CALCULATE(
            SUMX(
                a05_e2e_paid_media_summary_d,
                a05_e2e_paid_media_summary_d[cost_amt]
                  - a05_e2e_paid_media_summary_d[red_packet]
                  - a05_e2e_paid_media_summary_d[rebate]
            ),
            REMOVEFILTERS(Dim_Date_Current),
            a05_e2e_paid_media_summary_d[data_date] >= __TimeMin,
            a05_e2e_paid_media_summary_d[data_date] <= __TimeMax,
            a05_e2e_paid_media_summary_d[customer_type] = "ALL",
            a05_e2e_paid_media_summary_d[page_type] = "1",
            __PlatformFilter_summary,
            a05_e2e_paid_media_summary_d[trans_cycle] = __TransCycle
        )
    VAR __CostTarget =
        IF(__TimeFrameID = "Month",
            CALCULATE(
                MAX(a05_e2e_paid_media_fcst_data_m[cost_amt]),
                a05_e2e_paid_media_fcst_data_m[platform] = IF(__ChannelID = "ALL", "ALL", __ChannelID),
                a05_e2e_paid_media_fcst_data_m[data_date] >= __TimeMin,
                a05_e2e_paid_media_fcst_data_m[data_date] <= __TimeMax
            ),
            CALCULATE(
                MAX(a05_e2e_paid_media_fcst_data_m[year_cost_amt]),
                a05_e2e_paid_media_fcst_data_m[platform] = IF(__ChannelID = "ALL", "ALL", __ChannelID),
                a05_e2e_paid_media_fcst_data_m[data_date] >= __TimeMin,
                a05_e2e_paid_media_fcst_data_m[data_date] <= __TimeMax
            )
        )
    RETURN DIVIDE(__CostEx, __CostTarget),

    // ═══ ID 5: Net Sales ACH% = SUM(net_sales_amt) / net_sales目标(fcst) ═══
    5,
    VAR __Net =
        CALCULATE(
            SUM(a05_e2e_paid_media_summary_d[net_sales_amt]),
            REMOVEFILTERS(Dim_Date_Current),
            a05_e2e_paid_media_summary_d[data_date] >= __TimeMin,
            a05_e2e_paid_media_summary_d[data_date] <= __TimeMax,
            a05_e2e_paid_media_summary_d[customer_type] = "ALL",
            a05_e2e_paid_media_summary_d[page_type] = "1",
            __PlatformFilter_summary,
            a05_e2e_paid_media_summary_d[trans_cycle] = __TransCycle
        )
    VAR __NetTarget =
        IF(__TimeFrameID = "Month",
            CALCULATE(
                MAX(a05_e2e_paid_media_fcst_data_m[net_sales_amt]),
                a05_e2e_paid_media_fcst_data_m[platform] = IF(__ChannelID = "ALL", "ALL", __ChannelID),
                a05_e2e_paid_media_fcst_data_m[data_date] >= __TimeMin,
                a05_e2e_paid_media_fcst_data_m[data_date] <= __TimeMax
            ),
            CALCULATE(
                MAX(a05_e2e_paid_media_fcst_data_m[year_net_sales_amt]),
                a05_e2e_paid_media_fcst_data_m[platform] = IF(__ChannelID = "ALL", "ALL", __ChannelID),
                a05_e2e_paid_media_fcst_data_m[data_date] >= __TimeMin,
                a05_e2e_paid_media_fcst_data_m[data_date] <= __TimeMax
            )
        )
    RETURN DIVIDE(__Net, __NetTarget),

    // ═══ ID 6: Demand Sales ACH% = SUM(sales_amt) / sales目标(fcst) ═══
    6,
    VAR __Sales =
        CALCULATE(
            SUM(a05_e2e_paid_media_summary_d[sales_amt]),
            REMOVEFILTERS(Dim_Date_Current),
            a05_e2e_paid_media_summary_d[data_date] >= __TimeMin,
            a05_e2e_paid_media_summary_d[data_date] <= __TimeMax,
            a05_e2e_paid_media_summary_d[customer_type] = "ALL",
            a05_e2e_paid_media_summary_d[page_type] = "1",
            __PlatformFilter_summary,
            a05_e2e_paid_media_summary_d[trans_cycle] = __TransCycle
        )
    VAR __SalesTarget =
        IF(__TimeFrameID = "Month",
            CALCULATE(
                MAX(a05_e2e_paid_media_fcst_data_m[sales_amt]),
                a05_e2e_paid_media_fcst_data_m[platform] = IF(__ChannelID = "ALL", "ALL", __ChannelID),
                a05_e2e_paid_media_fcst_data_m[data_date] >= __TimeMin,
                a05_e2e_paid_media_fcst_data_m[data_date] <= __TimeMax
            ),
            CALCULATE(
                MAX(a05_e2e_paid_media_fcst_data_m[year_sales_amt]),
                a05_e2e_paid_media_fcst_data_m[platform] = IF(__ChannelID = "ALL", "ALL", __ChannelID),
                a05_e2e_paid_media_fcst_data_m[data_date] >= __TimeMin,
                a05_e2e_paid_media_fcst_data_m[data_date] <= __TimeMax
            )
        )
    RETURN DIVIDE(__Sales, __SalesTarget),

    // ═══ ID 7: Acceleration Cost% = SUM(cost_amt[Acc]) / SUM(cost_amt[全部]) ═══
    // 数据源 product_data_d；基础筛选 mix_msg is NULL（分子分母均加）；分子加 framework="Acceleration"，分母移除 framework
    7,
    VAR __AccCost =
        CALCULATE(
            SUM(a05_e2e_paid_media_product_data_d[cost_amt]),
            REMOVEFILTERS(Dim_Date_Current),
            a05_e2e_paid_media_product_data_d[data_date] >= __TimeMin,
            a05_e2e_paid_media_product_data_d[data_date] <= __TimeMax,
            ISBLANK(a05_e2e_paid_media_product_data_d[mix_msg]),
            a05_e2e_paid_media_product_data_d[framework] = "Acceleration",
            __PlatformFilter_product,
            a05_e2e_paid_media_product_data_d[trans_cycle] = __TransCycle
        )
    VAR __TtlCost =
        CALCULATE(
            SUM(a05_e2e_paid_media_product_data_d[cost_amt]),
            REMOVEFILTERS(Dim_Date_Current),
            a05_e2e_paid_media_product_data_d[data_date] >= __TimeMin,
            a05_e2e_paid_media_product_data_d[data_date] <= __TimeMax,
            ISBLANK(a05_e2e_paid_media_product_data_d[mix_msg]),
            __PlatformFilter_product,
            a05_e2e_paid_media_product_data_d[trans_cycle] = __TransCycle
        )
    RETURN DIVIDE(__AccCost, __TtlCost),

    // ═══ ID 8: Acceleration Net Sales% = SUM(net_sales_amt[Acc]) / SUM(net_sales_amt[全部]) ═══
    // 数据源 product_data_d；无 mix_msg 筛选；分子加 framework="Acceleration"，分母移除 framework
    8,
    VAR __AccNet =
        CALCULATE(
            SUM(a05_e2e_paid_media_product_data_d[net_sales_amt]),
            REMOVEFILTERS(Dim_Date_Current),
            a05_e2e_paid_media_product_data_d[data_date] >= __TimeMin,
            a05_e2e_paid_media_product_data_d[data_date] <= __TimeMax,
            a05_e2e_paid_media_product_data_d[framework] = "Acceleration",
            __PlatformFilter_product,
            a05_e2e_paid_media_product_data_d[trans_cycle] = __TransCycle
        )
    VAR __TtlNet =
        CALCULATE(
            SUM(a05_e2e_paid_media_product_data_d[net_sales_amt]),
            REMOVEFILTERS(Dim_Date_Current),
            a05_e2e_paid_media_product_data_d[data_date] >= __TimeMin,
            a05_e2e_paid_media_product_data_d[data_date] <= __TimeMax,
            __PlatformFilter_product,
            a05_e2e_paid_media_product_data_d[trans_cycle] = __TransCycle
        )
    RETURN DIVIDE(__AccNet, __TtlNet),

    // ═══ ID 9: Media Contribution = 媒体新客数 / 全店新客数 ═══
    // 分子 media_member_cnt：SUMMARIZE(platform, data_year, data_month, media_member_cnt) + SUMX 去重后汇总
    // 分母 全店新客数：a03 直接筛选 data_date ∈ [Min,Max] AND net_pay_amt>0 AND is_member=0 AND lp_12m_net_pay_amt=0，DISTINCTCOUNT user_id
    // a03 与 Dim_Date_Current 无连接，无需 REMOVEFILTERS；user_id 不受 trans_cycle 和 Currency 影响
    9,
    VAR __MediaMember =
        CALCULATE(
            SUMX(
                SUMMARIZE(
                    a05_e2e_paid_media_summary_d,
                    a05_e2e_paid_media_summary_d[platform],
                    a05_e2e_paid_media_summary_d[data_year],
                    a05_e2e_paid_media_summary_d[data_month],
                    a05_e2e_paid_media_summary_d[media_member_cnt]
                ),
                a05_e2e_paid_media_summary_d[media_member_cnt]
            ),
            REMOVEFILTERS(Dim_Date_Current),
            a05_e2e_paid_media_summary_d[data_date] >= __TimeMin,
            a05_e2e_paid_media_summary_d[data_date] <= __TimeMax,
            a05_e2e_paid_media_summary_d[customer_type] = "ALL",
            a05_e2e_paid_media_summary_d[page_type] = "1",
            __PlatformFilter_summary,
            a05_e2e_paid_media_summary_d[trans_cycle] = __TransCycle
        )
    VAR __NewCustomer =
        CALCULATE(
            DISTINCTCOUNT(a03_e2e_customer_data_m[user_id]),
            a03_e2e_customer_data_m[data_date] >= __TimeMin,
            a03_e2e_customer_data_m[data_date] <= __TimeMax,
            a03_e2e_customer_data_m[net_pay_amt] > 0,
            a03_e2e_customer_data_m[is_member] = 0,
            a03_e2e_customer_data_m[lp_12m_net_pay_amt] = 0,
            __PlatformFilter_a03
        )
    RETURN DIVIDE(__MediaMember, __NewCustomer),

    // ═══ ID 10: Cost Per New Acquisition = media_cost_amt / media_member_cnt（SUMMARIZE+SUMX 去重） ═══
    10,
    VAR __MediaCost =
        CALCULATE(
            SUMX(
                SUMMARIZE(
                    a05_e2e_paid_media_summary_d,
                    a05_e2e_paid_media_summary_d[platform],
                    a05_e2e_paid_media_summary_d[data_year],
                    a05_e2e_paid_media_summary_d[data_month],
                    a05_e2e_paid_media_summary_d[media_cost_amt]
                ),
                a05_e2e_paid_media_summary_d[media_cost_amt]
            ),
            REMOVEFILTERS(Dim_Date_Current),
            a05_e2e_paid_media_summary_d[data_date] >= __TimeMin,
            a05_e2e_paid_media_summary_d[data_date] <= __TimeMax,
            a05_e2e_paid_media_summary_d[customer_type] = "ALL",
            a05_e2e_paid_media_summary_d[page_type] = "1",
            __PlatformFilter_summary,
            a05_e2e_paid_media_summary_d[trans_cycle] = __TransCycle
        )
    VAR __MediaMember =
        CALCULATE(
            SUMX(
                SUMMARIZE(
                    a05_e2e_paid_media_summary_d,
                    a05_e2e_paid_media_summary_d[platform],
                    a05_e2e_paid_media_summary_d[data_year],
                    a05_e2e_paid_media_summary_d[data_month],
                    a05_e2e_paid_media_summary_d[media_member_cnt]
                ),
                a05_e2e_paid_media_summary_d[media_member_cnt]
            ),
            REMOVEFILTERS(Dim_Date_Current),
            a05_e2e_paid_media_summary_d[data_date] >= __TimeMin,
            a05_e2e_paid_media_summary_d[data_date] <= __TimeMax,
            a05_e2e_paid_media_summary_d[customer_type] = "ALL",
            a05_e2e_paid_media_summary_d[page_type] = "1",
            __PlatformFilter_summary,
            a05_e2e_paid_media_summary_d[trans_cycle] = __TransCycle
        )
    RETURN DIVIDE(__MediaCost, __MediaMember),

    BLANK()
)
```

---

### 5.3 Target 目标值 — KPIs Overview Target Target Base Value

```dax
KPIs Overview Target Target Base Value =
// Target 行：Metric_ID SWITCH（10 列），数据源 a05_e2e_paid_media_fcst_data_m
// fcst 表与 Dim_Date_Current 无连接，无需 REMOVEFILTERS
// Platform 筛选：fcst 表 platform 已物理算好 ALL，始终单选形式
//   ALL→platform="ALL"；单平台→platform=__ChannelID
// Month 取月度字段，Year 取 year_ 年度字段；统一 SUMMARIZE(platform, 字段) + SUMX 去重
// ACH% 类（ID 2-6）：Target 固定 100%
// 比率类（ID 1, 7-9）：Target = 对应 rate；ID 10：Target = cost_per_new_acquisition

VAR __SelID = SELECTEDVALUE(DIM_ColMetric_Target[Metric_ID])
VAR __ChannelID = SELECTEDVALUE(Slicer_Platform_Selection[Platform_ID], "ALL")
// fcst 表 platform 单选值（ALL→"ALL"；单平台→__ChannelID）
VAR __FcstPlatform = IF(__ChannelID = "ALL", "ALL", __ChannelID)
VAR __TimeFrameID = SELECTEDVALUE(Slicer_Time_Frame[TimeFrame_ID], "Month")
VAR __TimeMin = SELECTEDVALUE(Slicer_Time_Frame[TimeFrame_Min])
VAR __TimeMax = SELECTEDVALUE(Slicer_Time_Frame[TimeFrame_Max])

RETURN
SWITCH(
    __SelID,

    // ═══ ID 1: Cost Rate Target = media_cost_rate(Month) / year_media_cost_rate(Year) ═══
    1,
    IF(__TimeFrameID = "Month",
        CALCULATE(
            SUMX(
                SUMMARIZE(
                    a05_e2e_paid_media_fcst_data_m,
                    a05_e2e_paid_media_fcst_data_m[platform],
                    a05_e2e_paid_media_fcst_data_m[media_cost_rate]
                ),
                a05_e2e_paid_media_fcst_data_m[media_cost_rate]
            ),
            a05_e2e_paid_media_fcst_data_m[platform] = __FcstPlatform,
            a05_e2e_paid_media_fcst_data_m[data_date] >= __TimeMin,
            a05_e2e_paid_media_fcst_data_m[data_date] <= __TimeMax
        ),
        CALCULATE(
            SUMX(
                SUMMARIZE(
                    a05_e2e_paid_media_fcst_data_m,
                    a05_e2e_paid_media_fcst_data_m[platform],
                    a05_e2e_paid_media_fcst_data_m[year_media_cost_rate]
                ),
                a05_e2e_paid_media_fcst_data_m[year_media_cost_rate]
            ),
            a05_e2e_paid_media_fcst_data_m[platform] = __FcstPlatform,
            a05_e2e_paid_media_fcst_data_m[data_date] >= __TimeMin,
            a05_e2e_paid_media_fcst_data_m[data_date] <= __TimeMax
        )
    ),

    // ═══ ID 2-6: ACH% 类 Target 固定 100% ═══
    2, 1.0,
    3, 1.0,
    4, 1.0,
    5, 1.0,
    6, 1.0,

    // ═══ ID 7: Acceleration Cost% Target = acceleration_cost_rate(Month) / year_acceleration_cost_rate(Year) ═══
    7,
    IF(__TimeFrameID = "Month",
        CALCULATE(
            SUMX(
                SUMMARIZE(
                    a05_e2e_paid_media_fcst_data_m,
                    a05_e2e_paid_media_fcst_data_m[platform],
                    a05_e2e_paid_media_fcst_data_m[acceleration_cost_rate]
                ),
                a05_e2e_paid_media_fcst_data_m[acceleration_cost_rate]
            ),
            a05_e2e_paid_media_fcst_data_m[platform] = __FcstPlatform,
            a05_e2e_paid_media_fcst_data_m[data_date] >= __TimeMin,
            a05_e2e_paid_media_fcst_data_m[data_date] <= __TimeMax
        ),
        CALCULATE(
            SUMX(
                SUMMARIZE(
                    a05_e2e_paid_media_fcst_data_m,
                    a05_e2e_paid_media_fcst_data_m[platform],
                    a05_e2e_paid_media_fcst_data_m[year_acceleration_cost_rate]
                ),
                a05_e2e_paid_media_fcst_data_m[year_acceleration_cost_rate]
            ),
            a05_e2e_paid_media_fcst_data_m[platform] = __FcstPlatform,
            a05_e2e_paid_media_fcst_data_m[data_date] >= __TimeMin,
            a05_e2e_paid_media_fcst_data_m[data_date] <= __TimeMax
        )
    ),

    // ═══ ID 8: Acceleration Net Sales% Target = acceleration_net_sales_rate(Month) / year_acceleration_net_sales_rate(Year) ═══
    8,
    IF(__TimeFrameID = "Month",
        CALCULATE(
            SUMX(
                SUMMARIZE(
                    a05_e2e_paid_media_fcst_data_m,
                    a05_e2e_paid_media_fcst_data_m[platform],
                    a05_e2e_paid_media_fcst_data_m[acceleration_net_sales_rate]
                ),
                a05_e2e_paid_media_fcst_data_m[acceleration_net_sales_rate]
            ),
            a05_e2e_paid_media_fcst_data_m[platform] = __FcstPlatform,
            a05_e2e_paid_media_fcst_data_m[data_date] >= __TimeMin,
            a05_e2e_paid_media_fcst_data_m[data_date] <= __TimeMax
        ),
        CALCULATE(
            SUMX(
                SUMMARIZE(
                    a05_e2e_paid_media_fcst_data_m,
                    a05_e2e_paid_media_fcst_data_m[platform],
                    a05_e2e_paid_media_fcst_data_m[year_acceleration_net_sales_rate]
                ),
                a05_e2e_paid_media_fcst_data_m[year_acceleration_net_sales_rate]
            ),
            a05_e2e_paid_media_fcst_data_m[platform] = __FcstPlatform,
            a05_e2e_paid_media_fcst_data_m[data_date] >= __TimeMin,
            a05_e2e_paid_media_fcst_data_m[data_date] <= __TimeMax
        )
    ),

    // ═══ ID 9: Media Contribution Target = media_new_customer_contribution_rate(Month) / year_media_new_customer_contribution_rate(Year) ═══
    9,
    IF(__TimeFrameID = "Month",
        CALCULATE(
            SUMX(
                SUMMARIZE(
                    a05_e2e_paid_media_fcst_data_m,
                    a05_e2e_paid_media_fcst_data_m[platform],
                    a05_e2e_paid_media_fcst_data_m[media_new_customer_contribution_rate]
                ),
                a05_e2e_paid_media_fcst_data_m[media_new_customer_contribution_rate]
            ),
            a05_e2e_paid_media_fcst_data_m[platform] = __FcstPlatform,
            a05_e2e_paid_media_fcst_data_m[data_date] >= __TimeMin,
            a05_e2e_paid_media_fcst_data_m[data_date] <= __TimeMax
        ),
        CALCULATE(
            SUMX(
                SUMMARIZE(
                    a05_e2e_paid_media_fcst_data_m,
                    a05_e2e_paid_media_fcst_data_m[platform],
                    a05_e2e_paid_media_fcst_data_m[year_media_new_customer_contribution_rate]
                ),
                a05_e2e_paid_media_fcst_data_m[year_media_new_customer_contribution_rate]
            ),
            a05_e2e_paid_media_fcst_data_m[platform] = __FcstPlatform,
            a05_e2e_paid_media_fcst_data_m[data_date] >= __TimeMin,
            a05_e2e_paid_media_fcst_data_m[data_date] <= __TimeMax
        )
    ),

    // ═══ ID 10: Cost Per New Acquisition Target = cost_per_new_acquisition(Month) / year_cost_per_new_acquisition(Year) ═══
    10,
    IF(__TimeFrameID = "Month",
        CALCULATE(
            SUMX(
                SUMMARIZE(
                    a05_e2e_paid_media_fcst_data_m,
                    a05_e2e_paid_media_fcst_data_m[platform],
                    a05_e2e_paid_media_fcst_data_m[cost_per_new_acquisition]
                ),
                a05_e2e_paid_media_fcst_data_m[cost_per_new_acquisition]
            ),
            a05_e2e_paid_media_fcst_data_m[platform] = __FcstPlatform,
            a05_e2e_paid_media_fcst_data_m[data_date] >= __TimeMin,
            a05_e2e_paid_media_fcst_data_m[data_date] <= __TimeMax
        ),
        CALCULATE(
            SUMX(
                SUMMARIZE(
                    a05_e2e_paid_media_fcst_data_m,
                    a05_e2e_paid_media_fcst_data_m[platform],
                    a05_e2e_paid_media_fcst_data_m[year_cost_per_new_acquisition]
                ),
                a05_e2e_paid_media_fcst_data_m[year_cost_per_new_acquisition]
            ),
            a05_e2e_paid_media_fcst_data_m[platform] = __FcstPlatform,
            a05_e2e_paid_media_fcst_data_m[data_date] >= __TimeMin,
            a05_e2e_paid_media_fcst_data_m[data_date] <= __TimeMax
        )
    ),

    BLANK()
)
```

---

### 5.4 行路由 — KPIs Overview Target Cell Value

```dax
KPIs Overview Target Cell Value =
// 行路由：Actual/Target 取对应 Base Value；±Actual vs Target 按口径
// 币种：仅金额类（ID 10）Value / Currency_ExchangeRate（除法）；比率类不换算
// ±delta：
//   ID 1-9 = Actual - Target
//   ID 10  = Actual / Target - 1
// Target 缺失/为 0 → ±delta = BLANK；Actual 缺失 → ±delta = BLANK（显示 "-"）

VAR __Indicator = SELECTEDVALUE(DIM_RowKPIs_Overview_Target[Indicator_Type])
VAR __SelID = SELECTEDVALUE(DIM_ColMetric_Target[Metric_ID])
VAR __ExchangeRate = SELECTEDVALUE(Slicer_Currency_Selection[Currency_ExchangeRate], 1)
VAR __IsCurrencyAmt = SELECTEDVALUE(DIM_ColMetric_Target[Metric_IsCurrencyAmount], FALSE)

VAR __ActualValue = [KPIs Overview Target Actual Base Value]
VAR __TargetValue = [KPIs Overview Target Target Base Value]

// 金额类：除以汇率（RMB=1 原值；USD=7 折算）
VAR __ActualConverted = IF(__IsCurrencyAmt, DIVIDE(__ActualValue, __ExchangeRate), __ActualValue)
VAR __TargetConverted = IF(__IsCurrencyAmt, DIVIDE(__TargetValue, __ExchangeRate), __TargetValue)

VAR __ActIsEmpty = ISBLANK(__ActualValue)
VAR __TgtIsEmpty = ISBLANK(__TargetValue) || __TargetValue = 0

// ±delta：用未换算的原始值计算（金额类汇率约分抵消）
VAR __VsDelta =
    IF(__TgtIsEmpty, BLANK(),
        IF(__ActIsEmpty, BLANK(),
            IF(__SelID = 10,
                DIVIDE(__ActualValue, __TargetValue) - 1,   // ID 10: Actual/Target - 1
                __ActualValue - __TargetValue               // ID 1-9: Actual - Target
            )
        )
    )

RETURN
SWITCH(
    TRUE(),
    __Indicator = "Actual",            __ActualConverted,
    __Indicator = "Target",            __TargetConverted,
    __Indicator = "±Actual vs Target", __VsDelta,
    BLANK()
)
```

---

## 6. 格式化显示 — KPIs Overview Target Cell Display

> 参考模板：`RL E2E Customer Dashboard\口径文档\Customer\Cell Display模板文件.md`
> 新增拓展格式类型，便于后续扩展

```dax
KPIs Overview Target Cell Display =
// ========================================
// 度量值: KPIs Overview Target Cell Display
// Display Folder: Formatting
// 用途: 按 Metric_Format 单字段格式化显示
// 依赖: [KPIs Overview Target Cell Value],
//       DIM_ColMetric_Target[Metric_Format],
//       Slicer_Currency_Selection[Currency_Symbol]
// 格式类型（严格遵循口径文档数据类型定义，以 DIM_ColMetric_Target 为准）:
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
//   delta_bp              → 增减基点整数（小数×10000 转 bp）：+120bp / -80bp
//   delta_bp_1dp          → 增减基点一位小数（值本身已是基点）：+120.5bp / -80.0bp
// 说明:
//   - BLANK 显示为 "-"
//   - ±Actual vs Target 行固定 delta_pct_1dp
//   - 货币符号由 Slicer_Currency_Selection[Currency_Symbol] 决定（默认 "¥"）
// ========================================
VAR __Value = [KPIs Overview Target Cell Value]
VAR __Indicator = SELECTEDVALUE(DIM_RowKPIs_Overview_Target[Indicator_Type])
// ±delta 行固定 delta_pct_1dp；其余读 Metric_Format
VAR __Format =
    IF(__Indicator = "±Actual vs Target", "delta_pct_1dp",
        SELECTEDVALUE(DIM_ColMetric_Target[Metric_Format]))
VAR __CurrencySymbol = SELECTEDVALUE(Slicer_Currency_Selection[Currency_Symbol], "¥")

RETURN
IF(
    ISBLANK(__Value), "-",
    SWITCH(
        __Format,

        // ─── 1. 整数与小数 ──────────────────────────────────────────
        "integer",               FORMAT(__Value, "#,##0"),
        "decimal_1dp",           FORMAT(__Value, "#,##0.0"),
        "decimal_2dp",           FORMAT(__Value, "#,##0.00"),

        // ─── 2. 货币格式 ────────────────────────────────────────────
        "currency",              __CurrencySymbol & FORMAT(__Value, "#,##0"),
        "currency_decimal_1dp",  __CurrencySymbol & FORMAT(__Value, "#,##0.0"),
        "currency_k",            __CurrencySymbol & FORMAT(__Value / 1000, "#,##0") & "k",
        "currency_M_K_Int_0db",
            IF(
                __Value < 1000,
                __CurrencySymbol & FORMAT(__Value, "#,##0"),
                IF(
                    __Value < 1000000,
                    __CurrencySymbol & FORMAT(__Value / 1000, "#,##0.0") & "K",
                    __CurrencySymbol & FORMAT(__Value / 1000000, "#,##0.0") & "M"
                )
            ),

        // ─── 3. 百分比格式（纯显示，不含正负号）───────────────────────
        "percent_0dp",           FORMAT(__Value, "#,##0%"),
        "percent_1dp",           FORMAT(__Value, "0.0%"),
        "percent_2dp",           FORMAT(__Value, "0.00%"),

        // ─── 4. 增减百分比（Delta %，自动添加正负号）────────────────
        "delta_pct_0dp",         IF(__Value > 0, "+", "") & FORMAT(__Value, "#,##0%"),
        "delta_pct_1dp",         IF(__Value > 0, "+", "") & FORMAT(__Value, "0.0%"),
        "delta_pct_2dp",         IF(__Value > 0, "+", "") & FORMAT(__Value, "0.00%"),

        // ─── 5. 增减基点 ───────────────────────────────────────────
        "delta_pts",             IF(ROUND(__Value * 100, 0) > 0, "+", "") & FORMAT(__Value * 100, "#,##0pts;-#,##0pts;0pts"),
        "delta_bp",              IF(__Value > 0, "+", "") & FORMAT(__Value * 10000, "#,##0") & "bp",
        "delta_bp_1dp",          IF(__Value > 0, "+", "") & FORMAT(__Value, "#,##0.0") & "bp",

        // ─── 默认 ───────────────────────────────────────────────────
        FORMAT(__Value, "#,##0.00")
    )
)
```

---

## 7. 条件格式 — 字体颜色

```dax
KPIs Overview Target Cell Font Color =
// 仅 ±Actual vs Target 行三色（正绿/负红/零黄）；Actual/Target 行统一 #5f6165
VAR __Value = [KPIs Overview Target Cell Value]
VAR __Indicator = SELECTEDVALUE(DIM_RowKPIs_Overview_Target[Indicator_Type])

RETURN
SWITCH(
    TRUE(),
    ISBLANK(__Value),                                          SELECTEDVALUE(DIM_ColMetric_Target[Metric_ColorDefault], "#5f6165"),
    __Indicator = "±Actual vs Target" && __Value > 0,         SELECTEDVALUE(DIM_ColMetric_Target[Metric_ColorPositive], "#1A9018"),
    __Indicator = "±Actual vs Target" && __Value < 0,         SELECTEDVALUE(DIM_ColMetric_Target[Metric_ColorNegative], "#D64550"),
    __Indicator = "±Actual vs Target" && __Value = 0,         SELECTEDVALUE(DIM_ColMetric_Target[Metric_ColorZero], "#E1C233"),
    SELECTEDVALUE(DIM_ColMetric_Target[Metric_ColorDefault], "#5f6165")
)
```

---

## 8. 条件格式 — SVG 图标

```dax
KPIs Overview Target Cell SVG Icon = 
// ========================================
// 度量值: KPIs Overview Target Cell SVG Icon
// Display Folder: KPIs Overview Target > Formatting
// 用途: 为 ±Actual vs Target 行返回增减方向箭头 SVG 图标
//       仅 ±Actual vs Target 行显示，Actual / Target 行返回 BLANK
// 依赖: [KPIs Overview Target Cell Value],
//       DIM_RowKPIs_Overview_Target[Indicator_Type]
// 配置: 需将此度量值的数据类别设为"图像 URL"（Data Category = Image URL）
// ========================================
    VAR __Value = [KPIs Overview Target Cell Value]
    VAR __Indicator = SELECTEDVALUE(DIM_RowKPIs_Overview_Target[Indicator_Type])

    // ── SVG 图标定义 ──
    VAR __GreenArrowUp =
            "data:image/svg+xml;utf8," &
"<svg xmlns='http://www.w3.org/2000/svg' width='16' height='16'>" &
"<circle cx='8' cy='8' r='7' fill='%231A9018'/>" &
"<path d='M8 12 L8 5 M5 7 L8 4 L11 7' stroke='white' stroke-width='1.8' stroke-linecap='round' stroke-linejoin='round' fill='none'/>" &
"</svg>"
        // "data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' width='12' height='12' viewBox='0 0 12 12'><path fill='%231A9018' d='M6 2L10 8H2z'/></svg>"
    VAR __RedArrowDown =
        "data:image/svg+xml;utf8," &
"<svg xmlns='http://www.w3.org/2000/svg' width='16' height='16'>" &
"<circle cx='8' cy='8' r='7' fill='%23D64550'/>" &
"<path d='M8 4 L8 11 M5 9 L8 12 L11 9' stroke='white' stroke-width='1.8' stroke-linecap='round' stroke-linejoin='round' fill='none'/>" &
"</svg>"
        // "data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' width='12' height='12' viewBox='0 0 12 12'><path fill='%23D64550' d='M6 10L2 4h8z'/></svg>"
    VAR __YellowDash =
        "data:image/svg+xml;utf8," &
"<svg xmlns='http://www.w3.org/2000/svg' width='16' height='16'>" &
"<circle cx='8' cy='8' r='7' fill='%23E1C233'/>" &
"<path d='M4.5 8 L11.5 8' stroke='white' stroke-width='1.8' stroke-linecap='round' stroke-linejoin='round' fill='none'/>" &
"</svg>"
        // "data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' width='12' height='12' viewBox='0 0 12 12'><line x1='2' y1='6' x2='10' y2='6' stroke='%23E1C233' stroke-width='2'/></svg>"

    RETURN
        SWITCH(
            TRUE(),
            __Indicator <> "±Actual vs Target",   BLANK(),   // 仅 ±delta 行显示图标
            ISBLANK(__Value),                      BLANK(),   // 空值不显示
            __Value > 0,                           __GreenArrowUp,
            __Value < 0,                           __RedArrowDown,
            __Value = 0,                           __YellowDash,
            BLANK()
        )
```

---

## 9. 条件格式 — 交替行背景色

```dax
KPIs Overview Target Cell Background Color = 
// ========================================
// 度量值: KPIs Overview Target Cell Background Color
// Display Folder: KPIs Overview Target > Formatting
// 用途: 根据行 Indicator_Order 返回交替行背景色
//       Indicator_Order 采用起始10步长10规范（10, 20, 30）
//       先除以10还原行位次（10→1, 20→2, 30→3），再取 MOD 判断奇偶
//       奇数位次（Actual=10→1, ±Actual vs Target=30→3）→ 白色 #FFFFFF
//       偶数位次（Target=20→2）→ 浅灰色 #F5F5F5
//       仅 3 行，颜色交替规律：白 → 灰 → 白
// 依赖: DIM_RowKPIs_Overview_Target[Indicator_Order]
// ========================================
    VAR __RowID = SELECTEDVALUE(DIM_RowKPIs_Overview_Target[Indicator_Order])
    VAR __EffRowID =
        IF(NOT ISBLANK(__RowID), __RowID, SUM(DIM_RowKPIs_Overview_Target[Indicator_Order]))
    VAR __RowPos = INT(__EffRowID / 10)    // 还原行位次：10→1, 20→2, 30→3
    RETURN
        IF(
            MOD(__RowPos, 2) = 0,
            "#F5F5F5",                     // 偶数位次（Target 行）：浅灰色
            "#FFFFFF"                      // 奇数位次（Actual / ±delta 行）：白色
        )
```

---

## 10. 视觉对象配置

### 10.1 矩阵（Matrix）

| 属性 | 值 |
|------|-----|
| 行 | `DIM_RowKPIs_Overview_Target[Indicator_Type]` |
| 列 | `DIM_ColMetric_Target[Metric_Name]` |
| 值 | `[KPIs Overview Target Cell Display]` |

### 10.2 条件格式

| 格式类型 | 基于字段 | 说明 |
|---------|----------|------|
| 字体颜色 | `[KPIs Overview Target Cell Font Color]` | ±delta 行三色，其他 #5f6165 |
| 背景颜色 | `[KPIs Overview Target Cell Background Color]` | 交替行（白/灰/白） |
| 图标 | `[KPIs Overview Target Cell SVG Icon]` | ±delta 行箭头，数据类别 = 图像 URL |

### 10.3 切片器

| 切片器 | 类型 | 字段 | 默认值 |
|--------|------|------|--------|
| 时间粒度/区间 | 单选 | `Slicer_Time_Frame[TimeFrame_Value]` | 当前财月 |
| Platform | 单选 | `Slicer_Platform_Selection[Platform_Label]` | ALL |
| 数据口径 | 单选 | `Slicer_DataCaliber_Selection[DataCaliber_Label]` | T+1 |
| 币种 | 单选 | `Slicer_Currency_Selection[Currency_Label]` | RMB |

---

## 11. 度量值清单与 Display Folder

| # | 度量值名称 | Display Folder | 返回类型 |
|---|-----------|----------------|----------|
| 1 | KPIs Overview Target Actual Base Value | KPIs Overview Target | 数值 |
| 2 | KPIs Overview Target Target Base Value | KPIs Overview Target | 数值 |
| 3 | KPIs Overview Target Cell Value | KPIs Overview Target | 数值 |
| 4 | KPIs Overview Target Cell Display | KPIs Overview Target › Formatting | 文本 |
| 5 | KPIs Overview Target Cell Font Color | KPIs Overview Target › Formatting | 颜色代码 |
| 6 | KPIs Overview Target Cell SVG Icon | KPIs Overview Target › Formatting | 图像 URL |
| 7 | KPIs Overview Target Cell Background Color | KPIs Overview Target › Formatting | 颜色代码 |

```
_Measures
└─ KPIs Overview Target/
    ├── KPIs Overview Target Actual Base Value
    ├── KPIs Overview Target Target Base Value
    ├── KPIs Overview Target Cell Value
    └── Formatting/
        ├── KPIs Overview Target Cell Display
        ├── KPIs Overview Target Cell Font Color
        ├── KPIs Overview Target Cell SVG Icon
        └── KPIs Overview Target Cell Background Color
```

### 新建/重建对象清单

| 类型 | 名称 | 说明 |
|------|------|------|
| 计算表 | `DIM_RowKPIs_Overview_Target` | 沿用；Actual/Target/±Actual vs Target |
| 计算表 | `DIM_ColMetric_Target` | 重建；ACH% 类统一 percent_1dp，仅 ID 10 金额类 |
| 度量值 | `KPIs Overview Target Actual Base Value` | 重写；日期 = Slicer_Time_Frame，ACH% 分母走 fcst(MAX)，ID9 分母走 a03 DISTINCTCOUNT |
| 度量值 | `KPIs Overview Target Target Base Value` | 重写；fcst 表，SUMMARIZE 去重，ACH% 类固定 100% |
| 度量值 | `KPIs Overview Target Cell Value` | 重写；±delta ID 1-9 = Actual-Target，ID 10 = Actual/Target-1；金额类 ÷ 汇率 |
| 度量值 | Cell Display / Font Color / SVG Icon / Background Color | 沿用，Cell Display 新增拓展格式类型 |

---

## 12. 关键实现说明与边界

### A. 日期处理

| 表 | 与 Dim_Date_Current 关系 | 处理方式 |
|----|--------------------------|----------|
| `a05_e2e_paid_media_summary_d` | ✅ 已连接 | `REMOVEFILTERS(Dim_Date_Current)` + 重施加 `data_date ∈ [Min, Max]` |
| `a05_e2e_paid_media_product_data_d` | ✅ 已连接 | `REMOVEFILTERS(Dim_Date_Current)` + 重施加 `data_date ∈ [Min, Max]` |
| `a05_e2e_paid_media_fcst_data_m` | ❌ 断开 | 直接筛选 `data_date ∈ [Min, Max]`（无需 REMOVEFILTERS） |
| `a03_e2e_customer_data_m` | ❌ 断开 | 直接筛选 `data_date ∈ [Min, Max]`（无需 REMOVEFILTERS） |

- `Slicer_Time_Frame` 单选，`TimeFrame_Min/Max` 即所选财月/财年的完整自然日区间
- 各表 `data_date` 列需为 Date 类型（与 `TimeFrame_Min/Max` 比较）

### B. Platform 处理

| 表 | ALL | 单平台 | 写法 |
|----|-----|--------|------|
| Actual 表（summary_d / product_data_d / a03） | `IN{"TM","JD"}` | `=__ChannelID` | `FILTER(ALL(<表>[platform]), IF(__ChannelID="ALL", [platform] IN {"TM","JD"}, [platform]=__ChannelID))` |
| Target 表（fcst_data_m） | `="ALL"` | `=__ChannelID` | `[platform] = IF(__ChannelID="ALL", "ALL", __ChannelID)` |

- 仅 `a05_e2e_paid_media_fcst_data_m` 在物理层面计算好了 `platform IN {"ALL"}`，始终单选形式
- Actual 表用 `FILTER(ALL(<表>[platform]), ...)` 写法，每个事实表单独声明一个 `__PlatformFilter_<表>` 变量
- 原因：嵌套 IF 返回表时 DAX 引擎会把表达式降级为标量，导致 `IN __PlatFilterActual` 报错

### C. Target SUMMARIZE 去重

- **Month**：单行，`SUMMARIZE(platform, 月度字段)` + `SUMX` = 该月值
- **Year**：同财年 12 行重复年度值，`SUMMARIZE(platform, year_字段)` + `SUMX` 去重 = 该年度值（等价 MAX）
- **ACH% 分母**（Actual 内）：按口径用 `MAX`（Month 取月度字段 MAX，Year 取 year_ 字段 MAX）

### D. ID 9 新客判定（简化直接筛选）

- **分母**：`a03_e2e_customer_data_m` 直接筛选 `data_date ∈ [TimeFrame_Min, TimeFrame_Max] AND net_pay_amt > 0 AND is_member = 0 AND lp_12m_net_pay_amt = 0`，`DISTINCTCOUNT(user_id)`
- `a03` 与 `Dim_Date_Current` 无连接，无需 `REMOVEFILTERS`
- `user_id` 不受 `trans_cycle` 和 `Currency` 影响
- 受 Platform 筛选：ALL→`IN{"TM","JD"}`；单平台→`=__ChannelID`
- **分子**：`media_member_cnt` 用 `SUMMARIZE(platform, data_year, data_month, media_member_cnt)` + `SUMX` 去重后汇总

### E. ID 10 分子去重与边界

- `media_cost_amt` / `media_member_cnt` 均采用 `SUMMARIZE(platform, data_year, data_month, 字段)` + `SUMX` 去重后汇总
- Target 缺失/为 0 → Target 及 ±delta 展示 "-"
- 汇总后 `media_member_cnt` = 0 → Actual 及 ±delta 展示 "-"
- ±delta = Actual / Target - 1（区别于 ID 1-9 的 Actual - Target）

### F. 币种换算

- 仅 ID 10（金额类）在 Cell Value 层 `Value / Currency_ExchangeRate`（除法）
- 比率类指标汇率约分抵消，不换算
- ±delta 用原始值计算（金额类汇率约分）

### G. DAX 语法规范

- 文本常量必须使用双引号 `" "`，禁止使用单引号
- 单引号 `' '` 仅用于表名
- 列名使用方括号 `[ ]`
- 示例：`[framework] = "Acceleration"`
