# Power BI 解决方案 — VIC KPIs Pie Chart：T4-5 Upgrade No. / Retention VIC No. / Direct VIC No. Value/Display 度量

> status: ready
> created: 2026-08-13
> type: 度量值开发 + 饼图视觉对象
> 口径来源: 口径文档/VIC KPI.md - 3. T4-5 Upgrade No. / 4. Retention VIC No. / 5. Direct VIC No.
> 参考实现: RL E2E BOSS Dashboard/Performance by Merchandise/PB_Merchandise_Trend.md（Value/Display 范式）
> 底表: a03_e2e_customer_data_m

---

## 1. 需求理解

为 VIC Customer Dashboard 输出饼图所用的独立度量值（Value + Display），展示三个 VIC 子类型的本期 Act 数量构成：

| 指标 | 中文名 | 分类 | 底表字段 | is_xxx_vic |
|------|--------|------|---------|------------|
| T4-5 Upgrade No. | T4-5 升级 VIC 人数 | 数量类 | a03_e2e_customer_data_m | is_upgrade_vic=1 |
| Retention VIC No. | 留存 VIC 人数 | 数量类 | a03_e2e_customer_data_m | is_retention_vic=1 |
| Direct VIC No. | 直接 VIC 人数 | 数量类 | a03_e2e_customer_data_m | is_direct_vic=1 |

**核心设计原则**：
- 每个指标输出独立 Value + Display 度量对（本期 Act 一对），饼图场景仅展示本期快照，不涉及 LY / vs LY
- 度量值完全独立，不依赖 Dim_ColMetric_VIC_KPIs 断开维度、Metric_ID 路由体系，与 VIC_KPIs_Table.md 主表解耦
- 时间范围用 VIC 项目统一的 end period 当月区间（`Slicer_Time_Frame_Max[Last_Fiscal_Month_Min/Max]`），非 PB_Merchandise 的全局 TimeFrame_Min/Max
- 人群筛选保留 is_member / is_employee（与主表口径一致）
- 分组维度（platform / shop_info_id 等）由饼图图例直接拉取事实表字段天然形成筛选+分组，度量值内部不处理
- 一切口径以口径文档 VIC KPI.md 3/4/5 节为准

---

## 2. 现状分析

### 2.1 数据底表

| 对象 | 名称 | 出处 |
|------|------|------|
| 事实表 | a03_e2e_customer_data_m | 口径文档 全局逻辑 |
| 关键字段 | data_date, is_vic, is_upgrade_vic, is_retention_vic, is_direct_vic, is_member, is_employee, user_id, platform, shop_info_id | 口径文档 |

### 2.2 维度表清单（断开维度，沿用 VIC 项目现有切片器）

| 维度表 | 类型 | 连接方式 |
|--------|------|---------|
| Slicer_Time_Frame_Max | 断开维度 | SELECTEDVALUE 读取 `Last_Fiscal_Month_Min`（end period 当月起始日）、`Last_Fiscal_Month_Max`（end period 当月结束日） |
| Slicer_Is_Employee_Selection | 断开维度 | SELECTEDVALUE 读取 `IsEmployee_Code`（默认 1 = Yes） |
| IsMemberFilter | 断开维度 | SELECTEDVALUE 读取 `IsMember`（默认 0 = TTL VIC） |

> 本方案不使用 Slicer_Time_Frame_Min（VIC 端 end period 当月区间已在 Slicer_Time_Frame_Max 中预算）。

---

## 3. 方案设计

### 3.1 筛选上下文

| 筛选器 | 作用方式 | DAX 处理 |
|--------|---------|---------|
| Slicer_Time_Frame_Max | 断开维度，SELECTEDVALUE 读取 `Last_Fiscal_Month_Min/Max` | `data_date >= __PeriodMin AND data_date <= __PeriodMax` |
| Slicer_Is_Employee_Selection | 断开维度，SELECTEDVALUE 读取 `IsEmployee_Code` | `is_employee = __IsEmployeeFilter`（默认 1） |
| IsMemberFilter | 断开维度，SELECTEDVALUE 读取 `IsMember` | `is_member = __IsMemberFilter`（默认 0） |
| 事实表分组字段（platform / shop_info_id） | 饼图图例直接拉取，模型自动传递筛选 | DAX 无需显式处理 |

### 3.2 聚合粒度

三个指标均为 `DISTINCTCOUNT(user_id) WHERE is_xxx_vic = 1`，与主表 Metric_ID=10/17/23 的 Act 基础聚合口径完全一致。

### 3.3 格式规范

| 格式类型 | 格式串 | 示例 | 适用度量 |
|---------|--------|------|---------|
| integer | `#,##0` | 1,234 | T4-5 Upgrade No. / Retention VIC No. / Direct VIC No. Value & Display |

---

## 4. 度量值实现

---

### 指标 1：T4-5 Upgrade No.（T4-5 升级 VIC 人数）

> 数量类 · is_upgrade_vic=1 · DISTINCTCOUNT(user_id)
> 对应主表 Metric_ID=10 的 Act 基础聚合，但本度量值完全独立，不调用 [VIC KPIs Act Base Value]

### 4.1 T4-5 Upgrade No. Pie Value

```dax
T4-5 Upgrade No. Pie Value = 
// ========================================
// 度量值: T4-5 Upgrade No. Pie Value
// Display Folder: VIC Pie Chart
// 用途: T4-5 升级 VIC 人数（饼图数值）
// 口径来源: 口径文档/VIC KPI.md - 3. T4-5 Upgrade No.
// 计算公式: DISTINCTCOUNT(user_id) WHERE is_upgrade_vic = 1
// 筛选条件:
//   - data_date ∈ [Last_Fiscal_Month_Min, Last_Fiscal_Month_Max]（end period 当月）
//   - is_member = __IsMemberFilter（默认 0 = TTL VIC）
//   - is_employee = __IsEmployeeFilter（默认 1 = Yes）
//   - 分组维度由饼图图例直接拉取事实表字段自动传递
// 数据类型: integer → 整数，千分位整数
// 独立性: 不依赖 Metric_ID 路由，与 VIC_KPIs_Table.md 主表解耦
// ========================================
    VAR __PeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Max[Last_Fiscal_Month_Min])
    VAR __PeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max[Last_Fiscal_Month_Max])
    VAR __IsMemberFilter = SELECTEDVALUE(IsMemberFilter[IsMember], 0)
    VAR __IsEmployeeFilter = SELECTEDVALUE(Slicer_Is_Employee_Selection[IsEmployee_Code], 1)
    VAR __Result =
        CALCULATE(
            DISTINCTCOUNT('a03_e2e_customer_data_m'[user_id]),
            'a03_e2e_customer_data_m'[is_upgrade_vic] = 1,
            'a03_e2e_customer_data_m'[is_member] = __IsMemberFilter,
            'a03_e2e_customer_data_m'[is_employee] = __IsEmployeeFilter,
            'a03_e2e_customer_data_m'[data_date] >= __PeriodMin,
            'a03_e2e_customer_data_m'[data_date] <= __PeriodMax
        )
    RETURN __Result
```

### 4.2 T4-5 Upgrade No. Pie Display

```dax
T4-5 Upgrade No. Pie Display =
// ========================================
// 度量值: T4-5 Upgrade No. Pie Display
// Display Folder: VIC Pie Chart
// 用途: T4-5 升级 VIC 人数 格式化显示
// 依赖: [T4-5 Upgrade No. Pie Value]
// 格式类型: integer → #,##0
// ========================================
    VAR __Value = [T4-5 Upgrade No. Pie Value]
    RETURN
        IF(ISBLANK(__Value), "-", FORMAT(__Value, "#,##0"))
```

---

### 指标 2：Retention VIC No.（留存 VIC 人数）

> 数量类 · is_retention_vic=1 · DISTINCTCOUNT(user_id)
> 对应主表 Metric_ID=17 的 Act 基础聚合，但本度量值完全独立

### 4.3 Retention VIC No. Pie Value

```dax
Retention VIC No. Pie Value = 
// ========================================
// 度量值: Retention VIC No. Pie Value
// Display Folder: VIC Pie Chart
// 用途: 留存 VIC 人数（饼图数值）
// 口径来源: 口径文档/VIC KPI.md - 4. Retention VIC No.
// 计算公式: DISTINCTCOUNT(user_id) WHERE is_retention_vic = 1
// 筛选条件:
//   - data_date ∈ [Last_Fiscal_Month_Min, Last_Fiscal_Month_Max]（end period 当月）
//   - is_member = __IsMemberFilter（默认 0 = TTL VIC）
//   - is_employee = __IsEmployeeFilter（默认 1 = Yes）
//   - 分组维度由饼图图例直接拉取事实表字段自动传递
// 数据类型: integer → 整数，千分位整数
// 独立性: 不依赖 Metric_ID 路由，与 VIC_KPIs_Table.md 主表解耦
// ========================================
    VAR __PeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Max[Last_Fiscal_Month_Min])
    VAR __PeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max[Last_Fiscal_Month_Max])
    VAR __IsMemberFilter = SELECTEDVALUE(IsMemberFilter[IsMember], 0)
    VAR __IsEmployeeFilter = SELECTEDVALUE(Slicer_Is_Employee_Selection[IsEmployee_Code], 1)
    VAR __Result =
        CALCULATE(
            DISTINCTCOUNT('a03_e2e_customer_data_m'[user_id]),
            'a03_e2e_customer_data_m'[is_retention_vic] = 1,
            'a03_e2e_customer_data_m'[is_member] = __IsMemberFilter,
            'a03_e2e_customer_data_m'[is_employee] = __IsEmployeeFilter,
            'a03_e2e_customer_data_m'[data_date] >= __PeriodMin,
            'a03_e2e_customer_data_m'[data_date] <= __PeriodMax
        )
    RETURN __Result
```

### 4.4 Retention VIC No. Pie Display

```dax
Retention VIC No. Pie Display =
// ========================================
// 度量值: Retention VIC No. Pie Display
// Display Folder: VIC Pie Chart
// 用途: 留存 VIC 人数 格式化显示
// 依赖: [Retention VIC No. Pie Value]
// 格式类型: integer → #,##0
// ========================================
    VAR __Value = [Retention VIC No. Pie Value]
    RETURN
        IF(ISBLANK(__Value), "-", FORMAT(__Value, "#,##0"))
```

---

### 指标 3：Direct VIC No.（直接 VIC 人数）

> 数量类 · is_direct_vic=1 · DISTINCTCOUNT(user_id)
> 对应主表 Metric_ID=23 的 Act 基础聚合，但本度量值完全独立

### 4.5 Direct VIC No. Pie Value

```dax
Direct VIC No. Pie Value = 
// ========================================
// 度量值: Direct VIC No. Pie Value
// Display Folder: VIC Pie Chart
// 用途: 直接 VIC 人数（饼图数值）
// 口径来源: 口径文档/VIC KPI.md - 5. Direct VIC No.
// 计算公式: DISTINCTCOUNT(user_id) WHERE is_direct_vic = 1
// 筛选条件:
//   - data_date ∈ [Last_Fiscal_Month_Min, Last_Fiscal_Month_Max]（end period 当月）
//   - is_member = __IsMemberFilter（默认 0 = TTL VIC）
//   - is_employee = __IsEmployeeFilter（默认 1 = Yes）
//   - 分组维度由饼图图例直接拉取事实表字段自动传递
// 数据类型: integer → 整数，千分位整数
// 独立性: 不依赖 Metric_ID 路由，与 VIC_KPIs_Table.md 主表解耦
// ========================================
    VAR __PeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Max[Last_Fiscal_Month_Min])
    VAR __PeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max[Last_Fiscal_Month_Max])
    VAR __IsMemberFilter = SELECTEDVALUE(IsMemberFilter[IsMember], 0)
    VAR __IsEmployeeFilter = SELECTEDVALUE(Slicer_Is_Employee_Selection[IsEmployee_Code], 1)
    VAR __Result =
        CALCULATE(
            DISTINCTCOUNT('a03_e2e_customer_data_m'[user_id]),
            'a03_e2e_customer_data_m'[is_direct_vic] = 1,
            'a03_e2e_customer_data_m'[is_member] = __IsMemberFilter,
            'a03_e2e_customer_data_m'[is_employee] = __IsEmployeeFilter,
            'a03_e2e_customer_data_m'[data_date] >= __PeriodMin,
            'a03_e2e_customer_data_m'[data_date] <= __PeriodMax
        )
    RETURN __Result
```

### 4.6 Direct VIC No. Pie Display

```dax
Direct VIC No. Pie Display =
// ========================================
// 度量值: Direct VIC No. Pie Display
// Display Folder: VIC Pie Chart
// 用途: 直接 VIC 人数 格式化显示
// 依赖: [Direct VIC No. Pie Value]
// 格式类型: integer → #,##0
// ========================================
    VAR __Value = [Direct VIC No. Pie Value]
    RETURN
        IF(ISBLANK(__Value), "-", FORMAT(__Value, "#,##0"))
```

---

## 5. 度量值清单与 Display Folder

| 序号 | 度量值名称 | Display Folder | 指标 | 类型 | 格式 |
|------|-----------|----------------|------|------|------|
| 1 | T4-5 Upgrade No. Pie Value | VIC Pie Chart | T4-5 Upgrade No. | Value | integer |
| 2 | T4-5 Upgrade No. Pie Display | VIC Pie Chart | T4-5 Upgrade No. | Display | integer |
| 3 | Retention VIC No. Pie Value | VIC Pie Chart | Retention VIC No. | Value | integer |
| 4 | Retention VIC No. Pie Display | VIC Pie Chart | Retention VIC No. | Display | integer |
| 5 | Direct VIC No. Pie Value | VIC Pie Chart | Direct VIC No. | Value | integer |
| 6 | Direct VIC No. Pie Display | VIC Pie Chart | Direct VIC No. | Display | integer |

---

## 6. 视觉对象配置

### 6.1 饼图（Pie Chart）

| 配置项 | 值 |
|--------|-----|
| 图例（分组） | 可选：a03_e2e_customer_data_m[platform] 或 [shop_info_id]（直接拉取，天然筛选+分组）；不拉分组字段时饼图展示三个指标的整体构成 |
| 值 | 三个 Value 度量：[T4-5 Upgrade No. Pie Value]、[Retention VIC No. Pie Value]、[Direct VIC No. Pie Value] |
| 详情 | 可选拉 Display 度量替代 Value，带格式显示 |
| 全局筛选器 | Slicer_Time_Frame_Max、Slicer_Is_Employee_Selection、IsMemberFilter |

> 饼图场景：三个 Value 度量分别对应饼图三块扇区，展示本期 end period 当月三个 VIC 子类型的 DISTINCTCOUNT(user_id) 构成。

### 6.2 度量值拉取示例

| 场景 | 拉取度量 |
|------|---------|
| 饼图 - T4-5 升级 VIC 人数 | [T4-5 Upgrade No. Pie Display] |
| 饼图 - 留存 VIC 人数 | [Retention VIC No. Pie Display] |
| 饼图 - 直接 VIC 人数 | [Direct VIC No. Pie Display] |

---

## 7. 验证方法

### 7.1 验证 SQL

```sql
-- 三个 VIC 子类型本期 Act 数量（end period 当月）
-- 假设 Last_Fiscal_Month_Min='2026-09-01', Last_Fiscal_Month_Max='2026-09-30'
-- is_member=0 (TTL VIC), is_employee=1 (Yes)
SELECT
    COUNT(DISTINCT CASE WHEN is_upgrade_vic = 1 THEN user_id END) AS T4_5_Upgrade_No,
    COUNT(DISTINCT CASE WHEN is_retention_vic = 1 THEN user_id END) AS Retention_VIC_No,
    COUNT(DISTINCT CASE WHEN is_direct_vic = 1 THEN user_id END) AS Direct_VIC_No
FROM a03_e2e_customer_data_m
WHERE data_date BETWEEN '2026-09-01' AND '2026-09-30'
  AND is_member = 0
  AND is_employee = 1;
```

---

## 8. 注意事项

1. **独立性**：本方案三个指标完全独立实现，不调用 [VIC KPIs Act Base Value] 或 [VIC KPIs Base Value]，不依赖 Dim_ColMetric_VIC_KPIs / Metric_ID 路由体系。即使主表度量值变更，饼图度量值不受影响。

2. **时间范围**：用 VIC 项目统一的 end period 当月区间（`Last_Fiscal_Month_Min/Max`），非 PB_Merchandise 的全局 `TimeFrame_Min/Max`。若需要切换为 Rolling 12 或其他区间，需调整 `__PeriodMin/Max` 的取值逻辑。

3. **人群筛选保留**：is_member（默认 0 = TTL VIC）和 is_employee（默认 1 = Yes）与主表口径一致，确保饼图与主表 KPI 矩阵展示同一人群切片。若饼图需要展示不同人群，可通过切片器切换。

4. **分组维度传递**：platform / shop_info_id 等分组字段由饼图图例直接拉取事实表字段，DAX 度量值无需显式处理分组逻辑，模型自动传递筛选。

5. **仅本期 Act**：本方案不输出 LY / vs LY / vs LP / Share 派生度量值，饼图仅展示本期快照。若需要对比派生，参考 VIC_KPIs_Table.md 主表的 Metric_ID=11/18/24（vs LY）、12/19/25（vs LP）、14/20/26（Share）。

6. **口径等价性**：本方案三个 Value 度量与主表 Metric_ID=10/17/23 的 Act 基础聚合（[VIC KPIs Act Base Value] 在对应 Metric_ID 下的返回值）口径完全等价，可用作主表数据的饼图可视化呈现。

7. **Display 命名约定**：遵循 PB_Merchandise_Trend.md 风格，每个指标出 Value + Display 一对，便于饼图按需拉取 Value（用于排序/数据条）或 Display（用于带格式文本）。
