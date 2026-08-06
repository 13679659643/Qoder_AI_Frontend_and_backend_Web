# Power BI 解决方案 — PB Location：Sales 五指标 Value/Display 度量

> status: ready
> created: 2026-08-06
> type: 度量值开发 + 可视化构建
> 口径来源: 口径文档/Overview.md 子模块一 BOSS Core KPI - Sales 分组
> 参考实现: Performance By Location/PB_Location_Trend.md（Value/Display 范式）
> 源度量: Overview/BOSS Core KPI/Overview_KPIs_ms.md（矩阵 SWITCH 路由版本）

---

## 1. 需求理解

为 Performance By Location 页面输出 Sales 分组下五个指标的独立度量值（Value + Display），用于表格视觉对象：

| 指标 | 中文名 | 分类 | calc_type | 底表字段 |
|------|--------|------|-----------|---------|
| SLS | O2O销售净额 | 金额类 | payment | o2o_net_sales_amt |
| Demand SLS | O2O退前销售额 | 金额类 | payment | o2o_sales_amt |
| SLS Penetration | O2O销售渗透率 | 比率类 | payment | o2o_sales_amt / sales_amt |
| Return | O2O退货金额 | 金额类 | payment | o2o_return_amt |
| Return% | O2O退货率（金额） | 比率类 | payment | o2o_return_amt / o2o_sales_amt |

**每个指标输出 6 个度量值**（Actual / LY / vs LY 各一对 Value+Display），共 30 个度量值。

**核心设计原则**：
- 无需矩阵 SWITCH 路由分发，每个指标独立编写 Value/Display 度量
- 表格视觉对象：用户依次拉取单个度量值，分组维度（store_region/store_type 等）直接拉取事实表字段，天然形成筛选与分组
- 仅用全局时间范围筛选（Slicer_Time_Frame_Min/Max），无 X 轴时间段双层筛选
- LY 采用财历映射（直接读取日期表内置 TimeFrame_Min_LY / TimeFrame_Max_LY 字段）
- 不保留 Overview_KPIs_ms.md 中的 StoreGroup_ID → store_name 筛选逻辑
- 一切口径以口径文档 Overview.md 子模块一 Sales 分组为准

---

## 2. 现状分析

### 2.1 数据底表

| 对象 | 名称 | 出处 |
|------|------|------|
| 事实表 | a02_e2e_boss_performance_summary_d | Overview_KPIs_ms.md 2.1 |
| 关键字段 | data_date, store_name, calc_type, o2o_net_sales_amt, o2o_sales_amt, sales_amt, o2o_return_amt | Overview_KPIs_ms.md 2.1 |

### 2.2 维度表清单

| 维度表 | 类型 | 连接方式 |
|--------|------|---------|
| Slicer_Time_Frame_Min | 断开维度 | 起始切片器；SELECTEDVALUE 读取 TimeFrame_Min / TimeFrame_Min_LY |
| Slicer_Time_Frame_Max | 断开维度 | 结束切片器；SELECTEDVALUE 读取 TimeFrame_Max / TimeFrame_Max_LY |
| Slicer_Currency_Selection | 断开维度 | SELECTEDVALUE 读取 Currency_ExchangeRate / Currency_Symbol |

> 不使用 Slicer_Time_Frame（X 轴维度），不使用 Dim_RowKPIs_BossCoreKPI_Overview / Dim_ColKPIs_BossCoreKPI_Overview（矩阵行列维度）。

---

## 3. 方案设计

### 3.1 筛选上下文

| 筛选器 | 作用方式 | DAX 处理 |
|--------|---------|---------|
| Slicer_Time_Frame_Min | 断开维度，SELECTEDVALUE 读取 TimeFrame_Min | `data_date >= __TimeMin` |
| Slicer_Time_Frame_Max | 断开维度，SELECTEDVALUE 读取 TimeFrame_Max | `data_date <= __TimeMax` |
| Slicer_Currency_Selection | 断开维度，SELECTEDVALUE 读取 Currency_ExchangeRate, Currency_Symbol | 金额类指标 ÷ Currency_ExchangeRate |
| 事实表分组字段（store_region/store_type 等） | 表格行/列直接拉取，模型自动传递筛选 | DAX 无需显式处理 |

> calc_type 在 Sales 分组下固定为 "payment"，直接硬编码，不再通过 KPI_CalcType 读取。

### 3.2 时间偏移规则（LY — 财历映射）

直接读取日期表内置 LY 字段：
- 全局 LY 起始日：`Slicer_Time_Frame_Min[TimeFrame_Min_LY]`
- 全局 LY 结束日：`Slicer_Time_Frame_Max[TimeFrame_Max_LY]`
- 无需 EDATE -12 或 Key 偏移计算

### 3.3 vs LY 派生计算分类

| KPI 分类 | vs LY 计算方式 | 格式 | 展示示例 |
|---------|---------------|------|---------|
| 金额类（SLS / Demand SLS / Return） | 今年 / 去年 − 1 | percent_1dp | 14.5% |
| 比率类（SLS Penetration / Return%） | 今年 − 去年（差值，×10000 转 bp） | delta_bp | +120bp |

### 3.4 格式规范

| 格式类型 | 格式串 | 示例 | 适用度量 |
|---------|--------|------|---------|
| currency | `__CurrencySymbol & FORMAT(__Value, "#,##0")` | ¥1,234 | SLS / Demand SLS / Return 的 Actual、LY |
| percent_1dp | `#,##0.0%` | 14.5% | SLS Penetration / Return% 的 Actual、LY；金额类 vs LY |
| delta_bp | `IF(ROUND(__Value*10000,0)>0,"+","") & FORMAT(__Value*10000, "#,##0bp;-#,##0bp;0bp")` | +120bp | 比率类 vs LY |

---

## 4. 度量值实现

## 指标一：SLS（O2O销售净额）

> 金额类 · calc_type = "payment" · SUM(o2o_net_sales_amt)

### 4.1 SLS Actual Value

```dax
SLS Actual Value =
// ========================================
// 度量值: SLS Actual Value
// Display Folder: PB Location
// 用途: TY O2O销售净额 Act 值
// 口径来源: Overview.md 子模块一 - SLS
// 计算公式: SUM(o2o_net_sales_amt)
// 筛选条件:
//   - calc_type = "payment"
//   - data_date ∈ [__TimeMin, __TimeMax]（全局时间范围）
//   - 分组维度由表格行/列直接拉取事实表字段自动传递
//   - 金额类指标 ÷ __FXRate（汇率换算）
// 数据类型: currency → 货币符号由币种切片器决定，千分位整数
// ========================================
    VAR __TimeMin = SELECTEDVALUE(Slicer_Time_Frame_Min[TimeFrame_Min])
    VAR __TimeMax = SELECTEDVALUE(Slicer_Time_Frame_Max[TimeFrame_Max])
    VAR __FXRate = SELECTEDVALUE('Slicer_Currency_Selection'[Currency_ExchangeRate], 1)
    VAR __Result =
        CALCULATE(
            SUM('a02_e2e_boss_performance_summary_d'[o2o_net_sales_amt]),
            'a02_e2e_boss_performance_summary_d'[calc_type] = "payment",
            'a02_e2e_boss_performance_summary_d'[data_date] >= __TimeMin,
            'a02_e2e_boss_performance_summary_d'[data_date] <= __TimeMax
        )
    RETURN DIVIDE(__Result, __FXRate)
```

### 4.2 SLS Actual Display

```dax
SLS Actual Display =
// ========================================
// 度量值: SLS Actual Display
// Display Folder: PB Location
// 用途: TY O2O销售净额 格式化显示
// 依赖: [SLS Actual Value], Slicer_Currency_Selection
// 格式类型: currency → __CurrencySymbol & FORMAT(__Value, "#,##0")
// ========================================
    VAR __Value = [SLS Actual Value]
    VAR __CurrencySymbol = SELECTEDVALUE('Slicer_Currency_Selection'[Currency_Symbol], "¥")
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            __CurrencySymbol & FORMAT(__Value, "#,##0")
        )
```

### 4.3 SLS LY Value（财历映射）

```dax
SLS LY Value =
// ========================================
// 度量值: SLS LY Value
// Display Folder: PB Location
// 用途: LY O2O销售净额（去年同期）
// 口径来源: Overview.md 子模块一 - SLS LY
// 计算公式: 去年同期 SUM(o2o_net_sales_amt)
// 时间偏移: 财历映射（直接读取日期表内置 LY 字段）
//   全局范围: Slicer_Time_Frame_Min[TimeFrame_Min_LY] / Slicer_Time_Frame_Max[TimeFrame_Max_LY]
//   金额类指标 ÷ __FXRate（汇率换算）
// 数据类型: currency → 货币符号由币种切片器决定，千分位整数
// ========================================
    VAR __LYTimeMin = SELECTEDVALUE(Slicer_Time_Frame_Min[TimeFrame_Min_LY])
    VAR __LYTimeMax = SELECTEDVALUE(Slicer_Time_Frame_Max[TimeFrame_Max_LY])
    VAR __FXRate = SELECTEDVALUE('Slicer_Currency_Selection'[Currency_ExchangeRate], 1)
    VAR __Result =
        CALCULATE(
            SUM('a02_e2e_boss_performance_summary_d'[o2o_net_sales_amt]),
            'a02_e2e_boss_performance_summary_d'[calc_type] = "payment",
            'a02_e2e_boss_performance_summary_d'[data_date] >= __LYTimeMin,
            'a02_e2e_boss_performance_summary_d'[data_date] <= __LYTimeMax
        )
    RETURN DIVIDE(__Result, __FXRate)
```

### 4.4 SLS LY Display

```dax
SLS LY Display =
// ========================================
// 度量值: SLS LY Display
// Display Folder: PB Location
// 用途: LY O2O销售净额 格式化显示
// 依赖: [SLS LY Value], Slicer_Currency_Selection
// 格式类型: currency → __CurrencySymbol & FORMAT(__Value, "#,##0")
// ========================================
    VAR __Value = [SLS LY Value]
    VAR __CurrencySymbol = SELECTEDVALUE('Slicer_Currency_Selection'[Currency_Symbol], "¥")
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            __CurrencySymbol & FORMAT(__Value, "#,##0")
        )
```

### 4.5 SLS vs LY Value

```dax
SLS vs LY Value =
// ========================================
// 度量值: SLS vs LY Value
// Display Folder: PB Location
// 用途: O2O销售净额同比（今年/去年-1）
// 口径来源: Overview.md 子模块一 - SLS vs LY
// 计算公式: [SLS Actual Value] / [SLS LY Value] - 1
// 派生类型: 金额类 → percent_1dp（今年/去年-1）
// 注: vs LY 同比值不受 Currency 切片器影响（汇率在相除时自动抵消）
// 数据类型: percent_1dp → 百分比，保留一位小数，不含正号
// ========================================
    VAR __TY = [SLS Actual Value]
    VAR __LY = [SLS LY Value]
    RETURN
        IF(
            ISBLANK(__LY) || __LY = 0,
            BLANK(),
            DIVIDE(__TY, __LY) - 1
        )
```

### 4.6 SLS vs LY Display

```dax
SLS vs LY Display =
// ========================================
// 度量值: SLS vs LY Display
// Display Folder: PB Location
// 用途: O2O销售净额同比 格式化显示
// 依赖: [SLS vs LY Value]
// 格式类型: percent_1dp → #,##0.0%
// ========================================
    VAR __Value = [SLS vs LY Value]
    RETURN
        IF(ISBLANK(__Value), "-", FORMAT(__Value, "#,##0.0%"))
```

---

## 指标二：Demand SLS（O2O退前销售额）

> 金额类 · calc_type = "payment" · SUM(o2o_sales_amt)

### 4.7 Demand SLS Actual Value

```dax
Demand SLS Actual Value =
// ========================================
// 度量值: Demand SLS Actual Value
// Display Folder: PB Location
// 用途: TY O2O退前销售额 Act 值
// 口径来源: Overview.md 子模块一 - Demand SLS
// 计算公式: SUM(o2o_sales_amt)
// 筛选条件:
//   - calc_type = "payment"
//   - data_date ∈ [__TimeMin, __TimeMax]（全局时间范围）
//   - 金额类指标 ÷ __FXRate（汇率换算）
// 数据类型: currency → 货币符号由币种切片器决定，千分位整数
// ========================================
    VAR __TimeMin = SELECTEDVALUE(Slicer_Time_Frame_Min[TimeFrame_Min])
    VAR __TimeMax = SELECTEDVALUE(Slicer_Time_Frame_Max[TimeFrame_Max])
    VAR __FXRate = SELECTEDVALUE('Slicer_Currency_Selection'[Currency_ExchangeRate], 1)
    VAR __Result =
        CALCULATE(
            SUM('a02_e2e_boss_performance_summary_d'[o2o_sales_amt]),
            'a02_e2e_boss_performance_summary_d'[calc_type] = "payment",
            'a02_e2e_boss_performance_summary_d'[data_date] >= __TimeMin,
            'a02_e2e_boss_performance_summary_d'[data_date] <= __TimeMax
        )
    RETURN DIVIDE(__Result, __FXRate)
```

### 4.8 Demand SLS Actual Display

```dax
Demand SLS Actual Display =
// ========================================
// 度量值: Demand SLS Actual Display
// Display Folder: PB Location
// 用途: TY O2O退前销售额 格式化显示
// 依赖: [Demand SLS Actual Value], Slicer_Currency_Selection
// 格式类型: currency → __CurrencySymbol & FORMAT(__Value, "#,##0")
// ========================================
    VAR __Value = [Demand SLS Actual Value]
    VAR __CurrencySymbol = SELECTEDVALUE('Slicer_Currency_Selection'[Currency_Symbol], "¥")
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            __CurrencySymbol & FORMAT(__Value, "#,##0")
        )
```

### 4.9 Demand SLS LY Value（财历映射）

```dax
Demand SLS LY Value =
// ========================================
// 度量值: Demand SLS LY Value
// Display Folder: PB Location
// 用途: LY O2O退前销售额（去年同期）
// 口径来源: Overview.md 子模块一 - Demand SLS LY
// 计算公式: 去年同期 SUM(o2o_sales_amt)
// 时间偏移: 财历映射（直接读取日期表内置 LY 字段）
//   全局范围: Slicer_Time_Frame_Min[TimeFrame_Min_LY] / Slicer_Time_Frame_Max[TimeFrame_Max_LY]
//   金额类指标 ÷ __FXRate（汇率换算）
// 数据类型: currency → 货币符号由币种切片器决定，千分位整数
// ========================================
    VAR __LYTimeMin = SELECTEDVALUE(Slicer_Time_Frame_Min[TimeFrame_Min_LY])
    VAR __LYTimeMax = SELECTEDVALUE(Slicer_Time_Frame_Max[TimeFrame_Max_LY])
    VAR __FXRate = SELECTEDVALUE('Slicer_Currency_Selection'[Currency_ExchangeRate], 1)
    VAR __Result =
        CALCULATE(
            SUM('a02_e2e_boss_performance_summary_d'[o2o_sales_amt]),
            'a02_e2e_boss_performance_summary_d'[calc_type] = "payment",
            'a02_e2e_boss_performance_summary_d'[data_date] >= __LYTimeMin,
            'a02_e2e_boss_performance_summary_d'[data_date] <= __LYTimeMax
        )
    RETURN DIVIDE(__Result, __FXRate)
```

### 4.10 Demand SLS LY Display

```dax
Demand SLS LY Display =
// ========================================
// 度量值: Demand SLS LY Display
// Display Folder: PB Location
// 用途: LY O2O退前销售额 格式化显示
// 依赖: [Demand SLS LY Value], Slicer_Currency_Selection
// 格式类型: currency → __CurrencySymbol & FORMAT(__Value, "#,##0")
// ========================================
    VAR __Value = [Demand SLS LY Value]
    VAR __CurrencySymbol = SELECTEDVALUE('Slicer_Currency_Selection'[Currency_Symbol], "¥")
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            __CurrencySymbol & FORMAT(__Value, "#,##0")
        )
```

### 4.11 Demand SLS vs LY Value

```dax
Demand SLS vs LY Value =
// ========================================
// 度量值: Demand SLS vs LY Value
// Display Folder: PB Location
// 用途: O2O退前销售额同比（今年/去年-1）
// 口径来源: Overview.md 子模块一 - Demand SLS vs LY
// 计算公式: [Demand SLS Actual Value] / [Demand SLS LY Value] - 1
// 派生类型: 金额类 → percent_1dp（今年/去年-1）
// 注: vs LY 同比值不受 Currency 切片器影响（汇率在相除时自动抵消）
// 数据类型: percent_1dp → 百分比，保留一位小数，不含正号
// ========================================
    VAR __TY = [Demand SLS Actual Value]
    VAR __LY = [Demand SLS LY Value]
    RETURN
        IF(
            ISBLANK(__LY) || __LY = 0,
            BLANK(),
            DIVIDE(__TY, __LY) - 1
        )
```

### 4.12 Demand SLS vs LY Display

```dax
Demand SLS vs LY Display =
// ========================================
// 度量值: Demand SLS vs LY Display
// Display Folder: PB Location
// 用途: O2O退前销售额同比 格式化显示
// 依赖: [Demand SLS vs LY Value]
// 格式类型: percent_1dp → #,##0.0%
// ========================================
    VAR __Value = [Demand SLS vs LY Value]
    RETURN
        IF(ISBLANK(__Value), "-", FORMAT(__Value, "#,##0.0%"))
```

---

## 指标三：SLS Penetration（O2O销售渗透率）

> 比率类 · calc_type = "payment" · SUM(o2o_sales_amt) / SUM(sales_amt)
> 比率类不除汇率（分子分母同币种相除自动抵消）

### 4.13 SLS Penetration Actual Value

```dax
SLS Penetration Actual Value =
// ========================================
// 度量值: SLS Penetration Actual Value
// Display Folder: PB Location
// 用途: TY O2O销售渗透率 Act 值
// 口径来源: Overview.md 子模块一 - SLS Penetration
// 计算公式: SUM(o2o_sales_amt) / SUM(sales_amt)
//   分子: o2o_sales_amt
//   分母: sales_amt
// 筛选条件:
//   - calc_type = "payment"
//   - data_date ∈ [__TimeMin, __TimeMax]（全局时间范围）
//   - 比率类，不除汇率（分子分母同币种，相除自动抵消）
// 数据类型: percent_1dp → 百分比，保留一位小数，不含正号
// ========================================
    VAR __TimeMin = SELECTEDVALUE(Slicer_Time_Frame_Min[TimeFrame_Min])
    VAR __TimeMax = SELECTEDVALUE(Slicer_Time_Frame_Max[TimeFrame_Max])
    // 分子：o2o_sales_amt
    VAR __Numerator =
        CALCULATE(
            SUM('a02_e2e_boss_performance_summary_d'[o2o_sales_amt]),
            'a02_e2e_boss_performance_summary_d'[calc_type] = "payment",
            'a02_e2e_boss_performance_summary_d'[data_date] >= __TimeMin,
            'a02_e2e_boss_performance_summary_d'[data_date] <= __TimeMax
        )
    // 分母：sales_amt
    VAR __Denominator =
        CALCULATE(
            SUM('a02_e2e_boss_performance_summary_d'[sales_amt]),
            'a02_e2e_boss_performance_summary_d'[calc_type] = "payment",
            'a02_e2e_boss_performance_summary_d'[data_date] >= __TimeMin,
            'a02_e2e_boss_performance_summary_d'[data_date] <= __TimeMax
        )
    RETURN DIVIDE(__Numerator, __Denominator)
```

### 4.14 SLS Penetration Actual Display

```dax
SLS Penetration Actual Display =
// ========================================
// 度量值: SLS Penetration Actual Display
// Display Folder: PB Location
// 用途: TY O2O销售渗透率 格式化显示
// 依赖: [SLS Penetration Actual Value]
// 格式类型: percent_1dp → #,##0.0%
// ========================================
    VAR __Value = [SLS Penetration Actual Value]
    RETURN
        IF(ISBLANK(__Value), "-", FORMAT(__Value, "#,##0.0%"))
```

### 4.15 SLS Penetration LY Value（财历映射）

```dax
SLS Penetration LY Value =
// ========================================
// 度量值: SLS Penetration LY Value
// Display Folder: PB Location
// 用途: LY O2O销售渗透率（去年同期）
// 口径来源: Overview.md 子模块一 - SLS Penetration LY
// 计算公式: 去年同期 SUM(o2o_sales_amt) / SUM(sales_amt)
// 时间偏移: 财历映射（直接读取日期表内置 LY 字段）
//   全局范围: Slicer_Time_Frame_Min[TimeFrame_Min_LY] / Slicer_Time_Frame_Max[TimeFrame_Max_LY]
//   比率类，不除汇率
// 数据类型: percent_1dp → 百分比，保留一位小数，不含正号
// ========================================
    VAR __LYTimeMin = SELECTEDVALUE(Slicer_Time_Frame_Min[TimeFrame_Min_LY])
    VAR __LYTimeMax = SELECTEDVALUE(Slicer_Time_Frame_Max[TimeFrame_Max_LY])
    // 分子：o2o_sales_amt（去年同期）
    VAR __Numerator =
        CALCULATE(
            SUM('a02_e2e_boss_performance_summary_d'[o2o_sales_amt]),
            'a02_e2e_boss_performance_summary_d'[calc_type] = "payment",
            'a02_e2e_boss_performance_summary_d'[data_date] >= __LYTimeMin,
            'a02_e2e_boss_performance_summary_d'[data_date] <= __LYTimeMax
        )
    // 分母：sales_amt（去年同期）
    VAR __Denominator =
        CALCULATE(
            SUM('a02_e2e_boss_performance_summary_d'[sales_amt]),
            'a02_e2e_boss_performance_summary_d'[calc_type] = "payment",
            'a02_e2e_boss_performance_summary_d'[data_date] >= __LYTimeMin,
            'a02_e2e_boss_performance_summary_d'[data_date] <= __LYTimeMax
        )
    RETURN DIVIDE(__Numerator, __Denominator)
```

### 4.16 SLS Penetration LY Display

```dax
SLS Penetration LY Display =
// ========================================
// 度量值: SLS Penetration LY Display
// Display Folder: PB Location
// 用途: LY O2O销售渗透率 格式化显示
// 依赖: [SLS Penetration LY Value]
// 格式类型: percent_1dp → #,##0.0%
// ========================================
    VAR __Value = [SLS Penetration LY Value]
    RETURN
        IF(ISBLANK(__Value), "-", FORMAT(__Value, "#,##0.0%"))
```

### 4.17 SLS Penetration vs LY Value

```dax
SLS Penetration vs LY Value =
// ========================================
// 度量值: SLS Penetration vs LY Value
// Display Folder: PB Location
// 用途: O2O销售渗透率同比（今年-去年，差值）
// 口径来源: Overview.md 子模块一 - SLS Penetration vs LY
// 计算公式: [SLS Penetration Actual Value] - [SLS Penetration LY Value]
// 派生类型: 比率类 → delta_bp（今年-去年，差值，展示时 ×10000 转 bp）
// 数据类型: decimal（差值，0~1 范围小数）
// ========================================
    VAR __TY = [SLS Penetration Actual Value]
    VAR __LY = [SLS Penetration LY Value]
    RETURN __TY - __LY
```

### 4.18 SLS Penetration vs LY Display

```dax
SLS Penetration vs LY Display =
// ========================================
// 度量值: SLS Penetration vs LY Display
// Display Folder: PB Location
// 用途: O2O销售渗透率同比 格式化显示
// 依赖: [SLS Penetration vs LY Value]
// 格式类型: delta_bp → 值×10000 转 bp，含正负号
//   格式串: IF(ROUND(__Value*10000,0)>0,"+","") & FORMAT(__Value*10000, "#,##0bp;-#,##0bp;0bp")
// ========================================
    VAR __Value = [SLS Penetration vs LY Value]
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            IF(ROUND(__Value * 10000, 0) > 0, "+", "") & FORMAT(__Value * 10000, "#,##0bp;-#,##0bp;0bp")
        )
```

---

## 指标四：Return（O2O退货金额）

> 金额类 · calc_type = "payment" · SUM(o2o_return_amt)

### 4.19 Return Actual Value

```dax
Return Actual Value =
// ========================================
// 度量值: Return Actual Value
// Display Folder: PB Location
// 用途: TY O2O退货金额 Act 值
// 口径来源: Overview.md 子模块一 - Return
// 计算公式: SUM(o2o_return_amt)
// 筛选条件:
//   - calc_type = "payment"
//   - data_date ∈ [__TimeMin, __TimeMax]（全局时间范围）
//   - 金额类指标 ÷ __FXRate（汇率换算）
// 数据类型: currency → 货币符号由币种切片器决定，千分位整数
// ========================================
    VAR __TimeMin = SELECTEDVALUE(Slicer_Time_Frame_Min[TimeFrame_Min])
    VAR __TimeMax = SELECTEDVALUE(Slicer_Time_Frame_Max[TimeFrame_Max])
    VAR __FXRate = SELECTEDVALUE('Slicer_Currency_Selection'[Currency_ExchangeRate], 1)
    VAR __Result =
        CALCULATE(
            SUM('a02_e2e_boss_performance_summary_d'[o2o_return_amt]),
            'a02_e2e_boss_performance_summary_d'[calc_type] = "payment",
            'a02_e2e_boss_performance_summary_d'[data_date] >= __TimeMin,
            'a02_e2e_boss_performance_summary_d'[data_date] <= __TimeMax
        )
    RETURN DIVIDE(__Result, __FXRate)
```

### 4.20 Return Actual Display

```dax
Return Actual Display =
// ========================================
// 度量值: Return Actual Display
// Display Folder: PB Location
// 用途: TY O2O退货金额 格式化显示
// 依赖: [Return Actual Value], Slicer_Currency_Selection
// 格式类型: currency → __CurrencySymbol & FORMAT(__Value, "#,##0")
// ========================================
    VAR __Value = [Return Actual Value]
    VAR __CurrencySymbol = SELECTEDVALUE('Slicer_Currency_Selection'[Currency_Symbol], "¥")
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            __CurrencySymbol & FORMAT(__Value, "#,##0")
        )
```

### 4.21 Return LY Value（财历映射）

```dax
Return LY Value =
// ========================================
// 度量值: Return LY Value
// Display Folder: PB Location
// 用途: LY O2O退货金额（去年同期）
// 口径来源: Overview.md 子模块一 - Return LY
// 计算公式: 去年同期 SUM(o2o_return_amt)
// 时间偏移: 财历映射（直接读取日期表内置 LY 字段）
//   全局范围: Slicer_Time_Frame_Min[TimeFrame_Min_LY] / Slicer_Time_Frame_Max[TimeFrame_Max_LY]
//   金额类指标 ÷ __FXRate（汇率换算）
// 数据类型: currency → 货币符号由币种切片器决定，千分位整数
// ========================================
    VAR __LYTimeMin = SELECTEDVALUE(Slicer_Time_Frame_Min[TimeFrame_Min_LY])
    VAR __LYTimeMax = SELECTEDVALUE(Slicer_Time_Frame_Max[TimeFrame_Max_LY])
    VAR __FXRate = SELECTEDVALUE('Slicer_Currency_Selection'[Currency_ExchangeRate], 1)
    VAR __Result =
        CALCULATE(
            SUM('a02_e2e_boss_performance_summary_d'[o2o_return_amt]),
            'a02_e2e_boss_performance_summary_d'[calc_type] = "payment",
            'a02_e2e_boss_performance_summary_d'[data_date] >= __LYTimeMin,
            'a02_e2e_boss_performance_summary_d'[data_date] <= __LYTimeMax
        )
    RETURN DIVIDE(__Result, __FXRate)
```

### 4.22 Return LY Display

```dax
Return LY Display =
// ========================================
// 度量值: Return LY Display
// Display Folder: PB Location
// 用途: LY O2O退货金额 格式化显示
// 依赖: [Return LY Value], Slicer_Currency_Selection
// 格式类型: currency → __CurrencySymbol & FORMAT(__Value, "#,##0")
// ========================================
    VAR __Value = [Return LY Value]
    VAR __CurrencySymbol = SELECTEDVALUE('Slicer_Currency_Selection'[Currency_Symbol], "¥")
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            __CurrencySymbol & FORMAT(__Value, "#,##0")
        )
```

### 4.23 Return vs LY Value

```dax
Return vs LY Value =
// ========================================
// 度量值: Return vs LY Value
// Display Folder: PB Location
// 用途: O2O退货金额同比（今年/去年-1）
// 口径来源: Overview.md 子模块一 - Return vs LY
// 计算公式: [Return Actual Value] / [Return LY Value] - 1
// 派生类型: 金额类 → percent_1dp（今年/去年-1）
// 注: vs LY 同比值不受 Currency 切片器影响（汇率在相除时自动抵消）
// 数据类型: percent_1dp → 百分比，保留一位小数，不含正号
// ========================================
    VAR __TY = [Return Actual Value]
    VAR __LY = [Return LY Value]
    RETURN
        IF(
            ISBLANK(__LY) || __LY = 0,
            BLANK(),
            DIVIDE(__TY, __LY) - 1
        )
```

### 4.24 Return vs LY Display

```dax
Return vs LY Display =
// ========================================
// 度量值: Return vs LY Display
// Display Folder: PB Location
// 用途: O2O退货金额同比 格式化显示
// 依赖: [Return vs LY Value]
// 格式类型: percent_1dp → #,##0.0%
// ========================================
    VAR __Value = [Return vs LY Value]
    RETURN
        IF(ISBLANK(__Value), "-", FORMAT(__Value, "#,##0.0%"))
```

---

## 指标五：Return%（O2O退货率）

> 比率类 · calc_type = "payment" · SUM(o2o_return_amt) / SUM(o2o_sales_amt)
> 比率类不除汇率（分子分母同币种相除自动抵消）

### 4.25 Return% Actual Value

```dax
Return% Actual Value =
// ========================================
// 度量值: Return% Actual Value
// Display Folder: PB Location
// 用途: TY O2O退货率（金额）Act 值
// 口径来源: Overview.md 子模块一 - Return%
// 计算公式: SUM(o2o_return_amt) / SUM(o2o_sales_amt)
//   分子: o2o_return_amt
//   分母: o2o_sales_amt
// 筛选条件:
//   - calc_type = "payment"
//   - data_date ∈ [__TimeMin, __TimeMax]（全局时间范围）
//   - 比率类，不除汇率（分子分母同币种，相除自动抵消）
// 数据类型: percent_1dp → 百分比，保留一位小数，不含正号
// ========================================
    VAR __TimeMin = SELECTEDVALUE(Slicer_Time_Frame_Min[TimeFrame_Min])
    VAR __TimeMax = SELECTEDVALUE(Slicer_Time_Frame_Max[TimeFrame_Max])
    // 分子：o2o_return_amt
    VAR __Numerator =
        CALCULATE(
            SUM('a02_e2e_boss_performance_summary_d'[o2o_return_amt]),
            'a02_e2e_boss_performance_summary_d'[calc_type] = "payment",
            'a02_e2e_boss_performance_summary_d'[data_date] >= __TimeMin,
            'a02_e2e_boss_performance_summary_d'[data_date] <= __TimeMax
        )
    // 分母：o2o_sales_amt
    VAR __Denominator =
        CALCULATE(
            SUM('a02_e2e_boss_performance_summary_d'[o2o_sales_amt]),
            'a02_e2e_boss_performance_summary_d'[calc_type] = "payment",
            'a02_e2e_boss_performance_summary_d'[data_date] >= __TimeMin,
            'a02_e2e_boss_performance_summary_d'[data_date] <= __TimeMax
        )
    RETURN DIVIDE(__Numerator, __Denominator)
```

### 4.26 Return% Actual Display

```dax
Return% Actual Display =
// ========================================
// 度量值: Return% Actual Display
// Display Folder: PB Location
// 用途: TY O2O退货率 格式化显示
// 依赖: [Return% Actual Value]
// 格式类型: percent_1dp → #,##0.0%
// ========================================
    VAR __Value = [Return% Actual Value]
    RETURN
        IF(ISBLANK(__Value), "-", FORMAT(__Value, "#,##0.0%"))
```

### 4.27 Return% LY Value（财历映射）

```dax
Return% LY Value =
// ========================================
// 度量值: Return% LY Value
// Display Folder: PB Location
// 用途: LY O2O退货率（去年同期）
// 口径来源: Overview.md 子模块一 - Return% LY
// 计算公式: 去年同期 SUM(o2o_return_amt) / SUM(o2o_sales_amt)
// 时间偏移: 财历映射（直接读取日期表内置 LY 字段）
//   全局范围: Slicer_Time_Frame_Min[TimeFrame_Min_LY] / Slicer_Time_Frame_Max[TimeFrame_Max_LY]
//   比率类，不除汇率
// 数据类型: percent_1dp → 百分比，保留一位小数，不含正号
// ========================================
    VAR __LYTimeMin = SELECTEDVALUE(Slicer_Time_Frame_Min[TimeFrame_Min_LY])
    VAR __LYTimeMax = SELECTEDVALUE(Slicer_Time_Frame_Max[TimeFrame_Max_LY])
    // 分子：o2o_return_amt（去年同期）
    VAR __Numerator =
        CALCULATE(
            SUM('a02_e2e_boss_performance_summary_d'[o2o_return_amt]),
            'a02_e2e_boss_performance_summary_d'[calc_type] = "payment",
            'a02_e2e_boss_performance_summary_d'[data_date] >= __LYTimeMin,
            'a02_e2e_boss_performance_summary_d'[data_date] <= __LYTimeMax
        )
    // 分母：o2o_sales_amt（去年同期）
    VAR __Denominator =
        CALCULATE(
            SUM('a02_e2e_boss_performance_summary_d'[o2o_sales_amt]),
            'a02_e2e_boss_performance_summary_d'[calc_type] = "payment",
            'a02_e2e_boss_performance_summary_d'[data_date] >= __LYTimeMin,
            'a02_e2e_boss_performance_summary_d'[data_date] <= __LYTimeMax
        )
    RETURN DIVIDE(__Numerator, __Denominator)
```

### 4.28 Return% LY Display

```dax
Return% LY Display =
// ========================================
// 度量值: Return% LY Display
// Display Folder: PB Location
// 用途: LY O2O退货率 格式化显示
// 依赖: [Return% LY Value]
// 格式类型: percent_1dp → #,##0.0%
// ========================================
    VAR __Value = [Return% LY Value]
    RETURN
        IF(ISBLANK(__Value), "-", FORMAT(__Value, "#,##0.0%"))
```

### 4.29 Return% vs LY Value

```dax
Return% vs LY Value =
// ========================================
// 度量值: Return% vs LY Value
// Display Folder: PB Location
// 用途: O2O退货率同比（今年-去年，差值）
// 口径来源: Overview.md 子模块一 - Return% vs LY
// 计算公式: [Return% Actual Value] - [Return% LY Value]
// 派生类型: 比率类 → delta_bp（今年-去年，差值，展示时 ×10000 转 bp）
// 数据类型: decimal（差值，0~1 范围小数）
// ========================================
    VAR __TY = [Return% Actual Value]
    VAR __LY = [Return% LY Value]
    RETURN __TY - __LY
```

### 4.30 Return% vs LY Display

```dax
Return% vs LY Display =
// ========================================
// 度量值: Return% vs LY Display
// Display Folder: PB Location
// 用途: O2O退货率同比 格式化显示
// 依赖: [Return% vs LY Value]
// 格式类型: delta_bp → 值×10000 转 bp，含正负号
//   格式串: IF(ROUND(__Value*10000,0)>0,"+","") & FORMAT(__Value*10000, "#,##0bp;-#,##0bp;0bp")
// ========================================
    VAR __Value = [Return% vs LY Value]
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            IF(ROUND(__Value * 10000, 0) > 0, "+", "") & FORMAT(__Value * 10000, "#,##0bp;-#,##0bp;0bp")
        )
```

---

## 5. 度量值清单与 Display Folder

| 序号 | 度量值名称 | Display Folder | 指标 | 类型 | 格式 |
|------|-----------|----------------|------|------|------|
| 1 | SLS Actual Value | PB Location | SLS | Value | currency |
| 2 | SLS Actual Display | PB Location | SLS | Display | currency |
| 3 | SLS LY Value | PB Location | SLS | Value | currency |
| 4 | SLS LY Display | PB Location | SLS | Display | currency |
| 5 | SLS vs LY Value | PB Location | SLS | Value | percent_1dp |
| 6 | SLS vs LY Display | PB Location | SLS | Display | percent_1dp |
| 7 | Demand SLS Actual Value | PB Location | Demand SLS | Value | currency |
| 8 | Demand SLS Actual Display | PB Location | Demand SLS | Display | currency |
| 9 | Demand SLS LY Value | PB Location | Demand SLS | Value | currency |
| 10 | Demand SLS LY Display | PB Location | Demand SLS | Display | currency |
| 11 | Demand SLS vs LY Value | PB Location | Demand SLS | Value | percent_1dp |
| 12 | Demand SLS vs LY Display | PB Location | Demand SLS | Display | percent_1dp |
| 13 | SLS Penetration Actual Value | PB Location | SLS Penetration | Value | percent_1dp |
| 14 | SLS Penetration Actual Display | PB Location | SLS Penetration | Display | percent_1dp |
| 15 | SLS Penetration LY Value | PB Location | SLS Penetration | Value | percent_1dp |
| 16 | SLS Penetration LY Display | PB Location | SLS Penetration | Display | percent_1dp |
| 17 | SLS Penetration vs LY Value | PB Location | SLS Penetration | Value | delta_bp |
| 18 | SLS Penetration vs LY Display | PB Location | SLS Penetration | Display | delta_bp |
| 19 | Return Actual Value | PB Location | Return | Value | currency |
| 20 | Return Actual Display | PB Location | Return | Display | currency |
| 21 | Return LY Value | PB Location | Return | Value | currency |
| 22 | Return LY Display | PB Location | Return | Display | currency |
| 23 | Return vs LY Value | PB Location | Return | Value | percent_1dp |
| 24 | Return vs LY Display | PB Location | Return | Display | percent_1dp |
| 25 | Return% Actual Value | PB Location | Return% | Value | percent_1dp |
| 26 | Return% Actual Display | PB Location | Return% | Display | percent_1dp |
| 27 | Return% LY Value | PB Location | Return% | Value | percent_1dp |
| 28 | Return% LY Display | PB Location | Return% | Display | percent_1dp |
| 29 | Return% vs LY Value | PB Location | Return% | Value | delta_bp |
| 30 | Return% vs LY Display | PB Location | Return% | Display | delta_bp |

---

## 6. 视觉对象配置

### 6.1 表格视觉对象（Table）

| 配置项 | 值 |
|--------|-----|
| 行/分组 | 事实表字段（store_region / store_type / store_name 等，直接拉取，天然筛选+分组） |
| 值 | 依次拉取所需的 [* Value] 或 [* Display] 度量 |
| 全局筛选器 | Slicer_Time_Frame_Min、Slicer_Time_Frame_Max、Slicer_Currency_Selection |

> 无需 IsTimeFrameVisible 视觉对象级别筛选器（无 X 轴时间段）。

### 6.2 度量值拉取示例

| 场景 | 拉取度量 |
|------|---------|
| SLS 本期金额（带符号） | [SLS Actual Display] |
| SLS 去年同期金额（带符号） | [SLS LY Display] |
| SLS 同比百分比 | [SLS vs LY Display] |
| SLS Penetration 本期率 | [SLS Penetration Actual Display] |
| SLS Penetration 同比差值(bp) | [SLS Penetration vs LY Display] |

---

## 7. 验证方法

### 7.1 验证 SQL

```sql
-- SLS O2O销售净额（本期，所有 store 汇总）
-- 假设 __TimeMin='2025-06-29', __TimeMax='2025-08-09'
SELECT SUM(o2o_net_sales_amt) AS SLS_Actual
FROM a02_e2e_boss_performance_summary_d
WHERE calc_type = 'payment'
  AND data_date BETWEEN '2025-06-29' AND '2025-08-09';

-- SLS O2O销售净额（去年同期，LY 日期范围来自日期表 ly_timeframe_min / ly_timeframe_max）
SELECT SUM(o2o_net_sales_amt) AS SLS_LY
FROM a02_e2e_boss_performance_summary_d
WHERE calc_type = 'payment'
  AND data_date BETWEEN '__LYTimeMin' AND '__LYTimeMax';

-- SLS vs LY = SLS_Actual / SLS_LY - 1（percent_1dp）

-- Demand SLS O2O退前销售额（本期）
SELECT SUM(o2o_sales_amt) AS DemandSLS_Actual
FROM a02_e2e_boss_performance_summary_d
WHERE calc_type = 'payment'
  AND data_date BETWEEN '__TimeMin' AND '__TimeMax';

-- SLS Penetration O2O销售渗透率（本期）
SELECT
  SUM(o2o_sales_amt) / SUM(sales_amt) AS SLS_Penetration_Actual
FROM a02_e2e_boss_performance_summary_d
WHERE calc_type = 'payment'
  AND data_date BETWEEN '__TimeMin' AND '__TimeMax';

-- SLS Penetration vs LY = SLS_Penetration_Actual - SLS_Penetration_LY（delta_bp，×10000 转 bp）

-- Return O2O退货金额（本期）
SELECT SUM(o2o_return_amt) AS Return_Actual
FROM a02_e2e_boss_performance_summary_d
WHERE calc_type = 'payment'
  AND data_date BETWEEN '__TimeMin' AND '__TimeMax';

-- Return% O2O退货率（本期）
SELECT
  SUM(o2o_return_amt) / SUM(o2o_sales_amt) AS Return_Pct_Actual
FROM a02_e2e_boss_performance_summary_d
WHERE calc_type = 'payment'
  AND data_date BETWEEN '__TimeMin' AND '__TimeMax';

-- Return% vs LY = Return_Pct_Actual - Return_Pct_LY（delta_bp，×10000 转 bp）
```

### 7.2 LY 日期范围获取方式说明

| TimeFrame_ID | LY 范围获取方式 | 说明 |
|--------------|-----------------|------|
| Day / Week / Month / Quarter / Year | 直接读日期表 `ly_timeframe_min` / `ly_timeframe_max` | 日期表已内置，无需 EDATE -12 或 Key 偏移 |

---

## 8. 注意事项

1. **calc_type 固定**：本方案所有度量值均硬编码 `calc_type = "payment"`（Sales 分组），与 Overview_KPIs_ms.md 中通过 KPI_CalcType 动态读取不同。Sales 分组下五个指标均属 payment 类型。

2. **LY 财历映射**：周/月/季/年粒度按财年定义，LY 采用财历映射（直接读取日期表内置 TimeFrame_Min_LY / TimeFrame_Max_LY 字段），不使用 EDATE -12。日期表需包含至少2年历史数据。若数据历史不足1年，LY 字段返回 BLANK，显示"-"，属可接受行为。

3. **汇率换算**：金额类指标（SLS / Demand SLS / Return）÷ Currency_ExchangeRate；比率类（SLS Penetration / Return%）分子分母同币种相除自动抵消，不除汇率。vs LY 同比值因相除/相减自动抵消汇率影响。

4. **vs LY 派生分类**：
   - 金额类（SLS / Demand SLS / Return）：今年 / 去年 − 1 → percent_1dp
   - 比率类（SLS Penetration / Return%）：今年 − 去年 → delta_bp（展示时 ×10000 转 bp）

5. **分组维度传递**：store_region / store_type / store_name 等分组字段直接从事实表拉取到表格行/列，DAX 度量值无需显式处理分组逻辑，模型自动传递筛选。

6. **与 Overview_KPIs_ms.md 差异**：
   - 去除矩阵 SWITCH 路由，每个指标独立度量
   - 去除 Dim_RowKPIs_BossCoreKPI_Overview（行维度）依赖
   - 去除 Dim_ColKPIs_BossCoreKPI_Overview（列维度）依赖及 StoreGroup_ID → store_name 筛选
   - 去除 Slicer_Fulfillment_Calc_Type 依赖（Sales 分组不涉及）
   - calc_type 由动态读取改为硬编码 "payment"

7. **display 命名约定**：遵循 PB_Location_Trend.md 风格，Actual / LY / vs LY 三类各出 Value + Display，便于表格视觉对象按列拉取。
