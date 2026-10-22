# Handbags Sales_ms 解决方案

> **版本**: v1.0
> **模块**: RL E2E Merch Dashboard - Dimension Cross Analysis Tab - Handbags Sales Analysis by Dimension
> **关联口径**: 口径文档/口径Markdown格式/Dimension Cross Analysis.md - 子模块十一（§48~§52）
> **数据底表（销售类）**: s02_trade_sku_data_d
> **数据底表（库存类）**: s02_inventory_stock_sales_detail_d
> **关联维度**: Slicer_Time_Frame_Min_This / Max_This / Min_Last / Max_Last（时间，断开维度）；Field_Parameter_Store_Name（字段参数，行维度来源）；Button_Store_Name（渠道按钮，断开维度）；Slicer_Category（Handbags 前置筛选）；Slicer_Currency_Selection（币种，断开维度）
> **筛选影响范围**: dt（断开维度，DAX 显式筛选）+ shop_name（Button_Store_Name 单选，DAX 显式施加）+ category = "Handbags"（页面视觉对象筛选器，Slicer_Category 经关系传导）+ 其余与两表已建关系的商品维度切片器

---

## 1. 需求理解

### 1.1 模块定位与视觉对象结构

本板块为 Handbags 品类的多维销售分析矩阵，行维度通过字段参数（Field_Parameter_Store_Name）在五个商品维度间动态切换，渠道通过按钮切片器（Button_Store_Name）单选切换：

| 配置项         | 内容                                                                                                                                      |
| -------------- | ----------------------------------------------------------------------------------------------------------------------------------------- |
| 矩阵行         | Field_Parameter_Store_Name[Field_Parameter_Store_Name]（字段参数列，引擎自动展开）——行值 = 当前所选维度字段的实际值，多选时各选中字段并列展开                             |
| 字段参数切片器 | 单选 / 多选均可，可选 Model（spu_model）/ Subclass（ax_sub_class）/ Season（season）/ Category（category）/ Size（sku_size）                         |
| 渠道按钮切片器 | Button_Store_Name 单选：TTL / Tmall（TM）/ JD / RLE（RLE_CN）/ DY_Family / DY_W / DY_MN（DY_M），ActualValue 对应 trade 表 shop_name 字段 |
| 前置筛选       | 视觉对象筛选器 Slicer_Category[category] = "Handbags"（经关系传导限定 trade 侧）                                                          |
| 值列           | 七个指标的 Display 列（SLS Amt、SLS Amt%、SLS Amt% vs LP、SLS Unit、EOH Unit、EOH Unit vs LP、ST%）                                       |

- **字段参数行维度机制**：切片器选中字段后，行区域按所选字段的实际值展开行，行筛选自动落在 s02_trade_sku_data_d 对应列上（单选 = 单列筛选；多选 = 多列筛选交集）——trade 侧指标（SLS Amt / SLS Unit / SLS Amt% 分子）随行维度切换自动重算，无需度量值路由
- **度量值感知当前维度（天然路由，不读参数表）**：`ISINSCOPE(trade 表五个动态维度列)` 判定当前行展开到哪些字段，`VALUES(trade[字段])` 读取当前行该字段值（行上字段 = 当前行值单值）；多选时多个字段同时处于行上，任意字段组合同一套逻辑
- **inv 侧显式桥接**：两张事实表之间无模型关系，行维度值（来自 trade 表字段）对库存类指标（EOH Unit、ST% 库存分母）不自动传递，经 DAX 行上字段谓词匹配（SUMX + FILTER）显式桥接——行上字段精确匹配当前行值、非行字段放行，并叠加 inv[category] = "Handbags" 前置条件
- **行可见性**：IsEmpty 度量值（§4.17）配置为视觉级筛选器（IsEmpty = 1），七个指标全空的行不显示

### 1.2 指标清单

| 序号 | 指标           | 口径章节  | 时间口径                           | 计算公式                                                                                                                 | 数据类型 / 格式                       |
| ---- | -------------- | --------- | ---------------------------------- | ------------------------------------------------------------------------------------------------------------------------ | ------------------------------------- |
| 1    | SLS Amt        | §48      | This Period（区间）                | 该 dimension 下 sum(net_sales_amt)                                                                                       | currency → 币种符号 + `#,##0`      |
| 2    | SLS Amt%       | §49      | This Period（区间）                | 分子：该 dimension 下 sum(net_sales_amt)；分母：Handbags 筛选范围内 sum(net_sales_amt)（ALLSELECTED 五个动态维度列）       | percent_0dp → `#,##0%`             |
| 3    | SLS Amt% vs LP | §49 附属 | This − Last Period（差值）        | SLS Amt%（this）− SLS Amt%（last），原始差值小数，×10000 转 bp 在 Display 层                                           | integer_bp → `#,##0bp`             |
| 4    | SLS Unit       | §50      | This Period（区间）                | 该 dimension 下 sum(product_qty)                                                                                         | integer → `#,##0`                  |
| 5    | EOH Unit       | §51      | End Period（期末时点）             | 该 dimension 下 sum(stock_inv_qty)（快照日单日，行上字段谓词桥接）                                                           | integer → `#,##0`                  |
| 6    | EOH Unit vs LP | §51 附属 | 快照日 this / 快照日 LP − 1       | EOH Unit（this 快照日）/ EOH Unit（LP 快照日）− 1                                                                       | percent_0dp → `#,##0%`（不含正号） |
| 7    | ST%            | §52      | This Period + End Period（跨双表） | sales.sum(net_sales_amt) / (sales.sum(net_sales_amt) + inv.sum(msrp_inv_amt))；销售侧 this period 区间，库存侧快照日单日 | percent_0dp → `#,##0%`             |

### 1.3 时间口径

| 口径                              | 时间范围                                                                                                                                     | 适用指标                                         |
| --------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------ |
| This Period（区间类）             | dt ∈ [Slicer_Time_Frame_Min_This[TimeFrame_Min], Slicer_Time_Frame_Max_This[TimeFrame_Max]]                                                 | SLS Amt、SLS Unit、SLS Amt% 分子分母、ST% 销售侧 |
| Last Period（vs LP 基线，区间类） | dt ∈ [Slicer_Time_Frame_Min_Last[TimeFrame_Min], Slicer_Time_Frame_Max_Last[TimeFrame_Max]]                                                 | LP SLS Amt%（vs LP 的 last 侧）                  |
| End Period This（期末时点类）     | end period 范围 [Slicer_Time_Frame_Max_This[TimeFrame_Min], Slicer_Time_Frame_Max_This[TimeFrame_Max]] 内**最后一个有数据的快照日**    | EOH Unit、ST% 库存侧                             |
| End Period LP（期末时点类）       | end period LP 范围 [Slicer_Time_Frame_Max_Last[TimeFrame_Min], Slicer_Time_Frame_Max_Last[TimeFrame_Max]] 内**最后一个有数据的快照日** | LP EOH Unit（vs LP 的 last 侧）                  |

说明：

- 两张 s02 表日期字段均为 dt（非 data_date）
- 期末时点实现为「范围内最后一个有数据的快照日」：口径定义为区间最后一天，快照缺数时自动回退到范围内最近一天；快照表按日存储，期末时点只取单日，对整段区间求和会把库存重复计数

### 1.4 币种口径

- SLS Amt 为 currency 类指标：货币符号由币种切片器（Slicer_Currency_Selection）决定，千分位整数；数据底表金额仅存储 CNY，Value 层完成汇率换算（原始值 ÷ Currency_ExchangeRate，RMB 汇率 = 1 时换算前后值相同），Display 层仅拼接币种符号
- 占比 / 数量 / 比率类指标不涉及币种换算：占比分子分母同币种，换算与否比值不变

### 1.5 占比分母机制

口径「该 dimension 占 Handbags total 的比例」的分母实现：

- 分母对 trade 表五个动态维度列（spu_model / ax_sub_class / season / category / sku_size）整体施加 `ALLSELECTED`：移除行区域分组筛选（单选移除单列、多选移除多列），恢复外部查询筛选状态——**Handbags 前置筛选（Slicer_Category 经模型关系传导）与全部外部切片器筛选保留**
- Handbags 前置筛选经 Slicer_Category 与 s02_trade_sku_data_d 的一对多关系传导（筛选器位于 Slicer_Category 表列，不在 trade[category] 列上），ALLSELECTED(trade 五列) 不触及该筛选器，分母恒为 Handbags 范围；Category 模式下分母 = Handbags total（行值唯一 → 该行占比 100%，为口径正确语义）
- 不使用 REMOVEFILTERS(五列)——其会移除列上全部筛选器（含外部显式筛选），在 Handbags 前置筛选被直接配置于 trade[category] 列（而非经 Slicer_Category 关系传导）的场景下会误删，ALLSELECTED 恢复外部筛选状态无此风险

### 1.6 渠道上下文机制

Button_Store_Name 为断开维度表（DATATABLE），单选，ActualValue 对应 trade 表 shop_name 字段：

- 渠道上下文以 `FILTER(ALL(trade[shop_name]), 条件)` 实现：ALL 提取 shop_name 全值域，FILTER 按当前选择保留目标值，作为 CALCULATE 筛选参数整体替换 shop_name 列筛选——IF 分支均为 FILTER 迭代表，表语义完整传递（TREATAS 经 IF 分支会被降级为标量，禁用）
- 非 TTL：`FILTER(ALL(trade[shop_name]), trade[shop_name] = 实际值)` 精确限定单店铺
- TTL：`FILTER(ALL(trade[shop_name]), trade[shop_name] IN 六个实际值)` 显式 IN 全部店铺值（TM / JD / RLE_CN / DY_Family / DY_W / DY_M，排除 TTL 自身与非枚举值），等价全渠道口径且排除 shop_name 空白 / 非枚举记录
- 渠道上下文作用于全部 trade 侧指标（SLS Amt / SLS Unit / SLS Amt% 分子分母 / ST% 销售侧）；inv 表无渠道字段，库存侧指标（EOH Unit、ST% 库存侧）不受渠道选择影响

---

## 2. 现状分析

- 数据底表 `s02_trade_sku_data_d`（SKU 粒度交易表，dt 日粒度）：net_sales_amt 为 Power Query 取数新增列（行级 `ROUND(product_qty * sales_price, 6)` 生成，模型内存在，数据库无此列——测试 SQL 验证时按行级乘积还原）；product_qty 为净销售数量口径字段；维度含 dt、shop_name、category、spu_model、ax_sub_class、season、sku_size 及其余商品维度字段
- 数据底表 `s02_inventory_stock_sales_detail_d`（库存+销售+补货 SKU 模型表，dt 日快照）：stock_inv_qty（在库库存数量，EOH Unit 口径字段）、msrp_inv_amt（吊牌库存金额，ST% 库存侧口径字段）；**五动态维度字段齐备**（spu_model / ax_sub_class / season / category / sku_size，已逐一核对数据字典），行上字段谓词桥接全模式可行；**无 shop_name / platform 字段**（渠道筛选不影响库存侧）
- 两张事实表之间无模型关系：行维度值（trade 表字段）向库存类指标的传递经 DAX 行上字段谓词匹配（SUMX + FILTER）显式桥接——仅 ISINSCOPE 判定为行上的字段参与匹配（精确传当前行值），非行字段放行（不传递值域，纯库存无销售的组合不漏算），并叠加 inv[category] = "Handbags" 条件（Size 模式下必需——尺码值跨品类通用；其余模式下防止维度值跨品类重叠的边角数据混入）
- Field_Parameter_Store_Name 字段参数表已存在：五行五字段（spu_model / ax_sub_class / season / category / sku_size，NAMEOF 引用 s02_trade_sku_data_d 列），含 Label 显示列（Model / Subclass / Season / Category / Size）与订单排序列
- Button_Store_Name 按钮表已存在：Label / ActualValue / SortOrder 三列，TTL 与六个店铺实际值（TM / JD / RLE_CN / DY_Family / DY_W / DY_M），与事实表无关系（断开维度）
- Handbags 前置筛选由页面视觉对象筛选器（Slicer_Category[category] = "Handbags"）实现，依赖 Slicer_Category 与 s02_trade_sku_data_d 的模型关系向 trade 侧传导；inv 侧由度量值内显式条件保证，不依赖该筛选器
- 日期筛选器（Min_This / Max_This / Min_Last / Max_Last）为断开维度，时间范围在 DAX 中显式筛选
- 字段名与日期字段（dt）已逐一核对数据字典

---

## 3. 方案设计

### 3.1 度量值分层

```
Value（口径计算）
←  分子 / 分母时间范围显式筛选（This Period / Last Period / 双期快照日）
←  渠道上下文：Button_Store_Name 单选 FILTER(ALL(trade[shop_name]), 条件)
      施加（非 TTL = 列值等于实际值；TTL = IN 六个实际值）
←  SLS Amt% 分母：ALLSELECTED(trade 五个动态维度列)（移除行区域分组，
      保留 Handbags 前置筛选与外部切片器；单选 / 多选统一）
←  inv 侧聚合：SUMX + FILTER 行上字段谓词匹配（ISINSCOPE 判定行上字段，
      行上字段精确匹配当前行值，非行字段放行）+ inv[category] = "Handbags"
←  金额类 Value 层完成币种汇率换算（原始 CNY ÷ Currency_ExchangeRate）
←  LP 中间度量值（LP SLS Amt% / LP EOH Unit）供 vs LP 派生引用
↓
vs LP Value
←  SLS Amt% vs LP：this − last（原始差值小数，Display 层 ×10000 转 bp）
←  EOH Unit vs LP：this / last − 1（变化率，任一侧 BLANK 或 LP 为 0 返回 BLANK）
↓
Display（格式化显示）
←  currency: 币种符号 & FORMAT(#,##0)；integer: FORMAT(#,##0)
←  percent_0dp: FORMAT(#,##0%)（不含正号）
←  integer_bp: 值 ×10000 转 bp（FORMAT(#,##0) & "bp"，负数自带负号）
←  BLANK 统一显示 "-"
↓
IsEmpty（行可见性）
←  七个 Value 全 BLANK → 0；任一有值 → 1（视觉级筛选器 IsEmpty = 1）
```

### 3.2 字段参数路由机制

- **不依赖参数表的天然路由**：行区域字段参数列（Field_Parameter_Store_Name[Field_Parameter_Store_Name]）由引擎展开为所选字段的实际值，行筛选直接落在 s02_trade_sku_data_d 对应列上（单选 = 单列筛选，多选 = 多列筛选交集）——trade 侧分子聚合自动限定当前行值，无需读参数字段名
- **行上字段判定**：`ISINSCOPE(trade 表五个动态维度列)` 逐列判定——处于行上的字段返回 TRUE（参与 inv 侧桥接匹配），非行字段返回 FALSE（放行）；判定基于 trade 表列本身，不读参数表，多选时多个字段同时为 TRUE，天然支持任意组合
- **当前行值读取**：`VALUES(trade[字段])` 在矩阵行上下文求值——行上字段返回当前行值（单值），非行字段返回当前筛选上下文可见值域（谓词短路，不参与匹配）
- **两类机制的去分支化**：① SLS Amt% 分母——ALLSELECTED(trade 五列) 整体移除行区域分组，与当前选中哪几个字段无关；② inv 侧聚合——SUMX + FILTER 五谓词（行上字段启用、非行字段短路放行），任意字段组合同一套逻辑
- **总计行自洽**：开启总计行时 ISINSCOPE 全 FALSE，分子聚合为全 Handbags 合计、占比分母同范围（100%）、inv 侧五谓词全放行（Handbags 全量库存），行值域与总计对齐

### 3.3 inv 侧行上字段谓词桥接

行维度值向 s02_inventory_stock_sales_detail_d 的传递（SUMX + FILTER 谓词匹配）：

- **迭代基础集**：`CALCULATETABLE(inv 表, inv[category] = "Handbags", inv[dt] = 期末快照日)`——快照日单日 Handbags 全部实际行（SKU 粒度，非五列值域笛卡尔积，无组合爆炸）
- **五谓词 AND 匹配**：每个动态维度列一个谓词 `(NOT ISINSCOPE(trade[字段])) || (inv[同名字段] IN VALUES(trade[字段]))`——行上字段启用精确匹配（IN 当前行值，单值），非行字段短路放行（不传 trade 值域，纯库存无销售记录的 SPU / 子类 / 季节 / 尺码组合不漏算）
- **聚合**：SUMX 对谓词命中的行累加 stock_inv_qty（EOH Unit）/ msrp_inv_amt（ST% 库存侧）
- 单选模式语义与逐字段 TREATAS 等价（行上字段 IN 单值 = TREATAS 传单值）；多选模式行上多字段同时匹配，任意组合同一套逻辑
- `inv[category] = "Handbags"` 统一叠加：Size 模式下必需（尺码值跨品类通用，不限定会混入其他品类同尺码库存）；其余模式下为口径保险（维度值跨品类重叠时以 category 为准）
- 与 inv 表已建关系的外部商品维度切片器（Division 等）经 CALCULATETABLE 自动传导，不在桥接谓词内重复处理
- 期末快照日先经 REMOVEFILTERS(整表) 确定性取值（This / LP 两个范围各自取值），不随行上下文 / 切片器漂移
- 总计行（ISINSCOPE 全 FALSE）五谓词全放行 → Handbags 全量库存，行值域与总计自洽

### 3.4 度量值命名与组织

- 命名规则：模块前缀 `Handbags Sales` + 指标名 + 层次后缀（Value / Display）；LP 中间度量值在指标名前加 `LP`；行可见性为 `Handbags Sales IsEmpty`
- Display Folder：`Handbags Sales by Dimension\Base Metrics`、`Handbags Sales by Dimension\Formatting`、`Handbags Sales by Dimension\IsEmpty`
- 度量值统一存放于 `_Measures` 隐藏表

---

## 4. 度量值实现

### 4.1 Handbags Sales SLS Amt Value（当期净销售金额）

```dax
Handbags Sales SLS Amt Value =
// ========================================
// 度量值: Handbags Sales SLS Amt Value
// 中文名: 当期净销售金额
// Display Folder: Handbags Sales by Dimension\Base Metrics
// 用途: 当前行维度值（字段参数动态切换：spu_model / ax_sub_class / season /
//       category / sku_size）This Period 净销售金额（当前币种，当前渠道）
// 依赖: Slicer_Time_Frame_Min_This[TimeFrame_Min] / Slicer_Time_Frame_Max_This[TimeFrame_Max]
//       Button_Store_Name[ActualValue]
//       Slicer_Currency_Selection[Currency_ExchangeRate]
// 口径: 时间范围看 this period；该 dimension 下 sum(net_sales_amt)
// 数据底表: s02_trade_sku_data_d
// 行维度传递: 行区域字段参数列（引擎自动展开）使行筛选直接落在 trade 表当前
//       维度列上（单选单列 / 多选多列），聚合自动限定当前行值，无需路由
// 渠道: Button_Store_Name 单选——非 TTL 限定单店铺，TTL 显式 IN 六个实际值
//       （TM / JD / RLE_CN / DY_Family / DY_W / DY_M，排除空白与非枚举值）
// 前置筛选: Handbags（页面视觉对象筛选器 Slicer_Category 经关系传导）自动生效
// 币种: 数据底表仅存 CNY，Value 层换算为当前币种金额（原始值 ÷ 汇率）；
//       RMB 汇率 = 1 时换算前后值相同
// ========================================

// ── This Period 时间区间 ──
VAR __PeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Min_This[TimeFrame_Min])
VAR __PeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

// ── 渠道上下文（Button_Store_Name 单选；TTL = IN 全部店铺实际值）──
VAR __Store = SELECTEDVALUE('Button_Store_Name'[ActualValue], "TTL")
VAR __IsAllStore = (__Store = "TTL")
VAR __StoreFilter =
    FILTER(
        ALL('s02_trade_sku_data_d'[shop_name]),
        IF(__IsAllStore,
            's02_trade_sku_data_d'[shop_name] IN {"TM", "JD", "RLE_CN", "DY_Family", "DY_W", "DY_M"},
            's02_trade_sku_data_d'[shop_name] = __Store)
    )

// ── 币种汇率（RMB = 1；USD 动态取自数仓汇率表）──
VAR __ExchangeRate = SELECTEDVALUE(Slicer_Currency_Selection[Currency_ExchangeRate], 1)

// ── 当前行维度值 This Period 净销售金额（原始 CNY）──
VAR __BaseValue =
    CALCULATE(
        SUM('s02_trade_sku_data_d'[net_sales_amt]),
        __StoreFilter,
        's02_trade_sku_data_d'[dt] >= __PeriodMin,
        's02_trade_sku_data_d'[dt] <= __PeriodMax
    )

RETURN
    DIVIDE(__BaseValue, __ExchangeRate)   // BLANK ÷ 汇率 = BLANK（当期无销售数据返回空）
```

### 4.2 Handbags Sales SLS Amt Display（当期净销售金额显示）

```dax
Handbags Sales SLS Amt Display =
// ========================================
// 度量值: Handbags Sales SLS Amt Display
// 中文名: 当期净销售金额显示
// Display Folder: Handbags Sales by Dimension\Formatting
// 用途: currency 格式化（币种符号 + 千分位整数，符号由币种切片器决定）；BLANK 显示 "-"
// 依赖: [Handbags Sales SLS Amt Value], Slicer_Currency_Selection[Currency_Symbol]
// 数据格式: 币种符号 & #,##0（如 ¥1,000 / $1,000）
// ========================================
    VAR __Value = [Handbags Sales SLS Amt Value]
    VAR __CurrencySymbol = SELECTEDVALUE(Slicer_Currency_Selection[Currency_Symbol], "¥")
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            __CurrencySymbol & FORMAT(__Value, "#,##0")
        )
```

### 4.3 Handbags Sales SLS Amt% Value（当期销售金额占比）

```dax
Handbags Sales SLS Amt% Value =
// ========================================
// 度量值: Handbags Sales SLS Amt% Value
// 中文名: 当期销售金额占比
// Display Folder: Handbags Sales by Dimension\Base Metrics
// 用途: 当前行维度值占 Handbags total 的销售金额比例（This Period 区间，当前渠道），
//       行维度经字段参数动态切换（单选 / 多选统一）
// 依赖: Slicer_Time_Frame_Min_This[TimeFrame_Min] / Slicer_Time_Frame_Max_This[TimeFrame_Max]
//       Button_Store_Name[ActualValue]
// 口径: 时间范围看 this period；
//       分子：该 dimension 下 sum(net_sales_amt)；
//       分母：Handbags 筛选范围内 sum(net_sales_amt)
// 数据底表: s02_trade_sku_data_d
// 分母机制: ALLSELECTED(trade 五个动态维度列) 整体移除行区域分组筛选（单选移除
//       单列、多选移除多列），恢复外部查询筛选状态；Handbags 前置筛选位于
//       Slicer_Category 表列（经模型关系传导），不受 trade 列 ALLSELECTED 影响，
//       分母恒为 Handbags 范围；Category 模式下分母 = Handbags total（行值唯一，
//       占比 100% 为口径正确语义）
//       不使用 REMOVEFILTERS——其会移除列上全部筛选器（含外部显式筛选），
//       Handbags 前置筛选被直接配置于 trade[category] 列的场景下会误删
// 币种: 分子分母为同表同币种金额（底表 CNY），占比不受币种选择影响
// ========================================

// ── This Period 时间区间 ──
VAR __PeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Min_This[TimeFrame_Min])
VAR __PeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

// ── 渠道上下文（TTL = IN 全部店铺实际值）──
// FILTER(ALL(shop_name), 条件)：IF 分支均为 FILTER 迭代表，表语义完整传递
VAR __Store = SELECTEDVALUE('Button_Store_Name'[ActualValue], "TTL")
VAR __IsAllStore = (__Store = "TTL")
VAR __StoreFilter =
    FILTER(
        ALL('s02_trade_sku_data_d'[shop_name]),
        IF(__IsAllStore,
            's02_trade_sku_data_d'[shop_name] IN {"TM", "JD", "RLE_CN", "DY_Family", "DY_W", "DY_M"},
            's02_trade_sku_data_d'[shop_name] = __Store)
    )

// ── 分子：当前行维度值 This Period 净销售金额（行筛选自动传导）──
VAR __Numerator =
    CALCULATE(
        SUM('s02_trade_sku_data_d'[net_sales_amt]),
        __StoreFilter,
        's02_trade_sku_data_d'[dt] >= __PeriodMin,
        's02_trade_sku_data_d'[dt] <= __PeriodMax
    )

// ── 分母：Handbags 范围内全量 This Period 净销售金额 ──
// ALLSELECTED 五列整体移除行区域分组（单选 / 多选统一），保留外部筛选
VAR __Denominator =
    CALCULATE(
        SUM('s02_trade_sku_data_d'[net_sales_amt]),
        __StoreFilter,
        ALLSELECTED(
            's02_trade_sku_data_d'[spu_model],
            's02_trade_sku_data_d'[ax_sub_class],
            's02_trade_sku_data_d'[season],
            's02_trade_sku_data_d'[category],
            's02_trade_sku_data_d'[sku_size]
        ),
        's02_trade_sku_data_d'[dt] >= __PeriodMin,
        's02_trade_sku_data_d'[dt] <= __PeriodMax
    )

RETURN
    DIVIDE(__Numerator, __Denominator)
```

### 4.4 Handbags Sales SLS Amt% Display（当期销售金额占比显示）

```dax
Handbags Sales SLS Amt% Display =
// ========================================
// 度量值: Handbags Sales SLS Amt% Display
// 中文名: 当期销售金额占比显示
// Display Folder: Handbags Sales by Dimension\Formatting
// 用途: percent_0dp 格式化（百分比整数，不含正号）；BLANK 显示 "-"
// 依赖: [Handbags Sales SLS Amt% Value]
// 数据格式: #,##0%（如 26%）
// ========================================
    VAR __Value = [Handbags Sales SLS Amt% Value]
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            FORMAT(__Value, "#,##0%")
        )
```

### 4.5 Handbags Sales LP SLS Amt% Value（LP 销售金额占比，中间度量值）

```dax
Handbags Sales LP SLS Amt% Value =
// ========================================
// 度量值: Handbags Sales LP SLS Amt% Value
// 中文名: LP 销售金额占比（vs LP 对比基线）
// Display Folder: Handbags Sales by Dimension\Base Metrics
// 用途: Last Period 销售金额占比，供 SLS Amt% vs LP 派生引用，不直接进视觉对象
// 依赖: Slicer_Time_Frame_Min_Last[TimeFrame_Min] / Slicer_Time_Frame_Max_Last[TimeFrame_Max]
//       Button_Store_Name[ActualValue]
// 口径: 与 SLS Amt% 同构（渠道上下文、分母 ALLSELECTED 五个动态维度列整体移除
//       行分组），仅时间范围替换为 Last Period 日期切片器（对比期由切片器选择决定）
// ========================================

// ── Last Period 时间区间（vs LP 基线）──
VAR __PeriodMin_LP = SELECTEDVALUE(Slicer_Time_Frame_Min_Last[TimeFrame_Min])
VAR __PeriodMax_LP = SELECTEDVALUE(Slicer_Time_Frame_Max_Last[TimeFrame_Max])

// ── 渠道上下文（TTL = IN 全部店铺实际值）──
// FILTER(ALL(shop_name), 条件)：IF 分支均为 FILTER 迭代表，表语义完整传递
VAR __Store = SELECTEDVALUE('Button_Store_Name'[ActualValue], "TTL")
VAR __IsAllStore = (__Store = "TTL")
VAR __StoreFilter =
    FILTER(
        ALL('s02_trade_sku_data_d'[shop_name]),
        IF(__IsAllStore,
            's02_trade_sku_data_d'[shop_name] IN {"TM", "JD", "RLE_CN", "DY_Family", "DY_W", "DY_M"},
            's02_trade_sku_data_d'[shop_name] = __Store)
    )

// ── 分子：当前行维度值 Last Period 净销售金额 ──
VAR __Numerator =
    CALCULATE(
        SUM('s02_trade_sku_data_d'[net_sales_amt]),
        __StoreFilter,
        's02_trade_sku_data_d'[dt] >= __PeriodMin_LP,
        's02_trade_sku_data_d'[dt] <= __PeriodMax_LP
    )

// ── 分母：Handbags 范围内全量 Last Period 净销售金额 ──
// ALLSELECTED 五列整体移除行区域分组（单选 / 多选统一），保留外部筛选
VAR __Denominator =
    CALCULATE(
        SUM('s02_trade_sku_data_d'[net_sales_amt]),
        __StoreFilter,
        ALLSELECTED(
            's02_trade_sku_data_d'[spu_model],
            's02_trade_sku_data_d'[ax_sub_class],
            's02_trade_sku_data_d'[season],
            's02_trade_sku_data_d'[category],
            's02_trade_sku_data_d'[sku_size]
        ),
        's02_trade_sku_data_d'[dt] >= __PeriodMin_LP,
        's02_trade_sku_data_d'[dt] <= __PeriodMax_LP
    )

RETURN
    DIVIDE(__Numerator, __Denominator)
```

### 4.6 Handbags Sales SLS Amt% vs LP Value（销售金额占比 vs LP 差值）

```dax
Handbags Sales SLS Amt% vs LP Value =
// ========================================
// 度量值: Handbags Sales SLS Amt% vs LP Value
// 中文名: 销售金额占比 vs LP（差值）
// Display Folder: Handbags Sales by Dimension\Base Metrics
// 用途: this period - last period 占比差值（原始小数，×10000 转 bp 在 Display 层实现）
// 依赖: [Handbags Sales SLS Amt% Value], [Handbags Sales LP SLS Amt% Value]
// 口径: this period - last period（差值，bp 指标）
// 边界: 任一期为 BLANK 时返回 BLANK，避免单侧缺失产生失真差值
// ========================================
    VAR __ThisPct = [Handbags Sales SLS Amt% Value]
    VAR __LastPct = [Handbags Sales LP SLS Amt% Value]

    RETURN
        IF(
            ISBLANK(__ThisPct) || ISBLANK(__LastPct),
            BLANK(),
            __ThisPct - __LastPct
        )
```

### 4.7 Handbags Sales SLS Amt% vs LP Display（销售金额占比 vs LP 显示）

```dax
Handbags Sales SLS Amt% vs LP Display =
// ========================================
// 度量值: Handbags Sales SLS Amt% vs LP Display
// 中文名: 销售金额占比 vs LP 显示
// Display Folder: Handbags Sales by Dimension\Formatting
// 用途: integer_bp 格式化：值 ×10000 转 bp，负数自带负号，零值 0bp；BLANK 显示 "-"
// 依赖: [Handbags Sales SLS Amt% vs LP Value]
// 数据格式: #,##0bp;-#,##0bp;0bp
// 说明: ×10000 转换在 Display 层实现（本指标用于表格展示），Value 层保留
//       原始差值小数可复用
// ========================================
    VAR __Value = [Handbags Sales SLS Amt% vs LP Value]
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            FORMAT(__Value * 10000, "#,##0") & "bp"   // 负数自带负号，零值 0bp
        )
```

### 4.8 Handbags Sales SLS Unit Value（当期净销售数量）

```dax
Handbags Sales SLS Unit Value =
// ========================================
// 度量值: Handbags Sales SLS Unit Value
// 中文名: 当期净销售数量
// Display Folder: Handbags Sales by Dimension\Base Metrics
// 用途: 当前行维度值 This Period 净销售数量（当前渠道），行维度经字段参数动态切换
// 依赖: Slicer_Time_Frame_Min_This[TimeFrame_Min] / Slicer_Time_Frame_Max_This[TimeFrame_Max]
//       Button_Store_Name[ActualValue]
// 口径: 时间范围看 this period；该 dimension 下 sum(product_qty)
// 数据底表: s02_trade_sku_data_d
// 行维度传递: 行筛选自动落在 trade 表当前维度列上（单选单列 / 多选多列），无需路由
// 说明: 数量类指标，不涉及币种换算
// ========================================

// ── This Period 时间区间 ──
VAR __PeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Min_This[TimeFrame_Min])
VAR __PeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

// ── 渠道上下文（TTL = IN 全部店铺实际值）──
VAR __Store = SELECTEDVALUE('Button_Store_Name'[ActualValue], "TTL")
VAR __IsAllStore = (__Store = "TTL")
VAR __StoreFilter =
    FILTER(
        ALL('s02_trade_sku_data_d'[shop_name]),
        IF(__IsAllStore,
            's02_trade_sku_data_d'[shop_name] IN {"TM", "JD", "RLE_CN", "DY_Family", "DY_W", "DY_M"},
            's02_trade_sku_data_d'[shop_name] = __Store)
    )

RETURN
    CALCULATE(
        SUM('s02_trade_sku_data_d'[product_qty]),
        __StoreFilter,
        's02_trade_sku_data_d'[dt] >= __PeriodMin,
        's02_trade_sku_data_d'[dt] <= __PeriodMax
    )
```

### 4.9 Handbags Sales SLS Unit Display（当期净销售数量显示）

```dax
Handbags Sales SLS Unit Display =
// ========================================
// 度量值: Handbags Sales SLS Unit Display
// 中文名: 当期净销售数量显示
// Display Folder: Handbags Sales by Dimension\Formatting
// 用途: integer 格式化（千分位整数）；BLANK 显示 "-"
// 依赖: [Handbags Sales SLS Unit Value]
// 数据格式: #,##0（如 12,345）
// ========================================
    VAR __Value = [Handbags Sales SLS Unit Value]
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            FORMAT(__Value, "#,##0")
        )
```

### 4.10 Handbags Sales EOH Unit Value（当期期末库存数量）

```dax
Handbags Sales EOH Unit Value =
// ========================================
// 度量值: Handbags Sales EOH Unit Value
// 中文名: 当期期末库存数量
// Display Folder: Handbags Sales by Dimension\Base Metrics
// 用途: 当前行维度值期末库存数量（This 期末快照日单日时点），行维度经字段参数
//       动态切换（单选 / 多选统一），跨表行上字段谓词桥接
// 依赖: Slicer_Time_Frame_Max_This[TimeFrame_Min] / [TimeFrame_Max]
// 口径: 时间范围看 this period 最后一天（end period 范围内最后一个快照日）；
//       该 dimension 下 sum(stock_inv_qty)
// 数据底表: s02_inventory_stock_sales_detail_d
// 行维度传递: 两表无模型关系——SUMX + FILTER 行上字段谓词匹配：
//       ISINSCOPE(trade 五列) 判定行上字段，行上字段 IN 当前行值精确匹配，
//       非行字段短路放行（不传值域，纯库存无销售记录的 SPU / 子类 / 季节 /
//       尺码组合不漏算）；统一叠加 inv[category] = "Handbags"
//       （Size 模式必需——尺码值跨品类通用；其余模式为口径保险）
// 渠道: inv 表无 shop_name / platform 字段，本指标不受渠道选择影响
// 说明: 期末时点只取快照日单日，对区间求和会重复计数库存；
//       总计行（ISINSCOPE 全 FALSE）五谓词全放行 → Handbags 全量库存
// ========================================

// ── End Period This 时间范围（期末时点类）──
VAR __EndPeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Min])
VAR __EndPeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

// ── This 期末快照日：end period 范围内最后一个有数据的日期（单日时点）──
// REMOVEFILTERS(整表) 保证快照日不随行维度 / 切片器上下文漂移
VAR __EndPeriodDate =
    CALCULATE(
        MAX('s02_inventory_stock_sales_detail_d'[dt]),
        REMOVEFILTERS('s02_inventory_stock_sales_detail_d'),
        's02_inventory_stock_sales_detail_d'[dt] >= __EndPeriodMin,
        's02_inventory_stock_sales_detail_d'[dt] <= __EndPeriodMax
    )

// ── 行上字段判定（不依赖参数表；多选时多字段同时为 TRUE）──
VAR __InSpuModel = ISINSCOPE('s02_trade_sku_data_d'[spu_model])
VAR __InAxSubClass = ISINSCOPE('s02_trade_sku_data_d'[ax_sub_class])
VAR __InSeason = ISINSCOPE('s02_trade_sku_data_d'[season])
VAR __InCategory = ISINSCOPE('s02_trade_sku_data_d'[category])
VAR __InSkuSize = ISINSCOPE('s02_trade_sku_data_d'[sku_size])

// ── 当前行维度值（行上字段 = 当前行值单值；非行字段 = 可见值域，谓词短路不启用）──
VAR __RowSpuModel = VALUES('s02_trade_sku_data_d'[spu_model])
VAR __RowAxSubClass = VALUES('s02_trade_sku_data_d'[ax_sub_class])
VAR __RowSeason = VALUES('s02_trade_sku_data_d'[season])
VAR __RowCategory = VALUES('s02_trade_sku_data_d'[category])
VAR __RowSkuSize = VALUES('s02_trade_sku_data_d'[sku_size])

// ── 当前行维度值期末库存数量（快照日单日 + Handbags 限定 + 行上字段谓词）──
RETURN
    SUMX(
        FILTER(
            CALCULATETABLE(
                's02_inventory_stock_sales_detail_d',
                's02_inventory_stock_sales_detail_d'[category] = "Handbags",
                's02_inventory_stock_sales_detail_d'[dt] = __EndPeriodDate
            ),
            ((NOT __InSpuModel) || ('s02_inventory_stock_sales_detail_d'[spu_model] IN __RowSpuModel)) &&
            ((NOT __InAxSubClass) || ('s02_inventory_stock_sales_detail_d'[ax_sub_class] IN __RowAxSubClass)) &&
            ((NOT __InSeason) || ('s02_inventory_stock_sales_detail_d'[season] IN __RowSeason)) &&
            ((NOT __InCategory) || ('s02_inventory_stock_sales_detail_d'[category] IN __RowCategory)) &&
            ((NOT __InSkuSize) || ('s02_inventory_stock_sales_detail_d'[sku_size] IN __RowSkuSize))
        ),
        's02_inventory_stock_sales_detail_d'[stock_inv_qty]
    )
```

### 4.11 Handbags Sales EOH Unit Display（当期期末库存数量显示）

```dax
Handbags Sales EOH Unit Display =
// ========================================
// 度量值: Handbags Sales EOH Unit Display
// 中文名: 当期期末库存数量显示
// Display Folder: Handbags Sales by Dimension\Formatting
// 用途: integer 格式化（千分位整数）；BLANK 显示 "-"
// 依赖: [Handbags Sales EOH Unit Value]
// 数据格式: #,##0（如 45,678）
// ========================================
    VAR __Value = [Handbags Sales EOH Unit Value]
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            FORMAT(__Value, "#,##0")
        )
```

### 4.12 Handbags Sales LP EOH Unit Value（LP 期末库存数量，中间度量值）

```dax
Handbags Sales LP EOH Unit Value =
// ========================================
// 度量值: Handbags Sales LP EOH Unit Value
// 中文名: LP 期末库存数量（vs LP 对比基线）
// Display Folder: Handbags Sales by Dimension\Base Metrics
// 用途: LP 期末库存数量，供 EOH Unit vs LP 派生引用，不直接进视觉对象
// 依赖: Slicer_Time_Frame_Max_Last[TimeFrame_Min] / [TimeFrame_Max]
// 口径: 与 EOH Unit 同构（行上字段谓词桥接 + Handbags 限定），期末时点替换为
//       end period LP 范围内最后一个有数据的快照日
// ========================================

// ── End Period LP 时间范围（期末时点类，vs LP 基线）──
VAR __EndPeriodMin_LP = SELECTEDVALUE(Slicer_Time_Frame_Max_Last[TimeFrame_Min])
VAR __EndPeriodMax_LP = SELECTEDVALUE(Slicer_Time_Frame_Max_Last[TimeFrame_Max])

// ── LP 期末快照日：end period LP 范围内最后一个有数据的日期 ──
VAR __EndPeriodDate_LP =
    CALCULATE(
        MAX('s02_inventory_stock_sales_detail_d'[dt]),
        REMOVEFILTERS('s02_inventory_stock_sales_detail_d'),
        's02_inventory_stock_sales_detail_d'[dt] >= __EndPeriodMin_LP,
        's02_inventory_stock_sales_detail_d'[dt] <= __EndPeriodMax_LP
    )

// ── 行上字段判定（不依赖参数表；多选时多字段同时为 TRUE）──
VAR __InSpuModel = ISINSCOPE('s02_trade_sku_data_d'[spu_model])
VAR __InAxSubClass = ISINSCOPE('s02_trade_sku_data_d'[ax_sub_class])
VAR __InSeason = ISINSCOPE('s02_trade_sku_data_d'[season])
VAR __InCategory = ISINSCOPE('s02_trade_sku_data_d'[category])
VAR __InSkuSize = ISINSCOPE('s02_trade_sku_data_d'[sku_size])

// ── 当前行维度值（行上字段 = 当前行值单值；非行字段 = 可见值域，谓词短路不启用）──
VAR __RowSpuModel = VALUES('s02_trade_sku_data_d'[spu_model])
VAR __RowAxSubClass = VALUES('s02_trade_sku_data_d'[ax_sub_class])
VAR __RowSeason = VALUES('s02_trade_sku_data_d'[season])
VAR __RowCategory = VALUES('s02_trade_sku_data_d'[category])
VAR __RowSkuSize = VALUES('s02_trade_sku_data_d'[sku_size])

// ── 当前行维度值 LP 期末库存数量（快照日单日 + Handbags 限定 + 行上字段谓词）──
RETURN
    SUMX(
        FILTER(
            CALCULATETABLE(
                's02_inventory_stock_sales_detail_d',
                's02_inventory_stock_sales_detail_d'[category] = "Handbags",
                's02_inventory_stock_sales_detail_d'[dt] = __EndPeriodDate_LP
            ),
            ((NOT __InSpuModel) || ('s02_inventory_stock_sales_detail_d'[spu_model] IN __RowSpuModel)) &&
            ((NOT __InAxSubClass) || ('s02_inventory_stock_sales_detail_d'[ax_sub_class] IN __RowAxSubClass)) &&
            ((NOT __InSeason) || ('s02_inventory_stock_sales_detail_d'[season] IN __RowSeason)) &&
            ((NOT __InCategory) || ('s02_inventory_stock_sales_detail_d'[category] IN __RowCategory)) &&
            ((NOT __InSkuSize) || ('s02_inventory_stock_sales_detail_d'[sku_size] IN __RowSkuSize))
        ),
        's02_inventory_stock_sales_detail_d'[stock_inv_qty]
    )
```

### 4.13 Handbags Sales EOH Unit vs LP Value（期末库存数量 vs LP 变化率）

```dax
Handbags Sales EOH Unit vs LP Value =
// ========================================
// 度量值: Handbags Sales EOH Unit vs LP Value
// 中文名: 期末库存数量 vs LP（变化率）
// Display Folder: Handbags Sales by Dimension\Base Metrics
// 用途: this period / last period - 1（双期各自快照日单日时点值的变化率）
// 依赖: [Handbags Sales EOH Unit Value], [Handbags Sales LP EOH Unit Value]
// 口径: this period / last period - 1
// 边界: 任一侧为 BLANK 或 LP 侧为 0 时返回 BLANK，避免失真变化率
// ========================================
    VAR __ThisUnit = [Handbags Sales EOH Unit Value]
    VAR __LastUnit = [Handbags Sales LP EOH Unit Value]

    RETURN
        IF(
            ISBLANK(__ThisUnit) || ISBLANK(__LastUnit) || __LastUnit = 0,
            BLANK(),
            __ThisUnit / __LastUnit - 1
        )
```

### 4.14 Handbags Sales EOH Unit vs LP Display（期末库存数量 vs LP 显示）

```dax
Handbags Sales EOH Unit vs LP Display =
// ========================================
// 度量值: Handbags Sales EOH Unit vs LP Display
// 中文名: 期末库存数量 vs LP 显示
// Display Folder: Handbags Sales by Dimension\Formatting
// 用途: percent_0dp 格式化（百分比整数，不含正号）；BLANK 显示 "-"
// 依赖: [Handbags Sales EOH Unit vs LP Value]
// 数据格式: #,##0%（如 15% / -3%）
// ========================================
    VAR __Value = [Handbags Sales EOH Unit vs LP Value]
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            FORMAT(__Value, "#,##0%")
        )
```

### 4.15 Handbags Sales ST% Value（当期售罄率）

```dax
Handbags Sales ST% Value =
// ========================================
// 度量值: Handbags Sales ST% Value
// 中文名: 当期售罄率%（金额口径）
// Display Folder: Handbags Sales by Dimension\Base Metrics
// 用途: 当前行维度值的售罄率——This Period 销售金额 /（This Period 销售金额 +
//       期末库存金额），跨 sales + inv 双表，行维度经字段参数动态切换（单选 / 多选统一）
// 依赖: Slicer_Time_Frame_Min_This[TimeFrame_Min] / Slicer_Time_Frame_Max_This[TimeFrame_Max]
//       Slicer_Time_Frame_Max_This[TimeFrame_Min] / [TimeFrame_Max]
//       Button_Store_Name[ActualValue]
// 口径: 销售金额：看所选时间范围销售金额之和（this period 区间）；
//       期末库存金额：看所选时间范围 end period 最后一天（快照日单日）；
//       sales.sum(net_sales_amt) / (sales.sum(net_sales_amt) + inv.sum(msrp_inv_amt))
// 数据底表: s02_trade_sku_data_d（sales）；s02_inventory_stock_sales_detail_d（inv）
// 跨表说明: 销售侧行筛选自动传导；库存侧 SUMX + FILTER 行上字段谓词匹配
//       （ISINSCOPE 判定行上字段，行上字段精确匹配当前行值，非行字段放行）+
//       inv[category] = "Handbags"；两侧行维度粒度一致（当前行值）
// 渠道: 销售侧受渠道选择影响，库存侧不受（inv 表无渠道字段）——分子分母
//       渠道口径不对称为模型物理限制
// 币种: 分子分母均为原始 CNY 聚合，比值不受币种选择影响
// ========================================

// ── This Period 时间区间（销售侧）──
VAR __PeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Min_This[TimeFrame_Min])
VAR __PeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

// ── End Period 时间范围（库存侧期末时点）──
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

// ── 渠道上下文（TTL = IN 全部店铺实际值）──
// FILTER(ALL(shop_name), 条件)：IF 分支均为 FILTER 迭代表，表语义完整传递
VAR __Store = SELECTEDVALUE('Button_Store_Name'[ActualValue], "TTL")
VAR __IsAllStore = (__Store = "TTL")
VAR __StoreFilter =
    FILTER(
        ALL('s02_trade_sku_data_d'[shop_name]),
        IF(__IsAllStore,
            's02_trade_sku_data_d'[shop_name] IN {"TM", "JD", "RLE_CN", "DY_Family", "DY_W", "DY_M"},
            's02_trade_sku_data_d'[shop_name] = __Store)
    )

// ── 行上字段判定与当前行维度值（不依赖参数表；多选时多字段同时为 TRUE）──
VAR __InSpuModel = ISINSCOPE('s02_trade_sku_data_d'[spu_model])
VAR __InAxSubClass = ISINSCOPE('s02_trade_sku_data_d'[ax_sub_class])
VAR __InSeason = ISINSCOPE('s02_trade_sku_data_d'[season])
VAR __InCategory = ISINSCOPE('s02_trade_sku_data_d'[category])
VAR __InSkuSize = ISINSCOPE('s02_trade_sku_data_d'[sku_size])
VAR __RowSpuModel = VALUES('s02_trade_sku_data_d'[spu_model])
VAR __RowAxSubClass = VALUES('s02_trade_sku_data_d'[ax_sub_class])
VAR __RowSeason = VALUES('s02_trade_sku_data_d'[season])
VAR __RowCategory = VALUES('s02_trade_sku_data_d'[category])
VAR __RowSkuSize = VALUES('s02_trade_sku_data_d'[sku_size])

// ── 分子：当前行维度值 This Period 净销售金额（行筛选 + 渠道上下文）──
VAR __SLSAmt =
    CALCULATE(
        SUM('s02_trade_sku_data_d'[net_sales_amt]),
        __StoreFilter,
        's02_trade_sku_data_d'[dt] >= __PeriodMin,
        's02_trade_sku_data_d'[dt] <= __PeriodMax
    )

// ── 库存加项：当前行维度值期末库存金额（快照日单日，行上字段谓词桥接）──
// 用途：根据图表 X 轴当前激活的维度（字段参数动态切换），从库存明细表中
//       匹配对应行并汇总 msrp_inv_amt；未激活的维度自动放行，已激活的精确匹配。
//       天然支持单选、多选、矩阵层级、父级汇总行。
VAR __InvAmt =
    SUMX(
        // ── 外层：逐行迭代并累加 msrp_inv_amt ──
        FILTER(
            // ── 第 1 层：CALCULATETABLE 预筛选，缩小事实表基数 ──
            // 先锁定品类和快照日，减少后续 FILTER 逐行判断的数据量
            CALCULATETABLE(
                's02_inventory_stock_sales_detail_d',
                's02_inventory_stock_sales_detail_d'[category] = "Handbags",  // 限定品类
                's02_inventory_stock_sales_detail_d'[dt] = __EndPeriodDate     // 限定快照日
            ),
            // ── 第 2 层：FILTER 逐行谓词桥接 ──
            // 每个维度遵循同一模式：(NOT 激活 || 列 IN 行值列表)
            //   NOT 激活 = TRUE  → 该维度未参与 X 轴，自动放行（不参与筛选）
            //   列 IN 行值列表  → 该维度已激活，事实表行必须命中当前行的值
            // 所有维度用 && 串联 → 必须全部通过才保留该行
            // ── 维度 1：spu_model（Model）──
            (
                (NOT __InSpuModel)   // 未激活 → TRUE 放行
                ||                   // 已激活 → 进入右侧匹配
                ('s02_inventory_stock_sales_detail_d'[spu_model] IN __RowSpuModel)  // 多值列表匹配（VALUES 返回表）
            )
            &&
            // ── 维度 2：ax_sub_class（Subclass）──
            (
                (NOT __InAxSubClass)
                || ('s02_inventory_stock_sales_detail_d'[ax_sub_class] IN __RowAxSubClass)
            )
            &&
            // ── 维度 3：season（Season）──
            (
                (NOT __InSeason)
                || ('s02_inventory_stock_sales_detail_d'[season] IN __RowSeason)
            )
            &&
            // ── 维度 4：category（Category）──
            (
                (NOT __InCategory)
                || ('s02_inventory_stock_sales_detail_d'[category] IN __RowCategory)
            )
            &&
            // ── 维度 5：sku_size（Size）──
            (
                (NOT __InSkuSize)
                || ('s02_inventory_stock_sales_detail_d'[sku_size] IN __RowSkuSize)
            )
        ),
        // ── 第 3 层：SUMX 第二个参数，指定迭代中取出的列 ──
        's02_inventory_stock_sales_detail_d'[msrp_inv_amt]
    )
RETURN
    DIVIDE(__SLSAmt, __SLSAmt + __InvAmt)   // 分母加法：任一侧 BLANK 按 0 处理（DAX 算术运算 BLANK 当 0）
```

### 4.16 Handbags Sales ST% Display（当期售罄率显示）

```dax
Handbags Sales ST% Display =
// ========================================
// 度量值: Handbags Sales ST% Display
// 中文名: 当期售罄率显示
// Display Folder: Handbags Sales by Dimension\Formatting
// 用途: percent_0dp 格式化（百分比整数，不含正号）；BLANK 显示 "-"
// 依赖: [Handbags Sales ST% Value]
// 数据格式: #,##0%（如 63%）
// ========================================
    VAR __Value = [Handbags Sales ST% Value]
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            FORMAT(__Value, "#,##0%")
        )
```

### 4.17 Handbags Sales IsEmpty（行非空判定）

```dax
Handbags Sales IsEmpty =
// ========================================
// 度量值: Handbags Sales IsEmpty
// 中文名: 行非空判定
// Display Folder: Handbags Sales by Dimension\IsEmpty
// 用途: 行可见性判定——该行全部核心指标为空时返回 0，任一有值返回 1；
//       用于视觉级筛选器（IsEmpty = 1 仅显示有数据的行）
// 依赖: 全部七个指标 Value 度量值
// 说明: 字段参数行值域为所选维度字段的全量值，当前渠道 / 时间范围下无任何
//       销售与库存数据的行经此筛选器隐藏
// ========================================
    IF(
        ISBLANK([Handbags Sales SLS Amt Value]) &&
        ISBLANK([Handbags Sales SLS Amt% Value]) &&
        ISBLANK([Handbags Sales SLS Amt% vs LP Value]) &&
        ISBLANK([Handbags Sales SLS Unit Value]) &&
        ISBLANK([Handbags Sales EOH Unit Value]) &&
        ISBLANK([Handbags Sales EOH Unit vs LP Value]) &&
        ISBLANK([Handbags Sales ST% Value]),
        0,
        1
    )
```

---

## 5. 度量值清单

| #  | 度量值                                        | 指标类型                         | 用于视觉对象        |
| -- | --------------------------------------------- | -------------------------------- | ------------------- |
| 1  | Handbags Sales SLS Amt Value / Display        | currency                         | 矩阵                |
| 2  | Handbags Sales SLS Amt% Value / Display       | percent_0dp                      | 矩阵                |
| 3  | Handbags Sales LP SLS Amt% Value              | percent_0dp（中间值）            | 仅被 vs LP 引用     |
| 4  | Handbags Sales SLS Amt% vs LP Value / Display | integer_bp（Display 层 ×10000） | 矩阵                |
| 5  | Handbags Sales SLS Unit Value / Display       | integer                          | 矩阵                |
| 6  | Handbags Sales EOH Unit Value / Display       | integer                          | 矩阵                |
| 7  | Handbags Sales LP EOH Unit Value              | integer（中间值）                | 仅被 vs LP 引用     |
| 8  | Handbags Sales EOH Unit vs LP Value / Display | percent_0dp（不含正号）          | 矩阵                |
| 9  | Handbags Sales ST% Value / Display            | percent_0dp                      | 矩阵                |
| 10 | Handbags Sales IsEmpty                        | 行可见性标志（0/1）              | 视觉级筛选器（= 1） |

- 全部度量值存放于 `_Measures` 隐藏表；Display Folder：`Handbags Sales by Dimension\Base Metrics`（Value 层）、`Handbags Sales by Dimension\Formatting`（Display 层）、`Handbags Sales by Dimension\IsEmpty`（可见性）
- LP 中间度量值共 2 个（LP SLS Amt% / LP EOH Unit），不直接进视觉对象

---

## 6. 视觉对象配置

### 6.1 矩阵

| 配置项             | 内容                                                                                                                                                                                       |
| ------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| 视觉对象类型       | 矩阵                                                                                                                                                                                       |
| 行                 | Field_Parameter_Store_Name[Field_Parameter_Store_Name]（字段参数列——引擎自动展开为当前所选维度字段的实际值；单选 = 单字段行，多选 = 多字段并列行） |
| 值列（按口径顺序） | SLS Amt Display → SLS Amt% Display → SLS Amt% vs LP Display → SLS Unit Display → EOH Unit Display → EOH Unit vs LP Display → ST% Display                                             |
| 列标题             | 按口径指标名（SLS Amt / SLS Amt% / SLS Amt% vs LP / SLS Unit / EOH Unit / EOH Unit vs LP / ST%）                                                                                           |
| 视觉级筛选器       | Handbags Sales IsEmpty = 1（隐藏七指标全空行）                                                                                                                                             |
| 总计               | 单选为单字段行，多选为多字段并列行；若开启总计行，ISINSCOPE 全 FALSE——SLS Amt / SLS Unit 为全量合计，SLS Amt% = 100%（分子分母同范围），EOH Unit 为 Handbags 全量库存（五谓词全放行），ST% 为全量分子分母重算                                                                                   |

### 6.2 切片器

| 切片器                      | 类型           | 配置                                                                                                                                                                                                                                          |
| --------------------------- | -------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Field_Parameter_Store_Name  | 字段参数切片器 | 单选 / 多选均支持（样式：切片器 / 按钮）；字段 = Field_Parameter_Store_Name[Field_Parameter_Store_Name]（或 Label 列显示 Model / Subclass / Season / Category / Size），引擎自动展开为所选字段的实际值；指标经 ISINSCOPE / VALUES 作用于 trade 表列天然路由，不依赖参数表读取，无单选限制 |
| Button_Store_Name           | 按钮切片器     | **单选**；字段 = Button_Store_Name[ActualValue]（或 Label 显示 + ActualValue 取值），默认 TTL                                                                                                                                           |
| Slicer_Time_Frame           | 主时间筛选器   | 驱动 Min_This / Max_This / Min_Last / Max_Last 断开维度表，经 SELECTEDVALUE 读入度量值                                                                                                                                                        |
| Slicer_Category（前置筛选） | 视觉对象筛选器 | Slicer_Category[category] = "Handbags"，配置于本矩阵（或页面级），经模型关系限定 trade 侧                                                                                                                                                     |
| Slicer_Currency_Selection   | 断开维度       | SLS Amt 的汇率与符号来源；占比 / 数量 / 比率类不受影响                                                                                                                                                                                        |

---

## 7. 验证方法

测试文件：`test_Handbags_Sales_ms.sql`（MySQL 8.0+，CTE / 窗口函数 / NULL 安全等于 <=>，字面量直嵌），一个文件四段独立执行，分别对齐矩阵的四种行维度状态：

| 段   | 行维度状态                    | 对齐 PBI 配置                                            |
| ---- | ----------------------------- | -------------------------------------------------------- |
| 1/4  | 总计行（无分组）              | 矩阵开启总计行（ISINSCOPE 全 FALSE，SLS Amt% = 100%）    |
| 2/4  | spu_model 分组                | 字段参数切片器单选 Model                                 |
| 3/4  | spu_model + ax_sub_class 分组 | 字段参数切片器多选 Model + Subclass                      |
| 4/4  | 五维组合明细（SKU 级）        | 字段参数切片器全选五个字段                               |

核心还原逻辑：

| 指标                      | 测试 SQL 还原                                                                                                                                                                                            |
| ------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| SLS Amt / SLS Unit        | trade 侧按当前维度字段 GROUP BY 聚合（net_sales_amt = ROUND(product_qty × sales_price, 6) 行级还原，product_qty 直接聚合）；WHERE 含 dt 区间 + shop_name（渠道值或 TTL 六值 IN）+ category = 'Handbags' |
| SLS Amt%                  | 分子同上；分母 = SUM() OVER ()（Handbags + 渠道筛选下的全量合计，对应 ALLSELECTED 五个动态维度列整体移除行分组，与分组粒度 / 字段参数选择无关）                                                        |
| SLS Amt% vs LP            | 时间条件替换为 Last Period 重跑占比，差值为原始小数（×10000 转 bp 在 Display 层，-0.0152 → PBI 显示 -152bp）                                                                                          |
| EOH Unit / EOH Unit vs LP | inv 侧按同名字段 GROUP BY，WHERE 含 dt = 快照日（This / LP 各自取值）+ category = 'Handbags'；**不附加渠道条件**（inv 表无渠道字段）                                                               |
| ST%                       | 销售侧（含渠道条件）与库存侧（不含渠道条件）按当前维度字段各自聚合后相除；分母加法任一侧 NULL 按 0 处理（对齐 DAX 算术 BLANK 当 0）                                                                |

- 行值域 = trade WHERE category = 'Handbags' 的分组列 DISTINCT（全期，不受时间 / 渠道限制——dt 与渠道均在度量值 CALCULATE 内显式施加，不参与行值域生成）；inv 侧纯库存组合（trade 无记录）不在行值域，页面无对应行，SQL 经值域 LEFT JOIN 天然排除；若模型加载层含其他过滤需同步附加
- 维度列含 NULL 归为一组（对应 PBI 行显示 (Blank)）；值域与聚合 JOIN 使用 NULL 安全等于 <=> 保证 NULL 组合正确关联
- 参数区（测试文件头注释）：渠道 TTL（六值 IN，单渠道替换方法注明）、This Period / Last Period 区间、双期快照日，修改时对四段全文替换
- NULL 语义对齐：分子 NULL → 占比 / ST% 输出 NULL（对应 DAX BLANK，显示 "-"）；vs LP 任一侧 NULL → NULL；EOH Unit vs LP 在 LP 侧为 0 或 NULL 时输出 NULL
- IsEmpty 行可见性：SQL 输出值域全部行，七个指标全为 NULL 的行在页面被视觉级筛选器隐藏，对数时忽略

---

## 8. 注意事项

1. **字段参数切片器单选 / 多选均支持**：指标路由不依赖参数表——行上字段由 ISINSCOPE(trade 五列) 判定，行值由 VALUES(trade[字段]) 读取；多选时多个字段同时处于行上，分子（行筛选交集）、占比分母（ALLSELECTED 五列整体移除）、inv 桥接（行上字段同时谓词匹配）天然支持任意组合
2. **行区域使用字段参数列**：Field_Parameter_Store_Name[Field_Parameter_Store_Name]（引擎自动展开为所选字段的实际值并产生行筛选）；本方案指标不读参数表任何列（ISINSCOPE / VALUES 均作用于 trade 表列），参数表仅承担行维度切换
3. **SLS Amt% 分母整体移除行分组**：ALLSELECTED(trade 五个动态维度列) 一次到位（单选 / 多选统一）——移除行区域分组筛选、恢复外部查询筛选状态，Handbags 前置筛选与外部切片器保留；Category 模式下分母 = Handbags total，行值唯一 → 占比 100%，为口径正确语义。不使用 REMOVEFILTERS(五列)——其移除列上全部筛选器（含外部显式筛选），Handbags 前置筛选被直接配置于 trade[category] 列（而非经 Slicer_Category 关系传导）的场景下会误删，ALLSELECTED 无此风险
4. **inv 侧 Handbags 限定不可省略**：Size 模式下尺码值跨品类通用，`inv[category] = "Handbags"` 缺失会把其他品类同尺码库存计入；其余模式为口径保险（维度值跨品类重叠时以 category 为准）。inv 桥接谓词只匹配行上字段、非行字段放行（不传 trade 值域）——纯库存无销售记录的 SPU / 子类 / 季节 / 尺码组合不漏算；若改为五列全 TREATAS 传递 VALUES 值域，会把该部分库存排除、EOH 低估
5. **渠道上下文**：Button_Store_Name 单选经 `FILTER(ALL(trade[shop_name]), 条件)` 施加（非 TTL = 列值等于实际值；TTL = 显式 IN 六个实际值，排除空白与非枚举店铺值）；IF 分支均为 FILTER 迭代表，表语义完整传递——TREATAS 经 IF 分支会被降级为标量，禁用。渠道值清单以 Button_Store_Name 表为准，新增店铺时同步扩展 TTL 集合。trade 侧全部指标受渠道影响；inv 侧不受（无渠道字段）——ST% 分子分母渠道口径不对称为模型物理限制，业务需知悉
6. **Handbags 前置筛选的双侧实现**：trade 侧依赖页面视觉对象筛选器（Slicer_Category = "Handbags"）经模型关系传导（Slicer_Category 与 s02_trade_sku_data_d 一对多关系）；inv 侧由度量值内 `inv[category] = "Handbags"` 显式保证，不依赖页面配置。若页面筛选缺失，trade 侧指标范围会扩大至全品类（占比分母的 ALLSELECTED 恢复外部筛选状态，无法弥补页面筛选缺失），双侧范围不一致风险需知悉
7. **期末时点口径**：This / LP 两个快照日各自取对应范围内最后一个有数据的日期（快照缺数自动回退）；快照表按日存储只取单日，对整段区间求和会重复计数库存
8. **net_sales_amt 列来源**：模型内为 Power Query 行级计算列（ROUND(product_qty × sales_price, 6)），数据库无此列——测试 SQL 验证时按行级乘积还原，不可直接引用数据库 net_sales_amt（若底表存在同名字段以取数 SQL 为准核对）
9. **vs LP 空值规则**：SLS Amt% vs LP 任一期占比 BLANK → 差值 BLANK；EOH Unit vs LP 在任一侧 BLANK 或 LP 侧为 0 时返回 BLANK（避免除零与单侧缺失失真）；SLS Amt% vs LP 的 ×10000 转 bp 在 Display 层实现（表格展示场景），Value 层保持原始差值小数
10. **IsEmpty 筛选器**：视觉级筛选器配置「等于 1」；该度量覆盖七个 Value 指标，后续新增指标需同步扩展判定清单
11. **行维度扩展**：Field_Parameter_Store_Name 新增字段（如 color_name）时，需同步扩展三处——SLS Amt% 分母的 ALLSELECTED 列清单、inv 桥接的 ISINSCOPE 判定 + VALUES 行值变量、FILTER 谓词条件（各库存侧度量值同构展开），行可见性 IsEmpty 不受影响
12. **口径与语法**：口径文档中定义的所有指标必须遵守其数据类型与数据格式，与解决方案存在争议时一切以口径文档为准；DAX 文本常量使用双引号，单引号仅用于表名，列名使用方括号，例如：`[category] = "Handbags"`
13. **inv 桥接性能**：SUMX + FILTER 迭代快照日单日 Handbags 行集合（SKU 粒度实际行，非维度值域笛卡尔积），矩阵每个行上下文各执行一次；行数随品类库存规模增长，出现卡顿时优先排查快照日条件是否生效（失效会迭代全表行）与 Handbags 硬条件是否命中
