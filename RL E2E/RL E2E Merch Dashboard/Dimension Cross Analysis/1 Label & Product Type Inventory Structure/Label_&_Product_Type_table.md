# Label & Product Type Inventory Structure 表格解决方案

> **版本**: v1.0
> **模块**: RL E2E Merch Dashboard - Dimension Cross Analysis Tab - Label & Product Type Inventory Structure
> **关联口径**: 口径文档/口径Markdown格式/Dimension Cross Analysis.md - 子模块一~子模块四（§1~§16）
> **数据底表（销售类）**: a02_e2e_product_performance_sales_summary_d
> **数据底表（库存类）**: a02_e2e_product_performance_inv_summary_d
> **关联维度**: Slicer_Time_Frame_Min_This / Max_This / Min_Last / Max_Last（时间，断开维度）；Slicer_Currency_Selection（币种，断开维度）；Slicer_Label / Slicer_Super_Season / Slicer_Product_Type / Slicer_Category / Slicer_Md_Type / Slicer_Division（商品维度，行字段来源，与双事实表一对多关联）
> **筛选影响范围**: date（断开维度，DAX 显式筛选）+ 渠道（Platform + Store Name，仅销售侧）+ 商品维度切片器（与双表已建关系，自动传递）

---

## 1. 需求理解

### 1.1 模块定位与视觉对象结构

本板块覆盖口径文档子模块一~四，由三类视觉对象构成：

| 视觉对象                            | 覆盖口径                                              | 结构                                                                    |
| ----------------------------------- | ----------------------------------------------------- | ----------------------------------------------------------------------- |
| 主视图表格 ×1                      | 子模块一（Label 视图）+ 子模块三（Product Type 视图） | 行维度六选一 + 8 列指标（含 2 列 vs LP 附属），两子模块共享同一套度量值 |
| 交叉柱形图 ×2（Label 基数）        | 子模块二                                              | x 轴 = Label，图例 = 交叉维度五选一，y 轴 = SLS Amt% / EOH Amt%         |
| 交叉柱形图 ×2（Product Type 基数） | 子模块四                                              | x 轴 = Product Type，图例 = 交叉维度五选一，y 轴 = SLS Amt% / EOH Amt%  |

- **主视图**（子模块一/三）：行维度在 `Slicer_Label[label]` / `Slicer_Super_Season[super_season]` / `Slicer_Product_Type[product_type]` / `Slicer_Category[category]` / `Slicer_Md_Type[md_type]` / `Slicer_Division[division]` 六个维度表字段中六选一（切换时替换视觉对象行区域字段）。子模块一与子模块三的指标公式、时间口径、附属指标、数据格式完全一致，唯一差异是行维度取值字段，占比分母统一 `ALLSELECTED` 六个维度字段后两视图共享同一套度量值
- **交叉视图**（子模块二/四）：以基数维度（Label 或 Product Type）为 x 轴，所选商品维度为图例拆分，统计各交叉维度值占单个柱形（该基数维度值）的占比。两个基数视图的交叉维度集合互异（Label 基数可切 product_type，Product Type 基数可切 label，其余 super_season / category / md_type / division 共用），分母的 `ALLSELECTED` 列集合不同，各自独立输出一套度量值

### 1.2 行维度与维度切换

| 视觉对象               | 行 / x 轴 / 图例                              | 来源表.字段                                                                                                                                                                            | 切换方式                               |
| ---------------------- | --------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------- |
| 主视图表格             | 行：商品维度六选一                            | Slicer_Label[label] / Slicer_Super_Season[super_season] / Slicer_Product_Type[product_type] / Slicer_Category[category] / Slicer_Md_Type[md_type] / Slicer_Division[division]          | 替换视觉对象行区域字段，度量值层无感知 |
| 交叉柱形图（子模块二） | x 轴：Label 固定；图例：交叉维度五选一        | x 轴 Slicer_Label[label]；图例 Slicer_Super_Season[super_season] / Slicer_Product_Type[product_type] / Slicer_Category[category] / Slicer_Md_Type[md_type] / Slicer_Division[division] | 图例字段替换                           |
| 交叉柱形图（子模块四） | x 轴：Product Type 固定；图例：交叉维度五选一 | x 轴 Slicer_Product_Type[product_type]；图例 Slicer_Label[label] / Slicer_Super_Season[super_season] / Slicer_Category[category] / Slicer_Md_Type[md_type] / Slicer_Division[division] | 图例字段替换                           |

- **行字段全部取自 Slicer_ 维度表**（非事实表字段）：Slicer_ 维度表与两张事实表均为一对多关联，行维度筛选经模型关系自动传导到 sales 与 inv 两表，库存类指标无需 TREATAS 桥接
- **Slicer_Label[label] 与事实表 [brand] 关联**：Label 维度值域取自 sales 表 `brand` 字段的 distinct 值（口径中的 "Label / Brand" 维度即 brand 字段，数据字典已由 label 统一更新为 brand）
- **主视图总计行（若开启）**：行维度值不传递，占比分子分母同范围（SLS Amt% = 100%），数量类为全量合计，YTD ST% / MD 为全量分子分母重算，均为汇总语义下的正确行为

### 1.3 主视图指标清单（子模块一 / 子模块三共享）

| 序号 | 指标           | 口径章节        | 时间口径                      | 计算公式                                                                                           | 数据类型 / 格式           |
| ---- | -------------- | --------------- | ----------------------------- | -------------------------------------------------------------------------------------------------- | ------------------------- |
| 1    | SLS Amt%       | §1 / §9       | This Period（区间）           | 分子：行维度下 sum(net_sales_amt)；分母：ALLSELECTED 六维度 sum(net_sales_amt)                     | percent_0dp → `#,##0%` |
| 2    | EOH Amt%       | §2 / §10      | End Period（期末时点）        | 分子：行维度下 sum(msrp_inv_amt)；分母：ALLSELECTED 六维度 sum(msrp_inv_amt)                       | percent_0dp → `#,##0%` |
| 3    | SLS Amt% vs LP | §1 / §9 附属  | This − Last（差值）          | SLS Amt%（this period）− SLS Amt%（last period），原始差值，×10000 转 bp 在 Display 层           | delta_bp → `#,##0bp`   |
| 4    | EOH Amt% vs LP | §2 / §10 附属 | 快照日 this − 快照日 LP      | EOH Amt%（this 快照日）− EOH Amt%（LP 快照日），原始差值，×10000 转 bp 在 Display 层             | delta_bp → `#,##0bp`   |
| 5    | SLS Unit       | §3 / §11      | This Period（区间）           | 行维度下 sum(net_sales_qty)                                                                        | integer → `#,##0`      |
| 6    | EOH Unit       | §4 / §12      | End Period（期末时点）        | 行维度下 sum(inv_qty)                                                                              | integer → `#,##0`      |
| 7    | YTD ST%        | §5 / §13      | YTD 区间 + 期末时点（跨双表） | sales.net_sales_qty / (sales.net_sales_qty + inv.inv_qty)，sales 侧为 YTD 区间，inv 侧为快照日单日 | percent_0dp → `#,##0%` |
| 8    | MD             | §6 / §14      | This Period（区间）           | 1 − sum(md_net_sales_amt) / sum(msrp_net_sales_amt)                                               | percent_0dp → `#,##0%` |

### 1.4 交叉视图指标清单（子模块二 / 子模块四独立）

| 序号 | 指标                            | 口径章节  | 时间口径               | 计算公式                                                                                                                                  | 数据类型 / 格式                  |
| ---- | ------------------------------- | --------- | ---------------------- | ----------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------- |
| 9    | Cross Label SLS Amt%            | §7       | This Period（区间）    | 分子：该 label × 交叉维度下 sum(net_sales_amt)；分母：该 label 内合计（ALLSELECTED 五交叉维度，保留 label）                              | percent_0dp → `#,##0%`        |
| 10   | Cross Label EOH Amt%            | §8       | End Period（期末时点） | 分子：该 label × 交叉维度下 sum(msrp_inv_amt)；分母：该 label 内合计（同上，快照日）                                                     | percent_0dp → `#,##0%`        |
| 11   | Cross PT SLS Amt%               | §15      | This Period（区间）    | 分子：该 product_type × 交叉维度下 sum(net_sales_amt)；分母：该 product_type 内合计（ALLSELECTED 五交叉维度含 label，保留 product_type） | percent_0dp → `#,##0%`        |
| 12   | Cross PT EOH Amt%               | §16      | End Period（期末时点） | 分子：该 product_type × 交叉维度下 sum(msrp_inv_amt)；分母：该 product_type 内合计（同上，快照日）                                       | percent_0dp → `#,##0%`        |
| 13   | Cross Label SLS Amt（金额附属） | §7 附属  | This Period（区间）    | 该 label × 交叉维度下 sum(net_sales_amt)，与 SLS Amt% 分子同口径                                                                         | currency → 币种符号 + `#,##0` |
| 14   | Cross Label EOH Amt（金额附属） | §8 附属  | End Period（期末时点） | 该 label × 交叉维度下 sum(msrp_inv_amt)，快照日单日，与 EOH Amt% 分子同口径                                                              | currency → 币种符号 + `#,##0` |
| 15   | Cross PT SLS Amt（金额附属）    | §15 附属 | This Period（区间）    | 该 product_type × 交叉维度下 sum(net_sales_amt)，与 SLS Amt% 分子同口径                                                                  | currency → 币种符号 + `#,##0` |
| 16   | Cross PT EOH Amt（金额附属）    | §16 附属 | End Period（期末时点） | 该 product_type × 交叉维度下 sum(msrp_inv_amt)，快照日单日，与 EOH Amt% 分子同口径                                                       | currency → 币种符号 + `#,##0` |

### 1.5 时间口径

| 口径                                    | 时间范围                                                                                                                                     | 适用指标                                              |
| --------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------- |
| This Period（区间类）                   | data_date ∈ [Slicer_Time_Frame_Min_This[TimeFrame_Min], Slicer_Time_Frame_Max_This[TimeFrame_Max]]                                          | SLS Amt%、SLS Unit、MD 及占比分子分母                 |
| Last Period（vs LP 基线，区间类）       | data_date ∈ [Slicer_Time_Frame_Min_Last[TimeFrame_Min], Slicer_Time_Frame_Max_Last[TimeFrame_Max]]                                          | LP SLS Amt%（vs LP 附属的 LP 侧）                     |
| End Period（期末时点类）                | end period 范围 [Slicer_Time_Frame_Max_This[TimeFrame_Min], Slicer_Time_Frame_Max_This[TimeFrame_Max]] 内**最后一个有数据的快照日**    | EOH Amt%、EOH Unit 及其占比分子分母、YTD ST% 库存分母 |
| End Period LP（期末时点类，vs LP 基线） | end period LP 范围 [Slicer_Time_Frame_Max_Last[TimeFrame_Min], Slicer_Time_Frame_Max_Last[TimeFrame_Max]] 内**最后一个有数据的快照日** | LP EOH Amt%（vs LP 附属的 LP 侧）                     |
| YTD（财年区间类）                       | data_date ∈ [Slicer_Time_Frame_Max_This[Fiscal_Year_First_Day], Slicer_Time_Frame_Max_This[TimeFrame_Max]]                                  | YTD ST% 销售侧                                        |

说明：

- **Last Period 直接读 Min_Last / Max_Last 筛选器**的 TimeFrame_Min / TimeFrame_Max，非 _LY / _LP 字段对称映射，依赖模型中 Last 表与主时间筛选器的既有关系配置；无特殊说明的 LY/LP 对比均按此口径
- **期末时点实现为「end period 范围内最后一个有数据的快照日」**：口径定义为 end period 最后一天，快照缺数时自动回退到范围内最近一天，避免整段空值；快照表按日存储，期末时点只取单日，对 end period 整段区间求和会把库存重复计数
- **YTD 起点取 Slicer_Time_Frame_Max_This[Fiscal_Year_First_Day]**（该行 TimeFrame_Min 落入的财年区间第一天，取数 SQL 按财年日历自关联生成）；口径表述为「end period 所在财年第一天至 end period 最后一天」，财年型日历的时间选项内 TimeFrame_Min 与 TimeFrame_Max 同属一个财年，二者等价

### 1.6 币种口径

- 主视图指标（占比类 SLS Amt% / EOH Amt% 及 vs LP、数量类 SLS Unit / EOH Unit、比率类 YTD ST% / MD）不涉及金额展示，无需币种换算：占比分子分母为同表同币种金额字段（底表金额均存储 CNY），换算与否比值不变
- 交叉视图金额类附属指标（Cross Label / Cross PT 的 SLS Amt、EOH Amt）为 currency 类型：货币符号由币种切片器（Slicer_Currency_Selection）决定，千分位整数；数据底表金额仅存储 CNY，Value 层完成汇率换算（原始值 ÷ Currency_ExchangeRate，RMB 汇率 = 1 时换算前后值相同），Display 层仅拼接币种符号

### 1.7 占比分母的两种范围模式

| 视图                    | 分母范围                                                 | 分母机制                                                                                                                                                                                                 |
| ----------------------- | -------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 主视图（子模块一/三）   | 各维度值占 **total**（外部筛选上下文下的全量合计） | `ALLSELECTED` 六个商品维度表字段：移除视觉对象内部的行维度筛选，保留外部切片器筛选；一次只有一个字段在行上，其余五个字段的 ALLSELECTED 为无操作，实现六维度切换一套逻辑通吃                            |
| 交叉视图（子模块二/四） | 各交叉维度值占 **单个柱形**（该基数维度值内合计）  | `ALLSELECTED` 五个交叉维度表字段：移除视觉对象内部的图例维度筛选，保留外部切片器筛选；x 轴基数维度筛选不被触及（等价于移除全部视觉对象字段筛选后重新保留当前柱形的基数维度值），分母自然限定在该柱形内 |

---

## 2. 现状分析

- 数据底表 `a02_e2e_product_performance_sales_summary_d`（日粒度汇总）：net_sales_amt（净销售金额）、net_sales_qty（净销售数量）、md_net_sales_amt（折扣价净销售金额）、msrp_net_sales_amt（吊牌价净销售金额）；维度含 platform、shop_name 及 brand / super_season / product_type / category / md_type / division 等全部商品维度；日期字段为 data_date（date 类型）；platform 已在数据源层过滤 IN ('JD','TM','RLE','DY')
- 数据底表 `a02_e2e_product_performance_inv_summary_d`（日快照）：msrp_inv_amt（库存吊牌价金额，期末库存金额口径）、inv_qty（库存数量，期末库存数量口径）；商品维度字段与 sales 表同名同构；**无 platform / shop_name 字段**（渠道筛选不影响库存侧指标）；日期字段为 data_date（date 类型）
- 模型关系：Slicer_Label（值域 = sales 表 brand distinct，label 字段）/ Slicer_Super_Season / Slicer_Product_Type / Slicer_Category / Slicer_Md_Type / Slicer_Division 等商品维度切片器与两张事实表均一对多关联，筛选自动传递双表；Slicer_Platform_Selection、Slicer_Store_Name 与 sales 表一对多关联；日期筛选器（Min_This / Max_This / Min_Last / Max_Last）为断开维度，时间范围在 DAX 中显式筛选；Slicer_Currency_Selection 为断开维度
- Slicer_Time_Frame_Max_This 含 Fiscal_Year_First_Day 字段（按 TimeFrame_Min 落入的财年区间自关联财年日历生成），YTD 区间起点直接读取
- 字段名已逐一核对数据字典（含 md_net_sales_amt / msrp_net_sales_amt / msrp_inv_amt / inv_qty 等）

---

## 3. 方案设计

### 3.1 度量值分层

```
Value（口径计算，保留原始小数）
←  分子 / 分母时间范围显式筛选（This Period / Last Period / 快照日）
←  主视图占比分母：ALLSELECTED 六个商品维度表字段（移除行维度筛选，保留外部切片器）
←  交叉视图占比分母：ALLSELECTED 五个交叉维度表字段（移除图例筛选，保留 x 轴基数维度与外部切片器）
←  期末快照日先经 REMOVEFILTERS(整表) 确定性取值，不随行上下文 / 切片器漂移
←  LP 中间度量值（LP SLS Amt% / LP EOH Amt%）供 vs LP 派生引用
←  交叉视图金额类附属 Value 层完成币种汇率换算（原始 CNY ÷ Currency_ExchangeRate）
↓
vs LP Value（差值，原始小数）
←  This 期占比 − LP 期占比；任一期 BLANK 时返回 BLANK
↓
Display（格式化显示）
←  percent_0dp: FORMAT(#,##0%)；integer: FORMAT(#,##0)
←  currency: 币种符号 & FORMAT(#,##0)（仅交叉视图金额类附属）
←  delta_bp: 值 ×10000 转 bp（FORMAT(#,##0) & "bp"，负数自带负号，零值 0bp）
←  BLANK 统一显示 "-"
```

### 3.2 主视图占比分母机制（ALLSELECTED 六维度）

口径「单品类占总品类的比例」的分母 = 外部筛选上下文下的全量合计：

- 分母对六个商品维度表字段同时应用 `ALLSELECTED`：行维度当前字段（六选一）的视觉对象内部行筛选被移除，恢复为外部切片器筛选状态；其余五个未上行字段的 ALLSELECTED 为无操作（其上仅有外部切片器筛选，保留不变）
- ALLSELECTED 与 REMOVEFILTERS 的差异是本方案的关键：REMOVEFILTERS 会移除该列全部筛选（含外部切片器），导致分母脱离业务筛选条件；ALLSELECTED 仅移除视觉对象内部的行 / 图例筛选，保留外部切片器筛选，分母始终是「外部筛选下」的全量合计
- 行字段从 Slicer_ 维度表拉取，行筛选直接落在维度表字段上，ALLSELECTED 作用于维度表字段即可正确移除；移除后经一对多关系向双事实表正向传导，分母聚合范围自动恢复全量（外部筛选下）

### 3.3 交叉视图占比分母机制（基数保留 + 交叉移除）

口径「以 Label / Product Type 为基数，看所选商品维度在该基数的占比」的分母 = 该基数维度值内合计：

- 实现为：分母仅对**五个交叉维度表字段**应用 ALLSELECTED（移除视觉对象内部的图例维度筛选——图例必为五者之一，其余为无操作），x 轴基数维度（Slicer_Label[label] 或 Slicer_Product_Type[product_type]）的筛选不被触及，分母自然限定在当前柱形的基数维度值内；外部切片器筛选同样保留
- 该实现与「先移除视觉对象全部字段筛选、保留外部切片器、再重新添加 x 轴当前基数维度值」的思路行为完全等价：基数维度筛选从未被移除，即天然保留当前柱形值，省去移除后重加的显式步骤
- 子模块二（Label 基数）与子模块四（Product Type 基数）的交叉维度集合互异：Label 基数可切 product_type，Product Type 基数可切 label，二者分母的 ALLSELECTED 列集合不同，无法合并为同一套度量值，各自独立输出
- 交叉度量值专用于对应柱形图；柱形图 x 轴无总计柱，无总计分支需求

### 3.4 期末时点与 vs LP

- 期末快照日：`__EndPeriodDate` 在每个库存类 Value 度量内以 `VAR __EndPeriodDate = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])` 确定性取值，不随行维度、切片器或柱形图上下文漂移；LP 侧快照日同法取 end period LP 范围
- vs LP 附属：LP 侧占比（LP SLS Amt% / LP EOH Amt%）作为独立中间度量值输出（时间范围替换为 Last Period / end period LP，分母机制与 This 侧完全一致），vs LP Value = This 期占比 − LP 期占比（原始差值）；任一期 BLANK 时返回 BLANK（避免单侧缺失产生失真差值）；×10000 转 bp 在 Display 层实现，保证 Value 层差值可复用
- EOH Amt% vs LP 的双期时点：This 侧取 end period 范围最后快照日，LP 侧取 end period LP 范围最后快照日，两侧各自单日时点值

### 3.5 度量值命名与组织

- 命名规则：模块前缀 `Label & PT Table` + 指标名 + 层次后缀（Value / Display）；LP 中间度量值在指标名前加 `LP`；交叉视图在指标名前加 `Cross Label` / `Cross PT`
- Display Folder：`Label & Product Type Inventory Structure\Base Metrics`、`Label & Product Type Inventory Structure\Formatting`
- 度量值统一存放于 `_Measures` 隐藏表

---

## 4. 度量值实现

### 4.1 Label & PT Table SLS Amt% Value（当期销售金额占比）

```dax
Label & PT Table SLS Amt% Value =
// ========================================
// 度量值: Label & PT Table SLS Amt% Value
// 中文名: 当期销售金额占比
// Display Folder: Label & Product Type Inventory Structure\Base Metrics
// 用途: 当前行商品维度值占 total 的销售金额比例（This Period 区间），
//       主视图六维度行切换共享（子模块一 Label / 子模块三 Product Type 视图）
// 依赖: Slicer_Time_Frame_Min_This[TimeFrame_Min] / Slicer_Time_Frame_Max_This[TimeFrame_Max]
// 口径: 时间范围看 this period；分子：各维度值下 sum(net_sales_amt)；
//       分母：sum(net_sales_amt)（占 total 比例）
// 数据底表: a02_e2e_product_performance_sales_summary_d
// 分母机制: ALLSELECTED 六个商品维度表字段——移除视觉对象内部的行维度筛选，
//       保留外部切片器筛选；一次只有一个字段在行上，其余五个字段为无操作，
//       实现六维度切换一套逻辑通吃；行字段来自维度表，移除后经一对多关系
//       向事实表正向传导，分母恢复全量（外部筛选下）
// 币种: 分子分母为同表同币种金额（底表 CNY），占比不受币种选择影响
// ========================================

// ── This Period 时间区间 ──
VAR __PeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Min_This[TimeFrame_Min])
VAR __PeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

// ── 分子：当前行维度值 This Period 净销售金额（行筛选经维度表关系自动传导）──
VAR __Numerator =
    CALCULATE(
        SUM('a02_e2e_product_performance_sales_summary_d'[net_sales_amt]),
        'a02_e2e_product_performance_sales_summary_d'[data_date] >= __PeriodMin,
        'a02_e2e_product_performance_sales_summary_d'[data_date] <= __PeriodMax
    )

// ── 分母：外部筛选上下文下的全量 This Period 净销售金额 ──
// ALLSELECTED 六维度：移除行维度视觉对象内部筛选，保留外部切片器筛选
VAR __Denominator =
    CALCULATE(
        SUM('a02_e2e_product_performance_sales_summary_d'[net_sales_amt]),
        ALLSELECTED('Slicer_Label'[label]),
        ALLSELECTED('Slicer_Super_Season'[super_season]),
        ALLSELECTED('Slicer_Product_Type'[product_type]),
        ALLSELECTED('Slicer_Category'[category]),
        ALLSELECTED('Slicer_Md_Type'[md_type]),
        ALLSELECTED('Slicer_Division'[division]),
        'a02_e2e_product_performance_sales_summary_d'[data_date] >= __PeriodMin,
        'a02_e2e_product_performance_sales_summary_d'[data_date] <= __PeriodMax
    )

RETURN
    DIVIDE(__Numerator, __Denominator)
```

### 4.2 Label & PT Table SLS Amt% Display（当期销售金额占比显示）

```dax
Label & PT Table SLS Amt% Display =
// ========================================
// 度量值: Label & PT Table SLS Amt% Display
// 中文名: 当期销售金额占比显示
// Display Folder: Label & Product Type Inventory Structure\Formatting
// 用途: percent_0dp 格式化（百分比整数，不含正号）；BLANK 显示 "-"
// 依赖: [Label & PT Table SLS Amt% Value]
// 数据格式: #,##0%（如 26%）
// ========================================
    VAR __Value = [Label & PT Table SLS Amt% Value]
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            FORMAT(__Value, "#,##0%")
        )
```

### 4.3 Label & PT Table LP SLS Amt% Value（LP 销售金额占比，中间度量值）

```dax
Label & PT Table LP SLS Amt% Value =
// ========================================
// 度量值: Label & PT Table LP SLS Amt% Value
// 中文名: LP 销售金额占比（vs LP 对比基线）
// Display Folder: Label & Product Type Inventory Structure\Base Metrics
// 用途: Last Period 销售金额占比，供 SLS Amt% vs LP 派生引用，不直接进视觉对象
// 依赖: Slicer_Time_Frame_Min_Last[TimeFrame_Min] / Slicer_Time_Frame_Max_Last[TimeFrame_Max]
// 口径: 与 SLS Amt% 同构（分母 ALLSELECTED 六维度），仅时间范围替换为 Last Period
// ========================================

// ── Last Period 时间区间（vs LP 基线）──
VAR __PeriodMin_LP = SELECTEDVALUE(Slicer_Time_Frame_Min_Last[TimeFrame_Min])
VAR __PeriodMax_LP = SELECTEDVALUE(Slicer_Time_Frame_Max_Last[TimeFrame_Max])

// ── 分子：当前行维度值 Last Period 净销售金额 ──
VAR __Numerator =
    CALCULATE(
        SUM('a02_e2e_product_performance_sales_summary_d'[net_sales_amt]),
        'a02_e2e_product_performance_sales_summary_d'[data_date] >= __PeriodMin_LP,
        'a02_e2e_product_performance_sales_summary_d'[data_date] <= __PeriodMax_LP
    )

// ── 分母：外部筛选上下文下的全量 Last Period 净销售金额（ALLSELECTED 六维度）──
VAR __Denominator =
    CALCULATE(
        SUM('a02_e2e_product_performance_sales_summary_d'[net_sales_amt]),
        ALLSELECTED('Slicer_Label'[label]),
        ALLSELECTED('Slicer_Super_Season'[super_season]),
        ALLSELECTED('Slicer_Product_Type'[product_type]),
        ALLSELECTED('Slicer_Category'[category]),
        ALLSELECTED('Slicer_Md_Type'[md_type]),
        ALLSELECTED('Slicer_Division'[division]),
        'a02_e2e_product_performance_sales_summary_d'[data_date] >= __PeriodMin_LP,
        'a02_e2e_product_performance_sales_summary_d'[data_date] <= __PeriodMax_LP
    )

RETURN
    DIVIDE(__Numerator, __Denominator)
```

### 4.4 Label & PT Table SLS Amt% vs LP Value（销售金额占比 vs LP 差值）

```dax
Label & PT Table SLS Amt% vs LP Value =
// ========================================
// 度量值: Label & PT Table SLS Amt% vs LP Value
// 中文名: 销售金额占比 vs LP（差值）
// Display Folder: Label & Product Type Inventory Structure\Base Metrics
// 用途: this period - last period 占比差值（原始小数，×10000 转 bp 在 Display 层实现）
// 依赖: [Label & PT Table SLS Amt% Value], [Label & PT Table LP SLS Amt% Value]
// 口径: this period - last period（差值，bp 指标）
// 边界: 任一期为 BLANK 时返回 BLANK，避免单侧缺失产生失真差值
// ========================================
    VAR __ThisPct = [Label & PT Table SLS Amt% Value]
    VAR __LastPct = [Label & PT Table LP SLS Amt% Value]

    RETURN
        IF(
            ISBLANK(__ThisPct) || ISBLANK(__LastPct),
            BLANK(),
            __ThisPct - __LastPct
        )
```

### 4.5 Label & PT Table SLS Amt% vs LP Display（销售金额占比 vs LP 显示）

```dax
Label & PT Table SLS Amt% vs LP Display =
// ========================================
// 度量值: Label & PT Table SLS Amt% vs LP Display
// 中文名: 销售金额占比 vs LP 显示
// Display Folder: Label & Product Type Inventory Structure\Formatting
// 用途: delta_bp 格式化：值 ×10000 转 bp，负数自带负号，零值 0bp；BLANK 显示 "-"
// 依赖: [Label & PT Table SLS Amt% vs LP Value]
// 数据格式: #,##0bp;-#,##0bp;0bp
// 说明: ×10000 转换在 Display 层实现，Value 层保留原始差值可复用
// ========================================
    VAR __Value = [Label & PT Table SLS Amt% vs LP Value]
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            FORMAT(__Value * 10000, "#,##0") & "bp"   // 负数自带负号，零值 0bp
        )
```

### 4.6 Label & PT Table EOH Amt% Value（当期期末库存金额占比）

```dax
Label & PT Table EOH Amt% Value =
// ========================================
// 度量值: Label & PT Table EOH Amt% Value
// 中文名: 当期期末库存金额占比
// Display Folder: Label & Product Type Inventory Structure\Base Metrics
// 用途: 当前行商品维度值占 total 的期末库存金额比例（快照日时点），
//       主视图六维度行切换共享
// 依赖: Slicer_Time_Frame_Max_This[TimeFrame_Min] / [TimeFrame_Max]
// 口径: 时间范围看 this period 最后一天（实现为 end period 范围内最后一个
//       有数据的快照日）；分子：各维度值下 sum(msrp_inv_amt)；
//       分母：sum(msrp_inv_amt)（占 total 比例）
// 数据底表: a02_e2e_product_performance_inv_summary_d
// 分母机制: ALLSELECTED 六个商品维度表字段（同 SLS Amt%），行筛选经维度表
//       关系自动传导 inv 表，移除后分母恢复全量（外部筛选下）
// 说明: inv 表无 platform / shop_name 字段，本指标分子分母均不受渠道筛选影响；
//       期末时点只取快照日单日，对区间求和会重复计数库存
// ========================================

// ── End Period 时间范围（期末时点类）──
VAR __EndPeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Min])
VAR __EndPeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

// ── 期末日期：end period 最后一天 = Max_This 表 TimeFrame_Max（直接单日过滤）──
VAR __EndPeriodDate = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

// ── 分子：当前行维度值期末库存金额（快照日单日值）──
VAR __Numerator =
    CALCULATE(
        SUM('a02_e2e_product_performance_inv_summary_d'[msrp_inv_amt]),
        'a02_e2e_product_performance_inv_summary_d'[data_date] = __EndPeriodDate
    )

// ── 分母：外部筛选上下文下的全量期末库存金额（ALLSELECTED 六维度，快照日单日）──
VAR __Denominator =
    CALCULATE(
        SUM('a02_e2e_product_performance_inv_summary_d'[msrp_inv_amt]),
        ALLSELECTED('Slicer_Label'[label]),
        ALLSELECTED('Slicer_Super_Season'[super_season]),
        ALLSELECTED('Slicer_Product_Type'[product_type]),
        ALLSELECTED('Slicer_Category'[category]),
        ALLSELECTED('Slicer_Md_Type'[md_type]),
        ALLSELECTED('Slicer_Division'[division]),
        'a02_e2e_product_performance_inv_summary_d'[data_date] = __EndPeriodDate
    )

RETURN
    DIVIDE(__Numerator, __Denominator)
```

### 4.7 Label & PT Table EOH Amt% Display（当期期末库存金额占比显示）

```dax
Label & PT Table EOH Amt% Display =
// ========================================
// 度量值: Label & PT Table EOH Amt% Display
// 中文名: 当期期末库存金额占比显示
// Display Folder: Label & Product Type Inventory Structure\Formatting
// 用途: percent_0dp 格式化（百分比整数，不含正号）；BLANK 显示 "-"
// 依赖: [Label & PT Table EOH Amt% Value]
// 数据格式: #,##0%（如 18%）
// ========================================
    VAR __Value = [Label & PT Table EOH Amt% Value]
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            FORMAT(__Value, "#,##0%")
        )
```

### 4.8 Label & PT Table LP EOH Amt% Value（LP 期末库存金额占比，中间度量值）

```dax
Label & PT Table LP EOH Amt% Value =
// ========================================
// 度量值: Label & PT Table LP EOH Amt% Value
// 中文名: LP 期末库存金额占比（vs LP 对比基线）
// Display Folder: Label & Product Type Inventory Structure\Base Metrics
// 用途: LP 期末库存金额占比，供 EOH Amt% vs LP 派生引用，不直接进视觉对象
// 依赖: Slicer_Time_Frame_Max_Last[TimeFrame_Min] / [TimeFrame_Max]
// 口径: 与 EOH Amt% 同构（分母 ALLSELECTED 六维度），期末时点替换为
//       end period LP 范围内最后一个有数据的快照日
// ========================================

// ── End Period LP 时间范围（期末时点类，vs LP 基线）──
VAR __EndPeriodMin_LP = SELECTEDVALUE(Slicer_Time_Frame_Max_Last[TimeFrame_Min])
VAR __EndPeriodMax_LP = SELECTEDVALUE(Slicer_Time_Frame_Max_Last[TimeFrame_Max])

// ── 期末日期（LP）：end period LP 最后一天 = Max_Last 表 TimeFrame_Max（直接单日过滤）──
VAR __EndPeriodDate_LP = SELECTEDVALUE(Slicer_Time_Frame_Max_Last[TimeFrame_Max])

// ── 分子：当前行维度值 LP 期末库存金额（LP 快照日单日值）──
VAR __Numerator =
    CALCULATE(
        SUM('a02_e2e_product_performance_inv_summary_d'[msrp_inv_amt]),
        'a02_e2e_product_performance_inv_summary_d'[data_date] = __EndPeriodDate_LP
    )

// ── 分母：外部筛选上下文下的全量 LP 期末库存金额（ALLSELECTED 六维度）──
VAR __Denominator =
    CALCULATE(
        SUM('a02_e2e_product_performance_inv_summary_d'[msrp_inv_amt]),
        ALLSELECTED('Slicer_Label'[label]),
        ALLSELECTED('Slicer_Super_Season'[super_season]),
        ALLSELECTED('Slicer_Product_Type'[product_type]),
        ALLSELECTED('Slicer_Category'[category]),
        ALLSELECTED('Slicer_Md_Type'[md_type]),
        ALLSELECTED('Slicer_Division'[division]),
        'a02_e2e_product_performance_inv_summary_d'[data_date] = __EndPeriodDate_LP
    )

RETURN
    DIVIDE(__Numerator, __Denominator)
```

### 4.9 Label & PT Table EOH Amt% vs LP Value（期末库存金额占比 vs LP 差值）

```dax
Label & PT Table EOH Amt% vs LP Value =
// ========================================
// 度量值: Label & PT Table EOH Amt% vs LP Value
// 中文名: 期末库存金额占比 vs LP（差值）
// Display Folder: Label & Product Type Inventory Structure\Base Metrics
// 用途: this period - last period 占比差值（原始小数，×10000 转 bp 在 Display 层实现）；
//       双期各自取 end period / end period LP 范围最后快照日的单日时点值
// 依赖: [Label & PT Table EOH Amt% Value], [Label & PT Table LP EOH Amt% Value]
// 口径: this period - last period（差值，bp 指标）
// 边界: 任一期为 BLANK 时返回 BLANK，避免单侧缺失产生失真差值
// ========================================
    VAR __ThisPct = [Label & PT Table EOH Amt% Value]
    VAR __LastPct = [Label & PT Table LP EOH Amt% Value]

    RETURN
        IF(
            ISBLANK(__ThisPct) || ISBLANK(__LastPct),
            BLANK(),
            __ThisPct - __LastPct
        )
```

### 4.10 Label & PT Table EOH Amt% vs LP Display（期末库存金额占比 vs LP 显示）

```dax
Label & PT Table EOH Amt% vs LP Display =
// ========================================
// 度量值: Label & PT Table EOH Amt% vs LP Display
// 中文名: 期末库存金额占比 vs LP 显示
// Display Folder: Label & Product Type Inventory Structure\Formatting
// 用途: delta_bp 格式化：值 ×10000 转 bp，负数自带负号，零值 0bp；BLANK 显示 "-"
// 依赖: [Label & PT Table EOH Amt% vs LP Value]
// 数据格式: #,##0bp;-#,##0bp;0bp
// ========================================
    VAR __Value = [Label & PT Table EOH Amt% vs LP Value]
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            FORMAT(__Value * 10000, "#,##0") & "bp"   // 负数自带负号，零值 0bp
        )
```

### 4.11 Label & PT Table SLS Unit Value（当期净销售数量）

```dax
Label & PT Table SLS Unit Value =
// ========================================
// 度量值: Label & PT Table SLS Unit Value
// 中文名: 当期净销售数量
// Display Folder: Label & Product Type Inventory Structure\Base Metrics
// 用途: 当前行商品维度值 This Period 净销售数量，主视图六维度行切换共享
// 依赖: Slicer_Time_Frame_Min_This[TimeFrame_Min] / Slicer_Time_Frame_Max_This[TimeFrame_Max]
// 口径: 时间范围看 this period；sum(net_sales_qty)
// 数据底表: a02_e2e_product_performance_sales_summary_d
// 说明: 数量类指标，不涉及币种换算；受渠道筛选影响（sales 侧）
// ========================================

// ── This Period 时间区间 ──
VAR __PeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Min_This[TimeFrame_Min])
VAR __PeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

RETURN
    CALCULATE(
        SUM('a02_e2e_product_performance_sales_summary_d'[net_sales_qty]),
        'a02_e2e_product_performance_sales_summary_d'[data_date] >= __PeriodMin,
        'a02_e2e_product_performance_sales_summary_d'[data_date] <= __PeriodMax
    )
```

### 4.12 Label & PT Table SLS Unit Display（当期净销售数量显示）

```dax
Label & PT Table SLS Unit Display =
// ========================================
// 度量值: Label & PT Table SLS Unit Display
// 中文名: 当期净销售数量显示
// Display Folder: Label & Product Type Inventory Structure\Formatting
// 用途: integer 格式化（千分位整数）；BLANK 显示 "-"
// 依赖: [Label & PT Table SLS Unit Value]
// 数据格式: #,##0（如 12,345）
// ========================================
    VAR __Value = [Label & PT Table SLS Unit Value]
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            FORMAT(__Value, "#,##0")
        )
```

### 4.13 Label & PT Table EOH Unit Value（当期期末库存数量）

```dax
Label & PT Table EOH Unit Value =
// ========================================
// 度量值: Label & PT Table EOH Unit Value
// 中文名: 当期期末库存数量
// Display Folder: Label & Product Type Inventory Structure\Base Metrics
// 用途: 当前行商品维度值期末库存数量（快照日时点），主视图六维度行切换共享
// 依赖: Slicer_Time_Frame_Max_This[TimeFrame_Min] / [TimeFrame_Max]
// 口径: 时间范围看 this period 最后一天（end period 范围内最后一个快照日）；
//       sum(inv_qty)
// 数据底表: a02_e2e_product_performance_inv_summary_d
// 说明: 行筛选经维度表关系自动传导 inv 表；inv 表无渠道字段，不受渠道筛选影响
// ========================================

// ── End Period 时间范围（期末时点类）──
VAR __EndPeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Min])
VAR __EndPeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

// ── 期末日期：end period 最后一天 = Max_This 表 TimeFrame_Max（直接单日过滤）──
VAR __EndPeriodDate = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

RETURN
    CALCULATE(
        SUM('a02_e2e_product_performance_inv_summary_d'[inv_qty]),
        'a02_e2e_product_performance_inv_summary_d'[data_date] = __EndPeriodDate
    )
```

### 4.14 Label & PT Table EOH Unit Display（当期期末库存数量显示）

```dax
Label & PT Table EOH Unit Display =
// ========================================
// 度量值: Label & PT Table EOH Unit Display
// 中文名: 当期期末库存数量显示
// Display Folder: Label & Product Type Inventory Structure\Formatting
// 用途: integer 格式化（千分位整数）；BLANK 显示 "-"
// 依赖: [Label & PT Table EOH Unit Value]
// 数据格式: #,##0（如 45,678）
// ========================================
    VAR __Value = [Label & PT Table EOH Unit Value]
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            FORMAT(__Value, "#,##0")
        )
```

### 4.15 Label & PT Table YTD ST% Value（YTD 售罄率）

```dax
Label & PT Table YTD ST% Value =
// ========================================
// 度量值: Label & PT Table YTD ST% Value
// 中文名: YTD 售罄率%（数量口径）
// Display Folder: Label & Product Type Inventory Structure\Base Metrics
// 用途: 年至今销售数量 /（年至今销售数量 + 期末库存数量），主视图六维度行切换共享
// 依赖: Slicer_Time_Frame_Max_This[Fiscal_Year_First_Day] / [TimeFrame_Min] / [TimeFrame_Max]
// 口径: 销售数量：end period 所在财年第一天至 end period 最后一天销售数量之和；
//       期末库存数量：看所选时间范围 end period 最后一天（快照日单日时点）；
//       sales.net_sales_qty / (sales.net_sales_qty + inv.inv_qty)（数量口径）
// 数据底表: a02_e2e_product_performance_sales_summary_d（sales）；
//           a02_e2e_product_performance_inv_summary_d（inv）
// 说明: 跨双表时间口径不同——分子为 YTD 区间汇总，分母为快照日单日值，不可混用；
//       行维度经维度表关系自动传导双表；分子（sales 侧）受渠道筛选影响，
//       分母（inv 侧）不受渠道筛选影响（inv 表无渠道字段）；
//       YTD 起点 Fiscal_Year_First_Day 为 TimeFrame_Min 落入的财年第一天，
//       财年型时间选项内 TimeFrame_Min 与 TimeFrame_Max 同属一个财年，
//       与口径「end period 所在财年」等价
// ========================================

// ── YTD 时间区间（销售侧）──
VAR __YTDStart = SELECTEDVALUE(Slicer_Time_Frame_Max_This[Fiscal_Year_First_Day])
VAR __PeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

// ── End Period 时间范围（库存侧期末时点）──
VAR __EndPeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Min])
VAR __EndPeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

// ── 期末日期：end period 最后一天 = Max_This 表 TimeFrame_Max（直接单日过滤）──
VAR __EndPeriodDate = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

// ── 分子：YTD 销售数量（YTD 区间，sales 表，行筛选自动传导）──
VAR __SLSQty_YTD =
    CALCULATE(
        SUM('a02_e2e_product_performance_sales_summary_d'[net_sales_qty]),
        'a02_e2e_product_performance_sales_summary_d'[data_date] >= __YTDStart,
        'a02_e2e_product_performance_sales_summary_d'[data_date] <= __PeriodMax
    )

// ── 库存加项：期末库存数量（快照日单日，inv 表，行筛选自动传导）──
VAR __InvQty_End =
    CALCULATE(
        SUM('a02_e2e_product_performance_inv_summary_d'[inv_qty]),
        'a02_e2e_product_performance_inv_summary_d'[data_date] = __EndPeriodDate
    )

RETURN
    DIVIDE(__SLSQty_YTD, __SLSQty_YTD + __InvQty_End)
```

### 4.16 Label & PT Table YTD ST% Display（YTD 售罄率显示）

```dax
Label & PT Table YTD ST% Display =
// ========================================
// 度量值: Label & PT Table YTD ST% Display
// 中文名: YTD 售罄率显示
// Display Folder: Label & Product Type Inventory Structure\Formatting
// 用途: percent_0dp 格式化（百分比整数，不含正号）；BLANK 显示 "-"
// 依赖: [Label & PT Table YTD ST% Value]
// 数据格式: #,##0%（如 63%）
// ========================================
    VAR __Value = [Label & PT Table YTD ST% Value]
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            FORMAT(__Value, "#,##0%")
        )
```

### 4.17 Label & PT Table MD Value（当期平均折扣）

```dax
Label & PT Table MD Value =
// ========================================
// 度量值: Label & PT Table MD Value
// 中文名: 当期平均折扣
// Display Folder: Label & Product Type Inventory Structure\Base Metrics
// 用途: 当前行商品维度值 This Period 平均折扣，主视图六维度行切换共享
// 依赖: Slicer_Time_Frame_Min_This[TimeFrame_Min] / Slicer_Time_Frame_Max_This[TimeFrame_Max]
// 口径: 时间范围看 this period；1 - sum(md_net_sales_amt) / sum(msrp_net_sales_amt)
// 数据底表: a02_e2e_product_performance_sales_summary_d
// 边界: 分母（吊牌金额）空或 0 时返回 BLANK，避免 1 - BLANK() = 1（即 100% 折扣）失真
// 说明: 分子分母为同表金额字段（底表 CNY），折扣率不受币种选择影响
// ========================================

// ── This Period 时间区间 ──
VAR __PeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Min_This[TimeFrame_Min])
VAR __PeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

// ── 折扣价净销售金额（分子）与吊牌价净销售金额（分母）──
VAR __MdAmt =
    CALCULATE(
        SUM('a02_e2e_product_performance_sales_summary_d'[md_net_sales_amt]),
        'a02_e2e_product_performance_sales_summary_d'[data_date] >= __PeriodMin,
        'a02_e2e_product_performance_sales_summary_d'[data_date] <= __PeriodMax
    )
VAR __MsrpAmt =
    CALCULATE(
        SUM('a02_e2e_product_performance_sales_summary_d'[msrp_net_sales_amt]),
        'a02_e2e_product_performance_sales_summary_d'[data_date] >= __PeriodMin,
        'a02_e2e_product_performance_sales_summary_d'[data_date] <= __PeriodMax
    )

RETURN
    IF(
        ISBLANK(__MsrpAmt) || __MsrpAmt = 0,
        BLANK(),
        1 - DIVIDE(__MdAmt, __MsrpAmt)
    )
```

### 4.18 Label & PT Table MD Display（当期平均折扣显示）

```dax
Label & PT Table MD Display =
// ========================================
// 度量值: Label & PT Table MD Display
// 中文名: 当期平均折扣显示
// Display Folder: Label & Product Type Inventory Structure\Formatting
// 用途: percent_0dp 格式化（百分比整数，不含正号）；BLANK 显示 "-"
// 依赖: [Label & PT Table MD Value]
// 数据格式: #,##0%（如 32%）
// ========================================
    VAR __Value = [Label & PT Table MD Value]
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            FORMAT(__Value, "#,##0%")
        )
```

### 4.19 Label & PT Table Cross Label SLS Amt% Value（Label 基数交叉销售金额占比）

```dax
Label & PT Table Cross Label SLS Amt% Value =
// ========================================
// 度量值: Label & PT Table Cross Label SLS Amt% Value
// 中文名: Label 基数交叉销售金额占比
// Display Folder: Label & Product Type Inventory Structure\Base Metrics
// 用途: 以 Label 为基数（x 轴），所选交叉维度（图例）在该 Label 内的销售金额占比，
//       专用于子模块二交叉柱形图（x 轴 = Slicer_Label[label]，图例五选一）
// 依赖: Slicer_Time_Frame_Min_This[TimeFrame_Min] / Slicer_Time_Frame_Max_This[TimeFrame_Max]
// 口径: 时间范围看 this period；
//       分子：该 label × 交叉维度值下 sum(net_sales_amt)；
//       分母：该 label 下 sum(net_sales_amt)（占单个柱形比例）
// 数据底表: a02_e2e_product_performance_sales_summary_d
// 分母机制: 仅对五个交叉维度表字段应用 ALLSELECTED（移除视觉对象内部的
//       图例维度筛选——图例必为五者之一，其余为无操作），x 轴
//       Slicer_Label[label] 的柱形筛选不被触及，分母自然限定在当前柱形内；
//       外部切片器筛选保留。与「移除全部视觉对象字段筛选后重新保留 x 轴
//       当前 label 值」行为等价（基数筛选从未被移除）
// ========================================

// ── This Period 时间区间 ──
VAR __PeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Min_This[TimeFrame_Min])
VAR __PeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

// ── 分子：该 label × 交叉维度值 This Period 净销售金额（行上下文自动筛选）──
VAR __Numerator =
    CALCULATE(
        SUM('a02_e2e_product_performance_sales_summary_d'[net_sales_amt]),
        'a02_e2e_product_performance_sales_summary_d'[data_date] >= __PeriodMin,
        'a02_e2e_product_performance_sales_summary_d'[data_date] <= __PeriodMax
    )

// ── 分母：该 label 内 This Period 净销售金额合计 ──
// ALLSELECTED 五个交叉维度：移除图例维度视觉对象内部筛选，保留 x 轴 label
// 柱形筛选与外部切片器筛选
VAR __Denominator =
    CALCULATE(
        SUM('a02_e2e_product_performance_sales_summary_d'[net_sales_amt]),
        ALLSELECTED('Slicer_Super_Season'[super_season]),
        ALLSELECTED('Slicer_Product_Type'[product_type]),
        ALLSELECTED('Slicer_Category'[category]),
        ALLSELECTED('Slicer_Md_Type'[md_type]),
        ALLSELECTED('Slicer_Division'[division]),
        'a02_e2e_product_performance_sales_summary_d'[data_date] >= __PeriodMin,
        'a02_e2e_product_performance_sales_summary_d'[data_date] <= __PeriodMax
    )

RETURN
    DIVIDE(__Numerator, __Denominator)
```

### 4.20 Label & PT Table Cross Label SLS Amt% Display（Label 基数交叉销售金额占比显示）

```dax
Label & PT Table Cross Label SLS Amt% Display =
// ========================================
// 度量值: Label & PT Table Cross Label SLS Amt% Display
// 中文名: Label 基数交叉销售金额占比显示
// Display Folder: Label & Product Type Inventory Structure\Formatting
// 用途: percent_0dp 格式化（百分比整数，不含正号）；BLANK 显示 "-"
// 依赖: [Label & PT Table Cross Label SLS Amt% Value]
// 数据格式: #,##0%（如 41%）
// ========================================
    VAR __Value = [Label & PT Table Cross Label SLS Amt% Value]
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            FORMAT(__Value, "#,##0%")
        )
```

### 4.21 Label & PT Table Cross Label EOH Amt% Value（Label 基数交叉期末库存金额占比）

```dax
Label & PT Table Cross Label EOH Amt% Value =
// ========================================
// 度量值: Label & PT Table Cross Label EOH Amt% Value
// 中文名: Label 基数交叉期末库存金额占比
// Display Folder: Label & Product Type Inventory Structure\Base Metrics
// 用途: 以 Label 为基数，所选交叉维度在该 Label 内的期末库存金额占比（快照日时点），
//       专用于子模块二交叉柱形图
// 依赖: Slicer_Time_Frame_Max_This[TimeFrame_Min] / [TimeFrame_Max]
// 口径: 时间范围看 this period 最后一天（end period 范围内最后一个快照日）；
//       分子：该 label × 交叉维度值下 sum(msrp_inv_amt)；
//       分母：该 label 下 sum(msrp_inv_amt)
// 数据底表: a02_e2e_product_performance_inv_summary_d
// 分母机制: 同 Cross Label SLS Amt%（ALLSELECTED 五交叉维度，保留 label 柱形筛选）
// 说明: inv 表无渠道字段，本指标分子分母均不受渠道筛选影响
// ========================================

// ── End Period 时间范围（期末时点类）──
VAR __EndPeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Min])
VAR __EndPeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

// ── 期末日期：end period 最后一天 = Max_This 表 TimeFrame_Max（直接单日过滤）──
VAR __EndPeriodDate = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

// ── 分子：该 label × 交叉维度值期末库存金额（快照日单日值）──
VAR __Numerator =
    CALCULATE(
        SUM('a02_e2e_product_performance_inv_summary_d'[msrp_inv_amt]),
        'a02_e2e_product_performance_inv_summary_d'[data_date] = __EndPeriodDate
    )

// ── 分母：该 label 内期末库存金额合计（快照日单日值）──
VAR __Denominator =
    CALCULATE(
        SUM('a02_e2e_product_performance_inv_summary_d'[msrp_inv_amt]),
        ALLSELECTED('Slicer_Super_Season'[super_season]),
        ALLSELECTED('Slicer_Product_Type'[product_type]),
        ALLSELECTED('Slicer_Category'[category]),
        ALLSELECTED('Slicer_Md_Type'[md_type]),
        ALLSELECTED('Slicer_Division'[division]),
        'a02_e2e_product_performance_inv_summary_d'[data_date] = __EndPeriodDate
    )

RETURN
    DIVIDE(__Numerator, __Denominator)
```

### 4.22 Label & PT Table Cross Label EOH Amt% Display（Label 基数交叉期末库存金额占比显示）

```dax
Label & PT Table Cross Label EOH Amt% Display =
// ========================================
// 度量值: Label & PT Table Cross Label EOH Amt% Display
// 中文名: Label 基数交叉期末库存金额占比显示
// Display Folder: Label & Product Type Inventory Structure\Formatting
// 用途: percent_0dp 格式化（百分比整数，不含正号）；BLANK 显示 "-"
// 依赖: [Label & PT Table Cross Label EOH Amt% Value]
// 数据格式: #,##0%（如 37%）
// ========================================
    VAR __Value = [Label & PT Table Cross Label EOH Amt% Value]
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            FORMAT(__Value, "#,##0%")
        )
```

### 4.23 Label & PT Table Cross PT SLS Amt% Value（Product Type 基数交叉销售金额占比）

```dax
Label & PT Table Cross PT SLS Amt% Value =
// ========================================
// 度量值: Label & PT Table Cross PT SLS Amt% Value
// 中文名: Product Type 基数交叉销售金额占比
// Display Folder: Label & Product Type Inventory Structure\Base Metrics
// 用途: 以 Product Type 为基数（x 轴），所选交叉维度（图例，含 label）在该
//       Product Type 内的销售金额占比，专用于子模块四交叉柱形图
//       （x 轴 = Slicer_Product_Type[product_type]，图例五选一）
// 依赖: Slicer_Time_Frame_Min_This[TimeFrame_Min] / Slicer_Time_Frame_Max_This[TimeFrame_Max]
// 口径: 时间范围看 this period；
//       分子：该 product_type × 交叉维度值下 sum(net_sales_amt)；
//       分母：该 product_type 下 sum(net_sales_amt)（占单个柱形比例）
// 数据底表: a02_e2e_product_performance_sales_summary_d
// 分母机制: ALLSELECTED 五个交叉维度字段（label / super_season / category /
//       md_type / division，含 label——Label 基数视图不可切的维度在此可切），
//       移除图例维度视觉对象内部筛选，保留 x 轴 product_type 柱形筛选与
//       外部切片器筛选；与 Cross Label 视图的 ALLSELECTED 列集合互异
//      （product_type 与 label 互换位置），故独立成套
// ========================================

// ── This Period 时间区间 ──
VAR __PeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Min_This[TimeFrame_Min])
VAR __PeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

// ── 分子：该 product_type × 交叉维度值 This Period 净销售金额 ──
VAR __Numerator =
    CALCULATE(
        SUM('a02_e2e_product_performance_sales_summary_d'[net_sales_amt]),
        'a02_e2e_product_performance_sales_summary_d'[data_date] >= __PeriodMin,
        'a02_e2e_product_performance_sales_summary_d'[data_date] <= __PeriodMax
    )

// ── 分母：该 product_type 内 This Period 净销售金额合计 ──
VAR __Denominator =
    CALCULATE(
        SUM('a02_e2e_product_performance_sales_summary_d'[net_sales_amt]),
        ALLSELECTED('Slicer_Label'[label]),
        ALLSELECTED('Slicer_Super_Season'[super_season]),
        ALLSELECTED('Slicer_Category'[category]),
        ALLSELECTED('Slicer_Md_Type'[md_type]),
        ALLSELECTED('Slicer_Division'[division]),
        'a02_e2e_product_performance_sales_summary_d'[data_date] >= __PeriodMin,
        'a02_e2e_product_performance_sales_summary_d'[data_date] <= __PeriodMax
    )

RETURN
    DIVIDE(__Numerator, __Denominator)
```

### 4.24 Label & PT Table Cross PT SLS Amt% Display（Product Type 基数交叉销售金额占比显示）

```dax
Label & PT Table Cross PT SLS Amt% Display =
// ========================================
// 度量值: Label & PT Table Cross PT SLS Amt% Display
// 中文名: Product Type 基数交叉销售金额占比显示
// Display Folder: Label & Product Type Inventory Structure\Formatting
// 用途: percent_0dp 格式化（百分比整数，不含正号）；BLANK 显示 "-"
// 依赖: [Label & PT Table Cross PT SLS Amt% Value]
// 数据格式: #,##0%（如 41%）
// ========================================
    VAR __Value = [Label & PT Table Cross PT SLS Amt% Value]
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            FORMAT(__Value, "#,##0%")
        )
```

### 4.25 Label & PT Table Cross PT EOH Amt% Value（Product Type 基数交叉期末库存金额占比）

```dax
Label & PT Table Cross PT EOH Amt% Value =
// ========================================
// 度量值: Label & PT Table Cross PT EOH Amt% Value
// 中文名: Product Type 基数交叉期末库存金额占比
// Display Folder: Label & Product Type Inventory Structure\Base Metrics
// 用途: 以 Product Type 为基数，所选交叉维度（图例，含 label）在该 Product Type
//       内的期末库存金额占比（快照日时点），专用于子模块四交叉柱形图
// 依赖: Slicer_Time_Frame_Max_This[TimeFrame_Min] / [TimeFrame_Max]
// 口径: 时间范围看 this period 最后一天（end period 范围内最后一个快照日）；
//       分子：该 product_type × 交叉维度值下 sum(msrp_inv_amt)；
//       分母：该 product_type 下 sum(msrp_inv_amt)
// 数据底表: a02_e2e_product_performance_inv_summary_d
// 分母机制: 同 Cross PT SLS Amt%（ALLSELECTED 五交叉维度含 label，
//       保留 product_type 柱形筛选）；inv 表无渠道字段，不受渠道筛选影响
// ========================================

// ── End Period 时间范围（期末时点类）──
VAR __EndPeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Min])
VAR __EndPeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

// ── 期末日期：end period 最后一天 = Max_This 表 TimeFrame_Max（直接单日过滤）──
VAR __EndPeriodDate = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

// ── 分子：该 product_type × 交叉维度值期末库存金额（快照日单日值）──
VAR __Numerator =
    CALCULATE(
        SUM('a02_e2e_product_performance_inv_summary_d'[msrp_inv_amt]),
        'a02_e2e_product_performance_inv_summary_d'[data_date] = __EndPeriodDate
    )

// ── 分母：该 product_type 内期末库存金额合计（快照日单日值）──
VAR __Denominator =
    CALCULATE(
        SUM('a02_e2e_product_performance_inv_summary_d'[msrp_inv_amt]),
        ALLSELECTED('Slicer_Label'[label]),
        ALLSELECTED('Slicer_Super_Season'[super_season]),
        ALLSELECTED('Slicer_Category'[category]),
        ALLSELECTED('Slicer_Md_Type'[md_type]),
        ALLSELECTED('Slicer_Division'[division]),
        'a02_e2e_product_performance_inv_summary_d'[data_date] = __EndPeriodDate
    )

RETURN
    DIVIDE(__Numerator, __Denominator)
```

### 4.26 Label & PT Table Cross PT EOH Amt% Display（Product Type 基数交叉期末库存金额占比显示）

```dax
Label & PT Table Cross PT EOH Amt% Display =
// ========================================
// 度量值: Label & PT Table Cross PT EOH Amt% Display
// 中文名: Product Type 基数交叉期末库存金额占比显示
// Display Folder: Label & Product Type Inventory Structure\Formatting
// 用途: percent_0dp 格式化（百分比整数，不含正号）；BLANK 显示 "-"
// 依赖: [Label & PT Table Cross PT EOH Amt% Value]
// 数据格式: #,##0%（如 37%）
// ========================================
    VAR __Value = [Label & PT Table Cross PT EOH Amt% Value]
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            FORMAT(__Value, "#,##0%")
        )
```

### 4.27 Label & PT Table Cross Label SLS Amt Value（Label 基数交叉净销售金额，金额附属）

```dax
Label & PT Table Cross Label SLS Amt Value =
// ========================================
// 度量值: Label & PT Table Cross Label SLS Amt Value
// 中文名: Label 基数交叉净销售金额（金额附属，当前币种）
// Display Folder: Label & Product Type Inventory Structure\Base Metrics
// 用途: SLS Amt%（§7）的金额类附属指标——该 label × 交叉维度值下 This Period
//       净销售金额绝对值（与占比分子同维度同时间口径），度量值备用，
//       具体绑定（tooltip / 数据标签 / 轴切换）由后续视觉对象配置决定
// 依赖: Slicer_Time_Frame_Min_This[TimeFrame_Min] / Slicer_Time_Frame_Max_This[TimeFrame_Max]
//       Slicer_Currency_Selection[Currency_ExchangeRate]
// 口径: 时间范围看 this period；该 label × 交叉维度下 sum(net_sales_amt)
// 数据底表: a02_e2e_product_performance_sales_summary_d
// 币种: 数据底表仅存 CNY，Value 层换算为当前币种金额（原始值 ÷ 汇率）；
//       RMB 汇率 = 1 时换算前后值相同
// ========================================

// ── This Period 时间区间 ──
VAR __PeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Min_This[TimeFrame_Min])
VAR __PeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

// ── 币种汇率（RMB = 1；USD 动态取自数仓汇率表）──
VAR __ExchangeRate = SELECTEDVALUE(Slicer_Currency_Selection[Currency_ExchangeRate], 1)

// ── 该 label × 交叉维度值 This Period 净销售金额（原始 CNY，行上下文自动筛选）──
VAR __BaseValue =
    CALCULATE(
        SUM('a02_e2e_product_performance_sales_summary_d'[net_sales_amt]),
        'a02_e2e_product_performance_sales_summary_d'[data_date] >= __PeriodMin,
        'a02_e2e_product_performance_sales_summary_d'[data_date] <= __PeriodMax
    )

RETURN
    DIVIDE(__BaseValue, __ExchangeRate)   // BLANK ÷ 汇率 = BLANK（当期无销售数据返回空）
```

### 4.28 Label & PT Table Cross Label SLS Amt Display（Label 基数交叉净销售金额显示）

```dax
Label & PT Table Cross Label SLS Amt Display =
// ========================================
// 度量值: Label & PT Table Cross Label SLS Amt Display
// 中文名: Label 基数交叉净销售金额显示
// Display Folder: Label & Product Type Inventory Structure\Formatting
// 用途: currency 格式化（币种符号 + 千分位整数，符号由币种切片器决定）；BLANK 显示 "-"
// 依赖: [Label & PT Table Cross Label SLS Amt Value], Slicer_Currency_Selection[Currency_Symbol]
// 数据格式: 币种符号 & #,##0（如 ¥1,000 / $1,000）
// ========================================
    VAR __Value = [Label & PT Table Cross Label SLS Amt Value]
    VAR __CurrencySymbol = SELECTEDVALUE(Slicer_Currency_Selection[Currency_Symbol], "¥")
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            __CurrencySymbol & FORMAT(__Value, "#,##0")
        )
```

### 4.29 Label & PT Table Cross Label EOH Amt Value（Label 基数交叉期末库存金额，金额附属）

```dax
Label & PT Table Cross Label EOH Amt Value =
// ========================================
// 度量值: Label & PT Table Cross Label EOH Amt Value
// 中文名: Label 基数交叉期末库存金额（金额附属，当前币种）
// Display Folder: Label & Product Type Inventory Structure\Base Metrics
// 用途: EOH Amt%（§8）的金额类附属指标——该 label × 交叉维度值下期末库存金额
//       绝对值（快照日单日时点，与占比分子同维度同时间口径），度量值备用
// 依赖: Slicer_Time_Frame_Max_This[TimeFrame_Min] / [TimeFrame_Max]
//       Slicer_Currency_Selection[Currency_ExchangeRate]
// 口径: 时间范围看 this period 最后一天（end period 范围内最后一个快照日）；
//       该 label × 交叉维度下 sum(msrp_inv_amt)
// 数据底表: a02_e2e_product_performance_inv_summary_d
// 币种: 数据底表仅存 CNY，Value 层换算为当前币种金额（原始值 ÷ 汇率）
// 说明: inv 表无 platform / shop_name 字段，本指标不受渠道筛选影响
// ========================================

// ── End Period 时间范围（期末时点类）──
VAR __EndPeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Min])
VAR __EndPeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

// ── 期末日期：end period 最后一天 = Max_This 表 TimeFrame_Max（直接单日过滤）──
VAR __EndPeriodDate = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

// ── 币种汇率（RMB = 1；USD 动态取自数仓汇率表）──
VAR __ExchangeRate = SELECTEDVALUE(Slicer_Currency_Selection[Currency_ExchangeRate], 1)

// ── 该 label × 交叉维度值期末库存金额（原始 CNY，快照日单日值）──
VAR __BaseValue =
    CALCULATE(
        SUM('a02_e2e_product_performance_inv_summary_d'[msrp_inv_amt]),
        'a02_e2e_product_performance_inv_summary_d'[data_date] = __EndPeriodDate
    )

RETURN
    DIVIDE(__BaseValue, __ExchangeRate)   // BLANK ÷ 汇率 = BLANK（快照日无库存数据返回空）
```

### 4.30 Label & PT Table Cross Label EOH Amt Display（Label 基数交叉期末库存金额显示）

```dax
Label & PT Table Cross Label EOH Amt Display =
// ========================================
// 度量值: Label & PT Table Cross Label EOH Amt Display
// 中文名: Label 基数交叉期末库存金额显示
// Display Folder: Label & Product Type Inventory Structure\Formatting
// 用途: currency 格式化（币种符号 + 千分位整数，符号由币种切片器决定）；BLANK 显示 "-"
// 依赖: [Label & PT Table Cross Label EOH Amt Value], Slicer_Currency_Selection[Currency_Symbol]
// 数据格式: 币种符号 & #,##0（如 ¥1,000 / $1,000）
// ========================================
    VAR __Value = [Label & PT Table Cross Label EOH Amt Value]
    VAR __CurrencySymbol = SELECTEDVALUE(Slicer_Currency_Selection[Currency_Symbol], "¥")
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            __CurrencySymbol & FORMAT(__Value, "#,##0")
        )
```

### 4.31 Label & PT Table Cross PT SLS Amt Value（Product Type 基数交叉净销售金额，金额附属）

```dax
Label & PT Table Cross PT SLS Amt Value =
// ========================================
// 度量值: Label & PT Table Cross PT SLS Amt Value
// 中文名: Product Type 基数交叉净销售金额（金额附属，当前币种）
// Display Folder: Label & Product Type Inventory Structure\Base Metrics
// 用途: SLS Amt%（§15）的金额类附属指标——该 product_type × 交叉维度值下
//       This Period 净销售金额绝对值（与占比分子同维度同时间口径），度量值备用
// 依赖: Slicer_Time_Frame_Min_This[TimeFrame_Min] / Slicer_Time_Frame_Max_This[TimeFrame_Max]
//       Slicer_Currency_Selection[Currency_ExchangeRate]
// 口径: 时间范围看 this period；该 product_type × 交叉维度下 sum(net_sales_amt)
// 数据底表: a02_e2e_product_performance_sales_summary_d
// 币种: 数据底表仅存 CNY，Value 层换算为当前币种金额（原始值 ÷ 汇率）；
//       RMB 汇率 = 1 时换算前后值相同
// ========================================

// ── This Period 时间区间 ──
VAR __PeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Min_This[TimeFrame_Min])
VAR __PeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

// ── 币种汇率（RMB = 1；USD 动态取自数仓汇率表）──
VAR __ExchangeRate = SELECTEDVALUE(Slicer_Currency_Selection[Currency_ExchangeRate], 1)

// ── 该 product_type × 交叉维度值 This Period 净销售金额（原始 CNY）──
VAR __BaseValue =
    CALCULATE(
        SUM('a02_e2e_product_performance_sales_summary_d'[net_sales_amt]),
        'a02_e2e_product_performance_sales_summary_d'[data_date] >= __PeriodMin,
        'a02_e2e_product_performance_sales_summary_d'[data_date] <= __PeriodMax
    )

RETURN
    DIVIDE(__BaseValue, __ExchangeRate)   // BLANK ÷ 汇率 = BLANK（当期无销售数据返回空）
```

### 4.32 Label & PT Table Cross PT SLS Amt Display（Product Type 基数交叉净销售金额显示）

```dax
Label & PT Table Cross PT SLS Amt Display =
// ========================================
// 度量值: Label & PT Table Cross PT SLS Amt Display
// 中文名: Product Type 基数交叉净销售金额显示
// Display Folder: Label & Product Type Inventory Structure\Formatting
// 用途: currency 格式化（币种符号 + 千分位整数，符号由币种切片器决定）；BLANK 显示 "-"
// 依赖: [Label & PT Table Cross PT SLS Amt Value], Slicer_Currency_Selection[Currency_Symbol]
// 数据格式: 币种符号 & #,##0（如 ¥1,000 / $1,000）
// ========================================
    VAR __Value = [Label & PT Table Cross PT SLS Amt Value]
    VAR __CurrencySymbol = SELECTEDVALUE(Slicer_Currency_Selection[Currency_Symbol], "¥")
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            __CurrencySymbol & FORMAT(__Value, "#,##0")
        )
```

### 4.33 Label & PT Table Cross PT EOH Amt Value（Product Type 基数交叉期末库存金额，金额附属）

```dax
Label & PT Table Cross PT EOH Amt Value =
// ========================================
// 度量值: Label & PT Table Cross PT EOH Amt Value
// 中文名: Product Type 基数交叉期末库存金额（金额附属，当前币种）
// Display Folder: Label & Product Type Inventory Structure\Base Metrics
// 用途: EOH Amt%（§16）的金额类附属指标——该 product_type × 交叉维度值下
//       期末库存金额绝对值（快照日单日时点，与占比分子同维度同时间口径），度量值备用
// 依赖: Slicer_Time_Frame_Max_This[TimeFrame_Min] / [TimeFrame_Max]
//       Slicer_Currency_Selection[Currency_ExchangeRate]
// 口径: 时间范围看 this period 最后一天（end period 范围内最后一个快照日）；
//       该 product_type × 交叉维度下 sum(msrp_inv_amt)
// 数据底表: a02_e2e_product_performance_inv_summary_d
// 币种: 数据底表仅存 CNY，Value 层换算为当前币种金额（原始值 ÷ 汇率）
// 说明: inv 表无 platform / shop_name 字段，本指标不受渠道筛选影响
// ========================================

// ── End Period 时间范围（期末时点类）──
VAR __EndPeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Min])
VAR __EndPeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

// ── 期末日期：end period 最后一天 = Max_This 表 TimeFrame_Max（直接单日过滤）──
VAR __EndPeriodDate = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

// ── 币种汇率（RMB = 1；USD 动态取自数仓汇率表）──
VAR __ExchangeRate = SELECTEDVALUE(Slicer_Currency_Selection[Currency_ExchangeRate], 1)

// ── 该 product_type × 交叉维度值期末库存金额（原始 CNY，快照日单日值）──
VAR __BaseValue =
    CALCULATE(
        SUM('a02_e2e_product_performance_inv_summary_d'[msrp_inv_amt]),
        'a02_e2e_product_performance_inv_summary_d'[data_date] = __EndPeriodDate
    )

RETURN
    DIVIDE(__BaseValue, __ExchangeRate)   // BLANK ÷ 汇率 = BLANK（快照日无库存数据返回空）
```

### 4.34 Label & PT Table Cross PT EOH Amt Display（Product Type 基数交叉期末库存金额显示）

```dax
Label & PT Table Cross PT EOH Amt Display =
// ========================================
// 度量值: Label & PT Table Cross PT EOH Amt Display
// 中文名: Product Type 基数交叉期末库存金额显示
// Display Folder: Label & Product Type Inventory Structure\Formatting
// 用途: currency 格式化（币种符号 + 千分位整数，符号由币种切片器决定）；BLANK 显示 "-"
// 依赖: [Label & PT Table Cross PT EOH Amt Value], Slicer_Currency_Selection[Currency_Symbol]
// 数据格式: 币种符号 & #,##0（如 ¥1,000 / $1,000）
// ========================================
    VAR __Value = [Label & PT Table Cross PT EOH Amt Value]
    VAR __CurrencySymbol = SELECTEDVALUE(Slicer_Currency_Selection[Currency_Symbol], "¥")
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            __CurrencySymbol & FORMAT(__Value, "#,##0")
        )
```

### 4.35 Label & Product Dimensions IsEmpty
```dax
Label & Product Dimensions IsEmpty =
// ========================================
// 度量值: Label & Product Dimensions IsEmpty
// 中文名: 行非空判定
// Display Folder: Label & Product Dimensions IsEmpty\IsEmpty
// 用途: 行可见性判定——该行全部核心指标为空时返回 0，任一有值返回 1；
//       用于表格视觉级筛选器（IsEmpty = 1 仅显示有数据的行，
// ========================================
    IF(
        ISBLANK([Label & PT Table EOH Amt% Value]) &&
        ISBLANK([Label & PT Table SLS Amt% Value]) &&
        ISBLANK([Label & PT Table EOH Amt% vs LP Value]) &&
        ISBLANK([Label & PT Table SLS Amt% vs LP Value]),
        0,
        1
    )

```

### 4.36 Label & Product Dimensions Cross IsEmpty
```dax
Label & Product Dimensions Cross IsEmpty =
// ========================================
// 度量值: Label & Product Dimensions Cross IsEmpty
// 中文名: 行非空判定
// Display Folder: Label & Product Dimensions Cross IsEmpty\IsEmpty
// 用途: 行可见性判定——该行全部核心指标为空时返回 0，任一有值返回 1；
//       用于表格视觉级筛选器（IsEmpty = 1 仅显示有数据的行，
// ========================================
    IF(
        ISBLANK([Label & PT Table Cross Label SLS Amt Value]) &&
        ISBLANK([Label & PT Table Cross Label EOH Amt Value]),
        0,
        1
    )

```

### 4.37 Label & Product Dimensions Table IsEmpty
```dax
Label & Product Dimensions Table IsEmpty =
// ========================================
// 度量值: Label & Product Dimensions Table IsEmpty
// 中文名: 行非空判定
// Display Folder: Label & Product Dimensions Table IsEmpty\IsEmpty
// 用途: 行可见性判定——该行全部核心指标为空时返回 0，任一有值返回 1；
//       用于表格视觉级筛选器（IsEmpty = 1 仅显示有数据的行，
// ========================================
    IF(
        ISBLANK([Label & PT Table SLS Unit Value]) &&
        ISBLANK([Label & PT Table EOH Unit Value]) &&
        ISBLANK([Label & PT Table YTD ST% Value]) &&
        ISBLANK([Label & PT Table MD Value]),
        0,
        1
    )

```

### 4.38 PT & Product Dimensions Cross IsEmpty
```dax
PT & Product Dimensions Cross IsEmpty =
// ========================================
// 度量值: PT & Product Dimensions Cross IsEmpty
// 中文名: 行非空判定
// Display Folder: PT & Product Dimensions Cross IsEmpty\IsEmpty
// 用途: 行可见性判定——该行全部核心指标为空时返回 0，任一有值返回 1；
//       用于表格视觉级筛选器（IsEmpty = 1 仅显示有数据的行，
// ========================================
    IF(
        ISBLANK([Label & PT Table Cross PT SLS Amt Value]) &&
        ISBLANK([Label & PT Table Cross PT EOH Amt Value]),
        0,
        1
    )

```
---

## 5. 度量值清单

| #  | 度量值                                                | 指标类型              | 用于视觉对象                          |
| -- | ----------------------------------------------------- | --------------------- | ------------------------------------- |
| 1  | Label & PT Table SLS Amt% Value / Display             | percent_0dp           | 主视图表格                            |
| 2  | Label & PT Table EOH Amt% Value / Display             | percent_0dp           | 主视图表格                            |
| 3  | Label & PT Table LP SLS Amt% Value                    | percent_0dp（中间值） | 仅被 vs LP 引用                       |
| 4  | Label & PT Table LP EOH Amt% Value                    | percent_0dp（中间值） | 仅被 vs LP 引用                       |
| 5  | Label & PT Table SLS Amt% vs LP Value / Display       | delta_bp              | 主视图表格                            |
| 6  | Label & PT Table EOH Amt% vs LP Value / Display       | delta_bp              | 主视图表格                            |
| 7  | Label & PT Table SLS Unit Value / Display             | integer               | 主视图表格                            |
| 8  | Label & PT Table EOH Unit Value / Display             | integer               | 主视图表格                            |
| 9  | Label & PT Table YTD ST% Value / Display              | percent_0dp           | 主视图表格                            |
| 10 | Label & PT Table MD Value / Display                   | percent_0dp           | 主视图表格                            |
| 11 | Label & PT Table Cross Label SLS Amt% Value / Display | percent_0dp           | 交叉柱形图（Label 基数）              |
| 12 | Label & PT Table Cross Label EOH Amt% Value / Display | percent_0dp           | 交叉柱形图（Label 基数）              |
| 13 | Label & PT Table Cross PT SLS Amt% Value / Display    | percent_0dp           | 交叉柱形图（Product Type 基数）       |
| 14 | Label & PT Table Cross PT EOH Amt% Value / Display    | percent_0dp           | 交叉柱形图（Product Type 基数）       |
| 15 | Label & PT Table Cross Label SLS Amt Value / Display  | currency（金额附属）  | 交叉柱形图（Label 基数），备用        |
| 16 | Label & PT Table Cross Label EOH Amt Value / Display  | currency（金额附属）  | 交叉柱形图（Label 基数），备用        |
| 17 | Label & PT Table Cross PT SLS Amt Value / Display     | currency（金额附属）  | 交叉柱形图（Product Type 基数），备用 |
| 18 | Label & PT Table Cross PT EOH Amt Value / Display     | currency（金额附属）  | 交叉柱形图（Product Type 基数），备用 |

- 全部度量值存放于 `_Measures` 隐藏表；Display Folder：`Label & Product Type Inventory Structure\Base Metrics`（Value 层）与 `Label & Product Type Inventory Structure\Formatting`（Display 层）

---

## 6. 视觉对象配置

### 6.1 主视图表格（子模块一 / 子模块三，共享度量值）

| 配置项             | 内容                                                                                                                                                              |
| ------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 视觉对象类型       | 表格                                                                                                                                                              |
| 行                 | Slicer_ 六维度字段之一（六选一，切换时替换行区域字段；子模块一切 Label，子模块三切 Product Type，其余维度两视图均可切）                                           |
| 值列（按口径顺序） | SLS Amt% Display → EOH Amt% Display → SLS Amt% vs LP Display → EOH Amt% vs LP Display → SLS Unit Display → EOH Unit Display → YTD ST% Display → MD Display |
| 列标题             | 按口径指标名（SLS Amt% / EOH Amt% / SLS Amt% vs LP / EOH Amt% vs LP / SLS Unit / EOH Unit / YTD ST% / MD）                                                        |
| 排序               | 口径未定义排序规则，默认按行维度值排序；如需按值排序可对相应值列排序                                                                                              |
| 总计               | 若开启，行为见 §1.2（汇总语义正确）                                                                                                                              |

### 6.2 交叉柱形图（子模块二，Label 基数）

| 配置项       | 内容                                                                                                                                                                    |
| ------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 视觉对象类型 | 簇状柱形图（堆叠 / 簇状按版面需要选择）                                                                                                                                 |
| X 轴         | Slicer_Label[label]                                                                                                                                                     |
| 图例         | 交叉维度五选一：Slicer_Super_Season[super_season] / Slicer_Product_Type[product_type] / Slicer_Category[category] / Slicer_Md_Type[md_type] / Slicer_Division[division] |
| Y 轴         | Cross Label SLS Amt% Display（销售金额占比，This Period 区间）                                                                                                          |
| 建议         | EOH Amt%（快照日时点）另置一个柱形图，Y 轴 = Cross Label EOH Amt% Display；两个指标时间口径不同（区间 vs 快照日），分图呈现避免误读                                     |

> 金额附属：Cross Label SLS Amt / Cross Label EOH Amt（Value / Display）已输出备用，具体绑定（tooltip / 数据标签 / 轴切换）由后续视觉对象配置决定

### 6.3 交叉柱形图（子模块四，Product Type 基数）

| 配置项       | 内容                                                                                                                                                      |
| ------------ | --------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 视觉对象类型 | 簇状柱形图（同上）                                                                                                                                        |
| X 轴         | Slicer_Product_Type[product_type]                                                                                                                         |
| 图例         | 交叉维度五选一：Slicer_Label[label] / Slicer_Super_Season[super_season] / Slicer_Category[category] / Slicer_Md_Type[md_type] / Slicer_Division[division] |
| Y 轴         | Cross PT SLS Amt% Display；EOH Amt% 另置柱形图 = Cross PT EOH Amt% Display                                                                                |

> 金额附属：Cross PT SLS Amt / Cross PT EOH Amt（Value / Display）已输出备用，具体绑定（tooltip / 数据标签 / 轴切换）由后续视觉对象配置决定

### 6.4 切片器

| 切片器                                              | 类型                      | 作用                                                                                   |
| --------------------------------------------------- | ------------------------- | -------------------------------------------------------------------------------------- |
| Slicer_Time_Frame                                   | 主时间筛选器              | 驱动 Min_This / Max_This / Min_Last / Max_Last 断开维度表，经 SELECTEDVALUE 读入度量值 |
| Slicer_Platform_Selection / Slicer_Store_Name       | 一对多关联（仅 sales 表） | 渠道筛选自动传递销售侧指标                                                             |
| 商品维度切片器（Slicer_Label / Slicer_Division 等） | 一对多关联（双表）        | 外部筛选自动传递；占比分母经 ALLSELECTED 保留该外部筛选                                |
| Slicer_Currency_Selection                           | 断开维度                  | 本板块无金额展示指标，不影响任何指标值                                                 |

---

## 7. 验证方法

验证 SQL 为 ClickHouse 语法；时间范围与外部筛选条件按页面实际选择替换附加，与 Power BI 模型值逐项对齐。

### 7.1 主视图 SLS Amt%（行维度 = label 示例）

```sql
SELECT
    label,
    __numerator / SUM(__numerator) OVER () AS sls_amt_pct
FROM (
    SELECT
        brand AS label,
        SUM(net_sales_amt) AS __numerator
    FROM indep_rl_ads.a02_e2e_product_performance_sales_summary_d
    WHERE data_date >= '2025-06-29' AND data_date <= '2025-07-05'
        -- This Period 实际选择替换；外部切片器筛选条件（platform / 商品维度等）同步附加
    GROUP BY brand
)
```

- 分母窗口 `SUM(...) OVER ()` 对应 ALLSELECTED 六维度的全量合计（外部筛选下）；换行维度验证时将 brand 替换为对应维度字段

### 7.2 主视图 EOH Amt%（快照日时点）

```sql
WITH __end_date AS (
    SELECT max(data_date) AS end_date
    FROM indep_rl_ads.a02_e2e_product_performance_inv_summary_d
    WHERE data_date >= '2025-06-29' AND data_date <= '2025-07-05'   -- end period 范围（Max_This 表 TimeFrame_Min/Max）
)
SELECT
    label,
    __numerator / SUM(__numerator) OVER () AS eoh_amt_pct
FROM (
    SELECT
        inv.brand AS label,
        SUM(inv.msrp_inv_amt) AS __numerator
    FROM indep_rl_ads.a02_e2e_product_performance_inv_summary_d inv
    CROSS JOIN __end_date d
    WHERE inv.data_date = d.end_date
        -- 外部商品维度筛选条件同步附加；inv 表无渠道字段，不附加渠道条件（与 Power BI 行为一致）
    GROUP BY inv.brand
)
```

### 7.3 交叉视图（x 轴 = label，图例 = product_type 示例，子模块二）

```sql
SELECT
    label,
    product_type,
    __numerator / SUM(__numerator) OVER (PARTITION BY label) AS cross_sls_amt_pct
FROM (
    SELECT
        brand AS label,
        product_type,
        SUM(net_sales_amt) AS __numerator
    FROM indep_rl_ads.a02_e2e_product_performance_sales_summary_d
    WHERE data_date >= '2025-06-29' AND data_date <= '2025-07-05'
        -- 外部切片器筛选条件同步附加
    GROUP BY brand, product_type
)
```

- 窗口 `PARTITION BY label` 对应「占单个柱形」分母；子模块四验证时将分区键换为 product_type、行维度组合对应替换

### 7.4 YTD ST%（行维度 = label 示例，跨双表）

```sql
WITH __end_date AS (
    SELECT max(data_date) AS end_date
    FROM indep_rl_ads.a02_e2e_product_performance_inv_summary_d
    WHERE data_date >= '2025-06-29' AND data_date <= '2025-07-05'
),
__sales AS (
    SELECT brand AS label, SUM(net_sales_qty) AS ytd_qty
    FROM indep_rl_ads.a02_e2e_product_performance_sales_summary_d
    WHERE data_date >= '2025-03-30' AND data_date <= '2025-07-05'
        -- Fiscal_Year_First_Day（TimeFrame_Min 落入财年第一天）至 TimeFrame_Max
    GROUP BY brand
),
__inv AS (
    SELECT inv.brand AS label, SUM(inv.inv_qty) AS inv_qty
    FROM indep_rl_ads.a02_e2e_product_performance_inv_summary_d inv
    CROSS JOIN __end_date d
    WHERE inv.data_date = d.end_date
    GROUP BY inv.brand
)
SELECT
    s.label,
    s.ytd_qty / (s.ytd_qty + i.inv_qty) AS ytd_st_pct
FROM __sales s
FULL OUTER JOIN __inv i ON s.label = i.label
```

- sales 侧附加渠道条件（若渠道切片器有选择）、inv 侧不附加（无渠道字段）；外部商品维度条件双表同步附加

### 7.5 vs LP 附属

- 将 7.1 / 7.2 的时间范围替换为 Last Period（Min_Last / Max_Last 表 TimeFrame_Min / TimeFrame_Max；期末时点用 Max_Last 表范围）重跑，得 LP 侧占比；差值（this − last）×10000 与 bp 列对比
- 边界对齐：任一期无数据的维度值，Power BI vs LP 显示 "-"（Value 层 BLANK）

### 7.6 交叉视图金额类附属（Cross Label / Cross PT 的 SLS Amt、EOH Amt）

```sql
SELECT
    brand AS label,
    product_type,
    SUM(net_sales_amt) AS sls_amt_cny
FROM indep_rl_ads.a02_e2e_product_performance_sales_summary_d
WHERE data_date >= '2025-06-29' AND data_date <= '2025-07-05'
    -- This Period 实际选择替换；外部切片器筛选条件同步附加
GROUP BY brand, product_type
```

- 金额附属与对应占比主指标的分子同维度同时间口径：SLS Amt 为 This Period 区间聚合（上例为 x 轴 label × 图例 product_type）；EOH Amt 为快照日单日聚合（同 7.2 取快照日后，GROUP BY 键为基数维度 + 交叉维度）；子模块四验证时将聚合键中的 brand 换为 product_type、交叉维度对应替换
- 币种对齐：SQL 结果为原始 CNY 值，Power BI 模型值 = 原始值 ÷ 当前 Currency_ExchangeRate（RMB 汇率 = 1 时直接对比）

---

## 8. 注意事项

1. **inv 表无渠道字段**：EOH Amt% / EOH Unit / Cross EOH Amt% 的分子分母及 YTD ST% 库存分母均不受渠道切片器影响；SLS Amt% / SLS Unit / YTD ST% 分子受渠道筛选影响。YTD ST% 分子分母的渠道口径不对称为模型物理限制（渠道字段仅存在于 sales 表），业务需知悉该口径影响
2. **期末时点口径**：end period 范围 [Max_This[TimeFrame_Min], Max_This[TimeFrame_Max]] 内最后一个有数据的快照日，快照缺数时自动回退到范围内最近一天；快照表按日存储只取单日，对整段区间求和会把库存重复计数；LP 侧同法取 Max_Last 表范围
3. **YTD ST% 跨双表口径**：分子（sales）为财年第一天至今的区间汇总，分母（inv）为快照日单日值，两者时间口径不同不可混用；YTD 起点 Fiscal_Year_First_Day 为 TimeFrame_Min 落入财年的第一天，财年型时间选项内 TimeFrame_Min 与 TimeFrame_Max 同属一个财年，与口径「end period 所在财年」等价
4. **Last Period 读取方式**：直接读 Min_Last / Max_Last 筛选器的 TimeFrame_Min / TimeFrame_Max（非 _LY / _LP 字段对称映射），依赖模型中 Last 表与主时间筛选器的既有关系配置
5. **ALLSELECTED 六维度机制**：行维度六选一，其余五个未上行字段的 ALLSELECTED 为无操作；ALLSELECTED 仅移除视觉对象内部筛选、保留外部切片器筛选，与 REMOVEFILTERS（连外部筛选一并移除）的语义差异是分母正确性的关键
6. **行字段必须从 Slicer_ 维度表拉取**：行筛选直接落在维度表字段上，ALLSELECTED(维度表字段) 才能正确移除；若误用事实表字段（如 sales[brand]）作行字段，维度表字段上无视觉对象内部筛选，ALLSELECTED 为无效操作，事实表字段的行筛选不被移除，占比恒 100%
7. **交叉视图度量值专用性**：Cross Label / Cross PT 度量值分别绑定对应柱形图（x 轴基数维度筛选是分母机制的组成部分）；在无基数维度筛选的上下文中复用时，分母退化为全量占比（等同主视图口径），勿跨视觉对象混用
8. **MD 空值保护**：吊牌金额（msrp_net_sales_amt）空或 0 时返回 BLANK（显示 "-"），避免 1 − BLANK() = 1（即 100% 折扣）失真
9. **vs LP 空值规则**：任一期占比为 BLANK 时差值返回 BLANK（显示 "-"），避免单侧缺失产生失真差值；×10000 转 bp 在 Display 层实现，Value 层差值保持原始小数可复用
10. **主视图总计行**：占比类总计 = 100%（分子分母同范围）、数量类总计 = 全量合计、YTD ST% / MD 总计 = 全量分子分母重算，均为汇总语义下的正确行为
11. **币种**：主视图占比 / 数量 / 比率类指标分子分母同表同币种（底表 CNY），不受币种切片器影响，无需汇率换算；交叉视图金额类附属（Cross Label / Cross PT 的 SLS Amt、EOH Amt）按 currency 口径处理——Value 层 ÷ Currency_ExchangeRate 换算为当前币种（RMB 汇率 = 1 时换算前后值相同），Display 层拼接 Currency_Symbol（`#,##0`）
12. **口径与语法**：口径文档中定义的所有指标必须遵守其数据类型与数据格式，与解决方案存在争议时一切以口径文档为准；DAX 文本常量使用双引号，单引号仅用于表名，列名使用方括号，例如：`[md_type] = "FP"`
13. **金额附属口径**：交叉视图金额类附属与对应占比主指标的分子同维度同时间口径（SLS Amt = SLS Amt% 分子，This Period 区间；EOH Amt = EOH Amt% 分子，快照日单日），仅为金额绝对值，不涉及占比分母；SLS Amt 受渠道筛选影响（sales 侧），EOH Amt 不受（inv 表无渠道字段）
