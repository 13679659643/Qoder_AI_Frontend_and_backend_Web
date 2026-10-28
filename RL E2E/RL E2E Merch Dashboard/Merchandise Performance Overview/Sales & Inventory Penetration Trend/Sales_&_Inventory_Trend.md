# Sales & Inventory Penetration Trend 柱形图解决方案

> **版本**: v1.3（全部指标叠加全局 this period 区间范围框定：TY 指标 = [Min_This[TimeFrame_Min], Max_This[TimeFrame_Max]]，LY 指标 = 其去年同期 [Min_This[TimeFrame_Min_LY], Max_This[TimeFrame_Max_LY]]，与当前柱区间取交集；v1.2 EOH 期末日期直接取 TimeFrame_Max / TimeFrame_Max_LY；v1.1 新增 Inventory 侧四个指标）
> **模块**: RL E2E Merch Dashboard - Merchandise Performance Overview Tab - Sales & Inventory Penetration Trend - Trend 柱形图（板块左侧）
> **关联方案**: Sales_&_Inventory_Table.md（指标提取来源：§4.1 SLS Amt%、§4.3 SLS Amt TY、§4.7 SLS Amt LY、§4.12 EOH Amt%、§4.14 EOH Amt TY、§4.18 EOH Amt LY；SLS Amt% LY / EOH Amt% LY 表格方案未含，本次新增）
> **关联口径**: 口径文档/口径Markdown格式/Sales & Inventory Penetration Trend.md §1（SLS Amt%）、§3 / §6（SLS Amt TY / LY）、§10（EOH Amt%）、§12 / §16（EOH Amt TY / LY）；原始口径 §21 / §22 遗留的「Week / Month / Year 和全局时间筛选器的关系」待确认项，本方案以视觉对象筛选度量 + 全局区间框定落地
> **数据底表（销售类）**: a02_e2e_product_performance_sales_summary_d
> **数据底表（库存类）**: a02_e2e_product_performance_inv_summary_d
> **关联维度**: Slicer_Time_Frame_Sales_Trend（柱形图 X 轴 + 逐柱 TY / LY 区间与期末日期，断开维度）、Slicer_Time_Frame（全局时间粒度）、Slicer_Time_Frame_Min_This / Max_This（**全局 this period 区间：柱子显示范围（IsVisible）+ 全部指标的范围框定**，断开维度）、Slicer_Currency_Selection（币种，断开维度）、Slicer_Label / Slicer_Super_Season / Slicer_Product_Type / Slicer_Category / Slicer_Md_Type / Slicer_Division（商品维度，图例字段六选一，与双事实表一对多关联）
> **参考模版**: 模版复用/字段筛选模版.md §1.1 IsMonthVisible（日期筛选器展示值是否在范围内的写法——柱形图 X 轴为断开维度日期表时，以度量做视觉对象级别筛选限定柱子范围）

---

## 1. 需求理解

### 1.1 模块定位与视觉对象结构

本方案覆盖 Sales & Inventory Penetration Trend 板块的**左侧柱形图**（穿透趋势图），与右侧 Sales / Inventory 两张明细表格（见 Sales_&_Inventory_Table.md）共同构成本板块：

| 视觉对象                                | 覆盖口径                                                   | 结构                                                                   |
| --------------------------------------- | ---------------------------------------------------------- | ---------------------------------------------------------------------- |
| Sales Trend 柱形图（SLS 侧 4 度量）     | §1 SLS Amt%（销售穿透趋势）+ §3 / §6 SLS Amt TY / LY    | X 轴 = 时间（逐柱）+ 图例 = 商品维度（六选一）+ Y 轴 = SLS 侧 4 个度量 |
| Inventory Trend 柱形图（EOH 侧 4 度量） | §10 EOH Amt%（库存穿透趋势）+ §12 / §16 EOH Amt TY / LY | X 轴 = 时间（逐柱）+ 图例 = 商品维度（六选一）+ Y 轴 = EOH 侧 4 个度量 |
| Sales / Inventory 明细表格              | §1-§20                                                   | 见 Sales_&_Inventory_Table.md                                          |

- **SLS 侧与 EOH 侧建议分图呈现**（同 Label & PT 模块做法）：SLS Amt% 为区间汇总口径、EOH Amt% 为期末时点口径，两者时间语义不同，同图混排易误读；两图共用同一 X 轴字段、同一图例机制、同一 IsVisible 视觉筛选与全部度量写法模式
- 原始口径遗留的「明细表表格列受左边柱状图影响」联动关系：柱形图对明细表保持交叉筛选开启（点击柱子传导 `TimeFrame_Value` 筛选，明细表 SELECTEDVALUE 读取点击柱所在行，与表格方案的单选模式天然兼容，见注意事项 6）

### 1.2 柱形图结构（逐柱「当前值」+ 全局区间框定）

| 配置项           | 内容                                                                                                                                                                                                                                                      |
| ---------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| X 轴             | `Slicer_Time_Frame_Sales_Trend[TimeFrame_Value]`（新日期表，断开维度；按 ID_Sort 排序）                                                                                                                                                                 |
| 图例             | 商品维度字段六选一：`Slicer_Label[label]` / `Slicer_Super_Season[super_season]` / `Slicer_Product_Type[product_type]` / `Slicer_Category[category]` / `Slicer_Md_Type[md_type]` / `Slicer_Division[division]`（替换图例字段，度量值层无感知） |
| Y 轴（值）       | SLS 侧：S&I Trend SLS Amt% TY / LY（占比主指标）、S&I Trend SLS Amt TY / LY（金额）；EOH 侧：S&I Trend EOH Amt% TY / LY（占比主指标）、S&I Trend EOH Amt TY / LY（金额）——按版面组合使用（TY / LY 双图、同图双系列或 tooltip）                          |
| 视觉对象级别筛选 | `[S&I Trend TimeFrame IsVisible] = 1`（柱子范围限定在全局 this period 区间内 + 粒度一致，见 §3.4）                                                                                                                                                     |
| 指标全局框定     | 每个指标度量叠加全局 this period 区间（TY = [Min_This[TimeFrame_Min], Max_This[TimeFrame_Max]]；LY = 其去年同期 [Min_This[TimeFrame_Min_LY], Max_This[TimeFrame_Max_LY]]），与当前柱范围取交集——可见柱下为无操作（防御性框定），见 §1.3 / 注意事项 9   |
| 柱子范围示例     | 全局 this period = 2027-01 ~ 2027-04（Month 粒度）→ 柱形图显示 4 根柱子：2027-01、2027-02、2027-03、2027-04                                                                                                                                              |

**逐柱「当前值」机制**：X 轴按 `TimeFrame_Value` 分组，每根柱子在其计算上下文中将 `Slicer_Time_Frame_Sales_Trend` 表筛选到**当前柱所在行**——度量内 `SELECTEDVALUE(TimeFrame_Min / TimeFrame_Max / TimeFrame_Min_LY / TimeFrame_Max_LY)` 即取到**当前柱的 TY / LY 区间与期末日期**。例如范围为 2027-01~2027-04 时，第一根柱子是 2027-01，该柱的 TY 区间 = [TimeFrame_Min, TimeFrame_Max]（财月区间以日期表为准）、LY 区间 = [TimeFrame_Min_LY, TimeFrame_Max_LY]，即「当前值」。每根柱子独立计算，无需任何显式迭代。

- **SLS 侧（区间类）**：逐柱对区间 `[TimeFrame_Min, TimeFrame_Max]`（TY）/ `[TimeFrame_Min_LY, TimeFrame_Max_LY]`（LY）求 sum，并叠加全局区间框定（交集）
- **EOH 侧（期末时点类）**：逐柱取**当前柱所在行 `TimeFrame_Max`**（TY）/ `TimeFrame_Max_LY`（LY）——即口径「end period 最后一天」，直接以 `inv[data_date] = __EndPeriodDate` 单日过滤（单日同样满足全局区间框定）；对区间求和会重复计数库存

### 1.3 时间口径

| 口径                         | 时间范围                                                                                                                                                                                | 适用指标                            |
| ---------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------- |
| 当前柱 TY 区间               | data_date ∈ 当前柱所在行 [TimeFrame_Min, TimeFrame_Max]                                                                                                                                | SLS Amt TY、SLS Amt% TY（分子分母） |
| 当前柱 LY 区间               | data_date ∈ 当前柱所在行 [TimeFrame_Min_LY, TimeFrame_Max_LY]（表内预计算去年同期）                                                                                                    | SLS Amt LY、SLS Amt% LY（分子分母） |
| 当前柱期末时点（TY）         | 当前柱所在行**TimeFrame_Max**（end period 最后一天，单日时点）                                                                                                                    | EOH Amt TY、EOH Amt% TY（分子分母） |
| 当前柱期末时点（LY）         | 当前柱所在行**TimeFrame_Max_LY**（LY end period 最后一天，单日时点）                                                                                                              | EOH Amt LY、EOH Amt% LY（分子分母） |
| **全局范围框定（TY）** | data_date ∈**[Slicer_Time_Frame_Min_This[TimeFrame_Min], Slicer_Time_Frame_Max_This[TimeFrame_Max]]**（全局 This Period 区间，与当前柱时间范围取交集）                           | 全部 TY 指标（分子分母）            |
| **全局范围框定（LY）** | data_date ∈**[Slicer_Time_Frame_Min_This[TimeFrame_Min_LY], Slicer_Time_Frame_Max_This[TimeFrame_Max_LY]]**（全局 This Period 区间的**去年同期**，与当前柱 LY 范围取交集） | 全部 LY 指标（分子分母）            |
| 柱子显示范围                 | 当前柱时间单位**完全落在**全局 this period 区间内，且柱子粒度 = 全局所选粒度                                                                                                      | 视觉对象筛选（IsVisible）           |

说明：

- **全局 this period 区间**：This Period = data_date ∈ [Slicer_Time_Frame_Min_This[TimeFrame_Min], Slicer_Time_Frame_Max_This[TimeFrame_Max]]——`Slicer_Time_Frame_Min_This` 与 `Slicer_Time_Frame_Max_This` 两表共同构成一个时间区间，**每个指标度量均叠加该范围框定**（v1.3）
- **LY 指标的框定取全局区间的去年同期**（Min_This[TimeFrame_Min_LY] / Max_This[TimeFrame_Max_LY]，两表均含该预计算字段）——LY 数据位于去年，直接套当前 this period 区间会把 LY 值全部清空
- 全局框定对**可见柱**（IsVisible = 1，柱时间单位完全落在 this period 内）为无操作（柱区间 ⊆ 全局区间），属防御性框定——语义上全局时间筛选器约束每一个指标，视觉筛选之外二次保证数据范围
- **柱子范围与指标计算解耦**：度量按逐柱「当前值」计算（X 轴行上下文）；柱子显示范围由视觉对象筛选度量限定（由于 X 轴用的新日期表与全局日期筛选器为断开维度，全局筛选不自动过滤 X 轴，需度量视觉筛选——参照模版 IsMonthVisible 写法）
- **期末日期直接取日期表预计算值**：「end period 最后一天」= 当前柱所在行 `TimeFrame_Max`（LY 版 = `TimeFrame_Max_LY`），直接单日过滤（v1.2 调整，见注意事项 8）
- 时间为**财年日历**：月柱如 2027-01 对应的 TimeFrame_Min / TimeFrame_Max 为财月区间（如 [2026-12-28, 2027-01-24]），一切以日期表区间为准
- 逐柱区间只取该柱时间单位，柱与柱之间不重叠、不汇总；EOH 快照表按日存储，期末时点只取单日

### 1.4 指标清单（提取 + 新增）

| # | 指标        | 度量值名称                    | 来源                                                                                                   | 数据底表 | 时间口径                                | 计算公式                                                                                     | 数据类型       | 数据格式   |
| - | ----------- | ----------------------------- | ------------------------------------------------------------------------------------------------------ | -------- | --------------------------------------- | -------------------------------------------------------------------------------------------- | -------------- | ---------- |
| 1 | SLS Amt TY  | S&I Trend SLS Amt TY Value    | 提取自表格方案 §4.3（结构一致，时间范围语义由「单选所选行」改为「当前柱所在行 ∩ 全局 this period」） | sales    | 当前柱 TY 区间 ∩ 全局 TY 区间          | sum(net_sales_amt)                                                                           | currency       | `#,##0`  |
| 2 | SLS Amt LY  | S&I Trend SLS Amt LY Value    | 提取自表格方案 §4.7（同上，LY 取当前柱 LY 区间 ∩ 全局 LY 区间）                                      | sales    | 当前柱 LY 区间 ∩ 全局 LY 区间          | sum(net_sales_amt)                                                                           | currency       | `#,##0`  |
| 3 | SLS Amt% TY | S&I Trend SLS Amt% TY Value   | 提取自表格方案 §4.1（分母范围由「所选期间全量」改为「当前柱时间全量」）                               | sales    | 当前柱 TY 区间 ∩ 全局 TY 区间          | 分子 sum(net_sales_amt) / 分母 ALLSELECTED 六维度 sum(net_sales_amt)                         | percent_0dp    | `#,##0%` |
| 4 | SLS Amt% LY | S&I Trend SLS Amt% LY Value   | **新增**（表格方案无 LY 占比）                                                                   | sales    | 当前柱 LY 区间 ∩ 全局 LY 区间          | 分子 sum(net_sales_amt) / 分母 ALLSELECTED 六维度 sum(net_sales_amt)                         | percent_0dp    | `#,##0%` |
| 5 | EOH Amt TY  | S&I Trend EOH Amt TY Value    | 提取自表格方案 §4.14（期末日期直接取当前柱 TimeFrame_Max，单日满足全局 TY 区间框定）                  | inv      | 当前柱 TimeFrame_Max ∩ 全局 TY 区间    | sum(msrp_inv_amt)（单日）                                                                    | currency       | `#,##0`  |
| 6 | EOH Amt LY  | S&I Trend EOH Amt LY Value    | 提取自表格方案 §4.18（同上，取当前柱 TimeFrame_Max_LY，单日满足全局 LY 区间框定）                     | inv      | 当前柱 TimeFrame_Max_LY ∩ 全局 LY 区间 | sum(msrp_inv_amt)（单日）                                                                    | currency       | `#,##0`  |
| 7 | EOH Amt% TY | S&I Trend EOH Amt% TY Value   | 提取自表格方案 §4.12（分母期末日期直接取当前柱 TimeFrame_Max）                                        | inv      | 当前柱 TimeFrame_Max ∩ 全局 TY 区间    | 分子 sum(msrp_inv_amt) / 分母 ALLSELECTED 六维度 sum(msrp_inv_amt)（同为当前柱期末单日）     | percent_0dp    | `#,##0%` |
| 8 | EOH Amt% LY | S&I Trend EOH Amt% LY Value   | **新增**（表格方案无 EOH Amt% LY）                                                               | inv      | 当前柱 TimeFrame_Max_LY ∩ 全局 LY 区间 | 分子 sum(msrp_inv_amt) / 分母 ALLSELECTED 六维度 sum(msrp_inv_amt)（同为当前柱 LY 期末单日） | percent_0dp    | `#,##0%` |
| 9 | 柱子可见性  | S&I Trend TimeFrame IsVisible | 新增（视觉对象筛选度量，参照模版 §1.1 IsMonthVisible）                                                | —       | 全局 this period + 粒度                 | 当前柱时间单位落在全局区间内且粒度一致 → 1                                                  | integer（0/1） | 不展示     |

**SLS Amt% 占比口径（本次关键差异）**：单个商品占**当前柱子时间**的所有商品的比值——分母只覆盖当前柱的时间单位（如 2027-01 柱的分母 = 2027-01 区间内全部商品合计），而非整个 this period 或整个图表范围；各柱占比独立成立，单柱内图例各商品占比之和 = 100%。

**EOH Amt% 占比口径（原始口径 §10）**：根据所筛选维度统计对应 EOH amt 占比——分子：各 label / super_season / product_type / category / md_type / division 下，当前柱 end period 最后一天（TimeFrame_Max）sum(msrp_inv_amt)；分母：当前柱 end period 最后一天 sum(msrp_inv_amt)（ALLSELECTED 六维度）——同为当前柱期末单日值，单柱内图例各商品占比之和 = 100%；LY 版整体替换为当前柱 TimeFrame_Max_LY。

---

## 2. 现状分析

- 数据底表 `a02_e2e_product_performance_sales_summary_d`（日粒度）：net_sales_amt（净销售金额）；维度含 platform、shop_name 及 brand / super_season / product_type / category / md_type / division 等全部商品维度；日期字段为 data_date（date 类型）；platform 已在数据源层过滤 IN ('JD','TM','RLE','DY')
- 数据底表 `a02_e2e_product_performance_inv_summary_d`（日快照）：msrp_inv_amt（库存吊牌价金额，期末库存金额口径）、inv_qty（库存数量）；商品维度字段与 sales 表同名同构；**无 platform / shop_name 字段**（渠道筛选不影响 EOH 侧指标）；日期字段为 data_date（date 类型）
- `Slicer_Time_Frame_Sales_Trend`（新日期表，本板块表格方案引入）：单表含 TimeFrame_ID（Week / Month / Year，Day / Quarter 已在 Power Query 过滤）、TimeFrame_Value（X 轴字段）、TimeFrame_Min / TimeFrame_Max（逐柱 TY 区间与期末日期）、TimeFrame_Min_LY / TimeFrame_Max_LY（逐柱 LY 区间与 LY 期末日期，表内预计算）、ID_Sort（排序）等字段；与事实表及全局日期筛选器均为**断开维度**，时间过滤全部由度量内 data_date 谓词显式完成
- 全局日期体系（同页签其余模块共用）：`Slicer_Time_Frame`（主时间筛选器，含 TimeFrame_ID 粒度）、`Slicer_Time_Frame_Min_This` / `Max_This`（this period 区间端点表，经模型关系由主筛选器驱动，**两表均含 TimeFrame_Min / TimeFrame_Max / TimeFrame_Min_LY / TimeFrame_Max_LY 字段**）——this period = [Min_This[TimeFrame_Min], Max_This[TimeFrame_Max]]（TY 框定区间），其去年同期 = [Min_This[TimeFrame_Min_LY], Max_This[TimeFrame_Max_LY]]（LY 框定区间），粒度 = SELECTEDVALUE(Slicer_Time_Frame[TimeFrame_ID])
- **全局日期筛选器不会过滤新日期表的 X 轴**（两套日期表断开）——这正是需要「日期筛选器展示值是否在范围内」度量做视觉对象筛选的原因（模版 §1.1 IsMonthVisible 同款场景：轴表与筛选表断开，用度量逐行判定显示 / 隐藏）；指标数据范围由各度量内的全局区间谓词显式框定
- 六个商品维度表与 sales / inv 两张事实表均一对多关联：图例字段从维度表拉取，图例筛选经模型关系自动传导（SLS 侧到 sales、EOH 侧到 inv，均无需 TREATAS）；Slicer_Platform_Selection / Slicer_Store_Name 与 sales 表一对多关联，渠道筛选自动传递（仅影响 SLS 侧，EOH 侧不受影响）
- `Slicer_Currency_Selection`：RMB（汇率 = 1）/ USD（动态汇率），底表金额仅存 CNY
- 口径中的 "label" 维度对应事实表字段 `brand`（Slicer_Label[label] 由 brand distinct 生成）

---

## 3. 方案设计

### 3.1 度量值分层

```
Value 度量（8 个：SLS Amt TY / LY、SLS Amt% TY / LY、EOH Amt TY / LY、EOH Amt% TY / LY）
←  逐柱「当前值」：X 轴行上下文 SELECTEDVALUE 取当前柱 TimeFrame_Min / Max（TY）
   与 TimeFrame_Min_LY / Max_LY（LY），以 data_date 谓词显式过滤事实表
←  全局 this period 区间框定（v1.3）：TY 指标叠加 [Min_This[TimeFrame_Min], Max_This[TimeFrame_Max]]，
   LY 指标叠加其去年同期 [Min_This[TimeFrame_Min_LY], Max_This[TimeFrame_Max_LY]]
   ——与当前柱范围取交集；可见柱下为无操作（防御性框定）
←  SLS 侧（区间类）：逐柱区间求 sum(net_sales_amt)
←  EOH 侧（期末时点类）：逐柱取 TimeFrame_Max / TimeFrame_Max_LY（end period 最后一天）
   直接单日过滤 inv 表（单日同样满足全局区间框定）
←  图例维度筛选经维度表 1:N 关系自动传导（无需 TREATAS）
←  SLS Amt% / EOH Amt% 分母：ALLSELECTED 六个商品维度表字段（移除图例视觉筛选，
   保留外部切片器）× 当前柱时间范围（SLS 为柱区间、EOH 为柱期末单日）
   → 单个商品占当前柱时间所有商品的比值
←  currency 4 个（SLS Amt / EOH Amt 各 TY / LY）Value 层完成汇率换算
   （原始 CNY ÷ Currency_ExchangeRate）——柱形图 Y 轴需数值度量，
   不输出 Display 文本度量（动态币种符号无法用于轴）
↓
IsVisible 视觉对象筛选度量（1 个）
←  当前柱时间单位完全落在全局 this period [Min_This, Max_This] 内
   且柱子粒度 = 全局所选粒度 → 1（显示）；否则 0（隐藏）
←  参照模版 §1.1 IsMonthVisible（轴表断开 → 度量视觉筛选限定柱子范围）
```

### 3.2 逐柱「当前值」+ 全局区间框定机制

- X 轴按 `TimeFrame_Value` 分组：每根柱子的计算上下文中，`Slicer_Time_Frame_Sales_Trend` 被筛选到当前柱所在行（单行），度量内 `SELECTEDVALUE` 逐柱读取该行的 TY / LY 区间与期末日期字段
- **全局 this period 区间框定（v1.3）**：每个指标度量在当前柱「当前值」范围之上，叠加全局区间约束——TY 指标用 `data_date ∈ [Slicer_Time_Frame_Min_This[TimeFrame_Min], Slicer_Time_Frame_Max_This[TimeFrame_Max]]`（全局 This Period），LY 指标用其去年同期 `data_date ∈ [Slicer_Time_Frame_Min_This[TimeFrame_Min_LY], Slicer_Time_Frame_Max_This[TimeFrame_Max_LY]]`——与柱范围取交集；可见柱（IsVisible = 1）下柱区间 ⊆ 全局区间，框定为无操作（防御性），确保指标数据不逸出全局时间筛选器范围
- **EOH 侧期末日期**：`__EndPeriodDate` = 当前柱所在行 `TimeFrame_Max`（口径「end period 最后一天」，日期表预计算），直接以 `inv[data_date] = __EndPeriodDate` 单日过滤（该单日同时满足全局区间谓词）；LY 版 = `TimeFrame_Max_LY`——单选日期表行内即「当前值」，无需在事实表中检索快照日（v1.2 调整）
- 前提：**Slicer_Time_Frame_Sales_Trend 单选切片器（表格侧日期筛选）对本柱形图的编辑交互必须设为「无」**——否则切片器会把 X 轴过滤为单柱，趋势失效（见注意事项 5）
- 全局日期筛选器（Slicer_Time_Frame）对柱形图保持默认交互：其经 Min_This / Max_This / TimeFrame_ID 被 IsVisible 度量与全部指标度量的全局区间框定读取，驱动柱子范围与数据范围
- 柱与柱独立计算、互不影响；逐柱区间无重叠（财月 / 财周 / 财年区间互斥）

### 3.3 占比分母机制（当前柱时间范围内全量）

| 指标        | 分子                                                                                 | 分母                                                                                |
| ----------- | ------------------------------------------------------------------------------------ | ----------------------------------------------------------------------------------- |
| SLS Amt% TY | 当前柱 TY 区间 ∩ 全局 TY 区间 × 图例商品维度 sum(net_sales_amt)                    | ALLSELECTED 六表 +**当前柱 TY 区间 ∩ 全局 TY 区间** sum(net_sales_amt)       |
| SLS Amt% LY | 当前柱 LY 区间 ∩ 全局 LY 区间 × 图例商品维度 sum(net_sales_amt)                    | ALLSELECTED 六表 +**当前柱 LY 区间 ∩ 全局 LY 区间** sum(net_sales_amt)       |
| EOH Amt% TY | 当前柱期末（TimeFrame_Max，∈ 全局 TY 区间）× 图例商品维度 sum(msrp_inv_amt)        | ALLSELECTED 六表 +**当前柱期末单日（∈ 全局 TY 区间）** sum(msrp_inv_amt)     |
| EOH Amt% LY | 当前柱 LY 期末（TimeFrame_Max_LY，∈ 全局 LY 区间）× 图例商品维度 sum(msrp_inv_amt) | ALLSELECTED 六表 +**当前柱 LY 期末单日（∈ 全局 LY 区间）** sum(msrp_inv_amt) |

```dax
ALLSELECTED('Slicer_Label'[label]),
ALLSELECTED('Slicer_Super_Season'[super_season]),
ALLSELECTED('Slicer_Product_Type'[product_type]),
ALLSELECTED('Slicer_Category'[category]),
ALLSELECTED('Slicer_Md_Type'[md_type]),
ALLSELECTED('Slicer_Division'[division])
```

- 分母对六个商品维度表字段同时 `ALLSELECTED`：图例当前字段（六选一）的视觉对象内部图例筛选被移除，恢复为外部切片器筛选状态；其余五个未上图例字段的 ALLSELECTED 为无操作——**无论图例切换到哪个维度，一个度量即可覆盖六个维度**
- **与表格方案占比分母范围差异**：表格方案分母 = 单选所选期间全量（整个 this period / 所选期末）；本方案分母 = **当前柱时间范围**（SLS 为柱区间、EOH 为柱期末单日）——同一图例商品在不同柱子的占比分母不同，单柱内图例各商品占比之和 = 100%
- ALLSELECTED 仅移除视觉对象内部图例筛选、保留外部切片器（与 REMOVEFILTERS 的语义差异是分母正确性的关键，同 Label & PT / 表格方案沉淀）
- SLS Amt% 分子分母同为 sales 侧（同受渠道筛选，比率语义不受影响）；EOH Amt% 分子分母同为 inv 侧（**均不受渠道筛选**，inv 表无渠道字段）

### 3.4 视觉对象筛选机制（IsVisible，模版 §1.1 对照）

| 模版 IsMonthVisible                                    | 本方案 S&I Trend TimeFrame IsVisible                                                           |
| ------------------------------------------------------ | ---------------------------------------------------------------------------------------------- |
| 轴表 Slicer_Month_Period（月）                         | 轴表 Slicer_Time_Frame_Sales_Trend（Week / Month / Year 混合）                                 |
| 起止切片器表 Slicer_Month_Period_Min / Max（Key 比较） | 全局日期体系 Min_This / Max_This（**日期区间**比较，避免跨粒度 Key 不可比）              |
| 无粒度条件（表本身只有月）                             | **新增粒度一致条件**：柱子 TimeFrame_ID = 全局所选粒度（否则同区间内周 / 月 / 年柱混杂） |
| 未选择时默认全显                                       | 同（全局 this period 未选择时返回 1，确保全部显示）                                            |
| 用法：视觉对象级别筛选 = 1                             | 同                                                                                             |

判定逻辑：`当前柱 TimeFrame_Min >= ThisMin && 当前柱 TimeFrame_Max <= ThisMax（时间单位完全落在 this period 内）&& 当前柱 TimeFrame_ID = 全局粒度 → 1`。

### 3.5 度量值命名与组织

- 命名规则：模块前缀 `S&I Trend` + 指标名（含 TY / LY 后缀）+ 层次后缀 Value；视觉筛选度量命名为 `S&I Trend TimeFrame IsVisible`
- Display Folder：`Sales & Inventory Penetration Trend\Trend Base Metrics`（8 个指标度量）与 `Sales & Inventory Penetration Trend\Visual Filters`（IsVisible，沿用模版 Visual Filters 命名）
- 度量值统一存放于 `_Measures` 隐藏表

---

## 4. 度量值实现

### 4.1 S&I Trend SLS Amt TY Value（净销售额 TY，当前柱）

```dax
S&I Trend SLS Amt TY Value =
// ========================================
// 度量值: S&I Trend SLS Amt TY Value
// 中文名: DCom净销售额（TY，当前柱）
// Display Folder: Sales & Inventory Penetration Trend\Trend Base Metrics
// 用途: 柱形图 Y 轴——当前柱（X 轴遍历行）时间单位内的 DCom净销售额（TY），
//       图例商品维度 × 柱时间单位单元格取值
// 依赖: Slicer_Time_Frame_Sales_Trend[TimeFrame_Min] / [TimeFrame_Max]
//       （X 轴行上下文 = 当前柱所在行，即「当前值」；
//        单选切片器对本图交互需设为「无」，见注意事项 5）；
//       Slicer_Time_Frame_Min_This[TimeFrame_Min] / Slicer_Time_Frame_Max_This[TimeFrame_Max]
//       （全局 this period 区间范围框定）
// 口径: 提取自 Sales_&_Inventory_Table.md §4.3（SLS Amt TY Value），DAX 结构一致，
//       时间范围语义由「单选所选行」改为「当前柱所在行」，
//       并叠加全局 this period 区间框定（与当前柱区间取交集）
// 数据底表: a02_e2e_product_performance_sales_summary_d
// 全局框定: data_date 同时尚 ∈ [Min_This[TimeFrame_Min], Max_This[TimeFrame_Max]]——
//       可见柱（IsVisible = 1，完全落在 this period 内）下为无操作（防御性框定），
//       确保指标数据始终受全局时间筛选器约束
// 币种: 数据底表仅存 CNY，Value 层换算为当前币种金额（原始值 ÷ 汇率，
//       RMB 汇率 = 1 时换算前后值相同）；柱形图 Y 轴需数值度量，
//       不输出 Display 文本度量（动态币种符号无法用于轴）
// 说明: sales 侧指标，受渠道筛选影响（platform / shop_name）
// 数据类型: currency；数据格式: #,##0（度量值静态格式，轴 / 数据标签直接使用）
// ========================================

// ── 当前柱时间区间（X 轴行上下文，即「当前值」）──
VAR __PeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Sales_Trend[TimeFrame_Min])
VAR __PeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Sales_Trend[TimeFrame_Max])

// ── 全局 this period 区间（全局时间筛选器范围框定）──
VAR __ThisMin = SELECTEDVALUE(Slicer_Time_Frame_Min_This[TimeFrame_Min])
VAR __ThisMax = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

// ── 币种汇率（RMB = 1；USD 动态取自数仓汇率表）──
VAR __ExchangeRate = SELECTEDVALUE(Slicer_Currency_Selection[Currency_ExchangeRate], 1)

// ── 当前柱时间单位净销售金额（原始 CNY，柱区间 ∩ 全局区间）──
VAR __BaseValue =
    CALCULATE(
        SUM('a02_e2e_product_performance_sales_summary_d'[net_sales_amt]),
        'a02_e2e_product_performance_sales_summary_d'[data_date] >= __PeriodMin,
        'a02_e2e_product_performance_sales_summary_d'[data_date] <= __PeriodMax,
        'a02_e2e_product_performance_sales_summary_d'[data_date] >= __ThisMin,
        'a02_e2e_product_performance_sales_summary_d'[data_date] <= __ThisMax
    )

RETURN
    DIVIDE(__BaseValue, __ExchangeRate)   // BLANK ÷ 汇率 = BLANK（该柱该商品无销售数据返回空）
```

### 4.2 S&I Trend SLS Amt LY Value（净销售额 LY，当前柱）

```dax
S&I Trend SLS Amt LY Value =
// ========================================
// 度量值: S&I Trend SLS Amt LY Value
// 中文名: DCom净销售额（LY，当前柱）
// Display Folder: Sales & Inventory Penetration Trend\Trend Base Metrics
// 用途: 柱形图 Y 轴——当前柱对应去年同期时间单位内的 DCom净销售额（LY）
// 依赖: Slicer_Time_Frame_Sales_Trend[TimeFrame_Min_LY] / [TimeFrame_Max_LY]
//       （当前柱所在行的表内预计算 LY 区间，即「当前值」的去年同期）；
//       Slicer_Time_Frame_Min_This[TimeFrame_Min_LY] / Slicer_Time_Frame_Max_This[TimeFrame_Max_LY]
//       （全局 this period 区间的去年同期，LY 指标范围框定）
// 口径: 提取自 Sales_&_Inventory_Table.md §4.7（SLS Amt LY Value），DAX 结构一致，
//       时间范围语义由「单选所选行」改为「当前柱所在行」，
//       并叠加全局 LY 区间框定（与当前柱 LY 区间取交集）
// 全局框定说明: LY 数据位于去年，直接套当前 this period 区间会把 LY 值全部清空，
//       故取全局 this period 区间的去年同期 [Min_This[TimeFrame_Min_LY], Max_This[TimeFrame_Max_LY]]
// 数据底表: a02_e2e_product_performance_sales_summary_d
// 币种: 数据底表仅存 CNY，Value 层换算为当前币种金额（原始值 ÷ 汇率）
// 说明: sales 侧指标，受渠道筛选影响
// 数据类型: currency；数据格式: #,##0（度量值静态格式，轴 / 数据标签直接使用）
// ========================================

// ── 当前柱 LY 时间区间（当前柱所在行的表内预计算去年同期）──
VAR __PeriodMinLY = SELECTEDVALUE(Slicer_Time_Frame_Sales_Trend[TimeFrame_Min_LY])
VAR __PeriodMaxLY = SELECTEDVALUE(Slicer_Time_Frame_Sales_Trend[TimeFrame_Max_LY])

// ── 全局 LY 区间（全局 this period 的去年同期，LY 指标范围框定）──
VAR __ThisMinLY = SELECTEDVALUE(Slicer_Time_Frame_Min_This[TimeFrame_Min_LY])
VAR __ThisMaxLY = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max_LY])

// ── 币种汇率（RMB = 1；USD 动态取自数仓汇率表）──
VAR __ExchangeRate = SELECTEDVALUE(Slicer_Currency_Selection[Currency_ExchangeRate], 1)

// ── 当前柱 LY 时间单位净销售金额（原始 CNY，柱 LY 区间 ∩ 全局 LY 区间）──
VAR __BaseValue =
    CALCULATE(
        SUM('a02_e2e_product_performance_sales_summary_d'[net_sales_amt]),
        'a02_e2e_product_performance_sales_summary_d'[data_date] >= __PeriodMinLY,
        'a02_e2e_product_performance_sales_summary_d'[data_date] <= __PeriodMaxLY,
        'a02_e2e_product_performance_sales_summary_d'[data_date] >= __ThisMinLY,
        'a02_e2e_product_performance_sales_summary_d'[data_date] <= __ThisMaxLY
    )

RETURN
    DIVIDE(__BaseValue, __ExchangeRate)   // BLANK ÷ 汇率 = BLANK（该柱该商品 LY 无销售数据返回空）
```

### 4.3 S&I Trend SLS Amt% TY Value（销售金额占比 TY，当前柱）

```dax
S&I Trend SLS Amt% TY Value =
// ========================================
// 度量值: S&I Trend SLS Amt% TY Value
// 中文名: 销售金额占比（TY，当前柱）
// Display Folder: Sales & Inventory Penetration Trend\Trend Base Metrics
// 用途: 柱形图 Y 轴主指标——单个商品占【当前柱子时间】的所有商品的销售金额比值（TY）
// 依赖: Slicer_Time_Frame_Sales_Trend[TimeFrame_Min] / [TimeFrame_Max]
//       （X 轴行上下文 = 当前柱所在行，即「当前值」）；
//       Slicer_Time_Frame_Min_This[TimeFrame_Min] / Slicer_Time_Frame_Max_This[TimeFrame_Max]
//       （全局 this period 区间范围框定，分子分母同时叠加）
// 口径: 提取自 Sales_&_Inventory_Table.md §4.1（SLS Amt% Value），DAX 结构一致；
//       分母范围由「单选所选期间全量」改为「当前柱时间单位全量」
//       （原始口径 §1：单品类占总品类的比例 → 逐柱独立成立，单柱内图例占比之和 = 100%）
// 数据底表: a02_e2e_product_performance_sales_summary_d
// 分母机制: ALLSELECTED 六个商品维度表字段——移除视觉对象内部的图例维度筛选，
//       保留外部切片器筛选；一次只有一个字段在图例上，其余五个字段为无操作，
//       实现六维度图例切换一套逻辑通吃；分母时间范围 = 当前柱 TY 区间 ∩ 全局 TY 区间
// 币种: 分子分母为同表同币种金额（底表 CNY），占比不受币种选择影响
// 说明: sales 侧指标，分子分母同受渠道筛选，比率语义不受影响
// 数据类型: percent_0dp；数据格式: #,##0%（不含正号，度量值静态格式）
// ========================================

// ── 当前柱时间区间（X 轴行上下文，即「当前值」）──
VAR __PeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Sales_Trend[TimeFrame_Min])
VAR __PeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Sales_Trend[TimeFrame_Max])

// ── 全局 this period 区间（全局时间筛选器范围框定）──
VAR __ThisMin = SELECTEDVALUE(Slicer_Time_Frame_Min_This[TimeFrame_Min])
VAR __ThisMax = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

// ── 分子：当前柱 TY 区间 × 图例商品维度净销售金额 ──
VAR __Numerator =
    CALCULATE(
        SUM('a02_e2e_product_performance_sales_summary_d'[net_sales_amt]),
        'a02_e2e_product_performance_sales_summary_d'[data_date] >= __PeriodMin,
        'a02_e2e_product_performance_sales_summary_d'[data_date] <= __PeriodMax,
        'a02_e2e_product_performance_sales_summary_d'[data_date] >= __ThisMin,
        'a02_e2e_product_performance_sales_summary_d'[data_date] <= __ThisMax
    )

// ── 分母：当前柱 TY 区间内全部商品合计（移除图例筛选，保留外部切片器）──
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
        'a02_e2e_product_performance_sales_summary_d'[data_date] <= __PeriodMax,
        'a02_e2e_product_performance_sales_summary_d'[data_date] >= __ThisMin,
        'a02_e2e_product_performance_sales_summary_d'[data_date] <= __ThisMax
    )

RETURN
    DIVIDE(__Numerator, __Denominator)
```

### 4.4 S&I Trend SLS Amt% LY Value（销售金额占比 LY，当前柱，新增）

```dax
S&I Trend SLS Amt% LY Value =
// ========================================
// 度量值: S&I Trend SLS Amt% LY Value
// 中文名: 销售金额占比（LY，当前柱）
// Display Folder: Sales & Inventory Penetration Trend\Trend Base Metrics
// 用途: 柱形图 Y 轴——单个商品占【当前柱子 LY 时间】的所有商品的销售金额比值（LY，
//       与 TY 占比同构，时间范围替换为当前柱所在行的表内预计算 LY 区间）
// 依赖: Slicer_Time_Frame_Sales_Trend[TimeFrame_Min_LY] / [TimeFrame_Max_LY]
//       （当前柱所在行的表内预计算 LY 区间）；
//       Slicer_Time_Frame_Min_This[TimeFrame_Min_LY] / Slicer_Time_Frame_Max_This[TimeFrame_Max_LY]
//       （全局 this period 区间的去年同期，LY 指标范围框定，分子分母同时叠加）
// 口径: 表格方案未含 LY 占比，本次新增；公式与 S&I Trend SLS Amt% TY Value 同构，
//       仅时间区间整体替换为当前柱 LY 区间 ∩ 全局 LY 区间
// 全局框定说明: LY 数据位于去年，取全局 this period 区间的去年同期框定
//       （直接套当前区间会把 LY 值全部清空）
// 数据底表: a02_e2e_product_performance_sales_summary_d
// 分母机制: 同 S&I Trend SLS Amt% TY Value（ALLSELECTED 六维度 + 柱 LY 区间 ∩ 全局 LY 区间）
// 币种: 分子分母为同表同币种金额（底表 CNY），占比不受币种选择影响
// 数据类型: percent_0dp；数据格式: #,##0%（不含正号，度量值静态格式）
// ========================================

// ── 当前柱 LY 时间区间（当前柱所在行的表内预计算去年同期）──
VAR __PeriodMinLY = SELECTEDVALUE(Slicer_Time_Frame_Sales_Trend[TimeFrame_Min_LY])
VAR __PeriodMaxLY = SELECTEDVALUE(Slicer_Time_Frame_Sales_Trend[TimeFrame_Max_LY])

// ── 全局 LY 区间（全局 this period 的去年同期，LY 指标范围框定）──
VAR __ThisMinLY = SELECTEDVALUE(Slicer_Time_Frame_Min_This[TimeFrame_Min_LY])
VAR __ThisMaxLY = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max_LY])

// ── 分子：当前柱 LY 区间 × 图例商品维度净销售金额 ──
VAR __Numerator =
    CALCULATE(
        SUM('a02_e2e_product_performance_sales_summary_d'[net_sales_amt]),
        'a02_e2e_product_performance_sales_summary_d'[data_date] >= __PeriodMinLY,
        'a02_e2e_product_performance_sales_summary_d'[data_date] <= __PeriodMaxLY,
        'a02_e2e_product_performance_sales_summary_d'[data_date] >= __ThisMinLY,
        'a02_e2e_product_performance_sales_summary_d'[data_date] <= __ThisMaxLY
    )

// ── 分母：当前柱 LY 区间内全部商品合计（移除图例筛选，保留外部切片器）──
VAR __Denominator =
    CALCULATE(
        SUM('a02_e2e_product_performance_sales_summary_d'[net_sales_amt]),
        ALLSELECTED('Slicer_Label'[label]),
        ALLSELECTED('Slicer_Super_Season'[super_season]),
        ALLSELECTED('Slicer_Product_Type'[product_type]),
        ALLSELECTED('Slicer_Category'[category]),
        ALLSELECTED('Slicer_Md_Type'[md_type]),
        ALLSELECTED('Slicer_Division'[division]),
        'a02_e2e_product_performance_sales_summary_d'[data_date] >= __PeriodMinLY,
        'a02_e2e_product_performance_sales_summary_d'[data_date] <= __PeriodMaxLY,
        'a02_e2e_product_performance_sales_summary_d'[data_date] >= __ThisMinLY,
        'a02_e2e_product_performance_sales_summary_d'[data_date] <= __ThisMaxLY
    )

RETURN
    DIVIDE(__Numerator, __Denominator)
```

### 4.5 S&I Trend EOH Amt TY Value（期末库存金额 TY，当前柱）

```dax
S&I Trend EOH Amt TY Value =
// ========================================
// 度量值: S&I Trend EOH Amt TY Value
// 中文名: 期末库存金额（TY，当前柱）
// Display Folder: Sales & Inventory Penetration Trend\Trend Base Metrics
// 用途: 柱形图 Y 轴——当前柱（X 轴遍历行）end period 最后一天（= 当前柱所在行
//       TimeFrame_Max）的 EOH 期末库存金额（= EOH Units × msrp），
//       图例商品维度 × 柱期末单日单元格取值
// 依赖: Slicer_Time_Frame_Sales_Trend[TimeFrame_Max]
//       （X 轴行上下文 = 当前柱所在行，即「当前值」）；
//       Slicer_Time_Frame_Min_This[TimeFrame_Min] / Slicer_Time_Frame_Max_This[TimeFrame_Max]
//       （全局 this period 区间范围框定）
// 口径: 提取自 Sales_&_Inventory_Table.md §4.14（EOH Amt TY Value），DAX 结构一致；
//       期末日期直接取当前柱 TimeFrame_Max（口径「end period 最后一天」），
//       以 inv[data_date] = TimeFrame_Max 单日过滤，单日同时满足全局区间框定
// 数据底表: a02_e2e_product_performance_inv_summary_d
// 期末机制: end period 最后一天 = 当前柱所在行 TimeFrame_Max（日期表预计算），
//       直接单日过滤，无需在事实表中检索快照日（v1.2 调整，见注意事项 8）；
//       该单日 ∈ [Min_This[TimeFrame_Min], Max_This[TimeFrame_Max]]（可见柱下必然满足，
//       防御性框定）
// 币种: 数据底表仅存 CNY，Value 层换算为当前币种金额（原始值 ÷ 汇率）；
//       柱形图 Y 轴需数值度量，不输出 Display 文本度量
// 说明: inv 表无 platform / shop_name 字段，本指标不受渠道筛选影响
// 数据类型: currency；数据格式: #,##0（度量值静态格式，轴 / 数据标签直接使用）
// ========================================

// ── 当前柱期末日期（end period 最后一天 = 当前柱所在行 TimeFrame_Max）──
VAR __EndPeriodDate = SELECTEDVALUE(Slicer_Time_Frame_Sales_Trend[TimeFrame_Max])

// ── 全局 this period 区间（全局时间筛选器范围框定）──
VAR __ThisMin = SELECTEDVALUE(Slicer_Time_Frame_Min_This[TimeFrame_Min])
VAR __ThisMax = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

// ── 币种汇率（RMB = 1；USD 动态取自数仓汇率表）──
VAR __ExchangeRate = SELECTEDVALUE(Slicer_Currency_Selection[Currency_ExchangeRate], 1)

// ── 当前柱期末库存金额（原始 CNY，期末单日值 ∈ 全局区间）──
VAR __BaseValue =
    CALCULATE(
        SUM('a02_e2e_product_performance_inv_summary_d'[msrp_inv_amt]),
        'a02_e2e_product_performance_inv_summary_d'[data_date] = __EndPeriodDate,
        'a02_e2e_product_performance_inv_summary_d'[data_date] >= __ThisMin,
        'a02_e2e_product_performance_inv_summary_d'[data_date] <= __ThisMax
    )

RETURN
    DIVIDE(__BaseValue, __ExchangeRate)   // BLANK ÷ 汇率 = BLANK（该柱该商品期末无库存数据返回空）
```

### 4.6 S&I Trend EOH Amt LY Value（期末库存金额 LY，当前柱）

```dax
S&I Trend EOH Amt LY Value =
// ========================================
// 度量值: S&I Trend EOH Amt LY Value
// 中文名: 期末库存金额（LY，当前柱）
// Display Folder: Sales & Inventory Penetration Trend\Trend Base Metrics
// 用途: 柱形图 Y 轴——当前柱对应去年同期 end period 最后一天的 EOH 期末库存金额
// 依赖: Slicer_Time_Frame_Sales_Trend[TimeFrame_Max_LY]
//       （当前柱所在行的表内预计算 LY 期末日期）；
//       Slicer_Time_Frame_Min_This[TimeFrame_Min_LY] / Slicer_Time_Frame_Max_This[TimeFrame_Max_LY]
//       （全局 this period 区间的去年同期，LY 指标范围框定）
// 口径: 提取自 Sales_&_Inventory_Table.md §4.18（EOH Amt LY Value），DAX 结构一致；
//       期末日期直接取当前柱所在行 TimeFrame_Max_LY（LY end period 最后一天）单日过滤，
//       单日同时满足全局 LY 区间框定
// 全局框定说明: LY 数据位于去年，取全局 this period 区间的去年同期框定
//       （直接套当前区间会把 LY 值全部清空）
// 数据底表: a02_e2e_product_performance_inv_summary_d
// 期末机制: 同 EOH Amt TY（直接单日过滤，无快照日回退）
// 币种: 数据底表仅存 CNY，Value 层换算为当前币种金额（原始值 ÷ 汇率）
// 说明: inv 表无渠道字段，本指标不受渠道筛选影响
// 数据类型: currency；数据格式: #,##0（度量值静态格式，轴 / 数据标签直接使用）
// ========================================

// ── 当前柱 LY 期末日期（LY end period 最后一天 = 当前柱所在行 TimeFrame_Max_LY）──
VAR __EndPeriodDateLY = SELECTEDVALUE(Slicer_Time_Frame_Sales_Trend[TimeFrame_Max_LY])

// ── 全局 LY 区间（全局 this period 的去年同期，LY 指标范围框定）──
VAR __ThisMinLY = SELECTEDVALUE(Slicer_Time_Frame_Min_This[TimeFrame_Min_LY])
VAR __ThisMaxLY = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max_LY])

// ── 币种汇率（RMB = 1；USD 动态取自数仓汇率表）──
VAR __ExchangeRate = SELECTEDVALUE(Slicer_Currency_Selection[Currency_ExchangeRate], 1)

// ── 当前柱 LY 期末库存金额（原始 CNY，LY 期末单日值 ∈ 全局 LY 区间）──
VAR __BaseValue =
    CALCULATE(
        SUM('a02_e2e_product_performance_inv_summary_d'[msrp_inv_amt]),
        'a02_e2e_product_performance_inv_summary_d'[data_date] = __EndPeriodDateLY,
        'a02_e2e_product_performance_inv_summary_d'[data_date] >= __ThisMinLY,
        'a02_e2e_product_performance_inv_summary_d'[data_date] <= __ThisMaxLY
    )

RETURN
    DIVIDE(__BaseValue, __ExchangeRate)   // BLANK ÷ 汇率 = BLANK（该柱该商品 LY 期末无库存数据返回空）
```

### 4.7 S&I Trend EOH Amt% TY Value（期末库存金额占比 TY，当前柱）

```dax
S&I Trend EOH Amt% TY Value =
// ========================================
// 度量值: S&I Trend EOH Amt% TY Value
// 中文名: 期末库存金额占比（TY，当前柱）
// Display Folder: Sales & Inventory Penetration Trend\Trend Base Metrics
// 用途: 柱形图 Y 轴主指标——单个商品占【当前柱子期末最后一天】的所有商品的
//       期末库存金额比值（TY）
// 依赖: Slicer_Time_Frame_Sales_Trend[TimeFrame_Max]
//       （X 轴行上下文 = 当前柱所在行，即「当前值」）；
//       Slicer_Time_Frame_Min_This[TimeFrame_Min] / Slicer_Time_Frame_Max_This[TimeFrame_Max]
//       （全局 this period 区间范围框定，分子分母同时叠加）
// 口径: 提取自 Sales_&_Inventory_Table.md §4.12（EOH Amt% Value），DAX 结构一致；
//       分母期末日期由「所选期间回退快照日」改为「当前柱 TimeFrame_Max」
//       （原始口径 §10：分子 = 各 label / super_season / product_type / category /
//        md_type / division 下，看所选时间范围 end period 最后一天，sum(msrp_inv_amt)；
//        分母 = 看所选时间范围 end period 最后一天，sum(msrp_inv_amt)——
//        逐柱独立成立，单柱内图例占比之和 = 100%）
// 数据底表: a02_e2e_product_performance_inv_summary_d
// 期末机制: __EndPeriodDate = 当前柱所在行 TimeFrame_Max（直接单日过滤，
//       分子分母共用同一期末日期，v1.2 调整无快照日回退；
//       该单日 ∈ 全局 TY 区间，可见柱下必然满足，防御性框定）
// 分母机制: ALLSELECTED 六个商品维度表字段——移除视觉对象内部的图例维度筛选，
//       保留外部切片器筛选；一次只有一个字段在图例上，其余五个字段为无操作，
//       实现六维度图例切换一套逻辑通吃
// 币种: 分子分母为同表同币种金额（底表 CNY），占比不受币种选择影响
// 说明: inv 表无渠道字段，本指标分子分母均不受渠道筛选影响
// 数据类型: percent_0dp；数据格式: #,##0%（不含正号，度量值静态格式）
// ========================================

// ── 当前柱期末日期（end period 最后一天 = 当前柱所在行 TimeFrame_Max）──
VAR __EndPeriodDate = SELECTEDVALUE(Slicer_Time_Frame_Sales_Trend[TimeFrame_Max])

// ── 全局 this period 区间（全局时间筛选器范围框定）──
VAR __ThisMin = SELECTEDVALUE(Slicer_Time_Frame_Min_This[TimeFrame_Min])
VAR __ThisMax = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

// ── 分子：当前柱期末 × 图例商品维度期末库存金额 ──
VAR __Numerator =
    CALCULATE(
        SUM('a02_e2e_product_performance_inv_summary_d'[msrp_inv_amt]),
        'a02_e2e_product_performance_inv_summary_d'[data_date] = __EndPeriodDate,
        'a02_e2e_product_performance_inv_summary_d'[data_date] >= __ThisMin,
        'a02_e2e_product_performance_inv_summary_d'[data_date] <= __ThisMax
    )

// ── 分母：当前柱期末全部商品合计（移除图例筛选，保留外部切片器）──
VAR __Denominator =
    CALCULATE(
        SUM('a02_e2e_product_performance_inv_summary_d'[msrp_inv_amt]),
        ALLSELECTED('Slicer_Label'[label]),
        ALLSELECTED('Slicer_Super_Season'[super_season]),
        ALLSELECTED('Slicer_Product_Type'[product_type]),
        ALLSELECTED('Slicer_Category'[category]),
        ALLSELECTED('Slicer_Md_Type'[md_type]),
        ALLSELECTED('Slicer_Division'[division]),
        'a02_e2e_product_performance_inv_summary_d'[data_date] = __EndPeriodDate,
        'a02_e2e_product_performance_inv_summary_d'[data_date] >= __ThisMin,
        'a02_e2e_product_performance_inv_summary_d'[data_date] <= __ThisMax
    )

RETURN
    DIVIDE(__Numerator, __Denominator)
```

### 4.8 S&I Trend EOH Amt% LY Value（期末库存金额占比 LY，当前柱，新增）

```dax
S&I Trend EOH Amt% LY Value =
// ========================================
// 度量值: S&I Trend EOH Amt% LY Value
// 中文名: 期末库存金额占比（LY，当前柱）
// Display Folder: Sales & Inventory Penetration Trend\Trend Base Metrics
// 用途: 柱形图 Y 轴——单个商品占【当前柱子 LY 期末最后一天】的所有商品的
//       期末库存金额比值（LY，与 TY 占比同构，期末日期整体替换为 TimeFrame_Max_LY）
// 依赖: Slicer_Time_Frame_Sales_Trend[TimeFrame_Max_LY]
//       （当前柱所在行的表内预计算 LY 期末日期）；
//       Slicer_Time_Frame_Min_This[TimeFrame_Min_LY] / Slicer_Time_Frame_Max_This[TimeFrame_Max_LY]
//       （全局 this period 区间的去年同期，LY 指标范围框定，分子分母同时叠加）
// 口径: 表格方案未含 EOH Amt% LY，本次新增；公式与 EOH Amt% TY Value 同构，
//       仅期末日期整体替换为当前柱 TimeFrame_Max_LY（LY end period 最后一天），
//       单日同时满足全局 LY 区间框定
// 全局框定说明: LY 数据位于去年，取全局 this period 区间的去年同期框定
//       （直接套当前区间会把 LY 值全部清空）
// 数据底表: a02_e2e_product_performance_inv_summary_d
// 期末机制: 同 EOH Amt% TY（直接单日过滤，分子分母共用同一 LY 期末日期）
// 分母机制: 同 EOH Amt% TY（ALLSELECTED 六维度 + 当前柱 LY 期末单日 ∈ 全局 LY 区间）
// 币种: 分子分母为同表同币种金额（底表 CNY），占比不受币种选择影响
// 说明: inv 表无渠道字段，本指标分子分母均不受渠道筛选影响
// 数据类型: percent_0dp；数据格式: #,##0%（不含正号，度量值静态格式）
// ========================================

// ── 当前柱 LY 期末日期（LY end period 最后一天 = 当前柱所在行 TimeFrame_Max_LY）──
VAR __EndPeriodDateLY = SELECTEDVALUE(Slicer_Time_Frame_Sales_Trend[TimeFrame_Max_LY])

// ── 全局 LY 区间（全局 this period 的去年同期，LY 指标范围框定）──
VAR __ThisMinLY = SELECTEDVALUE(Slicer_Time_Frame_Min_This[TimeFrame_Min_LY])
VAR __ThisMaxLY = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max_LY])

// ── 分子：当前柱 LY 期末 × 图例商品维度期末库存金额 ──
VAR __Numerator =
    CALCULATE(
        SUM('a02_e2e_product_performance_inv_summary_d'[msrp_inv_amt]),
        'a02_e2e_product_performance_inv_summary_d'[data_date] = __EndPeriodDateLY,
        'a02_e2e_product_performance_inv_summary_d'[data_date] >= __ThisMinLY,
        'a02_e2e_product_performance_inv_summary_d'[data_date] <= __ThisMaxLY
    )

// ── 分母：当前柱 LY 期末全部商品合计（移除图例筛选，保留外部切片器）──
VAR __Denominator =
    CALCULATE(
        SUM('a02_e2e_product_performance_inv_summary_d'[msrp_inv_amt]),
        ALLSELECTED('Slicer_Label'[label]),
        ALLSELECTED('Slicer_Super_Season'[super_season]),
        ALLSELECTED('Slicer_Product_Type'[product_type]),
        ALLSELECTED('Slicer_Category'[category]),
        ALLSELECTED('Slicer_Md_Type'[md_type]),
        ALLSELECTED('Slicer_Division'[division]),
        'a02_e2e_product_performance_inv_summary_d'[data_date] = __EndPeriodDateLY,
        'a02_e2e_product_performance_inv_summary_d'[data_date] >= __ThisMinLY,
        'a02_e2e_product_performance_inv_summary_d'[data_date] <= __ThisMaxLY
    )

RETURN
    DIVIDE(__Numerator, __Denominator)
```

### 4.9 S&I Trend TimeFrame IsVisible（柱子可见性，视觉对象筛选度量）

```dax
S&I Trend TimeFrame IsVisible = 1
/**
// 最终优化：由视觉对象自带的去BLANK()机制去掉没有数据的X轴值。
// ========================================
// 度量值: S&I Trend TimeFrame IsVisible
// 中文名: 柱子可见性（当前柱是否在全局 this period 区间内）
// Display Folder: Sales & Inventory Penetration Trend\Visual Filters
// 用途: 柱形图视觉对象级别筛选——判断当前柱（X 轴遍历行）的时间单位是否完全落在
//       全局日期 this period 区间内且粒度与全局所选粒度一致
// 返回: 1（柱子显示）或 0（柱子隐藏）
// 依赖: Slicer_Time_Frame_Min_This[TimeFrame_Min] / Slicer_Time_Frame_Max_This[TimeFrame_Max]
//       （全局 this period 区间，参照模版 §1.1 IsMonthVisible 的起止切片器写法）
//       Slicer_Time_Frame[TimeFrame_ID]（全局所选时间粒度）
//       Slicer_Time_Frame_Sales_Trend[TimeFrame_ID / TimeFrame_Min / TimeFrame_Max]
//       （X 轴行上下文 = 当前柱所在行）
// 使用方式: 柱形图视觉对象级别筛选 → [S&I Trend TimeFrame IsVisible] = 1
//       （Sales Trend 图与 Inventory Trend 图均使用）
// 设计说明:
//   1. X 轴用的新日期表与全局日期筛选器为断开维度，全局筛选不自动过滤 X 轴，
//      需以度量视觉筛选限定柱子范围（模版 §1.1 同款场景）
//   2. 判定用【日期区间】而非 Key：新日期表混含 Week / Month / Year 行，
//      跨粒度 Key 不可比；日期区间比较天然粒度无关
//   3. 粒度一致条件：仅显示与全局所选粒度相同的柱子，避免同区间内
//      周 / 月 / 年柱混杂（全局粒度为 Day / Quarter 时本图无柱可显，
//      因新日期表已过滤这两种粒度）
//   4. 全局 this period 未选择时返回 1（默认全部显示，参照模版兜底逻辑）
// ========================================

// ── 步骤1：全局 this period 区间（标准全局日期体系，断开维度直读）──
VAR __ThisMin = SELECTEDVALUE(Slicer_Time_Frame_Min_This[TimeFrame_Min])
VAR __ThisMax = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

// ── 步骤2：全局所选时间粒度（Week / Month / Year）──
VAR __Granularity = SELECTEDVALUE(Slicer_Time_Frame[TimeFrame_ID])

// ── 步骤3：当前柱的时间单位（X 轴行上下文）──
VAR __BarID = SELECTEDVALUE(Slicer_Time_Frame_Sales_Trend[TimeFrame_ID])
VAR __BarMin = SELECTEDVALUE(Slicer_Time_Frame_Sales_Trend[TimeFrame_Min])
VAR __BarMax = SELECTEDVALUE(Slicer_Time_Frame_Sales_Trend[TimeFrame_Max])

// ── 步骤4：判定（当前柱时间单位完全落在 this period 内，且粒度一致）──
RETURN
    IF(
        // 全局 this period 未选择：默认全部显示（模版兜底逻辑）
        ISBLANK(__ThisMin) || ISBLANK(__ThisMax),
        1,
        IF(
            __BarMin >= __ThisMin
                && __BarMax <= __ThisMax
                && (ISBLANK(__Granularity) || __BarID = __Granularity),
            1,  // 在范围内且粒度一致：柱子显示
            0   // 不在范围内或粒度不一致：柱子隐藏
        )
    )

**/
```

---

## 5. 度量值清单

| # | 度量值                        | 中文名                         | 指标类型       | 度量值静态格式 | 用于视觉对象                          |
| - | ----------------------------- | ------------------------------ | -------------- | -------------- | ------------------------------------- |
| 1 | S&I Trend SLS Amt TY Value    | DCom净销售额（TY，当前柱）     | currency       | `#,##0`      | Sales Trend 柱形图 Y 轴 / tooltip     |
| 2 | S&I Trend SLS Amt LY Value    | DCom净销售额（LY，当前柱）     | currency       | `#,##0`      | Sales Trend 柱形图 Y 轴 / tooltip     |
| 3 | S&I Trend SLS Amt% TY Value   | 销售金额占比（TY，当前柱）     | percent_0dp    | `#,##0%`     | Sales Trend 柱形图 Y 轴（主指标）     |
| 4 | S&I Trend SLS Amt% LY Value   | 销售金额占比（LY，当前柱）     | percent_0dp    | `#,##0%`     | Sales Trend 柱形图 Y 轴 / tooltip     |
| 5 | S&I Trend EOH Amt TY Value    | 期末库存金额（TY，当前柱）     | currency       | `#,##0`      | Inventory Trend 柱形图 Y 轴 / tooltip |
| 6 | S&I Trend EOH Amt LY Value    | 期末库存金额（LY，当前柱）     | currency       | `#,##0`      | Inventory Trend 柱形图 Y 轴 / tooltip |
| 7 | S&I Trend EOH Amt% TY Value   | 期末库存金额占比（TY，当前柱） | percent_0dp    | `#,##0%`     | Inventory Trend 柱形图 Y 轴（主指标） |
| 8 | S&I Trend EOH Amt% LY Value   | 期末库存金额占比（LY，当前柱） | percent_0dp    | `#,##0%`     | Inventory Trend 柱形图 Y 轴 / tooltip |
| 9 | S&I Trend TimeFrame IsVisible | 柱子可见性                     | integer（0/1） | 不展示         | 两图视觉对象级别筛选（= 1）           |

- 全部度量值存放于 `_Measures` 隐藏表；Display Folder：`Sales & Inventory Penetration Trend\Trend Base Metrics`（8 个指标度量）与 `Sales & Inventory Penetration Trend\Visual Filters`（IsVisible）
- 全部 8 个指标度量均叠加全局 this period 区间框定（TY = [Min_This[TimeFrame_Min], Max_This[TimeFrame_Max]]，LY = 其去年同期，见 §1.3 / 注意事项 9）
- 提取对照：SLS 侧 #1 / #2 / #3 提取自 Sales_&_Inventory_Table.md §4.3 / §4.7 / §4.1，EOH 侧 #5 / #6 / #7 提取自 §4.14 / §4.18 / §4.12（DAX 结构一致，时间范围语义改为当前柱所在行区间 / 当前柱 TimeFrame_Max + 全局区间框定）；#4（SLS Amt% LY）与 #8（EOH Amt% LY）为本次新增（表格方案无 LY 占比）；#9 为本次新增（视觉对象筛选）

---

## 6. 血缘关系图

```
┌─────────────────────────────────────────────────────────────────────┐
│                        数据源层                                      │
│  a02_e2e_product_performance_sales_summary_d（销售类，日粒度）       │
│  字段: data_date, platform, shop_name,                              │
│        brand, super_season, product_type, category,                 │
│        md_type, division, framework, ax_class, ...                  │
│        net_sales_amt                                                │
│  a02_e2e_product_performance_inv_summary_d（库存类，日快照）        │
│  字段: data_date + 同名商品维度（无渠道字段）,                       │
│        msrp_inv_amt, inv_qty                                        │
└──────────────────────────────┬──────────────────────────────────────┘
                               │
        ┌──────────────────────┼────────────────────────────┐
        │ 图例 / 切片器 1:N 自动传递（无需 DAX）             │ 两套断开维度日期表
        │ 六个商品维度表（图例字段六选一，双事实表）         │ ┌────────────────────┐
        │ Slicer_Platform_Selection / Store_Name（渠道，    │ │ Slicer_Time_Frame_ │
        │ 仅 sales 侧；EOH 侧不受影响）                     │ │ Sales_Trend        │
        │ Slicer_Currency_Selection（币种，换算）           │ │ X 轴 TimeFrame_    │
        ▼                                                   │ │ Value + 逐柱 Min / │
┌───────────────────────────────────────────────────────┐   │ │ Max / Min_LY /     │
│  逐柱 Value 度量层（8 个）                             │◄──┤ │ Max_LY（当前值 +   │
│  - SELECTEDVALUE 取「当前值」（当前柱所在行）          │   │ │ EOH 期末日期       │
│  - 全局 this period 区间框定（TY / LY）                │   │ │ TimeFrame_Max[_LY])│
│    与当前柱范围取交集（可见柱下无操作，防御性）        │   │ └────────────────────┘
│  - SLS 侧：逐柱区间求 sum(net_sales_amt)              │   │ ┌────────────────────┐
│  - EOH 侧：逐柱 TimeFrame_Max / Max_LY 单日过滤       │   │ │ 全局日期体系        │
│    取 sum(msrp_inv_amt)                                │   │ │ Slicer_Time_Frame  │
│  - SLS Amt% / EOH Amt% 分母 ALLSELECTED 六商品维度表   │   │ │ [TimeFrame_ID]     │
│    × 当前柱时间范围（区间 / 期末单日）                  │   │ │ + Min_This /       │
│  - currency 4 个含汇率换算 ÷ ExchangeRate             │   │ │ Max_This（this     │
└──────────────────────────┬────────────────────────────┘   │ │ period：柱子范围 + │
                           ▼                                │ │ 全部指标区间框定， │
┌───────────────────────────────────────────────────────┐   │ │ 含 LY 同期字段）   │
│  IsVisible 视觉筛选度量（1 个）                        │◄──┘ │                    │
│  当前柱 ∈ 全局 this period 且粒度一致 → 1             │     └────────────────────┘
└──────────────────────────┬────────────────────────────┘
                           ▼
┌─────────────────────────────────────────────────────────────────────┐
│                     可视化层（两张柱形图）                           │
│  Sales Trend 图: X 轴 TimeFrame_Value（ID_Sort 排序），图例商品维度 │
│    六选一，Y 轴 S&I Trend SLS Amt% TY Value（主）/ SLS Amt、        │
│    SLS Amt% LY                                                       │
│  Inventory Trend 图: 同 X 轴 / 同图例机制，                          │
│    Y 轴 S&I Trend EOH Amt% TY Value（主）/ EOH Amt、EOH Amt% LY     │
│  两图视觉对象级别筛选: [S&I Trend TimeFrame IsVisible] = 1           │
│  交叉筛选: 图 → Sales / Inventory 明细表开启（点击柱传导             │
│  TimeFrame_Value，表格 SELECTEDVALUE 读取点击柱行）                 │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 7. 视觉对象配置

### 7.1 Sales Trend 柱形图（SLS 侧）

| 配置项           | 内容                                                                                                                                                                                                                                                            |
| ---------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 视觉对象类型     | 簇状柱形图（或堆叠，按版面需要）                                                                                                                                                                                                                                |
| X 轴             | `Slicer_Time_Frame_Sales_Trend[TimeFrame_Value]`；排序：将该列的「排序依据列」设为 `ID_Sort`（自然时间顺序，避免 "2027 Week14" 类文本乱序）                                                                                                                 |
| 图例             | 商品维度字段六选一（`Slicer_Label[label]` / `Slicer_Super_Season[super_season]` / `Slicer_Product_Type[product_type]` / `Slicer_Category[category]` / `Slicer_Md_Type[md_type]` / `Slicer_Division[division]`，切换时替换图例字段，度量值层无感知） |
| Y 轴（值）       | 主指标`S&I Trend SLS Amt% TY Value`；`S&I Trend SLS Amt TY Value` / `SLS Amt LY Value` / `SLS Amt% LY Value` 按版面组合使用（TY / LY 双图对比、同图多值或 tooltip）                                                                                     |
| 视觉对象级别筛选 | 筛选器窗格（本视觉对象）→`[S&I Trend TimeFrame IsVisible]` **为 1**                                                                                                                                                                                    |

### 7.2 Inventory Trend 柱形图（EOH 侧）

| 配置项           | 内容                                                                                                                                                                        |
| ---------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 视觉对象类型     | 簇状柱形图（或堆叠，按版面需要）                                                                                                                                            |
| X 轴             | 同 Sales Trend 图（`Slicer_Time_Frame_Sales_Trend[TimeFrame_Value]`，ID_Sort 排序）                                                                                       |
| 图例             | 同 Sales Trend 图（商品维度字段六选一，两图建议保持同一图例字段联动切换）                                                                                                   |
| Y 轴（值）       | 主指标`S&I Trend EOH Amt% TY Value`；`S&I Trend EOH Amt TY Value` / `EOH Amt LY Value` / `EOH Amt% LY Value` 按版面组合使用（TY / LY 双图对比、同图多值或 tooltip） |
| 视觉对象级别筛选 | 同 Sales Trend 图（`[S&I Trend TimeFrame IsVisible] = 1`）                                                                                                                |
| 分图说明         | SLS Amt%（区间汇总）与 EOH Amt%（期末时点）时间语义不同，建议分图呈现避免误读（同 Label & PT 模块做法）；两图 X 轴柱子范围一致（共用 IsVisible 判定）                       |

### 7.3 切片器与编辑交互

| 切片器 / 交互                                         | 类型                         | 对柱形图的作用                                                                                                                                                                 |
| ----------------------------------------------------- | ---------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| Slicer_Time_Frame（全局日期主筛选器）                 | 默认交互（开启）             | 经 Min_This / Max_This / TimeFrame_ID 被 IsVisible 度量与全部指标度量的全局区间框定读取，驱动两张柱形图的柱子范围、粒度与数据范围（断开维度不直接过滤 X 轴 / 事实表）          |
| Slicer_Time_Frame_Sales_Trend（单选，表格侧日期筛选） | **编辑交互设为「无」** | 不过滤两张柱形图的 X 轴（否则被切成单柱，趋势失效）；对 Sales / Inventory 明细表保持开启（表格方案依赖单选）                                                                   |
| 两柱形图 → 明细表                                    | 编辑交互保持开启             | 口径「明细表表格列受左边柱状图影响」：点击柱子传导`TimeFrame_Value` 筛选 → 表格 SELECTEDVALUE 读取点击柱所在行（天然单值，与表格方案单选模式兼容，表格 TY / LY 随柱行联动） |
| 商品维度切片器（Slicer_Label / Slicer_Division 等）   | 一对多关联（双表）           | 外部筛选自动传递（SLS 侧到 sales、EOH 侧到 inv）；占比分母经 ALLSELECTED 保留该外部筛选                                                                                        |
| Slicer_Platform_Selection / Slicer_Store_Name         | 一对多关联（仅 sales 表）    | 渠道筛选自动传递：仅影响 SLS 侧 4 个指标；EOH 侧 4 个指标不受影响（inv 表无渠道字段）                                                                                          |
| Slicer_Currency_Selection                             | 断开维度                     | SLS Amt / EOH Amt 各 TY / LY 汇率换算（÷ Currency_ExchangeRate）                                                                                                              |

---

## 8. 验证方法

验证 SQL 为 ClickHouse 语法；全局 this period 与外部筛选条件按页面实际选择替换附加，与 Power BI 模型值逐项对齐。示例按全局 this period = 2027-01 ~ 2027-04（Month 粒度，Min_This / Max_This = 2027-01-01 ~ 2027-04-30，示例按自然月示意，实际以财月区间为准）。

### 8.1 柱子范围（IsVisible）

```sql
SELECT
    timeframe_value AS bar
FROM indep_rl_dim.dim_t00_bi_fiscal_calendar
WHERE timeframe_id = 'Month'                            -- 全局所选粒度
    AND timeframe_min >= '2027-01-01'                   -- Min_This[TimeFrame_Min]
    AND timeframe_max <= '2027-04-30'                   -- Max_This[TimeFrame_Max]
ORDER BY id_sort
-- 结果即两张柱形图显示的柱子集合（TimeFrame_Value 完全落在 this period 内且粒度一致）
```

### 8.2 SLS Amt% TY（逐柱 × 图例商品维度，行维度 = label 示例）

```sql
SELECT
    c.timeframe_value AS bar,
    s.brand AS label,
    SUM(s.net_sales_amt) AS sls_amt_cny,
    SUM(s.net_sales_amt) / SUM(SUM(s.net_sales_amt)) OVER (PARTITION BY c.timeframe_value) AS sls_amt_pct
FROM indep_rl_ads.a02_e2e_product_performance_sales_summary_d s
INNER JOIN indep_rl_dim.dim_t00_bi_fiscal_calendar c
    ON s.data_date BETWEEN c.timeframe_min AND c.timeframe_max
WHERE c.timeframe_id = 'Month'
    AND c.timeframe_min >= '2027-01-01' AND c.timeframe_max <= '2027-04-30'
    -- 柱子限定在全局 this period 内 → 销售行经柱区间归入后必然落在全局区间内（交集语义）
    -- 外部切片器筛选条件（platform / 商品维度等）同步附加
GROUP BY c.timeframe_value, s.brand
```

- 窗口 `PARTITION BY bar` 对应**当前柱时间全量**分母（ALLSELECTED 六维度 + 逐柱区间 ∩ 全局区间）；换图例维度验证时将 brand 替换为对应维度字段
- JOIN 条件 `data_date BETWEEN c.timeframe_min AND c.timeframe_max` 将销售行归入所属柱（粒度限定 Month，财月区间互斥不重叠）；柱子集合已限定在全局 this period 内（8.1），故柱区间内的数据天然满足全局框定（可见柱下框定为无操作）

### 8.3 SLS Amt% LY（逐柱 × 图例商品维度）

```sql
SELECT
    c.timeframe_value AS bar,
    s.brand AS label,
    SUM(s.net_sales_amt) / SUM(SUM(s.net_sales_amt)) OVER (PARTITION BY c.timeframe_value) AS sls_amt_pct_ly
FROM indep_rl_ads.a02_e2e_product_performance_sales_summary_d s
INNER JOIN indep_rl_dim.dim_t00_bi_fiscal_calendar c
    ON s.data_date BETWEEN c.ly_timeframe_min AND c.ly_timeframe_max
WHERE c.timeframe_id = 'Month'
    AND c.timeframe_min >= '2027-01-01' AND c.timeframe_max <= '2027-04-30'
    -- 柱子仍限定在 this period 内（TY 侧），销售行按各柱的 LY 区间归入；
    -- 各柱 LY 区间整体落在全局 LY 区间 [Min_This[TimeFrame_Min_LY], Max_This[TimeFrame_Max_LY]] 内
GROUP BY c.timeframe_value, s.brand
```

- LY 版与 TY 版唯一差异：JOIN 用各柱行的 `ly_timeframe_min / ly_timeframe_max`（表内预计算去年同期区间）；全局 LY 框定 = this period 的去年同期区间（LY 数据位于去年，直接套当前区间会清空）

### 8.4 EOH Amt% TY（逐柱期末单日 × 图例商品维度）

```sql
SELECT
    c.timeframe_value AS bar,
    i.brand AS label,
    SUM(i.msrp_inv_amt) AS eoh_amt_cny,
    SUM(i.msrp_inv_amt) / SUM(SUM(i.msrp_inv_amt)) OVER (PARTITION BY c.timeframe_value) AS eoh_amt_pct
FROM indep_rl_ads.a02_e2e_product_performance_inv_summary_d i
INNER JOIN indep_rl_dim.dim_t00_bi_fiscal_calendar c
    ON i.data_date = c.timeframe_max          -- 各柱 end period 最后一天（TimeFrame_Max）单日过滤
WHERE c.timeframe_id = 'Month'
    AND c.timeframe_min >= '2027-01-01' AND c.timeframe_max <= '2027-04-30'
    -- 外部商品维度筛选条件同步附加；inv 表无渠道字段，不附加渠道条件（与 Power BI 行为一致）
GROUP BY c.timeframe_value, i.brand
```

- JOIN 条件 `i.data_date = c.timeframe_max` 对应 `__EndPeriodDate`（当前柱 TimeFrame_Max 直接单日过滤）；窗口 `PARTITION BY bar` 对应**当前柱期末全量**分母；换图例维度验证时将 brand 替换为对应维度字段
- 边界：某柱 TimeFrame_Max 当日无快照数据（如进行中的时间单位）→ 该柱无行返回，Power BI 显示空

### 8.5 EOH Amt% LY（逐柱 LY 期末单日）

- 将 8.4 的 JOIN 条件替换为 `i.data_date = c.ly_timeframe_max`（各柱 LY end period 最后一天 = TimeFrame_Max_LY），主查询不变——即 EOH Amt% LY 的分子分母整体落在当前柱 LY 期末；全局 LY 框定同 8.3 说明

### 8.6 SLS Amt / EOH Amt TY / LY（金额类）

- 8.2 / 8.3 / 8.4 / 8.5 去掉窗口列即逐柱金额（`sls_amt_cny` / `eoh_amt_cny`）；SLS LY 版 JOIN 用各柱 LY 区间、EOH LY 版用各柱 `ly_timeframe_max`（LY 期末单日）
- 币种对齐：SQL 结果为原始 CNY，Power BI 模型值 = 原始值 ÷ 当前 `Currency_ExchangeRate`（RMB 汇率 = 1 时直接对比）

### 8.7 边界对齐

- 某柱某商品无数据：Power BI 显示空（Value 层 BLANK），柱子仍在（其他商品有值）
- 某柱 TimeFrame_Max / TimeFrame_Max_LY 当日快照缺失（进行中的时间单位 / ETL 缺数）：该柱 EOH 类指标返回空（口径忠实：期末未到无期末值）
- 柱子不在 this period 内 / 粒度不一致：视觉对象筛选隐藏（SQL 侧即 8.1 的柱子集合差异）；指标层的全局区间框定为二次保证（可见柱下无操作）
- 全局 this period 未选择：IsVisible 默认全显（模版兜底）；指标层 __ThisMin / __ThisMax 为 BLANK，度量返回空（与其他模块一致，实际页面全局筛选器通常有默认选择）

---

## 9. 注意事项

1. **视觉筛选机制（模版 §1.1 对照）**：X 轴用的新日期表（Slicer_Time_Frame_Sales_Trend）与全局日期筛选器为**断开维度**，全局筛选不自动过滤 X 轴——参照模版 IsMonthVisible 写法，以 `[S&I Trend TimeFrame IsVisible] = 1` 视觉对象级别筛选逐柱判定显示 / 隐藏；判定用**日期区间**（当前柱 TimeFrame_Min / Max 完全落在 [Min_This, Max_This] 内）而非 Key（新日期表混含周 / 月 / 年行，跨粒度 Key 不可比）。
2. **粒度一致条件**：柱子 TimeFrame_ID 必须等于全局所选粒度（SELECTEDVALUE(Slicer_Time_Frame[TimeFrame_ID])），避免同一 this period 区间内周 / 月 / 年柱混杂；全局粒度为 Day / Quarter 时本图无柱可显（新日期表已过滤这两种粒度）。全局粒度未选择（ISBLANK）时跳过粒度检查。
3. **SLS 侧与 EOH 侧分图**：SLS Amt% 为区间汇总口径、EOH Amt% 为期末时点口径，时间语义不同，建议两张柱形图分图呈现（同 Label & PT 模块做法）；两图共用同一 X 轴字段、图例机制、IsVisible 视觉筛选与度量写法模式。
4. **全局时间体系**：This Period = data_date ∈ [Slicer_Time_Frame_Min_This[TimeFrame_Min], Slicer_Time_Frame_Max_This[TimeFrame_Max]]——Min_This 与 Max_This 两表共同构成一个时间区间，同时驱动柱子显示范围（IsVisible）与全部指标的数据范围（区间框定）。
5. **逐柱「当前值」与编辑交互（关键配置）**：每根柱子经 X 轴行上下文将日期表筛选到当前柱所在行，SELECTEDVALUE 逐柱取 TY / LY 区间与期末日期。**Slicer_Time_Frame_Sales_Trend 单选切片器（表格侧日期）对两张柱形图的编辑交互必须设为「无」**，否则切片器会把 X 轴过滤为单柱、趋势失效；该切片器对 Sales / Inventory 明细表保持开启（表格方案依赖）。
6. **柱形图 → 明细表联动（口径落地）**：原始口径「明细表表格列受左边柱状图影响」——两张图对明细表交叉筛选保持开启：点击柱子传导 `TimeFrame_Value` 筛选，明细表度量 SELECTEDVALUE 读取点击柱所在行（天然单值，与表格方案的单选模式兼容，表格 TY / LY 随点击柱行联动）。清除柱子选择后表格回到单选切片器的选择。
7. **占比分母范围（与表格方案的关键差异）**：本方案分母 = **当前柱时间范围**内全部商品（SLS Amt% 为当前柱区间、EOH Amt% 为当前柱期末单日；ALLSELECTED 六维度），单柱内图例各商品占比之和 = 100%；表格方案分母 = 单选所选期间全量 / 所选期末。同一商品同一时间在图 / 表中的占比语义不同，需业务知悉。
8. **EOH 期末日期口径（v1.2 调整）**：end period 最后一天 = 当前柱所在行 `TimeFrame_Max`（LY 版 = `TimeFrame_Max_LY`），度量直接以 `inv[data_date] = __EndPeriodDate` 单日过滤——语义贴合口径原文、免逐柱全表扫描（性能更优）；原「区间内最后一个有数据的快照日」回退模式已移除。边界：当前柱为**进行中的时间单位**（TimeFrame_Max 在未来，如未结束的当月）或该日快照未产出时，该柱 EOH 类指标返回 BLANK（口径忠实：期末未到无期末值），与 SLS 侧（区间已有部分数据）形成「销售有值、库存为空」的展示；如业务需展示最近可得快照，可改回 `CALCULATE(MAX(inv[data_date]), REMOVEFILTERS(inv), 区间谓词)` 回退模式，需业务确认。
9. **全局 this period 区间框定（v1.3 新增）**：全部 8 个指标度量叠加全局区间约束——TY 指标用 `data_date ∈ [Slicer_Time_Frame_Min_This[TimeFrame_Min], Slicer_Time_Frame_Max_This[TimeFrame_Max]]`（全局 This Period），LY 指标用其去年同期 `[Min_This[TimeFrame_Min_LY], Max_This[TimeFrame_Max_LY]]`（两表均含该预计算字段）——**LY 数据位于去年，直接套当前 this period 区间会把 LY 值全部清空，故取对应 LY 区间**。可见柱（IsVisible = 1）下柱区间 ⊆ 全局区间，框定为无操作（防御性）——语义上全局时间筛选器约束每一个指标，视觉筛选之外二次保证数据范围。全局日期未选择时 __ThisMin / __ThisMax 为 BLANK，度量返回空（与其他模块一致，实际页面全局筛选器通常有默认选择）。
10. **inv 表无渠道字段**：EOH 侧 4 个指标（EOH Amt / EOH Amt% 各 TY / LY）分子分母均不受渠道筛选影响（inv 表无 platform / shop_name）；SLS 侧 4 个指标均受渠道筛选影响（sales 侧）——图 / 表口径一致，需业务知悉。
11. **currency 无 Display 度量**：柱形图 Y 轴需数值度量，Display 文本度量（币种符号 + 千分位）无法用于轴——SLS Amt / EOH Amt 各 TY / LY 输出换算后数值（÷ Currency_ExchangeRate）+ 静态格式 `#,##0`，轴 / 数据标签直接使用；如 tooltip 需要带币种符号文本，可复用表格侧 Display 度量或后续补充。
12. **币种与汇率**：底表金额仅存 CNY；currency 4 个（SLS Amt / EOH Amt 各 TY / LY）在 Value 层换算（RMB 汇率 = 1 时值不变）；SLS Amt% / EOH Amt% 分子分母同表同币种相除，占比不受币种选择影响。
13. **财年日历**：TimeFrame 为财年日历（月柱 2027-01 的 TimeFrame_Min / Max 为财月区间，如 [2026-12-28, 2027-01-24]；LY 为表内预计算去年同期区间）——验证与取数一律以日期表区间为准，勿按自然月硬编码。
14. **X 轴排序**：TimeFrame_Value 含 "2026 Week14" / "2027-01" / "2027" 等混合格式文本，天然排序不可靠——将该列「排序依据列」设为 `ID_Sort`（行唯一、随时间递增）。
15. **图例字段必须从 Slicer_ 维度表拉取**：图例筛选直接落在维度表字段上，`ALLSELECTED(维度表字段)` 才能正确移除；若误用事实表字段（如 sales[brand] / inv[brand]）作图例，维度表字段上无视觉对象内部筛选，ALLSELECTED 为无效操作，事实表字段的图例筛选不被移除，占比恒 100%。
16. **未选择兜底**：全局 this period 未选择时 IsVisible 返回 1（全部柱显示，含全部粒度——参照模版兜底逻辑）；指标层全局框定此时为 BLANK，度量返回空；实际页面全局日期筛选器通常有默认选择，属边界行为。
17. **口径与语法**：口径文档中定义的所有指标必须遵守其数据类型与数据格式，与解决方案存在争议时一切以口径文档为准；DAX 文本常量使用双引号，单引号仅用于表名，列名使用方括号。
