# Controllable_Trend_solution 解决方案

> status: updated
> created: 2026-07-15
> complexity: 🟡中等
> type: 度量值开发
> naming: 遵循 dax-style.md 规范
> 口径来源: New Acquisition实际使用版本.md（子模块三：Controllable Ads Format Cost% Trend，#2~#5）

---

## 1. 需求理解

实现 New Acquisition 看板中"Controllable Ads Format Cost% Trend"（子模块三，#2~#5）共 4 个指标的矩阵柱形图/趋势图展示：

- **适用场景**：矩阵柱形图 + 趋势图，每个指标独立编写 Value / Display 度量
- **口径**：一切以口径文档 New Acquisition实际使用版本.md 子模块三为准
- **矩阵 X 轴上下文**：需同时应用两层时间筛选
  - 全局筛选：`Slicer_Month_Period_Min/Max`（起止月份切片器）
  - X 轴上下文：`Slicer_Month_Period`（X 轴当前遍历月份的自然日范围）
- **汇率方向**：人民币转美元，金额类指标**除以** `Currency_ExchangeRate`（RMB=1, USD=7）
- **特殊格式**：
  - `currency_M_K_Int_0db` → 货币符号 + K/M 单位切换（#4、#5）
  - `percent_0dp` → 百分比整数，不含正号（#2、#3）

---

## 2. 度量值实现

### 2.1 Controllable%（#2）

```dax
Controllable% Value = 
// ========================================
// 度量值: Controllable% Value
// Display Folder: Controllable Trend
// 用途: 可控花费占比趋势值（矩阵柱形图/趋势图 Y 轴）
// 口径来源: New Acquisition实际使用版本.md 子模块三 §2
// 计算公式: 可控广告 Cost / TTL Cost
//   分子: cost_amt（is_controllable_channel="1"）
//   分母: cost_amt（is_controllable_channel IN {"0","1"}）
// 筛选条件: customer_type='ALL' AND page_type="1"
// 数据类型: percent_0dp → 百分比整数，不含正号
// 矩阵场景: 同时应用全局月份筛选 + X轴当前月份筛选
// ========================================
    // 1. 获取起止切片器选择的全局范围
    VAR __TimeMin = SELECTEDVALUE(Slicer_Month_Period_Min[TimeFrame_Min])
    VAR __TimeMax = SELECTEDVALUE(Slicer_Month_Period_Max[TimeFrame_Max])
    // 2. 获取柱形图 X 轴当前遍历的月份的自然日范围
    VAR __CurrentMonthMin = SELECTEDVALUE(Slicer_Month_Period[TimeFrame_Min])
    VAR __CurrentMonthMax = SELECTEDVALUE(Slicer_Month_Period[TimeFrame_Max])
    // ── 分子：可控广告 Cost（is_controllable_channel="1"）──
    VAR __ControllableCost =
        CALCULATE(
            SUM('a05_e2e_paid_media_summary_d'[cost_amt]),
            'a05_e2e_paid_media_summary_d'[customer_type] = "ALL",
            'a05_e2e_paid_media_summary_d'[is_controllable_channel] = "1",
            'a05_e2e_paid_media_summary_d'[page_type] = "1",
            // 3. 全局切片器筛选：限制事实表数据在选定的起止月份范围内
            'a05_e2e_paid_media_summary_d'[data_date] >= __TimeMin,
            'a05_e2e_paid_media_summary_d'[data_date] <= __TimeMax,
            // 4. X轴上下文筛选：限制事实表数据仅属于当前X轴遍历的那个月
            'a05_e2e_paid_media_summary_d'[data_date] >= __CurrentMonthMin,
            'a05_e2e_paid_media_summary_d'[data_date] <= __CurrentMonthMax
        )
    // ── 分母：TTL Cost（is_controllable_channel IN {"0","1"}）──
    VAR __TotalCost =
        CALCULATE(
            SUM('a05_e2e_paid_media_summary_d'[cost_amt]),
            'a05_e2e_paid_media_summary_d'[customer_type] = "ALL",
            'a05_e2e_paid_media_summary_d'[is_controllable_channel] IN {"0", "1"},
            'a05_e2e_paid_media_summary_d'[page_type] = "1",
            'a05_e2e_paid_media_summary_d'[data_date] >= __TimeMin,
            'a05_e2e_paid_media_summary_d'[data_date] <= __TimeMax,
            'a05_e2e_paid_media_summary_d'[data_date] >= __CurrentMonthMin,
            'a05_e2e_paid_media_summary_d'[data_date] <= __CurrentMonthMax
        )
    RETURN
        DIVIDE(__ControllableCost, __TotalCost)
```

```dax
Controllable% Display = 
// ========================================
// 度量值: Controllable% Display
// Display Folder: Controllable Trend
// 用途: 可控花费占比格式化显示
// 依赖: [Controllable% Value]
// 格式类型: percent_0dp → 百分比整数，不含正号
// 格式串: #,##0%;#,##0%;0%
// ========================================
    VAR __Value = [Controllable% Value]
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            FORMAT(__Value, "#,##0%;#,##0%;0%")
        )
```

### 2.2 Uncontrollable%（#3）

```dax
Uncontrollable% Value = 
// ========================================
// 度量值: Uncontrollable% Value
// Display Folder: Controllable Trend
// 用途: 不可控花费占比趋势值（矩阵柱形图/趋势图 Y 轴）
// 口径来源: New Acquisition实际使用版本.md 子模块三 §3
// 计算公式: 不可控广告 Cost / TTL Cost
//   分子: cost_amt（is_controllable_channel="0"）
//   分母: cost_amt（is_controllable_channel IN {"0","1"}）
// 筛选条件: customer_type='ALL' AND page_type="1"
// 数据类型: percent_0dp → 百分比整数，不含正号
// 矩阵场景: 同时应用全局月份筛选 + X轴当前月份筛选
// ========================================
    // 1. 获取起止切片器选择的全局范围
    VAR __TimeMin = SELECTEDVALUE(Slicer_Month_Period_Min[TimeFrame_Min])
    VAR __TimeMax = SELECTEDVALUE(Slicer_Month_Period_Max[TimeFrame_Max])
    // 2. 获取柱形图 X 轴当前遍历的月份的自然日范围
    VAR __CurrentMonthMin = SELECTEDVALUE(Slicer_Month_Period[TimeFrame_Min])
    VAR __CurrentMonthMax = SELECTEDVALUE(Slicer_Month_Period[TimeFrame_Max])
    // ── 分子：不可控广告 Cost（is_controllable_channel="0"）──
    VAR __UncontrollableCost =
        CALCULATE(
            SUM('a05_e2e_paid_media_summary_d'[cost_amt]),
            'a05_e2e_paid_media_summary_d'[customer_type] = "ALL",
            'a05_e2e_paid_media_summary_d'[is_controllable_channel] = "0",
            'a05_e2e_paid_media_summary_d'[page_type] = "1",
            // 3. 全局切片器筛选
            'a05_e2e_paid_media_summary_d'[data_date] >= __TimeMin,
            'a05_e2e_paid_media_summary_d'[data_date] <= __TimeMax,
            // 4. X轴上下文筛选
            'a05_e2e_paid_media_summary_d'[data_date] >= __CurrentMonthMin,
            'a05_e2e_paid_media_summary_d'[data_date] <= __CurrentMonthMax
        )
    // ── 分母：TTL Cost（is_controllable_channel IN {"0","1"}）──
    VAR __TotalCost =
        CALCULATE(
            SUM('a05_e2e_paid_media_summary_d'[cost_amt]),
            'a05_e2e_paid_media_summary_d'[customer_type] = "ALL",
            'a05_e2e_paid_media_summary_d'[is_controllable_channel] IN {"0", "1"},
            'a05_e2e_paid_media_summary_d'[page_type] = "1",
            'a05_e2e_paid_media_summary_d'[data_date] >= __TimeMin,
            'a05_e2e_paid_media_summary_d'[data_date] <= __TimeMax,
            'a05_e2e_paid_media_summary_d'[data_date] >= __CurrentMonthMin,
            'a05_e2e_paid_media_summary_d'[data_date] <= __CurrentMonthMax
        )
    RETURN
        DIVIDE(__UncontrollableCost, __TotalCost)
```

```dax
Uncontrollable% Display = 
// ========================================
// 度量值: Uncontrollable% Display
// Display Folder: Controllable Trend
// 用途: 不可控花费占比格式化显示
// 依赖: [Uncontrollable% Value]
// 格式类型: percent_0dp → 百分比整数，不含正号
// 格式串: #,##0%;#,##0%;0%
// ========================================
    VAR __Value = [Uncontrollable% Value]
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            FORMAT(__Value, "#,##0%;#,##0%;0%")
        )
```

### 2.3 Controllable Cost（#4）

```dax
Controllable Cost Value = 
// ========================================
// 度量值: Controllable Cost Value
// Display Folder: Controllable Trend
// 用途: 可控广告花费趋势值（矩阵柱形图/趋势图 Y 轴）
// 口径来源: New Acquisition实际使用版本.md 子模块三 §4
// 计算公式: SUM(cost_amt), is_controllable_channel="1"
// 统计字段: cost_amt
// 筛选条件: customer_type='ALL' AND is_controllable_channel="1" AND page_type="1"
// 数据类型: currency_M_K_Int_0db（金额类指标，需汇率转换）
// 汇率方向: 人民币转美元，除以 Currency_ExchangeRate
// 矩阵场景: 同时应用全局月份筛选 + X轴当前月份筛选
// ========================================
    // 1. 获取起止切片器选择的全局范围
    VAR __TimeMin = SELECTEDVALUE(Slicer_Month_Period_Min[TimeFrame_Min])
    VAR __TimeMax = SELECTEDVALUE(Slicer_Month_Period_Max[TimeFrame_Max])
    // 2. 获取柱形图 X 轴当前遍历的月份的自然日范围
    VAR __CurrentMonthMin = SELECTEDVALUE(Slicer_Month_Period[TimeFrame_Min])
    VAR __CurrentMonthMax = SELECTEDVALUE(Slicer_Month_Period[TimeFrame_Max])
    // 3. 汇率（人民币转美元，用除法）
    VAR __FXRate = SELECTEDVALUE(Slicer_Currency_Selection[Currency_ExchangeRate], 1)
    VAR __ControllableCost =
        CALCULATE(
            SUM('a05_e2e_paid_media_summary_d'[cost_amt]),
            'a05_e2e_paid_media_summary_d'[customer_type] = "ALL",
            'a05_e2e_paid_media_summary_d'[is_controllable_channel] = "1",
            'a05_e2e_paid_media_summary_d'[page_type] = "1",
            // 4. 全局切片器筛选
            'a05_e2e_paid_media_summary_d'[data_date] >= __TimeMin,
            'a05_e2e_paid_media_summary_d'[data_date] <= __TimeMax,
            // 5. X轴上下文筛选
            'a05_e2e_paid_media_summary_d'[data_date] >= __CurrentMonthMin,
            'a05_e2e_paid_media_summary_d'[data_date] <= __CurrentMonthMax
        )
    RETURN
        DIVIDE(__ControllableCost, __FXRate)
```

```dax
Controllable Cost Display = 
// ========================================
// 度量值: Controllable Cost Display
// Display Folder: Controllable Trend
// 用途: 可控广告花费格式化显示（K/M 单位切换）
// 依赖: [Controllable Cost Value], Slicer_Currency_Selection
// 格式类型: currency_M_K_Int_0db
//   值 < 1,000        → 货币符号 + 千分位整数：¥999
//   1,000 ≤ 值 < 1M   → 货币符号 + K 单位（1位小数）：¥1.5K
//   值 ≥ 1,000,000    → 货币符号 + M 单位（1位小数）：¥1.5M
// ========================================
    VAR __Value = [Controllable Cost Value]
    VAR __CurrencySymbol = SELECTEDVALUE(Slicer_Currency_Selection[Currency_Symbol], "¥")
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            IF(
                __Value < 1000,
                __CurrencySymbol & FORMAT(__Value, "#,##0"),
                IF(
                    __Value < 1000000,
                    __CurrencySymbol & FORMAT(__Value / 1000, "#,##0.0") & "K",
                    __CurrencySymbol & FORMAT(__Value / 1000000, "#,##0.0") & "M"
                )
            )
        )
```

### 2.4 Uncontrollable Cost（#5）

```dax
Uncontrollable Cost Value = 
// ========================================
// 度量值: Uncontrollable Cost Value
// Display Folder: Controllable Trend
// 用途: 不可控广告花费趋势值（矩阵柱形图/趋势图 Y 轴）
// 口径来源: New Acquisition实际使用版本.md 子模块三 §5
// 计算公式: SUM(cost_amt), is_controllable_channel="0"
// 统计字段: cost_amt
// 筛选条件: customer_type='ALL' AND is_controllable_channel="0" AND page_type="1"
// 数据类型: currency_M_K_Int_0db（金额类指标，需汇率转换）
// 汇率方向: 人民币转美元，除以 Currency_ExchangeRate
// 矩阵场景: 同时应用全局月份筛选 + X轴当前月份筛选
// ========================================
    // 1. 获取起止切片器选择的全局范围
    VAR __TimeMin = SELECTEDVALUE(Slicer_Month_Period_Min[TimeFrame_Min])
    VAR __TimeMax = SELECTEDVALUE(Slicer_Month_Period_Max[TimeFrame_Max])
    // 2. 获取柱形图 X 轴当前遍历的月份的自然日范围
    VAR __CurrentMonthMin = SELECTEDVALUE(Slicer_Month_Period[TimeFrame_Min])
    VAR __CurrentMonthMax = SELECTEDVALUE(Slicer_Month_Period[TimeFrame_Max])
    // 3. 汇率（人民币转美元，用除法）
    VAR __FXRate = SELECTEDVALUE(Slicer_Currency_Selection[Currency_ExchangeRate], 1)
    VAR __UncontrollableCost =
        CALCULATE(
            SUM('a05_e2e_paid_media_summary_d'[cost_amt]),
            'a05_e2e_paid_media_summary_d'[customer_type] = "ALL",
            'a05_e2e_paid_media_summary_d'[is_controllable_channel] = "0",
            'a05_e2e_paid_media_summary_d'[page_type] = "1",
            // 4. 全局切片器筛选
            'a05_e2e_paid_media_summary_d'[data_date] >= __TimeMin,
            'a05_e2e_paid_media_summary_d'[data_date] <= __TimeMax,
            // 5. X轴上下文筛选
            'a05_e2e_paid_media_summary_d'[data_date] >= __CurrentMonthMin,
            'a05_e2e_paid_media_summary_d'[data_date] <= __CurrentMonthMax
        )
    RETURN
        DIVIDE(__UncontrollableCost, __FXRate)
```

```dax
Uncontrollable Cost Display = 
// ========================================
// 度量值: Uncontrollable Cost Display
// Display Folder: Controllable Trend
// 用途: 不可控广告花费格式化显示（K/M 单位切换）
// 依赖: [Uncontrollable Cost Value], Slicer_Currency_Selection
// 格式类型: currency_M_K_Int_0db
//   值 < 1,000        → 货币符号 + 千分位整数：¥999
//   1,000 ≤ 值 < 1M   → 货币符号 + K 单位（1位小数）：¥1.5K
//   值 ≥ 1,000,000    → 货币符号 + M 单位（1位小数）：¥1.5M
// ========================================
    VAR __Value = [Uncontrollable Cost Value]
    VAR __CurrencySymbol = SELECTEDVALUE(Slicer_Currency_Selection[Currency_Symbol], "¥")
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            IF(
                __Value < 1000,
                __CurrencySymbol & FORMAT(__Value, "#,##0"),
                IF(
                    __Value < 1000000,
                    __CurrencySymbol & FORMAT(__Value / 1000, "#,##0.0") & "K",
                    __CurrencySymbol & FORMAT(__Value / 1000000, "#,##0.0") & "M"
                )
            )
        )
```

---

### 2.5 Cost amt Value（自己额外新增）

```dax
Cost amt Value = 
// ========================================
// 度量值: Cost amt Value
// Display Folder: Controllable Trend
// 用途: 广告花费趋势值（矩阵柱形图/趋势图 Y 轴）
// 口径来源: New Acquisition实际使用版本.md 子模块三 §5
// 计算公式: SUM(cost_amt)  
// 统计字段: cost_amt
// 筛选条件: customer_type='ALL' AND page_type="1"
// 数据类型: currency_M_K_Int_0db（金额类指标，需汇率转换）
// 汇率方向: 人民币转美元，除以 Currency_ExchangeRate
// 矩阵场景: 同时应用全局月份筛选 + X轴当前月份筛选
// ========================================
    // 1. 获取起止切片器选择的全局范围
    VAR __TimeMin = SELECTEDVALUE(Slicer_Month_Period_Min[TimeFrame_Min])
    VAR __TimeMax = SELECTEDVALUE(Slicer_Month_Period_Max[TimeFrame_Max])
    // 2. 获取柱形图 X 轴当前遍历的月份的自然日范围
    VAR __CurrentMonthMin = SELECTEDVALUE(Slicer_Month_Period[TimeFrame_Min])
    VAR __CurrentMonthMax = SELECTEDVALUE(Slicer_Month_Period[TimeFrame_Max])
    // 3. 汇率（人民币转美元，用除法）
    VAR __FXRate = SELECTEDVALUE(Slicer_Currency_Selection[Currency_ExchangeRate], 1)
    VAR __CostAmt =
        CALCULATE(
            SUM('a05_e2e_paid_media_summary_d'[cost_amt]),
            'a05_e2e_paid_media_summary_d'[customer_type] = "ALL",
            'a05_e2e_paid_media_summary_d'[page_type] = "1",
            // 4. 全局切片器筛选
            'a05_e2e_paid_media_summary_d'[data_date] >= __TimeMin,
            'a05_e2e_paid_media_summary_d'[data_date] <= __TimeMax,
            // 5. X轴上下文筛选
            'a05_e2e_paid_media_summary_d'[data_date] >= __CurrentMonthMin,
            'a05_e2e_paid_media_summary_d'[data_date] <= __CurrentMonthMax
        )
    RETURN
        DIVIDE(__CostAmt, __FXRate)
```

```dax
Cost amt Display = 
// ========================================
// 度量值: Cost amt Display
// Display Folder: KPIs Measure
// 用途: 广告花费格式化显示（K/M 单位切换）
// 依赖: [Cost amt Value], Slicer_Currency_Selection
// 格式类型: currency_M_K_Int_0db
//   值 < 1,000        → 货币符号 + 千分位整数：¥999
//   1,000 ≤ 值 < 1M   → 货币符号 + K 单位（1位小数）：¥1.5K
//   值 ≥ 1,000,000    → 货币符号 + M 单位（1位小数）：¥1.5M
// ========================================
    VAR __Value = [Cost amt Value]
    VAR __CurrencySymbol = SELECTEDVALUE(Slicer_Currency_Selection[Currency_Symbol], "¥")
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            IF(
                __Value < 1000,
                __CurrencySymbol & FORMAT(__Value, "#,##0"),
                IF(
                    __Value < 1000000,
                    __CurrencySymbol & FORMAT(__Value / 1000, "#,##0.0") & "K",
                    __CurrencySymbol & FORMAT(__Value / 1000000, "#,##0.0") & "M"
                )
            )
        )
```
### 2.6 Cost amt Un controllable%（自己额外新增）

```dax
Cost amt Un controllable% Value = 
// ========================================
// 度量值: Cost amt Un controllable% Value
// Display Folder: Controllable Trend
// 用途: 广告花费占比趋势值（矩阵柱形图/趋势图 Y 轴）
// 基础: 基于 [Cost amt Value] 计算
// 计算公式: [Cost amt Value] / 移除 Un_Controllable_Group 维度的 [Cost amt Value]
//   分子: [Cost amt Value]（保持原计算方式不变）
//   分母: [Cost amt Value]，但移除 Un_Controllable_Group 维度的筛选
//         移除范围包括：行维度 + 筛选器对 Un_Controllable_Group 字段的筛选
// 数据类型: percent_0dp → 百分比整数，不含正号
// 矩阵场景: 同时应用全局月份筛选 + X轴当前月份筛选（继承自 Cost amt Value）
// 占比指标：分子分母均含汇率转换，结果不受汇率影响
// ========================================
    // ── 分子：Cost amt Value（保持原计算方式不变）──
    VAR __Numerator = [Cost amt Value]
    // ── 分母：移除 Un_Controllable_Group 维度的 Cost amt Value ──
    // REMOVEFILTERS 移除该列上的所有筛选，包括行维度和筛选器筛选
    VAR __Denominator =
        CALCULATE(
            [Cost amt Value],
            REMOVEFILTERS('a05_e2e_paid_media_summary_d'[Un_Controllable_Group])
        )
    RETURN
        DIVIDE(__Numerator, __Denominator)
```

```dax
Cost amt Un controllable% Display = 
// ========================================
// 度量值: Cost amt Un controllable% Display
// Display Folder: Controllable Trend
// 用途: 广告花费占比格式化显示
// 依赖: [Cost amt Un controllable% Value]
// 格式类型: percent_0dp → 百分比整数，不含正号
// 格式串: #,##0%;#,##0%;0%
// ========================================
    VAR __Value = [Cost amt Un controllable% Value]
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            FORMAT(__Value, "#,##0%;#,##0%;0%")
        )
```

---

## 3. 度量值清单与 Display Folder

| 序号 | 度量值名称                    | Display Folder     | 用途                       | 数据类型            | 是否金额类 |
| ---- | ----------------------------- | ------------------ | -------------------------- | ------------------- | ---------- |
| 1    | Controllable% Value           | Controllable Trend | 可控花费占比值（#2）       | percent_0dp         | 否         |
| 2    | Controllable% Display         | Controllable Trend | 可控花费占比格式化显示     | percent_0dp         | 否         |
| 3    | Uncontrollable% Value         | Controllable Trend | 不可控花费占比值（#3）     | percent_0dp         | 否         |
| 4    | Uncontrollable% Display       | Controllable Trend | 不可控花费占比格式化显示   | percent_0dp         | 否         |
| 5    | Controllable Cost Value       | Controllable Trend | 可控广告花费值（#4）       | currency_M_K_Int_0db | 是         |
| 6    | Controllable Cost Display     | Controllable Trend | 可控广告花费格式化显示     | currency_M_K_Int_0db | 是         |
| 7    | Uncontrollable Cost Value     | Controllable Trend | 不可控广告花费值（#5）     | currency_M_K_Int_0db | 是         |
| 8    | Uncontrollable Cost Display   | Controllable Trend | 不可控广告花费格式化显示   | currency_M_K_Int_0db | 是         |

---

## 4. 指标口径来源对照

| Metric_ID | Metric Name          | 口径文档出处   | 计算公式                                   | 统计字段                    | customer_type | is_controllable_channel | 数据类型            | 是否金额类 |
| --------- | -------------------- | -------------- | ------------------------------------------ | --------------------------- | ------------- | ----------------------- | ------------------- | ---------- |
| 2         | Controllable%        | 子模块三 §2    | 可控 Cost / TTL Cost                       | cost_amt                    | ALL           | 分子 "1" / 分母 {"0","1"} | percent_0dp         | 否         |
| 3         | Uncontrollable%      | 子模块三 §3    | 不可控 Cost / TTL Cost                     | cost_amt                    | ALL           | 分子 "0" / 分母 {"0","1"} | percent_0dp         | 否         |
| 4         | Controllable Cost    | 子模块三 §4    | SUM(cost_amt), is_controllable_channel="1" | cost_amt                    | ALL           | "1"                     | currency_M_K_Int_0db | 是         |
| 5         | Uncontrollable Cost  | 子模块三 §5    | SUM(cost_amt), is_controllable_channel="0" | cost_amt                    | ALL           | "0"                     | currency_M_K_Int_0db | 是         |

---

## 5. 血缘关系图（Lineage Diagram）

```
┌─────────────────────────────────────────────────────────────────────┐
│                        数据源层                                      │
│  a05_e2e_paid_media_summary_d（事实表）                              │
│  字段: data_date, platform, store_name, trans_cycle,                │
│        customer_type, page_type, is_controllable_channel,           │
│        cost_amt                                                     │
└──────────────────────────────┬──────────────────────────────────────┘
                               │
                               │ 1:N 关系（模型自动筛选）
                               │
              ┌────────────────┼────────────────┐
              │                │                │
              ▼                ▼                ▼
┌──────────────────┐ ┌──────────────────┐ ┌──────────────────┐
│ Slicer_Platform_  │ │ Slicer_Store_    │ │ trans_cycle     │
│ Selection         │ │ Name             │ │ 筛选器           │
│ (Platform_ID)     │ │ (Store_ID)       │ │ (trans_cycle)   │
└──────────────────┘ └──────────────────┘ └──────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│                        度量值层                                      │
│                                                                     │
│  ┌─────────────────────────────────────────────┐                    │
│  │  Slicer_Month_Period_Min / Max（断开维度）   │                    │
│  │  → __TimeMin / __TimeMax 全局起止月份筛选    │                    │
│  └─────────────────────────────────────────────┘                    │
│                                                                     │
│  ┌─────────────────────────────────────────────┐                    │
│  │  Slicer_Month_Period（断开维度，X轴上下文）   │                    │
│  │  → __CurrentMonthMin / __CurrentMonthMax     │                    │
│  │  → 当前X轴遍历月份的自然日范围               │                    │
│  └─────────────────────────────────────────────┘                    │
│                                                                     │
│  ┌─────────────────────────────────────────────┐                    │
│  │  Slicer_Currency_Selection（断开维度）       │                    │
│  │  → __FXRate 汇率（仅金额类指标 #4/#5 使用）  │                    │
│  │  → 人民币转美元，金额 ÷ FXRate              │                    │
│  │  → __CurrencySymbol 货币符号（Display 拼接） │                    │
│  └─────────────────────────────────────────────┘                    │
│                                                                     │
│  子模块三：Controllable Ads Format Cost% Trend                       │
│  ┌─────────────────────────┐  ┌─────────────────────────┐           │
│  │ Controllable% Value     │  │ Controllable% Display   │           │
│  │ (#2 可控/TTL)            │→ │ (percent_0dp)            │           │
│  └─────────────────────────┘  └─────────────────────────┘           │
│  ┌─────────────────────────┐  ┌─────────────────────────┐           │
│  │ Uncontrollable% Value   │  │ Uncontrollable% Display │           │
│  │ (#3 不可控/TTL)          │→ │ (percent_0dp)            │           │
│  └─────────────────────────┘  └─────────────────────────┘           │
│  ┌─────────────────────────┐  ┌─────────────────────────┐           │
│  │ Controllable Cost Value │  │ Controllable Cost Display│          │
│  │ (#4 可控 ÷FX)            │→ │ (K/M 单位切换)           │           │
│  └─────────────────────────┘  └─────────────────────────┘           │
│  ┌─────────────────────────┐  ┌─────────────────────────┐           │
│  │ Uncontrollable Cost     │  │ Uncontrollable Cost     │           │
│  │ Value (#5 不可控 ÷FX)    │→ │ Display (K/M 单位切换)   │           │
│  └─────────────────────────┘  └─────────────────────────┘           │
└─────────────────────────────────────────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────────┐
│                        可视化层                                      │
│  矩阵柱形图 / 折线图（趋势图）                                       │
│  X 轴: Slicer_Month_Period 月份（提供 X 轴上下文）                   │
│  Y 轴: [* Value] 度量值                                             │
│  工具提示: [* Display] 格式化文本                                    │
│  说明: 每个度量同时应用两层时间筛选                                  │
│    1. 全局筛选（Slicer_Month_Period_Min/Max）                       │
│    2. X轴当前月份筛选（Slicer_Month_Period）                        │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 6. 关键设计说明

### 6.1 格式类型说明

| 格式类型             | 适用指标   | 格式规则                                                    |
| -------------------- | ---------- | ----------------------------------------------------------- |
| currency_M_K_Int_0db | #4、#5     | <1K 千分位整数；≥1K 用 K（1位小数）；≥1M 用 M（1位小数）    |
| percent_0dp          | #2、#3     | 百分比整数，不含正号，格式串 `#,##0%;#,##0%;0%`            |

### 6.2 金额类指标与汇率转换

仅 #4（Controllable Cost）和 #5（Uncontrollable Cost）为金额类指标。

- **汇率方向**：人民币转美元，使用**除法** `DIVIDE(value, __FXRate)`
- `Slicer_Currency_Selection[Currency_ExchangeRate]`：RMB=1, USD=7
- 底表数据为人民币，选择 USD 时除以 7 转为美元
- #2、#3 为占比指标，不受汇率影响

### 6.3 矩阵两层时间筛选机制

本模块为矩阵柱形图/趋势图，每个度量值同时应用两层时间筛选：

| 筛选器                     | 作用                                     | 变量名                |
| -------------------------- | ---------------------------------------- | --------------------- |
| Slicer_Month_Period_Min    | 全局起止月份切片器（用户选择的时间范围） | __TimeMin             |
| Slicer_Month_Period_Max    | 全局起止月份切片器（用户选择的时间范围） | __TimeMax             |
| Slicer_Month_Period        | X 轴当前遍历月份的自然日范围             | __CurrentMonthMin/Max |

**筛选逻辑**：`data_date >= __TimeMin AND data_date <= __TimeMax AND data_date >= __CurrentMonthMin AND data_date <= __CurrentMonthMax`

全局筛选器限制整体数据范围，X 轴上下文筛选器让每个柱子只计算该月份的数据，实现按月趋势展示。

### 6.4 筛选器公用说明

本模块与全看板其他模块共用筛选器：

- **Slicer_Month_Period_Min/Max**：断开维度，全局起止月份范围
- **Slicer_Month_Period**：断开维度，X 轴当前遍历月份（矩阵上下文）
- **Slicer_Platform_Selection**：1:N 关系，模型自动筛选（注意 TM/JD 渠道映射：直通车↔快车、引力魔方↔触点、全站推↔海投）
- **Slicer_Store_Name**：1:N 关系，模型自动筛选
- **Slicer_Currency_Selection**：断开维度，仅金额类指标（#4/#5）除以汇率
- **trans_cycle**：1:N 关系，模型自动筛选

### 6.5 趋势图/柱形图使用方式

- **Y 轴**：使用 `[* Value]` 度量值（数值类型，供图表渲染）
- **工具提示**：使用 `[* Display]` 度量值（文本类型，格式化展示）
- **X 轴**：使用 `Slicer_Month_Period` 月份维度（提供 X 轴上下文筛选）

### 6.6 is_controllable_channel 字段类型说明

口径文档存在两处表述：
- "筛选条件"栏：`is_controllable_channel="1"`（字符串）
- "DAX 语法规范"示例：`[is_controllable_channel] = 1`（整数）

本方案按"筛选条件"栏的**字符串**口径处理（`"1"`/`"0"`）。若实际表中该字段为整数类型，需将 DAX 中的 `"1"`/`"0"` 改为 `1`/`0`。
