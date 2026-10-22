# Handbags & Outwear Sales Performance 矩阵解决方案

> **版本**: v1.0
> **模块**: RL E2E Merch Dashboard - Dimension Cross Analysis Tab - Handbags Sales Performance
> **关联口径**: 口径文档/口径Markdown格式/Dimension Cross Analysis.md - 子模块十：Handbags Sales Performance（§43-§47）
> **数据底表（销售类）**: s02_trade_sku_data_d
> **数据底表（库存类）**: s02_inventory_stock_sales_detail_d
> **关联维度**: Dim_ColMetric_Handbags&Outwear_Sales_ms（列，三层 ChannelGroup > Label > ColName，本目录单独文件）；Slicer_Spu_Model（行，一对多关系 × 2）；Slicer_Category（前置筛选，视觉对象筛选器，一对多关系 × 2）；Slicer_Time_Frame_Min_This / Max_This / Min_Last / Max_Last（时间，断开维度）；Slicer_Currency_Selection（币种，断开维度）

---

## 1. 需求理解

### 1.1 模块定位

Handbags Sales Performance 是 Handbags/Outerwear 前置品类筛选下的 Model 粒度销售绩效矩阵：

- **前置筛选**：商品维度切换 category = 'Handbags'/'Outerwear'，作为前置筛选条件在视觉对象筛选器中完成（Slicer_Category[category] IN ("Handbags", "Outerwear")，经与 trade / inv 双侧一对多关系自动传导限定两侧指标，度量值内零品类硬编码——后续品类切换仅需修改筛选器配置；口径文档 'Outwear' 已确认为笔误，底表实际值为 'Outerwear'）
- **行**：Slicer_Spu_Model[spu_model]（唯一行维度；维度表与两张事实表均一对多关联，行筛选自动传导，无需显式 DAX 处理行维度传递）
- **列**：三层结构 ChannelGroup（仅 Store）> Label（TTL + 6 店铺）> ColName（指标列），共 31 列
  - TTL 列组合（7 列）：SLS Unit、SLS Amt、SLS Amt%、Amt vs LP、ST%、EOH、EOH vs LP
  - 各店铺列组合（6 店铺 × 4 列，组合完全一致）：SLS Unit、SLS Amt、SLS Amt%、vs LP
- **行可见性**：Display 层 BLANK 一律返回 BLANK()（不返回 "-"）——矩阵检测到该行全部度量值均为 BLANK() 时自动隐藏该行（含层级行），无需 IsEmpty 视觉级筛选器

### 1.2 路由维度

| 路由维度 | 来源 | 类型 | 说明 |
| -------- | ---- | ---- | ---- |
| 渠道 | Dim_ColMetric_Handbags&Outwear_Sales_ms 的 Label_Value | 断开列维度 | 过滤事实表 [shop_name]；Label_Value = "TTL" 时走 ALLSELECTED 全店铺合计 |
| 指标 | Dim_ColMetric_Handbags&Outwear_Sales_ms 的 ColType | 断开列维度 | 8 种：SLS Unit / SLS Amt / SLS Amt% / Amt vs LP / ST% / EOH / EOH vs LP / vs LP |
| 行维度 | Slicer_Spu_Model[spu_model] | 维度表字段（一对多关系 × 2） | 行筛选经模型关系自动传导到 trade / inv 双表（Slicer_Spu_Model 与两张事实表均一对多关系）；占比分母移除行维度筛选用 ALLSELECTED 整表（见 3.4） |

**Label → 事实表实际值映射**（已核对 Slicer_Store_Name）：

| ChannelGroup | Label | Label_Value | 说明 |
| ------------ | ----- | ----------- | ---- |
| Store | TTL | TTL（特殊标记） | ALLSELECTED 移除视觉对象内部 shop_name 筛选，保留外部切片器 |
| Store | Tmall / JD / RLE / DY_Family / DY_W / DY_MN | TM / JD / RLE_CN / DY_Family / DY_W / DY_M | 过滤 [shop_name] |

**TTL 特殊处理**：度量值中对 [shop_name] 应用 ALLSELECTED——移除视觉对象内部的渠道筛选，保留外部切片器（Slicer_Store_Name 等）的筛选，即 TTL = 外部筛选上下文下的全店铺合计。

**占比分母类别总计**：分母需要移除视觉对象内部的行维度筛选、保留外部切片器。行维度为 Slicer_Spu_Model[spu_model]，因该表含 sort_order 排序字段（spu_model 按列排序），ALLSELECTED 必须针对**整张表**（`ALLSELECTED('Slicer_Spu_Model')`），不能用单列写法——详见 3.4。

### 1.3 时间口径

| 口径 | 时间范围 | 适用指标 |
| ---- | -------- | -------- |
| This Period（区间类） | dt ∈ [Slicer_Time_Frame_Min_This[TimeFrame_Min], Slicer_Time_Frame_Max_This[TimeFrame_Max]] | SLS Unit、SLS Amt、SLS Amt% 分子分母、Amt vs LP 分子、vs LP this 侧占比分子分母、ST% 销售侧 |
| Last Period（vs LP 基线，区间类） | dt ∈ [Slicer_Time_Frame_Min_Last[TimeFrame_Min], Slicer_Time_Frame_Max_Last[TimeFrame_Max]] | Amt vs LP 分母、vs LP last 侧占比分子分母 |
| End Period This（期末时点类） | end period This 范围 [Slicer_Time_Frame_Max_This[TimeFrame_Min], Slicer_Time_Frame_Max_This[TimeFrame_Max]] 内**最后一个有数据的快照日** | EOH、EOH vs LP this 侧、ST% 库存侧 |
| End Period LP（期末时点类） | end period LP 范围 [Slicer_Time_Frame_Max_Last[TimeFrame_Min], Slicer_Time_Frame_Max_Last[TimeFrame_Max]] 内**最后一个有数据的快照日** | EOH vs LP 分母 |

说明：

- 两张 s02 表日期字段均为 **dt**（非 data_date）
- 期末时点实现为「范围内最后一个有数据的快照日」：口径为 end period 最后一天，快照缺数时自动回退到范围内最近一天；快照表按日存储只取单日，整段区间求和会重复计数库存
- vs LP 受 last period 时间筛选器影响（this period / last period 对比）

### 1.4 币种口径

- SLS Amt 为 currency 类指标：货币符号由币种切片器（Slicer_Currency_Selection）决定，千分位整数；数据底表金额仅存储 CNY，Value 层完成汇率换算（原始值 ÷ Currency_ExchangeRate，RMB 汇率 = 1 时换算前后值相同），Display 层仅拼接币种符号
- 占比 / 数量 / 比率类指标不涉及币种换算：占比分子分母同币种，换算与否比值不变；Amt vs LP 分子分母均取原始 CNY 聚合，比值不受币种选择影响

---

## 2. 现状分析

- 数据底表 `s02_trade_sku_data_d`（SKU 粒度交易表，dt 日粒度）：net_sales_amt 为 Power Query 取数新增列（行级 `ROUND(product_qty * sales_price, 6)` 生成，模型内存在，数据库无此列——测试 SQL 验证时按行级乘积还原）；product_qty 为净销售数量口径字段；维度含 dt、shop_name、category、spu_model 及其余商品维度字段
- 数据底表 `s02_inventory_stock_sales_detail_d`（库存+销售+补货 SKU 模型表，dt 日快照）：stock_inv_qty（在库库存数量，EOH 口径字段）、msrp_inv_amt（吊牌库存金额，ST% 库存侧口径字段）；**spu_model / category 字段齐备**（已逐一核对数据字典，支持与 Slicer_Spu_Model 建立一对多关系）；**无 shop_name / platform 字段**（渠道筛选不影响库存侧）
- 行维度表 `Slicer_Spu_Model` 已存在：DISTINCT spu_model（Polo Play / Polo ID / Polo Blaze）+ sort_order 排序字段（1/2/3/99），与 s02_trade_sku_data_d、s02_inventory_stock_sales_detail_d **均建立一对多关系（共享维度模式）**——行筛选自动传导到两张事实表，trade / inv 两侧指标均无需显式处理行维度传递（无 TREATAS 桥接）
- 列维度表 `Dim_ColMetric_Handbags&Outwear_Sales_ms` 已存在（本目录单独文件）：ChannelGroup / Label / Label_Value / ColName / ColType / Metric_Format / Metric_IsCurrencyAmount / 颜色字段，31 行
- 两张事实表之间无模型关系，但行维度传导无需两表直连：行筛选从 Slicer_Spu_Model 出发经两条 1:N 关系分别传导到 trade / inv（筛选沿"维度表 → 事实表"关系传递，与两事实表之间是否有关系无关）——inv 侧指标（EOH、EOH vs LP、ST% 库存侧）无需 TREATAS 桥接；总计行两表均无 spu_model 筛选（品类全量语义，见注意事项 5）
- Handbags/Outerwear 前置筛选：由页面视觉对象筛选器（Slicer_Category[category] IN ("Handbags", "Outerwear")）承担，经 Slicer_Category 与 trade / inv 双侧一对多关系自动传导——度量值内零品类硬编码，后续品类切换（改值 / 增删值）仅需修改视觉对象筛选器配置
- 日期筛选器（Min_This / Max_This / Min_Last / Max_Last）为断开维度，时间范围在 DAX 中显式筛选
- 字段名与日期字段（dt）已逐一核对数据字典

---

## 3. 方案设计

### 3.1 度量值分层

```
Act Base Value / LY Base Value
    ←  渠道上下文路由（Label_Value，TTL 走 ALLSELECTED）
       + ColType 指标路由 + 行维度关系自然传导，保留 CNY 原始值
       （Act 覆盖 5 种基础指标；LY 按 vs LP 类 ColType 返回对应 LP 基线）
    ↓
Base Value（总路由）
    ←  vs LP 三种派生（Amt vs LP / vs LP / EOH vs LP）：
       分子经整表 REMOVEFILTERS + 三条件重路由取同渠道基础指标列，
       分母取 LY Base Value，派生比值 / 差值
       其余 5 种 ColType 直接取 Act Base Value
    ↓
Cell Value
    ←  金额类（Metric_IsCurrencyAmount = TRUE）汇率换算（÷ Currency_ExchangeRate）
    ↓
Cell Display
    ←  按 Metric_Format 格式化（integer / currency / percent_0dp / integer_bp）
       BLANK 一律返回 BLANK()（矩阵自动隐藏全空行，不返回 "-"）
    ↓
Cell Font Color / Cell Background Color
    ←  按 Metric_ColorRule 调度颜色 / ColName 层与上层背景区分
```

### 3.2 渠道上下文构造（度量值内统一模式）

| 列位置 | shop_name 上下文 |
| ------ | ---------------- |
| TTL | ALLSELECTED([shop_name])：移除视觉内部筛选，保留外部切片器 |
| Store 组非 TTL | [shop_name] = Label_Value（基于 ALLSELECTED 集，与外部切片器取交集） |

实现为表变量 `__ShopNameCtx`（UNION+FILTER 构造，保证表类型稳定——IF 分支返回表表达式会被降级为标量，禁用），作为 CALCULATE 过滤器统一传入所有 trade 侧聚合。ChannelGroup 仅 Store 一组，无需 ChannelGroup 分支判定。

### 3.3 指标口径（ColType 路由）

| ColType | 数据底表 | 时间口径 | 公式 | 格式 |
| ------- | -------- | -------- | ---- | ---- |
| SLS Unit | trade | This Period 区间 | sum(product_qty)（§43） | integer |
| SLS Amt | trade | This Period 区间 | sum(net_sales_amt)（§44） | currency |
| SLS Amt% | trade | This Period 区间 | 单元格 SLS Amt / Handbags/Outerwear 筛选范围内全 model 合计（§45） | percent_0dp |
| Amt vs LP | trade | This / Last 区间 | SLS Amt This / SLS Amt Last - 1（§44 附属） | percent_0dp |
| ST% | trade + inv | This 区间 / This 快照单日 | SLS Amt /（SLS Amt + 期末库存金额 msrp_inv_amt）（§46） | percent_0dp |
| EOH | inv | This 快照单日 | sum(stock_inv_qty)（§47） | integer |
| EOH vs LP | inv | 双期快照单日 | EOH This / EOH LP - 1（§47 附属） | percent_0dp |
| vs LP | trade | This / Last 区间 | SLS Amt% This - SLS Amt% Last（差值，×10000 转 bp 在 Display 层）（§45 附属） | integer_bp |

### 3.4 SLS Amt% 占比分母（ALLSELECTED 整表）

口径「该 spu_model 占 Handbags/Outerwear 筛选范围内 total 的比例」的分母实现：

- 分母对 `'Slicer_Spu_Model'` **整表**施加 `ALLSELECTED`：移除行区域分组筛选，恢复外部查询筛选状态——Handbags/Outerwear 前置筛选（Slicer_Category 经模型关系传导，筛选器位于 Slicer_Category 表列）与全部外部切片器筛选保留
- **必须整表、不能单列**：Slicer_Spu_Model 含 sort_order 排序字段，spu_model 列通过"按列排序（Sort by Column）"绑定 sort_order——矩阵行按 spu_model 分组时，视觉对象查询会同时按 spu_model + sort_order 组合分组，`ALLSELECTED(Slicer_Spu_Model[spu_model])` 单列写法无法从组合筛选中剥离 sort_order 部分，行维度筛选残留导致分母恒等于分子（占比 100%）；`ALLSELECTED('Slicer_Spu_Model')` 整表写法恢复整表外部筛选状态，spu_model 与 sort_order 上的内部筛选一并移除
- 不使用 REMOVEFILTERS——其会移除列上全部筛选器（含外部显式筛选），前置筛选被直接配置于 trade[category] 列（而非经 Slicer_Category 关系传导）的场景下会误删，ALLSELECTED 恢复外部筛选状态无此风险

### 3.5 inv 侧行维度传递（关系自然传导）

EOH / EOH vs LP / ST% 库存侧取数 inv 表，行维度筛选经模型关系自动传导：

- **共享维度传导**：Slicer_Spu_Model 与 s02_inventory_stock_sales_detail_d 建立一对多关系——矩阵行（Slicer_Spu_Model[spu_model]）的行筛选沿关系自动传导到 inv 表，明细行限定当前行 model，与 trade 侧传导路径对称（维度表 → 两张事实表各一条 1:N 关系），无需 TREATAS 桥接；Power BI 筛选只沿已建立的关系传递，同名字段（trade[spu_model] / inv[spu_model]）之间无关系不会自动传递，两侧均以 Slicer_Spu_Model 为桥即可达
- **前置品类关系传导**：品类筛选由视觉对象筛选器（Slicer_Category）经与 trade / inv 双侧一对多关系自动传导——度量值内零品类硬编码，后续前置品类调整（如改为其他 category 值 / 增删值）仅需修改视觉对象筛选器配置，无需触碰任何 DAX；口径文档 'Outwear' 已确认为笔误，实际值 'Outerwear'
- **渠道不作用**：inv 表无 shop_name / platform 字段，渠道上下文不作用于 inv 侧——EOH / EOH vs LP / ST% 库存侧不受渠道列影响（三者仅存在于 TTL 列，无跨渠道列对比问题）；ST% 分子分母渠道口径不对称为模型物理限制，业务需知悉
- **总计行语义**：总计行无 spu_model 行分组，trade / inv 两侧均不限定 model——总计 = Handbags/Outerwear 品类全量（行值域 Slicer_Spu_Model 仅 3 个 model，品类下其余 model 计入总计但不展示明细行），总计 ≠ 明细行之和；业务若需总计 = 展示行之和，关闭矩阵总计行即可（见注意事项 5）
- 与 Handbags_Sales_ms（子模块十一）谓词放行模式的差异：该方案行维度来自字段参数动态展开（行字段属于 trade 表，inv 无从经关系接收），必须 ISINSCOPE + VALUES 谓词桥接；本方案行维度有专门维度表且与双表建关系，行筛选由模型自动传递，写法最简

### 3.6 度量值命名与组织

- 命名规则：模块前缀 `Handbags & Outwear Sales` + 层次后缀（Act Base Value / LY Base Value / Base Value / Cell Value / Cell Display / Cell Font Color / Cell Background Color）
- 表名与度量值名含 "&" 字符，DAX 引用必须加单引号：`'Dim_ColMetric_Handbags&Outwear_Sales_ms'[ColType]`
- Display Folder：`Handbags Sales Performance\Base Metrics`（Value 层）、`Handbags Sales Performance\Formatting`（Display / 颜色层）
- 度量值统一存放于 `_Measures` 隐藏表

---

## 4. 度量值实现

### 4.1 Handbags & Outwear Sales Act Base Value（This Period 基础值）

```dax
Handbags & Outwear Sales Act Base Value =
// ========================================
// 度量值: Handbags & Outwear Sales Act Base Value
// Display Folder: Handbags Sales Performance\Base Metrics
// 用途: This Period 基础值，按渠道上下文（Label_Value）+ ColType 路由，
//       覆盖 5 种基础指标列（SLS Unit / SLS Amt / SLS Amt% / ST% / EOH），
//       保留 CNY 原始值；vs LP 三种派生指标在 Base Value 总路由中处理，本度量值不涉及
// 依赖: 'Dim_ColMetric_Handbags&Outwear_Sales_ms'[Label_Value, ColType]
//       Slicer_Time_Frame_Min_This[TimeFrame_Min] / Slicer_Time_Frame_Max_This[TimeFrame_Max]
// 数据底表: s02_trade_sku_data_d（销售类）
//           s02_inventory_stock_sales_detail_d（库存类：EOH / ST% 库存侧）
// 行维度: Slicer_Spu_Model[spu_model] 与 trade / inv 均一对多关系，行筛选自动传导
//       双表，无需显式处理（无 TREATAS 桥接）
// 前置筛选: category 筛选由视觉对象筛选器（Slicer_Category）经与 trade / inv 双侧
//       一对多关系自动传导，度量值内零品类硬编码（后续品类切换仅改筛选器配置）
// 汇率换算: 不在此度量值处理，保持原始 CNY，由 Cell Value 层统一换算
// ========================================

// ── 渠道路由 ──
VAR __LabelValue = SELECTEDVALUE('Dim_ColMetric_Handbags&Outwear_Sales_ms'[Label_Value], "TTL")
VAR __IsTTL = (__LabelValue = "TTL")

// ── 指标路由 ──
VAR __ColType = SELECTEDVALUE('Dim_ColMetric_Handbags&Outwear_Sales_ms'[ColType])

// ── This Period 时间区间（区间类指标）──
VAR __PeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Min_This[TimeFrame_Min])
VAR __PeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

// ── End Period This 时间范围（期末时点类指标）──
VAR __EndPeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Min])
VAR __EndPeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

// ── This 期末快照日：end period This 范围内最后一个有数据的日期（单日时点）──
// REMOVEFILTERS(整表) 保证快照日不随行维度 / 切片器上下文漂移
VAR __EndPeriodDate =
    CALCULATE(
        MAX('s02_inventory_stock_sales_detail_d'[dt]),
        REMOVEFILTERS('s02_inventory_stock_sales_detail_d'),
        's02_inventory_stock_sales_detail_d'[dt] >= __EndPeriodMin,
        's02_inventory_stock_sales_detail_d'[dt] <= __EndPeriodMax
    )

// ── 渠道上下文过滤器（shop_name 侧；UNION+FILTER 保证表类型稳定）──
//   TTL 列   → ALLSELECTED([shop_name])：移除视觉对象内部 shop_name 筛选，保留外部切片器
//   Store 列 → [shop_name] = Label_Value（基于 ALLSELECTED 集，与外部切片器取交集）
VAR __ShopNameCtx =
    UNION(
        FILTER(
            ALLSELECTED('s02_trade_sku_data_d'[shop_name]),
            __IsTTL
        ),
        FILTER(
            ALLSELECTED('s02_trade_sku_data_d'[shop_name]),
            (NOT __IsTTL) && 's02_trade_sku_data_d'[shop_name] = __LabelValue
        )
    )

// ═══ 基础聚合：SLS Amt / SLS Unit（This Period 区间 + 渠道上下文，行维度自然传导）═══
VAR __SLSAmt_This =
    CALCULATE(
        SUM('s02_trade_sku_data_d'[net_sales_amt]),
        __ShopNameCtx,
        's02_trade_sku_data_d'[dt] >= __PeriodMin,
        's02_trade_sku_data_d'[dt] <= __PeriodMax
    )
VAR __SLSUnit_This =
    CALCULATE(
        SUM('s02_trade_sku_data_d'[product_qty]),
        __ShopNameCtx,
        's02_trade_sku_data_d'[dt] >= __PeriodMin,
        's02_trade_sku_data_d'[dt] <= __PeriodMax
    )

// ═══ SLS Amt%（占比 = 单元格 SLS Amt / Handbags/Outerwear 筛选范围内全 model 合计）═══
// 分母 ALLSELECTED('Slicer_Spu_Model') 整表：移除行区域分组筛选，保留外部筛选；
// 必须整表不能单列——spu_model 按 sort_order 按列排序，单列 ALLSELECTED 无法剥离
// 组合筛选中的 sort_order 部分，行维度筛选残留导致分母恒等于分子（占比 100%）
VAR __SLSAmt_Total =
    CALCULATE(
        SUM('s02_trade_sku_data_d'[net_sales_amt]),
        __ShopNameCtx,
        ALLSELECTED('Slicer_Spu_Model'),
        's02_trade_sku_data_d'[dt] >= __PeriodMin,
        's02_trade_sku_data_d'[dt] <= __PeriodMax
    )
VAR __SLSAmtPct = DIVIDE(__SLSAmt_This, __SLSAmt_Total)

// ═══ EOH（期末库存数量，仅 TTL 列；inv 表 This 期末快照日单日时点）═══
// 行维度经 Slicer_Spu_Model → inv、品类经 Slicer_Category → inv 一对多关系
// 自动传导（明细行限当前行 model + 前置品类；总计行无行筛选，为品类全量语义）
VAR __EOHUnit =
    CALCULATE(
        SUM('s02_inventory_stock_sales_detail_d'[stock_inv_qty]),
        's02_inventory_stock_sales_detail_d'[dt] = __EndPeriodDate
    )

// ═══ ST%（售罄率%金额，仅 TTL 列；跨 trade + inv 双表）═══
// 分子: This Period SLS Amt（渠道上下文 + 行维度自然传导）
// 分母加项: This 期末快照日单日库存金额（行维度 / 品类均经关系传导）
// 分母加法任一侧 BLANK 按 0 处理（DAX 算术运算 BLANK 当 0）
VAR __InvAmt_End =
    CALCULATE(
        SUM('s02_inventory_stock_sales_detail_d'[msrp_inv_amt]),
        's02_inventory_stock_sales_detail_d'[dt] = __EndPeriodDate
    )
VAR __STPct = DIVIDE(__SLSAmt_This, __SLSAmt_This + __InvAmt_End)

RETURN
    SWITCH(
        __ColType,
        "SLS Unit", __SLSUnit_This,   // SLS Unit Act
        "SLS Amt",  __SLSAmt_This,    // SLS Amt Act
        "SLS Amt%", __SLSAmtPct,      // SLS Amt% Act
        "ST%",      __STPct,          // ST% Act（仅 TTL 列）
        "EOH",      __EOHUnit,        // EOH Act（仅 TTL 列）
        BLANK()
    )
```

### 4.2 Handbags & Outwear Sales LY Base Value（Last Period 基线）

```dax
Handbags & Outwear Sales LY Base Value =
// ========================================
// 度量值: Handbags & Outwear Sales LY Base Value
// Display Folder: Handbags Sales Performance\Base Metrics
// 用途: vs LP 三种派生指标（Amt vs LP / vs LP / EOH vs LP）的 Last Period 基线，
//       按 ColType 路由返回对应 LP 值：
//       - "Amt vs LP" → LP SLS Amt（区间汇总，原始 CNY）
//       - "vs LP"     → LP SLS Amt%（LP 分子 / LP 分母，分母 ALLSELECTED 整表同构）
//       - "EOH vs LP" → LP EOH（LP 期末快照日单日时点）
//       渠道上下文与 Act Base Value 完全一致（同列同渠道对比）
// 说明: 仅在 Base Value 总路由的 vs LP 类分支中被调用；
//       Last Period 直接读 Slicer_Time_Frame_Min_Last / Max_Last 筛选器
// 汇率换算: 不在此度量值处理，保持原始 CNY
// ========================================

// ── 渠道路由 ──
VAR __LabelValue = SELECTEDVALUE('Dim_ColMetric_Handbags&Outwear_Sales_ms'[Label_Value], "TTL")
VAR __IsTTL = (__LabelValue = "TTL")

// ── 指标路由（仅 vs LP 类三种 ColType 有效）──
VAR __ColType = SELECTEDVALUE('Dim_ColMetric_Handbags&Outwear_Sales_ms'[ColType])

// ── Last Period 时间区间（区间类基线）──
VAR __PeriodMin_LY = SELECTEDVALUE(Slicer_Time_Frame_Min_Last[TimeFrame_Min])
VAR __PeriodMax_LY = SELECTEDVALUE(Slicer_Time_Frame_Max_Last[TimeFrame_Max])

// ── End Period LP 时间范围（期末时点类基线）──
VAR __EndPeriodMin_LY = SELECTEDVALUE(Slicer_Time_Frame_Max_Last[TimeFrame_Min])
VAR __EndPeriodMax_LY = SELECTEDVALUE(Slicer_Time_Frame_Max_Last[TimeFrame_Max])

// ── LP 期末快照日：end period LP 范围内最后一个有数据的日期 ──
VAR __EndPeriodDate_LP =
    CALCULATE(
        MAX('s02_inventory_stock_sales_detail_d'[dt]),
        REMOVEFILTERS('s02_inventory_stock_sales_detail_d'),
        's02_inventory_stock_sales_detail_d'[dt] >= __EndPeriodMin_LY,
        's02_inventory_stock_sales_detail_d'[dt] <= __EndPeriodMax_LY
    )

// ── 渠道上下文过滤器（构造逻辑同 Act Base Value）──
VAR __ShopNameCtx =
    UNION(
        FILTER(
            ALLSELECTED('s02_trade_sku_data_d'[shop_name]),
            __IsTTL
        ),
        FILTER(
            ALLSELECTED('s02_trade_sku_data_d'[shop_name]),
            (NOT __IsTTL) && 's02_trade_sku_data_d'[shop_name] = __LabelValue
        )
    )

// ═══ LP SLS Amt（Amt vs LP 分母；LP SLS Amt% 分子）═══
VAR __SLSAmt_Last =
    CALCULATE(
        SUM('s02_trade_sku_data_d'[net_sales_amt]),
        __ShopNameCtx,
        's02_trade_sku_data_d'[dt] >= __PeriodMin_LY,
        's02_trade_sku_data_d'[dt] <= __PeriodMax_LY
    )

// ═══ LP SLS Amt%（vs LP 分母；分母 ALLSELECTED 整表，与 This 侧同构）═══
VAR __SLSAmt_Total_LP =
    CALCULATE(
        SUM('s02_trade_sku_data_d'[net_sales_amt]),
        __ShopNameCtx,
        ALLSELECTED('Slicer_Spu_Model'),
        's02_trade_sku_data_d'[dt] >= __PeriodMin_LY,
        's02_trade_sku_data_d'[dt] <= __PeriodMax_LY
    )
VAR __SLSAmtPct_LP = DIVIDE(__SLSAmt_Last, __SLSAmt_Total_LP)

// ═══ LP EOH（EOH vs LP 分母；LP 期末快照日单日时点，行维度 / 品类关系传导同构）═══
VAR __EOHUnit_LP =
    CALCULATE(
        SUM('s02_inventory_stock_sales_detail_d'[stock_inv_qty]),
        's02_inventory_stock_sales_detail_d'[dt] = __EndPeriodDate_LP
    )

RETURN
    SWITCH(
        __ColType,
        "Amt vs LP", __SLSAmt_Last,    // LP SLS Amt（区间汇总）
        "vs LP",     __SLSAmtPct_LP,   // LP SLS Amt%（区间占比）
        "EOH vs LP", __EOHUnit_LP,     // LP EOH（快照日单日）
        BLANK()
    )
```

### 4.3 Handbags & Outwear Sales Base Value（总路由）

```dax
Handbags & Outwear Sales Base Value =
// ========================================
// 度量值: Handbags & Outwear Sales Base Value
// Display Folder: Handbags Sales Performance\Base Metrics
// 用途: 总路由，按 ColType 分发
//       - vs LP 三种派生（Amt vs LP / vs LP / EOH vs LP）→ 分子重路由 + LY 基线派生
//       - 其余 5 种 ColType → 直接取 Act Base Value
//
// vs LP 分子重路由机制（整表 REMOVEFILTERS + 三条件重建）:
//   矩阵列头三层（ChannelGroup > Label > ColName）在视觉对象查询（SUMMARIZECOLUMNS）中
//   以 GroupBy 组合筛选形式存在，REMOVEFILTERS(Dim[ColName]) 单列写法无法从组合筛选中
//   剥离 ColName 部分——ColName（vs LP 类列）筛选残留，与新加的基础 ColType 互斥
//   → Dim 表空集 → 分子始终 BLANK（同坑已在 Merchandising Core KPI / Sales Performance
//   Details 实证沉淀）
//   正确做法：CALCULATE 外先捕获当前列 ChannelGroup / Label_Value 标量值，
//   REMOVEFILTERS(整表) 清除断开维度全部筛选，再以 ChannelGroup + Label_Value +
//   基础 ColType 三条件重建，唯一定位同渠道的基础指标列取分子
//
// 派生口径:
//   Amt vs LP → SLS Amt This / SLS Amt Last - 1（比值，分子分母均原始 CNY，不受币种影响）
//   vs LP     → SLS Amt% This - SLS Amt% Last（差值原始小数，×10000 转 bp 在 Display 层）
//   EOH vs LP → EOH This / EOH LP - 1（双期快照日单日时点值的变化率）
//
// 空值规则: LP 值为空或 0 时比值类返回 BLANK；差值类任一侧为空返回 BLANK
// ========================================
    VAR __ColType = SELECTEDVALUE('Dim_ColMetric_Handbags&Outwear_Sales_ms'[ColType])
    VAR __IsVsLPType =
        __ColType IN {"Amt vs LP", "vs LP", "EOH vs LP"}

    // ── vs LP 分子：当前列渠道上下文下的 This Period 基础指标值 ──
    // 先捕获标量再清筛选：整表 REMOVEFILTERS 后按三条件重建，避免组合筛选残留互斥
    // 基础 ColType 映射：Amt vs LP → SLS Amt；vs LP → SLS Amt%；EOH vs LP → EOH
    VAR __ChannelGroup = SELECTEDVALUE('Dim_ColMetric_Handbags&Outwear_Sales_ms'[ChannelGroup])
    VAR __LabelValue = SELECTEDVALUE('Dim_ColMetric_Handbags&Outwear_Sales_ms'[Label_Value])
    VAR __BaseColType =
        SWITCH(
            __ColType,
            "Amt vs LP", "SLS Amt",
            "vs LP",     "SLS Amt%",
            "EOH vs LP", "EOH"
        )
    VAR __BaseValue_This =
        IF(
            __IsVsLPType,
            CALCULATE(
                [Handbags & Outwear Sales Act Base Value],
                REMOVEFILTERS('Dim_ColMetric_Handbags&Outwear_Sales_ms'),
                'Dim_ColMetric_Handbags&Outwear_Sales_ms'[ChannelGroup] = __ChannelGroup,
                'Dim_ColMetric_Handbags&Outwear_Sales_ms'[Label_Value] = __LabelValue,
                'Dim_ColMetric_Handbags&Outwear_Sales_ms'[ColType] = __BaseColType
            )
        )

    // ── vs LP 分母：当前列渠道上下文下的 Last Period 基线 ──
    VAR __BaseValue_Last =
        IF(
            __IsVsLPType,
            [Handbags & Outwear Sales LY Base Value]
        )

    // ── vs LP 派生 ──
    VAR __vsLPResult =
        SWITCH(
            __ColType,
            // Amt vs LP = This / Last - 1（变化率）
            "Amt vs LP",
                IF(
                    ISBLANK(__BaseValue_Last) || __BaseValue_Last = 0,
                    BLANK(),
                    DIVIDE(__BaseValue_This, __BaseValue_Last) - 1
                ),
            // vs LP = This% - Last%（占比差值，原始小数）
            "vs LP",
                IF(
                    ISBLANK(__BaseValue_This) || ISBLANK(__BaseValue_Last),
                    BLANK(),
                    __BaseValue_This - __BaseValue_Last
                ),
            // EOH vs LP = This / Last - 1（变化率，双期快照日时点值）
            "EOH vs LP",
                IF(
                    ISBLANK(__BaseValue_This) || ISBLANK(__BaseValue_Last) || __BaseValue_Last = 0,
                    BLANK(),
                    __BaseValue_This / __BaseValue_Last - 1
                )
        )

    RETURN
        IF(
            __IsVsLPType,
            __vsLPResult,                            // vs LP 三种派生（TTL 2 列 + 6 店铺各 1 列）
            [Handbags & Outwear Sales Act Base Value]   // 其余 5 种 ColType 直接取 Act
        )
```

### 4.4 Handbags & Outwear Sales Cell Value（对外值，含汇率换算）

```dax
Handbags & Outwear Sales Cell Value =
// ========================================
// 度量值: Handbags & Outwear Sales Cell Value
// Display Folder: Handbags Sales Performance\Base Metrics
// 用途: 对外暴露的单元格值
//       - 金额类（Metric_IsCurrencyAmount = TRUE：SLS Amt）→ 按汇率换算
//       - 其余（数量类 / 比率类 / vs LP 派生）→ 直接返回 Base Value，不换算
// 依赖: [Handbags & Outwear Sales Base Value],
//       'Dim_ColMetric_Handbags&Outwear_Sales_ms'[Metric_IsCurrencyAmount],
//       Slicer_Currency_Selection[Currency_ExchangeRate]
//
// 汇率换算规则:
//   - 数据底表存储 CNY 原始值，USD 时通过 ÷ Currency_ExchangeRate 换算
//   - RMB 时 Currency_ExchangeRate = 1，换算前后值相同
//   - Base Value 层始终保留 CNY 原始值，确保派生计算口径一致；换算集中在展示层，便于管理
// ========================================
    VAR __BaseValue = [Handbags & Outwear Sales Base Value]
    VAR __IsCurrencyAmount = SELECTEDVALUE('Dim_ColMetric_Handbags&Outwear_Sales_ms'[Metric_IsCurrencyAmount], FALSE)
    VAR __ExchangeRate = SELECTEDVALUE(Slicer_Currency_Selection[Currency_ExchangeRate], 1)

    RETURN
        IF(
            ISBLANK(__BaseValue),
            BLANK(),
            IF(
                __IsCurrencyAmount,
                DIVIDE(__BaseValue, __ExchangeRate),   // 金额类: 汇率换算
                __BaseValue                            // 其他: 不换算
            )
        )
```

### 4.5 Handbags & Outwear Sales Cell Display（格式化显示）

```dax
Handbags & Outwear Sales Cell Display =
// ========================================
// 度量值: Handbags & Outwear Sales Cell Display
// Display Folder: Handbags Sales Performance\Formatting
// 用途: 按 Metric_Format 单字段格式化显示
// 依赖: [Handbags & Outwear Sales Cell Value],
//       'Dim_ColMetric_Handbags&Outwear_Sales_ms'[Metric_Format],
//       Slicer_Currency_Selection[Currency_Symbol]
//
// 格式类型（口径文档 §43-§47 已定义，一切以口径文档为准）:
//   integer     → FORMAT(__Value, "#,##0") 整数千分位（SLS Unit / EOH）
//   currency    → __CurrencySymbol & FORMAT(__Value, "#,##0")（SLS Amt，符号由币种切片器决定）
//   percent_0dp → FORMAT(__Value, "#,##0%") 百分比整数，不含正号（SLS Amt% / ST% /
//                 Amt vs LP / EOH vs LP）
//   integer_bp  → FORMAT(__Value * 10000, "#,##0") & "bp"（vs LP，占比差值 ×10000 转 bp，
//                 负数自带负号，零值 0bp）
// 扩展格式（口径文档未定义，按参考方案 Sales_Performance_Details_ms 保留，
// 当前无列使用，便于后续快速调整）:
//   currency_M_K_Int_0db → 金额类 M/K 缩写（¥999 / ¥1.5K / ¥1.5M）
//   integer_M_K_Int_0db  → 数量类 M/K 缩写（999 / 1.5K / 1.5M）
//   percent_1dp          → 百分比 1 位小数（26.5%）
//   delta_pct_1dp        → 百分比 1 位小数变化，含正号（+14.5%）
//   decimal_1dp          → 1 位小数千分位（203.5）
//
// BLANK 规则（本模块特有）: BLANK 一律返回 BLANK()（不返回 "-"）——
//   矩阵检测到该行全部度量值均为 BLANK() 时自动隐藏该行（含层级行，需所有指标均为
//   BLANK()），行可见性由矩阵原生机制承担，无需 IsEmpty 视觉级筛选器
// ========================================
    VAR __Value = [Handbags & Outwear Sales Cell Value]
    VAR __Format = SELECTEDVALUE('Dim_ColMetric_Handbags&Outwear_Sales_ms'[Metric_Format])
    VAR __CurrencySymbol = SELECTEDVALUE(Slicer_Currency_Selection[Currency_Symbol], "¥")

    RETURN
        IF(
            ISBLANK(__Value),
            "-", 
            SWITCH(
                __Format,
                // ─── 金额类（货币符号 + 千分位整数）───
                "currency",
                    __CurrencySymbol & FORMAT(__Value, "#,##0"),         // ¥640,299
                // ─── 整数千分位（数量类）───
                "integer",
                    FORMAT(__Value, "#,##0"),                            // 3,160
                // ─── 百分比整数，不含正号（占比 / 售罄率 / 变化率）───
                "percent_0dp",
                    FORMAT(__Value, "#,##0%"),                           // 26% / -3%
                // ─── bp 指标（占比差值 ×10000 转 bp）───
                "integer_bp",
                    FORMAT(__Value * 10000, "#,##0") & "bp",             // -152bp / 0bp
                // ─── 扩展格式（便于后续快速调整）───
                "currency_M_K_Int_0db",
                    IF(
                        __Value < 1000,
                        __CurrencySymbol & FORMAT(__Value, "#,##0"),     // ¥999
                        IF(
                            __Value < 1000000,
                            __CurrencySymbol & FORMAT(__Value / 1000, "#,##0.0") & "K",   // ¥1.5K
                            __CurrencySymbol & FORMAT(__Value / 1000000, "#,##0.0") & "M" // ¥1.5M
                        )
                    ),
                "integer_M_K_Int_0db",
                    IF(
                        __Value < 1000,
                        FORMAT(__Value, "#,##0"),                        // 999
                        IF(
                            __Value < 1000000,
                            FORMAT(__Value / 1000, "#,##0.0") & "K",     // 1.5K
                            FORMAT(__Value / 1000000, "#,##0.0") & "M"   // 1.5M
                        )
                    ),
                "percent_1dp",
                    FORMAT(__Value, "#,##0.0%"),                         // 26.5%
                "delta_pct_1dp",
                    IF(__Value > 0, "+", "") & FORMAT(__Value, "#,##0.0%"),  // +14.5%
                "decimal_1dp",
                    FORMAT(__Value, "#,##0.0"),                          // 203.5
                // ─── 默认 ─────────────────────────────
                FORMAT(__Value, "#,##0.00")
            )
        )
```

### 4.6 Handbags & Outwear Sales Cell Font Color（字体颜色）

```dax
Handbags & Outwear Sales Cell Font Color =
// ========================================
// 度量值: Handbags & Outwear Sales Cell Font Color
// Display Folder: Handbags Sales Performance\Formatting
// 用途: 按 Metric_ColorRule 字段分发字体颜色
// 依赖: [Handbags & Outwear Sales Cell Value],
//       'Dim_ColMetric_Handbags&Outwear_Sales_ms'[Metric_ColorRule,
//        Metric_ColorPositive / Negative / Zero / Default]
//
// 颜色规则:
//   1. 全部基础指标列（SLS Unit / SLS Amt / SLS Amt% / ST% / EOH）固定 #252423 → "fixed_black"
//   2. vs LP 类（Amt vs LP / vs LP / EOH vs LP，比率为正/负/零三色）→ "pos_neg_zero"
// ========================================
    VAR __Value = [Handbags & Outwear Sales Cell Value]
    VAR __ColorRule = SELECTEDVALUE('Dim_ColMetric_Handbags&Outwear_Sales_ms'[Metric_ColorRule], "fixed_default")
    VAR __ColorPositive = SELECTEDVALUE('Dim_ColMetric_Handbags&Outwear_Sales_ms'[Metric_ColorPositive], "#1A9018")
    VAR __ColorNegative = SELECTEDVALUE('Dim_ColMetric_Handbags&Outwear_Sales_ms'[Metric_ColorNegative], "#D64550")
    VAR __ColorZero = SELECTEDVALUE('Dim_ColMetric_Handbags&Outwear_Sales_ms'[Metric_ColorZero], "#E1C233")
    VAR __ColorDefault = SELECTEDVALUE('Dim_ColMetric_Handbags&Outwear_Sales_ms'[Metric_ColorDefault], "#5F6165")

    RETURN
        SWITCH(
            __ColorRule,
            "fixed_black",   "#252423",
            "pos_neg_zero",
                SWITCH(
                    TRUE(),
                    ISBLANK(__Value), __ColorDefault,
                    __Value > 0,      __ColorPositive,
                    __Value < 0,      __ColorNegative,
                    __Value = 0,      __ColorZero,
                    __ColorDefault
                ),
            "fixed_default", __ColorDefault,
            __ColorDefault
        )
```

### 4.7 Handbags & Outwear Sales Cell Background Color（背景色）

```dax
Handbags & Outwear Sales Cell Background Color =
// ========================================
// 度量值: Handbags & Outwear Sales Cell Background Color
// Display Folder: Handbags Sales Performance\Formatting
// 用途: 区分 ColName 层（指标列）与上层（Label / ChannelGroup）的背景色
// 依赖: ISINSCOPE('Dim_ColMetric_Handbags&Outwear_Sales_ms'[ColName])
// ========================================
    VAR __IsMetricCol = ISINSCOPE('Dim_ColMetric_Handbags&Outwear_Sales_ms'[ColName])
    RETURN
        IF(
            __IsMetricCol,
            "#FFFFFF",   // ColName 层（指标列）: 白色
            "#E6D9C7"    // Label / ChannelGroup 层: 中米色
        )
```

---

## 5. 度量值清单与 Display Folder

| 序号 | 度量值名称 | Display Folder | 用途 |
| ---- | ---------- | -------------- | ---- |
| 1 | Handbags & Outwear Sales Act Base Value | Base Metrics | This Period 基础值（5 种基础 ColType）；渠道上下文 + ColType 路由；CNY 原值 |
| 2 | Handbags & Outwear Sales LY Base Value | Base Metrics | Last Period 基线（按 vs LP 类 ColType 路由：LP SLS Amt / LP SLS Amt% / LP EOH） |
| 3 | Handbags & Outwear Sales Base Value | Base Metrics | 总路由（vs LP 三种派生 + 整表 REMOVEFILTERS + 三条件重路由；其余直接取 Act）；31 列全覆盖 |
| 4 | Handbags & Outwear Sales Cell Value | Base Metrics | 对外值：金额类（SLS Amt）汇率换算（÷ Currency_ExchangeRate） |
| 5 | Handbags & Outwear Sales Cell Display | Formatting | 格式化显示文本（integer / currency / percent_0dp / integer_bp + 5 种扩展格式）；BLANK 返回 BLANK() |
| 6 | Handbags & Outwear Sales Cell Font Color | Formatting | 字体颜色（基础指标 = fixed_black；vs LP 类 = pos_neg_zero 三色） |
| 7 | Handbags & Outwear Sales Cell Background Color | Formatting | 背景色（ColName 层 #FFFFFF vs 上层 #E6D9C7） |

- 全部度量值存放于 `_Measures` 隐藏表；Display Folder：`Handbags Sales Performance\Base Metrics`（1-4）、`Handbags Sales Performance\Formatting`（5-7）
- 无 LP 中间度量值拆分——LY 基线统一收敛在 LY Base Value 单度量值内按 ColType 路由（区别于 Handbags_Sales_ms 的多 LP 中间度量值模式）

---

## 6. 血缘关系图

```
┌─────────────────────────────────────────────────────────────────────┐
│                        数据源层                                      │
│  s02_trade_sku_data_d（销售类，SKU 粒度，dt 日粒度）                 │
│  字段: dt, shop_name, category, spu_model,                          │
│        product_qty, net_sales_amt（PQ 行级列）                       │
│  s02_inventory_stock_sales_detail_d（库存类，SKU 模型，dt 日快照）  │
│  字段: dt, category, spu_model,                                     │
│        stock_inv_qty, msrp_inv_amt（无渠道字段）                     │
└─────────────────────────────────────────────────────────────────────┘
        │ Slicer_Spu_Model（行，1:N × 2 自动传导）    │ Slicer_Spu_Model（行，1:N × 2 自动传导）
        │ Slicer_Category（前置筛选，1:N × 2 传导）   │ Slicer_Category（前置筛选，1:N × 2 传导）
        ▼                                              ▼
┌─────────────────────────────────────────────────────────────────────┐
│                        度量值层                                      │
│                                                                     │
│  ┌───────────────────────────┐   ┌───────────────────────────┐      │
│  │ Handbags & Outwear Sales  │   │ Handbags & Outwear Sales  │      │
│  │ Act Base Value            │   │ LY Base Value             │      │
│  │ (This Period + This 快照) │   │ (Last Period + LP 快照)   │      │
│  └────────────┬──────────────┘   └────────────┬──────────────┘      │
│               │      ┌──────────────────────────────┐               │
│               │◄─────│ Dim_ColMetric_Handbags&      │               │
│               │      │ Outwear_Sales_ms             │               │
│               │      │ (ChannelGroup/Label/         │               │
│               │      │  Label_Value/ColType)        │               │
│               │      ├──────────────────────────────┤               │
│               │◄─────│ Slicer_Time_Frame_Min/Max_   │               │
│               │      │ This / Min/Max_Last          │               │
│               │      └──────────────────────────────┘               │
│               ▼                                                     │
│  ┌──────────────────────────────────────────────────────┐           │
│  │ Handbags & Outwear Sales Base Value                  │           │
│  │ (总路由: vs LP 三种派生 = 分子重路由 + LY 基线；       │           │
│  │  整表 REMOVEFILTERS + ChannelGroup + Label_Value +    │           │
│  │  基础 ColType 三条件重建取分子；其余 5 种直接取 Act)   │           │
│  └───────────────────────┬──────────────────────────────┘           │
│                          ▼                                          │
│  ┌──────────────────────────────────────────────────────┐           │
│  │ Handbags & Outwear Sales Cell Value                  │           │
│  │ (金额类汇率换算 ÷ Currency_ExchangeRate)              │           │
│  │          ▲ Slicer_Currency_Selection                 │           │
│  └───────────────────────┬──────────────────────────────┘           │
│                          ▼                                          │
│  ┌──────────────────────────────────────────────────────┐           │
│  │ Handbags & Outwear Sales Cell Display                │           │
│  │ (按 Metric_Format 格式化 + Currency_Symbol 拼接；     │           │
│  │  BLANK 返回 BLANK()，矩阵自动隐藏全空行)              │           │
│  └───────────────────────┬──────────────────────────────┘           │
│                          ▼                                          │
│  ┌──────────────────────────────────────────────────────┐           │
│  │ Cell Font Color / Cell Background Color               │           │
│  └──────────────────────────────────────────────────────┘           │
└─────────────────────────────────────────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────────┐
│                        可视化层（矩阵）                              │
│  行: Slicer_Spu_Model[spu_model]（按 sort_order 排序）               │
│  列: 'Dim_ColMetric_Handbags&Outwear_Sales_ms'[ChannelGroup]        │
│      > [Label] > [ColName]（ChannelGroup_Sort / Label_Sort /        │
│      ColName_Sort 排序）                                             │
│  值: [Handbags & Outwear Sales Cell Display]                        │
│  视觉对象筛选器: Slicer_Category[category] IN ("Handbags","Outerwear") │
│  条件格式: 字体颜色 → Cell Font Color；背景色 → Cell Background     │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 7. 注意事项

1. **表名与度量值名含 "&" 字符**：`Dim_ColMetric_Handbags&Outwear_Sales_ms` 及 `Handbags & Outwear Sales ...` 系列度量值在 DAX 中引用必须加单引号，例如 `'Dim_ColMetric_Handbags&Outwear_Sales_ms'[ColType]`。
2. **行维度双表关系传导（建模前提）**：行维度为 Slicer_Spu_Model[spu_model]，需与 s02_trade_sku_data_d、s02_inventory_stock_sales_detail_d **均建立一对多关系（共享维度模式）**——行筛选自动传导到两张事实表，全部指标（trade 侧 + inv 侧）无需任何显式行维度传递 DAX；若模型中 Slicer_Spu_Model 未与 inv 表建关系，inv 侧指标需回退 TREATAS 桥接（`TREATAS(VALUES('s02_trade_sku_data_d'[spu_model]), 's02_inventory_stock_sales_detail_d'[spu_model])`，参考 Sales Performance Details 注意事项 2 的共享维度替代方案）。
3. **SLS Amt% 分母必须 ALLSELECTED 整表**：Slicer_Spu_Model 含 sort_order 排序字段，spu_model 通过"按列排序（Sort by Column）"绑定 sort_order——矩阵行按 spu_model 分组时查询会同时按 spu_model + sort_order 组合分组，`ALLSELECTED('Slicer_Spu_Model'[spu_model])` 单列写法无法剥离 sort_order 部分的组合筛选（行维度筛选残留 → 分母恒等于分子 → 占比恒 100%）；必须使用 `ALLSELECTED('Slicer_Spu_Model')` 整表写法恢复整表外部筛选状态。不使用 REMOVEFILTERS——其会移除列上全部筛选器（含外部显式筛选），前置筛选直接配置于 trade[category] 列的场景下会误删。
4. **vs LP 分子重路由必须整表 REMOVEFILTERS**：矩阵列头三层在视觉对象查询（SUMMARIZECOLUMNS）中以 GroupBy 组合筛选形式存在，`REMOVEFILTERS(Dim[ColName])` 单列写法无法剥离 ColName 部分，残留的 vs LP 类列筛选与新加的基础 ColType 互斥 → Dim 表空集 → 分子始终 BLANK；正确模式 = CALCULATE 外捕获 ChannelGroup / Label_Value 标量 + `REMOVEFILTERS(整表)` + 三条件重建（ChannelGroup + Label_Value + 基础 ColType 唯一定位单行）。ChannelGroup / Label 层汇总单元格无唯一 ColType → BLANK → Display 返回 BLANK()。
5. **前置品类关系传导（建模前提）与总计行语义**：行维度经 Slicer_Spu_Model → trade / inv、品类经 Slicer_Category → trade / inv 双侧一对多关系自动传导，度量值内零行维度 / 品类硬编码（无 TREATAS、无 IN 清单）——后续品类 / 行维度调整仅需修改视觉对象筛选器与维度表配置；若模型中 Slicer_Category 未与 inv 建关系，需在 inv 侧 3 处聚合（__EOHUnit / __InvAmt_End / __EOHUnit_LP）回退显式条件 `inv[category] IN {...}`。总计行无 spu_model 行分组，trade / inv 两侧均为品类全量——行值域 Slicer_Spu_Model 仅 3 个 model，品类下其余 model 计入总计但不展示明细行（总计 ≠ 明细行之和）；业务若需总计 = 展示行之和，关闭矩阵总计行即可。
6. **inv 表无渠道字段**：s02_inventory_stock_sales_detail_d 无 shop_name / platform，渠道上下文不作用于 inv 侧——EOH / EOH vs LP / ST% 库存侧不受渠道列影响；三者仅存在于 TTL 列（无跨渠道列对比问题），ST% 分子分母渠道口径不对称为模型物理限制，业务需知悉。
7. **Display 层 BLANK 返回 BLANK()（本模块特有）**：不返回 "-"——矩阵检测到该行全部度量值均为 BLANK() 时自动隐藏该行（含层级行，需所有指标均为 BLANK()），行可见性由矩阵原生机制承担，无需 IsEmpty 视觉级筛选器；代价是单元格级空值与行级隐藏不可区分（业务已确认接受）。
8. **期末时点口径**：This / LP 两个快照日各自取对应范围内最后一个有数据的日期（快照缺数自动回退）；快照表按日存储只取单日，对整段区间求和会重复计数库存；`__EndPeriodDate` / `__EndPeriodDate_LP` 用 REMOVEFILTERS(inv 整表) 取值，保证快照日不随行维度 / 切片器上下文漂移。
9. **net_sales_amt 列来源**：模型内为 Power Query 行级计算列（ROUND(product_qty × sales_price, 6)），数据库无此列——测试 SQL 验证时按行级乘积还原，不可直接引用数据库 net_sales_amt（若底表存在同名字段以取数 SQL 为准核对）。
10. **vs LP 空值规则**：Amt vs LP / EOH vs LP 在 LP 侧 BLANK 或 0 时返回 BLANK（避免除零与失真变化率；EOH vs LP 另在 this 侧 BLANK 时返回 BLANK）；vs LP（bp 差值）任一侧 BLANK 返回 BLANK（避免单侧缺失产生失真差值）；×10000 转 bp 在 Display 层实现，Value 层保持原始差值小数。
11. **'Outwear' 笔误已确认**：口径文档子模块十的 'Outwear' 为笔误，底表实际值为 'Outerwear'；前置筛选由视觉对象筛选器（Slicer_Category[category] IN ("Handbags", "Outerwear")）承担，经双侧关系传导生效，度量值内无品类硬编码。
12. **汇率换算分层**：Base Value 层始终保留 CNY 原始值（vs LP 派生计算口径一致）；换算集中在 Cell Value（÷ Currency_ExchangeRate，RMB 时汇率 = 1）；Cell Display 只拼接 Currency_Symbol。金额类判定用 Metric_IsCurrencyAmount；Amt vs LP / vs LP / EOH vs LP 为派生比率，分子分母同币种不换算。
13. **渠道上下文过滤器构造**：`__ShopNameCtx` 用 UNION+FILTER 构造（IF 分支返回表表达式会被降级为标量，禁用——项目内已两次实证），作为 CALCULATE 表过滤器统一传入所有 trade 侧聚合；TTL = ALLSELECTED（外部筛选上下文下的全店铺合计），非 TTL = Label_Value 精确匹配（与外部店铺切片器取交集，外部仅选 TM 时 JD 列返回空）。
14. **口径与语法**：口径文档中定义的所有指标必须遵守其数据类型与数据格式（percent_0dp 不含正号、integer_bp ×10000 转 bp、currency 币种符号 + 千分位整数），与解决方案存在争议时一切以口径文档为准；DAX 文本常量使用双引号，单引号仅用于表名，列名使用方括号，例如：`[category] IN {"Handbags", "Outerwear"}`。
15. **测试 SQL**：test_Handbags_&_Outwear_ms.sql（本目录，MySQL 8.0+，字面量直嵌不支持变量，两段独立执行）——段 1 TTL 7 指标（行 = spu_model）、段 2 六店铺 4 指标（行 = Store × spu_model，Store 列区分）；NULL 语义逐项对齐 DAX（占比分子 NULL 输出 0 / Amt vs LP 的 this NULL 按 0 处理 / ST% 单侧 NULL 按 0 / vs LP 输出原始差值小数，×10000 转 bp 在 Display 层）；参数区见文件头注释（This / Last Period 区间与双期快照日，修改时全文替换）。
