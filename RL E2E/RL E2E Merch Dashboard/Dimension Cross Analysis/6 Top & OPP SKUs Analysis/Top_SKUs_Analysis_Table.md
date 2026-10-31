# Top_SKUs_Analysis_Table 解决方案（Top 部分）

> **版本**: v2.0
> **模块**: RL E2E Merch Dashboard - Dimension Cross Analysis Tab - Top & OPP SKUs Analysis（Top 部分）
> **关联口径**: 口径文档/口径Markdown格式/Dimension Cross Analysis.md - 子模块九（§40 Weeks Cover / §41 SLS Units / §42 EOH + 模块说明属性列；§43~§49 为 OPP 部分指标，不在本方案范围，后续另行方案）
> **数据底表（销售/属性类）**: s02_trade_sku_data_d
> **数据底表（库存类）**: s02_inventory_stock_sales_detail_d
> **关联维度**: Slicer_Time_Frame_Min_This / Max_This（时间，断开维度）；Slicer_Framework（framework 一对多关系，前置筛选 'Foundation' 自动传导）；Slicer_Platform_Selection / Slicer_Store_Name（一对多关系自动传导，DAX 不显式处理）；Slicer_Currency_Selection（币种，断开维度）
> **筛选影响范围**: dt（断开维度，DAX 显式筛选）+ framework 前置筛选 + Platform / Store Name（模型关系自动传导）+ 其余与两张事实表已建关系的商品维度切片器
>
> **版本记录**:
> v2.1（2026-10-26，用户改写）——SKU Rank 改 RANKX 迭代器模式（候选集 CALCULATETABLE(VALUES, REMOVEFILTERS(sku), category 等值, dt)，无中间表物化、SE 批量合并）；Sort Key 改金额编码（-(CatAmt × 1e6 + SkuAmt)，负号翻转，排序与排名解耦）；并列语义改 DENSE（金额并列共享名次，放行含并列）——权重前提单 SKU 金额 < 1e6，超限改 1e9/1e12
> v2.0（2026-10-26）——性能修复第二轮：SKU Rank 排名表物化改 SUMMARIZE 单次分组查询（CALCULATETABLE 净化上下文内，GROUP BY sku_id 一条 SE 查询物化全部候选），替代 v1.1 的 ADDCOLUMNS + 逐候选 CALCULATE（每候选一次上下文转换，R′×K̄ 次转换为仍卡根因——SE 缓存无法消除 FE 转换开销）；候选集收窄与净化机制保持
> v1.1（2026-10-26）——性能修复：SKU Rank / Sort Key 类别排名候选集由全模型值域（ALL）收窄为当前分组值域（CALCULATETABLE 净化上下文 + VALUES），消除视觉级度量筛选器下 O(行组合数 × 全值域) 的逐候选聚合（查询超时被取消的根因）；Predictive Buy 比较类型修正为整数字面量（用户实证字段为整数类型）
> v1.0（2026-10-26）——初版：每 category Top3 SKU 平铺表格（组内排名度量筛选器 + Sort Key 编码排序）

---

## 1. 需求理解

### 1.1 模块定位与视觉对象结构

Top & OPP SKUs Analysis 板块含 TOP 与 OPP 两部分（口径板块级商品维度切换 TOP / OPP，经页面按钮 + 书签切换显隐，不在本方案度量值范围）。本方案仅覆盖 **TOP 部分**：单张平铺表格，前置筛选 framework = 'Foundation'，行 = category + sku_id 组合，每个 category 分组下按 SLS Amt 降序取 Top3 SKU：

| 配置项           | 内容                                                                                          |
| ---------------- | --------------------------------------------------------------------------------------------- |
| 视觉对象类型     | 表格（平铺，无层级无小计，总计行交由视觉对象默认生成）                                        |
| 字段井（行分组） | s02_trade_sku_data_d[category]、s02_trade_sku_data_d[sku_id]（两列行分组——每行一个组合）      |
| 值区域（属性列） | Product Photo / Product Type / Price / Predictive Buy（度量，见 §1.3）                        |
| 值区域（指标列） | SLS Units / EOH / Weeks Cover Display + SLS Amt（隐藏排序依据）+ Sort Key（行排序依据）       |
| 视觉级筛选器     | Slicer_Framework[framework] = 'Foundation'（前置）+ Top SKUs SKU Rank 介于 1 与 3 + 空白键排除 |
| 行排序           | Top SKUs Sort Key 升序（category 块按 SLS Amt 降序 + 组内 sku 按金额降序，行序完全确定）      |

- **指标计算粒度**：全部指标按当前行 category + sku_id 组合聚合——行分组双列筛选自动落在 trade 表对应列上，聚合范围 = 该组合下全部记录（跨尺码 / 渠道明细汇总）
- **inv 侧显式桥接**：两张事实表之间无模型关系，sku_id 行筛选对库存类指标不自动传递，经 DAX TREATAS sku_id 单列显式桥接（见 §3.4）
- **Top3 行筛选**：每个 category 分组内按 This Period SLS Amt 降序保留前三，由视觉级「SKU Rank 介于 1 与 3」度量筛选器实现（见 §3.2）
- **framework 前置筛选**：Slicer_Framework 与两张事实表一对多关联（framework 字段两表齐备，数据字典已核对），视觉对象筛选器 framework = 'Foundation' 经模型关系自动传导，DAX 不显式处理

### 1.2 指标清单

| 序号 | 指标            | 口径章节   | 时间口径               | 计算公式                                                                                                        | 数据类型 / 格式                     |
| ---- | --------------- | ---------- | ---------------------- | --------------------------------------------------------------------------------------------------------------- | ----------------------------------- |
| 1    | SLS Amt（隐藏） | 需求补充   | This Period（区间）    | 该 category + sku_id 分组下 sum(net_sales_amt)——Top3 排名与排序依据，视觉对象默认隐藏                          | currency → 币种符号 + `#,##0`      |
| 2    | SKU Rank        | 需求补充   | This Period（区间）    | category 组内按 SLS Amt 降序 + sku_id 字母序升序决胜排名（名次唯一），用于「介于 1 与 3」Top3 筛选             | integer → `#,##0`                  |
| 3    | Sort Key        | 需求补充   | This Period（区间）    | 类别排名 × 1,000,000 + 组内排名（全局唯一行排序键，见 §3.3）                                                    | integer → `#,##0`                  |
| 4    | Product Photo   | 属性列     | 最新日期（This 内）    | spu_img_url 最新日期值（§1.3 规则）                                                                             | 文本（数据类别 = 图像 URL）         |
| 5    | Product Type    | 属性列     | 最新日期（This 内）    | product_type 最新日期值（§1.3 规则）                                                                            | 文本                                |
| 6    | Price           | 属性列     | 最新日期（This 内）    | md_price 最新日期值（§1.3 规则，币种换算 + 格式化）                                                             | currency → 币种符号 + `#,##0`      |
| 7    | Predictive Buy  | 属性列     | 最新日期（This 内）    | predictive_buy 最新日期值映射：1 → "Y"、0 → "N"、其余为空（§1.3 规则）                                             | 文本枚举（Y / N）                   |
| 8    | Weeks Cover     | §40        | 跨双口径               | (sum(stock_inv_qty) + sum(in_trans_inv_qty)) / sum(product_qty)；库存侧看 end period 最后一天，销售侧 this period 区间 | decimal_1dp → `#,##0.0`          |
| 9    | SLS Units       | §41        | This Period（区间）    | 该 category + sku_id 分组下 sum(product_qty)                                                                    | integer → `#,##0`                  |
| 10   | EOH             | §42        | End Period（期末时点） | 该 sku_id 下 sum(stock_inv_qty)（快照日单日）                                                                   | integer → `#,##0`                  |

### 1.3 属性字段取值规则

四个属性字段全部按指标逻辑处理（单度量输出，规则统一，取值模式与 Item Stockout 模块 §1.3 一致）：

- **取值范围** = This Period 时间区间（[TimeFrame_Min, TimeFrame_Max]）+ 当前行 category + sku_id 分组筛选 + 外部切片器（framework / Platform / Store 等，自动传导）下的全部记录
- **"最新"定义**：范围内该 category + sku_id 组合的最大 dt（`MAX(trade[dt])`）——用户选定时间段内最后一次出现记录的日期
- **取值**：最大 dt 那天的该字段 distinct 值，按升序顿号（、）拼接——trade 表为 sku 粒度，同一组合同日多行为常态（不同订单 / 店铺）；product_type / md_price / spu_img_url / predictive_buy 为 sku 级属性，拼接自然退化为单值
- 区间内无记录（最大 dt 为 BLANK）时返回 BLANK；最新日期当天该字段全为空白时返回 BLANK（空白值不参与拼接）
- **Price 特殊**：md_price 为 CNY 单价，逐个值 ÷ Currency_ExchangeRate 换算 + 币种符号 + `#,##0` 格式化后拼接（md_price 为 0 的行展示 ¥0，NULL 行排除）
- **Predictive Buy 特殊**：predictive_buy 为整数类型（Nullable(Int32)，v1.1 实证确认），值包括 1 / 0 / NULL——最新日期当天仅 1 / 0 参与映射（1 → "Y"、0 → "N"），NULL 不参与，全部为空时返回 BLANK
- 示例：某 category + sku_id 组合在 this period 区间内最后记录日为 2026-07-20，当天该 sku 有 3 行记录，product_type 均为 T-shirt → Product Type 列显示 "T-shirt"

### 1.4 时间口径

| 口径                     | 时间范围                                                                                                                                  | 适用指标                                                        |
| ------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------- |
| This Period（区间类）    | dt ∈ [Slicer_Time_Frame_Min_This[TimeFrame_Min], Slicer_Time_Frame_Max_This[TimeFrame_Max]]                                              | SLS Amt、SLS Units、Weeks Cover 分母、Top3 排名金额、属性"最新日期"判定 |
| End Period（期末时点类） | end period 最后一天 = Slicer_Time_Frame_Max_This[TimeFrame_Max]（直接单日过滤） | EOH、Weeks Cover 分子                                           |

说明：

- 两张 s02 表日期字段均为 dt（非 data_date）
- 期末时点为 end period 最后一天（Max_This 表 TimeFrame_Max，直接单日过滤），与口径描述一致；快照表按日存储，期末时点只取单日，对整段区间求和会把库存重复计数；该日快照缺数时指标为空，不回退取范围内最近一天
- 属性字段的"最新日期"以 This Period 区间内该组合的实际最大 dt 为准（非 TimeFrame_Max——组合在该区间内的最后记录日）

### 1.5 币种口径

- SLS Amt / Price 为 currency 类：货币符号由币种切片器（Slicer_Currency_Selection）决定，千分位整数；数据底表金额仅存储 CNY，Value 层完成汇率换算（原始值 ÷ Currency_ExchangeRate，RMB 汇率 = 1 时换算前后值相同）
- 数量 / 周数类指标与文本属性不涉及币种换算
- **Top3 排名与 Sort Key 使用原始 CNY 聚合**（除以同一正汇率不改变相对顺序），不经币种换算

### 1.6 Top3 行筛选与行排序机制

- **排名依据**：隐藏指标 SLS Amt——该 category + sku_id 分组 This Period `sum(net_sales_amt)`（原始 CNY 聚合）降序
- **组内排名（Top SKUs SKU Rank）**：category 组内按 SLS Amt 降序 + sku_id 字母序升序决胜——sku_id 在候选集内唯一，两键决胜名次严格连续唯一（1、2、3、……），「介于 1 与 3」恒放行恰好 3 行 / 分组、边界确定
- **类别排名**：category 粒度（该 category 全部 sku 汇总金额）按 SLS Amt 降序 + category 字母序升序决胜，同样名次唯一
- **Sort Key 编码**：类别排名 × 1,000,000 + 组内排名——排序键全局唯一，升序行序 = category 块按 SLS Amt 降序、块内 sku 按金额降序（编码详见 §3.3）
- **Top3 行筛选**：视觉级「Top SKUs SKU Rank 介于 1 与 3」度量筛选器（含下界）——原生「前 N 个」列筛选器为**全局** TopN（跨 category 取全表前 N），无法实现按 category 分组取 Top3，故必须用组内排名度量筛选器
- **BLANK 防护**：Rank 对空白 category / sku_id / 当期无金额行返回 BLANK；数值筛选中 BLANK 视为 0，「介于 1 与 3」的下界将其排除（「小于或等于 3」会放行 BLANK 行，禁止使用）
- **候选上下文净化（关键）**：视觉级度量筛选器生效后落地为 (category, sku_id) 跨列组合筛选，单列 ALL / REMOVEFILTERS 无法清除，会污染候选迭代（候选与组合筛选冲突取 BLANK、名次失真）——排名候选集统一在 `CALCULATETABLE(REMOVEFILTERS(category, sku_id 两列) + TREATAS 重限分组)` 的净化上下文中求值（保留 framework / 渠道等外部筛选），筛选求值与显示求值两阶段语义一致
- **排名求值复杂度（v2.0）**：视觉级度量筛选器迫使引擎对**全部 (category, sku_id) 行组合**（非仅显示行）求值 Rank——当期无销售的行组经 `__CurrentAmt` BLANK 短路（VAR 惰性求值，仅一次聚合），当期有销售的 R′ 个行组各物化一次本 category 排名表；v1.1 的 ADDCOLUMNS + 逐候选 CALCULATE 为 O(R′ × K̄) 次上下文转换（K̄ = 平均每类 sku 数；R′=3 万、K̄=1000 即 3000 万次，仍卡根因），v2.0 改 SUMMARIZE 单次分组查询（每类别一条 SE 查询、跨行缓存），FE 仅余每行 O(K) 名次匹配——候选集仍限定当前 category 值域（v1.1 收窄保持）

### 1.7 渠道与 framework 上下文

- Slicer_Framework 与 s02_trade_sku_data_d / s02_inventory_stock_sales_detail_d 均为一对多关联（framework 字段两表齐备）：前置筛选 framework = 'Foundation' 经模型关系自动传导双表，DAX 不显式处理——trade 侧指标、属性取值与 Top3 候选金额均限定 Foundation 框架内
- Slicer_Platform_Selection / Slicer_Store_Name 与 trade 表一对多关联，筛选经模型关系自动传导（trade 侧指标与 Top3 候选随渠道收窄，DAX 不显式处理）
- inv 表无 platform / shop_name 字段：库存侧指标（EOH / Weeks Cover 分子）不受渠道筛选影响——trade 侧受筛选、inv 侧全量的口径不对称为模型物理限制（Weeks Cover 分子分母渠道口径不对称，业务需知悉）；framework 筛选若与 inv 建立关系则直接传导，否则经 sku_id 桥接间接限定（传入 sku 集合已在 trade 侧含 framework 筛选）

---

## 2. 现状分析

- 数据底表 `s02_trade_sku_data_d`（SKU 粒度交易表，dt 日粒度）：net_sales_amt 为 Power Query 取数新增列（行级 `ROUND(product_qty * sales_price, 6)` 生成，模型内存在，数据库无此列——测试 SQL 验证时按行级乘积还原）；category / sku_id / spu_img_url / product_type / md_price / framework 字段齐备（已逐一核对数据字典）；predictive_buy 为 Nullable(Int32) 整数类型（v1.1 用户实证确认，值 1 / 0 / NULL，见注意事项 8）；同一组合同日多行为常态（不同订单 / 店铺）
- 数据底表 `s02_inventory_stock_sales_detail_d`（库存+销售+补货 SKU 模型表，dt 日快照，唯一键 dt + sku_id）：stock_inv_qty（在库库存，EOH 口径）、in_trans_inv_qty（在途库存）、framework 字段齐备（已逐一核对数据字典）；**无 platform / shop_name 字段**（渠道筛选不影响库存侧）
- 两张事实表之间无模型关系：sku_id 行筛选向库存类指标的传递经 DAX TREATAS 单列显式桥接（本模块行粒度为 category + sku_id，桥接锚点仅需 sku_id 单列）
- 日期筛选器（Min_This / Max_This）为断开维度，时间范围在 DAX 中显式筛选
- Slicer_Platform_Selection / Slicer_Store_Name / Slicer_Framework 及其余商品维度切片器与事实表一对多关联，筛选自动传导，DAX 无需显式处理；Slicer_Currency_Selection 为断开维度，汇率与符号经 SELECTEDVALUE 读取

---

## 3. 方案设计

### 3.1 度量值分层

```
Rank / Sort Key（Top3 行筛选 + 行排序，2 个度量）
←  SKU Rank：category 组内 SLS Amt 降序 + sku_id 字母序决胜
      （RANK 窗口函数 relation 候选集，名次唯一）
←  Sort Key：类别排名 × 1,000,000 + 组内排名（引用 SKU Rank）
      （全局唯一行排序键，category 块按金额降序）
←  候选上下文净化 + 值域收窄 + 批量物化：CALCULATETABLE(REMOVEFILTERS
      (category, sku_id 两列) + TREATAS 重限分组) 净化上下文中
      SUMMARIZE 单次分组查询物化候选（非逐候选 CALCULATE，v2.0）
↓
Value（口径计算，3 个指标各一 + 4 个属性度量）
←  trade 侧：时间范围显式筛选，行分组（category + sku_id）自动传导
←  inv 侧：TREATAS(trade[sku_id] → inv[sku_id]) 单列桥接
      + inv[dt] = end period 最后一天（单日时点，Max_This 表 TimeFrame_Max 直接单日过滤）
←  SLS Amt / Price 金额类 Value 层完成币种换算（原始 CNY ÷ 汇率）
↓
Display（格式化显示）
←  currency: 币种符号 & FORMAT(#,##0)；integer: FORMAT(#,##0)
←  decimal_1dp: FORMAT(#,##0.0)；文本类（属性）BLANK 显示 "-"
←  属性度量（Product Photo / Product Type / Price / Predictive Buy）
      无 Value / Display 分层，单度量直接输出展示文本
```

### 3.2 Top3 行筛选机制

每个表格视觉对象配置四条视觉级筛选器：

| 筛选器                          | 类型       | 条件              | 作用                                                                                                        |
| ------------------------------- | ---------- | ----------------- | ----------------------------------------------------------------------------------------------------------- |
| Slicer_Framework[framework]     | 列筛选器   | = Foundation      | 前置筛选（用户配置）——经一对多关系自动传导双表                                                              |
| Top SKUs SKU Rank               | 度量筛选器 | 介于 1 与 3       | **行筛选主力**——每个 category 分组保留组内 SLS Amt 前三的 sku；含下界排除 BLANK 行（空白键 / 当期无金额） |
| s02_trade_sku_data_d[category]  | 列筛选器   | 不为空            | 排除空白 category 组（文本列 NULL 与空字符均归 (Blank) 组被排除）                                            |
| s02_trade_sku_data_d[sku_id]    | 列筛选器   | 不为空            | 双保险——Rank 对空白 sku 已返回 BLANK 被区间筛选排除，此条防边界（空白主键若金额非空会进入排名占据名额）    |

机制说明：

- **必须用组内排名度量筛选器**：原生「前 N 个」列筛选器为全局 TopN（对全部 sku_id 按度量排序取全表前 N），不按 category 分组——本场景"每个 category 取 Top3"只有组内排名 + 区间筛选可实现（与 Item Stockout 全局 Top 100 用原生 TopN 列筛选器的场景本质不同）
- **「介于 1 与 3」必须含下界**：Rank 度量对空白 / 当期无金额行返回 BLANK，数值筛选比较中 BLANK 视为 0——「小于或等于 3」成立（0 ≤ 3）会放行 BLANK 行，「介于 1 与 3」的下界（0 < 1 不满足）将其排除
- **性能结构（v2.0 修复）**：度量筛选器需对全部 category + sku_id 行组合逐组求值 Rank 后决定保留行——当期无销售行组经 `__CurrentAmt` BLANK 短路（VAR 惰性求值，排名表不物化）；当期有销售的 R′ 个行组各物化一次本 category 排名表：v1.0 用 `ALL(sku_id)` 全模型值域（O(行组合数 × 全值域)，超时根因）；v1.1 收窄为当前 category 值域但物化用 ADDCOLUMNS + 逐候选 CALCULATE（每候选一次上下文转换，O(R′ × K̄) 次转换，仍卡根因——SE 查询可被缓存，FE 逐候选上下文转换无法被缓存消除）；v2.0 改 SUMMARIZE 在净化上下文中一次分组查询物化全部候选金额（每类别一条 SE 查询，同 category 各行共享缓存），FE 仅余每行 O(K) 名次匹配；category / sku_id「不为空」列筛选器先行收窄查询行集，务必配置
- **Rank 仅决定行去留**：行序由 Sort Key 承担（Sort Key 在筛选落地后的显示上下文中求值，候选集净化保证其为全局真实排名，见 §3.3）

### 3.3 Sort Key 排序键编码

表格视觉对象仅支持单键排序，两级行排序规则通过排序键度量编码为一个整数，表格按该键升序排序：

| 层级        | 规则                                                                              | 编码贡献           |
| ----------- | --------------------------------------------------------------------------------- | ------------------ |
| L1 类别排名 | category 粒度 This Period sum(net_sales_amt) 降序（category 字母序 ASC 决胜）    | 排名 × 1,000,000   |
| L2 组内排名 | category 内 sku 按 This Period sum(net_sales_amt) 降序（sku_id 字母序 ASC 决胜） | 排名 × 1           |

排序键 = L1 + L2，升序排序后行序为：category 块按当期净销售金额降序排列（销售最大的 category 在最前），每个块内 sku 按金额降序。

示例（金额故意错开，展示两级分工）：

| category | category SLS Amt | 类别排名 | sku_id | 组内排名 | Sort Key   |
| -------- | ---------------- | -------- | ------ | -------- | ---------- |
| Knit     | ¥900,000         | 1        | SKU-A  | 1        | 1,000,001  |
| Knit     | ¥900,000         | 1        | SKU-C  | 2        | 1,000,002  |
| Knit     | ¥900,000         | 1        | SKU-B  | 3        | 1,000,003  |
| Belts    | ¥150,000         | 2        | SKU-D  | 1        | 2,000,001  |
| Belts    | ¥150,000         | 2        | SKU-E  | 2        | 2,000,002  |
| Belts    | ¥150,000         | 2        | SKU-F  | 3        | 2,000,003  |

- **权重前提**：单个 category 内 sku 数 < 1,000,000（L2 不侵位 L1）；类别数量不限
- **名次唯一 → 排序键唯一**：两级排名均为两键决胜（金额降序 + 维度值字母序升序）的严格唯一名次，排序键全局唯一、行序完全确定（金额完全相等的并列行序也确定）
- **类别排名为全局真实排名**：候选集经净化（REMOVEFILTERS 两列 + TREATAS 重建），不受视觉级 Top3 筛选器落地的组合筛选影响——Top3 只决定行去留，不改变 category 全量金额与排名
- 排名基于原始 CNY 金额聚合（不经币种换算——除以同一正汇率不改变相对顺序）

### 3.4 inv 侧 TREATAS sku_id 单列桥接

行组合筛选向 s02_inventory_stock_sales_detail_d 的传递：

```dax
CALCULATE(
    SUM('s02_inventory_stock_sales_detail_d'[stock_inv_qty]),
    TREATAS(
        VALUES('s02_trade_sku_data_d'[sku_id]),
        's02_inventory_stock_sales_detail_d'[sku_id]
    ),
    's02_inventory_stock_sales_detail_d'[dt] = __EndPeriodDate_This
)
```

- **sku_id 单列 TREATAS**：本模块行粒度为 category + sku_id，inv 表唯一键 dt + sku_id——sku_id 单列桥接即唯一锚定该 sku 快照日单行（category 为 sku 从属属性，无需双列传递）
- **无需 IF 分支**：与 Item Stockout 双表（spu / sku）切换场景不同，本模块仅 sku 粒度单一表格，桥接无分支
- **期末日期**：end period 最后一天 = `SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])`（直接单日过滤；Max_This 表为断开维度，读值不随行上下文 / 切片器漂移）
- framework 筛选若与 inv 建立关系经 CALCULATE 自动传导（同一 sku 行，无口径影响）；与 inv 已建关系的其余维度切片器同样自动传导，不在桥接参数内重复处理

### 3.5 度量值命名与组织

- 命名规则：模块前缀 `Top SKUs` + 指标名 + 层次后缀（Rank / Sort Key / Value / Display）；属性列为 `Top SKUs` + 属性名（单度量）
- Display Folder：`Top & OPP SKUs Analysis\Top\Rank`、`Top & OPP SKUs Analysis\Top\Base Metrics`、`Top & OPP SKUs Analysis\Top\Attributes`、`Top & OPP SKUs Analysis\Top\Formatting`（Top 子文件夹与后续 OPP 部分度量隔离）
- 度量值统一存放于 `_Measures` 隐藏表（与看板既有组织方式一致）

---

## 4. 度量值实现

### 4.1 Top SKUs SLS Amt Value（当期净销售金额，隐藏排序依据）

```dax
Top SKUs SLS Amt Value =
// ========================================
// 度量值: Top SKUs SLS Amt Value
// 中文名: 当期净销售金额（DCom，隐藏排序依据）
// Display Folder: Top & OPP SKUs Analysis\Top\Base Metrics
// 用途: 当前行 category + sku_id 组合 This Period 净销售金额——Top3 排名
//       与 Sort Key 的排序依据指标（视觉对象中默认隐藏，对数时可拖入验证）
// 依赖: Slicer_Time_Frame_Min_This[TimeFrame_Min] / Slicer_Time_Frame_Max_This[TimeFrame_Max]
//       Slicer_Currency_Selection[Currency_ExchangeRate]
// 口径: 时间范围看 this period；该 category + sku_id 分组下 sum(net_sales_amt)
//       （组合粒度全量——跨尺码 / 渠道明细汇总）
// 数据底表: s02_trade_sku_data_d
// 行维度传递: 行分组（category + sku_id 两列）筛选自动落在 trade 表对应列上，
//       聚合自动限定当前行组合，无需分支
// 排名口径: SKU Rank / Sort Key 内部排名使用原始 CNY 聚合（不经币种换算，
//       除以同一正汇率不改变相对顺序）；本度量输出换算后金额仅供展示对数
// 渠道: Platform / Store 切片器经模型关系自动传导（不显式处理）
// 币种: 数据底表仅存 CNY，Value 层换算为当前币种金额（原始值 ÷ 汇率，
//       RMB 汇率 = 1 时换算前后值相同）
// ========================================

// ── This Period 时间区间 ──
VAR __PeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Min_This[TimeFrame_Min])
VAR __PeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

// ── 币种汇率（RMB = 1；USD 动态取自数仓汇率表）──
VAR __ExchangeRate = SELECTEDVALUE(Slicer_Currency_Selection[Currency_ExchangeRate], 1)

// ── 当前行组合 This Period 净销售金额（原始 CNY）──
VAR __BaseValue =
    CALCULATE(
        SUM('s02_trade_sku_data_d'[net_sales_amt]),
        's02_trade_sku_data_d'[dt] >= __PeriodMin,
        's02_trade_sku_data_d'[dt] <= __PeriodMax
    )

RETURN
    DIVIDE(__BaseValue, __ExchangeRate)   // BLANK ÷ 汇率 = BLANK（当期无销售数据返回空）
```

### 4.2 Top SKUs SLS Amt Display（当期净销售金额显示）

```dax
Top SKUs SLS Amt Display =
// ========================================
// 度量值: Top SKUs SLS Amt Display
// 中文名: 当期净销售金额显示
// Display Folder: Top & OPP SKUs Analysis\Top\Formatting
// 用途: currency 格式化（币种符号 + 千分位整数）；BLANK 显示 "-"
//       （隐藏指标——默认不进视觉对象，对数时拖入）
// 依赖: [Top SKUs SLS Amt Value], Slicer_Currency_Selection[Currency_Symbol]
// 数据格式: 币种符号 & #,##0（如 ¥1,000 / $1,000）
// ========================================
    VAR __Value = [Top SKUs SLS Amt Value]
    VAR __CurrencySymbol = SELECTEDVALUE(Slicer_Currency_Selection[Currency_Symbol], "¥")
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            __CurrencySymbol & FORMAT(__Value, "#,##0")
        )
```

### 4.3 Top SKUs SKU Rank（category 组内 SKU 排名，Top3 筛选依据）

```dax
Top SKUs SKU Rank =
// ========================================
// 度量值: Top SKUs SKU Rank
// 中文名: category 组内 SKU 排名（Top3 筛选依据）
// Display Folder: Top & OPP SKUs Analysis\Top\Rank
// 用途: 当前行 sku_id 在其 category 分组内按 This Period sum(net_sales_amt)
//       降序的排名，用于视觉级筛选器「介于 1 与 3」实现每个 category
//       分组仅保留 SLS Amt 前三的 SKU
// 依赖: Slicer_Time_Frame_Min_This[TimeFrame_Min] / Slicer_Time_Frame_Max_This[TimeFrame_Max]
// 口径: framework + 渠道与其余商品维度切片器筛选组合下，category 组内按
//       sku_id 粒度 This Period sum(net_sales_amt) 降序排名
// 排名语义: 金额降序；金额相同的 sku 并列同名次（DENSE），
//       「介于 1 与 3」放行名次 ≤ 3 的所有行（含并列）
// 函数: RANKX 迭代器函数——相比 RANK 窗口函数：
//       ① 无中间表物化（不需 ADDCOLUMNS 构建排名表）
//       ② SE 层可批量合并聚合查询（减少 FE→SE 往返）
//       ③ 引擎优化路径成熟（2015 年引入，10 年优化积累）
//       ④ 视觉级筛选器逐行调用场景下性能优于 RANK 5-10 倍
// 候选集: CALCULATETABLE 净化上下文中 VALUES(sku_id) 取值——
//       REMOVEFILTERS(sku_id) 清除当前行 sku 筛选，
//       category 等值条件限定当前分组，时间条件限定当期；
//       候选集 = 当前 category 内当期有数据的全部 sku
// 候选上下文净化: 视觉级度量筛选器（Rank 介于 1 与 3）生效后落地为
//       (category, sku_id) 跨列组合筛选；REMOVEFILTERS(sku_id) 清除
//       行级 sku 筛选，category 等值条件覆盖组合筛选中的 category 部分，
//       外部筛选（framework / 渠道等）自然保留
// 空白/无金额拦截: 当前行 category / sku_id 空白或当期无金额时返回 BLANK
//       （「介于 1 与 3」将 BLANK 视为 0 排除在区间外）
// 排名金额: 原始 CNY 聚合，不经币种换算（除以同一正汇率不改变相对顺序）
// 时间复杂度: 单次调用 O(S × r)，总 O(C × S × r) = O(N)
//       S = 当前 category 内 SKU 数，r = 每 SKU 平均行数，
//       C = category 数，N = 事实表总行数
// ========================================

// ── This Period 时间区间 ──
VAR __PeriodMin = SELECTEDVALUE( Slicer_Time_Frame_Min_This[TimeFrame_Min] )
VAR __PeriodMax = SELECTEDVALUE( Slicer_Time_Frame_Max_This[TimeFrame_Max] )

// ── 当前行分组值（组合筛选下 SELECTEDVALUE 逐行可取）──
VAR __CurrentCategory = SELECTEDVALUE( 's02_trade_sku_data_d'[category] )
VAR __CurrentSkuId    = SELECTEDVALUE( 's02_trade_sku_data_d'[sku_id] )

// ── 当前行组合的 This Period 净销售金额（原始 CNY）──
// 行筛选（单列或组合形式）均定义当前行自身，直接聚合即可；无金额返回 BLANK
VAR __CurrentAmt =
    CALCULATE(
        SUM( 's02_trade_sku_data_d'[net_sales_amt] ),
        's02_trade_sku_data_d'[dt] >= __PeriodMin,
        's02_trade_sku_data_d'[dt] <= __PeriodMax
    )

RETURN
IF(
    // ── 短路：category / sku_id / 金额任一为空直接退出 ──
    NOT ISBLANK( __CurrentCategory )
        && NOT ISBLANK( __CurrentSkuId )
        && NOT ISBLANK( __CurrentAmt ),

    // ── RANKX 排名 ──
    // 参数 1 - 迭代表（候选集）:
    //   CALCULATETABLE 净化上下文：
    //   · REMOVEFILTERS(sku_id) → 清除当前行 sku 筛选及视觉级组合筛选中的 sku 部分
    //   · category = __CurrentCategory → 限定当前分组（覆盖组合筛选中的 category）
    //   · dt 时间条件 → 限定当期
    //   · 外部筛选（framework / 渠道等）自然保留
    //   VALUES(sku_id) → 候选集 = 当前 category 内当期有数据的全部 sku
    //
    // 参数 2 - 排名表达式:
    //   对每个候选 sku 求 This Period sum(net_sales_amt)
    //   RANKX 迭代时自动将候选 sku 注入行上下文，
    //   CALCULATE 上下文转换叠加候选 sku 筛选 + 时间条件
    //
    // 参数 3 - 当前行值:
    //   __CurrentAmt（已预计算，避免重复聚合）
    //
    // 参数 4/5 - 排序方向 / 并列处理:
    //   DESC = 金额降序（金额最大 = 第 1 名）
    //   DENSE = 并列不跳号（1, 2, 2, 3）
    RANKX(
        CALCULATETABLE(
            VALUES( 's02_trade_sku_data_d'[sku_id] ),
            REMOVEFILTERS( 's02_trade_sku_data_d'[sku_id] ),
            's02_trade_sku_data_d'[category] = __CurrentCategory,
            's02_trade_sku_data_d'[dt] >= __PeriodMin,
            's02_trade_sku_data_d'[dt] <= __PeriodMax
        ),
        CALCULATE(
            SUM( 's02_trade_sku_data_d'[net_sales_amt] ),
            's02_trade_sku_data_d'[dt] >= __PeriodMin,
            's02_trade_sku_data_d'[dt] <= __PeriodMax
        ),
        __CurrentAmt,
        DESC,
        DENSE
    )
)

```

### 4.4 Top SKUs Sort Key（表格行排序键）

```dax
Top SKUs Sort Key =
// ========================================
// 度量值: Top SKUs Sort Key
// 中文名: 表格行排序键（金额编码，非排名）
// Display Folder: Top & OPP SKUs Analysis\Top\Rank
// 用途: 表格行排序依据——category 块按 This Period SLS Amt 降序
//       （销售最大的 category 在最前），块内 sku 按金额降序；
//       表格按此度量值「升序」排列（负号翻转实现降序效果）
// 依赖: Slicer_Time_Frame_Min_This[TimeFrame_Min] / Slicer_Time_Frame_Max_This[TimeFrame_Max]
// 核心思路: 排序不需要排名，金额本身就是顺序
//       排序键 = -(category 总金额 × 1,000,000 + SKU 金额)
//       负号使金额越大 → 值越小 → 升序排列时越靠前
// 编码: L1 = category 总金额 × 1,000,000（保证 category 块间不交叉）
//       L2 = SKU 金额 × 1（块内排序）
//       权重前提：单个 SKU 金额绝对值 < 1,000,000（CNY）
//       若金额可能超过，改用 1,000,000,000
// 负金额处理: 负号统一翻转，正负金额均正确排序
//       例：CatAmt=100, SkuAmt=80 → -(100×10⁶+80) = -100,000,080
//           CatAmt=100, SkuAmt=50 → -(100×10⁶+50) = -100,000,050
//           升序：-100,000,080 < -100,000,050 → SkuAmt=80 排前面 ✓
// 性能: 无需 RANKX / RANK，仅两次 CALCULATE SUM（SE 层直接聚合）
//       单次调用 O(r)，总复杂度 O(C × S × r) = O(N)
//       相比排名方案（O(C×S×(C×r + S×r))）快 50-100 倍
// 空白拦截: 当前行 category / sku_id 空白或当期无金额时返回 BLANK
// 排名金额: 原始 CNY 聚合，不经币种换算
// 与 [Top SKUs SKU Rank] 的关系:
//       排序用本度量值（金额编码，快）
//       筛选用 [Top SKUs SKU Rank]（RANKX 版，已优化）
//       两者各司其职，互不嵌套
// ========================================

// ── 当前行分组值 ──
VAR __CurrentCategory =
    SELECTEDVALUE( 's02_trade_sku_data_d'[category] )
VAR __CurrentSkuId =
    SELECTEDVALUE( 's02_trade_sku_data_d'[sku_id] )

RETURN
IF(
    // ── 短路：category / sku_id 空白或空字符串直接退出 ──
    ISBLANK( __CurrentCategory )
        || ISBLANK( __CurrentSkuId )
        || LEN( TRIM( __CurrentCategory ) ) = 0
        || LEN( TRIM( __CurrentSkuId ) ) = 0,
    BLANK(),

    // ── This Period 时间区间 ──
    VAR __PeriodMin = SELECTEDVALUE( Slicer_Time_Frame_Min_This[TimeFrame_Min] )
    VAR __PeriodMax = SELECTEDVALUE( Slicer_Time_Frame_Max_This[TimeFrame_Max] )

    // ── 当前行 SKU 金额（This Period 净销售，原始 CNY）──
    VAR __SkuAmt =
        CALCULATE(
            SUM( 's02_trade_sku_data_d'[net_sales_amt] ),
            's02_trade_sku_data_d'[dt] >= __PeriodMin,
            's02_trade_sku_data_d'[dt] <= __PeriodMax
        )

    RETURN
    IF(
        // ── 短路：当期无金额直接退出 ──
        ISBLANK( __SkuAmt ),
        BLANK(),

        // ── Category 总金额（上卷到 category 粒度）──
        // REMOVEFILTERS(sku_id) 清除当前行 sku 筛选 → 自动上卷
        // 当前行的 category 筛选天然保留（无需额外 TREATAS）
        // 外部筛选（framework / 渠道等）自然保留
        // 视觉级组合筛选中的 sku 部分被 REMOVEFILTERS 清除，
        // category 部分由当前行上下文保留 → 候选净化完成
        VAR __CatAmt =
            CALCULATE(
                SUM( 's02_trade_sku_data_d'[net_sales_amt] ),
                REMOVEFILTERS( 's02_trade_sku_data_d'[sku_id] ),
                's02_trade_sku_data_d'[dt] >= __PeriodMin,
                's02_trade_sku_data_d'[dt] <= __PeriodMax
            )

        // ── 排序键 = -(category 金额 × 权重 + SKU 金额) ──
        // 负号翻转：表格按此列「升序」排列 = 实际金额降序效果
        // 权重 1,000,000 保证 category 块间不交叉
        // （前提：单 SKU 金额绝对值 < 1,000,000）
        RETURN
        IF(
            NOT ISBLANK( __CatAmt ),
            -( __CatAmt * 1000000 + __SkuAmt )
        )
    )
)

```

### 4.5 Top SKUs Product Photo（商品图片，属性列）

```dax
Top SKUs Product Photo =
// ========================================
// 度量值: Top SKUs Product Photo
// 中文名: 商品图片（属性列）
// Display Folder: Top & OPP SKUs Analysis\Top\Attributes
// 用途: 当前行 category + sku_id 组合的 spu_img_url 图片链接（值区域展示列，
//       度量设置数据类别 = 图像 URL 后显示图片）
// 数据底表: s02_trade_sku_data_d
// 取值规则（§1.3）: 最新日期 distinct 顿号拼接——This Period 区间内该组合的
//       最大 dt 那天 spu_img_url distinct 值升序拼接（sku 级属性以单值为
//       主，拼接自然退化单值）；区间无记录 / 当天全空白返回 BLANK
// 行维度传递: 行分组（category + sku_id 两列）筛选自动限定取值范围，
//       framework / 渠道等外部切片器自动传导
// 配置: 度量工具 → 数据类别 → 图像 URL；值区域列显示商品图片
// ========================================

// ── This Period 时间区间 ──
VAR __PeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Min_This[TimeFrame_Min])
VAR __PeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

// ── 最新日期：该组合在区间内的最大 dt ──
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

### 4.6 Top SKUs Product Type（产品类型，属性列）

```dax
Top SKUs Product Type =
// ========================================
// 度量值: Top SKUs Product Type
// 中文名: 产品类型（属性列）
// Display Folder: Top & OPP SKUs Analysis\Top\Attributes
// 用途: 当前行 category + sku_id 组合的 product_type 属性值（值区域展示列，
//       指标化输出）
// 数据底表: s02_trade_sku_data_d
// 取值规则（§1.3）: 同 Product Photo——最新日期 distinct 顿号拼接
//       （sku 级属性以单值为主，同日多值时全部拼接，如 "Jacket、T-shirt"）
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

### 4.7 Top SKUs Price（价格，属性列）

```dax
Top SKUs Price =
// ========================================
// 度量值: Top SKUs Price
// 中文名: 价格（属性列，md_price 最新值）
// Display Folder: Top & OPP SKUs Analysis\Top\Attributes
// 用途: 当前行 category + sku_id 组合的 md_price 最新值（值区域展示列，
//       指标化输出）——折扣价则展示折扣价
// 依赖: Slicer_Time_Frame_Min_This[TimeFrame_Min] / Slicer_Time_Frame_Max_This[TimeFrame_Max]
//       Slicer_Currency_Selection[Currency_ExchangeRate] / [Currency_Symbol]
// 数据底表: s02_trade_sku_data_d
// 取值规则（§1.3）: 最新日期（This Period 区间内该组合的 MAX(dt)）当天
//       md_price distinct 值逐个换算格式化后顿号拼接（sku 级属性以单值为主）
// 币种: md_price 为 CNY 单价，逐值 ÷ Currency_ExchangeRate 换算为当前币种
//       + 币种符号 + #,##0（如 ¥599）；md_price 为 0 的行展示 ¥0，
//       NULL 行排除；区间无记录 / 当天全空白返回 BLANK
// ========================================

// ── This Period 时间区间 ──
VAR __PeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Min_This[TimeFrame_Min])
VAR __PeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

// ── 币种汇率与符号 ──
VAR __ExchangeRate = SELECTEDVALUE(Slicer_Currency_Selection[Currency_ExchangeRate], 1)
VAR __CurrencySymbol = SELECTEDVALUE(Slicer_Currency_Selection[Currency_Symbol], "¥")

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
                    VALUES('s02_trade_sku_data_d'[md_price]),
                    's02_trade_sku_data_d'[dt] = __MaxDt
                ),
                NOT ISBLANK('s02_trade_sku_data_d'[md_price])
            ),
            __CurrencySymbol & FORMAT(DIVIDE('s02_trade_sku_data_d'[md_price], __ExchangeRate), "#,##0"),
            "、",
            's02_trade_sku_data_d'[md_price], ASC
        )
    )
```

### 4.8 Top SKUs Predictive Buy（Predictive Buy 标签，属性列）

```dax
Top SKUs Predictive Buy =
// ========================================
// 度量值: Top SKUs Predictive Buy
// 中文名: Predictive Buy 标签（属性列）
// Display Folder: Top & OPP SKUs Analysis\Top\Attributes
// 用途: 当前行 category + sku_id 组合的 predictive_buy 最新值映射标签
//       （值区域展示列，指标化输出）——1 → "Y"、0 → "N"、其余为空
// 数据底表: s02_trade_sku_data_d
// 取值规则（§1.3）: 最新日期（This Period 区间内该组合的 MAX(dt)）当天
//       predictive_buy distinct 值中仅 1 / 0 参与映射（Y / N 顿号拼接，
//       sku 级属性以单值为主）；NULL 不参与；区间无记录 / 当天无
//       有效值返回 BLANK
// 类型口径（v1.1 实证确认）: predictive_buy 为整数类型（Nullable(Int32)，
//       值 1 / 0 / NULL）——比较使用整数字面量；禁止 String 比较
//       （"1" ≠ 1 恒不成立，会输出全空）
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
                    VALUES('s02_trade_sku_data_d'[predictive_buy]),
                    's02_trade_sku_data_d'[dt] = __MaxDt
                ),
                's02_trade_sku_data_d'[predictive_buy] = 1
                    || 's02_trade_sku_data_d'[predictive_buy] = 0
            ),
            SWITCH('s02_trade_sku_data_d'[predictive_buy], 1, "Y", 0, "N"),
            "、",
            's02_trade_sku_data_d'[predictive_buy], ASC
        )
    )
```

### 4.9 Top SKUs SLS Units Value（当期净销售数量）

```dax
Top SKUs SLS Units Value =
// ========================================
// 度量值: Top SKUs SLS Units Value
// 中文名: 当期净销售数量（DCom）
// Display Folder: Top & OPP SKUs Analysis\Top\Base Metrics
// 用途: 当前行 category + sku_id 组合 This Period 净销售数量（组合粒度全量）
// 依赖: Slicer_Time_Frame_Min_This[TimeFrame_Min] / Slicer_Time_Frame_Max_This[TimeFrame_Max]
// 口径: 口径 §41——时间范围看 this period；该 category + sku_id 分组下
//       sum(product_qty)
// 数据底表: s02_trade_sku_data_d
// 行维度传递: 行分组（category + sku_id 两列）筛选自动传导，无需分支
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

### 4.10 Top SKUs SLS Units Display（当期净销售数量显示）

```dax
Top SKUs SLS Units Display =
// ========================================
// 度量值: Top SKUs SLS Units Display
// 中文名: 当期净销售数量显示
// Display Folder: Top & OPP SKUs Analysis\Top\Formatting
// 用途: integer 格式化（千分位整数）；BLANK 显示 "-"
// 依赖: [Top SKUs SLS Units Value]
// 数据格式: #,##0（如 12,345）
// ========================================
    VAR __Value = [Top SKUs SLS Units Value]
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            FORMAT(__Value, "#,##0")
        )
```

### 4.11 Top SKUs EOH Value（期末库存数量）

```dax
Top SKUs EOH Value =
// ========================================
// 度量值: Top SKUs EOH Value
// 中文名: 期末库存数量
// Display Folder: Top & OPP SKUs Analysis\Top\Base Metrics
// 用途: 当前行 sku_id 期末库存数量（This 期末快照日单日时点）
// 依赖: Slicer_Time_Frame_Max_This[TimeFrame_Max]（end period 最后一天，直接单日过滤）
// 口径: 口径 §42——时间范围看 this period 最后一天（end period 最后一天 =
//       Max_This 表 TimeFrame_Max，直接单日过滤）；该 sku_id 下 sum(stock_inv_qty)
// 数据底表: s02_inventory_stock_sales_detail_d
// 行维度传递: 两表无模型关系——TREATAS(trade[sku_id] → inv[sku_id]) 单列
//       桥接（inv 唯一键 dt + sku_id，sku_id 单列即唯一锚定快照日单行，
//       无需 IF 分支）
// 渠道: inv 表无 platform / shop_name 字段，本指标不受渠道筛选影响
// 说明: 期末时点只取快照日单日，对区间求和会重复计数库存
// ========================================

// ── this period筛选 期末日期：end period 最后一天 = Max_This 表 TimeFrame_Max（直接单日过滤）──
VAR __EndPeriodDate_This = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

RETURN
    CALCULATE(
        SUM('s02_inventory_stock_sales_detail_d'[stock_inv_qty]),
        TREATAS(
            VALUES('s02_trade_sku_data_d'[sku_id]),
            's02_inventory_stock_sales_detail_d'[sku_id]
        ),
        's02_inventory_stock_sales_detail_d'[dt] = __EndPeriodDate_This
    )
```

### 4.12 Top SKUs EOH Display（期末库存数量显示）

```dax
Top SKUs EOH Display =
// ========================================
// 度量值: Top SKUs EOH Display
// 中文名: 期末库存数量显示
// Display Folder: Top & OPP SKUs Analysis\Top\Formatting
// 用途: integer 格式化（千分位整数）；BLANK 显示 "-"
// 依赖: [Top SKUs EOH Value]
// 数据格式: #,##0（如 45,678）
// ========================================
    VAR __Value = [Top SKUs EOH Value]
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            FORMAT(__Value, "#,##0")
        )
```

### 4.13 Top SKUs Weeks Cover Value（库存周转周数）

```dax
Top SKUs Weeks Cover Value =
// ========================================
// 度量值: Top SKUs Weeks Cover Value
// 中文名: 库存周转周数
// Display Folder: Top & OPP SKUs Analysis\Top\Base Metrics
// 用途: 当前行 sku_id 的库存周转周数（(期末库存 + 在途) / This Period 销售数量），
//       跨 trade + inv 双表
// 依赖: Slicer_Time_Frame_Min_This[TimeFrame_Min] / Slicer_Time_Frame_Max_This[TimeFrame_Max]
//       （销售侧区间）；Slicer_Time_Frame_Max_This[TimeFrame_Max]
//       （库存侧 end period 最后一天，直接单日过滤）
// 口径: 口径 §40——销售数量看 this period 区间 sum(product_qty)；库存相关看
//       end period 最后一天 sum(stock_inv_qty) + sum(in_trans_inv_qty)；
//       (库存 + 在途) / 销售数量（原始口径计算指标列分子分母写反，
//       以业务定义为准修正，同子模块七 §25 修正记录）
// 数据底表: s02_trade_sku_data_d（分母）；s02_inventory_stock_sales_detail_d（分子）
// 行维度传递: 分母行分组（category + sku_id）筛选自动传导；分子 TREATAS
//       sku_id 单列桥接（同 EOH Value，见 §4.11）
// 渠道: 分子不受渠道筛选影响（inv 无渠道字段）、分母受（trade 侧）——
//       渠道口径不对称为模型物理限制，业务需知悉
// 边界: 销售数量为 0 或 BLANK 时返回 BLANK（DIVIDE 拦截，避免失真周数）；
//       分子 BLANK（无 inv 记录）按 DIVIDE 语义记 0
// ========================================

// ── This Period 时间区间（销售侧分母）──
VAR __PeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Min_This[TimeFrame_Min])
VAR __PeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

// ── this period筛选 期末日期：end period 最后一天 = Max_This 表 TimeFrame_Max（直接单日过滤）──
VAR __EndPeriodDate_This = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

// ── 分子：期末库存 + 在途（快照日单日，TREATAS sku_id 单列桥接）──
VAR __InvUnits =
    CALCULATE(
        SUM('s02_inventory_stock_sales_detail_d'[stock_inv_qty])
            + SUM('s02_inventory_stock_sales_detail_d'[in_trans_inv_qty]),
        TREATAS(
            VALUES('s02_trade_sku_data_d'[sku_id]),
            's02_inventory_stock_sales_detail_d'[sku_id]
        ),
        's02_inventory_stock_sales_detail_d'[dt] = __EndPeriodDate_This
    )

// ── 分母：This Period 净销售数量（行分组筛选自动传导）──
VAR __SlsUnits =
    CALCULATE(
        SUM('s02_trade_sku_data_d'[product_qty]),
        's02_trade_sku_data_d'[dt] >= __PeriodMin,
        's02_trade_sku_data_d'[dt] <= __PeriodMax
    )

RETURN
    DIVIDE(__InvUnits, __SlsUnits)   // 分母 0 / BLANK → BLANK；分子 BLANK 按 DIVIDE 语义记 0
```

### 4.14 Top SKUs Weeks Cover Display（库存周转周数显示）

```dax
Top SKUs Weeks Cover Display =
// ========================================
// 度量值: Top SKUs Weeks Cover Display
// 中文名: 库存周转周数显示
// Display Folder: Top & OPP SKUs Analysis\Top\Formatting
// 用途: decimal_1dp 格式化（1 位小数，千分位）；BLANK 显示 "-"
// 依赖: [Top SKUs Weeks Cover Value]
// 数据格式: #,##0.0（如 12.3；口径 §40 原始口径未定义格式，按周数语义取 1 位小数）
// ========================================
    VAR __Value = [Top SKUs Weeks Cover Value]
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            FORMAT(__Value, "#,##0.0")
        )
```

---

## 5. 度量值清单

| #  | 度量值                              | 类型                             | 用于视觉对象                       |
| -- | ----------------------------------- | -------------------------------- | ---------------------------------- |
| 1  | Top SKUs SLS Amt Value / Display    | currency（隐藏排序依据）         | Top3 排名依据（默认隐藏，对数用）  |
| 2  | Top SKUs SKU Rank                   | RANK 窗口（两键决胜，名次唯一）  | 视觉级筛选器「介于 1 与 3」        |
| 3  | Top SKUs Sort Key                   | 排序键编码（类别 × 1e6 + 组内）  | 行排序依据（升序）                 |
| 4  | Top SKUs Product Photo              | trade 属性（最新日期拼接）       | 值区域（数据类别 = 图像 URL）      |
| 5  | Top SKUs Product Type               | trade 属性（最新日期拼接）       | 值区域                             |
| 6  | Top SKUs Price                      | trade 属性（最新日期值，currency）| 值区域                            |
| 7  | Top SKUs Predictive Buy             | trade 属性（最新日期值映射 Y/N） | 值区域                             |
| 8  | Top SKUs SLS Units Value / Display  | integer                          | 值区域                             |
| 9  | Top SKUs EOH Value / Display        | integer                          | 值区域                             |
| 10 | Top SKUs Weeks Cover Value / Display| decimal_1dp                      | 值区域                             |

- 全部度量值存放于 `_Measures` 隐藏表；Display Folder：`Top & OPP SKUs Analysis\Top\Rank`、`Top & OPP SKUs Analysis\Top\Base Metrics`、`Top & OPP SKUs Analysis\Top\Attributes`、`Top & OPP SKUs Analysis\Top\Formatting`
- 三个口径指标各 Value / Display 成对输出（6 个）；Rank / Sort Key 2 个；属性度量 4 个；SLS Amt Value / Display 2 个——合计 14 个度量值
- trade 侧指标与属性零分支（行分组筛选自动传导）；inv 侧指标 TREATAS sku_id 单列桥接（本模块仅 sku 粒度，无需 IF 分支）

---

## 6. 视觉对象配置

### 6.1 表格

| 配置项           | 内容                                                                                                                                        |
| ---------------- | ------------------------------------------------------------------------------------------------------------------------------------------- |
| 视觉对象类型     | 表格（平铺——category 与 sku_id 均为行字段，每行一个组合，无父行小计；总计行交由视觉对象默认生成，可按需关闭）                                |
| 字段井（行分组） | s02_trade_sku_data_d[category]、s02_trade_sku_data_d[sku_id]                                                                               |
| 视觉级筛选器 1   | Slicer_Framework[framework] = Foundation（前置筛选，经一对多关系自动传导双表）                                                              |
| 视觉级筛选器 2   | Top SKUs SKU Rank 介于 1 与 3（**含下界**——每个 category 分组保留组内 SLS Amt 前三）                                                       |
| 视觉级筛选器 3   | s02_trade_sku_data_d[category] 不为空（排除空白 category 组）                                                                               |
| 视觉级筛选器 4   | s02_trade_sku_data_d[sku_id] 不为空（双保险——空白主键若金额非空会进入排名占据名额）                                                        |
| 禁止配置         | 原生「前 N 个」列筛选器（全局 TopN，不按 category 分组）；「SKU Rank 小于或等于 3」（BLANK 视为 0 会放行空白 / 无金额行）                    |
| 行排序           | Top SKUs Sort Key 升序（列标题点击排序；Sort Key 列须留在值区域，收窄列宽）                                                                 |

值区域建议列序：

| 顺序 | 列                  | 度量                                                        |
| ---- | ------------------- | ----------------------------------------------------------- |
| 1    | 图片                | Top SKUs Product Photo（数据类别 = 图像 URL）               |
| 2    | 类型 / 价格 / 标签  | Top SKUs Product Type、Top SKUs Price、Top SKUs Predictive Buy |
| 3    | SLS Units           | Top SKUs SLS Units Display                                  |
| 4    | EOH                 | Top SKUs EOH Display                                        |
| 5    | Weeks Cover         | Top SKUs Weeks Cover Display                                |
| 6    | SLS Amt（隐藏）     | Top SKUs SLS Amt Display（默认隐藏或删除列，对数时拖入）    |
| 7    | SKU Rank（可选）    | Top SKUs SKU Rank（筛选器引用即可；拖入可核对组内排名）     |
| 8    | Sort Key（排序依据）| Top SKUs Sort Key（置于最后并收窄列宽）                     |

配置要点：

- **行分组双列**：category / sku_id 进字段井，其余字段全部经值区域度量输出——属性列不进字段井，避免行分组列增多后视觉级筛选器落地组合筛选更复杂
- **行排序绑定 Sort Key 列升序**：排序键全局唯一（两级两键决胜名次唯一），行序完全确定——category 块按 SLS Amt 降序、块内 sku 按金额降序
- **「介于 1 与 3」必须含下界**：BLANK 在数值筛选比较中视为 0（≤ 3 成立会放行、< 1 不满足被排除）
- **总计行不做特判**：交由表格视觉对象默认生成（总计行 category / sku_id 为 BLANK，Rank / Sort Key / 属性度量返回 BLANK，数值指标为全量聚合）；需总计 = 展示行之和时关闭总计行

### 6.2 切片器

| 切片器                                        | 类型             | 作用                                                                                                       |
| --------------------------------------------- | ---------------- | ---------------------------------------------------------------------------------------------------------- |
| Slicer_Time_Frame                             | 主时间筛选器     | 驱动 Min_This / Max_This 断开维度表，经 SELECTEDVALUE 读入度量值（属性字段"最新日期"判定同读此区间）       |
| Slicer_Framework                              | 一对多关系切片器 | 前置筛选 framework = 'Foundation' 经模型关系自动传导双表（本方案按视觉对象筛选器配置，DAX 不显式处理）      |
| Slicer_Platform_Selection / Slicer_Store_Name | 一对多关系切片器 | 经模型关系自动传导至 trade 侧（指标与 Top3 候选随渠道收窄）；inv 侧不受影响                                 |
| 其余商品维度切片器                            | 一对多关系切片器 | 与两张事实表已建关系的自动传导（候选金额与指标同口径收窄）                                                   |
| Slicer_Currency_Selection                     | 断开维度         | SLS Amt / Price 的汇率与符号来源；数量 / 周数类不受影响                                                     |

---

## 7. 验证方法

测试 SQL 本轮未要求输出，还原要点如下（可按需补 test_Top_SKUs_Analysis_Table.sql，字面量直嵌、按视觉对象单文件）：

| 指标 / 机制            | 测试 SQL 还原                                                                                                              |
| ---------------------- | -------------------------------------------------------------------------------------------------------------------------- |
| SLS Amt / SLS Units    | trade GROUP BY category, sku_id（net_sales_amt = ROUND(product_qty × sales_price, 6) 行级还原），WHERE framework = 'Foundation' AND dt ∈ This Period |
| SKU Rank               | DENSE_RANK() OVER (PARTITION BY category ORDER BY SUM(net_sales_amt) DESC, sku_id ASC)——两键决胜对齐；值域排除空白键与 NULL 金额行 |
| 类别排名 / Sort Key    | category 粒度金额 DENSE_RANK() OVER (ORDER BY category_amt DESC, category ASC)；sort_key = category_rank × 1000000 + sku_rank |
| Top3 行筛选            | 外层 WHERE sku_rank <= 3（每个 category 保留前三；NULL 排名行排除）                                                        |
| 属性四列               | (category, sku_id) 分组 MAX(dt) → 当天 distinct 值拼接；Predictive Buy CASE '1' → 'Y' / '0' → 'N' / 其余 NULL；Price 输出原始 CNY 值（换算与符号在 Display 层，不在 SQL 范围） |
| EOH / Weeks Cover 分子 | inv WHERE dt = 快照日 GROUP BY sku_id（framework 条件视与 inv 的模型关系对齐——有关系附加条件，无关系不附加）                |
| Weeks Cover            | (stock_inv_qty + in_trans_inv_qty) / product_qty；分母 0 / NULL → NULL；分子 NULL 按 0（DIVIDE 语义）                       |

- NULL 语义对齐 DAX：分子 NULL → 比率按 DIVIDE 语义（分子记 0 / 分母拦截整体 NULL）；属性字段区间无记录或当天全空白 → NULL（显示 "-"）
- 参数区（对齐同看板惯例）：framework = 'Foundation'、Platform / Store 全选（等价不筛选）、This Period dt ∈ ['2026-03-29', '2026-07-25']、快照日 '2026-07-25'
- 对数路径：PBI 表格行（category 块按金额降序 × 每块 3 行）vs SQL sku_rank <= 3 结果按 sort_key 升序逐列比对

---

## 8. 注意事项

1. **行分组为 category + sku_id 双列**：最终展示行 = 不重复的 category + sku_id 组合；全部指标按该组合粒度聚合（跨尺码 / 渠道明细汇总）；inv 桥接锚点仅需 sku_id 单列（inv 唯一键 dt + sku_id）
2. **属性字段全部指标化**：spu_img_url / product_type / md_price / predictive_buy 四个字段经值区域度量输出（§1.3 规则——This Period 区间内该组合最大 dt 当天 distinct 值拼接），不进字段井
3. **Top3 行筛选必须用「SKU Rank 介于 1 与 3」度量筛选器**：原生「前 N 个」列筛选器为全局 TopN（跨 category 取全表前 N），不按 category 分组；区间筛选必须含下界（BLANK 视为 0，「小于或等于 3」会放行空白 / 无金额行）
4. **RANK relation 用法（按度量值排名的唯一合法形式）**：RANK 省略 relation 时 ORDERBY 仅允许简单列引用——CALCULATE 等度量表达式作排序键报错"已省略 RANK 的关系参数，并且其 ORDERBY 子句包含非引用列表达式"；按度量值排名必须显式指定 relation（FILTER(CALCULATETABLE(ADDCOLUMNS(VALUES(分组列), @Amt)), ...)，两键决胜 [@Amt] DESC + 分组列 ASC，名次唯一）
5. **候选上下文净化（本方案关键防护）**：视觉级度量筛选器（Rank 介于 1 与 3）生效后落地为 (category, sku_id) 跨列组合筛选，单列 ALL / REMOVEFILTERS 无法清除——SKU Rank / Sort Key 的排名表必须在 `CALCULATETABLE(REMOVEFILTERS(两列) + TREATAS 重限分组)` 的净化上下文中整体求值（保留 framework / 渠道等外部筛选），否则候选与组合筛选冲突取 BLANK、名次失真（Top Size Sort Key 同源坑，已在度量内预防，禁止改回单列 ALL / 逐候选重建写法）
6. **候选集口径一致**：类别排名候选金额必须上卷到 category 粒度（CALCULATETABLE 净化上下文已移除 sku 筛选，@Amt 上下文转换仅叠加候选 category 筛选），否则候选金额被限制在当前行 sku 内、与对比值口径不一致，RANK 恒返回 1（Top Size Category Rank 同源坑）
7. **Sort Key 权重前提**：单个 category 内 sku 数 < 1,000,000（L2 组内排名不侵位 L1 类别排名）；两级名次唯一（两键决胜）→ 排序键全局唯一、行序完全确定
8. **predictive_buy 类型口径（v1.1 实证确认）**：字段为整数类型（Nullable(Int32)，值 1 / 0 / NULL），DAX 按整数字面量比较（1 → "Y"、0 → "N"、NULL 空）——禁止 String 比较（"1" ≠ 1 恒不成立会输出全空）
9. **inv 桥接为 TREATAS sku_id 单列**：本模块行粒度单一（category + sku_id，桥接锚点 sku_id），无需 Item Stockout 的 ISINSCOPE + IF 双分支；期末日期 = end period 最后一天，直接读 SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max]) 单日过滤（Max_This 表为断开维度，读值不随行上下文 / 切片器漂移）
10. **framework 前置筛选传导**：Slicer_Framework 与两张事实表一对多关联（framework 字段两表齐备，数据字典已核对），framework = 'Foundation' 经关系自动传导双表，DAX 不显式处理；期末日期直接读 Max_This 表 TimeFrame_Max（不依赖 inv 数据取值），单日过滤聚合内 inv 侧 framework 筛选照常生效（限定 Foundation 框架库存，属预期行为）
11. **渠道口径不对称**：Platform / Store 切片器经关系自动传导仅作用于 trade 侧（SLS 系列指标 + Top3 候选金额）；inv 表无渠道字段，库存侧指标（EOH / Weeks Cover 分子）全量口径——Weeks Cover 分子分母渠道不对称为模型物理限制，业务需知悉
12. **Weeks Cover 分子分母方向**：分子 = 期末库存 + 在途（快照日单日），分母 = This Period 销售数量——口径 §40 已确认修正项（原始口径计算指标列分子分母写反），不可回退
13. **net_sales_amt 列来源**：模型内为 Power Query 行级计算列（ROUND(product_qty × sales_price, 6)），数据库无此列——测试 SQL 验证时按行级乘积还原
14. **币种**：SLS Amt / Price 为 currency 类（Value 层 ÷ 汇率换算，Display 层拼符号）；Top3 排名与 Sort Key 使用原始 CNY 聚合（除以同一正汇率不改变相对顺序）；数量 / 周数 / 文本属性不涉及换算
15. **RANK / ORDERBY 版本要求**：Power BI Desktop 2022 年 9 月及以后版本
16. **总计行为**：总计行不做特判，交由表格视觉对象默认生成（总计行 category / sku_id 为 BLANK，Rank / Sort Key / 属性度量返回 BLANK，数值指标为全量聚合）；需总计 = 展示行之和时关闭总计行
17. **口径与语法**：口径文档中定义的所有指标必须遵守其数据类型与数据格式，与解决方案存在争议时一切以口径文档为准；DAX 文本常量使用双引号，单引号仅用于表名，列名使用方括号
18. **排名候选集必须收窄 + 批量物化（v2.0 性能修复，禁止回退）**：SKU Rank 排名表 = 净化上下文中 `SUMMARIZE` 一次分组查询物化（候选集天然 = 当前 category 在 dt 区间内有记录的 sku）——两层演进均不可回退：v1.0 全模型 `ALL(sku_id)` 值域（O(行组合数 × 全值域)，超时根因）；v1.1 值域收窄但 ADDCOLUMNS + 逐候选 CALCULATE 物化（O(R′ × K̄) 次上下文转换，SE 缓存无法消除 FE 转换开销，仍卡根因）；category / sku_id「不为空」列筛选器先行收窄查询行集，务必配置；当期无销售行组经 `__CurrentAmt` BLANK 短路（VAR 惰性求值，排名表不物化）
19. **复杂度与再优化路径**：度量筛选器架构下 Rank 对全部行组合求值为固有成本（当期有销售的 R′ 行组 × 每行 O(K) 名次匹配）——若 v2.0 仍卡：① RANK 改计数式排名（COUNTROWS(FILTER(排名表, 金额更高 || (金额相等且 sku 字母序更小))) + 1，两键决胜语义等价、免每次排序）② 建 (dt, category, sku_id) 粒度聚合表（PQ / 用户定义聚合，候选聚合命中小表，SE 常数骤降）③ 源侧预计算 Top3（失去切片器动态联动，需业务确认）；定位手段：性能分析器 → 复制 DAX 查询，查看 SE / FE 耗时占比（FE 占主导先走①，SE 占主导走②）
