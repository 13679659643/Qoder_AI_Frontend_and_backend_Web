# Top_SKUs_Analysis_Table 解决方案（Top 部分）

> **版本**: v2.6
> **模块**: RL E2E Merch Dashboard - Dimension Cross Analysis Tab - Top & OPP SKUs Analysis（Top 部分）
> **关联口径**: 口径文档/口径Markdown格式/Dimension Cross Analysis.md - 子模块九（§40 Weeks Cover / §41 SLS Units / §42 EOH + 模块说明属性列；§43~§49 为 OPP 部分指标，不在本方案范围，后续另行方案）
> **数据底表（销售/属性类）**: s02_trade_sku_data_d
> **数据底表（库存类）**: s02_inventory_stock_sales_detail_d
> **关联维度**: Slicer_Time_Frame_Min_This / Max_This（时间，断开维度）；Slicer_Framework（framework 一对多关系，前置筛选 'Foundation' 自动传导）；Slicer_Platform_Selection / Slicer_Store_Name（一对多关系自动传导，DAX 不显式处理）；Slicer_Currency_Selection（币种，断开维度）
> **筛选影响范围**: dt（断开维度，DAX 显式筛选）+ framework 前置筛选 + Platform / Store Name（模型关系自动传导）+ 其余与两张事实表已建关系的商品维度切片器
>
> **版本记录**:
> v2.6（2026-11-20）——属性度量零销售行兜底（业务确认）：五个属性度量（Product Photo / Product Type / Price / Predictive Buy / SPU ID）"最新日期"原仅取 This Period 区间内 MAX(dt)，区间无记录即 BLANK——Top 表行必有当期销售不受影响，但 OPP 表 v2.4 候选域修复后本期零销售 sku 可凭 EOH 前三展示（ST% = 0 恒低于均值天然过判定），此类行属性列全空（实测 Product Photo / Product Type / SPU ID 均空）；业务确认全部属性列统一加回退——区间内无记录时回退取该组合全历史 MAX(dt) 当天值（属性为慢变字段，取最近已知值），全历史也无记录 / 当天全空白仍 BLANK；改法 = __MaxDt 包 COALESCE（区间内 MAX(dt) 为空 → 全历史 MAX(dt)），度量名称与 Top 表行为零变化（回退分支对 Top 行永不触发）；五个属性度量同步修改，OPP 表经复用自动生效
> v2.5（2026-11-19）——v2.4 代码语法修正（用户实测报错"找不到名称 _SkuUnits"）：v2.4 内层 VAR 块（__SkuUnits 之后）漏写 RETURN 关键字直接接 IF——DAX 规则：表达式内 VAR 声明必须以 RETURN 结束才能接表达式，缺 RETURN 解析失败致 IDE 报名称未找到（IsSkuRow / ISBLANK / SkuUnits / BLANK 全线红波浪）；修正为扁平结构——else 分支内 VAR 全部声明（__PeriodMin / __PeriodMax / __IsSkuRow / __SkuUnits / __CatUnits）后统一一个 RETURN 接 IF 链（__CatUnits 惰性求值，短路时不计算）；逻辑零变化（v2.3 块序修复 + v2.4 空行防线语义均保持）
> v2.4（2026-11-19）——v2.3 空行副作用修复（用户实测反馈：产生大量空行，视觉筛选条件不变）：v2.3 修复块序时误删"sku 行当期无销售数量 → BLANK"内层拦截——无数量行得块键 -CatUnits×1e6+0 通过「Sort Key 不为空」筛选，其 Top Rank BLANK 在实际配置「小于或等于 3」中视为 0 亦放行（视觉实际配置为 ≤3 而非「介于 1 与 3」，该拦截 + Sort Key 不为空为空行双防线，此前一直生效）；修复：三类上下文分别处理——category 空白 → BLANK；分组头（sku 不在作用域）→ 类别块键（v2.3 保持）；sku 行且 SkuUnits BLANK → BLANK（恢复，禁止删除）；视觉对象筛选条件不变
> v2.3（2026-11-19）——Sort Key 分组表头排序缺陷修复（用户实测反馈：块内排序正确，category 块序未按数量降序——Dresses(2585) 排在 Outerwear(2774) 前）：根因非负号（块内升序 -2585000089 → -44 → -39 证明翻转生效），而是分组表格视觉对象对 category 块的排序取 Sort Key 在「仅 category 层级」的求值——该上下文 SELECTEDVALUE(sku_id) 为 BLANK，原空白拦截返回 BLANK → 全部块头排序键并列 → 块序回退 category 字母序；修复：sku_id 不在作用域（分组头）时返回类别块键 -(CatUnits × 1e6)（SkuUnits 记 0），块头升序 = 类别数量降序；sku 行仍返回完整键，块内排序不变
> v2.2（2026-11-19）——两项口径调整（业务确认）：① Top3 排名与行排序依据由 SLS Amt 改为 SLS Units（This Period sum(product_qty)，数量口径不涉及币种）——SKU Rank 组内排名、Sort Key 类别/块内编码全部换数量聚合；SLS Amt 度量保留作对数辅助（不再参与排名 / 排序）；排序结构不变（category 权重大靠前、块内 Top3 跟随）；新增知悉项：数量为整数聚合，同 category 内两 sku 数量完全相等时 Sort Key 相同、行序不定（金额口径下概率极低，数量口径下常见，并列行内容等价仅行间顺序）；② Weeks Cover 改数仓预计算 weeks_cover 字段直读（s02_inventory_stock_sales_detail_d 含该字段）：取所选时间范围 end period 最后一天（快照日单日）该 sku 的值，防御性 MAX(weeks_cover)（sku + day 不保证唯一行，单行时 MAX 退化为行值）；"(期末库存 + 在途) / This Period 销售数量"计算逻辑与 §40 修正史整体废止，度量名称不变（与 Item Stockout 模块 v2.6 同款调整）；行粒度 category + sku_id，桥接仍 TREATAS sku_id 单列
> v2.1（2026-10-26，用户改写）——SKU Rank 改 RANKX 迭代器模式（候选集 CALCULATETABLE(VALUES, REMOVEFILTERS(sku), category 等值, dt)，无中间表物化、SE 批量合并）；Sort Key 改金额编码（-(CatAmt × 1e6 + SkuAmt)，负号翻转，排序与排名解耦）；并列语义改 DENSE（金额并列共享名次，放行含并列）——权重前提单 SKU 金额 < 1e6，超限改 1e9/1e12
> v2.0（2026-10-26）——性能修复第二轮：SKU Rank 排名表物化改 SUMMARIZE 单次分组查询（CALCULATETABLE 净化上下文内，GROUP BY sku_id 一条 SE 查询物化全部候选），替代 v1.1 的 ADDCOLUMNS + 逐候选 CALCULATE（每候选一次上下文转换，R′×K̄ 次转换为仍卡根因——SE 缓存无法消除 FE 转换开销）；候选集收窄与净化机制保持
> v1.1（2026-10-26）——性能修复：SKU Rank / Sort Key 类别排名候选集由全模型值域（ALL）收窄为当前分组值域（CALCULATETABLE 净化上下文 + VALUES），消除视觉级度量筛选器下 O(行组合数 × 全值域) 的逐候选聚合（查询超时被取消的根因）；Predictive Buy 比较类型修正为整数字面量（用户实证字段为整数类型）
> v1.0（2026-10-26）——初版：每 category Top3 SKU 平铺表格（组内排名度量筛选器 + Sort Key 编码排序）

---

## 1. 需求理解

### 1.1 模块定位与视觉对象结构

Top & OPP SKUs Analysis 板块含 TOP 与 OPP 两部分（口径板块级商品维度切换 TOP / OPP，经页面按钮 + 书签切换显隐，不在本方案度量值范围）。本方案仅覆盖 **TOP 部分**：单张平铺表格，前置筛选 framework = 'Foundation'，行 = category + sku_id 组合，每个 category 分组下按 SLS Units 降序取 Top3 SKU（v2.2 由 SLS Amt 改为 SLS Units）：

| 配置项           | 内容                                                                                          |
| ---------------- | --------------------------------------------------------------------------------------------- |
| 视觉对象类型     | 表格（平铺，无层级无小计，总计行交由视觉对象默认生成）                                        |
| 字段井（行分组） | s02_trade_sku_data_d[category]、s02_trade_sku_data_d[sku_id]（两列行分组——每行一个组合）      |
| 值区域（属性列） | Product Photo / Product Type / Price / Predictive Buy（度量，见 §1.3）                        |
| 值区域（指标列） | SLS Units / EOH / Weeks Cover Display + Sort Key（行排序依据）+ SLS Amt（对数辅助，默认隐藏——v2.2 起不再参与排名 / 排序） |
| 视觉级筛选器     | Slicer_Framework[framework] = 'Foundation'（前置）+ Top SKUs SKU Rank 介于 1 与 3 + 空白键排除 |
| 行排序           | Top SKUs Sort Key 升序（category 块按 SLS Units 降序 + 组内 sku 按数量降序，v2.2 基准改数量）      |

- **指标计算粒度**：全部指标按当前行 category + sku_id 组合聚合——行分组双列筛选自动落在 trade 表对应列上，聚合范围 = 该组合下全部记录（跨尺码 / 渠道明细汇总）
- **inv 侧显式桥接**：两张事实表之间无模型关系，sku_id 行筛选对库存类指标不自动传递，经 DAX TREATAS sku_id 单列显式桥接（见 §3.4）
- **Top3 行筛选**：每个 category 分组内按 This Period SLS Units 降序保留前三（v2.2 由金额改数量），由视觉级「SKU Rank 介于 1 与 3」度量筛选器实现（见 §3.2）
- **framework 前置筛选**：Slicer_Framework 与两张事实表一对多关联（framework 字段两表齐备，数据字典已核对），视觉对象筛选器 framework = 'Foundation' 经模型关系自动传导，DAX 不显式处理

### 1.2 指标清单

| 序号 | 指标            | 口径章节   | 时间口径               | 计算公式                                                                                                        | 数据类型 / 格式                     |
| ---- | --------------- | ---------- | ---------------------- | --------------------------------------------------------------------------------------------------------------- | ----------------------------------- |
| 1    | SLS Amt（对数辅助） | 需求补充   | This Period（区间）    | 该 category + sku_id 分组下 sum(net_sales_amt)——v2.2 起不再参与排名 / 排序（依据改 SLS Units），保留对数辅助，视觉对象默认隐藏                          | currency → 币种符号 + `#,##0`      |
| 2    | SKU Rank        | 需求补充   | This Period（区间）    | category 组内按 SLS Units（sum(product_qty)）降序排名（RANKX DENSE 并列同名次，「介于 1 与 3」放行含并列），用于 Top3 筛选（v2.2 由金额改数量）             | integer → `#,##0`                  |
| 3    | Sort Key        | 需求补充   | This Period（区间）    | 排序键 = -(category SLS Units × 1,000,000 + sku SLS Units)——负号翻转，表格升序 = category 块按数量降序 + 块内 sku 按数量降序（见 §3.3）                                                    | integer → `#,##0`                  |
| 4    | Product Photo   | 属性列     | 最新日期（This 内）    | spu_img_url 最新日期值（§1.3 规则）                                                                             | 文本（数据类别 = 图像 URL）         |
| 5    | Product Type    | 属性列     | 最新日期（This 内）    | product_type 最新日期值（§1.3 规则）                                                                            | 文本                                |
| 6    | Price           | 属性列     | 最新日期（This 内）    | md_price 最新日期值（§1.3 规则，币种换算 + 格式化）                                                             | currency → 币种符号 + `#,##0`      |
| 7    | Predictive Buy  | 属性列     | 最新日期（This 内）    | predictive_buy 最新日期值映射：1 → "Y"、0 → "N"、其余为空（§1.3 规则）                                             | 文本枚举（Y / N）                   |
| 8    | Weeks Cover     | §40        | End Period（期末时点） | 数仓预计算 weeks_cover 字段直读（v2.2 调整，与 Item Stockout 模块 v2.6 同款）：取 end period 最后一天（快照日单日）该 sku 的值，防御性 MAX(weeks_cover)（sku + day 不保证唯一行，单行时 MAX 退化为行值） | decimal_1dp → `#,##0.0`          |
| 9    | SLS Units       | §41        | This Period（区间）    | 该 category + sku_id 分组下 sum(product_qty)                                                                    | integer → `#,##0`                  |
| 10   | EOH             | §42        | End Period（期末时点） | 该 sku_id 下 sum(stock_inv_qty)（快照日单日）                                                                   | integer → `#,##0`                  |

### 1.3 属性字段取值规则

四个属性字段全部按指标逻辑处理（单度量输出，规则统一，取值模式与 Item Stockout 模块 §1.3 一致）：

- **取值范围** = This Period 时间区间（[TimeFrame_Min, TimeFrame_Max]）+ 当前行 category + sku_id 分组筛选 + 外部切片器（framework / Platform / Store 等，自动传导）下的全部记录
- **"最新"定义**：范围内该 category + sku_id 组合的最大 dt（`MAX(trade[dt])`）——用户选定时间段内最后一次出现记录的日期
- **零销售回退（v2.6）**：区间内无记录（最大 dt 为 BLANK）时回退取该组合**全历史 MAX(dt)** 当天值——属性为 sku 级慢变字段，取最近已知值；触发场景为 OPP 表零销售行（Top 表行必有当期销售，回退分支永不触发）；全历史也无记录 / 回退日当天该字段全空白仍返回 BLANK
- **取值**：最大 dt 那天的该字段 distinct 值，按升序顿号（、）拼接——trade 表为 sku 粒度，同一组合同日多行为常态（不同订单 / 店铺）；product_type / md_price / spu_img_url / predictive_buy 为 sku 级属性，拼接自然退化为单值
- **Price 特殊**：md_price 为 CNY 单价，逐个值 ÷ Currency_ExchangeRate 换算 + 币种符号 + `#,##0` 格式化后拼接（md_price 为 0 的行展示 ¥0，NULL 行排除）
- **Predictive Buy 特殊**：predictive_buy 为整数类型（Nullable(Int32)，v1.1 实证确认），值包括 1 / 0 / NULL——最新日期当天仅 1 / 0 参与映射（1 → "Y"、0 → "N"），NULL 不参与，全部为空时返回 BLANK
- 示例：某 category + sku_id 组合在 this period 区间内最后记录日为 2026-07-20，当天该 sku 有 3 行记录，product_type 均为 T-shirt → Product Type 列显示 "T-shirt"

### 1.4 时间口径

| 口径                     | 时间范围                                                                                                                                  | 适用指标                                                        |
| ------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------- |
| This Period（区间类）    | dt ∈ [Slicer_Time_Frame_Min_This[TimeFrame_Min], Slicer_Time_Frame_Max_This[TimeFrame_Max]]                                              | SLS Amt（对数辅助）、SLS Units、Top3 排名数量（v2.2）、属性"最新日期"判定 |
| End Period（期末时点类） | end period 最后一天 = Slicer_Time_Frame_Max_This[TimeFrame_Max]（直接单日过滤） | EOH、Weeks Cover（weeks_cover 字段直读）                       |

说明：

- 两张 s02 表日期字段均为 dt（非 data_date）
- 期末时点为 end period 最后一天（Max_This 表 TimeFrame_Max，直接单日过滤），与口径描述一致；快照表按日存储，期末时点只取单日，对整段区间求和会把库存重复计数；该日快照缺数时指标为空，不回退取范围内最近一天
- 属性字段的"最新日期"以 This Period 区间内该组合的实际最大 dt 为准（非 TimeFrame_Max——组合在该区间内的最后记录日）

### 1.5 币种口径

- SLS Amt / Price 为 currency 类：货币符号由币种切片器（Slicer_Currency_Selection）决定，千分位整数；数据底表金额仅存储 CNY，Value 层完成汇率换算（原始值 ÷ Currency_ExchangeRate，RMB 汇率 = 1 时换算前后值相同）
- 数量 / 周数类指标与文本属性不涉及币种换算
- **Top3 排名与 Sort Key 使用 SLS Units 数量口径**（v2.2 由 SLS Amt 改——This Period sum(product_qty)，整数聚合），不涉及币种换算

### 1.6 Top3 行筛选与行排序机制

- **排名依据**：SLS Units——该 category + sku_id 分组 This Period `sum(product_qty)`（数量口径，v2.2 由 SLS Amt 改）降序
- **组内排名（Top SKUs SKU Rank）**：category 组内按 SLS Units 降序（RANKX DENSE——数量相同的 sku 并列同名次，「介于 1 与 3」放行含并列行）；数量为整数聚合，并列概率高于金额口径，属预期行为
- **类别排名**：category 粒度（该 category 全部 sku 汇总 SLS Units）按数量降序，决定 category 块先后（权重大的 category 靠前）
- **Sort Key 编码**：-(category SLS Units × 1,000,000 + sku SLS Units)——负号翻转，表格按此键升序排序，行序 = category 块按数量降序、块内 sku 按数量降序（编码详见 §3.3；同 category 内两 sku 数量完全相等时排序键相同、行序不定——见 §8 注意事项 7）
- **Top3 行筛选**：视觉级「Top SKUs SKU Rank 介于 1 与 3」度量筛选器（含下界）——原生「前 N 个」列筛选器为**全局** TopN（跨 category 取全表前 N），无法实现按 category 分组取 Top3，故必须用组内排名度量筛选器
- **BLANK 防护**：Rank 对空白 category / sku_id / 当期无金额行返回 BLANK；数值筛选中 BLANK 视为 0，「介于 1 与 3」的下界将其排除（「小于或等于 3」会放行 BLANK 行，禁止使用）
- **候选上下文净化（关键）**：视觉级度量筛选器生效后落地为 (category, sku_id) 跨列组合筛选，单列 ALL / REMOVEFILTERS 无法清除，会污染候选迭代（候选与组合筛选冲突取 BLANK、名次失真）——排名候选集统一在 `CALCULATETABLE(REMOVEFILTERS(category, sku_id 两列) + TREATAS 重限分组)` 的净化上下文中求值（保留 framework / 渠道等外部筛选），筛选求值与显示求值两阶段语义一致
- **排名求值复杂度（v2.0）**：视觉级度量筛选器迫使引擎对**全部 (category, sku_id) 行组合**（非仅显示行）求值 Rank——当期无销售的行组经 `__CurrentUnits` BLANK 短路（VAR 惰性求值，仅一次聚合），当期有销售的 R′ 个行组各物化一次本 category 排名表；v1.1 的 ADDCOLUMNS + 逐候选 CALCULATE 为 O(R′ × K̄) 次上下文转换（K̄ = 平均每类 sku 数；R′=3 万、K̄=1000 即 3000 万次，仍卡根因），v2.0 改 SUMMARIZE 单次分组查询（每类别一条 SE 查询、跨行缓存），FE 仅余每行 O(K) 名次匹配——候选集仍限定当前 category 值域（v1.1 收窄保持）

### 1.7 渠道与 framework 上下文

- Slicer_Framework 与 s02_trade_sku_data_d / s02_inventory_stock_sales_detail_d 均为一对多关联（framework 字段两表齐备）：前置筛选 framework = 'Foundation' 经模型关系自动传导双表，DAX 不显式处理——trade 侧指标、属性取值与 Top3 候选金额均限定 Foundation 框架内
- Slicer_Platform_Selection / Slicer_Store_Name 与 trade 表一对多关联，筛选经模型关系自动传导（trade 侧指标与 Top3 候选随渠道收窄，DAX 不显式处理）
- inv 表无 platform / shop_name 字段：库存侧指标（EOH / Weeks Cover）不受渠道筛选影响——trade 侧受筛选、inv 侧全量的口径不对称为模型物理限制（业务需知悉）；Weeks Cover v2.2 起整体取数 inv 侧 weeks_cover 字段，不再存在分子分母渠道不对称；framework 筛选若与 inv 建立关系则直接传导，否则经 sku_id 桥接间接限定（传入 sku 集合已在 trade 侧含 framework 筛选）

---

## 2. 现状分析

- 数据底表 `s02_trade_sku_data_d`（SKU 粒度交易表，dt 日粒度）：net_sales_amt 为 Power Query 取数新增列（行级 `ROUND(product_qty * sales_price, 6)` 生成，模型内存在，数据库无此列——测试 SQL 验证时按行级乘积还原）；category / sku_id / spu_img_url / product_type / md_price / framework 字段齐备（已逐一核对数据字典）；predictive_buy 为 Nullable(Int32) 整数类型（v1.1 用户实证确认，值 1 / 0 / NULL，见注意事项 8）；同一组合同日多行为常态（不同订单 / 店铺）
- 数据底表 `s02_inventory_stock_sales_detail_d`（库存+销售+补货 SKU 模型表，dt 日快照，唯一键 dt + sku_id）：stock_inv_qty（在库库存，EOH 口径）、in_trans_inv_qty（在途库存）、weeks_cover（数仓预计算库存周转周数，v2.2 Weeks Cover 直读字段）、framework 字段齐备（已逐一核对数据字典）；**无 platform / shop_name 字段**（渠道筛选不影响库存侧）
- 两张事实表之间无模型关系：sku_id 行筛选向库存类指标的传递经 DAX TREATAS 单列显式桥接（本模块行粒度为 category + sku_id，桥接锚点仅需 sku_id 单列）
- 日期筛选器（Min_This / Max_This）为断开维度，时间范围在 DAX 中显式筛选
- Slicer_Platform_Selection / Slicer_Store_Name / Slicer_Framework 及其余商品维度切片器与事实表一对多关联，筛选自动传导，DAX 无需显式处理；Slicer_Currency_Selection 为断开维度，汇率与符号经 SELECTEDVALUE 读取

---

## 3. 方案设计

### 3.1 度量值分层

```
Rank / Sort Key（Top3 行筛选 + 行排序，2 个度量）
←  SKU Rank：category 组内 SLS Units 降序（RANKX DENSE 并列同名次，
      「介于 1 与 3」放行含并列——v2.2 由金额改数量）
←  Sort Key：-(category SLS Units × 1e6 + sku SLS Units)
      （负号翻转升序实现降序，category 块按数量降序）
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
| Top SKUs SKU Rank               | 度量筛选器 | 介于 1 与 3       | **行筛选主力**——每个 category 分组保留组内 SLS Units 前三的 sku；含下界排除 BLANK 行（空白键 / 当期无销售数量） |
| s02_trade_sku_data_d[category]  | 列筛选器   | 不为空            | 排除空白 category 组（文本列 NULL 与空字符均归 (Blank) 组被排除）                                            |
| s02_trade_sku_data_d[sku_id]    | 列筛选器   | 不为空            | 双保险——Rank 对空白 sku 已返回 BLANK 被区间筛选排除，此条防边界（空白主键若金额非空会进入排名占据名额）    |

机制说明：

- **必须用组内排名度量筛选器**：原生「前 N 个」列筛选器为全局 TopN（对全部 sku_id 按度量排序取全表前 N），不按 category 分组——本场景"每个 category 取 Top3"只有组内排名 + 区间筛选可实现（与 Item Stockout 全局 Top 100 用原生 TopN 列筛选器的场景本质不同）
- **「介于 1 与 3」必须含下界**：Rank 度量对空白 / 当期无金额行返回 BLANK，数值筛选比较中 BLANK 视为 0——「小于或等于 3」成立（0 ≤ 3）会放行 BLANK 行，「介于 1 与 3」的下界（0 < 1 不满足）将其排除
- **性能结构（v2.0 修复）**：度量筛选器需对全部 category + sku_id 行组合逐组求值 Rank 后决定保留行——当期无销售行组经 `__CurrentUnits` BLANK 短路（VAR 惰性求值，排名表不物化）；当期有销售的 R′ 个行组各物化一次本 category 排名表：v1.0 用 `ALL(sku_id)` 全模型值域（O(行组合数 × 全值域)，超时根因）；v1.1 收窄为当前 category 值域但物化用 ADDCOLUMNS + 逐候选 CALCULATE（每候选一次上下文转换，O(R′ × K̄) 次转换，仍卡根因——SE 查询可被缓存，FE 逐候选上下文转换无法被缓存消除）；v2.0 改 SUMMARIZE 在净化上下文中一次分组查询物化全部候选金额（每类别一条 SE 查询，同 category 各行共享缓存），FE 仅余每行 O(K) 名次匹配；category / sku_id「不为空」列筛选器先行收窄查询行集，务必配置
- **Rank 仅决定行去留**：行序由 Sort Key 承担（Sort Key 在筛选落地后的显示上下文中求值，候选集净化保证其为全局真实排名，见 §3.3）

### 3.3 Sort Key 排序键编码

表格视觉对象仅支持单键排序，两级行排序规则通过排序键度量编码为一个整数，表格按该键升序排序：

| 层级        | 规则                                                                              | 编码贡献           |
| ----------- | --------------------------------------------------------------------------------- | ------------------ |
| L1 类别块序 | category 粒度 This Period sum(product_qty) 降序（数量大的 category 块在前）        | -(CatUnits × 1,000,000) |
| L2 块内序   | category 内 sku 按 This Period sum(product_qty) 降序（数量大的 sku 在前）          | -(SkuUnits × 1)        |

排序键 = L1 + L2，升序排序后行序为：category 块按当期净销售数量降序排列（销售数量最大的 category 在最前），每个块内 sku 按数量降序。

示例（数量故意错开，展示两级分工）：

| category | category SLS Units | sku_id | sku SLS Units | Sort Key      |
| -------- | ------------------ | ------ | ------------- | ------------- |
| Knit     | 900                | SKU-A  | 500           | -900,000,500  |
| Knit     | 900                | SKU-C  | 300           | -900,000,300  |
| Knit     | 900                | SKU-B  | 100           | -900,000,100  |
| Belts    | 150                | SKU-D  | 90            | -150,000,090  |
| Belts    | 150                | SKU-E  | 40            | -150,000,040  |
| Belts    | 150                | SKU-F  | 20            | -150,000,020  |

- **权重前提**：单个 SKU 的 SLS Units < 1,000,000（L2 不侵位 L1）；数量可能超限时改用 1,000,000,000（编码结构不变，仅放大权重）
- **排序键并列（v2.2 需知悉）**：SLS Units 为整数聚合，同 category 内两 sku 数量完全相等时排序键相同，两者行序由视觉对象内部顺序决定（不定）——金额口径下完全相等概率极低，数量口径下常见；并列行仅行间顺序不定，块归属与块序不受影响，业务可接受
- **类别块序为全局真实序**：候选集经净化（REMOVEFILTERS sku 列 + category 筛选保留），不受视觉级 Top3 筛选器落地的组合筛选影响——Top3 只决定行去留，不改变 category 全量数量与块序
- **分组表头排序（v2.3 修复，务必知悉）**：分组表格视觉对象（category 跨行合并）对 category 块的排序取 Sort Key 在「仅 category 层级」的求值——sku_id 不在作用域时度量返回类别块键 -(CatUnits × 1,000,000)（SkuUnits 记 0），块头升序 = 类别数量降序；若该上下文返回 BLANK（v2.2 及以前的空白拦截写法），全部块头排序键并列，块序回退 category 字母序（实测 Dresses(2585) 排在 Outerwear(2774) 前的根因）——**禁止恢复"sku_id 空白即返回 BLANK"的拦截写法**
- 排序基于 SLS Units 数量聚合（不涉及币种——数量无币种换算）

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
// 用途: 当前行 category + sku_id 组合 This Period 净销售金额——v2.2 起 Top3
//       排名与 Sort Key 排序依据改 SLS Units，本度量保留作对数辅助
//       （视觉对象中默认隐藏，对数时可拖入验证）
// 依赖: Slicer_Time_Frame_Min_This[TimeFrame_Min] / Slicer_Time_Frame_Max_This[TimeFrame_Max]
//       Slicer_Currency_Selection[Currency_ExchangeRate]
// 口径: 时间范围看 this period；该 category + sku_id 分组下 sum(net_sales_amt)
//       （组合粒度全量——跨尺码 / 渠道明细汇总）
// 数据底表: s02_trade_sku_data_d
// 行维度传递: 行分组（category + sku_id 两列）筛选自动落在 trade 表对应列上，
//       聚合自动限定当前行组合，无需分支
// 排名口径: v2.2 起排名 / 排序依据为 SLS Units（sum(product_qty)），本度量
//       不再参与排名 / 排序；输出换算后金额仅供展示对数
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
// 用途: 当前行 sku_id 在其 category 分组内按 This Period sum(product_qty)
//       （SLS Units，v2.2 由金额改数量）降序的排名，用于视觉级筛选器
//       「介于 1 与 3」实现每个 category 分组仅保留 SLS Units 前三的 SKU
// 依赖: Slicer_Time_Frame_Min_This[TimeFrame_Min] / Slicer_Time_Frame_Max_This[TimeFrame_Max]
// 口径: framework + 渠道与其余商品维度切片器筛选组合下，category 组内按
//       sku_id 粒度 This Period sum(product_qty) 降序排名
// 排名语义: 数量降序；数量相同的 sku 并列同名次（DENSE），
//       「介于 1 与 3」放行名次 ≤ 3 的所有行（含并列——数量为整数聚合，
//       并列概率高于金额口径，属预期行为）
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
// 空白/无数量拦截: 当前行 category / sku_id 空白或当期无销售数量时返回 BLANK
//       （「介于 1 与 3」将 BLANK 视为 0 排除在区间外）
// 排名数量: SLS Units 聚合（sum(product_qty)），不涉及币种换算
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

// ── 当前行组合的 This Period 净销售数量（SLS Units）──
// 行筛选（单列或组合形式）均定义当前行自身，直接聚合即可；无数量返回 BLANK
VAR __CurrentUnits =
    CALCULATE(
        SUM( 's02_trade_sku_data_d'[product_qty] ),
        's02_trade_sku_data_d'[dt] >= __PeriodMin,
        's02_trade_sku_data_d'[dt] <= __PeriodMax
    )

RETURN
IF(
    // ── 短路：category / sku_id / 金额任一为空直接退出 ──
    NOT ISBLANK( __CurrentCategory )
        && NOT ISBLANK( __CurrentSkuId )
        && NOT ISBLANK( __CurrentUnits ),

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
    //   对每个候选 sku 求 This Period sum(product_qty)
    //   RANKX 迭代时自动将候选 sku 注入行上下文，
    //   CALCULATE 上下文转换叠加候选 sku 筛选 + 时间条件
    //
    // 参数 3 - 当前行值:
    //   __CurrentUnits（已预计算，避免重复聚合）
    //
    // 参数 4/5 - 排序方向 / 并列处理:
    //   DESC = 数量降序（数量最大 = 第 1 名）
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
            SUM( 's02_trade_sku_data_d'[product_qty] ),
            's02_trade_sku_data_d'[dt] >= __PeriodMin,
            's02_trade_sku_data_d'[dt] <= __PeriodMax
        ),
        __CurrentUnits,
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
// 用途: 表格行排序依据——category 块按 This Period SLS Units 降序
//       （销售数量最大的 category 在最前），块内 sku 按数量降序（v2.2
//       由金额改数量）；表格按此度量值「升序」排列（负号翻转实现降序效果）
// 依赖: Slicer_Time_Frame_Min_This[TimeFrame_Min] / Slicer_Time_Frame_Max_This[TimeFrame_Max]
// 核心思路: 排序不需要排名，数量本身就是顺序
//       排序键 = -(category 总数量 × 1,000,000 + SKU 数量)
//       负号使数量越大 → 值越小 → 升序排列时越靠前
// 编码: L1 = category 总数量 × 1,000,000（保证 category 块间不交叉）
//       L2 = SKU 数量 × 1（块内排序）
//       权重前提：单个 SKU 的 SLS Units < 1,000,000
//       若数量可能超过，改用 1,000,000,000
// 负值处理: 负号统一翻转，正负值均正确排序（product_qty 理论恒 ≥ 0，
//       防御性保留）
//       例：CatUnits=100, SkuUnits=80 → -(100×10⁶+80) = -100,000,080
//           CatUnits=100, SkuUnits=50 → -(100×10⁶+50) = -100,000,050
//           升序：-100,000,080 < -100,000,050 → SkuUnits=80 排前面 ✓
// 分组表头排序（v2.3 修复，关键）: 分组表格视觉对象（category 跨行合并）
//       对 category 块的排序 = Sort Key 在「仅 category 层级」上下文求值——
//       该上下文 sku_id 不在作用域（SELECTEDVALUE(sku_id) 为 BLANK）；
//       若此时返回 BLANK，全部块头排序键并列 → 块序回退 category 字母序
//       （实测：Dresses(2585) 排在 Outerwear(2774) 前，与数量无关）；
//       修复：sku_id 不在作用域时 SkuUnits 记 0，返回类别块键
//       -(CatUnits × 1,000,000)——块头升序 = 类别数量降序，块内行键不变
// 性能: 无需 RANKX / RANK，仅两次 CALCULATE SUM（SE 层直接聚合）
//       单次调用 O(r)，总复杂度 O(C × S × r) = O(N)
//       相比排名方案（O(C×S×(C×r + S×r))）快 50-100 倍
// 空白拦截（v2.4 修正）: 三类上下文分别处理——
//       ① category 空白（总计行 / 空白组）→ BLANK
//       ② 分组表头（sku_id 不在作用域）→ 返回类别块键 -(CatUnits × 1e6)
//         参与块排序（v2.3 修复，禁止回退）
//       ③ sku 行但当期无销售数量（SkuUnits BLANK）→ BLANK（v2.3 曾误删该
//         拦截导致空行混入：无数量行得块键 -CatUnits×1e6+0，通过
//         「Sort Key 不为空」，其 Rank BLANK 在「小于或等于 3」中视为 0
//         亦放行——实测空行根因；该拦截为空行防线，禁止删除）
// 排序数量: SLS Units 聚合（sum(product_qty)），不涉及币种换算
// 与 [Top SKUs SKU Rank] 的关系:
//       排序用本度量值（数量编码，快）
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
    // ── 短路 ①：category 空白或空字符串直接退出（总计行 / 空白组）──
    ISBLANK( __CurrentCategory )
        || LEN( TRIM( __CurrentCategory ) ) = 0,
    BLANK(),

    // ── ②③ sku 行 / 分组表头：VAR 全部声明后统一 RETURN（v2.5 语法修正，
    //    禁止 VAR 后直接接 IF——DAX 规则：表达式内 VAR 块必须以 RETURN 结束，
    //    v2.4 内层 VAR 漏 RETURN 导致 PBI 报"找不到名称 __SkuUnits"）──
    VAR __PeriodMin = SELECTEDVALUE( Slicer_Time_Frame_Min_This[TimeFrame_Min] )
    VAR __PeriodMax = SELECTEDVALUE( Slicer_Time_Frame_Max_This[TimeFrame_Max] )

    // ── 当前行是否 sku 行（分组表头上下文 sku_id 不在作用域）──
    VAR __IsSkuRow =
        NOT ISBLANK( __CurrentSkuId )
            && LEN( TRIM( __CurrentSkuId ) ) > 0

    // ── 当前行 SKU 数量（SLS Units；sku 行正常聚合，分组头取 0）──
    // 分组表头 → SkuUnits = 0 → 排序键退化为 -(CatUnits × 1e6) 类别块键，
    // 块头升序 = 类别数量降序（v2.3 修复）
    VAR __SkuUnits =
        IF(
            __IsSkuRow,
            CALCULATE(
                SUM( 's02_trade_sku_data_d'[product_qty] ),
                's02_trade_sku_data_d'[dt] >= __PeriodMin,
                's02_trade_sku_data_d'[dt] <= __PeriodMax
            ),
            0
        )

    // ── Category 总数量（上卷到 category 粒度；VAR 惰性求值，短路时不计算）──
    // REMOVEFILTERS(sku_id) 清除当前行 sku 筛选 → 自动上卷
    // 当前行的 category 筛选天然保留（无需额外 TREATAS）
    // 外部筛选（framework / 渠道等）自然保留
    // 视觉级组合筛选中的 sku 部分被 REMOVEFILTERS 清除，
    // category 部分由当前行上下文保留 → 候选净化完成
    // 分组表头上下文：category 筛选保留，sku 筛选本就不存在 → 同样正确上卷
    VAR __CatUnits =
        CALCULATE(
            SUM( 's02_trade_sku_data_d'[product_qty] ),
            REMOVEFILTERS( 's02_trade_sku_data_d'[sku_id] ),
            's02_trade_sku_data_d'[dt] >= __PeriodMin,
            's02_trade_sku_data_d'[dt] <= __PeriodMax
        )

    RETURN
    IF(
        // ── 短路 ③（v2.4 恢复，空行防线，禁止删除）──
        // sku 行但当期无销售数量（SkuUnits BLANK）→ BLANK：
        // 该类行 Top Rank 为 BLANK，数值筛选「小于或等于 3」中 BLANK 视为 0
        // 会放行（视觉实际配置为 ≤3 而非「介于 1 与 3」）——此前一直依赖
        // 本拦截 + 「Sort Key 不为空」筛选将其排除；v2.3 误删后无数量行
        // 得块键 -CatUnits×1e6+0 通过两道筛选混入空行（实测根因）
        __IsSkuRow && ISBLANK( __SkuUnits ),
        BLANK(),

        // ── 排序键 = -(category 数量 × 权重 + SKU 数量) ──
        // 负号翻转：表格按此列「升序」排列 = 实际数量降序效果
        // 权重 1,000,000 保证 category 块间不交叉
        // （前提：单 SKU 的 SLS Units < 1,000,000）
        // 分组表头：__SkuUnits = 0 → 类别块键，块头升序 = 类别数量降序
        IF(
            NOT ISBLANK( __CatUnits ),
            -( __CatUnits * 1000000 + __SkuUnits )
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
//       主，拼接自然退化单值）；区间无记录回退全历史最新 dt（v2.6 零销售行兜底）；全历史无记录 / 当天全空白返回 BLANK
// 行维度传递: 行分组（category + sku_id 两列）筛选自动限定取值范围，
//       framework / 渠道等外部切片器自动传导
// 配置: 度量工具 → 数据类别 → 图像 URL；值区域列显示商品图片
// ========================================

// ── This Period 时间区间 ──
VAR __PeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Min_This[TimeFrame_Min])
VAR __PeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

// ── 最新日期：该组合在区间内的最大 dt ──
// ── 最新日期：区间内最大 dt；无记录回退全历史最大 dt（v2.6 零销售行兜底）──
// OPP 表零销售行（本期无 trade 记录但 EOH 进前三）凭回退展示最近已知属性；
// Top 表行必有当期销售，回退分支永不触发
VAR __MaxDt =
    COALESCE(
        CALCULATE(
            MAX('s02_trade_sku_data_d'[dt]),
            's02_trade_sku_data_d'[dt] >= __PeriodMin,
            's02_trade_sku_data_d'[dt] <= __PeriodMax
        ),
        CALCULATE(MAX('s02_trade_sku_data_d'[dt]))
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
// ── 最新日期：区间内最大 dt；无记录回退全历史最大 dt（v2.6 零销售行兜底）──
// OPP 表零销售行（本期无 trade 记录但 EOH 进前三）凭回退展示最近已知属性；
// Top 表行必有当期销售，回退分支永不触发
VAR __MaxDt =
    COALESCE(
        CALCULATE(
            MAX('s02_trade_sku_data_d'[dt]),
            's02_trade_sku_data_d'[dt] >= __PeriodMin,
            's02_trade_sku_data_d'[dt] <= __PeriodMax
        ),
        CALCULATE(MAX('s02_trade_sku_data_d'[dt]))
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
//       NULL 行排除；区间无记录回退全历史最新 dt（v2.6 零销售行兜底）；全历史无记录 / 当天全空白返回 BLANK
// ========================================

// ── This Period 时间区间 ──
VAR __PeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Min_This[TimeFrame_Min])
VAR __PeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

// ── 币种汇率与符号 ──
VAR __ExchangeRate = SELECTEDVALUE(Slicer_Currency_Selection[Currency_ExchangeRate], 1)
VAR __CurrencySymbol = SELECTEDVALUE(Slicer_Currency_Selection[Currency_Symbol], "¥")

// ── 最新日期 ──
// ── 最新日期：区间内最大 dt；无记录回退全历史最大 dt（v2.6 零销售行兜底）──
// OPP 表零销售行（本期无 trade 记录但 EOH 进前三）凭回退展示最近已知属性；
// Top 表行必有当期销售，回退分支永不触发
VAR __MaxDt =
    COALESCE(
        CALCULATE(
            MAX('s02_trade_sku_data_d'[dt]),
            's02_trade_sku_data_d'[dt] >= __PeriodMin,
            's02_trade_sku_data_d'[dt] <= __PeriodMax
        ),
        CALCULATE(MAX('s02_trade_sku_data_d'[dt]))
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
//       sku 级属性以单值为主）；NULL 不参与；区间无记录回退全历史
//       最新 dt（v2.6 零销售行兜底）；全历史无记录 / 当天无有效值返回 BLANK
// 类型口径（v1.1 实证确认）: predictive_buy 为整数类型（Nullable(Int32)，
//       值 1 / 0 / NULL）——比较使用整数字面量；禁止 String 比较
//       （"1" ≠ 1 恒不成立，会输出全空）
// ========================================

// ── This Period 时间区间 ──
VAR __PeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Min_This[TimeFrame_Min])
VAR __PeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

// ── 最新日期 ──
// ── 最新日期：区间内最大 dt；无记录回退全历史最大 dt（v2.6 零销售行兜底）──
// OPP 表零销售行（本期无 trade 记录但 EOH 进前三）凭回退展示最近已知属性；
// Top 表行必有当期销售，回退分支永不触发
VAR __MaxDt =
    COALESCE(
        CALCULATE(
            MAX('s02_trade_sku_data_d'[dt]),
            's02_trade_sku_data_d'[dt] >= __PeriodMin,
            's02_trade_sku_data_d'[dt] <= __PeriodMax
        ),
        CALCULATE(MAX('s02_trade_sku_data_d'[dt]))
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
//       ——v2.2 起 Top3 排名（SKU Rank）与行排序（Sort Key）的依据指标
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
// 用途: 当前行 sku_id 的库存周转周数（数仓预计算 weeks_cover 字段直读）
// 依赖: Slicer_Time_Frame_Max_This[TimeFrame_Max]（end period 最后一天，直接单日过滤）
// 口径（v2.2 调整，业务确认）: weeks_cover 为数仓预计算字段，直接读取——取所选
//       时间范围 end period 最后一天（快照日单日）该 sku 的 weeks_cover 值；
//       "(期末库存 + 在途) / This Period 销售数量"计算逻辑与 §40 修正史（分子
//       分母写反）整体废止（度量名称不变）——数值为数仓固化口径（与 Item
//       Stockout 模块 v2.6 同款调整）
// 防御性写法: 快照日 sku + day 不保证唯一行，聚合取 MAX(weeks_cover)——
//       单行时 MAX 退化为该行自身值
// 数据底表: s02_inventory_stock_sales_detail_d（表含 weeks_cover 字段）
// 行维度传递: TREATAS(trade[sku_id] → inv[sku_id]) 单列桥接（行分组双列
//       category + sku_id，category 为 sku 从属属性无需传递；同 EOH Value §4.11）
// 空值处理: 快照日无对应表行（或 weeks_cover 为 NULL）时返回 BLANK
// 渠道: inv 表无渠道字段，本指标不受渠道筛选影响（不再有分子分母渠道不对称）
// ========================================

// ── this period筛选 期末日期：end period 最后一天 = Max_This 表 TimeFrame_Max（直接单日过滤）──
VAR __EndPeriodDate_This = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

RETURN
    CALCULATE(
        MAX('s02_inventory_stock_sales_detail_d'[weeks_cover]),
        TREATAS(
            VALUES('s02_trade_sku_data_d'[sku_id]),
            's02_inventory_stock_sales_detail_d'[sku_id]
        ),
        's02_inventory_stock_sales_detail_d'[dt] = __EndPeriodDate_This
    )
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
### 4.15 Top SKUs SPU ID（SPU ID）
```dax
Top SKUs SPU ID =
// ========================================
// 度量值: Top SKUs SPU ID
// 中文名: SPU ID（属性列）
// Display Folder: Top & OPP SKUs Analysis\Top\Attributes
// 用途: 根据当前筛选上下文中的 sku_id 反查 spu_id，作为值区域度量展示，
//       spu_id 不作为行维度
// 数据底表: s02_trade_sku_data_d
// 取值规则（§1.3）: 最新日期 distinct 顿号拼接——This Period 区间内该组合的
//       最大 dt 那天 spu_id distinct 值升序拼接（sku 级属性通常为单值，
//       拼接自然退化为单值）；区间无记录回退全历史最新 dt（v2.6 零销售行兜底）；全历史无记录 / 当天全空白返回 BLANK
// 行维度传递: 当前行的 category + sku_id 筛选自动限定取值范围；
//       若行上只有 sku_id，同样可按 sku_id 取值；
//       framework / 渠道等外部切片器自动传导
// 说明: 返回结果为文本，不会对 spu_id 进行求和等数值聚合
// ========================================

// ── This Period 时间区间 ──
VAR __PeriodMin =
    SELECTEDVALUE ( Slicer_Time_Frame_Min_This[TimeFrame_Min] )
VAR __PeriodMax =
    SELECTEDVALUE ( Slicer_Time_Frame_Max_This[TimeFrame_Max] )

// ── 最新日期：区间内最大 dt；无记录回退全历史最大 dt（v2.6 零销售行兜底）──
// OPP 表零销售行（本期无 trade 记录但 EOH 进前三）凭回退展示最近已知属性；
// Top 表行必有当期销售，回退分支永不触发
VAR __MaxDt =
    COALESCE (
        CALCULATE (
            MAX ( 's02_trade_sku_data_d'[dt] ),
            's02_trade_sku_data_d'[dt] >= __PeriodMin,
            's02_trade_sku_data_d'[dt] <= __PeriodMax
        ),
        CALCULATE ( MAX ( 's02_trade_sku_data_d'[dt] ) )
    )

RETURN
    IF (
        ISBLANK ( __MaxDt ),
        BLANK (),
        CONCATENATEX (
            FILTER (
                CALCULATETABLE (
                    VALUES ( 's02_trade_sku_data_d'[spu_id] ),
                    's02_trade_sku_data_d'[dt] = __MaxDt
                ),
                NOT ISBLANK ( 's02_trade_sku_data_d'[spu_id] )
                    && LEN ( TRIM ( 's02_trade_sku_data_d'[spu_id] & "" ) ) > 0
            ),
            's02_trade_sku_data_d'[spu_id] & "",
            "、",
            's02_trade_sku_data_d'[spu_id],
            ASC
        )
    )
```
---

## 5. 度量值清单

| #  | 度量值                              | 类型                             | 用于视觉对象                       |
| -- | ----------------------------------- | -------------------------------- | ---------------------------------- |
| 1  | Top SKUs SLS Amt Value / Display    | currency（对数辅助，默认隐藏）    | 不参与排名 / 排序（v2.2），对数用  |
| 2  | Top SKUs SKU Rank                   | RANKX（DENSE 并列同名次，SLS Units 降序） | 视觉级筛选器「介于 1 与 3」        |
| 3  | Top SKUs Sort Key                   | 排序键编码（-(类别数量 × 1e6 + sku 数量)）| 行排序依据（升序）                 |
| 4  | Top SKUs Product Photo              | trade 属性（最新日期拼接）       | 值区域（数据类别 = 图像 URL）      |
| 5  | Top SKUs Product Type               | trade 属性（最新日期拼接）       | 值区域                             |
| 6  | Top SKUs Price                      | trade 属性（最新日期值，currency）| 值区域                            |
| 7  | Top SKUs Predictive Buy             | trade 属性（最新日期值映射 Y/N） | 值区域                             |
| 8  | Top SKUs SLS Units Value / Display  | integer                          | 值区域                             |
| 9  | Top SKUs EOH Value / Display        | integer                          | 值区域                             |
| 10 | Top SKUs Weeks Cover Value / Display| decimal_1dp（weeks_cover 字段直读，防御性 MAX）| 值区域                             |

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
| 视觉级筛选器 2   | Top SKUs SKU Rank 介于 1 与 3（**含下界**——每个 category 分组保留组内 SLS Units 前三，v2.2 基准改数量）                                    |
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
- **行排序绑定 Sort Key 列升序**：category 块按 SLS Units 降序、块内 sku 按数量降序（v2.2 基准改数量）；同 category 内数量并列行排序键相同、行序不定（见 §8 注意事项 7）
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
| SKU Rank               | DENSE_RANK() OVER (PARTITION BY category ORDER BY SUM(product_qty) DESC)——DENSE 并列对齐；值域排除空白键与 NULL 数量行 |
| 类别排名 / Sort Key    | sort_key = -(category 粒度 SUM(product_qty) × 1000000 + sku SUM(product_qty))，ORDER BY sort_key ASC；数量并列行键相同（行序不定） |
| Top3 行筛选            | 外层 WHERE sku_rank <= 3（每个 category 保留前三；NULL 排名行排除）                                                        |
| 属性四列               | (category, sku_id) 分组 MAX(dt) → 当天 distinct 值拼接；Predictive Buy CASE '1' → 'Y' / '0' → 'N' / 其余 NULL；Price 输出原始 CNY 值（换算与符号在 Display 层，不在 SQL 范围） |
| EOH                    | inv WHERE dt = 快照日 GROUP BY sku_id（framework 条件视与 inv 的模型关系对齐——有关系附加条件，无关系不附加）                |
| Weeks Cover            | MAX(weeks_cover)（快照日该 sku 防御性 MAX 直读；无 inv 记录 / 字段 NULL → NULL，v2.2）                                       |

- NULL 语义对齐 DAX：分子 NULL → 比率按 DIVIDE 语义（分子记 0 / 分母拦截整体 NULL）；属性字段区间无记录回退全历史最新 dt（v2.6——SQL 对应：区间无记录的组合改在全历史 MAX(dt) 取值），全历史无记录或当天全空白 → NULL（显示 "-"）
- 参数区（对齐同看板惯例）：framework = 'Foundation'、Platform / Store 全选（等价不筛选）、This Period dt ∈ ['2026-03-29', '2026-07-25']、快照日 '2026-07-25'
- 对数路径：PBI 表格行（category 块按数量降序 × 每块 3 行）vs SQL sku_rank <= 3 结果按 sort_key 升序逐列比对

---

## 8. 注意事项

1. **行分组为 category + sku_id 双列**：最终展示行 = 不重复的 category + sku_id 组合；全部指标按该组合粒度聚合（跨尺码 / 渠道明细汇总）；inv 桥接锚点仅需 sku_id 单列（inv 唯一键 dt + sku_id）
2. **属性字段全部指标化**：spu_img_url / product_type / md_price / predictive_buy 四个字段经值区域度量输出（§1.3 规则——This Period 区间内该组合最大 dt 当天 distinct 值拼接），不进字段井
3. **Top3 行筛选必须用「SKU Rank 介于 1 与 3」度量筛选器**：原生「前 N 个」列筛选器为全局 TopN（跨 category 取全表前 N），不按 category 分组；区间筛选必须含下界（BLANK 视为 0，「小于或等于 3」会放行空白 / 无数量行）；排名依据 = SLS Units（v2.2 由 SLS Amt 改，This Period sum(product_qty) 降序，RANKX DENSE 并列同名次放行含并列）
4. **RANK relation 用法（按度量值排名的唯一合法形式）**：RANK 省略 relation 时 ORDERBY 仅允许简单列引用——CALCULATE 等度量表达式作排序键报错"已省略 RANK 的关系参数，并且其 ORDERBY 子句包含非引用列表达式"；按度量值排名必须显式指定 relation（FILTER(CALCULATETABLE(ADDCOLUMNS(VALUES(分组列), @Amt)), ...)，两键决胜 [@Amt] DESC + 分组列 ASC，名次唯一）
5. **候选上下文净化（本方案关键防护）**：视觉级度量筛选器（Rank 介于 1 与 3）生效后落地为 (category, sku_id) 跨列组合筛选，单列 ALL / REMOVEFILTERS 无法清除——SKU Rank / Sort Key 的排名表必须在 `CALCULATETABLE(REMOVEFILTERS(两列) + TREATAS 重限分组)` 的净化上下文中整体求值（保留 framework / 渠道等外部筛选），否则候选与组合筛选冲突取 BLANK、名次失真（Top Size Sort Key 同源坑，已在度量内预防，禁止改回单列 ALL / 逐候选重建写法）
6. **候选集口径一致**：类别排名候选金额必须上卷到 category 粒度（CALCULATETABLE 净化上下文已移除 sku 筛选，@Amt 上下文转换仅叠加候选 category 筛选），否则候选金额被限制在当前行 sku 内、与对比值口径不一致，RANK 恒返回 1（Top Size Category Rank 同源坑）
7. **Sort Key 权重前提与并列（v2.2）**：单个 SKU 的 SLS Units < 1,000,000（L2 不侵位 L1；数量可能超限时改 1,000,000,000）；数量为整数聚合，同 category 内两 sku 数量完全相等时排序键相同、行序不定（金额口径下概率极低，数量口径下常见）——并列行仅行间顺序不定，块归属与块序不受影响，业务可接受；若要求并列行序确定需业务确认是否回退金额决胜或追加次级键编码
8. **predictive_buy 类型口径（v1.1 实证确认）**：字段为整数类型（Nullable(Int32)，值 1 / 0 / NULL），DAX 按整数字面量比较（1 → "Y"、0 → "N"、NULL 空）——禁止 String 比较（"1" ≠ 1 恒不成立会输出全空）
9. **inv 桥接为 TREATAS sku_id 单列**：本模块行粒度单一（category + sku_id，桥接锚点 sku_id），无需 Item Stockout 的 ISINSCOPE + IF 双分支；期末日期 = end period 最后一天，直接读 SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max]) 单日过滤（Max_This 表为断开维度，读值不随行上下文 / 切片器漂移）
10. **framework 前置筛选传导**：Slicer_Framework 与两张事实表一对多关联（framework 字段两表齐备，数据字典已核对），framework = 'Foundation' 经关系自动传导双表，DAX 不显式处理；期末日期直接读 Max_This 表 TimeFrame_Max（不依赖 inv 数据取值），单日过滤聚合内 inv 侧 framework 筛选照常生效（限定 Foundation 框架库存，属预期行为）
11. **渠道口径不对称**：Platform / Store 切片器经关系自动传导仅作用于 trade 侧（SLS 系列指标 + Top3 候选数量）；inv 表无渠道字段，库存侧指标（EOH / Weeks Cover）全量口径——trade 侧受筛选、inv 侧全量的口径不对称为模型物理限制，业务需知悉；Weeks Cover v2.2 起整体取数 inv 侧 weeks_cover 字段，不再有分子分母渠道不对称
12. **Weeks Cover 字段直读（v2.2 调整，业务确认）**：由"(期末库存 + 在途) / This Period 销售数量"计算改为数仓预计算 weeks_cover 字段直读——取 end period 最后一天（快照日单日）该 sku 的值，防御性 MAX(weeks_cover)（sku + day 不保证唯一行，单行时 MAX 退化为行值）；计算逻辑与 §40 修正史（分子分母写反）废止，度量名称不变；快照日无对应表行 / 字段 NULL → BLANK（显示 "-"）；与 Item Stockout 模块 v2.6 同款调整
13. **net_sales_amt 列来源**：模型内为 Power Query 行级计算列（ROUND(product_qty × sales_price, 6)），数据库无此列——测试 SQL 验证时按行级乘积还原
14. **币种**：SLS Amt / Price 为 currency 类（Value 层 ÷ 汇率换算，Display 层拼符号）；Top3 排名与 Sort Key v2.2 起使用 SLS Units 数量聚合（不涉及币种）；数量 / 周数 / 文本属性不涉及换算
15. **RANK / ORDERBY 版本要求**：Power BI Desktop 2022 年 9 月及以后版本
16. **总计行为**：总计行不做特判，交由表格视觉对象默认生成（总计行 category / sku_id 为 BLANK，Rank / Sort Key / 属性度量返回 BLANK，数值指标为全量聚合）；需总计 = 展示行之和时关闭总计行
17. **口径与语法**：口径文档中定义的所有指标必须遵守其数据类型与数据格式，与解决方案存在争议时一切以口径文档为准；DAX 文本常量使用双引号，单引号仅用于表名，列名使用方括号
18. **排名候选集必须收窄 + 批量物化（v2.0 性能修复，禁止回退）**：SKU Rank 排名表 = 净化上下文中 `SUMMARIZE` 一次分组查询物化（候选集天然 = 当前 category 在 dt 区间内有记录的 sku）——两层演进均不可回退：v1.0 全模型 `ALL(sku_id)` 值域（O(行组合数 × 全值域)，超时根因）；v1.1 值域收窄但 ADDCOLUMNS + 逐候选 CALCULATE 物化（O(R′ × K̄) 次上下文转换，SE 缓存无法消除 FE 转换开销，仍卡根因）；category / sku_id「不为空」列筛选器先行收窄查询行集，务必配置；当期无销售行组经 `__CurrentUnits` BLANK 短路（VAR 惰性求值，排名表不物化）
19. **复杂度与再优化路径**：度量筛选器架构下 Rank 对全部行组合求值为固有成本（当期有销售的 R′ 行组 × 每行 O(K) 名次匹配）——若 v2.0 仍卡：① RANK 改计数式排名（COUNTROWS(FILTER(排名表, 金额更高 || (金额相等且 sku 字母序更小))) + 1，两键决胜语义等价、免每次排序）② 建 (dt, category, sku_id) 粒度聚合表（PQ / 用户定义聚合，候选聚合命中小表，SE 常数骤降）③ 源侧预计算 Top3（失去切片器动态联动，需业务确认）；定位手段：性能分析器 → 复制 DAX 查询，查看 SE / FE 耗时占比（FE 占主导先走①，SE 占主导走②）
20. **分组表头排序键（v2.3 修复，禁止回退）+ 空行防线（v2.4 恢复，禁止删除）**：分组表格对 category 块的排序 = Sort Key 在「仅 category 层级」上下文求值（sku_id 不在作用域）——度量此时须返回类别块键 -(CatUnits × 1e6)（SkuUnits 记 0），块头升序 = 类别数量降序；若返回 BLANK（v2.2 前写法）全部块头并列 → 块序回退 category 字母序（用户实测 Dresses(2585) 排 Outerwear(2774) 前，块内排序正常、块序失真的根因）；负号翻转逻辑本身无问题（块内 -2585000089 → -44 → -39 升序 = 数量 89/44/39 降序已验证生效）。**空行防线**：sku 行当期无销售数量必须返回 BLANK——该类行 Top Rank 为 BLANK，在视觉实际配置「Top Rank 小于或等于 3」中 BLANK 视为 0 会放行（§3.2 设计推荐「介于 1 与 3」，视觉实际为 ≤3，用户确认筛选条件不变），此前一直依赖本拦截 + 「Sort Key 不为空」筛选双重排除；v2.3 曾误删该拦截致无数量行得块键 -CatUnits×1e6+0 通过两道筛选混入空行（实测空行根因）——三类上下文处理规则见 §4.4 度量，禁止简化合并
