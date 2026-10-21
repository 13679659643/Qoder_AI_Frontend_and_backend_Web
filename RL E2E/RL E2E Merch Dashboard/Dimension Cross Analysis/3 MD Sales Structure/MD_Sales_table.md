# MD Sales Table 表格解决方案

> **版本**: v1.0
> **模块**: RL E2E Merch Dashboard - Dimension Cross Analysis Tab - MD Sales Structure
> **关联口径**: 口径文档/口径Markdown格式/Dimension Cross Analysis.md - 子模块六（§19~§20）
> **数据底表**: a02_e2e_product_performance_sales_summary_d
> **关联维度**: Slicer_Time_Frame_Min_This / Max_This / Min_Last / Max_Last（时间，断开维度）；Slicer_Md_Type（行字段来源，一对多关联）；Slicer_Division（Division 商品维度，一对多关联）；Slicer_Currency_Selection（币种，断开维度）
> **筛选影响范围**: date（断开维度，DAX 显式筛选）+ 渠道（Platform + Store Name）+ Division + 其余商品维度切片器（外部筛选）

---

## 1. 需求理解

### 1.1 模块定位与视觉对象结构

本板块以 MD type 为行粒度，统计各 MD type 的销售金额占比、货值占比及其金额绝对值与 vs LP 差值：

| 视觉对象 | 行 / Y 轴               | 值 / 列                                                                                          |
| -------- | ----------------------- | ------------------------------------------------------------------------------------------------ |
| 表格     | Slicer_Md_Type[md_type] | 六个指标的 Display 列（SLS Amt%、SLS Amt、SLS Amt% vs LP、MSRP Amt%、MSRP Amt、MSRP Amt% vs LP） |
| 柱形图   | 轴 = md_type            | Y 轴绑定 vs LP 的 Value 度量值（SLS Amt% vs LP Value / MSRP Amt% vs LP Value）                   |

- **行粒度固定 MD type**：行区域拉 Slicer_Md_Type[md_type]，单级行、无层级、无行小计
- **Division 为外部筛选维度**（口径「商品维度：Division」）：Division 切片器（或视觉对象筛选器）经 Slicer_Division 与事实表一对多关系自动传递，度量值内无需感知其选择状态——占比分母保留该筛选，单选某个 Division 时为该 Division 组内占比（组内之和 = 100%），全选时为全局占比
- **vs LP 的 bp 转换在 Value 层完成**（本方案核心设计）：Value 度量值直接返回 bp 数值（差值 ×10000，如 -152），柱形图 Y 轴绑定 Value 时刻度即 bp 数值；Display 层仅拼接 "bp" 后缀不再乘算
- **行可见性**：md_type 值域来自 Slicer_Md_Type（sales 表 distinct）；当前筛选下六个指标全为 BLANK 的 md_type 行由表格自动隐藏

### 1.2 指标清单

| 序号 | 指标            | 口径章节  | 时间口径                       | 计算公式                                                                                                         | 数据类型 / 格式                  |
| ---- | --------------- | --------- | ------------------------------ | ---------------------------------------------------------------------------------------------------------------- | -------------------------------- |
| 1    | SLS Amt%        | §19      | This Period（区间）            | 分子：各 md_type 下 sum(net_sales_amt)；分母：ALLSELECTED(md_type) 全量 sum(net_sales_amt)（保留 Division 筛选） | percent_0dp → `#,##0%`        |
| 2    | SLS Amt         | §19 附属 | This Period（区间）            | 各 md_type 下 sum(net_sales_amt)，与 SLS Amt% 分子同口径                                                         | currency → 币种符号 + `#,##0` |
| 3    | SLS Amt% vs LP  | §19 附属 | This − Last Period（差值 bp） | SLS Amt%（this period）− SLS Amt%（last period），**×10000 转 bp 在 Value 层完成**（Y 轴刻度即 bp 数值） | integer_bp → `#,##0bp`        |
| 4    | MSRP Amt%       | §20      | This Period（区间）            | 分子：各 md_type 下 sum(msrp_net_sales_amt)；分母：ALLSELECTED(md_type) 全量 sum(msrp_net_sales_amt)             | percent_0dp → `#,##0%`        |
| 5    | MSRP Amt        | §20 附属 | This Period（区间）            | 各 md_type 下 sum(msrp_net_sales_amt)，与 MSRP Amt% 分子同口径                                                   | currency → 币种符号 + `#,##0` |
| 6    | MSRP Amt% vs LP | §20 附属 | This − Last Period（差值 bp） | MSRP Amt%（this period）− MSRP Amt%（last period），×10000 转 bp 在 Value 层完成                               | integer_bp → `#,##0bp`        |

### 1.3 时间口径

| 口径                              | 时间范围                                                                                            | 适用指标                                                   |
| --------------------------------- | --------------------------------------------------------------------------------------------------- | ---------------------------------------------------------- |
| This Period（区间类）             | data_date ∈ [Slicer_Time_Frame_Min_This[TimeFrame_Min], Slicer_Time_Frame_Max_This[TimeFrame_Max]] | SLS Amt%、SLS Amt、MSRP Amt%、MSRP Amt 及 vs LP 的 this 侧 |
| Last Period（vs LP 基线，区间类） | data_date ∈ [Slicer_Time_Frame_Min_Last[TimeFrame_Min], Slicer_Time_Frame_Max_Last[TimeFrame_Max]] | LP SLS Amt%、LP MSRP Amt%（vs LP 的 last 侧）              |

说明：

- 本板块全部指标为销售区间类（双底表中的 sales 表），无期末时点类指标
- Last Period 直接读 Last Period 日期切片器（Min_Last / Max_Last 表的 TimeFrame_Min / TimeFrame_Max），对比期由切片器选择决定，依赖模型中 Last 表与主时间筛选器的既有关系配置

### 1.4 币种口径

- SLS Amt / MSRP Amt 为 currency 类附属指标：货币符号由币种切片器（Slicer_Currency_Selection）决定，千分位整数
- 数据底表金额仅存储 CNY：Value 层完成汇率换算（原始值 ÷ Currency_ExchangeRate，RMB 汇率 = 1 时换算前后值相同），Display 层仅拼接币种符号
- 占比类（SLS Amt% / MSRP Amt%）与差值类（vs LP）不涉及币种换算：占比分子分母同币种，换算与否比值不变；差值为两期占比之差，同样不受币种影响

### 1.5 占比分母机制

口径「各 MD type 销售金额占 total 销售金额的比例」的分母实现：

- 分母对行维度 Slicer_Md_Type[md_type] 应用 `ALLSELECTED`：移除视觉对象内部的 md_type 行筛选，恢复外部筛选上下文下的全量 MD type 合计
- Division、Platform、Store 及其余商品维度切片器筛选全部保留：Division 单选某值时分母 = 该 Division 下全量合计（组内占比，之和 = 100%）；全选时分母 = 全局合计（全局占比）——同一套度量值天然兼容两种选择状态
- 主指标与 LP 基线占比的分母同机制：各自时间范围内的全量合计（保留外部筛选）
- 行字段从 Slicer_Md_Type 维度表拉取，行筛选直接落在维度表字段上，ALLSELECTED(维度表字段) 正确移除后经一对多关系向事实表正向传导，分母恢复全量

---

## 2. 现状分析

- 数据底表 `a02_e2e_product_performance_sales_summary_d`（日粒度汇总）：net_sales_amt（净销售金额，SLS 系列分子分母口径字段）、msrp_net_sales_amt（吊牌价净销售金额，MSRP 系列分子分母口径字段）；维度含 platform、shop_name、division、md_type 及其余商品维度；日期字段为 data_date（date 类型）；platform 已在数据源层过滤 IN ('JD','TM','RLE','DY')
- 本板块全部指标取自 sales 单表，不涉及库存表，无期末时点类指标
- 模型关系：Slicer_Md_Type、Slicer_Division 与事实表一对多关联，筛选自动传递；Slicer_Platform_Selection、Slicer_Store_Name 与 sales 表一对多关联；日期筛选器（Min_This / Max_This / Min_Last / Max_Last）为断开维度，时间范围在 DAX 中显式筛选；Slicer_Currency_Selection 为断开维度，汇率与符号经 SELECTEDVALUE 读取
- 字段名已逐一核对数据字典（net_sales_amt / msrp_net_sales_amt）

---

## 3. 方案设计

### 3.1 度量值分层

```
Value（口径计算）
←  分子 / 分母时间范围显式筛选（This Period / Last Period）
←  占比分母：ALLSELECTED(Slicer_Md_Type[md_type])——移除 md_type 行筛选，
    保留 Division / 渠道 / 商品维度切片器等全部外部筛选
←  金额类 Value 层完成币种汇率换算（原始 CNY ÷ Currency_ExchangeRate）
←  LP 中间度量值（LP SLS Amt% / LP MSRP Amt%）供 vs LP 派生引用
↓
vs LP Value（差值 ×10000，bp 数值）
←  This 期占比 − LP 期占比 后 ×10000，直接返回 bp 数值（如 -152）
←  任一侧 BLANK 时返回 BLANK
←  ×10000 转换在本层完成：柱形图 Y 轴绑定 Value 时刻度即 bp 数值
↓
Display（格式化显示）
←  percent_0dp: FORMAT(#,##0%)；currency: 币种符号 & FORMAT(#,##0)
←  integer_bp: FORMAT(#,##0) & "bp"（Value 已是 bp 数值，仅拼接后缀）
←  BLANK 统一显示 "-"
```

### 3.2 占比分母机制

- 分母 `ALLSELECTED('Slicer_Md_Type')` 仅移除 md_type 的视觉对象内部行筛选；Division、渠道与全部商品维度切片器筛选保留
- ALLSELECTED 与 REMOVEFILTERS 的语义差异是分母正确性的关键：REMOVEFILTERS 会移除该列全部筛选，但需注意其无法用于此处分母的原因在于 md_type 行筛选必须被移除而外部筛选必须保留，ALLSELECTED 恰好实现「移除视觉对象内部筛选、保留外部切片器筛选」
- Division 的选择状态对度量值不可见：单选 → 组内占比（之和 100%）；全选 → 全局占比（之和 100%）；无论何种状态，各 md_type 占比之和恒为 100%

### 3.3 vs LP 与 bp 转换位置

- vs LP Value = (This 期占比 − LP 期占比) × 10000，直接返回 bp 数值；任一侧 BLANK 时返回 BLANK（避免单侧缺失产生失真差值）
- **×10000 转换在 Value 层完成**：柱形图 Y 轴直接绑定 vs LP Value 度量值，轴刻度显示 bp 数值（如 -152、-100、-50）；Display 层仅做 FORMAT(#,##0) & "bp" 拼接，不再乘算
- 差值依赖 LP 基线占比：LP SLS Amt% / LP MSRP Amt% 作为独立中间度量值输出（分母机制、时间口径与 This 侧一致，仅时间范围替换为 Last Period）

### 3.4 度量值命名与组织

- 命名规则：模块前缀 `MD Sales Table` + 指标名 + 层次后缀（Value / Display）；LP 中间度量值在指标名前加 `LP`
- Display Folder：`MD Sales Structure\Base Metrics`（Value 层）、`MD Sales Structure\Formatting`（Display 层）
- 度量值统一存放于 `_Measures` 隐藏表

---

## 4. 度量值实现

### 4.1 MD Sales Table SLS Amt% Value（当期销售金额占比）

```dax
MD Sales Table SLS Amt% Value =
// ========================================
// 度量值: MD Sales Table SLS Amt% Value
// 中文名: 当期销售金额占比
// Display Folder: MD Sales Structure\Base Metrics
// 用途: 各 MD type 销售金额占 total 销售金额的比例（This Period 区间），
//       Division / 渠道 / 商品维度切片器筛选保留于分子分母
// 依赖: Slicer_Time_Frame_Min_This[TimeFrame_Min] / Slicer_Time_Frame_Max_This[TimeFrame_Max]
// 口径: 时间范围看 this period；
//       分子：各 md_type 下 sum(net_sales_amt)；分母：全量 sum(net_sales_amt)
// 数据底表: a02_e2e_product_performance_sales_summary_d
// 分母机制: ALLSELECTED(Slicer_Md_Type[md_type])——移除视觉对象内部的
//       md_type 行筛选，保留 Division / 渠道 / 商品维度切片器等全部外部
//       筛选；Division 单选时为该 Division 组内占比（之和 100%），
//       全选时为全局占比（之和 100%），同一套度量值兼容两种状态
// 币种: 分子分母为同表同币种金额（底表 CNY），占比不受币种选择影响
// ========================================

// ── This Period 时间区间 ──
VAR __PeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Min_This[TimeFrame_Min])
VAR __PeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

// ── 分子：当前 md_type This Period 净销售金额（行筛选自动传导）──
VAR __Numerator =
    CALCULATE(
        SUM('a02_e2e_product_performance_sales_summary_d'[net_sales_amt]),
        'a02_e2e_product_performance_sales_summary_d'[data_date] >= __PeriodMin,
        'a02_e2e_product_performance_sales_summary_d'[data_date] <= __PeriodMax
    )

// ── 分母：外部筛选上下文下的全量 This Period 净销售金额 ──
// ALLSELECTED(md_type)：移除行维度视觉对象内部筛选，保留外部切片器筛选
VAR __Denominator =
    CALCULATE(
        SUM('a02_e2e_product_performance_sales_summary_d'[net_sales_amt]),
        ALLSELECTED('Slicer_Md_Type'),
        'a02_e2e_product_performance_sales_summary_d'[data_date] >= __PeriodMin,
        'a02_e2e_product_performance_sales_summary_d'[data_date] <= __PeriodMax
    )

RETURN
    DIVIDE(__Numerator, __Denominator)
```

### 4.2 MD Sales Table SLS Amt% Display（当期销售金额占比显示）

```dax
MD Sales Table SLS Amt% Display =
// ========================================
// 度量值: MD Sales Table SLS Amt% Display
// 中文名: 当期销售金额占比显示
// Display Folder: MD Sales Structure\Formatting
// 用途: percent_0dp 格式化（百分比整数，不含正号）；BLANK 显示 "-"
// 依赖: [MD Sales Table SLS Amt% Value]
// 数据格式: #,##0%（如 26%）
// ========================================
    VAR __Value = [MD Sales Table SLS Amt% Value]
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            FORMAT(__Value, "#,##0%")
        )
```

### 4.3 MD Sales Table LP SLS Amt% Value（LP 销售金额占比，中间度量值）

```dax
MD Sales Table LP SLS Amt% Value =
// ========================================
// 度量值: MD Sales Table LP SLS Amt% Value
// 中文名: LP 销售金额占比（vs LP 对比基线）
// Display Folder: MD Sales Structure\Base Metrics
// 用途: Last Period 销售金额占比，供 SLS Amt% vs LP 派生引用，不直接进视觉对象
// 依赖: Slicer_Time_Frame_Min_Last[TimeFrame_Min] / Slicer_Time_Frame_Max_Last[TimeFrame_Max]
// 口径: 与 SLS Amt% 同构（分母 ALLSELECTED(md_type) 保留外部筛选），
//       仅时间范围替换为 Last Period 日期切片器（对比期由切片器选择决定）
// ========================================

// ── Last Period 时间区间（vs LP 基线）──
VAR __PeriodMin_LP = SELECTEDVALUE(Slicer_Time_Frame_Min_Last[TimeFrame_Min])
VAR __PeriodMax_LP = SELECTEDVALUE(Slicer_Time_Frame_Max_Last[TimeFrame_Max])

// ── 分子：当前 md_type Last Period 净销售金额 ──
VAR __Numerator =
    CALCULATE(
        SUM('a02_e2e_product_performance_sales_summary_d'[net_sales_amt]),
        'a02_e2e_product_performance_sales_summary_d'[data_date] >= __PeriodMin_LP,
        'a02_e2e_product_performance_sales_summary_d'[data_date] <= __PeriodMax_LP
    )

// ── 分母：外部筛选上下文下的全量 Last Period 净销售金额 ──
VAR __Denominator =
    CALCULATE(
        SUM('a02_e2e_product_performance_sales_summary_d'[net_sales_amt]),
        ALLSELECTED('Slicer_Md_Type'),
        'a02_e2e_product_performance_sales_summary_d'[data_date] >= __PeriodMin_LP,
        'a02_e2e_product_performance_sales_summary_d'[data_date] <= __PeriodMax_LP
    )

RETURN
    DIVIDE(__Numerator, __Denominator)
```

### 4.4 MD Sales Table SLS Amt% vs LP Value（销售金额占比 vs LP 差值，bp 数值）

```dax
MD Sales Table SLS Amt% vs LP Value =
// ========================================
// 度量值: MD Sales Table SLS Amt% vs LP Value
// 中文名: 销售金额占比 vs LP（bp 数值）
// Display Folder: MD Sales Structure\Base Metrics
// 用途: this period - last period 占比差值，×10000 转 bp 在本层完成，
//       直接返回 bp 数值（如 -0.0152 → -152）——柱形图 Y 轴绑定本度量值
//       时刻度即 bp 数值
// 依赖: [MD Sales Table SLS Amt% Value], [MD Sales Table LP SLS Amt% Value]
// 口径: this period - last period（差值，bp 指标）
// 转换位置: ×10000 在 Value 层实现（非 Display 层）——Y 轴 / 数值排序 /
//       条件格式直接使用 bp 数值；Display 层仅拼接 "bp" 后缀不再乘算
// 边界: 任一期为 BLANK 时返回 BLANK，避免单侧缺失产生失真差值
// ========================================
    VAR __ThisPct = [MD Sales Table SLS Amt% Value]
    VAR __LastPct = [MD Sales Table LP SLS Amt% Value]

    RETURN
        IF(
            ISBLANK(__ThisPct) || ISBLANK(__LastPct),
            BLANK(),
            (__ThisPct - __LastPct) * 10000    // ×10000 转 bp（Value 层完成，Y 轴刻度即 bp 数值）
        )
```

### 4.5 MD Sales Table SLS Amt% vs LP Display（销售金额占比 vs LP 显示）

```dax
MD Sales Table SLS Amt% vs LP Display =
// ========================================
// 度量值: MD Sales Table SLS Amt% vs LP Display
// 中文名: 销售金额占比 vs LP 显示
// Display Folder: MD Sales Structure\Formatting
// 用途: integer_bp 格式化：Value 已是 bp 数值，仅拼接 "bp" 后缀；
//       负数自带负号，零值 0bp；BLANK 显示 "-"
// 依赖: [MD Sales Table SLS Amt% vs LP Value]
// 数据格式: #,##0bp;-#,##0bp;0bp
// 说明: ×10000 转换已在 Value 层完成，本层不再乘算
// ========================================
    VAR __Value = [MD Sales Table SLS Amt% vs LP Value]
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            FORMAT(__Value, "#,##0") & "bp"    // Value 已是 bp 数值（如 -152 → -152bp）
        )
```

### 4.6 MD Sales Table SLS Amt Value（当期净销售金额，金额附属）

```dax
MD Sales Table SLS Amt Value =
// ========================================
// 度量值: MD Sales Table SLS Amt Value
// 中文名: 当期净销售金额（金额附属，当前币种）
// Display Folder: MD Sales Structure\Base Metrics
// 用途: SLS Amt%（§19）的金额类附属——各 md_type This Period 净销售金额
//       绝对值（与占比分子同口径），表格展示与交叉验证
// 依赖: Slicer_Time_Frame_Min_This[TimeFrame_Min] / Slicer_Time_Frame_Max_This[TimeFrame_Max]
//       Slicer_Currency_Selection[Currency_ExchangeRate]
// 口径: 时间范围看 this period；各 md_type 下 sum(net_sales_amt)
// 数据底表: a02_e2e_product_performance_sales_summary_d
// 币种: 数据底表仅存 CNY，Value 层换算为当前币种金额（原始值 ÷ 汇率）；
//       RMB 汇率 = 1 时换算前后值相同
// ========================================

// ── This Period 时间区间 ──
VAR __PeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Min_This[TimeFrame_Min])
VAR __PeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

// ── 币种汇率（RMB = 1；USD 动态取自数仓汇率表）──
VAR __ExchangeRate = SELECTEDVALUE(Slicer_Currency_Selection[Currency_ExchangeRate], 1)

// ── 各 md_type This Period 净销售金额（原始 CNY，行筛选自动传导）──
VAR __BaseValue =
    CALCULATE(
        SUM('a02_e2e_product_performance_sales_summary_d'[net_sales_amt]),
        'a02_e2e_product_performance_sales_summary_d'[data_date] >= __PeriodMin,
        'a02_e2e_product_performance_sales_summary_d'[data_date] <= __PeriodMax
    )

RETURN
    DIVIDE(__BaseValue, __ExchangeRate)   // BLANK ÷ 汇率 = BLANK（当期无销售数据返回空）
```

### 4.7 MD Sales Table SLS Amt Display（当期净销售金额显示）

```dax
MD Sales Table SLS Amt Display =
// ========================================
// 度量值: MD Sales Table SLS Amt Display
// 中文名: 当期净销售金额显示
// Display Folder: MD Sales Structure\Formatting
// 用途: currency 格式化（币种符号 + 千分位整数，符号由币种切片器决定）；BLANK 显示 "-"
// 依赖: [MD Sales Table SLS Amt Value], Slicer_Currency_Selection[Currency_Symbol]
// 数据格式: 币种符号 & #,##0（如 ¥1,000 / $1,000）
// ========================================
    VAR __Value = [MD Sales Table SLS Amt Value]
    VAR __CurrencySymbol = SELECTEDVALUE(Slicer_Currency_Selection[Currency_Symbol], "¥")
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            __CurrencySymbol & FORMAT(__Value, "#,##0")
        )
```

### 4.8 MD Sales Table MSRP Amt% Value（当期货值占比）

```dax
MD Sales Table MSRP Amt% Value =
// ========================================
// 度量值: MD Sales Table MSRP Amt% Value
// 中文名: 当期货值占比
// Display Folder: MD Sales Structure\Base Metrics
// 用途: 各 MD type 货值（吊牌价金额）占 total 货值的比例（This Period 区间），
//       分母机制与 SLS Amt% 一致（ALLSELECTED(md_type) 保留全部外部筛选）
// 依赖: Slicer_Time_Frame_Min_This[TimeFrame_Min] / Slicer_Time_Frame_Max_This[TimeFrame_Max]
// 口径: 时间范围看 this period；
//       分子：各 md_type 下 sum(msrp_net_sales_amt)；
//       分母：全量 sum(msrp_net_sales_amt)
// 数据底表: a02_e2e_product_performance_sales_summary_d
// 币种: 分子分母为同表同币种金额（底表 CNY），占比不受币种选择影响
// ========================================

// ── This Period 时间区间 ──
VAR __PeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Min_This[TimeFrame_Min])
VAR __PeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

// ── 分子：当前 md_type This Period 吊牌价净销售金额 ──
VAR __Numerator =
    CALCULATE(
        SUM('a02_e2e_product_performance_sales_summary_d'[msrp_net_sales_amt]),
        'a02_e2e_product_performance_sales_summary_d'[data_date] >= __PeriodMin,
        'a02_e2e_product_performance_sales_summary_d'[data_date] <= __PeriodMax
    )

// ── 分母：外部筛选上下文下的全量 This Period 吊牌价净销售金额 ──
VAR __Denominator =
    CALCULATE(
        SUM('a02_e2e_product_performance_sales_summary_d'[msrp_net_sales_amt]),
        ALLSELECTED('Slicer_Md_Type'),
        'a02_e2e_product_performance_sales_summary_d'[data_date] >= __PeriodMin,
        'a02_e2e_product_performance_sales_summary_d'[data_date] <= __PeriodMax
    )

RETURN
    DIVIDE(__Numerator, __Denominator)
```

### 4.9 MD Sales Table MSRP Amt% Display（当期货值占比显示）

```dax
MD Sales Table MSRP Amt% Display =
// ========================================
// 度量值: MD Sales Table MSRP Amt% Display
// 中文名: 当期货值占比显示
// Display Folder: MD Sales Structure\Formatting
// 用途: percent_0dp 格式化（百分比整数，不含正号）；BLANK 显示 "-"
// 依赖: [MD Sales Table MSRP Amt% Value]
// 数据格式: #,##0%（如 31%）
// ========================================
    VAR __Value = [MD Sales Table MSRP Amt% Value]
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            FORMAT(__Value, "#,##0%")
        )
```

### 4.10 MD Sales Table LP MSRP Amt% Value（LP 货值占比，中间度量值）

```dax
MD Sales Table LP MSRP Amt% Value =
// ========================================
// 度量值: MD Sales Table LP MSRP Amt% Value
// 中文名: LP 货值占比（vs LP 对比基线）
// Display Folder: MD Sales Structure\Base Metrics
// 用途: Last Period 货值占比，供 MSRP Amt% vs LP 派生引用，不直接进视觉对象
// 依赖: Slicer_Time_Frame_Min_Last[TimeFrame_Min] / Slicer_Time_Frame_Max_Last[TimeFrame_Max]
// 口径: 与 MSRP Amt% 同构（分母 ALLSELECTED(md_type) 保留外部筛选），
//       仅时间范围替换为 Last Period 日期切片器
// ========================================

// ── Last Period 时间区间（vs LP 基线）──
VAR __PeriodMin_LP = SELECTEDVALUE(Slicer_Time_Frame_Min_Last[TimeFrame_Min])
VAR __PeriodMax_LP = SELECTEDVALUE(Slicer_Time_Frame_Max_Last[TimeFrame_Max])

// ── 分子：当前 md_type Last Period 吊牌价净销售金额 ──
VAR __Numerator =
    CALCULATE(
        SUM('a02_e2e_product_performance_sales_summary_d'[msrp_net_sales_amt]),
        'a02_e2e_product_performance_sales_summary_d'[data_date] >= __PeriodMin_LP,
        'a02_e2e_product_performance_sales_summary_d'[data_date] <= __PeriodMax_LP
    )

// ── 分母：外部筛选上下文下的全量 Last Period 吊牌价净销售金额 ──
VAR __Denominator =
    CALCULATE(
        SUM('a02_e2e_product_performance_sales_summary_d'[msrp_net_sales_amt]),
        ALLSELECTED('Slicer_Md_Type'),
        'a02_e2e_product_performance_sales_summary_d'[data_date] >= __PeriodMin_LP,
        'a02_e2e_product_performance_sales_summary_d'[data_date] <= __PeriodMax_LP
    )

RETURN
    DIVIDE(__Numerator, __Denominator)
```

### 4.11 MD Sales Table MSRP Amt% vs LP Value（货值占比 vs LP 差值，bp 数值）

```dax
MD Sales Table MSRP Amt% vs LP Value =
// ========================================
// 度量值: MD Sales Table MSRP Amt% vs LP Value
// 中文名: 货值占比 vs LP（bp 数值）
// Display Folder: MD Sales Structure\Base Metrics
// 用途: this period - last period 占比差值，×10000 转 bp 在本层完成，
//       直接返回 bp 数值（如 0.0121 → 121）——柱形图 Y 轴绑定本度量值
//       时刻度即 bp 数值
// 依赖: [MD Sales Table MSRP Amt% Value], [MD Sales Table LP MSRP Amt% Value]
// 口径: this period - last period（差值，bp 指标）
// 转换位置: ×10000 在 Value 层实现（非 Display 层）——Y 轴 / 数值排序 /
//       条件格式直接使用 bp 数值；Display 层仅拼接 "bp" 后缀不再乘算
// 边界: 任一期为 BLANK 时返回 BLANK，避免单侧缺失产生失真差值
// ========================================
    VAR __ThisPct = [MD Sales Table MSRP Amt% Value]
    VAR __LastPct = [MD Sales Table LP MSRP Amt% Value]

    RETURN
        IF(
            ISBLANK(__ThisPct) || ISBLANK(__LastPct),
            BLANK(),
            (__ThisPct - __LastPct) * 10000    // ×10000 转 bp（Value 层完成，Y 轴刻度即 bp 数值）
        )
```

### 4.12 MD Sales Table MSRP Amt% vs LP Display（货值占比 vs LP 显示）

```dax
MD Sales Table MSRP Amt% vs LP Display =
// ========================================
// 度量值: MD Sales Table MSRP Amt% vs LP Display
// 中文名: 货值占比 vs LP 显示
// Display Folder: MD Sales Structure\Formatting
// 用途: integer_bp 格式化：Value 已是 bp 数值，仅拼接 "bp" 后缀；
//       负数自带负号，零值 0bp；BLANK 显示 "-"
// 依赖: [MD Sales Table MSRP Amt% vs LP Value]
// 数据格式: #,##0bp;-#,##0bp;0bp
// 说明: ×10000 转换已在 Value 层完成，本层不再乘算
// ========================================
    VAR __Value = [MD Sales Table MSRP Amt% vs LP Value]
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            FORMAT(__Value, "#,##0") & "bp"    // Value 已是 bp 数值（如 121 → 121bp）
        )
```

### 4.13 MD Sales Table MSRP Amt Value（当期货值金额，金额附属）

```dax
MD Sales Table MSRP Amt Value =
// ========================================
// 度量值: MD Sales Table MSRP Amt Value
// 中文名: 当期货值金额（金额附属，当前币种）
// Display Folder: MD Sales Structure\Base Metrics
// 用途: MSRP Amt%（§20）的金额类附属——各 md_type This Period 吊牌价净销售
//       金额绝对值（与占比分子同口径），表格展示与交叉验证
// 依赖: Slicer_Time_Frame_Min_This[TimeFrame_Min] / Slicer_Time_Frame_Max_This[TimeFrame_Max]
//       Slicer_Currency_Selection[Currency_ExchangeRate]
// 口径: 时间范围看 this period；各 md_type 下 sum(msrp_net_sales_amt)
// 数据底表: a02_e2e_product_performance_sales_summary_d
// 币种: 数据底表仅存 CNY，Value 层换算为当前币种金额（原始值 ÷ 汇率）；
//       RMB 汇率 = 1 时换算前后值相同
// ========================================

// ── This Period 时间区间 ──
VAR __PeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Min_This[TimeFrame_Min])
VAR __PeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

// ── 币种汇率（RMB = 1；USD 动态取自数仓汇率表）──
VAR __ExchangeRate = SELECTEDVALUE(Slicer_Currency_Selection[Currency_ExchangeRate], 1)

// ── 各 md_type This Period 吊牌价净销售金额（原始 CNY，行筛选自动传导）──
VAR __BaseValue =
    CALCULATE(
        SUM('a02_e2e_product_performance_sales_summary_d'[msrp_net_sales_amt]),
        'a02_e2e_product_performance_sales_summary_d'[data_date] >= __PeriodMin,
        'a02_e2e_product_performance_sales_summary_d'[data_date] <= __PeriodMax
    )

RETURN
    DIVIDE(__BaseValue, __ExchangeRate)   // BLANK ÷ 汇率 = BLANK（当期无销售数据返回空）
```

### 4.14 MD Sales Table MSRP Amt Display（当期货值金额显示）

```dax
MD Sales Table MSRP Amt Display =
// ========================================
// 度量值: MD Sales Table MSRP Amt Display
// 中文名: 当期货值金额显示
// Display Folder: MD Sales Structure\Formatting
// 用途: currency 格式化（币种符号 + 千分位整数，符号由币种切片器决定）；BLANK 显示 "-"
// 依赖: [MD Sales Table MSRP Amt Value], Slicer_Currency_Selection[Currency_Symbol]
// 数据格式: 币种符号 & #,##0（如 ¥1,000 / $1,000）
// ========================================
    VAR __Value = [MD Sales Table MSRP Amt Value]
    VAR __CurrencySymbol = SELECTEDVALUE(Slicer_Currency_Selection[Currency_Symbol], "¥")
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            __CurrencySymbol & FORMAT(__Value, "#,##0")
        )
```

### 4.15 MD Sales Table IsEmpty(可以共用同一个度量作用于视觉对象筛选器)

```dax
MD Sales Table IsEmpty =
// ========================================
// 度量值: MD Sales Table IsEmpty
// 中文名: 行非空判定
// Display Folder: MD Sales Table IsEmpty\IsEmpty
// 用途: 行可见性判定——该行全部核心指标为空时返回 0，任一有值返回 1；
//       用于表格视觉级筛选器（IsEmpty = 1 仅显示有数据的行，
// ========================================
    IF(
        ISBLANK([MD Sales Table SLS Amt% Value]) &&
        ISBLANK([MD Sales Table SLS Amt% vs LP Value]) &&
        ISBLANK([MD Sales Table MSRP Amt% Value]) &&
        ISBLANK([MD Sales Table MSRP Amt% vs LP Value]),
        0,
        1
    )
```

---

## 5. 度量值清单

| # | 度量值                                         | 指标类型                       | 用于视觉对象                          |
| - | ---------------------------------------------- | ------------------------------ | ------------------------------------- |
| 1 | MD Sales Table SLS Amt% Value / Display        | percent_0dp                    | 表格                                  |
| 2 | MD Sales Table LP SLS Amt% Value               | percent_0dp（中间值）          | 仅被 vs LP 引用                       |
| 3 | MD Sales Table SLS Amt% vs LP Value / Display  | integer_bp（Value 为 bp 数值） | Value 绑定柱形图 Y 轴；Display 进表格 |
| 4 | MD Sales Table SLS Amt Value / Display         | currency                       | 表格                                  |
| 5 | MD Sales Table MSRP Amt% Value / Display       | percent_0dp                    | 表格                                  |
| 6 | MD Sales Table LP MSRP Amt% Value              | percent_0dp（中间值）          | 仅被 vs LP 引用                       |
| 7 | MD Sales Table MSRP Amt% vs LP Value / Display | integer_bp（Value 为 bp 数值） | Value 绑定柱形图 Y 轴；Display 进表格 |
| 8 | MD Sales Table MSRP Amt Value / Display        | currency                       | 表格                                  |

- 全部度量值存放于 `_Measures` 隐藏表；Display Folder：`MD Sales Structure\Base Metrics`（Value 层）与 `MD Sales Structure\Formatting`（Display 层）
- LP 中间度量值共 2 个（LP SLS Amt% / LP MSRP Amt%），不直接进视觉对象

---

## 6. 视觉对象配置

### 6.1 表格

| 配置项             | 内容                                                                                                                              |
| ------------------ | --------------------------------------------------------------------------------------------------------------------------------- |
| 视觉对象类型       | 表格                                                                                                                              |
| 行                 | Slicer_Md_Type[md_type]                                                                                                           |
| 值列（按口径顺序） | SLS Amt% Display → SLS Amt Display → SLS Amt% vs LP Display → MSRP Amt% Display → MSRP Amt Display → MSRP Amt% vs LP Display |
| 列标题             | 按口径指标名（SLS Amt% / SLS Amt / SLS Amt% vs LP / MSRP Amt% / MSRP Amt / MSRP Amt% vs LP）                                      |
| 行可见性           | 六个指标全为 BLANK 的 md_type 行由表格自动隐藏                                                                                    |
| 总计               | 单级行无行小计需求；若开启总计行，占比类总计 = 100%（分子分母同范围），vs LP 总计为全量分子分母重算后的 bp 差值                   |

### 6.2 柱形图（vs LP 差值）

| 配置项         | 内容                                                                                                                       |
| -------------- | -------------------------------------------------------------------------------------------------------------------------- |
| 视觉对象类型   | 簇状 / 条形柱形图                                                                                                          |
| X 轴（或类别） | Slicer_Md_Type[md_type]                                                                                                    |
| Y 轴           | MD Sales Table SLS Amt% vs LP Value（bp 数值，轴刻度即 bp）；或 MD Sales Table MSRP Amt% vs LP Value                       |
| 数据标签       | 可绑 Display 度量值（带 bp 后缀文本）或默认数值标签（bp 数值）                                                             |
| 说明           | Y 轴必须绑定 Value 度量值（×10000 已在 Value 层完成），刻度与数据标签即为 bp 数值；Display 度量值为文本类型，不能作轴字段 |

### 6.3 切片器

| 切片器                                        | 类型         | 作用                                                                                   |
| --------------------------------------------- | ------------ | -------------------------------------------------------------------------------------- |
| Slicer_Time_Frame                             | 主时间筛选器 | 驱动 Min_This / Max_This / Min_Last / Max_Last 断开维度表，经 SELECTEDVALUE 读入度量值 |
| Slicer_Division                               | 一对多关联   | Division 商品维度筛选自动传递；占比分母经 ALLSELECTED(md_type) 保留该筛选              |
| Slicer_Platform_Selection / Slicer_Store_Name | 一对多关联   | 渠道筛选自动传递                                                                       |
| 其余商品维度切片器（Slicer_Category 等）      | 一对多关联   | 外部筛选自动传递；占比分母保留该筛选                                                   |
| Slicer_Currency_Selection                     | 断开维度     | SLS Amt / MSRP Amt 金额附属的汇率与符号来源；占比与差值类不受影响                      |

---

## 7. 验证方法

验证 SQL 为 MySQL 8.0+ 语法（CTE / 窗口函数），与配套测试文件 `test_MD_Sales_table.sql` 对应；输出 division × md_type 全组合，对数时按 Division 切片器当前选择筛选 division 列后与 PBI 视觉对象逐行对比。

| 指标                             | 测试 SQL 还原                                                                                                                                     |
| -------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------- |
| SLS Amt% / MSRP Amt%             | (division, md_type) 粒度聚合 net_sales_amt / msrp_net_sales_amt；分母 = SUM() OVER (PARTITION BY division)（对应 ALLSELECTED 保留 Division 筛选） |
| SLS Amt / MSRP Amt               | 同上分子聚合，输出 RMB 原始值（PBI Value 层 ÷ 汇率换算，RMB 时直接对比）                                                                         |
| SLS Amt% vs LP / MSRP Amt% vs LP | 时间条件替换为 Last Period 重跑占比，差值 ×10000 直接输出 bp 数值（对齐 Value 层转换位置）                                                       |

- NULL 语义对齐：分子 NULL → 占比 NULL（对应 DAX BLANK，显示 "-"）；差值任一侧 NULL → NULL
- 时间参数与替换方法见测试文件头部参数区

---

## 8. 注意事项

1. **bp 转换位置在 Value 层**：SLS Amt% vs LP / MSRP Amt% vs LP 的 ×10000 转换在 Value 度量值内完成，Value 直接返回 bp 数值——柱形图 Y 轴、数值排序、条件格式均直接使用 bp 数值；Display 层仅做 FORMAT(#,##0) & "bp" 拼接不再乘算。绑定时注意：Y 轴与排序用 Value（数值），表格展示用 Display（文本），两者不可混绑（Display 为文本类型不能作轴字段）
2. **占比分母保留全部外部筛选**：分母 `ALLSELECTED('Slicer_Md_Type')` 仅移除 md_type 行筛选，保留 Division / 渠道 / 商品维度切片器筛选——Division 单选时为组内占比（之和 100%），全选时为全局占比（之和 100%）
3. **行字段必须从 Slicer_Md_Type 维度表拉取**：行筛选直接落在维度表字段上，ALLSELECTED(维度表字段) 才能正确移除；若误用事实表字段作行字段，维度表字段上无视觉对象内部筛选，ALLSELECTED 为无效操作，占比恒 100%
4. **Last Period 读取方式**：直接读 Min_Last / Max_Last 筛选器的 TimeFrame_Min / TimeFrame_Max，对比期由 Last Period 日期切片器自由选择，依赖模型中 Last 表与主时间筛选器的既有关系配置
5. **vs LP 空值规则**：任一期占比为 BLANK 时差值返回 BLANK（显示 "-"），避免单侧缺失产生失真差值
6. **币种**：SLS Amt / MSRP Amt 金额附属按 currency 口径处理——Value 层 ÷ Currency_ExchangeRate 换算（RMB 汇率 = 1 时值不变），Display 层拼接 Currency_Symbol（#,##0）；占比与差值类分子分母同币种，不受币种切片器影响
7. **总计行为**：若表格开启总计行，占比类总计 = 100%（分子分母同范围），vs LP 总计 = 全量分子分母重算后的 bp 差值（非各行差值之和），均为汇总语义下的正确行为
8. **口径与语法**：口径文档中定义的所有指标必须遵守其数据类型与数据格式，与解决方案存在争议时一切以口径文档为准；DAX 文本常量使用双引号，单引号仅用于表名，列名使用方括号，例如：`[md_type] = "FP"`
