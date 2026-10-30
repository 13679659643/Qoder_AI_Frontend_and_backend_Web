# Series Sales Performance 表格解决方案

> **版本**: v1.0
> **模块**: RL E2E Merch Dashboard - SKU Sales Tracking Tab - Series Sales Performance
> **关联口径**: 口径文档/口径Markdown格式/SKU Sales Tracking.md - 子模块七 Series Sales Performance（§13~§27）
> **数据底表（销售类）**: s02_trade_sku_data_d
> **数据底表（库存类）**: s02_inventory_stock_sales_detail_d
> **关联维度**: Slicer_Time_Frame_Min_This / Max_This（时间，断开维度）；Slicer_Currency_Selection（币种，断开维度）
> **筛选影响范围**: date + 渠道（Platform + Store Name，仅销售侧）+ 商品维度（Label / Division / Product Type / Framework / Category / AX Class / Category Summary / Special Supply / Predictive Buy；库存侧受与 s02_inventory_stock_sales_detail_d 已建关系的商品维度切片器影响）

---

## 1. 需求理解

### 1.1 模块定位

Series Sales Performance 是 SKU Sales Tracking Tab 的特别系列子模块，以单张层级表格展示每个特别系列（special_series）及其下 AXC（spu_id）的销售、库存、占比、AUR、MD 与 YTD / LTD 售罄率表现：

- **行结构**：Series（special_series）> AXC（spu_id）> Image（spu_img_url）层级，开启行小计（series 汇总行）
- **图片列**：Image（spu_img_url）为行区域学第三层字段（数据类别 = 图像 URL，见 §7），与 spu_id 正常一对一，行粒度即 spu；不排除一对多异常（同一 spu 多 url），见 §1.2
- **指标列**：SLS Amt / SLS Amt% / SLS Unit / SLS Unit% / EOH Amt / EOH Amt% / EOH Unit / EOH Unit% / AUR / MD / YTD SLS Unit / YTD ST% (Unit) / YTD ST% (Amt) / LTD SLS Unit / LTD ST% (Unit)，共 15 列
- **排序**：Sort Key 单键控制整表行序（series 分组金额降序 → series 内 AXC 金额降序）

### 1.2 行维度、行小计与 special_series 非空前提

| 层级 | 字段   | 来源                                 | 说明                                   |
| ---- | ------ | ------------------------------------ | -------------------------------------- |
| 1    | Series | s02_trade_sku_data_d[special_series] | 视觉对象筛选器配置「不为空」过滤空白值 |
| 2    | AXC    | s02_trade_sku_data_d[spu_id]         | series 内明细行                        |
| 3    | Image  | s02_trade_sku_data_d[spu_img_url]    | 行区域图片列（数据类别 = 图像 URL，见 §7） |

- **行粒度 = (special_series, spu_id, spu_img_url) 三元组**：spu_id 与 spu_img_url 正常一对一（行粒度即 spu，图片正常显示）；不排除一对多异常——同一 spu 多个 url 时按记录拆分为多行，销售类指标按 (spu, url) 记录集合拆分（历史换图的记录按各自 url 归属），库存类指标按 spu 粒度传递（url 行显示该 spu 全部库存，见 §3.2）
- **spu_img_url 行筛选对度量值的影响**：url 列进入行轴后成为行筛选上下文的一部分，占比分母的维度移除与 Sort Key 排名候选的上卷必须覆盖该列——分母 REMOVEFILTERS(三列)、L1 候选金额上卷清除 spu_id + spu_img_url、L2 候选金额上卷清除 spu_img_url（见 §3.3 / §3.4）；否则分母被 url 筛选收窄为分子自身（占比恒 100%）、排名候选被收窄为当前行自身（名次恒 1）
- **special_series 非空**：表格视觉对象级筛选器对 s02_trade_sku_data_d[special_series] 配置「不为空」，落地为该列的视觉级筛选；空白（NULL / 空字符 / 纯空格）series 不出现在行轴。口径「仅统计 special_series 有值的商品（含全部指标及占比分母）」由该筛选器与各度量值内部分母条件共同保证（逐类核查见 §1.6）
- **行小计**：series 汇总行 = 该 series 下全部 AXC 的上卷汇总（series 粒度），显示位置由表格格式面板的小计位置设置控制；Sort Key 中 series 汇总行编码为组内最后（SpuRank = 999,999），与小计显示在组底部的常规形态一致；行区域为三层结构时若同时开启 spu 层小计，spu 汇总行同样走 ISINSCOPE(spu_id) 分支（TREATAS 传 spu_id，值为该 spu 全部 url 记录汇总，行为正确）
- **总计行（若开启）**：全部有效 series 的汇总，行维度值不传递（不限定单个 series），仅保留 special_series 非空与外部筛选（实现见 §3.2 总计分支）
- **跨表无关系**：s02_trade_sku_data_d 与 s02_inventory_stock_sales_detail_d 之间无模型关系，行维度值（special_series / spu_id）对库存类指标不自动传递，经 DAX TREATAS 显式桥接（见 §3.2）

### 1.3 指标清单

| 序号 | 指标           | 计算公式（时间范围看 this period）                                                                                         | 时间口径                                          | 数据类型 / 格式                 |
| ---- | -------------- | -------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------- | ------------------------------- |
| §13 | SLS Amt        | 该 spu_id 下`sum(net_sales_amt)`                                                                                         | This Period（区间）                               | currency → 币种符号 +`#,##0` |
| §14 | SLS Amt%       | 分子：该 spu_id 下`sum(net_sales_amt)`；分母：`sum(net_sales_amt)`（移除表格中所有维度字段，但 special_series 不为空） | This Period（区间）                               | percent_0dp →`#,##0%`        |
| §15 | SLS Unit       | 该 spu_id 下`sum(product_qty)`                                                                                           | This Period（区间）                               | integer →`#,##0`             |
| §16 | SLS Unit%      | 分子：该 spu_id 下`sum(product_qty)`；分母：`sum(product_qty)`（移除表格中所有维度字段，但 special_series 不为空）     | This Period（区间）                               | percent_0dp →`#,##0%`        |
| §17 | EOH Amt        | 该 spu_id 下`sum(msrp_inv_amt)`                                                                                          | This Period 最后一天（期末时点）                  | currency → 币种符号 +`#,##0` |
| §18 | EOH Amt%       | 分子：该 spu_id 下`sum(msrp_inv_amt)`；分母：`sum(msrp_inv_amt)`（移除表格中所有维度字段，但 special_series 不为空）   | This Period 最后一天（期末时点）                  | percent_0dp →`#,##0%`        |
| §19 | EOH Unit       | 该 spu_id 下`sum(stock_inv_qty)`                                                                                         | This Period 最后一天（期末时点）                  | integer →`#,##0`             |
| §20 | EOH Unit%      | 分子：该 spu_id 下`sum(stock_inv_qty)`；分母：`sum(stock_inv_qty)`（移除表格中所有维度字段，但 special_series 不为空） | This Period 最后一天（期末时点）                  | percent_0dp →`#,##0%`        |
| §21 | AUR            | 该 spu_id 下`sum(net_sales_amt) / sum(product_qty)`                                                                      | This Period（区间）                               | currency → 币种符号 +`#,##0` |
| §22 | MD             | 该 spu_id 下`1 - sum(product_qty*md_price) / sum(product_qty*msrp)`                                                      | This Period（区间）                               | percent_0dp →`#,##0%`        |
| §23 | YTD SLS Unit   | 该 spu_id 下`sum(product_qty)`                                                                                           | this period 所在财年第一天至 this period 最后一天 | integer →`#,##0`             |
| §24 | YTD ST% (Unit) | `sales.product_qty / (sales.product_qty + inv.inv_qty)`（sales 为 YTD 区间，inv 为期末时点 inv_qty）                     | 跨表（区间 + 时点）                               | percent_0dp →`#,##0%`        |
| §25 | YTD ST% (Amt)  | `sales.net_sales_amt / (sales.net_sales_amt + inv.msrp_inv_amt)`（sales 为 YTD 区间，inv 为期末时点 msrp_inv_amt）       | 跨表（区间 + 时点）                               | percent_0dp →`#,##0%`        |
| §26 | LTD SLS Unit   | 该 spu_id 下`sum(product_qty)`                                                                                           | 开店以来：≤ this period 最后一天（无固定起始日） | integer →`#,##0`             |
| §27 | LTD ST% (Unit) | `sales.product_qty / (sales.product_qty + inv.inv_qty)`（sales 为 LTD 区间，inv 为期末时点 inv_qty）                     | 跨表（区间 + 时点）                               | percent_0dp →`#,##0%`        |

说明：

- **AUR / MD / ST% 的行小计口径**（口径文档未定义小计行为，按汇总语义实现）：AUR 小计 = series 层加权件单价（总金额 ÷ 总数量，非 AXC 均值的算术平均）；MD 小计 = series 层 1 − 总折扣金额 ÷ 总吊牌金额；ST% 小计 = series 层分子分母同步上卷后相除
- **ST% 库存字段**：§24 / §25 / §27 的库存分母字段为 `inv_qty`（库存数量），与 §19 EOH Unit 的 `stock_inv_qty`（在库库存数量）是两个不同字段，按口径文档字段名分别使用，不可混用

### 1.4 时间口径

| 口径                     | 时间范围                                                                                                                                  | 适用指标                           |
| ------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------- |
| This Period（区间类）    | dt ∈ [Slicer_Time_Frame_Min_This[TimeFrame_Min], Slicer_Time_Frame_Max_This[TimeFrame_Max]]                                              | SLS 系列、AUR、MD 及其占比分子分母 |
| End Period（期末时点类） | end period 范围 [Slicer_Time_Frame_Max_This[TimeFrame_Min], Slicer_Time_Frame_Max_This[TimeFrame_Max]] 内**最后一个有数据的快照日** | EOH 系列、ST% 库存分母             |
| YTD（财年区间类）        | dt ∈ [Slicer_Time_Frame_Max_This[Fiscal_Year_First_Day], Slicer_Time_Frame_Max_This[TimeFrame_Max]]，与 last period 无关                 | YTD SLS Unit、YTD ST% 销售侧       |
| LTD（开店以来类）        | dt ≤ Slicer_Time_Frame_Max_This[TimeFrame_Max]（无固定起始日），与 last period 无关                                                      | LTD SLS Unit、LTD ST% 销售侧       |

说明：

- 期末时点实现为「end period 范围内最后一个有数据的快照日」：口径定义为 this period 最后一天（TimeFrame_Max），快照缺数时自动回退到范围内最近一天，避免整段空值；快照表按日存储，期末时点**只取单日**，对 end period 整段区间求和会把库存重复计数
- YTD 财年第一天取自 Slicer_Time_Frame_Max_This[Fiscal_Year_First_Day]（该行 TimeFrame_Min 落入的财年区间第一天，取数时已按 dim_t00_bi_fiscal_calendar 自关联生成）；LTD 销售侧仅关注上限（≤ this period 最后一天），期末库存金额仅关注 end period 最后一天

### 1.5 币种口径

- SLS Amt / EOH Amt / AUR 为 currency 类指标：货币符号由币种切片器（Slicer_Currency_Selection）决定，千分位整数
- 数据底表金额仅存储 RMB：选择 USD 时按 `Currency_ExchangeRate`（动态取自数仓 dim_t00_currency 表 USD→CNY 最新有效汇率）换算。**Value 层完成汇率换算**（输出当前币种金额 = 原始 RMB 值 ÷ 汇率），**Display 层仅拼接币种符号**；RMB 时汇率为 1，换算前后值相同
- 占比类（Amt% / Unit% / MD / ST%）与数量类（Unit）不涉及币种换算：占比分子分母同币种，换算与否比值不变；AUR 换算与 SLS Amt 同层（分子金额 ÷ 汇率，数量不变）

### 1.6 special_series 非空前提对指标计算的影响核查

视觉对象筛选器「special_series 不为空」落地为 s02_trade_sku_data_d[special_series] 的视觉级筛选，对各类指标的影响逐项核查如下（结论：全部符合「仅统计 special_series 有值的商品」前提，需显式处理的点已在度量值内部实现）：

| 指标类别                                              | 影响机制                                                                                                                                                                                                                        | 核查结论                                                                                                                                          |
| ----------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------- |
| 销售类分子（§13 / §15 / §21 / §22 / §23 / §26） | 行维度来自 s02_trade_sku_data_d，行筛选（series / spu_id）与视觉级 series 非空筛选共同限定聚合范围，空白 series 商品自动排除                                                                                                    | 符合，自动生效                                                                                                                                    |
| 销售类占比分母（§14 / §16）                         | 分母`REMOVEFILTERS(special_series, spu_id, spu_img_url)` 上卷时会把视觉级「不为空」筛选与 url 行筛选一并移除（均为相应列的列筛选），若不重新限定 series 非空，分母会混入空白 series 商品的金额 / 数量，占比偏小；若不移除 url 列（行区域含 spu_img_url 时），分母被当前行 url 筛选收窄为分子自身，占比恒 100%                                           | 符合，度量值内部分母显式移除三列并重加`NOT ISBLANK && LEN(TRIM()) > 0` 条件（口径原文同样要求 series 非空）                                                           |
| 库存类分子（§17 / §19 / ST% 库存分母）              | inv 表与 trade 表无模型关系，视觉级 series 筛选不影响 inv 表；行维度值经 TREATAS 桥接传递——明细行传 spu_id（该 spu 来自有效 series 行）、series 汇总行传 special_series（值为当前行的有效 series）                            | 符合，传递值本身来自有效 series 行；inv 表中 special_series 为空白但 spu_id 与传递值匹配的记录按 spu_id 精确匹配语义计入（spu_id 为商品唯一标识） |
| 库存类分母（§18 / §20）                             | inv 表不受行维度与视觉级筛选影响，若不加条件会包含空白 series 商品的库存，占比偏小                                                                                                                                              | 符合，度量值内部分母显式加 inv 表`NOT ISBLANK && LEN(TRIM()) > 0` 条件                                                                          |
| Sort Key 排名                                         | L1 relation 为`ALL(special_series)` 且 FILTER 内排除空白 / 空字符 series（视觉级筛选被 ALL 移除，空白排除在度量值内部实现，双保险）；L1 / L2 候选金额均按排名粒度上卷——L1 清除 spu_id + spu_img_url 子级行筛选（series 粒度金额）、L2 清除 spu_img_url 子级行筛选（spu 粒度金额），当前行 series 筛选在 L2 保留，候选自动限定在当前有效 series 内 | 符合                                                                                                                                              |

---

## 2. 现状分析

- 数据底表 `s02_trade_sku_data_d`（SKU 粒度交易表，dt 日粒度）：net_sales_amt 为 Power Query 取数时新增列（`ROUND(product_qty * sales_price, 6) AS net_sales_amt`）；数量口径字段为 product_qty（net_sales_amt 由 product_qty × sales_price 行级计算而来，二者同源）；MD 分子字段 md_price、分母字段 msrp 均为行级字段（行级乘积后求和）；维度含 dt、platform、shop_name、division 及 special_series、spu_id、spu_img_url 等全部商品维度字段
- 数据底表 `s02_inventory_stock_sales_detail_d`（库存+销售+补货 SKU 模型表，dt 日快照）：msrp_inv_amt（吊牌库存金额）为期末库存金额口径字段；stock_inv_qty（在库库存数量）为 §19 EOH Unit 口径字段；inv_qty（库存数量）为 §24 / §25 / §27 ST% 库存分母口径字段；维度含 dt、division、special_series、spu_id 等商品维度字段；**无 platform / shop_name 字段**（渠道筛选不影响库存侧指标，口径限制见注意事项 1）
- 模型关系：两张事实表之间**无模型关系**，行维度值（special_series / spu_id）向库存类指标传递不依赖模型关系，全部经 DAX TREATAS 显式桥接；日期筛选器（Slicer_Time_Frame_Min_This / Max_This）为断开维度，时间范围在 DAX 中显式筛选；渠道切片器（Platform / Store Name）与 trade 表一对多关联自动传递；商品维度切片器与两张事实表已建关系的筛选自动传递（Division 确认与两表关联）；Slicer_Currency_Selection 为断开维度，币种符号与汇率经 SELECTEDVALUE 读取
- Slicer_Time_Frame_Max_This 已含 Fiscal_Year_First_Day 字段（取数 SQL 按 TimeFrame_Min 落入的财年区间自关联 dim_t00_bi_fiscal_calendar 生成），YTD 区间起点直接读取该字段，无需在 DAX 内推导财年
- 字段名已逐一核对数据字典与取数 SQL（两表日期字段统一为 dt，date 类型）
- **模型加载窗口限制**：Power Query 取数限定了数据窗口——trade 表为 `(dt >= '2026-03-29' AND dt <= '2026-09-26') OR (dt >= '2025-03-30' AND dt <= '2025-09-27')`，inv 表为 `(dt >= '2026-03-29' AND dt <= '2026-07-25') OR (dt >= '2025-03-30' AND dt <= '2025-07-26')`。LTD「开店以来」与 YTD「财年第一天起」在模型中实际统计范围为**加载窗口 ∩ 口径区间**：窗口外历史数据不在模型中，LTD / YTD 模型值小于全量口径值；如需全量口径需扩窗重新取数。测试 SQL 默认附加相同窗口条件与 Power BI 模型值逐行对齐（去窗口即全量口径，见测试 SQL 说明）

---

## 3. 方案设计

### 3.1 度量值分层

```
Sort Key（视觉对象行排序依据）
←  L1 series 粒度 This Period 净销售金额降序（special_series 升序决胜）
←  L2 series 内 spu 粒度 This Period 净销售金额降序（spu_id 升序决胜）
←  series 汇总行编码组内最后（SpuRank = 999,999）；当期无金额行垫底
↓
Value（口径计算，保留小数原值）
←  分子 / 分母时间范围显式筛选；占比分母 REMOVEFILTERS(三列：series / spu_id / spu_img_url) 上卷至全量并重加 series 非空条件
←  库存类分子 ISINSCOPE 分层 TREATAS 桥接行维度值（明细传 spu_id / 汇总传 special_series / 总计不传）
←  金额类 Value 层完成币种汇率换算（原始 RMB ÷ Currency_ExchangeRate）
↓
Display（格式化显示）
←  currency: 币种符号 & FORMAT(#,##0)；integer: FORMAT(#,##0)；percent_0dp: FORMAT(#,##0%)
←  BLANK 统一显示 "-"
```

### 3.2 行维度值跨表传递（TREATAS 桥接）

两张事实表间无模型关系，行维度值向 s02_inventory_stock_sales_detail_d 的传递按行层级分三种形态，在每个库存类 Value 度量内部以 ISINSCOPE 分层实现：

| 行层级                  | 判定条件                                               | 传递方式                                                        | 库存侧聚合范围                                                                        |
| ----------------------- | ------------------------------------------------------ | --------------------------------------------------------------- | ------------------------------------------------------------------------------------- |
| AXC 明细行（含 Image url 行与 spu 层小计行） | `ISINSCOPE(s02_trade_sku_data_d[spu_id])`            | `TREATAS(VALUES(trade[spu_id]), inv[spu_id])`                 | inv 表中该 spu_id 的全部记录（该 spu 的期末库存，不随 url 行筛选拆分）                |
| Series 汇总行（行小计） | `NOT ISINSCOPE(spu_id) && ISINSCOPE(special_series)` | `TREATAS(VALUES(trade[special_series]), inv[special_series])` | inv 表中该 special_series 的全部记录（含 trade 侧无销售记录的 spu，不受渠道筛选影响） |
| 总计行（若开启）        | 两层均不在 scope                                       | 不传递行维度值，仅保留`inv[special_series]` 非空条件          | inv 表中 special_series 有效值的全部记录                                              |

实现要点：

- 分层在**标量结果层**用 IF 嵌套分支实现（每个分支内部 CALCULATE + 对应 TREATAS 后返回标量）。IF 直接返回表表达式会被降级为标量，表形态的分支选择不可用 IF；本方案各分支均在 CALCULATE 聚合后返回标量，IF 分支安全
- **明细行传递 spu_id 而非 series 值，且不传递 url**：单 spu 的库存值与渠道筛选无关（inv 表无渠道字段，spu_id 为精确值匹配），渠道筛选只影响哪些 AXC 行出现在表格中，不影响单 AXC 的库存值；行区域含 spu_img_url 时，url 明细行与 spu 层小计行均满足 ISINSCOPE(spu_id)（url 是 spu 的子级属性，不参与库存传递粒度）——一对多异常时同一 spu 的多个 url 行显示相同的 spu 级库存值，为可接受的降级行为（inv 表 url 与 trade 表 url 不保证同步，按 (spu, url) 双列传递存在库存漏计风险）
- **汇总行传递 special_series 而非 spu_id 集合**：`VALUES(trade[spu_id])` 在汇总行受渠道 / 商品维度筛选约束（trade 侧可见 spu 集合），若传递 spu 集合会使库存汇总随渠道筛选收窄，与「库存侧指标不受渠道筛选影响」口径矛盾；传递 series 单值时 inv 侧聚合该 series 全部库存，仅受与 inv 表已建关系的商品维度切片器（Division）影响
- **期末快照日先经 REMOVEFILTERS(整表) 确定性取值**：`__EndPeriodDate` 在 TREATAS 分支之外计算，快照日不随行上下文或切片器漂移
- ST% 类（§24 / §25 / §27）为跨表双分母结构：销售侧分子沿用 trade 表行筛选自动传递，库存侧加项按同一分层 TREATAS 桥接，分子与库存加项在同一行粒度（明细 = spu、汇总 = series）上配对相除

### 3.3 占比分母的维度移除与 series 非空还原

口径「移除表格中所有维度字段，但 special_series 不为空」的实现：

- **销售类分母（§14 / §16）**：`REMOVEFILTERS(s02_trade_sku_data_d[special_series], s02_trade_sku_data_d[spu_id], s02_trade_sku_data_d[spu_img_url])` 移除三列的全部筛选（含行维度筛选、spu_img_url 行筛选与视觉级「不为空」筛选落地的列筛选），保留外部切片器筛选；随后以布尔筛选参数显式重加 `NOT ISBLANK(special_series) && LEN(TRIM(special_series)) > 0`（布尔筛选中列引用经引擎转换为对该列全量值的 FILTER，空白 / 空字符 / 纯空格一并排除），分母覆盖当前外部筛选下全部有效 series 商品（含表格未显示行）的金额 / 数量
- **库存类分母（§18 / §20）**：inv 表不受行维度与视觉级筛选影响，分母直接显式加 inv 表 `NOT ISBLANK(special_series) && LEN(TRIM(special_series)) > 0` 条件 + 期末快照日 + 外部筛选（Division 等已建关系切片器）
- 占比不受币种选择影响：分子分母均为原始 RMB 聚合（不经汇率换算）

### 3.4 Sort Key 排序机制

表格视觉对象仅支持单键排序，两级排序规则编码为一个整数键：

| 层级 | 排序规则                                                                                    | 实现方式                                                                                                                                                                                                                                             |
| ---- | ------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| L1   | Series 按 This Period 净销售金额（series 粒度汇总）降序，金额相同按 special_series 升序决胜 | `RANK(DENSE, FILTER(ALL(trade[special_series]), 非空白 && 当期有金额), ORDERBY(当期金额 DESC, special_series ASC))`——当前行 series 经 ORDERBY 中 relation 列匹配取名次，名次严格连续唯一；候选金额 CALCULATE 内 `REMOVEFILTERS(spu_id, spu_img_url)` 上卷到 series 粒度（清除子级行筛选，否则候选被当前行 spu / url 筛选收窄、名次恒 1）                                                         |
| L2   | Series 内 AXC 按 This Period 净销售金额降序，金额相同按 spu_id 升序决胜                     | `RANK(DENSE, FILTER(ALL(trade[spu_id]), 当期有金额), ORDERBY(当期金额 DESC, spu_id ASC))`——relation 为 `ALL(spu_id)` 仅移除 spu_id 列筛选，当前行 special_series 筛选保留 → 候选金额自动限定在当前 series 内（series 内排名，无需上下文重建）；候选金额 CALCULATE 内 `REMOVEFILTERS(spu_img_url)` 上卷到 spu 粒度（清除 url 行筛选，否则候选被当前行 url 筛选收窄、名次恒 1） |

- **编码**：`Key = __SeriesRank × 1,000,000 + __SpuRank`；series 汇总行 `__SpuRank = 999,999`（组内最后）；当期无金额行键值垫底（1,000,000,000,000，超出正常键值区间，排在全部有效行之后）
- **系数约束**：series 内有效 AXC 数需 < 999,999（L2 名次不超过 999,998 时汇总行保持组内最后），series 分组数需 < 1,000,000；超出需调大系数
- **金额口径**：两级排名均使用原始 RMB 聚合（不经币种换算——除以同一正汇率不改变相对顺序）；当期无金额的候选不占名次（避免其排序位置使有效行名次整体偏移），当前行当期无金额时键值垫底；L1 候选金额为 series 粒度（清除 spu_id + spu_img_url 子级行筛选）、L2 候选金额为 spu 粒度（清除 spu_img_url 子级行筛选），一对多异常时同一 spu 的多个 url 行共享同一 L2 名次（spu 粒度金额相同），行序由表格呈现确定
- **空白候选**：L1 relation 内部排除空白 / 空字符 / 纯空格 series（视觉级「不为空」筛选会被 `ALL(special_series)` 移除，空白排除在度量值内部实现，双保险）；L2 relation 不排除空白 spu_id——口径仅过滤 special_series，(Blank) AXC 行为合法数据行，按真实金额参与排名（金额相同按维度值升序决胜时空白排最前）
- **RANK 版本要求**：RANK / ORDERBY 为 Power BI Desktop 2022 年 9 月及以后版本引入的窗口函数，旧版本不可用

### 3.5 度量值命名与组织

- 命名规则：模块前缀 `Series Sales` + 指标名 + 层次后缀（Value / Display），排序键为 `Series Sales Sort Key`
- Display Folder：`Series Sales Performance\Rank`、`Series Sales Performance\Base Metrics`、`Series Sales Performance\Formatting`
- 度量值统一存放于 `_Measures` 隐藏表（与看板既有组织方式一致）

---

## 4. 度量值实现

### 4.1 Series Sales Sort Key（表格行排序键）

```dax
Series Sales Sort Key =
// ========================================
// 度量值: Series Sales Sort Key
// 中文名: Series 表格行排序键
// Display Folder: Series Sales Performance\Rank
// 用途: Series 表格行排序键（升序），表格视觉对象仅支持单键排序，
//       将两级排序规则编码为一个整数键：
//   L1 分组顺序：Series 按 This Period 净销售金额（series 粒度汇总）降序
//   L2 组内顺序：Series 内 AXC（spu_id）按 This Period 净销售金额降序
//   决胜规则：两级金额相同时均按维度值（special_series / spu_id）升序，
//             名次严格连续唯一（1、2、3、……），金额并列行序确定
// 依赖: Slicer_Time_Frame_Min_This[TimeFrame_Min] / Slicer_Time_Frame_Max_This[TimeFrame_Max]
// 使用: 拖入表格值区域最后一列并收窄列宽，点击该列标题按升序排序（配置见 §7）
// 编码: Key = SeriesRank × 1,000,000 + SpuRank
//       series 汇总行（行小计）SpuRank = 999,999 编码为组内最后；
//       单 series 内有效 AXC 数需 < 999,999、series 分组数需 < 1,000,000，
//       超出需调大系数
// 函数: RANK 窗口函数（Power BI Desktop 2022 年 9 月及以后版本）——
//       无 value 参数，当前行经 ORDERBY 中的 relation 列与 relation 行
//       匹配确定名次；L2 relation = ALL(spu_id) 仅移除 spu_id 列筛选，
//       当前行 special_series 筛选保留 → 候选金额自动限定在当前 series 内
//       （series 内排名，无需上下文重建）
// 排名粒度上卷: 行区域含 spu_img_url 时，当前行 spu_id / spu_img_url 列筛选
//       会残留在候选金额评估中（ALL 仅移除自身列），候选集被收窄为当前行
//       自身、名次恒 1——L1 候选金额 CALCULATE 内 REMOVEFILTERS(spu_id,
//       spu_img_url) 上卷到 series 粒度、L2 候选金额 CALCULATE 内
//       REMOVEFILTERS(spu_img_url) 上卷到 spu 粒度，清除子级行筛选
// 空值处理: 当期无金额的行键值垫底（1,000,000,000,000，超出正常键值
//       区间，排在全部有效行之后）；L1 relation 排除空白 / 空字符 series
//       与当期无金额候选（不占名次）；L2 relation 不排除空白 spu_id
//       （口径仅过滤 special_series，(Blank) AXC 行按真实金额参与排名）
// 排名金额: 原始 RMB 聚合（不经币种换算——除以同一正汇率不改变相对顺序）
// ========================================

// ── This Period 时间区间 ──
VAR __PeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Min_This[TimeFrame_Min])
VAR __PeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

// ── 当前行 This Period 净销售金额（明细行 = spu 粒度；series 汇总行 = series 粒度汇总）──
VAR __CurrentAmt =
    CALCULATE(
        SUM('s02_trade_sku_data_d'[net_sales_amt]),
        's02_trade_sku_data_d'[dt] >= __PeriodMin,
        's02_trade_sku_data_d'[dt] <= __PeriodMax
    )

// ── L1 series 排名：series 粒度当期净销售金额降序 + special_series 升序决胜 ──
// relation 排除空白/空字符 series（视觉级「不为空」筛选会被 ALL 移除，此处双保险）
// 与当期无金额候选（无金额候选不占名次，避免其排序位置使有效 series 名次整体偏移）；
// 候选金额 REMOVEFILTERS(spu_id, spu_img_url) 上卷到 series 粒度
VAR __SeriesRank =
    RANK(
        DENSE,
        FILTER(
            ALL('s02_trade_sku_data_d'[special_series]),
            NOT ISBLANK('s02_trade_sku_data_d'[special_series])
                && LEN(TRIM('s02_trade_sku_data_d'[special_series])) > 0
                && NOT ISBLANK(
                    CALCULATE(
                        SUM('s02_trade_sku_data_d'[net_sales_amt]),
                        REMOVEFILTERS(
                            's02_trade_sku_data_d'[spu_id],
                            's02_trade_sku_data_d'[spu_img_url]
                        ),
                        's02_trade_sku_data_d'[dt] >= __PeriodMin,
                        's02_trade_sku_data_d'[dt] <= __PeriodMax
                    )
                )
        ),
        ORDERBY(
            CALCULATE(
                SUM('s02_trade_sku_data_d'[net_sales_amt]),
                REMOVEFILTERS(
                    's02_trade_sku_data_d'[spu_id],
                    's02_trade_sku_data_d'[spu_img_url]
                ),
                's02_trade_sku_data_d'[dt] >= __PeriodMin,
                's02_trade_sku_data_d'[dt] <= __PeriodMax
            ), DESC,
            's02_trade_sku_data_d'[special_series], ASC    // 金额相同按 series 名称升序决胜
        )
    )

// ── L2 series 内 AXC 排名：spu 粒度当期净销售金额降序 + spu_id 升序决胜 ──
// relation = ALL(spu_id) 仅移除 spu_id 列筛选，当前行 special_series 筛选保留，
// 候选金额自动限定在当前 series 内（series 内排名）；
// 候选金额 REMOVEFILTERS(spu_img_url) 上卷到 spu 粒度（清除 url 子级行筛选）；
// series 汇总行无 spu_id 筛选上下文 → 以 999,999 编码（组内最后，对应小计显示位置）
VAR __SpuRank =
    IF(
        ISINSCOPE('s02_trade_sku_data_d'[spu_id]),
        RANK(
            DENSE,
            FILTER(
                ALL('s02_trade_sku_data_d'[spu_id]),
                NOT ISBLANK(
                    CALCULATE(
                        SUM('s02_trade_sku_data_d'[net_sales_amt]),
                        REMOVEFILTERS('s02_trade_sku_data_d'[spu_img_url]),
                        's02_trade_sku_data_d'[dt] >= __PeriodMin,
                        's02_trade_sku_data_d'[dt] <= __PeriodMax
                    )
                )
            ),
            ORDERBY(
                CALCULATE(
                    SUM('s02_trade_sku_data_d'[net_sales_amt]),
                    REMOVEFILTERS('s02_trade_sku_data_d'[spu_img_url]),
                    's02_trade_sku_data_d'[dt] >= __PeriodMin,
                    's02_trade_sku_data_d'[dt] <= __PeriodMax
                ), DESC,
                's02_trade_sku_data_d'[spu_id], ASC    // 金额相同按 spu_id 升序决胜
            )
        ),
        999999
    )

RETURN
    IF(
        ISBLANK(__CurrentAmt),
        1000000000000,                              // 当期无金额行垫底（键值超出正常区间）
        __SeriesRank * 1000000 + __SpuRank
    )
```

### 4.2 Series Sales SLS Amt Value（当期净销售金额）

```dax
Series Sales SLS Amt Value =
// ========================================
// 度量值: Series Sales SLS Amt Value
// 中文名: 当期净销售金额
// Display Folder: Series Sales Performance\Base Metrics
// 用途: 该行粒度（明细 = spu_id / series 汇总 = special_series）This Period 净销售金额（当前币种）
// 依赖: Slicer_Time_Frame_Min_This[TimeFrame_Min] / Slicer_Time_Frame_Max_This[TimeFrame_Max]
//       Slicer_Currency_Selection[Currency_ExchangeRate]
// 口径: 时间范围看 this period（区间汇总）；该 spu_id 下 sum(net_sales_amt)
// 数据底表: s02_trade_sku_data_d
// 行维度传递: 行维度来自本表，筛选自动传递（明细 / 汇总行均正确，无需桥接）
// 币种: 数据底表仅存 RMB，Value 层换算为当前币种金额（原始值 ÷ 汇率）；
//       RMB 汇率 = 1 时换算前后值相同
// ========================================

// ── This Period 时间区间 ──
VAR __PeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Min_This[TimeFrame_Min])
VAR __PeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

// ── 币种汇率（RMB = 1；USD 动态取自数仓汇率表）──
VAR __ExchangeRate = SELECTEDVALUE(Slicer_Currency_Selection[Currency_ExchangeRate], 1)

// ── 该行粒度 This Period 净销售金额（原始 RMB）──
VAR __BaseValue =
    CALCULATE(
        SUM('s02_trade_sku_data_d'[net_sales_amt]),
        's02_trade_sku_data_d'[dt] >= __PeriodMin,
        's02_trade_sku_data_d'[dt] <= __PeriodMax
    )

RETURN
    DIVIDE(__BaseValue, __ExchangeRate)   // BLANK ÷ 汇率 = BLANK（当期无销售数据行返回空）
```

### 4.3 Series Sales SLS Amt% Value（当期销售金额占比）

```dax
Series Sales SLS Amt% Value =
// ========================================
// 度量值: Series Sales SLS Amt% Value
// 中文名: 当期销售金额占比
// Display Folder: Series Sales Performance\Base Metrics
// 用途: 该 AXC（或 series 汇总行）占 total 的销售金额比例（This Period 区间）
// 依赖: Slicer_Time_Frame_Min_This[TimeFrame_Min] / Slicer_Time_Frame_Max_This[TimeFrame_Max]
// 口径: 分子：该 spu_id 下 sum(net_sales_amt)；
//       分母：sum(net_sales_amt)（移除表格中所有维度字段，但 special_series 不为空）
// 数据底表: s02_trade_sku_data_d
// 说明: 分母 REMOVEFILTERS(三列：series / spu_id / spu_img_url) 上卷至全量有效 series
//       （含表格未显示行与视觉级筛选前的全部商品），同时移除视觉级「不为空」
//       筛选落地的列筛选与 spu_img_url 行筛选（行区域含 spu_img_url 时若
//       不移除该列，分母被当前行 url 筛选收窄为分子自身、占比恒 100%），
//       故必须显式重加 series 非空条件（口径原文要求，且防止空白 series
//       金额混入分母）；分子分母均为原始 RMB 聚合，占比不受币种选择影响
// ========================================

// ── This Period 时间区间 ──
VAR __PeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Min_This[TimeFrame_Min])
VAR __PeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

// ── 分子：当前行粒度 This Period 净销售金额（原始 RMB）──
VAR __Numerator =
    CALCULATE(
        SUM('s02_trade_sku_data_d'[net_sales_amt]),
        's02_trade_sku_data_d'[dt] >= __PeriodMin,
        's02_trade_sku_data_d'[dt] <= __PeriodMax
    )

// ── 分母：全量有效 series 的 This Period 净销售金额 ──
// REMOVEFILTERS(三列) 移除行维度筛选（含 spu_img_url 行筛选）与视觉级
// 「不为空」筛选，保留外部切片器筛选；布尔筛选重加 series 非空
// （NULL / 空字符 / 纯空格一并排除）
VAR __Denominator =
    CALCULATE(
        SUM('s02_trade_sku_data_d'[net_sales_amt]),
        REMOVEFILTERS(
            's02_trade_sku_data_d'[special_series],
            's02_trade_sku_data_d'[spu_id],
            's02_trade_sku_data_d'[spu_img_url]
        ),
        NOT ISBLANK('s02_trade_sku_data_d'[special_series])
            && LEN(TRIM('s02_trade_sku_data_d'[special_series])) > 0,
        's02_trade_sku_data_d'[dt] >= __PeriodMin,
        's02_trade_sku_data_d'[dt] <= __PeriodMax
    )

RETURN
    DIVIDE(__Numerator, __Denominator)
```

### 4.4 Series Sales SLS Unit Value（当期净销售数量）

```dax
Series Sales SLS Unit Value =
// ========================================
// 度量值: Series Sales SLS Unit Value
// 中文名: 当期净销售数量
// Display Folder: Series Sales Performance\Base Metrics
// 用途: 该行粒度 This Period 净销售数量
// 依赖: Slicer_Time_Frame_Min_This[TimeFrame_Min] / Slicer_Time_Frame_Max_This[TimeFrame_Max]
// 口径: 时间范围看 this period；该 spu_id 下 sum(product_qty)
// 数据底表: s02_trade_sku_data_d
// 说明: product_qty 为净销售数量口径字段（net_sales_amt = product_qty ×
//       sales_price 行级计算而来，二者同源）；数量类不涉及币种换算
// ========================================

// ── This Period 时间区间 ──
VAR __PeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Min_This[TimeFrame_Min])
VAR __PeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

RETURN
    CALCULATE(
        SUM('s02_trade_sku_data_d'[product_qty]),
        's02_trade_sku_data_d'[dt] >= __PeriodMin,
        's02_trade_sku_data_d'[dt] <= __PeriodMax
    )
```

### 4.5 Series Sales SLS Unit% Value（当期净销售数量占比）

```dax
Series Sales SLS Unit% Value =
// ========================================
// 度量值: Series Sales SLS Unit% Value
// 中文名: 当期净销售数量占比
// Display Folder: Series Sales Performance\Base Metrics
// 用途: 该 AXC（或 series 汇总行）占 total 的净销售数量比例（This Period 区间）
// 依赖: Slicer_Time_Frame_Min_This[TimeFrame_Min] / Slicer_Time_Frame_Max_This[TimeFrame_Max]
// 口径: 分子：该 spu_id 下 sum(product_qty)；
//       分母：sum(product_qty)（移除表格中所有维度字段，但 special_series 不为空）
// 数据底表: s02_trade_sku_data_d
// 说明: 分母机制同 SLS Amt% Value（REMOVEFILTERS(三列，含 spu_img_url) 上卷 + series 非空还原）
// ========================================

// ── This Period 时间区间 ──
VAR __PeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Min_This[TimeFrame_Min])
VAR __PeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

// ── 分子：当前行粒度 This Period 净销售数量 ──
VAR __Numerator =
    CALCULATE(
        SUM('s02_trade_sku_data_d'[product_qty]),
        's02_trade_sku_data_d'[dt] >= __PeriodMin,
        's02_trade_sku_data_d'[dt] <= __PeriodMax
    )

// ── 分母：全量有效 series 的 This Period 净销售数量 ──
// REMOVEFILTERS(三列，含 spu_img_url 行筛选) 上卷至全量并重加 series 非空
VAR __Denominator =
    CALCULATE(
        SUM('s02_trade_sku_data_d'[product_qty]),
        REMOVEFILTERS(
            's02_trade_sku_data_d'[special_series],
            's02_trade_sku_data_d'[spu_id],
            's02_trade_sku_data_d'[spu_img_url]
        ),
        NOT ISBLANK('s02_trade_sku_data_d'[special_series])
            && LEN(TRIM('s02_trade_sku_data_d'[special_series])) > 0,
        's02_trade_sku_data_d'[dt] >= __PeriodMin,
        's02_trade_sku_data_d'[dt] <= __PeriodMax
    )

RETURN
    DIVIDE(__Numerator, __Denominator)
```

### 4.6 Series Sales EOH Amt Value（当期期末库存金额）

```dax
Series Sales EOH Amt Value =
// ========================================
// 度量值: Series Sales EOH Amt Value
// 中文名: 当期期末库存金额（当前币种）
// Display Folder: Series Sales Performance\Base Metrics
// 用途: 该行粒度（明细 = spu_id / series 汇总 = special_series）This Period
//       最后一天期末库存金额（时点数），用于表格展示与交叉验证
// 依赖: Slicer_Time_Frame_Max_This[TimeFrame_Min] / [TimeFrame_Max]
//       Slicer_Currency_Selection[Currency_ExchangeRate]
// 口径: 时间范围看 this period 最后一天（实现为 end period 范围内最后一个
//       有数据的快照日）；该 spu_id 下 sum(msrp_inv_amt)
// 数据底表: s02_inventory_stock_sales_detail_d
// 行维度传递: 两表无模型关系，行维度值经 TREATAS 显式桥接（IF 标量分支）——
//       明细行（ISINSCOPE(spu_id)）传 spu_id；
//       series 汇总行传 special_series（该 series 全部库存，不受渠道筛选影响）；
//       总计行（若开启）不传行维度值，仅 series 非空全量
// 币种: 数据底表仅存 RMB，Value 层换算为当前币种金额（原始值 ÷ 汇率）
// 说明: inv 表无 platform / shop_name 字段，不受渠道筛选影响（口径限制见注意事项 1）
// ========================================

// ── End Period 时间范围（期末时点类）──
VAR __EndPeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Min])
VAR __EndPeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

// ── 期末日期：end period 最后一天 = Max_This 表 TimeFrame_Max（直接单日过滤）──
VAR __EndPeriodDate = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

// ── 币种汇率（RMB = 1；USD 动态取自数仓汇率表）──
VAR __ExchangeRate = SELECTEDVALUE(Slicer_Currency_Selection[Currency_ExchangeRate], 1)

// ── 该行粒度期末库存金额（原始 RMB，期末快照日单日值，TREATAS 行维度传递）──
VAR __BaseValue =
    IF(
        ISINSCOPE('s02_trade_sku_data_d'[spu_id]),
        // 明细行：传递当前行 spu_id（单 spu 精确匹配）
        CALCULATE(
            SUM('s02_inventory_stock_sales_detail_d'[msrp_inv_amt]),
            TREATAS(
                VALUES('s02_trade_sku_data_d'[spu_id]),
                's02_inventory_stock_sales_detail_d'[spu_id]
            ),
            's02_inventory_stock_sales_detail_d'[dt] = __EndPeriodDate
        ),
        IF(
            ISINSCOPE('s02_trade_sku_data_d'[special_series]),
            // series 汇总行：传递当前行 special_series（该 series 全部库存）
            CALCULATE(
                SUM('s02_inventory_stock_sales_detail_d'[msrp_inv_amt]),
                TREATAS(
                    VALUES('s02_trade_sku_data_d'[special_series]),
                    's02_inventory_stock_sales_detail_d'[special_series]
                ),
                's02_inventory_stock_sales_detail_d'[dt] = __EndPeriodDate
            ),
            // 总计行（若开启）：不传行维度值，全量（special_series 非空）
            CALCULATE(
                SUM('s02_inventory_stock_sales_detail_d'[msrp_inv_amt]),
                NOT ISBLANK('s02_inventory_stock_sales_detail_d'[special_series])
                    && LEN(TRIM('s02_inventory_stock_sales_detail_d'[special_series])) > 0,
                's02_inventory_stock_sales_detail_d'[dt] = __EndPeriodDate
            )
        )
    )

RETURN
    DIVIDE(__BaseValue, __ExchangeRate)   // BLANK ÷ 汇率 = BLANK（快照日无库存数据行返回空）
```

### 4.7 Series Sales EOH Amt% Value（当期期末库存金额占比）

```dax
Series Sales EOH Amt% Value =
// ========================================
// 度量值: Series Sales EOH Amt% Value
// 中文名: 当期期末库存金额占比
// Display Folder: Series Sales Performance\Base Metrics
// 用途: 该 AXC（或 series 汇总行）占 total 的期末库存金额比例（时点数）
// 依赖: Slicer_Time_Frame_Max_This[TimeFrame_Min] / [TimeFrame_Max]
// 口径: 分子：该 spu_id 下 sum(msrp_inv_amt)；分母：sum(msrp_inv_amt)
//       （移除表格中所有维度字段，但 special_series 不为空）；
//       时间范围看 this period 最后一天（end period 范围内最后一个快照日）
// 数据底表: s02_inventory_stock_sales_detail_d
// 说明: 分子 TREATAS 行维度传递（同 EOH Amt Value）；分母为 inv 表全量
//       有效 series 汇总（不受行维度与视觉级筛选影响，显式 series 非空）；
//       分子分母均为原始 RMB 聚合，占比不受币种选择影响；
//       inv 表无渠道字段，指标不受渠道筛选影响（见注意事项 1）
// ========================================

// ── End Period 时间范围（期末时点类）──
VAR __EndPeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Min])
VAR __EndPeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

// ── 期末日期：end period 最后一天 = Max_This 表 TimeFrame_Max（直接单日过滤）──
VAR __EndPeriodDate = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

// ── 分子：当前行粒度期末库存金额（TREATAS 行维度传递，期末快照日单日值）──
VAR __Numerator =
    IF(
        ISINSCOPE('s02_trade_sku_data_d'[spu_id]),
        CALCULATE(
            SUM('s02_inventory_stock_sales_detail_d'[msrp_inv_amt]),
            TREATAS(
                VALUES('s02_trade_sku_data_d'[spu_id]),
                's02_inventory_stock_sales_detail_d'[spu_id]
            ),
            's02_inventory_stock_sales_detail_d'[dt] = __EndPeriodDate
        ),
        IF(
            ISINSCOPE('s02_trade_sku_data_d'[special_series]),
            CALCULATE(
                SUM('s02_inventory_stock_sales_detail_d'[msrp_inv_amt]),
                TREATAS(
                    VALUES('s02_trade_sku_data_d'[special_series]),
                    's02_inventory_stock_sales_detail_d'[special_series]
                ),
                's02_inventory_stock_sales_detail_d'[dt] = __EndPeriodDate
            ),
            CALCULATE(
                SUM('s02_inventory_stock_sales_detail_d'[msrp_inv_amt]),
                NOT ISBLANK('s02_inventory_stock_sales_detail_d'[special_series])
                    && LEN(TRIM('s02_inventory_stock_sales_detail_d'[special_series])) > 0,
                's02_inventory_stock_sales_detail_d'[dt] = __EndPeriodDate
            )
        )
    )

// ── 分母：inv 表全量有效 series 的期末库存金额（series 非空，保留 Division 等外部筛选）──
VAR __Denominator =
    CALCULATE(
        SUM('s02_inventory_stock_sales_detail_d'[msrp_inv_amt]),
        NOT ISBLANK('s02_inventory_stock_sales_detail_d'[special_series])
            && LEN(TRIM('s02_inventory_stock_sales_detail_d'[special_series])) > 0,
        's02_inventory_stock_sales_detail_d'[dt] = __EndPeriodDate
    )

RETURN
    DIVIDE(__Numerator, __Denominator)
```

### 4.8 Series Sales EOH Unit Value（当期期末库存数量）

```dax
Series Sales EOH Unit Value =
// ========================================
// 度量值: Series Sales EOH Unit Value
// 中文名: 当期期末库存数量
// Display Folder: Series Sales Performance\Base Metrics
// 用途: 该行粒度 This Period 最后一天期末库存数量（时点数）
// 依赖: Slicer_Time_Frame_Max_This[TimeFrame_Min] / [TimeFrame_Max]
// 口径: 时间范围看 this period 最后一天；该 spu_id 下 sum(stock_inv_qty)
// 数据底表: s02_inventory_stock_sales_detail_d
// 说明: stock_inv_qty 为在库库存数量口径字段（与 ST% 库存分母的 inv_qty
//       为不同字段，按口径文档分别使用）；数量类不涉及币种换算；
//       TREATAS 行维度传递同 EOH Amt Value
// ========================================

// ── End Period 时间范围（期末时点类）──
VAR __EndPeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Min])
VAR __EndPeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

// ── 期末日期：end period 最后一天 = Max_This 表 TimeFrame_Max（直接单日过滤）──
VAR __EndPeriodDate = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

RETURN
    IF(
        ISINSCOPE('s02_trade_sku_data_d'[spu_id]),
        // 明细行：传递当前行 spu_id
        CALCULATE(
            SUM('s02_inventory_stock_sales_detail_d'[stock_inv_qty]),
            TREATAS(
                VALUES('s02_trade_sku_data_d'[spu_id]),
                's02_inventory_stock_sales_detail_d'[spu_id]
            ),
            's02_inventory_stock_sales_detail_d'[dt] = __EndPeriodDate
        ),
        IF(
            ISINSCOPE('s02_trade_sku_data_d'[special_series]),
            // series 汇总行：传递当前行 special_series
            CALCULATE(
                SUM('s02_inventory_stock_sales_detail_d'[stock_inv_qty]),
                TREATAS(
                    VALUES('s02_trade_sku_data_d'[special_series]),
                    's02_inventory_stock_sales_detail_d'[special_series]
                ),
                's02_inventory_stock_sales_detail_d'[dt] = __EndPeriodDate
            ),
            // 总计行（若开启）：不传行维度值，全量（special_series 非空）
            CALCULATE(
                SUM('s02_inventory_stock_sales_detail_d'[stock_inv_qty]),
                NOT ISBLANK('s02_inventory_stock_sales_detail_d'[special_series])
                    && LEN(TRIM('s02_inventory_stock_sales_detail_d'[special_series])) > 0,
                's02_inventory_stock_sales_detail_d'[dt] = __EndPeriodDate
            )
        )
    )
```

### 4.9 Series Sales EOH Unit% Value（当期期末库存数量占比）

```dax
Series Sales EOH Unit% Value =
// ========================================
// 度量值: Series Sales EOH Unit% Value
// 中文名: 当期期末库存数量占比
// Display Folder: Series Sales Performance\Base Metrics
// 用途: 该 AXC（或 series 汇总行）占 total 的期末库存数量比例（时点数）
// 依赖: Slicer_Time_Frame_Max_This[TimeFrame_Min] / [TimeFrame_Max]
// 口径: 分子：该 spu_id 下 sum(stock_inv_qty)；分母：sum(stock_inv_qty)
//       （移除表格中所有维度字段，但 special_series 不为空）
// 数据底表: s02_inventory_stock_sales_detail_d
// 说明: 分子 TREATAS 行维度传递（同 EOH Unit Value）；分母机制同 EOH Amt% Value
// ========================================

// ── End Period 时间范围（期末时点类）──
VAR __EndPeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Min])
VAR __EndPeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

// ── 期末日期：end period 最后一天 = Max_This 表 TimeFrame_Max（直接单日过滤）──
VAR __EndPeriodDate = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

// ── 分子：当前行粒度期末库存数量（TREATAS 行维度传递）──
VAR __Numerator =
    IF(
        ISINSCOPE('s02_trade_sku_data_d'[spu_id]),
        CALCULATE(
            SUM('s02_inventory_stock_sales_detail_d'[stock_inv_qty]),
            TREATAS(
                VALUES('s02_trade_sku_data_d'[spu_id]),
                's02_inventory_stock_sales_detail_d'[spu_id]
            ),
            's02_inventory_stock_sales_detail_d'[dt] = __EndPeriodDate
        ),
        IF(
            ISINSCOPE('s02_trade_sku_data_d'[special_series]),
            CALCULATE(
                SUM('s02_inventory_stock_sales_detail_d'[stock_inv_qty]),
                TREATAS(
                    VALUES('s02_trade_sku_data_d'[special_series]),
                    's02_inventory_stock_sales_detail_d'[special_series]
                ),
                's02_inventory_stock_sales_detail_d'[dt] = __EndPeriodDate
            ),
            CALCULATE(
                SUM('s02_inventory_stock_sales_detail_d'[stock_inv_qty]),
                NOT ISBLANK('s02_inventory_stock_sales_detail_d'[special_series])
                    && LEN(TRIM('s02_inventory_stock_sales_detail_d'[special_series])) > 0,
                's02_inventory_stock_sales_detail_d'[dt] = __EndPeriodDate
            )
        )
    )

// ── 分母：inv 表全量有效 series 的期末库存数量 ──
VAR __Denominator =
    CALCULATE(
        SUM('s02_inventory_stock_sales_detail_d'[stock_inv_qty]),
        NOT ISBLANK('s02_inventory_stock_sales_detail_d'[special_series])
            && LEN(TRIM('s02_inventory_stock_sales_detail_d'[special_series])) > 0,
        's02_inventory_stock_sales_detail_d'[dt] = __EndPeriodDate
    )

RETURN
    DIVIDE(__Numerator, __Denominator)
```

### 4.10 Series Sales AUR Value（当期件单价）

```dax
Series Sales AUR Value =
// ========================================
// 度量值: Series Sales AUR Value
// 中文名: 当期件单价（当前币种）
// Display Folder: Series Sales Performance\Base Metrics
// 用途: 该行粒度 This Period 净销售金额 ÷ 净销售数量
// 依赖: Slicer_Time_Frame_Min_This[TimeFrame_Min] / Slicer_Time_Frame_Max_This[TimeFrame_Max]
//       Slicer_Currency_Selection[Currency_ExchangeRate]
// 口径: 时间范围看 this period；该 spu_id 下 sum(net_sales_amt) / sum(product_qty)
// 数据底表: s02_trade_sku_data_d
// 币种: Value 层换算当前币种（RMB 件单价 ÷ 汇率，数量不变）
// 说明: series 汇总行为加权件单价（总金额 ÷ 总数量，非 AXC 均值的算术平均）；
//       当期无数量（分母为空 / 0）时 DIVIDE 返回 BLANK
// ========================================

// ── This Period 时间区间 ──
VAR __PeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Min_This[TimeFrame_Min])
VAR __PeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

// ── 币种汇率（RMB = 1；USD 动态取自数仓汇率表）──
VAR __ExchangeRate = SELECTEDVALUE(Slicer_Currency_Selection[Currency_ExchangeRate], 1)

// ── 分子：该行粒度 This Period 净销售金额（原始 RMB）──
VAR __Numerator =
    CALCULATE(
        SUM('s02_trade_sku_data_d'[net_sales_amt]),
        's02_trade_sku_data_d'[dt] >= __PeriodMin,
        's02_trade_sku_data_d'[dt] <= __PeriodMax
    )

// ── 分母：该行粒度 This Period 净销售数量 ──
VAR __Denominator =
    CALCULATE(
        SUM('s02_trade_sku_data_d'[product_qty]),
        's02_trade_sku_data_d'[dt] >= __PeriodMin,
        's02_trade_sku_data_d'[dt] <= __PeriodMax
    )

// ── RMB 件单价 → 当前币种件单价 ──
VAR __BaseValue = DIVIDE(__Numerator, __Denominator)

RETURN
    DIVIDE(__BaseValue, __ExchangeRate)
```

### 4.11 Series Sales MD Value（当期平均折扣）

```dax
Series Sales MD Value =
// ========================================
// 度量值: Series Sales MD Value
// 中文名: 当期平均折扣
// Display Folder: Series Sales Performance\Base Metrics
// 用途: 该行粒度 This Period 平均折扣 = 1 - 折扣金额占比
// 依赖: Slicer_Time_Frame_Min_This[TimeFrame_Min] / Slicer_Time_Frame_Max_This[TimeFrame_Max]
// 口径: 时间范围看 this period；该 spu_id 下
//       1 - sum(product_qty*md_price) / sum(product_qty*msrp)
// 数据底表: s02_trade_sku_data_d
// 说明: md_price / msrp 为行级字段，行级乘积后求和（SUMX 行迭代）；
//       md_price 或 msrp 为空的行该乘积为空、不计入对应汇总（与 SQL SUM
//       忽略 NULL 行为一致）；series 汇总行为 1 - 总折扣金额 ÷ 总吊牌金额；
//       分母为空 / 0 时折扣比例 BLANK，MD 返回 BLANK；占比类不涉及币种换算
// ========================================

// ── This Period 时间区间 ──
VAR __PeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Min_This[TimeFrame_Min])
VAR __PeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

// ── 分子：该行粒度 This Period 折扣价金额（product_qty × md_price 行级求和）──
VAR __MdPriceAmt =
    CALCULATE(
        SUMX(
            's02_trade_sku_data_d',
            's02_trade_sku_data_d'[product_qty] * 's02_trade_sku_data_d'[md_price]
        ),
        's02_trade_sku_data_d'[dt] >= __PeriodMin,
        's02_trade_sku_data_d'[dt] <= __PeriodMax
    )

// ── 分母：该行粒度 This Period 吊牌价金额（product_qty × msrp 行级求和）──
VAR __MsrpAmt =
    CALCULATE(
        SUMX(
            's02_trade_sku_data_d',
            's02_trade_sku_data_d'[product_qty] * 's02_trade_sku_data_d'[msrp]
        ),
        's02_trade_sku_data_d'[dt] >= __PeriodMin,
        's02_trade_sku_data_d'[dt] <= __PeriodMax
    )

// ── 折扣价 ÷ 吊牌价 ──
VAR __MdRatio = DIVIDE(__MdPriceAmt, __MsrpAmt)

RETURN
    IF(
        ISBLANK(__MdRatio),
        BLANK(),
        1 - __MdRatio
    )
```

### 4.12 Series Sales YTD SLS Unit Value（YTD净销售数量）

```dax
Series Sales YTD SLS Unit Value =
// ========================================
// 度量值: Series Sales YTD SLS Unit Value
// 中文名: YTD DCom净销售数量
// Display Folder: Series Sales Performance\Base Metrics
// 用途: 该行粒度年初至今（this period 所在财年）净销售数量
// 依赖: Slicer_Time_Frame_Max_This[Fiscal_Year_First_Day] / [TimeFrame_Max]
// 口径: 时间范围看 this period 所在财年第一天至 this period 最后一天，
//       与 last period 无关；该 spu_id 下 sum(product_qty)
// 数据底表: s02_trade_sku_data_d
// 说明: 财年第一天取自 Slicer_Time_Frame_Max_This[Fiscal_Year_First_Day]
//       （该行 TimeFrame_Min 落入的财年区间第一天，取数时已生成）；
//       模型加载窗口早于财年第一天时，实际统计范围为窗口 ∩ YTD 区间
//       （见注意事项 7）；数量类不涉及币种换算
// ========================================

// ── YTD 时间区间（财年第一天 ~ this period 最后一天）──
VAR __FyFirstDay = SELECTEDVALUE(Slicer_Time_Frame_Max_This[Fiscal_Year_First_Day])
VAR __PeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

RETURN
    CALCULATE(
        SUM('s02_trade_sku_data_d'[product_qty]),
        's02_trade_sku_data_d'[dt] >= __FyFirstDay,
        's02_trade_sku_data_d'[dt] <= __PeriodMax
    )
```

### 4.13 Series Sales YTD ST% (Unit) Value（YTD售罄率%（数量））

```dax
Series Sales YTD ST% (Unit) Value =
// ========================================
// 度量值: Series Sales YTD ST% (Unit) Value
// 中文名: YTD售罄率%（数量）
// Display Folder: Series Sales Performance\Base Metrics
// 用途: 年至今销售数量 /（年至今销售数量 + 期末库存数量）
// 依赖: Slicer_Time_Frame_Max_This[Fiscal_Year_First_Day] / [TimeFrame_Min] / [TimeFrame_Max]
// 口径: 销售数量：时间范围看 this period 所在财年第一天至 this period 最后一天；
//       期末库存数量：看所选时间范围 end period 最后一天（快照日单日）；
//       sales.product_qty / (sales.product_qty + inv.inv_qty)
// 数据底表: s02_trade_sku_data_d（sales）；s02_inventory_stock_sales_detail_d（inv）
// 行维度传递: 销售侧分子沿用本表行筛选；库存侧加项 TREATAS 桥接
//       （明细传 spu_id / series 汇总传 special_series / 总计不传），
//       分子与库存加项在同一行粒度上配对
// 说明: ST% 库存字段为 inv_qty（库存数量），与 EOH Unit 的 stock_inv_qty
//       为不同字段，按口径文档分别使用；分子分母同步上卷后相除；
//       数量口径不涉及币种换算
// ========================================

// ── YTD 时间区间（财年第一天 ~ this period 最后一天）──
VAR __FyFirstDay = SELECTEDVALUE(Slicer_Time_Frame_Max_This[Fiscal_Year_First_Day])
VAR __PeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

// ── End Period 时间范围（期末时点类）──
VAR __EndPeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Min])
VAR __EndPeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

// ── 期末日期：end period 最后一天 = Max_This 表 TimeFrame_Max（直接单日过滤）──
VAR __EndPeriodDate = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

// ── 分子：该行粒度 YTD 销售数量（trade 表行筛选自动传递）──
VAR __YtdSalesQty =
    CALCULATE(
        SUM('s02_trade_sku_data_d'[product_qty]),
        's02_trade_sku_data_d'[dt] >= __FyFirstDay,
        's02_trade_sku_data_d'[dt] <= __PeriodMax
    )

// ── 库存加项：该行粒度期末库存数量（inv_qty，TREATAS 行维度传递）──
VAR __EndInvQty =
    IF(
        ISINSCOPE('s02_trade_sku_data_d'[spu_id]),
        CALCULATE(
            SUM('s02_inventory_stock_sales_detail_d'[inv_qty]),
            TREATAS(
                VALUES('s02_trade_sku_data_d'[spu_id]),
                's02_inventory_stock_sales_detail_d'[spu_id]
            ),
            's02_inventory_stock_sales_detail_d'[dt] = __EndPeriodDate
        ),
        IF(
            ISINSCOPE('s02_trade_sku_data_d'[special_series]),
            CALCULATE(
                SUM('s02_inventory_stock_sales_detail_d'[inv_qty]),
                TREATAS(
                    VALUES('s02_trade_sku_data_d'[special_series]),
                    's02_inventory_stock_sales_detail_d'[special_series]
                ),
                's02_inventory_stock_sales_detail_d'[dt] = __EndPeriodDate
            ),
            CALCULATE(
                SUM('s02_inventory_stock_sales_detail_d'[inv_qty]),
                NOT ISBLANK('s02_inventory_stock_sales_detail_d'[special_series])
                    && LEN(TRIM('s02_inventory_stock_sales_detail_d'[special_series])) > 0,
                's02_inventory_stock_sales_detail_d'[dt] = __EndPeriodDate
            )
        )
    )

RETURN
    DIVIDE(
        __YtdSalesQty,
        __YtdSalesQty + __EndInvQty
    )
```

### 4.14 Series Sales YTD ST% (Amt) Value（YTD售罄率%（金额））

```dax
Series Sales YTD ST% (Amt) Value =
// ========================================
// 度量值: Series Sales YTD ST% (Amt) Value
// 中文名: YTD售罄率%（金额）
// Display Folder: Series Sales Performance\Base Metrics
// 用途: 年至今销售金额 /（年至今销售金额 + 期末库存金额）
// 依赖: Slicer_Time_Frame_Max_This[Fiscal_Year_First_Day] / [TimeFrame_Min] / [TimeFrame_Max]
// 口径: 销售金额：时间范围看 this period 所在财年第一天至 this period 最后一天；
//       期末库存金额：看所选时间范围 end period 最后一天（快照日单日）；
//       sales.net_sales_amt / (sales.net_sales_amt + inv.msrp_inv_amt)
// 数据底表: s02_trade_sku_data_d（sales）；s02_inventory_stock_sales_detail_d（inv）
// 行维度传递: 同 YTD ST% (Unit) Value（明细传 spu_id / 汇总传 special_series / 总计不传）
// 说明: 分子分母均为原始 RMB 聚合（不经汇率换算），占比不受币种选择影响
// ========================================

// ── YTD 时间区间（财年第一天 ~ this period 最后一天）──
VAR __FyFirstDay = SELECTEDVALUE(Slicer_Time_Frame_Max_This[Fiscal_Year_First_Day])
VAR __PeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

// ── End Period 时间范围（期末时点类）──
VAR __EndPeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Min])
VAR __EndPeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

// ── 期末日期：end period 最后一天 = Max_This 表 TimeFrame_Max（直接单日过滤）──
VAR __EndPeriodDate = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

// ── 分子：该行粒度 YTD 销售金额（原始 RMB）──
VAR __YtdSalesAmt =
    CALCULATE(
        SUM('s02_trade_sku_data_d'[net_sales_amt]),
        's02_trade_sku_data_d'[dt] >= __FyFirstDay,
        's02_trade_sku_data_d'[dt] <= __PeriodMax
    )

// ── 库存加项：该行粒度期末库存金额（TREATAS 行维度传递）──
VAR __EndInvAmt =
    IF(
        ISINSCOPE('s02_trade_sku_data_d'[spu_id]),
        CALCULATE(
            SUM('s02_inventory_stock_sales_detail_d'[msrp_inv_amt]),
            TREATAS(
                VALUES('s02_trade_sku_data_d'[spu_id]),
                's02_inventory_stock_sales_detail_d'[spu_id]
            ),
            's02_inventory_stock_sales_detail_d'[dt] = __EndPeriodDate
        ),
        IF(
            ISINSCOPE('s02_trade_sku_data_d'[special_series]),
            CALCULATE(
                SUM('s02_inventory_stock_sales_detail_d'[msrp_inv_amt]),
                TREATAS(
                    VALUES('s02_trade_sku_data_d'[special_series]),
                    's02_inventory_stock_sales_detail_d'[special_series]
                ),
                's02_inventory_stock_sales_detail_d'[dt] = __EndPeriodDate
            ),
            CALCULATE(
                SUM('s02_inventory_stock_sales_detail_d'[msrp_inv_amt]),
                NOT ISBLANK('s02_inventory_stock_sales_detail_d'[special_series])
                    && LEN(TRIM('s02_inventory_stock_sales_detail_d'[special_series])) > 0,
                's02_inventory_stock_sales_detail_d'[dt] = __EndPeriodDate
            )
        )
    )

RETURN
    DIVIDE(
        __YtdSalesAmt,
        __YtdSalesAmt + __EndInvAmt
    )
```

### 4.15 Series Sales LTD SLS Unit Value（LTD净销售数量）

```dax
Series Sales LTD SLS Unit Value =
// ========================================
// 度量值: Series Sales LTD SLS Unit Value
// 中文名: LTD DCom净销售数量
// Display Folder: Series Sales Performance\Base Metrics
// 用途: 该行粒度开店至今（≤ this period 最后一天）净销售数量
// 依赖: Slicer_Time_Frame_Max_This[TimeFrame_Max]
// 口径: 销售数量：≤ 时间范围 this period 的最后一天（无固定起始日），
//       与 last period 无关；该 spu_id 下 sum(product_qty)
// 数据底表: s02_trade_sku_data_d
// 说明: 模型加载窗口外历史数据不在模型中，LTD 实际统计范围为
//       窗口 ∩（dt ≤ this period 最后一天），见注意事项 7；
//       数量类不涉及币种换算
// ========================================

// ── LTD 时间上限（this period 最后一天）──
VAR __PeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

RETURN
    CALCULATE(
        SUM('s02_trade_sku_data_d'[product_qty]),
        's02_trade_sku_data_d'[dt] <= __PeriodMax
    )
```

### 4.16 Series Sales LTD ST% (Unit) Value（LTD售罄率%（数量））

```dax
Series Sales LTD ST% (Unit) Value =
// ========================================
// 度量值: Series Sales LTD ST% (Unit) Value
// 中文名: LTD售罄率%（数量）
// Display Folder: Series Sales Performance\Base Metrics
// 用途: 开店以来销售数量 /（开店以来销售数量 + 期末库存数量）
// 依赖: Slicer_Time_Frame_Max_This[TimeFrame_Min] / [TimeFrame_Max]
// 口径: 销售数量：≤ 时间范围 this period 的最后一天（无固定起始日）；
//       期末库存数量：看所选时间范围 end period 最后一天（快照日单日）；
//       sales.product_qty / (sales.product_qty + inv.inv_qty)
// 数据底表: s02_trade_sku_data_d（sales）；s02_inventory_stock_sales_detail_d（inv）
// 行维度传递: 同 YTD ST% (Unit) Value（明细传 spu_id / 汇总传 special_series / 总计不传）
// 说明: ST% 库存字段为 inv_qty；LTD 销售侧受模型加载窗口限制（见注意事项 7）；
//       数量口径不涉及币种换算
// ========================================

// ── LTD 时间上限（this period 最后一天）──
VAR __PeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

// ── End Period 时间范围（期末时点类）──
VAR __EndPeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Min])
VAR __EndPeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

// ── 期末日期：end period 最后一天 = Max_This 表 TimeFrame_Max（直接单日过滤）──
VAR __EndPeriodDate = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

// ── 分子：该行粒度 LTD 销售数量（trade 表行筛选自动传递）──
VAR __LtdSalesQty =
    CALCULATE(
        SUM('s02_trade_sku_data_d'[product_qty]),
        's02_trade_sku_data_d'[dt] <= __PeriodMax
    )

// ── 库存加项：该行粒度期末库存数量（inv_qty，TREATAS 行维度传递）──
VAR __EndInvQty =
    IF(
        ISINSCOPE('s02_trade_sku_data_d'[spu_id]),
        CALCULATE(
            SUM('s02_inventory_stock_sales_detail_d'[inv_qty]),
            TREATAS(
                VALUES('s02_trade_sku_data_d'[spu_id]),
                's02_inventory_stock_sales_detail_d'[spu_id]
            ),
            's02_inventory_stock_sales_detail_d'[dt] = __EndPeriodDate
        ),
        IF(
            ISINSCOPE('s02_trade_sku_data_d'[special_series]),
            CALCULATE(
                SUM('s02_inventory_stock_sales_detail_d'[inv_qty]),
                TREATAS(
                    VALUES('s02_trade_sku_data_d'[special_series]),
                    's02_inventory_stock_sales_detail_d'[special_series]
                ),
                's02_inventory_stock_sales_detail_d'[dt] = __EndPeriodDate
            ),
            CALCULATE(
                SUM('s02_inventory_stock_sales_detail_d'[inv_qty]),
                NOT ISBLANK('s02_inventory_stock_sales_detail_d'[special_series])
                    && LEN(TRIM('s02_inventory_stock_sales_detail_d'[special_series])) > 0,
                's02_inventory_stock_sales_detail_d'[dt] = __EndPeriodDate
            )
        )
    )

RETURN
    DIVIDE(
        __LtdSalesQty,
        __LtdSalesQty + __EndInvQty
    )
```

### 4.17 Series Sales SLS Amt Display（当期净销售金额显示）

```dax
Series Sales SLS Amt Display =
// ========================================
// 度量值: Series Sales SLS Amt Display
// 中文名: 当期净销售金额显示
// Display Folder: Series Sales Performance\Formatting
// 用途: currency 格式化（币种符号 + 千分位整数，符号由币种切片器决定）；BLANK 显示 "-"
// 依赖: [Series Sales SLS Amt Value], Slicer_Currency_Selection[Currency_Symbol]
// 数据格式: 币种符号 & #,##0（如 ¥1,000 / $1,000）
// 说明: 本表格无 TopN 类视觉级金额筛选，当期无销售数据的行正常显示（各指标为 "-"），
//       BLANK 统一显示 "-"（不返回 BLANK()，行显示与隐藏由维度值决定）
// ========================================
    VAR __Value = [Series Sales SLS Amt Value]
    VAR __CurrencySymbol = SELECTEDVALUE(Slicer_Currency_Selection[Currency_Symbol], "¥")
    RETURN
        IF(
            ISBLANK(__Value),
    // 该行所有度量均为 BLANK() 时，通常会自动隐藏该行（包括层级行），需要所有指标都为 BLANK() 才会自动隐藏该行。
            BLANK(),
            __CurrencySymbol & FORMAT(__Value, "#,##0")
        )
```

### 4.18 Series Sales SLS Amt% Display（当期销售金额占比显示）

```dax
Series Sales SLS Amt% Display =
// ========================================
// 度量值: Series Sales SLS Amt% Display
// 中文名: 当期销售金额占比显示
// Display Folder: Series Sales Performance\Formatting
// 用途: percent_0dp 格式化（百分比整数，不含正号）；BLANK 显示 "-"
// 依赖: [Series Sales SLS Amt% Value]
// 数据格式: #,##0%（如 26%）
// ========================================
    VAR __Value = [Series Sales SLS Amt% Value]
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            FORMAT(__Value, "#,##0%")
        )
```

### 4.19 Series Sales SLS Unit Display（当期净销售数量显示）

```dax
Series Sales SLS Unit Display =
// ========================================
// 度量值: Series Sales SLS Unit Display
// 中文名: 当期净销售数量显示
// Display Folder: Series Sales Performance\Formatting
// 用途: integer 格式化（整数千分位）；BLANK 显示 "-"
// 依赖: [Series Sales SLS Unit Value]
// 数据格式: #,##0（如 1,234）
// ========================================
    VAR __Value = [Series Sales SLS Unit Value]
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            FORMAT(__Value, "#,##0")
        )
```

### 4.20 Series Sales SLS Unit% Display（当期净销售数量占比显示）

```dax
Series Sales SLS Unit% Display =
// ========================================
// 度量值: Series Sales SLS Unit% Display
// 中文名: 当期净销售数量占比显示
// Display Folder: Series Sales Performance\Formatting
// 用途: percent_0dp 格式化（百分比整数，不含正号）；BLANK 显示 "-"
// 依赖: [Series Sales SLS Unit% Value]
// 数据格式: #,##0%（如 26%）
// ========================================
    VAR __Value = [Series Sales SLS Unit% Value]
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            FORMAT(__Value, "#,##0%")
        )
```

### 4.21 Series Sales EOH Amt Display（当期期末库存金额显示）

```dax
Series Sales EOH Amt Display =
// ========================================
// 度量值: Series Sales EOH Amt Display
// 中文名: 当期期末库存金额显示
// Display Folder: Series Sales Performance\Formatting
// 用途: currency 格式化（币种符号 + 千分位整数，符号由币种切片器决定）；BLANK 显示 "-"
// 依赖: [Series Sales EOH Amt Value], Slicer_Currency_Selection[Currency_Symbol]
// 数据格式: 币种符号 & #,##0（如 ¥3,160 / $3,160）
// ========================================
    VAR __Value = [Series Sales EOH Amt Value]
    VAR __CurrencySymbol = SELECTEDVALUE(Slicer_Currency_Selection[Currency_Symbol], "¥")
    RETURN
        IF(
            ISBLANK(__Value),
    // 该行所有度量均为 BLANK() 时，通常会自动隐藏该行（包括层级行），需要所有指标都为 BLANK() 才会自动隐藏该行。
            BLANK(),
            __CurrencySymbol & FORMAT(__Value, "#,##0")
        )
```

### 4.22 Series Sales EOH Amt% Display（当期期末库存金额占比显示）

```dax
Series Sales EOH Amt% Display =
// ========================================
// 度量值: Series Sales EOH Amt% Display
// 中文名: 当期期末库存金额占比显示
// Display Folder: Series Sales Performance\Formatting
// 用途: percent_0dp 格式化（百分比整数，不含正号）；BLANK 显示 "-"
// 依赖: [Series Sales EOH Amt% Value]
// 数据格式: #,##0%（如 26%）
// ========================================
    VAR __Value = [Series Sales EOH Amt% Value]
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            FORMAT(__Value, "#,##0%")
        )
```

### 4.23 Series Sales EOH Unit Display（当期期末库存数量显示）

```dax
Series Sales EOH Unit Display =
// ========================================
// 度量值: Series Sales EOH Unit Display
// 中文名: 当期期末库存数量显示
// Display Folder: Series Sales Performance\Formatting
// 用途: integer 格式化（整数千分位）；BLANK 显示 "-"
// 依赖: [Series Sales EOH Unit Value]
// 数据格式: #,##0（如 3,160）
// ========================================
    VAR __Value = [Series Sales EOH Unit Value]
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            FORMAT(__Value, "#,##0")
        )
```

### 4.24 Series Sales EOH Unit% Display（当期期末库存数量占比显示）

```dax
Series Sales EOH Unit% Display =
// ========================================
// 度量值: Series Sales EOH Unit% Display
// 中文名: 当期期末库存数量占比显示
// Display Folder: Series Sales Performance\Formatting
// 用途: percent_0dp 格式化（百分比整数，不含正号）；BLANK 显示 "-"
// 依赖: [Series Sales EOH Unit% Value]
// 数据格式: #,##0%（如 26%）
// ========================================
    VAR __Value = [Series Sales EOH Unit% Value]
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            FORMAT(__Value, "#,##0%")
        )
```

### 4.25 Series Sales AUR Display（当期件单价显示）

```dax
Series Sales AUR Display =
// ========================================
// 度量值: Series Sales AUR Display
// 中文名: 当期件单价显示
// Display Folder: Series Sales Performance\Formatting
// 用途: currency 格式化（币种符号 + 千分位整数，符号由币种切片器决定）；BLANK 显示 "-"
// 依赖: [Series Sales AUR Value], Slicer_Currency_Selection[Currency_Symbol]
// 数据格式: 币种符号 & #,##0（如 ¥369 / $369）
// ========================================
    VAR __Value = [Series Sales AUR Value]
    VAR __CurrencySymbol = SELECTEDVALUE(Slicer_Currency_Selection[Currency_Symbol], "¥")
    RETURN
        IF(
            ISBLANK(__Value),
    // 该行所有度量均为 BLANK() 时，通常会自动隐藏该行（包括层级行），需要所有指标都为 BLANK() 才会自动隐藏该行。
            BLANK(),
            __CurrencySymbol & FORMAT(__Value, "#,##0")
        )
```

### 4.26 Series Sales MD Display（当期平均折扣显示）

```dax
Series Sales MD Display =
// ========================================
// 度量值: Series Sales MD Display
// 中文名: 当期平均折扣显示
// Display Folder: Series Sales Performance\Formatting
// 用途: percent_0dp 格式化（百分比整数，不含正号）；BLANK 显示 "-"
// 依赖: [Series Sales MD Value]
// 数据格式: #,##0%（如 32%）
// ========================================
    VAR __Value = [Series Sales MD Value]
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            FORMAT(__Value, "#,##0%")
        )
```

### 4.27 Series Sales YTD SLS Unit Display（YTD净销售数量显示）

```dax
Series Sales YTD SLS Unit Display =
// ========================================
// 度量值: Series Sales YTD SLS Unit Display
// 中文名: YTD DCom净销售数量显示
// Display Folder: Series Sales Performance\Formatting
// 用途: integer 格式化（整数千分位）；BLANK 显示 "-"
// 依赖: [Series Sales YTD SLS Unit Value]
// 数据格式: #,##0（如 12,345）
// ========================================
    VAR __Value = [Series Sales YTD SLS Unit Value]
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            FORMAT(__Value, "#,##0")
        )
```

### 4.28 Series Sales YTD ST% (Unit) Display（YTD售罄率%（数量）显示）

```dax
Series Sales YTD ST% (Unit) Display =
// ========================================
// 度量值: Series Sales YTD ST% (Unit) Display
// 中文名: YTD售罄率%（数量）显示
// Display Folder: Series Sales Performance\Formatting
// 用途: percent_0dp 格式化（百分比整数，不含正号）；BLANK 显示 "-"
// 依赖: [Series Sales YTD ST% (Unit) Value]
// 数据格式: #,##0%（如 58%）
// ========================================
    VAR __Value = [Series Sales YTD ST% (Unit) Value]
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            FORMAT(__Value, "#,##0%")
        )
```

### 4.29 Series Sales YTD ST% (Amt) Display（YTD售罄率%（金额）显示）

```dax
Series Sales YTD ST% (Amt) Display =
// ========================================
// 度量值: Series Sales YTD ST% (Amt) Display
// 中文名: YTD售罄率%（金额）显示
// Display Folder: Series Sales Performance\Formatting
// 用途: percent_0dp 格式化（百分比整数，不含正号）；BLANK 显示 "-"
// 依赖: [Series Sales YTD ST% (Amt) Value]
// 数据格式: #,##0%（如 61%）
// ========================================
    VAR __Value = [Series Sales YTD ST% (Amt) Value]
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            FORMAT(__Value, "#,##0%")
        )
```

### 4.30 Series Sales LTD SLS Unit Display（LTD净销售数量显示）

```dax
Series Sales LTD SLS Unit Display =
// ========================================
// 度量值: Series Sales LTD SLS Unit Display
// 中文名: LTD DCom净销售数量显示
// Display Folder: Series Sales Performance\Formatting
// 用途: integer 格式化（整数千分位）；BLANK 显示 "-"
// 依赖: [Series Sales LTD SLS Unit Value]
// 数据格式: #,##0（如 45,678）
// ========================================
    VAR __Value = [Series Sales LTD SLS Unit Value]
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            FORMAT(__Value, "#,##0")
        )
```

### 4.31 Series Sales LTD ST% (Unit) Display（LTD售罄率%（数量）显示）

```dax
Series Sales LTD ST% (Unit) Display =
// ========================================
// 度量值: Series Sales LTD ST% (Unit) Display
// 中文名: LTD售罄率%（数量）显示
// Display Folder: Series Sales Performance\Formatting
// 用途: percent_0dp 格式化（百分比整数，不含正号）；BLANK 显示 "-"
// 依赖: [Series Sales LTD ST% (Unit) Value]
// 数据格式: #,##0%（如 72%）
// ========================================
    VAR __Value = [Series Sales LTD ST% (Unit) Value]
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            FORMAT(__Value, "#,##0%")
        )
```

### 4.32 Series Sales IsEmpty（行非空判定）

```dax
Series Sales IsEmpty =
// ========================================
// 度量值: Series Sales IsEmpty
// 中文名: 行非空判定
// Display Folder: Series Sales Performance\Rank
// 用途: 行可见性判定——该行全部核心指标为空时返回 0，任一有值返回 1；
//       用于表格视觉级筛选器（IsEmpty = 1 仅显示有数据的行，
//       排除当期 / YTD / LTD / 期末库存全空的行）
// 依赖: SLS Amt / SLS Unit / EOH Amt / EOH Unit / YTD SLS Unit /
//       LTD SLS Unit Value
// 组合简化: SLS Amt 为空则 SLS Amt% 必为空（分子同源），占比类不单独判断，
//       同理 SLS Unit% / EOH Amt% / EOH Unit% 依赖对应值指标；
//       AUR（= Amt ÷ Unit）、MD（记录集同窗口）、ST%（= YTD / LTD 销售
//       + 期末库存的组合）的空值均由上述原子指标的组合决定，不单独判断
// 行粒度: (special_series, spu_id, spu_img_url) 三元组——判断在各行粒度
//       评估，一对多异常时按 (spu, url) 记录集合判定
// ========================================
    IF(
        ISBLANK([Series Sales SLS Amt Value]) &&
        ISBLANK([Series Sales SLS Unit Value]) &&
        ISBLANK([Series Sales EOH Amt Value]) &&
        ISBLANK([Series Sales EOH Unit Value]) &&
        ISBLANK([Series Sales YTD SLS Unit Value]) &&
        ISBLANK([Series Sales LTD SLS Unit Value]),
        0,
        1
    )
```

---

## 5. 度量值清单与 Display Folder

| 序号 | 度量值名称                          | Display Folder | 模型格式      | 用途                                                      |
| ---- | ----------------------------------- | -------------- | ------------- | --------------------------------------------------------- |
| 1    | Series Sales Sort Key               | Rank           | 整数          | 表格行排序键（series 金额降序 → series 内 AXC 金额降序） |
| 2    | Series Sales SLS Amt Value          | Base Metrics   | 数值          | 当期净销售金额（当前币种，验证用）                        |
| 3    | Series Sales SLS Amt% Value         | Base Metrics   | 百分比 #,##0% | 当期销售金额占比（全量有效 series 分母）                  |
| 4    | Series Sales SLS Unit Value         | Base Metrics   | 整数 #,##0    | 当期净销售数量                                            |
| 5    | Series Sales SLS Unit% Value        | Base Metrics   | 百分比 #,##0% | 当期净销售数量占比（全量有效 series 分母）                |
| 6    | Series Sales EOH Amt Value          | Base Metrics   | 数值          | 当期期末库存金额（当前币种，验证用）                      |
| 7    | Series Sales EOH Amt% Value         | Base Metrics   | 百分比 #,##0% | 当期期末库存金额占比（全量有效 series 分母）              |
| 8    | Series Sales EOH Unit Value         | Base Metrics   | 整数 #,##0    | 当期期末库存数量                                          |
| 9    | Series Sales EOH Unit% Value        | Base Metrics   | 百分比 #,##0% | 当期期末库存数量占比（全量有效 series 分母）              |
| 10   | Series Sales AUR Value              | Base Metrics   | 数值          | 当期件单价（当前币种，验证用）                            |
| 11   | Series Sales MD Value               | Base Metrics   | 百分比 #,##0% | 当期平均折扣                                              |
| 12   | Series Sales YTD SLS Unit Value     | Base Metrics   | 整数 #,##0    | YTD 净销售数量                                            |
| 13   | Series Sales YTD ST% (Unit) Value   | Base Metrics   | 百分比 #,##0% | YTD 售罄率%（数量，跨表）                                 |
| 14   | Series Sales YTD ST% (Amt) Value    | Base Metrics   | 百分比 #,##0% | YTD 售罄率%（金额，跨表）                                 |
| 15   | Series Sales LTD SLS Unit Value     | Base Metrics   | 整数 #,##0    | LTD 净销售数量                                            |
| 16   | Series Sales LTD ST% (Unit) Value   | Base Metrics   | 百分比 #,##0% | LTD 售罄率%（数量，跨表）                                 |
| 17   | Series Sales SLS Amt Display        | Formatting     | 文本          | SLS Amt 格式化显示（币种符号 + 千分位整数）               |
| 18   | Series Sales SLS Amt% Display       | Formatting     | 文本          | SLS Amt% 格式化显示（百分比整数）                         |
| 19   | Series Sales SLS Unit Display       | Formatting     | 文本          | SLS Unit 格式化显示（整数千分位）                         |
| 20   | Series Sales SLS Unit% Display      | Formatting     | 文本          | SLS Unit% 格式化显示（百分比整数）                        |
| 21   | Series Sales EOH Amt Display        | Formatting     | 文本          | EOH Amt 格式化显示（币种符号 + 千分位整数）               |
| 22   | Series Sales EOH Amt% Display       | Formatting     | 文本          | EOH Amt% 格式化显示（百分比整数）                         |
| 23   | Series Sales EOH Unit Display       | Formatting     | 文本          | EOH Unit 格式化显示（整数千分位）                         |
| 24   | Series Sales EOH Unit% Display      | Formatting     | 文本          | EOH Unit% 格式化显示（百分比整数）                        |
| 25   | Series Sales AUR Display            | Formatting     | 文本          | AUR 格式化显示（币种符号 + 千分位整数）                   |
| 26   | Series Sales MD Display             | Formatting     | 文本          | MD 格式化显示（百分比整数）                               |
| 27   | Series Sales YTD SLS Unit Display   | Formatting     | 文本          | YTD SLS Unit 格式化显示（整数千分位）                     |
| 28   | Series Sales YTD ST% (Unit) Display | Formatting     | 文本          | YTD ST% (Unit) 格式化显示（百分比整数）                   |
| 29   | Series Sales YTD ST% (Amt) Display  | Formatting     | 文本          | YTD ST% (Amt) 格式化显示（百分比整数）                    |
| 30   | Series Sales LTD SLS Unit Display   | Formatting     | 文本          | LTD SLS Unit 格式化显示（整数千分位）                     |
| 31   | Series Sales LTD ST% (Unit) Display   | Formatting     | 文本          | LTD ST% (Unit) 格式化显示（百分比整数）                 |
| 32   | Series Sales IsEmpty                   | Rank           | 整数（0/1）   | 行非空判定（视觉级筛选器 IsEmpty = 1 显示有数据行）   |

> 表格视觉对象值区域的绑定选择见 §7：15 列指标绑定 Display（文本格式化统一，金额列含动态币种符号），排序依据 Sort Key 置于最后一列并收窄列宽；如需为占比列配置数据条，可整体改绑对应 Value 度量并设置列格式（数值格式支持数据条，文本格式不支持）。

---

## 6. 血缘关系图

```
┌─────────────────────────────────────────────────────────────────────┐
│                        数据源层                                      │
│  s02_trade_sku_data_d（销售类，dt 日粒度）                            │
│  字段: dt, platform, shop_name, division, special_series,            │
│        spu_id, spu_img_url, product_qty, md_price, msrp,             │
│        net_sales_amt（PQ 新增列 = ROUND(product_qty ×                 │
│        sales_price, 6)）                                              │
│  s02_inventory_stock_sales_detail_d（库存类，dt 日快照）              │
│  字段: dt, division, special_series, spu_id, msrp_inv_amt,            │
│        stock_inv_qty, inv_qty（无 platform / shop_name）              │
└─────────────────────────────────────────────────────────────────────┘
│ 两事实表间无模型关系（行维度值 TREATAS 显式桥接）
│ Platform / Store Name / Division 等已建关系切片器自动传递
▼
┌─────────────────────────────────────────────────────────────────────┐
│                        度量值层                                      │
│  ┌────────────────────────────┐  ┌────────────────────────────┐     │
│  │ Series Sales Sort Key      │  │ 销售类 Value               │     │
│  │ L1: ALL(special_series)    │  │ SLS Amt / SLS Amt% /       │     │
│  │   series 金额降序排名      │  │ SLS Unit / SLS Unit% /     │     │
│  │ L2: ALL(spu_id) series     │  │ AUR / MD / YTD / LTD       │     │
│  │   筛选保留 → series 内排名 │  │ （占比分母 REMOVEFILTERS(两列)│  │
│  │ 汇总行 999,999 / 无金额垫底│  │   + series 非空还原）       │     │
│  └─────────────┬──────────────┘  └─────────────┬──────────────┘     │
│                ▼                                 ▼                   │
│  ┌──────────────────────────────────────────────────────────┐       │
│  │ 库存类 Value（EOH / ST% 库存分母）                        │       │
│  │ 期末快照日: MAX(dt) + REMOVEFILTERS(整表)（回退机制）     │       │
│  │ 明细行: TREATAS(VALUES(trade[spu_id]), inv[spu_id])      │       │
│  │ 汇总行: TREATAS(VALUES(trade[special_series]),          │       │
│  │                       inv[special_series])               │       │
│  │ 总计行: 不传维度，仅 inv[special_series] 非空            │       │
│  │ （IF 标量分支实现；分母另显式 series 非空）               │       │
│  └─────────────┬────────────────────────────────────────────┘       │
│                ▼                                                     │
│  ┌──────────────────────────────────────────────────────────┐       │
│  │ 15 列 Display（currency / integer / percent_0dp 格式化，  │       │
│  │ BLANK 显示 "-"）                                         │       │
│  └──────────────────────────────────────────────────────────┘       │
│        ▲ Slicer_Time_Frame_Min_This / Max_This（断开维度，            │
│          DAX 显式时间筛选；Max 表含 Fiscal_Year_First_Day）           │
│        ▲ Slicer_Currency_Selection（币种符号 + 汇率）                 │
└─────────────────────────────────────────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────────┐
│                        可视化层（表格 × 1）                           │
│  行: s02_trade_sku_data_d[special_series] > [spu_id] >               │
│      [spu_img_url]（三层，图片列数据类别 = 图像 URL；                │
│      行小计开启：series 汇总行；视觉级筛选器:                         │
│      special_series 不为空 + IsEmpty = 1）                            │
│  值: 15 列指标 Display                                                │
│      + Sort Key（排序依据，最后一列收窄列宽，升序）                   │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 7. 表格视觉对象配置

| 配置项       | 内容                                                                                             |
| ------------ | ------------------------------------------------------------------------------------------------ |
| 行字段       | s02_trade_sku_data_d[special_series] > [spu_id] > [spu_img_url]（三层；spu_img_url 数据类别 = 图像 URL，行区域第三层图片列） |
| 行小计       | 开启（series 汇总行，显示位置按表格格式面板小计位置设置；spu 层小计行同样被 ISINSCOPE(spu_id) 分支正确处理） |
| 总计         | 按需（DAX 已兼容总计行：行维度值不传递，仅 series 非空全量汇总）                                 |
| 值 1~15      | 15 列指标 Display 度量（§5 序号 17~31，文本格式化统一）                                         |
| 值 16        | [Series Sales Sort Key]（排序依据列，置于最后一列并收窄列宽）                                    |
| 排序         | 点击 Sort Key 列标题按升序排序（行序 = series 金额降序 → series 内 AXC 金额降序 + 维度值决胜）  |
| 视觉级筛选器 | s02_trade_sku_data_d[special_series] 不为空（排除空白 series 行）                                |
| 视觉级筛选器 | [Series Sales IsEmpty] 为 1（仅显示有数据的行，排除全部核心指标为空的行）                       |
| 显示元素     | 行小计开启；spu 层小计建议关闭（正常一对一时 spu 层小计行与 url 明细行值相同、显示冗余，按需开启） |

### 7.1 绑定与排序说明

- 15 列指标绑定 Display 度量（文本）：金额列含动态币种符号（列静态格式无法实现运行时符号切换，必须在 Display 层拼接）；BLANK 统一显示 "-"
- Image 列位于行区域第三层（spu_img_url 列的数据类别需设置为「图像 URL」）：正常一对一时行粒度即 spu、图片正常显示；series 汇总行跨多个 spu 无法确定唯一图片，显示为空；一对多异常时同一 spu 按 url 拆为多行（销售类指标按 (spu, url) 记录归属拆分，库存类指标为 spu 级值，见 §3.2）；spu_img_url 进入行轴后，占比分母的 REMOVEFILTERS(三列) 与 Sort Key 候选金额上卷均已覆盖该列（见 §3.3 / §3.4），占比与排名在三元组行粒度下正确计算
- 排序依据 Sort Key 列必须位于值区域才能作为排序依据（无法隐藏，置于最后一列并收窄列宽）；Sort Key 名次严格唯一（金额降序 + 维度值升序决胜），升序行序与两级金额降序完全一致且金额并列行序确定；当期无金额行键值垫底排在全部有效行之后
- series 汇总行 Sort Key = SeriesRank × 1,000,000 + 999,999（组内最后），与小计显示在组底部的形态一致；如后续将小计位置调整为组顶部，需同步将该编码改为 0（组内最前）
- 如需为 SLS Amt% / SLS Unit% / EOH Amt% / EOH Unit% / MD / ST% 列配置条件格式数据条，需改绑对应 Value 度量并设置列格式（数据条仅支持数值绑定）

---

## 8. 注意事项

1. **inv 表无渠道字段**：s02_inventory_stock_sales_detail_d 无 platform / shop_name 字段，库存类全部指标（EOH 系列、ST% 库存加项）与库存占比分母不受 Platform / Store Name 筛选影响，仅受 date + 与 inv 表已建关系的商品维度切片器（Division）影响；销售类全部指标受 date + 渠道 + 商品维度筛选影响。series 汇总行的 EOH / ST% 覆盖 inv 表中该 series 全部库存（含 trade 侧无销售记录的 spu），可能大于表格内可见 AXC 行库存之和——行为符合口径（库存为时点全量，与渠道筛选无关）
2. **行维度传递的层级判定**：库存类指标的 TREATAS 桥接依赖 ISINSCOPE(spu_id) / ISINSCOPE(special_series) 判定行层级（明细 / 汇总 / 总计三分支）。若后续在行区域增删字段或调整层级，需同步复核各库存类度量的分支判定
3. **期末时点只取单日**：EOH 系列与 ST% 库存加项取 end period 范围内最后一个快照日的单日值；快照表按日存储，对整段区间求和会把库存重复计数。快照缺数时在 end period 窗口内自动回退到最近一天（口径定义为 this period 最后一天）
4. **快照日 REMOVEFILTERS 机制**：`__EndPeriodDate` 用 // ── 期末日期：end period 最后一天 = Max_This 表 TimeFrame_Max（直接单日过滤）──
VAR __EndPeriodDate = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])
5. **占比分母为全量有效 series**：SLS Amt% / SLS Unit% 分母经 REMOVEFILTERS(三列：series / spu_id / spu_img_url) 上卷至全部有效 series 商品（含表格未显示行），同时显式重加 series 非空条件（视觉级「不为空」筛选被 REMOVEFILTERS 移除后必须还原，否则空白 series 金额混入分母、占比偏小；spu_img_url 行筛选必须一并移除，否则分母被当前行 url 筛选收窄为分子自身、占比恒 100%）；EOH Amt% / EOH Unit% 分母为 inv 表全量有效 series（显式非空）。全部 AXC 行占比加总小于 100%
6. **Sort Key 排名语义与粒度上卷**：两级 RANK 的 ORDERBY 均为金额降序 + 维度值升序决胜——金额相同的行因维度值不同而名次相邻不并列（金额 [100, 95, 95, 90] → 排名 [1, 2, 3, 4]），名次严格连续唯一；金额展示值经四舍五入，肉眼相同不代表底层并列。L2 的 series 内排名依赖 relation `ALL(spu_id)` 仅移除 spu_id 列筛选、保留当前行 series 筛选（行区域字段顺序变化不影响该机制，series 筛选始终存在于明细行上下文）；行区域含 spu_img_url 时，候选金额必须按排名粒度上卷——L1 候选 CALCULATE 内 REMOVEFILTERS(spu_id, spu_img_url)（series 粒度）、L2 候选 CALCULATE 内 REMOVEFILTERS(spu_img_url)（spu 粒度），否则候选集被当前行子级筛选收窄为自身、名次恒 1；一对多异常时同一 spu 的多个 url 行共享同一 L2 名次，行序由表格呈现确定
7. **YTD / LTD 的模型加载窗口限制**：Power Query 取数窗口为 trade `(2026-03-29 ~ 2026-09-26) ∪ (2025-03-30 ~ 2025-09-27)`、inv `(2026-03-29 ~ 2026-07-25) ∪ (2025-03-30 ~ 2025-07-26)`。LTD「开店以来」与 YTD「财年第一天起」在模型中实际统计范围为窗口 ∩ 口径区间：财年第一天早于窗口起点时 YTD ≈ This Period；LTD 仅含窗口内两段日期。窗口外历史数据不在模型中，如需全量 LTD / YTD 口径需扩窗重新取数。测试 SQL 默认附加相同窗口条件与 Power BI 模型值对齐，去窗口即为全量口径
8. **日期筛选器依赖**：SELECTEDVALUE(Slicer_Time_Frame_Min_This[TimeFrame_Min]) 等依赖日期切片器保持单选且必选；切片器未选或多选时时间边界为 BLANK，指标不可用（与看板既有日期筛选器使用方式一致）；YTD 区间起点依赖 Slicer_Time_Frame_Max_This[Fiscal_Year_First_Day]（取数时按 TimeFrame_Min 落入的财年区间生成，切片器单选时随行返回对应财年第一天）
9. **币种换算层次**：SLS Amt / EOH Amt / AUR 的 Value 层输出当前币种金额（原始 RMB ÷ Currency_ExchangeRate），Display 层仅拼接币种符号；占比类（Amt% / Unit% / MD / ST%）分子分母均为原始 RMB 聚合（不经换算），占比不受币种选择影响。数据源仅存储 RMB，USD 汇率动态取自数仓 dim_t00_currency 表（随数据刷新自动更新）
10. **DIVIDE 空值保护**：占比分母（全量汇总）为空或 0 时 DIVIDE 返回 BLANK，显示 "-"；金额 / 数量类 Value 在对应期间（或快照日）无记录时 SUM 返回 BLANK，显示 "-"；AUR 分母（数量）为空 / 0 时返回 BLANK；MD 吊牌金额为空 / 0 时返回 BLANK；ST% 分子与库存加项均为 BLANK 时 DIVIDE 返回 BLANK
11. **ST% 库存字段区分**：§24 / §25 / §27 ST% 的库存分母字段为 inv_qty（库存数量），§19 EOH Unit 的字段为 stock_inv_qty（在库库存数量），二者语义不同，按口径文档字段名分别使用，调整时不可混用
12. **DAX 语法规范**：文本常量使用双引号，单引号仅用于表名，列名使用方括号；与口径文档存在争议时一切以口径文档为准
13. **RANK 窗口函数版本要求与无金额候选排除**：RANK / ORDERBY 为 Power BI Desktop 2022 年 9 月引入的窗口函数，旧版本不可用；RANK 无 value 参数，当前行经 ORDERBY 中的 relation 列与 relation 行匹配确定名次。两级 relation 均排除当期无金额候选——无金额候选不占名次，避免其排序位置（BLANK 在 ORDERBY 中的默认排序方向随引擎实现）使有效行名次整体偏移；当前行当期无金额时 Sort Key 键值垫底（外层 IF 显式拦截）
14. **行小计口径**：series 汇总行 = 该 series 下全部 AXC 的上卷汇总——销售类指标（SLS / AUR / MD / YTD / LTD）为 series 粒度汇总或加权值（AUR = 总金额 ÷ 总数量、MD = 1 − 总折扣 ÷ 总吊牌）；库存类指标为 inv 表中该 series 全部库存的 TREATAS 汇总（含 trade 侧无销售记录的 spu）；占比分母不随行层级变化（始终全量有效 series）。汇总行的显示位置由表格格式面板控制，Sort Key 编码与之匹配（组内最后）
15. **spu_img_url 行维度与一对多异常**：行粒度为 (special_series, spu_id, spu_img_url) 三元组，spu_id 与 spu_img_url 正常一对一（行粒度即 spu）；一对多异常时同一 spu 按 url 拆为多行——销售类指标按 (spu, url) 记录集合拆分（历史换图的记录按各自 url 归属）、库存类指标为 spu 级值（url 行显示该 spu 全部库存，inv 表 url 与 trade 表 url 不保证同步，按 (spu, url) 双列传递存在库存漏计风险，故不拆分）；Sort Key 中同一 spu 的多个 url 行共享 (SeriesRank, SpuRank)（L2 候选金额为 spu 粒度），键值相同行序由表格呈现确定
16. **IsEmpty 行可见性筛选**：[Series Sales IsEmpty] 为 1 的视觉级筛选器仅显示有数据的行（当期 / YTD / LTD / 期末库存任一非空）；判断组合按分子依赖简化——SLS Amt 为空则 SLS Amt% 必为空（占比类不单独判断），同理 SLS Unit% / EOH Amt% / EOH Unit%，AUR / MD / ST% 的空值由原子指标组合决定；全部核心指标为空的行返回 0 被筛选器排除
