# Power BI 解决方案 — Overview_Sales：Demand SLS & SLS Penetration（饼图 + 柱形图/趋势图）

> status: ready
> created: 2026-08-01
> type: 度量值开发 + 可视化构建
> 口径来源: 口径文档/Overview.md 子模块一 BOSS Core KPI（Demand SLS=RowKPI_ID 20，SLS Penetration=RowKPI_ID 30）
> 参考矩阵实现: Overview/BOSS Core KPI/Overview_KPIs_BossCoreKPI_matrix_solution.md
> 参考趋势实现: RL E2E Traffic_Dashboard（Controllable% Value/Display 范式）

---

## 1. 需求理解

为 Overview → Sales 分组下的两个 KPI 提供独立度量值（Value + Display），用于饼图、柱形图、趋势图：

| 序号 | 度量值              | 用途          | 对应矩阵口径                                  | 格式类型             |
| ---- | ------------------- | ------------- | --------------------------------------------- | -------------------- |
| 1    | Demand SLS          | 饼图          | Demand SLS — O2O退前销售额 Act（RowKPI_ID=20）| currency_M_K_Int_0db |
| 2    | TY Demand SLS       | 柱形图/趋势图 | Demand SLS — O2O退前销售额 Act（RowKPI_ID=20）| currency_M_K_Int_0db |
| 3    | LY Demand SLS       | 柱形图/趋势图 | Demand SLS — O2O退前销售额 LY（RowKPI_ID=20） | currency_M_K_Int_0db |
| 4    | TY SLS Penetration  | 柱形图/趋势图 | SLS Penetration — O2O销售渗透率 Act（RowKPI_ID=30）| percent_0dp          |
| 5    | LY SLS Penetration  | 柱形图/趋势图 | SLS Penetration — O2O销售渗透率 LY（RowKPI_ID=30） | percent_0dp          |

附加：`IsTimeFrameVisible` 辅助度量，用于柱形图/趋势图 X 轴的视觉对象级别筛选（同粒度 + 范围内才显示）。

**与矩阵方案的关键差异**：不使用 SWITCH 路由分发，每个指标独立编写 Value/Display 度量；饼图/柱形图/趋势图脱离 `Dim_RowKPIs_BossCoreKPI_Overview`/`Dim_ColKPIs_BossCoreKPI_Overview` 断开维度，直接基于事实表 + `Slicer_Time_Frame` 维度表。

---

## 2. 现状分析

### 2.1 数据底表

| 对象     | 名称                                                                                                                                                                                                                                                                                                  | 出处                                            |
| -------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------- |
| 事实表   | a02_e2e_boss_performance_summary_d                                                                                                                                                                                                                                                                    | 维度复用/a02_e2e_boss_performance_summary_d.sql |
| 关键字段 | data_date, store_name, calc_type, o2o_sales_amt（Demand SLS 分子/SLS Penetration 分子）, sales_amt（SLS Penetration 分母）                                                                                                                                                                             | 口径文档 Overview.md 子模块一 + 数据字典        |

### 2.2 维度表清单

| 维度表                 | 类型     | 连接方式                                                                                       | 出处                                  |
| ---------------------- | -------- | ---------------------------------------------------------------------------------------------- | ------------------------------------- |
| Slicer_Time_Frame      | 断开维度 | 柱形图/趋势图 X 轴；SELECTEDVALUE 读取 TimeFrame_ID/Key/Value/Min/Max                          | 维度复用/Slicer_Time_Frame.sql        |
| Slicer_Time_Frame_Min  | 断开维度 | 起始切片器；SELECTEDVALUE 读取 TimeFrame_Min/TimeFrame_Key/TimeFrame_ID                        | 维度复用/Slicer_Time_Frame_Min.sql    |
| Slicer_Time_Frame_Max  | 断开维度 | 结束切片器；SELECTEDVALUE 读取 TimeFrame_Max/TimeFrame_Key/TimeFrame_ID                        | 维度复用/Slicer_Time_Frame_Max.sql    |
| Slicer_Currency_Selection | 断开维度 | SELECTEDVALUE 读取 Currency_ExchangeRate, Currency_Symbol                                      | 维度复用/Slicer_Currency_Selection    |

### 2.3 Slicer_Time_Frame 表结构（5 种粒度 UNION）

| TimeFrame_ID | TimeFrame_Label | TimeFrame_Value 示例 | TimeFrame_Key 示例 | TimeFrame_Min | TimeFrame_Max |
| ------------ | --------------- | -------------------- | ------------------ | ------------- | ------------- |
| Day          | 天              | 2025-01-01           | 20250101           | 2025-01-01    | 2025-01-01    |
| Week         | 周              | 2026 Week14          | 202614             | 2025-06-29    | 2025-07-05    |
| Month        | 月              | 2026-10              | 202610             | 2025-12-28    | 2026-01-24    |
| Quarter      | 季              | 2026 Q3              | 202603             | 2025-09-28    | 2025-12-27    |
| Year         | 年              | 2026                 | 2026               | 2025-03-30    | 2026-03-28    |

> 关键：每行 `TimeFrame_Min/Max` 为该时间段的自然日范围，用于筛选事实表 `data_date`。

---

## 3. 方案设计

### 3.1 整体架构

```
饼图（Demand SLS）                         柱形图/趋势图（TY/LY Demand SLS, TY/LY SLS Penetration）
    │                                                          │
    │  图例 = 事实表[store_name]                                │  X 轴 = Slicer_Time_Frame[TimeFrame_Value]
    │  值   = [Demand SLS Value]                               │  Y 轴 = [TY/LY Demand SLS Value] / [TY/LY SLS Penetration Value]
    │  标签 = [Demand SLS Display]                             │  标签 = [* Display]
    │                                                          │  视觉对象级别筛选器: [IsTimeFrameVisible] = 1
    ▼                                                          ▼
    ┌─────────────────────────┐         ┌─────────────────────────────────────────────┐
    │ Demand SLS Value        │         │ TY/LY Demand SLS Value                       │
    │  CALCULATE(             │         │  CALCULATE(                                  │
    │    SUM(o2o_sales_amt),  │         │    SUM(o2o_sales_amt),                       │
    │    calc_type="payment", │         │    calc_type="payment",                      │
    │    data_date ∈ 全局范围 │         │    data_date ∈ 全局范围 ∩ X轴时间段          │
    │  ) / __FXRate           │         │  ) / __FXRate                                 │
    │                         │         │  LY 版本: 时间 EDATE -12 偏移                 │
    │ store_name 由图例传递   │         │                                              │
    └─────────────────────────┘         ├──────────────────────────────────────────────┤
                                        │ TY/LY SLS Penetration Value                  │
                                        │  DIVIDE(                                     │
                                        │    SUM(o2o_sales_amt),  // 分子              │
                                        │    SUM(sales_amt)       // 分母              │
                                        │  )                                           │
                                        │  同 calc_type="payment" + 双层时间筛选       │
                                        └──────────────────────────────────────────────┘
                                        TY/LY Display: currency_M_K_Int_0db / percent_0dp
```

### 3.2 筛选器上下文

| 筛选器                   | 饼图 (Demand SLS)        | 柱形图/趋势图 (TY/LY)                          |
| ------------------------ | ------------------------ | --------------------------------------------- |
| Slicer_Time_Frame_Min    | `data_date >= __TimeMin` | `data_date >= __TimeMin`（LY 版偏移 -12）     |
| Slicer_Time_Frame_Max    | `data_date <= __TimeMax` | `data_date <= __TimeMax`（LY 版偏移 -12）     |
| Slicer_Time_Frame (X 轴) | 不适用                   | `data_date ∈ [__CurrentTFMin, __CurrentTFMax]`（LY 版偏移 -12） |
| 事实表[store_name]       | 饼图图例自动传递筛选     | 不筛选（所有店铺汇总）                        |
| calc_type                | = "payment"              | = "payment"                                   |
| Slicer_Currency_Selection| 金额类 ÷ __FXRate        | 金额类 ÷ __FXRate；比率类不除（分子分母抵消）|

### 3.3 粒度处理机制（关键设计）

```
用户在 Slicer_Time_Frame_Min/Max 切片器选择起止时间
    │
    │  所选行的 TimeFrame_ID 决定当前粒度（Day/Week/Month/Quarter/Year）
    ▼
柱形图/趋势图 X 轴 = Slicer_Time_Frame[TimeFrame_Value]
    │
    │  X 轴表包含全部 5 种粒度的所有行（混合）
    │  需通过 [IsTimeFrameVisible] 视觉对象级别筛选器（=1）过滤：
    │    1. X 轴当前行 TimeFrame_ID == Min/Max 切片器 TimeFrame_ID（同粒度）
    │    2. X 轴当前行 TimeFrame_Key ∈ [MinKey, MaxKey]（范围内）
    ▼
仅同粒度 + 范围内的 timeframe 柱子显示
```

> **设计假设**：粒度从 `Slicer_Time_Frame_Min[TimeFrame_ID]` 读取（Min/Max 切片器应保持同粒度）。若 Min/Max 粒度不一致，`IsTimeFrameVisible` 返回 0 隐藏所有柱子，避免错乱。请在报表层确保 Min/Max 切片器受同一粒度选择器联动筛选。

### 3.4 时间偏移规则（LY — 财历映射）

**背景**：周/月/季/年粒度按财年定义（财年2026 ≠ 公历2026），如财年2026 = 2025-03-30 ~ 2026-03-28。EDATE -12 基于公历自然日偏移，会因闰年星期错位导致 LY 范围与"去年同编号财周/月/季/年"差1天。因此 LY 必须采用**财历映射**：通过 TimeFrame_Key 偏移查找去年同期同编号时间段的自然日范围。

**Key 偏移规则**（基于 Slicer_Time_Frame.sql 定义）：

| TimeFrame_ID | TimeFrame_Key 公式 | LY Key 计算 | 示例 |
|--------------|-------------------|-------------|------|
| Day | `date_key`（如 20250629） | 用 EDATE -12（自然日无财历概念） | 2025-06-29 → 2024-06-29 |
| Week | `financial_year * 100 + financial_week_num` | `Key - 100` | 202614 → 202514 |
| Month | `financial_year * 100 + financial_month_num` | `Key - 100` | 202610 → 202510 |
| Quarter | `financial_year * 100 + financial_quarter_num` | `Key - 100` | 202603 → 202503 |
| Year | `financial_year` | `Key - 1` | 2026 → 2025 |

**查找流程**：

```
1. 从当前上下文（X 轴或 Min/Max 切片器）读取 TimeFrame_ID + TimeFrame_Key
2. 按 Key 偏移规则计算 LY Key（Day 粒度走 EDATE -12 分支）
3. 在 Slicer_Time_Frame(_Min/_Max) 表中查找 [TimeFrame_ID] + [LY Key] 匹配的行
4. 读取该行的 TimeFrame_Min（LY 起始日）和 TimeFrame_Max（LY 结束日）
5. 用 LY 自然日范围筛选事实表 data_date
```

**示例**（X 轴 = 2026 Week14，TimeFrame_Min=2025-06-29, TimeFrame_Max=2025-07-05）：

```
TY 聚合: 2025-06-29 ~ 2025-07-05（财周 2026 Week14 的自然日范围）

LY 财历映射:
  当前 Key = 202614
  LY Key = 202614 - 100 = 202514
  在 Slicer_Time_Frame 表查找 TimeFrame_ID="Week" AND TimeFrame_Key=202514
  → 读取该行的 TimeFrame_Min/TimeFrame_Max（假设为 2024-06-30 ~ 2024-07-06）
LY 聚合: 2024-06-30 ~ 2024-07-06（财周 2025 Week14 的自然日范围）
```

**关键差异**：
- EDATE -12（错误）：2024-06-29 ~ 2024-07-05（公历偏移，可能跨财周）
- 财历映射（正确）：2024-06-30 ~ 2024-07-06（去年同编号财周的完整定义范围）

**数据要求**：Slicer_Time_Frame 表需包含至少2年历史数据（当前年 + 去年同期）。若数据历史不足1年，LY 查找返回 BLANK，柱子自然不显示，属可接受行为。

### 3.5 格式规范

| 格式类型             | 格式串                          | 示例      | 适用度量                              |
| -------------------- | ------------------------------- | --------- | ------------------------------------- |
| currency_M_K_Int_0db | 三段式（<1K / <1M / >=1M）      | ¥999 / ¥1.5K / ¥1.5M | Demand SLS, TY/LY Demand SLS Display  |
| percent_0dp          | `#,##0%;-#,##0%;0%`             | 15% / -3% | TY/LY SLS Penetration Display         |

---

## 4. 度量值实现

### 4.1 IsTimeFrameVisible（辅助度量 — X 轴视觉对象级别筛选器）

```dax
IsTimeFrameVisible = 
// ========================================
// 度量值: IsTimeFrameVisible
// Display Folder: Sales Trend
// 用途: 判断柱形图/趋势图 X 轴当前遍历的 timeframe（日/周/月/季/年）
//       是否落在起止切片器选定的范围内（同粒度 + Key 在 [MinKey, MaxKey] 区间）
// 返回: 1（显示）或 0（隐藏）
// 依赖: Slicer_Time_Frame[TimeFrame_ID, TimeFrame_Key],
//       Slicer_Time_Frame_Min[TimeFrame_ID, TimeFrame_Key, TimeFrame_Value],
//       Slicer_Time_Frame_Max[TimeFrame_ID, TimeFrame_Key, TimeFrame_Value]
// 使用方式: 作为柱形图/趋势图 X 轴（Slicer_Time_Frame）的视觉对象级别筛选器
//           筛选条件: IsTimeFrameVisible = 1
// 设计说明:
//   1. 粒度一致性校验：X 轴当前行粒度必须与 Min/Max 切片器选择的粒度一致
//      （Min/Max 切片器应受同一粒度选择器联动，保持同粒度）
//   2. Key 范围校验：同粒度下比较 TimeFrame_Key，确保 X 轴柱子在 [MinKey, MaxKey] 区间
//   3. 若 Min/Max 未选择，默认显示 X 轴主表全部同粒度行（取主表 Min/Max Key）
// ========================================
    // ── 步骤1：获取 X 轴当前行的粒度与 Key ──
    VAR __CurrentTimeFrameID = SELECTEDVALUE(Slicer_Time_Frame[TimeFrame_ID])
    VAR __CurrentKey = SELECTEDVALUE(Slicer_Time_Frame[TimeFrame_Key])
    // ── 步骤2：获取起止切片器选定的粒度 ──
    VAR __MinTimeFrameID = SELECTEDVALUE(Slicer_Time_Frame_Min[TimeFrame_ID])
    VAR __MaxTimeFrameID = SELECTEDVALUE(Slicer_Time_Frame_Max[TimeFrame_ID])
    // ── 步骤3：粒度一致性校验 ──
    // X 轴当前行粒度必须与起止切片器选择的粒度一致，才参与 Key 比较
    VAR __IsSameGranularity =
        NOT ISBLANK(__CurrentTimeFrameID)
        && __CurrentTimeFrameID = __MinTimeFrameID
        && __CurrentTimeFrameID = __MaxTimeFrameID
    // ── 步骤4：获取起止切片器选定的 Key（同粒度下比较）──
    // 若未选择，默认取 X 轴主表的最小/最大 Key，确保全部显示
    VAR __MinKey =
        IF(
            ISFILTERED(Slicer_Time_Frame_Min[TimeFrame_Value]),
            MIN(Slicer_Time_Frame_Min[TimeFrame_Key]),
            MIN(Slicer_Time_Frame[TimeFrame_Key])
        )
    VAR __MaxKey =
        IF(
            ISFILTERED(Slicer_Time_Frame_Max[TimeFrame_Value]),
            MAX(Slicer_Time_Frame_Max[TimeFrame_Key]),
            MAX(Slicer_Time_Frame[TimeFrame_Key])
        )
    // ── 步骤5：判断当前 Key 是否在 [MinKey, MaxKey] 区间内 ──
    RETURN
        IF(
            NOT __IsSameGranularity, 0,
            IF(
                __CurrentKey >= __MinKey && __CurrentKey <= __MaxKey,
                1,  // 在范围内：柱子显示
                0   // 不在范围内：柱子隐藏
            )
        )
```

### 4.2 Demand SLS Value（饼图 — 按 store_name 分组）

```dax
Demand SLS Value = 
// ========================================
// 度量值: Demand SLS Value
// Display Folder: Sales Trend
// 用途: Demand SLS（O2O退前销售额）值，用于饼图（按 store_name 分组展示占比）
// 口径来源: Overview.md 子模块一 BOSS Core KPI - Demand SLS Act（RowKPI_ID=20）
// 计算公式: SUM(o2o_sales_amt)
// 筛选条件:
//   - calc_type = "payment"
//   - data_date ∈ [__TimeMin, __TimeMax]（全局时间范围）
//   - store_name 由饼图图例（事实表[store_name]）自动传递筛选，无需显式处理
//   - 金额类指标 ÷ __FXRate（汇率换算）
// 数据类型: currency_M_K_Int_0db
// 饼图占比: Power BI 饼图自动以各 store_name 的 Value 占总和比例绘制
// ========================================
    VAR __TimeMin = SELECTEDVALUE(Slicer_Time_Frame_Min[TimeFrame_Min])
    VAR __TimeMax = SELECTEDVALUE(Slicer_Time_Frame_Max[TimeFrame_Max])
    VAR __FXRate = SELECTEDVALUE(Slicer_Currency_Selection[Currency_ExchangeRate], 1)
    VAR __DemandSLS =
        CALCULATE(
            SUM('a02_e2e_boss_performance_summary_d'[o2o_sales_amt]),
            'a02_e2e_boss_performance_summary_d'[calc_type] = "payment",
            'a02_e2e_boss_performance_summary_d'[data_date] >= __TimeMin,
            'a02_e2e_boss_performance_summary_d'[data_date] <= __TimeMax
        )
    RETURN DIVIDE(__DemandSLS, __FXRate)
```

### 4.3 Demand SLS Display（饼图标签）

```dax
Demand SLS Display = 
// ========================================
// 度量值: Demand SLS Display
// Display Folder: Sales Trend
// 用途: Demand SLS 格式化显示（K/M 单位切换）
// 依赖: [Demand SLS Value], Slicer_Currency_Selection
// 格式类型: currency_M_K_Int_0db
//   值 < 1,000        → 货币符号 + 千分位整数：¥999
//   1,000 ≤ 值 < 1M   → 货币符号 + K 单位（1位小数）：¥1.5K
//   值 ≥ 1,000,000    → 货币符号 + M 单位（1位小数）：¥1.5M
// ========================================
    VAR __Value = [Demand SLS Value]
    VAR __CurrencySymbol = SELECTEDVALUE(Slicer_Currency_Selection[Currency_Symbol], "¥")
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            IF(
                __Value < 1000,
                __CurrencySymbol & FORMAT(__Value, "#,##0"),
                IF(
                    __Value < 1000000,
                    __CurrencySymbol & FORMAT(__Value / 1000, "#,##0.0") & "K",
                    __CurrencySymbol & FORMAT(__Value / 1000000, "#,##0.0") & "M"
                )
            )
        )
```

### 4.4 TY Demand SLS Value（柱形图/趋势图 — 本期）

```dax
TY Demand SLS Value = 
// ========================================
// 度量值: TY Demand SLS Value
// Display Folder: Sales Trend
// 用途: TY Demand SLS（O2O退前销售额 Act 值），用于柱形图/趋势图 Y 轴
// 口径来源: Overview.md 子模块一 BOSS Core KPI - Demand SLS Act（RowKPI_ID=20）
// 计算公式: SUM(o2o_sales_amt)
// 筛选条件:
//   - calc_type = "payment"
//   - 全局时间范围: data_date ∈ [__TimeMin, __TimeMax]
//   - X 轴上下文: data_date ∈ [__CurrentTFMin, __CurrentTFMax]（按所选 timeframe 日/周/月/季/年分组）
//   - 所有店铺汇总（不按 store_name 分组）
//   - 金额类指标 ÷ __FXRate（汇率换算）
// 数据类型: currency_M_K_Int_0db
// X 轴: Slicer_Time_Frame[TimeFrame_Value]，需配置 [IsTimeFrameVisible] = 1 视觉对象级别筛选器
// ========================================
    // 1. 获取起止切片器选择的全局范围
    VAR __TimeMin = SELECTEDVALUE(Slicer_Time_Frame_Min[TimeFrame_Min])
    VAR __TimeMax = SELECTEDVALUE(Slicer_Time_Frame_Max[TimeFrame_Max])
    // 2. 获取柱形图 X 轴当前遍历的 timeframe 的自然日范围
    VAR __CurrentTFMin = SELECTEDVALUE(Slicer_Time_Frame[TimeFrame_Min])
    VAR __CurrentTFMax = SELECTEDVALUE(Slicer_Time_Frame[TimeFrame_Max])
    // 3. 汇率（金额类指标需除以汇率）
    VAR __FXRate = SELECTEDVALUE(Slicer_Currency_Selection[Currency_ExchangeRate], 1)
    // 4. 聚合：全局范围 ∩ X 轴时间段
    VAR __DemandSLS =
        CALCULATE(
            SUM('a02_e2e_boss_performance_summary_d'[o2o_sales_amt]),
            'a02_e2e_boss_performance_summary_d'[calc_type] = "payment",
            // 全局切片器筛选：限制事实表数据在选定的起止时间范围内
            'a02_e2e_boss_performance_summary_d'[data_date] >= __TimeMin,
            'a02_e2e_boss_performance_summary_d'[data_date] <= __TimeMax,
            // X 轴上下文筛选：限制事实表数据仅属于当前 X 轴遍历的那个时间段
            'a02_e2e_boss_performance_summary_d'[data_date] >= __CurrentTFMin,
            'a02_e2e_boss_performance_summary_d'[data_date] <= __CurrentTFMax
        )
    RETURN DIVIDE(__DemandSLS, __FXRate)
```

### 4.5 TY Demand SLS Display

```dax
TY Demand SLS Display = 
// ========================================
// 度量值: TY Demand SLS Display
// Display Folder: Sales Trend
// 用途: TY Demand SLS 格式化显示（K/M 单位切换）
// 依赖: [TY Demand SLS Value], Slicer_Currency_Selection
// 格式类型: currency_M_K_Int_0db
// ========================================
    VAR __Value = [TY Demand SLS Value]
    VAR __CurrencySymbol = SELECTEDVALUE(Slicer_Currency_Selection[Currency_Symbol], "¥")
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            IF(
                __Value < 1000,
                __CurrencySymbol & FORMAT(__Value, "#,##0"),
                IF(
                    __Value < 1000000,
                    __CurrencySymbol & FORMAT(__Value / 1000, "#,##0.0") & "K",
                    __CurrencySymbol & FORMAT(__Value / 1000000, "#,##0.0") & "M"
                )
            )
        )
```

### 4.6 LY Demand SLS Value（柱形图/趋势图 — 去年同期，财历映射）

```dax
LY Demand SLS Value = 
// ========================================
// 度量值: LY Demand SLS Value
// Display Folder: Sales Trend
// 用途: LY Demand SLS（O2O退前销售额 去年同期值），用于柱形图/趋势图 Y 轴
// 口径来源: Overview.md 子模块一 BOSS Core KPI - Demand SLS LY（RowKPI_ID=20）
// 计算公式: SUM(o2o_sales_amt)（去年同期）
// 时间偏移: 财历映射（Day 粒度用 EDATE -12，Week/Month/Quarter/Year 用 Key 偏移查找）
//   全局范围:   从 Slicer_Time_Frame_Min/Max 查 LY 同编号时间段的 TimeFrame_Min/Max
//   X 轴时间段: 从 Slicer_Time_Frame 查 LY 同编号时间段的 TimeFrame_Min/Max
// 筛选条件: 同 TY Demand SLS Value，时间偏移到去年同编号财周/月/季/年
//   - 所有店铺汇总
//   - 金额类指标 ÷ __FXRate（汇率换算，与 Act 保持一致）
// 数据类型: currency_M_K_Int_0db
// 说明: X 轴仍显示当前 timeframe（如 2026 Week14），柱子聚合的是去年同编号财周（2025 Week14）的数据
// 前提: Slicer_Time_Frame(_Min/_Max) 表需包含去年同期数据，否则返回 BLANK
// ========================================
    // ── 1. 读取全局粒度（Min/Max 同粒度，从 Min 切片器读取）──
    VAR __GlobalTFID = SELECTEDVALUE(Slicer_Time_Frame_Min[TimeFrame_ID])
    // ── 2. 全局 LY 起始日（从 Min 切片器查找）──
    VAR __GlobalMinKey = SELECTEDVALUE(Slicer_Time_Frame_Min[TimeFrame_Key])
    VAR __GlobalMinValue = SELECTEDVALUE(Slicer_Time_Frame_Min[TimeFrame_Min])
    VAR __LY_GlobalMinKey =
        SWITCH(
            __GlobalTFID,
            "Year",   __GlobalMinKey - 1,
            "Week",   __GlobalMinKey - 100,
            "Month",  __GlobalMinKey - 100,
            "Quarter", __GlobalMinKey - 100,
            BLANK()  // Day 走 EDATE 分支
        )
    VAR __LYTimeMin =
        IF(
            __GlobalTFID = "Day",
            EDATE(__GlobalMinValue, -12),
            CALCULATE(
                MIN(Slicer_Time_Frame_Min[TimeFrame_Min]),  // 读 TimeFrame_Min 字段（起始日）
                ALL(Slicer_Time_Frame_Min),
                Slicer_Time_Frame_Min[TimeFrame_ID] = __GlobalTFID,
                Slicer_Time_Frame_Min[TimeFrame_Key] = __LY_GlobalMinKey
            )
        )
    // ── 3. 全局 LY 结束日（从 Max 切片器查找，独立算 LY Key）──
    VAR __GlobalMaxKey = SELECTEDVALUE(Slicer_Time_Frame_Max[TimeFrame_Key])
    VAR __GlobalMaxValue = SELECTEDVALUE(Slicer_Time_Frame_Max[TimeFrame_Max])
    VAR __LY_GlobalMaxKey =
        SWITCH(
            __GlobalTFID,  // Min/Max 同粒度
            "Year",   __GlobalMaxKey - 1,
            "Week",   __GlobalMaxKey - 100,
            "Month",  __GlobalMaxKey - 100,
            "Quarter", __GlobalMaxKey - 100,
            BLANK()
        )
    VAR __LYTimeMax =
        IF(
            __GlobalTFID = "Day",
            EDATE(__GlobalMaxValue, -12),
            CALCULATE(
                MAX(Slicer_Time_Frame_Max[TimeFrame_Max]),  // 读 TimeFrame_Max 字段（结束日）
                ALL(Slicer_Time_Frame_Max),
                Slicer_Time_Frame_Max[TimeFrame_ID] = __GlobalTFID,
                Slicer_Time_Frame_Max[TimeFrame_Key] = __LY_GlobalMaxKey
            )
        )
    // ── 4. X 轴 LY 范围（从 Slicer_Time_Frame 查找）──
    VAR __CurrentTFID = SELECTEDVALUE(Slicer_Time_Frame[TimeFrame_ID])
    VAR __CurrentTFKey = SELECTEDVALUE(Slicer_Time_Frame[TimeFrame_Key])
    VAR __CurrentTFMinValue = SELECTEDVALUE(Slicer_Time_Frame[TimeFrame_Min])
    VAR __CurrentTFMaxValue = SELECTEDVALUE(Slicer_Time_Frame[TimeFrame_Max])
    VAR __LY_TFKey =
        SWITCH(
            __CurrentTFID,
            "Year",   __CurrentTFKey - 1,
            "Week",   __CurrentTFKey - 100,
            "Month",  __CurrentTFKey - 100,
            "Quarter", __CurrentTFKey - 100,
            BLANK()  // Day 走 EDATE 分支
        )
    VAR __LYCurrentTFMin =
        IF(
            __CurrentTFID = "Day",
            EDATE(__CurrentTFMinValue, -12),
            CALCULATE(
                MIN(Slicer_Time_Frame[TimeFrame_Min]),
                ALL(Slicer_Time_Frame),
                Slicer_Time_Frame[TimeFrame_ID] = __CurrentTFID,
                Slicer_Time_Frame[TimeFrame_Key] = __LY_TFKey
            )
        )
    VAR __LYCurrentTFMax =
        IF(
            __CurrentTFID = "Day",
            EDATE(__CurrentTFMaxValue, -12),
            CALCULATE(
                MAX(Slicer_Time_Frame[TimeFrame_Max]),
                ALL(Slicer_Time_Frame),
                Slicer_Time_Frame[TimeFrame_ID] = __CurrentTFID,
                Slicer_Time_Frame[TimeFrame_Key] = __LY_TFKey
            )
        )
    // ── 5. 汇率 ──
    VAR __FXRate = SELECTEDVALUE(Slicer_Currency_Selection[Currency_ExchangeRate], 1)
    // ── 6. 聚合：LY 全局范围 ∩ LY X 轴时间段 ──
    VAR __DemandSLS_LY =
        CALCULATE(
            SUM('a02_e2e_boss_performance_summary_d'[o2o_sales_amt]),
            'a02_e2e_boss_performance_summary_d'[calc_type] = "payment",
            'a02_e2e_boss_performance_summary_d'[data_date] >= __LYTimeMin,
            'a02_e2e_boss_performance_summary_d'[data_date] <= __LYTimeMax,
            'a02_e2e_boss_performance_summary_d'[data_date] >= __LYCurrentTFMin,
            'a02_e2e_boss_performance_summary_d'[data_date] <= __LYCurrentTFMax
        )
    RETURN DIVIDE(__DemandSLS_LY, __FXRate)
```

### 4.7 LY Demand SLS Display

```dax
LY Demand SLS Display = 
// ========================================
// 度量值: LY Demand SLS Display
// Display Folder: Sales Trend
// 用途: LY Demand SLS 格式化显示（K/M 单位切换）
// 依赖: [LY Demand SLS Value], Slicer_Currency_Selection
// 格式类型: currency_M_K_Int_0db
// ========================================
    VAR __Value = [LY Demand SLS Value]
    VAR __CurrencySymbol = SELECTEDVALUE(Slicer_Currency_Selection[Currency_Symbol], "¥")
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            IF(
                __Value < 1000,
                __CurrencySymbol & FORMAT(__Value, "#,##0"),
                IF(
                    __Value < 1000000,
                    __CurrencySymbol & FORMAT(__Value / 1000, "#,##0.0") & "K",
                    __CurrencySymbol & FORMAT(__Value / 1000000, "#,##0.0") & "M"
                )
            )
        )
```

### 4.8 TY SLS Penetration Value（柱形图/趋势图 — 本期）

```dax
TY SLS Penetration Value = 
// ========================================
// 度量值: TY SLS Penetration Value
// Display Folder: Sales Trend
// 用途: TY SLS Penetration（O2O销售渗透率 Act 值），用于柱形图/趋势图 Y 轴
// 口径来源: Overview.md 子模块一 BOSS Core KPI - SLS Penetration Act（RowKPI_ID=30）
// 计算公式: SUM(o2o_sales_amt) / SUM(sales_amt)
//   分子: o2o_sales_amt（O2O退前销售额）
//   分母: sales_amt（总销售额）
// 筛选条件:
//   - calc_type = "payment"
//   - 全局时间范围 + X 轴上下文（与 TY Demand SLS Value 一致的双层时间筛选）
//   - 所有店铺汇总（不按 store_name 分组）
//   - 比率类，不除汇率（分子分母同币种，相除自动抵消）
// 数据类型: percent_0dp → 百分比整数，不含正号
// X 轴: Slicer_Time_Frame[TimeFrame_Value]，需配置 [IsTimeFrameVisible] = 1 视觉对象级别筛选器
// ========================================
    // 1. 获取起止切片器选择的全局范围
    VAR __TimeMin = SELECTEDVALUE(Slicer_Time_Frame_Min[TimeFrame_Min])
    VAR __TimeMax = SELECTEDVALUE(Slicer_Time_Frame_Max[TimeFrame_Max])
    // 2. 获取柱形图 X 轴当前遍历的 timeframe 的自然日范围
    VAR __CurrentTFMin = SELECTEDVALUE(Slicer_Time_Frame[TimeFrame_Min])
    VAR __CurrentTFMax = SELECTEDVALUE(Slicer_Time_Frame[TimeFrame_Max])
    // ── 分子：o2o_sales_amt ──
    VAR __Numerator =
        CALCULATE(
            SUM('a02_e2e_boss_performance_summary_d'[o2o_sales_amt]),
            'a02_e2e_boss_performance_summary_d'[calc_type] = "payment",
            'a02_e2e_boss_performance_summary_d'[data_date] >= __TimeMin,
            'a02_e2e_boss_performance_summary_d'[data_date] <= __TimeMax,
            'a02_e2e_boss_performance_summary_d'[data_date] >= __CurrentTFMin,
            'a02_e2e_boss_performance_summary_d'[data_date] <= __CurrentTFMax
        )
    // ── 分母：sales_amt ──
    VAR __Denominator =
        CALCULATE(
            SUM('a02_e2e_boss_performance_summary_d'[sales_amt]),
            'a02_e2e_boss_performance_summary_d'[calc_type] = "payment",
            'a02_e2e_boss_performance_summary_d'[data_date] >= __TimeMin,
            'a02_e2e_boss_performance_summary_d'[data_date] <= __TimeMax,
            'a02_e2e_boss_performance_summary_d'[data_date] >= __CurrentTFMin,
            'a02_e2e_boss_performance_summary_d'[data_date] <= __CurrentTFMax
        )
    RETURN DIVIDE(__Numerator, __Denominator)
```

### 4.9 TY SLS Penetration Display

```dax
TY SLS Penetration Display = 
// ========================================
// 度量值: TY SLS Penetration Display
// Display Folder: Sales Trend
// 用途: TY SLS Penetration 格式化显示（百分比整数，不含正号）
// 依赖: [TY SLS Penetration Value]
// 格式类型: percent_0dp → 百分比整数，不含正号
// 格式串: #,##0%;-#,##0%;0%
// ========================================
    VAR __Value = [TY SLS Penetration Value]
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            FORMAT(__Value, "#,##0%;-#,##0%;0%")
        )
```

### 4.10 LY SLS Penetration Value（柱形图/趋势图 — 去年同期，财历映射）

```dax
LY SLS Penetration Value = 
// ========================================
// 度量值: LY SLS Penetration Value
// Display Folder: Sales Trend
// 用途: LY SLS Penetration（O2O销售渗透率 去年同期值），用于柱形图/趋势图 Y 轴
// 口径来源: Overview.md 子模块一 BOSS Core KPI - SLS Penetration LY（RowKPI_ID=30）
// 计算公式: SUM(o2o_sales_amt) / SUM(sales_amt)（去年同期）
// 时间偏移: 财历映射（Day 粒度用 EDATE -12，Week/Month/Quarter/Year 用 Key 偏移查找）
//   与 LY Demand SLS Value 一致，详细注释参见该度量
// 筛选条件: 同 TY SLS Penetration Value，时间偏移到去年同编号财周/月/季/年
//   - 所有店铺汇总
//   - 比率类，不除汇率（分子分母同币种，相除自动抵消）
// 数据类型: percent_0dp → 百分比整数，不含正号
// 前提: Slicer_Time_Frame(_Min/_Max) 表需包含去年同期数据，否则返回 BLANK
// ========================================
    // ── 1. 读取全局粒度（Min/Max 同粒度，从 Min 切片器读取）──
    VAR __GlobalTFID = SELECTEDVALUE(Slicer_Time_Frame_Min[TimeFrame_ID])
    // ── 2. 全局 LY 起始日（从 Min 切片器查找）──
    VAR __GlobalMinKey = SELECTEDVALUE(Slicer_Time_Frame_Min[TimeFrame_Key])
    VAR __GlobalMinValue = SELECTEDVALUE(Slicer_Time_Frame_Min[TimeFrame_Min])
    VAR __LY_GlobalMinKey =
        SWITCH(
            __GlobalTFID,
            "Year",   __GlobalMinKey - 1,
            "Week",   __GlobalMinKey - 100,
            "Month",  __GlobalMinKey - 100,
            "Quarter", __GlobalMinKey - 100,
            BLANK()  // Day 走 EDATE 分支
        )
    VAR __LYTimeMin =
        IF(
            __GlobalTFID = "Day",
            EDATE(__GlobalMinValue, -12),
            CALCULATE(
                MIN(Slicer_Time_Frame_Min[TimeFrame_Min]),
                ALL(Slicer_Time_Frame_Min),
                Slicer_Time_Frame_Min[TimeFrame_ID] = __GlobalTFID,
                Slicer_Time_Frame_Min[TimeFrame_Key] = __LY_GlobalMinKey
            )
        )
    // ── 3. 全局 LY 结束日（从 Max 切片器查找，独立算 LY Key）──
    VAR __GlobalMaxKey = SELECTEDVALUE(Slicer_Time_Frame_Max[TimeFrame_Key])
    VAR __GlobalMaxValue = SELECTEDVALUE(Slicer_Time_Frame_Max[TimeFrame_Max])
    VAR __LY_GlobalMaxKey =
        SWITCH(
            __GlobalTFID,
            "Year",   __GlobalMaxKey - 1,
            "Week",   __GlobalMaxKey - 100,
            "Month",  __GlobalMaxKey - 100,
            "Quarter", __GlobalMaxKey - 100,
            BLANK()
        )
    VAR __LYTimeMax =
        IF(
            __GlobalTFID = "Day",
            EDATE(__GlobalMaxValue, -12),
            CALCULATE(
                MAX(Slicer_Time_Frame_Max[TimeFrame_Max]),
                ALL(Slicer_Time_Frame_Max),
                Slicer_Time_Frame_Max[TimeFrame_ID] = __GlobalTFID,
                Slicer_Time_Frame_Max[TimeFrame_Key] = __LY_GlobalMaxKey
            )
        )
    // ── 4. X 轴 LY 范围（从 Slicer_Time_Frame 查找）──
    VAR __CurrentTFID = SELECTEDVALUE(Slicer_Time_Frame[TimeFrame_ID])
    VAR __CurrentTFKey = SELECTEDVALUE(Slicer_Time_Frame[TimeFrame_Key])
    VAR __CurrentTFMinValue = SELECTEDVALUE(Slicer_Time_Frame[TimeFrame_Min])
    VAR __CurrentTFMaxValue = SELECTEDVALUE(Slicer_Time_Frame[TimeFrame_Max])
    VAR __LY_TFKey =
        SWITCH(
            __CurrentTFID,
            "Year",   __CurrentTFKey - 1,
            "Week",   __CurrentTFKey - 100,
            "Month",  __CurrentTFKey - 100,
            "Quarter", __CurrentTFKey - 100,
            BLANK()
        )
    VAR __LYCurrentTFMin =
        IF(
            __CurrentTFID = "Day",
            EDATE(__CurrentTFMinValue, -12),
            CALCULATE(
                MIN(Slicer_Time_Frame[TimeFrame_Min]),
                ALL(Slicer_Time_Frame),
                Slicer_Time_Frame[TimeFrame_ID] = __CurrentTFID,
                Slicer_Time_Frame[TimeFrame_Key] = __LY_TFKey
            )
        )
    VAR __LYCurrentTFMax =
        IF(
            __CurrentTFID = "Day",
            EDATE(__CurrentTFMaxValue, -12),
            CALCULATE(
                MAX(Slicer_Time_Frame[TimeFrame_Max]),
                ALL(Slicer_Time_Frame),
                Slicer_Time_Frame[TimeFrame_ID] = __CurrentTFID,
                Slicer_Time_Frame[TimeFrame_Key] = __LY_TFKey
            )
        )
    // ── 5. 分子：o2o_sales_amt（去年同期）──
    VAR __Numerator =
        CALCULATE(
            SUM('a02_e2e_boss_performance_summary_d'[o2o_sales_amt]),
            'a02_e2e_boss_performance_summary_d'[calc_type] = "payment",
            'a02_e2e_boss_performance_summary_d'[data_date] >= __LYTimeMin,
            'a02_e2e_boss_performance_summary_d'[data_date] <= __LYTimeMax,
            'a02_e2e_boss_performance_summary_d'[data_date] >= __LYCurrentTFMin,
            'a02_e2e_boss_performance_summary_d'[data_date] <= __LYCurrentTFMax
        )
    // ── 6. 分母：sales_amt（去年同期）──
    VAR __Denominator =
        CALCULATE(
            SUM('a02_e2e_boss_performance_summary_d'[sales_amt]),
            'a02_e2e_boss_performance_summary_d'[calc_type] = "payment",
            'a02_e2e_boss_performance_summary_d'[data_date] >= __LYTimeMin,
            'a02_e2e_boss_performance_summary_d'[data_date] <= __LYTimeMax,
            'a02_e2e_boss_performance_summary_d'[data_date] >= __LYCurrentTFMin,
            'a02_e2e_boss_performance_summary_d'[data_date] <= __LYCurrentTFMax
        )
    RETURN DIVIDE(__Numerator, __Denominator)
```

### 4.11 LY SLS Penetration Display

```dax
LY SLS Penetration Display = 
// ========================================
// 度量值: LY SLS Penetration Display
// Display Folder: Sales Trend
// 用途: LY SLS Penetration 格式化显示（百分比整数，不含正号）
// 依赖: [LY SLS Penetration Value]
// 格式类型: percent_0dp → 百分比整数，不含正号
// 格式串: #,##0%;-#,##0%;0%
// ========================================
    VAR __Value = [LY SLS Penetration Value]
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            FORMAT(__Value, "#,##0%;-#,##0%;0%")
        )
```

---

## 5. 度量值清单与 Display Folder

| 序号 | 度量值名称                  | Display Folder | 用途                                              |
| ---- | --------------------------- | -------------- | ------------------------------------------------- |
| 1    | IsTimeFrameVisible          | Sales Trend    | X 轴视觉对象级别筛选器（同粒度 + 范围内 = 1）     |
| 2    | Demand SLS Value            | Sales Trend    | 饼图值（按 store_name 分组占比）                  |
| 3    | Demand SLS Display          | Sales Trend    | 饼图标签（currency_M_K_Int_0db）                  |
| 4    | TY Demand SLS Value         | Sales Trend    | 柱形图/趋势图 Y 轴（本期）                        |
| 5    | TY Demand SLS Display       | Sales Trend    | 柱形图/趋势图标签（currency_M_K_Int_0db）         |
| 6    | LY Demand SLS Value         | Sales Trend    | 柱形图/趋势图 Y 轴（去年同期）                    |
| 7    | LY Demand SLS Display       | Sales Trend    | 柱形图/趋势图标签（currency_M_K_Int_0db）         |
| 8    | TY SLS Penetration Value    | Sales Trend    | 柱形图/趋势图 Y 轴（本期）                        |
| 9    | TY SLS Penetration Display  | Sales Trend    | 柱形图/趋势图标签（percent_0dp）                  |
| 10   | LY SLS Penetration Value    | Sales Trend    | 柱形图/趋势图 Y 轴（去年同期）                    |
| 11   | LY SLS Penetration Display  | Sales Trend    | 柱形图/趋势图标签（percent_0dp）                  |

---

## 6. 视觉对象配置

### 6.1 饼图（Demand SLS — 按 store_name 占比）

| 配置项   | 值                              |
| -------- | ------------------------------- |
| 图例     | `a02_e2e_boss_performance_summary_d[store_name]` |
| 值       | `[Demand SLS Value]`            |
| 详细信息 | `[Demand SLS Display]`（或工具提示） |
| 筛选器   | Slicer_Time_Frame_Min/Max（全局时间范围）、Slicer_Currency_Selection |

> 饼图自动以各 store_name 的 Value 占总和比例绘制扇区；Display 度量用于数据标签或工具提示展示格式化文本。

### 6.2 柱形图/趋势图（TY/LY Demand SLS, TY/LY SLS Penetration）

| 配置项               | 值                                                       |
| -------------------- | -------------------------------------------------------- |
| X 轴                 | `Slicer_Time_Frame[TimeFrame_Value]`                     |
| Y 轴                 | `[TY Demand SLS Value]` / `[LY Demand SLS Value]` / `[TY SLS Penetration Value]` / `[LY SLS Penetration Value]` |
| 数据标签             | 对应 `[* Display]` 度量                                   |
| 视觉对象级别筛选器   | `Slicer_Time_Frame` 表上添加 `[IsTimeFrameVisible] = 1`  |
| 全局筛选器           | Slicer_Time_Frame_Min/Max、Slicer_Currency_Selection     |

> **关键操作**：在柱形图/趋势图的"筛选器"窗格中，找到 `Slicer_Time_Frame` 表，将 `[IsTimeFrameVisible]` 拖入"此视觉对象上的筛选器"，设置条件为 `为 1`（is 1）。这样 X 轴只显示与起止切片器同粒度且在 [MinKey, MaxKey] 范围内的柱子。

---

## 7. 验证方法

### 7.1 粒度切换验证

| 验证项 | 方法 |
| ------ | ---- |
| 同粒度显示 | 在 Slicer_Time_Frame_Min 选"2026 Week14"、Max 选"2026 Week19"，确认柱形图 X 轴只显示 Week 粒度且 Key 在 [202614, 202619] 范围内的周 |
| 跨粒度隐藏 | 切换 Min 为 Month 粒度（如 2026-10），确认 X 轴切换为月粒度柱子，Day/Week/Quarter/Year 柱子全部隐藏 |
| 未选择兜底 | 清空 Min/Max 切片器，确认 X 轴显示全部同粒度柱子（取主表 Min/Max Key） |

### 7.2 数据验证 SQL（以 TY Demand SLS，所有店铺某周为例）

```sql
-- TY Demand SLS（某周，所有店铺汇总）
-- 假设 X 轴 = 2026 Week14，TimeFrame_Min=2025-06-29, TimeFrame_Max=2025-07-05
SELECT SUM(o2o_sales_amt) AS DemandSLS_TY
FROM a02_e2e_boss_performance_summary_d
WHERE calc_type = 'payment'
  AND data_date BETWEEN '2025-06-29' AND '2025-07-05';

-- LY Demand SLS（去年同编号财周，所有店铺汇总）
-- 步骤1: 计算 LY Key = 202614 - 100 = 202514
-- 步骤2: 查 Slicer_Time_Frame 表 TimeFrame_ID='Week' AND TimeFrame_Key=202514
--        得到 LY 的 TimeFrame_Min/Max（假设为 2024-06-30 ~ 2024-07-06）
-- 步骤3: 用 LY 自然日范围筛选事实表
SELECT SUM(o2o_sales_amt) AS DemandSLS_LY
FROM a02_e2e_boss_performance_summary_d
WHERE calc_type = 'payment'
  AND data_date BETWEEN '2024-06-30' AND '2024-07-06';
  -- 注意: 不是 DATE_SUB('2025-06-29', INTERVAL 12 MONTH) = '2024-06-29'
  -- 财历映射取去年同编号财周的完整定义范围，可能与 EDATE -12 差1天

-- TY SLS Penetration（某周，所有店铺汇总）
SELECT
  SUM(o2o_sales_amt) / SUM(sales_amt) AS SLS_Penetration_TY
FROM a02_e2e_boss_performance_summary_d
WHERE calc_type = 'payment'
  AND data_date BETWEEN '2025-06-29' AND '2025-07-05';

-- LY SLS Penetration（去年同编号财周，所有店铺汇总）
SELECT
  SUM(o2o_sales_amt) / SUM(sales_amt) AS SLS_Penetration_LY
FROM a02_e2e_boss_performance_summary_d
WHERE calc_type = 'payment'
  AND data_date BETWEEN '2024-06-30' AND '2024-07-06';
```

**LY Key 偏移规则速查**：

| TimeFrame_ID | LY Key 计算 | 示例 |
|--------------|-------------|------|
| Day | EDATE -12（不走 Key 偏移） | 2025-06-29 → 2024-06-29 |
| Week | Key - 100 | 202614 → 202514 |
| Month | Key - 100 | 202610 → 202510 |
| Quarter | Key - 100 | 202603 → 202503 |
| Year | Key - 1 | 2026 → 2025 |

### 7.3 饼图占比验证

```sql
-- Demand SLS 各店铺占比（饼图）
SELECT
  store_name,
  SUM(o2o_sales_amt) AS DemandSLS,
  SUM(o2o_sales_amt) / SUM(SUM(o2o_sales_amt)) OVER() AS Share
FROM a02_e2e_boss_performance_summary_d
WHERE calc_type = 'payment'
  AND data_date BETWEEN '__TimeMin' AND '__TimeMax'
GROUP BY store_name;
```

---

## 8. 注意事项

1. **粒度联动假设**：本方案假设 `Slicer_Time_Frame_Min` 和 `Slicer_Time_Frame_Max` 切片器受同一粒度选择器联动筛选（保持同粒度）。若两者粒度不一致，`IsTimeFrameVisible` 返回 0 隐藏所有柱子。请在报表层配置粒度联动。

2. **LY 财历映射（重要）**：周/月/季/年粒度按财年定义（财年2026 ≠ 公历2026），LY 不能用 EDATE -12（公历自然日偏移会因闰年星期错位差1天）。本方案采用财历映射：通过 TimeFrame_Key 偏移（Week/Month/Quarter: Key-100，Year: Key-1）在 Slicer_Time_Frame(_Min/_Max) 表中查找去年同编号时间段的自然日范围。Day 粒度无财历概念，仍用 EDATE -12。
   - **数据要求**：Slicer_Time_Frame 表需包含至少2年历史数据（当前年 + 去年同期）。若数据历史不足1年，LY 查找返回 BLANK，柱子不显示，属可接受行为。
   - **与原矩阵方案差异**：原矩阵 `BOSS Core KPI LY Base Value` 使用 EDATE -12，存在周/季/年粒度下 LY 范围与去年同编号财周/月/季/年差1天的潜在问题。本方案修正了此问题，如需统一口径，建议同步更新矩阵方案。

3. **饼图 store_name 传递**：饼图图例直接使用事实表 `store_name` 字段，度量值无需显式筛选。若事实表存在 store_name 为空的行，会在饼图中显示为空标签，建议在数据预处理或视觉对象筛选器中过滤。

4. **汇率换算**：金额类指标（Demand SLS）÷ `Currency_ExchangeRate`；比率类指标（SLS Penetration）分子分母同币种相除自动抵消，不除汇率。与原矩阵方案一致。

5. **全局筛选冗余性**：柱形图/趋势图中，X 轴时间段筛选是全局范围筛选的子集（由 `IsTimeFrameVisible` 保证），全局筛选冗余但保留，用于防止 X 轴超出全局范围时的异常显示，与参考 dax（Controllable% Value）保持一致。

6. **与矩阵方案的关系**：本方案度量值独立于矩阵的 `BOSS Core KPI Act/LY Base Value`，不复用矩阵的 SWITCH 路由。两套度量值可并存，分别服务饼图/柱形图/趋势图与矩阵视觉对象。

7. **LY Key 偏移的边界情况**：
   - Week Key = `financial_year * 100 + financial_week_num`，财年范围 1~53，Key-100 假设去年同周编号存在。若去年是短财年（如只有52周），而今年有 Week53，LY 查找会返回 BLANK。
   - Month/Quarter Key 同理，假设去年同编号月/季存在（财历定义稳定，通常成立）。
   - Year Key = `financial_year`，Key-1 即上一年，无边界问题。
