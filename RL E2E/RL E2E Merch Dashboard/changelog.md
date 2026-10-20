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

## [2026-10-19 15:31] DAX 新建 — Label & Product Type Inventory Structure 表格解决方案

- **模块**: Dimension Cross Analysis - Label & Product Type Inventory Structure
- **任务**: 子模块一~四（Label / Product Type Sales & Inventory Structure 主视图与交叉视图）Power BI 表格 + 柱形图解决方案
- **操作**: 新建
- **变更内容**:
  - 新建 26 个度量值（§4.1~§4.26）：主视图 8 指标 Value/Display + LP 中间度量值 2 个 + vs LP 附属 2 组；交叉视图 Cross Label / Cross PT 各 2 指标 Value/Display
  - 主视图占比分母 ALLSELECTED 六个 Slicer_ 维度表字段（label / super_season / product_type / category / md_type / division），六维度行切换一套逻辑通吃，子模块一/三共享；行字段从维度表拉取，行筛选经一对多关系自动传导双事实表，无需 TREATAS 桥接
  - 交叉视图分母 ALLSELECTED 五个交叉维度字段（保留 x 轴基数维度柱形筛选，与「移除后重加 x 轴当前值」等价），子模块二/四因交叉维度集合互异独立成套
  - 时间口径：This/Last Period 区间（Min_Last/Max_Last 直读）+ end period 范围最后快照日期末时点（LP 侧用 Max_Last 范围）+ YTD 财年区间（Fiscal_Year_First_Day）；vs LP 差值 ×10000 转 bp 在 Display 层
- **关联文件**: Dimension Cross Analysis/1 Label & Product Type Inventory Structure/Label_&_Product_Type_table.md
- **备注**: 全部指标为占比/数量/比率类，不涉及币种换算；inv 表无渠道字段，库存侧（EOH 系列、YTD ST% 分母、Cross EOH Amt%）不受渠道筛选影响；YTD ST% 分子分母渠道口径不对称为模型物理限制

## [2026-10-19 15:53] DAX 修改 — Label & PT Table 交叉视图补充金额类附属度量值

- **模块**: Dimension Cross Analysis - Label & Product Type Inventory Structure
- **任务**: 子模块二/四交叉视图金额类附属指标补充（口径文档 §7/§8/§15/§16 已由业务补入附属指标类型：SLS Amt:currency / EOH Amt:currency）
- **操作**: 修改
- **变更内容**:
  - 新增 8 个金额类附属度量值（§4.27~§4.34）：Cross Label SLS Amt / Cross Label EOH Amt / Cross PT SLS Amt / Cross PT EOH Amt 各 Value/Display；与对应占比主指标分子同维度同时间口径（SLS Amt 为 This Period 区间，EOH Amt 为快照日单日），不涉及占比分母
  - 币种处理：Value 层 ÷ Currency_ExchangeRate 换算为当前币种（RMB 汇率 = 1 时值不变），Display 层拼接 Currency_Symbol（#,##0）
  - 同步更新 §1.4 指标清单（序号 13~16）、§1.6 币种口径、§3.1 分层图、§5 度量值清单（15~18）、§6.2/6.3 备用说明、§7.6 验证 SQL、§8 注意事项 11/13
  - 金额附属度量值为备用输出，具体绑定（tooltip / 数据标签 / 轴切换）由后续视觉对象配置决定
- **关联文件**: Dimension Cross Analysis/1 Label & Product Type Inventory Structure/Label_&_Product_Type_table.md；口径文档/口径Markdown格式/Dimension Cross Analysis.md（业务已同步补入附属指标类型行）
- **备注**: SLS Amt 附属受渠道筛选影响（sales 侧），EOH Amt 附属不受（inv 表无渠道字段）

## [2026-10-20 10:12] 测试 SQL 新建 — Label & PT Table 三份拆分测试 SQL

- **模块**: Dimension Cross Analysis - Label & Product Type Inventory Structure
- **任务**: 主视图与交叉视图度量值对数测试 SQL（按视觉对象拆分三文件，字面量直嵌无用户变量）
- **操作**: 新建
- **变更内容**:
  - test_Label_&_Product_Type_table_1_主视图.sql：子模块一/三全部 8 指标，六种行维度 UNION ALL 一次输出（Row_Dimension 列区分），分母全量合计对应 ALLSELECTED 六维度；trade/inv 各自独立上卷后 LEFT JOIN（inv 同维度全量含 trade 无记录子组合）
  - test_Label_&_Product_Type_table_2_交叉视图_Label基数.sql：子模块二 SLS/EOH Amt% + 金额附属，五种图例维度一次输出，分母窗口 PARTITION BY Label 对应 ALLSELECTED 五交叉维度；行组合 trade ∪ inv（UNION ALL 再聚合还原 FULL OUTER，对齐 PBI 数据点由度量值非空驱动）
  - test_Label_&_Product_Type_table_3_交叉视图_PT基数.sql：子模块四同构，窗口 PARTITION BY Product_Type
  - NULL 传播对齐 DAX BLANK（显示 "-"）；YTD ST% 分母 COALESCE 对齐 DAX 算术 BLANK 当 0；vs LP 输出原始差值；金额附属输出 RMB 原值
- **关联文件**: Dimension Cross Analysis/1 Label & Product Type Inventory Structure/ 下上述三个 .sql
- **备注**: 参数：Platform/Store 全选不筛选，Sales This ['2026-03-29','2026-07-25'] / Last ['2025-03-30','2025-07-26']，双期快照日 '2026-07-25'/'2025-07-26'；YTD 财年第一天与 This 起点重合；sales 侧 platform IN ('JD','TM','RLE','DY') 为模型加载过滤与切片器无关

## [2026-10-20 11:35] DAX 新建 — Label & Division Table 表格解决方案（含测试 SQL）

- **模块**: Dimension Cross Analysis - Product Type Sales & Inventory Structure【Category × Division/Label】
- **任务**: 子模块五（§17~§18）SLS Amt% / EOH Amt% 及 vs LP / vs LY 附属指标表格解决方案 + 对数测试 SQL
- **操作**: 新建
- **变更内容**:
  - 新建 16 个度量值（§4.1~§4.16）：SLS Amt% / EOH Amt% 各 Value/Display + vs LP / vs LY 各 Value/Display + LP / LY 中间度量值 4 个；分母 ALLSELECTED(Slicer_Category[category]) 组内分母（保留 Division/Label 视觉对象筛选器，组内占比之和 = 100%），Division 分组表与 Label 分组表共用一套度量值
  - vs LP 与 vs LY 双独立基线：vs LP 读 Last Period 日期切片器（Min_Last/Max_Last）；vs LY 读 Min_This/Max_This 表的 TimeFrame_Min_LY/TimeFrame_Max_LY 字段（财年同期映射，与 LP 切片器无关）；EOH 三个快照日各自独立取值（This = Max_This 范围、LP = Max_Last 范围、LY = Max_This _LY 字段范围各自最后快照日）
  - 测试 SQL test_Label_&_Division_table.sql：一个文件两段独立 SQL（SQL 1/2 Division 分组、SQL 2/2 Label 分组/brand 字段），窗口 PARTITION BY 分组键还原组内分母；trade ∪ inv UNION ALL 再聚合还原 FULL OUTER；差值 CASE 拦截 NULL 对齐 DAX ISBLANK；参数：Platform/Store 全选不筛选，This/LP/TY/LY = ['2026-03-29','2026-07-25']/['2025-03-30','2025-09-27']/['2026-03-29','2026-07-25']/['2025-03-30','2025-07-26']，三快照日 '2026-07-25'/'2025-09-27'/'2025-07-26'
- **关联文件**: Dimension Cross Analysis/2 Product Type Sales & Inventory Structure/Label_&_Division_table.md；同目录 test_Label_&_Division_table.sql
- **备注**: 用户澄清分母口径为组内分母（Division/Label 视觉对象筛选器固定单值，页面多表分组展示，占比之和 = 100%）；口径文档§17/§18业务定义与公式列的“占所有 Category”表述按此澄清理解

## [2026-10-20 11:52] 口径类型统一 — integer_bp 更名 delta_bp

- **模块**: Dimension Cross Analysis - Label & Division Table / 口径文档
- **任务**: 附属指标类型命名统一（integer_bp → delta_bp，对齐《数据类型和格式总览》标准类型名）
- **操作**: 修改
- **变更内容**:
  - Label_&_Division_table.md：13 处（§1.2 指标清单 4 处、§3.1 分层图 1 处、4 个 Display 度量值注释、§5 度量值清单 4 处）
  - 口径文档 Dimension Cross Analysis.md：6 处附属指标类型行（§1/§2/§9/§10 各 1 处、§17/§18 各 1 处）
  - 数据格式与显示行为不变：`#,##0bp;-#,##0bp;0bp`（不含正号，负数自带负号，零值 0bp），与同看板既有 delta_bp 实现惯例一致
- **关联文件**: Dimension Cross Analysis/2 Product Type Sales & Inventory Structure/Label_&_Division_table.md；口径文档/口径Markdown格式/Dimension Cross Analysis.md
- **备注**: SKU Sales Tracking.md（另一 Tab 口径文档）中仍有自定义 integer_bp 数据类型/格式定义块（Top Size 附属指标引用），本次未动，如需全局统一另行确认

## [SKU Sales Tracking] 模块

## [2026-10-16 18:00] 测试 SQL 调整 — Series Sales 变量改字面量直嵌 + 拆分明细 / 汇总两段

- **模块**: SKU Sales Tracking - Series Sales Performance
- **任务**: 测试环境不支持用户变量模式（SET @var），改为字面量直嵌；拆分为两段独立 SQL 分别验证明细行与 series 汇总行
- **操作**: 修改
- **变更内容**:
  - 删除全部 SET @变量与参数取值辅助查询，参数字面量直嵌：Division 四值全选（division IN ('CW','HM','MN','WM')，等价切片器全选）、This Period ['2026-03-29', '2026-07-25']、End Period 快照日 '2026-07-25'、YTD 财年第一天 '2026-03-29'（FY27 财年首日 = TimeFrame_Min，本参数下 YTD 与 This Period 重合）
  - 拆为 SQL 1/2 明细行（(special_series, spu_id, spu_img_url) 三元组粒度，库存按 spu_id 匹配）+ SQL 2/2 series 汇总行（仅 special_series 维度、非空，库存按 series 值匹配，Spu_Rank 固定 999,999）两段独立执行
  - SQL 1/2 排名窗口去除 row_level 隔离分区（纯明细段不再需要）；分母 CTE 简化（sales_total 从 trade_agg 直接 SUM 金额 / 数量，inv_total 去嵌套子查询改为全量条件聚合）
- **关联文件**: SKU Sales Tracking/4 Series Sales Performance/test_Series_Sales_Table.sql
- **备注**: 后续修改参数时对两段全文替换对应日期 / 维度值；去窗口条件即全量 LTD / YTD 口径

## [2026-10-16 17:30] 方案修复 — Series Sales 行区域新增 spu_img_url 后占比恒 100% / Sort Key 恒 1 修复

- **模块**: SKU Sales Tracking - Series Sales Performance
- **任务**: spu_img_url 拖入表格行区域（第三层图片列，行粒度变为 (special_series, spu_id, spu_img_url) 三元组）后，占比类指标恒 100%、Sort Key 恒 1000001——修复占比分母与 Sort Key 排名候选的子级行筛选残留；新增 IsEmpty 行非空判定度量
- **操作**: 修改
- **变更内容**:
  - 根因：url 列进入行轴后成为行筛选上下文的一部分——SLS Amt% / SLS Unit% 分母 REMOVEFILTERS 仅移除两列，url 筛选残留使分母被收窄为分子自身（占比恒 100%）；Sort Key L1 relation ALL(special_series) / L2 relation ALL(spu_id) 均仅移除自身列筛选，spu_id / url 子级行筛选残留在候选金额评估中使候选集收窄为当前行自身（名次恒 1）
  - `Series Sales SLS Amt% Value` / `Series Sales SLS Unit% Value`：分母 REMOVEFILTERS 扩为三列（special_series / spu_id / spu_img_url）
  - `Series Sales Sort Key`：L1 候选金额 CALCULATE 内 REMOVEFILTERS(spu_id, spu_img_url) 上卷到 series 粒度、L2 候选金额 CALCULATE 内 REMOVEFILTERS(spu_img_url) 上卷到 spu 粒度（relation FILTER 与 ORDERBY 两处同步）；__CurrentAmt 保持三元组行粒度（垫底判定）
  - 库存类指标无需修改：url 明细行与 spu 层小计行均满足 ISINSCOPE(spu_id)，TREATAS 按 spu_id 传递天然兼容三层结构（一对多异常时 url 行显示相同 spu 级库存，为可接受降级；inv 表 url 与 trade 表 url 不保证同步，双列传递存在库存漏计风险）
  - 新增 `Series Sales IsEmpty`（行非空判定，§4.32）：判断组合按分子依赖简化——SLS Amt 为空则 SLS Amt% 必为空，占比类不单独判断；原子集 = SLS Amt / SLS Unit / EOH Amt / EOH Unit / YTD SLS Unit / LTD SLS Unit，全空返回 0（视觉级筛选器 IsEmpty = 1 仅显示有数据行）
  - 方案文档同步：§1.1 / §1.2（行粒度三元组 + 一对多异常说明）/ §1.6 / §3.2 / §3.3 / §3.4（排名粒度上卷）/ §4.1 / §4.3 / §4.5 / §4.32 新增 / §5（32 个度量值）/ §6 / §7（行字段三层 + IsEmpty 筛选器 + spu 层小计建议关闭）/ §8 注意事项 5、6 重写 + 新增 15（spu_img_url 行维度）、16（IsEmpty）
  - 测试 SQL 同步：trade_agg GROUP BY 三元组、新增 trade_spu CTE（L2 排名依据跨 url 上卷）、Spu_Rank / Sort_Key 排序列改用 spu_rank_amt、垫底判定用三元组粒度 spu_amt、头部口径还原说明更新
- **关联文件**: SKU Sales Tracking/4 Series Sales Performance/Series_Sales_Table.md、SKU Sales Tracking/4 Series Sales Performance/test_Series_Sales_Table.sql
- **备注**: 一对多异常时同一 spu 的多个 url 行共享 (SeriesRank, SpuRank)，键值相同行序由表格呈现确定；销售类指标按 (spu, url) 记录归属拆分（历史换图记录按各自 url 归属）

## [2026-10-16 16:30] 方案新建 — Series Sales Performance 表格解决方案

- **模块**: SKU Sales Tracking - Series Sales Performance
- **任务**: 依据口径文档子模块七（§13~§27），产出 Series > AXC 层级行 + Image 图片列单表格完整解决方案（15 列指标 + Sort Key，开启行小计），解决两事实表无模型关系下行维度值向库存侧传递与 series 汇总行数据正常问题
- **操作**: 新建
- **变更内容**:
  - 新建 `SKU Sales Tracking/4 Series Sales Performance/Series_Sales_Table.md`（31 个度量值 = 1 个 Sort Key + 15 个指标 Value + 15 个指标 Display）
  - 行维度值跨表传递：库存类指标（EOH / ST% 库存加项）在度量内部以 ISINSCOPE 分层 TREATAS 桥接——明细行传 spu_id（单 spu 精确匹配）、series 汇总行传 special_series（该 series 全部库存，不受渠道筛选影响）、总计行不传维度仅 series 非空；IF 标量分支实现（IF 返回表会降级为标量），行小计数据正常
  - special_series 非空前提核查（§1.6）：销售占比分母 REMOVEFILTERS(两列) 后显式重加 series 非空条件（视觉级「不为空」筛选被 REMOVEFILTERS 移除后必须还原，否则空白 series 金额混入分母）；库存分母显式 inv 侧 series 非空
  - Sort Key：L1 series 粒度当期净销售金额降序 + L2 series 内 spu 金额降序（两级维度值升序决胜，RANK(DENSE, ALL(列), ORDERBY(金额 DESC, 维度 ASC)) 窗口函数；L2 relation ALL(spu_id) 保留 series 筛选 → series 内排名无需上下文重建）；汇总行编码 999,999 组内最后；当期无金额行键值垫底
  - YTD 区间起点读 Slicer_Time_Frame_Max_This[Fiscal_Year_First_Day]（新增字段）；LTD 销售侧仅上限 dt ≤ TimeFrame_Max、库存侧 end period 快照日；ST% 库存字段 inv_qty（≠ EOH Unit 的 stock_inv_qty）；模型加载窗口对 YTD/LTD 的截断限制已注明（§8.7）
  - 新建配套测试 SQL `test_Series_Sales_Table.sql`（明细 + series 汇总行两段 UNION ALL + DENSE_RANK 双列 ORDER BY 还原两级排名与 Sort Key；ST% 分母 NULL 侧按 0 处理对齐 DAX BLANK 算术行为；默认附加模型加载窗口与 PBI 值对齐，去窗口即全量 LTD/YTD 口径）
- **关联文件**: SKU Sales Tracking/4 Series Sales Performance/Series_Sales_Table.md、SKU Sales Tracking/4 Series Sales Performance/test_Series_Sales_Table.sql
- **备注**: 表格视觉级筛选器仅 special_series 不为空；Image 列拖值区域（数据类别图像 URL，汇总行为空）；金额 Display 统一 BLANK 显示 "-"（无 TopN 金额筛选器，空值行正常显示）

## [2026-10-15 18:30] 方案重构 — Emerging Style 行列维度表化 + 热力 SVG（v2.0）

- **模块**: SKU Sales Tracking - Emerging Style Identification
- **任务**: 矩阵行列改为从四张维度表获取（用户已建：Dim_Sales_color_name / Dim_Sales_sku_size / Dim_Inventory_color_name / Dim_Inventory_sku_size，distinct + 非空白过滤），占比分母限定维度表字段值（整行相加 100%），新增行/列可见性与 SVG 热力度量
- **操作**: 重构
- **变更内容**:
  - `3 Emerging_Style_ms.md` 升级 v2.0（度量值 4 → 10 个）：每视图新增 Is_Matrix_Row / Is_Matrix_Col（MAXX 遍历 ALLSELECTED(对侧维度表) 逐候选复刻单元格 Value，CALCULATE 上下文转换使 Value 内 SELECTEDVALUE 读到候选值）+ SVG（背景/字体四点三段插值，双 ISINSCOPE 明细判定，空值三段 RETURN：总计 BLANK / 空值且行列均有效才返回灰色占位 SVG、否则 BLANK / 有值直接 SVG）
  - Value 重构：行列值经 SELECTEDVALUE 从维度表读取 + 显式等值桥接事实表；分母 `事实表[color_name] = 当前行值 + TREATAS(ALLSELECTED(Dim_xxx_sku_size), 事实表[sku_size])` 限定维度表 size 值范围——空白 sku_size 金额不进分母，同一 color 行全部 size 列占比相加 = 100%（用户明确口径）
  - 矩阵配置：值字段绑 Value + 条件格式图像 URL 绑 SVG；关闭小计/总计与「显示无数据的项」；可见性度量不配视觉级筛选器（视觉筛选器按行字段定粒度、列向无法对称过滤，行列双向抑制统一在 SVG 内调用）
  - 测试 SQL 同步：WHERE 增 color_name / sku_size 非空白过滤（对应维度表限定），新增整行加总 = 100% 验证说明
- **关联文件**: SKU Sales Tracking/3 Emerging Style Identification/3 Emerging_Style_ms.md、test_3 Emerging_Style_ms.sql
- **备注**: 维度表与事实表建不建一对多关系均可（显式等值桥接两种建模行为一致）；SVG 插值色标与 Co-Purchase 热力矩阵同款（0%→#d8dee5→30%→#95afcf→50%→#0c2340→100%→#000000，字体白色提前到 35%）；Value 按明细单元格设计，汇总位置 SELECTEDVALUE=BLANK 不可用（小计/总计已关闭 + SVG 层 ISINSCOPE 排除）

## [2026-10-15 17:30] 方案新建 — Emerging Style Identification 双矩阵解决方案

- **模块**: SKU Sales Tracking - Emerging Style Identification
- **任务**: 依据口径文档子模块五【Sales】（§11）+ 子模块六【Inventory】（§12），产出 color × size 交叉矩阵（行 color_name、列 sku_size）双矩阵（Sales / Inventory 并排）解决方案，每矩阵单一占比指标
- **操作**: 新建
- **变更内容**:
  - 新建 `SKU Sales Tracking/3 Emerging Style Identification/3 Emerging_Style_ms.md`（4 个度量值 = 2 个指标 Value + 2 个指标 Display）
  - SLS Amt%：分子 = 该 color + sku_size This Period sum(net_sales_amt)（矩阵单元格上下文）；分母 REMOVEFILTERS(sku_size) 保留行 color 筛选 → 该 color 层级全 size 汇总（口径「该 color + size 占该 color」）
  - EOH Amt%：期末快照日单日时点（REMOVEFILTERS(整表) 取 end period 最后一个有数据快照日 + 回退），分母同构收敛到该 color 层级
  - 矩阵行列均为原始字段（color_name / sku_size），非自定义行列路由，无需断开维度表；行显示范围口径未定义 TopN，默认全部行 + 「Value 不为空」视觉级筛选
  - 汇总单元格行为（§3.4）：行小计/总计恒 100%（分子 = 分母）、列总计 = 该 size 占 total（分母层级不同），建议关闭全部小计/总计
  - 值绑定：默认绑 Value（列格式 #,##0%，支持热力图背景色/数据条条件格式）；Display 文本备用（不支持条件格式）
  - 新建配套测试 SQL `test_3 Emerging_Style_ms.sql`（Sales / Inventory 两段：GROUP BY (color_name, sku_size) + SUM(SUM()) OVER (PARTITION BY color_name) 窗口还原 color 级分母，对应 REMOVEFILTERS(sku_size)）
- **关联文件**: SKU Sales Tracking/3 Emerging Style Identification/3 Emerging_Style_ms.md、SKU Sales Tracking/3 Emerging Style Identification/test_3 Emerging_Style_ms.sql
- **备注**: 占比分母为 color 级全量（含矩阵未显示/被筛选排除的 size 与空白 sku_size 金额）→ 可见列占比加总可能 < 100%；空白行/(Blank) 列建议视觉级筛选排除（排除后加总仍 < 100%，分母含空白 size 金额）；inv 表无渠道字段，Inventory 矩阵仅受 date + Division 影响

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

