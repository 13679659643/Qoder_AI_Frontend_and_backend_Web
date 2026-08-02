# Power BI 解决方案 — Overview_Fulfillment：Fulfillment% / Order Processing Efficiency / Penalty（条形图 / 堆积柱形图）

> status: ready
> created: 2026-08-02
> type: 度量值开发 + 可视化构建
> 口径来源: 口径文档/Overview.md 子模块五 Fulfillment% by Label、子模块六 Order Processing Efficiency by Label、子模块七 Penalty by Platform
> 参考实现: Overview/Sales/Overview_Sales_DemandSLS_SLSPenetration_solution.md（Value/Display 范式）

---

## 1. 需求理解

为 Overview → Fulfillment 分组下的三个子模块提供独立度量值（Value + Display），每个指标均独立编写，不使用 SWITCH 路由分发。所有度量仅计算当期值，不涉及 LY（去年同期）。

### 1.1 子模块五：Fulfillment% by Label（条形图）

| 序号 | 度量值               | 用途       | 数据底表                            | 分组字段                                | 格式类型    |
| ---- | -------------------- | ---------- | ----------------------------------- | --------------------------------------- | ----------- |
| 1    | Fulfillment% Value   | 条形图值   | a02_e2e_boss_performance_summary_d  | `a02_e2e_boss_performance_summary_d'[brand]` | percent_1dp |
| 2    | Fulfillment% Display | 条形图标签 | 同上                                | 同上                                    | percent_1dp |

### 1.2 子模块六：Order Processing Efficiency by Label（条形图）

| 序号 | 度量值                     | 用途       | 数据底表                                 | 分组字段                                       | 格式类型   |
| ---- | -------------------------- | ---------- | ---------------------------------------- | --------------------------------------------- | ---------- |
| 1    | Avg Store Passed Value     | 条形图值   | a02_e2e_boss_fulfillment_request_data_d  | `a02_e2e_boss_fulfillment_request_data_d'[brand]` | decimal_1dp |
| 2    | Avg Store Passed Display   | 条形图标签 | 同上                                     | 同上                                          | decimal_1dp |
| 3    | Avg Processing Time Value  | 条形图值   | 同上                                     | 同上                                          | decimal_1dp |
| 4    | Avg Processing Time Display| 条形图标签 | 同上                                     | 同上                                          | decimal_1dp |

### 1.3 子模块七：Penalty by Platform（堆积柱形图）

| 序号 | 度量值                              | 用途             | 数据底表                            | 分组字段                       | 格式类型    |
| ---- | ----------------------------------- | ---------------- | ----------------------------------- | ------------------------------ | ----------- |
| 1    | Penalty Amt Value                   | 柱形图堆积值     | a02_e2e_boss_performance_summary_d  | Slicer_Store_Name[Store_ID]    | currency    |
| 2    | Penalty Amt Display                 | 数据标签         | 同上                                | 同上                           | currency    |
| 3    | OOS Penalty Amt Value               | 柱形图堆积值     | 同上                                | 同上                           | currency    |
| 4    | OOS Penalty Amt Display             | 数据标签         | 同上                                | 同上                           | currency    |
| 5    | Delay Penalty Amt Value             | 柱形图堆积值     | 同上                                | 同上                           | currency    |
| 6    | Delay Penalty Amt Display           | 数据标签         | 同上                                | 同上                           | currency    |
| 7    | OOS Penalty Amt Share Value         | 数据标签/工具提示| 同上                                | 同上                           | percent_1dp |
| 8    | OOS Penalty Amt Share Display       | 数据标签         | 同上                                | 同上                           | percent_1dp |
| 9    | Delay Penalty Amt Share Value       | 数据标签/工具提示| 同上                                | 同上                           | percent_1dp |
| 10   | Delay Penalty Amt Share Display     | 数据标签         | 同上                                | 同上                           | percent_1dp |
| 11   | Penalty Order Value                 | 柱形图堆积值     | 同上                                | 同上                           | integer     |
| 12   | Penalty Order Display               | 数据标签         | 同上                                | 同上                           | integer     |
| 13   | OOS Penalty Order Value             | 柱形图堆积值     | 同上                                | 同上                           | integer     |
| 14   | OOS Penalty Order Display           | 数据标签         | 同上                                | 同上                           | integer     |
| 15   | Delay Penalty Order Value           | 柱形图堆积值     | 同上                                | 同上                           | integer     |
| 16   | Delay Penalty Order Display         | 数据标签         | 同上                                | 同上                           | integer     |
| 17   | OOS Penalty Order Share Value       | 数据标签/工具提示| 同上                                | 同上                           | percent_1dp |
| 18   | OOS Penalty Order Share Display     | 数据标签         | 同上                                | 同上                           | percent_1dp |
| 19   | Delay Penalty Order Share Value     | 数据标签/工具提示| 同上                                | 同上                           | percent_1dp |
| 20   | Delay Penalty Order Share Display   | 数据标签         | 同上                                | 同上                           | percent_1dp |

**关键说明**：
- 子模块五/六/七**不涉及上期值（LY）**，仅计算当期值。
- 子模块五/六为条形图，**按 `brand` 分组**，brand 字段位于事实表本身（图表天然自带 brand 分组属性）。
- 子模块七为堆积柱形图，**按 `Slicer_Store_Name[Store_ID]` 分组**（横轴），OOS/Delay 通过两个独立度量值堆叠实现。
- 时间筛选：三个子模块均仅使用全局时间范围（Slicer_Time_Frame_Min/Max），**无 X 轴时间段筛选**（分组字段非 timeframe）。
- 汇率换算：金额类指标 ÷ `Currency_ExchangeRate`；比率类和整数类指标不除汇率（分子分母同币种相除自动抵消 / 整数本身无币种属性）。

---

## 2. 现状分析

### 2.1 数据底表

| 对象     | 名称                                   | 关键字段                                                                                                                                                                                              |
| -------- | -------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 事实表 1 | a02_e2e_boss_performance_summary_d     | data_date, store_name, brand, calc_type, o2o_fulfillment_shipped_order_cnt, o2o_fulfillment_request_order_cnt, o2o_penalty_oos_amt, o2o_penalty_delay_amt, o2o_penalty_oos_order_cnt, o2o_penalty_delay_order_cnt |
| 事实表 2 | a02_e2e_boss_fulfillment_request_data_d| data_date, brand, calc_type, o2o_fulfillment_request_times, o2o_fulfillment_request_sku_qty, o2o_fulfillment_request_duration                                                                                       |

### 2.2 维度表清单

| 维度表                    | 类型     | 连接方式                                                                                       |
| ------------------------- | -------- | ---------------------------------------------------------------------------------------------- |
| Slicer_Time_Frame_Min     | 断开维度 | 起始切片器；SELECTEDVALUE 读取 TimeFrame_Min                                                    |
| Slicer_Time_Frame_Max     | 断开维度 | 结束切片器；SELECTEDVALUE 读取 TimeFrame_Max                                                    |
| Slicer_Currency_Selection | 断开维度 | SELECTEDVALUE 读取 Currency_ExchangeRate, Currency_Symbol                                       |
| Slicer_Store_Name         | 维度表   | 1:N 关联事实表 `a02_e2e_boss_performance_summary_d[store_name]`；横轴使用 `Store_ID` 字段       |

### 2.3 分组字段映射

| 子模块 | 分组字段                      | 字段位置                                          | 关系类型        |
| ------ | ----------------------------- | ------------------------------------------------- | --------------- |
| 五     | `brand`                       | 事实表 `a02_e2e_boss_performance_summary_d[brand]`| 直接使用事实表字段，无关系依赖 |
| 六     | `brand`                       | 事实表 `a02_e2e_boss_fulfillment_request_data_d[brand]`| 直接使用事实表字段，无关系依赖 |
| 七     | `Slicer_Store_Name[Store_ID]` | 维度表主键                                        | 1:N → 事实表[store_name] |

> 子模块七关键说明：`Slicer_Store_Name[Store_ID]` 与 `a02_e2e_boss_performance_summary_d[store_name]` 建立 1:N 关系。横轴使用 `Slicer_Store_Name[Store_ID]`，模型天然自带筛选效果，将筛选传递到事实表。

---

## 3. 方案设计

### 3.1 整体架构

```
子模块五：Fulfillment% by Label（条形图）             子模块六：Order Processing Efficiency by Label（条形图）
    │                                                          │
    │  Y 轴 = 事实表[brand]                                     │  Y 轴 = 事实表[brand]
    │  X 轴 = [Fulfillment% Value]                              │  X 轴 = [Avg Store Passed Value] / [Avg Processing Time Value]
    │  标签 = [Fulfillment% Display]                            │  标签 = [* Display]
    │  全局筛选: Slicer_Time_Frame_Min/Max                      │  全局筛选: Slicer_Time_Frame_Min/Max
    ▼                                                          ▼
    ┌─────────────────────────┐         ┌─────────────────────────────────────────────┐
    │ Fulfillment% Value       │         │ Avg Store Passed Value                       │
    │  CALCULATE(              │         │  CALCULATE(                                  │
    │    DIVIDE(               │         │    SUM(o2o_fulfillment_request_times),       │
    │      SUM(shipped_cnt),   │         │    calc_type="fulfillment",                  │
    │      SUM(request_cnt)    │         │    data_date ∈ 全局范围                      │
    │    ),                    │         │  ) / SUM(... request_sku_qty)                │
    │    calc_type="fulfillment",│       │                                              │
    │    data_date ∈ 全局范围  │         │ Avg Processing Time Value                    │
    │  )                       │         │  CALCULATE(SUM(request_duration), ...)       │
    │  brand 由图例传递        │         │  / SUM(... request_sku_qty)                  │
    └─────────────────────────┘         │  brand 由 Y 轴传递                           │
                                        └─────────────────────────────────────────────┘

子模块七：Penalty by Platform（堆积柱形图）
    │
    │  X 轴 = Slicer_Store_Name[Store_ID]
    │  Y 轴（堆积）= [OOS Penalty Amt Value] + [Delay Penalty Amt Value]  （或 Order 版本）
    │  数据标签 = [* Display]
    │  全局筛选: Slicer_Time_Frame_Min/Max, Slicer_Currency_Selection
    ▼
    ┌─────────────────────────────────────────────────────────────┐
    │ OOS Penalty Amt Value                                       │
    │  CALCULATE(                                                 │
    │    SUM(o2o_penalty_oos_amt),                                │
    │    calc_type="fulfillment",                                 │
    │    data_date ∈ 全局范围                                     │
    │  ) / __FXRate                                               │
    │                                                             │
    │ Delay Penalty Amt Value  （结构同上，字段换 delay_amt）      │
    │ Penalty Amt Value        （= OOS + Delay，独立聚合避免双计） │
    │                                                             │
    │ Share 类: OOS / (OOS + Delay)                               │
    │ Store_ID 由 X 轴传递筛选（1:N 关系自动传递）                │
    └─────────────────────────────────────────────────────────────┘
```

### 3.2 筛选器上下文

| 筛选器                   | 子模块五（Fulfillment%）   | 子模块六（Avg 系列）        | 子模块七（Penalty 系列）    |
| ------------------------ | -------------------------- | --------------------------- | --------------------------- |
| Slicer_Time_Frame_Min    | `data_date >= __TimeMin`   | `data_date >= __TimeMin`    | `data_date >= __TimeMin`    |
| Slicer_Time_Frame_Max    | `data_date <= __TimeMax`   | `data_date <= __TimeMax`    | `data_date <= __TimeMax`    |
| 事实表[brand]            | 条形图 Y 轴自动传递筛选    | 条形图 Y 轴自动传递筛选     | 不筛选                      |
| Slicer_Store_Name[Store_ID] | 不适用                  | 不适用                      | 堆积柱形图 X 轴自动传递筛选 |
| calc_type                | = "fulfillment"            | = "fulfillment"             | = "fulfillment"             |
| Slicer_Currency_Selection| 比率类不除汇率             | 比率类不除汇率              | 金额类 ÷ __FXRate；整数类、比率类不除 |

### 3.3 汇率换算规则

| 指标类型 | 是否除汇率 | 原因 |
| -------- | ---------- | ---- |
| 金额类（Penalty Amt / OOS Penalty Amt / Delay Penalty Amt） | 是，÷ __FXRate | 数据源默认 RMB，需按币种切片器换算 |
| 整数类（Penalty Order / OOS Penalty Order / Delay Penalty Order） | 否 | 订单数为计数，无币种属性 |
| 比率类（Fulfillment% / Share 类 / Avg 系列） | 否 | 分子分母同币种相除自动抵消，比值不受汇率影响 |

### 3.4 格式规范

| 格式类型     | 格式串                          | 示例            | 适用度量                                            |
| ------------ | ------------------------------- | --------------- | --------------------------------------------------- |
| percent_1dp  | `#,##0.0%;-#,##0.0%;0.0%`       | 85.3% / -2.5%   | Fulfillment%, Share 类                              |
| decimal_1dp  | `#,##0.0;-#,##0.0;0.0`          | 1.5 / -0.3      | Avg Store Passed, Avg Processing Time               |
| currency     | `__CurrencySymbol & FORMAT("#,##0")` | ¥1,234 / $5,678 | Penalty Amt, OOS/Delay Penalty Amt                  |
| integer      | `#,##0`                         | 1,234           | Penalty Order, OOS/Delay Penalty Order              |

---

## 4. 度量值实现

### 4.1 子模块五：Fulfillment% by label Value（条形图 — 按 brand 分组）

```dax
Fulfillment% by label Value = 
// ========================================
// 度量值: Fulfillment% by label Value
// Display Folder: Fulfillment
// 用途: Fulfillment%（O2O订单履约率）值，用于条形图（按 brand 分组）
// 口径来源: Overview.md 子模块五 Fulfillment% by Label - Fulfillment%
// 计算公式: SUM(o2o_fulfillment_shipped_order_cnt) / SUM(o2o_fulfillment_request_order_cnt)
//   分子: o2o_fulfillment_shipped_order_cnt（实际发货订单数）
//   分母: o2o_fulfillment_request_order_cnt（客户请求门店的总订单数）
// 筛选条件:
//   - calc_type = "fulfillment"
//   - data_date ∈ [__TimeMin, __TimeMax]（全局时间范围）
//   - brand 由条形图 Y 轴（事实表[brand]）自动传递筛选，无需显式处理
//   - 比率类，不除汇率（分子分母同币种相除自动抵消）
// 数据类型: percent_1dp → 百分比，保留一位小数，不含正号
// ========================================
    VAR __TimeMin = SELECTEDVALUE(Slicer_Time_Frame_Min[TimeFrame_Min])
    VAR __TimeMax = SELECTEDVALUE(Slicer_Time_Frame_Max[TimeFrame_Max])
    VAR __Numerator =
        CALCULATE(
            SUM('a02_e2e_boss_performance_summary_d'[o2o_fulfillment_shipped_order_cnt]),
            'a02_e2e_boss_performance_summary_d'[calc_type] = "fulfillment",
            'a02_e2e_boss_performance_summary_d'[data_date] >= __TimeMin,
            'a02_e2e_boss_performance_summary_d'[data_date] <= __TimeMax
        )
    VAR __Denominator =
        CALCULATE(
            SUM('a02_e2e_boss_performance_summary_d'[o2o_fulfillment_request_order_cnt]),
            'a02_e2e_boss_performance_summary_d'[calc_type] = "fulfillment",
            'a02_e2e_boss_performance_summary_d'[data_date] >= __TimeMin,
            'a02_e2e_boss_performance_summary_d'[data_date] <= __TimeMax
        )
    RETURN DIVIDE(__Numerator, __Denominator)
```

### 4.2 子模块五：Fulfillment% by label Display

```dax
Fulfillment% by label Display = 
// ========================================
// 度量值: Fulfillment% by label Display
// Display Folder: Fulfillment
// 用途: Fulfillment% 格式化显示（百分比，保留一位小数，不含正号）
// 依赖: [Fulfillment% by label Value]
// 格式类型: percent_1dp
// 格式串: #,##0.0%;-#,##0.0%;0.0%
// ========================================
    VAR __Value = [Fulfillment% by label Value]
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            FORMAT(__Value, "#,##0.0%;-#,##0.0%;0.0%")
        )
```

### 4.3 子模块六：Avg Store Passed Value（条形图 — 按 brand 分组）

```dax
Avg Store Passed Value = 
// ========================================
// 度量值: Avg Store Passed Value
// Display Folder: Fulfillment
// 用途: Avg. No. of Store Passed Before Order Got Accepted（O2O平均订单流转次数）值
//       用于条形图（按 brand 分组）
// 口径来源: Overview.md 子模块六 Order Processing Efficiency by Label - Avg. No. of Store Passed
// 计算公式: SUM(o2o_fulfillment_request_times) / SUM(o2o_fulfillment_request_sku_qty)
//   分子: o2o_fulfillment_request_times（订单在系统中出现的次数）
//   分母: o2o_fulfillment_request_sku_qty（订单商品数）
// 筛选条件:
//   - calc_type = "fulfillment"
//   - data_date ∈ [__TimeMin, __TimeMax]（全局时间范围）
//   - brand 由条形图 Y 轴（事实表[brand]）自动传递筛选，无需显式处理
//   - 比率类，不除汇率（分子分母同币种相除自动抵消）
// 数据类型: decimal_1dp → 小数，保留一位小数，千分位
// 业务说明: 换货订单已在数据源层剔除，度量值无需额外筛选
// ========================================
    VAR __TimeMin = SELECTEDVALUE(Slicer_Time_Frame_Min[TimeFrame_Min])
    VAR __TimeMax = SELECTEDVALUE(Slicer_Time_Frame_Max[TimeFrame_Max])
    VAR __Numerator =
        CALCULATE(
            SUM('a02_e2e_boss_fulfillment_request_data_d'[o2o_fulfillment_request_times]),
            'a02_e2e_boss_fulfillment_request_data_d'[calc_type] = "fulfillment",
            'a02_e2e_boss_fulfillment_request_data_d'[data_date] >= __TimeMin,
            'a02_e2e_boss_fulfillment_request_data_d'[data_date] <= __TimeMax
        )
    VAR __Denominator =
        CALCULATE(
            SUM('a02_e2e_boss_fulfillment_request_data_d'[o2o_fulfillment_request_sku_qty]),
            'a02_e2e_boss_fulfillment_request_data_d'[calc_type] = "fulfillment",
            'a02_e2e_boss_fulfillment_request_data_d'[data_date] >= __TimeMin,
            'a02_e2e_boss_fulfillment_request_data_d'[data_date] <= __TimeMax
        )
    RETURN DIVIDE(__Numerator, __Denominator)
```

### 4.4 子模块六：Avg Store Passed Display

```dax
Avg Store Passed Display = 
// ========================================
// 度量值: Avg Store Passed Display
// Display Folder: Fulfillment
// 用途: Avg. No. of Store Passed 格式化显示（小数，保留一位小数，千分位）
// 依赖: [Avg Store Passed Value]
// 格式类型: decimal_1dp
// 格式串: #,##0.0;-#,##0.0;0.0
// ========================================
    VAR __Value = [Avg Store Passed Value]
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            FORMAT(__Value, "#,##0.0;-#,##0.0;0.0")
        )
```

### 4.5 子模块六：Avg Processing Time Value（条形图 — 按 brand 分组）

```dax
Avg Processing Time Value = 
// ========================================
// 度量值: Avg Processing Time Value
// Display Folder: Fulfillment
// 用途: Avg. Processing Time（O2O平均订单流转时长）值，用于条形图（按 brand 分组）
// 口径来源: Overview.md 子模块六 Order Processing Efficiency by Label - Avg. Processing Time
// 计算公式: SUM(o2o_fulfillment_request_duration) / SUM(o2o_fulfillment_request_sku_qty)
//   分子: o2o_fulfillment_request_duration（订单流转时长）
//   分母: o2o_fulfillment_request_sku_qty（订单商品数）
// 筛选条件:
//   - calc_type = "fulfillment"
//   - data_date ∈ [__TimeMin, __TimeMax]（全局时间范围）
//   - brand 由条形图 Y 轴（事实表[brand]）自动传递筛选，无需显式处理
//   - 比率类，不除汇率（分子分母同币种相除自动抵消）
// 数据类型: decimal_1dp → 小数，保留一位小数，千分位
// 业务说明: 换货订单已在数据源层剔除，度量值无需额外筛选
// ========================================
    VAR __TimeMin = SELECTEDVALUE(Slicer_Time_Frame_Min[TimeFrame_Min])
    VAR __TimeMax = SELECTEDVALUE(Slicer_Time_Frame_Max[TimeFrame_Max])
    VAR __Numerator =
        CALCULATE(
            SUM('a02_e2e_boss_fulfillment_request_data_d'[o2o_fulfillment_request_duration]),
            'a02_e2e_boss_fulfillment_request_data_d'[calc_type] = "fulfillment",
            'a02_e2e_boss_fulfillment_request_data_d'[data_date] >= __TimeMin,
            'a02_e2e_boss_fulfillment_request_data_d'[data_date] <= __TimeMax
        )
    VAR __Denominator =
        CALCULATE(
            SUM('a02_e2e_boss_fulfillment_request_data_d'[o2o_fulfillment_request_sku_qty]),
            'a02_e2e_boss_fulfillment_request_data_d'[calc_type] = "fulfillment",
            'a02_e2e_boss_fulfillment_request_data_d'[data_date] >= __TimeMin,
            'a02_e2e_boss_fulfillment_request_data_d'[data_date] <= __TimeMax
        )
    RETURN DIVIDE(__Numerator, __Denominator)
```

### 4.6 子模块六：Avg Processing Time Display

```dax
Avg Processing Time Display = 
// ========================================
// 度量值: Avg Processing Time Display
// Display Folder: Fulfillment
// 用途: Avg. Processing Time 格式化显示（小数，保留一位小数，千分位）
// 依赖: [Avg Processing Time Value]
// 格式类型: decimal_1dp
// 格式串: #,##0.0;-#,##0.0;0.0
// ========================================
    VAR __Value = [Avg Processing Time Value]
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            FORMAT(__Value, "#,##0.0;-#,##0.0;0.0")
        )
```

### 4.7 子模块七：Penalty Amt Value（堆积柱形图 — 按 Store_ID 分组）

```dax
Penalty Amt Value = 
// ========================================
// 度量值: Penalty Amt Value
// Display Folder: Fulfillment
// 用途: Penalty Amt（O2O赔付金额 总额）值，用于堆积柱形图（按 Store_ID 分组）
// 口径来源: Overview.md 子模块七 Penalty by Platform - Penalty Amt
// 计算公式: SUM(o2o_penalty_oos_amt) + SUM(o2o_penalty_delay_amt)
//   说明: 一个柱子的总赔付金额 = OOS赔付金额 + Delay赔付金额
//         独立聚合 OOS 和 Delay 再相加，避免在堆积柱形图中双计
//         （堆积柱形图的 Y 轴应放 OOS Penalty Amt Value 和 Delay Penalty Amt Value 两个度量堆叠，
//          Penalty Amt Value 用于工具提示或总标签展示）
// 筛选条件:
//   - calc_type = "fulfillment"
//   - data_date ∈ [__TimeMin, __TimeMax]（全局时间范围）
//   - Store_ID 由堆积柱形图 X 轴（Slicer_Store_Name[Store_ID]）通过 1:N 关系自动传递筛选
//   - 金额类指标 ÷ __FXRate（汇率换算）
// 数据类型: currency → 货币符号由币种切片器决定，千分位整数
// ========================================
    VAR __TimeMin = SELECTEDVALUE(Slicer_Time_Frame_Min[TimeFrame_Min])
    VAR __TimeMax = SELECTEDVALUE(Slicer_Time_Frame_Max[TimeFrame_Max])
    VAR __FXRate = SELECTEDVALUE(Slicer_Currency_Selection[Currency_ExchangeRate], 1)
    VAR __OOSAmt =
        CALCULATE(
            SUM('a02_e2e_boss_performance_summary_d'[o2o_penalty_oos_amt]),
            'a02_e2e_boss_performance_summary_d'[calc_type] = "fulfillment",
            'a02_e2e_boss_performance_summary_d'[data_date] >= __TimeMin,
            'a02_e2e_boss_performance_summary_d'[data_date] <= __TimeMax
        )
    VAR __DelayAmt =
        CALCULATE(
            SUM('a02_e2e_boss_performance_summary_d'[o2o_penalty_delay_amt]),
            'a02_e2e_boss_performance_summary_d'[calc_type] = "fulfillment",
            'a02_e2e_boss_performance_summary_d'[data_date] >= __TimeMin,
            'a02_e2e_boss_performance_summary_d'[data_date] <= __TimeMax
        )
    VAR __PenaltyAmt = __OOSAmt + __DelayAmt
    RETURN DIVIDE(__PenaltyAmt, __FXRate)
```

### 4.8 子模块七：Penalty Amt Display

```dax
Penalty Amt Display = 
// ========================================
// 度量值: Penalty Amt Display
// Display Folder: Fulfillment
// 用途: Penalty Amt 格式化显示（货币符号 + 千分位整数）
// 依赖: [Penalty Amt Value], Slicer_Currency_Selection
// 格式类型: currency
// 格式串: __CurrencySymbol & FORMAT(__Value, "#,##0")
// ========================================
    VAR __Value = [Penalty Amt Value]
    VAR __CurrencySymbol = SELECTEDVALUE(Slicer_Currency_Selection[Currency_Symbol], "¥")
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            __CurrencySymbol & FORMAT(__Value, "#,##0")
        )
```

### 4.9 子模块七：OOS Penalty Amt Value

```dax
OOS Penalty Amt Value = 
// ========================================
// 度量值: OOS Penalty Amt Value
// Display Folder: Fulfillment
// 用途: OOS Penalty Amt（OOS赔付金额）值，用于堆积柱形图（按 Store_ID 分组）
// 口径来源: Overview.md 子模块七 Penalty by Platform - OOS Penalty Amt
// 计算公式: SUM(o2o_penalty_oos_amt)
// 筛选条件: 同 Penalty Amt Value
// 数据类型: currency → 货币符号由币种切片器决定，千分位整数
// 用途说明: 作为堆积柱形图 Y 轴的一个堆积系列（与 Delay Penalty Amt Value 堆叠）
// ========================================
    VAR __TimeMin = SELECTEDVALUE(Slicer_Time_Frame_Min[TimeFrame_Min])
    VAR __TimeMax = SELECTEDVALUE(Slicer_Time_Frame_Max[TimeFrame_Max])
    VAR __FXRate = SELECTEDVALUE(Slicer_Currency_Selection[Currency_ExchangeRate], 1)
    VAR __OOSAmt =
        CALCULATE(
            SUM('a02_e2e_boss_performance_summary_d'[o2o_penalty_oos_amt]),
            'a02_e2e_boss_performance_summary_d'[calc_type] = "fulfillment",
            'a02_e2e_boss_performance_summary_d'[data_date] >= __TimeMin,
            'a02_e2e_boss_performance_summary_d'[data_date] <= __TimeMax
        )
    RETURN DIVIDE(__OOSAmt, __FXRate)
```

### 4.10 子模块七：OOS Penalty Amt Display

```dax
OOS Penalty Amt Display = 
// ========================================
// 度量值: OOS Penalty Amt Display
// Display Folder: Fulfillment
// 用途: OOS Penalty Amt 格式化显示（货币符号 + 千分位整数）
// 依赖: [OOS Penalty Amt Value], Slicer_Currency_Selection
// 格式类型: currency
// ========================================
    VAR __Value = [OOS Penalty Amt Value]
    VAR __CurrencySymbol = SELECTEDVALUE(Slicer_Currency_Selection[Currency_Symbol], "¥")
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            __CurrencySymbol & FORMAT(__Value, "#,##0")
        )
```

### 4.11 子模块七：Delay Penalty Amt Value

```dax
Delay Penalty Amt Value = 
// ========================================
// 度量值: Delay Penalty Amt Value
// Display Folder: Fulfillment
// 用途: Delay Penalty Amt（Delay赔付金额）值，用于堆积柱形图（按 Store_ID 分组）
// 口径来源: Overview.md 子模块七 Penalty by Platform - Delay Penalty Amt
// 计算公式: SUM(o2o_penalty_delay_amt)
// 筛选条件: 同 Penalty Amt Value
// 数据类型: currency → 货币符号由币种切片器决定，千分位整数
// 用途说明: 作为堆积柱形图 Y 轴的一个堆积系列（与 OOS Penalty Amt Value 堆叠）
// ========================================
    VAR __TimeMin = SELECTEDVALUE(Slicer_Time_Frame_Min[TimeFrame_Min])
    VAR __TimeMax = SELECTEDVALUE(Slicer_Time_Frame_Max[TimeFrame_Max])
    VAR __FXRate = SELECTEDVALUE(Slicer_Currency_Selection[Currency_ExchangeRate], 1)
    VAR __DelayAmt =
        CALCULATE(
            SUM('a02_e2e_boss_performance_summary_d'[o2o_penalty_delay_amt]),
            'a02_e2e_boss_performance_summary_d'[calc_type] = "fulfillment",
            'a02_e2e_boss_performance_summary_d'[data_date] >= __TimeMin,
            'a02_e2e_boss_performance_summary_d'[data_date] <= __TimeMax
        )
    RETURN DIVIDE(__DelayAmt, __FXRate)
```

### 4.12 子模块七：Delay Penalty Amt Display

```dax
Delay Penalty Amt Display = 
// ========================================
// 度量值: Delay Penalty Amt Display
// Display Folder: Fulfillment
// 用途: Delay Penalty Amt 格式化显示（货币符号 + 千分位整数）
// 依赖: [Delay Penalty Amt Value], Slicer_Currency_Selection
// 格式类型: currency
// ========================================
    VAR __Value = [Delay Penalty Amt Value]
    VAR __CurrencySymbol = SELECTEDVALUE(Slicer_Currency_Selection[Currency_Symbol], "¥")
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            __CurrencySymbol & FORMAT(__Value, "#,##0")
        )
```

### 4.13 子模块七：OOS Penalty Amt Share Value

```dax
OOS Penalty Amt Share Value = 
// ========================================
// 度量值: OOS Penalty Amt Share Value
// Display Folder: Fulfillment
// 用途: OOS Penalty Amt Share（OOS赔付金额占比）值，用于数据标签或工具提示
// 口径来源: Overview.md 子模块七 Penalty by Platform - OOS Penalty Amt Share
// 计算公式: SUM(o2o_penalty_oos_amt) / (SUM(o2o_penalty_oos_amt) + SUM(o2o_penalty_delay_amt))
//   分子: o2o_penalty_oos_amt（当前 Store_ID 的 OOS 赔付金额，原始 RMB 值）
//   分母: o2o_penalty_oos_amt + o2o_penalty_delay_amt（当前 Store_ID 的总赔付金额，原始 RMB 值）
// 筛选条件: 同 Penalty Amt Value
// 数据类型: percent_1dp → 百分比，保留一位小数，不含正号
// 关键说明:
//   - 比率类指标，分子分母同币种相除自动抵消，不受汇率影响
//   - 分子分母均使用原始 RMB 值聚合后再相除，不除 __FXRate
//   - Store_ID 由 X 轴自动传递筛选
// ========================================
    VAR __TimeMin = SELECTEDVALUE(Slicer_Time_Frame_Min[TimeFrame_Min])
    VAR __TimeMax = SELECTEDVALUE(Slicer_Time_Frame_Max[TimeFrame_Max])
    VAR __OOSAmt =
        CALCULATE(
            SUM('a02_e2e_boss_performance_summary_d'[o2o_penalty_oos_amt]),
            'a02_e2e_boss_performance_summary_d'[calc_type] = "fulfillment",
            'a02_e2e_boss_performance_summary_d'[data_date] >= __TimeMin,
            'a02_e2e_boss_performance_summary_d'[data_date] <= __TimeMax
        )
    VAR __DelayAmt =
        CALCULATE(
            SUM('a02_e2e_boss_performance_summary_d'[o2o_penalty_delay_amt]),
            'a02_e2e_boss_performance_summary_d'[calc_type] = "fulfillment",
            'a02_e2e_boss_performance_summary_d'[data_date] >= __TimeMin,
            'a02_e2e_boss_performance_summary_d'[data_date] <= __TimeMax
        )
    RETURN DIVIDE(__OOSAmt, __OOSAmt + __DelayAmt)
```

### 4.14 子模块七：OOS Penalty Amt Share Display

```dax
OOS Penalty Amt Share Display = 
// ========================================
// 度量值: OOS Penalty Amt Share Display
// Display Folder: Fulfillment
// 用途: OOS Penalty Amt Share 格式化显示（百分比，保留一位小数，不含正号）
// 依赖: [OOS Penalty Amt Share Value]
// 格式类型: percent_1dp
// 格式串: #,##0.0%;-#,##0.0%;0.0%
// ========================================
    VAR __Value = [OOS Penalty Amt Share Value]
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            FORMAT(__Value, "#,##0.0%;-#,##0.0%;0.0%")
        )
```

### 4.15 子模块七：Delay Penalty Amt Share Value

```dax
Delay Penalty Amt Share Value = 
// ========================================
// 度量值: Delay Penalty Amt Share Value
// Display Folder: Fulfillment
// 用途: Delay Penalty Amt Share（Delay赔付金额占比）值，用于数据标签或工具提示
// 口径来源: Overview.md 子模块七 Penalty by Platform - Delay Penalty Amt Share
// 计算公式: SUM(o2o_penalty_delay_amt) / (SUM(o2o_penalty_oos_amt) + SUM(o2o_penalty_delay_amt))
//   分子: o2o_penalty_delay_amt（当前 Store_ID 的 Delay 赔付金额，原始 RMB 值）
//   分母: o2o_penalty_oos_amt + o2o_penalty_delay_amt（当前 Store_ID 的总赔付金额，原始 RMB 值）
// 筛选条件: 同 Penalty Amt Value
// 数据类型: percent_1dp → 百分比，保留一位小数，不含正号
// 关键说明: 同 OOS Penalty Amt Share Value（比率类，不除汇率，分子分母用原始 RMB 值）
// ========================================
    VAR __TimeMin = SELECTEDVALUE(Slicer_Time_Frame_Min[TimeFrame_Min])
    VAR __TimeMax = SELECTEDVALUE(Slicer_Time_Frame_Max[TimeFrame_Max])
    VAR __OOSAmt =
        CALCULATE(
            SUM('a02_e2e_boss_performance_summary_d'[o2o_penalty_oos_amt]),
            'a02_e2e_boss_performance_summary_d'[calc_type] = "fulfillment",
            'a02_e2e_boss_performance_summary_d'[data_date] >= __TimeMin,
            'a02_e2e_boss_performance_summary_d'[data_date] <= __TimeMax
        )
    VAR __DelayAmt =
        CALCULATE(
            SUM('a02_e2e_boss_performance_summary_d'[o2o_penalty_delay_amt]),
            'a02_e2e_boss_performance_summary_d'[calc_type] = "fulfillment",
            'a02_e2e_boss_performance_summary_d'[data_date] >= __TimeMin,
            'a02_e2e_boss_performance_summary_d'[data_date] <= __TimeMax
        )
    RETURN DIVIDE(__DelayAmt, __OOSAmt + __DelayAmt)
```

### 4.16 子模块七：Delay Penalty Amt Share Display

```dax
Delay Penalty Amt Share Display = 
// ========================================
// 度量值: Delay Penalty Amt Share Display
// Display Folder: Fulfillment
// 用途: Delay Penalty Amt Share 格式化显示（百分比，保留一位小数，不含正号）
// 依赖: [Delay Penalty Amt Share Value]
// 格式类型: percent_1dp
// 格式串: #,##0.0%;-#,##0.0%;0.0%
// ========================================
    VAR __Value = [Delay Penalty Amt Share Value]
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            FORMAT(__Value, "#,##0.0%;-#,##0.0%;0.0%")
        )
```

### 4.17 子模块七：Penalty Order Value

```dax
Penalty Order Value = 
// ========================================
// 度量值: Penalty Order Value
// Display Folder: Fulfillment
// 用途: Penalty Order（O2O赔付订单数 总数）值，用于堆积柱形图（按 Store_ID 分组）
// 口径来源: Overview.md 子模块七 Penalty by Platform - Penalty Order
// 计算公式: SUM(o2o_penalty_oos_order_cnt) + SUM(o2o_penalty_delay_order_cnt)
//   说明: 一个柱子的总赔付订单数 = OOS赔付订单数 + Delay赔付订单数
//         独立聚合 OOS 和 Delay 再相加，避免在堆积柱形图中双计
//         （堆积柱形图的 Y 轴应放 OOS Penalty Order Value 和 Delay Penalty Order Value 两个度量堆叠，
//          Penalty Order Value 用于工具提示或总标签展示）
// 筛选条件: 同 Penalty Amt Value（calc_type = "fulfillment" + 全局时间范围）
//   - Store_ID 由 X 轴自动传递筛选
//   - 整数类指标，不除汇率（计数无币种属性）
// 数据类型: integer → 整数，千分位整数
// ========================================
    VAR __TimeMin = SELECTEDVALUE(Slicer_Time_Frame_Min[TimeFrame_Min])
    VAR __TimeMax = SELECTEDVALUE(Slicer_Time_Frame_Max[TimeFrame_Max])
    VAR __OOSOrder =
        CALCULATE(
            SUM('a02_e2e_boss_performance_summary_d'[o2o_penalty_oos_order_cnt]),
            'a02_e2e_boss_performance_summary_d'[calc_type] = "fulfillment",
            'a02_e2e_boss_performance_summary_d'[data_date] >= __TimeMin,
            'a02_e2e_boss_performance_summary_d'[data_date] <= __TimeMax
        )
    VAR __DelayOrder =
        CALCULATE(
            SUM('a02_e2e_boss_performance_summary_d'[o2o_penalty_delay_order_cnt]),
            'a02_e2e_boss_performance_summary_d'[calc_type] = "fulfillment",
            'a02_e2e_boss_performance_summary_d'[data_date] >= __TimeMin,
            'a02_e2e_boss_performance_summary_d'[data_date] <= __TimeMax
        )
    RETURN __OOSOrder + __DelayOrder
```

### 4.18 子模块七：Penalty Order Display

```dax
Penalty Order Display = 
// ========================================
// 度量值: Penalty Order Display
// Display Folder: Fulfillment
// 用途: Penalty Order 格式化显示（整数，千分位）
// 依赖: [Penalty Order Value]
// 格式类型: integer
// 格式串: #,##0
// ========================================
    VAR __Value = [Penalty Order Value]
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            FORMAT(__Value, "#,##0")
        )
```

### 4.19 子模块七：OOS Penalty Order Value

```dax
OOS Penalty Order Value = 
// ========================================
// 度量值: OOS Penalty Order Value
// Display Folder: Fulfillment
// 用途: OOS Penalty Order（OOS赔付订单数）值，用于堆积柱形图（按 Store_ID 分组）
// 口径来源: Overview.md 子模块七 Penalty by Platform - OOS Penalty Order
// 计算公式: SUM(o2o_penalty_oos_order_cnt)
// 筛选条件: 同 Penalty Amt Value
// 数据类型: integer → 整数，千分位整数
// 用途说明: 作为堆积柱形图 Y 轴的一个堆积系列（与 Delay Penalty Order Value 堆叠）
// ========================================
    VAR __TimeMin = SELECTEDVALUE(Slicer_Time_Frame_Min[TimeFrame_Min])
    VAR __TimeMax = SELECTEDVALUE(Slicer_Time_Frame_Max[TimeFrame_Max])
    VAR __OOSOrder =
        CALCULATE(
            SUM('a02_e2e_boss_performance_summary_d'[o2o_penalty_oos_order_cnt]),
            'a02_e2e_boss_performance_summary_d'[calc_type] = "fulfillment",
            'a02_e2e_boss_performance_summary_d'[data_date] >= __TimeMin,
            'a02_e2e_boss_performance_summary_d'[data_date] <= __TimeMax
        )
    RETURN __OOSOrder
```

### 4.20 子模块七：OOS Penalty Order Display

```dax
OOS Penalty Order Display = 
// ========================================
// 度量值: OOS Penalty Order Display
// Display Folder: Fulfillment
// 用途: OOS Penalty Order 格式化显示（整数，千分位）
// 依赖: [OOS Penalty Order Value]
// 格式类型: integer
// 格式串: #,##0
// ========================================
    VAR __Value = [OOS Penalty Order Value]
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            FORMAT(__Value, "#,##0")
        )
```

### 4.21 子模块七：Delay Penalty Order Value

```dax
Delay Penalty Order Value = 
// ========================================
// 度量值: Delay Penalty Order Value
// Display Folder: Fulfillment
// 用途: Delay Penalty Order（Delay赔付订单数）值，用于堆积柱形图（按 Store_ID 分组）
// 口径来源: Overview.md 子模块七 Penalty by Platform - Delay Penalty Order
// 计算公式: SUM(o2o_penalty_delay_order_cnt)
// 筛选条件: 同 Penalty Amt Value
// 数据类型: integer → 整数，千分位整数
// 用途说明: 作为堆积柱形图 Y 轴的一个堆积系列（与 OOS Penalty Order Value 堆叠）
// ========================================
    VAR __TimeMin = SELECTEDVALUE(Slicer_Time_Frame_Min[TimeFrame_Min])
    VAR __TimeMax = SELECTEDVALUE(Slicer_Time_Frame_Max[TimeFrame_Max])
    VAR __DelayOrder =
        CALCULATE(
            SUM('a02_e2e_boss_performance_summary_d'[o2o_penalty_delay_order_cnt]),
            'a02_e2e_boss_performance_summary_d'[calc_type] = "fulfillment",
            'a02_e2e_boss_performance_summary_d'[data_date] >= __TimeMin,
            'a02_e2e_boss_performance_summary_d'[data_date] <= __TimeMax
        )
    RETURN __DelayOrder
```

### 4.22 子模块七：Delay Penalty Order Display

```dax
Delay Penalty Order Display = 
// ========================================
// 度量值: Delay Penalty Order Display
// Display Folder: Fulfillment
// 用途: Delay Penalty Order 格式化显示（整数，千分位）
// 依赖: [Delay Penalty Order Value]
// 格式类型: integer
// 格式串: #,##0
// ========================================
    VAR __Value = [Delay Penalty Order Value]
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            FORMAT(__Value, "#,##0")
        )
```

### 4.23 子模块七：OOS Penalty Order Share Value

```dax
OOS Penalty Order Share Value = 
// ========================================
// 度量值: OOS Penalty Order Share Value
// Display Folder: Fulfillment
// 用途: OOS Penalty Order Share（OOS赔付订单数占比）值，用于数据标签或工具提示
// 口径来源: Overview.md 子模块七 Penalty by Platform - OOS Penalty Order Share
// 计算公式: SUM(o2o_penalty_oos_order_cnt) / (SUM(o2o_penalty_oos_order_cnt) + SUM(o2o_penalty_delay_order_cnt))
//   分子: o2o_penalty_oos_order_cnt（当前 Store_ID 的 OOS 赔付订单数）
//   分母: o2o_penalty_oos_order_cnt + o2o_penalty_delay_order_cnt（当前 Store_ID 的总赔付订单数）
// 筛选条件: 同 Penalty Amt Value
// 数据类型: percent_1dp → 百分比，保留一位小数，不含正号
// 关键说明: 比率类指标，不除汇率；Store_ID 由 X 轴自动传递筛选
// ========================================
    VAR __TimeMin = SELECTEDVALUE(Slicer_Time_Frame_Min[TimeFrame_Min])
    VAR __TimeMax = SELECTEDVALUE(Slicer_Time_Frame_Max[TimeFrame_Max])
    VAR __OOSOrder =
        CALCULATE(
            SUM('a02_e2e_boss_performance_summary_d'[o2o_penalty_oos_order_cnt]),
            'a02_e2e_boss_performance_summary_d'[calc_type] = "fulfillment",
            'a02_e2e_boss_performance_summary_d'[data_date] >= __TimeMin,
            'a02_e2e_boss_performance_summary_d'[data_date] <= __TimeMax
        )
    VAR __DelayOrder =
        CALCULATE(
            SUM('a02_e2e_boss_performance_summary_d'[o2o_penalty_delay_order_cnt]),
            'a02_e2e_boss_performance_summary_d'[calc_type] = "fulfillment",
            'a02_e2e_boss_performance_summary_d'[data_date] >= __TimeMin,
            'a02_e2e_boss_performance_summary_d'[data_date] <= __TimeMax
        )
    RETURN DIVIDE(__OOSOrder, __OOSOrder + __DelayOrder)
```

### 4.24 子模块七：OOS Penalty Order Share Display

```dax
OOS Penalty Order Share Display = 
// ========================================
// 度量值: OOS Penalty Order Share Display
// Display Folder: Fulfillment
// 用途: OOS Penalty Order Share 格式化显示（百分比，保留一位小数，不含正号）
// 依赖: [OOS Penalty Order Share Value]
// 格式类型: percent_1dp
// 格式串: #,##0.0%;-#,##0.0%;0.0%
// ========================================
    VAR __Value = [OOS Penalty Order Share Value]
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            FORMAT(__Value, "#,##0.0%;-#,##0.0%;0.0%")
        )
```

### 4.25 子模块七：Delay Penalty Order Share Value

```dax
Delay Penalty Order Share Value = 
// ========================================
// 度量值: Delay Penalty Order Share Value
// Display Folder: Fulfillment
// 用途: Delay Penalty Order Share（Delay赔付订单数占比）值，用于数据标签或工具提示
// 口径来源: Overview.md 子模块七 Penalty by Platform - Delay Penalty Order Share
// 计算公式: SUM(o2o_penalty_delay_order_cnt) / (SUM(o2o_penalty_oos_order_cnt) + SUM(o2o_penalty_delay_order_cnt))
//   分子: o2o_penalty_delay_order_cnt（当前 Store_ID 的 Delay 赔付订单数）
//   分母: o2o_penalty_oos_order_cnt + o2o_penalty_delay_order_cnt（当前 Store_ID 的总赔付订单数）
// 筛选条件: 同 Penalty Amt Value
// 数据类型: percent_1dp → 百分比，保留一位小数，不含正号
// 关键说明: 比率类指标，不除汇率；Store_ID 由 X 轴自动传递筛选
// ========================================
    VAR __TimeMin = SELECTEDVALUE(Slicer_Time_Frame_Min[TimeFrame_Min])
    VAR __TimeMax = SELECTEDVALUE(Slicer_Time_Frame_Max[TimeFrame_Max])
    VAR __OOSOrder =
        CALCULATE(
            SUM('a02_e2e_boss_performance_summary_d'[o2o_penalty_oos_order_cnt]),
            'a02_e2e_boss_performance_summary_d'[calc_type] = "fulfillment",
            'a02_e2e_boss_performance_summary_d'[data_date] >= __TimeMin,
            'a02_e2e_boss_performance_summary_d'[data_date] <= __TimeMax
        )
    VAR __DelayOrder =
        CALCULATE(
            SUM('a02_e2e_boss_performance_summary_d'[o2o_penalty_delay_order_cnt]),
            'a02_e2e_boss_performance_summary_d'[calc_type] = "fulfillment",
            'a02_e2e_boss_performance_summary_d'[data_date] >= __TimeMin,
            'a02_e2e_boss_performance_summary_d'[data_date] <= __TimeMax
        )
    RETURN DIVIDE(__DelayOrder, __OOSOrder + __DelayOrder)
```

### 4.26 子模块七：Delay Penalty Order Share Display

```dax
Delay Penalty Order Share Display = 
// ========================================
// 度量值: Delay Penalty Order Share Display
// Display Folder: Fulfillment
// 用途: Delay Penalty Order Share 格式化显示（百分比，保留一位小数，不含正号）
// 依赖: [Delay Penalty Order Share Value]
// 格式类型: percent_1dp
// 格式串: #,##0.0%;-#,##0.0%;0.0%
// ========================================
    VAR __Value = [Delay Penalty Order Share Value]
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            FORMAT(__Value, "#,##0.0%;-#,##0.0%;0.0%")
        )
```

---

## 5. 度量值清单与 Display Folder

| 序号 | 度量值名称                              | Display Folder | 子模块 | 用途                                      |
| ---- | --------------------------------------- | --------------- | ------ | ----------------------------------------- |
| 1    | Fulfillment% Value                      | Fulfillment     | 五     | 条形图值（按 brand 分组）                 |
| 2    | Fulfillment% Display                    | Fulfillment     | 五     | 条形图标签（percent_1dp）                 |
| 3    | Avg Store Passed Value                  | Fulfillment     | 六     | 条形图值（按 brand 分组）                 |
| 4    | Avg Store Passed Display                | Fulfillment     | 六     | 条形图标签（decimal_1dp）                 |
| 5    | Avg Processing Time Value               | Fulfillment     | 六     | 条形图值（按 brand 分组）                 |
| 6    | Avg Processing Time Display             | Fulfillment     | 六     | 条形图标签（decimal_1dp）                 |
| 7    | Penalty Amt Value                       | Fulfillment     | 七     | 柱形图总值/工具提示（按 Store_ID 分组）   |
| 8    | Penalty Amt Display                     | Fulfillment     | 七     | 柱形图总标签（currency）                  |
| 9    | OOS Penalty Amt Value                   | Fulfillment     | 七     | 柱形图堆积系列（OOS）                     |
| 10   | OOS Penalty Amt Display                 | Fulfillment     | 七     | 柱形图标签（currency）                    |
| 11   | Delay Penalty Amt Value                 | Fulfillment     | 七     | 柱形图堆积系列（Delay）                   |
| 12   | Delay Penalty Amt Display               | Fulfillment     | 七     | 柱形图标签（currency）                    |
| 13   | OOS Penalty Amt Share Value             | Fulfillment     | 七     | 工具提示/数据标签                         |
| 14   | OOS Penalty Amt Share Display           | Fulfillment     | 七     | 数据标签（percent_1dp）                   |
| 15   | Delay Penalty Amt Share Value           | Fulfillment     | 七     | 工具提示/数据标签                         |
| 16   | Delay Penalty Amt Share Display         | Fulfillment     | 七     | 数据标签（percent_1dp）                   |
| 17   | Penalty Order Value                     | Fulfillment     | 七     | 柱形图总值/工具提示                       |
| 18   | Penalty Order Display                   | Fulfillment     | 七     | 柱形图总标签（integer）                   |
| 19   | OOS Penalty Order Value                 | Fulfillment     | 七     | 柱形图堆积系列（OOS）                     |
| 20   | OOS Penalty Order Display               | Fulfillment     | 七     | 柱形图标签（integer）                     |
| 21   | Delay Penalty Order Value               | Fulfillment     | 七     | 柱形图堆积系列（Delay）                   |
| 22   | Delay Penalty Order Display             | Fulfillment     | 七     | 柱形图标签（integer）                     |
| 23   | OOS Penalty Order Share Value           | Fulfillment     | 七     | 工具提示/数据标签                         |
| 24   | OOS Penalty Order Share Display         | Fulfillment     | 七     | 数据标签（percent_1dp）                   |
| 25   | Delay Penalty Order Share Value         | Fulfillment     | 七     | 工具提示/数据标签                         |
| 26   | Delay Penalty Order Share Display       | Fulfillment     | 七     | 数据标签（percent_1dp）                   |

---

## 6. 视觉对象配置

### 6.1 子模块五：Fulfillment% by Label（条形图）

| 配置项     | 值                                                              |
| ---------- | --------------------------------------------------------------- |
| Y 轴       | `a02_e2e_boss_performance_summary_d[brand]`                     |
| X 轴       | `[Fulfillment% Value]`                                          |
| 数据标签   | `[Fulfillment% Display]`                                        |
| 排序       | 按 `[Fulfillment% Value]` 从高到低                              |
| 全局筛选器 | Slicer_Time_Frame_Min、Slicer_Time_Frame_Max                    |

> 条形图 Y 轴直接使用事实表 `brand` 字段，图表天然自带 brand 分组属性，度量值无需显式处理 brand 筛选。

### 6.2 子模块六：Order Processing Efficiency by Label（条形图）

| 配置项     | 值                                                              |
| ---------- | --------------------------------------------------------------- |
| Y 轴       | `a02_e2e_boss_fulfillment_request_data_d[brand]`                |
| X 轴       | `[Avg Store Passed Value]` 或 `[Avg Processing Time Value]`     |
| 数据标签   | 对应 `[* Display]` 度量                                         |
| 排序       | 按对应 Value 从高到低                                           |
| 全局筛选器 | Slicer_Time_Frame_Min、Slicer_Time_Frame_Max                    |

> 两个指标可分别放在两个条形图中，或使用 Power BI 的「小倍数」功能并排展示。建议两个独立条形图，Y 轴 brand 排序保持一致便于对比。

### 6.3 子模块七：Penalty by Platform（堆积柱形图）

**金额类堆积柱形图（Penalty Amt 系列）**：

| 配置项         | 值                                                              |
| -------------- | --------------------------------------------------------------- |
| X 轴           | `Slicer_Store_Name[Store_ID]`                                   |
| Y 轴（堆积）   | `[OOS Penalty Amt Value]` + `[Delay Penalty Amt Value]`         |
| 数据标签       | `[OOS Penalty Amt Display]` / `[Delay Penalty Amt Display]`     |
| 工具提示       | `[Penalty Amt Display]`、`[OOS Penalty Amt Share Display]`、`[Delay Penalty Amt Share Display]` |
| 全局筛选器     | Slicer_Time_Frame_Min、Slicer_Time_Frame_Max、Slicer_Currency_Selection |

**订单数类堆积柱形图（Penalty Order 系列）**：

| 配置项         | 值                                                              |
| -------------- | --------------------------------------------------------------- |
| X 轴           | `Slicer_Store_Name[Store_ID]`                                   |
| Y 轴（堆积）   | `[OOS Penalty Order Value]` + `[Delay Penalty Order Value]`     |
| 数据标签       | `[OOS Penalty Order Display]` / `[Delay Penalty Order Display]` |
| 工具提示       | `[Penalty Order Display]`、`[OOS Penalty Order Share Display]`、`[Delay Penalty Order Share Display]` |
| 全局筛选器     | Slicer_Time_Frame_Min、Slicer_Time_Frame_Max                    |

> **关键说明**：
> 1. 堆积柱形图 Y 轴同时放入 OOS 和 Delay 两个独立度量值，Power BI 自动堆积。
> 2. `Penalty Amt Value`（总额）和 `Penalty Order Value`（总数）不放入 Y 轴，仅作为工具提示展示总数；若放入 Y 轴会与 OOS+Delay 堆叠重复计算。
> 3. Share 类指标仅作为工具提示或数据标签展示，不参与堆积。
> 4. X 轴使用 `Slicer_Store_Name[Store_ID]`，通过 1:N 关系自动将筛选传递到事实表 `a02_e2e_boss_performance_summary_d[store_name]`。

---

## 7. 验证方法

### 7.1 子模块五：Fulfillment% 验证

```sql
-- Fulfillment%（所有 brand 汇总，全局时间范围）
SELECT
  SUM(o2o_fulfillment_shipped_order_cnt) * 1.0 / SUM(o2o_fulfillment_request_order_cnt) AS Fulfillment_Pct
FROM a02_e2e_boss_performance_summary_d
WHERE calc_type = 'fulfillment'
  AND data_date BETWEEN '__TimeMin' AND '__TimeMax';

-- Fulfillment%（按 brand 分组）
SELECT
  brand,
  SUM(o2o_fulfillment_shipped_order_cnt) * 1.0 / SUM(o2o_fulfillment_request_order_cnt) AS Fulfillment_Pct
FROM a02_e2e_boss_performance_summary_d
WHERE calc_type = 'fulfillment'
  AND data_date BETWEEN '__TimeMin' AND '__TimeMax'
GROUP BY brand
ORDER BY Fulfillment_Pct DESC;
```

### 7.2 子模块六：Avg Store Passed / Avg Processing Time 验证

```sql
-- Avg Store Passed（按 brand 分组）
SELECT
  brand,
  SUM(o2o_fulfillment_request_times) * 1.0 / SUM(o2o_fulfillment_request_sku_qty) AS Avg_Store_Passed
FROM a02_e2e_boss_fulfillment_request_data_d
WHERE calc_type = 'fulfillment'
  AND data_date BETWEEN '__TimeMin' AND '__TimeMax'
GROUP BY brand
ORDER BY Avg_Store_Passed DESC;

-- Avg Processing Time（按 brand 分组）
SELECT
  brand,
  SUM(o2o_fulfillment_request_duration) * 1.0 / SUM(o2o_fulfillment_request_sku_qty) AS Avg_Processing_Time
FROM a02_e2e_boss_fulfillment_request_data_d
WHERE calc_type = 'fulfillment'
  AND data_date BETWEEN '__TimeMin' AND '__TimeMax'
GROUP BY brand
ORDER BY Avg_Processing_Time DESC;
```

### 7.3 子模块七：Penalty 系列验证

```sql
-- Penalty Amt（按 Store_ID 分组，对应 store_name）
-- 注意：Slicer_Store_Name[Store_ID] 与事实表[store_name] 通过 1:N 关联
--       验证时需 join Slicer_Store_Name 表或直接按 store_name 分组
SELECT
  s.Store_ID,
  s.Store_Label,
  SUM(p.o2o_penalty_oos_amt) AS OOS_Amt_RMB,
  SUM(p.o2o_penalty_delay_amt) AS Delay_Amt_RMB,
  SUM(p.o2o_penalty_oos_amt) + SUM(p.o2o_penalty_delay_amt) AS Total_Amt_RMB,
  -- 换算为美元（假设 __FXRate = 7）
  (SUM(p.o2o_penalty_oos_amt) + SUM(p.o2o_penalty_delay_amt)) / 7 AS Total_Amt_USD,
  -- Share 类（不受汇率影响）
  SUM(p.o2o_penalty_oos_amt) * 1.0 / (SUM(p.o2o_penalty_oos_amt) + SUM(p.o2o_penalty_delay_amt)) AS OOS_Share,
  SUM(p.o2o_penalty_delay_amt) * 1.0 / (SUM(p.o2o_penalty_oos_amt) + SUM(p.o2o_penalty_delay_amt)) AS Delay_Share
FROM a02_e2e_boss_performance_summary_d p
JOIN Slicer_Store_Name s ON s.Store_ID = p.store_name  -- 关联关系
WHERE p.calc_type = 'fulfillment'
  AND p.data_date BETWEEN '__TimeMin' AND '__TimeMax'
GROUP BY s.Store_ID, s.Store_Label
ORDER BY Total_Amt_RMB DESC;

-- Penalty Order（按 Store_ID 分组）
SELECT
  s.Store_ID,
  s.Store_Label,
  SUM(p.o2o_penalty_oos_order_cnt) AS OOS_Order,
  SUM(p.o2o_penalty_delay_order_cnt) AS Delay_Order,
  SUM(p.o2o_penalty_oos_order_cnt) + SUM(p.o2o_penalty_delay_order_cnt) AS Total_Order,
  SUM(p.o2o_penalty_oos_order_cnt) * 1.0 / (SUM(p.o2o_penalty_oos_order_cnt) + SUM(p.o2o_penalty_delay_order_cnt)) AS OOS_Order_Share,
  SUM(p.oo2o_penalty_delay_order_cnt) * 1.0 / (SUM(p.o2o_penalty_oos_order_cnt) + SUM(p.o2o_penalty_delay_order_cnt)) AS Delay_Order_Share
FROM a02_e2e_boss_performance_summary_d p
JOIN Slicer_Store_Name s ON s.Store_ID = p.store_name
WHERE p.calc_type = 'fulfillment'
  AND p.data_date BETWEEN '__TimeMin' AND '__TimeMax'
GROUP BY s.Store_ID, s.Store_Label
ORDER BY Total_Order DESC;
```

### 7.4 汇率换算验证

| 验证项 | 方法 |
| ------ | ---- |
| 金额类随币种切换变化 | 在 Slicer_Currency_Selection 切换 RMB/USD，确认 Penalty Amt Display 数值变化（RMB ÷ 7 = USD） |
| 比率类不受币种影响 | 切换币种，确认 Fulfillment%、Share 类指标数值保持不变 |
| 整数类不受币种影响 | 切换币种，确认 Penalty Order 数值保持不变 |

---

## 8. 注意事项

1. **不涉及 LY**：本方案三个子模块仅计算当期值，不计算去年同期值（LY）。如后续需要对比去年同期，需新增 LY 版本度量并采用财历映射（参考 Overview/Sales 方案的 LY 实现）。

2. **brand 字段直接使用事实表字段**：子模块五/六的条形图 Y 轴直接使用事实表 `a02_e2e_boss_performance_summary_d[brand]` / `a02_e2e_boss_fulfillment_request_data_d[brand]`，不建立独立的 brand 维度表。图表天然自带 brand 分组属性，度量值无需显式处理 brand 筛选。若后续需要 brand 切片器联动多个视觉对象，建议另建独立 brand 维度表。

3. **Slicer_Store_Name 关系**：子模块七的 `Slicer_Store_Name[Store_ID]` 与事实表 `a02_e2e_boss_performance_summary_d[store_name]` 建立 1:N 关系。横轴使用 `Store_ID`，模型天然自带筛选效果。请确认关系基数设置为「1:N」，单向（从 Slicer_Store_Name 筛选事实表）。

4. **堆积柱形图避免双计**：Y 轴堆积 OOS 和 Delay 两个独立度量值时，`Penalty Amt Value`（= OOS + Delay）和 `Penalty Order Value`（= OOS + Delay）**不要**放入 Y 轴，仅作为工具提示展示总数。否则会与 OOS+Delay 堆叠结果重复计算。

5. **汇率换算规则**：
   - 金额类（Penalty Amt / OOS Penalty Amt / Delay Penalty Amt）÷ `Currency_ExchangeRate`，受 Slicer_Currency_Selection 控制。
   - 比率类（Fulfillment% / Share 类 / Avg Store Passed / Avg Processing Time）不除汇率，分子分母同币种相除自动抵消，比值不受汇率影响。
   - 整数类（Penalty Order / OOS Penalty Order / Delay Penalty Order）不除汇率，计数无币种属性。
   - **Share 类分子分母使用原始 RMB 值聚合后再相除**，不使用换算后的 USD 值，避免汇率精度误差导致 Share 之和 ≠ 100%。

6. **Avg Processing Time 换货剔除**：口径注释提到「剔除换货的订单」，已在数据源层过滤，度量值无需额外筛选。若后续数据源变更，需在事实表新增换货标记字段并在 DAX 中显式筛选。

7. **BLANK 处理**：所有 Display 度量在 Value 为 BLANK 时返回 "-"，避免图表显示空白标签。分母为 0 时 DIVIDE 返回 BLANK，Display 显示 "-"。

8. **时间筛选仅用全局范围**：三个子模块的分组字段为 brand / Store_ID（非 timeframe），因此**不使用** `Slicer_Time_Frame` X 轴表和 `IsTimeFrameVisible` 视觉对象级别筛选器，仅使用 `Slicer_Time_Frame_Min/Max` 的全局时间范围筛选事实表 `data_date`。

9. **与矩阵方案的关系**：本方案度量值独立于矩阵的 `BOSS Core KPI Act/LY Base Value`，不复用矩阵的 SWITCH 路由。两套度量值可并存，分别服务条形图/堆积柱形图与矩阵视觉对象。

10. **DAX 语法规范**：文本常量使用双引号 `" "`，表名使用单引号 `' '`，列名使用方括号 `[ ]`。例如：`'a02_e2e_boss_performance_summary_d'[calc_type] = "fulfillment"`。
