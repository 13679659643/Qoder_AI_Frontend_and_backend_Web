# Power BI 解决方案 — PB Merchandise：子模块一 + 子模块二 Value/Display 度量

> status: ready
> created: 2026-08-07
> type: 度量值开发 + 条形图视觉对象
> 口径来源: 口径文档/PB Merchandise.md 子模块一 BOSS Fulfillment - Fulfillment% by Label、子模块二 BOSS M/W POLO Unfulfilled Order by Category
> 参考实现: Performance By Location/PB_Location_Sales_detail.md（Value/Display 范式）
> 底表: a02_e2e_boss_performance_summary_d

---

## 1. 需求理解

为 Performance By Merchandise 页面子模块一、子模块二输出条形图所用的独立度量值（Value + Display），无 X 轴时间维度：

| 子模块 | 指标 | 中文名 | 分类 | calc_type | 底表字段 |
|--------|------|--------|------|-----------|---------|
| 一 | Fulfillment% | O2O订单履约率 | 比率类 | fulfillment | o2o_fulfillment_shipped_order_cnt / o2o_fulfillment_request_order_cnt |
| 一 | Request Order Qty | O2O销售订单量（分母项） | 数量类 | fulfillment | o2o_fulfillment_request_order_cnt |
| 一 | Shipped Order Qty | O2O已配货订单量（分子项） | 数量类 | fulfillment | o2o_fulfillment_shipped_order_cnt |
| 二 | Total Unfulfilled Order | O2O失败订单数（W Polo + M Polo） | 数量类 | fulfillment | o2o_fulfillment_unshipped_order_cnt |
| 二 | W Polo Unfulfilled Order | O2O失败订单数（W Polo） | 数量类 | fulfillment | o2o_fulfillment_unshipped_order_cnt |
| 二 | M Polo Unfulfilled Order | O2O失败订单数（M Polo） | 数量类 | fulfillment | o2o_fulfillment_unshipped_order_cnt |
| 二 | W Polo Unfulfilled Order Share | W Polo O2O失败订单数占比 | 比率类 | fulfillment | W Polo / Total（派生） |
| 二 | M Polo Unfulfilled Order Share | M Polo O2O失败订单数占比 | 比率类 | fulfillment | M Polo / Total（派生） |

**核心设计原则**：
- 每个指标输出独立 Value + Display 度量对（本期 Act 一对），条形图场景不涉及 LY / vs LY
- 度量值内部不处理分组维度（brand / category_summary 由视觉对象直接拉取事实表字段天然形成筛选+分组）
- 仅用全局时间范围筛选（Slicer_Time_Frame_Min / Slicer_Time_Frame_Max），无 X 轴时间段双层筛选
- 一切口径以口径文档 PB Merchandise.md 子模块一、子模块二为准
- brand 字段取值以子模块二具体指标定义为准：`brand in ("W Polo", "M Polo")`

---

## 2. 现状分析

### 2.1 数据底表

| 对象 | 名称 | 出处 |
|------|------|------|
| 事实表 | a02_e2e_boss_performance_summary_d | 口径文档 全局逻辑 |
| 关键字段 | data_date, brand, category, category_summary, calc_type, o2o_fulfillment_shipped_order_cnt, o2o_fulfillment_request_order_cnt, o2o_fulfillment_unshipped_order_cnt | 口径文档 |

### 2.2 维度表清单（断开维度，沿用项目现有切片器）

| 维度表 | 类型 | 连接方式 |
|--------|------|---------|
| Slicer_Time_Frame_Min | 断开维度 | 起始切片器；SELECTEDVALUE 读取 TimeFrame_Min |
| Slicer_Time_Frame_Max | 断开维度 | 结束切片器；SELECTEDVALUE 读取 TimeFrame_Max |

> 子模块一/二均为数量/比率类指标，不涉及币种换算，不需要 Slicer_Currency_Selection。

---

## 3. 方案设计

### 3.1 筛选上下文

| 筛选器 | 作用方式 | DAX 处理 |
|--------|---------|---------|
| Slicer_Time_Frame_Min | 断开维度，SELECTEDVALUE 读取 TimeFrame_Min | `data_date >= __TimeMin` |
| Slicer_Time_Frame_Max | 断开维度，SELECTEDVALUE 读取 TimeFrame_Max | `data_date <= __TimeMax` |
| 事实表分组字段（brand / category_summary） | 条形图轴直接拉取，模型自动传递筛选 | DAX 无需显式处理（子模块二 brand 硬编码例外，见 3.3） |

> calc_type 在子模块一/二均固定为 "fulfillment"，直接硬编码。

### 3.2 子模块二 brand 硬编码与 REMOVEFILTERS 规则

子模块二需按 brand 硬编码筛选（"W Polo"、"M Polo" 或两者），同时口径文档要求：

> "category_summary 我会直接拉取事实表中的对应字段，对模型天然自带筛选和分组属性，所以这里计算总值需要 REMOVEFILTERS 移除 a02_e2e_boss_performance_summary_d[category] 字段的影响。"

**DAX 处理策略**：
- 三个数量类指标（Total / W Polo / M Polo Unfulfilled Order）的 Value 度量，在 CALCULATE 中使用 `REMOVEFILTERS('a02_e2e_boss_performance_summary_d'[category])`，确保按 category_summary 分组时，每个 category_summary 汇总值不受 category 维度筛选影响
- brand 筛选硬编码在度量值内部（Total/W Polo/M Polo 三档分别 hardcode）
- 占比类指标基于上述三个数量类度量派生（分子分母已自带 REMOVEFILTERS，无需重复）

### 3.3 格式规范

| 格式类型 | 格式串 | 示例 | 适用度量 |
|---------|--------|------|---------|
| percent_1dp | `#,##0.0%` | 92.3% | Fulfillment%、W/M Polo Unfulfilled Order Share |
| integer | `#,##0` | 1,234 | Request Order Qty / Shipped Order Qty / Total/W/M Polo Unfulfilled Order |

---

## 4. 度量值实现

---

## 子模块一：BOSS Fulfillment - Fulfillment% by Label

> 分组维度：条形图按 `brand` 分组（直接拉取事实表字段天然筛选+分组），度量值内部不处理 brand
> calc_type = "fulfillment" · 底表 a02_e2e_boss_performance_summary_d

---

### 指标 1：Fulfillment%（O2O订单履约率）

> 比率类 · SUM(o2o_fulfillment_shipped_order_cnt) / SUM(o2o_fulfillment_request_order_cnt)
> 比率类不除汇率（数量类相除自动抵消）

### 4.1 PBM Fulfillment% by Label Value

```dax
PBM Fulfillment% by Label Value =
// ========================================
// 度量值: Fulfillment% by Label Value
// Display Folder: PB Merchandise
// 用途: O2O订单履约率 by Label（条形图数值）
// 口径来源: PB Merchandise.md 子模块一 - Fulfillment%
// 计算公式: SUM(o2o_fulfillment_shipped_order_cnt) / SUM(o2o_fulfillment_request_order_cnt)
//   分子: o2o_fulfillment_shipped_order_cnt
//   分母: o2o_fulfillment_request_order_cnt
// 筛选条件:
//   - calc_type = "fulfillment"
//   - data_date ∈ [__TimeMin, __TimeMax]（全局时间范围）
//   - 分组维度 brand 由条形图 Y 轴直接拉取事实表字段自动传递
//   - 比率类，不除汇率（数量类相除自动抵消）
// 数据类型: percent_1dp → 百分比，保留一位小数，不含正号
// ========================================
    VAR __TimeMin = SELECTEDVALUE(Slicer_Time_Frame_Min[TimeFrame_Min])
    VAR __TimeMax = SELECTEDVALUE(Slicer_Time_Frame_Max[TimeFrame_Max])
    // 分子：o2o_fulfillment_shipped_order_cnt
    VAR __Numerator =
        CALCULATE(
            SUM('a02_e2e_boss_performance_summary_d'[o2o_fulfillment_shipped_order_cnt]),
            'a02_e2e_boss_performance_summary_d'[calc_type] = "fulfillment",
            'a02_e2e_boss_performance_summary_d'[data_date] >= __TimeMin,
            'a02_e2e_boss_performance_summary_d'[data_date] <= __TimeMax
        )
    // 分母：o2o_fulfillment_request_order_cnt
    VAR __Denominator =
        CALCULATE(
            SUM('a02_e2e_boss_performance_summary_d'[o2o_fulfillment_request_order_cnt]),
            'a02_e2e_boss_performance_summary_d'[calc_type] = "fulfillment",
            'a02_e2e_boss_performance_summary_d'[data_date] >= __TimeMin,
            'a02_e2e_boss_performance_summary_d'[data_date] <= __TimeMax
        )
    RETURN DIVIDE(__Numerator, __Denominator)
```

### 4.2 PBM Fulfillment% by Label Display

```dax
PBM Fulfillment% by Label Display =
// ========================================
// 度量值: Fulfillment% by Label Display
// Display Folder: PB Merchandise
// 用途: O2O订单履约率 by Label 格式化显示
// 依赖: [Fulfillment% by Label Value]
// 格式类型: percent_1dp → #,##0.0%
// ========================================
    VAR __Value = [Fulfillment% by Label Value]
    RETURN
        IF(ISBLANK(__Value), "-", FORMAT(__Value, "#,##0.0%"))
```

---

### 指标 2：Request Order Qty（O2O销售订单量 - 分母项）

> 数量类 · calc_type = "fulfillment" · SUM(o2o_fulfillment_request_order_cnt)

### 4.3 Request Order Qty by Label Value

```dax
Request Order Qty by Label Value =
// ========================================
// 度量值: Request Order Qty by Label Value
// Display Folder: PB Merchandise
// 用途: O2O销售订单量（分母项）by Label（条形图数值）
// 口径来源: PB Merchandise.md 子模块一 - Request Order Qty
// 计算公式: SUM(o2o_fulfillment_request_order_cnt)
// 筛选条件:
//   - calc_type = "fulfillment"
//   - data_date ∈ [__TimeMin, __TimeMax]（全局时间范围）
//   - 分组维度 brand 由条形图 Y 轴直接拉取事实表字段自动传递
// 数据类型: integer → 整数，千分位整数
// ========================================
    VAR __TimeMin = SELECTEDVALUE(Slicer_Time_Frame_Min[TimeFrame_Min])
    VAR __TimeMax = SELECTEDVALUE(Slicer_Time_Frame_Max[TimeFrame_Max])
    VAR __Result =
        CALCULATE(
            SUM('a02_e2e_boss_performance_summary_d'[o2o_fulfillment_request_order_cnt]),
            'a02_e2e_boss_performance_summary_d'[calc_type] = "fulfillment",
            'a02_e2e_boss_performance_summary_d'[data_date] >= __TimeMin,
            'a02_e2e_boss_performance_summary_d'[data_date] <= __TimeMax
        )
    RETURN __Result
```

### 4.4 Request Order Qty by Label Display

```dax
Request Order Qty by Label Display =
// ========================================
// 度量值: Request Order Qty by Label Display
// Display Folder: PB Merchandise
// 用途: O2O销售订单量（分母项）by Label 格式化显示
// 依赖: [Request Order Qty by Label Value]
// 格式类型: integer → #,##0
// ========================================
    VAR __Value = [Request Order Qty by Label Value]
    RETURN
        IF(ISBLANK(__Value), "-", FORMAT(__Value, "#,##0"))
```

---

### 指标 3：Shipped Order Qty（O2O已配货订单量 - 分子项）

> 数量类 · calc_type = "fulfillment" · SUM(o2o_fulfillment_shipped_order_cnt)

### 4.5 Shipped Order Qty by Label Value

```dax
Shipped Order Qty by Label Value =
// ========================================
// 度量值: Shipped Order Qty by Label Value
// Display Folder: PB Merchandise
// 用途: O2O已配货订单量（分子项）by Label（条形图数值）
// 口径来源: PB Merchandise.md 子模块一 - Shipped Order Qty
// 计算公式: SUM(o2o_fulfillment_shipped_order_cnt)
// 筛选条件:
//   - calc_type = "fulfillment"
//   - data_date ∈ [__TimeMin, __TimeMax]（全局时间范围）
//   - 分组维度 brand 由条形图 Y 轴直接拉取事实表字段自动传递
// 数据类型: integer → 整数，千分位整数
// ========================================
    VAR __TimeMin = SELECTEDVALUE(Slicer_Time_Frame_Min[TimeFrame_Min])
    VAR __TimeMax = SELECTEDVALUE(Slicer_Time_Frame_Max[TimeFrame_Max])
    VAR __Result =
        CALCULATE(
            SUM('a02_e2e_boss_performance_summary_d'[o2o_fulfillment_shipped_order_cnt]),
            'a02_e2e_boss_performance_summary_d'[calc_type] = "fulfillment",
            'a02_e2e_boss_performance_summary_d'[data_date] >= __TimeMin,
            'a02_e2e_boss_performance_summary_d'[data_date] <= __TimeMax
        )
    RETURN __Result
```

### 4.6 Shipped Order Qty by Label Display

```dax
Shipped Order Qty by Label Display =
// ========================================
// 度量值: Shipped Order Qty by Label Display
// Display Folder: PB Merchandise
// 用途: O2O已配货订单量（分子项）by Label 格式化显示
// 依赖: [Shipped Order Qty by Label Value]
// 格式类型: integer → #,##0
// ========================================
    VAR __Value = [Shipped Order Qty by Label Value]
    RETURN
        IF(ISBLANK(__Value), "-", FORMAT(__Value, "#,##0"))
```

---

## 子模块二：BOSS M/W POLO Unfulfilled Order by Category

> 分组维度：条形图按 `category_summary` 分组（直接拉取事实表字段天然筛选+分组）
> brand 硬编码筛选：W Polo + M Polo（以子模块二具体指标定义为准）
> calc_type = "fulfillment" · 底表 a02_e2e_boss_performance_summary_d
> 关键约束：计算总值需 REMOVEFILTERS 移除 a02_e2e_boss_performance_summary_d[category] 字段的影响

---

### 指标 4：Total Unfulfilled Order（O2O失败订单数 - W Polo + M Polo）

> 数量类 · brand in ("W Polo", "M Polo") · SUM(o2o_fulfillment_unshipped_order_cnt)
> REMOVEFILTERS(category) 确保 category_summary 分组时汇总值不被 category 筛选影响

### 4.7 Total Unfulfilled Order Value

```dax
Total Unfulfilled Order Value =
// ========================================
// 度量值: Total Unfulfilled Order Value
// Display Folder: PB Merchandise
// 用途: O2O失败订单数（W Polo + M Polo）by category_summary（条形图数值）
// 口径来源: PB Merchandise.md 子模块二 - Total Unfulfilled Order
// 计算公式: SUM(o2o_fulfillment_unshipped_order_cnt)
// 筛选条件:
//   - calc_type = "fulfillment"
//   - brand in ("W Polo", "M Polo")
//   - data_date ∈ [__TimeMin, __TimeMax]（全局时间范围）
//   - 分组维度 category_summary 由条形图 Y 轴直接拉取事实表字段自动传递
//   - REMOVEFILTERS(a02_e2e_boss_performance_summary_d[category])：按 category_summary
//     分组时移除 category 维度筛选影响，确保汇总值正确
// 数据类型: integer → 整数，千分位整数
// ========================================
    VAR __TimeMin = SELECTEDVALUE(Slicer_Time_Frame_Min[TimeFrame_Min])
    VAR __TimeMax = SELECTEDVALUE(Slicer_Time_Frame_Max[TimeFrame_Max])
    VAR __Result =
        CALCULATE(
            SUM('a02_e2e_boss_performance_summary_d'[o2o_fulfillment_unshipped_order_cnt]),
            'a02_e2e_boss_performance_summary_d'[calc_type] = "fulfillment",
            'a02_e2e_boss_performance_summary_d'[brand] IN {"W Polo", "M Polo"},
            'a02_e2e_boss_performance_summary_d'[data_date] >= __TimeMin,
            'a02_e2e_boss_performance_summary_d'[data_date] <= __TimeMax,
            REMOVEFILTERS('a02_e2e_boss_performance_summary_d'[category])
        )
    RETURN __Result
```

### 4.8 Total Unfulfilled Order Display

```dax
Total Unfulfilled Order Display =
// ========================================
// 度量值: Total Unfulfilled Order Display
// Display Folder: PB Merchandise
// 用途: O2O失败订单数（W Polo + M Polo）格式化显示
// 依赖: [Total Unfulfilled Order Value]
// 格式类型: integer → #,##0
// ========================================
    VAR __Value = [Total Unfulfilled Order Value]
    RETURN
        IF(ISBLANK(__Value), "-", FORMAT(__Value, "#,##0"))
```

---

### 指标 5：W Polo Unfulfilled Order（O2O失败订单数 - W Polo）

> 数量类 · brand = "W Polo" · SUM(o2o_fulfillment_unshipped_order_cnt)

### 4.9 W Polo Unfulfilled Order Value

```dax
W Polo Unfulfilled Order Value =
// ========================================
// 度量值: W Polo Unfulfilled Order Value
// Display Folder: PB Merchandise
// 用途: O2O失败订单数（W Polo）by category_summary（条形图数值）
// 口径来源: PB Merchandise.md 子模块二 - W Polo Unfulfilled Order
// 计算公式: SUM(o2o_fulfillment_unshipped_order_cnt)
// 筛选条件:
//   - calc_type = "fulfillment"
//   - brand = "W Polo"
//   - data_date ∈ [__TimeMin, __TimeMax]（全局时间范围）
//   - 分组维度 category_summary 由条形图 Y 轴直接拉取事实表字段自动传递
// 数据类型: integer → 整数，千分位整数
// ========================================
    VAR __TimeMin = SELECTEDVALUE(Slicer_Time_Frame_Min[TimeFrame_Min])
    VAR __TimeMax = SELECTEDVALUE(Slicer_Time_Frame_Max[TimeFrame_Max])
    VAR __Result =
        CALCULATE(
            SUM('a02_e2e_boss_performance_summary_d'[o2o_fulfillment_unshipped_order_cnt]),
            'a02_e2e_boss_performance_summary_d'[calc_type] = "fulfillment",
            'a02_e2e_boss_performance_summary_d'[brand] = "W Polo",
            'a02_e2e_boss_performance_summary_d'[data_date] >= __TimeMin,
            'a02_e2e_boss_performance_summary_d'[data_date] <= __TimeMax
        )
    RETURN __Result
```

### 4.10 W Polo Unfulfilled Order Display

```dax
W Polo Unfulfilled Order Display =
// ========================================
// 度量值: W Polo Unfulfilled Order Display
// Display Folder: PB Merchandise
// 用途: O2O失败订单数（W Polo）格式化显示
// 依赖: [W Polo Unfulfilled Order Value]
// 格式类型: integer → #,##0
// ========================================
    VAR __Value = [W Polo Unfulfilled Order Value]
    RETURN
        IF(ISBLANK(__Value), "-", FORMAT(__Value, "#,##0"))
```

---

### 指标 6：M Polo Unfulfilled Order（O2O失败订单数 - M Polo）

> 数量类 · brand = "M Polo" · SUM(o2o_fulfillment_unshipped_order_cnt)

### 4.11 M Polo Unfulfilled Order Value

```dax
M Polo Unfulfilled Order Value =
// ========================================
// 度量值: M Polo Unfulfilled Order Value
// Display Folder: PB Merchandise
// 用途: O2O失败订单数（M Polo）by category_summary（条形图数值）
// 口径来源: PB Merchandise.md 子模块二 - M Polo Unfulfilled Order
// 计算公式: SUM(o2o_fulfillment_unshipped_order_cnt)
// 筛选条件:
//   - calc_type = "fulfillment"
//   - brand = "M Polo"
//   - data_date ∈ [__TimeMin, __TimeMax]（全局时间范围）
//   - 分组维度 category_summary 由条形图 Y 轴直接拉取事实表字段自动传递
// 数据类型: integer → 整数，千分位整数
// ========================================
    VAR __TimeMin = SELECTEDVALUE(Slicer_Time_Frame_Min[TimeFrame_Min])
    VAR __TimeMax = SELECTEDVALUE(Slicer_Time_Frame_Max[TimeFrame_Max])
    VAR __Result =
        CALCULATE(
            SUM('a02_e2e_boss_performance_summary_d'[o2o_fulfillment_unshipped_order_cnt]),
            'a02_e2e_boss_performance_summary_d'[calc_type] = "fulfillment",
            'a02_e2e_boss_performance_summary_d'[brand] = "M Polo",
            'a02_e2e_boss_performance_summary_d'[data_date] >= __TimeMin,
            'a02_e2e_boss_performance_summary_d'[data_date] <= __TimeMax
        )
    RETURN __Result
```

### 4.12 M Polo Unfulfilled Order Display

```dax
M Polo Unfulfilled Order Display =
// ========================================
// 度量值: M Polo Unfulfilled Order Display
// Display Folder: PB Merchandise
// 用途: O2O失败订单数（M Polo）格式化显示
// 依赖: [M Polo Unfulfilled Order Value]
// 格式类型: integer → #,##0
// ========================================
    VAR __Value = [M Polo Unfulfilled Order Value]
    RETURN
        IF(ISBLANK(__Value), "-", FORMAT(__Value, "#,##0"))
```

---

### 指标 7：W Polo Unfulfilled Order Share（W Polo O2O失败订单数占比）

> 比率类（派生）· W Polo Unfulfilled Order / Total Unfulfilled Order
> 分母均 REMOVEFILTERS(category)
### 4.13 W Polo Unfulfilled Order Share Value

```dax
W Polo Unfulfilled Order Share Value =
// ========================================
// 度量值: W Polo Unfulfilled Order Share Value
// Display Folder: PB Merchandise
// 用途: W Polo O2O失败订单数占比（条形图数值）
// 口径来源: PB Merchandise.md 子模块二 - W Polo Unfulfilled Order Share
// 计算公式: [W Polo Unfulfilled Order Value] / [Total Unfulfilled Order Value]
//   分子: W Polo Unfulfilled Order
//   分母: Total Unfulfilled Order（W Polo + M Polo，已 REMOVEFILTERS category）
// 派生类型: 占比类 → percent_1dp
// 数据类型: percent_1dp → 百分比，保留一位小数，不含正号
// ========================================
    VAR __Numerator = [W Polo Unfulfilled Order Value]
    VAR __Denominator = [Total Unfulfilled Order Value]
    RETURN DIVIDE(__Numerator, __Denominator)
```

### 4.14 W Polo Unfulfilled Order Share Display

```dax
W Polo Unfulfilled Order Share Display =
// ========================================
// 度量值: W Polo Unfulfilled Order Share Display
// Display Folder: PB Merchandise
// 用途: W Polo O2O失败订单数占比 格式化显示
// 依赖: [W Polo Unfulfilled Order Share Value]
// 格式类型: percent_1dp → #,##0.0%
// ========================================
    VAR __Value = [W Polo Unfulfilled Order Share Value]
    RETURN
        IF(ISBLANK(__Value), "-", FORMAT(__Value, "#,##0.0%"))
```

---

### 指标 8：M Polo Unfulfilled Order Share（M Polo O2O失败订单数占比）

> 比率类（派生）· M Polo Unfulfilled Order / Total Unfulfilled Order
> 分母已 REMOVEFILTERS(category)

### 4.15 M Polo Unfulfilled Order Share Value

```dax
M Polo Unfulfilled Order Share Value =
// ========================================
// 度量值: M Polo Unfulfilled Order Share Value
// Display Folder: PB Merchandise
// 用途: M Polo O2O失败订单数占比（条形图数值）
// 口径来源: PB Merchandise.md 子模块二 - M Polo Unfulfilled Order Share
// 计算公式: [M Polo Unfulfilled Order Value] / [Total Unfulfilled Order Value]
//   分子: M Polo Unfulfilled Order
//   分母: Total Unfulfilled Order（W Polo + M Polo，已 REMOVEFILTERS category）
// 派生类型: 占比类 → percent_1dp
// 数据类型: percent_1dp → 百分比，保留一位小数，不含正号
// ========================================
    VAR __Numerator = [M Polo Unfulfilled Order Value]
    VAR __Denominator = [Total Unfulfilled Order Value]
    RETURN DIVIDE(__Numerator, __Denominator)
```

### 4.16 M Polo Unfulfilled Order Share Display

```dax
M Polo Unfulfilled Order Share Display =
// ========================================
// 度量值: M Polo Unfulfilled Order Share Display
// Display Folder: PB Merchandise
// 用途: M Polo O2O失败订单数占比 格式化显示
// 依赖: [M Polo Unfulfilled Order Share Value]
// 格式类型: percent_1dp → #,##0.0%
// ========================================
    VAR __Value = [M Polo Unfulfilled Order Share Value]
    RETURN
        IF(ISBLANK(__Value), "-", FORMAT(__Value, "#,##0.0%"))
```

---

## 5. 度量值清单与 Display Folder

| 序号 | 度量值名称 | Display Folder | 子模块 | 指标 | 类型 | 格式 |
|------|-----------|----------------|--------|------|------|------|
| 1 | Fulfillment% by Label Value | PB Merchandise | 一 | Fulfillment% | Value | percent_1dp |
| 2 | Fulfillment% by Label Display | PB Merchandise | 一 | Fulfillment% | Display | percent_1dp |
| 3 | Request Order Qty by Label Value | PB Merchandise | 一 | Request Order Qty | Value | integer |
| 4 | Request Order Qty by Label Display | PB Merchandise | 一 | Request Order Qty | Display | integer |
| 5 | Shipped Order Qty by Label Value | PB Merchandise | 一 | Shipped Order Qty | Value | integer |
| 6 | Shipped Order Qty by Label Display | PB Merchandise | 一 | Shipped Order Qty | Display | integer |
| 7 | Total Unfulfilled Order Value | PB Merchandise | 二 | Total Unfulfilled Order | Value | integer |
| 8 | Total Unfulfilled Order Display | PB Merchandise | 二 | Total Unfulfilled Order | Display | integer |
| 9 | W Polo Unfulfilled Order Value | PB Merchandise | 二 | W Polo Unfulfilled Order | Value | integer |
| 10 | W Polo Unfulfilled Order Display | PB Merchandise | 二 | W Polo Unfulfilled Order | Display | integer |
| 11 | M Polo Unfulfilled Order Value | PB Merchandise | 二 | M Polo Unfulfilled Order | Value | integer |
| 12 | M Polo Unfulfilled Order Display | PB Merchandise | 二 | M Polo Unfulfilled Order | Display | integer |
| 13 | W Polo Unfulfilled Order Share Value | PB Merchandise | 二 | W Polo Unfulfilled Order Share | Value | percent_1dp |
| 14 | W Polo Unfulfilled Order Share Display | PB Merchandise | 二 | W Polo Unfulfilled Order Share | Display | percent_1dp |
| 15 | M Polo Unfulfilled Order Share Value | PB Merchandise | 二 | M Polo Unfulfilled Order Share | Value | percent_1dp |
| 16 | M Polo Unfulfilled Order Share Display | PB Merchandise | 二 | M Polo Unfulfilled Order Share | Display | percent_1dp |

---

## 6. 视觉对象配置

### 6.1 条形图（Bar Chart）— 子模块一

| 配置项 | 值 |
|--------|-----|
| Y 轴（分组） | a02_e2e_boss_performance_summary_d[brand]（直接拉取，天然筛选+分组） |
| X 轴（数值） | [Fulfillment% by Label Value] 或 [Fulfillment% by Label Display] |
| 排序 | 按 X 轴数值从高到低排序（口径文档要求） |
| 全局筛选器 | Slicer_Time_Frame_Min、Slicer_Time_Frame_Max |

> 子模块一三个指标共用同一 brand 分组，可做三个并列条形图或同一图表切换度量。

### 6.2 条形图（Bar Chart）— 子模块二

| 配置项 | 值 |
|--------|-----|
| Y 轴（分组） | a02_e2e_boss_performance_summary_d[category_summary]（直接拉取，天然筛选+分组） |
| X 轴（数值） | 按需拉取 Total / W Polo / M Polo Unfulfilled Order Value/Display，或 W/M Polo Share Value/Display |
| 排序 | 按 X 轴数值从高到低排序 |
| 全局筛选器 | Slicer_Time_Frame_Min、Slicer_Time_Frame_Max |

> brand 筛选已在度量值内部硬编码，视觉对象不需要再拉 brand 字段做筛选器。
> REMOVEFILTERS(category) 已在度量值内处理，category_summary 分组聚合值正确。

### 6.3 度量值拉取示例

| 场景 | 拉取度量 |
|------|---------|
| 子模块一 履约率条形图 | [Fulfillment% by Label Display] |
| 子模块一 分母订单量条形图 | [Request Order Qty by Label Display] |
| 子模块一 分子订单量条形图 | [Shipped Order Qty by Label Display] |
| 子模块二 总失败订单数 | [Total Unfulfilled Order Display] |
| 子模块二 W Polo 失败订单数 | [W Polo Unfulfilled Order Display] |
| 子模块二 M Polo 失败订单数 | [M Polo Unfulfilled Order Display] |
| 子模块二 W Polo 占比 | [W Polo Unfulfilled Order Share Display] |
| 子模块二 M Polo 占比 | [M Polo Unfulfilled Order Share Display] |

---

## 7. 验证方法

### 7.1 验证 SQL（子模块一）

```sql
-- 子模块一 Fulfillment% by Label（按 brand 分组）
-- 假设 __TimeMin='2025-06-29', __TimeMax='2025-08-09'
SELECT
    brand,
    SUM(o2o_fulfillment_shipped_order_cnt) AS Shipped_Order_Qty,
    SUM(o2o_fulfillment_request_order_cnt) AS Request_Order_Qty,
    SUM(o2o_fulfillment_shipped_order_cnt) * 1.0 / SUM(o2o_fulfillment_request_order_cnt) AS Fulfillment_Pct
FROM a02_e2e_boss_performance_summary_d
WHERE calc_type = 'fulfillment'
  AND data_date BETWEEN '2025-06-29' AND '2025-08-09'
GROUP BY brand
ORDER BY Fulfillment_Pct DESC;
```

### 7.2 验证 SQL（子模块二）

```sql
-- 子模块二 Total Unfulfilled Order by category_summary（W Polo + M Polo）
-- REMOVEFILTERS(category) 等价于 SQL 中不按 category 分组
SELECT
    category_summary,
    SUM(o2o_fulfillment_unshipped_order_cnt) AS Total_Unfulfilled_Order
FROM a02_e2e_boss_performance_summary_d
WHERE calc_type = 'fulfillment'
  AND brand IN ('W Polo', 'M Polo')
  AND data_date BETWEEN '2025-06-29' AND '2025-08-09'
GROUP BY category_summary
ORDER BY Total_Unfulfilled_Order DESC;

-- 子模块二 W Polo Unfulfilled Order by category_summary
SELECT
    category_summary,
    SUM(o2o_fulfillment_unshipped_order_cnt) AS W_Polo_Unfulfilled_Order
FROM a02_e2e_boss_performance_summary_d
WHERE calc_type = 'fulfillment'
  AND brand = 'W Polo'
  AND data_date BETWEEN '2025-06-29' AND '2025-08-09'
GROUP BY category_summary
ORDER BY W_Polo_Unfulfilled_Order DESC;

-- 子模块二 M Polo Unfulfilled Order by category_summary
SELECT
    category_summary,
    SUM(o2o_fulfillment_unshipped_order_cnt) AS M_Polo_Unfulfilled_Order
FROM a02_e2e_boss_performance_summary_d
WHERE calc_type = 'fulfillment'
  AND brand = 'M Polo'
  AND data_date BETWEEN '2025-06-29' AND '2025-08-09'
GROUP BY category_summary
ORDER BY M_Polo_Unfulfilled_Order DESC;

-- 子模块二 W Polo / M Polo Share（按 category_summary 分组）
-- W Polo Share = W Polo Unfulfilled / Total Unfulfilled
-- M Polo Share = M Polo Unfulfilled / Total Unfulfilled
-- 可在 PBI 中用 [W Polo Unfulfilled Order Value] / [Total Unfulfilled Order Value] 直接验证
```

---

## 8. 注意事项

1. **calc_type 固定**：子模块一、二所有度量值均硬编码 `calc_type = "fulfillment"`，与口径文档一致。

2. **brand 取值**：子模块二 brand 取值以子模块二具体指标定义为准 — `brand in ("W Polo", "M Polo")`（口径文档通用规则汇总中出现的 "1. W Polo"、"2. M Polo" 为旧版前缀命名，本方案不采用）。若实际底表 brand 字段为 "1. W Polo"、"2. M Polo" 等带前缀格式，需调整度量值中的硬编码值。

3. **REMOVEFILTERS(category)**：子模块二三个数量类指标（Total / W Polo / M Polo Unfulfilled Order Value）均显式 `REMOVEFILTERS('a02_e2e_boss_performance_summary_d'[category])`，确保按 category_summary 分组时汇总值不被 category 筛选影响。占比类指标分子分母均已 REMOVEFILTERS，相除自动抵消，无需重复。

4. **分组维度传递**：brand（子模块一）、category_summary（子模块二）由条形图 Y 轴直接拉取事实表字段，DAX 度量值无需显式处理分组逻辑，模型自动传递筛选。度量值内部不依赖分组字段。

5. **无 X 轴时间维度**：本方案仅用全局时间范围筛选（Slicer_Time_Frame_Min / Slicer_Time_Frame_Max），不涉及 Slicer_Time_Frame（X 轴时间段）、Dim_RowKPIs / Dim_ColKPIs（矩阵行列维度）等依赖。

6. **比率类不除汇率**：Fulfillment%、W/M Polo Share 为比率类指标，分子分母同币种/同数量类相除自动抵消，不除 Currency_ExchangeRate；子模块一/二均为数量/比率类，不涉及金额，不需要 Slicer_Currency_Selection。

7. **条形图排序**：子模块一口径要求"按 brand 分组从高到低排序"，子模块二按 category_summary 分组，排序方向在视觉对象 X 轴设置中配置（按度量值降序），不在 DAX 中处理。

8. **Display 命名约定**：遵循 PB_Location_Sales_detail.md 风格，每个指标出 Value + Display 一对，便于条形图按需拉取 Value（用于排序/数据条）或 Display（用于带格式文本）。
