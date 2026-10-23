# Item Stockout_Table 解决方案

> **版本**: v1.0
> **模块**: RL E2E Merch Dashboard - Dimension Cross Analysis Tab - Item Stockout & Slow Mover Alert
> **关联口径**: 口径文档/口径Markdown格式/Dimension Cross Analysis.md - 子模块七（§21~§33）
> **数据底表（销售/属性类）**: s02_trade_sku_data_d
> **数据底表（库存/预警/补货类）**: s02_inventory_stock_sales_detail_d
> **关联维度**: Slicer_Time_Frame_Min_This / Max_This（时间，断开维度）；Slicer_Platform_Selection / Slicer_Store_Name（一对多关系自动传导，DAX 不显式处理）；Slicer_Currency_Selection（币种，断开维度）
> **筛选影响范围**: dt（断开维度，DAX 显式筛选）+ Platform / Store Name（模型关系自动传导）+ 其余与两张事实表已建关系的商品维度切片器

---

## 1. 需求理解

### 1.1 模块定位与视觉对象结构

本板块为单品级缺货与滞销预警表格，通过两个按钮（SPU / SKU）切换显示 spu_id 维度与 sku_id 维度两张表格，各取 SLS Amt 最大的 Top 100 行：

| 配置项 | SPU 表格 | SKU 表格 |
| --- | --- | --- |
| 字段井（行分组） | s02_trade_sku_data_d[spu_id] + [product_type] + [special_series] | s02_trade_sku_data_d[sku_id] + [product_type] + [special_series] |
| 值区域（属性列） | US Style / AX Class / SPU Image / Product Tag / Special Supply（度量） | 同左（桥接锚点换 sku_id） |
| 值区域（指标列） | 十三个指标 Display + Rank 度量（行排序依据） | 同左（共用同一套指标度量） |
| 视觉级筛选器 | SPU Rank 介于 1 与 100 + SLS Amt Value 不为空 | SKU Rank 介于 1 与 100 + SLS Amt Value 不为空 |
| 显隐控制 | 按钮（书签）切换，两表互斥显示 | 同左 |

- **行主键（业务修正）**：`(spu_id / sku_id, product_type, special_series)` 三元组为该表唯一键——同一个 spu_id / sku_id 只对应一个 us_style / ax_class / spu_img_url（一对一），但对应多行 product_type / special_series（一对多）。字段井只放三元组三列；一对一属性列经度量放值区域，行值由三元组唯一确定
- **指标计算的行过滤**：仅经三元组行分组筛选传导（"通过 spu_id / sku_id 过滤行"）——product_type / special_series 参与行分组，行筛选自动落在 s02_trade_sku_data_d 对应列上，trade 侧聚合自动限定当前行组合，无需度量值路由
- **inv 侧显式桥接**：两张事实表之间无模型关系，行维度值对库存类指标（EOH / In-transit / Replenishment / Alert / Available Sizes / Product Tag / Special Supply + Weeks Cover 分子 + ST% 库存分母）不自动传递，经 DAX TREATAS 三列交集显式桥接（见 §1.6、§3.4）
- **表格无小计无层级**：字段井三列为并列单层行分组；总计行不做特判，交由表格视觉对象默认生成
- **行可见性**：Top 100 行由视觉级 Rank 筛选器驱动——Rank 候选集已排除空白 / 当期无金额组合，入选行必有 SLS Amt，无全空行，不设 IsEmpty 筛选器

### 1.2 指标清单

| 序号 | 指标 | 口径章节 | 时间口径 | 计算公式 | 数据类型 / 格式 |
| ---- | --- | --- | --- | --- | --- |
| 1 | SLS Amt | §21 | This Period（区间） | 该行组合下 sum(net_sales_amt) | currency → 币种符号 + `#,##0` |
| 2 | SLS Units | §22 | This Period（区间） | 该行组合下 sum(product_qty) | integer → `#,##0` |
| 3 | EOH | §23 | End Period（期末时点） | 该行组合下 sum(stock_inv_qty)（快照日单日） | integer → `#,##0` |
| 4 | In-transit Inventory | §24 | End Period（期末时点） | 该行组合下 sum(in_trans_inv_qty)（快照日单日） | integer → `#,##0` |
| 5 | Weeks Cover | §25 | 跨双口径 | (sum(stock_inv_qty) + sum(in_trans_inv_qty)) / sum(product_qty)；库存侧看 end period 最后一天，销售侧 this period 区间 | decimal_1dp → `#,##0.0` |
| 6 | MTD SLS Unit | §26 | 财月至今（区间） | end period 所在财月第一天至 end period 最后一天 sum(product_qty) | integer → `#,##0` |
| 7 | YTD SLS Unit | §27 | 财年至今（区间） | end period 所在财年第一天至 end period 最后一天 sum(product_qty) | integer → `#,##0` |
| 8 | ST% | §28 | 跨双口径 | sales.sum(product_qty) / (sales.sum(product_qty) + inv.sum(stock_inv_qty))；数量口径 | percent_0dp → `#,##0%` |
| 9 | AUR | §29 | This Period（区间） | sum(net_sales_amt) / sum(product_qty) | currency → 币种符号 + `#,##0` |
| 10 | MD | §30 | This Period（区间） | 1 - sum(product_qty×md_price) / sum(product_qty×msrp) | percent_0dp → `#,##0%` |
| 11 | Alert | §31 | End Period（期末时点） | oos_tag 与 computed_product_tag 共同判定：缺货 / 滞销 / 其他（优先级聚合） | 文本 |
| 12 | Available Sizes | §32 | End Period（期末时点） | 该行组合下 distinct sku_size where inv_qty > 0，多值顿号拼接 | 文本枚举 |
| 13 | Replenishment Count | §33 | End Period（期末时点） | 该行组合下 sum(reph_qty)（快照日单日） | integer → `#,##0` |

属性列（非口径指标，单度量输出）：

| 属性列 | 来源 | 输出方式 |
| --- | --- | --- |
| US Style / AX Class / SPU Image | s02_trade_sku_data_d（us_style / ax_class / spu_img_url） | SELECTEDVALUE 度量（一对一属性，行组合下单值）；Image 设数据类别 = 图像 URL 显示图片 |
| Product Tag / Special Supply | s02_inventory_stock_sales_detail_d（computed_product_tag / special_supply） | TREATAS 桥接：SKU 表快照日单行单值；SPU 表多 sku 值 distinct 顿号拼接 |

### 1.3 时间口径

| 口径 | 时间范围 | 适用指标 |
| --- | --- | --- |
| This Period（区间类） | dt ∈ [Slicer_Time_Frame_Min_This[TimeFrame_Min], Slicer_Time_Frame_Max_This[TimeFrame_Max]] | SLS Amt、SLS Units、AUR、MD、ST% 销售侧、Weeks Cover 分母、Top 100 排序金额 |
| End Period（期末时点类） | end period 范围 [Slicer_Time_Frame_Max_This[TimeFrame_Min], Slicer_Time_Frame_Max_This[TimeFrame_Max]] 内**最后一个有数据的快照日** | EOH、In-transit、Replenishment、Alert、Available Sizes、Product Tag、Special Supply、Weeks Cover 分子、ST% 库存侧 |
| MTD（财月至今区间） | dt ∈ [Slicer_Time_Frame_Max_This[Fiscal_Month_First_Day], Slicer_Time_Frame_Max_This[TimeFrame_Max]] | MTD SLS Unit |
| YTD（财年至今区间） | dt ∈ [Slicer_Time_Frame_Max_This[Fiscal_Year_First_Day], Slicer_Time_Frame_Max_This[TimeFrame_Max]] | YTD SLS Unit |

说明：

- 两张 s02 表日期字段均为 dt（非 data_date）
- 期末时点实现为「范围内最后一个有数据的快照日」：口径定义为区间最后一天，快照缺数时自动回退到范围内最近一天；快照表按日存储，期末时点只取单日，对整段区间求和会把库存重复计数
- MTD / YTD 的起点字段（Fiscal_Month_First_Day / Fiscal_Year_First_Day）由 Slicer_Time_Frame_Max_This 表提供（口径 §26 / §27 指定），终点为 TimeFrame_Max

### 1.4 币种口径

- SLS Amt / AUR 为 currency 类指标：货币符号由币种切片器（Slicer_Currency_Selection）决定，千分位整数；数据底表金额仅存储 CNY，Value 层完成汇率换算（原始值 ÷ Currency_ExchangeRate，RMB 汇率 = 1 时换算前后值相同），Display 层仅拼接币种符号
- 数量 / 占比 / 比率 / 周数类指标不涉及币种换算

### 1.5 Top 100 排名机制

- **排序依据**：This Period `sum(net_sales_amt)`（原始 CNY 聚合，不经币种换算——除以同一正汇率不改变相对顺序）降序，取最大的 100 条（行 = 三元组组合）
- **决胜链（名次唯一）**：金额降序 → spu_id / sku_id 字母序升序 → product_type 字母序升序 → special_series 字母序升序。行主键为三元组，同一 spu_id / sku_id 可展开多行（不同 product_type / special_series），仅按 spu_id / sku_id 一列决胜无法消除同行并列，决胜链按行主键全键延伸保证名次严格连续唯一（1、2、3、……），Top 100 恰好 100 行、边界确定
- **两个排序度量**：Item Stockout SPU Rank（SPU 表，决胜首键 spu_id）、Item Stockout SKU Rank（SKU 表，决胜首键 sku_id）——RANK 窗口函数的 relation 与 ORDERBY 绑定不同主键列，无法合并
- **行筛选落地**：视觉级筛选器「Rank 介于 1 与 100」（含下界）+「SLS Amt Value 不为空」双保险；Rank 对空白主键 / 当期无金额行返回 BLANK，被区间筛选排除（BLANK 视为 0 不满足下界）
- **行排序依据**：Rank 度量拖入值区域按升序排序（名次唯一 → 行序 = 金额降序 + 决胜链顺序，并列金额行序确定）

### 1.6 单度量双维度机制

两张表格共用同一套指标度量（除 Rank 外每指标一个度量），机制分两类：

| 指标类别 | 双表复用机制 | 分支需求 |
| --- | --- | --- |
| trade 侧（SLS Amt / SLS Units / MTD / YTD / AUR / MD / ST% 销售侧 / Weeks Cover 分母） | 行分组筛选自动落在 trade 表对应列上（SPU 表 = spu_id + product_type + special_series，SKU 表 = sku_id + product_type + special_series），聚合自动限定当前行组合 | **零分支**——聚合与主键列是哪个无关 |
| inv 侧（EOH / In-transit / Replenishment / Alert / Available Sizes / Product Tag / Special Supply / Weeks Cover 分子 / ST% 库存分母） | `ISINSCOPE(trade[spu_id])` 判定当前表格（SPU 表 TRUE / SKU 表 FALSE——两表互斥显示，行分组必含其一），TREATAS 桥接按判定结果切换锚点列 | **IF 标量双分支**——分支内 CALCULATE / CONCATENATEX 返回标量后经 IF 选择（分支返回表会被降级为标量，TREATAS / CALCULATETABLE 不经 IF 传递） |
| Rank | 两表 relation 与 ORDERBY 绑定不同主键列 | 各写一个 |

### 1.7 渠道上下文

- Slicer_Platform_Selection / Slicer_Store_Name 与 s02_trade_sku_data_d 一对多关联，筛选经模型关系自动传导——trade 侧指标与 Top 100 候选金额随渠道筛选收窄，DAX 不显式处理
- inv 表无 platform / shop_name 字段：库存侧指标（EOH / In-transit / Replenishment / Alert / Available Sizes / ST% 库存分母 / Weeks Cover 分子）不受渠道筛选影响——trade 侧受筛选、inv 侧全量的口径不对称为模型物理限制（ST% / Weeks Cover 分子分母渠道口径不对称，业务需知悉）

---

## 2. 现状分析

- 数据底表 `s02_trade_sku_data_d`（SKU 粒度交易表，dt 日粒度）：net_sales_amt 为 Power Query 取数新增列（行级 `ROUND(product_qty * sales_price, 6)` 生成，模型内存在，数据库无此列——测试 SQL 验证时按行级乘积还原）；product_qty 为净销售数量口径字段；md_price / msrp 为 MD 折扣价 / 吊牌价（MD 公式行级乘积字段）；主键维度字段 spu_id / sku_id / product_type / special_series 与一对一属性字段 us_style / ax_class / spu_img_url 齐备（已逐一核对数据字典）
- 数据底表 `s02_inventory_stock_sales_detail_d`（库存+销售+补货 SKU 模型表，dt 日快照，唯一键 dt + sku_id）：stock_inv_qty（在库库存，EOH 口径）、in_trans_inv_qty（在途库存）、reph_qty（补货数量，数仓预计算）、inv_qty（在库库存数量，Available Sizes 判定字段）、oos_tag（缺货标签）、computed_product_tag（商品分层标签：hero model / slow mover / normal）、special_supply（特供标识）、sku_size（尺码）齐备；spu_id / sku_id / product_type / special_series 同名桥接字段齐备（已逐一核对数据字典）；**无 platform / shop_name 字段**（渠道筛选不影响库存侧）
- 两张事实表之间无模型关系：行维度值向库存类指标的传递经 DAX TREATAS 显式桥接
- 日期筛选器（Min_This / Max_This）为断开维度，时间范围在 DAX 中显式筛选；MTD / YTD 起点字段（Fiscal_Month_First_Day / Fiscal_Year_First_Day）在 Slicer_Time_Frame_Max_This 表
- Slicer_Platform_Selection / Slicer_Store_Name 与 trade 表一对多关联（渠道筛选自动传导，DAX 不显式处理）；Slicer_Currency_Selection 为断开维度，汇率与符号经 SELECTEDVALUE 读取
- 字段名与日期字段（dt）已逐一核对数据字典

---

## 3. 方案设计

### 3.1 度量值分层

```
Rank（视觉级筛选 + 行排序依据，两个度量）
←  候选集：ALL(trade 主键三列)——三元组全量组合（清除行分组筛选与
      视觉级筛选器落地的跨列组合筛选，保留 Platform / Store 及其余
      外部切片器筛选）
←  候选金额物化：ADDCOLUMNS @Amt（this period sum(net_sales_amt)，
      上下文转换叠加候选三元组）
←  RANK(DENSE, FILTER(候选, 非空白主键 && @Amt 非空),
      ORDERBY(@Amt DESC, 主键三列 ASC))——四键决胜，名次唯一
←  外层 IF 双拦截：主键空白 / 当期无金额 → BLANK（视觉级区间筛选排除）
↓
Value（口径计算，13 个指标各一）
←  trade 侧：时间范围显式筛选，行分组筛选自动传导，零分支
←  inv 侧：ISINSCOPE(trade[spu_id]) 判定 → IF 标量双分支
      TREATAS 三列交集桥接 + inv[dt] = 快照日（单日时点）
←  金额类 Value 层完成币种汇率换算（原始 CNY ÷ Currency_ExchangeRate）
↓
Display（格式化显示）
←  currency: 币种符号 & FORMAT(#,##0)；integer: FORMAT(#,##0)
←  percent_0dp: FORMAT(#,##0%)；decimal_1dp: FORMAT(#,##0.0)
←  文本类（Alert / Available Sizes）: BLANK 显示 "-"
←  BLANK 统一显示 "-"
↓
属性度量（单度量直出，无 Display 层）
←  一对一属性：SELECTEDVALUE(trade[us_style / ax_class / spu_img_url])
←  inv 属性：TREATAS 桥接——SKU 表单值，SPU 表 distinct 顿号拼接
```

### 3.2 Top 100 行筛选机制

每个表格视觉对象配置两条视觉级筛选器：

| 筛选器 | 条件 | 作用 |
| --- | --- | --- |
| Item Stockout SPU Rank（SKU 表用 SKU Rank） | 介于 1 与 100（含） | 仅显示排名前 100 的行组合（名次唯一，恰好 100 行） |
| Item Stockout SLS Amt Value | 不为空 | 双保险——Rank 对当期无金额行返回 BLANK，被区间筛选排除 |

机制说明：

- 视觉级筛选器对 Rank 的取值发生在筛选生效前（真实排名），行按真实名次保留
- Rank 度量对空白主键 / 当期无金额行返回 BLANK；数值筛选「介于 1 与 100」对 BLANK 判定为不在区间内（BLANK 视为 0），此类行被排除——**不可仅配置「小于或等于 100」**，BLANK 会被放行
- 视觉级 Rank 筛选器落地为行分组三列的跨列组合筛选，Rank 度量自身求值不受影响（度量筛选器先求值后筛行）；候选集以 ALL(主键三列) 整体清除（单列 ALL 清不掉跨列组合筛选，三列全涉及才能清除干净）

### 3.3 排名候选集构建

- relation：`FILTER(ADDCOLUMNS(ALL(trade[spu_id], trade[product_type], trade[special_series]), "@Amt", CALCULATE(SUM(net_sales_amt), dt 条件)), 主键非空白 && [@Amt] 非空)`
  - ALL(主键三列) 生成全量三元组组合（同表 auto-exist 为实际存在组合），同时清除行分组筛选与视觉级筛选器落地的组合筛选；Platform / Store / 其余商品维度切片器筛选保留（候选金额与当前筛选上下文同口径）
  - ADDCOLUMNS 物化候选金额：上下文转换将候选三元组叠加于当前筛选上下文——一对一属性列不在行分组（经值区域度量输出），无残留行筛选污染候选金额
  - FILTER 排除空白主键与当期无金额候选：不占名次（避免其排序位置使有效行名次整体偏移导致区间筛选误排）
- ORDERBY：`[@Amt] DESC + 主键三列 ASC`——金额降序为第一序，三元组字母序逐级决胜，元组唯一 → 名次严格连续唯一；RANK 无 value 参数，当前行经 ORDERBY 中的 relation 列与候选行匹配确定名次
- 排名基于原始 CNY 金额聚合（不经币种换算）

### 3.4 inv 侧 TREATAS 三元组桥接

行维度值向 s02_inventory_stock_sales_detail_d 的传递（IF 标量双分支，以 SPU 表分支为例）：

```dax
IF(
    ISINSCOPE('s02_trade_sku_data_d'[spu_id]),
    CALCULATE(
        SUM('s02_inventory_stock_sales_detail_d'[stock_inv_qty]),
        TREATAS(VALUES('s02_trade_sku_data_d'[spu_id]), 's02_inventory_stock_sales_detail_d'[spu_id]),
        TREATAS(VALUES('s02_trade_sku_data_d'[product_type]), 's02_inventory_stock_sales_detail_d'[product_type]),
        TREATAS(VALUES('s02_trade_sku_data_d'[special_series]), 's02_inventory_stock_sales_detail_d'[special_series]),
        's02_inventory_stock_sales_detail_d'[dt] = __EndPeriodDate
    ),
    CALCULATE( ... sku_id 分支同构，锚点列换 TREATAS(VALUES(trade[sku_id]), inv[sku_id]) ... )
)
```

- **三列 TREATAS 交集**：锚点列（spu_id / sku_id）+ product_type + special_series 各自 TREATAS 传递当前行单值，交集 = inv 中该三元组的全部行（SPU 表 = 该 spu 该组合下全部 sku 行；SKU 表 = 快照日单行）
- **IF 标量双分支**：ISINSCOPE(trade[spu_id]) 判定当前表格（两表互斥显示，行分组必含 spu_id / sku_id 其一）；分支内 CALCULATE / CONCATENATEX 聚合返回标量后经 IF 选择——TREATAS / CALCULATETABLE 不经 IF 传递（IF 分支返回表会被降级为标量）
- **期末快照日**：`CALCULATE(MAX(inv[dt]), REMOVEFILTERS(整表), 范围条件)` 全表确定性取值，不随行上下文 / 切片器漂移
- 与 inv 表已建关系的外部维度切片器（Division 等）经 CALCULATE / CALCULATETABLE 自动传导，不在桥接参数内重复处理

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
// 用途: SPU 表格当前行组合 (spu_id, product_type, special_series) 按
//       This Period sum(net_sales_amt) 的降序排名，用于视觉级筛选器
//       固定 Top 100 行并作为行排序依据（值区域升序排序）
// 依赖: Slicer_Time_Frame_Min_This[TimeFrame_Min] / Slicer_Time_Frame_Max_This[TimeFrame_Max]
// 口径: 渠道（Platform / Store）与其余商品维度切片器筛选组合下，按行组合
//       粒度 This Period sum(net_sales_amt) 降序排名
// 排名语义: 金额降序为第一序；金额相同的行按 spu_id → product_type →
//       special_series 字母序升序逐级决胜，名次严格连续唯一（1、2、3、……），
//       Top 100 恰好 100 行、边界确定——行主键为三元组，决胜链覆盖全键
// 函数: RANK 窗口函数（Power BI Desktop 2022 年 9 月及以后版本可用）——
//       无 value 参数，当前行经 ORDERBY 中的 relation 列与候选行匹配
//       确定名次；元组唯一时 DENSE 名次即排序位置
// 候选集: ADDCOLUMNS(ALL(主键三列), @Amt) 物化候选金额——ALL 三列生成
//       全量三元组组合，同时清除行分组筛选与视觉级筛选器落地的跨列
//       组合筛选（单列 ALL 清不掉组合筛选），保留外部切片器筛选；
//       FILTER 排除空白主键与当期无金额候选（不占名次，避免其排序
//       位置使有效行名次整体偏移导致区间筛选误排）
// 空白/无金额拦截: 当前行主键空白或当期无金额时返回 BLANK，被视觉级
//       区间筛选（介于 1 与 100）排除（relation 无匹配行 + 外层 IF 显式
//       拦截，双保险）
// 排名金额: 原始 CNY 聚合，不经币种换算（除以同一正汇率不改变相对顺序）
// ========================================

// ── This Period 时间区间 ──
VAR __PeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Min_This[TimeFrame_Min])
VAR __PeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

// ── 当前行主键（空白/空字符拦截的判定依据）──
VAR __CurrentSpuId = SELECTEDVALUE('s02_trade_sku_data_d'[spu_id])

// ── 当前行组合的 This Period 净销售金额（无金额行返回 BLANK 的拦截依据）──
VAR __CurrentAmt =
    CALCULATE(
        SUM('s02_trade_sku_data_d'[net_sales_amt]),
        's02_trade_sku_data_d'[dt] >= __PeriodMin,
        's02_trade_sku_data_d'[dt] <= __PeriodMax
    )

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
                        ALL(
                            's02_trade_sku_data_d'[spu_id],
                            's02_trade_sku_data_d'[product_type],
                            's02_trade_sku_data_d'[special_series]
                        ),
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
                    's02_trade_sku_data_d'[spu_id], ASC,
                    's02_trade_sku_data_d'[product_type], ASC,
                    's02_trade_sku_data_d'[special_series], ASC
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
// 用途: SKU 表格当前行组合 (sku_id, product_type, special_series) 按
//       This Period sum(net_sales_amt) 的降序排名（机制同 SPU Rank）
// 依赖: Slicer_Time_Frame_Min_This[TimeFrame_Min] / Slicer_Time_Frame_Max_This[TimeFrame_Max]
// 口径: 同 SPU Rank，行主键锚点列换 sku_id
// 排名语义: 金额降序 + sku_id → product_type → special_series 字母序
//       逐级决胜，名次严格连续唯一
// 候选集: ADDCOLUMNS(ALL(sku_id, product_type, special_series), @Amt)——
//       机制同 SPU Rank（见 §4.1 注释）
// ========================================

// ── This Period 时间区间 ──
VAR __PeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Min_This[TimeFrame_Min])
VAR __PeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

// ── 当前行主键 ──
VAR __CurrentSkuId = SELECTEDVALUE('s02_trade_sku_data_d'[sku_id])

// ── 当前行组合的 This Period 净销售金额 ──
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
                        ALL(
                            's02_trade_sku_data_d'[sku_id],
                            's02_trade_sku_data_d'[product_type],
                            's02_trade_sku_data_d'[special_series]
                        ),
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
                    's02_trade_sku_data_d'[sku_id], ASC,
                    's02_trade_sku_data_d'[product_type], ASC,
                    's02_trade_sku_data_d'[special_series], ASC
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
// 用途: 当前行组合（spu_id / sku_id 表通用）This Period 净销售金额
//       （当前币种），Top 100 排序依据指标
// 依赖: Slicer_Time_Frame_Min_This[TimeFrame_Min] / Slicer_Time_Frame_Max_This[TimeFrame_Max]
//       Slicer_Currency_Selection[Currency_ExchangeRate]
// 口径: 时间范围看 this period；该行组合下 sum(net_sales_amt)
// 数据底表: s02_trade_sku_data_d
// 行维度传递: 行分组（spu_id 或 sku_id + product_type + special_series）
//       筛选自动落在 trade 表对应列上，聚合自动限定当前行组合——
//       单度量双表通用，无需分支
// 渠道: Platform / Store 切片器经模型关系自动传导（不显式处理）
// 币种: 数据底表仅存 CNY，Value 层换算为当前币种金额（原始值 ÷ 汇率）；
//       RMB 汇率 = 1 时换算前后值相同
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
// 用途: 当前行组合 This Period 净销售数量，单度量双表通用
// 依赖: Slicer_Time_Frame_Min_This[TimeFrame_Min] / Slicer_Time_Frame_Max_This[TimeFrame_Max]
// 口径: 时间范围看 this period；该行组合下 sum(product_qty)
// 数据底表: s02_trade_sku_data_d
// 行维度传递: 行分组筛选自动传导，无需分支
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
// 用途: 当前行组合期末库存数量（This 期末快照日单日时点），单度量双表通用
// 依赖: Slicer_Time_Frame_Max_This[TimeFrame_Min] / [TimeFrame_Max]
// 口径: 时间范围看 this period 最后一天（end period 范围内最后一个快照日）；
//       该行组合下 sum(stock_inv_qty)
// 数据底表: s02_inventory_stock_sales_detail_d
// 行维度传递: 两表无模型关系——ISINSCOPE(trade[spu_id]) 判定当前表格，
//       TREATAS 三列交集桥接（锚点列 spu_id / sku_id + product_type +
//       special_series，各自传当前行单值），IF 标量双分支
//       （分支 CALCULATE 返回标量后经 IF 选择，TREATAS 不经 IF 传递）
// 渠道: inv 表无 platform / shop_name 字段，本指标不受渠道筛选影响
// 说明: 期末时点只取快照日单日，对区间求和会重复计数库存
// ========================================

// ── End Period This 时间范围（期末时点类）──
VAR __EndPeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Min])
VAR __EndPeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

// ── This 期末快照日：end period 范围内最后一个有数据的日期（单日时点）──
// REMOVEFILTERS(整表) 保证快照日不随行上下文 / 切片器漂移
VAR __EndPeriodDate =
    CALCULATE(
        MAX('s02_inventory_stock_sales_detail_d'[dt]),
        REMOVEFILTERS('s02_inventory_stock_sales_detail_d'),
        's02_inventory_stock_sales_detail_d'[dt] >= __EndPeriodMin,
        's02_inventory_stock_sales_detail_d'[dt] <= __EndPeriodMax
    )

// ── 表判定（两表互斥显示，行分组必含 spu_id / sku_id 其一）──
VAR __InSpuId = ISINSCOPE('s02_trade_sku_data_d'[spu_id])

RETURN
    IF(
        __InSpuId,
        // ── SPU 表分支：TREATAS 传 (spu_id, product_type, special_series) 三列交集 ──
        CALCULATE(
            SUM('s02_inventory_stock_sales_detail_d'[stock_inv_qty]),
            TREATAS(
                VALUES('s02_trade_sku_data_d'[spu_id]),
                's02_inventory_stock_sales_detail_d'[spu_id]
            ),
            TREATAS(
                VALUES('s02_trade_sku_data_d'[product_type]),
                's02_inventory_stock_sales_detail_d'[product_type]
            ),
            TREATAS(
                VALUES('s02_trade_sku_data_d'[special_series]),
                's02_inventory_stock_sales_detail_d'[special_series]
            ),
            's02_inventory_stock_sales_detail_d'[dt] = __EndPeriodDate
        ),
        // ── SKU 表分支：锚点列换 sku_id（快照日单行）──
        CALCULATE(
            SUM('s02_inventory_stock_sales_detail_d'[stock_inv_qty]),
            TREATAS(
                VALUES('s02_trade_sku_data_d'[sku_id]),
                's02_inventory_stock_sales_detail_d'[sku_id]
            ),
            TREATAS(
                VALUES('s02_trade_sku_data_d'[product_type]),
                's02_inventory_stock_sales_detail_d'[product_type]
            ),
            TREATAS(
                VALUES('s02_trade_sku_data_d'[special_series]),
                's02_inventory_stock_sales_detail_d'[special_series]
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
// 用途: 当前行组合在途库存数量（This 期末快照日单日时点），单度量双表通用
// 依赖: Slicer_Time_Frame_Max_This[TimeFrame_Min] / [TimeFrame_Max]
// 口径: 看所选时间范围 end period 最后一天；该行组合下 sum(in_trans_inv_qty)
// 数据底表: s02_inventory_stock_sales_detail_d
// 行维度传递: 同 EOH Unit（TREATAS 三列交集 + IF 标量双分支，见 §4.7）
// 渠道: inv 表无渠道字段，本指标不受渠道筛选影响
// 说明: 期末时点只取快照日单日
// ========================================

// ── End Period This 时间范围 ──
VAR __EndPeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Min])
VAR __EndPeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

// ── This 期末快照日 ──
VAR __EndPeriodDate =
    CALCULATE(
        MAX('s02_inventory_stock_sales_detail_d'[dt]),
        REMOVEFILTERS('s02_inventory_stock_sales_detail_d'),
        's02_inventory_stock_sales_detail_d'[dt] >= __EndPeriodMin,
        's02_inventory_stock_sales_detail_d'[dt] <= __EndPeriodMax
    )

// ── 表判定 ──
VAR __InSpuId = ISINSCOPE('s02_trade_sku_data_d'[spu_id])

RETURN
    IF(
        __InSpuId,
        CALCULATE(
            SUM('s02_inventory_stock_sales_detail_d'[in_trans_inv_qty]),
            TREATAS(
                VALUES('s02_trade_sku_data_d'[spu_id]),
                's02_inventory_stock_sales_detail_d'[spu_id]
            ),
            TREATAS(
                VALUES('s02_trade_sku_data_d'[product_type]),
                's02_inventory_stock_sales_detail_d'[product_type]
            ),
            TREATAS(
                VALUES('s02_trade_sku_data_d'[special_series]),
                's02_inventory_stock_sales_detail_d'[special_series]
            ),
            's02_inventory_stock_sales_detail_d'[dt] = __EndPeriodDate
        ),
        CALCULATE(
            SUM('s02_inventory_stock_sales_detail_d'[in_trans_inv_qty]),
            TREATAS(
                VALUES('s02_trade_sku_data_d'[sku_id]),
                's02_inventory_stock_sales_detail_d'[sku_id]
            ),
            TREATAS(
                VALUES('s02_trade_sku_data_d'[product_type]),
                's02_inventory_stock_sales_detail_d'[product_type]
            ),
            TREATAS(
                VALUES('s02_trade_sku_data_d'[special_series]),
                's02_inventory_stock_sales_detail_d'[special_series]
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
// 用途: 当前行组合的库存周转周数（(期末库存 + 在途) / This Period 销售数量），
//       跨 trade + inv 双表，单度量双表通用
// 依赖: Slicer_Time_Frame_Min_This[TimeFrame_Min] / Slicer_Time_Frame_Max_This[TimeFrame_Max]
//       （销售侧区间）；Slicer_Time_Frame_Max_This[TimeFrame_Min] / [TimeFrame_Max]
//       （库存侧期末时点）
// 口径: 销售数量看 this period 区间 sum(product_qty)；库存相关看 end period
//       最后一天 sum(stock_inv_qty) + sum(in_trans_inv_qty)；
//       (库存 + 在途) / 销售数量
// 口径修正: 原始口径计算指标列分子分母写反，以业务定义为准（分子库存+在途，
//       分母销售数量——口径 §25 修正记录）
// 数据底表: s02_trade_sku_data_d（分母）；s02_inventory_stock_sales_detail_d（分子）
// 行维度传递: 分母行分组筛选自动传导；分子 TREATAS 三列交集 + IF 标量双分支
// 边界: 销售数量为 0 或 BLANK 时返回 BLANK（DIVIDE 拦截，避免失真周数）
// ========================================

// ── This Period 时间区间（销售侧分母）──
VAR __PeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Min_This[TimeFrame_Min])
VAR __PeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

// ── End Period This 时间范围（库存侧期末时点）──
VAR __EndPeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Min])
VAR __EndPeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

// ── This 期末快照日 ──
VAR __EndPeriodDate =
    CALCULATE(
        MAX('s02_inventory_stock_sales_detail_d'[dt]),
        REMOVEFILTERS('s02_inventory_stock_sales_detail_d'),
        's02_inventory_stock_sales_detail_d'[dt] >= __EndPeriodMin,
        's02_inventory_stock_sales_detail_d'[dt] <= __EndPeriodMax
    )

// ── 表判定 ──
VAR __InSpuId = ISINSCOPE('s02_trade_sku_data_d'[spu_id])

// ── 分子：期末库存 + 在途（快照日单日，TREATAS 三列交集双分支）──
VAR __InvUnits =
    IF(
        __InSpuId,
        CALCULATE(
            SUM('s02_inventory_stock_sales_detail_d'[stock_inv_qty])
                + SUM('s02_inventory_stock_sales_detail_d'[in_trans_inv_qty]),
            TREATAS(
                VALUES('s02_trade_sku_data_d'[spu_id]),
                's02_inventory_stock_sales_detail_d'[spu_id]
            ),
            TREATAS(
                VALUES('s02_trade_sku_data_d'[product_type]),
                's02_inventory_stock_sales_detail_d'[product_type]
            ),
            TREATAS(
                VALUES('s02_trade_sku_data_d'[special_series]),
                's02_inventory_stock_sales_detail_d'[special_series]
            ),
            's02_inventory_stock_sales_detail_d'[dt] = __EndPeriodDate
        ),
        CALCULATE(
            SUM('s02_inventory_stock_sales_detail_d'[stock_inv_qty])
                + SUM('s02_inventory_stock_sales_detail_d'[in_trans_inv_qty]),
            TREATAS(
                VALUES('s02_trade_sku_data_d'[sku_id]),
                's02_inventory_stock_sales_detail_d'[sku_id]
            ),
            TREATAS(
                VALUES('s02_trade_sku_data_d'[product_type]),
                's02_inventory_stock_sales_detail_d'[product_type]
            ),
            TREATAS(
                VALUES('s02_trade_sku_data_d'[special_series]),
                's02_inventory_stock_sales_detail_d'[special_series]
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
// 用途: end period 所在财月第一天至 end period 最后一天的净销售数量，
//       单度量双表通用
// 依赖: Slicer_Time_Frame_Max_This[Fiscal_Month_First_Day] / [TimeFrame_Max]
// 口径: 时间范围看 this period 的 end period 所在财月第一天至 end period
//       最后一天；该行组合下 sum(product_qty)
// 数据底表: s02_trade_sku_data_d
// 行维度传递: 行分组筛选自动传导，无需分支
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
// 用途: end period 所在财年第一天至 end period 最后一天的净销售数量，
//       单度量双表通用
// 依赖: Slicer_Time_Frame_Max_This[Fiscal_Year_First_Day] / [TimeFrame_Max]
// 口径: 时间范围看 this period 的 end period 所在财年第一天至 end period
//       最后一天；该行组合下 sum(product_qty)
// 数据底表: s02_trade_sku_data_d
// 行维度传递: 行分组筛选自动传导，无需分支
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
// 用途: 当前行组合的售罄率——This Period 销售数量 /（This Period 销售数量 +
//       期末库存数量），跨 trade + inv 双表，单度量双表通用
// 依赖: Slicer_Time_Frame_Min_This[TimeFrame_Min] / Slicer_Time_Frame_Max_This[TimeFrame_Max]
//       （销售侧区间）；Slicer_Time_Frame_Max_This[TimeFrame_Min] / [TimeFrame_Max]
//       （库存侧期末时点）
// 口径: 销售数量看 this period 区间；期末库存数量看 end period 最后一天；
//       sales.sum(product_qty) / (sales.sum(product_qty) + inv.sum(stock_inv_qty))
// 口径修正: 原始口径公式为金额口径（net_sales_amt / msrp_inv_amt），已确认
//       修正为数量口径（口径 §28 修正记录）
// 数据底表: s02_trade_sku_data_d（sales）；s02_inventory_stock_sales_detail_d（inv）
// 行维度传递: 销售侧行分组筛选自动传导；库存侧 TREATAS 三列交集 +
//       IF 标量双分支
// 渠道: 销售侧受 Platform / Store 筛选影响，库存侧不受（inv 表无渠道字段）——
//       分子分母渠道口径不对称为模型物理限制，业务需知悉
// ========================================

// ── This Period 时间区间（销售侧）──
VAR __PeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Min_This[TimeFrame_Min])
VAR __PeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

// ── End Period This 时间范围（库存侧期末时点）──
VAR __EndPeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Min])
VAR __EndPeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

// ── This 期末快照日 ──
VAR __EndPeriodDate =
    CALCULATE(
        MAX('s02_inventory_stock_sales_detail_d'[dt]),
        REMOVEFILTERS('s02_inventory_stock_sales_detail_d'),
        's02_inventory_stock_sales_detail_d'[dt] >= __EndPeriodMin,
        's02_inventory_stock_sales_detail_d'[dt] <= __EndPeriodMax
    )

// ── 表判定 ──
VAR __InSpuId = ISINSCOPE('s02_trade_sku_data_d'[spu_id])

// ── 分子：This Period 净销售数量（行分组筛选自动传导）──
VAR __SlsUnits =
    CALCULATE(
        SUM('s02_trade_sku_data_d'[product_qty]),
        's02_trade_sku_data_d'[dt] >= __PeriodMin,
        's02_trade_sku_data_d'[dt] <= __PeriodMax
    )

// ── 库存加项：期末库存数量（快照日单日，TREATAS 三列交集双分支）──
VAR __InvUnits =
    IF(
        __InSpuId,
        CALCULATE(
            SUM('s02_inventory_stock_sales_detail_d'[stock_inv_qty]),
            TREATAS(
                VALUES('s02_trade_sku_data_d'[spu_id]),
                's02_inventory_stock_sales_detail_d'[spu_id]
            ),
            TREATAS(
                VALUES('s02_trade_sku_data_d'[product_type]),
                's02_inventory_stock_sales_detail_d'[product_type]
            ),
            TREATAS(
                VALUES('s02_trade_sku_data_d'[special_series]),
                's02_inventory_stock_sales_detail_d'[special_series]
            ),
            's02_inventory_stock_sales_detail_d'[dt] = __EndPeriodDate
        ),
        CALCULATE(
            SUM('s02_inventory_stock_sales_detail_d'[stock_inv_qty]),
            TREATAS(
                VALUES('s02_trade_sku_data_d'[sku_id]),
                's02_inventory_stock_sales_detail_d'[sku_id]
            ),
            TREATAS(
                VALUES('s02_trade_sku_data_d'[product_type]),
                's02_inventory_stock_sales_detail_d'[product_type]
            ),
            TREATAS(
                VALUES('s02_trade_sku_data_d'[special_series]),
                's02_inventory_stock_sales_detail_d'[special_series]
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
// 用途: 当前行组合的件单价（This Period 净销售金额 / 净销售数量，当前币种），
//       单度量双表通用
// 依赖: Slicer_Time_Frame_Min_This[TimeFrame_Min] / Slicer_Time_Frame_Max_This[TimeFrame_Max]
//       Slicer_Currency_Selection[Currency_ExchangeRate]
// 口径: 时间范围看 this period；sum(net_sales_amt) / sum(product_qty)
// 数据底表: s02_trade_sku_data_d
// 行维度传递: 行分组筛选自动传导，无需分支
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
// 用途: 当前行组合的平均折扣（1 - 折扣价加权 / 吊牌价加权），单度量双表通用
// 依赖: Slicer_Time_Frame_Min_This[TimeFrame_Min] / Slicer_Time_Frame_Max_This[TimeFrame_Max]
// 口径: 时间范围看 this period；
//       1 - sum(product_qty × md_price) / sum(product_qty × msrp)
// 数据底表: s02_trade_sku_data_d（md_price / msrp 为行级字段）
// 行维度传递: 行分组筛选自动传导，无需分支
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

### 4.23 Item Stockout Alert Value（缺货/滞销/其他判定）

```dax
Item Stockout Alert Value =
// ========================================
// 度量值: Item Stockout Alert Value
// 中文名: 缺货/滞销/其他判定
// Display Folder: Item Stockout & Slow Mover Alert\Base Metrics
// 用途: 当前行组合的预警判定（快照日 oos_tag 与 computed_product_tag 共同
//       决定），单度量双表通用
// 依赖: Slicer_Time_Frame_Max_This[TimeFrame_Min] / [TimeFrame_Max]
// 口径: 判定规则（口径 §31）——
//       缺货：oos_tag 不为空 且 computed_product_tag <> 'slow mover'
//       滞销：oos_tag 不为空 且 computed_product_tag = 'slow mover'
//       其他：oos_tag 为空
// 聚合规则（SPU 表）：该 spu 组合下多个 sku 的判定结果取最高预警级别，
//       优先级 缺货 > 滞销 > 其他（任一 sku 缺货 → 该行"缺货"；
//       否则任一 sku 滞销 → "滞销"；否则"其他"）；SKU 表为快照日单行，
//       判定自然退化为该行自身
// 数据底表: s02_inventory_stock_sales_detail_d
// 行维度传递: TREATAS 三列交集取该组合快照日行集，IF 标量双分支
// 空值处理: oos_tag 判空含空字符（NOT ISBLANK 且 LEN(TRIM) > 0）；
//       该组合在快照日无 inv 记录时返回 BLANK（显示 "-"，不判"其他"——
//       "其他"语义为有记录但 oos_tag 为空）
// 渠道: inv 表无渠道字段，本指标不受渠道筛选影响
// ========================================

// ── End Period This 时间范围 ──
VAR __EndPeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Min])
VAR __EndPeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

// ── This 期末快照日 ──
VAR __EndPeriodDate =
    CALCULATE(
        MAX('s02_inventory_stock_sales_detail_d'[dt]),
        REMOVEFILTERS('s02_inventory_stock_sales_detail_d'),
        's02_inventory_stock_sales_detail_d'[dt] >= __EndPeriodMin,
        's02_inventory_stock_sales_detail_d'[dt] <= __EndPeriodMax
    )

// ── 表判定 ──
VAR __InSpuId = ISINSCOPE('s02_trade_sku_data_d'[spu_id])

RETURN
    IF(
        __InSpuId,
        // ── SPU 表分支：该组合全部 sku 行判定结果的最高预警级别 ──
        VAR __InvRows_Spu =
            CALCULATETABLE(
                's02_inventory_stock_sales_detail_d',
                TREATAS(
                    VALUES('s02_trade_sku_data_d'[spu_id]),
                    's02_inventory_stock_sales_detail_d'[spu_id]
                ),
                TREATAS(
                    VALUES('s02_trade_sku_data_d'[product_type]),
                    's02_inventory_stock_sales_detail_d'[product_type]
                ),
                TREATAS(
                    VALUES('s02_trade_sku_data_d'[special_series]),
                    's02_inventory_stock_sales_detail_d'[special_series]
                ),
                's02_inventory_stock_sales_detail_d'[dt] = __EndPeriodDate
            )
        VAR __HasRow_Spu = COUNTROWS(__InvRows_Spu) > 0
        VAR __HasOos_Spu =
            COUNTROWS(
                FILTER(
                    __InvRows_Spu,
                    NOT ISBLANK('s02_inventory_stock_sales_detail_d'[oos_tag])
                        && LEN(TRIM('s02_inventory_stock_sales_detail_d'[oos_tag])) > 0
                        && 's02_inventory_stock_sales_detail_d'[computed_product_tag] <> "slow mover"
                )
            ) > 0
        VAR __HasSlow_Spu =
            COUNTROWS(
                FILTER(
                    __InvRows_Spu,
                    NOT ISBLANK('s02_inventory_stock_sales_detail_d'[oos_tag])
                        && LEN(TRIM('s02_inventory_stock_sales_detail_d'[oos_tag])) > 0
                        && 's02_inventory_stock_sales_detail_d'[computed_product_tag] = "slow mover"
                )
            ) > 0
        RETURN
            IF(
                NOT __HasRow_Spu,
                BLANK(),
                IF(__HasOos_Spu, "缺货", IF(__HasSlow_Spu, "滞销", "其他"))
            )
        ,
        // ── SKU 表分支：快照日单行判定（优先级结构同构，单行自然退化）──
        VAR __InvRows_Sku =
            CALCULATETABLE(
                's02_inventory_stock_sales_detail_d',
                TREATAS(
                    VALUES('s02_trade_sku_data_d'[sku_id]),
                    's02_inventory_stock_sales_detail_d'[sku_id]
                ),
                TREATAS(
                    VALUES('s02_trade_sku_data_d'[product_type]),
                    's02_inventory_stock_sales_detail_d'[product_type]
                ),
                TREATAS(
                    VALUES('s02_trade_sku_data_d'[special_series]),
                    's02_inventory_stock_sales_detail_d'[special_series]
                ),
                's02_inventory_stock_sales_detail_d'[dt] = __EndPeriodDate
            )
        VAR __HasRow_Sku = COUNTROWS(__InvRows_Sku) > 0
        VAR __HasOos_Sku =
            COUNTROWS(
                FILTER(
                    __InvRows_Sku,
                    NOT ISBLANK('s02_inventory_stock_sales_detail_d'[oos_tag])
                        && LEN(TRIM('s02_inventory_stock_sales_detail_d'[oos_tag])) > 0
                        && 's02_inventory_stock_sales_detail_d'[computed_product_tag] <> "slow mover"
                )
            ) > 0
        VAR __HasSlow_Sku =
            COUNTROWS(
                FILTER(
                    __InvRows_Sku,
                    NOT ISBLANK('s02_inventory_stock_sales_detail_d'[oos_tag])
                        && LEN(TRIM('s02_inventory_stock_sales_detail_d'[oos_tag])) > 0
                        && 's02_inventory_stock_sales_detail_d'[computed_product_tag] = "slow mover"
                )
            ) > 0
        RETURN
            IF(
                NOT __HasRow_Sku,
                BLANK(),
                IF(__HasOos_Sku, "缺货", IF(__HasSlow_Sku, "滞销", "其他"))
            )
    )
```

### 4.24 Item Stockout Alert Display（预警判定显示）

```dax
Item Stockout Alert Display =
// ========================================
// 度量值: Item Stockout Alert Display
// 中文名: 缺货/滞销/其他判定显示
// Display Folder: Item Stockout & Slow Mover Alert\Formatting
// 用途: 文本直出（缺货 / 滞销 / 其他）；BLANK 显示 "-"
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
// 用途: 当前行组合期末在库库存（inv_qty > 0）的尺码枚举值，多值顿号拼接，
//       单度量双表通用
// 依赖: Slicer_Time_Frame_Max_This[TimeFrame_Min] / [TimeFrame_Max]
// 口径: 看所选时间范围 end period 最后一天；该行组合下 distinct sku_size
//       where inv_qty > 0（口径 §32）
// 数据底表: s02_inventory_stock_sales_detail_d
// 行维度传递: TREATAS 三列交集 + IF 标量双分支（分支 CONCATENATEX 返回
//       文本标量后经 IF 选择）
// 拼接: 多值用顿号（、）拼接，按 sku_size 字母序升序
// 渠道: inv 表无渠道字段，本指标不受渠道筛选影响
// ========================================

// ── End Period This 时间范围 ──
VAR __EndPeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Min])
VAR __EndPeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

// ── This 期末快照日 ──
VAR __EndPeriodDate =
    CALCULATE(
        MAX('s02_inventory_stock_sales_detail_d'[dt]),
        REMOVEFILTERS('s02_inventory_stock_sales_detail_d'),
        's02_inventory_stock_sales_detail_d'[dt] >= __EndPeriodMin,
        's02_inventory_stock_sales_detail_d'[dt] <= __EndPeriodMax
    )

// ── 表判定 ──
VAR __InSpuId = ISINSCOPE('s02_trade_sku_data_d'[spu_id])

RETURN
    IF(
        __InSpuId,
        CONCATENATEX(
            CALCULATETABLE(
                VALUES('s02_inventory_stock_sales_detail_d'[sku_size]),
                TREATAS(
                    VALUES('s02_trade_sku_data_d'[spu_id]),
                    's02_inventory_stock_sales_detail_d'[spu_id]
                ),
                TREATAS(
                    VALUES('s02_trade_sku_data_d'[product_type]),
                    's02_inventory_stock_sales_detail_d'[product_type]
                ),
                TREATAS(
                    VALUES('s02_trade_sku_data_d'[special_series]),
                    's02_inventory_stock_sales_detail_d'[special_series]
                ),
                's02_inventory_stock_sales_detail_d'[dt] = __EndPeriodDate,
                's02_inventory_stock_sales_detail_d'[inv_qty] > 0
            ),
            's02_inventory_stock_sales_detail_d'[sku_size], "、",
            's02_inventory_stock_sales_detail_d'[sku_size], ASC
        ),
        CONCATENATEX(
            CALCULATETABLE(
                VALUES('s02_inventory_stock_sales_detail_d'[sku_size]),
                TREATAS(
                    VALUES('s02_trade_sku_data_d'[sku_id]),
                    's02_inventory_stock_sales_detail_d'[sku_id]
                ),
                TREATAS(
                    VALUES('s02_trade_sku_data_d'[product_type]),
                    's02_inventory_stock_sales_detail_d'[product_type]
                ),
                TREATAS(
                    VALUES('s02_trade_sku_data_d'[special_series]),
                    's02_inventory_stock_sales_detail_d'[special_series]
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
// 用途: 当前行组合的补货数量（This 期末快照日单日时点），单度量双表通用
// 依赖: Slicer_Time_Frame_Max_This[TimeFrame_Min] / [TimeFrame_Max]
// 口径: 看所选时间范围 end period 最后一天；该行组合下 sum(reph_qty)
//       （计算指标列直接取 reph_qty 字段——Definition 公式由数仓预计算实现，
//       口径 §33 以字段为准）
// 数据底表: s02_inventory_stock_sales_detail_d
// 行维度传递: 同 EOH Unit（TREATAS 三列交集 + IF 标量双分支，见 §4.7）
// 渠道: inv 表无渠道字段，本指标不受渠道筛选影响
// 说明: 期末时点只取快照日单日
// ========================================

// ── End Period This 时间范围 ──
VAR __EndPeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Min])
VAR __EndPeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

// ── This 期末快照日 ──
VAR __EndPeriodDate =
    CALCULATE(
        MAX('s02_inventory_stock_sales_detail_d'[dt]),
        REMOVEFILTERS('s02_inventory_stock_sales_detail_d'),
        's02_inventory_stock_sales_detail_d'[dt] >= __EndPeriodMin,
        's02_inventory_stock_sales_detail_d'[dt] <= __EndPeriodMax
    )

// ── 表判定 ──
VAR __InSpuId = ISINSCOPE('s02_trade_sku_data_d'[spu_id])

RETURN
    IF(
        __InSpuId,
        CALCULATE(
            SUM('s02_inventory_stock_sales_detail_d'[reph_qty]),
            TREATAS(
                VALUES('s02_trade_sku_data_d'[spu_id]),
                's02_inventory_stock_sales_detail_d'[spu_id]
            ),
            TREATAS(
                VALUES('s02_trade_sku_data_d'[product_type]),
                's02_inventory_stock_sales_detail_d'[product_type]
            ),
            TREATAS(
                VALUES('s02_trade_sku_data_d'[special_series]),
                's02_inventory_stock_sales_detail_d'[special_series]
            ),
            's02_inventory_stock_sales_detail_d'[dt] = __EndPeriodDate
        ),
        CALCULATE(
            SUM('s02_inventory_stock_sales_detail_d'[reph_qty]),
            TREATAS(
                VALUES('s02_trade_sku_data_d'[sku_id]),
                's02_inventory_stock_sales_detail_d'[sku_id]
            ),
            TREATAS(
                VALUES('s02_trade_sku_data_d'[product_type]),
                's02_inventory_stock_sales_detail_d'[product_type]
            ),
            TREATAS(
                VALUES('s02_trade_sku_data_d'[special_series]),
                's02_inventory_stock_sales_detail_d'[special_series]
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
// 用途: 当前行组合的 us_style 属性值（值区域展示列）
// 数据底表: s02_trade_sku_data_d
// 输出方式: 行分组（三元组）筛选下 SELECTEDVALUE 取单值——us_style 为
//       spu_id / sku_id 的一对一属性，行组合下可见值唯一；边角数据
//       同组合多值时返回 BLANK（显示空）
// ========================================
    SELECTEDVALUE('s02_trade_sku_data_d'[us_style])
```

### 4.30 Item Stockout AX Class（AX 分类，属性列）

```dax
Item Stockout AX Class =
// ========================================
// 度量值: Item Stockout AX Class
// 中文名: AX 分类（属性列）
// Display Folder: Item Stockout & Slow Mover Alert\Attributes
// 用途: 当前行组合的 ax_class 属性值（值区域展示列）
// 数据底表: s02_trade_sku_data_d
// 输出方式: 同 US Style（一对一属性，SELECTEDVALUE 单值）
// ========================================
    SELECTEDVALUE('s02_trade_sku_data_d'[ax_class])
```

### 4.31 Item Stockout SPU Image（商品图片，属性列）

```dax
Item Stockout SPU Image =
// ========================================
// 度量值: Item Stockout SPU Image
// 中文名: 商品图片（属性列）
// Display Folder: Item Stockout & Slow Mover Alert\Attributes
// 用途: 当前行组合的 spu_img_url 图片链接（值区域展示列，度量设置
//       数据类别 = 图像 URL 后显示图片）
// 数据底表: s02_trade_sku_data_d
// 输出方式: 同 US Style（一对一属性，SELECTEDVALUE 单值）
// 配置: 度量工具 → 数据类别 → 图像 URL；值区域列显示商品图片
// ========================================
    SELECTEDVALUE('s02_trade_sku_data_d'[spu_img_url])
```

### 4.32 Item Stockout Product Tag（商品分层标签，inv 属性列）

```dax
Item Stockout Product Tag =
// ========================================
// 度量值: Item Stockout Product Tag
// 中文名: 商品分层标签（属性列）
// Display Folder: Item Stockout & Slow Mover Alert\Attributes
// 用途: 当前行组合的商品分层标签（hero model / slow mover / normal），
//       底表 inv，单度量双表通用
// 依赖: Slicer_Time_Frame_Max_This[TimeFrame_Min] / [TimeFrame_Max]
// 口径: 属性列取快照日值（口径 §360：底表 s02_inventory_stock_sales_detail_d）
// 输出方式: SKU 表 = 快照日单行单值（MAX）；SPU 表 = 该组合全部 sku 值
//       distinct 顿号拼接（同一 spu 下不同 sku 分层可能不同，拼接保留
//       全部信息，与 Available Sizes 风格一致；如需单一值口径可改为 MAX）
// 行维度传递: TREATAS 三列交集 + IF 标量双分支
// 渠道: inv 表无渠道字段，本属性不受渠道筛选影响
// ========================================

// ── End Period This 时间范围 ──
VAR __EndPeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Min])
VAR __EndPeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

// ── This 期末快照日 ──
VAR __EndPeriodDate =
    CALCULATE(
        MAX('s02_inventory_stock_sales_detail_d'[dt]),
        REMOVEFILTERS('s02_inventory_stock_sales_detail_d'),
        's02_inventory_stock_sales_detail_d'[dt] >= __EndPeriodMin,
        's02_inventory_stock_sales_detail_d'[dt] <= __EndPeriodMax
    )

// ── 表判定 ──
VAR __InSpuId = ISINSCOPE('s02_trade_sku_data_d'[spu_id])

RETURN
    IF(
        __InSpuId,
        CONCATENATEX(
            CALCULATETABLE(
                VALUES('s02_inventory_stock_sales_detail_d'[computed_product_tag]),
                TREATAS(
                    VALUES('s02_trade_sku_data_d'[spu_id]),
                    's02_inventory_stock_sales_detail_d'[spu_id]
                ),
                TREATAS(
                    VALUES('s02_trade_sku_data_d'[product_type]),
                    's02_inventory_stock_sales_detail_d'[product_type]
                ),
                TREATAS(
                    VALUES('s02_trade_sku_data_d'[special_series]),
                    's02_inventory_stock_sales_detail_d'[special_series]
                ),
                's02_inventory_stock_sales_detail_d'[dt] = __EndPeriodDate
            ),
            's02_inventory_stock_sales_detail_d'[computed_product_tag], "、",
            's02_inventory_stock_sales_detail_d'[computed_product_tag], ASC
        ),
        CALCULATE(
            MAX('s02_inventory_stock_sales_detail_d'[computed_product_tag]),
            TREATAS(
                VALUES('s02_trade_sku_data_d'[sku_id]),
                's02_inventory_stock_sales_detail_d'[sku_id]
            ),
            TREATAS(
                VALUES('s02_trade_sku_data_d'[product_type]),
                's02_inventory_stock_sales_detail_d'[product_type]
            ),
            TREATAS(
                VALUES('s02_trade_sku_data_d'[special_series]),
                's02_inventory_stock_sales_detail_d'[special_series]
            ),
            's02_inventory_stock_sales_detail_d'[dt] = __EndPeriodDate
        )
    )
```

### 4.33 Item Stockout Special Supply（特供标识，inv 属性列）

```dax
Item Stockout Special Supply =
// ========================================
// 度量值: Item Stockout Special Supply
// 中文名: 特供标识（属性列）
// Display Folder: Item Stockout & Slow Mover Alert\Attributes
// 用途: 当前行组合的特供标识，底表 inv，单度量双表通用
// 依赖: Slicer_Time_Frame_Max_This[TimeFrame_Min] / [TimeFrame_Max]
// 口径: 属性列取快照日值（口径 §360：底表 s02_inventory_stock_sales_detail_d）
// 输出方式: 同 Product Tag（SKU 表快照日单行单值 MAX；SPU 表 distinct
//       顿号拼接）
// 行维度传递: TREATAS 三列交集 + IF 标量双分支
// ========================================

// ── End Period This 时间范围 ──
VAR __EndPeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Min])
VAR __EndPeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

// ── This 期末快照日 ──
VAR __EndPeriodDate =
    CALCULATE(
        MAX('s02_inventory_stock_sales_detail_d'[dt]),
        REMOVEFILTERS('s02_inventory_stock_sales_detail_d'),
        's02_inventory_stock_sales_detail_d'[dt] >= __EndPeriodMin,
        's02_inventory_stock_sales_detail_d'[dt] <= __EndPeriodMax
    )

// ── 表判定 ──
VAR __InSpuId = ISINSCOPE('s02_trade_sku_data_d'[spu_id])

RETURN
    IF(
        __InSpuId,
        CONCATENATEX(
            CALCULATETABLE(
                VALUES('s02_inventory_stock_sales_detail_d'[special_supply]),
                TREATAS(
                    VALUES('s02_trade_sku_data_d'[spu_id]),
                    's02_inventory_stock_sales_detail_d'[spu_id]
                ),
                TREATAS(
                    VALUES('s02_trade_sku_data_d'[product_type]),
                    's02_inventory_stock_sales_detail_d'[product_type]
                ),
                TREATAS(
                    VALUES('s02_trade_sku_data_d'[special_series]),
                    's02_inventory_stock_sales_detail_d'[special_series]
                ),
                's02_inventory_stock_sales_detail_d'[dt] = __EndPeriodDate
            ),
            's02_inventory_stock_sales_detail_d'[special_supply], "、",
            's02_inventory_stock_sales_detail_d'[special_supply], ASC
        ),
        CALCULATE(
            MAX('s02_inventory_stock_sales_detail_d'[special_supply]),
            TREATAS(
                VALUES('s02_trade_sku_data_d'[sku_id]),
                's02_inventory_stock_sales_detail_d'[sku_id]
            ),
            TREATAS(
                VALUES('s02_trade_sku_data_d'[product_type]),
                's02_inventory_stock_sales_detail_d'[product_type]
            ),
            TREATAS(
                VALUES('s02_trade_sku_data_d'[special_series]),
                's02_inventory_stock_sales_detail_d'[special_series]
            ),
            's02_inventory_stock_sales_detail_d'[dt] = __EndPeriodDate
        )
    )
```

---

## 5. 度量值清单

| # | 度量值 | 类型 | 用于视觉对象 |
| - | --- | --- | --- |
| 1 | Item Stockout SPU Rank | RANK 窗口（四键决胜，唯一名次） | SPU 表（视觉级筛选器 + 行排序） |
| 2 | Item Stockout SKU Rank | RANK 窗口（四键决胜，唯一名次） | SKU 表（视觉级筛选器 + 行排序） |
| 3 | Item Stockout SLS Amt Value / Display | currency | 两表共用 |
| 4 | Item Stockout SLS Units Value / Display | integer | 两表共用 |
| 5 | Item Stockout EOH Unit Value / Display | integer | 两表共用 |
| 6 | Item Stockout In-transit Inventory Value / Display | integer | 两表共用 |
| 7 | Item Stockout Weeks Cover Value / Display | decimal_1dp | 两表共用 |
| 8 | Item Stockout MTD SLS Unit Value / Display | integer | 两表共用 |
| 9 | Item Stockout YTD SLS Unit Value / Display | integer | 两表共用 |
| 10 | Item Stockout ST% Value / Display | percent_0dp | 两表共用 |
| 11 | Item Stockout AUR Value / Display | currency | 两表共用 |
| 12 | Item Stockout MD Value / Display | percent_0dp | 两表共用 |
| 13 | Item Stockout Alert Value / Display | 文本（缺货/滞销/其他） | 两表共用 |
| 14 | Item Stockout Available Sizes Value / Display | 文本枚举（顿号拼接） | 两表共用 |
| 15 | Item Stockout Replenishment Count Value / Display | integer | 两表共用 |
| 16 | Item Stockout US Style / AX Class / SPU Image | 一对一属性（SELECTEDVALUE） | 两表共用（值区域） |
| 17 | Item Stockout Product Tag / Special Supply | inv 属性（单值 / 拼接） | 两表共用（值区域） |

- 全部度量值存放于 `_Measures` 隐藏表；Display Folder：`Item Stockout & Slow Mover Alert\Rank`、`Item Stockout & Slow Mover Alert\Attributes`、`Item Stockout & Slow Mover Alert\Base Metrics`、`Item Stockout & Slow Mover Alert\Formatting`
- 十三个口径指标各 Value / Display 成对输出（26 个）；Rank 2 个；属性度量 5 个——合计 33 个度量值
- 除 Rank 外全部指标单度量双表通用（trade 侧零分支，inv 侧 ISINSCOPE 判定 + IF 标量双分支）

---

## 6. 视觉对象配置

### 6.1 两张表格

| 配置项 | SPU 表格 | SKU 表格 |
| --- | --- | --- |
| 视觉对象类型 | 表格 | 表格 |
| 字段井（行分组） | s02_trade_sku_data_d[spu_id]、[product_type]、[special_series] | s02_trade_sku_data_d[sku_id]、[product_type]、[special_series] |
| 视觉级筛选器 1 | Item Stockout SPU Rank 介于 1 与 100（含下界） | Item Stockout SKU Rank 介于 1 与 100（含下界） |
| 视觉级筛选器 2 | Item Stockout SLS Amt Value 不为空（双保险） | 同左 |
| 行排序 | SPU Rank 升序（列标题点击排序） | SKU Rank 升序 |

值区域建议列序（两表一致）：

| 顺序 | 列 | 度量 |
| --- | --- | --- |
| 1 | 图片 | Item Stockout SPU Image（数据类别 = 图像 URL） |
| 2 | US / Class | Item Stockout US Style、Item Stockout AX Class |
| 3 | Tag / Supply | Item Stockout Product Tag、Item Stockout Special Supply |
| 4 | SLS Amt | Item Stockout SLS Amt Display |
| 5 | SLS Units | Item Stockout SLS Units Display |
| 6 | EOH | Item Stockout EOH Unit Display |
| 7 | In-transit | Item Stockout In-transit Inventory Display |
| 8 | Weeks Cover | Item Stockout Weeks Cover Display |
| 9 | MTD / YTD | Item Stockout MTD SLS Unit Display、Item Stockout YTD SLS Unit Display |
| 10 | ST% / AUR / MD | Item Stockout ST% / AUR / MD Display |
| 11 | Alert / Sizes / Replenishment | Item Stockout Alert / Available Sizes / Replenishment Count Display |
| 12 | Rank（排序依据） | Item Stockout SPU Rank（或 SKU Rank），置于最后并收窄列宽 |

配置要点：

- **一对一属性列不进字段井**：us_style / ax_class / spu_img_url 经值区域度量输出——若加入字段井会形成六列行分组，视觉级 Rank 筛选器落地为六列跨列组合筛选，单列 / 部分列 ALL 无法清除，Rank 候选集被当前行收窄导致名次失真
- **总计行不做特判**：交由表格视觉对象默认生成（isInScope 全 FALSE 时各度量按当前上下文聚合，行为以引擎默认为准）
- Rank 度量列必须留在值区域可见（行排序绑定该列；「介于 1 与 100」筛选器亦引用该度量）

### 6.2 按钮切换

| 配置项 | 内容 |
| --- | --- |
| 切换机制 | 两个按钮（SPU / SKU）经书签控制两张表格显隐——每按钮一书签：显示对应表格 + 隐藏另一张 |
| 交互 | 两表互斥显示；指标度量共用，无需为按钮写度量分支 |

### 6.3 切片器

| 切片器 | 类型 | 作用 |
| --- | --- | --- |
| Slicer_Time_Frame | 主时间筛选器 | 驱动 Min_This / Max_This 断开维度表，经 SELECTEDVALUE 读入度量值（MTD / YTD 起点同读 Max_This 表） |
| Slicer_Platform_Selection / Slicer_Store_Name | 一对多关系切片器 | 经模型关系自动传导至 trade 侧（指标与 Top 100 候选随渠道收窄），DAX 不显式处理；inv 侧不受影响 |
| 其余商品维度切片器 | 一对多关系切片器 | 与两张事实表已建关系的自动传导（候选金额与指标同口径收窄） |
| Slicer_Currency_Selection | 断开维度 | SLS Amt / AUR 的汇率与符号来源；数量 / 占比 / 比率类不受影响 |

---

## 7. 验证方法

测试 SQL 还原要点（MySQL 8.0+，字面量直嵌，输出时按本看板参数区惯例）：

| 指标 | 测试 SQL 还原 |
| --- | --- |
| SLS Amt / SLS Units / AUR / MD | trade 侧按 (spu_id / sku_id, product_type, special_series) 三元组 GROUP BY（net_sales_amt = ROUND(product_qty × sales_price, 6) 行级还原；MD 分子分母行级乘积 SUM，NULL 行忽略 + 分母 0 拦截） |
| MTD / YTD SLS Unit | 时间条件替换为 [Fiscal_Month_First_Day / Fiscal_Year_First_Day, TimeFrame_Max] 重跑 |
| EOH / In-transit / Replenishment | inv 侧按同名三元组 GROUP BY，WHERE dt = 快照日（This 范围最后有数据日期）；不附加渠道条件 |
| ST% | 销售侧（含渠道条件）数量与库存侧（不含渠道条件）数量按三元组各自聚合后相除（分母加法 NULL 按 0） |
| Weeks Cover | 分子库存 + 在途（快照日）与分母销售数量（this period）相除 |
| Alert | 按 CASE 优先级聚合：MAX(CASE oos 非空且 tag<>'slow mover' THEN 1) 存在 → 缺货；否则 tag='slow mover' 存在 → 滞销；有行 → 其他；无行 → NULL |
| Available Sizes | GROUP_CONCAT(DISTINCT sku_size WHERE inv_qty > 0 ORDER BY sku_size) 顿号拼接 |
| Rank | DENSE_RANK() OVER (ORDER BY 金额 DESC, 主键三列 ASC)——四键决胜对齐；候选排除空白主键与当期无金额组合 |

- NULL 语义对齐 DAX：分子 NULL → 比率 NULL；MD / vs 类任一侧 NULL → NULL；Alert 无 inv 记录 → NULL（显示 "-"）
- 两段独立输出（SPU 三元组 / SKU 三元组），Top 100 以 Rank ≤ 100 筛选

---

## 8. 注意事项

1. **行主键为三元组**：(spu_id / sku_id, product_type, special_series) 为该表唯一键——同一 spu_id / sku_id 对应唯一 us_style / ax_class / spu_img_url（一对一），对应多行 product_type / special_series（一对多），同一主键在表格展开多行、各行独立参与 Top 100 排名
2. **一对一属性列必须经值区域度量输出**：us_style / ax_class / spu_img_url 若加入字段井会形成六列行分组，视觉级 Rank 筛选器落地为跨列组合筛选侵入候选集（名次失真）；SELECTEDVALUE 度量在三元组行组合下输出单值，表格效果一致
3. **Rank 决胜链为四键**：金额降序 → 主键（spu_id / sku_id）→ product_type → special_series 字母序升序——三元组主键下仅一列决胜无法消除同行并列，四键保证名次严格唯一，Top 100 恰好 100 行
4. **候选集 ALL 三列整体清除**：relation 用 ALL(trade[spu_id], trade[product_type], trade[special_series])——视觉级筛选器落地为三列组合筛选，单列 ALL 清不掉跨列组合筛选，三列全涉及才清除干净；候选排除空白主键与当期无金额行（不占名次）
5. **视觉级筛选器必须「介于 1 与 100」**：Rank 对空白主键 / 无金额行返回 BLANK，「小于或等于 100」会把 BLANK 当 0 放行；另配 SLS Amt Value 不为空双保险
6. **inv 桥接为 IF 标量双分支**：TREATAS / CALCULATETABLE 不经 IF 传递（IF 分支返回表会被降级为标量）——各分支聚合返回标量后经 IF 选择；表判定用 ISINSCOPE(trade[spu_id])，两表互斥显示，行分组必含其一
7. **Alert 优先级聚合**：SPU 表该组合任一 sku 判定缺货 → "缺货"，否则任一滞销 → "滞销"，否则"其他"；快照日无 inv 记录返回 BLANK（"其他"语义为有记录但 oos_tag 为空）；oos_tag 判空含空字符（LEN(TRIM) > 0）
8. **渠道口径不对称**：Platform / Store 切片器经关系自动传导仅作用于 trade 侧（SLS 系列指标 + Top 100 候选）；inv 表无渠道字段，库存侧指标（EOH / In-transit / Replenishment / Alert / Available Sizes / ST% 库存分母 / Weeks Cover 分子）全量口径——ST% / Weeks Cover 分子分母渠道不对称为模型物理限制，业务需知悉
9. **期末时点口径**：This 期末快照日 = end period 范围内最后一个有数据的日期（快照缺数自动回退）；快照表按日存储只取单日，对整段区间求和会重复计数库存
10. **net_sales_amt 列来源**：模型内为 Power Query 行级计算列（ROUND(product_qty × sales_price, 6)），数据库无此列——测试 SQL 验证时按行级乘积还原
11. **MD 空值拦截**：分子分母行级乘积对任一字段 NULL 的行不计入（直接算术相乘会把 BLANK 当 0，无折扣价行 MD 虚高 100%）；分母为 0 或任一侧 BLANK 时整体返回 BLANK（1 - BLANK = 1 失真，必须显式拦截）
12. **ST% 数量口径 / Weeks Cover 分子分母方向**：均为口径文档已确认修正项（§28 金额→数量、§25 原始公式写反以业务定义为准），不可回退
13. **MTD / YTD 起点**：读 Slicer_Time_Frame_Max_This 表 Fiscal_Month_First_Day / Fiscal_Year_First_Day 字段，终点 TimeFrame_Max（口径 §26 / §27 指定）
14. **RANK / ORDERBY 版本要求**：Power BI Desktop 2022 年 9 月及以后版本
15. **总计行为**：总计行不做特判，交由表格视觉对象默认生成
16. **口径与语法**：口径文档中定义的所有指标必须遵守其数据类型与数据格式，与解决方案存在争议时一切以口径文档为准；DAX 文本常量使用双引号，单引号仅用于表名，列名使用方括号
