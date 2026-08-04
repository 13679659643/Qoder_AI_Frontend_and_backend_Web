# TimeFrame LY / LP 时间偏移规则总结

> **用途**：本文档总结 RL E2E BOSS Dashboard 项目中"去年同期（LY）"和"上期（LP）"的时间偏移规则，覆盖"仅全局日期筛选（无 X 轴）"和"全局 + X 轴"两种场景，供各方案文档（卡片图/柱形图/趋势图/矩阵）借鉴复用。
>
> **适用维度表**：`Slicer_Time_Frame`、`Slicer_Time_Frame_Min`、`Slicer_Time_Frame_Max`（三者结构一致，均来自 [Slicer_Time_Frame.sql](<file:///d:/Users/QiYe/BaoZun/Project/Qoder_AI_Frontend_and_backend_Web/RL%20E2E/RL%20E2E%20BOSS%20Dashboard/维度复用/Slicer_Time_Frame.sql>)）

---

## 1. 背景与核心问题

### 1.1 财年 ≠ 公历

| 粒度 (TimeFrame_ID) | Key 公式                                         | 示例数据                                                  |
| ------------------- | ------------------------------------------------ | --------------------------------------------------------- |
| Day                 | `date_key`                                     | 2025-01-01 → Key=20250101, Min=Max=2025-01-01            |
| Week                | `financial_year * 100 + financial_week_num`    | 2026 Week14 → Key=202614, Min=2025-06-29, Max=2025-07-05 |
| Month               | `financial_year * 100 + financial_month_num`   | 2026-10 → Key=202610, Min=2025-12-28, Max=2026-01-24     |
| Quarter             | `financial_year * 100 + financial_quarter_num` | 2026 Q3 → Key=202603, Min=2025-09-28, Max=2025-12-27     |
| Year                | `financial_year`                               | 2026 → Key=2026, Min=2025-03-30, Max=2026-03-28          |

**关键事实**：财年 2026 = 2025-03-30 ~ 2026-03-28（不是 2026-01-01 ~ 2026-12-31）。

### 1.2 为什么不能用 EDATE -12

EDATE -12 基于公历自然月偏移（365/366 天），会因闰年星期错位导致 LY 范围与"去年同编号财周/月/季/年"差 1 天。

**示例**（X 轴 = 2026 Week14, Min=2025-06-29, Max=2025-07-05）：

- EDATE -12（错误）：2024-06-29 ~ 2024-07-05（公历偏移，可能跨财周）
- 财历映射（正确）：查表得 2025 Week14 的 Min/Max = 2024-06-30 ~ 2024-07-06（去年同编号财周完整范围）

### 1.3 解决方案：财历映射

通过 `TimeFrame_Key` 偏移在 `Slicer_Time_Frame` 表中查找去年/上期同编号时间段的自然日范围（TimeFrame_Min / TimeFrame_Max），再用该自然日范围筛选事实表 `data_date`。

---

## 2. LY（Last Year，去年同期）偏移规则

### 2.1 LY Key 偏移规则

| TimeFrame_ID | LY Key 计算                           | 说明                           | 示例                     |
| ------------ | ------------------------------------- | ------------------------------ | ------------------------ |
| Day          | 不走 Key 偏移，用`EDATE(date, -12)` | 自然日无财历概念               | 2025-06-29 → 2024-06-29 |
| Week         | `Key - 100`                         | 财年*100+周数，减100即去年同周 | 202614 → 202514         |
| Month        | `Key - 100`                         | 财年*100+月数，减100即去年同月 | 202610 → 202510         |
| Quarter      | `Key - 100`                         | 财年*100+季数，减100即去年同季 | 202603 → 202503         |
| Year         | `Key - 1`                           | 财年减1即上一年                | 2026 → 2025             |

### 2.2 LY 通用查找模式（单点查找）

适用于"给定一个 TimeFrame_Key，查找其 LY 自然日范围"的场景。

```dax
// ── 输入：__CurrentTFID, __CurrentTFKey, __CurrentTFMinValue, __CurrentTFMaxValue ──
// ── 输出：__LY_TFMin, __LY_TFMax（LY 自然日范围）──

VAR __LY_TFKey =
    SWITCH(
        __CurrentTFID,
        "Year",   __CurrentTFKey - 1,
        "Week",   __CurrentTFKey - 100,
        "Month",  __CurrentTFKey - 100,
        "Quarter", __CurrentTFKey - 100,
        BLANK()  // Day 走 EDATE 分支
    )
VAR __LY_TFMin =
    IF(
        __CurrentTFID = "Day",
        EDATE(__CurrentTFMinValue, -12),
        CALCULATE(
            MIN(Slicer_Time_Frame[TimeFrame_Min]),  // 查找表替换为对应切片器表
            ALL(Slicer_Time_Frame),
            Slicer_Time_Frame[TimeFrame_ID] = __CurrentTFID,
            Slicer_Time_Frame[TimeFrame_Key] = __LY_TFKey
        )
    )
VAR __LY_TFMax =
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
```

### 2.3 LY 示例验证

**Min=2026 Week14, Max=2026 Week19**（Week 粒度）：

| 项            | Min 切片器                         | Max 切片器                       |
| ------------- | ---------------------------------- | -------------------------------- |
| 当前 Key      | 202614                             | 202619                           |
| LY Key        | 202514                             | 202519                           |
| 查表得 LY     | TimeFrame_Min=2024-06-30（假设）   | TimeFrame_Max=2024-08-04（假设） |
| LY 自然日范围 | **[2024-06-30, 2024-08-04]** |                                  |

**EDATE -12 对照**（错误）：[2024-06-29, 2024-08-09] ← 与财历映射差 1 天。

---

## 3. LP（Last Period，上期）偏移规则

### 3.1 LP 的语义

LP = 与当期期数相同、紧邻当期之前的范围（当期整体往前平移 N 期，N = 当期期数）。

**不是**"Min 上一期 + Max 上一期"（错误，会与当期重叠），**而是**"当期整体往前平移 N 期"（正确，紧邻当期之前）。

**示例**：

| 粒度 | 当期 | LP | 说明 |
|------|------|-----|------|
| Day | 2026-06-07 ~ 2026-06-09（3期） | 2026-06-04 ~ 2026-06-06（3期） | 整体前移3期 |
| Week | 2026 Week14（1期） | 2026 Week13（1期） | 整体前移1期 |
| Month | 2026-04 ~ 2026-07（4期） | 2025-12 ~ 2026-03（4期） | 整体前移4期 |
| Quarter | 2026 Q2 ~ 2026 Q3（2期） | 2025 Q4 ~ 2026 Q1（2期） | 整体前移2期 |
| Year | 2026（1期） | 2025（1期） | 整体前移1期 |

### 3.2 为什么不能用"自然日偏移当期天数"

财月/财季天数不固定（看实际数据）：

| TimeFrame_Value | TimeFrame_Min | TimeFrame_Max | 天数 |
|-----------------|---------------|---------------|------|
| 2026-10 | 2025-12-28 | 2026-01-24 | 28天 |
| 2026-06 | 2025-08-24 | 2025-09-27 | 35天 |

**问题**：当期4个月总天数（如 126天）≠ 前期4个月总天数（如 119天），自然日偏移会导致 LP Min 错位。

**验证**（Month 当期 [2026-04, 2026-07]，4期，当期 126天，前期 119天）：
- LP Max = 当期Max - 126 = 当期Min - 1 = 2025-05-24 ✓（巧合正确，因 LP Max = 当期 Min - 1）
- LP Min = 当期Min - 126 = 2025-01-19 ✗（应该 = 当期Min - 119 = 2025-01-26，差7天）

**结论**：Day/Week 粒度因每期天数固定（1天/7天），自然日偏移可用；Month/Quarter/Year 粒度因每期天数不固定，必须按"期数"偏移。

### 3.3 为什么不能用"Key 差值算期数 + Key 偏移"

TimeFrame_Key 在跨年时不连续：

| 粒度 | 跨年 Key 跳变 | 示例 |
|------|--------------|------|
| Week | 202652 → 202701（跳49） | 2026 Week52 → 2027 Week1 |
| Month | 202612 → 202701（跳89） | 2026-12 → 2027-01 |
| Quarter | 202604 → 202701（跳97） | 2026 Q4 → 2027 Q1 |

**问题**：`MaxKey - MinKey + 1` 在跨年时算出错误期数。

**验证**（Month 当期 [2026-10, 2027-02]，5期，跨年）：
- MinKey=202610, MaxKey=202702
- Key 差值 = 202702 - 202610 + 1 = 93 ✗（实际5期）

**结论**：Key 偏移法在跨年时失效，必须用 COUNTROWS 数实际行数。

### 3.4 LP 推荐方案：COUNTROWS 算期数 + TOPN 查范围（无边界问题）

**核心思路**（3步）：
1. **当期期数 N** = COUNTROWS 数维度表中落在当期范围内的行数（不受 Key 跨年跳变影响）
2. **LP 结束日** = 当期 TimeFrame_Min - 1（前一期结束日，自然日连续）
3. **LP 起始日** = 从维度表中筛 TimeFrame_Max ≤ LP结束日 的行，按 TimeFrame_Min 降序取前 N 行的 MIN(TimeFrame_Min)

```dax
// ── 输入：__GlobalTFID（粒度）, __TimeMin, __TimeMax（当期自然日范围）──
// ── 输出：__LPTimeMin, __LPTimeMax（LP 自然日范围）──
// ── 查找表：Slicer_Time_Frame（场景A用对应切片器表，场景B用 Slicer_Time_Frame）──

// 1. 当期期数 N（数落在当期范围内的行数）
VAR __N =
    CALCULATE(
        COUNTROWS(Slicer_Time_Frame),
        ALL(Slicer_Time_Frame),
        Slicer_Time_Frame[TimeFrame_ID] = __GlobalTFID,
        Slicer_Time_Frame[TimeFrame_Min] >= __TimeMin,
        Slicer_Time_Frame[TimeFrame_Max] <= __TimeMax
    )

// 2. LP 结束日 = 当期起始日 - 1
VAR __LPEndDate = __TimeMin - 1

// 3. LP 起始日 = 在 TimeFrame_Max <= LPEndDate 的行中，按 TimeFrame_Min 降序取前 N 行的 MIN(TimeFrame_Min)
VAR __LPTimeMin =
    MINX(
        TOPN(
            __N,
            CALCULATETABLE(
                Slicer_Time_Frame,
                ALL(Slicer_Time_Frame),
                Slicer_Time_Frame[TimeFrame_ID] = __GlobalTFID,
                Slicer_Time_Frame[TimeFrame_Max] <= __LPEndDate
            ),
            Slicer_Time_Frame[TimeFrame_Min], DESC
        ),
        Slicer_Time_Frame[TimeFrame_Min]
    )
VAR __LPTimeMax = __LPEndDate
```

**优势**：
- **无跨年问题**：用 COUNTROWS 代替 Key 差值算期数，用 TOPN 代替 Key 偏移查范围
- **无天数不对称问题**：按"期数"偏移，不按"天数"偏移，财月28/35天自动正确
- **所有粒度统一**：Day/Week/Month/Quarter/Year 用同一段代码，无需 SWITCH 分支
- **正确语义**：LP 期数 = 当期期数，LP Max + 1 = 当期 Min（紧邻不重叠）

**前提**：维度表时间段连续（无空隙）。Day/Week/Month/Quarter/Year 基于完整日历表生成，天然满足。

### 3.5 LP 示例验证

**Day 当期 2026-06-07 ~ 2026-06-09（3期）**：
- `__N = COUNTROWS(Day 行 Min>=2026-06-07 AND Max<=2026-06-09) = 3`
- `__LPEndDate = 2026-06-07 - 1 = 2026-06-06`
- TOPN(3, Day 行 Max<=2026-06-06, 按 Min DESC) → 2026-06-06, 2026-06-05, 2026-06-04
- `__LPTimeMin = MIN(2026-06-06, 2026-06-05, 2026-06-04) = 2026-06-04`
- `__LPTimeMax = 2026-06-06`
- LP 范围 = [2026-06-04, 2026-06-06] ✓

**Week 当期 2026 Week14（1期，Min=2025-06-29, Max=2025-07-05）**：
- `__N = 1`
- `__LPEndDate = 2025-06-29 - 1 = 2025-06-28`
- TOPN(1, Week 行 Max<=2025-06-28, 按 Min DESC) → 2026 Week13（Min=2025-06-22, Max=2025-06-28）
- `__LPTimeMin = 2025-06-22`, `__LPTimeMax = 2025-06-28`
- LP 范围 = Week13 ✓

**Month 当期 2026-04 ~ 2026-07（4期，假设 Min=2025-05-25, Max=2025-09-27）**：
- `__N = 4`
- `__LPEndDate = 2025-05-25 - 1 = 2025-05-24`
- TOPN(4, Month 行 Max<=2025-05-24, 按 Min DESC) → 2026-03, 2026-02, 2026-01, 2025-12
- `__LPTimeMin = 2025-12 的 TimeFrame_Min`（假设 2025-01-19）
- `__LPTimeMax = 2025-05-24`
- LP 范围 = 财月 [2025-12, 2026-03] ✓（4期，紧邻当期之前）

**Month 跨年当期 2026-10 ~ 2027-02（5期，跨财年）**：
- `__N = 5`（COUNTROWS 正确算出5期，不受 Key 跨年跳变影响）
- `__LPEndDate = 当期 Min - 1`
- TOPN(5, ...) → 2026-09, 2026-08, 2026-07, 2026-06, 2026-05
- LP 范围 = 财月 [2026-05, 2026-09] ✓（5期，跨年边界正确）

### 3.6 LP 与 LY 实现方式对比

| 项目 | LY（去年同期） | LP（上期） |
|------|---------------|-----------|
| 偏移单位 | 时间段编号（财年/周/月/季） | 期数（N 期） |
| 期数计算 | 不需要（固定偏移1年） | COUNTROWS 数当期行数 |
| 范围查找 | Key 偏移 + CALCULATE 查 TimeFrame_Min/Max | TOPN + MINX 查前 N 期 |
| 跨年问题 | 无（Key 偏移规则稳定） | 无（COUNTROWS + TOPN 不依赖 Key 连续性） |
| 天数不对称 | 不涉及（LY 是同编号映射） | 无（按期数偏移，不按天数） |
| 依赖维度表 | 是 | 是（COUNTROWS + TOPN 都需查表） |
| 原因 | LY 需保持"同编号"语义，Key 偏移最直接 | LP 是连续平移 N 期，TOPN 最可靠 |

---

## 4. 场景 A：仅全局日期筛选（无 X 轴）

**适用视觉对象**：卡片图（KPI Card）、单值卡片、矩阵表（无时间维度行列）。

### 4.1 场景特征

- 只有一组时间范围：来自 `Slicer_Time_Frame_Min` 和 `Slicer_Time_Frame_Max` 切片器
- Min/Max 各自选定一个时间段（同粒度），构成 `[__TimeMin, __TimeMax]` 的全局日期范围
- **无 X 轴遍历**，无需 `IsTimeFrameVisible` 视觉筛选器

### 4.2 LY 完整 DAX 模板

```dax
// ════════════════════════════════════════════════════════
// 场景 A: 仅全局日期筛选 — LY 时间范围查找
// 输出: __LYTimeMin, __LYTimeMax（用于事实表 data_date 筛选）
// ════════════════════════════════════════════════════════

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

// ── 4. 用 LY 范围筛选事实表 ──
// CALCULATE(
//     SUM(Fact[amount]),
//     Fact[data_date] >= __LYTimeMin,
//     Fact[data_date] <= __LYTimeMax
// )
```

### 4.3 LP 完整 DAX 模板

```dax
// ════════════════════════════════════════════════════════
// 场景 A: 仅全局日期筛选 — LP 时间范围查找
// 输出: __LPTimeMin, __LPTimeMax（用于事实表 data_date 筛选）
// 采用 COUNTROWS 算期数 + TOPN 查范围，无边界问题（无跨年/无天数不对称）
// ════════════════════════════════════════════════════════

// ── 1. 读取当期全局 Min/Max（自然日范围）与粒度 ──
VAR __GlobalTFID = SELECTEDVALUE(Slicer_Time_Frame_Min[TimeFrame_ID])
VAR __TimeMin = SELECTEDVALUE(Slicer_Time_Frame_Min[TimeFrame_Min])
VAR __TimeMax = SELECTEDVALUE(Slicer_Time_Frame_Max[TimeFrame_Max])

// ── 2. 当期期数 N（数 Min 切片器表中落在当期范围内的行数）──
// 注：用 Min 切片器表作为查找表（Min/Max 切片器表结构一致，均可）
VAR __N =
    CALCULATE(
        COUNTROWS(Slicer_Time_Frame_Min),
        ALL(Slicer_Time_Frame_Min),
        Slicer_Time_Frame_Min[TimeFrame_ID] = __GlobalTFID,
        Slicer_Time_Frame_Min[TimeFrame_Min] >= __TimeMin,
        Slicer_Time_Frame_Min[TimeFrame_Max] <= __TimeMax
    )

// ── 3. LP 结束日 = 当期起始日 - 1 ──
VAR __LPEndDate = __TimeMin - 1

// ── 4. LP 起始日 = 在 TimeFrame_Max <= LPEndDate 的行中按 TimeFrame_Min 降序取前 N 行的 MIN ──
VAR __LPTimeMin =
    MINX(
        TOPN(
            __N,
            CALCULATETABLE(
                Slicer_Time_Frame_Min,
                ALL(Slicer_Time_Frame_Min),
                Slicer_Time_Frame_Min[TimeFrame_ID] = __GlobalTFID,
                Slicer_Time_Frame_Min[TimeFrame_Max] <= __LPEndDate
            ),
            Slicer_Time_Frame_Min[TimeFrame_Min], DESC
        ),
        Slicer_Time_Frame_Min[TimeFrame_Min]
    )
VAR __LPTimeMax = __LPEndDate

// ── 5. 用 LP 范围筛选事实表 ──
// CALCULATE(
//     SUM(Fact[amount]),
//     Fact[data_date] >= __LPTimeMin,
//     Fact[data_date] <= __LPTimeMax
// )
```

> **说明**：场景 A 的 LP 查找表用 `Slicer_Time_Frame_Min`（也可用 `Slicer_Time_Frame_Max`，二者结构一致）。TOPN 的 N 值来自步骤 2 的 COUNTROWS，不受 Key 跨年跳变影响；TOPN 按 `TimeFrame_Min DESC` 取最紧邻当期之前的 N 期，自动适配财月 28/35 天不对称。

### 4.4 场景 A 注意事项

1. **Min/Max 同粒度**：假设 Min 和 Max 切片器受同一粒度选择器联动，从 Min 切片器读 `TimeFrame_ID` 即可。
2. **Min/Max 各自独立算 LY Key**：Min 和 Max 是两个不同时间段（Key 不同），LY Key 必须分别计算，不能共用。
3. **LP 不区分 Min/Max Key**：LP 用 COUNTROWS 算期数 + TOPN 查范围，仅需当期 `__TimeMin` / `__TimeMax` / `__GlobalTFID` 三个变量，无需分别算 Min/Max 的 Key。
4. **字段读取**：
   - Min 切片器读 `TimeFrame_Min` 字段（起始日）
   - Max 切片器读 `TimeFrame_Max` 字段（结束日）
5. **数据历史要求（LY 与 LP 都依赖维度表）**：
   - LY 需维度表包含去年同期数据，否则查找返回 BLANK，卡片显示"-"。
   - LP 需维度表包含当期之前的 N 期数据（N = 当期期数），否则 TOPN 取不满 N 行，LP Min 会偏后（LP 范围被截断）。若事实表历史数据不足，LP 数值会偏小。
6. **维度表连续性要求（仅 LP）**：LP 的 COUNTROWS 和 TOPN 假设维度表时间段连续无空隙。Day/Week/Month/Quarter/Year 基于完整日历表生成，天然满足；若维度表被业务裁剪（如只保留有销售的日子），需用未裁剪的日历表作为查找表。

---

## 5. 场景 B：全局 + X 轴

**适用视觉对象**：柱形图、趋势图、折线图（X 轴为时间段）。

### 5.1 场景特征

- 两组时间范围：
  - 全局范围：来自 `Slicer_Time_Frame_Min` / `Slicer_Time_Frame_Max`（同场景 A）
  - X 轴范围：来自 `Slicer_Time_Frame`（柱形图 X 轴遍历的当前行）
- X 轴时间段必须是全局范围的子集，通过 `IsTimeFrameVisible` 视觉对象级别筛选器保证
- 事实表筛选：`data_date ∈ [全局 Min, 全局 Max] ∩ [X 轴 Min, X 轴 Max]`
  - 由于 X 轴是全局的子集，全局筛选冗余但保留（防止异常显示）

### 5.2 LY 完整 DAX 模板

```dax
// ════════════════════════════════════════════════════════
// 场景 B: 全局 + X 轴 — LY 时间范围查找
// 输出: __LYTimeMin, __LYTimeMax（全局 LY）
//       __LYCurrentTFMin, __LYCurrentTFMax（X 轴 LY）
// ════════════════════════════════════════════════════════

// ── 1. 全局 LY 范围（同场景 A，代码省略，直接复制场景 A 的步骤 1~3）──
// VAR __GlobalTFID = ...
// VAR __LYTimeMin = ...
// VAR __LYTimeMax = ...
// （完整代码见场景 A 的 4.2 节）

// ── 2. X 轴 LY 范围（从 Slicer_Time_Frame 查找）──
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

// ── 3. 用 LY 范围筛选事实表（全局 ∩ X 轴）──
// CALCULATE(
//     SUM(Fact[amount]),
//     Fact[data_date] >= __LYTimeMin,
//     Fact[data_date] <= __LYTimeMax,
//     Fact[data_date] >= __LYCurrentTFMin,
//     Fact[data_date] <= __LYCurrentTFMax
// )
```

### 5.3 LP 完整 DAX 模板

```dax
// ════════════════════════════════════════════════════════
// 场景 B: 全局 + X 轴 — LP 时间范围查找
// 输出: __LPTimeMin, __LPTimeMax（全局 LP）
//       __LPCurrentTFMin, __LPCurrentTFMax（X 轴 LP）
// 采用 COUNTROWS 算期数 + TOPN 查范围，无边界问题（无跨年/无天数不对称）
// ════════════════════════════════════════════════════════

// ── 1. 全局 LP 范围（同场景 A，代码省略，直接复制场景 A 4.3 节的步骤 1~4）──
// VAR __GlobalTFID = SELECTEDVALUE(Slicer_Time_Frame_Min[TimeFrame_ID])
// VAR __TimeMin = ...
// VAR __TimeMax = ...
// VAR __N = COUNTROWS(...)  // 当期期数
// VAR __LPEndDate = __TimeMin - 1
// VAR __LPTimeMin = MINX(TOPN(__N, ..., TimeFrame_Min DESC), TimeFrame_Min)
// VAR __LPTimeMax = __LPEndDate
// （完整代码见场景 A 的 4.3 节）

// ── 2. X 轴 LP 范围（按 X 轴当期1期算 N=1，TOPN 查前一期的 Min/Max）──
// 注：X 轴遍历的是单个时间段，当期1期 → LP 也是1期（前一期）
VAR __CurrentTFID = SELECTEDVALUE(Slicer_Time_Frame[TimeFrame_ID])
VAR __CurrentTFMinValue = SELECTEDVALUE(Slicer_Time_Frame[TimeFrame_Min])
VAR __CurrentTFMaxValue = SELECTEDVALUE(Slicer_Time_Frame[TimeFrame_Max])

// 2.1 X 轴 LP 结束日 = X 轴当期起始日 - 1
VAR __CurrentLPEndDate = __CurrentTFMinValue - 1

// 2.2 X 轴 LP 起始日 = TOPN(1, ..., TimeFrame_Min DESC) 取紧邻当期前1期的 TimeFrame_Min
VAR __LPCurrentTFMin =
    MINX(
        TOPN(
            1,
            CALCULATETABLE(
                Slicer_Time_Frame,
                ALL(Slicer_Time_Frame),
                Slicer_Time_Frame[TimeFrame_ID] = __CurrentTFID,
                Slicer_Time_Frame[TimeFrame_Max] <= __CurrentLPEndDate
            ),
            Slicer_Time_Frame[TimeFrame_Min], DESC
        ),
        Slicer_Time_Frame[TimeFrame_Min]
    )

// 2.3 X 轴 LP 结束日 = 紧邻前1期的 TimeFrame_Max（比 __CurrentLPEndDate 更精确，落在维度表实际期边界上）
VAR __LPCurrentTFMax =
    MAXX(
        TOPN(
            1,
            CALCULATETABLE(
                Slicer_Time_Frame,
                ALL(Slicer_Time_Frame),
                Slicer_Time_Frame[TimeFrame_ID] = __CurrentTFID,
                Slicer_Time_Frame[TimeFrame_Max] <= __CurrentLPEndDate
            ),
            Slicer_Time_Frame[TimeFrame_Min], DESC
        ),
        Slicer_Time_Frame[TimeFrame_Max]
    )

// ── 3. 用 LP 范围筛选事实表（全局 ∩ X 轴）──
// CALCULATE(
//     SUM(Fact[amount]),
//     Fact[data_date] >= __LPTimeMin,
//     Fact[data_date] <= __LPTimeMax,
//     Fact[data_date] >= __LPCurrentTFMin,
//     Fact[data_date] <= __LPCurrentTFMax
// )
```

> **说明**：场景 B 的 X 轴遍历单个时间段，LP 期数固定 N=1（前一期），可直接用 `TOPN(1, ...)` 查找；若 X 轴允许选多个时间段（罕见），改用 COUNTROWS 算 N 后再 TOPN。`__LPCurrentTFMax` 用 `MAXX(TOPN(1, ...))` 取前一期 TimeFrame_Max，确保落在维度表实际期边界（比 `__CurrentTFMinValue - 1` 更语义化，二者在维度表连续时数值相等）。

### 5.4 IsTimeFrameVisible 视觉筛选器（仅场景 B 需要）

```dax
IsTimeFrameVisible = 
// ========================================
// 功能: 判断柱形图 X 轴当前行是否落在全局 [Min, Max] 范围内
// 返回: 1（显示）或 0（隐藏）
// 用法: 在柱形图/趋势图的筛选器窗格对 Slicer_Time_Frame 添加视觉对象级别筛选 = 1
// ========================================
    // 1. 全局粒度（从 Min 切片器读取，Min/Max 同粒度）
    VAR __GlobalTFID = SELECTEDVALUE(Slicer_Time_Frame_Min[TimeFrame_ID])
    // 2. 全局 Min/Max 的 Key（各自独立）
    VAR __MinKey =
        IF(
            ISFILTERED(Slicer_Time_Frame_Min[TimeFrame_Value]),
            SELECTEDVALUE(Slicer_Time_Frame_Min[TimeFrame_Key]),
            MIN(Slicer_Time_Frame[TimeFrame_Key])  // 未选则默认全部显示
        )
    VAR __MaxKey =
        IF(
            ISFILTERED(Slicer_Time_Frame_Max[TimeFrame_Value]),
            SELECTEDVALUE(Slicer_Time_Frame_Max[TimeFrame_Key]),
            MAX(Slicer_Time_Frame[TimeFrame_Key])
        )
    // 3. X 轴当前行的 Key（需同粒度才比较）
    VAR __CurrentTFID = SELECTEDVALUE(Slicer_Time_Frame[TimeFrame_ID])
    VAR __CurrentKey = SELECTEDVALUE(Slicer_Time_Frame[TimeFrame_Key])
    // 4. 同粒度 + Key 在 [MinKey, MaxKey] 区间内 → 显示
    RETURN
        IF(
            __CurrentTFID = __GlobalTFID
                && __CurrentKey >= __MinKey
                && __CurrentKey <= __MaxKey,
            1,
            0
        )
```

### 5.5 场景 B 注意事项

1. **视觉对象级别筛选器**：柱形图/趋势图必须在筛选器窗格对 `Slicer_Time_Frame` 添加 `IsTimeFrameVisible = 1`，否则 X 轴会显示全部 5 种粒度混合的所有行。
2. **X 轴 LY Key 与全局独立**：X 轴的 `TimeFrame_Key` 来自当前遍历行，与 Min/Max 切片器的 Key 不同，LY Key 必须独立计算。
3. **X 轴 LP 无需算 Key**：LP 用 TOPN 查前一期，X 轴遍历单个时间段时 N=1，直接 `TOPN(1, ..., TimeFrame_Min DESC)` 取紧邻当期前1期的 TimeFrame_Min/Max，无需算 Key、无需算天数。
4. **Day 粒度的 X 轴 LY**：用 EDATE -12；Day 粒度的 LP 用 TOPN 查前1期（自然等价于 date - 1），统一所有粒度。
5. **全局筛选冗余**：X 轴时间段是全局的子集（由 IsTimeFrameVisible 保证），全局筛选冗余但保留，用于防止异常显示，与参考 DAX（Controllable% Value）保持一致。
6. **维度表连续性要求（仅 LP）**：与场景 A 相同，X 轴 LP 的 TOPN 假设维度表时间段连续无空隙。Day/Week/Month/Quarter/Year 基于完整日历表生成，天然满足。

---

## 6. LY / LP 对比速查表

### 6.1 偏移规则对比

| 项目     | LY（去年同期）                 | LP（上期）                                       |
| -------- | ------------------------------ | ------------------------------------------------ |
| 语义     | 去年同编号时间段               | 当期整体往前平移 N 期（N = 当期期数）            |
| Day      | EDATE -12                      | COUNTROWS + TOPN（等价 date - N 天）             |
| Week     | Key - 100                      | COUNTROWS + TOPN（自动适配7天/期）               |
| Month    | Key - 100                      | COUNTROWS + TOPN（自动适配28/35天/期）           |
| Quarter  | Key - 100                      | COUNTROWS + TOPN（自动适配季天数）               |
| Year     | Key - 1                        | COUNTROWS + TOPN（自动适配年天数）               |
| 边界问题 | 无（Key 偏移可靠）             | 无（COUNTROWS 不受 Key 跨年跳变影响）            |
| 实现方式 | Key 偏移 + 维度表查找          | COUNTROWS 算期数 + TOPN 查前 N 期                |
| 依赖维度表 | 是                           | 是（COUNTROWS + TOPN 都需查维度表）              |
| 推荐实现 | Key 偏移 + EDATE 分支          | COUNTROWS + TOPN（统一，所有粒度）               |

### 6.2 场景对比

| 项目               | 场景 A（仅全局）                | 场景 B（全局 + X 轴）                    |
| ------------------ | ------------------------------- | ---------------------------------------- |
| 适用视觉对象       | 卡片图、矩阵                    | 柱形图、趋势图                           |
| 时间范围来源       | Min/Max 切片器                  | Min/Max 切片器 + Slicer_Time_Frame       |
| LY 查找次数        | 2 次（Min Key + Max Key）       | 4 次（Min + Max + X 轴 + X 轴）          |
| LP 查找次数        | 1 次 COUNTROWS + 1 次 TOPN      | 全局1次COUNTROWS+TOPN + X轴1次TOPN(N=1)  |
| IsTimeFrameVisible | 不需要                          | 需要（视觉筛选 = 1）                     |
| 事实表筛选         | 单层（全局 LY/LP）              | 双层（全局 ∩ X 轴）                      |
| DAX 复杂度         | LY 中 / LP 中                   | LY 高 / LP 中                            |

### 6.3 示例对比（Week 粒度，Min=2026 Week14, Max=2026 Week19, X 轴=2026 Week16）

当期全局期数 N = COUNTROWS(Week 行 Min>=2025-06-29 AND Max<=2025-08-09) = 6（Week14~Week19）

| 时间范围       | TY（本期）              | LY（去年同期）                           | LP（上期）                                                    |
| -------------- | ----------------------- | ---------------------------------------- | ------------------------------------------------------------- |
| 全局 Min       | 2025-06-29              | 2024-06-30（查 Key=202514）              | TOPN(6, Week行Max<=2025-06-28, Min DESC) 的 MIN(Min)（Week8） |
| 全局 Max       | 2025-08-09              | 2024-08-04（查 Key=202519）              | 2025-06-28（当期Min - 1）                                     |
| X 轴（Week16） | 2025-07-13 ~ 2025-07-19 | 2024-07-14 ~ 2024-07-20（查 Key=202516） | TOPN(1, Week行Max<=2025-07-12, Min DESC) 的 Min/Max（Week15） |

**LP 对应说明**：
- 全局 LP = [Week8 的 Min, 2025-06-28] = Week8 ~ Week13（6 期，N=6，COUNTROWS 算出，与当期 6 期长度一致）
- X 轴 LP = Week15（当期 Week16 的前一期，N=1，TOPN(1) 查出）
- **为何不用自然日偏移**：当期 42 天（6 周 × 7 天），自然日偏移在 Week 粒度巧合正确；但 Month 粒度因财月 28/35 天不对称会失效（见 3.2 节验证），统一采用 COUNTROWS + TOPN 避免边界问题。

---

## 7. 常见陷阱与最佳实践

### 7.1 常见陷阱

1. **Min/Max 共用 LY Key**：Min Key=202614, Max Key=202619，若都用 202514 查找，Max 会查错。**必须各自独立算**。
2. **字段读错**：Min 切片器应读 `TimeFrame_Min`（起始日），Max 切片器应读 `TimeFrame_Max`（结束日）。查 LY Min 用 `MIN()`，查 LY Max 用 `MAX()`。
3. **LP 用 Key - 1**：Week/Month/Quarter 的 Key-1 在跨年边界失效（如 Month01 - 1 = 00）。**用 COUNTROWS + TOPN**。
4. **LP 用 Key 差值算期数（MaxKey - MinKey + 1）**：跨年时 Key 跳变（Month 202612 → 202701 跳 89），算出错误期数。**用 COUNTROWS 数实际行数**（见 3.3 节验证）。
5. **LP 用自然日偏移当期天数**：Month/Quarter/Year 粒度因财月天数不固定（28/35天），前期总天数 ≠ 当期总天数，LP Min 会错位。**用 COUNTROWS + TOPN 按期数偏移**（见 3.2 节验证）。
6. **LP 误用"Min 上一期 + Max 上一期"**：错误语义，对 Day 当期 [6-07, 6-09] 会得到 [6-06, 6-08]（与当期重叠）。正确语义是"当期整体往前平移 N 期"，Day 当期 [6-07, 6-09] 应得 [6-04, 6-06]（不重叠）。
7. **EDATE -12 用于财历**：周/月/季/年粒度用 EDATE -12 会差 1 天。**用 Key 偏移查找**。
8. **未配置 IsTimeFrameVisible**：场景 B 不加视觉筛选器，X 轴会显示全部粒度混合的所有行。
9. **维度表被业务裁剪**：LP 的 COUNTROWS + TOPN 假设维度表时间段连续无空隙，若维度表只保留有销售的日子会失效。**用未裁剪的完整日历表作为查找表**。

### 7.2 最佳实践

1. **维度表数据历史（LY 与 LP 都依赖）**：
   - LY 需 `Slicer_Time_Frame` 表包含至少 2 年历史数据（当前年 + 去年同期），否则 LY 返回 BLANK。
   - LP 需维度表包含当期之前的 N 期数据（N = 当期期数），否则 TOPN 取不满 N 行，LP 范围被截断。
2. **Min/Max 同粒度联动**：在报表层配置粒度选择器联动 Min/Max 切片器，保持同粒度。
3. **统一查找模式**：
   - LY 用 Key 偏移 + 维度表查找（财历映射）
   - LP 用 COUNTROWS 算期数 + TOPN 查前 N 期（期数偏移）
   - 两者模式不同但都依赖维度表，且都不受 Key 跨年跳变影响。
4. **BLANK 处理**：LY/LP 查找失败返回 BLANK 时，Display 度量应显示"-"而非错误值。
5. **代码复用**：场景 B 的全局部分代码与场景 A 完全一致，可直接复制场景 A 的步骤 1~4。

---

## 8. 参考链接

- 维度表定义：[Slicer_Time_Frame.sql](<file:///d:/Users/QiYe/BaoZun/Project/Qoder_AI_Frontend_and_backend_Web/RL%20E2E/RL%20E2E%20BOSS%20Dashboard/维度复用/Slicer_Time_Frame.sql>)
- 场景 A 应用案例：[Overview_KPIs_BossCoreKPI_matrix_solution.md](<file:///d:/Users/QiYe/BaoZun/Project/Qoder_AI_Frontend_and_backend_Web/RL%20E2E/RL%20E2E%20BOSS%20Dashboard/Overview/BOSS%20Core%20KPI/Overview_KPIs_BossCoreKPI_matrix_solution.md>)（卡片图）
- 场景 B 应用案例：[Overview_Sales_DemandSLS_SLSPenetration_solution.md](<file:///d:/Users/QiYe/BaoZun/Project/Qoder_AI_Frontend_and_backend_Web/RL%20E2E/RL%20E2E%20BOSS%20Dashboard/Overview/Sales/Overview_Sales_DemandSLS_SLSPenetration_solution.md>)（柱形图/趋势图）
