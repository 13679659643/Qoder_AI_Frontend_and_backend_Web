# Class x Label Drilldown 解决方案

> **版本**: v1.0
> **模块**: Customer Dashboard - Customer Tab - Class x Label Drilldown
> **关联口径**: 口径文档/Customer/Class x Label Drilldown.md
> **数据底表**: `t05_customer_order_data_d`（行级订单，日期字段 `dt`）、`a03_e2e_customer_data_m`（汇总维度，日期字段 `data_date`，用于 New/Existing user_id 判定）
> **关联维度**: `Slicer_Time_Frame`、`Slicer_Time_Frame_Min`、`Slicer_Time_Frame_Max`、`Slicer_Currency_Selection`
> **用途**: 用于条形图和表格（非矩阵），每个指标独立拉取，无 x 轴，无需处理 x 轴当前时间
> **行维度**: `category_summary` / `product_id` 直接拉取 `t05_customer_order_data_d` 字段，表关系自动传递，DAX 无需显式处理分组

---

## 1. 需求理解

### 1.1 模块定位

Class x Label Drilldown 是 Customer Tab 的品类下钻模块，共 **14 个指标**，每个指标独立输出 **Value 度量 + Display 度量**，共 28 个度量值。分为两个子模块：

- **子模块八：Class x Label**（按 `category_summary` 分组，8 个指标）
- **子模块九：Product**（按 `product_id` 分组，6 个指标）

### 1.2 全局规则

| 项目 | 说明 |
| --- | --- |
| **不受 Slicer_Customer_Type_Selection 影响** | 每个度量值直接硬编码对应分支（New/Existing/All），不通过切片器切换 |
| **不受 Net/Demand 按钮影响** | 统一使用 `net_pay_amt` 等 Net 系列字段，不读 `Dim_RowMetric_Customer_Net_Demand` |
| **行维度直接拉事实表字段** | `category_summary` / `product_id` 从 `t05_customer_order_data_d` 直接拉取，表关系自动传递 |
| **时间口径** | `t05` 用 `dt ∈ [TimeFrame_Min, TimeFrame_Max]`；`a03`（New/Existing 判定）用 `data_date ∈ [First_Fiscal_Month_Min, First_Fiscal_Month_Max]` |
| **New/Existing 判定** | Step1：`a03` 在 start_period 内筛选 `lp_12m_net_pay_amt = 0`（New）/ `> 0`（Existing）的 user_id 集合；Step2：在 `t05` 的 slicer 区间内对该集合聚合 |
| **分母不受产品筛选器影响** | 百分比指标的分母用 `ALLSELECTED('t05_customer_order_data_d'[category_summary])` 移除图表维度影响，保留外部切片器筛选 |
| **货币转换** | 金额类 Value 度量保留 RMB 原值，Display 层按 `Currency_ExchangeRate` 换算（RMB÷汇率） |
| **is_member 筛选** | 仅 `a03`（New/Existing 判定）使用 `is_member = 0`；`t05` 聚合不筛选 `is_member` |

### 1.3 14 个指标清单

| #  | 指标名称 | 子模块 | 分组维度 | 分支 | 类型 | 数据格式 |
| -- | -------- | ------ | -------- | ---- | ---- | -------- |
| 1  | Net_Customer No. | Class x Label | category_summary | All | integer | #,##0 |
| 2  | Net_SLS | Class x Label | category_summary | All | currency | #,##0 |
| 3  | New Customer%（按人数） | Class x Label | category_summary | New/TTL | percent_0dp | #,##0% |
| 4  | TTL Customer%（按人数） | Class x Label | category_summary | TTL | percent_0dp | #,##0% |
| 5  | ±%（按人数） | Class x Label | category_summary | Delta | delta_pts | +#,##0pts;-#,##0pts;0pts |
| 6  | New Customer%（按金额） | Class x Label | category_summary | New/TTL | percent_0dp | #,##0% |
| 7  | TTL Customer%（按金额） | Class x Label | category_summary | TTL | percent_0dp | #,##0% |
| 8  | ±%（按金额） | Class x Label | category_summary | Delta | delta_pts | +#,##0pts;-#,##0pts;0pts |
| 9  | Net_New_Customer No. | Product | product_id | New | integer | #,##0 |
| 10 | Net_New_SLS | Product | product_id | New | currency | #,##0 |
| 11 | Net_TTL_Customer No. | Product | product_id | All | integer | #,##0 |
| 12 | TTL_SLS | Product | product_id | All | currency | #,##0 |
| 13 | Net_Existing_Customer No. | Product | product_id | Existing | integer | #,##0 |
| 14 | Net_Existing_SLS | Product | product_id | Existing | currency | #,##0 |

### 1.4 分支口径

- **All（TTL）**：`t05` 在 `dt ∈ [TimeFrame_Min, TimeFrame_Max]` 内直接聚合，不限定 user_id 集合
- **New**：Step1 在 `a03` start_period 内筛选 `net_pay_amt > 0 AND is_member = 0 AND lp_12m_net_pay_amt = 0` 的 user_id 集合；Step2 在 `t05` slicer 区间内对该集合 `TREATAS` 后聚合
- **Existing**：同 New，但 `lp_12m_net_pay_amt > 0`
- **百分比分母**：`t05` slicer 区间聚合，`ALLSELECTED(category_summary)` 移除图表维度，保留外部筛选
- **Delta**：New Customer% - TTL Customer%，值 × 100 转 pts

---

## 2. 现状分析

### 2.1 数据底表

| 表名 | 日期字段 | 用途 | 关键字段 |
| --- | --- | --- | --- |
| `t05_customer_order_data_d` | `dt` | 行级订单聚合 | `user_id`, `net_pay_amt`, `category_summary`, `product_id` |
| `a03_e2e_customer_data_m` | `data_date` | New/Existing user_id 判定 | `user_id`, `is_member`, `net_pay_amt`, `lp_12m_net_pay_amt` |

> `a03_e2e_customer_data_m` 是汇总维度，**没有** `category_summary` 和 `product_id` 字段，不能直接按这两个维度分组。New/Existing 判定先在 `a03` 得到 user_id 集合，再到 `t05` 按维度聚合。

### 2.2 关键说明

- `category_summary` 和 `product_id` 是 `t05_customer_order_data_d` 的字段，直接拉取实现自动分组与筛选
- `t05` 无 `is_member` 字段，故 `t05` 聚合不筛选 `is_member`；`is_member = 0` 仅在 `a03` 的 New/Existing 判定中使用
- 口径文档中分母提到的 `data_date` 为笔误，实际为 `dt`（表为 `t05_customer_order_data_d`）

---

## 3. 方案设计

### 3.1 度量值分层

```
Value 度量（14 个）  ←  直接计算指标值，金额类保留 RMB 原值
    ↓
Display 度量（14 个） ←  按数据格式格式化 + 金额类汇率换算 + 币种符号拼接
```

### 3.2 通用 VAR 模式

```dax
// 时间区间变量（每个 Value 度量内部复用）
VAR __PeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Min[TimeFrame_Min])
VAR __PeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max[TimeFrame_Max])
VAR __StartPeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Min[First_Fiscal_Month_Min])
VAR __StartPeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Min[First_Fiscal_Month_Max])
```

### 3.3 数据格式规范

| 数据格式 | 格式串 | 示例 | 适用指标 |
| --- | --- | --- | --- |
| `integer` | `FORMAT(__Value, "#,##0")` | 1,234 | Net_Customer No. / Net_New_Customer No. / Net_TTL_Customer No. / Net_Existing_Customer No. |
| `currency` | `__CurrencySymbol & FORMAT(__ValueInCurrency, "#,##0")` | ¥1,000 / $143 | Net_SLS / Net_New_SLS / TTL_SLS / Net_Existing_SLS |
| `percent_0dp` | `FORMAT(__Value, "#,##0%")` | 30% / -5% | New Customer% / TTL Customer%（按人数/按金额） |
| `delta_pts` | `FORMAT(__Value * 100, "+#,##0pts;-#,##0pts;0pts")` | +120pts / -80pts | ±%（按人数/按金额） |

### 3.4 汇率换算规则

- 数据底表存储 RMB 原始值
- `Slicer_Currency_Selection` 提供 `Currency_ExchangeRate`（RMB=1, USD=7）和 `Currency_Symbol`（¥ / $）
- **换算时机**：在 Display 层对金额类指标换算 `RMB ÷ Currency_ExchangeRate`
- 百分比 / delta_pts 为无量纲比率，不涉及汇率换算

---

## 4. 度量值实现

### 4.1 Net_Customer No.（指标 1 — All 分支，按人数）

#### 4.1.1 Net_Customer No. Value

```dax
Net_Customer No. Value =
// ========================================
// 度量值: Net_Customer No. Value
// 用途: 按 category_summary 分组的净购买买家人数
// 分支: All → count(distinct user_id) where net_pay_amt > 0, dt ∈ slicer 区间
// 数据底表: t05_customer_order_data_d
// 数据格式: integer（Display 层处理）
// 行维度: category_summary 直接拉取 t05 字段，自动分组
// ========================================
VAR __PeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Min[TimeFrame_Min])
VAR __PeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max[TimeFrame_Max])

RETURN
    CALCULATE(
        DISTINCTCOUNT('t05_customer_order_data_d'[user_id]),
        't05_customer_order_data_d'[net_pay_amt] > 0,
        't05_customer_order_data_d'[dt] >= __PeriodMin,
        't05_customer_order_data_d'[dt] <= __PeriodMax
    )
```

#### 4.1.2 Net_Customer No. Display

```dax
Net_Customer No. Display =
// ========================================
// 度量值: Net_Customer No. Display
// 用途: 按 integer 格式化（整数千分位）
// ========================================
VAR __Value = [Net_Customer No. Value]
RETURN
    IF(
        ISBLANK(__Value),
        "-",
        FORMAT(__Value, "#,##0")
    )
```

### 4.2 Net_SLS（指标 2 — All 分支，按金额）

#### 4.2.1 Net_SLS Value

```dax
Net_SLS Value =
// ========================================
// 度量值: Net_SLS Value
// 用途: 按 category_summary 分组的净销售额
// 分支: All → sum(net_pay_amt), dt ∈ slicer 区间
// 数据底表: t05_customer_order_data_d
// 数据格式: currency（Display 层处理汇率换算）
// 汇率换算: 不在此度量值处理，由 Display 层处理
// ========================================
VAR __PeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Min[TimeFrame_Min])
VAR __PeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max[TimeFrame_Max])

RETURN
    CALCULATE(
        SUM('t05_customer_order_data_d'[net_pay_amt]),
        't05_customer_order_data_d'[dt] >= __PeriodMin,
        't05_customer_order_data_d'[dt] <= __PeriodMax
    )
```

#### 4.2.2 Net_SLS Display

```dax
Net_SLS Display =
// ========================================
// 度量值: Net_SLS Display
// 用途: 按 currency 格式化（货币符号 + 整数千分位）
// 汇率换算: Value 度量保留 RMB 原值，Display 层按 Currency_ExchangeRate 换算
//           RMB: ExchangeRate=1（原值）；USD: ExchangeRate=7（RMB÷7=USD）
// ========================================
VAR __Value = [Net_SLS Value]
VAR __ExchangeRate = SELECTEDVALUE(Slicer_Currency_Selection[Currency_ExchangeRate], 1)
VAR __CurrencySymbol = SELECTEDVALUE(Slicer_Currency_Selection[Currency_Symbol], "¥")
VAR __ValueInCurrency = DIVIDE(__Value, __ExchangeRate)

RETURN
    IF(
        ISBLANK(__Value),
        "-",
        __CurrencySymbol & FORMAT(__ValueInCurrency, "#,##0")
    )
```

### 4.3 New Customer%（按人数）（指标 3 — New 分子 / TTL 分母）

#### 4.3.1 New Customer% by No. Value

```dax
New Customer% by No. Value =
// ========================================
// 度量值: New Customer% by No. Value
// 用途: 新客买家人数占全客买家人数的比例
// 分子: Step1 a03 start_period 内 lp_12m_net_pay_amt=0 的 user_id 集合
//       Step2 t05 dt ∈ slicer 区间内对该集合 count(distinct user_id), by category_summary
// 分母: t05 dt ∈ slicer 区间 count(distinct user_id) where net_pay_amt > 0
//       ALLSELECTED(category_summary) 移除图表维度，保留外部筛选
// 数据格式: percent_0dp（Display 层处理）
// ========================================
VAR __PeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Min[TimeFrame_Min])
VAR __PeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max[TimeFrame_Max])
VAR __StartPeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Min[First_Fiscal_Month_Min])
VAR __StartPeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Min[First_Fiscal_Month_Max])

// ── Step1: New 客户 user_id 集合（a03 start_period 内判定）──
VAR __NewUserIDs =
    CALCULATETABLE(
        VALUES('a03_e2e_customer_data_m'[user_id]),
        'a03_e2e_customer_data_m'[is_member] = 0,
        'a03_e2e_customer_data_m'[net_pay_amt] > 0,
        'a03_e2e_customer_data_m'[lp_12m_net_pay_amt] = 0,
        'a03_e2e_customer_data_m'[data_date] >= __StartPeriodMin,
        'a03_e2e_customer_data_m'[data_date] <= __StartPeriodMax
    )

// ── Step2 分子: t05 slicer 区间内对 New 集合 count(distinct user_id) ──
VAR __Numerator =
    CALCULATE(
        DISTINCTCOUNT('t05_customer_order_data_d'[user_id]),
        TREATAS(__NewUserIDs, 't05_customer_order_data_d'[user_id]),
        't05_customer_order_data_d'[dt] >= __PeriodMin,
        't05_customer_order_data_d'[dt] <= __PeriodMax
    )

// ── 分母: 全客买家人数，ALLSELECTED 移除图表 category_summary 维度 ──
VAR __Denominator =
    CALCULATE(
        [Net_Customer No. Value],
        ALLSELECTED('t05_customer_order_data_d'[category_summary])
    )

RETURN
    DIVIDE(__Numerator, __Denominator)
```

#### 4.3.2 New Customer% by No. Display

```dax
New Customer% by No. Display =
// ========================================
// 度量值: New Customer% by No. Display
// 用途: 按 percent_0dp 格式化（百分比整数，不含正号）
// ========================================
VAR __Value = [New Customer% by No. Value]
RETURN
    IF(
        ISBLANK(__Value),
        "-",
        FORMAT(__Value, "#,##0%")
    )
```

### 4.4 TTL Customer%（按人数）（指标 4 — TTL 分子 / TTL 分母）

#### 4.4.1 TTL Customer% by No. Value

```dax
TTL Customer% by No. Value =
// ========================================
// 度量值: TTL Customer% by No. Value
// 用途: 各筛选条件下全客买家人数占无产品筛选全客的比例
// 分子: [Net_Customer No. Value]（by category_summary，受图表维度影响）
// 分母: [Net_Customer No. Value] ALLSELECTED(category_summary)（移除图表维度，保留外部筛选）
// 数据格式: percent_0dp（Display 层处理）
// ========================================
VAR __Numerator = [Net_Customer No. Value]
VAR __Denominator =
    CALCULATE(
        [Net_Customer No. Value],
        ALLSELECTED('t05_customer_order_data_d'[category_summary])
    )

RETURN
    DIVIDE(__Numerator, __Denominator)
```

#### 4.4.2 TTL Customer% by No. Display

```dax
TTL Customer% by No. Display =
VAR __Value = [TTL Customer% by No. Value]
RETURN
    IF(
        ISBLANK(__Value),
        "-",
        FORMAT(__Value, "#,##0%")
    )
```

### 4.5 ±%（按人数）（指标 5 — Delta）

#### 4.5.1 ±% by No. Value

```dax
±% by No. Value =
// ========================================
// 度量值: ±% by No. Value
// 用途: 新客占比 - 全客占比（按人数）
// 计算: [New Customer% by No. Value] - [TTL Customer% by No. Value]
// 数据格式: delta_pts（Display 层 × 100 转 pts）
// ========================================
VAR __NewPct = [New Customer% by No. Value]
VAR __TTLPct = [TTL Customer% by No. Value]

RETURN
    IF(
        ISBLANK(__NewPct) || ISBLANK(__TTLPct),
        BLANK(),
        __NewPct - __TTLPct
    )
```

#### 4.5.2 ±% by No. Display

```dax
±% by No. Display =
// ========================================
// 度量值: ±% by No. Display
// 用途: 按 delta_pts 格式化（基点，含正负号，值×100 转 pts）
// 格式: +120pts / -80pts / 0pts
// ========================================
VAR __Value = [±% by No. Value]
RETURN
    IF(
        ISBLANK(__Value),
        "-",
        FORMAT(__Value * 100, "+#,##0pts;-#,##0pts;0pts")
    )
```

### 4.6 New Customer%（按金额）（指标 6 — New 分子 / TTL 分母）

#### 4.6.1 New Customer% by Amt Value

```dax
New Customer% by Amt Value =
// ========================================
// 度量值: New Customer% by Amt Value
// 用途: 新客净销售额占全客净销售额的比例
// 分子: Step1 a03 start_period 内 lp_12m_net_pay_amt=0 的 user_id 集合
//       Step2 t05 dt ∈ slicer 区间内对该集合 sum(net_pay_amt), by category_summary
// 分母: t05 dt ∈ slicer 区间 sum(net_pay_amt)
//       ALLSELECTED(category_summary) 移除图表维度，保留外部筛选
// 数据格式: percent_0dp（Display 层处理）
// 汇率换算: 不涉及（比率为无量纲，RMB/USD 同值）
// ========================================
VAR __PeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Min[TimeFrame_Min])
VAR __PeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max[TimeFrame_Max])
VAR __StartPeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Min[First_Fiscal_Month_Min])
VAR __StartPeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Min[First_Fiscal_Month_Max])

// ── Step1: New 客户 user_id 集合 ──
VAR __NewUserIDs =
    CALCULATETABLE(
        VALUES('a03_e2e_customer_data_m'[user_id]),
        'a03_e2e_customer_data_m'[is_member] = 0,
        'a03_e2e_customer_data_m'[net_pay_amt] > 0,
        'a03_e2e_customer_data_m'[lp_12m_net_pay_amt] = 0,
        'a03_e2e_customer_data_m'[data_date] >= __StartPeriodMin,
        'a03_e2e_customer_data_m'[data_date] <= __StartPeriodMax
    )

// ── Step2 分子: t05 slicer 区间内对 New 集合 sum(net_pay_amt) ──
VAR __Numerator =
    CALCULATE(
        SUM('t05_customer_order_data_d'[net_pay_amt]),
        TREATAS(__NewUserIDs, 't05_customer_order_data_d'[user_id]),
        't05_customer_order_data_d'[dt] >= __PeriodMin,
        't05_customer_order_data_d'[dt] <= __PeriodMax
    )

// ── 分母: 全客净销售额，ALLSELECTED 移除图表 category_summary 维度 ──
VAR __Denominator =
    CALCULATE(
        [Net_SLS Value],
        ALLSELECTED('t05_customer_order_data_d'[category_summary])
    )

RETURN
    DIVIDE(__Numerator, __Denominator)
```

#### 4.6.2 New Customer% by Amt Display

```dax
New Customer% by Amt Display =
VAR __Value = [New Customer% by Amt Value]
RETURN
    IF(
        ISBLANK(__Value),
        "-",
        FORMAT(__Value, "#,##0%")
    )
```

### 4.7 TTL Customer%（按金额）（指标 7 — TTL 分子 / TTL 分母）

#### 4.7.1 TTL Customer% by Amt Value

```dax
TTL Customer% by Amt Value =
// ========================================
// 度量值: TTL Customer% by Amt Value
// 用途: 各筛选条件下全客净销售额占无产品筛选全客的比例
// 分子: [Net_SLS Value]（by category_summary，受图表维度影响）
// 分母: [Net_SLS Value] ALLSELECTED(category_summary)（移除图表维度，保留外部筛选）
// 数据格式: percent_0dp（Display 层处理）
// ========================================
VAR __Numerator = [Net_SLS Value]
VAR __Denominator =
    CALCULATE(
        [Net_SLS Value],
        ALLSELECTED('t05_customer_order_data_d'[category_summary])
    )

RETURN
    DIVIDE(__Numerator, __Denominator)
```

#### 4.7.2 TTL Customer% by Amt Display

```dax
TTL Customer% by Amt Display =
VAR __Value = [TTL Customer% by Amt Value]
RETURN
    IF(
        ISBLANK(__Value),
        "-",
        FORMAT(__Value, "#,##0%")
    )
```

### 4.8 ±%（按金额）（指标 8 — Delta）

#### 4.8.1 ±% by Amt Value

```dax
±% by Amt Value =
// ========================================
// 度量值: ±% by Amt Value
// 用途: 新客占比 - 全客占比（按金额）
// 计算: [New Customer% by Amt Value] - [TTL Customer% by Amt Value]
// 数据格式: delta_pts（Display 层 × 100 转 pts）
// ========================================
VAR __NewPct = [New Customer% by Amt Value]
VAR __TTLPct = [TTL Customer% by Amt Value]

RETURN
    IF(
        ISBLANK(__NewPct) || ISBLANK(__TTLPct),
        BLANK(),
        __NewPct - __TTLPct
    )
```

#### 4.8.2 ±% by Amt Display

```dax
±% by Amt Display =
VAR __Value = [±% by Amt Value]
RETURN
    IF(
        ISBLANK(__Value),
        "-",
        FORMAT(__Value * 100, "+#,##0pts;-#,##0pts;0pts")
    )
```

---

### 4.9 Net_New_Customer No.（指标 9 — New 分支，按 product_id，按人数）

#### 4.9.1 Net_New_Customer No. Value

```dax
Net_New_Customer No. Value =
// ========================================
// 度量值: Net_New_Customer No. Value
// 用途: 新客在所选时间范围内各 product_id 下的买家人数
// 分支: New → Step1 a03 start_period 内 lp_12m_net_pay_amt=0 的 user_id 集合
//       Step2 t05 dt ∈ slicer 区间内对该集合 count(distinct user_id), by product_id
// 数据底表: a03_e2e_customer_data_m（Step1）、t05_customer_order_data_d（Step2）
// 数据格式: integer（Display 层处理）
// 行维度: product_id 直接拉取 t05 字段，自动分组
// ========================================
VAR __PeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Min[TimeFrame_Min])
VAR __PeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max[TimeFrame_Max])
VAR __StartPeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Min[First_Fiscal_Month_Min])
VAR __StartPeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Min[First_Fiscal_Month_Max])

// ── Step1: New 客户 user_id 集合（a03 start_period 内判定）──
VAR __NewUserIDs =
    CALCULATETABLE(
        VALUES('a03_e2e_customer_data_m'[user_id]),
        'a03_e2e_customer_data_m'[is_member] = 0,
        'a03_e2e_customer_data_m'[net_pay_amt] > 0,
        'a03_e2e_customer_data_m'[lp_12m_net_pay_amt] = 0,
        'a03_e2e_customer_data_m'[data_date] >= __StartPeriodMin,
        'a03_e2e_customer_data_m'[data_date] <= __StartPeriodMax
    )

// ── Step2: t05 slicer 区间内对 New 集合 count(distinct user_id) ──
RETURN
    CALCULATE(
        DISTINCTCOUNT('t05_customer_order_data_d'[user_id]),
        TREATAS(__NewUserIDs, 't05_customer_order_data_d'[user_id]),
        't05_customer_order_data_d'[dt] >= __PeriodMin,
        't05_customer_order_data_d'[dt] <= __PeriodMax
    )
```

#### 4.9.2 Net_New_Customer No. Display

```dax
Net_New_Customer No. Display =
VAR __Value = [Net_New_Customer No. Value]
RETURN
    IF(
        ISBLANK(__Value),
        "-",
        FORMAT(__Value, "#,##0")
    )
```

### 4.10 Net_New_SLS（指标 10 — New 分支，按 product_id，按金额）

#### 4.10.1 Net_New_SLS Value

```dax
Net_New_SLS Value =
// ========================================
// 度量值: Net_New_SLS Value
// 用途: 新客在所选时间范围内各 product_id 下的净销售额
// 分支: New → Step1 a03 start_period 内 lp_12m_net_pay_amt=0 的 user_id 集合
//       Step2 t05 dt ∈ slicer 区间内对该集合 sum(net_pay_amt), by product_id
// 数据格式: currency（Display 层处理汇率换算）
// 汇率换算: 不在此度量值处理，由 Display 层处理
// ========================================
VAR __PeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Min[TimeFrame_Min])
VAR __PeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max[TimeFrame_Max])
VAR __StartPeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Min[First_Fiscal_Month_Min])
VAR __StartPeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Min[First_Fiscal_Month_Max])

// ── Step1: New 客户 user_id 集合 ──
VAR __NewUserIDs =
    CALCULATETABLE(
        VALUES('a03_e2e_customer_data_m'[user_id]),
        'a03_e2e_customer_data_m'[is_member] = 0,
        'a03_e2e_customer_data_m'[net_pay_amt] > 0,
        'a03_e2e_customer_data_m'[lp_12m_net_pay_amt] = 0,
        'a03_e2e_customer_data_m'[data_date] >= __StartPeriodMin,
        'a03_e2e_customer_data_m'[data_date] <= __StartPeriodMax
    )

// ── Step2: t05 slicer 区间内对 New 集合 sum(net_pay_amt) ──
RETURN
    CALCULATE(
        SUM('t05_customer_order_data_d'[net_pay_amt]),
        TREATAS(__NewUserIDs, 't05_customer_order_data_d'[user_id]),
        't05_customer_order_data_d'[dt] >= __PeriodMin,
        't05_customer_order_data_d'[dt] <= __PeriodMax
    )
```

#### 4.10.2 Net_New_SLS Display

```dax
Net_New_SLS Display =
// ========================================
// 度量值: Net_New_SLS Display
// 用途: 按 currency 格式化（货币符号 + 整数千分位）
// 汇率换算: Value 保留 RMB，Display 层按 Currency_ExchangeRate 换算
// ========================================
VAR __Value = [Net_New_SLS Value]
VAR __ExchangeRate = SELECTEDVALUE(Slicer_Currency_Selection[Currency_ExchangeRate], 1)
VAR __CurrencySymbol = SELECTEDVALUE(Slicer_Currency_Selection[Currency_Symbol], "¥")
VAR __ValueInCurrency = DIVIDE(__Value, __ExchangeRate)

RETURN
    IF(
        ISBLANK(__Value),
        "-",
        __CurrencySymbol & FORMAT(__ValueInCurrency, "#,##0")
    )
```

### 4.11 Net_TTL_Customer No.（指标 11 — All 分支，按 product_id，按人数）

#### 4.11.1 Net_TTL_Customer No. Value

```dax
Net_TTL_Customer No. Value =
// ========================================
// 度量值: Net_TTL_Customer No. Value
// 用途: 全客在所选时间范围内各 product_id 下的买家人数
// 分支: All → count(distinct user_id) where net_pay_amt > 0, dt ∈ slicer 区间
// 数据底表: t05_customer_order_data_d
// 数据格式: integer（Display 层处理）
// 行维度: product_id 直接拉取 t05 字段，自动分组
// ========================================
VAR __PeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Min[TimeFrame_Min])
VAR __PeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max[TimeFrame_Max])

RETURN
    CALCULATE(
        DISTINCTCOUNT('t05_customer_order_data_d'[user_id]),
        't05_customer_order_data_d'[net_pay_amt] > 0,
        't05_customer_order_data_d'[dt] >= __PeriodMin,
        't05_customer_order_data_d'[dt] <= __PeriodMax
    )
```

#### 4.11.2 Net_TTL_Customer No. Display

```dax
Net_TTL_Customer No. Display =
VAR __Value = [Net_TTL_Customer No. Value]
RETURN
    IF(
        ISBLANK(__Value),
        "-",
        FORMAT(__Value, "#,##0")
    )
```

### 4.12 TTL_SLS（指标 12 — All 分支，按 product_id，按金额）

#### 4.12.1 TTL_SLS Value

```dax
TTL_SLS Value =
// ========================================
// 度量值: TTL_SLS Value
// 用途: 全客在所选时间范围内各 product_id 下的净销售额
// 分支: All → sum(net_pay_amt), dt ∈ slicer 区间
// 数据底表: t05_customer_order_data_d
// 数据格式: currency（Display 层处理汇率换算）
// 汇率换算: 不在此度量值处理，由 Display 层处理
// ========================================
VAR __PeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Min[TimeFrame_Min])
VAR __PeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max[TimeFrame_Max])

RETURN
    CALCULATE(
        SUM('t05_customer_order_data_d'[net_pay_amt]),
        't05_customer_order_data_d'[dt] >= __PeriodMin,
        't05_customer_order_data_d'[dt] <= __PeriodMax
    )
```

#### 4.12.2 TTL_SLS Display

```dax
TTL_SLS Display =
VAR __Value = [TTL_SLS Value]
VAR __ExchangeRate = SELECTEDVALUE(Slicer_Currency_Selection[Currency_ExchangeRate], 1)
VAR __CurrencySymbol = SELECTEDVALUE(Slicer_Currency_Selection[Currency_Symbol], "¥")
VAR __ValueInCurrency = DIVIDE(__Value, __ExchangeRate)

RETURN
    IF(
        ISBLANK(__Value),
        "-",
        __CurrencySymbol & FORMAT(__ValueInCurrency, "#,##0")
    )
```

### 4.13 Net_Existing_Customer No.（指标 13 — Existing 分支，按 product_id，按人数）

#### 4.13.1 Net_Existing_Customer No. Value

```dax
Net_Existing_Customer No. Value =
// ========================================
// 度量值: Net_Existing_Customer No. Value
// 用途: 老客在所选时间范围内各 product_id 下的买家人数
// 分支: Existing → Step1 a03 start_period 内 lp_12m_net_pay_amt > 0 的 user_id 集合
//       Step2 t05 dt ∈ slicer 区间内对该集合 count(distinct user_id), by product_id
// 数据底表: a03_e2e_customer_data_m（Step1）、t05_customer_order_data_d（Step2）
// 数据格式: integer（Display 层处理）
// ========================================
VAR __PeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Min[TimeFrame_Min])
VAR __PeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max[TimeFrame_Max])
VAR __StartPeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Min[First_Fiscal_Month_Min])
VAR __StartPeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Min[First_Fiscal_Month_Max])

// ── Step1: Existing 客户 user_id 集合（a03 start_period 内判定）──
// 与 New 的区别: lp_12m_net_pay_amt > 0（老客有历史净销售额）
VAR __ExistingUserIDs =
    CALCULATETABLE(
        VALUES('a03_e2e_customer_data_m'[user_id]),
        'a03_e2e_customer_data_m'[is_member] = 0,
        'a03_e2e_customer_data_m'[net_pay_amt] > 0,
        'a03_e2e_customer_data_m'[lp_12m_net_pay_amt] > 0,
        'a03_e2e_customer_data_m'[data_date] >= __StartPeriodMin,
        'a03_e2e_customer_data_m'[data_date] <= __StartPeriodMax
    )

// ── Step2: t05 slicer 区间内对 Existing 集合 count(distinct user_id) ──
RETURN
    CALCULATE(
        DISTINCTCOUNT('t05_customer_order_data_d'[user_id]),
        TREATAS(__ExistingUserIDs, 't05_customer_order_data_d'[user_id]),
        't05_customer_order_data_d'[dt] >= __PeriodMin,
        't05_customer_order_data_d'[dt] <= __PeriodMax
    )
```

#### 4.13.2 Net_Existing_Customer No. Display

```dax
Net_Existing_Customer No. Display =
VAR __Value = [Net_Existing_Customer No. Value]
RETURN
    IF(
        ISBLANK(__Value),
        "-",
        FORMAT(__Value, "#,##0")
    )
```

### 4.14 Net_Existing_SLS（指标 14 — Existing 分支，按 product_id，按金额）

#### 4.14.1 Net_Existing_SLS Value

```dax
Net_Existing_SLS Value =
// ========================================
// 度量值: Net_Existing_SLS Value
// 用途: 老客在所选时间范围内各 product_id 下的净销售额
// 分支: Existing → Step1 a03 start_period 内 lp_12m_net_pay_amt > 0 的 user_id 集合
//       Step2 t05 dt ∈ slicer 区间内对该集合 sum(net_pay_amt), by product_id
// 数据格式: currency（Display 层处理汇率换算）
// 汇率换算: 不在此度量值处理，由 Display 层处理
// ========================================
VAR __PeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Min[TimeFrame_Min])
VAR __PeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max[TimeFrame_Max])
VAR __StartPeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Min[First_Fiscal_Month_Min])
VAR __StartPeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Min[First_Fiscal_Month_Max])

// ── Step1: Existing 客户 user_id 集合 ──
VAR __ExistingUserIDs =
    CALCULATETABLE(
        VALUES('a03_e2e_customer_data_m'[user_id]),
        'a03_e2e_customer_data_m'[is_member] = 0,
        'a03_e2e_customer_data_m'[net_pay_amt] > 0,
        'a03_e2e_customer_data_m'[lp_12m_net_pay_amt] > 0,
        'a03_e2e_customer_data_m'[data_date] >= __StartPeriodMin,
        'a03_e2e_customer_data_m'[data_date] <= __StartPeriodMax
    )

// ── Step2: t05 slicer 区间内对 Existing 集合 sum(net_pay_amt) ──
RETURN
    CALCULATE(
        SUM('t05_customer_order_data_d'[net_pay_amt]),
        TREATAS(__ExistingUserIDs, 't05_customer_order_data_d'[user_id]),
        't05_customer_order_data_d'[dt] >= __PeriodMin,
        't05_customer_order_data_d'[dt] <= __PeriodMax
    )
```

#### 4.14.2 Net_Existing_SLS Display

```dax
Net_Existing_SLS Display =
VAR __Value = [Net_Existing_SLS Value]
VAR __ExchangeRate = SELECTEDVALUE(Slicer_Currency_Selection[Currency_ExchangeRate], 1)
VAR __CurrencySymbol = SELECTEDVALUE(Slicer_Currency_Selection[Currency_Symbol], "¥")
VAR __ValueInCurrency = DIVIDE(__Value, __ExchangeRate)

RETURN
    IF(
        ISBLANK(__Value),
        "-",
        __CurrencySymbol & FORMAT(__ValueInCurrency, "#,##0")
    )
```

---

## 5. 度量值清单

| # | 度量值名称 | 类型 | 数据格式 | 用途 |
| --- | --- | --- | --- | --- |
| 1 | Net_Customer No. Value | Value | integer | All 分支买家人数 by category_summary |
| 2 | Net_Customer No. Display | Display | #,##0 | 整数千分位 |
| 3 | Net_SLS Value | Value | currency | All 分支净销售额 by category_summary |
| 4 | Net_SLS Display | Display | #,##0 | 货币符号 + 汇率换算 |
| 5 | New Customer% by No. Value | Value | percent_0dp | New 买家人数 / TTL 买家人数 |
| 6 | New Customer% by No. Display | Display | #,##0% | 百分比整数不含正号 |
| 7 | TTL Customer% by No. Value | Value | percent_0dp | TTL 买家人数 / 全客买家人数 |
| 8 | TTL Customer% by No. Display | Display | #,##0% | 百分比整数不含正号 |
| 9 | ±% by No. Value | Value | delta_pts | New% - TTL%（按人数） |
| 10 | ±% by No. Display | Display | +#,##0pts | 基点含正负号 |
| 11 | New Customer% by Amt Value | Value | percent_0dp | New 净销售额 / TTL 净销售额 |
| 12 | New Customer% by Amt Display | Display | #,##0% | 百分比整数不含正号 |
| 13 | TTL Customer% by Amt Value | Value | percent_0dp | TTL 净销售额 / 全客净销售额 |
| 14 | TTL Customer% by Amt Display | Display | #,##0% | 百分比整数不含正号 |
| 15 | ±% by Amt Value | Value | delta_pts | New% - TTL%（按金额） |
| 16 | ±% by Amt Display | Display | +#,##0pts | 基点含正负号 |
| 17 | Net_New_Customer No. Value | Value | integer | New 买家人数 by product_id |
| 18 | Net_New_Customer No. Display | Display | #,##0 | 整数千分位 |
| 19 | Net_New_SLS Value | Value | currency | New 净销售额 by product_id |
| 20 | Net_New_SLS Display | Display | #,##0 | 货币符号 + 汇率换算 |
| 21 | Net_TTL_Customer No. Value | Value | integer | All 买家人数 by product_id |
| 22 | Net_TTL_Customer No. Display | Display | #,##0 | 整数千分位 |
| 23 | TTL_SLS Value | Value | currency | All 净销售额 by product_id |
| 24 | TTL_SLS Display | Display | #,##0 | 货币符号 + 汇率换算 |
| 25 | Net_Existing_Customer No. Value | Value | integer | Existing 买家人数 by product_id |
| 26 | Net_Existing_Customer No. Display | Display | #,##0 | 整数千分位 |
| 27 | Net_Existing_SLS Value | Value | currency | Existing 净销售额 by product_id |
| 28 | Net_Existing_SLS Display | Display | #,##0 | 货币符号 + 汇率换算 |

---

## 6. 注意事项

1. **不受 Slicer_Customer_Type_Selection 影响**：本方案所有度量值均不读 `Slicer_Customer_Type_Selection`，每个指标直接硬编码对应分支（New/Existing/All），通过 `CALCULATETABLE` 在 `a03` start_period 内判定 user_id 集合，再 `TREATAS` 到 `t05` 聚合。

2. **不受 Net/Demand 按钮影响**：统一使用 `net_pay_amt` / `lp_12m_net_pay_amt` 等 Net 系列字段，不读 `Dim_RowMetric_Customer_Net_Demand`。

3. **行维度直接拉取事实表字段**：`category_summary` 和 `product_id` 是 `t05_customer_order_data_d` 的字段，直接拉取实现自动分组与筛选，DAX 无需显式处理。`a03_e2e_customer_data_m` 是汇总维度，无这两个字段，不能直接按其分组。

4. **时间口径差异**：
   - `t05_customer_order_data_d` 日期字段为 `dt`，区间 `dt ∈ [TimeFrame_Min, TimeFrame_Max]`
   - `a03_e2e_customer_data_m` 日期字段为 `data_date`，start_period 区间 `data_date ∈ [First_Fiscal_Month_Min, First_Fiscal_Month_Max]`
   - 口径文档中指标 4 分母提到的 `data_date` 为笔误，实际为 `dt`（表为 `t05_customer_order_data_d`）

5. **New/Existing 判定（Step1 + Step2）**：
   - Step1：`a03` 在 start_period 内筛选 `net_pay_amt > 0 AND is_member = 0 AND lp_12m_net_pay_amt = 0`（New）/ `> 0`（Existing）的 user_id 集合
   - Step2：在 `t05` 的 slicer 区间内对该集合 `TREATAS` 后 `DISTINCTCOUNT` 或 `SUM`
   - `is_member = 0` 仅在 `a03` Step1 中使用；`t05` 聚合不筛选 `is_member`（`t05` 无此字段）

6. **百分比分母不受产品筛选器影响**：
   - 指标 3/4/6/7 的分母用 `ALLSELECTED('t05_customer_order_data_d'[category_summary])` 移除图表维度影响
   - `ALLSELECTED` 保留外部切片器对 `category_summary` 的筛选，仅移除图表行维度的筛选
   - 聚合粒度分母为 `platform, shop_info_id, brand, framework`（不含 `category_summary`）

7. **汇率换算分层处理**：
   - Value 度量始终保留 RMB 原始值
   - Display 度量对金额类指标按 `DIVIDE(__Value, Currency_ExchangeRate)` 换算
   - 百分比 / delta_pts 为无量纲比率，不涉及汇率换算

8. **delta_pts 转换规则**：值 × 100 转 pts（基点），格式 `+#,##0pts;-#,##0pts;0pts`，含正负号。如 New Customer% = 0.30，TTL Customer% = 0.25，差值 = 0.05，× 100 = 5pts，显示为 `+5pts`。

9. **BLANK 处理**：所有 Display 度量在 Value 为 BLANK 时显示 `"-"`，避免空白单元格影响可读性。
