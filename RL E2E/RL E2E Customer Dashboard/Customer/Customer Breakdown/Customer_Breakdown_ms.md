# Customer Breakdown 矩阵解决方案

> **版本**: v1.0
> **模块**: Customer Dashboard - Customer Tab - Customer Breakdown
> **关联口径**: 口径文档/Customer/Performance Indicator.md
> **数据底表**: a03_e2e_customer_data_m
> **关联维度**: Dim_RowMetric_Customer_Net_Demand（行）、Dim_ColMetric_Customer_Breakdown（列）、Slicer_Currency_Selection、Slicer_Time_Frame_Min、Slicer_Time_Frame_Max
> **与 Performance Indicator 的关系**: 本方案基于 Customer_KPIs_Performance_ms.md 的 **All 分支**独立提取，移除了 Customer_Type 路由（不读 Slicer_Customer_Type_Selection），仅保留 Net/Demand 路由 + Act/LY/LP + 派生。

---

## 1. 需求理解

### 1.1 模块定位
Customer Breakdown 是 Customer Tab 的"客户结构下钻"矩阵，展示 6 个 KPI 分组（DCom SLS / Customer No. / ACV / AUR / Freq. / UPT）× 3 指标（本身实际值 / vs LY / vs LP）= 18 列。

### 1.2 路由维度
| 路由维度 | 来源表 | 类型 | 说明 |
| --- | --- | --- | --- |
| Net / Demand | Dim_RowMetric_Customer_Net_Demand | 断开维度 | 切换 amt/qty/order_cnt 字段：Net→net_*，Demand→pay_* |
| Metric_ID（6×3=18 列） | Dim_ColMetric_Customer_Breakdown | 断开维度 | 列指标路由，ColType 中 Act 列替换为对应分组名 |

**关键差异（与 Performance Indicator 模块）**：本方案**不读 Slicer_Customer_Type_Selection**，逻辑等价于 Customer_Type = "All" 分支（即 Performance Indicator 中 HASONEVALUE=FALSE → All 分支），无需 New/Existing user_id 集合预过滤，直接在 slicer 区间聚合 + `is_member=0` + 必要时 `amt>0`。

### 1.3 时间口径（与 Performance Indicator 一致）
- 实际值（Act）：`data_date ∈ [Slicer_Time_Frame_Min[TimeFrame_Min], Slicer_Time_Frame_Max[TimeFrame_Max]]`，区间聚合
- LY：slicer 区间对称映射到去年，`data_date ∈ [TimeFrame_Min_LY, TimeFrame_Max_LY]`
- LP：slicer 区间对称映射到上期，`data_date ∈ [TimeFrame_Min_LP, TimeFrame_Max_LP]`
- start_period（仅 Performance Indicator 模块用于 New/Existing 判定）—— **本方案不使用**

---

## 2. 现状分析

- 数据底表 `a03_e2e_customer_data_m` 含 net_pay_amt / pay_amt / net_pay_qty / pay_qty / net_pay_order_cnt / pay_order_cnt 等字段，字段名以口径文档为准
- 行维度表 `Dim_RowMetric_Customer_Net_Demand` 已存在（位于 Customer/Performance Indicator 目录），可复用
- 列维度表 `Dim_ColMetric_Customer_Breakdown` 已存在（位于 Customer/Customer Breakdown 目录），与 Performance 版本差异：金额类 Metric_Format 改为 `currency_M_K_Int_0db`，ColType 中 Act 列替换为分组名

---

## 3. 方案设计

### 3.1 度量值分层
```
Base Value (Act/LY/LP)  ←  仅 Net/Demand 路由 + Metric_ID 路由，保留 RMB 原值
    ↓
Base Value 总路由        ←  Metric_ID 派生 vs LY / vs LP（比率）
    ↓
Cell Value              ←  金额类 Act 汇率换算（÷ Currency_ExchangeRate）
    ↓
Cell Display            ←  按 Metric_Format 格式化（含 currency_M_K_Int_0db 分级显示）
    ↓
Cell Font Color         ←  按 Metric_ColorRule 调度颜色
Cell Background Color   ←  KPIGroup 行 vs KPI 行
```

### 3.2 字段路由（Net/Demand）
| KPI | Net 字段 | Demand 字段 |
| --- | --- | --- |
| DCom SLS | net_pay_amt | pay_amt |
| Customer No. | net_pay_amt > 0 | pay_amt > 0 |
| ACV 分子 | net_pay_amt | pay_amt |
| ACV 分母 | net_pay_amt > 0 | pay_amt > 0 |
| AUR 分子 | net_pay_amt | pay_amt |
| AUR 分母 | net_pay_qty | pay_qty |
| Freq. 分子 | net_pay_order_cnt | pay_order_cnt |
| Freq. 分母 | net_pay_amt > 0 | pay_amt > 0 |
| UPT 分子 | net_pay_qty | pay_qty |
| UPT 分母 | net_pay_order_cnt | pay_order_cnt |

### 3.3 6 KPI 的 All 分支口径（直接抄自 Performance All 分支）

| Metric_ID | KPI | 分子 | 分母 | 额外筛选 |
| --- | --- | --- | --- | --- |
| 1 | DCom SLS | SUM(amt) | — | is_member=0, slicer 区间 |
| 4 | Customer No. | DISTINCTCOUNT(user_id) | — | is_member=0, amt>0, slicer 区间 |
| 7 | ACV | SUM(amt) | DISTINCTCOUNT(user_id) | 分子 is_member=0；分母 is_member=0, amt>0；slicer 区间 |
| 10 | AUR | SUM(amt) | SUM(qty) | 均需 is_member=0, slicer 区间 |
| 13 | Freq. | SUM(order_cnt) | DISTINCTCOUNT(user_id) | 分子 is_member=0；分母 is_member=0, amt>0；slicer 区间 |
| 16 | UPT | SUM(qty) | SUM(order_cnt) | 均需 is_member=0, slicer 区间 |

### 3.4 派生指标
- vs LY = Act / LY - 1（路由 2→1, 5→4, 8→7, 11→10, 14→13, 17→16）
- vs LP = Act / LP - 1（路由 3→1, 6→4, 9→7, 12→10, 15→13, 18→16）
- 全部 delta_pct_0dp 格式

---

## 4. 度量值实现

### 4.1 维度表（已存在，可复用）

- **行维度表**: `Dim_RowMetric_Customer_Net_Demand`（位于 Customer/Performance Indicator 目录，可复用）
- **列维度表**: `Dim_ColMetric_Customer_Breakdown`（位于 Customer/Customer Breakdown 目录，新表）
  - 金额类 Metric_Format = `currency_M_K_Int_0db`（SLS / ACV / AUR Act）
  - ColType 中 Act 列替换为分组名（DCom SLS / Customer No. / ACV / AUR / Freq. / UPT）

### 4.2 Customer Breakdown Act Base Value（本期基础值）

```dax
Customer Breakdown Act Base Value =
// ========================================
// 度量值: Customer Breakdown Act Base Value
// Display Folder: Base Metrics
// 用途: 本期基础值（slicer 区间聚合），仅受 Net/Demand 路由影响
//       不读 Slicer_Customer_Type_Selection（等价于 Performance 模块 All 分支）
// 依赖: 'Dim_RowMetric_Customer_Net_Demand'[Row_Code]
//       'Dim_ColMetric_Customer_Breakdown'[Metric_ID]
//       Slicer_Time_Frame_Min[TimeFrame_Min]
//       Slicer_Time_Frame_Max[TimeFrame_Max]
// 数据底表: a03_e2e_customer_data_m
// 时间口径: data_date ∈ [TimeFrame_Min, TimeFrame_Max]
// 汇率换算: 不在此度量值处理，保持原始 RMB，由 Cell Value 层统一换算
// ========================================

// ── 行维度路由：Net / Demand ──
VAR __RowCode =
    IF(
        HASONEVALUE('Dim_RowMetric_Customer_Net_Demand'[Row_Code]),
        SELECTEDVALUE('Dim_RowMetric_Customer_Net_Demand'[Row_Code]),
        "Net"
    )

// ── 列维度路由：Metric_ID ──
VAR __MetricID = SELECTEDVALUE('Dim_ColMetric_Customer_Breakdown'[Metric_ID])

// ── 时间区间：slicer 所选范围 ──
VAR __PeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Min[TimeFrame_Min])
VAR __PeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max[TimeFrame_Max])

// ═══════════════════════════════════════════════════════════════
// Metric_ID=1: DCom SLS（销售额）
// 口径: SUM(amt) WHERE slicer 区间 AND is_member=0
// ═══════════════════════════════════════════════════════════════
VAR __SLS_Act =
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

// ═══════════════════════════════════════════════════════════════
// Metric_ID=4: Customer No.（买家人数）
// 口径: DISTINCTCOUNT(user_id) WHERE slicer 区间 AND amt>0 AND is_member=0
// ═══════════════════════════════════════════════════════════════
VAR __CustomerNo_Act =
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

// ═══════════════════════════════════════════════════════════════
// Metric_ID=7: ACV（客单价 = SUM(amt) / COUNT(DISTINCT user_id)）
// 分子: SUM(amt) WHERE slicer 区间 AND is_member=0
// 分母: DISTINCTCOUNT(user_id) WHERE slicer 区间 AND amt>0 AND is_member=0
// ═══════════════════════════════════════════════════════════════
VAR __ACV_Act =
    SWITCH(
        __RowCode,
        "Net",
            DIVIDE(
                CALCULATE(
                    SUM('a03_e2e_customer_data_m'[net_pay_amt]),
                    'a03_e2e_customer_data_m'[is_member] = 0,
                    'a03_e2e_customer_data_m'[data_date] >= __PeriodMin,
                    'a03_e2e_customer_data_m'[data_date] <= __PeriodMax
                ),
                CALCULATE(
                    DISTINCTCOUNT('a03_e2e_customer_data_m'[user_id]),
                    'a03_e2e_customer_data_m'[is_member] = 0,
                    'a03_e2e_customer_data_m'[net_pay_amt] > 0,
                    'a03_e2e_customer_data_m'[data_date] >= __PeriodMin,
                    'a03_e2e_customer_data_m'[data_date] <= __PeriodMax
                )
            ),
        "Demand",
            DIVIDE(
                CALCULATE(
                    SUM('a03_e2e_customer_data_m'[pay_amt]),
                    'a03_e2e_customer_data_m'[is_member] = 0,
                    'a03_e2e_customer_data_m'[data_date] >= __PeriodMin,
                    'a03_e2e_customer_data_m'[data_date] <= __PeriodMax
                ),
                CALCULATE(
                    DISTINCTCOUNT('a03_e2e_customer_data_m'[user_id]),
                    'a03_e2e_customer_data_m'[is_member] = 0,
                    'a03_e2e_customer_data_m'[pay_amt] > 0,
                    'a03_e2e_customer_data_m'[data_date] >= __PeriodMin,
                    'a03_e2e_customer_data_m'[data_date] <= __PeriodMax
                )
            )
    )

// ═══════════════════════════════════════════════════════════════
// Metric_ID=10: AUR（件单价 = SUM(amt) / SUM(qty)）
// 分子/分母均 WHERE slicer 区间 AND is_member=0
// ═══════════════════════════════════════════════════════════════
VAR __AUR_Act =
    SWITCH(
        __RowCode,
        "Net",
            DIVIDE(
                CALCULATE(
                    SUM('a03_e2e_customer_data_m'[net_pay_amt]),
                    'a03_e2e_customer_data_m'[is_member] = 0,
                    'a03_e2e_customer_data_m'[data_date] >= __PeriodMin,
                    'a03_e2e_customer_data_m'[data_date] <= __PeriodMax
                ),
                CALCULATE(
                    SUM('a03_e2e_customer_data_m'[net_pay_qty]),
                    'a03_e2e_customer_data_m'[is_member] = 0,
                    'a03_e2e_customer_data_m'[data_date] >= __PeriodMin,
                    'a03_e2e_customer_data_m'[data_date] <= __PeriodMax
                )
            ),
        "Demand",
            DIVIDE(
                CALCULATE(
                    SUM('a03_e2e_customer_data_m'[pay_amt]),
                    'a03_e2e_customer_data_m'[is_member] = 0,
                    'a03_e2e_customer_data_m'[data_date] >= __PeriodMin,
                    'a03_e2e_customer_data_m'[data_date] <= __PeriodMax
                ),
                CALCULATE(
                    SUM('a03_e2e_customer_data_m'[pay_qty]),
                    'a03_e2e_customer_data_m'[is_member] = 0,
                    'a03_e2e_customer_data_m'[data_date] >= __PeriodMin,
                    'a03_e2e_customer_data_m'[data_date] <= __PeriodMax
                )
            )
    )

// ═══════════════════════════════════════════════════════════════
// Metric_ID=13: Freq.（购买频次 = SUM(order_cnt) / COUNT(DISTINCT user_id)）
// 分子: SUM(order_cnt) WHERE slicer 区间 AND is_member=0
// 分母: DISTINCTCOUNT(user_id) WHERE slicer 区间 AND amt>0 AND is_member=0
// ═══════════════════════════════════════════════════════════════
VAR __Freq_Act =
    SWITCH(
        __RowCode,
        "Net",
            DIVIDE(
                CALCULATE(
                    SUM('a03_e2e_customer_data_m'[net_pay_order_cnt]),
                    'a03_e2e_customer_data_m'[is_member] = 0,
                    'a03_e2e_customer_data_m'[data_date] >= __PeriodMin,
                    'a03_e2e_customer_data_m'[data_date] <= __PeriodMax
                ),
                CALCULATE(
                    DISTINCTCOUNT('a03_e2e_customer_data_m'[user_id]),
                    'a03_e2e_customer_data_m'[is_member] = 0,
                    'a03_e2e_customer_data_m'[net_pay_amt] > 0,
                    'a03_e2e_customer_data_m'[data_date] >= __PeriodMin,
                    'a03_e2e_customer_data_m'[data_date] <= __PeriodMax
                )
            ),
        "Demand",
            DIVIDE(
                CALCULATE(
                    SUM('a03_e2e_customer_data_m'[pay_order_cnt]),
                    'a03_e2e_customer_data_m'[is_member] = 0,
                    'a03_e2e_customer_data_m'[data_date] >= __PeriodMin,
                    'a03_e2e_customer_data_m'[data_date] <= __PeriodMax
                ),
                CALCULATE(
                    DISTINCTCOUNT('a03_e2e_customer_data_m'[user_id]),
                    'a03_e2e_customer_data_m'[is_member] = 0,
                    'a03_e2e_customer_data_m'[pay_amt] > 0,
                    'a03_e2e_customer_data_m'[data_date] >= __PeriodMin,
                    'a03_e2e_customer_data_m'[data_date] <= __PeriodMax
                )
            )
    )

// ═══════════════════════════════════════════════════════════════
// Metric_ID=16: UPT（客单件 = SUM(qty) / SUM(order_cnt)）
// 分子/分母均 WHERE slicer 区间 AND is_member=0
// ═══════════════════════════════════════════════════════════════
VAR __UPT_Act =
    SWITCH(
        __RowCode,
        "Net",
            DIVIDE(
                CALCULATE(
                    SUM('a03_e2e_customer_data_m'[net_pay_qty]),
                    'a03_e2e_customer_data_m'[is_member] = 0,
                    'a03_e2e_customer_data_m'[data_date] >= __PeriodMin,
                    'a03_e2e_customer_data_m'[data_date] <= __PeriodMax
                ),
                CALCULATE(
                    SUM('a03_e2e_customer_data_m'[net_pay_order_cnt]),
                    'a03_e2e_customer_data_m'[is_member] = 0,
                    'a03_e2e_customer_data_m'[data_date] >= __PeriodMin,
                    'a03_e2e_customer_data_m'[data_date] <= __PeriodMax
                )
            ),
        "Demand",
            DIVIDE(
                CALCULATE(
                    SUM('a03_e2e_customer_data_m'[pay_qty]),
                    'a03_e2e_customer_data_m'[is_member] = 0,
                    'a03_e2e_customer_data_m'[data_date] >= __PeriodMin,
                    'a03_e2e_customer_data_m'[data_date] <= __PeriodMax
                ),
                CALCULATE(
                    SUM('a03_e2e_customer_data_m'[pay_order_cnt]),
                    'a03_e2e_customer_data_m'[is_member] = 0,
                    'a03_e2e_customer_data_m'[data_date] >= __PeriodMin,
                    'a03_e2e_customer_data_m'[data_date] <= __PeriodMax
                )
            )
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

### 4.3 Customer Breakdown LY Base Value（去年同期基础值）

```dax
Customer Breakdown LY Base Value =
// ========================================
// 度量值: Customer Breakdown LY Base Value
// Display Folder: Base Metrics
// 用途: 去年同期基础值，时间区间对称映射到去年（_LY 字段）
// 依赖: 'Dim_RowMetric_Customer_Net_Demand'[Row_Code]
//       'Dim_ColMetric_Customer_Breakdown'[Metric_ID]
//       Slicer_Time_Frame_Min[TimeFrame_Min_LY]
//       Slicer_Time_Frame_Max[TimeFrame_Max_LY]
// 汇率换算: 不在此度量值处理，保持原始 RMB
// ========================================

VAR __RowCode =
    IF(
        HASONEVALUE('Dim_RowMetric_Customer_Net_Demand'[Row_Code]),
        SELECTEDVALUE('Dim_RowMetric_Customer_Net_Demand'[Row_Code]),
        "Net"
    )
VAR __MetricID = SELECTEDVALUE('Dim_ColMetric_Customer_Breakdown'[Metric_ID])

// ── 时间区间：LY 对称映射 ──
VAR __PeriodMin_LY = SELECTEDVALUE(Slicer_Time_Frame_Min[TimeFrame_Min_LY])
VAR __PeriodMax_LY = SELECTEDVALUE(Slicer_Time_Frame_Max[TimeFrame_Max_LY])

// ═══ Metric_ID=1: DCom SLS LY ═══
VAR __SLS_LY =
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

// ═══ Metric_ID=4: Customer No. LY ═══
VAR __CustomerNo_LY =
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

// ═══ Metric_ID=7: ACV LY（SUM(amt) / DISTINCTCOUNT(user_id)）═══
VAR __ACV_LY =
    SWITCH(
        __RowCode,
        "Net",
            DIVIDE(
                CALCULATE(
                    SUM('a03_e2e_customer_data_m'[net_pay_amt]),
                    'a03_e2e_customer_data_m'[is_member] = 0,
                    'a03_e2e_customer_data_m'[data_date] >= __PeriodMin_LY,
                    'a03_e2e_customer_data_m'[data_date] <= __PeriodMax_LY
                ),
                CALCULATE(
                    DISTINCTCOUNT('a03_e2e_customer_data_m'[user_id]),
                    'a03_e2e_customer_data_m'[is_member] = 0,
                    'a03_e2e_customer_data_m'[net_pay_amt] > 0,
                    'a03_e2e_customer_data_m'[data_date] >= __PeriodMin_LY,
                    'a03_e2e_customer_data_m'[data_date] <= __PeriodMax_LY
                )
            ),
        "Demand",
            DIVIDE(
                CALCULATE(
                    SUM('a03_e2e_customer_data_m'[pay_amt]),
                    'a03_e2e_customer_data_m'[is_member] = 0,
                    'a03_e2e_customer_data_m'[data_date] >= __PeriodMin_LY,
                    'a03_e2e_customer_data_m'[data_date] <= __PeriodMax_LY
                ),
                CALCULATE(
                    DISTINCTCOUNT('a03_e2e_customer_data_m'[user_id]),
                    'a03_e2e_customer_data_m'[is_member] = 0,
                    'a03_e2e_customer_data_m'[pay_amt] > 0,
                    'a03_e2e_customer_data_m'[data_date] >= __PeriodMin_LY,
                    'a03_e2e_customer_data_m'[data_date] <= __PeriodMax_LY
                )
            )
    )

// ═══ Metric_ID=10: AUR LY（SUM(amt) / SUM(qty)）═══
VAR __AUR_LY =
    SWITCH(
        __RowCode,
        "Net",
            DIVIDE(
                CALCULATE(
                    SUM('a03_e2e_customer_data_m'[net_pay_amt]),
                    'a03_e2e_customer_data_m'[is_member] = 0,
                    'a03_e2e_customer_data_m'[data_date] >= __PeriodMin_LY,
                    'a03_e2e_customer_data_m'[data_date] <= __PeriodMax_LY
                ),
                CALCULATE(
                    SUM('a03_e2e_customer_data_m'[net_pay_qty]),
                    'a03_e2e_customer_data_m'[is_member] = 0,
                    'a03_e2e_customer_data_m'[data_date] >= __PeriodMin_LY,
                    'a03_e2e_customer_data_m'[data_date] <= __PeriodMax_LY
                )
            ),
        "Demand",
            DIVIDE(
                CALCULATE(
                    SUM('a03_e2e_customer_data_m'[pay_amt]),
                    'a03_e2e_customer_data_m'[is_member] = 0,
                    'a03_e2e_customer_data_m'[data_date] >= __PeriodMin_LY,
                    'a03_e2e_customer_data_m'[data_date] <= __PeriodMax_LY
                ),
                CALCULATE(
                    SUM('a03_e2e_customer_data_m'[pay_qty]),
                    'a03_e2e_customer_data_m'[is_member] = 0,
                    'a03_e2e_customer_data_m'[data_date] >= __PeriodMin_LY,
                    'a03_e2e_customer_data_m'[data_date] <= __PeriodMax_LY
                )
            )
    )

// ═══ Metric_ID=13: Freq. LY（SUM(order_cnt) / DISTINCTCOUNT(user_id)）═══
VAR __Freq_LY =
    SWITCH(
        __RowCode,
        "Net",
            DIVIDE(
                CALCULATE(
                    SUM('a03_e2e_customer_data_m'[net_pay_order_cnt]),
                    'a03_e2e_customer_data_m'[is_member] = 0,
                    'a03_e2e_customer_data_m'[data_date] >= __PeriodMin_LY,
                    'a03_e2e_customer_data_m'[data_date] <= __PeriodMax_LY
                ),
                CALCULATE(
                    DISTINCTCOUNT('a03_e2e_customer_data_m'[user_id]),
                    'a03_e2e_customer_data_m'[is_member] = 0,
                    'a03_e2e_customer_data_m'[net_pay_amt] > 0,
                    'a03_e2e_customer_data_m'[data_date] >= __PeriodMin_LY,
                    'a03_e2e_customer_data_m'[data_date] <= __PeriodMax_LY
                )
            ),
        "Demand",
            DIVIDE(
                CALCULATE(
                    SUM('a03_e2e_customer_data_m'[pay_order_cnt]),
                    'a03_e2e_customer_data_m'[is_member] = 0,
                    'a03_e2e_customer_data_m'[data_date] >= __PeriodMin_LY,
                    'a03_e2e_customer_data_m'[data_date] <= __PeriodMax_LY
                ),
                CALCULATE(
                    DISTINCTCOUNT('a03_e2e_customer_data_m'[user_id]),
                    'a03_e2e_customer_data_m'[is_member] = 0,
                    'a03_e2e_customer_data_m'[pay_amt] > 0,
                    'a03_e2e_customer_data_m'[data_date] >= __PeriodMin_LY,
                    'a03_e2e_customer_data_m'[data_date] <= __PeriodMax_LY
                )
            )
    )

// ═══ Metric_ID=16: UPT LY（SUM(qty) / SUM(order_cnt)）═══
VAR __UPT_LY =
    SWITCH(
        __RowCode,
        "Net",
            DIVIDE(
                CALCULATE(
                    SUM('a03_e2e_customer_data_m'[net_pay_qty]),
                    'a03_e2e_customer_data_m'[is_member] = 0,
                    'a03_e2e_customer_data_m'[data_date] >= __PeriodMin_LY,
                    'a03_e2e_customer_data_m'[data_date] <= __PeriodMax_LY
                ),
                CALCULATE(
                    SUM('a03_e2e_customer_data_m'[net_pay_order_cnt]),
                    'a03_e2e_customer_data_m'[is_member] = 0,
                    'a03_e2e_customer_data_m'[data_date] >= __PeriodMin_LY,
                    'a03_e2e_customer_data_m'[data_date] <= __PeriodMax_LY
                )
            ),
        "Demand",
            DIVIDE(
                CALCULATE(
                    SUM('a03_e2e_customer_data_m'[pay_qty]),
                    'a03_e2e_customer_data_m'[is_member] = 0,
                    'a03_e2e_customer_data_m'[data_date] >= __PeriodMin_LY,
                    'a03_e2e_customer_data_m'[data_date] <= __PeriodMax_LY
                ),
                CALCULATE(
                    SUM('a03_e2e_customer_data_m'[pay_order_cnt]),
                    'a03_e2e_customer_data_m'[is_member] = 0,
                    'a03_e2e_customer_data_m'[data_date] >= __PeriodMin_LY,
                    'a03_e2e_customer_data_m'[data_date] <= __PeriodMax_LY
                )
            )
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

### 4.4 Customer Breakdown LP Base Value（上期基础值）

```dax
Customer Breakdown LP Base Value =
// ========================================
// 度量值: Customer Breakdown LP Base Value
// Display Folder: Base Metrics
// 用途: 上期基础值，时间区间对称映射到上期（_LP 字段）
// 依赖: 'Dim_RowMetric_Customer_Net_Demand'[Row_Code]
//       'Dim_ColMetric_Customer_Breakdown'[Metric_ID]
//       Slicer_Time_Frame_Min[TimeFrame_Min_LP]
//       Slicer_Time_Frame_Max[TimeFrame_Max_LP]
// 汇率换算: 不在此度量值处理，保持原始 RMB
// ========================================

VAR __RowCode =
    IF(
        HASONEVALUE('Dim_RowMetric_Customer_Net_Demand'[Row_Code]),
        SELECTEDVALUE('Dim_RowMetric_Customer_Net_Demand'[Row_Code]),
        "Net"
    )
VAR __MetricID = SELECTEDVALUE('Dim_ColMetric_Customer_Breakdown'[Metric_ID])

// ── 时间区间：LP 对称映射 ──
VAR __PeriodMin_LP = SELECTEDVALUE(Slicer_Time_Frame_Min[TimeFrame_Min_LP])
VAR __PeriodMax_LP = SELECTEDVALUE(Slicer_Time_Frame_Max[TimeFrame_Max_LP])

// ═══ Metric_ID=1: DCom SLS LP ═══
VAR __SLS_LP =
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

// ═══ Metric_ID=4: Customer No. LP ═══
VAR __CustomerNo_LP =
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

// ═══ Metric_ID=7: ACV LP ═══
VAR __ACV_LP =
    SWITCH(
        __RowCode,
        "Net",
            DIVIDE(
                CALCULATE(
                    SUM('a03_e2e_customer_data_m'[net_pay_amt]),
                    'a03_e2e_customer_data_m'[is_member] = 0,
                    'a03_e2e_customer_data_m'[data_date] >= __PeriodMin_LP,
                    'a03_e2e_customer_data_m'[data_date] <= __PeriodMax_LP
                ),
                CALCULATE(
                    DISTINCTCOUNT('a03_e2e_customer_data_m'[user_id]),
                    'a03_e2e_customer_data_m'[is_member] = 0,
                    'a03_e2e_customer_data_m'[net_pay_amt] > 0,
                    'a03_e2e_customer_data_m'[data_date] >= __PeriodMin_LP,
                    'a03_e2e_customer_data_m'[data_date] <= __PeriodMax_LP
                )
            ),
        "Demand",
            DIVIDE(
                CALCULATE(
                    SUM('a03_e2e_customer_data_m'[pay_amt]),
                    'a03_e2e_customer_data_m'[is_member] = 0,
                    'a03_e2e_customer_data_m'[data_date] >= __PeriodMin_LP,
                    'a03_e2e_customer_data_m'[data_date] <= __PeriodMax_LP
                ),
                CALCULATE(
                    DISTINCTCOUNT('a03_e2e_customer_data_m'[user_id]),
                    'a03_e2e_customer_data_m'[is_member] = 0,
                    'a03_e2e_customer_data_m'[pay_amt] > 0,
                    'a03_e2e_customer_data_m'[data_date] >= __PeriodMin_LP,
                    'a03_e2e_customer_data_m'[data_date] <= __PeriodMax_LP
                )
            )
    )

// ═══ Metric_ID=10: AUR LP ═══
VAR __AUR_LP =
    SWITCH(
        __RowCode,
        "Net",
            DIVIDE(
                CALCULATE(
                    SUM('a03_e2e_customer_data_m'[net_pay_amt]),
                    'a03_e2e_customer_data_m'[is_member] = 0,
                    'a03_e2e_customer_data_m'[data_date] >= __PeriodMin_LP,
                    'a03_e2e_customer_data_m'[data_date] <= __PeriodMax_LP
                ),
                CALCULATE(
                    SUM('a03_e2e_customer_data_m'[net_pay_qty]),
                    'a03_e2e_customer_data_m'[is_member] = 0,
                    'a03_e2e_customer_data_m'[data_date] >= __PeriodMin_LP,
                    'a03_e2e_customer_data_m'[data_date] <= __PeriodMax_LP
                )
            ),
        "Demand",
            DIVIDE(
                CALCULATE(
                    SUM('a03_e2e_customer_data_m'[pay_amt]),
                    'a03_e2e_customer_data_m'[is_member] = 0,
                    'a03_e2e_customer_data_m'[data_date] >= __PeriodMin_LP,
                    'a03_e2e_customer_data_m'[data_date] <= __PeriodMax_LP
                ),
                CALCULATE(
                    SUM('a03_e2e_customer_data_m'[pay_qty]),
                    'a03_e2e_customer_data_m'[is_member] = 0,
                    'a03_e2e_customer_data_m'[data_date] >= __PeriodMin_LP,
                    'a03_e2e_customer_data_m'[data_date] <= __PeriodMax_LP
                )
            )
    )

// ═══ Metric_ID=13: Freq. LP ═══
VAR __Freq_LP =
    SWITCH(
        __RowCode,
        "Net",
            DIVIDE(
                CALCULATE(
                    SUM('a03_e2e_customer_data_m'[net_pay_order_cnt]),
                    'a03_e2e_customer_data_m'[is_member] = 0,
                    'a03_e2e_customer_data_m'[data_date] >= __PeriodMin_LP,
                    'a03_e2e_customer_data_m'[data_date] <= __PeriodMax_LP
                ),
                CALCULATE(
                    DISTINCTCOUNT('a03_e2e_customer_data_m'[user_id]),
                    'a03_e2e_customer_data_m'[is_member] = 0,
                    'a03_e2e_customer_data_m'[net_pay_amt] > 0,
                    'a03_e2e_customer_data_m'[data_date] >= __PeriodMin_LP,
                    'a03_e2e_customer_data_m'[data_date] <= __PeriodMax_LP
                )
            ),
        "Demand",
            DIVIDE(
                CALCULATE(
                    SUM('a03_e2e_customer_data_m'[pay_order_cnt]),
                    'a03_e2e_customer_data_m'[is_member] = 0,
                    'a03_e2e_customer_data_m'[data_date] >= __PeriodMin_LP,
                    'a03_e2e_customer_data_m'[data_date] <= __PeriodMax_LP
                ),
                CALCULATE(
                    DISTINCTCOUNT('a03_e2e_customer_data_m'[user_id]),
                    'a03_e2e_customer_data_m'[is_member] = 0,
                    'a03_e2e_customer_data_m'[pay_amt] > 0,
                    'a03_e2e_customer_data_m'[data_date] >= __PeriodMin_LP,
                    'a03_e2e_customer_data_m'[data_date] <= __PeriodMax_LP
                )
            )
    )

// ═══ Metric_ID=16: UPT LP ═══
VAR __UPT_LP =
    SWITCH(
        __RowCode,
        "Net",
            DIVIDE(
                CALCULATE(
                    SUM('a03_e2e_customer_data_m'[net_pay_qty]),
                    'a03_e2e_customer_data_m'[is_member] = 0,
                    'a03_e2e_customer_data_m'[data_date] >= __PeriodMin_LP,
                    'a03_e2e_customer_data_m'[data_date] <= __PeriodMax_LP
                ),
                CALCULATE(
                    SUM('a03_e2e_customer_data_m'[net_pay_order_cnt]),
                    'a03_e2e_customer_data_m'[is_member] = 0,
                    'a03_e2e_customer_data_m'[data_date] >= __PeriodMin_LP,
                    'a03_e2e_customer_data_m'[data_date] <= __PeriodMax_LP
                )
            ),
        "Demand",
            DIVIDE(
                CALCULATE(
                    SUM('a03_e2e_customer_data_m'[pay_qty]),
                    'a03_e2e_customer_data_m'[is_member] = 0,
                    'a03_e2e_customer_data_m'[data_date] >= __PeriodMin_LP,
                    'a03_e2e_customer_data_m'[data_date] <= __PeriodMax_LP
                ),
                CALCULATE(
                    SUM('a03_e2e_customer_data_m'[pay_order_cnt]),
                    'a03_e2e_customer_data_m'[is_member] = 0,
                    'a03_e2e_customer_data_m'[data_date] >= __PeriodMin_LP,
                    'a03_e2e_customer_data_m'[data_date] <= __PeriodMax_LP
                )
            )
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

### 4.5 Customer Breakdown Base Value（总路由）

```dax
Customer Breakdown Base Value =
// ========================================
// 度量值: Customer Breakdown Base Value
// Display Folder: Base Metrics
// 用途: 总路由，按 Metric_ID 分发到 Act / vs LY / vs LP
// 依赖: [Customer Breakdown Act Base Value],
//       [Customer Breakdown LY Base Value],
//       [Customer Breakdown LP Base Value],
//       'Dim_ColMetric_Customer_Breakdown'[Metric_ID]
//
// Metric_ID 路由规则（18 列，6 分组 × 3 指标）:
//   Act 基础指标 ID: 1, 4, 7, 10, 13, 16
//   vs LY 派生 ID  : 2, 5, 8, 11, 14, 17
//   vs LP 派生 ID  : 3, 6, 9, 12, 15, 18
//
// 派生规则:
//   vs LY = Act / LY - 1   (Metric_ID: 2→1, 5→4, 8→7, 11→10, 14→13, 17→16)
//   vs LP = Act / LP - 1   (Metric_ID: 3→1, 6→4, 9→7, 12→10, 15→13, 18→16)
//
// REMOVEFILTERS 机制:
//   派生行需先 REMOVEFILTERS 清除断开维度的所有筛选，再应用目标 Metric_ID，
//   否则矩阵行/列标题保留的筛选器会导致冲突返回 BLANK。
// ========================================
    VAR __MetricID = SELECTEDVALUE('Dim_ColMetric_Customer_Breakdown'[Metric_ID])

    // ═══════════════════════════════════════
    // vs LY 派生：今年 / 去年 - 1
    // ═══════════════════════════════════════
    VAR __IsVsLY = __MetricID IN {2, 5, 8, 11, 14, 17}
    VAR __ActMetricID_ForLY =
        SWITCH(__MetricID,
            2,  1, 5, 4, 8, 7, 11, 10, 14, 13, 17, 16
        )
    VAR __ActValue_LY =
        IF(
            __IsVsLY,
            CALCULATE(
                [Customer Breakdown Act Base Value],
                REMOVEFILTERS('Dim_ColMetric_Customer_Breakdown'),
                'Dim_ColMetric_Customer_Breakdown'[Metric_ID] = __ActMetricID_ForLY
            )
        )
    VAR __LYValue =
        IF(
            __IsVsLY,
            CALCULATE(
                [Customer Breakdown LY Base Value],
                REMOVEFILTERS('Dim_ColMetric_Customer_Breakdown'),
                'Dim_ColMetric_Customer_Breakdown'[Metric_ID] = __ActMetricID_ForLY
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
    // ═══════════════════════════════════════
    VAR __IsVsLP = __MetricID IN {3, 6, 9, 12, 15, 18}
    VAR __ActMetricID_ForLP =
        SWITCH(__MetricID,
            3,  1, 6, 4, 9, 7, 12, 10, 15, 13, 18, 16
        )
    VAR __ActValue_LP =
        IF(
            __IsVsLP,
            CALCULATE(
                [Customer Breakdown Act Base Value],
                REMOVEFILTERS('Dim_ColMetric_Customer_Breakdown'),
                'Dim_ColMetric_Customer_Breakdown'[Metric_ID] = __ActMetricID_ForLP
            )
        )
    VAR __LPValue =
        IF(
            __IsVsLP,
            CALCULATE(
                [Customer Breakdown LP Base Value],
                REMOVEFILTERS('Dim_ColMetric_Customer_Breakdown'),
                'Dim_ColMetric_Customer_Breakdown'[Metric_ID] = __ActMetricID_ForLP
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
            1,  [Customer Breakdown Act Base Value],
            4,  [Customer Breakdown Act Base Value],
            7,  [Customer Breakdown Act Base Value],
            10, [Customer Breakdown Act Base Value],
            13, [Customer Breakdown Act Base Value],
            16, [Customer Breakdown Act Base Value],
            // ─── vs LY 派生（6 个，今年 / 去年 - 1）───
            2,  __VsLYResult,
            5,  __VsLYResult,
            8,  __VsLYResult,
            11, __VsLYResult,
            14, __VsLYResult,
            17, __VsLYResult,
            // ─── vs LP 派生（6 个，当期 / 上期 - 1）───
            3,  __VsLPResult,
            6,  __VsLPResult,
            9,  __VsLPResult,
            12, __VsLPResult,
            15, __VsLPResult,
            18, __VsLPResult,
            BLANK()
        )
```

### 4.6 Customer Breakdown Cell Value（对外值，含汇率换算）

```dax
Customer Breakdown Cell Value =
// ========================================
// 度量值: Customer Breakdown Cell Value
// Display Folder: Cell Values
// 用途: 对外暴露的单元格值
//       - 金额类 Act（Metric_IsCurrencyAmount=TRUE, ColType 为分组名）→ 按汇率换算
//       - 非金额类 或 vs LY/vs LP（比率，无量纲）→ 直接返回 Base Value，不换算
// 依赖: [Customer Breakdown Base Value],
//       'Dim_ColMetric_Customer_Breakdown'[Metric_IsCurrencyAmount, ColType],
//       Slicer_Currency_Selection[Currency_ExchangeRate]
//
// 汇率换算规则:
//   - 数据底表存储 RMB 原始值，USD 时通过 ÷ Currency_ExchangeRate 换算
//   - RMB 时 Currency_ExchangeRate = 1，换算前后值相同
//   - 仅金额类 Act 触发换算（vs LY/vs LP 为比率 delta，不涉及换算）
//   - Base Value 层始终保留 RMB 原始值，确保派生计算口径一致
// 注：本版本 ColType 中 Act 列替换为对应分组名（DCom SLS / Customer No. / ACV / AUR / Freq. / UPT），
//     不再统一为 "Act"，故金额类判断需用 Metric_IsCurrencyAmount=TRUE 而非 ColType="Act"
// ========================================
    VAR __BaseValue = [Customer Breakdown Base Value]
    VAR __IsCurrencyAmount = SELECTEDVALUE('Dim_ColMetric_Customer_Breakdown'[Metric_IsCurrencyAmount], FALSE)
    VAR __ColType = SELECTEDVALUE('Dim_ColMetric_Customer_Breakdown'[ColType])
    VAR __ExchangeRate = SELECTEDVALUE(Slicer_Currency_Selection[Currency_ExchangeRate], 1)

    // 判断是否为 Act 列（vs LY / vs LP 不换算）
    // ColType 为分组名时表示 Act 列；为 "vs LY" / "vs LP" 时表示派生列
    VAR __IsActCol = NOT (__ColType = "vs LY" || __ColType = "vs LP")

    RETURN
        IF(
            ISBLANK(__BaseValue),
            BLANK(),
            IF(
                __IsCurrencyAmount && __IsActCol,
                DIVIDE(__BaseValue, __ExchangeRate),   // 金额类 Act: 汇率换算
                __BaseValue                             // 其他: 不换算
            )
        )
```

### 4.7 Customer Breakdown Cell Display（格式化显示，含 currency_M_K_Int_0db 分级）

```dax
Customer Breakdown Cell Display =
// ========================================
// 度量值: Customer Breakdown Cell Display
// Display Folder: Formatting
// 用途: 按 Metric_Format 单字段格式化显示
// 依赖: [Customer Breakdown Cell Value],
//       'Dim_ColMetric_Customer_Breakdown'[Metric_Format],
//       Slicer_Currency_Selection[Currency_Symbol]
//
// 格式类型（严格遵循口径文档 Performance Indicator.md 数据类型定义，本版本金额类升级为分级显示）:
//   currency_M_K_Int_0db → 分级显示（SLS / ACV / AUR Act）:
//     值 < 1,000       → 货币符号 + 千分位整数：¥999
//     1,000 ≤ 值 < 1M  → 货币符号 + K 单位（1 位小数）：¥1.5K
//     值 ≥ 1,000,000   → 货币符号 + M 单位（1 位小数）：¥1.5M
//   integer              → 整数千分位：1,000（Customer No. / Freq. / UPT Act）
//   delta_pct_0dp        → 百分比整数变化，含正号：+15% / -3%（所有 vs LY / vs LP，共 12 列）
// 说明:
//   - BLANK 显示为 "-"
//   - 货币符号由 Slicer_Currency_Selection[Currency_Symbol] 决定（默认 "¥"）
//   - Cell Value 层已完成汇率换算，Display 层只负责符号拼接
// ========================================
    VAR __Value = [Customer Breakdown Cell Value]
    VAR __Format = SELECTEDVALUE('Dim_ColMetric_Customer_Breakdown'[Metric_Format])
    VAR __CurrencySymbol = SELECTEDVALUE(Slicer_Currency_Selection[Currency_Symbol], "¥")

    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            SWITCH(
                __Format,
                // ─── 金额类分级显示（SLS / ACV / AUR Act）───
                "currency_M_K_Int_0db",
                    IF(
                        __Value < 1000,
                        __CurrencySymbol & FORMAT(__Value, "#,##0"),                                           // ¥999
                        IF(
                            __Value < 1000000,
                            __CurrencySymbol & FORMAT(__Value / 1000, "#,##0.0") & "K",                       // ¥1.5K
                            __CurrencySymbol & FORMAT(__Value / 1000000, "#,##0.0") & "M"                      // ¥1.5M
                        )
                    ),
                // ─── 整数千分位（数量类 Act）───
                "integer",
                    FORMAT(__Value, "#,##0"),                                                                 // 1,000
                // ─── 百分比整数变化，含正号（vs LY / vs LP）───
                "delta_pct_0dp",
                    IF(__Value > 0, "+", "") & FORMAT(__Value, "#,##0%"),                                     // +15% / -3%
                // ─── 扩展格式（便于后续快速调整）───
                "currency",
                    __CurrencySymbol & FORMAT(__Value, "#,##0"),                                              // ¥1,000
                "currency_decimal_1dp",
                    __CurrencySymbol & FORMAT(__Value, "#,##0.0"),                                            // ¥1,000.0
                "currency_decimal_2dp",
                    __CurrencySymbol & FORMAT(__Value, "#,##0.00"),                                           // ¥1,000.00
                "decimal_1dp",
                    FORMAT(__Value, "#,##0.0"),
                "decimal_2dp",
                    FORMAT(__Value, "#,##0.00"),
                "percent_0dp",
                    FORMAT(__Value, "#,##0%"),
                "percent_1dp",
                    FORMAT(__Value, "#,##0.0%"),
                "percent_2dp",
                    FORMAT(__Value, "#,##0.00%"),
                "delta_pct_1dp",
                    IF(__Value > 0, "+", "") & FORMAT(__Value, "#,##0.0%"),
                "delta_pct_2dp",
                    IF(__Value > 0, "+", "") & FORMAT(__Value, "#,##0.00%"),
                // ─── 默认 ─────────────────────────────────
                FORMAT(__Value, "#,##0.00")
            )
        )
```

### 4.8 Customer Breakdown Cell Font Color（字体颜色）

```dax
Customer Breakdown Cell Font Color =
// ========================================
// 度量值: Customer Breakdown Cell Font Color
// Display Folder: Formatting
// 用途: 按 Metric_ColorRule 字段分发字体颜色
// 依赖: [Customer Breakdown Cell Value],
//       'Dim_ColMetric_Customer_Breakdown'[Metric_ColorRule, Metric_ColorPositive/Negative/Zero/Default]
//
// 颜色规则（与 Performance Indicator 一致）:
//   1. Act 基础指标（Metric_ID=1,4,7,10,13,16）固定 #252423 → "fixed_black"
//   2. vs LY / vs LP（12 列，比率为正/负/零三色）→ "pos_neg_zero"
// ========================================
    VAR __Value = [Customer Breakdown Cell Value]
    VAR __ColorRule = SELECTEDVALUE('Dim_ColMetric_Customer_Breakdown'[Metric_ColorRule], "fixed_default")
    VAR __ColorPositive = SELECTEDVALUE('Dim_ColMetric_Customer_Breakdown'[Metric_ColorPositive], "#1A9018")
    VAR __ColorNegative = SELECTEDVALUE('Dim_ColMetric_Customer_Breakdown'[Metric_ColorNegative], "#D64550")
    VAR __ColorZero = SELECTEDVALUE('Dim_ColMetric_Customer_Breakdown'[Metric_ColorZero], "#E1C233")
    VAR __ColorDefault = SELECTEDVALUE('Dim_ColMetric_Customer_Breakdown'[Metric_ColorDefault], "#5F6165")

    RETURN
        SWITCH(
            __ColorRule,
            "fixed_black",   "#252423",
            "pos_neg_zero",
                SWITCH(
                    TRUE(),
                    ISBLANK(__Value), __ColorDefault,
                    __Value > 0,      __ColorPositive,
                    __Value < 0,      __ColorNegative,
                    __Value = 0,      __ColorZero,
                    __ColorDefault
                ),
            "fixed_default", __ColorDefault,
            __ColorDefault
        )
```

### 4.9 Customer Breakdown Cell Background Color（背景色）

```dax
Customer Breakdown Cell Background Color =
// ========================================
// 度量值: Customer Breakdown Cell Background Color
// Display Folder: Formatting
// 用途: 区分 KPIGroup 行与 KPI 行的背景色
// 依赖: ISINSCOPE('Dim_ColMetric_Customer_Breakdown'[ColName])
// ========================================
    VAR __IsKPIRow = ISINSCOPE('Dim_ColMetric_Customer_Breakdown'[ColName])
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
| 1 | Customer Breakdown Act Base Value | Base Metrics | 本期基础值（slicer 区间聚合）；仅按 Row_Code 路由 Net/Demand 字段；不受 Customer_Type 影响 |
| 2 | Customer Breakdown LY Base Value | Base Metrics | 去年同期基础值（区间对称映射 TimeFrame_*_LY） |
| 3 | Customer Breakdown LP Base Value | Base Metrics | 上期基础值（区间对称映射 TimeFrame_*_LP） |
| 4 | Customer Breakdown Base Value | Base Metrics | 总路由（Act + vs LY/vs LP 派生 + REMOVEFILTERS）；6 个 KPI × 3 指标 = 18 列全覆盖 |
| 5 | Customer Breakdown Cell Value | Cell Values | 对外值：金额类 Act 触发汇率换算（÷ Currency_ExchangeRate），其余直接返回 Base Value |
| 6 | Customer Breakdown Cell Display | Formatting | 格式化显示文本（含 currency_M_K_Int_0db 分级显示 + Currency_Symbol 拼接） |
| 7 | Customer Breakdown Cell Font Color | Formatting | 字体颜色（按 Metric_ColorRule：Act=fixed_black；vs LY/vs LP=pos_neg_zero 三色） |
| 8 | Customer Breakdown Cell Background Color | Formatting | 背景色（KPIGroup 行 #E6D9C7 vs KPI 行 #FFFFFF） |

---

## 6. 血缘关系图

```
┌─────────────────────────────────────────────────────────────────────┐
│                        数据源层                                      │
│  a03_e2e_customer_data_m（月度事实表）                               │
│  字段: data_date, platform, shop_info_id, user_id, is_member,       │
│        net_pay_amt, net_pay_qty, net_pay_order_cnt,                 │
│        pay_amt, pay_qty, pay_order_cnt                              │
└──────────────────────────────┬──────────────────────────────────────┘
                               │
                               │ 模型自动传递（行维度 = 事实表字段直接拉取）
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────────┐
│                        度量值层                                      │
│                                                                     │
│  ┌───────────────────────┐   ┌───────────────────────┐              │
│  │ Customer Breakdown     │   │ Customer Breakdown    │              │
│  │ Act Base Value         │   │ LY Base Value         │              │
│  │ (slicer 区间聚合)      │   │ (区间对称映射 LY)     │              │
│  └───────────┬───────────┘   └───────────┬───────────┘              │
│              │                           │                          │
│  ┌───────────────────────┐               │                          │
│  │ Customer Breakdown     │               │                          │
│  │ LP Base Value          │               │                          │
│  │ (区间对称映射 LP)      │               │                          │
│  └───────────┬───────────┘               │                          │
│              │                            │                          │
│              ▼                            ▼                          │
│  ┌───────────────────────────────────┐   ┌───────────────────────┐  │
│  │ Customer Breakdown                │   │ Dim_RowMetric_        │  │
│  │ Base Value                        │◄──│ Customer_Net_Demand   │  │
│  │ (总路由 + 派生计算)               │   │ (复用, Row_Code)      │  │
│  │ REMOVEFILTERS + 目标 Metric_ID    │   └───────────────────────┘  │
│  │ vs LY / vs LP 派生（12 列）       │                              │
│  └───────────────┬───────────────────┘   ┌───────────────────────┐  │
│                  │                        │ Dim_ColMetric_       │  │
│                  │◄──────────────────────│ Customer_Breakdown   │  │
│                  │                        │ (新表, Metric_ID,    │  │
│                  ▼                        │  Metric_IsCurrencyAmount│
│  ┌───────────────────────────────────┐    │  Metric_Format,       │  │
│  │ Customer Breakdown                │    │  ColType=分组名)      │  │
│  │ Cell Value                        │    └───────────────────────┘  │
│  │ (金额类 Act 汇率换算)             │                              │
│  └───────────────┬───────────────────┘   ┌───────────────────────┐  │
│                  │                        │ Slicer_Currency_      │  │
│                  │◄──────────────────────│ Selection             │  │
│                  ▼                        │ (断开, ExchangeRate, │  │
│  ┌───────────────────────────────────┐    │  Symbol)              │  │
│  │ Customer Breakdown                │    └───────────────────────┘  │
│  │ Cell Display                      │                              │
│  │ (按 Metric_Format + Currency_Symbol│                              │
│  │  含 currency_M_K_Int_0db 分级显示) │                              │
│  └───────────────┬───────────────────┘                              │
│                  │                                                  │
│                  ▼                                                  │
│  ┌───────────────────────────────────┐                              │
│  │  Customer Breakdown Cell Color     │                              │
│  │  (Font Color + Background Color)   │                              │
│  └───────────────────────────────────┘                              │
└─────────────────────────────────────────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────────┐
│                        可视化层                                      │
│  Matrix 视觉对象                                                     │
│  行: 事实表字段直接拉取（platform / shop_info_id 等）              │
│      + 'Dim_RowMetric_Customer_Net_Demand'[Row_Label] (Net/Demand)  │
│  列: 'Dim_ColMetric_Customer_Breakdown'[KPIGroup] > [ColName]       │
│  值: [Customer Breakdown Cell Display]                              │
│  条件格式:                                                           │
│    字体颜色 → [Customer Breakdown Cell Font Color]                   │
│    背景色   → [Customer Breakdown Cell Background Color]             │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 7. 注意事项

1. **本方案与 Performance Indicator 的关系**：基于 `Customer_KPIs_Performance_ms.md` 的 **All 分支**独立提取。等价于 Performance 模块中 `HASONEVALUE(Slicer_Customer_Type_Selection[Customer_Type_ID])=FALSE` → 走 All 分支的情况（不选 / 多选 / 全选）。

2. **不读 Slicer_Customer_Type_Selection**：本方案完全不引用 Customer_Type 切片器，逻辑固定为 All 分支，无需 New/Existing user_id 集合预过滤（无 TREATAS、无 start_period 子集判定）。

3. **保留 Net/Demand 路由**：行维度 `Dim_RowMetric_Customer_Net_Demand` 可复用（位于 Customer/Performance Indicator 目录）。通过 `SELECTEDVALUE([Row_Code])` 切换字段：
   - Net → `net_pay_amt` / `net_pay_qty` / `net_pay_order_cnt`
   - Demand → `pay_amt` / `pay_qty` / `pay_order_cnt`

4. **列维度表差异**（`Dim_ColMetric_Customer_Breakdown` vs `Dim_ColMetric_Customer_Performance_Indicator`）：
   - 金额类 Metric_Format 从 `currency` 改为 `currency_M_K_Int_0db`（分级显示）
   - ColType 中 Act 列替换为对应分组名（`DCom SLS` / `Customer No.` / `ACV` / `AUR` / `Freq.` / `UPT`）
   - 其余字段（vs LY / vs LP、Metric_IsCurrencyAmount、Metric_ColorRule 等）保持不变

5. **Cell Value 汇率换算判断逻辑调整**：由于本版本 ColType 中 Act 列替换为分组名（不再是统一字符串 `"Act"`），汇率换算判断改为：
   - `__IsActCol = NOT (__ColType = "vs LY" || __ColType = "vs LP")`
   - 即只要 ColType 不是 `"vs LY"` 或 `"vs LP"`，就视为 Act 列
   - 再叠加 `Metric_IsCurrencyAmount=TRUE` 才触发汇率换算

6. **currency_M_K_Int_0db 分级显示规则**：
   - 值 < 1,000 → 货币符号 + 千分位整数：`¥999`
   - 1,000 ≤ 值 < 1,000,000 → 货币符号 + K 单位（1 位小数）：`¥1.5K`
   - 值 ≥ 1,000,000 → 货币符号 + M 单位（1 位小数）：`¥1.5M`
   - 仅适用于 SLS / ACV / AUR 的 Act 列（金额类）
   - Customer No. / Freq. / UPT Act 列仍是 `integer` 整数千分位
   - 所有 vs LY / vs LP 仍是 `delta_pct_0dp` 百分比整数含正号

7. **实际值时间口径 = 所选时间范围区间聚合**：
   - slicer 区间：`data_date ∈ [Slicer_Time_Frame_Min[TimeFrame_Min], Slicer_Time_Frame_Max[TimeFrame_Max]]`
   - LY 区间：`data_date ∈ [TimeFrame_Min_LY, TimeFrame_Max_LY]`（slicer 区间对称映射到去年）
   - LP 区间：`data_date ∈ [TimeFrame_Min_LP, TimeFrame_Max_LP]`（slicer 区间对称映射到上期）

8. **ACV / Freq. 比率类指标分母的 All 分支特殊处理**：
   - 公式：`ACV = SUM(amt) / DISTINCTCOUNT(user_id)`；`Freq. = SUM(order_cnt) / DISTINCTCOUNT(user_id)`
   - 分母需加 `amt > 0` 筛选，定义为"活跃买家"集合
     - Net→`net_pay_amt > 0`，Demand→`pay_amt > 0`

9. **Customer No. All 分支口径**：`DISTINCTCOUNT(user_id) WHERE slicer 区间 AND amt>0 AND is_member=0`
   - 字段路由按 Row_Code（Net/Demand）切换 `amt` 字段

10. **REMOVEFILTERS 机制**：派生指标（vs LY / vs LP）的取值必须先 `REMOVEFILTERS('Dim_ColMetric_Customer_Breakdown')` 再应用目标 Metric_ID，否则矩阵行/列标题保留的筛选器会导致冲突返回 BLANK。

11. **汇率换算分层处理**：
    - Base Value 层：始终保留 RMB 原始值，确保 LY/LP/Act 派生计算口径一致
    - Cell Value 层：仅当 `Metric_IsCurrencyAmount=TRUE AND __IsActCol=TRUE` 时按 `÷ Currency_ExchangeRate` 换算
    - vs LY / vs LP：为比率（delta_pct_0dp），无量纲，不涉及汇率换算
    - Cell Display 层：拼接 `Currency_Symbol`（¥ / $），金额类才拼符号

12. **Metric_IsCurrencyAmount 字段定义**：
    - `TRUE`：SLS Act（ID=1）、ACV Act（ID=7）、AUR Act（ID=10）—— 金额类
    - `FALSE`：Customer No. Act（ID=4）、Freq. Act（ID=13）、UPT Act（ID=16）—— 数量类
    - `FALSE`：所有 vs LY / vs LP（ID=2,3,5,6,8,9,11,12,14,15,17,18）—— 比率类，无量纲

13. **行维度处理**：行维度由 `Dim_RowMetric_Customer_Net_Demand` 提供 Net/Demand 两行，外加事实表字段（`platform` / `shop_info_id` 等）作为附加行维度直接拉取，天然形成筛选与分组，DAX 度量值无需显式处理。

14. **字段名严格遵循口径文档**：
    - `net_pay_amt` / `net_pay_qty` / `net_pay_order_cnt`（Net 系列）
    - `pay_amt` / `pay_qty` / `pay_order_cnt`（Demand 系列）
    - 日期字段统一为 `data_date`（非 `dt`）
```
