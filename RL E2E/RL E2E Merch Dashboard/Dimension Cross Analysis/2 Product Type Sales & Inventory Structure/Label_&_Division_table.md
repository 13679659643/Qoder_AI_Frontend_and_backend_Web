# Label & Division Table 表格解决方案

> **版本**: v1.0
> **模块**: RL E2E Merch Dashboard - Dimension Cross Analysis Tab - Product Type Sales & Inventory Structure【Category × Division/Label】
> **关联口径**: 口径文档/口径Markdown格式/Dimension Cross Analysis.md - 子模块五（§17~§18）
> **数据底表（销售类）**: a02_e2e_product_performance_sales_summary_d
> **数据底表（库存类）**: a02_e2e_product_performance_inv_summary_d
> **关联维度**: Slicer_Time_Frame_Min_This / Max_This / Min_Last / Max_Last（时间，断开维度；vs LY 的去年区间取自 Min_This / Max_This 表的 _LY 字段）；Slicer_Category（行字段来源）；Slicer_Division / Slicer_Label（视觉对象筛选器，一对多关联）；Slicer_Currency_Selection（币种，断开维度）
> **筛选影响范围**: date（断开维度，DAX 显式筛选）+ 渠道（Platform + Store Name，仅销售侧）+ Division / Label 视觉对象筛选器（双表自动传递）+ 商品维度切片器（外部筛选）

---

## 1. 需求理解

### 1.1 模块定位与视觉对象结构

本板块以 Category 为固定粒度，Division / Label 作为视觉对象筛选器固定单值形成分组表，统计各 Category 在所属分组内的销售金额占比与期末库存金额占比及其 vs LP / vs LY 附属指标：

| 视觉对象 | 分组筛选器（视觉对象级，单值） | 行 | 值列（6 列） |
|---|---|---|---|
| Division 分组表 ×4 | Slicer_Division[division]，每表固定一个值（CW / HM / MN / WM） | Slicer_Category[category] | SLS Amt%、SLS Amt% vs LP、SLS Amt% vs LY、EOH Amt%、EOH Amt% vs LP、EOH Amt% vs LY |
| Label 分组表 ×N | Slicer_Label[label]，每表固定一个值（值域 = sales 表 brand distinct） | 同上 | 同上 |

- **行粒度固定 Category**：行区域拉 Slicer_Category[category]，无层级、无行小计（单级行）
- **Division / Label 为视觉对象筛选器而非行维度**：页面通过多个表格视觉对象各固定一个 Division / Label 值形成分组展示；该筛选经 Slicer_Division / Slicer_Label 与双事实表的一对多关系自动传递，度量值内无需感知分组模式——**同一套度量值同时服务 Division 分组表与 Label 分组表**
- **行可见性**：Category 值域来自 Slicer_Category（sales 表 distinct）；当前分组筛选值下六个指标全为 BLANK 的 Category 行由表格自动隐藏（含该分组下无任何销售与库存记录的 Category）

### 1.2 指标清单

| 序号 | 指标 | 口径章节 | 时间口径 | 计算公式 | 数据类型 / 格式 |
|---|---|---|---|---|---|
| 1 | SLS Amt% | §17 | This Period（区间） | 分子：该分组值 × Category 下 sum(net_sales_amt)；分母：该分组值下全量 sum(net_sales_amt)（ALLSELECTED Category，组内分母） | percent_0dp → `#,##0%` |
| 2 | SLS Amt% vs LP | §17 附属 | This − Last Period（差值） | SLS Amt%（this period）− SLS Amt%（last period），原始差值，×10000 转 bp 在 Display 层 | delta_bp → `#,##0bp` |
| 3 | SLS Amt% vs LY | §17 附属 | This − Last Year（差值） | SLS Amt%（this year）− SLS Amt%（last year），原始差值，×10000 转 bp 在 Display 层 | delta_bp → `#,##0bp` |
| 4 | EOH Amt% | §18 | End Period（期末时点） | 分子：该分组值 × Category 下 sum(msrp_inv_amt)（快照日单日）；分母：该分组值下全量 sum(msrp_inv_amt)（ALLSELECTED Category，组内分母） | percent_0dp → `#,##0%` |
| 5 | EOH Amt% vs LP | §18 附属 | 快照日 this − 快照日 LP（差值） | EOH Amt%（this 快照日）− EOH Amt%（LP 快照日），原始差值，×10000 转 bp 在 Display 层 | delta_bp → `#,##0bp` |
| 6 | EOH Amt% vs LY | §18 附属 | 快照日 this − 快照日 LY（差值） | EOH Amt%（this 快照日）− EOH Amt%（LY 快照日），原始差值，×10000 转 bp 在 Display 层 | delta_bp → `#,##0bp` |

### 1.3 时间口径

| 口径 | 时间范围 | 适用指标 |
|---|---|---|
| This Period（区间类） | data_date ∈ [Slicer_Time_Frame_Min_This[TimeFrame_Min], Slicer_Time_Frame_Max_This[TimeFrame_Max]] | SLS Amt% 及 vs LP / vs LY 的 this 侧 |
| Last Period（vs LP 基线，区间类） | data_date ∈ [Slicer_Time_Frame_Min_Last[TimeFrame_Min], Slicer_Time_Frame_Max_Last[TimeFrame_Max]] | LP SLS Amt%（vs LP 的 last 侧） |
| Last Year（vs LY 基线，区间类） | data_date ∈ [Slicer_Time_Frame_Min_This[TimeFrame_Min_LY], Slicer_Time_Frame_Max_This[TimeFrame_Max_LY]] | LY SLS Amt%（vs LY 的 last year 侧） |
| End Period This（期末时点类） | end period 范围 [Slicer_Time_Frame_Max_This[TimeFrame_Min], Slicer_Time_Frame_Max_This[TimeFrame_Max]] 内**最后一个有数据的快照日** | EOH Amt% 及 vs LP / vs LY 的 this 侧 |
| End Period LP（期末时点类） | end period LP 范围 [Slicer_Time_Frame_Max_Last[TimeFrame_Min], Slicer_Time_Frame_Max_Last[TimeFrame_Max]] 内**最后一个有数据的快照日** | LP EOH Amt%（vs LP 的 last 侧） |
| End Period LY（期末时点类） | LY 区间范围 [Slicer_Time_Frame_Max_This[TimeFrame_Min_LY], Slicer_Time_Frame_Max_This[TimeFrame_Max_LY]] 内**最后一个有数据的快照日** | LY EOH Amt%（vs LY 的 last year 侧） |

说明：

- **vs LP 与 vs LY 为两套独立对比基线**：Last Period 取自 Last Period 日期切片器（Min_Last / Max_Last 表，用户可自由选择对比期）；Last Year 取自 This Period 所选时间行的财年同期映射字段（Min_This[TimeFrame_Min_LY] / Max_This[TimeFrame_Max_LY]，财年日历表内去年同字段对称生成），与 Last Period 切片器无关。二者时间范围可以不同（例如 This Period 为 FY27 年内区间时，Last Period 切片器可选任意历史区间，Last Year 固定为 FY26 同期）
- **期末时点实现为「范围内最后一个有数据的快照日」**：口径定义为区间最后一天，快照缺数时自动回退到范围内最近一天，避免整段空值；快照表按日存储，期末时点只取单日，对整段区间求和会把库存重复计数
- This Year 侧时间范围与 This Period 相同（同读 Min_This / Max_This 的 TimeFrame_Min / TimeFrame_Max）

### 1.4 币种口径

本方案全部指标为占比类与占比差值类（SLS Amt% / EOH Amt% 及 vs LP / vs LY），不涉及金额展示：占比分子分母为同表同币种金额字段（底表金额均存储 CNY），换算与否比值不变，不受币种切片器影响，无需汇率换算与币种符号拼接。

### 1.5 占比分母机制（组内分母）

口径「横坐标及表格行固定聚合在 Category 粒度」+ Division / Label 作为视觉对象筛选器固定单值的实现：

- 分母对行维度 Slicer_Category[category] 应用 `ALLSELECTED`：移除视觉对象内部的 Category 行筛选，恢复该分组筛选值下的全量 Category 合计；**Division / Label 视觉对象筛选器与全部外部切片器筛选均保留**
- 效果：每个分组表内各 Category 的 SLS Amt% / EOH Amt% 之和 = 100%（组内占比）
- 主指标与全部附属基线（LP / LY 占比）的分母同机制：各自时间范围内的组内全量合计
- 行字段从 Slicer_Category 维度表拉取，行筛选直接落在维度表字段上，ALLSELECTED(维度表字段) 正确移除后经一对多关系向双事实表正向传导，分母恢复组内全量

---

## 2. 现状分析

- 数据底表 `a02_e2e_product_performance_sales_summary_d`（日粒度汇总）：net_sales_amt（净销售金额，SLS Amt% 分子分母口径字段）；维度含 platform、shop_name、division、brand 及 category 等全部商品维度；日期字段为 data_date（date 类型）；platform 已在数据源层过滤 IN ('JD','TM','RLE','DY')
- 数据底表 `a02_e2e_product_performance_inv_summary_d`（日快照）：msrp_inv_amt（库存吊牌价金额，EOH Amt% 分子分母口径字段）；商品维度字段与 sales 表同名同构；**无 platform / shop_name 字段**（渠道筛选不影响库存侧指标）；日期字段为 data_date（date 类型）
- 模型关系：Slicer_Category / Slicer_Division / Slicer_Label 与两张事实表均一对多关联，筛选自动传递双表（Division / Label 视觉对象筛选器同机制传递）；Slicer_Platform_Selection、Slicer_Store_Name 与 sales 表一对多关联；日期筛选器（Min_This / Max_This / Min_Last / Max_Last）为断开维度，时间范围在 DAX 中显式筛选；Slicer_Time_Frame_Min_This / Max_This 表含 TimeFrame_Min_LY / TimeFrame_Max_LY 字段（财年日历去年同字段对称生成），vs LY 区间直接读取
- 字段名已逐一核对数据字典（net_sales_amt / msrp_inv_amt 等）

---

## 3. 方案设计

### 3.1 度量值分层

```
Value（口径计算，保留原始小数）
←  分子 / 分母时间范围显式筛选（This Period / Last Period / Last Year / 三个快照日）
←  占比分母：ALLSELECTED(Slicer_Category[category])——移除 Category 行筛选，
    保留 Division / Label 视觉对象筛选与外部切片器（组内分母，组内占比之和 = 100%）
←  LP / LY 中间度量值（LP SLS Amt% / LY SLS Amt% / LP EOH Amt% / LY EOH Amt%）
    供 vs LP / vs LY 派生引用，分母机制与 This 侧完全一致
←  期末快照日先经 REMOVEFILTERS(整表) 确定性取值（This / LP / LY 三个范围各自取值），
    不随行上下文 / 切片器漂移
↓
vs LP / vs LY Value（差值，原始小数）
←  This 期占比 − 基线占比；任一侧 BLANK 时返回 BLANK
↓
Display（格式化显示）
←  percent_0dp: FORMAT(#,##0%)；BLANK 显示 "-"
←  delta_bp: 值 ×10000 转 bp（FORMAT(#,##0) & "bp"，负数自带负号，零值 0bp）；BLANK 显示 "-"
```

### 3.2 占比分母机制（组内分母）

- 分母 `ALLSELECTED('Slicer_Category'[category])` 仅移除 Category 的视觉对象内部行筛选；Division / Label 视觉对象筛选器（固定单值）、Platform / Store / 商品维度切片器等全部外部筛选保留
- ALLSELECTED 与 REMOVEFILTERS 的语义差异是分母正确性的关键：REMOVEFILTERS 会移除该列全部筛选（含视觉对象筛选器），导致分母脱离分组条件退化为全局合计；ALLSELECTED 保留视觉对象筛选器与外部切片器，分母为该分组值下的全量合计
- Division 分组表与 Label 分组表共用同一套度量值：分组模式（Division 或 Label）对度量值不可见——两种模式的差异仅体现在视觉对象筛选器作用的维度表字段（Slicer_Division 或 Slicer_Label），分母逻辑统一为「保留该筛选 + 移除 Category 行筛选」

### 3.3 vs LP 与 vs LY 双基线

- **vs LP**：基线读 Last Period 日期切片器（Slicer_Time_Frame_Min_Last[TimeFrame_Min] / Slicer_Time_Frame_Max_Last[TimeFrame_Max]），对比期由切片器选择决定；EOH 基线快照日取 Max_Last 表范围最后快照日
- **vs LY**：基线读 This Period 所选时间行的财年同期映射字段（Slicer_Time_Frame_Min_This[TimeFrame_Min_LY] / Slicer_Time_Frame_Max_This[TimeFrame_Max_LY]），与 Last Period 切片器无关；EOH 基线快照日取 LY 区间范围（Max_This 表 _LY 字段）最后快照日
- LP / LY 占比作为独立中间度量值输出（分母机制、组内口径与 This 侧一致），vs LP / vs LY Value = This 期占比 − 基线占比（原始差值）；任一侧 BLANK 时返回 BLANK（避免单侧缺失产生失真差值）；×10000 转 bp 在 Display 层实现，保证 Value 层差值可复用

### 3.4 期末时点取值

- 三个快照日各自独立确定性取值：This（Max_This 表 TimeFrame_Min / TimeFrame_Max 范围）、LP（Max_Last 表 TimeFrame_Min / TimeFrame_Max 范围）、LY（Max_This 表 TimeFrame_Min_LY / TimeFrame_Max_LY 范围）内 `MAX(inv[data_date])`，均以 `REMOVEFILTERS(inv 表)` 计算，保证快照日不随行维度、分组筛选或切片器上下文漂移
- 快照日无数据时（该范围整段缺数）对应基线返回 BLANK，差值指标按空值规则显示 "-"

### 3.5 度量值命名与组织

- 命名规则：模块前缀 `Label & Division Table` + 指标名 + 层次后缀（Value / Display）；中间基线度量值在指标名前加 `LP` / `LY`
- Display Folder：`Label & Division Table\Base Metrics`（Value 层）、`Label & Division Table\Formatting`（Display 层）
- 度量值统一存放于 `_Measures` 隐藏表

---

## 4. 度量值实现

### 4.1 Label & Division Table SLS Amt% Value（当期销售金额占比）

```dax
Label & Division Table SLS Amt% Value =
// ========================================
// 度量值: Label & Division Table SLS Amt% Value
// 中文名: 当期销售金额占比
// Display Folder: Label & Division Table\Base Metrics
// 用途: 当前分组值（Division / Label 视觉对象筛选器固定单值）下，
//       各 Category 占该分组全量 Category 的销售金额比例（This Period 区间）
// 依赖: Slicer_Time_Frame_Min_This[TimeFrame_Min] / Slicer_Time_Frame_Max_This[TimeFrame_Max]
// 口径: 时间范围看 this period；
//       分子：该分组值 × Category 下 sum(net_sales_amt)；
//       分母：该分组值下全量 sum(net_sales_amt)（组内分母）
// 数据底表: a02_e2e_product_performance_sales_summary_d
// 分母机制: ALLSELECTED(Slicer_Category[category])——移除视觉对象内部的
//       Category 行筛选，保留 Division / Label 视觉对象筛选器（分组条件）
//       与全部外部切片器筛选；分母 = 该分组值下全量 Category 合计，
//       组内占比之和 = 100%；Division 分组表与 Label 分组表共用本度量值
//       （分组模式对度量值不可见，仅视觉对象筛选器作用的维度表不同）
// 币种: 分子分母为同表同币种金额（底表 CNY），占比不受币种选择影响
// ========================================

// ── This Period 时间区间 ──
VAR __PeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Min_This[TimeFrame_Min])
VAR __PeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

// ── 分子：当前 Category This Period 净销售金额（行筛选 + 分组筛选自动传导）──
VAR __Numerator =
    CALCULATE(
        SUM('a02_e2e_product_performance_sales_summary_d'[net_sales_amt]),
        'a02_e2e_product_performance_sales_summary_d'[data_date] >= __PeriodMin,
        'a02_e2e_product_performance_sales_summary_d'[data_date] <= __PeriodMax
    )

// ── 分母：该分组值下全量 Category 的 This Period 净销售金额 ──
// ALLSELECTED(Category)：移除 Category 行筛选，保留 Division / Label 分组筛选
// 与外部切片器（组内分母）
VAR __Denominator =
    CALCULATE(
        SUM('a02_e2e_product_performance_sales_summary_d'[net_sales_amt]),
        ALLSELECTED('Slicer_Category'[category]),
        'a02_e2e_product_performance_sales_summary_d'[data_date] >= __PeriodMin,
        'a02_e2e_product_performance_sales_summary_d'[data_date] <= __PeriodMax
    )

RETURN
    DIVIDE(__Numerator, __Denominator)
```

### 4.2 Label & Division Table SLS Amt% Display（当期销售金额占比显示）

```dax
Label & Division Table SLS Amt% Display =
// ========================================
// 度量值: Label & Division Table SLS Amt% Display
// 中文名: 当期销售金额占比显示
// Display Folder: Label & Division Table\Formatting
// 用途: percent_0dp 格式化（百分比整数，不含正号）；BLANK 显示 "-"
// 依赖: [Label & Division Table SLS Amt% Value]
// 数据格式: #,##0%（如 26%）
// ========================================
    VAR __Value = [Label & Division Table SLS Amt% Value]
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            FORMAT(__Value, "#,##0%")
        )
```

### 4.3 Label & Division Table LP SLS Amt% Value（LP 销售金额占比，中间度量值）

```dax
Label & Division Table LP SLS Amt% Value =
// ========================================
// 度量值: Label & Division Table LP SLS Amt% Value
// 中文名: LP 销售金额占比（vs LP 对比基线）
// Display Folder: Label & Division Table\Base Metrics
// 用途: Last Period 销售金额占比，供 SLS Amt% vs LP 派生引用，不直接进视觉对象
// 依赖: Slicer_Time_Frame_Min_Last[TimeFrame_Min] / Slicer_Time_Frame_Max_Last[TimeFrame_Max]
// 口径: 与 SLS Amt% 同构（组内分母 ALLSELECTED Category），仅时间范围替换为
//       Last Period 日期切片器（对比期由切片器选择决定）
// ========================================

// ── Last Period 时间区间（vs LP 基线）──
VAR __PeriodMin_LP = SELECTEDVALUE(Slicer_Time_Frame_Min_Last[TimeFrame_Min])
VAR __PeriodMax_LP = SELECTEDVALUE(Slicer_Time_Frame_Max_Last[TimeFrame_Max])

// ── 分子：当前 Category Last Period 净销售金额 ──
VAR __Numerator =
    CALCULATE(
        SUM('a02_e2e_product_performance_sales_summary_d'[net_sales_amt]),
        'a02_e2e_product_performance_sales_summary_d'[data_date] >= __PeriodMin_LP,
        'a02_e2e_product_performance_sales_summary_d'[data_date] <= __PeriodMax_LP
    )

// ── 分母：该分组值下全量 Category 的 Last Period 净销售金额（组内分母）──
VAR __Denominator =
    CALCULATE(
        SUM('a02_e2e_product_performance_sales_summary_d'[net_sales_amt]),
        ALLSELECTED('Slicer_Category'[category]),
        'a02_e2e_product_performance_sales_summary_d'[data_date] >= __PeriodMin_LP,
        'a02_e2e_product_performance_sales_summary_d'[data_date] <= __PeriodMax_LP
    )

RETURN
    DIVIDE(__Numerator, __Denominator)
```

### 4.4 Label & Division Table LY SLS Amt% Value（LY 销售金额占比，中间度量值）

```dax
Label & Division Table LY SLS Amt% Value =
// ========================================
// 度量值: Label & Division Table LY SLS Amt% Value
// 中文名: LY 销售金额占比（vs LY 对比基线）
// Display Folder: Label & Division Table\Base Metrics
// 用途: Last Year（财年同期）销售金额占比，供 SLS Amt% vs LY 派生引用，
//       不直接进视觉对象
// 依赖: Slicer_Time_Frame_Min_This[TimeFrame_Min_LY] / Slicer_Time_Frame_Max_This[TimeFrame_Max_LY]
// 口径: 与 SLS Amt% 同构（组内分母 ALLSELECTED Category），时间范围为 This Period
//       所选时间行的财年同期映射字段（_LY 字段，财年日历去年同字段对称生成），
//       与 Last Period 日期切片器无关——vs LP 与 vs LY 为两套独立对比基线
// ========================================

// ── Last Year 时间区间（vs LY 基线，_LY 字段财年同期映射）──
VAR __PeriodMin_LY = SELECTEDVALUE(Slicer_Time_Frame_Min_This[TimeFrame_Min_LY])
VAR __PeriodMax_LY = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max_LY])

// ── 分子：当前 Category Last Year 净销售金额 ──
VAR __Numerator =
    CALCULATE(
        SUM('a02_e2e_product_performance_sales_summary_d'[net_sales_amt]),
        'a02_e2e_product_performance_sales_summary_d'[data_date] >= __PeriodMin_LY,
        'a02_e2e_product_performance_sales_summary_d'[data_date] <= __PeriodMax_LY
    )

// ── 分母：该分组值下全量 Category 的 Last Year 净销售金额（组内分母）──
VAR __Denominator =
    CALCULATE(
        SUM('a02_e2e_product_performance_sales_summary_d'[net_sales_amt]),
        ALLSELECTED('Slicer_Category'[category]),
        'a02_e2e_product_performance_sales_summary_d'[data_date] >= __PeriodMin_LY,
        'a02_e2e_product_performance_sales_summary_d'[data_date] <= __PeriodMax_LY
    )

RETURN
    DIVIDE(__Numerator, __Denominator)
```

### 4.5 Label & Division Table SLS Amt% vs LP Value（销售金额占比 vs LP 差值）

```dax
Label & Division Table SLS Amt% vs LP Value =
// ========================================
// 度量值: Label & Division Table SLS Amt% vs LP Value
// 中文名: 销售金额占比 vs LP（差值）
// Display Folder: Label & Division Table\Base Metrics
// 用途: this period - last period 占比差值（原始小数，×10000 转 bp 在 Display 层实现）
// 依赖: [Label & Division Table SLS Amt% Value], [Label & Division Table LP SLS Amt% Value]
// 口径: this period - last period（差值，bp 指标）
// 边界: 任一期为 BLANK 时返回 BLANK，避免单侧缺失产生失真差值
// ========================================
    VAR __ThisPct = [Label & Division Table SLS Amt% Value]
    VAR __LastPct = [Label & Division Table LP SLS Amt% Value]

    RETURN
        IF(
            ISBLANK(__ThisPct) || ISBLANK(__LastPct),
            BLANK(),
            __ThisPct - __LastPct
        ) * 10000
```

### 4.6 Label & Division Table SLS Amt% vs LP Display（销售金额占比 vs LP 显示）

```dax
Label & Division Table SLS Amt% vs LP Display =
// ========================================
// 度量值: Label & Division Table SLS Amt% vs LP Display
// 中文名: 销售金额占比 vs LP 显示
// Display Folder: Label & Division Table\Formatting
// 用途: delta_bp 格式化：值 ×10000 转 bp，负数自带负号，零值 0bp；BLANK 显示 "-"
// 依赖: [Label & Division Table SLS Amt% vs LP Value]
// 数据格式: #,##0bp;-#,##0bp;0bp
// 说明: ×10000 转换在 Display 层实现，Value 层保留原始差值可复用
// ========================================
    VAR __Value = [Label & Division Table SLS Amt% vs LP Value]
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
        // IF(ROUND(__Value , 0) > 0, "+", "") & FORMAT(__Value , "#,##0bp;-#,##0bp;0bp"),       // +1200bp
            FORMAT(__Value, "#,##0") & "bp"   // 负数自带负号，零值 0bp
        )
```

### 4.7 Label & Division Table SLS Amt% vs LY Value（销售金额占比 vs LY 差值）

```dax
Label & Division Table SLS Amt% vs LY Value =
// ========================================
// 度量值: Label & Division Table SLS Amt% vs LY Value
// 中文名: 销售金额占比 vs LY（差值）
// Display Folder: Label & Division Table\Base Metrics
// 用途: this year - last year 占比差值（原始小数，×10000 转 bp 在 Display 层实现）
// 依赖: [Label & Division Table SLS Amt% Value], [Label & Division Table LY SLS Amt% Value]
// 口径: this year - last year（差值，bp 指标）；this year 时间范围同 This Period
//       （Min_This / Max_This 的 TimeFrame_Min / TimeFrame_Max），last year 为
//       _LY 字段财年同期映射，与 Last Period 切片器无关
// 边界: 任一侧为 BLANK 时返回 BLANK，避免单侧缺失产生失真差值
// ========================================
    VAR __ThisPct = [Label & Division Table SLS Amt% Value]
    VAR __LastYearPct = [Label & Division Table LY SLS Amt% Value]

    RETURN
        IF(
            ISBLANK(__ThisPct) || ISBLANK(__LastYearPct),
            BLANK(),
            __ThisPct - __LastYearPct
        ) * 10000
```

### 4.8 Label & Division Table SLS Amt% vs LY Display（销售金额占比 vs LY 显示）

```dax
Label & Division Table SLS Amt% vs LY Display =
// ========================================
// 度量值: Label & Division Table SLS Amt% vs LY Display
// 中文名: 销售金额占比 vs LY 显示
// Display Folder: Label & Division Table\Formatting
// 用途: delta_bp 格式化：值 ×10000 转 bp，负数自带负号，零值 0bp；BLANK 显示 "-"
// 依赖: [Label & Division Table SLS Amt% vs LY Value]
// 数据格式: #,##0bp;-#,##0bp;0bp
// ========================================
    VAR __Value = [Label & Division Table SLS Amt% vs LY Value]
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
        // IF(ROUND(__Value , 0) > 0, "+", "") & FORMAT(__Value , "#,##0bp;-#,##0bp;0bp"),       // +1200bp
            FORMAT(__Value , "#,##0") & "bp"   // 负数自带负号，零值 0bp
        )
```

### 4.9 Label & Division Table EOH Amt% Value（当期期末库存金额占比）

```dax
Label & Division Table EOH Amt% Value =
// ========================================
// 度量值: Label & Division Table EOH Amt% Value
// 中文名: 当期期末库存金额占比
// Display Folder: Label & Division Table\Base Metrics
// 用途: 当前分组值（Division / Label 视觉对象筛选器固定单值）下，
//       各 Category 占该分组全量 Category 的期末库存金额比例（快照日时点）
// 依赖: Slicer_Time_Frame_Max_This[TimeFrame_Min] / [TimeFrame_Max]
// 口径: 时间范围看 this period 最后一天（实现为 end period 范围内最后一个
//       有数据的快照日）；
//       分子：该分组值 × Category 下 sum(msrp_inv_amt)（快照日单日）；
//       分母：该分组值下全量 sum(msrp_inv_amt)（组内分母，快照日单日）
// 数据底表: a02_e2e_product_performance_inv_summary_d
// 分母机制: ALLSELECTED(Slicer_Category[category])（组内分母，同 SLS Amt%）；
//       行筛选与分组筛选经维度表关系自动传导 inv 表
// 说明: inv 表无 platform / shop_name 字段，本指标分子分母均不受渠道筛选影响；
//       期末时点只取快照日单日，对区间求和会重复计数库存
// ========================================

// ── End Period This 时间范围（期末时点类）──
VAR __EndPeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Min])
VAR __EndPeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

// ── 期末日期：end period 最后一天 = Max_This 表 TimeFrame_Max（直接单日过滤）──
VAR __EndPeriodDate = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

// ── 分子：当前 Category 期末库存金额（快照日单日值）──
VAR __Numerator =
    CALCULATE(
        SUM('a02_e2e_product_performance_inv_summary_d'[msrp_inv_amt]),
        'a02_e2e_product_performance_inv_summary_d'[data_date] = __EndPeriodDate
    )

// ── 分母：该分组值下全量 Category 的期末库存金额（组内分母，快照日单日）──
VAR __Denominator =
    CALCULATE(
        SUM('a02_e2e_product_performance_inv_summary_d'[msrp_inv_amt]),
        ALLSELECTED('Slicer_Category'[category]),
        'a02_e2e_product_performance_inv_summary_d'[data_date] = __EndPeriodDate
    )

RETURN
    DIVIDE(__Numerator, __Denominator)
```

### 4.10 Label & Division Table EOH Amt% Display（当期期末库存金额占比显示）

```dax
Label & Division Table EOH Amt% Display =
// ========================================
// 度量值: Label & Division Table EOH Amt% Display
// 中文名: 当期期末库存金额占比显示
// Display Folder: Label & Division Table\Formatting
// 用途: percent_0dp 格式化（百分比整数，不含正号）；BLANK 显示 "-"
// 依赖: [Label & Division Table EOH Amt% Value]
// 数据格式: #,##0%（如 18%）
// ========================================
    VAR __Value = [Label & Division Table EOH Amt% Value]
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            FORMAT(__Value, "#,##0%")
        )
```

### 4.11 Label & Division Table LP EOH Amt% Value（LP 期末库存金额占比，中间度量值）

```dax
Label & Division Table LP EOH Amt% Value =
// ========================================
// 度量值: Label & Division Table LP EOH Amt% Value
// 中文名: LP 期末库存金额占比（vs LP 对比基线）
// Display Folder: Label & Division Table\Base Metrics
// 用途: LP 期末库存金额占比，供 EOH Amt% vs LP 派生引用，不直接进视觉对象
// 依赖: Slicer_Time_Frame_Max_Last[TimeFrame_Min] / [TimeFrame_Max]
// 口径: 与 EOH Amt% 同构（组内分母 ALLSELECTED Category），期末时点替换为
//       end period LP 范围内最后一个有数据的快照日（对比期由 LP 切片器选择决定）
// ========================================

// ── End Period LP 时间范围（期末时点类，vs LP 基线）──
VAR __EndPeriodMin_LP = SELECTEDVALUE(Slicer_Time_Frame_Max_Last[TimeFrame_Min])
VAR __EndPeriodMax_LP = SELECTEDVALUE(Slicer_Time_Frame_Max_Last[TimeFrame_Max])

// ── 期末日期（LP）：end period LP 最后一天 = Max_Last 表 TimeFrame_Max（直接单日过滤）──
VAR __EndPeriodDate_LP = SELECTEDVALUE(Slicer_Time_Frame_Max_Last[TimeFrame_Max])

// ── 分子：当前 Category LP 期末库存金额（LP 快照日单日值）──
VAR __Numerator =
    CALCULATE(
        SUM('a02_e2e_product_performance_inv_summary_d'[msrp_inv_amt]),
        'a02_e2e_product_performance_inv_summary_d'[data_date] = __EndPeriodDate_LP
    )

// ── 分母：该分组值下全量 Category 的 LP 期末库存金额（组内分母）──
VAR __Denominator =
    CALCULATE(
        SUM('a02_e2e_product_performance_inv_summary_d'[msrp_inv_amt]),
        ALLSELECTED('Slicer_Category'[category]),
        'a02_e2e_product_performance_inv_summary_d'[data_date] = __EndPeriodDate_LP
    )

RETURN
    DIVIDE(__Numerator, __Denominator)
```

### 4.12 Label & Division Table LY EOH Amt% Value（LY 期末库存金额占比，中间度量值）

```dax
Label & Division Table LY EOH Amt% Value =
// ========================================
// 度量值: Label & Division Table LY EOH Amt% Value
// 中文名: LY 期末库存金额占比（vs LY 对比基线）
// Display Folder: Label & Division Table\Base Metrics
// 用途: LY（财年同期）期末库存金额占比，供 EOH Amt% vs LY 派生引用，
//       不直接进视觉对象
// 依赖: Slicer_Time_Frame_Max_This[TimeFrame_Min_LY] / [TimeFrame_Max_LY]
// 口径: 与 EOH Amt% 同构（组内分母 ALLSELECTED Category），期末时点替换为
//       LY 区间范围（_LY 字段财年同期映射）内最后一个有数据的快照日，
//       与 Last Period 切片器无关——vs LP 与 vs LY 为两套独立对比基线
// ========================================

// ── End Period LY 时间范围（期末时点类，vs LY 基线，_LY 字段映射）──
VAR __EndPeriodMin_LY = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Min_LY])
VAR __EndPeriodMax_LY = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max_LY])

// ── 期末日期（LY）：end period LY 最后一天 = Max_This 表 TimeFrame_Max_LY（直接单日过滤）──
VAR __EndPeriodDate_LY = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max_LY])

// ── 分子：当前 Category LY 期末库存金额（LY 快照日单日值）──
VAR __Numerator =
    CALCULATE(
        SUM('a02_e2e_product_performance_inv_summary_d'[msrp_inv_amt]),
        'a02_e2e_product_performance_inv_summary_d'[data_date] = __EndPeriodDate_LY
    )

// ── 分母：该分组值下全量 Category 的 LY 期末库存金额（组内分母）──
VAR __Denominator =
    CALCULATE(
        SUM('a02_e2e_product_performance_inv_summary_d'[msrp_inv_amt]),
        ALLSELECTED('Slicer_Category'[category]),
        'a02_e2e_product_performance_inv_summary_d'[data_date] = __EndPeriodDate_LY
    )

RETURN
    DIVIDE(__Numerator, __Denominator)
```

### 4.13 Label & Division Table EOH Amt% vs LP Value（期末库存金额占比 vs LP 差值）

```dax
Label & Division Table EOH Amt% vs LP Value =
// ========================================
// 度量值: Label & Division Table EOH Amt% vs LP Value
// 中文名: 期末库存金额占比 vs LP（差值）
// Display Folder: Label & Division Table\Base Metrics
// 用途: this period - last period 占比差值（原始小数，×10000 转 bp 在 Display 层实现）；
//       双期各自取 end period / end period LP 范围最后快照日的单日时点值
// 依赖: [Label & Division Table EOH Amt% Value], [Label & Division Table LP EOH Amt% Value]
// 口径: this period - last period（差值，bp 指标）
// 边界: 任一期为 BLANK 时返回 BLANK，避免单侧缺失产生失真差值
// ========================================
    VAR __ThisPct = [Label & Division Table EOH Amt% Value]
    VAR __LastPct = [Label & Division Table LP EOH Amt% Value]

    RETURN
        IF(
            ISBLANK(__ThisPct) || ISBLANK(__LastPct),
            BLANK(),
            __ThisPct - __LastPct
        ) * 10000
```

### 4.14 Label & Division Table EOH Amt% vs LP Display（期末库存金额占比 vs LP 显示）

```dax
Label & Division Table EOH Amt% vs LP Display =
// ========================================
// 度量值: Label & Division Table EOH Amt% vs LP Display
// 中文名: 期末库存金额占比 vs LP 显示
// Display Folder: Label & Division Table\Formatting
// 用途: delta_bp 格式化：值 ×10000 转 bp，负数自带负号，零值 0bp；BLANK 显示 "-"
// 依赖: [Label & Division Table EOH Amt% vs LP Value]
// 数据格式: #,##0bp;-#,##0bp;0bp
// ========================================
    VAR __Value = [Label & Division Table EOH Amt% vs LP Value]
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
        // IF(ROUND(__Value , 0) > 0, "+", "") & FORMAT(__Value , "#,##0bp;-#,##0bp;0bp"),       // +1200bp
            FORMAT(__Value , "#,##0") & "bp"   // 负数自带负号，零值 0bp
        )
```

### 4.15 Label & Division Table EOH Amt% vs LY Value（期末库存金额占比 vs LY 差值）

```dax
Label & Division Table EOH Amt% vs LY Value =
// ========================================
// 度量值: Label & Division Table EOH Amt% vs LY Value
// 中文名: 期末库存金额占比 vs LY（差值）
// Display Folder: Label & Division Table\Base Metrics
// 用途: this year - last year 占比差值（原始小数，×10000 转 bp 在 Display 层实现）；
//       双期各自取 end period / LY 区间范围最后快照日的单日时点值
// 依赖: [Label & Division Table EOH Amt% Value], [Label & Division Table LY EOH Amt% Value]
// 口径: this year - last year（差值，bp 指标）；LY 侧快照日为 _LY 字段财年同期
//       映射区间内最后一个有数据的快照日，与 Last Period 切片器无关
// 边界: 任一侧为 BLANK 时返回 BLANK，避免单侧缺失产生失真差值
// ========================================
    VAR __ThisPct = [Label & Division Table EOH Amt% Value]
    VAR __LastYearPct = [Label & Division Table LY EOH Amt% Value]

    RETURN
        IF(
            ISBLANK(__ThisPct) || ISBLANK(__LastYearPct),
            BLANK(),
            __ThisPct - __LastYearPct
        ) * 10000
```

### 4.16 Label & Division Table EOH Amt% vs LY Display（期末库存金额占比 vs LY 显示）

```dax
Label & Division Table EOH Amt% vs LY Display =
// ========================================
// 度量值: Label & Division Table EOH Amt% vs LY Display
// 中文名: 期末库存金额占比 vs LY 显示
// Display Folder: Label & Division Table\Formatting
// 用途: delta_bp 格式化：值 ×10000 转 bp，负数自带负号，零值 0bp；BLANK 显示 "-"
// 依赖: [Label & Division Table EOH Amt% vs LY Value]
// 数据格式: #,##0bp;-#,##0bp;0bp
// ========================================
    VAR __Value = [Label & Division Table EOH Amt% vs LY Value]
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
        // IF(ROUND(__Value , 0) > 0, "+", "") & FORMAT(__Value , "#,##0bp;-#,##0bp;0bp"),       // +1200bp
            FORMAT(__Value , "#,##0") & "bp"   // 负数自带负号，零值 0bp
        )
```

### 4.17 Label & Division Dimensions IsEmpty(可以共用同一个度量作用于视觉对象筛选器)
```dax
Label & Division Dimensions IsEmpty =
// ========================================
// 度量值: Label & Division Dimensions IsEmpty
// 中文名: 行非空判定
// Display Folder: Label & Division Dimensions IsEmpty\IsEmpty
// 用途: 行可见性判定——该行全部核心指标为空时返回 0，任一有值返回 1；
//       用于表格视觉级筛选器（IsEmpty = 1 仅显示有数据的行，
// ========================================
    IF(
        ISBLANK([Label & Division Table SLS Amt% Value]) &&
        ISBLANK([Label & Division Table SLS Amt% vs LP Value]) &&
        ISBLANK([Label & Division Table SLS Amt% vs LY Value]) &&
        ISBLANK([Label & Division Table EOH Amt% Value]) &&
        ISBLANK([Label & Division Table EOH Amt% vs LP Value]) &&
        ISBLANK([Label & Division Table EOH Amt% vs LY Value]),
        0,
        1
    )
```
---

## 5. 度量值清单

| # | 度量值 | 指标类型 | 用于视觉对象 |
|---|---|---|---|
| 1 | Label & Division Table SLS Amt% Value / Display | percent_0dp | Division / Label 分组表 |
| 2 | Label & Division Table LP SLS Amt% Value | percent_0dp（中间值） | 仅被 vs LP 引用 |
| 3 | Label & Division Table LY SLS Amt% Value | percent_0dp（中间值） | 仅被 vs LY 引用 |
| 4 | Label & Division Table SLS Amt% vs LP Value / Display | delta_bp | Division / Label 分组表 |
| 5 | Label & Division Table SLS Amt% vs LY Value / Display | delta_bp | Division / Label 分组表 |
| 6 | Label & Division Table EOH Amt% Value / Display | percent_0dp | Division / Label 分组表 |
| 7 | Label & Division Table LP EOH Amt% Value | percent_0dp（中间值） | 仅被 vs LP 引用 |
| 8 | Label & Division Table LY EOH Amt% Value | percent_0dp（中间值） | 仅被 vs LY 引用 |
| 9 | Label & Division Table EOH Amt% vs LP Value / Display | delta_bp | Division / Label 分组表 |
| 10 | Label & Division Table EOH Amt% vs LY Value / Display | delta_bp | Division / Label 分组表 |

- 全部度量值存放于 `_Measures` 隐藏表；Display Folder：`Label & Division Table\Base Metrics`（Value 层）与 `Label & Division Table\Formatting`（Display 层）
- LP / LY 中间度量值共 4 个（LP / LY × SLS / EOH），不直接进视觉对象

---

## 6. 视觉对象配置

### 6.1 Division 分组表（×4）

| 配置项 | 内容 |
|---|---|
| 视觉对象类型 | 表格 |
| 视觉对象筛选器 | Slicer_Division[division] = 单值（CW / HM / MN / WM 各一表，is required 筛选器） |
| 行 | Slicer_Category[category] |
| 值列（按口径顺序） | SLS Amt% Display → SLS Amt% vs LP Display → SLS Amt% vs LY Display → EOH Amt% Display → EOH Amt% vs LP Display → EOH Amt% vs LY Display |
| 列标题 | 按口径指标名（SLS Amt% / SLS Amt% vs LP / SLS Amt% vs LY / EOH Amt% / EOH Amt% vs LP / EOH Amt% vs LY） |
| 行可见性 | 六个指标全为 BLANK 的 Category 行由表格自动隐藏 |
| 总计 | 单级行无行小计需求；若开启总计行，占比类总计 = 100%（组内分母同范围） |

### 6.2 Label 分组表（×N）

| 配置项 | 内容 |
|---|---|
| 视觉对象类型 | 表格 |
| 视觉对象筛选器 | Slicer_Label[label] = 单值（每表固定一个 Label 值；Label 在事实表中对应 brand 字段） |
| 行 | Slicer_Category[category] |
| 值列 | 同 §6.1（与 Division 分组表共用全部度量值） |

### 6.3 切片器

| 切片器 | 类型 | 作用 |
|---|---|---|
| Slicer_Time_Frame | 主时间筛选器 | 驱动 Min_This / Max_This / Min_Last / Max_Last 断开维度表；vs LY 的去年区间取自 Min_This / Max_This 表的 TimeFrame_Min_LY / TimeFrame_Max_LY 字段 |
| Slicer_Platform_Selection / Slicer_Store_Name | 一对多关联（仅 sales 表） | 渠道筛选自动传递销售侧指标 |
| 商品维度切片器（Slicer_Division / Slicer_Label / Slicer_Category 等） | 一对多关联（双表） | 外部筛选自动传递；占比分母经 ALLSELECTED(Category) 保留该外部筛选 |
| Slicer_Currency_Selection | 断开维度 | 本板块无金额展示指标，不影响任何指标值 |

---

## 7. 验证方法

验证 SQL 为 MySQL 8.0+ 语法（CTE / 窗口函数），与配套测试文件 `test_Label_&_Division_table.sql` 两段对应：段 1 Division 分组、段 2 Label 分组；对数时按视觉对象筛选器固定值筛选分组列（division / label）后与对应 PBI 表逐行对比。

| 指标 | 测试 SQL 还原 |
|---|---|
| SLS Amt% | 分组键 + category 粒度聚合 net_sales_amt；分母 = SUM() OVER (PARTITION BY 分组键)（组内分母） |
| SLS Amt% vs LP / vs LY | 同上，时间条件分别替换为 Last Period / Last Year 区间，差值 = This 占比 − 基线占比 |
| EOH Amt% | inv 表三个快照日单日聚合；分母 = SUM() OVER (PARTITION BY 分组键) |
| EOH Amt% vs LP / vs LY | LP 快照日 / LY 快照日各取各自区间最后一天，差值同上 |

- NULL 语义对齐：分子 NULL → 占比 NULL（对应 DAX BLANK，显示 "-"）；差值任一侧 NULL → NULL
- 时间参数与替换方法见测试文件头部参数区

---

## 8. 注意事项

1. **组内分母**：分母 `ALLSELECTED(Slicer_Category[category])` 仅移除 Category 行筛选，保留 Division / Label 视觉对象筛选器与全部外部切片器筛选——分母 = 该分组值下全量 Category 合计，组内占比之和 = 100%。若误用 REMOVEFILTERS(Category)（移除该列全部筛选，含视觉对象筛选器），分母退化为跨分组全局合计，组内占比之和 ≠ 100%
2. **行字段必须从 Slicer_Category 维度表拉取**：行筛选直接落在维度表字段上，ALLSELECTED(维度表字段) 才能正确移除；若误用事实表字段作行字段，占比恒 100%
3. **vs LP 与 vs LY 双基线独立**：vs LP 读 Last Period 日期切片器（Min_Last / Max_Last 表，对比期自由选择）；vs LY 读 This Period 所选时间行的 _LY 字段（TimeFrame_Min_LY / TimeFrame_Max_LY，财年日历去年同字段对称映射），与 Last Period 切片器无关。二者时间范围可以不同，属预期行为
4. **EOH 三个快照日各自独立取值**：This（Max_This 表范围）、LP（Max_Last 表范围）、LY（Max_This 表 _LY 字段范围）内最后一个有数据的快照日；任一范围整段缺数时对应基线 BLANK，差值显示 "-"；期末时点只取单日，对整段区间求和会重复计数库存
5. **inv 表无渠道字段**：EOH Amt% 及其 vs LP / vs LY 的分子分母均不受渠道切片器影响；SLS Amt% 及其附属的分子分母受渠道筛选影响（sales 侧）——同一行两类指标的渠道口径不对称为模型物理限制，业务需知悉
6. **vs LP / vs LY 空值规则**：任一侧占比为 BLANK 时差值返回 BLANK（显示 "-"），避免单侧缺失产生失真差值；×10000 转 bp 在 Display 层实现，Value 层差值保持原始小数可复用
7. **币种**：本板块全部指标为占比与占比差值类，分子分母同表同币种（底表 CNY），不受币种切片器影响，无需汇率换算
8. **总计行为**：若表格开启总计行，占比类总计 = 100%（分子分母同范围），占比差值总计 = 0bp 附近的全量重算值（分子分母同步上卷后相减），均为汇总语义下的正确行为
9. **口径与语法**：口径文档中定义的所有指标必须遵守其数据类型与数据格式，与解决方案存在争议时一切以口径文档为准；DAX 文本常量使用双引号，单引号仅用于表名，列名使用方括号，例如：`[md_type] = "FP"`
