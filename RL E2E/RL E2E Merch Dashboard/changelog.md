# 变更日志 — RL E2E Merch Dashboard

> 本文件记录 RL E2E Merch Dashboard 看板的代码创建与修改历史。
> 看板模块：Merchandise Performance Overview · Dimension Cross Analysis · SKU Sales Tracking
> 口径文档：

---

## 模块索引


## [ Merchandise Performance Overview ] 模块

## [2026-10-12 17:09] DAX 修复 — Sales Performance Details Base Value YOY 分子始终空值

- **模块**: Merchandise Performance Overview - Sales Performance Details by Channel
- **任务**: 修复 4.3 总路由中度量值 YOY 分子 `__SLSAmt_This` 始终返回 BLANK 的问题
- **操作**: 修改
- **变更内容**:
  - `Sales Performance Details Base Value`：YOY 分子重路由由 `REMOVEFILTERS(Dim[ColName]) + ColType = "SLS Amt"` 改为「CALCULATE 外捕获 ChannelGroup / Label_Value 标量 + `REMOVEFILTERS(整表)` + 三条件重建」
  - 根因：矩阵列头 ChannelGroup > Label > ColName 在视觉对象查询（SUMMARIZECOLUMNS）中以 GroupBy 组合筛选形式存在，单列 REMOVEFILTERS 无法剥离 ColName 部分，残留筛选与 `ColType = "SLS Amt"` 互斥 → Dim 表空集 → 始终 BLANK（同坑在 Merchandising Core KPI 已实证沉淀）
  - 同步更新方案文档 3.1 分层图 / 4.3 代码与注释 / 度量值清单 / 血缘图 / 注意事项 7、12
- **关联文件**: Sales Performance Details by Channel/Sales_Performance_Details_ms.md
- **备注**: 分母 LY Base Value 无重路由、不受影响；ChannelGroup / Label 层汇总单元格显示 "-" 的行为不变

## [Dimension Cross Analysis] 模块


## [SKU Sales Tracking] 模块

## [2026-10-15 16:30] DAX 重构 — Color Rank 改用新版 RANK 窗口函数（名称决胜唯一名次）

- **模块**: SKU Sales Tracking - Top Color Sales Performance
- **任务**: ① 解答 color_name 空值行排名显示（BLANK 空单元格，被「介于 1 与 10」区间筛选排除，候选集不占名次）；② 两个 Color Rank 度量由 RANKX Dense 改写为新版 RANK 窗口函数，排名语义从「金额并列共享名次」改为「金额降序 + color_name 字母序决胜的严格唯一名次」（经业务确认）
- **操作**: 修改
- **变更内容**:
  - `Top Color Sales Color Rank` / `Top Color Inventory Color Rank`：RANKX(候选集, value 参数, Dense) 重构为 RANK(DENSE, relation, ORDERBY(金额 CALCULATE, DESC, color_name, ASC))——无 value 参数，当前行经 ORDERBY 中的 relation 列（color_name）与 relation 行匹配确定名次；relation = FILTER(ALL(color_name)) 同时排除空白/空字符与当期无金额候选（无金额候选不占名次，避免 BLANK 排序位置使有效 color 名次整体偏移导致区间筛选误排）
  - 排名语义变更：金额相同的 color 按 color_name 字母序分先后（名次相邻不并列，1,2,3,4 严格连续），「Rank 介于 1 与 10」恒放行恰好 10 行（原 Dense 共享名次语义下并列可能超过 10 行）
  - 行排序依据由 SLS Amt Value / EOH Amt Value 列降序改为 Color Rank 列升序（名次唯一 → 行序 = 金额降序 + 名称字母序决胜，金额并列行序确定）
  - 方案文档同步：§1.2 / §3.1 / §3.2 / §3.5 / §4.1 / §4.2 / §5 / §6 / §7 / §8 注意事项 5、8 重写 + 新增注意事项 15（RANK 版本要求 2022 年 9 月+、无金额候选排除机制）/ §9 并列描述修正
  - 测试 SQL 同步：DENSE_RANK 双列 ORDER BY（金额 DESC, color_name ASC）还原名称决胜，恰好 10 行，行序注释更新
- **关联文件**: SKU Sales Tracking/2 Top Color Sales Performance/Top_Color_Sales_Performance_table.md、SKU Sales Tracking/2 Top Color Sales Performance/test_Top_Color_Sales_Performance_table.sql
- **备注**: ORDERBY 金额方向为 DESC（金额最大 = 名次 1，Top10 降序）；relation 用 ALL(color_name) 而非 ALLSELECTED（候选需不受视觉级筛选器落地筛选影响，行为更确定）；金额列绑定 Display（文本含动态币种符号）无法数值排序，Rank 列兼任行排序依据

## [2026-10-15 15:30] 方案新建 — Top Color Sales Performance 双表格解决方案（Top10 密集排名）

- **模块**: SKU Sales Tracking - Top Color Sales Performance
- **任务**: 依据口径文档子模块三【Sales】+ 子模块四【Inventory】，产出 Color 行维度双表格（Sales / Inventory 并排）完整解决方案，每表 4 列指标（SLS Amt / SLS Amt% / SLS Unit / SLS Unit%；EOH Amt / EOH Amt% / EOH Unit / EOH Unit%）
- **操作**: 新建
- **变更内容**:
  - 新建 `SKU Sales Tracking/2 Top Color Sales Performance/Top_Color_Sales_Performance_table.md`（18 个度量值 = 2 个 Color Rank + 8 个指标 Value + 8 个指标 Display）
  - Color Rank 为 DENSE 密集排名（金额并列共享名次、下一名次不跳号，RANKX(..., DESC, Dense)），视觉级筛选器「介于 1 与 10」固定 Top10 行；空白/空字符/当期无金额 color 返回 BLANK 被区间筛选排除（仅配「≤ 10」会放行 BLANK，已标注）；行排序按 SLS Amt Value / EOH Amt Value 降序（Value 列拖入值区域收窄列宽作排序依据）
  - 占比类分母为全量 color（REMOVEFILTERS(color_name) 上卷，含 Top10 之外颜色与空白 color_name 金额），Top10 行占比加总 < 100%；§9 标注拓展为 Top10 color 集合分母的修改方式（__Top10Colors CALCULATETABLE 限定，Rank 判定与视觉级筛选器同源）
  - 金额类（SLS Amt / EOH Amt Value）Value 层完成币种汇率换算（原始 RMB ÷ Currency_ExchangeRate），Display 层拼接币种符号（Slicer_Currency_Selection）
  - SLS Unit% 分母口径修正：口径文档原文 sum(sales_qty) 字段在 s02_trade_sku_data_d 数据字典与取数 SQL 中均不存在，经业务确认修正为 sum(product_qty)（与分子同字段）
  - EOH 系列期末单日时点 + end period 快照回退（快照日 REMOVEFILTERS(整表) 全表确定性取值）；Inventory 侧不受渠道筛选（inv 表无 platform / shop_name）
  - 新建配套测试 SQL `test_Top_Color_Sales_Performance_table.sql`（Sales / Inventory 两段：row_agg → color_rank(DENSE_RANK + 空白排除) → total(全量分母) → Top10 输出）
- **关联文件**: SKU Sales Tracking/2 Top Color Sales Performance/Top_Color_Sales_Performance_table.md、SKU Sales Tracking/2 Top Color Sales Performance/test_Top_Color_Sales_Performance_table.sql
- **备注**: Sales Top10 排名受 date + Platform + Store Name + Division 影响，Inventory Top10 仅受 date + Division 影响（口径限制同 Top Size 板块，已与业务确认）；DENSE 并列时排名 ≤ 10 的行数可能超过 10 行（密集名次共享，已在注意事项 5 标注）

## [2026-10-15 10:30] 文档补充 — LP 占比分母的上卷语义澄清

- **模块**: SKU Sales Tracking - Top Size Sales Performance
- **任务**: 澄清「过滤当期空值行后，LP 占比分母是否也会丢掉被过滤行的上期金额」的边界问题
- **操作**: 修改（仅文档，无度量值变更）
- **变更内容**:
  - 方案文档注意事项 17② 扩写：LP 分母经 REMOVEFILTERS(sku_size) 上卷至 category + size category 层级，汇总覆盖该分组底层数据中的全部 size（含被表格过滤掉的行组合的上期金额）；视觉级度量筛选器只决定行组合显示与否、不向其他行度量值注入列筛选，sku_size 列筛选器/切片器也会被分母 REMOVEFILTERS(sku_size) 移除；并注明 LP 分母为普通 CALCULATE + REMOVEFILTERS 模式，不受注意事项 16 候选迭代类污染影响
- **关联文件**: SKU Sales Tracking/1 Top Size Sales Performance/Top_Size_Sales Performance_table.md
- **备注**: 结论——过滤当期空值行不会改变剩余行的 LP 分子分母，代价仅为丢掉被过滤行自身承载的上期信息

## [2026-10-15 09:30] DAX 修复 — Sort Key L3 空值垫底与上期值边界说明

- **模块**: SKU Sales Tracking - Top Size Sales Performance
- **任务**: ① 当期占比为空的行排在分组最后（原升序 RANKX 中 BLANK 计为更小值浮到组内最前，如 XXL 行 EOH Amt% 空、LP 有值排序异常）；② 澄清过滤当期空值行对上期值计算的影响
- **操作**: 修改
- **变更内容**:
  - `Top Size Sales Sort Key` / `Top Size Inventory Sort Key`：L3 增加空值垫底——候选 [@Pct] 与 value 参数双侧把 BLANK 映射为 1E15 哨兵值（同构避免两阶段不一致），空值行排在分组最后且不占正序名次；外层 ADDCOLUMNS 嵌套新增 [@RankValue] 列
  - 方案文档 §3.5 L3 规则与新增空值垫底说明（真 BLANK 垫底 vs 0% 小值按真实值排序的区分）；§4.17/4.18 代码与头部注释同步；§8 注意事项 6 重写（行显示范围与空值边界：真 BLANK 被「不为空」筛选器排除，小值 0% 保留展示），新增注意事项 17（空值垫底机制 + LP 类 Value 按行组合独立计算不受行级过滤影响 + 零值与真空区分）
- **关联文件**: SKU Sales Tracking/1 Top Size Sales Performance/Top_Size_Sales Performance_table.md
- **备注**: 过滤当期空值行不会影响剩余行的上期值（LP 按行内组合独立计算），但会丢掉被过滤行自身承载的上期信息——需展示上期信息时应保留行并垫底而非过滤；「不为空」筛选器排不掉 0% 小值行（非 BLANK）

## [2026-10-14 22:00] DAX 修复 — Sort Key 候选迭代被视觉级度量筛选器污染（XXL 名次虚增）

- **模块**: SKU Sales Tracking - Top Size Sales Performance
- **任务**: 修复 Rank = 1 视觉级筛选器生效时，XXL 行 L3 组内名次虚增 1（PctRank 2→3、Sort Key 1002→1003）且 XL 同为 1003 的问题；源侧 SQL 与 Power BI 实证两行金额/占比均不同，非真实并列；取消筛选器后排名恢复正确
- **操作**: 修改
- **变更内容**:
  - `Top Size Sales Sort Key` / `Top Size Inventory Sort Key`：L2/L3 候选值计算重构——新增分组锚点 VAR（__Category / __SizeCategory）；候选 CALCULATE 改用 REMOVEFILTERS(category, sku_size_category, sku_size 三列组合) 清除行筛选与视觉级复合组合筛选（保留 Division/Platform/Store 外部筛选）+ TREATAS 重建候选三元组；候选值一次计算物化为 [@GroupValue]/[@Pct] 列，FILTER 与 RANKX 共用物化值
  - 根因：Rank = N 度量筛选器落地为跨列组合筛选，单列 ALL/REMOVEFILTERS 清不掉；候选上下文转换与组合筛选取交集时，当前行自身 size 候选在 RANKX 迭代阶段取 BLANK（FILTER 物化阶段非空、两阶段不一致），升序下被计入“小于当前值”致名次虚增 1（与注意事项 13 Rank 显示恒 1 同源）
  - 方案文档 §3.5 新增候选上下文净化说明；§4.17/4.18 代码与头部注释同步；§8 新增注意事项 16
- **关联文件**: SKU Sales Tracking/1 Top Size Sales Performance/Top_Size_Sales Performance_table.md
- **备注**: 修复后 L4 决胜与四级编码不变；Rank 度量（Category Rank）不受影响（仅作筛选，显示值恒 1 属预期现象 13）；上一轮 L4 决胜变更已另条记录

## [2026-10-14 20:30] DAX 修复 — Sort Key 新增 L4 决胜排名（并列行序确定）

- **模块**: SKU Sales Tracking - Top Size Sales Performance
- **任务**: 解决组内占比精确相等并列时 Sort Key 同值、行序不确定的问题（XL/XXL 同为 1003 现象）
- **操作**: 修改
- **变更内容**:
  - `Top Size Sales Sort Key` / `Top Size Inventory Sort Key`：新增 __TieRank 第四级决胜（按 sku_size 名称字典序升序，COUNTROWS(FILTER(ALL(sku_size), sku_size < 当前值)) + 1），编码升级为优先级×1e9 + 分组排名×1e6 + 组内排名×1e3 + 决胜排名，保证排序键全局唯一、行序确定
  - 方案文档 §3.5 升级为四级编码表并列语义说明（L3 竞争排名：占比精确相等才并列，同分组下等价于金额分毫不差；展示值舍入后肉眼不可辨），L2 示例区间同步 1e9 编码；§4.17/4.18 代码与头部注释、§5 清单、§7 排序说明、§8 注意事项 7/14/15 同步
- **关联文件**: SKU Sales Tracking/1 Top Size Sales Performance/Top_Size_Sales Performance_table.md
- **备注**: 并列本身是 RANKX 竞争排名预期行为非计算错误；后续用户报告 XL/XXL 金额不同仍同 Key，已提供诊断度量（拼接未舍入金额/占比/分组标签）与源侧 SQL 验证行值归属——升序排列中 602K 不可能夹在 4.3M 与 8.7M 之间，待诊断结果确认是否存在行对齐偏移或真 bug

## [2026-10-14 18:00] 测试 SQL 新建 — Top Size Sales Performance 八段测试 SQL

- **模块**: SKU Sales Tracking - Top Size Sales Performance
- **任务**: 输出 Sales Top1~4 + Inventory Top1~4 八段测试 SQL（MySQL 8.0+ 语法），验证八个表格视觉对象数值口径
- **操作**: 新建
- **变更内容**:
  - 新建 `SKU Sales Tracking/1 Top Size Sales Performance/test_Top_Size_Sales_Performance_table.sql`（八段独立查询 + 统一参数区）
  - Sales 段（1~4）：category 级 RANK() 竞争排名（This Period SUM(ROUND(product_qty×sales_price,6)) 降序）→ 取 rank=N category → size 组合输出 SLS_Amt_Value / SLS_Amt_Pct / LP_SLS_Amt_Pct / Vs_LP / Vs_LP_Bp
  - Inventory 段（5~8）：排名与指标均为期末时点（dt = '2026-07-25' / '2025-07-26'），输出 EOH_Amt_Value / EOH_Amt_Pct / LP_EOH_Amt_Pct / Vs_LP / Vs_LP_Bp
  - 口径还原：dt 日期字段、net_sales_amt 行级 ROUND 等价还原、category 空字符/空白排除（TRIM(category) <> ''）、占比分母 = category + sku_size_category（窗口 PARTITION）、CASE 无 ELSE 对应 DAX SUM 空集 BLANK、行序对应 Sort Key 三级编码（L1/L2/L3）
- **关联文件**: SKU Sales Tracking/1 Top Size Sales Performance/test_Top_Size_Sales_Performance_table.sql
- **备注**: division 单选参数化为 SET @division（默认 'WM'，改后需重跑全部八段）；Platform / Store Name 全选等价不筛选；inv 表无渠道字段，Inventory 段仅 date + Division 筛选；并列第 1 时 Top2 段返回空集（与 DAX RANKX 竞争排名一致）

## [2026-10-14 16:30] 文档补充 — Sort Key L2 分组排名机制说明

- **模块**: SKU Sales Tracking - Top Size Sales Performance
- **任务**: 补充 §3.5 中 L2 分组排名的分工说明与示例（金额与优先级错开的对照表）
- **操作**: 修改（仅文档，无度量值变更）
- **变更内容**:
  - 方案文档 §3.5 新增 L2 说明：L1 定层（跨优先级顺序）、L2 定同层内分组先后（分组当期金额降序）、L3 定组内行序（占比升序）；__GroupRank 为全部分组统一排名，L1 权重主导下与分层排名等价
- **关联文件**: SKU Sales Tracking/1 Top Size Sales Performance/Top_Size_Sales Performance_table.md
- **备注**: 无

## [2026-10-14 15:00] DAX 修复 + 新增 — Rank 空字符排除、当期具体值度量与行排序键

- **模块**: SKU Sales Tracking - Top Size Sales Performance
- **任务**: ① 修复空白/空字符 category 占据排名 1 导致 Top1~4 筛选异常；② 新增当期具体值度量 2 个；③ 新增表格行排序键 2 个（字母尺码 > 数字尺码 > 其余，组内占比升序）
- **操作**: 修改 / 新建
- **变更内容**:
  - `Top Size Sales Category Rank` / `Top Size Inventory Category Rank`：候选集与 RETURN 增加 LEN(TRIM()) > 0 排除空字符 category（数据中 NULL 与 "" 并存，空字符非 BLANK 且金额最大占据排名 1；视觉级 category 筛选器被候选集 ALL(category) 移除而无效，必须在度量值内部排除）
  - 新增 `Top Size Sales SLS Amt Value`（This Period 区间当期净销售金额）/ `Top Size Inventory EOH Amt Value`（This Period 最后一天期末库存金额，时点数）
  - 新增 `Top Size Sales Sort Key` / `Top Size Inventory Sort Key`：三级排序键编码（L1 分组优先级：含"字母尺码"=0、含"数字尺码"=1、其余=2；L2 同优先级按分组当期金额降序；L3 组内按占比升序），表格按排序键升序排序；L3 候选 FILTER 排除 BLANK（升序 RANKX 中 BLANK 计为更小值会虚增组内排名）
  - 方案文档新增 §3.5 行排序机制、§4.15~4.18 度量值，更新 §5 清单 / §6 血缘图 / §7 表格配置（排序操作 + 移除 category 空白筛选说明）/ §8 注意事项 4、7、14
- **关联文件**: SKU Sales Tracking/1 Top Size Sales Performance/Top_Size_Sales Performance_table.md
- **备注**: 组内占比升序与金额升序等价（同分组分母相同）；排序键编码系数要求分组数与组内 size 数 < 1,000

## [2026-10-14 11:00] 文档补充 — Rank 显示值验证现象说明

- **模块**: SKU Sales Tracking - Top Size Sales Performance
- **任务**: 说明视觉级筛选器 Rank = N 生效后，拖入表格的 Rank 显示值恒为 1 的上下文机制
- **操作**: 修改（仅文档，无度量值变更）
- **变更内容**:
  - 方案文档注意事项新增第 13 条：筛选器取值发生在筛选生效前（真实排名，行正确保留）；显示值在筛选后上下文重新评估（视觉内仅剩单 category，其余候选与组合筛选冲突取 BLANK，故恒显示 1），不影响筛选正确性
- **关联文件**: SKU Sales Tracking/1 Top Size Sales Performance/Top_Size_Sales Performance_table.md
- **备注**: 验证真实排名需临时移除视觉级筛选器；Rank 为辅助度量不建议展示给最终用户

## [2026-10-14 09:30] DAX 修复 — Top Size Category Rank 恒返回 1

- **模块**: SKU Sales Tracking - Top Size Sales Performance
- **任务**: 修复两个 Rank 度量值在表格中每行均返回 1、视觉级筛选器 Rank = 1 放行全部行的问题
- **操作**: 修改
- **变更内容**:
  - `Top Size Sales Category Rank` / `Top Size Inventory Category Rank`：__Ranking 候选集 @Amt 的 CALCULATE 补充 `ALL(sku_size_category, sku_size)`，使候选金额与 __CurrentCategoryAmt 同为 category 粒度
  - 根因：视觉对象行字段在每行残留 sku_size_category / sku_size 筛选，上下文转换只添加候选 category 筛选不清除残留筛选 → 候选金额被限制在当前行尺码内，而对比值为 category 全尺码真实金额（恒为最大）→ RANKX 恒返回 1
  - 同步更新方案文档 §4.1 / §4.2 代码与注释、注意事项新增第 12 条（排名候选集口径一致）
- **关联文件**: SKU Sales Tracking/1 Top Size Sales Performance/Top_Size_Sales Performance_table.md
- **备注**: 修复后非 Top1 category（如 Belts/mail accessories）返回真实排名，被 Rank = N 筛选器正确过滤，Top1 表格仅显示真实第一名 category

## [2026-10-13 10:30] DAX 新建 — Top Size Sales Performance 表格解决方案

- **模块**: SKU Sales Tracking - Top Size Sales Performance
- **任务**: Sales / Inventory 双视图 Top4 category 尺码结构占比表格（SLS Amt% / LP SLS Amt% / vs LP；EOH Amt% / LP EOH Amt% / vs LP）
- **操作**: 新建
- **变更内容**:
  - 新建解决方案文档 `SKU Sales Tracking/1 Top Size Sales Performance/Top_Size_Sales Performance_table.md`（14 个度量值 + 表格视觉对象配置）
  - Rank 度量值 2 个：`Top Size Sales Category Rank`（This Period sum(net_sales_amt) 降序）、`Top Size Inventory Category Rank`（This Period 最后一天 sum(msrp_inv_amt) 降序），用于表格视觉级筛选器固定 Top1~Top4 category
  - Sales 三指标 Value + Display：SLS Amt% / LP SLS Amt%（分母 category + size category 层级，REMOVEFILTERS(sku_size)）、vs LP（差值 bp，×10000 在 Display 层）
  - Inventory 三指标 Value + Display：EOH Amt% / LP EOH Amt%（期末快照日单日时点，end period 范围内最后一天回退保护）、vs LP
  - 表格行筛选机制：视觉级筛选器 Rank = N 且 Value 不为空，仅显示本期有数据的 category + size category + size 组合
- **关联文件**: SKU Sales Tracking/1 Top Size Sales Performance/Top_Size_Sales Performance_table.md
- **备注**: net_sales_amt 为取数新增列（ROUND(product_qty × sales_price, 6)，业务确认）；inv 表无 platform / shop_name 字段，Inventory 指标不受渠道筛选影响（业务确认接受）；Sales/Inventory 视图切换由页面按钮 + 书签实现，不在度量值范围内

