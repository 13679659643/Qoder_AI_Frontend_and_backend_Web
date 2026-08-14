# Power BI 解决方案 — VIC Segment 表格（独立度量值）

> status: ready
> created: 2026-08-14
> type: 度量值开发 + 表格可视化
> 口径来源: 口径文档/VIC Segment.md（子模块四 VIC Segment，12 个指标，指标 0 为行维度本身）
> 参考实现: VIC/LY Last Purchase Time/LY_Last_Purchase_Time_Table.md（表格 + 每指标独立 Value/Display 范式，无 SWITCH 路由，无 x 轴时间处理）
> 金额类参考: Member/Customer_Member_Indicator.md（currency 货币符号拼接、Currency_ExchangeRate 汇率字段）

---

## 1. 需求理解

为 Customer Dashboard - VIC Tab 实现 VIC Segment 表格：

- **视觉对象**：Table（表格），非 Matrix
- **行维度**：`DIM_Row_VIC_Tier[Tier ID]`（T1 / T2 / T3 / T4 / T5）
  - DIM_Row_VIC_Tier 与 a03_e2e_customer_data_m 表模型关系为 1:N，分组维度由模型自动传递筛选，DAX 无需显式处理分组
  - `platform`、`shop_info_id` 分组维度直接拉取事实表字段实现自动传递，模型自动传递筛选，DAX 无需显式处理
- **无 x 轴**：表格视觉无列维度，不需要处理 x 轴上的当前时间
- **指标输出**：每个指标独立输出 Value（值）和 Display（格式化显示）两个度量值，不使用 SWITCH 路由
- **指标范围**：口径文档定义 12 个指标，其中指标 0（Tier）为行维度本身（字段直接拉取，不需要度量值），其余 12 个指标（指标 1~12）需要独立 Value + Display 度量值
- **口径**：一切以口径文档为准

### 1.1 关键特殊逻辑一：end period 时间筛选

口径文档全局逻辑要求：

> **聚合粒度**: `dt = 所选时间范围 end period`，`platform, shop_info_id`
> **end period 说明**: 所选时间范围的最后一个财月，只关注 Slicer_Time_Frame_Max 值

子模块四所有指标（指标 1~12）均应用 end period 时间筛选到事实表 `data_date`：

- 本期：`data_date ∈ [Last_Fiscal_Month_Min, Last_Fiscal_Month_Max]`
- LY（用于 YOY 分子）：`data_date ∈ [Last_Fiscal_Month_Min_LY, Last_Fiscal_Month_Max_LY]`

`Slicer_Time_Frame_Max` 已内置 `Last_Fiscal_Month_*` 系列字段，直接 SELECTEDVALUE 读取即可，无需 EDATE 计算。

### 1.2 关键特殊逻辑二：is_member / is_employee 双重人群筛选

口径文档要求：

> **is_member 使用**: `VAR __IsMemberFilter = SELECTEDVALUE(IsMemberFilter[IsMember], 0)`，默认 TTL VIC
> **is_employee 使用**: `VAR __IsEmployeeFilter = SELECTEDVALUE(Slicer_Is_Employee_Selection[IsEmployee_Code], 1)`，默认 Yes

所有指标均应用这两个筛选到事实表 `a03_e2e_customer_data_m[is_member]` / `[is_employee]`。

### 1.3 关键特殊逻辑三：分组维度自动传递

口径文档明确：

> **分组维度**: 按 `customer_tier`（T1/T2/T3/T4/T5）分组，已有 DIM_Row_VIC_Tier 行维度字段，DIM_Row_VIC_Tier 和 a03_e2e_customer_data_m 表，模型关系为 1:N，所以分组维度由模型自动传递，DAX 无需显式处理分组
> **聚合粒度**: `platform, shop_info_id` 分组维度由表字段自动传递，DAX 无需显式处理

`customer_tier`（通过 DIM_Row_VIC_Tier）、`platform`、`shop_info_id` 三个分组维度由模型自动传递筛选，DAX 度量值无需显式处理分组逻辑。

### 1.4 关键特殊逻辑四：SLS 类指标的 Step 1 + Step 2 口径

口径文档指标 5（SLS）、指标 7（% of Total SLS 分子）、指标 9（ACV 分子）、指标 10（AUR 分子/分母）、指标 11（UPT 分子/分母）、指标 12（Freq. 分子）均采用 Step 1 + Step 2 口径：

> **Step 1**: 在 dt = 所选时间范围 end period，筛选 customer_tier = T1/T2/T3/T4/T5，框定 user_id 范围
> **Step 2**: 再看该 user_id 在所选时间范围对应的 sum(net_pay_amt) / sum(net_pay_qty) / sum(net_pay_order_cnt)

经业务确认：Step 2 的"所选时间范围"= end period 当月（与 Step1 时间范围一致）。

**实现方式**：由于 Step1（end period 当月筛选 customer_tier）和 Step2（end period 当月对 user_id 求 SUM）的时间范围一致，且 customer_tier 分组由模型自动传递（当前行筛选即为 T1/T2/.../T5），所以 Step 1 + Step 2 可合并为：在 end period 当月对事实表直接按当前 customer_tier 行上下文做 SUM/DISTINCTCOUNT，无需显式用 TREATAS/CONTAINS 做 user_id 传递。

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

口径文档指标 2（Customer No. vs LY）、指标 4（Customer% vs LY）、指标 6（SLS vs LY）、指标 8（SLS % vs LY）的 YOY 计算：

> **计算公式**: 今年 / 去年 - 1

"去年"采用 LY end period 时间偏移（读取 `Slicer_Time_Frame_Max[Last_Fiscal_Month_Min_LY/Max_LY]`），对事实表 `data_date` 做 LY 区间筛选。

派生公式展开：

- Customer No. vs LY = 今年 Customer No. / 去年 Customer No. - 1
- SLS vs LY = 今年 SLS / 去年 SLS - 1
- Customer% vs LY = 今年 Customer% / 去年 Customer% - 1
- SLS % vs LY = 今年 SLS% - 去年 SLS%（差值，×100 转 pts）

### 1.7 与参考文件 LY_Last_Purchase_Time_Table.md 的关键差异

| 维度       | 参考文件（LY_Last_Purchase_Time_Table.md）             | 本方案（VIC_Segment_Table.md）                                      |
| ---------- | ------------------------------------------------------ | ------------------------------------------------------------------- |
| 行维度     | last_fy_last_order_month_type（事实表字段直接拉取）    | DIM_Row_VIC_Tier[Tier ID]（1:N 模型关系，模型自动传递）             |
| 指标数量   | 7 对 Value/Display（指标 2~8）                         | 12 对 Value/Display（指标 1~12）                                    |
| 金额类指标 | 无（仅数量类、比率类）                                 | 有（SLS / ACV / AUR，需货币符号 + 汇率换算）                        |
| SLS 口径   | 不涉及                                                 | Step 1 + Step 2（经确认 Step2 时间= end period 当月）               |
| 货币符号   | 不涉及                                                 | 复用 Slicer_Currency_Selection（参考 Customer_Member_Indicator.md） |
| YOY 派生   | VIC Repurchase% YOY / VIC Retention% YOY               | Customer No. vs LY / Customer% vs LY / SLS vs LY / SLS % vs LY      |
| 字段筛选   | is_fy_vic / is_fy_retention_vic / last_12m_net_pay_amt | 无（直接按 customer_tier 分组，无 VIC 标识字段筛选）                |

---

## 2. 现状分析

### 2.1 数据底表

| 对象     | 名称                                                                                                                           | 出处                   |
| -------- | ------------------------------------------------------------------------------------------------------------------------------ | ---------------------- |
| 事实表   | a03_e2e_customer_data_m                                                                                                        | 口径文档全局逻辑       |
| 关键字段 | data_date, platform, shop_info_id, user_id, is_member, is_employee, customer_tier, net_pay_amt, net_pay_qty, net_pay_order_cnt | 口径文档子模块四各指标 |

> 表为月度聚合表，`data_date` 为月末日期，用于 end period 时间筛选。

### 2.2 维度表清单

| 维度表                       | 类型     | 连接方式                                                                                                                                 |
| ---------------------------- | -------- | ---------------------------------------------------------------------------------------------------------------------------------------- |
| DIM_Row_VIC_Tier             | 1:N 维度 | 与 a03_e2e_customer_data_m[customer_tier] 建立 1:N 关系，模型自动传递筛选                                                                |
| Slicer_Time_Frame_Max        | 断开维度 | SELECTEDVALUE 读取 `Last_Fiscal_Month_Min/Max`（本期自然日）、`Last_Fiscal_Month_Min_LY/Max_LY`（LY 区间自然日，已预算，YOY 直接读） |
| Slicer_Is_Employee_Selection | 断开维度 | SELECTEDVALUE 读取 `IsEmployee_Code`                                                                                                   |
| IsMemberFilter               | 断开维度 | SELECTEDVALUE 读取 `IsMember`                                                                                                          |
| Slicer_Platform_Selection    | 断开维度 | 行维度直接拉事实表 platform 字段，模型自动传递                                                                                           |
| Slicer_Store_Name            | 断开维度 | 行维度直接拉事实表 shop_info_id 字段，模型自动传递                                                                                       |
| Slicer_Currency_Selection    | 断开维度 | SELECTEDVALUE 读取 `Currency_ExchangeRate`、`Currency_Symbol`（金额类指标专用）                                                      |

> **行维度处理**：`customer_tier`（通过 DIM_Row_VIC_Tier 1:N 关系）/ `platform` / `shop_info_id` 三个分组维度由模型自动传递筛选，DAX 度量值无需显式处理分组逻辑。

---

## 3. 方案设计

### 3.1 整体架构

```
核心思路：表格视觉 + 每指标独立 Value/Display 度量值（无 SWITCH 路由）

a03_e2e_customer_data_m（事实表）
    │
    │  行维度：
    │  - DIM_Row_VIC_Tier[Tier ID]（1:N 模型关系，自动传递）
    │  - platform / shop_info_id（可选叠加粒度，事实表字段直接拉取）
    │  模型自动传递筛选，DAX 无需显式处理
    │
    ▼
┌─────────────────────────── Table 视觉对象 ──────────────────────────┐
│  行 = DIM_Row_VIC_Tier[Tier ID]（+ 可选 platform / shop_info_id）    │
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
              │     （SLS Total = 移除 customer_tier 的总买家净销售额）│
              │     统一应用 is_member / is_employee / end period │
              │     Act 用本期区间，LY 用 LY 区间                 │
              │                                                    │
              │  对外 Value 层（12 个独立度量值）                │
              │  ├ Customer No. Value = _Customer No. Base Act    │
              │  ├ Customer No. vs LY Value = 今年/去年-1         │
              │  ├ Customer% Value = DIVIDE(分子Act, 分母Act)     │
              │  ├ Customer% vs LY Value = 今年%/去年%-1            │
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
_Customer No. Base Act                  ← end period 当月 DISTINCTCOUNT(user_id)
_Customer No. Base LY                   ← LY end period 当月 DISTINCTCOUNT(user_id)
_SLS Base Act                           ← end period 当月 SUM(net_pay_amt)，不÷1000（基础值保留原值，÷1000 在 SLS Value 中做）
_SLS Base LY                            ← LY end period 当月 SUM(net_pay_amt)
_SLS Total Base Act                     ← 移除 customer_tier（DIM_Row_VIC_Tier）筛选，end period 当月 SUM(net_pay_amt)
_SLS Total Base LY                      ← 移除 customer_tier（DIM_Row_VIC_Tier）筛选，LY end period 当月 SUM(net_pay_amt)
_Customer Total Base Act                ← end period 当月 sum(net_pay_amt)>0 的 DISTINCTCOUNT(user_id)（Customer% 分母）
_Customer Total Base LY                 ← LY end period 当月 sum(net_pay_amt)>0 的 DISTINCTCOUNT(user_id)（Customer% vs LY 分母）
_Net Pay Qty Base Act                   ← end period 当月 SUM(net_pay_qty)
_Net Pay Qty Base LY                    ← LY end period 当月 SUM(net_pay_qty)
_Net Pay Order Cnt Base Act             ← end period 当月 SUM(net_pay_order_cnt)
_Net Pay Order Cnt Base LY              ← LY end period 当月 SUM(net_pay_order_cnt)

[对外 Value 层 — 12 个独立度量值]       ← 放 Cell Values 文件夹
Customer No. Value                      ← = _Customer No. Base Act
Customer No. vs LY Value                ← = 今年 / 去年 - 1
Customer% Value                         ← = DIVIDE(_Customer No. Base Act, _Customer Total Base Act)
Customer% vs LY Value                   ← = 今年% / 去年% - 1
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
Customer% vs LY Display                 ← percent_1dp 格式 #,##0.0%（不含正号）
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

| 筛选器                                    | 作用方式                                                                    | DAX 处理                                                                 |
| ----------------------------------------- | --------------------------------------------------------------------------- | ------------------------------------------------------------------------ |
| Slicer_Time_Frame_Max（本期）             | 断开维度，SELECTEDVALUE 读取 `Last_Fiscal_Month_Min/Max`                  | `data_date >= __PeriodMin AND data_date <= __PeriodMax`                |
| Slicer_Time_Frame_Max（LY）               | SELECTEDVALUE 读取 `Last_Fiscal_Month_Min_LY/Max_LY`                      | `data_date >= __LYMin AND data_date <= __LYMax`（YOY 派生专用）        |
| Slicer_Is_Employee_Selection              | 断开维度，SELECTEDVALUE 读取 `IsEmployee_Code`                            | `a03_e2e_customer_data_m[is_employee] = __IsEmployeeFilter`            |
| IsMemberFilter                            | 断开维度，SELECTEDVALUE 读取 `IsMember`                                   | `a03_e2e_customer_data_m[is_member] = __IsMemberFilter`                |
| DIM_Row_VIC_Tier                          | 1:N 模型关系                                                                | 模型自动传递 customer_tier 筛选，DAX 无需显式处理                        |
| Slicer_Currency_Selection                 | 断开维度，SELECTEDVALUE 读取 `Currency_ExchangeRate`、`Currency_Symbol` | 金额类指标 ÷`Currency_ExchangeRate`；Display 拼接 `Currency_Symbol` |
| 事实表分组字段（platform / shop_info_id） | 表格行直接拉取，模型自动传递筛选                                            | DAX 无需显式处理                                                         |

### 3.4 YOY 时间偏移规则（财历映射）

直接读取 Slicer_Time_Frame_Max 内置的 `Last_Fiscal_Month_*` 系列字段：

- 本期：`Last_Fiscal_Month_Min` ~ `Last_Fiscal_Month_Max`
- LY：`Last_Fiscal_Month_Min_LY` ~ `Last_Fiscal_Month_Max_LY`
- 无需 EDATE -12 或 Key 偏移计算

### 3.5 指标计算公式与数据格式

| 序号 | 指标名称               | 计算公式                                                                                                   | 数据类型    | 数据格式                    |
| ---- | ---------------------- | ---------------------------------------------------------------------------------------------------------- | ----------- | --------------------------- |
| 0    | Tier                   | 行维度字段直接拉取（DIM_Row_VIC_Tier[Tier ID]），不需要度量值                                              | —          | —                          |
| 1    | Customer No.           | count(distinct user_id)                                                                                    | integer     | `#,##0`                   |
| 2    | Customer No. vs LY     | 今年 / 去年 - 1                                                                                            | percent_1dp | `#,##0.0%`                |
| 3    | % of Total (Customer%) | 分子：count(distinct user_id) where customer_tier=T1-T5；分母：count(distinct user_id) where net_pay_amt>0 | percent_1dp | `#,##0.0%`                |
| 4    | Customer% vs LY        | 今年 / 去年 - 1                                                                                            | percent_1dp | `#,##0.0%`                |
| 5    | SLS (in K)             | Step1+Step2 sum(net_pay_amt)，÷1000，÷汇率                                                               | currency    | `#,##0`（拼接货币符号）   |
| 6    | SLS vs LY              | 今年 / 去年 - 1                                                                                            | percent_1dp | `#,##0.0%`                |
| 7    | % of Total (SLS%)      | 分子：Step1+Step2 sum(net_pay_amt)；分母：所选时间范围 sum(net_pay_amt)（移除 customer_tier）              | percent_1dp | `#,##0.0%`                |
| 8    | SLS % vs LY            | 今年 - 去年（差值，×100 转 pts）                                                                          | integer_pts | `#,##0pts;-#,##0pts;0pts` |
| 9    | ACV                    | 分子：SLS；分母：count(distinct user_id)                                                                   | currency    | `#,##0`（拼接货币符号）   |
| 10   | AUR                    | 分子：SLS；分母：sum(net_pay_qty)                                                                          | currency    | `#,##0`（拼接货币符号）   |
| 11   | UPT                    | 分子：sum(net_pay_qty)；分母：sum(net_pay_order_cnt)                                                       | integer     | `#,##0`                   |
| 12   | Freq.                  | 分子：sum(net_pay_order_cnt)；分母：count(distinct user_id)                                                | decimal_1dp | `#,##0.0`                 |

> **YOY 格式说明**：口径文档指标 2 / 4 / 6 数据格式为 `#,##0.0%`（percent_1dp，不含正号），指标 8 数据格式为 `#,##0pts;-#,##0pts;0pts`（integer_pts，不含正号）。本方案严格遵循口径文档，所有 YOY Display 不含正号。

---

## 4. 度量值实现

### 4.1 内部基础层 — Base Act / Base LY（私有度量值）

> 私有度量值（下划线前缀），放 Base Metrics 文件夹，供对外 Value 层调用，避免重复代码。
> Act = 本期 end period 区间，LY = LY end period 区间。

#### 4.1.1 _Customer No. Base Act（买家人数本期基础值）

```dax
_Customer No. Base Act = 
// ========================================
// 度量值: _Customer No. Base Act
// Display Folder: Base Metrics
// 用途: Customer No.（买家人数）本期基础值
// 依赖: a03_e2e_customer_data_m,
//       Slicer_Time_Frame_Max[Last_Fiscal_Month_Min/Max],
//       Slicer_Is_Employee_Selection[IsEmployee_Code],
//       IsMemberFilter[IsMember]
// 口径来源: 口径文档/VIC Segment.md 指标 1
// 筛选上下文:
//   - data_date ∈ [Last_Fiscal_Month_Min, Last_Fiscal_Month_Max]（end period 当月）
//   - is_member = __IsMemberFilter（默认 0 = TTL VIC）
//   - is_employee = __IsEmployeeFilter（默认 1 = Yes）
//   - customer_tier 分组由 DIM_Row_VIC_Tier 1:N 模型关系自动传递，DAX 无需显式处理
// 聚合粒度: DISTINCTCOUNT(user_id)
// ========================================
    VAR __PeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Max[Last_Fiscal_Month_Min])
    VAR __PeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max[Last_Fiscal_Month_Max])
    VAR __IsMemberFilter = SELECTEDVALUE(IsMemberFilter[IsMember], 0)
    VAR __IsEmployeeFilter = SELECTEDVALUE(Slicer_Is_Employee_Selection[IsEmployee_Code], 1)

    RETURN
        CALCULATE(
            DISTINCTCOUNT('a03_e2e_customer_data_m'[user_id]),
            'a03_e2e_customer_data_m'[is_member] = __IsMemberFilter,
            'a03_e2e_customer_data_m'[is_employee] = __IsEmployeeFilter,
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
    VAR __IsEmployeeFilter = SELECTEDVALUE(Slicer_Is_Employee_Selection[IsEmployee_Code], 1)

    RETURN
        CALCULATE(
            DISTINCTCOUNT('a03_e2e_customer_data_m'[user_id]),
            'a03_e2e_customer_data_m'[is_member] = __IsMemberFilter,
            'a03_e2e_customer_data_m'[is_employee] = __IsEmployeeFilter,
            'a03_e2e_customer_data_m'[data_date] >= __LYMin,
            'a03_e2e_customer_data_m'[data_date] <= __LYMax
        )
```

#### 4.1.3 _Customer Total Base Act（买家人数占比分母本期基础值）

```dax
_Customer Total Base Act = 
// ========================================
// 度量值: _Customer Total Base Act
// Display Folder: Base Metrics
// 用途: Customer% 分母（总买家人数，net_pay_amt > 0）本期基础值
// 依赖: a03_e2e_customer_data_m,
//       Slicer_Time_Frame_Max[Last_Fiscal_Month_Min/Max],
//       Slicer_Is_Employee_Selection[IsEmployee_Code],
//       IsMemberFilter[IsMember]
// 口径来源: 口径文档/VIC Segment.md 指标 3（分母）
// 筛选上下文:
//   - data_date ∈ [Last_Fiscal_Month_Min, Last_Fiscal_Month_Max]（end period 当月）
//   - net_pay_amt > 0（有购买的买家）
//   - is_member / is_employee 双重人群筛选
//   - 注意：分母不限制 customer_tier，但保留 platform/shop_info_id 分组维度
// 聚合粒度: DISTINCTCOUNT(user_id)
// ========================================
    VAR __PeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Max[Last_Fiscal_Month_Min])
    VAR __PeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max[Last_Fiscal_Month_Max])
    VAR __IsMemberFilter = SELECTEDVALUE(IsMemberFilter[IsMember], 0)
    VAR __IsEmployeeFilter = SELECTEDVALUE(Slicer_Is_Employee_Selection[IsEmployee_Code], 1)

    RETURN
        CALCULATE(
            DISTINCTCOUNT('a03_e2e_customer_data_m'[user_id]),
            // 'a03_e2e_customer_data_m'[net_pay_amt] > 0,
            'a03_e2e_customer_data_m'[is_member] = __IsMemberFilter,
            'a03_e2e_customer_data_m'[is_employee] = __IsEmployeeFilter,
            'a03_e2e_customer_data_m'[data_date] >= __PeriodMin,
            'a03_e2e_customer_data_m'[data_date] <= __PeriodMax,
            REMOVEFILTERS(DIM_Row_VIC_Tier)
        )
```

#### 4.1.4 _Customer Total Base LY（买家人数占比分母去年同期基础值）

```dax
_Customer Total Base LY = 
// ========================================
// 度量值: _Customer Total Base LY
// Display Folder: Base Metrics
// 用途: Customer% 分母（总买家人数，net_pay_amt > 0）去年同期基础值
// 依赖: a03_e2e_customer_data_m,
//       Slicer_Time_Frame_Max[Last_Fiscal_Month_Min_LY/Max_LY],
//       Slicer_Is_Employee_Selection[IsEmployee_Code],
//       IsMemberFilter[IsMember]
// 口径来源: 口径文档/VIC Segment.md 指标 3（分母 LY 版本，用于指标 4 YOY 分母）
// 筛选上下文:
//   - data_date ∈ [Last_Fiscal_Month_Min_LY, Last_Fiscal_Month_Max_LY]（LY end period 当月）
//   - net_pay_amt > 0
//   - is_member / is_employee 双重人群筛选
// 时间偏移: 财历映射
// ========================================
    VAR __LYMin = SELECTEDVALUE(Slicer_Time_Frame_Max[Last_Fiscal_Month_Min_LY])
    VAR __LYMax = SELECTEDVALUE(Slicer_Time_Frame_Max[Last_Fiscal_Month_Max_LY])
    VAR __IsMemberFilter = SELECTEDVALUE(IsMemberFilter[IsMember], 0)
    VAR __IsEmployeeFilter = SELECTEDVALUE(Slicer_Is_Employee_Selection[IsEmployee_Code], 1)

    RETURN
        CALCULATE(
            DISTINCTCOUNT('a03_e2e_customer_data_m'[user_id]),
            // 'a03_e2e_customer_data_m'[net_pay_amt] > 0,
            'a03_e2e_customer_data_m'[is_member] = __IsMemberFilter,
            'a03_e2e_customer_data_m'[is_employee] = __IsEmployeeFilter,
            'a03_e2e_customer_data_m'[data_date] >= __LYMin,
            'a03_e2e_customer_data_m'[data_date] <= __LYMax,
            REMOVEFILTERS(DIM_Row_VIC_Tier)
        )
```

#### 4.1.5 _SLS Base Act（净销售额本期基础值，原值不÷1000）

```dax
_SLS Base Act = 
// ========================================
// 度量值: _SLS Base Act
// Display Folder: Base Metrics
// 用途: SLS（净销售额）本期基础值（原值，不÷1000，不÷汇率）
// 依赖: a03_e2e_customer_data_m,
//       Slicer_Time_Frame_Max[Last_Fiscal_Month_Min/Max],
//       Slicer_Is_Employee_Selection[IsEmployee_Code],
//       IsMemberFilter[IsMember]
// 口径来源: 口径文档/VIC Segment.md 指标 5（Step1+Step2 合并实现）
// 筛选上下文:
//   - data_date ∈ [Last_Fiscal_Month_Min, Last_Fiscal_Month_Max]（end period 当月）
//   - is_member / is_employee 双重人群筛选
//   - customer_tier 分组由 DIM_Row_VIC_Tier 1:N 模型关系自动传递，DAX 无需显式处理
// Step1+Step2 合并说明:
//   - 口径文档 Step1: 在 dt=end period 框定 customer_tier=T1-T5 的 user_id 范围
//   - 口径文档 Step2: 再看该 user_id 在所选时间范围对应的 sum(net_pay_amt)
//   - 经业务确认 Step2 "所选时间范围" = end period 当月（与 Step1 一致）
//   - 因 customer_tier 分组由模型自动传递（当前行筛选即为 T1/T2/.../T5），
//     Step1+Step2 合并为：在 end period 当月直接对事实表做 SUM(net_pay_amt)
// 聚合粒度: SUM(net_pay_amt)
// 注: 此处返回原值（RMB），÷1000 和 ÷汇率 在 SLS Value 中实现
// ========================================
    VAR __PeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Max[Last_Fiscal_Month_Min])
    VAR __PeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max[Last_Fiscal_Month_Max])
    VAR __IsMemberFilter = SELECTEDVALUE(IsMemberFilter[IsMember], 0)
    VAR __IsEmployeeFilter = SELECTEDVALUE(Slicer_Is_Employee_Selection[IsEmployee_Code], 1)

    RETURN
        CALCULATE(
            SUM('a03_e2e_customer_data_m'[net_pay_amt]),
            'a03_e2e_customer_data_m'[is_member] = __IsMemberFilter,
            'a03_e2e_customer_data_m'[is_employee] = __IsEmployeeFilter,
            'a03_e2e_customer_data_m'[data_date] >= __PeriodMin,
            'a03_e2e_customer_data_m'[data_date] <= __PeriodMax
        )
```

#### 4.1.6 _SLS Base LY（净销售额去年同期基础值）

```dax
_SLS Base LY = 
// ========================================
// 度量值: _SLS Base LY
// Display Folder: Base Metrics
// 用途: SLS（净销售额）去年同期基础值（原值，不÷1000，不÷汇率）
// 依赖: a03_e2e_customer_data_m,
//       Slicer_Time_Frame_Max[Last_Fiscal_Month_Min_LY/Max_LY],
//       Slicer_Is_Employee_Selection[IsEmployee_Code],
//       IsMemberFilter[IsMember]
// 口径来源: 口径文档/VIC Segment.md 指标 5（LY 版本，用于指标 6 YOY 分母）
// 筛选上下文:
//   - data_date ∈ [Last_Fiscal_Month_Min_LY, Last_Fiscal_Month_Max_LY]（LY end period 当月）
//   - is_member / is_employee 双重人群筛选
// 时间偏移: 财历映射
// 注: vs LY 同比值（今年/去年-1）汇率在相除时自动抵消，所以 LY 基础值不÷汇率
//     但 SLS LY 基础值也用于其他场景，保持原值（RMB）输出
// ========================================
    VAR __LYMin = SELECTEDVALUE(Slicer_Time_Frame_Max[Last_Fiscal_Month_Min_LY])
    VAR __LYMax = SELECTEDVALUE(Slicer_Time_Frame_Max[Last_Fiscal_Month_Max_LY])
    VAR __IsMemberFilter = SELECTEDVALUE(IsMemberFilter[IsMember], 0)
    VAR __IsEmployeeFilter = SELECTEDVALUE(Slicer_Is_Employee_Selection[IsEmployee_Code], 1)

    RETURN
        CALCULATE(
            SUM('a03_e2e_customer_data_m'[net_pay_amt]),
            'a03_e2e_customer_data_m'[is_member] = __IsMemberFilter,
            'a03_e2e_customer_data_m'[is_employee] = __IsEmployeeFilter,
            'a03_e2e_customer_data_m'[data_date] >= __LYMin,
            'a03_e2e_customer_data_m'[data_date] <= __LYMax
        )
```

#### 4.1.7 _SLS Total Base Act（净销售额占比分母本期基础值，移除 customer_tier）

```dax
_SLS Total Base Act = 
// ========================================
// 度量值: _SLS Total Base Act
// Display Folder: Base Metrics
// 用途: SLS% 分母（总买家净销售额，移除 customer_tier 筛选）本期基础值
// 依赖: a03_e2e_customer_data_m,
//       Slicer_Time_Frame_Max[Last_Fiscal_Month_Min/Max],
//       Slicer_Is_Employee_Selection[IsEmployee_Code],
//       IsMemberFilter[IsMember],
//       DIM_Row_VIC_Tier
// 口径来源: 口径文档/VIC Segment.md 指标 7（分母）
// 筛选上下文:
//   - data_date ∈ [Last_Fiscal_Month_Min, Last_Fiscal_Month_Max]（end period 当月）
//   - is_member / is_employee 双重人群筛选
//   - 移除 DIM_Row_VIC_Tier 对 customer_tier 的筛选（分母=全部 customer_tier）
//   - 保留外部切片器影响（platform / shop_info_id / is_member / is_employee）
// 实现方式: REMOVEFILTERS(DIM_Row_VIC_Tier) 移除 customer_tier 筛选
// 聚合粒度: SUM(net_pay_amt)
// 注: 口径文档第 157 行明确"需要移除 a03_e2e_customer_data_m 中 customer_tier 字段对表的影响，
//     但同时需要保留外部切片器的影响，我理解使用 ALLSELECTED"
//     本方案采用 REMOVEFILTERS(DIM_Row_VIC_Tier) 实现：移除 DIM_Row_VIC_Tier 的筛选传递，
//     保留 platform / shop_info_id / is_member / is_employee 等外部筛选器
// ========================================
    VAR __PeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Max[Last_Fiscal_Month_Min])
    VAR __PeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max[Last_Fiscal_Month_Max])
    VAR __IsMemberFilter = SELECTEDVALUE(IsMemberFilter[IsMember], 0)
    VAR __IsEmployeeFilter = SELECTEDVALUE(Slicer_Is_Employee_Selection[IsEmployee_Code], 1)

    RETURN
        CALCULATE(
            SUM('a03_e2e_customer_data_m'[net_pay_amt]),
            'a03_e2e_customer_data_m'[is_member] = __IsMemberFilter,
            'a03_e2e_customer_data_m'[is_employee] = __IsEmployeeFilter,
            'a03_e2e_customer_data_m'[data_date] >= __PeriodMin,
            'a03_e2e_customer_data_m'[data_date] <= __PeriodMax,
            REMOVEFILTERS(DIM_Row_VIC_Tier)
        )
```

#### 4.1.8 _SLS Total Base LY（净销售额占比分母去年同期基础值，移除 customer_tier）

```dax
_SLS Total Base LY = 
// ========================================
// 度量值: _SLS Total Base LY
// Display Folder: Base Metrics
// 用途: SLS% 分母（总买家净销售额，移除 customer_tier 筛选）去年同期基础值
// 依赖: a03_e2e_customer_data_m,
//       Slicer_Time_Frame_Max[Last_Fiscal_Month_Min_LY/Max_LY],
//       Slicer_Is_Employee_Selection[IsEmployee_Code],
//       IsMemberFilter[IsMember],
//       DIM_Row_VIC_Tier
// 口径来源: 口径文档/VIC Segment.md 指标 7（分母 LY 版本，用于指标 8 YOY 计算）
// 筛选上下文:
//   - data_date ∈ [Last_Fiscal_Month_Min_LY, Last_Fiscal_Month_Max_LY]（LY end period 当月）
//   - is_member / is_employee 双重人群筛选
//   - 移除 DIM_Row_VIC_Tier 对 customer_tier 的筛选
// 时间偏移: 财历映射
// ========================================
    VAR __LYMin = SELECTEDVALUE(Slicer_Time_Frame_Max[Last_Fiscal_Month_Min_LY])
    VAR __LYMax = SELECTEDVALUE(Slicer_Time_Frame_Max[Last_Fiscal_Month_Max_LY])
    VAR __IsMemberFilter = SELECTEDVALUE(IsMemberFilter[IsMember], 0)
    VAR __IsEmployeeFilter = SELECTEDVALUE(Slicer_Is_Employee_Selection[IsEmployee_Code], 1)

    RETURN
        CALCULATE(
            SUM('a03_e2e_customer_data_m'[net_pay_amt]),
            'a03_e2e_customer_data_m'[is_member] = __IsMemberFilter,
            'a03_e2e_customer_data_m'[is_employee] = __IsEmployeeFilter,
            'a03_e2e_customer_data_m'[data_date] >= __LYMin,
            'a03_e2e_customer_data_m'[data_date] <= __LYMax,
            REMOVEFILTERS(DIM_Row_VIC_Tier)
        )
```

#### 4.1.9 _Net Pay Qty Base Act（净出库件数本期基础值）

```dax
_Net Pay Qty Base Act = 
// ========================================
// 度量值: _Net Pay Qty Base Act
// Display Folder: Base Metrics
// 用途: 净出库件数本期基础值（用于 AUR 分母 / UPT 分子）
// 依赖: a03_e2e_customer_data_m,
//       Slicer_Time_Frame_Max[Last_Fiscal_Month_Min/Max],
//       Slicer_Is_Employee_Selection[IsEmployee_Code],
//       IsMemberFilter[IsMember]
// 口径来源: 口径文档/VIC Segment.md 指标 10（AUR 分母）/ 指标 11（UPT 分子）
// 筛选上下文:
//   - data_date ∈ [Last_Fiscal_Month_Min, Last_Fiscal_Month_Max]（end period 当月）
//   - is_member / is_employee 双重人群筛选
//   - customer_tier 分组由模型自动传递
// 聚合粒度: SUM(net_pay_qty)
// ========================================
    VAR __PeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Max[Last_Fiscal_Month_Min])
    VAR __PeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max[Last_Fiscal_Month_Max])
    VAR __IsMemberFilter = SELECTEDVALUE(IsMemberFilter[IsMember], 0)
    VAR __IsEmployeeFilter = SELECTEDVALUE(Slicer_Is_Employee_Selection[IsEmployee_Code], 1)

    RETURN
        CALCULATE(
            SUM('a03_e2e_customer_data_m'[net_pay_qty]),
            'a03_e2e_customer_data_m'[is_member] = __IsMemberFilter,
            'a03_e2e_customer_data_m'[is_employee] = __IsEmployeeFilter,
            'a03_e2e_customer_data_m'[data_date] >= __PeriodMin,
            'a03_e2e_customer_data_m'[data_date] <= __PeriodMax
        )
```

#### 4.1.10 _Net Pay Qty Base LY（净出库件数去年同期基础值）

```dax
_Net Pay Qty Base LY = 
// ========================================
// 度量值: _Net Pay Qty Base LY
// Display Folder: Base Metrics
// 用途: 净出库件数去年同期基础值（备用，当前 YOY 指标未直接使用）
// 依赖: a03_e2e_customer_data_m,
//       Slicer_Time_Frame_Max[Last_Fiscal_Month_Min_LY/Max_LY],
//       Slicer_Is_Employee_Selection[IsEmployee_Code],
//       IsMemberFilter[IsMember]
// 口径来源: 口径文档/VIC Segment.md 指标 10/11（LY 版本，预留扩展）
// 筛选上下文:
//   - data_date ∈ [Last_Fiscal_Month_Min_LY, Last_Fiscal_Month_Max_LY]（LY end period 当月）
//   - is_member / is_employee 双重人群筛选
// 时间偏移: 财历映射
// ========================================
    VAR __LYMin = SELECTEDVALUE(Slicer_Time_Frame_Max[Last_Fiscal_Month_Min_LY])
    VAR __LYMax = SELECTEDVALUE(Slicer_Time_Frame_Max[Last_Fiscal_Month_Max_LY])
    VAR __IsMemberFilter = SELECTEDVALUE(IsMemberFilter[IsMember], 0)
    VAR __IsEmployeeFilter = SELECTEDVALUE(Slicer_Is_Employee_Selection[IsEmployee_Code], 1)

    RETURN
        CALCULATE(
            SUM('a03_e2e_customer_data_m'[net_pay_qty]),
            'a03_e2e_customer_data_m'[is_member] = __IsMemberFilter,
            'a03_e2e_customer_data_m'[is_employee] = __IsEmployeeFilter,
            'a03_e2e_customer_data_m'[data_date] >= __LYMin,
            'a03_e2e_customer_data_m'[data_date] <= __LYMax
        )
```

#### 4.1.11 _Net Pay Order Cnt Base Act（净出库订单数本期基础值）

```dax
_Net Pay Order Cnt Base Act = 
// ========================================
// 度量值: _Net Pay Order Cnt Base Act
// Display Folder: Base Metrics
// 用途: 净出库订单数本期基础值（用于 UPT 分母 / Freq. 分子）
// 依赖: a03_e2e_customer_data_m,
//       Slicer_Time_Frame_Max[Last_Fiscal_Month_Min/Max],
//       Slicer_Is_Employee_Selection[IsEmployee_Code],
//       IsMemberFilter[IsMember]
// 口径来源: 口径文档/VIC Segment.md 指标 11（UPT 分母）/ 指标 12（Freq. 分子）
// 筛选上下文:
//   - data_date ∈ [Last_Fiscal_Month_Min, Last_Fiscal_Month_Max]（end period 当月）
//   - is_member / is_employee 双重人群筛选
//   - customer_tier 分组由模型自动传递
// 聚合粒度: SUM(net_pay_order_cnt)
// ========================================
    VAR __PeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Max[Last_Fiscal_Month_Min])
    VAR __PeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max[Last_Fiscal_Month_Max])
    VAR __IsMemberFilter = SELECTEDVALUE(IsMemberFilter[IsMember], 0)
    VAR __IsEmployeeFilter = SELECTEDVALUE(Slicer_Is_Employee_Selection[IsEmployee_Code], 1)

    RETURN
        CALCULATE(
            SUM('a03_e2e_customer_data_m'[net_pay_order_cnt]),
            'a03_e2e_customer_data_m'[is_member] = __IsMemberFilter,
            'a03_e2e_customer_data_m'[is_employee] = __IsEmployeeFilter,
            'a03_e2e_customer_data_m'[data_date] >= __PeriodMin,
            'a03_e2e_customer_data_m'[data_date] <= __PeriodMax
        )
```

#### 4.1.12 _Net Pay Order Cnt Base LY（净出库订单数去年同期基础值）

```dax
_Net Pay Order Cnt Base LY = 
// ========================================
// 度量值: _Net Pay Order Cnt Base LY
// Display Folder: Base Metrics
// 用途: 净出库订单数去年同期基础值（备用，当前 YOY 指标未直接使用）
// 依赖: a03_e2e_customer_data_m,
//       Slicer_Time_Frame_Max[Last_Fiscal_Month_Min_LY/Max_LY],
//       Slicer_Is_Employee_Selection[IsEmployee_Code],
//       IsMemberFilter[IsMember]
// 口径来源: 口径文档/VIC Segment.md 指标 11/12（LY 版本，预留扩展）
// 筛选上下文:
//   - data_date ∈ [Last_Fiscal_Month_Min_LY, Last_Fiscal_Month_Max_LY]（LY end period 当月）
//   - is_member / is_employee 双重人群筛选
// 时间偏移: 财历映射
// ========================================
    VAR __LYMin = SELECTEDVALUE(Slicer_Time_Frame_Max[Last_Fiscal_Month_Min_LY])
    VAR __LYMax = SELECTEDVALUE(Slicer_Time_Frame_Max[Last_Fiscal_Month_Max_LY])
    VAR __IsMemberFilter = SELECTEDVALUE(IsMemberFilter[IsMember], 0)
    VAR __IsEmployeeFilter = SELECTEDVALUE(Slicer_Is_Employee_Selection[IsEmployee_Code], 1)

    RETURN
        CALCULATE(
            SUM('a03_e2e_customer_data_m'[net_pay_order_cnt]),
            'a03_e2e_customer_data_m'[is_member] = __IsMemberFilter,
            'a03_e2e_customer_data_m'[is_employee] = __IsEmployeeFilter,
            'a03_e2e_customer_data_m'[data_date] >= __LYMin,
            'a03_e2e_customer_data_m'[data_date] <= __LYMax
        )
```

### 4.2 对外 Value 层 — 12 个独立度量值

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
// 计算公式: 分子 count(distinct user_id) where customer_tier=T1-T5 / 分母 count(distinct user_id) where net_pay_amt>0
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
// 计算公式: 今年 / 去年 - 1
//   今年 Customer% = _Customer No. Base Act / _Customer Total Base Act
//   去年 Customer% = _Customer No. Base LY / _Customer Total Base LY
// 边界处理: 去年% 为 0 或 BLANK 时返回 BLANK
// 时间偏移: 去年 = LY end period
// ========================================
    VAR __PctAct = DIVIDE([_Customer No. Base Act], [_Customer Total Base Act])
    VAR __PctLY = DIVIDE([_Customer No. Base LY], [_Customer Total Base LY])

    RETURN
        IF(
            ISBLANK(__PctLY) || __PctLY = 0,
            BLANK(),
            DIVIDE(__PctAct, __PctLY) - 1
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
// 计算公式: Step1+Step2 sum(net_pay_amt) ÷ 1000 ÷ __FXRate
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
// 计算公式: 今年 / 去年 - 1
// 边界处理: 去年为 0 或 BLANK 时返回 BLANK
// 时间偏移: 去年 = LY end period
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
// 计算公式: 分子 Step1+Step2 sum(net_pay_amt) / 分母 所选时间范围 sum(net_pay_amt)（移除 customer_tier）
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
// 时间偏移: 去年 = LY end period
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
// 计算公式: 分子 SLS（Step1+Step2 sum(net_pay_amt)）/ 分母 count(distinct user_id)
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
// 计算公式: 分子 SLS（Step1+Step2 sum(net_pay_amt)）/ 分母 sum(net_pay_qty)
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
// 计算公式: 分子 sum(net_pay_qty) / 分母 sum(net_pay_order_cnt)
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
// 计算公式: 分子 sum(net_pay_order_cnt) / 分母 count(distinct user_id)
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
// 数据格式: percent_1dp → #,##0.0%（不含正号）
// 注: 口径文档明确定义为 #,##0.0%，不含正号
// ========================================
    VAR __Value = [Customer% vs LY Value]
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            FORMAT(__Value, "#,##0.0%")
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
        "<path d='M8 12 L8 5 M5 7 L8 4 L11 7' stroke='white' stroke-width='1.8' stroke-linecap='round' stroke-linejoin='round' fill='none'/     >" &
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
        "<path d='M8 12 L8 5 M5 7 L8 4 L11 7' stroke='white' stroke-width='1.8' stroke-linecap='round' stroke-linejoin='round' fill='none'/     >" &
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

| 序号 | 度量值名称                  | Display Folder | 用途                                                   |
| ---- | --------------------------- | -------------- | ------------------------------------------------------ |
| 1    | _Customer No. Base Act      | Base Metrics   | 买家人数本期基础值（私有，供派生调用）                 |
| 2    | _Customer No. Base LY       | Base Metrics   | 买家人数去年同期基础值（私有，YOY 分母用）             |
| 3    | _Customer Total Base Act    | Base Metrics   | 买家人数占比分母本期基础值（私有，net_pay_amt>0）      |
| 4    | _Customer Total Base LY     | Base Metrics   | 买家人数占比分母去年同期基础值（私有）                 |
| 5    | _SLS Base Act               | Base Metrics   | 净销售额本期基础值（私有，原值不÷1000）               |
| 6    | _SLS Base LY                | Base Metrics   | 净销售额去年同期基础值（私有）                         |
| 7    | _SLS Total Base Act         | Base Metrics   | 净销售额占比分母本期基础值（私有，移除 customer_tier） |
| 8    | _SLS Total Base LY          | Base Metrics   | 净销售额占比分母去年同期基础值（私有）                 |
| 9    | _Net Pay Qty Base Act       | Base Metrics   | 净出库件数本期基础值（私有）                           |
| 10   | _Net Pay Qty Base LY        | Base Metrics   | 净出库件数去年同期基础值（私有，预留扩展）             |
| 11   | _Net Pay Order Cnt Base Act | Base Metrics   | 净出库订单数本期基础值（私有）                         |
| 12   | _Net Pay Order Cnt Base LY  | Base Metrics   | 净出库订单数去年同期基础值（私有，预留扩展）           |
| 13   | Customer No. Value          | Cell Values    | 指标 1 对外值                                          |
| 14   | Customer No. vs LY Value    | Cell Values    | 指标 2 对外值                                          |
| 15   | Customer% Value             | Cell Values    | 指标 3 对外值                                          |
| 16   | Customer% vs LY Value       | Cell Values    | 指标 4 对外值                                          |
| 17   | SLS Value                   | Cell Values    | 指标 5 对外值（÷1000，÷汇率）                        |
| 18   | SLS vs LY Value             | Cell Values    | 指标 6 对外值                                          |
| 19   | SLS% Value                  | Cell Values    | 指标 7 对外值                                          |
| 20   | SLS% vs LY Value            | Cell Values    | 指标 8 对外值（差值小数，Display ×100 转 pts）        |
| 21   | ACV Value                   | Cell Values    | 指标 9 对外值（÷汇率）                                |
| 22   | AUR Value                   | Cell Values    | 指标 10 对外值（÷汇率）                               |
| 23   | UPT Value                   | Cell Values    | 指标 11 对外值                                         |
| 24   | Freq. Value                 | Cell Values    | 指标 12 对外值                                         |
| 25   | Customer No. Display        | Formatting     | 指标 1 格式化显示（#,##0）                             |
| 26   | Customer No. vs LY Display  | Formatting     | 指标 2 格式化显示（#,##0.0%）                          |
| 27   | Customer% Display           | Formatting     | 指标 3 格式化显示（#,##0.0%）                          |
| 28   | Customer% vs LY Display     | Formatting     | 指标 4 格式化显示（#,##0.0%）                          |
| 29   | SLS Display                 | Formatting     | 指标 5 格式化显示（货币符号 + #,##0）                  |
| 30   | SLS vs LY Display           | Formatting     | 指标 6 格式化显示（#,##0.0%）                          |
| 31   | SLS% Display                | Formatting     | 指标 7 格式化显示（#,##0.0%）                          |
| 32   | SLS% vs LY Display          | Formatting     | 指标 8 格式化显示（#,##0pts;-#,##0pts;0pts）           |
| 33   | ACV Display                 | Formatting     | 指标 9 格式化显示（货币符号 + #,##0）                  |
| 34   | AUR Display                 | Formatting     | 指标 10 格式化显示（货币符号 + #,##0）                 |
| 35   | UPT Display                 | Formatting     | 指标 11 格式化显示（#,##0）                            |
| 36   | Freq. Display               | Formatting     | 指标 12 格式化显示（#,##0.0）                          |

---

## 6. 血缘关系图

```
┌─────────────────────────────────────────────────────────────────────┐
│                        数据源层                                      │
│  a03_e2e_customer_data_m（月度事实表）                               │
│  字段: data_date, platform, shop_info_id, user_id, is_member,       │
│        is_employee, customer_tier, net_pay_amt, net_pay_qty,        │
│        net_pay_order_cnt                                            │
│                                                                     │
│  DIM_Row_VIC_Tier（1:N 维度表，Tier ID: T1-T5）                     │
│  与 a03_e2e_customer_data_m[customer_tier] 1:N 关系                 │
└──────────────────────────────┬──────────────────────────────────────┘
                               │
                               │ 模型自动传递（行维度 = DIM_Row_VIC_Tier[Tier ID]）
                               │ + platform / shop_info_id 事实表字段直接拉取
                               │
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
│  │  │ net_pay_amt>0, 本期  │  │ net_pay_amt>0, LY    │         │    │
│  │  └──────────┬───────────┘  └──────────┬───────────┘         │    │
│  │  ┌──────────────────────┐  ┌──────────────────────┐         │    │
│  │  │ _SLS Base Act        │  │ _SLS Base LY         │         │    │
│  │  │ SUM(net_pay_amt),本期│  │ SUM(net_pay_amt), LY │         │    │
│  │  └──────────┬───────────┘  └──────────┬───────────┘         │    │
│  │  ┌──────────────────────┐  ┌──────────────────────┐         │    │
│  │  │ _SLS Total Base Act  │  │ _SLS Total Base LY   │         │    │
│  │  │ REMOVEFILTERS(Tier), │  │ REMOVEFILTERS(Tier), │         │    │
│  │  │ 本期                 │  │ LY                   │         │    │
│  │  └──────────┬───────────┘  └──────────┬───────────┘         │    │
│  │  ┌──────────────────────┐  ┌──────────────────────┐         │    │
│  │  │ _Net Pay Qty        │  │ _Net Pay Qty         │         │    │
│  │  │ Base Act             │  │ Base LY              │         │    │
│  │  └──────────┬───────────┘  └──────────┬───────────┘         │    │
│  │  ┌──────────────────────┐  ┌──────────────────────┐         │    │
│  │  │ _Net Pay Order Cnt  │  │ _Net Pay Order Cnt   │         │    │
│  │  │ Base Act             │  │ Base LY              │         │    │
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
│  │  Customer% vs LY Display       → #,##0.0%                    │    │
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
│  行: DIM_Row_VIC_Tier[Tier ID]（+ 可选 platform / shop_info_id）    │
│  值: 12 对独立 Value/Display 度量值（无 x 轴，无 SWITCH 路由）     │
│  说明: 指标 0（Tier）= 行维度字段本身，不需要度量值                  │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 7. 注意事项

1. **end period 时间筛选（关键逻辑）**：所有指标均使用 `Slicer_Time_Frame_Max[Last_Fiscal_Month_Min]` ~ `[Last_Fiscal_Month_Max]` 作为本期时间范围；YOY 派生的"去年"使用 `Last_Fiscal_Month_Min_LY` ~ `Last_Fiscal_Month_Max_LY`。这些字段已由 Slicer_Time_Frame_Max 日期维度表预算，无需在 DAX 中重复实现。
2. **is_member / is_employee 双重筛选（关键逻辑）**：所有指标均应用 `is_member = SELECTEDVALUE(IsMemberFilter[IsMember], 0)` 和 `is_employee = SELECTEDVALUE(Slicer_Is_Employee_Selection[IsEmployee_Code], 1)` 筛选。默认值：is_member=0（TTL VIC），is_employee=1（Yes）。
3. **分组维度自动传递（关键逻辑）**：

   - `customer_tier` 通过 DIM_Row_VIC_Tier 与 a03_e2e_customer_data_m 的 1:N 模型关系自动传递筛选，DAX 度量值无需显式处理分组
   - `platform`、`shop_info_id` 直接拉取事实表字段，模型自动传递筛选
   - 三者均为模型自动传递，DAX 无需显式处理
4. **指标 0 不需要度量值**：Tier 是行维度本身（`DIM_Row_VIC_Tier[Tier ID]` 字段直接拉取），不需要 Value/Display 度量值。本方案只对指标 1~12 输出度量值。
5. **SLS 的 Step 1 + Step 2 合并实现（关键逻辑）**：口径文档指标 5/7/9/10/11/12 均采用 Step1（dt=end period 框定 user_id 范围）+ Step2（该 user_id 在所选时间范围 sum）的口径。经业务确认 Step2 "所选时间范围" = end period 当月（与 Step1 一致）。因 customer_tier 分组由模型自动传递（当前行筛选即为 T1-T5），Step1+Step2 合并为：在 end period 当月直接对事实表做 SUM/DISTINCTCOUNT，无需显式用 TREATAS/CONTAINS 做 user_id 传递。
6. **SLS ÷ 1000（关键逻辑）**：口径文档第 125 行明确"报表上看到的数值 = 实际金额 ÷ 1,000"。SLS Value 度量值中 `DIVIDE(DIVIDE(__Base, __FXRate), 1000)`，先÷汇率再÷1000。Display 格式化为 `#,##0`（不再拼接 "k"），严格遵循口径文档数据格式。
7. **货币符号与汇率（关键逻辑）**：

   - 金额类指标（SLS / ACV / AUR）使用 `Slicer_Currency_Selection` 切片器
   - 汇率字段：`Slicer_Currency_Selection[Currency_ExchangeRate]`，默认 1
   - 货币符号字段：`Slicer_Currency_Selection[Currency_Symbol]`，默认 "¥"
   - Value 度量值中 `DIVIDE(SUM(net_pay_amt), __FXRate)` 做汇率换算
   - Display 度量值中 `__CurrencySymbol & FORMAT(__Value, "#,##0")` 拼接货币符号
   - 参考实现：Member/Customer_Member_Indicator.md
8. **ACV / AUR 不÷1000**：口径文档 ACV / AUR 数据格式为 `#,##0`（currency），未要求 ÷1000，与 SLS (in K) 不同。ACV / AUR Value 度量值只÷汇率，不÷1000。
9. **SLS% 分母 REMOVEFILTERS（关键逻辑）**：口径文档第 157 行明确"分母需要移除 a03_e2e_customer_data_m 中 customer_tier 字段对表的影响，但同时需要保留外部切片器的影响，我理解使用 ALLSELECTED"。本方案采用 `REMOVEFILTERS(DIM_Row_VIC_Tier)` 实现：移除 DIM_Row_VIC_Tier 的筛选传递，保留 platform / shop_info_id / is_member / is_employee 等外部筛选器。这与 ALLSELECTED 效果一致但语义更清晰。
10. **YOY 派生的"去年"定义（关键逻辑）**：

    - Customer No. vs LY / SLS vs LY / Customer% vs LY: 今年 / 去年 - 1（百分比变化，percent_1dp 不含正号）
    - SLS % vs LY: 今年 - 去年（差值，×100 转 pts，integer_pts 不含正号）
    - "去年"采用 LY end period 时间偏移（读取 `Slicer_Time_Frame_Max[Last_Fiscal_Month_Min_LY/Max_LY]`）
11. **YOY 数据格式不含正号（关键差异）**：口径文档指标 2 / 4 / 6 数据格式为 `#,##0.0%`（percent_1dp，不含正号），指标 8 数据格式为 `#,##0pts;-#,##0pts;0pts`（integer_pts，不含正号）。本方案严格遵循口径文档，所有 YOY Display 不含正号。这与参考文件 LY_Last_Purchase_Time_Table.md 的 YOY 处理一致。
12. **SLS % vs LY 的 pts 转换**：口径文档第 177 行明确"直接使用 FORMAT(__Value * 100, "#,##0pts;-#,##0pts;0pts")"。Value 度量返回原始差值（小数），Display 度量乘以 100 转 pts。
13. **分母为零或 BLANK 处理**：

    - DIVIDE 默认分母为 0/BLANK 时返回 BLANK，Display 显示 "-"
    - YOY 类指标显式判断去年值为 0/BLANK 时返回 BLANK（避免除零错误）
    - SLS% vs LY 判断今年或去年为 BLANK 时返回 BLANK
14. **私有基础层度量值命名约定**：内部基础层度量值以 `_` 下划线前缀命名（如 `_Customer No. Base Act`），放 Base Metrics 文件夹，供对外 Value 层调用，避免重复代码。对外暴露的是 12 对 Value/Display 度量值，符合"独立输出每个指标的 Value 和 Display 度量"的要求。
15. **无 SWITCH 路由**：与参考文件 VIC_KPIs_Table.md 的矩阵 SWITCH 路由范式不同，本方案为表格视觉，每个指标独立度量值，无 Metric_ID 路由，无 REMOVEFILTERS(Dim_ColMetric) 机制（SLS% 分母的 REMOVEFILTERS(DIM_Row_VIC_Tier) 是移除 customer_tier 分组，与 SWITCH 路由无关），无列维度表依赖。度量值结构更简单直接。
16. **无 x 轴时间处理**：表格视觉无列维度，不需要处理 x 轴上的当前时间。所有指标共享同一行上下文（customer_tier / platform / shop_info_id 分组），end period 时间筛选由 Slicer_Time_Frame_Max 统一提供。
17. **预留 LY 基础值**：_Net Pay Qty Base LY 和 _Net Pay Order Cnt Base LY 当前 YOY 指标未直接使用（口径文档 UPT / Freq. / AUR 未定义 YOY 派生），但预留以备后续扩展。
18. **与参考文件 LY_Last_Purchase_Time_Table.md 的关系**：本方案为 Customer Dashboard VIC Tab 的 VIC Segment 表格版本，与 LY Last Purchase Time 表格版本共享相同的架构基础（表格视觉 + 每指标独立 Value/Display 度量 + 无 SWITCH 路由 + is_member/is_employee 双重筛选 + end period 时间筛选 + LY 财历映射），差异在于：

    - 行维度由 last_fy_last_order_month_type（事实表字段）改为 DIM_Row_VIC_Tier（1:N 模型关系）
    - 指标数量由 7 对扩展为 12 对
    - 新增金额类指标（SLS / ACV / AUR），引入货币符号 + 汇率换算
    - 新增 SLS 的 Step 1 + Step 2 口径（经业务确认 Step2 时间= end period 当月）
    - 新增 SLS% 分母的 REMOVEFILTERS(DIM_Row_VIC_Tier) 机制
    - 派生指标类型由 VIC Repurchase% / VIC Retention% 简化为 Customer No. vs LY / Customer% vs LY / SLS vs LY / SLS% vs LY
    - 字段筛选由 is_fy_vic / is_fy_retention_vic / last_12m_net_pay_amt 改为无 VIC 标识字段筛选（直接按 customer_tier 分组）
