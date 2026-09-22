# Power BI 解决方案 — VIC Breakdown Trend：4 个指标 Value/Display 度量（柱形图趋势）

> status: 待模型验收
> created: 2026-08-15
> revised: 2026-09-21（仅修改会员筛选：两档事实 is_member=0，Member VIC 追加当前柱最后财月末注册上限；Month 行级、Quarter 分子两步及 SLS% 正金额全客分母等其他有效逻辑不变）
> type: 度量值开发 + 柱形图视觉对象
> 口径来源: 口径文档/VIC/VIC Breakdown KPI.md（Metric_ID 1/4/23/26 共 4 个指标）
> 参考实现: VIC_Trend.md（柱形图 X 轴 + IsTimeFrameVisible 范式）、VIC_Breakdown_ms.md（VIC Breakdown 主表口径）
> 底表: a03_e2e_customer_data_m

---

## 1. 需求理解

为 VIC Customer Dashboard 的 VIC Breakdown Trend 柱形图输出 4 个指标的独立 Value + Display 度量对：

| Metric_ID | 指标                     | VICType       | 类型       | 计算方式                                                                                                                             | 格式        |
| --------- | ------------------------ | ------------- | ---------- | ------------------------------------------------------------------------------------------------------------------------------------ | ----------- |
| 1         | SLS Act (New VIC)        | New VIC       | 金额类 Act | Month：当月 is_new_vic=1 行汇总；Quarter：季末月框定 New VIC 用户后汇总整季；结果 ÷ FXRate | currency_k  |
| 4         | SLS% Act (New VIC)       | New VIC       | 比率类 Act | 分子采用 New VIC 月/季分支；分母为当前柱期间 net_pay_amt > 0 行汇总；DIVIDE(分子, 分母) | percent_0dp |
| 23        | SLS Act (Retention VIC)  | Retention VIC | 金额类 Act | Month：当月 is_retention_vic=1 行汇总；Quarter：季末月框定 Retention VIC 用户后汇总整季；结果 ÷ FXRate | currency_k  |
| 26        | SLS% Act (Retention VIC) | Retention VIC | 比率类 Act | 分子采用 Retention VIC 月/季分支；分母与 New VIC 相同，不施加 VIC 标记或用户集合筛选 | percent_0dp |

**核心设计原则**：

- 每个指标独立输出 Value + Display 度量对，直接平铺，不拆基础层
- 度量值作用于柱形图，X 轴 = Slicer_Time_Frame_VIC_Breakdown[TimeFrame_Value]
- 配置 IsTimeFrameVisible VIC Breakdown 视觉对象级别筛选器，控制 X 轴显示范围
- 日期表使用 VIC Breakdown 专用版本（Slicer_Time_Frame_VIC_Breakdown / _Min_ / _Max_），与主表 VIC_Breakdown_ms.md 共用，但与其他模块（VIC KPI、VIC Trend、Pie Chart 等）隔离
- 按 X 轴真实粒度值 `Month` / `Quarter` 分支：Month 对当前月直接筛选 `is_xxx_vic=1`；Quarter 保留季末月识别用户、整季消费聚合两步，集合变量放在 Quarter 分支内部。
- SLS% 全客分母对齐主表当前有效 `__TTL_SLS`：月/季均在当前柱 TimeFrame 区间直接筛选 `net_pay_amt > 0` 后汇总，不框定用户、不添加任何 VIC 标记筛选；不能把正金额条件添加到 VIC 分子。
- 会员切片器 `0 = TTL VIC`、`1 = Member VIC`，无唯一选值默认 0；两档事实均筛选 `is_member=0`，仅 Member 追加 `register_date <= __CurrentLFMMax`，通过 `KEEPFILTERS` 与已有注册日期筛选取交集，TTL 不追加注册日期限制。
- `__CurrentLFMMax` 沿用 `SELECTEDVALUE(Slicer_Time_Frame_VIC_Breakdown[Last_Fiscal_Month_Max])`，即每根柱子的最后财月末，不使用全局 Max 或 `TimeFrame_Max` 替代；月分子、季度 Step 1 / Step 2、单步全客分母全部覆盖，不新增注册日期下限。
- 保留现有员工 `VALUES` + `IN` 筛选、平台/店铺等分组上下文、金额类 ÷ Currency_ExchangeRate；不移除整张事实表筛选。
- 本方案仅输出 Act 值（本期），不涉及 vs LY / vs LP / vs Store 派生指标

### 1.1 格式说明

| Metric_ID | 指标     | 原格式      | 新格式      | 格式串                                                       | 示例               |
| --------- | -------- | ----------- | ----------- | ------------------------------------------------------------ | ------------------ |
| 1, 23     | SLS Act  | currency    | currency_k  | `__CurrencySymbol & FORMAT(__Value / 1000, "#,##0") & "k"` | ¥1k / $5k / ¥12k |
| 4, 26     | SLS% Act | percent_0dp | percent_0dp | `FORMAT(__Value, "0%")`                                    | 45% / 62%          |

> **currency_k 格式说明**：将 SLS 金额（已按 FXRate 换算为 RMB 或 USD）除以 1000 后保留整数，拼接货币符号 + "k" 后缀。例如 ¥1234 → "¥1k"，$5678 → "$6k"。
> **percent_0dp 格式说明**：SLS% 为比率，FORMAT 为 0% 不保留小数。例如 0.4567 → "46%"。分子保留净额口径，可能为负，不额外裁剪到 0~1。

### 1.2 柱形图 X 轴与时间筛选范式（Month 行级 / Quarter 分步）

参考 VIC_Trend.md（及 PB_Location_Trend.md 子模块二 Fulfillment% Trend）+ 主表 VIC_Breakdown_ms.md 的分步口径（范式参考用户已验证的"新客"DAX，即 Customer Breakdown Trend 的 TREATAS 模式）：

- 柱形图 X 轴 = Slicer_Time_Frame_VIC_Breakdown[TimeFrame_Value]
- 视觉对象级别筛选器：IsTimeFrameVisible VIC Breakdown = 1（控制 X 轴显示范围：同粒度 + Key 在 [MinKey, MaxKey] 区间）
- `Month`：当前柱 `Last_Fiscal_Month_Min/Max` 与 `TimeFrame_Min/Max` 对应同一财月；按现有行级口径，直接在该月筛选 `is_xxx_vic=1` 汇总，不构建用户集合。
- `Quarter`：两步时间不同，保留原 VIC 计算结构：
  - **Step 1**：当前柱 `Last_Fiscal_Month_Min/Max`（季末财月）筛选 `is_xxx_vic=1`，框定 user_id。
  - **Step 2**：当前柱 `TimeFrame_Min/Max`（整季）通过 `TREATAS` 汇总该用户集合消费，不再次施加 VIC 标记。
- **SLS% 分母（月/季共用）**：当前柱 `TimeFrame_Min/Max` 内直接汇总 `net_pay_amt > 0` 行；不施加 VIC 标记、不框定全客用户集合。
- 月分子、季度 Step 2 及分母均保留全局 Min/Max 日期范围；季度 Step 1 保留原季末月范围。未知粒度或粒度非单值时返回 BLANK。
- **Month 行级范围**：同一用户跨店 VIC 标记不同时，仅汇总标记为 1 的行，不通过用户集合扩展到其他店的未标记行。

---

## 2. 现状分析

### 2.1 数据底表

| 对象     | 名称                                                                                  | 出处              |
| -------- | ------------------------------------------------------------------------------------- | ----------------- |
| 事实表   | a03_e2e_customer_data_m                                                               | 口径文档 全局逻辑 |
| 关键字段 | data_date, user_id, net_pay_amt, is_member, register_date, is_employee, is_new_vic, is_retention_vic | 口径文档 |
| 注册日期 | register_date（源为 String，模型须与财月末字段统一转换为 Date） | Member VIC 的当前柱财月末注册上限；不新增下限或非空条件 |

### 2.2 维度表清单（VIC Breakdown 专用日期表，与其他模块隔离）

| 维度表                              | 类型     | 连接方式                                                                                                                                                                                     |
| ----------------------------------- | -------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Slicer_Time_Frame_VIC_Breakdown     | 断开维度 | 柱形图 X 轴；SELECTEDVALUE 读取 TimeFrame_ID/Key/Value、Last_Fiscal_Month_Min/Max（Step 1：X 轴每个时间点的 end period 当月区间）、TimeFrame_Min/Max（Step 2：X 轴每个时间点自身的时间范围） |
| Slicer_Time_Frame_Max_VIC_Breakdown | 断开维度 | 结束切片器；SELECTEDVALUE 读取 TimeFrame_Max（全局范围上界）                                                                                                                                 |
| Slicer_Time_Frame_Min_VIC_Breakdown | 断开维度 | 起始切片器；SELECTEDVALUE 读取 TimeFrame_Min（全局范围下界）                                                                                                                                 |
| Slicer_Is_Employee_Selection        | 断开维度 | VALUES 读取当前可见 IsEmployee_Code 集合，通过 IN 筛选；无显式筛选时使用当前可见全部值 |
| IsMemberFilter                      | 断开维度 | SELECTEDVALUE 读取 IsMember（默认 0 = TTL VIC）                                                                                                                                              |
| Slicer_Currency_Selection           | 断开维度 | SELECTEDVALUE 读取 Currency_ExchangeRate（默认 1）、Currency_Symbol（默认 "¥"）                                                                                                             |

> **日期表结构**：Slicer_Time_Frame_VIC_Breakdown 含 Last_Fiscal_Month_Min/Max 字段（与 Slicer_Time_Frame_Max_VIC_Breakdown 同源 SQL，通过自关联 dim_t00_bi_fiscal_calendar 得到每个时间点的 end period 当月区间）及 TimeFrame_Min/Max 字段（每个时间点自身的时间范围），两套区间同表内置，Step 1 / Step 2 分步直接读取，无需改动日期表。TimeFrame_ID 筛选为 Month / Quarter。

---

## 3. 方案设计

### 3.1 筛选上下文

| 筛选器                                                         | 作用方式                                                   | DAX 处理                                                                                                               |
| -------------------------------------------------------------- | ---------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------- |
| Slicer_Time_Frame_VIC_Breakdown（X 轴粒度） | SELECTEDVALUE 读取 TimeFrame_ID | `Month`：行级筛选；`Quarter`：VIC 分子分步；其他返回 BLANK |
| Slicer_Time_Frame_VIC_Breakdown（Quarter Step 1） | 断开维度，读取 Last_Fiscal_Month_Min/Max | 季末月 `is_xxx_vic = 1` 框定 VIC 用户，仅用于 Quarter 分子 |
| Slicer_Time_Frame_VIC_Breakdown（当前柱期间） | 读取 TimeFrame_Min/Max | Month 分子行筛选、Quarter Step 2 TREATAS 聚合、月/季全客分母正金额行汇总 |
| Slicer_Time_Frame_Min/Max_VIC_Breakdown（全局范围） | 月分子、Quarter Step 2 及分母的冗余保护 | `data_date >= __GlobalMin AND data_date <= __GlobalMax` |
| Slicer_Is_Employee_Selection | VALUES 读取当前可见 IsEmployee_Code 集合 | `is_employee in __IsEmployeeFilter`；保持现有员工筛选行为，不设固定默认 1 |
| IsMemberFilter | SELECTEDVALUE 读取 IsMember，非单值默认 0 | 两档事实 `is_member=0`；0=TTL VIC 不追加注册限制，1=Member VIC 通过 `KEEPFILTERS` 追加 `register_date <= __CurrentLFMMax`，与已有注册筛选取交集 |
| Slicer_Currency_Selection                                      | SELECTEDVALUE 读取 Currency_ExchangeRate / Currency_Symbol | 金额类`DIVIDE(SUM(net_pay_amt), __FXRate)`；Display 拼接 `__CurrencySymbol`                                        |
| 事实表行维度字段（platform / shop_info_id / 新老客分层等）     | 柱形图图例/小多图直接拉取，模型自动传递                    | DAX 无需显式处理                                                                                                       |

**会员上下文与日期前提**：四个 Value 的会员筛选共 14 处（SLS New 3、SLS% New 4、SLS Retention 3、SLS% Retention 4），分别覆盖月分子、季度两步及 SLS% 全客分母。截止统一读取当前柱 `Last_Fiscal_Month_Max`；模型 `register_date` 与财月末字段须为 Date，当前柱日期须为有效单值。仅追加注册日期上限，原数据日期范围、员工/分组、FX、FORMAT、可见性和 Display 逻辑不变；BLANK / SQL NULL 差异单列于 §7。

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
// 口径来源: 口径文档/VIC/VIC Breakdown KPI.md - Metric_ID=1 SLS Act (New VIC)
//           （现行口径：Month 行级；Quarter VIC 分子分步；SLS% 为当前柱正金额全客分母）
// 计算公式（按 X 轴 TimeFrame_ID 分支，两个分支均返回数值）:
//   Month: 当前柱月份直接筛选 is_xxx_vic=1 后 SUM(net_pay_amt)，不框定 user_id 集合
//   Quarter: 沿用以下 Step1+Step2 分步；集合变量仅在 Quarter 分支内部定义
//   Step 1（X 轴时间点 end period 当月框定集合）: data_date ∈ [Last_Fiscal_Month_Min, Last_Fiscal_Month_Max]，
//          筛选 is_new_vic = 1，框定 user_id 集合
//   Step 2（X 轴时间点自身时间范围聚合）: data_date ∈ [TimeFrame_Min, TimeFrame_Max]，
//          TREATAS 传递 Step 1 集合 SUM(net_pay_amt)，is_new_vic=1 不再施加
//          （另加全局范围冗余筛选，防止 X 轴超出全局范围时的异常显示）
//   结果 ÷ FXRate
// 筛选条件:
//   - 会员模式 0=TTL VIC、1=Member VIC，非单值默认 0；两档事实 is_member=0
//   - 仅 Member 通过 KEEPFILTERS 追加 register_date <= __CurrentLFMMax，与已有注册筛选取交集
//   - __CurrentLFMMax 取当前柱 Last_Fiscal_Month_Max，不是全局 Max 或 TimeFrame_Max
//   - 月分子、Quarter Step 1 / Step 2 及 SLS% 全客分母均应用会员规则，不新增注册下限或排空
//   - is_employee in __IsEmployeeFilter：VALUES 当前可见员工集合，各事实筛选阶段保持不变
// 货币转换: 金额类 ÷ Currency_ExchangeRate（RMB=1, USD=7）
// Metric_ID: 1
// 数据类型: currency（内部值，未格式化）
// ========================================
    // ── X 轴当前柱粒度：Month / Quarter；其他或非单值上下文返回 BLANK ──
    VAR __CurrentTimeFrameID = SELECTEDVALUE(Slicer_Time_Frame_VIC_Breakdown[TimeFrame_ID])
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

    // ── 按粒度计算原币 SLS；Month 分支不引用用户集合 ──
    VAR __RawSLS =
        SWITCH(
            __CurrentTimeFrameID,
            "Month",
                CALCULATE(
                    SUM('a03_e2e_customer_data_m'[net_pay_amt]),
                    'a03_e2e_customer_data_m'[is_new_vic] = 1,
                    'a03_e2e_customer_data_m'[is_member] = 0,
                    KEEPFILTERS(__IsMemberFilter = 0 || 'a03_e2e_customer_data_m'[register_date] <= __CurrentLFMMax),
                    'a03_e2e_customer_data_m'[is_employee] in __IsEmployeeFilter,
                    'a03_e2e_customer_data_m'[data_date] >= __GlobalMin,
                    'a03_e2e_customer_data_m'[data_date] <= __GlobalMax,
                    'a03_e2e_customer_data_m'[data_date] >= __CurrentTFMin,
                    'a03_e2e_customer_data_m'[data_date] <= __CurrentTFMax
                ),
            "Quarter",
                // Step 1：季末财月识别 New VIC，仅季度分支构建集合
                VAR __VICUsers =
                    CALCULATETABLE(
                        VALUES('a03_e2e_customer_data_m'[user_id]),
                        'a03_e2e_customer_data_m'[is_new_vic] = 1,
                        'a03_e2e_customer_data_m'[is_member] = 0,
                        KEEPFILTERS(__IsMemberFilter = 0 || 'a03_e2e_customer_data_m'[register_date] <= __CurrentLFMMax),
                        'a03_e2e_customer_data_m'[is_employee] in __IsEmployeeFilter,
                        'a03_e2e_customer_data_m'[data_date] >= __CurrentLFMMin,
                        'a03_e2e_customer_data_m'[data_date] <= __CurrentLFMMax
                    )
                RETURN
                    // Step 2：集合在当前整季消费，不再次施加 VIC 标记
                    CALCULATE(
                        SUM('a03_e2e_customer_data_m'[net_pay_amt]),
                        TREATAS(__VICUsers, 'a03_e2e_customer_data_m'[user_id]),
                        'a03_e2e_customer_data_m'[is_member] = 0,
                        KEEPFILTERS(__IsMemberFilter = 0 || 'a03_e2e_customer_data_m'[register_date] <= __CurrentLFMMax),
                        'a03_e2e_customer_data_m'[is_employee] in __IsEmployeeFilter,
                        'a03_e2e_customer_data_m'[data_date] >= __GlobalMin,
                        'a03_e2e_customer_data_m'[data_date] <= __GlobalMax,
                        'a03_e2e_customer_data_m'[data_date] >= __CurrentTFMin,
                        'a03_e2e_customer_data_m'[data_date] <= __CurrentTFMax
                    ),
            BLANK()
        )
    RETURN DIVIDE(__RawSLS, __FXRate)
    // Month：行筛选；Quarter：两步；未识别粒度：BLANK；分组上下文始终保留。
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
// 口径来源: 口径文档/VIC/VIC Breakdown KPI.md - Metric_ID=4 SLS% Act (New VIC)
//           （现行口径：Month 行级；Quarter VIC 分子分步；SLS% 为当前柱正金额全客分母）
// 计算公式: DIVIDE(分子, 分母):
//   Month 分子: 当前柱月份直接筛选 is_new_vic=1 后 SUM(net_pay_amt)
//   Quarter 分子: 季末月筛选 is_new_vic=1 框定用户，再 TREATAS 汇总整季（不再次筛选 VIC 标记）
//   分母（月/季统一）: 当前柱 TimeFrame 区间直接筛选 net_pay_amt > 0 后 SUM(net_pay_amt)
//   分母不框定用户集合、不施加 VIC 标记筛选；分子不添加 net_pay_amt > 0
//   月分子、季度 Step 2 和分母均保留全局范围及分组维度筛选
// 筛选条件:
//   - 会员模式 0=TTL VIC、1=Member VIC，非单值默认 0；两档事实 is_member=0
//   - 仅 Member 通过 KEEPFILTERS 追加 register_date <= __CurrentLFMMax，与已有注册筛选取交集
//   - __CurrentLFMMax 取当前柱 Last_Fiscal_Month_Max，不是全局 Max 或 TimeFrame_Max
//   - 月分子、Quarter Step 1 / Step 2 及 SLS% 全客分母均应用会员规则，不新增注册下限或排空
//   - is_employee in __IsEmployeeFilter：VALUES 当前可见员工集合，各事实筛选阶段保持不变
// 货币转换: SLS% 占比不除（分子分母同币种抵消）
// Metric_ID: 4
// 数据类型: percent_0dp（比率，不额外裁剪净额结果）
// ========================================
    // ── X 轴当前柱粒度：Month / Quarter；其他或非单值上下文返回 BLANK ──
    VAR __CurrentTimeFrameID = SELECTEDVALUE(Slicer_Time_Frame_VIC_Breakdown[TimeFrame_ID])
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

    // ── 分子：Month 行级筛选；Quarter 季末主体 + 整季消费 ──
    VAR __Numerator =
        SWITCH(
            __CurrentTimeFrameID,
            "Month",
                CALCULATE(
                    SUM('a03_e2e_customer_data_m'[net_pay_amt]),
                    'a03_e2e_customer_data_m'[is_new_vic] = 1,
                    'a03_e2e_customer_data_m'[is_member] = 0,
                    KEEPFILTERS(__IsMemberFilter = 0 || 'a03_e2e_customer_data_m'[register_date] <= __CurrentLFMMax),
                    'a03_e2e_customer_data_m'[is_employee] in __IsEmployeeFilter,
                    'a03_e2e_customer_data_m'[data_date] >= __GlobalMin,
                    'a03_e2e_customer_data_m'[data_date] <= __GlobalMax,
                    'a03_e2e_customer_data_m'[data_date] >= __CurrentTFMin,
                    'a03_e2e_customer_data_m'[data_date] <= __CurrentTFMax
                ),
            "Quarter",
                VAR __VICUsers =
                    CALCULATETABLE(
                        VALUES('a03_e2e_customer_data_m'[user_id]),
                        'a03_e2e_customer_data_m'[is_new_vic] = 1,
                        'a03_e2e_customer_data_m'[is_member] = 0,
                        KEEPFILTERS(__IsMemberFilter = 0 || 'a03_e2e_customer_data_m'[register_date] <= __CurrentLFMMax),
                        'a03_e2e_customer_data_m'[is_employee] in __IsEmployeeFilter,
                        'a03_e2e_customer_data_m'[data_date] >= __CurrentLFMMin,
                        'a03_e2e_customer_data_m'[data_date] <= __CurrentLFMMax
                    )
                RETURN
                    CALCULATE(
                        SUM('a03_e2e_customer_data_m'[net_pay_amt]),
                        TREATAS(__VICUsers, 'a03_e2e_customer_data_m'[user_id]),
                        'a03_e2e_customer_data_m'[is_member] = 0,
                        KEEPFILTERS(__IsMemberFilter = 0 || 'a03_e2e_customer_data_m'[register_date] <= __CurrentLFMMax),
                        'a03_e2e_customer_data_m'[is_employee] in __IsEmployeeFilter,
                        'a03_e2e_customer_data_m'[data_date] >= __GlobalMin,
                        'a03_e2e_customer_data_m'[data_date] <= __GlobalMax,
                        'a03_e2e_customer_data_m'[data_date] >= __CurrentTFMin,
                        'a03_e2e_customer_data_m'[data_date] <= __CurrentTFMax
                    ),
            BLANK()
        )
    // ── 分母：月/季均为当前柱期间内正金额行，不框定用户、不添加 VIC 标记 ──
    VAR __Denominator =
        CALCULATE(
            SUM('a03_e2e_customer_data_m'[net_pay_amt]),
            'a03_e2e_customer_data_m'[net_pay_amt] > 0,
            'a03_e2e_customer_data_m'[is_member] = 0,
            KEEPFILTERS(__IsMemberFilter = 0 || 'a03_e2e_customer_data_m'[register_date] <= __CurrentLFMMax),
            'a03_e2e_customer_data_m'[is_employee] in __IsEmployeeFilter,
            'a03_e2e_customer_data_m'[data_date] >= __GlobalMin,
            'a03_e2e_customer_data_m'[data_date] <= __GlobalMax,
            'a03_e2e_customer_data_m'[data_date] >= __CurrentTFMin,
            'a03_e2e_customer_data_m'[data_date] <= __CurrentTFMax
        )
    RETURN DIVIDE(__Numerator, __Denominator)
    // Month/Quarter 共用全客分母；其他粒度或分母为 0/BLANK 时返回 BLANK。
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
// 口径来源: 口径文档/VIC/VIC Breakdown KPI.md - Metric_ID=23 SLS Act (Retention VIC)
//           （现行口径：Month 行级；Quarter VIC 分子分步；SLS% 为当前柱正金额全客分母）
// 计算公式（按 X 轴 TimeFrame_ID 分支，两个分支均返回数值）:
//   Month: 当前柱月份直接筛选 is_xxx_vic=1 后 SUM(net_pay_amt)，不框定 user_id 集合
//   Quarter: 沿用以下 Step1+Step2 分步；集合变量仅在 Quarter 分支内部定义
//   Step 1（X 轴时间点 end period 当月框定集合）: data_date ∈ [Last_Fiscal_Month_Min, Last_Fiscal_Month_Max]，
//          筛选 is_retention_vic = 1，框定 user_id 集合
//   Step 2（X 轴时间点自身时间范围聚合）: data_date ∈ [TimeFrame_Min, TimeFrame_Max]，
//          TREATAS 传递 Step 1 集合 SUM(net_pay_amt)，is_retention_vic=1 不再施加
//          （另加全局范围冗余筛选，防止 X 轴超出全局范围时的异常显示）
//   结果 ÷ FXRate
// 筛选条件:
//   - 会员模式 0=TTL VIC、1=Member VIC，非单值默认 0；两档事实 is_member=0
//   - 仅 Member 通过 KEEPFILTERS 追加 register_date <= __CurrentLFMMax，与已有注册筛选取交集
//   - __CurrentLFMMax 取当前柱 Last_Fiscal_Month_Max，不是全局 Max 或 TimeFrame_Max
//   - 月分子、Quarter Step 1 / Step 2 及 SLS% 全客分母均应用会员规则，不新增注册下限或排空
//   - is_employee in __IsEmployeeFilter：VALUES 当前可见员工集合，各事实筛选阶段保持不变
// 货币转换: 金额类 ÷ Currency_ExchangeRate（RMB=1, USD=7）
// Metric_ID: 23
// 数据类型: currency（内部值，未格式化）
// ========================================
    // ── X 轴当前柱粒度：Month / Quarter；其他或非单值上下文返回 BLANK ──
    VAR __CurrentTimeFrameID = SELECTEDVALUE(Slicer_Time_Frame_VIC_Breakdown[TimeFrame_ID])
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

    // ── 按粒度计算原币 SLS；Month 分支不引用用户集合 ──
    VAR __RawSLS =
        SWITCH(
            __CurrentTimeFrameID,
            "Month",
                CALCULATE(
                    SUM('a03_e2e_customer_data_m'[net_pay_amt]),
                    'a03_e2e_customer_data_m'[is_retention_vic] = 1,
                    'a03_e2e_customer_data_m'[is_member] = 0,
                    KEEPFILTERS(__IsMemberFilter = 0 || 'a03_e2e_customer_data_m'[register_date] <= __CurrentLFMMax),
                    'a03_e2e_customer_data_m'[is_employee] in __IsEmployeeFilter,
                    'a03_e2e_customer_data_m'[data_date] >= __GlobalMin,
                    'a03_e2e_customer_data_m'[data_date] <= __GlobalMax,
                    'a03_e2e_customer_data_m'[data_date] >= __CurrentTFMin,
                    'a03_e2e_customer_data_m'[data_date] <= __CurrentTFMax
                ),
            "Quarter",
                // Step 1：季末财月识别 Retention VIC，仅季度分支构建集合
                VAR __VICUsers =
                    CALCULATETABLE(
                        VALUES('a03_e2e_customer_data_m'[user_id]),
                        'a03_e2e_customer_data_m'[is_retention_vic] = 1,
                        'a03_e2e_customer_data_m'[is_member] = 0,
                        KEEPFILTERS(__IsMemberFilter = 0 || 'a03_e2e_customer_data_m'[register_date] <= __CurrentLFMMax),
                        'a03_e2e_customer_data_m'[is_employee] in __IsEmployeeFilter,
                        'a03_e2e_customer_data_m'[data_date] >= __CurrentLFMMin,
                        'a03_e2e_customer_data_m'[data_date] <= __CurrentLFMMax
                    )
                RETURN
                    // Step 2：集合在当前整季消费，不再次施加 VIC 标记
                    CALCULATE(
                        SUM('a03_e2e_customer_data_m'[net_pay_amt]),
                        TREATAS(__VICUsers, 'a03_e2e_customer_data_m'[user_id]),
                        'a03_e2e_customer_data_m'[is_member] = 0,
                        KEEPFILTERS(__IsMemberFilter = 0 || 'a03_e2e_customer_data_m'[register_date] <= __CurrentLFMMax),
                        'a03_e2e_customer_data_m'[is_employee] in __IsEmployeeFilter,
                        'a03_e2e_customer_data_m'[data_date] >= __GlobalMin,
                        'a03_e2e_customer_data_m'[data_date] <= __GlobalMax,
                        'a03_e2e_customer_data_m'[data_date] >= __CurrentTFMin,
                        'a03_e2e_customer_data_m'[data_date] <= __CurrentTFMax
                    ),
            BLANK()
        )
    RETURN DIVIDE(__RawSLS, __FXRate)
    // Month：行筛选；Quarter：两步；未识别粒度：BLANK；分组上下文始终保留。
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
// 口径来源: 口径文档/VIC/VIC Breakdown KPI.md - Metric_ID=26 SLS% Act (Retention VIC)
//           （现行口径：Month 行级；Quarter VIC 分子分步；SLS% 为当前柱正金额全客分母）
// 计算公式: DIVIDE(分子, 分母):
//   Month 分子: 当前柱月份直接筛选 is_retention_vic=1 后 SUM(net_pay_amt)
//   Quarter 分子: 季末月筛选 is_retention_vic=1 框定用户，再 TREATAS 汇总整季（不再次筛选 VIC 标记）
//   分母（月/季统一）: 当前柱 TimeFrame 区间直接筛选 net_pay_amt > 0 后 SUM(net_pay_amt)
//   分母不框定用户集合、不施加 VIC 标记筛选；分子不添加 net_pay_amt > 0
//   月分子、季度 Step 2 和分母均保留全局范围及分组维度筛选
// 筛选条件:
//   - 会员模式 0=TTL VIC、1=Member VIC，非单值默认 0；两档事实 is_member=0
//   - 仅 Member 通过 KEEPFILTERS 追加 register_date <= __CurrentLFMMax，与已有注册筛选取交集
//   - __CurrentLFMMax 取当前柱 Last_Fiscal_Month_Max，不是全局 Max 或 TimeFrame_Max
//   - 月分子、Quarter Step 1 / Step 2 及 SLS% 全客分母均应用会员规则，不新增注册下限或排空
//   - is_employee in __IsEmployeeFilter：VALUES 当前可见员工集合，各事实筛选阶段保持不变
// 货币转换: SLS% 占比不除（分子分母同币种抵消）
// Metric_ID: 26
// 数据类型: percent_0dp（比率，不额外裁剪净额结果）
// ========================================
    // ── X 轴当前柱粒度：Month / Quarter；其他或非单值上下文返回 BLANK ──
    VAR __CurrentTimeFrameID = SELECTEDVALUE(Slicer_Time_Frame_VIC_Breakdown[TimeFrame_ID])
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

    // ── 分子：Month 行级筛选；Quarter 季末主体 + 整季消费 ──
    VAR __Numerator =
        SWITCH(
            __CurrentTimeFrameID,
            "Month",
                CALCULATE(
                    SUM('a03_e2e_customer_data_m'[net_pay_amt]),
                    'a03_e2e_customer_data_m'[is_retention_vic] = 1,
                    'a03_e2e_customer_data_m'[is_member] = 0,
                    KEEPFILTERS(__IsMemberFilter = 0 || 'a03_e2e_customer_data_m'[register_date] <= __CurrentLFMMax),
                    'a03_e2e_customer_data_m'[is_employee] in __IsEmployeeFilter,
                    'a03_e2e_customer_data_m'[data_date] >= __GlobalMin,
                    'a03_e2e_customer_data_m'[data_date] <= __GlobalMax,
                    'a03_e2e_customer_data_m'[data_date] >= __CurrentTFMin,
                    'a03_e2e_customer_data_m'[data_date] <= __CurrentTFMax
                ),
            "Quarter",
                VAR __VICUsers =
                    CALCULATETABLE(
                        VALUES('a03_e2e_customer_data_m'[user_id]),
                        'a03_e2e_customer_data_m'[is_retention_vic] = 1,
                        'a03_e2e_customer_data_m'[is_member] = 0,
                        KEEPFILTERS(__IsMemberFilter = 0 || 'a03_e2e_customer_data_m'[register_date] <= __CurrentLFMMax),
                        'a03_e2e_customer_data_m'[is_employee] in __IsEmployeeFilter,
                        'a03_e2e_customer_data_m'[data_date] >= __CurrentLFMMin,
                        'a03_e2e_customer_data_m'[data_date] <= __CurrentLFMMax
                    )
                RETURN
                    CALCULATE(
                        SUM('a03_e2e_customer_data_m'[net_pay_amt]),
                        TREATAS(__VICUsers, 'a03_e2e_customer_data_m'[user_id]),
                        'a03_e2e_customer_data_m'[is_member] = 0,
                        KEEPFILTERS(__IsMemberFilter = 0 || 'a03_e2e_customer_data_m'[register_date] <= __CurrentLFMMax),
                        'a03_e2e_customer_data_m'[is_employee] in __IsEmployeeFilter,
                        'a03_e2e_customer_data_m'[data_date] >= __GlobalMin,
                        'a03_e2e_customer_data_m'[data_date] <= __GlobalMax,
                        'a03_e2e_customer_data_m'[data_date] >= __CurrentTFMin,
                        'a03_e2e_customer_data_m'[data_date] <= __CurrentTFMax
                    ),
            BLANK()
        )
    // ── 分母：月/季均为当前柱期间内正金额行，不框定用户、不添加 VIC 标记 ──
    VAR __Denominator =
        CALCULATE(
            SUM('a03_e2e_customer_data_m'[net_pay_amt]),
            'a03_e2e_customer_data_m'[net_pay_amt] > 0,
            'a03_e2e_customer_data_m'[is_member] = 0,
            KEEPFILTERS(__IsMemberFilter = 0 || 'a03_e2e_customer_data_m'[register_date] <= __CurrentLFMMax),
            'a03_e2e_customer_data_m'[is_employee] in __IsEmployeeFilter,
            'a03_e2e_customer_data_m'[data_date] >= __GlobalMin,
            'a03_e2e_customer_data_m'[data_date] <= __GlobalMax,
            'a03_e2e_customer_data_m'[data_date] >= __CurrentTFMin,
            'a03_e2e_customer_data_m'[data_date] <= __CurrentTFMax
        )
    RETURN DIVIDE(__Numerator, __Denominator)
    // Month/Quarter 共用全客分母；其他粒度或分母为 0/BLANK 时返回 BLANK。
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

以下为**待执行的参数化 SQL 测试模板**，不是已运行验证结果。执行前替换 `${...}`：

- `CurrentTFMin/Max` 为当前柱财历期间，`CurrentLFMMin/Max` 为该柱最后财月区间（月柱为当月，季柱为季末财月），`GlobalMin/Max` 为起止切片器范围；原数据日期条件保持不变。
- 注册截止参数 `CurrentLFMMax` 必须取当前柱 `Slicer_Time_Frame_VIC_Breakdown[Last_Fiscal_Month_Max]` 的实际单值，与 DAX `__CurrentLFMMax` 一致，不取全局 Max、不用 `TimeFrame_Max` 替代，不把财月标签当自然月。
- `IsMemberMode` 为会员模式（0=TTL VIC，1=Member VIC；无唯一选值按 DAX 默认 0），不是事实表标记；事实表始终 `is_member=0`。`IsEmployeeList` 为当前可见员工集合，`FXRate` 对应当前币种。
- 源 `register_date` 为 String，不假定 SQL 字段已为 Date。模板用 `CAST(register_date AS DATE)` 与日期截止比较；执行前须按实际 SQL 引擎、源字符串格式及模型转换规则确认/适配日期转换表达式。不得默认字符串比较等价，也不得擅自把无效日期转成默认日期。
- 平台、店铺及已有注册日期筛选等报表上下文，需一致追加到每个事实表查询的 WHERE，与会员注册上限取交集。Month 的 `period_data` 覆盖分子/分母；Quarter 的 `vic_users` 覆盖 Step 1，`period_data` 覆盖 Step 2 主查询及单步全客分母。

**BLANK / NULL 差异（单独验收）**：模型 DAX 日期比较可能纳入 BLANK 注册日期；SQL 的 NULL 日期比较在 Member 模式下为 UNKNOWN，会被 WHERE 排除。TTL 模式的 OR 左支为真，不因新增注册上限排除空日期。空值样本须单独核对，不能直接把 SQL 与 DAX 的差异判为计算错误；未获业务授权，不新增排空、`COALESCE`、默认日期或其他空值补偿来改变现有 DAX。

### 7.1 Month 验证 SQL（New VIC SLS / SLS% 行级筛选）

```sql
WITH period_data AS (
    SELECT net_pay_amt, is_new_vic
    FROM a03_e2e_customer_data_m
    WHERE data_date BETWEEN '${CurrentTFMin}' AND '${CurrentTFMax}'
      AND data_date BETWEEN '${GlobalMin}' AND '${GlobalMax}'
      AND is_member = 0
      AND (${IsMemberMode} = 0 OR CAST(register_date AS DATE) <= CAST('${CurrentLFMMax}' AS DATE))
      AND is_employee IN (${IsEmployeeList})
), totals AS (
    SELECT
        SUM(CASE WHEN is_new_vic = 1 THEN net_pay_amt END) AS numerator,
        SUM(CASE WHEN net_pay_amt > 0 THEN net_pay_amt END) AS denominator
    FROM period_data
)
SELECT
    numerator / NULLIF(${FXRate}, 0) AS sls_value,
    numerator,
    denominator,
    numerator * 1.0 / NULLIF(denominator, 0) AS sls_pct
FROM totals;
```

Retention VIC 的 Month 验证只需将此模板的 `is_new_vic` 替换为 `is_retention_vic`，全客分母不变。

### 7.2 Quarter 验证 SQL（VIC 分子分步 / 全客分母单步）

```sql
WITH vic_users AS (
    SELECT DISTINCT user_id
    FROM a03_e2e_customer_data_m
    WHERE data_date BETWEEN '${CurrentLFMMin}' AND '${CurrentLFMMax}'
      AND is_new_vic = 1
      AND is_member = 0
      AND (${IsMemberMode} = 0 OR CAST(register_date AS DATE) <= CAST('${CurrentLFMMax}' AS DATE))
      AND is_employee IN (${IsEmployeeList})
), period_data AS (
    SELECT user_id, net_pay_amt
    FROM a03_e2e_customer_data_m
    WHERE data_date BETWEEN '${CurrentTFMin}' AND '${CurrentTFMax}'
      AND data_date BETWEEN '${GlobalMin}' AND '${GlobalMax}'
      AND is_member = 0
      AND (${IsMemberMode} = 0 OR CAST(register_date AS DATE) <= CAST('${CurrentLFMMax}' AS DATE))
      AND is_employee IN (${IsEmployeeList})
), numerator AS (
    SELECT SUM(f.net_pay_amt) AS amt
    FROM period_data f
    JOIN vic_users u ON f.user_id = u.user_id
), denominator AS (
    SELECT SUM(net_pay_amt) AS amt
    FROM period_data
    WHERE net_pay_amt > 0
)
SELECT
    n.amt / NULLIF(${FXRate}, 0) AS sls_value,
    n.amt AS numerator,
    d.amt AS denominator,
    n.amt * 1.0 / NULLIF(d.amt, 0) AS sls_pct
FROM numerator n CROSS JOIN denominator d;
```

Retention VIC 的 Quarter 验证只替换 Step 1 的 VIC 标记；Step 2 不再施加标记，分母不依赖 New / Retention 类型。

### 7.3 待执行验收

| 场景 | 预期结果 |
| --- | --- |
| Month，单店/多店，New 与 Retention | 非空有效日期样本按 §7.1 行级 SQL 对账；空值按前述差异单独核对；分母相同，不受度量中的 VIC 类型选择影响 |
| 同一用户同月 A 店标记为 1、B 店为 0 | Month 仅汇总标记为 1 的行，不扩展到 B 店未标记行 |
| Quarter，用户只在季末月标记为 1 | 分子包含该用户整季消费，不局限季末月，也不要求之前月份标记为 1 |
| 当季有正消费、季末月无记录的非 VIC 用户 | 满足会员和现有上下文时，消费计入 SLS% 全客分母，无须期末用户集合 |
| 净额为负的 VIC 记录 | 分子保留该净额；分母只汇总正金额行 |
| 分母为 0 / BLANK、粒度非单值或不支持 | 返回 BLANK；Display 沿用原有空值显示 |
| 会员模式 0 / 无唯一选值 | 事实均筛选 is_member=0；不追加注册限制，已有注册筛选仍保留 |
| 会员模式 1，注册日期早于/等于/晚于当前柱财月末 | 在其他条件满足时，早于或等于可纳入，晚于排除；不切换事实 is_member=1 |
| 多根柱子，全局结束晚于当前柱财月末 | 各柱分别用自身 Last_Fiscal_Month_Max，不以全局截止提前纳入后注册记录 |
| Quarter 两步及全客分母覆盖 | 季末框定与整季消费均需满足当前柱注册上限；Step 2 不因用户已入集合而豁免逐行会员筛选，分母也应用同一上限 |
| 已有更窄注册日期筛选 | KEEPFILTERS 取交集，不扩大既有筛选范围 |
| BLANK 注册日期 / SQL NULL | 按 §7 的差异单独核对，不擅自增添排空或 COALESCE |
| 切换员工、平台/店铺、币种 | 员工沿用 VALUES + IN 当前可见集合；保留分组上下文；SLS 按汇率换算，SLS% 不随币种改变 |

- 静态验收：相对 HEAD 去除注释与空白，将新增会员谓词还原后，四个 Value 的其余有效代码应完全一致；四个 Display 和 IsTimeFrameVisible 应完全不变。会员覆盖应为 3/4/3/4 共 14 处，SQL 三处事实查询均覆盖会员模式。
- 本次仅做文本修改与只读静态验收，未执行真实数据 SQL、Power BI 引擎计算或耗时基准测试；上表均为待执行预期。

---

## 8. 注意事项

1. **日期表共用**：本方案与 VIC_Breakdown_ms.md 主表共用 Slicer_Time_Frame_VIC_Breakdown / _Min_ / _Max_ 三张专用日期表，但与其他模块（VIC KPI、VIC Trend、Pie Chart 等）隔离。柱形图的 X 轴筛选与主表的切片器筛选互不影响（断开维度）。
2. **柱形图 X 轴筛选**：必须配置 [IsTimeFrameVisible VIC Breakdown] = 1 作为视觉对象级别筛选器，否则 X 轴会显示所有时间段（超出 Min/Max 选择范围）。逻辑与 VIC_Trend.md IsTimeFrameVisible VIC Trend 一致。
3. **按粒度分支**：`Month` 的 VIC 分子在当前柱 `TimeFrame_Min/Max` 内直接行筛选；`Quarter` 的 VIC 分子仍用 `Last_Fiscal_Month_Min/Max` 季末月框定用户，再在 `TimeFrame_Min/Max` 整季汇总。全局范围保留在月分子、季度 Step 2 及全客分母中，不扩大为所有柱子的全局累计。`SWITCH` 返回数值，不使用 IF 返回表；季度集合变量只定义在季度分支中。
4. **New VIC / Retention VIC 区分（关键逻辑）**：

   - New VIC（Metric_ID=1/4）：Month 行筛选或 Quarter Step 1 使用 `is_new_vic = 1`。
   - Retention VIC（Metric_ID=23/26）：Month 行筛选或 Quarter Step 1 使用 `is_retention_vic = 1`。
   - SLS% 分母月/季均直接汇总当前柱期间内 `net_pay_amt > 0` 行；不添加 VIC 标记、不框定全客用户集合。New / Retention 共用相同全客定义。
   - Quarter Step 2 不再次施加 VIC 标记；Month / Quarter 的 VIC 分子均不添加正金额限制。
   - 每个度量值 VICType 固定，季度 Step 1 直接 CALCULATETABLE 框定，无需主表动态路由 VICType 的 UNION+FILTER。
5. **货币转换**：

   - 金额类（SLS Act，Metric_ID=1/23）÷ Currency_ExchangeRate（RMB=1, USD=7）
   - 比率类（SLS% Act，Metric_ID=4/26）不除（分子分母同币种抵消，SLS% 占比不除）
   - 货币符号从 Slicer_Currency_Selection[Currency_Symbol] 读取（默认 "¥"，USD 时为 "$"）
6. **currency_k 格式**：SLS 金额除以 1000 后保留整数，拼接货币符号 + "k"。例如 ¥1234 → "¥1k"，$5678 → "$6k"。若未来需要更精细的小数位，可调整 FORMAT 串为 "#,##0.0" 等。
7. **percent_0dp 格式**：SLS% 为比率，FORMAT "0%" 不保留小数。例如 0.4567 → "46%"。分子保留净额，可能为负，不额外裁剪范围。若未来需要小数位，可调整为 "0.0%"。
8. **会员模式与员工筛选**：两档事实均为 `is_member=0`；Member 通过 `KEEPFILTERS` 追加当前柱财月末注册上限，TTL 不追加注册限制。会员无唯一选值默认 TTL；员工始终使用 `VALUES` + `IN` 当前可见集合，不设固定默认 Yes。日期转换与空值边界见 §3、§7。
9. **与主表的对齐边界**：主表 Metric_ID 4/26 的有效全客分母返回 `__TTL_SLS`。Trend 同样采用期间正金额行分母，Quarter VIC 分子为两步、Month 为行级筛选。主表聚合期间起点来自 Min 表、终点来自 Max 表；Trend 读取每个 X 轴时间点自身区间并保留全局日期保护，会员截止只取当前柱最后财月末。本次仅 Act，不新增 LY/LP；除会员筛选外，其余有效逻辑均以现有代码为准。
10. **行维度自动传递**：柱形图若配置图例（platform / shop_info_id 等）或小多图，事实表分组字段由模型自动传递筛选上下文，DAX 无需显式处理。
