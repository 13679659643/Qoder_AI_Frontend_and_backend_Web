# Label & Division Table 表格解决方案

> **版本**: v1.2（vs LP / vs LY 改为金额同比口径：原「占比相减 ×10000 = bp」改为「本期金额 / 同期金额 − 1」，新增 6 个金额度量 SLS Amt / EOH Amt × TY / LP / LY（仅内部引用、不进视觉对象）；4 个 vs 度量名称不变（PBI 已绑定），Display 由 bp 改为百分比整数；原 SLS Amt% / EOH Amt% 及其 Display 不动，原 LP / LY 占比中间度量保留但自 v1.2 起不再被引用。详见 §1.2 / §3.1 / §3.3 / §4.5–§4.8 / §4.13–§4.16 / §4.18–§4.23 / 注意事项 6、10）。v1.1（商品维度 category → ax_class 字段替换（度量名称不变，仅改度量内字段引用与描述）；占比分母 ALLSELECTED 由列级改为维度表【整表】移除——按列排序 auto-existence 隐藏筛选传播，详见 §4.1 / §3.2）
> **模块**: RL E2E Merch Dashboard - Dimension Cross Analysis Tab - Product Type Sales & Inventory Structure【AX_Class × Division/Label】
> **关联口径**: 口径文档/口径Markdown格式/Dimension Cross Analysis.md - 子模块五（§17~§18）
> **数据底表（销售类）**: a02_e2e_product_performance_sales_summary_d
> **数据底表（库存类）**: a02_e2e_product_performance_inv_summary_d
> **关联维度**: Slicer_Time_Frame_Min_This / Max_This / Min_Last / Max_Last（时间，断开维度；vs LY 的去年区间取自 Min_This / Max_This 表的 _LY 字段）；Slicer_AX_Class（行字段来源）；Slicer_Division / Slicer_Label（视觉对象筛选器，一对多关联）；Slicer_Currency_Selection（币种，断开维度）
> **筛选影响范围**: date（断开维度，DAX 显式筛选）+ 渠道（Platform + Store Name，仅销售侧）+ Division / Label 视觉对象筛选器（双表自动传递）+ 商品维度切片器（外部筛选）

---

## 1. 需求理解

### 1.1 模块定位与视觉对象结构

本板块以 AX_Class 为固定粒度，Division / Label 作为视觉对象筛选器固定单值形成分组表，统计各 AX_Class 在所属分组内的销售金额占比与期末库存金额占比，以及两列金额（销售金额 / 期末库存金额）相对 LP / LY 的金额同比：

| 视觉对象 | 分组筛选器（视觉对象级，单值） | 行 | 值列（6 列） |
|---|---|---|---|
| Division 分组表 ×4 | Slicer_Division[division]，每表固定一个值（CW / HM / MN / WM） | Slicer_AX_Class[ax_class] | SLS Amt%、SLS Amt% vs LP、SLS Amt% vs LY、EOH Amt%、EOH Amt% vs LP、EOH Amt% vs LY |
| Label 分组表 ×N | Slicer_Label[label]，每表固定一个值（值域 = sales 表 brand distinct） | 同上 | 同上 |

- **行粒度固定 AX_Class**：行区域拉 Slicer_AX_Class[ax_class]，无层级、无行小计（单级行）
- **Division / Label 为视觉对象筛选器而非行维度**：页面通过多个表格视觉对象各固定一个 Division / Label 值形成分组展示；该筛选经 Slicer_Division / Slicer_Label 与双事实表的一对多关系自动传递，度量值内无需感知分组模式——**同一套度量值同时服务 Division 分组表与 Label 分组表**
- **行可见性**：AX_Class 值域来自 Slicer_AX_Class（sales 表 distinct）；当前分组筛选值下六个指标全为 BLANK 的 AX_Class 行由表格自动隐藏（含该分组下无任何销售与库存记录的 AX_Class）

### 1.2 指标清单

| 序号 | 指标 | 口径章节 | 时间口径 | 计算公式 | 数据类型 / 格式 |
|---|---|---|---|---|---|
| 1 | SLS Amt% | §17 | This Period（区间） | 分子：该分组值 × AX_Class 下 sum(net_sales_amt)；分母：该分组值下全量 sum(net_sales_amt)（ALLSELECTED AX_Class，组内分母） | percent_0dp → `#,##0%` |
| 2 | SLS Amt% vs LP | §17 附属 | This vs Last Period（金额同比） | SLS Amt(TY) / SLS Amt(LP) − 1；同期为 0 或空 → BLANK，本期为 0 或空（同期有值）→ −1 | percent_0dp → `#,##0%` |
| 3 | SLS Amt% vs LY | §17 附属 | This vs Last Year（金额同比） | SLS Amt(TY) / SLS Amt(LY) − 1；边界同 vs LP | percent_0dp → `#,##0%` |
| 4 | EOH Amt% | §18 | End Period（期末时点） | 分子：该分组值 × AX_Class 下 sum(msrp_inv_amt)（快照日单日）；分母：该分组值下全量 sum(msrp_inv_amt)（ALLSELECTED AX_Class，组内分母） | percent_0dp → `#,##0%` |
| 5 | EOH Amt% vs LP | §18 附属 | 快照日 this vs 快照日 LP（金额同比） | EOH Amt(TY) / EOH Amt(LP) − 1；边界同 vs LP | percent_0dp → `#,##0%` |
| 6 | EOH Amt% vs LY | §18 附属 | 快照日 this vs 快照日 LY（金额同比） | EOH Amt(TY) / EOH Amt(LY) − 1；边界同 vs LP | percent_0dp → `#,##0%` |

说明（v1.2）：

- 指标名与列标题**沿用旧名**（SLS Amt% vs LP 等），PBI 视觉对象绑定关系不变，仅度量内部逻辑替换；实际口径已经是**金额同比**（两期金额之比减 1），不再是占比差值
- 第 2/3/5/6 项依赖 §4.18–§4.23 新增的 6 个金额度量（内部引用，不出现在视觉对象）；第 1/4 项与原有 SLS Amt%（§4.1）/ EOH Amt%（§4.9）逻辑完全一致，未改动

### 1.3 时间口径

| 口径 | 时间范围 | 适用指标 |
|---|---|---|
| This Period（区间类） | data_date ∈ [Slicer_Time_Frame_Min_This[TimeFrame_Min], Slicer_Time_Frame_Max_This[TimeFrame_Max]] | SLS Amt%（§4.1）；SLS Amt TY（vs LP / vs LY 的 this 侧，§4.18） |
| Last Period（vs LP 基线，区间类） | data_date ∈ [Slicer_Time_Frame_Min_Last[TimeFrame_Min], Slicer_Time_Frame_Max_Last[TimeFrame_Max]] | SLS Amt LP（vs LP 基线金额，§4.19）；旧 LP SLS Amt% 中间度量保留但不再被引用 |
| Last Year（vs LY 基线，区间类） | data_date ∈ [Slicer_Time_Frame_Min_This[TimeFrame_Min_LY], Slicer_Time_Frame_Max_This[TimeFrame_Max_LY]] | SLS Amt LY（vs LY 基线金额，§4.20）；旧 LY SLS Amt% 中间度量保留但不再被引用 |
| End Period This（期末时点类） | end period 范围 [Slicer_Time_Frame_Max_This[TimeFrame_Min], Slicer_Time_Frame_Max_This[TimeFrame_Max]] 内**最后一个有数据的快照日** | EOH Amt%（§4.9）；EOH Amt TY（vs 的 this 侧，§4.21） |
| End Period LP（期末时点类） | end period LP 范围 [Slicer_Time_Frame_Max_Last[TimeFrame_Min], Slicer_Time_Frame_Max_Last[TimeFrame_Max]] 内**最后一个有数据的快照日** | EOH Amt LP（vs LP 基线金额，§4.22）；旧 LP EOH Amt% 中间度量保留但不再被引用 |
| End Period LY（期末时点类） | LY 区间范围 [Slicer_Time_Frame_Max_This[TimeFrame_Min_LY], Slicer_Time_Frame_Max_This[TimeFrame_Max_LY]] 内**最后一个有数据的快照日** | EOH Amt LY（vs LY 基线金额，§4.23）；旧 LY EOH Amt% 中间度量保留但不再被引用 |

说明：

- **vs LP 与 vs LY 为两套独立对比基线**：Last Period 取自 Last Period 日期切片器（Min_Last / Max_Last 表，用户可自由选择对比期）；Last Year 取自 This Period 所选时间行的财年同期映射字段（Min_This[TimeFrame_Min_LY] / Max_This[TimeFrame_Max_LY]，财年日历表内去年同字段对称生成），与 Last Period 切片器无关。二者时间范围可以不同（例如 This Period 为 FY27 年内区间时，Last Period 切片器可选任意历史区间，Last Year 固定为 FY26 同期）
- **期末时点实现为「范围内最后一个有数据的快照日」**：口径定义为区间最后一天，快照缺数时自动回退到范围内最近一天，避免整段空值；快照表按日存储，期末时点只取单日，对整段区间求和会把库存重复计数
- This Year 侧时间范围与 This Period 相同（同读 Min_This / Max_This 的 TimeFrame_Min / TimeFrame_Max）

### 1.4 币种口径

本方案指标为占比类（SLS Amt% / EOH Amt%）与金额同比类（vs LP / vs LY，v1.2 起为两期金额之比减 1），均不涉及金额绝对值展示：占比与同比的分子分母均为同表同币种的金额字段（底表金额均存储 CNY），换算与否比值不变，不受币种切片器影响，无需汇率换算与币种符号拼接。新增的 6 个金额度量（§4.18–§4.23）只用于内部相除、不直接展示数值，同样无需汇率换算。

### 1.5 占比分母机制（组内分母）

口径「横坐标及表格行固定聚合在 AX_Class 粒度」+ Division / Label 作为视觉对象筛选器固定单值的实现：

- 分母对行维度 Slicer_AX_Class 整表应用 `ALLSELECTED`：移除视觉对象内部的 AX_Class 行筛选（含按列排序隐式带入的排序列筛选），恢复该分组筛选值下的全量 AX_Class 合计；**Division / Label 视觉对象筛选器与全部外部切片器筛选均保留**
- 效果：每个‍分组表内各 AX_Class 的 SLS Amt% / EOH Amt% 之和 = 100%（组内占比）
-  主指标与全部附属基线（LP / LY 占比）的分母同机制：各自时间范围内的组内全量合计
- 行字段从 Slicer_AX_Class 维度表拉取，行筛选直接落在维度表上，ALLSELECTED(维度表整表) 正确移除后经一对多关系向双事实表正向传导，分母恢复组内全量
- **必须整表移除而不能只移除值列**：值列配置「按列排序」后，视觉对象查询经 auto-existence（同表共存）把排序列隐式并入 GroupBy 并合并为表粒度组合筛选；只移除值列时排序列筛选独自存活——排序键与业务值 1:1（Sort 表内唯一），1:1 反推等价于原值筛选，维度表仍被钉在当前行，分母与分子聚合范围重合，占比恒 100%
- **vs LP / vs LY 不使用组内分母（v1.2）**：金额同比只比较行级金额（本期 / 同期），分子分母同为该 AX_Class 行在该期的金额，与占比分母机制无关；组内分母只服务 SLS Amt% / EOH Amt% 两列

---

## 2. 现状分析

- 数据底表 `a02_e2e_product_performance_sales_summary_d`（日粒度汇总）：net_sales_amt（净销售金额，SLS Amt% 分子分母口径字段）；维度含 platform、shop_name、division、brand 及 ax_class 等全部商品维度；日期字段为 data_date（date 类型）；platform 已在数据源层过滤 IN ('JD','TM','RLE','DY')
- 数据底表 `a02_e2e_product_performance_inv_summary_d`（日快照）：msrp_inv_amt（库存吊牌价金额，EOH Amt% 分子分母口径字段）；商品维度字段与 sales 表同名同构；**无 platform / shop_name 字段**（渠道筛选不影响库存侧指标）；日期字段为 data_date（date 类型）
- 模型关系：Slicer_AX_Class / Slicer_Division / Slicer_Label 与两张事实表均一对多关联，筛选自动传递双表（Division / Label 视觉对象筛选器同机制传递）；Slicer_Platform_Selection、Slicer_Store_Name 与 sales 表一对多关联；日期筛选器（Min_This / Max_This / Min_Last / Max_Last）为断开维度，时间范围在 DAX 中显式筛选；Slicer_Time_Frame_Min_This / Max_This 表含 TimeFrame_Min_LY / TimeFrame_Max_LY 字段（财年日历去年同字段对称生成），vs LY 区间直接读取
- 字段名已逐一核对数据字典（net_sales_amt / msrp_inv_amt 等）

---

## 3. 方案设计

### 3.1 度量值分层

```
Value（口径计算，保留原始小数）
←  占比类（SLS Amt% / EOH Amt%，逻辑不变）：分子 / 分母按各自时间范围显式筛选
←  占比分母：ALLSELECTED('Slicer_AX_Class')——移除 AX_Class 行筛选（整表移除，含按列排序隐式带入的排序列筛选），
    保留 Division / Label 视觉对象筛选与外部切片器（组内分母，组内占比之和 = 100%）
←  金额类（v1.2 新增，仅内部引用）：SLS Amt TY / LP / LY、EOH Amt TY / LP / LY
    行级聚合（行筛选 + 分组筛选自动传导），无组内分母；期末类取各自快照日单日
←  期末快照日先经 REMOVEFILTERS(整表) 确定性取值（This / LP / LY 三个范围各自取值），
    不随行上下文 / 切片器漂移
←  LP / LY 占比中间度量值（LP SLS Amt% / LY SLS Amt% / LP EOH Amt% / LY EOH Amt%）
    v1.2 起保留但不再被 vs 引用（vs 改用金额类）
↓
vs LP / vs LY Value（比率，原始小数）
←  本期金额 / 同期金额 − 1
←  同期为 0 或空 → BLANK()；本期为 0 或空（同期有值）→ −1
↓
Display（格式化显示）
←  percent_0dp: FORMAT(#,##0%)；BLANK 显示 "-"
```

### 3.2 占比分母机制（组内分母）

- 分母 `ALLSELECTED('Slicer_AX_Class')` 整表移除 AX_Class 的视觉对象内部行筛选（含按列排序隐式带入的排序列筛选）；Division / Label 视觉对象筛选器（固定单值）、Platform / Store / 商品维度切片器等全部外部筛选保留
- ALLSELECTED 与 REMOVEFILTERS 的语义差异是分母正确性的关键：REMOVEFILTERS 会移除该列全部筛选（含视觉对象筛选器），导致分母脱离分组条件退化为全局合计；ALLSELECTED 保留视觉对象筛选器与外部切片器，分母为该分组值下的全量合计
- **必须整表移除而不能只移除值列**：值列配置「按列排序」后，视觉对象查询经 auto-existence（同表共存）把排序列隐式并入 GroupBy；只移除值列时排序列筛选独自存活，排序键与业务值 1:1 反推等价于原值筛选，维度表仍被钉在当前行，占比恒 100%
- Division 分组表与 Label 分组表共用同一套度量值：分组模式（Division 或 Label）对度量值不可见——两种模式的差异仅体现在视觉对象筛选器作用的维度表字段（Slicer_Division 或 Slicer_Label），分母逻辑统一为「保留该筛选 + 移除 AX_Class 行筛选」

### 3.3 vs LP 与 vs LY 双基线

- **vs LP**：基线读 Last Period 日期切片器（Slicer_Time_Frame_Min_Last[TimeFrame_Min] / Slicer_Time_Frame_Max_Last[TimeFrame_Max]），对比期由切片器选择决定；EOH 基线快照日取 Max_Last 表范围最后快照日
- **vs LY**：基线读 This Period 所选时间行的财年同期映射字段（Slicer_Time_Frame_Min_This[TimeFrame_Min_LY] / Slicer_Time_Frame_Max_This[TimeFrame_Max_LY]），与 Last Period 切片器无关；EOH 基线快照日取 LY 区间范围（Max_This 表 _LY 字段）最后快照日
- **vs 改为金额同比（v1.2）**：新增 SLS Amt / EOH Amt × TY / LP / LY 六个金额度量（行级聚合，LP / LY 读各自基线时间范围 / 快照日，见 §4.18–§4.23），vs LP / vs LY Value = 本期金额 / 同期金额 − 1（原始比率，Display 用 percent_0dp 输出整数百分比）；边界：同期为 0 或空 → BLANK()（含双零 / 双空），本期为 0 或空且同期有值 → −1（−100%）。4 个 vs 度量名称沿用旧名，PBI 视觉对象绑定不变，只需整段替换度量逻辑
- LP / LY 占比中间度量值（LP / LY × SLS / EOH 共 4 个）保留不删（防止其它潜在引用报错），但自 v1.2 起不再被任何度量引用

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
//       各 AX_Class 占该分组全量 AX_Class 的销售金额比例（This Period 区间）
// 依赖: Slicer_Time_Frame_Min_This[TimeFrame_Min] / Slicer_Time_Frame_Max_This[TimeFrame_Max]
// 口径: 时间范围看 this period；
//       分子：该分组值 × AX_Class 下 sum(net_sales_amt)；
//       分母：该分组值下全量 sum(net_sales_amt)（组内分母）
// 数据底表: a02_e2e_product_performance_sales_summary_d
// 分母机制: ALLSELECTED(Slicer_AX_Class)——整表移除视觉对象内部的
//       AX_Class 行筛选（含按列排序隐式带入的排序列筛选；auto-existence：
//       同表共存时值列筛选会合并排序列为表粒度组合筛选，只移除值列则排序列
//       筛选存活，排序键与业务值 1:1 → 占比恒 100%，必须整表移除），
//       保留 Division / Label 视觉对象筛选器（分组条件）与全部外部切片器筛选；
//       分母 = 该分组值下全量 AX_Class 合计，组内占比之和 = 100%；
//       Division 分组表与 Label 分组表共用本度量值
//       （分组模式对度量值不可见，仅视觉对象筛选器作用的维度表不同）
// 币种: 分子分母为同表同币种金额（底表 CNY），占比不受币种选择影响
// ========================================

// ── This Period 时间区间 ──
VAR __PeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Min_This[TimeFrame_Min])
VAR __PeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

// ── 分子：当前 AX_Class This Period 净销售金额（行筛选 + 分组筛选自动传导）──
VAR __Numerator =
    CALCULATE(
        SUM('a02_e2e_product_performance_sales_summary_d'[net_sales_amt]),
        'a02_e2e_product_performance_sales_summary_d'[data_date] >= __PeriodMin,
        'a02_e2e_product_performance_sales_summary_d'[data_date] <= __PeriodMax
    )

// ── 分母：该分组值下全量 AX_Class 的 This Period 净销售金额 ──
// ALLSELECTED(Slicer_AX_Class)：整表移除 AX_Class 行筛选（含按列排序隐式带入的排序列筛选），
// 保留 Division / Label 分组筛选与外部切片器（组内分母）
VAR __Denominator =
    CALCULATE(
        SUM('a02_e2e_product_performance_sales_summary_d'[net_sales_amt]),
        ALLSELECTED('Slicer_AX_Class'),
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
// 口径: 与 SLS Amt% 同构（组内分母 ALLSELECTED AX_Class 整表移除），仅时间范围替换为
//       Last Period 日期切片器（对比期由切片器选择决定）
// ========================================

// ── Last Period 时间区间（vs LP 基线）──
VAR __PeriodMin_LP = SELECTEDVALUE(Slicer_Time_Frame_Min_Last[TimeFrame_Min])
VAR __PeriodMax_LP = SELECTEDVALUE(Slicer_Time_Frame_Max_Last[TimeFrame_Max])

// ── 分子：当前 AX_Class Last Period 净销售金额 ──
VAR __Numerator =
    CALCULATE(
        SUM('a02_e2e_product_performance_sales_summary_d'[net_sales_amt]),
        'a02_e2e_product_performance_sales_summary_d'[data_date] >= __PeriodMin_LP,
        'a02_e2e_product_performance_sales_summary_d'[data_date] <= __PeriodMax_LP
    )

// ── 分母：该分组值下全量 AX_Class 的 Last Period 净销售金额（组内分母）──
// ALLSELECTED(Slicer_AX_Class)：整表移除 AX_Class 行筛选（含按列排序隐式带入的排序列筛选），
// 保留 Division / Label 分组筛选与外部切片器（组内分母）
VAR __Denominator =
    CALCULATE(
        SUM('a02_e2e_product_performance_sales_summary_d'[net_sales_amt]),
        ALLSELECTED('Slicer_AX_Class'),
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
// 口径: 与 SLS Amt% 同构（组内分母 ALLSELECTED AX_Class 整表移除），时间范围为 This Period
//       所选时间行的财年同期映射字段（_LY 字段，财年日历去年同字段对称生成），
//       与 Last Period 日期切片器无关——vs LP 与 vs LY 为两套独立对比基线
// ========================================

// ── Last Year 时间区间（vs LY 基线，_LY 字段财年同期映射）──
VAR __PeriodMin_LY = SELECTEDVALUE(Slicer_Time_Frame_Min_This[TimeFrame_Min_LY])
VAR __PeriodMax_LY = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max_LY])

// ── 分子：当前 AX_Class Last Year 净销售金额 ──
VAR __Numerator =
    CALCULATE(
        SUM('a02_e2e_product_performance_sales_summary_d'[net_sales_amt]),
        'a02_e2e_product_performance_sales_summary_d'[data_date] >= __PeriodMin_LY,
        'a02_e2e_product_performance_sales_summary_d'[data_date] <= __PeriodMax_LY
    )

// ── 分母：该分组值下全量 AX_Class 的 Last Year 净销售金额（组内分母）──
// ALLSELECTED(Slicer_AX_Class)：整表移除 AX_Class 行筛选（含按列排序隐式带入的排序列筛选），
// 保留 Division / Label 分组筛选与外部切片器（组内分母）
VAR __Denominator =
    CALCULATE(
        SUM('a02_e2e_product_performance_sales_summary_d'[net_sales_amt]),
        ALLSELECTED('Slicer_AX_Class'),
        'a02_e2e_product_performance_sales_summary_d'[data_date] >= __PeriodMin_LY,
        'a02_e2e_product_performance_sales_summary_d'[data_date] <= __PeriodMax_LY
    )

RETURN
    DIVIDE(__Numerator, __Denominator)
```

### 4.5 Label & Division Table SLS Amt% vs LP Value（销售金额 vs LP 金额同比）

```dax
Label & Division Table SLS Amt% vs LP Value =
// ========================================
// 度量值: Label & Division Table SLS Amt% vs LP Value
// 中文名: 销售金额 vs LP（金额同比）
// Display Folder: Label & Division Table\Base Metrics
// 用途: 本期销售金额 / 同期（LP）销售金额 − 1（原始比率，Display 层格式化为整数百分比）；
//       指标名沿用旧名「SLS Amt% vs LP」，PBI 视觉对象绑定不变
// 依赖: [Label & Division Table SLS Amt TY Value]（§4.18）、
//       [Label & Division Table SLS Amt LP Value]（§4.19）
// 口径: 金额同比（v1.2 起；原「占比相减 ×10000 转 bp」已废止）
// 边界: 同期为 0 或空 → BLANK()（含双零 / 双空，显示 "-"）；
//       本期为 0 或空且同期有值 → -1（显示 -100%）
// ========================================
    VAR __ThisAmt = [Label & Division Table SLS Amt TY Value]
    VAR __BaseAmt = [Label & Division Table SLS Amt LP Value]

    RETURN
        IF(
            ISBLANK(__BaseAmt) || __BaseAmt = 0,
            BLANK(),
            IF(
                ISBLANK(__ThisAmt) || __ThisAmt = 0,
                -1,
                DIVIDE(__ThisAmt, __BaseAmt) - 1
            )
        )
```

### 4.6 Label & Division Table SLS Amt% vs LP Display（销售金额 vs LP 显示）

```dax
Label & Division Table SLS Amt% vs LP Display =
// ========================================
// 度量值: Label & Division Table SLS Amt% vs LP Display
// 中文名: 销售金额 vs LP 显示
// Display Folder: Label & Division Table\Formatting
// 用途: percent_0dp 格式化（百分比整数，负数自带负号）；BLANK 显示 "-"
// 依赖: [Label & Division Table SLS Amt% vs LP Value]
// 数据格式: #,##0%（如 12%、-8%）
// 说明: v1.2 起 vs 为金额同比比率，不再 ×10000 转 bp
// ========================================
    VAR __Value = [Label & Division Table SLS Amt% vs LP Value]
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            FORMAT(__Value, "#,##0%")
        )
```

### 4.7 Label & Division Table SLS Amt% vs LY Value（销售金额 vs LY 金额同比）

```dax
Label & Division Table SLS Amt% vs LY Value =
// ========================================
// 度量值: Label & Division Table SLS Amt% vs LY Value
// 中文名: 销售金额 vs LY（金额同比）
// Display Folder: Label & Division Table\Base Metrics
// 用途: 本期销售金额 / 去年同期销售金额 − 1（原始比率，Display 层格式化为整数百分比）；
//       指标名沿用旧名「SLS Amt% vs LY」，PBI 视觉对象绑定不变
// 依赖: [Label & Division Table SLS Amt TY Value]（§4.18）、
//       [Label & Division Table SLS Amt LY Value]（§4.20）
// 口径: 金额同比（v1.2 起；原「占比相减 ×10000 转 bp」已废止）；
//       TY 与 This Period 同区间，LY 为 _LY 字段财年同期映射，与 Last Period 切片器无关
// 边界: 同期为 0 或空 → BLANK()（含双零 / 双空，显示 "-"）；
//       本期为 0 或空且同期有值 → -1（显示 -100%）
// ========================================
    VAR __ThisAmt = [Label & Division Table SLS Amt TY Value]
    VAR __LastYearAmt = [Label & Division Table SLS Amt LY Value]

    RETURN
        IF(
            ISBLANK(__LastYearAmt) || __LastYearAmt = 0,
            BLANK(),
            IF(
                ISBLANK(__ThisAmt) || __ThisAmt = 0,
                -1,
                DIVIDE(__ThisAmt, __LastYearAmt) - 1
            )
        )
```

### 4.8 Label & Division Table SLS Amt% vs LY Display（销售金额 vs LY 显示）

```dax
Label & Division Table SLS Amt% vs LY Display =
// ========================================
// 度量值: Label & Division Table SLS Amt% vs LY Display
// 中文名: 销售金额 vs LY 显示
// Display Folder: Label & Division Table\Formatting
// 用途: percent_0dp 格式化（百分比整数，负数自带负号）；BLANK 显示 "-"
// 依赖: [Label & Division Table SLS Amt% vs LY Value]
// 数据格式: #,##0%（如 12%、-8%）
// ========================================
    VAR __Value = [Label & Division Table SLS Amt% vs LY Value]
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            FORMAT(__Value, "#,##0%")
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
//       各 AX_Class 占该分组全量 AX_Class 的期末库存金额比例（快照日时点）
// 依赖: Slicer_Time_Frame_Max_This[TimeFrame_Min] / [TimeFrame_Max]
// 口径: 时间范围看 this period 最后一天（实现为 end period 范围内最后一个
//       有数据的快照日）；
//       分子：该分组值 × AX_Class 下 sum(msrp_inv_amt)（快照日单日）；
//       分母：该分组值下全量 sum(msrp_inv_amt)（组内分母，快照日单日）
// 数据底表: a02_e2e_product_performance_inv_summary_d
// 分母机制: ALLSELECTED(Slicer_AX_Class)——整表移除 AX_Class 行筛选（含按列排序
//       隐式带入的排序列筛选；auto-existence：同表共存时值列筛选会合并排序列为
//       表粒度组合筛选，只移除值列则排序列筛选存活，排序键与业务值 1:1 →
//       占比恒 100%，必须整表移除），保留 Division / Label 视觉对象筛选器与
//       全部外部切片器筛选（组内分母，同 SLS Amt%）；
//       行筛选与分组筛选经维度表关系自动传导 inv 表
// 说明: inv 表无 platform / shop_name 字段，本指标分子分母均不受渠道筛选影响；
//       期末时点只取快照日单日，对区间求和会重复计数库存
// ========================================

// ── End Period This 时间范围（期末时点类）──
VAR __EndPeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Min])
VAR __EndPeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

// ── 期末日期：end period 最后一天 = Max_This 表 TimeFrame_Max（直接单日过滤）──
VAR __EndPeriodDate = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

// ── 分子：当前 AX_Class 期末库存金额（快照日单日值）──
VAR __Numerator =
    CALCULATE(
        SUM('a02_e2e_product_performance_inv_summary_d'[msrp_inv_amt]),
        'a02_e2e_product_performance_inv_summary_d'[data_date] = __EndPeriodDate
    )

// ── 分母：该分组值下全量 AX_Class 的期末库存金额（组内分母，快照日单日）──
// ALLSELECTED(Slicer_AX_Class)：整表移除 AX_Class 行筛选（含按列排序隐式带入的排序列筛选），
// 保留 Division / Label 分组筛选与外部切片器（组内分母）
VAR __Denominator =
    CALCULATE(
        SUM('a02_e2e_product_performance_inv_summary_d'[msrp_inv_amt]),
        ALLSELECTED('Slicer_AX_Class'),
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
// 口径: 与 EOH Amt% 同构（组内分母 ALLSELECTED AX_Class 整表移除），期末时点替换为
//       end period LP 范围内最后一个有数据的快照日（对比期由 LP 切片器选择决定）
// ========================================

// ── End Period LP 时间范围（期末时点类，vs LP 基线）──
VAR __EndPeriodMin_LP = SELECTEDVALUE(Slicer_Time_Frame_Max_Last[TimeFrame_Min])
VAR __EndPeriodMax_LP = SELECTEDVALUE(Slicer_Time_Frame_Max_Last[TimeFrame_Max])

// ── 期末日期（LP）：end period LP 最后一天 = Max_Last 表 TimeFrame_Max（直接单日过滤）──
VAR __EndPeriodDate_LP = SELECTEDVALUE(Slicer_Time_Frame_Max_Last[TimeFrame_Max])

// ── 分子：当前 AX_Class LP 期末库存金额（LP 快照日单日值）──
VAR __Numerator =
    CALCULATE(
        SUM('a02_e2e_product_performance_inv_summary_d'[msrp_inv_amt]),
        'a02_e2e_product_performance_inv_summary_d'[data_date] = __EndPeriodDate_LP
    )

// ── 分母：该分组值下全量 AX_Class 的 LP 期末库存金额（组内分母）──
// ALLSELECTED(Slicer_AX_Class)：整表移除 AX_Class 行筛选（含按列排序隐式带入的排序列筛选），
// 保留 Division / Label 分组筛选与外部切片器（组内分母）
VAR __Denominator =
    CALCULATE(
        SUM('a02_e2e_product_performance_inv_summary_d'[msrp_inv_amt]),
        ALLSELECTED('Slicer_AX_Class'),
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
// 口径: 与 EOH Amt% 同构（组内分母 ALLSELECTED AX_Class 整表移除），期末时点替换为
//       LY 区间范围（_LY 字段财年同期映射）内最后一个有数据的快照日，
//       与 Last Period 切片器无关——vs LP 与 vs LY 为两套独立对比基线
// ========================================

// ── End Period LY 时间范围（期末时点类，vs LY 基线，_LY 字段映射）──
VAR __EndPeriodMin_LY = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Min_LY])
VAR __EndPeriodMax_LY = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max_LY])

// ── 期末日期（LY）：end period LY 最后一天 = Max_This 表 TimeFrame_Max_LY（直接单日过滤）──
VAR __EndPeriodDate_LY = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max_LY])

// ── 分子：当前 AX_Class LY 期末库存金额（LY 快照日单日值）──
VAR __Numerator =
    CALCULATE(
        SUM('a02_e2e_product_performance_inv_summary_d'[msrp_inv_amt]),
        'a02_e2e_product_performance_inv_summary_d'[data_date] = __EndPeriodDate_LY
    )

// ── 分母：该分组值下全量 AX_Class 的 LY 期末库存金额（组内分母）──
// ALLSELECTED(Slicer_AX_Class)：整表移除 AX_Class 行筛选（含按列排序隐式带入的排序列筛选），
// 保留 Division / Label 分组筛选与外部切片器（组内分母）
VAR __Denominator =
    CALCULATE(
        SUM('a02_e2e_product_performance_inv_summary_d'[msrp_inv_amt]),
        ALLSELECTED('Slicer_AX_Class'),
        'a02_e2e_product_performance_inv_summary_d'[data_date] = __EndPeriodDate_LY
    )

RETURN
    DIVIDE(__Numerator, __Denominator)
```

### 4.13 Label & Division Table EOH Amt% vs LP Value（期末库存金额 vs LP 金额同比）

```dax
Label & Division Table EOH Amt% vs LP Value =
// ========================================
// 度量值: Label & Division Table EOH Amt% vs LP Value
// 中文名: 期末库存金额 vs LP（金额同比）
// Display Folder: Label & Division Table\Base Metrics
// 用途: This 快照日期末库存金额 / LP 快照日期末库存金额 − 1（原始比率，
//       Display 层格式化为整数百分比）；指标名沿用旧名「EOH Amt% vs LP」，
//       PBI 视觉对象绑定不变
// 依赖: [Label & Division Table EOH Amt TY Value]（§4.21）、
//       [Label & Division Table EOH Amt LP Value]（§4.22）
// 口径: 金额同比（v1.2 起；原「占比相减 ×10000 转 bp」已废止）；
//       双期各自取 Max_This / Max_Last 表 TimeFrame_Max 的单日快照
// 边界: 同期为 0 或空 → BLANK()（含双零 / 双空，显示 "-"）；
//       本期为 0 或空且同期有值 → -1（显示 -100%）
// ========================================
    VAR __ThisAmt = [Label & Division Table EOH Amt TY Value]
    VAR __BaseAmt = [Label & Division Table EOH Amt LP Value]

    RETURN
        IF(
            ISBLANK(__BaseAmt) || __BaseAmt = 0,
            BLANK(),
            IF(
                ISBLANK(__ThisAmt) || __ThisAmt = 0,
                -1,
                DIVIDE(__ThisAmt, __BaseAmt) - 1
            )
        )
```

### 4.14 Label & Division Table EOH Amt% vs LP Display（期末库存金额 vs LP 显示）

```dax
Label & Division Table EOH Amt% vs LP Display =
// ========================================
// 度量值: Label & Division Table EOH Amt% vs LP Display
// 中文名: 期末库存金额 vs LP 显示
// Display Folder: Label & Division Table\Formatting
// 用途: percent_0dp 格式化（百分比整数，负数自带负号）；BLANK 显示 "-"
// 依赖: [Label & Division Table EOH Amt% vs LP Value]
// 数据格式: #,##0%（如 12%、-8%）
// ========================================
    VAR __Value = [Label & Division Table EOH Amt% vs LP Value]
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            FORMAT(__Value, "#,##0%")
        )
```

### 4.15 Label & Division Table EOH Amt% vs LY Value（期末库存金额 vs LY 金额同比）

```dax
Label & Division Table EOH Amt% vs LY Value =
// ========================================
// 度量值: Label & Division Table EOH Amt% vs LY Value
// 中文名: 期末库存金额 vs LY（金额同比）
// Display Folder: Label & Division Table\Base Metrics
// 用途: This 快照日期末库存金额 / 去年同期末库存金额 − 1（原始比率，
//       Display 层格式化为整数百分比）；指标名沿用旧名「EOH Amt% vs LY」，
//       PBI 视觉对象绑定不变
// 依赖: [Label & Division Table EOH Amt TY Value]（§4.21）、
//       [Label & Division Table EOH Amt LY Value]（§4.23）
// 口径: 金额同比（v1.2 起；原「占比相减 ×10000 转 bp」已废止）；
//       LY 快照日为 _LY 字段财年同期映射区间单日（Max_This[TimeFrame_Max_LY]），
//       与 Last Period 切片器无关
// 边界: 同期为 0 或空 → BLANK()（含双零 / 双空，显示 "-"）；
//       本期为 0 或空且同期有值 → -1（显示 -100%）
// ========================================
    VAR __ThisAmt = [Label & Division Table EOH Amt TY Value]
    VAR __LastYearAmt = [Label & Division Table EOH Amt LY Value]

    RETURN
        IF(
            ISBLANK(__LastYearAmt) || __LastYearAmt = 0,
            BLANK(),
            IF(
                ISBLANK(__ThisAmt) || __ThisAmt = 0,
                -1,
                DIVIDE(__ThisAmt, __LastYearAmt) - 1
            )
        )
```

### 4.16 Label & Division Table EOH Amt% vs LY Display（期末库存金额 vs LY 显示）

```dax
Label & Division Table EOH Amt% vs LY Display =
// ========================================
// 度量值: Label & Division Table EOH Amt% vs LY Display
// 中文名: 期末库存金额 vs LY 显示
// Display Folder: Label & Division Table\Formatting
// 用途: percent_0dp 格式化（百分比整数，负数自带负号）；BLANK 显示 "-"
// 依赖: [Label & Division Table EOH Amt% vs LY Value]
// 数据格式: #,##0%（如 12%、-8%）
// ========================================
    VAR __Value = [Label & Division Table EOH Amt% vs LY Value]
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            FORMAT(__Value, "#,##0%")
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
        ISBLANK([Label & Division Table SLS Amt LP Value]) &&
        ISBLANK([Label & Division Table SLS Amt LY Value]) &&
        ISBLANK([Label & Division Table SLS Amt% vs LP Value]) &&
        ISBLANK([Label & Division Table SLS Amt% vs LY Value]) &&
        ISBLANK([Label & Division Table EOH Amt% Value]) &&
        ISBLANK([Label & Division Table EOH Amt LP Value]) &&
        ISBLANK([Label & Division Table EOH Amt LY Value]) &&
        ISBLANK([Label & Division Table EOH Amt% vs LP Value]) &&
        ISBLANK([Label & Division Table EOH Amt% vs LY Value]),
        0,
        1
    )
```

### 4.18 Label & Division Table SLS Amt TY Value（本期销售金额，v1.2 新增，内部引用）

```dax
Label & Division Table SLS Amt TY Value =
// ========================================
// 度量值: Label & Division Table SLS Amt TY Value
// 中文名: 本期销售金额（vs 的 this 侧）
// Display Folder: Label & Division Table\Base Metrics
// 用途: 仅供 [SLS Amt% vs LP Value] / [SLS Amt% vs LY Value] 引用的金额分子
//       （v1.2 新增），不直接进视觉对象、不做 Display
// 依赖: Slicer_Time_Frame_Min_This[TimeFrame_Min] / Slicer_Time_Frame_Max_This[TimeFrame_Max]
// 口径: This Period 区间 sum(net_sales_amt)；行级聚合（AX_Class 行筛选 + Division /
//       Label 分组筛选自动传导），无组内分母；渠道切片器经关系正常生效
// 数据底表: a02_e2e_product_performance_sales_summary_d
// ========================================

// ── This Period 时间区间 ──
VAR __PeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Min_This[TimeFrame_Min])
VAR __PeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

RETURN
    CALCULATE(
        SUM('a02_e2e_product_performance_sales_summary_d'[net_sales_amt]),
        'a02_e2e_product_performance_sales_summary_d'[data_date] >= __PeriodMin,
        'a02_e2e_product_performance_sales_summary_d'[data_date] <= __PeriodMax
    )
```

### 4.19 Label & Division Table SLS Amt LP Value（LP 销售金额，v1.2 新增，内部引用）

```dax
Label & Division Table SLS Amt LP Value =
// ========================================
// 度量值: Label & Division Table SLS Amt LP Value
// 中文名: LP 销售金额（vs LP 基线）
// Display Folder: Label & Division Table\Base Metrics
// 用途: 仅供 [SLS Amt% vs LP Value] 引用的基线金额（v1.2 新增），
//       不直接进视觉对象、不做 Display
// 依赖: Slicer_Time_Frame_Min_Last[TimeFrame_Min] / Slicer_Time_Frame_Max_Last[TimeFrame_Max]
// 口径: Last Period 区间 sum(net_sales_amt)（对比期由 LP 日期切片器选择决定）；
//       行级聚合，无组内分母
// 数据底表: a02_e2e_product_performance_sales_summary_d
// ========================================

// ── Last Period 时间区间（vs LP 基线）──
VAR __PeriodMin_LP = SELECTEDVALUE(Slicer_Time_Frame_Min_Last[TimeFrame_Min])
VAR __PeriodMax_LP = SELECTEDVALUE(Slicer_Time_Frame_Max_Last[TimeFrame_Max])

RETURN
    CALCULATE(
        SUM('a02_e2e_product_performance_sales_summary_d'[net_sales_amt]),
        'a02_e2e_product_performance_sales_summary_d'[data_date] >= __PeriodMin_LP,
        'a02_e2e_product_performance_sales_summary_d'[data_date] <= __PeriodMax_LP
    )
```

### 4.20 Label & Division Table SLS Amt LY Value（LY 销售金额，v1.2 新增，内部引用）

```dax
Label & Division Table SLS Amt LY Value =
// ========================================
// 度量值: Label & Division Table SLS Amt LY Value
// 中文名: LY 销售金额（vs LY 基线）
// Display Folder: Label & Division Table\Base Metrics
// 用途: 仅供 [SLS Amt% vs LY Value] 引用的基线金额（v1.2 新增），
//       不直接进视觉对象、不做 Display
// 依赖: Slicer_Time_Frame_Min_This[TimeFrame_Min_LY] / Slicer_Time_Frame_Max_This[TimeFrame_Max_LY]
// 口径: Last Year 区间 sum(net_sales_amt)（_LY 字段财年同期映射，与 Last Period
//       切片器无关）；行级聚合，无组内分母
// 数据底表: a02_e2e_product_performance_sales_summary_d
// ========================================

// ── Last Year 时间区间（vs LY 基线，_LY 字段财年同期映射）──
VAR __PeriodMin_LY = SELECTEDVALUE(Slicer_Time_Frame_Min_This[TimeFrame_Min_LY])
VAR __PeriodMax_LY = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max_LY])

RETURN
    CALCULATE(
        SUM('a02_e2e_product_performance_sales_summary_d'[net_sales_amt]),
        'a02_e2e_product_performance_sales_summary_d'[data_date] >= __PeriodMin_LY,
        'a02_e2e_product_performance_sales_summary_d'[data_date] <= __PeriodMax_LY
    )
```

### 4.21 Label & Division Table EOH Amt TY Value（本期期末库存金额，v1.2 新增，内部引用）

```dax
Label & Division Table EOH Amt TY Value =
// ========================================
// 度量值: Label & Division Table EOH Amt TY Value
// 中文名: 本期期末库存金额（vs 的 this 侧）
// Display Folder: Label & Division Table\Base Metrics
// 用途: 仅供 [EOH Amt% vs LP Value] / [EOH Amt% vs LY Value] 引用的金额分子
//       （v1.2 新增），不直接进视觉对象、不做 Display
// 依赖: Slicer_Time_Frame_Max_This[TimeFrame_Max]
// 口径: This 期末快照日（Max_This 表 TimeFrame_Max，直接单日过滤）sum(msrp_inv_amt)；
//       行级聚合，无组内分母；期末时点只取单日，对区间求和会重复计数库存
// 数据底表: a02_e2e_product_performance_inv_summary_d
// 说明: inv 表无 platform / shop_name 字段，不受渠道筛选影响
// ========================================

// ── 期末日期：end period 最后一天 = Max_This 表 TimeFrame_Max（直接单日过滤）──
VAR __EndPeriodDate = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

RETURN
    CALCULATE(
        SUM('a02_e2e_product_performance_inv_summary_d'[msrp_inv_amt]),
        'a02_e2e_product_performance_inv_summary_d'[data_date] = __EndPeriodDate
    )
```

### 4.22 Label & Division Table EOH Amt LP Value（LP 期末库存金额，v1.2 新增，内部引用）

```dax
Label & Division Table EOH Amt LP Value =
// ========================================
// 度量值: Label & Division Table EOH Amt LP Value
// 中文名: LP 期末库存金额（vs LP 基线）
// Display Folder: Label & Division Table\Base Metrics
// 用途: 仅供 [EOH Amt% vs LP Value] 引用的基线金额（v1.2 新增），
//       不直接进视觉对象、不做 Display
// 依赖: Slicer_Time_Frame_Max_Last[TimeFrame_Max]
// 口径: LP 期末快照日（Max_Last 表 TimeFrame_Max，直接单日过滤）sum(msrp_inv_amt)；
//       行级聚合，无组内分母
// 数据底表: a02_e2e_product_performance_inv_summary_d
// ========================================

// ── 期末日期（LP）：end period LP 最后一天 = Max_Last 表 TimeFrame_Max（直接单日过滤）──
VAR __EndPeriodDate_LP = SELECTEDVALUE(Slicer_Time_Frame_Max_Last[TimeFrame_Max])

RETURN
    CALCULATE(
        SUM('a02_e2e_product_performance_inv_summary_d'[msrp_inv_amt]),
        'a02_e2e_product_performance_inv_summary_d'[data_date] = __EndPeriodDate_LP
    )
```

### 4.23 Label & Division Table EOH Amt LY Value（LY 期末库存金额，v1.2 新增，内部引用）

```dax
Label & Division Table EOH Amt LY Value =
// ========================================
// 度量值: Label & Division Table EOH Amt LY Value
// 中文名: LY 期末库存金额（vs LY 基线）
// Display Folder: Label & Division Table\Base Metrics
// 用途: 仅供 [EOH Amt% vs LY Value] 引用的基线金额（v1.2 新增），
//       不直接进视觉对象、不做 Display
// 依赖: Slicer_Time_Frame_Max_This[TimeFrame_Max_LY]
// 口径: LY 期末快照日（Max_This 表 TimeFrame_Max_LY，_LY 字段财年同期映射，
//       直接单日过滤）sum(msrp_inv_amt)；与 Last Period 切片器无关
// 数据底表: a02_e2e_product_performance_inv_summary_d
// ========================================

// ── 期末日期（LY）：end period LY 最后一天 = Max_This 表 TimeFrame_Max_LY（直接单日过滤）──
VAR __EndPeriodDate_LY = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max_LY])

RETURN
    CALCULATE(
        SUM('a02_e2e_product_performance_inv_summary_d'[msrp_inv_amt]),
        'a02_e2e_product_performance_inv_summary_d'[data_date] = __EndPeriodDate_LY
    )
```
---

## 5. 度量值清单

| # | 度量值 | 指标类型 | 用于视觉对象 |
|---|---|---|---|
| 1 | Label & Division Table SLS Amt% Value / Display | percent_0dp | Division / Label 分组表 |
| 2 | Label & Division Table LP SLS Amt% Value | percent_0dp（中间值） | v1.2 起不再被引用（保留不删） |
| 3 | Label & Division Table LY SLS Amt% Value | percent_0dp（中间值） | v1.2 起不再被引用（保留不删） |
| 4 | Label & Division Table SLS Amt% vs LP Value / Display | percent_0dp（金额同比） | Division / Label 分组表 |
| 5 | Label & Division Table SLS Amt% vs LY Value / Display | percent_0dp（金额同比） | Division / Label 分组表 |
| 6 | Label & Division Table EOH Amt% Value / Display | percent_0dp | Division / Label 分组表 |
| 7 | Label & Division Table LP EOH Amt% Value | percent_0dp（中间值） | v1.2 起不再被引用（保留不删） |
| 8 | Label & Division Table LY EOH Amt% Value | percent_0dp（中间值） | v1.2 起不再被引用（保留不删） |
| 9 | Label & Division Table EOH Amt% vs LP Value / Display | percent_0dp（金额同比） | Division / Label 分组表 |
| 10 | Label & Division Table EOH Amt% vs LY Value / Display | percent_0dp（金额同比） | Division / Label 分组表 |
| 11 | Label & Division Table SLS Amt TY Value（§4.18） | 金额（中间值） | 仅被 vs LP / vs LY 引用 |
| 12 | Label & Division Table SLS Amt LP Value（§4.19） | 金额（中间值） | 仅被 vs LP 引用 |
| 13 | Label & Division Table SLS Amt LY Value（§4.20） | 金额（中间值） | 仅被 vs LY 引用 |
| 14 | Label & Division Table EOH Amt TY Value（§4.21） | 金额（中间值） | 仅被 vs LP / vs LY 引用 |
| 15 | Label & Division Table EOH Amt LP Value（§4.22） | 金额（中间值） | 仅被 vs LP 引用 |
| 16 | Label & Division Table EOH Amt LY Value（§4.23） | 金额（中间值） | 仅被 vs LY 引用 |

- 全部度量值存放于 `_Measures` 隐藏表；Display Folder：`Label & Division Table\Base Metrics`（Value 层）与 `Label & Division Table\Formatting`（Display 层）
- v1.2 新增 6 个金额度量（#11–#16），仅内部引用、不做 Display、不进视觉对象；新增度量无同名旧度量，需在 PBI 内**新建**
- #2 / #3 / #7 / #8 四个占比中间度量保留不删，仅不再被引用（vs 已改用金额度量）

---

## 6. 视觉对象配置

### 6.1 Division 分组表（×4）

| 配置项 | 内容 |
|---|---|
| 视觉对象类型 | 表格 |
| 视觉对象筛选器 | Slicer_Division[division] = 单值（CW / HM / MN / WM 各一表，is required 筛选器） |
| 行 | Slicer_AX_Class[ax_class] |
| 值列（按口径顺序） | SLS Amt% Display → SLS Amt% vs LP Display → SLS Amt% vs LY Display → EOH Amt% Display → EOH Amt% vs LP Display → EOH Amt% vs LY Display |
| 列标题 | 按口径指标名（SLS Amt% / SLS Amt% vs LP / SLS Amt% vs LY / EOH Amt% / EOH Amt% vs LP / EOH Amt% vs LY） |
| 行可见性 | 六个指标全为 BLANK 的 AX_Class 行由表格自动隐藏 |
| 总计 | 单级行无行小计需求；若开启总计行，占比类总计 = 100%（组内分母同范围） |

- 第 2/3/5/6 列（vs LP / vs LY）自 v1.2 起为**金额同比**（整数百分比），列标题与绑定的度量名称均不变——PBI 侧无需调整视觉对象配置，只整段替换度量逻辑

### 6.2 Label 分组表（×N）

| 配置项 | 内容 |
|---|---|
| 视觉对象类型 | 表格 |
| 视觉对象筛选器 | Slicer_Label[label] = 单值（每表固定一个 Label 值；Label 在事实表中对应 brand 字段） |
| 行 | Slicer_AX_Class[ax_class] |
| 值列 | 同 §6.1（与 Division 分组表共用全部度量值） |

### 6.3 切片器

| 切片器 | 类型 | 作用 |
|---|---|---|
| Slicer_Time_Frame | 主时间筛选器 | 驱动 Min_This / Max_This / Min_Last / Max_Last 断开维度表；vs LY 的去年区间取自 Min_This / Max_This 表的 TimeFrame_Min_LY / TimeFrame_Max_LY 字段 |
| Slicer_Platform_Selection / Slicer_Store_Name | 一对多关联（仅 sales 表） | 渠道筛选自动传递销售侧指标 |
| 商品维度切片器（Slicer_Division / Slicer_Label / Slicer_AX_Class 等） | 一对多关联（双表） | 外部筛选自动传递；占比分母经 ALLSELECTED(Slicer_AX_Class) 整表移除保留该外部筛选 |
| Slicer_Currency_Selection | 断开维度 | 本板块无金额展示指标，不影响任何指标值 |

---

## 7. 验证方法

验证 SQL 为 MySQL 8.0+ 语法（CTE / 窗口函数），与配套测试文件 `test_Label_&_Division_table.sql` 两段对应：段 1 Division 分组、段 2 Label 分组；对数时按视觉对象筛选器固定值筛选分组列（division / label）后与对应 PBI 表逐行对比。

| 指标 | 测试 SQL 还原 |
|---|---|
| SLS Amt% | 分组键 + ax_class 粒度聚合 net_sales_amt；分母 = SUM() OVER (PARTITION BY 分组键)（组内分母） |
| SLS Amt% vs LP / vs LY | v1.2：SLS Amt(TY) / SLS Amt(基线) − 1；基线为 Last Period / Last Year 区间的行级金额（SQL 输出原始比率，×100 即百分比） |
| EOH Amt% | inv 表三个快照日单日聚合；分母 = SUM() OVER (PARTITION BY 分组键) |
| EOH Amt% vs LP / vs LY | v1.2：EOH Amt(TY) / EOH Amt(基线) − 1；基线为 LP / LY 快照日的单日库存金额 |

- NULL 语义对齐：占比分子 NULL → 占比 NULL（显示 "-"）；vs 基线金额 NULL 或 0 → NULL；vs 本期金额 NULL 或 0 且基线非 0 → −1（−100%）
- 时间参数与替换方法见测试文件头部参数区

---

## 8. 注意事项

1. **组内分母**：分母 `ALLSELECTED(Slicer_AX_Class)` 整表移除 AX_Class 行筛选（含按列排序隐式带入的排序列筛选；auto-existence：同表共存时值列筛选会合并排序列为表粒度组合筛选，只移除值列则排序列筛选存活，排序键与业务值 1:1 → 占比恒 100%，必须整表移除），保留 Division / Label 视觉对象筛选器与全部外部切片器筛选——分母 = 该分组值下全量 AX_Class 合计，组内占比之和 = 100%。若误用 REMOVEFILTERS(Slicer_AX_Class)（移除该表全部筛选，含视觉对象筛选器），分母退化为跨分组全局合计，组内占比之和 ≠ 100%
2. **行字段必须从 Slicer_AX_Class 维度表拉取**：行筛选直接落在维度表字段上，ALLSELECTED(维度表整表) 才能正确移除；若误用事实表字段作行字段，占比恒 100%
3. **vs LP 与 vs LY 双基线独立**：vs LP 读 Last Period 日期切片器（Min_Last / Max_Last 表，对比期自由选择）；vs LY 读 This Period 所选时间行的 _LY 字段（TimeFrame_Min_LY / TimeFrame_Max_LY，财年日历去年同字段对称映射），与 Last Period 切片器无关。二者时间范围可以不同，属预期行为
4. **EOH 三个快照日各自独立取值**：This（Max_This 表范围）、LP（Max_Last 表范围）、LY（Max_This 表 _LY 字段范围）内最后一个有数据的快照日；任一范围整段缺数时对应基线 BLANK，差值显示 "-"；期末时点只取单日，对整段区间求和会重复计数库存
5. **inv 表无渠道字段**：EOH Amt% / EOH Amt TY / LP / LY 及其 vs 均不受渠道切片器影响；SLS Amt% / SLS Amt TY / LP / LY 及 vs 的金额分子受渠道筛选影响（sales 侧）——同一行两类指标的渠道口径不对称为模型物理限制，业务需知悉
6. **vs LP / vs LY 为金额同比（v1.2）**：4 个 vs 度量名称不变（PBI 已绑定），逻辑改为 SLS Amt / EOH Amt 的本期金额 / 同期金额 − 1；边界：同期为 0 或空 → BLANK()（含双零 / 双空，显示 "-"），本期为 0 或空且同期有值 → −1（显示 -100%）；Display 用 percent_0dp（`#,##0%`），不再 ×10000 转 bp。旧「占比相减」口径已废止；LP / LY 占比中间度量保留不删但不再被引用
7. **币种**：本板块指标为占比类与金额同比类，分子分母均同表同币种（底表 CNY），不受币种切片器影响，无需汇率换算；新增 6 个金额度量仅内部相除、不直接展示数值
8. **总计行为**：若表格开启总计行，占比类总计 = 100%（分子分母同范围）；金额同比总计 = 分组内全部 AX_Class 金额上卷后重算的比率（不是各行比率求和），均为汇总语义下的正确行为
9. **口径与语法**：口径文档中定义的所有指标必须遵守其数据类型与数据格式，与解决方案存在争议时一切以口径文档为准；DAX 文本常量使用双引号，单引号仅用于表名，列名使用方括号，例如：`[md_type] = "FP"`
10. **新增金额度量需在 PBI 内新建（v1.2）**：6 个 `… SLS Amt / EOH Amt × TY / LP / LY Value` 为全新度量名，需在 `_Measures` 表内新建（Display Folder 同 Base Metrics，不做 Display）；随后整段替换 4 个 vs Value + 4 个 vs Display 共 8 个度量（名称均不变）。验证：切换时间 / LP 切片器，vs 列随两期金额变化；某 AX_Class 本期无销售但有 LP 金额的行应显示 -100%；双期均无金额的行显示 "-"（行可见性由 IsEmpty 保持原逻辑，未纳入金额度量）
