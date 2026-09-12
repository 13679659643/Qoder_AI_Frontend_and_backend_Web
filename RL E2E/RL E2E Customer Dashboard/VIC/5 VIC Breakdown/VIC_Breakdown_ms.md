# Power BI 解决方案 — VIC Breakdown 矩阵（SWITCH 路由）

> status: ready
> created: 2026-08-15
> revised: 2026-09-12（Step1+Step2 分步口径调整：Step 1 = end period 当月框定 VIC 买家 user_id，Step 2 = 所选时间范围聚合，两步时间范围不同不能合并；全客分母（Store Base Value，vs Store / SLS% 分母）同样分步，与 VIC 侧唯一区别是 Step 1 筛选条件（is_xxx_vic IN {0,1} vs =1）；两套区间均从 Slicer_Time_Frame_Max_VIC_Breakdown 读取，日期表不改动）
> type: 度量值开发 + 矩阵可视化构建
> 口径来源: 口径文档/VIC Breakdown KPI.md（子模块五 DCom VIC Breakdown，2 个大分组 × 6 个 KPI 分组，共 44 列指标）
> 参考实现: VIC/VIC KPI/VIC_KPIs_Table.md（断开列维度 + SWITCH 动态路由 + REMOVEFILTERS 范式）
> 列指标维度表: Dim_ColMetric_New_Retention_VIC（44 行，2 个大分组 × 6 个 KPI 分组）

---

## 1. 需求理解

为 Customer Dashboard - VIC Tab 实现 DCom VIC Breakdown 矩阵：

- **行**：无行维度表，直接拉取事实表字段（`platform` / `shop_info_id`），天然实现行维度分组和筛选，DAX 无需显式处理
- **列**：`Dim_ColMetric_New_Retention_VIC` 的三级层级 `VICType`（父）> `KPIGroup`（中）> `ColName`（子）
  - 2 个大分组（VICType）：New VIC（is_new_vic=1）/ Retention VIC（is_retention_vic=1）
  - 6 个 KPI 分组：SLS / SLS% / ACV / UPT / AUR / Freq.
  - 共 44 列指标（每大分组 22 列，完全对称）
- **值**：SWITCH 动态路由，按 `Metric_ID` 分发到 Act / vs LY / vs LP / vs Store
- **口径**：一切以口径文档 VIC Breakdown KPI.md 为准
- **筛选器**：
  - Slicer_Time_Frame_VIC_Breakdown（VIC Breakdown 专用日期表，与其他模块隔离）
  - Slicer_Time_Frame_Max_VIC_Breakdown（断开维度，读取两套区间字段：`Last_Fiscal_Month_*` 系列 → Step 1 end period 当月；`TimeFrame_*` 系列 → Step 2 所选时间范围；均含 `_LY/_LP` 偏移版本）
  - Slicer_Time_Frame_Min_VIC_Breakdown（断开维度，本方案不使用——两套区间均从 Max 表读取，防止日期表互相依赖）
  - Slicer_Is_Employee_Selection（断开维度，筛选 `is_employee`）
  - IsMemberFilter（断开维度，筛选 `is_member`）
  - Slicer_Platform_Selection / Slicer_Store_Name（断开维度，行维度直接拉事实表字段实现自动传递）
  - Slicer_Currency_Selection（断开维度，金额类指标 SLS/ACV/AUR 做汇率换算）

### 1.1 关键特殊逻辑一：VIC Breakdown 专用日期表（与其他模块隔离）

为避免与其他 VIC 模块的日期切片器互相干扰，VIC Breakdown 使用专用日期表：

| 原日期表（其他模块）                       | VIC Breakdown 专用日期表                                      |
| ------------------------------------------ | ------------------------------------------------------------- |
| Slicer_Time_Frame                          | Slicer_Time_Frame_VIC_Breakdown                               |
| Slicer_Time_Frame_Max                      | Slicer_Time_Frame_Max_VIC_Breakdown                           |
| Slicer_Time_Frame_Min                      | Slicer_Time_Frame_Min_VIC_Breakdown                           |

字段结构完全一致，均内置 `Last_Fiscal_Month` 及 7 个时间字段（`Last_Fiscal_Month_Min/Max/Min_LY/Max_LY/Min_LP/Max_LP`）。

### 1.2 关键特殊逻辑二：end period 时间范围 + Step1/Step2 两步法（分步计算，不能合并）

口径文档要求：

> **聚合粒度**: `dt = 所选时间范围 end period`，`platform, shop_info_id` 分组维度由表字段自动传递
> **end period 说明**: 所选时间范围的最后一个财月，只关注 Slicer_Time_Frame_Max_VIC_Breakdown 值

SLS / SLS% / ACV / UPT / AUR / Freq. 的计算公式均为 Step1 + Step2 两步法，**两步时间范围不同，不能合并区间计算**（分步范式参考用户已验证的"新客"DAX，即 Customer Breakdown Trend 的 TREATAS 模式）：

- **Step 1**（end period 当月框定 VIC 买家）：在 `dt = end period`（即 `[Last_Fiscal_Month_Min, Last_Fiscal_Month_Max]` 当月区间）筛选 `is_new_vic=1`（或 `is_retention_vic=1`），框定 user_id 集合
- **Step 2**（所选时间范围聚合）：该 user_id 集合在切片器所选完整时间范围（即 `[TimeFrame_Min, TimeFrame_Max]` 区间）对应的 `sum(net_pay_amt)` / `sum(net_pay_qty)` / `sum(net_pay_order_cnt)`；`is_xxx_vic=1` 仅用于 Step 1 框定，Step 2 不再施加；`platform, shop_info_id` 分组维度由模型自动传递保留（Step 2 不移除分组维度）

> **例外（单步口径）**：ACV / Freq. 分母 `count(distinct user_id)` 口径明确为 "dt = 所选时间范围 end period，筛选 is_xxx_vic=1"，保持 end period 当月单步聚合（即 Step 1 框定的 user_id 数量，COUNTROWS(Step 1 集合)）。
>
> **SLS% 分母（全客，同样分步）**：Step 1 end period 当月框定全客 `is_xxx_vic in (0,1)` user_id 集合 + Step 2 所选时间范围（TimeFrame 区间）`sum(net_pay_amt)`，与分子唯一区别是 Step 1 的筛选条件（见 §3.6）。
>
> **LY / LP 版本**：Step 1 用 LY/LP end period 当月（`Last_Fiscal_Month_*_LY/LP`），Step 2 用 LY/LP 所选时间范围（`TimeFrame_Min/Max_LY/LP`）。

`Slicer_Time_Frame_Max_VIC_Breakdown` 已内置两套区间全部字段（`Last_Fiscal_Month` 系列 + `TimeFrame` 系列，含 LY/LP 偏移），直接获取用于筛选事实表的时间范围，**无需改动日期表**（两套区间同表读取，防止日期表互相依赖）。

> **历史口径说明**：本方案曾将两步合并为 end period 当月单步聚合（当时的理解：Step2 "所选时间范围" = end period 当月）。2026-09-12 经澄清 Step 2 = 切片器所选完整时间范围，已全面改为分步实现，旧逻辑块以注释形式保留在各 Base Value 度量值末尾（可回退）。

### 1.3 关键特殊逻辑三：New VIC / Retention VIC 双大分组（仅筛选字段不同）

口径文档明确要求：

> **分组维度**: 按 VIC 类型（New VIC / Retention VIC）区分，都是基于 dt = 所选时间范围 end period 的情况下，New VIC 和 Retention VIC 的区别仅在于 `is_new_vic = 1` 和 `is_retention_vic = 1` 的筛选条件。

- **New VIC** 大分组（Metric_ID 1-22）：Step1 筛选 `is_new_vic = 1`
- **Retention VIC** 大分组（Metric_ID 23-44）：Step1 筛选 `is_retention_vic = 1`
- 两个大分组指标完全对称，唯一区别是筛选字段

实现方式：在度量值中按 `VICType` 字段判断应用哪个筛选条件，避免为两个大分组重复编写度量值。

### 1.4 关键特殊逻辑四：is_member / is_employee 双重人群筛选

口径文档要求：

> **is_member 使用**: `VAR __IsMemberFilter = SELECTEDVALUE(IsMemberFilter[IsMember], 0)`，默认 TTL VIC
> **is_employee 使用**: `VAR __IsEmployeeFilter = VALUES(Slicer_Is_Employee_Selection[IsEmployee_Code])`，默认 Yes

所有指标（除特殊说明外）都需要应用这两个筛选到事实表 `a03_e2e_customer_data_m[is_member]` / `[is_employee]`。

### 1.5 关键特殊逻辑五：货币转换

口径文档要求：

> 金额类（SLS / ACV / AUR）÷ Currency_ExchangeRate（RMB=1, USD=7）
> 比率类不除（分子分母同币种抵消）
> SLS% 占比不除

- 汇率字段：`Slicer_Currency_Selection[Currency_ExchangeRate]`，默认 1（RMB）
- 货币符号字段：`Slicer_Currency_Selection[Currency_Symbol]`，默认 "¥"
- 金额类指标 Value 度量值中 `DIVIDE(SUM(net_pay_amt), __FXRate)` 做汇率换算
- Display 度量值中 `__CurrencySymbol & FORMAT(__Value, "#,##0")` 拼接货币符号
- 比率类（SLS%、ACV vs Store、UPT、AUR vs Store、Freq.）不做汇率换算（分子分母同币种抵消）

### 1.6 关键特殊逻辑六：vs Store 全客对比（分母同样 Step1+Step2 分步）

口径文档要求：

> vs Store 全客分母用 `is_xxx_vic in (0, 1)` + `is_member/is_employee` 切片器筛选（统一）

- **分子**：New VIC 或 Retention VIC 的 Act 值（`is_new_vic=1` 或 `is_retention_vic=1`，Step1+Step2 分步）
- **分母**：全客值（`is_new_vic in (0, 1)` 或 `is_retention_vic in (0, 1)`，同样 Step1+Step2 分步——Step 1 end period 当月框定全客 user 集合，Step 2 所选时间范围聚合；与分子唯一区别是 Step 1 的筛选条件）
- **计算方式**：`分子 / 分母 - 1`
- vs Store 仅 ACV / UPT / AUR / Freq. 四个 KPI 分组有（SLS / SLS% 无 vs Store）

### 1.7 关键特殊逻辑七：vs LY / vs LP 时间偏移规则（财历映射）

直接读取 Slicer_Time_Frame_Max_VIC_Breakdown 内置的 `Last_Fiscal_Month_*` 系列字段：

- 本期：`Last_Fiscal_Month_Min` ~ `Last_Fiscal_Month_Max`
- LY：`Last_Fiscal_Month_Min_LY` ~ `Last_Fiscal_Month_Max_LY`
- LP：`Last_Fiscal_Month_Min_LP` ~ `Last_Fiscal_Month_Max_LP`
- 无需 EDATE -12 或 Key 偏移计算

### 1.8 关键特殊逻辑八：派生指标分类

| 派生类型                                   | 计算方式                          | 数据格式                                       | 适用指标                                       |
| ------------------------------------------ | --------------------------------- | ---------------------------------------------- | ---------------------------------------------- |
| **vs LY**（数量类 SLS / ACV / UPT / AUR / Freq.） | 今年 / 去年 - 1                   | `delta_pct_0dp`（含正号）                    | 所有 KPI 分组的 vs LY（SLS% 除外）             |
| **vs LP**（数量类）                         | 当期 / 上期 - 1                   | `delta_pct_0dp`（含正号）                    | 所有 KPI 分组的 vs LP（SLS% 除外）             |
| **vs Store**（ACV / UPT / AUR / Freq.）     | New VIC / 全客 - 1                | `delta_pct_0dp`（含正号）                    | ACV / UPT / AUR / Freq. 的 vs Store            |
| **SLS% vs LY / vs LP**（比率类）            | 今年 - 去年（差值，×100 转 pts） | `delta_pts`                                   | SLS% 分组的 vs LY / vs LP                      |

---

## 2. 现状分析

### 2.1 数据底表

| 对象     | 名称                                                                                                                                                                                                                                                              | 出处                       |
| -------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------- |
| 事实表   | a03_e2e_customer_data_m                                                                                                                                                                                                                                           | VIC Breakdown KPI.md 全局逻辑 |
| 关键字段 | data_date, platform, shop_info_id, user_id, is_member, is_employee, is_new_vic, is_retention_vic, net_pay_amt, net_pay_qty, net_pay_order_cnt                                                                                                                                 | VIC Breakdown KPI.md 全部指标 |

> 表为月度聚合表（每用户每月一行），`data_date` 已在 Power Query 中通过 `LAST_DAY(DATE_SUB(STR_TO_DATE(CONCAT(data_month,'01'),'%Y%m%d'), INTERVAL 10 MONTH))` 计算得到月末日期。

### 2.2 维度表清单

| 维度表                                   | 类型     | 连接方式                                                                                                                                                                                                                                                                                                                                                             |
| ---------------------------------------- | -------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Slicer_Time_Frame_VIC_Breakdown          | 断开维度 | VIC Breakdown 专用日期表（与其他模块隔离），用于时间范围切片器                                                                                                                                                                                                                                                                                                       |
| Slicer_Time_Frame_Max_VIC_Breakdown      | 断开维度 | SELECTEDVALUE 读取两套区间字段（已预算，基础聚合直接读）：`Last_Fiscal_Month_Min/Max`（Step 1 end period 当月）+ `TimeFrame_Min/Max`（Step 2 所选时间范围），均含 `_LY/_LP` 偏移版本（`Last_Fiscal_Month_Min_LY/Max_LY/Min_LP/Max_LP`、`TimeFrame_Min_LY/Max_LY/Min_LP/Max_LP`）                                                                 |
| Slicer_Time_Frame_Min_VIC_Breakdown      | 断开维度 | 本方案不使用（两套区间均从 Max 表读取，防止日期表互相依赖）                                                                                                                                                                                                                                                                                                          |
| Slicer_Is_Employee_Selection             | 断开维度 | SELECTEDVALUE 读取 `IsEmployee_Code`                                                                                                                                                                                                                                                                                                                               |
| IsMemberFilter                           | 断开维度 | SELECTEDVALUE 读取 `IsMember`                                                                                                                                                                                                                                                                                                                                      |
| Slicer_Platform_Selection                | 断开维度 | 行维度直接拉事实表 platform 字段，模型自动传递                                                                                                                                                                                                                                                                                                                       |
| Slicer_Store_Name                        | 断开维度 | 行维度直接拉事实表 shop_info_id 字段，模型自动传递                                                                                                                                                                                                                                                                                                                   |
| Slicer_Currency_Selection                | 断开维度 | SELECTEDVALUE 读取 `Currency_ExchangeRate`（默认 1）、`Currency_Symbol`（默认 "¥"）                                                                                                                                                                                                                                                                                 |
| Dim_ColMetric_New_Retention_VIC          | 断开维度 | SELECTEDVALUE 读取 `Metric_ID` / `VICType` / `KPIGroup` / `ColName` / `ColType` / `Metric_Format` / `Metric_ColorRule` / 颜色字段                                                                                                                                                                                                                                  |

> **行维度处理**：`platform` / `shop_info_id` 直接拉取事实表字段实现自动传递，模型自动传递筛选，DAX 无需显式处理。

---

## 3. 方案设计

### 3.1 整体架构

```
核心思路：断开列维度 + SWITCH 动态路由（Disconnected Dimension + Dispatch Pattern）

Dim_ColMetric_New_Retention_VIC（断开维度，三级列头）
    │
    │  无关系连接，仅通过 SELECTEDVALUE 读取：
    │  - Metric_ID, VICType, KPIGroup, ColName
    │  - ColType, Metric_Format, Metric_ColorRule
    │  - Metric_ColorPositive/Negative/Zero/Default
    │
    ▼
    ┌─────────────────────────── Matrix 视觉对象 ──────────────────────────┐
    │  行 = 事实表字段（platform / shop_info_id）                          │
    │  列 = 'Dim_ColMetric_New_Retention_VIC'[VICType]                     │
    │      > [KPIGroup] > [ColName]                                        │
    │  值 = [VIC Breakdown Cell Display]                                   │
    └────────────────────────────────────────────────────────────────────────┘
                                   ▲
                                   │
              SWITCH 动态路由度量值链（按 Metric_ID 分发）
              ┌────────────────────────────────────────────────────┐
              │  [VIC Breakdown Cell Value]                        │
              │    └→ [VIC Breakdown Base Value]（总路由）         │
              │         ├→ [VIC Breakdown Act Base Value]（本期值）│
              │         ├→ [VIC Breakdown LY Base Value]（LY 值）  │
              │         ├→ [VIC Breakdown LP Base Value]（LP 值）  │
              │         ├→ [VIC Breakdown Store Base Value]（全客值）│
              │         └→ 派生：vs LY / vs LP / vs Store           │
              │            （按 Metric_ID 路由到对应计算分支）     │
              └────────────────────────────────────────────────────┘
```

### 3.2 度量值模型设计

```
[VIC Breakdown Act Base Value]         ← 本期基础值（Step1+Step2 分步，不能合并）：
                                       ←   Step1 end period 当月 UNION+FILTER 框定 is_xxx_vic=1 user_id 集合
                                       ←   Step2 TREATAS 传递 + TimeFrame 区间聚合（is_xxx_vic=1 不再施加）
                                       ← 按 Metric_ID 路由到对应 KPI 分组的聚合
                                       ← 统一应用 is_member / is_employee 筛选
                                       ← 金额类（SLS/ACV/AUR）÷ Currency_ExchangeRate
                                       ← SLS%/UPT/Freq. 不做汇率换算
                                       ← ACV/Freq. 分母 = COUNTROWS(Step1 集合)（end period 当月单步口径）
[VIC Breakdown LY Base Value]          ← 去年同期基础值（Step1: Last_Fiscal_Month_*_LY；Step2: TimeFrame_Min/Max_LY）
[VIC Breakdown LP Base Value]          ← 上期基础值（Step1: Last_Fiscal_Month_*_LP；Step2: TimeFrame_Min/Max_LP）
[VIC Breakdown Store Base Value]       ← 全客基础值（is_xxx_vic in (0,1)，同样 Step1+Step2 分步）：
                                       ←   Step1 end period 当月（按 Metric_ID 路由 Act/LY/LP）框定全客 user_id 集合
                                       ←   Step2 TREATAS + TimeFrame 区间（按 Metric_ID 路由 Act/LY/LP）聚合
                                       ←   __UserCount_Store = COUNTROWS(Step1 集合)（end period 当月单步口径）
[VIC Breakdown Base Value]             ← 总路由（含 vs LY / vs LP / vs Store 派生）
                                       ← REMOVEFILTERS 清除断开维度筛选，再应用目标 Metric_ID
                                       ← vs LY = Act / LY - 1（数量类）
                                       ← vs LP = Act / LP - 1（数量类）
                                       ← vs Store = Act / Store - 1
                                       ← SLS% vs LY/LP = Act - LY/LP（差值，×100 转 pts）
[VIC Breakdown Cell Value]             ← 对外值 = Base Value
[VIC Breakdown Cell Display]           ← 格式化显示文本（按 Metric_Format 单字段分发）
[VIC Breakdown Cell Font Color]        ← 字体颜色（按 Metric_ColorRule 分发：fixed_black / pos_neg_zero）
[VIC Breakdown Cell Background Color]  ← 背景色（区分 VICType/KPIGroup/ColName 层级行）
```

### 3.3 筛选器上下文

| 筛选器                                         | 作用方式                                                                                  | DAX 处理                                                                                       |
| ---------------------------------------------- | ----------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------- |
| Slicer_Time_Frame_Max_VIC_Breakdown（Step 1）  | 断开维度，SELECTEDVALUE 读取 `Last_Fiscal_Month_Min/Max`（end period 当月）              | `data_date >= __EndPeriodMin AND data_date <= __EndPeriodMax`（Step 1 框定 user_id 集合）    |
| Slicer_Time_Frame_Max_VIC_Breakdown（Step 2）  | SELECTEDVALUE 读取 `TimeFrame_Min/Max`（所选时间范围）                                    | `data_date >= __TimeFrameMin AND data_date <= __TimeFrameMax`（Step 2 TREATAS 聚合）         |
| Slicer_Time_Frame_Max_VIC_Breakdown（Step 1 LY）| SELECTEDVALUE 读取 `Last_Fiscal_Month_Min_LY/Max_LY`                                    | `data_date >= __EndPeriodMin_LY AND data_date <= __EndPeriodMax_LY`（LY Step 1）             |
| Slicer_Time_Frame_Max_VIC_Breakdown（Step 2 LY）| SELECTEDVALUE 读取 `TimeFrame_Min_LY/Max_LY`                                            | `data_date >= __LYMin AND data_date <= __LYMax`（LY Step 2）                                  |
| Slicer_Time_Frame_Max_VIC_Breakdown（Step 1 LP）| SELECTEDVALUE 读取 `Last_Fiscal_Month_Min_LP/Max_LP`                                    | `data_date >= __EndPeriodMin_LP AND data_date <= __EndPeriodMax_LP`（LP Step 1）             |
| Slicer_Time_Frame_Max_VIC_Breakdown（Step 2 LP）| SELECTEDVALUE 读取 `TimeFrame_Min_LP/Max_LP`                                            | `data_date >= __LPMin AND data_date <= __LPMax`（LP Step 2）                                  |
| Slicer_Is_Employee_Selection                   | 断开维度，SELECTEDVALUE 读取 `IsEmployee_Code`                                          | `a03_e2e_customer_data_m[is_employee] in __IsEmployeeFilter`                                 |
| IsMemberFilter                                 | 断开维度，SELECTEDVALUE 读取 `IsMember`                                                 | `a03_e2e_customer_data_m[is_member] = __IsMemberFilter`                                     |
| Slicer_Currency_Selection                      | 断开维度，SELECTEDVALUE 读取 `Currency_ExchangeRate` / `Currency_Symbol`                | 金额类 `DIVIDE(SUM(net_pay_amt), __FXRate)`；Display 拼接 `__CurrencySymbol`                 |
| 事实表分组字段                                 | 表格行直接拉取，模型自动传递筛选                                                          | DAX 无需显式处理（Step 1/Step 2 均保留自动传递，不移除分组维度）                                 |

### 3.4 两套时间区间（Step 1 end period / Step 2 TimeFrame）与 LY/LP 偏移（财历映射）

两套区间字段全部从 Slicer_Time_Frame_Max_VIC_Breakdown 读取（日期表不改动，防止日期表互相依赖）：

**Step 1（end period 当月，框定 VIC 买家 user_id）**：
- 本期：`Last_Fiscal_Month_Min` ~ `Last_Fiscal_Month_Max`
- LY：`Last_Fiscal_Month_Min_LY` ~ `Last_Fiscal_Month_Max_LY`
- LP：`Last_Fiscal_Month_Min_LP` ~ `Last_Fiscal_Month_Max_LP`

**Step 2（所选时间范围，聚合）**：
- 本期：`TimeFrame_Min` ~ `TimeFrame_Max`
- LY：`TimeFrame_Min_LY` ~ `TimeFrame_Max_LY`
- LP：`TimeFrame_Min_LP` ~ `TimeFrame_Max_LP`

- 无需 EDATE -12 或 Key 偏移计算（两组字段均已由日期维度表预算）

### 3.5 vs LY / vs LP / vs Store 派生计算分类

| Metric_ID | 指标                 | VICType        | 派生类型   | 计算方式            | Metric_Format  |
| --------- | -------------------- | -------------- | ---------- | ------------------- | -------------- |
| 2         | SLS vs LY            | New VIC        | 数量类 vs LY | 今年 / 去年 - 1     | delta_pct_0dp  |
| 3         | SLS vs LP            | New VIC        | 数量类 vs LP | 当期 / 上期 - 1     | delta_pct_0dp  |
| 5         | SLS% vs LY           | New VIC        | 比率类 vs LY | 今年 - 去年（差值） | delta_pts      |
| 6         | SLS% vs LP           | New VIC        | 比率类 vs LP | 当期 - 上期（差值） | delta_pts      |
| 8         | ACV vs LY            | New VIC        | 数量类 vs LY | 今年 / 去年 - 1     | delta_pct_0dp  |
| 9         | ACV vs LP            | New VIC        | 数量类 vs LP | 当期 / 上期 - 1     | delta_pct_0dp  |
| 10        | ACV vs Store         | New VIC        | vs Store   | New VIC / 全客 - 1  | delta_pct_0dp  |
| 12        | UPT vs LY            | New VIC        | 数量类 vs LY | 今年 / 去年 - 1     | delta_pct_0dp  |
| 13        | UPT vs LP            | New VIC        | 数量类 vs LP | 当期 / 上期 - 1     | delta_pct_0dp  |
| 14        | UPT vs Store         | New VIC        | vs Store   | New VIC / 全客 - 1  | delta_pct_0dp  |
| 16        | AUR vs LY            | New VIC        | 数量类 vs LY | 今年 / 去年 - 1     | delta_pct_0dp  |
| 17        | AUR vs LP            | New VIC        | 数量类 vs LP | 当期 / 上期 - 1     | delta_pct_0dp  |
| 18        | AUR vs Store         | New VIC        | vs Store   | New VIC / 全客 - 1  | delta_pct_0dp  |
| 20        | Freq. vs LY          | New VIC        | 数量类 vs LY | 今年 / 去年 - 1     | delta_pct_0dp  |
| 21        | Freq. vs LP          | New VIC        | 数量类 vs LP | 当期 / 上期 - 1     | delta_pct_0dp  |
| 22        | Freq. vs Store       | New VIC        | vs Store   | New VIC / 全客 - 1  | delta_pct_0dp  |
| 24        | SLS vs LY            | Retention VIC  | 数量类 vs LY | 今年 / 去年 - 1     | delta_pct_0dp  |
| 25        | SLS vs LP            | Retention VIC  | 数量类 vs LP | 当期 / 上期 - 1     | delta_pct_0dp  |
| 27        | SLS% vs LY           | Retention VIC  | 比率类 vs LY | 今年 - 去年（差值） | delta_pts      |
| 28        | SLS% vs LP           | Retention VIC  | 比率类 vs LP | 当期 - 上期（差值） | delta_pts      |
| 30        | ACV vs LY            | Retention VIC  | 数量类 vs LY | 今年 / 去年 - 1     | delta_pct_0dp  |
| 31        | ACV vs LP            | Retention VIC  | 数量类 vs LP | 当期 / 上期 - 1     | delta_pct_0dp  |
| 32        | ACV vs Store         | Retention VIC  | vs Store   | Retention VIC / 全客 - 1 | delta_pct_0dp  |
| 34        | UPT vs LY            | Retention VIC  | 数量类 vs LY | 今年 / 去年 - 1     | delta_pct_0dp  |
| 35        | UPT vs LP            | Retention VIC  | 数量类 vs LP | 当期 / 上期 - 1     | delta_pct_0dp  |
| 36        | UPT vs Store         | Retention VIC  | vs Store   | Retention VIC / 全客 - 1 | delta_pct_0dp  |
| 38        | AUR vs LY            | Retention VIC  | 数量类 vs LY | 今年 / 去年 - 1     | delta_pct_0dp  |
| 39        | AUR vs LP            | Retention VIC  | 数量类 vs LP | 当期 / 上期 - 1     | delta_pct_0dp  |
| 40        | AUR vs Store         | Retention VIC  | vs Store   | Retention VIC / 全客 - 1 | delta_pct_0dp  |
| 42        | Freq. vs LY          | Retention VIC  | 数量类 vs LY | 今年 / 去年 - 1     | delta_pct_0dp  |
| 43        | Freq. vs LP          | Retention VIC  | 数量类 vs LP | 当期 / 上期 - 1     | delta_pct_0dp  |
| 44        | Freq. vs Store       | Retention VIC  | vs Store   | Retention VIC / 全客 - 1 | delta_pct_0dp  |

### 3.6 Share 类指标计算（SLS% 分母为全客 net_pay_amt，同样 Step1+Step2 分步）

| Metric_ID | 指标     | VICType       | 分子筛选                                                | 分母筛选                                                       | Metric_Format |
| --------- | -------- | ------------- | ------------------------------------------------------- | -------------------------------------------------------------- | ------------- |
| 4         | SLS%     | New VIC       | Step1 end period 框定（`is_new_vic=1`）+ Step2 TimeFrame 区间 `sum(net_pay_amt)` ÷ FXRate | Step1 end period 框定全客（`is_new_vic in (0,1)`）+ Step2 TimeFrame 区间 `sum(net_pay_amt)` ÷ FXRate | percent_0dp   |
| 26        | SLS%     | Retention VIC | Step1 end period 框定（`is_retention_vic=1`）+ Step2 TimeFrame 区间 `sum(net_pay_amt)` ÷ FXRate | Step1 end period 框定全客（`is_retention_vic in (0,1)`）+ Step2 TimeFrame 区间 `sum(net_pay_amt)` ÷ FXRate | percent_0dp   |

> **SLS% 分子分母时间口径（2026-09-12 修订）**：分子 = New/Retention VIC 的 Step1+Step2 分步 SLS（同 §1.2，end period 当月框定 + 所选时间范围聚合）；分母 = 全客 Step1+Step2 分步 SLS（Step 1 end period 当月框定 `is_xxx_vic in (0,1)` 全客 user 集合 + Step 2 所选时间范围 `sum(net_pay_amt)`），与分子唯一区别是 Step 1 的筛选条件。SLS% vs LY / vs LP 的分母对应取 LY/LP 区间全客分步 SLS（Store Base Value 按 Metric_ID 同步路由两套区间）。
>
> **SLS% 不做汇率换算**：分子分母同币种抵消，DIVIDE 时 FXRate 相消。但为保持口径清晰，实现时分子分母均先除以 FXRate 再 DIVIDE（等价于不除）。

### 3.7 格式规范（按 Metric_Format 单字段分发）

| Metric_Format          | 格式串                                                                                     | 示例                    | 适用指标                                              |
| ---------------------- | ------------------------------------------------------------------------------------------ | ----------------------- | ----------------------------------------------------- |
| `currency`             | `__CurrencySymbol & FORMAT(__Value, "#,##0")`                                            | ¥1,000 / $1,000         | SLS Act                                               |
| `currency_decimal_1dp` | `__CurrencySymbol & FORMAT(__Value, "#,##0.0")`                                          | ¥1,000.0 / $1,000.0     | ACV / AUR Act                                         |
| `decimal_1dp`          | `FORMAT(__Value, "#,##0.0")`                                                              | 1.5                     | UPT / Freq. Act                                       |
| `percent_0dp`          | `FORMAT(__Value, "#,##0%")`                                                               | 15%                     | SLS% Act                                              |
| `delta_pct_0dp`        | `IF(__Value>0,"+","") & FORMAT(__Value,"#,##0%")`                                        | +15% / -3%              | 数量类 vs LY / vs LP / vs Store                       |
| `delta_pts`            | `IF(ROUND(__Value*100,0)>0,"+","") & FORMAT(__Value*100,"+#,##0pts;-#,##0pts;0pts")`    | +120pts / -80pts / 0pts | SLS% vs LY / SLS% vs LP（值×100 转 pts 在 Cell Display 中实现） |

---

## 4. 度量值实现

### 4.1 Dim_ColMetric_New_Retention_VIC（列指标维度表）

> 维度表已存在于 `Dim_ColMetric_New_Retention_VIC.md`，此处不再重复定义，直接引用。下表明晰 Metric_ID 与口径文档指标的映射关系：

| Metric_ID | VICType        | KPIGroup | ColName           | ColType   | 口径文档对应指标       | Act/LP/LY/Store 字段                                                            | 数据底表                |
| --------- | -------------- | -------- | ----------------- | --------- | ---------------------- | ------------------------------------------------------------------------------- | ----------------------- |
| 1         | New VIC        | SLS      | 1-SLS             | Act       | 1. SLS                 | is_new_vic=1, sum(net_pay_amt) ÷ FXRate                                         | a03_e2e_customer_data_m |
| 2         | New VIC        | SLS      | 2-SLS vs LY       | vs LY     | 1.1 SLS vs LY          | —                                                                               | 派生                    |
| 3         | New VIC        | SLS      | 3-SLS vs LP       | vs LP     | 1.2 SLS vs LP          | —                                                                               | 派生                    |
| 4         | New VIC        | SLS%     | 4-SLS%            | Act       | 2. SLS%                | 分子: is_new_vic=1；分母: is_new_vic in (0,1)                                   | a03_e2e_customer_data_m |
| 5         | New VIC        | SLS%     | 5-SLS% vs LY      | vs LY     | 2.1 SLS% vs LY         | —                                                                               | 派生                    |
| 6         | New VIC        | SLS%     | 6-SLS% vs LP      | vs LP     | 2.2 SLS% vs LP         | —                                                                               | 派生                    |
| 7         | New VIC        | ACV      | 7-ACV             | Act       | 3. ACV                 | 分子: sum(net_pay_amt) ÷ FXRate；分母: count(distinct user_id)（is_new_vic=1） | a03_e2e_customer_data_m |
| 8         | New VIC        | ACV      | 8-ACV vs LY       | vs LY     | 3.1 ACV vs LY          | —                                                                               | 派生                    |
| 9         | New VIC        | ACV      | 9-ACV vs LP       | vs LP     | 3.2 ACV vs LP          | —                                                                               | 派生                    |
| 10        | New VIC        | ACV      | 10-ACV vs Store   | vs Store  | 3.3 ACV vs Store       | 分子: is_new_vic=1；分母: is_new_vic in (0,1)                                   | a03_e2e_customer_data_m |
| 11        | New VIC        | UPT      | 11-UPT            | Act       | 4. UPT                 | 分子: sum(net_pay_qty)；分母: sum(net_pay_order_cnt)（is_new_vic=1）            | a03_e2e_customer_data_m |
| 12        | New VIC        | UPT      | 12-UPT vs LY      | vs LY     | 4.1 UPT vs LY          | —                                                                               | 派生                    |
| 13        | New VIC        | UPT      | 13-UPT vs LP      | vs LP     | 4.2 UPT vs LP          | —                                                                               | 派生                    |
| 14        | New VIC        | UPT      | 14-UPT vs Store   | vs Store  | 4.3 UPT vs Store       | 分子: is_new_vic=1；分母: is_new_vic in (0,1)                                   | a03_e2e_customer_data_m |
| 15        | New VIC        | AUR      | 15-AUR            | Act       | 5. AUR                 | 分子: sum(net_pay_amt) ÷ FXRate；分母: sum(net_pay_qty)（is_new_vic=1）         | a03_e2e_customer_data_m |
| 16        | New VIC        | AUR      | 16-AUR vs LY      | vs LY     | 5.1 AUR vs LY          | —                                                                               | 派生                    |
| 17        | New VIC        | AUR      | 17-AUR vs LP      | vs LP     | 5.2 AUR vs LP          | —                                                                               | 派生                    |
| 18        | New VIC        | AUR      | 18-AUR vs Store   | vs Store  | 5.3 AUR vs Store       | 分子: is_new_vic=1；分母: is_new_vic in (0,1)                                   | a03_e2e_customer_data_m |
| 19        | New VIC        | Freq.    | 19-Freq.          | Act       | 6. Freq.               | 分子: sum(net_pay_order_cnt)；分母: count(distinct user_id)（is_new_vic=1）     | a03_e2e_customer_data_m |
| 20        | New VIC        | Freq.    | 20-Freq. vs LY    | vs LY     | 6.1 Freq. vs LY        | —                                                                               | 派生                    |
| 21        | New VIC        | Freq.    | 21-Freq. vs LP    | vs LP     | 6.2 Freq. vs LP        | —                                                                               | 派生                    |
| 22        | New VIC        | Freq.    | 22-Freq. vs Store | vs Store  | 6.3 Freq. vs Store     | 分子: is_new_vic=1；分母: is_new_vic in (0,1)                                   | a03_e2e_customer_data_m |
| 23-44     | Retention VIC  | (同上)   | (同上)            | (同上)    | (同上，仅 is_retention_vic=1) | (同上，仅 is_retention_vic=1)                                                   | a03_e2e_customer_data_m |

### 4.2 VIC Breakdown Act Base Value（本期基础值）

```dax
VIC Breakdown Act Base Value = 
// ========================================
// 度量值: VIC Breakdown Act Base Value
// Display Folder: Base Metrics
// 用途: 根据 Metric_ID 路由到本期（Act）基础值
// 依赖: 'Dim_ColMetric_New_Retention_VIC'[Metric_ID, VICType],
//       a03_e2e_customer_data_m,
//       Slicer_Time_Frame_Max_VIC_Breakdown[Last_Fiscal_Month_Min/Max]（Step 1 end period 当月）,
//       Slicer_Time_Frame_Max_VIC_Breakdown[TimeFrame_Min/Max]（Step 2 所选时间范围）,
//       Slicer_Is_Employee_Selection[IsEmployee_Code],
//       IsMemberFilter[IsMember],
//       Slicer_Currency_Selection[Currency_ExchangeRate, Currency_Symbol]
// 口径来源: 口径文档/VIC Breakdown KPI.md 子模块五（Step1+Step2 分步口径，2026-09-12 修订）
// Step1+Step2 分步说明（两步时间范围不同，不能合并区间计算，分步范式参考用户"新客"DAX）:
//   - Step 1（end period 当月框定 VIC 买家 user_id）: data_date ∈ [Last_Fiscal_Month_Min, Last_Fiscal_Month_Max]，
//     按 VICType 应用 is_new_vic=1 / is_retention_vic=1，CALCULATETABLE(VALUES(user_id)) 框定 user_id 集合；
//     用 UNION+FILTER 按 __IsNewVIC 常量选择目标集合（避免 IF 返回表被降级为标量）
//   - Step 2（所选时间范围聚合）: data_date ∈ [TimeFrame_Min, TimeFrame_Max]，
//     TREATAS 将 Step 1 的 user_id 集合传递回事实表聚合；is_xxx_vic=1 仅用于 Step 1 框定，
//     Step 2 不再施加；platform / shop_info_id 行分组维度由模型自动传递保留（不移除分组维度）
//   - 两套区间均从 Slicer_Time_Frame_Max_VIC_Breakdown 读取（防止日期表互相依赖）
//   - 例外（单步口径）: ACV / Freq. 分母 count(distinct user_id) = "dt = 所选时间范围 end period，
//     筛选 is_xxx_vic=1"，即 Step 1 框定的 user_id 数量，直接 COUNTROWS(__VICUsers)
// 筛选上下文:
//   - is_member = __IsMemberFilter（默认 0 = TTL VIC）
//   - is_employee in __IsEmployeeFilter（默认 所有）
// 货币转换:
//   - 金额类（SLS/ACV/AUR 分子）÷ Currency_ExchangeRate
//   - 比率类不除（分子分母同币种抵消）
// 说明:
//   - SLS（Metric_ID 1/23）: Step2 sum(net_pay_amt) ÷ FXRate
//   - SLS%（Metric_ID 4/26）: 占位 BLANK()，实际计算在总路由（分子 Step1+Step2，分母全客 TimeFrame 区间）
//   - ACV（Metric_ID 7/29）: DIVIDE(Step2 sum(net_pay_amt) ÷ FXRate, COUNTROWS(Step1 集合))
//   - UPT（Metric_ID 11/33）: DIVIDE(Step2 sum(net_pay_qty), Step2 sum(net_pay_order_cnt))
//   - AUR（Metric_ID 15/37）: DIVIDE(Step2 sum(net_pay_amt) ÷ FXRate, Step2 sum(net_pay_qty))
//   - Freq.（Metric_ID 19/41）: DIVIDE(Step2 sum(net_pay_order_cnt), COUNTROWS(Step1 集合))
// ========================================
    VAR __MetricID = SELECTEDVALUE('Dim_ColMetric_New_Retention_VIC'[Metric_ID])
    VAR __VICType = SELECTEDVALUE('Dim_ColMetric_New_Retention_VIC'[VICType])
    // ── Step 1 时间范围（end period 当月，本期）──
    VAR __EndPeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Max_VIC_Breakdown[Last_Fiscal_Month_Min])
    VAR __EndPeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max_VIC_Breakdown[Last_Fiscal_Month_Max])
    // ── Step 2 时间范围（所选时间范围，本期；与 Step 1 同表读取，防止日期表互相依赖）──
    VAR __TimeFrameMin = SELECTEDVALUE(Slicer_Time_Frame_Max_VIC_Breakdown[TimeFrame_Min])
    VAR __TimeFrameMax = SELECTEDVALUE(Slicer_Time_Frame_Max_VIC_Breakdown[TimeFrame_Max])
    // ── 人群筛选 ──
    VAR __IsMemberFilter = SELECTEDVALUE(IsMemberFilter[IsMember], 0)
    VAR __IsEmployeeFilter = VALUES(Slicer_Is_Employee_Selection[IsEmployee_Code])
    // ── 货币转换 ──
    VAR __FXRate = SELECTEDVALUE(Slicer_Currency_Selection[Currency_ExchangeRate], 1)

    // ═══════════════════════════════════════
    // VIC 类型筛选路由（New VIC → is_new_vic=1；Retention VIC → is_retention_vic=1）
    // 说明: Step 1 表集合用 UNION+FILTER 按 __IsNewVIC 常量分支
    //       （IF 返回表会降级为标量，参考 Customer Breakdown Trend 已验证的"新客"模式）
    // ═══════════════════════════════════════
    VAR __IsNewVIC = (__VICType = "New VIC")

    // ═══════════════════════════════════════
    // Step 1: end period 当月，按 VICType 应用 is_xxx_vic=1，框定 user_id 集合
    // （__IsNewVIC 为常量时另一分支 FILTER 返回空表，UNION 结果即目标集合）
    // ═══════════════════════════════════════
    VAR __VICUsers =
        UNION(
            FILTER(
                CALCULATETABLE(
                    VALUES('a03_e2e_customer_data_m'[user_id]),
                    'a03_e2e_customer_data_m'[is_new_vic] = 1,
                    'a03_e2e_customer_data_m'[is_member] = __IsMemberFilter,
                    'a03_e2e_customer_data_m'[is_employee] in __IsEmployeeFilter,
                    'a03_e2e_customer_data_m'[data_date] >= __EndPeriodMin,
                    'a03_e2e_customer_data_m'[data_date] <= __EndPeriodMax
                ),
                __IsNewVIC
            ),
            FILTER(
                CALCULATETABLE(
                    VALUES('a03_e2e_customer_data_m'[user_id]),
                    'a03_e2e_customer_data_m'[is_retention_vic] = 1,
                    'a03_e2e_customer_data_m'[is_member] = __IsMemberFilter,
                    'a03_e2e_customer_data_m'[is_employee] in __IsEmployeeFilter,
                    'a03_e2e_customer_data_m'[data_date] >= __EndPeriodMin,
                    'a03_e2e_customer_data_m'[data_date] <= __EndPeriodMax
                ),
                NOT __IsNewVIC
            )
        )

    // ═══════════════════════════════════════
    // Step 2: 该 user_id 集合在所选时间范围（TimeFrame 区间）的聚合
    // is_xxx_vic=1 不再施加（Step 1 已框定主体）；
    // platform / shop_info_id 行分组维度由模型自动传递保留（不移除分组维度）
    // ═══════════════════════════════════════
    // SLS：sum(net_pay_amt) ÷ FXRate
    VAR __SLS_Act =
        DIVIDE(
            CALCULATE(
                SUM('a03_e2e_customer_data_m'[net_pay_amt]),
                TREATAS(__VICUsers, 'a03_e2e_customer_data_m'[user_id]),
                'a03_e2e_customer_data_m'[is_member] = __IsMemberFilter,
                'a03_e2e_customer_data_m'[is_employee] in __IsEmployeeFilter,
                'a03_e2e_customer_data_m'[data_date] >= __TimeFrameMin,
                'a03_e2e_customer_data_m'[data_date] <= __TimeFrameMax
            ),
            __FXRate
        )
    // count(distinct user_id)（is_xxx_vic=1）—— 单步口径: end period 当月
    // __VICUsers 即该口径下的去重 user_id 集合，COUNTROWS 等价于 DISTINCTCOUNT
    VAR __UserCount_Act = COUNTROWS(__VICUsers)
    // sum(net_pay_qty)（Step 1 集合 × Step 2 所选时间范围）
    VAR __NetPayQty_Act =
        CALCULATE(
            SUM('a03_e2e_customer_data_m'[net_pay_qty]),
            TREATAS(__VICUsers, 'a03_e2e_customer_data_m'[user_id]),
            'a03_e2e_customer_data_m'[is_member] = __IsMemberFilter,
            'a03_e2e_customer_data_m'[is_employee] in __IsEmployeeFilter,
            'a03_e2e_customer_data_m'[data_date] >= __TimeFrameMin,
            'a03_e2e_customer_data_m'[data_date] <= __TimeFrameMax
        )
    // sum(net_pay_order_cnt)（Step 1 集合 × Step 2 所选时间范围）
    VAR __NetPayOrderCnt_Act =
        CALCULATE(
            SUM('a03_e2e_customer_data_m'[net_pay_order_cnt]),
            TREATAS(__VICUsers, 'a03_e2e_customer_data_m'[user_id]),
            'a03_e2e_customer_data_m'[is_member] = __IsMemberFilter,
            'a03_e2e_customer_data_m'[is_employee] in __IsEmployeeFilter,
            'a03_e2e_customer_data_m'[data_date] >= __TimeFrameMin,
            'a03_e2e_customer_data_m'[data_date] <= __TimeFrameMax
        )

    RETURN
        SWITCH(
            __MetricID,
            // ── SLS Act（New VIC=1, Retention VIC=23）──
            1,  __SLS_Act,
            23, __SLS_Act,
            // ── SLS% Act（New VIC=4, Retention VIC=26）──
            // 占位: SLS% 的实际计算在 Base Value 总路由中通过 Store Base Value 获取全客分母后完成
            //       此处返回 BLANK() 避免混淆，总路由不会通过此路径取 SLS% 的值
            4,  BLANK(),
            26, BLANK(),
            // ── ACV Act（New VIC=7, Retention VIC=29）──
            7,  DIVIDE(__SLS_Act, __UserCount_Act),
            29, DIVIDE(__SLS_Act, __UserCount_Act),
            // ── UPT Act（New VIC=11, Retention VIC=33）──
            11, DIVIDE(__NetPayQty_Act, __NetPayOrderCnt_Act),
            33, DIVIDE(__NetPayQty_Act, __NetPayOrderCnt_Act),
            // ── AUR Act（New VIC=15, Retention VIC=37）──
            15, DIVIDE(__SLS_Act, __NetPayQty_Act),
            37, DIVIDE(__SLS_Act, __NetPayQty_Act),
            // ── Freq. Act（New VIC=19, Retention VIC=41）──
            19, DIVIDE(__NetPayOrderCnt_Act, __UserCount_Act),
            41, DIVIDE(__NetPayOrderCnt_Act, __UserCount_Act),
            BLANK()
        )

/* ── 旧逻辑：Step1+Step2 合并为 end period 当月单步聚合（2026-09-12 弃用，保留备查）──
   当时口径理解: Step2 "所选时间范围" = end period 当月（与 Step 1 一致），因 platform / shop_info_id
   分组由模型自动传递，直接在 end period 当月区间（__PeriodMin/__PeriodMax = Last_Fiscal_Month_Min/Max）
   内应用 is_xxx_vic=1 + is_member + is_employee 筛选做单步聚合（IF 双 CALCULATE 分支）：
     __SLS_Act = DIVIDE(IF(__IsNewVIC, CALCULATE(SUM(net_pay_amt), is_new_vic=1, ...当月区间...),
                            CALCULATE(..., is_retention_vic=1, ...)), __FXRate)
     __UserCount_Act / __NetPayQty_Act / __NetPayOrderCnt_Act = 同款 IF 双 CALCULATE
     （DISTINCTCOUNT(user_id) / SUM(net_pay_qty) / SUM(net_pay_order_cnt)）
   如需回退: 注释掉上方 Step1/Step2 分步实现（含 __VICUsers 与 TREATAS 块），
   将时间变量恢复为 __PeriodMin/__PeriodMax（Last_Fiscal_Month_Min/Max）并按上述结构恢复单步实现。
── 旧逻辑结束 ── */
```

> **说明**：Metric_ID=4/26（SLS% Act）在 Act Base Value 中为占位，实际 SLS% 计算需要全客分母，在 Base Value 总路由中通过调用 `[VIC Breakdown Store Base Value]` 获取分母后计算。

### 4.3 VIC Breakdown LY Base Value（去年同期基础值）

```dax
VIC Breakdown LY Base Value = 
// ========================================
// 度量值: VIC Breakdown LY Base Value
// Display Folder: Base Metrics
// 用途: 根据 Metric_ID 路由到去年同期（LY）基础值
// 依赖: 'Dim_ColMetric_New_Retention_VIC'[Metric_ID, VICType],
//       Slicer_Time_Frame_Max_VIC_Breakdown[Last_Fiscal_Month_Min_LY/Max_LY]（Step 1 LY end period 当月）,
//       Slicer_Time_Frame_Max_VIC_Breakdown[TimeFrame_Min_LY/Max_LY]（Step 2 LY 所选时间范围）,
//       a03_e2e_customer_data_m,
//       Slicer_Currency_Selection[Currency_ExchangeRate]
// 口径来源: 口径文档/VIC Breakdown KPI.md 子模块五（Step1+Step2 分步口径，LY 版本，2026-09-12 修订）
// 时间偏移: 财历映射（直接读取 Max 表已预算的 _LY 字段，无需 EDATE）
// Step1+Step2 分步说明（与 Act Base Value 对称，两步时间范围不同，不能合并）:
//   - Step 1（LY end period 当月框定 VIC 买家）: data_date ∈ [Last_Fiscal_Month_Min_LY, Last_Fiscal_Month_Max_LY]，
//     按 VICType 应用 is_new_vic=1 / is_retention_vic=1，UNION+FILTER 框定 user_id 集合
//   - Step 2（LY 所选时间范围聚合）: data_date ∈ [TimeFrame_Min_LY, TimeFrame_Max_LY]，
//     TREATAS 传递 Step 1 集合聚合；is_xxx_vic=1 不再施加；分组维度自动传递保留（不移除）
//   - __UserCount_LY = COUNTROWS(Step 1 集合)（LY end period 当月单步口径，ACV/Freq. LY 分母）
// 说明:
//   - 与 Act Base Value 结构对称，仅两套区间均替换为 _LY 版本
//   - SLS% LY 在总路由中通过 Store Base Value(LY) 获取全客分母
// ========================================
    VAR __MetricID = SELECTEDVALUE('Dim_ColMetric_New_Retention_VIC'[Metric_ID])
    VAR __VICType = SELECTEDVALUE('Dim_ColMetric_New_Retention_VIC'[VICType])
    // ── Step 1 时间范围（LY end period 当月；Max 表已预算直接读取）──
    VAR __EndPeriodMin_LY = SELECTEDVALUE(Slicer_Time_Frame_Max_VIC_Breakdown[Last_Fiscal_Month_Min_LY])
    VAR __EndPeriodMax_LY = SELECTEDVALUE(Slicer_Time_Frame_Max_VIC_Breakdown[Last_Fiscal_Month_Max_LY])
    // ── Step 2 时间范围（LY 所选时间范围；与 Step 1 同表读取，防止日期表互相依赖）──
    VAR __LYMin = SELECTEDVALUE(Slicer_Time_Frame_Max_VIC_Breakdown[TimeFrame_Min_LY])
    VAR __LYMax = SELECTEDVALUE(Slicer_Time_Frame_Max_VIC_Breakdown[TimeFrame_Max_LY])
    // ── 人群筛选 ──
    VAR __IsMemberFilter = SELECTEDVALUE(IsMemberFilter[IsMember], 0)
    VAR __IsEmployeeFilter = VALUES(Slicer_Is_Employee_Selection[IsEmployee_Code])
    // ── 货币转换 ──
    VAR __FXRate = SELECTEDVALUE(Slicer_Currency_Selection[Currency_ExchangeRate], 1)

    // ═══════════════════════════════════════
    // VIC 类型筛选路由（New VIC → is_new_vic=1；Retention VIC → is_retention_vic=1）
    // 说明: Step 1 表集合用 UNION+FILTER 按 __IsNewVIC 常量分支
    //       （IF 返回表会降级为标量，参考 Customer Breakdown Trend 已验证的"新客"模式）
    // ═══════════════════════════════════════
    VAR __IsNewVIC = (__VICType = "New VIC")

    // ═══════════════════════════════════════
    // Step 1: LY end period 当月，按 VICType 应用 is_xxx_vic=1，框定 user_id 集合
    // （__IsNewVIC 为常量时另一分支 FILTER 返回空表，UNION 结果即目标集合）
    // ═══════════════════════════════════════
    VAR __VICUsers_LY =
        UNION(
            FILTER(
                CALCULATETABLE(
                    VALUES('a03_e2e_customer_data_m'[user_id]),
                    'a03_e2e_customer_data_m'[is_new_vic] = 1,
                    'a03_e2e_customer_data_m'[is_member] = __IsMemberFilter,
                    'a03_e2e_customer_data_m'[is_employee] in __IsEmployeeFilter,
                    'a03_e2e_customer_data_m'[data_date] >= __EndPeriodMin_LY,
                    'a03_e2e_customer_data_m'[data_date] <= __EndPeriodMax_LY
                ),
                __IsNewVIC
            ),
            FILTER(
                CALCULATETABLE(
                    VALUES('a03_e2e_customer_data_m'[user_id]),
                    'a03_e2e_customer_data_m'[is_retention_vic] = 1,
                    'a03_e2e_customer_data_m'[is_member] = __IsMemberFilter,
                    'a03_e2e_customer_data_m'[is_employee] in __IsEmployeeFilter,
                    'a03_e2e_customer_data_m'[data_date] >= __EndPeriodMin_LY,
                    'a03_e2e_customer_data_m'[data_date] <= __EndPeriodMax_LY
                ),
                NOT __IsNewVIC
            )
        )

    // ═══════════════════════════════════════
    // Step 2: 该 user_id 集合在 LY 所选时间范围（TimeFrame_LY 区间）的聚合
    // is_xxx_vic=1 不再施加（Step 1 已框定主体）；分组维度自动传递保留（不移除）
    // ═══════════════════════════════════════
    VAR __SLS_LY =
        DIVIDE(
            CALCULATE(
                SUM('a03_e2e_customer_data_m'[net_pay_amt]),
                TREATAS(__VICUsers_LY, 'a03_e2e_customer_data_m'[user_id]),
                'a03_e2e_customer_data_m'[is_member] = __IsMemberFilter,
                'a03_e2e_customer_data_m'[is_employee] in __IsEmployeeFilter,
                'a03_e2e_customer_data_m'[data_date] >= __LYMin,
                'a03_e2e_customer_data_m'[data_date] <= __LYMax
            ),
            __FXRate
        )
    // count(distinct user_id)（is_xxx_vic=1）—— 单步口径: LY end period 当月
    // __VICUsers_LY 即该口径下的去重 user_id 集合，COUNTROWS 等价于 DISTINCTCOUNT
    VAR __UserCount_LY = COUNTROWS(__VICUsers_LY)
    // sum(net_pay_qty)（Step 1 集合 × Step 2 LY 所选时间范围）
    VAR __NetPayQty_LY =
        CALCULATE(
            SUM('a03_e2e_customer_data_m'[net_pay_qty]),
            TREATAS(__VICUsers_LY, 'a03_e2e_customer_data_m'[user_id]),
            'a03_e2e_customer_data_m'[is_member] = __IsMemberFilter,
            'a03_e2e_customer_data_m'[is_employee] in __IsEmployeeFilter,
            'a03_e2e_customer_data_m'[data_date] >= __LYMin,
            'a03_e2e_customer_data_m'[data_date] <= __LYMax
        )
    // sum(net_pay_order_cnt)（Step 1 集合 × Step 2 LY 所选时间范围）
    VAR __NetPayOrderCnt_LY =
        CALCULATE(
            SUM('a03_e2e_customer_data_m'[net_pay_order_cnt]),
            TREATAS(__VICUsers_LY, 'a03_e2e_customer_data_m'[user_id]),
            'a03_e2e_customer_data_m'[is_member] = __IsMemberFilter,
            'a03_e2e_customer_data_m'[is_employee] in __IsEmployeeFilter,
            'a03_e2e_customer_data_m'[data_date] >= __LYMin,
            'a03_e2e_customer_data_m'[data_date] <= __LYMax
        )

    RETURN
        SWITCH(
            __MetricID,
            // ── SLS LY ──
            1,  __SLS_LY,
            23, __SLS_LY,
            // ── SLS% LY（占位: SLS% 的实际计算在总路由中完成，此处返回 BLANK()）──
            4,  BLANK(),
            26, BLANK(),
            // ── ACV LY ──
            7,  DIVIDE(__SLS_LY, __UserCount_LY),
            29, DIVIDE(__SLS_LY, __UserCount_LY),
            // ── UPT LY ──
            11, DIVIDE(__NetPayQty_LY, __NetPayOrderCnt_LY),
            33, DIVIDE(__NetPayQty_LY, __NetPayOrderCnt_LY),
            // ── AUR LY ──
            15, DIVIDE(__SLS_LY, __NetPayQty_LY),
            37, DIVIDE(__SLS_LY, __NetPayQty_LY),
            // ── Freq. LY ──
            19, DIVIDE(__NetPayOrderCnt_LY, __UserCount_LY),
            41, DIVIDE(__NetPayOrderCnt_LY, __UserCount_LY),
            BLANK()
        )

/* ── 旧逻辑：Step1+Step2 合并为 LY end period 当月单步聚合（2026-09-12 弃用，保留备查）──
   当时口径理解: Step2 "所选时间范围" = LY end period 当月（与 Step 1 一致），直接在 LY 当月区间
   （__LYMin/__LYMax = Last_Fiscal_Month_Min_LY/Max_LY）内应用 is_xxx_vic=1 + is_member + is_employee
   筛选做单步聚合（IF 双 CALCULATE 分支，结构同 Act 旧逻辑，仅区间为 _LY 版本）。
   如需回退: 注释掉上方 Step1/Step2 分步实现（含 __VICUsers_LY 与 TREATAS 块），
   将 __LYMin/__LYMax 恢复为 Last_Fiscal_Month_Min_LY/Max_LY 并按 Act 旧逻辑结构恢复单步实现。
── 旧逻辑结束 ── */
```

### 4.4 VIC Breakdown LP Base Value（上期基础值）

```dax
VIC Breakdown LP Base Value = 
// ========================================
// 度量值: VIC Breakdown LP Base Value
// Display Folder: Base Metrics
// 用途: 根据 Metric_ID 路由到上期（LP）基础值
// 依赖: 'Dim_ColMetric_New_Retention_VIC'[Metric_ID, VICType],
//       Slicer_Time_Frame_Max_VIC_Breakdown[Last_Fiscal_Month_Min_LP/Max_LP]（Step 1 LP end period 当月）,
//       Slicer_Time_Frame_Max_VIC_Breakdown[TimeFrame_Min_LP/Max_LP]（Step 2 LP 所选时间范围）,
//       a03_e2e_customer_data_m,
//       Slicer_Currency_Selection[Currency_ExchangeRate]
// 口径来源: 口径文档/VIC Breakdown KPI.md 子模块五（Step1+Step2 分步口径，LP 版本，2026-09-12 修订）
// 时间偏移: 财历映射（直接读取 Max 表已预算的 _LP 字段，无需 EDATE）
// Step1+Step2 分步说明（与 Act Base Value 对称，两步时间范围不同，不能合并）:
//   - Step 1（LP end period 当月框定 VIC 买家）: data_date ∈ [Last_Fiscal_Month_Min_LP, Last_Fiscal_Month_Max_LP]，
//     按 VICType 应用 is_new_vic=1 / is_retention_vic=1，UNION+FILTER 框定 user_id 集合
//   - Step 2（LP 所选时间范围聚合）: data_date ∈ [TimeFrame_Min_LP, TimeFrame_Max_LP]，
//     TREATAS 传递 Step 1 集合聚合；is_xxx_vic=1 不再施加；分组维度自动传递保留（不移除）
//   - __UserCount_LP = COUNTROWS(Step 1 集合)（LP end period 当月单步口径，ACV/Freq. LP 分母）
// 说明:
//   - 与 Act Base Value 结构对称，仅两套区间均替换为 _LP 版本
//   - SLS% LP 在总路由中通过 Store Base Value(LP) 获取全客分母
// ========================================
    VAR __MetricID = SELECTEDVALUE('Dim_ColMetric_New_Retention_VIC'[Metric_ID])
    VAR __VICType = SELECTEDVALUE('Dim_ColMetric_New_Retention_VIC'[VICType])
    // ── Step 1 时间范围（LP end period 当月；Max 表已预算直接读取）──
    VAR __EndPeriodMin_LP = SELECTEDVALUE(Slicer_Time_Frame_Max_VIC_Breakdown[Last_Fiscal_Month_Min_LP])
    VAR __EndPeriodMax_LP = SELECTEDVALUE(Slicer_Time_Frame_Max_VIC_Breakdown[Last_Fiscal_Month_Max_LP])
    // ── Step 2 时间范围（LP 所选时间范围；与 Step 1 同表读取，防止日期表互相依赖）──
    VAR __LPMin = SELECTEDVALUE(Slicer_Time_Frame_Max_VIC_Breakdown[TimeFrame_Min_LP])
    VAR __LPMax = SELECTEDVALUE(Slicer_Time_Frame_Max_VIC_Breakdown[TimeFrame_Max_LP])
    // ── 人群筛选 ──
    VAR __IsMemberFilter = SELECTEDVALUE(IsMemberFilter[IsMember], 0)
    VAR __IsEmployeeFilter = VALUES(Slicer_Is_Employee_Selection[IsEmployee_Code])
    // ── 货币转换 ──
    VAR __FXRate = SELECTEDVALUE(Slicer_Currency_Selection[Currency_ExchangeRate], 1)

    // ═══════════════════════════════════════
    // VIC 类型筛选路由（New VIC → is_new_vic=1；Retention VIC → is_retention_vic=1）
    // 说明: Step 1 表集合用 UNION+FILTER 按 __IsNewVIC 常量分支
    //       （IF 返回表会降级为标量，参考 Customer Breakdown Trend 已验证的"新客"模式）
    // ═══════════════════════════════════════
    VAR __IsNewVIC = (__VICType = "New VIC")

    // ═══════════════════════════════════════
    // Step 1: LP end period 当月，按 VICType 应用 is_xxx_vic=1，框定 user_id 集合
    // （__IsNewVIC 为常量时另一分支 FILTER 返回空表，UNION 结果即目标集合）
    // ═══════════════════════════════════════
    VAR __VICUsers_LP =
        UNION(
            FILTER(
                CALCULATETABLE(
                    VALUES('a03_e2e_customer_data_m'[user_id]),
                    'a03_e2e_customer_data_m'[is_new_vic] = 1,
                    'a03_e2e_customer_data_m'[is_member] = __IsMemberFilter,
                    'a03_e2e_customer_data_m'[is_employee] in __IsEmployeeFilter,
                    'a03_e2e_customer_data_m'[data_date] >= __EndPeriodMin_LP,
                    'a03_e2e_customer_data_m'[data_date] <= __EndPeriodMax_LP
                ),
                __IsNewVIC
            ),
            FILTER(
                CALCULATETABLE(
                    VALUES('a03_e2e_customer_data_m'[user_id]),
                    'a03_e2e_customer_data_m'[is_retention_vic] = 1,
                    'a03_e2e_customer_data_m'[is_member] = __IsMemberFilter,
                    'a03_e2e_customer_data_m'[is_employee] in __IsEmployeeFilter,
                    'a03_e2e_customer_data_m'[data_date] >= __EndPeriodMin_LP,
                    'a03_e2e_customer_data_m'[data_date] <= __EndPeriodMax_LP
                ),
                NOT __IsNewVIC
            )
        )

    // ═══════════════════════════════════════
    // Step 2: 该 user_id 集合在 LP 所选时间范围（TimeFrame_LP 区间）的聚合
    // is_xxx_vic=1 不再施加（Step 1 已框定主体）；分组维度自动传递保留（不移除）
    // ═══════════════════════════════════════
    VAR __SLS_LP =
        DIVIDE(
            CALCULATE(
                SUM('a03_e2e_customer_data_m'[net_pay_amt]),
                TREATAS(__VICUsers_LP, 'a03_e2e_customer_data_m'[user_id]),
                'a03_e2e_customer_data_m'[is_member] = __IsMemberFilter,
                'a03_e2e_customer_data_m'[is_employee] in __IsEmployeeFilter,
                'a03_e2e_customer_data_m'[data_date] >= __LPMin,
                'a03_e2e_customer_data_m'[data_date] <= __LPMax
            ),
            __FXRate
        )
    // count(distinct user_id)（is_xxx_vic=1）—— 单步口径: LP end period 当月
    // __VICUsers_LP 即该口径下的去重 user_id 集合，COUNTROWS 等价于 DISTINCTCOUNT
    VAR __UserCount_LP = COUNTROWS(__VICUsers_LP)
    // sum(net_pay_qty)（Step 1 集合 × Step 2 LP 所选时间范围）
    VAR __NetPayQty_LP =
        CALCULATE(
            SUM('a03_e2e_customer_data_m'[net_pay_qty]),
            TREATAS(__VICUsers_LP, 'a03_e2e_customer_data_m'[user_id]),
            'a03_e2e_customer_data_m'[is_member] = __IsMemberFilter,
            'a03_e2e_customer_data_m'[is_employee] in __IsEmployeeFilter,
            'a03_e2e_customer_data_m'[data_date] >= __LPMin,
            'a03_e2e_customer_data_m'[data_date] <= __LPMax
        )
    // sum(net_pay_order_cnt)（Step 1 集合 × Step 2 LP 所选时间范围）
    VAR __NetPayOrderCnt_LP =
        CALCULATE(
            SUM('a03_e2e_customer_data_m'[net_pay_order_cnt]),
            TREATAS(__VICUsers_LP, 'a03_e2e_customer_data_m'[user_id]),
            'a03_e2e_customer_data_m'[is_member] = __IsMemberFilter,
            'a03_e2e_customer_data_m'[is_employee] in __IsEmployeeFilter,
            'a03_e2e_customer_data_m'[data_date] >= __LPMin,
            'a03_e2e_customer_data_m'[data_date] <= __LPMax
        )

    RETURN
        SWITCH(
            __MetricID,
            // ── SLS LP ──
            1,  __SLS_LP,
            23, __SLS_LP,
            // ── SLS% LP（占位: SLS% 的实际计算在总路由中完成，此处返回 BLANK()）──
            4,  BLANK(),
            26, BLANK(),
            // ── ACV LP ──
            7,  DIVIDE(__SLS_LP, __UserCount_LP),
            29, DIVIDE(__SLS_LP, __UserCount_LP),
            // ── UPT LP ──
            11, DIVIDE(__NetPayQty_LP, __NetPayOrderCnt_LP),
            33, DIVIDE(__NetPayQty_LP, __NetPayOrderCnt_LP),
            // ── AUR LP ──
            15, DIVIDE(__SLS_LP, __NetPayQty_LP),
            37, DIVIDE(__SLS_LP, __NetPayQty_LP),
            // ── Freq. LP ──
            19, DIVIDE(__NetPayOrderCnt_LP, __UserCount_LP),
            41, DIVIDE(__NetPayOrderCnt_LP, __UserCount_LP),
            BLANK()
        )

/* ── 旧逻辑：Step1+Step2 合并为 LP end period 当月单步聚合（2026-09-12 弃用，保留备查）──
   当时口径理解: Step2 "所选时间范围" = LP end period 当月（与 Step 1 一致），直接在 LP 当月区间
   （__LPMin/__LPMax = Last_Fiscal_Month_Min_LP/Max_LP）内应用 is_xxx_vic=1 + is_member + is_employee
   筛选做单步聚合（IF 双 CALCULATE 分支，结构同 Act 旧逻辑，仅区间为 _LP 版本）。
   如需回退: 注释掉上方 Step1/Step2 分步实现（含 __VICUsers_LP 与 TREATAS 块），
   将 __LPMin/__LPMax 恢复为 Last_Fiscal_Month_Min_LP/Max_LP 并按 Act 旧逻辑结构恢复单步实现。
── 旧逻辑结束 ── */
```

### 4.5 VIC Breakdown Store Base Value（全客基础值，用于 vs Store 分母）

```dax
VIC Breakdown Store Base Value = 
// ========================================
// 度量值: VIC Breakdown Store Base Value
// Display Folder: Base Metrics
// 用途: 根据 Metric_ID 路由到全客（Store）基础值，作为 vs Store 的分母和 SLS% 的分母
// 依赖: 'Dim_ColMetric_New_Retention_VIC'[Metric_ID, VICType],
//       Slicer_Time_Frame_Max_VIC_Breakdown[Last_Fiscal_Month_Min/Max,
//                                           Last_Fiscal_Month_Min_LY/Max_LY,
//                                           Last_Fiscal_Month_Min_LP/Max_LP]（Step 1 end period 当月区间）,
//       Slicer_Time_Frame_Max_VIC_Breakdown[TimeFrame_Min/Max,
//                                           TimeFrame_Min_LY/Max_LY,
//                                           TimeFrame_Min_LP/Max_LP]（Step 2 所选时间范围区间）,
//       a03_e2e_customer_data_m,
//       Slicer_Currency_Selection[Currency_ExchangeRate]
// 口径来源: 口径文档/VIC Breakdown KPI.md 子模块五（Step1+Step2 分步口径，全客分母同样分步，2026-09-12 修订）
// 筛选上下文:
//   - 全客筛选：is_xxx_vic in (0, 1)（New VIC → is_new_vic in (0,1)；Retention VIC → is_retention_vic in (0,1)）
//   - is_member / is_employee 筛选统一应用
// Step1+Step2 分步说明（全客与 VIC 侧对称，唯一区别是 Step 1 的筛选条件，两步时间范围不同不能合并）:
//   - Step 1（end period 当月框定全客 user 集合）: data_date ∈ 路由后 end period 当月区间，
//     按 VICType 应用 is_xxx_vic IN {0, 1}（全客），UNION+FILTER 框定 user_id 集合
//   - Step 2（所选时间范围聚合）: data_date ∈ 路由后 TimeFrame 区间，TREATAS 传递 Step 1 集合聚合；
//     is_xxx_vic IN {0,1} 不再施加；分组维度自动传递保留（不移除）
//   - __UserCount_Store = COUNTROWS(Step 1 集合)（end period 当月单步口径，ACV/Freq. vs Store 分母）
// 说明:
//   - vs Store 仅 ACV / UPT / AUR / Freq. 四个 KPI 分组有（SLS / SLS% 无 vs Store）
//   - 全客与 VIC 侧（Act/LY/LP Base Value）结构对称，区别仅 Step 1 筛选条件（IN {0,1} vs =1）——
//     单步 TimeFrame 聚合的人群包含"TimeFrame 内活跃但 end period 当月不活跃"的人，
//     与分子（end period 当月框定人群）基准不一致，故全客分母同样分步
//   - 全客 ACV = Step2 sum(net_pay_amt) ÷ FXRate / COUNTROWS(Step1 集合)（is_xxx_vic in (0,1)）
//   - 全客 UPT = Step2 sum(net_pay_qty) / sum(net_pay_order_cnt)（is_xxx_vic in (0,1)）
//   - 全客 AUR = Step2 sum(net_pay_amt) ÷ FXRate / sum(net_pay_qty)（is_xxx_vic in (0,1)）
//   - 全客 Freq. = Step2 sum(net_pay_order_cnt) / COUNTROWS(Step1 集合)（is_xxx_vic in (0,1)）
//   - 同时也用于 SLS% 的分母（全客分步 SLS：Step1 集合 × Step2 区间 sum(net_pay_amt)）
// 时间区间路由（关键修正）:
//   - 本度量值被总路由通过 CALCULATE + [Metric_ID]=x 调用，外层会覆盖 Metric_ID
//   - 维度表中 Metric_ID 与 ColType 一一绑定，覆盖 Metric_ID 后 SELECTEDVALUE(ColType)
//     会读到新 Metric_ID 对应行的 ColType，而非外层期望的区间
//   - 因此本度量值内部直接按 Metric_ID 推导两套时间区间（Step 1 / Step 2 同步路由），不读 ColType：
//       * Metric_ID 5/27（SLS% vs LY 分母）→ LY end period 当月 + LY TimeFrame 区间
//       * Metric_ID 6/28（SLS% vs LP 分母）→ LP end period 当月 + LP TimeFrame 区间
//       * 其他（4/26 SLS% Act 分母、10/14/18/22/32/36/40/44 vs Store 分母）→ 本期 end period 当月 + Act TimeFrame 区间
// ========================================
    // 本度量值内部按 Metric_ID 推导两套时间区间（不依赖 ColType，避免外层覆盖 Metric_ID 后冲突）
    // Step 1（end period 当月框定全客 user 集合）与 Step 2（所选时间范围聚合）同步按 Metric_ID 路由:
    //   vs Store 分母（10/14/18/22/32/36/40/44）→ 本期 end period 当月 + Act TimeFrame 区间
    //   SLS% Act 分母（4/26）→ 本期 end period 当月 + Act TimeFrame 区间
    //   SLS% vs LY 分母（5/27）→ LY end period 当月 + LY TimeFrame 区间
    //   SLS% vs LP 分母（6/28）→ LP end period 当月 + LP TimeFrame 区间
    VAR __MetricID = SELECTEDVALUE('Dim_ColMetric_New_Retention_VIC'[Metric_ID])
    VAR __VICType = SELECTEDVALUE('Dim_ColMetric_New_Retention_VIC'[VICType])
    // ── Step 1 时间范围（end period 当月框定全客 user 集合，按 Metric_ID 推导，不能读 ColType）──
    // 关键修正: 维度表中 Metric_ID 与 ColType 一一绑定，外层总路由覆盖 Metric_ID 后，
    //          SELECTEDVALUE(ColType) 会读到新 Metric_ID 对应行的 ColType，而非外层期望的区间。
    //          因此 Store Base Value 内部直接按 Metric_ID 推导时间区间：
    //   - Metric_ID 5/27（SLS% vs LY 分母）→ LY end period 当月（Last_Fiscal_Month_*_LY）
    //   - Metric_ID 6/28（SLS% vs LP 分母）→ LP end period 当月（Last_Fiscal_Month_*_LP）
    //   - 其他（4/26 SLS% Act 分母、10/14/18/22/32/36/40/44 vs Store 分母）→ 本期 end period 当月
    VAR __EndPeriodMin =
        IF(
            __MetricID IN {5, 27},
            SELECTEDVALUE(Slicer_Time_Frame_Max_VIC_Breakdown[Last_Fiscal_Month_Min_LY]),
            IF(
                __MetricID IN {6, 28},
                SELECTEDVALUE(Slicer_Time_Frame_Max_VIC_Breakdown[Last_Fiscal_Month_Min_LP]),
                SELECTEDVALUE(Slicer_Time_Frame_Max_VIC_Breakdown[Last_Fiscal_Month_Min])  // Act / vs Store
            )
        )
    VAR __EndPeriodMax =
        IF(
            __MetricID IN {5, 27},
            SELECTEDVALUE(Slicer_Time_Frame_Max_VIC_Breakdown[Last_Fiscal_Month_Max_LY]),
            IF(
                __MetricID IN {6, 28},
                SELECTEDVALUE(Slicer_Time_Frame_Max_VIC_Breakdown[Last_Fiscal_Month_Max_LP]),
                SELECTEDVALUE(Slicer_Time_Frame_Max_VIC_Breakdown[Last_Fiscal_Month_Max])  // Act / vs Store
            )
        )
    // ── Step 2 时间范围（所选时间范围聚合，按 Metric_ID 推导）──
    //   - Metric_ID 5/27（SLS% vs LY 分母）→ LY TimeFrame 区间
    //   - Metric_ID 6/28（SLS% vs LP 分母）→ LP TimeFrame 区间
    //   - 其他（4/26 SLS% Act 分母、10/14/18/22/32/36/40/44 vs Store 分母）→ Act TimeFrame 区间
    VAR __PeriodMin =
        IF(
            __MetricID IN {5, 27},
            SELECTEDVALUE(Slicer_Time_Frame_Max_VIC_Breakdown[TimeFrame_Min_LY]),
            IF(
                __MetricID IN {6, 28},
                SELECTEDVALUE(Slicer_Time_Frame_Max_VIC_Breakdown[TimeFrame_Min_LP]),
                SELECTEDVALUE(Slicer_Time_Frame_Max_VIC_Breakdown[TimeFrame_Min])  // Act / vs Store
            )
        )
    VAR __PeriodMax =
        IF(
            __MetricID IN {5, 27},
            SELECTEDVALUE(Slicer_Time_Frame_Max_VIC_Breakdown[TimeFrame_Max_LY]),
            IF(
                __MetricID IN {6, 28},
                SELECTEDVALUE(Slicer_Time_Frame_Max_VIC_Breakdown[TimeFrame_Max_LP]),
                SELECTEDVALUE(Slicer_Time_Frame_Max_VIC_Breakdown[TimeFrame_Max])  // Act / vs Store
            )
        )
    // ── 人群筛选 ──
    VAR __IsMemberFilter = SELECTEDVALUE(IsMemberFilter[IsMember], 0)
    VAR __IsEmployeeFilter = VALUES(Slicer_Is_Employee_Selection[IsEmployee_Code])
    // ── 货币转换 ──
    VAR __FXRate = SELECTEDVALUE(Slicer_Currency_Selection[Currency_ExchangeRate], 1)

    // ═══════════════════════════════════════
    // 全客筛选路由（New VIC → is_new_vic in {0,1}；Retention VIC → is_retention_vic in {0,1}）
    // 说明: 全客 Step 1 集合框定与 VIC 侧对称，用 UNION+FILTER 按 __IsNewVIC 常量分支
    //       （IF 返回表会降级为标量，参考 Customer Breakdown Trend 已验证的"新客"模式）
    // ═══════════════════════════════════════
    VAR __IsNewVIC = (__VICType = "New VIC")

    // ═══════════════════════════════════════
    // Step 1: end period 当月（路由后），按 VICType 应用 is_xxx_vic IN {0,1}（全客），框定 user_id 集合
    // （__IsNewVIC 为常量时另一分支 FILTER 返回空表，UNION 结果即目标集合）
    // ═══════════════════════════════════════
    VAR __AllUsers =
        UNION(
            FILTER(
                CALCULATETABLE(
                    VALUES('a03_e2e_customer_data_m'[user_id]),
                    'a03_e2e_customer_data_m'[is_new_vic] IN {0, 1},
                    'a03_e2e_customer_data_m'[is_member] = __IsMemberFilter,
                    'a03_e2e_customer_data_m'[is_employee] in __IsEmployeeFilter,
                    'a03_e2e_customer_data_m'[data_date] >= __EndPeriodMin,
                    'a03_e2e_customer_data_m'[data_date] <= __EndPeriodMax
                ),
                __IsNewVIC
            ),
            FILTER(
                CALCULATETABLE(
                    VALUES('a03_e2e_customer_data_m'[user_id]),
                    'a03_e2e_customer_data_m'[is_retention_vic] IN {0, 1},
                    'a03_e2e_customer_data_m'[is_member] = __IsMemberFilter,
                    'a03_e2e_customer_data_m'[is_employee] in __IsEmployeeFilter,
                    'a03_e2e_customer_data_m'[data_date] >= __EndPeriodMin,
                    'a03_e2e_customer_data_m'[data_date] <= __EndPeriodMax
                ),
                NOT __IsNewVIC
            )
        )

    // ═══════════════════════════════════════
    // Step 2: 该 user_id 集合在所选时间范围（路由后 TimeFrame 区间）的聚合
    // is_xxx_vic IN {0,1} 不再施加（Step 1 已框定主体）；分组维度自动传递保留（不移除）
    // ═══════════════════════════════════════
    VAR __SLS_Store =
        DIVIDE(
            CALCULATE(
                SUM('a03_e2e_customer_data_m'[net_pay_amt]),
                TREATAS(__AllUsers, 'a03_e2e_customer_data_m'[user_id]),
                'a03_e2e_customer_data_m'[is_member] = __IsMemberFilter,
                'a03_e2e_customer_data_m'[is_employee] in __IsEmployeeFilter,
                'a03_e2e_customer_data_m'[data_date] >= __PeriodMin,
                'a03_e2e_customer_data_m'[data_date] <= __PeriodMax
            ),
            __FXRate
        )
    // count(distinct user_id)（is_xxx_vic in (0,1)）—— 单步口径: end period 当月（路由后）
    // __AllUsers 即该口径下的去重 user_id 集合，COUNTROWS 等价于 DISTINCTCOUNT
    // （vs Store 场景 Metric_ID 10/14/18/22/32/36/40/44 路由到本期 end period 当月）
    VAR __UserCount_Store = COUNTROWS(__AllUsers)
    // sum(net_pay_qty)（Step 1 集合 × Step 2 路由后 TimeFrame 区间）
    VAR __NetPayQty_Store =
        CALCULATE(
            SUM('a03_e2e_customer_data_m'[net_pay_qty]),
            TREATAS(__AllUsers, 'a03_e2e_customer_data_m'[user_id]),
            'a03_e2e_customer_data_m'[is_member] = __IsMemberFilter,
            'a03_e2e_customer_data_m'[is_employee] in __IsEmployeeFilter,
            'a03_e2e_customer_data_m'[data_date] >= __PeriodMin,
            'a03_e2e_customer_data_m'[data_date] <= __PeriodMax
        )
    // sum(net_pay_order_cnt)（Step 1 集合 × Step 2 路由后 TimeFrame 区间）
    VAR __NetPayOrderCnt_Store =
        CALCULATE(
            SUM('a03_e2e_customer_data_m'[net_pay_order_cnt]),
            TREATAS(__AllUsers, 'a03_e2e_customer_data_m'[user_id]),
            'a03_e2e_customer_data_m'[is_member] = __IsMemberFilter,
            'a03_e2e_customer_data_m'[is_employee] in __IsEmployeeFilter,
            'a03_e2e_customer_data_m'[data_date] >= __PeriodMin,
            'a03_e2e_customer_data_m'[data_date] <= __PeriodMax
        )

    RETURN
        SWITCH(
            __MetricID,
            // ── SLS% 分母（全客 sum(net_pay_amt)）──
            // Metric_ID 4/5/6/26/27/28 均需全客 SLS 作为分母
            4,  __SLS_Store,
            5,  __SLS_Store,
            6,  __SLS_Store,
            26, __SLS_Store,
            27, __SLS_Store,
            28, __SLS_Store,
            // ── ACV vs Store 分母（全客 ACV）──
            10, DIVIDE(__SLS_Store, __UserCount_Store),
            32, DIVIDE(__SLS_Store, __UserCount_Store),
            // ── UPT vs Store 分母（全客 UPT）──
            14, DIVIDE(__NetPayQty_Store, __NetPayOrderCnt_Store),
            36, DIVIDE(__NetPayQty_Store, __NetPayOrderCnt_Store),
            // ── AUR vs Store 分母（全客 AUR）──
            18, DIVIDE(__SLS_Store, __NetPayQty_Store),
            40, DIVIDE(__SLS_Store, __NetPayQty_Store),
            // ── Freq. vs Store 分母（全客 Freq.）──
            22, DIVIDE(__NetPayOrderCnt_Store, __UserCount_Store),
            44, DIVIDE(__NetPayOrderCnt_Store, __UserCount_Store),
            BLANK()
        )

/* ── 旧逻辑：全客分母单步聚合（2026-09-12 弃用，保留备查）──
   演进一（最初版）: 聚合类与 user_id 计数统一按 Metric_ID 路由 Last_Fiscal_Month 区间
   （全客与分子同用 end period 当月区间，__UserCount_Store 与 __SLS_Store 同用 __PeriodMin/Max）。
   演进二（单步 TimeFrame 版）: 聚合类（SLS/qty/order_cnt）按 Metric_ID 路由 TimeFrame 区间直接聚合
   （is_xxx_vic IN {0,1} 施加于聚合本身，无 Step 1 框定）；__UserCount_Store 固定本期 end period 当月
   DISTINCTCOUNT。当时理解: 全客为全量口径无 Step 1 框定，时间口径按"与分子对齐"原则处理。
   2026-09-12 修订: 全客分母同样需要 Step1+Step2 分步——Step 1 在 end period 当月框定
   is_xxx_vic IN {0,1} 全客 user 集合（与 VIC 侧唯一区别是筛选条件），Step 2 在所选时间范围聚合；
   单步 TimeFrame 版的人群包含"TimeFrame 内活跃但 end period 当月不活跃"的人，与分子人群基准不一致。
   如需回退到演进二: 注释掉上方 Step1/Step2 分步实现（含 __AllUsers 与 TREATAS 块），
   将 __EndPeriodMin/__EndPeriodMax 改回固定本期（SELECTEDVALUE(...[Last_Fiscal_Month_Min/Max])），
   并恢复下方实现:

    // ── 演进二实现（单步 TimeFrame 版）──
    VAR __SLS_Store =
        DIVIDE(
            IF(
                __IsNewVIC,
                CALCULATE(
                    SUM('a03_e2e_customer_data_m'[net_pay_amt]),
                    'a03_e2e_customer_data_m'[is_new_vic] IN {0, 1},
                    'a03_e2e_customer_data_m'[is_member] = __IsMemberFilter,
                    'a03_e2e_customer_data_m'[is_employee] in __IsEmployeeFilter,
                    'a03_e2e_customer_data_m'[data_date] >= __PeriodMin,
                    'a03_e2e_customer_data_m'[data_date] <= __PeriodMax
                ),
                CALCULATE(
                    SUM('a03_e2e_customer_data_m'[net_pay_amt]),
                    'a03_e2e_customer_data_m'[is_retention_vic] IN {0, 1},
                    'a03_e2e_customer_data_m'[is_member] = __IsMemberFilter,
                    'a03_e2e_customer_data_m'[is_employee] in __IsEmployeeFilter,
                    'a03_e2e_customer_data_m'[data_date] >= __PeriodMin,
                    'a03_e2e_customer_data_m'[data_date] <= __PeriodMax
                )
            ),
            __FXRate
        )
    VAR __UserCount_Store =
        IF(
            __IsNewVIC,
            CALCULATE(
                DISTINCTCOUNT('a03_e2e_customer_data_m'[user_id]),
                'a03_e2e_customer_data_m'[is_new_vic] IN {0, 1},
                'a03_e2e_customer_data_m'[is_member] = __IsMemberFilter,
                'a03_e2e_customer_data_m'[is_employee] in __IsEmployeeFilter,
                'a03_e2e_customer_data_m'[data_date] >= __EndPeriodMin,
                'a03_e2e_customer_data_m'[data_date] <= __EndPeriodMax
            ),
            CALCULATE(
                DISTINCTCOUNT('a03_e2e_customer_data_m'[user_id]),
                'a03_e2e_customer_data_m'[is_retention_vic] IN {0, 1},
                'a03_e2e_customer_data_m'[is_member] = __IsMemberFilter,
                'a03_e2e_customer_data_m'[is_employee] in __IsEmployeeFilter,
                'a03_e2e_customer_data_m'[data_date] >= __EndPeriodMin,
                'a03_e2e_customer_data_m'[data_date] <= __EndPeriodMax
            )
        )
    VAR __NetPayQty_Store =
        IF(
            __IsNewVIC,
            CALCULATE(
                SUM('a03_e2e_customer_data_m'[net_pay_qty]),
                'a03_e2e_customer_data_m'[is_new_vic] IN {0, 1},
                'a03_e2e_customer_data_m'[is_member] = __IsMemberFilter,
                'a03_e2e_customer_data_m'[is_employee] in __IsEmployeeFilter,
                'a03_e2e_customer_data_m'[data_date] >= __PeriodMin,
                'a03_e2e_customer_data_m'[data_date] <= __PeriodMax
            ),
            CALCULATE(
                SUM('a03_e2e_customer_data_m'[net_pay_qty]),
                'a03_e2e_customer_data_m'[is_retention_vic] IN {0, 1},
                'a03_e2e_customer_data_m'[is_member] = __IsMemberFilter,
                'a03_e2e_customer_data_m'[is_employee] in __IsEmployeeFilter,
                'a03_e2e_customer_data_m'[data_date] >= __PeriodMin,
                'a03_e2e_customer_data_m'[data_date] <= __PeriodMax
            )
        )
    VAR __NetPayOrderCnt_Store =
        IF(
            __IsNewVIC,
            CALCULATE(
                SUM('a03_e2e_customer_data_m'[net_pay_order_cnt]),
                'a03_e2e_customer_data_m'[is_new_vic] IN {0, 1},
                'a03_e2e_customer_data_m'[is_member] = __IsMemberFilter,
                'a03_e2e_customer_data_m'[is_employee] in __IsEmployeeFilter,
                'a03_e2e_customer_data_m'[data_date] >= __PeriodMin,
                'a03_e2e_customer_data_m'[data_date] <= __PeriodMax
            ),
            CALCULATE(
                SUM('a03_e2e_customer_data_m'[net_pay_order_cnt]),
                'a03_e2e_customer_data_m'[is_retention_vic] IN {0, 1},
                'a03_e2e_customer_data_m'[is_member] = __IsMemberFilter,
                'a03_e2e_customer_data_m'[is_employee] in __IsEmployeeFilter,
                'a03_e2e_customer_data_m'[data_date] >= __PeriodMin,
                'a03_e2e_customer_data_m'[data_date] <= __PeriodMax
            )
        )
── 旧逻辑结束 ── */
```

### 4.6 VIC Breakdown Base Value（总路由）

```dax
VIC Breakdown Base Value = 
// ========================================
// 度量值: VIC Breakdown Base Value
// Display Folder: Base Metrics
// 用途: 总路由，根据 Metric_ID 分发到 Act / vs LY / vs LP / vs Store / SLS%
// 依赖: [VIC Breakdown Act Base Value], [VIC Breakdown LY Base Value],
//       [VIC Breakdown LP Base Value], [VIC Breakdown Store Base Value],
//       'Dim_ColMetric_New_Retention_VIC'[Metric_ID, ColType]
//
// Metric_ID 路由规则:
//   Act 基础指标 ID: 1, 7, 11, 15, 19, 23, 29, 33, 37, 41（SLS/ACV/UPT/AUR/Freq. × New/Retention）
//   SLS% Act: 4, 26（需全客分母）
//   数量类 vs LY: 2, 8, 12, 16, 20, 24, 30, 34, 38, 42
//   数量类 vs LP: 3, 9, 13, 17, 21, 25, 31, 35, 39, 43
//   vs Store: 10, 14, 18, 22, 32, 36, 40, 44
//   SLS% vs LY: 5, 27（比率类差值，×100 转 pts）
//   SLS% vs LP: 6, 28（比率类差值，×100 转 pts）
//
// 派生规则:
//   - 数量类 vs LY: Act / LY - 1
//   - 数量类 vs LP: Act / LP - 1
//   - vs Store: Act / Store - 1
//   - SLS% Act: DIVIDE(Act SLS, Store SLS)（分子 is_xxx_vic=1 分步，分母 is_xxx_vic in (0,1) 全客
//               同样 Step1+Step2 分步，唯一区别是 Step 1 筛选条件）
//   - SLS% vs LY: SLS%(Act) - SLS%(LY)（差值，×100 转 pts）
//   - SLS% vs LP: SLS%(Act) - SLS%(LP)（差值，×100 转 pts）
//
// REMOVEFILTERS 机制（参考 VIC_KPIs_Table.md）:
//   派生行需先 REMOVEFILTERS 清除断开维度的所有筛选，再应用目标 Metric_ID
// ========================================
    VAR __MetricID = SELECTEDVALUE('Dim_ColMetric_New_Retention_VIC'[Metric_ID])

    // ═══════════════════════════════════════
    // SLS% 计算（分子: is_xxx_vic=1 的 Step1+Step2 分步 SLS；分母: is_xxx_vic in (0,1) 的全客
    //          分步 SLS——Step1 end period 框定全客集合 + Step2 TimeFrame 区间聚合）
    // 关键修正: 不能再用 [Metric_ID]=4 + [ColType]="vs LP" 这种冲突筛选
    //          （维度表中 Metric_ID=4 的 ColType 恒为 "Act"，冲突筛选会导致 SELECTEDVALUE 返回 BLANK）
    // 正确做法: 按 VICType 映射到对应 SLS% Metric_ID（New VIC: 4/5/6, Retention VIC: 26/27/28），
    //          Store Base Value 内部会按 Metric_ID 自动推导时间区间，不再需要外层覆盖 ColType
    // ═══════════════════════════════════════
    VAR __IsSLSPct = __MetricID IN {4, 5, 6, 26, 27, 28}
    // SLS% 分子（is_xxx_vic=1）对应的 SLS Act Metric_ID
    VAR __SLSActMetricID =
        SWITCH(
            __MetricID,
            4, 1,    // SLS% Act (New VIC) → SLS Act (New VIC)
            5, 1,    // SLS% vs LY (New VIC) → SLS Act (New VIC)
            6, 1,    // SLS% vs LP (New VIC) → SLS Act (New VIC)
            26, 23,  // SLS% Act (Retention VIC) → SLS Act (Retention VIC)
            27, 23,  // SLS% vs LY (Retention VIC) → SLS Act (Retention VIC)
            28, 23   // SLS% vs LP (Retention VIC) → SLS Act (Retention VIC)
        )
    // SLS% 分母（全客 SLS）对应的各时间区间 Metric_ID
    // 关键: SLS% vs LY = SLS%(Act) - SLS%(LY)，分母 Act 部分用 Act 区间全客 SLS，分母 LY 部分用 LY 区间全客 SLS
    //       SLS% vs LP = SLS%(Act) - SLS%(LP)，分母 Act 部分用 Act 区间全客 SLS，分母 LP 部分用 LP 区间全客 SLS
    // 因此分母 Act 部分始终用 SLS% Act 的 Metric_ID（4/26），分母 LY/LP 部分用当前 Metric_ID（5/27 或 6/28）
    VAR __SLSPctActMetricID =  // SLS% Act 的 Metric_ID（用于分母 Act 部分调用 Store Base Value）
        IF(__MetricID IN {4, 5, 6}, 4, 26)
    // Store Base Value 内部按 Metric_ID 推导两套时间区间（Step 1 end period + Step 2 TimeFrame 同步路由）：
    //   4/26 → Act 两套区间；5/27 → LY 两套区间；6/28 → LP 两套区间

    // SLS% 分子（is_xxx_vic=1 的 SLS，Act/LY/LP 区间由各自 Base Value 度量值内部处理）
    VAR __SLSNumeratorAct =
        IF(
            __IsSLSPct,
            CALCULATE(
                [VIC Breakdown Act Base Value],
                REMOVEFILTERS('Dim_ColMetric_New_Retention_VIC'),
                'Dim_ColMetric_New_Retention_VIC'[Metric_ID] = __SLSActMetricID
            )
        )
    VAR __SLSNumeratorLY =
        IF(
            __MetricID IN {5, 27},
            CALCULATE(
                [VIC Breakdown LY Base Value],
                REMOVEFILTERS('Dim_ColMetric_New_Retention_VIC'),
                'Dim_ColMetric_New_Retention_VIC'[Metric_ID] = __SLSActMetricID
            )
        )
    VAR __SLSNumeratorLP =
        IF(
            __MetricID IN {6, 28},
            CALCULATE(
                [VIC Breakdown LP Base Value],
                REMOVEFILTERS('Dim_ColMetric_New_Retention_VIC'),
                'Dim_ColMetric_New_Retention_VIC'[Metric_ID] = __SLSActMetricID
            )
        )

    // SLS% 分母（全客分步 SLS，通过 Store Base Value 获取）
    // 分母 Act 部分始终用 SLS% Act 的 Metric_ID（4/26）→ Store Base Value 两套区间路由到 Act
    // 分母 LY 部分用当前 Metric_ID（5/27）→ Store Base Value 两套区间路由到 LY
    // 分母 LP 部分用当前 Metric_ID（6/28）→ Store Base Value 两套区间路由到 LP
    VAR __SLSDenominatorAct =
        IF(
            __IsSLSPct,
            CALCULATE(
                [VIC Breakdown Store Base Value],
                REMOVEFILTERS('Dim_ColMetric_New_Retention_VIC'),
                'Dim_ColMetric_New_Retention_VIC'[Metric_ID] = __SLSPctActMetricID  // 4/26 → Act 区间
            )
        )
    VAR __SLSDenominatorLY =
        IF(
            __MetricID IN {5, 27},
            CALCULATE(
                [VIC Breakdown Store Base Value],
                REMOVEFILTERS('Dim_ColMetric_New_Retention_VIC'),
                'Dim_ColMetric_New_Retention_VIC'[Metric_ID] = __MetricID  // 5/27 → LY 区间
            )
        )
    VAR __SLSDenominatorLP =
        IF(
            __MetricID IN {6, 28},
            CALCULATE(
                [VIC Breakdown Store Base Value],
                REMOVEFILTERS('Dim_ColMetric_New_Retention_VIC'),
                'Dim_ColMetric_New_Retention_VIC'[Metric_ID] = __MetricID  // 6/28 → LP 区间
            )
        )

    // SLS% Act / vs LY / vs LP
    VAR __SLSPctAct =
        IF(
            __MetricID IN {4, 26},
            DIVIDE(__SLSNumeratorAct, __SLSDenominatorAct)
        )
    VAR __SLSPctVsLYResult =
        IF(
            __MetricID IN {5, 27},
            DIVIDE(__SLSNumeratorAct, __SLSDenominatorAct)
            - DIVIDE(__SLSNumeratorLY, __SLSDenominatorLY)
        )
    VAR __SLSPctVsLPResult =
        IF(
            __MetricID IN {6, 28},
            DIVIDE(__SLSNumeratorAct, __SLSDenominatorAct)
            - DIVIDE(__SLSNumeratorLP, __SLSDenominatorLP)
        )

    // ═══════════════════════════════════════
    // 数量类 vs LY（分子: Act，分母: LY）
    // SLS vs LY: Metric_ID=2/24，Act→1/23，LY→1/23
    // ACV vs LY: Metric_ID=8/30，Act→7/29，LY→7/29
    // UPT vs LY: Metric_ID=12/34，Act→11/33，LY→11/33
    // AUR vs LY: Metric_ID=16/38，Act→15/37，LY→15/37
    // Freq. vs LY: Metric_ID=20/42，Act→19/41，LY→19/41
    // ═══════════════════════════════════════
    VAR __IsQtyVsLY = __MetricID IN {2, 8, 12, 16, 20, 24, 30, 34, 38, 42}
    VAR __QtyActMetricID_LY =
        SWITCH(__MetricID,
            2, 1,    8, 7,    12, 11,    16, 15,    20, 19,
            24, 23,  30, 29,  34, 33,    38, 37,    42, 41
        )
    VAR __QtyActValue_LY =
        IF(
            __IsQtyVsLY,
            CALCULATE(
                [VIC Breakdown Act Base Value],
                REMOVEFILTERS('Dim_ColMetric_New_Retention_VIC'),
                'Dim_ColMetric_New_Retention_VIC'[Metric_ID] = __QtyActMetricID_LY
            )
        )
    VAR __QtyLYValue =
        IF(
            __IsQtyVsLY,
            CALCULATE(
                [VIC Breakdown LY Base Value],
                REMOVEFILTERS('Dim_ColMetric_New_Retention_VIC'),
                'Dim_ColMetric_New_Retention_VIC'[Metric_ID] = __QtyActMetricID_LY
            )
        )
    VAR __QtyVsLYResult =
        IF(
            ISBLANK(__QtyLYValue) || __QtyLYValue = 0,
            BLANK(),
            DIVIDE(__QtyActValue_LY, __QtyLYValue) - 1
        )

    // ═══════════════════════════════════════
    // 数量类 vs LP（分子: Act，分母: LP）
    // SLS vs LP: Metric_ID=3/25，Act→1/23
    // ACV vs LP: Metric_ID=9/31，Act→7/29
    // UPT vs LP: Metric_ID=13/35，Act→11/33
    // AUR vs LP: Metric_ID=17/39，Act→15/37
    // Freq. vs LP: Metric_ID=21/43，Act→19/41
    // ═══════════════════════════════════════
    VAR __IsQtyVsLP = __MetricID IN {3, 9, 13, 17, 21, 25, 31, 35, 39, 43}
    VAR __QtyActMetricID_LP =
        SWITCH(__MetricID,
            3, 1,    9, 7,    13, 11,    17, 15,    21, 19,
            25, 23,  31, 29,  35, 33,    39, 37,    43, 41
        )
    VAR __QtyActValue_LP =
        IF(
            __IsQtyVsLP,
            CALCULATE(
                [VIC Breakdown Act Base Value],
                REMOVEFILTERS('Dim_ColMetric_New_Retention_VIC'),
                'Dim_ColMetric_New_Retention_VIC'[Metric_ID] = __QtyActMetricID_LP
            )
        )
    VAR __QtyLPValue =
        IF(
            __IsQtyVsLP,
            CALCULATE(
                [VIC Breakdown LP Base Value],
                REMOVEFILTERS('Dim_ColMetric_New_Retention_VIC'),
                'Dim_ColMetric_New_Retention_VIC'[Metric_ID] = __QtyActMetricID_LP
            )
        )
    VAR __QtyVsLPResult =
        IF(
            ISBLANK(__QtyLPValue) || __QtyLPValue = 0,
            BLANK(),
            DIVIDE(__QtyActValue_LP, __QtyLPValue) - 1
        )

    // ═══════════════════════════════════════
    // vs Store（分子: Act，分母: Store 全客）
    // ACV vs Store: Metric_ID=10/32，Act→7/29，Store→10/32
    // UPT vs Store: Metric_ID=14/36，Act→11/33，Store→14/36
    // AUR vs Store: Metric_ID=18/40，Act→15/37，Store→18/40
    // Freq. vs Store: Metric_ID=22/44，Act→19/41，Store→22/44
    // ═══════════════════════════════════════
    VAR __IsVsStore = __MetricID IN {10, 14, 18, 22, 32, 36, 40, 44}
    VAR __StoreActMetricID =
        SWITCH(__MetricID,
            10, 7,    14, 11,    18, 15,    22, 19,
            32, 29,   36, 33,    40, 37,    44, 41
        )
    VAR __StoreNumeratorAct =
        IF(
            __IsVsStore,
            CALCULATE(
                [VIC Breakdown Act Base Value],
                REMOVEFILTERS('Dim_ColMetric_New_Retention_VIC'),
                'Dim_ColMetric_New_Retention_VIC'[Metric_ID] = __StoreActMetricID
            )
        )
    VAR __StoreDenominator =
        IF(
            __IsVsStore,
            CALCULATE(
                [VIC Breakdown Store Base Value],
                REMOVEFILTERS('Dim_ColMetric_New_Retention_VIC'),
                'Dim_ColMetric_New_Retention_VIC'[Metric_ID] = __MetricID  // 10/14/18/22/32/36/40/44 → Act 区间
            )
        )
    VAR __VsStoreResult =
        IF(
            ISBLANK(__StoreDenominator) || __StoreDenominator = 0,
            BLANK(),
            DIVIDE(__StoreNumeratorAct, __StoreDenominator) - 1
        )

    RETURN
        SWITCH(
            __MetricID,
            // ─── Act 本期值 ───
            1,  [VIC Breakdown Act Base Value],      // SLS Act (New VIC)
            23, [VIC Breakdown Act Base Value],      // SLS Act (Retention VIC)
            7,  [VIC Breakdown Act Base Value],      // ACV Act (New VIC)
            29, [VIC Breakdown Act Base Value],      // ACV Act (Retention VIC)
            11, [VIC Breakdown Act Base Value],      // UPT Act (New VIC)
            33, [VIC Breakdown Act Base Value],      // UPT Act (Retention VIC)
            15, [VIC Breakdown Act Base Value],      // AUR Act (New VIC)
            37, [VIC Breakdown Act Base Value],      // AUR Act (Retention VIC)
            19, [VIC Breakdown Act Base Value],      // Freq. Act (New VIC)
            41, [VIC Breakdown Act Base Value],      // Freq. Act (Retention VIC)
            // ─── SLS% Act（分子 is_xxx_vic=1，分母 is_xxx_vic in (0,1)）───
            4,  __SLSPctAct,                          // SLS% Act (New VIC)
            26, __SLSPctAct,                          // SLS% Act (Retention VIC)
            // ─── 数量类 vs LY 派生（今年 / 去年 - 1）───
            2,  __QtyVsLYResult,                      // SLS vs LY (New VIC)
            8,  __QtyVsLYResult,                      // ACV vs LY (New VIC)
            12, __QtyVsLYResult,                      // UPT vs LY (New VIC)
            16, __QtyVsLYResult,                      // AUR vs LY (New VIC)
            20, __QtyVsLYResult,                      // Freq. vs LY (New VIC)
            24, __QtyVsLYResult,                      // SLS vs LY (Retention VIC)
            30, __QtyVsLYResult,                      // ACV vs LY (Retention VIC)
            34, __QtyVsLYResult,                      // UPT vs LY (Retention VIC)
            38, __QtyVsLYResult,                      // AUR vs LY (Retention VIC)
            42, __QtyVsLYResult,                      // Freq. vs LY (Retention VIC)
            // ─── 数量类 vs LP 派生（当期 / 上期 - 1）───
            3,  __QtyVsLPResult,                      // SLS vs LP (New VIC)
            9,  __QtyVsLPResult,                      // ACV vs LP (New VIC)
            13, __QtyVsLPResult,                      // UPT vs LP (New VIC)
            17, __QtyVsLPResult,                      // AUR vs LP (New VIC)
            21, __QtyVsLPResult,                      // Freq. vs LP (New VIC)
            25, __QtyVsLPResult,                      // SLS vs LP (Retention VIC)
            31, __QtyVsLPResult,                      // ACV vs LP (Retention VIC)
            35, __QtyVsLPResult,                      // UPT vs LP (Retention VIC)
            39, __QtyVsLPResult,                      // AUR vs LP (Retention VIC)
            43, __QtyVsLPResult,                      // Freq. vs LP (Retention VIC)
            // ─── vs Store 派生（New VIC / 全客 - 1）───
            10, __VsStoreResult,                      // ACV vs Store (New VIC)
            14, __VsStoreResult,                      // UPT vs Store (New VIC)
            18, __VsStoreResult,                      // AUR vs Store (New VIC)
            22, __VsStoreResult,                      // Freq. vs Store (New VIC)
            32, __VsStoreResult,                      // ACV vs Store (Retention VIC)
            36, __VsStoreResult,                      // UPT vs Store (Retention VIC)
            40, __VsStoreResult,                      // AUR vs Store (Retention VIC)
            44, __VsStoreResult,                      // Freq. vs Store (Retention VIC)
            // ─── SLS% vs LY / vs LP 派生（比率差值，×100 转 pts）───
            5,  __SLSPctVsLYResult,                   // SLS% vs LY (New VIC)
            6,  __SLSPctVsLPResult,                   // SLS% vs LP (New VIC)
            27, __SLSPctVsLYResult,                   // SLS% vs LY (Retention VIC)
            28, __SLSPctVsLPResult,                   // SLS% vs LP (Retention VIC)
            BLANK()
        )
```

### 4.7 VIC Breakdown Cell Value（对外值）

```dax
VIC Breakdown Cell Value = 
// ========================================
// 度量值: VIC Breakdown Cell Value
// Display Folder: Cell Values
// 用途: 对外暴露的单元格值，等于 Base Value
// 依赖: [VIC Breakdown Base Value]
// ========================================
    [VIC Breakdown Base Value]
```

### 4.8 VIC Breakdown Cell Display（格式化显示，按 Metric_Format 单字段分发）

```dax
VIC Breakdown Cell Display = 
// ========================================
// 度量值: VIC Breakdown Cell Display
// Display Folder: Formatting
// 用途: 按 Metric_Format 单字段格式化显示
// 依赖: [VIC Breakdown Cell Value],
//       'Dim_ColMetric_New_Retention_VIC'[Metric_Format],
//       Slicer_Currency_Selection[Currency_Symbol]
// 格式类型（严格遵循口径文档数据类型定义，以 Dim_ColMetric_New_Retention_VIC 为准）:
//   integer               → 整数千分位：1,000
//   decimal_1dp           → 小数一位小数千分位：1.5（UPT / Freq.）
//   decimal_2dp           → 小数两位小数千分位：1,000.00
//   currency              → 货币符号 + 整数千分位：¥1,000 / $1,000（SLS）
//   currency_decimal_1dp  → 货币符号 + 一位小数千分位：¥1,000.0 / $1,000.0（ACV / AUR）
//   currency_k            → 货币符号 + 千位缩写：¥1k / $5k
//   percent_0dp           → 百分比整数，不含正号：15%（SLS%）
//   percent_1dp           → 百分比一位小数：40.5%
//   percent_2dp           → 百分比两位小数：40.50%
//   delta_pct_0dp         → 百分比整数变化，含正号：+15% / -3%（vs LY / vs LP / vs Store）
//   delta_pct_1dp         → 百分比一位小数变化，含正号：+14.5% / -3.2%
//   delta_pct_2dp         → 百分比两位小数变化，含正号：+14.50%
//   delta_pts             → 增减基点整数（小数×100 转 pts）：+120pts / -80pts / 0pts
//   delta_bp              → 增减基点整数（小数×10000 转 bp）：+120bp / -80bp
//   delta_bp_1dp          → 增减基点一位小数（值本身已是基点）：+120.5bp / -80.0bp
// 说明:
//   - BLANK 显示为 "-"
//   - 货币符号由 Slicer_Currency_Selection[Currency_Symbol] 决定（默认 "¥"）
// ========================================
    VAR __Value = [VIC Breakdown Cell Value]
    VAR __Format = SELECTEDVALUE('Dim_ColMetric_New_Retention_VIC'[Metric_Format])
    VAR __CurrencySymbol = SELECTEDVALUE(Slicer_Currency_Selection[Currency_Symbol], "¥")

    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            SWITCH(
                __Format,

                // ─── 1. 整数与小数 ──────────────────────────────────────────
                "integer",
                    FORMAT(__Value, "#,##0"),                                    // 1,000

                "decimal_1dp",
                    FORMAT(__Value, "#,##0.0"),                                  // 1.5

                "decimal_2dp",
                    FORMAT(__Value, "#,##0.00"),                                 // 1,000.00

                // ─── 2. 货币格式 ────────────────────────────────────────────
                "currency",
                    __CurrencySymbol & FORMAT(__Value, "#,##0"),                 // ¥1,000 / $1,000

                "currency_decimal_1dp",
                    __CurrencySymbol & FORMAT(__Value, "#,##0.0"),               // ¥1,000.0 / $1,000.0

                "currency_k",
                    __CurrencySymbol & FORMAT(__Value / 1000, "#,##0") & "k",    // ¥1k / $5k

                // ─── 3. 百分比格式（纯显示，不含正负号）───────────────────────
                "percent_0dp",
                    FORMAT(__Value, "#,##0%"),                                   // 15%

                "percent_1dp",
                    FORMAT(__Value, "0.0%"),                                     // 40.5%

                "percent_2dp",
                    FORMAT(__Value, "0.00%"),                                    // 40.50%

                // ─── 4. 增减百分比（Delta %，自动添加正负号）────────────────
                "delta_pct_0dp",
                    IF(__Value > 0, "+", "") & FORMAT(__Value, "#,##0%"),        // +15% / -3%

                "delta_pct_1dp",
                    IF(__Value > 0, "+", "") & FORMAT(__Value, "0.0%"),          // +14.5% / -3.2%

                "delta_pct_2dp",
                    IF(__Value > 0, "+", "") & FORMAT(__Value, "0.00%"),         // +14.50%

                // ─── 5. 增减基点 ───────────────────────────────────────────
                // 5.1 __Value 为小数，需 ×100 转换为 pts（整数）
                "delta_pts",
                    IF(ROUND(__Value * 100, 0) > 0, "+", "") & FORMAT(__Value * 100, "#,##0pts;-#,##0pts;0pts"),
                                                                                 // +120pts / -80pts / 0pts

                // 5.2 __Value 为小数，需 ×10000 转换为 bp（整数）
                "delta_bp",
                    IF(__Value > 0, "+", "") & FORMAT(__Value * 10000, "#,##0") & "bp",
                                                                                 // +120bp / -80bp

                // 5.3 __Value 本身已是基点值，保留 1 位小数
                "delta_bp_1dp",
                    IF(__Value > 0, "+", "") & FORMAT(__Value, "#,##0.0") & "bp",// +120.5bp / -80.0bp

                // ─── 默认 ───────────────────────────────────────────────────
                FORMAT(__Value, "#,##0.00")
            )
        )
```

### 4.9 VIC Breakdown Cell Font Color（字体颜色，按 Metric_ColorRule 分发）

```dax
VIC Breakdown Cell Font Color = 
// ========================================
// 度量值: VIC Breakdown Cell Font Color
// Display Folder: Formatting
// 用途: 按 Metric_ColorRule 字段分发字体颜色
// 依赖: [VIC Breakdown Cell Value],
//       'Dim_ColMetric_New_Retention_VIC'[Metric_ColorRule, Metric_ColorPositive/Negative/Zero/Default]
//
// 颜色规则（口径文档要求）:
//   1. Act 列固定 #252423（主指标 Act 类型）
//      → Metric_ColorRule = "fixed_black"
//   2. vs LY / vs LP / vs Store 使用列维度表的颜色取值字段判断大小（正/负/零三色）
//      → Metric_ColorRule = "pos_neg_zero"
// ========================================
    VAR __Value = [VIC Breakdown Cell Value]
    VAR __ColorRule = SELECTEDVALUE('Dim_ColMetric_New_Retention_VIC'[Metric_ColorRule], "fixed_black")
    // ── 颜色取值（来自列维度表）──
    VAR __ColorPositive = SELECTEDVALUE('Dim_ColMetric_New_Retention_VIC'[Metric_ColorPositive], "#1A9018")
    VAR __ColorNegative = SELECTEDVALUE('Dim_ColMetric_New_Retention_VIC'[Metric_ColorNegative], "#D64550")
    VAR __ColorZero = SELECTEDVALUE('Dim_ColMetric_New_Retention_VIC'[Metric_ColorZero], "#E1C233")
    VAR __ColorDefault = SELECTEDVALUE('Dim_ColMetric_New_Retention_VIC'[Metric_ColorDefault], "#5F6165")

    RETURN
        SWITCH(
            __ColorRule,
            // ─── 固定黑色（Act 列）───
            "fixed_black",
                "#252423",
            // ─── 正/负/零三色（vs LY / vs LP / vs Store）───
            "pos_neg_zero",
                SWITCH(
                    TRUE(),
                    ISBLANK(__Value), __ColorDefault,
                    __Value > 0,      __ColorPositive,
                    __Value < 0,      __ColorNegative,
                    __Value = 0,      __ColorZero,
                    __ColorDefault
                ),
            // ─── 兜底 ───
            __ColorDefault
        )
```

### 4.10 VIC Breakdown Cell Background Color（背景色）

```dax
VIC Breakdown Cell Background Color = 
// ========================================
// 度量值: VIC Breakdown Cell Background Color
// Display Folder: Formatting
// 用途: 区分 VICType / KPIGroup / ColName 层级行的背景色
// 依赖: ISINSCOPE('Dim_ColMetric_New_Retention_VIC'[ColName]),
//       ISINSCOPE('Dim_ColMetric_New_Retention_VIC'[KPIGroup])
// 颜色规则:
//   ColName 行（具体指标行）   : #FFFFFF（白色）
//   KPIGroup 行（KPI 分组标题）: #F0E6D2（浅米色）
//   VICType 行（大分组标题）   : #E6D9C7（中米色）
// ========================================
    VAR __IsColNameRow = ISINSCOPE('Dim_ColMetric_New_Retention_VIC'[ColName])
    VAR __IsKPIGroupRow = ISINSCOPE('Dim_ColMetric_New_Retention_VIC'[KPIGroup])
    RETURN
        IF(
            __IsColNameRow,
            "#FFFFFF",   // ColName 行：白色
            IF(
                __IsKPIGroupRow,
                "#F0E6D2",  // KPIGroup 行：浅米色
                "#E6D9C7"   // VICType 行：中米色
            )
        )
```

---

## 5. 度量值清单与 Display Folder

| 序号 | 度量值名称                            | Display Folder | 用途                                                                                                                   |
| ---- | ------------------------------------- | -------------- | ---------------------------------------------------------------------------------------------------------------------- |
| 1    | VIC Breakdown Act Base Value          | Base Metrics   | 本期基础值（Step1 end period 当月 UNION+FILTER 框定 is_xxx_vic=1 user_id + Step2 TREATAS + TimeFrame 区间聚合；ACV/Freq. 分母 = COUNTROWS(Step1 集合)） |
| 2    | VIC Breakdown LY Base Value           | Base Metrics   | 去年同期基础值（Step1: Last_Fiscal_Month_*_LY；Step2: TimeFrame_Min/Max_LY，分步同 Act）                              |
| 3    | VIC Breakdown LP Base Value           | Base Metrics   | 上期基础值（Step1: Last_Fiscal_Month_*_LP；Step2: TimeFrame_Min/Max_LP，分步同 Act）                                  |
| 4    | VIC Breakdown Store Base Value        | Base Metrics   | 全客基础值（is_xxx_vic in (0,1)，同样 Step1+Step2 分步：Step1 end period 当月框定全客集合 + Step2 TimeFrame 区间 TREATAS 聚合，两套区间按 Metric_ID 同步路由）；用于 vs Store 分母和 SLS% 分母 |
| 5    | VIC Breakdown Base Value              | Base Metrics   | 总路由（含 vs LY / vs LP / vs Store / SLS% 派生 + REMOVEFILTERS）                                                      |
| 6    | VIC Breakdown Cell Value              | Cell Values    | 对外值 = Base Value                                                                                                    |
| 7    | VIC Breakdown Cell Display            | Formatting     | 格式化显示文本（按 Metric_Format 单字段分发，货币符号由 Slicer_Currency_Selection 决定）                              |
| 8    | VIC Breakdown Cell Font Color         | Formatting     | 字体颜色（按 Metric_ColorRule 分发：fixed_black / pos_neg_zero）                                                       |
| 9    | VIC Breakdown Cell Background Color   | Formatting     | 背景色（VICType / KPIGroup / ColName 三级层级区分）                                                                    |

---

## 6. 血缘关系图

```
┌─────────────────────────────────────────────────────────────────────┐
│                        数据源层                                      │
│  a03_e2e_customer_data_m（月度事实表）                               │
│  字段: data_date, platform, shop_info_id, user_id, is_member,       │
│        is_employee, is_new_vic, is_retention_vic,                   │
│        net_pay_amt, net_pay_qty, net_pay_order_cnt                  │
└──────────────────────────────┬──────────────────────────────────────┘
                               │
                               │ 模型自动传递（行维度 = 事实表字段直接拉取）
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────────┐
│                        度量值层                                      │
│                                                                     │
│  ┌───────────────────────┐   ┌───────────────────────┐              │
│  │ VIC Breakdown         │   │ VIC Breakdown         │              │
│  │ Act Base Value        │   │ LY Base Value         │              │
│  │ (Step1 end period 当月 │   │ (Step1: Last_Fiscal_  │              │
│  │  + Step2 TimeFrame)   │   │  Month_*_LY;          │              │
│  │                       │   │  Step2: TimeFrame_*_LY)│              │
│  └───────────┬───────────┘   └───────────┬───────────┘              │
│              │                           │                          │
│  ┌───────────────────────┐               │                          │
│  │ VIC Breakdown         │               │                          │
│  │ LP Base Value         │               │                          │
│  │ (Step1: Last_Fiscal_  │               │                          │
│  │  Month_*_LP;          │               │                          │
│  │  Step2: TimeFrame_*_LP)│               │                          │
│  └───────────┬───────────┘               │                          │
│              │                            │                          │
│  ┌───────────────────────┐               │                          │
│  │ VIC Breakdown         │               │                          │
│  │ Store Base Value      │               │                          │
│  │ (全客 is_xxx_vic      │               │                          │
│  │  in (0,1), 同样 Step1 │               │                          │
│  │  +Step2 分步, 两套区间│               │                          │
│  │  按 Metric_ID 路由)   │               │                          │
│  └───────────┬───────────┘               │                          │
│              │                            │                          │
│              ▼                            ▼                          │
│  ┌───────────────────────────────────┐   ┌───────────────────────┐  │
│  │ VIC Breakdown Base Value          │   │ Dim_ColMetric_New_    │  │
│  │ (总路由 + 派生计算)                │   │ Retention_VIC         │  │
│  │ REMOVEFILTERS + 目标 Metric_ID     │   │ (断开维度, Metric_ID, │  │
│  │ vs LY / vs LP / vs Store / SLS%   │   │  VICType, ColType)    │  │
│  └───────────────┬───────────────────┘   └───────────────────────┘  │
│                  │                                                  │
│                  ▼                                                  │
│  ┌───────────────────────────────────┐                              │
│  │ VIC Breakdown Cell Value          │                              │
│  │ (= Base Value)                    │                              │
│  └───────────────┬───────────────────┘                              │
│                  │                                                  │
│                  ▼                                                  │
│  ┌───────────────────────────────────┐   ┌───────────────────────┐  │
│  │ VIC Breakdown Cell Display        │◄──│ Slicer_Currency_      │  │
│  │ (按 Metric_Format 单字段格式化,   │   │ Selection             │  │
│  │  货币符号拼接)                    │   │ (Currency_Symbol,     │  │
│  └───────────────┬───────────────────┘   │  Currency_ExchangeRate)│  │
│                  │                       └───────────────────────┘  │
│                  ▼                                                  │
│  ┌─────────────────────────────────────────────────────┐            │
│  │  VIC Breakdown Cell Font Color                      │            │
│  │  VIC Breakdown Cell Background Color                │            │
│  │  (条件格式度量值，按 Metric_ColorRule 调度颜色)      │            │
│  └─────────────────────────────────────────────────────┘            │
└─────────────────────────────────────────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────────┐
│                        可视化层                                      │
│  Matrix 视觉对象                                                     │
│  行: 事实表字段（platform / shop_info_id，直接拉取）                  │
│  列: 'Dim_ColMetric_New_Retention_VIC'[VICType]                      │
│      > [KPIGroup] > [ColName]                                        │
│  值: [VIC Breakdown Cell Display]                                    │
│  条件格式:                                                           │
│    字体颜色 → [VIC Breakdown Cell Font Color]                        │
│    背景色   → [VIC Breakdown Cell Background Color]                  │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 7. 注意事项

1. **VIC Breakdown 专用日期表（关键逻辑）**：VIC Breakdown 使用专用日期表 `Slicer_Time_Frame_VIC_Breakdown` / `Slicer_Time_Frame_Max_VIC_Breakdown` / `Slicer_Time_Frame_Min_VIC_Breakdown`，与其他 VIC 模块的日期表隔离，避免切片器互相干扰。字段结构与原日期表完全一致，均内置 `Last_Fiscal_Month` 及 7 个时间字段。

2. **两套时间区间（关键逻辑，2026-09-12 修订）**：Step 1（end period 当月框定 VIC 买家）使用 `Last_Fiscal_Month_Min` ~ `Last_Fiscal_Month_Max`；Step 2（所选时间范围聚合）使用 `TimeFrame_Min` ~ `TimeFrame_Max`；LY/LP 版本对应使用 `_LY/_LP` 偏移字段（`Last_Fiscal_Month_*_LY/LP`、`TimeFrame_Min/Max_LY/LP`）。两套区间均从 Slicer_Time_Frame_Max_VIC_Breakdown 读取（日期表不改动，防止日期表互相依赖；Slicer_Time_Frame_Min_VIC_Breakdown 本方案不使用），且两步时间范围不同，不能合并区间计算。这些字段已由日期维度表通过自关联计算得到，无需在 DAX 中重复实现。

3. **is_member / is_employee 双重筛选（关键逻辑）**：所有指标均应用 `is_member = SELECTEDVALUE(IsMemberFilter[IsMember], 0)` 和 `is_employee = VALUES(Slicer_Is_Employee_Selection[IsEmployee_Code])` 筛选。默认值：is_member=0（TTL VIC），is_employee=1（Yes）。

4. **New VIC / Retention VIC 双大分组（关键逻辑）**：两个大分组指标完全对称，唯一区别是筛选字段：
   - New VIC（Metric_ID 1-22）：Step1 筛选 `is_new_vic = 1`
   - Retention VIC（Metric_ID 23-44）：Step1 筛选 `is_retention_vic = 1`
   - 实现方式（Step 1 集合框定）：在度量值中通过 `SELECTEDVALUE('Dim_ColMetric_New_Retention_VIC'[VICType])` 判断 VICType 得到 `__IsNewVIC` 常量，再用 `UNION(FILTER(CALCULATETABLE(VALUES(user_id), is_new_vic=1, ...), __IsNewVIC), FILTER(CALCULATETABLE(VALUES(user_id), is_retention_vic=1, ...), NOT __IsNewVIC))` 按常量分支框定目标集合——避免 IF 返回表被降级为标量（分步范式参考用户已验证的"新客"DAX，即 Customer Breakdown Trend 的 TREATAS 模式）。Step 2 用 `TREATAS(__VICUsers, 'a03_e2e_customer_data_m'[user_id])` 传递集合聚合，`is_xxx_vic=1` 不再施加。

5. **货币转换（关键逻辑）**：
   - 金额类（SLS / ACV / AUR 分子）÷ `Slicer_Currency_Selection[Currency_ExchangeRate]`（默认 1=RMB，7=USD）
   - 比率类不除（分子分母同币种抵消）
   - SLS% 占比不除（分子分母同除 FXRate 等价于不除）
   - Display 度量值中 `__CurrencySymbol & FORMAT(__Value, "#,##0")` 拼接货币符号（默认 "¥"）

6. **vs Store 全客对比（关键逻辑，2026-09-12 修订：分母同样分步）**：
   - 分子：New VIC 或 Retention VIC 的 Act 值（`is_xxx_vic=1`，Step1+Step2 分步）
   - 分母：全客值（`is_xxx_vic in (0, 1)`，同样 Step1+Step2 分步）——Step 1 在 end period 当月（按 Metric_ID 路由 Act/LY/LP）框定全客 user_id 集合（UNION+FILTER，is_xxx_vic IN {0,1}），Step 2 在所选时间范围（按 Metric_ID 路由 TimeFrame 区间）TREATAS 聚合；__UserCount_Store = COUNTROWS(Step 1 集合)。全客与 VIC 侧唯一区别是 Step 1 的筛选条件——单步 TimeFrame 聚合的人群包含"TimeFrame 内活跃但 end period 当月不活跃"的人，与分子人群基准不一致，故分母分步
   - 计算方式：`分子 / 分母 - 1`
   - vs Store 仅 ACV / UPT / AUR / Freq. 四个 KPI 分组有（SLS / SLS% 无 vs Store）
   - 实现方式：Step 1 集合框定用 `UNION(FILTER(CALCULATETABLE(VALUES(user_id), is_xxx_vic IN {0,1}, ...), __IsNewVIC), FILTER(..., NOT __IsNewVIC))`（IF 返回表会降级为标量）；Step 2 用 `TREATAS(__AllUsers, 'a03_e2e_customer_data_m'[user_id])` 传递集合聚合，`is_xxx_vic IN {0,1}` 不再施加。

7. **REMOVEFILTERS 机制**：派生指标（vs LY / vs LP / vs Store / SLS% / SLS% vs LY / SLS% vs LP）的取值必须先 `REMOVEFILTERS('Dim_ColMetric_New_Retention_VIC')` 再应用目标 Metric_ID，否则矩阵行标题保留的筛选器会导致冲突返回 BLANK。这与 VIC_KPIs_Table.md 的总路由范式完全一致。

8. **SLS% 计算的特殊处理**：SLS% 的分母为全客分步 SLS（Step1 end period 当月框定 `is_xxx_vic in (0,1)` 全客集合 + Step2 TimeFrame 区间 `sum(net_pay_amt)`），通过 `[VIC Breakdown Store Base Value]` 获取；分子为 Step1+Step2 分步 SLS（is_xxx_vic=1，见 §1.2）。SLS% vs LY / vs LP 的分母需要对应时间区间的全客分步 SLS（Store Base Value 内部两套区间按 Metric_ID 同步路由）：
   - **分母 Act 部分**：用 SLS% Act 的 Metric_ID（4/26）调用 Store Base Value → Store Base Value 内部 4/26 ∉ {5,27,6,28} → 本期 end period 当月 + Act TimeFrame 区间
   - **分母 LY 部分**：用当前 Metric_ID（5/27）调用 Store Base Value → Store Base Value 内部 5/27 ∈ {5,27} → LY end period 当月 + LY TimeFrame 区间
   - **分母 LP 部分**：用当前 Metric_ID（6/28）调用 Store Base Value → Store Base Value 内部 6/28 ∈ {6,28} → LP end period 当月 + LP TimeFrame 区间
   - **关键修正**：不能用 `[Metric_ID]=4, [ColType]="vs LP"` 这种冲突筛选（维度表中 Metric_ID=4 的 ColType 恒为 "Act"，不存在同时满足两个条件的行，SELECTEDVALUE 返回 BLANK）。Store Base Value 内部直接按 Metric_ID 推导两套时间区间，不读 ColType。

9. **Metric_ID 编码规则**：
   - New VIC 分组：1-22（SLS 1-3 / SLS% 4-6 / ACV 7-10 / UPT 11-14 / AUR 15-18 / Freq. 19-22）
   - Retention VIC 分组：23-44（SLS 23-25 / SLS% 26-28 / ACV 29-32 / UPT 33-36 / AUR 37-40 / Freq. 41-44）
   - 每大分组 22 列，共 44 列指标

10. **颜色规则二值标识**：通过 `Metric_ColorRule` 字段二值（`fixed_black` / `pos_neg_zero`）统一调度字体颜色：
    - `fixed_black` → 所有 Act 列（SLS / SLS% / ACV / UPT / AUR / Freq. 的 Act）
    - `pos_neg_zero` → 所有 vs LY / vs LP / vs Store 派生指标

11. **行维度处理**：无行维度表，直接拉取事实表字段（`platform` / `shop_info_id`），天然形成筛选与分组，DAX 度量值无需显式处理。模型自动传递筛选，支持 platform 粒度行展开看 shop_info_id 粒度明细数据。**Step 2 不移除任何分组维度筛选**——若在 Step 2 的 CALCULATE 中加 REMOVEFILTERS(platform / shop_info_id) 会破坏行上下文分组传递，把行内值算成全量值；SLS% / vs Store 全客分母保留行分组为"行内占比"口径，也无需 ALLSELECTED（与 VIC Segment 的断开维度表 DIM_Row_VIC_Tier 场景不同）。

12. **Step1/Step2 两步法（分步实现，2026-09-12 修订）**：口径文档中 SLS / SLS% / ACV / UPT / AUR / Freq. 的计算公式为 Step1 + Step2 两步法，**两步时间范围不同，不能合并区间计算**：Step 1 = end period 当月（`Last_Fiscal_Month` 区间）框定 `is_xxx_vic=1` 的 user_id 集合（UNION+FILTER）；Step 2 = 所选时间范围（`TimeFrame` 区间）对该集合做 sum 聚合（TREATAS 传递，`is_xxx_vic=1` 不再施加）。例外：ACV / Freq. 分母 `count(distinct user_id)` 为 end period 当月单步口径（COUNTROWS(Step 1 集合)）。**全客分母（Store Base Value，vs Store / SLS% 分母）同样分步**，Step 1 筛选条件为 `is_xxx_vic IN {0,1}`，其余与 VIC 侧一致（两套区间按 Metric_ID 路由 Act/LY/LP）。各 Base Value 度量值末尾保留旧逻辑（单步版本）注释块，如需回退按块内说明恢复即可。

13. **单一 Metric_Format 字段**：列指标维度表仅保留单个 `Metric_Format` 字段（不再区分 Act/LY/VsLY），因为每个指标对应一个格式。行格式严格遵循口径文档数据类型定义。

14. **与 VIC_KPIs_Table.md 的关系**：本方案为 Customer Dashboard VIC Tab 的 DCom VIC Breakdown 矩阵 SWITCH 路由版本，与 VIC KPIs 版本共享相同的架构范式（断开列维度 + SWITCH 动态路由 + REMOVEFILTERS 修复上下文），差异在于：
    - 列层级由二级（KPIGroup > ColName）改为三级（VICType > KPIGroup > ColName）
    - 列指标维度表替换为 Dim_ColMetric_New_Retention_VIC（44 行 vs 28 行）
    - 日期表替换为 VIC Breakdown 专用日期表（Slicer_Time_Frame_VIC_Breakdown）
    - 新增金额类指标货币转换（SLS / ACV / AUR）
    - 新增 vs Store 全客对比派生类型
    - 新增 New VIC / Retention VIC 双大分组（仅筛选字段不同）
    - 时间逻辑由"end period 当月 DISTINCTCOUNT"改为"end period 当月 SUM / DISTINCTCOUNT 混合"
    - 颜色规则由"三值标识"精简为"二值标识"（fixed_black / pos_neg_zero）
