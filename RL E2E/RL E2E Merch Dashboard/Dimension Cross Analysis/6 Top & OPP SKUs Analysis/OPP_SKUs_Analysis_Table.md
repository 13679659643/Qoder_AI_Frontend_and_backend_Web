# OPP_SKUs_Analysis_Table 解决方案（OPP 部分）

> **版本**: v2.5
> **模块**: RL E2E Merch Dashboard - Dimension Cross Analysis Tab - Top & OPP SKUs Analysis（OPP 部分）
> **关联口径**: 口径文档/口径Markdown格式/Dimension Cross Analysis.md - 子模块九模块说明（OPP 定义 + 参与判断的计算：launch_time / ST%（金额））+ §40 Weeks Cover / §41 SLS Units / §42 EOH；§40~§42 与属性列口径同 Top 部分复用（§40 Weeks Cover 自 Top v2.2 起为数仓预计算 weeks_cover 字段直读，本模块 v2.0 判定同步切换）
> **数据底表（库存为主）**: s02_inventory_stock_sales_detail_d（排序依据 stock_inv_qty / 资格判定 launch_time / brand / ax_class / msrp_inv_amt / stock_inv_qty / in_trans_inv_qty / weeks_cover 同表直聚合或直读）
> **数据底表（销售/属性类）**: s02_trade_sku_data_d（ST% 销售侧 + Top3 排除集排名基准 SLS Units + 属性列取值）
> **关联维度**: Slicer_Time_Frame_Min_This / Max_This（时间，断开维度）；Slicer_Framework（framework 一对多关系，前置筛选 'Foundation' 自动传导双表）；Slicer_Platform_Selection / Slicer_Store_Name（一对多关系自动传导，DAX 不显式处理）；Slicer_Currency_Selection（币种，断开维度）
> **筛选影响范围**: dt（断开维度，DAX 显式筛选）+ framework 前置筛选 + Platform / Store Name（模型关系自动传导）+ 其余与两张事实表已建关系的商品维度切片器
>
> **版本记录**:
> v2.5（2026-11-20）——属性列零销售行兜底说明（配合 Top v2.6）：v2.4 候选域修复后本期零销售 sku 可凭 EOH 前三展示（ST% = 0 恒低于均值天然过判定），但复用的属性度量（Product Photo / Product Type / Price / Predictive Buy / SPU ID）"最新日期"原仅取 This Period 区间内 MAX(dt) → 零销售行属性列全空（实测 Photo / Type / SPU ID 均空）；业务确认全部属性列统一加回退——区间无记录时回退取该组合全历史 MAX(dt) 当天值（属性为慢变字段，取最近已知值），修改落位 Top_SKUs_Analysis_Table.md v2.6（五个属性度量 __MaxDt 包 COALESCE），本表经复用自动生效，本文件仅补 §4.4 复用说明，度量代码不另建
> v2.4（2026-11-20）——Rank 全 1 真根因修复（候选域与行域错位）：v2.3 修复后实测仍全 1（Skirt 组 EOH 13/11/10/10），用户提供关键线索——WMLRSKTS6H202994106 不属于本期财年（202701~202704，dt ∈ 2026-03-29 ~ 2026-07-25）；机制：时间切片器为断开维度、仅 DAX 显式筛选 → 视觉行组 (category, sku) 不受 dt 筛选、全历史 sku 照常显示，而 Rank 候选集 __CandSkus 沿习 Top v2.1 写法带 dt ∈ 本期筛选 → 本期无 trade 记录的 sku 全部缺席候选表——本期零销售 category（OPP 典型场景：旧季滞销库存）候选表为空 → __Qualified 空表 → RANKX 空表对所有行返回 1、Top3 截断失效全组放行；修复：__CandSkus 去掉 dt 区间筛选，候选域 = 当前 category 全部 sku（framework 等外部筛选保留），与视觉行域对齐——排名基准为快照日 EOH（时点值）本就不依赖本期销售；dt 仅保留约束 __TradeAgg（@StAmt 当期口径，无本期记录候选 @StAmt BLANK → ST% = 0 < 均值，与行级第 0 层判定一致）与 __TopCandSkus（Top3 排除集当期 SLS Units 口径）；Top 模块不受影响（其排名基准为当期 SLS Units，候选域滤 dt 与基准同源）
> v2.3（2026-11-20）——Rank 全 1 缺陷修复：实测 Skirt 组 EOH 13/11/10/10 四行 Rank 全为 1——RANKX 的排名候选表 __Qualified 为空（空表无值可比较，全行返回 1，全 1 为空候选表典型签名）；两处缺陷修复：① __TradeAgg 分组物化缺 REMOVEFILTERS(sku_id)——视觉行组当前 sku 筛选泄漏进 CALCULATETABLE，__TradeAgg 仅含当前 sku、其余候选 @StAmt 全 BLANK（候选 ST% 判定退化为 0 < 均值恒真，高售罄候选被误放行）；② 全部候选物化表（__WcBySku / __TopCandSkus / __InvAgg / __TradeAgg / __GrpAvg）由 SUMMARIZE 传统扩展列改为「SUMMARIZE 仅分组列 + CALCULATETABLE(ADDCOLUMNS(..., CALCULATE(...)), 筛选参数)」分组/扩展分离写法——传统 SUMMARIZE 扩展列在 CALCULATETABLE + TREATAS 组合下求值上下文脆弱，扩展列值一旦成 BLANK，资格 FILTER 筛光全部候选 → 空表 → 全 1；Qualify / Rank 两处同步；遗留边界与调试配方见 §8 注意事项 19
> v2.2（2026-11-20）——内存不足（OOM）根治：单通道重构——原「Qualify = 1」+「Rank 介于 1 与 3」双度量筛选器 = 引擎对全部 (category, sku) 分组跑两遍完整度量求值（Qualify 通道每行约 8 次 SE 查询 + 排除集物化，Rank 通道再物化候选表），全表行组规模下 FE 物化叠加内存耗尽；重构为 Rank 自包含五条件判定（不再引用 [OPP SKUs Qualify]），判定分三层惰性短路：第 0 层每行标量聚合（空白键 / EOH / launch / ST% / WC）任一不成立直接 BLANK 不物化任何候选表，第 1 层条件 4 分组均值，第 2 层（仅资格候选行到达）条件 5 排除集 + 资格集合候选表 + RANKX；视觉级「Qualify = 1」筛选器**移除**（Qualify 度量保留作对数 / 调试，不挂视觉），RANK 窗口函数方案评估否决（瓶颈非排名计算，且无 relation 时 ORDERBY 不接受度量表达式）
> v2.1（2026-11-20）——Sort Key 分组表头排序缺陷修复：v1.0/v2.0 结构沿袭旧写法（sku_id 空白即 BLANK 拦截），分组表头上下文（sku_id 不在作用域）排序键恒 BLANK → 全部块头排序键并列 → category 块序回退字母序（实测 Belts < Headwear < Pants / Luggage/Bags < Pants 均为字母序），块序 EOH 降序失效——Top 模块 v2.3 同源缺陷漏移植；修复为三上下文结构（①category 空白 → BLANK；②分组表头 → 块键 -(CatEOH × 1e6)；③sku 行无库存 → BLANK 空行防线，同 Top v2.5）。性能优化：Top3 排除集构建由全类目收窄到当前 category（sku→category 一一对应下等价，跨 category sku 需回退全类目写法）、Rank 候选表 @StAmt 由每候选 TREATAS(ROW) 桥接改为 __TradeAgg 一次分组查询 + 内存匹配、WC 均值由 VALUES 迭代 + 逐行上下文转换 AVERAGEX 改为 __WcBySku 一次分组物化 + AVERAGEX
> v2.0（2026-11-19）——Weeks Cover 判定切换数仓预计算 weeks_cover 字段直读（判定值 = 快照日 MAX(weeks_cover)，与 Top v2.2 / Item Stockout v2.6 同源同款）；均值口径由比值均值改为 SKU 值算术平均（各 SKU 先按直读逻辑取值，再 Σ ÷ 参与计算 SKU 数，BLANK 不参与分子分母），原"(stock_inv_qty + in_trans_inv_qty) / product_qty"计算与比值均值废止；新增资格条件 5——OPP 行排除 Top 表格各 category 组内 Top3 sku（sku 级排除，非 category 级；Top3 口径跟随 Top 模块 v2.2：This Period SLS Units 降序、DENSE 含并列、≤3、无数量 sku 不入集），Qualify 当前行判定与 Rank 候选集判定两处同步；Sort Key 维持 EOH 库存量编码不变（排除逻辑落位资格 / 排名筛选层，排序键不涉及 weeks_cover 与排除集）；条件 3 判定值与均值全量取自 inv 侧 → 原 WC 渠道口径不对称消失（ST% 保留）
> v1.0（初版）——四条件资格判定（上架超 2 周 / ST% 低于均值 / WC 高于均值 / EOH 高于同组均值）+ 资格集合内 EOH Top3 + EOH 库存量编码排序键

---

## 1. 需求理解

### 1.1 模块定位与视觉对象结构

Top & OPP SKUs Analysis 板块含 TOP 与 OPP 两部分，经页面按钮 + 书签切换显隐（不在度量值范围）。本方案覆盖 **OPP 部分**：单张平铺表格，前置筛选 framework = 'Foundation'，行 = category + sku_id 组合，先按五项资格条件过滤出「机会 SKU」（低售罄、高库存、慢周转的新上架商品，且排除 Top 表 Top3 sku），再在**资格 SKU 集合内**按 EOH（在库库存数量，快照日时点）降序取每个 category 的 Top3：

| 配置项           | 内容                                                                                                   |
| ---------------- | ------------------------------------------------------------------------------------------------------ |
| 视觉对象类型     | 表格（平铺，无层级小计，总计行交由视觉对象默认生成）                                                   |
| 字段井（行分组） | s02_trade_sku_data_d[category]、s02_trade_sku_data_d[sku_id]（与 Top 表格同构）                        |
| 值区域（属性列） | Product Photo / Product Type / Price / Predictive Buy（复用 Top SKUs 度量，见 §4.4）                   |
| 值区域（指标列） | EOH / SLS Units / Weeks Cover Display（复用 Top SKUs 度量）+ Sort Key（行排序依据）                    |
| 视觉级筛选器     | framework = 'Foundation'（前置）+ **OPP SKUs SKU Rank 介于 1 与 3（资格 + Top3 单通道，v2.2）** + 空白键排除 |
| 行排序           | OPP SKUs Sort Key 升序（category 块按 EOH 降序 + 组内 sku 按 EOH 降序，库存量编码负号翻转，v2.1 三上下文修复块序） |

- **以库存表为主**：排序依据指标（EOH = sum(stock_inv_qty)）与资格判定的库存侧（launch_time / brand / ax_class / msrp_inv_amt / stock / weeks_cover）全部取自 s02_inventory_stock_sales_detail_d——该表字段齐备（已核对数据字典），库存侧判定**同表直聚合 / 直读，无需桥接**；仅销售侧标量（净销售金额）与 Top3 排除集排名基准（SLS Units）取自 trade 表
- **行维度沿用 trade 字段**：与 Top 表格同构（行分组双列 trade[category] + trade[sku_id]），展示指标与属性列度量直接复用 Top SKUs 系列（行分组筛选自动传导 trade 侧聚合）；库存指标经 TREATAS 桥接（同 Top 模式）
- **资格筛选与 Top3 单通道（v2.2）**：五条件判定内嵌 Rank 度量（分层惰性短路），视觉级仅挂 Rank 筛选器一遍求值；Qualify 度量保留作对数 / 调试，不挂视觉（双通道为 OOM 根源，禁止恢复）

### 1.2 OPP 资格判定规则（五条件）

在外部切片器（framework / 渠道等）+ 时间筛选下，当前行 SKU 须**同时满足**以下五项（条件 1~4 判定值与均值的比较方向为口径核心，任一不成立即无资格；条件 5 为 sku 级集合排除）：

| #   | 条件                | SKU 判定值                                                                                                        | 比较对象（均值）                                                                                          | 数据源                          |
| --- | ------------------- | ----------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------- | ------------------------------- |
| 1   | 上架超 2 周         | launch_time（String 转日期）：上架日期至 end period 最后一天的天数                                                | > 14 天（严格大于）                                                                                       | inv[launch_time]（快照日行）    |
| 2   | 售罄率低于均值      | ST% = net_sales_amt / (net_sales_amt + msrp_inv_amt)（销售侧 this period 区间，库存侧快照日，金额口径）          | 全 SKU 均值 = sum(net_sales_amt) / (sum(net_sales_amt) + sum(msrp_inv_amt))，sum 范围 = 外部筛选下全部 SKU | trade + inv                     |
| 3   | 周转周数高于均值    | weeks_cover 字段直读：快照日 MAX(weeks_cover)（数仓预计算，防御性 MAX；v2.0）                                     | 全 SKU 算术平均 = 各 SKU 直读值 Σ ÷ 参与计算 SKU 数（BLANK 不参与分子分母；v2.0）                          | inv[weeks_cover]（快照日行）   |
| 4   | 库存高于同组均值    | EOH = sum(stock_inv_qty)（快照日）                                                                                | 同 Label & CLASS（brand + ax_class）分组均值 = 分组 EOH 合计 / 分组 SKU 个数                              | inv（brand / ax_class 同表）    |
| 5   | 非 Top Top3 sku     | 当前 sku ∉ Top 表各 category 组内 SLS Units Top3 集合（sku 级排除，非 category 级；v2.0 新增）                   | —（集合排除，无比较对象）                                                                                 | trade（SLS Units，复用 Top 口径） |

口径细节：

- **条件 1**：launch_time 值形如 "2022-09-02 00:00:00.000"（String），取前 10 位转日期（DATEVALUE(LEFT(...,10))）；上架日期 BLANK 或无法解析 → 资格不成立；`__EndPeriodDate_This - __LaunchDate > 14`（严格大于 14 天）
- **条件 2 均值**：比值均值（先各自全量 sum 再相除），非 SKU 值的算术平均；trade 侧与 inv 侧的全量 sum 各自独立（两侧 SKU 域不必对齐——比值公式原始口径）
- **条件 3 判定值与均值（v2.0）**：判定值 = 快照日该 sku 的 MAX(weeks_cover)（与 Top v2.2 展示度量同源同款，快照日同 sku 多行时防御性取 MAX）；均值 = **算术平均**——各 SKU 先按同一逻辑取直读值，再聚合除以参与计算的 SKU 数（值 BLANK 的 SKU 不参与分子与分母，AVERAGEX 自动跳过）；均值域 = 外部筛选下 inv 全部 SKU，与判定值同源同侧（无渠道不对称）
- **条件 3 边界（v2.0）**：weeks_cover BLANK（快照日无 inv 记录 / 字段 NULL）→ 判定值 BLANK → 严格大于比较不成立 → 资格不通过；注意零销售高库存 sku 不再被条件 3 天然排除（原分母 product_qty = 0 短路废止，数仓预计算 weeks_cover 可为高值），是否放行取决于其余条件
- **条件 4 的分组与 SKU 个数**：分组键 = inv[brand]（Label）+ inv[ax_class]（CLASS）；分组 EOH 合计与 SKU 个数均为**快照日 inv 侧口径**（分组内有库存记录的 distinct sku 数）；SKU 的分组归属按其 inv 快照日行的 brand / ax_class 取值
- **条件 5（Top Top3 排除，v2.0 新增）**：排除集 = Top 表格**实际展示行**的 sku 全体——各 category 组内 This Period SLS Units（SUM(product_qty)）降序 DENSE 排名 ≤ 3（含并列放行），且无数量 sku 与空白 category 组不入集（对齐 Top 表空行防线）；排除为 **sku 级**——Top3 sku 不出现在 OPP 任何行，而非排除其所属 category（该 category 其余 sku 正常参与）；Top3 排名口径跟随 Top 模块当前版本（v2.2 起基准 SLS Units），Top 口径再调整时本排除集必须同步
- ST%（金额口径）仅参与判定、不在前端展示（口径文档 §633 说明）；Weeks Cover / SLS Units / EOH 展示口径同 Top（§40~§42 复用）

### 1.3 Top3 与排序机制

- **Top3 行筛选**：在**资格 SKU 集合内**（已经条件 5 排除 Top Top3 sku）按 category 分组、组内 EOH 降序取前三——视觉级「OPP SKUs SKU Rank 介于 1 与 3」度量筛选器（含下界），Rank 候选集限定资格通过的 SKU（与 Top 的全量组内排名不同，资格过滤内嵌于排名候选集）
- **SKU Rank**：RANKX 迭代器（候选集 = 当前 category 内资格 SKU 物化表），EOH 降序、DENSE 并列共享名次（含并列放行，同 Top v2.1 语义）
- **Sort Key（库存量编码，v2.1 三上下文结构）**：排序不需要排名——库存数量本身就是顺序：`-(category EOH 合计 × 1,000,000 + SKU EOH)`，负号翻转使表格升序排列 = EOH 降序效果；category 块按快照日库存量降序（库存最大的 category 在最前）、块内 sku 按 EOH 降序；权重前提：单 SKU EOH < 1,000,000（库存件数，超限改 1e9）。**分组表头上下文（sku_id 不在作用域）返回类别块键 -(CatEOH × 1e6)**——块头升序 = 类别 EOH 降序（v2.1 修复，禁止恢复 sku 空白即 BLANK 的拦截写法，同 Top v2.3 教训）；**排除逻辑（条件 3 直读 / 条件 5 排除）落位资格与排名筛选层，排序键不感知**——被排除行不进入视觉，无排序求值
- **BLANK 防护（v2.2 单通道）**：Rank 对无资格行（五条件任一不成立）返回 BLANK（「介于 1 与 3」的下界排除）；Qualify 度量对无资格行返回 0（对数辅助，不挂视觉）

### 1.4 时间口径

| 口径                     | 时间范围                                                                                                                                  | 适用指标                                                        |
| ------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------- |
| This Period（区间类）    | dt ∈ [Slicer_Time_Frame_Min_This[TimeFrame_Min], Slicer_Time_Frame_Max_This[TimeFrame_Max]]                                              | ST% 销售侧、Top3 排除集排名基准（SLS Units）、SLS Units 展示、属性"最新日期"判定 |
| End Period（期末时点类） | end period 最后一天 = Slicer_Time_Frame_Max_This[TimeFrame_Max]（直接单日过滤） | EOH（排序与判定）、launch 判定基准日、ST% 库存侧、**Weeks Cover（判定值直读 + 均值 + 展示复用 Top 直读）** |

说明：

- 两张 s02 表日期字段均为 dt；期末时点为 end period 最后一天（Max_This 表 TimeFrame_Max，直接单日过滤），只取单日；该日快照缺数时判定值按空处理，不回退取范围内最近一天
- 全局均值（条件 2 / 3）与分组均值（条件 4）的时间口径与 SKU 判定值同口径（条件 2 销售侧 this period、库存侧快照日；条件 3 判定值与均值全量取自快照日）
- 属性字段"最新日期"以 This Period 区间内该组合实际最大 dt 为准（复用 Top 度量，同 Top §1.3 规则）

### 1.5 币种与渠道口径

- OPP 判定（ST% / WC / EOH / launch）均为数量与原始金额的比值或数量，不涉及币种换算；展示列复用 Top SKUs 度量（Price / 币种规则同 Top §1.5）
- framework = 'Foundation' 经一对多关系自动传导双表（framework 字段两表齐备），DAX 不显式处理
- inv 表无 platform / shop_name 字段：库存侧（EOH / WC 判定值与均值 / ST% 库存侧）不受渠道筛选影响；trade 侧（ST% 分子 / Top3 排除集 SLS Units）受——ST% 分子分母渠道口径不对称为模型物理限制（同 Top §1.7，业务需知悉）；**条件 3 自 v2.0 起判定值与均值全量取自 inv 侧，原 WC 渠道口径不对称消失**

---

## 2. 现状分析

- inv 表 `s02_inventory_stock_sales_detail_d`（dt + sku_id 唯一键，日快照）**字段齐备**（已逐一核对数据字典）：brand（Label）、ax_class、category、framework、launch_time（Nullable(String)，值形如 "2022-09-02 00:00:00.000"）、msrp_inv_amt（吊牌库存金额）、stock_inv_qty（在库库存）、in_trans_inv_qty（在途库存）、**weeks_cover（数仓预计算库存周转周数，v2.0 起条件 3 判定值与均值的直读源，快照日行值）**——OPP 判定与排序的库存侧全部同表直聚合 / 直读，无桥接
- trade 表 `s02_trade_sku_data_d`：net_sales_amt（PQ 行级列 ROUND(product_qty × sales_price, 6)）、product_qty（ST% 销售侧 + Top3 排除集排名基准 SLS Units）、category / sku_id 与属性字段齐备；ST% 销售侧需经 TREATAS 桥接，Top3 排除集在 trade 侧全类目物化
- 两张事实表无模型关系：trade 行筛选向 inv 传递经 TREATAS 单列桥接（同 Top §3.4）；inv 行值（brand / ax_class / launch / weeks_cover）向 trade 侧判定传递经 TREATAS(ROW) 单值桥接
- 资格判定所需的 brand / ax_class 取自 **inv 表**（快照日行值）——trade 表虽有同名字段，但条件 4 的分组均值域在 inv 侧（EOH 同源），分组归属与均值口径保持同表一致
- weeks_cover 直读的防御性 MAX：与 Top v2.2 / Item Stockout v2.6 同款——快照日同 sku 多行时取 MAX（dt + sku_id 唯一键下自然单值），字段 NULL / 无记录 → BLANK → 条件 3 不成立

---

## 3. 方案设计

### 3.1 度量值分层

```
Rank（资格 + Top3 单通道筛选 + 排名，1 个度量，v2.2 自包含）
←  第 0 层（每行标量聚合）：空白键 / EOH / launch / ST% / WC
      判定——inv 侧 TREATAS 桥接聚合 + trade 侧直聚合 +
      全局均值（__T_St / __T_Inv / __WcBySku，上下文跨行相同
      → SE 缓存共享）；任一不成立 → BLANK，候选表零物化
←  第 1 层（第 0 层通过后）：条件 4 分组均值
      （TREATAS(ROW) 4 次聚合）
←  第 2 层（仅资格候选行到达，同 category 缓存共享）：
      条件 5 排除集（当前 category 分组查询 + RANKX 内存排名）+
      资格集合候选表（__CandSkus / __InvAgg / __TradeAgg /
      __GrpAvg 各一次分组查询 + 内存匹配）→ RANKX 排名
←  视觉级筛选器「Rank 介于 1 与 3」：单通道一遍求值
      （v2.2：Qualify 筛选器移除，双通道 = OOM 根源）
↓
Qualify（对数 / 调试辅助，不挂视觉，v2.2 降级）
←  五条件判定当行列版（每行常数次聚合），用于核对资格
↓
Sort Key（行排序，1 个度量，库存量编码，v2.1 三上下文）
←  -(category EOH 合计 × 1,000,000 + SKU EOH)，负号翻转
←  分组表头 → 块键 -(CatEOH × 1e6)（块序 EOH 降序，v2.1 修复）
←  sku 行无库存 → BLANK（空行防线，禁止删除）
←  库存数量本身即顺序，无需排名（学 Top v2.1）
↓
展示指标（复用 Top SKUs 系列 9 个度量，见 §4.4）
```

### 3.2 行筛选机制

每个表格视觉对象配置四条视觉级筛选器（v2.2 起，Qualify 筛选器移除）：

| 筛选器                          | 类型       | 条件          | 作用                                                                                                    |
| ------------------------------- | ---------- | ------------- | ------------------------------------------------------------------------------------------------------- |
| Slicer_Framework[framework]     | 列筛选器   | = Foundation  | 前置筛选（用户配置）——经一对多关系自动传导双表                                                          |
| OPP SKUs SKU Rank               | 度量筛选器 | 介于 1 与 3   | **资格 + Top3 单通道**——五条件内嵌 Rank 度量，非资格行 Rank 为 BLANK（区间下界排除）；含下界排除 BLANK 行 |
| s02_trade_sku_data_d[category]  | 列筛选器   | 不为空        | 排除空白 category 组                                                                                    |
| s02_trade_sku_data_d[sku_id]    | 列筛选器   | 不为空        | 排除空白主键行（Rank 对空白键返回 BLANK 已被上条排除，此条双保险）                                      |

机制说明：

- **单通道（v2.2 OOM 根治）**：原「Qualify = 1」+「Rank 介于 1 与 3」双度量筛选器迫使引擎对全部 (category, sku) 分组跑两遍完整度量求值（Qualify 通道每行约 8 次 SE 查询 + 排除集物化，Rank 通道再物化候选表），全表行组规模下 FE 物化叠加 → 内存不足；v2.2 将五条件判定内嵌 Rank（分层惰性短路），一遍求值完成资格过滤 + Top3 排名，**禁止恢复 Qualify 筛选器双通道**
- **判定分层惰性短路（v2.2）**：第 0 层每行标量聚合（空白键 / EOH / launch / ST% / WC，约 7 次 SE 查询）任一不成立 → BLANK，候选表零物化；第 1 层条件 4 分组均值；第 2 层（仅资格候选行到达）条件 5 排除集 + 资格集合候选表 + RANKX——非资格行（绝大多数）成本从重表物化降到标量聚合
- **Top3 必须在资格集合内取**：口径为「通过条件 1~5 的 SKU 中按 EOH 取 Top3」——Rank 候选集内嵌资格过滤（先 FILTER 资格再排名），非「全量排名后再过滤」
- **Qualify 度量角色（v2.2）**：保留不删除（名称不变），仅作对数 / 调试（临时拖入表格核对资格判定），**不挂视觉级筛选器**

### 3.3 资格判定口径细化

**全局均值（条件 2 / 3）**：

- 条件 2 trade 侧全量：`CALCULATE(SUM(...), REMOVEFILTERS(trade[category], trade[sku_id]), dt 区间)`——**必须两列整体清除**：视觉级 Qualify / Rank 筛选器落地为 (category, sku_id) 跨列组合筛选，不清除会把均值收窄为当前行自身（判定恒不成立）；framework / 渠道等外部筛选保留
- 条件 2 inv 侧全量：`CALCULATE(SUM(...), inv[dt] = 快照日)`——组合筛选落在 trade 列上，不影响 inv 聚合；外部切片器（framework 等已建关系）自动传导
- 条件 2 均值 = 比值均值（两侧各自全量 sum 后相除），两侧 SKU 域独立（原始口径）
- **条件 3 均值（v2.0 算术平均，v2.1 改一次分组查询）**：inv 侧 `SUMMARIZE(inv, sku_id, @Wc = MAX(weeks_cover))`（快照日）一次分组物化 + `AVERAGEX(@Wc)`——各 SKU 直读值（与判定值同逻辑）求算术平均，自动跳过 BLANK 行（BLANK 不参与分子分母，参与计算 SKU 数 = 快照日 weeks_cover 非 BLANK 的 distinct sku 数）；上下文 = 快照日 + 外部筛选，跨行相同 → SE 缓存共享（v2.1 优化：原 VALUES 迭代 + 逐行上下文转换为 FE 密集操作）；组合筛选落在 trade 列上不影响 inv 聚合，无需 REMOVEFILTERS

**分组均值（条件 4）**：

- 分组键 = inv[brand] + inv[ax_class]；分组 EOH 合计 = `CALCULATE(SUM(inv[stock_inv_qty]), inv[dt] = 快照日, TREATAS(ROW(brand, ax_class), inv[brand], inv[ax_class]))`
- 分组 SKU 个数 = 快照日该分组内有库存记录的 distinct sku 数（`DISTINCTCOUNT(inv[sku_id])` 同上下文）
- SKU 的分组归属 = 该 sku 快照日行的 brand / ax_class（TREATAS(VALUES(trade[sku_id]), inv[sku_id]) 桥接取值）

**Top Top3 排除集（条件 5，v2.0；v2.1 收窄构建域）**：

- 候选物化：`CALCULATETABLE(SUMMARIZE(trade, sku_id, "@Units", SUM(product_qty)), REMOVEFILTERS(sku_id), category = 当前行 category, dt 区间)`——一次**当前 category** 分组查询（v2.1 由全类目构建收窄：sku→category 一一对应下与全类目构建等价——Top3 sku 归属唯一 category，跨类目无交集；候选行数与 FE 排名成本大幅下降；若数据存在同一 sku 跨多 category，需回退 v2.0 全类目构建）
- 组内排名：候选先 FILTER 排除 Units BLANK，ADDCOLUMNS 内存 RANKX 按 Units 降序 DENSE 排名（与 Top 模块 Top SKUs SKU Rank v2.2 同构）
- 排除集 = `SELECTCOLUMNS(FILTER(排名表, Rank ≤ 3), "@TopSku", sku_id)`——含并列放行（DENSE ≤3 可多于 3 行，与 Top 表展示一致）；无数量 sku 不入集（对齐 Top 表空行防线）
- 判定：`NOT CONTAINSROW(排除集, 当前行 sku_id)`——sku 级排除（Top3 sku 不出现在 OPP 任何行，非排除其所属 category）

**候选表物化（Rank 度量内，每行组一次）**：

| 物化表         | 结构                                                                                                          | 成本                     |
| -------------- | ------------------------------------------------------------------------------------------------------------- | ------------------------ |
| __CandSkus     | 当前 category **全部** sku（VALUES + 等值条件，**不滤 dt**——v2.4 对齐视觉行域：行组不受 dt 筛选，候选域滤 dt 会掏空零销售 category 候选表 → RANKX 全 1） | 一次值域查询             |
| __InvAgg       | SUMMARIZE(inv, sku_id, brand, ax_class) 分组 + ADDCOLUMNS 扩展（@EOH / @InvAmt / @Wc / @Launch，v2.3 分组/扩展分离）——快照日 + TREATAS 候选集，**一次分组查询** | 一条 SE 查询（库存为主） |
| __GrpAvg       | SUMMARIZE(inv, brand, ax_class) 分组 + ADDCOLUMNS 扩展（@GrpEOH / @GrpCnt，v2.3 分组/扩展分离）——快照日全量，一次分组查询（几十行级）                        | 一条 SE 查询             |
| __TopSet       | trade 当前 category (sku_id, @Units) 一次分组查询（v2.3 分组/扩展分离）+ RANKX 内存排名 ≤ 3（同 Qualify 排除集，v2.1 收窄构建域） | 一条 category 级 SE 查询 |
| __TradeAgg     | trade 候选集 (sku_id, @StAmt) 一次分组查询（v2.1 替代每候选 TREATAS(ROW) 桥接；**v2.3 补 REMOVEFILTERS(sku_id) 修复当前行筛选泄漏**）          | 一条 SE 查询             |
| __CandTable    | __InvAgg + ADDCOLUMNS：@StAmt（MAXX 匹配 __TradeAgg，纯内存查找）+ @GrpAvgEOH（MAXX 匹配 __GrpAvg）           | 纯内存匹配               |
| __Qualified    | FILTER(__CandTable, 五条件)——资格候选集                                                                       | 纯内存过滤               |

- 判定在 FILTER 内以除法比较直接书写（DIVIDE 边界清晰：分母 0 / BLANK → BLANK → 比较不成立）；条件 5 以 `NOT CONTAINSROW(__TopSet, sku)` 排除；Qualify 度量与 Rank 候选判定**逻辑同构**（两处代码需同步维护，见注意事项 3）

### 3.4 度量值命名与组织

- 命名规则：模块前缀 `OPP SKUs` + 用途（Qualify / SKU Rank / Sort Key）；展示指标复用 Top SKUs 系列度量（命名不变，列头在视觉对象中可重命名）
- Display Folder：`Top & OPP SKUs Analysis\OPP\Qualify`、`Top & OPP SKUs Analysis\OPP\Rank`（与 Top 部分度量隔离）
- 度量值统一存放于 `_Measures` 隐藏表

---

## 4. 度量值实现

### 4.1 OPP SKUs Qualify（资格判定，对数 / 调试辅助，不挂视觉）

> v2.2 起本度量**降级为对数 / 调试辅助**：五条件判定已内嵌 OPP SKUs SKU Rank（单通道），本度量不再挂视觉级筛选器（双通道 = OOM 根源，禁止恢复）；保留用途——临时拖入表格核对某行资格判定（1 / 0），或对数时与 Rank 结果互验；度量代码与判定逻辑保持与 Rank 第 0~2 层同构（口径调整两处同步）。

```dax
OPP SKUs Qualify =
// ========================================
// 度量值: OPP SKUs Qualify
// 中文名: OPP 资格判定（五条件）
// Display Folder: Top & OPP SKUs Analysis\OPP\Qualify
// 用途: 当前行 SKU 是否为 OPP 机会商品——上架超 2 周 && ST% 低于全量均值
//       && Weeks Cover 高于全 SKU 直读值算术平均 && EOH 高于同 Label & CLASS
//       分组均值 && 不在 Top 表 Top3 sku 集合，五条件全通过返回 1，否则返回 0；
//       v2.2 起不挂视觉级筛选器（单通道重构，Rank 内嵌判定），
//       仅作对数 / 调试（临时拖入核对资格）
// 依赖: Slicer_Time_Frame_Min_This[TimeFrame_Min] / Slicer_Time_Frame_Max_This[TimeFrame_Max]
//       Slicer_Time_Frame_Max_This[TimeFrame_Max]（end period 最后一天，直接单日过滤）
// 条件 1 上架超 2 周: inv[launch_time]（String，值形如 2022-09-02 00:00:00.000）
//       取前 10 位 DATEVALUE 转日期，快照日 - 上架日 > 14 天（严格大于）；
//       launch_time BLANK / 无法解析 → 资格不成立（IFERROR 容错）
// 条件 2 ST% < 全量均值: SKU = net_sales_amt / (net_sales_amt + msrp_inv_amt)
//       （销售侧 this period 区间、库存侧快照日，金额口径）；
//       均值 = sum(net_sales_amt) / (sum(net_sales_amt) + sum(msrp_inv_amt))
//       （trade / inv 两侧各自全量 sum 后相除，SKU 域独立——原始口径）
// 条件 3 WC > 全 SKU 算术平均（v2.0 字段直读）: SKU 判定值 = 快照日
//       MAX(inv[weeks_cover])（数仓预计算字段直读，防御性 MAX——与 Top
//       v2.2 / Item Stockout v2.6 同源同款）；均值 = 各 SKU 直读值的
//       算术平均（Σ SKU 值 ÷ 参与计算 SKU 数，BLANK 不参与分子分母，
//       AVERAGEX 自动跳过），原"(stock+in_trans)/product_qty"计算与
//       比值均值废止；判定值 BLANK（无 inv 快照记录 / 字段 NULL）→ 比较不成立
// 条件 4 EOH > 同组均值: 分组键 = inv[brand]（Label）+ inv[ax_class]（CLASS），
//       分组均值 = 分组快照日 EOH 合计 / 分组内 distinct sku 数（inv 侧口径）；
//       SKU 分组归属 = 其 inv 快照日行的 brand / ax_class
// 条件 5 非 Top Top3 sku（v2.0 新增）: 排除集 = Top 表各 category 组内
//       This Period SLS Units（SUM(product_qty)）降序 DENSE 排名 ≤ 3 的
//       sku（含并列放行；无数量 sku 与空白 category 不入集，对齐 Top 表
//       实际展示行）；排除为 sku 级（Top3 sku 不出现在 OPP 任何行，
//       非排除其所属 category）；口径跟随 Top 模块当前版本（v2.2 起
//       基准 SLS Units），Top 口径调整时本排除集必须同步
// 全局均值净化（关键）: 视觉级度量筛选器（Rank 介于 1 与 3）落地为
//       (category, sku_id) 跨列组合筛选——trade 侧全量（条件 2 分子）必须
//       REMOVEFILTERS(两列) 整体清除（否则被收窄为当前行自身，判定恒不
//       成立）；Top3 排除集构建 = REMOVEFILTERS(sku_id) + category 等值
//       （等值覆盖组合筛选 category 部分、REMOVEFILTERS 清除 sku 部分，
//       同 __CandSkus 模式，v2.1 收窄到当前 category）；inv 侧聚合不受
//       trade 列组合筛选影响（两表无关系），外部筛选（framework / 渠道等）保留
// 渠道: 条件 2 ST% 销售侧受 Platform / Store 筛选、inv 侧不受——分子分母
//       渠道口径不对称为模型物理限制（业务需知悉）；条件 3 判定与均值
//       全量取自 inv 侧，不受渠道筛选影响（v2.0 起原 WC 不对称消失）
// 性能: 每行常数次聚合（trade 1 + inv 桥接 4 + 分组均值 2）+ WC 均值一次
//       分组查询（__WcBySku 物化 + AVERAGEX，上下文跨行相同 → SE 缓存
//       共享）+ Top3 排除集一次当前 category 分组查询与内存排名
//       （v2.1 收窄：候选行数与排名成本由全类目降到单 category；
//       VAR 惰性求值——category 空白短路路径不构建）
// ========================================

// ── This Period 时间区间（销售侧）──
VAR __PeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Min_This[TimeFrame_Min])
VAR __PeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

// ── 期末日期：end period 最后一天 = Max_This 表 TimeFrame_Max（直接单日过滤）──
VAR __EndPeriodDate_This = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

// ── 当前行分组值 ──
VAR __CurrentCategory = SELECTEDVALUE('s02_trade_sku_data_d'[category])
VAR __CurrentSkuId = SELECTEDVALUE('s02_trade_sku_data_d'[sku_id])

// ── 当前行 SKU 判定值：销售侧（行分组筛选自动传导 trade）──
VAR __StAmt =
    CALCULATE(
        SUM('s02_trade_sku_data_d'[net_sales_amt]),
        's02_trade_sku_data_d'[dt] >= __PeriodMin,
        's02_trade_sku_data_d'[dt] <= __PeriodMax
    )

// ── 当前行 SKU 判定值：库存侧（TREATAS sku_id 单列桥接，快照日单日）──
VAR __SkuFilter =
    TREATAS(
        VALUES('s02_trade_sku_data_d'[sku_id]),
        's02_inventory_stock_sales_detail_d'[sku_id]
    )
VAR __EOH =
    CALCULATE(
        SUM('s02_inventory_stock_sales_detail_d'[stock_inv_qty]),
        __SkuFilter,
        's02_inventory_stock_sales_detail_d'[dt] = __EndPeriodDate_This
    )
VAR __InvAmt =
    CALCULATE(
        SUM('s02_inventory_stock_sales_detail_d'[msrp_inv_amt]),
        __SkuFilter,
        's02_inventory_stock_sales_detail_d'[dt] = __EndPeriodDate_This
    )
// ── 条件 3 判定值：weeks_cover 字段直读（v2.0，防御性 MAX，快照日单日）──
VAR __SkuWc =
    CALCULATE(
        MAX('s02_inventory_stock_sales_detail_d'[weeks_cover]),
        __SkuFilter,
        's02_inventory_stock_sales_detail_d'[dt] = __EndPeriodDate_This
    )
VAR __Launch =
    CALCULATE(
        MAX('s02_inventory_stock_sales_detail_d'[launch_time]),
        __SkuFilter,
        's02_inventory_stock_sales_detail_d'[dt] = __EndPeriodDate_This
    )

// ── 条件 1：上架日期（String 前 10 位转日期；BLANK / 解析失败容错）──
VAR __LaunchDate = IFERROR(DATEVALUE(LEFT(__Launch, 10)), BLANK())

// ── 条件 2 均值：trade 侧全量（REMOVEFILTERS 两列清除行筛选与视觉级组合筛选）──
VAR __T_St =
    CALCULATE(
        SUM('s02_trade_sku_data_d'[net_sales_amt]),
        REMOVEFILTERS('s02_trade_sku_data_d'[category], 's02_trade_sku_data_d'[sku_id]),
        's02_trade_sku_data_d'[dt] >= __PeriodMin,
        's02_trade_sku_data_d'[dt] <= __PeriodMax
    )

// ── 条件 2 均值：inv 侧全量（快照日单日；trade 列组合筛选不影响 inv 聚合）──
VAR __T_Inv =
    CALCULATE(
        SUM('s02_inventory_stock_sales_detail_d'[msrp_inv_amt]),
        's02_inventory_stock_sales_detail_d'[dt] = __EndPeriodDate_This
    )
VAR __AvgSt = DIVIDE(__T_St, __T_St + __T_Inv)

// ── 条件 3 均值：全 SKU weeks_cover 算术平均（v2.0 直读值域，v2.3 分组/扩展分离）──
// 各 SKU 直读值（MAX(weeks_cover)，与判定值同逻辑）一次分组查询物化后
// AVERAGEX 求均值——自动跳过 BLANK 行，BLANK 的 SKU 不参与分子与分母
// （参与计算 SKU 数 = 快照日 weeks_cover 非 BLANK 的 distinct sku 数）；
// 上下文 = 快照日 + 外部筛选，跨行相同 → SE 查询缓存共享（v2.1 优化：
// 原 VALUES 迭代 + 逐行上下文转换的 AVERAGEX 为 FE 密集操作）；
// v2.3：SUMMARIZE 仅做分组，扩展列经 CALCULATETABLE 内 ADDCOLUMNS +
// CALCULATE 求值——传统 SUMMARIZE 扩展列在 CALCULATETABLE + TREATAS
// 组合下求值上下文脆弱（扩展列值可能成 BLANK）
VAR __WcBySku =
    CALCULATETABLE(
        ADDCOLUMNS(
            SUMMARIZE(
                's02_inventory_stock_sales_detail_d',
                's02_inventory_stock_sales_detail_d'[sku_id]
            ),
            "@Wc", CALCULATE(MAX('s02_inventory_stock_sales_detail_d'[weeks_cover]))
        ),
        's02_inventory_stock_sales_detail_d'[dt] = __EndPeriodDate_This
    )
VAR __AvgWc = AVERAGEX(__WcBySku, [@Wc])

// ── 条件 4 分组均值：SKU 分组归属（inv 快照日行的 brand / ax_class）──
VAR __MyBrand =
    CALCULATE(
        MAX('s02_inventory_stock_sales_detail_d'[brand]),
        __SkuFilter,
        's02_inventory_stock_sales_detail_d'[dt] = __EndPeriodDate_This
    )
VAR __MyAx =
    CALCULATE(
        MAX('s02_inventory_stock_sales_detail_d'[ax_class]),
        __SkuFilter,
        's02_inventory_stock_sales_detail_d'[dt] = __EndPeriodDate_This
    )
VAR __GrpFilter =
    TREATAS(
        ROW("@B", __MyBrand, "@A", __MyAx),
        's02_inventory_stock_sales_detail_d'[brand],
        's02_inventory_stock_sales_detail_d'[ax_class]
    )
VAR __GrpEOH =
    CALCULATE(
        SUM('s02_inventory_stock_sales_detail_d'[stock_inv_qty]),
        's02_inventory_stock_sales_detail_d'[dt] = __EndPeriodDate_This,
        __GrpFilter
    )
VAR __GrpCnt =
    CALCULATE(
        DISTINCTCOUNT('s02_inventory_stock_sales_detail_d'[sku_id]),
        's02_inventory_stock_sales_detail_d'[dt] = __EndPeriodDate_This,
        __GrpFilter
    )
VAR __GrpAvgEOH = DIVIDE(__GrpEOH, __GrpCnt)

// ── 条件 5：Top Top3 排除集（v2.1 收窄到当前 category 构建）──
// 排除集 = 当前 category 组内 SLS Units 降序 DENSE 排名 ≤ 3 的 sku；
// 无数量 sku 不入集（对齐 Top 表实际展示行）；sku→category 一一对应下
// 与全类目构建等价（Top3 sku 归属唯一 category，跨类目无交集），
// 若存在同一 sku 跨多 category 的数据需回退全类目构建；
// 口径跟随 Top 模块（v2.2 起基准 SLS Units），Top 调整须同步
VAR __TopCandSkus =
    CALCULATETABLE(
        ADDCOLUMNS(
            SUMMARIZE(
                's02_trade_sku_data_d',
                's02_trade_sku_data_d'[sku_id]
            ),
            "@Units", CALCULATE(SUM('s02_trade_sku_data_d'[product_qty]))
        ),
        REMOVEFILTERS('s02_trade_sku_data_d'[sku_id]),
        's02_trade_sku_data_d'[category] = __CurrentCategory,
        's02_trade_sku_data_d'[dt] >= __PeriodMin,
        's02_trade_sku_data_d'[dt] <= __PeriodMax
    )
VAR __TopCand = FILTER(__TopCandSkus, NOT ISBLANK([@Units]))
VAR __TopSet =
    SELECTCOLUMNS(
        FILTER(
            ADDCOLUMNS(
                __TopCand,
                "@Rank", RANKX(__TopCand, [@Units], , DESC, DENSE)
            ),
            [@Rank] <= 3
        ),
        "@TopSku", 's02_trade_sku_data_d'[sku_id]
    )
VAR __NotInTop = NOT CONTAINSROW(__TopSet, __CurrentSkuId)

// ── 五条件判定（除法比较：分母 0 / BLANK → BLANK → 比较不成立）──
VAR __PassLaunch =
    NOT ISBLANK(__LaunchDate)
        && (__EndPeriodDate_This - __LaunchDate) > 14
VAR __PassSt = DIVIDE(__StAmt, __StAmt + __InvAmt) < __AvgSt
VAR __PassWc =
    NOT ISBLANK(__SkuWc) && __SkuWc > __AvgWc
VAR __PassEoh =
    NOT ISBLANK(__EOH) && NOT ISBLANK(__GrpAvgEOH)
        && __EOH > __GrpAvgEOH

RETURN
    IF(
        NOT ISBLANK(__CurrentCategory) && LEN(TRIM(__CurrentCategory)) > 0
            && NOT ISBLANK(__CurrentSkuId) && LEN(TRIM(__CurrentSkuId)) > 0
            && __NotInTop
            && __PassLaunch && __PassSt && __PassWc && __PassEoh,
        1,
        0
    )
```

### 4.2 OPP SKUs SKU Rank（资格集合内组内排名，Top3 筛选依据）

```dax
OPP SKUs SKU Rank =
// ========================================
// 度量值: OPP SKUs SKU Rank
// 中文名: 资格 SKU 集合内 category 组内 EOH 排名（Top3 筛选依据）
// Display Folder: Top & OPP SKUs Analysis\OPP\Rank
// 用途: 当前行 sku_id 在其 category 分组内、**资格 SKU 集合中**按快照日
//       sum(stock_inv_qty) 降序的排名，用于视觉级筛选器「介于 1 与 3」实现
//       每个 category 分组仅保留资格 SKU 中 EOH 前三（口径：先资格过滤
//       再取 Top3，非全量排名后再过滤）
// 依赖: Slicer_Time_Frame_Min_This[TimeFrame_Min] / Slicer_Time_Frame_Max_This[TimeFrame_Max]
//       Slicer_Time_Frame_Max_This[TimeFrame_Max]（end period 最后一天，直接单日过滤）
//       （v2.2 起不再引用 [OPP SKUs Qualify]——自包含五条件判定）
// 排名依据: EOH = 快照日 sum(inv.stock_inv_qty)（库存表为主，学 Top v2.1
//       RANKX 迭代器模式——value 参数迭代外预计算）
// 排名语义: EOH 降序；EOH 相同的 sku 并列同名次（DENSE），「介于 1 与 3」
//       放行名次 ≤ 3 的所有行（含并列）；候选集已限定资格 SKU，
//       无资格 sku 不占名次
// v2.2 单通道重构（OOM 根治）: 原架构「Qualify = 1」+「Rank 介于 1 与 3」
//       双度量筛选器 = 引擎对全部 (category, sku) 分组跑两遍完整度量求值
//       ——Qualify 通道每行约 8 次 SE 查询 + 排除集物化，Rank 通道再跑
//       一遍候选表物化，全表行组规模下 FE 物化叠加 → 内存不足；
//       重构后单通道：五条件判定内嵌本度量（廉价条件先行，VAR 惰性
//       求值——四判定未通过的行**不物化任何候选表**），视觉级
//       「Qualify = 1」筛选器移除（Qualify 度量保留作对数 / 调试，不挂视觉）
// 判定分层（v2.2 惰性短路）:
//       第 0 层（每行少量 SE 查询）: 空白键 / EOH / launch / ST% / WC
//       ——任一不成立直接 BLANK，重表零物化
//       第 1 层（通过第 0 层后）: 条件 4 分组均值（TREATAS(ROW) 4 次聚合）
//       第 2 层（通过前四判定后，仅资格候选行到达）: 条件 5 排除集 +
//       资格集合候选表物化 + RANKX——__CandSkus / __TopCandSkus /
//       __InvAgg / __TradeAgg / __GrpAvg 求值上下文仅含 category +
//       外部筛选 → 同 category 内跨行 SE 缓存共享
// 候选表物化（仅资格候选行触发，每 category 一次、缓存共享）:
//       __CandSkus = 当前 category 内当期有 trade 记录的 sku
//       （VALUES + category 等值 + dt，学 Top v2.1——等值条件覆盖组合筛选
//       的 category 部分，REMOVEFILTERS(sku) 清除 sku 部分）
//       __InvAgg = SUMMARIZE(inv, sku_id, brand, ax_class, @EOH, @InvAmt,
//       @Wc, @Launch)——快照日 + TREATAS 候选集，一次分组查询
//       （@Wc 为 v2.0 weeks_cover 字段直读 MAX）
//       __GrpAvg = SUMMARIZE(inv, brand, ax_class, @GrpEOH, @GrpCnt)——
//       快照日全量，一次分组查询（几十行级，上下文跨行相同 → 缓存共享）
//       __TopCandSkus / __TopSet = Top Top3 排除集（当前 category 一次
//       分组查询 + RANKX 内存排名 ≤ 3，v2.1 收窄）
//       __TradeAgg = trade 候选集 (sku_id, @StAmt) 一次分组查询
//       （v2.1 替代每候选 TREATAS(ROW) 桥接）
//       __CandTable = __InvAgg + ADDCOLUMNS：@StAmt（MAXX 匹配
//       __TradeAgg）+ @GrpAvgEOH（MAXX 匹配 __GrpAvg，纯内存查找）
//       __Qualified = FILTER(__CandTable, 五条件)——判定逻辑与 Qualify
//       度量同构（两处需同步维护，含第 0 层每行判定）
// 全局均值净化: trade 侧全量（条件 2 分子）REMOVEFILTERS(两列) 清除
//       行筛选与视觉级组合筛选（防均值被收窄为当前行自身）；
//       Top3 排除集 = REMOVEFILTERS(sku_id) + category 等值（同
//       __CandSkus 模式，覆盖组合筛选 category 部分 / 清除 sku 部分）
// 空白/无资格拦截: 五条件任一不成立返回 BLANK
//       （「介于 1 与 3」将 BLANK 视为 0 排除在区间外）
// 性能: 每行 = 第 0 层约 7 次 SE 查询（空白键 / EOH / launch / ST / WC /
//       全局均值缓存命中）；候选表物化仅对资格候选行触发且同 category
//       缓存共享——非资格行（绝大多数）成本从「重表物化」降到「7 次标量
//       聚合」，全表两通道 → 单通道
// v2.3 候选物化加固（Rank 全 1 修复）: 实测 Skirt 组 EOH 13/11/10/10 全行
//       Rank 1——RANKX 空候选表签名（__Qualified 为空时无值可比较，全行
//       返回 1）。两处缺陷：① __TradeAgg 缺 REMOVEFILTERS(sku_id)——视觉
//       行组当前 sku 筛选泄漏进 CALCULATETABLE，__TradeAgg 仅含当前 sku，
//       其余候选 @StAmt 全 BLANK（候选 ST% 判定退化 0 < 均值恒真，高售罄
//       候选被误放行）；② 全部候选物化（__WcBySku / __TopCandSkus /
//       __InvAgg / __TradeAgg / __GrpAvg）改「SUMMARIZE 仅分组列 +
//       CALCULATETABLE(ADDCOLUMNS(..., CALCULATE(...)), 筛选参数)」——
//       传统 SUMMARIZE 扩展列在 CALCULATETABLE + TREATAS 组合下求值
//       上下文脆弱，扩展列值一旦成 BLANK，资格 FILTER 筛光全部候选 →
//       空表 → RANKX 全 1；调试配方见 §8 注意事项 19
// v2.4 候选域与行域对齐（全 1 真根因）: v2.3 后仍全 1——时间切片器为
//       断开维度仅 DAX 筛选 → 视觉行组 (category, sku) 不受 dt 筛选、
//       全历史 sku 照常显示，而 __CandSkus 沿习 Top v2.1 带本期 dt 筛选
//       → 本期无 trade 记录的 sku 缺席候选表，零销售 category（OPP 典型
//       场景）候选表为空 → __Qualified 空 → RANKX 全 1、Top3 截断失效；
//       修复：__CandSkus 去 dt 筛选（候选域 = 当前 category 全部 sku，
//       外部筛选保留，对齐行域）——排名基准快照日 EOH 为时点值本就
//       不依赖本期销售；dt 仅保留于 __TradeAgg（@StAmt 当期，无记录
//       候选 BLANK → ST% = 0 < 均值，与第 0 层一致）与 __TopCandSkus
//       （排除集当期 SLS Units 口径）；Top 模块不受影响（其排名基准
//       即当期 SLS Units，候选域滤 dt 与基准同源）
// ========================================

// ── This Period 时间区间（销售侧）──
VAR __PeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Min_This[TimeFrame_Min])
VAR __PeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

// ── 期末日期：end period 最后一天 = Max_This 表 TimeFrame_Max（直接单日过滤）──
VAR __EndPeriodDate_This = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

// ── 当前行分组值 ──
VAR __CurrentCategory = SELECTEDVALUE('s02_trade_sku_data_d'[category])
VAR __CurrentSkuId = SELECTEDVALUE('s02_trade_sku_data_d'[sku_id])

// ── 当前行判定值：第 0 层（每行少量 SE 查询，候选表不物化）──
// __SkuFilter 单列桥接；__StAmt 行分组筛选自动传导 trade
VAR __SkuFilter =
    TREATAS(
        VALUES('s02_trade_sku_data_d'[sku_id]),
        's02_inventory_stock_sales_detail_d'[sku_id]
    )
VAR __CurrentEOH =
    CALCULATE(
        SUM('s02_inventory_stock_sales_detail_d'[stock_inv_qty]),
        __SkuFilter,
        's02_inventory_stock_sales_detail_d'[dt] = __EndPeriodDate_This
    )
VAR __StAmt =
    CALCULATE(
        SUM('s02_trade_sku_data_d'[net_sales_amt]),
        's02_trade_sku_data_d'[dt] >= __PeriodMin,
        's02_trade_sku_data_d'[dt] <= __PeriodMax
    )
VAR __InvAmt =
    CALCULATE(
        SUM('s02_inventory_stock_sales_detail_d'[msrp_inv_amt]),
        __SkuFilter,
        's02_inventory_stock_sales_detail_d'[dt] = __EndPeriodDate_This
    )
VAR __SkuWc =
    CALCULATE(
        MAX('s02_inventory_stock_sales_detail_d'[weeks_cover]),
        __SkuFilter,
        's02_inventory_stock_sales_detail_d'[dt] = __EndPeriodDate_This
    )
VAR __Launch =
    CALCULATE(
        MAX('s02_inventory_stock_sales_detail_d'[launch_time]),
        __SkuFilter,
        's02_inventory_stock_sales_detail_d'[dt] = __EndPeriodDate_This
    )
VAR __LaunchDate = IFERROR(DATEVALUE(LEFT(__Launch, 10)), BLANK())

// ── 全局均值（第 0 层标量，求值上下文跨行相同 → SE 缓存跨行共享）──
VAR __T_St =
    CALCULATE(
        SUM('s02_trade_sku_data_d'[net_sales_amt]),
        REMOVEFILTERS('s02_trade_sku_data_d'[category], 's02_trade_sku_data_d'[sku_id]),
        's02_trade_sku_data_d'[dt] >= __PeriodMin,
        's02_trade_sku_data_d'[dt] <= __PeriodMax
    )
VAR __T_Inv =
    CALCULATE(
        SUM('s02_inventory_stock_sales_detail_d'[msrp_inv_amt]),
        's02_inventory_stock_sales_detail_d'[dt] = __EndPeriodDate_This
    )
VAR __AvgSt = DIVIDE(__T_St, __T_St + __T_Inv)
// ── 条件 3 均值：全 SKU weeks_cover 算术平均（v2.0 直读值域，v2.3 分组/扩展分离）──
VAR __WcBySku =
    CALCULATETABLE(
        ADDCOLUMNS(
            SUMMARIZE(
                's02_inventory_stock_sales_detail_d',
                's02_inventory_stock_sales_detail_d'[sku_id]
            ),
            "@Wc", CALCULATE(MAX('s02_inventory_stock_sales_detail_d'[weeks_cover]))
        ),
        's02_inventory_stock_sales_detail_d'[dt] = __EndPeriodDate_This
    )
VAR __AvgWc = AVERAGEX(__WcBySku, [@Wc])

RETURN
IF(
    // ── 第 0 层短路（VAR 惰性求值：任一不成立，下方候选表全部不物化）──
    // 空白键 → 条件 1 launch → 条件 2 ST% → 条件 3 WC，全部每行标量聚合
    NOT ISBLANK(__CurrentCategory) && LEN(TRIM(__CurrentCategory)) > 0
        && NOT ISBLANK(__CurrentSkuId) && LEN(TRIM(__CurrentSkuId)) > 0
        && NOT ISBLANK(__CurrentEOH)
        && NOT ISBLANK(__LaunchDate)
        && (__EndPeriodDate_This - __LaunchDate) > 14
        && DIVIDE(__StAmt, __StAmt + __InvAmt) < __AvgSt
        && NOT ISBLANK(__SkuWc) && __SkuWc > __AvgWc,

    // ── 第 1 层：条件 4 分组均值（TREATAS(ROW) 4 次聚合）──
    VAR __MyBrand =
        CALCULATE(
            MAX('s02_inventory_stock_sales_detail_d'[brand]),
            __SkuFilter,
            's02_inventory_stock_sales_detail_d'[dt] = __EndPeriodDate_This
        )
    VAR __MyAx =
        CALCULATE(
            MAX('s02_inventory_stock_sales_detail_d'[ax_class]),
            __SkuFilter,
            's02_inventory_stock_sales_detail_d'[dt] = __EndPeriodDate_This
        )
    VAR __GrpFilter =
        TREATAS(
            ROW("@B", __MyBrand, "@A", __MyAx),
            's02_inventory_stock_sales_detail_d'[brand],
            's02_inventory_stock_sales_detail_d'[ax_class]
        )
    VAR __GrpEOH =
        CALCULATE(
            SUM('s02_inventory_stock_sales_detail_d'[stock_inv_qty]),
            's02_inventory_stock_sales_detail_d'[dt] = __EndPeriodDate_This,
            __GrpFilter
        )
    VAR __GrpCnt =
        CALCULATE(
            DISTINCTCOUNT('s02_inventory_stock_sales_detail_d'[sku_id]),
            's02_inventory_stock_sales_detail_d'[dt] = __EndPeriodDate_This,
            __GrpFilter
        )
    VAR __GrpAvgEOH = DIVIDE(__GrpEOH, __GrpCnt)

    RETURN
    IF(
        NOT ISBLANK(__GrpAvgEOH) && __CurrentEOH > __GrpAvgEOH,

        // ── 第 2 层：条件 5 排除集（当前 category 收窄构建，v2.1）──
        // 仅通过前四判定的行到达此处（资格候选规模），同 category 缓存共享
        VAR __TopCandSkus =
            CALCULATETABLE(
                ADDCOLUMNS(
                    SUMMARIZE(
                        's02_trade_sku_data_d',
                        's02_trade_sku_data_d'[sku_id]
                    ),
                    "@Units", CALCULATE(SUM('s02_trade_sku_data_d'[product_qty]))
                ),
                REMOVEFILTERS('s02_trade_sku_data_d'[sku_id]),
                's02_trade_sku_data_d'[category] = __CurrentCategory,
                's02_trade_sku_data_d'[dt] >= __PeriodMin,
                's02_trade_sku_data_d'[dt] <= __PeriodMax
            )
        VAR __TopCand = FILTER(__TopCandSkus, NOT ISBLANK([@Units]))
        VAR __TopSet =
            SELECTCOLUMNS(
                FILTER(
                    ADDCOLUMNS(
                        __TopCand,
                        "@Rank", RANKX(__TopCand, [@Units], , DESC, DENSE)
                    ),
                    [@Rank] <= 3
                ),
                "@TopSku", 's02_trade_sku_data_d'[sku_id]
            )

        RETURN
        IF(
            NOT CONTAINSROW(__TopSet, __CurrentSkuId),

            // ── 资格集合候选表物化 + 排名（仅全五条件通过的行到达）──
            // 当前行通过全部五判定 → 必在 __Qualified 中（同判定同候选域）；
            // 候选表 = 当前 category 全部 sku 的判定列（排名需要完整资格集合）
            // ── v2.4 修复：候选 sku 域不滤 dt，对齐视觉行域 ──
            // 时间切片器为断开维度，行组 (category, sku) 不受 dt 筛选、全历史
            // sku 照常显示；候选域若滤 dt，本期无 trade 记录的 sku 全部缺席
            // 候选表 → 零销售 category 候选表为空 → RANKX 空表全行返回 1
            // （全 1 真根因）；排名基准为快照日 EOH（时点值），不依赖本期销售；
            // dt 仅约束 __TradeAgg / __TopCandSkus（销售侧当期口径），
            // 无本期记录的候选 @StAmt 为 BLANK → ST% = 0 < 均值
            // （与行级第 0 层判定一致）；framework 等外部筛选经关系保留
            VAR __CandSkus =
                CALCULATETABLE(
                    VALUES('s02_trade_sku_data_d'[sku_id]),
                    REMOVEFILTERS('s02_trade_sku_data_d'[sku_id]),
                    's02_trade_sku_data_d'[category] = __CurrentCategory
                )
            VAR __InvAgg =
                CALCULATETABLE(
                    ADDCOLUMNS(
                        SUMMARIZE(
                            's02_inventory_stock_sales_detail_d',
                            's02_inventory_stock_sales_detail_d'[sku_id],
                            's02_inventory_stock_sales_detail_d'[brand],
                            's02_inventory_stock_sales_detail_d'[ax_class]
                        ),
                        "@EOH", CALCULATE(SUM('s02_inventory_stock_sales_detail_d'[stock_inv_qty])),
                        "@InvAmt", CALCULATE(SUM('s02_inventory_stock_sales_detail_d'[msrp_inv_amt])),
                        "@Wc", CALCULATE(MAX('s02_inventory_stock_sales_detail_d'[weeks_cover])),
                        "@Launch", CALCULATE(MAX('s02_inventory_stock_sales_detail_d'[launch_time]))
                    ),
                    's02_inventory_stock_sales_detail_d'[dt] = __EndPeriodDate_This,
                    TREATAS(__CandSkus, 's02_inventory_stock_sales_detail_d'[sku_id])
                )
            VAR __TradeAgg =
                CALCULATETABLE(
                    ADDCOLUMNS(
                        SUMMARIZE(
                            's02_trade_sku_data_d',
                            's02_trade_sku_data_d'[sku_id]
                        ),
                        "@StAmt", CALCULATE(SUM('s02_trade_sku_data_d'[net_sales_amt]))
                    ),
                    // v2.3 修复：缺 REMOVEFILTERS(sku_id) 时视觉行组当前 sku
                    // 筛选泄漏 → __TradeAgg 仅含当前 sku，其余候选 @StAmt 全 BLANK
                    REMOVEFILTERS('s02_trade_sku_data_d'[sku_id]),
                    's02_trade_sku_data_d'[dt] >= __PeriodMin,
                    's02_trade_sku_data_d'[dt] <= __PeriodMax,
                    TREATAS(__CandSkus, 's02_trade_sku_data_d'[sku_id])
                )
            VAR __GrpAvg =
                CALCULATETABLE(
                    ADDCOLUMNS(
                        SUMMARIZE(
                            's02_inventory_stock_sales_detail_d',
                            's02_inventory_stock_sales_detail_d'[brand],
                            's02_inventory_stock_sales_detail_d'[ax_class]
                        ),
                        "@GrpEOH", CALCULATE(SUM('s02_inventory_stock_sales_detail_d'[stock_inv_qty])),
                        "@GrpCnt", CALCULATE(DISTINCTCOUNT('s02_inventory_stock_sales_detail_d'[sku_id]))
                    ),
                    's02_inventory_stock_sales_detail_d'[dt] = __EndPeriodDate_This
                )
            VAR __CandTable =
                ADDCOLUMNS(
                    __InvAgg,
                    "@StAmt",
                        VAR __S = 's02_inventory_stock_sales_detail_d'[sku_id]
                        RETURN
                            MAXX(
                                FILTER(__TradeAgg, 's02_trade_sku_data_d'[sku_id] = __S),
                                [@StAmt]
                            ),
                    "@GrpAvgEOH",
                        VAR __B = 's02_inventory_stock_sales_detail_d'[brand]
                        VAR __A = 's02_inventory_stock_sales_detail_d'[ax_class]
                        VAR __GrpRow =
                            FILTER(
                                __GrpAvg,
                                's02_inventory_stock_sales_detail_d'[brand] = __B
                                    && 's02_inventory_stock_sales_detail_d'[ax_class] = __A
                            )
                        RETURN
                            DIVIDE(
                                MAXX(__GrpRow, [@GrpEOH]),
                                MAXX(__GrpRow, [@GrpCnt])
                            )
                )
            VAR __Qualified =
                FILTER(
                    __CandTable,
                    VAR __S = 's02_inventory_stock_sales_detail_d'[sku_id]
                    VAR __LD = IFERROR(DATEVALUE(LEFT([@Launch], 10)), BLANK())
                    RETURN
                        NOT ISBLANK(__LD)
                            && (__EndPeriodDate_This - __LD) > 14
                            && DIVIDE([@StAmt], [@StAmt] + [@InvAmt]) < __AvgSt
                            && NOT ISBLANK([@Wc]) && [@Wc] > __AvgWc
                            && [@EOH] > [@GrpAvgEOH]
                            && NOT CONTAINSROW(__TopSet, __S)
                )

            RETURN
                RANKX(
                    __Qualified,
                    [@EOH],
                    __CurrentEOH,
                    DESC,
                    DENSE
                )
        )
    )
)
```

### 4.3 OPP SKUs Sort Key（表格行排序键，库存量编码）

> v2.1 **修复分组表头排序缺陷**：v1.0/v2.0 结构沿袭旧写法（sku_id 空白即 BLANK 拦截），分组表头上下文（sku_id 不在作用域）排序键恒 BLANK → 全部块头排序键并列 → category 块序回退字母序（实测 Belts < Headwear < Pants / Luggage/Bags < Pants 均为字母序），块序 EOH 降序失效——Top 模块 v2.3 同源缺陷漏移植。修复为三上下文结构（同 Top v2.5）：①category 空白（总计行）→ BLANK；②分组表头 → 块键 -(CatEOH × 1e6)，块头升序 = 类别 EOH 降序；③sku 行无库存记录 → BLANK（空行防线，禁止删除）。排序依据仍为 EOH 库存量编码；weeks_cover 直读与 Top Top3 排除落位资格 / 排名筛选层，排序键不感知。

```dax
OPP SKUs Sort Key =
// ========================================
// 度量值: OPP SKUs Sort Key
// 中文名: 表格行排序键（库存量编码，非排名）
// Display Folder: Top & OPP SKUs Analysis\OPP\Rank
// 用途: 表格行排序依据——category 块按快照日 EOH 合计降序（库存最大的
//       category 在最前），块内 sku 按 EOH 降序；表格按此度量值「升序」
//       排列（负号翻转实现降序效果）
// 核心思路: 排序不需要排名，库存数量本身就是顺序（学 Top v2.1 金额编码）
//       排序键 = -(category EOH 合计 × 1,000,000 + SKU EOH)
//       负号使库存越大 → 值越小 → 升序排列时越靠前
// 编码: L1 = category EOH 合计 × 1,000,000（保证 category 块间不交叉）
//       L2 = SKU EOH × 1（块内排序）
//       权重前提：单 SKU EOH < 1,000,000（库存件数；超限改 1e9）
//       EOH 为数量口径非负，无负值翻转问题
// 三上下文（v2.1 修复，同 Top v2.5，禁止回退旧写法）:
//       ① category 空白（总计行 / 空白组）→ BLANK
//       ② 分组表头（sku_id 不在作用域，__IsSkuRow = FALSE）→ SkuEOH 记 0，
//          返回类别块键 -(CatEOH × 1e6)——块头升序 = 类别 EOH 降序；
//          旧写法 sku 空白即 BLANK → 块头排序键全部并列 → 块序回退
//          字母序（实测根因，Top v2.3 同源缺陷）
//       ③ sku 行且 SkuEOH BLANK（快照日无库存记录）→ BLANK（空行防线，
//          禁止删除——与 Rank「介于 1 与 3」下界构成双保险）
// 性能: 无需 RANKX / RANK，仅 2 次 CALCULATE SUM（SE 层直接聚合）；
//       __CatEOH 为 VAR 惰性求值，被短路路径不计算
//       排序用本度量值，筛选用 [OPP SKUs Qualify] + [OPP SKUs SKU Rank]，
//       三者各司其职，互不嵌套
// category 上卷: TREATAS(VALUES(trade[category]), inv[category]) 桥接——
//       行/组合筛选下 VALUES(trade[category]) = 当前行 category（单值），
//       组合筛选的 sku 部分不桥接自然忽略（净化完成）；分组表头上下文
//       category 筛选保留、sku 筛选不存在 → 同样正确上卷
// ========================================

// ── 当前行分组值 ──
VAR __CurrentCategory = SELECTEDVALUE('s02_trade_sku_data_d'[category])
VAR __CurrentSkuId = SELECTEDVALUE('s02_trade_sku_data_d'[sku_id])

RETURN
IF(
    // ── 短路 ①：category 空白或空字符串直接退出（总计行 / 空白组）──
    ISBLANK( __CurrentCategory )
        || LEN( TRIM( __CurrentCategory ) ) = 0,
    BLANK(),

    // ── 期末日期：end period 最后一天 = Max_This 表 TimeFrame_Max（直接单日过滤）──
    VAR __EndPeriodDate_This = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

    // ── 当前行是否 sku 行（分组表头上下文 sku_id 不在作用域）──
    VAR __IsSkuRow =
        NOT ISBLANK( __CurrentSkuId )
            && LEN( TRIM( __CurrentSkuId ) ) > 0

    // ── 当前行 SKU EOH（快照日，TREATAS sku_id 单列桥接；分组头取 0）──
    // 分组表头 → SkuEOH = 0 → 排序键退化为 -(CatEOH × 1e6) 类别块键，
    // 块头升序 = 类别 EOH 降序（v2.1 修复）
    VAR __SkuEOH =
        IF(
            __IsSkuRow,
            CALCULATE(
                SUM('s02_inventory_stock_sales_detail_d'[stock_inv_qty]),
                TREATAS(
                    VALUES('s02_trade_sku_data_d'[sku_id]),
                    's02_inventory_stock_sales_detail_d'[sku_id]
                ),
                's02_inventory_stock_sales_detail_d'[dt] = __EndPeriodDate_This
            ),
            0
        )

    // ── Category EOH 合计（category 单值桥接 inv 上卷）──
    VAR __CatEOH =
        CALCULATE(
            SUM('s02_inventory_stock_sales_detail_d'[stock_inv_qty]),
            TREATAS(
                VALUES('s02_trade_sku_data_d'[category]),
                's02_inventory_stock_sales_detail_d'[category]
            ),
            's02_inventory_stock_sales_detail_d'[dt] = __EndPeriodDate_This
        )

    RETURN
    IF(
        // ── 短路 ③：sku 行但快照日无库存记录 → BLANK（空行防线，禁止删除）──
        __IsSkuRow && ISBLANK( __SkuEOH ),
        BLANK(),
        IF(
            NOT ISBLANK( __CatEOH ),
            -( __CatEOH * 1000000 + __SkuEOH )
        )
    )
)
```

### 4.4 复用度量清单（Top SKUs 系列）

OPP 表格展示指标与属性列直接复用 Top 部分已建度量（行分组双列同为 trade[category] + trade[sku_id]，行分组筛选传导与桥接机制完全同构，无需新建）：

| 展示列         | 复用度量（见 Top_SKUs_Analysis_Table.md）                              |
| -------------- | ---------------------------------------------------------------------- |
| Product Photo  | Top SKUs Product Photo（数据类别 = 图像 URL）                          |
| Product Type   | Top SKUs Product Type                                                  |
| Price          | Top SKUs Price                                                         |
| Predictive Buy | Top SKUs Predictive Buy（整数比较，1 → "Y"、0 → "N"）                  |
| SLS Units      | Top SKUs SLS Units Display（依赖 Top SKUs SLS Units Value）            |
| EOH            | Top SKUs EOH Display（依赖 Top SKUs EOH Value，TREATAS 桥接）          |
| Weeks Cover    | Top SKUs Weeks Cover Display（依赖 Top SKUs Weeks Cover Value，v2.2 起字段直读——与 OPP 条件 3 判定值同源） |
| 对数辅助       | Top SKUs SLS Amt Value / Display（OPP 不参与排序，对数时拖入）         |

- 复用度量的时间口径与 OPP 判定一致（SLS 侧 this period、库存侧快照日）——**Weeks Cover 展示与条件 3 判定同源直读（快照日 MAX(weeks_cover)），对数可直接互验**；v2.0 起判定与展示完全同口径
- **属性列零销售行兜底（Top v2.6）**：Product Photo / Product Type / Price / Predictive Buy / SPU ID 的"最新日期"在 This Period 区间无记录时回退取该组合全历史 MAX(dt) 当天值——v2.4 起本期零销售 sku 可凭 EOH 前三展示（ST% = 0 恒低于均值天然过条件 2），其属性列凭此回退展示最近已知值，全历史无记录 / 回退日当天全空白仍 BLANK
- 列头在视觉对象中可重命名（度量名不改）；如后续要求 OPP 指标集独立演化（如展示 ST%），再按需新建 OPP 前缀度量，勿改 Top 度量语义

---

## 5. 度量值清单

| #  | 度量值             | 类型                                      | 用于视觉对象                 |
| -- | ------------------ | ----------------------------------------- | ---------------------------- |
| 1  | OPP SKUs Qualify   | 资格判定布尔（五条件，1 / 0；v2.2 对数 / 调试辅助，不挂视觉） | 对数核对（临时拖入）          |
| 2  | OPP SKUs SKU Rank  | RANKX 自包含（五条件资格 + 组内 EOH 降序，DENSE 并列；v2.2 单通道） | 视觉级筛选器「介于 1 与 3」  |
| 3  | OPP SKUs Sort Key  | 库存量编码排序键（三上下文，v2.1 修复块序） | 行排序依据（升序）           |
| 4  | 展示指标 9 个      | 复用 Top SKUs 系列（见 §4.4）             | 值区域                       |

- 新建度量 3 个（v2.0 为度量内部逻辑调整，名称与数量不变），全部存放于 `_Measures` 隐藏表；Display Folder：`Top & OPP SKUs Analysis\OPP\Qualify`、`Top & OPP SKUs Analysis\OPP\Rank`
- 与 Top 部分合计：Top 14 个 + OPP 新建 3 个（展示指标复用 9 个不重复建）——子模块九共 17 个独立度量

---

## 6. 视觉对象配置

### 6.1 表格

| 配置项           | 内容                                                                                        |
| ---------------- | ------------------------------------------------------------------------------------------- |
| 视觉对象类型     | 表格（平铺，无层级小计；总计行交由视觉对象默认生成，可按需关闭）                             |
| 字段井（行分组） | s02_trade_sku_data_d[category]、s02_trade_sku_data_d[sku_id]                                |
| 视觉级筛选器 1   | Slicer_Framework[framework] = Foundation（前置筛选，一对多关系自动传导双表）                 |
| 视觉级筛选器 2   | OPP SKUs SKU Rank 介于 1 与 3（**含下界**——五条件资格 + 组内 EOH 前三单通道；v2.2 起 Qualify 筛选器移除，勿恢复） |
| 视觉级筛选器 3   | s02_trade_sku_data_d[category] 不为空                                                       |
| 视觉级筛选器 4   | s02_trade_sku_data_d[sku_id] 不为空（双保险）                                               |
| 行排序           | OPP SKUs Sort Key 升序（列标题点击排序；Sort Key 列须留在值区域，收窄列宽）                  |

值区域建议列序（EOH 为 OPP 核心指标前置）：

| 顺序 | 列                  | 度量                                                          |
| ---- | ------------------- | ------------------------------------------------------------- |
| 1    | 图片                | Top SKUs Product Photo（数据类别 = 图像 URL）                 |
| 2    | 类型 / 价格 / 标签  | Top SKUs Product Type、Top SKUs Price、Top SKUs Predictive Buy |
| 3    | EOH（核心指标）     | Top SKUs EOH Display                                          |
| 4    | SLS Units           | Top SKUs SLS Units Display                                    |
| 5    | Weeks Cover         | Top SKUs Weeks Cover Display                                  |
| 6    | SKU Rank（可选）    | OPP SKUs SKU Rank（核对组内排名）                             |
| 7    | Sort Key（排序依据）| OPP SKUs Sort Key（置于最后并收窄列宽）                       |

### 6.2 按钮切换与切片器

- **按钮切换**：TOP / OPP 两按钮经书签控制两张表格显隐（每按钮一书签：显示对应表格 + 隐藏另一张；同 Item Stockout SPU / SKU 切换模式）
- **切片器**：同 Top §6.2（Slicer_Time_Frame 主时间 / Slicer_Framework 前置 / Platform / Store / 币种）——OPP 判定的渠道不对称见注意事项 9

---

## 7. 验证方法

测试 SQL 本轮未要求输出，还原要点如下（可按需补 test_OPP_SKUs_Analysis_Table.sql，字面量直嵌）：

| 指标 / 机制   | 测试 SQL 还原                                                                                                                          |
| ------------- | -------------------------------------------------------------------------------------------------------------------------------------- |
| inv_agg       | inv WHERE dt = 快照日 GROUP BY sku_id, brand, ax_class：SUM(stock_inv_qty) EOH / SUM(msrp_inv_amt) / MAX(weeks_cover) WC（v2.0 直读）/ MAX(launch_time) |
| grp_avg       | inv WHERE dt = 快照日 GROUP BY brand, ax_class：SUM(stock_inv_qty) / COUNT(DISTINCT sku_id)                                             |
| trade_agg     | trade WHERE framework='Foundation' AND dt ∈ This GROUP BY sku_id, category：SUM(ROUND(product_qty×sales_price,6)) sls_amt / SUM(product_qty) sls_unit |
| 全局均值      | ST% 均值 = SUM(销售) / (SUM(销售) + SUM(msrp_inv_amt))（两侧各自全量）；WC 均值 = AVG(weeks_cover)（快照日，AVG 自动忽略 NULL——参与计算 SKU 数 = 非 NULL 行数） |
| Top3 排除集   | 各 category 组内 DENSE_RANK() OVER (PARTITION BY category ORDER BY sls_unit DESC) ≤ 3 且 sls_unit 非空 → sku 全集（Top 表实际展示行；DAX 侧按当前 category 收窄构建，sku→category 一一对应下等价） |
| 资格判定      | JOIN 三 CTE（on sku_id）+ 五条件：DATEDIFF(快照日, DATE(launch_time), day) > 14 && ST% < 均值 && WC > 均值 && EOH > 分组均值 && sku NOT IN Top3 排除集 |
| Rank / Top3   | DENSE_RANK() OVER (PARTITION BY category ORDER BY EOH DESC) on 资格 SKU 集合；外层 WHERE rank <= 3                                       |
| Sort Key / 行序 | category EOH 合计降序（GROUP BY category）+ 块内 EOH 降序；ORDER BY category_eoh DESC, eoh DESC（v2.1 分组表头返回块键，块序修复） |
| 展示列        | 同 Top 测试还原（属性最新日期拼接 / 币种换算不在 SQL 范围，输出原值）                                                                   |

- NULL 语义对齐 DAX：ST% 的 DIVIDE 边界（分母 0 / NULL → NULL → 判定不成立）；WC 直读 NULL → 判定不成立；launch_time NULL / 解析失败 → 无资格；EOH 无 inv 记录 → 无资格
- 参数区（对齐同看板惯例）：framework = 'Foundation'、Platform / Store 全选（等价不筛选）、This Period dt ∈ ['2026-03-29', '2026-07-25']、快照日 '2026-07-25'
- 对数路径：PBI 表格行（资格 + 每 category 3 行、Sort Key 升序）vs SQL 资格集合（五条件过滤 + rank ≤ 3）结果按 category_eoh DESC, eoh DESC 逐列比对；另核对 OPP 全表无任何 Top 表 Top3 行（跨 category 逐一检查 sku_id 不在排除集）

---

## 8. 注意事项

1. **Top3 在资格集合内取（口径核心）**：先五条件过滤（四判定 + Top Top3 sku 排除）、再组内 EOH 排名取前三——Rank 候选集内嵌资格过滤（FILTER 后 RANKX）；非「全量排名后按 Qualify 过滤」（后者语义为全量 EOH 前三 ∩ 资格行，不符口径）
2. **均值与排除集净化（关键防护）**：视觉级 Qualify / Rank 筛选器落地为 (category, sku_id) 跨列组合筛选——trade 侧全量均值（条件 2 分子）必须 `REMOVEFILTERS(两列)` 整体清除，否则均值被收窄为当前行自身（判定恒不成立）；Top3 排除集构建用 REMOVEFILTERS(sku_id) + category 等值（同 __CandSkus 模式——等值覆盖组合筛选 category 部分、REMOVEFILTERS 清除 sku 部分，v2.1 起）；inv 侧聚合不受 trade 列组合筛选影响（两表无关系），无需清除
3. **Qualify 与 Rank 判定同构双写**：五条件判定在两个度量中各写一份（Qualify 当前行版 / Rank 候选表版）——DAX 无表达式共享机制，**口径调整必须两处同步修改**（含全局均值口径、WC 直读逻辑与 Top3 排除集）
4. **两条件均值口径不同（勿互改）**：条件 2 均值 = 比值均值（trade / inv 两侧各自全量 sum 后相除，SKU 域独立不对齐——原始口径）；条件 3 均值 = SKU 值算术平均（v2.0，Σ 直读值 ÷ 参与计算 SKU 数，BLANK 不参与分子分母）——条件 3 原"分子分母各自全量汇总后相除"的比值均值随 WC 直读废止
5. **零销售 sku 边界变化（v2.0 需知悉）**：行值域仍为 trade 行字段（无当期 trade 记录的 sku 不出现）；WC 改直读后条件 3 不再天然排除零销售 sku（原 product_qty = 0 分母短路废止，数仓预计算 weeks_cover 可为高值）——零销售高库存 sku 若满足其余条件将通过判定，业务需知悉；如需恢复排除须另行确认口径
6. **launch_time 解析**：String 前 10 位 DATEVALUE（"2022-09-02 00:00:00.000" → 2022-09-02）；BLANK / 格式异常经 IFERROR 容错为无资格；判定基准日为 end period 最后一天（= Max_This 表 TimeFrame_Max，直接单日过滤）
7. **条件 4 分组口径**：分组键 inv[brand] + inv[ax_class]（同表，Label / CLASS）；分组 EOH 合计与 SKU 个数均为快照日 inv 侧口径（分组内有库存记录的 distinct sku 数）——SKU 分组归属取 inv 快照日行值（勿改用 trade 侧 brand / ax_class，避免与 EOH 均值域错位）
8. **排序键三上下文（v2.1 修复，禁止回退）**：分组表头上下文（sku_id 不在作用域）必须返回类别块键 -(CatEOH × 1e6)——旧写法 sku 空白即 BLANK 使块头排序键全部并列、块序回退字母序（实测根因，Top v2.3 同源缺陷）；sku 行快照日无库存 → BLANK 空行防线禁止删除；权重前提单 SKU EOH < 1,000,000（超限改 1e9）；category 块间按快照日库存量降序（如业务要求其他块序依据，仅调 L1 聚合）；排除逻辑落位资格 / 排名筛选层，被排除行不进入视觉，无排序求值
9. **渠道口径不对称**：trade 侧（ST% 分子 / 全量均值分子 / Top3 排除集 SLS Units）受 Platform / Store 筛选，inv 侧（EOH / 库存金额 / WC 判定值与均值）不受——ST% 分子分母渠道不对称为模型物理限制，业务需知悉；**条件 3 自 v2.0 起判定值与均值全量取自 inv 侧，原 WC 渠道口径不对称消失**
10. **性能结构（v2.2 单通道 + 分层惰性短路）**：视觉级仅 Rank 一条度量筛选器（Qualify 筛选器移除——双通道对全行组两遍完整求值，OOM 根源）；Rank 第 0 层每行约 7 次 SE 查询（空白键 / EOH / launch / ST% / WC + 缓存命中的全局均值），任一不成立 → BLANK、候选表零物化——非资格行（绝大多数）不触发重表；第 2 层候选表（__CandSkus / __InvAgg / __TradeAgg / __TopSet / __GrpAvg）仅资格候选行触发且求值上下文仅含 category + 外部筛选 → 同 category 跨行 SE 缓存共享；__WcBySku / __T_St / __T_Inv 上下文跨行相同 → 全局缓存共享；若仍卡顿 / OOM 递进：Top3 排除标签与资格标签数仓预计算（终极方案，判定全部下沉源侧）/ 建 (dt, sku_id, brand, ax_class) 聚合表 / 缩短 This Period 默认区间
11. **DENSE 并列语义**：EOH 相同的资格 SKU 共享名次，名次 ≤ 3 的行可能超过 3 行 / 分组（含并列放行，与 Top v2.1 一致）；Top3 排除集同样 DENSE 含并列（≤ 3 放行并列行，与 Top 表实际展示一致）
12. **复用度量边界**：展示指标复用 Top SKUs 系列 9 个（行分组传导同构成立）；OPP 独立演化指标集时新建 OPP 前缀度量，勿改 Top 度量语义
13. **ST% 仅参与判定不展示**（口径文档 §633 说明）；如需展示可后续新增（金额口径 net_sales_amt / (net_sales_amt + msrp_inv_amt)）
14. **期末时点口径**：期末日期 = end period 最后一天（Max_This 表 TimeFrame_Max，直接单日过滤）；快照表按日存储只取单日，对区间求和会重复计数库存；该日快照缺数时判定值 / 指标为空，不回退取范围内最近一天；weeks_cover 直读同口径（快照日单日）
15. **函数版本**：RANKX / CONTAINSROW 全版本可用（无 RANK 窗口函数版本要求）；复用 Top 度量的 predictive_buy 为整数比较（同 Top 注意事项 8）
16. **口径与语法**：口径文档中定义的所有指标必须遵守其数据类型与数据格式，与解决方案存在争议时一切以口径文档为准；DAX 文本常量使用双引号，单引号仅用于表名，列名使用方括号
17. **Top3 排除集口径跟随（关键）**：排除集口径 = Top 模块当前实现（v2.2 起基准 This Period SLS Units 降序、DENSE、名次 ≤ 3、无数量行不入集）——**Top 模块口径再调整（基准指标 / 名次语义）时本模块排除集必须同步**，否则 OPP 会漏排 / 误排 Top 表实际展示的 sku；排除为 **sku 级**（Top3 sku 在 OPP 全表任何 category 行均不出现，非排除其所属 category）；v2.1 起排除集按当前 category 收窄构建——sku→category 一一对应下与全类目并集等价，**若存在同一 sku 跨多 category 的数据须回退全类目构建**（v2.0 写法）
18. **weeks_cover 直读防御性 MAX**：与 Top v2.2 / Item Stockout v2.6 同款——快照日同 sku 多行时取 MAX（dt + sku_id 唯一键下自然单值）；字段 NULL / 无记录 → BLANK → 条件 3 不成立；均值 AVERAGEX 自动跳过 BLANK，参与计算 SKU 数 = 快照日非 BLANK SKU 数
19. **Rank 全 1 签名与两轮修复（v2.3 / v2.4）**：全行 Rank 1 = RANKX 候选表 __Qualified 为空——空表无值可比较，RANKX 对所有行返回 1，不是排名基准错，是「和谁比」不存在。v2.3 修物化写法（__TradeAgg 补 REMOVEFILTERS(sku_id) 修筛选泄漏；全部候选物化改「SUMMARIZE 仅分组列 + CALCULATETABLE(ADDCOLUMNS + CALCULATE)」分组/扩展分离，Qualify / Rank 两处同步）；v2.4 修候选域错位（**真根因**，实测 v2.3 后仍全 1）：时间切片器为断开维度 → 视觉行组 (category, sku) 不受 dt 筛选、全历史 sku 照常显示，而 __CandSkus 带本期 dt 筛选 → 本期无 trade 记录的 sku（OPP 典型场景：旧季零销售库存）缺席候选表 → 零销售 category 候选表为空 → 全 1；修复后候选域 = 当前 category 全部 sku（不滤 dt，对齐行域），本期零销售 sku 正常参与排名（其 ST% = 0 恒低于均值，资格本就可能通过——注意事项 5 已知悉）；若修复后仍全 1，调试三步——① 临时把 §4.2 末尾 RANKX 换成 `COUNTROWS(__Qualified)`（0 = 资格 FILTER 筛光候选，查 [@Wc]/[@Launch] 等扩展列是否成 BLANK）；② 换成 `COUNTROWS(__InvAgg)`（0 = 候选 sku 无快照日 inv 记录，查快照日数据）；③ 核对该 category SLS Units 展示列与 inv 快照行是否存在
