# KPI_Trend_solution 解决方案

> status: updated
> created: 2026-06-23
> updated: 2026-09-01
> complexity: 🟡中等
> type: 度量值开发
> naming: 遵循 dax-style.md 规范
> 口径来源: KPI Progress.md（最新口径，2026-09-01 同步）

---

## 1. 需求理解

实现 KPI Progress 看板中"New Acquisition KPI Trend"（子模块三，25~27）与"Category Growth KPI Trend"（子模块四，28~30）共 6 个指标的趋势图/柱形图展示：

- **适用场景**：柱形图 + 趋势图，每个指标独立编写 Value / Display 度量
- **口径**：一切以口径文档 KPI Progress.md 子模块三、子模块四为准
- **筛选器**：独立筛选器 Slicer_Month_Period 系列（结构与全局 Slicer_Time_Frame 一致，表名不同），不与其他模块日期筛选产生交叉筛选，只作用于本模块柱形图
- **特殊格式**：
  - `integer_M_K_Int_0db` → 整数/M/K 单位切换，不带货币符号（#25）
  - `currency_M_K_Int_0db` → 货币符号 + K/M 单位切换（#28）
  - `percent_0dp` → 百分比整数，不含正号（#26、#27、#29、#30）

---

## 2. 筛选器与时间上下文

### 2.1 独立筛选器说明

本模块使用独立筛选器 Slicer_Month_Period 系列，与全局 Slicer_Time_Frame 结构完全一致，仅表名不同，避免交叉筛选：

| 筛选器 | 对应全局筛选器 | 作用 |
| ------ | -------------- | ---- |
| Slicer_Month_Period | Slicer_Time_Frame | 读取 TimeFrame_ID（时间粒度，判断 Day/Week） |
| Slicer_Month_Period_Min | Slicer_Time_Frame_Min | 读取 TimeFrame_Min（全局起止日） |
| Slicer_Month_Period_Max | Slicer_Time_Frame_Max | 读取 TimeFrame_Max（全局结束日） |

### 2.2 时间上下文变量（所有指标公用）

```dax
// ── 全局时间范围（柱形图整体覆盖区间）──
VAR __TimeMin = SELECTEDVALUE(Slicer_Month_Period_Min[TimeFrame_Min])
VAR __TimeMax = SELECTEDVALUE(Slicer_Month_Period_Max[TimeFrame_Max])

// ── X 轴当前遍历月份的自然日范围（每个柱子对应的时间段）──
VAR __CurrentMonthMin = SELECTEDVALUE(Slicer_Month_Period[TimeFrame_Min])
VAR __CurrentMonthMax = SELECTEDVALUE(Slicer_Month_Period[TimeFrame_Max])

// ── 时间粒度判断（Day/Week 时部分指标留空）──
VAR __TimeFrameID = SELECTEDVALUE(Slicer_Month_Period[TimeFrame_ID])
VAR __IsDayOrWeek = __TimeFrameID IN {"Day", "Week"}
```

### 2.3 数据底表说明

| 底表 | 用途 | 涉及指标 |
| ---- | ---- | -------- |
| a03_e2e_customer_data_m | 全店新客 / 全部买家（DISTINCTCOUNT user_id） | #25 分子、#26 分子分母、#27 分母 |
| a05_e2e_paid_media_summary_d | 媒体新客数（media_member_cnt，MAX+SUM 聚合） | #27 分子 |
| a05_e2e_paid_media_product_data_d | 第二品类 SLS / Cost（framework 筛选） | #28、#29、#30 |

---

## 3. 度量值实现

### 3.1 New Customer No.（#25）

```dax
New Customer No. Value = 
// ========================================
// 度量值: New Customer No. Value
// Display Folder: KPI Trend
// 用途: 新客数量趋势值（柱形图/趋势图 Y 轴）
// 口径来源: KPI Progress.md 子模块三 §25
// 计算公式: COUNT(DISTINCT user_id)（全店新客）
// 数据底表: a03_e2e_customer_data_m
// 筛选条件: 合并区间等价于单一筛选：
//   data_date ∈ [__TimeMin, __TimeMax] AND net_pay_amt > 0 AND is_member = 0 AND lp_12m_net_pay_amt = 0
// 聚合粒度: 按趋势图所选 Period 及 platform、shop_info_id 对 user_id 去重计数
//   （platform/shop_info_id 由模型 1:N 关系自动筛选，无需显式 DAX 处理）
// 数据类型: integer_M_K_Int_0db（整数，不涉及汇率换算）
// 注意: Day/Week 时指标无意义，在最终结果层统一留空，不细分到分子分母
// ========================================
    // ── 全局时间范围 ──
    VAR __TimeMin = SELECTEDVALUE(Slicer_Month_Period_Min[TimeFrame_Min])
    VAR __TimeMax = SELECTEDVALUE(Slicer_Month_Period_Max[TimeFrame_Max])
    // ── X 轴当前遍历月份 ──
    VAR __CurrentMonthMin = SELECTEDVALUE(Slicer_Month_Period[TimeFrame_Min])
    VAR __CurrentMonthMax = SELECTEDVALUE(Slicer_Month_Period[TimeFrame_Max])
    // ── 时间粒度判断（Day/Week 时指标无意义，统一留空）──
    VAR __TimeFrameID = SELECTEDVALUE(Slicer_Month_Period[TimeFrame_ID])
    VAR __IsDayOrWeek = __TimeFrameID IN {"Day", "Week"}

    RETURN
        IF(
            __IsDayOrWeek,
            BLANK(),
            CALCULATE(
                DISTINCTCOUNT('a03_e2e_customer_data_m'[user_id]),
                'a03_e2e_customer_data_m'[data_date] >= __TimeMin,
                'a03_e2e_customer_data_m'[data_date] <= __TimeMax,
                'a03_e2e_customer_data_m'[data_date] >= __CurrentMonthMin,
                'a03_e2e_customer_data_m'[data_date] <= __CurrentMonthMax,
                'a03_e2e_customer_data_m'[net_pay_amt] > 0,
                'a03_e2e_customer_data_m'[is_member] = 0,
                'a03_e2e_customer_data_m'[lp_12m_net_pay_amt] = 0
            )
        )
```

```dax
New Customer No. Display = 
// ========================================
// 度量值: New Customer No. Display
// Display Folder: KPI Trend
// 用途: 新客数量格式化显示（K/M 单位切换，不带货币符号）
// 依赖: [New Customer No. Value]
// 格式类型: integer_M_K_Int_0db
//   值 < 1,000        → 千分位整数：999
//   1,000 ≤ 值 < 1M   → K 单位（1位小数）：1.5K
//   值 ≥ 1,000,000    → M 单位（1位小数）：1.5M
// ========================================
    VAR __Value = [New Customer No. Value]
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            IF(
                __Value < 1000,
                FORMAT(__Value, "#,##0"),
                IF(
                    __Value < 1000000,
                    FORMAT(__Value / 1000, "#,##0.0") & "K",
                    FORMAT(__Value / 1000000, "#,##0.0") & "M"
                )
            )
        )
```

### 3.2 New Customer%（#26）

```dax
New Customer% Value = 
// ========================================
// 度量值: New Customer% Value
// Display Folder: KPI Trend
// 用途: 新客占比趋势值
// 口径来源: KPI Progress.md 子模块三 §26
// 计算公式: New Customer No / TTL Buyers
// 数据底表: a03_e2e_customer_data_m
// 分子: COUNT(DISTINCT user_id)（全店新客，同 #25）
//   筛选: net_pay_amt > 0 AND is_member = 0 AND lp_12m_net_pay_amt = 0
// 分母: COUNT(DISTINCT user_id)（全部买家）
//   筛选: SUM(net_pay_amt) > 0 AND is_member = 0（行级等价 net_pay_amt > 0）
// 数据类型: percent_0dp（比率，不涉及汇率换算）
// 注意: Day/Week 时指标无意义，在最终结果层统一留空，不细分到分子分母
// ========================================
    // ── 全局时间范围 ──
    VAR __TimeMin = SELECTEDVALUE(Slicer_Month_Period_Min[TimeFrame_Min])
    VAR __TimeMax = SELECTEDVALUE(Slicer_Month_Period_Max[TimeFrame_Max])
    // ── X 轴当前遍历月份 ──
    VAR __CurrentMonthMin = SELECTEDVALUE(Slicer_Month_Period[TimeFrame_Min])
    VAR __CurrentMonthMax = SELECTEDVALUE(Slicer_Month_Period[TimeFrame_Max])
    // ── 时间粒度判断（Day/Week 时指标无意义，统一留空）──
    VAR __TimeFrameID = SELECTEDVALUE(Slicer_Month_Period[TimeFrame_ID])
    VAR __IsDayOrWeek = __TimeFrameID IN {"Day", "Week"}

    // ── 分子：全店新客（合并区间筛选，同 #25）──
    VAR __NewCustCnt =
        CALCULATE(
            DISTINCTCOUNT('a03_e2e_customer_data_m'[user_id]),
            'a03_e2e_customer_data_m'[data_date] >= __TimeMin,
            'a03_e2e_customer_data_m'[data_date] <= __TimeMax,
            'a03_e2e_customer_data_m'[data_date] >= __CurrentMonthMin,
            'a03_e2e_customer_data_m'[data_date] <= __CurrentMonthMax,
            'a03_e2e_customer_data_m'[net_pay_amt] > 0,
            'a03_e2e_customer_data_m'[is_member] = 0,
            'a03_e2e_customer_data_m'[lp_12m_net_pay_amt] = 0
        )
    // ── 分母：全部买家（net_pay_amt > 0 AND is_member = 0）──
    VAR __TTLBuyers =
        CALCULATE(
            DISTINCTCOUNT('a03_e2e_customer_data_m'[user_id]),
            'a03_e2e_customer_data_m'[data_date] >= __TimeMin,
            'a03_e2e_customer_data_m'[data_date] <= __TimeMax,
            'a03_e2e_customer_data_m'[data_date] >= __CurrentMonthMin,
            'a03_e2e_customer_data_m'[data_date] <= __CurrentMonthMax,
            'a03_e2e_customer_data_m'[net_pay_amt] > 0,
            'a03_e2e_customer_data_m'[is_member] = 0
        )
    RETURN
        IF(
            __IsDayOrWeek,
            BLANK(),
            DIVIDE(__NewCustCnt, __TTLBuyers)
        )
```

```dax
New Customer% Display = 
// ========================================
// 度量值: New Customer% Display
// Display Folder: KPI Trend
// 用途: 新客占比格式化显示
// 依赖: [New Customer% Value]
// 格式类型: percent_0dp → 百分比整数，不含正号
// 格式串: #,##0%;-#,##0%;0%
// ========================================
    VAR __Value = [New Customer% Value]
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            FORMAT(__Value, "#,##0%;-#,##0%;0%")
        )
```

### 3.3 Media Contribution to New Customer Acquisition%（#27）

```dax
Media Contribution to New Customer Acquisition% Value = 
// ========================================
// 度量值: Media Contribution to New Customer Acquisition% Value
// Display Folder: KPI Trend
// 用途: 媒体新客贡献率趋势值
// 口径来源: KPI Progress.md 子模块三 §27
// 计算公式: 媒体新客数 / 全店新客数
// 分子底表: a05_e2e_paid_media_summary_d（media_member_cnt）
// 分母底表: a03_e2e_customer_data_m（DISTINCTCOUNT user_id）
// 分子筛选: customer_type='ALL' AND page_type="1"
//   Month/Quarter/Year: 先按 platform, shop_id, data_month_name 取 MAX(media_member_cnt)，再 SUM
// 分母筛选: 合并区间 net_pay_amt > 0 AND is_member = 0 AND lp_12m_net_pay_amt = 0
// 数据类型: percent_0dp（比率，不涉及汇率换算）
// 注意: SUMX+SUMMARIZE 中列引用用 [__Value]，不是 "__Value"
// 注意: Day/Week 时指标无意义，在最终结果层统一留空，不细分到分子分母
// ========================================
    // ── 全局时间范围 ──
    VAR __TimeMin = SELECTEDVALUE(Slicer_Month_Period_Min[TimeFrame_Min])
    VAR __TimeMax = SELECTEDVALUE(Slicer_Month_Period_Max[TimeFrame_Max])
    // ── X 轴当前遍历月份 ──
    VAR __CurrentMonthMin = SELECTEDVALUE(Slicer_Month_Period[TimeFrame_Min])
    VAR __CurrentMonthMax = SELECTEDVALUE(Slicer_Month_Period[TimeFrame_Max])
    // ── 时间粒度判断（Day/Week 时指标无意义，统一留空）──
    VAR __TimeFrameID = SELECTEDVALUE(Slicer_Month_Period[TimeFrame_ID])
    VAR __IsDayOrWeek = __TimeFrameID IN {"Day", "Week"}

    // ── 分子：媒体新客数（MAX+SUM 聚合）──
    //   先按 platform, shop_id, data_month_name 分组取 MAX(media_member_cnt)，再对所有分组 SUM
    VAR __MediaNewCust =
        CALCULATE(
            SUMX(
                SUMMARIZE(
                    'a05_e2e_paid_media_summary_d',
                    'a05_e2e_paid_media_summary_d'[platform],
                    'a05_e2e_paid_media_summary_d'[shop_id],
                    'a05_e2e_paid_media_summary_d'[data_month_name],
                    "__Value", MAX('a05_e2e_paid_media_summary_d'[media_member_cnt])
                ),
                [__Value]    // 列引用写法：[__Value]，不是 "__Value"
            ),
            'a05_e2e_paid_media_summary_d'[customer_type] = "ALL",
            'a05_e2e_paid_media_summary_d'[page_type] = "1",
            'a05_e2e_paid_media_summary_d'[data_date] >= __TimeMin,
            'a05_e2e_paid_media_summary_d'[data_date] <= __TimeMax,
            'a05_e2e_paid_media_summary_d'[data_date] >= __CurrentMonthMin,
            'a05_e2e_paid_media_summary_d'[data_date] <= __CurrentMonthMax
        )

    // ── 分母：全店新客（合并区间筛选，同 #25）──
    VAR __TotalNewCust =
        CALCULATE(
            DISTINCTCOUNT('a03_e2e_customer_data_m'[user_id]),
            'a03_e2e_customer_data_m'[data_date] >= __TimeMin,
            'a03_e2e_customer_data_m'[data_date] <= __TimeMax,
            'a03_e2e_customer_data_m'[data_date] >= __CurrentMonthMin,
            'a03_e2e_customer_data_m'[data_date] <= __CurrentMonthMax,
            'a03_e2e_customer_data_m'[net_pay_amt] > 0,
            'a03_e2e_customer_data_m'[is_member] = 0,
            'a03_e2e_customer_data_m'[lp_12m_net_pay_amt] = 0
        )
    RETURN
        IF(
            __IsDayOrWeek,
            BLANK(),
            DIVIDE(__MediaNewCust, __TotalNewCust)
        )
```

```dax
Media Contribution to New Customer Acquisition% Display = 
// ========================================
// 度量值: Media Contribution to New Customer Acquisition% Display
// Display Folder: KPI Trend
// 用途: 媒体新客贡献率格式化显示
// 依赖: [Media Contribution to New Customer Acquisition% Value]
// 格式类型: percent_0dp → 百分比整数，不含正号
// 格式串: #,##0%;-#,##0%;0%
// ========================================
    VAR __Value = [Media Contribution to New Customer Acquisition% Value]
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            FORMAT(__Value, "#,##0%;-#,##0%;0%")
        )
```

### 3.4 Acceleration SLS（#28）

```dax
Acceleration SLS Value = 
// ========================================
// 度量值: Acceleration SLS Value
// Display Folder: KPI Trend
// 用途: 第二品类退后销售额趋势值（柱形图/趋势图 Y 轴）
// 口径来源: KPI Progress.md 子模块四 §28
// 计算公式: SUM(net_sales_amt), framework='Acceleration'
// 数据底表: a05_e2e_paid_media_product_data_d
// 筛选条件: framework='Acceleration'
// 数据类型: currency_M_K_Int_0db（金额类指标，需汇率换算）
// 汇率: DIVIDE(__Value, __FXRate)（除法，非乘法）
// ========================================
    // ── 全局时间范围 ──
    VAR __TimeMin = SELECTEDVALUE(Slicer_Month_Period_Min[TimeFrame_Min])
    VAR __TimeMax = SELECTEDVALUE(Slicer_Month_Period_Max[TimeFrame_Max])
    // ── X 轴当前遍历月份 ──
    VAR __CurrentMonthMin = SELECTEDVALUE(Slicer_Month_Period[TimeFrame_Min])
    VAR __CurrentMonthMax = SELECTEDVALUE(Slicer_Month_Period[TimeFrame_Max])
    // ── 汇率 ──
    VAR __FXRate = SELECTEDVALUE(Slicer_Currency_Selection[Currency_ExchangeRate], 1)

    VAR __AccelSLS =
        CALCULATE(
            SUM('a05_e2e_paid_media_product_data_d'[net_sales_amt]),
            'a05_e2e_paid_media_product_data_d'[framework] = "Acceleration",
            'a05_e2e_paid_media_product_data_d'[data_date] >= __TimeMin,
            'a05_e2e_paid_media_product_data_d'[data_date] <= __TimeMax,
            'a05_e2e_paid_media_product_data_d'[data_date] >= __CurrentMonthMin,
            'a05_e2e_paid_media_product_data_d'[data_date] <= __CurrentMonthMax
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

### 3.5 Acceleration SLS MOB%（#29）

```dax
Acceleration SLS MOB% Value = 
// ========================================
// 度量值: Acceleration SLS MOB% Value
// Display Folder: KPI Trend
// 用途: 第二品类退后销售额 MOB% 趋势值
// 口径来源: KPI Progress.md 子模块四 §29
// 计算公式: Acceleration SLS / TTL SLS
// 数据底表: a05_e2e_paid_media_product_data_d
// 分子: SUM(net_sales_amt[framework='Acceleration'])
// 分母: SUM(net_sales_amt[全部 framework])
// 数据类型: percent_0dp（比率，不涉及汇率换算）
// ========================================
    // ── 全局时间范围 ──
    VAR __TimeMin = SELECTEDVALUE(Slicer_Month_Period_Min[TimeFrame_Min])
    VAR __TimeMax = SELECTEDVALUE(Slicer_Month_Period_Max[TimeFrame_Max])
    // ── X 轴当前遍历月份 ──
    VAR __CurrentMonthMin = SELECTEDVALUE(Slicer_Month_Period[TimeFrame_Min])
    VAR __CurrentMonthMax = SELECTEDVALUE(Slicer_Month_Period[TimeFrame_Max])

    // ── 分子：Acceleration SLS ──
    VAR __AccelSLS =
        CALCULATE(
            SUM('a05_e2e_paid_media_product_data_d'[net_sales_amt]),
            'a05_e2e_paid_media_product_data_d'[framework] = "Acceleration",
            'a05_e2e_paid_media_product_data_d'[data_date] >= __TimeMin,
            'a05_e2e_paid_media_product_data_d'[data_date] <= __TimeMax,
            'a05_e2e_paid_media_product_data_d'[data_date] >= __CurrentMonthMin,
            'a05_e2e_paid_media_product_data_d'[data_date] <= __CurrentMonthMax
        )
    // ── 分母：TTL SLS（全部 framework）──
    VAR __TotalSLS =
        CALCULATE(
            SUM('a05_e2e_paid_media_product_data_d'[net_sales_amt]),
            'a05_e2e_paid_media_product_data_d'[data_date] >= __TimeMin,
            'a05_e2e_paid_media_product_data_d'[data_date] <= __TimeMax,
            'a05_e2e_paid_media_product_data_d'[data_date] >= __CurrentMonthMin,
            'a05_e2e_paid_media_product_data_d'[data_date] <= __CurrentMonthMax
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
// 格式串: #,##0%;-#,##0%;0%
// ========================================
    VAR __Value = [Acceleration SLS MOB% Value]
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            FORMAT(__Value, "#,##0%;-#,##0%;0%")
        )
```

### 3.6 Acceleration Cost MOB%（#30）

```dax
Acceleration Cost MOB% Value = 
// ========================================
// 度量值: Acceleration Cost MOB% Value
// Display Folder: KPI Trend
// 用途: 第二品类花费 MOB% 趋势值
// 口径来源: KPI Progress.md 子模块四 §30
// 计算公式: Acceleration Cost / TTL Cost
// 数据底表: a05_e2e_paid_media_product_data_d
// 分子筛选: mix_msg is NULL AND framework='Acceleration', SUM(cost_amt)
// 分母筛选: mix_msg is NULL（不限制 framework）, SUM(cost_amt)
// 数据类型: percent_0dp（比率，不涉及汇率换算）
// ========================================
    // ── 全局时间范围 ──
    VAR __TimeMin = SELECTEDVALUE(Slicer_Month_Period_Min[TimeFrame_Min])
    VAR __TimeMax = SELECTEDVALUE(Slicer_Month_Period_Max[TimeFrame_Max])
    // ── X 轴当前遍历月份 ──
    VAR __CurrentMonthMin = SELECTEDVALUE(Slicer_Month_Period[TimeFrame_Min])
    VAR __CurrentMonthMax = SELECTEDVALUE(Slicer_Month_Period[TimeFrame_Max])

    // ── 分子：Acceleration Cost（mix_msg is NULL AND framework='Acceleration'）──
    VAR __AccelCost =
        CALCULATE(
            SUM('a05_e2e_paid_media_product_data_d'[cost_amt]),
            'a05_e2e_paid_media_product_data_d'[framework] = "Acceleration",
            ISBLANK('a05_e2e_paid_media_product_data_d'[mix_msg]),
            'a05_e2e_paid_media_product_data_d'[data_date] >= __TimeMin,
            'a05_e2e_paid_media_product_data_d'[data_date] <= __TimeMax,
            'a05_e2e_paid_media_product_data_d'[data_date] >= __CurrentMonthMin,
            'a05_e2e_paid_media_product_data_d'[data_date] <= __CurrentMonthMax
        )
    // ── 分母：TTL Cost（mix_msg is NULL，不限制 framework）──
    VAR __TotalCost =
        CALCULATE(
            SUM('a05_e2e_paid_media_product_data_d'[cost_amt]),
            ISBLANK('a05_e2e_paid_media_product_data_d'[mix_msg]),
            'a05_e2e_paid_media_product_data_d'[data_date] >= __TimeMin,
            'a05_e2e_paid_media_product_data_d'[data_date] <= __TimeMax,
            'a05_e2e_paid_media_product_data_d'[data_date] >= __CurrentMonthMin,
            'a05_e2e_paid_media_product_data_d'[data_date] <= __CurrentMonthMax
        )
    RETURN
        DIVIDE(__AccelCost, __TotalCost)
```

```dax
Acceleration Cost MOB% Display = 
// ========================================
// 度量值: Acceleration Cost MOB% Display
// Display Folder: KPI Trend
// 用途: 第二品类花费 MOB% 格式化显示
// 依赖: [Acceleration Cost MOB% Value]
// 格式类型: percent_0dp → 百分比整数，不含正号
// 格式串: #,##0%;-#,##0%;0%
// ========================================
    VAR __Value = [Acceleration Cost MOB% Value]
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            FORMAT(__Value, "#,##0%;-#,##0%;0%")
        )
```

---

## 4. 度量值清单与 Display Folder

| 序号 | 度量值名称                                                | Display Folder | 用途                              | 数据类型            | 涉及汇率 |
| ---- | --------------------------------------------------------- | -------------- | --------------------------------- | ------------------- | -------- |
| 1    | New Customer No. Value                                    | KPI Trend      | 新客数量值（#25）                 | integer_M_K_Int_0db | 否       |
| 2    | New Customer No. Display                                  | KPI Trend      | 新客数量格式化显示                | integer_M_K_Int_0db | 否       |
| 3    | New Customer% Value                                       | KPI Trend      | 新客占比值（#26）                 | percent_0dp         | 否       |
| 4    | New Customer% Display                                     | KPI Trend      | 新客占比格式化显示                | percent_0dp         | 否       |
| 5    | Media Contribution to New Customer Acquisition% Value     | KPI Trend      | 媒体新客贡献率值（#27）           | percent_0dp         | 否       |
| 6    | Media Contribution to New Customer Acquisition% Display   | KPI Trend      | 媒体新客贡献率格式化显示          | percent_0dp         | 否       |
| 7    | Acceleration SLS Value                                    | KPI Trend      | 第二品类退后销售额值（#28）       | currency_M_K_Int_0db | 是       |
| 8    | Acceleration SLS Display                                  | KPI Trend      | 第二品类退后销售额格式化显示      | currency_M_K_Int_0db | 是       |
| 9    | Acceleration SLS MOB% Value                               | KPI Trend      | 第二品类退后销售额 MOB% 值（#29） | percent_0dp         | 否       |
| 10   | Acceleration SLS MOB% Display                             | KPI Trend      | 第二品类退后销售额 MOB% 格式化显示 | percent_0dp         | 否       |
| 11   | Acceleration Cost MOB% Value                              | KPI Trend      | 第二品类花费 MOB% 值（#30）       | percent_0dp         | 否       |
| 12   | Acceleration Cost MOB% Display                            | KPI Trend      | 第二品类花费 MOB% 格式化显示      | percent_0dp         | 否       |

---

## 5. 指标口径来源对照

| Metric_ID | Metric Name                                  | 口径文档出处   | 计算公式                                | 统计字段                                       | 数据底表                              | 数据类型            | 涉及汇率 |
| --------- | -------------------------------------------- | -------------- | --------------------------------------- | ---------------------------------------------- | ------------------------------------- | ------------------- | -------- |
| 25        | New Customer No.                             | 子模块三 §25   | COUNT(DISTINCT user_id)                 | user_id                                        | a03_e2e_customer_data_m               | integer_M_K_Int_0db | 否       |
| 26        | New Customer%                                | 子模块三 §26   | New Customer No / TTL Buyers            | user_id（分子新客 / 分母全部买家）            | a03_e2e_customer_data_m               | percent_0dp         | 否       |
| 27        | Media Contribution to New Customer Acq%      | 子模块三 §27   | 媒体新客数 / 全店新客数                 | media_member_cnt / user_id                     | summary_d + customer_data_m           | percent_0dp         | 否       |
| 28        | Acceleration SLS                             | 子模块四 §28   | SUM(net_sales_amt), framework='Accel'   | net_sales_amt                                  | a05_e2e_paid_media_product_data_d       | currency_M_K_Int_0db | 是       |
| 29        | Acceleration SLS MOB%                        | 子模块四 §29   | SUM(net_sales_amt[Accel]) / SUM(全部)   | net_sales_amt(Accel) / net_sales_amt(全部)     | a05_e2e_paid_media_product_data_d       | percent_0dp         | 否       |
| 30        | Acceleration Cost MOB%                       | 子模块四 §30   | SUM(cost_amt[Accel]) / SUM(cost_amt)    | cost_amt(Accel, mix_msg NULL) / cost_amt(全部, mix_msg NULL) | a05_e2e_paid_media_product_data_d | percent_0dp         | 否       |

---

## 6. 血缘关系图（Lineage Diagram）

```
┌─────────────────────────────────────────────────────────────────────┐
│                        数据源层                                      │
│  a03_e2e_customer_data_m（全店新客/买家）                            │
│    字段: data_date, platform, shop_info_id, user_id,                 │
│          net_pay_amt, is_member, lp_12m_net_pay_amt                  │
│  a05_e2e_paid_media_summary_d（媒体新客）                            │
│    字段: data_date, platform, shop_id, data_month_name,             │
│          customer_type, page_type, media_member_cnt                  │
│  a05_e2e_paid_media_product_data_d（第二品类 SLS/Cost）                │
│    字段: data_date, platform, framework, mix_msg,                    │
│          net_sales_amt, cost_amt                                      │
└──────────────────────────────┬──────────────────────────────────────┘
                               │
                               │ 1:N 关系（模型自动筛选）
                               │
              ┌────────────────┼────────────────┐
              │                │                │
              ▼                ▼                ▼
┌──────────────────┐ ┌──────────────────┐ ┌──────────────────┐
│ Slicer_Platform_  │ │ Slicer_Store_    │ │ Slicer_Currency_  │
│ Selection         │ │ Name             │ │ Selection         │
│ (Platform_ID)     │ │ (Store_ID)       │ │ (汇率/符号)        │
└──────────────────┘ └──────────────────┘ └──────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│              独立筛选器层（仅作用于本模块柱形图）                     │
│  Slicer_Month_Period（TimeFrame_ID 时间粒度）                        │
│  Slicer_Month_Period_Min（TimeFrame_Min 全局起止日）                 │
│  Slicer_Month_Period_Max（TimeFrame_Max 全局结束日）                 │
│  └─ X 轴遍历: Slicer_Month_Period[TimeFrame_Min/Max] 当前月份       │
└──────────────────────────────┬──────────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────────┐
│                        度量值层                                      │
│                                                                     │
│  子模块三：New Acquisition KPI Trend                                 │
│  ┌─────────────────────────┐  ┌─────────────────────────┐           │
│  │ New Customer No. Value  │  │ New Customer No. Display│           │
│  │ (#25 DISTINCTCOUNT)     │→ │ (integer_M_K_Int_0db)   │           │
│  └─────────────────────────┘  └─────────────────────────┘           │
│  ┌─────────────────────────┐  ┌─────────────────────────┐           │
│  │ New Customer% Value     │  │ New Customer% Display   │           │
│  │ (#26 新客/买家)         │→ │ (percent_0dp)            │           │
│  └─────────────────────────┘  └─────────────────────────┘           │
│  ┌─────────────────────────┐  ┌─────────────────────────┐           │
│  │ Media Contribution...   │  │ Media Contribution...   │           │
│  │ % Value (#27 MAX+SUM)   │→ │ % Display (percent_0dp) │           │
│  └─────────────────────────┘  └─────────────────────────┘           │
│                                                                     │
│  子模块四：Category Growth KPI Trend                                 │
│  ┌─────────────────────────┐  ┌─────────────────────────┐           │
│  │ Acceleration SLS Value │  │ Acceleration SLS Display│           │
│  │ (#28 SUM ÷FX)           │→ │ (currency_M_K_Int_0db)  │           │
│  └─────────────────────────┘  └─────────────────────────┘           │
│  ┌─────────────────────────┐  ┌─────────────────────────┐           │
│  │ Acceleration SLS MOB%   │  │ Acceleration SLS MOB%   │           │
│  │ Value (#29 Accel/Total)  │→ │ Display (percent_0dp)    │           │
│  └─────────────────────────┘  └─────────────────────────┘           │
│  ┌─────────────────────────┐  ┌─────────────────────────┐           │
│  │ Acceleration Cost MOB%  │  │ Acceleration Cost MOB%  │           │
│  │ Value (#30 Accel/Total)  │→ │ Display (percent_0dp)    │           │
│  └─────────────────────────┘  └─────────────────────────┘           │
└─────────────────────────────────────────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────────┐
│                        可视化层                                      │
│  柱形图 / 折线图（趋势图）                                           │
│  X 轴: data_month_name（时间维度）                                   │
│  Y 轴: [* Value] 度量值（数值类型，供图表渲染）                      │
│  工具提示: [* Display] 格式化文本                                    │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 7. 关键设计说明

### 7.1 格式类型说明

| 格式类型             | 适用指标           | 格式规则                                                    |
| -------------------- | ------------------ | ----------------------------------------------------------- |
| integer_M_K_Int_0db  | #25                | <1K 千分位整数；≥1K 用 K（1位小数）；≥1M 用 M（1位小数），不带货币符号 |
| currency_M_K_Int_0db | #28                | <1K 千分位整数；≥1K 用 K（1位小数）；≥1M 用 M（1位小数），带货币符号   |
| percent_0dp          | #26、#27、#29、#30 | 百分比整数，不含正号，格式串 `#,##0%;-#,##0%;0%`            |

### 7.2 金额类指标与汇率换算

仅 #28（Acceleration SLS）为金额类指标，需 `DIVIDE(__Value, __FXRate)`（除法，非乘法）。
- #25 为整数类型（integer_M_K_Int_0db），不涉及汇率换算
- #26/#27/#29/#30 为比率类型（percent_0dp），不涉及汇率换算

### 7.3 独立筛选器设计

本模块使用 Slicer_Month_Period 系列独立筛选器，与全局 Slicer_Time_Frame 结构完全一致但表名不同：
- **全局范围**：Slicer_Month_Period_Min[TimeFrame_Min] ~ Slicer_Month_Period_Max[TimeFrame_Max]
- **X 轴当前月份**：Slicer_Month_Period[TimeFrame_Min] ~ Slicer_Month_Period[TimeFrame_Max]
- **时间粒度**：Slicer_Month_Period[TimeFrame_ID]（判断 Day/Week）
- **设计目的**：不与其他模块的日期筛选产生交叉筛选，只作用于本模块柱形图

### 7.4 全店新客判定（合并区间）

#25/#26 分子 / #27 分母均使用全店新客判定，技术实现等价于单一筛选：
```
data_date ∈ [__TimeMin, __TimeMax] AND net_pay_amt > 0 AND is_member = 0 AND lp_12m_net_pay_amt = 0
```
说明：start_period（第一个财月）是 slicer 区间的子集，用于判断 `lp_12m_net_pay_amt = 0` 的行一定也在 slicer 区间内，因此可合并区间。

### 7.5 #27 媒体新客 MAX+SUM 聚合

#27 分子（media_member_cnt）需要先按 platform, shop_id, data_month_name 分组取 MAX，再对所有分组 SUM：
```dax
SUMX(
    SUMMARIZE(
        'a05_e2e_paid_media_summary_d',
        'a05_e2e_paid_media_summary_d'[platform],
        'a05_e2e_paid_media_summary_d'[shop_id],
        'a05_e2e_paid_media_summary_d'[data_month_name],
        "__Value", MAX('a05_e2e_paid_media_summary_d'[media_member_cnt])
    ),
    [__Value]    // 列引用写法：[__Value]，不是 "__Value"
)
```
- Day/Week 时整个指标无意义，在最终结果层 `IF(__IsDayOrWeek, BLANK(), DIVIDE(...))` 统一留空（#25/#26/#27 同此处理，不细分到分子分母）
- SUMX+SUMMARIZE 中列引用用 `[__Value]`，不是字符串 `"__Value"`

### 7.6 #30 mix_msg is NULL 筛选

#30 分子分母均需筛选 `mix_msg is NULL`：
- 分子：`mix_msg is NULL AND framework='Acceleration'`
- 分母：`mix_msg is NULL`（不限制 framework）
- DAX 实现：`ISBLANK('a05_e2e_paid_media_product_data_d'[mix_msg])`

### 7.7 筛选器公用说明

本模块与 KPIs、KPI by Platform 等模块共用以下筛选器：
- **Slicer_Platform_Selection**：1:N 关系，模型自动筛选
- **Slicer_Store_Name**：1:N 关系，模型自动筛选
- **Slicer_Currency_Selection**：断开维度，仅金额类指标 #28 除以汇率
- **trans_cycle**：1:N 关系，模型自动筛选

本模块独有的独立日期筛选器：
- **Slicer_Month_Period / Min / Max**：断开维度，仅作用于本模块柱形图

### 7.8 趋势图/柱形图使用方式

- **Y 轴**：使用 `[* Value]` 度量值（数值类型，供图表渲染）
- **工具提示**：使用 `[* Display]` 度量值（文本类型，格式化展示）
- **X 轴**：使用 `data_month_name` 时间维度（月/季/年，取决于图表粒度）
