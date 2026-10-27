# Sales & Inventory Penetration Trend 表格解决方案

> **版本**: v1.2（期末时点口径调整：end period 最后一天直接取所选行 `TimeFrame_Max` / `TimeFrame_Max_LY` 单日过滤，移除「区间内最后一个有数据的快照日」回退模式；ST% 加分母空值保护。v1.1 对齐 Label_&_Product_Type_table.md 度量值写法；时间筛选器保持本模块单选日期表 Slicer_Time_Frame_Sales_Trend）
> **模块**: RL E2E Merch Dashboard - Merchandise Performance Overview Tab - Sales & Inventory Penetration Trend
> **关联口径**: 口径文档/口径Markdown格式/Sales & Inventory Penetration Trend.md - 子模块一【Sales】（§1-§9）+ 子模块二【Inventory】（§10-§20）
> **数据底表（销售类）**: a02_e2e_product_performance_sales_summary_d
> **数据底表（库存类）**: a02_e2e_product_performance_inv_summary_d
> **关联维度**: Slicer_Time_Frame_Sales_Trend（时间，单选 TimeFrame_Value，断开维度，表内预计算 LY 区间与期末日期）；Slicer_Currency_Selection（币种，断开维度）；Slicer_Label / Slicer_Super_Season / Slicer_Product_Type / Slicer_Category / Slicer_Md_Type / Slicer_Division（商品维度，行字段来源，与双事实表一对多关联）
> **参考方案**: Label_&_Product_Type_table.md（Value/Display 度量写法、ALLSELECTED 分母机制、验证 SQL 结构参考——**日期表不同，本模块不读 Min_This / Max_This / Min_Last / Max_Last**）；Merchandising_Core_KPI_ms.md（文档结构参考）
> **筛选影响范围**: 时间（断开维度，DAX 显式筛选 data_date）+ 渠道（Platform + Store Name，仅销售侧）+ 商品维度切片器（与双表已建关系，自动传递）

---

## 1. 需求理解

### 1.1 模块定位与视觉对象结构

本板块由**两张表格**（非矩阵）构成：

| 视觉对象       | 覆盖口径                           | 结构                     |
| -------------- | ---------------------------------- | ------------------------ |
| Sales 表格     | 子模块一【Sales】（§1-§9）       | 行维度六选一 + 9 列指标  |
| Inventory 表格 | 子模块二【Inventory】（§10-§20） | 行维度六选一 + 11 列指标 |

- **行**：商品维度字段六选一拉到表格（`Slicer_Label[label]` / `Slicer_Super_Season[super_season]` / `Slicer_Product_Type[product_type]` / `Slicer_Category[category]` / `Slicer_Md_Type[md_type]` / `Slicer_Division[division]`，切换时替换视觉对象行区域字段，度量值层无感知）
- **ST%（TY）/ ST%（LY）两表口径完全一致**（公式、时间口径、数据格式无差异，唯一差异是所在表格），按 Label & Product Type 模块的共享模式：**同一套度量值，两表各引用一次**
- 行字段全部取自 Slicer_ 维度表（非事实表字段）：维度表与两张事实表一对多关联，行维度筛选经模型关系自动传导到 sales 与 inv，**库存类指标无需 TREATAS 桥接**

**与矩阵方案（Merchandising Core KPI）的关键差异**：

1. 本次为**表格**而非矩阵：无 Dim_ColMetric 列路由维度、无 Amt/Unit 按钮路由、无商品标签按钮路由，**每个指标独立输出单独的 Value 度量**
2. **Display 度量仅输出数据类型为 currency 的指标**（SLS Amt TY / SLS Amt LY / EOH Amt TY / EOH Amt LY，共 4 个），其余指标（percent / integer）直接使用 Value 度量 + 度量值静态格式
3. 时间筛选器使用**单选模式** `Slicer_Time_Frame_Sales_Trend`（单选 TimeFrame_Value），LY 读**表内预计算的 `TimeFrame_Min_LY` / `TimeFrame_Max_LY`**（区别于 Merchandising Core KPI / Label & PT 的 Min_Last / Max_Last 独立筛选器模式，本模块无 last period 筛选器）
4. 六个商品维度表与两张事实表均一对多关联，行维度筛选经模型关系自动传递，无需任何 TREATAS

### 1.2 时间筛选器（单选模式）

| 项目     | 内容                                                                                                       |
| -------- | ---------------------------------------------------------------------------------------------------------- |
| 表       | `Slicer_Time_Frame_Sales_Trend`（与事实表断开维度，DAX 内以 data_date 谓词显式过滤）                     |
| 选择方式 | **单选模式**：在对应时间粒度下单选 `TimeFrame_Value` 字段值，如 Month 粒度下选 `2027-04`         |
| 支持粒度 | Week / Month / Year（Day / Quarter 已在 Power Query 层过滤）                                               |
| TY 区间  | 所选行`TimeFrame_Min` / `TimeFrame_Max`（单选下即一个完整时间单位）                                    |
| LY 区间  | 所选行`TimeFrame_Min_LY` / `TimeFrame_Max_LY`（**日期表预计算的去年同期区间，直接读取**）        |
| 期末日期 | 所选行`TimeFrame_Max`（end period 最后一天；LY 库存类 = `TimeFrame_Max_LY`）                           |
| YOY 基准 | 今年 / 去年 - 1，即 TY / LY 同期对比（LY 取日期表预计算区间）                                              |
| 单选语义 | Min / Max / LY 字段同属所选行，同现同缺；未选择时 SELECTEDVALUE 返回 BLANK，度量返回 BLANK（显示空 / "-"） |

### 1.3 时间口径

| 口径                      | 时间范围                                                              | 适用指标                                                                         |
| ------------------------- | --------------------------------------------------------------------- | -------------------------------------------------------------------------------- |
| This Period 区间（TY）    | data_date ∈ [TimeFrame_Min, TimeFrame_Max]                           | SLS Unit（TY）、SLS Amt（TY）、SLS Amt% 分子分母、ST%（TY）分子                  |
| LY 区间                   | data_date ∈ [TimeFrame_Min_LY, TimeFrame_Max_LY]                     | SLS Unit（LY）、SLS Amt（LY）、ST%（LY）分子                                     |
| End Period 期末时点（TY） | **所选行 TimeFrame_Max**（end period 最后一天，单日时点）       | EOH Amt%（分子分母）、EOH Unit / Amt（TY）、In-transit Unit（TY）、ST%（TY）分母 |
| End Period 期末时点（LY） | **所选行 TimeFrame_Max_LY**（LY end period 最后一天，单日时点） | EOH Unit（LY）、EOH Amt（LY）、In-transit Unit（LY）                             |
| ST%（LY）分母             | **当前所选行 TimeFrame_Max**（非 LY 期末，口径原文如此）        | ST%（LY）期末库存金额                                                            |
| YOY                       | TY 值 / LY 值 - 1                                                     | SLS Amt YOY、SLS Unit YOY、EOH Amt YOY、EOH Unit YOY                             |

说明：

- 单选模式下所选区间即一个完整时间单位（如 Month 2027-04 → [2027-04-01, 2027-04-30]），**「end period 最后一天」= 所选行 `TimeFrame_Max`**（日期表预计算），度量直接单日过滤（v1.2 调整，原「区间内最后一个有数据的快照日」回退模式移除，见注意事项 3）；快照表按日存储只取单日，对整段区间求和会重复计数库存
- ST%（LY）为**混合口径**：分子（LY 销售）取去年同期区间，分母（期末库存金额）取**当前** end period 最后一天——原始口径明文如此定义（口径文档 §7 / §18 已标注"需业务确认"）

### 1.4 币种口径

- 占比 / 比率 / 数量类指标（SLS Amt% / EOH Amt% / ST% / YOY / SLS Unit / EOH Unit / In-transit Unit）不涉及金额展示，无需币种换算：占比分子分母为同表同币种金额字段（底表金额均存储 CNY），换算与否比值不变
- currency 类 4 个指标（SLS Amt TY / LY、EOH Amt TY / LY）：货币符号由币种切片器（Slicer_Currency_Selection）决定，千分位整数；数据底表金额仅存储 CNY，**Value 层完成汇率换算**（原始值 ÷ Currency_ExchangeRate，RMB 汇率 = 1 时换算前后值相同），**Display 层仅拼接币种符号**

### 1.5 指标清单

**Sales 表（9 列）**：SLS Amt%、SLS Unit（TY）、SLS Amt（TY）、ST%（TY）、SLS Unit（LY）、SLS Amt（LY）、ST%（LY）、SLS Amt YOY、SLS Unit YOY

**Inventory 表（11 列）**：EOH Amt%、EOH Unit（TY）、EOH Amt（TY）、In-transit Unit（TY）、ST%（TY）、EOH Unit（LY）、EOH Amt（LY）、In-transit Unit（LY）、ST%（LY）、EOH Amt YOY、EOH Unit YOY

---

## 2. 现状分析

- 数据底表 `a02_e2e_product_performance_sales_summary_d`（日粒度）：net_sales_amt（净销售金额）、net_sales_qty（净销售数量）；维度含 platform、shop_name 及 brand / super_season / product_type / category / md_type / division / framework / ax_class 等全部商品维度；日期字段为 data_date（date 类型）；platform 已在数据源层过滤 IN ('JD','TM','RLE','DY')
- 数据底表 `a02_e2e_product_performance_inv_summary_d`（日快照）：msrp_inv_amt（库存吊牌价金额，期末库存金额口径）、inv_qty（库存数量）、msrp_in_trans_inv_amt（在途库存吊牌价金额）、in_trans_inv_qty（在途库存数量）；商品维度字段与 sales 表同名同构；**无 platform / shop_name 字段**（渠道筛选不影响库存侧指标）；日期字段为 data_date（date 类型）
- 模型关系：Slicer_Label（值域 = sales 表 brand distinct，label 字段）/ Slicer_Super_Season / Slicer_Product_Type / Slicer_Category / Slicer_Md_Type / Slicer_Division 商品维度表与两张事实表均一对多关联，筛选自动传递双表；Slicer_Platform_Selection、Slicer_Store_Name 与 sales 表一对多关联；**日期筛选器（Slicer_Time_Frame_Sales_Trend）为断开维度，时间范围在 DAX 中显式筛选**；Slicer_Currency_Selection 为断开维度
- Slicer_Time_Frame_Sales_Trend（新增单选日期表）：TimeFrame_ID / TimeFrame_Value（单选字段）/ TimeFrame_Min / TimeFrame_Max（TY 区间与期末日期）/ TimeFrame_Min_LY / TimeFrame_Max_LY（LY 区间与 LY 期末日期，表内预计算）等字段齐全，计算 LY 与 YOY 直接读取预计算日期值范围
- 口径中 "label" 维度对应事实表字段 `brand`（Slicer_Label 表 [label] 字段由 `select distinct brand as label` 生成，数据字典已由 label 统一更新为 brand）
- 字段名已逐一核对数据字典（msrp_inv_amt / inv_qty / msrp_in_trans_inv_amt / in_trans_inv_qty 等）

---

## 3. 方案设计

### 3.1 度量值分层

```
Value（口径计算）
←  单选时间筛选器日期范围（TY 区间 / LY 区间 / 期末最后一天 TimeFrame_Max / LY 期末最后一天 TimeFrame_Max_LY）显式筛选 data_date
←  维度表 1:N 关联自然传递行 / 切片器筛选（无需 TREATAS）
←  SLS Amt% / EOH Amt% 分母：ALLSELECTED 六个商品维度表字段（移除行维度筛选，保留外部切片器）
←  currency 4 个 Value 层完成币种汇率换算（原始 CNY ÷ Currency_ExchangeRate）
↓
YOY Value（比率）
←  TY Value / LY Value - 1；LY 空或 0 时返回 BLANK
↓
Display（仅 currency 类，格式化显示）
←  币种符号 & FORMAT(#,##0)；BLANK 显示 "-"
```

其余（percent_0dp / integer）不建 Display 度量，直接使用 Value 度量 + 度量值静态格式（`#,##0%` / `#,##0`）。

### 3.2 指标口径清单

| #  | 表格      | 指标（口径§）                | 度量值名称                             | 数据底表    | 时间口径                                        | 计算公式                                                             | 数据类型    | 数据格式            | 输出            |
| -- | --------- | ----------------------------- | -------------------------------------- | ----------- | ----------------------------------------------- | -------------------------------------------------------------------- | ----------- | ------------------- | --------------- |
| 1  | Sales     | SLS Amt%（§1）               | S&I Sales SLS Amt% Value               | sales       | TY 区间                                         | 分子 sum(net_sales_amt) / 分母 ALLSELECTED 六维度 sum(net_sales_amt) | percent_0dp | `#,##0%`          | Value           |
| 2  | Sales     | SLS Unit（TY）（§2）         | S&I Sales SLS Unit TY Value            | sales       | TY 区间                                         | sum(net_sales_qty)                                                   | integer     | `#,##0`           | Value           |
| 3  | Sales     | SLS Amt（TY）（§3）          | S&I Sales SLS Amt TY Value             | sales       | TY 区间                                         | sum(net_sales_amt)                                                   | currency    | 币种符号 +`#,##0` | Value + Display |
| 4  | 两表共享  | ST%（TY）（§4 / §14）       | S&I ST% TY Value                       | sales + inv | 分子 TY 区间 / 分母当前 TimeFrame_Max           | sales.net_sales_amt / (sales.net_sales_amt + inv.msrp_inv_amt)       | percent_0dp | `#,##0%`          | Value           |
| 5  | Sales     | SLS Unit（LY）（§5）         | S&I Sales SLS Unit LY Value            | sales       | LY 区间                                         | sum(net_sales_qty)                                                   | integer     | `#,##0`           | Value           |
| 6  | Sales     | SLS Amt（LY）（§6）          | S&I Sales SLS Amt LY Value             | sales       | LY 区间                                         | sum(net_sales_amt)                                                   | currency    | 币种符号 +`#,##0` | Value + Display |
| 7  | 两表共享  | ST%（LY）（§7 / §18）       | S&I ST% LY Value                       | sales + inv | 分子 LY 区间 / 分母**当前** TimeFrame_Max | LY sales.net_sales_amt / (LY sales.net_sales_amt + inv.msrp_inv_amt) | percent_0dp | `#,##0%`          | Value           |
| 8  | Sales     | SLS Amt YOY（§8）            | S&I Sales SLS Amt YOY Value            | sales       | TY / LY                                         | TY / LY - 1                                                          | percent_0dp | `#,##0%`          | Value           |
| 9  | Sales     | SLS Unit YOY（§9）           | S&I Sales SLS Unit YOY Value           | sales       | TY / LY                                         | TY / LY - 1                                                          | percent_0dp | `#,##0%`          | Value           |
| 10 | Inventory | EOH Amt%（§10）              | S&I Inventory EOH Amt% Value           | inv         | 当前 TimeFrame_Max（期末最后一天）              | 分子 sum(msrp_inv_amt) / 分母 ALLSELECTED 六维度 sum(msrp_inv_amt)   | percent_0dp | `#,##0%`          | Value           |
| 11 | Inventory | EOH Unit（TY）（§11）        | S&I Inventory EOH Unit TY Value        | inv         | 当前 TimeFrame_Max（期末最后一天）              | sum(inv_qty)                                                         | integer     | `#,##0`           | Value           |
| 12 | Inventory | EOH Amt（TY）（§12）         | S&I Inventory EOH Amt TY Value         | inv         | 当前 TimeFrame_Max（期末最后一天）              | sum(msrp_inv_amt)                                                    | currency    | 币种符号 +`#,##0` | Value + Display |
| 13 | Inventory | In-transit Unit（TY）（§13） | S&I Inventory In-transit Unit TY Value | inv         | 当前 TimeFrame_Max（期末最后一天）              | sum(in_trans_inv_qty)                                                | integer     | `#,##0`           | Value           |
| 14 | Inventory | EOH Unit（LY）（§15）        | S&I Inventory EOH Unit LY Value        | inv         | LY TimeFrame_Max_LY（LY 期末最后一天）          | sum(inv_qty)                                                         | integer     | `#,##0`           | Value           |
| 15 | Inventory | EOH Amt（LY）（§16）         | S&I Inventory EOH Amt LY Value         | inv         | LY TimeFrame_Max_LY（LY 期末最后一天）          | sum(msrp_inv_amt)                                                    | currency    | 币种符号 +`#,##0` | Value + Display |
| 16 | Inventory | In-transit Unit（LY）（§17） | S&I Inventory In-transit Unit LY Value | inv         | LY TimeFrame_Max_LY（LY 期末最后一天）          | sum(in_trans_inv_qty)                                                | integer     | `#,##0`           | Value           |
| 17 | Inventory | EOH Amt YOY（§19）           | S&I Inventory EOH Amt YOY Value        | inv         | TY / LY                                         | TY / LY - 1（金额口径）                                              | percent_0dp | `#,##0%`          | Value           |
| 18 | Inventory | EOH Unit YOY（§20）          | S&I Inventory EOH Unit YOY Value       | inv         | TY / LY                                         | TY / LY - 1（数量口径）                                              | percent_0dp | `#,##0%`          | Value           |

注：ST%（TY）/ ST%（LY）为两表共享度量（§4 与 §14、§7 与 §18 口径完全一致，Label & Product Type 模块同款共享模式）；共享度量不带 Sales / Inventory 子模块前缀。指标度量合计 18 Value + 4 Display = 22 个；另有 2 个辅助文本度量（当前 TY / LY 时间值显示，见 §4.23 / §4.24），合计 24 个。

### 3.3 占比分母机制（ALLSELECTED 六维度，SLS Amt% / EOH Amt%）

口径「单品类占总品类的比例」的分母 = 外部筛选上下文下的全量合计：

- 分母对六个商品维度表**字段**同时应用 `ALLSELECTED`（列级写法，与 Label & PT / Sales Performance Details 模块一致）：行维度当前字段（六选一）的视觉对象内部行筛选被移除，恢复为外部切片器筛选状态；其余五个未上行字段的 ALLSELECTED 为无操作（其上仅有外部切片器筛选，保留不变）
- **ALLSELECTED 与 REMOVEFILTERS 的差异是本方案的关键**：REMOVEFILTERS 会移除该列全部筛选（含外部切片器），导致分母脱离业务筛选条件；ALLSELECTED 仅移除视觉对象内部的行筛选，保留外部切片器筛选，分母始终是「外部筛选下」的全量合计
- 行字段从 Slicer_ 维度表拉取，行筛选直接落在维度表字段上，ALLSELECTED 作用于维度表字段即可正确移除；移除后经一对多关系向双事实表正向传导，分母聚合范围自动恢复全量（外部筛选下）
- **一次只有一个字段在表格行上，其余五个字段的 ALLSELECTED 为无操作**——无论行字段切换到哪个维度，**一个度量即可实现对所有商品维度的统计**，无需按维度各建一套占比度量

```dax
ALLSELECTED('Slicer_Label'[label]),
ALLSELECTED('Slicer_Super_Season'[super_season]),
ALLSELECTED('Slicer_Product_Type'[product_type]),
ALLSELECTED('Slicer_Category'[category]),
ALLSELECTED('Slicer_Md_Type'[md_type]),
ALLSELECTED('Slicer_Division'[division])
```

### 3.4 时间口径实现（单选模式）

- TY 区间 / LY 区间：`SELECTEDVALUE(Slicer_Time_Frame_Sales_Trend[TimeFrame_Min / TimeFrame_Max / TimeFrame_Min_LY / TimeFrame_Max_LY])` 取所选行日期值，以 `data_date >= __Min && data_date <= __Max` 谓词显式过滤事实表
- 期末日期（end period 最后一天）：**直接取所选行 `TimeFrame_Max`**，以 `inv[data_date] = __EndPeriodDate` 单日过滤（LY 库存类 = `TimeFrame_Max_LY`）——单选下所选区间即一个完整时间单位，TimeFrame_Max 即其最后一天；语义贴合口径原文、免全表扫描（v1.2 调整，原「区间内最后一个有数据的快照日」回退模式移除，见注意事项 3）
- ST%（LY）分母：分子（LY 销售）读 `TimeFrame_Min_LY / TimeFrame_Max_LY` 区间，分母（期末库存）读**当前** `TimeFrame_Max`（口径原文如此，需业务确认）

### 3.5 度量值命名与组织

- 命名规则：模块前缀 `S&I`（Sales & Inventory）+ 子模块前缀 `Sales` / `Inventory`（两表共享的 ST% 不带子模块前缀）+ 指标名 + 层次后缀（Value / Display）
- Display Folder：`Sales & Inventory Penetration Trend\Base Metrics`（Value 层）与 `Sales & Inventory Penetration Trend\Formatting`（Display 层）
- 度量值统一存放于 `_Measures` 隐藏表

---

## 4. 度量值实现

### 4.1 S&I Sales SLS Amt% Value（销售金额占比）

```dax
S&I Sales SLS Amt% Value =
// ========================================
// 度量值: S&I Sales SLS Amt% Value
// 中文名: 销售金额占比
// Display Folder: Sales & Inventory Penetration Trend\Base Metrics
// 用途: 当前行商品维度值占 total 的销售金额比例（单品类占总品类的比例），
//       Sales 表六维度行切换共享
// 依赖: Slicer_Time_Frame_Sales_Trend[TimeFrame_Min] / [TimeFrame_Max]（单选 TimeFrame_Value 所选行）
// 口径: 口径文档 Sales & Inventory Penetration Trend.md §1；时间范围看 this period；
//       分子：各维度值下 sum(net_sales_amt)；分母：sum(net_sales_amt)（占 total 比例）
// 数据底表: a02_e2e_product_performance_sales_summary_d
// 分母机制: ALLSELECTED 六个商品维度表字段——移除视觉对象内部的行维度筛选，
//       保留外部切片器筛选；一次只有一个字段在行上，其余五个字段为无操作，
//       实现六维度切换一套逻辑通吃；行字段来自维度表，移除后经一对多关系
//       向事实表正向传导，分母恢复全量（外部筛选下）
// 币种: 分子分母为同表同币种金额（底表 CNY），占比不受币种选择影响
// 数据类型: percent_0dp；数据格式: #,##0%（不含正号，度量值静态格式）
// ========================================

// ── This Period 时间区间（单选 TimeFrame_Value 所选行）──
VAR __PeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Sales_Trend[TimeFrame_Min])
VAR __PeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Sales_Trend[TimeFrame_Max])

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

### 4.2 S&I Sales SLS Unit TY Value（净销售数量 TY）

```dax
S&I Sales SLS Unit TY Value =
// ========================================
// 度量值: S&I Sales SLS Unit TY Value
// 中文名: DCom净销售数量（TY）
// Display Folder: Sales & Inventory Penetration Trend\Base Metrics
// 用途: 统计周期内 DCom净销售数量 = DCom销售订单总销售数量 - 退货数量，Sales 表六维度行切换共享
// 依赖: Slicer_Time_Frame_Sales_Trend[TimeFrame_Min] / [TimeFrame_Max]
// 口径: 口径文档 Sales & Inventory Penetration Trend.md §2；时间范围看 this period；
//       sum(net_sales_qty)
// 数据底表: a02_e2e_product_performance_sales_summary_d
// 说明: 数量类指标，不涉及币种换算；受渠道筛选影响（sales 侧）
// 数据类型: integer；数据格式: #,##0（千分位整数，度量值静态格式）
// ========================================

// ── This Period 时间区间 ──
VAR __PeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Sales_Trend[TimeFrame_Min])
VAR __PeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Sales_Trend[TimeFrame_Max])

RETURN
    CALCULATE(
        SUM('a02_e2e_product_performance_sales_summary_d'[net_sales_qty]),
        'a02_e2e_product_performance_sales_summary_d'[data_date] >= __PeriodMin,
        'a02_e2e_product_performance_sales_summary_d'[data_date] <= __PeriodMax
    )
```

### 4.3 S&I Sales SLS Amt TY Value（净销售额 TY，当前币种）

```dax
S&I Sales SLS Amt TY Value =
// ========================================
// 度量值: S&I Sales SLS Amt TY Value
// 中文名: DCom净销售额（TY，当前币种）
// Display Folder: Sales & Inventory Penetration Trend\Base Metrics
// 用途: 统计周期内 DCom净销售额 = DCom销售订单总销售额 - 退货额，Sales 表六维度行切换共享
// 依赖: Slicer_Time_Frame_Sales_Trend[TimeFrame_Min] / [TimeFrame_Max]，
//       Slicer_Currency_Selection[Currency_ExchangeRate]
// 口径: 口径文档 Sales & Inventory Penetration Trend.md §3；时间范围看 this period；
//       sum(net_sales_amt)
// 数据底表: a02_e2e_product_performance_sales_summary_d
// 币种: 数据底表仅存 CNY，Value 层换算为当前币种金额（原始值 ÷ 汇率）；
//       RMB 汇率 = 1 时换算前后值相同；Display 层仅拼接币种符号
// 数据类型: currency；数据格式: #,##0（货币符号由币种切片器决定）
// ========================================

// ── This Period 时间区间 ──
VAR __PeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Sales_Trend[TimeFrame_Min])
VAR __PeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Sales_Trend[TimeFrame_Max])

// ── 币种汇率（RMB = 1；USD 动态取自数仓汇率表）──
VAR __ExchangeRate = SELECTEDVALUE(Slicer_Currency_Selection[Currency_ExchangeRate], 1)

// ── This Period 净销售金额（原始 CNY，行上下文自动筛选）──
VAR __BaseValue =
    CALCULATE(
        SUM('a02_e2e_product_performance_sales_summary_d'[net_sales_amt]),
        'a02_e2e_product_performance_sales_summary_d'[data_date] >= __PeriodMin,
        'a02_e2e_product_performance_sales_summary_d'[data_date] <= __PeriodMax
    )

RETURN
    DIVIDE(__BaseValue, __ExchangeRate)   // BLANK ÷ 汇率 = BLANK（当期无销售数据返回空）
```

### 4.4 S&I Sales SLS Amt TY Display（净销售额 TY 显示）

```dax
S&I Sales SLS Amt TY Display =
// ========================================
// 度量值: S&I Sales SLS Amt TY Display
// 中文名: DCom净销售额（TY）显示
// Display Folder: Sales & Inventory Penetration Trend\Formatting
// 用途: currency 格式化（币种符号 + 千分位整数，符号由币种切片器决定）；BLANK 显示 "-"
// 依赖: [S&I Sales SLS Amt TY Value]（已完成汇率换算）、
//       Slicer_Currency_Selection[Currency_Symbol]
// 数据格式: 币种符号 & #,##0（如 ¥1,000 / $1,000）
// ========================================
    VAR __Value = [S&I Sales SLS Amt TY Value]
    VAR __CurrencySymbol = SELECTEDVALUE(Slicer_Currency_Selection[Currency_Symbol], "¥")
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            __CurrencySymbol & FORMAT(__Value, "#,##0")
        )
```

### 4.5 S&I ST% TY Value（售罄率%金额 TY，两表共享）

```dax
S&I ST% TY Value =
// ========================================
// 度量值: S&I ST% TY Value
// 中文名: 售罄率%（金额，TY）
// Display Folder: Sales & Inventory Penetration Trend\Base Metrics
// 用途: 统计周期内销售金额 /（销售金额 + 期末库存金额）× 100%，
//       Sales 表与 Inventory 表共享（§4 与 §14 口径完全一致，两表各引用一次）
// 依赖: Slicer_Time_Frame_Sales_Trend[TimeFrame_Min] / [TimeFrame_Max]
// 口径: 口径文档 Sales & Inventory Penetration Trend.md §4 / §14；
//       销售金额：看所选时间范围销售金额之和；期末库存金额：看所选时间范围
//       end period 最后一天（= 所选行 TimeFrame_Max，直接单日过滤）；
//       sales.net_sales_amt / (sales.net_sales_amt + inv.msrp_inv_amt)
// 数据底表: a02_e2e_product_performance_sales_summary_d（sales）；
//           a02_e2e_product_performance_inv_summary_d（inv）
// 说明: 跨双表时间口径不同——分子为区间汇总，分母为期末单日值，不可混用；
//       行维度经维度表关系自动传导双表；分子（sales 侧）受渠道筛选影响，
//       分母（inv 侧）不受渠道筛选影响（inv 表无渠道字段）
// 边界保护: 期末库存缺失（所选 TimeFrame_Max 当日快照未产出，如进行中的时间单位）时
//       返回 BLANK，避免 DIVIDE(SLS, SLS + BLANK) = 100% 失真
// 数据类型: percent_0dp；数据格式: #,##0%（不含正号，度量值静态格式）
// ========================================

// ── This Period 时间区间 ──
VAR __PeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Sales_Trend[TimeFrame_Min])
VAR __PeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Sales_Trend[TimeFrame_Max])

// ── 期末日期：所选时间范围 end period 最后一天 = 所选行 TimeFrame_Max ──
VAR __EndPeriodDate = SELECTEDVALUE(Slicer_Time_Frame_Sales_Trend[TimeFrame_Max])

// ── 分子：This Period 区间净销售金额（sales 表）──
VAR __SLSAmt =
    CALCULATE(
        SUM('a02_e2e_product_performance_sales_summary_d'[net_sales_amt]),
        'a02_e2e_product_performance_sales_summary_d'[data_date] >= __PeriodMin,
        'a02_e2e_product_performance_sales_summary_d'[data_date] <= __PeriodMax
    )

// ── 库存加项：期末库存金额（期末单日值，inv 表）──
VAR __InvAmt =
    CALCULATE(
        SUM('a02_e2e_product_performance_inv_summary_d'[msrp_inv_amt]),
        'a02_e2e_product_performance_inv_summary_d'[data_date] = __EndPeriodDate
    )

RETURN
    IF(
        ISBLANK(__InvAmt),
        BLANK(),
        DIVIDE(__SLSAmt, __SLSAmt + __InvAmt)
    )
```

### 4.6 S&I Sales SLS Unit LY Value（净销售数量 LY）

```dax
S&I Sales SLS Unit LY Value =
// ========================================
// 度量值: S&I Sales SLS Unit LY Value
// 中文名: DCom净销售数量（LY）
// Display Folder: Sales & Inventory Penetration Trend\Base Metrics
// 用途: 去年同期 DCom净销售数量，Sales 表六维度行切换共享
// 依赖: Slicer_Time_Frame_Sales_Trend[TimeFrame_Min_LY] / [TimeFrame_Max_LY]
//       （单选所选行表内预计算 LY 区间，非 Min_Last / Max_Last 筛选器）
// 口径: 口径文档 Sales & Inventory Penetration Trend.md §5；看所选时间范围去年同期；
//       sum(net_sales_qty)
// 数据底表: a02_e2e_product_performance_sales_summary_d
// 说明: 数量类指标，不涉及币种换算；受渠道筛选影响（sales 侧）
// 数据类型: integer；数据格式: #,##0（千分位整数，度量值静态格式）
// ========================================

// ── LY 时间区间（日期表预计算去年同期）──
VAR __PeriodMinLY = SELECTEDVALUE(Slicer_Time_Frame_Sales_Trend[TimeFrame_Min_LY])
VAR __PeriodMaxLY = SELECTEDVALUE(Slicer_Time_Frame_Sales_Trend[TimeFrame_Max_LY])

RETURN
    CALCULATE(
        SUM('a02_e2e_product_performance_sales_summary_d'[net_sales_qty]),
        'a02_e2e_product_performance_sales_summary_d'[data_date] >= __PeriodMinLY,
        'a02_e2e_product_performance_sales_summary_d'[data_date] <= __PeriodMaxLY
    )
```

### 4.7 S&I Sales SLS Amt LY Value（净销售额 LY，当前币种）

```dax
S&I Sales SLS Amt LY Value =
// ========================================
// 度量值: S&I Sales SLS Amt LY Value
// 中文名: DCom净销售额（LY，当前币种）
// Display Folder: Sales & Inventory Penetration Trend\Base Metrics
// 用途: 去年同期 DCom净销售额，Sales 表六维度行切换共享
// 依赖: Slicer_Time_Frame_Sales_Trend[TimeFrame_Min_LY] / [TimeFrame_Max_LY]，
//       Slicer_Currency_Selection[Currency_ExchangeRate]
// 口径: 口径文档 Sales & Inventory Penetration Trend.md §6；看所选时间范围去年同期；
//       sum(net_sales_amt)
// 数据底表: a02_e2e_product_performance_sales_summary_d
// 币种: 数据底表仅存 CNY，Value 层换算为当前币种金额（原始值 ÷ 汇率）
// 数据类型: currency；数据格式: #,##0（货币符号由币种切片器决定）
// ========================================

// ── LY 时间区间（日期表预计算去年同期）──
VAR __PeriodMinLY = SELECTEDVALUE(Slicer_Time_Frame_Sales_Trend[TimeFrame_Min_LY])
VAR __PeriodMaxLY = SELECTEDVALUE(Slicer_Time_Frame_Sales_Trend[TimeFrame_Max_LY])

// ── 币种汇率（RMB = 1；USD 动态取自数仓汇率表）──
VAR __ExchangeRate = SELECTEDVALUE(Slicer_Currency_Selection[Currency_ExchangeRate], 1)

// ── LY 区间净销售金额（原始 CNY）──
VAR __BaseValue =
    CALCULATE(
        SUM('a02_e2e_product_performance_sales_summary_d'[net_sales_amt]),
        'a02_e2e_product_performance_sales_summary_d'[data_date] >= __PeriodMinLY,
        'a02_e2e_product_performance_sales_summary_d'[data_date] <= __PeriodMaxLY
    )

RETURN
    DIVIDE(__BaseValue, __ExchangeRate)   // BLANK ÷ 汇率 = BLANK（LY 无销售数据返回空）
```

### 4.8 S&I Sales SLS Amt LY Display（净销售额 LY 显示）

```dax
S&I Sales SLS Amt LY Display =
// ========================================
// 度量值: S&I Sales SLS Amt LY Display
// 中文名: DCom净销售额（LY）显示
// Display Folder: Sales & Inventory Penetration Trend\Formatting
// 用途: currency 格式化（币种符号 + 千分位整数，符号由币种切片器决定）；BLANK 显示 "-"
// 依赖: [S&I Sales SLS Amt LY Value]（已完成汇率换算）、
//       Slicer_Currency_Selection[Currency_Symbol]
// 数据格式: 币种符号 & #,##0（如 ¥1,000 / $1,000）
// ========================================
    VAR __Value = [S&I Sales SLS Amt LY Value]
    VAR __CurrencySymbol = SELECTEDVALUE(Slicer_Currency_Selection[Currency_Symbol], "¥")
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            __CurrencySymbol & FORMAT(__Value, "#,##0")
        )
```

### 4.9 S&I ST% LY Value（售罄率%金额 LY，两表共享）

```dax
S&I ST% LY Value =
// ========================================
// 度量值: S&I ST% LY Value
// 中文名: 售罄率%（金额，LY）
// Display Folder: Sales & Inventory Penetration Trend\Base Metrics
// 用途: 去年同期售罄率，Sales 表与 Inventory 表共享（§7 与 §18 口径完全一致）
// 依赖: Slicer_Time_Frame_Sales_Trend[TimeFrame_Min_LY / TimeFrame_Max_LY /
//       TimeFrame_Max]
// 口径: 口径文档 Sales & Inventory Penetration Trend.md §7 / §18；
//       销售金额：看所选时间范围去年同期销售金额之和；
//       期末库存金额：看所选时间范围 end period 最后一天（【当前】所选行 TimeFrame_Max，
//       非 LY 期末）；sales.net_sales_amt / (sales.net_sales_amt + inv.msrp_inv_amt)
// 特殊说明: 分子分母时间基准不对称为原始口径明文定义（口径文档已标注需业务确认），
//           DAX 按口径原文实现；若业务确认应为 LY 期末，仅需将 __InvAmt 的
//           __EndPeriodDate 换为 TimeFrame_Max_LY
// 边界保护: 期末库存缺失（当前 TimeFrame_Max 当日快照未产出）时返回 BLANK，
//           避免 DIVIDE(SLS, SLS + BLANK) = 100% 失真
// 数据底表: a02_e2e_product_performance_sales_summary_d（sales）；
//           a02_e2e_product_performance_inv_summary_d（inv）
// 数据类型: percent_0dp；数据格式: #,##0%（不含正号，度量值静态格式）
// ========================================

// ── LY 时间区间（日期表预计算去年同期）──
VAR __PeriodMinLY = SELECTEDVALUE(Slicer_Time_Frame_Sales_Trend[TimeFrame_Min_LY])
VAR __PeriodMaxLY = SELECTEDVALUE(Slicer_Time_Frame_Sales_Trend[TimeFrame_Max_LY])

// ── 期末日期：当前所选时间范围 end period 最后一天 = 当前所选行 TimeFrame_Max ──
VAR __EndPeriodDate = SELECTEDVALUE(Slicer_Time_Frame_Sales_Trend[TimeFrame_Max])

// ── 分子：LY 区间净销售金额（去年同期，sales 表）──
VAR __SLSAmtLY =
    CALCULATE(
        SUM('a02_e2e_product_performance_sales_summary_d'[net_sales_amt]),
        'a02_e2e_product_performance_sales_summary_d'[data_date] >= __PeriodMinLY,
        'a02_e2e_product_performance_sales_summary_d'[data_date] <= __PeriodMaxLY
    )

// ── 库存加项：期末库存金额（当前期末单日值，inv 表）──
VAR __InvAmt =
    CALCULATE(
        SUM('a02_e2e_product_performance_inv_summary_d'[msrp_inv_amt]),
        'a02_e2e_product_performance_inv_summary_d'[data_date] = __EndPeriodDate
    )

RETURN
    IF(
        ISBLANK(__InvAmt),
        BLANK(),
        DIVIDE(__SLSAmtLY, __SLSAmtLY + __InvAmt)
    )
```

### 4.10 S&I Sales SLS Amt YOY Value（净销售额 YOY）

```dax
S&I Sales SLS Amt YOY Value =
// ========================================
// 度量值: S&I Sales SLS Amt YOY Value
// 中文名: DCom净销售额 YOY
// Display Folder: Sales & Inventory Penetration Trend\Base Metrics
// 用途: 今年 / 去年 - 1（净销售额同比）
// 依赖: [S&I Sales SLS Amt TY Value]、[S&I Sales SLS Amt LY Value]
// 口径: 口径文档 Sales & Inventory Penetration Trend.md §8（今年/去年-1）；
//       「去年」按日期表预计算 LY 区间（去年同期）
// 边界: LY 空或 0 时返回 BLANK（避免 DIVIDE 结果 BLANK - 1 = -100% 失真）
// 币种: TY / LY 均为同汇率换算后数值，比率不受币种选择影响
// 数据类型: percent_0dp；数据格式: #,##0%（不含正号，负值自动带负号）
// ========================================
    VAR __TY = [S&I Sales SLS Amt TY Value]
    VAR __LY = [S&I Sales SLS Amt LY Value]

    RETURN
        IF(
            ISBLANK(__LY) || __LY = 0,
            BLANK(),
            DIVIDE(__TY, __LY) - 1
        )
```

### 4.11 S&I Sales SLS Unit YOY Value（净销售数量 YOY）

```dax
S&I Sales SLS Unit YOY Value =
// ========================================
// 度量值: S&I Sales SLS Unit YOY Value
// 中文名: DCom净销售数量 YOY
// Display Folder: Sales & Inventory Penetration Trend\Base Metrics
// 用途: 今年 / 去年 - 1（净销售数量同比）
// 依赖: [S&I Sales SLS Unit TY Value]、[S&I Sales SLS Unit LY Value]
// 口径: 口径文档 Sales & Inventory Penetration Trend.md §9（今年/去年-1）
// 边界: LY 空或 0 时返回 BLANK
// 数据类型: percent_0dp；数据格式: #,##0%（不含正号，负值自动带负号）
// ========================================
    VAR __TY = [S&I Sales SLS Unit TY Value]
    VAR __LY = [S&I Sales SLS Unit LY Value]

    RETURN
        IF(
            ISBLANK(__LY) || __LY = 0,
            BLANK(),
            DIVIDE(__TY, __LY) - 1
        )
```

### 4.12 S&I Inventory EOH Amt% Value（期末库存金额占比）

```dax
S&I Inventory EOH Amt% Value =
// ========================================
// 度量值: S&I Inventory EOH Amt% Value
// 中文名: 期末库存金额占比
// Display Folder: Sales & Inventory Penetration Trend\Base Metrics
// 用途: 根据所筛选维度统计对应 EOH amt 占比（当前行维度值占 total），
//       Inventory 表六维度行切换共享
// 依赖: Slicer_Time_Frame_Sales_Trend[TimeFrame_Max]
//       （所选行 end period 最后一天，直接单日过滤）
// 口径: 口径文档 Sales & Inventory Penetration Trend.md §10；时间范围看 this period
//       end period 最后一天（= 所选行 TimeFrame_Max）；
//       分子：各维度值下 sum(msrp_inv_amt)；分母：sum(msrp_inv_amt)（占 total 比例）
// 数据底表: a02_e2e_product_performance_inv_summary_d
// 期末机制: 期末日期直接取所选行 TimeFrame_Max 单日过滤（v1.2 调整，
//       原「区间内最后一个有数据的快照日」回退模式移除，见注意事项 3）
// 分母机制: ALLSELECTED 六个商品维度表字段（同 SLS Amt%），行筛选经维度表
//       关系自动传导 inv 表，移除后分母恢复全量（外部筛选下）
// 说明: inv 表无 platform / shop_name 字段，本指标分子分母均不受渠道筛选影响；
//       期末时点只取单日，对区间求和会重复计数库存
// 数据类型: percent_0dp；数据格式: #,##0%（不含正号，度量值静态格式）
// ========================================

// ── 期末日期：所选时间范围 end period 最后一天 = 所选行 TimeFrame_Max ──
VAR __EndPeriodDate = SELECTEDVALUE(Slicer_Time_Frame_Sales_Trend[TimeFrame_Max])

// ── 分子：当前行维度值期末库存金额（期末单日值）──
VAR __Numerator =
    CALCULATE(
        SUM('a02_e2e_product_performance_inv_summary_d'[msrp_inv_amt]),
        'a02_e2e_product_performance_inv_summary_d'[data_date] = __EndPeriodDate
    )

// ── 分母：外部筛选上下文下的全量期末库存金额（ALLSELECTED 六维度，期末单日）──
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

### 4.13 S&I Inventory EOH Unit TY Value（期末库存数量 TY）

```dax
S&I Inventory EOH Unit TY Value =
// ========================================
// 度量值: S&I Inventory EOH Unit TY Value
// 中文名: 期末库存数量（TY）
// Display Folder: Sales & Inventory Penetration Trend\Base Metrics
// 用途: 选定日期业务周期结束时点的期末库存总数量，Inventory 表六维度行切换共享
// 依赖: Slicer_Time_Frame_Sales_Trend[TimeFrame_Max]
//       （所选行 end period 最后一天，直接单日过滤）
// 口径: 口径文档 Sales & Inventory Penetration Trend.md §11；时间范围看 this period
//       end period 最后一天（= 所选行 TimeFrame_Max）；sum(inv_qty)
// 数据底表: a02_e2e_product_performance_inv_summary_d
// 说明: 行筛选经维度表关系自动传导 inv 表；inv 表无渠道字段，不受渠道筛选影响
// 数据类型: integer；数据格式: #,##0（千分位整数，度量值静态格式）
// ========================================

// ── 期末日期：所选时间范围 end period 最后一天 = 所选行 TimeFrame_Max ──
VAR __EndPeriodDate = SELECTEDVALUE(Slicer_Time_Frame_Sales_Trend[TimeFrame_Max])

RETURN
    CALCULATE(
        SUM('a02_e2e_product_performance_inv_summary_d'[inv_qty]),
        'a02_e2e_product_performance_inv_summary_d'[data_date] = __EndPeriodDate
    )
```

### 4.14 S&I Inventory EOH Amt TY Value（期末库存金额 TY，当前币种）

```dax
S&I Inventory EOH Amt TY Value =
// ========================================
// 度量值: S&I Inventory EOH Amt TY Value
// 中文名: 期末库存金额（TY，当前币种）
// Display Folder: Sales & Inventory Penetration Trend\Base Metrics
// 用途: EOH Units × msrp（期末库存金额），Inventory 表六维度行切换共享
// 依赖: Slicer_Time_Frame_Sales_Trend[TimeFrame_Max]，
//       Slicer_Currency_Selection[Currency_ExchangeRate]
// 口径: 口径文档 Sales & Inventory Penetration Trend.md §12；时间范围看 this period
//       end period 最后一天（= 所选行 TimeFrame_Max）；sum(msrp_inv_amt)
// 数据底表: a02_e2e_product_performance_inv_summary_d
// 期末机制: 期末日期直接取所选行 TimeFrame_Max 单日过滤（v1.2 调整，无快照日回退）
// 币种: 数据底表仅存 CNY，Value 层换算为当前币种金额（原始值 ÷ 汇率）；
//       RMB 汇率 = 1 时换算前后值相同；Display 层仅拼接币种符号
// 说明: inv 表无渠道字段，本指标不受渠道筛选影响
// 数据类型: currency；数据格式: #,##0（货币符号由币种切片器决定）
// ========================================

// ── 期末日期：所选时间范围 end period 最后一天 = 所选行 TimeFrame_Max ──
VAR __EndPeriodDate = SELECTEDVALUE(Slicer_Time_Frame_Sales_Trend[TimeFrame_Max])

// ── 币种汇率（RMB = 1；USD 动态取自数仓汇率表）──
VAR __ExchangeRate = SELECTEDVALUE(Slicer_Currency_Selection[Currency_ExchangeRate], 1)

// ── 期末库存金额（原始 CNY，期末单日值）──
VAR __BaseValue =
    CALCULATE(
        SUM('a02_e2e_product_performance_inv_summary_d'[msrp_inv_amt]),
        'a02_e2e_product_performance_inv_summary_d'[data_date] = __EndPeriodDate
    )

RETURN
    DIVIDE(__BaseValue, __ExchangeRate)   // BLANK ÷ 汇率 = BLANK（期末无库存数据返回空）
```

### 4.15 S&I Inventory EOH Amt TY Display（期末库存金额 TY 显示）

```dax
S&I Inventory EOH Amt TY Display =
// ========================================
// 度量值: S&I Inventory EOH Amt TY Display
// 中文名: 期末库存金额（TY）显示
// Display Folder: Sales & Inventory Penetration Trend\Formatting
// 用途: currency 格式化（币种符号 + 千分位整数，符号由币种切片器决定）；BLANK 显示 "-"
// 依赖: [S&I Inventory EOH Amt TY Value]（已完成汇率换算）、
//       Slicer_Currency_Selection[Currency_Symbol]
// 数据格式: 币种符号 & #,##0（如 ¥1,000 / $1,000）
// ========================================
    VAR __Value = [S&I Inventory EOH Amt TY Value]
    VAR __CurrencySymbol = SELECTEDVALUE(Slicer_Currency_Selection[Currency_Symbol], "¥")
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            __CurrencySymbol & FORMAT(__Value, "#,##0")
        )
```

### 4.16 S&I Inventory In-transit Unit TY Value（在途库存数量 TY）

```dax
S&I Inventory In-transit Unit TY Value =
// ========================================
// 度量值: S&I Inventory In-transit Unit TY Value
// 中文名: 在途库存数量（TY）
// Display Folder: Sales & Inventory Penetration Trend\Base Metrics
// 用途: 已出库尚未入库到仓的货品总件数，Inventory 表六维度行切换共享
// 依赖: Slicer_Time_Frame_Sales_Trend[TimeFrame_Max]
//       （所选行 end period 最后一天，直接单日过滤）
// 口径: 口径文档 Sales & Inventory Penetration Trend.md §13；时间范围看 this period
//       end period 最后一天（= 所选行 TimeFrame_Max）；sum(in_trans_inv_qty)
// 数据底表: a02_e2e_product_performance_inv_summary_d
// 说明: 行筛选经维度表关系自动传导 inv 表；inv 表无渠道字段，不受渠道筛选影响
// 数据类型: integer；数据格式: #,##0（千分位整数，度量值静态格式）
// ========================================

// ── 期末日期：所选时间范围 end period 最后一天 = 所选行 TimeFrame_Max ──
VAR __EndPeriodDate = SELECTEDVALUE(Slicer_Time_Frame_Sales_Trend[TimeFrame_Max])

RETURN
    CALCULATE(
        SUM('a02_e2e_product_performance_inv_summary_d'[in_trans_inv_qty]),
        'a02_e2e_product_performance_inv_summary_d'[data_date] = __EndPeriodDate
    )
```

### 4.17 S&I Inventory EOH Unit LY Value（期末库存数量 LY）

```dax
S&I Inventory EOH Unit LY Value =
// ========================================
// 度量值: S&I Inventory EOH Unit LY Value
// 中文名: 期末库存数量（LY）
// Display Folder: Sales & Inventory Penetration Trend\Base Metrics
// 用途: 去年同期业务周期结束时点的期末库存总数量，Inventory 表六维度行切换共享
// 依赖: Slicer_Time_Frame_Sales_Trend[TimeFrame_Max_LY]
//       （所选行 LY end period 最后一天，直接单日过滤）
// 口径: 口径文档 Sales & Inventory Penetration Trend.md §15；看所选时间范围
//       去年同期 end period 最后一天（= 所选行 TimeFrame_Max_LY）；sum(inv_qty)
// 数据底表: a02_e2e_product_performance_inv_summary_d
// 说明: inv 表无渠道字段，不受渠道筛选影响
// 数据类型: integer；数据格式: #,##0（千分位整数，度量值静态格式）
// ========================================

// ── LY 期末日期：LY end period 最后一天 = 所选行 TimeFrame_Max_LY ──
VAR __EndPeriodDateLY = SELECTEDVALUE(Slicer_Time_Frame_Sales_Trend[TimeFrame_Max_LY])

RETURN
    CALCULATE(
        SUM('a02_e2e_product_performance_inv_summary_d'[inv_qty]),
        'a02_e2e_product_performance_inv_summary_d'[data_date] = __EndPeriodDateLY
    )
```

### 4.18 S&I Inventory EOH Amt LY Value（期末库存金额 LY，当前币种）

```dax
S&I Inventory EOH Amt LY Value =
// ========================================
// 度量值: S&I Inventory EOH Amt LY Value
// 中文名: 期末库存金额（LY，当前币种）
// Display Folder: Sales & Inventory Penetration Trend\Base Metrics
// 用途: 去年同期 EOH Units × msrp，Inventory 表六维度行切换共享
// 依赖: Slicer_Time_Frame_Sales_Trend[TimeFrame_Max_LY]，
//       Slicer_Currency_Selection[Currency_ExchangeRate]
// 口径: 口径文档 Sales & Inventory Penetration Trend.md §16；看所选时间范围
//       去年同期 end period 最后一天（= 所选行 TimeFrame_Max_LY）；sum(msrp_inv_amt)
// 数据底表: a02_e2e_product_performance_inv_summary_d
// 期末机制: 期末日期直接取所选行 TimeFrame_Max_LY 单日过滤（v1.2 调整，无快照日回退）
// 币种: 数据底表仅存 CNY，Value 层换算为当前币种金额（原始值 ÷ 汇率）
// 说明: inv 表无渠道字段，本指标不受渠道筛选影响
// 数据类型: currency；数据格式: #,##0（货币符号由币种切片器决定）
// ========================================

// ── LY 期末日期：LY end period 最后一天 = 所选行 TimeFrame_Max_LY ──
VAR __EndPeriodDateLY = SELECTEDVALUE(Slicer_Time_Frame_Sales_Trend[TimeFrame_Max_LY])

// ── 币种汇率（RMB = 1；USD 动态取自数仓汇率表）──
VAR __ExchangeRate = SELECTEDVALUE(Slicer_Currency_Selection[Currency_ExchangeRate], 1)

// ── LY 期末库存金额（原始 CNY，期末单日值）──
VAR __BaseValue =
    CALCULATE(
        SUM('a02_e2e_product_performance_inv_summary_d'[msrp_inv_amt]),
        'a02_e2e_product_performance_inv_summary_d'[data_date] = __EndPeriodDateLY
    )

RETURN
    DIVIDE(__BaseValue, __ExchangeRate)   // BLANK ÷ 汇率 = BLANK（LY 期末无库存数据返回空）
```

### 4.19 S&I Inventory EOH Amt LY Display（期末库存金额 LY 显示）

```dax
S&I Inventory EOH Amt LY Display =
// ========================================
// 度量值: S&I Inventory EOH Amt LY Display
// 中文名: 期末库存金额（LY）显示
// Display Folder: Sales & Inventory Penetration Trend\Formatting
// 用途: currency 格式化（币种符号 + 千分位整数，符号由币种切片器决定）；BLANK 显示 "-"
// 依赖: [S&I Inventory EOH Amt LY Value]（已完成汇率换算）、
//       Slicer_Currency_Selection[Currency_Symbol]
// 数据格式: 币种符号 & #,##0（如 ¥1,000 / $1,000）
// ========================================
    VAR __Value = [S&I Inventory EOH Amt LY Value]
    VAR __CurrencySymbol = SELECTEDVALUE(Slicer_Currency_Selection[Currency_Symbol], "¥")
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            __CurrencySymbol & FORMAT(__Value, "#,##0")
        )
```

### 4.20 S&I Inventory In-transit Unit LY Value（在途库存数量 LY）

```dax
S&I Inventory In-transit Unit LY Value =
// ========================================
// 度量值: S&I Inventory In-transit Unit LY Value
// 中文名: 在途库存数量（LY）
// Display Folder: Sales & Inventory Penetration Trend\Base Metrics
// 用途: 去年同期已出库尚未入库到仓的货品总件数，Inventory 表六维度行切换共享
// 依赖: Slicer_Time_Frame_Sales_Trend[TimeFrame_Max_LY]
//       （所选行 LY end period 最后一天，直接单日过滤）
// 口径: 口径文档 Sales & Inventory Penetration Trend.md §17；看所选时间范围
//       去年同期 end period 最后一天（= 所选行 TimeFrame_Max_LY）；sum(in_trans_inv_qty)
// 数据底表: a02_e2e_product_performance_inv_summary_d
// 说明: inv 表无渠道字段，不受渠道筛选影响
// 数据类型: integer；数据格式: #,##0（千分位整数，度量值静态格式）
// ========================================

// ── LY 期末日期：LY end period 最后一天 = 所选行 TimeFrame_Max_LY ──
VAR __EndPeriodDateLY = SELECTEDVALUE(Slicer_Time_Frame_Sales_Trend[TimeFrame_Max_LY])

RETURN
    CALCULATE(
        SUM('a02_e2e_product_performance_inv_summary_d'[in_trans_inv_qty]),
        'a02_e2e_product_performance_inv_summary_d'[data_date] = __EndPeriodDateLY
    )
```

### 4.21 S&I Inventory EOH Amt YOY Value（期末库存金额 YOY）

```dax
S&I Inventory EOH Amt YOY Value =
// ========================================
// 度量值: S&I Inventory EOH Amt YOY Value
// 中文名: 期末库存金额 YOY
// Display Folder: Sales & Inventory Penetration Trend\Base Metrics
// 用途: 今年 / 去年 - 1（期末库存金额同比）
// 依赖: [S&I Inventory EOH Amt TY Value]、[S&I Inventory EOH Amt LY Value]
// 口径: 口径文档 Sales & Inventory Penetration Trend.md §19（今年/去年-1）；
//       原始口径该行 EN/CN 名称交叉错位（Name_EN = EOH Amt YOY / Name_CN = 期末库存数量YOY），
//       本方案按 EN 名称实现金额 YOY = EOH Amt（TY）/ EOH Amt（LY）- 1，需业务确认
// 边界: LY 空或 0 时返回 BLANK
// 币种: TY / LY 均为同汇率换算后数值，比率不受币种选择影响
// 数据类型: percent_0dp；数据格式: #,##0%（不含正号，负值自动带负号）
// ========================================
    VAR __TY = [S&I Inventory EOH Amt TY Value]
    VAR __LY = [S&I Inventory EOH Amt LY Value]

    RETURN
        IF(
            ISBLANK(__LY) || __LY = 0,
            BLANK(),
            DIVIDE(__TY, __LY) - 1
        )
```

### 4.22 S&I Inventory EOH Unit YOY Value（期末库存数量 YOY）

```dax
S&I Inventory EOH Unit YOY Value =
// ========================================
// 度量值: S&I Inventory EOH Unit YOY Value
// 中文名: 期末库存数量 YOY
// Display Folder: Sales & Inventory Penetration Trend\Base Metrics
// 用途: 今年 / 去年 - 1（期末库存数量同比）
// 依赖: [S&I Inventory EOH Unit TY Value]、[S&I Inventory EOH Unit LY Value]
// 口径: 口径文档 Sales & Inventory Penetration Trend.md §20（今年/去年-1）；
//       原始口径该行 EN/CN 名称交叉错位（Name_EN = EOH Unit YOY / Name_CN = 期末库存金额YOY），
//       本方案按 EN 名称实现数量 YOY = EOH Unit（TY）/ EOH Unit（LY）- 1，需业务确认
// 边界: LY 空或 0 时返回 BLANK
// 数据类型: percent_0dp；数据格式: #,##0%（不含正号，负值自动带负号）
// ========================================
    VAR __TY = [S&I Inventory EOH Unit TY Value]
    VAR __LY = [S&I Inventory EOH Unit LY Value]

    RETURN
        IF(
            ISBLANK(__LY) || __LY = 0,
            BLANK(),
            DIVIDE(__TY, __LY) - 1
        )
```

### 4.23 S&I TimeFrame Value TY（当前所选时间值 TY）

```dax
S&I TimeFrame Value TY =
// ========================================
// 度量值: S&I TimeFrame Value TY
// 中文名: 当前所选时间值（TY）
// Display Folder: Sales & Inventory Penetration Trend\Base Metrics
// 用途: 返回当前单选的 TimeFrame_Value 显示值（如 Month 粒度 "2027-04"），
//       可用于卡片 / 视觉对象标题 / 表头展示当前 TY 期间
// 依赖: Slicer_Time_Frame_Sales_Trend[TimeFrame_Value]（单选字段）
// 边界: 未选择 / 多选时返回 BLANK
// 数据类型: text（原始口径未定义，按日期表字段类型输出）
// ========================================
    SELECTEDVALUE(Slicer_Time_Frame_Sales_Trend[TimeFrame_Value])
```

### 4.24 S&I TimeFrame Value LY（当前所选时间值 LY）

```dax
S&I TimeFrame Value LY =
// ========================================
// 度量值: S&I TimeFrame Value LY
// 中文名: 当前所选时间值（LY）
// Display Folder: Sales & Inventory Penetration Trend\Base Metrics
// 用途: 返回当前所选行的 TimeFrame_Value_LY 显示值（日期表预计算的去年同期，
//       如 Month 粒度选 "2027-04" 时返回 "2026-04"），可用于卡片 / 视觉对象
//       标题 / 表头展示 LY 期间
// 依赖: Slicer_Time_Frame_Sales_Trend[TimeFrame_Value_LY]（表内预计算去年同期值）
// 边界: 未选择 / 多选时返回 BLANK；日期表该行 LY 值为空时返回 BLANK
// 数据类型: text（原始口径未定义，按日期表字段类型输出）
// ========================================
    SELECTEDVALUE(Slicer_Time_Frame_Sales_Trend[TimeFrame_Value_LY])
```

---

## 5. 度量值清单

| #  | 度量值                                 | 中文名                 | 指标类型      | 度量值静态格式 | 用于视觉对象                    |
| -- | -------------------------------------- | ---------------------- | ------------- | -------------- | ------------------------------- |
| 1  | S&I Sales SLS Amt% Value               | 销售金额占比           | percent_0dp   | `#,##0%`     | Sales 表                        |
| 2  | S&I Sales SLS Unit TY Value            | DCom净销售数量（TY）   | integer       | `#,##0`      | Sales 表                        |
| 3  | S&I Sales SLS Amt TY Value             | DCom净销售额（TY）     | currency      | `#,##0`      | Sales 表（经 Display）          |
| 4  | S&I Sales SLS Amt TY Display           | DCom净销售额（TY）显示 | currency 文本 | 文本           | Sales 表                        |
| 5  | S&I ST% TY Value                       | 售罄率%（金额，TY）    | percent_0dp   | `#,##0%`     | Sales 表 + Inventory 表（共享） |
| 6  | S&I Sales SLS Unit LY Value            | DCom净销售数量（LY）   | integer       | `#,##0`      | Sales 表                        |
| 7  | S&I Sales SLS Amt LY Value             | DCom净销售额（LY）     | currency      | `#,##0`      | Sales 表（经 Display）          |
| 8  | S&I Sales SLS Amt LY Display           | DCom净销售额（LY）显示 | currency 文本 | 文本           | Sales 表                        |
| 9  | S&I ST% LY Value                       | 售罄率%（金额，LY）    | percent_0dp   | `#,##0%`     | Sales 表 + Inventory 表（共享） |
| 10 | S&I Sales SLS Amt YOY Value            | DCom净销售额 YOY       | percent_0dp   | `#,##0%`     | Sales 表                        |
| 11 | S&I Sales SLS Unit YOY Value           | DCom净销售数量 YOY     | percent_0dp   | `#,##0%`     | Sales 表                        |
| 12 | S&I Inventory EOH Amt% Value           | 期末库存金额占比       | percent_0dp   | `#,##0%`     | Inventory 表                    |
| 13 | S&I Inventory EOH Unit TY Value        | 期末库存数量（TY）     | integer       | `#,##0`      | Inventory 表                    |
| 14 | S&I Inventory EOH Amt TY Value         | 期末库存金额（TY）     | currency      | `#,##0`      | Inventory 表（经 Display）      |
| 15 | S&I Inventory EOH Amt TY Display       | 期末库存金额（TY）显示 | currency 文本 | 文本           | Inventory 表                    |
| 16 | S&I Inventory In-transit Unit TY Value | 在途库存数量（TY）     | integer       | `#,##0`      | Inventory 表                    |
| 17 | S&I Inventory EOH Unit LY Value        | 期末库存数量（LY）     | integer       | `#,##0`      | Inventory 表                    |
| 18 | S&I Inventory EOH Amt LY Value         | 期末库存金额（LY）     | currency      | `#,##0`      | Inventory 表（经 Display）      |
| 19 | S&I Inventory EOH Amt LY Display       | 期末库存金额（LY）显示 | currency 文本 | 文本           | Inventory 表                    |
| 20 | S&I Inventory In-transit Unit LY Value | 在途库存数量（LY）     | integer       | `#,##0`      | Inventory 表                    |
| 21 | S&I Inventory EOH Amt YOY Value        | 期末库存金额 YOY       | percent_0dp   | `#,##0%`     | Inventory 表                    |
| 22 | S&I Inventory EOH Unit YOY Value       | 期末库存数量 YOY       | percent_0dp   | `#,##0%`     | Inventory 表                    |
| 23 | S&I TimeFrame Value TY                 | 当前所选时间值（TY）   | text（辅助）  | 文本           | 卡片 / 标题 / 表头（当前期间）  |
| 24 | S&I TimeFrame Value LY                 | 当前所选时间值（LY）   | text（辅助）  | 文本           | 卡片 / 标题 / 表头（LY 期间）   |

- 全部度量值存放于 `_Measures` 隐藏表；Display Folder：`Sales & Inventory Penetration Trend\Base Metrics`（Value 层 18 个 + 辅助文本度量 2 个）与 `Sales & Inventory Penetration Trend\Formatting`（Display 层，4 个），合计 24 个
- `S&I TimeFrame Value TY / LY`（§4.23 / §4.24）为非指标类辅助度量：读单选所选行的 TimeFrame_Value / TimeFrame_Value_LY 文本值（如 "2027-04" / "2026-04"），可用于卡片 / 视觉对象标题 / 表头展示当前期间与 LY 期间；未选择或多选时返回 BLANK

---

## 6. 血缘关系图

```
┌─────────────────────────────────────────────────────────────────────┐
│                        数据源层                                      │
│  a02_e2e_product_performance_sales_summary_d（销售类，日粒度）       │
│  字段: data_date, platform, shop_name,                              │
│        brand, super_season, product_type, category,                 │
│        md_type, division, framework, ax_class, ...                  │
│        net_sales_amt, net_sales_qty                                 │
│  a02_e2e_product_performance_inv_summary_d（库存类，日快照）        │
│  字段: data_date + 同名商品维度（无 platform / shop_name）,         │
│        msrp_inv_amt, inv_qty,                                       │
│        msrp_in_trans_inv_amt, in_trans_inv_qty                      │
└──────────────────────────────┬──────────────────────────────────────┘
                               │
        ┌──────────────────────┼───────────────────────────┐
        │ 渠道/商品切片器 1:N 自动传递（无需 DAX）          │ 时间筛选器（断开维度）
        │ Slicer_Platform_Selection / Store_Name           │ Slicer_Time_Frame_Sales_Trend
        │ （仅 sales 侧）                                   │ （单选 TimeFrame_Value）
        │ 六个商品维度表 1:N 双事实表                       │ → TimeFrame_Min / Max（TY 区间）
        │ Slicer_Label / Super_Season /                    │ → TimeFrame_Min_LY / Max_LY
        │ Product_Type / Category /                        │   （LY 区间，表内预计算）
        │ Md_Type / Division                               │ → TimeFrame_Max / Max_LY
        ▼                                                  │   （期末最后一天，直接单日过滤）
┌─────────────────────────────────────────────────────────────────────┐
│  Value 度量层（18 个：Sales 专属 7 + Inventory 专属 9 + ST% 共享 2） │
│  - 区间类（TY / LY）/ 期末时点类（TimeFrame_Max / Max_LY 单日）时间口径 │
│  - SLS Amt% / EOH Amt% 分母 ALLSELECTED 六个商品维度表字段           │
│    （移除视觉内部行维度筛选，保留外部切片器，单度量适配六维度切换）   │
│  - currency 4 个含汇率换算 ÷ Slicer_Currency_Selection              │
│    [Currency_ExchangeRate]（RMB = 1 时值不变）                       │
│  - YOY 4 个 = TY Value / LY Value - 1（复用 Value 度量）             │
└──────────────────────────────┬──────────────────────────────────────┘
                               ▼
┌─────────────────────────────────────────────────────────────────────┐
│  Display 度量层（4 个 currency：SLS Amt TY/LY、EOH Amt TY/LY）       │
│  Currency_Symbol & FORMAT(Value, "#,##0")，BLANK 显示 "-"           │
└──────────────────────────────┬──────────────────────────────────────┘
                               ▼
┌─────────────────────────────────────────────────────────────────────┐
│                        可视化层（两张表格）                          │
│  Sales 表:    行 = 商品维度六选一；9 列（currency 列用 Display，     │
│               其余用 Value + 静态格式；ST% 两列为共享度量）          │
│  Inventory 表: 行 = 同一行字段；11 列（currency 列用 Display，      │
│               其余用 Value + 静态格式；ST% 两列为共享度量）          │
│  时间切片器: Slicer_Time_Frame_Sales_Trend 单选 TimeFrame_Value      │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 7. 视觉对象配置

### 7.1 Sales 表格（子模块一）

| 配置项             | 内容                                                                                                                                                                                                                                                                             |
| ------------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 视觉对象类型       | 表格                                                                                                                                                                                                                                                                             |
| 行                 | Slicer_ 六维度字段六选一（切换时替换行区域字段，度量值层无感知）                                                                                                                                                                                                                 |
| 值列（按口径顺序） | S&I Sales SLS Amt% Value → S&I Sales SLS Unit TY Value → S&I Sales SLS Amt TY**Display** → S&I ST% TY Value → S&I Sales SLS Unit LY Value → S&I Sales SLS Amt LY **Display** → S&I ST% LY Value → S&I Sales SLS Amt YOY Value → S&I Sales SLS Unit YOY Value |
| 列标题             | 按口径指标名（SLS Amt% / SLS Unit（TY）/ SLS Amt（TY）/ ST%（TY）/ SLS Unit（LY）/ SLS Amt（LY）/ ST%（LY）/ SLS Amt YOY / SLS Unit YOY）                                                                                                                                        |
| 总计               | 若开启：占比列 = 100%（分子分母同范围）、数量类 = 全量合计、ST% / YOY = 全量分子分母重算，均为汇总语义下的正确行为                                                                                                                                                               |

### 7.2 Inventory 表格（子模块二）

| 配置项             | 内容                                                                                                                                                                                                                                                                                                                                                                                                           |
| ------------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 视觉对象类型       | 表格                                                                                                                                                                                                                                                                                                                                                                                                           |
| 行                 | 与 Sales 表共用同一行字段（两表切换同一维度联动）                                                                                                                                                                                                                                                                                                                                                              |
| 值列（按口径顺序） | S&I Inventory EOH Amt% Value → S&I Inventory EOH Unit TY Value → S&I Inventory EOH Amt TY**Display** → S&I Inventory In-transit Unit TY Value → S&I ST% TY Value（共享）→ S&I Inventory EOH Unit LY Value → S&I Inventory EOH Amt LY **Display** → S&I Inventory In-transit Unit LY Value → S&I ST% LY Value（共享）→ S&I Inventory EOH Amt YOY Value → S&I Inventory EOH Unit YOY Value |
| 总计               | 若开启：行为同 Sales 表（汇总语义正确）                                                                                                                                                                                                                                                                                                                                                                        |

### 7.3 切片器

| 切片器                                              | 类型                                                        | 作用                                                                                                 |
| --------------------------------------------------- | ----------------------------------------------------------- | ---------------------------------------------------------------------------------------------------- |
| Slicer_Time_Frame_Sales_Trend                       | 单选时间筛选器（TimeFrame_Value 单选，Week / Month / Year） | 驱动全部度量的 TY / LY 时间范围与期末日期（读表内 TimeFrame_Min / Max / Min_LY / Max_LY 预计算字段） |
| Slicer_Platform_Selection / Slicer_Store_Name       | 一对多关联（仅 sales 表）                                   | 渠道筛选自动传递销售侧指标                                                                           |
| 商品维度切片器（Slicer_Label / Slicer_Division 等） | 一对多关联（双表）                                          | 外部筛选自动传递；占比分母经 ALLSELECTED 保留该外部筛选                                              |
| Slicer_Currency_Selection                           | 断开维度                                                    | currency 4 个指标 Value 层汇率换算 + Display 层币种符号                                              |

---

## 8. 验证方法

验证 SQL 为 ClickHouse 语法；时间范围与外部筛选条件按页面实际选择替换附加，与 Power BI 模型值逐项对齐。示例按单选 Month 粒度 `TimeFrame_Value = '2027-04'`（TY = 2027-04-01 ~ 2027-04-30，LY = 2026-04-01 ~ 2026-04-30，示例按自然月示意，实际以财月区间为准）。

### 8.1 SLS Amt%（行维度 = label 示例）

```sql
SELECT
    label,
    __numerator / SUM(__numerator) OVER () AS sls_amt_pct
FROM (
    SELECT
        brand AS label,
        SUM(net_sales_amt) AS __numerator
    FROM indep_rl_ads.a02_e2e_product_performance_sales_summary_d
    WHERE data_date >= '2027-04-01' AND data_date <= '2027-04-30'
        -- TimeFrame_Min / TimeFrame_Max（单选所选行）；外部切片器筛选条件（platform / 商品维度等）同步附加
    GROUP BY brand
)
```

- 分母窗口 `SUM(...) OVER ()` 对应 ALLSELECTED 六维度的全量合计（外部筛选下）；换行维度验证时将 brand 替换为对应维度字段（super_season / product_type / category / md_type / division）

### 8.2 EOH Amt%（期末最后一天时点）

```sql
SELECT
    label,
    __numerator / SUM(__numerator) OVER () AS eoh_amt_pct
FROM (
    SELECT
        inv.brand AS label,
        SUM(inv.msrp_inv_amt) AS __numerator
    FROM indep_rl_ads.a02_e2e_product_performance_inv_summary_d inv
    INNER JOIN indep_rl_dim.dim_t00_bi_fiscal_calendar c
        ON inv.data_date = c.timeframe_max          -- 所选行 TimeFrame_Max（end period 最后一天）单日过滤
    WHERE c.timeframe_id = 'Month' AND c.timeframe_value = '2027-04'
        -- 外部商品维度筛选条件同步附加；inv 表无渠道字段，不附加渠道条件（与 Power BI 行为一致）
    GROUP BY inv.brand
)
```

- EOH Unit / EOH Amt / In-transit Unit 同法：换聚合字段（inv_qty / msrp_inv_amt / in_trans_inv_qty），金额类结果为原始 CNY
- 边界：所选 TimeFrame_Max 当日无快照数据（如进行中的时间单位）→ SQL 无行返回，Power BI 显示空 / "-"

### 8.3 ST%（TY，跨双表）

```sql
WITH __sales AS (
    SELECT brand AS label, SUM(net_sales_amt) AS sls_amt
    FROM indep_rl_ads.a02_e2e_product_performance_sales_summary_d
    WHERE data_date >= '2027-04-01' AND data_date <= '2027-04-30'
        -- sales 侧附加渠道条件（若渠道切片器有选择）
    GROUP BY brand
),
__inv AS (
    SELECT inv.brand AS label, SUM(inv.msrp_inv_amt) AS inv_amt
    FROM indep_rl_ads.a02_e2e_product_performance_inv_summary_d inv
    INNER JOIN indep_rl_dim.dim_t00_bi_fiscal_calendar c
        ON inv.data_date = c.timeframe_max          -- 所选行 TimeFrame_Max（end period 最后一天）单日过滤
    WHERE c.timeframe_id = 'Month' AND c.timeframe_value = '2027-04'
    GROUP BY inv.brand
)
SELECT
    s.label,
    s.sls_amt / (s.sls_amt + i.inv_amt) AS st_pct
FROM __sales s
FULL OUTER JOIN __inv i ON s.label = i.label
```

- sales 侧附加渠道条件（若渠道切片器有选择）、inv 侧不附加（无渠道字段）；外部商品维度条件双表同步附加
- 期末库存缺失的行（inv 侧无数据）：Power BI ST% 显示空（空值保护返回 BLANK）

### 8.4 LY 指标与 YOY

- **LY 区间日期换为所选行 `TimeFrame_Min_LY` / `TimeFrame_Max_LY`**（示例 '2026-04-01' ~ '2026-04-30'）——注意与 Merchandising Core KPI / Label & PT 模块不同，本模块 LY 读 `Slicer_Time_Frame_Sales_Trend` 表内预计算字段，**不读 Min_Last / Max_Last 筛选器**
- LY 库存类（EOH Unit / EOH Amt / In-transit Unit LY）：期末日期取所选行 **`TimeFrame_Max_LY`**（LY end period 最后一天，8.2 的 JOIN 换 `c.ly_timeframe_max`）
- ST%（LY）：sales 侧时间换 LY 区间、inv 侧仍用**当前** `TimeFrame_Max`（8.3 仅改 `__sales` 的时间范围）——口径不对称为原始口径定义，需业务确认
- YOY：TY / LY - 1，两侧按上述口径分别取数后计算；LY 空或 0 时 Power BI 显示空（Value 层 BLANK）

### 8.5 金额类（SLS Amt / EOH Amt，currency 4 个）

```sql
SELECT
    brand AS label,
    SUM(net_sales_amt) AS sls_amt_cny
FROM indep_rl_ads.a02_e2e_product_performance_sales_summary_d
WHERE data_date >= '2027-04-01' AND data_date <= '2027-04-30'
    -- TY：TimeFrame_Min / TimeFrame_Max；LY：换 TimeFrame_Min_LY / TimeFrame_Max_LY
    -- 外部切片器筛选条件同步附加
GROUP BY brand
```

- 币种对齐：SQL 结果为原始 CNY，Power BI 模型值 = 原始值 ÷ 当前 `Currency_ExchangeRate`（RMB 汇率 = 1 时直接对比）；EOH Amt / LY 同法（TimeFrame_Max / TimeFrame_Max_LY 单日聚合，同 8.2 JOIN 后换聚合字段）

---

## 9. 注意事项

1. **日期表差异（本模块核心差异）**：本模块使用 `Slicer_Time_Frame_Sales_Trend` **单选** TimeFrame_Value，TY / LY 区间与期末日期均读**同一所选行的表内字段**（TimeFrame_Min / TimeFrame_Max / TimeFrame_Min_LY / TimeFrame_Max_LY 预计算；期末最后一天 = TimeFrame_Max / TimeFrame_Max_LY）——区别于 Merchandising Core KPI / Label & PT 的 Min_This / Max_This / Min_Last / Max_Last 四表模式（多选区间 + 独立 last period 筛选器）。本模块无 last period 筛选器，"去年" 固定为去年同期；单选保证 Min / Max / LY 字段同现同缺，未选择时度量返回 BLANK；多选时 SELECTEDVALUE 返回 BLANK（效果同未选择）。
2. **LY / YOY 时间基准**：LY = 日期表预计算去年同期区间；YOY = 今年 / 去年 - 1（TY / LY 同期对比，复用 Value 度量计算）。
3. **期末时点口径（v1.2 调整）**：单选下所选区间即一个完整时间单位，「end period 最后一天」= 所选行 `TimeFrame_Max`（LY 库存类 = `TimeFrame_Max_LY`），度量直接以 `inv[data_date] = __EndPeriodDate` 单日过滤——语义贴合口径原文、免全表扫描（原「区间内最后一个有数据的快照日」回退模式已移除）。快照表按日存储只取单日，对整段区间求和会重复计数库存。边界：所选时间为**进行中的时间单位**（TimeFrame_Max 在未来，如未结束的当月）或该日快照未产出时，EOH / In-transit / EOH Amt% 返回 BLANK（口径忠实：期末未到无期末值）；如业务需展示最近可得快照，可改回 `CALCULATE(MAX(inv[data_date]), REMOVEFILTERS(inv), 区间谓词)` 回退模式，需业务确认。
4. **ST%（LY）分子分母时间基准不对称**：分子（LY 销售）取去年同期区间，分母（期末库存金额）取**当前** TimeFrame_Max（非 LY 期末）——原始口径明文如此定义（口径文档 §7 / §18 标注"需业务确认"），DAX 按口径原文实现；若业务确认应为 LY 期末，仅需将 `__InvAmt` 的 `__EndPeriodDate` 换为 `TimeFrame_Max_LY`。
5. **ST% 空值保护（v1.2 新增）**：期末库存缺失（所选 TimeFrame_Max 当日快照未产出，如进行中的时间单位）时 ST%（TY / LY）返回 BLANK，避免 `DIVIDE(SLS, SLS + BLANK) = 100%`（即 100% 售罄）失真；期末有库存而期间无销售时仍为 0%（数学正确）。
6. **EOH Amt YOY / EOH Unit YOY 名称交叉错位**：原始口径两行的 Name_EN / Name_CN 交叉（EOH Amt YOY ↔ 期末库存数量YOY、EOH Unit YOY ↔ 期末库存金额YOY）；本方案按 EN 名称实现——EOH Amt YOY = EOH Amt（TY）/ EOH Amt（LY）- 1（金额口径），EOH Unit YOY = EOH Unit（TY）/ EOH Unit（LY）- 1（数量口径），需业务确认。
7. **inv 表无渠道字段**：a02_e2e_product_performance_inv_summary_d 无 platform / shop_name，渠道筛选（Slicer_Platform_Selection / Slicer_Store_Name）不影响 Inventory 侧全部指标（EOH / In-transit / EOH Amt% / ST% 分母）；ST% 分子（sales 侧）受渠道筛选影响、分母不受影响（渠道口径不对称，需业务知悉）；SLS Amt% 分子分母同为 sales 侧、同受渠道筛选，比率语义不受影响。
8. **占比分母的 ALLSELECTED（列级写法）**：SLS Amt% / EOH Amt% 分母同时对六个商品维度表**字段**应用 `ALLSELECTED('Slicer_Label'[label])` … `ALLSELECTED('Slicer_Division'[division])`（与 Label & PT / Sales Performance Details 模块一致）——一次只有一个字段在表格行上，其余五个字段为无操作；移除视觉对象内部的行维度筛选、保留外部切片器。**ALLSELECTED 与 REMOVEFILTERS 的语义差异是分母正确性的关键**：REMOVEFILTERS 连外部切片器一并移除，分母会脱离业务筛选条件；ALLSELECTED 仅移除视觉对象内部行筛选。**无论行字段切换到哪个维度，一个度量即可覆盖六个维度**。
9. **行字段必须从 Slicer_ 维度表拉取**：行筛选直接落在维度表字段上，`ALLSELECTED(维度表字段)` 才能正确移除；若误用事实表字段（如 sales[brand]）作行字段，维度表字段上无视觉对象内部筛选，ALLSELECTED 为无效操作，事实表字段的行筛选不被移除，占比恒 100%。
10. **label / brand 字段说明**：口径中的 "label" 维度对应事实表字段 `brand`（Slicer_Label 表 [label] 字段由 `select distinct brand as label` 生成，数据字典已由 label 统一更新为 brand）；本方案行字段与 ALLSELECTED 均作用于 Slicer_Label 维度表，字段映射由模型关系完成。
11. **币种换算分层**：currency 类 4 个指标在 Value 度量内完成换算（原始 CNY ÷ Currency_ExchangeRate，RMB 汇率 = 1 时值不变）；Display 度量仅拼接 Currency_Symbol；YOY 为 TY / LY 同汇率相除，比率不受币种选择影响；占比 / 比率 / 数量类不涉及换算（分子分母同表同币种）。
12. **Display 度量仅覆盖 currency 类（本模块需求范围）**：percent_0dp / integer 类直接使用 Value 度量 + 度量值静态格式（`#,##0%` / `#,##0`，均不含正号，负值自动带负号）；BLANK 在 Value 列显示为空、在 Display 列显示 "-"。如后续需要非 currency 列也显示 "-"，可按 Label & PT 模块补对应 Display 度量。
13. **YOY 空值规则**：LY 空或 0 时 YOY 返回 BLANK（避免 `DIVIDE` 返回 BLANK 后 `- 1` 变成 -100% 的失真）。
14. **维度表 1:N 自动传递（无 TREATAS）**：六个商品维度表与 sales / inv 两张事实表均建立一对多关系，行维度与外部切片器筛选全部经模型关系自动传递——区别于 Sales Performance Details 方案（行字段取自 sales 表 + inv 侧 TREATAS 显式传递），本模块无需任何 TREATAS。
15. **ST% 两表共享度量**：ST%（TY）/ ST%（LY）在 Sales 与 Inventory 两表口径完全一致（公式 / 时间口径 / 数据格式无差异，唯一差异是所在表格），按 Label & Product Type 模块共享模式输出一套度量（`S&I ST% TY Value` / `S&I ST% LY Value`，不带子模块前缀），两表各引用一次。
16. **度量值命名与组织**：模块前缀 `S&I` + 子模块前缀 `Sales` / `Inventory`（共享度量不带子模块前缀）+ 指标名 + 层次后缀 Value / Display；全部度量值存放于 `_Measures` 隐藏表；Display Folder 按层次分为 `Sales & Inventory Penetration Trend\Base Metrics`（Value 层）与 `Sales & Inventory Penetration Trend\Formatting`（Display 层）。
17. **字段名已核对数据字典**：net_sales_amt / net_sales_qty（sales 表）；msrp_inv_amt / inv_qty / msrp_in_trans_inv_amt / in_trans_inv_qty（inv 表）；日期字段统一为 data_date（Date 类型）；TimeFrame_Min / TimeFrame_Max / TimeFrame_Min_LY / TimeFrame_Max_LY 为日期表预计算日期字段。
18. **口径与语法**：口径文档中定义的所有指标必须遵守其数据类型与数据格式，与解决方案存在争议时一切以口径文档为准；DAX 文本常量使用双引号，单引号仅用于表名，列名使用方括号，例如：`[md_type] = "FP"`。
