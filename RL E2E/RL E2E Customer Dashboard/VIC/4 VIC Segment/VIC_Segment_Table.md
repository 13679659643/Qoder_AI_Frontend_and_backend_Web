# Power BI 解决方案 — VIC Segment 表格（独立度量值）

> status: ready
> created: 2026-08-14
> revised: 2026-09-12（SLS 类指标 Step1+Step2 由"合并为 end period 当月单步聚合"调整为分步实现：Step1 在 end period 当月框定 user_id，Step2 在所选时间范围 TimeFrame 区间聚合，两步时间范围不同不能合并）
> revised: 2026-09-14（占比类分母口径调整：_Customer Total 去掉 net_pay_amt>0 与分子完全对称；_SLS Total 由"所选时间范围单步全量"改为与 _SLS 同结构 Step1+Step2 分步；两者 customer_tier 均扩为全部 T1-T5，Total = T1+T2+T3+T4+T5 加总；LY 版本同步，旧逻辑块注释删除）
> revised: 2026-09-21（会员筛选统一为事实表 is_member=0；Member VIC 通过 KEEPFILTERS 追加 register_date<=对应本期/LY 最后财月末，单步计算与 Step1/Step2 均生效；不改变指标公式，不保留旧逻辑块注释）
> revised: 2026-09-22 15:19（Member VIC 要求 register_date 非空且不晚于原截止日；12 个 Base 的 20 处 KEEPFILTERS 同步，含单步、Step1/Step2 及占比分母；TTL VIC 原 OR 放行分支、筛选交集、Act/LY 截止日及其他公式保持不变）
> revised: 2026-09-22 17:27（SUM 类统一按 end period Tier 归属：Step1 保留 Tier 圈人，Step2 移除历史 Tier 限制；SLS/Qty/OrderCnt Act/LY 同步，SLS Total 逐个外部选中 Tier 复用分子加总；人数、其他筛选与派生公式不变，不保留旧逻辑块注释）
> type: 度量值开发 + 表格可视化
> 口径来源: 口径文档/VIC Segment.md（子模块四 VIC Segment，12 个指标，指标 0 为行维度本身）
> 参考实现: VIC/LY Last Purchase Time/LY_Last_Purchase_Time_Table.md（表格 + 每指标独立 Value/Display 范式，无 SWITCH 路由，无 x 轴时间处理）
> 金额类参考: Member/Customer_Member_Indicator.md（currency 货币符号拼接、Currency_ExchangeRate 汇率字段）

---

## 1. 需求理解

为 Customer Dashboard - VIC Tab 实现 VIC Segment 表格：

- **视觉对象**：Table（表格），非 Matrix
- **行维度**：`DIM_Row_VIC_Tier[Row Label]`（T1 (≧ 200K) ~ T5 (< 5K)，图片展示行标签；`Tier ID` 为与事实表 customer_tier 的 1:N 关系关联列）
  - DIM_Row_VIC_Tier 与 a03_e2e_customer_data_m 表模型关系为 1:N，Customer 人数和 SUM 类 Step1 由关系自动按期末 Tier 分组；SUM 类 Step2 显式移除 Tier 筛选，按已圈定用户聚合
  - `platform`、`shop_info_id` 分组维度直接拉取事实表字段实现自动传递，模型自动传递筛选，DAX 无需显式处理
- **无 x 轴**：表格视觉无列维度，不需要处理 x 轴上的当前时间
- **指标输出**：每个指标独立输出 Value（值）和 Display（格式化显示）两个度量值，不使用 SWITCH 路由
- **指标范围**：口径文档定义 12 个指标，其中指标 0（Tier）为行维度本身（字段直接拉取，不需要度量值），其余 12 个指标（指标 1~12）需要独立 Value + Display 度量值
- **口径**：一切以口径文档为准

### 1.1 关键特殊逻辑一：end period 时间筛选与所选时间范围筛选

口径文档全局逻辑要求：

> **聚合粒度**: `dt = 所选时间范围 end period`，`platform, shop_info_id`
> **end period 说明**: 所选时间范围的最后一个财月，只关注 Slicer_Time_Frame_Max 值

子模块四指标存在两套时间范围（2026-09-12 口径修订后明确区分，两套时间范围不一致，不能合并）：

- **Step 1 时间范围（end period 当月，用于框定分层买家 user_id）**：
  - 本期：`data_date ∈ [Last_Fiscal_Month_Min, Last_Fiscal_Month_Max]`
  - LY（用于 YOY 分子）：`data_date ∈ [Last_Fiscal_Month_Min_LY, Last_Fiscal_Month_Max_LY]`
  - 适用：指标 5/7/9/10/11/12 的 Step1（按期末 Tier 框定 user_id，指标 7 分母逐 Tier 复用）；指标 6 同比继承 SLS 的双步计算。指标 1/2/3/4 及 ACV/Freq. 的人数分母为单步 end period 聚合
- **Step 2 时间范围（所选时间范围，用于对 Step 1 user_id 聚合）**：
  - 本期：`data_date ∈ [TimeFrame_Min, TimeFrame_Max]`（TimeFrame_Min 读 Slicer_Time_Frame_Min，TimeFrame_Max 读 Slicer_Time_Frame_Max）
  - LY（用于 YOY 分子）：`data_date ∈ [TimeFrame_Min_LY, TimeFrame_Max_LY]`
  - 适用：指标 5/7/9/10/11/12 的 Step 2 聚合；指标 7 分母逐个外部选中 Tier 复用分子的 Step1+Step2 后加总，见 4.1.7

`Slicer_Time_Frame_Max` 已内置 `Last_Fiscal_Month_*` / `TimeFrame_Max*` 系列字段，`Slicer_Time_Frame_Min` 已内置 `TimeFrame_Min*` 系列字段，直接 SELECTEDVALUE 读取即可，无需 EDATE 计算。

### 1.2 关键特殊逻辑二：is_member / is_employee 双重人群筛选

口径文档要求：

> **is_member 使用**: `VAR __IsMemberFilter = SELECTEDVALUE(IsMemberFilter[IsMember], 0)`，默认 TTL VIC
> **is_employee 使用**: `VAR __IsEmployeeFilter = VALUES(Slicer_Is_Employee_Selection[IsEmployee_Code])`，默认 Yes

`IsMemberFilter` 与事实表保持断开关系，`__IsMemberFilter` 仅控制是否追加注册日期限制，不能直接作为事实表 `is_member` 的筛选值。

| 切片器结果         | 事实表会员筛选    | 注册日期限制                                                                                              |
| ------------------ | ----------------- | --------------------------------------------------------------------------------------------------------- |
| 0：TTL VIC（默认） | `is_member = 0` | 不追加限制，保留已有注册日期筛选                                                                          |
| 1：Member VIC      | `is_member = 0` | `NOT ISBLANK(register_date) && register_date <= end_period_date`，通过 `KEEPFILTERS` 与已有筛选取交集 |

- 本期 `end_period_date` = `Slicer_Time_Frame_Max[Last_Fiscal_Month_Max]`；LY = `Last_Fiscal_Month_Max_LY`，均包含截止当天。本方案没有 LP 指标，不新增 LP 分支；含 LP 的扩展才使用 `Last_Fiscal_Month_Max_LP`。
- Customer No. / Customer Total 的单步计算使用 `__PeriodMax`（Act）或 `__LYMax`（LY），它们已经读取对应财月末。
- SLS / SLS Total / Net Pay Qty / Net Pay Order Cnt 的 **Step 1、Step 2 均追加相同会员条件**：Member VIC 两步均要求注册日期非空，Act 上限为 `__EndPeriodMax`，LY 上限为 `__EndPeriodMax_LY`。这两步的 `__PeriodMax` / `__PeriodMax_LY` 表示 Step 2 的 TimeFrame 区间终点，不能用作注册截止日，也不增加注册日期下限。
- TTL VIC 保留 `__IsMemberFilter = 0` 的原 OR 放行分支，不新增非空要求；空注册日期是否保留仍取决于已有筛选，`KEEPFILTERS` 不会恢复外部已排除的日期。Member VIC 的非空与截止日条件也只与已有注册日期筛选取交集。
- 原有 `is_employee in __IsEmployeeFilter`、platform/shop_info_id、Step1/Step2 数据日期区间和派生公式保持不变；Tier 按 1.4 节仅用于期末圈人，SLS Total 按外部选中 Tier 逐行加总。Customer 人数及人数分母不变，本模块不涉及 VIC Retention%。

### 1.3 关键特殊逻辑三：分组维度自动传递

口径文档明确：

> **分组维度**: 按 `customer_tier`（T1/T2/T3/T4/T5）分组，已有 DIM_Row_VIC_Tier 行维度字段，DIM_Row_VIC_Tier 和 a03_e2e_customer_data_m 表，模型关系为 1:N，因此 Customer 人数和 SUM 类 Step1 自动按期末 Tier 分组；SUM 类 Step2 显式移除 Tier 筛选
> **聚合粒度**: `platform, shop_info_id` 分组维度由表字段自动传递，DAX 无需显式处理

`customer_tier`（通过 DIM_Row_VIC_Tier）只用于 Customer 人数和 SUM 类 Step1 的期末分层；SUM 类 Step2 移除 Tier 筛选，并保留已圈定用户集合。`platform`、`shop_info_id` 在两步均保留原筛选。

### 1.4 关键特殊逻辑四：SLS 类指标的 Step 1 + Step 2 口径（分步计算，不能合并）

口径文档指标 5（SLS）、指标 7（% of Total SLS 分子）、指标 9（ACV 分子）、指标 10（AUR 分子/分母）、指标 11（UPT 分子/分母）、指标 12（Freq. 分子）均采用 Step 1 + Step 2 口径：

> **Step 1**: 在 dt = 所选时间范围 end period（`Last_Fiscal_Month_Min ~ Last_Fiscal_Month_Max`），筛选 customer_tier = T1/T2/T3/T4/T5，框定 user_id 范围
> **Step 2**: 再看该 user_id 在所选时间范围（`TimeFrame_Min ~ TimeFrame_Max`）对应的 sum(net_pay_amt) / sum(net_pay_qty) / sum(net_pay_order_cnt)

**2026-09-12 口径修订**：Step 1 与 Step 2 时间范围不一致（Step 1 = end period 当月，Step 2 = 所选时间范围），**不能直接合并区间计算**，必须分步实现（分步范式参考："新客 No." 度量值的 Step1+Step2 实现，两步各自独立框定/聚合，不做区间合并）：

- **Step 1（end period 当月框定分层买家）**：`CALCULATETABLE(VALUES(user_id), ...)`，data_date ∈ end period 当月区间，customer_tier 分组由 DIM_Row_VIC_Tier 1:N 模型关系自动传递（当前行筛选即为 T1/T2/.../T5），is_member / is_employee 双重人群筛选，框定 user_id 集合
- **Step 2（按期末 Tier 归属的区间聚合）**：`CALCULATE(SUM(...), TREATAS(__TierUsers, a03_e2e_customer_data_m[user_id]), ...)`，data_date ∈ TimeFrame 区间；仅在此步用 `REMOVEFILTERS('DIM_Row_VIC_Tier')` 和 `REMOVEFILTERS('a03_e2e_customer_data_m'[customer_tier])` 移除历史 Tier 限制。Step1 用户集合已固定，历史记录属于其他 Tier 或 Tier 为空也计入该用户的期末 Tier；is_member、is_employee、注册日期、platform、shop_info_id 筛选保持原规则。Step2 内使用两层 CALCULATE：外层先移除 Tier，内层再求值日期/会员筛选并聚合，避免同层筛选参数在原 Tier 上下文提前求值而裁剪历史记录。此嵌套仅包 Step2，不得包在整个基础度量外层，以免改变 Step1 圈人。
- **SLS Total（4.1.7/4.1.8）**：`SUMX` 遍历 `ALLSELECTED('DIM_Row_VIC_Tier')` 中非空 Tier，逐 Tier 复用对应 Act/LY 的 `_SLS Base` 后加总；每次调用均独立执行 Step1+Step2。外部 Tier 选择仅限定期末人群，不限制历史 Tier。Customer Total（4.1.3/4.1.4）仍为原单步 end period DISTINCTCOUNT + ALLSELECTED。
- **LY 版本对应偏移**：Step 1 用 `Last_Fiscal_Month_Min_LY ~ Last_Fiscal_Month_Max_LY`（LY end period 当月），Step 2 用 `TimeFrame_Min_LY ~ TimeFrame_Max_LY`（LY 所选时间范围）

### 1.5 关键特殊逻辑五：货币转换

口径文档要求：

> **货币转换规则**: 数据源默认为 RMB，转化为美元需要除以固定值 7

金额类指标（SLS / ACV / AUR）使用 `Slicer_Currency_Selection` 切片器：

- 汇率字段：`Slicer_Currency_Selection[Currency_ExchangeRate]`，默认 1
- 货币符号字段：`Slicer_Currency_Selection[Currency_Symbol]`，默认 "¥"
- 金额类指标 Value 度量值中 `DIVIDE(SUM(net_pay_amt), __FXRate)` 做汇率换算
- Display 度量值中 `__CurrencySymbol & FORMAT(__Value, "#,##0")` 拼接货币符号

> 注：口径文档第 125 行明确"报表上看到的数值 = 实际金额 ÷ 1,000"，SLS (in K) 指标名称已带 (in K)，但数据格式定义为 `#,##0`（千分位整数，非 K 单位）。经与口径文档对齐，SLS Value 度量值中显式 ÷1000，Display 格式化为 `#,##0`（不再拼接 "k"），严格遵循口径文档数据格式 `#,##0`。

### 1.6 关键特殊逻辑六：YOY 派生指标的"去年"定义

口径文档指标 2（Customer No. vs LY）、指标 6（SLS vs LY）为比值 YOY；指标 4（Customer% vs LY）、指标 8（SLS % vs LY）为差值 YOY（pts 指标，展示时 ×100 转 pts）。四者的 YOY 计算：

> **计算公式**: 比值 YOY = 今年 / 去年 - 1；差值 YOY = 今年 - 去年（×100 转 pts）

"去年"采用 LY end period 时间偏移（读取 `Slicer_Time_Frame_Max[Last_Fiscal_Month_Min_LY/Max_LY]`），对事实表 `data_date` 做 LY 区间筛选。

派生公式展开：

- Customer No. vs LY = 今年 Customer No. / 去年 Customer No. - 1
- SLS vs LY = 今年 SLS / 去年 SLS - 1
- Customer% vs LY = 今年 Customer% - 去年 Customer%（差值，×100 转 pts）
- SLS % vs LY = 今年 SLS% - 去年 SLS%（差值，×100 转 pts）

### 1.7 与参考文件 LY_Last_Purchase_Time_Table.md 的关键差异

| 维度       | 参考文件（LY_Last_Purchase_Time_Table.md）             | 本方案（VIC_Segment_Table.md）                                      |
| ---------- | ------------------------------------------------------ | ------------------------------------------------------------------- |
| 行维度     | last_fy_last_order_month_type（事实表字段直接拉取）    | DIM_Row_VIC_Tier[Row Label]（1:N 模型关系，模型自动传递）           |
| 指标数量   | 7 对 Value/Display（指标 2~8）                         | 12 对 Value/Display（指标 1~12）                                    |
| 金额类指标 | 无（仅数量类、比率类）                                 | 有（SLS / ACV / AUR，需货币符号 + 汇率换算）                        |
| SLS 口径   | 不涉及                                                 | Step 1 + Step 2 分步（Step2 时间=所选时间范围，2026-09-12 修订）    |
| 货币符号   | 不涉及                                                 | 复用 Slicer_Currency_Selection（参考 Customer_Member_Indicator.md） |
| YOY 派生   | VIC Repurchase% YOY / VIC Retention% YOY               | Customer No. vs LY / Customer% vs LY / SLS vs LY / SLS % vs LY      |
| 字段筛选   | is_fy_vic / is_fy_retention_vic / last_12m_net_pay_amt | 无（直接按 customer_tier 分组，无 VIC 标识字段筛选）                |

---

## 2. 现状分析

### 2.1 数据底表

| 对象     | 名称                                                                                                                                          | 出处                                 |
| -------- | --------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------ |
| 事实表   | a03_e2e_customer_data_m                                                                                                                       | 口径文档全局逻辑                     |
| 关键字段 | data_date, platform, shop_info_id, user_id, is_member, register_date, is_employee, customer_tier, net_pay_amt, net_pay_qty, net_pay_order_cnt | 口径文档子模块四各指标及全局会员规则 |

> 表为月度聚合表，`data_date` 为月末日期，用于 end period 时间筛选。

### 2.2 维度表清单

| 维度表                       | 类型     | 连接方式                                                                                                                                                                                                                           |
| ---------------------------- | -------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| DIM_Row_VIC_Tier             | 1:N 维度 | 与 a03_e2e_customer_data_m[customer_tier] 建立 1:N 关系，模型自动传递筛选                                                                                                                                                          |
| Slicer_Time_Frame_Min        | 断开维度 | SELECTEDVALUE 读取`TimeFrame_Min`（本期所选时间范围起始日）、`TimeFrame_Min_LY`（LY 所选时间范围起始日），Step 2 聚合区间起点，2026-09-12 修订新增依赖                                                                         |
| Slicer_Time_Frame_Max        | 断开维度 | SELECTEDVALUE 读取`TimeFrame_Max`/`TimeFrame_Max_LY`（所选时间范围终点，Step 2）、`Last_Fiscal_Month_Min/Max`（本期 end period 当月，Step 1）、`Last_Fiscal_Month_Min_LY/Max_LY`（LY end period 当月，已预算，YOY 直接读） |
| Slicer_Is_Employee_Selection | 断开维度 | SELECTEDVALUE 读取`IsEmployee_Code`                                                                                                                                                                                              |
| IsMemberFilter               | 断开维度 | SELECTEDVALUE 读取`IsMember`                                                                                                                                                                                                     |
| Slicer_Platform_Selection    | 断开维度 | 行维度直接拉事实表 platform 字段，模型自动传递                                                                                                                                                                                     |
| Slicer_Store_Name            | 断开维度 | 行维度直接拉事实表 shop_info_id 字段，模型自动传递                                                                                                                                                                                 |
| Slicer_Currency_Selection    | 断开维度 | SELECTEDVALUE 读取`Currency_ExchangeRate`、`Currency_Symbol`（金额类指标专用）                                                                                                                                                 |

> **行维度处理**：Customer 人数与 SUM 类 Step1 保留 `customer_tier` 的 1:N 关系筛选；SUM 类 Step2 仅移除 Tier，保留期末用户集合及 `platform` / `shop_info_id` 等其他筛选。

---

## 3. 方案设计

### 3.1 整体架构

```
核心思路：表格视觉 + 每指标独立 Value/Display 度量值（无 SWITCH 路由）

a03_e2e_customer_data_m（事实表）
    │
    │  行维度：
    │  - DIM_Row_VIC_Tier[Row Label]（1:N 模型关系，自动传递）
    │  - platform / shop_info_id（可选叠加粒度，事实表字段直接拉取）
    │  人数与 Step1 自动传递；SUM 类 Step2 移除 Tier
    │
    ▼
┌─────────────────────────── Table 视觉对象 ──────────────────────────┐
│  行 = DIM_Row_VIC_Tier[Row Label]（+ 可选 platform / shop_info_id）  │
│  值 = 12 对独立 Value/Display 度量值                                │
│       - Customer No. Value / Display                                │
│       - Customer No. vs LY Value / Display                          │
│       - Customer% Value / Display                                  │
│       - Customer% vs LY Value / Display                             │
│       - SLS Value / Display                                         │
│       - SLS vs LY Value / Display                                   │
│       - SLS% Value / Display                                       │
│       - SLS% vs LY Value / Display                                  │
│       - ACV Value / Display                                        │
│       - AUR Value / Display                                        │
│       - UPT Value / Display                                         │
│       - Freq. Value / Display                                       │
└──────────────────────────────────────────────────────────────────────┘
                                   ▲
                                   │
              度量值链（每指标独立，无 SWITCH 路由）
              ┌────────────────────────────────────────────────────┐
              │  内部基础层（Base，私有，下划线前缀）              │
              │  ├ _Customer No. Base Act / _Customer No. Base LY│
              │  ├ _SLS Base Act / _SLS Base LY                  │
              │  └ _SLS Total Base Act / _SLS Total Base LY      │
              │     （SLS Total = 逐个外部选中 Tier 复用 _SLS，   │
              │       每行执行 Step1+Step2，再用 SUMX 加总）      │
              │     统一应用 is_member / is_employee 筛选         │
              │     Customer 类单步 end period 当月；SLS 类为     │
              │     Step1 end period + Step2 所选时间范围分步     │
              │                                                    │
              │  对外 Value 层（12 个独立度量值）                │
              │  ├ Customer No. Value = _Customer No. Base Act    │
              │  ├ Customer No. vs LY Value = 今年/去年-1         │
              │  ├ Customer% Value = DIVIDE(分子Act, 分母Act)     │
              │  ├ Customer% vs LY Value = 今年%-去年%（差值）      │
              │  ├ SLS Value = _SLS Base Act ÷ 1000               │
              │  ├ SLS vs LY Value = 今年/去年-1                   │
              │  ├ SLS% Value = DIVIDE(SLS Act, SLS Total Act)     │
              │  ├ SLS% vs LY Value = 今年%-去年%（差值）          │
              │  ├ ACV Value = DIVIDE(SLS Act, Customer No. Act)  │
              │  ├ AUR Value = DIVIDE(SLS Act, Qty Act)           │
              │  ├ UPT Value = DIVIDE(Qty Act, OrderCnt Act)      │
              │  └ Freq. Value = DIVIDE(OrderCnt Act, Customer No.)│
              │                                                    │
              │  对外 Display 层（12 个独立度量值，按数据格式格式化）│
              └────────────────────────────────────────────────────┘
```

### 3.2 度量值模型设计

```
[内部基础层 — Base Act / Base LY]       ← 私有度量值（下划线前缀，放 Base Metrics 文件夹）
_Customer No. Base Act                  ← end period 当月 DISTINCTCOUNT(user_id)（单步口径，不涉及 Step1+Step2）
_Customer No. Base LY                   ← LY end period 当月 DISTINCTCOUNT(user_id)
_SLS Base Act                           ← Step1（end period 当月框定 user_id）+ Step2（所选时间范围 SUM(net_pay_amt)），不÷1000（基础值保留原值，÷1000 在 SLS Value 中做）
_SLS Base LY                            ← Step1（LY end period 当月框定 user_id）+ Step2（LY 所选时间范围 SUM(net_pay_amt)）
_SLS Total Base Act                     ← SUMX 遍历 ALLSELECTED 非空 Tier，逐行调用 _SLS Base Act（各自 Step1+Step2）后加总
_SLS Total Base LY                      ← SUMX 遍历 ALLSELECTED 非空 Tier，逐行调用 _SLS Base LY（各自 LY Step1+Step2）后加总
_Customer Total Base Act                ← end period 当月 DISTINCTCOUNT(user_id)，customer_tier 全部 T1-T5（ALLSELECTED Row Label），与分子完全对称（Customer% 分母，单步口径）
_Customer Total Base LY                 ← LY end period 当月 DISTINCTCOUNT(user_id)，customer_tier 全部 T1-T5（ALLSELECTED Row Label），与分子对称（Customer% vs LY 分母）
_Net Pay Qty Base Act                   ← Step1（end period 当月框定 user_id）+ Step2（所选时间范围 SUM(net_pay_qty)）
_Net Pay Qty Base LY                    ← Step1（LY end period 当月框定 user_id）+ Step2（LY 所选时间范围 SUM(net_pay_qty)）
_Net Pay Order Cnt Base Act             ← Step1（end period 当月框定 user_id）+ Step2（所选时间范围 SUM(net_pay_order_cnt)）
_Net Pay Order Cnt Base LY              ← Step1（LY end period 当月框定 user_id）+ Step2（LY 所选时间范围 SUM(net_pay_order_cnt)）

[对外 Value 层 — 12 个独立度量值]       ← 放 Cell Values 文件夹
Customer No. Value                      ← = _Customer No. Base Act
Customer No. vs LY Value                ← = 今年 / 去年 - 1
Customer% Value                         ← = DIVIDE(_Customer No. Base Act, _Customer Total Base Act)
Customer% vs LY Value                   ← = 今年% - 去年%（差值，×100 转 pts）
SLS Value                               ← = DIVIDE(_SLS Base Act, __FXRate) / 1000
SLS vs LY Value                         ← = 今年 / 去年 - 1
SLS% Value                              ← = DIVIDE(_SLS Base Act, _SLS Total Base Act)
SLS% vs LY Value                        ← = 今年% - 去年%（差值，pts）
ACV Value                               ← = DIVIDE(_SLS Base Act, _Customer No. Base Act) ÷ __FXRate
AUR Value                               ← = DIVIDE(_SLS Base Act, _Net Pay Qty Base Act) ÷ __FXRate
UPT Value                               ← = DIVIDE(_Net Pay Qty Base Act, _Net Pay Order Cnt Base Act)
Freq. Value                             ← = DIVIDE(_Net Pay Order Cnt Base Act, _Customer No. Base Act)

[对外 Display 层 — 12 个独立度量值]     ← 放 Formatting 文件夹
Customer No. Display                    ← integer 格式 #,##0
Customer No. vs LY Display              ← percent_1dp 格式 #,##0.0%（不含正号）
Customer% Display                       ← percent_1dp 格式 #,##0.0%（不含正号）
Customer% vs LY Display                 ← integer_pts 格式 #,##0pts;-#,##0pts;0pts（差值，不含正号）
SLS Display                             ← currency 格式 __CurrencySymbol & FORMAT(__Value, "#,##0")
SLS vs LY Display                       ← percent_1dp 格式 #,##0.0%（不含正号）
SLS% Display                            ← percent_1dp 格式 #,##0.0%（不含正号）
SLS% vs LY Display                      ← integer_pts 格式 #,##0pts;-#,##0pts;0pts（不含正号）
ACV Display                             ← currency 格式 __CurrencySymbol & FORMAT(__Value, "#,##0")
AUR Display                             ← currency 格式 __CurrencySymbol & FORMAT(__Value, "#,##0")
UPT Display                             ← integer 格式 #,##0
Freq. Display                           ← decimal_1dp 格式 #,##0.0
```

### 3.3 筛选器上下文

| 筛选器                                              | 作用方式                                                                                   | DAX 处理                                                                                                                                                                  |
| --------------------------------------------------- | ------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Slicer_Time_Frame_Max（Step1 本期 end period）      | 断开维度，SELECTEDVALUE 读取`Last_Fiscal_Month_Min/Max`                                  | `data_date >= __EndPeriodMin AND data_date <= __EndPeriodMax`（Step1 框定 user_id）                                                                                     |
| Slicer_Time_Frame_Max（Step1 LY end period）        | SELECTEDVALUE 读取`Last_Fiscal_Month_Min_LY/Max_LY`                                      | `data_date >= __EndPeriodMin_LY AND data_date <= __EndPeriodMax_LY`（LY Step1，YOY 派生专用）                                                                           |
| Slicer_Time_Frame_Min/Max（Step2 本期所选时间范围） | 断开维度，SELECTEDVALUE 读取`TimeFrame_Min`（Min 表）/ `TimeFrame_Max`（Max 表）       | `data_date >= __PeriodMin AND data_date <= __PeriodMax`（Step2 聚合区间，2026-09-12 修订新增）                                                                          |
| Slicer_Time_Frame_Min/Max（Step2 LY 所选时间范围）  | SELECTEDVALUE 读取`TimeFrame_Min_LY`（Min 表）/ `TimeFrame_Max_LY`（Max 表）           | `data_date >= __PeriodMin_LY AND data_date <= __PeriodMax_LY`（LY Step2）                                                                                               |
| Slicer_Is_Employee_Selection                        | 断开维度，SELECTEDVALUE 读取`IsEmployee_Code`                                            | `a03_e2e_customer_data_m[is_employee] in __IsEmployeeFilter`                                                                                                            |
| IsMemberFilter                                      | 断开维度，SELECTEDVALUE 读取`IsMember`，默认 0                                           | 事实表固定`is_member = 0`；Member VIC 用 KEEPFILTERS 追加 `register_date 非空且 <= 对应本期/LY 最后财月末`，单步及 Step1/Step2 均生效                                 |
| DIM_Row_VIC_Tier                                    | 1:N 模型关系；视觉对象筛选：Tier ≠ 空白（排除未分层买家，保占比类分母 tier 范围 = T1-T5） | Customer 人数与 SUM 类 Step1 保留 Tier；SUM 类 Step2 移除维度表及事实表 Tier 筛选。Customer Total 保留原 ALLSELECTED；SLS Total 按 ALLSELECTED 非空 Tier 逐行复用分子加总 |
| Slicer_Currency_Selection                           | 断开维度，SELECTEDVALUE 读取`Currency_ExchangeRate`、`Currency_Symbol`                 | 金额类指标 ÷`Currency_ExchangeRate`；Display 拼接 `Currency_Symbol`                                                                                                  |
| 事实表分组字段（platform / shop_info_id）           | 表格行直接拉取，模型自动传递筛选                                                           | Step1/Step2 均保留自动传递（分组维度）                                                                                                                                    |

### 3.4 时间偏移规则（财历映射）

直接读取 Slicer_Time_Frame_Min / Slicer_Time_Frame_Max 内置的预算字段（无需 EDATE -12 或 Key 偏移计算）：

- Step 1（end period 当月）：本期 `Last_Fiscal_Month_Min` ~ `Last_Fiscal_Month_Max`；LY `Last_Fiscal_Month_Min_LY` ~ `Last_Fiscal_Month_Max_LY`
- Step 2（所选时间范围）：本期 `TimeFrame_Min`（Min 表）~ `TimeFrame_Max`（Max 表）；LY `TimeFrame_Min_LY`（Min 表）~ `TimeFrame_Max_LY`（Max 表）
- Step 1 与 Step 2 两套区间不一致，分别独立筛选，不能合并

### 3.5 指标计算公式与数据格式

| 序号 | 指标名称               | 计算公式                                                                                                                                            | 数据类型    | 数据格式                    |
| ---- | ---------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------- | ----------- | --------------------------- |
| 0    | Tier                   | 行维度字段直接拉取（DIM_Row_VIC_Tier[Row Label]），不需要度量值                                                                                     | —          | —                          |
| 1    | Customer No.           | count(distinct user_id)                                                                                                                             | integer     | `#,##0`                   |
| 2    | Customer No. vs LY     | 今年 / 去年 - 1                                                                                                                                     | percent_1dp | `#,##0.0%`                |
| 3    | % of Total (Customer%) | 分子：count(distinct user_id) where customer_tier=T1-T5；分母：count(distinct user_id) where customer_tier in T1-T5（与分子对称，Total = 五行加总） | percent_1dp | `#,##0.0%`                |
| 4    | Customer% vs LY        | 今年 - 去年（差值，×100 转 pts）                                                                                                                   | integer_pts | `#,##0pts;-#,##0pts;0pts` |
| 5    | SLS (in K)             | Step1（end period 当月框定 user_id）+ Step2（所选时间范围 sum(net_pay_amt)），÷1000，÷汇率                                                        | currency    | `#,##0`（拼接货币符号）   |
| 6    | SLS vs LY              | 今年 / 去年 - 1                                                                                                                                     | percent_1dp | `#,##0.0%`                |
| 7    | % of Total (SLS%)      | 分子：按期末 Tier 圈人后跨历史 Tier 聚合；分母：逐个外部选中 Tier 复用分子后加总                                                                    | percent_1dp | `#,##0.0%`                |
| 8    | SLS % vs LY            | 今年 - 去年（差值，×100 转 pts）                                                                                                                   | integer_pts | `#,##0pts;-#,##0pts;0pts` |
| 9    | ACV                    | 分子：SLS（Step1+Step2 同指标 5）；分母：end period 当月 count(distinct user_id)                                                                    | currency    | `#,##0`（拼接货币符号）   |
| 10   | AUR                    | 分子：Step1+Step2 sum(net_pay_amt)；分母：Step1+Step2 sum(net_pay_qty)                                                                              | currency    | `#,##0`（拼接货币符号）   |
| 11   | UPT                    | 分子：Step1+Step2 sum(net_pay_qty)；分母：Step1+Step2 sum(net_pay_order_cnt)                                                                        | integer     | `#,##0`                   |
| 12   | Freq.                  | 分子：Step1+Step2 sum(net_pay_order_cnt)；分母：end period 当月 count(distinct user_id)                                                             | decimal_1dp | `#,##0.0`                 |

> **YOY 格式说明**：口径文档指标 2 / 6 数据格式为 `#,##0.0%`（percent_1dp，不含正号），指标 4 / 8 数据格式为 `#,##0pts;-#,##0pts;0pts`（integer_pts，差值 ×100 转 pts，不含正号）。本方案严格遵循口径文档，所有 YOY Display 不含正号。

---

## 4. 度量值实现

### 4.1 内部基础层 — Base Act / Base LY（私有度量值）

> 私有度量值（下划线前缀），放 Base Metrics 文件夹，供对外 Value 层调用，避免重复代码。
> Act = 本期区间，LY = LY 区间。分两类口径（2026-09-12 修订）：4.1.1~4.1.4（Customer 类）为单步 end period 当月口径；4.1.5~4.1.12（SLS / Qty / OrderCnt 类）为 Step1（end period 当月框定 user_id）+ Step2（所选时间范围聚合）分步口径，两步时间范围不同不能合并。
> 4 个 Customer Base 单步与 6 个 SLS/Qty/OrderCnt Base 双步共 16 处直接事实表筛选；2 个 SLS Total Base 逐 Tier 复用 SLS Base，继承相同规则：统一 `is_member = 0`，配合 `KEEPFILTERS(__IsMemberFilter = 0 || (NOT ISBLANK(register_date) && register_date <= 对应财月末))`。TTL 保留原 OR 放行分支，不新增非空或截止日限制；Member 要求日期非空且不晚于原截止日，并与已有注册日期筛选取交集。Act/LY 各取自身财月末，Step1/Step2 使用同一对应期注册截止日。

#### 4.1.1 _Customer No. Base Act（买家人数本期基础值，单步 end period 口径）

```dax
_Customer No. Base Act = 
// ========================================
// 度量值: _Customer No. Base Act
// Display Folder: Base Metrics
// 用途: Customer No.（买家人数）本期基础值
// 会员筛选: 两档 is_member=0；仅 Member VIC 要求 register_date 非空且<=本度量对应期最后财月末，KEEPFILTERS 保留交集，TTL 原逻辑不变
// 依赖: a03_e2e_customer_data_m,
//       Slicer_Time_Frame_Max[Last_Fiscal_Month_Min/Max],
//       Slicer_Is_Employee_Selection[IsEmployee_Code],
//       IsMemberFilter[IsMember]
// 口径来源: 口径文档/VIC Segment.md 指标 1
// 筛选上下文:
//   - data_date ∈ [Last_Fiscal_Month_Min, Last_Fiscal_Month_Max]（end period 当月）
//   - is_member = 0；Member VIC 追加 register_date 非空且 <= __PeriodMax（默认 TTL VIC 不追加日期限制）
//   - is_employee in __IsEmployeeFilter（默认 所有）
//   - customer_tier 分组由 DIM_Row_VIC_Tier 1:N 模型关系自动传递，DAX 无需显式处理
// 聚合粒度: DISTINCTCOUNT(user_id)
// ========================================
    VAR __PeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Max[Last_Fiscal_Month_Min])
    VAR __PeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max[Last_Fiscal_Month_Max])
    VAR __IsMemberFilter = SELECTEDVALUE(IsMemberFilter[IsMember], 0)
    VAR __IsEmployeeFilter = VALUES(Slicer_Is_Employee_Selection[IsEmployee_Code])

    RETURN
        CALCULATE(
            DISTINCTCOUNT('a03_e2e_customer_data_m'[user_id]),
            'a03_e2e_customer_data_m'[is_member] = 0,
            KEEPFILTERS(
                __IsMemberFilter = 0
                    || (
                        NOT ISBLANK('a03_e2e_customer_data_m'[register_date])
                            && 'a03_e2e_customer_data_m'[register_date] <= __PeriodMax
                    )
            ),
            'a03_e2e_customer_data_m'[is_employee] in __IsEmployeeFilter,
            'a03_e2e_customer_data_m'[data_date] >= __PeriodMin,
            'a03_e2e_customer_data_m'[data_date] <= __PeriodMax
        )
```

#### 4.1.2 _Customer No. Base LY（买家人数去年同期基础值）

```dax
_Customer No. Base LY = 
// ========================================
// 度量值: _Customer No. Base LY
// Display Folder: Base Metrics
// 用途: Customer No.（买家人数）去年同期基础值，用于 YOY 派生
// 会员筛选: 两档 is_member=0；仅 Member VIC 要求 register_date 非空且<=本度量对应期最后财月末，KEEPFILTERS 保留交集，TTL 原逻辑不变
// 依赖: a03_e2e_customer_data_m,
//       Slicer_Time_Frame_Max[Last_Fiscal_Month_Min_LY/Max_LY],
//       Slicer_Is_Employee_Selection[IsEmployee_Code],
//       IsMemberFilter[IsMember]
// 口径来源: 口径文档/VIC Segment.md 指标 1（LY 版本，用于指标 2 YOY 分母）
// 筛选上下文:
//   - data_date ∈ [Last_Fiscal_Month_Min_LY, Last_Fiscal_Month_Max_LY]（LY end period 当月）
//   - is_member / is_employee 双重人群筛选
// 时间偏移: 财历映射，直接读取 Slicer_Time_Frame_Max 已预算字段，无需 EDATE
// ========================================
    VAR __LYMin = SELECTEDVALUE(Slicer_Time_Frame_Max[Last_Fiscal_Month_Min_LY])
    VAR __LYMax = SELECTEDVALUE(Slicer_Time_Frame_Max[Last_Fiscal_Month_Max_LY])
    VAR __IsMemberFilter = SELECTEDVALUE(IsMemberFilter[IsMember], 0)
    VAR __IsEmployeeFilter = VALUES(Slicer_Is_Employee_Selection[IsEmployee_Code])

    RETURN
        CALCULATE(
            DISTINCTCOUNT('a03_e2e_customer_data_m'[user_id]),
            'a03_e2e_customer_data_m'[is_member] = 0,
            KEEPFILTERS(
                __IsMemberFilter = 0
                    || (
                        NOT ISBLANK('a03_e2e_customer_data_m'[register_date])
                            && 'a03_e2e_customer_data_m'[register_date] <= __LYMax
                    )
            ),
            'a03_e2e_customer_data_m'[is_employee] in __IsEmployeeFilter,
            'a03_e2e_customer_data_m'[data_date] >= __LYMin,
            'a03_e2e_customer_data_m'[data_date] <= __LYMax
        )
```

#### 4.1.3 _Customer Total Base Act（买家人数占比分母本期基础值，customer_tier 全量，与分子对称）

```dax
_Customer Total Base Act = 
// ========================================
// 度量值: _Customer Total Base Act
// Display Folder: Base Metrics
// 用途: Customer% 分母（总买家人数）本期基础值
// 会员筛选: 两档 is_member=0；仅 Member VIC 要求 register_date 非空且<=本度量对应期最后财月末，KEEPFILTERS 保留交集，TTL 原逻辑不变
// 依赖: a03_e2e_customer_data_m,
//       Slicer_Time_Frame_Max[Last_Fiscal_Month_Min/Max],
//       Slicer_Is_Employee_Selection[IsEmployee_Code],
//       IsMemberFilter[IsMember],
//       DIM_Row_VIC_Tier
// 口径来源: 口径文档/VIC Segment.md 指标 3（分母，2026-09-14 修订）
// 筛选上下文:
//   - data_date ∈ [Last_Fiscal_Month_Min, Last_Fiscal_Month_Max]（end period 当月，与分子一致）
//   - customer_tier ∈ 全部 T1-T5（ALLSELECTED Row Label 移除行上下文 tier 筛选，
//     保留外部切片器/视觉筛选影响，Total = T1+T2+T3+T4+T5 加总口径）
//   - is_member / is_employee 双重人群筛选（与分子一致）
//   - 与分子完全对称（无 net_pay_amt > 0 附加筛选，2026-09-14 修订删除），
//     保留 platform/shop_info_id 分组维度
// 聚合粒度: DISTINCTCOUNT(user_id)
// ========================================
    VAR __PeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Max[Last_Fiscal_Month_Min])
    VAR __PeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max[Last_Fiscal_Month_Max])
    VAR __IsMemberFilter = SELECTEDVALUE(IsMemberFilter[IsMember], 0)
    VAR __IsEmployeeFilter = VALUES(Slicer_Is_Employee_Selection[IsEmployee_Code])

    RETURN
        CALCULATE(
            DISTINCTCOUNT('a03_e2e_customer_data_m'[user_id]),
            'a03_e2e_customer_data_m'[is_member] = 0,
            KEEPFILTERS(
                __IsMemberFilter = 0
                    || (
                        NOT ISBLANK('a03_e2e_customer_data_m'[register_date])
                            && 'a03_e2e_customer_data_m'[register_date] <= __PeriodMax
                    )
            ),
            'a03_e2e_customer_data_m'[is_employee] in __IsEmployeeFilter,
            'a03_e2e_customer_data_m'[data_date] >= __PeriodMin,
            'a03_e2e_customer_data_m'[data_date] <= __PeriodMax,
            ALLSELECTED('DIM_Row_VIC_Tier')
        )
```

#### 4.1.4 _Customer Total Base LY（买家人数占比分母去年同期基础值，customer_tier 全量，与分子对称）

```dax
_Customer Total Base LY = 
// ========================================
// 度量值: _Customer Total Base LY
// Display Folder: Base Metrics
// 用途: Customer% 分母（总买家人数）去年同期基础值
// 会员筛选: 两档 is_member=0；仅 Member VIC 要求 register_date 非空且<=本度量对应期最后财月末，KEEPFILTERS 保留交集，TTL 原逻辑不变
// 依赖: a03_e2e_customer_data_m,
//       Slicer_Time_Frame_Max[Last_Fiscal_Month_Min_LY/Max_LY],
//       Slicer_Is_Employee_Selection[IsEmployee_Code],
//       IsMemberFilter[IsMember],
//       DIM_Row_VIC_Tier
// 口径来源: 口径文档/VIC Segment.md 指标 3（分母 LY 版本，用于指标 4 YOY 分母，2026-09-14 修订）
// 筛选上下文:
//   - data_date ∈ [Last_Fiscal_Month_Min_LY, Last_Fiscal_Month_Max_LY]（LY end period 当月，与分子一致）
//   - customer_tier ∈ 全部 T1-T5（ALLSELECTED Row Label，同 4.1.3，Total = 五行加总口径）
//   - is_member / is_employee 双重人群筛选（与分子一致，无 net_pay_amt > 0 附加筛选）
// 时间偏移: 财历映射
// ========================================
    VAR __LYMin = SELECTEDVALUE(Slicer_Time_Frame_Max[Last_Fiscal_Month_Min_LY])
    VAR __LYMax = SELECTEDVALUE(Slicer_Time_Frame_Max[Last_Fiscal_Month_Max_LY])
    VAR __IsMemberFilter = SELECTEDVALUE(IsMemberFilter[IsMember], 0)
    VAR __IsEmployeeFilter = VALUES(Slicer_Is_Employee_Selection[IsEmployee_Code])

    RETURN
        CALCULATE(
            DISTINCTCOUNT('a03_e2e_customer_data_m'[user_id]),
            'a03_e2e_customer_data_m'[is_member] = 0,
            KEEPFILTERS(
                __IsMemberFilter = 0
                    || (
                        NOT ISBLANK('a03_e2e_customer_data_m'[register_date])
                            && 'a03_e2e_customer_data_m'[register_date] <= __LYMax
                    )
            ),
            'a03_e2e_customer_data_m'[is_employee] in __IsEmployeeFilter,
            'a03_e2e_customer_data_m'[data_date] >= __LYMin,
            'a03_e2e_customer_data_m'[data_date] <= __LYMax,
            ALLSELECTED('DIM_Row_VIC_Tier')
        )
```

#### 4.1.5 _SLS Base Act（净销售额本期基础值，Step1+Step2 分步，原值不÷1000）

```dax
_SLS Base Act = 
// ========================================
// 度量值: _SLS Base Act
// Display Folder: Base Metrics
// 用途: SLS（净销售额）本期基础值（原值，不÷1000，不÷汇率）
// 会员筛选: 两档 is_member=0；仅 Member VIC 要求 register_date 非空且<=本度量对应期最后财月末，KEEPFILTERS 保留交集，TTL 原逻辑不变
// 依赖: a03_e2e_customer_data_m,
//       Slicer_Time_Frame_Max[Last_Fiscal_Month_Min/Max]（Step1 end period 当月）,
//       Slicer_Time_Frame_Min[TimeFrame_Min] + Slicer_Time_Frame_Max[TimeFrame_Max]（Step2 所选时间范围）,
//       Slicer_Is_Employee_Selection[IsEmployee_Code],
//       IsMemberFilter[IsMember],
//       DIM_Row_VIC_Tier
// 口径来源: 口径文档/VIC Segment.md 指标 5（Step1+Step2 分步实现，2026-09-12 修订）
// Step1+Step2 分步说明（两步时间范围不同，不能合并区间计算，分步范式参考"新客 No."度量值）:
//   - Step1（end period 框定分层买家 user_id）: data_date ∈ [Last_Fiscal_Month_Min, Last_Fiscal_Month_Max]，
//     customer_tier = 当前行 T1-T5（DIM_Row_VIC_Tier 1:N 模型关系自动传递），
//     is_member / is_employee 双重人群筛选，CALCULATETABLE(VALUES(user_id)) 框定 user_id 集合
//   - Step2（所选时间范围聚合）: data_date ∈ [TimeFrame_Min, TimeFrame_Max]，
//     TREATAS 将 Step1 的 user_id 集合传递回事实表求 SUM(net_pay_amt)，
//     移除维度表及事实表 customer_tier 筛选，包含历史其他 Tier/空 Tier 记录，统一归入期末 Tier；
//     __TierUsers 已在 Step1 固定，platform / shop_info_id 及其他原有筛选保留
// 聚合粒度: SUM(net_pay_amt)
// 注: 此处返回原值（RMB），÷1000 和 ÷汇率 在 SLS Value 中实现
// ========================================
    // ── Step 2 时间范围（所选时间范围，本期）──
    VAR __PeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Min[TimeFrame_Min])
    VAR __PeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max[TimeFrame_Max])
    // ── Step 1 时间范围（end period 当月，本期）──
    VAR __EndPeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Max[Last_Fiscal_Month_Min])
    VAR __EndPeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max[Last_Fiscal_Month_Max])
    VAR __IsMemberFilter = SELECTEDVALUE(IsMemberFilter[IsMember], 0)
    VAR __IsEmployeeFilter = VALUES(Slicer_Is_Employee_Selection[IsEmployee_Code])

    // ── Step 1: end period 当月，按当前行 customer_tier 框定 user_id 集合 ──
    VAR __TierUsers =
        CALCULATETABLE(
            VALUES('a03_e2e_customer_data_m'[user_id]),
            'a03_e2e_customer_data_m'[is_member] = 0,
            KEEPFILTERS(
                __IsMemberFilter = 0
                    || (
                        NOT ISBLANK('a03_e2e_customer_data_m'[register_date])
                            && 'a03_e2e_customer_data_m'[register_date] <= __EndPeriodMax
                    )
            ),
            'a03_e2e_customer_data_m'[is_employee] in __IsEmployeeFilter,
            'a03_e2e_customer_data_m'[data_date] >= __EndPeriodMin,
            'a03_e2e_customer_data_m'[data_date] <= __EndPeriodMax
        )

    // ── Step 2: 该 user_id 集合在所选时间范围的 sum(net_pay_amt) ──
    RETURN
        CALCULATE(
            // 先在外层解除历史 Tier；内层日期/会员筛选不再被原 Tier 提前裁剪
            CALCULATE(
                SUM('a03_e2e_customer_data_m'[net_pay_amt]),
                TREATAS(__TierUsers, 'a03_e2e_customer_data_m'[user_id]),
                'a03_e2e_customer_data_m'[is_member] = 0,
                KEEPFILTERS(
                    __IsMemberFilter = 0
                        || (
                            NOT ISBLANK('a03_e2e_customer_data_m'[register_date])
                                && 'a03_e2e_customer_data_m'[register_date] <= __EndPeriodMax
                        )
                ),
                'a03_e2e_customer_data_m'[is_employee] in __IsEmployeeFilter,
                'a03_e2e_customer_data_m'[data_date] >= __PeriodMin,
                'a03_e2e_customer_data_m'[data_date] <= __PeriodMax
            ),
            // __TierUsers 已在 Step1 按期末 Tier 固定，不会随此处移除筛选重新圈人
            REMOVEFILTERS('DIM_Row_VIC_Tier'),
            REMOVEFILTERS('a03_e2e_customer_data_m'[customer_tier])
        )
```

#### 4.1.6 _SLS Base LY（净销售额去年同期基础值，Step1+Step2 分步）

```dax
_SLS Base LY = 
// ========================================
// 度量值: _SLS Base LY
// Display Folder: Base Metrics
// 用途: SLS（净销售额）去年同期基础值（原值，不÷1000，不÷汇率）
// 会员筛选: 两档 is_member=0；仅 Member VIC 要求 register_date 非空且<=本度量对应期最后财月末，KEEPFILTERS 保留交集，TTL 原逻辑不变
// 依赖: a03_e2e_customer_data_m,
//       Slicer_Time_Frame_Max[Last_Fiscal_Month_Min_LY/Max_LY]（Step1 LY end period 当月）,
//       Slicer_Time_Frame_Min[TimeFrame_Min_LY] + Slicer_Time_Frame_Max[TimeFrame_Max_LY]（Step2 LY 所选时间范围）,
//       Slicer_Is_Employee_Selection[IsEmployee_Code],
//       IsMemberFilter[IsMember],
//       DIM_Row_VIC_Tier
// 口径来源: 口径文档/VIC Segment.md 指标 5（LY 版本，用于指标 6 YOY 分母，Step1+Step2 分步实现，2026-09-12 修订）
// Step1+Step2 分步说明（两步时间范围不同，不能合并区间计算）:
//   - Step1（LY end period 框定分层买家 user_id）: data_date ∈ [Last_Fiscal_Month_Min_LY, Last_Fiscal_Month_Max_LY]，
//     customer_tier = 当前行 T1-T5（模型自动传递），is_member / is_employee 双重人群筛选
//   - Step2（LY 所选时间范围聚合）: data_date ∈ [TimeFrame_Min_LY, TimeFrame_Max_LY]，
//     TREATAS 传递 Step1 user_id 集合，移除维度表及事实表 customer_tier 筛选，按 LY 期末 Tier 归属；其他原有筛选保留
// 时间偏移: 财历映射，直接读取 Slicer_Time_Frame_Min/Max 已预算字段，无需 EDATE
// 注: vs LY 同比值（今年/去年-1）汇率在相除时自动抵消，所以 LY 基础值不÷汇率
//     但 SLS LY 基础值也用于其他场景，保持原值（RMB）输出
// ========================================
    // ── Step 2 时间范围（所选时间范围，LY）──
    VAR __PeriodMin_LY = SELECTEDVALUE(Slicer_Time_Frame_Min[TimeFrame_Min_LY])
    VAR __PeriodMax_LY = SELECTEDVALUE(Slicer_Time_Frame_Max[TimeFrame_Max_LY])
    // ── Step 1 时间范围（end period 当月，LY）──
    VAR __EndPeriodMin_LY = SELECTEDVALUE(Slicer_Time_Frame_Max[Last_Fiscal_Month_Min_LY])
    VAR __EndPeriodMax_LY = SELECTEDVALUE(Slicer_Time_Frame_Max[Last_Fiscal_Month_Max_LY])
    VAR __IsMemberFilter = SELECTEDVALUE(IsMemberFilter[IsMember], 0)
    VAR __IsEmployeeFilter = VALUES(Slicer_Is_Employee_Selection[IsEmployee_Code])

    // ── Step 1: LY end period 当月，按当前行 customer_tier 框定 user_id 集合 ──
    VAR __TierUsers =
        CALCULATETABLE(
            VALUES('a03_e2e_customer_data_m'[user_id]),
            'a03_e2e_customer_data_m'[is_member] = 0,
            KEEPFILTERS(
                __IsMemberFilter = 0
                    || (
                        NOT ISBLANK('a03_e2e_customer_data_m'[register_date])
                            && 'a03_e2e_customer_data_m'[register_date] <= __EndPeriodMax_LY
                    )
            ),
            'a03_e2e_customer_data_m'[is_employee] in __IsEmployeeFilter,
            'a03_e2e_customer_data_m'[data_date] >= __EndPeriodMin_LY,
            'a03_e2e_customer_data_m'[data_date] <= __EndPeriodMax_LY
        )

    // ── Step 2: 该 user_id 集合在 LY 所选时间范围的 sum(net_pay_amt) ──
    RETURN
        CALCULATE(
            // 先解除历史 Tier，再在内层计算 LY 区间及会员筛选
            CALCULATE(
                SUM('a03_e2e_customer_data_m'[net_pay_amt]),
                TREATAS(__TierUsers, 'a03_e2e_customer_data_m'[user_id]),
                'a03_e2e_customer_data_m'[is_member] = 0,
                KEEPFILTERS(
                    __IsMemberFilter = 0
                        || (
                            NOT ISBLANK('a03_e2e_customer_data_m'[register_date])
                                && 'a03_e2e_customer_data_m'[register_date] <= __EndPeriodMax_LY
                        )
                ),
                'a03_e2e_customer_data_m'[is_employee] in __IsEmployeeFilter,
                'a03_e2e_customer_data_m'[data_date] >= __PeriodMin_LY,
                'a03_e2e_customer_data_m'[data_date] <= __PeriodMax_LY
            ),
            // 用户集合已按 LY 期末 Tier 固定，其他维度筛选继续保留
            REMOVEFILTERS('DIM_Row_VIC_Tier'),
            REMOVEFILTERS('a03_e2e_customer_data_m'[customer_tier])
        )
```

#### 4.1.7 _SLS Total Base Act（净销售额占比分母，逐 Tier 复用本期 Step1+Step2 并加总）

```dax
_SLS Total Base Act =
// ========================================
// 度量值: _SLS Total Base Act
// Display Folder: Base Metrics
// 用途: SLS% 分母，按外部选中 Tier 的本期销售额逐行加总
// 依赖: [_SLS Base Act], DIM_Row_VIC_Tier
// 口径来源: 口径文档/VIC Segment.md 指标 7（2026-09-22：按期末 Tier 归属）
// 筛选上下文:
//   - ALLSELECTED 保留外部 Tier 选择，排除空 Tier；无外部限制时为 T1-T5
//   - 每个 Tier 分别调用 _SLS Base Act：Step1 按本期期末 Tier 圈人，Step2 跨历史 Tier 聚合
//   - 会员、员工、注册日期、平台、门店及日期规则由基础度量继承
//   - 不先合并不同 Tier 的用户去重，保证 Total 等于选中 Tier 行值之和
// ========================================
    VAR __SelectedTiers =
        FILTER(
            ALLSELECTED('DIM_Row_VIC_Tier'),
            NOT ISBLANK('DIM_Row_VIC_Tier'[Tier ID])
        )

    RETURN
        SUMX(
            __SelectedTiers,
            // 将迭代 Tier 转为筛选上下文；基础值必须在每行重新计算，不能提前缓存
            CALCULATE([_SLS Base Act])
        )
```

#### 4.1.8 _SLS Total Base LY（净销售额占比分母，逐 Tier 复用 LY Step1+Step2 并加总）

```dax
_SLS Total Base LY =
// ========================================
// 度量值: _SLS Total Base LY
// Display Folder: Base Metrics
// 用途: SLS% 去年同期分母，按外部选中 Tier 的 LY 销售额逐行加总
// 依赖: [_SLS Base LY], DIM_Row_VIC_Tier
// 口径来源: 口径文档/VIC Segment.md 指标 7/8（2026-09-22：按 LY 期末 Tier 归属）
// 筛选上下文:
//   - ALLSELECTED 保留外部 Tier 选择，排除空 Tier；与本期分母采用相同加总方式
//   - 每个 Tier 分别调用 _SLS Base LY：按 LY 期末圈人并汇总 LY 区间，不复用本期用户
//   - LY 注册截止日及其他会员、员工、平台、门店筛选由基础度量继承
// ========================================
    VAR __SelectedTiers =
        FILTER(
            ALLSELECTED('DIM_Row_VIC_Tier'),
            NOT ISBLANK('DIM_Row_VIC_Tier'[Tier ID])
        )

    RETURN
        SUMX(
            __SelectedTiers,
            // 每个 Tier 独立执行 LY Step1+Step2，再累加行值
            CALCULATE([_SLS Base LY])
        )
```

#### 4.1.9 _Net Pay Qty Base Act（净出库件数本期基础值，Step1+Step2 分步）

```dax
_Net Pay Qty Base Act = 
// ========================================
// 度量值: _Net Pay Qty Base Act
// Display Folder: Base Metrics
// 用途: 净出库件数本期基础值（用于 AUR 分母 / UPT 分子）
// 会员筛选: 两档 is_member=0；仅 Member VIC 要求 register_date 非空且<=本度量对应期最后财月末，KEEPFILTERS 保留交集，TTL 原逻辑不变
// 依赖: a03_e2e_customer_data_m,
//       Slicer_Time_Frame_Max[Last_Fiscal_Month_Min/Max]（Step1 end period 当月）,
//       Slicer_Time_Frame_Min[TimeFrame_Min] + Slicer_Time_Frame_Max[TimeFrame_Max]（Step2 所选时间范围）,
//       Slicer_Is_Employee_Selection[IsEmployee_Code],
//       IsMemberFilter[IsMember],
//       DIM_Row_VIC_Tier
// 口径来源: 口径文档/VIC Segment.md 指标 10（AUR 分母）/ 指标 11（UPT 分子）（Step1+Step2 分步实现，2026-09-12 修订）
// Step1+Step2 分步说明（两步时间范围不同，不能合并区间计算，同 4.1.5 _SLS Base Act）:
//   - Step1（end period 框定分层买家 user_id）: data_date ∈ [Last_Fiscal_Month_Min, Last_Fiscal_Month_Max]，
//     customer_tier = 当前行 T1-T5（模型自动传递），is_member / is_employee 双重人群筛选
//   - Step2（所选时间范围聚合）: data_date ∈ [TimeFrame_Min, TimeFrame_Max]，
//     TREATAS 传递 Step1 user_id 集合求 SUM(net_pay_qty)，
//     移除维度表及事实表 customer_tier 筛选，按期末 Tier 归属；platform / shop_info_id 等原筛选保留
// 聚合粒度: SUM(net_pay_qty)
// ========================================
    // ── Step 2 时间范围（所选时间范围，本期）──
    VAR __PeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Min[TimeFrame_Min])
    VAR __PeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max[TimeFrame_Max])
    // ── Step 1 时间范围（end period 当月，本期）──
    VAR __EndPeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Max[Last_Fiscal_Month_Min])
    VAR __EndPeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max[Last_Fiscal_Month_Max])
    VAR __IsMemberFilter = SELECTEDVALUE(IsMemberFilter[IsMember], 0)
    VAR __IsEmployeeFilter = VALUES(Slicer_Is_Employee_Selection[IsEmployee_Code])

    // ── Step 1: end period 当月，按当前行 customer_tier 框定 user_id 集合 ──
    VAR __TierUsers =
        CALCULATETABLE(
            VALUES('a03_e2e_customer_data_m'[user_id]),
            'a03_e2e_customer_data_m'[is_member] = 0,
            KEEPFILTERS(
                __IsMemberFilter = 0
                    || (
                        NOT ISBLANK('a03_e2e_customer_data_m'[register_date])
                            && 'a03_e2e_customer_data_m'[register_date] <= __EndPeriodMax
                    )
            ),
            'a03_e2e_customer_data_m'[is_employee] in __IsEmployeeFilter,
            'a03_e2e_customer_data_m'[data_date] >= __EndPeriodMin,
            'a03_e2e_customer_data_m'[data_date] <= __EndPeriodMax
        )

    // ── Step 2: 该 user_id 集合在所选时间范围的 sum(net_pay_qty) ──
    RETURN
        CALCULATE(
            // 与 SLS 同口径：先解除历史 Tier，再应用区间及会员筛选
            CALCULATE(
                SUM('a03_e2e_customer_data_m'[net_pay_qty]),
                TREATAS(__TierUsers, 'a03_e2e_customer_data_m'[user_id]),
                'a03_e2e_customer_data_m'[is_member] = 0,
                KEEPFILTERS(
                    __IsMemberFilter = 0
                        || (
                            NOT ISBLANK('a03_e2e_customer_data_m'[register_date])
                                && 'a03_e2e_customer_data_m'[register_date] <= __EndPeriodMax
                        )
                ),
                'a03_e2e_customer_data_m'[is_employee] in __IsEmployeeFilter,
                'a03_e2e_customer_data_m'[data_date] >= __PeriodMin,
                'a03_e2e_customer_data_m'[data_date] <= __PeriodMax
            ),
            // 期末用户集合不变，历史其他 Tier/空 Tier 的件数一并归入期末 Tier
            REMOVEFILTERS('DIM_Row_VIC_Tier'),
            REMOVEFILTERS('a03_e2e_customer_data_m'[customer_tier])
        )
```

#### 4.1.10 _Net Pay Qty Base LY（净出库件数去年同期基础值，Step1+Step2 分步）

```dax
_Net Pay Qty Base LY = 
// ========================================
// 度量值: _Net Pay Qty Base LY
// Display Folder: Base Metrics
// 用途: 净出库件数去年同期基础值（备用，当前 YOY 指标未直接使用）
// 会员筛选: 两档 is_member=0；仅 Member VIC 要求 register_date 非空且<=本度量对应期最后财月末，KEEPFILTERS 保留交集，TTL 原逻辑不变
// 依赖: a03_e2e_customer_data_m,
//       Slicer_Time_Frame_Max[Last_Fiscal_Month_Min_LY/Max_LY]（Step1 LY end period 当月）,
//       Slicer_Time_Frame_Min[TimeFrame_Min_LY] + Slicer_Time_Frame_Max[TimeFrame_Max_LY]（Step2 LY 所选时间范围）,
//       Slicer_Is_Employee_Selection[IsEmployee_Code],
//       IsMemberFilter[IsMember],
//       DIM_Row_VIC_Tier
// 口径来源: 口径文档/VIC Segment.md 指标 10/11（LY 版本，预留扩展，Step1+Step2 分步实现，2026-09-12 修订）
// Step1+Step2 分步说明（两步时间范围不同，不能合并区间计算，同 4.1.6 _SLS Base LY）:
//   - Step1（LY end period 框定分层买家 user_id）: data_date ∈ [Last_Fiscal_Month_Min_LY, Last_Fiscal_Month_Max_LY]，
//     customer_tier = 当前行 T1-T5（模型自动传递），is_member / is_employee 双重人群筛选
//   - Step2（LY 所选时间范围聚合）: data_date ∈ [TimeFrame_Min_LY, TimeFrame_Max_LY]，
//     TREATAS 传递 Step1 user_id 集合求 SUM(net_pay_qty)，移除维度表及事实表 customer_tier 筛选，按 LY 期末 Tier 归属；其他原有筛选保留
// 时间偏移: 财历映射，直接读取 Slicer_Time_Frame_Min/Max 已预算字段，无需 EDATE
// ========================================
    // ── Step 2 时间范围（所选时间范围，LY）──
    VAR __PeriodMin_LY = SELECTEDVALUE(Slicer_Time_Frame_Min[TimeFrame_Min_LY])
    VAR __PeriodMax_LY = SELECTEDVALUE(Slicer_Time_Frame_Max[TimeFrame_Max_LY])
    // ── Step 1 时间范围（end period 当月，LY）──
    VAR __EndPeriodMin_LY = SELECTEDVALUE(Slicer_Time_Frame_Max[Last_Fiscal_Month_Min_LY])
    VAR __EndPeriodMax_LY = SELECTEDVALUE(Slicer_Time_Frame_Max[Last_Fiscal_Month_Max_LY])
    VAR __IsMemberFilter = SELECTEDVALUE(IsMemberFilter[IsMember], 0)
    VAR __IsEmployeeFilter = VALUES(Slicer_Is_Employee_Selection[IsEmployee_Code])

    // ── Step 1: LY end period 当月，按当前行 customer_tier 框定 user_id 集合 ──
    VAR __TierUsers =
        CALCULATETABLE(
            VALUES('a03_e2e_customer_data_m'[user_id]),
            'a03_e2e_customer_data_m'[is_member] = 0,
            KEEPFILTERS(
                __IsMemberFilter = 0
                    || (
                        NOT ISBLANK('a03_e2e_customer_data_m'[register_date])
                            && 'a03_e2e_customer_data_m'[register_date] <= __EndPeriodMax_LY
                    )
            ),
            'a03_e2e_customer_data_m'[is_employee] in __IsEmployeeFilter,
            'a03_e2e_customer_data_m'[data_date] >= __EndPeriodMin_LY,
            'a03_e2e_customer_data_m'[data_date] <= __EndPeriodMax_LY
        )

    // ── Step 2: 该 user_id 集合在 LY 所选时间范围的 sum(net_pay_qty) ──
    RETURN
        CALCULATE(
            // 与 SLS LY 同口径：先解除历史 Tier，再应用 LY 区间及会员筛选
            CALCULATE(
                SUM('a03_e2e_customer_data_m'[net_pay_qty]),
                TREATAS(__TierUsers, 'a03_e2e_customer_data_m'[user_id]),
                'a03_e2e_customer_data_m'[is_member] = 0,
                KEEPFILTERS(
                    __IsMemberFilter = 0
                        || (
                            NOT ISBLANK('a03_e2e_customer_data_m'[register_date])
                                && 'a03_e2e_customer_data_m'[register_date] <= __EndPeriodMax_LY
                        )
                ),
                'a03_e2e_customer_data_m'[is_employee] in __IsEmployeeFilter,
                'a03_e2e_customer_data_m'[data_date] >= __PeriodMin_LY,
                'a03_e2e_customer_data_m'[data_date] <= __PeriodMax_LY
            ),
            // 用户集合由 LY 期末确定，不复用本期 Tier 归属
            REMOVEFILTERS('DIM_Row_VIC_Tier'),
            REMOVEFILTERS('a03_e2e_customer_data_m'[customer_tier])
        )

```

#### 4.1.11 _Net Pay Order Cnt Base Act（净出库订单数本期基础值，Step1+Step2 分步）

```dax
_Net Pay Order Cnt Base Act = 
// ========================================
// 度量值: _Net Pay Order Cnt Base Act
// Display Folder: Base Metrics
// 用途: 净出库订单数本期基础值（用于 UPT 分母 / Freq. 分子）
// 会员筛选: 两档 is_member=0；仅 Member VIC 要求 register_date 非空且<=本度量对应期最后财月末，KEEPFILTERS 保留交集，TTL 原逻辑不变
// 依赖: a03_e2e_customer_data_m,
//       Slicer_Time_Frame_Max[Last_Fiscal_Month_Min/Max]（Step1 end period 当月）,
//       Slicer_Time_Frame_Min[TimeFrame_Min] + Slicer_Time_Frame_Max[TimeFrame_Max]（Step2 所选时间范围）,
//       Slicer_Is_Employee_Selection[IsEmployee_Code],
//       IsMemberFilter[IsMember],
//       DIM_Row_VIC_Tier
// 口径来源: 口径文档/VIC Segment.md 指标 11（UPT 分母）/ 指标 12（Freq. 分子）（Step1+Step2 分步实现，2026-09-12 修订）
// Step1+Step2 分步说明（两步时间范围不同，不能合并区间计算，同 4.1.5 _SLS Base Act）:
//   - Step1（end period 框定分层买家 user_id）: data_date ∈ [Last_Fiscal_Month_Min, Last_Fiscal_Month_Max]，
//     customer_tier = 当前行 T1-T5（模型自动传递），is_member / is_employee 双重人群筛选
//   - Step2（所选时间范围聚合）: data_date ∈ [TimeFrame_Min, TimeFrame_Max]，
//     TREATAS 传递 Step1 user_id 集合求 SUM(net_pay_order_cnt)，
//     移除维度表及事实表 customer_tier 筛选，按期末 Tier 归属；platform / shop_info_id 等原筛选保留
// 聚合粒度: SUM(net_pay_order_cnt)
// ========================================
    // ── Step 2 时间范围（所选时间范围，本期）──
    VAR __PeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Min[TimeFrame_Min])
    VAR __PeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max[TimeFrame_Max])
    // ── Step 1 时间范围（end period 当月，本期）──
    VAR __EndPeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Max[Last_Fiscal_Month_Min])
    VAR __EndPeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max[Last_Fiscal_Month_Max])
    VAR __IsMemberFilter = SELECTEDVALUE(IsMemberFilter[IsMember], 0)
    VAR __IsEmployeeFilter = VALUES(Slicer_Is_Employee_Selection[IsEmployee_Code])

    // ── Step 1: end period 当月，按当前行 customer_tier 框定 user_id 集合 ──
    VAR __TierUsers =
        CALCULATETABLE(
            VALUES('a03_e2e_customer_data_m'[user_id]),
            'a03_e2e_customer_data_m'[is_member] = 0,
            KEEPFILTERS(
                __IsMemberFilter = 0
                    || (
                        NOT ISBLANK('a03_e2e_customer_data_m'[register_date])
                            && 'a03_e2e_customer_data_m'[register_date] <= __EndPeriodMax
                    )
            ),
            'a03_e2e_customer_data_m'[is_employee] in __IsEmployeeFilter,
            'a03_e2e_customer_data_m'[data_date] >= __EndPeriodMin,
            'a03_e2e_customer_data_m'[data_date] <= __EndPeriodMax
        )

    // ── Step 2: 该 user_id 集合在所选时间范围的 sum(net_pay_order_cnt) ──
    RETURN
        CALCULATE(
            // 与 SLS/Qty 同口径：先解除历史 Tier，再应用区间及会员筛选
            CALCULATE(
                SUM('a03_e2e_customer_data_m'[net_pay_order_cnt]),
                TREATAS(__TierUsers, 'a03_e2e_customer_data_m'[user_id]),
                'a03_e2e_customer_data_m'[is_member] = 0,
                KEEPFILTERS(
                    __IsMemberFilter = 0
                        || (
                            NOT ISBLANK('a03_e2e_customer_data_m'[register_date])
                                && 'a03_e2e_customer_data_m'[register_date] <= __EndPeriodMax
                        )
                ),
                'a03_e2e_customer_data_m'[is_employee] in __IsEmployeeFilter,
                'a03_e2e_customer_data_m'[data_date] >= __PeriodMin,
                'a03_e2e_customer_data_m'[data_date] <= __PeriodMax
            ),
            // 期末用户集合不变，保留平台、门店等其他原筛选
            REMOVEFILTERS('DIM_Row_VIC_Tier'),
            REMOVEFILTERS('a03_e2e_customer_data_m'[customer_tier])
        )

```

#### 4.1.12 _Net Pay Order Cnt Base LY（净出库订单数去年同期基础值，Step1+Step2 分步）

```dax
_Net Pay Order Cnt Base LY = 
// ========================================
// 度量值: _Net Pay Order Cnt Base LY
// Display Folder: Base Metrics
// 用途: 净出库订单数去年同期基础值（备用，当前 YOY 指标未直接使用）
// 会员筛选: 两档 is_member=0；仅 Member VIC 要求 register_date 非空且<=本度量对应期最后财月末，KEEPFILTERS 保留交集，TTL 原逻辑不变
// 依赖: a03_e2e_customer_data_m,
//       Slicer_Time_Frame_Max[Last_Fiscal_Month_Min_LY/Max_LY]（Step1 LY end period 当月）,
//       Slicer_Time_Frame_Min[TimeFrame_Min_LY] + Slicer_Time_Frame_Max[TimeFrame_Max_LY]（Step2 LY 所选时间范围）,
//       Slicer_Is_Employee_Selection[IsEmployee_Code],
//       IsMemberFilter[IsMember],
//       DIM_Row_VIC_Tier
// 口径来源: 口径文档/VIC Segment.md 指标 11/12（LY 版本，预留扩展，Step1+Step2 分步实现，2026-09-12 修订）
// Step1+Step2 分步说明（两步时间范围不同，不能合并区间计算，同 4.1.6 _SLS Base LY）:
//   - Step1（LY end period 框定分层买家 user_id）: data_date ∈ [Last_Fiscal_Month_Min_LY, Last_Fiscal_Month_Max_LY]，
//     customer_tier = 当前行 T1-T5（模型自动传递），is_member / is_employee 双重人群筛选
//   - Step2（LY 所选时间范围聚合）: data_date ∈ [TimeFrame_Min_LY, TimeFrame_Max_LY]，
//     TREATAS 传递 Step1 user_id 集合求 SUM(net_pay_order_cnt)，移除维度表及事实表 customer_tier 筛选，按 LY 期末 Tier 归属；其他原有筛选保留
// 时间偏移: 财历映射，直接读取 Slicer_Time_Frame_Min/Max 已预算字段，无需 EDATE
// ========================================
    // ── Step 2 时间范围（所选时间范围，LY）──
    VAR __PeriodMin_LY = SELECTEDVALUE(Slicer_Time_Frame_Min[TimeFrame_Min_LY])
    VAR __PeriodMax_LY = SELECTEDVALUE(Slicer_Time_Frame_Max[TimeFrame_Max_LY])
    // ── Step 1 时间范围（end period 当月，LY）──
    VAR __EndPeriodMin_LY = SELECTEDVALUE(Slicer_Time_Frame_Max[Last_Fiscal_Month_Min_LY])
    VAR __EndPeriodMax_LY = SELECTEDVALUE(Slicer_Time_Frame_Max[Last_Fiscal_Month_Max_LY])
    VAR __IsMemberFilter = SELECTEDVALUE(IsMemberFilter[IsMember], 0)
    VAR __IsEmployeeFilter = VALUES(Slicer_Is_Employee_Selection[IsEmployee_Code])

    // ── Step 1: LY end period 当月，按当前行 customer_tier 框定 user_id 集合 ──
    VAR __TierUsers =
        CALCULATETABLE(
            VALUES('a03_e2e_customer_data_m'[user_id]),
            'a03_e2e_customer_data_m'[is_member] = 0,
            KEEPFILTERS(
                __IsMemberFilter = 0
                    || (
                        NOT ISBLANK('a03_e2e_customer_data_m'[register_date])
                            && 'a03_e2e_customer_data_m'[register_date] <= __EndPeriodMax_LY
                    )
            ),
            'a03_e2e_customer_data_m'[is_employee] in __IsEmployeeFilter,
            'a03_e2e_customer_data_m'[data_date] >= __EndPeriodMin_LY,
            'a03_e2e_customer_data_m'[data_date] <= __EndPeriodMax_LY
        )

    // ── Step 2: 该 user_id 集合在 LY 所选时间范围的 sum(net_pay_order_cnt) ──
    RETURN
        CALCULATE(
            // 先解除历史 Tier，再应用 LY 区间及会员筛选
            CALCULATE(
                SUM('a03_e2e_customer_data_m'[net_pay_order_cnt]),
                TREATAS(__TierUsers, 'a03_e2e_customer_data_m'[user_id]),
                'a03_e2e_customer_data_m'[is_member] = 0,
                KEEPFILTERS(
                    __IsMemberFilter = 0
                        || (
                            NOT ISBLANK('a03_e2e_customer_data_m'[register_date])
                                && 'a03_e2e_customer_data_m'[register_date] <= __EndPeriodMax_LY
                        )
                ),
                'a03_e2e_customer_data_m'[is_employee] in __IsEmployeeFilter,
                'a03_e2e_customer_data_m'[data_date] >= __PeriodMin_LY,
                'a03_e2e_customer_data_m'[data_date] <= __PeriodMax_LY
            ),
            // 用户集合已按 LY 期末 Tier 固定，历史订单按该归属汇总
            REMOVEFILTERS('DIM_Row_VIC_Tier'),
            REMOVEFILTERS('a03_e2e_customer_data_m'[customer_tier])
        )

```

### 4.2 对外 Value 层 — 12 个独立度量值

> SLS、SLS vs LY、SLS%、SLS% vs LY、ACV、AUR、UPT、Freq. 保留原派生公式，通过更新后的 Base 自动继承期末 Tier 归属；ACV/Freq. 的人数分母和全部 Customer 指标不变。

#### 4.2.1 Customer No. Value

```dax
Customer No. Value = 
// ========================================
// 度量值: Customer No. Value
// Display Folder: Cell Values
// 用途: 指标 1 — 买家人数（对外值）
// 依赖: [_Customer No. Base Act]
// 口径来源: 口径文档/VIC Segment.md 指标 1
// ========================================
    [_Customer No. Base Act]
```

#### 4.2.2 Customer No. vs LY Value

```dax
Customer No. vs LY Value = 
// ========================================
// 度量值: Customer No. vs LY Value
// Display Folder: Cell Values
// 用途: 指标 2 — 买家人数YOY（对外值）
// 依赖: [_Customer No. Base Act], [_Customer No. Base LY]
// 口径来源: 口径文档/VIC Segment.md 指标 2
// 计算公式: 今年 / 去年 - 1
// 边界处理: 去年为 0 或 BLANK 时返回 BLANK
// 时间偏移: 去年 = LY end period（Slicer_Time_Frame_Max Last_Fiscal_Month_*_LY 字段）
// ========================================
    VAR __Act = [_Customer No. Base Act]
    VAR __LY = [_Customer No. Base LY]

    RETURN
        IF(
            ISBLANK(__LY) || __LY = 0,
            BLANK(),
            DIVIDE(__Act, __LY) - 1
        )
```

#### 4.2.3 Customer% Value（买家人数占比）

```dax
Customer% Value = 
// ========================================
// 度量值: Customer% Value
// Display Folder: Cell Values
// 用途: 指标 3 — 买家人数占比（对外值）
// 依赖: [_Customer No. Base Act], [_Customer Total Base Act]
// 口径来源: 口径文档/VIC Segment.md 指标 3
// 计算公式: 分子 count(distinct user_id) where customer_tier=当前行 T1-T5 / 分母 count(distinct user_id) where customer_tier in T1-T5（与分子对称，Total = 五行加总）
// 边界处理: 分母为 0 或 BLANK 时返回 BLANK（DIVIDE 默认行为）
// ========================================
    DIVIDE(
        [_Customer No. Base Act],
        [_Customer Total Base Act]
    )
```

#### 4.2.4 Customer% vs LY Value

```dax
Customer% vs LY Value = 
// ========================================
// 度量值: Customer% vs LY Value
// Display Folder: Cell Values
// 用途: 指标 4 — 买家人数占比YOY（对外值）
// 依赖: [_Customer No. Base Act], [_Customer Total Base Act],
//       [_Customer No. Base LY], [_Customer Total Base LY]
// 口径来源: 口径文档/VIC Segment.md 指标 4
// 计算公式: 今年买家人数占比 - 去年买家人数占比（差值，pts 指标，展示时 ×100 转 pts）
//   今年 Customer% = _Customer No. Base Act / _Customer Total Base Act
//   去年 Customer% = _Customer No. Base LY / _Customer Total Base LY
// 边界处理: 去年% 为 0 或 BLANK 时返回 BLANK
// 时间偏移: 去年 = LY end period
// ========================================
   VAR LYCustomer =  DIVIDE([_Customer No. Base LY],[_Customer Total Base LY])
   VAR ActCustomer = DIVIDE([_Customer No. Base Act],[_Customer Total Base Act])

   RETURN
        IF(
            ISBLANK(LYCustomer),
            BLANK(),
            ActCustomer - LYCustomer
        )
```

#### 4.2.5 SLS Value（净销售额，÷1000，÷汇率）

```dax
SLS Value = 
// ========================================
// 度量值: SLS Value
// Display Folder: Cell Values
// 用途: 指标 5 — 净销售额（对外值）
// 依赖: [_SLS Base Act], Slicer_Currency_Selection[Currency_ExchangeRate]
// 口径来源: 口径文档/VIC Segment.md 指标 5
// 计算公式: Step1（end period 当月框定 user_id）+ Step2（所选时间范围 sum(net_pay_amt)）÷ 1000 ÷ __FXRate
//   - 口径文档第 125 行: 报表上看到的数值 = 实际金额 ÷ 1,000
//   - 口径文档第 127 行: currency 货币符号由币种切片器决定
//   - 货币转换规则: 数据源默认 RMB，转化为美元需要除以固定值 7（由切片器 Currency_ExchangeRate 提供）
// 边界处理: 基础值为 BLANK 时返回 BLANK
// ========================================
    VAR __FXRate = SELECTEDVALUE('Slicer_Currency_Selection'[Currency_ExchangeRate], 1)
    VAR __Base = [_SLS Base Act]

    RETURN
        IF(
            ISBLANK(__Base),
            BLANK(),
            DIVIDE(DIVIDE(__Base, __FXRate), 1000)
        )
```

#### 4.2.6 SLS vs LY Value

```dax
SLS vs LY Value = 
// ========================================
// 度量值: SLS vs LY Value
// Display Folder: Cell Values
// 用途: 指标 6 — 净销售额YOY（对外值）
// 依赖: [_SLS Base Act], [_SLS Base LY]
// 口径来源: 口径文档/VIC Segment.md 指标 6
// 计算公式: 今年 / 去年 - 1（分子分母均为 Step1+Step2 分步口径）
// 边界处理: 去年为 0 或 BLANK 时返回 BLANK
// 时间偏移: 去年 = LY Step1（LY end period 当月框定 user_id）+ LY Step2（LY 所选时间范围），见 _SLS Base LY
// 注: vs LY 同比值（今年/去年-1），汇率在相除时自动抵消，所以直接用原值（RMB）计算
// ========================================
    VAR __Act = [_SLS Base Act]
    VAR __LY = [_SLS Base LY]

    RETURN
        IF(
            ISBLANK(__LY) || __LY = 0,
            BLANK(),
            DIVIDE(__Act, __LY) - 1
        )
```

#### 4.2.7 SLS% Value（净销售额占比）

```dax
SLS% Value = 
// ========================================
// 度量值: SLS% Value
// Display Folder: Cell Values
// 用途: 指标 7 — 净销售额占比（对外值）
// 依赖: [_SLS Base Act], [_SLS Total Base Act]
// 口径来源: 口径文档/VIC Segment.md 指标 7
// 计算公式: 分子按期末 Tier 圈人后跨历史 Tier 聚合 / 分母逐个外部选中 Tier 复用分子并加总
// 边界处理: 分母为 0 或 BLANK 时返回 BLANK（DIVIDE 默认行为）
// 注: 比率类指标，分子分母同币种相除自动抵消，不除汇率
// ========================================
    DIVIDE(
        [_SLS Base Act],
        [_SLS Total Base Act]
    )
```

#### 4.2.8 SLS% vs LY Value（净销售额占比YOY，差值 pts）

```dax
SLS% vs LY Value = 
// ========================================
// 度量值: SLS% vs LY Value
// Display Folder: Cell Values
// 用途: 指标 8 — 净销售额占比YOY（对外值，差值小数，Display 中 ×100 转 pts）
// 依赖: [_SLS Base Act], [_SLS Total Base Act],
//       [_SLS Base LY], [_SLS Total Base LY]
// 口径来源: 口径文档/VIC Segment.md 指标 8
// 计算公式: 今年 - 去年（差值，展示时 ×100 转 pts）
//   今年 SLS% = _SLS Base Act / _SLS Total Base Act
//   去年 SLS% = _SLS Base LY / _SLS Total Base LY
// 边界处理: 今年或去年为 BLANK 时返回 BLANK
// 时间偏移: 去年 = LY Step1（LY end period 当月）+ LY Step2（LY 所选时间范围），分子分母同口径偏移
// 注: Value 度量返回原始差值（小数），Display 度量乘以 100 转 pts
// ========================================
    VAR __PctAct = DIVIDE([_SLS Base Act], [_SLS Total Base Act])
    VAR __PctLY = DIVIDE([_SLS Base LY], [_SLS Total Base LY])

    RETURN
        IF(
            ISBLANK(__PctAct) || ISBLANK(__PctLY),
            BLANK(),
            __PctAct - __PctLY
        )
```

#### 4.2.9 ACV Value（客单价，÷汇率）

```dax
ACV Value = 
// ========================================
// 度量值: ACV Value
// Display Folder: Cell Values
// 用途: 指标 9 — 客单价（对外值）
// 依赖: [_SLS Base Act], [_Customer No. Base Act], Slicer_Currency_Selection[Currency_ExchangeRate]
// 口径来源: 口径文档/VIC Segment.md 指标 9
// 计算公式: 分子 SLS（Step1+Step2 分步，同指标 5）/ 分母 end period 当月 count(distinct user_id)
// 货币转换: 分子 ÷ __FXRate（分母为人数，不除汇率）
// 边界处理: 分母为 0 或 BLANK 时返回 BLANK（DIVIDE 默认行为）
// 注: ACV 不再 ÷1000（口径文档 ACV 数据格式为 currency #,##0，未要求 ÷1000，与 SLS 不同）
// ========================================
    VAR __FXRate = SELECTEDVALUE('Slicer_Currency_Selection'[Currency_ExchangeRate], 1)
    VAR __SLS = [_SLS Base Act]
    VAR __CustomerNo = [_Customer No. Base Act]

    RETURN
        IF(
            ISBLANK(__SLS) || ISBLANK(__CustomerNo) || __CustomerNo = 0,
            BLANK(),
            DIVIDE(DIVIDE(__SLS, __FXRate), __CustomerNo)
        )
```

#### 4.2.10 AUR Value（件单价，÷汇率）

```dax
AUR Value = 
// ========================================
// 度量值: AUR Value
// Display Folder: Cell Values
// 用途: 指标 10 — 件单价（对外值）
// 依赖: [_SLS Base Act], [_Net Pay Qty Base Act], Slicer_Currency_Selection[Currency_ExchangeRate]
// 口径来源: 口径文档/VIC Segment.md 指标 10
// 计算公式: 分子 Step1+Step2 分步 sum(net_pay_amt) / 分母 Step1+Step2 分步 sum(net_pay_qty)（两分子分母共享同一 Step1 user_id 集合）
// 货币转换: 分子 ÷ __FXRate（分母为件数，不除汇率）
// 边界处理: 分母为 0 或 BLANK 时返回 BLANK（DIVIDE 默认行为）
// ========================================
    VAR __FXRate = SELECTEDVALUE('Slicer_Currency_Selection'[Currency_ExchangeRate], 1)
    VAR __SLS = [_SLS Base Act]
    VAR __Qty = [_Net Pay Qty Base Act]

    RETURN
        IF(
            ISBLANK(__SLS) || ISBLANK(__Qty) || __Qty = 0,
            BLANK(),
            DIVIDE(DIVIDE(__SLS, __FXRate), __Qty)
        )
```

#### 4.2.11 UPT Value（客单件）

```dax
UPT Value = 
// ========================================
// 度量值: UPT Value
// Display Folder: Cell Values
// 用途: 指标 11 — 客单件（对外值）
// 依赖: [_Net Pay Qty Base Act], [_Net Pay Order Cnt Base Act]
// 口径来源: 口径文档/VIC Segment.md 指标 11
// 计算公式: 分子 Step1+Step2 分步 sum(net_pay_qty) / 分母 Step1+Step2 分步 sum(net_pay_order_cnt)（两分子分母共享同一 Step1 user_id 集合）
// 边界处理: 分母为 0 或 BLANK 时返回 BLANK（DIVIDE 默认行为）
// 注: 数量类比值，不除汇率
// ========================================
    DIVIDE(
        [_Net Pay Qty Base Act],
        [_Net Pay Order Cnt Base Act]
    )
```

#### 4.2.12 Freq. Value（购买频次）

```dax
Freq. Value = 
// ========================================
// 度量值: Freq. Value
// Display Folder: Cell Values
// 用途: 指标 12 — 购买频次（对外值）
// 依赖: [_Net Pay Order Cnt Base Act], [_Customer No. Base Act]
// 口径来源: 口径文档/VIC Segment.md 指标 12
// 计算公式: 分子 Step1+Step2 分步 sum(net_pay_order_cnt) / 分母 end period 当月 count(distinct user_id)
// 边界处理: 分母为 0 或 BLANK 时返回 BLANK（DIVIDE 默认行为）
// 注: 数量类比值，不除汇率
// ========================================
    DIVIDE(
        [_Net Pay Order Cnt Base Act],
        [_Customer No. Base Act]
    )
```

### 4.3 对外 Display 层 — 12 个独立度量值

> 严格遵循口径文档数据格式定义：
>
> - integer → `#,##0`（千分位整数）
> - percent_1dp → `#,##0.0%`（百分比一位小数，不含正号）
> - currency → `__CurrencySymbol & FORMAT(__Value, "#,##0")`（拼接货币符号）
> - integer_pts → `FORMAT(__Value * 100, "#,##0pts;-#,##0pts;0pts")`（不含正号）
> - decimal_1dp → `#,##0.0`（小数一位，千分位）
>
> BLANK 显示为 "-"。

#### 4.3.1 Customer No. Display

```dax
Customer No. Display = 
// ========================================
// 度量值: Customer No. Display
// Display Folder: Formatting
// 用途: 指标 1 — 买家人数（格式化显示）
// 依赖: [Customer No. Value]
// 数据格式: integer → #,##0
// ========================================
    VAR __Value = [Customer No. Value]
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            FORMAT(__Value, "#,##0")
        )
```

#### 4.3.2 Customer No. vs LY Display

```dax
Customer No. vs LY Display = 
// ========================================
// 度量值: Customer No. vs LY Display
// Display Folder: Formatting
// 用途: 指标 2 — 买家人数YOY（格式化显示）
// 依赖: [Customer No. vs LY Value]
// 数据格式: percent_1dp → #,##0.0%（不含正号）
// 注: 口径文档明确定义为 #,##0.0%，不含正号
// ========================================
    VAR __Value = [Customer No. vs LY Value]
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            FORMAT(__Value, "#,##0.0%")
        )
```

#### 4.3.3 Customer% Display

```dax
Customer% Display = 
// ========================================
// 度量值: Customer% Display
// Display Folder: Formatting
// 用途: 指标 3 — 买家人数占比（格式化显示）
// 依赖: [Customer% Value]
// 数据格式: percent_1dp → #,##0.0%（不含正号）
// ========================================
    VAR __Value = [Customer% Value]
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            FORMAT(__Value, "#,##0.0%")
        )
```

#### 4.3.4 Customer% vs LY Display

```dax
Customer% vs LY Display = 
// ========================================
// 度量值: Customer% vs LY Display
// Display Folder: Formatting
// 用途: 指标 4 — 买家人数占比YOY（格式化显示）
// 依赖: [Customer% vs LY Value]
// 数据格式: integer_pts → #,##0pts;-#,##0pts;0pts（不含正号）
// 注: 口径文档指标 4 明确定义为差值 pts 格式（当期值 − 同期值，展示时 ×100 转 pts），不含正号
// ========================================
    VAR __Value = [Customer% vs LY Value]
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            FORMAT(__Value * 100, "#,##0pts;-#,##0pts;0pts")
        )
```

#### 4.3.5 SLS Display

```dax
SLS Display = 
// ========================================
// 度量值: SLS Display
// Display Folder: Formatting
// 用途: 指标 5 — 净销售额（格式化显示）
// 依赖: [SLS Value], Slicer_Currency_Selection[Currency_Symbol]
// 数据格式: currency → __CurrencySymbol & FORMAT(__Value, "#,##0")
// 注: 口径文档第 128 行明确"在 DAX 中用 __CurrencySymbol & FORMAT(__Value, "#,##0") 拼接币种符号"
// ========================================
    VAR __Value = [SLS Value]
    VAR __CurrencySymbol = SELECTEDVALUE('Slicer_Currency_Selection'[Currency_Symbol], "¥")
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            __CurrencySymbol & FORMAT(__Value, "#,##0")
        )
```

#### 4.3.6 SLS vs LY Display

```dax
SLS vs LY Display = 
// ========================================
// 度量值: SLS vs LY Display
// Display Folder: Formatting
// 用途: 指标 6 — 净销售额YOY（格式化显示）
// 依赖: [SLS vs LY Value]
// 数据格式: percent_1dp → #,##0.0%（不含正号）
// 注: 口径文档明确定义为 #,##0.0%，不含正号
// ========================================
    VAR __Value = [SLS vs LY Value]
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            FORMAT(__Value, "#,##0.0%")
        )
```

#### 4.3.7 SLS% Display

```dax
SLS% Display = 
// ========================================
// 度量值: SLS% Display
// Display Folder: Formatting
// 用途: 指标 7 — 净销售额占比（格式化显示）
// 依赖: [SLS% Value]
// 数据格式: percent_1dp → #,##0.0%（不含正号）
// ========================================
    VAR __Value = [SLS% Value]
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            FORMAT(__Value, "#,##0.0%")
        )
```

#### 4.3.8 SLS% vs LY Display

```dax
SLS% vs LY Display = 
// ========================================
// 度量值: SLS% vs LY Display
// Display Folder: Formatting
// 用途: 指标 8 — 净销售额占比YOY（格式化显示）
// 依赖: [SLS% vs LY Value]
// 数据格式: integer_pts → #,##0pts;-#,##0pts;0pts（不含正号）
// 转换: Value（小数差值）× 100 转 pts
// 注: 口径文档第 177 行明确"直接使用 FORMAT(__Value * 100, "#,##0pts;-#,##0pts;0pts")"
// ========================================
    VAR __Value = [SLS% vs LY Value]
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            FORMAT(__Value * 100, "#,##0pts;-#,##0pts;0pts")
        )
```

#### 4.3.9 ACV Display

```dax
ACV Display = 
// ========================================
// 度量值: ACV Display
// Display Folder: Formatting
// 用途: 指标 9 — 客单价（格式化显示）
// 依赖: [ACV Value], Slicer_Currency_Selection[Currency_Symbol]
// 数据格式: currency → __CurrencySymbol & FORMAT(__Value, "#,##0")
// ========================================
    VAR __Value = [ACV Value]
    VAR __CurrencySymbol = SELECTEDVALUE('Slicer_Currency_Selection'[Currency_Symbol], "¥")
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            __CurrencySymbol & FORMAT(__Value, "#,##0")
        )
```

#### 4.3.10 AUR Display

```dax
AUR Display = 
// ========================================
// 度量值: AUR Display
// Display Folder: Formatting
// 用途: 指标 10 — 件单价（格式化显示）
// 依赖: [AUR Value], Slicer_Currency_Selection[Currency_Symbol]
// 数据格式: currency → __CurrencySymbol & FORMAT(__Value, "#,##0")
// ========================================
    VAR __Value = [AUR Value]
    VAR __CurrencySymbol = SELECTEDVALUE('Slicer_Currency_Selection'[Currency_Symbol], "¥")
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            __CurrencySymbol & FORMAT(__Value, "#,##0")
        )
```

#### 4.3.11 UPT Display

```dax
UPT Display = 
// ========================================
// 度量值: UPT Display
// Display Folder: Formatting
// 用途: 指标 11 — 客单件（格式化显示）
// 依赖: [UPT Value]
// 数据格式: integer → #,##0
// ========================================
    VAR __Value = [UPT Value]
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            FORMAT(__Value, "#,##0")
        )
```

#### 4.3.12 Freq. Display

```dax
Freq. Display = 
// ========================================
// 度量值: Freq. Display
// Display Folder: Formatting
// 用途: 指标 12 — 购买频次（格式化显示）
// 依赖: [Freq. Value]
// 数据格式: decimal_1dp → #,##0.0
// ========================================
    VAR __Value = [Freq. Value]
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            FORMAT(__Value, "#,##0.0")
        )
```

### 4.4 对外 SVG图像 — 2 个独立度量值

> 额外补充的度量

#### 4.4.1 Customer% vs LY Value Cell SVG Icon

```dax
Customer% vs LY Value Cell SVG Icon =
// ========================================
// 度量值: Customer% vs LY Value Cell SVG Icon
// Display Folder: Formatting
// 用途: 仅 Customer% vs LY Value 指标返回 SVG 圆形图标，其余返回 BLANK
// 配置: 需将此度量值的数据类别设为"图像 URL"
//
// 圆形里面带箭头图标规则：
//   正值（>0）→ 绿色圆形 #1A9018
//   负值（<0）→ 红色圆形 #D64550
//   零值（=0）→ 黄色圆形 #E1C233
// 依赖: [Customer% vs LY Value]
// ========================================

    VAR __Value  = [Customer% vs LY Value]

    // ── SVG 图标定义 ──
    VAR __GreenSVG =
        "data:image/svg+xml;utf8," &
        "<svg xmlns='http://www.w3.org/2000/svg' width='16' height='16'>" &
        "<circle cx='8' cy='8' r='7' fill='%234CAF50'/>" &
        "<path d='M8 12 L8 5 M5 7 L8 4 L11 7' stroke='white' stroke-width='1.8' stroke-linecap='round' stroke-linejoin='round' fill='none'/>" &
        "</svg>"
    VAR __RedSVG =
        "data:image/svg+xml;utf8," &
        "<svg xmlns='http://www.w3.org/2000/svg' width='16' height='16'>" &
        "<circle cx='8' cy='8' r='7' fill='%23F44336'/>" &
        "<path d='M8 4 L8 11 M5 9 L8 12 L11 9' stroke='white' stroke-width='1.8' stroke-linecap='round' stroke-linejoin='round' fill='none'/>" &
        "</svg>"
    VAR __YellowSVG =
        "data:image/svg+xml;utf8," &
        "<svg xmlns='http://www.w3.org/2000/svg' width='16' height='16'>" &
        "<circle cx='8' cy='8' r='7' fill='%23FF9800'/>" &
        "<path d='M4.5 8 L11.5 8' stroke='white' stroke-width='1.8' stroke-linecap='round' stroke-linejoin='round' fill='none'/>" &
        "</svg>"

    RETURN
        SWITCH(
            TRUE(),
            ISBLANK(__Value),    BLANK(),
            __Value > 0,         __GreenSVG,
            __Value < 0,         __RedSVG,
            __Value = 0,         __YellowSVG,
            BLANK()
        )
```

#### 4.4.2 SLS% vs LY Value Cell SVG Icon

```dax
SLS% vs LY Value Cell SVG Icon =
// ========================================
// 度量值: SLS% vs LY Value Cell SVG Icon
// Display Folder: Formatting
// 用途: 仅 SLS% vs LY Value 指标返回 SVG 圆形图标，其余返回 BLANK
// 配置: 需将此度量值的数据类别设为"图像 URL"
//
// 圆形里面带箭头图标规则：
//   正值（>0）→ 绿色圆形 #1A9018
//   负值（<0）→ 红色圆形 #D64550
//   零值（=0）→ 黄色圆形 #E1C233
// 依赖: [SLS% vs LY Value]
// ========================================

    VAR __Value  = [SLS% vs LY Value]

    // ── SVG 图标定义 ──
    VAR __GreenSVG =
        "data:image/svg+xml;utf8," &
        "<svg xmlns='http://www.w3.org/2000/svg' width='16' height='16'>" &
        "<circle cx='8' cy='8' r='7' fill='%234CAF50'/>" &
        "<path d='M8 12 L8 5 M5 7 L8 4 L11 7' stroke='white' stroke-width='1.8' stroke-linecap='round' stroke-linejoin='round' fill='none'/>" &
        "</svg>"
    VAR __RedSVG =
        "data:image/svg+xml;utf8," &
        "<svg xmlns='http://www.w3.org/2000/svg' width='16' height='16'>" &
        "<circle cx='8' cy='8' r='7' fill='%23F44336'/>" &
        "<path d='M8 4 L8 11 M5 9 L8 12 L11 9' stroke='white' stroke-width='1.8' stroke-linecap='round' stroke-linejoin='round' fill='none'/>" &
        "</svg>"
    VAR __YellowSVG =
        "data:image/svg+xml;utf8," &
        "<svg xmlns='http://www.w3.org/2000/svg' width='16' height='16'>" &
        "<circle cx='8' cy='8' r='7' fill='%23FF9800'/>" &
        "<path d='M4.5 8 L11.5 8' stroke='white' stroke-width='1.8' stroke-linecap='round' stroke-linejoin='round' fill='none'/>" &
        "</svg>"

    RETURN
        SWITCH(
            TRUE(),
            ISBLANK(__Value),    BLANK(),
            __Value > 0,         __GreenSVG,
            __Value < 0,         __RedSVG,
            __Value = 0,         __YellowSVG,
            BLANK()
        )
```

---

## 5. 度量值清单与 Display Folder

| 序号 | 度量值名称                  | Display Folder | 用途                                                              |
| ---- | --------------------------- | -------------- | ----------------------------------------------------------------- |
| 1    | _Customer No. Base Act      | Base Metrics   | 买家人数本期基础值（私有，供派生调用）                            |
| 2    | _Customer No. Base LY       | Base Metrics   | 买家人数去年同期基础值（私有，YOY 分母用）                        |
| 3    | _Customer Total Base Act    | Base Metrics   | 买家人数占比分母本期基础值（私有，tier 全量，与分子对称）         |
| 4    | _Customer Total Base LY     | Base Metrics   | 买家人数占比分母去年同期基础值（私有，tier 全量，与分子对称）     |
| 5    | _SLS Base Act               | Base Metrics   | 净销售额本期基础值（私有，Step1+Step2 分步，原值不÷1000）        |
| 6    | _SLS Base LY                | Base Metrics   | 净销售额去年同期基础值（私有，Step1+Step2 分步）                  |
| 7    | _SLS Total Base Act         | Base Metrics   | 净销售额占比分母本期基础值（逐 Tier 复用分子，SUMX 加总）         |
| 8    | _SLS Total Base LY          | Base Metrics   | 净销售额占比分母去年同期基础值（逐 Tier 复用 LY 分子，SUMX 加总） |
| 9    | _Net Pay Qty Base Act       | Base Metrics   | 净出库件数本期基础值（私有，Step1+Step2 分步）                    |
| 10   | _Net Pay Qty Base LY        | Base Metrics   | 净出库件数去年同期基础值（私有，Step1+Step2 分步，预留扩展）      |
| 11   | _Net Pay Order Cnt Base Act | Base Metrics   | 净出库订单数本期基础值（私有，Step1+Step2 分步）                  |
| 12   | _Net Pay Order Cnt Base LY  | Base Metrics   | 净出库订单数去年同期基础值（私有，Step1+Step2 分步，预留扩展）    |
| 13   | Customer No. Value          | Cell Values    | 指标 1 对外值                                                     |
| 14   | Customer No. vs LY Value    | Cell Values    | 指标 2 对外值                                                     |
| 15   | Customer% Value             | Cell Values    | 指标 3 对外值                                                     |
| 16   | Customer% vs LY Value       | Cell Values    | 指标 4 对外值（差值小数，Display ×100 转 pts）                   |
| 17   | SLS Value                   | Cell Values    | 指标 5 对外值（÷1000，÷汇率）                                   |
| 18   | SLS vs LY Value             | Cell Values    | 指标 6 对外值                                                     |
| 19   | SLS% Value                  | Cell Values    | 指标 7 对外值                                                     |
| 20   | SLS% vs LY Value            | Cell Values    | 指标 8 对外值（差值小数，Display ×100 转 pts）                   |
| 21   | ACV Value                   | Cell Values    | 指标 9 对外值（÷汇率）                                           |
| 22   | AUR Value                   | Cell Values    | 指标 10 对外值（÷汇率）                                          |
| 23   | UPT Value                   | Cell Values    | 指标 11 对外值                                                    |
| 24   | Freq. Value                 | Cell Values    | 指标 12 对外值                                                    |
| 25   | Customer No. Display        | Formatting     | 指标 1 格式化显示（#,##0）                                        |
| 26   | Customer No. vs LY Display  | Formatting     | 指标 2 格式化显示（#,##0.0%）                                     |
| 27   | Customer% Display           | Formatting     | 指标 3 格式化显示（#,##0.0%）                                     |
| 28   | Customer% vs LY Display     | Formatting     | 指标 4 格式化显示（#,##0pts;-#,##0pts;0pts）                      |
| 29   | SLS Display                 | Formatting     | 指标 5 格式化显示（货币符号 + #,##0）                             |
| 30   | SLS vs LY Display           | Formatting     | 指标 6 格式化显示（#,##0.0%）                                     |
| 31   | SLS% Display                | Formatting     | 指标 7 格式化显示（#,##0.0%）                                     |
| 32   | SLS% vs LY Display          | Formatting     | 指标 8 格式化显示（#,##0pts;-#,##0pts;0pts）                      |
| 33   | ACV Display                 | Formatting     | 指标 9 格式化显示（货币符号 + #,##0）                             |
| 34   | AUR Display                 | Formatting     | 指标 10 格式化显示（货币符号 + #,##0）                            |
| 35   | UPT Display                 | Formatting     | 指标 11 格式化显示（#,##0）                                       |
| 36   | Freq. Display               | Formatting     | 指标 12 格式化显示（#,##0.0）                                     |

---

## 6. 血缘关系图

```
┌─────────────────────────────────────────────────────────────────────┐
│                        数据源层                                      │
│  a03_e2e_customer_data_m（月度事实表）                               │
│  字段: data_date, platform, shop_info_id, user_id, is_member,       │
│        is_employee, customer_tier, net_pay_amt, net_pay_qty,        │
│        net_pay_order_cnt, register_date                             │
│                                                                     │
│  DIM_Row_VIC_Tier（1:N 维度表，Row Label 行标签）                │
│  与 a03_e2e_customer_data_m[customer_tier] 1:N 关系                 │
│                                                                     │
│  Slicer_Time_Frame_Min / Slicer_Time_Frame_Max（断开日期维度表）    │
│  Step1: Last_Fiscal_Month_Min/Max（end period 当月）及 LY 偏移      │
│  Step2: TimeFrame_Min/Max（所选时间范围）及 LY 偏移                │
└──────────────────────────────┬──────────────────────────────────────┘
                               │
                               │ 模型自动传递（行维度 = DIM_Row_VIC_Tier[Row Label]）
                               │ + platform / shop_info_id 事实表字段直接拉取
                               │ 人数与 Step1 保留期末 tier；SUM 类 Step2 移除历史 tier
                               │ SLS 分母 SUMX + ALLSELECTED 逐 Tier 复用分子加总
                               ▼
┌─────────────────────────────────────────────────────────────────────┐
│                        度量值层                                      │
│                                                                     │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │  内部基础层（Base Metrics，私有）                           │    │
│  │  ┌──────────────────────┐  ┌──────────────────────┐         │    │
│  │  │ _Customer No.        │  │ _Customer No.        │         │    │
│  │  │ Base Act             │  │ Base LY              │         │    │
│  │  │ DISTINCTCOUNT, 本期  │  │ DISTINCTCOUNT, LY    │         │    │
│  │  └──────────┬───────────┘  └──────────┬───────────┘         │    │
│  │  ┌──────────────────────┐  ┌──────────────────────┐         │    │
│  │  │ _Customer Total      │  │ _Customer Total      │         │    │
│  │  │ Base Act             │  │ Base LY              │         │    │
│  │  │ tier全量对称, 本期    │  │ tier全量对称, LY      │         │    │
│  │  └──────────┬───────────┘  └──────────┬───────────┘         │    │
│  │  ┌──────────────────────┐  ┌──────────────────────┐         │    │
│  │  │ _SLS Base Act        │  │ _SLS Base LY         │         │    │
│  │  │ Step1+Step2, 本期    │  │ Step1+Step2, LY      │         │    │
│  │  └──────────┬───────────┘  └──────────┬───────────┘         │    │
│  │  ┌──────────────────────┐  ┌──────────────────────┐         │    │
│  │  │ _SLS Total Base Act  │  │ _SLS Total Base LY   │         │    │
│  │  │ 逐Tier复用+加总,    │  │ 逐Tier复用+加总,    │         │    │
│  │  │ 本期                 │  │ LY                   │         │    │
│  │  └──────────┬───────────┘  └──────────┬───────────┘         │    │
│  │  ┌──────────────────────┐  ┌──────────────────────┐         │    │
│  │  │ _Net Pay Qty        │  │ _Net Pay Qty         │         │    │
│  │  │ Base Act(Step1+2)   │  │ Base LY(Step1+2)     │         │    │
│  │  └──────────┬───────────┘  └──────────┬───────────┘         │    │
│  │  ┌──────────────────────┐  ┌──────────────────────┐         │    │
│  │  │ _Net Pay Order Cnt  │  │ _Net Pay Order Cnt   │         │    │
│  │  │ Base Act(Step1+2)   │  │ Base LY(Step1+2)     │         │    │
│  │  └──────────┬───────────┘  └──────────┬───────────┘         │    │
│  └─────────────┼──────────────────────────┼─────────────────────┘    │
│                │                          │                          │
│                ▼                          ▼                          │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │  对外 Value 层（Cell Values，12 个独立度量值）             │    │
│  │  Customer No. Value       ← _Customer No. Base Act          │    │
│  │  Customer No. vs LY Value ← 今年/去年-1                      │    │
│  │  Customer% Value          ← DIVIDE(No. Act, Total Act)       │    │
│  │  Customer% vs LY Value    ← 今年%/去年%-1                    │    │
│  │  SLS Value                ← _SLS Base Act ÷ FXRate ÷ 1000    │    │
│  │  SLS vs LY Value          ← 今年/去年-1                      │    │
│  │  SLS% Value               ← DIVIDE(SLS Act, SLS Total Act)  │    │
│  │  SLS% vs LY Value         ← 今年%-去年%（差值）              │    │
│  │  ACV Value                ← DIVIDE(SLS Act ÷ FXRate, No.)   │    │
│  │  AUR Value                ← DIVIDE(SLS Act ÷ FXRate, Qty)   │    │
│  │  UPT Value                ← DIVIDE(Qty, OrderCnt)           │    │
│  │  Freq. Value              ← DIVIDE(OrderCnt, No.)            │    │
│  └─────────────┬───────────────────────────────────────────────┘    │
│                │                                                    │
│                ▼                                                    │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │  对外 Display 层（Formatting，12 个独立度量值）            │    │
│  │  Customer No. Display          → #,##0                       │    │
│  │  Customer No. vs LY Display    → #,##0.0%                    │    │
│  │  Customer% Display             → #,##0.0%                    │    │
│  │  Customer% vs LY Display       → #,##0pts;-#,##0pts;0pts     │    │
│  │  SLS Display                   → ¥/# + #,##0                 │    │
│  │  SLS vs LY Display             → #,##0.0%                    │    │
│  │  SLS% Display                  → #,##0.0%                    │    │
│  │  SLS% vs LY Display            → #,##0pts;-#,##0pts;0pts     │    │
│  │  ACV Display                   → ¥/# + #,##0                │    │
│  │  AUR Display                   → ¥/# + #,##0                │    │
│  │  UPT Display                   → #,##0                       │    │
│  │  Freq. Display                 → #,##0.0                     │    │
│  └─────────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────────┐
│                        可视化层                                      │
│  Table 视觉对象（非 Matrix）                                        │
│  行: DIM_Row_VIC_Tier[Row Label]（+ 可选 platform / shop_info_id）  │
│  值: 12 对独立 Value/Display 度量值（无 x 轴，无 SWITCH 路由）     │
│  说明: 指标 0（Tier）= 行维度字段本身，不需要度量值                  │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 7. 注意事项

1. **两套时间范围筛选（关键逻辑，2026-09-12 修订）**：SLS 类指标（指标 5/7/9/10/11/12）分两套时间范围——Step 1 用 `Slicer_Time_Frame_Max[Last_Fiscal_Month_Min]` ~ `[Last_Fiscal_Month_Max]`（end period 当月，框定 user_id），Step 2 用 `Slicer_Time_Frame_Min[TimeFrame_Min]` ~ `Slicer_Time_Frame_Max[TimeFrame_Max]`（所选时间范围，聚合）；LY 版本分别用 `Last_Fiscal_Month_*_LY` 与 `TimeFrame_Min_LY/TimeFrame_Max_LY`。Customer 类指标（指标 1~4 及 ACV/Freq. 的人数分母）仍为单步 end period 当月口径；指标 6 为 SLS 同比，继承双步计算。这些字段已由 Slicer_Time_Frame_Min/Max 日期维度表预算，无需在 DAX 中重复实现。
2. **is_member / is_employee 双重筛选（关键逻辑）**：保留 `SELECTEDVALUE(IsMemberFilter[IsMember], 0)` 作为会员模式开关；事实表两档均筛 `is_member = 0`。TTL VIC 不追加注册日期限制；Member VIC 通过 `KEEPFILTERS` 追加 `register_date 非空且 <= 对应本期/LY 最后财月末`，单步计算及 Step1/Step2 均生效，继续与已有注册日期筛选取交集。员工筛选继续使用 `VALUES(Slicer_Is_Employee_Selection[IsEmployee_Code])` 配合 `in`，不改变原行为。
3. **分组维度自动传递（关键逻辑）**：

   - `customer_tier` 通过 DIM_Row_VIC_Tier 的 1:N 关系影响人数与 SUM 类 Step1，确定期末分层用户
   - SUM 类 Step2 显式移除维度表及事实表 Tier 筛选，只按已固定用户集合聚合历史记录
   - `platform`、`shop_info_id` 直接拉取事实表字段，两步均保留原筛选
4. **指标 0 不需要度量值**：Tier 是行维度本身（`DIM_Row_VIC_Tier[Row Label]` 字段直接拉取，图片展示行标签），不需要 Value/Display 度量值。本方案只对指标 1~12 输出度量值。
5. **期末 Tier 归属（关键逻辑）**：Step1 保留当前行 Tier，先用 `CALCULATETABLE(VALUES(user_id), ...)` 固定期末用户集合；Step2 使用 `TREATAS(__TierUsers, a03_e2e_customer_data_m[user_id])`，同时移除 DIM_Row_VIC_Tier 及事实表 customer_tier 筛选，在 TimeFrame 区间聚合。历史其他 Tier 或空 Tier 记录也计入期末 Tier；各行仍由不同的期末用户集合区分，不会因 Step2 移除 Tier 自动变为全量。不得在基础度量外层移除 Tier，也不得移除整张事实表筛选。会员、员工、平台、门店与日期规则均保留，Member VIC 两步仍要求注册日期非空且不晚于对应期末。
6. **SLS ÷ 1000（关键逻辑）**：口径文档第 125 行明确"报表上看到的数值 = 实际金额 ÷ 1,000"。SLS Value 度量值中 `DIVIDE(DIVIDE(__Base, __FXRate), 1000)`，先÷汇率再÷1000。Display 格式化为 `#,##0`（不再拼接 "k"），严格遵循口径文档数据格式。
7. **货币符号与汇率（关键逻辑）**：

   - 金额类指标（SLS / ACV / AUR）使用 `Slicer_Currency_Selection` 切片器
   - 汇率字段：`Slicer_Currency_Selection[Currency_ExchangeRate]`，默认 1
   - 货币符号字段：`Slicer_Currency_Selection[Currency_Symbol]`，默认 "¥"
   - Value 度量值中 `DIVIDE(SUM(net_pay_amt), __FXRate)` 做汇率换算
   - Display 度量值中 `__CurrencySymbol & FORMAT(__Value, "#,##0")` 拼接货币符号
   - 参考实现：Member/Customer_Member_Indicator.md
8. **ACV / AUR 不÷1000**：口径文档 ACV / AUR 数据格式为 `#,##0`（currency），未要求 ÷1000，与 SLS (in K) 不同。ACV / AUR Value 度量值只÷汇率，不÷1000。
9. **占比类分母与外部 Tier 选择**：Customer Total 维持原 end period DISTINCTCOUNT + ALLSELECTED；SLS Total 用 `SUMX(FILTER(ALLSELECTED('DIM_Row_VIC_Tier'), NOT ISBLANK([Tier ID])), CALCULATE([_SLS Base Act/LY]))` 逐个选中 Tier 复用基础度量后加总（Act/LY 分别引用自身度量，详见 4.1.7/4.1.8）。外部 Tier 切片器限定期末人群，Step2 仍包含这些用户的其他历史 Tier/空 Tier 记录。即使同一用户期末存在多个 Tier，也按 SQL 的 DISTINCT(customer_tier,user_id) 在各 Tier 计算后加总，不先合并去重。迭代最多 5 个 Tier，可能比单次合并用户聚合增加查询次数，实际性能需在模型中验收。
10. **YOY 派生的"去年"定义（关键逻辑）**：

    - Customer No. vs LY / SLS vs LY: 今年 / 去年 - 1（百分比变化，percent_1dp 不含正号）
    - Customer% vs LY: 今年 - 去年（差值，×100 转 pts，integer_pts 不含正号）
    - SLS % vs LY: 今年 - 去年（差值，×100 转 pts，integer_pts 不含正号）
    - "去年"：Customer 类指标采用 LY end period 当月偏移（`Last_Fiscal_Month_Min_LY/Max_LY`）；SLS 类指标采用 LY Step1（`Last_Fiscal_Month_*_LY` 框定 user_id）+ LY Step2（`TimeFrame_Min_LY/TimeFrame_Max_LY` 所选时间范围聚合）双区间偏移
11. **YOY 数据格式不含正号（关键差异）**：口径文档指标 2 / 6 数据格式为 `#,##0.0%`（percent_1dp，不含正号），指标 4 / 8 数据格式为 `#,##0pts;-#,##0pts;0pts`（integer_pts，差值 ×100 转 pts，不含正号）。本方案严格遵循口径文档，所有 YOY Display 不含正号。这与参考文件 LY_Last_Purchase_Time_Table.md 的 YOY 处理一致。
12. **SLS % vs LY 的 pts 转换**：口径文档第 177 行明确"直接使用 FORMAT(__Value * 100, "#,##0pts;-#,##0pts;0pts")"。Value 度量返回原始差值（小数），Display 度量乘以 100 转 pts。
13. **分母为零或 BLANK 处理**：

    - DIVIDE 默认分母为 0/BLANK 时返回 BLANK，Display 显示 "-"
    - YOY 类指标显式判断去年值为 0/BLANK 时返回 BLANK（避免除零错误）
    - SLS% vs LY 判断今年或去年为 BLANK 时返回 BLANK
14. **私有基础层度量值命名约定**：内部基础层度量值以 `_` 下划线前缀命名（如 `_Customer No. Base Act`），放 Base Metrics 文件夹，供对外 Value 层调用，避免重复代码。对外暴露的是 12 对 Value/Display 度量值，符合"独立输出每个指标的 Value 和 Display 度量"的要求。
15. **无 SWITCH 路由**：与参考文件 VIC_KPIs_Table.md 的矩阵 SWITCH 路由范式不同，本方案为表格视觉，每个指标独立度量值，无 Metric_ID 路由，无 REMOVEFILTERS(Dim_ColMetric) 机制（SLS% 分母的 ALLSELECTED('DIM_Row_VIC_Tier') 是移除行上下文 customer_tier 分组以算全量分母，与 SWITCH 路由无关），无列维度表依赖。度量值结构更简单直接。
16. **无 x 轴时间处理**：表格视觉无列维度，不需要处理 x 轴上的当前时间。各行以 end period customer_tier 归属，SUM 类 Step2 移除历史 Tier 限制；platform / shop_info_id 筛选保持。Step1 end period / Step2 所选时间范围两套日期由 Slicer_Time_Frame_Min/Max 统一提供。
17. **预留 LY 基础值**：_Net Pay Qty Base LY 和 _Net Pay Order Cnt Base LY 当前 YOY 指标未直接使用（口径文档 UPT / Freq. / AUR 未定义 YOY 派生），但预留以备后续扩展，且已同步 Step1+Step2 分步口径（LY Step1 + LY Step2）。
18. **与参考文件 LY_Last_Purchase_Time_Table.md 的关系**：本方案为 Customer Dashboard VIC Tab 的 VIC Segment 表格版本，与 LY Last Purchase Time 表格版本共享相同的架构基础（表格视觉 + 每指标独立 Value/Display 度量 + 无 SWITCH 路由 + is_member/is_employee 双重筛选 + end period 时间筛选 + LY 财历映射），差异在于：

    - 行维度由 last_fy_last_order_month_type（事实表字段）改为 DIM_Row_VIC_Tier（1:N 模型关系）
    - 指标数量由 7 对扩展为 12 对
    - 新增金额类指标（SLS / ACV / AUR），引入货币符号 + 汇率换算
    - 新增 SLS 的 Step 1 + Step 2 分步口径（Step2 时间 = 所选时间范围，2026-09-12 修订，不能合并区间计算）
    - SLS% 分母通过 SUMX + ALLSELECTED('DIM_Row_VIC_Tier') 逐 Tier 复用分子后加总，保留外部期末 Tier 选择
    - 派生指标类型由 VIC Repurchase% / VIC Retention% 简化为 Customer No. vs LY / Customer% vs LY / SLS vs LY / SLS% vs LY
    - 字段筛选由 is_fy_vic / is_fy_retention_vic / last_12m_net_pay_amt 改为无 VIC 标识字段筛选（直接按 customer_tier 分组）
19. **注册日期类型与空值**：`register_date` 和财月末字段应为 Date，日期切片器需提供有效单值。仓库事实查询包含将 `register_date` 转为 Date 的版本，实际模型仍需核验；仅使用 `<=` 可能放行 BLANK 日期，现按业务要求在 Member VIC 日期分支增加 `NOT ISBLANK`，同时保留原 `<=` 截止判断。TTL VIC 原 OR 放行分支不变，不因本次修改排除空日期；`KEEPFILTERS` 继续取交集，不恢复外部筛选已排除的日期。

---

## 8. 会员筛选验收用例

> 以下为 Power BI 实际验收步骤与预期，非已执行的 DAX 引擎测试；测试时固定相同的员工、Tier、平台、店铺及日期上下文。“与调整前一致”仅指注册日期筛选行为，不表示 SUM 数值在期末 Tier 口径更新后不变。

| 场景               | 操作与预期                                                                                                                                                                                  |
| ------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| TTL VIC（0）       | 人数不变；会员条件仍只筛事实表 is_member=0，不因 register_date 新增限制；SUM 按期末 Tier 新口径聚合                                                                                         |
| Member VIC（1）    | 在其他筛选均满足时，只纳入 is_member=0 且注册日期非空、不晚于对应财月末的记录；空日期排除，早于或等于截止日纳入，晚于截止日排除，is_member=1 的事实记录仍排除                               |
| LY 截止日          | 使用注册日期介于 LY 财月末与本期财月末之间的记录：不因满足本期截止日而被误纳入 LY；其他条件满足时可纳入本期                                                                                 |
| 已有注册日期筛选   | 在事实表 register_date 上添加范围筛选：0 档保留该范围，1 档与非空及对应财月末上限条件取交集，不覆盖原范围，也不重新纳入外部已排除的非空日期                                                 |
| Step1/Step2 双步   | 检查 SLS、SLS Total、Qty、OrderCnt 的 Act/LY 两步均有会员条件，Member VIC 两步均排除空注册日期；仅改变起始期时 Step2 区间随之变化，注册截止日不变；不得把 Step2 压缩为 end period 当月      |
| 占比与派生指标     | Customer% / SLS% 分子分母使用同一会员规则与对应期间截止日，Customer Total 保留原 ALLSELECTED，SLS Total 用 ALLSELECTED 选中 Tier 后逐行加总；YOY、ACV、AUR、UPT、Freq. 继续引用对应基础度量 |
| 默认与空值         | 没有唯一会员选值时仍回退 0；外部筛选允许 BLANK 时，TTL VIC 空日期处理与调整前一致，Member VIC 排除 BLANK；外部筛选已排除 BLANK 时，两档均不恢复空日期                                       |
| 外部筛选仅含 BLANK | register_date 仅筛选 BLANK，其他条件固定：TTL VIC 保留该注册日期筛选，Member VIC 日期交集为空，无符合记录的基础聚合保持原空值返回行为                                                       |

## 9. 期末 Tier 归属核对要点

> 未在 Power BI 模型中实测；以下仅为后续对数要点。

- TTL VIC 下对齐日期、员工、平台、门店等筛选，用 `_SLS Base Act` 原值对照 SQL，避免千元缩放或汇率干扰。
- 抽查一个跨月换 Tier 的用户：历史其他 Tier/空 Tier 记录应归入 end period Tier；Customer 人数仍只看期末，保持不变。
- SLS Total 应等于外部选中 Tier 行金额之和；LY 使用自身期末圈人，ACV/AUR/UPT/Freq. 自动继承新基础值。
