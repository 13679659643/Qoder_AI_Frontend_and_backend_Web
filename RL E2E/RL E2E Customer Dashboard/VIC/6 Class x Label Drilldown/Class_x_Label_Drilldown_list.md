# Power BI 解决方案 — Class x Label Drilldown（条形图 + 表格，独立度量值）

> status: ready
> created: 2026-08-17
> type: 度量值开发 + 条形图/表格可视化
> 口径来源: 口径文档/Class x Label Drilldown.md（子模块 Class x Label Drilldown，4 个 VIC No. 指标）
> 参考实现 1（end period 时间筛选 + is_member/is_employee 双重筛选 + DIM_Row_VIC_Tier 模型自动传递）: VIC/4 VIC Segment/VIC_Segment_Table.md
> 参考实现 2（dt ∈ [__TimeMin, __TimeMax] 全局时间范围筛选）: Member/Customer_Member_Indicator.md

---

## 1. 需求理解

为 Customer Dashboard - VIC Tab 实现 Class x Label Drilldown 子模块（条形图 + 表格）：

- **视觉对象**：条形图（Bar Chart）+ 表格（Table），非 Matrix
- **无 x 轴时间维度**：条形图使用分组字段（如 category_summary）作为轴，不涉及 x 轴上的当前时间处理；度量值仅受全局时间筛选器影响
- **分组维度**：按 `platform, shop_info_id, tier, category_summary, framework, brand, product_id` 分组，由表字段自动传递筛选，DAX 无需显式处理分组
  - `platform, shop_info_id, tier` 直接拉取 `a03_e2e_customer_data_m` 表字段
  - `category_summary, framework, product_id, brand` 拉取 `t05_customer_order_data_d` 表字段
- **指标范围**：4 个 VIC No. 指标，每个指标独立输出 Value + Display 两个度量值，共 8 个度量值
  - VIC No.（Net_Retention VIC）— is_retention_vic = 1
  - VIC No.（Net_T4-5 Upgrade）— is_upgrade_vic = 1
  - VIC No.（Net_Direct VIC）— is_direct_vic = 1
  - VIC No.（Net_New VIC）— is_new_vic = 1
- **口径**：一切以口径文档为准

### 1.1 关键特殊逻辑一：两步法计算（Step 1 + Step 2）

口径文档明确：

> **计算模式（两步法）**:
> - Step 1：在 `a03_e2e_customer_data_m` 中，dt = 所选时间范围 end period，筛选对应 VIC 标识（is_retention_vic / is_upgrade_vic / is_direct_vic / is_new_vic = 1），框定 user_id 范围；
> - Step 2：在 `t05_customer_order_data_d` 中，dt = 所选时间范围，限定 user_id ∈ Step 1 框定范围，直接统计 count(distinct user_id)

**两步法时间口径差异（关键）**：
- Step 1 时间范围：**dt = 所选时间范围 end period**（参考 VIC_Segment_Table.md 的 end period 逻辑）
  - 本期：`data_date ∈ [Last_Fiscal_Month_Min, Last_Fiscal_Month_Max]`（读取 `Slicer_Time_Frame_Max`）
- Step 2 时间范围：**dt = 所选时间范围**（dt ∈ [__TimeMin, __TimeMax] 全局时间范围）
  - 读取 `Slicer_Time_Frame_Min[TimeFrame_Min]` 和 `Slicer_Time_Frame_Max[TimeFrame_Max]`（参考 Customer_Member_Indicator.md 的用法）

**两步法实现方式**：
- Step 1：在 `a03_e2e_customer_data_m` 中按 end period 时间范围 + VIC 标识字段筛选，用 `VALUES(user_id)` 框定 user_id 集合
- Step 2：在 `t05_customer_order_data_d` 中按全局时间范围筛选，并用 `TREATAS` 将 Step 1 的 user_id 集合传递到 `t05` 表，做 `DISTINCTCOUNT(user_id)`
- 采用 TREATAS 传递的原因：`a03_e2e_customer_data_m` 和 `t05_customer_order_data_d` 之间的分组字段跨表拉取依赖模型关系，user_id 集合需显式传递才能保证 Step 2 的筛选与 Step 1 框定范围一致

### 1.2 关键特殊逻辑二：end period 时间筛选（Step 1 专用）

口径文档要求：

> **聚合粒度**: 数字卡片：所选时间范围 `dt`（多数为 end period）
> **end period 说明**: 所选时间范围的最后一个财月，只关注 Slicer_Time_Frame_Max 值

Step 1 应用 end period 时间筛选到 `a03_e2e_customer_data_m[data_date]`：

- `data_date ∈ [Last_Fiscal_Month_Min, Last_Fiscal_Month_Max]`

`Slicer_Time_Frame_Max` 已内置 `Last_Fiscal_Month_*` 系列字段，直接 SELECTEDVALUE 读取即可，无需 EDATE 计算。

### 1.3 关键特殊逻辑三：全局时间范围筛选（Step 2 专用）

口径文档要求：

> **dt = 所选时间范围**: 涉及到 t05_customer_order_data_d 表计算，dt = 所选时间范围，所选时间范围的计算，dt ∈ [__TimeMin, __TimeMax]（全局时间范围），Slicer_Time_Frame_Min 和 Slicer_Time_Frame_Max 维度表已经给出了具体的 TimeFrame_Min 和 TimeFrame_Max 值

Step 2 应用全局时间范围筛选到 `t05_customer_order_data_d[dt]`：

- `dt ∈ [TimeFrame_Min, TimeFrame_Max]`（读取 `Slicer_Time_Frame_Min[TimeFrame_Min]` 和 `Slicer_Time_Frame_Max[TimeFrame_Max]`）

> 参考实现：Member/Customer_Member_Indicator.md 中的 `__TimeMin` / `__TimeMax` 用法

### 1.4 关键特殊逻辑四：is_member / is_employee 双重人群筛选

口径文档要求：

> **is_member 使用**: `VAR __IsMemberFilter = SELECTEDVALUE(IsMemberFilter[IsMember], 0)`，默认 TTL VIC
> **is_employee 使用**: `VAR __IsEmployeeFilter = SELECTEDVALUE(Slicer_Is_Employee_Selection[IsEmployee_Code], 1)`，默认 Yes

Step 1 应用这两个筛选到事实表 `a03_e2e_customer_data_m[is_member]` / `[is_employee]`（Step 2 的 `t05` 表不涉及此筛选，仅 Step 1 框定 user_id 范围时应用）。

### 1.5 关键特殊逻辑五：分组维度跨表传递（通过共享切片器维度表）

口径文档明确：

> **分组维度**: 按 `platform, shop_info_id, tier, category_summary, framework, brand, product_id` 分组，由表字段自动传递，DAX 无需显式处理分组
> platform, shop_info_id, tier 直接拉取 `a03_e2e_customer_data_m` 表，category_summary, framework, product_id, brand 拉取 `t05_customer_order_data_d` 表中的字段

**两表模型关系现状（关键）**：
- `a03_e2e_customer_data_m` 和 `t05_customer_order_data_d` 之间**无直接模型关系**
- 两表 user_id 为多对多关系，不符合模型常规关联关系，不能直接建立关系
- 因此跨表分组字段（如 a03 的 tier 与 t05 的 category_summary）**无法通过模型关系自动互相传递筛选**

**跨表传递的桥梁：共享切片器维度表**
两表通过以下共享切片器维度表建立间接关联，实现 platform / shop 字段的跨表筛选传递：

| 切片器维度表 | 与 a03 表关系 | 与 t05 表关系 | 传递字段 |
|---|---|---|---|
| `Slicer_Platform_Selection` | `Slicer_Platform_Selection[Platform_ID]` 1:N `a03_e2e_customer_data_m[platform]` | `Slicer_Platform_Selection[Platform_ID]` 1:N `t05_customer_order_data_d[platform]` | platform |
| `Slicer_Store_Name` | `Slicer_Store_Name[Store_ID]` 1:N `a03_e2e_customer_data_m[shop_name_en]` | `Slicer_Store_Name[Store_ID]` 1:N `t05_customer_order_data_d[shop_name]` | shop |

> 注意：a03 表的 shop 字段名为 `shop_name_en`，t05 表的 shop 字段名为 `shop_name`（字段名不同，但通过 `Slicer_Store_Name[Store_ID]` 桥接）。

**实现方式**：
- **platform / shop（store）分组字段**：由 `Slicer_Platform_Selection` / `Slicer_Store_Name` 切片器表统一传递，两表共享同一筛选上下文，模型自动传递筛选
- **tier / category_summary / framework / product_id/ brand 分组字段**：各自依附于所在事实表（tier 在 a03 表，category_summary/framework/product_id 在 t05 表），仅影响所在表的聚合，不跨表传递
- DAX 度量值中 Step 1 框定的 user_id 集合通过 `TREATAS` 显式传递到 Step 2（跨表 user_id 传递），保证 Step 2 的 user_id 筛选严格限定在 Step 1 范围内

**分组字段跨表传递能力矩阵**：

| 分组字段 | 所在表 | 跨表传递方式 | 是否可跨表传递 |
|---|---|---|---|
| platform | a03 + t05（字段名相同） | Slicer_Platform_Selection 桥接 | 是 |
| shop_info_id / shop | a03（shop_name_en）+ t05（shop_name） | Slicer_Store_Name 桥接 | 是 |
| tier | a03 | 无桥接 | 否（仅影响 a03 聚合） |
| category_summary | t05 | 无桥接 | 否（仅影响 t05 聚合） |
| framework | t05 | 无桥接 | 否（仅影响 t05 聚合） |
| product_id | t05 | 无桥接 | 否（仅影响 t05 聚合） |

### 1.6 关键特殊逻辑六：条形图交叉筛选联动

口径文档要求（用户确认）：

> 条形图拉取 `t05_customer_order_data_d` 表中的 category_summary，点击某个条形柱子可以联动其他分组的表格，相当于做了一个 category_summary 的筛选

**实现方式**：
- 条形图轴：`t05_customer_order_data_d[category_summary]`
- 度量值：拉取本方案的 4 对 Value/Display 度量值
- 点击条形柱子 → Power BI 自动将该 category_summary 值作为筛选器传递到同页其他视觉对象（表格/条形图）
- 其他分组维度（platform / shop_info_id / tier / framework / product_id）的表格自动刷新
- 此为 Power BI 标准交叉筛选行为，无需额外 DAX 处理

### 1.7 与参考文件的关键差异

| 维度       | 参考文件 1（VIC_Segment_Table.md）         | 参考文件 2（Customer_Member_Indicator.md） | 本方案（Class_x_Label_Drilldown_list.md）                       |
| ---------- | ------------------------------------------ | ------------------------------------------ | ---------------------------------------------------------------- |
| 视觉对象   | Table（表格）                              | Card（卡片图）                             | Bar Chart（条形图） + Table（表格）                              |
| 行/轴维度   | DIM_Row_VIC_Tier[Tier ID]                 | 无（卡片图无维度）                         | 分组字段跨表拉取（a03 + t05）                                     |
| 指标数量   | 12 对 Value/Display                        | 14 对 Value/Display                        | 4 对 Value/Display                                              |
| 时间筛选   | end period（Last_Fiscal_Month_*）          | 全局时间范围（TimeFrame_Min / TimeFrame_Max）| Step 1 用 end period + Step 2 用全局时间范围                     |
| 计算模式   | 单步法（Step1+Step2 合并）                 | 单步法                                     | 两步法（Step1 框定 user_id + Step2 TREATAS 传递）               |
| 数据底表   | a03_e2e_customer_data_m（单表）            | a03_e2e_customer_data_m（单表）            | a03_e2e_customer_data_m + t05_customer_order_data_d（双表）      |
| VIC 标识字段 | 无（按 customer_tier 分组）              | 无                                         | is_retention_vic / is_upgrade_vic / is_direct_vic / is_new_vic  |
| 货币转换   | 涉及（SLS/ACV/AUR）                        | 涉及（SLS）                                | 不涉及（数量类指标）                                             |

---

## 2. 现状分析

### 2.1 数据底表

| 对象     | 名称                                                                                              | 出处                   |
| -------- | ------------------------------------------------------------------------------------------------- | ---------------------- |
| 事实表 1 | a03_e2e_customer_data_m                                                                           | 口径文档全局逻辑       |
| 关键字段 1 | data_date, platform, shop_name_en, user_id, is_member, is_employee, customer_tier, is_retention_vic, is_upgrade_vic, is_direct_vic, is_new_vic | 口径文档子模块各指标 |
| 事实表 2 | t05_customer_order_data_d                                                                         | 口径文档子模块各指标   |
| 关键字段 2 | dt, platform, shop_name, user_id, category_summary, framework, product_id, brand                         | 口径文档子模块各指标   |

> `a03_e2e_customer_data_m` 为月度聚合表，`data_date` 为月末日期，用于 Step 1 的 end period 时间筛选。
> `t05_customer_order_data_d` 为订单明细表，`dt` 为订单日期，用于 Step 2 的全局时间范围筛选。
> 两表无直接模型关系，user_id 为多对多关系，通过 `Slicer_Platform_Selection` / `Slicer_Store_Name` 共享切片器维度表间接关联（详见 1.5 节）。

### 2.2 维度表清单（沿用项目现有切片器）

| 维度表                       | 类型     | 连接方式                                                                                                                          |
| ---------------------------- | -------- | --------------------------------------------------------------------------------------------------------------------------------- |
| Slicer_Time_Frame_Min        | 断开维度 | SELECTEDVALUE 读取 `TimeFrame_Min`（Step 2 全局时间范围下限）                                                                    |
| Slicer_Time_Frame_Max        | 断开维度 | SELECTEDVALUE 读取 `TimeFrame_Max`（Step 2 全局时间范围上限）、`Last_Fiscal_Month_Min/Max`（Step 1 end period 区间）              |
| Slicer_Is_Employee_Selection | 断开维度 | SELECTEDVALUE 读取 `IsEmployee_Code`                                                                                              |
| IsMemberFilter               | 断开维度 | SELECTEDVALUE 读取 `IsMember`                                                                                                     |
| Slicer_Platform_Selection    | 1:N 维度 | `Slicer_Platform_Selection[Platform_ID]` 1:N `a03_e2e_customer_data_m[platform]`、1:N `t05_customer_order_data_d[platform]`（桥接两表 platform 筛选） |
| Slicer_Store_Name            | 1:N 维度 | `Slicer_Store_Name[Store_ID]` 1:N `a03_e2e_customer_data_m[shop_name_en]`、1:N `t05_customer_order_data_d[shop_name]`（桥接两表 shop 筛选） |

> 不使用 X 轴时间段维度（条形图场景，轴为分组字段）。
> `Slicer_Platform_Selection` 和 `Slicer_Store_Name` 为两表的共享桥接维度表，实现 platform / shop 字段跨表筛选传递。

---

## 3. 方案设计

### 3.1 整体架构

```
核心思路：条形图/表格视觉 + 每指标独立 Value/Display 度量值（无 SWITCH 路由）

a03_e2e_customer_data_m（Step 1 事实表）   t05_customer_order_data_d（Step 2 事实表）
    │                                              │
    │  Step 1:                                      │  Step 2:
    │  - data_date ∈ end period                     │  - dt ∈ [TimeFrame_Min, TimeFrame_Max]
    │  - VIC 标识 = 1（如 is_retention_vic = 1）    │  - user_id ∈ Step 1 框定范围（TREATAS 传递）
    │  - is_member / is_employee 筛选               │  - DISTINCTCOUNT(user_id)
    │  - VALUES(user_id) 框定范围                   │
    │                                              │
    └─────────────────────┬────────────────────────┘
                          │
                          ▼
┌─────────────────────────── 条形图 / 表格视觉对象 ──────────────────────────┐
│  轴/行 = 分组字段（跨表拉取）                                              │
│    - a03 表：platform / shop_info_id / tier                              │
│    - t05 表：category_summary / framework / product_id                   │
│  值 = 4 对独立 Value/Display 度量值                                      │
│       - VIC No. (Net_Retention VIC) Value / Display                     │
│       - VIC No. (Net_T4-5 Upgrade) Value / Display                      │
│       - VIC No. (Net_Direct VIC) Value / Display                        │
│       - VIC No. (Net_New VIC) Value / Display                           │
└──────────────────────────────────────────────────────────────────────────┘
                                   ▲
                                   │
              度量值链（每指标独立，无 SWITCH 路由）
              ┌────────────────────────────────────────────────────┐
              │  对外 Value 层（4 个独立度量值）                   │
              │  ├ VIC No. (Net_Retention VIC) Value              │
              │  ├ VIC No. (Net_T4-5 Upgrade) Value               │
              │  ├ VIC No. (Net_Direct VIC) Value                 │
              │  └ VIC No. (Net_New VIC) Value                    │
              │                                                    │
              │  对外 Display 层（4 个独立度量值）                 │
              │  ├ VIC No. (Net_Retention VIC) Display            │
              │  ├ VIC No. (Net_T4-5 Upgrade) Display             │
              │  ├ VIC No. (Net_Direct VIC) Display               │
              │  └ VIC No. (Net_New VIC) Display                 │
              └────────────────────────────────────────────────────┘
```

### 3.2 度量值模型设计

```
[对外 Value 层 — 4 个独立度量值]          ← 放 Cell Values 文件夹
VIC No. (Net_Retention VIC) Value         ← Step1(end period + is_retention_vic=1) + Step2(TREATAS + 全局时间范围)
VIC No. (Net_T4-5 Upgrade) Value          ← Step1(end period + is_upgrade_vic=1) + Step2(TREATAS + 全局时间范围)
VIC No. (Net_Direct VIC) Value            ← Step1(end period + is_direct_vic=1) + Step2(TREATAS + 全局时间范围)
VIC No. (Net_New VIC) Value               ← Step1(end period + is_new_vic=1) + Step2(TREATAS + 全局时间范围)

[对外 Display 层 — 4 个独立度量值]        ← 放 Formatting 文件夹
VIC No. (Net_Retention VIC) Display       ← integer 格式 #,##0
VIC No. (Net_T4-5 Upgrade) Display        ← integer 格式 #,##0
VIC No. (Net_Direct VIC) Display          ← integer 格式 #,##0
VIC No. (Net_New VIC) Display             ← integer 格式 #,##0
```

### 3.3 筛选器上下文

| 筛选器                                    | 作用方式                                                                    | DAX 处理                                                                 |
| ----------------------------------------- | --------------------------------------------------------------------------- | ------------------------------------------------------------------------ |
| Slicer_Time_Frame_Max（Step 1 end period）| 断开维度，SELECTEDVALUE 读取 `Last_Fiscal_Month_Min/Max`                  | `a03[data_date] >= __PeriodMin AND a03[data_date] <= __PeriodMax`     |
| Slicer_Time_Frame_Min（Step 2 全局下限）  | 断开维度，SELECTEDVALUE 读取 `TimeFrame_Min`                              | `t05[dt] >= __TimeMin`                                          |
| Slicer_Time_Frame_Max（Step 2 全局上限）  | 断开维度，SELECTEDVALUE 读取 `TimeFrame_Max`                              | `t05[dt] <= __TimeMax`                                          |
| Slicer_Is_Employee_Selection              | 断开维度，SELECTEDVALUE 读取 `IsEmployee_Code`                            | `a03[is_employee] = __IsEmployeeFilter`                                  |
| IsMemberFilter                            | 断开维度，SELECTEDVALUE 读取 `IsMember`                                   | `a03[is_member] = __IsMemberFilter`                                     |
| Slicer_Platform_Selection                 | 1:N 维度，桥接两表 platform 字段                                          | 模型自动传递 platform 筛选到 a03 和 t05                                |
| Slicer_Store_Name                         | 1:N 维度，桥接两表 shop 字段（a03[shop_name_en] / t05[shop_name]）        | 模型自动传递 shop 筛选到 a03 和 t05                                     |
| 分组字段（tier / category_summary / framework / product_id/ brand） | 视觉对象轴/行维度直接拉取，仅影响所在事实表聚合                | DAX 无需显式处理（无法跨表传递）                                         |

### 3.4 指标计算公式与数据格式

| 序号 | 指标名称                          | VIC 标识字段       | 计算公式（两步法）                                                                                                | 数据类型 | 数据格式  |
| ---- | --------------------------------- | ------------------ | ----------------------------------------------------------------------------------------------------------------- | -------- | --------- |
| 1    | VIC No.（Net_Retention VIC）     | is_retention_vic=1 | Step1: VALUES(a03[user_id]) where is_retention_vic=1, dt=end period; Step2: DISTINCTCOUNT(t05[user_id]) where dt=全局时间范围, user_id ∈ Step1 | integer  | `#,##0`   |
| 2    | VIC No.（Net_T4-5 Upgrade）       | is_upgrade_vic=1   | Step1: VALUES(a03[user_id]) where is_upgrade_vic=1, dt=end period; Step2: DISTINCTCOUNT(t05[user_id]) where dt=全局时间范围, user_id ∈ Step1   | integer  | `#,##0`   |
| 3    | VIC No.（Net_Direct VIC）         | is_direct_vic=1    | Step1: VALUES(a03[user_id]) where is_direct_vic=1, dt=end period; Step2: DISTINCTCOUNT(t05[user_id]) where dt=全局时间范围, user_id ∈ Step1    | integer  | `#,##0`   |
| 4    | VIC No.（Net_New VIC）            | is_new_vic=1       | Step1: VALUES(a03[user_id]) where is_new_vic=1, dt=end period; Step2: DISTINCTCOUNT(t05[user_id]) where dt=全局时间范围, user_id ∈ Step1       | integer  | `#,##0`   |

---

## 4. 度量值实现

### 4.1 对外 Value 层 — 4 个独立度量值

#### 4.1.1 VIC No. (Net_Retention VIC) Value（留存VIC数量）

```dax
VIC No. (Net_Retention VIC) Value = 
// ========================================
// 度量值: VIC No. (Net_Retention VIC) Value
// Display Folder: Cell Values
// 用途: 留存VIC数量（对外值）
// 依赖: a03_e2e_customer_data_m, t05_customer_order_data_d,
//       Slicer_Time_Frame_Max[Last_Fiscal_Month_Min/Max],
//       Slicer_Time_Frame_Min[TimeFrame_Min], Slicer_Time_Frame_Max[TimeFrame_Max],
//       Slicer_Is_Employee_Selection[IsEmployee_Code],
//       IsMemberFilter[IsMember]
// 口径来源: 口径文档/Class x Label Drilldown.md 指标 1
// 计算公式（两步法）:
//   Step 1: 在 a03_e2e_customer_data_m 中，dt = 所选时间范围 end period，
//           筛选 is_retention_vic = 1，框定 user_id 范围
//   Step 2: 在 t05_customer_order_data_d 中，dt = 所选时间范围（全局时间范围，使用 t05 表的 dt 字段），
//           限定 user_id ∈ Step 1 范围，统计 count(distinct user_id)
// 筛选上下文:
//   Step 1:
//     - a03[data_date] ∈ [Last_Fiscal_Month_Min, Last_Fiscal_Month_Max]（end period 当月）
//     - a03[is_retention_vic] = 1
//     - a03[is_member] = __IsMemberFilter（默认 0 = TTL VIC）
//     - a03[is_employee] = __IsEmployeeFilter（默认 1 = Yes）
//   Step 2:
//     - t05[dt] ∈ [TimeFrame_Min, TimeFrame_Max]（全局时间范围）
//     - t05[user_id] ∈ Step 1 框定的 user_id 集合（TREATAS 传递）
// 聚合粒度: Step1 VALUES(user_id) + Step2 DISTINCTCOUNT(user_id)
// 分组维度: platform, shop_info_id, tier, category_summary, framework, brand, product_id
//          - platform / shop 通过 Slicer_Platform_Selection / Slicer_Store_Name 桥接跨表传递
//          - tier / category_summary / framework / product_id/ brand 仅影响所在事实表聚合，不跨表传递
// ========================================
    // ── Step 1: 在 a03 中按 end period 框定 user_id 范围 ──
    VAR __PeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Max[Last_Fiscal_Month_Min])
    VAR __PeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max[Last_Fiscal_Month_Max])
    VAR __IsMemberFilter = SELECTEDVALUE(IsMemberFilter[IsMember], 0)
    VAR __IsEmployeeFilter = SELECTEDVALUE(Slicer_Is_Employee_Selection[IsEmployee_Code], 1)

    VAR __VICUserIds =
        CALCULATETABLE(
            VALUES('a03_e2e_customer_data_m'[user_id]),
            'a03_e2e_customer_data_m'[is_retention_vic] = 1,
            'a03_e2e_customer_data_m'[is_member] = __IsMemberFilter,
            'a03_e2e_customer_data_m'[is_employee] = __IsEmployeeFilter,
            'a03_e2e_customer_data_m'[data_date] >= __PeriodMin,
            'a03_e2e_customer_data_m'[data_date] <= __PeriodMax
        )

    // ── Step 2: 在 t05 中按全局时间范围 + user_id 集合做 DISTINCTCOUNT ──
    VAR __TimeMin = SELECTEDVALUE(Slicer_Time_Frame_Min[TimeFrame_Min])
    VAR __TimeMax = SELECTEDVALUE(Slicer_Time_Frame_Max[TimeFrame_Max])

    VAR __Result =
        CALCULATE(
            DISTINCTCOUNT('t05_customer_order_data_d'[user_id]),
            't05_customer_order_data_d'[dt] >= __TimeMin,
            't05_customer_order_data_d'[dt] <= __TimeMax,
            TREATAS(__VICUserIds, 't05_customer_order_data_d'[user_id])
        )

    RETURN
        __Result
```

#### 4.1.2 VIC No. (Net_T4-5 Upgrade) Value（T4-5升级VIC数量）

```dax
VIC No. (Net_T4-5 Upgrade) Value = 
// ========================================
// 度量值: VIC No. (Net_T4-5 Upgrade) Value
// Display Folder: Cell Values
// 用途: T4-5升级VIC数量（对外值）
// 依赖: a03_e2e_customer_data_m, t05_customer_order_data_d,
//       Slicer_Time_Frame_Max[Last_Fiscal_Month_Min/Max],
//       Slicer_Time_Frame_Min[TimeFrame_Min], Slicer_Time_Frame_Max[TimeFrame_Max],
//       Slicer_Is_Employee_Selection[IsEmployee_Code],
//       IsMemberFilter[IsMember]
// 口径来源: 口径文档/Class x Label Drilldown.md 指标 2
// 计算公式（两步法）:
//   Step 1: 在 a03_e2e_customer_data_m 中，dt = 所选时间范围 end period，
//           筛选 is_upgrade_vic = 1，框定 user_id 范围
//   Step 2: 在 t05_customer_order_data_d 中，dt = 所选时间范围（全局时间范围，使用 t05 表的 dt 字段），
//           限定 user_id ∈ Step 1 范围，统计 count(distinct user_id)
// 筛选上下文:
//   Step 1:
//     - a03[data_date] ∈ [Last_Fiscal_Month_Min, Last_Fiscal_Month_Max]（end period 当月）
//     - a03[is_upgrade_vic] = 1
//     - a03[is_member] = __IsMemberFilter（默认 0 = TTL VIC）
//     - a03[is_employee] = __IsEmployeeFilter（默认 1 = Yes）
//   Step 2:
//     - t05[dt] ∈ [TimeFrame_Min, TimeFrame_Max]（全局时间范围）
//     - t05[user_id] ∈ Step 1 框定的 user_id 集合（TREATAS 传递）
// 聚合粒度: Step1 VALUES(user_id) + Step2 DISTINCTCOUNT(user_id)
// 分组维度: platform, shop_info_id, tier, category_summary, framework, brand, product_id
//          由视觉对象轴/行维度直接拉取对应表字段，模型自动传递筛选，DAX 无需显式处理
// ========================================
    // ── Step 1: 在 a03 中按 end period 框定 user_id 范围 ──
    VAR __PeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Max[Last_Fiscal_Month_Min])
    VAR __PeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max[Last_Fiscal_Month_Max])
    VAR __IsMemberFilter = SELECTEDVALUE(IsMemberFilter[IsMember], 0)
    VAR __IsEmployeeFilter = SELECTEDVALUE(Slicer_Is_Employee_Selection[IsEmployee_Code], 1)

    VAR __VICUserIds =
        CALCULATETABLE(
            VALUES('a03_e2e_customer_data_m'[user_id]),
            'a03_e2e_customer_data_m'[is_upgrade_vic] = 1,
            'a03_e2e_customer_data_m'[is_member] = __IsMemberFilter,
            'a03_e2e_customer_data_m'[is_employee] = __IsEmployeeFilter,
            'a03_e2e_customer_data_m'[data_date] >= __PeriodMin,
            'a03_e2e_customer_data_m'[data_date] <= __PeriodMax
        )

    // ── Step 2: 在 t05 中按全局时间范围 + user_id 集合做 DISTINCTCOUNT ──
    VAR __TimeMin = SELECTEDVALUE(Slicer_Time_Frame_Min[TimeFrame_Min])
    VAR __TimeMax = SELECTEDVALUE(Slicer_Time_Frame_Max[TimeFrame_Max])

    VAR __Result =
        CALCULATE(
            DISTINCTCOUNT('t05_customer_order_data_d'[user_id]),
            't05_customer_order_data_d'[dt] >= __TimeMin,
            't05_customer_order_data_d'[dt] <= __TimeMax,
            TREATAS(__VICUserIds, 't05_customer_order_data_d'[user_id])
        )

    RETURN
        __Result
```

#### 4.1.3 VIC No. (Net_Direct VIC) Value（直接买成VIC数量）

```dax
VIC No. (Net_Direct VIC) Value = 
// ========================================
// 度量值: VIC No. (Net_Direct VIC) Value
// Display Folder: Cell Values
// 用途: 直接买成VIC数量（对外值）
// 依赖: a03_e2e_customer_data_m, t05_customer_order_data_d,
//       Slicer_Time_Frame_Max[Last_Fiscal_Month_Min/Max],
//       Slicer_Time_Frame_Min[TimeFrame_Min], Slicer_Time_Frame_Max[TimeFrame_Max],
//       Slicer_Is_Employee_Selection[IsEmployee_Code],
//       IsMemberFilter[IsMember]
// 口径来源: 口径文档/Class x Label Drilldown.md 指标 3
// 计算公式（两步法）:
//   Step 1: 在 a03_e2e_customer_data_m 中，dt = 所选时间范围 end period，
//           筛选 is_direct_vic = 1，框定 user_id 范围
//   Step 2: 在 t05_customer_order_data_d 中，dt = 所选时间范围（全局时间范围，使用 t05 表的 dt 字段），
//           限定 user_id ∈ Step 1 范围，统计 count(distinct user_id)
// 筛选上下文:
//   Step 1:
//     - a03[data_date] ∈ [Last_Fiscal_Month_Min, Last_Fiscal_Month_Max]（end period 当月）
//     - a03[is_direct_vic] = 1
//     - a03[is_member] = __IsMemberFilter（默认 0 = TTL VIC）
//     - a03[is_employee] = __IsEmployeeFilter（默认 1 = Yes）
//   Step 2:
//     - t05[dt] ∈ [TimeFrame_Min, TimeFrame_Max]（全局时间范围）
//     - t05[user_id] ∈ Step 1 框定的 user_id 集合（TREATAS 传递）
// 聚合粒度: Step1 VALUES(user_id) + Step2 DISTINCTCOUNT(user_id)
// 分组维度: platform, shop_info_id, tier, category_summary, framework, brand, product_id
//          由视觉对象轴/行维度直接拉取对应表字段，模型自动传递筛选，DAX 无需显式处理
// ========================================
    // ── Step 1: 在 a03 中按 end period 框定 user_id 范围 ──
    VAR __PeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Max[Last_Fiscal_Month_Min])
    VAR __PeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max[Last_Fiscal_Month_Max])
    VAR __IsMemberFilter = SELECTEDVALUE(IsMemberFilter[IsMember], 0)
    VAR __IsEmployeeFilter = SELECTEDVALUE(Slicer_Is_Employee_Selection[IsEmployee_Code], 1)

    VAR __VICUserIds =
        CALCULATETABLE(
            VALUES('a03_e2e_customer_data_m'[user_id]),
            'a03_e2e_customer_data_m'[is_direct_vic] = 1,
            'a03_e2e_customer_data_m'[is_member] = __IsMemberFilter,
            'a03_e2e_customer_data_m'[is_employee] = __IsEmployeeFilter,
            'a03_e2e_customer_data_m'[data_date] >= __PeriodMin,
            'a03_e2e_customer_data_m'[data_date] <= __PeriodMax
        )

    // ── Step 2: 在 t05 中按全局时间范围 + user_id 集合做 DISTINCTCOUNT ──
    VAR __TimeMin = SELECTEDVALUE(Slicer_Time_Frame_Min[TimeFrame_Min])
    VAR __TimeMax = SELECTEDVALUE(Slicer_Time_Frame_Max[TimeFrame_Max])

    VAR __Result =
        CALCULATE(
            DISTINCTCOUNT('t05_customer_order_data_d'[user_id]),
            't05_customer_order_data_d'[dt] >= __TimeMin,
            't05_customer_order_data_d'[dt] <= __TimeMax,
            TREATAS(__VICUserIds, 't05_customer_order_data_d'[user_id])
        )

    RETURN
        __Result
```

#### 4.1.4 VIC No. (Net_New VIC) Value（新VIC数量）

```dax
VIC No. (Net_New VIC) Value = 
// ========================================
// 度量值: VIC No. (Net_New VIC) Value
// Display Folder: Cell Values
// 用途: 新VIC数量（对外值）
// 依赖: a03_e2e_customer_data_m, t05_customer_order_data_d,
//       Slicer_Time_Frame_Max[Last_Fiscal_Month_Min/Max],
//       Slicer_Time_Frame_Min[TimeFrame_Min], Slicer_Time_Frame_Max[TimeFrame_Max],
//       Slicer_Is_Employee_Selection[IsEmployee_Code],
//       IsMemberFilter[IsMember]
// 口径来源: 口径文档/Class x Label Drilldown.md 指标 4
// 计算公式（两步法）:
//   Step 1: 在 a03_e2e_customer_data_m 中，dt = 所选时间范围 end period，
//           筛选 is_new_vic = 1，框定 user_id 范围
//   Step 2: 在 t05_customer_order_data_d 中，dt = 所选时间范围（全局时间范围，使用 t05 表的 dt 字段），
//           限定 user_id ∈ Step 1 范围，统计 count(distinct user_id)
// 筛选上下文:
//   Step 1:
//     - a03[data_date] ∈ [Last_Fiscal_Month_Min, Last_Fiscal_Month_Max]（end period 当月）
//     - a03[is_new_vic] = 1
//     - a03[is_member] = __IsMemberFilter（默认 0 = TTL VIC）
//     - a03[is_employee] = __IsEmployeeFilter（默认 1 = Yes）
//   Step 2:
//     - t05[dt] ∈ [TimeFrame_Min, TimeFrame_Max]（全局时间范围）
//     - t05[user_id] ∈ Step 1 框定的 user_id 集合（TREATAS 传递）
// 聚合粒度: Step1 VALUES(user_id) + Step2 DISTINCTCOUNT(user_id)
// 分组维度: platform, shop_info_id, tier, category_summary, framework, brand, product_id
//          由视觉对象轴/行维度直接拉取对应表字段，模型自动传递筛选，DAX 无需显式处理
// ========================================
    // ── Step 1: 在 a03 中按 end period 框定 user_id 范围 ──
    VAR __PeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Max[Last_Fiscal_Month_Min])
    VAR __PeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max[Last_Fiscal_Month_Max])
    VAR __IsMemberFilter = SELECTEDVALUE(IsMemberFilter[IsMember], 0)
    VAR __IsEmployeeFilter = SELECTEDVALUE(Slicer_Is_Employee_Selection[IsEmployee_Code], 1)

    VAR __VICUserIds =
        CALCULATETABLE(
            VALUES('a03_e2e_customer_data_m'[user_id]),
            'a03_e2e_customer_data_m'[is_new_vic] = 1,
            'a03_e2e_customer_data_m'[is_member] = __IsMemberFilter,
            'a03_e2e_customer_data_m'[is_employee] = __IsEmployeeFilter,
            'a03_e2e_customer_data_m'[data_date] >= __PeriodMin,
            'a03_e2e_customer_data_m'[data_date] <= __PeriodMax
        )

    // ── Step 2: 在 t05 中按全局时间范围 + user_id 集合做 DISTINCTCOUNT ──
    VAR __TimeMin = SELECTEDVALUE(Slicer_Time_Frame_Min[TimeFrame_Min])
    VAR __TimeMax = SELECTEDVALUE(Slicer_Time_Frame_Max[TimeFrame_Max])

    VAR __Result =
        CALCULATE(
            DISTINCTCOUNT('t05_customer_order_data_d'[user_id]),
            't05_customer_order_data_d'[dt] >= __TimeMin,
            't05_customer_order_data_d'[dt] <= __TimeMax,
            TREATAS(__VICUserIds, 't05_customer_order_data_d'[user_id])
        )

    RETURN
        __Result
```

### 4.2 对外 Display 层 — 4 个独立度量值

> 严格遵循口径文档数据格式定义：
>
> - integer → `#,##0`（千分位整数）
> - BLANK 显示为 "-"。

#### 4.2.1 VIC No. (Net_Retention VIC) Display

```dax
VIC No. (Net_Retention VIC) Display = 
// ========================================
// 度量值: VIC No. (Net_Retention VIC) Display
// Display Folder: Formatting
// 用途: 留存VIC数量（格式化显示）
// 依赖: [VIC No. (Net_Retention VIC) Value]
// 数据格式: integer → #,##0
// ========================================
    VAR __Value = [VIC No. (Net_Retention VIC) Value]
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            FORMAT(__Value, "#,##0")
        )
```

#### 4.2.2 VIC No. (Net_T4-5 Upgrade) Display

```dax
VIC No. (Net_T4-5 Upgrade) Display = 
// ========================================
// 度量值: VIC No. (Net_T4-5 Upgrade) Display
// Display Folder: Formatting
// 用途: T4-5升级VIC数量（格式化显示）
// 依赖: [VIC No. (Net_T4-5 Upgrade) Value]
// 数据格式: integer → #,##0
// ========================================
    VAR __Value = [VIC No. (Net_T4-5 Upgrade) Value]
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            FORMAT(__Value, "#,##0")
        )
```

#### 4.2.3 VIC No. (Net_Direct VIC) Display

```dax
VIC No. (Net_Direct VIC) Display = 
// ========================================
// 度量值: VIC No. (Net_Direct VIC) Display
// Display Folder: Formatting
// 用途: 直接买成VIC数量（格式化显示）
// 依赖: [VIC No. (Net_Direct VIC) Value]
// 数据格式: integer → #,##0
// ========================================
    VAR __Value = [VIC No. (Net_Direct VIC) Value]
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            FORMAT(__Value, "#,##0")
        )
```

#### 4.2.4 VIC No. (Net_New VIC) Display

```dax
VIC No. (Net_New VIC) Display = 
// ========================================
// 度量值: VIC No. (Net_New VIC) Display
// Display Folder: Formatting
// 用途: 新VIC数量（格式化显示）
// 依赖: [VIC No. (Net_New VIC) Value]
// 数据格式: integer → #,##0
// ========================================
    VAR __Value = [VIC No. (Net_New VIC) Value]
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            FORMAT(__Value, "#,##0")
        )
```

---

## 5. 度量值清单与 Display Folder

| 序号 | 度量值名称                              | Display Folder | 用途                                          |
| ---- | --------------------------------------- | --------------- | --------------------------------------------- |
| 1    | VIC No. (Net_Retention VIC) Value      | Cell Values     | 留存VIC数量（对外值，两步法）                 |
| 2    | VIC No. (Net_T4-5 Upgrade) Value       | Cell Values     | T4-5升级VIC数量（对外值，两步法）             |
| 3    | VIC No. (Net_Direct VIC) Value         | Cell Values     | 直接买成VIC数量（对外值，两步法）             |
| 4    | VIC No. (Net_New VIC) Value            | Cell Values     | 新VIC数量（对外值，两步法）                   |
| 5    | VIC No. (Net_Retention VIC) Display    | Formatting      | 留存VIC数量格式化显示（#,##0）                |
| 6    | VIC No. (Net_T4-5 Upgrade) Display     | Formatting      | T4-5升级VIC数量格式化显示（#,##0）            |
| 7    | VIC No. (Net_Direct VIC) Display       | Formatting      | 直接买成VIC数量格式化显示（#,##0）            |
| 8    | VIC No. (Net_New VIC) Display           | Formatting      | 新VIC数量格式化显示（#,##0）                   |

---

## 6. 血缘关系图

```
┌─────────────────────────────────────────────────────────────────────┐
│                        数据源层                                      │
│  a03_e2e_customer_data_m（月度事实表，Step 1）                       │
│  字段: data_date, platform, shop_info_id, user_id, is_member,       │
│        is_employee, customer_tier, is_retention_vic,                 │
│        is_upgrade_vic, is_direct_vic, is_new_vic                     │
│                                                                     │
│  t05_customer_order_data_d（订单明细表，Step 2）                     │
│  字段: dt, platform, shop_name, user_id,                             │
│        category_summary, framework, product_id, brand                      │
│                                                                     │
│  两表无直接模型关系（user_id 多对多），通过共享切片器维度表桥接：    │
│    - Slicer_Platform_Selection[Platform_ID] 1:N a03[platform] / t05[platform] │
│    - Slicer_Store_Name[Store_ID] 1:N a03[shop_name_en] / t05[shop_name] │
│  Step1 user_id 集合通过 TREATAS 显式传递到 Step2                     │
└──────────────────────────────┬──────────────────────────────────────┘
                               │
                               │ Step 1 (a03 表) + Step 2 (t05 表)
                               │ Step1 框定 user_id 范围 → TREATAS 传递到 Step2
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────────┐
│                        度量值层                                      │
│                                                                     │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │  对外 Value 层（Cell Values，4 个独立度量值）               │    │
│  │  VIC No. (Net_Retention VIC) Value                         │    │
│  │    └ Step1: VALUES(user_id) where is_retention_vic=1       │    │
│  │       Step2: DISTINCTCOUNT(t05[user_id]) + TREATAS         │    │
│  │  VIC No. (Net_T4-5 Upgrade) Value                          │    │
│  │    └ Step1: VALUES(user_id) where is_upgrade_vic=1         │    │
│  │       Step2: DISTINCTCOUNT(t05[user_id]) + TREATAS         │    │
│  │  VIC No. (Net_Direct VIC) Value                            │    │
│  │    └ Step1: VALUES(user_id) where is_direct_vic=1          │    │
│  │       Step2: DISTINCTCOUNT(t05[user_id]) + TREATAS         │    │
│  │  VIC No. (Net_New VIC) Value                               │    │
│  │    └ Step1: VALUES(user_id) where is_new_vic=1            │    │
│  │       Step2: DISTINCTCOUNT(t05[user_id]) + TREATAS         │    │
│  └─────────────┬───────────────────────────────────────────────┘    │
│                │                                                    │
│                ▼                                                    │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │  对外 Display 层（Formatting，4 个独立度量值）             │    │
│  │  VIC No. (Net_Retention VIC) Display → #,##0               │    │
│  │  VIC No. (Net_T4-5 Upgrade) Display  → #,##0               │    │
│  │  VIC No. (Net_Direct VIC) Display    → #,##0              │    │
│  │  VIC No. (Net_New VIC) Display       → #,##0               │    │
│  └─────────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────────┐
│                        可视化层                                      │
│  条形图（Bar Chart）                                                 │
│    轴 = t05_customer_order_data_d[category_summary]                 │
│    值 = 4 对独立 Value/Display 度量值                                │
│    交互: 点击条形柱子 → 交叉筛选其他视觉对象（表格/条形图）         │
│                                                                     │
│  表格（Table，非 Matrix）                                            │
│    行 = 分组字段跨表拉取                                             │
│         - a03 表: platform / shop_info_id / tier                    │
│         - t05 表: category_summary / framework / product_id         │
│    值 = 4 对独立 Value/Display 度量值（无 x 轴，无 SWITCH 路由）   │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 7. 视觉对象配置

### 7.1 条形图（Bar Chart）

| 配置项 | 值 |
|--------|-----|
| 轴（X 或 Y） | `t05_customer_order_data_d[category_summary]` |
| 值 | 4 对 Value/Display 度量值（按需拉取 Display 或 Value） |
| 全局筛选器 | Slicer_Time_Frame_Min、Slicer_Time_Frame_Max、Slicer_Is_Employee_Selection、IsMemberFilter |
| 分组维度筛选 | platform / shop_info_id / tier / framework / product_id 由模型自动传递，无需显式拉取 |
| 交互 | 启用交叉筛选（默认行为），点击条形柱子联动其他表格/条形图 |

### 7.2 表格（Table）

| 配置项 | 值 |
|--------|-----|
| 行 | 分组字段跨表拉取（按需组合）：<br>- a03 表: platform / shop_info_id / tier<br>- t05 表: category_summary / framework / product_id |
| 值 | 4 对 Value/Display 度量值（无 x 轴，无 SWITCH 路由） |
| 全局筛选器 | Slicer_Time_Frame_Min、Slicer_Time_Frame_Max、Slicer_Is_Employee_Selection、IsMemberFilter |
| 交互 | 接收条形图的交叉筛选（category_summary 点击联动） |

### 7.3 度量值拉取示例

| 场景 | 拉取度量 |
|------|---------|
| 留存VIC数量（数值） | [VIC No. (Net_Retention VIC) Value] |
| 留存VIC数量（格式化显示） | [VIC No. (Net_Retention VIC) Display] |
| T4-5升级VIC数量（数值） | [VIC No. (Net_T4-5 Upgrade) Value] |
| T4-5升级VIC数量（格式化显示） | [VIC No. (Net_T4-5 Upgrade) Display] |
| 直接买成VIC数量（数值） | [VIC No. (Net_Direct VIC) Value] |
| 直接买成VIC数量（格式化显示） | [VIC No. (Net_Direct VIC) Display] |
| 新VIC数量（数值） | [VIC No. (Net_New VIC) Value] |
| 新VIC数量（格式化显示） | [VIC No. (Net_New VIC) Display] |

---

## 8. 验证方法

### 8.1 验证 SQL（以指标 1 — 留存VIC数量为例）

```sql
-- Step 1: 在 a03 中按 end period + is_retention_vic=1 框定 user_id 范围
-- 假设 end period 区间: Last_Fiscal_Month_Min='2026-09-01', Last_Fiscal_Month_Max='2026-09-30'
-- 假设 is_member=0 (TTL VIC), is_employee=1 (Yes)
WITH vic_users AS (
    SELECT DISTINCT user_id
    FROM a03_e2e_customer_data_m
    WHERE is_retention_vic = 1
      AND is_member = 0
      AND is_employee = 1
      AND data_date BETWEEN '2026-09-01' AND '2026-09-30'
)
-- Step 2: 在 t05 中按全局时间范围 + user_id ∈ Step1 范围，统计 count(distinct user_id)
-- 假设全局时间范围: TimeFrame_Min='2026-01-01', TimeFrame_Max='2026-09-30'
SELECT COUNT(DISTINCT t.user_id) AS VIC_No_Retention
FROM t05_customer_order_data_d t
WHERE t.dt BETWEEN '2026-01-01' AND '2026-09-30'
  AND t.user_id IN (SELECT user_id FROM vic_users);

-- 指标 2/3/4 同理，仅将 is_retention_vic=1 替换为 is_upgrade_vic=1 / is_direct_vic=1 / is_new_vic=1
```

### 8.2 分组维度验证

```sql
-- 按 category_summary 分组验证（条形图轴）
WITH vic_users AS (
    SELECT DISTINCT user_id
    FROM a03_e2e_customer_data_m
    WHERE is_retention_vic = 1
      AND is_member = 0
      AND is_employee = 1
      AND data_date BETWEEN '2026-09-01' AND '2026-09-30'
)
SELECT
    t.category_summary,
    COUNT(DISTINCT t.user_id) AS VIC_No_Retention
FROM t05_customer_order_data_d t
WHERE t.dt BETWEEN '2026-01-01' AND '2026-09-30'
  AND t.user_id IN (SELECT user_id FROM vic_users)
GROUP BY t.category_summary
ORDER BY VIC_No_Retention DESC;
```

### 8.3 交叉筛选联动验证

在 Power BI 报表中：
1. 配置条形图（轴 = t05[category_summary]，值 = VIC No. (Net_Retention VIC) Value）
2. 配置表格（行 = a03[platform] / a03[tier] 等，值 = 同度量值）
3. 点击条形图某个 category_summary 柱子
4. 验证表格自动按该 category_summary 值筛选刷新

---

## 9. 注意事项

1. **两步法时间口径差异（关键逻辑）**：
   - Step 1 时间范围：dt = 所选时间范围 end period（读取 `Slicer_Time_Frame_Max[Last_Fiscal_Month_Min/Max]`）
   - Step 2 时间范围：dt = 所选时间范围（全局时间范围，读取 `Slicer_Time_Frame_Min[TimeFrame_Min]` 和 `Slicer_Time_Frame_Max[TimeFrame_Max]`）
   - 两步时间范围不同，Step 1 框定 VIC user_id 范围（基于 end period），Step 2 统计这些 user_id 在全局时间范围的购买行为

2. **TREATAS 跨表传递 user_id（关键逻辑）**：
   - Step 1 在 a03 表框定的 user_id 集合，通过 `TREATAS(__VICUserIds, 't05_customer_order_data_d'[user_id])` 显式传递到 Step 2 的 t05 表
   - 采用 TREATAS 而非依赖模型关系的原因：保证 Step 2 的 user_id 筛选严格限定在 Step 1 框定范围内，不受其他筛选上下文干扰
   - 若 a03 和 t05 之间已有 user_id 模型关系，TREATAS 仍可叠加使用，确保语义明确

3. **end period 时间筛选（关键逻辑）**：Step 1 使用 `Slicer_Time_Frame_Max[Last_Fiscal_Month_Min]` ~ `[Last_Fiscal_Month_Max]` 作为本期 end period 时间范围。这些字段已由 Slicer_Time_Frame_Max 日期维度表预算，无需在 DAX 中重复实现。参考实现：VIC_Segment_Table.md。

4. **全局时间范围筛选（关键逻辑）**：Step 2 使用 `Slicer_Time_Frame_Min[TimeFrame_Min]` 和 `Slicer_Time_Frame_Max[TimeFrame_Max]` 作为全局时间范围。参考实现：Customer_Member_Indicator.md。

5. **is_member / is_employee 双重筛选（关键逻辑）**：Step 1 应用 `is_member = SELECTEDVALUE(IsMemberFilter[IsMember], 0)` 和 `is_employee = SELECTEDVALUE(Slicer_Is_Employee_Selection[IsEmployee_Code], 1)` 筛选。默认值：is_member=0（TTL VIC），is_employee=1（Yes）。Step 2 的 t05 表不涉及此筛选（仅 Step 1 框定 user_id 范围时应用）。

6. **分组维度跨表传递（关键逻辑，两表无直接模型关系）**：
   - `a03_e2e_customer_data_m` 和 `t05_customer_order_data_d` 之间**无直接模型关系**（user_id 为多对多，不符合常规关联关系）
   - 两表通过共享切片器维度表桥接，实现 platform / shop 字段的跨表筛选传递：
     - `Slicer_Platform_Selection[Platform_ID]` 1:N `a03_e2e_customer_data_m[platform]`、1:N `t05_customer_order_data_d[platform]`
     - `Slicer_Store_Name[Store_ID]` 1:N `a03_e2e_customer_data_m[shop_name_en]`、1:N `t05_customer_order_data_d[shop_name]`
   - `platform / shop` 分组字段：通过上述共享切片器维度表跨表传递，模型自动传递筛选
   - `tier / category_summary / framework / product_id/ brand` 分组字段：仅影响所在事实表聚合，不跨表传递
     - `tier` 在 a03 表，仅影响 Step 1 聚合
     - `category_summary / framework / product_id` 在 t05 表，仅影响 Step 2 聚合
   - Step 1 框定的 user_id 集合通过 TREATAS 显式传递到 Step 2（跨表 user_id 传递），保证口径一致

7. **分组字段跨表拉取前提（关键逻辑）**：
   - `a03_e2e_customer_data_m` 和 `t05_customer_order_data_d` 之间**无直接模型关系**
   - `platform` 筛选通过 `Slicer_Platform_Selection` 桥接传递（两表 platform 字段名相同）
   - `shop` 筛选通过 `Slicer_Store_Name` 桥接传递（注意：a03 表字段名为 `shop_name_en`，t05 表字段名为 `shop_name`，字段名不同但通过 `Slicer_Store_Name[Store_ID]` 桥接）
   - 其他分组字段（tier / category_summary / framework / product_id/ brand）无法跨表传递，仅影响所在事实表聚合

8. **条形图交叉筛选联动（关键逻辑）**：
   - 条形图轴使用 `t05_customer_order_data_d[category_summary]`
   - 点击条形柱子 → Power BI 自动将该 category_summary 值作为筛选器传递到同页其他视觉对象
   - 其他分组维度（platform / shop / tier / framework / product_id）的表格自动刷新
   - 此为 Power BI 标准交叉筛选行为，无需额外 DAX 处理
   - 注意：点击 category_summary 只直接影响 Step 2 中 t05 表的筛选上下文；Step 1 中的 a03 表不受 category_summary 筛选影响（符合口径设计意图：Step 1 框定 user_id 范围，Step 2 在该范围内按 category_summary 细分）

9. **VIC 标识字段差异（关键逻辑）**：4 个指标仅 Step 1 的 VIC 标识字段筛选不同：
   - VIC No.（Net_Retention VIC）：`is_retention_vic = 1`
   - VIC No.（Net_T4-5 Upgrade）：`is_upgrade_vic = 1`
   - VIC No.（Net_Direct VIC）：`is_direct_vic = 1`
   - VIC No.（Net_New VIC）：`is_new_vic = 1`
   - Step 2 逻辑完全一致

10. **无 SWITCH 路由**：与 VIC_KPIs_Table.md 的矩阵 SWITCH 路由范式不同，本方案为条形图/表格视觉，每个指标独立度量值，无 Metric_ID 路由，无列维度表依赖。度量值结构更简单直接。

11. **无 x 轴时间处理**：条形图轴为分组字段（如 category_summary），不涉及 x 轴上的当前时间处理。所有指标共享同一分组上下文，时间筛选由 Slicer_Time_Frame_* 统一提供。

12. **不涉及货币转换**：4 个指标均为数量类（DISTINCTCOUNT user_id），不涉及金额，无需汇率换算和货币符号拼接。

13. **BLANK 显示处理**：DISTINCTCOUNT 在无数据时返回 BLANK，Display 度量统一显示为 "-"。

14. **私有基础层未抽离**：由于 4 个指标的 Step 1 仅 VIC 标识字段不同，Step 2 逻辑完全一致，可考虑抽离私有基础层（如 `_VIC UserIds Base` 接受 VIC 标识参数）。但本方案为保持每个指标度量的独立性和可读性，选择在每个 Value 度量中完整实现两步法。如需优化代码复用，可后续重构为带参数的私有基础层 + 对外 Value 层调用模式。

15. **两表无直接模型关系（关键逻辑）**：
   - `a03_e2e_customer_data_m` 和 `t05_customer_order_data_d` 之间**无直接模型关系**，user_id 为多对多关系
   - 两表通过 `Slicer_Platform_Selection` / `Slicer_Store_Name` 共享切片器维度表桥接
   - Step 1 框定的 user_id 集合通过 TREATAS 显式传递到 Step 2，不依赖模型关系
   - 不需要在模型中建立两表直接关系（避免多对多带来的筛选传递歧义）

16. **日期字段说明**：`t05_customer_order_data_d` 表的订单日期字段为 `dt`（非 order_date），用于 Step 2 的全局时间范围筛选。`a03_e2e_customer_data_m` 表的日期字段为 `data_date`，用于 Step 1 的 end period 时间筛选。
