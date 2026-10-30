# Item Stockout_Table 解决方案

> **版本**: v2.4
> **模块**: RL E2E Merch Dashboard - Dimension Cross Analysis Tab - Item Stockout & Slow Mover Alert
> **关联口径**: 口径文档/口径Markdown格式/Dimension Cross Analysis.md - 子模块七（§21~§33）
> **数据底表（销售/属性类）**: s02_trade_sku_data_d
> **数据底表（库存/预警/补货类）**: SKU 表分支 = s02_inventory_stock_sales_detail_d；SPU 表分支 = s02_inventory_stock_sales_detail_d_spu（数仓 SPU 粒度预聚合表，v2.4 起）
> **关联维度**: Slicer_Time_Frame_Min_This / Max_This（时间，断开维度）；Slicer_Platform_Selection / Slicer_Store_Name（一对多关系自动传导，DAX 不显式处理）；Slicer_Currency_Selection（币种，断开维度）
> **筛选影响范围**: dt（断开维度，DAX 显式筛选）+ Platform / Store Name（模型关系自动传导）+ 其余与两张事实表已建关系的商品维度切片器
>
> **版本记录**:
> v2.4（2026-10-30）——SPU 表分支 inv 类指标（EOH / In-transit / Replenishment / Weeks Cover 分子 / ST% 库存加项 / Alert / Available Sizes / Product Tag）取数源整体切换为 s02_inventory_stock_sales_detail_d_spu（数仓 SPU 粒度预聚合表：快照日每 spu 单行，sku_size 为预拼接串逗号分隔）；Alert 判定修订（业务确认）：oos_tag = "1" → 缺货，computed_product_tag = 'slow mover' → 滞销，其他情况返回 BLANK（v2.3"其他"类别废止），SPU 分支新表直判（最高预警级别聚合废止），SKU 分支由 CALCULATETABLE 整表物化 + FILTER 迭代简化为 MAX 标量聚合（单行退化行值）；Available Sizes SPU 分支直读预拼接 sku_size（VALUES + CONCATENATEX + inv_qty > 0 过滤废止）；SKU 表分支全部保持原状
> v2.3（2026-10-23）——Alert 判定规则修订（业务确认）：缺货 = oos_tag = "1"（String 字面量），滞销 = computed_product_tag = 'slow mover'，其他 = 有记录但两条件均不成立；两条件 SKU 级互斥（SKU 单行免优先级判定），SPU 粒度按最高预警级别聚合（缺货 > 滞销 > 其他）；输出测试 SQL（test_Item_Stockout_Table.sql，两段：SPU / SKU）
> v2.2（2026-10-23）——Rank 回退 relation 用法 + 行筛选改原生 TopN 列筛选器：v2.1 无 relation 写法被引擎拒绝（省略 relation 时 ORDERBY 仅允许简单列引用，CALCULATE 度量表达式排序键报错"已省略 RANK 的关系参数，并且其 ORDERBY 子句包含非引用列表达式"）——按度量值排名必须显式指定 relation；卡顿真正根源为「Rank 介于 1 与 100」度量筛选器（迫使引擎对全部主键分组逐组求值 Rank，每组物化一次候选集，O(行数 × 候选集)）——改为「spu_id/sku_id 前 100 个（按 SLS Amt Value 降序）」原生列筛选器（引擎单遍取 TopN，Rank 仅对可见 100 行求值，候选表跨行共享缓存）
> v2.1（2026-10-23）——Rank 无 relation 用法尝试：被引擎约束拒绝，已回退（见 v2.2，保留记录作为约束实证：度量表达式不可作无 relation RANK 的 ORDERBY 键）
> v2.0（2026-10-23）——模块维度收敛为单列 spu_id / sku_id：字段井仅放主键一列，其余七个字段（us_style / ax_class / product_type / special_series / spu_img_url / computed_product_tag / special_supply）全部指标化输出（取值规则见 §1.3）；全部指标聚合与 Top 100 排名按主键粒度（跨 product_type / special_series 汇总）；inv 桥接由三列交集简化为主键单列；special_supply 取数源由 inv 改为 trade
> v1.0（2026-10-22）——初版：行主键三元组 (spu_id/sku_id, product_type, special_series)，product_type / special_series 参与行分组，一对一属性值区域化

---

## 1. 需求理解

### 1.1 模块定位与视觉对象结构

本板块为单品级缺货与滞销预警表格，通过两个按钮（SPU / SKU）切换显示 spu_id 维度与 sku_id 维度两张表格，各取 SLS Amt 最大的 Top 100 行：

| 配置项           | SPU 表格                                                                                                         | SKU 表格                                      |
| ---------------- | ---------------------------------------------------------------------------------------------------------------- | --------------------------------------------- |
| 字段井（行分组） | s02_trade_sku_data_d[spu_id]（单列）                                                                             | s02_trade_sku_data_d[sku_id]（单列）          |
| 值区域（属性列） | US Style / AX Class / Product Type / Special Series / SPU Image / Product Tag / Special Supply（度量，见 §1.3） | 同左                                          |
| 值区域（指标列） | 十三个指标 Display + Rank 度量（行排序依据）                                                                     | 同左（共用同一套指标度量）                    |
| 视觉级筛选器     | SPU Rank 介于 1 与 100 + SLS Amt Value 不为空                                                                    | SKU Rank 介于 1 与 100 + SLS Amt Value 不为空 |
| 显隐控制         | 按钮（书签）切换，两表互斥显示                                                                                   | 同左                                          |

- **模块维度收敛为单列主键**：最终展示的行 = 不重复的 spu_id / sku_id——product_type / special_series 不再参与行分组（v1.0 三元组结构废止），转为属性指标输出；表格无小计无层级，总计行不做特判，交由表格视觉对象默认生成
- **指标计算粒度**：全部指标按当前行主键聚合——行分组筛选自动落在 s02_trade_sku_data_d[spu_id] / [sku_id] 单列上，聚合范围 = 该主键下全部记录（跨 product_type / special_series / 尺码 / 渠道明细汇总）
- **inv 侧显式桥接**：两张事实表之间无模型关系，主键行筛选对库存类指标不自动传递，经 DAX TREATAS 主键单列显式桥接（见 §1.7、§3.4）
- **行可见性**：Top 100 行由视觉级 Rank 筛选器驱动——候选集已排除空白 / 当期无金额主键，入选行必有 SLS Amt，无全空行，不设 IsEmpty 筛选器

### 1.2 指标清单

| 序号 | 指标                 | 口径章节 | 时间口径               | 计算公式                                                                                                                                | 数据类型 / 格式                 |
| ---- | -------------------- | -------- | ---------------------- | --------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------- |
| 1    | SLS Amt              | §21     | This Period（区间）    | 该 spu_id/sku_id 下 sum(net_sales_amt)                                                                                                  | currency → 币种符号 +`#,##0` |
| 2    | SLS Units            | §22     | This Period（区间）    | 该 spu_id/sku_id 下 sum(product_qty)                                                                                                    | integer →`#,##0`             |
| 3    | EOH                  | §23     | End Period（期末时点） | 该 spu_id/sku_id 下 sum(stock_inv_qty)（快照日单日）                                                                                    | integer →`#,##0`             |
| 4    | In-transit Inventory | §24     | End Period（期末时点） | 该 spu_id/sku_id 下 sum(in_trans_inv_qty)（快照日单日）                                                                                 | integer →`#,##0`             |
| 5    | Weeks Cover          | §25     | 跨双口径               | (sum(stock_inv_qty) + sum(in_trans_inv_qty)) / sum(product_qty)；库存侧看 end period 最后一天，销售侧 this period 区间                  | decimal_1dp →`#,##0.0`       |
| 6    | MTD SLS Unit         | §26     | 财月至今（区间）       | end period 所在财月第一天至 end period 最后一天 sum(product_qty)                                                                        | integer →`#,##0`             |
| 7    | YTD SLS Unit         | §27     | 财年至今（区间）       | end period 所在财年第一天至 end period 最后一天 sum(product_qty)                                                                        | integer →`#,##0`             |
| 8    | ST%                  | §28     | 跨双口径               | sales.sum(product_qty) / (sales.sum(product_qty) + inv.sum(stock_inv_qty))；数量口径                                                    | percent_0dp →`#,##0%`        |
| 9    | AUR                  | §29     | This Period（区间）    | sum(net_sales_amt) / sum(product_qty)                                                                                                   | currency → 币种符号 +`#,##0` |
| 10   | MD                   | §30     | This Period（区间）    | 1 - sum(product_qty×md_price) / sum(product_qty×msrp)                                                                                 | percent_0dp →`#,##0%`        |
| 11   | Alert                | §31     | End Period（期末时点） | oos_tag = "1" → 缺货；computed_product_tag = 'slow mover' → 滞销；其他情况 BLANK；两条件互斥（单状态）；SPU 取 spu 预聚合表直判 / SKU 取 inv 表单行判定（分源） | 文本                            |
| 12   | Available Sizes      | §32     | End Period（期末时点） | SPU：spu 预聚合表 sku_size 预拼接串直读（逗号分隔）；SKU：distinct sku_size where inv_qty > 0 顿号拼接                                      | 文本枚举                        |
| 13   | Replenishment Count  | §33     | End Period（期末时点） | 该 spu_id/sku_id 下 sum(reph_qty)（快照日单日）                                                                                         | integer →`#,##0`             |

属性列（非口径指标，指标化输出，共 7 个）：

| 序号 | 属性列                              | 底表                               | 取值规则（详见 §1.3）                      |
| ---- | ----------------------------------- | ---------------------------------- | ------------------------------------------- |
| 1    | US Style（us_style）                | s02_trade_sku_data_d               | 最新日期值拼接                              |
| 2    | AX Class（ax_class）                | s02_trade_sku_data_d               | 最新日期值拼接                              |
| 3    | Product Type（product_type）        | s02_trade_sku_data_d               | 最新日期值拼接                              |
| 4    | Special Series（special_series）    | s02_trade_sku_data_d               | 最新日期值拼接                              |
| 5    | SPU Image（spu_img_url）            | s02_trade_sku_data_d               | 最新日期值拼接（一对一属性，退化单值）      |
| 6    | Special Supply（special_supply）    | s02_trade_sku_data_d               | 最新日期值拼接                              |
| 7    | Product Tag（computed_product_tag） | SKU 表：s02_inventory_stock_sales_detail_d；SPU 表：s02_inventory_stock_sales_detail_d_spu | 最新快照日值拼接（inv 类独有字段，v2.4 SPU 分支取 spu 预聚合表单值） |

### 1.3 属性字段取值规则

七个属性字段全部按指标逻辑处理（单度量输出，规则统一）：

**通用规则（trade 侧六字段）**：

- 取值范围 = This Period 时间区间（[TimeFrame_Min, TimeFrame_Max]）+ 当前行主键（spu_id / sku_id）筛选下的全部记录
- **"最新"定义**：范围内该主键的最大 dt（`MAX(trade[dt])`）——用户选定时间段内最后一次出现记录的日期
- **取值**：最大 dt 那天的该字段 distinct 值，按字母序升序顿号（、）拼接——同一最新日期存在多条记录且字段值不同时全部展示（trade 表为 sku 粒度，同日多行是常态：不同 sku / 不同订单类型 / 不同店铺，product_type / special_series 同日多值常态存在；us_style / ax_class / spu_img_url / special_supply 为主键一对一属性，拼接自然退化为单值）
- 区间内无记录（最大 dt 为 BLANK）时返回 BLANK；最新日期当天该字段全为空白时返回 BLANK（空白值不参与拼接）
- 示例：某 spu_id 在 this period 区间内最后记录日为 2026-07-20，当天该 spu 有 3 个 sku 行，product_type 分别为 T-shirt / T-shirt / Jacket → Product Type 列显示 "Jacket、T-shirt"

**inv 侧（computed_product_tag）**：

- 取值范围 = 最新期末快照日（快照日机制见 §1.4）+ 当前行主键筛选下的全部记录（SKU 表快照日每 sku 一行；SPU 表快照日每 spu 单行——v2.4 取 spu 预聚合表）
- **取值**：快照日该主键行的 computed_product_tag distinct 值升序顿号拼接；SKU 表快照日单行，拼接自然退化为单值；SPU 表取数仓预聚合单行，同样退化为单值（v2.3"同 spu 不同 sku 分层共存"场景随预聚合表切换消失）
- 快照日无 inv 类记录或全部空白时返回 BLANK

**特殊（Available Sizes，口径指标 §32，非"最新"规则）**：

- 不取最新一条——快照日下取值（口径原文语义），与属性字段的"最新值"规则明确区分
- **分源（v2.4）**：SPU 表 = 直读 spu 预聚合表 sku_size 预拼接串（该 SPU 全部在库尺码，数仓已固化口径，逗号分隔）；SKU 表 = 快照日下该主键全部尺码（`inv_qty > 0`）distinct 顿号拼接（原状）

**取数源（用户指定）**：computed_product_tag 等 inv 类字段分源——SKU 表取 s02_inventory_stock_sales_detail_d，SPU 表取 s02_inventory_stock_sales_detail_d_spu（v2.4）；其余六个属性字段全部从 s02_trade_sku_data_d 取（special_supply v1.0 曾从 inv 桥接，v2.0 改源为 trade）

### 1.4 时间口径

| 口径                     | 时间范围                                                                                                                                  | 适用指标                                                                                                      |
| ------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------- |
| This Period（区间类）    | dt ∈ [Slicer_Time_Frame_Min_This[TimeFrame_Min], Slicer_Time_Frame_Max_This[TimeFrame_Max]]                                              | SLS Amt、SLS Units、AUR、MD、ST% 销售侧、Weeks Cover 分母、Top 100 排序金额、trade 侧属性字段的"最新日期"判定 |
| End Period（期末时点类） | end period 范围 [Slicer_Time_Frame_Max_This[TimeFrame_Min], Slicer_Time_Frame_Max_This[TimeFrame_Max]] 内**最后一个有数据的快照日** | EOH、In-transit、Replenishment、Alert、Available Sizes、Product Tag、Weeks Cover 分子、ST% 库存侧             |
| MTD（财月至今区间）      | dt ∈ [Slicer_Time_Frame_Max_This[Fiscal_Month_First_Day], Slicer_Time_Frame_Max_This[TimeFrame_Max]]                                     | MTD SLS Unit                                                                                                  |
| YTD（财年至今区间）      | dt ∈ [Slicer_Time_Frame_Max_This[Fiscal_Year_First_Day], Slicer_Time_Frame_Max_This[TimeFrame_Max]]                                      | YTD SLS Unit                                                                                                  |

说明：

- 两张 s02 表日期字段均为 dt（非 data_date）
- 期末时点实现为「范围内最后一个有数据的快照日」：口径定义为区间最后一天，快照缺数时自动回退到范围内最近一天；快照表按日存储，期末时点只取单日，对整段区间求和会把库存重复计数
- MTD / YTD 的起点字段（Fiscal_Month_First_Day / Fiscal_Year_First_Day）由 Slicer_Time_Frame_Max_This 表提供（口径 §26 / §27 指定），终点为 TimeFrame_Max
- trade 侧属性字段的"最新日期"以 This Period 区间内该主键的实际最大 dt 为准（非 TimeFrame_Max——主键在该区间内的最后记录日）

### 1.5 币种口径

- SLS Amt / AUR 为 currency 类指标：货币符号由币种切片器（Slicer_Currency_Selection）决定，千分位整数；数据底表金额仅存储 CNY，Value 层完成汇率换算（原始值 ÷ Currency_ExchangeRate，RMB 汇率 = 1 时换算前后值相同），Display 层仅拼接币种符号
- 数量 / 占比 / 比率 / 周数类指标与属性字段不涉及币种换算

### 1.6 Top 100 排名机制

- **排名粒度**：spu_id / sku_id 主键单列（跨 product_type / special_series 汇总后的主键全量金额）
- **排序依据**：This Period `sum(net_sales_amt)`（原始 CNY 聚合，不经币种换算——除以同一正汇率不改变相对顺序）降序，取最大的 100 条
- **决胜链（名次唯一）**：金额降序 → spu_id / sku_id 字母序升序。主键在候选集内唯一，两键决胜名次严格连续唯一（1、2、3、……），Top 100 恰好 100 行、边界确定
- **两个排序度量**：Item Stockout SPU Rank（SPU 表）、Item Stockout SKU Rank（SKU 表）——RANK 的 relation 与 ORDERBY 绑定不同主键列，无法合并
- **Rank relation 用法（引擎约束）**：按度量值排名必须显式指定 relation——RANK 省略 relation 时 ORDERBY 仅允许简单列引用（引擎依 orderBy 列构建默认行集），CALCULATE 等度量表达式作排序键报错"已省略 RANK 的关系参数，并且其 ORDERBY 子句包含非引用列表达式"；relation = FILTER(ADDCOLUMNS(ALL(主键), @Amt), 非空白 && @Amt 非空)，ALL(主键) 移除行分组与视觉级 TopN 落地筛选 → 排名恒为全局真实名次
- **行筛选（性能关键）**：原生「前 N 个」列筛选器（spu_id / sku_id 前 100 个，按 Item Stockout SLS Amt Value 降序）——引擎对全部主键分组单遍求值排序度量后取前 100，Rank 仅对可见 100 行求值（候选表跨行共享缓存，有效成本 = 一次候选物化）；**禁止「Rank 介于 1 与 100」度量筛选器**（迫使引擎对全部主键分组逐组求值 Rank，每组物化一次候选集，O(行数 × 候选集)，卡顿根源）
- **行排序依据**：Rank 度量拖入值区域按升序排序（名次唯一 → 行序 = 金额降序 + 主键字母序）

### 1.7 单度量双维度机制

两张表格共用同一套指标度量（除 Rank 外每指标一个度量），机制分三类：

| 指标类别                                                                                                                 | 双表复用机制                                                                                                                                      | 分支需求                                                                                                                                           |
| ------------------------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------- |
| trade 侧指标（SLS Amt / SLS Units / MTD / YTD / AUR / MD / ST% 销售侧 / Weeks Cover 分母）                               | 行分组筛选（spu_id 或 sku_id 单列）自动落在 trade 表对应列上，聚合自动限定当前行主键                                                              | **零分支**——聚合与主键列是哪个无关                                                                                                         |
| trade 侧属性（US Style / AX Class / Product Type / Special Series / SPU Image / Special Supply）                         | MAX(trade[dt]) 与 VALUES(字段) 求值均随行分组筛选自动生效——主键筛选限定取值范围，字段拼接结果与主键列是哪个无关                                 | **零分支**                                                                                                                                   |
| inv 侧指标（EOH / In-transit / Replenishment / Alert / Available Sizes / Product Tag + Weeks Cover 分子 + ST% 库存分母） | `ISINSCOPE(trade[spu_id])` 判定当前表格（SPU 表 TRUE / SKU 表 FALSE——两表互斥显示，行分组必含其一），TREATAS 主键单列桥接按判定结果切换锚点列**与取数源表**（SPU 分支 → s02_inventory_stock_sales_detail_d_spu；SKU 分支 → s02_inventory_stock_sales_detail_d） | **IF 标量双分支**——分支内 CALCULATE / CONCATENATEX 返回标量后经 IF 选择（分支返回表会被降级为标量，TREATAS / CALCULATETABLE 不经 IF 传递） |
| Rank                                                                                                                     | 两表 relation 与 ORDERBY 绑定不同主键列（relation 候选集模式）                                                                                    | 各写一个                                                                                                                                           |

### 1.8 渠道上下文

- Slicer_Platform_Selection / Slicer_Store_Name 与 s02_trade_sku_data_d 一对多关联，筛选经模型关系自动传导——trade 侧指标与 Top 100 候选金额随渠道筛选收窄，DAX 不显式处理
- 两张 inv 类表（s02_inventory_stock_sales_detail_d / s02_inventory_stock_sales_detail_d_spu）均无 platform / shop_name 字段：库存侧指标（EOH / In-transit / Replenishment / Alert / Available Sizes / Product Tag / ST% 库存分母 / Weeks Cover 分子）不受渠道筛选影响——trade 侧受筛选、inv 侧全量的口径不对称为模型物理限制（ST% / Weeks Cover 分子分母渠道口径不对称，业务需知悉）

---

## 2. 现状分析

- 数据底表 `s02_trade_sku_data_d`（SKU 粒度交易表，dt 日粒度）：net_sales_amt 为 Power Query 取数新增列（行级 `ROUND(product_qty * sales_price, 6)` 生成，模型内存在，数据库无此列——测试 SQL 验证时按行级乘积还原）；product_qty 为净销售数量口径字段；md_price / msrp 为 MD 折扣价 / 吊牌价（MD 公式行级乘积字段）；主键字段 spu_id / sku_id 与七个属性字段（us_style / ax_class / product_type / special_series / spu_img_url / special_supply）齐备（已逐一核对数据字典）；同一主键同日多行为常态（不同 sku / 订单类型 / 店铺），属性"最新值"取最大 dt 当天 distinct 拼接（§1.3）
- 数据底表 `s02_inventory_stock_sales_detail_d`（库存+销售+补货 SKU 模型表，dt 日快照，取数源 = s02_inventory_stock_sales_detail_result_d 且 data_type = 'sku'，快照日每 sku 一行）：stock_inv_qty（在库库存，EOH 口径）、in_trans_inv_qty（在途库存）、reph_qty（补货数量，数仓预计算）、inv_qty（在库库存数量，Available Sizes 判定字段）、oos_tag（缺货标签）、computed_product_tag（商品分层标签：hero model / slow mover / normal）、sku_size（尺码）齐备；spu_id / sku_id 同名桥接字段齐备（已逐一核对数据字典）；**无 platform / shop_name 字段**（渠道筛选不影响库存侧）；v2.4 起仅作为 SKU 表分支取数源
- 数据底表 `s02_inventory_stock_sales_detail_d_spu`（SPU 粒度预聚合表，v2.4 新增）：与上表同源（s02_inventory_stock_sales_detail_result_d 且 data_type = 'spu'，源表唯一键 dt + sku_id + spu_id + data_type），快照日每 spu 单行；sku_size 为数仓预拼接串（该 SPU 全部在库尺码，逗号分隔——Available Sizes 直读依据）；oos_tag / computed_product_tag / stock_inv_qty / in_trans_inv_qty / reph_qty / inv_qty 等 SPU 粒度字段齐备（已核对数据字典）；**同样无 platform / shop_name 字段**；作为 SPU 表分支 inv 类指标的取数源
- trade 表与两张 inv 类表之间均无模型关系：主键行筛选向库存类指标的传递经 DAX TREATAS 单列显式桥接
- 日期筛选器（Min_This / Max_This）为断开维度，时间范围在 DAX 中显式筛选；MTD / YTD 起点字段（Fiscal_Month_First_Day / Fiscal_Year_First_Day）在 Slicer_Time_Frame_Max_This 表
- Slicer_Platform_Selection / Slicer_Store_Name 与 trade 表一对多关联（渠道筛选自动传导，DAX 不显式处理）；Slicer_Currency_Selection 为断开维度，汇率与符号经 SELECTEDVALUE 读取
- 字段名与日期字段（dt）已逐一核对数据字典

---

## 3. 方案设计

### 3.1 度量值分层

```
Rank（值区域展示 + 行排序依据，两个度量）
←  relation 候选集：FILTER(ADDCOLUMNS(ALL(trade 主键单列), @Amt,
      this period sum(net_sales_amt)), 主键非空白 && @Amt 非空)
      ——ALL(主键) 移除行分组筛选与视觉级 TopN 落地筛选，
      排名恒为全局真实名次；FILTER 排除空白 / 无金额候选
←  RANK(DENSE, 候选集, ORDERBY(@Amt DESC, 主键 ASC))
      ——两键决胜，名次唯一（relation 不可省略：无 relation 时
      ORDERBY 仅允许列引用，度量表达式排序键报错）
←  外层 IF 拦截：主键空白 / 当期无金额 → BLANK
←  行筛选：视觉级「主键 前 100 个（按 SLS Amt Value 降序）」列筛选器
      （引擎单遍取 TopN，Rank 仅对可见 100 行求值，候选表跨行共享）
↓
Value（口径计算，13 个指标各一）
←  trade 侧：时间范围显式筛选，行分组筛选（主键单列）自动传导，零分支
←  inv 侧：ISINSCOPE(trade[spu_id]) 判定 → IF 标量双分支（分源）
      TREATAS 主键单列桥接 + [dt] = 快照日（单日时点）
      SPU 分支 → s02_inventory_stock_sales_detail_d_spu（SPU 预聚合表，
                  快照日每 spu 单行）
      SKU 分支 → s02_inventory_stock_sales_detail_d（原状）
←  金额类 Value 层完成币种汇率换算（原始 CNY ÷ Currency_ExchangeRate）
↓
Display（格式化显示）
←  currency: 币种符号 & FORMAT(#,##0)；integer: FORMAT(#,##0)
←  percent_0dp: FORMAT(#,##0%)；decimal_1dp: FORMAT(#,##0.0)
←  文本类（Alert / Available Sizes）: BLANK 显示 "-"
←  BLANK 统一显示 "-"
↓
属性度量（指标化输出，7 个，无 Display 层）
←  trade 侧六字段：MAX(dt) 那天 distinct 顿号拼接（零分支）
←  inv 侧 Product Tag：快照日 distinct 顿号拼接（IF 双分支；SPU 分支
      取 spu 预聚合表单行值，拼接自然退化单值）
```

### 3.2 Top 100 行筛选机制

每个表格视觉对象配置三条视觉级筛选器：

| 筛选器                                          | 类型       | 条件                                           | 作用                                                                                                                        |
| ----------------------------------------------- | ---------- | ---------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------- |
| s02_trade_sku_data_d[spu_id]（SKU 表 [sku_id]） | 前 N 个    | 前 100 个，按 Item Stockout SLS Amt Value 降序 | **行筛选主力**——原生 TopN 由引擎对全部主键分组单遍求值排序度量后取前 100（Rank 度量不参与筛选求值，仅对可见行求值） |
| Item Stockout SLS Amt Value                     | 度量筛选器 | 不为空                                         | 排除当期无金额行——有效主键不足 100 个时防 BLANK 行经 TopN 混入（TopN 降序下 BLANK 排末尾，双保险）                        |
| s02_trade_sku_data_d[spu_id]（SKU 表 [sku_id]） | 列筛选器   | 不为空                                         | 排除空白主键行——空白主键若金额非空会进入 TopN 占据名额（文本列 NULL 与空字符均归入 (Blank) 组被排除）                     |

机制说明：

- **禁止配置「Rank 介于 1 与 100」度量筛选器**：度量筛选器须先对全部主键分组逐组求值 Rank 才能决定保留行——每组物化一次 relation 候选集，O(行数 × 候选集) 复杂度，数万主键量级下明显卡顿（本次性能问题根源）；原生 TopN 列筛选器先按排序度量收窄行集（排序度量为单遍分组聚合，成本低），Rank 仅对可见 100 行求值
- TopN 列筛选器落地为 spu_id 列筛选，Rank 候选集 ALL(spu_id) 将其移除 → 排名恒为全局真实名次；可见行恰为全局 Top 100 → 显示名次 1..100
- 边界并列提示：TopN 引擎的并列打破规则不确定（非按主键字母序）——金额完全相等且恰好跨第 100 名边界时，TopN 入选行与 Rank 决胜链的第 100 名可能不一致（金额 6 位小数精度下完全相等概率极低，知悉即可）
- Rank 度量对空白主键 / 当期无金额行返回 BLANK（外层 IF 拦截）

### 3.3 排名候选集构建

- relation：`FILTER(ADDCOLUMNS(ALL(trade[spu_id] 或 [sku_id]), "@Amt", CALCULATE(SUM(net_sales_amt), dt 条件)), 主键非空白 && [@Amt] 非空)`
  - **relation 不可省略**：RANK 省略 relation 时 ORDERBY 仅允许简单列引用（引擎依 orderBy 列构建默认行集 ALLSELECTED(列)），CALCULATE 等度量表达式作排序键直接报错——按度量值排名必须显式指定 relation
  - ALL(主键单列) 生成主键全量值域，同时清除行分组筛选与视觉级 TopN / 不为空筛选器落地筛选；Platform / Store / 其余商品维度切片器筛选保留（候选金额与当前筛选上下文同口径）
  - ADDCOLUMNS 物化候选金额：上下文转换将候选主键叠加于当前筛选上下文，候选金额为主键粒度全量
  - FILTER 排除空白主键与当期无金额候选：不占名次（避免其排序位置使有效行名次整体偏移）
- ORDERBY：`[@Amt] DESC + 主键 ASC`——金额降序为第一序，主键字母序升序决胜；主键在候选集内唯一 → 元组唯一 → 名次严格连续唯一；RANK 无 value 参数，当前行经 ORDERBY 中的 relation 列与候选行匹配确定名次
- **性能结构**：候选集跨行共享——表格各行的 Rank 求值中，外部筛选上下文（切片器）一致，行分组筛选与 TopN 落地筛选被 ALL(主键) 移除，候选表对全部可见行一致，引擎缓存复用，有效成本 = 一次 O(候选集) 物化 + 100 次名次匹配；配合原生 TopN 列筛选器（Rank 仅对可见 100 行求值），总量数万主键下流畅
- 排名基于原始 CNY 金额聚合（不经币种换算）

### 3.4 inv 侧 TREATAS 主键单列桥接

行主键筛选向 inv 类表的传递（IF 标量双分支 + 分源，以 SPU 表分支为例）：

```dax
IF(
    ISINSCOPE('s02_trade_sku_data_d'[spu_id]),
    CALCULATE(
        SUM('s02_inventory_stock_sales_detail_d_spu'[stock_inv_qty]),
        TREATAS(VALUES('s02_trade_sku_data_d'[spu_id]), 's02_inventory_stock_sales_detail_d_spu'[spu_id]),
        's02_inventory_stock_sales_detail_d_spu'[dt] = __EndPeriodDate
    ),
    CALCULATE( ... sku_id 分支同构，源表换 s02_inventory_stock_sales_detail_d、锚点列换 TREATAS(VALUES(trade[sku_id]), inv[sku_id]) ... )
)
```

- **主键单列 TREATAS + 分源（v2.4）**：SPU 表分支 = 该 spu_id 快照日在 s02_inventory_stock_sales_detail_d_spu 的单行（数仓已按 SPU 粒度预聚合，SUM 退化为行值）；SKU 表分支 = 该 sku_id 快照日在 s02_inventory_stock_sales_detail_d 的行（快照日每 sku 单行）
- **IF 标量双分支**：ISINSCOPE(trade[spu_id]) 判定当前表格（两表互斥显示，行分组必含 spu_id / sku_id 其一）；分支内 CALCULATE / CONCATENATEX 聚合返回标量后经 IF 选择——TREATAS / CALCULATETABLE 不经 IF 传递（IF 分支返回表会被降级为标量）
- **期末快照日**：`CALCULATE(MAX(inv[dt]), REMOVEFILTERS(整表), 范围条件)` 全表确定性取值，不随行上下文 / 切片器漂移
- 与 inv 类表已建关系的外部维度切片器（Division 等）经 CALCULATE / CALCULATETABLE 自动传导，不在桥接参数内重复处理——**建模前提**：s02_inventory_stock_sales_detail_d_spu 需在模型中建立与 s02_inventory_stock_sales_detail_d 同款的外部维度关系（Division 等），否则 SPU 分支会丢失这些切片器的收窄效果

### 3.5 度量值命名与组织

- 命名规则：模块前缀 `Item Stockout` + 指标名 + 层次后缀（Rank / Value / Display）；属性列为 `Item Stockout` + 属性名（单度量）
- Display Folder：`Item Stockout & Slow Mover Alert\Rank`、`Item Stockout & Slow Mover Alert\Attributes`、`Item Stockout & Slow Mover Alert\Base Metrics`、`Item Stockout & Slow Mover Alert\Formatting`
- 度量值统一存放于 `_Measures` 隐藏表

---

## 4. 度量值实现

### 4.1 Item Stockout SPU Rank（SPU 表 Top 100 排名）

```dax
Item Stockout SPU Rank =
// ========================================
// 度量值: Item Stockout SPU Rank
// 中文名: SPU 表格 Top 100 排名
// Display Folder: Item Stockout & Slow Mover Alert\Rank
// 用途: SPU 表格当前行 spu_id 按 This Period sum(net_sales_amt) 的降序
//       排名（主键粒度——跨 product_type / special_series 汇总），用于
//       视觉级筛选器固定 Top 100 行并作为行排序依据（值区域升序排序）
// 依赖: Slicer_Time_Frame_Min_This[TimeFrame_Min] / Slicer_Time_Frame_Max_This[TimeFrame_Max]
// 口径: 渠道（Platform / Store）与其余商品维度切片器筛选组合下，按 spu_id
//       粒度 This Period sum(net_sales_amt) 降序排名
// 排名语义: 金额降序为第一序；金额相同的 spu_id 按字母序升序决胜——主键
//       在候选集内唯一，两键决胜名次严格连续唯一（1、2、3、……），
//       Top 100 恰好 100 行、边界确定
// 函数: RANK 窗口函数 relation 用法（Power BI Desktop 2022 年 9 月及以后
//       版本可用）——按度量值排名必须显式指定 relation：省略 relation 时
//       ORDERBY 仅允许简单列引用（引擎依 orderBy 列构建默认行集），
//       CALCULATE 等度量表达式作排序键报错"已省略 RANK 的关系参数，并且
//       其 ORDERBY 子句包含非引用列表达式。不支持此操作"
// 候选集: FILTER(ADDCOLUMNS(ALL(spu_id), @Amt), 非空白主键 && @Amt 非空)
//       ——ALL 移除主键列全部筛选（含行分组筛选与视觉级「前 N 个」落地
//       筛选），候选 = 外部切片器筛选下的主键全量，排名恒为全局真实名次
//       （可见行恰为全局 Top 100 → 显示 1..100）；FILTER 排除空白主键与
//       当期无金额候选（不占名次）
// 性能: 行筛选由视觉级「spu_id 前 100 个（按 SLS Amt Value 降序）」列
//       筛选器完成——原生 TopN 由引擎对全部主键分组单遍求值排序度量后
//       取前 100，Rank 仅对可见 100 行求值；候选表跨行共享（各行的候选
//       求值上下文一致——ALL(主键) 移除行内差异筛选，引擎缓存复用，
//       有效成本 = 一次候选物化）。**禁止改配「Rank 介于 1 与 100」度量
//       筛选器**：度量筛选器须先对全部主键分组逐组求值 Rank 才能决定
//       保留行（每组物化一次候选集，O(行数 × 候选集)，卡顿根源）
// 空白/无金额拦截: 当前行主键空白或当期无金额时返回 BLANK（行筛选由
//       TopN 列筛选器 + 不为空筛选器承担）
// 排名金额: 原始 CNY 聚合，不经币种换算（除以同一正汇率不改变相对顺序）
// ========================================

// ── This Period 时间区间 ──
VAR __PeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Min_This[TimeFrame_Min])
VAR __PeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

// ── 当前行主键（空白/空字符拦截的判定依据）──
VAR __CurrentSpuId = SELECTEDVALUE('s02_trade_sku_data_d'[spu_id])

// ── 当前行主键的 This Period 净销售金额（无金额行返回 BLANK 的拦截依据）──
VAR __CurrentAmt =
    CALCULATE(
        SUM('s02_trade_sku_data_d'[net_sales_amt]),
        's02_trade_sku_data_d'[dt] >= __PeriodMin,
        's02_trade_sku_data_d'[dt] <= __PeriodMax
    )

// ── 排名：relation 候选集 + 两键决胜 ──
// ORDERBY 第一键 [@Amt] 降序（候选集行上下文物化列）；第二键 spu_id
// 字母序升序决胜（金额相同的主键分先后，名次相邻不并列）
RETURN
    IF(
        NOT ISBLANK(__CurrentSpuId) && LEN(TRIM(__CurrentSpuId)) > 0,
        IF(
            ISBLANK(__CurrentAmt),
            BLANK(),
            RANK(
                DENSE,
                FILTER(
                    ADDCOLUMNS(
                        ALL('s02_trade_sku_data_d'[spu_id]),
                        "@Amt",
                            CALCULATE(
                                SUM('s02_trade_sku_data_d'[net_sales_amt]),
                                's02_trade_sku_data_d'[dt] >= __PeriodMin,
                                's02_trade_sku_data_d'[dt] <= __PeriodMax
                            )
                    ),
                    NOT ISBLANK('s02_trade_sku_data_d'[spu_id])
                        && LEN(TRIM('s02_trade_sku_data_d'[spu_id])) > 0
                        && NOT ISBLANK([@Amt])
                ),
                ORDERBY(
                    [@Amt], DESC,
                    's02_trade_sku_data_d'[spu_id], ASC
                )
            )
        )
    )
```

### 4.2 Item Stockout SKU Rank（SKU 表 Top 100 排名）

```dax
Item Stockout SKU Rank =
// ========================================
// 度量值: Item Stockout SKU Rank
// 中文名: SKU 表格 Top 100 排名
// Display Folder: Item Stockout & Slow Mover Alert\Rank
// 用途: SKU 表格当前行 sku_id 按 This Period sum(net_sales_amt) 的降序
//       排名（主键粒度），用于视觉级筛选器固定 Top 100 行并作为行排序依据
// 依赖: Slicer_Time_Frame_Min_This[TimeFrame_Min] / Slicer_Time_Frame_Max_This[TimeFrame_Max]
// 口径: 同 SPU Rank，行主键锚点列换 sku_id
// 排名语义: 金额降序 + sku_id 字母序升序决胜，名次严格连续唯一
//       （机制与性能说明同 SPU Rank，见 §4.1 注释——relation 候选集
//       用法 / ALL(主键) 全局真实名次 / 视觉级「前 N 个」列筛选器行
//       筛选 / 禁止 Rank 区间度量筛选器）
// ========================================

// ── This Period 时间区间 ──
VAR __PeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Min_This[TimeFrame_Min])
VAR __PeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

// ── 当前行主键 ──
VAR __CurrentSkuId = SELECTEDVALUE('s02_trade_sku_data_d'[sku_id])

// ── 当前行主键的 This Period 净销售金额 ──
VAR __CurrentAmt =
    CALCULATE(
        SUM('s02_trade_sku_data_d'[net_sales_amt]),
        's02_trade_sku_data_d'[dt] >= __PeriodMin,
        's02_trade_sku_data_d'[dt] <= __PeriodMax
    )

RETURN
    IF(
        NOT ISBLANK(__CurrentSkuId) && LEN(TRIM(__CurrentSkuId)) > 0,
        IF(
            ISBLANK(__CurrentAmt),
            BLANK(),
            RANK(
                DENSE,
                FILTER(
                    ADDCOLUMNS(
                        ALL('s02_trade_sku_data_d'[sku_id]),
                        "@Amt",
                            CALCULATE(
                                SUM('s02_trade_sku_data_d'[net_sales_amt]),
                                's02_trade_sku_data_d'[dt] >= __PeriodMin,
                                's02_trade_sku_data_d'[dt] <= __PeriodMax
                            )
                    ),
                    NOT ISBLANK('s02_trade_sku_data_d'[sku_id])
                        && LEN(TRIM('s02_trade_sku_data_d'[sku_id])) > 0
                        && NOT ISBLANK([@Amt])
                ),
                ORDERBY(
                    [@Amt], DESC,
                    's02_trade_sku_data_d'[sku_id], ASC
                )
            )
        )
    )
```

### 4.3 Item Stockout SLS Amt Value（当期净销售金额）

```dax
Item Stockout SLS Amt Value =
// ========================================
// 度量值: Item Stockout SLS Amt Value
// 中文名: 当期净销售金额（DCom）
// Display Folder: Item Stockout & Slow Mover Alert\Base Metrics
// 用途: 当前行主键（spu_id / sku_id 表通用）This Period 净销售金额
//       （当前币种），Top 100 排序依据指标
// 依赖: Slicer_Time_Frame_Min_This[TimeFrame_Min] / Slicer_Time_Frame_Max_This[TimeFrame_Max]
//       Slicer_Currency_Selection[Currency_ExchangeRate]
// 口径: 时间范围看 this period；该 spu_id/sku_id 下 sum(net_sales_amt)
//       （主键粒度全量——跨 product_type / special_series / 尺码 / 渠道明细汇总）
// 数据底表: s02_trade_sku_data_d
// 行维度传递: 行分组（spu_id 或 sku_id 单列）筛选自动落在 trade 表对应
//       列上，聚合自动限定当前行主键——单度量双表通用，无需分支
// 渠道: Platform / Store 切片器经模型关系自动传导（不显式处理）
// 币种: 数据底表仅存 CNY，Value 层换算为当前币种金额（原始值 ÷ 汇率）；
//       RMB 汇率 = 1 时换算前后值相同
// ========================================

// ── This Period 时间区间 ──
VAR __PeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Min_This[TimeFrame_Min])
VAR __PeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

// ── 币种汇率（RMB = 1；USD 动态取自数仓汇率表）──
VAR __ExchangeRate = SELECTEDVALUE(Slicer_Currency_Selection[Currency_ExchangeRate], 1)

// ── 当前行主键 This Period 净销售金额（原始 CNY）──
VAR __BaseValue =
    CALCULATE(
        SUM('s02_trade_sku_data_d'[net_sales_amt]),
        's02_trade_sku_data_d'[dt] >= __PeriodMin,
        's02_trade_sku_data_d'[dt] <= __PeriodMax
    )

RETURN
    DIVIDE(__BaseValue, __ExchangeRate)   // BLANK ÷ 汇率 = BLANK（当期无销售数据返回空）
```

### 4.4 Item Stockout SLS Amt Display（当期净销售金额显示）

```dax
Item Stockout SLS Amt Display =
// ========================================
// 度量值: Item Stockout SLS Amt Display
// 中文名: 当期净销售金额显示
// Display Folder: Item Stockout & Slow Mover Alert\Formatting
// 用途: currency 格式化（币种符号 + 千分位整数）；BLANK 显示 "-"
// 依赖: [Item Stockout SLS Amt Value], Slicer_Currency_Selection[Currency_Symbol]
// 数据格式: 币种符号 & #,##0（如 ¥1,000 / $1,000）
// ========================================
    VAR __Value = [Item Stockout SLS Amt Value]
    VAR __CurrencySymbol = SELECTEDVALUE(Slicer_Currency_Selection[Currency_Symbol], "¥")
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            __CurrencySymbol & FORMAT(__Value, "#,##0")
        )
```

### 4.5 Item Stockout SLS Units Value（当期净销售数量）

```dax
Item Stockout SLS Units Value =
// ========================================
// 度量值: Item Stockout SLS Units Value
// 中文名: 当期净销售数量（DCom）
// Display Folder: Item Stockout & Slow Mover Alert\Base Metrics
// 用途: 当前行主键 This Period 净销售数量（主键粒度全量），单度量双表通用
// 依赖: Slicer_Time_Frame_Min_This[TimeFrame_Min] / Slicer_Time_Frame_Max_This[TimeFrame_Max]
// 口径: 时间范围看 this period；该 spu_id/sku_id 下 sum(product_qty)
// 数据底表: s02_trade_sku_data_d
// 行维度传递: 行分组（主键单列）筛选自动传导，无需分支
// 说明: 数量类指标，不涉及币种换算
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

### 4.6 Item Stockout SLS Units Display（当期净销售数量显示）

```dax
Item Stockout SLS Units Display =
// ========================================
// 度量值: Item Stockout SLS Units Display
// 中文名: 当期净销售数量显示
// Display Folder: Item Stockout & Slow Mover Alert\Formatting
// 用途: integer 格式化（千分位整数）；BLANK 显示 "-"
// 依赖: [Item Stockout SLS Units Value]
// 数据格式: #,##0（如 12,345）
// ========================================
    VAR __Value = [Item Stockout SLS Units Value]
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            FORMAT(__Value, "#,##0")
        )
```

### 4.7 Item Stockout EOH Unit Value（期末库存数量）

```dax
Item Stockout EOH Unit Value =
// ========================================
// 度量值: Item Stockout EOH Unit Value
// 中文名: 期末库存数量
// Display Folder: Item Stockout & Slow Mover Alert\Base Metrics
// 用途: 当前行主键期末库存数量（This 期末快照日单日时点，主键粒度），
//       单度量双表通用
// 依赖: Slicer_Time_Frame_Max_This[TimeFrame_Min] / [TimeFrame_Max]
// 口径: 时间范围看 this period 最后一天（end period 范围内最后一个快照日）；
//       该 spu_id/sku_id 下 sum(stock_inv_qty)
// 数据底表: SPU 表分支 = s02_inventory_stock_sales_detail_d_spu（数仓 SPU
//       粒度预聚合表，快照日每 spu 一行，SUM 退化为该行值，v2.4 切换）；
//       SKU 表分支 = s02_inventory_stock_sales_detail_d（原状）
// 行维度传递: 两表无模型关系——ISINSCOPE(trade[spu_id]) 判定当前表格，
//       TREATAS 主键单列桥接（SPU 表 = 该 spu 快照日预聚合单行；SKU 表 =
//       该 sku 快照日单行），IF 标量双分支
//       （分支 CALCULATE 返回标量后经 IF 选择，TREATAS 不经 IF 传递）
// 渠道: inv 表无 platform / shop_name 字段，本指标不受渠道筛选影响
// 说明: 期末时点只取快照日单日，对区间求和会重复计数库存
// ========================================

// ── End Period This 时间范围（期末时点类）──
VAR __EndPeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Min])
VAR __EndPeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

// ── 期末日期：end period 最后一天 = Max_This 表 TimeFrame_Max（直接单日过滤）──
VAR __EndPeriodDate = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

// ── 表判定（两表互斥显示，行分组必含 spu_id / sku_id 其一）──
VAR __InSpuId = ISINSCOPE('s02_trade_sku_data_d'[spu_id])

RETURN
    IF(
        __InSpuId,
        // ── SPU 表分支：TREATAS 传 spu_id 单列（spu 预聚合表，快照日每 spu 单行）──
        CALCULATE(
            SUM('s02_inventory_stock_sales_detail_d_spu'[stock_inv_qty]),
            TREATAS(
                VALUES('s02_trade_sku_data_d'[spu_id]),
                's02_inventory_stock_sales_detail_d_spu'[spu_id]
            ),
            's02_inventory_stock_sales_detail_d_spu'[dt] = __EndPeriodDate
        ),
        // ── SKU 表分支：锚点列换 sku_id（快照日单行）──
        CALCULATE(
            SUM('s02_inventory_stock_sales_detail_d'[stock_inv_qty]),
            TREATAS(
                VALUES('s02_trade_sku_data_d'[sku_id]),
                's02_inventory_stock_sales_detail_d'[sku_id]
            ),
            's02_inventory_stock_sales_detail_d'[dt] = __EndPeriodDate
        )
    )
```

### 4.8 Item Stockout EOH Unit Display（期末库存数量显示）

```dax
Item Stockout EOH Unit Display =
// ========================================
// 度量值: Item Stockout EOH Unit Display
// 中文名: 期末库存数量显示
// Display Folder: Item Stockout & Slow Mover Alert\Formatting
// 用途: integer 格式化（千分位整数）；BLANK 显示 "-"
// 依赖: [Item Stockout EOH Unit Value]
// 数据格式: #,##0（如 45,678）
// ========================================
    VAR __Value = [Item Stockout EOH Unit Value]
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            FORMAT(__Value, "#,##0")
        )
```

### 4.9 Item Stockout In-transit Inventory Value（在途库存数量）

```dax
Item Stockout In-transit Inventory Value =
// ========================================
// 度量值: Item Stockout In-transit Inventory Value
// 中文名: 在途库存数量
// Display Folder: Item Stockout & Slow Mover Alert\Base Metrics
// 用途: 当前行主键在途库存数量（This 期末快照日单日时点，主键粒度），
//       单度量双表通用
// 依赖: Slicer_Time_Frame_Max_This[TimeFrame_Min] / [TimeFrame_Max]
// 口径: 看所选时间范围 end period 最后一天；该 spu_id/sku_id 下
//       sum(in_trans_inv_qty)
// 数据底表: SPU 表分支 = s02_inventory_stock_sales_detail_d_spu（v2.4 切换）；
//       SKU 表分支 = s02_inventory_stock_sales_detail_d（原状）
// 行维度传递: 同 EOH Unit（TREATAS 主键单列 + IF 标量双分支，见 §4.7）
// 渠道: inv 表无渠道字段，本指标不受渠道筛选影响
// 说明: 期末时点只取快照日单日
// ========================================

// ── End Period This 时间范围 ──
VAR __EndPeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Min])
VAR __EndPeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

// ── 期末日期：end period 最后一天 = Max_This 表 TimeFrame_Max（直接单日过滤）──
VAR __EndPeriodDate = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

// ── 表判定 ──
VAR __InSpuId = ISINSCOPE('s02_trade_sku_data_d'[spu_id])

RETURN
    IF(
        __InSpuId,
        CALCULATE(
            SUM('s02_inventory_stock_sales_detail_d_spu'[in_trans_inv_qty]),
            TREATAS(
                VALUES('s02_trade_sku_data_d'[spu_id]),
                's02_inventory_stock_sales_detail_d_spu'[spu_id]
            ),
            's02_inventory_stock_sales_detail_d_spu'[dt] = __EndPeriodDate
        ),
        CALCULATE(
            SUM('s02_inventory_stock_sales_detail_d'[in_trans_inv_qty]),
            TREATAS(
                VALUES('s02_trade_sku_data_d'[sku_id]),
                's02_inventory_stock_sales_detail_d'[sku_id]
            ),
            's02_inventory_stock_sales_detail_d'[dt] = __EndPeriodDate
        )
    )
```

### 4.10 Item Stockout In-transit Inventory Display（在途库存数量显示）

```dax
Item Stockout In-transit Inventory Display =
// ========================================
// 度量值: Item Stockout In-transit Inventory Display
// 中文名: 在途库存数量显示
// Display Folder: Item Stockout & Slow Mover Alert\Formatting
// 用途: integer 格式化（千分位整数）；BLANK 显示 "-"
// 依赖: [Item Stockout In-transit Inventory Value]
// 数据格式: #,##0
// ========================================
    VAR __Value = [Item Stockout In-transit Inventory Value]
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            FORMAT(__Value, "#,##0")
        )
```

### 4.11 Item Stockout Weeks Cover Value（库存周转周数）

```dax
Item Stockout Weeks Cover Value =
// ========================================
// 度量值: Item Stockout Weeks Cover Value
// 中文名: 库存周转周数
// Display Folder: Item Stockout & Slow Mover Alert\Base Metrics
// 用途: 当前行主键的库存周转周数（(期末库存 + 在途) / This Period 销售数量），
//       跨 trade + inv 双表，主键粒度，单度量双表通用
// 依赖: Slicer_Time_Frame_Min_This[TimeFrame_Min] / Slicer_Time_Frame_Max_This[TimeFrame_Max]
//       （销售侧区间）；Slicer_Time_Frame_Max_This[TimeFrame_Min] / [TimeFrame_Max]
//       （库存侧期末时点）
// 口径: 销售数量看 this period 区间 sum(product_qty)；库存相关看 end period
//       最后一天 sum(stock_inv_qty) + sum(in_trans_inv_qty)；
//       (库存 + 在途) / 销售数量
// 口径修正: 原始口径计算指标列分子分母写反，以业务定义为准（分子库存+在途，
//       分母销售数量——口径 §25 修正记录）
// 数据底表: s02_trade_sku_data_d（分母）；分子 SPU 表分支 =
//       s02_inventory_stock_sales_detail_d_spu（v2.4 切换），SKU 表分支 =
//       s02_inventory_stock_sales_detail_d（原状）
// 行维度传递: 分母行分组（主键单列）筛选自动传导；分子 TREATAS 主键单列 +
//       IF 标量双分支
// 边界: 销售数量为 0 或 BLANK 时返回 BLANK（DIVIDE 拦截，避免失真周数）
// ========================================

// ── This Period 时间区间（销售侧分母）──
VAR __PeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Min_This[TimeFrame_Min])
VAR __PeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

// ── End Period This 时间范围（库存侧期末时点）──
VAR __EndPeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Min])
VAR __EndPeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

// ── 期末日期：end period 最后一天 = Max_This 表 TimeFrame_Max（直接单日过滤）──
VAR __EndPeriodDate = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

// ── 表判定 ──
VAR __InSpuId = ISINSCOPE('s02_trade_sku_data_d'[spu_id])

// ── 分子：期末库存 + 在途（快照日单日，TREATAS 主键单列双分支；SPU 分支
//    取 spu 预聚合表，快照日每 spu 单行）──
VAR __InvUnits =
    IF(
        __InSpuId,
        CALCULATE(
            SUM('s02_inventory_stock_sales_detail_d_spu'[stock_inv_qty])
                + SUM('s02_inventory_stock_sales_detail_d_spu'[in_trans_inv_qty]),
            TREATAS(
                VALUES('s02_trade_sku_data_d'[spu_id]),
                's02_inventory_stock_sales_detail_d_spu'[spu_id]
            ),
            's02_inventory_stock_sales_detail_d_spu'[dt] = __EndPeriodDate
        ),
        CALCULATE(
            SUM('s02_inventory_stock_sales_detail_d'[stock_inv_qty])
                + SUM('s02_inventory_stock_sales_detail_d'[in_trans_inv_qty]),
            TREATAS(
                VALUES('s02_trade_sku_data_d'[sku_id]),
                's02_inventory_stock_sales_detail_d'[sku_id]
            ),
            's02_inventory_stock_sales_detail_d'[dt] = __EndPeriodDate
        )
    )

// ── 分母：This Period 净销售数量（行分组筛选自动传导）──
VAR __SlsUnits =
    CALCULATE(
        SUM('s02_trade_sku_data_d'[product_qty]),
        's02_trade_sku_data_d'[dt] >= __PeriodMin,
        's02_trade_sku_data_d'[dt] <= __PeriodMax
    )

RETURN
    DIVIDE(__InvUnits, __SlsUnits)   // 分母 0 / BLANK → BLANK
```

### 4.12 Item Stockout Weeks Cover Display（库存周转周数显示）

```dax
Item Stockout Weeks Cover Display =
// ========================================
// 度量值: Item Stockout Weeks Cover Display
// 中文名: 库存周转周数显示
// Display Folder: Item Stockout & Slow Mover Alert\Formatting
// 用途: decimal_1dp 格式化（1 位小数，千分位）；BLANK 显示 "-"
// 依赖: [Item Stockout Weeks Cover Value]
// 数据格式: #,##0.0（如 12.3；原始口径未定义格式，按周数语义取 1 位小数）
// ========================================
    VAR __Value = [Item Stockout Weeks Cover Value]
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            FORMAT(__Value, "#,##0.0")
        )
```

### 4.13 Item Stockout MTD SLS Unit Value（月至今净销售数量）

```dax
Item Stockout MTD SLS Unit Value =
// ========================================
// 度量值: Item Stockout MTD SLS Unit Value
// 中文名: 月至今净销售数量（DCom）
// Display Folder: Item Stockout & Slow Mover Alert\Base Metrics
// 用途: end period 所在财月第一天至 end period 最后一天的净销售数量
//       （主键粒度全量），单度量双表通用
// 依赖: Slicer_Time_Frame_Max_This[Fiscal_Month_First_Day] / [TimeFrame_Max]
// 口径: 时间范围看 this period 的 end period 所在财月第一天至 end period
//       最后一天；该 spu_id/sku_id 下 sum(product_qty)
// 数据底表: s02_trade_sku_data_d
// 行维度传递: 行分组（主键单列）筛选自动传导，无需分支
// 说明: 起点字段由 Slicer_Time_Frame_Max_This 表提供（口径 §26 指定）
// ========================================

// ── MTD 时间区间（财月第一天 → end period 最后一天）──
VAR __MtdStart = SELECTEDVALUE(Slicer_Time_Frame_Max_This[Fiscal_Month_First_Day])
VAR __PeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

RETURN
    CALCULATE(
        SUM('s02_trade_sku_data_d'[product_qty]),
        's02_trade_sku_data_d'[dt] >= __MtdStart,
        's02_trade_sku_data_d'[dt] <= __PeriodMax
    )
```

### 4.14 Item Stockout MTD SLS Unit Display（月至今净销售数量显示）

```dax
Item Stockout MTD SLS Unit Display =
// ========================================
// 度量值: Item Stockout MTD SLS Unit Display
// 中文名: 月至今净销售数量显示
// Display Folder: Item Stockout & Slow Mover Alert\Formatting
// 用途: integer 格式化（千分位整数）；BLANK 显示 "-"
// 依赖: [Item Stockout MTD SLS Unit Value]
// 数据格式: #,##0
// ========================================
    VAR __Value = [Item Stockout MTD SLS Unit Value]
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            FORMAT(__Value, "#,##0")
        )
```

### 4.15 Item Stockout YTD SLS Unit Value（年至今净销售数量）

```dax
Item Stockout YTD SLS Unit Value =
// ========================================
// 度量值: Item Stockout YTD SLS Unit Value
// 中文名: 年至今净销售数量（DCom）
// Display Folder: Item Stockout & Slow Mover Alert\Base Metrics
// 用途: end period 所在财年第一天至 end period 最后一天的净销售数量
//       （主键粒度全量），单度量双表通用
// 依赖: Slicer_Time_Frame_Max_This[Fiscal_Year_First_Day] / [TimeFrame_Max]
// 口径: 时间范围看 this period 的 end period 所在财年第一天至 end period
//       最后一天；该 spu_id/sku_id 下 sum(product_qty)
// 数据底表: s02_trade_sku_data_d
// 行维度传递: 行分组（主键单列）筛选自动传导，无需分支
// 说明: 起点字段由 Slicer_Time_Frame_Max_This 表提供（口径 §27 指定）
// ========================================

// ── YTD 时间区间（财年第一天 → end period 最后一天）──
VAR __YtdStart = SELECTEDVALUE(Slicer_Time_Frame_Max_This[Fiscal_Year_First_Day])
VAR __PeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

RETURN
    CALCULATE(
        SUM('s02_trade_sku_data_d'[product_qty]),
        's02_trade_sku_data_d'[dt] >= __YtdStart,
        's02_trade_sku_data_d'[dt] <= __PeriodMax
    )
```

### 4.16 Item Stockout YTD SLS Unit Display（年至今净销售数量显示）

```dax
Item Stockout YTD SLS Unit Display =
// ========================================
// 度量值: Item Stockout YTD SLS Unit Display
// 中文名: 年至今净销售数量显示
// Display Folder: Item Stockout & Slow Mover Alert\Formatting
// 用途: integer 格式化（千分位整数）；BLANK 显示 "-"
// 依赖: [Item Stockout YTD SLS Unit Value]
// 数据格式: #,##0
// ========================================
    VAR __Value = [Item Stockout YTD SLS Unit Value]
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            FORMAT(__Value, "#,##0")
        )
```

### 4.17 Item Stockout ST% Value（售罄率%）

```dax
Item Stockout ST% Value =
// ========================================
// 度量值: Item Stockout ST% Value
// 中文名: 售罄率%（数量口径）
// Display Folder: Item Stockout & Slow Mover Alert\Base Metrics
// 用途: 当前行主键的售罄率——This Period 销售数量 /（This Period 销售数量 +
//       期末库存数量），跨 trade + inv 双表，主键粒度，单度量双表通用
// 依赖: Slicer_Time_Frame_Min_This[TimeFrame_Min] / Slicer_Time_Frame_Max_This[TimeFrame_Max]
//       （销售侧区间）；Slicer_Time_Frame_Max_This[TimeFrame_Min] / [TimeFrame_Max]
//       （库存侧期末时点）
// 口径: 销售数量看 this period 区间；期末库存数量看 end period 最后一天；
//       sales.sum(product_qty) / (sales.sum(product_qty) + inv.sum(stock_inv_qty))
// 口径修正: 原始口径公式为金额口径（net_sales_amt / msrp_inv_amt），已确认
//       修正为数量口径（口径 §28 修正记录）
// 数据底表: s02_trade_sku_data_d（sales）；库存加项 SPU 表分支 =
//       s02_inventory_stock_sales_detail_d_spu（v2.4 切换），SKU 表分支 =
//       s02_inventory_stock_sales_detail_d（原状）
// 行维度传递: 销售侧行分组（主键单列）筛选自动传导；库存侧 TREATAS 主键
//       单列 + IF 标量双分支
// 渠道: 销售侧受 Platform / Store 筛选影响，库存侧不受（inv 表无渠道字段）——
//       分子分母渠道口径不对称为模型物理限制，业务需知悉
// ========================================

// ── This Period 时间区间（销售侧）──
VAR __PeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Min_This[TimeFrame_Min])
VAR __PeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

// ── End Period This 时间范围（库存侧期末时点）──
VAR __EndPeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Min])
VAR __EndPeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

// ── 期末日期：end period 最后一天 = Max_This 表 TimeFrame_Max（直接单日过滤）──
VAR __EndPeriodDate = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

// ── 表判定 ──
VAR __InSpuId = ISINSCOPE('s02_trade_sku_data_d'[spu_id])

// ── 分子：This Period 净销售数量（行分组筛选自动传导）──
VAR __SlsUnits =
    CALCULATE(
        SUM('s02_trade_sku_data_d'[product_qty]),
        's02_trade_sku_data_d'[dt] >= __PeriodMin,
        's02_trade_sku_data_d'[dt] <= __PeriodMax
    )

// ── 库存加项：期末库存数量（快照日单日，TREATAS 主键单列双分支；SPU 分支
//    取 spu 预聚合表，快照日每 spu 单行）──
VAR __InvUnits =
    IF(
        __InSpuId,
        CALCULATE(
            SUM('s02_inventory_stock_sales_detail_d_spu'[stock_inv_qty]),
            TREATAS(
                VALUES('s02_trade_sku_data_d'[spu_id]),
                's02_inventory_stock_sales_detail_d_spu'[spu_id]
            ),
            's02_inventory_stock_sales_detail_d_spu'[dt] = __EndPeriodDate
        ),
        CALCULATE(
            SUM('s02_inventory_stock_sales_detail_d'[stock_inv_qty]),
            TREATAS(
                VALUES('s02_trade_sku_data_d'[sku_id]),
                's02_inventory_stock_sales_detail_d'[sku_id]
            ),
            's02_inventory_stock_sales_detail_d'[dt] = __EndPeriodDate
        )
    )

RETURN
    DIVIDE(__SlsUnits, __SlsUnits + __InvUnits)   // 分母加法：任一侧 BLANK 按 0 处理（DAX 算术运算 BLANK 当 0）；双侧 BLANK → BLANK
```

### 4.18 Item Stockout ST% Display（售罄率显示）

```dax
Item Stockout ST% Display =
// ========================================
// 度量值: Item Stockout ST% Display
// 中文名: 售罄率显示
// Display Folder: Item Stockout & Slow Mover Alert\Formatting
// 用途: percent_0dp 格式化（百分比整数，不含正号）；BLANK 显示 "-"
// 依赖: [Item Stockout ST% Value]
// 数据格式: #,##0%（如 63%）
// ========================================
    VAR __Value = [Item Stockout ST% Value]
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            FORMAT(__Value, "#,##0%")
        )
```

### 4.19 Item Stockout AUR Value（件单价）

```dax
Item Stockout AUR Value =
// ========================================
// 度量值: Item Stockout AUR Value
// 中文名: 件单价
// Display Folder: Item Stockout & Slow Mover Alert\Base Metrics
// 用途: 当前行主键的件单价（This Period 净销售金额 / 净销售数量，当前币种），
//       主键粒度，单度量双表通用
// 依赖: Slicer_Time_Frame_Min_This[TimeFrame_Min] / Slicer_Time_Frame_Max_This[TimeFrame_Max]
//       Slicer_Currency_Selection[Currency_ExchangeRate]
// 口径: 时间范围看 this period；sum(net_sales_amt) / sum(product_qty)
// 数据底表: s02_trade_sku_data_d
// 行维度传递: 行分组（主键单列）筛选自动传导，无需分支
// 币种: AUR 为 CNY 单价，Value 层 ÷ 汇率换算为当前币种单价
// 边界: 销售数量为 0 或 BLANK 时返回 BLANK（DIVIDE 拦截）
// ========================================

// ── This Period 时间区间 ──
VAR __PeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Min_This[TimeFrame_Min])
VAR __PeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

// ── 币种汇率 ──
VAR __ExchangeRate = SELECTEDVALUE(Slicer_Currency_Selection[Currency_ExchangeRate], 1)

// ── 分子：This Period 净销售金额（原始 CNY）──
VAR __SlsAmt =
    CALCULATE(
        SUM('s02_trade_sku_data_d'[net_sales_amt]),
        's02_trade_sku_data_d'[dt] >= __PeriodMin,
        's02_trade_sku_data_d'[dt] <= __PeriodMax
    )

// ── 分母：This Period 净销售数量 ──
VAR __SlsUnits =
    CALCULATE(
        SUM('s02_trade_sku_data_d'[product_qty]),
        's02_trade_sku_data_d'[dt] >= __PeriodMin,
        's02_trade_sku_data_d'[dt] <= __PeriodMax
    )

RETURN
    DIVIDE(DIVIDE(__SlsAmt, __SlsUnits), __ExchangeRate)   // 内层算 CNY 单价，外层换算币种
```

### 4.20 Item Stockout AUR Display（件单价显示）

```dax
Item Stockout AUR Display =
// ========================================
// 度量值: Item Stockout AUR Display
// 中文名: 件单价显示
// Display Folder: Item Stockout & Slow Mover Alert\Formatting
// 用途: currency 格式化（币种符号 + 千分位整数）；BLANK 显示 "-"
// 依赖: [Item Stockout AUR Value], Slicer_Currency_Selection[Currency_Symbol]
// 数据格式: 币种符号 & #,##0（如 ¥599）
// ========================================
    VAR __Value = [Item Stockout AUR Value]
    VAR __CurrencySymbol = SELECTEDVALUE(Slicer_Currency_Selection[Currency_Symbol], "¥")
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            __CurrencySymbol & FORMAT(__Value, "#,##0")
        )
```

### 4.21 Item Stockout MD Value（平均折扣）

```dax
Item Stockout MD Value =
// ========================================
// 度量值: Item Stockout MD Value
// 中文名: 平均折扣
// Display Folder: Item Stockout & Slow Mover Alert\Base Metrics
// 用途: 当前行主键的平均折扣（1 - 折扣价加权 / 吊牌价加权），主键粒度，
//       单度量双表通用
// 依赖: Slicer_Time_Frame_Min_This[TimeFrame_Min] / Slicer_Time_Frame_Max_This[TimeFrame_Max]
// 口径: 时间范围看 this period；
//       1 - sum(product_qty × md_price) / sum(product_qty × msrp)
// 数据底表: s02_trade_sku_data_d（md_price / msrp 为行级字段）
// 行维度传递: 行分组（主键单列）筛选自动传导，无需分支
// 空值处理: 行级乘积对任一字段（product_qty / md_price / msrp）为 BLANK 的
//       行返回 BLANK（不参与分子分母累计——对齐 SQL SUM 忽略 NULL 行语义；
//       直接算术相乘会把 BLANK 当 0，使无折扣价行的 MD 虚高为 100%）
// 边界: 分母为 0 或任一侧 BLANK 时返回 BLANK——1 - BLANK = 1 会失真为
//       100% 折扣，必须显式拦截
// 币种: 分子分母为同币种加权金额比值，不受币种选择影响
// ========================================

// ── This Period 时间区间 ──
VAR __PeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Min_This[TimeFrame_Min])
VAR __PeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

// ── 分子：折扣价加权金额（md_price 为空的行不计入）──
VAR __MdAmt =
    CALCULATE(
        SUMX(
            's02_trade_sku_data_d',
            IF(
                ISBLANK('s02_trade_sku_data_d'[product_qty])
                    || ISBLANK('s02_trade_sku_data_d'[md_price]),
                BLANK(),
                's02_trade_sku_data_d'[product_qty] * 's02_trade_sku_data_d'[md_price]
            )
        ),
        's02_trade_sku_data_d'[dt] >= __PeriodMin,
        's02_trade_sku_data_d'[dt] <= __PeriodMax
    )

// ── 分母：吊牌价加权金额（msrp 为空的行不计入）──
VAR __MsrpAmt =
    CALCULATE(
        SUMX(
            's02_trade_sku_data_d',
            IF(
                ISBLANK('s02_trade_sku_data_d'[product_qty])
                    || ISBLANK('s02_trade_sku_data_d'[msrp]),
                BLANK(),
                's02_trade_sku_data_d'[product_qty] * 's02_trade_sku_data_d'[msrp]
            )
        ),
        's02_trade_sku_data_d'[dt] >= __PeriodMin,
        's02_trade_sku_data_d'[dt] <= __PeriodMax
    )

RETURN
    IF(
        ISBLANK(__MdAmt) || ISBLANK(__MsrpAmt) || __MsrpAmt = 0,
        BLANK(),
        1 - DIVIDE(__MdAmt, __MsrpAmt)
    )
```

### 4.22 Item Stockout MD Display（平均折扣显示）

```dax
Item Stockout MD Display =
// ========================================
// 度量值: Item Stockout MD Display
// 中文名: 平均折扣显示
// Display Folder: Item Stockout & Slow Mover Alert\Formatting
// 用途: percent_0dp 格式化（百分比整数，不含正号）；BLANK 显示 "-"
// 依赖: [Item Stockout MD Value]
// 数据格式: #,##0%（如 32%）
// ========================================
    VAR __Value = [Item Stockout MD Value]
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            FORMAT(__Value, "#,##0%")
        )
```

### 4.23 Item Stockout Alert Value（缺货/滞销判定）

```dax
Item Stockout Alert Value =
// ========================================
// 度量值: Item Stockout Alert Value
// 中文名: 缺货/滞销判定
// Display Folder: Item Stockout & Slow Mover Alert\Base Metrics
// 用途: 当前行主键的预警判定（快照日 oos_tag 与 computed_product_tag 决定），
//       主键粒度，单度量双表通用
// 依赖: Slicer_Time_Frame_Max_This[TimeFrame_Min] / [TimeFrame_Max]
// 口径: 判定规则（v2.4 修订，业务确认）——
//       缺货：oos_tag = "1"（String 类型，双引号字面量）
//       滞销：computed_product_tag = 'slow mover'
//       其他情况：返回 BLANK()（显示 "-"，v2.3"其他"类别废止——仅两条件
//       之一成立才输出判定，无记录同径 BLANK）
// 分源机制（v2.4）:
//       SPU 表分支 —— 取数源切换为 s02_inventory_stock_sales_detail_d_spu
//       （数仓 SPU 粒度预聚合表，快照日每 spu 一行）：直接标量判定，
//       无跨 sku 行的最高预警级别聚合（v2.3 缺货 > 滞销 > 其他聚合逻辑废止）
//       SKU 表分支 —— 取数源仍为 s02_inventory_stock_sales_detail_d
//       （快照日每 sku 单行，唯一键 dt + sku_id + data_type）
// 标量聚合简化（v2.4，SKU 分支性能优化）: 原 CALCULATETABLE 物化整表行集 +
//       FILTER 逐行迭代（__HasOos / __HasSlow 两次 COUNTROWS(FILTER)），
//       改为 MAX 单列标量聚合——快照日单行下 MAX 退化为该行自身值；
//       行存在性以 COUNTROWS 判定（oos_tag / tag 字段可为 NULL 空串，
//       不能以标签字段非空反推行存在）
// 判定唯一性: 两条件在 SKU 级互斥为数据不变量（oos_tag = "1" 时
//       computed_product_tag 必不为 'slow mover'）——单行判定必出且仅出
//       一个状态；若两条件同时成立即为数据异常（需排查上游标签生成），
//       SWITCH 顺序仅为异常下的确定性兜底（缺货在前），非业务优先级语义；
//       SPU 预聚合行为同属数仓保证，同样互斥
// 行维度传递: TREATAS 主键单列取该主键快照日行集，IF 标量双分支
// 空值处理: 该主键在快照日无对应表记录时返回 BLANK；oos_tag 为 NULL /
//       空串时 = "1" 不成立（NULL 语义安全）
// 渠道: 两张 inv 类表均无渠道字段，本指标不受渠道筛选影响
// ========================================

// ── End Period This 时间范围 ──
VAR __EndPeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Min])
VAR __EndPeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

// ── 期末日期：end period 最后一天 = Max_This 表 TimeFrame_Max（直接单日过滤）──
VAR __EndPeriodDate = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

// ── 表判定 ──
VAR __InSpuId = ISINSCOPE('s02_trade_sku_data_d'[spu_id])

RETURN
    IF(
        __InSpuId,
        // ── SPU 表分支：spu 预聚合表直判（快照日每 spu 单行，标量取值即该行值）──
        VAR __OosTag_Spu =
            CALCULATE(
                MAX('s02_inventory_stock_sales_detail_d_spu'[oos_tag]),
                TREATAS(
                    VALUES('s02_trade_sku_data_d'[spu_id]),
                    's02_inventory_stock_sales_detail_d_spu'[spu_id]
                ),
                's02_inventory_stock_sales_detail_d_spu'[dt] = __EndPeriodDate
            )
        VAR __SlowTag_Spu =
            CALCULATE(
                MAX('s02_inventory_stock_sales_detail_d_spu'[computed_product_tag]),
                TREATAS(
                    VALUES('s02_trade_sku_data_d'[spu_id]),
                    's02_inventory_stock_sales_detail_d_spu'[spu_id]
                ),
                's02_inventory_stock_sales_detail_d_spu'[dt] = __EndPeriodDate
            )
        VAR __HasRow_Spu =
            CALCULATE(
                COUNTROWS('s02_inventory_stock_sales_detail_d_spu'),
                TREATAS(
                    VALUES('s02_trade_sku_data_d'[spu_id]),
                    's02_inventory_stock_sales_detail_d_spu'[spu_id]
                ),
                's02_inventory_stock_sales_detail_d_spu'[dt] = __EndPeriodDate
            ) > 0
        RETURN
            IF(
                NOT __HasRow_Spu,
                BLANK(),
                SWITCH(
                    TRUE(),
                    __OosTag_Spu = "1", "缺货",
                    __SlowTag_Spu = "slow mover", "滞销",
                    BLANK()
                )
            )
        ,
        // ── SKU 表分支：快照日单行标量判定（两条件互斥为数据不变量，
        //    单行下 MAX 聚合退化为该行自身值，判定结构与 SPU 分支同构）──
        VAR __OosTag_Sku =
            CALCULATE(
                MAX('s02_inventory_stock_sales_detail_d'[oos_tag]),
                TREATAS(
                    VALUES('s02_trade_sku_data_d'[sku_id]),
                    's02_inventory_stock_sales_detail_d'[sku_id]
                ),
                's02_inventory_stock_sales_detail_d'[dt] = __EndPeriodDate
            )
        VAR __SlowTag_Sku =
            CALCULATE(
                MAX('s02_inventory_stock_sales_detail_d'[computed_product_tag]),
                TREATAS(
                    VALUES('s02_trade_sku_data_d'[sku_id]),
                    's02_inventory_stock_sales_detail_d'[sku_id]
                ),
                's02_inventory_stock_sales_detail_d'[dt] = __EndPeriodDate
            )
        VAR __HasRow_Sku =
            CALCULATE(
                COUNTROWS('s02_inventory_stock_sales_detail_d'),
                TREATAS(
                    VALUES('s02_trade_sku_data_d'[sku_id]),
                    's02_inventory_stock_sales_detail_d'[sku_id]
                ),
                's02_inventory_stock_sales_detail_d'[dt] = __EndPeriodDate
            ) > 0
        RETURN
            IF(
                NOT __HasRow_Sku,
                BLANK(),
                SWITCH(
                    TRUE(),
                    __OosTag_Sku = "1", "缺货",
                    __SlowTag_Sku = "slow mover", "滞销",
                    BLANK()
                )
            )
    )
```

### 4.24 Item Stockout Alert Display（预警判定显示）

```dax
Item Stockout Alert Display =
// ========================================
// 度量值: Item Stockout Alert Display
// 中文名: 缺货/滞销判定显示
// Display Folder: Item Stockout & Slow Mover Alert\Formatting
// 用途: 文本直出（缺货 / 滞销）；BLANK（含 v2.4 起其他情况）显示 "-"
// 依赖: [Item Stockout Alert Value]
// 数据格式: 文本，无数值格式
// ========================================
    VAR __Value = [Item Stockout Alert Value]
    RETURN
        IF(ISBLANK(__Value), "-", __Value)
```

### 4.25 Item Stockout Available Sizes Value（在库尺码）

```dax
Item Stockout Available Sizes Value =
// ========================================
// 度量值: Item Stockout Available Sizes Value
// 中文名: 在库尺码
// Display Folder: Item Stockout & Slow Mover Alert\Base Metrics
// 用途: 当前行主键期末在库尺码枚举值（多值拼接文本），主键粒度，
//       单度量双表通用
// 依赖: Slicer_Time_Frame_Max_This[TimeFrame_Min] / [TimeFrame_Max]
// 口径: 看所选时间范围 end period 最后一天（口径 §32）
// 分源机制（v2.4）:
//       SPU 表分支 —— 取数源切换为 s02_inventory_stock_sales_detail_d_spu，
//       其 sku_size 字段为数仓预拼接串（该 SPU 全部在库尺码，逗号分隔），
//       直接整字段读取：v2.3 的 VALUES + CONCATENATEX 拼接与
//       inv_qty > 0 过滤逻辑整体废止（预拼接时已固化该口径）
//       SKU 表分支 —— 取数源仍为 s02_inventory_stock_sales_detail_d，
//       保持快照日 distinct sku_size where inv_qty > 0 顿号拼接（原状）
// 取值规则: 不取最新一条——快照日下取值（口径原文语义，与属性字段的
//       "最新值"规则明确区分，见 §1.3）
// 行维度传递: SPU 分支 MAX 标量取值 + SKU 分支 CONCATENATEX 文本标量，
//       均经 TREATAS 主键单列桥接后 IF 标量双分支选择
// 分隔符说明: SPU 分支输出数仓预拼接串（逗号分隔），SKU 分支输出顿号
//       （、）拼接——两表分隔符不一致为已知显示差异，尺码值本身不含
//       逗号，如需统一可在 Display 层加 SUBSTITUTE 转换（当前原样输出）
// 渠道: 两张 inv 类表均无渠道字段，本指标不受渠道筛选影响
// ========================================

// ── End Period This 时间范围 ──
VAR __EndPeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Min])
VAR __EndPeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

// ── 期末日期：end period 最后一天 = Max_This 表 TimeFrame_Max（直接单日过滤）──
VAR __EndPeriodDate = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

// ── 表判定 ──
VAR __InSpuId = ISINSCOPE('s02_trade_sku_data_d'[spu_id])

RETURN
    IF(
        __InSpuId,
        // ── SPU 表分支：直读 spu 预聚合表预拼接 sku_size（逗号分隔整串）──
        VAR __Sizes_Spu =
            CALCULATE(
                MAX('s02_inventory_stock_sales_detail_d_spu'[sku_size]),
                TREATAS(
                    VALUES('s02_trade_sku_data_d'[spu_id]),
                    's02_inventory_stock_sales_detail_d_spu'[spu_id]
                ),
                's02_inventory_stock_sales_detail_d_spu'[dt] = __EndPeriodDate
            )
        RETURN
            IF(
                ISBLANK(__Sizes_Spu) || LEN(TRIM(__Sizes_Spu)) = 0,
                BLANK(),
                __Sizes_Spu
            )
        ,
        // ── SKU 表分支：快照日 distinct 尺码（inv_qty > 0）顿号拼接（原状）──
        CONCATENATEX(
            CALCULATETABLE(
                VALUES('s02_inventory_stock_sales_detail_d'[sku_size]),
                TREATAS(
                    VALUES('s02_trade_sku_data_d'[sku_id]),
                    's02_inventory_stock_sales_detail_d'[sku_id]
                ),
                's02_inventory_stock_sales_detail_d'[dt] = __EndPeriodDate,
                's02_inventory_stock_sales_detail_d'[inv_qty] > 0
            ),
            's02_inventory_stock_sales_detail_d'[sku_size], "、",
            's02_inventory_stock_sales_detail_d'[sku_size], ASC
        )
    )
```

### 4.26 Item Stockout Available Sizes Display（在库尺码显示）

```dax
Item Stockout Available Sizes Display =
// ========================================
// 度量值: Item Stockout Available Sizes Display
// 中文名: 在库尺码显示
// Display Folder: Item Stockout & Slow Mover Alert\Formatting
// 用途: 文本直出（尺码枚举拼接值）；BLANK 显示 "-"
// 依赖: [Item Stockout Available Sizes Value]
// 数据格式: 文本枚举，无数值格式
// ========================================
    VAR __Value = [Item Stockout Available Sizes Value]
    RETURN
        IF(ISBLANK(__Value), "-", __Value)
```

### 4.27 Item Stockout Replenishment Count Value（补货数量）

```dax
Item Stockout Replenishment Count Value =
// ========================================
// 度量值: Item Stockout Replenishment Count Value
// 中文名: 补货数量
// Display Folder: Item Stockout & Slow Mover Alert\Base Metrics
// 用途: 当前行主键的补货数量（This 期末快照日单日时点，主键粒度），
//       单度量双表通用
// 依赖: Slicer_Time_Frame_Max_This[TimeFrame_Min] / [TimeFrame_Max]
// 口径: 看所选时间范围 end period 最后一天；该 spu_id/sku_id 下 sum(reph_qty)
//       （计算指标列直接取 reph_qty 字段——Definition 公式由数仓预计算实现，
//       口径 §33 以字段为准）
// 数据底表: SPU 表分支 = s02_inventory_stock_sales_detail_d_spu（v2.4 切换）；
//       SKU 表分支 = s02_inventory_stock_sales_detail_d（原状）
// 行维度传递: 同 EOH Unit（TREATAS 主键单列 + IF 标量双分支，见 §4.7）
// 渠道: inv 表无渠道字段，本指标不受渠道筛选影响
// 说明: 期末时点只取快照日单日
// ========================================

// ── End Period This 时间范围 ──
VAR __EndPeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Min])
VAR __EndPeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

// ── 期末日期：end period 最后一天 = Max_This 表 TimeFrame_Max（直接单日过滤）──
VAR __EndPeriodDate = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

// ── 表判定 ──
VAR __InSpuId = ISINSCOPE('s02_trade_sku_data_d'[spu_id])

RETURN
    IF(
        __InSpuId,
        CALCULATE(
            SUM('s02_inventory_stock_sales_detail_d_spu'[reph_qty]),
            TREATAS(
                VALUES('s02_trade_sku_data_d'[spu_id]),
                's02_inventory_stock_sales_detail_d_spu'[spu_id]
            ),
            's02_inventory_stock_sales_detail_d_spu'[dt] = __EndPeriodDate
        ),
        CALCULATE(
            SUM('s02_inventory_stock_sales_detail_d'[reph_qty]),
            TREATAS(
                VALUES('s02_trade_sku_data_d'[sku_id]),
                's02_inventory_stock_sales_detail_d'[sku_id]
            ),
            's02_inventory_stock_sales_detail_d'[dt] = __EndPeriodDate
        )
    )
```

### 4.28 Item Stockout Replenishment Count Display（补货数量显示）

```dax
Item Stockout Replenishment Count Display =
// ========================================
// 度量值: Item Stockout Replenishment Count Display
// 中文名: 补货数量显示
// Display Folder: Item Stockout & Slow Mover Alert\Formatting
// 用途: integer 格式化（千分位整数）；BLANK 显示 "-"
// 依赖: [Item Stockout Replenishment Count Value]
// 数据格式: #,##0
// ========================================
    VAR __Value = [Item Stockout Replenishment Count Value]
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            FORMAT(__Value, "#,##0")
        )
```

### 4.29 Item Stockout US Style（US 款号，属性列）

```dax
Item Stockout US Style =
// ========================================
// 度量值: Item Stockout US Style
// 中文名: US 款号（属性列）
// Display Folder: Item Stockout & Slow Mover Alert\Attributes
// 用途: 当前行主键的 us_style 属性值（值区域展示列，指标化输出）
// 数据底表: s02_trade_sku_data_d
// 取值规则（§1.3）: This Period 区间 + 当前主键筛选下 MAX(dt) 那天的
//       distinct 值顿号拼接（字母序升序）；us_style 为主键一对一属性，
//       拼接自然退化为单值；区间内无记录（最大 dt 为 BLANK）或当天该字段
//       全为空白时返回 BLANK
// 行维度传递: MAX(dt) 与 VALUES(字段) 均随行分组（主键单列）筛选自动
//       生效——零分支，单度量双表通用
// ========================================

// ── This Period 时间区间 ──
VAR __PeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Min_This[TimeFrame_Min])
VAR __PeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

// ── 最新日期：区间内该主键的最大 dt ──
VAR __MaxDt =
    CALCULATE(
        MAX('s02_trade_sku_data_d'[dt]),
        's02_trade_sku_data_d'[dt] >= __PeriodMin,
        's02_trade_sku_data_d'[dt] <= __PeriodMax
    )

RETURN
    IF(
        ISBLANK(__MaxDt),
        BLANK(),
        CONCATENATEX(
            FILTER(
                CALCULATETABLE(
                    VALUES('s02_trade_sku_data_d'[us_style]),
                    's02_trade_sku_data_d'[dt] = __MaxDt
                ),
                NOT ISBLANK('s02_trade_sku_data_d'[us_style])
                    && LEN(TRIM('s02_trade_sku_data_d'[us_style])) > 0
            ),
            's02_trade_sku_data_d'[us_style], "、",
            's02_trade_sku_data_d'[us_style], ASC
        )
    )
```

### 4.30 Item Stockout AX Class（AX 分类，属性列）

```dax
Item Stockout AX Class =
// ========================================
// 度量值: Item Stockout AX Class
// 中文名: AX 分类（属性列）
// Display Folder: Item Stockout & Slow Mover Alert\Attributes
// 用途: 当前行主键的 ax_class 属性值（值区域展示列，指标化输出）
// 数据底表: s02_trade_sku_data_d
// 取值规则: 同 US Style（最新日期 distinct 拼接，一对一属性退化单值，见 §4.29）
// ========================================

// ── This Period 时间区间 ──
VAR __PeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Min_This[TimeFrame_Min])
VAR __PeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

// ── 最新日期 ──
VAR __MaxDt =
    CALCULATE(
        MAX('s02_trade_sku_data_d'[dt]),
        's02_trade_sku_data_d'[dt] >= __PeriodMin,
        's02_trade_sku_data_d'[dt] <= __PeriodMax
    )

RETURN
    IF(
        ISBLANK(__MaxDt),
        BLANK(),
        CONCATENATEX(
            FILTER(
                CALCULATETABLE(
                    VALUES('s02_trade_sku_data_d'[ax_class]),
                    's02_trade_sku_data_d'[dt] = __MaxDt
                ),
                NOT ISBLANK('s02_trade_sku_data_d'[ax_class])
                    && LEN(TRIM('s02_trade_sku_data_d'[ax_class])) > 0
            ),
            's02_trade_sku_data_d'[ax_class], "、",
            's02_trade_sku_data_d'[ax_class], ASC
        )
    )
```

### 4.31 Item Stockout Product Type（产品类型，属性列）

```dax
Item Stockout Product Type =
// ========================================
// 度量值: Item Stockout Product Type
// 中文名: 产品类型（属性列）
// Display Folder: Item Stockout & Slow Mover Alert\Attributes
// 用途: 当前行主键的 product_type 属性值（值区域展示列，指标化输出）
// 数据底表: s02_trade_sku_data_d
// 取值规则（§1.3）: 最新日期 distinct 顿号拼接——product_type 为主键一对多
//       属性（同一主键不同 sku / 记录可能不同），最新日期当天多值全部拼接
//       （如 "Jacket、T-shirt"）
// ========================================

// ── This Period 时间区间 ──
VAR __PeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Min_This[TimeFrame_Min])
VAR __PeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

// ── 最新日期 ──
VAR __MaxDt =
    CALCULATE(
        MAX('s02_trade_sku_data_d'[dt]),
        's02_trade_sku_data_d'[dt] >= __PeriodMin,
        's02_trade_sku_data_d'[dt] <= __PeriodMax
    )

RETURN
    IF(
        ISBLANK(__MaxDt),
        BLANK(),
        CONCATENATEX(
            FILTER(
                CALCULATETABLE(
                    VALUES('s02_trade_sku_data_d'[product_type]),
                    's02_trade_sku_data_d'[dt] = __MaxDt
                ),
                NOT ISBLANK('s02_trade_sku_data_d'[product_type])
                    && LEN(TRIM('s02_trade_sku_data_d'[product_type])) > 0
            ),
            's02_trade_sku_data_d'[product_type], "、",
            's02_trade_sku_data_d'[product_type], ASC
        )
    )
```

### 4.32 Item Stockout Special Series（特别系列，属性列）

```dax
Item Stockout Special Series =
// ========================================
// 度量值: Item Stockout Special Series
// 中文名: 特别系列（属性列）
// Display Folder: Item Stockout & Slow Mover Alert\Attributes
// 用途: 当前行主键的 special_series 属性值（值区域展示列，指标化输出）
// 数据底表: s02_trade_sku_data_d
// 取值规则: 同 Product Type（最新日期 distinct 顿号拼接，一对多属性，见 §4.31）
// ========================================

// ── This Period 时间区间 ──
VAR __PeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Min_This[TimeFrame_Min])
VAR __PeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

// ── 最新日期 ──
VAR __MaxDt =
    CALCULATE(
        MAX('s02_trade_sku_data_d'[dt]),
        's02_trade_sku_data_d'[dt] >= __PeriodMin,
        's02_trade_sku_data_d'[dt] <= __PeriodMax
    )

RETURN
    IF(
        ISBLANK(__MaxDt),
        BLANK(),
        CONCATENATEX(
            FILTER(
                CALCULATETABLE(
                    VALUES('s02_trade_sku_data_d'[special_series]),
                    's02_trade_sku_data_d'[dt] = __MaxDt
                ),
                NOT ISBLANK('s02_trade_sku_data_d'[special_series])
                    && LEN(TRIM('s02_trade_sku_data_d'[special_series])) > 0
            ),
            's02_trade_sku_data_d'[special_series], "、",
            's02_trade_sku_data_d'[special_series], ASC
        )
    )
```

### 4.33 Item Stockout SPU Image（商品图片，属性列）

```dax
Item Stockout SPU Image =
// ========================================
// 度量值: Item Stockout SPU Image
// 中文名: 商品图片（属性列）
// Display Folder: Item Stockout & Slow Mover Alert\Attributes
// 用途: 当前行主键的 spu_img_url 图片链接（值区域展示列，度量设置
//       数据类别 = 图像 URL 后显示图片）
// 数据底表: s02_trade_sku_data_d
// 取值规则: 同 US Style（最新日期 distinct 拼接，一对一属性退化单值）；
//       spu_img_url 为主键一对一属性，正常输出单条 URL
// 配置: 度量工具 → 数据类别 → 图像 URL；值区域列显示商品图片
// ========================================

// ── This Period 时间区间 ──
VAR __PeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Min_This[TimeFrame_Min])
VAR __PeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

// ── 最新日期 ──
VAR __MaxDt =
    CALCULATE(
        MAX('s02_trade_sku_data_d'[dt]),
        's02_trade_sku_data_d'[dt] >= __PeriodMin,
        's02_trade_sku_data_d'[dt] <= __PeriodMax
    )

RETURN
    IF(
        ISBLANK(__MaxDt),
        BLANK(),
        CONCATENATEX(
            FILTER(
                CALCULATETABLE(
                    VALUES('s02_trade_sku_data_d'[spu_img_url]),
                    's02_trade_sku_data_d'[dt] = __MaxDt
                ),
                NOT ISBLANK('s02_trade_sku_data_d'[spu_img_url])
                    && LEN(TRIM('s02_trade_sku_data_d'[spu_img_url])) > 0
            ),
            's02_trade_sku_data_d'[spu_img_url], "、",
            's02_trade_sku_data_d'[spu_img_url], ASC
        )
    )
```

### 4.34 Item Stockout Special Supply（特供标识，属性列）

```dax
Item Stockout Special Supply =
// ========================================
// 度量值: Item Stockout Special Supply
// 中文名: 特供标识（属性列）
// Display Folder: Item Stockout & Slow Mover Alert\Attributes
// 用途: 当前行主键的 special_supply 属性值（值区域展示列，指标化输出）
// 数据底表: s02_trade_sku_data_d
// 取值源（用户指定）: 从 trade 表取（v1.0 曾从 inv 桥接，v2.0 改源——
//       除 computed_product_tag 外属性字段全部取 trade）
// 取值规则: 同 US Style（最新日期 distinct 拼接，一对一属性退化单值）
// ========================================

// ── This Period 时间区间 ──
VAR __PeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Min_This[TimeFrame_Min])
VAR __PeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

// ── 最新日期 ──
VAR __MaxDt =
    CALCULATE(
        MAX('s02_trade_sku_data_d'[dt]),
        's02_trade_sku_data_d'[dt] >= __PeriodMin,
        's02_trade_sku_data_d'[dt] <= __PeriodMax
    )

RETURN
    IF(
        ISBLANK(__MaxDt),
        BLANK(),
        CONCATENATEX(
            FILTER(
                CALCULATETABLE(
                    VALUES('s02_trade_sku_data_d'[special_supply]),
                    's02_trade_sku_data_d'[dt] = __MaxDt
                ),
                NOT ISBLANK('s02_trade_sku_data_d'[special_supply])
                    && LEN(TRIM('s02_trade_sku_data_d'[special_supply])) > 0
            ),
            's02_trade_sku_data_d'[special_supply], "、",
            's02_trade_sku_data_d'[special_supply], ASC
        )
    )
```

### 4.35 Item Stockout Product Tag（商品分层标签，inv 属性列）

```dax
Item Stockout Product Tag =
// ========================================
// 度量值: Item Stockout Product Tag
// 中文名: 商品分层标签（属性列）
// Display Folder: Item Stockout & Slow Mover Alert\Attributes
// 用途: 当前行主键的商品分层标签（hero model / slow mover / normal），
//       主键粒度，单度量双表通用
// 依赖: Slicer_Time_Frame_Max_This[TimeFrame_Min] / [TimeFrame_Max]
// 取数源: SPU 表分支 = s02_inventory_stock_sales_detail_d_spu（v2.4 切换，
//       SPU 粒度预聚合表——快照日每 spu 单行，CONCATENATEX 自然退化为
//       该行单值）；SKU 表分支 = s02_inventory_stock_sales_detail_d（原状）
// 取值规则（§1.3）: 最新期末快照日下该主键行的 computed_product_tag
//       distinct 值顿号拼接（字母序升序）——SKU 表快照日每 sku 单行，
//       拼接自然退化为单值；无 inv 记录或全部空白时返回 BLANK
//       （v2.3 描述的"同 spu 不同 sku 分层共存拼接"场景随 SPU 分支切换
//       预聚合表而消失——spu 行标签为数仓预聚合结果）
// 行维度传递: TREATAS 主键单列 + IF 标量双分支（分支 CONCATENATEX 返回
//       文本标量后经 IF 选择）
// 渠道: inv 表无渠道字段，本属性不受渠道筛选影响
// ========================================

// ── End Period This 时间范围 ──
VAR __EndPeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Min])
VAR __EndPeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

// ── 期末日期：end period 最后一天 = Max_This 表 TimeFrame_Max（直接单日过滤）──
VAR __EndPeriodDate = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

// ── 表判定 ──
VAR __InSpuId = ISINSCOPE('s02_trade_sku_data_d'[spu_id])

RETURN
    IF(
        __InSpuId,
        CONCATENATEX(
            FILTER(
                CALCULATETABLE(
                    VALUES('s02_inventory_stock_sales_detail_d_spu'[computed_product_tag]),
                    TREATAS(
                        VALUES('s02_trade_sku_data_d'[spu_id]),
                        's02_inventory_stock_sales_detail_d_spu'[spu_id]
                    ),
                    's02_inventory_stock_sales_detail_d_spu'[dt] = __EndPeriodDate
                ),
                NOT ISBLANK('s02_inventory_stock_sales_detail_d_spu'[computed_product_tag])
                    && LEN(TRIM('s02_inventory_stock_sales_detail_d_spu'[computed_product_tag])) > 0
            ),
            's02_inventory_stock_sales_detail_d_spu'[computed_product_tag], "、",
            's02_inventory_stock_sales_detail_d_spu'[computed_product_tag], ASC
        ),
        CONCATENATEX(
            FILTER(
                CALCULATETABLE(
                    VALUES('s02_inventory_stock_sales_detail_d'[computed_product_tag]),
                    TREATAS(
                        VALUES('s02_trade_sku_data_d'[sku_id]),
                        's02_inventory_stock_sales_detail_d'[sku_id]
                    ),
                    's02_inventory_stock_sales_detail_d'[dt] = __EndPeriodDate
                ),
                NOT ISBLANK('s02_inventory_stock_sales_detail_d'[computed_product_tag])
                    && LEN(TRIM('s02_inventory_stock_sales_detail_d'[computed_product_tag])) > 0
            ),
            's02_inventory_stock_sales_detail_d'[computed_product_tag], "、",
            's02_inventory_stock_sales_detail_d'[computed_product_tag], ASC
        )
    )
```

---

## 5. 度量值清单

| #  | 度量值                                                                                         | 类型                               | 用于视觉对象                    |
| -- | ---------------------------------------------------------------------------------------------- | ---------------------------------- | ------------------------------- |
| 1  | Item Stockout SPU Rank                                                                         | RANK 窗口（两键决胜，唯一名次）    | SPU 表（视觉级筛选器 + 行排序） |
| 2  | Item Stockout SKU Rank                                                                         | RANK 窗口（两键决胜，唯一名次）    | SKU 表（视觉级筛选器 + 行排序） |
| 3  | Item Stockout SLS Amt Value / Display                                                          | currency                           | 两表共用                        |
| 4  | Item Stockout SLS Units Value / Display                                                        | integer                            | 两表共用                        |
| 5  | Item Stockout EOH Unit Value / Display                                                         | integer                            | 两表共用                        |
| 6  | Item Stockout In-transit Inventory Value / Display                                             | integer                            | 两表共用                        |
| 7  | Item Stockout Weeks Cover Value / Display                                                      | decimal_1dp                        | 两表共用                        |
| 8  | Item Stockout MTD SLS Unit Value / Display                                                     | integer                            | 两表共用                        |
| 9  | Item Stockout YTD SLS Unit Value / Display                                                     | integer                            | 两表共用                        |
| 10 | Item Stockout ST% Value / Display                                                              | percent_0dp                        | 两表共用                        |
| 11 | Item Stockout AUR Value / Display                                                              | currency                           | 两表共用                        |
| 12 | Item Stockout MD Value / Display                                                               | percent_0dp                        | 两表共用                        |
| 13 | Item Stockout Alert Value / Display                                                            | 文本（缺货/滞销，其他 BLANK）      | 两表共用（SPU 分支取 spu 预聚合表） |
| 14 | Item Stockout Available Sizes Value / Display                                                  | 文本枚举（SPU 直读预拼接 / SKU 顿号拼接） | 两表共用                        |
| 15 | Item Stockout Replenishment Count Value / Display                                              | integer                            | 两表共用                        |
| 16 | Item Stockout US Style / AX Class / Product Type / Special Series / SPU Image / Special Supply | trade 属性（最新日期拼接，零分支） | 两表共用（值区域）              |
| 17 | Item Stockout Product Tag                                                                      | inv 属性（快照日拼接，IF 双分支，SPU 分支取预聚合表） | 两表共用（值区域）              |

- 全部度量值存放于 `_Measures` 隐藏表；Display Folder：`Item Stockout & Slow Mover Alert\Rank`、`Item Stockout & Slow Mover Alert\Attributes`、`Item Stockout & Slow Mover Alert\Base Metrics`、`Item Stockout & Slow Mover Alert\Formatting`
- 十三个口径指标各 Value / Display 成对输出（26 个）；Rank 2 个；属性度量 7 个（trade 侧 6 + inv 侧 1）——合计 35 个度量值
- 除 Rank 外全部指标单度量双表通用（trade 侧与属性零分支，inv 侧 ISINSCOPE 判定 + IF 标量双分支 + 分源：SPU 分支 → s02_inventory_stock_sales_detail_d_spu，SKU 分支 → s02_inventory_stock_sales_detail_d）

---

## 6. 视觉对象配置

### 6.1 两张表格

| 配置项           | SPU 表格                                                                                             | SKU 表格                                                                                                                                         |
| ---------------- | ---------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------ |
| 视觉对象类型     | 表格                                                                                                 | 表格                                                                                                                                             |
| 字段井（行分组） | s02_trade_sku_data_d[spu_id]（单列——最终展示不重复的 spu_id）                                      | s02_trade_sku_data_d[sku_id]（单列）                                                                                                             |
| 视觉级筛选器 1   | s02_trade_sku_data_d[spu_id] 前 100 个（按 Item Stockout SLS Amt Value 降序）——筛选类型「前 N 个」 | s02_trade_sku_data_d[sku_id] 前 100 个（按 Item Stockout SLS Amt Value 降序）                                                                    |
| 视觉级筛选器 2   | Item Stockout SLS Amt Value 不为空（防 BLANK 行混入）                                                | 同左                                                                                                                                             |
| 视觉级筛选器 3   | s02_trade_sku_data_d[spu_id] 不为空（列筛选器）                                                      | s02_trade_sku_data_d[sku_id] 不为空（列筛选器）——排除空白主键行占 TopN 名额                                                                    |
| 禁止配置         | ——                                                                                                 | **不可配置「Rank 介于 1 与 100」度量筛选器**（迫使 Rank 对全部主键分组逐组求值，每组物化一次候选集，O(行数 × 候选集) 卡顿根源，见 §3.2） |
| 行排序           | SPU Rank 升序（列标题点击排序）                                                                      | SKU Rank 升序                                                                                                                                    |

值区域建议列序（两表一致）：

| 顺序 | 列                            | 度量                                                                   |
| ---- | ----------------------------- | ---------------------------------------------------------------------- |
| 1    | 图片                          | Item Stockout SPU Image（数据类别 = 图像 URL）                         |
| 2    | US / Class                    | Item Stockout US Style、Item Stockout AX Class                         |
| 3    | Type / Series                 | Item Stockout Product Type、Item Stockout Special Series               |
| 4    | Tag / Supply                  | Item Stockout Product Tag、Item Stockout Special Supply                |
| 5    | SLS Amt                       | Item Stockout SLS Amt Display                                          |
| 6    | SLS Units                     | Item Stockout SLS Units Display                                        |
| 7    | EOH                           | Item Stockout EOH Unit Display                                         |
| 8    | In-transit                    | Item Stockout In-transit Inventory Display                             |
| 9    | Weeks Cover                   | Item Stockout Weeks Cover Display                                      |
| 10   | MTD / YTD                     | Item Stockout MTD SLS Unit Display、Item Stockout YTD SLS Unit Display |
| 11   | ST% / AUR / MD                | Item Stockout ST% / AUR / MD Display                                   |
| 12   | Alert / Sizes / Replenishment | Item Stockout Alert / Available Sizes / Replenishment Count Display    |
| 13   | Rank（排序依据）              | Item Stockout SPU Rank（或 SKU Rank），置于最后并收窄列宽              |

配置要点：

- **字段井仅主键一列**：product_type / special_series 等全部属性经值区域度量输出——行分组单列保证视觉级 Rank 筛选器落地为单列筛选（候选集 ALL(主键) 干净清除）、展示不重复的主键行
- **属性列值为拼接文本**：product_type / special_series / product tag 同日（最新日期 / 快照日）多值时显示顿号拼接（§1.3 规则）；一对一属性自然退化为单值；v2.4 起 SPU 表 Product Tag 取 spu 预聚合表单行值（不再多值拼接）
- **总计行不做特判**：交由表格视觉对象默认生成（总计行上 SELECTEDVALUE 主键为 BLANK，Rank / 属性度量返回 BLANK，数值指标为全量聚合）
- Rank 度量列必须留在值区域可见（行排序绑定该列；「介于 1 与 100」筛选器亦引用该度量）

### 6.2 按钮切换

| 配置项   | 内容                                                                                   |
| -------- | -------------------------------------------------------------------------------------- |
| 切换机制 | 两个按钮（SPU / SKU）经书签控制两张表格显隐——每按钮一书签：显示对应表格 + 隐藏另一张 |
| 交互     | 两表互斥显示；指标度量共用，无需为按钮写度量分支                                       |

### 6.3 切片器

| 切片器                                        | 类型             | 作用                                                                                                                                               |
| --------------------------------------------- | ---------------- | -------------------------------------------------------------------------------------------------------------------------------------------------- |
| Slicer_Time_Frame                             | 主时间筛选器     | 驱动 Min_This / Max_This 断开维度表，经 SELECTEDVALUE 读入度量值（MTD / YTD 起点同读 Max_This 表；属性字段"最新日期"判定同读 Min_This / Max_This） |
| Slicer_Platform_Selection / Slicer_Store_Name | 一对多关系切片器 | 经模型关系自动传导至 trade 侧（指标与 Top 100 候选随渠道收窄），DAX 不显式处理；inv 侧不受影响                                                     |
| 其余商品维度切片器                            | 一对多关系切片器 | 与两张事实表已建关系的自动传导（候选金额与指标同口径收窄）                                                                                         |
| Slicer_Currency_Selection                     | 断开维度         | SLS Amt / AUR 的汇率与符号来源；数量 / 占比 / 比率类不受影响                                                                                       |

---

## 7. 验证方法

测试文件：`test_Item_Stockout_Table.sql`（MySQL 8.0+，CTE / 窗口函数 / GROUP_CONCAT，字面量直嵌），一个文件两段独立执行（SQL 1/2 SPU 维度 GROUP BY spu_id、SQL 2/2 SKU 维度 GROUP BY sku_id），每段按 SLS Amt 降序 + 主键字母序决胜输出 Top 100（ORDER BY + LIMIT 100，对齐 PBI TopN 列筛选器与行序）。核心还原逻辑：

| 指标                             | 测试 SQL 还原                                                                                                                                                                 |
| -------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| SLS Amt / SLS Units / AUR / MD   | trade 侧按 spu_id / sku_id 单列 GROUP BY（net_sales_amt = ROUND(product_qty × sales_price, 6) 行级还原；MD 分子分母行级乘积 SUM，NULL 行忽略 + 分母 0 拦截）                 |
| MTD / YTD SLS Unit               | 条件聚合 dt ∈ [财月首日 '2026-06-28' / 财年首日 '2026-03-29', '2026-07-25']（本参数下 YTD 与 This Period 重合）                                                              |
| EOH / In-transit / Replenishment | inv 侧按主键单列 GROUP BY，WHERE dt = 快照日 '2026-07-25'；不附加渠道条件（inv 无渠道字段）；SPU 段改查 s02_inventory_stock_sales_detail_d_spu（data_type = 'spu' 预聚合行，直接取单行值，v2.4）                                                              |
| ST%                              | 销售侧数量与库存侧数量按主键各自聚合后相除（分母加法 NULL 按 0，销售侧 NULL → 整体 NULL）                                                                                    |
| Weeks Cover                      | 分子库存 + 在途（快照日，NULL 按 0）与分母销售数量（this period）相除；分母 0 / NULL → NULL                                                                                  |
| Alert                            | 缺货 = oos_tag = '1'（String）；滞销 = computed_product_tag = 'slow mover'；其他情况 NULL（v2.4 起不再输出 '其他'）；SPU 段直取 spu 预聚合表单行判定（无优先级聚合），SKU 段取 inv 表单行直判；无对应表行 → NULL |
| Available Sizes                  | SPU 段直取 spu 预聚合表 sku_size 预拼接串（逗号分隔，原样输出）；SKU 段 GROUP_CONCAT(DISTINCT CASE WHEN inv_qty > 0 THEN sku_size END ORDER BY ...) 顿号拼接                                                                                          |
| 属性字段（trade 六字段）         | trade_maxdt（主键 MAX(dt)）+ trade_attr：最新日期当天 distinct 值 GROUP_CONCAT(DISTINCT NULLIF(TRIM(字段), '') ORDER BY ...) 顿号拼接                                         |
| Product Tag                      | SKU 段：inv 快照日下主键 GROUP BY 的 GROUP_CONCAT(DISTINCT NULLIF(TRIM(computed_product_tag), '')) 顿号拼接；SPU 段：直取 spu 预聚合表单行 computed_product_tag |
| Rank                             | DENSE_RANK() OVER (ORDER BY 金额 DESC, 主键 ASC)——两键决胜对齐；值域排除空白主键，NULL 金额行排末尾不进 Top 100                                                             |

- NULL 语义对齐 DAX：分子 NULL → 比率 NULL；MD / AUR 任一侧 NULL 或分母 0 → NULL；Alert / 库存类无 inv 记录 → NULL（显示 "-"）；属性字段区间无记录或当天全空白 → NULL
- 参数区（测试文件头注释）：Platform / Store 全选、This Period ['2026-03-29', '2026-07-25']、快照日 '2026-07-25'、财月首日 '2026-06-28'、财年首日 '2026-03-29'（Last Period / Last Year / This Year 组参数本方案无 vs 指标不参与计算，留档）；修改时对两段全文替换

---

## 8. 注意事项

1. **模块维度为单列主键**：字段井仅放 spu_id / sku_id 一列——最终展示不重复的主键行；全部指标聚合、Top 100 排名、inv 桥接均按主键粒度（跨 product_type / special_series / 尺码 / 渠道明细汇总）
2. **属性字段全部指标化**：us_style / ax_class / product_type / special_series / spu_img_url / computed_product_tag / special_supply 七个字段经值区域度量输出（§1.3 规则）——不进字段井，避免多列行分组下视觉级 Rank 筛选器落地为跨列组合筛选侵入候选集
3. **属性"最新值"规则**：trade 侧六字段 = This Period 区间内该主键最大 dt 那天的 distinct 值顿号拼接（同日多值是常态——trade 为 sku 粒度，同日不同 sku / 记录的 product_type / special_series 可能不同，全部拼接展示）；一对一属性（us_style / ax_class / spu_img_url / special_supply）拼接自然退化为单值；区间内无记录或当天全空白返回 BLANK
4. **Available Sizes 不取最新**：快照日下取值（口径 §32 原文语义），与属性字段"最新值"规则明确区分；v2.4 分源——SPU 表直读 spu 预聚合表 sku_size 预拼接串（逗号分隔，数仓已固化在库口径，PBI 不再复算 CONCATENATEX / inv_qty > 0），SKU 表保持 distinct sku_size where inv_qty > 0 顿号拼接
5. **Rank relation 用法（按度量值排名的唯一合法形式）**：RANK 省略 relation 时 ORDERBY 仅允许简单列引用——CALCULATE 等度量表达式作排序键报错"已省略 RANK 的关系参数，并且其 ORDERBY 子句包含非引用列表达式"（v2.1 实证）；按度量值排名必须显式指定 relation（FILTER(ADDCOLUMNS(ALL(主键), @Amt))，两键决胜 [@Amt] DESC + 主键 ASC，名次唯一）；候选集 ALL(主键) 同时移除行分组筛选与视觉级 TopN 落地筛选 → 排名恒为全局真实名次
6. **行筛选必须用原生「前 N 个」列筛选器，禁止「Rank 介于 1 与 100」度量筛选器**：视觉级筛选器三条——①「spu_id / sku_id 前 100 个（按 Item Stockout SLS Amt Value 降序）」（引擎单遍分组求值排序度量取 TopN，Rank 仅对可见 100 行求值，候选表跨行共享缓存）②「SLS Amt Value 不为空」③「主键 不为空」；度量筛选器须对全部主键分组逐组求值 Rank（每组物化一次候选集，O(行数 × 候选集)）——数万主键量级下明显卡顿，为本次性能问题根源；边界并列提示：TopN 引擎并列打破不确定（非按主键字母序），金额完全相等且恰跨第 100 名边界时入选行与 Rank 决胜链可能不一致（6 位小数精度下概率极低）
7. **inv 桥接为 IF 标量双分支**：TREATAS / CALCULATETABLE 不经 IF 传递（IF 分支返回表会被降级为标量）——各分支聚合返回标量后经 IF 选择；表判定用 ISINSCOPE(trade[spu_id])，两表互斥显示，行分组必含其一
8. **Alert 判定规则（v2.4 业务确认修订）**：缺货 = oos_tag = "1"（String 字面量）；滞销 = computed_product_tag = 'slow mover'；其他情况返回 BLANK()（v2.3"其他"类别废止；无对应表行同径 BLANK）；两条件互斥为数据不变量——单行判定必出且仅出一个状态，两条件同时成立属数据异常（SWITCH 顺序仅为异常下确定性兜底，非业务优先级）；SPU 分支取 spu 预聚合表直判（最高预警级别聚合废止），SKU 分支取 inv 表单行直判（CALCULATETABLE 整表物化 + FILTER 迭代已简化为 MAX 标量聚合；行存在性用 COUNTROWS 判定——标签字段可为 NULL / 空串，不能以其非空反推行存在）
9. **渠道口径不对称**：Platform / Store 切片器经关系自动传导仅作用于 trade 侧（SLS 系列指标 + Top 100 候选）；两张 inv 类表均无渠道字段，库存侧指标全量口径——ST% / Weeks Cover 分子分母渠道不对称为模型物理限制，业务需知悉
10. **期末时点口径**：This 期末快照日 = end period 范围内最后一个有数据的日期（快照缺数自动回退）；快照表按日存储只取单日，对整段区间求和会重复计数库存
11. **net_sales_amt 列来源**：模型内为 Power Query 行级计算列（ROUND(product_qty × sales_price, 6)），数据库无此列——测试 SQL 验证时按行级乘积还原
12. **MD 空值拦截**：分子分母行级乘积对任一字段 NULL 的行不计入（直接算术相乘会把 BLANK 当 0，无折扣价行 MD 虚高 100%）；分母为 0 或任一侧 BLANK 时整体返回 BLANK（1 - BLANK = 1 失真，必须显式拦截）
13. **ST% 数量口径 / Weeks Cover 分子分母方向**：均为口径文档已确认修正项（§28 金额→数量、§25 原始公式写反以业务定义为准），不可回退
14. **MTD / YTD 起点**：读 Slicer_Time_Frame_Max_This 表 Fiscal_Month_First_Day / Fiscal_Year_First_Day 字段，终点 TimeFrame_Max（口径 §26 / §27 指定）
15. **RANK / ORDERBY 版本要求**：Power BI Desktop 2022 年 9 月及以后版本
16. **总计行为**：总计行不做特判，交由表格视觉对象默认生成（总计行主键为 BLANK，Rank / 属性度量返回 BLANK，数值指标为全量聚合）
17. **口径与语法**：口径文档中定义的所有指标必须遵守其数据类型与数据格式，与解决方案存在争议时一切以口径文档为准；DAX 文本常量使用双引号，单引号仅用于表名，列名使用方括号
18. **SPU 表分支取数源切换（v2.4）**：inv 类指标 SPU 分支统一改读 s02_inventory_stock_sales_detail_d_spu（与 s02_inventory_stock_sales_detail_d 同源——均取自 s02_inventory_stock_sales_detail_result_d，按 data_type = 'spu' / 'sku' 分流；spu 行快照日每 spu 单行，sku_size 为逗号分隔预拼接串，oos_tag / computed_product_tag 等标签为数仓预聚合结果），SKU 分支保持原状；**建模前提**：spu 表需建立与 inv 表同款的外部维度关系（Division 等），否则 SPU 分支丢失切片器收窄；Available Sizes 两表分隔符不一致（SPU 逗号 / SKU 顿号）为已知显示差异，如需统一在 Display 层加 SUBSTITUTE 转换
