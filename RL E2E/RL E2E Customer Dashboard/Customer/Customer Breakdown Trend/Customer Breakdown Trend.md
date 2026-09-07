# Customer Breakdown Trend 解决方案

> **版本**: v1.0
> **模块**: Customer Dashboard - Customer Tab - Customer Breakdown Trend
> **关联口径**: 口径文档/Customer/Customer Breakdown Trend.md
> **数据底表**: a03_e2e_customer_data_m
> **关联维度**: Dim_RowMetric_Customer_Net_Demand（行，复用）、Slicer_Currency_Selection、Slicer_Time_Frame_Customer_Breakdown、Slicer_Time_Frame_Min_Customer_Breakdown、Slicer_Time_Frame_Max_Customer_Breakdown
> **用途**: 用于条形图和表格（非矩阵），每个指标独立拉取，无 x 轴，无需处理 x 轴当前时间

---

## 1. 需求理解

### 1.1 模块定位

Customer Breakdown Trend 是 Customer Tab 的客户结构下钻模块，按 New/Existing/All 三种客户类型展示 SLS 与 Customer No. 的趋势。共 **18 个指标**，每个指标独立输出 **Value 度量 + Display 度量**，共 36 个度量值。

### 1.2 全局规则（与 Performance Indicator 模块的关键差异）

| 项目               | 说明                                                                                                                              |
| ------------------ | --------------------------------------------------------------------------------------------------------------------------------- |
| Customer_Type 路由 | **不读 Slicer_Customer_Type_Selection**，每个度量值直接硬编码对应分支（New/Existing/All），不通过切片器切换                 |
| Net/Demand 路由    | 受 `Dim_RowMetric_Customer_Net_Demand[Row_Code]` 影响，通过 `SELECTEDVALUE([Row_Code])` 切换字段：Net→net_*，Demand→pay_* |
| 日期表改名         | 三个日期表全部加 `_Customer_Breakdown` 后缀，结构完全相同，仅为了避免与其他模块相互影响                                         |
| 派生指标格式       | 统一 `percent_0dp`（百分比整数**不含正号**：`#,##0%`，与 Performance 的 `delta_pct_0dp` 不同）                        |
| 金额类格式         | `currency_M_K_Int_0db`（分级显示：¥999 / ¥1.5K / ¥1.5M）                                                                     |
| 数量类格式         | `integer`（整数千分位：1,000）                                                                                                  |

### 1.3 18 个指标清单

| #  | 指标名称                     | 分支     | 类型  | 数据格式             |
| -- | ---------------------------- | -------- | ----- | -------------------- |
| 1  | SLS Breakdown                | All      | Act   | currency_M_K_Int_0db |
| 2  | SLS Breakdown vs LY          | All      | vs LY | percent_0dp          |
| 3  | SLS Breakdown vs LP          | All      | vs LP | percent_0dp          |
| 4  | New Customer SLS             | New      | Act   | currency_M_K_Int_0db |
| 5  | New Customer SLS vs LY       | New      | vs LY | percent_0dp          |
| 6  | New Customer SLS vs LP       | New      | vs LP | percent_0dp          |
| 7  | Existing Customer SLS        | Existing | Act   | currency_M_K_Int_0db |
| 8  | New Customer SLS Share       | —       | Share | percent_0dp          |
| 9  | Existing Customer SLS Share  | —       | Share | percent_0dp          |
| 10 | Customer No. Breakdown       | All      | Act   | integer              |
| 11 | Customer No. Breakdown vs LY | All      | vs LY | percent_0dp          |
| 12 | Customer No. Breakdown vs LP | All      | vs LP | percent_0dp          |
| 13 | New Customer No.             | New      | Act   | integer              |
| 14 | New Customer No. vs LY       | New      | vs LY | percent_0dp          |
| 15 | New Customer No. vs LP       | New      | vs LP | percent_0dp          |
| 16 | Existing Customer No.        | Existing | Act   | integer              |
| 17 | New Customer No. Share       | —       | Share | percent_0dp          |
| 18 | Existing Customer No. Share  | —       | Share | percent_0dp          |

### 1.4 分支口径（与 Performance Indicator 一致，来源：Customer Breakdown Trend.md）

- **All**：`SUM(amt) WHERE data_date ∈ slicer 区间 AND is_member=0`（SLS）；`DISTINCTCOUNT(user_id) WHERE slicer 区间 AND amt>0 AND is_member=0`（Customer No.）—— All 逻辑不变
- **New**：Step1（本期有消费的新客候选）：`data_date ∈ slicer 区间 AND is_member=0 AND SUM(amt) > 0`；Step2（第一财月的老客排除集）：`data_date ∈ start_period AND is_member=0 AND SUM(lp_12m_*_amt) > 0`；New user_id 集 = `EXCEPT(SUMMARIZE(Step1,[user_id]), SUMMARIZE(Step2,[user_id]))`；再在 slicer 区间内对该集合用 `TREATAS` 做 `SUM(amt)`
- **Existing**：Step1 同 New，但与 Step2 取 INTERSECT（本期消费者中第一财月已识别的老客，`lp_12m_*_amt > 0`）；再在 slicer 区间内对该集合用 `TREATAS` 做 `SUM(amt)`
- **New Customer No.**：直接 `COUNTROWS(EXCEPT(SUMMARIZE(Step1,[user_id]), SUMMARIZE(Step2,[user_id])))`（按 user_id 粒度计数，与 Customer.md 新客数口径一致）
- **Existing Customer No.**：直接 `COUNTROWS(INTERSECT(SUMMARIZE(Step1,[user_id]), SUMMARIZE(Step2,[user_id])))`
- **Share**：`分子 / (New 分支 + Existing 分支)`

> 注：Step1/Step2 内部按 `user_id + shop_info_id` 聚合做 SUM 判定，最终各自 `SUMMARIZE(..., [user_id])` 去重到 user_id 级再 EXCEPT/INTERSECT；两步区间不同、不可合并（参考：维度复用/新客 No. 模板详解.md）。New + Existing = Step1（本期消费者总数），两者互补。

---

## 2. 现状分析

- 数据底表 `a03_e2e_customer_data_m` 字段齐全：net_pay_amt / pay_amt / net_pay_qty / pay_qty / net_pay_order_cnt / pay_order_cnt / lp_12m_net_pay_amt / lp_12m_pay_amt / user_id / is_member / data_date
- 行维度表 `Dim_RowMetric_Customer_Net_Demand` 可复用（位于 Customer/Performance Indicator 目录）
- 三个日期表 `Slicer_Time_Frame_Customer_Breakdown` / `Slicer_Time_Frame_Min_Customer_Breakdown` / `Slicer_Time_Frame_Max_Customer_Breakdown` 需新建（结构复制自原 Slicer_Time_Frame 系列）

---

## 3. 方案设计

### 3.1 度量值分层

```
Value 度量（18 个）  ←  直接计算指标值，保留 RMB 原值
    ↓
Display 度量（18 个） ←  按 percent_0dp / currency_M_K_Int_0db / integer 格式化 + 货币符号拼接
```

### 3.2 字段路由（Net/Demand）

| KPI                   | Net 字段           | Demand 字段    |
| --------------------- | ------------------ | -------------- |
| SLS                   | net_pay_amt        | pay_amt        |
| Customer No. (筛选)   | net_pay_amt > 0    | pay_amt > 0    |
| start_period 判定字段 | lp_12m_net_pay_amt | lp_12m_pay_amt |

### 3.3 通用 VAR 模式（每个 Value 度量内部复用）

```dax
VAR __RowCode = IF(HASONEVALUE('Dim_RowMetric_Customer_Net_Demand'[Row_Code]),
                   SELECTEDVALUE('Dim_RowMetric_Customer_Net_Demand'[Row_Code]), "Net")
VAR __PeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Min_Customer_Breakdown[TimeFrame_Min])
VAR __PeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max_Customer_Breakdown[TimeFrame_Max])
VAR __StartPeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Min_Customer_Breakdown[First_Fiscal_Month_Min])
VAR __StartPeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Min_Customer_Breakdown[First_Fiscal_Month_Max])
// LY/LP 对称映射同理
```

---

## 4. 度量值实现

### 4.1 SLS Breakdown Value（All 分支 Act）

```dax
SLS Breakdown Value =
// ========================================
// 度量值: SLS Breakdown Value
// Display Folder: SLS\Value
// 用途: All 分支净销售额 / 销售额（受 Net/Demand 路由切换字段）
// 分支: All → SUM(amt) WHERE slicer 区间 AND is_member=0
// 数据格式: currency_M_K_Int_0db（Display 层处理）
// 汇率换算: 不在此度量值处理，由 Display 层处理（如有需要）
// ========================================
VAR __RowCode =
    IF(
        HASONEVALUE('Dim_RowMetric_Customer_Net_Demand'[Row_Code]),
        SELECTEDVALUE('Dim_RowMetric_Customer_Net_Demand'[Row_Code]),
        "Net"
    )
VAR __PeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Min_Customer_Breakdown[TimeFrame_Min])
VAR __PeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max_Customer_Breakdown[TimeFrame_Max])

RETURN
    SWITCH(
        __RowCode,
        "Net",
            CALCULATE(
                SUM('a03_e2e_customer_data_m'[net_pay_amt]),
                'a03_e2e_customer_data_m'[is_member] = 0,
                'a03_e2e_customer_data_m'[data_date] >= __PeriodMin,
                'a03_e2e_customer_data_m'[data_date] <= __PeriodMax
            ),
        "Demand",
            CALCULATE(
                SUM('a03_e2e_customer_data_m'[pay_amt]),
                'a03_e2e_customer_data_m'[is_member] = 0,
                'a03_e2e_customer_data_m'[data_date] >= __PeriodMin,
                'a03_e2e_customer_data_m'[data_date] <= __PeriodMax
            )
    )
```

### 4.2 SLS Breakdown Display

```dax
SLS Breakdown Display =
// ========================================
// 度量值: SLS Breakdown Display
// Display Folder: SLS\Display
// 用途: 按 currency_M_K_Int_0db 格式化显示
// 格式: < 1K → ¥999；1K~1M → ¥1.5K；≥ 1M → ¥1.5M
// 汇率换算: Value 度量保留 RMB 原值，Display 层按 Currency_ExchangeRate 换算
//           RMB: ExchangeRate=1（原值）；USD: ExchangeRate=7（RMB÷7=USD）
// ========================================
VAR __Value = [SLS Breakdown Value]
VAR __ExchangeRate = SELECTEDVALUE(Slicer_Currency_Selection[Currency_ExchangeRate], 1)
VAR __CurrencySymbol = SELECTEDVALUE(Slicer_Currency_Selection[Currency_Symbol], "¥")
// ── 汇率换算：RMB → 所选币种 ──
VAR __ValueInCurrency = DIVIDE(__Value, __ExchangeRate)

RETURN
    IF(
        ISBLANK(__Value),
        "-",
        IF(
            __ValueInCurrency < 1000,
            __CurrencySymbol & FORMAT(__ValueInCurrency, "#,##0"),
            IF(
                __ValueInCurrency < 1000000,
                __CurrencySymbol & FORMAT(__ValueInCurrency / 1000, "#,##0.0") & "K",
                __CurrencySymbol & FORMAT(__ValueInCurrency / 1000000, "#,##0.0") & "M"
            )
        )
    )
```

### 4.3 SLS Breakdown vs LY Value（All 分支 vs LY）

```dax
SLS Breakdown vs LY Value =
// ========================================
// 度量值: SLS Breakdown vs LY Value
// Display Folder: SLS\Value
// 用途: All 分支同比 = Act / LY - 1
// 优化: Act 直接引用 [SLS Breakdown Value]，自动继承当前筛选上下文
//       （包括 platform、shop_info_id 等行维度），无需重写 Act 逻辑
// 数据格式: percent_0dp（Display 层处理，不含正号）
// ========================================
VAR __RowCode =
    IF(
        HASONEVALUE('Dim_RowMetric_Customer_Net_Demand'[Row_Code]),
        SELECTEDVALUE('Dim_RowMetric_Customer_Net_Demand'[Row_Code]),
        "Net"
    )
VAR __PeriodMin_LY = SELECTEDVALUE(Slicer_Time_Frame_Min_Customer_Breakdown[TimeFrame_Min_LY])
VAR __PeriodMax_LY = SELECTEDVALUE(Slicer_Time_Frame_Max_Customer_Breakdown[TimeFrame_Max_LY])

// ── Act: 直接引用当期度量（自动继承店铺等行维度筛选）──
VAR __Act = [SLS Breakdown Value]

// ── LY: 用 LY 时间字段重新计算 ──
VAR __LY =
    SWITCH(
        __RowCode,
        "Net",
            CALCULATE(
                SUM('a03_e2e_customer_data_m'[net_pay_amt]),
                'a03_e2e_customer_data_m'[is_member] = 0,
                'a03_e2e_customer_data_m'[data_date] >= __PeriodMin_LY,
                'a03_e2e_customer_data_m'[data_date] <= __PeriodMax_LY
            ),
        "Demand",
            CALCULATE(
                SUM('a03_e2e_customer_data_m'[pay_amt]),
                'a03_e2e_customer_data_m'[is_member] = 0,
                'a03_e2e_customer_data_m'[data_date] >= __PeriodMin_LY,
                'a03_e2e_customer_data_m'[data_date] <= __PeriodMax_LY
            )
    )

RETURN
    IF(
        ISBLANK(__LY) || __LY = 0,
        BLANK(),
        DIVIDE(__Act, __LY) - 1
    )
```

### 4.4 SLS Breakdown vs LY Display

```dax
SLS Breakdown vs LY Display =
// ========================================
// 度量值: SLS Breakdown vs LY Display
// Display Folder: SLS\Display
// 用途: 按 percent_0dp 格式化（百分比整数，不含正号）
// ========================================
VAR __Value = [SLS Breakdown vs LY Value]
RETURN
    IF(
        ISBLANK(__Value),
        "-",
        FORMAT(__Value, "#,##0%")
    )
```

### 4.5 SLS Breakdown vs LP Value（All 分支 vs LP）

```dax
SLS Breakdown vs LP Value =
// ========================================
// 度量值: SLS Breakdown vs LP Value
// Display Folder: SLS\Value
// 用途: All 分支环比 = Act / LP - 1
// 优化: Act 直接引用 [SLS Breakdown Value]，自动继承当前筛选上下文
// ========================================
VAR __RowCode =
    IF(
        HASONEVALUE('Dim_RowMetric_Customer_Net_Demand'[Row_Code]),
        SELECTEDVALUE('Dim_RowMetric_Customer_Net_Demand'[Row_Code]),
        "Net"
    )
VAR __PeriodMin_LP = SELECTEDVALUE(Slicer_Time_Frame_Min_Customer_Breakdown[TimeFrame_Min_LP])
VAR __PeriodMax_LP = SELECTEDVALUE(Slicer_Time_Frame_Max_Customer_Breakdown[TimeFrame_Max_LP])

VAR __Act = [SLS Breakdown Value]

VAR __LP =
    SWITCH(
        __RowCode,
        "Net",
            CALCULATE(
                SUM('a03_e2e_customer_data_m'[net_pay_amt]),
                'a03_e2e_customer_data_m'[is_member] = 0,
                'a03_e2e_customer_data_m'[data_date] >= __PeriodMin_LP,
                'a03_e2e_customer_data_m'[data_date] <= __PeriodMax_LP
            ),
        "Demand",
            CALCULATE(
                SUM('a03_e2e_customer_data_m'[pay_amt]),
                'a03_e2e_customer_data_m'[is_member] = 0,
                'a03_e2e_customer_data_m'[data_date] >= __PeriodMin_LP,
                'a03_e2e_customer_data_m'[data_date] <= __PeriodMax_LP
            )
    )

RETURN
    IF(
        ISBLANK(__LP) || __LP = 0,
        BLANK(),
        DIVIDE(__Act, __LP) - 1
    )
```

### 4.6 SLS Breakdown vs LP Display

```dax
SLS Breakdown vs LP Display =
VAR __Value = [SLS Breakdown vs LP Value]
RETURN
    IF(
        ISBLANK(__Value),
        "-",
        FORMAT(__Value, "#,##0%")
    )
```

### 4.7 New Customer SLS Value（New 分支 Act）

```dax
New Customer SLS Value =
// ========================================
// 度量值: New Customer SLS Value
// Display Folder: SLS\Value
// 用途: New 分支净销售额 / 销售额
// 实现（与新客数最新 EXCEPT 逻辑一致，两步区间不可合并）:
//   Step1（本期有消费的新客候选）：data_date ∈ slicer 区间，is_member=0，SUM(amt) > 0
//   Step2（第一财月的老客排除集）：data_date ∈ start_period，is_member=0，SUM(lp_12m_*_amt) > 0
//   New user_id 集 = EXCEPT(SUMMARIZE(Step1,[user_id]), SUMMARIZE(Step2,[user_id]))
//   Step 3: 该集合在 slicer 区间内 SUM(amt) AND is_member=0（用 TREATAS 作为 user_id 筛选器）
// 字段路由: Net → net_pay_amt / lp_12m_net_pay_amt；Demand → pay_amt / lp_12m_pay_amt
// Step1/Step2 内部按 user_id + shop_info_id 聚合做 SUM 判定，最终各自 SUMMARIZE 去重到 user_id 再 EXCEPT
// ========================================
VAR __RowCode =
    IF(
        HASONEVALUE('Dim_RowMetric_Customer_Net_Demand'[Row_Code]),
        SELECTEDVALUE('Dim_RowMetric_Customer_Net_Demand'[Row_Code]),
        "Net"
    )
VAR __PeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Min_Customer_Breakdown[TimeFrame_Min])
VAR __PeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max_Customer_Breakdown[TimeFrame_Max])
VAR __StartPeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Min_Customer_Breakdown[First_Fiscal_Month_Min])
VAR __StartPeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Min_Customer_Breakdown[First_Fiscal_Month_Max])

// ── 同结构空表（IF 返回表需两分支列名一致）──
VAR __EmptyUsers = FILTER(VALUES('a03_e2e_customer_data_m'[user_id]), FALSE())

// ── Step1（本期有消费的新客候选，slicer 区间）：按 user_id + shop_info_id 聚合做 SUM(amt) > 0 判定 ──
VAR __Step1_Net =
    SELECTCOLUMNS(
        FILTER(
            CALCULATETABLE(
                SUMMARIZECOLUMNS(
                    'a03_e2e_customer_data_m'[user_id],
                    'a03_e2e_customer_data_m'[shop_info_id],
                    "_net", SUM('a03_e2e_customer_data_m'[net_pay_amt])
                ),
                'a03_e2e_customer_data_m'[data_date] >= __PeriodMin,
                'a03_e2e_customer_data_m'[data_date] <= __PeriodMax,
                'a03_e2e_customer_data_m'[is_member] = 0
            ),
            [_net] > 0
        ),
        "user_id", [user_id],
        "shop_info_id", [shop_info_id]
    )
VAR __Step1_Demand =
    SELECTCOLUMNS(
        FILTER(
            CALCULATETABLE(
                SUMMARIZECOLUMNS(
                    'a03_e2e_customer_data_m'[user_id],
                    'a03_e2e_customer_data_m'[shop_info_id],
                    "_pay", SUM('a03_e2e_customer_data_m'[pay_amt])
                ),
                'a03_e2e_customer_data_m'[data_date] >= __PeriodMin,
                'a03_e2e_customer_data_m'[data_date] <= __PeriodMax,
                'a03_e2e_customer_data_m'[is_member] = 0
            ),
            [_pay] > 0
        ),
        "user_id", [user_id],
        "shop_info_id", [shop_info_id]
    )

// ── Step2（第一财月的老客排除集，start_period 区间）：按 user_id + shop_info_id 聚合做 SUM(lp_12m_*_amt) > 0 判定 ──
VAR __Step2_Net =
    SELECTCOLUMNS(
        FILTER(
            CALCULATETABLE(
                SUMMARIZECOLUMNS(
                    'a03_e2e_customer_data_m'[user_id],
                    'a03_e2e_customer_data_m'[shop_info_id],
                    "_lp12m", SUM('a03_e2e_customer_data_m'[lp_12m_net_pay_amt])
                ),
                'a03_e2e_customer_data_m'[data_date] >= __StartPeriodMin,
                'a03_e2e_customer_data_m'[data_date] <= __StartPeriodMax,
                'a03_e2e_customer_data_m'[is_member] = 0
            ),
            [_lp12m] > 0
        ),
        "user_id", [user_id],
        "shop_info_id", [shop_info_id]
    )
VAR __Step2_Demand =
    SELECTCOLUMNS(
        FILTER(
            CALCULATETABLE(
                SUMMARIZECOLUMNS(
                    'a03_e2e_customer_data_m'[user_id],
                    'a03_e2e_customer_data_m'[shop_info_id],
                    "_lp12m", SUM('a03_e2e_customer_data_m'[lp_12m_pay_amt])
                ),
                'a03_e2e_customer_data_m'[data_date] >= __StartPeriodMin,
                'a03_e2e_customer_data_m'[data_date] <= __StartPeriodMax,
                'a03_e2e_customer_data_m'[is_member] = 0
            ),
            [_lp12m] > 0
        ),
        "user_id", [user_id],
        "shop_info_id", [shop_info_id]
    )

// ── New user_id 集 = Step1 EXCEPT Step2（按 user_id 去重）──
VAR __Users_New_Net    = EXCEPT(SUMMARIZE(__Step1_Net, [user_id]), SUMMARIZE(__Step2_Net, [user_id]))
VAR __Users_New_Demand = EXCEPT(SUMMARIZE(__Step1_Demand, [user_id]), SUMMARIZE(__Step2_Demand, [user_id]))

// ── 用 UNION+FILTER 选择目标集合（避免 IF 返回表被降级为标量） ──
VAR __TargetUserIDs =
    UNION(
        FILTER(__Users_New_Net,    __RowCode = "Net"),
        FILTER(__Users_New_Demand, __RowCode = "Demand"),
        FILTER(__EmptyUsers,       __RowCode <> "Net" && __RowCode <> "Demand")
    )

// ── Step 3: slicer 区间内对集合用户聚合 ──
RETURN
    SWITCH(
        __RowCode,
        "Net",
            CALCULATE(
                SUM('a03_e2e_customer_data_m'[net_pay_amt]),
                TREATAS(__TargetUserIDs, 'a03_e2e_customer_data_m'[user_id]),
                'a03_e2e_customer_data_m'[is_member] = 0,
                'a03_e2e_customer_data_m'[data_date] >= __PeriodMin,
                'a03_e2e_customer_data_m'[data_date] <= __PeriodMax
            ),
        "Demand",
            CALCULATE(
                SUM('a03_e2e_customer_data_m'[pay_amt]),
                TREATAS(__TargetUserIDs, 'a03_e2e_customer_data_m'[user_id]),
                'a03_e2e_customer_data_m'[is_member] = 0,
                'a03_e2e_customer_data_m'[data_date] >= __PeriodMin,
                'a03_e2e_customer_data_m'[data_date] <= __PeriodMax
            )
    )
```

### 4.8 New Customer SLS Display

```dax
New Customer SLS Display =
// ========================================
// 度量值: New Customer SLS Display
// Display Folder: SLS\Display
// 用途: 按 currency_M_K_Int_0db 格式化显示
// 汇率换算: Value 度量保留 RMB 原值，Display 层按 Currency_ExchangeRate 换算
// ========================================
VAR __Value = [New Customer SLS Value]
VAR __ExchangeRate = SELECTEDVALUE(Slicer_Currency_Selection[Currency_ExchangeRate], 1)
VAR __CurrencySymbol = SELECTEDVALUE(Slicer_Currency_Selection[Currency_Symbol], "¥")
VAR __ValueInCurrency = DIVIDE(__Value, __ExchangeRate)

RETURN
    IF(
        ISBLANK(__Value),
        "-",
        IF(
            __ValueInCurrency < 1000,
            __CurrencySymbol & FORMAT(__ValueInCurrency, "#,##0"),
            IF(
                __ValueInCurrency < 1000000,
                __CurrencySymbol & FORMAT(__ValueInCurrency / 1000, "#,##0.0") & "K",
                __CurrencySymbol & FORMAT(__ValueInCurrency / 1000000, "#,##0.0") & "M"
            )
        )
    )
```

### 4.9 New Customer SLS vs LY Value（New 分支 vs LY）

```dax
New Customer SLS vs LY Value =
// ========================================
// 度量值: New Customer SLS vs LY Value
// Display Folder: SLS\Value
// 用途: New 分支同比 = New Act / New LY - 1
// 优化: Act 直接引用 [New Customer SLS Value]，自动继承当前筛选上下文
//       （包括 platform、shop_info_id 等行维度），无需重写 Act 逻辑
//       LY 部分需重写：时间字段换 _LY，user_id 集合用 LY 的 Step1 EXCEPT Step2 重新构造
//       （与新客数最新 EXCEPT 逻辑一致，两步区间不可合并）
// ========================================
VAR __RowCode =
    IF(
        HASONEVALUE('Dim_RowMetric_Customer_Net_Demand'[Row_Code]),
        SELECTEDVALUE('Dim_RowMetric_Customer_Net_Demand'[Row_Code]),
        "Net"
    )
VAR __PeriodMin_LY = SELECTEDVALUE(Slicer_Time_Frame_Min_Customer_Breakdown[TimeFrame_Min_LY])
VAR __PeriodMax_LY = SELECTEDVALUE(Slicer_Time_Frame_Max_Customer_Breakdown[TimeFrame_Max_LY])
VAR __StartPeriodMin_LY = SELECTEDVALUE(Slicer_Time_Frame_Min_Customer_Breakdown[First_Fiscal_Month_Min_LY])
VAR __StartPeriodMax_LY = SELECTEDVALUE(Slicer_Time_Frame_Min_Customer_Breakdown[First_Fiscal_Month_Max_LY])

VAR __EmptyUsers = FILTER(VALUES('a03_e2e_customer_data_m'[user_id]), FALSE())

// ── Step1 LY（本期有消费的新客候选，slicer LY 区间）──
VAR __Step1_Net_LY =
    SELECTCOLUMNS(
        FILTER(
            CALCULATETABLE(
                SUMMARIZECOLUMNS(
                    'a03_e2e_customer_data_m'[user_id],
                    'a03_e2e_customer_data_m'[shop_info_id],
                    "_net", SUM('a03_e2e_customer_data_m'[net_pay_amt])
                ),
                'a03_e2e_customer_data_m'[data_date] >= __PeriodMin_LY,
                'a03_e2e_customer_data_m'[data_date] <= __PeriodMax_LY,
                'a03_e2e_customer_data_m'[is_member] = 0
            ),
            [_net] > 0
        ),
        "user_id", [user_id],
        "shop_info_id", [shop_info_id]
    )
VAR __Step1_Demand_LY =
    SELECTCOLUMNS(
        FILTER(
            CALCULATETABLE(
                SUMMARIZECOLUMNS(
                    'a03_e2e_customer_data_m'[user_id],
                    'a03_e2e_customer_data_m'[shop_info_id],
                    "_pay", SUM('a03_e2e_customer_data_m'[pay_amt])
                ),
                'a03_e2e_customer_data_m'[data_date] >= __PeriodMin_LY,
                'a03_e2e_customer_data_m'[data_date] <= __PeriodMax_LY,
                'a03_e2e_customer_data_m'[is_member] = 0
            ),
            [_pay] > 0
        ),
        "user_id", [user_id],
        "shop_info_id", [shop_info_id]
    )

// ── Step2 LY（第一财月的老客排除集，start_period LY 区间）──
VAR __Step2_Net_LY =
    SELECTCOLUMNS(
        FILTER(
            CALCULATETABLE(
                SUMMARIZECOLUMNS(
                    'a03_e2e_customer_data_m'[user_id],
                    'a03_e2e_customer_data_m'[shop_info_id],
                    "_lp12m", SUM('a03_e2e_customer_data_m'[lp_12m_net_pay_amt])
                ),
                'a03_e2e_customer_data_m'[data_date] >= __StartPeriodMin_LY,
                'a03_e2e_customer_data_m'[data_date] <= __StartPeriodMax_LY,
                'a03_e2e_customer_data_m'[is_member] = 0
            ),
            [_lp12m] > 0
        ),
        "user_id", [user_id],
        "shop_info_id", [shop_info_id]
    )
VAR __Step2_Demand_LY =
    SELECTCOLUMNS(
        FILTER(
            CALCULATETABLE(
                SUMMARIZECOLUMNS(
                    'a03_e2e_customer_data_m'[user_id],
                    'a03_e2e_customer_data_m'[shop_info_id],
                    "_lp12m", SUM('a03_e2e_customer_data_m'[lp_12m_pay_amt])
                ),
                'a03_e2e_customer_data_m'[data_date] >= __StartPeriodMin_LY,
                'a03_e2e_customer_data_m'[data_date] <= __StartPeriodMax_LY,
                'a03_e2e_customer_data_m'[is_member] = 0
            ),
            [_lp12m] > 0
        ),
        "user_id", [user_id],
        "shop_info_id", [shop_info_id]
    )

// ── LY New user_id 集 = Step1 LY EXCEPT Step2 LY（按 user_id 去重）──
VAR __Users_New_Net_LY    = EXCEPT(SUMMARIZE(__Step1_Net_LY, [user_id]), SUMMARIZE(__Step2_Net_LY, [user_id]))
VAR __Users_New_Demand_LY = EXCEPT(SUMMARIZE(__Step1_Demand_LY, [user_id]), SUMMARIZE(__Step2_Demand_LY, [user_id]))

VAR __TargetUserIDs_LY =
    UNION(
        FILTER(__Users_New_Net_LY,    __RowCode = "Net"),
        FILTER(__Users_New_Demand_LY, __RowCode = "Demand"),
        FILTER(__EmptyUsers,           __RowCode <> "Net" && __RowCode <> "Demand")
    )

// ── Act: 直接引用当期度量（自动继承店铺等行维度筛选）──
VAR __Act = [New Customer SLS Value]

// ── LY: 用 LY 时间字段 + LY 用户集合重新计算 ──
VAR __LY =
    SWITCH(
        __RowCode,
        "Net",
            CALCULATE(
                SUM('a03_e2e_customer_data_m'[net_pay_amt]),
                TREATAS(__TargetUserIDs_LY, 'a03_e2e_customer_data_m'[user_id]),
                'a03_e2e_customer_data_m'[is_member] = 0,
                'a03_e2e_customer_data_m'[data_date] >= __PeriodMin_LY,
                'a03_e2e_customer_data_m'[data_date] <= __PeriodMax_LY
            ),
        "Demand",
            CALCULATE(
                SUM('a03_e2e_customer_data_m'[pay_amt]),
                TREATAS(__TargetUserIDs_LY, 'a03_e2e_customer_data_m'[user_id]),
                'a03_e2e_customer_data_m'[is_member] = 0,
                'a03_e2e_customer_data_m'[data_date] >= __PeriodMin_LY,
                'a03_e2e_customer_data_m'[data_date] <= __PeriodMax_LY
            )
    )

RETURN
    IF(
        ISBLANK(__LY) || __LY = 0,
        BLANK(),
        DIVIDE(__Act, __LY) - 1
    )
```

### 4.10 New Customer SLS vs LY Display

```dax
New Customer SLS vs LY Display =
VAR __Value = [New Customer SLS vs LY Value]
RETURN
    IF(
        ISBLANK(__Value),
        "-",
        FORMAT(__Value, "#,##0%")
    )
```

### 4.11 New Customer SLS vs LP Value（New 分支 vs LP）

```dax
New Customer SLS vs LP Value =
// ========================================
// 度量值: New Customer SLS vs LP Value
// Display Folder: SLS\Value
// 用途: New 分支环比 = New Act / New LP - 1
// 优化: Act 直接引用 [New Customer SLS Value]，自动继承当前筛选上下文
//       LP 部分需重写：时间字段换 _LP，user_id 集合用 LP 的 Step1 EXCEPT Step2 重新构造
//       （与新客数最新 EXCEPT 逻辑一致，两步区间不可合并）
// ========================================
VAR __RowCode =
    IF(
        HASONEVALUE('Dim_RowMetric_Customer_Net_Demand'[Row_Code]),
        SELECTEDVALUE('Dim_RowMetric_Customer_Net_Demand'[Row_Code]),
        "Net"
    )
VAR __PeriodMin_LP = SELECTEDVALUE(Slicer_Time_Frame_Min_Customer_Breakdown[TimeFrame_Min_LP])
VAR __PeriodMax_LP = SELECTEDVALUE(Slicer_Time_Frame_Max_Customer_Breakdown[TimeFrame_Max_LP])
VAR __StartPeriodMin_LP = SELECTEDVALUE(Slicer_Time_Frame_Min_Customer_Breakdown[First_Fiscal_Month_Min_LP])
VAR __StartPeriodMax_LP = SELECTEDVALUE(Slicer_Time_Frame_Min_Customer_Breakdown[First_Fiscal_Month_Max_LP])

VAR __EmptyUsers = FILTER(VALUES('a03_e2e_customer_data_m'[user_id]), FALSE())

// ── Step1 LP（本期有消费的新客候选，slicer LP 区间）──
VAR __Step1_Net_LP =
    SELECTCOLUMNS(
        FILTER(
            CALCULATETABLE(
                SUMMARIZECOLUMNS(
                    'a03_e2e_customer_data_m'[user_id],
                    'a03_e2e_customer_data_m'[shop_info_id],
                    "_net", SUM('a03_e2e_customer_data_m'[net_pay_amt])
                ),
                'a03_e2e_customer_data_m'[data_date] >= __PeriodMin_LP,
                'a03_e2e_customer_data_m'[data_date] <= __PeriodMax_LP,
                'a03_e2e_customer_data_m'[is_member] = 0
            ),
            [_net] > 0
        ),
        "user_id", [user_id],
        "shop_info_id", [shop_info_id]
    )
VAR __Step1_Demand_LP =
    SELECTCOLUMNS(
        FILTER(
            CALCULATETABLE(
                SUMMARIZECOLUMNS(
                    'a03_e2e_customer_data_m'[user_id],
                    'a03_e2e_customer_data_m'[shop_info_id],
                    "_pay", SUM('a03_e2e_customer_data_m'[pay_amt])
                ),
                'a03_e2e_customer_data_m'[data_date] >= __PeriodMin_LP,
                'a03_e2e_customer_data_m'[data_date] <= __PeriodMax_LP,
                'a03_e2e_customer_data_m'[is_member] = 0
            ),
            [_pay] > 0
        ),
        "user_id", [user_id],
        "shop_info_id", [shop_info_id]
    )

// ── Step2 LP（第一财月的老客排除集，start_period LP 区间）──
VAR __Step2_Net_LP =
    SELECTCOLUMNS(
        FILTER(
            CALCULATETABLE(
                SUMMARIZECOLUMNS(
                    'a03_e2e_customer_data_m'[user_id],
                    'a03_e2e_customer_data_m'[shop_info_id],
                    "_lp12m", SUM('a03_e2e_customer_data_m'[lp_12m_net_pay_amt])
                ),
                'a03_e2e_customer_data_m'[data_date] >= __StartPeriodMin_LP,
                'a03_e2e_customer_data_m'[data_date] <= __StartPeriodMax_LP,
                'a03_e2e_customer_data_m'[is_member] = 0
            ),
            [_lp12m] > 0
        ),
        "user_id", [user_id],
        "shop_info_id", [shop_info_id]
    )
VAR __Step2_Demand_LP =
    SELECTCOLUMNS(
        FILTER(
            CALCULATETABLE(
                SUMMARIZECOLUMNS(
                    'a03_e2e_customer_data_m'[user_id],
                    'a03_e2e_customer_data_m'[shop_info_id],
                    "_lp12m", SUM('a03_e2e_customer_data_m'[lp_12m_pay_amt])
                ),
                'a03_e2e_customer_data_m'[data_date] >= __StartPeriodMin_LP,
                'a03_e2e_customer_data_m'[data_date] <= __StartPeriodMax_LP,
                'a03_e2e_customer_data_m'[is_member] = 0
            ),
            [_lp12m] > 0
        ),
        "user_id", [user_id],
        "shop_info_id", [shop_info_id]
    )

// ── LP New user_id 集 = Step1 LP EXCEPT Step2 LP（按 user_id 去重）──
VAR __Users_New_Net_LP    = EXCEPT(SUMMARIZE(__Step1_Net_LP, [user_id]), SUMMARIZE(__Step2_Net_LP, [user_id]))
VAR __Users_New_Demand_LP = EXCEPT(SUMMARIZE(__Step1_Demand_LP, [user_id]), SUMMARIZE(__Step2_Demand_LP, [user_id]))

VAR __TargetUserIDs_LP =
    UNION(
        FILTER(__Users_New_Net_LP,    __RowCode = "Net"),
        FILTER(__Users_New_Demand_LP, __RowCode = "Demand"),
        FILTER(__EmptyUsers,           __RowCode <> "Net" && __RowCode <> "Demand")
    )

// ── Act: 直接引用当期度量 ──
VAR __Act = [New Customer SLS Value]

// ── LP: 用 LP 时间字段 + LP 用户集合重新计算 ──
VAR __LP =
    SWITCH(
        __RowCode,
        "Net",
            CALCULATE(
                SUM('a03_e2e_customer_data_m'[net_pay_amt]),
                TREATAS(__TargetUserIDs_LP, 'a03_e2e_customer_data_m'[user_id]),
                'a03_e2e_customer_data_m'[is_member] = 0,
                'a03_e2e_customer_data_m'[data_date] >= __PeriodMin_LP,
                'a03_e2e_customer_data_m'[data_date] <= __PeriodMax_LP
            ),
        "Demand",
            CALCULATE(
                SUM('a03_e2e_customer_data_m'[pay_amt]),
                TREATAS(__TargetUserIDs_LP, 'a03_e2e_customer_data_m'[user_id]),
                'a03_e2e_customer_data_m'[is_member] = 0,
                'a03_e2e_customer_data_m'[data_date] >= __PeriodMin_LP,
                'a03_e2e_customer_data_m'[data_date] <= __PeriodMax_LP
            )
    )

RETURN
    IF(
        ISBLANK(__LP) || __LP = 0,
        BLANK(),
        DIVIDE(__Act, __LP) - 1
    )
```

### 4.12 New Customer SLS vs LP Display

```dax
New Customer SLS vs LP Display =
VAR __Value = [New Customer SLS vs LP Value]
RETURN
    IF(
        ISBLANK(__Value),
        "-",
        FORMAT(__Value, "#,##0%")
    )
```

### 4.13 Existing Customer SLS Value（Existing 分支 Act，不计算 vs LY/vs LP）

```dax
Existing Customer SLS Value =
// ========================================
// 度量值: Existing Customer SLS Value
// Display Folder: SLS\Value
// 用途: Existing 分支净销售额 / 销售额（老客，不计算 vs LY/vs LP）
// 实现（与新客数最新 EXCEPT 逻辑一致，两步区间不可合并）:
//   Step1（本期有消费的新客候选）：data_date ∈ slicer 区间，is_member=0，SUM(amt) > 0
//   Step2（第一财月的老客排除集）：data_date ∈ start_period，is_member=0，SUM(lp_12m_*_amt) > 0
//   Existing user_id 集 = INTERSECT(SUMMARIZE(Step1,[user_id]), SUMMARIZE(Step2,[user_id]))（本期消费者中第一财月已识别的老客）
//   Step 3: 该集合在 slicer 区间内 SUM(amt) AND is_member=0（用 TREATAS 作为 user_id 筛选器）
// 字段路由: Net → net_pay_amt / lp_12m_net_pay_amt；Demand → pay_amt / lp_12m_pay_amt
// Step1/Step2 内部按 user_id + shop_info_id 聚合做 SUM 判定，最终各自 SUMMARIZE 去重到 user_id 再 INTERSECT
// ========================================
VAR __RowCode =
    IF(
        HASONEVALUE('Dim_RowMetric_Customer_Net_Demand'[Row_Code]),
        SELECTEDVALUE('Dim_RowMetric_Customer_Net_Demand'[Row_Code]),
        "Net"
    )
VAR __PeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Min_Customer_Breakdown[TimeFrame_Min])
VAR __PeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max_Customer_Breakdown[TimeFrame_Max])
VAR __StartPeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Min_Customer_Breakdown[First_Fiscal_Month_Min])
VAR __StartPeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Min_Customer_Breakdown[First_Fiscal_Month_Max])

VAR __EmptyUsers = FILTER(VALUES('a03_e2e_customer_data_m'[user_id]), FALSE())

// ── Step1（本期有消费的新客候选，slicer 区间）：按 user_id + shop_info_id 聚合做 SUM(amt) > 0 判定 ──
VAR __Step1_Net =
    SELECTCOLUMNS(
        FILTER(
            CALCULATETABLE(
                SUMMARIZECOLUMNS(
                    'a03_e2e_customer_data_m'[user_id],
                    'a03_e2e_customer_data_m'[shop_info_id],
                    "_net", SUM('a03_e2e_customer_data_m'[net_pay_amt])
                ),
                'a03_e2e_customer_data_m'[data_date] >= __PeriodMin,
                'a03_e2e_customer_data_m'[data_date] <= __PeriodMax,
                'a03_e2e_customer_data_m'[is_member] = 0
            ),
            [_net] > 0
        ),
        "user_id", [user_id],
        "shop_info_id", [shop_info_id]
    )
VAR __Step1_Demand =
    SELECTCOLUMNS(
        FILTER(
            CALCULATETABLE(
                SUMMARIZECOLUMNS(
                    'a03_e2e_customer_data_m'[user_id],
                    'a03_e2e_customer_data_m'[shop_info_id],
                    "_pay", SUM('a03_e2e_customer_data_m'[pay_amt])
                ),
                'a03_e2e_customer_data_m'[data_date] >= __PeriodMin,
                'a03_e2e_customer_data_m'[data_date] <= __PeriodMax,
                'a03_e2e_customer_data_m'[is_member] = 0
            ),
            [_pay] > 0
        ),
        "user_id", [user_id],
        "shop_info_id", [shop_info_id]
    )

// ── Step2（第一财月的老客排除集，start_period 区间）：按 user_id + shop_info_id 聚合做 SUM(lp_12m_*_amt) > 0 判定 ──
VAR __Step2_Net =
    SELECTCOLUMNS(
        FILTER(
            CALCULATETABLE(
                SUMMARIZECOLUMNS(
                    'a03_e2e_customer_data_m'[user_id],
                    'a03_e2e_customer_data_m'[shop_info_id],
                    "_lp12m", SUM('a03_e2e_customer_data_m'[lp_12m_net_pay_amt])
                ),
                'a03_e2e_customer_data_m'[data_date] >= __StartPeriodMin,
                'a03_e2e_customer_data_m'[data_date] <= __StartPeriodMax,
                'a03_e2e_customer_data_m'[is_member] = 0
            ),
            [_lp12m] > 0
        ),
        "user_id", [user_id],
        "shop_info_id", [shop_info_id]
    )
VAR __Step2_Demand =
    SELECTCOLUMNS(
        FILTER(
            CALCULATETABLE(
                SUMMARIZECOLUMNS(
                    'a03_e2e_customer_data_m'[user_id],
                    'a03_e2e_customer_data_m'[shop_info_id],
                    "_lp12m", SUM('a03_e2e_customer_data_m'[lp_12m_pay_amt])
                ),
                'a03_e2e_customer_data_m'[data_date] >= __StartPeriodMin,
                'a03_e2e_customer_data_m'[data_date] <= __StartPeriodMax,
                'a03_e2e_customer_data_m'[is_member] = 0
            ),
            [_lp12m] > 0
        ),
        "user_id", [user_id],
        "shop_info_id", [shop_info_id]
    )

// ── Existing user_id 集 = Step1 INTERSECT Step2（按 user_id 去重，与 New 互补）──
VAR __Users_Existing_Net    = INTERSECT(SUMMARIZE(__Step1_Net, [user_id]), SUMMARIZE(__Step2_Net, [user_id]))
VAR __Users_Existing_Demand = INTERSECT(SUMMARIZE(__Step1_Demand, [user_id]), SUMMARIZE(__Step2_Demand, [user_id]))

VAR __TargetUserIDs =
    UNION(
        FILTER(__Users_Existing_Net,    __RowCode = "Net"),
        FILTER(__Users_Existing_Demand, __RowCode = "Demand"),
        FILTER(__EmptyUsers,            __RowCode <> "Net" && __RowCode <> "Demand")
    )

RETURN
    SWITCH(
        __RowCode,
        "Net",
            CALCULATE(
                SUM('a03_e2e_customer_data_m'[net_pay_amt]),
                TREATAS(__TargetUserIDs, 'a03_e2e_customer_data_m'[user_id]),
                'a03_e2e_customer_data_m'[is_member] = 0,
                'a03_e2e_customer_data_m'[data_date] >= __PeriodMin,
                'a03_e2e_customer_data_m'[data_date] <= __PeriodMax
            ),
        "Demand",
            CALCULATE(
                SUM('a03_e2e_customer_data_m'[pay_amt]),
                TREATAS(__TargetUserIDs, 'a03_e2e_customer_data_m'[user_id]),
                'a03_e2e_customer_data_m'[is_member] = 0,
                'a03_e2e_customer_data_m'[data_date] >= __PeriodMin,
                'a03_e2e_customer_data_m'[data_date] <= __PeriodMax
            )
    )
```

### 4.14 Existing Customer SLS Display

```dax
Existing Customer SLS Display =
// ========================================
// 度量值: Existing Customer SLS Display
// Display Folder: SLS\Display
// 用途: 按 currency_M_K_Int_0db 格式化显示
// 汇率换算: Value 度量保留 RMB 原值，Display 层按 Currency_ExchangeRate 换算
// ========================================
VAR __Value = [Existing Customer SLS Value]
VAR __ExchangeRate = SELECTEDVALUE(Slicer_Currency_Selection[Currency_ExchangeRate], 1)
VAR __CurrencySymbol = SELECTEDVALUE(Slicer_Currency_Selection[Currency_Symbol], "¥")
VAR __ValueInCurrency = DIVIDE(__Value, __ExchangeRate)

RETURN
    IF(
        ISBLANK(__Value),
        "-",
        IF(
            __ValueInCurrency < 1000,
            __CurrencySymbol & FORMAT(__ValueInCurrency, "#,##0"),
            IF(
                __ValueInCurrency < 1000000,
                __CurrencySymbol & FORMAT(__ValueInCurrency / 1000, "#,##0.0") & "K",
                __CurrencySymbol & FORMAT(__ValueInCurrency / 1000000, "#,##0.0") & "M"
            )
        )
    )
```

### 4.15 New Customer SLS Share Value

```dax
New Customer SLS Share Value =
// ========================================
// 度量值: New Customer SLS Share Value
// Display Folder: SLS\Value
// 用途: 新客销售额占比 = New 分支 / (New 分支 + Existing 分支)
// 数据格式: percent_0dp（不含正号）
// ========================================
VAR __New = [New Customer SLS Value]
VAR __Existing = [Existing Customer SLS Value]
VAR __Denominator = __New + __Existing

RETURN
    IF(
        __Denominator = 0 || ISBLANK(__Denominator),
        BLANK(),
        DIVIDE(__New, __Denominator)
    )
```

### 4.16 New Customer SLS Share Display

```dax
New Customer SLS Share Display =
VAR __Value = [New Customer SLS Share Value]
RETURN
    IF(
        ISBLANK(__Value),
        "-",
        FORMAT(__Value, "#,##0%")
    )
```

### 4.17 Existing Customer SLS Share Value

```dax
Existing Customer SLS Share Value =
// ========================================
// 度量值: Existing Customer SLS Share Value
// Display Folder: SLS\Value
// 用途: 老客销售额占比 = Existing 分支 / (New 分支 + Existing 分支)
// ========================================
VAR __New = [New Customer SLS Value]
VAR __Existing = [Existing Customer SLS Value]
VAR __Denominator = __New + __Existing

RETURN
    IF(
        __Denominator = 0 || ISBLANK(__Denominator),
        BLANK(),
        DIVIDE(__Existing, __Denominator)
    )
```

### 4.18 Existing Customer SLS Share Display

```dax
Existing Customer SLS Share Display =
VAR __Value = [Existing Customer SLS Share Value]
RETURN
    IF(
        ISBLANK(__Value),
        "-",
        FORMAT(__Value, "#,##0%")
    )
```

### 4.19 Customer No. Breakdown Value（All 分支 Act）

```dax
Customer No. Breakdown Value =
// ========================================
// 度量值: Customer No. Breakdown Value
// Display Folder: Customer No.\Value
// 用途: All 分支买家人数
// 口径: DISTINCTCOUNT(user_id) WHERE slicer 区间 AND amt>0 AND is_member=0
// 数据格式: integer
// ========================================
VAR __RowCode =
    IF(
        HASONEVALUE('Dim_RowMetric_Customer_Net_Demand'[Row_Code]),
        SELECTEDVALUE('Dim_RowMetric_Customer_Net_Demand'[Row_Code]),
        "Net"
    )
VAR __PeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Min_Customer_Breakdown[TimeFrame_Min])
VAR __PeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max_Customer_Breakdown[TimeFrame_Max])

RETURN
    SWITCH(
        __RowCode,
        "Net",
            CALCULATE(
                DISTINCTCOUNT('a03_e2e_customer_data_m'[user_id]),
                'a03_e2e_customer_data_m'[is_member] = 0,
                'a03_e2e_customer_data_m'[net_pay_amt] > 0,
                'a03_e2e_customer_data_m'[data_date] >= __PeriodMin,
                'a03_e2e_customer_data_m'[data_date] <= __PeriodMax
            ),
        "Demand",
            CALCULATE(
                DISTINCTCOUNT('a03_e2e_customer_data_m'[user_id]),
                'a03_e2e_customer_data_m'[is_member] = 0,
                'a03_e2e_customer_data_m'[pay_amt] > 0,
                'a03_e2e_customer_data_m'[data_date] >= __PeriodMin,
                'a03_e2e_customer_data_m'[data_date] <= __PeriodMax
            )
    )
```

### 4.20 Customer No. Breakdown Display

```dax
Customer No. Breakdown Display =
VAR __Value = [Customer No. Breakdown Value]
RETURN
    IF(
        ISBLANK(__Value),
        "-",
        FORMAT(__Value, "#,##0")
    )
```

### 4.21 Customer No. Breakdown vs LY Value（All 分支 vs LY）

```dax
Customer No. Breakdown vs LY Value =
// ========================================
// 度量值: Customer No. Breakdown vs LY Value
// Display Folder: Customer No.\Value
// 用途: All 分支买家人数同比 = Act / LY - 1
// 优化: Act 直接引用 [Customer No. Breakdown Value]，自动继承当前筛选上下文
// ========================================
VAR __RowCode =
    IF(
        HASONEVALUE('Dim_RowMetric_Customer_Net_Demand'[Row_Code]),
        SELECTEDVALUE('Dim_RowMetric_Customer_Net_Demand'[Row_Code]),
        "Net"
    )
VAR __PeriodMin_LY = SELECTEDVALUE(Slicer_Time_Frame_Min_Customer_Breakdown[TimeFrame_Min_LY])
VAR __PeriodMax_LY = SELECTEDVALUE(Slicer_Time_Frame_Max_Customer_Breakdown[TimeFrame_Max_LY])

VAR __Act = [Customer No. Breakdown Value]

VAR __LY =
    SWITCH(
        __RowCode,
        "Net",
            CALCULATE(
                DISTINCTCOUNT('a03_e2e_customer_data_m'[user_id]),
                'a03_e2e_customer_data_m'[is_member] = 0,
                'a03_e2e_customer_data_m'[net_pay_amt] > 0,
                'a03_e2e_customer_data_m'[data_date] >= __PeriodMin_LY,
                'a03_e2e_customer_data_m'[data_date] <= __PeriodMax_LY
            ),
        "Demand",
            CALCULATE(
                DISTINCTCOUNT('a03_e2e_customer_data_m'[user_id]),
                'a03_e2e_customer_data_m'[is_member] = 0,
                'a03_e2e_customer_data_m'[pay_amt] > 0,
                'a03_e2e_customer_data_m'[data_date] >= __PeriodMin_LY,
                'a03_e2e_customer_data_m'[data_date] <= __PeriodMax_LY
            )
    )

RETURN
    IF(
        ISBLANK(__LY) || __LY = 0,
        BLANK(),
        DIVIDE(__Act, __LY) - 1
    )
```

### 4.22 Customer No. Breakdown vs LY Display

```dax
Customer No. Breakdown vs LY Display =
VAR __Value = [Customer No. Breakdown vs LY Value]
RETURN
    IF(
        ISBLANK(__Value),
        "-",
        FORMAT(__Value, "#,##0%")
    )
```

### 4.23 Customer No. Breakdown vs LP Value（All 分支 vs LP）

```dax
Customer No. Breakdown vs LP Value =
// ========================================
// 度量值: Customer No. Breakdown vs LP Value
// Display Folder: Customer No.\Value
// 用途: All 分支买家人数环比 = Act / LP - 1
// 优化: Act 直接引用 [Customer No. Breakdown Value]，自动继承当前筛选上下文
// ========================================
VAR __RowCode =
    IF(
        HASONEVALUE('Dim_RowMetric_Customer_Net_Demand'[Row_Code]),
        SELECTEDVALUE('Dim_RowMetric_Customer_Net_Demand'[Row_Code]),
        "Net"
    )
VAR __PeriodMin_LP = SELECTEDVALUE(Slicer_Time_Frame_Min_Customer_Breakdown[TimeFrame_Min_LP])
VAR __PeriodMax_LP = SELECTEDVALUE(Slicer_Time_Frame_Max_Customer_Breakdown[TimeFrame_Max_LP])

VAR __Act = [Customer No. Breakdown Value]

VAR __LP =
    SWITCH(
        __RowCode,
        "Net",
            CALCULATE(
                DISTINCTCOUNT('a03_e2e_customer_data_m'[user_id]),
                'a03_e2e_customer_data_m'[is_member] = 0,
                'a03_e2e_customer_data_m'[net_pay_amt] > 0,
                'a03_e2e_customer_data_m'[data_date] >= __PeriodMin_LP,
                'a03_e2e_customer_data_m'[data_date] <= __PeriodMax_LP
            ),
        "Demand",
            CALCULATE(
                DISTINCTCOUNT('a03_e2e_customer_data_m'[user_id]),
                'a03_e2e_customer_data_m'[is_member] = 0,
                'a03_e2e_customer_data_m'[pay_amt] > 0,
                'a03_e2e_customer_data_m'[data_date] >= __PeriodMin_LP,
                'a03_e2e_customer_data_m'[data_date] <= __PeriodMax_LP
            )
    )

RETURN
    IF(
        ISBLANK(__LP) || __LP = 0,
        BLANK(),
        DIVIDE(__Act, __LP) - 1
    )
```

### 4.24 Customer No. Breakdown vs LP Display

```dax
Customer No. Breakdown vs LP Display =
VAR __Value = [Customer No. Breakdown vs LP Value]
RETURN
    IF(
        ISBLANK(__Value),
        "-",
        FORMAT(__Value, "#,##0%")
    )
```

### 4.25 New Customer No. Value（New 分支 Act）

```dax
New Customer No. Value =
// ========================================
// 度量值: New Customer No. Value
// Display Folder: Customer No.\Value
// 用途: New 分支买家人数
// 口径（与新客数最新 EXCEPT 逻辑一致，两步区间不可合并）:
//   Step1（本期有消费的新客候选）：data_date ∈ slicer 区间，is_member=0，SUM(amt) > 0
//   Step2（第一财月的老客排除集）：data_date ∈ start_period，is_member=0，SUM(lp_12m_*_amt) > 0
//   结果 = COUNTROWS(EXCEPT(SUMMARIZE(Step1,[user_id]), SUMMARIZE(Step2,[user_id])))
// 字段路由: Net → net_pay_amt / lp_12m_net_pay_amt；Demand → pay_amt / lp_12m_pay_amt
// Step1/Step2 内部按 user_id + shop_info_id 聚合做 SUM 判定，最终各自 SUMMARIZE 去重到 user_id 再 EXCEPT
// 人数按 user_id 粒度计数（与 Customer.md 新客数口径一致）
// ========================================
VAR __RowCode =
    IF(
        HASONEVALUE('Dim_RowMetric_Customer_Net_Demand'[Row_Code]),
        SELECTEDVALUE('Dim_RowMetric_Customer_Net_Demand'[Row_Code]),
        "Net"
    )
VAR __PeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Min_Customer_Breakdown[TimeFrame_Min])
VAR __PeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max_Customer_Breakdown[TimeFrame_Max])
VAR __StartPeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Min_Customer_Breakdown[First_Fiscal_Month_Min])
VAR __StartPeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Min_Customer_Breakdown[First_Fiscal_Month_Max])

// ── Step1（本期有消费的新客候选，slicer 区间）──
VAR __Step1_Net =
    SELECTCOLUMNS(
        FILTER(
            CALCULATETABLE(
                SUMMARIZECOLUMNS(
                    'a03_e2e_customer_data_m'[user_id],
                    'a03_e2e_customer_data_m'[shop_info_id],
                    "_net", SUM('a03_e2e_customer_data_m'[net_pay_amt])
                ),
                'a03_e2e_customer_data_m'[data_date] >= __PeriodMin,
                'a03_e2e_customer_data_m'[data_date] <= __PeriodMax,
                'a03_e2e_customer_data_m'[is_member] = 0
            ),
            [_net] > 0
        ),
        "user_id", [user_id],
        "shop_info_id", [shop_info_id]
    )
VAR __Step1_Demand =
    SELECTCOLUMNS(
        FILTER(
            CALCULATETABLE(
                SUMMARIZECOLUMNS(
                    'a03_e2e_customer_data_m'[user_id],
                    'a03_e2e_customer_data_m'[shop_info_id],
                    "_pay", SUM('a03_e2e_customer_data_m'[pay_amt])
                ),
                'a03_e2e_customer_data_m'[data_date] >= __PeriodMin,
                'a03_e2e_customer_data_m'[data_date] <= __PeriodMax,
                'a03_e2e_customer_data_m'[is_member] = 0
            ),
            [_pay] > 0
        ),
        "user_id", [user_id],
        "shop_info_id", [shop_info_id]
    )

// ── Step2（第一财月的老客排除集，start_period 区间）──
VAR __Step2_Net =
    SELECTCOLUMNS(
        FILTER(
            CALCULATETABLE(
                SUMMARIZECOLUMNS(
                    'a03_e2e_customer_data_m'[user_id],
                    'a03_e2e_customer_data_m'[shop_info_id],
                    "_lp12m", SUM('a03_e2e_customer_data_m'[lp_12m_net_pay_amt])
                ),
                'a03_e2e_customer_data_m'[data_date] >= __StartPeriodMin,
                'a03_e2e_customer_data_m'[data_date] <= __StartPeriodMax,
                'a03_e2e_customer_data_m'[is_member] = 0
            ),
            [_lp12m] > 0
        ),
        "user_id", [user_id],
        "shop_info_id", [shop_info_id]
    )
VAR __Step2_Demand =
    SELECTCOLUMNS(
        FILTER(
            CALCULATETABLE(
                SUMMARIZECOLUMNS(
                    'a03_e2e_customer_data_m'[user_id],
                    'a03_e2e_customer_data_m'[shop_info_id],
                    "_lp12m", SUM('a03_e2e_customer_data_m'[lp_12m_pay_amt])
                ),
                'a03_e2e_customer_data_m'[data_date] >= __StartPeriodMin,
                'a03_e2e_customer_data_m'[data_date] <= __StartPeriodMax,
                'a03_e2e_customer_data_m'[is_member] = 0
            ),
            [_lp12m] > 0
        ),
        "user_id", [user_id],
        "shop_info_id", [shop_info_id]
    )

// ── New user_id 集 = Step1 EXCEPT Step2（按 user_id 去重）──
VAR __Users_New_Net    = EXCEPT(SUMMARIZE(__Step1_Net, [user_id]), SUMMARIZE(__Step2_Net, [user_id]))
VAR __Users_New_Demand = EXCEPT(SUMMARIZE(__Step1_Demand, [user_id]), SUMMARIZE(__Step2_Demand, [user_id]))

RETURN
    SWITCH(
        __RowCode,
        "Net",      COUNTROWS(__Users_New_Net),
        "Demand",   COUNTROWS(__Users_New_Demand)
    )
```

### 4.26 New Customer No. Display

```dax
New Customer No. Display =
VAR __Value = [New Customer No. Value]
RETURN
    IF(
        ISBLANK(__Value),
        "-",
        FORMAT(__Value, "#,##0")
    )
```

### 4.27 New Customer No. vs LY Value（New 分支 vs LY）

```dax
New Customer No. vs LY Value =
// ========================================
// 度量值: New Customer No. vs LY Value
// Display Folder: Customer No.\Value
// 用途: New 分支买家人数同比 = New Act / New LY - 1
// 优化: Act 直接引用 [New Customer No. Value]，自动继承当前筛选上下文
//       LY 部分需重写：时间字段换 _LY，user_id 集合用 LY 的 Step1 EXCEPT Step2 重新构造
//       （与新客数最新 EXCEPT 逻辑一致，两步区间不可合并）
// ========================================
VAR __RowCode =
    IF(
        HASONEVALUE('Dim_RowMetric_Customer_Net_Demand'[Row_Code]),
        SELECTEDVALUE('Dim_RowMetric_Customer_Net_Demand'[Row_Code]),
        "Net"
    )
VAR __PeriodMin_LY = SELECTEDVALUE(Slicer_Time_Frame_Min_Customer_Breakdown[TimeFrame_Min_LY])
VAR __PeriodMax_LY = SELECTEDVALUE(Slicer_Time_Frame_Max_Customer_Breakdown[TimeFrame_Max_LY])
VAR __StartPeriodMin_LY = SELECTEDVALUE(Slicer_Time_Frame_Min_Customer_Breakdown[First_Fiscal_Month_Min_LY])
VAR __StartPeriodMax_LY = SELECTEDVALUE(Slicer_Time_Frame_Min_Customer_Breakdown[First_Fiscal_Month_Max_LY])

// ── Step1 LY（本期有消费的新客候选，slicer LY 区间）──
VAR __Step1_Net_LY =
    SELECTCOLUMNS(
        FILTER(
            CALCULATETABLE(
                SUMMARIZECOLUMNS(
                    'a03_e2e_customer_data_m'[user_id],
                    'a03_e2e_customer_data_m'[shop_info_id],
                    "_net", SUM('a03_e2e_customer_data_m'[net_pay_amt])
                ),
                'a03_e2e_customer_data_m'[data_date] >= __PeriodMin_LY,
                'a03_e2e_customer_data_m'[data_date] <= __PeriodMax_LY,
                'a03_e2e_customer_data_m'[is_member] = 0
            ),
            [_net] > 0
        ),
        "user_id", [user_id],
        "shop_info_id", [shop_info_id]
    )
VAR __Step1_Demand_LY =
    SELECTCOLUMNS(
        FILTER(
            CALCULATETABLE(
                SUMMARIZECOLUMNS(
                    'a03_e2e_customer_data_m'[user_id],
                    'a03_e2e_customer_data_m'[shop_info_id],
                    "_pay", SUM('a03_e2e_customer_data_m'[pay_amt])
                ),
                'a03_e2e_customer_data_m'[data_date] >= __PeriodMin_LY,
                'a03_e2e_customer_data_m'[data_date] <= __PeriodMax_LY,
                'a03_e2e_customer_data_m'[is_member] = 0
            ),
            [_pay] > 0
        ),
        "user_id", [user_id],
        "shop_info_id", [shop_info_id]
    )

// ── Step2 LY（第一财月的老客排除集，start_period LY 区间）──
VAR __Step2_Net_LY =
    SELECTCOLUMNS(
        FILTER(
            CALCULATETABLE(
                SUMMARIZECOLUMNS(
                    'a03_e2e_customer_data_m'[user_id],
                    'a03_e2e_customer_data_m'[shop_info_id],
                    "_lp12m", SUM('a03_e2e_customer_data_m'[lp_12m_net_pay_amt])
                ),
                'a03_e2e_customer_data_m'[data_date] >= __StartPeriodMin_LY,
                'a03_e2e_customer_data_m'[data_date] <= __StartPeriodMax_LY,
                'a03_e2e_customer_data_m'[is_member] = 0
            ),
            [_lp12m] > 0
        ),
        "user_id", [user_id],
        "shop_info_id", [shop_info_id]
    )
VAR __Step2_Demand_LY =
    SELECTCOLUMNS(
        FILTER(
            CALCULATETABLE(
                SUMMARIZECOLUMNS(
                    'a03_e2e_customer_data_m'[user_id],
                    'a03_e2e_customer_data_m'[shop_info_id],
                    "_lp12m", SUM('a03_e2e_customer_data_m'[lp_12m_pay_amt])
                ),
                'a03_e2e_customer_data_m'[data_date] >= __StartPeriodMin_LY,
                'a03_e2e_customer_data_m'[data_date] <= __StartPeriodMax_LY,
                'a03_e2e_customer_data_m'[is_member] = 0
            ),
            [_lp12m] > 0
        ),
        "user_id", [user_id],
        "shop_info_id", [shop_info_id]
    )

// ── LY New user_id 集 = Step1 LY EXCEPT Step2 LY（按 user_id 去重）──
VAR __Users_New_Net_LY    = EXCEPT(SUMMARIZE(__Step1_Net_LY, [user_id]), SUMMARIZE(__Step2_Net_LY, [user_id]))
VAR __Users_New_Demand_LY = EXCEPT(SUMMARIZE(__Step1_Demand_LY, [user_id]), SUMMARIZE(__Step2_Demand_LY, [user_id]))

VAR __Act = [New Customer No. Value]

VAR __LY =
    SWITCH(
        __RowCode,
        "Net",      COUNTROWS(__Users_New_Net_LY),
        "Demand",   COUNTROWS(__Users_New_Demand_LY)
    )

RETURN
    IF(
        ISBLANK(__LY) || __LY = 0,
        BLANK(),
        DIVIDE(__Act, __LY) - 1
    )
```

### 4.28 New Customer No. vs LY Display

```dax
New Customer No. vs LY Display =
VAR __Value = [New Customer No. vs LY Value]
RETURN
    IF(
        ISBLANK(__Value),
        "-",
        FORMAT(__Value, "#,##0%")
    )
```

### 4.29 New Customer No. vs LP Value（New 分支 vs LP）

```dax
New Customer No. vs LP Value =
// ========================================
// 度量值: New Customer No. vs LP Value
// Display Folder: Customer No.\Value
// 用途: New 分支买家人数环比 = New Act / New LP - 1
// 优化: Act 直接引用 [New Customer No. Value]，自动继承当前筛选上下文
//       LP 部分需重写：时间字段换 _LP，user_id 集合用 LP 的 Step1 EXCEPT Step2 重新构造
//       （与新客数最新 EXCEPT 逻辑一致，两步区间不可合并）
// ========================================
VAR __RowCode =
    IF(
        HASONEVALUE('Dim_RowMetric_Customer_Net_Demand'[Row_Code]),
        SELECTEDVALUE('Dim_RowMetric_Customer_Net_Demand'[Row_Code]),
        "Net"
    )
VAR __PeriodMin_LP = SELECTEDVALUE(Slicer_Time_Frame_Min_Customer_Breakdown[TimeFrame_Min_LP])
VAR __PeriodMax_LP = SELECTEDVALUE(Slicer_Time_Frame_Max_Customer_Breakdown[TimeFrame_Max_LP])
VAR __StartPeriodMin_LP = SELECTEDVALUE(Slicer_Time_Frame_Min_Customer_Breakdown[First_Fiscal_Month_Min_LP])
VAR __StartPeriodMax_LP = SELECTEDVALUE(Slicer_Time_Frame_Min_Customer_Breakdown[First_Fiscal_Month_Max_LP])

// ── Step1 LP（本期有消费的新客候选，slicer LP 区间）──
VAR __Step1_Net_LP =
    SELECTCOLUMNS(
        FILTER(
            CALCULATETABLE(
                SUMMARIZECOLUMNS(
                    'a03_e2e_customer_data_m'[user_id],
                    'a03_e2e_customer_data_m'[shop_info_id],
                    "_net", SUM('a03_e2e_customer_data_m'[net_pay_amt])
                ),
                'a03_e2e_customer_data_m'[data_date] >= __PeriodMin_LP,
                'a03_e2e_customer_data_m'[data_date] <= __PeriodMax_LP,
                'a03_e2e_customer_data_m'[is_member] = 0
            ),
            [_net] > 0
        ),
        "user_id", [user_id],
        "shop_info_id", [shop_info_id]
    )
VAR __Step1_Demand_LP =
    SELECTCOLUMNS(
        FILTER(
            CALCULATETABLE(
                SUMMARIZECOLUMNS(
                    'a03_e2e_customer_data_m'[user_id],
                    'a03_e2e_customer_data_m'[shop_info_id],
                    "_pay", SUM('a03_e2e_customer_data_m'[pay_amt])
                ),
                'a03_e2e_customer_data_m'[data_date] >= __PeriodMin_LP,
                'a03_e2e_customer_data_m'[data_date] <= __PeriodMax_LP,
                'a03_e2e_customer_data_m'[is_member] = 0
            ),
            [_pay] > 0
        ),
        "user_id", [user_id],
        "shop_info_id", [shop_info_id]
    )

// ── Step2 LP（第一财月的老客排除集，start_period LP 区间）──
VAR __Step2_Net_LP =
    SELECTCOLUMNS(
        FILTER(
            CALCULATETABLE(
                SUMMARIZECOLUMNS(
                    'a03_e2e_customer_data_m'[user_id],
                    'a03_e2e_customer_data_m'[shop_info_id],
                    "_lp12m", SUM('a03_e2e_customer_data_m'[lp_12m_net_pay_amt])
                ),
                'a03_e2e_customer_data_m'[data_date] >= __StartPeriodMin_LP,
                'a03_e2e_customer_data_m'[data_date] <= __StartPeriodMax_LP,
                'a03_e2e_customer_data_m'[is_member] = 0
            ),
            [_lp12m] > 0
        ),
        "user_id", [user_id],
        "shop_info_id", [shop_info_id]
    )
VAR __Step2_Demand_LP =
    SELECTCOLUMNS(
        FILTER(
            CALCULATETABLE(
                SUMMARIZECOLUMNS(
                    'a03_e2e_customer_data_m'[user_id],
                    'a03_e2e_customer_data_m'[shop_info_id],
                    "_lp12m", SUM('a03_e2e_customer_data_m'[lp_12m_pay_amt])
                ),
                'a03_e2e_customer_data_m'[data_date] >= __StartPeriodMin_LP,
                'a03_e2e_customer_data_m'[data_date] <= __StartPeriodMax_LP,
                'a03_e2e_customer_data_m'[is_member] = 0
            ),
            [_lp12m] > 0
        ),
        "user_id", [user_id],
        "shop_info_id", [shop_info_id]
    )

// ── LP New user_id 集 = Step1 LP EXCEPT Step2 LP（按 user_id 去重）──
VAR __Users_New_Net_LP    = EXCEPT(SUMMARIZE(__Step1_Net_LP, [user_id]), SUMMARIZE(__Step2_Net_LP, [user_id]))
VAR __Users_New_Demand_LP = EXCEPT(SUMMARIZE(__Step1_Demand_LP, [user_id]), SUMMARIZE(__Step2_Demand_LP, [user_id]))

VAR __Act = [New Customer No. Value]

VAR __LP =
    SWITCH(
        __RowCode,
        "Net",      COUNTROWS(__Users_New_Net_LP),
        "Demand",   COUNTROWS(__Users_New_Demand_LP)
    )

RETURN
    IF(
        ISBLANK(__LP) || __LP = 0,
        BLANK(),
        DIVIDE(__Act, __LP) - 1
    )
```

### 4.30 New Customer No. vs LP Display

```dax
New Customer No. vs LP Display =
VAR __Value = [New Customer No. vs LP Value]
RETURN
    IF(
        ISBLANK(__Value),
        "-",
        FORMAT(__Value, "#,##0%")
    )

```

### 4.31 Existing Customer No. Value（Existing 分支 Act，不计算 vs LY/vs LP）

```dax
Existing Customer No. Value =
// ========================================
// 度量值: Existing Customer No. Value
// Display Folder: Customer No.\Value
// 用途: Existing 分支买家人数（老客，不计算 vs LY/vs LP）
// 口径（与老客数最新 INTERSECT 逻辑一致，两步区间不可合并）:
//   Step1（本期有消费的老客候选）：data_date ∈ slicer 区间，is_member=0，SUM(amt) > 0
//   Step2（第一财月的老客识别集）：data_date ∈ start_period，is_member=0，SUM(lp_12m_*_amt) > 0
//   结果 = COUNTROWS(INTERSECT(SUMMARIZE(Step1,[user_id]), SUMMARIZE(Step2,[user_id])))
// 字段路由: Net → net_pay_amt / lp_12m_net_pay_amt；Demand → pay_amt / lp_12m_pay_amt
// Step1/Step2 内部按 user_id + shop_info_id 聚合做 SUM 判定，最终各自 SUMMARIZE 去重到 user_id 再 INTERSECT
// 人数按 user_id 粒度计数（与 Customer.md 老客数口径一致，New + Existing = Step1 本期消费者总数）
// ========================================
VAR __RowCode =
    IF(
        HASONEVALUE('Dim_RowMetric_Customer_Net_Demand'[Row_Code]),
        SELECTEDVALUE('Dim_RowMetric_Customer_Net_Demand'[Row_Code]),
        "Net"
    )
VAR __PeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Min_Customer_Breakdown[TimeFrame_Min])
VAR __PeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max_Customer_Breakdown[TimeFrame_Max])
VAR __StartPeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Min_Customer_Breakdown[First_Fiscal_Month_Min])
VAR __StartPeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Min_Customer_Breakdown[First_Fiscal_Month_Max])

// ── Step1（本期有消费的老客候选，slicer 区间）──
VAR __Step1_Net =
    SELECTCOLUMNS(
        FILTER(
            CALCULATETABLE(
                SUMMARIZECOLUMNS(
                    'a03_e2e_customer_data_m'[user_id],
                    'a03_e2e_customer_data_m'[shop_info_id],
                    "_net", SUM('a03_e2e_customer_data_m'[net_pay_amt])
                ),
                'a03_e2e_customer_data_m'[data_date] >= __PeriodMin,
                'a03_e2e_customer_data_m'[data_date] <= __PeriodMax,
                'a03_e2e_customer_data_m'[is_member] = 0
            ),
            [_net] > 0
        ),
        "user_id", [user_id],
        "shop_info_id", [shop_info_id]
    )
VAR __Step1_Demand =
    SELECTCOLUMNS(
        FILTER(
            CALCULATETABLE(
                SUMMARIZECOLUMNS(
                    'a03_e2e_customer_data_m'[user_id],
                    'a03_e2e_customer_data_m'[shop_info_id],
                    "_pay", SUM('a03_e2e_customer_data_m'[pay_amt])
                ),
                'a03_e2e_customer_data_m'[data_date] >= __PeriodMin,
                'a03_e2e_customer_data_m'[data_date] <= __PeriodMax,
                'a03_e2e_customer_data_m'[is_member] = 0
            ),
            [_pay] > 0
        ),
        "user_id", [user_id],
        "shop_info_id", [shop_info_id]
    )

// ── Step2（第一财月的老客识别集，start_period 区间）──
VAR __Step2_Net =
    SELECTCOLUMNS(
        FILTER(
            CALCULATETABLE(
                SUMMARIZECOLUMNS(
                    'a03_e2e_customer_data_m'[user_id],
                    'a03_e2e_customer_data_m'[shop_info_id],
                    "_lp12m", SUM('a03_e2e_customer_data_m'[lp_12m_net_pay_amt])
                ),
                'a03_e2e_customer_data_m'[data_date] >= __StartPeriodMin,
                'a03_e2e_customer_data_m'[data_date] <= __StartPeriodMax,
                'a03_e2e_customer_data_m'[is_member] = 0
            ),
            [_lp12m] > 0
        ),
        "user_id", [user_id],
        "shop_info_id", [shop_info_id]
    )
VAR __Step2_Demand =
    SELECTCOLUMNS(
        FILTER(
            CALCULATETABLE(
                SUMMARIZECOLUMNS(
                    'a03_e2e_customer_data_m'[user_id],
                    'a03_e2e_customer_data_m'[shop_info_id],
                    "_lp12m", SUM('a03_e2e_customer_data_m'[lp_12m_pay_amt])
                ),
                'a03_e2e_customer_data_m'[data_date] >= __StartPeriodMin,
                'a03_e2e_customer_data_m'[data_date] <= __StartPeriodMax,
                'a03_e2e_customer_data_m'[is_member] = 0
            ),
            [_lp12m] > 0
        ),
        "user_id", [user_id],
        "shop_info_id", [shop_info_id]
    )

// ── Existing user_id 集 = Step1 INTERSECT Step2（按 user_id 去重）──
VAR __Users_Existing_Net    = INTERSECT(SUMMARIZE(__Step1_Net, [user_id]), SUMMARIZE(__Step2_Net, [user_id]))
VAR __Users_Existing_Demand = INTERSECT(SUMMARIZE(__Step1_Demand, [user_id]), SUMMARIZE(__Step2_Demand, [user_id]))

RETURN
    SWITCH(
        __RowCode,
        "Net",      COUNTROWS(__Users_Existing_Net),
        "Demand",   COUNTROWS(__Users_Existing_Demand)
    )
```

### 4.32 Existing Customer No. Display

```dax
Existing Customer No. Display =
VAR __Value = [Existing Customer No. Value]
RETURN
    IF(
        ISBLANK(__Value),
        "-",
        FORMAT(__Value, "#,##0")
    )
```

### 4.33 New Customer No. Share Value

```dax
New Customer No. Share Value =
// ========================================
// 度量值: New Customer No. Share Value
// Display Folder: Customer No.\Value
// 用途: 新客人数占比 = New 分支 / (New 分支 + Existing 分支)
// ========================================
VAR __New = [New Customer No. Value]
VAR __Existing = [Existing Customer No. Value]
VAR __Denominator = __New + __Existing

RETURN
    IF(
        __Denominator = 0 || ISBLANK(__Denominator),
        BLANK(),
        DIVIDE(__New, __Denominator)
    )
```

### 4.34 New Customer No. Share Display

```dax
New Customer No. Share Display =
VAR __Value = [New Customer No. Share Value]
RETURN
    IF(
        ISBLANK(__Value),
        "-",
        FORMAT(__Value, "#,##0%")
    )
```

### 4.35 Existing Customer No. Share Value

```dax
Existing Customer No. Share Value =
// ========================================
// 度量值: Existing Customer No. Share Value
// Display Folder: Customer No.\Value
// 用途: 老客人数占比 = Existing 分支 / (New 分支 + Existing 分支)
// ========================================
VAR __New = [New Customer No. Value]
VAR __Existing = [Existing Customer No. Value]
VAR __Denominator = __New + __Existing

RETURN
    IF(
        __Denominator = 0 || ISBLANK(__Denominator),
        BLANK(),
        DIVIDE(__Existing, __Denominator)
    )
```

### 4.36 Existing Customer No. Share Display

```dax
Existing Customer No. Share Display =
VAR __Value = [Existing Customer No. Share Value]
RETURN
    IF(
        ISBLANK(__Value),
        "-",
        FORMAT(__Value, "#,##0%")
    )
```

---

## 5. 度量值清单与 Display Folder

| 序号 | 度量值名称                           | Display Folder       | 数据格式             | 用途                  |
| ---- | ------------------------------------ | -------------------- | -------------------- | --------------------- |
| 1    | SLS Breakdown Value                  | SLS\Value            | currency_M_K_Int_0db | All 分支净销售额      |
| 2    | SLS Breakdown Display                | SLS\Display          | currency_M_K_Int_0db | 显示                  |
| 3    | SLS Breakdown vs LY Value            | SLS\Value            | percent_0dp          | All 分支同比          |
| 4    | SLS Breakdown vs LY Display          | SLS\Display          | percent_0dp          | 显示                  |
| 5    | SLS Breakdown vs LP Value            | SLS\Value            | percent_0dp          | All 分支环比          |
| 6    | SLS Breakdown vs LP Display          | SLS\Display          | percent_0dp          | 显示                  |
| 7    | New Customer SLS Value               | SLS\Value            | currency_M_K_Int_0db | New 分支净销售额      |
| 8    | New Customer SLS Display             | SLS\Display          | currency_M_K_Int_0db | 显示                  |
| 9    | New Customer SLS vs LY Value         | SLS\Value            | percent_0dp          | New 分支同比          |
| 10   | New Customer SLS vs LY Display       | SLS\Display          | percent_0dp          | 显示                  |
| 11   | New Customer SLS vs LP Value         | SLS\Value            | percent_0dp          | New 分支环比          |
| 12   | New Customer SLS vs LP Display       | SLS\Display          | percent_0dp          | 显示                  |
| 13   | Existing Customer SLS Value          | SLS\Value            | currency_M_K_Int_0db | Existing 分支净销售额 |
| 14   | Existing Customer SLS Display        | SLS\Display          | currency_M_K_Int_0db | 显示                  |
| 15   | New Customer SLS Share Value         | SLS\Value            | percent_0dp          | 新客占比              |
| 16   | New Customer SLS Share Display       | SLS\Display          | percent_0dp          | 显示                  |
| 17   | Existing Customer SLS Share Value    | SLS\Value            | percent_0dp          | 老客占比              |
| 18   | Existing Customer SLS Share Display  | SLS\Display          | percent_0dp          | 显示                  |
| 19   | Customer No. Breakdown Value         | Customer No.\Value   | integer              | All 分支买家人数      |
| 20   | Customer No. Breakdown Display       | Customer No.\Display | integer              | 显示                  |
| 21   | Customer No. Breakdown vs LY Value   | Customer No.\Value   | percent_0dp          | All 分支同比          |
| 22   | Customer No. Breakdown vs LY Display | Customer No.\Display | percent_0dp          | 显示                  |
| 23   | Customer No. Breakdown vs LP Value   | Customer No.\Value   | percent_0dp          | All 分支环比          |
| 24   | Customer No. Breakdown vs LP Display | Customer No.\Display | percent_0dp          | 显示                  |
| 25   | New Customer No. Value               | Customer No.\Value   | integer              | New 分支买家人数      |
| 26   | New Customer No. Display             | Customer No.\Display | integer              | 显示                  |
| 27   | New Customer No. vs LY Value         | Customer No.\Value   | percent_0dp          | New 分支同比          |
| 28   | New Customer No. vs LY Display       | Customer No.\Display | percent_0dp          | 显示                  |
| 29   | New Customer No. vs LP Value         | Customer No.\Value   | percent_0dp          | New 分支环比          |
| 30   | New Customer No. vs LP Display       | Customer No.\Display | percent_0dp          | 显示                  |
| 31   | Existing Customer No. Value          | Customer No.\Value   | integer              | Existing 分支买家人数 |
| 32   | Existing Customer No. Display        | Customer No.\Display | integer              | 显示                  |
| 33   | New Customer No. Share Value         | Customer No.\Value   | percent_0dp          | 新客人数占比          |
| 34   | New Customer No. Share Display       | Customer No.\Display | percent_0dp          | 显示                  |
| 35   | Existing Customer No. Share Value    | Customer No.\Value   | percent_0dp          | 老客人数占比          |
| 36   | Existing Customer No. Share Display  | Customer No.\Display | percent_0dp          | 显示                  |

---

## 6. 注意事项

1. **本方案不读 Slicer_Customer_Type_Selection**：每个度量值内部直接硬编码对应分支（All/New/Existing）逻辑，不通过切片器切换。这与 Performance Indicator 模块的"切片器切换 New/Existing/All"设计不同。
2. **保留 Net/Demand 路由**：通过 `SELECTEDVALUE('Dim_RowMetric_Customer_Net_Demand'[Row_Code])` 切换字段：

   - Net → `net_pay_amt` / `net_pay_qty` / `net_pay_order_cnt` / `lp_12m_net_pay_amt`
   - Demand → `pay_amt` / `pay_qty` / `pay_order_cnt` / `lp_12m_pay_amt`
   - 默认（不选/多选）→ Net
3. **日期表全部改名**（结构相同，仅命名隔离）：

   - `Slicer_Time_Frame` → `Slicer_Time_Frame_Customer_Breakdown`
   - `Slicer_Time_Frame_Min` → `Slicer_Time_Frame_Min_Customer_Breakdown`
   - `Slicer_Time_Frame_Max` → `Slicer_Time_Frame_Max_Customer_Breakdown`
   - 所有度量值中均使用新表名，字段名保持不变（TimeFrame_Min / TimeFrame_Max / TimeFrame_Min_LY / TimeFrame_Max_LY / TimeFrame_Min_LP / TimeFrame_Max_LP / First_Fiscal_Month_Min / First_Fiscal_Month_Max 等）
4. **派生指标数据格式为 percent_0dp（不含正号）**：与 Performance Indicator 模块的 `delta_pct_0dp`（含正号）不同。本方案附属指标（vs LY / vs LP / Share）一律使用 `#,##0%` 格式，**不含正号**（如 `15%` 而非 `+15%`），严格遵循 Customer Breakdown Trend 口径文档要求。
5. **金额类格式 currency_M_K_Int_0db**（仅 SLS 系列 4 个 Act 指标）：

   - 值 < 1,000 → 货币符号 + 千分位整数：`¥999`
   - 1,000 ≤ 值 < 1,000,000 → 货币符号 + K 单位（1 位小数）：`¥1.5K`
   - 值 ≥ 1,000,000 → 货币符号 + M 单位（1 位小数）：`¥1.5M`
   - Customer No. 系列仍为 `integer` 整数千分位
6. **New/Existing 分支的 user_id 集合构造技术（Step1+Step2 EXCEPT/INTERSECT）**：

   - Step1（本期有消费的新客候选）：`CALCULATETABLE(SUMMARIZECOLUMNS(user_id, shop_info_id, "_amt", SUM(amt)), slicer 区间, is_member=0)` 过滤 `[_amt] > 0`
   - Step2（第一财月的老客排除/识别集）：`CALCULATETABLE(SUMMARIZECOLUMNS(user_id, shop_info_id, "_lp12m", SUM(lp_12m_*_amt)), start_period, is_member=0)` 过滤 `[_lp12m] > 0`
   - New 集合 = `EXCEPT(SUMMARIZE(Step1,[user_id]), SUMMARIZE(Step2,[user_id]))`（本期消费者剔除第一财月已识别的老客）
   - Existing 集合 = `INTERSECT(SUMMARIZE(Step1,[user_id]), SUMMARIZE(Step2,[user_id]))`（本期消费者中第一财月已识别的老客，与 New 互补）
   - Customer No. 直接 `COUNTROWS(New/Existing 集合)`（按 user_id 粒度计数）
   - SLS 通过 `TREATAS(__TargetUserIDs, user_id)` 在 slicer 区间聚合时筛选目标用户
   - Step1/Step2 内部按 `user_id + shop_info_id` 聚合做 SUM 判定，最终各自 `SUMMARIZE(..., [user_id])` 去重到 user_id 级再 EXCEPT/INTERSECT
7. **Step1/Step2 两步区间不可合并**（与新客数最新 EXCEPT 逻辑一致）：

   - Step1 区间（slicer 区间）：`data_date ∈ [TimeFrame_Min, TimeFrame_Max]`，判断 `SUM(amt) > 0`
   - Step2 区间（start_period）：`data_date ∈ [First_Fiscal_Month_Min, First_Fiscal_Month_Max]`，判断 `SUM(lp_12m_*_amt) > 0`
   - 两步区间不同、不可合并（参考：维度复用/新客 No. 模板详解.md）
   - New + Existing = Step1（本期消费者总数），两者互补
   - vs LY/vs LP 分别用对应 `_LY`/`_LP` 后缀的时间字段重新构造 Step1/Step2
8. **Share 计算口径**：

   - `New Customer SLS Share = New Customer SLS Value / (New Customer SLS Value + Existing Customer SLS Value)`
   - `Existing Customer SLS Share = Existing Customer SLS Value / (New Customer SLS Value + Existing Customer SLS Value)`
   - Customer No. Share 同理，分母 = New Customer No. Value + Existing Customer No. Value
   - 分母为 0 或 BLANK 时返回 BLANK
9. **Existing 分支不计算 vs LY / vs LP**（严格遵循口径文档要求）：

   - Existing Customer SLS 只有 Value 和 Display，没有 vs LY / vs LP
   - Existing Customer No. 同理
   - 仅 Existing Share 是单独的占比指标
   - Existing Value 实现采用 `INTERSECT(SUMMARIZE(Step1,[user_id]), SUMMARIZE(Step2,[user_id]))` 再 `COUNTROWS`（Customer No.）或 `TREATAS` + `SUM`（SLS），与 New 的 EXCEPT 互补
10. **用于条形图和表格（非矩阵）**：

    - 每个度量值独立可拉取，无 x 轴依赖
    - 不需要处理 x 轴上的当前时间
    - 行维度（platform / shop_info_id 等）由事实表字段直接拉取，模型自动传递筛选，DAX 无需显式处理
11. **汇率换算分层处理**（已实现）：
    - Value 层：始终保留 RMB 原始值，确保 LY/LP/Act 派生计算口径一致
    - Display 层：仅金额类 SLS（SLS Breakdown / New Customer SLS / Existing Customer SLS）的 3 个 Display 度量做汇率换算
      - 读取 `Slicer_Currency_Selection[Currency_ExchangeRate]`（RMB=1, USD=7）
      - `__ValueInCurrency = DIVIDE(__Value, __ExchangeRate)`
      - 再按 currency_M_K_Int_0db 分级显示拼接 `Currency_Symbol`（¥ / $）
    - 非金额类 Display（Customer No. Display、vs LY/vs LP Display、Share Display）不做汇率换算
      - 原因：Customer No. 为人数（integer），vs LY/vs LP/Share 为比率（percent_0dp），均无量纲
    - 分级判断（< 1K / < 1M / ≥ 1M）基于换算后的币种值，确保 USD 视图下也能正确分级
12. **DAX 语法规范**（遵循口径文档要求）：

    - 文本常量使用双引号 `" "`，禁止单引号
    - 单引号 `' '` 仅用于表名
    - 列名使用方括号 `[ ]`，如 `[is_member] = 0`
13. **字段名严格遵循口径文档**：

    - `net_pay_amt` / `net_pay_qty` / `net_pay_order_cnt`（Net 系列）
    - `pay_amt` / `pay_qty` / `pay_order_cnt`（Demand 系列）
    - `lp_12m_net_pay_amt` / `lp_12m_pay_amt`（start_period 内判定字段）
    - 日期字段统一为 `data_date`（非 `dt`）

```

```
