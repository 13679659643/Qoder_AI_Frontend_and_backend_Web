# Power BI 解决方案 — VIC Breakdown Trend：4 个指标 Value/Display 度量（柱形图趋势）

> status: ready
> created: 2026-08-15
> revised: 2026-09-12（Step1+Step2 分步口径调整，与 VIC_Breakdown_ms.md 主表同步：Step 1 = X 轴时间点 end period 当月框定 is_xxx_vic=1 / IN {0,1} user_id 集合，Step 2 = 该集合在 X 轴时间点自身时间范围（TimeFrame 区间）聚合，两步时间范围不同不能合并）
> type: 度量值开发 + 柱形图视觉对象
> 口径来源: 口径文档/VIC Breakdown KPI.md（Metric_ID 1/4/23/26 共 4 个指标）
> 参考实现: VIC_Trend.md（柱形图 X 轴 + IsTimeFrameVisible 范式）、VIC_Breakdown_ms.md（VIC Breakdown 主表口径）
> 底表: a03_e2e_customer_data_m

---

## 1. 需求理解

为 VIC Customer Dashboard 的 VIC Breakdown Trend 柱形图输出 4 个指标的独立 Value + Display 度量对：

| Metric_ID | 指标                     | VICType       | 类型       | 计算方式                                                                                                                             | 格式        |
| --------- | ------------------------ | ------------- | ---------- | ------------------------------------------------------------------------------------------------------------------------------------ | ----------- |
| 1         | SLS Act (New VIC)        | New VIC       | 金额类 Act | Step1 end period 当月框定 is_new_vic=1 集合 + Step2 TimeFrame 区间 SUM(net_pay_amt) ÷ FXRate                                        | currency_k  |
| 4         | SLS% Act (New VIC)       | New VIC       | 比率类 Act | Step1 框定分子集合（is_new_vic=1）与分母集合（is_new_vic IN {0,1}，与分子唯一区别是筛选条件）+ Step2 TimeFrame 区间各自聚合后 DIVIDE | percent_0dp |
| 23        | SLS Act (Retention VIC)  | Retention VIC | 金额类 Act | Step1 end period 当月框定 is_retention_vic=1 集合 + Step2 TimeFrame 区间 SUM(net_pay_amt) ÷ FXRate                                  | currency_k  |
| 26        | SLS% Act (Retention VIC) | Retention VIC | 比率类 Act | Step1 框定分子集合（is_retention_vic=1）与分母集合（is_retention_vic IN {0,1}）+ Step2 TimeFrame 区间各自聚合后 DIVIDE               | percent_0dp |

**核心设计原则**：

- 每个指标独立输出 Value + Display 度量对，直接平铺，不拆基础层
- 度量值作用于柱形图，X 轴 = Slicer_Time_Frame_VIC_Breakdown[TimeFrame_Value]
- 配置 IsTimeFrameVisible VIC Breakdown 视觉对象级别筛选器，控制 X 轴显示范围
- 日期表使用 VIC Breakdown 专用版本（Slicer_Time_Frame_VIC_Breakdown / _Min_ / _Max_），与主表 VIC_Breakdown_ms.md 共用，但与其他模块（VIC KPI、VIC Trend、Pie Chart 等）隔离
- 保留 VIC Breakdown 口径（Step1+Step2 分步，2026-09-12 与主表同步）：Step 1 在 X 轴时间点 end period 当月（Last_Fiscal_Month_Min/Max）框定 is_xxx_vic=1（或 IN {0,1}）user_id 集合，Step 2 在 X 轴时间点自身时间范围（TimeFrame_Min/Max）对该集合 TREATAS 聚合，两步时间范围不同不能合并；is_member / is_employee 双重人群筛选、is_new_vic / is_retention_vic 区分、金额类 ÷ Currency_ExchangeRate
- 本方案仅输出 Act 值（本期），不涉及 vs LY / vs LP / vs Store 派生指标

### 1.1 格式说明

| Metric_ID | 指标     | 原格式      | 新格式      | 格式串                                                       | 示例               |
| --------- | -------- | ----------- | ----------- | ------------------------------------------------------------ | ------------------ |
| 1, 23     | SLS Act  | currency    | currency_k  | `__CurrencySymbol & FORMAT(__Value / 1000, "#,##0") & "k"` | ¥1k / $5k / ¥12k |
| 4, 26     | SLS% Act | percent_0dp | percent_0dp | `FORMAT(__Value, "0%")`                                    | 45% / 62%          |

> **currency_k 格式说明**：将 SLS 金额（已按 FXRate 换算为 RMB 或 USD）除以 1000 后保留整数，拼接货币符号 + "k" 后缀。例如 ¥1234 → "¥1k"，$5678 → "$6k"。
> **percent_0dp 格式说明**：SLS% 为比率（0~1），FORMAT 为 0% 不保留小数。例如 0.4567 → "46%"。

### 1.2 柱形图 X 轴与时间筛选范式（Step1+Step2 分步）

参考 VIC_Trend.md（及 PB_Location_Trend.md 子模块二 Fulfillment% Trend）+ 主表 VIC_Breakdown_ms.md 的分步口径（范式参考用户已验证的"新客"DAX，即 Customer Breakdown Trend 的 TREATAS 模式）：

- 柱形图 X 轴 = Slicer_Time_Frame_VIC_Breakdown[TimeFrame_Value]
- 视觉对象级别筛选器：IsTimeFrameVisible VIC Breakdown = 1（控制 X 轴显示范围：同粒度 + Key 在 [MinKey, MaxKey] 区间）
- 度量值内部 Step1+Step2 分步（两步时间范围不同，不能合并区间计算）：
  - **Step 1**（X 轴时间点 end period 当月框定集合）：data_date ∈ Slicer_Time_Frame_VIC_Breakdown[Last_Fiscal_Month_Min] ~ [Last_Fiscal_Month_Max]，筛选 is_xxx_vic=1（SLS% 分母为 IN {0,1}），框定 user_id 集合
  - **Step 2**（X 轴时间点自身时间范围聚合）：data_date ∈ Slicer_Time_Frame_VIC_Breakdown[TimeFrame_Min] ~ [TimeFrame_Max]，TREATAS 传递 Step 1 集合聚合（is_xxx_vic 不再施加）；另加全局范围冗余筛选（Min/Max 表 TimeFrame_Min/Max，防止 X 轴超出全局范围时的异常显示）
  - Month 粒度时 Step 1 与 Step 2 区间重合（同为当月），但 Step 1 有 is_xxx_vic 筛选而 Step 2 无——语义为"当月被识别为 VIC 的人在当月的消费"；Quarter 粒度时 Step 1 为季末当月、Step 2 为整季

---

## 2. 现状分析

### 2.1 数据底表

| 对象     | 名称                                                                                  | 出处              |
| -------- | ------------------------------------------------------------------------------------- | ----------------- |
| 事实表   | a03_e2e_customer_data_m                                                               | 口径文档 全局逻辑 |
| 关键字段 | data_date, user_id, net_pay_amt, is_member, is_employee, is_new_vic, is_retention_vic | 口径文档          |

### 2.2 维度表清单（VIC Breakdown 专用日期表，与其他模块隔离）

| 维度表                              | 类型     | 连接方式                                                                                                                                                                                     |
| ----------------------------------- | -------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Slicer_Time_Frame_VIC_Breakdown     | 断开维度 | 柱形图 X 轴；SELECTEDVALUE 读取 TimeFrame_ID/Key/Value、Last_Fiscal_Month_Min/Max（Step 1：X 轴每个时间点的 end period 当月区间）、TimeFrame_Min/Max（Step 2：X 轴每个时间点自身的时间范围） |
| Slicer_Time_Frame_Max_VIC_Breakdown | 断开维度 | 结束切片器；SELECTEDVALUE 读取 TimeFrame_Max（全局范围上界）                                                                                                                                 |
| Slicer_Time_Frame_Min_VIC_Breakdown | 断开维度 | 起始切片器；SELECTEDVALUE 读取 TimeFrame_Min（全局范围下界）                                                                                                                                 |
| Slicer_Is_Employee_Selection        | 断开维度 | SELECTEDVALUE 读取 IsEmployee_Code（默认 所有）                                                                                                                                              |
| IsMemberFilter                      | 断开维度 | SELECTEDVALUE 读取 IsMember（默认 0 = TTL VIC）                                                                                                                                              |
| Slicer_Currency_Selection           | 断开维度 | SELECTEDVALUE 读取 Currency_ExchangeRate（默认 1）、Currency_Symbol（默认 "¥"）                                                                                                             |

> **日期表结构**：Slicer_Time_Frame_VIC_Breakdown 含 Last_Fiscal_Month_Min/Max 字段（与 Slicer_Time_Frame_Max_VIC_Breakdown 同源 SQL，通过自关联 dim_t00_bi_fiscal_calendar 得到每个时间点的 end period 当月区间）及 TimeFrame_Min/Max 字段（每个时间点自身的时间范围），两套区间同表内置，Step 1 / Step 2 分步直接读取，无需改动日期表。TimeFrame_ID 筛选为 Month / Quarter。

---

## 3. 方案设计

### 3.1 筛选上下文

| 筛选器                                                         | 作用方式                                                   | DAX 处理                                                                                                               |
| -------------------------------------------------------------- | ---------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------- |
| Slicer_Time_Frame_VIC_Breakdown（X 轴 Step 1 end period 当月） | 断开维度，SELECTEDVALUE 读取 Last_Fiscal_Month_Min/Max     | Step 1 框定集合：`data_date >= __CurrentLFMMin AND data_date <= __CurrentLFMMax` + `is_xxx_vic = 1`（或 IN {0,1}） |
| Slicer_Time_Frame_VIC_Breakdown（X 轴 Step 2 时间范围）        | SELECTEDVALUE 读取 TimeFrame_Min/Max                       | Step 2 TREATAS 聚合：`data_date >= __CurrentTFMin AND data_date <= __CurrentTFMax`（is_xxx_vic 不再施加）            |
| Slicer_Time_Frame_Min/Max_VIC_Breakdown（全局范围）            | 冗余保护，仅 Step 2 施加                                   | `data_date >= __GlobalMin AND data_date <= __GlobalMax`                                                              |
| Slicer_Is_Employee_Selection                                   | SELECTEDVALUE 读取 IsEmployee_Code                         | `is_employee in __IsEmployeeFilter`（默认 1）                                                                        |
| IsMemberFilter                                                 | SELECTEDVALUE 读取 IsMember                                | `is_member = __IsMemberFilter`（默认 0）                                                                             |
| Slicer_Currency_Selection                                      | SELECTEDVALUE 读取 Currency_ExchangeRate / Currency_Symbol | 金额类`DIVIDE(SUM(net_pay_amt), __FXRate)`；Display 拼接 `__CurrencySymbol`                                        |
| 事实表行维度字段（platform / shop_info_id / 新老客分层等）     | 柱形图图例/小多图直接拉取，模型自动传递                    | DAX 无需显式处理                                                                                                       |

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

| 格式类型    | 格式串                                                       | 示例       | 适用指标                                      |
| ----------- | ------------------------------------------------------------ | ---------- | --------------------------------------------- |
| currency_k  | `__CurrencySymbol & FORMAT(__Value / 1000, "#,##0") & "k"` | ¥1k / $5k | SLS Act (New VIC) / SLS Act (Retention VIC)   |
| percent_0dp | `FORMAT(__Value, "0%")`                                    | 46% / 62%  | SLS% Act (New VIC) / SLS% Act (Retention VIC) |

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
//           （Step1+Step2 分步口径，2026-09-12 与主表 VIC_Breakdown_ms.md 同步）
// 计算公式（Step1+Step2 分步，两步时间范围不同不能合并，范式参考 Customer Breakdown Trend 的 TREATAS 模式）:
//   Step 1（X 轴时间点 end period 当月框定集合）: data_date ∈ [Last_Fiscal_Month_Min, Last_Fiscal_Month_Max]，
//          筛选 is_new_vic = 1，框定 user_id 集合
//   Step 2（X 轴时间点自身时间范围聚合）: data_date ∈ [TimeFrame_Min, TimeFrame_Max]，
//          TREATAS 传递 Step 1 集合 SUM(net_pay_amt)，is_new_vic=1 不再施加
//          （另加全局范围冗余筛选，防止 X 轴超出全局范围时的异常显示）
//   结果 ÷ FXRate
// 筛选条件:
//   - is_member = __IsMemberFilter（默认 0 = TTL VIC，两步均施加）
//   - is_employee in __IsEmployeeFilter（默认 所有，两步均施加）
// 货币转换: 金额类 ÷ Currency_ExchangeRate（RMB=1, USD=7）
// Metric_ID: 1
// 数据类型: currency（内部值，未格式化）
// ========================================
    VAR __GlobalMin = SELECTEDVALUE(Slicer_Time_Frame_Min_VIC_Breakdown[TimeFrame_Min])
    VAR __GlobalMax = SELECTEDVALUE(Slicer_Time_Frame_Max_VIC_Breakdown[TimeFrame_Max])
    // ── Step 1 时间范围（X 轴当前时间点的 end period 当月）──
    VAR __CurrentLFMMin = SELECTEDVALUE(Slicer_Time_Frame_VIC_Breakdown[Last_Fiscal_Month_Min])
    VAR __CurrentLFMMax = SELECTEDVALUE(Slicer_Time_Frame_VIC_Breakdown[Last_Fiscal_Month_Max])
    // ── Step 2 时间范围（X 轴当前时间点自身的时间范围；与 Step 1 同表读取，无需改动日期表）──
    VAR __CurrentTFMin = SELECTEDVALUE(Slicer_Time_Frame_VIC_Breakdown[TimeFrame_Min])
    VAR __CurrentTFMax = SELECTEDVALUE(Slicer_Time_Frame_VIC_Breakdown[TimeFrame_Max])
    VAR __IsMemberFilter = SELECTEDVALUE(IsMemberFilter[IsMember], 0)
    VAR __IsEmployeeFilter = VALUES(Slicer_Is_Employee_Selection[IsEmployee_Code])
    VAR __FXRate = SELECTEDVALUE(Slicer_Currency_Selection[Currency_ExchangeRate], 1)

    // ═══════════════════════════════════════
    // Step 1: X 轴时间点 end period 当月，筛选 is_new_vic=1，框定 user_id 集合
    // （VICType 固定为 New VIC，直接 CALCULATETABLE 框定，无需 UNION 分支）
    // ═══════════════════════════════════════
    VAR __VICUsers =
        CALCULATETABLE(
            VALUES('a03_e2e_customer_data_m'[user_id]),
            'a03_e2e_customer_data_m'[is_new_vic] = 1,
            'a03_e2e_customer_data_m'[is_member] = __IsMemberFilter,
            'a03_e2e_customer_data_m'[is_employee] in __IsEmployeeFilter,
            'a03_e2e_customer_data_m'[data_date] >= __CurrentLFMMin,
            'a03_e2e_customer_data_m'[data_date] <= __CurrentLFMMax
        )

    // ═══════════════════════════════════════
    // Step 2: 该 user_id 集合在 X 轴时间点自身时间范围（+全局冗余）的 SUM(net_pay_amt)
    // is_new_vic=1 不再施加（Step 1 已框定主体）；分组维度（图例/小多图）自动传递保留（不移除）
    // ═══════════════════════════════════════
    VAR __Result =
        DIVIDE(
            CALCULATE(
                SUM('a03_e2e_customer_data_m'[net_pay_amt]),
                TREATAS(__VICUsers, 'a03_e2e_customer_data_m'[user_id]),
                'a03_e2e_customer_data_m'[is_member] = __IsMemberFilter,
                'a03_e2e_customer_data_m'[is_employee] in __IsEmployeeFilter,
                'a03_e2e_customer_data_m'[data_date] >= __GlobalMin,
                'a03_e2e_customer_data_m'[data_date] <= __GlobalMax,
                'a03_e2e_customer_data_m'[data_date] >= __CurrentTFMin,
                'a03_e2e_customer_data_m'[data_date] <= __CurrentTFMax
            ),
            __FXRate
        )
    RETURN __Result

/* ── 旧逻辑：end period 当月单步聚合（2026-09-12 弃用，保留备查）──
   当时口径理解: "dt = 所选时间范围 end period" 直接单步聚合（is_new_vic=1 + 当月区间 + 全局冗余）。
   2026-09-12 修订: 与主表同步改为 Step1+Step2 分步——单步版无法体现"end period 当月框定人群、
   再看时间范围消费"的两步语义（Quarter 粒度时 Step 1 为季末当月、Step 2 为整季，两步区间不同）。
   如需回退: 注释掉上方 Step1/Step2 分步实现（含 __VICUsers 与 TREATAS 块），并恢复下方实现:

    VAR __Result =
        DIVIDE(
            CALCULATE(
                SUM('a03_e2e_customer_data_m'[net_pay_amt]),
                'a03_e2e_customer_data_m'[is_new_vic] = 1,
                'a03_e2e_customer_data_m'[is_member] = __IsMemberFilter,
                'a03_e2e_customer_data_m'[is_employee] in __IsEmployeeFilter,
                'a03_e2e_customer_data_m'[data_date] >= __GlobalMin,
                'a03_e2e_customer_data_m'[data_date] <= __GlobalMax,
                'a03_e2e_customer_data_m'[data_date] >= __CurrentLFMMin,
                'a03_e2e_customer_data_m'[data_date] <= __CurrentLFMMax
            ),
            __FXRate
        )
    RETURN __Result
── 旧逻辑结束 ── */
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
//           （Step1+Step2 分步口径，2026-09-12 与主表 VIC_Breakdown_ms.md 同步）
// 计算公式: DIVIDE(分子, 分母)，分子分母均 Step1+Step2 分步（两步时间范围不同不能合并）:
//   分子（New VIC 集合）:
//     Step 1: data_date ∈ [Last_Fiscal_Month_Min, Max]（X 轴 end period 当月），is_new_vic = 1，框定集合
//     Step 2: data_date ∈ [TimeFrame_Min, Max]（X 轴时间点自身范围），TREATAS 聚合（is_new_vic=1 不再施加）
//   分母（全客集合，与分子唯一区别是 Step 1 的筛选条件）:
//     Step 1: 同上区间，is_new_vic IN {0, 1}，框定全客集合
//     Step 2: 同上区间，TREATAS 聚合（is_new_vic IN {0,1} 不再施加）
//   两步均另加全局范围冗余筛选（仅 Step 2 施加，防 X 轴超出全局范围异常显示）
// 筛选条件:
//   - is_member = __IsMemberFilter（默认 0 = TTL VIC，两步均施加）
//   - is_employee in __IsEmployeeFilter（默认 所有，两步均施加）
// 货币转换: SLS% 占比不除（分子分母同币种抵消）
// Metric_ID: 4
// 数据类型: percent_0dp（比率，0~1）
// ========================================
    VAR __GlobalMin = SELECTEDVALUE(Slicer_Time_Frame_Min_VIC_Breakdown[TimeFrame_Min])
    VAR __GlobalMax = SELECTEDVALUE(Slicer_Time_Frame_Max_VIC_Breakdown[TimeFrame_Max])
    // ── Step 1 时间范围（X 轴当前时间点的 end period 当月）──
    VAR __CurrentLFMMin = SELECTEDVALUE(Slicer_Time_Frame_VIC_Breakdown[Last_Fiscal_Month_Min])
    VAR __CurrentLFMMax = SELECTEDVALUE(Slicer_Time_Frame_VIC_Breakdown[Last_Fiscal_Month_Max])
    // ── Step 2 时间范围（X 轴当前时间点自身的时间范围；与 Step 1 同表读取）──
    VAR __CurrentTFMin = SELECTEDVALUE(Slicer_Time_Frame_VIC_Breakdown[TimeFrame_Min])
    VAR __CurrentTFMax = SELECTEDVALUE(Slicer_Time_Frame_VIC_Breakdown[TimeFrame_Max])
    VAR __IsMemberFilter = SELECTEDVALUE(IsMemberFilter[IsMember], 0)
    VAR __IsEmployeeFilter = VALUES(Slicer_Is_Employee_Selection[IsEmployee_Code])

    // ═══════════════════════════════════════
    // Step 1: X 轴时间点 end period 当月，各自框定分子/分母 user_id 集合
    // （分母与分子唯一区别是筛选条件：is_new_vic IN {0,1} 全客 vs =1 New VIC）
    // ═══════════════════════════════════════
    VAR __VICUsers =
        CALCULATETABLE(
            VALUES('a03_e2e_customer_data_m'[user_id]),
            'a03_e2e_customer_data_m'[is_new_vic] = 1,
            'a03_e2e_customer_data_m'[is_member] = __IsMemberFilter,
            'a03_e2e_customer_data_m'[is_employee] in __IsEmployeeFilter,
            'a03_e2e_customer_data_m'[data_date] >= __CurrentLFMMin,
            'a03_e2e_customer_data_m'[data_date] <= __CurrentLFMMax
        )
    VAR __AllUsers =
        CALCULATETABLE(
            VALUES('a03_e2e_customer_data_m'[user_id]),
            'a03_e2e_customer_data_m'[is_new_vic] IN {0, 1},
            'a03_e2e_customer_data_m'[is_member] = __IsMemberFilter,
            'a03_e2e_customer_data_m'[is_employee] in __IsEmployeeFilter,
            'a03_e2e_customer_data_m'[data_date] >= __CurrentLFMMin,
            'a03_e2e_customer_data_m'[data_date] <= __CurrentLFMMax
        )

    // ═══════════════════════════════════════
    // Step 2: 各集合在 X 轴时间点自身时间范围（+全局冗余）的 SUM(net_pay_amt)
    // is_new_vic 筛选不再施加（Step 1 已框定主体）；分组维度自动传递保留（不移除）
    // ═══════════════════════════════════════
    VAR __Numerator =
        CALCULATE(
            SUM('a03_e2e_customer_data_m'[net_pay_amt]),
            TREATAS(__VICUsers, 'a03_e2e_customer_data_m'[user_id]),
            'a03_e2e_customer_data_m'[is_member] = __IsMemberFilter,
            'a03_e2e_customer_data_m'[is_employee] in __IsEmployeeFilter,
            'a03_e2e_customer_data_m'[data_date] >= __GlobalMin,
            'a03_e2e_customer_data_m'[data_date] <= __GlobalMax,
            'a03_e2e_customer_data_m'[data_date] >= __CurrentTFMin,
            'a03_e2e_customer_data_m'[data_date] <= __CurrentTFMax
        )
    VAR __Denominator =
        CALCULATE(
            SUM('a03_e2e_customer_data_m'[net_pay_amt]),
            TREATAS(__AllUsers, 'a03_e2e_customer_data_m'[user_id]),
            'a03_e2e_customer_data_m'[is_member] = __IsMemberFilter,
            'a03_e2e_customer_data_m'[is_employee] in __IsEmployeeFilter,
            'a03_e2e_customer_data_m'[data_date] >= __GlobalMin,
            'a03_e2e_customer_data_m'[data_date] <= __GlobalMax,
            'a03_e2e_customer_data_m'[data_date] >= __CurrentTFMin,
            'a03_e2e_customer_data_m'[data_date] <= __CurrentTFMax
        )

    RETURN DIVIDE(__Numerator, __Denominator)

/* ── 旧逻辑：end period 当月单步聚合（2026-09-12 弃用，保留备查）──
   当时口径理解: 分子分母均单步聚合（各自筛选 + 当月区间 + 全局冗余）。
   2026-09-12 修订: 与主表同步改为 Step1+Step2 分步——分子分母均先框定集合再看时间范围，
   分母集合（is_new_vic IN {0,1}）与分子唯一区别是 Step 1 的筛选条件（与主表 Store 分母分步化一致）。
   如需回退: 注释掉上方 Step1/Step2 分步实现（含 __VICUsers/__AllUsers 与 TREATAS 块），并恢复下方实现:

    // ── 分子: is_new_vic=1 的 SLS ──
    VAR __Numerator =
        CALCULATE(
            SUM('a03_e2e_customer_data_m'[net_pay_amt]),
            'a03_e2e_customer_data_m'[is_new_vic] = 1,
            'a03_e2e_customer_data_m'[is_member] = __IsMemberFilter,
            'a03_e2e_customer_data_m'[is_employee] in __IsEmployeeFilter,
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
            'a03_e2e_customer_data_m'[is_employee] in __IsEmployeeFilter,
            'a03_e2e_customer_data_m'[data_date] >= __GlobalMin,
            'a03_e2e_customer_data_m'[data_date] <= __GlobalMax,
            'a03_e2e_customer_data_m'[data_date] >= __CurrentLFMMin,
            'a03_e2e_customer_data_m'[data_date] <= __CurrentLFMMax
        )

    RETURN DIVIDE(__Numerator, __Denominator)
── 旧逻辑结束 ── */
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
//           （Step1+Step2 分步口径，2026-09-12 与主表 VIC_Breakdown_ms.md 同步）
// 计算公式（Step1+Step2 分步，两步时间范围不同不能合并，范式参考 Customer Breakdown Trend 的 TREATAS 模式）:
//   Step 1（X 轴时间点 end period 当月框定集合）: data_date ∈ [Last_Fiscal_Month_Min, Last_Fiscal_Month_Max]，
//          筛选 is_retention_vic = 1，框定 user_id 集合
//   Step 2（X 轴时间点自身时间范围聚合）: data_date ∈ [TimeFrame_Min, TimeFrame_Max]，
//          TREATAS 传递 Step 1 集合 SUM(net_pay_amt)，is_retention_vic=1 不再施加
//          （另加全局范围冗余筛选，防止 X 轴超出全局范围时的异常显示）
//   结果 ÷ FXRate
// 筛选条件:
//   - is_member = __IsMemberFilter（默认 0 = TTL VIC，两步均施加）
//   - is_employee in __IsEmployeeFilter（默认 所有，两步均施加）
// 货币转换: 金额类 ÷ Currency_ExchangeRate（RMB=1, USD=7）
// Metric_ID: 23
// 数据类型: currency（内部值，未格式化）
// ========================================
    VAR __GlobalMin = SELECTEDVALUE(Slicer_Time_Frame_Min_VIC_Breakdown[TimeFrame_Min])
    VAR __GlobalMax = SELECTEDVALUE(Slicer_Time_Frame_Max_VIC_Breakdown[TimeFrame_Max])
    // ── Step 1 时间范围（X 轴当前时间点的 end period 当月）──
    VAR __CurrentLFMMin = SELECTEDVALUE(Slicer_Time_Frame_VIC_Breakdown[Last_Fiscal_Month_Min])
    VAR __CurrentLFMMax = SELECTEDVALUE(Slicer_Time_Frame_VIC_Breakdown[Last_Fiscal_Month_Max])
    // ── Step 2 时间范围（X 轴当前时间点自身的时间范围；与 Step 1 同表读取）──
    VAR __CurrentTFMin = SELECTEDVALUE(Slicer_Time_Frame_VIC_Breakdown[TimeFrame_Min])
    VAR __CurrentTFMax = SELECTEDVALUE(Slicer_Time_Frame_VIC_Breakdown[TimeFrame_Max])
    VAR __IsMemberFilter = SELECTEDVALUE(IsMemberFilter[IsMember], 0)
    VAR __IsEmployeeFilter = VALUES(Slicer_Is_Employee_Selection[IsEmployee_Code])
    VAR __FXRate = SELECTEDVALUE(Slicer_Currency_Selection[Currency_ExchangeRate], 1)

    // ═══════════════════════════════════════
    // Step 1: X 轴时间点 end period 当月，筛选 is_retention_vic=1，框定 user_id 集合
    // （VICType 固定为 Retention VIC，直接 CALCULATETABLE 框定，无需 UNION 分支）
    // ═══════════════════════════════════════
    VAR __VICUsers =
        CALCULATETABLE(
            VALUES('a03_e2e_customer_data_m'[user_id]),
            'a03_e2e_customer_data_m'[is_retention_vic] = 1,
            'a03_e2e_customer_data_m'[is_member] = __IsMemberFilter,
            'a03_e2e_customer_data_m'[is_employee] in __IsEmployeeFilter,
            'a03_e2e_customer_data_m'[data_date] >= __CurrentLFMMin,
            'a03_e2e_customer_data_m'[data_date] <= __CurrentLFMMax
        )

    // ═══════════════════════════════════════
    // Step 2: 该 user_id 集合在 X 轴时间点自身时间范围（+全局冗余）的 SUM(net_pay_amt)
    // is_retention_vic=1 不再施加（Step 1 已框定主体）；分组维度自动传递保留（不移除）
    // ═══════════════════════════════════════
    VAR __Result =
        DIVIDE(
            CALCULATE(
                SUM('a03_e2e_customer_data_m'[net_pay_amt]),
                TREATAS(__VICUsers, 'a03_e2e_customer_data_m'[user_id]),
                'a03_e2e_customer_data_m'[is_member] = __IsMemberFilter,
                'a03_e2e_customer_data_m'[is_employee] in __IsEmployeeFilter,
                'a03_e2e_customer_data_m'[data_date] >= __GlobalMin,
                'a03_e2e_customer_data_m'[data_date] <= __GlobalMax,
                'a03_e2e_customer_data_m'[data_date] >= __CurrentTFMin,
                'a03_e2e_customer_data_m'[data_date] <= __CurrentTFMax
            ),
            __FXRate
        )
    RETURN __Result

/* ── 旧逻辑：end period 当月单步聚合（2026-09-12 弃用，保留备查）──
   当时口径理解: "dt = 所选时间范围 end period" 直接单步聚合（is_retention_vic=1 + 当月区间 + 全局冗余）。
   2026-09-12 修订: 与主表同步改为 Step1+Step2 分步——单步版无法体现"end period 当月框定人群、
   再看时间范围消费"的两步语义（Quarter 粒度时 Step 1 为季末当月、Step 2 为整季，两步区间不同）。
   如需回退: 注释掉上方 Step1/Step2 分步实现（含 __VICUsers 与 TREATAS 块），并恢复下方实现:

    VAR __Result =
        DIVIDE(
            CALCULATE(
                SUM('a03_e2e_customer_data_m'[net_pay_amt]),
                'a03_e2e_customer_data_m'[is_retention_vic] = 1,
                'a03_e2e_customer_data_m'[is_member] = __IsMemberFilter,
                'a03_e2e_customer_data_m'[is_employee] in __IsEmployeeFilter,
                'a03_e2e_customer_data_m'[data_date] >= __GlobalMin,
                'a03_e2e_customer_data_m'[data_date] <= __GlobalMax,
                'a03_e2e_customer_data_m'[data_date] >= __CurrentLFMMin,
                'a03_e2e_customer_data_m'[data_date] <= __CurrentLFMMax
            ),
            __FXRate
        )
    RETURN __Result
── 旧逻辑结束 ── */
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
//           （Step1+Step2 分步口径，2026-09-12 与主表 VIC_Breakdown_ms.md 同步）
// 计算公式: DIVIDE(分子, 分母)，分子分母均 Step1+Step2 分步（两步时间范围不同不能合并）:
//   分子（Retention VIC 集合）:
//     Step 1: data_date ∈ [Last_Fiscal_Month_Min, Max]（X 轴 end period 当月），is_retention_vic = 1，框定集合
//     Step 2: data_date ∈ [TimeFrame_Min, Max]（X 轴时间点自身范围），TREATAS 聚合（is_retention_vic=1 不再施加）
//   分母（全客集合，与分子唯一区别是 Step 1 的筛选条件）:
//     Step 1: 同上区间，is_retention_vic IN {0, 1}，框定全客集合
//     Step 2: 同上区间，TREATAS 聚合（is_retention_vic IN {0,1} 不再施加）
//   两步均另加全局范围冗余筛选（仅 Step 2 施加，防 X 轴超出全局范围异常显示）
// 筛选条件:
//   - is_member = __IsMemberFilter（默认 0 = TTL VIC，两步均施加）
//   - is_employee in __IsEmployeeFilter（默认 所有，两步均施加）
// 货币转换: SLS% 占比不除（分子分母同币种抵消）
// Metric_ID: 26
// 数据类型: percent_0dp（比率，0~1）
// ========================================
    VAR __GlobalMin = SELECTEDVALUE(Slicer_Time_Frame_Min_VIC_Breakdown[TimeFrame_Min])
    VAR __GlobalMax = SELECTEDVALUE(Slicer_Time_Frame_Max_VIC_Breakdown[TimeFrame_Max])
    // ── Step 1 时间范围（X 轴当前时间点的 end period 当月）──
    VAR __CurrentLFMMin = SELECTEDVALUE(Slicer_Time_Frame_VIC_Breakdown[Last_Fiscal_Month_Min])
    VAR __CurrentLFMMax = SELECTEDVALUE(Slicer_Time_Frame_VIC_Breakdown[Last_Fiscal_Month_Max])
    // ── Step 2 时间范围（X 轴当前时间点自身的时间范围；与 Step 1 同表读取）──
    VAR __CurrentTFMin = SELECTEDVALUE(Slicer_Time_Frame_VIC_Breakdown[TimeFrame_Min])
    VAR __CurrentTFMax = SELECTEDVALUE(Slicer_Time_Frame_VIC_Breakdown[TimeFrame_Max])
    VAR __IsMemberFilter = SELECTEDVALUE(IsMemberFilter[IsMember], 0)
    VAR __IsEmployeeFilter = VALUES(Slicer_Is_Employee_Selection[IsEmployee_Code])

    // ═══════════════════════════════════════
    // Step 1: X 轴时间点 end period 当月，各自框定分子/分母 user_id 集合
    // （分母与分子唯一区别是筛选条件：is_retention_vic IN {0,1} 全客 vs =1 Retention VIC）
    // ═══════════════════════════════════════
    VAR __VICUsers =
        CALCULATETABLE(
            VALUES('a03_e2e_customer_data_m'[user_id]),
            'a03_e2e_customer_data_m'[is_retention_vic] = 1,
            'a03_e2e_customer_data_m'[is_member] = __IsMemberFilter,
            'a03_e2e_customer_data_m'[is_employee] in __IsEmployeeFilter,
            'a03_e2e_customer_data_m'[data_date] >= __CurrentLFMMin,
            'a03_e2e_customer_data_m'[data_date] <= __CurrentLFMMax
        )
    VAR __AllUsers =
        CALCULATETABLE(
            VALUES('a03_e2e_customer_data_m'[user_id]),
            'a03_e2e_customer_data_m'[is_retention_vic] IN {0, 1},
            'a03_e2e_customer_data_m'[is_member] = __IsMemberFilter,
            'a03_e2e_customer_data_m'[is_employee] in __IsEmployeeFilter,
            'a03_e2e_customer_data_m'[data_date] >= __CurrentLFMMin,
            'a03_e2e_customer_data_m'[data_date] <= __CurrentLFMMax
        )

    // ═══════════════════════════════════════
    // Step 2: 各集合在 X 轴时间点自身时间范围（+全局冗余）的 SUM(net_pay_amt)
    // is_retention_vic 筛选不再施加（Step 1 已框定主体）；分组维度自动传递保留（不移除）
    // ═══════════════════════════════════════
    VAR __Numerator =
        CALCULATE(
            SUM('a03_e2e_customer_data_m'[net_pay_amt]),
            TREATAS(__VICUsers, 'a03_e2e_customer_data_m'[user_id]),
            'a03_e2e_customer_data_m'[is_member] = __IsMemberFilter,
            'a03_e2e_customer_data_m'[is_employee] in __IsEmployeeFilter,
            'a03_e2e_customer_data_m'[data_date] >= __GlobalMin,
            'a03_e2e_customer_data_m'[data_date] <= __GlobalMax,
            'a03_e2e_customer_data_m'[data_date] >= __CurrentTFMin,
            'a03_e2e_customer_data_m'[data_date] <= __CurrentTFMax
        )
    VAR __Denominator =
        CALCULATE(
            SUM('a03_e2e_customer_data_m'[net_pay_amt]),
            TREATAS(__AllUsers, 'a03_e2e_customer_data_m'[user_id]),
            'a03_e2e_customer_data_m'[is_member] = __IsMemberFilter,
            'a03_e2e_customer_data_m'[is_employee] in __IsEmployeeFilter,
            'a03_e2e_customer_data_m'[data_date] >= __GlobalMin,
            'a03_e2e_customer_data_m'[data_date] <= __GlobalMax,
            'a03_e2e_customer_data_m'[data_date] >= __CurrentTFMin,
            'a03_e2e_customer_data_m'[data_date] <= __CurrentTFMax
        )

    RETURN DIVIDE(__Numerator, __Denominator)

/* ── 旧逻辑：end period 当月单步聚合（2026-09-12 弃用，保留备查）──
   当时口径理解: 分子分母均单步聚合（各自筛选 + 当月区间 + 全局冗余）。
   2026-09-12 修订: 与主表同步改为 Step1+Step2 分步——分子分母均先框定集合再看时间范围，
   分母集合（is_retention_vic IN {0,1}）与分子唯一区别是 Step 1 的筛选条件（与主表 Store 分母分步化一致）。
   如需回退: 注释掉上方 Step1/Step2 分步实现（含 __VICUsers/__AllUsers 与 TREATAS 块），并恢复下方实现:

    // ── 分子: is_retention_vic=1 的 SLS ──
    VAR __Numerator =
        CALCULATE(
            SUM('a03_e2e_customer_data_m'[net_pay_amt]),
            'a03_e2e_customer_data_m'[is_retention_vic] = 1,
            'a03_e2e_customer_data_m'[is_member] = __IsMemberFilter,
            'a03_e2e_customer_data_m'[is_employee] in __IsEmployeeFilter,
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
            'a03_e2e_customer_data_m'[is_employee] in __IsEmployeeFilter,
            'a03_e2e_customer_data_m'[data_date] >= __GlobalMin,
            'a03_e2e_customer_data_m'[data_date] <= __GlobalMax,
            'a03_e2e_customer_data_m'[data_date] >= __CurrentLFMMin,
            'a03_e2e_customer_data_m'[data_date] <= __CurrentLFMMax
        )

    RETURN DIVIDE(__Numerator, __Denominator)
── 旧逻辑结束 ── */
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

| 序号 | 度量值名称                         | Display Folder      | Metric_ID | 指标                     | 类型    | 格式        |
| ---- | ---------------------------------- | ------------------- | --------- | ------------------------ | ------- | ----------- |
| 1    | IsTimeFrameVisible VIC Breakdown   | VIC Breakdown Trend | —        | X 轴筛选器               | 辅助    | —          |
| 2    | SLS Trend Value (New VIC)          | VIC Breakdown Trend | 1         | SLS Act (New VIC)        | Value   | currency_k  |
| 3    | SLS Trend Display (New VIC)        | VIC Breakdown Trend | 1         | SLS Act (New VIC)        | Display | currency_k  |
| 4    | SLS% Trend Value (New VIC)         | VIC Breakdown Trend | 4         | SLS% Act (New VIC)       | Value   | percent_0dp |
| 5    | SLS% Trend Display (New VIC)       | VIC Breakdown Trend | 4         | SLS% Act (New VIC)       | Display | percent_0dp |
| 6    | SLS Trend Value (Retention VIC)    | VIC Breakdown Trend | 23        | SLS Act (Retention VIC)  | Value   | currency_k  |
| 7    | SLS Trend Display (Retention VIC)  | VIC Breakdown Trend | 23        | SLS Act (Retention VIC)  | Display | currency_k  |
| 8    | SLS% Trend Value (Retention VIC)   | VIC Breakdown Trend | 26        | SLS% Act (Retention VIC) | Value   | percent_0dp |
| 9    | SLS% Trend Display (Retention VIC) | VIC Breakdown Trend | 26        | SLS% Act (Retention VIC) | Display | percent_0dp |

---

## 6. 视觉对象配置

### 6.1 柱形图（VIC Breakdown Trend）

| 配置项             | 值                                                                                                                                                |
| ------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------- |
| X 轴               | Slicer_Time_Frame_VIC_Breakdown[TimeFrame_Value]                                                                                                  |
| Y 轴               | 按需拉取 4 个 Value 度量之一（如 [SLS Trend Value (New VIC)]）                                                                                    |
| 图例               | 可选：a03_e2e_customer_data_m[platform] 或 [shop_info_id]（直接拉取，天然筛选+分组）                                                              |
| 数据标签           | 对应 [* Display] 度量                                                                                                                             |
| 视觉对象级别筛选器 | Slicer_Time_Frame_VIC_Breakdown 表上 [IsTimeFrameVisible VIC Breakdown] = 1                                                                       |
| 全局筛选器         | Slicer_Time_Frame_Min_VIC_Breakdown、Slicer_Time_Frame_Max_VIC_Breakdown、Slicer_Is_Employee_Selection、IsMemberFilter、Slicer_Currency_Selection |

### 6.2 度量值拉取示例

| 场景                    | 拉取度量                             |
| ----------------------- | ------------------------------------ |
| New VIC SLS 趋势        | [SLS Trend Display (New VIC)]        |
| New VIC SLS% 趋势       | [SLS% Trend Display (New VIC)]       |
| Retention VIC SLS 趋势  | [SLS Trend Display (Retention VIC)]  |
| Retention VIC SLS% 趋势 | [SLS% Trend Display (Retention VIC)] |

---

## 7. 验证方法

### 7.1 验证 SQL（SLS Trend Value (New VIC)，Step1+Step2 分步）

```sql
-- New VIC SLS 本期值（某月，所有 platform 汇总，Step1+Step2 分步）
-- 假设 X 轴 TimeFrame = 2026-09（Month 粒度：Step 1 与 Step 2 区间同为当月）
--        Last_Fiscal_Month_Min='2026-09-01', Last_Fiscal_Month_Max='2026-09-30'
--        TimeFrame_Min='2026-09-01', TimeFrame_Max='2026-09-30'
--        （Quarter 粒度示例：X 轴 = 2026 Q3 时 Step 1 为 2025-12-28~2026-01-24 季末当月，Step 2 为整季区间）
-- is_member=0 (TTL VIC), is_employee=1 (Yes), FXRate=1 (RMB)
-- Step 1: end period 当月框定 is_new_vic=1 user_id 集合
-- Step 2: 该集合在 TimeFrame 区间 SUM(net_pay_amt)（is_new_vic 不再施加）
WITH vic_users AS (
  SELECT DISTINCT user_id
  FROM a03_e2e_customer_data_m
  WHERE data_date BETWEEN '2026-09-01' AND '2026-09-30'   -- Step 1: end period 当月
    AND is_new_vic = 1
    AND is_member = 0
    AND is_employee = 1
)
SELECT
    SUM(f.net_pay_amt) / 1 AS SLS_Trend_NewVIC  -- FXRate=1 (RMB), 若 USD 则除以 7
FROM a03_e2e_customer_data_m f
JOIN vic_users u ON f.user_id = u.user_id
WHERE f.data_date BETWEEN '2026-09-01' AND '2026-09-30'   -- Step 2: TimeFrame 区间
  AND f.is_member = 0
  AND f.is_employee = 1;
```

### 7.2 验证 SQL（SLS% Trend Value (New VIC)，Step1+Step2 分步）

```sql
-- New VIC SLS% 本期比率（Step1+Step2 分步）
-- Step 1: end period 当月各自框定分子集合（is_new_vic=1）与分母集合（is_new_vic IN (0,1)，
--         与分子唯一区别是筛选条件）
-- Step 2: 各集合在 TimeFrame 区间 SUM(net_pay_amt) 后相除
WITH vic_users AS (
  SELECT DISTINCT user_id
  FROM a03_e2e_customer_data_m
  WHERE data_date BETWEEN '2026-09-01' AND '2026-09-30'   -- Step 1: end period 当月
    AND is_new_vic = 1
    AND is_member = 0
    AND is_employee = 1
),
all_users AS (
  SELECT DISTINCT user_id
  FROM a03_e2e_customer_data_m
  WHERE data_date BETWEEN '2026-09-01' AND '2026-09-30'   -- Step 1: end period 当月
    AND is_new_vic IN (0, 1)
    AND is_member = 0
    AND is_employee = 1
),
numerator AS (
  SELECT SUM(f.net_pay_amt) AS amt
  FROM a03_e2e_customer_data_m f
  JOIN vic_users u ON f.user_id = u.user_id
  WHERE f.data_date BETWEEN '2026-09-01' AND '2026-09-30' -- Step 2: TimeFrame 区间
    AND f.is_member = 0
    AND f.is_employee = 1
),
denominator AS (
  SELECT SUM(f.net_pay_amt) AS amt
  FROM a03_e2e_customer_data_m f
  JOIN all_users u ON f.user_id = u.user_id
  WHERE f.data_date BETWEEN '2026-09-01' AND '2026-09-30' -- Step 2: TimeFrame 区间
    AND f.is_member = 0
    AND f.is_employee = 1
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
3. **Step1+Step2 分步时间筛选（2026-09-12 修订，关键逻辑）**：度量值内部两步分步计算，两步时间范围不同不能合并——Step 1 用 X 轴当前时间点的 end period 当月（Last_Fiscal_Month_Min/Max）框定 user_id 集合（施加 is_xxx_vic 筛选）；Step 2 用 X 轴当前时间点自身时间范围（TimeFrame_Min/Max）TREATAS 聚合（is_xxx_vic 不再施加）。Month 粒度时两步区间重合但筛选条件不同；Quarter 粒度时 Step 1 为季末当月、Step 2 为整季。全局范围冗余筛选（Min/Max 表 TimeFrame_Min/Max）仅 Step 2 施加，防止 X 轴超出全局范围时的异常显示（参考 VIC_Trend.md / PB_Location_Trend.md 范式）。
4. **New VIC / Retention VIC 区分（关键逻辑）**：

   - New VIC（Metric_ID=1/4）：Step 1 筛选 `is_new_vic = 1`
   - Retention VIC（Metric_ID=23/26）：Step 1 筛选 `is_retention_vic = 1`
   - SLS% 分母集合 Step 1 用 `is_xxx_vic IN {0, 1}` 全客筛选（New VIC 用 is_new_vic，Retention VIC 用 is_retention_vic），与分子唯一区别是 Step 1 的筛选条件；Step 2 均不再施加 is_xxx_vic
   - 每个度量值 VICType 固定，Step 1 直接 CALCULATETABLE 框定，无需主表的 UNION+FILTER 分支（主表因单个度量值动态路由 VICType 才需要）
5. **货币转换**：

   - 金额类（SLS Act，Metric_ID=1/23）÷ Currency_ExchangeRate（RMB=1, USD=7）
   - 比率类（SLS% Act，Metric_ID=4/26）不除（分子分母同币种抵消，SLS% 占比不除）
   - 货币符号从 Slicer_Currency_Selection[Currency_Symbol] 读取（默认 "¥"，USD 时为 "$"）
6. **currency_k 格式**：SLS 金额除以 1000 后保留整数，拼接货币符号 + "k"。例如 ¥1234 → "¥1k"，$5678 → "$6k"。若未来需要更精细的小数位，可调整 FORMAT 串为 "#,##0.0" 等。
7. **percent_0dp 格式**：SLS% 为比率（0~1），FORMAT "0%" 不保留小数。例如 0.4567 → "46%"。若未来需要小数位，可调整为 "0.0%"。
8. **is_member / is_employee 双重筛选**：与 VIC_Breakdown_ms.md 主表口径一致，默认 is_member=0（TTL VIC）、is_employee=1（Yes）。
9. **口径等价性（Step1+Step2 分步，2026-09-12 修订）**：本方案 4 个 Value 度量与 VIC_Breakdown_ms.md 主表 Metric_ID=1/4/23/26 的 Act 分步口径一致（Step 1 end period 当月框定集合 + Step 2 时间范围 TREATAS 聚合，分母集合与分子唯一区别是 Step 1 筛选条件），差异仅在于两套区间的读取来源（主表从 Slicer_Time_Frame_Max_VIC_Breakdown 读取切片器所选范围的两套区间；本方案从 Slicer_Time_Frame_VIC_Breakdown 读取 X 轴当前时间点的两套区间 + 全局冗余筛选）。各 Value 度量末尾保留旧逻辑（end period 当月单步聚合版本）块注释，如需回退按块内说明恢复即可。
10. **行维度自动传递**：柱形图若配置图例（platform / shop_info_id 等）或小多图，事实表分组字段由模型自动传递筛选上下文，DAX 无需显式处理。
