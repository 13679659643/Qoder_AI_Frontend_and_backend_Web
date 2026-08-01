# TimeFrame LY / LP DAX 模板（SQL 字段方案）

> **用途**：本文档基于 [Slicer_Time_Frame.sql](<file:///d:/Users/QiYe/BaoZun/Project/Qoder_AI_Frontend_and_backend_Web/RL%20E2E/RL%20E2E%20BOSS%20Dashboard/维度复用/Slicer_Time_Frame.sql>) 新增的 4 个 LY 字段（`TimeFrame_Value_LY` / `TimeFrame_Key_LY` / `TimeFrame_Min_LY` / `TimeFrame_Max_LY`），输出 LY 和 LP 的 DAX 模板。
>
> **对比文档**：[TimeFrame_LY_LP_Offset_Rules.md](<file:///d:/Users/QiYe/BaoZun/Project/Qoder_AI_Frontend_and_backend_Web/RL%20E2E/RL%20E2E%20BOSS%20Dashboard/口径文档/TimeFrame_LY_LP_Offset_Rules.md>)（纯 DAX 方案，可对比查看）
>
> **适用维度表**：`Slicer_Time_Frame`、`Slicer_Time_Frame_Min`、`Slicer_Time_Frame_Max`（三者结构一致，均已包含 LY 字段）

---

## 1. 方案核心

### 1.1 SQL 字段方案 vs 纯 DAX 方案

| 项目 | 纯 DAX 方案（对比文档） | SQL 字段方案（本文档） |
|------|------------------------|----------------------|
| LY 实现位置 | DAX（Key 偏移 + CALCULATE 查表） | SQL（self-join 预计算） |
| LY DAX 代码量 | 20+ 行（SWITCH + CALCULATE） | 1 行（SELECTEDVALUE） |
| LP 实现位置 | DAX（COUNTROWS + TOPN） | DAX（COUNTROWS + TOPN，不变） |
| 维度表字段数 | 8 个 | 12 个（+4 个 LY 字段） |
| 跨年/天数不对称 | DAX 处理 | SQL 处理 |
| 维度表存储 | 较小 | 略增（4 字段 × 行数） |
| 复用性 | 每个度量值都要写 LY 查找逻辑 | 所有度量值直接读字段，零重复 |

### 1.2 LY 字段说明

| 字段 | 含义 | 示例 |
|------|------|------|
| TimeFrame_Value_LY | LY 时间段名称 | 2026 Week14 → 2025 Week14 |
| TimeFrame_Key_LY | LY Key | 202614 → 202514 |
| TimeFrame_Min_LY | LY 起始自然日 | 2026 Week14 → 2024-06-30 |
| TimeFrame_Max_LY | LY 结束自然日 | 2026 Week14 → 2024-07-06 |

**LY 偏移规则**（SQL self-join 实现）：
- Day: `addMonths(TimeFrame_Min, -12)` 找去年同日
- Week/Month/Quarter: `TimeFrame_Key - 100` 找去年同编号
- Year: `TimeFrame_Key - 1` 找上一年

### 1.3 LP 为什么不用 SQL 字段

LP 语义是"当期整体往前平移 N 期"，N = 当期期数（依赖用户选择 Min~Max 跨多少期）。

SQL 字段只能预计算"单行的前1期"，无法预知用户选的范围：

| 场景 | N | SQL 字段是否正确 |
|------|---|-----------------|
| X 轴单点 LP | N=1 | ✅ 正确（"前1期"= "整体前移1期"） |
| 全局范围 LP，Min=Max | N=1 | ✅ 正确 |
| 全局范围 LP，Min≠Max | N≥2 | ❌ 错误（与当期重叠） |

**验证**（Day 当期 [2026-06-07, 2026-06-09]，3期）：
- 正确 LP = [2026-06-04, 2026-06-06]（整体前移3期，紧邻当期之前）
- SQL 字段拼接 = [2026-06-06, 2026-06-08]（Min行的前1期 + Max行的前1期，与当期重叠2天）✗

**结论**：LP 全局范围仍需 DAX 的 COUNTROWS+TOPN 来算 N 期偏移。LY 是固定偏移1年，不依赖 N，适合 SQL 预计算。

---

## 2. LY DAX 模板

### 2.1 通用读取模式

```dax
// ── 输入：任意切片器表（Slicer_Time_Frame_Min / _Max / Slicer_Time_Frame）──
// ── 输出：__LYTimeMin, __LYTimeMax（LY 自然日范围，用于事实表 data_date 筛选）──

// 直接读取当前行的 LY 字段（SQL 已预计算）
VAR __LYTimeMin = SELECTEDVALUE(Slicer_Time_Frame[TimeFrame_Min_LY])
VAR __LYTimeMax = SELECTEDVALUE(Slicer_Time_Frame[TimeFrame_Max_LY])

// 用 LY 范围筛选事实表
// CALCULATE(
//     SUM(Fact[amount]),
//     Fact[data_date] >= __LYTimeMin,
//     Fact[data_date] <= __LYTimeMax
// )
```

**对比纯 DAX 方案**（20+ 行 → 2 行）：

```dax
// 纯 DAX 方案（对比文档 2.2 节，已废弃）
// VAR __LY_TFKey = SWITCH(__CurrentTFID, "Year", Key-1, "Week", Key-100, ...)
// VAR __LY_TFMin = IF(__CurrentTFID = "Day", EDATE(...), CALCULATE(MIN(...), ALL(...), ...))
// VAR __LY_TFMax = IF(__CurrentTFID = "Day", EDATE(...), CALCULATE(MAX(...), ALL(...), ...))
```

---

## 3. LP DAX 模板（保持纯 DAX 方案）

LP 仍采用 COUNTROWS + TOPN，与对比文档第 3 节一致。

### 3.1 LP 通用查找模式

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

// 3. LP 起始日 = 在 TimeFrame_Max <= LPEndDate 的行中按 TimeFrame_Min 降序取前 N 行的 MIN
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

---

## 4. 场景 A：仅全局日期筛选（无 X 轴）

**适用视觉对象**：卡片图、矩阵表。

### 4.1 LY 完整 DAX 模板

```dax
// ════════════════════════════════════════════════════════
// 场景 A: 仅全局日期筛选 — LY 时间范围查找
// 输出: __LYTimeMin, __LYTimeMax（用于事实表 data_date 筛选）
// ════════════════════════════════════════════════════════

// ── 1. 全局 LY 起始日（从 Min 切片器读取 LY 字段）──
VAR __LYTimeMin = SELECTEDVALUE(Slicer_Time_Frame_Min[TimeFrame_Min_LY])

// ── 2. 全局 LY 结束日（从 Max 切片器读取 LY 字段）──
VAR __LYTimeMax = SELECTEDVALUE(Slicer_Time_Frame_Max[TimeFrame_Max_LY])

// ── 3. 用 LY 范围筛选事实表 ──
// CALCULATE(
//     SUM(Fact[amount]),
//     Fact[data_date] >= __LYTimeMin,
//     Fact[data_date] <= __LYTimeMax
// )
```

### 4.2 LP 完整 DAX 模板

```dax
// ════════════════════════════════════════════════════════
// 场景 A: 仅全局日期筛选 — LP 时间范围查找
// 输出: __LPTimeMin, __LPTimeMax（用于事实表 data_date 筛选）
// 采用 COUNTROWS 算期数 + TOPN 查范围
// ════════════════════════════════════════════════════════

// ── 1. 读取当期全局 Min/Max（自然日范围）与粒度 ──
VAR __GlobalTFID = SELECTEDVALUE(Slicer_Time_Frame_Min[TimeFrame_ID])
VAR __TimeMin = SELECTEDVALUE(Slicer_Time_Frame_Min[TimeFrame_Min])
VAR __TimeMax = SELECTEDVALUE(Slicer_Time_Frame_Max[TimeFrame_Max])

// ── 2. 当期期数 N（数 Min 切片器表中落在当期范围内的行数）──
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

// ── 4. LP 起始日 = TOPN 前 N 行的 MIN(TimeFrame_Min) ──
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

### 4.3 场景 A 注意事项

1. **Min/Max 同粒度**：假设 Min 和 Max 切片器受同一粒度选择器联动，从 Min 切片器读 `TimeFrame_ID` 即可。
2. **Min/Max 各自独立读 LY 字段**：Min 切片器读 `TimeFrame_Min_LY`，Max 切片器读 `TimeFrame_Max_LY`，分别对应 LY 范围的起始日和结束日。
3. **LP 不区分 Min/Max Key**：LP 用 COUNTROWS + TOPN，仅需当期 `__TimeMin` / `__TimeMax` / `__GlobalTFID`。
4. **字段读取**：
   - Min 切片器读 `TimeFrame_Min`（当期起始日）和 `TimeFrame_Min_LY`（LY 起始日）
   - Max 切片器读 `TimeFrame_Max`（当期结束日）和 `TimeFrame_Max_LY`（LY 结束日）
5. **数据历史要求**：
   - LY：SQL self-join 找不到对应行时，LY 字段为 NULL，DAX 读为 BLANK，Display 度量应显示"-"。需确保维度表包含至少 2 年历史数据。
   - LP：需维度表包含当期之前的 N 期数据，否则 TOPN 取不满 N 行，LP 范围被截断。
6. **维度表连续性要求（仅 LP）**：LP 的 COUNTROWS + TOPN 假设维度表时间段连续无空隙。

---

## 5. 场景 B：全局 + X 轴

**适用视觉对象**：柱形图、趋势图、折线图（X 轴为时间段）。

### 5.1 LY 完整 DAX 模板

```dax
// ════════════════════════════════════════════════════════
// 场景 B: 全局 + X 轴 — LY 时间范围查找
// 输出: __LYTimeMin, __LYTimeMax（全局 LY）
//       __LYCurrentTFMin, __LYCurrentTFMax（X 轴 LY）
// ════════════════════════════════════════════════════════

// ── 1. 全局 LY 范围（同场景 A，直接读 LY 字段）──
VAR __LYTimeMin = SELECTEDVALUE(Slicer_Time_Frame_Min[TimeFrame_Min_LY])
VAR __LYTimeMax = SELECTEDVALUE(Slicer_Time_Frame_Max[TimeFrame_Max_LY])

// ── 2. X 轴 LY 范围（从 Slicer_Time_Frame 读取 LY 字段）──
VAR __LYCurrentTFMin = SELECTEDVALUE(Slicer_Time_Frame[TimeFrame_Min_LY])
VAR __LYCurrentTFMax = SELECTEDVALUE(Slicer_Time_Frame[TimeFrame_Max_LY])

// ── 3. 用 LY 范围筛选事实表（全局 ∩ X 轴）──
// CALCULATE(
//     SUM(Fact[amount]),
//     Fact[data_date] >= __LYTimeMin,
//     Fact[data_date] <= __LYTimeMax,
//     Fact[data_date] >= __LYCurrentTFMin,
//     Fact[data_date] <= __LYCurrentTFMax
// )
```

### 5.2 LP 完整 DAX 模板

```dax
// ════════════════════════════════════════════════════════
// 场景 B: 全局 + X 轴 — LP 时间范围查找
// 输出: __LPTimeMin, __LPTimeMax（全局 LP）
//       __LPCurrentTFMin, __LPCurrentTFMax（X 轴 LP）
// 全局 LP 用 COUNTROWS + TOPN；X 轴 LP 用 TOPN(1)（N=1）
// ════════════════════════════════════════════════════════

// ── 1. 全局 LP 范围（同场景 A，代码省略，直接复制场景 A 4.2 节步骤 1~4）──
// VAR __GlobalTFID = SELECTEDVALUE(Slicer_Time_Frame_Min[TimeFrame_ID])
// VAR __TimeMin = ...
// VAR __TimeMax = ...
// VAR __N = COUNTROWS(...)
// VAR __LPEndDate = __TimeMin - 1
// VAR __LPTimeMin = MINX(TOPN(__N, ..., TimeFrame_Min DESC), TimeFrame_Min)
// VAR __LPTimeMax = __LPEndDate
// （完整代码见场景 A 的 4.2 节）

// ── 2. X 轴 LP 范围（X 轴遍历单个时间段，N=1，TOPN 查前一期）──
VAR __CurrentTFID = SELECTEDVALUE(Slicer_Time_Frame[TimeFrame_ID])
VAR __CurrentTFMinValue = SELECTEDVALUE(Slicer_Time_Frame[TimeFrame_Min])

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

// 2.3 X 轴 LP 结束日 = 紧邻前1期的 TimeFrame_Max
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

### 5.3 IsTimeFrameVisible 视觉筛选器（仅场景 B 需要）

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

> 注：IsTimeFrameVisible 仍用 Key 比较，不依赖 LY 字段（它判断的是当期可见性，不是 LY）。

### 5.4 场景 B 注意事项

1. **视觉对象级别筛选器**：柱形图/趋势图必须在筛选器窗格对 `Slicer_Time_Frame` 添加 `IsTimeFrameVisible = 1`。
2. **X 轴 LY 与全局独立读字段**：X 轴从 `Slicer_Time_Frame` 读 LY 字段，全局从 Min/Max 切片器读 LY 字段，各自独立。
3. **X 轴 LP 无需算 Key**：LP 用 TOPN 查前一期，X 轴遍历单个时间段时 N=1。
4. **全局筛选冗余**：X 轴时间段是全局的子集（由 IsTimeFrameVisible 保证），全局筛选冗余但保留。

---

## 6. LY / LP 对比速查表

### 6.1 偏移规则对比

| 项目 | LY（去年同期） | LP（上期） |
|------|---------------|-----------|
| 实现位置 | **SQL 字段预计算** | **DAX COUNTROWS+TOPN** |
| 实现方式 | SQL self-join 找去年同编号行 | DAX 数当期期数 + TOPN 查前 N 期 |
| DAX 代码量 | 2 行（SELECTEDVALUE × 2） | 15+ 行（COUNTROWS + TOPN + MINX） |
| 依赖维度表 | 是（SQL 预计算时） | 是（DAX 运行时） |
| 跨年问题 | 无（SQL self-join 按 Key 偏移） | 无（COUNTROWS 不受 Key 跳变影响） |
| 天数不对称 | 无（SQL 按 Key 映射） | 无（TOPN 按期数偏移） |
| 字段读取 | Min 切片器读 `TimeFrame_Min_LY`，Max 切片器读 `TimeFrame_Max_LY` | 用 `__TimeMin` / `__TimeMax` 算 |

### 6.2 场景对比

| 项目 | 场景 A（仅全局） | 场景 B（全局 + X 轴） |
|------|------------------|----------------------|
| LY DAX 代码 | 2 行（读 Min/Max LY 字段） | 4 行（读 Min/Max + X 轴 LY 字段） |
| LP DAX 代码 | 15+ 行（COUNTROWS + TOPN） | 25+ 行（全局 + X 轴 TOPN） |
| IsTimeFrameVisible | 不需要 | 需要（视觉筛选 = 1） |
| 事实表筛选 | 单层（全局 LY/LP） | 双层（全局 ∩ X 轴） |
| DAX 复杂度 | LY 极低 / LP 中 | LY 低 / LP 中 |

### 6.3 示例对比（Week 粒度，Min=2026 Week14, Max=2026 Week19, X 轴=2026 Week16）

| 时间范围 | TY（本期） | LY（SQL 字段） | LP（DAX COUNTROWS+TOPN） |
|----------|-----------|---------------|-------------------------|
| 全局 Min | 2025-06-29 | `SELECTEDVALUE(Slicer_Time_Frame_Min[TimeFrame_Min_LY])` = 2024-06-30 | TOPN(6, ..., Min DESC) 的 MIN(Min) |
| 全局 Max | 2025-08-09 | `SELECTEDVALUE(Slicer_Time_Frame_Max[TimeFrame_Max_LY])` = 2024-08-04 | 2025-06-28（当期Min - 1） |
| X 轴（Week16） | 2025-07-13 ~ 2025-07-19 | `SELECTEDVALUE(Slicer_Time_Frame[TimeFrame_Min_LY])` = 2024-07-14 | TOPN(1, ..., Min DESC) 的 Min/Max |

---

## 7. 常见陷阱与最佳实践

### 7.1 常见陷阱

1. **LP 误用 SQL 字段拼接**：LP 全局范围不能用 `SELECTEDVALUE(Min[TimeFrame_Min_LP])` + `SELECTEDVALUE(Max[TimeFrame_Max_LP])`，会与当期重叠。**LP 全局范围必须用 DAX COUNTROWS+TOPN**。
2. **LY 字段为 NULL**：当期行已是维度表最早一期，SQL self-join 找不到去年对应行，LY 字段为 NULL。DAX 读为 BLANK，Display 度量应显示"-"。
3. **Min/Max 各自独立读 LY 字段**：Min 切片器读 `TimeFrame_Min_LY`（LY 起始日），Max 切片器读 `TimeFrame_Max_LY`（LY 结束日），不能混用。
4. **LP 误用"Min 上一期 + Max 上一期"**：错误语义，与当期重叠。正确语义是"当期整体往前平移 N 期"。
5. **维度表被业务裁剪**：LP 的 COUNTROWS + TOPN 假设维度表时间段连续无空隙。

### 7.2 最佳实践

1. **维度表数据历史**：
   - LY：确保 `Slicer_Time_Frame` 表包含至少 2 年历史数据（当前年 + 去年同期），否则 SQL self-join 返回 NULL。
   - LP：需维度表包含当期之前的 N 期数据，否则 TOPN 取不满 N 行。
2. **Min/Max 同粒度联动**：在报表层配置粒度选择器联动 Min/Max 切片器，保持同粒度。
3. **统一查找模式**：
   - LY 用 SQL 字段预计算（直接 SELECTEDVALUE 读取）
   - LP 用 DAX COUNTROWS + TOPN（运行时算期数偏移）
4. **BLANK 处理**：LY 字段为 BLANK 时，Display 度量应显示"-"而非错误值。
5. **代码复用**：场景 B 的全局部分代码与场景 A 完全一致，可直接复制场景 A 的步骤 1~4。

---

## 8. 参考链接

- SQL 维度表定义：[Slicer_Time_Frame.sql](<file:///d:/Users/QiYe/BaoZun/Project/Qoder_AI_Frontend_and_backend_Web/RL%20E2E/RL%20E2E%20BOSS%20Dashboard/维度复用/Slicer_Time_Frame.sql>)（含 4 个 LY 字段）
- 对比文档（纯 DAX 方案）：[TimeFrame_LY_LP_Offset_Rules.md](<file:///d:/Users/QiYe/BaoZun/Project/Qoder_AI_Frontend_and_backend_Web/RL%20E2E/RL%20E2E%20BOSS%20Dashboard/口径文档/TimeFrame_LY_LP_Offset_Rules.md>)
- 场景 A 应用案例：[Overview_KPIs_BossCoreKPI_matrix_solution.md](<file:///d:/Users/QiYe/BaoZun/Project/Qoder_AI_Frontend_and_backend_Web/RL%20E2E/RL%20E2E%20BOSS%20Dashboard/Overview/BOSS%20Core%20KPI/Overview_KPIs_BossCoreKPI_matrix_solution.md>)（卡片图）
- 场景 B 应用案例：[Overview_Sales_DemandSLS_SLSPenetration_solution.md](<file:///d:/Users/QiYe/BaoZun/Project/Qoder_AI_Frontend_and_backend_Web/RL%20E2E/RL%20E2E%20BOSS%20Dashboard/Overview/Sales/Overview_Sales_DemandSLS_SLSPenetration_solution.md>)（柱形图/趋势图）
