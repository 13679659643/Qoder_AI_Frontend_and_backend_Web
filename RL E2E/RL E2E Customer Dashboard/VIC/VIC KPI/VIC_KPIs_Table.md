# Power BI 解决方案 — VIC KPIs 矩阵（SWITCH 路由）

> status: ready
> created: 2026-08-12
> revised: 2026-08-12（格式统一 + Rolling 12 分母修正）
> type: 度量值开发 + 可视化构建
> 口径来源: 口径文档/VIC KPI.md（子模块一 VIC KPI，5 个 KPI 分组共 28 列指标）
> 参考实现: PB_Merchandise_Fulfillment_detail_ms.md（总路由 REMOVEFILTERS 范式）
> 列指标维度表: Dim_ColMetric_VIC_KPIs（28 行，5 个 KPI 分组）

---

## 1. 需求理解

为 Customer Dashboard - VIC Tab 实现 VIC KPI 矩阵：

- **行**：无行维度表，直接拉取事实表字段（`platform` / `shop_info_id`），天然实现行维度分组和筛选，DAX 无需显式处理
- **列**：`Dim_ColMetric_VIC_KPIs` 的两级层级 `KPIGroup`（父）> `ColName`（子）
  - 5 个 KPI 分组：VIC No. / VIC Retention% / T4-5 Upgrade No. / Retention VIC No. / Direct VIC No.
  - 共 28 列指标
- **值**：SWITCH 动态路由，按 `Metric_ID` 分发到 Act / vs LY / vs LP / TAR ACH% / Share / Share vs LY / Share vs LP
- **口径**：一切以口径文档 VIC KPI.md 为准
- **筛选器**：
  - Slicer_Time_Frame_Max（断开维度，读取 `Last_Fiscal_Month_*` 系列字段 → end period 时间范围）
  - Slicer_Time_Frame_Min（断开维度，end period 逻辑只需要 Max；Min 仅用于辅助）
  - Slicer_Is_Employee_Selection（断开维度，筛选 `is_employee`）
  - IsMemberFilter（断开维度，筛选 `is_member`）
  - Slicer_Platform_Selection / Slicer_Store_Name（断开维度，行维度直接拉事实表字段实现自动传递）
  - Slicer_Currency_Selection（断开维度，本方案无金额类指标，不参与汇率换算）

### 1.1 关键特殊逻辑一：end period 时间范围

口径文档明确要求：
> **聚合粒度**: `dt = 所选时间范围 end period`，`platform, shop_info_id`
> **end period 说明**: 所选时间范围的最后一个财月，只关注 Slicer_Time_Frame_Max 值
>   - 月：2026-09 → 只关注 2026-09
>   - 季：2026 Q2 → 只关注 2026-06
>   - 年：财年 2026 → 只关注 2026-12

`Slicer_Time_Frame_Max` 已内置 `Last_Fiscal_Month` 字段及对应的 7 个时间字段（`Last_Fiscal_Month_Min/Max/Min_LY/Max_LY/Min_LP/Max_LP`），直接获取用于筛选事实表的时间范围。

### 1.2 关键特殊逻辑二：is_member / is_employee 双重人群筛选

口径文档要求：
> **is_member 使用**: `VAR __IsMemberFilter = SELECTEDVALUE(IsMemberFilter[IsMember], 0)`，默认 TTL VIC
> **is_employee 使用**: `VAR __IsEmployeeFilter = SELECTEDVALUE(Slicer_Is_Employee_Selection[IsEmployee_Code], 1)`，默认 Yes

所有指标（除特殊说明外）都需要应用这两个筛选到事实表 `a03_e2e_customer_data_m[is_member]` / `[is_employee]`。

### 1.3 关键特殊逻辑三：派生指标分类

| 派生类型 | 计算方式 | 数据格式 |
|---------|---------|---------|
| **vs LY**（数量类 VIC No. / T4-5 Upgrade No. / Direct VIC No.） | 今年 / 去年 - 1 | `delta_pct_1dp`（含正号） |
| **vs LP**（数量类） | 当期 / 上期 - 1 | `delta_pct_1dp`（含正号） |
| **vs LY**（VIC Retention% / Share 类） | 今年 - 去年（差值，×100 转 pts） | `delta_pts` |
| **vs LP**（VIC Retention% / Share 类） | 当期 - 上期（差值，×100 转 pts） | `delta_pts` |
| **TAR ACH%** | 占位值 1 | `percent_1dp`（不含正号） |
| **Retention VIC No. vs LY**（数量类特殊） | 今年 / 去年 - 1 | `percent_1dp`（不含正号，口径文档 4.1 明确） |

### 1.4 关键特殊逻辑四：VIC Retention% 的 Rolling 12 个财月分母（仅此指标使用）

口径文档 2. VIC Retention% 明确要求：
> **分母**: `user_id`（所选时间范围 end period 往前 Rolling 12 个财月 count(distinct user_id)，Rolling 12 个财月 = 当前月 + 往前 11 个月，共 12 个月、`is_vic = 1`）

**分母计算方式（区间 DISTINCT 汇总）**：在 Rolling 12 个财月区间内 `count(distinct user_id) where is_vic = 1`，同一用户只计一次（非按月 SUM 累加）。

**Rolling 12 个月区间起止日获取**：
- 区间结束日 = `Slicer_Time_Frame_Max[Last_Fiscal_Month_Max]`（end period 当月的自然日结束日）
- 区间起始日：用 `EDATE(Slicer_Time_Frame_Max[Last_Fiscal_Month_Min], -11)` 往前推 11 个月得到起始月（如 end period=2026-09，则起始月=2025-10），再用该月作为 `TimeFrame_Value` 去 `Slicer_Time_Frame_Max` 中匹配获取该月的 `TimeFrame_Min`（自然日起始日）
- 最终区间 = `[起始月 TimeFrame_Min, Last_Fiscal_Month_Max]`，共 12 个自然月

**适用范围**：仅 VIC Retention% 分组（Metric_ID 6/7/8）的分母使用此 Rolling 12 个月区间；其他分组（T4-5 Upgrade No. Share / Retention VIC No. Share / Direct VIC No. Share）的分母仍使用 end period 当月 `is_vic=1` 的人数。

**LY/LP 的 Rolling 12 区间**：同样逻辑应用 `Last_Fiscal_Month_*_LY` 和 `Last_Fiscal_Month_*_LP` 字段。

---

## 2. 现状分析

### 2.1 数据底表

| 对象 | 名称 | 出处 |
|------|------|------|
| 事实表 | a03_e2e_customer_data_m | VIC KPI.md 全局逻辑 |
| 关键字段 | data_date, platform, shop_info_id, user_id, is_member, is_employee, is_vic, is_retention_vic, is_upgrade_vic, is_direct_vic | VIC KPI.md 全部指标 |

> 表为月度聚合表（每用户每月一行），`data_date` 已在 Power Query 中通过 `LAST_DAY(DATE_SUB(STR_TO_DATE(CONCAT(data_month,'01'),'%Y%m%d'), INTERVAL 10 MONTH))` 计算得到月末日期。

### 2.2 维度表清单

| 维度表 | 类型 | 连接方式 |
|--------|------|---------|
| Slicer_Time_Frame_Max | 断开维度 | SELECTEDVALUE 读取 `Last_Fiscal_Month_Min/Max/Min_LY/Max_LY/Min_LP/Max_LP`；并支持通过 `TimeFrame_Value` 查找 Rolling 12 起始月的 `TimeFrame_Min` |
| Slicer_Time_Frame_Min | 断开维度 | 本方案 end period 逻辑不使用（仅 Max 即可） |
| Slicer_Is_Employee_Selection | 断开维度 | SELECTEDVALUE 读取 `IsEmployee_Code` |
| IsMemberFilter | 断开维度 | SELECTEDVALUE 读取 `IsMember` |
| Slicer_Platform_Selection | 断开维度 | 行维度直接拉事实表 platform 字段，模型自动传递 |
| Slicer_Store_Name | 断开维度 | 行维度直接拉事实表 shop_info_id 字段，模型自动传递 |
| Slicer_Currency_Selection | 断开维度 | 本方案无金额类指标，不参与计算 |
| Dim_ColMetric_VIC_KPIs | 断开维度 | SELECTEDVALUE 读取 `Metric_ID` / `ColType` / `Metric_Format` / `Metric_ColorRule` / 颜色字段 |

> **行维度处理**：`platform` / `shop_info_id` 直接拉取事实表字段实现自动传递，模型自动传递筛选，DAX 无需显式处理。

---

## 3. 方案设计

### 3.1 整体架构

```
核心思路：断开列维度 + SWITCH 动态路由（Disconnected Dimension + Dispatch Pattern）

Dim_ColMetric_VIC_KPIs（断开维度，列头）
    │
    │  无关系连接，仅通过 SELECTEDVALUE 读取：
    │  - Metric_ID, ColType, KPIGroup, ColName
    │  - Metric_Format, Metric_ColorRule
    │  - Metric_ColorPositive/Negative/Zero/Default
    │
    ▼
    ┌─────────────────────────── Matrix 视觉对象 ──────────────────────────┐
    │  行 = 事实表字段（platform / shop_info_id）                          │
    │  列 = 'Dim_ColMetric_VIC_KPIs'[KPIGroup] > [ColName]                │
    │  值 = [VIC KPIs Cell Display]                                       │
    └────────────────────────────────────────────────────────────────────────┘
                                   ▲
                                   │
              SWITCH 动态路由度量值链（按 Metric_ID 分发）
              ┌────────────────────────────────────────────────────┐
              │  [VIC KPIs Cell Value]                             │
              │    └→ [VIC KPIs Base Value]（总路由）              │
              │         ├→ [VIC KPIs Act Base Value]（本期值）     │
              │         ├→ [VIC KPIs LY Base Value]（去年同期值）  │
              │         ├→ [VIC KPIs LP Base Value]（上期值）      │
              │         ├→ [VIC KPIs Rolling12 VIC Denominator]    │
              │         │   （VIC Retention% 专用 Rolling 12 分母）│
              │         └→ 派生：vs LY / vs LP / TAR ACH% / Share  │
              │            （按 Metric_ID 路由到对应计算分支）     │
              └────────────────────────────────────────────────────┘
```

### 3.2 度量值模型设计

```
[VIC KPIs Act Base Value]              ← 本期基础值
                                       ← 按 Metric_ID 路由到对应字段的 DISTINCTCOUNT
                                       ← 统一应用 is_member / is_employee / end period 时间筛选
[VIC KPIs LY Base Value]               ← 去年同期基础值（财历映射 Last_Fiscal_Month_*_LY）
[VIC KPIs LP Base Value]               ← 上期基础值（财历映射 Last_Fiscal_Month_*_LP）
[VIC KPIs Rolling12 VIC Denominator]   ← VIC Retention% 专用 Rolling 12 个财月区间 is_vic=1 DISTINCT 汇总
                                       ← 支持本期 / LY / LP 三套时间范围
[VIC KPIs Base Value]                  ← 总路由（含 vs LY / vs LP / TAR ACH% / Share 派生）
                                       ← REMOVEFILTERS 清除断开维度筛选，再应用目标 Metric_ID
                                       ← VIC Retention% 分母调用 Rolling12 VIC Denominator
                                       ← Share 类分母调用 Act Base Value（end period 当月 is_vic=1）
[VIC KPIs Cell Value]                  ← 对外值 = Base Value
[VIC KPIs Cell Display]                ← 格式化显示文本（按 Metric_Format 单字段分发）
[VIC KPIs Cell Font Color]             ← 字体颜色（按 Metric_ColorRule 分发：fixed_black / pos_neg_zero / fixed_default）
```

### 3.3 筛选器上下文

| 筛选器 | 作用方式 | DAX 处理 |
|--------|---------|---------|
| Slicer_Time_Frame_Max | 断开维度，SELECTEDVALUE 读取 `Last_Fiscal_Month_Min/Max` | `data_date >= __PeriodMin AND data_date <= __PeriodMax` |
| Slicer_Time_Frame_Max（LY） | SELECTEDVALUE 读取 `Last_Fiscal_Month_Min_LY/Max_LY` | `data_date >= __LYMin AND data_date <= __LYMax` |
| Slicer_Time_Frame_Max（LP） | SELECTEDVALUE 读取 `Last_Fiscal_Month_Min_LP/Max_LP` | `data_date >= __LPMin AND data_date <= __LPMax` |
| Slicer_Time_Frame_Max（Rolling12 起始月） | EDATE 往前推 11 个月，再查 `TimeFrame_Min` | VIC Retention% 分母专用 |
| Slicer_Is_Employee_Selection | 断开维度，SELECTEDVALUE 读取 `IsEmployee_Code` | `a03_e2e_customer_data_m[is_employee] = __IsEmployeeFilter` |
| IsMemberFilter | 断开维度，SELECTEDVALUE 读取 `IsMember` | `a03_e2e_customer_data_m[is_member] = __IsMemberFilter` |
| 事实表分组字段 | 表格行直接拉取，模型自动传递筛选 | DAX 无需显式处理 |

### 3.4 vs LY / vs LP 时间偏移规则（财历映射）

直接读取 Slicer_Time_Frame_Max 内置的 `Last_Fiscal_Month_*` 系列字段：
- 本期：`Last_Fiscal_Month_Min` ~ `Last_Fiscal_Month_Max`
- LY：`Last_Fiscal_Month_Min_LY` ~ `Last_Fiscal_Month_Max_LY`
- LP：`Last_Fiscal_Month_Min_LP` ~ `Last_Fiscal_Month_Max_LP`
- 无需 EDATE -12 或 Key 偏移计算

### 3.5 vs LY / vs LP 派生计算分类

| Metric_ID | 指标 | 派生类型 | 计算方式 | Metric_Format |
|-----------|------|---------|---------|---------------|
| 2 | VIC No. vs LY | 数量类 vs LY | 今年 / 去年 - 1 | delta_pct_1dp |
| 3 | VIC No. vs LP | 数量类 vs LP | 当期 / 上期 - 1 | delta_pct_1dp |
| 7 | VIC Retention% vs LY | 比率类 vs LY | 今年 - 去年（差值） | delta_pts |
| 8 | VIC Retention% vs LP | 比率类 vs LP | 当期 - 上期（差值） | delta_pts |
| 11 | T4-5 Upgrade No. vs LY | 数量类 vs LY | 今年 / 去年 - 1 | delta_pct_1dp |
| 12 | T4-5 Upgrade No. vs LP | 数量类 vs LP | 当期 / 上期 - 1 | delta_pct_1dp |
| 15 | T4-5 Upgrade No. Share vs LY | 比率类 vs LY | 今年 - 去年（差值） | delta_pts |
| 16 | T4-5 Upgrade No. Share vs LP | 比率类 vs LP | 当期 - 上期（差值） | delta_pts |
| 18 | Retention VIC No. vs LY | 数量类 vs LY（特殊格式） | 今年 / 去年 - 1 | percent_1dp |
| 19 | Retention VIC No. vs LP | 数量类 vs LP | 当期 / 上期 - 1 | delta_pct_1dp |
| 21 | Retention VIC No. Share vs LY | 比率类 vs LY | 今年 - 去年（差值） | delta_pts |
| 22 | Retention VIC No. Share vs LP | 比率类 vs LP | 当期 - 上期（差值） | delta_pts |
| 24 | Direct VIC No. vs LY | 数量类 vs LY | 今年 / 去年 - 1 | delta_pct_1dp |
| 25 | Direct VIC No. vs LP | 数量类 vs LP | 当期 / 上期 - 1 | delta_pct_1dp |
| 27 | Direct VIC No. Share vs LY | 比率类 vs LY | 今年 - 去年（差值） | delta_pts |
| 28 | Direct VIC No. Share vs LP | 比率类 vs LP | 当期 - 上期（差值） | delta_pts |

> **TAR ACH% 类指标**（Metric_ID 4, 5, 9, 13）：占位值为 1，待逻辑确认后再填充。

### 3.6 Share 类指标计算（分母为 end period 当月 is_vic=1）

| Metric_ID | 指标 | 分子筛选 | 分母筛选 | Metric_Format |
|-----------|------|---------|---------|---------------|
| 14 | T4-5 Upgrade No. Share | `is_upgrade_vic=1` 的 DISTINCTCOUNT user_id | `is_vic=1` 的 DISTINCTCOUNT user_id（end period 当月） | percent_1dp |
| 20 | Retention VIC No. Share | `is_retention_vic=1` 的 DISTINCTCOUNT user_id | `is_vic=1` 的 DISTINCTCOUNT user_id（end period 当月） | percent_1dp |
| 26 | Direct VIC No. Share | `is_direct_vic=1` 的 DISTINCTCOUNT user_id | `is_vic=1` 的 DISTINCTCOUNT user_id（end period 当月） | percent_1dp |

> **VIC Retention% 分母特殊**：分母为 Rolling 12 个财月区间 `is_vic=1` 的 DISTINCTCOUNT user_id，详见 1.4 节。

### 3.7 格式规范（按 Metric_Format 单字段分发）

| Metric_Format | 格式串 | 示例 | 适用指标 |
|---------------|--------|------|---------|
| `integer` | `#,##0` | 1,234 | 所有数量类 Act（VIC No. / T4-5 Upgrade No. / Retention VIC No. / Direct VIC No.） |
| `percent_1dp` | `#,##0.0%` | 14.5% | TAR ACH% / VIC Retention% / Share / Retention VIC No. vs LY |
| `delta_pct_1dp` | `IF(__Value>0,"+","") & FORMAT(__Value,"#,##0.0%")` | +14.5% / -3.2% | 数量类 vs LY / vs LP |
| `delta_pts` | `IF(ROUND(__Value*100,0)>0,"+","") & FORMAT(__Value*100,"+#,##0pts;-#,##0pts;0pts")` | +120pts / -80pts / 0pts | 比率类 vs LY / vs LP / Share vs LY / Share vs LP（值×100 转 pts 在 Cell Display 中实现） |

> 注：不存在 `percent_1dp_signed` / `percent_1dp_nosign` 两个格式。所有"不含正号的百分比"统一为 `percent_1dp`，所有"含正号的百分比变化"统一为 `delta_pct_1dp`。TAR ACH% 口径文档标注"含正负号"，但按用户要求统一为 `percent_1dp`（不含正号）。

---

## 4. 度量值实现

### 4.1 Dim_ColMetric_VIC_KPIs（列指标维度表）

> 维度表已存在于 `Dim_ColMetric_VIC_KPIs.md`，此处不再重复定义，直接引用。下表明晰 Metric_ID 与口径文档指标的映射关系：

| Metric_ID | KPIGroup | ColName | ColType | 口径文档对应指标 | Act/LP/LY 字段 | 数据底表 |
|-----------|----------|---------|---------|-----------------|---------------|---------|
| 1 | VIC No. | 1-VIC No. | Act | 1. VIC No. | is_vic=1 | a03_e2e_customer_data_m |
| 2 | VIC No. | 2-VIC No. vs LY | vs LY | 1.1 VIC No. vs LY | — | 派生 |
| 3 | VIC No. | 3-VIC No. vs LP | vs LP | 1.2 VIC No. vs LP | — | 派生 |
| 4 | VIC No. | 4-VIC Monthly TAR ACH% | TAR ACH% Monthly | 1.3 VIC Monthly TAR ACH% | — | 占位=1 |
| 5 | VIC No. | 5-VIC Yearly TAR ACH% | TAR ACH% Yearly | 1.4 VIC Yearly TAR ACH% | — | 占位=1 |
| 6 | VIC Retention% | 6-VIC Retention% | Act | 2. VIC Retention% | 分子: is_retention_vic=1；分母: is_vic=1（Rolling 12） | a03_e2e_customer_data_m |
| 7 | VIC Retention% | 7-VIC Retention% vs LY | vs LY | 2.1 VIC Retention% vs LY | — | 派生 |
| 8 | VIC Retention% | 8-VIC Retention% vs LP | vs LP | 2.2 VIC Retention% vs LP | — | 派生 |
| 9 | VIC Retention% | 9-VIC Retention% TAR ACH% | TAR ACH% | 2.3 VIC Retention% TAR ACH% | — | 占位=1 |
| 10 | T4-5 Upgrade No. | 10-T4-5 Upgrade No. | Act | 3. T4-5 Upgrade No. | is_upgrade_vic=1 | a03_e2e_customer_data_m |
| 11 | T4-5 Upgrade No. | 11-T4-5 Upgrade No. vs LY | vs LY | 3.1 T4-5 Upgrade No. vs LY | — | 派生 |
| 12 | T4-5 Upgrade No. | 12-T4-5 Upgrade No. vs LP | vs LP | 3.2 T4-5 Upgrade No. vs LP | — | 派生 |
| 13 | T4-5 Upgrade No. | 13-T4-5 Upgrade No. TAR ACH% | TAR ACH% | 3.3 T4-5 Upgrade No. TAR ACH% | — | 占位=1 |
| 14 | T4-5 Upgrade No. | 14-T4-5 Upgrade No. Share | Share | 3.4 T4-5 Upgrade No. Share | 分子: is_upgrade_vic=1；分母: is_vic=1（end period 当月） | a03_e2e_customer_data_m |
| 15 | T4-5 Upgrade No. | 15-T4-5 Upgrade No. Share vs LY | Share vs LY | 3.5 T4-5 Upgrade No. Share vs LY | — | 派生 |
| 16 | T4-5 Upgrade No. | 16-T4-5 Upgrade No. Share vs LP | Share vs LP | 3.6 T4-5 Upgrade No. Share vs LP | — | 派生 |
| 17 | Retention VIC No. | 17-Retention VIC No. | Act | 4. Retention VIC No. | is_retention_vic=1 | a03_e2e_customer_data_m |
| 18 | Retention VIC No. | 18-Retention VIC No. vs LY | vs LY | 4.1 Retention VIC No. vs LY | — | 派生 |
| 19 | Retention VIC No. | 19-Retention VIC No. vs LP | vs LP | 4.2 Retention VIC No. vs LP | — | 派生 |
| 20 | Retention VIC No. | 20-Retention VIC No. Share | Share | 4.3 Retention VIC No. Share | 分子: is_retention_vic=1；分母: is_vic=1（end period 当月） | a03_e2e_customer_data_m |
| 21 | Retention VIC No. | 21-Retention VIC No. Share vs LY | Share vs LY | 4.4 Retention VIC No. Share vs LY | — | 派生 |
| 22 | Retention VIC No. | 22-Retention VIC No. Share vs LP | Share vs LP | 4.5 Retention VIC No. Share vs LP | — | 派生 |
| 23 | Direct VIC No. | 23-Direct VIC No. | Act | 5. Direct VIC No. | is_direct_vic=1 | a03_e2e_customer_data_m |
| 24 | Direct VIC No. | 24-Direct VIC No. vs LY | vs LY | 5.1 Direct VIC No. vs LY | — | 派生 |
| 25 | Direct VIC No. | 25-Direct VIC No. vs LP | vs LP | 5.2 Direct VIC No. vs LP | — | 派生 |
| 26 | Direct VIC No. | 26-Direct VIC No. Share | Share | 5.3 Direct VIC No. Share | 分子: is_direct_vic=1；分母: is_vic=1（end period 当月） | a03_e2e_customer_data_m |
| 27 | Direct VIC No. | 27-Direct VIC No. Share vs LY | Share vs LY | 5.4 Direct VIC No. Share vs LY | — | 派生 |
| 28 | Direct VIC No. | 28-Direct VIC No. Share vs LP | Share vs LP | 5.5 Direct VIC No. Share vs LP | — | 派生 |

### 4.2 VIC KPIs Act Base Value（本期基础值）

```dax
VIC KPIs Act Base Value = 
// ========================================
// 度量值: VIC KPIs Act Base Value
// Display Folder: Base Metrics
// 用途: 根据 Metric_ID 路由到本期（Act）基础值
// 依赖: 'Dim_ColMetric_VIC_KPIs'[Metric_ID],
//       a03_e2e_customer_data_m,
//       Slicer_Time_Frame_Max[Last_Fiscal_Month_Min/Max],
//       Slicer_Is_Employee_Selection[IsEmployee_Code],
//       IsMemberFilter[IsMember]
// 口径来源: 口径文档/VIC KPI.md
// 筛选上下文:
//   - data_date ∈ [Last_Fiscal_Month_Min, Last_Fiscal_Month_Max]（end period 当月）
//   - is_member = __IsMemberFilter（默认 0 = TTL VIC）
//   - is_employee = __IsEmployeeFilter（默认 1 = Yes）
//   - 按 Metric_ID 路由到 is_vic / is_retention_vic / is_upgrade_vic / is_direct_vic 字段
// 聚合粒度: DISTINCTCOUNT(user_id) WHERE 对应 is_xxx_vic = 1
// 说明:
//   - VIC Retention% 和 Share 类指标在此处返回分子
//   - VIC Retention% 的分母（Rolling 12 个财月区间）见 [VIC KPIs Rolling12 VIC Denominator]
//   - Share 类的分母（end period 当月 is_vic=1）在 Base Value 中通过 Metric_ID=1 取值
// ========================================
    VAR __MetricID = SELECTEDVALUE('Dim_ColMetric_VIC_KPIs'[Metric_ID])
    // ── 时间筛选：end period 当月（本期）──
    VAR __PeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Max[Last_Fiscal_Month_Min])
    VAR __PeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max[Last_Fiscal_Month_Max])
    // ── 人群筛选 ──
    VAR __IsMemberFilter = SELECTEDVALUE(IsMemberFilter[IsMember], 0)
    VAR __IsEmployeeFilter = SELECTEDVALUE(Slicer_Is_Employee_Selection[IsEmployee_Code], 1)

    // ═══════════════════════════════════════
    // 基础聚合：DISTINCTCOUNT(user_id) WHERE is_xxx_vic = 1
    // 统一应用 is_member / is_employee / end period 时间筛选
    // ═══════════════════════════════════════
    VAR __VICCount_Act =
        CALCULATE(
            DISTINCTCOUNT('a03_e2e_customer_data_m'[user_id]),
            'a03_e2e_customer_data_m'[is_vic] = 1,
            'a03_e2e_customer_data_m'[is_member] = __IsMemberFilter,
            'a03_e2e_customer_data_m'[is_employee] = __IsEmployeeFilter,
            'a03_e2e_customer_data_m'[data_date] >= __PeriodMin,
            'a03_e2e_customer_data_m'[data_date] <= __PeriodMax
        )
    VAR __RetentionVICCount_Act =
        CALCULATE(
            DISTINCTCOUNT('a03_e2e_customer_data_m'[user_id]),
            'a03_e2e_customer_data_m'[is_retention_vic] = 1,
            'a03_e2e_customer_data_m'[is_member] = __IsMemberFilter,
            'a03_e2e_customer_data_m'[is_employee] = __IsEmployeeFilter,
            'a03_e2e_customer_data_m'[data_date] >= __PeriodMin,
            'a03_e2e_customer_data_m'[data_date] <= __PeriodMax
        )
    VAR __UpgradeVICCount_Act =
        CALCULATE(
            DISTINCTCOUNT('a03_e2e_customer_data_m'[user_id]),
            'a03_e2e_customer_data_m'[is_upgrade_vic] = 1,
            'a03_e2e_customer_data_m'[is_member] = __IsMemberFilter,
            'a03_e2e_customer_data_m'[is_employee] = __IsEmployeeFilter,
            'a03_e2e_customer_data_m'[data_date] >= __PeriodMin,
            'a03_e2e_customer_data_m'[data_date] <= __PeriodMax
        )
    VAR __DirectVICCount_Act =
        CALCULATE(
            DISTINCTCOUNT('a03_e2e_customer_data_m'[user_id]),
            'a03_e2e_customer_data_m'[is_direct_vic] = 1,
            'a03_e2e_customer_data_m'[is_member] = __IsMemberFilter,
            'a03_e2e_customer_data_m'[is_employee] = __IsEmployeeFilter,
            'a03_e2e_customer_data_m'[data_date] >= __PeriodMin,
            'a03_e2e_customer_data_m'[data_date] <= __PeriodMax
        )

    RETURN
        SWITCH(
            __MetricID,
            // ── VIC No. 分组（Act）──
            1,  __VICCount_Act,
            // ── VIC Retention% 分组（Act：分子 is_retention_vic=1）──
            6,  __RetentionVICCount_Act,
            // ── T4-5 Upgrade No. 分组（Act）──
            10, __UpgradeVICCount_Act,
            // ── T4-5 Upgrade No. Share 分组（Act：分子 is_upgrade_vic=1）──
            14, __UpgradeVICCount_Act,
            // ── Retention VIC No. 分组（Act）──
            17, __RetentionVICCount_Act,
            // ── Retention VIC No. Share 分组（Act：分子 is_retention_vic=1）──
            20, __RetentionVICCount_Act,
            // ── Direct VIC No. 分组（Act）──
            23, __DirectVICCount_Act,
            // ── Direct VIC No. Share 分组（Act：分子 is_direct_vic=1）──
            26, __DirectVICCount_Act,
            BLANK()
        )
```

### 4.3 VIC KPIs LY Base Value（去年同期基础值，财历映射）

```dax
VIC KPIs LY Base Value = 
// ========================================
// 度量值: VIC KPIs LY Base Value
// Display Folder: Base Metrics
// 用途: 根据 Metric_ID 路由到去年同期（LY）基础值
// 依赖: 'Dim_ColMetric_VIC_KPIs'[Metric_ID],
//       Slicer_Time_Frame_Max[Last_Fiscal_Month_Min_LY/Max_LY],
//       a03_e2e_customer_data_m
// 口径来源: 口径文档/VIC KPI.md
// 时间偏移: 财历映射（直接读取 Slicer_Time_Frame_Max 内置 Last_Fiscal_Month_*_LY 字段）
// 注: 仅 Act 基础指标的 LY 才有实际意义；TAR ACH% / vs LY / vs LP / Share vs LY 等派生指标的 LY 通过 Base Value 路由
// ========================================
    VAR __MetricID = SELECTEDVALUE('Dim_ColMetric_VIC_KPIs'[Metric_ID])
    // ── 直接读取日期表内置的 LY 时间范围 ──
    VAR __LYMin = SELECTEDVALUE(Slicer_Time_Frame_Max[Last_Fiscal_Month_Min_LY])
    VAR __LYMax = SELECTEDVALUE(Slicer_Time_Frame_Max[Last_Fiscal_Month_Max_LY])
    // ── 人群筛选 ──
    VAR __IsMemberFilter = SELECTEDVALUE(IsMemberFilter[IsMember], 0)
    VAR __IsEmployeeFilter = SELECTEDVALUE(Slicer_Is_Employee_Selection[IsEmployee_Code], 1)

    // ═══════════════════════════════════════
    // 基础聚合：去年同期 end period 当月
    // ═══════════════════════════════════════
    VAR __VICCount_LY =
        CALCULATE(
            DISTINCTCOUNT('a03_e2e_customer_data_m'[user_id]),
            'a03_e2e_customer_data_m'[is_vic] = 1,
            'a03_e2e_customer_data_m'[is_member] = __IsMemberFilter,
            'a03_e2e_customer_data_m'[is_employee] = __IsEmployeeFilter,
            'a03_e2e_customer_data_m'[data_date] >= __LYMin,
            'a03_e2e_customer_data_m'[data_date] <= __LYMax
        )
    VAR __RetentionVICCount_LY =
        CALCULATE(
            DISTINCTCOUNT('a03_e2e_customer_data_m'[user_id]),
            'a03_e2e_customer_data_m'[is_retention_vic] = 1,
            'a03_e2e_customer_data_m'[is_member] = __IsMemberFilter,
            'a03_e2e_customer_data_m'[is_employee] = __IsEmployeeFilter,
            'a03_e2e_customer_data_m'[data_date] >= __LYMin,
            'a03_e2e_customer_data_m'[data_date] <= __LYMax
        )
    VAR __UpgradeVICCount_LY =
        CALCULATE(
            DISTINCTCOUNT('a03_e2e_customer_data_m'[user_id]),
            'a03_e2e_customer_data_m'[is_upgrade_vic] = 1,
            'a03_e2e_customer_data_m'[is_member] = __IsMemberFilter,
            'a03_e2e_customer_data_m'[is_employee] = __IsEmployeeFilter,
            'a03_e2e_customer_data_m'[data_date] >= __LYMin,
            'a03_e2e_customer_data_m'[data_date] <= __LYMax
        )
    VAR __DirectVICCount_LY =
        CALCULATE(
            DISTINCTCOUNT('a03_e2e_customer_data_m'[user_id]),
            'a03_e2e_customer_data_m'[is_direct_vic] = 1,
            'a03_e2e_customer_data_m'[is_member] = __IsMemberFilter,
            'a03_e2e_customer_data_m'[is_employee] = __IsEmployeeFilter,
            'a03_e2e_customer_data_m'[data_date] >= __LYMin,
            'a03_e2e_customer_data_m'[data_date] <= __LYMax
        )

    RETURN
        SWITCH(
            __MetricID,
            // ── VIC No. LY ──
            1,  __VICCount_LY,
            // ── VIC Retention% LY（分子 is_retention_vic=1）──
            6,  __RetentionVICCount_LY,
            // ── T4-5 Upgrade No. LY ──
            10, __UpgradeVICCount_LY,
            // ── T4-5 Upgrade No. Share LY（分子 is_upgrade_vic=1）──
            14, __UpgradeVICCount_LY,
            // ── Retention VIC No. LY ──
            17, __RetentionVICCount_LY,
            // ── Retention VIC No. Share LY（分子 is_retention_vic=1）──
            20, __RetentionVICCount_LY,
            // ── Direct VIC No. LY ──
            23, __DirectVICCount_LY,
            // ── Direct VIC No. Share LY（分子 is_direct_vic=1）──
            26, __DirectVICCount_LY,
            BLANK()
        )
```

### 4.4 VIC KPIs LP Base Value（上期基础值，财历映射）

```dax
VIC KPIs LP Base Value = 
// ========================================
// 度量值: VIC KPIs LP Base Value
// Display Folder: Base Metrics
// 用途: 根据 Metric_ID 路由到上期（LP）基础值
// 依赖: 'Dim_ColMetric_VIC_KPIs'[Metric_ID],
//       Slicer_Time_Frame_Max[Last_Fiscal_Month_Min_LP/Max_LP],
//       a03_e2e_customer_data_m
// 口径来源: 口径文档/VIC KPI.md
// 时间偏移: 财历映射（直接读取 Slicer_Time_Frame_Max 内置 Last_Fiscal_Month_*_LP 字段）
// 注: LP = Last Period（上一期），按所选粒度（月/季/年）的上一期
// ========================================
    VAR __MetricID = SELECTEDVALUE('Dim_ColMetric_VIC_KPIs'[Metric_ID])
    // ── 直接读取日期表内置的 LP 时间范围 ──
    VAR __LPMin = SELECTEDVALUE(Slicer_Time_Frame_Max[Last_Fiscal_Month_Min_LP])
    VAR __LPMax = SELECTEDVALUE(Slicer_Time_Frame_Max[Last_Fiscal_Month_Max_LP])
    // ── 人群筛选 ──
    VAR __IsMemberFilter = SELECTEDVALUE(IsMemberFilter[IsMember], 0)
    VAR __IsEmployeeFilter = SELECTEDVALUE(Slicer_Is_Employee_Selection[IsEmployee_Code], 1)

    // ═══════════════════════════════════════
    // 基础聚合：上期 end period 当月
    // ═══════════════════════════════════════
    VAR __VICCount_LP =
        CALCULATE(
            DISTINCTCOUNT('a03_e2e_customer_data_m'[user_id]),
            'a03_e2e_customer_data_m'[is_vic] = 1,
            'a03_e2e_customer_data_m'[is_member] = __IsMemberFilter,
            'a03_e2e_customer_data_m'[is_employee] = __IsEmployeeFilter,
            'a03_e2e_customer_data_m'[data_date] >= __LPMin,
            'a03_e2e_customer_data_m'[data_date] <= __LPMax
        )
    VAR __RetentionVICCount_LP =
        CALCULATE(
            DISTINCTCOUNT('a03_e2e_customer_data_m'[user_id]),
            'a03_e2e_customer_data_m'[is_retention_vic] = 1,
            'a03_e2e_customer_data_m'[is_member] = __IsMemberFilter,
            'a03_e2e_customer_data_m'[is_employee] = __IsEmployeeFilter,
            'a03_e2e_customer_data_m'[data_date] >= __LPMin,
            'a03_e2e_customer_data_m'[data_date] <= __LPMax
        )
    VAR __UpgradeVICCount_LP =
        CALCULATE(
            DISTINCTCOUNT('a03_e2e_customer_data_m'[user_id]),
            'a03_e2e_customer_data_m'[is_upgrade_vic] = 1,
            'a03_e2e_customer_data_m'[is_member] = __IsMemberFilter,
            'a03_e2e_customer_data_m'[is_employee] = __IsEmployeeFilter,
            'a03_e2e_customer_data_m'[data_date] >= __LPMin,
            'a03_e2e_customer_data_m'[data_date] <= __LPMax
        )
    VAR __DirectVICCount_LP =
        CALCULATE(
            DISTINCTCOUNT('a03_e2e_customer_data_m'[user_id]),
            'a03_e2e_customer_data_m'[is_direct_vic] = 1,
            'a03_e2e_customer_data_m'[is_member] = __IsMemberFilter,
            'a03_e2e_customer_data_m'[is_employee] = __IsEmployeeFilter,
            'a03_e2e_customer_data_m'[data_date] >= __LPMin,
            'a03_e2e_customer_data_m'[data_date] <= __LPMax
        )

    RETURN
        SWITCH(
            __MetricID,
            // ── VIC No. LP ──
            1,  __VICCount_LP,
            // ── VIC Retention% LP（分子 is_retention_vic=1）──
            6,  __RetentionVICCount_LP,
            // ── T4-5 Upgrade No. LP ──
            10, __UpgradeVICCount_LP,
            // ── T4-5 Upgrade No. Share LP（分子 is_upgrade_vic=1）──
            14, __UpgradeVICCount_LP,
            // ── Retention VIC No. LP ──
            17, __RetentionVICCount_LP,
            // ── Retention VIC No. Share LP（分子 is_retention_vic=1）──
            20, __RetentionVICCount_LP,
            // ── Direct VIC No. LP ──
            23, __DirectVICCount_LP,
            // ── Direct VIC No. Share LP（分子 is_direct_vic=1）──
            26, __DirectVICCount_LP,
            BLANK()
        )
```

### 4.5 VIC KPIs Rolling12 VIC Denominator（VIC Retention% 专用 Rolling 12 个财月分母）

```dax
VIC KPIs Rolling12 VIC Denominator = 
// ========================================
// 度量值: VIC KPIs Rolling12 VIC Denominator
// Display Folder: Base Metrics
// 用途: 计算 VIC Retention% 的分母 — Rolling 12 个财月区间 is_vic=1 的 DISTINCTCOUNT(user_id)
// 依赖: Slicer_Time_Frame_Max[Last_Fiscal_Month_Min/Max, TimeFrame_Value, TimeFrame_Min],
//       Slicer_Time_Frame_Max[Last_Fiscal_Month_Min_LY/Max_LY],
//       Slicer_Time_Frame_Max[Last_Fiscal_Month_Min_LP/Max_LP],
//       a03_e2e_customer_data_m
// 口径来源: 口径文档/VIC KPI.md - 2. VIC Retention%
//
// 分母定义（口径文档原文）:
//   所选时间范围 end period 往前 Rolling 12 个财月 count(distinct user_id)
//   Rolling 12 个财月 = 当前月 + 往前 11 个月，共 12 个月
//   is_vic = 1
//
// 聚合方式: 区间 DISTINCT 汇总
//   在 12 个月区间内 count(distinct user_id) where is_vic=1
//   同一用户只计一次（非按月 SUM 累加）
//
// Rolling 12 区间起止日获取（用户确认的逻辑）:
//   - 区间结束日 = Last_Fiscal_Month_Max（end period 当月自然日结束日）
//   - 起始月 = EDATE(Last_Fiscal_Month_Min, -11) 往前推 11 个月
//   - 起始日 = 在 Slicer_Time_Frame_Max 中按 TimeFrame_Value = 起始月 查找 TimeFrame_Min
//   - 最终区间 = [起始月 TimeFrame_Min, Last_Fiscal_Month_Max]
//
// 支持三套时间范围:
//   - 本期: __PeriodMin / __PeriodMax
//   - LY:   __LYMin / __LYMax
//   - LP:   __LPMin / __LPMax
// 通过 __TimeScope 参数切换（"Act" / "LY" / "LP"）
// ========================================
    VAR __TimeScope = SELECTEDVALUE('Dim_ColMetric_VIC_KPIs'[__Rolling12Scope], "Act")  // 通过计算列或外部切换，默认 Act
    // ── 人群筛选 ──
    VAR __IsMemberFilter = SELECTEDVALUE(IsMemberFilter[IsMember], 0)
    VAR __IsEmployeeFilter = SELECTEDVALUE(Slicer_Is_Employee_Selection[IsEmployee_Code], 1)

    // ═══════════════════════════════════════
    // 1. 取 end period 当月的时间范围（按 TimeScope 切换）
    // ═══════════════════════════════════════
    VAR __EndPeriodMin =
        SWITCH(__TimeScope,
            "Act", SELECTEDVALUE(Slicer_Time_Frame_Max[Last_Fiscal_Month_Min]),
            "LY",  SELECTEDVALUE(Slicer_Time_Frame_Max[Last_Fiscal_Month_Min_LY]),
            "LP",  SELECTEDVALUE(Slicer_Time_Frame_Max[Last_Fiscal_Month_Min_LP])
        )
    VAR __EndPeriodMax =
        SWITCH(__TimeScope,
            "Act", SELECTEDVALUE(Slicer_Time_Frame_Max[Last_Fiscal_Month_Max]),
            "LY",  SELECTEDVALUE(Slicer_Time_Frame_Max[Last_Fiscal_Month_Max_LY]),
            "LP",  SELECTEDVALUE(Slicer_Time_Frame_Max[Last_Fiscal_Month_Max_LP])
        )

    // ═══════════════════════════════════════
    // 2. 计算 Rolling 12 起始月（往前推 11 个月）
    //    EDATE 处理：以 end period 当月起始日往前推 11 个月
    //    例: end period=2026-09-01 → 起始月=2025-10-01
    // ═══════════════════════════════════════
    VAR __Rolling12StartMonthDate = EDATE(__EndPeriodMin, -11)
    // 转为 YYYY-MM 格式，用于匹配 Slicer_Time_Frame_Max[TimeFrame_Value]（月粒度）
    VAR __Rolling12StartMonthValue =
        FORMAT(__Rolling12StartMonthDate, "yyyy-MM")

    // ═══════════════════════════════════════
    // 3. 在 Slicer_Time_Frame_Max 中查找起始月的 TimeFrame_Min（自然日起始日）
    //    使用 CALCULATE + FILTER 在断开维度表中查找
    // ═══════════════════════════════════════
    VAR __Rolling12StartMin =
        CALCULATE(
            SELECTEDVALUE(Slicer_Time_Frame_Max[TimeFrame_Min]),
            FILTER(
                ALL(Slicer_Time_Frame_Max),
                Slicer_Time_Frame_Max[TimeFrame_Label] = "月"
                && Slicer_Time_Frame_Max[TimeFrame_Value] = __Rolling12StartMonthValue
            )
        )

    // ═══════════════════════════════════════
    // 4. 在 Rolling 12 区间内计算 is_vic=1 的 DISTINCTCOUNT(user_id)
    //    区间 = [__Rolling12StartMin, __EndPeriodMax]
    //    区间 DISTINCT 汇总：同一用户只计一次
    // ═══════════════════════════════════════
    VAR __Denominator =
        CALCULATE(
            DISTINCTCOUNT('a03_e2e_customer_data_m'[user_id]),
            'a03_e2e_customer_data_m'[is_vic] = 1,
            'a03_e2e_customer_data_m'[is_member] = __IsMemberFilter,
            'a03_e2e_customer_data_m'[is_employee] = __IsEmployeeFilter,
            'a03_e2e_customer_data_m'[data_date] >= __Rolling12StartMin,
            'a03_e2e_customer_data_m'[data_date] <= __EndPeriodMax
        )

    RETURN __Denominator
```

> **说明**：`[VIC KPIs Rolling12 VIC Denominator]` 通过 `__TimeScope` 参数切换本期/LY/LP 三套时间范围。在总路由 `[VIC KPIs Base Value]` 中，VIC Retention% 的本期/LY/LP 计算会分别传入 `"Act"` / `"LY"` / `"LP"` 调用此度量值。
>
> 由于 DAX 度量值不能直接传参，实际实现通过 `CALCULATE(..., 'Dim_ColMetric_VIC_KPIs'[__Rolling12Scope] = "LY")` 方式覆盖 `__TimeScope`。为此需要在 `Dim_ColMetric_VIC_KPIs` 表中增加一个计算列 `__Rolling12Scope`（默认值 "Act"），由总路由在调用时通过 CALCULATE 覆盖。或者更简洁的方式：将此度量值拆为三个独立度量值（Act/LY/LP），见下方实现。

### 4.5b VIC KPIs Rolling12 VIC Denominator（三套独立度量值实现，推荐）

```dax
VIC KPIs Rolling12 VIC Denominator Act = 
// ========================================
// 度量值: VIC KPIs Rolling12 VIC Denominator Act
// Display Folder: Base Metrics
// 用途: VIC Retention% 本期分母 — Rolling 12 个财月区间 is_vic=1 的 DISTINCTCOUNT(user_id)
// ========================================
    // ── 人群筛选 ──
    VAR __IsMemberFilter = SELECTEDVALUE(IsMemberFilter[IsMember], 0)
    VAR __IsEmployeeFilter = SELECTEDVALUE(Slicer_Is_Employee_Selection[IsEmployee_Code], 1)
    // ── 本期 end period 当月范围 ──
    VAR __EndPeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Max[Last_Fiscal_Month_Min])
    VAR __EndPeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max[Last_Fiscal_Month_Max])
    // ── Rolling 12 起始月（往前推 11 个月）──
    VAR __Rolling12StartMonthDate = EDATE(__EndPeriodMin, -11)
    VAR __Rolling12StartMonthValue = FORMAT(__Rolling12StartMonthDate, "yyyy-MM")
    // ── 在 Slicer_Time_Frame_Max 中查找起始月的 TimeFrame_Min ──
    VAR __Rolling12StartMin =
        CALCULATE(
            SELECTEDVALUE(Slicer_Time_Frame_Max[TimeFrame_Min]),
            FILTER(
                ALL(Slicer_Time_Frame_Max),
                Slicer_Time_Frame_Max[TimeFrame_Label] = "月"
                && Slicer_Time_Frame_Max[TimeFrame_Value] = __Rolling12StartMonthValue
            )
        )
    // ── Rolling 12 区间 is_vic=1 的 DISTINCTCOUNT(user_id) ──
    RETURN
        CALCULATE(
            DISTINCTCOUNT('a03_e2e_customer_data_m'[user_id]),
            'a03_e2e_customer_data_m'[is_vic] = 1,
            'a03_e2e_customer_data_m'[is_member] = __IsMemberFilter,
            'a03_e2e_customer_data_m'[is_employee] = __IsEmployeeFilter,
            'a03_e2e_customer_data_m'[data_date] >= __Rolling12StartMin,
            'a03_e2e_customer_data_m'[data_date] <= __EndPeriodMax
        )

VIC KPIs Rolling12 VIC Denominator LY = 
// ========================================
// 度量值: VIC KPIs Rolling12 VIC Denominator LY
// Display Folder: Base Metrics
// 用途: VIC Retention% LY 分母 — Rolling 12 个财月区间 is_vic=1 的 DISTINCTCOUNT(user_id)（LY）
// ========================================
    VAR __IsMemberFilter = SELECTEDVALUE(IsMemberFilter[IsMember], 0)
    VAR __IsEmployeeFilter = SELECTEDVALUE(Slicer_Is_Employee_Selection[IsEmployee_Code], 1)
    VAR __EndPeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Max[Last_Fiscal_Month_Min_LY])
    VAR __EndPeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max[Last_Fiscal_Month_Max_LY])
    VAR __Rolling12StartMonthDate = EDATE(__EndPeriodMin, -11)
    VAR __Rolling12StartMonthValue = FORMAT(__Rolling12StartMonthDate, "yyyy-MM")
    VAR __Rolling12StartMin =
        CALCULATE(
            SELECTEDVALUE(Slicer_Time_Frame_Max[TimeFrame_Min]),
            FILTER(
                ALL(Slicer_Time_Frame_Max),
                Slicer_Time_Frame_Max[TimeFrame_Label] = "月"
                && Slicer_Time_Frame_Max[TimeFrame_Value] = __Rolling12StartMonthValue
            )
        )
    RETURN
        CALCULATE(
            DISTINCTCOUNT('a03_e2e_customer_data_m'[user_id]),
            'a03_e2e_customer_data_m'[is_vic] = 1,
            'a03_e2e_customer_data_m'[is_member] = __IsMemberFilter,
            'a03_e2e_customer_data_m'[is_employee] = __IsEmployeeFilter,
            'a03_e2e_customer_data_m'[data_date] >= __Rolling12StartMin,
            'a03_e2e_customer_data_m'[data_date] <= __EndPeriodMax
        )

VIC KPIs Rolling12 VIC Denominator LP = 
// ========================================
// 度量值: VIC KPIs Rolling12 VIC Denominator LP
// Display Folder: Base Metrics
// 用途: VIC Retention% LP 分母 — Rolling 12 个财月区间 is_vic=1 的 DISTINCTCOUNT(user_id)（LP）
// ========================================
    VAR __IsMemberFilter = SELECTEDVALUE(IsMemberFilter[IsMember], 0)
    VAR __IsEmployeeFilter = SELECTEDVALUE(Slicer_Is_Employee_Selection[IsEmployee_Code], 1)
    VAR __EndPeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Max[Last_Fiscal_Month_Min_LP])
    VAR __EndPeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max[Last_Fiscal_Month_Max_LP])
    VAR __Rolling12StartMonthDate = EDATE(__EndPeriodMin, -11)
    VAR __Rolling12StartMonthValue = FORMAT(__Rolling12StartMonthDate, "yyyy-MM")
    VAR __Rolling12StartMin =
        CALCULATE(
            SELECTEDVALUE(Slicer_Time_Frame_Max[TimeFrame_Min]),
            FILTER(
                ALL(Slicer_Time_Frame_Max),
                Slicer_Time_Frame_Max[TimeFrame_Label] = "月"
                && Slicer_Time_Frame_Max[TimeFrame_Value] = __Rolling12StartMonthValue
            )
        )
    RETURN
        CALCULATE(
            DISTINCTCOUNT('a03_e2e_customer_data_m'[user_id]),
            'a03_e2e_customer_data_m'[is_vic] = 1,
            'a03_e2e_customer_data_m'[is_member] = __IsMemberFilter,
            'a03_e2e_customer_data_m'[is_employee] = __IsEmployeeFilter,
            'a03_e2e_customer_data_m'[data_date] >= __Rolling12StartMin,
            'a03_e2e_customer_data_m'[data_date] <= __EndPeriodMax
        )
```

### 4.6 VIC KPIs Base Value（总路由）

```dax
VIC KPIs Base Value = 
// ========================================
// 度量值: VIC KPIs Base Value
// Display Folder: Base Metrics
// 用途: 总路由，根据 Metric_ID 分发到 Act / vs LY / vs LP / TAR ACH% / Share / Share vs LY / Share vs LP
// 依赖: [VIC KPIs Act Base Value], [VIC KPIs LY Base Value], [VIC KPIs LP Base Value],
//       [VIC KPIs Rolling12 VIC Denominator Act/LY/LP],
//       'Dim_ColMetric_VIC_KPIs'[Metric_ID]
//
// Metric_ID 路由规则:
//   Act 基础指标 ID: 1, 6, 10, 14, 17, 20, 23, 26
//   数量类 vs LY: 2（VIC No.）, 11（T4-5）, 24（Direct）
//   数量类 vs LP: 3（VIC No.）, 12（T4-5）, 19（Retention）, 25（Direct）
//   数量类 vs LY 特殊格式: 18（Retention VIC No. vs LY，percent_1dp）
//   比率类 vs LY: 7（Retention%）, 15（T4-5 Share）, 21（Retention Share）, 27（Direct Share）
//   比率类 vs LP: 8（Retention%）, 16（T4-5 Share）, 22（Retention Share）, 28（Direct Share）
//   TAR ACH% 占位: 4, 5, 9, 13 → 返回 1
//
// 派生规则:
//   - 数量类 vs LY: 今年 / 去年 - 1
//   - 数量类 vs LP: 当期 / 上期 - 1
//   - 比率类（Retention%）vs LY: 今年 - 去年（差值，×100 转 pts）
//     分母特殊: VIC Retention% 分母使用 [VIC KPIs Rolling12 VIC Denominator Act/LY/LP]
//   - 比率类（Share）vs LY: 今年 - 去年（差值，×100 转 pts）
//     分母: end period 当月 is_vic=1 的 Act Base Value（Metric_ID=1）
//
// REMOVEFILTERS 机制（参考 PB_Merchandise_Fulfillment_detail_ms.md）:
//   派生行需先 REMOVEFILTERS 清除断开维度的所有筛选，再应用目标 Metric_ID
// ========================================
    VAR __MetricID = SELECTEDVALUE('Dim_ColMetric_VIC_KPIs'[Metric_ID])

    // ═══════════════════════════════════════
    // 数量类 vs LY（分子: Act，分母: LY）
    // VIC No. vs LY: Metric_ID=2，Act→1，LY→1
    // T4-5 Upgrade No. vs LY: Metric_ID=11，Act→10，LY→10
    // Retention VIC No. vs LY（特殊格式）: Metric_ID=18，Act→17，LY→17
    // Direct VIC No. vs LY: Metric_ID=24，Act→23，LY→23
    // ═══════════════════════════════════════
    VAR __IsQtyVsLY = __MetricID IN {2, 11, 18, 24}
    VAR __QtyActMetricID_LY =
        SWITCH(__MetricID,
            2, 1,
            11, 10,
            18, 17,
            24, 23
        )
    VAR __QtyActValue_LY =
        IF(
            __IsQtyVsLY,
            CALCULATE(
                [VIC KPIs Act Base Value],
                REMOVEFILTERS('Dim_ColMetric_VIC_KPIs'),
                'Dim_ColMetric_VIC_KPIs'[Metric_ID] = __QtyActMetricID_LY
            )
        )
    VAR __QtyLYValue =
        IF(
            __IsQtyVsLY,
            CALCULATE(
                [VIC KPIs LY Base Value],
                REMOVEFILTERS('Dim_ColMetric_VIC_KPIs'),
                'Dim_ColMetric_VIC_KPIs'[Metric_ID] = __QtyActMetricID_LY
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
    // VIC No. vs LP: Metric_ID=3，Act→1
    // T4-5 Upgrade No. vs LP: Metric_ID=12，Act→10
    // Retention VIC No. vs LP: Metric_ID=19，Act→17
    // Direct VIC No. vs LP: Metric_ID=25，Act→23
    // ═══════════════════════════════════════
    VAR __IsQtyVsLP = __MetricID IN {3, 12, 19, 25}
    VAR __QtyActMetricID_LP =
        SWITCH(__MetricID,
            3, 1,
            12, 10,
            19, 17,
            25, 23
        )
    VAR __QtyActValue_LP =
        IF(
            __IsQtyVsLP,
            CALCULATE(
                [VIC KPIs Act Base Value],
                REMOVEFILTERS('Dim_ColMetric_VIC_KPIs'),
                'Dim_ColMetric_VIC_KPIs'[Metric_ID] = __QtyActMetricID_LP
            )
        )
    VAR __QtyLPValue =
        IF(
            __IsQtyVsLP,
            CALCULATE(
                [VIC KPIs LP Base Value],
                REMOVEFILTERS('Dim_ColMetric_VIC_KPIs'),
                'Dim_ColMetric_VIC_KPIs'[Metric_ID] = __QtyActMetricID_LP
            )
        )
    VAR __QtyVsLPResult =
        IF(
            ISBLANK(__QtyLPValue) || __QtyLPValue = 0,
            BLANK(),
            DIVIDE(__QtyActValue_LP, __QtyLPValue) - 1
        )

    // ═══════════════════════════════════════
    // VIC Retention% 分组（Metric_ID 6/7/8）— 分母为 Rolling 12 个财月区间
    // 分子: is_retention_vic=1 的 Act/LY/LP DISTINCTCOUNT（Metric_ID=6 的 Act/LY/LP Base Value）
    // 分母: is_vic=1 的 Rolling 12 区间 DISTINCT 汇总（[VIC KPIs Rolling12 VIC Denominator Act/LY/LP]）
    // ═══════════════════════════════════════
    VAR __IsRetentionPct = __MetricID IN {6, 7, 8}
    VAR __IsRetentionVsLY = __MetricID = 7
    VAR __IsRetentionVsLP = __MetricID = 8

    // VIC Retention% 分子取值
    VAR __RetentionNumeratorAct =
        IF(
            __IsRetentionPct,
            CALCULATE(
                [VIC KPIs Act Base Value],
                REMOVEFILTERS('Dim_ColMetric_VIC_KPIs'),
                'Dim_ColMetric_VIC_KPIs'[Metric_ID] = 6
            )
        )
    VAR __RetentionNumeratorLY =
        IF(
            __IsRetentionVsLY,
            CALCULATE(
                [VIC KPIs LY Base Value],
                REMOVEFILTERS('Dim_ColMetric_VIC_KPIs'),
                'Dim_ColMetric_VIC_KPIs'[Metric_ID] = 6
            )
        )
    VAR __RetentionNumeratorLP =
        IF(
            __IsRetentionVsLP,
            CALCULATE(
                [VIC KPIs LP Base Value],
                REMOVEFILTERS('Dim_ColMetric_VIC_KPIs'),
                'Dim_ColMetric_VIC_KPIs'[Metric_ID] = 6
            )
        )

    // VIC Retention% 分母取值（Rolling 12 个财月区间 is_vic=1 DISTINCT 汇总）
    VAR __RetentionDenominatorAct =
        IF(
            __IsRetentionPct,
            [VIC KPIs Rolling12 VIC Denominator Act]
        )
    VAR __RetentionDenominatorLY =
        IF(
            __IsRetentionVsLY,
            [VIC KPIs Rolling12 VIC Denominator LY]
        )
    VAR __RetentionDenominatorLP =
        IF(
            __IsRetentionVsLP,
            [VIC KPIs Rolling12 VIC Denominator LP]
        )

    // VIC Retention% Act / vs LY / vs LP
    VAR __RetentionPctAct =
        IF(
            __MetricID = 6,
            DIVIDE(__RetentionNumeratorAct, __RetentionDenominatorAct)
        )
    VAR __RetentionPctVsLYResult =
        IF(
            __IsRetentionVsLY,
            DIVIDE(__RetentionNumeratorAct, __RetentionDenominatorAct)
            - DIVIDE(__RetentionNumeratorLY, __RetentionDenominatorLY)
        )
    VAR __RetentionPctVsLPResult =
        IF(
            __IsRetentionVsLP,
            DIVIDE(__RetentionNumeratorAct, __RetentionDenominatorAct)
            - DIVIDE(__RetentionNumeratorLP, __RetentionDenominatorLP)
        )

    // ═══════════════════════════════════════
    // Share 类（T4-5 / Retention / Direct）分组 — 分母为 end period 当月 is_vic=1
    // 分子: 对应 is_xxx_vic=1 的 Act/LY/LP DISTINCTCOUNT
    // 分母: is_vic=1 的 Act/LY/LP DISTINCTCOUNT（等价于 VIC No. Act/LY/LP，Metric_ID=1）
    // ═══════════════════════════════════════
    // Share Act: Metric_ID 14/20/26；Share vs LY: 15/21/27；Share vs LP: 16/22/28
    VAR __IsShare = __MetricID IN {14, 20, 26}
    VAR __IsShareVsLY = __MetricID IN {15, 21, 27}
    VAR __IsShareVsLP = __MetricID IN {16, 22, 28}
    VAR __IsShareDerived = __IsShareVsLY || __IsShareVsLP

    // 分子 Metric_ID
    VAR __ShareNumeratorMetricID =
        SWITCH(__MetricID,
            14, 14,  // T4-5 Upgrade No. Share Act
            15, 14,  // T4-5 Upgrade No. Share vs LY → 分子 Act Metric_ID=14
            16, 14,  // T4-5 Upgrade No. Share vs LP → 分子 Act Metric_ID=14
            20, 20,  // Retention VIC No. Share Act
            21, 20,  // Retention VIC No. Share vs LY → 分子 Act Metric_ID=20
            22, 20,  // Retention VIC No. Share vs LP → 分子 Act Metric_ID=20
            26, 26,  // Direct VIC No. Share Act
            27, 26,  // Direct VIC No. Share vs LY → 分子 Act Metric_ID=26
            28, 26   // Direct VIC No. Share vs LP → 分子 Act Metric_ID=26
        )

    // Share 分子取值
    VAR __ShareNumeratorAct =
        IF(
            __IsShare || __IsShareDerived,
            CALCULATE(
                [VIC KPIs Act Base Value],
                REMOVEFILTERS('Dim_ColMetric_VIC_KPIs'),
                'Dim_ColMetric_VIC_KPIs'[Metric_ID] = __ShareNumeratorMetricID
            )
        )
    VAR __ShareNumeratorLY =
        IF(
            __IsShareVsLY,
            CALCULATE(
                [VIC KPIs LY Base Value],
                REMOVEFILTERS('Dim_ColMetric_VIC_KPIs'),
                'Dim_ColMetric_VIC_KPIs'[Metric_ID] = __ShareNumeratorMetricID
            )
        )
    VAR __ShareNumeratorLP =
        IF(
            __IsShareVsLP,
            CALCULATE(
                [VIC KPIs LP Base Value],
                REMOVEFILTERS('Dim_ColMetric_VIC_KPIs'),
                'Dim_ColMetric_VIC_KPIs'[Metric_ID] = __ShareNumeratorMetricID
            )
        )

    // Share 分母取值（end period 当月 is_vic=1，等价于 VIC No. Act/LY/LP）
    VAR __ShareDenominatorAct =
        IF(
            __IsShare || __IsShareDerived,
            CALCULATE(
                [VIC KPIs Act Base Value],
                REMOVEFILTERS('Dim_ColMetric_VIC_KPIs'),
                'Dim_ColMetric_VIC_KPIs'[Metric_ID] = 1
            )
        )
    VAR __ShareDenominatorLY =
        IF(
            __IsShareVsLY,
            CALCULATE(
                [VIC KPIs LY Base Value],
                REMOVEFILTERS('Dim_ColMetric_VIC_KPIs'),
                'Dim_ColMetric_VIC_KPIs'[Metric_ID] = 1
            )
        )
    VAR __ShareDenominatorLP =
        IF(
            __IsShareVsLP,
            CALCULATE(
                [VIC KPIs LP Base Value],
                REMOVEFILTERS('Dim_ColMetric_VIC_KPIs'),
                'Dim_ColMetric_VIC_KPIs'[Metric_ID] = 1
            )
        )

    // Share Act / vs LY / vs LP
    VAR __ShareAct =
        IF(
            __IsShare,
            DIVIDE(__ShareNumeratorAct, __ShareDenominatorAct)
        )
    VAR __ShareVsLYResult =
        IF(
            __IsShareVsLY,
            DIVIDE(__ShareNumeratorAct, __ShareDenominatorAct)
            - DIVIDE(__ShareNumeratorLY, __ShareDenominatorLY)
        )
    VAR __ShareVsLPResult =
        IF(
            __IsShareVsLP,
            DIVIDE(__ShareNumeratorAct, __ShareDenominatorAct)
            - DIVIDE(__ShareNumeratorLP, __ShareDenominatorLP)
        )

    RETURN
        SWITCH(
            __MetricID,
            // ─── Act 本期值 ───
            1,  [VIC KPIs Act Base Value],      // VIC No. Act
            6,  __RetentionPctAct,               // VIC Retention% Act（Rolling 12 分母）
            10, [VIC KPIs Act Base Value],      // T4-5 Upgrade No. Act
            14, __ShareAct,                      // T4-5 Upgrade No. Share Act
            17, [VIC KPIs Act Base Value],      // Retention VIC No. Act
            20, __ShareAct,                      // Retention VIC No. Share Act
            23, [VIC KPIs Act Base Value],      // Direct VIC No. Act
            26, __ShareAct,                      // Direct VIC No. Share Act
            // ─── 数量类 vs LY 派生（今年 / 去年 - 1）───
            2,  __QtyVsLYResult,                 // VIC No. vs LY
            11, __QtyVsLYResult,                 // T4-5 Upgrade No. vs LY
            18, __QtyVsLYResult,                 // Retention VIC No. vs LY（特殊格式 percent_1dp）
            24, __QtyVsLYResult,                 // Direct VIC No. vs LY
            // ─── 数量类 vs LP 派生（当期 / 上期 - 1）───
            3,  __QtyVsLPResult,                 // VIC No. vs LP
            12, __QtyVsLPResult,                 // T4-5 Upgrade No. vs LP
            19, __QtyVsLPResult,                 // Retention VIC No. vs LP
            25, __QtyVsLPResult,                 // Direct VIC No. vs LP
            // ─── VIC Retention% vs LY / vs LP（Rolling 12 分母差值，×100 转 pts）───
            7,  __RetentionPctVsLYResult,        // VIC Retention% vs LY
            8,  __RetentionPctVsLPResult,        // VIC Retention% vs LP
            // ─── Share vs LY / vs LP 派生（end period 当月分母差值，×100 转 pts）───
            15, __ShareVsLYResult,               // T4-5 Upgrade No. Share vs LY
            16, __ShareVsLPResult,               // T4-5 Upgrade No. Share vs LP
            21, __ShareVsLYResult,               // Retention VIC No. Share vs LY
            22, __ShareVsLPResult,               // Retention VIC No. Share vs LP
            27, __ShareVsLYResult,               // Direct VIC No. Share vs LY
            28, __ShareVsLPResult,               // Direct VIC No. Share vs LP
            // ─── TAR ACH% 占位（值为 1，待逻辑确认后填充）───
            4,  1,                               // VIC Monthly TAR ACH%
            5,  1,                               // VIC Yearly TAR ACH%
            9,  1,                               // VIC Retention% TAR ACH%
            13, 1,                               // T4-5 Upgrade No. TAR ACH%
            BLANK()
        )
```

### 4.7 VIC KPIs Cell Value（对外值）

```dax
VIC KPIs Cell Value = 
// ========================================
// 度量值: VIC KPIs Cell Value
// Display Folder: Cell Values
// 用途: 对外暴露的单元格值，等于 Base Value
// 依赖: [VIC KPIs Base Value]
// ========================================
    [VIC KPIs Base Value]
```

### 4.8 VIC KPIs Cell Display（格式化显示，按 Metric_Format 单字段分发）

```dax
VIC KPIs Cell Display = 
// ========================================
// 度量值: VIC KPIs Cell Display
// Display Folder: Formatting
// 用途: 按 Metric_Format 单字段格式化显示（不再分 Act/LY/VsLY）
// 依赖: [VIC KPIs Cell Value],
//       'Dim_ColMetric_VIC_KPIs'[Metric_Format]
// 格式类型（严格遵循口径文档数据类型定义，以参考列维度表为准）:
//   integer       → 千分位整数：1,000
//   percent_1dp   → 百分比一位小数不含正号：14.5%
//                   （TAR ACH% / VIC Retention% / Share / Retention VIC No. vs LY）
//   delta_pct_1dp → 百分比变化含正号：+14.5% / -3.2%
//                   （数量类 vs LY / vs LP）
//   delta_pts     → 增减基点整数含正负号：+120pts / -80pts / 0pts
//                   （比率类 vs LY / vs LP / Share vs LY / Share vs LP，值×100 转 pts 在此处实现）
// 说明:
//   - BLANK 显示为 "-"
//   - 已扩展百分比整数等格式，便于后续快速调整
// ========================================
    VAR __Value = [VIC KPIs Cell Value]
    VAR __Format = SELECTEDVALUE('Dim_ColMetric_VIC_KPIs'[Metric_Format])

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

### 4.9 VIC KPIs Cell Font Color（字体颜色，按 Metric_ColorRule 分发）

```dax
VIC KPIs Cell Font Color = 
// ========================================
// 度量值: VIC KPIs Cell Font Color
// Display Folder: Formatting
// 用途: 按 Metric_ColorRule 字段分发字体颜色
// 依赖: [VIC KPIs Cell Value],
//       'Dim_ColMetric_VIC_KPIs'[Metric_ColorRule, Metric_ColorPositive/Negative/Zero/Default]
//
// 颜色规则（口径文档要求）:
//   1. VIC No.、VIC Retention%、T4-5 Upgrade No. 这三个基础指标的 Act 列固定 #252423
//      → Metric_ColorRule = "fixed_black"
//   2. 涉及 vs LY、vs LP、占比的 vs LY 和 vs LP、几个 TAR ACH% 达成率的指标
//      使用列维度表的颜色取值字段判断大小（正/负/零三色）
//      → Metric_ColorRule = "pos_neg_zero"
//   3. T4-5 Upgrade No. Share 等其余指标使用列指标维度中的 Metric_ColorDefault 默认颜色
//      → Metric_ColorRule = "fixed_default"
// ========================================
    VAR __Value = [VIC KPIs Cell Value]
    VAR __ColorRule = SELECTEDVALUE('Dim_ColMetric_VIC_KPIs'[Metric_ColorRule], "fixed_default")
    // ── 颜色取值（来自列维度表）──
    VAR __ColorPositive = SELECTEDVALUE('Dim_ColMetric_VIC_KPIs'[Metric_ColorPositive], "#1A9018")
    VAR __ColorNegative = SELECTEDVALUE('Dim_ColMetric_VIC_KPIs'[Metric_ColorNegative], "#D64550")
    VAR __ColorZero = SELECTEDVALUE('Dim_ColMetric_VIC_KPIs'[Metric_ColorZero], "#E1C233")
    VAR __ColorDefault = SELECTEDVALUE('Dim_ColMetric_VIC_KPIs'[Metric_ColorDefault], "#5F6165")

    RETURN
        SWITCH(
            __ColorRule,
            // ─── 固定黑色（VIC No. / VIC Retention% / T4-5 Upgrade No. 基础指标 Act 列）───
            "fixed_black",
                "#252423",
            // ─── 正/负/零三色（vs LY / vs LP / Share vs LY / Share vs LP / TAR ACH%）───
            "pos_neg_zero",
                SWITCH(
                    TRUE(),
                    ISBLANK(__Value), __ColorDefault,
                    __Value > 0,      __ColorPositive,
                    __Value < 0,      __ColorNegative,
                    __Value = 0,      __ColorZero,
                    __ColorDefault
                ),
            // ─── 默认颜色（T4-5 Upgrade No. Share / Retention VIC No. / Direct VIC No. 等）───
            "fixed_default",
                __ColorDefault,
            // ─── 兜底 ───
            __ColorDefault
        )
```

### 4.10 VIC KPIs Cell Background Color（背景色）

```dax
VIC KPIs Cell Background Color = 
// ========================================
// 度量值: VIC KPIs Cell Background Color
// Display Folder: Formatting
// 用途: 区分 KPIGroup 行（分组标题行）与 KPI 行的背景色
// 依赖: ISINSCOPE('Dim_ColMetric_VIC_KPIs'[ColName])
// 颜色规则:
//   KPIGroup 行（分组标题行）: #E6D9C7（中米色）
//   KPI 行（具体指标行）     : #FFFFFF（白色）
// ========================================
    VAR __IsKPIRow = ISINSCOPE('Dim_ColMetric_VIC_KPIs'[ColName])
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
|------|-----------|----------------|------|
| 1 | VIC KPIs Act Base Value | Base Metrics | 本期基础值（end period 当月 DISTINCTCOUNT） |
| 2 | VIC KPIs LY Base Value | Base Metrics | 去年同期基础值（财历映射 Last_Fiscal_Month_*_LY） |
| 3 | VIC KPIs LP Base Value | Base Metrics | 上期基础值（财历映射 Last_Fiscal_Month_*_LP） |
| 4 | VIC KPIs Rolling12 VIC Denominator Act | Base Metrics | VIC Retention% 本期分母（Rolling 12 个财月区间 is_vic=1 DISTINCT 汇总） |
| 5 | VIC KPIs Rolling12 VIC Denominator LY | Base Metrics | VIC Retention% LY 分母（Rolling 12，LY 区间） |
| 6 | VIC KPIs Rolling12 VIC Denominator LP | Base Metrics | VIC Retention% LP 分母（Rolling 12，LP 区间） |
| 7 | VIC KPIs Base Value | Base Metrics | 总路由（含 vs LY / vs LP / TAR ACH% / Share 派生 + REMOVEFILTERS） |
| 8 | VIC KPIs Cell Value | Cell Values | 对外值 = Base Value |
| 9 | VIC KPIs Cell Display | Formatting | 格式化显示文本（按 Metric_Format 单字段分发） |
| 10 | VIC KPIs Cell Font Color | Formatting | 字体颜色（按 Metric_ColorRule 分发） |
| 11 | VIC KPIs Cell Background Color | Formatting | 背景色（KPIGroup 行 vs KPI 行） |

---

## 6. 血缘关系图

```
┌─────────────────────────────────────────────────────────────────────┐
│                        数据源层                                      │
│  a03_e2e_customer_data_m（月度事实表）                               │
│  字段: data_date, platform, shop_info_id, user_id, is_member,       │
│        is_employee, is_vic, is_retention_vic, is_upgrade_vic,       │
│        is_direct_vic                                                │
└──────────────────────────────┬──────────────────────────────────────┘
                               │
                               │ 模型自动传递（行维度 = 事实表字段直接拉取）
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────────┐
│                        度量值层                                      │
│                                                                     │
│  ┌───────────────────────┐   ┌───────────────────────┐              │
│  │ VIC KPIs              │   │ VIC KPIs              │              │
│  │ Act Base Value        │   │ LY Base Value         │              │
│  │ (本期 end period 当月) │   │ (财历映射 LY)         │              │
│  └───────────┬───────────┘   └───────────┬───────────┘              │
│              │                           │                          │
│  ┌───────────────────────┐               │                          │
│  │ VIC KPIs              │               │                          │
│  │ LP Base Value         │               │                          │
│  │ (财历映射 LP)         │               │                          │
│  └───────────┬───────────┘               │                          │
│              │                            │                          │
│  ┌───────────────────────────────────┐   ┌───────────────────────┐  │
│  │ VIC KPIs Rolling12 VIC            │   │ Dim_ColMetric_VIC_KPIs│  │
│  │ Denominator Act/LY/LP             │   │ (断开维度, Metric_ID) │  │
│  │ (VIC Retention% 专用 Rolling 12)  │   └───────────────────────┘  │
│  │ EDATE(-11) + 维度表查 TimeFrame_Min│                              │
│  └───────────┬───────────────────────┘                              │
│              │                                                      │
│              ▼                                                      │
│  ┌───────────────────────────────────┐                              │
│  │ VIC KPIs Base Value               │                              │
│  │ (总路由 + 派生计算)                │                              │
│  │ REMOVEFILTERS + 目标 Metric_ID     │                              │
│  │ vs LY / vs LP / TAR ACH% / Share  │                              │
│  │ VIC Retention% 调用 Rolling12 分母 │                              │
│  │ Share 调用 Act Base Value (Metric_ID=1)                          │
│  └───────────────┬───────────────────┘                              │
│                  │                                                  │
│                  ▼                                                  │
│  ┌───────────────────────────────────┐                              │
│  │ VIC KPIs Cell Value               │                              │
│  │ (= Base Value)                    │                              │
│  └───────────────┬───────────────────┘                              │
│                  │                                                  │
│                  ▼                                                  │
│  ┌───────────────────────────────────┐   ┌───────────────────────┐  │
│  │ VIC KPIs Cell Display             │◄──│ Dim_ColMetric_VIC_KPIs│  │
│  │ (按 Metric_Format 单字段格式化)    │   │ (Metric_Format)       │  │
│  └───────────────┬───────────────────┘   └───────────────────────┘  │
│                  │                                                  │
│                  ▼                                                  │
│  ┌─────────────────────────────────────────────────────┐            │
│  │  VIC KPIs Cell Font Color                           │            │
│  │  VIC KPIs Cell Background Color                     │            │
│  │  (条件格式度量值，按 Metric_ColorRule 调度颜色)      │            │
│  └─────────────────────────────────────────────────────┘            │
└─────────────────────────────────────────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────────┐
│                        可视化层                                      │
│  Matrix 视觉对象                                                     │
│  行: 事实表字段（platform / shop_info_id，直接拉取）                  │
│  列: 'Dim_ColMetric_VIC_KPIs'[KPIGroup] > [ColName]                  │
│  值: [VIC KPIs Cell Display]                                         │
│  条件格式:                                                           │
│    字体颜色 → [VIC KPIs Cell Font Color]                             │
│    背景色   → [VIC KPIs Cell Background Color]                       │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 7. 矩阵视觉对象配置

### 7.1 字段配置

| 区域 | 字段 |
|------|------|
| **行** | 事实表字段（`a03_e2e_customer_data_m[platform]` / `[shop_info_id]`，直接拉取） |
| **列** | `'Dim_ColMetric_VIC_KPIs'[KPIGroup]` > `[ColName]` |
| **值** | `[VIC KPIs Cell Display]` |

### 7.2 排序配置

| 字段 | 排序依据 |
|------|---------|
| `'Dim_ColMetric_VIC_KPIs'[KPIGroup]` | `KPIGroup_Sort` |
| `'Dim_ColMetric_VIC_KPIs'[ColName]` | `ColName_Sort` |

### 7.3 格式设置

- 关闭"阶梯布局"（Stepped Layout → Off）
- 关闭"+/-"展开按钮
- 列标题：居中对齐，加粗
- 行标题：左对齐
- 值：居中对齐

### 7.4 条件格式

对 `[VIC KPIs Cell Display]` 值区域设置：

1. **字体颜色**：右键值区域 → 条件格式 → 字体颜色 → 格式样式：字段值 → 基于字段：`[VIC KPIs Cell Font Color]`
2. **背景颜色**：右键值区域 → 条件格式 → 背景颜色 → 格式样式：字段值 → 基于字段：`[VIC KPIs Cell Background Color]`

### 7.5 切片器配置

| 切片器 | 维度表 | 默认值 |
|--------|--------|--------|
| Time Frame Max | Slicer_Time_Frame_Max | — |
| Time Frame Min | Slicer_Time_Frame_Min | —（end period 逻辑仅需 Max） |
| Is Member | IsMemberFilter | TTL VIC（IsMember=0） |
| Is Employee | Slicer_Is_Employee_Selection | Yes（IsEmployee_Code=1） |
| Platform | Slicer_Platform_Selection | TM |
| Store | Slicer_Store_Name | TM |
| Currency | Slicer_Currency_Selection | RMB（本方案无金额类，不参与计算） |

---

## 8. 验证方法

### 8.1 矩阵结构验证

| 验证项 | 方法 |
|--------|------|
| 列数 | 确认 28 列（5 KPI 分组：VIC No. 5 列 + VIC Retention% 4 列 + T4-5 Upgrade No. 7 列 + Retention VIC No. 6 列 + Direct VIC No. 6 列） |
| 列排序 | KPIGroup 按 KPIGroup_Sort（10/20/30/40/50），ColName 按 ColName_Sort |
| 同名区分 | 确认各 KPI 同名 Act/vs LY/vs LP 在 ColName 中通过 Metric_ID 前缀区分 |
| KPIGroup 行颜色 | 字体黑色 #252423，背景中米色 #E6D9C7 |
| KPI 行颜色 | fixed_black → #252423；pos_neg_zero → 正/负/零三色；fixed_default → #5F6165 |
| 行展开 | platform 粒度行支持展开到 shop_info_id |

### 8.2 颜色规则验证

| Metric_ID | 指标 | Metric_ColorRule | 预期颜色行为 |
|-----------|------|------------------|------------|
| 1 | VIC No. | fixed_black | 始终 #252423 |
| 6 | VIC Retention% | fixed_black | 始终 #252423 |
| 10 | T4-5 Upgrade No. | fixed_black | 始终 #252423 |
| 2, 3 | VIC No. vs LY / vs LP | pos_neg_zero | 正绿/负红/零黄 |
| 4, 5, 9, 13 | TAR ACH% | pos_neg_zero | 正绿/负红/零黄 |
| 7, 8 | VIC Retention% vs LY / vs LP | pos_neg_zero | 正绿/负红/零黄 |
| 11, 12 | T4-5 Upgrade No. vs LY / vs LP | pos_neg_zero | 正绿/负红/零黄 |
| 15, 16 | T4-5 Upgrade No. Share vs LY / vs LP | pos_neg_zero | 正绿/负红/零黄 |
| 14 | T4-5 Upgrade No. Share | fixed_default | #5F6165 |
| 17 | Retention VIC No. | fixed_default | #5F6165 |
| 18, 19 | Retention VIC No. vs LY / vs LP | pos_neg_zero | 正绿/负红/零黄 |
| 20 | Retention VIC No. Share | fixed_default | #5F6165 |
| 21, 22 | Retention VIC No. Share vs LY / vs LP | pos_neg_zero | 正绿/负红/零黄 |
| 23 | Direct VIC No. | fixed_default | #5F6165 |
| 24, 25 | Direct VIC No. vs LY / vs LP | pos_neg_zero | 正绿/负红/零黄 |
| 26 | Direct VIC No. Share | fixed_default | #5F6165 |
| 27, 28 | Direct VIC No. Share vs LY / vs LP | pos_neg_zero | 正绿/负红/零黄 |

### 8.3 验证 SQL

```sql
-- VIC No.（本期 end period 当月 is_vic=1 的 DISTINCTCOUNT user_id）
-- 假设 __PeriodMin='2026-09-01', __PeriodMax='2026-09-30', __IsMemberFilter=0, __IsEmployeeFilter=1
SELECT
    COUNT(DISTINCT user_id) AS VIC_No_Actual
FROM a03_e2e_customer_data_m
WHERE is_vic = 1
  AND is_member = 0
  AND is_employee = 1
  AND data_date BETWEEN '2026-09-01' AND '2026-09-30';

-- VIC Retention%（分子 is_retention_vic=1，分母 Rolling 12 个财月 is_vic=1 区间 DISTINCT 汇总）
-- 分子: end period 当月 is_retention_vic=1
-- 分母: Rolling 12 个月区间（如 end period=2026-09，则区间=2025-10 ~ 2026-09）is_vic=1 的 DISTINCT user_id
SELECT
    (SELECT COUNT(DISTINCT user_id) FROM a03_e2e_customer_data_m
     WHERE is_retention_vic = 1 AND is_member = 0 AND is_employee = 1
       AND data_date BETWEEN '2026-09-01' AND '2026-09-30')  -- 分子
    * 1.0
    / (SELECT COUNT(DISTINCT user_id) FROM a03_e2e_customer_data_m
       WHERE is_vic = 1 AND is_member = 0 AND is_employee = 1
       AND data_date BETWEEN '2025-10-01' AND '2026-09-30')  -- 分母（Rolling 12）
    AS VIC_Retention_Pct_Actual;

-- T4-5 Upgrade No.（本期 end period 当月 is_upgrade_vic=1 的 DISTINCTCOUNT user_id）
SELECT
    COUNT(DISTINCT user_id) AS T4_5_Upgrade_No_Actual
FROM a03_e2e_customer_data_m
WHERE is_upgrade_vic = 1
  AND is_member = 0
  AND is_employee = 1
  AND data_date BETWEEN '2026-09-01' AND '2026-09-30';

-- T4-5 Upgrade No. Share（分子 end period 当月 is_upgrade_vic=1，分母 end period 当月 is_vic=1）
SELECT
    (SELECT COUNT(DISTINCT user_id) FROM a03_e2e_customer_data_m
     WHERE is_upgrade_vic = 1 AND is_member = 0 AND is_employee = 1
       AND data_date BETWEEN '2026-09-01' AND '2026-09-30')  -- 分子
    * 1.0
    / (SELECT COUNT(DISTINCT user_id) FROM a03_e2e_customer_data_m
       WHERE is_vic = 1 AND is_member = 0 AND is_employee = 1
       AND data_date BETWEEN '2026-09-01' AND '2026-09-30')  -- 分母（end period 当月）
    AS T4_5_Upgrade_No_Share_Actual;

-- VIC No. vs LY = (本期 VIC No.) / (LY VIC No.) - 1
-- LY 区间使用 Last_Fiscal_Month_Min_LY ~ Last_Fiscal_Month_Max_LY（如 2025-09-01 ~ 2025-09-30）

-- VIC Retention% vs LP = (当期 Retention%) - (LP Retention%)（差值，×100 转 pts）
-- LP 区间使用 Last_Fiscal_Month_Min_LP ~ Last_Fiscal_Month_Max_LP
-- 分母 Rolling 12 区间相应使用 LP 的 end period 往前推 11 个月
```

### 8.4 LY/LP 日期范围获取方式说明

| TimeFrame_ID | LY/LP 范围获取方式 | 说明 |
|--------------|---------------------|------|
| Month / Quarter / Year | 直接读 Slicer_Time_Frame_Max 的 `Last_Fiscal_Month_Min_LY/Max_LY/Min_LP/Max_LP` | 日期表已内置，无需 EDATE -12 或 Key 偏移 |
| Rolling 12 起始月 | `EDATE(Last_Fiscal_Month_Min, -11)` → 在维度表中查 `TimeFrame_Min` | VIC Retention% 分母专用 |

---

## 9. 注意事项

1. **end period 时间范围（关键逻辑）**：所有指标均使用 `Slicer_Time_Frame_Max[Last_Fiscal_Month_Min]` ~ `[Last_Fiscal_Month_Max]` 作为本期时间范围；LY 使用 `Last_Fiscal_Month_Min_LY` ~ `Last_Fiscal_Month_Max_LY`；LP 使用 `Last_Fiscal_Month_Min_LP` ~ `Last_Fiscal_Month_Max_LP`。这些字段已由 Slicer_Time_Frame_Max 日期维度表通过自关联计算得到，无需在 DAX 中重复实现。

2. **is_member / is_employee 双重筛选（关键逻辑）**：所有指标均应用 `is_member = SELECTEDVALUE(IsMemberFilter[IsMember], 0)` 和 `is_employee = SELECTEDVALUE(Slicer_Is_Employee_Selection[IsEmployee_Code], 1)` 筛选。默认值：is_member=0（TTL VIC），is_employee=1（Yes）。

3. **REMOVEFILTERS 机制**：派生指标（vs LY / vs LP / Share / Share vs LY / Share vs LP）的取值必须先 `REMOVEFILTERS('Dim_ColMetric_VIC_KPIs')` 再应用目标 Metric_ID，否则矩阵行标题保留的筛选器会导致冲突返回 BLANK。这与 PB_Merchandise_Fulfillment_detail_ms.md 的总路由范式完全一致。

4. **VIC Retention% 的 Rolling 12 个财月分母（关键逻辑，仅此指标使用）**：分母为"所选时间范围 end period 往前 Rolling 12 个财月 count(distinct user_id) where is_vic=1"。
   - Rolling 12 个财月 = 当前月 + 往前 11 个月，共 12 个月
   - 聚合方式：区间 DISTINCT 汇总（同一用户只计一次，非按月 SUM 累加）
   - 区间起始日获取：`EDATE(Last_Fiscal_Month_Min, -11)` 得到起始月，再用该月作为 `TimeFrame_Value` 去 `Slicer_Time_Frame_Max` 中匹配获取 `TimeFrame_Min`
   - 区间结束日 = `Last_Fiscal_Month_Max`
   - LY/LP 的 Rolling 12 区间同理使用 `Last_Fiscal_Month_*_LY` 和 `Last_Fiscal_Month_*_LP` 字段
   - 新增 3 个度量值：`[VIC KPIs Rolling12 VIC Denominator Act/LY/LP]`

5. **Share 类分母（end period 当月 is_vic=1）**：与 VIC Retention% 分母不同，Share 类指标（T4-5 Upgrade No. Share / Retention VIC No. Share / Direct VIC No. Share）的分母使用 end period 当月 `is_vic=1` 的人数，等价于 VIC No. Act（Metric_ID=1）。

6. **TAR ACH% 占位**：Metric_ID 4, 5, 9, 13 为占位指标，值固定为 1，待口径文档逻辑确认后再填充。

7. **Retention VIC No. vs LY 特殊格式**：Metric_ID 18（Retention VIC No. vs LY）的计算方式仍是 `今年 / 去年 - 1`（数量类），但数据格式为 `percent_1dp`（不含正号），严格遵循口径文档 4.1 的数据类型定义。

8. **格式字段精简（关键调整）**：
   - 不存在 `percent_1dp_signed` / `percent_1dp_nosign` 两个格式
   - 所有"不含正号的百分比"统一为 `percent_1dp`（格式串 `#,##0.0%`）
   - 所有"含正号的百分比变化"统一为 `delta_pct_1dp`（格式串 `IF(__Value>0,"+","") & FORMAT(__Value,"#,##0.0%")`）
   - TAR ACH% 口径文档标注"含正负号"，但按用户要求统一为 `percent_1dp`（不含正号）

9. **Metric_ID 编码规则**：
   - VIC No. 分组：1（Act）/ 2（vs LY）/ 3（vs LP）/ 4（Monthly TAR）/ 5（Yearly TAR）
   - VIC Retention% 分组：6（Act）/ 7（vs LY）/ 8（vs LP）/ 9（TAR）
   - T4-5 Upgrade No. 分组：10（Act）/ 11（vs LY）/ 12（vs LP）/ 13（TAR）/ 14（Share）/ 15（Share vs LY）/ 16（Share vs LP）
   - Retention VIC No. 分组：17（Act）/ 18（vs LY）/ 19（vs LP）/ 20（Share）/ 21（Share vs LY）/ 22（Share vs LP）
   - Direct VIC No. 分组：23（Act）/ 24（vs LY）/ 25（vs LP）/ 26（Share）/ 27（Share vs LY）/ 28（Share vs LP）

10. **颜色规则三值标识**：通过 `Metric_ColorRule` 字段三值（`fixed_black` / `pos_neg_zero` / `fixed_default`）统一调度字体颜色，便于后续扩展。
    - `fixed_black` → VIC No. / VIC Retention% / T4-5 Upgrade No. 三个基础指标的 Act 列
    - `pos_neg_zero` → vs LY / vs LP / Share vs LY / Share vs LP / TAR ACH% 派生指标
    - `fixed_default` → T4-5 Upgrade No. Share / Retention VIC No. / Retention VIC No. Share / Direct VIC No. / Direct VIC No. Share 等其余指标

11. **行维度处理**：无行维度表，直接拉取事实表字段（`platform` / `shop_info_id`），天然形成筛选与分组，DAX 度量值无需显式处理。模型自动传递筛选，支持 platform 粒度行展开看 shop_info_id 粒度明细数据。

12. **单一 Metric_Format 字段**：列指标维度表仅保留单个 `Metric_Format` 字段（不再区分 Act/LY/VsLY），因为每个指标对应一个格式。行格式严格遵循口径文档数据类型定义。

13. **扩展格式支持**：Cell Display 已扩展 `percent_0dp` / `percent_0dp_signed` / `percent_2dp` / `delta_pct_2dp` / `delta_pts_2dp` / `delta_bp` 等格式，便于后续快速调整。如需新增指标使用扩展格式，只需在 `Dim_ColMetric_VIC_KPIs` 的 `Metric_Format` 字段填入对应格式值即可。

14. **与 PB_Merchandise_Fulfillment_detail_ms.md 的关系**：本方案为 Customer Dashboard VIC Tab 的 KPI 矩阵 SWITCH 路由版本，与 PB Merchandise Fulfillment 版本共享相同的架构范式（断开列维度 + SWITCH 动态路由 + REMOVEFILTERS 修复上下文），差异在于：
    - 行维度由 merchandise 字段改为 customer 字段（platform / shop_info_id）
    - 列指标维度表替换为 Dim_ColMetric_VIC_KPIs（28 行 vs 36 行）
    - 数据底表由 a02_e2e_boss_performance_summary_d / a02_e2e_boss_fulfillment_request_data_d 改为 a03_e2e_customer_data_m（单一事实表）
    - 时间逻辑由"区间 SUM"改为"end period 当月 DISTINCTCOUNT"
    - 新增 is_member / is_employee 双重人群筛选
    - 新增 VIC Retention% 专用 Rolling 12 个财月分母度量值
    - 派生指标新增 vs LP / Share / Share vs LY / Share vs LP / TAR ACH% 等类型
    - 颜色规则由"按 ColType 判断"改为"按 Metric_ColorRule 字段三值标识统一调度"
    - 格式字段由三字段（Metric_Format_Act/LY/VsLY）精简为单字段（Metric_Format）
