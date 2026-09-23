# KPIs_Measure_solution 解决方案

> status: updated
> created: 2026-07-15
> complexity: 🟡中等
> type: 度量值开发
> naming: 遵循 dax-style.md 规范
> 口径来源: New Acquisition实际使用版本.md（子模块二 #1、子模块四 #6~#9、子模块五 #10~#13）

---

## 1. 需求理解

实现 New Acquisition 看板中 9 个指标的卡片图展示：

- **适用场景**：卡片图（无 X 轴，无矩阵行上下文），每个指标独立编写 Value / Display 度量
- **口径**：一切以口径文档 New Acquisition实际使用版本.md 为准
- **时间筛选**：使用 `Slicer_Time_Frame_Min`、`Slicer_Time_Frame_Max`（断开维度，SELECTEDVALUE），全局日期筛选
- **汇率方向**：人民币转美元，金额类指标**除以** `Currency_ExchangeRate`（RMB=1, USD=7）
- **数据底表分布**：
  - #1 Media Cost → `a05_e2e_paid_media_summary_d`（汇总表，有 page_type 筛选）
  - #6~#9 引力魔方下钻 → `a05_e2e_paid_media_crowed_data_d`（下钻表，无 page_type 筛选）
  - #10~#13 直通车下钻 → `a05_e2e_paid_media_keyword_data_d`（下钻表，无 page_type 筛选）
- **数据格式**：
  - `currency_M_K_Int_0db` → 货币符号 + K/M 单位切换（#1）
  - `currency` → 货币符号 + 千分位整数（#6、#10）
  - `percent_0dp` → 百分比整数（#7、#11）
  - `percent_1dp` → 百分比一位小数（#8、#12）
  - `decimal_1dp` → 数值一位小数（#9、#13）

---

## 2. 度量值实现

### 2.1 Media Cost（#1）

```dax
Media Cost Value = 
// ========================================
// 度量值: Media Cost Value
// Display Folder: KPIs Measure
// 用途: 各平台实际媒体花费（卡片图）
// 口径来源: New Acquisition实际使用版本.md 子模块二 §1
// 计算公式: SUM(cost_amt)
// 统计字段: cost_amt
// 数据底表: a05_e2e_paid_media_summary_d
// 筛选条件: customer_type='ALL' AND page_type="1"
// 数据类型: currency_M_K_Int_0db（金额类指标，需汇率转换）
// 汇率方向: 人民币转美元，除以 Currency_ExchangeRate
// ========================================
    // ── 时间筛选：本期 ──
    VAR __TimeMin = SELECTEDVALUE(Slicer_Time_Frame_Min[TimeFrame_Min])
    VAR __TimeMax = SELECTEDVALUE(Slicer_Time_Frame_Max[TimeFrame_Max])
    // ── 汇率（金额类指标需要除以汇率）──
    VAR __FXRate = SELECTEDVALUE(Slicer_Currency_Selection[Currency_ExchangeRate], 1)
    VAR __MediaCost =
        CALCULATE(
            SUM('a05_e2e_paid_media_summary_d'[cost_amt]),
            'a05_e2e_paid_media_summary_d'[customer_type] = "ALL",
            'a05_e2e_paid_media_summary_d'[page_type] = "1",
            'a05_e2e_paid_media_summary_d'[data_date] >= __TimeMin,
            'a05_e2e_paid_media_summary_d'[data_date] <= __TimeMax
        )
    RETURN
        DIVIDE(__MediaCost, __FXRate)
```

```dax
Media Cost Display = 
// ========================================
// 度量值: Media Cost Display
// Display Folder: KPIs Measure
// 用途: 媒体花费格式化显示（K/M 单位切换）
// 依赖: [Media Cost Value], Slicer_Currency_Selection
// 格式类型: currency_M_K_Int_0db
//   值 < 1,000        → 货币符号 + 千分位整数：¥999
//   1,000 ≤ 值 < 1M   → 货币符号 + K 单位（1位小数）：¥1.5K
//   值 ≥ 1,000,000    → 货币符号 + M 单位（1位小数）：¥1.5M
// ========================================
    VAR __Value = [Media Cost Value]
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

### 2.2 Cost — 引力魔方（#6）

```dax
Cost 引力魔方 Value = 
// ========================================
// 度量值: Cost 引力魔方 Value
// Display Folder: KPIs Measure
// 用途: 引力魔方 TA/新老/OAIPL 层级花费（卡片图）
// 口径来源: New Acquisition实际使用版本.md 子模块四 §6
// 计算公式: SUM(cost_amt), channel in {"引力魔方","触点"}
// 统计字段: cost_amt
// 数据底表: a05_e2e_paid_media_crowed_data_d（下钻表，无 page_type 筛选）
// 筛选条件: channel in {"引力魔方","触点"}
// 数据类型: currency（金额类指标，需汇率转换）
// 汇率方向: 人民币转美元，除以 Currency_ExchangeRate
// ========================================
    // ── 时间筛选：本期 ──
    VAR __TimeMin = SELECTEDVALUE(Slicer_Time_Frame_Min[TimeFrame_Min])
    VAR __TimeMax = SELECTEDVALUE(Slicer_Time_Frame_Max[TimeFrame_Max])
    // ── 汇率（金额类指标需要除以汇率）──
    VAR __FXRate = SELECTEDVALUE(Slicer_Currency_Selection[Currency_ExchangeRate], 1)
    VAR __CostYlmf =
        CALCULATE(
            SUM('a05_e2e_paid_media_crowed_data_d'[cost_amt]),
            'a05_e2e_paid_media_crowed_data_d'[channel] in {"引力魔方","触点"},
            'a05_e2e_paid_media_crowed_data_d'[data_date] >= __TimeMin,
            'a05_e2e_paid_media_crowed_data_d'[data_date] <= __TimeMax
        )
    RETURN
        DIVIDE(__CostYlmf, __FXRate)
```

```dax
Cost 引力魔方 Display = 
// ========================================
// 度量值: Cost 引力魔方 Display
// Display Folder: KPIs Measure
// 用途: 引力魔方花费格式化显示（千分位整数）
// 依赖: [Cost 引力魔方 Value], Slicer_Currency_Selection
// 格式类型: currency → 货币符号 + 千分位整数
// 格式串: #,##0
// ========================================
    VAR __Value = [Cost 引力魔方 Value]
    VAR __CurrencySymbol = SELECTEDVALUE(Slicer_Currency_Selection[Currency_Symbol], "¥")
    RETURN
        IF(
            ISBLANK(__Value),
            BLANK(),
            __CurrencySymbol & FORMAT(__Value, "#,##0")
        )
```

### 2.3 Cost 引力魔方 触点占比（#7）

```dax
Cost 引力魔方 触点占比 Value = 
// ========================================
// 度量值: Cost 引力魔方 触点占比 Value
// Display Folder: KPIs Measure
// 用途: (引力魔方/触点) / (引力魔方/触点 + 直通车/快车) 占比（卡片图）
// 口径来源: New Acquisition实际使用版本.md 子模块四 §7
// 计算公式: cost_amt(引力魔方/触点) / cost_amt(引力魔方/触点+直通车/快车)
// 统计字段: cost_amt
// 数据底表: a05_e2e_paid_media_crowed_data_d
// 筛选条件:
//   分子: channel IN {'引力魔方','触点'}
//   分母: channel IN {'引力魔方','直通车','快车','触点'}
// 平台映射: TM引力魔方↔JD触点, TM直通车↔JD快车（platform筛选器自动映射）
// 数据类型: percent_0dp → 百分比整数，不含正号
// ========================================
    // ── 时间筛选：本期 ──
    VAR __TimeMin = SELECTEDVALUE(Slicer_Time_Frame_Min[TimeFrame_Min])
    VAR __TimeMax = SELECTEDVALUE(Slicer_Time_Frame_Max[TimeFrame_Max])
    // ── 分子：引力魔方/触点 花费 ──
    VAR __Numerator =
        CALCULATE(
            SUM('a05_e2e_paid_media_crowed_data_d'[cost_amt]),
            'a05_e2e_paid_media_crowed_data_d'[channel] IN {"引力魔方", "触点"},
            'a05_e2e_paid_media_crowed_data_d'[data_date] >= __TimeMin,
            'a05_e2e_paid_media_crowed_data_d'[data_date] <= __TimeMax
        )
    // ── 分母：引力魔方/触点 + 直通车/快车 花费 ──
    VAR __Denominator =
        CALCULATE(
            SUM('a05_e2e_paid_media_crowed_data_d'[cost_amt]),
            'a05_e2e_paid_media_crowed_data_d'[channel] IN {"引力魔方", "直通车", "快车", "触点"},
            'a05_e2e_paid_media_crowed_data_d'[data_date] >= __TimeMin,
            'a05_e2e_paid_media_crowed_data_d'[data_date] <= __TimeMax
        )
    RETURN
        DIVIDE(__Numerator, __Denominator)
```

```dax
Cost 引力魔方 触点占比 Display = 
// ========================================
// 度量值: Cost 引力魔方 触点占比 Display
// Display Folder: KPIs Measure
// 用途: 引力魔方触点占比格式化显示
// 依赖: [Cost 引力魔方 触点占比 Value]
// 格式类型: percent_0dp → 百分比整数，不含正号
// 格式串: #,##0%;#,##0%;0%
// ========================================
    VAR __Value = [Cost 引力魔方 触点占比 Value]
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            FORMAT(__Value, "#,##0%;-#,##0%;0%")
        )
```

### 2.4 Cost% — 引力魔方（#8）

```dax
Cost% 引力魔方 Value = 
// ========================================
// 度量值: Cost% 引力魔方 Value
// Display Folder: KPIs Measure
// 用途: 引力魔方 TA/新老/OAIPL 层级花费占比（卡片图）
// 口径来源: New Acquisition实际使用版本.md 子模块四 §8
// 计算公式: TA层级引力魔方 Cost / TTL Cost
//   分子: cost_amt（该 TA 层级，受行维度筛选）
//   分母: cost_amt（该广告点位 TA 合计，移除所有行维度）
// 数据底表: a05_e2e_paid_media_crowed_data_d
// 筛选条件: channel in {"引力魔方","触点"}
// 数据类型: percent_1dp → 百分比一位小数，不含正号
// 说明: 分母用 REMOVEFILTERS 移除行维度（customer_type/crowed_layer/crowed_type
//       卡片图场景下无行维度，REMOVEFILTERS 不影响结果，但保证矩阵场景兼容
// ========================================
    // ── 时间筛选：本期 ──
    VAR __TimeMin = SELECTEDVALUE(Slicer_Time_Frame_Min[TimeFrame_Min])
    VAR __TimeMax = SELECTEDVALUE(Slicer_Time_Frame_Max[TimeFrame_Max])
    // ── 分子：该 TA 层级引力魔方 Cost（受行维度筛选）──
    VAR __Numerator =
        CALCULATE(
            SUM('a05_e2e_paid_media_crowed_data_d'[cost_amt]),
            'a05_e2e_paid_media_crowed_data_d'[channel] in {"引力魔方","触点"},
            'a05_e2e_paid_media_crowed_data_d'[data_date] >= __TimeMin,
            'a05_e2e_paid_media_crowed_data_d'[data_date] <= __TimeMax
        )
    // ── 分母：该广告点位 TA 合计（移除所有行维度）──
    VAR __Denominator =
        CALCULATE(
            SUM('a05_e2e_paid_media_crowed_data_d'[cost_amt]),
            'a05_e2e_paid_media_crowed_data_d'[channel] in {"引力魔方","触点"},
            'a05_e2e_paid_media_crowed_data_d'[data_date] >= __TimeMin,
            'a05_e2e_paid_media_crowed_data_d'[data_date] <= __TimeMax,
            REMOVEFILTERS(
                'a05_e2e_paid_media_crowed_data_d'[crowed_layer],
                'a05_e2e_paid_media_crowed_data_d'[crowed_type],
                'a05_e2e_paid_media_crowed_data_d'[customer_type]
            )
        )
    RETURN
        DIVIDE(__Numerator, __Denominator)
```

```dax
Cost% 引力魔方 Display = 
// ========================================
// 度量值: Cost% 引力魔方 Display
// Display Folder: KPIs Measure
// 用途: 引力魔方花费占比格式化显示
// 依赖: [Cost% 引力魔方 Value]
// 格式类型: percent_1dp → 百分比一位小数，不含正号
// 格式串: #,##0.0%;-#,##0.0%;0.0%
// ========================================
    VAR __Value = [Cost% 引力魔方 Value]
    RETURN
        IF(
            ISBLANK(__Value),
            BLANK(),
            FORMAT(__Value, "#,##0.0%;-#,##0.0%;0.0%")
        )
```

### 2.5 ROI — 引力魔方（#9）

```dax
ROI 引力魔方 Value = 
// ========================================
// 度量值: ROI 引力魔方 Value
// Display Folder: KPIs Measure
// 用途: 引力魔方 TA/新老/OAIPL 层级 ROI（卡片图）
// 口径来源: New Acquisition实际使用版本.md 子模块四 §9
// 计算公式: 引力魔方 TA 层级 Sales / Cost
//   分子: media_sales_amt（引力魔方 TA 层级成交金额）
//   分母: cost_amt（引力魔方 TA 层级花费）
// 数据底表: a05_e2e_paid_media_crowed_data_d
// 筛选条件: channel in {"引力魔方","触点"}
// 数据类型: decimal_1dp → 数值一位小数
// ========================================
    // ── 时间筛选：本期 ──
    VAR __TimeMin = SELECTEDVALUE(Slicer_Time_Frame_Min[TimeFrame_Min])
    VAR __TimeMax = SELECTEDVALUE(Slicer_Time_Frame_Max[TimeFrame_Max])
    // ── 分子：引力魔方 TA 层级 Sales ──
    VAR __Sales =
        CALCULATE(
            SUM('a05_e2e_paid_media_crowed_data_d'[media_sales_amt]),
            'a05_e2e_paid_media_crowed_data_d'[channel] in {"引力魔方","触点"},
            'a05_e2e_paid_media_crowed_data_d'[data_date] >= __TimeMin,
            'a05_e2e_paid_media_crowed_data_d'[data_date] <= __TimeMax
        )
    // ── 分母：引力魔方 TA 层级 Cost ──
    VAR __Cost =
        CALCULATE(
            SUM('a05_e2e_paid_media_crowed_data_d'[cost_amt]),
            'a05_e2e_paid_media_crowed_data_d'[channel] in {"引力魔方","触点"},
            'a05_e2e_paid_media_crowed_data_d'[data_date] >= __TimeMin,
            'a05_e2e_paid_media_crowed_data_d'[data_date] <= __TimeMax
        )
    RETURN
        DIVIDE(__Sales, __Cost)
```

```dax
ROI 引力魔方 Display = 
// ========================================
// 度量值: ROI 引力魔方 Display
// Display Folder: KPIs Measure
// 用途: 引力魔方 ROI 格式化显示
// 依赖: [ROI 引力魔方 Value]
// 格式类型: decimal_1dp → 数值一位小数
// 格式串: #,##0.0
// ========================================
    VAR __Value = [ROI 引力魔方 Value]
    RETURN
        IF(
            ISBLANK(__Value),
            BLANK(),
            FORMAT(__Value, "#,##0.0")
        )
```

### 2.6 Cost — 直通车（#10）

```dax
Cost 直通车 Value = 
// ========================================
// 度量值: Cost 直通车 Value
// Display Folder: KPIs Measure
// 用途: 直通车新老/计划层级花费（卡片图）
// 口径来源: New Acquisition实际使用版本.md 子模块五 §10
// 计算公式: SUM(cost_amt), channel in {"直通车","快车"}
// 统计字段: cost_amt
// 数据底表: a05_e2e_paid_media_keyword_data_d（下钻表，无 page_type 筛选）
// 筛选条件: channel in {"直通车","快车"}
// 数据类型: currency（金额类指标，需汇率转换）
// 汇率方向: 人民币转美元，除以 Currency_ExchangeRate
// ========================================
    // ── 时间筛选：本期 ──
    VAR __TimeMin = SELECTEDVALUE(Slicer_Time_Frame_Min[TimeFrame_Min])
    VAR __TimeMax = SELECTEDVALUE(Slicer_Time_Frame_Max[TimeFrame_Max])
    // ── 汇率（金额类指标需要除以汇率）──
    VAR __FXRate = SELECTEDVALUE(Slicer_Currency_Selection[Currency_ExchangeRate], 1)
    VAR __CostZtc =
        CALCULATE(
            SUM('a05_e2e_paid_media_keyword_data_d'[cost_amt]),
            'a05_e2e_paid_media_keyword_data_d'[channel] in {"直通车","快车"},
            'a05_e2e_paid_media_keyword_data_d'[data_date] >= __TimeMin,
            'a05_e2e_paid_media_keyword_data_d'[data_date] <= __TimeMax
        )
    RETURN
        DIVIDE(__CostZtc, __FXRate)
```

```dax
Cost 直通车 Display = 
// ========================================
// 度量值: Cost 直通车 Display
// Display Folder: KPIs Measure
// 用途: 直通车花费格式化显示（千分位整数）
// 依赖: [Cost 直通车 Value], Slicer_Currency_Selection
// 格式类型: currency → 货币符号 + 千分位整数
// 格式串: #,##0
// ========================================
    VAR __Value = [Cost 直通车 Value]
    VAR __CurrencySymbol = SELECTEDVALUE(Slicer_Currency_Selection[Currency_Symbol], "¥")
    RETURN
        IF(
            ISBLANK(__Value),
            BLANK(),
            __CurrencySymbol & FORMAT(__Value, "#,##0")
        )
```

### 2.7 Cost 直通车 快车占比（#11）

```dax
Cost 直通车 快车占比 Value = 
// ========================================
// 度量值: Cost 直通车 快车占比 Value
// Display Folder: KPIs Measure
// 用途: (直通车/快车) / (引力魔方/触点 + 直通车/快车) 占比（卡片图）
// 口径来源: New Acquisition实际使用版本.md 子模块五 §11
// 计算公式: cost_amt(直通车/快车) / cost_amt(引力魔方/触点+直通车/快车)
// 统计字段: cost_amt
// 数据底表: a05_e2e_paid_media_keyword_data_d
// 筛选条件:
//   分子: channel IN {'直通车','快车'}
//   分母: channel IN {'引力魔方','直通车','快车','触点'}
// 平台映射: TM引力魔方↔JD触点, TM直通车↔JD快车（platform筛选器自动映射）
// 数据类型: percent_0dp → 百分比整数，不含正号
// ========================================
    // ── 时间筛选：本期 ──
    VAR __TimeMin = SELECTEDVALUE(Slicer_Time_Frame_Min[TimeFrame_Min])
    VAR __TimeMax = SELECTEDVALUE(Slicer_Time_Frame_Max[TimeFrame_Max])
    // ── 分子：直通车/快车 花费 ──
    VAR __Numerator =
        CALCULATE(
            SUM('a05_e2e_paid_media_keyword_data_d'[cost_amt]),
            'a05_e2e_paid_media_keyword_data_d'[channel] IN {"直通车", "快车"},
            'a05_e2e_paid_media_keyword_data_d'[data_date] >= __TimeMin,
            'a05_e2e_paid_media_keyword_data_d'[data_date] <= __TimeMax
        )
    // ── 分母：引力魔方/触点 + 直通车/快车 花费 ──
    VAR __Denominator =
        CALCULATE(
            SUM('a05_e2e_paid_media_keyword_data_d'[cost_amt]),
            'a05_e2e_paid_media_keyword_data_d'[channel] IN {"引力魔方", "直通车", "快车", "触点"},
            'a05_e2e_paid_media_keyword_data_d'[data_date] >= __TimeMin,
            'a05_e2e_paid_media_keyword_data_d'[data_date] <= __TimeMax
        )
    RETURN
        DIVIDE(__Numerator, __Denominator)
```

```dax
Cost 直通车 快车占比 Display = 
// ========================================
// 度量值: Cost 直通车 快车占比 Display
// Display Folder: KPIs Measure
// 用途: 直通车快车占比格式化显示
// 依赖: [Cost 直通车 快车占比 Value]
// 格式类型: percent_0dp → 百分比整数，不含正号
// 格式串: #,##0%;#,##0%;0%
// ========================================
    VAR __Value = [Cost 直通车 快车占比 Value]
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            FORMAT(__Value, "#,##0%;-#,##0%;0%")
        )
```

### 2.8 Cost% — 直通车（#12）

```dax
Cost% 直通车 Value =
// ========================================
// 度量值: Cost% 直通车 Value
// 中文名: 直通车／快车各行层级花费占比
// Display Folder: KPIs Measure
// 用途: 当前行 Cost / 整个矩阵入选明细的 Cost 总额
// 数据底表: a05_e2e_paid_media_keyword_data_d
// 筛选条件: channel IN {"直通车", "快车"}；本期日期范围
// 行层级: TTL / customer_type / category / keyword_type / keyword_name
// 口径说明: ALLSELECTED 恢复视觉外层选择，所有父组共用一个分母
// 数据类型: percent_1dp；分子分母均用人民币原值，比值不需要汇率转换
// ========================================
    // ── 时间筛选：本期 ──
    VAR __TimeMin = SELECTEDVALUE(Slicer_Time_Frame_Min[TimeFrame_Min])
    VAR __TimeMax = SELECTEDVALUE(Slicer_Time_Frame_Max[TimeFrame_Max])
    // ── 分子：当前行层级直通车／快车 Cost ──
    VAR __Numerator =
        CALCULATE(
            SUM('a05_e2e_paid_media_keyword_data_d'[cost_amt]),
            'a05_e2e_paid_media_keyword_data_d'[channel] IN {"直通车", "快车"},
            'a05_e2e_paid_media_keyword_data_d'[data_date] >= __TimeMin,
            'a05_e2e_paid_media_keyword_data_d'[data_date] <= __TimeMax
        )
    // ── 分母：解除当前行定位，保留视觉外层入选组合及切片器筛选 ──
    VAR __Denominator =
        CALCULATE(
            SUM('a05_e2e_paid_media_keyword_data_d'[cost_amt]),
            'a05_e2e_paid_media_keyword_data_d'[channel] IN {"直通车", "快车"},
            'a05_e2e_paid_media_keyword_data_d'[data_date] >= __TimeMin,
            'a05_e2e_paid_media_keyword_data_d'[data_date] <= __TimeMax,
            ALLSELECTED(
                'a05_e2e_paid_media_keyword_data_d'[customer_type],
                'a05_e2e_paid_media_keyword_data_d'[category],
                'a05_e2e_paid_media_keyword_data_d'[keyword_type],
                'a05_e2e_paid_media_keyword_data_d'[keyword_name]
            )
        )
    RETURN
        DIVIDE(__Numerator, __Denominator)
```

```dax
Cost% 直通车 Display = 
// ========================================
// 度量值: Cost% 直通车 Display
// Display Folder: KPIs Measure
// 用途: 直通车花费占比格式化显示
// 依赖: [Cost% 直通车 Value]
// 格式类型: percent_1dp → 百分比一位小数，不含正号
// 格式串: #,##0.0%;-#,##0.0%;0.0%
// ========================================
    VAR __Value = [Cost% 直通车 Value]
    RETURN
        IF(
            ISBLANK(__Value),
            BLANK(),
            FORMAT(__Value, "#,##0.0%;-#,##0.0%;0.0%")
        )
```

### 2.9 ROI — 直通车（#13）

```dax
ROI 直通车 Value = 
// ========================================
// 度量值: ROI 直通车 Value
// Display Folder: KPIs Measure
// 用途: 直通车关键词/计划层级 ROI（卡片图）
// 口径来源: New Acquisition实际使用版本.md 子模块五 §13
// 计算公式: 直通车关键词层级 Sales / Cost
//   分子: media_sales_amt（直通车关键词层级成交金额）
//   分母: cost_amt（直通车关键词层级花费）
// 数据底表: a05_e2e_paid_media_keyword_data_d
// 筛选条件: channel in {"直通车","快车"}
// 数据类型: decimal_1dp → 数值一位小数
// ========================================
    // ── 时间筛选：本期 ──
    VAR __TimeMin = SELECTEDVALUE(Slicer_Time_Frame_Min[TimeFrame_Min])
    VAR __TimeMax = SELECTEDVALUE(Slicer_Time_Frame_Max[TimeFrame_Max])
    // ── 分子：直通车关键词层级 Sales ──
    VAR __Sales =
        CALCULATE(
            SUM('a05_e2e_paid_media_keyword_data_d'[media_sales_amt]),
            'a05_e2e_paid_media_keyword_data_d'[channel] in {"直通车","快车"},
            'a05_e2e_paid_media_keyword_data_d'[data_date] >= __TimeMin,
            'a05_e2e_paid_media_keyword_data_d'[data_date] <= __TimeMax
        )
    // ── 分母：直通车关键词层级 Cost ──
    VAR __Cost =
        CALCULATE(
            SUM('a05_e2e_paid_media_keyword_data_d'[cost_amt]),
            'a05_e2e_paid_media_keyword_data_d'[channel] in {"直通车","快车"},
            'a05_e2e_paid_media_keyword_data_d'[data_date] >= __TimeMin,
            'a05_e2e_paid_media_keyword_data_d'[data_date] <= __TimeMax
        )
    RETURN
        DIVIDE(__Sales, __Cost)
```

```dax
ROI 直通车 Display = 
// ========================================
// 度量值: ROI 直通车 Display
// Display Folder: KPIs Measure
// 用途: 直通车 ROI 格式化显示
// 依赖: [ROI 直通车 Value]
// 格式类型: decimal_1dp → 数值一位小数
// 格式串: #,##0.0
// ========================================
    VAR __Value = [ROI 直通车 Value]
    RETURN
        IF(
            ISBLANK(__Value),
            BLANK(),
            FORMAT(__Value, "#,##0.0")
        )
```

### 2.10 TM 直通车-->JD 快车\TM 引力魔方-->JD 触点

```dax
TM 引力魔方-->JD 触点 = 
    // ── 店铺筛选： ──
    VAR __Store_ID = SELECTEDVALUE(Slicer_Store_Name[Store_ID])
      
    RETURN
        SWITCH(__Store_ID,
            "TM","引力魔方",
            "JD","触点",
            "-"
        )
```

```dax
TM 直通车-->JD 快车 = 
    // ── 店铺筛选： ──
    VAR __Store_ID = SELECTEDVALUE(Slicer_Store_Name[Store_ID])
      
    RETURN
        SWITCH(__Store_ID,
            "TM","直通车",
            "JD","快车",
            "-"
        )
```

### 2.11 字段筛选任一不为空&&空字符，即显示

```dax
IsAnyCrowedNotEmpty = 
/*
功能：实现跨字段并集（OR）筛选
逻辑：三个字段中任一字段"不为空"（既非 BLANK 也非空字符串 ""）即显示
返回：1（显示）或 0（隐藏）
*/

// 步骤1：获取当前上下文中各字段的值（行粒度下 MAX 即当前行的值）
VAR LayerValue = MAX('a05_e2e_paid_media_crowed_data_d'[crowed_layer])
VAR NameValue  = MAX('a05_e2e_paid_media_crowed_data_d'[customer_type])
VAR TypeValue  = MAX('a05_e2e_paid_media_crowed_data_d'[crowed_type])

// 步骤2：逐字段判断"有效"= 不为 BLANK 且 不为空字符串
VAR IsLayerValid = NOT ISBLANK(LayerValue) && LayerValue <> ""
VAR IsNameValid  = NOT ISBLANK(NameValue)  && NameValue  <> ""
VAR IsTypeValid  = NOT ISBLANK(TypeValue)  && TypeValue  <> ""

// 步骤3：并集（OR）—— 任一字段有效即显示
RETURN
    IF(
        IsLayerValid || IsNameValid || IsTypeValid,
        1,  // 任一不为空：显示
        0   // 全为空：隐藏
    )
```

```dax
IsAnyKeywordNotEmpty =
// ========================================
// 度量值: IsAnyKeywordNotEmpty
// 中文名: 直通车／快车行字段有效性筛选
// Display Folder: KPIs Measure
// 用途: 四个行字段中任一字段有效即显示，返回 1 或 0
// 口径说明: 四个行字段采用 OR 判断；keyword_name 使用 TRIM 排除空白字符串
// ========================================
    // ── 获取当前行上下文中的字段值 ──
    VAR CustomerTypeValue = MAX('a05_e2e_paid_media_keyword_data_d'[customer_type])
    VAR CategoryValue = MAX('a05_e2e_paid_media_keyword_data_d'[category])
    VAR KeywordTypeValue = MAX('a05_e2e_paid_media_keyword_data_d'[keyword_type])
    VAR KeywordNameValue = MAX('a05_e2e_paid_media_keyword_data_d'[keyword_name])
    // ── 判断各字段有效性 ──
    VAR IsCustomerTypeValid = NOT ISBLANK(CustomerTypeValue) && CustomerTypeValue <> ""
    VAR IsCategoryValid = NOT ISBLANK(CategoryValue) && CategoryValue <> ""
    VAR IsKeywordTypeValid = NOT ISBLANK(KeywordTypeValue) && KeywordTypeValue <> ""
    VAR IsKeywordNameValid =
        NOT ISBLANK(KeywordNameValue)
            && TRIM(KeywordNameValue) <> ""
            && TRIM(KeywordNameValue) <> " "
    // ── 并集（OR）：任一字段有效即显示 ──
    RETURN
        IF(
            IsCustomerTypeValid || IsCategoryValid || IsKeywordTypeValid || IsKeywordNameValid,
            1,
            0
        )
// 核对点：仅 keyword_type 非空时返回 1；四个行字段全部无效时返回 0。
// 本度量只负责字段有效性，不承担 Top10 筛选。

```

### 2.12 度量加起来等于 0 的行过滤

```dax
引力魔方 IsZero = 
VAR _Total = 
    COALESCE([Cost 引力魔方 Value], 0) +
    COALESCE([Cost% 引力魔方 Value], 0) +
    COALESCE([ROI 引力魔方 Value], 0)
RETURN
    IF(_Total = 0, 0, 1)
```

```dax
直通车 IsZero = 
VAR _Total = 
    COALESCE([Cost 直通车 Value], 0) +
    COALESCE([Cost% 直通车 Value], 0) +
    COALESCE([ROI 直通车 Value], 0)
RETURN
    IF(_Total = 0, 0, 1)
```

### 2.13 Cost 排名与 Top10 显示筛选 — 引力魔方／触点

```dax
Cost 引力魔方 Rank =
// ========================================
// 度量值: Cost 引力魔方 Rank
// 中文名: 引力魔方／触点人群名称花费排名
// Display Folder: KPIs Measure
// 用途: 固定 customer_type + crowed_layer，在该组内排名各 crowed_type
// 依赖: [Cost 引力魔方 Value]
// 行层级: customer_type / crowed_layer / crowed_type
// 口径说明: 每个父组独立按 Cost 降序、SKIP 排名，不计算全矩阵统一排名
// 计算方式: 显式匹配父组，按候选完整组合逐项计算 Cost
// 外部筛选: 保留平台、店铺、日期、转化周期及行字段的外部选择
// ========================================
    // ── 识别末级，并确保能唯一确定当前父组 ──
    VAR __IsDetail = ISINSCOPE('a05_e2e_paid_media_crowed_data_d'[crowed_type])
    VAR __HasParentGroup =
        HASONEVALUE('a05_e2e_paid_media_crowed_data_d'[customer_type])
            && HASONEVALUE('a05_e2e_paid_media_crowed_data_d'[crowed_layer])
    VAR __CustomerType = SELECTEDVALUE('a05_e2e_paid_media_crowed_data_d'[customer_type])
    VAR __CrowedLayer = SELECTEDVALUE('a05_e2e_paid_media_crowed_data_d'[crowed_layer])
    RETURN
        IF(
            __IsDetail && __HasParentGroup,
            VAR __CurrentCost = [Cost 引力魔方 Value]
            // ── 第一步：恢复外部选择范围内的行组合，再显式限定当前父组 ──
            VAR __GroupRows =
                FILTER(
                    ALLSELECTED(
                        'a05_e2e_paid_media_crowed_data_d'[customer_type],
                        'a05_e2e_paid_media_crowed_data_d'[crowed_layer],
                        'a05_e2e_paid_media_crowed_data_d'[crowed_type]
                    ),
                    'a05_e2e_paid_media_crowed_data_d'[customer_type] == __CustomerType
                        && 'a05_e2e_paid_media_crowed_data_d'[crowed_layer] == __CrowedLayer
                )
            // ── 第二步：清除当前明细行筛选，以候选完整组合逐行重新计算 Cost ──
            // __GroupRows 已在外部上下文中确定，不会因下方 REMOVEFILTERS 变成全表。
            // 完整列血缘 + 度量上下文转换也会覆盖同列筛选；清理步骤的作用详见第 3 节。
            VAR __RankTable =
                CALCULATETABLE(
                    FILTER(
                        ADDCOLUMNS(
                            __GroupRows,
                            "@RankCost", [Cost 引力魔方 Value]
                        ),
                        NOT ISBLANK([@RankCost])
                    ),
                    REMOVEFILTERS(
                        'a05_e2e_paid_media_crowed_data_d'[customer_type],
                        'a05_e2e_paid_media_crowed_data_d'[crowed_layer],
                        'a05_e2e_paid_media_crowed_data_d'[crowed_type]
                    )
                )
            // ── 第三步：RANKX 的候选表仅包含当前组，不会与其他父组竞争 ──
            RETURN
                IF(
                    NOT ISBLANK(__CurrentCost),
                    RANKX(__RankTable, [@RankCost], __CurrentCost, DESC, SKIP),
                    BLANK()
                ),
            BLANK()
        )
// 层级判断：crowed_type 明细且父组唯一 → 组内排名；父级／TTL → BLANK()。
// 严格相等 == 区分 BLANK() 和空字符串；不能用“父组值为空”判断是否处于父级。
// 候选表保留三列数据血缘，度量引用自动上下文转换，按完整组合计算 Cost。
// 验证：New/OA、New/I、Old/OA 各有 12 个不并列明细 → 各留 10 个，共 30 个明细。
// 同名 crowed_type 在不同父组分别排名；各组均从 1 重新开始。
// 空 Cost 不参与排名；0、负值及名称空值不额外剔除，沿用现有过滤配置。
// 单组示例：Cost=100,100,90,80,80,70 → Rank=1,1,3,4,4,6。
// 排名依据未格式化的 Cost；显示整数相同不代表实际 Cost 完全相等。
```

```dax
引力魔方 Top10 Show Row =
// ========================================
// 度量值: 引力魔方 Top10 Show Row
// 中文名: 引力魔方／触点 Top10 行显示筛选
// Display Folder: KPIs Measure
// 用途: 每个 customer_type + crowed_layer 组各留排名 ≤10 的 crowed_type；非末级返回 1
// 依赖: [Cost 引力魔方 Rank]
// 配置类型: 视觉对象级度量筛选，不作为基础 Cost 的计算条件
// 使用: 加到引力魔方／触点矩阵的“此视觉对象上的筛选器”，设置等于 1
// ========================================
    VAR __IsDetail = ISINSCOPE('a05_e2e_paid_media_crowed_data_d'[crowed_type])
    RETURN
        IF(
            NOT __IsDetail,
            1,
            VAR __Rank = [Cost 引力魔方 Rank]
            RETURN
                IF(NOT ISBLANK(__Rank) && __Rank <= 10, 1, 0)
        )
// 返回对照：父级／TTL=1；末级 Rank≤10=1；末级 Rank>10 或 BLANK()=0。
// 不直接用“Rank≤10”过滤，避免空排名在比较时被当作 0，以及父级空排名的歧义。
// 可与字段有效性及零值筛选共同使用；本度量不负责排序，请按数值 Cost 降序排序。
// 三个行层级必须使用上方事实表字段；若改用独立维表，需同步改写排名和层级判定。
// 必须保留 customer_type、crowed_layer 父组上下文；使用展开层级，不把所有父组混成单层。
// 移除 crowed_type 上额外配置的原生 Top N 筛选，仅以本度量 = 1 实施分组 Top10。
```

### 2.14 Cost 排名与 Top10 显示筛选 — 直通车／快车

```dax
Cost 直通车 Rank =
// ========================================
// 度量值: Cost 直通车 Rank
// 中文名: 直通车／快车关键词花费排名
// Display Folder: KPIs Measure
// 用途: 在每个 customer_type / category / keyword_type 组内排名 keyword_name
// 依赖: [Cost 直通车 Value]
// 行层级: TTL / customer_type / category / keyword_type / keyword_name
// 口径说明: 每个父组独立按 Cost 降序、SKIP 排名，保留全部边界并列
// 计算方式: 显式匹配 customer_type、category、keyword_type 三个父组字段
//           按候选完整组合计算 Cost，平台等非行筛选不移除
// ========================================
    VAR __IsDetail = ISINSCOPE('a05_e2e_paid_media_keyword_data_d'[keyword_name])
    VAR __HasParentGroup =
        HASONEVALUE('a05_e2e_paid_media_keyword_data_d'[customer_type])
            && HASONEVALUE('a05_e2e_paid_media_keyword_data_d'[category])
            && HASONEVALUE('a05_e2e_paid_media_keyword_data_d'[keyword_type])
    VAR __CustomerType = SELECTEDVALUE('a05_e2e_paid_media_keyword_data_d'[customer_type])
    VAR __Category = SELECTEDVALUE('a05_e2e_paid_media_keyword_data_d'[category])
    VAR __KeywordType = SELECTEDVALUE('a05_e2e_paid_media_keyword_data_d'[keyword_type])
    RETURN
        IF(
            __IsDetail && __HasParentGroup,
            VAR __CurrentCost = [Cost 直通车 Value]
            // ── 第一步：只选出当前三个父级字段组合下的关键词候选行 ──
            VAR __GroupRows =
                FILTER(
                    ALLSELECTED(
                        'a05_e2e_paid_media_keyword_data_d'[customer_type],
                        'a05_e2e_paid_media_keyword_data_d'[category],
                        'a05_e2e_paid_media_keyword_data_d'[keyword_type],
                        'a05_e2e_paid_media_keyword_data_d'[keyword_name]
                    ),
                    'a05_e2e_paid_media_keyword_data_d'[customer_type] == __CustomerType
                        && 'a05_e2e_paid_media_keyword_data_d'[category] == __Category
                        && 'a05_e2e_paid_media_keyword_data_d'[keyword_type] == __KeywordType
                )
            // ── 第二步：清理行字段上下文，再逐候选调用基础 Cost 度量 ──
            // 完整列血缘 + 度量上下文转换也会覆盖同列筛选；清理步骤的作用详见第 3 节。
            VAR __RankTable =
                CALCULATETABLE(
                    FILTER(
                        ADDCOLUMNS(
                            __GroupRows,
                            "@RankCost", [Cost 直通车 Value]
                        ),
                        NOT ISBLANK([@RankCost])
                    ),
                    REMOVEFILTERS(
                        'a05_e2e_paid_media_keyword_data_d'[customer_type],
                        'a05_e2e_paid_media_keyword_data_d'[category],
                        'a05_e2e_paid_media_keyword_data_d'[keyword_type],
                        'a05_e2e_paid_media_keyword_data_d'[keyword_name]
                    )
                )
            // ── 第三步：只在当前父组候选表中排名 ──
            RETURN
                IF(
                    NOT ISBLANK(__CurrentCost),
                    RANKX(__RankTable, [@RankCost], __CurrentCost, DESC, SKIP),
                    BLANK()
                ),
            BLANK()
        )
// 层级判断：keyword_name 明细且父组唯一 → 组内排名；其余层级 → BLANK()。
// 同名关键词在不同父组分别排名；同父组内跨 plan_name 的同名关键词合并计算 Cost。
// 候选表保存外部行字段选择；仅剔除空 Cost，不新增名称或零值过滤规则。
// 验证：同一 customer_type/category 下两个 keyword_type 各 12 项 → 各取 10 项，共 20 项。
// 排名使用未格式化 Cost；若数据库浮点精度造成“看似相等但排名不同”，需先确认金额精度口径。
// 单组示例：Cost=100,100,90,80,80,70,60,50,40,30 → Rank=1,1,3,4,4,6,7,8,9,10。
```

```dax
直通车 Top10 Show Row =
// ========================================
// 度量值: 直通车 Top10 Show Row
// 中文名: 直通车／快车 Top10 关键词行显示筛选
// Display Folder: KPIs Measure
// 用途: 仅限制 keyword_name 末级；前三层和 TTL 不按自身 Cost 排名截断
// 依赖: [Cost 直通车 Rank]
// 配置类型: 视觉对象级度量筛选，末级为 keyword_name
// 使用: 加到直通车／快车矩阵的“此视觉对象上的筛选器”，设置等于 1
// ========================================
    VAR __IsDetail = ISINSCOPE('a05_e2e_paid_media_keyword_data_d'[keyword_name])
    RETURN
        IF(
            NOT __IsDetail,
            1,
            VAR __Rank = [Cost 直通车 Rank]
            RETURN
                IF(NOT ISBLANK(__Rank) && __Rank <= 10, 1, 0)
        )
// 返回对照：父级／TTL=1；末级 Rank≤10=1；末级 Rank>10 或 BLANK()=0。
// 可与 [IsAnyKeywordNotEmpty]、[直通车 IsZero] 共同筛选。
// 视觉配置：四个行字段均使用关键词事实表，第三层为 keyword_type；按数值 Cost 降序排序。
// 保留全部三个父组字段上下文；移除 keyword_name 上额外的原生 Top N 筛选。
// 用例：父组 A 的第 1 名不与父组 B 竞争；多个组可同时展示各自的第 1～10 名。
// 两组 Top10 Show Row 各用于对应矩阵，不同时配置到同一个矩阵或页面级筛选器。
// 两组排名共同边界：前 9 行花费较高，第 10～12 行花费相同，则 12 行全部保留。
// 验收：逐级展开、切换父组和日期、测试第 10 名并列／全空／不足 10 项；关闭“显示无数据的项”。
// 注意：非末级返回 1 仅表示不按父级排名过滤；小计/TTL 仍受视觉对象入选集合影响。
// Cost% 使用矩阵视觉总额作分母；部署后按第 3 节验证小计、总计及筛选器的共同作用。
```

---

## 3. 度量值清单与 Display Folder

| 序号 | 度量值名称                     | Display Folder | 用途                           | 数据类型             | 是否金额类 |
| ---- | ------------------------------ | -------------- | ------------------------------ | -------------------- | ---------- |
| 1    | Media Cost Value               | KPIs Measure   | 媒体花费值（#1）               | currency_M_K_Int_0db | 是         |
| 2    | Media Cost Display             | KPIs Measure   | 媒体花费格式化显示（K/M 切换） | currency_M_K_Int_0db | 是         |
| 3    | Cost 引力魔方 Value            | KPIs Measure   | 引力魔方花费值（#6）           | currency             | 是         |
| 4    | Cost 引力魔方 Display          | KPIs Measure   | 引力魔方花费格式化显示         | currency             | 是         |
| 5    | Cost 引力魔方 触点占比 Value   | KPIs Measure   | 引力魔方触点占比值（#7）       | percent_0dp          | 否         |
| 6    | Cost 引力魔方 触点占比 Display | KPIs Measure   | 引力魔方触点占比格式化显示     | percent_0dp          | 否         |
| 7    | Cost% 引力魔方 Value           | KPIs Measure   | 引力魔方花费占比值（#8）       | percent_1dp          | 否         |
| 8    | Cost% 引力魔方 Display         | KPIs Measure   | 引力魔方花费占比格式化显示     | percent_1dp          | 否         |
| 9    | ROI 引力魔方 Value             | KPIs Measure   | 引力魔方 ROI 值（#9）          | decimal_1dp          | 否         |
| 10   | ROI 引力魔方 Display           | KPIs Measure   | 引力魔方 ROI 格式化显示        | decimal_1dp          | 否         |
| 11   | Cost 直通车 Value              | KPIs Measure   | 直通车花费值（#10）            | currency             | 是         |
| 12   | Cost 直通车 Display            | KPIs Measure   | 直通车花费格式化显示           | currency             | 是         |
| 13   | Cost 直通车 快车占比 Value     | KPIs Measure   | 直通车快车占比值（#11）        | percent_0dp          | 否         |
| 14   | Cost 直通车 快车占比 Display   | KPIs Measure   | 直通车快车占比格式化显示       | percent_0dp          | 否         |
| 15   | Cost% 直通车 Value             | KPIs Measure   | 直通车花费占比值（#12）        | percent_1dp          | 否         |
| 16   | Cost% 直通车 Display           | KPIs Measure   | 直通车花费占比格式化显示       | percent_1dp          | 否         |
| 17   | ROI 直通车 Value               | KPIs Measure   | 直通车 ROI 值（#13）           | decimal_1dp          | 否         |
| 18   | ROI 直通车 Display             | KPIs Measure   | 直通车 ROI 格式化显示          | decimal_1dp          | 否         |

---

## 4. 指标口径来源对照

| Metric_ID | Metric Name            | 口径文档出处  | 计算公式                                      | 数据底表                          | 筛选条件                                        | 数据类型             | 是否金额类 |
| --------- | ---------------------- | ------------- | --------------------------------------------- | --------------------------------- | ----------------------------------------------- | -------------------- | ---------- |
| 1         | Media Cost             | 子模块二 §1  | SUM(cost_amt)                                 | a05_e2e_paid_media_summary_d      | customer_type='ALL' AND page_type="1"           | currency_M_K_Int_0db | 是         |
| 6         | Cost 引力魔方          | 子模块四 §6  | SUM(cost_amt), channel in {"引力魔方","触点"} | a05_e2e_paid_media_crowed_data_d  | channel in {"引力魔方","触点"}                  | currency             | 是         |
| 7         | Cost 引力魔方 触点占比 | 子模块四 §7  | cost_amt(引力魔方/触点) / cost_amt(四渠道)    | a05_e2e_paid_media_crowed_data_d  | 分子 channel IN {'引力魔方','触点'}；分母四渠道 | percent_0dp          | 否         |
| 8         | Cost% 引力魔方         | 子模块四 §8  | TA层级Cost / TTL Cost（移除行维度）           | a05_e2e_paid_media_crowed_data_d  | channel in {"引力魔方","触点"}                  | percent_1dp          | 否         |
| 9         | ROI 引力魔方           | 子模块四 §9  | media_sales_amt / cost_amt                    | a05_e2e_paid_media_crowed_data_d  | channel in {"引力魔方","触点"}                  | decimal_1dp          | 否         |
| 10        | Cost 直通车            | 子模块五 §10 | SUM(cost_amt), channel in {"直通车","快车"}   | a05_e2e_paid_media_keyword_data_d | channel in {"直通车","快车"}                    | currency             | 是         |
| 11        | Cost 直通车 快车占比   | 子模块五 §11 | cost_amt(直通车/快车) / cost_amt(四渠道)      | a05_e2e_paid_media_keyword_data_d | 分子 channel IN {'直通车','快车'}；分母四渠道   | percent_0dp          | 否         |
| 12        | Cost% 直通车           | 子模块五 §12 | 关键词层级Cost / TTL Cost（移除行维度）       | a05_e2e_paid_media_keyword_data_d | channel in {"直通车","快车"}                    | percent_1dp          | 否         |
| 13        | ROI 直通车             | 子模块五 §13 | media_sales_amt / cost_amt                    | a05_e2e_paid_media_keyword_data_d | channel in {"直通车","快车"}                    | decimal_1dp          | 否         |

---

## 5. 血缘关系图（Lineage Diagram）

```
┌─────────────────────────────────────────────────────────────────────┐
│                        数据源层                                      │
│  ① a05_e2e_paid_media_summary_d（汇总表）                           │
│     字段: data_date, platform, store_name, customer_type,           │
│           page_type, channel, is_controllable_channel, cost_amt     │
│     → #1 Media Cost                                                │
│                                                                     │
│  ② a05_e2e_paid_media_crowed_data_d（引力魔方下钻表）                │
│     字段: data_date, channel, crowed_layer, crowed_type,            │
│           customer_type, cost_amt, media_sales_amt                    │
│     → #6 Cost 引力魔方 / #7 触点占比 / #8 Cost% / #9 ROI           │
│                                                                     │
│  ③ a05_e2e_paid_media_keyword_data_d（直通车下钻表）                 │
│     字段: data_date, channel, category, plan_name, keyword_name,    │
│           cost_amt, media_sales_amt                                 │
│     → #10 Cost 直通车 / #11 快车占比 / #12 Cost% / #13 ROI         │
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
│  │  Slicer_Time_Frame_Min / Max（断开维度）     │                    │
│  │  → __TimeMin / __TimeMax 全局日期筛选        │                    │
│  └─────────────────────────────────────────────┘                    │
│                                                                     │
│  ┌─────────────────────────────────────────────┐                    │
│  │  Slicer_Currency_Selection（断开维度）       │                    │
│  │  → __FXRate 汇率（金额类指标 #1/#6/#10 使用）│                    │
│  │  → 人民币转美元，金额 ÷ FXRate              │                    │
│  │  → __CurrencySymbol 货币符号（Display 拼接） │                    │
│  └─────────────────────────────────────────────┘                    │
│                                                                     │
│  子模块二：Ads Format Cost%                                          │
│  ┌─────────────────────────┐  ┌─────────────────────────┐           │
│  │ Media Cost Value        │  │ Media Cost Display      │           │
│  │ (#1 summary ÷FX)        │→ │ (K/M 单位切换)           │           │
│  └─────────────────────────┘  └─────────────────────────┘           │
│                                                                     │
│  子模块四：Controllable Ads format breakdown: 引力魔方                │
│  ┌─────────────────────────┐  ┌─────────────────────────┐           │
│  │ Cost 引力魔方 Value     │  │ Cost 引力魔方 Display   │           │
│  │ (#6 crowed ÷FX)         │→ │ (千分位整数)             │           │
│  └─────────────────────────┘  └─────────────────────────┘           │
│  ┌─────────────────────────┐  ┌─────────────────────────┐           │
│  │ Cost 引力魔方 触点占比  │  │ Cost 引力魔方 触点占比  │           │
│  │ Value (#7)              │→ │ Display (percent_0dp)    │           │
│  └─────────────────────────┘  └─────────────────────────┘           │
│  ┌─────────────────────────┐  ┌─────────────────────────┐           │
│  │ Cost% 引力魔方 Value    │  │ Cost% 引力魔方 Display  │           │
│  │ (#8 REMOVEFILTERS)      │→ │ (percent_1dp)            │           │
│  └─────────────────────────┘  └─────────────────────────┘           │
│  ┌─────────────────────────┐  ┌─────────────────────────┐           │
│  │ ROI 引力魔方 Value      │  │ ROI 引力魔方 Display    │           │
│  │ (#9 Sales/Cost)         │→ │ (decimal_1dp)            │           │
│  └─────────────────────────┘  └─────────────────────────┘           │
│                                                                     │
│  子模块五：Controllable Ads format breakdown: 直通车                 │
│  ┌─────────────────────────┐  ┌─────────────────────────┐           │
│  │ Cost 直通车 Value       │  │ Cost 直通车 Display     │           │
│  │ (#10 keyword ÷FX)       │→ │ (千分位整数)             │           │
│  └─────────────────────────┘  └─────────────────────────┘           │
│  ┌─────────────────────────┐  ┌─────────────────────────┐           │
│  │ Cost 直通车 快车占比    │  │ Cost 直通车 快车占比    │           │
│  │ Value (#11)             │→ │ Display (percent_0dp)    │           │
│  └─────────────────────────┘  └─────────────────────────┘           │
│  ┌─────────────────────────┐  ┌─────────────────────────┐           │
│  │ Cost% 直通车 Value      │  │ Cost% 直通车 Display    │           │
│  │ (#12 REMOVEFILTERS)     │→ │ (percent_1dp)            │           │
│  └─────────────────────────┘  └─────────────────────────┘           │
│  ┌─────────────────────────┐  ┌─────────────────────────┐           │
│  │ ROI 直通车 Value        │  │ ROI 直通车 Display      │           │
│  │ (#13 Sales/Cost)        │→ │ (decimal_1dp)            │           │
│  └─────────────────────────┘  └─────────────────────────┘           │
└─────────────────────────────────────────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────────┐
│                        可视化层                                      │
│  卡片图（无 X 轴，无矩阵行上下文）                                   │
│  值: [* Value] 度量值                                               │
│  工具提示/标签: [* Display] 格式化文本                               │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 6. 关键设计说明

### 6.1 格式类型说明

| 格式类型             | 适用指标 | 格式规则                                                    |
| -------------------- | -------- | ----------------------------------------------------------- |
| currency_M_K_Int_0db | #1       | <1K 千分位整数；≥1K 用 K（1位小数）；≥1M 用 M（1位小数）  |
| currency             | #6、#10  | 货币符号 + 千分位整数，格式串`#,##0`                      |
| percent_0dp          | #7、#11  | 百分比整数，不含正号，格式串`#,##0%;#,##0%;0%`            |
| percent_1dp          | #8、#12  | 百分比一位小数，不含正号，格式串`#,##0.0%;-#,##0.0%;0.0%` |
| decimal_1dp          | #9、#13  | 数值一位小数，格式串`#,##0.0`                             |

### 6.2 金额类指标与汇率转换

仅 #1（Media Cost）、#6（Cost 引力魔方）、#10（Cost 直通车）为金额类指标。

- **汇率方向**：人民币转美元，使用**除法** `DIVIDE(value, __FXRate)`
- `Slicer_Currency_Selection[Currency_ExchangeRate]`：RMB=1, USD=7
- 底表数据为人民币，选择 USD 时除以 7 转为美元
- 占比/ROI 指标不受汇率影响

### 6.3 数据底表分布

| 指标           | 数据底表                          | 特点                          |
| -------------- | --------------------------------- | ----------------------------- |
| #1 Media Cost  | a05_e2e_paid_media_summary_d      | 汇总表，有 page_type="1" 筛选 |
| #6~#9 引力魔方 | a05_e2e_paid_media_crowed_data_d  | 下钻表，无 page_type 筛选     |
| #10~#13 直通车 | a05_e2e_paid_media_keyword_data_d | 下钻表，无 page_type 筛选     |

### 6.4 Cost% 分母移除行维度（#8、#12）

#8 和 #12 的分母是"该广告点位合计"，需要移除所有行维度：

- **#8 引力魔方**：`REMOVEFILTERS(crowed_layer, crowed_type, customer_type)`
- **#12 直通车**：`REMOVEFILTERS(customer_type, category, plan_name, keyword_name)`

卡片图场景下无行维度，REMOVEFILTERS 不影响结果；但保证将来用于矩阵/表格时也能正确计算占比。

### 6.5 平台渠道映射（#7、#11）

TM 和 JD 平台的渠道存在映射关系：

| TM 渠道  | JD 渠道 |
| -------- | ------- |
| 直通车   | 快车    |
| 引力魔方 | 触点    |
| 全站推   | 海投    |

#7 和 #11 的分子分母都用 `channel IN {...}` 包含所有映射渠道，platform 筛选器会自动筛选对应渠道，无需在 DAX 中额外处理平台映射。

### 6.6 筛选器公用说明

本模块与全看板其他模块共用筛选器：

- **Slicer_Time_Frame_Min/Max**：断开维度，SELECTEDVALUE 读取全局日期范围
- **Slicer_Platform_Selection**：1:N 关系，模型自动筛选（TM/JD 渠道自动映射）
- **Slicer_Store_Name**：1:N 关系，模型自动筛选
- **Slicer_Currency_Selection**：断开维度，仅金额类指标（#1/#6/#10）除以汇率，其他指标不受影响
- **trans_cycle**：1:N 关系，模型自动筛选

### 6.7 卡片图使用方式

- **值**：使用 `[* Value]` 度量值（数值类型，供卡片图渲染）
- **工具提示/标签**：使用 `[* Display]` 度量值（文本类型，格式化展示）
- **无 X 轴**：卡片图不涉及时间维度上下文，仅使用全局时间筛选器

### 6.8 is_controllable_channel 字段类型说明

口径文档存在两处表述：

- "筛选条件"栏：`is_controllable_channel="1"`（字符串）
- "DAX 语法规范"示例：`[is_controllable_channel] = 1`（整数）

本方案子模块二/四/五的 9 个指标均不涉及 `is_controllable_channel` 筛选（仅子模块三 #2~#5 涉及），故无影响。
