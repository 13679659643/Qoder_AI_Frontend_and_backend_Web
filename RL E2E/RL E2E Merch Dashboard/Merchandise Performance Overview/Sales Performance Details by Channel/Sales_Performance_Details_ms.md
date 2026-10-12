# Sales Performance Details by Channel 矩阵解决方案

> **版本**: v1.0
> **模块**: RL E2E Merch Dashboard - Merchandise Performance Overview Tab - Sales Performance Details by Channel
> **关联口径**: 口径文档/口径Markdown格式/Merchandise Performance Overview.md - 子模块六：Sales Performance Details by Channel（§33-§41）
> **数据底表（销售类）**: a02_e2e_product_performance_sales_summary_d
> **数据底表（库存类）**: a02_e2e_product_performance_inv_summary_d
> **关联维度**: Dim_ColMetric_Sales_Performance_Details（列，三层 ChannelGroup > Label > ColName）、Slicer_Time_Frame_Min_This / Max_This / Min_Last / Max_Last（时间）、Slicer_Currency_Selection（币种）

---

## 1. 需求理解

### 1.1 模块定位

Sales Performance Details by Channel 是按渠道展开的销售明细矩阵：

- **列**：三层结构 ChannelGroup（Platform / Store）> Label（页面显示标签）> ColName（指标列），共 74 列
  - Platform 组：TTL（7 列）+ Tmall / JD / RLE / DY（各 6 列）
  - Store 组：TTL（7 列）+ Tmall / JD / RLE / DY_Family / DY_W / DY_MN（各 6 列）
  - TTL 列组合：SLS Unit、SLS Amt、YOY、SLS Amt%、LTD ST%、EOH Unit、AUR
  - 非 TTL 列组合：SLS Unit、SLS Amt、YOY、Vert. Amt%、Horiz. Amt%、AUR
- **行**：商品维度字段六选一拉到矩阵（`brand` / `super_season` / `product_type` / `category` / `md_type` / `division`，均取自 sales 表）

### 1.2 路由维度

| 路由维度 | 来源                                                                  | 类型       | 说明                                                                                                        |
| -------- | --------------------------------------------------------------------- | ---------- | ----------------------------------------------------------------------------------------------------------- |
| 渠道     | Dim_ColMetric_Sales_Performance_Details 的 ChannelGroup + Label_Value | 断开列维度 | Platform 组过滤事实表 [platform]，Store 组过滤 [shop_name]；Label_Value = "TTL" 时走 ALLSELECTED 全渠道合计 |
| 指标     | Dim_ColMetric_Sales_Performance_Details 的 ColType                    | 断开列维度 | 9 种：SLS Unit / SLS Amt / YOY / SLS Amt% / Vert. Amt% / Horiz. Amt% / LTD ST% / EOH Unit / AUR             |
| 行维度   | sales 表商品维度字段六选一                                            | 事实表字段 | 一次只使用一个字段；占比分母类别总计用 ALLSELECTED 移除该行维度筛选                                         |

**Label → 事实表实际值映射**（已核对 Slicer_Platform_Selection / Slicer_Store_Name）：

| ChannelGroup | Label                                       | Label_Value                                | 说明                                                                   |
| ------------ | ------------------------------------------- | ------------------------------------------ | ---------------------------------------------------------------------- |
| Platform     | TTL                                         | TTL（特殊标记）                            | ALLSELECTED 移除视觉对象内部 platform / shop_name 筛选，保留外部切片器 |
| Platform     | Tmall / JD / RLE / DY                       | TM / JD / RLE / DY                         | 过滤 [platform]                                                        |
| Store        | TTL                                         | TTL（特殊标记）                            | 同上，全店铺合计                                                       |
| Store        | Tmall / JD / RLE / DY_Family / DY_W / DY_MN | TM / JD / RLE_CN / DY_Family / DY_W / DY_M | 过滤 [shop_name]                                                       |

**TTL 特殊处理**：度量值中对 [platform] / [shop_name] 应用 ALLSELECTED——移除视觉对象内部的渠道筛选，保留外部切片器（Slicer_Platform_Selection / Slicer_Store_Name 等）的筛选，即 TTL = 外部筛选上下文下的全渠道合计。

**占比分母类别总计**：分母需要移除视觉对象内部的行维度筛选、保留外部切片器。由于行维度六字段一次只用一个，度量值中同时 ALLSELECTED 这六个字段（其余未上行的字段 ALLSELECTED 为无操作），实现对所有商品维度的统计。

### 1.3 时间口径

| 口径                     | 时间范围                                                                                                                          | 适用指标                                                            |
| ------------------------ | --------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------- |
| This Period（区间类）    | data_date ∈ [Slicer_Time_Frame_Min_This[TimeFrame_Min], Slicer_Time_Frame_Max_This[TimeFrame_Max]]                               | SLS Unit、SLS Amt、YOY 分子、SLS Amt%、Vert. Amt%、Horiz. Amt%、AUR |
| Last Period（YOY 基线）  | data_date ∈ [Slicer_Time_Frame_Min_Last[TimeFrame_Min], Slicer_Time_Frame_Max_Last[TimeFrame_Max]]                               | YOY 分母                                                            |
| End Period（期末时点类） | end period 范围 [Slicer_Time_Frame_Max_This[TimeFrame_Min], Slicer_Time_Frame_Max_This[TimeFrame_Max]] 内**最后一个快照日** | EOH Unit、LTD ST% 分母库存                                          |
| LTD 区间                 | data_date ∈ [2024-01-01（口径待定）, This Period end]                                                                            | LTD ST% 分子销售                                                    |

说明：

- YOY 是 this period 和 last period 对比，受 last period 时间筛选器影响
- LTD ST% 销售区间为 2024 年起算至所选 end period（原始口径标注「待定」），起算日以度量值内变量 `__LTDStartDate` 承载，确认后改一处即可
- 期末时点类实现为 end period 范围内最后一个有数据的快照日：口径为 end period 最后一天，快照缺数时自动回退到范围内最近一天；快照表按日存储只取单日，整段区间求和会重复计数库存

---

## 2. 现状分析

- 数据底表 `a02_e2e_product_performance_sales_summary_d`（日粒度）：net_sales_amt / net_sales_qty 及全部商品维度字段（brand、super_season、product_type、category、md_type、division、framework、ax_class、category_summary、special_supply、predictive_buy、computed_product_tag）+ platform / shop_name 渠道字段；platform 已在数据源层过滤 IN ('JD','TM','RLE','DY')
- 数据底表 `a02_e2e_product_performance_inv_summary_d`（日快照）：msrp_inv_amt / inv_qty，商品维度字段与 sales 表同名同构；**无 platform / shop_name 字段**，渠道筛选不影响库存侧
- 商品维度字段为 `brand`（品牌标签：W Polo、FJ、CL、PL、CW、M Polo、RRL、HM、Lauren；数据字典已由 label 统一更新为 brand），口径中的 "Label / Brand" 维度即该字段，本方案按 `brand` 实现
- 列维度表 `Dim_ColMetric_Sales_Performance_Details` 已存在（本目录），含 ChannelGroup / Label / Label_Value / ColName / ColType / Metric_Format / Metric_IsCurrencyAmount / 颜色字段
- 行维度六个字段取自 sales 表；inv 侧指标（EOH Unit、LTD ST% 分母）通过 TREATAS 将 sales 侧行维度筛选传递到 inv 表
- Slicer_Platform_Selection、Slicer_Store_Name、Slicer_AX_Class 等筛选器与事实表一对多关联，筛选自动传递，DAX 无需显式处理
- 字段名已逐一核对数据字典

---

## 3. 方案设计

### 3.1 度量值分层

```
Act Base Value / LY Base Value
    ←  渠道上下文路由（ChannelGroup + Label_Value，TTL 走 ALLSELECTED）
       + ColType 指标路由 + 行维度自然筛选，保留 RMB 原始值
    ↓
Base Value（总路由）
    ←  YOY = SLS Amt This / SLS Amt Last - 1（REMOVEFILTERS(ColName) 重路由取分子）
       其余 8 种 ColType 直接取 Act Base Value
    ↓
Cell Value
    ←  金额类（Metric_IsCurrencyAmount = TRUE）汇率换算（÷ Currency_ExchangeRate）
    ↓
Cell Display
    ←  按 Metric_Format 格式化（integer / currency / delta_pct_0dp / percent_0dp）
    ↓
Cell Font Color / Cell Background Color
    ←  按 Metric_ColorRule 调度颜色 / ColName 层与上层背景区分
```

### 3.2 渠道上下文构造（度量值内统一模式）

| 列位置            | platform 上下文                                           | shop_name 上下文                                |
| ----------------- | --------------------------------------------------------- | ----------------------------------------------- |
| TTL（两组）       | ALLSELECTED([platform])：移除视觉内部筛选，保留外部切片器 | ALLSELECTED([shop_name])：同左                  |
| Platform 组非 TTL | [platform] = Label_Value（与外部切片器取交集）            | ALLSELECTED([shop_name])（外部切片器自然生效）  |
| Store 组非 TTL    | ALLSELECTED([platform])（外部切片器自然生效）             | [shop_name] = Label_Value（与外部切片器取交集） |

实现为两个表变量 `__PlatformCtx` / `__ShopNameCtx`（UNION+FILTER 构造，保证表类型稳定），作为 CALCULATE 过滤器统一传入所有 sales 侧聚合。

### 3.3 指标口径（ColType 路由）

| ColType     | 数据底表    | 时间口径            | 公式                                                                                           | 格式          |
| ----------- | ----------- | ------------------- | ---------------------------------------------------------------------------------------------- | ------------- |
| SLS Unit    | sales       | This Period 区间    | sum(net_sales_qty)                                                                             | integer       |
| SLS Amt     | sales       | This Period 区间    | sum(net_sales_amt)                                                                             | currency      |
| YOY         | sales       | This / Last 区间    | SLS Amt This / SLS Amt Last - 1                                                                | delta_pct_0dp |
| SLS Amt%    | sales       | This Period 区间    | 单元格 SLS Amt / 该列渠道全部商品维度合计                                                      | percent_0dp   |
| Vert. Amt%  | sales       | This Period 区间    | 单元格 SLS Amt / 该列渠道全部商品维度合计（与 SLS Amt% 公式结构相同，渠道上下文为对应 Label）  | percent_0dp   |
| Horiz. Amt% | sales       | This Period 区间    | 单元格 SLS Amt / 该行商品维度全渠道合计                                                        | percent_0dp   |
| LTD ST%     | sales + inv | LTD 区间 / 期末快照 | LTD 销售金额 /（LTD 销售金额 + 期末库存金额）                                                  | percent_0dp   |
| EOH Unit    | inv         | 期末快照单日        | sum(inv_qty)（口径 §40 原文写作 sum(msrp_inv_amt)，按「数量」定义实现为 inv_qty，需业务确认） | integer       |
| AUR         | sales       | This Period 区间    | sum(net_sales_amt) / sum(net_sales_qty)                                                        | currency      |

### 3.4 占比指标分子分母

| 指标                     | 分子                                                | 分母                                                                              |
| ------------------------ | --------------------------------------------------- | --------------------------------------------------------------------------------- |
| SLS Amt%（TTL 列）       | 当前单元格 SLS Amt（TTL 渠道上下文 + 当前行商品）   | TTL 渠道上下文 + ALLSELECTED 六商品字段（全部行合计）                             |
| Vert. Amt%（非 TTL 列）  | 当前单元格 SLS Amt（Label_Value 渠道 + 当前行商品） | 同渠道上下文 + ALLSELECTED 六商品字段（该渠道列全部行合计）                       |
| Horiz. Amt%（非 TTL 列） | 当前单元格 SLS Amt（Label_Value 渠道 + 当前行商品） | 当前行商品 + ALLSELECTED([platform]) + ALLSELECTED([shop_name])（该行全渠道合计） |

ALLSELECTED 六商品字段：`brand` / `super_season` / `product_type` / `category` / `md_type` / `division` 同时 ALLSELECTED——一次只有一个字段在矩阵行上，其余字段为无操作；移除视觉对象内部的行维度筛选，保留外部切片器。

### 3.5 inv 侧行维度筛选传递

EOH Unit 与 LTD ST% 分母取数 inv 表，行维度字段在 sales 表上，通过 TREATAS 传递：
`TREATAS(VALUES(sales[字段]), inv[字段])` × 六字段——上行字段传递行筛选，未上行字段传递外部切片器上下文（或全量无操作）。inv 表无渠道字段，渠道上下文不作用于 inv 侧。
说明：sales 与 inv 为两张独立事实表，筛选只沿模型关系传递，同名字段之间不会自动传递（且两表之间最多一条活动关系，无法覆盖六个可切换行维度），故 inv 侧需显式传递；共享维度替代方案见注意事项 2。

---

## 4. 度量值实现

### 4.1 Sales Performance Details Act Base Value（This Period 基础值）

```dax
Sales Performance Details Act Base Value =
// ========================================
// 度量值: Sales Performance Details Act Base Value
// Display Folder: Base Metrics
// 用途: This Period 基础值，按渠道上下文（ChannelGroup + Label_Value）+ ColType 路由，
//       覆盖 8 种基础指标列（SLS Unit / SLS Amt / SLS Amt% / Vert. Amt% / Horiz. Amt% /
//       LTD ST% / EOH Unit / AUR），保留 RMB 原始值
//       YOY 为跨期派生指标，在 Base Value 总路由中处理，本度量值不涉及
// 依赖: 'Dim_ColMetric_Sales_Performance_Details'[ChannelGroup, Label_Value, ColType]
//       Slicer_Time_Frame_Min_This[TimeFrame_Min] / Slicer_Time_Frame_Max_This[TimeFrame_Max]
// 数据底表: a02_e2e_product_performance_sales_summary_d（销售类）
//           a02_e2e_product_performance_inv_summary_d（库存类：EOH Unit / LTD ST% 分母）
// 汇率换算: 不在此度量值处理，保持原始 RMB，由 Cell Value 层统一换算
// ========================================

// ── 渠道路由 ──
VAR __ChannelGroup = SELECTEDVALUE('Dim_ColMetric_Sales_Performance_Details'[ChannelGroup], "Platform")
VAR __LabelValue = SELECTEDVALUE('Dim_ColMetric_Sales_Performance_Details'[Label_Value], "TTL")
VAR __IsTTL = (__LabelValue = "TTL")

// ── 指标路由 ──
VAR __ColType = SELECTEDVALUE('Dim_ColMetric_Sales_Performance_Details'[ColType])

// ── This Period 时间区间（区间类指标）──
VAR __PeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Min_This[TimeFrame_Min])
VAR __PeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

// ── End Period 时间范围（期末时点类指标）──
VAR __EndPeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Min])
VAR __EndPeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

// ── LTD 起算日（口径待定项：原始口径标注 2024-01-01 待定，确认后仅调整此处）──
VAR __LTDStartDate = DATE(2024, 1, 1)

// ── 期末快照日：end period 范围内最后一个有数据的日期 ──
// REMOVEFILTERS 保证快照日不随行维度 / 商品切片器上下文漂移（全表最后一个快照日）
VAR __EndPeriodDate =
    CALCULATE(
        MAX('a02_e2e_product_performance_inv_summary_d'[data_date]),
        REMOVEFILTERS('a02_e2e_product_performance_inv_summary_d'),
        'a02_e2e_product_performance_inv_summary_d'[data_date] >= __EndPeriodMin,
        'a02_e2e_product_performance_inv_summary_d'[data_date] <= __EndPeriodMax
    )

// ── 渠道上下文过滤器（platform 侧；UNION+FILTER 保证表类型稳定）──
//   TTL 列      → ALLSELECTED([platform])：移除视觉对象内部 platform 筛选，保留外部切片器
//   Platform 列 → [platform] = Label_Value（基于 ALLSELECTED 集，与外部切片器取交集）
//   Store 列    → 不限定 platform（ALLSELECTED 集，外部切片器自然生效）
VAR __PlatformCtx =
    UNION(
        FILTER(
            ALLSELECTED('a02_e2e_product_performance_sales_summary_d'[platform]),
            __IsTTL
        ),
        FILTER(
            ALLSELECTED('a02_e2e_product_performance_sales_summary_d'[platform]),
            (NOT __IsTTL) && __ChannelGroup = "Store"
        ),
        FILTER(
            ALLSELECTED('a02_e2e_product_performance_sales_summary_d'[platform]),
            (NOT __IsTTL) && __ChannelGroup = "Platform"
                && 'a02_e2e_product_performance_sales_summary_d'[platform] = __LabelValue
        )
    )

// ── 渠道上下文过滤器（shop_name 侧）──
//   TTL 列   → ALLSELECTED([shop_name])：移除视觉对象内部 shop_name 筛选，保留外部切片器
//   Store 列 → [shop_name] = Label_Value（基于 ALLSELECTED 集，与外部切片器取交集）
//   Platform 列 → 不限定 shop_name（ALLSELECTED 集，外部切片器自然生效）
VAR __ShopNameCtx =
    UNION(
        FILTER(
            ALLSELECTED('a02_e2e_product_performance_sales_summary_d'[shop_name]),
            __IsTTL
        ),
        FILTER(
            ALLSELECTED('a02_e2e_product_performance_sales_summary_d'[shop_name]),
            (NOT __IsTTL) && __ChannelGroup = "Platform"
        ),
        FILTER(
            ALLSELECTED('a02_e2e_product_performance_sales_summary_d'[shop_name]),
            (NOT __IsTTL) && __ChannelGroup = "Store"
                && 'a02_e2e_product_performance_sales_summary_d'[shop_name] = __LabelValue
        )
    )

// ═══ 基础聚合：SLS Amt / SLS Unit（This Period 区间 + 渠道上下文，行维度自然筛选）═══
VAR __SLSAmt_This =
    CALCULATE(
        SUM('a02_e2e_product_performance_sales_summary_d'[net_sales_amt]),
        __PlatformCtx,
        __ShopNameCtx,
        'a02_e2e_product_performance_sales_summary_d'[data_date] >= __PeriodMin,
        'a02_e2e_product_performance_sales_summary_d'[data_date] <= __PeriodMax
    )
VAR __SLSUnit_This =
    CALCULATE(
        SUM('a02_e2e_product_performance_sales_summary_d'[net_sales_qty]),
        __PlatformCtx,
        __ShopNameCtx,
        'a02_e2e_product_performance_sales_summary_d'[data_date] >= __PeriodMin,
        'a02_e2e_product_performance_sales_summary_d'[data_date] <= __PeriodMax
    )

// ═══ AUR（件单价 = SLS Amt / SLS Unit；金额类，双模式无关，汇率换算在 Cell Value 层）═══
VAR __AUR = DIVIDE(__SLSAmt_This, __SLSUnit_This)

// ═══ SLS Amt% / Vert. Amt%（占比 = 单元格 SLS Amt / 该列渠道全部商品维度合计）═══
// 两者公式结构相同，渠道上下文由列位置自动区分：
//   SLS Amt%（TTL 列）  → 渠道上下文 = TTL（ALLSELECTED platform / shop_name）
//   Vert. Amt%（非 TTL）→ 渠道上下文 = 对应 Label_Value
// 分母 ALLSELECTED 六个商品维度字段（brand / super_season / product_type / category / md_type / division）：
// 一次只有一个字段在矩阵行上，其余字段 ALLSELECTED 为无操作；移除视觉对象内部的行维度筛选，
// 保留外部切片器，实现对所有商品维度的统计
VAR __SLSAmt_Total_Channel =
    CALCULATE(
        SUM('a02_e2e_product_performance_sales_summary_d'[net_sales_amt]),
        __PlatformCtx,
        __ShopNameCtx,
        ALLSELECTED('a02_e2e_product_performance_sales_summary_d'[brand]),
        ALLSELECTED('a02_e2e_product_performance_sales_summary_d'[super_season]),
        ALLSELECTED('a02_e2e_product_performance_sales_summary_d'[product_type]),
        ALLSELECTED('a02_e2e_product_performance_sales_summary_d'[category]),
        ALLSELECTED('a02_e2e_product_performance_sales_summary_d'[md_type]),
        ALLSELECTED('a02_e2e_product_performance_sales_summary_d'[division]),
        'a02_e2e_product_performance_sales_summary_d'[data_date] >= __PeriodMin,
        'a02_e2e_product_performance_sales_summary_d'[data_date] <= __PeriodMax
    )
VAR __SLSAmtPct = DIVIDE(__SLSAmt_This, __SLSAmt_Total_Channel)

// ═══ Horiz. Amt%（占比 = 单元格 SLS Amt / 该行商品维度全渠道合计）═══
// 分母移除渠道限定（ALLSELECTED platform / shop_name），保留行维度筛选与外部切片器
VAR __SLSAmt_Total_Row =
    CALCULATE(
        SUM('a02_e2e_product_performance_sales_summary_d'[net_sales_amt]),
        ALLSELECTED('a02_e2e_product_performance_sales_summary_d'[platform]),
        ALLSELECTED('a02_e2e_product_performance_sales_summary_d'[shop_name]),
        'a02_e2e_product_performance_sales_summary_d'[data_date] >= __PeriodMin,
        'a02_e2e_product_performance_sales_summary_d'[data_date] <= __PeriodMax
    )
VAR __HorizAmtPct = DIVIDE(__SLSAmt_This, __SLSAmt_Total_Row)

// ═══ LTD ST%（LTD 售罄率%金额，仅 TTL 列；跨 sales + inv 双表）═══
// 分子: LTD 销售金额 = 2024-01-01（待定）至 This Period end 的 net_sales_amt 合计（TTL 渠道上下文）
// 分母: LTD 销售金额 + 期末库存金额（inv 表期末快照日单日时点）
// inv 侧行维度筛选通过 TREATAS 从 sales 表六个商品维度字段传递（上行字段传行筛选，
// 未上行字段传外部切片器上下文）
VAR __LTDSalesAmt =
    CALCULATE(
        SUM('a02_e2e_product_performance_sales_summary_d'[net_sales_amt]),
        __PlatformCtx,
        __ShopNameCtx,
        'a02_e2e_product_performance_sales_summary_d'[data_date] >= __LTDStartDate,
        'a02_e2e_product_performance_sales_summary_d'[data_date] <= __PeriodMax
    )
VAR __InvAmt_End =
    CALCULATE(
        SUM('a02_e2e_product_performance_inv_summary_d'[msrp_inv_amt]),
        'a02_e2e_product_performance_inv_summary_d'[data_date] = __EndPeriodDate
    )
VAR __LTDSTPct = DIVIDE(__LTDSalesAmt, __LTDSalesAmt + __InvAmt_End)

// ═══ EOH Unit（期末库存数量，仅 TTL 列；inv 表期末快照日单日时点）═══
// 口径注意：原始口径 §40 公式写作 sum(msrp_inv_amt)（金额字段），与「期末库存数量」定义存在差异，
// 此处按数量口径 sum(inv_qty) 实现，需业务确认
VAR __EOHUnit =
    CALCULATE(
        SUM('a02_e2e_product_performance_inv_summary_d'[inv_qty]),
        'a02_e2e_product_performance_inv_summary_d'[data_date] = __EndPeriodDate
    )

RETURN
    SWITCH(
        __ColType,
        "SLS Unit",    __SLSUnit_This,   // SLS Unit Act
        "SLS Amt",     __SLSAmt_This,    // SLS Amt Act
        "SLS Amt%",    __SLSAmtPct,      // SLS Amt% Act（仅 TTL 列）
        "Vert. Amt%",  __SLSAmtPct,      // Vert. Amt% Act（非 TTL 列，渠道上下文自动区分）
        "Horiz. Amt%", __HorizAmtPct,    // Horiz. Amt% Act（非 TTL 列）
        "LTD ST%",     __LTDSTPct,       // LTD ST% Act（仅 TTL 列）
        "EOH Unit",    __EOHUnit,        // EOH Unit Act（仅 TTL 列）
        "AUR",         __AUR,            // AUR Act
        BLANK()
    )
```

### 4.2 Sales Performance Details LY Base Value（Last Period 基线）

```dax
Sales Performance Details LY Base Value =
// ========================================
// 度量值: Sales Performance Details LY Base Value
// Display Folder: Base Metrics
// 用途: YOY 对比基线 = SLS Amt Last Period（受 last period 时间筛选器影响）
//       渠道上下文与 Act Base Value 完全一致（同列同渠道对比）
// 说明: 仅在 Base Value 总路由的 YOY 分支中被调用（ColType = "YOY" 时有效）；
//       Last Period 直接读 Slicer_Time_Frame_Min_Last / Max_Last 筛选器，
//       依赖模型中 Last 表与主时间筛选器的既有关系配置
// 汇率换算: 不在此度量值处理，保持原始 RMB
// ========================================

// ── 渠道路由 ──
VAR __ChannelGroup = SELECTEDVALUE('Dim_ColMetric_Sales_Performance_Details'[ChannelGroup], "Platform")
VAR __LabelValue = SELECTEDVALUE('Dim_ColMetric_Sales_Performance_Details'[Label_Value], "TTL")
VAR __IsTTL = (__LabelValue = "TTL")

// ── 指标路由（仅 YOY 列有效）──
VAR __ColType = SELECTEDVALUE('Dim_ColMetric_Sales_Performance_Details'[ColType])

// ── Last Period 时间区间 ──
VAR __PeriodMin_LY = SELECTEDVALUE(Slicer_Time_Frame_Min_Last[TimeFrame_Min])
VAR __PeriodMax_LY = SELECTEDVALUE(Slicer_Time_Frame_Max_Last[TimeFrame_Max])

// ── 渠道上下文过滤器（platform 侧，构造逻辑同 Act Base Value）──
VAR __PlatformCtx =
    UNION(
        FILTER(
            ALLSELECTED('a02_e2e_product_performance_sales_summary_d'[platform]),
            __IsTTL
        ),
        FILTER(
            ALLSELECTED('a02_e2e_product_performance_sales_summary_d'[platform]),
            (NOT __IsTTL) && __ChannelGroup = "Store"
        ),
        FILTER(
            ALLSELECTED('a02_e2e_product_performance_sales_summary_d'[platform]),
            (NOT __IsTTL) && __ChannelGroup = "Platform"
                && 'a02_e2e_product_performance_sales_summary_d'[platform] = __LabelValue
        )
    )

// ── 渠道上下文过滤器（shop_name 侧）──
VAR __ShopNameCtx =
    UNION(
        FILTER(
            ALLSELECTED('a02_e2e_product_performance_sales_summary_d'[shop_name]),
            __IsTTL
        ),
        FILTER(
            ALLSELECTED('a02_e2e_product_performance_sales_summary_d'[shop_name]),
            (NOT __IsTTL) && __ChannelGroup = "Platform"
        ),
        FILTER(
            ALLSELECTED('a02_e2e_product_performance_sales_summary_d'[shop_name]),
            (NOT __IsTTL) && __ChannelGroup = "Store"
                && 'a02_e2e_product_performance_sales_summary_d'[shop_name] = __LabelValue
        )
    )

RETURN
    IF(
        __ColType = "YOY",
        CALCULATE(
            SUM('a02_e2e_product_performance_sales_summary_d'[net_sales_amt]),
            __PlatformCtx,
            __ShopNameCtx,
            'a02_e2e_product_performance_sales_summary_d'[data_date] >= __PeriodMin_LY,
            'a02_e2e_product_performance_sales_summary_d'[data_date] <= __PeriodMax_LY
        )
    )
```

### 4.3 Sales Performance Details Base Value（总路由）

```dax
Sales Performance Details Base Value =
// ========================================
// 度量值: Sales Performance Details Base Value
// Display Folder: Base Metrics
// 用途: 总路由，按 ColType 分发
//       - YOY → SLS Amt This Period / SLS Amt Last Period - 1
//       - 其余 8 种 ColType → 直接取 Act Base Value
//
// YOY 分子重路由机制:
//   REMOVEFILTERS(Dim[ColName]) 清除当前指标列筛选，保留 ChannelGroup / Label 筛选
//   （同渠道对比），再以 ColType = "SLS Amt" 定位到同渠道的 SLS Amt 列取分子；
//   ColName 带 Metric_ID 前缀全局唯一，ChannelGroup + Label + ColType 可唯一定位单行
//
// 空值规则: Last Period 值为空或 0 时 YOY 返回 BLANK
// ========================================
    VAR __ColType = SELECTEDVALUE('Dim_ColMetric_Sales_Performance_Details'[ColType])

    // ── YOY 分子：当前列渠道上下文下的 This Period SLS Amt ──
    VAR __SLSAmt_This =
        IF(
            __ColType = "YOY",
            CALCULATE(
                [Sales Performance Details Act Base Value],
                REMOVEFILTERS('Dim_ColMetric_Sales_Performance_Details'[ColName]),
                'Dim_ColMetric_Sales_Performance_Details'[ColType] = "SLS Amt"
            )
        )

    // ── YOY 分母：当前列渠道上下文下的 Last Period SLS Amt ──
    VAR __SLSAmt_Last =
        IF(
            __ColType = "YOY",
            [Sales Performance Details LY Base Value]
        )

    // ── YOY = This / Last - 1 ──
    VAR __YOYResult =
        IF(
            __ColType = "YOY",
            IF(
                ISBLANK(__SLSAmt_Last) || __SLSAmt_Last = 0,
                BLANK(),
                DIVIDE(__SLSAmt_This, __SLSAmt_Last) - 1
            )
        )

    RETURN
        SWITCH(
            __ColType,
            "YOY", __YOYResult,                          // YOY（12 列，每组各 Label 下 1 列）
            [Sales Performance Details Act Base Value]   // 其余 8 种 ColType 直接取 Act
        )
```

### 4.4 Sales Performance Details Cell Value（对外值，含汇率换算）

```dax
Sales Performance Details Cell Value =
// ========================================
// 度量值: Sales Performance Details Cell Value
// Display Folder: Cell Values
// 用途: 对外暴露的单元格值
//       - 金额类（Metric_IsCurrencyAmount = TRUE：SLS Amt / AUR）→ 按汇率换算
//       - 其余（数量类 / 比率类 / YOY 派生）→ 直接返回 Base Value，不换算
// 依赖: [Sales Performance Details Base Value],
//       'Dim_ColMetric_Sales_Performance_Details'[Metric_IsCurrencyAmount],
//       Slicer_Currency_Selection[Currency_ExchangeRate]
//
// 汇率换算规则:
//   - 数据底表存储 RMB 原始值，USD 时通过 ÷ Currency_ExchangeRate 换算
//   - RMB 时 Currency_ExchangeRate = 1，换算前后值相同
//   - Base Value 层始终保留 RMB 原始值，确保派生计算口径一致；换算集中在展示层，便于管理
// ========================================
    VAR __BaseValue = [Sales Performance Details Base Value]
    VAR __IsCurrencyAmount = SELECTEDVALUE('Dim_ColMetric_Sales_Performance_Details'[Metric_IsCurrencyAmount], FALSE)
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

### 4.5 Sales Performance Details Cell Display（格式化显示）

```dax
Sales Performance Details Cell Display =
// ========================================
// 度量值: Sales Performance Details Cell Display
// Display Folder: Formatting
// 用途: 按 Metric_Format 单字段格式化显示
// 依赖: [Sales Performance Details Cell Value],
//       'Dim_ColMetric_Sales_Performance_Details'[Metric_Format],
//       Slicer_Currency_Selection[Currency_Symbol]
//
// 格式类型（口径文档未定义本模块数据格式，按页面设计 + 模版复用/数据类型和格式总览.md 推定，
// 业务确认后可调整）:
//   integer       → FORMAT(__Value, "#,##0") 整数千分位（SLS Unit / EOH Unit）
//   currency      → __CurrencySymbol & FORMAT(__Value, "#,##0")（SLS Amt / AUR，符号由币种切片器决定）
//   delta_pct_0dp → IF(__Value>0,"+","") & FORMAT(__Value,"#,##0%") 百分比整数变化，含正号（YOY）
//   percent_0dp   → FORMAT(__Value, "#,##0%") 百分比整数（SLS Amt% / Vert. Amt% / Horiz. Amt% / LTD ST%）
// 说明: BLANK 显示为 "-"; Cell Value 层已完成汇率换算，Display 层只负责符号拼接
// ========================================
    VAR __Value = [Sales Performance Details Cell Value]
    VAR __Format = SELECTEDVALUE('Dim_ColMetric_Sales_Performance_Details'[Metric_Format])
    VAR __CurrencySymbol = SELECTEDVALUE(Slicer_Currency_Selection[Currency_Symbol], "¥")

    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            SWITCH(
                __Format,
                // ─── 金额类（货币符号 + 千分位整数）───
                "currency",
                    __CurrencySymbol & FORMAT(__Value, "#,##0"),                                    // ¥640,299
                // ─── 整数千分位（数量类）───
                "integer",
                    FORMAT(__Value, "#,##0"),                                                       // 3,160
                // ─── 百分比整数，不含正号（占比 / LTD ST%）───
                "percent_0dp",
                    FORMAT(__Value, "#,##0%"),                                                      // 26%
                // ─── 百分比整数变化，含正号（YOY）───
                "delta_pct_0dp",
                    IF(__Value > 0, "+", "") & FORMAT(__Value, "#,##0%"),                           // +26% / -3%
                // ─── 扩展格式（便于后续快速调整）───
                "currency_M_K_Int_0db",
                    IF(
                        __Value < 1000,
                        __CurrencySymbol & FORMAT(__Value, "#,##0"),                                // ¥999
                        IF(
                            __Value < 1000000,
                            __CurrencySymbol & FORMAT(__Value / 1000, "#,##0.0") & "K",             // ¥1.5K
                            __CurrencySymbol & FORMAT(__Value / 1000000, "#,##0.0") & "M"           // ¥1.5M
                        )
                    ),
                "integer_M_K_Int_0db",
                    IF(
                        __Value < 1000,
                        FORMAT(__Value, "#,##0"),                                                   // 999
                        IF(
                            __Value < 1000000,
                            FORMAT(__Value / 1000, "#,##0.0") & "K",                                // 1.5K
                            FORMAT(__Value / 1000000, "#,##0.0") & "M"                              // 1.5M
                        )
                    ),
                "percent_1dp",
                    FORMAT(__Value, "#,##0.0%"),                                                    // 26.5%
                "delta_pct_1dp",
                    IF(__Value > 0, "+", "") & FORMAT(__Value, "#,##0.0%"),                         // +14.5%
                "decimal_1dp",
                    FORMAT(__Value, "#,##0.0"),                                                     // 203.5
                // ─── 默认 ─────────────────────────────────
                FORMAT(__Value, "#,##0.00")
            )
        )
```

### 4.6 Sales Performance Details Cell Font Color（字体颜色）

```dax
Sales Performance Details Cell Font Color =
// ========================================
// 度量值: Sales Performance Details Cell Font Color
// Display Folder: Formatting
// 用途: 按 Metric_ColorRule 字段分发字体颜色
// 依赖: [Sales Performance Details Cell Value],
//       'Dim_ColMetric_Sales_Performance_Details'[Metric_ColorRule, Metric_ColorPositive/Negative/Zero/Default]
//
// 颜色规则:
//   1. 全部基础指标列（SLS Unit / SLS Amt / SLS Amt% / Vert. Amt% / Horiz. Amt% /
//      LTD ST% / EOH Unit / AUR）固定 #252423 → "fixed_black"
//   2. YOY（比率为正/负/零三色）→ "pos_neg_zero"
// ========================================
    VAR __Value = [Sales Performance Details Cell Value]
    VAR __ColorRule = SELECTEDVALUE('Dim_ColMetric_Sales_Performance_Details'[Metric_ColorRule], "fixed_default")
    VAR __ColorPositive = SELECTEDVALUE('Dim_ColMetric_Sales_Performance_Details'[Metric_ColorPositive], "#1A9018")
    VAR __ColorNegative = SELECTEDVALUE('Dim_ColMetric_Sales_Performance_Details'[Metric_ColorNegative], "#D64550")
    VAR __ColorZero = SELECTEDVALUE('Dim_ColMetric_Sales_Performance_Details'[Metric_ColorZero], "#E1C233")
    VAR __ColorDefault = SELECTEDVALUE('Dim_ColMetric_Sales_Performance_Details'[Metric_ColorDefault], "#5F6165")

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

### 4.7 Sales Performance Details Cell Background Color（背景色）

```dax
Sales Performance Details Cell Background Color =
// ========================================
// 度量值: Sales Performance Details Cell Background Color
// Display Folder: Formatting
// 用途: 区分 ColName 层（指标列）与上层（Label / ChannelGroup）的背景色
// 依赖: ISINSCOPE('Dim_ColMetric_Sales_Performance_Details'[ColName])
// ========================================
    VAR __IsMetricCol = ISINSCOPE('Dim_ColMetric_Sales_Performance_Details'[ColName])
    RETURN
        IF(
            __IsMetricCol,
            "#FFFFFF",   // ColName 层（指标列）: 白色
            "#E6D9C7"    // Label / ChannelGroup 层: 中米色
        )
```

---

## 5. 度量值清单与 Display Folder

| 序号 | 度量值名称                                      | Display Folder | 用途                                                                            |
| ---- | ----------------------------------------------- | -------------- | ------------------------------------------------------------------------------- |
| 1    | Sales Performance Details Act Base Value        | Base Metrics   | This Period 基础值（8 种基础 ColType）；渠道上下文 + ColType 路由；RMB 原值     |
| 2    | Sales Performance Details LY Base Value         | Base Metrics   | Last Period SLS Amt 基线（YOY 分母）                                            |
| 3    | Sales Performance Details Base Value            | Base Metrics   | 总路由（YOY 派生 + REMOVEFILTERS(ColName) 重路由；其余直接取 Act）；74 列全覆盖 |
| 4    | Sales Performance Details Cell Value            | Cell Values    | 对外值：金额类（SLS Amt / AUR）汇率换算（÷ Currency_ExchangeRate）             |
| 5    | Sales Performance Details Cell Display          | Formatting     | 格式化显示文本（integer / currency / delta_pct_0dp / percent_0dp + 扩展格式）   |
| 6    | Sales Performance Details Cell Font Color       | Formatting     | 字体颜色（基础指标=fixed_black；YOY=pos_neg_zero 三色）                         |
| 7    | Sales Performance Details Cell Background Color | Formatting     | 背景色（ColName 层#FFFFFF vs 上层 #E6D9C7）                                     |

---

## 6. 血缘关系图

```
┌─────────────────────────────────────────────────────────────────────┐
│                        数据源层                                      │
│  a02_e2e_product_performance_sales_summary_d（销售类，日粒度）       │
│  字段: data_date, platform, shop_name,                              │
│        brand, super_season, product_type, category,                 │
│        md_type, division, framework, ax_class, ...                  │
│        net_sales_amt, net_sales_qty                                 │
│  a02_e2e_product_performance_inv_summary_d（库存类，日快照）        │
│  字段: data_date + 商品维度（与 sales 同名同构，无渠道字段）,        │
│        msrp_inv_amt, inv_qty                                        │
└──────────────────────────────┬──────────────────────────────────────┘
                               │ 渠道/商品切片器 1:N 自动传递
                               ▼
┌─────────────────────────────────────────────────────────────────────┐
│                        度量值层                                      │
│                                                                     │
│  ┌───────────────────────────┐   ┌───────────────────────────┐      │
│  │ Sales Performance Details │   │ Sales Performance Details │      │
│  │ Act Base Value            │   │ LY Base Value             │      │
│  │ (This Period + 期末快照   │   │ (Last Period SLS Amt)     │      │
│  │  + LTD 区间)              │   └────────────┬──────────────┘      │
│  └────────────┬──────────────┘                │                     │
│               │        ┌──────────────────────────────┐             │
│               │◄───────│ Dim_ColMetric_Sales_         │             │
│               │        │ Performance_Details          │             │
│               │        │ (ChannelGroup/Label/         │             │
│               │        │  Label_Value/ColType)        │             │
│               │        ├──────────────────────────────┤             │
│               │◄───────│ Slicer_Time_Frame_Min/Max_   │             │
│               │        │ This / Min/Max_Last          │             │
│               │        └──────────────────────────────┘             │
│               ▼                                                     │
│  ┌──────────────────────────────────────────────────────┐           │
│  │ Sales Performance Details Base Value                 │           │
│  │ (总路由: YOY = This/Last - 1，REMOVEFILTERS(ColName)  │           │
│  │  重路由取分子；其余 8 种 ColType 直接取 Act)          │           │
│  └───────────────────────┬──────────────────────────────┘           │
│                          ▼                                          │
│  ┌──────────────────────────────────────────────────────┐           │
│  │ Sales Performance Details Cell Value                 │           │
│  │ (金额类汇率换算 ÷ Currency_ExchangeRate)             │           │
│  │          ▲ Slicer_Currency_Selection                 │           │
│  └───────────────────────┬──────────────────────────────┘           │
│                          ▼                                          │
│  ┌──────────────────────────────────────────────────────┐           │
│  │ Sales Performance Details Cell Display               │           │
│  │ (按 Metric_Format 格式化 + Currency_Symbol 拼接)      │           │
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
│  列: 'Dim_ColMetric_Sales_Performance_Details'[ChannelGroup]        │
│      > [Label] > [ColName]（ChannelGroup_Sort / Label_Sort /        │
│      ColName_Sort 排序）                                             │
│  行: sales 表商品维度字段六选一                                      │
│      (brand / super_season / product_type / category /              │
│       md_type / division)，一次只用一个字段                          │
│  值: [Sales Performance Details Cell Display]                       │
│  条件格式: 字体颜色 → Cell Font Color；背景色 → Cell Background     │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 7. 注意事项

1. **Brand 字段说明**：商品维度字段为 `brand`（品牌标签：W Polo、FJ、CL、PL、CW、M Polo、RRL、HM、Lauren），数据字典已由 label 统一更新为 brand，口径中的 "Label / Brand" 维度即该字段，全部 ALLSELECTED / TREATAS 均按 `brand` 实现。
2. **inv 侧 TREATAS 的原因与替代方案**：六个商品维度行字段取自 sales 表，行筛选只作用于 sales 表本身——sales 侧指标（SLS / YOY / 占比 / AUR）全部依赖模型自然传递，无显式 DAX。inv 是另一张独立事实表，Power BI 筛选只沿模型关系传递，同名字段之间没有关系不会自动传递；且 sales 与 inv 两表之间最多只能存在一条活动关系，无法覆盖六个可切换的行维度字段，故 inv 侧（EOH Unit、LTD ST% 分母）通过 `TREATAS(VALUES(sales[字段]), inv[字段])` × 六字段显式传递（上行字段传行筛选，未上行字段传外部切片器上下文）。替代方案：六个字段各建 distinct 维度表并与两张事实表分别建 1:N 关系、行维度从维度表字段拉取，行筛选即可由模型自动传递到两张事实表（TREATAS 全部移除，ALLSELECTED 六字段目标同步改为维度表字段）；现有 Slicer_Label / Slicer_Product_Type / Slicer_Category / Slicer_Division 为 distinct 维度表可复用，super_season / md_type 无对应维度表需补建。
3. **TTL 的 ALLSELECTED 语义**：TTL 列对 [platform] / [shop_name] 应用 ALLSELECTED——移除视觉对象内部的渠道筛选，保留外部切片器，即外部筛选上下文下的全渠道合计；不选或多选 Label 时 SELECTEDVALUE 默认 "TTL"。
4. **非 TTL 列与外部渠道切片器的交集关系**：Platform / Store 列的渠道过滤基于 ALLSELECTED 集与 Label_Value 取交集。如外部 platform 切片器仅选 TM，则 JD 列返回空（外部切片器限定数据范围）。若业务期望明细列不受外部渠道切片器限制，需将 `__PlatformCtx` / `__ShopNameCtx` 中对应分支的 ALLSELECTED 基表改为 ALL——待业务确认。
5. **占比分母的 ALLSELECTED**：SLS Amt% / Vert. Amt% 分母同时 ALLSELECTED 六个商品维度字段（一次只有一个字段在行上，其余为无操作），移除视觉对象内部行维度筛选、保留外部切片器；Horiz. Amt% 分母不 ALLSELECTED 商品字段（保留行筛选），改为 ALLSELECTED [platform] / [shop_name]（该行全渠道合计）。
6. **SLS Amt% 与 Vert. Amt% 公式同构**：两者均为「单元格 SLS Amt / 该列渠道全部商品合计」，渠道上下文由列位置（TTL / 非 TTL）自动区分，Act Base Value 中共用同一组变量。
7. **YOY 口径**：this period / last period 对比，受 last period 时间筛选器影响；分子通过 `REMOVEFILTERS(Dim[ColName]) + ColType = "SLS Amt"` 重路由取得（保留 ChannelGroup / Label 渠道上下文，同渠道对比）；Last Period 值空或 0 时返回 BLANK。
8. **LTD ST% 待定项**：销售区间起算 2024-01-01 为口径待定项，以变量 `__LTDStartDate` 承载（Act Base Value 内一处调整）；分母期末库存金额取 end period 范围内最后快照日单日值，LTD ST% 仅存在于 TTL 列。
9. **EOH Unit 口径差异**：原始口径 §40 公式写作 `sum(msrp_inv_amt)`（金额字段），与「期末库存数量」定义存在差异，本方案按数量口径 `sum(inv_qty)` 实现，需业务确认；确认若为金额口径，仅调整 `__EOHUnit` 的聚合字段。
10. **inv 表无渠道字段**：a02_e2e_product_performance_inv_summary_d 无 platform / shop_name，渠道上下文不作用于 inv 侧；EOH Unit / LTD ST% 分母不受渠道筛选影响，需业务知悉该口径影响。
11. **期末快照日机制**：`__EndPeriodDate` 取 end period 范围 [Max_This[TimeFrame_Min], Max_This[TimeFrame_Max]] 内最后一个有数据的快照日，用 REMOVEFILTERS(inv) 计算，保证快照日不随行维度 / 商品切片器漂移；快照缺数时自动回退到范围内最近一天。
12. **REMOVEFILTERS(ColName) 重路由前提**：ColName 带 Metric_ID 前缀全局唯一，ChannelGroup + Label + ColType 三条件可唯一定位单行；ChannelGroup / Label 层汇总单元格无唯一 ColName → BLANK → 显示 "-"。
13. **汇率换算分层**：Base Value 层始终保留 RMB 原始值（YOY 派生计算口径一致）；换算集中在 Cell Value（÷ Currency_ExchangeRate，RMB 时汇率 = 1）；Cell Display 只拼接 Currency_Symbol。金额类判定用 Metric_IsCurrencyAmount（本模块无双模式，该字段直接生效）。
14. **渠道上下文过滤器构造**：`__PlatformCtx` / `__ShopNameCtx` 用 UNION+FILTER 构造（避免 IF/SWITCH 分支退化表变量），作为 CALCULATE 表过滤器统一传入所有 sales 侧聚合，六种聚合（SLS Amt / SLS Unit / 渠道合计 / 行合计 / LTD 销售）共用同一渠道上下文。
15. **字段名已核对数据字典**：net_sales_amt / net_sales_qty / platform / shop_name / brand / super_season / product_type / category / md_type / division（sales 表）；msrp_inv_amt / inv_qty + 同名商品维度（inv 表）；日期字段统一为 data_date（date 类型）。
16. **DAX 语法规范**：文本常量使用双引号（如 [md_type] = "FP"），单引号仅用于表名，列名使用方括号；与解决方案存在争议时一切以口径文档为准。
