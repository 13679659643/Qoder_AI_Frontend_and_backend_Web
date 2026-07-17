# KPI_Trend_solution 解决方案

> status: updated
> created: 2026-06-23
> updated: 2026-07-03
> complexity: 🟡中等
> type: 度量值开发
> naming: 遵循 dax-style.md 规范
> 口径来源: KPI Progress.md（最新口径，2026-07-03 同步）

---

## 1. 需求理解

实现 KPI Progress 看板中"New Acquisition KPI Trend"（子模块三，25~27）与"Category Growth KPI Trend"（子模块四，28~30）共 6 个指标的趋势图/柱形图展示：

- **适用场景**：柱形图 + 趋势图，无需矩阵 SWITCH 路由分发，每个指标独立编写 Value / Display 度量
- **口径**：一切以口径文档 KPI Progress.md 子模块三、子模块四为准
- **筛选器**：与 Category Growth/KPI_Breakdown、KPIs 模块公用同一套筛选器（全看板公用）
- **特殊格式**：
  - `currency_M_K_Int_0db` → 货币符号 + K/M 单位切换（#25、#28）
  - `percent_0dp` → 百分比整数，不含正号（#26、#27、#29、#30）

---

## 2. 度量值实现

### 2.1 New Customer No.（#25）

```dax
New Customer No. Value = 
// ========================================
// 度量值: New Customer No. Value
// Display Folder: KPI Trend
// 用途: 新客数量趋势值（柱形图/趋势图 Y 轴）
// 口径来源: KPI Progress.md 子模块三 §25
// 计算公式: COUNT DISTINCT 买家id（全店新客）
// 统计字段: 暂时固定为 1，待后续补充口径
// 筛选条件: customer_type='NEW' AND page_type="1"
// 数据类型: currency_M_K_Int_0db
// ========================================
    // ── 暂时固定为 1，待后续补充实际口径 ──
	VAR __FXRate = SELECTEDVALUE(Slicer_Currency_Selection[Currency_ExchangeRate], 1)
    RETURN DIVIDE(1 , __FXRate )
```

```dax
New Customer No. Display = 
// ========================================
// 度量值: New Customer No. Display
// Display Folder: KPI Trend
// 用途: 新客数量格式化显示（K/M 单位切换）
// 依赖: [New Customer No. Value], Slicer_Currency_Selection
// 格式类型: currency_M_K_Int_0db
//   值 < 1,000        → 货币符号 + 千分位整数：¥999
//   1,000 ≤ 值 < 1M   → 货币符号 + K 单位（1位小数）：¥1.5K
//   值 ≥ 1,000,000    → 货币符号 + M 单位（1位小数）：¥1.5M
// ========================================
    VAR __Value = [New Customer No. Value]
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

### 2.2 New Customer%（#26）

```dax
New Customer% Value = 
// ========================================
// 度量值: New Customer% Value
// Display Folder: KPI Trend
// 用途: 新客占比趋势值
// 口径来源: KPI Progress.md 子模块三 §26
// 计算公式: New Customer No / TTL Buyers
// 统计字段: 分子 member_cnt（new）暂时固定 1；分母 member_cnt（all）暂时固定 2
// 筛选条件: 分子 customer_type='NEW'；分母 customer_type='ALL'；统一 page_type="1"
// 数据类型: percent_0dp → 百分比整数，不含正号
// ========================================
    // ── 暂时固定为 1/2，待后续补充实际口径 ──
    DIVIDE(1, 2)
```

```dax
New Customer% Display = 
// ========================================
// 度量值: New Customer% Display
// Display Folder: KPI Trend
// 用途: 新客占比格式化显示
// 依赖: [New Customer% Value]
// 格式类型: percent_0dp → 百分比整数，不含正号
// 格式串: #,##0%;#,##0%;0%
// ========================================
    VAR __Value = [New Customer% Value]
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            FORMAT(__Value, "#,##0%;#,##0%;0%")
        )
```

### 2.3 Media Contribution to New Customer Acquisition%（#27）

```dax
Media Contribution to New Customer Acquisition% Value = 
// ========================================
// 度量值: Media Contribution to New Customer Acquisition% Value
// Display Folder: KPI Trend
// 用途: 媒体新客贡献率趋势值
// 口径来源: KPI Progress.md 子模块三 §27
// 计算公式: 媒体新客数 / 全店新客数
// 统计字段: 分子 media_member_cnt（new）暂时固定 1；分母 member_cnt（all）暂时固定 3
// 筛选条件: customer_type='NEW' AND page_type="1"
// 数据类型: percent_0dp → 百分比整数，不含正号
// ========================================
    // ── 暂时固定为 1/3，待后续补充实际口径 ──
    DIVIDE(1, 3)
```

```dax
Media Contribution to New Customer Acquisition% Display = 
// ========================================
// 度量值: Media Contribution to New Customer Acquisition% Display
// Display Folder: KPI Trend
// 用途: 媒体新客贡献率格式化显示
// 依赖: [Media Contribution to New Customer Acquisition% Value]
// 格式类型: percent_0dp → 百分比整数，不含正号
// 格式串: #,##0%;#,##0%;0%
// ========================================
    VAR __Value = [Media Contribution to New Customer Acquisition% Value]
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            FORMAT(__Value, "#,##0%;#,##0%;0%")
        )
```

### 2.4 Acceleration SLS（#28）

```dax
	Acceleration SLS Value = 
	// ========================================
	// 度量值: Acceleration SLS Value
	// Display Folder: KPI Trend
	// 用途: 第二品类退后销售额趋势值（柱形图/趋势图 Y 轴）
	// 口径来源: KPI Progress.md 子模块四 §28
	// 计算公式: SUM(net_sales_amt), framework='Acceleration'
	// 统计字段: net_sales_amt
	// 筛选条件: customer_type='ALL' AND framework='Acceleration' AND page_type="1"
	// 数据类型: currency_M_K_Int_0db（金额类指标，需汇率转换）
	// ========================================
	    // 1. 获取起止切片器选择的全局范围
	    VAR __TimeMin = SELECTEDVALUE(Slicer_Month_Period_Min[TimeFrame_Min])
	    VAR __TimeMax = SELECTEDVALUE(Slicer_Month_Period_Max[TimeFrame_Max])
	    // 2. 获取柱形图 X 轴当前遍历的月份的自然日范围（关键新增）
	    VAR __CurrentMonthMin = SELECTEDVALUE(Slicer_Month_Period[TimeFrame_Min])
	    VAR __CurrentMonthMax = SELECTEDVALUE(Slicer_Month_Period[TimeFrame_Max])
	    VAR __FXRate = SELECTEDVALUE(Slicer_Currency_Selection[Currency_ExchangeRate], 1)
	    VAR __AccelSLS =
	        CALCULATE(
	            SUM('a05_e2e_paid_media_summary_d'[net_sales_amt]),
	            'a05_e2e_paid_media_summary_d'[customer_type] = "ALL",
	            'a05_e2e_paid_media_summary_d'[framework] = "Acceleration",
	            'a05_e2e_paid_media_summary_d'[page_type] = "1",
	            // 3. 全局切片器筛选：限制事实表数据在选定的起止月份范围内
	            'a05_e2e_paid_media_summary_d'[data_date] >= __TimeMin,
	            'a05_e2e_paid_media_summary_d'[data_date] <= __TimeMax,
	            // 4. X轴上下文筛选：限制事实表数据仅属于当前X轴遍历的那个月（关键新增）
	            'a05_e2e_paid_media_summary_d'[data_date] >= __CurrentMonthMin,
	            'a05_e2e_paid_media_summary_d'[data_date] <= __CurrentMonthMax
	        )
	    RETURN
	        DIVIDE(__AccelSLS, __FXRate)
```

```dax
Acceleration SLS Display = 
// ========================================
// 度量值: Acceleration SLS Display
// Display Folder: KPI Trend
// 用途: 第二品类退后销售额格式化显示（K/M 单位切换）
// 依赖: [Acceleration SLS Value], Slicer_Currency_Selection
// 格式类型: currency_M_K_Int_0db
//   值 < 1,000        → 货币符号 + 千分位整数：¥999
//   1,000 ≤ 值 < 1M   → 货币符号 + K 单位（1位小数）：¥1.5K
//   值 ≥ 1,000,000    → 货币符号 + M 单位（1位小数）：¥1.5M
// ========================================
    VAR __Value = [Acceleration SLS Value]
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

### 2.5 Acceleration SLS MOB%（#29）

```dax
	Acceleration SLS MOB% Value = 
	// ========================================
	// 度量值: Acceleration SLS MOB% Value
	// Display Folder: KPI Trend
	// 用途: 第二品类退后销售额 MOB% 趋势值
	// 口径来源: KPI Progress.md 子模块四 §29
	// 计算公式: Acceleration SLS / TTL SLS
	// 统计字段: net_sales_amt（framework='Acceleration'）/ net_sales_amt（全部 framework）
	// 筛选条件: customer_type='ALL' AND page_type="1"
	// 数据类型: percent_0dp → 百分比整数，不含正号
	// ========================================
	    VAR __TimeMin = SELECTEDVALUE(Slicer_Month_Period_Min[TimeFrame_Min])
	    VAR __TimeMax = SELECTEDVALUE(Slicer_Month_Period_Max[TimeFrame_Max])
	    // 获取柱形图 X 轴当前遍历月份的自然日范围（关键新增）
	    VAR __CurrentMonthMin = SELECTEDVALUE(Slicer_Month_Period[TimeFrame_Min])
	    VAR __CurrentMonthMax = SELECTEDVALUE(Slicer_Month_Period[TimeFrame_Max])
	    // ── 分子：Acceleration SLS ──
	    VAR __AccelSLS =
	        CALCULATE(
	            SUM('a05_e2e_paid_media_summary_d'[net_sales_amt]),
	            'a05_e2e_paid_media_summary_d'[customer_type] = "ALL",
	            'a05_e2e_paid_media_summary_d'[framework] = "Acceleration",
	            'a05_e2e_paid_media_summary_d'[page_type] = "1",
	            'a05_e2e_paid_media_summary_d'[data_date] >= __TimeMin,
	            'a05_e2e_paid_media_summary_d'[data_date] <= __TimeMax,
	            'a05_e2e_paid_media_summary_d'[data_date] >= __CurrentMonthMin,
	            'a05_e2e_paid_media_summary_d'[data_date] <= __CurrentMonthMax
	        )
	    // ── 分母：TTL SLS（全部 framework）──
	    VAR __TotalSLS =
	        CALCULATE(
	            SUM('a05_e2e_paid_media_summary_d'[net_sales_amt]),
	            'a05_e2e_paid_media_summary_d'[customer_type] = "ALL",
	            'a05_e2e_paid_media_summary_d'[page_type] = "1",
	            'a05_e2e_paid_media_summary_d'[data_date] >= __TimeMin,
	            'a05_e2e_paid_media_summary_d'[data_date] <= __TimeMax,
	            'a05_e2e_paid_media_summary_d'[data_date] >= __CurrentMonthMin,
	            'a05_e2e_paid_media_summary_d'[data_date] <= __CurrentMonthMax
	        )
	    RETURN
	        DIVIDE(__AccelSLS, __TotalSLS)
```

```dax
Acceleration SLS MOB% Display = 
// ========================================
// 度量值: Acceleration SLS MOB% Display
// Display Folder: KPI Trend
// 用途: 第二品类退后销售额 MOB% 格式化显示
// 依赖: [Acceleration SLS MOB% Value]
// 格式类型: percent_0dp → 百分比整数，不含正号
// 格式串: #,##0%;#,##0%;0%
// ========================================
    VAR __Value = [Acceleration SLS MOB% Value]
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            FORMAT(__Value, "#,##0%;#,##0%;0%")
        )
```

### 2.6 Acceleration Cost MOB%（#30）

```dax
	Acceleration Cost MOB% Value = 
	// ========================================
	// 度量值: Acceleration Cost MOB% Value
	// Display Folder: KPI Trend
	// 用途: 第二品类花费 MOB% 趋势值
	// 口径来源: KPI Progress.md 子模块四 §30
	// 计算公式: Acceleration Cost / TTL Cost
	// 统计字段: cost_amt（framework='Acceleration'）/ cost_amt（全部 framework）
	// 筛选条件: customer_type='ALL' AND page_type="1"
	// 数据类型: percent_0dp → 百分比整数，不含正号
	// ========================================
	    VAR __TimeMin = SELECTEDVALUE(Slicer_Month_Period_Min[TimeFrame_Min])
	    VAR __TimeMax = SELECTEDVALUE(Slicer_Month_Period_Max[TimeFrame_Max])
	    // 获取柱形图 X 轴当前遍历月份的自然日范围（关键新增）
	    VAR __CurrentMonthMin = SELECTEDVALUE(Slicer_Month_Period[TimeFrame_Min])
	    VAR __CurrentMonthMax = SELECTEDVALUE(Slicer_Month_Period[TimeFrame_Max])
	    // ── 分子：Acceleration Cost ──
	    VAR __AccelCost =
	        CALCULATE(
	            SUM('a05_e2e_paid_media_summary_d'[cost_amt]),
	            'a05_e2e_paid_media_summary_d'[customer_type] = "ALL",
	            'a05_e2e_paid_media_summary_d'[framework] = "Acceleration",
	            'a05_e2e_paid_media_summary_d'[page_type] = "1",
	            'a05_e2e_paid_media_summary_d'[data_date] >= __TimeMin,
	            'a05_e2e_paid_media_summary_d'[data_date] <= __TimeMax,
	            'a05_e2e_paid_media_summary_d'[data_date] >= __CurrentMonthMin,
	            'a05_e2e_paid_media_summary_d'[data_date] <= __CurrentMonthMax
	        )
	    // ── 分母：TTL Cost（全部 framework）──
	    VAR __TotalCost =
	        CALCULATE(
	            SUM('a05_e2e_paid_media_summary_d'[cost_amt]),
	            'a05_e2e_paid_media_summary_d'[customer_type] = "ALL",
	            'a05_e2e_paid_media_summary_d'[page_type] = "1",
	            'a05_e2e_paid_media_summary_d'[data_date] >= __TimeMin,
	            'a05_e2e_paid_media_summary_d'[data_date] <= __TimeMax,
	            'a05_e2e_paid_media_summary_d'[data_date] >= __CurrentMonthMin,
	            'a05_e2e_paid_media_summary_d'[data_date] <= __CurrentMonthMax
	        )
	    RETURN
	        IF(ISBLANK(DIVIDE(__AccelCost, __TotalCost)),1)
```

```dax
Acceleration Cost MOB% Display = 
// ========================================
// 度量值: Acceleration Cost MOB% Display
// Display Folder: KPI Trend
// 用途: 第二品类花费 MOB% 格式化显示
// 依赖: [Acceleration Cost MOB% Value]
// 格式类型: percent_0dp → 百分比整数，不含正号
// 格式串: #,##0%;#,##0%;0%
// ========================================
    VAR __Value = [Acceleration Cost MOB% Value]
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            FORMAT(__Value, "#,##0%;#,##0%;0%")
        )
```

---

## 3. 度量值清单与 Display Folder

| 序号 | 度量值名称                                                | Display Folder | 用途                              | 数据类型            |
| ---- | --------------------------------------------------------- | -------------- | --------------------------------- | ------------------- |
| 1    | New Customer No. Value                                    | KPI Trend      | 新客数量值（#25）                 | currency_M_K_Int_0db |
| 2    | New Customer No. Display                                  | KPI Trend      | 新客数量格式化显示                | currency_M_K_Int_0db |
| 3    | New Customer% Value                                       | KPI Trend      | 新客占比值（#26）                 | percent_0dp         |
| 4    | New Customer% Display                                     | KPI Trend      | 新客占比格式化显示                | percent_0dp         |
| 5    | Media Contribution to New Customer Acquisition% Value     | KPI Trend      | 媒体新客贡献率值（#27）           | percent_0dp         |
| 6    | Media Contribution to New Customer Acquisition% Display   | KPI Trend      | 媒体新客贡献率格式化显示          | percent_0dp         |
| 7    | Acceleration SLS Value                                    | KPI Trend      | 第二品类退后销售额值（#28）       | currency_M_K_Int_0db |
| 8    | Acceleration SLS Display                                  | KPI Trend      | 第二品类退后销售额格式化显示      | currency_M_K_Int_0db |
| 9    | Acceleration SLS MOB% Value                               | KPI Trend      | 第二品类退后销售额 MOB% 值（#29） | percent_0dp         |
| 10   | Acceleration SLS MOB% Display                             | KPI Trend      | 第二品类退后销售额 MOB% 格式化显示 | percent_0dp         |
| 11   | Acceleration Cost MOB% Value                              | KPI Trend      | 第二品类花费 MOB% 值（#30）       | percent_0dp         |
| 12   | Acceleration Cost MOB% Display                            | KPI Trend      | 第二品类花费 MOB% 格式化显示      | percent_0dp         |

---

## 4. 指标口径来源对照

| Metric_ID | Metric Name                                            | 口径文档出处   | 计算公式                                | 统计字段                                       | customer_type | framework    | 数据类型            | 是否金额类 |
| --------- | ------------------------------------------------------ | -------------- | --------------------------------------- | ---------------------------------------------- | ------------- | ------------ | ------------------- | ---------- |
| 25        | New Customer No.                                       | 子模块三 §25   | COUNT DISTINCT 买家id（暂时固定 1）      | 1（占位）                                      | NEW           | -            | currency_M_K_Int_0db | 是         |
| 26        | New Customer%                                          | 子模块三 §26   | New Customer No / TTL Buyers            | 分子 1（占位）/ 分母 2（占位）                  | NEW / ALL     | -            | percent_0dp         | 否         |
| 27        | Media Contribution to New Customer Acquisition%        | 子模块三 §27   | 媒体新客数 / 全店新客数                  | 分子 1（占位）/ 分母 3（占位）                  | NEW           | -            | percent_0dp         | 否         |
| 28        | Acceleration SLS                                       | 子模块四 §28   | SUM(net_sales_amt), framework='Accel'   | net_sales_amt                                  | ALL           | Acceleration | currency_M_K_Int_0db | 是         |
| 29        | Acceleration SLS MOB%                                  | 子模块四 §29   | Acceleration SLS / TTL SLS              | net_sales_amt(Accel) / net_sales_amt(全部)     | ALL           | Accel + 全部 | percent_0dp         | 否         |
| 30        | Acceleration Cost MOB%                                 | 子模块四 §30   | Acceleration Cost / TTL Cost            | cost_amt(Accel) / cost_amt(全部)               | ALL           | Accel + 全部 | percent_0dp         | 否         |

---

## 5. 血缘关系图（Lineage Diagram）

```
┌─────────────────────────────────────────────────────────────────────┐
│                        数据源层                                      │
│  a05_e2e_paid_media_summary_d（事实表）                              │
│  字段: data_date, platform, store_name, trans_cycle,                │
│        customer_type, page_type, framework,                         │
│        cost_amt, net_sales_amt, media_member_cnt, member_cnt        │
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
│  │  Slicer_Month_Period_Min / Max（断开维度）     │                    │
│  │  → __TimeMin / __TimeMax 日期筛选            │                    │
│  └─────────────────────────────────────────────┘                    │
│                                                                     │
│  ┌─────────────────────────────────────────────┐                    │
│  │  Slicer_Currency_Selection（断开维度）       │                    │
│  │  → __FXRate 汇率（仅金额类指标 #25/#28 使用）│                    │
│  │  → __CurrencySymbol 货币符号（Display 拼接） │                    │
│  └─────────────────────────────────────────────┘                    │
│                                                                     │
│  子模块三：New Acquisition KPI Trend                                 │
│  ┌─────────────────────────┐  ┌─────────────────────────┐           │
│  │ New Customer No. Value  │  │ New Customer No. Display│           │
│  │ (#25 固定值 1)           │→ │ (K/M 单位切换)           │           │
│  └─────────────────────────┘  └─────────────────────────┘           │
│  ┌─────────────────────────┐  ┌─────────────────────────┐           │
│  │ New Customer% Value     │  │ New Customer% Display   │           │
│  │ (#26 固定 1/2)           │→ │ (percent_0dp)            │           │
│  └─────────────────────────┘  └─────────────────────────┘           │
│  ┌─────────────────────────┐  ┌─────────────────────────┐           │
│  │ Media Contribution...   │  │ Media Contribution...   │           │
│  │ % Value (#27 固定 1/3)  │→ │ % Display (percent_0dp) │           │
│  └─────────────────────────┘  └─────────────────────────┘           │
│                                                                     │
│  子模块四：Category Growth KPI Trend                                 │
│  ┌─────────────────────────┐  ┌─────────────────────────┐           │
│  │ Acceleration SLS Value  │  │ Acceleration SLS Display│           │
│  │ (#28 net_sales_amt ×FX) │→ │ (K/M 单位切换)           │           │
│  └─────────────────────────┘  └─────────────────────────┘           │
│  ┌─────────────────────────┐  ┌─────────────────────────┐           │
│  │ Acceleration SLS MOB%   │  │ Acceleration SLS MOB%   │           │
│  │ Value (#29 Accel/Total) │→ │ Display (percent_0dp)    │           │
│  └─────────────────────────┘  └─────────────────────────┘           │
│  ┌─────────────────────────┐  ┌─────────────────────────┐           │
│  │ Acceleration Cost MOB%  │  │ Acceleration Cost MOB%  │           │
│  │ Value (#30 Accel/Total) │→ │ Display (percent_0dp)    │           │
│  └─────────────────────────┘  └─────────────────────────┘           │
└─────────────────────────────────────────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────────┐
│                        可视化层                                      │
│  柱形图 / 折线图（趋势图）                                           │
│  X 轴: data_date（时间维度）                                         │
│  Y 轴: [* Value] 度量值                                             │
│  工具提示: [* Display] 格式化文本                                    │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 6. 关键设计说明

### 6.1 格式类型说明

| 格式类型             | 适用指标       | 格式规则                                                    |
| -------------------- | -------------- | ----------------------------------------------------------- |
| currency_M_K_Int_0db | #25、#28       | <1K 千分位整数；≥1K 用 K（1位小数）；≥1M 用 M（1位小数）    |
| percent_0dp          | #26、#27、#29、#30 | 百分比整数，不含正号，格式串 `#,##0%;#,##0%;0%`            |

### 6.2 金额类指标与汇率转换

仅 #25（New Customer No.）和 #28（Acceleration SLS）为金额类指标，需除以 `Slicer_Currency_Selection[Currency_ExchangeRate]`（RMB=1, USD=7）。#25 当前为固定值 1，汇率转换逻辑已预留，待补充实际口径后自动生效。

### 6.3 暂时固定值指标（待口径补充）

| Metric_ID | 指标名                              | 固定值 | 说明           |
| --------- | ----------------------------------- | ------ | -------------- |
| 25        | New Customer No.                    | 1      | 待补充实际口径 |
| 26        | New Customer%                       | 1/2    | 分子分母均占位 |
| 27        | Media Contribution to New Customer Acquisition% | 1/3 | 分子分母均占位 |

### 6.4 筛选器公用说明

本模块与 KPIs、KPI by Platform、Category Growth/KPI_Breakdown 共用筛选器：

- **Slicer_Month_Period_Min/Max**：断开维度，SELECTEDVALUE 读取时间范围
- **Slicer_Platform_Selection**：1:N 关系，模型自动筛选
- **Slicer_Store_Name**：1:N 关系，模型自动筛选
- **Slicer_Currency_Selection**：断开维度，仅金额类指标（#25/#28）除以汇率
- **trans_cycle**：1:N 关系，模型自动筛选

### 6.5 趋势图/柱形图使用方式

- **Y 轴**：使用 `[* Value]` 度量值（数值类型，供图表渲染）
- **工具提示**：使用 `[* Display]` 度量值（文本类型，格式化展示）
- **X 轴**：使用 `data_date` 时间维度（日/周/月，取决于图表粒度）
