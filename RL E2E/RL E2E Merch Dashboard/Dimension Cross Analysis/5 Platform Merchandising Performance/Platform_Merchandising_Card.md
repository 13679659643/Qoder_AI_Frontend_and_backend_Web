# Platform Merchandising Performance 卡片图 KPI 解决方案

> **版本**: v1.0
> **模块**: RL E2E Merch Dashboard - Dimension Cross Analysis Tab - Platform Merchandising Performance（子模块八，卡片图衍生场景）
> **关联口径**: 口径文档/口径Markdown格式/Dimension Cross Analysis.md - 子模块八：Platform Merchandising Performance（§34-§39）+ 口径文档/口径Markdown格式/actual除target逻辑详情.md（TAR 类指标五粒度规则）
> **数据底表（销售类）**: a02_e2e_product_performance_sales_summary_d
> **数据底表（目标类）**: a05_e2e_product_fcst_data_d
> **关联维度**: Slicer_Time_Frame（时间粒度）、Slicer_Time_Frame_Min_This / Max_This / Min_Last / Max_Last（日期，断开维度）、Slicer_Framework（framework 视觉对象筛选单选，一对多自动传导）、Slicer_Category / Slicer_Platform_Selection / Slicer_Store_Name / Slicer_Label（页面筛选器，一对多自动传导）

---

## 1. 需求理解

### 1.1 模块定位

Platform Merchandising Performance 卡片图 KPI：五个指标以独立卡片展示，**无矩阵行 / 列维度**——筛选作用全部由页面筛选器（Slicer_Category / Slicer_Platform_Selection / Slicer_Store_Name / Slicer_Label 等，维度表与事实表一对多关联，自动传导）与视觉对象筛选器（固定单选 Slicer_Framework[framework]）提供。

| 指标 | 计算逻辑 | 数据类型 |
| ---- | -------- | -------- |
| SLS Amt% | 单个 framework 销售金额 / 全部 framework 销售金额（This Period 区间） | percent_1dp |
| SLS Amt% vs LP | SLS Amt% This - SLS Amt% Last（占比差值，×10000 转 bp 在 Display 层） | delta_bp |
| TAR ACH% | This actual / This target（date to date，全粒度） | percent_1dp |
| MTD TAR Progress | This actual / 分母区间 target（随时间粒度分支） | percent_1dp |
| YTD TAR Progress | This actual / 分母区间 target（随时间粒度分支） | percent_1dp |

每指标独立输出 Value（数值层）+ Display（格式化文本层），共 10 个度量值。

### 1.2 筛选上下文

| 筛选来源 | 作用方式 | DAX 处理 |
| -------- | -------- | -------- |
| Slicer_Time_Frame / Min_This / Max_This / Min_Last / Max_Last | 断开维度，SELECTEDVALUE 读取 | 时间粒度、This / Last 区间、财月财年区间、跨期判定字段，度量值内以 data_date 比较显式过滤两张事实表 |
| Slicer_Framework[framework]（视觉对象筛选固定单选） | 与 sales / a05 一对多关联自动传导 | 分子（SLS Amt% / vs LP / TAR 类 actual 与 target）自然生效；SLS Amt% 与 vs LP 的**分母**需 ALLSELECTED 移除该视觉筛选 |
| Slicer_Category / Slicer_Platform_Selection / Slicer_Store_Name / Slicer_Label（页面筛选器） | 一对多关联自动传导 | 自然生效，保留在 SLS Amt% 分母中（ALLSELECTED 不触碰这些列） |

### 1.3 SLS Amt% 占比口径（单 framework ÷ 总 framework）

- **分子**：视觉对象筛选固定单选 framework + 页面筛选器（关系自动传导），This Period 区间 `sum(net_sales_amt)`
- **分母**：`ALLSELECTED(Slicer_Framework[framework], Slicer_Framework[sort_order])` 移除视觉对象内部的 framework 筛选、保留页面级外部切片器，This Period 区间全部 framework 合计——占比 = 单个 framework 占总 framework 的比值
- **两列 ALLSELECTED 的原因**：framework 按 sort_order 按列排序（Sort by Column），视觉对象筛选器的 framework 筛选在引擎查询中以 framework + sort_order 组合筛选形式落地，单列 `ALLSELECTED(Slicer_Framework[framework])` 无法剥离组合筛选中的 sort_order 部分——筛选残留导致分母恒等于分子（占比恒 100%），必须同时 ALLSELECTED 两列
- vs LP 双期同构：This 占比与 Last 占比均按此分子分母口径，差值 = This 占比 - Last 占比

### 1.4 TAR 类指标口径（actual ÷ target）

- **actual**：`a02_e2e_product_performance_sales_summary_d[net_sales_amt]`，恒为 This Period 区间（视觉 framework 筛选 + 页面筛选器自动传导）
- **target**：`a05_e2e_product_fcst_data_d[fcst_sales_amt]`，时间区间随指标与粒度分支（framework / 渠道 / 品牌等维度筛选经一对多关系同步传导至 a05）

**粒度 × 指标计算矩阵**：

| 时间粒度 | TAR ACH% | MTD TAR Progress | YTD TAR Progress |
| -------- | -------- | ---------------- | ---------------- |
| Day | This / This | 不跨财月：This / 财月 target；跨财月：不计算 | 不跨财年：This / 财年 target；跨财年：不计算 |
| Week | This / This | 同 Day | 同 Day |
| Month | This / This | This / This（分子分母始终和 This Period 区间一致） | 不跨财年：This / 财年 target；跨财年：不计算 |
| Quarter | This / This | 不计算 | 不跨财年：This / 财年 target；跨财年：不计算 |
| Year | This / This | 不计算 | 计算，This / This（分子分母始终和 This Period 区间一致） |

- **时间粒度**读 `SELECTEDVALUE(Slicer_Time_Frame[TimeFrame_ID])`（Day / Week / Month / Quarter / Year）
- **跨财月判定**：不区分粒度，比较 `Slicer_Time_Frame_Min_This[TimeFrame_Min_Month_Value]` 与 `Slicer_Time_Frame_Max_This[TimeFrame_Max_Month_Value]`（财月 value，文本类型），不相等 → 跨财月
- **跨财年判定**：不区分粒度，比较 `Slicer_Time_Frame_Min_This[TimeFrame_Min_Year_Value]` 与 `Slicer_Time_Frame_Max_This[TimeFrame_Max_Year_Value]`（财年 value，文本类型），不相等 → 跨财年
- **target MTD 区间**：`[Slicer_Time_Frame_Max_This[Fiscal_Month_First_Day], Slicer_Time_Frame_Max_This[Fiscal_Month_Last_Day]]`（TimeFrame_Max 所在财月）
- **target YTD 区间**：`[Slicer_Time_Frame_Max_This[Fiscal_Year_First_Day], Slicer_Time_Frame_Max_This[Fiscal_Year_Last_Day]]`（TimeFrame_Max 所在财年）
- **不计算** = Value 返回 BLANK → Display 返回 BLANK()（卡片显示空白）
- actual / target 同为底表 RMB 原值相除，TAR 比率不受币种选择影响

---

## 2. 方案设计

### 2.1 度量值分层

```
SLS Amt% Value
    ←  分子：framework 视觉筛选自然传导 + This Period 区间
       分母：ALLSELECTED(Slicer_Framework[framework], Slicer_Framework[sort_order]) + This Period 区间
    ↓
SLS Amt% vs LP Value
    ←  SLS Amt% This（复用 SLS Amt% Value）- SLS Amt% Last（LP 区间同构占比）
    ↓
TAR ACH% / MTD TAR Progress / YTD TAR Progress Value
    ←  actual（This Period 区间）÷ target（区间随指标与粒度分支）
    ↓
各指标 Display
    ←  percent_1dp：FORMAT(__Value, "#,##0.0%")
       delta_bp：FORMAT(__Value * 10000, "#,##0") & "bp"（×10000 在 Display 层，卡片无 Y 轴）
```

### 2.2 度量值清单

| 序号 | 度量值名称 | Display Folder | 类型 |
| ---- | ---------- | -------------- | ---- |
| 1 | Platform Merchandising Card SLS Amt% Value | Card KPIs\Values | percent_1dp |
| 2 | Platform Merchandising Card SLS Amt% Display | Card KPIs\Display | percent_1dp |
| 3 | Platform Merchandising Card SLS Amt% vs LP Value | Card KPIs\Values | delta_bp |
| 4 | Platform Merchandising Card SLS Amt% vs LP Display | Card KPIs\Display | delta_bp |
| 5 | Platform Merchandising Card TAR ACH% Value | Card KPIs\Values | percent_1dp |
| 6 | Platform Merchandising Card TAR ACH% Display | Card KPIs\Display | percent_1dp |
| 7 | Platform Merchandising Card MTD TAR Progress Value | Card KPIs\Values | percent_1dp |
| 8 | Platform Merchandising Card MTD TAR Progress Display | Card KPIs\Display | percent_1dp |
| 9 | Platform Merchandising Card YTD TAR Progress Value | Card KPIs\Values | percent_1dp |
| 10 | Platform Merchandising Card YTD TAR Progress Display | Card KPIs\Display | percent_1dp |

卡片图绑定：卡片主体（数据标签）绑 Display（文本）；数据标签精度 / 条件格式（若有）绑 Value（数值）。

---

## 3. 度量值实现

### 3.1 Platform Merchandising Card SLS Amt% Value

```dax
Platform Merchandising Card SLS Amt% Value = 
// ========================================
// 度量值: Platform Merchandising Card SLS Amt% Value
// 中文名: 单Framework销售金额占比（卡片）
// Display Folder: Platform Merchandising Performance\Card KPIs\Values
// 用途: 卡片图 SLS Amt%——单个 framework 销售金额 / 全部 framework 销售金额
//       分子: 视觉对象筛选固定单选 Slicer_Framework[framework] + 页面筛选器
//             （一对多关联自动传导），This Period 区间 sum(net_sales_amt)
//       分母: ALLSELECTED(Slicer_Framework[framework], Slicer_Framework[sort_order])
//             移除视觉对象内部 framework 筛选、保留页面级外部切片器，
//             This Period 区间全部 framework 合计
// 依赖: Slicer_Time_Frame_Min_This[TimeFrame_Min] / Slicer_Time_Frame_Max_This[TimeFrame_Max]
//       Slicer_Framework[framework, sort_order]
// 数据底表: a02_e2e_product_performance_sales_summary_d
// 说明: framework 按 sort_order 按列排序，视觉筛选以 framework + sort_order
//       组合筛选落地，分母必须两列同时 ALLSELECTED（单列写法筛选残留
//       → 分母恒等于分子 → 占比恒 100%）
// ========================================

// ── This Period 时间区间（日期筛选器断开维度，度量值内显式过滤）──
VAR __PeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Min_This[TimeFrame_Min])
VAR __PeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

// ── 分子：视觉对象筛选单选 framework + 页面筛选器（关系自动传导）──
VAR __SLSAmt_This =
    CALCULATE(
        SUM('a02_e2e_product_performance_sales_summary_d'[net_sales_amt]),
        'a02_e2e_product_performance_sales_summary_d'[data_date] >= __PeriodMin,
        'a02_e2e_product_performance_sales_summary_d'[data_date] <= __PeriodMax
    )

// ── 分母：ALLSELECTED 两列移除视觉 framework 筛选，保留外部切片器 ──
// framework + sort_order 两列同时 ALLSELECTED（按列排序组合筛选需整体剥离）
VAR __SLSAmt_Total =
    CALCULATE(
        SUM('a02_e2e_product_performance_sales_summary_d'[net_sales_amt]),
        ALL(Slicer_Framework[framework], Slicer_Framework[sort_order]),
        'a02_e2e_product_performance_sales_summary_d'[data_date] >= __PeriodMin,
        'a02_e2e_product_performance_sales_summary_d'[data_date] <= __PeriodMax,
        NOT ISBLANK('Slicer_Framework'[framework])
    )

RETURN
    DIVIDE(__SLSAmt_This, __SLSAmt_Total)
```

### 3.2 Platform Merchandising Card SLS Amt% Display

```dax
Platform Merchandising Card SLS Amt% Display =
// ========================================
// 度量值: Platform Merchandising Card SLS Amt% Display
// 中文名: 单Framework销售金额占比显示（卡片）
// Display Folder: Platform Merchandising Performance\Card KPIs\Display
// 用途: 卡片图 SLS Amt% 格式化显示，percent_1dp：百分比一位小数，不含正号
// 依赖: [Platform Merchandising Card SLS Amt% Value]
// 空值规则: BLANK 返回 BLANK()（卡片显示空白）
// ========================================
    VAR __Value = [Platform Merchandising Card SLS Amt% Value]

    RETURN
        IF(
            ISBLANK(__Value),
            BLANK(),
            FORMAT(__Value, "#,##0.0%")    // 26.5%
        )
```

### 3.3 Platform Merchandising Card SLS Amt% vs LP Value

```dax
Platform Merchandising Card SLS Amt% vs LP Value =
// ========================================
// 度量值: Platform Merchandising Card SLS Amt% vs LP Value
// 中文名: 单Framework销售金额占比vs LP差值（卡片）
// Display Folder: Platform Merchandising Performance\Card KPIs\Values
// 用途: 卡片图 vs LP——SLS Amt% This - SLS Amt% Last（占比差值原始小数）
//       双期同构占比口径：分子 = 视觉 framework 筛选 + 页面筛选器，
//       分母 = ALLSELECTED(Slicer_Framework[framework], sort_order) 全部 framework 合计
// 依赖: [Platform Merchandising Card SLS Amt% Value]（This 占比，上下文一致直接复用）
//       Slicer_Time_Frame_Min_Last[TimeFrame_Min] / Slicer_Time_Frame_Max_Last[TimeFrame_Max]
// 类型: delta_bp（Value 层保持原始差值小数，×10000 转 bp 在 Display 层——
//       卡片图无 Y 轴绑定，刻度无需 bp 数值）
// 空值规则: 任一侧占比为空时返回 BLANK
// ========================================

// ── Last Period 时间区间 ──
VAR __PeriodMin_LY = SELECTEDVALUE(Slicer_Time_Frame_Min_Last[TimeFrame_Min])
VAR __PeriodMax_LY = SELECTEDVALUE(Slicer_Time_Frame_Max_Last[TimeFrame_Max])

// ── LP 占比分子：视觉 framework 筛选 + 页面筛选器，LP 区间 ──
VAR __SLSAmt_Last =
    CALCULATE(
        SUM('a02_e2e_product_performance_sales_summary_d'[net_sales_amt]),
        'a02_e2e_product_performance_sales_summary_d'[data_date] >= __PeriodMin_LY,
        'a02_e2e_product_performance_sales_summary_d'[data_date] <= __PeriodMax_LY
    )

// ── LP 占比分母：ALLSELECTED 两列全部 framework 合计，LP 区间（与 This 侧同构）──
VAR __SLSAmt_Total_Last =
    CALCULATE(
        SUM('a02_e2e_product_performance_sales_summary_d'[net_sales_amt]),
        ALL(Slicer_Framework[framework], Slicer_Framework[sort_order]),
        'a02_e2e_product_performance_sales_summary_d'[data_date] >= __PeriodMin_LY,
        'a02_e2e_product_performance_sales_summary_d'[data_date] <= __PeriodMax_LY,
        NOT ISBLANK('Slicer_Framework'[framework])
    )
VAR __SLSAmtPct_Last = DIVIDE(__SLSAmt_Last, __SLSAmt_Total_Last)

// ── This 占比：卡片上下文与 SLS Amt% Value 一致，直接复用 ──
VAR __SLSAmtPct_This = [Platform Merchandising Card SLS Amt% Value]

RETURN
    IF(
        ISBLANK(__SLSAmtPct_This) || ISBLANK(__SLSAmtPct_Last),
        BLANK(),
        ROUND(__SLSAmtPct_This - __SLSAmtPct_Last,6)    // 差值原始小数，×10000 在 Display 层
    )
```

### 3.4 Platform Merchandising Card SLS Amt% vs LP Display

```dax
Platform Merchandising Card SLS Amt% vs LP Display =
// ========================================
// 度量值: Platform Merchandising Card SLS Amt% vs LP Display
// 中文名: 单Framework销售金额占比vs LP显示（卡片）
// Display Folder: Platform Merchandising Performance\Card KPIs\Display
// 用途: 卡片图 vs LP 格式化显示，delta_bp：差值 ×10000 转 bp
//       负数自带负号、零值 0bp、含正号
// 依赖: [Platform Merchandising Card SLS Amt% vs LP Value]
// 空值规则: BLANK 返回 BLANK()（卡片显示空白）
// ========================================
    VAR __Value = [Platform Merchandising Card SLS Amt% vs LP Value]

    RETURN
        IF(
            ISBLANK(__Value),
            BLANK(),
            IF(__Value * 10000 >0,"+","") & FORMAT(__Value * 10000, "#,##0") & "bp"    // -152bp / 0bp
        )
```

### 3.5 Platform Merchandising Card TAR ACH% Value

```dax
Platform Merchandising Card TAR ACH% Value =
// ========================================
// 度量值: Platform Merchandising Card TAR ACH% Value
// 中文名: 目标达成率（卡片）
// Display Folder: Platform Merchandising Performance\Card KPIs\Values
// 用途: 卡片图 TAR ACH%——This actual / This target（date to date，全粒度
//       分子分母均 This Period 区间）
//       actual: sales[net_sales_amt]（视觉 framework 筛选 + 页面筛选器自动传导）
//       target: a05[fcst_sales_amt]（维度筛选经一对多关系同步传导）
// 依赖: Slicer_Time_Frame_Min_This[TimeFrame_Min] / Slicer_Time_Frame_Max_This[TimeFrame_Max]
// 数据底表: a02_e2e_product_performance_sales_summary_d（actual）
//           a05_e2e_product_fcst_data_d（target）
// 汇率: actual / target 同币种相除，比率不受币种选择影响
// ========================================

// ── This Period 时间区间（actual 与 target 同区间）──
VAR __PeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Min_This[TimeFrame_Min])
VAR __PeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

// ── actual：This Period 区间销售金额 ──
VAR __Actual =
    CALCULATE(
        SUM('a02_e2e_product_performance_sales_summary_d'[net_sales_amt]),
        'a02_e2e_product_performance_sales_summary_d'[data_date] >= __PeriodMin,
        'a02_e2e_product_performance_sales_summary_d'[data_date] <= __PeriodMax
    )

// ── target：This Period 区间预测销售金额（a05 与日期筛选器断开维度，显式过滤）──
VAR __Target =
    CALCULATE(
        SUM('a05_e2e_product_fcst_data_d'[fcst_sales_amt]),
        'a05_e2e_product_fcst_data_d'[data_date] >= __PeriodMin,
        'a05_e2e_product_fcst_data_d'[data_date] <= __PeriodMax
    )

RETURN
    DIVIDE(__Actual, __Target)
```

### 3.6 Platform Merchandising Card TAR ACH% Display

```dax
Platform Merchandising Card TAR ACH% Display =
// ========================================
// 度量值: Platform Merchandising Card TAR ACH% Display
// 中文名: 目标达成率显示（卡片）
// Display Folder: Platform Merchandising Performance\Card KPIs\Display
// 用途: 卡片图 TAR ACH% 格式化显示，percent_1dp：百分比一位小数，不含正号
// 依赖: [Platform Merchandising Card TAR ACH% Value]
// 空值规则: BLANK 返回 BLANK()（卡片显示空白）
// ========================================
    VAR __Value = [Platform Merchandising Card TAR ACH% Value]

    RETURN
        IF(
            ISBLANK(__Value),
            BLANK(),
            FORMAT(__Value, "#,##0.0%")    // 96.5%
        )
```

### 3.7 Platform Merchandising Card MTD TAR Progress Value

```dax
Platform Merchandising Card MTD TAR Progress Value =
// ========================================
// 度量值: Platform Merchandising Card MTD TAR Progress Value
// 中文名: 月度目标进度（卡片）
// Display Folder: Platform Merchandising Performance\Card KPIs\Values
// 用途: 卡片图 MTD TAR Progress——actual 恒为 This Period 区间，分母区间随粒度分支：
//       Day / Week   → 不跨财月：This actual / 所在财月汇总 target；跨财月：不计算
//       Month        → This / This（分子分母始终和 This Period 区间一致）
//       Quarter / Year → 不计算
// 依赖: Slicer_Time_Frame[TimeFrame_ID]（时间粒度）
//       Slicer_Time_Frame_Min_This[TimeFrame_Min] / Slicer_Time_Frame_Max_This[TimeFrame_Max]
//       Slicer_Time_Frame_Max_This[Fiscal_Month_First_Day / Fiscal_Month_Last_Day]（财月区间）
//       Slicer_Time_Frame_Min_This[TimeFrame_Min_Month_Value] 与
//       Slicer_Time_Frame_Max_This[TimeFrame_Max_Month_Value]（跨财月判定，文本比较）
// 数据底表: a02_e2e_product_performance_sales_summary_d（actual）
//           a05_e2e_product_fcst_data_d（target）
// ========================================

// ── This Period 时间区间（actual）──
VAR __PeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Min_This[TimeFrame_Min])
VAR __PeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

// ── 财月区间（TimeFrame_Max 所在财月）──
VAR __MonthFirstDay = SELECTEDVALUE(Slicer_Time_Frame_Max_This[Fiscal_Month_First_Day])
VAR __MonthLastDay = SELECTEDVALUE(Slicer_Time_Frame_Max_This[Fiscal_Month_Last_Day])

// ── 时间粒度与跨财月判定（判定不区分粒度，直接比较财月 value 文本）──
VAR __TimeFrameID = SELECTEDVALUE(Slicer_Time_Frame[TimeFrame_ID])
VAR __IsCrossMonth =
    SELECTEDVALUE(Slicer_Time_Frame_Min_This[TimeFrame_Min_Month_Value])
        <> SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max_Month_Value])

// ── actual：This Period 区间销售金额 ──
VAR __Actual =
    CALCULATE(
        SUM('a02_e2e_product_performance_sales_summary_d'[net_sales_amt]),
        'a02_e2e_product_performance_sales_summary_d'[data_date] >= __PeriodMin,
        'a02_e2e_product_performance_sales_summary_d'[data_date] <= __PeriodMax
    )

// ── target：分母区间随粒度分支 ──
// Day / Week 不跨财月取财月汇总 target；Month 直接取 This Period 区间 target
VAR __Target =
    SWITCH(
        TRUE(),
        __TimeFrameID IN {"Day", "Week"},
            IF(
                __IsCrossMonth,
                BLANK(),    // 跨财月：不计算（外层 DIVIDE 返回 BLANK）
                CALCULATE(
                    SUM('a05_e2e_product_fcst_data_d'[fcst_sales_amt]),
                    'a05_e2e_product_fcst_data_d'[data_date] >= __MonthFirstDay,
                    'a05_e2e_product_fcst_data_d'[data_date] <= __MonthLastDay
                )
            ),
        __TimeFrameID = "Month",
            CALCULATE(
                SUM('a05_e2e_product_fcst_data_d'[fcst_sales_amt]),
                'a05_e2e_product_fcst_data_d'[data_date] >= __PeriodMin,
                'a05_e2e_product_fcst_data_d'[data_date] <= __PeriodMax
            ),
        BLANK()    // Quarter / Year 及其他：不计算
    )

RETURN
    DIVIDE(__Actual, __Target)
```

### 3.8 Platform Merchandising Card MTD TAR Progress Display

```dax
Platform Merchandising Card MTD TAR Progress Display =
// ========================================
// 度量值: Platform Merchandising Card MTD TAR Progress Display
// 中文名: 月度目标进度显示（卡片）
// Display Folder: Platform Merchandising Performance\Card KPIs\Display
// 用途: 卡片图 MTD TAR Progress 格式化显示，percent_1dp：百分比一位小数，不含正号
// 依赖: [Platform Merchandising Card MTD TAR Progress Value]
// 空值规则: BLANK 返回 BLANK()（卡片显示空白；"不计算"场景由此消化）
// ========================================
    VAR __Value = [Platform Merchandising Card MTD TAR Progress Value]

    RETURN
        IF(
            ISBLANK(__Value),
            BLANK(),
            FORMAT(__Value, "#,##0.0%")    // 78.3%
        )
```

### 3.9 Platform Merchandising Card YTD TAR Progress Value

```dax
Platform Merchandising Card YTD TAR Progress Value =
// ========================================
// 度量值: Platform Merchandising Card YTD TAR Progress Value
// 中文名: 年度目标进度（卡片）
// Display Folder: Platform Merchandising Performance\Card KPIs\Values
// 用途: 卡片图 YTD TAR Progress——actual 恒为 This Period 区间，分母区间随粒度分支：
//       Day / Week / Month / Quarter → 不跨财年：This actual / 所在财年汇总 target；
//                                     跨财年：不计算
//       Year                          → 始终计算，This / This（分子分母始终和
//                                     This Period 区间一致）
// 依赖: Slicer_Time_Frame[TimeFrame_ID]（时间粒度）
//       Slicer_Time_Frame_Min_This[TimeFrame_Min] / Slicer_Time_Frame_Max_This[TimeFrame_Max]
//       Slicer_Time_Frame_Max_This[Fiscal_Year_First_Day / Fiscal_Year_Last_Day]（财年区间）
//       Slicer_Time_Frame_Min_This[TimeFrame_Min_Year_Value] 与
//       Slicer_Time_Frame_Max_This[TimeFrame_Max_Year_Value]（跨财年判定，文本比较）
// 数据底表: a02_e2e_product_performance_sales_summary_d（actual）
//           a05_e2e_product_fcst_data_d（target）
// ========================================

// ── This Period 时间区间（actual）──
VAR __PeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Min_This[TimeFrame_Min])
VAR __PeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

// ── 财年区间（TimeFrame_Max 所在财年）──
VAR __YearFirstDay = SELECTEDVALUE(Slicer_Time_Frame_Max_This[Fiscal_Year_First_Day])
VAR __YearLastDay = SELECTEDVALUE(Slicer_Time_Frame_Max_This[Fiscal_Year_Last_Day])

// ── 时间粒度与跨财年判定（判定不区分粒度，直接比较财年 value 文本）──
VAR __TimeFrameID = SELECTEDVALUE(Slicer_Time_Frame[TimeFrame_ID])
VAR __IsCrossYear =
    SELECTEDVALUE(Slicer_Time_Frame_Min_This[TimeFrame_Min_Year_Value])
        <> SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max_Year_Value])

// ── actual：This Period 区间销售金额 ──
VAR __Actual =
    CALCULATE(
        SUM('a02_e2e_product_performance_sales_summary_d'[net_sales_amt]),
        'a02_e2e_product_performance_sales_summary_d'[data_date] >= __PeriodMin,
        'a02_e2e_product_performance_sales_summary_d'[data_date] <= __PeriodMax
    )

// ── target：分母区间随粒度分支 ──
// Day / Week / Month / Quarter 不跨财年取财年汇总 target；Year 直接取 This Period 区间 target
VAR __Target =
    SWITCH(
        TRUE(),
        __TimeFrameID IN {"Day", "Week", "Month", "Quarter"},
            IF(
                __IsCrossYear,
                BLANK(),    // 跨财年：不计算（外层 DIVIDE 返回 BLANK）
                CALCULATE(
                    SUM('a05_e2e_product_fcst_data_d'[fcst_sales_amt]),
                    'a05_e2e_product_fcst_data_d'[data_date] >= __YearFirstDay,
                    'a05_e2e_product_fcst_data_d'[data_date] <= __YearLastDay
                )
            ),
        __TimeFrameID = "Year",
            CALCULATE(
                SUM('a05_e2e_product_fcst_data_d'[fcst_sales_amt]),
                'a05_e2e_product_fcst_data_d'[data_date] >= __PeriodMin,
                'a05_e2e_product_fcst_data_d'[data_date] <= __PeriodMax
            ),
        BLANK()    // 其他：不计算
    )

RETURN
    DIVIDE(__Actual, __Target)

// ========================================
// 尾部注释: TAR 三指标 × 五粒度计算矩阵（actual 恒为 This Period 区间）
//   指标             Day             Week            Month           Quarter        Year
//   TAR ACH%         This/This       This/This       This/This       This/This      This/This
//   MTD Progress     不跨月:This/财月 跨月:BLANK     同Day           This/This      BLANK          BLANK
//   YTD Progress     不跨年:This/财年 跨年:BLANK     同Day           同Day          同Day          This/This
//   财月区间 = [Fiscal_Month_First_Day, Fiscal_Month_Last_Day]（TimeFrame_Max 所在财月）
//   财年区间 = [Fiscal_Year_First_Day, Fiscal_Year_Last_Day]（TimeFrame_Max 所在财年）
// ========================================
```

### 3.10 Platform Merchandising Card YTD TAR Progress Display

```dax
Platform Merchandising Card YTD TAR Progress Display =
// ========================================
// 度量值: Platform Merchandising Card YTD TAR Progress Display
// 中文名: 年度目标进度显示（卡片）
// Display Folder: Platform Merchandising Performance\Card KPIs\Display
// 用途: 卡片图 YTD TAR Progress 格式化显示，percent_1dp：百分比一位小数，不含正号
// 依赖: [Platform Merchandising Card YTD TAR Progress Value]
// 空值规则: BLANK 返回 BLANK()（卡片显示空白；"不计算"场景由此消化）
// ========================================
    VAR __Value = [Platform Merchandising Card YTD TAR Progress Value]

    RETURN
        IF(
            ISBLANK(__Value),
            BLANK(),
            FORMAT(__Value, "#,##0.0%")    // 64.9%
        )
```

---

## 4. 视觉对象配置

| 配置项 | 内容 |
| ------ | ---- |
| 视觉对象类型 | 卡片图 × 5（每指标一张卡片） |
| 数据标签 / 卡片主体 | 各指标 Display 度量值（文本） |
| 数值类条件格式（如有） | 各指标 Value 度量值（数值） |
| 视觉对象筛选器 | Slicer_Framework[framework] 固定单选（五张卡片统一配置；SLS Amt% / vs LP 的分子与 TAR 类的 actual / target 均按该 framework，SLS Amt% 与 vs LP 的分母经 ALLSELECTED 移除该筛选取全部 framework 合计） |
| 页面筛选器 | Slicer_Category / Slicer_Platform_Selection / Slicer_Store_Name / Slicer_Label 等，关系一对多自动传导，全部指标分子分母统一生效 |
| 时间筛选器 | Slicer_Time_Frame（粒度）+ Min_This / Max_This / Min_Last / Max_Last（断开维度，度量值内读取） |

---

## 5. 注意事项

1. **SLS Amt% 分母的两列 ALLSELECTED**：framework 按 sort_order 按列排序，视觉对象筛选器的 framework 筛选以 framework + sort_order 组合筛选落地，分母必须 `ALLSELECTED(Slicer_Framework[framework], Slicer_Framework[sort_order])` 两列同写——单列写法无法剥离组合筛选中的 sort_order 部分，筛选残留使分母恒等于分子（占比恒 100%）。
2. **ALLSELECTED 的语义边界**：分母移除的是视觉对象内部 framework 筛选，页面级外部切片器保留——外部 Slicer_Framework 切片器选中多个 framework 时，分母为选中集合合计（占比 = 单 framework ÷ 选中集合合计）；外部不筛选时为全部 framework 合计。Slicer_Category / 渠道 / 品牌等页面筛选器不在 ALLSELECTED 范围，分母统一受其约束。
3. **vs LP 双期同构**：This 占比与 Last 占比分子分母口径完全一致（分子单 framework、分母 ALLSELECTED 两列全部 framework 合计），差值在两个同构占比之间计算；Value 层为原始差值小数，任一侧占比为空返回 BLANK。
4. **delta_bp 与 percent_1dp 的分层**：vs LP 的 ×10000 转 bp 在 Display 层（卡片图无 Y 轴绑定，Value 保持原始差值小数）；落地格式不含正号（-152bp / 0bp，负数自带负号）。若后续 vs LP 需绑定图表 Y 轴或数值排序，×10000 需移至 Value 层并同步调整 Display。其余四指标 percent_1dp：`#,##0.0%` 一位小数百分比，不含正号。
5. **TAR 类粒度分支**：actual 恒为 This Period 区间；TAR ACH% 全粒度 This / This；MTD 在 Day / Week 不跨财月取所在财月汇总 target、Month 为 This / This、Quarter / Year 不计算；YTD 在 Day / Week / Month / Quarter 不跨财年取所在财年汇总 target、Year 始终计算且 This / This。"不计算"返回 BLANK，卡片显示空白。
6. **跨财月 / 跨财年判定**：不区分粒度，直接比较 Min_This 与 Max_This 两表的 Month_Value / Year_Value 字段（财月年均为文本类型，如 "2027-08" / "2027"）；时间粒度另行读取 `SELECTEDVALUE(Slicer_Time_Frame[TimeFrame_ID])`。
7. **日期表断开维度**：Slicer_Time_Frame 系列与 sales / a05 均无关系，全部时间区间在度量值内以 data_date 比较显式过滤；其余维度表（Slicer_Framework / Slicer_Category / Slicer_Platform_Selection / Slicer_Store_Name / Slicer_Label）与事实表一对多关联，筛选自动传导，无需显式 DAX。
8. **a05 维度同步传导**：target 侧的 framework（视觉筛选）、category / 渠道 / 品牌页面筛选经一对多关系同步传导至 a05，与 actual 侧维度口径天然一致；a05 无 TTL 预聚合值，卡片全渠道（外部筛选上下文）合计由自然聚合取得。
9. **Display 空值返回 BLANK()**：卡片图显示空白；TAR 类"不计算"场景（跨财月 / 跨财年 / Quarter / Year 的 MTD 等）由此消化。如需 "-" 占位可在 Display 层调整。
10. **汇率说明**：TAR 三指标为 actual / target 同币种相除，SLS Amt% / vs LP 为比率或差值，均不受币种选择影响；本方案无金额类指标，不涉及汇率换算与币种符号。
11. **DAX 语法规范**：文本常量使用双引号，单引号仅用于表名，列名使用方括号；与口径文档存在争议时一切以口径文档为准。
