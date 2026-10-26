# Platform Merchandising Performance 矩阵解决方案

> **版本**: v1.0
> **模块**: RL E2E Merch Dashboard - Dimension Cross Analysis Tab - Platform Merchandising Performance（子模块八）
> **关联口径**: 口径文档/口径Markdown格式/Dimension Cross Analysis.md - 子模块八：Platform Merchandising Performance（§34-§39）+ 口径文档/口径Markdown格式/actual除target逻辑详情.md（TAR 类指标五粒度规则）
> **数据底表（销售类）**: a02_e2e_product_performance_sales_summary_d
> **数据底表（库存类）**: a02_e2e_product_performance_inv_summary_d
> **数据底表（目标类）**: a05_e2e_product_fcst_data_d
> **关联维度**: Dim_ColMetric_Platform_Merchandising_Performance（列，三层 ChannelGroup > Label > ColName，64 列）、Slicer_Time_Frame（时间粒度）、Slicer_Time_Frame_Min_This / Max_This / Min_Last / Max_Last（日期，断开维度）、Slicer_Framework / Slicer_Category（行维度）、Slicer_Platform_Selection / Slicer_Store_Name / Slicer_Label（渠道 / 品牌外部切片器）、Slicer_Currency_Selection（币种）

---

## 1. 需求理解

### 1.1 模块定位

Platform Merchandising Performance 是按 Framework + Category 展开的渠道 × 指标销售明细矩阵：

- **列**：三层结构 ChannelGroup（Platform / Store）> Label（页面显示标签）> ColName（指标列），共 64 列
  - Platform 组 27 列：TTL（7 列）+ Tmall / JD / RLE / DY（各 5 列）
  - Store 组 37 列：TTL（7 列）+ Tmall / JD / RLE / DY_Family / DY_W / DY_MN（各 5 列）
  - TTL 列组合（7 列）: SLS Amt% / vs LP / EOH / ST% / TAR ACH% / MTD TAR Progress / YTD TAR Progress
  - 非 TTL 列组合（5 列）: SLS Amt% / vs LP / TAR ACH% / MTD TAR Progress / YTD TAR Progress
  - EOH / ST% 仅 TTL 列展示——库存类指标按全渠道口径（inv 表无渠道字段）；
    TAR 三指标（TAR ACH% / MTD TAR Progress / YTD TAR Progress）按渠道口径在全部 Label 列展示
- **行**：层级结构 `Slicer_Framework[framework]`（父层）> `Slicer_Category[category]`（子层），均取自 Slicer_ 维度表，与三张事实表一对多关联，行筛选经模型关系自动传导
- **行自动隐藏**：矩阵在检测到该行所有度量值均为 BLANK() 时自动隐藏该行（包括层级行）；Display 度量值空值一律返回 BLANK()（非 "-""），由矩阵自动隐藏机制消化

### 1.2 路由维度

| 路由维度 | 来源                                                                           | 类型       | 说明                                                                                                        |
| -------- | ------------------------------------------------------------------------------ | ---------- | ----------------------------------------------------------------------------------------------------------- |
| 渠道     | Dim_ColMetric_Platform_Merchandising_Performance 的 ChannelGroup + Label_Value | 断开列维度 | Platform 组过滤事实表 [platform]，Store 组过滤 [shop_name]；Label_Value = "TTL" 时走 ALLSELECTED 全渠道合计 |
| 指标     | Dim_ColMetric_Platform_Merchandising_Performance 的 ColType                    | 断开列维度 | 7 种：SLS Amt% / vs LP / EOH / ST% / TAR ACH% / MTD TAR Progress / YTD TAR Progress                         |
| 行维度   | Slicer_Framework[framework] + Slicer_Category[category]                        | 维度表字段 | 层级行维度（framework 父层 + category 子层）；与三张事实表一对多关联，筛选自动传导，DAX 无需显式处理        |

**Label → 事实表实际值映射**（已核对 Slicer_Platform_Selection / Slicer_Store_Name）：

| ChannelGroup | Label                                       | Label_Value                                | 说明                                                                   |
| ------------ | ------------------------------------------- | ------------------------------------------ | ---------------------------------------------------------------------- |
| Platform     | TTL                                         | TTL（特殊标记）                            | ALLSELECTED 移除视觉对象内部 platform / shop_name 筛选，保留外部切片器 |
| Platform     | Tmall / JD / RLE / DY                       | TM / JD / RLE / DY                         | 过滤 [platform]                                                        |
| Store        | TTL                                         | TTL（特殊标记）                            | 同上，全店铺合计                                                       |
| Store        | Tmall / JD / RLE / DY_Family / DY_W / DY_MN | TM / JD / RLE_CN / DY_Family / DY_W / DY_M | 过滤 [shop_name]                                                       |

**TTL 特殊处理**：度量值中对 [platform] / [shop_name] 应用 ALLSELECTED——移除视觉对象内部的渠道筛选，保留外部切片器（Slicer_Platform_Selection / Slicer_Store_Name 等）的筛选，即 TTL = 外部筛选上下文下的全渠道合计。

**渠道上下文对三张事实表对称生效**：sales 侧（[platform] / [shop_name]）与 fcst 侧（a05[platform] / a05[shop_name]）各构造一组同构的渠道上下文过滤器；a05 事实表无 TTL 预聚合值，TTL 列 target 由 ALLSELECTED 汇总取得，不存在重复计数。inv 表无 platform / shop_name 字段，渠道上下文不作用于库存侧。

### 1.3 时间口径

| 口径                      | 时间范围                                                                                                                          | 适用                                                         |
| ------------------------- | --------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------ |
| This Period（区间类）     | data_date ∈ [Slicer_Time_Frame_Min_This[TimeFrame_Min], Slicer_Time_Frame_Max_This[TimeFrame_Max]]                               | SLS Amt% 分子分母、TAR 三指标 actual、TAR ACH% 分母          |
| Last Period（vs LP 基线） | data_date ∈ [Slicer_Time_Frame_Min_Last[TimeFrame_Min], Slicer_Time_Frame_Max_Last[TimeFrame_Max]]                               | vs LP 分子分母（占比差值双期）                               |
| End Period（期末时点类）  | end period 范围 [Slicer_Time_Frame_Max_This[TimeFrame_Min], Slicer_Time_Frame_Max_Time[TimeFrame_Max]] 内**最后一个快照日** | EOH、ST% 分母库存                                            |
| target MTD 区间           | [Slicer_Time_Frame_Max_This[Fiscal_Month_First_Day], Slicer_Time_Frame_Max_This[Fiscal_Month_Last_Day]]（TimeFrame_Max 所在财月） | MTD TAR Progress 分母（Day / Week 不跨月）                   |
| target YTD 区间           | [Slicer_Time_Frame_Max_This[Fiscal_Year_First_Day], Slicer_Time_Frame_Max_This[Fiscal_Year_Last_Day]]（TimeFrame_Max 所在财年）   | YTD TAR Progress 分母（Day / Week / Month / Quarter 不跨年） |

说明：

- vs LP 是 this period 和 last period 对比，受 last period 时间筛选器影响
- 期末时点类实现为 end period 范围内最后一个有数据的快照日：口径为 end period 最后一天，快照缺数时自动回退到范围内最近一天；快照表按日存储只取单日，整段区间求和会重复计数库存
- **时间粒度**读 `SELECTEDVALUE(Slicer_Time_Frame[TimeFrame_ID])`（Day / Week / Month / Quarter / Year）
- **跨财月判定**：不区分粒度，直接比较 `Slicer_Time_Frame_Min_This[TimeFrame_Min_Month_Value]` 与 `Slicer_Time_Frame_Max_This[TimeFrame_Max_Month_Value]`（财月 value，文本类型，如 "2027-08"），不相等 → 跨财月
- **跨财年判定**：不区分粒度，直接比较 `Slicer_Time_Frame_Min_This[TimeFrame_Min_Year_Value]` 与 `Slicer_Time_Frame_Max_This[TimeFrame_Max_Year_Value]`（财年 value，文本类型，如 "2027"），不相等 → 跨财年

### 1.4 TAR 类指标口径（actual ÷ target）

- **actual**：`a02_e2e_product_performance_sales_summary_d[net_sales_amt]`，**恒为 This Period 区间**（渠道上下文 + 行维度），三指标分子一致
- **target**：`a05_e2e_product_fcst_data_d[fcst_sales_amt]`，时间区间随指标与粒度分支（渠道上下文与行维度与 actual 同构）
- actual / target 同为底表 RMB 原值相除，TAR 比率不受币种选择影响

**粒度 × 指标计算矩阵**：

| 时间粒度 | TAR ACH%（达成率）                        | MTD TAR Progress                                    | YTD TAR Progress                                         |
| -------- | ----------------------------------------- | --------------------------------------------------- | -------------------------------------------------------- |
| Day      | This actual / This target（date to date） | 不跨财月：This actual / 财月 target；跨财月：不计算 | 不跨财年：This actual / 财年 target；跨财年：不计算      |
| Week     | This / This                               | 同 Day                                              | 同 Day                                                   |
| Month    | This / This                               | This / This（分子分母始终和 This Period 区间一致）  | 不跨财年：This / 财年 target；跨财年：不计算             |
| Quarter  | This / This                               | 不计算                                              | 不跨财年：This / 财年 target；跨财年：不计算             |
| Year     | This / This                               | 不计算                                              | 计算，This / This（分子分母始终和 This Period 区间一致） |

- **TAR ACH%（达成率）**：全粒度 date to date——分子分母始终和 This Period 区间一致
- **MTD TAR Progress**：actual 恒为 This Period 区间；Day / Week 不跨月时分母取 TimeFrame_Max 所在财月汇总 target（财月区间可超出 This Period，即"本月进度"语义）；Month 粒度下财月选择与 This Period 等价，口径直接定义为 This / This（跨月多选时同样如此）；Quarter / Year 不计算
- **YTD TAR Progress**：actual 恒为 This Period 区间；Day / Week / Month / Quarter 不跨年时分母取 TimeFrame_Max 所在财年汇总 target（财年区间可超出 This Period，即"年度进度"语义）；Year 粒度下财年选择与 This Period 等价（跨年多选时财年区间不唯一），口径直接定义为 This / This 且始终计算
- **不计算** = 度量值返回 BLANK → Display 返回 BLANK() → 参与整行自动隐藏

**Day 粒度交叉点对照示例**：

| 所选区间                                | TAR ACH%                                  | MTD TAR Progress                                                   | YTD TAR Progress                                                 |
| --------------------------------------- | ----------------------------------------- | ------------------------------------------------------------------ | ---------------------------------------------------------------- |
| 2026-03-29 ~ 2026-04-03（不跨月不跨年） | actual[03-29~04-03] / target[03-29~04-03] | actual[03-29~04-03] / target[2026-03-29~2026-04-25]（FY2701 财月） | actual[03-29~04-03] / target[2026-03-29~2027-04-03]（FY27 财年） |
| 2026-03-29 ~ 2026-05-03（跨月不跨年）   | actual[03-29~05-03] / target[03-29~05-03] | 不计算（BLANK）                                                    | actual[03-29~05-03] / target[FY27 财年]                          |
| 跨财年区间                              | actual / target 同区间                    | 视是否跨财月                                                       | 不计算（BLANK）                                                  |

### 1.5 指标口径（§34-§39 → 7 种 ColType）

| ColType          | 口径出处        | 计算逻辑                                                                                | 格式        |
| ---------------- | --------------- | --------------------------------------------------------------------------------------- | ----------- |
| SLS Amt%         | §34-§37       | 单元格 SLS Amt / 该列渠道全部行合计（占比；随行维度切换承载 framework / category 占比） | percent_0dp |
| vs LP            | §34-§37 附属  | SLS Amt% This - SLS Amt% Last（占比差值，原始小数，×10000 转 bp 在 Display 层）        | integer_bp  |
| EOH              | §38            | 期末库存金额 = end period 最后快照日 `sum(msrp_inv_amt)`，仅 TTL 列                   | currency    |
| ST%              | §39            | This Period 销售金额 /（This Period 销售金额 + 期末库存金额），仅 TTL 列                | percent_0dp |
| TAR ACH%         | 子模块八 TAR 类 | 见 §1.4 粒度矩阵                                                                       | percent_0dp |
| MTD TAR Progress | 子模块八 TAR 类 | 见 §1.4 粒度矩阵                                                                       | percent_0dp |
| YTD TAR Progress | 子模块八 TAR 类 | 见 §1.4 粒度矩阵                                                                       | percent_0dp |

**§34-§36（Foundation / Acceleration / Complementary 销售金额占比）与 §37（Category SLS Amt%）的承载方式**：四者均为「该行 framework / category 销售金额 ÷ 该列渠道全部行合计」的占比，公式结构相同——行维度为 framework 时 SLS Amt% 列分别给出三个 framework 的占比（§34-§36），行维度展开到 category 时给出各 category 的占比（§37）。一套 SLS Amt% 逻辑覆盖全部四个口径，列指标表不单独建 Foundation / Acceleration / Complementary 列。

---

## 2. 现状分析

- 数据底表 `a02_e2e_product_performance_sales_summary_d`（日粒度）：net_sales_amt 及商品维度字段（brand、super_season、product_type、category、md_type、division、framework、ax_class 等）+ platform / shop_name 渠道字段；platform 已在数据源层过滤 IN ('JD','TM','RLE','DY')，无 TTL 值
- 数据底表 `a02_e2e_product_performance_inv_summary_d`（日快照）：msrp_inv_amt，商品维度字段与 sales 表同名同构；**无 platform / shop_name 字段**，渠道筛选不影响库存侧
- 数据底表 `a05_e2e_product_fcst_data_d`（目标类）：data_date（date 类型）、platform、shop_name、brand、framework、category、fcst_sales_amt；**无 TTL 预聚合值**（TTL 列 target 由 ALLSELECTED 汇总实现）
- **模型关系**：Slicer_Platform_Selection、Slicer_Store_Name、Slicer_Label、Slicer_Framework、Slicer_Category 五个维度表与三张事实表均为一对多关联，切片器与行维度筛选自动传导；**日期筛选器（Slicer_Time_Frame 系列）与三张事实表断开维度**，全部时间区间在度量值内以 data_date 比较显式过滤
- 矩阵行取自 Slicer_ 维度表字段（framework / category），sales / inv / a05 三侧行筛选均经关系自动传导，**无需 TREATAS 桥接**
- 列维度表 `Dim_ColMetric_Platform_Merchandising_Performance` 已存在（本目录，64 行），含 ChannelGroup / Label / Label_Value / ColName / ColType / Metric_Format / Metric_IsCurrencyAmount / 颜色字段
- Slicer_Time_Frame_Max_This 含 Fiscal_Month_First_Day / Fiscal_Month_Last_Day / Fiscal_Year_First_Day / Fiscal_Year_Last_Day（按 TimeFrame_Max 落入的财月 / 财年自关联财年日历生成）及 TimeFrame_Max_Month_Value / TimeFrame_Max_Year_Value；Slicer_Time_Frame_Min_This 含 TimeFrame_Min_Month_Value / TimeFrame_Min_Year_Value——TAR 分母区间起点与跨期判定字段直接读取
- 字段名已逐一核对数据字典与维度复用 SQL

---

## 3. 方案设计

### 3.1 度量值分层

```
Act Base Value / LY Base Value
    ←  渠道上下文路由（ChannelGroup + Label_Value，TTL 走 ALLSELECTED；sales 侧与 fcst 侧同构）
       + ColType 指标路由 + 时间粒度分支（TAR 类）+ 行维度自然传导，保留 RMB 原始值
    ↓
Base Value（总路由）
    ←  vs LP = SLS Amt% This - SLS Amt% Last（整表 REMOVEFILTERS + 渠道三条件重路由取分子）
       其余 6 种 ColType 直接取 Act Base Value
    ↓
Cell Value
    ←  金额类（Metric_IsCurrencyAmount = TRUE，仅 EOH）汇率换算（÷ Currency_ExchangeRate）
    ↓
Cell Display
    ←  按 Metric_Format 格式化（percent_0dp / currency / integer_bp + 扩展格式）；空值返回 BLANK()
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

实现为表变量：sales 侧 `__PlatformCtx` / `__ShopNameCtx`（基于 sales 表两列），fcst 侧 `__FcstPlatformCtx` / `__FcstShopNameCtx`（基于 a05 表两列，构造逻辑完全同构）——均为 UNION + FILTER 构造（保证表类型稳定），作为 CALCULATE 过滤器分别传入 sales 侧与 fcst 侧聚合。

### 3.3 指标口径（ColType 路由）

| ColType          | 数据底表    | 时间口径             | 公式                                                                                  | 格式        |
| ---------------- | ----------- | -------------------- | ------------------------------------------------------------------------------------- | ----------- |
| SLS Amt%         | sales       | This Period 区间     | 单元格 SLS Amt / 该列渠道全部行合计（分母 ALLSELECTED framework + category 两行维度） | percent_0dp |
| vs LP            | sales       | This / Last 区间     | SLS Amt% This - SLS Amt% Last（差值原始小数）                                         | integer_bp  |
| EOH              | inv         | 期末快照单日         | sum(msrp_inv_amt)                                                                     | currency    |
| ST%              | sales + inv | This 区间 / 期末快照 | This SLS Amt /（This SLS Amt + 期末库存金额）                                         | percent_0dp |
| TAR ACH%         | sales + a05 | This / This 区间     | This actual / This target                                                             | percent_0dp |
| MTD TAR Progress | sales + a05 | 见 §1.4 粒度矩阵    | This actual / 分母区间 target（随粒度分支）                                           | percent_0dp |
| YTD TAR Progress | sales + a05 | 见 §1.4 粒度矩阵    | This actual / 分母区间 target（随粒度分支）                                           | percent_0dp |

### 3.4 占比与 bp 差值口径

| 指标             | 分子                                                             | 分母                                                                                                                                                |
| ---------------- | ---------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------- |
| SLS Amt%         | 当前单元格 SLS Amt（列渠道上下文 + 当前行 framework / category） | 同渠道上下文 + ALLSELECTED(Slicer_Framework[framework],Slicer_Framework[sort_order]) + ALLSELECTED(Slicer_Category[category])（该列渠道全部行合计） |
| vs LP（bp 差值） | SLS Amt% This（同渠道上下文，This Period 区间）                  | SLS Amt% Last（同渠道上下文，Last Period 区间，分母 ALLSELECTED 同构）                                                                              |

- ALLSELECTED 两个行维度字段：移除视觉对象内部的行维度筛选、保留外部切片器；framework 上行时 category 无内部筛选（ALLSELECTED 为无操作），展开到 category 时同理——一套分母逻辑同时覆盖 §34-§36（framework 行）与 §37（category 行）
- vs LP 值层为占比差值原始小数（如 -0.0152），×10000 转 bp 在 Cell Display 层完成（本模块为矩阵纯展示场景，无 Y 轴绑定）；落地格式不含正号（-152bp / 0bp）

---

## 4. 度量值实现

### 4.1 Platform Merchandising Act Base Value（This Period 基础值）

```dax
Platform Merchandising Act Base Value =
// ========================================
// 度量值: Platform Merchandising Act Base Value
// Display Folder: Platform Merchandising Performance\Base Metrics
// 用途: This Period 基础值，按渠道上下文（ChannelGroup + Label_Value）+ ColType 路由，
//       覆盖 6 种基础指标列（SLS Amt% / EOH / ST% / TAR ACH% / MTD TAR Progress /
//       YTD TAR Progress），保留 RMB 原始值（比率类为原始小数）
//       vs LP 为跨期派生指标，在 Base Value 总路由中处理，本度量值不涉及
// 依赖: 'Dim_ColMetric_Platform_Merchandising_Performance'[ChannelGroup, Label_Value, ColType]
//       Slicer_Time_Frame[TimeFrame_ID]（时间粒度，TAR 分母区间分支）
//       Slicer_Time_Frame_Min_This[TimeFrame_Min] / Slicer_Time_Frame_Max_This[TimeFrame_Max]
//       Slicer_Time_Frame_Max_This[Fiscal_Month_First_Day / Fiscal_Month_Last_Day /
//         Fiscal_Year_First_Day / Fiscal_Year_Last_Day]（TAR 分母区间）
//       Slicer_Time_Frame_Min_This[TimeFrame_Min_Month_Value / TimeFrame_Min_Year_Value] 与
//       Slicer_Time_Frame_Max_This[TimeFrame_Max_Month_Value / TimeFrame_Max_Year_Value]
//         （跨财月 / 跨财年判定，文本比较）
// 数据底表: a02_e2e_product_performance_sales_summary_d（actual）
//           a02_e2e_product_performance_inv_summary_d（EOH / ST% 分母库存）
//           a05_e2e_product_fcst_data_d（target；无 TTL 预聚合值，TTL 由 ALLSELECTED 汇总）
// 汇率换算: 不在此度量值处理，EOH 保持原始 RMB，由 Cell Value 层统一换算；
//           TAR 类比率为 actual / target 同币种相除，不受币种选择影响
// ========================================

// ── 渠道路由 ──
VAR __ChannelGroup = SELECTEDVALUE('Dim_ColMetric_Platform_Merchandising_Performance'[ChannelGroup], "Platform")
VAR __LabelValue = SELECTEDVALUE('Dim_ColMetric_Platform_Merchandising_Performance'[Label_Value], "TTL")
VAR __IsTTL = (__LabelValue = "TTL")

// ── 指标路由 ──
VAR __ColType = SELECTEDVALUE('Dim_ColMetric_Platform_Merchandising_Performance'[ColType])

// ── This Period 时间区间（区间类指标 / TAR 分子 actual / TAR ACH% 分母）──
VAR __PeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Min_This[TimeFrame_Min])
VAR __PeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

// ── End Period 时间范围（期末时点类指标）──
VAR __EndPeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Min])
VAR __EndPeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

// ── TAR 分母区间（均以 TimeFrame_Max 所在财月 / 财年框定）──
VAR __MonthFirstDay = SELECTEDVALUE(Slicer_Time_Frame_Max_This[Fiscal_Month_First_Day])
VAR __MonthLastDay = SELECTEDVALUE(Slicer_Time_Frame_Max_This[Fiscal_Month_Last_Day])
VAR __YearFirstDay = SELECTEDVALUE(Slicer_Time_Frame_Max_This[Fiscal_Year_First_Day])
VAR __YearLastDay = SELECTEDVALUE(Slicer_Time_Frame_Max_This[Fiscal_Year_Last_Day])

// ── 时间粒度与跨期判定 ──
// 粒度读 Slicer_Time_Frame[TimeFrame_ID]；跨财月 / 跨财年判定不区分粒度，
// 直接比较 Min_This 与 Max_This 的财月 / 财年 value（文本类型，如 "2027-08" / "2027"）
VAR __TimeFrameID = SELECTEDVALUE(Slicer_Time_Frame[TimeFrame_ID])
VAR __IsCrossMonth =
    SELECTEDVALUE(Slicer_Time_Frame_Min_This[TimeFrame_Min_Month_Value])
        <> SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max_Month_Value])
VAR __IsCrossYear =
    SELECTEDVALUE(Slicer_Time_Frame_Min_This[TimeFrame_Min_Year_Value])
        <> SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max_Year_Value])

// ── 期末快照日：end period 范围内最后一个有数据的日期 ──
// REMOVEFILTERS 保证快照日不随行维度 / 商品切片器上下文漂移（全表最后一个快照日）
VAR __EndPeriodDate =
    CALCULATE(
        MAX('a02_e2e_product_performance_inv_summary_d'[data_date]),
        REMOVEFILTERS('a02_e2e_product_performance_inv_summary_d'),
        'a02_e2e_product_performance_inv_summary_d'[data_date] >= __EndPeriodMin,
        'a02_e2e_product_performance_inv_summary_d'[data_date] <= __EndPeriodMax
    )

// ── 渠道上下文过滤器（sales 侧 platform；UNION+FILTER 保证表类型稳定）──
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

// ── 渠道上下文过滤器（sales 侧 shop_name）──
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

// ── 渠道上下文过滤器（fcst 侧，与 sales 侧同构；a05 无 TTL 值，TTL 由 ALLSELECTED 汇总）──
VAR __FcstPlatformCtx =
    UNION(
        FILTER(
            ALLSELECTED('a05_e2e_product_fcst_data_d'[platform]),
            __IsTTL
        ),
        FILTER(
            ALLSELECTED('a05_e2e_product_fcst_data_d'[platform]),
            (NOT __IsTTL) && __ChannelGroup = "Store"
        ),
        FILTER(
            ALLSELECTED('a05_e2e_product_fcst_data_d'[platform]),
            (NOT __IsTTL) && __ChannelGroup = "Platform"
                && 'a05_e2e_product_fcst_data_d'[platform] = __LabelValue
        )
    )

// ── 渠道上下文过滤器（fcst 侧 shop_name）──
VAR __FcstShopNameCtx =
    UNION(
        FILTER(
            ALLSELECTED('a05_e2e_product_fcst_data_d'[shop_name]),
            __IsTTL
        ),
        FILTER(
            ALLSELECTED('a05_e2e_product_fcst_data_d'[shop_name]),
            (NOT __IsTTL) && __ChannelGroup = "Platform"
        ),
        FILTER(
            ALLSELECTED('a05_e2e_product_fcst_data_d'[shop_name]),
            (NOT __IsTTL) && __ChannelGroup = "Store"
                && 'a05_e2e_product_fcst_data_d'[shop_name] = __LabelValue
        )
    )

// ═══ SLS Amt（This Period；SLS Amt% 分子 + TAR 三指标共同的 actual）═══
VAR __SLSAmt_This =
    CALCULATE(
        SUM('a02_e2e_product_performance_sales_summary_d'[net_sales_amt]),
        __PlatformCtx,
        __ShopNameCtx,
        'a02_e2e_product_performance_sales_summary_d'[data_date] >= __PeriodMin,
        'a02_e2e_product_performance_sales_summary_d'[data_date] <= __PeriodMax
    )

// ═══ SLS Amt%（§34-§37 占比；分母 = 该列渠道全部行合计）═══
// 分母 ALLSELECTED 两个行维度字段（framework / category，均取自 Slicer_ 维度表）：
// 移除视觉对象内部行维度筛选，保留外部切片器；framework 上行时 category 无内部筛选
//（ALLSELECTED 为无操作），展开到 category 时同理——一套逻辑覆盖 §34-§36 与 §37
VAR __SLSAmt_Total_Channel =
    CALCULATE(
        SUM('a02_e2e_product_performance_sales_summary_d'[net_sales_amt]),
        __PlatformCtx,
        __ShopNameCtx,
        ALLSELECTED(Slicer_Framework[framework],Slicer_Framework[sort_order]),
        ALLSELECTED(Slicer_Category[category]),
        'a02_e2e_product_performance_sales_summary_d'[data_date] >= __PeriodMin,
        'a02_e2e_product_performance_sales_summary_d'[data_date] <= __PeriodMax
    )
VAR __SLSAmtPct = DIVIDE(__SLSAmt_This, __SLSAmt_Total_Channel)

// ═══ EOH（期末库存金额，仅 TTL 列；inv 表期末快照日单日时点，§38）═══
// 行维度经 Slicer_Framework / Slicer_Category 与 inv 一对多关系自动传导；
// inv 无渠道字段，渠道上下文不作用于库存侧
VAR __EOHAmt =
    CALCULATE(
        SUM('a02_e2e_product_performance_inv_summary_d'[msrp_inv_amt]),
        'a02_e2e_product_performance_inv_summary_d'[data_date] = __EndPeriodDate
    )

// ═══ ST%（售罄率%金额，仅 TTL 列，§39）═══
// 分子: This Period SLS Amt（TTL 渠道上下文 + 行维度关系传导）
// 分母: This Period SLS Amt + 期末快照日单日库存金额；任一侧 BLANK 按 0 参与加法
//（DAX 算术运算 BLANK 当 0），两侧均空时 DIVIDE 返回 BLANK
VAR __STPct = DIVIDE(__SLSAmt_This, __SLSAmt_This + __EOHAmt)

// ═══ TAR target（a05 三区间汇总，渠道上下文与 sales 侧同构，行维度关系自动传导）═══
// a05 与日期筛选器断开维度，三区间均为度量值内显式 data_date 过滤
VAR __FcstAmt_This =
    CALCULATE(
        SUM('a05_e2e_product_fcst_data_d'[fcst_sales_amt]),
        __FcstPlatformCtx,
        __FcstShopNameCtx,
        'a05_e2e_product_fcst_data_d'[data_date] >= __PeriodMin,
        'a05_e2e_product_fcst_data_d'[data_date] <= __PeriodMax
    )
VAR __FcstAmt_MTD =
    CALCULATE(
        SUM('a05_e2e_product_fcst_data_d'[fcst_sales_amt]),
        __FcstPlatformCtx,
        __FcstShopNameCtx,
        'a05_e2e_product_fcst_data_d'[data_date] >= __MonthFirstDay,
        'a05_e2e_product_fcst_data_d'[data_date] <= __MonthLastDay
    )
VAR __FcstAmt_YTD =
    CALCULATE(
        SUM('a05_e2e_product_fcst_data_d'[fcst_sales_amt]),
        __FcstPlatformCtx,
        __FcstShopNameCtx,
        'a05_e2e_product_fcst_data_d'[data_date] >= __YearFirstDay,
        'a05_e2e_product_fcst_data_d'[data_date] <= __YearLastDay
    )

// ═══ TAR ACH%（达成率；全粒度 date to date，分子分母均 This Period 区间）═══
VAR __TARAchPct = DIVIDE(__SLSAmt_This, __FcstAmt_This)

// ═══ MTD TAR Progress（月度进度；actual 恒为 This Period，分母区间随粒度分支）═══
VAR __MTDProgress =
    SWITCH(
        TRUE(),
        // Day / Week：不跨财月 → This actual / 所在财月汇总 target；跨财月 → 不计算
        __TimeFrameID IN {"Day", "Week"},
            IF(__IsCrossMonth, BLANK(), DIVIDE(__SLSAmt_This, __FcstAmt_MTD)),
        // Month：分子分母始终和 This Period 区间一致
        __TimeFrameID = "Month",
            DIVIDE(__SLSAmt_This, __FcstAmt_This),
        // Quarter / Year 及其他：不计算
        BLANK()
    )

// ═══ YTD TAR Progress（年度进度；actual 恒为 This Period，分母区间随粒度分支）═══
VAR __YTDProgress =
    SWITCH(
        TRUE(),
        // Day / Week / Month / Quarter：不跨财年 → This actual / 所在财年汇总 target；跨财年 → 不计算
        __TimeFrameID IN {"Day", "Week", "Month", "Quarter"},
            IF(__IsCrossYear, BLANK(), DIVIDE(__SLSAmt_This, __FcstAmt_YTD)),
        // Year：始终计算，分子分母始终和 This Period 区间一致
        __TimeFrameID = "Year",
            DIVIDE(__SLSAmt_This, __FcstAmt_This),
        // 其他：不计算
        BLANK()
    )

RETURN
    SWITCH(
        __ColType,
        "SLS Amt%",         __SLSAmtPct,      // SLS Amt% Act（§34-§37，随行维度切换承载占比）
        "EOH",              __EOHAmt,         // EOH Act（仅 TTL 列）
        "ST%",              __STPct,          // ST% Act（仅 TTL 列）
        "TAR ACH%",         IF(ISBLANK(__TARAchPct)&& NOT ISBLANK(__SLSAmtPct),"-",__TARAchPct),      // TAR ACH% Act（全部 Label 列，渠道上下文随列位置）
        "MTD TAR Progress", IF(ISBLANK(__MTDProgress)&& NOT ISBLANK(__SLSAmtPct),"-",__MTDProgress),    // MTD TAR Progress Act
        "YTD TAR Progress", IF(ISBLANK(__YTDProgress)&& NOT ISBLANK(__SLSAmtPct),"-",__YTDProgress),    // YTD TAR Progress Act
        BLANK()
    )

// ========================================
// 尾部注释: TAR 三指标 × 五粒度计算矩阵（actual 恒为 This Period 区间）
//   指标             Day             Week            Month           Quarter        Year
//   TAR ACH%         This/This       This/This       This/This       This/This      This/This
//   MTD Progress     不跨月:This/财月 跨月:BLANK     同Day           This/This      BLANK          BLANK
//   YTD Progress     不跨年:This/财年 跨年:BLANK     同Day           同Day          同Day          This/This
//   财月区间 = [Fiscal_Month_First_Day, Fiscal_Month_Last_Day]（TimeFrame_Max 所在财月）
//   财年区间 = [Fiscal_Year_First_Day, Fiscal_Year_Last_Day]（TimeFrame_Max 所在财年）
// ========================================
```

### 4.2 Platform Merchandising LY Base Value（Last Period 基线）

```dax
Platform Merchandising LY Base Value =
// ========================================
// 度量值: Platform Merchandising LY Base Value
// Display Folder: Platform Merchandising Performance\Base Metrics
// 用途: vs LP 派生指标的 Last Period 基线 = SLS Amt% Last（LP 分子 / LP 分母，
//       分母 ALLSELECTED 行维度与 This 侧同构），渠道上下文与 Act Base Value 完全一致
//       （同列同渠道对比）
// 说明: 仅在 Base Value 总路由的 vs LP 分支中被调用（ColType = "vs LP" 时有效）；
//       Last Period 直接读 Slicer_Time_Frame_Min_Last / Max_Last 筛选器
// 汇率换算: 不在此度量值处理，保持原始 RMB；占比为比率不受币种影响
// ========================================

// ── 渠道路由 ──
VAR __ChannelGroup = SELECTEDVALUE('Dim_ColMetric_Platform_Merchandising_Performance'[ChannelGroup], "Platform")
VAR __LabelValue = SELECTEDVALUE('Dim_ColMetric_Platform_Merchandising_Performance'[Label_Value], "TTL")
VAR __IsTTL = (__LabelValue = "TTL")

// ── 指标路由（仅 vs LP 列有效）──
VAR __ColType = SELECTEDVALUE('Dim_ColMetric_Platform_Merchandising_Performance'[ColType])

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

// ═══ LP SLS Amt%（vs LP 基线；分子 = LP SLS Amt，分母 = 同渠道上下文 + ALLSELECTED 行维度）═══
VAR __SLSAmt_Last =
    CALCULATE(
        SUM('a02_e2e_product_performance_sales_summary_d'[net_sales_amt]),
        __PlatformCtx,
        __ShopNameCtx,
        'a02_e2e_product_performance_sales_summary_d'[data_date] >= __PeriodMin_LY,
        'a02_e2e_product_performance_sales_summary_d'[data_date] <= __PeriodMax_LY
    )
VAR __SLSAmt_Total_LP =
    CALCULATE(
        SUM('a02_e2e_product_performance_sales_summary_d'[net_sales_amt]),
        __PlatformCtx,
        __ShopNameCtx,
        ALLSELECTED(Slicer_Framework[framework],Slicer_Framework[sort_order]),
        ALLSELECTED(Slicer_Category[category]),
        'a02_e2e_product_performance_sales_summary_d'[data_date] >= __PeriodMin_LY,
        'a02_e2e_product_performance_sales_summary_d'[data_date] <= __PeriodMax_LY
    )

RETURN
    IF(
        __ColType = "vs LP",
        DIVIDE(__SLSAmt_Last, __SLSAmt_Total_LP)
    )
```

### 4.3 Platform Merchandising Base Value（总路由）

```dax
Platform Merchandising Base Value =
// ========================================
// 度量值: Platform Merchandising Base Value
// Display Folder: Platform Merchandising Performance\Base Metrics
// 用途: 总路由，按 ColType 分发
//       - vs LP → SLS Amt% This - SLS Amt% Last（占比差值原始小数，×10000 转 bp 在 Display 层）
//       - 其余 6 种 ColType → 直接取 Act Base Value
//
// vs LP 分子重路由机制（整表 REMOVEFILTERS + 三条件重建）:
//   矩阵列头三层（ChannelGroup > Label > ColName）在视觉对象查询（SUMMARIZECOLUMNS）中
//   以 GroupBy 组合筛选形式存在，REMOVEFILTERS(Dim[ColName]) 单列写法无法从组合筛选中
//   剥离 ColName 部分——ColName（vs LP 列）筛选残留，与新加的 ColType = "SLS Amt%" 互斥
//   → Dim 表空集 → 分子始终 BLANK
//   正确做法：CALCULATE 外先捕获当前列 ChannelGroup / Label_Value 标量值，
//   REMOVEFILTERS(整表) 清除断开维度全部筛选，再以 ChannelGroup + Label_Value +
//   ColType = "SLS Amt%" 三条件重建，唯一定位同渠道的 SLS Amt% 列取分子
//
// 空值规则: 差值任一侧为空时 vs LP 返回 BLANK
// ========================================
    VAR __ColType = SELECTEDVALUE('Dim_ColMetric_Platform_Merchandising_Performance'[ColType])
    VAR __IsVsLP = (__ColType = "vs LP")

    // ── vs LP 分子：当前列渠道上下文下的 This Period SLS Amt% ──
    // 先捕获标量再清筛选：整表 REMOVEFILTERS 后按三条件重建，避免组合筛选残留互斥
    VAR __ChannelGroup = SELECTEDVALUE('Dim_ColMetric_Platform_Merchandising_Performance'[ChannelGroup])
    VAR __LabelValue = SELECTEDVALUE('Dim_ColMetric_Platform_Merchandising_Performance'[Label_Value])
    VAR __SLSAmtPct_This =
        IF(
            __IsVsLP,
            CALCULATE(
                [Platform Merchandising Act Base Value],
                REMOVEFILTERS('Dim_ColMetric_Platform_Merchandising_Performance'),
                'Dim_ColMetric_Platform_Merchandising_Performance'[ChannelGroup] = __ChannelGroup,
                'Dim_ColMetric_Platform_Merchandising_Performance'[Label_Value] = __LabelValue,
                'Dim_ColMetric_Platform_Merchandising_Performance'[ColType] = "SLS Amt%"
            )
        )

    // ── vs LP 分母：当前列渠道上下文下的 Last Period SLS Amt% ──
    VAR __SLSAmtPct_Last =
        IF(
            __IsVsLP,
            [Platform Merchandising LY Base Value]
        )

    // ── vs LP = SLS Amt% This - SLS Amt% Last（差值原始小数）──
    VAR __vsLPResult =
        IF(
            __IsVsLP,
            IF(
                ISBLANK(__SLSAmtPct_This) || ISBLANK(__SLSAmtPct_Last),
                BLANK(),
                __SLSAmtPct_This - __SLSAmtPct_Last
            )
        )

    RETURN
        IF(
            __IsVsLP,
            __vsLPResult,                                // vs LP（12 列，每组各 Label 下 1 列）
            [Platform Merchandising Act Base Value]      // 其余 6 种 ColType 直接取 Act
        )
```

### 4.4 Platform Merchandising Cell Value（对外值，含汇率换算）

```dax
Platform Merchandising Cell Value =
// ========================================
// 度量值: Platform Merchandising Cell Value
// Display Folder: Platform Merchandising Performance\Cell Values
// 用途: 对外暴露的单元格值
//       - 金额类（Metric_IsCurrencyAmount = TRUE：EOH）→ 按汇率换算
//       - 其余（比率类 / bp 差值类）→ 直接返回 Base Value，不换算
// 依赖: [Platform Merchandising Base Value],
//       'Dim_ColMetric_Platform_Merchandising_Performance'[Metric_IsCurrencyAmount],
//       Slicer_Currency_Selection[Currency_ExchangeRate]
//
// 汇率换算规则:
//   - 数据底表存储 RMB 原始值，USD 时通过 ÷ Currency_ExchangeRate 换算
//   - RMB 时 Currency_ExchangeRate = 1，换算前后值相同
//   - Base Value 层始终保留 RMB 原始值，确保派生计算口径一致；换算集中在展示层
//   - TAR 类比率为 actual / target 同币种相除，SLS Amt% / ST% / vs LP 为比率或差值，
//     均不受币种选择影响（Metric_IsCurrencyAmount = FALSE 不换算）
// ========================================
    VAR __BaseValue = [Platform Merchandising Base Value]
    VAR __IsCurrencyAmount = SELECTEDVALUE('Dim_ColMetric_Platform_Merchandising_Performance'[Metric_IsCurrencyAmount], FALSE)
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

### 4.5 Platform Merchandising Cell Display（格式化显示）

```dax
Platform Merchandising Cell Display =
// ========================================
// 度量值: Platform Merchandising Cell Display
// Display Folder: Platform Merchandising Performance\Formatting
// 用途: 按 Metric_Format 单字段格式化显示
// 依赖: [Platform Merchandising Cell Value],
//       'Dim_ColMetric_Platform_Merchandising_Performance'[Metric_Format],
//       Slicer_Currency_Selection[Currency_Symbol]
//
// 格式类型（口径文档子模块八 §34-§39 数据类型 + 附属指标类型）:
//   percent_0dp → FORMAT(__Value, "#,##0%") 百分比整数，不含正号
//                 （SLS Amt% / ST% / TAR ACH% / MTD TAR Progress / YTD TAR Progress）
//   currency    → __CurrencySymbol & FORMAT(__Value, "#,##0")（EOH，符号由币种切片器决定，§38）
//   integer_bp  → FORMAT(__Value * 10000, "#,##0") & "bp"（vs LP 占比差值 ×10000 转 bp；
//                 负数自带负号、零值 0bp、不含正号；本模块为矩阵纯展示场景，
//                 ×10000 转换在 Display 层完成，Value 层保持原始差值小数）
//
// 空值规则: BLANK 返回 BLANK()（非 "-"）——矩阵在检测到该行所有度量值均为 BLANK() 时
//           自动隐藏该行（包括层级行），TAR 类"不计算"场景（跨财月 / 跨财年 / Quarter / Year
//           的 MTD 等）经此机制一并消化
// ========================================
    VAR __Value = [Platform Merchandising Cell Value]
    VAR __Format = SELECTEDVALUE('Dim_ColMetric_Platform_Merchandising_Performance'[Metric_Format])
    VAR __CurrencySymbol = SELECTEDVALUE(Slicer_Currency_Selection[Currency_Symbol], "¥")

    RETURN
        IF(
            ISBLANK(__Value),
            BLANK(),
            SWITCH(
                __Format,
                // ─── 金额类（货币符号 + 千分位整数）───
                "currency",
                    __CurrencySymbol & FORMAT(__Value, "#,##0"),                                    // ¥640,299
                // ─── 百分比整数，不含正号（占比 / 售罄率 / TAR 类）───
                "percent_0dp",
                    FORMAT(__Value, "#,##0%"),                                                       // 26%
                // ─── bp 差值（占比差值 ×10000 转 bp，不含正号）───
                "integer_bp",
                    FORMAT(__Value * 10000, "#,##0") & "bp",                                         // -152bp / 0bp
                // ─── 扩展格式（便于后续快速调整）───
                "percent_1dp",
                    FORMAT(__Value, "#,##0.0%"),                                                    // 26.5%
                "delta_pct_0dp",
                    IF(__Value > 0, "+", "") & FORMAT(__Value, "#,##0%"),                           // +26% / -3%
                "delta_pct_1dp",
                    IF(__Value > 0, "+", "") & FORMAT(__Value, "#,##0.0%"),                         // +14.5%
                "integer",
                    FORMAT(__Value, "#,##0"),                                                       // 3,160
                "decimal_1dp",
                    FORMAT(__Value, "#,##0.0"),                                                     // 203.5
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
                // ─── 默认 ─────────────────────────────────
                FORMAT(__Value, "#,##0.00")
            )
        )
```

### 4.6 Platform Merchandising Cell Font Color（字体颜色）

```dax
Platform Merchandising Cell Font Color =
// ========================================
// 度量值: Platform Merchandising Cell Font Color
// Display Folder: Platform Merchandising Performance\Formatting
// 用途: 按 Metric_ColorRule 字段分发字体颜色
// 依赖: [Platform Merchandising Cell Value],
//       'Dim_ColMetric_Platform_Merchandising_Performance'[Metric_ColorRule,
//        Metric_ColorPositive/Negative/Zero/Default]
//
// 颜色规则:
//   1. 全部基础指标列（SLS Amt% / EOH / ST% / TAR ACH% / MTD TAR Progress /
//      YTD TAR Progress）固定 #252423 → "fixed_black"
//   2. vs LP（差值为正 / 负 / 零三色）→ "pos_neg_zero"
// ========================================
    VAR __Value = [Platform Merchandising Cell Value]
    VAR __ColorRule = SELECTEDVALUE('Dim_ColMetric_Platform_Merchandising_Performance'[Metric_ColorRule], "fixed_default")
    VAR __ColorPositive = SELECTEDVALUE('Dim_ColMetric_Platform_Merchandising_Performance'[Metric_ColorPositive], "#1A9018")
    VAR __ColorNegative = SELECTEDVALUE('Dim_ColMetric_Platform_Merchandising_Performance'[Metric_ColorNegative], "#D64550")
    VAR __ColorZero = SELECTEDVALUE('Dim_ColMetric_Platform_Merchandising_Performance'[Metric_ColorZero], "#E1C233")
    VAR __ColorDefault = SELECTEDVALUE('Dim_ColMetric_Platform_Merchandising_Performance'[Metric_ColorDefault], "#5F6165")

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

### 4.7 Platform Merchandising Cell Background Color（背景色）

```dax
Platform Merchandising Cell Background Color =
// ========================================
// 度量值: Platform Merchandising Cell Background Color
// Display Folder: Platform Merchandising Performance\Formatting
// 用途: 区分 ColName 层（指标列）与上层（Label / ChannelGroup）的背景色
// 依赖: ISINSCOPE('Dim_ColMetric_Platform_Merchandising_Performance'[ColName])
// ========================================
    VAR __IsMetricCol = ISINSCOPE('Dim_ColMetric_Platform_Merchandising_Performance'[ColName])
    RETURN
        IF(
            __IsMetricCol,
            "#FFFFFF",   // ColName 层（指标列）: 白色
            "#E6D9C7"    // Label / ChannelGroup 层: 中米色
        )
```

---

## 5. 度量值清单与 Display Folder

| 序号 | 度量值名称                                   | Display Folder | 用途                                                                                       |
| ---- | -------------------------------------------- | -------------- | ------------------------------------------------------------------------------------------ |
| 1    | Platform Merchandising Act Base Value        | Base Metrics   | This Period 基础值（6 种基础 ColType）；渠道上下文 + ColType 路由 + TAR 粒度分支；RMB 原值 |
| 2    | Platform Merchandising LY Base Value         | Base Metrics   | Last Period SLS Amt% 基线（vs LP 分母，占比差值双期口径）                                  |
| 3    | Platform Merchandising Base Value            | Base Metrics   | 总路由（vs LP 派生 + 整表 REMOVEFILTERS + 渠道三条件重路由；其余直接取 Act）；64 列全覆盖  |
| 4    | Platform Merchandising Cell Value            | Cell Values    | 对外值：金额类（EOH）汇率换算（÷ Currency_ExchangeRate）                                  |
| 5    | Platform Merchandising Cell Display          | Formatting     | 格式化显示文本（percent_0dp / currency / integer_bp + 扩展格式）；空值返回 BLANK()         |
| 6    | Platform Merchandising Cell Font Color       | Formatting     | 字体颜色（基础指标 = fixed_black；vs LP = pos_neg_zero 三色）                              |
| 7    | Platform Merchandising Cell Background Color | Formatting     | 背景色（ColName 层 #FFFFFF vs 上层 #E6D9C7）                                               |

---

## 6. 血缘关系图

```
┌─────────────────────────────────────────────────────────────────────┐
│                        数据源层                                      │
│  a02_e2e_product_performance_sales_summary_d（销售类，日粒度）       │
│  字段: data_date, platform, shop_name, framework, category,         │
│        brand, ..., net_sales_amt                                    │
│  a02_e2e_product_performance_inv_summary_d（库存类，日快照）        │
│  字段: data_date + 商品维度（与 sales 同名同构，无渠道字段）,        │
│        msrp_inv_amt                                                 │
│  a05_e2e_product_fcst_data_d（目标类）                              │
│  字段: data_date, platform, shop_name, brand, framework,            │
│        category, fcst_sales_amt（无 TTL 预聚合值）                  │
└─────────────────────────────┬───────────────────────────────────────┘
                              │ 行维度 / 渠道 / 品牌切片器 1:N 自动传递
                              │ （日期筛选器断开维度，区间在度量值内显式过滤）
                              ▼
┌─────────────────────────────────────────────────────────────────────┐
│                        度量值层                                      │
│                                                                     │
│  ┌───────────────────────────┐   ┌───────────────────────────┐      │
│  │ Platform Merchandising    │   │ Platform Merchandising    │      │
│  │ Act Base Value            │   │ LY Base Value             │      │
│  │ (This Period + 期末快照   │   │ (Last Period SLS Amt%)    │      │
│  │  + TAR 三区间 target)     │   └────────────┬──────────────┘      │
│  └────────────┬──────────────┘                │                     │
│               │        ┌──────────────────────────────┐             │
│               │◄───────│ Dim_ColMetric_Platform_       │             │
│               │        │ Merchandising_Performance     │             │
│               │        │ (ChannelGroup / Label /       │             │
│               │        │  Label_Value / ColType)       │             │
│               │        ├──────────────────────────────┤             │
│               │◄───────│ Slicer_Time_Frame[_Min/Max_   │             │
│               │        │ This / _Min/Max_Last]         │             │
│               │        │ (粒度 / 区间 / 财月财年字段)   │             │
│               ▼        └──────────────────────────────┘             │
│  ┌──────────────────────────────────────────────────────┐           │
│  │ Platform Merchandising Base Value                    │           │
│  │ (总路由: vs LP = SLS Amt% This - Last，整表           │           │
│  │  REMOVEFILTERS + 渠道三条件重路由取分子；             │           │
│  │  其余 6 种直接取 Act)                                │           │
│  └───────────────────────┬──────────────────────────────┘           │
│                          ▼                                          │
│  ┌──────────────────────────────────────────────────────┐           │
│  │ Platform Merchandising Cell Value                    │           │
│  │ (金额类 EOH 汇率换算 ÷ Currency_ExchangeRate)        │           │
│  │          ▲ Slicer_Currency_Selection                 │           │
│  └───────────────────────┬──────────────────────────────┘           │
│                          ▼                                          │
│  ┌──────────────────────────────────────────────────────┐           │
│  │ Platform Merchandising Cell Display                  │           │
│  │ (按 Metric_Format 格式化 + Currency_Symbol 拼接；     │           │
│  │  空值返回 BLANK() 支撑行自动隐藏)                     │           │
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
│  行: Slicer_Framework[framework] > Slicer_Category[category]        │
│      （framework 按 sort_order 按列排序）                           │
│  列: 'Dim_ColMetric_Platform_Merchandising_Performance'[ChannelGroup]│
│      > [Label] > [ColName]（ChannelGroup_Sort / Label_Sort /        │
│      ColName_Sort 排序）                                             │
│  值: [Platform Merchandising Cell Display]                          │
│  条件格式: 字体颜色 → Cell Font Color；背景色 → Cell Background     │
│  行为: 整行所有度量值 BLANK 时自动隐藏（含层级），无需额外筛选器      │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 7. 注意事项

1. **TAR 类口径核心**：三指标分子（actual）恒为 This Period 区间的 sales[net_sales_amt]，分母（target）区间随粒度分支——TAR ACH% 全粒度 date to date（This / This）；MTD Progress 在 Day / Week 不跨财月时取 TimeFrame_Max 所在财月汇总 target（财月区间可超出 This Period，即"本月进度"）、Month 为 This / This、Quarter / Year 不计算；YTD Progress 在 Day / Week / Month / Quarter 不跨财年时取 TimeFrame_Max 所在财年汇总 target、Year 始终计算且为 This / This。"不计算"返回 BLANK，经 Display 的 BLANK() 返回参与整行自动隐藏。
2. **跨财月 / 跨财年判定**：不区分粒度，直接比较 Min_This 与 Max_This 两表的 Month_Value / Year_Value 字段（财月年均为文本类型，如 "2027-08" / "2027"）；时间粒度另行读取 `SELECTEDVALUE(Slicer_Time_Frame[TimeFrame_ID])`。两表各自独立被切片器筛选、互相无关系，SELECTEDVALUE 后拼接比较。
3. **a05 无 TTL 预聚合值**：TTL 列 target 由 ALLSELECTED(a05[platform]) / ALLSELECTED(a05[shop_name]) 汇总取得（与 sales 侧同构），明细列按 Label_Value 直接过滤 a05 渠道字段；不存在汇总行重复计数问题。a05 与日期筛选器断开维度，target 三区间均为度量值内显式 data_date 过滤。
4. **行维度关系传导**：矩阵行取自 Slicer_Framework[framework] / Slicer_Category[category] 维度表字段，与 sales / inv / a05 三张事实表均为一对多关联，行筛选自动传导——inv 侧（EOH / ST% 库存）与 fcst 侧（target）均无需 TREATAS 桥接。若模型中任一维度表与某事实表未建关系，对应侧需补建关系或回退 TREATAS 显式传递。
5. **SLS Amt% 分母口径**：该列渠道上下文 + ALLSELECTED(Slicer_Framework[framework],Slicer_Framework[sort_order]) + ALLSELECTED(Slicer_Category[category])（该列渠道全部行合计）。口径文档待确认项「Platform Merchandising Category SLS Amt% 分母范围」按列指标表「SLS Amt% 路由键 + 行维度切换」设计实现；若业务确认为其他分母（如全局合计），仅需调整 `__SLSAmt_Total_Channel` 的 ALLSELECTED 范围（同步调整 LY Base Value 的 `__SLSAmt_Total_LP`）。
6. **vs LP 分子重路由必须整表 REMOVEFILTERS 的原因**：矩阵列头三层（ChannelGroup > Label > ColName）在视觉对象查询（SUMMARIZECOLUMNS）中以 GroupBy 组合筛选形式存在，`REMOVEFILTERS(Dim[ColName])` 单列写法无法从组合筛选中剥离 ColName 部分，残留的 ColName（vs LP 列）筛选与新加的 `ColType = "SLS Amt%"` 互斥 → Dim 表空集 → 分子始终 BLANK；正确模式 = CALCULATE 外捕获 ChannelGroup / Label_Value 标量 + `REMOVEFILTERS(整表)` + 三条件重建（ChannelGroup + Label_Value + ColType 唯一定位单行）。ChannelGroup / Label 层汇总单元格无唯一 ColType → BLANK。
7. **vs LP 为占比差值 bp 口径**：SLS Amt% This - SLS Amt% Last（差值原始小数），×10000 转 bp 在 Display 层完成（本模块为矩阵纯展示场景，无 Y 轴 / 数值排序绑定）；落地格式不含正号（-152bp / 0bp）。若后续 vs LP 需绑定图表 Y 轴或数值排序，×10000 需移至 Value 层并同步调整 Display。
8. **TTL 的 ALLSELECTED 语义**：TTL 列对 [platform] / [shop_name] 应用 ALLSELECTED——移除视觉对象内部的渠道筛选，保留外部切片器，即外部筛选上下文下的全渠道合计；不选或多选 Label 时 SELECTEDVALUE 默认 "TTL"。
9. **非 TTL 列与外部渠道切片器的交集关系**：Platform / Store 列的渠道过滤基于 ALLSELECTED 集与 Label_Value 取交集。如外部 platform 切片器仅选 TM，则 JD 列返回空（外部切片器限定数据范围）。
10. **inv 表无渠道字段**：a02_e2e_product_performance_inv_summary_d 无 platform / shop_name，渠道上下文不作用于库存侧；EOH / ST% 仅 TTL 列展示，其值实际为全渠道口径。
11. **期末快照日机制**：`__EndPeriodDate` 取 end period 范围 [Max_This[TimeFrame_Min], Max_This[TimeFrame_Max]] 内最后一个有数据的快照日，用 REMOVEFILTERS(inv) 计算，保证快照日不随行维度 / 商品切片器漂移；快照缺数时自动回退到范围内最近一天。
12. **汇率换算分层**：Base Value 层始终保留 RMB 原始值；换算集中在 Cell Value（÷ Currency_ExchangeRate，RMB 时汇率 = 1，仅 EOH 金额类）；Cell Display 只拼接 Currency_Symbol。金额类判定用 Metric_IsCurrencyAmount；TAR / SLS Amt% / ST% / vs LP 为比率或差值，不受币种影响。
13. **Display 空值返回 BLANK()**：区别于文本 "-" 占位，空值一律返回 BLANK()，使矩阵在整行所有度量值均为 BLANK 时自动隐藏该行（包括 framework / category 层级行），无需额外 IsEmpty 视觉级筛选器。
14. **字段名已核对数据字典**：net_sales_amt / platform / shop_name / framework / category（sales 表）；msrp_inv_amt（inv 表）；fcst_sales_amt / data_date / platform / shop_name / brand / framework / category（a05 表）；日期字段统一为 data_date（date 类型）。
15. **DAX 语法规范**：文本常量使用双引号，单引号仅用于表名，列名使用方括号；渠道上下文过滤器用 UNION + FILTER 构造（IF 分支返回表会被降级为标量）；与口径文档存在争议时一切以口径文档为准。
