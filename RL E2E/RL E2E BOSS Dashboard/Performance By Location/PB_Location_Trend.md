# Power BI 解决方案 — PB Location：子模块一~四 Value/Display 度量

> status: ready
> created: 2026-08-05
> type: 度量值开发 + 可视化构建
> 口径来源: 口径文档/PB Location.md 子模块一~四
> 参考实现: Overview/Sales/Overview_Sales_ms.md（柱形图/趋势图 Value/Display 范式）

---

## 1. 需求理解

为 Performance By Location 页面的四个子模块提供独立度量值（Value + Display），用于柱形图/趋势图：

| 子模块 | 指标 | 可视化类型 | 数据底表 | calc_type |
|--------|------|-----------|---------|-----------|
| 一：Fulfilled Order by Region/Store Type | Shipped Order Qty, Shipped Order Amt（含 LY/YOY） | 柱形图 | a02_e2e_boss_performance_summary_d | fulfillment |
| 二：Fulfillment% Trend | Fulfillment%（趋势） | 柱形图/趋势图 | a02_e2e_boss_performance_summary_d | fulfillment |
| 三：Unfulfilled Order by Region | Unfulfilled Order 四分类 + Share 四分类 + Tooltip | 柱形图 | t01_o2o_fulfillment_order_detail_d | — |
| 四：Failed Request by Reason | Failed Request | 柱形图 | a02_e2e_boss_fulfillment_fail_reason_d | — |

**核心设计原则**：
- 无需矩阵 SWITCH 路由分发，每个指标独立编写 Value/Display 度量
- 分组维度（store_region/store_type）直接拉取数据表字段到视觉对象，无需在 DAX 中添加分组维度
- 柱形图/趋势图 X 轴 = Slicer_Time_Frame[TimeFrame_Value]，需配置 [IsTimeFrameVisible] = 1 视觉对象级别筛选器
- 折线/图例 = store_region 或 store_type（直接拉事实表字段）
- LY 采用财历映射（直接读取日期表内置 TimeFrame_Min_LY / TimeFrame_Max_LY 字段）
- 一切口径以口径文档 PB Location.md 为准

---

## 2. 现状分析

### 2.1 数据底表

| 对象 | 名称 | 出处 |
|------|------|------|
| 事实表1 | a02_e2e_boss_performance_summary_d | 子模块一/二 |
| 事实表2 | t01_o2o_fulfillment_order_detail_d | 子模块三 |
| 事实表3 | a02_e2e_boss_fulfillment_fail_reason_d | 子模块四 |

### 2.2 维度表清单

| 维度表 | 类型 | 连接方式 |
|--------|------|---------|
| Slicer_Time_Frame | 断开维度 | 柱形图/趋势图 X 轴；SELECTEDVALUE 读取 TimeFrame_ID/Key/Value/Min/Max/LY 字段 |
| Slicer_Time_Frame_Min | 断开维度 | 起始切片器；SELECTEDVALUE 读取 TimeFrame_Min/TimeFrame_Key/TimeFrame_ID/LY 字段 |
| Slicer_Time_Frame_Max | 断开维度 | 结束切片器；SELECTEDVALUE 读取 TimeFrame_Max/TimeFrame_Key/TimeFrame_ID/LY 字段 |

---

## 3. 方案设计

### 3.1 粒度处理机制

范式：
- 用户在 Slicer_Time_Frame_Min/Max 切片器选择起止时间
- 所选行的 TimeFrame_ID 决定当前粒度
- 柱形图/趋势图 X 轴 = Slicer_Time_Frame[TimeFrame_Value]
- 通过 [IsTimeFrameVisible] 视觉对象级别筛选器（=1）过滤：同粒度 + Key 在 [MinKey, MaxKey] 区间
- 子模块三/四不按 timeframe 聚合，仅用全局时间范围筛选

### 3.2 时间偏移规则（LY — 财历映射）

直接读取日期表内置 LY 字段：
- 全局范围：Slicer_Time_Frame_Min[TimeFrame_Min_LY] / Slicer_Time_Frame_Max[TimeFrame_Max_LY]
- X 轴时间段：Slicer_Time_Frame[TimeFrame_Min_LY] / Slicer_Time_Frame[TimeFrame_Max_LY]
- 无需 EDATE -12 或 Key 偏移计算

### 3.3 格式规范

| 格式类型 | 格式串 | 示例 | 适用度量 |
|---------|--------|------|---------|
| integer | `#,##0` | 1,234 | Shipped Order Qty, Failed Request, Unfulfilled Order |
| currency | `__CurrencySymbol & FORMAT(__Value, "#,##0")` | ¥1,234 | Shipped Order Amt |
| percent_1dp | `#,##0.0%` | 85.5% | Fulfillment%, YOY, Share |
| delta_bp | `+#,##0bp;-#,##0bp;0bp` | +120bp | vs LY（率类差值 bp） |

---

## 4. 度量值实现

### 4.1 IsTimeFrameVisible（辅助度量 — X 轴视觉对象级别筛选器）

> 复用 Overview_Sales_ms.md 中的 IsTimeFrameVisible，逻辑完全一致

```dax
IsTimeFrameVisible =
// ========================================
// 度量值: IsTimeFrameVisible
// Display Folder: PB Location
// 用途: 判断柱形图/趋势图 X 轴当前遍历的 timeframe
//       是否落在起止切片器选定的范围内（同粒度 + Key 在 [MinKey, MaxKey] 区间）
// 返回: 1（显示）或 0（隐藏）
// 依赖: Slicer_Time_Frame[TimeFrame_ID, TimeFrame_Key],
//       Slicer_Time_Frame_Min[TimeFrame_ID, TimeFrame_Key, TimeFrame_Value],
//       Slicer_Time_Frame_Max[TimeFrame_ID, TimeFrame_Key, TimeFrame_Value]
// 使用方式: 作为柱形图/趋势图 X 轴的视觉对象级别筛选器
//           筛选条件: IsTimeFrameVisible = 1
// ========================================
    VAR __CurrentTimeFrameID = SELECTEDVALUE(Slicer_Time_Frame[TimeFrame_ID])
    VAR __CurrentKey = SELECTEDVALUE(Slicer_Time_Frame[TimeFrame_Key])
    VAR __MinTimeFrameID = SELECTEDVALUE(Slicer_Time_Frame_Min[TimeFrame_ID])
    VAR __MaxTimeFrameID = SELECTEDVALUE(Slicer_Time_Frame_Max[TimeFrame_ID])
    VAR __IsSameGranularity =
        NOT ISBLANK(__CurrentTimeFrameID)
        && __CurrentTimeFrameID = __MinTimeFrameID
        && __CurrentTimeFrameID = __MaxTimeFrameID
    VAR __MinKey =
        IF(
            ISFILTERED(Slicer_Time_Frame_Min[TimeFrame_Value]),
            MIN(Slicer_Time_Frame_Min[TimeFrame_Key]),
            MIN(Slicer_Time_Frame[TimeFrame_Key])
        )
    VAR __MaxKey =
        IF(
            ISFILTERED(Slicer_Time_Frame_Max[TimeFrame_Value]),
            MAX(Slicer_Time_Frame_Max[TimeFrame_Key]),
            MAX(Slicer_Time_Frame[TimeFrame_Key])
        )
    RETURN
        IF(
            NOT __IsSameGranularity, 0,
            IF(
                __CurrentKey >= __MinKey && __CurrentKey <= __MaxKey,
                1,
                0
            )
        )
```

---

## 子模块一：BOSS Fulfillment - Fulfilled Order by Region/Store Type

> 柱形图 X 轴 =  store_region 或 store_type（直接拉取）
> calc_type = "fulfillment"

### 4.2 TY Shipped Order Qty Value

```dax
TY Shipped Order Qty Value =
// ========================================
// 度量值: TY Shipped Order Qty Value
// Display Folder: PB Location
// 用途: TY O2O已配货订单量 Act 值，用于柱形图 Y 轴
// 口径来源: PB Location.md 子模块一 - Shipped Order Qty
// 计算公式: SUM(o2o_fulfillment_shipped_order_cnt)
// 筛选条件:
//   - calc_type = "fulfillment"
//   - 柱形图 X 轴 =  store_region 或 store_type（直接拉取）
// 数据类型: integer → 千分位整数
// 格式: #,##0
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

### 4.3 TY Shipped Order Qty Display

```dax
TY Shipped Order Qty Display =
// ========================================
// 度量值: TY Shipped Order Qty Display
// Display Folder: PB Location
// 用途: TY O2O已配货订单量 格式化显示
// 依赖: [TY Shipped Order Qty Value]
// 格式类型: integer → #,##0
// ========================================
    VAR __Value = [TY Shipped Order Qty Value]
    RETURN
        IF(ISBLANK(__Value), "-", FORMAT(__Value, "#,##0"))
```

### 4.4 LY Shipped Order Qty Value（财历映射）

```dax
LY Shipped Order Qty Value =
// ========================================
// 度量值: LY Shipped Order Qty Value
// Display Folder: PB Location
// 用途: LY O2O已配货订单量（去年同期），用于柱形图 Y 轴
// 口径来源: PB Location.md 子模块一 - LY Fulfilled Order Qty
// 计算公式: 去年同期 SUM(o2o_fulfillment_shipped_order_cnt)
// 时间偏移: 财历映射（直接读取日期表内置 LY 字段）
//   全局范围:   Slicer_Time_Frame_Min[TimeFrame_Min_LY] / Slicer_Time_Frame_Max[TimeFrame_Max_LY]
//   柱形图 X 轴 =  store_region 或 store_type（直接拉取）
// 数据类型: integer → 千分位整数
// ========================================
    VAR __LYTimeMin = SELECTEDVALUE(Slicer_Time_Frame_Min[TimeFrame_Min_LY])
    VAR __LYTimeMax = SELECTEDVALUE(Slicer_Time_Frame_Max[TimeFrame_Max_LY])
    VAR __Result =
        CALCULATE(
            SUM('a02_e2e_boss_performance_summary_d'[o2o_fulfillment_shipped_order_cnt]),
            'a02_e2e_boss_performance_summary_d'[calc_type] = "fulfillment",
            'a02_e2e_boss_performance_summary_d'[data_date] >= __LYTimeMin,
            'a02_e2e_boss_performance_summary_d'[data_date] <= __LYTimeMax
        )
    RETURN __Result
```

### 4.5 LY Shipped Order Qty Display

```dax
LY Shipped Order Qty Display =
// ========================================
// 度量值: LY Shipped Order Qty Display
// Display Folder: PB Location
// 用途: LY O2O已配货订单量 格式化显示
// 依赖: [LY Shipped Order Qty Value]
// 格式类型: integer → #,##0
// ========================================
    VAR __Value = [LY Shipped Order Qty Value]
    RETURN
        IF(ISBLANK(__Value), "-", FORMAT(__Value, "#,##0"))
```

### 4.6 Shipped Order Qty YOY Value

```dax
Shipped Order Qty YOY Value =
// ========================================
// 度量值: Shipped Order Qty YOY Value
// Display Folder: PB Location
// 用途: O2O已配货订单量同比（今年/去年-1）
// 口径来源: PB Location.md 子模块一 - YOY
// 计算公式: [TY Shipped Order Qty Value] / [LY Shipped Order Qty Value] - 1
// 数据类型: percent_1dp → 百分比，保留一位小数，不含正号
// ========================================
    VAR __TY = [TY Shipped Order Qty Value]
    VAR __LY = [LY Shipped Order Qty Value]
    RETURN DIVIDE(__TY, __LY) - 1
```

### 4.7 Shipped Order Qty YOY Display

```dax
Shipped Order Qty YOY Display =
// ========================================
// 度量值: Shipped Order Qty YOY Display
// Display Folder: PB Location
// 用途: O2O已配货订单量同比 格式化显示
// 依赖: [Shipped Order Qty YOY Value]
// 格式类型: percent_1dp → #,##0.0%
// ========================================
    VAR __Value = [Shipped Order Qty YOY Value]
    RETURN
        IF(ISBLANK(__Value), "-", FORMAT(__Value, "#,##0.0%"))
```

### 4.8 TY Shipped Order Amt Value

```dax
TY Shipped Order Amt Value =
// ========================================
// 度量值: TY Shipped Order Amt Value
// Display Folder: PB Location
// 用途: TY O2O已配货销售金额 Act 值，用于柱形图 Y 轴
// 口径来源: PB Location.md 子模块一 - Shipped Order Amt
// 计算公式: SUM(o2o_fulfillment_shipped_sales_amt)
// 筛选条件:
//   - calc_type = "fulfillment"
//   - 柱形图 X 轴 =  store_region 或 store_type（直接拉取）
//   - 金额类指标 ÷ __FXRate（汇率换算）
// 数据类型: currency → 货币符号由币种切片器决定，千分位整数
// ========================================
    VAR __TimeMin = SELECTEDVALUE(Slicer_Time_Frame_Min[TimeFrame_Min])
    VAR __TimeMax = SELECTEDVALUE(Slicer_Time_Frame_Max[TimeFrame_Max])

    VAR __FXRate = SELECTEDVALUE('Slicer_Currency_Selection'[Currency_ExchangeRate], 1)
    VAR __Result =
        CALCULATE(
            SUM('a02_e2e_boss_performance_summary_d'[o2o_fulfillment_shipped_sales_amt]),
            'a02_e2e_boss_performance_summary_d'[calc_type] = "fulfillment",
            'a02_e2e_boss_performance_summary_d'[data_date] >= __TimeMin,
            'a02_e2e_boss_performance_summary_d'[data_date] <= __TimeMax
        )
    RETURN DIVIDE(__Result, __FXRate)
```

### 4.9 TY Shipped Order Amt Display

```dax
TY Shipped Order Amt Display =
// ========================================
// 度量值: TY Shipped Order Amt Display
// Display Folder: PB Location
// 用途: TY O2O已配货销售金额 格式化显示
// 依赖: [TY Shipped Order Amt Value], Slicer_Currency_Selection
// 格式类型: currency → __CurrencySymbol & FORMAT(__Value, "#,##0")
// ========================================
    VAR __Value = [TY Shipped Order Amt Value]
    VAR __CurrencySymbol = SELECTEDVALUE('Slicer_Currency_Selection'[Currency_Symbol], "¥")
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            __CurrencySymbol & FORMAT(__Value, "#,##0")
        )
```

### 4.10 LY Shipped Order Amt Value（财历映射）

```dax
LY Shipped Order Amt Value =
// ========================================
// 度量值: LY Shipped Order Amt Value
// Display Folder: PB Location
// 用途: LY O2O已配货销售金额（去年同期），用于柱形图 Y 轴
// 口径来源: PB Location.md 子模块一 - LY Fulfilled Order Amt
// 计算公式: 去年同期 SUM(o2o_fulfillment_shipped_sales_amt)
// 时间偏移: 财历映射（直接读取日期表内置 LY 字段）
//   全局范围:   Slicer_Time_Frame_Min[TimeFrame_Min_LY] / Slicer_Time_Frame_Max[TimeFrame_Max_LY]
//   X 轴 =  store_region 或 store_type（直接拉取）
//   金额类指标 ÷ __FXRate（汇率换算）
// 数据类型: currency → 货币符号由币种切片器决定，千分位整数
// ========================================
    VAR __LYTimeMin = SELECTEDVALUE(Slicer_Time_Frame_Min[TimeFrame_Min_LY])
    VAR __LYTimeMax = SELECTEDVALUE(Slicer_Time_Frame_Max[TimeFrame_Max_LY])
    VAR __FXRate = SELECTEDVALUE('Slicer_Currency_Selection'[Currency_ExchangeRate], 1)
    VAR __Result =
        CALCULATE(
            SUM('a02_e2e_boss_performance_summary_d'[o2o_fulfillment_shipped_sales_amt]),
            'a02_e2e_boss_performance_summary_d'[calc_type] = "fulfillment",
            'a02_e2e_boss_performance_summary_d'[data_date] >= __LYTimeMin,
            'a02_e2e_boss_performance_summary_d'[data_date] <= __LYTimeMax
        )
    RETURN DIVIDE(__Result, __FXRate)
```

### 4.11 LY Shipped Order Amt Display

```dax
LY Shipped Order Amt Display =
// ========================================
// 度量值: LY Shipped Order Amt Display
// Display Folder: PB Location
// 用途: LY O2O已配货销售金额 格式化显示
// 依赖: [LY Shipped Order Amt Value], Slicer_Currency_Selection
// 格式类型: currency → __CurrencySymbol & FORMAT(__Value, "#,##0")
// ========================================
    VAR __Value = [LY Shipped Order Amt Value]
    VAR __CurrencySymbol = SELECTEDVALUE('Slicer_Currency_Selection'[Currency_Symbol], "¥")
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            __CurrencySymbol & FORMAT(__Value, "#,##0")
        )
```

### 4.12 Shipped Order Amt YOY Value

```dax
Shipped Order Amt YOY Value =
// ========================================
// 度量值: Shipped Order Amt YOY Value
// Display Folder: PB Location
// 用途: O2O已配货销售金额同比（今年/去年-1）
// 口径来源: PB Location.md 子模块一 - YOY
// 计算公式: [TY Shipped Order Amt Value] / [LY Shipped Order Amt Value] - 1
// 数据类型: percent_1dp → 百分比，保留一位小数，不含正号
// ========================================
    VAR __TY = [TY Shipped Order Amt Value]
    VAR __LY = [LY Shipped Order Amt Value]
    RETURN DIVIDE(__TY, __LY) - 1
```

### 4.13 Shipped Order Amt YOY Display

```dax
Shipped Order Amt YOY Display =
// ========================================
// 度量值: Shipped Order Amt YOY Display
// Display Folder: PB Location
// 用途: O2O已配货销售金额同比 格式化显示
// 依赖: [Shipped Order Amt YOY Value]
// 格式类型: percent_1dp → #,##0.0%
// ========================================
    VAR __Value = [Shipped Order Amt YOY Value]
    RETURN
        IF(ISBLANK(__Value), "-", FORMAT(__Value, "#,##0.0%"))
```

---

## 子模块二：Fulfillment% Trend

> 柱形图/趋势图 X 轴 = Slicer_Time_Frame[TimeFrame_Value]，折线 = store_region 或 store_type（直接拉取）
> calc_type = "fulfillment"

### 4.14 TY Fulfillment% Value

```dax
TY Fulfillment% Value =
// ========================================
// 度量值: TY Fulfillment% Value
// Display Folder: PB Location
// 用途: TY O2O订单履约率 Act 值，用于柱形图/趋势图 Y 轴
// 口径来源: PB Location.md 子模块二 - Fulfillment%
// 计算公式: SUM(o2o_fulfillment_shipped_order_cnt) / SUM(o2o_fulfillment_request_order_cnt)
//   分子: o2o_fulfillment_shipped_order_cnt
//   分母: o2o_fulfillment_request_order_cnt
// 筛选条件:
//   - calc_type = "fulfillment"
//   - 全局时间范围 + X 轴上下文（双层时间筛选）
//   - 比率类，不除汇率（分子分母同币种，相除自动抵消）
// 数据类型: percent_1dp → 百分比，保留一位小数，不含正号
// ========================================
    VAR __TimeMin = SELECTEDVALUE(Slicer_Time_Frame_Min[TimeFrame_Min])
    VAR __TimeMax = SELECTEDVALUE(Slicer_Time_Frame_Max[TimeFrame_Max])
    VAR __CurrentTFMin = SELECTEDVALUE(Slicer_Time_Frame[TimeFrame_Min])
    VAR __CurrentTFMax = SELECTEDVALUE(Slicer_Time_Frame[TimeFrame_Max])
    // 分子：o2o_fulfillment_shipped_order_cnt
    VAR __Numerator =
        CALCULATE(
            SUM('a02_e2e_boss_performance_summary_d'[o2o_fulfillment_shipped_order_cnt]),
            'a02_e2e_boss_performance_summary_d'[calc_type] = "fulfillment",
            'a02_e2e_boss_performance_summary_d'[data_date] >= __TimeMin,
            'a02_e2e_boss_performance_summary_d'[data_date] <= __TimeMax,
            'a02_e2e_boss_performance_summary_d'[data_date] >= __CurrentTFMin,
            'a02_e2e_boss_performance_summary_d'[data_date] <= __CurrentTFMax
        )
    // 分母：o2o_fulfillment_request_order_cnt
    VAR __Denominator =
        CALCULATE(
            SUM('a02_e2e_boss_performance_summary_d'[o2o_fulfillment_request_order_cnt]),
            'a02_e2e_boss_performance_summary_d'[calc_type] = "fulfillment",
            'a02_e2e_boss_performance_summary_d'[data_date] >= __TimeMin,
            'a02_e2e_boss_performance_summary_d'[data_date] <= __TimeMax,
            'a02_e2e_boss_performance_summary_d'[data_date] >= __CurrentTFMin,
            'a02_e2e_boss_performance_summary_d'[data_date] <= __CurrentTFMax
        )
    RETURN DIVIDE(__Numerator, __Denominator)
```

### 4.15 TY Fulfillment% Display

```dax
TY Fulfillment% Display =
// ========================================
// 度量值: TY Fulfillment% Display
// Display Folder: PB Location
// 用途: TY O2O订单履约率 格式化显示
// 依赖: [TY Fulfillment% Value]
// 格式类型: percent_1dp → #,##0.0%
// ========================================
    VAR __Value = [TY Fulfillment% Value]
    RETURN
        IF(ISBLANK(__Value), "-", FORMAT(__Value, "#,##0.0%"))
```

### 4.16 LY Fulfillment% Value（财历映射）

```dax
LY Fulfillment% Value =
// ========================================
// 度量值: LY Fulfillment% Value
// Display Folder: PB Location
// 用途: LY O2O订单履约率（去年同期），用于柱形图/趋势图 Y 轴
// 口径来源: PB Location.md 子模块二 - Fulfillment% LY（隐含）
// 计算公式: 去年同期 SUM(shipped_order_cnt) / SUM(request_order_cnt)
// 时间偏移: 财历映射（直接读取日期表内置 LY 字段）
//   全局范围:   Slicer_Time_Frame_Min[TimeFrame_Min_LY] / Slicer_Time_Frame_Max[TimeFrame_Max_LY]
//   X 轴时间段: Slicer_Time_Frame[TimeFrame_Min_LY] / Slicer_Time_Frame[TimeFrame_Max_LY]
//   比率类，不除汇率
// 数据类型: percent_1dp → 百分比，保留一位小数，不含正号
// ========================================
    VAR __LYTimeMin = SELECTEDVALUE(Slicer_Time_Frame_Min[TimeFrame_Min_LY])
    VAR __LYTimeMax = SELECTEDVALUE(Slicer_Time_Frame_Max[TimeFrame_Max_LY])
    VAR __LYCurrentTFMin = SELECTEDVALUE(Slicer_Time_Frame[TimeFrame_Min_LY])
    VAR __LYCurrentTFMax = SELECTEDVALUE(Slicer_Time_Frame[TimeFrame_Max_LY])
    // 分子：o2o_fulfillment_shipped_order_cnt（去年同期）
    VAR __Numerator =
        CALCULATE(
            SUM('a02_e2e_boss_performance_summary_d'[o2o_fulfillment_shipped_order_cnt]),
            'a02_e2e_boss_performance_summary_d'[calc_type] = "fulfillment",
            'a02_e2e_boss_performance_summary_d'[data_date] >= __LYTimeMin,
            'a02_e2e_boss_performance_summary_d'[data_date] <= __LYTimeMax,
            'a02_e2e_boss_performance_summary_d'[data_date] >= __LYCurrentTFMin,
            'a02_e2e_boss_performance_summary_d'[data_date] <= __LYCurrentTFMax
        )
    // 分母：o2o_fulfillment_request_order_cnt（去年同期）
    VAR __Denominator =
        CALCULATE(
            SUM('a02_e2e_boss_performance_summary_d'[o2o_fulfillment_request_order_cnt]),
            'a02_e2e_boss_performance_summary_d'[calc_type] = "fulfillment",
            'a02_e2e_boss_performance_summary_d'[data_date] >= __LYTimeMin,
            'a02_e2e_boss_performance_summary_d'[data_date] <= __LYTimeMax,
            'a02_e2e_boss_performance_summary_d'[data_date] >= __LYCurrentTFMin,
            'a02_e2e_boss_performance_summary_d'[data_date] <= __LYCurrentTFMax
        )
    RETURN DIVIDE(__Numerator, __Denominator)
```

### 4.17 LY Fulfillment% Display

```dax
LY Fulfillment% Display =
// ========================================
// 度量值: LY Fulfillment% Display
// Display Folder: PB Location
// 用途: LY O2O订单履约率 格式化显示
// 依赖: [LY Fulfillment% Value]
// 格式类型: percent_1dp → #,##0.0%
// ========================================
    VAR __Value = [LY Fulfillment% Value]
    RETURN
        IF(ISBLANK(__Value), "-", FORMAT(__Value, "#,##0.0%"))
```

---

## 子模块三：BOSS Unfulfillment - Unfulfilled Order by Region

> 不按 timeframe 聚合，仅按全局时间范围筛选
> 图例/分组 = store_region 或 store_type（直接拉取 t01_o2o_fulfillment_order_detail_d 表字段）
> 数据底表: t01_o2o_fulfillment_order_detail_d
> 时间字段: dt（PBI 中已转换为 date 类型，对应 data_date）
> Unfulfilled Order Scope: failure_remark 不为空的记录（PBI 上实现，四个子分类各自按 failure_remark 值筛选）

### 4.18 Rejected Order by Store Value

```dax
Rejected Order by Store Value =
// ========================================
// 度量值: Rejected Order by Store Value
// Display Folder: PB Location
// 用途: O2O失败订单数 - 门店拒绝接单分类，用于柱形图 Y 轴
// 口径来源: PB Location.md 子模块三 - Unfulfilled Order
// 计算公式: COUNTROWS(按 failure_remark 筛选后的订单去重)
//   对 order_code 去重计数
// 筛选条件:
//   - failure_remark in ("门店拒绝接单", "门店接单后取消配货")
//   - dt ∈ [__TimeMin, __TimeMax]（全局时间范围）
//   - store_region/store_type 由视觉对象图例自动传递
// 数据类型: integer → 千分位整数
// 格式: #,##0
// ========================================
    VAR __TimeMin = SELECTEDVALUE(Slicer_Time_Frame_Min[TimeFrame_Min])
    VAR __TimeMax = SELECTEDVALUE(Slicer_Time_Frame_Max[TimeFrame_Max])
    VAR __Result =
        CALCULATE(
            DISTINCTCOUNT('t01_o2o_fulfillment_order_detail_d'[order_code]),
            't01_o2o_fulfillment_order_detail_d'[failure_remark] IN { "门店拒绝接单", "门店接单后取消配货" },
            't01_o2o_fulfillment_order_detail_d'[dt] >= __TimeMin,
            't01_o2o_fulfillment_order_detail_d'[dt] <= __TimeMax
        )
    RETURN __Result
```

### 4.19 Rejected Order by Store Display

```dax
Rejected Order by Store Display =
// ========================================
// 度量值: Rejected Order by Store Display
// Display Folder: PB Location
// 用途: O2O失败订单数 - 门店拒绝接单 格式化显示
// 依赖: [Rejected Order by Store Value]
// 格式类型: integer → #,##0
// ========================================
    VAR __Value = [Rejected Order by Store Value]
    RETURN
        IF(ISBLANK(__Value), "-", FORMAT(__Value, "#,##0"))
```

### 4.20 Cancelled Order by Overdue Value

```dax
Cancelled Order by Overdue Value =
// ========================================
// 度量值: Cancelled Order by Overdue Value
// Display Folder: PB Location
// 用途: O2O失败订单数 - 超时分类，用于柱形图 Y 轴
// 口径来源: PB Location.md 子模块三 - Unfulfilled Order
// 计算公式: DISTINCTCOUNT(order_code)
// 筛选条件:
//   - failure_remark in ("待接单超时", "门店接单后超时未处理", "接单超时")
//   - dt ∈ [__TimeMin, __TimeMax]（全局时间范围）
// 数据类型: integer → 千分位整数
// ========================================
    VAR __TimeMin = SELECTEDVALUE(Slicer_Time_Frame_Min[TimeFrame_Min])
    VAR __TimeMax = SELECTEDVALUE(Slicer_Time_Frame_Max[TimeFrame_Max])
    VAR __Result =
        CALCULATE(
            DISTINCTCOUNT('t01_o2o_fulfillment_order_detail_d'[order_code]),
            't01_o2o_fulfillment_order_detail_d'[failure_remark] IN { "待接单超时", "门店接单后超时未处理", "接单超时" },
            't01_o2o_fulfillment_order_detail_d'[dt] >= __TimeMin,
            't01_o2o_fulfillment_order_detail_d'[dt] <= __TimeMax
        )
    RETURN __Result
```

### 4.21 Cancelled Order by Overdue Display

```dax
Cancelled Order by Overdue Display =
// ========================================
// 度量值: Cancelled Order by Overdue Display
// Display Folder: PB Location
// 用途: O2O失败订单数 - 超时 格式化显示
// 依赖: [Cancelled Order by Overdue Value]
// 格式类型: integer → #,##0
// ========================================
    VAR __Value = [Cancelled Order by Overdue Value]
    RETURN
        IF(ISBLANK(__Value), "-", FORMAT(__Value, "#,##0"))
```

### 4.22 Cancelled Order by Customer Value

```dax
Cancelled Order by Customer Value =
// ========================================
// 度量值: Cancelled Order by Customer Value
// Display Folder: PB Location
// 用途: O2O失败订单数 - 顾客取消分类，用于柱形图 Y 轴
// 口径来源: PB Location.md 子模块三 - Unfulfilled Order
// 计算公式: DISTINCTCOUNT(order_code)
// 筛选条件:
//   - failure_remark in ("顾客取消订单", "消费者取消")
//   - dt ∈ [__TimeMin, __TimeMax]（全局时间范围）
// 数据类型: integer → 千分位整数
// ========================================
    VAR __TimeMin = SELECTEDVALUE(Slicer_Time_Frame_Min[TimeFrame_Min])
    VAR __TimeMax = SELECTEDVALUE(Slicer_Time_Frame_Max[TimeFrame_Max])
    VAR __Result =
        CALCULATE(
            DISTINCTCOUNT('t01_o2o_fulfillment_order_detail_d'[order_code]),
            't01_o2o_fulfillment_order_detail_d'[failure_remark] IN { "顾客取消订单", "消费者取消" },
            't01_o2o_fulfillment_order_detail_d'[dt] >= __TimeMin,
            't01_o2o_fulfillment_order_detail_d'[dt] <= __TimeMax
        )
    RETURN __Result
```

### 4.23 Cancelled Order by Customer Display

```dax
Cancelled Order by Customer Display =
// ========================================
// 度量值: Cancelled Order by Customer Display
// Display Folder: PB Location
// 用途: O2O失败订单数 - 顾客取消 格式化显示
// 依赖: [Cancelled Order by Customer Value]
// 格式类型: integer → #,##0
// ========================================
    VAR __Value = [Cancelled Order by Customer Value]
    RETURN
        IF(ISBLANK(__Value), "-", FORMAT(__Value, "#,##0"))
```

### 4.24 Cancelled Order by Other Value

```dax
Cancelled Order by Other Value =
// ========================================
// 度量值: Cancelled Order by Other Value
// Display Folder: PB Location
// 用途: O2O失败订单数 - 其他原因分类，用于柱形图 Y 轴
// 口径来源: PB Location.md 子模块三 - Unfulfilled Order
// 计算公式: DISTINCTCOUNT(order_code)
// 筛选条件:
//   - failure_remark NOT IN ("门店拒绝接单", "门店接单后取消配货", "待接单超时",
//     "门店接单后超时未处理", "接单超时", "顾客取消订单", "消费者取消")
//   - 即排除以上三类后，failure_remark 不为空的所有其他原因
//   - dt ∈ [__TimeMin, __TimeMax]（全局时间范围）
// 数据类型: integer → 千分位整数
// ========================================
    VAR __TimeMin = SELECTEDVALUE(Slicer_Time_Frame_Min[TimeFrame_Min])
    VAR __TimeMax = SELECTEDVALUE(Slicer_Time_Frame_Max[TimeFrame_Max])
    VAR __Result =
        CALCULATE(
            DISTINCTCOUNT('t01_o2o_fulfillment_order_detail_d'[order_code]),
            NOT 't01_o2o_fulfillment_order_detail_d'[failure_remark] IN {
                "门店拒绝接单", "门店接单后取消配货",
                "待接单超时", "门店接单后超时未处理", "接单超时",
                "顾客取消订单", "消费者取消"
            },
            't01_o2o_fulfillment_order_detail_d'[dt] >= __TimeMin,
            't01_o2o_fulfillment_order_detail_d'[dt] <= __TimeMax
        )
    RETURN __Result
```

### 4.25 Cancelled Order by Other Display

```dax
Cancelled Order by Other Display =
// ========================================
// 度量值: Cancelled Order by Other Display
// Display Folder: PB Location
// 用途: O2O失败订单数 - 其他原因 格式化显示
// 依赖: [Cancelled Order by Other Value]
// 格式类型: integer → #,##0
// ========================================
    VAR __Value = [Cancelled Order by Other Value]
    RETURN
        IF(ISBLANK(__Value), "-", FORMAT(__Value, "#,##0"))
```

### 4.26 Rejected Order Share by Store Value

```dax
Rejected Order Share by Store Value =
// ========================================
// 度量值: Rejected Order Share by Store Value
// Display Folder: PB Location
// 用途: 门店拒绝接单订单数占所有失败订单数的比例
// 口径来源: PB Location.md 子模块三 - Unfulfilled Order Share
// 计算公式: [Rejected Order by Store Value] / 四类之和
//   分母使用四个指标相加，不使用 REMOVEFILTERS 函数
// 数据类型: percent_1dp → 百分比，保留一位小数，不含正号
// ========================================
    VAR __Numerator = [Rejected Order by Store Value]
    VAR __Denominator =
        [Rejected Order by Store Value]
        + [Cancelled Order by Overdue Value]
        + [Cancelled Order by Customer Value]
        + [Cancelled Order by Other Value]
    RETURN DIVIDE(__Numerator, __Denominator)
```

### 4.27 Rejected Order Share by Store Display

```dax
Rejected Order Share by Store Display =
// ========================================
// 度量值: Rejected Order Share by Store Display
// Display Folder: PB Location
// 用途: 门店拒绝接单占比 格式化显示
// 依赖: [Rejected Order Share by Store Value]
// 格式类型: percent_1dp → #,##0.0%
// ========================================
    VAR __Value = [Rejected Order Share by Store Value]
    RETURN
        IF(ISBLANK(__Value), "-", FORMAT(__Value, "#,##0.0%"))
```

### 4.28 Cancelled Order Share by Overdue Value

```dax
Cancelled Order Share by Overdue Value =
// ========================================
// 度量值: Cancelled Order Share by Overdue Value
// Display Folder: PB Location
// 用途: 超时订单数占所有失败订单数的比例
// 口径来源: PB Location.md 子模块三 - Unfulfilled Order Share
// 计算公式: [Cancelled Order by Overdue Value] / 四类之和
//   分母使用四个指标相加，不使用 REMOVEFILTERS 函数
// 数据类型: percent_1dp → 百分比，保留一位小数，不含正号
// ========================================
    VAR __Numerator = [Cancelled Order by Overdue Value]
    VAR __Denominator =
        [Rejected Order by Store Value]
        + [Cancelled Order by Overdue Value]
        + [Cancelled Order by Customer Value]
        + [Cancelled Order by Other Value]
    RETURN DIVIDE(__Numerator, __Denominator)
```

### 4.29 Cancelled Order Share by Overdue Display

```dax
Cancelled Order Share by Overdue Display =
// ========================================
// 度量值: Cancelled Order Share by Overdue Display
// Display Folder: PB Location
// 用途: 超时订单占比 格式化显示
// 依赖: [Cancelled Order Share by Overdue Value]
// 格式类型: percent_1dp → #,##0.0%
// ========================================
    VAR __Value = [Cancelled Order Share by Overdue Value]
    RETURN
        IF(ISBLANK(__Value), "-", FORMAT(__Value, "#,##0.0%"))
```

### 4.30 Cancelled Order Share by Customer Value

```dax
Cancelled Order Share by Customer Value =
// ========================================
// 度量值: Cancelled Order Share by Customer Value
// Display Folder: PB Location
// 用途: 顾客取消订单数占所有失败订单数的比例
// 口径来源: PB Location.md 子模块三 - Unfulfilled Order Share
// 计算公式: [Cancelled Order by Customer Value] / 四类之和
//   分母使用四个指标相加，不使用 REMOVEFILTERS 函数
// 数据类型: percent_1dp → 百分比，保留一位小数，不含正号
// ========================================
    VAR __Numerator = [Cancelled Order by Customer Value]
    VAR __Denominator =
        [Rejected Order by Store Value]
        + [Cancelled Order by Overdue Value]
        + [Cancelled Order by Customer Value]
        + [Cancelled Order by Other Value]
    RETURN DIVIDE(__Numerator, __Denominator)
```

### 4.31 Cancelled Order Share by Customer Display

```dax
Cancelled Order Share by Customer Display =
// ========================================
// 度量值: Cancelled Order Share by Customer Display
// Display Folder: PB Location
// 用途: 顾客取消订单占比 格式化显示
// 依赖: [Cancelled Order Share by Customer Value]
// 格式类型: percent_1dp → #,##0.0%
// ========================================
    VAR __Value = [Cancelled Order Share by Customer Value]
    RETURN
        IF(ISBLANK(__Value), "-", FORMAT(__Value, "#,##0.0%"))
```

### 4.32 Cancelled Order Share by Other Value

```dax
Cancelled Order Share by Other Value =
// ========================================
// 度量值: Cancelled Order Share by Other Value
// Display Folder: PB Location
// 用途: 其他原因失败订单数占所有失败订单数的比例
// 口径来源: PB Location.md 子模块三 - Unfulfilled Order Share
// 计算公式: [Cancelled Order by Other Value] / 四类之和
//   分母使用四个指标相加，不使用 REMOVEFILTERS 函数
// 数据类型: percent_1dp → 百分比，保留一位小数，不含正号
// ========================================
    VAR __Numerator = [Cancelled Order by Other Value]
    VAR __Denominator =
        [Rejected Order by Store Value]
        + [Cancelled Order by Overdue Value]
        + [Cancelled Order by Customer Value]
        + [Cancelled Order by Other Value]
    RETURN DIVIDE(__Numerator, __Denominator)
```

### 4.33 Cancelled Order Share by Other Display

```dax
Cancelled Order Share by Other Display =
// ========================================
// 度量值: Cancelled Order Share by Other Display
// Display Folder: PB Location
// 用途: 其他原因失败订单占比 格式化显示
// 依赖: [Cancelled Order Share by Other Value]
// 格式类型: percent_1dp → #,##0.0%
// ========================================
    VAR __Value = [Cancelled Order Share by Other Value]
    RETURN
        IF(ISBLANK(__Value), "-", FORMAT(__Value, "#,##0.0%"))
```

### 4.34 Region Unfulfilled Order Tooltip Display

```dax
Region Unfulfilled Order Tooltip Display = 
// ========================================
// 度量值: Region Unfulfilled Order Tooltip Display
// Display Folder: PB Location
// 用途: Unfulfilled Order 工具提示
// 口径来源: PB Location.md 子模块三 - Unfulfilled Order Tooltip Display
// 格式:
//   Region：{Region}
//   Rejected By Store：{Rejected Order by Store} 占比：{Rejected Order Share by Store}
//   Cancelled By Overdue：{Cancelled Order by Overdue} 占比：{Cancelled Order Share by Overdue}
//   Cancelled By Customer：{Cancelled Order by Customer} 占比：{Cancelled Order Share by Customer}
//   Cancelled By Other：{Cancelled Order by Other} 占比：{Cancelled Order Share by Other}
//   共五行，换行拼接
// ========================================
    VAR __Region = SELECTEDVALUE('t01_o2o_fulfillment_order_detail_d'[order_type_cd])
    VAR __Line1 = "Region：" & IF(ISBLANK(__Region), "-", __Region)
    VAR __Line2 = "Rejected By Store：" & [Rejected Order by Store Display] & " ：" & [Rejected Order Share by Store Display]
    VAR __Line3 = "Cancelled By Overdue：" & [Cancelled Order by Overdue Display] & " ：" & [Cancelled Order Share by Overdue Display]
    VAR __Line4 = "Cancelled By Customer：" & [Cancelled Order by Customer Display] & " ：" & [Cancelled Order Share by Customer Display]
    VAR __Line5 = "Cancelled By Other：" & [Cancelled Order by Other Display] & " ：" & [Cancelled Order Share by Other Display]
    RETURN
        __Line1 & UNICHAR(10) & __Line2 & UNICHAR(10) & __Line3 & UNICHAR(10) & __Line4 & UNICHAR(10) & __Line5
```

### 4.35 Store Type Unfulfilled Order Tooltip Display

```dax
Store Type Unfulfilled Order Tooltip Display = 
// ========================================
// 度量值: Store Type Unfulfilled Order Tooltip Display
// Display Folder: PB Location
// 用途: Unfulfilled Order 工具提示
// 口径来源: PB Location.md 子模块三 - Unfulfilled Order Tooltip Display
// 格式:
//   Store Type：{Store Type}
//   Rejected By Store：{Rejected Order by Store} 占比：{Rejected Order Share by Store}
//   Cancelled By Overdue：{Cancelled Order by Overdue} 占比：{Cancelled Order Share by Overdue}
//   Cancelled By Customer：{Cancelled Order by Customer} 占比：{Cancelled Order Share by Customer}
//   Cancelled By Other：{Cancelled Order by Other} 占比：{Cancelled Order Share by Other}
//   共五行，换行拼接
// ========================================
    VAR __StoreType = SELECTEDVALUE('t01_o2o_fulfillment_order_detail_d'[order_type])
    VAR __Line1 = "Store Type：" & IF(ISBLANK(__StoreType), "-", __StoreType)
    VAR __Line2 = "Rejected By Store：" & [Rejected Order by Store Display] & " ：" & [Rejected Order Share by Store Display]
    VAR __Line3 = "Cancelled By Overdue：" & [Cancelled Order by Overdue Display] & " ：" & [Cancelled Order Share by Overdue Display]
    VAR __Line4 = "Cancelled By Customer：" & [Cancelled Order by Customer Display] & " ：" & [Cancelled Order Share by Customer Display]
    VAR __Line5 = "Cancelled By Other：" & [Cancelled Order by Other Display] & " ：" & [Cancelled Order Share by Other Display]
    RETURN
        __Line1 & UNICHAR(10) & __Line2 & UNICHAR(10) & __Line3 & UNICHAR(10) & __Line4 & UNICHAR(10) & __Line5
```

---

## 子模块四：BOSS Unfulfillment - Failed Request by Reason

> 不按 timeframe 聚合，仅按全局时间范围聚合
> 图例/分组 = store_region 或 store_type（直接拉取事实表字段）
> 数据底表: a02_e2e_boss_fulfillment_fail_reason_d
> Region 筛选器默认选中所有 region，数据展示所有 region 的总和

### 4.35 Failed Request Value

```dax
Failed Request Value =
// ========================================
// 度量值: Failed Request Value
// Display Folder: PB Location
// 用途: O2O门店订单失败次数，用于柱形图 Y 轴
// 口径来源: PB Location.md 子模块四 - Failed Request
// 计算公式: SUM(request_times)
// 筛选条件:
//   - data_date ∈ [__TimeMin, __TimeMax]（全局时间范围）
//   - store_region/store_type 由视觉对象图例自动传递
// 数据类型: integer → 千分位整数
// 格式: #,##0
// ========================================
    VAR __TimeMin = SELECTEDVALUE(Slicer_Time_Frame_Min[TimeFrame_Min])
    VAR __TimeMax = SELECTEDVALUE(Slicer_Time_Frame_Max[TimeFrame_Max])
    VAR __Result =
        CALCULATE(
            SUM('a02_e2e_boss_fulfillment_fail_reason_d'[request_times]),
            'a02_e2e_boss_fulfillment_fail_reason_d'[data_date] >= __TimeMin,
            'a02_e2e_boss_fulfillment_fail_reason_d'[data_date] <= __TimeMax
        )
    RETURN __Result
```

### 4.36 Failed Request Display

```dax
Failed Request Display =
// ========================================
// 度量值: Failed Request Display
// Display Folder: PB Location
// 用途: O2O门店订单失败次数 格式化显示
// 依赖: [Failed Request Value]
// 格式类型: integer → #,##0
// ========================================
    VAR __Value = [Failed Request Value]
    RETURN
        IF(ISBLANK(__Value), "-", FORMAT(__Value, "#,##0"))
```

### 4.37 Failed Request Ratio Value

```dax
Failed Request Ratio Value =
// ========================================
// 度量值: Failed Request Ratio Value
// Display Folder: PB Location
// 用途: 单个 failure_reason 维度占总失败次数的百分比
// 口径来源: PB Location.md 子模块四 - Failed Request (扩展)
// 计算公式: SUM(request_times) / 移除 failure_reason 后的 SUM(request_times)
// 筛选条件:
//   - data_date ∈ [__TimeMin, __TimeMax]（全局时间范围）
//   - store_region/store_type 由视觉对象图例自动传递
//   - 分母通过 REMOVEFILTERS 移除 failure_reason 维度影响
// 数据类型: decimal (0~1)
// ========================================
    VAR __TimeMin = SELECTEDVALUE(Slicer_Time_Frame_Min[TimeFrame_Min])
    VAR __TimeMax = SELECTEDVALUE(Slicer_Time_Frame_Max[TimeFrame_Max])
    // 分子: 当前 failure_reason 上下文下的失败次数
    VAR __Numerator =
        CALCULATE(
            SUM('a02_e2e_boss_fulfillment_fail_reason_d'[request_times]),
            'a02_e2e_boss_fulfillment_fail_reason_d'[data_date] >= __TimeMin,
            'a02_e2e_boss_fulfillment_fail_reason_d'[data_date] <= __TimeMax
        )
    // 分母: 移除 failure_reason 维度影响后的总失败次数
    VAR __Denominator =
        CALCULATE(
            SUM('a02_e2e_boss_fulfillment_fail_reason_d'[request_times]),
            'a02_e2e_boss_fulfillment_fail_reason_d'[data_date] >= __TimeMin,
            'a02_e2e_boss_fulfillment_fail_reason_d'[data_date] <= __TimeMax,
            REMOVEFILTERS('a02_e2e_boss_fulfillment_fail_reason_d'[failure_reason])
        )
    VAR __Result =
        DIVIDE(__Numerator, __Denominator, 0)
    RETURN __Result
```
### 4.38 Failed Request Ratio Display

```dax
Failed Request Ratio Display =
// ========================================
// 度量值: Failed Request Ratio Display
// Display Folder: PB Location
// 用途: 单个 failure_reason 占总失败次数的百分比 格式化显示
// 依赖: [Failed Request Ratio Value]
// 格式类型: decimal (0~1) → #,##0%
// ========================================
    VAR __Value = [Failed Request Ratio Value]
    RETURN
        IF(ISBLANK(__Value), "-", FORMAT(__Value, "#,##0%"))
```

---

## 5. 度量值清单与 Display Folder

| 序号 | 度量值名称 | Display Folder | 用途 | 子模块 |
|------|-----------|----------------|------|--------|
| 1 | IsTimeFrameVisible | PB Location | X 轴视觉对象级别筛选器 | 通用 |
| 2 | TY Shipped Order Qty Value | PB Location | 柱形图 Y 轴（本期订单量） | 一 |
| 3 | TY Shipped Order Qty Display | PB Location | 柱形图标签 | 一 |
| 4 | LY Shipped Order Qty Value | PB Location | 柱形图 Y 轴（去年同期订单量） | 一 |
| 5 | LY Shipped Order Qty Display | PB Location | 柱形图标签 | 一 |
| 6 | Shipped Order Qty YOY Value | PB Location | 柱形图 Y 轴（同比） | 一 |
| 7 | Shipped Order Qty YOY Display | PB Location | 柱形图标签 | 一 |
| 8 | TY Shipped Order Amt Value | PB Location | 柱形图 Y 轴（本期金额） | 一 |
| 9 | TY Shipped Order Amt Display | PB Location | 柱形图标签 | 一 |
| 10 | LY Shipped Order Amt Value | PB Location | 柱形图 Y 轴（去年同期金额） | 一 |
| 11 | LY Shipped Order Amt Display | PB Location | 柱形图标签 | 一 |
| 12 | Shipped Order Amt YOY Value | PB Location | 柱形图 Y 轴（同比） | 一 |
| 13 | Shipped Order Amt YOY Display | PB Location | 柱形图标签 | 一 |
| 14 | TY Fulfillment% Value | PB Location | 趋势图 Y 轴（本期履约率） | 二 |
| 15 | TY Fulfillment% Display | PB Location | 趋势图标签 | 二 |
| 16 | LY Fulfillment% Value | PB Location | 趋势图 Y 轴（去年同期履约率） | 二 |
| 17 | LY Fulfillment% Display | PB Location | 趋势图标签 | 二 |
| 18 | Rejected Order by Store Value | PB Location | 柱形图 Y 轴（门店拒绝接单） | 三 |
| 19 | Rejected Order by Store Display | PB Location | 柱形图标签 | 三 |
| 20 | Cancelled Order by Overdue Value | PB Location | 柱形图 Y 轴（超时） | 三 |
| 21 | Cancelled Order by Overdue Display | PB Location | 柱形图标签 | 三 |
| 22 | Cancelled Order by Customer Value | PB Location | 柱形图 Y 轴（顾客取消） | 三 |
| 23 | Cancelled Order by Customer Display | PB Location | 柱形图标签 | 三 |
| 24 | Cancelled Order by Other Value | PB Location | 柱形图 Y 轴（其他原因） | 三 |
| 25 | Cancelled Order by Other Display | PB Location | 柱形图标签 | 三 |
| 26 | Rejected Order Share by Store Value | PB Location | 柱形图 Y 轴（门店拒绝占比） | 三 |
| 27 | Rejected Order Share by Store Display | PB Location | 柱形图标签 | 三 |
| 28 | Cancelled Order Share by Overdue Value | PB Location | 柱形图 Y 轴（超时占比） | 三 |
| 29 | Cancelled Order Share by Overdue Display | PB Location | 柱形图标签 | 三 |
| 30 | Cancelled Order Share by Customer Value | PB Location | 柱形图 Y 轴（顾客取消占比） | 三 |
| 31 | Cancelled Order Share by Customer Display | PB Location | 柱形图标签 | 三 |
| 32 | Cancelled Order Share by Other Value | PB Location | 柱形图 Y 轴（其他原因占比） | 三 |
| 33 | Cancelled Order Share by Other Display | PB Location | 柱形图标签 | 三 |
| 34 | Unfulfilled Order Tooltip Display | PB Location | 工具提示 | 三 |
| 35 | Failed Request Value | PB Location | 柱形图 Y 轴（失败次数） | 四 |
| 36 | Failed Request Display | PB Location | 柱形图标签 | 四 |

---

## 6. 视觉对象配置

### 6.1 子模块一：柱形图（Fulfilled Order by Region/Store Type）

| 配置项 | 值 |
|--------|-----|
| X 轴 | Slicer_Time_Frame[TimeFrame_Value] |
| Y 轴 | [TY Shipped Order Qty Value] / [LY Shipped Order Qty Value] / [TY Shipped Order Amt Value] / [LY Shipped Order Amt Value] |
| 图例 | 事实表[store_region] 或 [store_type]（直接拉取） |
| 数据标签 | 对应 [* Display] 度量 |
| 视觉对象级别筛选器 | Slicer_Time_Frame 表上 [IsTimeFrameVisible] = 1 |
| 全局筛选器 | Slicer_Time_Frame_Min/Max、Slicer_Currency_Selection |

### 6.2 子模块二：柱形图/趋势图（Fulfillment% Trend）

| 配置项 | 值 |
|--------|-----|
| X 轴 | Slicer_Time_Frame[TimeFrame_Value] |
| Y 轴 | [TY Fulfillment% Value] / [LY Fulfillment% Value] |
| 折线/图例 | 事实表[store_region] 或 [store_type]（直接拉取） |
| 数据标签 | 对应 [* Display] 度量 |
| 视觉对象级别筛选器 | Slicer_Time_Frame 表上 [IsTimeFrameVisible] = 1 |
| 全局筛选器 | Slicer_Time_Frame_Min/Max |

### 6.3 子模块三：柱形图（Unfulfilled Order by Region）

| 配置项 | 值 |
|--------|-----|
| Y 轴 | [Rejected Order by Store Value] / [Cancelled Order by Overdue Value] / [Cancelled Order by Customer Value] / [Cancelled Order by Other Value] |
| 图例 | 事实表[store_region] 或 [store_type]（直接拉取） |
| 数据标签 | 对应 [* Display] 度量 |
| Tooltip | [Unfulfilled Order Tooltip Display] |
| 全局筛选器 | Slicer_Time_Frame_Min/Max |

> 不按 timeframe 聚合，不使用 X 轴 = Slicer_Time_Frame

### 6.4 子模块四：柱形图（Failed Request by Reason）

| 配置项 | 值 |
|--------|-----|
| Y 轴 | [Failed Request Value] |
| 图例 | 事实表[store_region] 或 [store_type]（直接拉取） |
| 数据标签 | [Failed Request Display] |
| 全局筛选器 | Slicer_Time_Frame_Min/Max |

> 不按 timeframe 聚合，不使用 X 轴 = Slicer_Time_Frame

---

## 7. 验证方法

### 7.1 子模块一验证 SQL

```sql
-- TY Shipped Order Qty（某月，所有 region 汇总）
-- 假设 TimeFrame = 2026-10, TimeFrame_Min=2025-12-28, TimeFrame_Max=2026-01-24
SELECT SUM(o2o_fulfillment_shipped_order_cnt) AS ShippedOrderQty_TY
FROM a02_e2e_boss_performance_summary_d
WHERE calc_type = 'fulfillment'
  AND data_date BETWEEN '2025-12-28' AND '2026-01-24';

-- LY Shipped Order Qty（去年同编号月）
-- LY 日期范围直接来自日期表 ly_timeframe_min / ly_timeframe_max
SELECT SUM(o2o_fulfillment_shipped_order_cnt) AS ShippedOrderQty_LY
FROM a02_e2e_boss_performance_summary_d
WHERE calc_type = 'fulfillment'
  AND data_date BETWEEN '__LYTimeMin' AND '__LYTimeMax';

-- TY Shipped Order Amt（某月）
SELECT SUM(o2o_fulfillment_shipped_sales_amt) AS ShippedOrderAmt_TY
FROM a02_e2e_boss_performance_summary_d
WHERE calc_type = 'fulfillment'
  AND data_date BETWEEN '2025-12-28' AND '2026-01-24';
```

### 7.2 子模块二验证 SQL

```sql
-- TY Fulfillment%（某月）
SELECT
  SUM(o2o_fulfillment_shipped_order_cnt) / SUM(o2o_fulfillment_request_order_cnt) AS FulfillmentPct_TY
FROM a02_e2e_boss_performance_summary_d
WHERE calc_type = 'fulfillment'
  AND data_date BETWEEN '2025-12-28' AND '2026-01-24';
```

### 7.3 子模块三验证 SQL

```sql
-- Rejected Order by Store
SELECT COUNT(DISTINCT order_code) AS RejectedByStore
FROM t01_o2o_fulfillment_order_detail_d
WHERE failure_remark IN ('门店拒绝接单', '门店接单后取消配货')
  AND dt BETWEEN '__TimeMin' AND '__TimeMax';

-- Cancelled Order by Overdue
SELECT COUNT(DISTINCT order_code) AS CancelledByOverdue
FROM t01_o2o_fulfillment_order_detail_d
WHERE failure_remark IN ('待接单超时', '门店接单后超时未处理', '接单超时')
  AND dt BETWEEN '__TimeMin' AND '__TimeMax';

-- Cancelled Order by Customer
SELECT COUNT(DISTINCT order_code) AS CancelledByCustomer
FROM t01_o2o_fulfillment_order_detail_d
WHERE failure_remark IN ('顾客取消订单', '消费者取消')
  AND dt BETWEEN '__TimeMin' AND '__TimeMax';

-- Cancelled Order by Other
SELECT COUNT(DISTINCT order_code) AS CancelledByOther
FROM t01_o2o_fulfillment_order_detail_d
WHERE failure_remark NOT IN (
    '门店拒绝接单', '门店接单后取消配货',
    '待接单超时', '门店接单后超时未处理', '接单超时',
    '顾客取消订单', '消费者取消'
  )
  AND dt BETWEEN '__TimeMin' AND '__TimeMax';

-- Rejected Order Share by Store
-- 分母 = 四类之和（不使用 REMOVEFILTERS）
-- RejectedByStore / (RejectedByStore + CancelledByOverdue + CancelledByCustomer + CancelledByOther)
```

### 7.4 子模块四验证 SQL

```sql
-- Failed Request
SELECT SUM(request_times) AS FailedRequest
FROM a02_e2e_boss_fulfillment_fail_reason_d
WHERE data_date BETWEEN '__TimeMin' AND '__TimeMax';
```

---

## 8. 注意事项

1. **粒度联动假设**：Slicer_Time_Frame_Min 和 Slicer_Time_Frame_Max 切片器应受同一粒度选择器联动筛选（保持同粒度）。若两者粒度不一致，IsTimeFrameVisible 返回 0 隐藏所有柱子。

2. **LY 财历映射**：周/月/季/年粒度按财年定义，LY 采用财历映射（直接读取日期表内置 TimeFrame_Min_LY / TimeFrame_Max_LY 字段），不使用 EDATE -12。日期表需包含至少2年历史数据。

3. **子模块三数据底表差异**：t01_o2o_fulfillment_order_detail_d 表的时间字段在 PBI 模型中为 `dt`（已转换为 date 类型），而非 `data_date`。该表不含 calc_type 字段，通过 failure_remark 分类逻辑界定 Unfulfilled Order Scope。

4. **子模块三分母计算**：Unfulfilled Order Share 分母使用四个指标相加，不使用 REMOVEFILTERS 函数，确保与口径文档一致。

5. **分组维度传递**：store_region / store_type 直接从数据表字段拉取到视觉对象图例/轴，DAX 度量值无需显式处理分组逻辑。

6. **汇率换算**：金额类指标（Shipped Order Amt）÷ Currency_ExchangeRate；比率类（Fulfillment%）分子分母同币种相除自动抵消，不除汇率。

7. **全局筛选冗余性**：柱形图/趋势图中 X 轴时间段筛选是全局范围筛选的子集，全局筛选冗余但保留，防止 X 轴超出全局范围时的异常显示。
