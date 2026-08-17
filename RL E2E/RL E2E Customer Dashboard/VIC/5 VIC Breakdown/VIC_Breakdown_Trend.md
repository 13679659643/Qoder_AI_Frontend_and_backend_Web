# Power BI 解决方案 — VIC Breakdown Trend：4 个指标 Value/Display 度量（柱形图趋势）

> status: ready
> created: 2026-08-15
> type: 度量值开发 + 柱形图视觉对象
> 口径来源: 口径文档/VIC Breakdown KPI.md（Metric_ID 1/4/23/26 共 4 个指标）
> 参考实现: VIC_Trend.md（柱形图 X 轴 + IsTimeFrameVisible 范式）、VIC_Breakdown_ms.md（VIC Breakdown 主表口径）
> 底表: a03_e2e_customer_data_m

---

## 1. 需求理解

为 VIC Customer Dashboard 的 VIC Breakdown Trend 柱形图输出 4 个指标的独立 Value + Display 度量对：

| Metric_ID | 指标 | VICType | 类型 | 计算方式 | 格式 |
|-----------|------|---------|------|---------|------|
| 1  | SLS Act (New VIC)       | New VIC       | 金额类 Act | DIVIDE(SUM(net_pay_amt) WHERE is_new_vic=1, FXRate) | currency_k |
| 4  | SLS% Act (New VIC)      | New VIC       | 比率类 Act | DIVIDE(SLS 分子 is_new_vic=1, SLS 分母 is_new_vic IN {0,1}) | percent_0dp |
| 23 | SLS Act (Retention VIC) | Retention VIC | 金额类 Act | DIVIDE(SUM(net_pay_amt) WHERE is_retention_vic=1, FXRate) | currency_k |
| 26 | SLS% Act (Retention VIC)| Retention VIC | 比率类 Act | DIVIDE(SLS 分子 is_retention_vic=1, SLS 分母 is_retention_vic IN {0,1}) | percent_0dp |

**核心设计原则**：
- 每个指标独立输出 Value + Display 度量对，直接平铺，不拆基础层
- 度量值作用于柱形图，X 轴 = Slicer_Time_Frame_VIC_Breakdown[TimeFrame_Value]
- 配置 IsTimeFrameVisible VIC Breakdown 视觉对象级别筛选器，控制 X 轴显示范围
- 日期表使用 VIC Breakdown 专用版本（Slicer_Time_Frame_VIC_Breakdown / _Min_ / _Max_），与主表 VIC_Breakdown_ms.md 共用，但与其他模块（VIC KPI、VIC Trend、Pie Chart 等）隔离
- 保留 VIC Breakdown 口径：end period 当月聚合（Last_Fiscal_Month_Min/Max）、is_member / is_employee 双重人群筛选、is_new_vic / is_retention_vic 区分、金额类 ÷ Currency_ExchangeRate
- 本方案仅输出 Act 值（本期），不涉及 vs LY / vs LP / vs Store 派生指标

### 1.1 格式说明

| Metric_ID | 指标 | 原格式 | 新格式 | 格式串 | 示例 |
|-----------|------|--------|--------|--------|------|
| 1, 23 | SLS Act | currency | currency_k | `__CurrencySymbol & FORMAT(__Value / 1000, "#,##0") & "k"` | ¥1k / $5k / ¥12k |
| 4, 26 | SLS% Act | percent_0dp | percent_0dp | `FORMAT(__Value, "0%")` | 45% / 62% |

> **currency_k 格式说明**：将 SLS 金额（已按 FXRate 换算为 RMB 或 USD）除以 1000 后保留整数，拼接货币符号 + "k" 后缀。例如 ¥1234 → "¥1k"，$5678 → "$6k"。
> **percent_0dp 格式说明**：SLS% 为比率（0~1），FORMAT 为 0% 不保留小数。例如 0.4567 → "46%"。

### 1.2 柱形图 X 轴与时间筛选范式

参考 VIC_Trend.md（及 PB_Location_Trend.md 子模块二 Fulfillment% Trend）：
- 柱形图 X 轴 = Slicer_Time_Frame_VIC_Breakdown[TimeFrame_Value]
- 视觉对象级别筛选器：IsTimeFrameVisible VIC Breakdown = 1（控制 X 轴显示范围：同粒度 + Key 在 [MinKey, MaxKey] 区间）
- 度量值内部双层时间筛选：
  - 全局范围（冗余但保留）：Slicer_Time_Frame_Min_VIC_Breakdown[TimeFrame_Min] ~ Slicer_Time_Frame_Max_VIC_Breakdown[TimeFrame_Max]
  - X 轴 end period 当月上下文：Slicer_Time_Frame_VIC_Breakdown[Last_Fiscal_Month_Min] ~ [Last_Fiscal_Month_Max]

---

## 2. 现状分析

### 2.1 数据底表

| 对象 | 名称 | 出处 |
|------|------|------|
| 事实表 | a03_e2e_customer_data_m | 口径文档 全局逻辑 |
| 关键字段 | data_date, user_id, net_pay_amt, is_member, is_employee, is_new_vic, is_retention_vic | 口径文档 |

### 2.2 维度表清单（VIC Breakdown 专用日期表，与其他模块隔离）

| 维度表 | 类型 | 连接方式 |
|--------|------|---------|
| Slicer_Time_Frame_VIC_Breakdown | 断开维度 | 柱形图 X 轴；SELECTEDVALUE 读取 TimeFrame_ID/Key/Value、Last_Fiscal_Month_Min/Max（X 轴每个时间点的 end period 区间） |
| Slicer_Time_Frame_Max_VIC_Breakdown | 断开维度 | 结束切片器；SELECTEDVALUE 读取 TimeFrame_Max（全局范围上界） |
| Slicer_Time_Frame_Min_VIC_Breakdown | 断开维度 | 起始切片器；SELECTEDVALUE 读取 TimeFrame_Min（全局范围下界） |
| Slicer_Is_Employee_Selection | 断开维度 | SELECTEDVALUE 读取 IsEmployee_Code（默认 1 = Yes） |
| IsMemberFilter | 断开维度 | SELECTEDVALUE 读取 IsMember（默认 0 = TTL VIC） |
| Slicer_Currency_Selection | 断开维度 | SELECTEDVALUE 读取 Currency_ExchangeRate（默认 1）、Currency_Symbol（默认 "¥"） |

> **日期表结构**：Slicer_Time_Frame_VIC_Breakdown 含 Last_Fiscal_Month_Min/Max 字段（与 Slicer_Time_Frame_Max_VIC_Breakdown 同源 SQL，通过自关联 dim_t00_bi_fiscal_calendar 得到每个时间点的 end period 当月区间）。TimeFrame_ID 筛选为 Month / Quarter。

---

## 3. 方案设计

### 3.1 筛选上下文

| 筛选器 | 作用方式 | DAX 处理 |
|--------|---------|---------|
| Slicer_Time_Frame_VIC_Breakdown（X 轴 end period） | 断开维度，SELECTEDVALUE 读取 Last_Fiscal_Month_Min/Max | `data_date >= __CurrentLFMMin AND data_date <= __CurrentLFMMax` |
| Slicer_Time_Frame_Min/Max_VIC_Breakdown（全局范围） | 冗余保护 | `data_date >= __GlobalMin AND data_date <= __GlobalMax` |
| Slicer_Is_Employee_Selection | SELECTEDVALUE 读取 IsEmployee_Code | `is_employee = __IsEmployeeFilter`（默认 1） |
| IsMemberFilter | SELECTEDVALUE 读取 IsMember | `is_member = __IsMemberFilter`（默认 0） |
| Slicer_Currency_Selection | SELECTEDVALUE 读取 Currency_ExchangeRate / Currency_Symbol | 金额类 `DIVIDE(SUM(net_pay_amt), __FXRate)`；Display 拼接 `__CurrencySymbol` |
| 事实表行维度字段（platform / shop_info_id / 新老客分层等） | 柱形图图例/小多图直接拉取，模型自动传递 | DAX 无需显式处理 |

### 3.2 度量值架构

```
IsTimeFrameVisible VIC Breakdown（辅助度量 — X 轴视觉对象级别筛选器）
    │
    ▼
┌─────────────────────────────────────────────────────────────┐
│  对外度量层（VIC Breakdown Trend，4 个指标 × Value + Display）│
│                                                             │
│  Metric_ID=1:  SLS Trend Value (New VIC) / Display          │
│  Metric_ID=4:  SLS% Trend Value (New VIC) / Display         │
│  Metric_ID=23: SLS Trend Value (Retention VIC) / Display    │
│  Metric_ID=26: SLS% Trend Value (Retention VIC) / Display   │
└─────────────────────────────────────────────────────────────┘
```

### 3.3 格式规范

| 格式类型 | 格式串 | 示例 | 适用指标 |
|---------|--------|------|---------|
| currency_k | `__CurrencySymbol & FORMAT(__Value / 1000, "#,##0") & "k"` | ¥1k / $5k | SLS Act (New VIC) / SLS Act (Retention VIC) |
| percent_0dp | `FORMAT(__Value, "0%")` | 46% / 62% | SLS% Act (New VIC) / SLS% Act (Retention VIC) |

---

## 4. 度量值实现

### 4.1 IsTimeFrameVisible VIC Breakdown（辅助度量 — X 轴视觉对象级别筛选器）

> 参考 VIC_Trend.md 的 IsTimeFrameVisible VIC Trend，逻辑完全一致，仅替换日期表为 VIC Breakdown 版本

```dax
IsTimeFrameVisible VIC Breakdown =
// ========================================
// 度量值: IsTimeFrameVisible VIC Breakdown
// Display Folder: VIC Breakdown Trend
// 用途: 判断柱形图 X 轴当前遍历的 timeframe
//       是否落在起止切片器选定的范围内（同粒度 + Key 在 [MinKey, MaxKey] 区间）
// 返回: 1（显示）或 0（隐藏）
// 依赖: Slicer_Time_Frame_VIC_Breakdown[TimeFrame_ID, TimeFrame_Key],
//       Slicer_Time_Frame_Min_VIC_Breakdown[TimeFrame_ID, TimeFrame_Key, TimeFrame_Value],
//       Slicer_Time_Frame_Max_VIC_Breakdown[TimeFrame_ID, TimeFrame_Key, TimeFrame_Value]
// 使用方式: 作为柱形图 X 轴的视觉对象级别筛选器
//           筛选条件: IsTimeFrameVisible VIC Breakdown = 1
// ========================================
    VAR __CurrentTimeFrameID = SELECTEDVALUE(Slicer_Time_Frame_VIC_Breakdown[TimeFrame_ID])
    VAR __CurrentKey = SELECTEDVALUE(Slicer_Time_Frame_VIC_Breakdown[TimeFrame_Key])
    VAR __MinTimeFrameID = SELECTEDVALUE(Slicer_Time_Frame_Min_VIC_Breakdown[TimeFrame_ID])
    VAR __MaxTimeFrameID = SELECTEDVALUE(Slicer_Time_Frame_Max_VIC_Breakdown[TimeFrame_ID])
    VAR __IsSameGranularity =
        NOT ISBLANK(__CurrentTimeFrameID)
        && __CurrentTimeFrameID = __MinTimeFrameID
        && __CurrentTimeFrameID = __MaxTimeFrameID
    VAR __MinKey =
        IF(
            ISFILTERED(Slicer_Time_Frame_Min_VIC_Breakdown[TimeFrame_Value]),
            MIN(Slicer_Time_Frame_Min_VIC_Breakdown[TimeFrame_Key]),
            MIN(Slicer_Time_Frame_VIC_Breakdown[TimeFrame_Key])
        )
    VAR __MaxKey =
        IF(
            ISFILTERED(Slicer_Time_Frame_Max_VIC_Breakdown[TimeFrame_Value]),
            MAX(Slicer_Time_Frame_Max_VIC_Breakdown[TimeFrame_Key]),
            MAX(Slicer_Time_Frame_VIC_Breakdown[TimeFrame_Key])
        )
    RETURN
        IF(
            NOT __IsSameGranularity, 0,
            IF(
                __CurrentKey >= __MinKey && __CurrentKey <= __MaxKey,
                1,
                0
            )
        )
```

---

### 4.2 SLS Trend Value (New VIC)

```dax
SLS Trend Value (New VIC) =
// ========================================
// 度量值: SLS Trend Value (New VIC)
// Display Folder: VIC Breakdown Trend
// 用途: New VIC SLS 本期值（柱形图 Y 轴）
// 口径来源: 口径文档/VIC Breakdown KPI.md - Metric_ID=1 SLS Act (New VIC)
// 计算公式: DIVIDE(SUM(net_pay_amt) WHERE is_new_vic=1, FXRate)
// 筛选条件:
//   - data_date ∈ [Last_Fiscal_Month_Min, Last_Fiscal_Month_Max]（X 轴 end period 当月）
//   - 全局范围冗余筛选: data_date ∈ [TimeFrame_Min, TimeFrame_Max]
//   - is_new_vic = 1
//   - is_member = __IsMemberFilter（默认 0 = TTL VIC）
//   - is_employee = __IsEmployeeFilter（默认 1 = Yes）
// 货币转换: 金额类 ÷ Currency_ExchangeRate（RMB=1, USD=7）
// Metric_ID: 1
// 数据类型: currency（内部值，未格式化）
// ========================================
    VAR __GlobalMin = SELECTEDVALUE(Slicer_Time_Frame_Min_VIC_Breakdown[TimeFrame_Min])
    VAR __GlobalMax = SELECTEDVALUE(Slicer_Time_Frame_Max_VIC_Breakdown[TimeFrame_Max])
    VAR __CurrentLFMMin = SELECTEDVALUE(Slicer_Time_Frame_VIC_Breakdown[Last_Fiscal_Month_Min])
    VAR __CurrentLFMMax = SELECTEDVALUE(Slicer_Time_Frame_VIC_Breakdown[Last_Fiscal_Month_Max])
    VAR __IsMemberFilter = SELECTEDVALUE(IsMemberFilter[IsMember], 0)
    VAR __IsEmployeeFilter = SELECTEDVALUE(Slicer_Is_Employee_Selection[IsEmployee_Code], 1)
    VAR __FXRate = SELECTEDVALUE(Slicer_Currency_Selection[Currency_ExchangeRate], 1)
    VAR __Result =
        DIVIDE(
            CALCULATE(
                SUM('a03_e2e_customer_data_m'[net_pay_amt]),
                'a03_e2e_customer_data_m'[is_new_vic] = 1,
                'a03_e2e_customer_data_m'[is_member] = __IsMemberFilter,
                'a03_e2e_customer_data_m'[is_employee] = __IsEmployeeFilter,
                'a03_e2e_customer_data_m'[data_date] >= __GlobalMin,
                'a03_e2e_customer_data_m'[data_date] <= __GlobalMax,
                'a03_e2e_customer_data_m'[data_date] >= __CurrentLFMMin,
                'a03_e2e_customer_data_m'[data_date] <= __CurrentLFMMax
            ),
            __FXRate
        )
    RETURN __Result
```

### 4.3 SLS Trend Display (New VIC)

```dax
SLS Trend Display (New VIC) =
// ========================================
// 度量值: SLS Trend Display (New VIC)
// Display Folder: VIC Breakdown Trend
// 用途: New VIC SLS 格式化显示（千位缩写 + 货币符号）
// 依赖: [SLS Trend Value (New VIC)]
// 格式类型: currency_k → __CurrencySymbol & FORMAT(__Value / 1000, "#,##0") & "k"
// 示例: ¥1k / $5k / ¥12k
// ========================================
    VAR __Value = [SLS Trend Value (New VIC)]
    VAR __CurrencySymbol = SELECTEDVALUE(Slicer_Currency_Selection[Currency_Symbol], "¥")
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            __CurrencySymbol & FORMAT(__Value / 1000, "#,##0") & "k"
        )
```

---

### 4.4 SLS% Trend Value (New VIC)

```dax
SLS% Trend Value (New VIC) =
// ========================================
// 度量值: SLS% Trend Value (New VIC)
// Display Folder: VIC Breakdown Trend
// 用途: New VIC SLS% 本期比率（柱形图 Y 轴）
// 口径来源: 口径文档/VIC Breakdown KPI.md - Metric_ID=4 SLS% Act (New VIC)
// 计算公式: DIVIDE(分子, 分母)
//   分子: SUM(net_pay_amt) WHERE is_new_vic = 1（X 轴 end period 当月）
//   分母: SUM(net_pay_amt) WHERE is_new_vic IN {0, 1}（X 轴 end period 当月，全客）
// 筛选条件:
//   - data_date ∈ [Last_Fiscal_Month_Min, Last_Fiscal_Month_Max]（X 轴 end period 当月）
//   - 全局范围冗余筛选: data_date ∈ [TimeFrame_Min, TimeFrame_Max]
//   - is_member = __IsMemberFilter（默认 0 = TTL VIC）
//   - is_employee = __IsEmployeeFilter（默认 1 = Yes）
// 货币转换: SLS% 占比不除（分子分母同币种抵消）
// Metric_ID: 4
// 数据类型: percent_0dp（比率，0~1）
// ========================================
    VAR __GlobalMin = SELECTEDVALUE(Slicer_Time_Frame_Min_VIC_Breakdown[TimeFrame_Min])
    VAR __GlobalMax = SELECTEDVALUE(Slicer_Time_Frame_Max_VIC_Breakdown[TimeFrame_Max])
    VAR __CurrentLFMMin = SELECTEDVALUE(Slicer_Time_Frame_VIC_Breakdown[Last_Fiscal_Month_Min])
    VAR __CurrentLFMMax = SELECTEDVALUE(Slicer_Time_Frame_VIC_Breakdown[Last_Fiscal_Month_Max])
    VAR __IsMemberFilter = SELECTEDVALUE(IsMemberFilter[IsMember], 0)
    VAR __IsEmployeeFilter = SELECTEDVALUE(Slicer_Is_Employee_Selection[IsEmployee_Code], 1)

    // ── 分子: is_new_vic=1 的 SLS ──
    VAR __Numerator =
        CALCULATE(
            SUM('a03_e2e_customer_data_m'[net_pay_amt]),
            'a03_e2e_customer_data_m'[is_new_vic] = 1,
            'a03_e2e_customer_data_m'[is_member] = __IsMemberFilter,
            'a03_e2e_customer_data_m'[is_employee] = __IsEmployeeFilter,
            'a03_e2e_customer_data_m'[data_date] >= __GlobalMin,
            'a03_e2e_customer_data_m'[data_date] <= __GlobalMax,
            'a03_e2e_customer_data_m'[data_date] >= __CurrentLFMMin,
            'a03_e2e_customer_data_m'[data_date] <= __CurrentLFMMax
        )

    // ── 分母: is_new_vic IN {0, 1} 的全客 SLS ──
    VAR __Denominator =
        CALCULATE(
            SUM('a03_e2e_customer_data_m'[net_pay_amt]),
            'a03_e2e_customer_data_m'[is_new_vic] IN {0, 1},
            'a03_e2e_customer_data_m'[is_member] = __IsMemberFilter,
            'a03_e2e_customer_data_m'[is_employee] = __IsEmployeeFilter,
            'a03_e2e_customer_data_m'[data_date] >= __GlobalMin,
            'a03_e2e_customer_data_m'[data_date] <= __GlobalMax,
            'a03_e2e_customer_data_m'[data_date] >= __CurrentLFMMin,
            'a03_e2e_customer_data_m'[data_date] <= __CurrentLFMMax
        )

    RETURN DIVIDE(__Numerator, __Denominator)
```

### 4.5 SLS% Trend Display (New VIC)

```dax
SLS% Trend Display (New VIC) =
// ========================================
// 度量值: SLS% Trend Display (New VIC)
// Display Folder: VIC Breakdown Trend
// 用途: New VIC SLS% 格式化显示
// 依赖: [SLS% Trend Value (New VIC)]
// 格式类型: percent_0dp → FORMAT(__Value, "0%")
// 示例: 46% / 62%
// ========================================
    VAR __Value = [SLS% Trend Value (New VIC)]
    RETURN
        IF(ISBLANK(__Value), "-", FORMAT(__Value, "0%"))
```

---

### 4.6 SLS Trend Value (Retention VIC)

```dax
SLS Trend Value (Retention VIC) =
// ========================================
// 度量值: SLS Trend Value (Retention VIC)
// Display Folder: VIC Breakdown Trend
// 用途: Retention VIC SLS 本期值（柱形图 Y 轴）
// 口径来源: 口径文档/VIC Breakdown KPI.md - Metric_ID=23 SLS Act (Retention VIC)
// 计算公式: DIVIDE(SUM(net_pay_amt) WHERE is_retention_vic=1, FXRate)
// 筛选条件:
//   - data_date ∈ [Last_Fiscal_Month_Min, Last_Fiscal_Month_Max]（X 轴 end period 当月）
//   - 全局范围冗余筛选: data_date ∈ [TimeFrame_Min, TimeFrame_Max]
//   - is_retention_vic = 1
//   - is_member = __IsMemberFilter（默认 0 = TTL VIC）
//   - is_employee = __IsEmployeeFilter（默认 1 = Yes）
// 货币转换: 金额类 ÷ Currency_ExchangeRate（RMB=1, USD=7）
// Metric_ID: 23
// 数据类型: currency（内部值，未格式化）
// ========================================
    VAR __GlobalMin = SELECTEDVALUE(Slicer_Time_Frame_Min_VIC_Breakdown[TimeFrame_Min])
    VAR __GlobalMax = SELECTEDVALUE(Slicer_Time_Frame_Max_VIC_Breakdown[TimeFrame_Max])
    VAR __CurrentLFMMin = SELECTEDVALUE(Slicer_Time_Frame_VIC_Breakdown[Last_Fiscal_Month_Min])
    VAR __CurrentLFMMax = SELECTEDVALUE(Slicer_Time_Frame_VIC_Breakdown[Last_Fiscal_Month_Max])
    VAR __IsMemberFilter = SELECTEDVALUE(IsMemberFilter[IsMember], 0)
    VAR __IsEmployeeFilter = SELECTEDVALUE(Slicer_Is_Employee_Selection[IsEmployee_Code], 1)
    VAR __FXRate = SELECTEDVALUE(Slicer_Currency_Selection[Currency_ExchangeRate], 1)
    VAR __Result =
        DIVIDE(
            CALCULATE(
                SUM('a03_e2e_customer_data_m'[net_pay_amt]),
                'a03_e2e_customer_data_m'[is_retention_vic] = 1,
                'a03_e2e_customer_data_m'[is_member] = __IsMemberFilter,
                'a03_e2e_customer_data_m'[is_employee] = __IsEmployeeFilter,
                'a03_e2e_customer_data_m'[data_date] >= __GlobalMin,
                'a03_e2e_customer_data_m'[data_date] <= __GlobalMax,
                'a03_e2e_customer_data_m'[data_date] >= __CurrentLFMMin,
                'a03_e2e_customer_data_m'[data_date] <= __CurrentLFMMax
            ),
            __FXRate
        )
    RETURN __Result
```

### 4.7 SLS Trend Display (Retention VIC)

```dax
SLS Trend Display (Retention VIC) =
// ========================================
// 度量值: SLS Trend Display (Retention VIC)
// Display Folder: VIC Breakdown Trend
// 用途: Retention VIC SLS 格式化显示（千位缩写 + 货币符号）
// 依赖: [SLS Trend Value (Retention VIC)]
// 格式类型: currency_k → __CurrencySymbol & FORMAT(__Value / 1000, "#,##0") & "k"
// 示例: ¥1k / $5k / ¥12k
// ========================================
    VAR __Value = [SLS Trend Value (Retention VIC)]
    VAR __CurrencySymbol = SELECTEDVALUE(Slicer_Currency_Selection[Currency_Symbol], "¥")
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            __CurrencySymbol & FORMAT(__Value / 1000, "#,##0") & "k"
        )
```

---

### 4.8 SLS% Trend Value (Retention VIC)

```dax
SLS% Trend Value (Retention VIC) =
// ========================================
// 度量值: SLS% Trend Value (Retention VIC)
// Display Folder: VIC Breakdown Trend
// 用途: Retention VIC SLS% 本期比率（柱形图 Y 轴）
// 口径来源: 口径文档/VIC Breakdown KPI.md - Metric_ID=26 SLS% Act (Retention VIC)
// 计算公式: DIVIDE(分子, 分母)
//   分子: SUM(net_pay_amt) WHERE is_retention_vic = 1（X 轴 end period 当月）
//   分母: SUM(net_pay_amt) WHERE is_retention_vic IN {0, 1}（X 轴 end period 当月，全客）
// 筛选条件:
//   - data_date ∈ [Last_Fiscal_Month_Min, Last_Fiscal_Month_Max]（X 轴 end period 当月）
//   - 全局范围冗余筛选: data_date ∈ [TimeFrame_Min, TimeFrame_Max]
//   - is_member = __IsMemberFilter（默认 0 = TTL VIC）
//   - is_employee = __IsEmployeeFilter（默认 1 = Yes）
// 货币转换: SLS% 占比不除（分子分母同币种抵消）
// Metric_ID: 26
// 数据类型: percent_0dp（比率，0~1）
// ========================================
    VAR __GlobalMin = SELECTEDVALUE(Slicer_Time_Frame_Min_VIC_Breakdown[TimeFrame_Min])
    VAR __GlobalMax = SELECTEDVALUE(Slicer_Time_Frame_Max_VIC_Breakdown[TimeFrame_Max])
    VAR __CurrentLFMMin = SELECTEDVALUE(Slicer_Time_Frame_VIC_Breakdown[Last_Fiscal_Month_Min])
    VAR __CurrentLFMMax = SELECTEDVALUE(Slicer_Time_Frame_VIC_Breakdown[Last_Fiscal_Month_Max])
    VAR __IsMemberFilter = SELECTEDVALUE(IsMemberFilter[IsMember], 0)
    VAR __IsEmployeeFilter = SELECTEDVALUE(Slicer_Is_Employee_Selection[IsEmployee_Code], 1)

    // ── 分子: is_retention_vic=1 的 SLS ──
    VAR __Numerator =
        CALCULATE(
            SUM('a03_e2e_customer_data_m'[net_pay_amt]),
            'a03_e2e_customer_data_m'[is_retention_vic] = 1,
            'a03_e2e_customer_data_m'[is_member] = __IsMemberFilter,
            'a03_e2e_customer_data_m'[is_employee] = __IsEmployeeFilter,
            'a03_e2e_customer_data_m'[data_date] >= __GlobalMin,
            'a03_e2e_customer_data_m'[data_date] <= __GlobalMax,
            'a03_e2e_customer_data_m'[data_date] >= __CurrentLFMMin,
            'a03_e2e_customer_data_m'[data_date] <= __CurrentLFMMax
        )

    // ── 分母: is_retention_vic IN {0, 1} 的全客 SLS ──
    VAR __Denominator =
        CALCULATE(
            SUM('a03_e2e_customer_data_m'[net_pay_amt]),
            'a03_e2e_customer_data_m'[is_retention_vic] IN {0, 1},
            'a03_e2e_customer_data_m'[is_member] = __IsMemberFilter,
            'a03_e2e_customer_data_m'[is_employee] = __IsEmployeeFilter,
            'a03_e2e_customer_data_m'[data_date] >= __GlobalMin,
            'a03_e2e_customer_data_m'[data_date] <= __GlobalMax,
            'a03_e2e_customer_data_m'[data_date] >= __CurrentLFMMin,
            'a03_e2e_customer_data_m'[data_date] <= __CurrentLFMMax
        )

    RETURN DIVIDE(__Numerator, __Denominator)
```

### 4.9 SLS% Trend Display (Retention VIC)

```dax
SLS% Trend Display (Retention VIC) =
// ========================================
// 度量值: SLS% Trend Display (Retention VIC)
// Display Folder: VIC Breakdown Trend
// 用途: Retention VIC SLS% 格式化显示
// 依赖: [SLS% Trend Value (Retention VIC)]
// 格式类型: percent_0dp → FORMAT(__Value, "0%")
// 示例: 46% / 62%
// ========================================
    VAR __Value = [SLS% Trend Value (Retention VIC)]
    RETURN
        IF(ISBLANK(__Value), "-", FORMAT(__Value, "0%"))
```

---

## 5. 度量值清单与 Display Folder

| 序号 | 度量值名称 | Display Folder | Metric_ID | 指标 | 类型 | 格式 |
|------|-----------|----------------|-----------|------|------|------|
| 1 | IsTimeFrameVisible VIC Breakdown | VIC Breakdown Trend | — | X 轴筛选器 | 辅助 | — |
| 2 | SLS Trend Value (New VIC) | VIC Breakdown Trend | 1 | SLS Act (New VIC) | Value | currency_k |
| 3 | SLS Trend Display (New VIC) | VIC Breakdown Trend | 1 | SLS Act (New VIC) | Display | currency_k |
| 4 | SLS% Trend Value (New VIC) | VIC Breakdown Trend | 4 | SLS% Act (New VIC) | Value | percent_0dp |
| 5 | SLS% Trend Display (New VIC) | VIC Breakdown Trend | 4 | SLS% Act (New VIC) | Display | percent_0dp |
| 6 | SLS Trend Value (Retention VIC) | VIC Breakdown Trend | 23 | SLS Act (Retention VIC) | Value | currency_k |
| 7 | SLS Trend Display (Retention VIC) | VIC Breakdown Trend | 23 | SLS Act (Retention VIC) | Display | currency_k |
| 8 | SLS% Trend Value (Retention VIC) | VIC Breakdown Trend | 26 | SLS% Act (Retention VIC) | Value | percent_0dp |
| 9 | SLS% Trend Display (Retention VIC) | VIC Breakdown Trend | 26 | SLS% Act (Retention VIC) | Display | percent_0dp |

---

## 6. 视觉对象配置

### 6.1 柱形图（VIC Breakdown Trend）

| 配置项 | 值 |
|--------|-----|
| X 轴 | Slicer_Time_Frame_VIC_Breakdown[TimeFrame_Value] |
| Y 轴 | 按需拉取 4 个 Value 度量之一（如 [SLS Trend Value (New VIC)]） |
| 图例 | 可选：a03_e2e_customer_data_m[platform] 或 [shop_info_id]（直接拉取，天然筛选+分组） |
| 数据标签 | 对应 [* Display] 度量 |
| 视觉对象级别筛选器 | Slicer_Time_Frame_VIC_Breakdown 表上 [IsTimeFrameVisible VIC Breakdown] = 1 |
| 全局筛选器 | Slicer_Time_Frame_Min_VIC_Breakdown、Slicer_Time_Frame_Max_VIC_Breakdown、Slicer_Is_Employee_Selection、IsMemberFilter、Slicer_Currency_Selection |

### 6.2 度量值拉取示例

| 场景 | 拉取度量 |
|------|---------|
| New VIC SLS 趋势 | [SLS Trend Display (New VIC)] |
| New VIC SLS% 趋势 | [SLS% Trend Display (New VIC)] |
| Retention VIC SLS 趋势 | [SLS Trend Display (Retention VIC)] |
| Retention VIC SLS% 趋势 | [SLS% Trend Display (Retention VIC)] |

---

## 7. 验证方法

### 7.1 验证 SQL（SLS Trend Value (New VIC)）

```sql
-- New VIC SLS 本期值（某月，所有 platform 汇总）
-- 假设 X 轴 TimeFrame = 2026-09, Last_Fiscal_Month_Min='2026-09-01', Last_Fiscal_Month_Max='2026-09-30'
-- is_member=0 (TTL VIC), is_employee=1 (Yes), FXRate=1 (RMB)
SELECT
    SUM(net_pay_amt) / 1 AS SLS_Trend_NewVIC  -- FXRate=1 (RMB), 若 USD 则除以 7
FROM a03_e2e_customer_data_m
WHERE data_date BETWEEN '2026-09-01' AND '2026-09-30'
  AND is_new_vic = 1
  AND is_member = 0
  AND is_employee = 1;
```

### 7.2 验证 SQL（SLS% Trend Value (New VIC)）

```sql
-- New VIC SLS% 本期比率
-- 分子: is_new_vic=1 当月 SUM(net_pay_amt)
-- 分母: is_new_vic IN (0,1) 当月 SUM(net_pay_amt)
WITH numerator AS (
  SELECT SUM(net_pay_amt) AS amt
  FROM a03_e2e_customer_data_m
  WHERE data_date BETWEEN '2026-09-01' AND '2026-09-30'
    AND is_new_vic = 1
    AND is_member = 0
    AND is_employee = 1
),
denominator AS (
  SELECT SUM(net_pay_amt) AS amt
  FROM a03_e2e_customer_data_m
  WHERE data_date BETWEEN '2026-09-01' AND '2026-09-30'
    AND is_new_vic IN (0, 1)
    AND is_member = 0
    AND is_employee = 1
)
SELECT
  n.amt AS numerator,
  d.amt AS denominator,
  ROUND(n.amt * 1.0 / d.amt, 4) AS sls_pct
FROM numerator n, denominator d;
```

---

## 8. 注意事项

1. **日期表共用**：本方案与 VIC_Breakdown_ms.md 主表共用 Slicer_Time_Frame_VIC_Breakdown / _Min_ / _Max_ 三张专用日期表，但与其他模块（VIC KPI、VIC Trend、Pie Chart 等）隔离。柱形图的 X 轴筛选与主表的切片器筛选互不影响（断开维度）。

2. **柱形图 X 轴筛选**：必须配置 [IsTimeFrameVisible VIC Breakdown] = 1 作为视觉对象级别筛选器，否则 X 轴会显示所有时间段（超出 Min/Max 选择范围）。逻辑与 VIC_Trend.md IsTimeFrameVisible VIC Trend 一致。

3. **双层时间筛选**：度量值内部同时应用全局范围（TimeFrame_Min/Max）和 X 轴 end period 当月范围（Last_Fiscal_Month_Min/Max）。全局筛选冗余但保留，防止 X 轴超出全局范围时的异常显示（参考 VIC_Trend.md / PB_Location_Trend.md 范式）。

4. **New VIC / Retention VIC 区分（关键逻辑）**：
   - New VIC（Metric_ID=1/4）：筛选 `is_new_vic = 1`
   - Retention VIC（Metric_ID=23/26）：筛选 `is_retention_vic = 1`
   - SLS% 分母用 `is_xxx_vic IN {0, 1}` 全客筛选（New VIC 用 is_new_vic，Retention VIC 用 is_retention_vic）

5. **货币转换**：
   - 金额类（SLS Act，Metric_ID=1/23）÷ Currency_ExchangeRate（RMB=1, USD=7）
   - 比率类（SLS% Act，Metric_ID=4/26）不除（分子分母同币种抵消，SLS% 占比不除）
   - 货币符号从 Slicer_Currency_Selection[Currency_Symbol] 读取（默认 "¥"，USD 时为 "$"）

6. **currency_k 格式**：SLS 金额除以 1000 后保留整数，拼接货币符号 + "k"。例如 ¥1234 → "¥1k"，$5678 → "$6k"。若未来需要更精细的小数位，可调整 FORMAT 串为 "#,##0.0" 等。

7. **percent_0dp 格式**：SLS% 为比率（0~1），FORMAT "0%" 不保留小数。例如 0.4567 → "46%"。若未来需要小数位，可调整为 "0.0%"。

8. **is_member / is_employee 双重筛选**：与 VIC_Breakdown_ms.md 主表口径一致，默认 is_member=0（TTL VIC）、is_employee=1（Yes）。

9. **口径等价性**：本方案 4 个 Value 度量与 VIC_Breakdown_ms.md 主表 Metric_ID=1/4/23/26 的 Act 口径等价，差异仅在于时间筛选上下文（主表用 Slicer_Time_Frame_Max_VIC_Breakdown 全局 end period，本方案用 Slicer_Time_Frame_VIC_Breakdown X 轴 end period + 全局冗余筛选）。

10. **行维度自动传递**：柱形图若配置图例（platform / shop_info_id 等）或小多图，事实表分组字段由模型自动传递筛选上下文，DAX 无需显式处理。
