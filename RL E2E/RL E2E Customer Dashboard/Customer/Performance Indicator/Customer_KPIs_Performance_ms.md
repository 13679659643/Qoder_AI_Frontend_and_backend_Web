# Power BI 解决方案 — Customer Performance Indicator 矩阵（SWITCH 路由 + Net/Demand + New/Existing/All）

> status: ready
> created: 2026-08-19
> type: 度量值开发 + 可视化构建
> 口径来源: 口径文档/Customer/Performance Indicator.md（子模块二，6 个 KPI 分组共 18 列指标，按 Net/Demand 维度区分）
> 行指标维度表: Dim_RowMetric_Customer_Net_Demand（2 行：Net / Demand）
> 列指标维度表: Dim_ColMetric_Customer_Performance_Indicator（18 行，6 个 KPI 分组）

---

## 1. 需求理解

为 Customer Dashboard - Customer Tab 实现 Performance Indicator 矩阵：

- **行**：`Dim_RowMetric_Customer_Net_Demand` 的 `Row_Label`（Net / Demand），断开维度，通过 SELECTEDVALUE 读取 `Row_Code` 实现字段路由
- **列**：`Dim_ColMetric_Customer_Performance_Indicator` 的两级层级 `KPIGroup`（父）> `ColName`（子）
  - 6 个 KPI 分组：DCom SLS / Customer No. / ACV / AUR / Freq. / UPT
  - 共 18 列指标（每组 3 列：Act / vs LY / vs LP）
- **值**：SWITCH 动态路由，按 `Metric_ID` 分发到 Act / vs LY / vs LP
- **口径**：一切以口径文档 Performance Indicator.md 为准
- **筛选器**：
  - Slicer_Time_Frame_Min / Slicer_Time_Frame_Max（断开维度，区间聚合）
  - Slicer_Customer_Type_Selection（断开维度，New/Existing/All 逻辑切换）
  - Slicer_Currency_Selection（断开维度，币种符号与汇率换算）
  - Slicer_Platform_Selection / Slicer_Store_Name（行维度直接拉事实表字段实现自动传递）

### 1.1 实际值时间口径 = 所选时间范围区间聚合

- **slicer 区间**：`data_date ∈ [Slicer_Time_Frame_Min[TimeFrame_Min], Slicer_Time_Frame_Max[TimeFrame_Max]]`
- **start_period（第一个财月）**：`data_date ∈ [Slicer_Time_Frame_Min[First_Fiscal_Month_Min], Slicer_Time_Frame_Min[First_Fiscal_Month_Max]]`
- start_period 是 slicer 区间的子集

**LY/LP 区间对称映射**（起始端读 Min 切片器 LY/LP，结束端读 Max 切片器 LY/LP）：
- LY 区间 = `[Slicer_Time_Frame_Min[TimeFrame_Min_LY], Slicer_Time_Frame_Max[TimeFrame_Max_LY]]`
- LP 区间 = `[Slicer_Time_Frame_Min[TimeFrame_Min_LP], Slicer_Time_Frame_Max[TimeFrame_Max_LP]]`
- start_period LY = `[First_Fiscal_Month_Min_LY, First_Fiscal_Month_Max_LY]`
- start_period LP = `[First_Fiscal_Month_Min_LP, First_Fiscal_Month_Max_LP]`

### 1.2 Net / Demand 维度区分（通过 Row_Code 路由字段）

| Row_Code | 金额字段 | 件数字段 | 订单数字段 | 新客/老客判定字段 |
| --- | --- | --- | --- | --- |
| Net | net_pay_amt | net_pay_qty | net_pay_order_cnt | lp_12m_net_pay_amt |
| Demand | pay_amt | pay_qty | pay_order_cnt | lp_12m_pay_amt |

Net 与 Demand 指标个数、逻辑完全一致，区别仅在于字段。通过 `SELECTEDVALUE(Dim_RowMetric_Customer_Net_Demand[Row_Code])` 读取，在 DAX 中用 SWITCH 分支选择对应字段。不选/多选时默认走 Net 逻辑（通过 `HASONEVALUE` 判定，默认值 "Net"）。

### 1.3 New / Existing / All 逻辑（通过 Slicer_Customer_Type_Selection 路由）

Slicer_Customer_Type_Selection 中 Customer_Type_ID 只有 New 和 Existing 两个选项。

**路由判定**：
- `HASONEVALUE(Slicer_Customer_Type_Selection[Customer_Type_ID]) = TRUE` → 单选
  - 单选 New → New 逻辑
  - 单选 Existing → Existing 逻辑
- `HASONEVALUE = FALSE`（不选/多选/全选）→ All 逻辑

**New/Existing/All 口径**（参考 New Existing All 口径.md）：

| 客户类型 | 用户判定（start_period 内） | 销售额/件数/订单数汇总口径 |
| --- | --- | --- |
| **New** | `amt > 0 AND is_member = 0 AND lp_12m_*_amt = 0` → 得到新客 user_id 集合 | 对该 user_id 集合在 **slicer 区间** 内 `SUM(amt/qty/order_cnt) WHERE is_member = 0` |
| **Existing** | `amt > 0 AND is_member = 0 AND lp_12m_*_amt > 0` → 得到老客 user_id 集合 | 对该 user_id 集合在 **slicer 区间** 内 `SUM(amt/qty/order_cnt) WHERE is_member = 0` |
| **All** | 不限定 user_id 集合 | 在 **slicer 区间** 内 `SUM(amt/qty/order_cnt) WHERE is_member = 0` |

**技术实现**：
- New/Existing：先用 `CALCULATETABLE(VALUES(user_id), <start_period + New/Existing 条件>)` 得到目标 user_id 集合，再用 `TREATAS(__TargetUserIDs, 'a03_e2e_customer_data_m'[user_id])` 作为筛选器应用到 slicer 区间的 SUM/COUNT
- All：不应用 user_id 集合筛选，直接在 slicer 区间内 SUM/COUNT

### 1.4 指标分类与派生规则

| Metric_ID | KPIGroup | ColType | 计算方式 | Metric_Format | Metric_IsCurrencyAmount |
| --- | --- | --- | --- | --- | --- |
| 1 | DCom SLS | Act | `SUM(amt)` | currency | TRUE |
| 2 | DCom SLS | vs LY | 今年 / 去年 - 1 | delta_pct_0dp | FALSE |
| 3 | DCom SLS | vs LP | 当期 / 上期 - 1 | delta_pct_0dp | FALSE |
| 4 | Customer No. | Act | `COUNT(DISTINCT user_id)` | integer | FALSE |
| 5 | Customer No. | vs LY | 今年 / 去年 - 1 | delta_pct_0dp | FALSE |
| 6 | Customer No. | vs LP | 当期 / 上期 - 1 | delta_pct_0dp | FALSE |
| 7 | ACV | Act | `SUM(amt) / COUNT(DISTINCT user_id)` | currency | TRUE |
| 8 | ACV | vs LY | 今年 / 去年 - 1 | delta_pct_0dp | FALSE |
| 9 | ACV | vs LP | 当期 / 上期 - 1 | delta_pct_0dp | FALSE |
| 10 | AUR | Act | `SUM(amt) / SUM(qty)` | currency | TRUE |
| 11 | AUR | vs LY | 今年 / 去年 - 1 | delta_pct_0dp | FALSE |
| 12 | AUR | vs LP | 当期 / 上期 - 1 | delta_pct_0dp | FALSE |
| 13 | Freq. | Act | `SUM(order_cnt) / COUNT(DISTINCT user_id)` | integer | FALSE |
| 14 | Freq. | vs LY | 今年 / 去年 - 1 | delta_pct_0dp | FALSE |
| 15 | Freq. | vs LP | 当期 / 上期 - 1 | delta_pct_0dp | FALSE |
| 16 | UPT | Act | `SUM(qty) / SUM(order_cnt)` | integer | FALSE |
| 17 | UPT | vs LY | 今年 / 去年 - 1 | delta_pct_0dp | FALSE |
| 18 | UPT | vs LP | 当期 / 上期 - 1 | delta_pct_0dp | FALSE |

**派生规则**：
- 数量类 vs LY：今年 / 去年 - 1（全部 6 个分组均适用）
- 数量类 vs LP：当期 / 上期 - 1（全部 6 个分组均适用）

### 1.5 货币转换规则

- 数据源默认为 RMB
- Slicer_Currency_Selection 提供 `Currency_ExchangeRate`（RMB=1, USD=7）和 `Currency_Symbol`（¥ / $）
- **换算时机**：在 Cell Value 层对 `Metric_IsCurrencyAmount = TRUE` 且 `ColType = "Act"` 的指标做换算（`Value / Currency_ExchangeRate`）
- **vs LY / vs LP** 为无量纲比率，不涉及汇率换算
- Base Value 保持原始 RMB 值，确保派生计算一致性

---

## 2. 现状分析

### 2.1 数据底表

| 对象 | 名称 | 出处 |
| --- | --- | --- |
| 事实表 | a03_e2e_customer_data_m | Performance Indicator.md 全局逻辑 |
| 实际值关键字段 | data_date, platform, shop_info_id, user_id, is_member, net_pay_amt, net_pay_qty, net_pay_order_cnt, pay_amt, pay_qty, pay_order_cnt, lp_12m_net_pay_amt, lp_12m_pay_amt | a03_e2e_customer_data_m 数据字典 |

### 2.2 维度表清单

| 维度表 | 类型 | 连接方式 |
| --- | --- | --- |
| Dim_RowMetric_Customer_Net_Demand | 断开维度 | SELECTEDVALUE 读取 `Row_Code`（Net/Demand）实现字段路由 |
| Dim_ColMetric_Customer_Performance_Indicator | 断开维度 | SELECTEDVALUE 读取 `Metric_ID` / `ColType` / `Metric_Format` / `Metric_IsCurrencyAmount` / `Metric_ColorRule` / 颜色字段 |
| Slicer_Time_Frame_Min | 断开维度 | SELECTEDVALUE 读取 `TimeFrame_Min` / `First_Fiscal_Month_Min/Max` / LY/LP 系列 |
| Slicer_Time_Frame_Max | 断开维度 | SELECTEDVALUE 读取 `TimeFrame_Max` / LY/LP 系列 |
| Slicer_Customer_Type_Selection | 断开维度 | HASONEVALUE 判定单选/多选，SELECTEDVALUE 读取 `Customer_Type_ID`（New/Existing/All 路由） |
| Slicer_Currency_Selection | 断开维度 | SELECTEDVALUE 读取 `Currency_Symbol` / `Currency_ExchangeRate`（币种符号与汇率换算） |
| Slicer_Platform_Selection / Slicer_Store_Name | 断开维度 | 行维度直接拉事实表字段，模型自动传递 |

> **行维度处理**：`platform` / `shop_info_id` 直接拉取事实表字段实现自动传递，模型自动传递筛选，DAX 无需显式处理。

---

## 3. 方案设计

### 3.1 整体架构

```
核心思路：断开行列维度 + SWITCH 动态路由（Disconnected Dimension + Dispatch Pattern）

Dim_RowMetric_Customer_Net_Demand（断开维度，行头）
    │  无关系连接，仅通过 SELECTEDVALUE 读取 Row_Code（Net/Demand）
    │  → 路由到 net_pay_* 或 pay_* 字段
    │
Dim_ColMetric_Customer_Performance_Indicator（断开维度，列头）
    │  无关系连接，仅通过 SELECTEDVALUE 读取：
    │  - Metric_ID, ColType, KPIGroup, ColName
    │  - Metric_Format, Metric_IsCurrencyAmount
    │  - Metric_ColorRule, 颜色字段
    │
    ▼
    ┌─────────────────────────── Matrix 视觉对象 ──────────────────────────┐
    │  行 = 'Dim_RowMetric_Customer_Net_Demand'[Row_Label]（Net / Demand）    │
    │  列 = 'Dim_ColMetric_Customer_Performance_Indicator'[KPIGroup] > [ColName]│
    │  值 = [Customer Performance Cell Display]                             │
    └────────────────────────────────────────────────────────────────────────┘
                               ▲
                               │
          SWITCH 动态路由度量值链（按 Metric_ID + Row_Code + Customer_Type 分发）
          ┌────────────────────────────────────────────────────────────┐
          │  [Customer Performance Cell Value]                         │
          │    └→ [Customer Performance Base Value]（总路由）         │
          │         ├→ [Customer Performance Act Base Value]（本期） │
          │         │    内含 Net/Demand 字段分支 + New/Existing/All │
          │         │    user_id 集合分支 + 6 指标分支              │
          │         ├→ [Customer Performance LY Base Value]（去年同期）│
          │         ├→ [Customer Performance LP Base Value]（上期）    │
          │         └→ 派生：vs LY / vs LP（按 Metric_ID 路由）      │
          └────────────────────────────────────────────────────────────┘
```

### 3.2 度量值模型设计

```
[Customer Performance Act Base Value]   ← 本期基础值（原始 RMB）
                                         ← 三维路由：Row_Code × Customer_Type × Metric_ID
                                         ← New/Existing: TREATAS(user_id 集合) 筛选
                                         ← All: 不带 user_id 集合筛选
[Customer Performance LY Base Value]    ← 去年同期基础值（LY 区间对称映射）
[Customer Performance LP Base Value]    ← 上期基础值（LP 区间对称映射）
[Customer Performance Base Value]       ← 总路由（含 vs LY / vs LP 派生）
                                         ← REMOVEFILTERS 清陧行列断开维度筛选，再应用目标 Metric_ID
[Customer Performance Cell Value]       ← 对外值 = 汇率换算后的值
                                         ← Metric_IsCurrencyAmount=TRUE 且 ColType=Act 时 Value / ExchangeRate
[Customer Performance Cell Display]     ← 格式化显示文本（按 Metric_Format + Currency_Symbol）
[Customer Performance Cell Font Color]  ← 字体颜色（按 Metric_ColorRule 分发）
[Customer Performance Cell Background Color] ← 背景色（KPIGroup 行 vs KPI 行）
```

### 3.3 筛选器上下文

| 筛选器 | 作用方式 | DAX 处理 |
| --- | --- | --- |
| Slicer_Time_Frame_Min | 断开维度，SELECTEDVALUE 读取 `TimeFrame_Min` / `First_Fiscal_Month_Min/Max` | 本期区间起始日 + start_period 区间 + LY/LP 区间起始日 |
| Slicer_Time_Frame_Max | 断开维度，SELECTEDVALUE 读取 `TimeFrame_Max` | 本期区间结束日 + LY/LP 区间结束日 |
| Slicer_Customer_Type_Selection | 断开维度，HASONEVALUE 判定单选/多选 | New/Existing/All 逻辑路由 |
| Slicer_Currency_Selection | 断开维度，SELECTEDVALUE 读取 `Currency_Symbol/ExchangeRate` | 币种符号拼接 + 金额类汇率换算 |
| Dim_RowMetric_Customer_Net_Demand | 断开维度，SELECTEDVALUE 读取 `Row_Code` | Net/Demand 字段路由 |
| 事实表分组字段 | 表格行直接拉取，模型自动传递筛选 | DAX 无需显式处理 |

### 3.4 New/Existing/All 路由设计（最优方案）

**设计原则**：用 `HASONEVALUE` 判定单选状态，避免对 Slicer_Customer_Type_Selection 的全选/多选做特殊枚举。

```dax
// 单选判定：HASONEVALUE 为 TRUE 表示只选了一个
VAR __IsSingleCustomerType = HASONEVALUE(Slicer_Customer_Type_Selection[Customer_Type_ID])
// Customer_Type 路由值：单选时取选中值，多选/不选时取 "All"
VAR __CustomerType = 
    IF(__IsSingleCustomerType, 
        VALUES(Slicer_Customer_Type_Selection[Customer_Type_ID]), 
        "All"
    )
```

**路由结果**：
- 不选 → `HASONEVALUE = FALSE` → `__CustomerType = "All"`
- 单选 New → `HASONEVALUE = TRUE` → `__CustomerType = "New"`
- 单选 Existing → `HASONEVALUE = TRUE` → `__CustomerType = "Existing"`
- 全选（两个都选）→ `HASONEVALUE = FALSE` → `__CustomerType = "All"`

**New/Existing user_id 集合计算**（在 start_period 内）：
```dax
VAR __TargetUserIDs =
    SWITCH(__CustomerType,
        "New",
            SWITCH(__RowCode,
                "Net",
                    CALCULATETABLE(
                        VALUES('a03_e2e_customer_data_m'[user_id]),
                        'a03_e2e_customer_data_m'[is_member] = 0,
                        'a03_e2e_customer_data_m'[net_pay_amt] > 0,
                        'a03_e2e_customer_data_m'[lp_12m_net_pay_amt] = 0,
                        'a03_e2e_customer_data_m'[data_date] >= __StartPeriodMin,
                        'a03_e2e_customer_data_m'[data_date] <= __StartPeriodMax
                    ),
                "Demand",
                    CALCULATETABLE(
                        VALUES('a03_e2e_customer_data_m'[user_id]),
                        'a03_e2e_customer_data_m'[is_member] = 0,
                        'a03_e2e_customer_data_m'[pay_amt] > 0,
                        'a03_e2e_customer_data_m'[lp_12m_pay_amt] = 0,
                        'a03_e2e_customer_data_m'[data_date] >= __StartPeriodMin,
                        'a03_e2e_customer_data_m'[data_date] <= __StartPeriodMax
                    ),
                {}   // 兜底空表
            ),
        "Existing",
            SWITCH(__RowCode,
                "Net",
                    CALCULATETABLE(
                        VALUES('a03_e2e_customer_data_m'[user_id]),
                        'a03_e2e_customer_data_m'[is_member] = 0,
                        'a03_e2e_customer_data_m'[net_pay_amt] > 0,
                        'a03_e2e_customer_data_m'[lp_12m_net_pay_amt] > 0,
                        'a03_e2e_customer_data_m'[data_date] >= __StartPeriodMin,
                        'a03_e2e_customer_data_m'[data_date] <= __StartPeriodMax
                    ),
                "Demand",
                    CALCULATETABLE(
                        VALUES('a03_e2e_customer_data_m'[user_id]),
                        'a03_e2e_customer_data_m'[is_member] = 0,
                        'a03_e2e_customer_data_m'[pay_amt] > 0,
                        'a03_e2e_customer_data_m'[lp_12m_pay_amt] > 0,
                        'a03_e2e_customer_data_m'[data_date] >= __StartPeriodMin,
                        'a03_e2e_customer_data_m'[data_date] <= __StartPeriodMax
                    ),
                {}
            ),
        {}   // All 返回空表，表示不应用 user_id 集合筛选
    )
```

**All 逻辑处理**：当 `__CustomerType = "All"` 时，`__TargetUserIDs` 返回空表。在后续 SUM/COUNT 中用 `IF(__IsAll, ...)` 分支，All 分支不带 TREATAS 筛选。

### 3.5 指标 Act 逻辑汇总（按 Metric_ID）

| Metric_ID | 指标 | New/Existing 逻辑 | All 逻辑 |
| --- | --- | --- | --- |
| 1 | DCom SLS | `SUM(amt) WHERE slicer 区间 AND is_member=0 AND user_id ∈ __TargetUserIDs` | `SUM(amt) WHERE slicer 区间 AND is_member=0` |
| 4 | Customer No. | `COUNT(DISTINCT user_id) WHERE start_period AND amt>0 AND is_member=0 AND lp_12m_*_amt 判定` | `COUNT(DISTINCT user_id) WHERE slicer 区间 AND amt>0 AND is_member=0` |
| 7 | ACV | 分子: `SUM(amt) WHERE slicer 区间 AND is_member=0 AND user_id ∈ __TargetUserIDs`；分母: `COUNT(DISTINCT user_id) WHERE slicer 区间 AND is_member=0 AND user_id ∈ __TargetUserIDs` | 分子: `SUM(amt) WHERE slicer 区间 AND is_member=0`；分母: `COUNT(DISTINCT user_id) WHERE slicer 区间 AND amt>0 AND is_member=0` |
| 10 | AUR | 分子: `SUM(amt) WHERE slicer 区间 AND is_member=0 AND user_id ∈ __TargetUserIDs`；分母: `SUM(qty) WHERE slicer 区间 AND is_member=0 AND user_id ∈ __TargetUserIDs` | 分子: `SUM(amt) WHERE slicer 区间 AND is_member=0`；分母: `SUM(qty) WHERE slicer 区间 AND is_member=0` |
| 13 | Freq. | 分子: `SUM(order_cnt) WHERE slicer 区间 AND is_member=0 AND user_id ∈ __TargetUserIDs`；分母: `COUNT(DISTINCT user_id) WHERE slicer 区间 AND is_member=0 AND user_id ∈ __TargetUserIDs` | 分子: `SUM(order_cnt) WHERE slicer 区间 AND is_member=0`；分母: `COUNT(DISTINCT user_id) WHERE slicer 区间 AND amt>0 AND is_member=0` |
| 16 | UPT | 分子: `SUM(qty) WHERE slicer 区间 AND is_member=0 AND user_id ∈ __TargetUserIDs`；分母: `SUM(order_cnt) WHERE slicer 区间 AND is_member=0 AND user_id ∈ __TargetUserIDs` | 分子: `SUM(qty) WHERE slicer 区间 AND is_member=0`；分母: `SUM(order_cnt) WHERE slicer 区间 AND is_member=0` |

> **注**：Customer No. (Metric_ID=4) 的 New/Existing 逻辑特殊——直接在 start_period 内 DISTINCTCOUNT（合并区间实现，无需 TREATAS），因为 Customer No. 的统计本身就是基于 start_period 内的 user_id 判定。All 逻辑则在 slicer 区间内 DISTINCTCOUNT。

### 3.6 格式规范（按 Metric_Format + Currency_Symbol）

| Metric_Format | 格式串 | 示例 | 适用指标 |
| --- | --- | --- | --- |
| `currency` | `__CurrencySymbol & FORMAT(__Value, "#,##0")` | ¥1,000 / $143 | DCom SLS / ACV / AUR 的 Act 列（Metric_IsCurrencyAmount=TRUE） |
| `integer` | `FORMAT(__Value, "#,##0")` | 1,234 | Customer No. / Freq. / UPT 的 Act 列 |
| `delta_pct_0dp` | `IF(__Value>0,"+","") & FORMAT(__Value,"#,##0%")` | +15% / -3% | 全部 vs LY / vs LP 列 |

---

## 4. 度量值实现

### 4.1 行/列指标维度表（已存在）

- 行指标维度表：`Dim_RowMetric_Customer_Net_Demand`（2 行：Net / Demand），已存在于 `Dim_RowMetric_Customer_Net_Demand.md`
- 列指标维度表：`Dim_ColMetric_Customer_Performance_Indicator`（18 行，6 个 KPI 分组），已存在于 `Dim_ColMetric_Customer_KPIs_Performance.md`

### 4.2 Customer Performance Act Base Value（本期基础值）

```dax
Customer Performance Act Base Value =
// ========================================
// 度量值: Customer Performance Act Base Value
// Display Folder: Base Metrics
// 用途: 根据 Row_Code × Customer_Type × Metric_ID 三维路由到本期（Act）基础值（原始 RMB）
// 依赖:
//   'Dim_RowMetric_Customer_Net_Demand'[Row_Code],
//   'Dim_ColMetric_Customer_Performance_Indicator'[Metric_ID],
//   Slicer_Customer_Type_Selection[Customer_Type_ID],
//   Slicer_Time_Frame_Min[TimeFrame_Min, First_Fiscal_Month_Min, First_Fiscal_Month_Max],
//   Slicer_Time_Frame_Max[TimeFrame_Max],
//   a03_e2e_customer_data_m
// 口径来源: 口径文档/Customer/Performance Indicator.md 子模块二
// 筛选上下文:
//   - slicer 区间: data_date ∈ [TimeFrame_Min, TimeFrame_Max]（实际值汇总区间）
//   - start_period 区间: data_date ∈ [First_Fiscal_Month_Min, First_Fiscal_Month_Max]（New/Existing user_id 判定区间）
//   - is_member = 0（固定非会员）
// 三维路由:
//   1. Row_Code（Net/Demand）→ 选择字段: amt / qty / order_cnt / lp_12m_*_amt
//   2. Customer_Type（New/Existing/All）→ 选择 user_id 集合筛选
//   3. Metric_ID（1/4/7/10/13/16）→ 选择指标计算方式
// 汇率换算: 不在此度量值处理，保持原始 RMB，由 Cell Value 层统一换算
// ========================================

// ── 行维度路由：Net / Demand ──
// 注意：VALUES 返回"表"（单行单列），SELECTEDVALUE 返回"标量值"，
//       后续做字符串比较（__RowCode = "Net"）必须用标量，故用 SELECTEDVALUE
VAR __RowCode =
    IF(
        HASONEVALUE('Dim_RowMetric_Customer_Net_Demand'[Row_Code]),
        SELECTEDVALUE('Dim_RowMetric_Customer_Net_Demand'[Row_Code]),
        "Net"   // 不选/多选时默认 Net
    )

// ── 客户类型路由：New / Existing / All ──
VAR __IsSingleCustomerType = HASONEVALUE(Slicer_Customer_Type_Selection[Customer_Type_ID])
VAR __CustomerType =
    IF(__IsSingleCustomerType, SELECTEDVALUE(Slicer_Customer_Type_Selection[Customer_Type_ID]), "All")
VAR __IsAll = (__CustomerType = "All")

// ── 列维度路由：Metric_ID ──
VAR __MetricID = SELECTEDVALUE('Dim_ColMetric_Customer_Performance_Indicator'[Metric_ID])

// ── 时间区间变量 ──
VAR __PeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Min[TimeFrame_Min])
VAR __PeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max[TimeFrame_Max])
VAR __StartPeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Min[First_Fiscal_Month_Min])
VAR __StartPeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Min[First_Fiscal_Month_Max])

// ═══════════════════════════════════════════════════════════════
// New/Existing user_id 集合（在 start_period 内判定）
// All 返回空表，后续用 __IsAll 分支不应用 TREATAS
//
// 关键技术点（DAX 表类型约束）:
//   1. SWITCH 只能返回标量值，不能返回表 → 必须用 IF 嵌套
//   2. IF 返回表时，两个分支必须返回"列结构完全一致"的表
//      - {} 字面量创建的空表列名是 "Value"
//      - VALUES(user_id) 创建的表列名是 "user_id"
//      列名不匹配时，引擎把 IF 当作标量函数处理 → 报错
//      "该表达式引用多列。多列不能转换为标量值"
//   3. 解决: 用 FILTER(VALUES(user_id), FALSE()) 创建与目标表列名
//      相同的空表，确保 IF 两分支结构一致
// ═══════════════════════════════════════════════════════════════
VAR __EmptyUsers = FILTER(VALUES('a03_e2e_customer_data_m'[user_id]), FALSE())   // 列名为 user_id 的空表

VAR __Users_New_Net =
    CALCULATETABLE(
        VALUES('a03_e2e_customer_data_m'[user_id]),
        'a03_e2e_customer_data_m'[is_member] = 0,
        'a03_e2e_customer_data_m'[net_pay_amt] > 0,
        'a03_e2e_customer_data_m'[lp_12m_net_pay_amt] = 0,
        'a03_e2e_customer_data_m'[data_date] >= __StartPeriodMin,
        'a03_e2e_customer_data_m'[data_date] <= __StartPeriodMax
    )
VAR __Users_New_Demand =
    CALCULATETABLE(
        VALUES('a03_e2e_customer_data_m'[user_id]),
        'a03_e2e_customer_data_m'[is_member] = 0,
        'a03_e2e_customer_data_m'[pay_amt] > 0,
        'a03_e2e_customer_data_m'[lp_12m_pay_amt] = 0,
        'a03_e2e_customer_data_m'[data_date] >= __StartPeriodMin,
        'a03_e2e_customer_data_m'[data_date] <= __StartPeriodMax
    )
VAR __Users_Existing_Net =
    CALCULATETABLE(
        VALUES('a03_e2e_customer_data_m'[user_id]),
        'a03_e2e_customer_data_m'[is_member] = 0,
        'a03_e2e_customer_data_m'[net_pay_amt] > 0,
        'a03_e2e_customer_data_m'[lp_12m_net_pay_amt] > 0,
        'a03_e2e_customer_data_m'[data_date] >= __StartPeriodMin,
        'a03_e2e_customer_data_m'[data_date] <= __StartPeriodMax
    )
VAR __Users_Existing_Demand =
    CALCULATETABLE(
        VALUES('a03_e2e_customer_data_m'[user_id]),
        'a03_e2e_customer_data_m'[is_member] = 0,
        'a03_e2e_customer_data_m'[pay_amt] > 0,
        'a03_e2e_customer_data_m'[lp_12m_pay_amt] > 0,
        'a03_e2e_customer_data_m'[data_date] >= __StartPeriodMin,
        'a03_e2e_customer_data_m'[data_date] <= __StartPeriodMax
    )
VAR __TargetUserIDs =
    // 用 UNION+FILTER 替代嵌套 IF，确保 VAR 解析为表类型
    // 原因: 嵌套 IF 返回表时 DAX 引擎会把表达式降级为标量，导致 TREATAS 报错
    //       "TREATAS 函数要求参数使用一个表表达式，实际使用的却是字符串或数值表达式"
    //       UNION/FILTER 始终返回表类型，规避类型推断问题
    UNION(
        FILTER(__Users_New_Net,         NOT __IsAll && __CustomerType = "New"      && __RowCode = "Net"),
        FILTER(__Users_New_Demand,      NOT __IsAll && __CustomerType = "New"      && __RowCode = "Demand"),
        FILTER(__Users_Existing_Net,    NOT __IsAll && __CustomerType = "Existing" && __RowCode = "Net"),
        FILTER(__Users_Existing_Demand, NOT __IsAll && __CustomerType = "Existing" && __RowCode = "Demand"),
        FILTER(__EmptyUsers,            __IsAll)
    )

// ═══════════════════════════════════════════════════════════════
// Metric_ID=1: DCom SLS（销售额）
// New/Existing: SUM(amt) WHERE slicer 区间 AND is_member=0 AND user_id ∈ __TargetUserIDs
// All: SUM(amt) WHERE slicer 区间 AND is_member=0
// ═══════════════════════════════════════════════════════════════
VAR __SLS_Net =
    IF(__IsAll,
        CALCULATE(
            SUM('a03_e2e_customer_data_m'[net_pay_amt]),
            'a03_e2e_customer_data_m'[is_member] = 0,
            'a03_e2e_customer_data_m'[data_date] >= __PeriodMin,
            'a03_e2e_customer_data_m'[data_date] <= __PeriodMax
        ),
        CALCULATE(
            SUM('a03_e2e_customer_data_m'[net_pay_amt]),
            TREATAS(__TargetUserIDs, 'a03_e2e_customer_data_m'[user_id]),
            'a03_e2e_customer_data_m'[is_member] = 0,
            'a03_e2e_customer_data_m'[data_date] >= __PeriodMin,
            'a03_e2e_customer_data_m'[data_date] <= __PeriodMax
        )
    )
VAR __SLS_Demand =
    IF(__IsAll,
        CALCULATE(
            SUM('a03_e2e_customer_data_m'[pay_amt]),
            'a03_e2e_customer_data_m'[is_member] = 0,
            'a03_e2e_customer_data_m'[data_date] >= __PeriodMin,
            'a03_e2e_customer_data_m'[data_date] <= __PeriodMax
        ),
        CALCULATE(
            SUM('a03_e2e_customer_data_m'[pay_amt]),
            TREATAS(__TargetUserIDs, 'a03_e2e_customer_data_m'[user_id]),
            'a03_e2e_customer_data_m'[is_member] = 0,
            'a03_e2e_customer_data_m'[data_date] >= __PeriodMin,
            'a03_e2e_customer_data_m'[data_date] <= __PeriodMax
        )
    )
VAR __SLS_Act = SWITCH(__RowCode, "Net", __SLS_Net, "Demand", __SLS_Demand)

// ═══════════════════════════════════════════════════════════════
// Metric_ID=4: Customer No.（买家人数）
// New/Existing: DISTINCTCOUNT(user_id) WHERE start_period AND amt>0 AND is_member=0 AND lp_12m_*_amt 判定
//   （合并区间实现，无需 TREATAS，直接在 start_period 内判定）
// All: DISTINCTCOUNT(user_id) WHERE slicer 区间 AND amt>0 AND is_member=0
// ═══════════════════════════════════════════════════════════════
VAR __CustomerNo_Net_New_Existing =
    SWITCH(
        __CustomerType,
        "New",
            CALCULATE(
                DISTINCTCOUNT('a03_e2e_customer_data_m'[user_id]),
                'a03_e2e_customer_data_m'[is_member] = 0,
                'a03_e2e_customer_data_m'[net_pay_amt] > 0,
                'a03_e2e_customer_data_m'[lp_12m_net_pay_amt] = 0,
                'a03_e2e_customer_data_m'[data_date] >= __StartPeriodMin,
                'a03_e2e_customer_data_m'[data_date] <= __StartPeriodMax
            ),
        "Existing",
            CALCULATE(
                DISTINCTCOUNT('a03_e2e_customer_data_m'[user_id]),
                'a03_e2e_customer_data_m'[is_member] = 0,
                'a03_e2e_customer_data_m'[net_pay_amt] > 0,
                'a03_e2e_customer_data_m'[lp_12m_net_pay_amt] > 0,
                'a03_e2e_customer_data_m'[data_date] >= __StartPeriodMin,
                'a03_e2e_customer_data_m'[data_date] <= __StartPeriodMax
            ),
        BLANK()
    )
VAR __CustomerNo_Demand_New_Existing =
    SWITCH(
        __CustomerType,
        "New",
            CALCULATE(
                DISTINCTCOUNT('a03_e2e_customer_data_m'[user_id]),
                'a03_e2e_customer_data_m'[is_member] = 0,
                'a03_e2e_customer_data_m'[pay_amt] > 0,
                'a03_e2e_customer_data_m'[lp_12m_pay_amt] = 0,
                'a03_e2e_customer_data_m'[data_date] >= __StartPeriodMin,
                'a03_e2e_customer_data_m'[data_date] <= __StartPeriodMax
            ),
        "Existing",
            CALCULATE(
                DISTINCTCOUNT('a03_e2e_customer_data_m'[user_id]),
                'a03_e2e_customer_data_m'[is_member] = 0,
                'a03_e2e_customer_data_m'[pay_amt] > 0,
                'a03_e2e_customer_data_m'[lp_12m_pay_amt] > 0,
                'a03_e2e_customer_data_m'[data_date] >= __StartPeriodMin,
                'a03_e2e_customer_data_m'[data_date] <= __StartPeriodMax
            ),
        BLANK()
    )
VAR __CustomerNo_Net_All =
    CALCULATE(
        DISTINCTCOUNT('a03_e2e_customer_data_m'[user_id]),
        'a03_e2e_customer_data_m'[is_member] = 0,
        'a03_e2e_customer_data_m'[net_pay_amt] > 0,
        'a03_e2e_customer_data_m'[data_date] >= __PeriodMin,
        'a03_e2e_customer_data_m'[data_date] <= __PeriodMax
    )
VAR __CustomerNo_Demand_All =
    CALCULATE(
        DISTINCTCOUNT('a03_e2e_customer_data_m'[user_id]),
        'a03_e2e_customer_data_m'[is_member] = 0,
        'a03_e2e_customer_data_m'[pay_amt] > 0,
        'a03_e2e_customer_data_m'[data_date] >= __PeriodMin,
        'a03_e2e_customer_data_m'[data_date] <= __PeriodMax
    )
VAR __CustomerNo_Act =
    SWITCH(
        __RowCode,
        "Net",    IF(__IsAll, __CustomerNo_Net_All, __CustomerNo_Net_New_Existing),
        "Demand", IF(__IsAll, __CustomerNo_Demand_All, __CustomerNo_Demand_New_Existing)
    )

// ═══════════════════════════════════════════════════════════════
// Metric_ID=7: ACV（客单价 = SUM(amt) / COUNT(DISTINCT user_id)）
// New/Existing: 分子 SUM(amt) WHERE slicer 区间 AND is_member=0 AND user_id ∈ __TargetUserIDs
//              分母 COUNT(DISTINCT user_id) WHERE slicer 区间 AND is_member=0 AND user_id ∈ __TargetUserIDs
// All: 分子 SUM(amt) WHERE slicer 区间 AND is_member=0
//      分母 COUNT(DISTINCT user_id) WHERE slicer 区间 AND amt>0 AND is_member=0
// ═══════════════════════════════════════════════════════════════
VAR __ACV_Net_Num =
    IF(__IsAll,
        CALCULATE(
            SUM('a03_e2e_customer_data_m'[net_pay_amt]),
            'a03_e2e_customer_data_m'[is_member] = 0,
            'a03_e2e_customer_data_m'[data_date] >= __PeriodMin,
            'a03_e2e_customer_data_m'[data_date] <= __PeriodMax
        ),
        CALCULATE(
            SUM('a03_e2e_customer_data_m'[net_pay_amt]),
            TREATAS(__TargetUserIDs, 'a03_e2e_customer_data_m'[user_id]),
            'a03_e2e_customer_data_m'[is_member] = 0,
            'a03_e2e_customer_data_m'[data_date] >= __PeriodMin,
            'a03_e2e_customer_data_m'[data_date] <= __PeriodMax
        )
    )
VAR __ACV_Net_Den =
    IF(__IsAll,
        CALCULATE(
            DISTINCTCOUNT('a03_e2e_customer_data_m'[user_id]),
            'a03_e2e_customer_data_m'[is_member] = 0,
            'a03_e2e_customer_data_m'[net_pay_amt] > 0,
            'a03_e2e_customer_data_m'[data_date] >= __PeriodMin,
            'a03_e2e_customer_data_m'[data_date] <= __PeriodMax
        ),
        CALCULATE(
            DISTINCTCOUNT('a03_e2e_customer_data_m'[user_id]),
            TREATAS(__TargetUserIDs, 'a03_e2e_customer_data_m'[user_id]),
            'a03_e2e_customer_data_m'[is_member] = 0,
            'a03_e2e_customer_data_m'[data_date] >= __PeriodMin,
            'a03_e2e_customer_data_m'[data_date] <= __PeriodMax
        )
    )
VAR __ACV_Demand_Num =
    IF(__IsAll,
        CALCULATE(
            SUM('a03_e2e_customer_data_m'[pay_amt]),
            'a03_e2e_customer_data_m'[is_member] = 0,
            'a03_e2e_customer_data_m'[data_date] >= __PeriodMin,
            'a03_e2e_customer_data_m'[data_date] <= __PeriodMax
        ),
        CALCULATE(
            SUM('a03_e2e_customer_data_m'[pay_amt]),
            TREATAS(__TargetUserIDs, 'a03_e2e_customer_data_m'[user_id]),
            'a03_e2e_customer_data_m'[is_member] = 0,
            'a03_e2e_customer_data_m'[data_date] >= __PeriodMin,
            'a03_e2e_customer_data_m'[data_date] <= __PeriodMax
        )
    )
VAR __ACV_Demand_Den =
    IF(__IsAll,
        CALCULATE(
            DISTINCTCOUNT('a03_e2e_customer_data_m'[user_id]),
            'a03_e2e_customer_data_m'[is_member] = 0,
            'a03_e2e_customer_data_m'[pay_amt] > 0,
            'a03_e2e_customer_data_m'[data_date] >= __PeriodMin,
            'a03_e2e_customer_data_m'[data_date] <= __PeriodMax
        ),
        CALCULATE(
            DISTINCTCOUNT('a03_e2e_customer_data_m'[user_id]),
            TREATAS(__TargetUserIDs, 'a03_e2e_customer_data_m'[user_id]),
            'a03_e2e_customer_data_m'[is_member] = 0,
            'a03_e2e_customer_data_m'[data_date] >= __PeriodMin,
            'a03_e2e_customer_data_m'[data_date] <= __PeriodMax
        )
    )
VAR __ACV_Act =
    SWITCH(
        __RowCode,
        "Net",    DIVIDE(__ACV_Net_Num, __ACV_Net_Den),
        "Demand", DIVIDE(__ACV_Demand_Num, __ACV_Demand_Den)
    )

// ═══════════════════════════════════════════════════════════════
// Metric_ID=10: AUR（件单价 = SUM(amt) / SUM(qty)）
// New/Existing: 分子/分母均 WHERE slicer 区间 AND is_member=0 AND user_id ∈ __TargetUserIDs
// All: 分子/分母均 WHERE slicer 区间 AND is_member=0
// ═══════════════════════════════════════════════════════════════
VAR __AUR_Net_Num =
    IF(__IsAll,
        CALCULATE(
            SUM('a03_e2e_customer_data_m'[net_pay_amt]),
            'a03_e2e_customer_data_m'[is_member] = 0,
            'a03_e2e_customer_data_m'[data_date] >= __PeriodMin,
            'a03_e2e_customer_data_m'[data_date] <= __PeriodMax
        ),
        CALCULATE(
            SUM('a03_e2e_customer_data_m'[net_pay_amt]),
            TREATAS(__TargetUserIDs, 'a03_e2e_customer_data_m'[user_id]),
            'a03_e2e_customer_data_m'[is_member] = 0,
            'a03_e2e_customer_data_m'[data_date] >= __PeriodMin,
            'a03_e2e_customer_data_m'[data_date] <= __PeriodMax
        )
    )
VAR __AUR_Net_Den =
    IF(__IsAll,
        CALCULATE(
            SUM('a03_e2e_customer_data_m'[net_pay_qty]),
            'a03_e2e_customer_data_m'[is_member] = 0,
            'a03_e2e_customer_data_m'[data_date] >= __PeriodMin,
            'a03_e2e_customer_data_m'[data_date] <= __PeriodMax
        ),
        CALCULATE(
            SUM('a03_e2e_customer_data_m'[net_pay_qty]),
            TREATAS(__TargetUserIDs, 'a03_e2e_customer_data_m'[user_id]),
            'a03_e2e_customer_data_m'[is_member] = 0,
            'a03_e2e_customer_data_m'[data_date] >= __PeriodMin,
            'a03_e2e_customer_data_m'[data_date] <= __PeriodMax
        )
    )
VAR __AUR_Demand_Num =
    IF(__IsAll,
        CALCULATE(
            SUM('a03_e2e_customer_data_m'[pay_amt]),
            'a03_e2e_customer_data_m'[is_member] = 0,
            'a03_e2e_customer_data_m'[data_date] >= __PeriodMin,
            'a03_e2e_customer_data_m'[data_date] <= __PeriodMax
        ),
        CALCULATE(
            SUM('a03_e2e_customer_data_m'[pay_amt]),
            TREATAS(__TargetUserIDs, 'a03_e2e_customer_data_m'[user_id]),
            'a03_e2e_customer_data_m'[is_member] = 0,
            'a03_e2e_customer_data_m'[data_date] >= __PeriodMin,
            'a03_e2e_customer_data_m'[data_date] <= __PeriodMax
        )
    )
VAR __AUR_Demand_Den =
    IF(__IsAll,
        CALCULATE(
            SUM('a03_e2e_customer_data_m'[pay_qty]),
            'a03_e2e_customer_data_m'[is_member] = 0,
            'a03_e2e_customer_data_m'[data_date] >= __PeriodMin,
            'a03_e2e_customer_data_m'[data_date] <= __PeriodMax
        ),
        CALCULATE(
            SUM('a03_e2e_customer_data_m'[pay_qty]),
            TREATAS(__TargetUserIDs, 'a03_e2e_customer_data_m'[user_id]),
            'a03_e2e_customer_data_m'[is_member] = 0,
            'a03_e2e_customer_data_m'[data_date] >= __PeriodMin,
            'a03_e2e_customer_data_m'[data_date] <= __PeriodMax
        )
    )
VAR __AUR_Act =
    SWITCH(
        __RowCode,
        "Net",    DIVIDE(__AUR_Net_Num, __AUR_Net_Den),
        "Demand", DIVIDE(__AUR_Demand_Num, __AUR_Demand_Den)
    )

// ═══════════════════════════════════════════════════════════════
// Metric_ID=13: Freq.（购买频次 = SUM(order_cnt) / COUNT(DISTINCT user_id)）
// New/Existing: 分子/分母均 WHERE slicer 区间 AND is_member=0 AND user_id ∈ __TargetUserIDs
// All: 分子 WHERE slicer 区间 AND is_member=0
//      分母 WHERE slicer 区间 AND amt>0 AND is_member=0
// ═══════════════════════════════════════════════════════════════
VAR __Freq_Net_Num =
    IF(__IsAll,
        CALCULATE(
            SUM('a03_e2e_customer_data_m'[net_pay_order_cnt]),
            'a03_e2e_customer_data_m'[is_member] = 0,
            'a03_e2e_customer_data_m'[data_date] >= __PeriodMin,
            'a03_e2e_customer_data_m'[data_date] <= __PeriodMax
        ),
        CALCULATE(
            SUM('a03_e2e_customer_data_m'[net_pay_order_cnt]),
            TREATAS(__TargetUserIDs, 'a03_e2e_customer_data_m'[user_id]),
            'a03_e2e_customer_data_m'[is_member] = 0,
            'a03_e2e_customer_data_m'[data_date] >= __PeriodMin,
            'a03_e2e_customer_data_m'[data_date] <= __PeriodMax
        )
    )
VAR __Freq_Net_Den =
    IF(__IsAll,
        CALCULATE(
            DISTINCTCOUNT('a03_e2e_customer_data_m'[user_id]),
            'a03_e2e_customer_data_m'[is_member] = 0,
            'a03_e2e_customer_data_m'[net_pay_amt] > 0,
            'a03_e2e_customer_data_m'[data_date] >= __PeriodMin,
            'a03_e2e_customer_data_m'[data_date] <= __PeriodMax
        ),
        CALCULATE(
            DISTINCTCOUNT('a03_e2e_customer_data_m'[user_id]),
            TREATAS(__TargetUserIDs, 'a03_e2e_customer_data_m'[user_id]),
            'a03_e2e_customer_data_m'[is_member] = 0,
            'a03_e2e_customer_data_m'[data_date] >= __PeriodMin,
            'a03_e2e_customer_data_m'[data_date] <= __PeriodMax
        )
    )
VAR __Freq_Demand_Num =
    IF(__IsAll,
        CALCULATE(
            SUM('a03_e2e_customer_data_m'[pay_order_cnt]),
            'a03_e2e_customer_data_m'[is_member] = 0,
            'a03_e2e_customer_data_m'[data_date] >= __PeriodMin,
            'a03_e2e_customer_data_m'[data_date] <= __PeriodMax
        ),
        CALCULATE(
            SUM('a03_e2e_customer_data_m'[pay_order_cnt]),
            TREATAS(__TargetUserIDs, 'a03_e2e_customer_data_m'[user_id]),
            'a03_e2e_customer_data_m'[is_member] = 0,
            'a03_e2e_customer_data_m'[data_date] >= __PeriodMin,
            'a03_e2e_customer_data_m'[data_date] <= __PeriodMax
        )
    )
VAR __Freq_Demand_Den =
    IF(__IsAll,
        CALCULATE(
            DISTINCTCOUNT('a03_e2e_customer_data_m'[user_id]),
            'a03_e2e_customer_data_m'[is_member] = 0,
            'a03_e2e_customer_data_m'[pay_amt] > 0,
            'a03_e2e_customer_data_m'[data_date] >= __PeriodMin,
            'a03_e2e_customer_data_m'[data_date] <= __PeriodMax
        ),
        CALCULATE(
            DISTINCTCOUNT('a03_e2e_customer_data_m'[user_id]),
            TREATAS(__TargetUserIDs, 'a03_e2e_customer_data_m'[user_id]),
            'a03_e2e_customer_data_m'[is_member] = 0,
            'a03_e2e_customer_data_m'[data_date] >= __PeriodMin,
            'a03_e2e_customer_data_m'[data_date] <= __PeriodMax
        )
    )
VAR __Freq_Act =
    SWITCH(
        __RowCode,
        "Net",    DIVIDE(__Freq_Net_Num, __Freq_Net_Den),
        "Demand", DIVIDE(__Freq_Demand_Num, __Freq_Demand_Den)
    )

// ═══════════════════════════════════════════════════════════════
// Metric_ID=16: UPT（客单件 = SUM(qty) / SUM(order_cnt)）
// New/Existing: 分子/分母均 WHERE slicer 区间 AND is_member=0 AND user_id ∈ __TargetUserIDs
// All: 分子/分母均 WHERE slicer 区间 AND is_member=0
// ═══════════════════════════════════════════════════════════════
VAR __UPT_Net_Num =
    IF(__IsAll,
        CALCULATE(
            SUM('a03_e2e_customer_data_m'[net_pay_qty]),
            'a03_e2e_customer_data_m'[is_member] = 0,
            'a03_e2e_customer_data_m'[data_date] >= __PeriodMin,
            'a03_e2e_customer_data_m'[data_date] <= __PeriodMax
        ),
        CALCULATE(
            SUM('a03_e2e_customer_data_m'[net_pay_qty]),
            TREATAS(__TargetUserIDs, 'a03_e2e_customer_data_m'[user_id]),
            'a03_e2e_customer_data_m'[is_member] = 0,
            'a03_e2e_customer_data_m'[data_date] >= __PeriodMin,
            'a03_e2e_customer_data_m'[data_date] <= __PeriodMax
        )
    )
VAR __UPT_Net_Den =
    IF(__IsAll,
        CALCULATE(
            SUM('a03_e2e_customer_data_m'[net_pay_order_cnt]),
            'a03_e2e_customer_data_m'[is_member] = 0,
            'a03_e2e_customer_data_m'[data_date] >= __PeriodMin,
            'a03_e2e_customer_data_m'[data_date] <= __PeriodMax
        ),
        CALCULATE(
            SUM('a03_e2e_customer_data_m'[net_pay_order_cnt]),
            TREATAS(__TargetUserIDs, 'a03_e2e_customer_data_m'[user_id]),
            'a03_e2e_customer_data_m'[is_member] = 0,
            'a03_e2e_customer_data_m'[data_date] >= __PeriodMin,
            'a03_e2e_customer_data_m'[data_date] <= __PeriodMax
        )
    )
VAR __UPT_Demand_Num =
    IF(__IsAll,
        CALCULATE(
            SUM('a03_e2e_customer_data_m'[pay_qty]),
            'a03_e2e_customer_data_m'[is_member] = 0,
            'a03_e2e_customer_data_m'[data_date] >= __PeriodMin,
            'a03_e2e_customer_data_m'[data_date] <= __PeriodMax
        ),
        CALCULATE(
            SUM('a03_e2e_customer_data_m'[pay_qty]),
            TREATAS(__TargetUserIDs, 'a03_e2e_customer_data_m'[user_id]),
            'a03_e2e_customer_data_m'[is_member] = 0,
            'a03_e2e_customer_data_m'[data_date] >= __PeriodMin,
            'a03_e2e_customer_data_m'[data_date] <= __PeriodMax
        )
    )
VAR __UPT_Demand_Den =
    IF(__IsAll,
        CALCULATE(
            SUM('a03_e2e_customer_data_m'[pay_order_cnt]),
            'a03_e2e_customer_data_m'[is_member] = 0,
            'a03_e2e_customer_data_m'[data_date] >= __PeriodMin,
            'a03_e2e_customer_data_m'[data_date] <= __PeriodMax
        ),
        CALCULATE(
            SUM('a03_e2e_customer_data_m'[pay_order_cnt]),
            TREATAS(__TargetUserIDs, 'a03_e2e_customer_data_m'[user_id]),
            'a03_e2e_customer_data_m'[is_member] = 0,
            'a03_e2e_customer_data_m'[data_date] >= __PeriodMin,
            'a03_e2e_customer_data_m'[data_date] <= __PeriodMax
        )
    )
VAR __UPT_Act =
    SWITCH(
        __RowCode,
        "Net",    DIVIDE(__UPT_Net_Num, __UPT_Net_Den),
        "Demand", DIVIDE(__UPT_Demand_Num, __UPT_Demand_Den)
    )

RETURN
    SWITCH(
        __MetricID,
        1,  __SLS_Act,          // DCom SLS
        4,  __CustomerNo_Act,   // Customer No.
        7,  __ACV_Act,          // ACV
        10, __AUR_Act,          // AUR
        13, __Freq_Act,         // Freq.
        16, __UPT_Act,          // UPT
        BLANK()
    )
```

### 4.3 Customer Performance LY Base Value（去年同期基础值）

```dax
Customer Performance LY Base Value =
// ========================================
// 度量值: Customer Performance LY Base Value
// Display Folder: Base Metrics
// 用途: 根据 Row_Code × Customer_Type × Metric_ID 三维路由到去年同期（LY）基础值（原始 RMB）
// 依赖: Slicer_Time_Frame_Min[TimeFrame_Min_LY, First_Fiscal_Month_Min_LY, First_Fiscal_Month_Max_LY],
//       Slicer_Time_Frame_Max[TimeFrame_Max_LY],
//       a03_e2e_customer_data_m
// 时间偏移: 区间对称映射（LY 区间 = [TimeFrame_Min_LY, TimeFrame_Max_LY]）
// 说明: 逻辑结构与 Act Base Value 完全一致，仅时间区间改为 LY 对应字段
// ========================================

// ── 行维度路由：Net / Demand ──
// 注意：VALUES 返回"表"，SELECTEDVALUE 返回"标量值"，字符串比较需用标量
VAR __RowCode =
    IF(
        HASONEVALUE('Dim_RowMetric_Customer_Net_Demand'[Row_Code]),
        SELECTEDVALUE('Dim_RowMetric_Customer_Net_Demand'[Row_Code]),
        "Net"
    )

// ── 客户类型路由：New / Existing / All ──
VAR __IsSingleCustomerType = HASONEVALUE(Slicer_Customer_Type_Selection[Customer_Type_ID])
VAR __CustomerType =
    IF(__IsSingleCustomerType, SELECTEDVALUE(Slicer_Customer_Type_Selection[Customer_Type_ID]), "All")
VAR __IsAll = (__CustomerType = "All")

// ── 列维度路由：Metric_ID ──
VAR __MetricID = SELECTEDVALUE('Dim_ColMetric_Customer_Performance_Indicator'[Metric_ID])

// ── LY 时间区间变量 ──
VAR __PeriodMin_LY = SELECTEDVALUE(Slicer_Time_Frame_Min[TimeFrame_Min_LY])
VAR __PeriodMax_LY = SELECTEDVALUE(Slicer_Time_Frame_Max[TimeFrame_Max_LY])
VAR __StartPeriodMin_LY = SELECTEDVALUE(Slicer_Time_Frame_Min[First_Fiscal_Month_Min_LY])
VAR __StartPeriodMax_LY = SELECTEDVALUE(Slicer_Time_Frame_Min[First_Fiscal_Month_Max_LY])

// ── New/Existing user_id 集合（在 start_period LY 内判定）──
// 注意：SWITCH 不能返回表，IF 返回表需两分支列结构一致，用 FILTER(VALUES,FALSE) 造同结构空表
VAR __EmptyUsers_LY = FILTER(VALUES('a03_e2e_customer_data_m'[user_id]), FALSE())
VAR __Users_New_Net_LY =
    CALCULATETABLE(
        VALUES('a03_e2e_customer_data_m'[user_id]),
        'a03_e2e_customer_data_m'[is_member] = 0,
        'a03_e2e_customer_data_m'[net_pay_amt] > 0,
        'a03_e2e_customer_data_m'[lp_12m_net_pay_amt] = 0,
        'a03_e2e_customer_data_m'[data_date] >= __StartPeriodMin_LY,
        'a03_e2e_customer_data_m'[data_date] <= __StartPeriodMax_LY
    )
VAR __Users_New_Demand_LY =
    CALCULATETABLE(
        VALUES('a03_e2e_customer_data_m'[user_id]),
        'a03_e2e_customer_data_m'[is_member] = 0,
        'a03_e2e_customer_data_m'[pay_amt] > 0,
        'a03_e2e_customer_data_m'[lp_12m_pay_amt] = 0,
        'a03_e2e_customer_data_m'[data_date] >= __StartPeriodMin_LY,
        'a03_e2e_customer_data_m'[data_date] <= __StartPeriodMax_LY
    )
VAR __Users_Existing_Net_LY =
    CALCULATETABLE(
        VALUES('a03_e2e_customer_data_m'[user_id]),
        'a03_e2e_customer_data_m'[is_member] = 0,
        'a03_e2e_customer_data_m'[net_pay_amt] > 0,
        'a03_e2e_customer_data_m'[lp_12m_net_pay_amt] > 0,
        'a03_e2e_customer_data_m'[data_date] >= __StartPeriodMin_LY,
        'a03_e2e_customer_data_m'[data_date] <= __StartPeriodMax_LY
    )
VAR __Users_Existing_Demand_LY =
    CALCULATETABLE(
        VALUES('a03_e2e_customer_data_m'[user_id]),
        'a03_e2e_customer_data_m'[is_member] = 0,
        'a03_e2e_customer_data_m'[pay_amt] > 0,
        'a03_e2e_customer_data_m'[lp_12m_pay_amt] > 0,
        'a03_e2e_customer_data_m'[data_date] >= __StartPeriodMin_LY,
        'a03_e2e_customer_data_m'[data_date] <= __StartPeriodMax_LY
    )
VAR __TargetUserIDs_LY =
    // UNION+FILTER 确保返回表类型，避免 IF 返回表被降级为标量
    UNION(
        FILTER(__Users_New_Net_LY,         NOT __IsAll && __CustomerType = "New"      && __RowCode = "Net"),
        FILTER(__Users_New_Demand_LY,      NOT __IsAll && __CustomerType = "New"      && __RowCode = "Demand"),
        FILTER(__Users_Existing_Net_LY,     NOT __IsAll && __CustomerType = "Existing" && __RowCode = "Net"),
        FILTER(__Users_Existing_Demand_LY, NOT __IsAll && __CustomerType = "Existing" && __RowCode = "Demand"),
        FILTER(__EmptyUsers_LY,            __IsAll)
    )

// ═══ Metric_ID=1: DCom SLS LY ═══
VAR __SLS_Net_LY =
    IF(__IsAll,
        CALCULATE(
            SUM('a03_e2e_customer_data_m'[net_pay_amt]),
            'a03_e2e_customer_data_m'[is_member] = 0,
            'a03_e2e_customer_data_m'[data_date] >= __PeriodMin_LY,
            'a03_e2e_customer_data_m'[data_date] <= __PeriodMax_LY
        ),
        CALCULATE(
            SUM('a03_e2e_customer_data_m'[net_pay_amt]),
            TREATAS(__TargetUserIDs_LY, 'a03_e2e_customer_data_m'[user_id]),
            'a03_e2e_customer_data_m'[is_member] = 0,
            'a03_e2e_customer_data_m'[data_date] >= __PeriodMin_LY,
            'a03_e2e_customer_data_m'[data_date] <= __PeriodMax_LY
        )
    )
VAR __SLS_Demand_LY =
    IF(__IsAll,
        CALCULATE(
            SUM('a03_e2e_customer_data_m'[pay_amt]),
            'a03_e2e_customer_data_m'[is_member] = 0,
            'a03_e2e_customer_data_m'[data_date] >= __PeriodMin_LY,
            'a03_e2e_customer_data_m'[data_date] <= __PeriodMax_LY
        ),
        CALCULATE(
            SUM('a03_e2e_customer_data_m'[pay_amt]),
            TREATAS(__TargetUserIDs_LY, 'a03_e2e_customer_data_m'[user_id]),
            'a03_e2e_customer_data_m'[is_member] = 0,
            'a03_e2e_customer_data_m'[data_date] >= __PeriodMin_LY,
            'a03_e2e_customer_data_m'[data_date] <= __PeriodMax_LY
        )
    )
VAR __SLS_LY = SWITCH(__RowCode, "Net", __SLS_Net_LY, "Demand", __SLS_Demand_LY)

// ═══ Metric_ID=4: Customer No. LY ═══
VAR __CustomerNo_Net_NE_LY =
    SWITCH(
        __CustomerType,
        "New",
            CALCULATE(
                DISTINCTCOUNT('a03_e2e_customer_data_m'[user_id]),
                'a03_e2e_customer_data_m'[is_member] = 0,
                'a03_e2e_customer_data_m'[net_pay_amt] > 0,
                'a03_e2e_customer_data_m'[lp_12m_net_pay_amt] = 0,
                'a03_e2e_customer_data_m'[data_date] >= __StartPeriodMin_LY,
                'a03_e2e_customer_data_m'[data_date] <= __StartPeriodMax_LY
            ),
        "Existing",
            CALCULATE(
                DISTINCTCOUNT('a03_e2e_customer_data_m'[user_id]),
                'a03_e2e_customer_data_m'[is_member] = 0,
                'a03_e2e_customer_data_m'[net_pay_amt] > 0,
                'a03_e2e_customer_data_m'[lp_12m_net_pay_amt] > 0,
                'a03_e2e_customer_data_m'[data_date] >= __StartPeriodMin_LY,
                'a03_e2e_customer_data_m'[data_date] <= __StartPeriodMax_LY
            ),
        BLANK()
    )
VAR __CustomerNo_Demand_NE_LY =
    SWITCH(
        __CustomerType,
        "New",
            CALCULATE(
                DISTINCTCOUNT('a03_e2e_customer_data_m'[user_id]),
                'a03_e2e_customer_data_m'[is_member] = 0,
                'a03_e2e_customer_data_m'[pay_amt] > 0,
                'a03_e2e_customer_data_m'[lp_12m_pay_amt] = 0,
                'a03_e2e_customer_data_m'[data_date] >= __StartPeriodMin_LY,
                'a03_e2e_customer_data_m'[data_date] <= __StartPeriodMax_LY
            ),
        "Existing",
            CALCULATE(
                DISTINCTCOUNT('a03_e2e_customer_data_m'[user_id]),
                'a03_e2e_customer_data_m'[is_member] = 0,
                'a03_e2e_customer_data_m'[pay_amt] > 0,
                'a03_e2e_customer_data_m'[lp_12m_pay_amt] > 0,
                'a03_e2e_customer_data_m'[data_date] >= __StartPeriodMin_LY,
                'a03_e2e_customer_data_m'[data_date] <= __StartPeriodMax_LY
            ),
        BLANK()
    )
VAR __CustomerNo_Net_All_LY =
    CALCULATE(
        DISTINCTCOUNT('a03_e2e_customer_data_m'[user_id]),
        'a03_e2e_customer_data_m'[is_member] = 0,
        'a03_e2e_customer_data_m'[net_pay_amt] > 0,
        'a03_e2e_customer_data_m'[data_date] >= __PeriodMin_LY,
        'a03_e2e_customer_data_m'[data_date] <= __PeriodMax_LY
    )
VAR __CustomerNo_Demand_All_LY =
    CALCULATE(
        DISTINCTCOUNT('a03_e2e_customer_data_m'[user_id]),
        'a03_e2e_customer_data_m'[is_member] = 0,
        'a03_e2e_customer_data_m'[pay_amt] > 0,
        'a03_e2e_customer_data_m'[data_date] >= __PeriodMin_LY,
        'a03_e2e_customer_data_m'[data_date] <= __PeriodMax_LY
    )
VAR __CustomerNo_LY =
    SWITCH(
        __RowCode,
        "Net",    IF(__IsAll, __CustomerNo_Net_All_LY, __CustomerNo_Net_NE_LY),
        "Demand", IF(__IsAll, __CustomerNo_Demand_All_LY, __CustomerNo_Demand_NE_LY)
    )

// ═══ Metric_ID=7: ACV LY（SUM(amt) / COUNT(DISTINCT user_id)）═══
VAR __ACV_Net_Num_LY =
    IF(__IsAll,
        CALCULATE(
            SUM('a03_e2e_customer_data_m'[net_pay_amt]),
            'a03_e2e_customer_data_m'[is_member] = 0,
            'a03_e2e_customer_data_m'[data_date] >= __PeriodMin_LY,
            'a03_e2e_customer_data_m'[data_date] <= __PeriodMax_LY
        ),
        CALCULATE(
            SUM('a03_e2e_customer_data_m'[net_pay_amt]),
            TREATAS(__TargetUserIDs_LY, 'a03_e2e_customer_data_m'[user_id]),
            'a03_e2e_customer_data_m'[is_member] = 0,
            'a03_e2e_customer_data_m'[data_date] >= __PeriodMin_LY,
            'a03_e2e_customer_data_m'[data_date] <= __PeriodMax_LY
        )
    )
VAR __ACV_Net_Den_LY =
    IF(__IsAll,
        CALCULATE(
            DISTINCTCOUNT('a03_e2e_customer_data_m'[user_id]),
            'a03_e2e_customer_data_m'[is_member] = 0,
            'a03_e2e_customer_data_m'[net_pay_amt] > 0,
            'a03_e2e_customer_data_m'[data_date] >= __PeriodMin_LY,
            'a03_e2e_customer_data_m'[data_date] <= __PeriodMax_LY
        ),
        CALCULATE(
            DISTINCTCOUNT('a03_e2e_customer_data_m'[user_id]),
            TREATAS(__TargetUserIDs_LY, 'a03_e2e_customer_data_m'[user_id]),
            'a03_e2e_customer_data_m'[is_member] = 0,
            'a03_e2e_customer_data_m'[data_date] >= __PeriodMin_LY,
            'a03_e2e_customer_data_m'[data_date] <= __PeriodMax_LY
        )
    )
VAR __ACV_Demand_Num_LY =
    IF(__IsAll,
        CALCULATE(
            SUM('a03_e2e_customer_data_m'[pay_amt]),
            'a03_e2e_customer_data_m'[is_member] = 0,
            'a03_e2e_customer_data_m'[data_date] >= __PeriodMin_LY,
            'a03_e2e_customer_data_m'[data_date] <= __PeriodMax_LY
        ),
        CALCULATE(
            SUM('a03_e2e_customer_data_m'[pay_amt]),
            TREATAS(__TargetUserIDs_LY, 'a03_e2e_customer_data_m'[user_id]),
            'a03_e2e_customer_data_m'[is_member] = 0,
            'a03_e2e_customer_data_m'[data_date] >= __PeriodMin_LY,
            'a03_e2e_customer_data_m'[data_date] <= __PeriodMax_LY
        )
    )
VAR __ACV_Demand_Den_LY =
    IF(__IsAll,
        CALCULATE(
            DISTINCTCOUNT('a03_e2e_customer_data_m'[user_id]),
            'a03_e2e_customer_data_m'[is_member] = 0,
            'a03_e2e_customer_data_m'[pay_amt] > 0,
            'a03_e2e_customer_data_m'[data_date] >= __PeriodMin_LY,
            'a03_e2e_customer_data_m'[data_date] <= __PeriodMax_LY
        ),
        CALCULATE(
            DISTINCTCOUNT('a03_e2e_customer_data_m'[user_id]),
            TREATAS(__TargetUserIDs_LY, 'a03_e2e_customer_data_m'[user_id]),
            'a03_e2e_customer_data_m'[is_member] = 0,
            'a03_e2e_customer_data_m'[data_date] >= __PeriodMin_LY,
            'a03_e2e_customer_data_m'[data_date] <= __PeriodMax_LY
        )
    )
VAR __ACV_LY =
    SWITCH(
        __RowCode,
        "Net",    DIVIDE(__ACV_Net_Num_LY, __ACV_Net_Den_LY),
        "Demand", DIVIDE(__ACV_Demand_Num_LY, __ACV_Demand_Den_LY)
    )

// ═══ Metric_ID=10: AUR LY（SUM(amt) / SUM(qty)）═══
VAR __AUR_Net_Num_LY =
    IF(__IsAll,
        CALCULATE(
            SUM('a03_e2e_customer_data_m'[net_pay_amt]),
            'a03_e2e_customer_data_m'[is_member] = 0,
            'a03_e2e_customer_data_m'[data_date] >= __PeriodMin_LY,
            'a03_e2e_customer_data_m'[data_date] <= __PeriodMax_LY
        ),
        CALCULATE(
            SUM('a03_e2e_customer_data_m'[net_pay_amt]),
            TREATAS(__TargetUserIDs_LY, 'a03_e2e_customer_data_m'[user_id]),
            'a03_e2e_customer_data_m'[is_member] = 0,
            'a03_e2e_customer_data_m'[data_date] >= __PeriodMin_LY,
            'a03_e2e_customer_data_m'[data_date] <= __PeriodMax_LY
        )
    )
VAR __AUR_Net_Den_LY =
    IF(__IsAll,
        CALCULATE(
            SUM('a03_e2e_customer_data_m'[net_pay_qty]),
            'a03_e2e_customer_data_m'[is_member] = 0,
            'a03_e2e_customer_data_m'[data_date] >= __PeriodMin_LY,
            'a03_e2e_customer_data_m'[data_date] <= __PeriodMax_LY
        ),
        CALCULATE(
            SUM('a03_e2e_customer_data_m'[net_pay_qty]),
            TREATAS(__TargetUserIDs_LY, 'a03_e2e_customer_data_m'[user_id]),
            'a03_e2e_customer_data_m'[is_member] = 0,
            'a03_e2e_customer_data_m'[data_date] >= __PeriodMin_LY,
            'a03_e2e_customer_data_m'[data_date] <= __PeriodMax_LY
        )
    )
VAR __AUR_Demand_Num_LY =
    IF(__IsAll,
        CALCULATE(
            SUM('a03_e2e_customer_data_m'[pay_amt]),
            'a03_e2e_customer_data_m'[is_member] = 0,
            'a03_e2e_customer_data_m'[data_date] >= __PeriodMin_LY,
            'a03_e2e_customer_data_m'[data_date] <= __PeriodMax_LY
        ),
        CALCULATE(
            SUM('a03_e2e_customer_data_m'[pay_amt]),
            TREATAS(__TargetUserIDs_LY, 'a03_e2e_customer_data_m'[user_id]),
            'a03_e2e_customer_data_m'[is_member] = 0,
            'a03_e2e_customer_data_m'[data_date] >= __PeriodMin_LY,
            'a03_e2e_customer_data_m'[data_date] <= __PeriodMax_LY
        )
    )
VAR __AUR_Demand_Den_LY =
    IF(__IsAll,
        CALCULATE(
            SUM('a03_e2e_customer_data_m'[pay_qty]),
            'a03_e2e_customer_data_m'[is_member] = 0,
            'a03_e2e_customer_data_m'[data_date] >= __PeriodMin_LY,
            'a03_e2e_customer_data_m'[data_date] <= __PeriodMax_LY
        ),
        CALCULATE(
            SUM('a03_e2e_customer_data_m'[pay_qty]),
            TREATAS(__TargetUserIDs_LY, 'a03_e2e_customer_data_m'[user_id]),
            'a03_e2e_customer_data_m'[is_member] = 0,
            'a03_e2e_customer_data_m'[data_date] >= __PeriodMin_LY,
            'a03_e2e_customer_data_m'[data_date] <= __PeriodMax_LY
        )
    )
VAR __AUR_LY =
    SWITCH(
        __RowCode,
        "Net",    DIVIDE(__AUR_Net_Num_LY, __AUR_Net_Den_LY),
        "Demand", DIVIDE(__AUR_Demand_Num_LY, __AUR_Demand_Den_LY)
    )

// ═══ Metric_ID=13: Freq. LY（SUM(order_cnt) / COUNT(DISTINCT user_id)）═══
VAR __Freq_Net_Num_LY =
    IF(__IsAll,
        CALCULATE(
            SUM('a03_e2e_customer_data_m'[net_pay_order_cnt]),
            'a03_e2e_customer_data_m'[is_member] = 0,
            'a03_e2e_customer_data_m'[data_date] >= __PeriodMin_LY,
            'a03_e2e_customer_data_m'[data_date] <= __PeriodMax_LY
        ),
        CALCULATE(
            SUM('a03_e2e_customer_data_m'[net_pay_order_cnt]),
            TREATAS(__TargetUserIDs_LY, 'a03_e2e_customer_data_m'[user_id]),
            'a03_e2e_customer_data_m'[is_member] = 0,
            'a03_e2e_customer_data_m'[data_date] >= __PeriodMin_LY,
            'a03_e2e_customer_data_m'[data_date] <= __PeriodMax_LY
        )
    )
VAR __Freq_Net_Den_LY =
    IF(__IsAll,
        CALCULATE(
            DISTINCTCOUNT('a03_e2e_customer_data_m'[user_id]),
            'a03_e2e_customer_data_m'[is_member] = 0,
            'a03_e2e_customer_data_m'[net_pay_amt] > 0,
            'a03_e2e_customer_data_m'[data_date] >= __PeriodMin_LY,
            'a03_e2e_customer_data_m'[data_date] <= __PeriodMax_LY
        ),
        CALCULATE(
            DISTINCTCOUNT('a03_e2e_customer_data_m'[user_id]),
            TREATAS(__TargetUserIDs_LY, 'a03_e2e_customer_data_m'[user_id]),
            'a03_e2e_customer_data_m'[is_member] = 0,
            'a03_e2e_customer_data_m'[data_date] >= __PeriodMin_LY,
            'a03_e2e_customer_data_m'[data_date] <= __PeriodMax_LY
        )
    )
VAR __Freq_Demand_Num_LY =
    IF(__IsAll,
        CALCULATE(
            SUM('a03_e2e_customer_data_m'[pay_order_cnt]),
            'a03_e2e_customer_data_m'[is_member] = 0,
            'a03_e2e_customer_data_m'[data_date] >= __PeriodMin_LY,
            'a03_e2e_customer_data_m'[data_date] <= __PeriodMax_LY
        ),
        CALCULATE(
            SUM('a03_e2e_customer_data_m'[pay_order_cnt]),
            TREATAS(__TargetUserIDs_LY, 'a03_e2e_customer_data_m'[user_id]),
            'a03_e2e_customer_data_m'[is_member] = 0,
            'a03_e2e_customer_data_m'[data_date] >= __PeriodMin_LY,
            'a03_e2e_customer_data_m'[data_date] <= __PeriodMax_LY
        )
    )
VAR __Freq_Demand_Den_LY =
    IF(__IsAll,
        CALCULATE(
            DISTINCTCOUNT('a03_e2e_customer_data_m'[user_id]),
            'a03_e2e_customer_data_m'[is_member] = 0,
            'a03_e2e_customer_data_m'[pay_amt] > 0,
            'a03_e2e_customer_data_m'[data_date] >= __PeriodMin_LY,
            'a03_e2e_customer_data_m'[data_date] <= __PeriodMax_LY
        ),
        CALCULATE(
            DISTINCTCOUNT('a03_e2e_customer_data_m'[user_id]),
            TREATAS(__TargetUserIDs_LY, 'a03_e2e_customer_data_m'[user_id]),
            'a03_e2e_customer_data_m'[is_member] = 0,
            'a03_e2e_customer_data_m'[data_date] >= __PeriodMin_LY,
            'a03_e2e_customer_data_m'[data_date] <= __PeriodMax_LY
        )
    )
VAR __Freq_LY =
    SWITCH(
        __RowCode,
        "Net",    DIVIDE(__Freq_Net_Num_LY, __Freq_Net_Den_LY),
        "Demand", DIVIDE(__Freq_Demand_Num_LY, __Freq_Demand_Den_LY)
    )

// ═══ Metric_ID=16: UPT LY（SUM(qty) / SUM(order_cnt)）═══
VAR __UPT_Net_Num_LY =
    IF(__IsAll,
        CALCULATE(
            SUM('a03_e2e_customer_data_m'[net_pay_qty]),
            'a03_e2e_customer_data_m'[is_member] = 0,
            'a03_e2e_customer_data_m'[data_date] >= __PeriodMin_LY,
            'a03_e2e_customer_data_m'[data_date] <= __PeriodMax_LY
        ),
        CALCULATE(
            SUM('a03_e2e_customer_data_m'[net_pay_qty]),
            TREATAS(__TargetUserIDs_LY, 'a03_e2e_customer_data_m'[user_id]),
            'a03_e2e_customer_data_m'[is_member] = 0,
            'a03_e2e_customer_data_m'[data_date] >= __PeriodMin_LY,
            'a03_e2e_customer_data_m'[data_date] <= __PeriodMax_LY
        )
    )
VAR __UPT_Net_Den_LY =
    IF(__IsAll,
        CALCULATE(
            SUM('a03_e2e_customer_data_m'[net_pay_order_cnt]),
            'a03_e2e_customer_data_m'[is_member] = 0,
            'a03_e2e_customer_data_m'[data_date] >= __PeriodMin_LY,
            'a03_e2e_customer_data_m'[data_date] <= __PeriodMax_LY
        ),
        CALCULATE(
            SUM('a03_e2e_customer_data_m'[net_pay_order_cnt]),
            TREATAS(__TargetUserIDs_LY, 'a03_e2e_customer_data_m'[user_id]),
            'a03_e2e_customer_data_m'[is_member] = 0,
            'a03_e2e_customer_data_m'[data_date] >= __PeriodMin_LY,
            'a03_e2e_customer_data_m'[data_date] <= __PeriodMax_LY
        )
    )
VAR __UPT_Demand_Num_LY =
    IF(__IsAll,
        CALCULATE(
            SUM('a03_e2e_customer_data_m'[pay_qty]),
            'a03_e2e_customer_data_m'[is_member] = 0,
            'a03_e2e_customer_data_m'[data_date] >= __PeriodMin_LY,
            'a03_e2e_customer_data_m'[data_date] <= __PeriodMax_LY
        ),
        CALCULATE(
            SUM('a03_e2e_customer_data_m'[pay_qty]),
            TREATAS(__TargetUserIDs_LY, 'a03_e2e_customer_data_m'[user_id]),
            'a03_e2e_customer_data_m'[is_member] = 0,
            'a03_e2e_customer_data_m'[data_date] >= __PeriodMin_LY,
            'a03_e2e_customer_data_m'[data_date] <= __PeriodMax_LY
        )
    )
VAR __UPT_Demand_Den_LY =
    IF(__IsAll,
        CALCULATE(
            SUM('a03_e2e_customer_data_m'[pay_order_cnt]),
            'a03_e2e_customer_data_m'[is_member] = 0,
            'a03_e2e_customer_data_m'[data_date] >= __PeriodMin_LY,
            'a03_e2e_customer_data_m'[data_date] <= __PeriodMax_LY
        ),
        CALCULATE(
            SUM('a03_e2e_customer_data_m'[pay_order_cnt]),
            TREATAS(__TargetUserIDs_LY, 'a03_e2e_customer_data_m'[user_id]),
            'a03_e2e_customer_data_m'[is_member] = 0,
            'a03_e2e_customer_data_m'[data_date] >= __PeriodMin_LY,
            'a03_e2e_customer_data_m'[data_date] <= __PeriodMax_LY
        )
    )
VAR __UPT_LY =
    SWITCH(
        __RowCode,
        "Net",    DIVIDE(__UPT_Net_Num_LY, __UPT_Net_Den_LY),
        "Demand", DIVIDE(__UPT_Demand_Num_LY, __UPT_Demand_Den_LY)
    )

RETURN
    SWITCH(
        __MetricID,
        1,  __SLS_LY,
        4,  __CustomerNo_LY,
        7,  __ACV_LY,
        10, __AUR_LY,
        13, __Freq_LY,
        16, __UPT_LY,
        BLANK()
    )
```

### 4.4 Customer Performance LP Base Value（上期基础值）

```dax
Customer Performance LP Base Value =
// ========================================
// 度量值: Customer Performance LP Base Value
// Display Folder: Base Metrics
// 用途: 根据 Row_Code × Customer_Type × Metric_ID 三维路由到上期（LP）基础值（原始 RMB）
// 依赖: Slicer_Time_Frame_Min[TimeFrame_Min_LP, First_Fiscal_Month_Min_LP, First_Fiscal_Month_Max_LP],
//       Slicer_Time_Frame_Max[TimeFrame_Max_LP],
//       a03_e2e_customer_data_m
// 时间偏移: 区间对称映射（LP 区间 = [TimeFrame_Min_LP, TimeFrame_Max_LP]）
// 注: LP = Last Period（上一期），按所选粒度（月/季/年）的上一期
// 说明: 逻辑结构与 Act/LY Base Value 完全一致，仅时间区间改为 LP 对应字段
// ========================================

// ── 行维度路由：Net / Demand ──
// 注意：VALUES 返回"表"，SELECTEDVALUE 返回"标量值"，字符串比较需用标量
VAR __RowCode =
    IF(
        HASONEVALUE('Dim_RowMetric_Customer_Net_Demand'[Row_Code]),
        SELECTEDVALUE('Dim_RowMetric_Customer_Net_Demand'[Row_Code]),
        "Net"
    )

// ── 客户类型路由：New / Existing / All ──
VAR __IsSingleCustomerType = HASONEVALUE(Slicer_Customer_Type_Selection[Customer_Type_ID])
VAR __CustomerType =
    IF(__IsSingleCustomerType, SELECTEDVALUE(Slicer_Customer_Type_Selection[Customer_Type_ID]), "All")
VAR __IsAll = (__CustomerType = "All")

// ── 列维度路由：Metric_ID ──
VAR __MetricID = SELECTEDVALUE('Dim_ColMetric_Customer_Performance_Indicator'[Metric_ID])

// ── LP 时间区间变量 ──
VAR __PeriodMin_LP = SELECTEDVALUE(Slicer_Time_Frame_Min[TimeFrame_Min_LP])
VAR __PeriodMax_LP = SELECTEDVALUE(Slicer_Time_Frame_Max[TimeFrame_Max_LP])
VAR __StartPeriodMin_LP = SELECTEDVALUE(Slicer_Time_Frame_Min[First_Fiscal_Month_Min_LP])
VAR __StartPeriodMax_LP = SELECTEDVALUE(Slicer_Time_Frame_Min[First_Fiscal_Month_Max_LP])

// ── New/Existing user_id 集合（在 start_period LP 内判定）──
// 注意：SWITCH 不能返回表，IF 返回表需两分支列结构一致，用 FILTER(VALUES,FALSE) 造同结构空表
VAR __EmptyUsers_LP = FILTER(VALUES('a03_e2e_customer_data_m'[user_id]), FALSE())
VAR __Users_New_Net_LP =
    CALCULATETABLE(
        VALUES('a03_e2e_customer_data_m'[user_id]),
        'a03_e2e_customer_data_m'[is_member] = 0,
        'a03_e2e_customer_data_m'[net_pay_amt] > 0,
        'a03_e2e_customer_data_m'[lp_12m_net_pay_amt] = 0,
        'a03_e2e_customer_data_m'[data_date] >= __StartPeriodMin_LP,
        'a03_e2e_customer_data_m'[data_date] <= __StartPeriodMax_LP
    )
VAR __Users_New_Demand_LP =
    CALCULATETABLE(
        VALUES('a03_e2e_customer_data_m'[user_id]),
        'a03_e2e_customer_data_m'[is_member] = 0,
        'a03_e2e_customer_data_m'[pay_amt] > 0,
        'a03_e2e_customer_data_m'[lp_12m_pay_amt] = 0,
        'a03_e2e_customer_data_m'[data_date] >= __StartPeriodMin_LP,
        'a03_e2e_customer_data_m'[data_date] <= __StartPeriodMax_LP
    )
VAR __Users_Existing_Net_LP =
    CALCULATETABLE(
        VALUES('a03_e2e_customer_data_m'[user_id]),
        'a03_e2e_customer_data_m'[is_member] = 0,
        'a03_e2e_customer_data_m'[net_pay_amt] > 0,
        'a03_e2e_customer_data_m'[lp_12m_net_pay_amt] > 0,
        'a03_e2e_customer_data_m'[data_date] >= __StartPeriodMin_LP,
        'a03_e2e_customer_data_m'[data_date] <= __StartPeriodMax_LP
    )
VAR __Users_Existing_Demand_LP =
    CALCULATETABLE(
        VALUES('a03_e2e_customer_data_m'[user_id]),
        'a03_e2e_customer_data_m'[is_member] = 0,
        'a03_e2e_customer_data_m'[pay_amt] > 0,
        'a03_e2e_customer_data_m'[lp_12m_pay_amt] > 0,
        'a03_e2e_customer_data_m'[data_date] >= __StartPeriodMin_LP,
        'a03_e2e_customer_data_m'[data_date] <= __StartPeriodMax_LP
    )
VAR __TargetUserIDs_LP =
    // UNION+FILTER 确保返回表类型，避免 IF 返回表被降级为标量
    UNION(
        FILTER(__Users_New_Net_LP,         NOT __IsAll && __CustomerType = "New"      && __RowCode = "Net"),
        FILTER(__Users_New_Demand_LP,      NOT __IsAll && __CustomerType = "New"      && __RowCode = "Demand"),
        FILTER(__Users_Existing_Net_LP,     NOT __IsAll && __CustomerType = "Existing" && __RowCode = "Net"),
        FILTER(__Users_Existing_Demand_LP, NOT __IsAll && __CustomerType = "Existing" && __RowCode = "Demand"),
        FILTER(__EmptyUsers_LP,            __IsAll)
    )

// ═══ Metric_ID=1: DCom SLS LP ═══
VAR __SLS_Net_LP =
    IF(__IsAll,
        CALCULATE(
            SUM('a03_e2e_customer_data_m'[net_pay_amt]),
            'a03_e2e_customer_data_m'[is_member] = 0,
            'a03_e2e_customer_data_m'[data_date] >= __PeriodMin_LP,
            'a03_e2e_customer_data_m'[data_date] <= __PeriodMax_LP
        ),
        CALCULATE(
            SUM('a03_e2e_customer_data_m'[net_pay_amt]),
            TREATAS(__TargetUserIDs_LP, 'a03_e2e_customer_data_m'[user_id]),
            'a03_e2e_customer_data_m'[is_member] = 0,
            'a03_e2e_customer_data_m'[data_date] >= __PeriodMin_LP,
            'a03_e2e_customer_data_m'[data_date] <= __PeriodMax_LP
        )
    )
VAR __SLS_Demand_LP =
    IF(__IsAll,
        CALCULATE(
            SUM('a03_e2e_customer_data_m'[pay_amt]),
            'a03_e2e_customer_data_m'[is_member] = 0,
            'a03_e2e_customer_data_m'[data_date] >= __PeriodMin_LP,
            'a03_e2e_customer_data_m'[data_date] <= __PeriodMax_LP
        ),
        CALCULATE(
            SUM('a03_e2e_customer_data_m'[pay_amt]),
            TREATAS(__TargetUserIDs_LP, 'a03_e2e_customer_data_m'[user_id]),
            'a03_e2e_customer_data_m'[is_member] = 0,
            'a03_e2e_customer_data_m'[data_date] >= __PeriodMin_LP,
            'a03_e2e_customer_data_m'[data_date] <= __PeriodMax_LP
        )
    )
VAR __SLS_LP = SWITCH(__RowCode, "Net", __SLS_Net_LP, "Demand", __SLS_Demand_LP)

// ═══ Metric_ID=4: Customer No. LP ═══
VAR __CustomerNo_Net_NE_LP =
    SWITCH(
        __CustomerType,
        "New",
            CALCULATE(
                DISTINCTCOUNT('a03_e2e_customer_data_m'[user_id]),
                'a03_e2e_customer_data_m'[is_member] = 0,
                'a03_e2e_customer_data_m'[net_pay_amt] > 0,
                'a03_e2e_customer_data_m'[lp_12m_net_pay_amt] = 0,
                'a03_e2e_customer_data_m'[data_date] >= __StartPeriodMin_LP,
                'a03_e2e_customer_data_m'[data_date] <= __StartPeriodMax_LP
            ),
        "Existing",
            CALCULATE(
                DISTINCTCOUNT('a03_e2e_customer_data_m'[user_id]),
                'a03_e2e_customer_data_m'[is_member] = 0,
                'a03_e2e_customer_data_m'[net_pay_amt] > 0,
                'a03_e2e_customer_data_m'[lp_12m_net_pay_amt] > 0,
                'a03_e2e_customer_data_m'[data_date] >= __StartPeriodMin_LP,
                'a03_e2e_customer_data_m'[data_date] <= __StartPeriodMax_LP
            ),
        BLANK()
    )
VAR __CustomerNo_Demand_NE_LP =
    SWITCH(
        __CustomerType,
        "New",
            CALCULATE(
                DISTINCTCOUNT('a03_e2e_customer_data_m'[user_id]),
                'a03_e2e_customer_data_m'[is_member] = 0,
                'a03_e2e_customer_data_m'[pay_amt] > 0,
                'a03_e2e_customer_data_m'[lp_12m_pay_amt] = 0,
                'a03_e2e_customer_data_m'[data_date] >= __StartPeriodMin_LP,
                'a03_e2e_customer_data_m'[data_date] <= __StartPeriodMax_LP
            ),
        "Existing",
            CALCULATE(
                DISTINCTCOUNT('a03_e2e_customer_data_m'[user_id]),
                'a03_e2e_customer_data_m'[is_member] = 0,
                'a03_e2e_customer_data_m'[pay_amt] > 0,
                'a03_e2e_customer_data_m'[lp_12m_pay_amt] > 0,
                'a03_e2e_customer_data_m'[data_date] >= __StartPeriodMin_LP,
                'a03_e2e_customer_data_m'[data_date] <= __StartPeriodMax_LP
            ),
        BLANK()
    )
VAR __CustomerNo_Net_All_LP =
    CALCULATE(
        DISTINCTCOUNT('a03_e2e_customer_data_m'[user_id]),
        'a03_e2e_customer_data_m'[is_member] = 0,
        'a03_e2e_customer_data_m'[net_pay_amt] > 0,
        'a03_e2e_customer_data_m'[data_date] >= __PeriodMin_LP,
        'a03_e2e_customer_data_m'[data_date] <= __PeriodMax_LP
    )
VAR __CustomerNo_Demand_All_LP =
    CALCULATE(
        DISTINCTCOUNT('a03_e2e_customer_data_m'[user_id]),
        'a03_e2e_customer_data_m'[is_member] = 0,
        'a03_e2e_customer_data_m'[pay_amt] > 0,
        'a03_e2e_customer_data_m'[data_date] >= __PeriodMin_LP,
        'a03_e2e_customer_data_m'[data_date] <= __PeriodMax_LP
    )
VAR __CustomerNo_LP =
    SWITCH(
        __RowCode,
        "Net",    IF(__IsAll, __CustomerNo_Net_All_LP, __CustomerNo_Net_NE_LP),
        "Demand", IF(__IsAll, __CustomerNo_Demand_All_LP, __CustomerNo_Demand_NE_LP)
    )

// ═══ Metric_ID=7: ACV LP ═══
VAR __ACV_Net_Num_LP =
    IF(__IsAll,
        CALCULATE(
            SUM('a03_e2e_customer_data_m'[net_pay_amt]),
            'a03_e2e_customer_data_m'[is_member] = 0,
            'a03_e2e_customer_data_m'[data_date] >= __PeriodMin_LP,
            'a03_e2e_customer_data_m'[data_date] <= __PeriodMax_LP
        ),
        CALCULATE(
            SUM('a03_e2e_customer_data_m'[net_pay_amt]),
            TREATAS(__TargetUserIDs_LP, 'a03_e2e_customer_data_m'[user_id]),
            'a03_e2e_customer_data_m'[is_member] = 0,
            'a03_e2e_customer_data_m'[data_date] >= __PeriodMin_LP,
            'a03_e2e_customer_data_m'[data_date] <= __PeriodMax_LP
        )
    )
VAR __ACV_Net_Den_LP =
    IF(__IsAll,
        CALCULATE(
            DISTINCTCOUNT('a03_e2e_customer_data_m'[user_id]),
            'a03_e2e_customer_data_m'[is_member] = 0,
            'a03_e2e_customer_data_m'[net_pay_amt] > 0,
            'a03_e2e_customer_data_m'[data_date] >= __PeriodMin_LP,
            'a03_e2e_customer_data_m'[data_date] <= __PeriodMax_LP
        ),
        CALCULATE(
            DISTINCTCOUNT('a03_e2e_customer_data_m'[user_id]),
            TREATAS(__TargetUserIDs_LP, 'a03_e2e_customer_data_m'[user_id]),
            'a03_e2e_customer_data_m'[is_member] = 0,
            'a03_e2e_customer_data_m'[data_date] >= __PeriodMin_LP,
            'a03_e2e_customer_data_m'[data_date] <= __PeriodMax_LP
        )
    )
VAR __ACV_Demand_Num_LP =
    IF(__IsAll,
        CALCULATE(
            SUM('a03_e2e_customer_data_m'[pay_amt]),
            'a03_e2e_customer_data_m'[is_member] = 0,
            'a03_e2e_customer_data_m'[data_date] >= __PeriodMin_LP,
            'a03_e2e_customer_data_m'[data_date] <= __PeriodMax_LP
        ),
        CALCULATE(
            SUM('a03_e2e_customer_data_m'[pay_amt]),
            TREATAS(__TargetUserIDs_LP, 'a03_e2e_customer_data_m'[user_id]),
            'a03_e2e_customer_data_m'[is_member] = 0,
            'a03_e2e_customer_data_m'[data_date] >= __PeriodMin_LP,
            'a03_e2e_customer_data_m'[data_date] <= __PeriodMax_LP
        )
    )
VAR __ACV_Demand_Den_LP =
    IF(__IsAll,
        CALCULATE(
            DISTINCTCOUNT('a03_e2e_customer_data_m'[user_id]),
            'a03_e2e_customer_data_m'[is_member] = 0,
            'a03_e2e_customer_data_m'[pay_amt] > 0,
            'a03_e2e_customer_data_m'[data_date] >= __PeriodMin_LP,
            'a03_e2e_customer_data_m'[data_date] <= __PeriodMax_LP
        ),
        CALCULATE(
            DISTINCTCOUNT('a03_e2e_customer_data_m'[user_id]),
            TREATAS(__TargetUserIDs_LP, 'a03_e2e_customer_data_m'[user_id]),
            'a03_e2e_customer_data_m'[is_member] = 0,
            'a03_e2e_customer_data_m'[data_date] >= __PeriodMin_LP,
            'a03_e2e_customer_data_m'[data_date] <= __PeriodMax_LP
        )
    )
VAR __ACV_LP =
    SWITCH(
        __RowCode,
        "Net",    DIVIDE(__ACV_Net_Num_LP, __ACV_Net_Den_LP),
        "Demand", DIVIDE(__ACV_Demand_Num_LP, __ACV_Demand_Den_LP)
    )

// ═══ Metric_ID=10: AUR LP ═══
VAR __AUR_Net_Num_LP =
    IF(__IsAll,
        CALCULATE(
            SUM('a03_e2e_customer_data_m'[net_pay_amt]),
            'a03_e2e_customer_data_m'[is_member] = 0,
            'a03_e2e_customer_data_m'[data_date] >= __PeriodMin_LP,
            'a03_e2e_customer_data_m'[data_date] <= __PeriodMax_LP
        ),
        CALCULATE(
            SUM('a03_e2e_customer_data_m'[net_pay_amt]),
            TREATAS(__TargetUserIDs_LP, 'a03_e2e_customer_data_m'[user_id]),
            'a03_e2e_customer_data_m'[is_member] = 0,
            'a03_e2e_customer_data_m'[data_date] >= __PeriodMin_LP,
            'a03_e2e_customer_data_m'[data_date] <= __PeriodMax_LP
        )
    )
VAR __AUR_Net_Den_LP =
    IF(__IsAll,
        CALCULATE(
            SUM('a03_e2e_customer_data_m'[net_pay_qty]),
            'a03_e2e_customer_data_m'[is_member] = 0,
            'a03_e2e_customer_data_m'[data_date] >= __PeriodMin_LP,
            'a03_e2e_customer_data_m'[data_date] <= __PeriodMax_LP
        ),
        CALCULATE(
            SUM('a03_e2e_customer_data_m'[net_pay_qty]),
            TREATAS(__TargetUserIDs_LP, 'a03_e2e_customer_data_m'[user_id]),
            'a03_e2e_customer_data_m'[is_member] = 0,
            'a03_e2e_customer_data_m'[data_date] >= __PeriodMin_LP,
            'a03_e2e_customer_data_m'[data_date] <= __PeriodMax_LP
        )
    )
VAR __AUR_Demand_Num_LP =
    IF(__IsAll,
        CALCULATE(
            SUM('a03_e2e_customer_data_m'[pay_amt]),
            'a03_e2e_customer_data_m'[is_member] = 0,
            'a03_e2e_customer_data_m'[data_date] >= __PeriodMin_LP,
            'a03_e2e_customer_data_m'[data_date] <= __PeriodMax_LP
        ),
        CALCULATE(
            SUM('a03_e2e_customer_data_m'[pay_amt]),
            TREATAS(__TargetUserIDs_LP, 'a03_e2e_customer_data_m'[user_id]),
            'a03_e2e_customer_data_m'[is_member] = 0,
            'a03_e2e_customer_data_m'[data_date] >= __PeriodMin_LP,
            'a03_e2e_customer_data_m'[data_date] <= __PeriodMax_LP
        )
    )
VAR __AUR_Demand_Den_LP =
    IF(__IsAll,
        CALCULATE(
            SUM('a03_e2e_customer_data_m'[pay_qty]),
            'a03_e2e_customer_data_m'[is_member] = 0,
            'a03_e2e_customer_data_m'[data_date] >= __PeriodMin_LP,
            'a03_e2e_customer_data_m'[data_date] <= __PeriodMax_LP
        ),
        CALCULATE(
            SUM('a03_e2e_customer_data_m'[pay_qty]),
            TREATAS(__TargetUserIDs_LP, 'a03_e2e_customer_data_m'[user_id]),
            'a03_e2e_customer_data_m'[is_member] = 0,
            'a03_e2e_customer_data_m'[data_date] >= __PeriodMin_LP,
            'a03_e2e_customer_data_m'[data_date] <= __PeriodMax_LP
        )
    )
VAR __AUR_LP =
    SWITCH(
        __RowCode,
        "Net",    DIVIDE(__AUR_Net_Num_LP, __AUR_Net_Den_LP),
        "Demand", DIVIDE(__AUR_Demand_Num_LP, __AUR_Demand_Den_LP)
    )

// ═══ Metric_ID=13: Freq. LP ═══
VAR __Freq_Net_Num_LP =
    IF(__IsAll,
        CALCULATE(
            SUM('a03_e2e_customer_data_m'[net_pay_order_cnt]),
            'a03_e2e_customer_data_m'[is_member] = 0,
            'a03_e2e_customer_data_m'[data_date] >= __PeriodMin_LP,
            'a03_e2e_customer_data_m'[data_date] <= __PeriodMax_LP
        ),
        CALCULATE(
            SUM('a03_e2e_customer_data_m'[net_pay_order_cnt]),
            TREATAS(__TargetUserIDs_LP, 'a03_e2e_customer_data_m'[user_id]),
            'a03_e2e_customer_data_m'[is_member] = 0,
            'a03_e2e_customer_data_m'[data_date] >= __PeriodMin_LP,
            'a03_e2e_customer_data_m'[data_date] <= __PeriodMax_LP
        )
    )
VAR __Freq_Net_Den_LP =
    IF(__IsAll,
        CALCULATE(
            DISTINCTCOUNT('a03_e2e_customer_data_m'[user_id]),
            'a03_e2e_customer_data_m'[is_member] = 0,
            'a03_e2e_customer_data_m'[net_pay_amt] > 0,
            'a03_e2e_customer_data_m'[data_date] >= __PeriodMin_LP,
            'a03_e2e_customer_data_m'[data_date] <= __PeriodMax_LP
        ),
        CALCULATE(
            DISTINCTCOUNT('a03_e2e_customer_data_m'[user_id]),
            TREATAS(__TargetUserIDs_LP, 'a03_e2e_customer_data_m'[user_id]),
            'a03_e2e_customer_data_m'[is_member] = 0,
            'a03_e2e_customer_data_m'[data_date] >= __PeriodMin_LP,
            'a03_e2e_customer_data_m'[data_date] <= __PeriodMax_LP
        )
    )
VAR __Freq_Demand_Num_LP =
    IF(__IsAll,
        CALCULATE(
            SUM('a03_e2e_customer_data_m'[pay_order_cnt]),
            'a03_e2e_customer_data_m'[is_member] = 0,
            'a03_e2e_customer_data_m'[data_date] >= __PeriodMin_LP,
            'a03_e2e_customer_data_m'[data_date] <= __PeriodMax_LP
        ),
        CALCULATE(
            SUM('a03_e2e_customer_data_m'[pay_order_cnt]),
            TREATAS(__TargetUserIDs_LP, 'a03_e2e_customer_data_m'[user_id]),
            'a03_e2e_customer_data_m'[is_member] = 0,
            'a03_e2e_customer_data_m'[data_date] >= __PeriodMin_LP,
            'a03_e2e_customer_data_m'[data_date] <= __PeriodMax_LP
        )
    )
VAR __Freq_Demand_Den_LP =
    IF(__IsAll,
        CALCULATE(
            DISTINCTCOUNT('a03_e2e_customer_data_m'[user_id]),
            'a03_e2e_customer_data_m'[is_member] = 0,
            'a03_e2e_customer_data_m'[pay_amt] > 0,
            'a03_e2e_customer_data_m'[data_date] >= __PeriodMin_LP,
            'a03_e2e_customer_data_m'[data_date] <= __PeriodMax_LP
        ),
        CALCULATE(
            DISTINCTCOUNT('a03_e2e_customer_data_m'[user_id]),
            TREATAS(__TargetUserIDs_LP, 'a03_e2e_customer_data_m'[user_id]),
            'a03_e2e_customer_data_m'[is_member] = 0,
            'a03_e2e_customer_data_m'[data_date] >= __PeriodMin_LP,
            'a03_e2e_customer_data_m'[data_date] <= __PeriodMax_LP
        )
    )
VAR __Freq_LP =
    SWITCH(
        __RowCode,
        "Net",    DIVIDE(__Freq_Net_Num_LP, __Freq_Net_Den_LP),
        "Demand", DIVIDE(__Freq_Demand_Num_LP, __Freq_Demand_Den_LP)
    )

// ═══ Metric_ID=16: UPT LP ═══
VAR __UPT_Net_Num_LP =
    IF(__IsAll,
        CALCULATE(
            SUM('a03_e2e_customer_data_m'[net_pay_qty]),
            'a03_e2e_customer_data_m'[is_member] = 0,
            'a03_e2e_customer_data_m'[data_date] >= __PeriodMin_LP,
            'a03_e2e_customer_data_m'[data_date] <= __PeriodMax_LP
        ),
        CALCULATE(
            SUM('a03_e2e_customer_data_m'[net_pay_qty]),
            TREATAS(__TargetUserIDs_LP, 'a03_e2e_customer_data_m'[user_id]),
            'a03_e2e_customer_data_m'[is_member] = 0,
            'a03_e2e_customer_data_m'[data_date] >= __PeriodMin_LP,
            'a03_e2e_customer_data_m'[data_date] <= __PeriodMax_LP
        )
    )
VAR __UPT_Net_Den_LP =
    IF(__IsAll,
        CALCULATE(
            SUM('a03_e2e_customer_data_m'[net_pay_order_cnt]),
            'a03_e2e_customer_data_m'[is_member] = 0,
            'a03_e2e_customer_data_m'[data_date] >= __PeriodMin_LP,
            'a03_e2e_customer_data_m'[data_date] <= __PeriodMax_LP
        ),
        CALCULATE(
            SUM('a03_e2e_customer_data_m'[net_pay_order_cnt]),
            TREATAS(__TargetUserIDs_LP, 'a03_e2e_customer_data_m'[user_id]),
            'a03_e2e_customer_data_m'[is_member] = 0,
            'a03_e2e_customer_data_m'[data_date] >= __PeriodMin_LP,
            'a03_e2e_customer_data_m'[data_date] <= __PeriodMax_LP
        )
    )
VAR __UPT_Demand_Num_LP =
    IF(__IsAll,
        CALCULATE(
            SUM('a03_e2e_customer_data_m'[pay_qty]),
            'a03_e2e_customer_data_m'[is_member] = 0,
            'a03_e2e_customer_data_m'[data_date] >= __PeriodMin_LP,
            'a03_e2e_customer_data_m'[data_date] <= __PeriodMax_LP
        ),
        CALCULATE(
            SUM('a03_e2e_customer_data_m'[pay_qty]),
            TREATAS(__TargetUserIDs_LP, 'a03_e2e_customer_data_m'[user_id]),
            'a03_e2e_customer_data_m'[is_member] = 0,
            'a03_e2e_customer_data_m'[data_date] >= __PeriodMin_LP,
            'a03_e2e_customer_data_m'[data_date] <= __PeriodMax_LP
        )
    )
VAR __UPT_Demand_Den_LP =
    IF(__IsAll,
        CALCULATE(
            SUM('a03_e2e_customer_data_m'[pay_order_cnt]),
            'a03_e2e_customer_data_m'[is_member] = 0,
            'a03_e2e_customer_data_m'[data_date] >= __PeriodMin_LP,
            'a03_e2e_customer_data_m'[data_date] <= __PeriodMax_LP
        ),
        CALCULATE(
            SUM('a03_e2e_customer_data_m'[pay_order_cnt]),
            TREATAS(__TargetUserIDs_LP, 'a03_e2e_customer_data_m'[user_id]),
            'a03_e2e_customer_data_m'[is_member] = 0,
            'a03_e2e_customer_data_m'[data_date] >= __PeriodMin_LP,
            'a03_e2e_customer_data_m'[data_date] <= __PeriodMax_LP
        )
    )
VAR __UPT_LP =
    SWITCH(
        __RowCode,
        "Net",    DIVIDE(__UPT_Net_Num_LP, __UPT_Net_Den_LP),
        "Demand", DIVIDE(__UPT_Demand_Num_LP, __UPT_Demand_Den_LP)
    )

RETURN
    SWITCH(
        __MetricID,
        1,  __SLS_LP,
        4,  __CustomerNo_LP,
        7,  __ACV_LP,
        10, __AUR_LP,
        13, __Freq_LP,
        16, __UPT_LP,
        BLANK()
    )
```

### 4.5 Customer Performance Base Value（总路由）

```dax
Customer Performance Base Value =
// ========================================
// 度量值: Customer Performance Base Value
// Display Folder: Base Metrics
// 用途: 总路由，按 Metric_ID 分发到 Act / vs LY / vs LP
// 依赖: [Customer Performance Act Base Value],
//       [Customer Performance LY Base Value],
//       [Customer Performance LP Base Value],
//       'Dim_ColMetric_Customer_Performance_Indicator'[Metric_ID]
//
// Metric_ID 路由规则（18 列，6 分组 × 3 指标）:
//   Act 基础指标 ID: 1, 4, 7, 10, 13, 16
//   vs LY 派生 ID  : 2, 5, 8, 11, 14, 17
//   vs LP 派生 ID  : 3, 6, 9, 12, 15, 18
//
// 派生规则（全部为比率 delta_pct_0dp，即 今年/去年-1 或 当期/上期-1）:
//   - vs LY = Act / LY - 1   (Metric_ID: 2→1, 5→4, 8→7, 11→10, 14→13, 17→16)
//   - vs LP = Act / LP - 1   (Metric_ID: 3→1, 6→4, 9→7, 12→10, 15→13, 18→16)
//   全部为比率类指标变化百分比，无 pts 类型，统一 delta_pct_0dp 格式
//
// REMOVEFILTERS 机制:
//   派生行需先 REMOVEFILTERS 清除断开维度的所有筛选，再应用目标 Metric_ID，
//   否则矩阵行/列标题保留的筛选器会导致冲突返回 BLANK。
//
// 路由目标 ID 映射表（严格遵循口径文档）:
//   ┌────────────┬──────┬─────────┬─────────┐
//   │ KPI Group  │ Act  │ vs LY   │ vs LP   │
//   ├────────────┼──────┼─────────┼─────────┤
//   │ DCom SLS   │  1   │  2→1    │  3→1    │
//   │ Customer No│  4   │  5→4    │  6→4    │
//   │ ACV        │  7   │  8→7    │  9→7    │
//   │ AUR        │ 10   │ 11→10   │ 12→10   │
//   │ Freq.      │ 13   │ 14→13   │ 15→13   │
//   │ UPT        │ 16   │ 17→16   │ 18→16   │
//   └────────────┴──────┴─────────┴─────────┘
// ========================================
    VAR __MetricID = SELECTEDVALUE('Dim_ColMetric_Customer_Performance_Indicator'[Metric_ID])

    // ═══════════════════════════════════════
    // vs LY 派生：今年 / 去年 - 1
    // 路由映射: 2→1, 5→4, 8→7, 11→10, 14→13, 17→16
    // ═══════════════════════════════════════
    VAR __IsVsLY = __MetricID IN {2, 5, 8, 11, 14, 17}
    VAR __ActMetricID_ForLY =
        SWITCH(__MetricID,
            2,  1,    // DCom SLS vs LY → SLS Act
            5,  4,    // Customer No. vs LY → Customer No. Act
            8,  7,    // ACV vs LY → ACV Act
            11, 10,   // AUR vs LY → AUR Act
            14, 13,   // Freq. vs LY → Freq. Act
            17, 16    // UPT vs LY → UPT Act
        )
    VAR __ActValue_LY =
        IF(
            __IsVsLY,
            CALCULATE(
                [Customer Performance Act Base Value],
                REMOVEFILTERS('Dim_ColMetric_Customer_Performance_Indicator'),
                'Dim_ColMetric_Customer_Performance_Indicator'[Metric_ID] = __ActMetricID_ForLY
            )
        )
    VAR __LYValue =
        IF(
            __IsVsLY,
            CALCULATE(
                [Customer Performance LY Base Value],
                REMOVEFILTERS('Dim_ColMetric_Customer_Performance_Indicator'),
                'Dim_ColMetric_Customer_Performance_Indicator'[Metric_ID] = __ActMetricID_ForLY
            )
        )
    VAR __VsLYResult =
        IF(
            ISBLANK(__LYValue) || __LYValue = 0,
            BLANK(),
            DIVIDE(__ActValue_LY, __LYValue) - 1
        )

    // ═══════════════════════════════════════
    // vs LP 派生：当期 / 上期 - 1
    // 路由映射: 3→1, 6→4, 9→7, 12→10, 15→13, 18→16
    // ═══════════════════════════════════════
    VAR __IsVsLP = __MetricID IN {3, 6, 9, 12, 15, 18}
    VAR __ActMetricID_ForLP =
        SWITCH(__MetricID,
            3,  1,    // DCom SLS vs LP → SLS Act
            6,  4,    // Customer No. vs LP → Customer No. Act
            9,  7,    // ACV vs LP → ACV Act
            12, 10,   // AUR vs LP → AUR Act
            15, 13,   // Freq. vs LP → Freq. Act
            18, 16    // UPT vs LP → UPT Act
        )
    VAR __ActValue_LP =
        IF(
            __IsVsLP,
            CALCULATE(
                [Customer Performance Act Base Value],
                REMOVEFILTERS('Dim_ColMetric_Customer_Performance_Indicator'),
                'Dim_ColMetric_Customer_Performance_Indicator'[Metric_ID] = __ActMetricID_ForLP
            )
        )
    VAR __LPValue =
        IF(
            __IsVsLP,
            CALCULATE(
                [Customer Performance LP Base Value],
                REMOVEFILTERS('Dim_ColMetric_Customer_Performance_Indicator'),
                'Dim_ColMetric_Customer_Performance_Indicator'[Metric_ID] = __ActMetricID_ForLP
            )
        )
    VAR __VsLPResult =
        IF(
            ISBLANK(__LPValue) || __LPValue = 0,
            BLANK(),
            DIVIDE(__ActValue_LP, __LPValue) - 1
        )

    RETURN
        SWITCH(
            __MetricID,
            // ─── Act 基础指标（6 个）───
            1,  [Customer Performance Act Base Value],    // DCom SLS Act
            4,  [Customer Performance Act Base Value],    // Customer No. Act
            7,  [Customer Performance Act Base Value],    // ACV Act
            10, [Customer Performance Act Base Value],    // AUR Act
            13, [Customer Performance Act Base Value],    // Freq. Act
            16, [Customer Performance Act Base Value],    // UPT Act
            // ─── vs LY 派生（6 个，今年 / 去年 - 1）───
            2,  __VsLYResult,                             // DCom SLS vs LY
            5,  __VsLYResult,                             // Customer No. vs LY
            8,  __VsLYResult,                             // ACV vs LY
            11, __VsLYResult,                             // AUR vs LY
            14, __VsLYResult,                             // Freq. vs LY
            17, __VsLYResult,                             // UPT vs LY
            // ─── vs LP 派生（6 个，当期 / 上期 - 1）───
            3,  __VsLPResult,                             // DCom SLS vs LP
            6,  __VsLPResult,                             // Customer No. vs LP
            9,  __VsLPResult,                             // ACV vs LP
            12, __VsLPResult,                             // AUR vs LP
            15, __VsLPResult,                             // Freq. vs LP
            18, __VsLPResult,                             // UPT vs LP
            BLANK()
        )
```

### 4.6 Customer Performance Cell Value（对外值，含汇率换算）

```dax
Customer Performance Cell Value =
// ========================================
// 度量值: Customer Performance Cell Value
// Display Folder: Cell Values
// 用途: 对外暴露的单元格值
//       - 金额类 Act（Metric_IsCurrencyAmount=TRUE, ColType="Act"）：按 Slicer_Currency_Selection 汇率换算
//       - 非金额类 或 vs LY/vs LP（比率，无量纲）：直接返回 Base Value，不换算
// 依赖: [Customer Performance Base Value],
//       'Dim_ColMetric_Customer_Performance_Indicator'[Metric_IsCurrencyAmount, ColType],
//       Slicer_Currency_Selection[Currency_ExchangeRate]
//
// 汇率换算规则:
//   - 数据底表存储 RMB 原始值，USD 时通过 ÷ Currency_ExchangeRate 换算
//   - RMB 时 Currency_ExchangeRate = 1，换算前后值相同
//   - 仅金额类 Act 触发换算（vs LY/vs LP 为比率 delta，不涉及换算）
//   - Base Value 层始终保留 RMB 原始值，确保派生计算口径一致
// ========================================
    VAR __BaseValue = [Customer Performance Base Value]
    VAR __IsCurrencyAmount = SELECTEDVALUE('Dim_ColMetric_Customer_Performance_Indicator'[Metric_IsCurrencyAmount], FALSE)
    VAR __ColType = SELECTEDVALUE('Dim_ColMetric_Customer_Performance_Indicator'[ColType])
    VAR __ExchangeRate = SELECTEDVALUE(Slicer_Currency_Selection[Currency_ExchangeRate], 1)

    RETURN
        IF(
            ISBLANK(__BaseValue),
            BLANK(),
            IF(
                __IsCurrencyAmount && __ColType = "Act",
                DIVIDE(__BaseValue, __ExchangeRate),   // 金额类 Act: 汇率换算
                __BaseValue                             // 其他: 不换算
            )
        )
```

### 4.7 Customer Performance Cell Display（格式化显示，按 Metric_Format 分发）

```dax
Customer Performance Cell Display =
// ========================================
// 度量值: Customer Performance Cell Display
// Display Folder: Formatting
// 用途: 按 Metric_Format 单字段格式化显示
// 依赖: [Customer Performance Cell Value],
//       'Dim_ColMetric_Customer_Performance_Indicator'[Metric_Format],
//       Slicer_Currency_Selection[Currency_Symbol]
//
// 格式类型（严格遵循口径文档 Performance Indicator.md 数据类型定义）:
//   currency      → 货币符号 + 整数千分位：¥1,000 / $1,000
//                   （SLS Act / ACV Act / AUR Act 金额类）
//   integer       → 整数千分位：1,000
//                   （Customer No. Act / Freq. Act / UPT Act 数量类）
//   delta_pct_0dp → 百分比整数变化，含正号：+15% / -3%
//                   （所有 vs LY / vs LP，共 12 列）
// 说明:
//   - BLANK 显示为 "-"
//   - 货币符号由 Slicer_Currency_Selection[Currency_Symbol] 决定（默认 "¥"）
//   - Cell Value 层已完成汇率换算，Display 层只负责符号拼接
// ========================================
    VAR __Value = [Customer Performance Cell Value]
    VAR __Format = SELECTEDVALUE('Dim_ColMetric_Customer_Performance_Indicator'[Metric_Format])
    VAR __CurrencySymbol = SELECTEDVALUE(Slicer_Currency_Selection[Currency_Symbol], "¥")

    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            SWITCH(
                __Format,
                // ─── 货币符号 + 整数千分位（金额类 Act）───
                "currency",
                    __CurrencySymbol & FORMAT(__Value, "#,##0"),                              // ¥1,000 / $1,000
                // ─── 整数千分位（数量类 Act）───
                "integer",
                    FORMAT(__Value, "#,##0"),                                                 // 1,000
                // ─── 百分比整数变化，含正号（vs LY / vs LP）───
                "delta_pct_0dp",
                    IF(__Value > 0, "+", "") & FORMAT(__Value, "#,##0%"),                     // +15% / -3%
                // ─── 扩展格式（便于后续快速调整）───
                "currency_decimal_1dp",
                    __CurrencySymbol & FORMAT(__Value, "#,##0.0"),                            // ¥1,000.0
                "currency_decimal_2dp",
                    __CurrencySymbol & FORMAT(__Value, "#,##0.00"),                           // ¥1,000.00
                "decimal_1dp",
                    FORMAT(__Value, "#,##0.0"),                                               // 1.5
                "decimal_2dp",
                    FORMAT(__Value, "#,##0.00"),                                              // 1,000.00
                "percent_0dp",
                    FORMAT(__Value, "#,##0%"),                                                // 15%
                "percent_1dp",
                    FORMAT(__Value, "#,##0.0%"),                                              // 14.5%
                "percent_2dp",
                    FORMAT(__Value, "#,##0.00%"),                                             // 14.50%
                "delta_pct_1dp",
                    IF(__Value > 0, "+", "") & FORMAT(__Value, "#,##0.0%"),                   // +14.5%
                "delta_pct_2dp",
                    IF(__Value > 0, "+", "") & FORMAT(__Value, "#,##0.00%"),                  // +14.50%
                // ─── 默认 ─────────────────────────────────
                FORMAT(__Value, "#,##0.00")
            )
        )
```

### 4.8 Customer Performance Cell Font Color（字体颜色，按 Metric_ColorRule 分发）

```dax
Customer Performance Cell Font Color =
// ========================================
// 度量值: Customer Performance Cell Font Color
// Display Folder: Formatting
// 用途: 按 Metric_ColorRule 字段分发字体颜色
// 依赖: [Customer Performance Cell Value],
//       'Dim_ColMetric_Customer_Performance_Indicator'[Metric_ColorRule, Metric_ColorPositive/Negative/Zero/Default]
//
// 颜色规则（口径文档要求）:
//   1. Act 基础指标（Metric_ID=1,4,7,10,13,16）固定 #252423 → "fixed_black"
//   2. vs LY / vs LP（12 列，比率为正/负/零三色）→ "pos_neg_zero"
//   颜色取值:
//     正值（>0）：#1A9018 绿色
//     负值（<0）：#D64550 红色
//     零值（=0）：#E1C233 黄色
//     默认      ：#5F6165 深灰
//     固定黑色  ：#252423
// ========================================
    VAR __Value = [Customer Performance Cell Value]
    VAR __ColorRule = SELECTEDVALUE('Dim_ColMetric_Customer_Performance_Indicator'[Metric_ColorRule], "fixed_default")
    // ── 颜色取值（来自列维度表）──
    VAR __ColorPositive = SELECTEDVALUE('Dim_ColMetric_Customer_Performance_Indicator'[Metric_ColorPositive], "#1A9018")
    VAR __ColorNegative = SELECTEDVALUE('Dim_ColMetric_Customer_Performance_Indicator'[Metric_ColorNegative], "#D64550")
    VAR __ColorZero = SELECTEDVALUE('Dim_ColMetric_Customer_Performance_Indicator'[Metric_ColorZero], "#E1C233")
    VAR __ColorDefault = SELECTEDVALUE('Dim_ColMetric_Customer_Performance_Indicator'[Metric_ColorDefault], "#5F6165")

    RETURN
        SWITCH(
            __ColorRule,
            // ─── 固定黑色（Act 基础指标）───
            "fixed_black",
                "#252423",
            // ─── 正/负/零三色（vs LY / vs LP）───
            "pos_neg_zero",
                SWITCH(
                    TRUE(),
                    ISBLANK(__Value), __ColorDefault,
                    __Value > 0,      __ColorPositive,
                    __Value < 0,      __ColorNegative,
                    __Value = 0,      __ColorZero,
                    __ColorDefault
                ),
            // ─── 默认颜色 ───
            "fixed_default",
                __ColorDefault,
            // ─── 兜底 ───
            __ColorDefault
        )
```

### 4.9 Customer Performance Cell Background Color（背景色）

```dax
Customer Performance Cell Background Color =
// ========================================
// 度量值: Customer Performance Cell Background Color
// Display Folder: Formatting
// 用途: 区分 KPIGroup 行（分组标题行）与 KPI 行的背景色
// 依赖: ISINSCOPE('Dim_ColMetric_Customer_Performance_Indicator'[ColName])
// 颜色规则:
//   KPIGroup 行（分组标题行）: #E6D9C7（中米色）
//   KPI 行（具体指标行）     : #FFFFFF（白色）
// ========================================
    VAR __IsKPIRow = ISINSCOPE('Dim_ColMetric_Customer_Performance_Indicator'[ColName])
    RETURN
        IF(
            __IsKPIRow,
            "#FFFFFF",   // KPI 行：白色
            "#E6D9C7"    // KPIGroup 行：中米色
        )
```

---

## 5. 度量值清单与 Display Folder

| 序号 | 度量值名称 | Display Folder | 用途 |
| --- | --- | --- | --- |
| 1 | Customer Performance Act Base Value | Base Metrics | 本期基础值（slicer 区间聚合 + start_period 子集）；按 Row_Code 路由 Net/Demand 字段；按 Customer_Type 路由 New/Existing/All |
| 2 | Customer Performance LY Base Value | Base Metrics | 去年同期基础值（区间对称映射 TimeFrame_*_LY / First_Fiscal_Month_*_LY） |
| 3 | Customer Performance LP Base Value | Base Metrics | 上期基础值（区间对称映射 TimeFrame_*_LP / First_Fiscal_Month_*_LP） |
| 4 | Customer Performance Base Value | Base Metrics | 总路由（Act + vs LY/vs LP 派生 + REMOVEFILTERS）；6 个 KPI × 3 指标 = 18 列全覆盖 |
| 5 | Customer Performance Cell Value | Cell Values | 对外值：金额类 Act 触发汇率换算（÷ Currency_ExchangeRate），其余直接返回 Base Value |
| 6 | Customer Performance Cell Display | Formatting | 格式化显示文本（按 Metric_Format 单字段分发，金额类拼接 Currency_Symbol） |
| 7 | Customer Performance Cell Font Color | Formatting | 字体颜色（按 Metric_ColorRule：Act=fixed_black；vs LY/vs LP=pos_neg_zero 三色） |
| 8 | Customer Performance Cell Background Color | Formatting | 背景色（KPIGroup 行 #E6D9C7 vs KPI 行 #FFFFFF） |

---

## 6. 血缘关系图

```
┌─────────────────────────────────────────────────────────────────────┐
│                        数据源层                                      │
│  a03_e2e_customer_data_m（月度事实表）                               │
│  字段: data_date, platform, shop_info_id, user_id, is_member,       │
│        net_pay_amt, net_pay_qty, net_pay_order_cnt,                 │
│        pay_amt, pay_qty, pay_order_cnt,                             │
│        lp_12m_net_pay_amt, lp_12m_pay_amt                           │
└──────────────────────────────┬──────────────────────────────────────┘
                               │
                               │ 模型自动传递（行维度 = 事实表字段直接拉取）
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────────┐
│                        度量值层                                      │
│                                                                     │
│  ┌───────────────────────┐   ┌───────────────────────┐              │
│  │ Customer Performance  │   │ Customer Performance  │              │
│  │ Act Base Value        │   │ LY Base Value         │              │
│  │ (本期区间聚合 +        │   │ (区间对称映射 LY)     │              │
│  │  start_period 子集)   │   │                       │              │
│  └───────────┬───────────┘   └───────────┬───────────┘              │
│              │                           │                          │
│  ┌───────────────────────┐               │                          │
│  │ Customer Performance  │               │                          │
│  │ LP Base Value         │               │                          │
│  │ (区间对称映射 LP)     │               │                          │
│  └───────────┬───────────┘               │                          │
│              │                            │                          │
│              ▼                            ▼                          │
│  ┌───────────────────────────────────┐   ┌───────────────────────┐  │
│  │ Customer Performance              │   │ Dim_RowMetric_        │  │
│  │ Base Value                        │◄──│ Customer_Net_Demand    │  │
│  │ (总路由 + 派生计算)                │   │ (断开维度, Row_Code)  │  │
│  │ REMOVEFILTERS + 目标 Metric_ID    │   └───────────────────────┘  │
│  │ vs LY / vs LP 派生（12 列）        │                              │
│  └───────────────┬───────────────────┘   ┌───────────────────────┐  │
│                  │                        │ Dim_ColMetric_        │  │
│                  │◄──────────────────────│ Customer_Performance_ │  │
│                  │                        │ Indicator             │  │
│                  ▼                        │ (断开维度, Metric_ID, │  │
│  ┌───────────────────────────────────┐    │  Metric_IsCurrencyAmount│  │
│  │ Customer Performance              │    │  Metric_Format)       │  │
│  │ Cell Value                        │    └───────────────────────┘  │
│  │ (金额类 Act 汇率换算)             │                              │
│  └───────────────┬───────────────────┘   ┌───────────────────────┐  │
│                  │                        │ Slicer_Customer_Type_ │  │
│                  │◄──────────────────────│ Selection              │  │
│                  │                        │ (断开, Customer_Type) │  │
│                  ▼                        │  HASONEVALUE 判定     │  │
│  ┌───────────────────────────────────┐    │  New/Existing/All    │  │
│  │ Customer Performance              │    └───────────────────────┘  │
│  │ Cell Display                      │                              │
│  │ (按 Metric_Format + Currency_Symbol│   ┌───────────────────────┐  │
│  │  单字段格式化)                     │◄──│ Slicer_Currency_       │  │
│  └───────────────┬───────────────────┘   │ Selection              │  │
│                  │                        │ (断开, ExchangeRate,  │  │
│                  ▼                        │  Symbol)               │  │
│  ┌───────────────────────────────────┐    └───────────────────────┘  │
│  │  Customer Performance Cell Color   │                              │
│  │  (Font Color + Background Color)   │                              │
│  │  按 Metric_ColorRule 调度颜色      │                              │
│  └───────────────────────────────────┘                              │
└─────────────────────────────────────────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────────┐
│                        可视化层                                      │
│  Matrix 视觉对象                                                     │
│  行: 'Dim_RowMetric_Customer_Net_Demand'[Row_Label] (Net/Demand)    │
│  列: 'Dim_ColMetric_Customer_Performance_Indicator'[KPIGroup]       │
│      > [ColName]                                                    │
│  值: [Customer Performance Cell Display]                            │
│  条件格式:                                                           │
│    字体颜色 → [Customer Performance Cell Font Color]                 │
│    背景色   → [Customer Performance Cell Background Color]           │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 7. 注意事项

1. **三维路由设计**：本方案采用三个断开维度协同路由：
   - **Row 维度**（`Dim_RowMetric_Customer_Net_Demand`）：Net / Demand 字段路由，通过 `SELECTEDVALUE([Row_Code])` 读取
   - **Customer_Type 维度**（`Slicer_Customer_Type_Selection`）：New / Existing / All 逻辑路由，通过 `HASONEVALUE([Customer_Type_ID])` 判定
   - **Col 维度**（`Dim_ColMetric_Customer_Performance_Indicator`）：6 KPI × 3 指标 = 18 列，通过 `SELECTEDVALUE([Metric_ID])` 路由
2. **New/Existing/All 路由设计**（关键创新）：
   - `Slicer_Customer_Type_Selection[Customer_Type_ID]` 仅含 "New"、"Existing" 两个值（无 "All" 值）
   - 用 `HASONEVALUE([Customer_Type_ID])` 判定单选状态：
     - `TRUE` → 单选 New 或单选 Existing，分别走 New / Existing 分支
     - `FALSE` → 不选 / 多选（同时选 New+Existing）/ 全选，统一走 All 分支
   - 此设计避免枚举多选组合，逻辑简洁且语义正确
3. **Net / Demand 字段映射**（行指标维度表元数据驱动）：
   - Net 部分：`net_pay_amt` / `net_pay_qty` / `net_pay_order_cnt` / `lp_12m_net_pay_amt`
   - Demand 部分：`pay_amt` / `pay_qty` / `pay_order_cnt` / `lp_12m_pay_amt`
   - 通过 `SWITCH(__RowCode, "Net", <Net逻辑>, "Demand", <Demand逻辑>)` 在每个 KPI 内分发
4. **实际值时间口径 = 所选时间范围区间聚合**：
   - slicer 区间：`data_date ∈ [Slicer_Time_Frame_Min[TimeFrame_Min], Slicer_Time_Frame_Max[TimeFrame_Max]]`
   - start_period（第一个财月）：`data_date ∈ [Slicer_Time_Frame_Min[First_Fiscal_Month_Min], Slicer_Time_Frame_Min[First_Fiscal_Month_Max]]`
   - start_period 是 slicer 区间的子集，技术实现可"合并区间"
5. **DCom 新客判定（Customer No. Metric_ID=4）Step1 + Step2 合并区间实现**：
   - **New 逻辑**：`data_date ∈ start_period AND amt > 0 AND is_member = 0 AND lp_12m_*_amt = 0`
     - amt 字段按 Net/Demand 路由：Net→`net_pay_amt`，Demand→`pay_amt`
     - lp_12m 字段按 Net/Demand 路由：Net→`lp_12m_net_pay_amt`，Demand→`lp_12m_pay_amt`
     - 技术实现直接等价于单一 `CALCULATE(DISTINCTCOUNT(user_id), <四条件>)`，无需 INTERSECT
   - **Existing 逻辑**：本期区间有消费 ∩ start_period 在 lp_12m_*_amt > 0 名单
   - **All 逻辑**：本期区间 `amt > 0`（不限定 is_member=0 与 lp_12m 字段）
6. **Customer No. 三个分支的特殊处理**：
   - New / Existing：用户集合先过滤，再对 start_period 区间做 `DISTINCTCOUNT(user_id)`
   - All：直接对 slicer 区间做 `DISTINCTCOUNT(user_id) WHERE amt > 0`
   - 字段路由按 Row_Code（Net/Demand）切换 amt 字段
7. **ACV / Freq. 比率类指标分母的 All 分支特殊处理**：
   - 公式：`ACV = SLS / DISTINCTCOUNT(user_id)`；`Freq. = pay_order_cnt / DISTINCTCOUNT(user_id)`
   - **All 分支**：分母需加 `amt > 0` 筛选，定义为"活跃买家"集合
     - Net→`net_pay_amt > 0`，Demand→`pay_amt > 0`
   - **New / Existing 分支**：用户集合已通过 TREATAS 预先过滤，分母无需再加 `amt > 0`
8. **vs LY / vs LP 区间对称映射**：
   - 本期区间 = `[Slicer_Time_Frame_Min[TimeFrame_Min], Slicer_Time_Frame_Max[TimeFrame_Max]]`
   - LY 区间 = `[Slicer_Time_Frame_Min[TimeFrame_Min_LY], Slicer_Time_Frame_Max[TimeFrame_Max_LY]]`
   - LP 区间 = `[Slicer_Time_Frame_Min[TimeFrame_Min_LP], Slicer_Time_Frame_Max[TimeFrame_Max_LP]]`
   - start_period LY/LP 区间同理：`[First_Fiscal_Month_Min_LY/Max_LY, First_Fiscal_Month_Min_LP/Max_LP]`
9. **REMOVEFILTERS 机制**：派生指标（vs LY / vs LP）的取值必须先 `REMOVEFILTERS('Dim_ColMetric_Customer_Performance_Indicator')` 再应用目标 Metric_ID，否则矩阵行/列标题保留的筛选器会导致冲突返回 BLANK。
10. **汇率换算分层处理**：
    - Base Value 层：始终保留 RMB 原始值，确保 LY/LP/Act 派生计算口径一致
    - Cell Value 层：仅当 `Metric_IsCurrencyAmount=TRUE AND ColType="Act"` 时按 `÷ Currency_ExchangeRate` 换算
    - vs LY / vs LP：为比率（delta_pct_0dp），无量纲，不涉及汇率换算
    - Cell Display 层：拼接 `Currency_Symbol`（¥ / $），金额类才拼符号
11. **Metric_IsCurrencyAmount 字段定义**：
    - `TRUE`：SLS Act（ID=1）、ACV Act（ID=7）、AUR Act（ID=10）—— 金额类
    - `FALSE`：Customer No. Act（ID=4）、Freq. Act（ID=13）、UPT Act（ID=16）—— 数量类
    - `FALSE`：所有 vs LY / vs LP（ID=2,3,5,6,8,9,11,12,14,15,17,18）—— 比率类，无量纲
12. **Metric_Format 取值**（严格遵循口径文档）：
    - `currency`：金额类 Act（SLS / ACV / AUR Act，共 3 列）
    - `integer`：数量类 Act（Customer No. / Freq. / UPT Act，共 3 列）
    - `delta_pct_0dp`：所有 vs LY / vs LP（共 12 列），百分比整数变化含正号 `+15% / -3%`
13. **单一 Metric_Format 字段**：每个指标对应一个格式（不再区分 Act/LY/VsLY），行格式严格遵循口径文档数据类型定义。
14. **行维度处理**：无独立行维度表（行维度由 `Dim_RowMetric_Customer_Net_Demand` 提供 Net/Demand 两行）。事实表字段（`platform` / `shop_info_id`）作为附加行维度直接拉取，天然形成筛选与分组，DAX 度量值无需显式处理。
15. **扩展格式支持**：Cell Display 已扩展 `currency_decimal_1dp` / `currency_decimal_2dp` / `decimal_1dp` / `decimal_2dp` / `percent_0dp` / `percent_1dp` / `percent_2dp` / `delta_pct_1dp` / `delta_pct_2dp` 等格式，便于后续快速调整。如需新增指标使用扩展格式，只需在 `Dim_ColMetric_Customer_Performance_Indicator` 的 `Metric_Format` 字段填入对应格式值即可。
16. **字段名严格遵循口径文档**：
    - `net_pay_amt` / `net_pay_qty` / `net_pay_order_cnt` / `lp_12m_net_pay_amt`（Net 系列）
    - `pay_amt` / `pay_qty` / `pay_order_cnt` / `lp_12m_pay_amt`（Demand 系列）
    - 日期字段统一为 `data_date`（非 `dt`）
```
