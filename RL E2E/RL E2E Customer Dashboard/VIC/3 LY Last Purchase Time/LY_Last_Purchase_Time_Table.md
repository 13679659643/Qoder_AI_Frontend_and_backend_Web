# Power BI 解决方案 — LY Last Purchase Time 表格（独立度量值）

> status: ready
> created: 2026-08-14
> type: 度量值开发 + 表格可视化
> 口径来源: 口径文档/LY Last Purchase Time.md（子模块三 VIC Composition & By Recency Repurchase，8 个指标，指标1 为行维度本身）
> 参考实现: VIC/VIC KPI/VIC_KPIs_Table.md（矩阵 SWITCH 路由范式，本方案差异：表格视觉 + 每指标独立 Value/Display 度量，无 SWITCH 路由，无 x 轴时间处理）

---

## 1. 需求理解

为 Customer Dashboard - VIC Tab 实现 LY Last Purchase Time 表格：

- **视觉对象**：Table（表格），非 Matrix
- **行维度**：`a03_e2e_customer_data_m[last_fy_last_order_month_type]`（R3 / R4-6 / R7-9 / R10-12），可选叠加 `platform` / `shop_info_id` 粒度
  - 行维度字段直接拉取事实表字段实现自动传递，模型自动传递筛选，DAX 无需显式处理分组
  - 无行维度表，不使用 DIM_Row_LY_Last_Purchase_Time.md（该表为矩阵场景预留，本表格方案直接拉事实表字段）
- **无 x 轴**：表格视觉无列维度，不需要处理 x 轴上的当前时间
- **指标输出**：每个指标独立输出 Value（值）和 Display（格式化显示）两个度量值，不使用 SWITCH 路由
- **指标范围**：口径文档定义 8 个指标，其中指标 1（LY Last Purchase Time）为行维度本身（字段直接拉取，不需要度量值），其余 7 个指标（指标 2~8）需要独立 Value + Display 度量值
- **口径**：一切以口径文档为准

### 1.1 关键特殊逻辑一：end period 时间筛选

口径文档全局逻辑要求：

> **聚合粒度**: `dt = 所选时间范围 end period`，`platform, shop_info_id`
> **end period 说明**: 所选时间范围的最后一个财月，只关注 Slicer_Time_Frame_Max 值

子模块三所有指标（指标 2~8）均应用 end period 时间筛选到事实表 `data_date`：

- 本期：`data_date ∈ [Last_Fiscal_Month_Min, Last_Fiscal_Month_Max]`
- LY（用于 YOY 分子）：`data_date ∈ [Last_Fiscal_Month_Min_LY, Last_Fiscal_Month_Max_LY]`

`Slicer_Time_Frame_Max` 已内置 `Last_Fiscal_Month_*` 系列字段，直接 SELECTEDVALUE 读取即可，无需 EDATE 计算。

### 1.2 关键特殊逻辑二：is_member / is_employee 双重人群筛选

口径文档要求：

> **is_member 使用**: `VAR __IsMemberFilter = SELECTEDVALUE(IsMemberFilter[IsMember], 0)`，默认 TTL VIC
> **is_employee 使用**: `VAR __IsEmployeeFilter = SELECTEDVALUE(Slicer_Is_Employee_Selection[IsEmployee_Code], 1)`，默认 Yes

所有指标均应用这两个筛选到事实表 `a03_e2e_customer_data_m[is_member]` / `[is_employee]`。

### 1.3 关键特殊逻辑三：行维度字段自动传递

口径文档明确：

> **分组维度**: `a03_e2e_customer_data_m[last_fy_last_order_month_type]`，字段值包括：R3, R4-6, R7-9, R10-12
> **分组维度由表字段自动传递，DAX 无需显式处理分组**
> **聚合粒度**: `platform, shop_info_id` 分组维度由表字段自动传递，DAX 无需显式处理

`last_fy_last_order_month_type`、`platform`、`shop_info_id` 三个分组维度直接拉取事实表字段，模型自动传递筛选，DAX 度量值无需显式处理分组逻辑。

### 1.4 关键特殊逻辑四：YOY 派生指标的"去年"定义

口径文档指标 6（VIC Repurchase% YOY）和指标 8（VIC Retention% YOY）：

> **计算公式**: 今年 / 去年 - 1

"去年"采用 LY end period 时间偏移（读取 `Slicer_Time_Frame_Max[Last_Fiscal_Month_Min_LY/Max_LY]`），对事实表 `data_date` 做 LY 区间筛选。派生公式展开：

- VIC Repurchase% YOY = (今年 VIC Repurchase No. / 今年 LY VIC No.) / (去年 VIC Repurchase No. / 去年 LY VIC No.) - 1
- VIC Retention% YOY = (今年 VIC Retention No. / 今年 LY VIC No.) / (去年 VIC Retention No. / 去年 LY VIC No.) - 1

其中"今年"= end period 当期，"去年"= LY end period。分子分母均使用同一时间区间的字段筛选。

### 1.5 与参考文件 VIC_KPIs_Table.md 的关键差异

| 维度 | 参考文件（VIC_KPIs_Table.md） | 本方案（LY_Last_Purchase_Time_Table.md） |
|---|---|---|
| 视觉对象 | Matrix（矩阵） | Table（表格） |
| 列维度 | Dim_ColMetric_VIC_KPIs 断开维度 + KPIGroup > ColName 两级层级 | 无列维度，无 x 轴 |
| 路由方式 | SWITCH 动态路由（按 Metric_ID 分发） | 每指标独立度量值，无 SWITCH |
| 度量值输出 | Cell Value / Cell Display 单一度量值统管所有指标 | 每指标独立 Value + Display 度量值（共 7 对） |
| 时间逻辑 | end period 当月 DISTINCTCOUNT + VIC Retention% Rolling 12 分母 | end period 当月 DISTINCTCOUNT，无 Rolling 12 分母 |
| 字段筛选 | is_vic / is_retention_vic / is_upgrade_vic / is_direct_vic | is_fy_vic / is_fy_retention_vic / last_12m_net_pay_amt |
| YOY 时间偏移 | 不涉及（用 vs LY / vs LP 派生） | 涉及（YOY 用 LY end period 时间偏移） |

---

## 2. 现状分析

### 2.1 数据底表

| 对象 | 名称 | 出处 |
|---|---|---|
| 事实表 | a03_e2e_customer_data_m | 口径文档全局逻辑 |
| 关键字段 | data_date, platform, shop_info_id, user_id, is_member, is_employee, is_fy_vic, is_fy_retention_vic, last_12m_net_pay_amt, last_fy_last_order_month_type | 口径文档子模块三各指标 |

> 表为月度聚合表，`data_date` 为月末日期，用于 end period 时间筛选。

### 2.2 维度表清单

| 维度表 | 类型 | 连接方式 |
|---|---|---|
| Slicer_Time_Frame_Max | 断开维度 | SELECTEDVALUE 读取 `Last_Fiscal_Month_Min/Max`（本期自然日）、`Last_Fiscal_Month_Min_LY/Max_LY`（LY 区间自然日，已预算，YOY 直接读） |
| Slicer_Time_Frame_Min | 断开维度 | 本方案 end period 逻辑不使用（仅 Max 即可） |
| Slicer_Is_Employee_Selection | 断开维度 | SELECTEDVALUE 读取 `IsEmployee_Code` |
| IsMemberFilter | 断开维度 | SELECTEDVALUE 读取 `IsMember` |
| Slicer_Platform_Selection | 断开维度 | 行维度直接拉事实表 platform 字段，模型自动传递 |
| Slicer_Store_Name | 断开维度 | 行维度直接拉事实表 shop_info_id 字段，模型自动传递 |
| Slicer_Currency_Selection | 断开维度 | 本方案无金额类指标，不参与计算 |

> **行维度处理**：`last_fy_last_order_month_type` / `platform` / `shop_info_id` 直接拉取事实表字段实现自动传递，模型自动传递筛选，DAX 无需显式处理。

---

## 3. 方案设计

### 3.1 整体架构

```
核心思路：表格视觉 + 每指标独立 Value/Display 度量值（无 SWITCH 路由）

a03_e2e_customer_data_m（事实表）
    │
    │  行维度字段直接拉取：
    │  - last_fy_last_order_month_type（R3 / R4-6 / R7-9 / R10-12）
    │  - platform / shop_info_id（可选叠加粒度）
    │  模型自动传递筛选，DAX 无需显式处理
    │
    ▼
┌─────────────────────────── Table 视觉对象 ──────────────────────────┐
│  行 = 事实表字段（last_fy_last_order_month_type / platform / shop_info_id）│
│  值 = 7 对独立 Value/Display 度量值                                  │
│       - LY VIC No. Value / Display                                  │
│       - VIC Repurchase No. Value / Display                          │
│       - VIC Retention No. Value / Display                           │
│       - VIC Repurchase% Value / Display                             │
│       - VIC Repurchase% YOY Value / Display                         │
│       - VIC Retention% Value / Display                              │
│       - VIC Retention% YOY Value / Display                          │
└──────────────────────────────────────────────────────────────────────┘
                                   ▲
                                   │
              度量值链（每指标独立，无 SWITCH 路由）
              ┌────────────────────────────────────────────────────┐
              │  内部基础层（Base，私有，下划线前缀）              │
              │  ├ _LY VIC No. Base Act / _LY VIC No. Base LY     │
              │  ├ _VIC Repurchase No. Base Act / Base LY         │
              │  └ _VIC Retention No. Base Act / Base LY          │
              │     统一应用 is_member / is_employee / end period │
              │     Act 用本期区间，LY 用 LY 区间                 │
              │                                                    │
              │  对外 Value 层（7 个独立度量值）                  │
              │  ├ LY VIC No. Value = _LY VIC No. Base Act        │
              │  ├ VIC Repurchase No. Value = _Repurchase Base Act│
              │  ├ VIC Retention No. Value = _Retention Base Act  │
              │  ├ VIC Repurchase% Value = DIVIDE(分子Act, 分母Act)│
              │  ├ VIC Repurchase% YOY Value = 今年% / 去年% - 1  │
              │  ├ VIC Retention% Value = DIVIDE(分子Act, 分母Act)│
              │  └ VIC Retention% YOY Value = 今年% / 去年% - 1   │
              │                                                    │
              │  对外 Display 层（7 个独立度量值，按数据格式格式化）│
              └────────────────────────────────────────────────────┘
```

### 3.2 度量值模型设计

```
[内部基础层 — Base Act / Base LY]       ← 私有度量值（下划线前缀，放 Base Metrics 文件夹）
_LY VIC No. Base Act                    ← is_fy_vic=1，本期 end period 区间 DISTINCTCOUNT
_LY VIC No. Base LY                     ← is_fy_vic=1，LY end period 区间 DISTINCTCOUNT
_VIC Repurchase No. Base Act            ← is_fy_vic=1 AND last_12m_net_pay_amt>0，本期
_VIC Repurchase No. Base LY             ← is_fy_vic=1 AND last_12m_net_pay_amt>0，LY
_VIC Retention No. Base Act             ← is_fy_retention_vic=1，本期
_VIC Retention No. Base LY              ← is_fy_retention_vic=1，LY

[对外 Value 层 — 7 个独立度量值]        ← 放 Cell Values 文件夹
LY VIC No. Value                        ← = _LY VIC No. Base Act
VIC Repurchase No. Value                ← = _VIC Repurchase No. Base Act
VIC Retention No. Value                 ← = _VIC Retention No. Base Act
VIC Repurchase% Value                   ← = DIVIDE(_VIC Repurchase No. Base Act, _LY VIC No. Base Act)
VIC Repurchase% YOY Value               ← = DIVIDE(今年%, 去年%) - 1
VIC Retention% Value                    ← = DIVIDE(_VIC Retention No. Base Act, _LY VIC No. Base Act)
VIC Retention% YOY Value                ← = DIVIDE(今年%, 去年%) - 1

[对外 Display 层 — 7 个独立度量值]      ← 放 Formatting 文件夹
LY VIC No. Display                      ← integer 格式 #,##0
VIC Repurchase No. Display              ← integer 格式 #,##0
VIC Retention No. Display               ← integer 格式 #,##0
VIC Repurchase% Display                 ← percent_0dp 格式 #,##0%
VIC Repurchase% YOY Display             ← percent_1dp 格式 #,##0.0%（不含正号）
VIC Retention% Display                  ← percent_0dp 格式 #,##0%
VIC Retention% YOY Display              ← percent_1dp 格式 #,##0.0%（不含正号）
```

### 3.3 筛选器上下文

| 筛选器 | 作用方式 | DAX 处理 |
|---|---|---|
| Slicer_Time_Frame_Max（本期） | 断开维度，SELECTEDVALUE 读取 `Last_Fiscal_Month_Min/Max` | `data_date >= __PeriodMin AND data_date <= __PeriodMax` |
| Slicer_Time_Frame_Max（LY） | SELECTEDVALUE 读取 `Last_Fiscal_Month_Min_LY/Max_LY` | `data_date >= __LYMin AND data_date <= __LYMax`（YOY 派生专用） |
| Slicer_Is_Employee_Selection | 断开维度，SELECTEDVALUE 读取 `IsEmployee_Code` | `a03_e2e_customer_data_m[is_employee] = __IsEmployeeFilter` |
| IsMemberFilter | 断开维度，SELECTEDVALUE 读取 `IsMember` | `a03_e2e_customer_data_m[is_member] = __IsMemberFilter` |
| 事实表分组字段 | 表格行直接拉取，模型自动传递筛选 | DAX 无需显式处理 |

### 3.4 YOY 时间偏移规则（财历映射）

直接读取 Slicer_Time_Frame_Max 内置的 `Last_Fiscal_Month_*` 系列字段：

- 本期：`Last_Fiscal_Month_Min` ~ `Last_Fiscal_Month_Max`
- LY：`Last_Fiscal_Month_Min_LY` ~ `Last_Fiscal_Month_Max_LY`
- 无需 EDATE -12 或 Key 偏移计算

### 3.5 指标计算公式与数据格式

| 序号 | 指标名称 | 计算公式 | 数据类型 | 数据格式 |
|---|---|---|---|---|
| 1 | LY Last Purchase Time | 行维度字段直接拉取，不需要度量值 | — | — |
| 2 | LY VIC No. | count(distinct user_id) where is_fy_vic=1 | integer | `#,##0` |
| 3 | VIC Repurchase No. | count(distinct user_id) where is_fy_vic=1 AND last_12m_net_pay_amt>0 | integer | `#,##0` |
| 4 | VIC Retention No. | count(distinct user_id) where is_fy_retention_vic=1 | integer | `#,##0` |
| 5 | VIC Repurchase% | VIC Repurchase No. / LY VIC No. | percent_0dp | `#,##0%` |
| 6 | VIC Repurchase% YOY | 今年 VIC Repurchase% / 去年 VIC Repurchase% - 1 | percent_1dp | `#,##0.0%` |
| 7 | VIC Retention% | VIC Retention No. / LY VIC No. | percent_0dp | `#,##0%` |
| 8 | VIC Retention% YOY | 今年 VIC Retention% / 去年 VIC Retention% - 1 | percent_1dp | `#,##0.0%` |

> **YOY 格式说明**：口径文档指标 6 / 8 数据格式为 `#,##0.0%`（percent_1dp，不含正号），与参考文件 VIC_KPIs_Table.md 中 vs LY 使用 `delta_pct_1dp`（含正号）不同。本方案严格遵循口径文档，YOY 不含正号。

---

## 4. 度量值实现

### 4.1 内部基础层 — Base Act / Base LY（私有度量值）

> 私有度量值（下划线前缀），放 Base Metrics 文件夹，供对外 Value 层调用，避免重复代码。
> Act = 本期 end period 区间，LY = LY end period 区间。

#### 4.1.1 _LY VIC No. Base Act（LY VIC No. 本期基础值）

```dax
_LY VIC No. Base Act = 
// ========================================
// 度量值: _LY VIC No. Base Act
// Display Folder: Base Metrics
// 用途: LY VIC No.（去年VIC人数）本期基础值
// 依赖: a03_e2e_customer_data_m,
//       Slicer_Time_Frame_Max[Last_Fiscal_Month_Min/Max],
//       Slicer_Is_Employee_Selection[IsEmployee_Code],
//       IsMemberFilter[IsMember]
// 口径来源: 口径文档/LY Last Purchase Time.md 指标 2
// 筛选上下文:
//   - data_date ∈ [Last_Fiscal_Month_Min, Last_Fiscal_Month_Max]（end period 当月）
//   - is_fy_vic = 1
//   - is_member = __IsMemberFilter（默认 0 = TTL VIC）
//   - is_employee = __IsEmployeeFilter（默认 1 = Yes）
// 聚合粒度: DISTINCTCOUNT(user_id)
// ========================================
    VAR __PeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Max[Last_Fiscal_Month_Min])
    VAR __PeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max[Last_Fiscal_Month_Max])
    VAR __IsMemberFilter = SELECTEDVALUE(IsMemberFilter[IsMember], 0)
    VAR __IsEmployeeFilter = SELECTEDVALUE(Slicer_Is_Employee_Selection[IsEmployee_Code], 1)

    RETURN
        CALCULATE(
            DISTINCTCOUNT('a03_e2e_customer_data_m'[user_id]),
            'a03_e2e_customer_data_m'[is_fy_vic] = 1,
            'a03_e2e_customer_data_m'[is_member] = __IsMemberFilter,
            'a03_e2e_customer_data_m'[is_employee] = __IsEmployeeFilter,
            'a03_e2e_customer_data_m'[data_date] >= __PeriodMin,
            'a03_e2e_customer_data_m'[data_date] <= __PeriodMax
        )
```

#### 4.1.2 _LY VIC No. Base LY（LY VIC No. 去年同期基础值）

```dax
_LY VIC No. Base LY = 
// ========================================
// 度量值: _LY VIC No. Base LY
// Display Folder: Base Metrics
// 用途: LY VIC No.（去年VIC人数）去年同期基础值，用于 YOY 派生
// 依赖: a03_e2e_customer_data_m,
//       Slicer_Time_Frame_Max[Last_Fiscal_Month_Min_LY/Max_LY],
//       Slicer_Is_Employee_Selection[IsEmployee_Code],
//       IsMemberFilter[IsMember]
// 口径来源: 口径文档/LY Last Purchase Time.md 指标 2（LY 版本，用于指标 6 YOY 分母）
// 筛选上下文:
//   - data_date ∈ [Last_Fiscal_Month_Min_LY, Last_Fiscal_Month_Max_LY]（LY end period 当月）
//   - is_fy_vic = 1
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
            'a03_e2e_customer_data_m'[is_fy_vic] = 1,
            'a03_e2e_customer_data_m'[is_member] = __IsMemberFilter,
            'a03_e2e_customer_data_m'[is_employee] = __IsEmployeeFilter,
            'a03_e2e_customer_data_m'[data_date] >= __LYMin,
            'a03_e2e_customer_data_m'[data_date] <= __LYMax
        )
```

#### 4.1.3 _VIC Repurchase No. Base Act（VIC Repurchase No. 本期基础值）

```dax
_VIC Repurchase No. Base Act = 
// ========================================
// 度量值: _VIC Repurchase No. Base Act
// Display Folder: Base Metrics
// 用途: VIC Repurchase No.（复购VIC人数）本期基础值
// 依赖: a03_e2e_customer_data_m,
//       Slicer_Time_Frame_Max[Last_Fiscal_Month_Min/Max],
//       Slicer_Is_Employee_Selection[IsEmployee_Code],
//       IsMemberFilter[IsMember]
// 口径来源: 口径文档/LY Last Purchase Time.md 指标 3
// 筛选上下文:
//   - data_date ∈ [Last_Fiscal_Month_Min, Last_Fiscal_Month_Max]（end period 当月）
//   - is_fy_vic = 1
//   - last_12m_net_pay_amt > 0
//   - is_member / is_employee 双重人群筛选
// 聚合粒度: DISTINCTCOUNT(user_id)
// ========================================
    VAR __PeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Max[Last_Fiscal_Month_Min])
    VAR __PeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max[Last_Fiscal_Month_Max])
    VAR __IsMemberFilter = SELECTEDVALUE(IsMemberFilter[IsMember], 0)
    VAR __IsEmployeeFilter = SELECTEDVALUE(Slicer_Is_Employee_Selection[IsEmployee_Code], 1)

    RETURN
        CALCULATE(
            DISTINCTCOUNT('a03_e2e_customer_data_m'[user_id]),
            'a03_e2e_customer_data_m'[is_fy_vic] = 1,
            'a03_e2e_customer_data_m'[last_12m_net_pay_amt] > 0,
            'a03_e2e_customer_data_m'[is_member] = __IsMemberFilter,
            'a03_e2e_customer_data_m'[is_employee] = __IsEmployeeFilter,
            'a03_e2e_customer_data_m'[data_date] >= __PeriodMin,
            'a03_e2e_customer_data_m'[data_date] <= __PeriodMax
        )
```

#### 4.1.4 _VIC Repurchase No. Base LY（VIC Repurchase No. 去年同期基础值）

```dax
_VIC Repurchase No. Base LY = 
// ========================================
// 度量值: _VIC Repurchase No. Base LY
// Display Folder: Base Metrics
// 用途: VIC Repurchase No.（复购VIC人数）去年同期基础值，用于 YOY 派生
// 依赖: a03_e2e_customer_data_m,
//       Slicer_Time_Frame_Max[Last_Fiscal_Month_Min_LY/Max_LY],
//       Slicer_Is_Employee_Selection[IsEmployee_Code],
//       IsMemberFilter[IsMember]
// 口径来源: 口径文档/LY Last Purchase Time.md 指标 3（LY 版本，用于指标 6 YOY 分子）
// 筛选上下文:
//   - data_date ∈ [Last_Fiscal_Month_Min_LY, Last_Fiscal_Month_Max_LY]（LY end period 当月）
//   - is_fy_vic = 1
//   - last_12m_net_pay_amt > 0
//   - is_member / is_employee 双重人群筛选
// 时间偏移: 财历映射，直接读取 Slicer_Time_Frame_Max 已预算字段
// ========================================
    VAR __LYMin = SELECTEDVALUE(Slicer_Time_Frame_Max[Last_Fiscal_Month_Min_LY])
    VAR __LYMax = SELECTEDVALUE(Slicer_Time_Frame_Max[Last_Fiscal_Month_Max_LY])
    VAR __IsMemberFilter = SELECTEDVALUE(IsMemberFilter[IsMember], 0)
    VAR __IsEmployeeFilter = SELECTEDVALUE(Slicer_Is_Employee_Selection[IsEmployee_Code], 1)

    RETURN
        CALCULATE(
            DISTINCTCOUNT('a03_e2e_customer_data_m'[user_id]),
            'a03_e2e_customer_data_m'[is_fy_vic] = 1,
            'a03_e2e_customer_data_m'[last_12m_net_pay_amt] > 0,
            'a03_e2e_customer_data_m'[is_member] = __IsMemberFilter,
            'a03_e2e_customer_data_m'[is_employee] = __IsEmployeeFilter,
            'a03_e2e_customer_data_m'[data_date] >= __LYMin,
            'a03_e2e_customer_data_m'[data_date] <= __LYMax
        )
```

#### 4.1.5 _VIC Retention No. Base Act（VIC Retention No. 本期基础值）

```dax
_VIC Retention No. Base Act = 
// ========================================
// 度量值: _VIC Retention No. Base Act
// Display Folder: Base Metrics
// 用途: VIC Retention No.（留存VIC人数）本期基础值
// 依赖: a03_e2e_customer_data_m,
//       Slicer_Time_Frame_Max[Last_Fiscal_Month_Min/Max],
//       Slicer_Is_Employee_Selection[IsEmployee_Code],
//       IsMemberFilter[IsMember]
// 口径来源: 口径文档/LY Last Purchase Time.md 指标 4
// 筛选上下文:
//   - data_date ∈ [Last_Fiscal_Month_Min, Last_Fiscal_Month_Max]（end period 当月）
//   - is_fy_retention_vic = 1
//   - is_member / is_employee 双重人群筛选
// 聚合粒度: DISTINCTCOUNT(user_id)
// ========================================
    VAR __PeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Max[Last_Fiscal_Month_Min])
    VAR __PeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max[Last_Fiscal_Month_Max])
    VAR __IsMemberFilter = SELECTEDVALUE(IsMemberFilter[IsMember], 0)
    VAR __IsEmployeeFilter = SELECTEDVALUE(Slicer_Is_Employee_Selection[IsEmployee_Code], 1)

    RETURN
        CALCULATE(
            DISTINCTCOUNT('a03_e2e_customer_data_m'[user_id]),
            'a03_e2e_customer_data_m'[is_fy_retention_vic] = 1,
            'a03_e2e_customer_data_m'[is_member] = __IsMemberFilter,
            'a03_e2e_customer_data_m'[is_employee] = __IsEmployeeFilter,
            'a03_e2e_customer_data_m'[data_date] >= __PeriodMin,
            'a03_e2e_customer_data_m'[data_date] <= __PeriodMax
        )
```

#### 4.1.6 _VIC Retention No. Base LY（VIC Retention No. 去年同期基础值）

```dax
_VIC Retention No. Base LY = 
// ========================================
// 度量值: _VIC Retention No. Base LY
// Display Folder: Base Metrics
// 用途: VIC Retention No.（留存VIC人数）去年同期基础值，用于 YOY 派生
// 依赖: a03_e2e_customer_data_m,
//       Slicer_Time_Frame_Max[Last_Fiscal_Month_Min_LY/Max_LY],
//       Slicer_Is_Employee_Selection[IsEmployee_Code],
//       IsMemberFilter[IsMember]
// 口径来源: 口径文档/LY Last Purchase Time.md 指标 4（LY 版本，用于指标 8 YOY 分子）
// 筛选上下文:
//   - data_date ∈ [Last_Fiscal_Month_Min_LY, Last_Fiscal_Month_Max_LY]（LY end period 当月）
//   - is_fy_retention_vic = 1
//   - is_member / is_employee 双重人群筛选
// 时间偏移: 财历映射，直接读取 Slicer_Time_Frame_Max 已预算字段
// ========================================
    VAR __LYMin = SELECTEDVALUE(Slicer_Time_Frame_Max[Last_Fiscal_Month_Min_LY])
    VAR __LYMax = SELECTEDVALUE(Slicer_Time_Frame_Max[Last_Fiscal_Month_Max_LY])
    VAR __IsMemberFilter = SELECTEDVALUE(IsMemberFilter[IsMember], 0)
    VAR __IsEmployeeFilter = SELECTEDVALUE(Slicer_Is_Employee_Selection[IsEmployee_Code], 1)

    RETURN
        CALCULATE(
            DISTINCTCOUNT('a03_e2e_customer_data_m'[user_id]),
            'a03_e2e_customer_data_m'[is_fy_retention_vic] = 1,
            'a03_e2e_customer_data_m'[is_member] = __IsMemberFilter,
            'a03_e2e_customer_data_m'[is_employee] = __IsEmployeeFilter,
            'a03_e2e_customer_data_m'[data_date] >= __LYMin,
            'a03_e2e_customer_data_m'[data_date] <= __LYMax
        )
```

### 4.2 对外 Value 层 — 7 个独立度量值

#### 4.2.1 LY VIC No. Value

```dax
LY VIC No. Value = 
// ========================================
// 度量值: LY VIC No. Value
// Display Folder: Cell Values
// 用途: 指标 2 — 去年VIC人数（对外值）
// 依赖: [_LY VIC No. Base Act]
// 口径来源: 口径文档/LY Last Purchase Time.md 指标 2
// ========================================
    [_LY VIC No. Base Act]
```

#### 4.2.2 VIC Repurchase No. Value

```dax
VIC Repurchase No. Value = 
// ========================================
// 度量值: VIC Repurchase No. Value
// Display Folder: Cell Values
// 用途: 指标 3 — 复购VIC人数（对外值）
// 依赖: [_VIC Repurchase No. Base Act]
// 口径来源: 口径文档/LY Last Purchase Time.md 指标 3
// ========================================
    [_VIC Repurchase No. Base Act]
```

#### 4.2.3 VIC Retention No. Value

```dax
VIC Retention No. Value = 
// ========================================
// 度量值: VIC Retention No. Value
// Display Folder: Cell Values
// 用途: 指标 4 — 留存VIC人数（对外值）
// 依赖: [_VIC Retention No. Base Act]
// 口径来源: 口径文档/LY Last Purchase Time.md 指标 4
// ========================================
    [_VIC Retention No. Base Act]
```

#### 4.2.4 VIC Repurchase% Value

```dax
VIC Repurchase% Value = 
// ========================================
// 度量值: VIC Repurchase% Value
// Display Folder: Cell Values
// 用途: 指标 5 — 复购VIC占比（对外值）
// 依赖: [_VIC Repurchase No. Base Act], [_LY VIC No. Base Act]
// 口径来源: 口径文档/LY Last Purchase Time.md 指标 5
// 计算公式: 分子 VIC Repurchase No. / 分母 LY VIC No.
// 边界处理: 分母为 0 或 BLANK 时返回 BLANK（DIVIDE 默认行为）
// ========================================
    DIVIDE(
        [_VIC Repurchase No. Base Act],
        [_LY VIC No. Base Act]
    )
```

#### 4.2.5 VIC Repurchase% YOY Value

```dax
VIC Repurchase% YOY Value = 
// ========================================
// 度量值: VIC Repurchase% YOY Value
// Display Folder: Cell Values
// 用途: 指标 6 — 复购VIC占比YOY（对外值）
// 依赖: [_VIC Repurchase No. Base Act], [_LY VIC No. Base Act],
//       [_VIC Repurchase No. Base LY], [_LY VIC No. Base LY]
// 口径来源: 口径文档/LY Last Purchase Time.md 指标 6
// 计算公式: 今年 VIC Repurchase% / 去年 VIC Repurchase% - 1
//   今年 VIC Repurchase% = _VIC Repurchase No. Base Act / _LY VIC No. Base Act
//   去年 VIC Repurchase% = _VIC Repurchase No. Base LY / _LY VIC No. Base LY
// 边界处理: 去年% 为 0 或 BLANK 时返回 BLANK
// 时间偏移: 去年 = LY end period（Slicer_Time_Frame_Max Last_Fiscal_Month_*_LY 字段）
// ========================================
    VAR __PctAct = DIVIDE([_VIC Repurchase No. Base Act], [_LY VIC No. Base Act])
    VAR __PctLY = DIVIDE([_VIC Repurchase No. Base LY], [_LY VIC No. Base LY])

    RETURN
        IF(
            ISBLANK(__PctLY) || __PctLY = 0,
            BLANK(),
            DIVIDE(__PctAct, __PctLY) - 1
        )
```

#### 4.2.6 VIC Retention% Value

```dax
VIC Retention% Value = 
// ========================================
// 度量值: VIC Retention% Value
// Display Folder: Cell Values
// 用途: 指标 7 — 留存VIC占比（对外值）
// 依赖: [_VIC Retention No. Base Act], [_LY VIC No. Base Act]
// 口径来源: 口径文档/LY Last Purchase Time.md 指标 7
// 计算公式: 分子 VIC Retention No. / 分母 LY VIC No.
// 边界处理: 分母为 0 或 BLANK 时返回 BLANK（DIVIDE 默认行为）
// ========================================
    DIVIDE(
        [_VIC Retention No. Base Act],
        [_LY VIC No. Base Act]
    )
```

#### 4.2.7 VIC Retention% YOY Value

```dax
VIC Retention% YOY Value = 
// ========================================
// 度量值: VIC Retention% YOY Value
// Display Folder: Cell Values
// 用途: 指标 8 — 留存VIC占比YOY（对外值）
// 依赖: [_VIC Retention No. Base Act], [_LY VIC No. Base Act],
//       [_VIC Retention No. Base LY], [_LY VIC No. Base LY]
// 口径来源: 口径文档/LY Last Purchase Time.md 指标 8
// 计算公式: 今年 VIC Retention% / 去年 VIC Retention% - 1
//   今年 VIC Retention% = _VIC Retention No. Base Act / _LY VIC No. Base Act
//   去年 VIC Retention% = _VIC Retention No. Base LY / _LY VIC No. Base LY
// 边界处理: 去年% 为 0 或 BLANK 时返回 BLANK
// 时间偏移: 去年 = LY end period（Slicer_Time_Frame_Max Last_Fiscal_Month_*_LY 字段）
// ========================================
    VAR __PctAct = DIVIDE([_VIC Retention No. Base Act], [_LY VIC No. Base Act])
    VAR __PctLY = DIVIDE([_VIC Retention No. Base LY], [_LY VIC No. Base LY])

    RETURN
        IF(
            ISBLANK(__PctLY) || __PctLY = 0,
            BLANK(),
            DIVIDE(__PctAct, __PctLY) - 1
        )
```

### 4.3 对外 Display 层 — 7 个独立度量值

> 严格遵循口径文档数据格式定义：
> - integer → `#,##0`（千分位整数）
> - percent_0dp → `#,##0%`（百分比整数，不含正号）
> - percent_1dp → `#,##0.0%`（百分比一位小数，不含正号）
>
> BLANK 显示为 "-"。

#### 4.3.1 LY VIC No. Display

```dax
LY VIC No. Display = 
// ========================================
// 度量值: LY VIC No. Display
// Display Folder: Formatting
// 用途: 指标 2 — 去年VIC人数（格式化显示）
// 依赖: [LY VIC No. Value]
// 数据格式: integer → #,##0
// ========================================
    VAR __Value = [LY VIC No. Value]
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            FORMAT(__Value, "#,##0")
        )
```

#### 4.3.2 VIC Repurchase No. Display

```dax
VIC Repurchase No. Display = 
// ========================================
// 度量值: VIC Repurchase No. Display
// Display Folder: Formatting
// 用途: 指标 3 — 复购VIC人数（格式化显示）
// 依赖: [VIC Repurchase No. Value]
// 数据格式: integer → #,##0
// ========================================
    VAR __Value = [VIC Repurchase No. Value]
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            FORMAT(__Value, "#,##0")
        )
```

#### 4.3.3 VIC Retention No. Display

```dax
VIC Retention No. Display = 
// ========================================
// 度量值: VIC Retention No. Display
// Display Folder: Formatting
// 用途: 指标 4 — 留存VIC人数（格式化显示）
// 依赖: [VIC Retention No. Value]
// 数据格式: integer → #,##0
// ========================================
    VAR __Value = [VIC Retention No. Value]
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            FORMAT(__Value, "#,##0")
        )
```

#### 4.3.4 VIC Repurchase% Display

```dax
VIC Repurchase% Display = 
// ========================================
// 度量值: VIC Repurchase% Display
// Display Folder: Formatting
// 用途: 指标 5 — 复购VIC占比（格式化显示）
// 依赖: [VIC Repurchase% Value]
// 数据格式: percent_0dp → #,##0%（百分比整数，不含正号）
// ========================================
    VAR __Value = [VIC Repurchase% Value]
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            FORMAT(__Value, "#,##0%")
        )
```

#### 4.3.5 VIC Repurchase% YOY Display

```dax
VIC Repurchase% YOY Display = 
// ========================================
// 度量值: VIC Repurchase% YOY Display
// Display Folder: Formatting
// 用途: 指标 6 — 复购VIC占比YOY（格式化显示）
// 依赖: [VIC Repurchase% YOY Value]
// 数据格式: percent_1dp → #,##0.0%（百分比一位小数，不含正号）
// 注: 口径文档明确定义为 #,##0.0%，不含正号
// ========================================
    VAR __Value = [VIC Repurchase% YOY Value]
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            FORMAT(__Value, "#,##0.0%")
        )
```

#### 4.3.6 VIC Retention% Display

```dax
VIC Retention% Display = 
// ========================================
// 度量值: VIC Retention% Display
// Display Folder: Formatting
// 用途: 指标 7 — 留存VIC占比（格式化显示）
// 依赖: [VIC Retention% Value]
// 数据格式: percent_0dp → #,##0%（百分比整数，不含正号）
// ========================================
    VAR __Value = [VIC Retention% Value]
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            FORMAT(__Value, "#,##0%")
        )
```

#### 4.3.7 VIC Retention% YOY Display

```dax
VIC Retention% YOY Display = 
// ========================================
// 度量值: VIC Retention% YOY Display
// Display Folder: Formatting
// 用途: 指标 8 — 留存VIC占比YOY（格式化显示）
// 依赖: [VIC Retention% YOY Value]
// 数据格式: percent_1dp → #,##0.0%（百分比一位小数，不含正号）
// 注: 口径文档明确定义为 #,##0.0%，不含正号
// ========================================
    VAR __Value = [VIC Retention% YOY Value]
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            FORMAT(__Value, "#,##0.0%")
        )
```

---

## 5. 度量值清单与 Display Folder

| 序号 | 度量值名称 | Display Folder | 用途 |
|---|---|---|---|
| 1 | _LY VIC No. Base Act | Base Metrics | LY VIC No. 本期基础值（私有，供派生调用） |
| 2 | _LY VIC No. Base LY | Base Metrics | LY VIC No. 去年同期基础值（私有，YOY 分母用） |
| 3 | _VIC Repurchase No. Base Act | Base Metrics | VIC Repurchase No. 本期基础值（私有） |
| 4 | _VIC Repurchase No. Base LY | Base Metrics | VIC Repurchase No. 去年同期基础值（私有，YOY 分子用） |
| 5 | _VIC Retention No. Base Act | Base Metrics | VIC Retention No. 本期基础值（私有） |
| 6 | _VIC Retention No. Base LY | Base Metrics | VIC Retention No. 去年同期基础值（私有，YOY 分子用） |
| 7 | LY VIC No. Value | Cell Values | 指标 2 对外值 |
| 8 | VIC Repurchase No. Value | Cell Values | 指标 3 对外值 |
| 9 | VIC Retention No. Value | Cell Values | 指标 4 对外值 |
| 10 | VIC Repurchase% Value | Cell Values | 指标 5 对外值 |
| 11 | VIC Repurchase% YOY Value | Cell Values | 指标 6 对外值 |
| 12 | VIC Retention% Value | Cell Values | 指标 7 对外值 |
| 13 | VIC Retention% YOY Value | Cell Values | 指标 8 对外值 |
| 14 | LY VIC No. Display | Formatting | 指标 2 格式化显示 |
| 15 | VIC Repurchase No. Display | Formatting | 指标 3 格式化显示 |
| 16 | VIC Retention No. Display | Formatting | 指标 4 格式化显示 |
| 17 | VIC Repurchase% Display | Formatting | 指标 5 格式化显示 |
| 18 | VIC Repurchase% YOY Display | Formatting | 指标 6 格式化显示 |
| 19 | VIC Retention% Display | Formatting | 指标 7 格式化显示 |
| 20 | VIC Retention% YOY Display | Formatting | 指标 8 格式化显示 |

---

## 6. 血缘关系图

```
┌─────────────────────────────────────────────────────────────────────┐
│                        数据源层                                      │
│  a03_e2e_customer_data_m（月度事实表）                               │
│  字段: data_date, platform, shop_info_id, user_id, is_member,       │
│        is_employee, is_fy_vic, is_fy_retention_vic,                 │
│        last_12m_net_pay_amt, last_fy_last_order_month_type          │
└──────────────────────────────┬──────────────────────────────────────┘
                               │
                               │ 模型自动传递（行维度 = 事实表字段直接拉取）
                               │ last_fy_last_order_month_type / platform / shop_info_id
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────────┐
│                        度量值层                                      │
│                                                                     │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │  内部基础层（Base Metrics，私有）                           │    │
│  │  ┌──────────────────────┐  ┌──────────────────────┐         │    │
│  │  │ _LY VIC No. Base Act │  │ _LY VIC No. Base LY  │         │    │
│  │  │ is_fy_vic=1，本期    │  │ is_fy_vic=1，LY      │         │    │
│  │  └──────────┬───────────┘  └──────────┬───────────┘         │    │
│  │  ┌──────────────────────┐  ┌──────────────────────┐         │    │
│  │  │ _VIC Repurchase No.  │  │ _VIC Repurchase No.  │         │    │
│  │  │ Base Act             │  │ Base LY              │         │    │
│  │  │ is_fy_vic=1 &        │  │ is_fy_vic=1 &        │         │    │
│  │  │ last_12m_net_pay>0,  │  │ last_12m_net_pay>0,  │         │    │
│  │  │ 本期                 │  │ LY                   │         │    │
│  │  └──────────┬───────────┘  └──────────┬───────────┘         │    │
│  │  ┌──────────────────────┐  ┌──────────────────────┐         │    │
│  │  │ _VIC Retention No.   │  │ _VIC Retention No.   │         │    │
│  │  │ Base Act             │  │ Base LY              │         │    │
│  │  │ is_fy_retention_vic=1│  │ is_fy_retention_vic=1│         │    │
│  │  │ 本期                 │  │ LY                   │         │    │
│  │  └──────────┬───────────┘  └──────────┬───────────┘         │    │
│  └─────────────┼──────────────────────────┼─────────────────────┘    │
│                │                          │                          │
│                ▼                          ▼                          │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │  对外 Value 层（Cell Values，7 个独立度量值）               │    │
│  │  LY VIC No. Value          ← _LY VIC No. Base Act           │    │
│  │  VIC Repurchase No. Value  ← _VIC Repurchase No. Base Act   │    │
│  │  VIC Retention No. Value   ← _VIC Retention No. Base Act    │    │
│  │  VIC Repurchase% Value     ← DIVIDE(Repurchase Act, LY Act) │    │
│  │  VIC Repurchase% YOY Value ← 今年% / 去年% - 1              │    │
│  │  VIC Retention% Value      ← DIVIDE(Retention Act, LY Act)  │    │
│  │  VIC Retention% YOY Value  ← 今年% / 去年% - 1              │    │
│  └─────────────┬───────────────────────────────────────────────┘    │
│                │                                                    │
│                ▼                                                    │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │  对外 Display 层（Formatting，7 个独立度量值）              │    │
│  │  LY VIC No. Display          → #,##0                         │    │
│  │  VIC Repurchase No. Display  → #,##0                         │    │
│  │  VIC Retention No. Display   → #,##0                         │    │
│  │  VIC Repurchase% Display     → #,##0%                        │    │
│  │  VIC Repurchase% YOY Display → #,##0.0%                      │    │
│  │  VIC Retention% Display      → #,##0%                        │    │
│  │  VIC Retention% YOY Display  → #,##0.0%                      │    │
│  └─────────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────────┐
│                        可视化层                                      │
│  Table 视觉对象（非 Matrix）                                        │
│  行: 事实表字段（last_fy_last_order_month_type / platform / shop_info_id）│
│  值: 7 对独立 Value/Display 度量值（无 x 轴，无 SWITCH 路由）       │
│  说明: 指标 1（LY Last Purchase Time）= 行维度字段本身，不需要度量值│
└─────────────────────────────────────────────────────────────────────┘
```

---

## 7. 注意事项

1. **end period 时间筛选（关键逻辑）**：所有指标均使用 `Slicer_Time_Frame_Max[Last_Fiscal_Month_Min]` ~ `[Last_Fiscal_Month_Max]` 作为本期时间范围；YOY 派生的"去年"使用 `Last_Fiscal_Month_Min_LY` ~ `Last_Fiscal_Month_Max_LY`。这些字段已由 Slicer_Time_Frame_Max 日期维度表预算，无需在 DAX 中重复实现。

2. **is_member / is_employee 双重筛选（关键逻辑）**：所有指标均应用 `is_member = SELECTEDVALUE(IsMemberFilter[IsMember], 0)` 和 `is_employee = SELECTEDVALUE(Slicer_Is_Employee_Selection[IsEmployee_Code], 1)` 筛选。默认值：is_member=0（TTL VIC），is_employee=1（Yes）。

3. **行维度字段自动传递（关键逻辑）**：`last_fy_last_order_month_type` / `platform` / `shop_info_id` 三个分组维度直接拉取事实表字段，模型自动传递筛选，DAX 度量值无需显式处理分组逻辑。这是口径文档明确要求的方式。

4. **指标 1 不需要度量值**：LY Last Purchase Time 是行维度本身（`last_fy_last_order_month_type` 字段直接拉取），不需要 Value/Display 度量值。本方案只对指标 2~8 输出度量值。

5. **YOY 派生的"去年"定义（关键逻辑）**：VIC Repurchase% YOY 和 VIC Retention% YOY 的"去年"采用 LY end period 时间偏移（读取 `Slicer_Time_Frame_Max[Last_Fiscal_Month_Min_LY/Max_LY]`），对事实表 `data_date` 做 LY 区间筛选。派生公式展开：
   - VIC Repurchase% YOY = (今年 Repurchase No. / 今年 LY VIC No.) / (去年 Repurchase No. / 去年 LY VIC No.) - 1
   - VIC Retention% YOY = (今年 Retention No. / 今年 LY VIC No.) / (去年 Retention No. / 去年 LY VIC No.) - 1

6. **YOY 数据格式不含正号（关键差异）**：口径文档指标 6 / 8 数据格式为 `#,##0.0%`（percent_1dp，不含正号），与参考文件 VIC_KPIs_Table.md 中 vs LY 使用 `delta_pct_1dp`（含正号）不同。本方案严格遵循口径文档，YOY Display 不含正号。

7. **分母为零或 BLANK 处理**：
   - VIC Repurchase% / VIC Retention%：分母 `_LY VIC No. Base Act` 为 0 或 BLANK 时，DIVIDE 默认返回 BLANK，Display 显示 "-"
   - VIC Repurchase% YOY / VIC Retention% YOY：去年% 为 0 或 BLANK 时，显式返回 BLANK（避免除零错误），Display 显示 "-"

8. **私有基础层度量值命名约定**：内部基础层度量值以 `_` 下划线前缀命名（如 `_LY VIC No. Base Act`），放 Base Metrics 文件夹，供对外 Value 层调用，避免重复代码。对外暴露的是 7 对 Value/Display 度量值，符合"独立输出每个指标的 Value 和 Display 度量"的要求。

9. **无 SWITCH 路由**：与参考文件 VIC_KPIs_Table.md 的矩阵 SWITCH 路由范式不同，本方案为表格视觉，每个指标独立度量值，无 Metric_ID 路由，无 REMOVEFILTERS 机制，无列维度表依赖。度量值结构更简单直接。

10. **无 x 轴时间处理**：表格视觉无列维度，不需要处理 x 轴上的当前时间。所有指标共享同一行上下文（last_fy_last_order_month_type / platform / shop_info_id 分组），end period 时间筛选由 Slicer_Time_Frame_Max 统一提供。

11. **与参考文件 VIC_KPIs_Table.md 的关系**：本方案为 Customer Dashboard VIC Tab 的 LY Last Purchase Time 表格版本，与 VIC KPIs 矩阵版本共享相同的架构基础（断开维度 + 事实表字段行维度 + is_member/is_employee 双重筛选 + end period 时间筛选），差异在于：

    - 视觉对象由 Matrix 改为 Table
    - 列维度由 Dim_ColMetric_VIC_KPIs 改为无列维度
    - 路由方式由 SWITCH 动态路由改为每指标独立度量值
    - 时间逻辑由"end period 当月 + Rolling 12 分母"改为"end period 当月 + LY end period"（YOY 用）
    - 字段筛选由 is_vic / is_retention_vic / is_upgrade_vic / is_direct_vic 改为 is_fy_vic / is_fy_retention_vic / last_12m_net_pay_amt
    - 行维度由 platform / shop_info_id 扩展为 last_fy_last_order_month_type / platform / shop_info_id
    - 派生指标类型由 vs LY / vs LP / Share / Share vs LY / Share vs LP / TAR ACH% 简化为 VIC Repurchase% / VIC Repurchase% YOY / VIC Retention% / VIC Retention% YOY
    - 颜色规则暂不实现（参考文件有 Cell Font Color / Cell Background Color，本方案未要求）
