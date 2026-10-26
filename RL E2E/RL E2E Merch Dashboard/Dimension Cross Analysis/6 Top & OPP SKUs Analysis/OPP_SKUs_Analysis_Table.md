# OPP_SKUs_Analysis_Table 解决方案（OPP 部分）

> **版本**: v1.0
> **模块**: RL E2E Merch Dashboard - Dimension Cross Analysis Tab - Top & OPP SKUs Analysis（OPP 部分）
> **关联口径**: 口径文档/口径Markdown格式/Dimension Cross Analysis.md - 子模块九模块说明（OPP 定义 + 参与判断的计算：launch_time / ST%（金额））+ §40 Weeks Cover / §41 SLS Units / §42 EOH；§40~§42 与属性列口径同 Top 部分复用
> **数据底表（库存为主）**: s02_inventory_stock_sales_detail_d（排序依据 stock_inv_qty / 资格判定 launch_time / brand / ax_class / msrp_inv_amt / stock_inv_qty / in_trans_inv_qty 同表直聚合）
> **数据底表（销售/属性类）**: s02_trade_sku_data_d（ST% / Weeks Cover 分母的销售侧 + 属性列取值）
> **关联维度**: Slicer_Time_Frame_Min_This / Max_This（时间，断开维度）；Slicer_Framework（framework 一对多关系，前置筛选 'Foundation' 自动传导双表）；Slicer_Platform_Selection / Slicer_Store_Name（一对多关系自动传导，DAX 不显式处理）；Slicer_Currency_Selection（币种，断开维度）
> **筛选影响范围**: dt（断开维度，DAX 显式筛选）+ framework 前置筛选 + Platform / Store Name（模型关系自动传导）+ 其余与两张事实表已建关系的商品维度切片器

---

## 1. 需求理解

### 1.1 模块定位与视觉对象结构

Top & OPP SKUs Analysis 板块含 TOP 与 OPP 两部分，经页面按钮 + 书签切换显隐（不在度量值范围）。本方案覆盖 **OPP 部分**：单张平铺表格，前置筛选 framework = 'Foundation'，行 = category + sku_id 组合，先按四项资格条件过滤出「机会 SKU」（低售罄、高库存、慢周转的新上架商品），再在**资格 SKU 集合内**按 EOH（在库库存数量，快照日时点）降序取每个 category 的 Top3：

| 配置项           | 内容                                                                                                   |
| ---------------- | ------------------------------------------------------------------------------------------------------ |
| 视觉对象类型     | 表格（平铺，无层级小计，总计行交由视觉对象默认生成）                                                   |
| 字段井（行分组） | s02_trade_sku_data_d[category]、s02_trade_sku_data_d[sku_id]（与 Top 表格同构）                        |
| 值区域（属性列） | Product Photo / Product Type / Price / Predictive Buy（复用 Top SKUs 度量，见 §4.4）                   |
| 值区域（指标列） | EOH / SLS Units / Weeks Cover Display（复用 Top SKUs 度量）+ Sort Key（行排序依据）                    |
| 视觉级筛选器     | framework = 'Foundation'（前置）+ **OPP SKUs Qualify = 1（资格筛选）** + SKU Rank 介于 1 与 3 + 空白键排除 |
| 行排序           | OPP SKUs Sort Key 升序（category 块按 EOH 降序 + 组内 sku 按 EOH 降序，金额编码负号翻转）              |

- **以库存表为主**：排序依据指标（EOH = sum(stock_inv_qty)）与资格判定的库存侧（launch_time / brand / ax_class / msrp_inv_amt / stock / in_trans）全部取自 s02_inventory_stock_sales_detail_d——该表字段齐备（已核对数据字典），库存侧判定**同表直聚合，无需桥接**；仅销售侧两个标量（净销售金额 / 净销售数量）经 TREATAS 桥接 trade 表
- **行维度沿用 trade 字段**：与 Top 表格同构（行分组双列 trade[category] + trade[sku_id]），展示指标与属性列度量直接复用 Top SKUs 系列（行分组筛选自动传导 trade 侧聚合）；库存指标经 TREATAS 桥接（同 Top 模式）
- **资格筛选先行**：OPP SKUs Qualify = 1 视觉级筛选器先过滤行集（每行一次常数聚合，无候选迭代），SKU Rank 仅对资格行求值

### 1.2 OPP 资格判定规则（四条件）

在外部切片器（framework / 渠道等）+ 时间筛选下，当前行 SKU 须**同时满足**以下四项（判定值与均值的比较方向为口径核心，任一不成立即无资格）：

| #   | 条件                | SKU 判定值                                                                                                        | 比较对象（均值）                                                                                          | 数据源                          |
| --- | ------------------- | ----------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------- | ------------------------------- |
| 1   | 上架超 2 周         | launch_time（String 转日期）：上架日期至 end period 最后一天的天数                                                | > 14 天（严格大于）                                                                                       | inv[launch_time]（快照日行）    |
| 2   | 售罄率低于均值      | ST% = net_sales_amt / (net_sales_amt + msrp_inv_amt)（销售侧 this period 区间，库存侧快照日，金额口径）          | 全 SKU 均值 = sum(net_sales_amt) / (sum(net_sales_amt) + sum(msrp_inv_amt))，sum 范围 = 外部筛选下全部 SKU | trade + inv                     |
| 3   | 周转周数高于均值    | Weeks Cover = (stock_inv_qty + in_trans_inv_qty) / product_qty（库存侧快照日，销售侧 this period 区间）           | 全 SKU 均值 = sum(stock + in_trans) / sum(product_qty)（分子分母各自全量汇总后相除）                      | inv + trade                     |
| 4   | 库存高于同组均值    | EOH = sum(stock_inv_qty)（快照日）                                                                                | 同 Label & CLASS（brand + ax_class）分组均值 = 分组 EOH 合计 / 分组 SKU 个数                              | inv（brand / ax_class 同表）    |

口径细节：

- **条件 1**：launch_time 值形如 "2022-09-02 00:00:00.000"（String），取前 10 位转日期（DATEVALUE(LEFT(...,10))）；上架日期 BLANK 或无法解析 → 资格不成立；`__EndPeriodDate - __LaunchDate > 14`（严格大于 14 天）
- **条件 2 / 3 的均值**：比值均值（先各自全量 sum 再相除），非 SKU 值的算术平均；trade 侧与 inv 侧的全量 sum 各自独立（两侧 SKU 域不必对齐——比值公式原始口径）
- **条件 3 边界**：product_qty 为 0 或 BLANK（当期无净销售数量）→ Weeks Cover 为 BLANK → 严格大于比较不成立 → 资格不通过（纯库存无销售 SKU 天然被排除，见注意事项 5）
- **条件 4 的分组与 SKU 个数**：分组键 = inv[brand]（Label）+ inv[ax_class]（CLASS）；分组 EOH 合计与 SKU 个数均为**快照日 inv 侧口径**（分组内有库存记录的 distinct sku 数）；SKU 的分组归属按其 inv 快照日行的 brand / ax_class 取值
- ST%（金额口径）仅参与判定、不在前端展示（口径文档 §633 说明）；Weeks Cover / SLS Units / EOH 展示口径同 Top（§40~§42 复用）

### 1.3 Top3 与排序机制

- **Top3 行筛选**：在**资格 SKU 集合内**按 category 分组、组内 EOH 降序取前三——视觉级「OPP SKUs SKU Rank 介于 1 与 3」度量筛选器（含下界），Rank 候选集限定资格通过的 SKU（与 Top 的全量组内排名不同，资格过滤内嵌于排名候选集）
- **SKU Rank**：RANKX 迭代器（候选集 = 当前 category 内资格 SKU 物化表），EOH 降序、DENSE 并列共享名次（含并列放行，同 Top v2.1 语义）
- **Sort Key（金额编码，学 Top v2.1）**：排序不需要排名——库存数量本身就是顺序：`-(category EOH 合计 × 1,000,000 + SKU EOH)`，负号翻转使表格升序排列 = EOH 降序效果；category 块按快照日库存量降序（库存最大的 category 在最前）、块内 sku 按 EOH 降序；权重前提：单 SKU EOH < 1,000,000（库存件数，超限改 1e9）
- **BLANK 防护**：Qualify 对无资格行返回 0（筛选器「为 1」排除）；Rank 对无资格行返回 BLANK（「介于 1 与 3」的下界排除）

### 1.4 时间口径

| 口径                     | 时间范围                                                                                                                                  | 适用指标                                                        |
| ------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------- |
| This Period（区间类）    | dt ∈ [Slicer_Time_Frame_Min_This[TimeFrame_Min], Slicer_Time_Frame_Max_This[TimeFrame_Max]]                                              | ST% 销售侧、Weeks Cover 分母、SLS Units 展示、属性"最新日期"判定 |
| End Period（期末时点类） | end period 范围 [Slicer_Time_Frame_Max_This[TimeFrame_Min], Slicer_Time_Frame_Max_This[TimeFrame_Max]] 内**最后一个有数据的快照日** | EOH（排序与判定）、launch 判定基准日、ST% 库存侧、WC 分子       |

说明：

- 两张 s02 表日期字段均为 dt；期末时点为「范围内最后一个有数据的快照日」（快照缺数自动回退），只取单日
- 全局均值（条件 2 / 3）与分组均值（条件 4）的时间口径与 SKU 判定值同口径（销售侧 this period、库存侧快照日）
- 属性字段"最新日期"以 This Period 区间内该组合实际最大 dt 为准（复用 Top 度量，同 §1.3 规则）

### 1.5 币种与渠道口径

- OPP 判定（ST% / WC / EOH / launch）均为数量与原始金额的比值或数量，不涉及币种换算；展示列复用 Top SKUs 度量（Price / 币种规则同 Top §1.5）
- framework = 'Foundation' 经一对多关系自动传导双表（framework 字段两表齐备），DAX 不显式处理
- inv 表无 platform / shop_name 字段：库存侧（EOH / WC 分子 / ST% 库存侧 / 全部均值）不受渠道筛选影响；trade 侧受——判定分子分母渠道口径不对称为模型物理限制（同 Top §1.7，业务需知悉）

---

## 2. 现状分析

- inv 表 `s02_inventory_stock_sales_detail_d`（dt + sku_id 唯一键，日快照）**字段齐备**（已逐一核对数据字典）：brand（Label）、ax_class、category、framework、launch_time（Nullable(String)，值形如 "2022-09-02 00:00:00.000"）、msrp_inv_amt（吊牌库存金额）、stock_inv_qty（在库库存）、in_trans_inv_qty（在途库存）——OPP 判定与排序的库存侧全部同表直聚合，无桥接
- trade 表 `s02_trade_sku_data_d`：net_sales_amt（PQ 行级列 ROUND(product_qty × sales_price, 6)）、product_qty、category / sku_id 与属性字段齐备；ST% 销售侧与 WC 分母需经 TREATAS 桥接
- 两张事实表无模型关系：trade 行筛选向 inv 传递经 TREATAS 单列桥接（同 Top §3.4）；inv 行值（brand / ax_class / launch）向 trade 侧判定传递经 TREATAS(ROW) 单值桥接
- 资格判定所需的 brand / ax_class 取自 **inv 表**（快照日行值）——trade 表虽有同名字段，但条件 4 的分组均值域在 inv 侧（EOH 同源），分组归属与均值口径保持同表一致

---

## 3. 方案设计

### 3.1 度量值分层

```
Qualify（资格筛选，1 个度量）
←  当前行四个判定值的常数次聚合（trade 侧 2 个直聚合 +
      inv 侧 5 个 TREATAS 桥接聚合 + 分组均值 2 个聚合）
←  全局均值 / 分组均值：REMOVEFILTERS(category, sku_id 两列)
      清除行筛选与视觉级组合筛选（防均值被收窄为当前行自身）
←  视觉级筛选器「Qualify = 1」：先过滤行集，无候选迭代
↓
Rank（资格集合内组内排名，1 个度量，RANKX 迭代器）
←  候选表物化：inv 侧 SUMMARIZE 一次分组查询（库存为主：
      @EOH / @InvAmt / @WcInv / @Launch + brand / ax_class 分组列）
      + trade 侧 2 列 TREATAS(ROW) 桥接 + 分组均值表
      MAXX 纯内存匹配（分组均值表一次物化，几十行级）
←  FILTER 四条件 → 资格候选集（Top3 在资格集合内取）
←  RANKX(资格表, [@EOH], 当前行 EOH, DESC, DENSE)
↓
Sort Key（行排序，1 个度量，金额编码）
←  -(category EOH 合计 × 1,000,000 + SKU EOH)，负号翻转
←  库存数量本身即顺序，无需排名（学 Top v2.1）
↓
展示指标（复用 Top SKUs 系列 9 个度量，见 §4.4）
```

### 3.2 行筛选机制

每个表格视觉对象配置五条视觉级筛选器：

| 筛选器                          | 类型       | 条件          | 作用                                                                                                    |
| ------------------------------- | ---------- | ------------- | ------------------------------------------------------------------------------------------------------- |
| Slicer_Framework[framework]     | 列筛选器   | = Foundation  | 前置筛选（用户配置）——经一对多关系自动传导双表                                                          |
| OPP SKUs Qualify                | 度量筛选器 | **为 1**       | **资格筛选主力**——四条件全通过的行为 1，其余为 0 / BLANK（「为 1」精确匹配，勿用「≤ 1」放行 BLANK）   |
| OPP SKUs SKU Rank               | 度量筛选器 | 介于 1 与 3   | 资格集合内每 category 组内 EOH 前三；含下界排除 BLANK 行                                                |
| s02_trade_sku_data_d[category]  | 列筛选器   | 不为空        | 排除空白 category 组                                                                                    |
| s02_trade_sku_data_d[sku_id]    | 列筛选器   | 不为空        | 排除空白主键行（Rank / Qualify 对空白键返回 0 / BLANK 已被前两条排除，此条双保险）                      |

机制说明：

- **Qualify 先行**：资格筛选为每行一次常数聚合（无候选迭代），行集先收窄到资格行；Rank 仅对资格行求值（外层 IF 引用 Qualify，非资格行返回 BLANK）
- **Top3 必须在资格集合内取**：口径为「通过条件 1~4 的 SKU 中按 EOH 取 Top3」——Rank 候选集内嵌资格过滤（先 FILTER 资格再排名），非「全量排名后再过滤」
- **「为 1」勿改「≤ 1」**：Qualify 对空白 category / sku_id 行返回 0（非 BLANK），但防御性仍用精确匹配（BLANK 在数值比较中当 0，0 ≤ 1 成立会放行意外行）

### 3.3 资格判定口径细化

**全局均值（条件 2 / 3）**：

- trade 侧全量：`CALCULATE(SUM(...), REMOVEFILTERS(trade[category], trade[sku_id]), dt 区间)`——**必须两列整体清除**：视觉级 Qualify / Rank 筛选器落地为 (category, sku_id) 跨列组合筛选，不清除会把均值收窄为当前行自身（判定恒不成立）；framework / 渠道等外部筛选保留
- inv 侧全量：`CALCULATE(SUM(...), inv[dt] = 快照日)`——组合筛选落在 trade 列上，不影响 inv 聚合；外部切片器（framework 等已建关系）自动传导
- 均值 = 比值均值（两侧各自全量 sum 后相除），两侧 SKU 域独立（原始口径）

**分组均值（条件 4）**：

- 分组键 = inv[brand] + inv[ax_class]；分组 EOH 合计 = `CALCULATE(SUM(inv[stock_inv_qty]), inv[dt] = 快照日, TREATAS(ROW(brand, ax_class), inv[brand], inv[ax_class]))`
- 分组 SKU 个数 = 快照日该分组内有库存记录的 distinct sku 数（`DISTINCTCOUNT(inv[sku_id])` 同上下文）
- SKU 的分组归属 = 该 sku 快照日行的 brand / ax_class（TREATAS(VALUES(trade[sku_id]), inv[sku_id]) 桥接取值）

**候选表物化（Rank 度量内，每行组一次）**：

| 物化表         | 结构                                                                                                          | 成本                     |
| -------------- | ------------------------------------------------------------------------------------------------------------- | ------------------------ |
| __CandSkus     | 当前 category 内当期有 trade 记录的 sku（VALUES + 等值条件 + dt，学 Top v2.1）                                | 一次值域查询             |
| __InvAgg       | SUMMARIZE(inv, sku_id, brand, ax_class, @EOH, @InvAmt, @WcInv, @Launch)——快照日 + TREATAS 候选集，**一次分组查询** | 一条 SE 查询（库存为主） |
| __GrpAvg       | SUMMARIZE(inv, brand, ax_class, @GrpEOH, @GrpCnt)——快照日全量，一次分组查询（几十行级）                        | 一条 SE 查询             |
| __CandTable    | __InvAgg + ADDCOLUMNS：@StAmt / @Qty（TREATAS(ROW) 桥接 trade）+ @GrpAvgEOH（MAXX 匹配 __GrpAvg，纯内存查找）  | 每候选 2 次桥接聚合      |
| __Qualified    | FILTER(__CandTable, 四条件)——资格候选集                                                                       | 纯内存过滤               |

- 判定在 FILTER 内以除法比较直接书写（DIVIDE 边界清晰：分母 0 / BLANK → BLANK → 比较不成立）；Qualify 度量与 Rank 候选判定**逻辑同构**（两处代码需同步维护，见注意事项 10）

### 3.4 度量值命名与组织

- 命名规则：模块前缀 `OPP SKUs` + 用途（Qualify / SKU Rank / Sort Key）；展示指标复用 Top SKUs 系列度量（命名不变，列头在视觉对象中可重命名）
- Display Folder：`Top & OPP SKUs Analysis\OPP\Qualify`、`Top & OPP SKUs Analysis\OPP\Rank`（与 Top 部分度量隔离）
- 度量值统一存放于 `_Measures` 隐藏表

---

## 4. 度量值实现

### 4.1 OPP SKUs Qualify（资格判定，视觉级筛选器）

```dax
OPP SKUs Qualify =
// ========================================
// 度量值: OPP SKUs Qualify
// 中文名: OPP 资格判定（四条件）
// Display Folder: Top & OPP SKUs Analysis\OPP\Qualify
// 用途: 当前行 SKU 是否为 OPP 机会商品——上架超 2 周 && ST% 低于全量均值
//       && Weeks Cover 高于全量均值 && EOH 高于同 Label & CLASS 分组均值，
//       四条件全通过返回 1，否则返回 0；用于视觉级筛选器「为 1」
// 依赖: Slicer_Time_Frame_Min_This[TimeFrame_Min] / Slicer_Time_Frame_Max_This[TimeFrame_Max]
//       Slicer_Time_Frame_Max_This[TimeFrame_Min] / [TimeFrame_Max]（快照日）
// 条件 1 上架超 2 周: inv[launch_time]（String，值形如 2022-09-02 00:00:00.000）
//       取前 10 位 DATEVALUE 转日期，快照日 - 上架日 > 14 天（严格大于）；
//       launch_time BLANK / 无法解析 → 资格不成立（IFERROR 容错）
// 条件 2 ST% < 全量均值: SKU = net_sales_amt / (net_sales_amt + msrp_inv_amt)
//       （销售侧 this period 区间、库存侧快照日，金额口径）；
//       均值 = sum(net_sales_amt) / (sum(net_sales_amt) + sum(msrp_inv_amt))
//       （trade / inv 两侧各自全量 sum 后相除，SKU 域独立——原始口径）
// 条件 3 WC > 全量均值: SKU = (stock_inv_qty + in_trans_inv_qty) / product_qty
//       （库存侧快照日、销售侧 this period 区间）；
//       均值 = sum(stock + in_trans) / sum(product_qty)（同口径全量比值）；
//       分母 0 / BLANK → SKU 值 BLANK → 比较不成立（纯库存无销售 SKU 天然排除）
// 条件 4 EOH > 同组均值: 分组键 = inv[brand]（Label）+ inv[ax_class]（CLASS），
//       分组均值 = 分组快照日 EOH 合计 / 分组内 distinct sku 数（inv 侧口径）；
//       SKU 分组归属 = 其 inv 快照日行的 brand / ax_class
// 全局均值净化（关键）: 视觉级度量筛选器（Qualify = 1 / Rank 介于 1 与 3）落地为
//       (category, sku_id) 跨列组合筛选——trade 侧全量必须 REMOVEFILTERS(两列)
//       整体清除（否则均值被收窄为当前行自身，判定恒不成立）；inv 侧聚合不受
//       trade 列组合筛选影响（两表无关系），外部筛选（framework / 渠道等）保留
// 渠道: trade 侧受 Platform / Store 筛选、inv 侧不受——判定分子分母渠道口径
//       不对称为模型物理限制（业务需知悉）
// 性能: 每行常数次聚合（trade 2 + inv 桥接 5 + 分组均值 2），无候选迭代
// ========================================

// ── This Period 时间区间（销售侧）──
VAR __PeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Min_This[TimeFrame_Min])
VAR __PeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

// ── End Period 时间范围与快照日（库存侧期末时点）──
VAR __EndPeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Min])
VAR __EndPeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])
VAR __EndPeriodDate =
    CALCULATE(
        MAX('s02_inventory_stock_sales_detail_d'[dt]),
        REMOVEFILTERS('s02_inventory_stock_sales_detail_d'),
        's02_inventory_stock_sales_detail_d'[dt] >= __EndPeriodMin,
        's02_inventory_stock_sales_detail_d'[dt] <= __EndPeriodMax
    )

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
VAR __Qty =
    CALCULATE(
        SUM('s02_trade_sku_data_d'[product_qty]),
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
        's02_inventory_stock_sales_detail_d'[dt] = __EndPeriodDate
    )
VAR __InvAmt =
    CALCULATE(
        SUM('s02_inventory_stock_sales_detail_d'[msrp_inv_amt]),
        __SkuFilter,
        's02_inventory_stock_sales_detail_d'[dt] = __EndPeriodDate
    )
VAR __WcInv =
    CALCULATE(
        SUM('s02_inventory_stock_sales_detail_d'[stock_inv_qty])
            + SUM('s02_inventory_stock_sales_detail_d'[in_trans_inv_qty]),
        __SkuFilter,
        's02_inventory_stock_sales_detail_d'[dt] = __EndPeriodDate
    )
VAR __Launch =
    CALCULATE(
        MAX('s02_inventory_stock_sales_detail_d'[launch_time]),
        __SkuFilter,
        's02_inventory_stock_sales_detail_d'[dt] = __EndPeriodDate
    )

// ── 条件 1：上架日期（String 前 10 位转日期；BLANK / 解析失败容错）──
VAR __LaunchDate = IFERROR(DATEVALUE(LEFT(__Launch, 10)), BLANK())

// ── 全量均值：trade 侧全量（REMOVEFILTERS 两列清除行筛选与视觉级组合筛选）──
VAR __T_St =
    CALCULATE(
        SUM('s02_trade_sku_data_d'[net_sales_amt]),
        REMOVEFILTERS('s02_trade_sku_data_d'[category], 's02_trade_sku_data_d'[sku_id]),
        's02_trade_sku_data_d'[dt] >= __PeriodMin,
        's02_trade_sku_data_d'[dt] <= __PeriodMax
    )
VAR __T_Qty =
    CALCULATE(
        SUM('s02_trade_sku_data_d'[product_qty]),
        REMOVEFILTERS('s02_trade_sku_data_d'[category], 's02_trade_sku_data_d'[sku_id]),
        's02_trade_sku_data_d'[dt] >= __PeriodMin,
        's02_trade_sku_data_d'[dt] <= __PeriodMax
    )

// ── 全量均值：inv 侧全量（快照日单日；trade 列组合筛选不影响 inv 聚合）──
VAR __T_Inv =
    CALCULATE(
        SUM('s02_inventory_stock_sales_detail_d'[msrp_inv_amt]),
        's02_inventory_stock_sales_detail_d'[dt] = __EndPeriodDate
    )
VAR __T_WcInv =
    CALCULATE(
        SUM('s02_inventory_stock_sales_detail_d'[stock_inv_qty])
            + SUM('s02_inventory_stock_sales_detail_d'[in_trans_inv_qty]),
        's02_inventory_stock_sales_detail_d'[dt] = __EndPeriodDate
    )

// ── 全量比值均值（先各自全量 sum 再相除，非 SKU 值算术平均）──
VAR __AvgSt = DIVIDE(__T_St, __T_St + __T_Inv)
VAR __AvgWc = DIVIDE(__T_WcInv, __T_Qty)

// ── 条件 4 分组均值：SKU 分组归属（inv 快照日行的 brand / ax_class）──
VAR __MyBrand =
    CALCULATE(
        MAX('s02_inventory_stock_sales_detail_d'[brand]),
        __SkuFilter,
        's02_inventory_stock_sales_detail_d'[dt] = __EndPeriodDate
    )
VAR __MyAx =
    CALCULATE(
        MAX('s02_inventory_stock_sales_detail_d'[ax_class]),
        __SkuFilter,
        's02_inventory_stock_sales_detail_d'[dt] = __EndPeriodDate
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
        's02_inventory_stock_sales_detail_d'[dt] = __EndPeriodDate,
        __GrpFilter
    )
VAR __GrpCnt =
    CALCULATE(
        DISTINCTCOUNT('s02_inventory_stock_sales_detail_d'[sku_id]),
        's02_inventory_stock_sales_detail_d'[dt] = __EndPeriodDate,
        __GrpFilter
    )
VAR __GrpAvgEOH = DIVIDE(__GrpEOH, __GrpCnt)

// ── 四条件判定（除法比较：分母 0 / BLANK → BLANK → 比较不成立）──
VAR __PassLaunch =
    NOT ISBLANK(__LaunchDate)
        && (__EndPeriodDate - __LaunchDate) > 14
VAR __PassSt = DIVIDE(__StAmt, __StAmt + __InvAmt) < __AvgSt
VAR __PassWc = DIVIDE(__WcInv, __Qty) > __AvgWc
VAR __PassEoh =
    NOT ISBLANK(__EOH) && NOT ISBLANK(__GrpAvgEOH)
        && __EOH > __GrpAvgEOH

RETURN
    IF(
        NOT ISBLANK(__CurrentCategory) && LEN(TRIM(__CurrentCategory)) > 0
            && NOT ISBLANK(__CurrentSkuId) && LEN(TRIM(__CurrentSkuId)) > 0
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
//       Slicer_Time_Frame_Max_This[TimeFrame_Min] / [TimeFrame_Max]（快照日）
//       [OPP SKUs Qualify]
// 排名依据: EOH = 快照日 sum(inv.stock_inv_qty)（库存表为主，学 Top v2.1
//       RANKX 迭代器模式——value 参数迭代外预计算）
// 排名语义: EOH 降序；EOH 相同的 sku 并列同名次（DENSE），「介于 1 与 3」
//       放行名次 ≤ 3 的所有行（含并列）；候选集已限定资格 SKU，
//       无资格 sku 不占名次
// 候选表物化（每行组一次）:
//       __CandSkus = 当前 category 内当期有 trade 记录的 sku
//       （VALUES + category 等值 + dt，学 Top v2.1——等值条件覆盖组合筛选
//       的 category 部分，REMOVEFILTERS(sku) 清除 sku 部分）
//       __InvAgg = SUMMARIZE(inv, sku_id, brand, ax_class, @EOH, @InvAmt,
//       @WcInv, @Launch)——快照日 + TREATAS 候选集，一次分组查询
//       （库存为主，inv 侧全部判定列同表直聚合）
//       __GrpAvg = SUMMARIZE(inv, brand, ax_class, @GrpEOH, @GrpCnt)——
//       快照日全量，一次分组查询（几十行级）
//       __CandTable = __InvAgg + ADDCOLUMNS：@StAmt / @Qty（TREATAS(ROW)
//       桥接 trade，每候选 2 次）+ @GrpAvgEOH（VAR 捕获行值 + MAXX 匹配
//       __GrpAvg，纯内存查找）
//       __Qualified = FILTER(__CandTable, 四条件)——与 Qualify 度量
//       判定逻辑同构（两处需同步维护）
// 全局均值净化: trade 侧全量 REMOVEFILTERS(两列) 清除行筛选与视觉级组合
//       筛选（同 Qualify，防均值被收窄为当前行自身）
// 空白/无资格拦截: 当前行 Qualify ≠ 1 或 EOH 空时返回 BLANK
//       （「介于 1 与 3」将 BLANK 视为 0 排除在区间外）
// 性能: 每行组 = 2 条 SE 分组查询（__InvAgg / __GrpAvg）+ 每候选 2 次
//       trade 桥接聚合（学 Top v2.1 成本结构 × 2）+ 纯内存过滤匹配；
//       视觉级 Qualify = 1 筛选器先行收窄行集，Rank 仅对资格行求值
// ========================================

// ── This Period 时间区间（销售侧）──
VAR __PeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Min_This[TimeFrame_Min])
VAR __PeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

// ── End Period 时间范围与快照日 ──
VAR __EndPeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Min])
VAR __EndPeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])
VAR __EndPeriodDate =
    CALCULATE(
        MAX('s02_inventory_stock_sales_detail_d'[dt]),
        REMOVEFILTERS('s02_inventory_stock_sales_detail_d'),
        's02_inventory_stock_sales_detail_d'[dt] >= __EndPeriodMin,
        's02_inventory_stock_sales_detail_d'[dt] <= __EndPeriodMax
    )

// ── 当前行分组值 ──
VAR __CurrentCategory = SELECTEDVALUE('s02_trade_sku_data_d'[category])
VAR __CurrentSkuId = SELECTEDVALUE('s02_trade_sku_data_d'[sku_id])

// ── 当前行 EOH（RANKX value 参数，迭代外预计算）──
VAR __CurrentEOH =
    CALCULATE(
        SUM('s02_inventory_stock_sales_detail_d'[stock_inv_qty]),
        TREATAS(
            VALUES('s02_trade_sku_data_d'[sku_id]),
            's02_inventory_stock_sales_detail_d'[sku_id]
        ),
        's02_inventory_stock_sales_detail_d'[dt] = __EndPeriodDate
    )

// ── 全量比值均值（迭代外标量，口径与净化同 Qualify）──
VAR __T_St =
    CALCULATE(
        SUM('s02_trade_sku_data_d'[net_sales_amt]),
        REMOVEFILTERS('s02_trade_sku_data_d'[category], 's02_trade_sku_data_d'[sku_id]),
        's02_trade_sku_data_d'[dt] >= __PeriodMin,
        's02_trade_sku_data_d'[dt] <= __PeriodMax
    )
VAR __T_Qty =
    CALCULATE(
        SUM('s02_trade_sku_data_d'[product_qty]),
        REMOVEFILTERS('s02_trade_sku_data_d'[category], 's02_trade_sku_data_d'[sku_id]),
        's02_trade_sku_data_d'[dt] >= __PeriodMin,
        's02_trade_sku_data_d'[dt] <= __PeriodMax
    )
VAR __T_Inv =
    CALCULATE(
        SUM('s02_inventory_stock_sales_detail_d'[msrp_inv_amt]),
        's02_inventory_stock_sales_detail_d'[dt] = __EndPeriodDate
    )
VAR __T_WcInv =
    CALCULATE(
        SUM('s02_inventory_stock_sales_detail_d'[stock_inv_qty])
            + SUM('s02_inventory_stock_sales_detail_d'[in_trans_inv_qty]),
        's02_inventory_stock_sales_detail_d'[dt] = __EndPeriodDate
    )
VAR __AvgSt = DIVIDE(__T_St, __T_St + __T_Inv)
VAR __AvgWc = DIVIDE(__T_WcInv, __T_Qty)

// ── 候选 sku 集：当前 category 内当期有 trade 记录的 sku（学 Top v2.1）──
// REMOVEFILTERS(sku) 清除行级 sku 筛选，category 等值条件覆盖组合筛选的
// category 部分，dt 条件限定当期；外部筛选（framework / 渠道等）自然保留
VAR __CandSkus =
    CALCULATETABLE(
        VALUES('s02_trade_sku_data_d'[sku_id]),
        REMOVEFILTERS('s02_trade_sku_data_d'[sku_id]),
        's02_trade_sku_data_d'[category] = __CurrentCategory,
        's02_trade_sku_data_d'[dt] >= __PeriodMin,
        's02_trade_sku_data_d'[dt] <= __PeriodMax
    )

// ── inv 侧候选聚合：一次分组查询物化全部库存侧判定列（库存表为主）──
// 快照日 + TREATAS 候选集限定；无 inv 记录的候选 sku 天然不在表内
// （EOH 判定本要求有库存，符合口径）
VAR __InvAgg =
    CALCULATETABLE(
        SUMMARIZE(
            's02_inventory_stock_sales_detail_d',
            's02_inventory_stock_sales_detail_d'[sku_id],
            's02_inventory_stock_sales_detail_d'[brand],
            's02_inventory_stock_sales_detail_d'[ax_class],
            "@EOH", SUM('s02_inventory_stock_sales_detail_d'[stock_inv_qty]),
            "@InvAmt", SUM('s02_inventory_stock_sales_detail_d'[msrp_inv_amt]),
            "@WcInv",
                SUM('s02_inventory_stock_sales_detail_d'[stock_inv_qty])
                    + SUM('s02_inventory_stock_sales_detail_d'[in_trans_inv_qty]),
            "@Launch", MAX('s02_inventory_stock_sales_detail_d'[launch_time])
        ),
        's02_inventory_stock_sales_detail_d'[dt] = __EndPeriodDate,
        TREATAS(__CandSkus, 's02_inventory_stock_sales_detail_d'[sku_id])
    )

// ── 分组均值表：快照日全量一次物化（brand + ax_class 粒度，几十行级）──
VAR __GrpAvg =
    CALCULATETABLE(
        SUMMARIZE(
            's02_inventory_stock_sales_detail_d',
            's02_inventory_stock_sales_detail_d'[brand],
            's02_inventory_stock_sales_detail_d'[ax_class],
            "@GrpEOH", SUM('s02_inventory_stock_sales_detail_d'[stock_inv_qty]),
            "@GrpCnt", DISTINCTCOUNT('s02_inventory_stock_sales_detail_d'[sku_id])
        ),
        's02_inventory_stock_sales_detail_d'[dt] = __EndPeriodDate
    )

// ── 候选判定表：补 trade 侧两列（TREATAS(ROW) 桥接）+ 分组均值（内存匹配）──
// VAR 捕获 __InvAgg 行上下文列值 → ROW 重建单值筛选桥接 trade；
// 分组均值经 MAXX 匹配 __GrpAvg（VAR 捕获候选行 brand / ax_class，
// FILTER 迭代行的同名列取 __GrpAvg 行值，标量比较无歧义）
VAR __CandTable =
    ADDCOLUMNS(
        __InvAgg,
        "@StAmt",
            VAR __S = 's02_inventory_stock_sales_detail_d'[sku_id]
            RETURN
                CALCULATE(
                    SUM('s02_trade_sku_data_d'[net_sales_amt]),
                    TREATAS(ROW("@S", __S), 's02_trade_sku_data_d'[sku_id]),
                    's02_trade_sku_data_d'[dt] >= __PeriodMin,
                    's02_trade_sku_data_d'[dt] <= __PeriodMax
                ),
        "@Qty",
            VAR __S = 's02_inventory_stock_sales_detail_d'[sku_id]
            RETURN
                CALCULATE(
                    SUM('s02_trade_sku_data_d'[product_qty]),
                    TREATAS(ROW("@S", __S), 's02_trade_sku_data_d'[sku_id]),
                    's02_trade_sku_data_d'[dt] >= __PeriodMin,
                    's02_trade_sku_data_d'[dt] <= __PeriodMax
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

// ── 资格候选集：四条件过滤（判定逻辑与 Qualify 度量同构）──
VAR __Qualified =
    FILTER(
        __CandTable,
        VAR __LaunchDate = IFERROR(DATEVALUE(LEFT([@Launch], 10)), BLANK())
        RETURN
            NOT ISBLANK(__LaunchDate)
                && (__EndPeriodDate - __LaunchDate) > 14
                && DIVIDE([@StAmt], [@StAmt] + [@InvAmt]) < __AvgSt
                && DIVIDE([@WcInv], [@Qty]) > __AvgWc
                && [@EOH] > [@GrpAvgEOH]
    )

// ── 排名：资格集合内 RANKX（EOH 降序 + DENSE 并列）──
// 当前行 Qualify = 1 保证其 sku 必在 __Qualified 中（同判定同候选域）；
// value 参数用预计算的 __CurrentEOH（避免迭代内重复聚合）
RETURN
    IF(
        [OPP SKUs Qualify] = 1 && NOT ISBLANK(__CurrentEOH),
        RANKX(
            __Qualified,
            [@EOH],
            __CurrentEOH,
            DESC,
            DENSE
        )
    )
```

### 4.3 OPP SKUs Sort Key（表格行排序键，库存量编码）

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
// 性能: 无需 RANKX / RANK，仅 2 次 CALCULATE SUM（SE 层直接聚合）
//       排序用本度量值，筛选用 [OPP SKUs Qualify] + [OPP SKUs SKU Rank]，
//       三者各司其职，互不嵌套
// 空白拦截: 当前行 category / sku_id / EOH 空时返回 BLANK
// category 上卷: TREATAS(VALUES(trade[category]), inv[category]) 桥接——
//       行/组合筛选下 VALUES(trade[category]) = 当前行 category（单值），
//       组合筛选的 sku 部分不桥接自然忽略（净化完成）
// ========================================

// ── 当前行分组值 ──
VAR __CurrentCategory = SELECTEDVALUE('s02_trade_sku_data_d'[category])
VAR __CurrentSkuId = SELECTEDVALUE('s02_trade_sku_data_d'[sku_id])

RETURN
    IF(
        // ── 短路：category / sku_id 空白或空字符串直接退出 ──
        ISBLANK(__CurrentCategory)
            || ISBLANK(__CurrentSkuId)
            || LEN(TRIM(__CurrentCategory)) = 0
            || LEN(TRIM(__CurrentSkuId)) = 0,
        BLANK(),

        // ── End Period 时间范围与快照日 ──
        VAR __EndPeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Min])
        VAR __EndPeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])
        VAR __EndPeriodDate =
            CALCULATE(
                MAX('s02_inventory_stock_sales_detail_d'[dt]),
                REMOVEFILTERS('s02_inventory_stock_sales_detail_d'),
                's02_inventory_stock_sales_detail_d'[dt] >= __EndPeriodMin,
                's02_inventory_stock_sales_detail_d'[dt] <= __EndPeriodMax
            )

        // ── 当前行 SKU EOH（快照日，TREATAS sku_id 单列桥接）──
        VAR __SkuEOH =
            CALCULATE(
                SUM('s02_inventory_stock_sales_detail_d'[stock_inv_qty]),
                TREATAS(
                    VALUES('s02_trade_sku_data_d'[sku_id]),
                    's02_inventory_stock_sales_detail_d'[sku_id]
                ),
                's02_inventory_stock_sales_detail_d'[dt] = __EndPeriodDate
            )

        RETURN
            IF(
                // ── 短路：无库存记录直接退出 ──
                ISBLANK(__SkuEOH),
                BLANK(),

                // ── Category EOH 合计（category 单值桥接 inv 上卷）──
                VAR __CatEOH =
                    CALCULATE(
                        SUM('s02_inventory_stock_sales_detail_d'[stock_inv_qty]),
                        TREATAS(
                            VALUES('s02_trade_sku_data_d'[category]),
                            's02_inventory_stock_sales_detail_d'[category]
                        ),
                        's02_inventory_stock_sales_detail_d'[dt] = __EndPeriodDate
                    )

                // ── 排序键 = -(category EOH × 权重 + SKU EOH) ──
                RETURN
                    IF(
                        NOT ISBLANK(__CatEOH),
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
| Weeks Cover    | Top SKUs Weeks Cover Display（依赖 Top SKUs Weeks Cover Value）        |
| 对数辅助       | Top SKUs SLS Amt Value / Display（OPP 不参与排序，对数时拖入）         |

- 复用度量的时间口径与 OPP 判定一致（SLS 侧 this period、库存侧快照日）——展示值与资格判定值同源，对数可直接互验
- 列头在视觉对象中可重命名（度量名不改）；如后续要求 OPP 指标集独立演化（如展示 ST%），再按需新建 OPP 前缀度量，勿改 Top 度量语义

---

## 5. 度量值清单

| #  | 度量值             | 类型                                      | 用于视觉对象                 |
| -- | ------------------ | ----------------------------------------- | ---------------------------- |
| 1  | OPP SKUs Qualify   | 资格判定布尔（1 / 0）                     | 视觉级筛选器「为 1」         |
| 2  | OPP SKUs SKU Rank  | RANKX（资格集合内 EOH 降序，DENSE 并列）  | 视觉级筛选器「介于 1 与 3」  |
| 3  | OPP SKUs Sort Key  | 库存量编码排序键（负号翻转）              | 行排序依据（升序）           |
| 4  | 展示指标 9 个      | 复用 Top SKUs 系列（见 §4.4）             | 值区域                       |

- 新建度量 3 个，全部存放于 `_Measures` 隐藏表；Display Folder：`Top & OPP SKUs Analysis\OPP\Qualify`、`Top & OPP SKUs Analysis\OPP\Rank`
- 与 Top 部分合计：Top 14 个 + OPP 新建 3 个（展示指标复用 9 个不重复建）——子模块九共 17 个独立度量

---

## 6. 视觉对象配置

### 6.1 表格

| 配置项           | 内容                                                                                        |
| ---------------- | ------------------------------------------------------------------------------------------- |
| 视觉对象类型     | 表格（平铺，无层级小计；总计行交由视觉对象默认生成，可按需关闭）                             |
| 字段井（行分组） | s02_trade_sku_data_d[category]、s02_trade_sku_data_d[sku_id]                                |
| 视觉级筛选器 1   | Slicer_Framework[framework] = Foundation（前置筛选，一对多关系自动传导双表）                 |
| 视觉级筛选器 2   | OPP SKUs Qualify **为 1**（四条件资格筛选——勿用「≤ 1」放行 BLANK）                          |
| 视觉级筛选器 3   | OPP SKUs SKU Rank 介于 1 与 3（**含下界**——资格集合内每 category 保留 EOH 前三）             |
| 视觉级筛选器 4   | s02_trade_sku_data_d[category] 不为空                                                       |
| 视觉级筛选器 5   | s02_trade_sku_data_d[sku_id] 不为空（双保险）                                               |
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
| inv_agg       | inv WHERE dt = 快照日 GROUP BY sku_id, brand, ax_class：SUM(stock_inv_qty) EOH / SUM(msrp_inv_amt) / SUM(stock)+SUM(in_trans) / MAX(launch_time) |
| grp_avg       | inv WHERE dt = 快照日 GROUP BY brand, ax_class：SUM(stock_inv_qty) / COUNT(DISTINCT sku_id)                                             |
| trade_agg     | trade WHERE framework='Foundation' AND dt ∈ This GROUP BY sku_id：SUM(ROUND(product_qty×sales_price,6)) / SUM(product_qty)              |
| 全局均值      | ST% 均值 = SUM(销售) / (SUM(销售) + SUM(msrp_inv_amt))；WC 均值 = SUM(stock+in_trans) / SUM(product_qty)（两侧各自全量）                 |
| 资格判定      | JOIN 三 CTE（on sku_id）+ 四条件：DATEDIFF(快照日, DATE(launch_time), day) > 14 && ST% < 均值 && WC > 均值 && EOH > 分组均值             |
| Rank / Top3   | DENSE_RANK() OVER (PARTITION BY category ORDER BY EOH DESC) on 资格 SKU 集合；外层 WHERE rank <= 3                                       |
| Sort Key / 行序 | category EOH 合计降序（GROUP BY category）+ 块内 EOH 降序；ORDER BY category_eoh DESC, eoh DESC                                       |
| 展示列        | 同 Top 测试还原（属性最新日期拼接 / 币种换算不在 SQL 范围，输出原值）                                                                   |

- NULL 语义对齐 DAX：ST% / WC 的 DIVIDE 边界（分母 0 / NULL → NULL → 判定不成立）；launch_time NULL / 解析失败 → 无资格；EOH 无 inv 记录 → 无资格
- 参数区（对齐同看板惯例）：framework = 'Foundation'、Platform / Store 全选（等价不筛选）、This Period dt ∈ ['2026-03-29', '2026-07-25']、快照日 '2026-07-25'
- 对数路径：PBI 表格行（资格 + 每 category 3 行、Sort Key 升序）vs SQL 资格集合 rank ≤ 3 结果按 category_eoh DESC, eoh DESC 逐列比对

---

## 8. 注意事项

1. **Top3 在资格集合内取（口径核心）**：先四条件过滤、再组内 EOH 排名取前三——Rank 候选集内嵌资格过滤（FILTER 后 RANKX）；非「全量排名后按 Qualify 过滤」（后者语义为全量 EOH 前三 ∩ 资格行，不符口径）
2. **均值净化（关键防护）**：视觉级 Qualify / Rank 筛选器落地为 (category, sku_id) 跨列组合筛选——trade 侧全量均值必须 `REMOVEFILTERS(两列)` 整体清除，否则均值被收窄为当前行自身、判定恒不成立（Top Size Sort Key 同源坑）；inv 侧聚合不受 trade 列组合筛选影响（两表无关系），无需清除
3. **Qualify 与 Rank 判定同构双写**：四条件判定在两个度量中各写一份（Qualify 当前行版 / Rank 候选表版）——DAX 无表达式共享机制，**口径调整必须两处同步修改**（含全局均值口径）
4. **均值口径为比值均值**：条件 2 / 3 的均值 = 两侧各自全量 sum 后相除（非 SKU 值的算术平均）；trade / inv 两侧 SKU 域独立不对齐（原始口径，勿改为交集域）
5. **纯库存无销售 SKU 天然排除**：行值域为 trade 行字段（无 trade 记录的 sku 不出现）；且条件 3 的 WC 分母（product_qty）为 0 / BLANK 时 SKU 值为 BLANK、严格大于比较不成立——若业务需纳入「零销售高库存」滞销品（典型 OPP 候选），需另行确认 WC 分母兜底规则（如以极小值代替 0）后调整
6. **launch_time 解析**：String 前 10 位 DATEVALUE（"2022-09-02 00:00:00.000" → 2022-09-02）；BLANK / 格式异常经 IFERROR 容错为无资格；判定基准日为 end period 快照日（非 TimeFrame_Max）
7. **条件 4 分组口径**：分组键 inv[brand] + inv[ax_class]（同表，Label / CLASS）；分组 EOH 合计与 SKU 个数均为快照日 inv 侧口径（分组内有库存记录的 distinct sku 数）——SKU 分组归属取 inv 快照日行值（勿改用 trade 侧 brand / ax_class，避免与 EOH 均值域错位）
8. **排序键权重前提**：单 SKU EOH < 1,000,000（库存件数）；EOH 为数量口径非负，无负值翻转问题；category 块间按快照日库存量降序（如业务要求其他块序依据，仅调 Sort Key 的 L1 聚合）
9. **渠道口径不对称**：trade 侧（ST% 分子 / WC 分母 / 全量均值分子）受 Platform / Store 筛选，inv 侧（EOH / 库存金额 / WC 分子）不受——判定分子分母渠道不对称为模型物理限制，业务需知悉
10. **性能结构**：Qualify 每行常数次聚合（先行收窄行集）；Rank 每行组 = 2 条 SE 分组查询（__InvAgg / __GrpAvg）+ 每候选 2 次 trade 桥接 + 纯内存过滤匹配——成本约为 Top v2.1 的 3~4 倍（判定列更多）；若卡顿递进：候选表两表分别物化后内存 join / 建 (dt, sku_id, brand, ax_class) 聚合表 / 源侧预计算资格标签
11. **DENSE 并列语义**：EOH 相同的资格 SKU 共享名次，名次 ≤ 3 的行可能超过 3 行 / 分组（含并列放行，与 Top v2.1 一致）
12. **复用度量边界**：展示指标复用 Top SKUs 系列 9 个（行分组传导同构成立）；OPP 独立演化指标集时新建 OPP 前缀度量，勿改 Top 度量语义
13. **ST% 仅参与判定不展示**（口径文档 §633 说明）；如需展示可后续新增（金额口径 net_sales_amt / (net_sales_amt + msrp_inv_amt)）
14. **期末时点口径**：快照日 = end period 范围内最后一个有数据的日期（快照缺数自动回退）；快照表按日存储只取单日，对区间求和会重复计数库存
15. **函数版本**：RANKX 全版本可用（无 RANK 窗口函数版本要求）；复用 Top 度量的 predictive_buy 为整数比较（同 Top 注意事项 8）
16. **口径与语法**：口径文档中定义的所有指标必须遵守其数据类型与数据格式，与解决方案存在争议时一切以口径文档为准；DAX 文本常量使用双引号，单引号仅用于表名，列名使用方括号
