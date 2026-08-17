# Power BI 解决方案 — VIC Trend：10 个指标 Value/Display 度量（柱形图趋势）

> status: ready
> created: 2026-08-13
> type: 度量值开发 + 柱形图视觉对象
> 口径来源: 口径文档/VIC KPI.md（Metric_ID 1/2/3/6/7/8/10/11/12/14 共 10 个指标）
> 参考实现: VIC_KPIs_Pie_Chart.md（独立 Value/Display 范式）、PB_Location_Trend.md 子模块二 Fulfillment% Trend（柱形图 X 轴 + IsTimeFrameVisible 范式）
> 底表: a03_e2e_customer_data_m

---

## 1. 需求理解

为 VIC Customer Dashboard 的 VIC Trend 柱形图输出 10 个指标的独立 Value + Display 度量对：

| Metric_ID | 指标 | 类型 | 计算方式 | 原格式 | 新格式 |
|-----------|------|------|---------|--------|--------|
| 1 | VIC No. | Act | DISTINCTCOUNT(user_id) WHERE is_vic=1 | integer | integer |
| 2 | VIC No. vs LY | 数量类 vs LY | Act / LY - 1 | delta_pct_1dp | percent_1dp |
| 3 | VIC No. vs LP | 数量类 vs LP | Act / LP - 1 | delta_pct_1dp | percent_1dp |
| 6 | VIC Retention% | Act（比率） | DIVIDE(分子 is_retention_vic=1, 分母 Rolling 12 is_vic=1) | percent_1dp | percent_1dp |
| 7 | VIC Retention% vs LY | 比率类 vs LY | Act - LY（差值） | delta_pts | integer_pts |
| 8 | VIC Retention% vs LP | 比率类 vs LP | Act - LP（差值） | delta_pts | integer_pts |
| 10 | T4-5 Upgrade No. | Act | DISTINCTCOUNT(user_id) WHERE is_upgrade_vic=1 | integer | integer |
| 11 | T4-5 Upgrade No. vs LY | 数量类 vs LY | Act / LY - 1 | delta_pct_1dp | percent_1dp |
| 12 | T4-5 Upgrade No. vs LP | 数量类 vs LP | Act / LP - 1 | delta_pct_1dp | percent_1dp |
| 14 | T4-5 Upgrade No. Share | Act（比率） | DIVIDE(分子 is_upgrade_vic=1, 分母 is_vic=1 当月) | percent_1dp | percent_1dp |

**核心设计原则**：
- 每个指标独立输出 Value + Display 度量对，参考 VIC_KPIs_Pie_Chart.md 范式
- 度量值作用于柱形图（非卡片图/矩阵），X 轴 = Slicer_Time_Frame_VIC_Trend[TimeFrame_Value]
- 参考 PB_Location_Trend.md 子模块二 Fulfillment% Trend 实现，配置 IsTimeFrameVisible 视觉对象级别筛选器
- 日期表替换为 VIC Trend 专用版本（Slicer_Time_Frame_VIC_Trend / Slicer_Time_Frame_Max_VIC_Trend / Slicer_Time_Frame_Min_VIC_Trend），避免与其他模块互相筛选影响
- 保留 VIC 项目口径：end period 当月聚合（Last_Fiscal_Month_Min/Max）、is_member / is_employee 双重人群筛选、VIC Retention% 专用 Rolling 12 分母
- 格式调整：所有指标不含正号

### 1.1 格式调整说明

| 原格式 | 新格式 | 格式串 | 示例 |
|--------|--------|--------|------|
| delta_pct_1dp | percent_1dp | `FORMAT(__Value, "#,##0.0%")` | 14.5% / -3.2% |
| delta_pts | integer_pts | `FORMAT(__Value * 100, "#,##0pts;-#,##0pts;0pts")` | 120pts / -80pts |

> 去掉正号前缀 `IF(__Value>0,"+","")`，直接使用 FORMAT 输出不含正号的格式。

### 1.2 柱形图 X 轴与时间筛选范式

参考 PB_Location_Trend.md 子模块二 Fulfillment% Trend：
- 柱形图 X 轴 = Slicer_Time_Frame_VIC_Trend[TimeFrame_Value]
- 视觉对象级别筛选器：IsTimeFrameVisible VIC Trend = 1（控制 X 轴显示范围：同粒度 + Key 在 [MinKey, MaxKey] 区间）
- 度量值内部双层时间筛选：
  - 全局范围（冗余但保留）：Slicer_Time_Frame_Min_VIC_Trend[TimeFrame_Min] ~ Slicer_Time_Frame_Max_VIC_Trend[TimeFrame_Max]
  - X 轴 end period 当月上下文：Slicer_Time_Frame_VIC_Trend[Last_Fiscal_Month_Min] ~ [Last_Fiscal_Month_Max]

### 1.3 VIC Retention% 的 Rolling 12 分母（柱形图适配）

口径不变，分母 = end period 往前 Rolling 12 个财月 is_vic=1 的 DISTINCTCOUNT(user_id)。在柱形图场景下，每个柱子的 Rolling 12 区间基于该柱子 X 轴当前时间点的 Last_Fiscal_Month 推导：

- 起始月：X 轴 Last_Fiscal_Month 月份字符串 EDATE(-11) → 起始月字符串 → 查 Slicer_Time_Frame_VIC_Trend 中 TimeFrame_Label='月' AND TimeFrame_Value=起始月字符串 的 TimeFrame_Min
- 结束日：X 轴 Last_Fiscal_Month_Max
- LY/LP 的 Rolling 12 起始月：基于 X 轴 Last_Fiscal_Month 推导 LY/LP 月份字符串后再 EDATE(-11)
- LY/LP 的 Rolling 12 结束日：X 轴 Last_Fiscal_Month_Max_LY / Last_Fiscal_Month_Max_LP

---

## 2. 现状分析

### 2.1 数据底表

| 对象 | 名称 | 出处 |
|------|------|------|
| 事实表 | a03_e2e_customer_data_m | 口径文档 全局逻辑 |
| 关键字段 | data_date, platform, shop_info_id, user_id, is_member, is_employee, is_vic, is_retention_vic, is_upgrade_vic | 口径文档 |

### 2.2 维度表清单（VIC Trend 专用日期表，与其他模块隔离）

| 维度表 | 类型 | 连接方式 |
|--------|------|---------|
| Slicer_Time_Frame_VIC_Trend | 断开维度 | 柱形图 X 轴；SELECTEDVALUE 读取 TimeFrame_ID/Key/Value/Label、TimeFrame_Min/Max、TimeFrame_Min_LY/Max_LY、Last_Fiscal_Month 及 Last_Fiscal_Month_Min/Max/Min_LY/Max_LY/Min_LP/Max_LP 系列 |
| Slicer_Time_Frame_Max_VIC_Trend | 断开维度 | 结束切片器；SELECTEDVALUE 读取 TimeFrame_Max/Key/ID、TimeFrame_Max_LY、Last_Fiscal_Month 系列 |
| Slicer_Time_Frame_Min_VIC_Trend | 断开维度 | 起始切片器；SELECTEDVALUE 读取 TimeFrame_Min/Key/ID、TimeFrame_Min_LY |
| Slicer_Is_Employee_Selection | 断开维度 | SELECTEDVALUE 读取 IsEmployee_Code（默认 1 = Yes） |
| IsMemberFilter | 断开维度 | SELECTEDVALUE 读取 IsMember（默认 0 = TTL VIC） |

> **日期表结构假设**：Slicer_Time_Frame_VIC_Trend 的结构与原 Slicer_Time_Frame_Max 一致（包含 TimeFrame 系列 + Last_Fiscal_Month 系列），每个 X 轴时间点都有完整的 Last_Fiscal_Month 系列字段，用于 end period 逻辑和 Rolling 12 推导。Slicer_Time_Frame_Max_VIC_Trend / Slicer_Time_Frame_Min_VIC_Trend 的结构与原 Slicer_Time_Frame_Max / Slicer_Time_Frame_Min 一致。

---

## 3. 方案设计

### 3.1 筛选上下文

| 筛选器 | 作用方式 | DAX 处理 |
|--------|---------|---------|
| Slicer_Time_Frame_VIC_Trend（X 轴 end period） | 断开维度，SELECTEDVALUE 读取 Last_Fiscal_Month_Min/Max | `data_date >= __CurrentLFMMin AND data_date <= __CurrentLFMMax`（end period 当月） |
| Slicer_Time_Frame_VIC_Trend（X 轴 LY） | SELECTEDVALUE 读取 Last_Fiscal_Month_Min_LY/Max_LY | `data_date >= __CurrentLFMMin_LY AND data_date <= __CurrentLFMMax_LY` |
| Slicer_Time_Frame_VIC_Trend（X 轴 LP） | SELECTEDVALUE 读取 Last_Fiscal_Month_Min_LP/Max_LP | `data_date >= __CurrentLFMMin_LP AND data_date <= __CurrentLFMMax_LP` |
| Slicer_Time_Frame_Min/Max_VIC_Trend（全局范围） | 冗余保护，防止 X 轴超出全局范围 | `data_date >= __GlobalMin AND data_date <= __GlobalMax` |
| Slicer_Is_Employee_Selection | 断开维度，SELECTEDVALUE 读取 IsEmployee_Code | `is_employee = __IsEmployeeFilter`（默认 1） |
| IsMemberFilter | 断开维度，SELECTEDVALUE 读取 IsMember | `is_member = __IsMemberFilter`（默认 0） |
| 事实表分组字段（platform / shop_info_id） | 柱形图图例直接拉取，模型自动传递 | DAX 无需显式处理 |

### 3.2 度量值架构

```
IsTimeFrameVisible VIC Trend（辅助度量 — X 轴视觉对象级别筛选器）
    │
    ▼
┌─────────────────────────────────────────────────────────┐
│  基础度量层（Base Metrics，用于派生 vs LY / vs LP）       │
│                                                         │
│  VIC No. Trend Act/LY/LP Value                         │
│  VIC Retention% Trend Act/LY/LP Value（内化 Rolling 12）│
│  T4-5 Upgrade No. Trend Act/LY/LP Value                │
└──────────────────────────┬──────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────┐
│  对外度量层（VIC Trend，每个指标 Value + Display 对）     │
│                                                         │
│  Metric_ID=1:  VIC No. Trend Value / Display           │
│  Metric_ID=2:  VIC No. vs LY Trend Value / Display     │
│  Metric_ID=3:  VIC No. vs LP Trend Value / Display     │
│  Metric_ID=6:  VIC Retention% Trend Value / Display    │
│  Metric_ID=7:  VIC Retention% vs LY Trend Value/Display│
│  Metric_ID=8:  VIC Retention% vs LP Trend Value/Display│
│  Metric_ID=10: T4-5 Upgrade No. Trend Value / Display  │
│  Metric_ID=11: T4-5 Upgrade No. vs LY Trend Value/Disp │
│  Metric_ID=12: T4-5 Upgrade No. vs LP Trend Value/Disp │
│  Metric_ID=14: T4-5 Upgrade No. Share Trend Value/Disp │
└─────────────────────────────────────────────────────────┘
```

### 3.3 格式规范

| 格式类型 | 格式串 | 示例 | 适用指标 |
|---------|--------|------|---------|
| integer | `FORMAT(__Value, "#,##0")` | 1,234 | VIC No. / T4-5 Upgrade No. |
| percent_1dp | `FORMAT(__Value, "#,##0.0%")` | 14.5% / -3.2% | VIC No. vs LY/LP / VIC Retention% / T4-5 Upgrade No. vs LY/LP / T4-5 Upgrade No. Share |
| integer_pts | `FORMAT(__Value * 100, "#,##0pts;-#,##0pts;0pts")` | 120pts / -80pts | VIC Retention% vs LY / vs LP |

---

## 4. 度量值实现

### 4.1 IsTimeFrameVisible VIC Trend（辅助度量 — X 轴视觉对象级别筛选器）

> 参考 PB_Location_Trend.md 的 IsTimeFrameVisible，逻辑完全一致，仅替换日期表为 VIC Trend 版本

```dax
IsTimeFrameVisible VIC Trend =
// ========================================
// 度量值: IsTimeFrameVisible VIC Trend
// Display Folder: VIC Trend
// 用途: 判断柱形图 X 轴当前遍历的 timeframe
//       是否落在起止切片器选定的范围内（同粒度 + Key 在 [MinKey, MaxKey] 区间）
// 返回: 1（显示）或 0（隐藏）
// 依赖: Slicer_Time_Frame_VIC_Trend[TimeFrame_ID, TimeFrame_Key],
//       Slicer_Time_Frame_Min_VIC_Trend[TimeFrame_ID, TimeFrame_Key, TimeFrame_Value],
//       Slicer_Time_Frame_Max_VIC_Trend[TimeFrame_ID, TimeFrame_Key, TimeFrame_Value]
// 使用方式: 作为柱形图 X 轴的视觉对象级别筛选器
//           筛选条件: IsTimeFrameVisible VIC Trend = 1
// ========================================
    VAR __CurrentTimeFrameID = SELECTEDVALUE(Slicer_Time_Frame_VIC_Trend[TimeFrame_ID])
    VAR __CurrentKey = SELECTEDVALUE(Slicer_Time_Frame_VIC_Trend[TimeFrame_Key])
    VAR __MinTimeFrameID = SELECTEDVALUE(Slicer_Time_Frame_Min_VIC_Trend[TimeFrame_ID])
    VAR __MaxTimeFrameID = SELECTEDVALUE(Slicer_Time_Frame_Max_VIC_Trend[TimeFrame_ID])
    VAR __IsSameGranularity =
        NOT ISBLANK(__CurrentTimeFrameID)
        && __CurrentTimeFrameID = __MinTimeFrameID
        && __CurrentTimeFrameID = __MaxTimeFrameID
    VAR __MinKey =
        IF(
            ISFILTERED(Slicer_Time_Frame_Min_VIC_Trend[TimeFrame_Value]),
            MIN(Slicer_Time_Frame_Min_VIC_Trend[TimeFrame_Key]),
            MIN(Slicer_Time_Frame_VIC_Trend[TimeFrame_Key])
        )
    VAR __MaxKey =
        IF(
            ISFILTERED(Slicer_Time_Frame_Max_VIC_Trend[TimeFrame_Value]),
            MAX(Slicer_Time_Frame_Max_VIC_Trend[TimeFrame_Key]),
            MAX(Slicer_Time_Frame_VIC_Trend[TimeFrame_Key])
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

## 基础度量层（Base Metrics）

> 基础度量用于派生 vs LY / vs LP 指标，不直接对外使用。每个基础指标实现 Act / LY / LP 三个版本。

---

### 4.2 VIC No. Trend Act Value（本期基础值）

```dax
VIC No. Trend Act Value =
// ========================================
// 度量值: VIC No. Trend Act Value
// Display Folder: VIC Trend Base
// 用途: VIC No. 本期值（柱形图 Y 轴基础值）
// 口径来源: 口径文档/VIC KPI.md - 1. VIC No.
// 计算公式: DISTINCTCOUNT(user_id) WHERE is_vic = 1
// 筛选条件:
//   - data_date ∈ [Last_Fiscal_Month_Min, Last_Fiscal_Month_Max]（X 轴 end period 当月）
//   - 全局范围冗余筛选: data_date ∈ [TimeFrame_Min, TimeFrame_Max]
//   - is_member = __IsMemberFilter（默认 0 = TTL VIC）
//   - is_employee = __IsEmployeeFilter（默认 1 = Yes）
// 数据类型: integer
// ========================================
    VAR __GlobalMin = SELECTEDVALUE(Slicer_Time_Frame_Min_VIC_Trend[TimeFrame_Min])
    VAR __GlobalMax = SELECTEDVALUE(Slicer_Time_Frame_Max_VIC_Trend[TimeFrame_Max])
    VAR __CurrentLFMMin = SELECTEDVALUE(Slicer_Time_Frame_VIC_Trend[Last_Fiscal_Month_Min])
    VAR __CurrentLFMMax = SELECTEDVALUE(Slicer_Time_Frame_VIC_Trend[Last_Fiscal_Month_Max])
    VAR __IsMemberFilter = SELECTEDVALUE(IsMemberFilter[IsMember], 0)
    VAR __IsEmployeeFilter = SELECTEDVALUE(Slicer_Is_Employee_Selection[IsEmployee_Code], 1)
    VAR __Result =
        CALCULATE(
            DISTINCTCOUNT('a03_e2e_customer_data_m'[user_id]),
            'a03_e2e_customer_data_m'[is_vic] = 1,
            'a03_e2e_customer_data_m'[is_member] = __IsMemberFilter,
            'a03_e2e_customer_data_m'[is_employee] = __IsEmployeeFilter,
            'a03_e2e_customer_data_m'[data_date] >= __GlobalMin,
            'a03_e2e_customer_data_m'[data_date] <= __GlobalMax,
            'a03_e2e_customer_data_m'[data_date] >= __CurrentLFMMin,
            'a03_e2e_customer_data_m'[data_date] <= __CurrentLFMMax
        )
    RETURN __Result
```

### 4.3 VIC No. Trend LY Value（去年同期基础值）

```dax
VIC No. Trend LY Value =
// ========================================
// 度量值: VIC No. Trend LY Value
// Display Folder: VIC Trend Base
// 用途: VIC No. 去年同期值（柱形图 Y 轴基础值）
// 口径来源: 口径文档/VIC KPI.md - 1.1 VIC No. vs LY
// 计算公式: DISTINCTCOUNT(user_id) WHERE is_vic = 1（去年同期）
// 时间偏移: 财历映射
//   全局 LY 范围: Slicer_Time_Frame_Min_VIC_Trend[TimeFrame_Min_LY] / Slicer_Time_Frame_Max_VIC_Trend[TimeFrame_Max_LY]
//   X 轴 LY end period: Slicer_Time_Frame_VIC_Trend[Last_Fiscal_Month_Min_LY] / [Last_Fiscal_Month_Max_LY]
// ========================================
    VAR __GlobalMin_LY = SELECTEDVALUE(Slicer_Time_Frame_Min_VIC_Trend[TimeFrame_Min_LY])
    VAR __GlobalMax_LY = SELECTEDVALUE(Slicer_Time_Frame_Max_VIC_Trend[TimeFrame_Max_LY])
    VAR __CurrentLFMMin_LY = SELECTEDVALUE(Slicer_Time_Frame_VIC_Trend[Last_Fiscal_Month_Min_LY])
    VAR __CurrentLFMMax_LY = SELECTEDVALUE(Slicer_Time_Frame_VIC_Trend[Last_Fiscal_Month_Max_LY])
    VAR __IsMemberFilter = SELECTEDVALUE(IsMemberFilter[IsMember], 0)
    VAR __IsEmployeeFilter = SELECTEDVALUE(Slicer_Is_Employee_Selection[IsEmployee_Code], 1)
    VAR __Result =
        CALCULATE(
            DISTINCTCOUNT('a03_e2e_customer_data_m'[user_id]),
            'a03_e2e_customer_data_m'[is_vic] = 1,
            'a03_e2e_customer_data_m'[is_member] = __IsMemberFilter,
            'a03_e2e_customer_data_m'[is_employee] = __IsEmployeeFilter,
            'a03_e2e_customer_data_m'[data_date] >= __GlobalMin_LY,
            'a03_e2e_customer_data_m'[data_date] <= __GlobalMax_LY,
            'a03_e2e_customer_data_m'[data_date] >= __CurrentLFMMin_LY,
            'a03_e2e_customer_data_m'[data_date] <= __CurrentLFMMax_LY
        )
    RETURN __Result
```

### 4.4 VIC No. Trend LP Value（上期基础值）

```dax
VIC No. Trend LP Value =
// ========================================
// 度量值: VIC No. Trend LP Value
// Display Folder: VIC Trend Base
// 用途: VIC No. 上期值（柱形图 Y 轴基础值）
// 口径来源: 口径文档/VIC KPI.md - 1.2 VIC No. vs LP
// 计算公式: DISTINCTCOUNT(user_id) WHERE is_vic = 1（上期）
// 时间偏移: 财历映射
//   X 轴 LP end period: Slicer_Time_Frame_VIC_Trend[Last_Fiscal_Month_Min_LP] / [Last_Fiscal_Month_Max_LP]
// 注: LP = Last Period（上一期），按所选粒度的上一期
// ========================================
    VAR __CurrentLFMMin_LP = SELECTEDVALUE(Slicer_Time_Frame_VIC_Trend[Last_Fiscal_Month_Min_LP])
    VAR __CurrentLFMMax_LP = SELECTEDVALUE(Slicer_Time_Frame_VIC_Trend[Last_Fiscal_Month_Max_LP])
    VAR __IsMemberFilter = SELECTEDVALUE(IsMemberFilter[IsMember], 0)
    VAR __IsEmployeeFilter = SELECTEDVALUE(Slicer_Is_Employee_Selection[IsEmployee_Code], 1)
    VAR __Result =
        CALCULATE(
            DISTINCTCOUNT('a03_e2e_customer_data_m'[user_id]),
            'a03_e2e_customer_data_m'[is_vic] = 1,
            'a03_e2e_customer_data_m'[is_member] = __IsMemberFilter,
            'a03_e2e_customer_data_m'[is_employee] = __IsEmployeeFilter,
            'a03_e2e_customer_data_m'[data_date] >= __CurrentLFMMin_LP,
            'a03_e2e_customer_data_m'[data_date] <= __CurrentLFMMax_LP
        )
    RETURN __Result
```

---

### 4.5 VIC Retention% Trend Act Value（本期比率，内化 Rolling 12 分母）

```dax
VIC Retention% Trend Act Value =
// ========================================
// 度量值: VIC Retention% Trend Act Value
// Display Folder: VIC Trend Base
// 用途: VIC Retention% 本期比率（柱形图 Y 轴基础值）
// 口径来源: 口径文档/VIC KPI.md - 2. VIC Retention%
// 计算公式: DIVIDE(分子, 分母)
//   分子: DISTINCTCOUNT(user_id) WHERE is_retention_vic = 1（X 轴 end period 当月）
//   分母: DISTINCTCOUNT(user_id) WHERE is_vic = 1（X 轴 end period 往前 Rolling 12 个财月区间）
// Rolling 12 区间推导（基于 X 轴当前时间点的 Last_Fiscal_Month）:
//   1. 取 X 轴 Last_Fiscal_Month 月份字符串（如 "2026-09"）
//   2. EDATE(-11) 得起始月字符串（如 "2025-10"）
//   3. 在 Slicer_Time_Frame_VIC_Trend 中查 TimeFrame_Label='月' AND TimeFrame_Value=起始月字符串 的 TimeFrame_Min
//   4. 区间 = [起始月 TimeFrame_Min, X 轴 Last_Fiscal_Month_Max]
// 数据类型: percent_1dp（比率，0~1）
// ========================================
    VAR __GlobalMin = SELECTEDVALUE(Slicer_Time_Frame_Min_VIC_Trend[TimeFrame_Min])
    VAR __GlobalMax = SELECTEDVALUE(Slicer_Time_Frame_Max_VIC_Trend[TimeFrame_Max])
    VAR __CurrentLFMMin = SELECTEDVALUE(Slicer_Time_Frame_VIC_Trend[Last_Fiscal_Month_Min])
    VAR __CurrentLFMMax = SELECTEDVALUE(Slicer_Time_Frame_VIC_Trend[Last_Fiscal_Month_Max])
    VAR __IsMemberFilter = SELECTEDVALUE(IsMemberFilter[IsMember], 0)
    VAR __IsEmployeeFilter = SELECTEDVALUE(Slicer_Is_Employee_Selection[IsEmployee_Code], 1)

    // ── 分子: is_retention_vic=1 在 X 轴 end period 当月的 DISTINCTCOUNT ──
    VAR __Numerator =
        CALCULATE(
            DISTINCTCOUNT('a03_e2e_customer_data_m'[user_id]),
            'a03_e2e_customer_data_m'[is_retention_vic] = 1,
            'a03_e2e_customer_data_m'[is_member] = __IsMemberFilter,
            'a03_e2e_customer_data_m'[is_employee] = __IsEmployeeFilter,
            'a03_e2e_customer_data_m'[data_date] >= __GlobalMin,
            'a03_e2e_customer_data_m'[data_date] <= __GlobalMax,
            'a03_e2e_customer_data_m'[data_date] >= __CurrentLFMMin,
            'a03_e2e_customer_data_m'[data_date] <= __CurrentLFMMax
        )

    // ── 分母: is_vic=1 在 X 轴 end period 往前 Rolling 12 个财月区间的 DISTINCTCOUNT ──
    // 1. 取 X 轴当前时间点的 Last_Fiscal_Month 月份字符串
    VAR __LFM = SELECTEDVALUE(Slicer_Time_Frame_VIC_Trend[Last_Fiscal_Month])
    // 2. EDATE(-11) 得 Rolling 12 起始月字符串
    VAR __Rolling12StartMonthValue =
        FORMAT(
            EDATE(
                DATE(LEFT(__LFM, 4), RIGHT(__LFM, 2), 1),
                -11
            ),
            "yyyy-MM"
        )
    // 3. 在 Slicer_Time_Frame_VIC_Trend 中查起始月的 TimeFrame_Min
    VAR __Rolling12StartMin =
        CALCULATE(
            SELECTEDVALUE(Slicer_Time_Frame_VIC_Trend[TimeFrame_Min]),
            FILTER(
                ALL(Slicer_Time_Frame_VIC_Trend),
                Slicer_Time_Frame_VIC_Trend[TimeFrame_Label] = "月"
                && Slicer_Time_Frame_VIC_Trend[TimeFrame_Value] = __Rolling12StartMonthValue
            )
        )
    // 4. Rolling 12 区间 [起始月 TimeFrame_Min, X 轴 Last_Fiscal_Month_Max] 的 is_vic=1 DISTINCTCOUNT
    VAR __Denominator =
        CALCULATE(
            DISTINCTCOUNT('a03_e2e_customer_data_m'[user_id]),
            'a03_e2e_customer_data_m'[is_vic] = 1,
            'a03_e2e_customer_data_m'[is_member] = __IsMemberFilter,
            'a03_e2e_customer_data_m'[is_employee] = __IsEmployeeFilter,
            'a03_e2e_customer_data_m'[data_date] >= __Rolling12StartMin,
            'a03_e2e_customer_data_m'[data_date] <= __CurrentLFMMax
        )

    RETURN DIVIDE(__Numerator, __Denominator)
```

### 4.6 VIC Retention% Trend LY Value（LY 比率，内化 Rolling 12 LY 分母）

```dax
VIC Retention% Trend LY Value =
// ========================================
// 度量值: VIC Retention% Trend LY Value
// Display Folder: VIC Trend Base
// 用途: VIC Retention% 去年同期比率（柱形图 Y 轴基础值）
// 口径来源: 口径文档/VIC KPI.md - 2.1 VIC Retention% vs LY
// 计算公式: DIVIDE(分子_LY, 分母_LY)
//   分子_LY: DISTINCTCOUNT(user_id) WHERE is_retention_vic = 1（X 轴 LY end period 当月）
//   分母_LY: DISTINCTCOUNT(user_id) WHERE is_vic = 1（X 轴 LY end period 往前 Rolling 12 个财月区间）
// Rolling 12 LY 区间推导:
//   1. LY 月份字符串 = X 轴 Last_Fiscal_Month EDATE(-12)
//   2. Rolling 12 LY 起始月 = LY 月份字符串 EDATE(-11)（等价于 Last_Fiscal_Month 往前推 23 个月）
//   3. 区间 = [起始月 TimeFrame_Min, X 轴 Last_Fiscal_Month_Max_LY]
// ========================================
    VAR __GlobalMin_LY = SELECTEDVALUE(Slicer_Time_Frame_Min_VIC_Trend[TimeFrame_Min_LY])
    VAR __GlobalMax_LY = SELECTEDVALUE(Slicer_Time_Frame_Max_VIC_Trend[TimeFrame_Max_LY])
    VAR __CurrentLFMMin_LY = SELECTEDVALUE(Slicer_Time_Frame_VIC_Trend[Last_Fiscal_Month_Min_LY])
    VAR __CurrentLFMMax_LY = SELECTEDVALUE(Slicer_Time_Frame_VIC_Trend[Last_Fiscal_Month_Max_LY])
    VAR __IsMemberFilter = SELECTEDVALUE(IsMemberFilter[IsMember], 0)
    VAR __IsEmployeeFilter = SELECTEDVALUE(Slicer_Is_Employee_Selection[IsEmployee_Code], 1)

    // ── 分子_LY: is_retention_vic=1 在 X 轴 LY end period 当月的 DISTINCTCOUNT ──
    VAR __Numerator_LY =
        CALCULATE(
            DISTINCTCOUNT('a03_e2e_customer_data_m'[user_id]),
            'a03_e2e_customer_data_m'[is_retention_vic] = 1,
            'a03_e2e_customer_data_m'[is_member] = __IsMemberFilter,
            'a03_e2e_customer_data_m'[is_employee] = __IsEmployeeFilter,
            'a03_e2e_customer_data_m'[data_date] >= __GlobalMin_LY,
            'a03_e2e_customer_data_m'[data_date] <= __GlobalMax_LY,
            'a03_e2e_customer_data_m'[data_date] >= __CurrentLFMMin_LY,
            'a03_e2e_customer_data_m'[data_date] <= __CurrentLFMMax_LY
        )

    // ── 分母_LY: is_vic=1 在 X 轴 LY end period 往前 Rolling 12 个财月区间的 DISTINCTCOUNT ──
    VAR __LFM = SELECTEDVALUE(Slicer_Time_Frame_VIC_Trend[Last_Fiscal_Month])
    // LY 月份字符串: Last_Fiscal_Month 往前推 12 个月
    VAR __LFM_LY =
        FORMAT(
            EDATE(
                DATE(LEFT(__LFM, 4), RIGHT(__LFM, 2), 1),
                -12
            ),
            "yyyy-MM"
        )
    // Rolling 12 LY 起始月: LY 月份字符串往前推 11 个月
    VAR __Rolling12StartMonthValue_LY =
        FORMAT(
            EDATE(
                DATE(LEFT(__LFM_LY, 4), RIGHT(__LFM_LY, 2), 1),
                -11
            ),
            "yyyy-MM"
        )
    // 在 Slicer_Time_Frame_VIC_Trend 中查起始月的 TimeFrame_Min
    VAR __Rolling12StartMin =
        CALCULATE(
            SELECTEDVALUE(Slicer_Time_Frame_VIC_Trend[TimeFrame_Min]),
            FILTER(
                ALL(Slicer_Time_Frame_VIC_Trend),
                Slicer_Time_Frame_VIC_Trend[TimeFrame_Label] = "月"
                && Slicer_Time_Frame_VIC_Trend[TimeFrame_Value] = __Rolling12StartMonthValue_LY
            )
        )
    // Rolling 12 LY 区间 [起始月 TimeFrame_Min, X 轴 Last_Fiscal_Month_Max_LY] 的 is_vic=1 DISTINCTCOUNT
    VAR __Denominator_LY =
        CALCULATE(
            DISTINCTCOUNT('a03_e2e_customer_data_m'[user_id]),
            'a03_e2e_customer_data_m'[is_vic] = 1,
            'a03_e2e_customer_data_m'[is_member] = __IsMemberFilter,
            'a03_e2e_customer_data_m'[is_employee] = __IsEmployeeFilter,
            'a03_e2e_customer_data_m'[data_date] >= __Rolling12StartMin,
            'a03_e2e_customer_data_m'[data_date] <= __CurrentLFMMax_LY
        )

    RETURN DIVIDE(__Numerator_LY, __Denominator_LY)
```

### 4.7 VIC Retention% Trend LP Value（LP 比率，内化 Rolling 12 LP 分母）

```dax
VIC Retention% Trend LP Value =
// ========================================
// 度量值: VIC Retention% Trend LP Value
// Display Folder: VIC Trend Base
// 用途: VIC Retention% 上期比率（柱形图 Y 轴基础值）
// 口径来源: 口径文档/VIC KPI.md - 2.2 VIC Retention% vs LP
// 计算公式: DIVIDE(分子_LP, 分母_LP)
//   分子_LP: DISTINCTCOUNT(user_id) WHERE is_retention_vic = 1（X 轴 LP end period 当月）
//   分母_LP: DISTINCTCOUNT(user_id) WHERE is_vic = 1（X 轴 LP end period 往前 Rolling 12 个财月区间）
// Rolling 12 LP 区间推导:
//   1. LP 月份字符串 = X 轴 Last_Fiscal_Month EDATE(-1)
//   2. Rolling 12 LP 起始月 = LP 月份字符串 EDATE(-11)（等价于 Last_Fiscal_Month 往前推 12 个月）
//   3. 区间 = [起始月 TimeFrame_Min, X 轴 Last_Fiscal_Month_Max_LP]
// ========================================
    VAR __CurrentLFMMin_LP = SELECTEDVALUE(Slicer_Time_Frame_VIC_Trend[Last_Fiscal_Month_Min_LP])
    VAR __CurrentLFMMax_LP = SELECTEDVALUE(Slicer_Time_Frame_VIC_Trend[Last_Fiscal_Month_Max_LP])
    VAR __IsMemberFilter = SELECTEDVALUE(IsMemberFilter[IsMember], 0)
    VAR __IsEmployeeFilter = SELECTEDVALUE(Slicer_Is_Employee_Selection[IsEmployee_Code], 1)

    // ── 分子_LP: is_retention_vic=1 在 X 轴 LP end period 当月的 DISTINCTCOUNT ──
    VAR __Numerator_LP =
        CALCULATE(
            DISTINCTCOUNT('a03_e2e_customer_data_m'[user_id]),
            'a03_e2e_customer_data_m'[is_retention_vic] = 1,
            'a03_e2e_customer_data_m'[is_member] = __IsMemberFilter,
            'a03_e2e_customer_data_m'[is_employee] = __IsEmployeeFilter,
            'a03_e2e_customer_data_m'[data_date] >= __CurrentLFMMin_LP,
            'a03_e2e_customer_data_m'[data_date] <= __CurrentLFMMax_LP
        )

    // ── 分母_LP: is_vic=1 在 X 轴 LP end period 往前 Rolling 12 个财月区间的 DISTINCTCOUNT ──
    VAR __LFM = SELECTEDVALUE(Slicer_Time_Frame_VIC_Trend[Last_Fiscal_Month])
    // LP 月份字符串: Last_Fiscal_Month 往前推 1 个月
    VAR __LFM_LP =
        FORMAT(
            EDATE(
                DATE(LEFT(__LFM, 4), RIGHT(__LFM, 2), 1),
                -1
            ),
            "yyyy-MM"
        )
    // Rolling 12 LP 起始月: LP 月份字符串往前推 11 个月
    VAR __Rolling12StartMonthValue_LP =
        FORMAT(
            EDATE(
                DATE(LEFT(__LFM_LP, 4), RIGHT(__LFM_LP, 2), 1),
                -11
            ),
            "yyyy-MM"
        )
    // 在 Slicer_Time_Frame_VIC_Trend 中查起始月的 TimeFrame_Min
    VAR __Rolling12StartMin =
        CALCULATE(
            SELECTEDVALUE(Slicer_Time_Frame_VIC_Trend[TimeFrame_Min]),
            FILTER(
                ALL(Slicer_Time_Frame_VIC_Trend),
                Slicer_Time_Frame_VIC_Trend[TimeFrame_Label] = "月"
                && Slicer_Time_Frame_VIC_Trend[TimeFrame_Value] = __Rolling12StartMonthValue_LP
            )
        )
    // Rolling 12 LP 区间 [起始月 TimeFrame_Min, X 轴 Last_Fiscal_Month_Max_LP] 的 is_vic=1 DISTINCTCOUNT
    VAR __Denominator_LP =
        CALCULATE(
            DISTINCTCOUNT('a03_e2e_customer_data_m'[user_id]),
            'a03_e2e_customer_data_m'[is_vic] = 1,
            'a03_e2e_customer_data_m'[is_member] = __IsMemberFilter,
            'a03_e2e_customer_data_m'[is_employee] = __IsEmployeeFilter,
            'a03_e2e_customer_data_m'[data_date] >= __Rolling12StartMin,
            'a03_e2e_customer_data_m'[data_date] <= __CurrentLFMMax_LP
        )

    RETURN DIVIDE(__Numerator_LP, __Denominator_LP)
```

---

### 4.8 T4-5 Upgrade No. Trend Act Value（本期基础值）

```dax
T4-5 Upgrade No. Trend Act Value =
// ========================================
// 度量值: T4-5 Upgrade No. Trend Act Value
// Display Folder: VIC Trend Base
// 用途: T4-5 Upgrade No. 本期值（柱形图 Y 轴基础值）
// 口径来源: 口径文档/VIC KPI.md - 3. T4-5 Upgrade No.
// 计算公式: DISTINCTCOUNT(user_id) WHERE is_upgrade_vic = 1
// 筛选条件:
//   - data_date ∈ [Last_Fiscal_Month_Min, Last_Fiscal_Month_Max]（X 轴 end period 当月）
//   - 全局范围冗余筛选: data_date ∈ [TimeFrame_Min, TimeFrame_Max]
//   - is_member = __IsMemberFilter（默认 0 = TTL VIC）
//   - is_employee = __IsEmployeeFilter（默认 1 = Yes）
// 数据类型: integer
// ========================================
    VAR __GlobalMin = SELECTEDVALUE(Slicer_Time_Frame_Min_VIC_Trend[TimeFrame_Min])
    VAR __GlobalMax = SELECTEDVALUE(Slicer_Time_Frame_Max_VIC_Trend[TimeFrame_Max])
    VAR __CurrentLFMMin = SELECTEDVALUE(Slicer_Time_Frame_VIC_Trend[Last_Fiscal_Month_Min])
    VAR __CurrentLFMMax = SELECTEDVALUE(Slicer_Time_Frame_VIC_Trend[Last_Fiscal_Month_Max])
    VAR __IsMemberFilter = SELECTEDVALUE(IsMemberFilter[IsMember], 0)
    VAR __IsEmployeeFilter = SELECTEDVALUE(Slicer_Is_Employee_Selection[IsEmployee_Code], 1)
    VAR __Result =
        CALCULATE(
            DISTINCTCOUNT('a03_e2e_customer_data_m'[user_id]),
            'a03_e2e_customer_data_m'[is_upgrade_vic] = 1,
            'a03_e2e_customer_data_m'[is_member] = __IsMemberFilter,
            'a03_e2e_customer_data_m'[is_employee] = __IsEmployeeFilter,
            'a03_e2e_customer_data_m'[data_date] >= __GlobalMin,
            'a03_e2e_customer_data_m'[data_date] <= __GlobalMax,
            'a03_e2e_customer_data_m'[data_date] >= __CurrentLFMMin,
            'a03_e2e_customer_data_m'[data_date] <= __CurrentLFMMax
        )
    RETURN __Result
```

### 4.9 T4-5 Upgrade No. Trend LY Value（去年同期基础值）

```dax
T4-5 Upgrade No. Trend LY Value =
// ========================================
// 度量值: T4-5 Upgrade No. Trend LY Value
// Display Folder: VIC Trend Base
// 用途: T4-5 Upgrade No. 去年同期值（柱形图 Y 轴基础值）
// 口径来源: 口径文档/VIC KPI.md - 3.1 T4-5 Upgrade No. vs LY
// 计算公式: DISTINCTCOUNT(user_id) WHERE is_upgrade_vic = 1（去年同期）
// 时间偏移: 财历映射
//   全局 LY 范围: Slicer_Time_Frame_Min_VIC_Trend[TimeFrame_Min_LY] / Slicer_Time_Frame_Max_VIC_Trend[TimeFrame_Max_LY]
//   X 轴 LY end period: Slicer_Time_Frame_VIC_Trend[Last_Fiscal_Month_Min_LY] / [Last_Fiscal_Month_Max_LY]
// ========================================
    VAR __GlobalMin_LY = SELECTEDVALUE(Slicer_Time_Frame_Min_VIC_Trend[TimeFrame_Min_LY])
    VAR __GlobalMax_LY = SELECTEDVALUE(Slicer_Time_Frame_Max_VIC_Trend[TimeFrame_Max_LY])
    VAR __CurrentLFMMin_LY = SELECTEDVALUE(Slicer_Time_Frame_VIC_Trend[Last_Fiscal_Month_Min_LY])
    VAR __CurrentLFMMax_LY = SELECTEDVALUE(Slicer_Time_Frame_VIC_Trend[Last_Fiscal_Month_Max_LY])
    VAR __IsMemberFilter = SELECTEDVALUE(IsMemberFilter[IsMember], 0)
    VAR __IsEmployeeFilter = SELECTEDVALUE(Slicer_Is_Employee_Selection[IsEmployee_Code], 1)
    VAR __Result =
        CALCULATE(
            DISTINCTCOUNT('a03_e2e_customer_data_m'[user_id]),
            'a03_e2e_customer_data_m'[is_upgrade_vic] = 1,
            'a03_e2e_customer_data_m'[is_member] = __IsMemberFilter,
            'a03_e2e_customer_data_m'[is_employee] = __IsEmployeeFilter,
            'a03_e2e_customer_data_m'[data_date] >= __GlobalMin_LY,
            'a03_e2e_customer_data_m'[data_date] <= __GlobalMax_LY,
            'a03_e2e_customer_data_m'[data_date] >= __CurrentLFMMin_LY,
            'a03_e2e_customer_data_m'[data_date] <= __CurrentLFMMax_LY
        )
    RETURN __Result
```

### 4.10 T4-5 Upgrade No. Trend LP Value（上期基础值）

```dax
T4-5 Upgrade No. Trend LP Value =
// ========================================
// 度量值: T4-5 Upgrade No. Trend LP Value
// Display Folder: VIC Trend Base
// 用途: T4-5 Upgrade No. 上期值（柱形图 Y 轴基础值）
// 口径来源: 口径文档/VIC KPI.md - 3.2 T4-5 Upgrade No. vs LP
// 计算公式: DISTINCTCOUNT(user_id) WHERE is_upgrade_vic = 1（上期）
// 时间偏移: 财历映射
//   X 轴 LP end period: Slicer_Time_Frame_VIC_Trend[Last_Fiscal_Month_Min_LP] / [Last_Fiscal_Month_Max_LP]
// ========================================
    VAR __CurrentLFMMin_LP = SELECTEDVALUE(Slicer_Time_Frame_VIC_Trend[Last_Fiscal_Month_Min_LP])
    VAR __CurrentLFMMax_LP = SELECTEDVALUE(Slicer_Time_Frame_VIC_Trend[Last_Fiscal_Month_Max_LP])
    VAR __IsMemberFilter = SELECTEDVALUE(IsMemberFilter[IsMember], 0)
    VAR __IsEmployeeFilter = SELECTEDVALUE(Slicer_Is_Employee_Selection[IsEmployee_Code], 1)
    VAR __Result =
        CALCULATE(
            DISTINCTCOUNT('a03_e2e_customer_data_m'[user_id]),
            'a03_e2e_customer_data_m'[is_upgrade_vic] = 1,
            'a03_e2e_customer_data_m'[is_member] = __IsMemberFilter,
            'a03_e2e_customer_data_m'[is_employee] = __IsEmployeeFilter,
            'a03_e2e_customer_data_m'[data_date] >= __CurrentLFMMin_LP,
            'a03_e2e_customer_data_m'[data_date] <= __CurrentLFMMax_LP
        )
    RETURN __Result
```

---

## 对外度量层（VIC Trend）

> 每个指标独立输出 Value + Display 度量对，参考 VIC_KPIs_Pie_Chart.md 范式

---

### 指标 1：VIC No.（Metric_ID=1）

> 数量类 · is_vic=1 · DISTINCTCOUNT(user_id) · 格式: integer

### 4.11 VIC No. Trend Value

```dax
VIC No. Trend Value =
// ========================================
// 度量值: VIC No. Trend Value
// Display Folder: VIC Trend
// 用途: VIC No. 本期值（柱形图 Y 轴）
// 依赖: [VIC No. Trend Act Value]
// Metric_ID: 1
// 数据类型: integer → 千分位整数
// ========================================
    [VIC No. Trend Act Value]
```

### 4.12 VIC No. Trend Display

```dax
VIC No. Trend Display =
// ========================================
// 度量值: VIC No. Trend Display
// Display Folder: VIC Trend
// 用途: VIC No. 格式化显示
// 依赖: [VIC No. Trend Value]
// 格式类型: integer → #,##0
// ========================================
    VAR __Value = [VIC No. Trend Value]
    RETURN
        IF(ISBLANK(__Value), "-", FORMAT(__Value, "#,##0"))
```

---

### 指标 2：VIC No. vs LY（Metric_ID=2）

> 数量类 vs LY · Act / LY - 1 · 格式: percent_1dp（不含正号）

### 4.13 VIC No. vs LY Trend Value

```dax
VIC No. vs LY Trend Value =
// ========================================
// 度量值: VIC No. vs LY Trend Value
// Display Folder: VIC Trend
// 用途: VIC No. 同比（今年/去年-1）
// 依赖: [VIC No. Trend Act Value], [VIC No. Trend LY Value]
// Metric_ID: 2
// 数据类型: percent_1dp → 百分比，保留一位小数，不含正号
// ========================================
    VAR __Act = [VIC No. Trend Act Value]
    VAR __LY = [VIC No. Trend LY Value]
    RETURN DIVIDE(__Act, __LY) - 1
```

### 4.14 VIC No. vs LY Trend Display

```dax
VIC No. vs LY Trend Display =
// ========================================
// 度量值: VIC No. vs LY Trend Display
// Display Folder: VIC Trend
// 用途: VIC No. 同比 格式化显示
// 依赖: [VIC No. vs LY Trend Value]
// 格式类型: percent_1dp → #,##0.0%（不含正号）
// ========================================
    VAR __Value = [VIC No. vs LY Trend Value]
    RETURN
        IF(ISBLANK(__Value), "-", FORMAT(__Value, "#,##0.0%"))
```

---

### 指标 3：VIC No. vs LP（Metric_ID=3）

> 数量类 vs LP · Act / LP - 1 · 格式: percent_1dp（不含正号）

### 4.15 VIC No. vs LP Trend Value

```dax
VIC No. vs LP Trend Value =
// ========================================
// 度量值: VIC No. vs LP Trend Value
// Display Folder: VIC Trend
// 用途: VIC No. 环比（当期/上期-1）
// 依赖: [VIC No. Trend Act Value], [VIC No. Trend LP Value]
// Metric_ID: 3
// 数据类型: percent_1dp → 百分比，保留一位小数，不含正号
// ========================================
    VAR __Act = [VIC No. Trend Act Value]
    VAR __LP = [VIC No. Trend LP Value]
    RETURN DIVIDE(__Act, __LP) - 1
```

### 4.16 VIC No. vs LP Trend Display

```dax
VIC No. vs LP Trend Display =
// ========================================
// 度量值: VIC No. vs LP Trend Display
// Display Folder: VIC Trend
// 用途: VIC No. 环比 格式化显示
// 依赖: [VIC No. vs LP Trend Value]
// 格式类型: percent_1dp → #,##0.0%（不含正号）
// ========================================
    VAR __Value = [VIC No. vs LP Trend Value]
    RETURN
        IF(ISBLANK(__Value), "-", FORMAT(__Value, "#,##0.0%"))
```

---

### 指标 6：VIC Retention%（Metric_ID=6）

> 比率类 · DIVIDE(分子 is_retention_vic=1, 分母 Rolling 12 is_vic=1) · 格式: percent_1dp

### 4.17 VIC Retention% Trend Value

```dax
VIC Retention% Trend Value =
// ========================================
// 度量值: VIC Retention% Trend Value
// Display Folder: VIC Trend
// 用途: VIC Retention% 本期比率（柱形图 Y 轴）
// 依赖: [VIC Retention% Trend Act Value]（已内化 Rolling 12 分母）
// Metric_ID: 6
// 数据类型: percent_1dp → 百分比，保留一位小数，不含正号
// ========================================
    [VIC Retention% Trend Act Value]
```

### 4.18 VIC Retention% Trend Display

```dax
VIC Retention% Trend Display =
// ========================================
// 度量值: VIC Retention% Trend Display
// Display Folder: VIC Trend
// 用途: VIC Retention% 格式化显示
// 依赖: [VIC Retention% Trend Value]
// 格式类型: percent_1dp → #,##0.0%
// ========================================
    VAR __Value = [VIC Retention% Trend Value]
    RETURN
        IF(ISBLANK(__Value), "-", FORMAT(__Value, "#,##0.0%"))
```

---

### 指标 7：VIC Retention% vs LY（Metric_ID=7）

> 比率类 vs LY · Act - LY（差值） · 格式: integer_pts（不含正号）

### 4.19 VIC Retention% vs LY Trend Value

```dax
VIC Retention% vs LY Trend Value =
// ========================================
// 度量值: VIC Retention% vs LY Trend Value
// Display Folder: VIC Trend
// 用途: VIC Retention% 同比差值（今年 - 去年）
// 依赖: [VIC Retention% Trend Act Value], [VIC Retention% Trend LY Value]
// Metric_ID: 7
// 数据类型: integer_pts → 整数 pts，不含正号
// 说明: Act/LY Base Value 已内化 Rolling 12 分母返回比率，此处做比率差值
// ========================================
    VAR __Act = [VIC Retention% Trend Act Value]
    VAR __LY = [VIC Retention% Trend LY Value]
    RETURN __Act - __LY
```

### 4.20 VIC Retention% vs LY Trend Display

```dax
VIC Retention% vs LY Trend Display =
// ========================================
// 度量值: VIC Retention% vs LY Trend Display
// Display Folder: VIC Trend
// 用途: VIC Retention% 同比差值 格式化显示
// 依赖: [VIC Retention% vs LY Trend Value]
// 格式类型: integer_pts → FORMAT(__Value * 100, "#,##0pts;-#,##0pts;0pts")（不含正号）
// 示例: 120pts / -80pts / 0pts
// ========================================
    VAR __Value = [VIC Retention% vs LY Trend Value]
    RETURN
        IF(ISBLANK(__Value), "-", FORMAT(__Value * 100, "#,##0pts;-#,##0pts;0pts"))
```

---

### 指标 8：VIC Retention% vs LP（Metric_ID=8）

> 比率类 vs LP · Act - LP（差值） · 格式: integer_pts（不含正号）

### 4.21 VIC Retention% vs LP Trend Value

```dax
VIC Retention% vs LP Trend Value =
// ========================================
// 度量值: VIC Retention% vs LP Trend Value
// Display Folder: VIC Trend
// 用途: VIC Retention% 环比差值（当期 - 上期）
// 依赖: [VIC Retention% Trend Act Value], [VIC Retention% Trend LP Value]
// Metric_ID: 8
// 数据类型: integer_pts → 整数 pts，不含正号
// 说明: Act/LP Base Value 已内化 Rolling 12 分母返回比率，此处做比率差值
// ========================================
    VAR __Act = [VIC Retention% Trend Act Value]
    VAR __LP = [VIC Retention% Trend LP Value]
    RETURN __Act - __LP
```

### 4.22 VIC Retention% vs LP Trend Display

```dax
VIC Retention% vs LP Trend Display =
// ========================================
// 度量值: VIC Retention% vs LP Trend Display
// Display Folder: VIC Trend
// 用途: VIC Retention% 环比差值 格式化显示
// 依赖: [VIC Retention% vs LP Trend Value]
// 格式类型: integer_pts → FORMAT(__Value * 100, "#,##0pts;-#,##0pts;0pts")（不含正号）
// 示例: 120pts / -80pts / 0pts
// ========================================
    VAR __Value = [VIC Retention% vs LP Trend Value]
    RETURN
        IF(ISBLANK(__Value), "-", FORMAT(__Value * 100, "#,##0pts;-#,##0pts;0pts"))
```

---

### 指标 10：T4-5 Upgrade No.（Metric_ID=10）

> 数量类 · is_upgrade_vic=1 · DISTINCTCOUNT(user_id) · 格式: integer

### 4.23 T4-5 Upgrade No. Trend Value

```dax
T4-5 Upgrade No. Trend Value =
// ========================================
// 度量值: T4-5 Upgrade No. Trend Value
// Display Folder: VIC Trend
// 用途: T4-5 Upgrade No. 本期值（柱形图 Y 轴）
// 依赖: [T4-5 Upgrade No. Trend Act Value]
// Metric_ID: 10
// 数据类型: integer → 千分位整数
// ========================================
    [T4-5 Upgrade No. Trend Act Value]
```

### 4.24 T4-5 Upgrade No. Trend Display

```dax
T4-5 Upgrade No. Trend Display =
// ========================================
// 度量值: T4-5 Upgrade No. Trend Display
// Display Folder: VIC Trend
// 用途: T4-5 Upgrade No. 格式化显示
// 依赖: [T4-5 Upgrade No. Trend Value]
// 格式类型: integer → #,##0
// ========================================
    VAR __Value = [T4-5 Upgrade No. Trend Value]
    RETURN
        IF(ISBLANK(__Value), "-", FORMAT(__Value, "#,##0"))
```

---

### 指标 11：T4-5 Upgrade No. vs LY（Metric_ID=11）

> 数量类 vs LY · Act / LY - 1 · 格式: percent_1dp（不含正号）

### 4.25 T4-5 Upgrade No. vs LY Trend Value

```dax
T4-5 Upgrade No. vs LY Trend Value =
// ========================================
// 度量值: T4-5 Upgrade No. vs LY Trend Value
// Display Folder: VIC Trend
// 用途: T4-5 Upgrade No. 同比（今年/去年-1）
// 依赖: [T4-5 Upgrade No. Trend Act Value], [T4-5 Upgrade No. Trend LY Value]
// Metric_ID: 11
// 数据类型: percent_1dp → 百分比，保留一位小数，不含正号
// ========================================
    VAR __Act = [T4-5 Upgrade No. Trend Act Value]
    VAR __LY = [T4-5 Upgrade No. Trend LY Value]
    RETURN DIVIDE(__Act, __LY) - 1
```

### 4.26 T4-5 Upgrade No. vs LY Trend Display

```dax
T4-5 Upgrade No. vs LY Trend Display =
// ========================================
// 度量值: T4-5 Upgrade No. vs LY Trend Display
// Display Folder: VIC Trend
// 用途: T4-5 Upgrade No. 同比 格式化显示
// 依赖: [T4-5 Upgrade No. vs LY Trend Value]
// 格式类型: percent_1dp → #,##0.0%（不含正号）
// ========================================
    VAR __Value = [T4-5 Upgrade No. vs LY Trend Value]
    RETURN
        IF(ISBLANK(__Value), "-", FORMAT(__Value, "#,##0.0%"))
```

---

### 指标 12：T4-5 Upgrade No. vs LP（Metric_ID=12）

> 数量类 vs LP · Act / LP - 1 · 格式: percent_1dp（不含正号）

### 4.27 T4-5 Upgrade No. vs LP Trend Value

```dax
T4-5 Upgrade No. vs LP Trend Value =
// ========================================
// 度量值: T4-5 Upgrade No. vs LP Trend Value
// Display Folder: VIC Trend
// 用途: T4-5 Upgrade No. 环比（当期/上期-1）
// 依赖: [T4-5 Upgrade No. Trend Act Value], [T4-5 Upgrade No. Trend LP Value]
// Metric_ID: 12
// 数据类型: percent_1dp → 百分比，保留一位小数，不含正号
// ========================================
    VAR __Act = [T4-5 Upgrade No. Trend Act Value]
    VAR __LP = [T4-5 Upgrade No. Trend LP Value]
    RETURN DIVIDE(__Act, __LP) - 1
```

### 4.28 T4-5 Upgrade No. vs LP Trend Display

```dax
T4-5 Upgrade No. vs LP Trend Display =
// ========================================
// 度量值: T4-5 Upgrade No. vs LP Trend Display
// Display Folder: VIC Trend
// 用途: T4-5 Upgrade No. 环比 格式化显示
// 依赖: [T4-5 Upgrade No. vs LP Trend Value]
// 格式类型: percent_1dp → #,##0.0%（不含正号）
// ========================================
    VAR __Value = [T4-5 Upgrade No. vs LP Trend Value]
    RETURN
        IF(ISBLANK(__Value), "-", FORMAT(__Value, "#,##0.0%"))
```

---

### 指标 14：T4-5 Upgrade No. Share（Metric_ID=14）

> 比率类 · DIVIDE(分子 is_upgrade_vic=1, 分母 is_vic=1 当月) · 格式: percent_1dp
> 分母使用 X 轴 end period 当月 is_vic=1 的 DISTINCTCOUNT，等价于 VIC No. Trend Act Value

### 4.29 T4-5 Upgrade No. Share Trend Value

```dax
T4-5 Upgrade No. Share Trend Value =
// ========================================
// 度量值: T4-5 Upgrade No. Share Trend Value
// Display Folder: VIC Trend
// 用途: T4-5 Upgrade No. Share 本期比率（柱形图 Y 轴）
// 依赖: [T4-5 Upgrade No. Trend Act Value]（分子）, [VIC No. Trend Act Value]（分母）
// Metric_ID: 14
// 计算公式: DIVIDE(分子 is_upgrade_vic=1, 分母 is_vic=1 当月)
//   分子: T4-5 Upgrade No. Trend Act Value
//   分母: VIC No. Trend Act Value（end period 当月 is_vic=1）
// 数据类型: percent_1dp → 百分比，保留一位小数，不含正号
// ========================================
    VAR __Numerator = [T4-5 Upgrade No. Trend Act Value]
    VAR __Denominator = [VIC No. Trend Act Value]
    RETURN DIVIDE(__Numerator, __Denominator)
```

### 4.30 T4-5 Upgrade No. Share Trend Display

```dax
T4-5 Upgrade No. Share Trend Display =
// ========================================
// 度量值: T4-5 Upgrade No. Share Trend Display
// Display Folder: VIC Trend
// 用途: T4-5 Upgrade No. Share 格式化显示
// 依赖: [T4-5 Upgrade No. Share Trend Value]
// 格式类型: percent_1dp → #,##0.0%
// ========================================
    VAR __Value = [T4-5 Upgrade No. Share Trend Value]
    RETURN
        IF(ISBLANK(__Value), "-", FORMAT(__Value, "#,##0.0%"))
```

---

## 5. 度量值清单与 Display Folder

| 序号 | 度量值名称 | Display Folder | Metric_ID | 指标 | 类型 | 格式 |
|------|-----------|----------------|-----------|------|------|------|
| 1 | IsTimeFrameVisible VIC Trend | VIC Trend | — | X 轴筛选器 | 辅助 | — |
| 2 | VIC No. Trend Act Value | VIC Trend Base | 1 | VIC No. | 基础 Act | integer |
| 3 | VIC No. Trend LY Value | VIC Trend Base | 1 | VIC No. | 基础 LY | integer |
| 4 | VIC No. Trend LP Value | VIC Trend Base | 1 | VIC No. | 基础 LP | integer |
| 5 | VIC Retention% Trend Act Value | VIC Trend Base | 6 | VIC Retention% | 基础 Act | percent_1dp |
| 6 | VIC Retention% Trend LY Value | VIC Trend Base | 6 | VIC Retention% | 基础 LY | percent_1dp |
| 7 | VIC Retention% Trend LP Value | VIC Trend Base | 6 | VIC Retention% | 基础 LP | percent_1dp |
| 8 | T4-5 Upgrade No. Trend Act Value | VIC Trend Base | 10 | T4-5 Upgrade No. | 基础 Act | integer |
| 9 | T4-5 Upgrade No. Trend LY Value | VIC Trend Base | 10 | T4-5 Upgrade No. | 基础 LY | integer |
| 10 | T4-5 Upgrade No. Trend LP Value | VIC Trend Base | 10 | T4-5 Upgrade No. | 基础 LP | integer |
| 11 | VIC No. Trend Value | VIC Trend | 1 | VIC No. | Value | integer |
| 12 | VIC No. Trend Display | VIC Trend | 1 | VIC No. | Display | integer |
| 13 | VIC No. vs LY Trend Value | VIC Trend | 2 | VIC No. vs LY | Value | percent_1dp |
| 14 | VIC No. vs LY Trend Display | VIC Trend | 2 | VIC No. vs LY | Display | percent_1dp |
| 15 | VIC No. vs LP Trend Value | VIC Trend | 3 | VIC No. vs LP | Value | percent_1dp |
| 16 | VIC No. vs LP Trend Display | VIC Trend | 3 | VIC No. vs LP | Display | percent_1dp |
| 17 | VIC Retention% Trend Value | VIC Trend | 6 | VIC Retention% | Value | percent_1dp |
| 18 | VIC Retention% Trend Display | VIC Trend | 6 | VIC Retention% | Display | percent_1dp |
| 19 | VIC Retention% vs LY Trend Value | VIC Trend | 7 | VIC Retention% vs LY | Value | integer_pts |
| 20 | VIC Retention% vs LY Trend Display | VIC Trend | 7 | VIC Retention% vs LY | Display | integer_pts |
| 21 | VIC Retention% vs LP Trend Value | VIC Trend | 8 | VIC Retention% vs LP | Value | integer_pts |
| 22 | VIC Retention% vs LP Trend Display | VIC Trend | 8 | VIC Retention% vs LP | Display | integer_pts |
| 23 | T4-5 Upgrade No. Trend Value | VIC Trend | 10 | T4-5 Upgrade No. | Value | integer |
| 24 | T4-5 Upgrade No. Trend Display | VIC Trend | 10 | T4-5 Upgrade No. | Display | integer |
| 25 | T4-5 Upgrade No. vs LY Trend Value | VIC Trend | 11 | T4-5 Upgrade No. vs LY | Value | percent_1dp |
| 26 | T4-5 Upgrade No. vs LY Trend Display | VIC Trend | 11 | T4-5 Upgrade No. vs LY | Display | percent_1dp |
| 27 | T4-5 Upgrade No. vs LP Trend Value | VIC Trend | 12 | T4-5 Upgrade No. vs LP | Value | percent_1dp |
| 28 | T4-5 Upgrade No. vs LP Trend Display | VIC Trend | 12 | T4-5 Upgrade No. vs LP | Display | percent_1dp |
| 29 | T4-5 Upgrade No. Share Trend Value | VIC Trend | 14 | T4-5 Upgrade No. Share | Value | percent_1dp |
| 30 | T4-5 Upgrade No. Share Trend Display | VIC Trend | 14 | T4-5 Upgrade No. Share | Display | percent_1dp |

---

## 6. 视觉对象配置

### 6.1 柱形图（VIC Trend）

| 配置项 | 值 |
|--------|-----|
| X 轴 | Slicer_Time_Frame_VIC_Trend[TimeFrame_Value] |
| Y 轴 | 按需拉取 10 个 Value 度量之一（如 [VIC No. Trend Value]） |
| 图例 | 可选：a03_e2e_customer_data_m[platform] 或 [shop_info_id]（直接拉取，天然筛选+分组） |
| 数据标签 | 对应 [* Display] 度量 |
| 视觉对象级别筛选器 | Slicer_Time_Frame_VIC_Trend 表上 [IsTimeFrameVisible VIC Trend] = 1 |
| 全局筛选器 | Slicer_Time_Frame_Min_VIC_Trend、Slicer_Time_Frame_Max_VIC_Trend、Slicer_Is_Employee_Selection、IsMemberFilter |

### 6.2 度量值拉取示例

| 场景 | 拉取度量 |
|------|---------|
| VIC No. 趋势 | [VIC No. Trend Display] |
| VIC No. 同比趋势 | [VIC No. vs LY Trend Display] |
| VIC No. 环比趋势 | [VIC No. vs LP Trend Display] |
| VIC Retention% 趋势 | [VIC Retention% Trend Display] |
| VIC Retention% 同比差值趋势 | [VIC Retention% vs LY Trend Display] |
| VIC Retention% 环比差值趋势 | [VIC Retention% vs LP Trend Display] |
| T4-5 Upgrade No. 趋势 | [T4-5 Upgrade No. Trend Display] |
| T4-5 Upgrade No. 同比趋势 | [T4-5 Upgrade No. vs LY Trend Display] |
| T4-5 Upgrade No. 环比趋势 | [T4-5 Upgrade No. vs LP Trend Display] |
| T4-5 Upgrade No. Share 趋势 | [T4-5 Upgrade No. Share Trend Display] |

---

## 7. 验证方法

### 7.1 验证 SQL（以 VIC No. Trend Act Value 为例）

```sql
-- VIC No. 本期值（某月，所有 platform 汇总）
-- 假设 X 轴 TimeFrame = 2026-09, Last_Fiscal_Month_Min='2026-09-01', Last_Fiscal_Month_Max='2026-09-30'
-- is_member=0 (TTL VIC), is_employee=1 (Yes)
SELECT COUNT(DISTINCT user_id) AS VIC_No_Trend_Act
FROM a03_e2e_customer_data_m
WHERE data_date BETWEEN '2026-09-01' AND '2026-09-30'
  AND is_vic = 1
  AND is_member = 0
  AND is_employee = 1;
```

### 7.2 验证 SQL（VIC Retention% Trend Act Value，含 Rolling 12 分母）

```sql
-- VIC Retention% 本期比率
-- 分子: is_retention_vic=1 当月 DISTINCTCOUNT
-- 分母: is_vic=1 Rolling 12 区间 DISTINCTCOUNT（2025-10 ~ 2026-09）
WITH numerator AS (
  SELECT COUNT(DISTINCT user_id) AS cnt
  FROM a03_e2e_customer_data_m
  WHERE data_date BETWEEN '2026-09-01' AND '2026-09-30'
    AND is_retention_vic = 1
    AND is_member = 0
    AND is_employee = 1
),
denominator AS (
  SELECT COUNT(DISTINCT user_id) AS cnt
  FROM a03_e2e_customer_data_m
  WHERE data_date BETWEEN '2025-10-01' AND '2026-09-30'
    AND is_vic = 1
    AND is_member = 0
    AND is_employee = 1
)
SELECT
  n.cnt AS numerator,
  d.cnt AS denominator,
  ROUND(n.cnt * 1.0 / d.cnt, 4) AS retention_pct
FROM numerator n, denominator d;
```

---

## 8. 注意事项

1. **日期表隔离**：本方案使用 Slicer_Time_Frame_VIC_Trend / Slicer_Time_Frame_Max_VIC_Trend / Slicer_Time_Frame_Min_VIC_Trend 三张专用日期表，结构与原 Slicer_Time_Frame 系列一致，仅改名以避免与其他模块（VIC KPI 矩阵、Pie Chart 等）互相筛选影响。

2. **柱形图 X 轴筛选**：必须配置 [IsTimeFrameVisible VIC Trend] = 1 作为视觉对象级别筛选器，否则 X 轴会显示所有时间段（超出 Min/Max 选择范围）。逻辑与 PB_Location_Trend.md IsTimeFrameVisible 一致。

3. **双层时间筛选**：度量值内部同时应用全局范围（TimeFrame_Min/Max）和 X 轴 end period 当月范围（Last_Fiscal_Month_Min/Max）。全局筛选冗余但保留，防止 X 轴超出全局范围时的异常显示（参考 PB_Location_Trend.md 子模块二的范式）。

4. **VIC Retention% 的 Rolling 12 分母（关键逻辑）**：分母基于 X 轴当前时间点的 Last_Fiscal_Month 推导 Rolling 12 区间，每个柱子独立计算自己的 Rolling 12 区间（非全局统一区间）。
   - 本期：Last_Fiscal_Month EDATE(-11) 起始月 → [起始月 TimeFrame_Min, Last_Fiscal_Month_Max]
   - LY：Last_Fiscal_Month EDATE(-12) 得 LY 月份，再 EDATE(-11) 起始月 → [起始月 TimeFrame_Min, Last_Fiscal_Month_Max_LY]
   - LP：Last_Fiscal_Month EDATE(-1) 得 LP 月份，再 EDATE(-11) 起始月 → [起始月 TimeFrame_Min, Last_Fiscal_Month_Max_LP]
   - 起始月字符串通过 Slicer_Time_Frame_VIC_Trend 查 TimeFrame_Label='月' AND TimeFrame_Value=起始月字符串 的 TimeFrame_Min 获取

5. **格式调整（不含正号）**：
   - 原 delta_pct_1dp（+14.5% / -3.2%）→ 新 percent_1dp（14.5% / -3.2%），使用 `FORMAT(__Value, "#,##0.0%")`
   - 原 delta_pts（+120pts / -80pts）→ 新 integer_pts（120pts / -80pts），使用 `FORMAT(__Value * 100, "#,##0pts;-#,##0pts;0pts")`
   - 去掉正号前缀 `IF(__Value>0,"+","")`，直接用 FORMAT 的正负数格式串实现

6. **is_member / is_employee 双重筛选**：与主表 VIC_KPIs_Table.md 口径一致，默认 is_member=0（TTL VIC）、is_employee=1（Yes）。

7. **Share 类分母**：Metric_ID=14（T4-5 Upgrade No. Share）的分母使用 X 轴 end period 当月 is_vic=1 的 DISTINCTCOUNT，等价于 [VIC No. Trend Act Value]。与 VIC Retention% 的 Rolling 12 分母不同。

8. **独立性**：本方案 10 个指标的 Value/Display 度量完全独立，不依赖 Dim_ColMetric_VIC_KPIs 断开维度、Metric_ID 路由体系，与 VIC_KPIs_Table.md 主表解耦。基础度量（Act/LY/LP）在内部复用，但对外暴露的 Value/Display 度量按指标独立命名。

9. **LP 全局筛选省略**：LP 度量（VIC No. Trend LP Value / T4-5 Upgrade No. Trend LP Value / VIC Retention% Trend LP Value）未应用全局 LP 范围筛选，仅用 X 轴 LP end period 区间（Last_Fiscal_Month_Min_LP/Max_LP）。因为 LP 是"上一期"概念，全局 LP 范围字段在日期表中可能不存在；若日期表有对应字段，可按需补充全局 LP 筛选。

10. **LY 全局筛选使用 TimeFrame_Min_LY / TimeFrame_Max_LY**：LY 度量应用全局 LY 范围筛选，字段来自 Slicer_Time_Frame_Min_VIC_Trend[TimeFrame_Min_LY] 和 Slicer_Time_Frame_Max_VIC_Trend[TimeFrame_Max_LY]。这假设日期表已预算这些字段（与 PB_Location_Trend.md 范式一致）。

11. **口径等价性**：本方案基础度量（Act/LY/LP）与 VIC_KPIs_Table.md 主表 Metric_ID=1/6/10/14 的 Act/LY/LP Base Value 口径等价，差异仅在于时间筛选上下文（主表用 Slicer_Time_Frame_Max 全局 end period，本方案用 Slicer_Time_Frame_VIC_Trend X 轴 end period + 全局冗余筛选）。

