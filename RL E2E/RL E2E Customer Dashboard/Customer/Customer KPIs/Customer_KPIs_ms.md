# Power BI 解决方案 — Customer KPIs 矩阵（SWITCH 路由）

> status: ready
> created: 2026-08-19
> type: 度量值开发 + 可视化构建
> 口径来源: 口径文档/Customer/Customer KPI.md（子模块一 Customer KPI，2 个 KPI 分组共 10 列指标）
> 列指标维度表: Dim_ColMetric_Customer_KPIs（10 行，2 个 KPI 分组）

---

## 1. 需求理解

为 Customer Dashboard - Customer Tab 实现 Customer KPIs 矩阵：

- **行**：无行维度表，直接拉取事实表字段（`platform` / `shop_info_id`），天然实现行维度分组和筛选，DAX 无需显式处理
- **列**：`Dim_ColMetric_Customer_KPIs` 的两级层级 `KPIGroup`（父）> `ColName`（子）
  - 2 个 KPI 分组：Customer No. / Customer%
  - 共 10 列指标（每组 5 列）
- **值**：SWITCH 动态路由，按 `Metric_ID` 分发到 Act / vs LY / vs LP / TAR ACH% Monthly / TAR ACH% Yearly
- **口径**：一切以口径文档 Customer KPI.md 为准
- **筛选器**：
  - Slicer_Time_Frame（断开维度，读取 `TimeFrame_ID` 判断 Month/Quarter/Year 粒度）
  - Slicer_Time_Frame_Min（断开维度，读取 `TimeFrame_Min`、`TimeFrame_Value`、`First_Fiscal_Month_Min/Max` 及 LY/LP 系列）
  - Slicer_Time_Frame_Max（断开维度，读取 `TimeFrame_Max`、`TimeFrame_Value` 及 LY/LP 系列）
  - Slicer_Platform_Selection / Slicer_Store_Name（断开维度，行维度直接拉事实表字段实现自动传递；Customer% TAR ACH% 系列需 SELECTEDVALUE 判定 Store 单选）

### 1.1 实际值 = 所选时间范围区间聚合

口径文档全局逻辑明确：

> **聚合粒度**: 数字卡片：所选时间范围 `data_date`；表格：所选时间范围 `data_date`，按对应维度聚合

即实际值的取数区间为：`data_date ∈ [Slicer_Time_Frame_Min[TimeFrame_Min], Slicer_Time_Frame_Max[TimeFrame_Max]]`（全局时间范围）。

**LY/LP 区间**按对称原则构造（起始端读 Min 切片器 LY/LP，结束端读 Max 切片器 LY/LP）：
- LY 区间 = `[Slicer_Time_Frame_Min[TimeFrame_Min_LY], Slicer_Time_Frame_Max[TimeFrame_Max_LY]]`
- LP 区间 = `[Slicer_Time_Frame_Min[TimeFrame_Min_LP], Slicer_Time_Frame_Max[TimeFrame_Max_LP]]`

### 1.2 DCom 新客判定 = Step1 + Step2 交集（合并区间简化实现）

口径文档 1. DCom New Customer No. 筛选条件：

> Step 1：在所选时间范围内筛选 `net_pay_amt > 0` 的 `user_id`（`data_date = 所选时间范围`，`is_member = 0`，`net_pay_amt > 0`）；Step 2：缩小顾客范围至 `lp_12m_net_pay_amt = 0`（`data_date = 所选时间范围 start_period`）；相当于取 Step 1 和 Step 2 的交集，最后 count(distinct user_id)

由于 start_period（第一个财月）是 slicer 区间的子集，技术实现上可"合并区间"——用于判断 `lp_12m_net_pay_amt = 0` 的行一定也在 slicer 区间内。因此技术实现直接等价于单一筛选：

```
data_date ∈ start_period AND net_pay_amt > 0 AND is_member = 0 AND lp_12m_net_pay_amt = 0
```

其中：
- `start_period` = `data_date ∈ [Slicer_Time_Frame_Min[First_Fiscal_Month_Min], Slicer_Time_Frame_Min[First_Fiscal_Month_Max]]`（第一个财月区间）
- `net_pay_amt > 0` 来自 Step 1
- `is_member = 0` 来自 Step 1（Customer KPI 固定非会员）
- `lp_12m_net_pay_amt = 0` 来自 Step 2（新客判定字段）

DAX 实现用单一 `CALCULATE(DISTINCTCOUNT(user_id), <上述四条件>)` 即可，无需 INTERSECT 两张表集合。

### 1.3 派生指标分类

| 派生类型 | 计算方式 | 数据格式 | 适用 Metric_ID |
| --- | --- | --- | --- |
| **数量类 vs LY**（Customer No.） | 今年 / 去年 - 1 | `delta_pct_1dp`（含正号） | 2 |
| **数量类 vs LP**（Customer No.） | 当期 / 上期 - 1 | `delta_pct_1dp`（含正号） | 3 |
| **比率类 vs LY**（Customer%） | 今年 - 去年（差值，×100 转 pts 在 Cell Display 实现） | `delta_pts` | 7 |
| **比率类 vs LP**（Customer%） | 当期 - 上期（差值，×100 转 pts 在 Cell Display 实现） | `delta_pts` | 8 |
| **TAR ACH% Monthly** | 实际值 / 月度目标值 | `percent_1dp`（不含正号） | 4, 9 |
| **TAR ACH% Yearly** | 实际值 / 年度目标值 | `percent_1dp`（不含正号） | 5, 10 |

### 1.4 TAR ACH% 触发条件（按最新口径文档调整）

**TAR ACH% 计算规则矩阵汇总**（严格按口径文档 Customer KPI.md）：

| Metric_ID | 指标 | TimeFrame | 选择范围 | 分子 | 分母 | 说明 |
| --- | --- | --- | --- | --- | --- | --- |
| 4 | Customer Monthly TAR ACH% | Month | 单选财月 | New Customer No.（month actual） | SUM(new_customer_cnt) | 实际值 / 月度目标 |
| 4 | Customer Monthly TAR ACH% | Month | 多选财月 | New Customer No.（month actual） | SUM(new_customer_cnt) | 实际值 / 月度目标 |
| 4 | Customer Monthly TAR ACH% | Month | 多选财月且跨财年 | New Customer No.（month actual） | SUM(new_customer_cnt) | 实际值 / 月度目标 |
| 4 | Customer Monthly TAR ACH% | Quarter/Year | 任意 | — | — | 留空 |
| 5 | Customer Yearly TAR ACH% | Month | 单选财月 | New Customer No.（month actual） | SUM(DISTINCT year_new_customer_cnt) | 单月实际 / 年度目标 |
| 5 | Customer Yearly TAR ACH% | Month | 多选财月 | New Customer No.（month actual） | SUM(DISTINCT year_new_customer_cnt) | 单月实际 / 年度目标 |
| 5 | Customer Yearly TAR ACH% | Month | 多选财月且跨财年 | — | — | 留空 |
| 5 | Customer Yearly TAR ACH% | Quarter | 单季不跨财年 | New Customer No.（quarter actual） | SUM(DISTINCT year_new_customer_cnt) | 季度实际 / 年度目标 |
| 5 | Customer Yearly TAR ACH% | Quarter | 多季不跨财年 | New Customer No.（quarter actual） | SUM(DISTINCT year_new_customer_cnt) | 季度实际 / 年度目标 |
| 5 | Customer Yearly TAR ACH% | Quarter | 跨财年 | — | — | 留空 |
| 5 | Customer Yearly TAR ACH% | Year | 单选财年 | New Customer No.（year actual） | SUM(DISTINCT year_new_customer_cnt) | 年度实际 / 年度目标 |
| 5 | Customer Yearly TAR ACH% | Year | 多选财年 | New Customer No.（year actual） | SUM(DISTINCT year_new_customer_cnt) | 年度实际 / 年度目标 |
| 9 | Customer% Monthly TAR ACH% | Month | 单选财月且 Store 单选 | New Customer%（month actual） | SUM(new_customer_percent) | 单月占比实际 / 月度占比目标 |
| 9 | Customer% Monthly TAR ACH% | 其他 | — | — | — | 留空 |
| 10 | Customer% Yearly TAR ACH% | Month | 单选财月且 Store 单选 | New Customer%（month actual） | SUM(DISTINCT year_new_customer_percent) | 单月占比实际 / 年度占比目标 |
| 10 | Customer% Yearly TAR ACH% | Year | 单选财年且 Store 单选 | New Customer%（year actual） | SUM(DISTINCT year_new_customer_percent) | 年度占比实际 / 年度占比目标 |
| 10 | Customer% Yearly TAR ACH% | 其他 | — | — | — | 留空 |

**单选/多选判定**：
- 单选 = `TimeFrame_ID ∈ {"Month","Year"}` 且 `Slicer_Time_Frame_Min[TimeFrame_Value] = Slicer_Time_Frame_Max[TimeFrame_Value]`
- 多选 = 非单选

**跨财年判定**：
- 仅在 `TimeFrame_ID ∈ {"Month","Quarter"}` 时判断
- 比较 `LEFT(Slicer_Time_Frame_Min[TimeFrame_Value], 4)` 与 `LEFT(Slicer_Time_Frame_Max[TimeFrame_Value], 4)` 的年部分
- 不相等 → 跨财年

**Customer% TAR ACH% 系列额外要求**：`Slicer_Store_Name[Store_ID]` 单选（DISTINCTCOUNT = 1）。

### 1.5 目标值取数与聚合方式

> 公式：`TAR ACH% = 实际值 / 目标值`
> 目标值来源：`a03_e2e_customer_fcst_data_m`（日期字段 `data_date`）
> 目标值时间范围：`data_date ∈ [Slicer_Time_Frame_Min[TimeFrame_Min], Slicer_Time_Frame_Max[TimeFrame_Max]]`（全局时间范围，与实际值同区间）
> 目标值无 is_member / is_employee 筛选
> 行维度 platform / shop_info_id 通过共享维度表自动传递到目标值表

| Metric_ID | 指标 | 实际值来源 | 目标值字段 | 目标值聚合方式 |
| --- | --- | --- | --- | --- |
| 4  | Customer Monthly TAR ACH% | DCom New Customer No. Act（Metric_ID=1） | `new_customer_cnt` | SUM |
| 5  | Customer Yearly TAR ACH% | DCom New Customer No. Act（Metric_ID=1） | `year_new_customer_cnt` | SUM(DISTINCT) |
| 9  | Customer% Monthly TAR ACH% | DCom New Customer% Act（Metric_ID=6） | `new_customer_percent` | SUM |
| 10 | Customer% Yearly TAR ACH% | DCom New Customer% Act（Metric_ID=6） | `year_new_customer_percent` | SUM(DISTINCT) |

**目标值聚合方式说明**：
- `SUM(field)`：月度目标值字段（`new_customer_cnt` / `new_customer_percent`），按当前行维度粒度直接 SUM 汇总
- `SUM(DISTINCT field)`：年度目标值字段（`year_new_customer_cnt` / `year_new_customer_percent`），每个 shop 同年唯一，先按 platform/shop_info_id 分组 DISTINCT 去重，再 SUM 汇总到当前行维度粒度。实现方式：`SUMX(SUMMARIZE(table, [platform], [shop_info_id], [year_xxx_field]), [year_xxx_field])`（DISTINCT 返回表非标量，用 SUMMARIZE 分组等价实现 DISTINCT 去重后再 SUM）

---

## 2. 现状分析

### 2.1 数据底表

| 对象 | 名称 | 出处 |
| --- | --- | --- |
| 事实表（实际值） | a03_e2e_customer_data_m | Customer KPI.md 全局逻辑 |
| 事实表（目标值） | a03_e2e_customer_fcst_data_m | Customer KPI.md 全局逻辑 |
| 实际值关键字段 | data_date, platform, shop_info_id, user_id, is_member, net_pay_amt, lp_12m_net_pay_amt | Customer KPI.md 子模块一 |
| 目标值关键字段 | data_date, platform, shop_info_id, new_customer_cnt, new_customer_percent, year_new_customer_cnt, year_new_customer_percent | a03_e2e_customer_fcst_data_m 数据字典 |

### 2.2 维度表清单

| 维度表 | 类型 | 连接方式 |
| --- | --- | --- |
| Slicer_Time_Frame | 断开维度 | SELECTEDVALUE 读取 `TimeFrame_ID` 判断 Month/Quarter/Year 粒度 |
| Slicer_Time_Frame_Min | 断开维度 | SELECTEDVALUE 读取 `TimeFrame_Min` / `TimeFrame_Value`（区间起始日，单选判定）；`First_Fiscal_Month_Min/Max`（start_period 第一个财月区间，Step 2 新客判定用）；`TimeFrame_Min_LY/Max_LY/Min_LP/Max_LP`（区间聚合 LY/LP 起止日） |
| Slicer_Time_Frame_Max | 断开维度 | SELECTEDVALUE 读取 `TimeFrame_Max` / `TimeFrame_Value`（区间结束日，单选判定）；`TimeFrame_Min_LY/Max_LY/Min_LP/Max_LP`（区间聚合 LY/LP 起止日） |
| Slicer_Platform_Selection | 断开维度 | 行维度直接拉事实表 platform 字段，模型自动传递 |
| Slicer_Store_Name | 断开维度 | 行维度直接拉事实表 shop_info_id 字段，模型自动传递；Customer% TAR ACH% 系列（Metric_ID=9/10）需 SELECTEDVALUE 判定 Store 单选 |
| Dim_ColMetric_Customer_KPIs | 断开维度 | SELECTEDVALUE 读取 `Metric_ID` / `ColType` / `Metric_Format` / `Metric_ColorRule` / 颜色字段 |

> **行维度处理**：`platform` / `shop_info_id` 直接拉取事实表字段实现自动传递，模型自动传递筛选，DAX 无需显式处理。

---

## 3. 方案设计

### 3.1 整体架构

```
核心思路：断开列维度 + SWITCH 动态路由（Disconnected Dimension + Dispatch Pattern）

Dim_ColMetric_Customer_KPIs（断开维度，列头）
    │
    │  无关系连接，仅通过 SELECTEDVALUE 读取：
    │  - Metric_ID, ColType, KPIGroup, ColName
    │  - Metric_Format, Metric_ColorRule
    │  - Metric_ColorPositive/Negative/Zero/Default
    │
    ▼
    ┌─────────────────────────── Matrix 视觉对象 ──────────────────────────┐
    │  行 = 事实表字段（platform / shop_info_id）                          │
    │  列 = 'Dim_ColMetric_Customer_KPIs'[KPIGroup] > [ColName]            │
    │  值 = [Customer KPIs Cell Display]                                    │
    └────────────────────────────────────────────────────────────────────────┘
                                   ▲
                                   │
              SWITCH 动态路由度量值链（按 Metric_ID 分发）
              ┌────────────────────────────────────────────────────┐
              │  [Customer KPIs Cell Value]                        │
              │    └→ [Customer KPIs Base Value]（总路由）         │
              │         ├→ [Customer KPIs Act Base Value]（本期） │
              │         │     ├ Metric_ID=1: DCom New Customer No. │
              │         │     │  (合并区间 DISTINCTCOUNT)          │
              │         │     └ Metric_ID=6: DCom New Customer%  │
              │         │        (分子 Metric_ID=1 / 分母全部)    │
              │         ├→ [Customer KPIs LY Base Value]（去年同期）│
              │         ├→ [Customer KPIs LP Base Value]（上期）  │
              │         └→ 派生：vs LY / vs LP / TAR ACH% Monthly /│
              │            TAR ACH% Yearly（按 Metric_ID 路由）    │
              └────────────────────────────────────────────────────┘
```

### 3.2 度量值模型设计

```
[Customer KPIs Act Base Value]          ← 本期基础值
                                        ← Metric_ID=1: DCom New Customer No.（合并区间）
                                        ← Metric_ID=6: DCom New Customer%（分子 Metric_ID=1 / 分母全部）
                                        ← 统一应用 is_member=0、本期区间 data_date 筛选
[Customer KPIs LY Base Value]           ← 去年同期基础值（LY 区间对称映射）
[Customer KPIs LP Base Value]           ← 上期基础值（LP 区间对称映射）
[Customer KPIs Base Value]              ← 总路由（含 vs LY / vs LP / TAR ACH% Monthly / TAR ACH% Yearly 派生）
                                        ← REMOVEFILTERS 清除断开维度筛选，再应用目标 Metric_ID
                                        ← TAR ACH%: 实际值(Act Base Value) / 目标值(a03_e2e_customer_fcst_data_m)
[Customer KPIs Cell Value]              ← 对外值 = Base Value
[Customer KPIs Cell Display]            ← 格式化显示文本（按 Metric_Format 单字段分发）
[Customer KPIs Cell Font Color]         ← 字体颜色（按 Metric_ColorRule 分发：fixed_black / pos_neg_zero / fixed_default）
[Customer KPIs Cell Background Color]   ← 背景色（KPIGroup 行 vs KPI 行）
```

### 3.3 筛选器上下文

| 筛选器 | 作用方式 | DAX 处理 |
| --- | --- | --- |
| Slicer_Time_Frame | 断开维度，SELECTEDVALUE 读取 `TimeFrame_ID` | 判断 Month/Quarter/Year 粒度，用于 TAR ACH% 触发条件 |
| Slicer_Time_Frame_Min | 断开维度，SELECTEDVALUE 读取 `TimeFrame_Min/TimeFrame_Value` | 本期区间起始日 + 单选判定 + start_period 第一个财月（First_Fiscal_Month_Min/Max）+ LY/LP 区间起始日 |
| Slicer_Time_Frame_Max | 断开维度，SELECTEDVALUE 读取 `TimeFrame_Max/TimeFrame_Value` | 本期区间结束日 + 单选判定 + LY/LP 区间结束日 |
| 事实表分组字段 | 表格行直接拉取，模型自动传递筛选 | DAX 无需显式处理 |

### 3.4 vs LY / vs LP 时间偏移规则（区间对称映射）

本期区间 = `[Slicer_Time_Frame_Min[TimeFrame_Min], Slicer_Time_Frame_Max[TimeFrame_Max]]`

LY/LP 区间按对称原则构造（起始端读 Min 切片器 LY/LP，结束端读 Max 切片器 LY/LP）：

- **LY 区间** = `[Slicer_Time_Frame_Min[TimeFrame_Min_LY], Slicer_Time_Frame_Max[TimeFrame_Max_LY]]`
- **LP 区间** = `[Slicer_Time_Frame_Min[TimeFrame_Min_LP], Slicer_Time_Frame_Max[TimeFrame_Max_LP]]`

> 这些字段已在 Slicer_Time_Frame_Min/Max 维度表中预算，无需 DAX 重复实现。

### 3.5 vs LY / vs LP 派生计算分类

| Metric_ID | 指标 | 派生类型 | 计算方式 | Metric_Format |
| --- | --- | --- | --- | --- |
| 2 | DCom New Customer No. vs LY | 数量类 vs LY | 今年 / 去年 - 1 | delta_pct_1dp |
| 3 | DCom New Customer No. vs LP | 数量类 vs LP | 当期 / 上期 - 1 | delta_pct_1dp |
| 7 | DCom New Customer% vs LY | 比率类 vs LY | 今年 - 去年（差值） | delta_pts |
| 8 | DCom New Customer% vs LP | 比率类 vs LP | 当期 - 上期（差值） | delta_pts |

### 3.6 TAR ACH% 类指标计算（实际值 / 目标值）

> 公式：`TAR ACH% = 实际值 / 目标值`
> 目标值来源：`a03_e2e_customer_fcst_data_m`（日期字段 `data_date`，目标值无 is_member / is_employee 筛选）
> 目标值时间范围：`data_date ∈ [Slicer_Time_Frame_Min[TimeFrame_Min], Slicer_Time_Frame_Max[TimeFrame_Max]]`（全局时间范围，与实际值同区间）
> 行维度 platform / shop_info_id 通过共享维度表自动传递到目标值表

| Metric_ID | 指标 | 实际值来源 | 目标值字段 | 目标值聚合 | 触发条件 |
| --- | --- | --- | --- | --- | --- |
| 4  | Customer Monthly TAR ACH% | DCom New Customer No. Act（Metric_ID=1） | `new_customer_cnt` | SUM | Month 任意选择范围都有值；Quarter/Year 留空 |
| 5  | Customer Yearly TAR ACH% | DCom New Customer No. Act（Metric_ID=1） | `year_new_customer_cnt` | SUM(DISTINCT) | Month 单选/多选不跨财年有值；Quarter 单选/多选不跨财年有值；Year 单选/多选有值；Month/Quarter 跨财年留空 |
| 9  | Customer% Monthly TAR ACH% | DCom New Customer% Act（Metric_ID=6） | `new_customer_percent` | SUM | Month 单选且 Store 单选有值；其他留空 |
| 10 | Customer% Yearly TAR ACH% | DCom New Customer% Act（Metric_ID=6） | `year_new_customer_percent` | SUM(DISTINCT) | Month 单选且 Store 单选有值；Year 单选且 Store 单选有值；其他留空 |

**单选/多选判定规则**：
- `Slicer_Time_Frame[TimeFrame_ID] ∈ {"Month", "Year"}`（时间粒度为月或年，排除 Quarter）
- `Slicer_Time_Frame_Min[TimeFrame_Value] = Slicer_Time_Frame_Max[TimeFrame_Value]`（Min/Max 切片器选中值相等）
- 两个条件同时满足时为单选，否则为多选

**跨财年判定规则**：
- 仅在 `Slicer_Time_Frame[TimeFrame_ID] ∈ {"Month", "Quarter"}` 时判断
- 比较 `LEFT(Slicer_Time_Frame_Min[TimeFrame_Value], 4)` 与 `LEFT(Slicer_Time_Frame_Max[TimeFrame_Value], 4)` 的年部分
- 不相等 → 跨财年 → Yearly TAR ACH%（Metric_ID=5/10）留空（BLANK）

**目标值聚合方式说明**：
- `SUM(field)`：月度目标值字段（`new_customer_cnt` / `new_customer_percent`），按当前行维度粒度直接 SUM 汇总
- `SUM(DISTINCT field)`：年度目标值字段（`year_new_customer_cnt` / `year_new_customer_percent`），每个 shop 同年唯一，先按 platform/shop_info_id 分组 DISTINCT 去重，再 SUM 汇总到当前行维度粒度。实现方式：`SUMX(SUMMARIZE(table, [platform], [shop_info_id], [year_xxx_field]), [year_xxx_field])`

**非触发场景（留空 BLANK）**：
- Metric_ID=4（Customer Monthly TAR ACH%）：Quarter / Year 粒度 → BLANK
- Metric_ID=5（Customer Yearly TAR ACH%）：Month 跨财年 / Quarter 跨财年 → BLANK
- Metric_ID=9（Customer% Monthly TAR ACH%）：非 Month 单选 / Store 未单选 → BLANK
- Metric_ID=10（Customer% Yearly TAR ACH%）：非 Month/Year 单选 / Store 未单选 / 跨财年 → BLANK

### 3.7 格式规范（按 Metric_Format 单字段分发）

| Metric_Format | 格式串 | 示例 | 适用指标 |
| --- | --- | --- | --- |
| `integer` | `#,##0` | 1,234 | DCom New Customer No. Act（Metric_ID=1） |
| `percent_1dp` | `#,##0.0%` | 14.5% | DCom New Customer% Act（Metric_ID=6）/ 4 个 TAR ACH%（Metric_ID=4/5/9/10） |
| `delta_pct_1dp` | `IF(__Value>0,"+","") & FORMAT(__Value,"#,##0.0%")` | +14.5% / -3.2% | 数量类 vs LY / vs LP（Metric_ID=2/3） |
| `delta_pts` | `IF(ROUND(__Value*100,0)>0,"+","") & FORMAT(__Value*100,"+#,##0pts;-#,##0pts;0pts")` | +120pts / -80pts / 0pts | 比率类 vs LY / vs LP（Metric_ID=7/8），值×100 转 pts 在 Cell Display 中实现 |

---

## 4. 度量值实现

### 4.1 Dim_ColMetric_Customer_KPIs（列指标维度表）

> 维度表已存在于 `Dim_ColMetric_Customer_KPIs.md`，此处不再重复定义，直接引用。下表明晰 Metric_ID 与口径文档指标的映射关系：

| Metric_ID | KPIGroup | ColName | ColType | 口径文档对应指标 | Act/LP/LY 字段/逻辑 | 数据底表 |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | Customer No. | 1-DCom New Customer No. | Act | 1. DCom New Customer No. | 合并区间（start_period 内 net_pay_amt>0 ∩ lp_12m_net_pay_amt=0 ∩ is_member=0） | a03_e2e_customer_data_m |
| 2 | Customer No. | 2-DCom New Customer No. vs LY | vs LY | 1.1 | — | 派生 |
| 3 | Customer No. | 3-DCom New Customer No. vs LP | vs LP | 1.2 | — | 派生 |
| 4 | Customer No. | 4-Customer Monthly TAR ACH% | TAR ACH% Monthly | 1.3 | 实际值: Metric_ID=1；目标值: SUM(new_customer_cnt) | a03_e2e_customer_data_m / a03_e2e_customer_fcst_data_m |
| 5 | Customer No. | 5-Customer Yearly TAR ACH% | TAR ACH% Yearly | 1.4 | 实际值: Metric_ID=1；目标值: SUM(DISTINCT year_new_customer_cnt) | a03_e2e_customer_data_m / a03_e2e_customer_fcst_data_m |
| 6 | Customer% | 6-DCom New Customer% | Act | 2. DCom New Customer% | 分子: Metric_ID=1；分母: count(distinct user_id) where net_pay_amt>0 AND is_member=0 | a03_e2e_customer_data_m |
| 7 | Customer% | 7-DCom New Customer% vs LY | vs LY | 2.1 | — | 派生 |
| 8 | Customer% | 8-DCom New Customer% vs LP | vs LP | 2.2 | — | 派生 |
| 9 | Customer% | 9-Customer% Monthly TAR ACH% | TAR ACH% Monthly | 2.3 | 实际值: Metric_ID=6；目标值: SUM(new_customer_percent) | a03_e2e_customer_data_m / a03_e2e_customer_fcst_data_m |
| 10 | Customer% | 10-Customer% Yearly TAR ACH% | TAR ACH% Yearly | 2.4 | 实际值: Metric_ID=6；目标值: SUM(DISTINCT year_new_customer_percent) | a03_e2e_customer_data_m / a03_e2e_customer_fcst_data_m |

### 4.2 Customer KPIs Act Base Value（本期基础值）

```dax
Customer KPIs Act Base Value =
// ========================================
// 度量值: Customer KPIs Act Base Value
// Display Folder: Base Metrics
// 用途: 根据 Metric_ID 路由到本期（Act）基础值
// 依赖: 'Dim_ColMetric_Customer_KPIs'[Metric_ID],
//       a03_e2e_customer_data_m,
//       Slicer_Time_Frame_Min[TimeFrame_Min, First_Fiscal_Month_Min, First_Fiscal_Month_Max],
//       Slicer_Time_Frame_Max[TimeFrame_Max]
// 口径来源: 口径文档/Customer/Customer KPI.md 子模块一
// 筛选上下文:
//   - 本期区间: data_date ∈ [Slicer_Time_Frame_Min[TimeFrame_Min], Slicer_Time_Frame_Max[TimeFrame_Max]]
//   - start_period 区间（Step 2 新客判定用）: data_date ∈ [First_Fiscal_Month_Min, First_Fiscal_Month_Max]
//   - is_member = 0（Customer KPI 固定非会员）
// 聚合粒度: DISTINCTCOUNT(user_id)
// 说明:
//   - Metric_ID=1: DCom New Customer No.
//     Step1+Step2 合并区间等价实现：
//       data_date ∈ start_period AND net_pay_amt > 0 AND is_member = 0 AND lp_12m_net_pay_amt = 0
//     （start_period 是 slicer 区间的子集，合并区间后单一 CALCULATE 即可）
//   - Metric_ID=6: DCom New Customer% = DIVIDE(分子 Metric_ID=1, 分母 全部 user_id)
//     分子: 同 Metric_ID=1（DCom New Customer No.）
//     分母: 本期区间内 net_pay_amt>0 AND is_member=0 的 user_id 全部计数（不分新老客）
//   - 字段名: 严格按口径文档使用 lp_12m_net_pay_amt
// ========================================
    VAR __MetricID = SELECTEDVALUE('Dim_ColMetric_Customer_KPIs'[Metric_ID])

    // ── 本期区间（Step 1 时间范围）──
    VAR __PeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Min[TimeFrame_Min])
    VAR __PeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max[TimeFrame_Max])

    // ── start_period 区间（Step 2 新客判定时间范围，第一个财月）──
    VAR __StartPeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Min[First_Fiscal_Month_Min])
    VAR __StartPeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Min[First_Fiscal_Month_Max])

    // ═══════════════════════════════════════
    // DCom New Customer No.（Metric_ID=1）
    // Step1+Step2 合并区间等价实现：
    //   data_date ∈ start_period AND net_pay_amt > 0 AND is_member = 0 AND lp_12m_net_pay_amt = 0
    // ═══════════════════════════════════════
    VAR __NewCustomerCnt_Act =
        CALCULATE(
            DISTINCTCOUNT('a03_e2e_customer_data_m'[user_id]),
            'a03_e2e_customer_data_m'[is_member] = 0,
            'a03_e2e_customer_data_m'[net_pay_amt] > 0,
            'a03_e2e_customer_data_m'[lp_12m_net_pay_amt] = 0,
            'a03_e2e_customer_data_m'[data_date] >= __StartPeriodMin,
            'a03_e2e_customer_data_m'[data_date] <= __StartPeriodMax
        )

    // ═══════════════════════════════════════
    // 分母（DCom New Customer%，Metric_ID=6 分母）
    // 本期区间内 net_pay_amt>0 AND is_member=0 的全部 user_id
    // ═══════════════════════════════════════
    VAR __AllCustomerCnt_Act =
        CALCULATE(
            DISTINCTCOUNT('a03_e2e_customer_data_m'[user_id]),
            'a03_e2e_customer_data_m'[is_member] = 0,
            'a03_e2e_customer_data_m'[net_pay_amt] > 0,
            'a03_e2e_customer_data_m'[data_date] >= __PeriodMin,
            'a03_e2e_customer_data_m'[data_date] <= __PeriodMax
        )

    // ═══════════════════════════════════════
    // DCom New Customer% = 分子 / 分母
    // ═══════════════════════════════════════
    VAR __NewCustomerPct_Act =
        DIVIDE(__NewCustomerCnt_Act, __AllCustomerCnt_Act)

    RETURN
        SWITCH(
            __MetricID,
            // ── Customer No. 分组（Act：DCom New Customer No.）──
            1,  __NewCustomerCnt_Act,
            // ── Customer% 分组（Act：DCom New Customer%）──
            6,  __NewCustomerPct_Act,
            BLANK()
        )
```

### 4.3 Customer KPIs LY Base Value（去年同期基础值）

```dax
Customer KPIs LY Base Value =
// ========================================
// 度量值: Customer KPIs LY Base Value
// Display Folder: Base Metrics
// 用途: 根据 Metric_ID 路由到去年同期（LY）基础值
// 依赖: 'Dim_ColMetric_Customer_KPIs'[Metric_ID],
//       Slicer_Time_Frame_Min[TimeFrame_Min_LY, First_Fiscal_Month_Min_LY, First_Fiscal_Month_Max_LY],
//       Slicer_Time_Frame_Max[TimeFrame_Max_LY],
//       a03_e2e_customer_data_m
// 口径来源: 口径文档/Customer/Customer KPI.md 子模块一
// 时间偏移: 区间对称映射
//   - 本期 LY 区间 = [Slicer_Time_Frame_Min[TimeFrame_Min_LY], Slicer_Time_Frame_Max[TimeFrame_Max_LY]]
//   - start_period LY 区间 = [First_Fiscal_Month_Min_LY, First_Fiscal_Month_Max_LY]
// 说明:
//   - Metric_ID=1: DCom New Customer No. LY（Step1+Step2 合并区间，时间范围改为 LY）
//   - Metric_ID=6: DCom New Customer% LY = DIVIDE(分子, 分母)
// ========================================
    VAR __MetricID = SELECTEDVALUE('Dim_ColMetric_Customer_KPIs'[Metric_ID])

    // ── 本期 LY 区间（Step 1 时间范围，LY）──
    VAR __PeriodMin_LY = SELECTEDVALUE(Slicer_Time_Frame_Min[TimeFrame_Min_LY])
    VAR __PeriodMax_LY = SELECTEDVALUE(Slicer_Time_Frame_Max[TimeFrame_Max_LY])

    // ── start_period LY 区间（Step 2 新客判定时间范围，LY）──
    VAR __StartPeriodMin_LY = SELECTEDVALUE(Slicer_Time_Frame_Min[First_Fiscal_Month_Min_LY])
    VAR __StartPeriodMax_LY = SELECTEDVALUE(Slicer_Time_Frame_Min[First_Fiscal_Month_Max_LY])

    // ═══════════════════════════════════════
    // DCom New Customer No. LY（Metric_ID=1）
    // Step1+Step2 合并区间等价实现（LY 版本）：
    //   data_date ∈ start_period_LY AND net_pay_amt > 0 AND is_member = 0 AND lp_12m_net_pay_amt = 0
    // ═══════════════════════════════════════
    VAR __NewCustomerCnt_LY =
        CALCULATE(
            DISTINCTCOUNT('a03_e2e_customer_data_m'[user_id]),
            'a03_e2e_customer_data_m'[is_member] = 0,
            'a03_e2e_customer_data_m'[net_pay_amt] > 0,
            'a03_e2e_customer_data_m'[lp_12m_net_pay_amt] = 0,
            'a03_e2e_customer_data_m'[data_date] >= __StartPeriodMin_LY,
            'a03_e2e_customer_data_m'[data_date] <= __StartPeriodMax_LY
        )

    // ═══════════════════════════════════════
    // 分母 LY — DCom New Customer% 分母（LY 区间内全部 user_id）
    // ═══════════════════════════════════════
    VAR __AllCustomerCnt_LY =
        CALCULATE(
            DISTINCTCOUNT('a03_e2e_customer_data_m'[user_id]),
            'a03_e2e_customer_data_m'[is_member] = 0,
            'a03_e2e_customer_data_m'[net_pay_amt] > 0,
            'a03_e2e_customer_data_m'[data_date] >= __PeriodMin_LY,
            'a03_e2e_customer_data_m'[data_date] <= __PeriodMax_LY
        )

    // ═══════════════════════════════════════
    // DCom New Customer% LY
    // ═══════════════════════════════════════
    VAR __NewCustomerPct_LY =
        DIVIDE(__NewCustomerCnt_LY, __AllCustomerCnt_LY)

    RETURN
        SWITCH(
            __MetricID,
            // ── Customer No. LY ──
            1,  __NewCustomerCnt_LY,
            // ── Customer% LY ──
            6,  __NewCustomerPct_LY,
            BLANK()
        )
```

### 4.4 Customer KPIs LP Base Value（上期基础值）

```dax
Customer KPIs LP Base Value =
// ========================================
// 度量值: Customer KPIs LP Base Value
// Display Folder: Base Metrics
// 用途: 根据 Metric_ID 路由到上期（LP）基础值
// 依赖: 'Dim_ColMetric_Customer_KPIs'[Metric_ID],
//       Slicer_Time_Frame_Min[TimeFrame_Min_LP, First_Fiscal_Month_Min_LP, First_Fiscal_Month_Max_LP],
//       Slicer_Time_Frame_Max[TimeFrame_Max_LP],
//       a03_e2e_customer_data_m
// 口径来源: 口径文档/Customer/Customer KPI.md 子模块一
// 时间偏移: 区间对称映射
//   - 本期 LP 区间 = [Slicer_Time_Frame_Min[TimeFrame_Min_LP], Slicer_Time_Frame_Max[TimeFrame_Max_LP]]
//   - start_period LP 区间 = [First_Fiscal_Month_Min_LP, First_Fiscal_Month_Max_LP]
// 注: LP = Last Period（上一期），按所选粒度（月/季/年）的上一期
// ========================================
    VAR __MetricID = SELECTEDVALUE('Dim_ColMetric_Customer_KPIs'[Metric_ID])

    // ── 本期 LP 区间（Step 1 时间范围，LP）──
    VAR __PeriodMin_LP = SELECTEDVALUE(Slicer_Time_Frame_Min[TimeFrame_Min_LP])
    VAR __PeriodMax_LP = SELECTEDVALUE(Slicer_Time_Frame_Max[TimeFrame_Max_LP])

    // ── start_period LP 区间（Step 2 新客判定时间范围，LP）──
    VAR __StartPeriodMin_LP = SELECTEDVALUE(Slicer_Time_Frame_Min[First_Fiscal_Month_Min_LP])
    VAR __StartPeriodMax_LP = SELECTEDVALUE(Slicer_Time_Frame_Min[First_Fiscal_Month_Max_LP])

    // ═══════════════════════════════════════
    // DCom New Customer No. LP（Metric_ID=1）
    // Step1+Step2 合并区间等价实现（LP 版本）：
    //   data_date ∈ start_period_LP AND net_pay_amt > 0 AND is_member = 0 AND lp_12m_net_pay_amt = 0
    // ═══════════════════════════════════════
    VAR __NewCustomerCnt_LP =
        CALCULATE(
            DISTINCTCOUNT('a03_e2e_customer_data_m'[user_id]),
            'a03_e2e_customer_data_m'[is_member] = 0,
            'a03_e2e_customer_data_m'[net_pay_amt] > 0,
            'a03_e2e_customer_data_m'[lp_12m_net_pay_amt] = 0,
            'a03_e2e_customer_data_m'[data_date] >= __StartPeriodMin_LP,
            'a03_e2e_customer_data_m'[data_date] <= __StartPeriodMax_LP
        )

    // ═══════════════════════════════════════
    // 分母 LP — DCom New Customer% 分母（LP 区间内全部 user_id）
    // ═══════════════════════════════════════
    VAR __AllCustomerCnt_LP =
        CALCULATE(
            DISTINCTCOUNT('a03_e2e_customer_data_m'[user_id]),
            'a03_e2e_customer_data_m'[is_member] = 0,
            'a03_e2e_customer_data_m'[net_pay_amt] > 0,
            'a03_e2e_customer_data_m'[data_date] >= __PeriodMin_LP,
            'a03_e2e_customer_data_m'[data_date] <= __PeriodMax_LP
        )

    // ═══════════════════════════════════════
    // DCom New Customer% LP
    // ═══════════════════════════════════════
    VAR __NewCustomerPct_LP =
        DIVIDE(__NewCustomerCnt_LP, __AllCustomerCnt_LP)

    RETURN
        SWITCH(
            __MetricID,
            // ── Customer No. LP ──
            1,  __NewCustomerCnt_LP,
            // ── Customer% LP ──
            6,  __NewCustomerPct_LP,
            BLANK()
        )
```

### 4.5 Customer KPIs Base Value（总路由）

```dax
Customer KPIs Base Value =
// ========================================
// 度量值: Customer KPIs Base Value
// Display Folder: Base Metrics
// 用途: 总路由，根据 Metric_ID 分发到 Act / vs LY / vs LP / TAR ACH% Monthly / TAR ACH% Yearly
// 依赖: [Customer KPIs Act Base Value], [Customer KPIs LY Base Value], [Customer KPIs LP Base Value],
//       'Dim_ColMetric_Customer_KPIs'[Metric_ID],
//       Slicer_Time_Frame[TimeFrame_ID],
//       Slicer_Time_Frame_Min[TimeFrame_Value, TimeFrame_Min],
//       Slicer_Time_Frame_Max[TimeFrame_Value, TimeFrame_Max],
//       Slicer_Store_Name[Store_ID],
//       a03_e2e_customer_fcst_data_m
//
// Metric_ID 路由规则:
//   Act 基础指标 ID: 1, 6
//   数量类 vs LY: 2（Customer No.）
//   数量类 vs LP: 3（Customer No.）
//   比率类 vs LY: 7（Customer%）
//   比率类 vs LP: 8（Customer%）
//   TAR ACH% Monthly: 4（Customer No.）/ 9（Customer%）
//   TAR ACH% Yearly: 5（Customer No.）/ 10（Customer%）
//
// 派生规则:
//   - 数量类 vs LY: 今年 / 去年 - 1
//   - 数量类 vs LP: 当期 / 上期 - 1
//   - 比率类 vs LY: 今年 - 去年（差值，×100 转 pts 在 Cell Display 实现）
//   - 比率类 vs LP: 当期 - 上期（差值，×100 转 pts 在 Cell Display 实现）
//   - TAR ACH% Monthly: 实际值 / 月度目标值（SUM）
//   - TAR ACH% Yearly: 实际值 / 年度目标值（SUM(DISTINCT)）
//
// REMOVEFILTERS 机制:
//   派生行需先 REMOVEFILTERS 清除断开维度的所有筛选，再应用目标 Metric_ID
//
// TAR ACH% 触发条件（按最新口径文档调整）:
//   - 单选判定: Slicer_Time_Frame[TimeFrame_ID] ∈ {"Month","Year"} 且 Min/Max TimeFrame_Value 相等
//   - 多选判定: 非单选（Month/Year 多选也有值，针对 Metric_ID=4/5）
//   - 跨财年判定: TimeFrame_ID ∈ {"Month","Quarter"} 时比较 Min/Max TimeFrame_Value 年部分
//   - Customer% TAR ACH% 系列（Metric_ID=9/10）额外要求 Store 单选
//   - 非触发场景:
//     * Metric_ID=4: Quarter/Year 粒度 → BLANK
//     * Metric_ID=5: Month 跨财年 / Quarter 跨财年 → BLANK
//     * Metric_ID=9: 非 Month 单选 / Store 未单选 → BLANK
//     * Metric_ID=10: 非 Month/Year 单选 / Store 未单选 / 跨财年 → BLANK
// ========================================
    VAR __MetricID = SELECTEDVALUE('Dim_ColMetric_Customer_KPIs'[Metric_ID])

    // ═══════════════════════════════════════
    // 数量类 vs LY（分子: Act，分母: LY）
    // DCom New Customer No. vs LY: Metric_ID=2，Act→1，LY→1
    // ═══════════════════════════════════════
    VAR __IsQtyVsLY = __MetricID = 2
    VAR __QtyActValue_LY =
        IF(
            __IsQtyVsLY,
            CALCULATE(
                [Customer KPIs Act Base Value],
                REMOVEFILTERS('Dim_ColMetric_Customer_KPIs'),
                'Dim_ColMetric_Customer_KPIs'[Metric_ID] = 1
            )
        )
    VAR __QtyLYValue =
        IF(
            __IsQtyVsLY,
            CALCULATE(
                [Customer KPIs LY Base Value],
                REMOVEFILTERS('Dim_ColMetric_Customer_KPIs'),
                'Dim_ColMetric_Customer_KPIs'[Metric_ID] = 1
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
    // DCom New Customer No. vs LP: Metric_ID=3，Act→1
    // ═══════════════════════════════════════
    VAR __IsQtyVsLP = __MetricID = 3
    VAR __QtyActValue_LP =
        IF(
            __IsQtyVsLP,
            CALCULATE(
                [Customer KPIs Act Base Value],
                REMOVEFILTERS('Dim_ColMetric_Customer_KPIs'),
                'Dim_ColMetric_Customer_KPIs'[Metric_ID] = 1
            )
        )
    VAR __QtyLPValue =
        IF(
            __IsQtyVsLP,
            CALCULATE(
                [Customer KPIs LP Base Value],
                REMOVEFILTERS('Dim_ColMetric_Customer_KPIs'),
                'Dim_ColMetric_Customer_KPIs'[Metric_ID] = 1
            )
        )
    VAR __QtyVsLPResult =
        IF(
            ISBLANK(__QtyLPValue) || __QtyLPValue = 0,
            BLANK(),
            DIVIDE(__QtyActValue_LP, __QtyLPValue) - 1
        )

    // ═══════════════════════════════════════
    // 比率类 vs LY / vs LP（Customer%，差值，×100 转 pts 在 Cell Display 实现）
    // DCom New Customer% vs LY: Metric_ID=7
    // DCom New Customer% vs LP: Metric_ID=8
    // ═══════════════════════════════════════
    VAR __IsPctVsLY = __MetricID = 7
    VAR __IsPctVsLP = __MetricID = 8

    // DCom New Customer% Act / LY / LP（Metric_ID=6）
    VAR __NewCustomerPctAct =
        CALCULATE(
            [Customer KPIs Act Base Value],
            REMOVEFILTERS('Dim_ColMetric_Customer_KPIs'),
            'Dim_ColMetric_Customer_KPIs'[Metric_ID] = 6
        )
    VAR __NewCustomerPctLY =
        IF(
            __IsPctVsLY,
            CALCULATE(
                [Customer KPIs LY Base Value],
                REMOVEFILTERS('Dim_ColMetric_Customer_KPIs'),
                'Dim_ColMetric_Customer_KPIs'[Metric_ID] = 6
            )
        )
    VAR __NewCustomerPctLP =
        IF(
            __IsPctVsLP,
            CALCULATE(
                [Customer KPIs LP Base Value],
                REMOVEFILTERS('Dim_ColMetric_Customer_KPIs'),
                'Dim_ColMetric_Customer_KPIs'[Metric_ID] = 6
            )
        )

    // 比率类 vs LY / vs LP（差值）
    VAR __PctVsLYResult =
        IF(
            __IsPctVsLY,
            __NewCustomerPctAct - __NewCustomerPctLY
        )
    VAR __PctVsLPResult =
        IF(
            __IsPctVsLP,
            __NewCustomerPctAct - __NewCustomerPctLP
        )

    // ═══════════════════════════════════════
    // TAR ACH% 指标（Metric_ID 4, 5, 9, 10）
    // 公式：TAR ACH% = 实际值 / 目标值
    // 目标值来源：a03_e2e_customer_fcst_data_m（日期字段 data_date）
    // 目标值筛选：data_date ∈ [__TimeMin, __TimeMax]（全局时间范围）
    //   - __TimeMin = SELECTEDVALUE(Slicer_Time_Frame_Min[TimeFrame_Min])
    //   - __TimeMax = SELECTEDVALUE(Slicer_Time_Frame_Max[TimeFrame_Max])
    // 目标值无 is_member / is_employee 筛选
    // 行维度 platform / shop_info_id 通过共享维度表自动传递到目标值表
    // 触发条件（按最新口径文档调整）:
    //   - 单选判定: Slicer_Time_Frame[TimeFrame_ID] ∈ {"Month","Year"}
    //     且 Slicer_Time_Frame_Min[TimeFrame_Value] = Slicer_Time_Frame_Max[TimeFrame_Value]
    //   - 跨财年判定: TimeFrame_ID ∈ {"Month","Quarter"} 时比较 Min/Max TimeFrame_Value 年部分
    //   - Customer% TAR ACH% 系列（Metric_ID=9/10）额外要求 Store 单选
    //   - 非触发场景:
    //     * Metric_ID=4: Quarter/Year 粒度 → BLANK
    //     * Metric_ID=5: Month 跨财年 / Quarter 跨财年 → BLANK
    //     * Metric_ID=9: 非 Month 单选 / Store 未单选 → BLANK
    //     * Metric_ID=10: 非 Month/Year 单选 / Store 未单选 / 跨财年 → BLANK
    // 目标值字段与聚合方式（按指标区分）:
    //   - Metric_ID=4 (Customer Monthly TAR ACH%): SUM(new_customer_cnt)
    //   - Metric_ID=5 (Customer Yearly TAR ACH%): SUM(DISTINCT year_new_customer_cnt)
    //     实现: SUMX(SUMMARIZE(table, [platform], [shop_info_id], [year_new_customer_cnt]), [year_new_customer_cnt])
    //   - Metric_ID=9 (Customer% Monthly TAR ACH%): SUM(new_customer_percent)
    //   - Metric_ID=10 (Customer% Yearly TAR ACH%): SUM(DISTINCT year_new_customer_percent)
    //     实现: SUMX(SUMMARIZE(table, [platform], [shop_info_id], [year_new_customer_percent]), [year_new_customer_percent])
    // 实际值取数（复用 Act Base Value，按 Metric_ID 分支）:
    //   - Metric_ID=4/5: DCom New Customer No. Act（Metric_ID=1）
    //   - Metric_ID=9/10: DCom New Customer% Act（Metric_ID=6）
    // ═══════════════════════════════════════
    VAR __IsTARACH = __MetricID IN {4, 5, 9, 10}

    // ── 时间粒度判定 ──
    VAR __TimeFrameID = SELECTEDVALUE(Slicer_Time_Frame[TimeFrame_ID])
    VAR __TimeFrameValueMin = SELECTEDVALUE(Slicer_Time_Frame_Min[TimeFrame_Value])
    VAR __TimeFrameValueMax = SELECTEDVALUE(Slicer_Time_Frame_Max[TimeFrame_Value])

    // ── 单选判定：TimeFrame_ID ∈ {"Month","Year"} 且 Min/Max TimeFrame_Value 相等 ──
    VAR __IsMonthOrYear = __TimeFrameID IN {"Month", "Year"}
    VAR __IsSingleSelection =
        __IsMonthOrYear
        && NOT ISBLANK(__TimeFrameValueMin)
        && NOT ISBLANK(__TimeFrameValueMax)
        && __TimeFrameValueMin = __TimeFrameValueMax
    // ── 多选判定：非单选（Month/Year 多选也有值，针对 Metric_ID=4/5）──
    VAR __IsMultiSelection = NOT __IsSingleSelection

    // ── 跨财年判定：Month/Quarter 粒度下，比较 Min/Max TimeFrame_Value 的年部分 ──
    VAR __IsMonthOrQuarter = __TimeFrameID IN {"Month", "Quarter"}
    VAR __YearPartMin = LEFT(__TimeFrameValueMin, 4)
    VAR __YearPartMax = LEFT(__TimeFrameValueMax, 4)
    VAR __IsCrossFiscalYear =
        __IsMonthOrQuarter
        && NOT ISBLANK(__YearPartMin)
        && NOT ISBLANK(__YearPartMax)
        && __YearPartMin <> __YearPartMax

    // ── 目标值时间范围：data_date ∈ [__TimeMin, __TimeMax]（全局时间范围）──
    VAR __TimeMin = SELECTEDVALUE(Slicer_Time_Frame_Min[TimeFrame_Min])
    VAR __TimeMax = SELECTEDVALUE(Slicer_Time_Frame_Max[TimeFrame_Max])

    // ── Customer% TAR ACH% 系列专用：Store 单选判定 ──
    VAR __StoreIDCount =
        CALCULATE(
            DISTINCTCOUNT(Slicer_Store_Name[Store_ID])
        )
    VAR __IsSingleStore = __StoreIDCount = 1

    // ── 各 TAR ACH% 触发条件判定（按最新口径文档）──
    // Metric_ID=4: Customer Monthly TAR ACH%
    //   - Month 单选/多选/跨财年都有值
    //   - Quarter/Year 任意范围留空
    VAR __Trigger_MonthlyTAR_CustomerNo =
        (__TimeFrameID = "Month")   // 仅 Month 粒度有值（单选/多选/跨财年都计算）
    // Metric_ID=5: Customer Yearly TAR ACH%
    //   - Month 单选/多选不跨财年有值，跨财年留空
    //   - Quarter 单选/多选不跨财年有值，跨财年留空
    //   - Year 单选/多选都有值
    VAR __Trigger_YearlyTAR_CustomerNo =
        SWITCH(
            __TimeFrameID,
            "Month",    NOT __IsCrossFiscalYear,                          // Month 不跨财年有值
            "Quarter",  NOT __IsCrossFiscalYear,                          // Quarter 不跨财年有值
            "Year",     TRUE(),                                           // Year 任意选择范围都有值
            FALSE()                                                       // 其他粒度留空
        )
    // Metric_ID=9: Customer% Monthly TAR ACH%
    //   - 仅 Month 单选 + Store 单选有值
    VAR __Trigger_MonthlyTAR_CustomerPct =
        __TimeFrameID = "Month"
        && __IsSingleSelection
        && __IsSingleStore
    // Metric_ID=10: Customer% Yearly TAR ACH%
    //   - Month 单选 + Store 单选有值
    //   - Year 单选 + Store 单选有值
    //   - 其他留空
    VAR __Trigger_YearlyTAR_CustomerPct =
        __IsSingleSelection
        && __IsSingleStore
        && (
            __TimeFrameID = "Month"
            || __TimeFrameID = "Year"
        )

    // ── 目标值计算（按 Metric_ID 路由到对应字段与聚合方式）──
    // Metric_ID=4: Customer Monthly TAR ACH% → SUM(new_customer_cnt)
    VAR __Target_MonthlyNewCustomerCnt =
        IF(
            __IsTARACH && __MetricID = 4 && __Trigger_MonthlyTAR_CustomerNo,
            CALCULATE(
                SUM('a03_e2e_customer_fcst_data_m'[new_customer_cnt]),
                'a03_e2e_customer_fcst_data_m'[data_date] >= __TimeMin,
                'a03_e2e_customer_fcst_data_m'[data_date] <= __TimeMax
            )
        )

    // Metric_ID=5: Customer Yearly TAR ACH% → SUM(DISTINCT year_new_customer_cnt)
    //   year_* 字段为年度目标值，按 platform/shop_info_id 分组后每个 shop 同年唯一
    //   实现方式: SUMMARIZE 按 platform/shop_info_id/year_new_customer_cnt 分组去重，再 SUMX 求和
    VAR __Target_YearlyNewCustomerCnt =
        IF(
            __IsTARACH && __MetricID = 5 && __Trigger_YearlyTAR_CustomerNo,
            CALCULATE(
                SUMX(
                    SUMMARIZE(
                        'a03_e2e_customer_fcst_data_m',
                        'a03_e2e_customer_fcst_data_m'[platform],
                        'a03_e2e_customer_fcst_data_m'[shop_info_id],
                        'a03_e2e_customer_fcst_data_m'[year_new_customer_cnt]
                    ),
                    'a03_e2e_customer_fcst_data_m'[year_new_customer_cnt]
                ),
                'a03_e2e_customer_fcst_data_m'[data_date] >= __TimeMin,
                'a03_e2e_customer_fcst_data_m'[data_date] <= __TimeMax
            )
        )

    // Metric_ID=9: Customer% Monthly TAR ACH% → SUM(new_customer_percent)
    VAR __Target_MonthlyNewCustomerPct =
        IF(
            __IsTARACH && __MetricID = 9 && __Trigger_MonthlyTAR_CustomerPct,
            CALCULATE(
                SUM('a03_e2e_customer_fcst_data_m'[new_customer_percent]),
                'a03_e2e_customer_fcst_data_m'[data_date] >= __TimeMin,
                'a03_e2e_customer_fcst_data_m'[data_date] <= __TimeMax
            )
        )

    // Metric_ID=10: Customer% Yearly TAR ACH% → DISTINCT(year_new_customer_percent)
    //   百分比目标值，无 SUM；仅 Store 单选时有值
    //   按 platform/shop_info_id 分组后 DISTINCT 取值（同 shop 同年唯一）
    VAR __Target_YearlyNewCustomerPct =
        IF(
            __IsTARACH && __MetricID = 10 && __Trigger_YearlyTAR_CustomerPct,
            CALCULATE(
                DISTINCT('a03_e2e_customer_fcst_data_m'[year_new_customer_percent]),
                'a03_e2e_customer_fcst_data_m'[data_date] >= __TimeMin,
                'a03_e2e_customer_fcst_data_m'[data_date] <= __TimeMax
            )
        )

    // ── 实际值取数（复用 Act Base Value，按 Metric_ID 分支）──
    // 实际值 Metric_ID 映射（严格遵循口径文档"实际值"字段）:
    //   - Metric_ID=4/5 (Customer No. TAR ACH%): DCom New Customer No. Act（Metric_ID=1）
    //   - Metric_ID=9/10 (Customer% TAR ACH%): DCom New Customer% Act（Metric_ID=6）
    VAR __ActMetricID_ForTAR =
        SWITCH(__MetricID,
            4, 1,    // Customer Monthly TAR ACH% → DCom New Customer No. Act
            5, 1,    // Customer Yearly TAR ACH% → DCom New Customer No. Act
            9, 6,    // Customer% Monthly TAR ACH% → DCom New Customer% Act
            10, 6    // Customer% Yearly TAR ACH% → DCom New Customer% Act
        )

    // 取实际值（REMOVEFILTERS 清除断开维度筛选，再应用目标 Metric_ID）
    // 触发条件分别判定，避免非触发场景下浪费计算
    VAR __ActualValue_ForTAR =
        IF(
            __IsTARACH
            && SWITCH(__MetricID,
                4,  __Trigger_MonthlyTAR_CustomerNo,
                5,  __Trigger_YearlyTAR_CustomerNo,
                9,  __Trigger_MonthlyTAR_CustomerPct,
                10, __Trigger_YearlyTAR_CustomerPct,
                FALSE()
            ),
            CALCULATE(
                [Customer KPIs Act Base Value],
                REMOVEFILTERS('Dim_ColMetric_Customer_KPIs'),
                'Dim_ColMetric_Customer_KPIs'[Metric_ID] = __ActMetricID_ForTAR
            )
        )

    // ── TAR ACH% 计算：实际值 / 目标值 ──
    //   非触发场景 → BLANK()
    VAR __TARACH_MonthlyNewCustomer =
        IF(
            __MetricID = 4 && __Trigger_MonthlyTAR_CustomerNo,
            DIVIDE(__ActualValue_ForTAR, __Target_MonthlyNewCustomerCnt)
        )
    VAR __TARACH_YearlyNewCustomer =
        IF(
            __MetricID = 5 && __Trigger_YearlyTAR_CustomerNo,
            DIVIDE(__ActualValue_ForTAR, __Target_YearlyNewCustomerCnt)
        )
    VAR __TARACH_MonthlyNewCustomerPct =
        IF(
            __MetricID = 9 && __Trigger_MonthlyTAR_CustomerPct,
            DIVIDE(__ActualValue_ForTAR, __Target_MonthlyNewCustomerPct)
        )
    VAR __TARACH_YearlyNewCustomerPct =
        IF(
            __MetricID = 10 && __Trigger_YearlyTAR_CustomerPct,
            DIVIDE(__ActualValue_ForTAR, __Target_YearlyNewCustomerPct)
        )

    RETURN
        SWITCH(
            __MetricID,
            // ─── Act 本期值 ───
            1,  [Customer KPIs Act Base Value],                    // DCom New Customer No. Act
            6,  [Customer KPIs Act Base Value],                    // DCom New Customer% Act
            // ─── 数量类 vs LY 派生（今年 / 去年 - 1）───
            2,  __QtyVsLYResult,                                    // DCom New Customer No. vs LY
            // ─── 数量类 vs LP 派生（当期 / 上期 - 1）───
            3,  __QtyVsLPResult,                                    // DCom New Customer No. vs LP
            // ─── 比率类 vs LY / vs LP（差值，×100 转 pts 在 Cell Display 实现）───
            7,  __PctVsLYResult,                                    // DCom New Customer% vs LY
            8,  __PctVsLPResult,                                    // DCom New Customer% vs LP
            // ─── TAR ACH% Monthly（实际值 / 月度目标值）───
            //   Metric_ID=4: Month 单选/多选/跨财年都有值；Quarter/Year 留空
            4,  __TARACH_MonthlyNewCustomer,                       // Customer Monthly TAR ACH%
            // ─── TAR ACH% Yearly（实际值 / 年度目标值）───
            //   Metric_ID=5: Month/Quarter 不跨财年有值；Year 任意范围有值；跨财年留空
            5,  __TARACH_YearlyNewCustomer,                        // Customer Yearly TAR ACH%
            // ─── Customer% TAR ACH% Monthly（实际值 / 月度占比目标值）───
            //   Metric_ID=9: 仅 Month 单选 + Store 单选有值
            9,  __TARACH_MonthlyNewCustomerPct,                    // Customer% Monthly TAR ACH%
            // ─── Customer% TAR ACH% Yearly（实际值 / 年度占比目标值）───
            //   Metric_ID=10: Month 单选 + Store 单选 / Year 单选 + Store 单选 有值
            10, __TARACH_YearlyNewCustomerPct,                     // Customer% Yearly TAR ACH%
            BLANK()
        )
```

### 4.6 Customer KPIs Cell Value（对外值）

```dax
Customer KPIs Cell Value =
// ========================================
// 度量值: Customer KPIs Cell Value
// Display Folder: Cell Values
// 用途: 对外暴露的单元格值，等于 Base Value
// 依赖: [Customer KPIs Base Value]
// ========================================
    [Customer KPIs Base Value]
```

### 4.7 Customer KPIs Cell Display（格式化显示，按 Metric_Format 单字段分发）

```dax
Customer KPIs Cell Display =
// ========================================
// 度量值: Customer KPIs Cell Display
// Display Folder: Formatting
// 用途: 按 Metric_Format 单字段格式化显示
// 依赖: [Customer KPIs Cell Value],
//       'Dim_ColMetric_Customer_KPIs'[Metric_Format]
// 格式类型（严格遵循口径文档数据类型定义）:
//   integer       → 千分位整数：1,000
//   percent_1dp   → 百分比一位小数不含正号：14.5%
//                   （DCom New Customer% Act / 4 个 TAR ACH%）
//   delta_pct_1dp → 百分比变化含正号：+14.5% / -3.2%
//                   （数量类 vs LY / vs LP：Customer No. 系列 Metric_ID=2/3）
//   delta_pts     → 增减基点整数含正负号：+120pts / -80pts / 0pts
//                   （比率类 vs LY / vs LP：Customer% 系列 Metric_ID=7/8，值×100 转 pts 在此处实现）
// 说明:
//   - BLANK 显示为 "-"
//   - 已扩展百分比整数等格式，便于后续快速调整
// ========================================
    VAR __Value = [Customer KPIs Cell Value]
    VAR __Format = SELECTEDVALUE('Dim_ColMetric_Customer_KPIs'[Metric_Format])

    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            SWITCH(
                __Format,
                // ─── 整数（千分位）────────────────────────────────
                "integer",
                    FORMAT(__Value, "#,##0"),                                                                          // 1,000
                // ─── 百分比一位小数不含正号 ──────────────────────
                "percent_1dp",
                    FORMAT(__Value, "#,##0.0%"),                                                                        // 14.5%
                // ─── 百分比变化含正号（数量类 vs LY / vs LP）─────
                "delta_pct_1dp",
                    IF(__Value > 0, "+", "") & FORMAT(__Value, "#,##0.0%"),                                             // +14.5% / -3.2%
                // ─── 增减基点整数（比率类 vs LY / vs LP，×100 转 pts）─
                "delta_pts",
                    IF(ROUND(__Value * 100, 0) > 0, "+", "") & FORMAT(__Value * 100, "#,##0pts;-#,##0pts;0pts"),        // +120pts / -80pts / 0pts
                // ─── 扩展格式（便于后续快速调整）─────────────────
                "percent_0dp",
                    FORMAT(__Value, "#,##0%"),                                                                          // 15%
                "percent_0dp_signed",
                    IF(__Value > 0, "+", "") & FORMAT(__Value, "#,##0%;-#,##0%;0%"),                                    // +15% / -3% / 0%
                "percent_2dp",
                    FORMAT(__Value, "#,##0.00%"),                                                                       // 14.50%
                "delta_pct_2dp",
                    IF(__Value > 0, "+", "") & FORMAT(__Value, "#,##0.00%"),                                            // +14.50%
                "delta_pts_2dp",
                    IF(ROUND(__Value * 100, 2) > 0, "+", "") & FORMAT(__Value * 100, "#,##0.00pts;-#,##0.00pts;0.00pts"), // +120.50pts
                "delta_bp",
                    IF(ROUND(__Value * 10000, 0) > 0, "+", "") & FORMAT(__Value * 10000, "#,##0bp;-#,##0bp;0bp"),       // +1200bp
                // ─── 默认 ─────────────────────────────────
                FORMAT(__Value, "#,##0.00")
            )
        )
```

### 4.8 Customer KPIs Cell Font Color（字体颜色，按 Metric_ColorRule 分发）

```dax
Customer KPIs Cell Font Color =
// ========================================
// 度量值: Customer KPIs Cell Font Color
// Display Folder: Formatting
// 用途: 按 Metric_ColorRule 字段分发字体颜色
// 依赖: [Customer KPIs Cell Value],
//       'Dim_ColMetric_Customer_KPIs'[Metric_ColorRule, Metric_ColorPositive/Negative/Zero/Default]
//
// 颜色规则（口径文档要求）:
//   1. Customer No. Act（Metric_ID=1）固定 #252423
//      → Metric_ColorRule = "fixed_black"
//   2. 涉及 vs LY、vs LP、TAR ACH% 的指标使用列维度表的颜色取值字段判断大小（正/负/零三色）
//      → Metric_ColorRule = "pos_neg_zero"
//   3. Customer% Act（Metric_ID=6）使用列指标维度中的 Metric_ColorDefault 默认颜色
//      → Metric_ColorRule = "fixed_default"
// ========================================
    VAR __Value = [Customer KPIs Cell Value]
    VAR __ColorRule = SELECTEDVALUE('Dim_ColMetric_Customer_KPIs'[Metric_ColorRule], "fixed_default")
    // ── 颜色取值（来自列维度表）──
    VAR __ColorPositive = SELECTEDVALUE('Dim_ColMetric_Customer_KPIs'[Metric_ColorPositive], "#1A9018")
    VAR __ColorNegative = SELECTEDVALUE('Dim_ColMetric_Customer_KPIs'[Metric_ColorNegative], "#D64550")
    VAR __ColorZero = SELECTEDVALUE('Dim_ColMetric_Customer_KPIs'[Metric_ColorZero], "#E1C233")
    VAR __ColorDefault = SELECTEDVALUE('Dim_ColMetric_Customer_KPIs'[Metric_ColorDefault], "#5F6165")

    RETURN
        SWITCH(
            __ColorRule,
            // ─── 固定黑色（Customer No. Act）───
            "fixed_black",
                "#252423",
            // ─── 正/负/零三色（vs LY / vs LP / TAR ACH%）───
            "pos_neg_zero",
                SWITCH(
                    TRUE(),
                    ISBLANK(__Value), __ColorDefault,
                    __Value > 0,      __ColorPositive,
                    __Value < 0,      __ColorNegative,
                    __Value = 0,      __ColorZero,
                    __ColorDefault
                ),
            // ─── 默认颜色（Customer% Act）───
            "fixed_default",
                __ColorDefault,
            // ─── 兜底 ───
            __ColorDefault
        )
```

### 4.9 Customer KPIs Cell Background Color（背景色）

```dax
Customer KPIs Cell Background Color =
// ========================================
// 度量值: Customer KPIs Cell Background Color
// Display Folder: Formatting
// 用途: 区分 KPIGroup 行（分组标题行）与 KPI 行的背景色
// 依赖: ISINSCOPE('Dim_ColMetric_Customer_KPIs'[ColName])
// 颜色规则:
//   KPIGroup 行（分组标题行）: #E6D9C7（中米色）
//   KPI 行（具体指标行）     : #FFFFFF（白色）
// ========================================
    VAR __IsKPIRow = ISINSCOPE('Dim_ColMetric_Customer_KPIs'[ColName])
    RETURN
        IF(
            __IsKPIRow,
            "#FFFFFF",   // KPI 行：白色
            "#E6D9C7"    // KPIGroup 行：中米色
        )
```

---

## 5. 度量值清单与 Display Folder

| 序号 | 度量值名称 | Display Folder | 用途 |
| --- | --- | --- | --- |
| 1 | Customer KPIs Act Base Value | Base Metrics | 本期基础值（合并区间 DISTINCTCOUNT）；Metric_ID=6 返回 DCom New Customer% 比率 |
| 2 | Customer KPIs LY Base Value | Base Metrics | 去年同期基础值（区间对称映射 TimeFrame_*_LY） |
| 3 | Customer KPIs LP Base Value | Base Metrics | 上期基础值（区间对称映射 TimeFrame_*_LP） |
| 4 | Customer KPIs Base Value | Base Metrics | 总路由（含 vs LY / vs LP / TAR ACH% Monthly / TAR ACH% Yearly 派生 + REMOVEFILTERS）；TAR ACH% = 实际值(Act Base Value) / 目标值(a03_e2e_customer_fcst_data_m)，按口径文档触发条件判定 |
| 5 | Customer KPIs Cell Value | Cell Values | 对外值 = Base Value |
| 6 | Customer KPIs Cell Display | Formatting | 格式化显示文本（按 Metric_Format 单字段分发） |
| 7 | Customer KPIs Cell Font Color | Formatting | 字体颜色（按 Metric_ColorRule 分发） |
| 8 | Customer KPIs Cell Background Color | Formatting | 背景色（KPIGroup 行 vs KPI 行） |

---

## 6. 血缘关系图

```
┌─────────────────────────────────────────────────────────────────────┐
│                        数据源层                                      │
│  a03_e2e_customer_data_m（月度事实表）                               │
│  字段: data_date, platform, shop_info_id, user_id, is_member,       │
│        net_pay_amt, lp_12m_net_pay_amt                              │
│                                                                     │
│  a03_e2e_customer_fcst_data_m（月度目标值事实表）                    │
│  字段: data_date, platform, shop_info_id,                          │
│        new_customer_cnt, new_customer_percent,                      │
│        year_new_customer_cnt, year_new_customer_percent             │
└──────────────────────────────┬──────────────────────────────────────┘
                               │
                               │ 模型自动传递（行维度 = 事实表字段直接拉取）
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────────┐
│                        度量值层                                      │
│                                                                     │
│  ┌───────────────────────┐   ┌───────────────────────┐              │
│  │ Customer KPIs         │   │ Customer KPIs         │              │
│  │ Act Base Value        │   │ LY Base Value         │              │
│  │ (本期区间聚合)         │   │ (区间对称映射 LY)     │              │
│  │ Metric_ID=1: 合并区间 │   │                       │              │
│  │   (start_period ∩     │   │                       │              │
│  │    net_pay_amt>0 ∩    │   │                       │              │
│  │    is_member=0 ∩      │   │                       │              │
│  │    lp_12m_net_pay_=0)│   │                       │              │
│  │ Metric_ID=6: 比率     │   │                       │              │
│  └───────────┬───────────┘   └───────────┬───────────┘              │
│              │                           │                          │
│  ┌───────────────────────┐               │                          │
│  │ Customer KPIs         │               │                          │
│  │ LP Base Value         │               │                          │
│  │ (区间对称映射 LP)     │               │                          │
│  └───────────┬───────────┘               │                          │
│              │                            │                          │
│              ▼                            ▼                          │
│  ┌───────────────────────────────────┐   ┌───────────────────────┐  │
│  │ Customer KPIs Base Value          │   │ Dim_ColMetric_         │  │
│  │ (总路由 + 派生计算)                │   │ Customer_KPIs         │  │
│  │ REMOVEFILTERS + 目标 Metric_ID    │   │ (断开维度, Metric_ID) │  │
│  │ vs LY / vs LP / TAR ACH% Monthly /│   └───────────────────────┘  │
│  │ TAR ACH% Yearly                   │                              │
│  │ TAR ACH% = Act Base Value /       │                              │
│  │   a03_e2e_customer_fcst_data_m    │                              │
│  └───────────────┬───────────────────┘                              │
│                  │                                                  │
│                  ▼                                                  │
│  ┌───────────────────────────────────┐                              │
│  │ Customer KPIs Cell Value          │                              │
│  │ (= Base Value)                    │                              │
│  └───────────────┬───────────────────┘                              │
│                  │                                                  │
│                  ▼                                                  │
│  ┌───────────────────────────────────┐   ┌───────────────────────┐  │
│  │ Customer KPIs Cell Display        │◄──│ Dim_ColMetric_         │  │
│  │ (按 Metric_Format 单字段格式化)    │   │ Customer_KPIs         │  │
│  └───────────────┬───────────────────┘   │ (Metric_Format)       │  │
│                  │                       └───────────────────────┘  │
│                  ▼                                                  │
│  ┌─────────────────────────────────────────────────────┐            │
│  │  Customer KPIs Cell Font Color                       │            │
│  │  Customer KPIs Cell Background Color                 │            │
│  │  (条件格式度量值，按 Metric_ColorRule 调度颜色)      │            │
│  └─────────────────────────────────────────────────────┘            │
└─────────────────────────────────────────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────────┐
│                        可视化层                                      │
│  Matrix 视觉对象                                                     │
│  行: 事实表字段（platform / shop_info_id，直接拉取）                  │
│  列: 'Dim_ColMetric_Customer_KPIs'[KPIGroup] > [ColName]            │
│  值: [Customer KPIs Cell Display]                                    │
│  条件格式:                                                           │
│    字体颜色 → [Customer KPIs Cell Font Color]                        │
│    背景色   → [Customer KPIs Cell Background Color]                   │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 7. 注意事项

1. **实际值时间口径**：实际值取数按**所选时间范围区间聚合**（`data_date ∈ [Slicer_Time_Frame_Min[TimeFrame_Min], Slicer_Time_Frame_Max[TimeFrame_Max]]`）。分母（DCom New Customer% 的全部 user_id）按本期区间聚合；分子（DCom New Customer No.）按 start_period（第一个财月）区间聚合。
2. **DCom 新客判定 Step1 + Step2 合并区间实现**：
   - 由于 start_period（第一个财月）是 slicer 区间的子集，技术实现上可"合并区间"
   - 用于判断 `lp_12m_net_pay_amt = 0` 的行一定也在 slicer 区间内
   - 技术实现直接等价于单一筛选：`data_date ∈ start_period AND net_pay_amt > 0 AND is_member = 0 AND lp_12m_net_pay_amt = 0`
   - DAX 用单一 `CALCULATE(DISTINCTCOUNT(user_id), <四条件>)` 实现，无需 INTERSECT 两张表集合
   - start_period 时间范围：`data_date ∈ [First_Fiscal_Month_Min, First_Fiscal_Month_Max]`（第一个财月区间）
3. **字段名**：严格按口径文档使用 `lp_12m_net_pay_amt`（已在 a03_e2e_customer_data_m 数据字典中扩展）。
4. **vs LY / vs LP 区间对称映射**：本期区间 = `[Slicer_Time_Frame_Min[TimeFrame_Min], Slicer_Time_Frame_Max[TimeFrame_Max]]`，LY/LP 区间按对称原则构造（起始端读 Min 切片器 LY/LP，结束端读 Max 切片器 LY/LP）：
   - LY 区间 = `[Slicer_Time_Frame_Min[TimeFrame_Min_LY], Slicer_Time_Frame_Max[TimeFrame_Max_LY]]`
   - LP 区间 = `[Slicer_Time_Frame_Min[TimeFrame_Min_LP], Slicer_Time_Frame_Max[TimeFrame_Max_LP]]`
   - start_period LY/LP 区间同理：`[First_Fiscal_Month_Min_LY/Max_LY, First_Fiscal_Month_Min_LP/Max_LP]`
5. **REMOVEFILTERS 机制**：派生指标（vs LY / vs LP / TAR ACH%）的取值必须先 `REMOVEFILTERS('Dim_ColMetric_Customer_KPIs')` 再应用目标 Metric_ID，否则矩阵行标题保留的筛选器会导致冲突返回 BLANK。
6. **TAR ACH% 完整取数逻辑（实际值 / 目标值）**：Metric_ID 4, 5, 9, 10 为目标达成率指标，公式 = 实际值 / 目标值。
   - **实际值**：复用 Act Base Value（REMOVEFILTERS + 目标 Metric_ID）
     - Metric_ID=4/5：DCom New Customer No. Act（Metric_ID=1）
     - Metric_ID=9/10：DCom New Customer% Act（Metric_ID=6）
   - **目标值**：取自 `a03_e2e_customer_fcst_data_m`，日期字段 `data_date`
     - 时间范围：`data_date ∈ [Slicer_Time_Frame_Min[TimeFrame_Min], Slicer_Time_Frame_Max[TimeFrame_Max]]`（全局时间范围，与实际值同区间）
     - **无 is_member / is_employee 筛选**
     - 行维度 platform / shop_info_id 通过共享维度表自动传递
     - 字段与聚合方式：
       - Metric_ID=4：`SUM(new_customer_cnt)`（月度目标值）
       - Metric_ID=5：`SUM(DISTINCT year_new_customer_cnt)`（年度目标值，按 platform/shop_info_id 分组 DISTINCT 后 SUM，用 SUMMARIZE 等价实现）
       - Metric_ID=9：`SUM(new_customer_percent)`（月度占比目标值）
       - Metric_ID=10：`SUM(DISTINCT year_new_customer_percent)`（年度占比目标值，按 platform/shop_info_id 分组 DISTINCT 后 SUM，用 SUMMARIZE 等价实现）
7. **TAR ACH% 触发条件（按最新口径文档调整）**：
   - **单选判定**：`Slicer_Time_Frame[TimeFrame_ID] ∈ {"Month", "Year"}` 且 `Slicer_Time_Frame_Min[TimeFrame_Value] = Slicer_Time_Frame_Max[TimeFrame_Value]`
   - **跨财年判定**：`Slicer_Time_Frame[TimeFrame_ID] ∈ {"Month", "Quarter"}` 时比较 `LEFT(Slicer_Time_Frame_Min[TimeFrame_Value], 4)` 与 `LEFT(Slicer_Time_Frame_Max[TimeFrame_Value], 4)` 的年部分，不相等 → 跨财年
   - **Customer% TAR ACH% 系列**（Metric_ID=9/10）额外要求 `Slicer_Store_Name[Store_ID]` 单选（DISTINCTCOUNT = 1）
   - **非触发场景**（留空 BLANK，按最新口径文档）：
     - Metric_ID=4（Customer Monthly TAR ACH%）：Quarter / Year 粒度 → BLANK（Month 任意选择范围都有值，含多选和跨财年）
     - Metric_ID=5（Customer Yearly TAR ACH%）：Month 跨财年 / Quarter 跨财年 → BLANK（Month 不跨财年有值；Quarter 不跨财年有值；Year 任意选择范围有值）
     - Metric_ID=9（Customer% Monthly TAR ACH%）：非 Month 单选 / Store 未单选 → BLANK（仅 Month 单选 + Store 单选有值）
     - Metric_ID=10（Customer% Yearly TAR ACH%）：非 Month/Year 单选 / Store 未单选 / 跨财年 → BLANK（Month 单选 + Store 单选 / Year 单选 + Store 单选 有值）
8. **行维度处理**：无行维度表，直接拉取事实表字段（`platform` / `shop_info_id`），天然形成筛选与分组，DAX 度量值无需显式处理。模型自动传递筛选，支持 platform 粒度行展开看 shop_info_id 粒度明细数据。
9. **单一 Metric_Format 字段**：列指标维度表仅保留单个 `Metric_Format` 字段（不再区分 Act/LY/VsLY），因为每个指标对应一个格式。行格式严格遵循口径文档数据类型定义。
10. **扩展格式支持**：Cell Display 已扩展 `percent_0dp` / `percent_0dp_signed` / `percent_2dp` / `delta_pct_2dp` / `delta_pts_2dp` / `delta_bp` 等格式，便于后续快速调整。如需新增指标使用扩展格式，只需在 `Dim_ColMetric_Customer_KPIs` 的 `Metric_Format` 字段填入对应格式值即可。
