# Merchandising Core KPI 矩阵解决方案

> **版本**: v1.1
> **模块**: RL E2E Merch Dashboard - Merchandise Performance Overview Tab - Merchandising Core KPI
> **关联口径**: 口径文档/口径Markdown格式/Merchandise Performance Overview.md - 子模块一【Amt】（§1-§10）+ 子模块二【Unit】（§11-§20）+ 口径文档/口径Markdown格式/actual除target逻辑详情.md（TAR 类指标五粒度规则）
> **数据底表（销售类）**: a02_e2e_product_performance_sales_summary_d
> **数据底表（库存类）**: a02_e2e_product_performance_inv_summary_d
> **数据底表（目标类）**: a05_e2e_product_fcst_data_d
> **关联维度**: Dim_ColMetric_Merchandising_Core_KPI（列）、IsAmtUnitFilter（Amt/Unit 按钮）、IsProductTagFilter（商品标签按钮）、Slicer_Time_Frame（时间粒度）、Slicer_Time_Frame_Min_This / Max_This / Min_Last / Max_Last（时间）、Slicer_Currency_Selection（币种）
> **参考方案**: Customer_Breakdown_ms.md（仅分层结构与书写风格参考，具体口径以 Merch 口径文档 + 提示词第 1~7 点为准）

---

## 1. 需求理解

### 1.1 模块定位

Merchandising Core KPI 是 Merchandise Performance Overview Tab 的核心 KPI 矩阵，覆盖 10 个 KPI 分组（SLS / ST% / AVG MD / Fullprice% / AUR / EOH / In-Transit Inventory / O2O Inventory / Inbound / Outbound）× 主指标 + 附属指标 = 21 列（SLS 组 5 列：SLS / SLS vs LY / TAR ACH% / MTD TAR Progress / YTD TAR Progress）。
【Amt】与【Unit】指标数量、结构完全一致，共用单套 21 列，由 Amt/Unit 按钮切换计算逻辑。
TAR 类三指标（TAR ACH% / MTD TAR Progress / YTD TAR Progress）同时用于卡片图：每张卡片通过视觉级筛选器固定 Dim[ColName] 为唯一值，与矩阵共用同一套度量值。

### 1.2 路由维度

| 路由维度                               | 来源表                               | 类型         | 说明                                                                                                           |
| -------------------------------------- | ------------------------------------ | ------------ | -------------------------------------------------------------------------------------------------------------- |
| Amt / Unit                             | IsAmtUnitFilter                      | 断开按钮维度 | SELECTEDVALUE([Sort])：=10 → Amt 逻辑；=20 → Unit 逻辑；默认 Amt（未选时取 10）                              |
| ALL / Hero Model / Slow Mover / Normal | IsProductTagFilter                   | 断开按钮维度 | computed_product_tag 过滤：选中 "ALL" → IN {"hero model", "slow mover", "normal"}；其余 → 单值匹配；默认 ALL |
| Metric_ID（10 组 21 列）               | Dim_ColMetric_Merchandising_Core_KPI | 断开列维度   | Act / vs LY / TAR ACH% / MTD TAR Progress / YTD TAR Progress 列路由                                              |

**与 Customer Breakdown 方案的关键差异**：

1. 行路由从 Net/Demand（Dim_RowMetric）改为 **Amt/Unit 按钮 + 商品标签按钮**（两个断开按钮维度）
2. LY 不再使用 _LY 字段对称映射，改为**直接读 Last Period 筛选器**（Min_Last / Max_Last 表的 TimeFrame_Min / TimeFrame_Max）
3. 新增**期末时点口径**（EOH / In-Transit / O2O / ST% 分母）：end period 范围内最后一个快照日
4. 格式驱动为 **Metric_Format_Amt / Metric_Format_Unit 双列**（按模式取一），金额类为 currency（非 currency_M_K_Int_0db），比率类 vs LY 为 delta_bp（基点）
5. TAR 类三指标（TAR ACH% / MTD TAR Progress / YTD TAR Progress）为 actual ÷ target 真实现（占位符已废弃）：actual 按 Amt/Unit 模式路由 sales 金额/数量字段，target 按模式路由 a05[fcst_sales_amt] / [fcst_sales_qty]，分母区间随时间粒度分支（读 Slicer_Time_Frame[TimeFrame_ID]）

### 1.3 时间口径

| 口径                     | 时间范围                                                                                                                          | 适用指标                                                  |
| ------------------------ | --------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------- |
| This Period（区间类）    | data_date ∈ [Slicer_Time_Frame_Min_This[TimeFrame_Min], Slicer_Time_Frame_Max_This[TimeFrame_Max]]                               | SLS、AVG MD、Fullprice%、AUR、Inbound、Outbound、ST% 分子 |
| Last Period（LY 对比）   | data_date ∈ [Slicer_Time_Frame_Min_Last[TimeFrame_Min], Slicer_Time_Frame_Max_Last[TimeFrame_Max]]                               | 上述全部指标的 LY 基线                                    |
| End Period（期末时点类） | end period 范围 [Slicer_Time_Frame_Max_This[TimeFrame_Min], Slicer_Time_Frame_Max_This[TimeFrame_Max]] 内**最后一个快照日** | EOH、In-Transit、O2O、ST% 分母                            |
| End Period LY            | end period 范围 [Slicer_Time_Frame_Max_Last[TimeFrame_Min], Slicer_Time_Frame_Max_Last[TimeFrame_Max]] 内**最后一个快照日** | 上述期末类指标的 LY 基线                                  |
| target MTD 区间          | [Slicer_Time_Frame_Max_This[Fiscal_Month_First_Day], Slicer_Time_Frame_Max_This[Fiscal_Month_Last_Day]]（TimeFrame_Max 所在财月） | MTD TAR Progress 分母（Day / Week 不跨财月）              |
| target YTD 区间          | [Slicer_Time_Frame_Max_This[Fiscal_Year_First_Day], Slicer_Time_Frame_Max_This[Fiscal_Year_Last_Day]]（TimeFrame_Max 所在财年） | YTD TAR Progress 分母（Day / Week / Month / Quarter 不跨财年） |

说明：

- 没有特殊说明的情况下，计算 LY 时使用 Last Period 特定筛选器的结果作为上期时间范围对比
- ST% 这类跨双表指标需留意：sales 部分（分子）是整个 This Period 的区间汇总，inv 部分（分母）只看 end period 范围的最后一天，不能混用
- 期末时点类实现为「end period 范围内最后一个有数据的快照日」：口径定义为 end period 最后一天，快照缺数时自动回退到范围内最近一天，避免整段空值
- 快照表按日存储，期末时点**只取单日**，若对 end period 整段区间求和会把库存重复计数
- TAR 类三指标：actual 恒为 This Period 区间（Amt 模式 = sum(net_sales_amt)，Unit 模式 = sum(net_sales_qty)，均受商品标签过滤）；TAR ACH% 全粒度 date to date；时间粒度读 SELECTEDVALUE(Slicer_Time_Frame[TimeFrame_ID])；跨财月判定不区分粒度，比较 Min_This[TimeFrame_Min_Month_Value] 与 Max_This[TimeFrame_Max_Month_Value]（财月 value，文本），不相等 → 跨财月；跨财年判定同理比较两表 Year_Value 字段

---

## 2. 现状分析

- 数据底表 `a02_e2e_product_performance_sales_summary_d`（日粒度）：net_sales_amt / net_sales_qty / md_net_sales_amt / msrp_net_sales_amt / msrp_inbound_amt / inbound_qty / md_outbound_amt / outbound_qty，维度含 platform、shop_name、md_type、computed_product_tag 及全部商品维度；platform 已在数据源层过滤 IN ('JD','TM','RLE','DY')
- 数据底表 `a02_e2e_product_performance_inv_summary_d`（日快照）：msrp_inv_amt / inv_qty / msrp_in_trans_inv_amt / in_trans_inv_qty / msrp_o2o_inv_amt / o2o_inv_qty，维度含 computed_product_tag 及商品维度；**无 platform / shop_name 字段**（渠道筛选不影响库存侧指标）
- 数据底表 `a05_e2e_product_fcst_data_d`（目标类）：data_date（date 类型）、platform、shop_name、brand、framework、category、fcst_sales_amt（金额目标）、fcst_sales_qty（数量目标）；**无 computed_product_tag 字段**（target 侧无法按商品标签过滤）；渠道 / 商品维度切片器与该表一对多关联自动传导；与日期筛选器断开维度
- 列维度表 `Dim_ColMetric_Merchandising_Core_KPI` 已存在（本目录，21 行），含 Metric_Format_Amt / Metric_Format_Unit 双格式列与 Metric_IsCurrencyAmount 标记
- Slicer_Time_Frame_Max_This 含 Fiscal_Month_First/Last_Day、Fiscal_Year_First/Last_Day 及 TimeFrame_Max_Month/Year_Value 字段，Slicer_Time_Frame_Min_This 含 TimeFrame_Min_Month/Year_Value——TAR 分母区间与跨期判定字段直接读取
- Slicer_Platform_Selection、Slicer_Store_Name、Slicer_AX_Class 等筛选器与事实表一对多关联，筛选自动传递，DAX 无需显式处理
- 字段名已逐一核对数据字典（含 md_outbound_amt、msrp_in_trans_inv_amt、msrp_o2o_inv_amt 等）

---

## 3. 方案设计

### 3.1 度量值分层

```
Act Base Value / LY Base Value / TAR Base Value
    ←  Amt/Unit 路由 + 商品标签路由 + Metric_ID 路由，保留 RMB 原值
    ↓
Base Value（总路由）
    ←  Metric_ID 派生 vs LY（变化率 / 差值 bp）+ TAR 类三分支调用 TAR Base Value
    ↓
Cell Value
    ←  模式相关金额类汇率换算（÷ Currency_ExchangeRate）
    ↓
Cell Display
    ←  按模式相关 Metric_Format（Amt/Unit 取一）格式化，含 delta_bp ×10000 转 bp
    ↓
Cell Font Color / Cell Background Color
    ←  按 Metric_ColorRule 调度颜色 / KPIGroup 层与 ColName 层背景区分
```

### 3.2 字段路由（Amt / Unit）

| KPI                  | Amt 逻辑                                                   | Unit 逻辑                                    | 是否共享                                     |
| -------------------- | ---------------------------------------------------------- | -------------------------------------------- | -------------------------------------------- |
| SLS                  | sum(net_sales_amt)                                         | sum(net_sales_qty)                           | 否                                           |
| ST%                  | net_sales_amt / (net_sales_amt + msrp_inv_amt)             | net_sales_qty / (net_sales_qty + inv_qty)    | 结构一致（复用模式路由后的 SLS 与 EOH 结果） |
| AVG MD               | 1 - sum(md_net_sales_amt) / sum(msrp_net_sales_amt)        | 同左                                         | 是（口径明确可直接复用）                     |
| Fullprice%           | sum(net_sales_amt where md_type="FP") / sum(net_sales_amt) | sum(msrp_net_sales_amt) / sum(net_sales_amt) | 否（口径已确认两套公式）                     |
| AUR                  | sum(net_sales_amt) / sum(net_sales_qty)                    | 同左                                         | 是（口径明确可直接复用）                     |
| EOH                  | sum(msrp_inv_amt)                                          | sum(inv_qty)                                 | 否                                           |
| In-Transit Inventory | sum(msrp_in_trans_inv_amt)                                 | sum(in_trans_inv_qty)                        | 否                                           |
| O2O Inventory        | sum(msrp_o2o_inv_amt)                                      | sum(o2o_inv_qty)                             | 否                                           |
| Inbound              | sum(msrp_inbound_amt)                                      | sum(inbound_qty)                             | 否                                           |
| Outbound             | sum(md_outbound_amt)                                       | sum(outbound_qty)                            | 否                                           |

### 3.3 主指标口径（This Period）

| Metric_ID | KPI                  | 数据底表    | 时间口径            | 说明                                                         |
| --------- | -------------------- | ----------- | ------------------- | ------------------------------------------------------------ |
| 1         | SLS                  | sales       | 区间                | DCom 净销售额 / 净销售数量                                   |
| 5         | ST%                  | sales + inv | 分子区间 / 分母期末 | 售罄率，分子看整个 This Period，分母看 end period 最后快照日 |
| 7         | AVG MD               | sales       | 区间                | 平均折扣，Amt/Unit 共享                                      |
| 9         | Fullprice%           | sales       | 区间                | 全价率，Amt/Unit 公式不同                                    |
| 11        | AUR                  | sales       | 区间                | 件单价（金额类，双模式均需汇率换算），Amt/Unit 共享          |
| 13        | EOH                  | inv         | 期末                | 期末库存                                                     |
| 15        | In-Transit Inventory | inv         | 期末                | 在途库存，无附属指标                                         |
| 16        | O2O Inventory        | inv         | 期末                | O2O 库存，无附属指标                                         |
| 17        | Inbound              | sales       | 区间                | 入库                                                         |
| 19        | Outbound             | sales       | 区间                | 出库                                                         |

### 3.4 派生指标

| Metric_ID | 派生类型          | 目标 Act Metric_ID | 公式                                           | 格式          |
| --------- | ----------------- | ------------------ | ---------------------------------------------- | ------------- |
| 2         | vs LY 变化率      | 1（SLS）           | Act / LY - 1                                   | delta_pct_0dp |
| 6         | vs LY 差值 bp     | 5（ST%）           | Act - LY（×10000 转 bp 在 Cell Display 实现） | delta_bp      |
| 8         | vs LY 差值 bp     | 7（AVG MD）        | 同上                                           | delta_bp      |
| 10        | vs LY 差值 bp     | 9（Fullprice%）    | 同上                                           | delta_bp      |
| 12        | vs LY 变化率      | 11（AUR）          | Act / LY - 1                                   | delta_pct_0dp |
| 14        | vs LY 变化率      | 13（EOH）          | Act / LY - 1                                   | delta_pct_0dp |
| 18        | vs LY 变化率      | 17（Inbound）      | Act / LY - 1                                   | delta_pct_0dp |
| 20        | vs LY 变化率      | 19（Outbound）      | Act / LY - 1                                   | delta_pct_0dp |
| 21        | TAR ACH%          | —（TAR Base Value 内实现） | This actual / This target（date to date，全粒度）           | percent_0dp   |
| 3         | MTD TAR Progress  | —（TAR Base Value 内实现） | This actual / 分母区间 target（Day/Week 不跨财月取财月、Month This/This、Quarter/Year 不计算） | percent_1dp |
| 4         | YTD TAR Progress  | —（TAR Base Value 内实现） | This actual / 分母区间 target（Day~Quarter 不跨财年取财年、Year 始终 This/This） | percent_1dp   |

### 3.5 金额类汇率换算（模式相关）

| 指标                                                     | Amt 模式         | Unit 模式         |
| -------------------------------------------------------- | ---------------- | ----------------- |
| SLS / EOH / In-Transit / O2O / Inbound / Outbound 的 Act | currency → 换算 | integer → 不换算 |
| AUR 的 Act                                               | currency → 换算 | currency → 换算  |
| ST% / AVG MD / Fullprice% 的 Act                         | 比率，不换算     | 比率，不换算      |
| 全部 vs LY / TAR 类                                     | 派生比率，不换算 | 派生比率，不换算  |

判定方式（Dim 表设计原则第 4 条）：`IF(__IsAmt, Metric_Format_Amt = "currency", Metric_Format_Unit = "currency")`。
说明：Metric_IsCurrencyAmount 为按【Amt】口径的静态标记，Unit 模式下 6 组金额/数量类指标为 integer，故不能直接用该标记判断当前模式是否换算，统一用模式相关格式列等价判断。

---

## 4. 度量值实现

### 4.1 Merchandising Core KPI Act Base Value（This Period 基础值）

```dax
Merchandising Core KPI Act Base Value =
// ========================================
// 度量值: Merchandising Core KPI Act Base Value
// Display Folder: Base Metrics
// 用途: This Period 基础值（主指标 Act 列，Metric_ID=1/5/7/9/11/13/15/16/17/19）
//       按 Amt/Unit 按钮 + 商品标签按钮 + Metric_ID 三重路由，保留 RMB 原始值
// 依赖: 'IsAmtUnitFilter'[Sort]（=10 Amt / =20 Unit，默认 Amt）
//       'IsProductTagFilter'[computed_product_tag]（ALL/hero model/slow mover/normal，默认 ALL）
//       'Dim_ColMetric_Merchandising_Core_KPI'[Metric_ID]
//       Slicer_Time_Frame_Min_This[TimeFrame_Min] / Slicer_Time_Frame_Max_This[TimeFrame_Max]
// 数据底表: a02_e2e_product_performance_sales_summary_d（销售类）
//           a02_e2e_product_performance_inv_summary_d（库存类）
// 时间口径:
//   区间类（SLS/AVG MD/Fullprice%/AUR/Inbound/Outbound/ST% 分子）:
//     data_date ∈ [Min_This[TimeFrame_Min], Max_This[TimeFrame_Max]]
//   期末时点类（EOH/In-Transit/O2O/ST% 分母）:
//     end period 范围 [Max_This[TimeFrame_Min], Max_This[TimeFrame_Max]] 内最后一个快照日
//     （口径为 end period 最后一天；快照缺数时自动取范围内最近一天）
// 汇率换算: 不在此度量值处理，保持原始 RMB，由 Cell Value 层统一换算
// ========================================

// ── 模式路由：Amt / Unit ──
VAR __AmtUnitSort = SELECTEDVALUE('IsAmtUnitFilter'[Sort], 10)
VAR __IsAmt = (__AmtUnitSort = 10)

// ── 商品标签路由：ALL / Hero Model / Slow Mover / Normal ──
VAR __ProductTag = SELECTEDVALUE('IsProductTagFilter'[computed_product_tag], "ALL")

// ── 列维度路由：Metric_ID ──
VAR __MetricID = SELECTEDVALUE('Dim_ColMetric_Merchandising_Core_KPI'[Metric_ID])

// ── This Period 时间区间（区间类指标）──
VAR __PeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Min_This[TimeFrame_Min])
VAR __PeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

// ── End Period 时间范围（期末时点类指标）──
VAR __EndPeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Min])
VAR __EndPeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

// ── 期末快照日：end period 范围内最后一个有数据的日期 ──
// REMOVEFILTERS 保证快照日不随商品切片器/矩阵上下文漂移（全表最后一个快照日，确定性更强）
VAR __EndPeriodDate =
    CALCULATE(
        MAX('a02_e2e_product_performance_inv_summary_d'[data_date]),
        REMOVEFILTERS('a02_e2e_product_performance_inv_summary_d'),
        'a02_e2e_product_performance_inv_summary_d'[data_date] >= __EndPeriodMin,
        'a02_e2e_product_performance_inv_summary_d'[data_date] <= __EndPeriodMax
    )

// ── 商品标签过滤器（sales 表；UNION+FILTER 保证表类型稳定，避免 IF 退化表变量）──
VAR __TagFilter_Sales =
    UNION(
        FILTER(
            ALL('a02_e2e_product_performance_sales_summary_d'[computed_product_tag]),
            __ProductTag = "ALL"
                && 'a02_e2e_product_performance_sales_summary_d'[computed_product_tag]
                    IN {"hero model", "slow mover", "normal"}
        ),
        FILTER(
            ALL('a02_e2e_product_performance_sales_summary_d'[computed_product_tag]),
            __ProductTag <> "ALL"
                && 'a02_e2e_product_performance_sales_summary_d'[computed_product_tag] = __ProductTag
        )
    )

// ── 商品标签过滤器（inv 表）──
VAR __TagFilter_Inv =
    UNION(
        FILTER(
            ALL('a02_e2e_product_performance_inv_summary_d'[computed_product_tag]),
            __ProductTag = "ALL"
                && 'a02_e2e_product_performance_inv_summary_d'[computed_product_tag]
                    IN {"hero model", "slow mover", "normal"}
        ),
        FILTER(
            ALL('a02_e2e_product_performance_inv_summary_d'[computed_product_tag]),
            __ProductTag <> "ALL"
                && 'a02_e2e_product_performance_inv_summary_d'[computed_product_tag] = __ProductTag
        )
    )

// ═══ 公共聚合：sales 表 This Period 区间（供 SLS/ST%/Fullprice%/AUR 复用）═══
VAR __NetSalesAmt_Act =
    CALCULATE(
        SUM('a02_e2e_product_performance_sales_summary_d'[net_sales_amt]),
        __TagFilter_Sales,
        'a02_e2e_product_performance_sales_summary_d'[data_date] >= __PeriodMin,
        'a02_e2e_product_performance_sales_summary_d'[data_date] <= __PeriodMax
    )
VAR __NetSalesQty_Act =
    CALCULATE(
        SUM('a02_e2e_product_performance_sales_summary_d'[net_sales_qty]),
        __TagFilter_Sales,
        'a02_e2e_product_performance_sales_summary_d'[data_date] >= __PeriodMin,
        'a02_e2e_product_performance_sales_summary_d'[data_date] <= __PeriodMax
    )
VAR __MDNetSalesAmt_Act =
    CALCULATE(
        SUM('a02_e2e_product_performance_sales_summary_d'[md_net_sales_amt]),
        __TagFilter_Sales,
        'a02_e2e_product_performance_sales_summary_d'[data_date] >= __PeriodMin,
        'a02_e2e_product_performance_sales_summary_d'[data_date] <= __PeriodMax
    )
VAR __MsrpNetSalesAmt_Act =
    CALCULATE(
        SUM('a02_e2e_product_performance_sales_summary_d'[msrp_net_sales_amt]),
        __TagFilter_Sales,
        'a02_e2e_product_performance_sales_summary_d'[data_date] >= __PeriodMin,
        'a02_e2e_product_performance_sales_summary_d'[data_date] <= __PeriodMax
    )
// Fullprice% Amt 分子：md_type = "FP"（口径公式 sum(case when md_type = 'FP' ...)）
VAR __FPNetSalesAmt_Act =
    CALCULATE(
        SUM('a02_e2e_product_performance_sales_summary_d'[net_sales_amt]),
        __TagFilter_Sales,
        'a02_e2e_product_performance_sales_summary_d'[md_type] = "FP",
        'a02_e2e_product_performance_sales_summary_d'[data_date] >= __PeriodMin,
        'a02_e2e_product_performance_sales_summary_d'[data_date] <= __PeriodMax
    )
VAR __MsrpInboundAmt_Act =
    CALCULATE(
        SUM('a02_e2e_product_performance_sales_summary_d'[msrp_inbound_amt]),
        __TagFilter_Sales,
        'a02_e2e_product_performance_sales_summary_d'[data_date] >= __PeriodMin,
        'a02_e2e_product_performance_sales_summary_d'[data_date] <= __PeriodMax
    )
VAR __InboundQty_Act =
    CALCULATE(
        SUM('a02_e2e_product_performance_sales_summary_d'[inbound_qty]),
        __TagFilter_Sales,
        'a02_e2e_product_performance_sales_summary_d'[data_date] >= __PeriodMin,
        'a02_e2e_product_performance_sales_summary_d'[data_date] <= __PeriodMax
    )
VAR __MDOutboundAmt_Act =
    CALCULATE(
        SUM('a02_e2e_product_performance_sales_summary_d'[md_outbound_amt]),
        __TagFilter_Sales,
        'a02_e2e_product_performance_sales_summary_d'[data_date] >= __PeriodMin,
        'a02_e2e_product_performance_sales_summary_d'[data_date] <= __PeriodMax
    )
VAR __OutboundQty_Act =
    CALCULATE(
        SUM('a02_e2e_product_performance_sales_summary_d'[outbound_qty]),
        __TagFilter_Sales,
        'a02_e2e_product_performance_sales_summary_d'[data_date] >= __PeriodMin,
        'a02_e2e_product_performance_sales_summary_d'[data_date] <= __PeriodMax
    )

// ═══ 公共聚合：inv 表期末快照日（单日时点，供 EOH/ST% 分母复用）═══
VAR __MsrpInvAmt_End =
    CALCULATE(
        SUM('a02_e2e_product_performance_inv_summary_d'[msrp_inv_amt]),
        __TagFilter_Inv,
        'a02_e2e_product_performance_inv_summary_d'[data_date] = __EndPeriodDate
    )
VAR __InvQty_End =
    CALCULATE(
        SUM('a02_e2e_product_performance_inv_summary_d'[inv_qty]),
        __TagFilter_Inv,
        'a02_e2e_product_performance_inv_summary_d'[data_date] = __EndPeriodDate
    )
VAR __MsrpInTransInvAmt_End =
    CALCULATE(
        SUM('a02_e2e_product_performance_inv_summary_d'[msrp_in_trans_inv_amt]),
        __TagFilter_Inv,
        'a02_e2e_product_performance_inv_summary_d'[data_date] = __EndPeriodDate
    )
VAR __InTransInvQty_End =
    CALCULATE(
        SUM('a02_e2e_product_performance_inv_summary_d'[in_trans_inv_qty]),
        __TagFilter_Inv,
        'a02_e2e_product_performance_inv_summary_d'[data_date] = __EndPeriodDate
    )
VAR __MsrpO2OInvAmt_End =
    CALCULATE(
        SUM('a02_e2e_product_performance_inv_summary_d'[msrp_o2o_inv_amt]),
        __TagFilter_Inv,
        'a02_e2e_product_performance_inv_summary_d'[data_date] = __EndPeriodDate
    )
VAR __O2OInvQty_End =
    CALCULATE(
        SUM('a02_e2e_product_performance_inv_summary_d'[o2o_inv_qty]),
        __TagFilter_Inv,
        'a02_e2e_product_performance_inv_summary_d'[data_date] = __EndPeriodDate
    )

// ═══ Metric_ID=1: SLS（Amt/Unit 模式路由）═══
VAR __SLS_Act = IF(__IsAmt, __NetSalesAmt_Act, __NetSalesQty_Act)

// ═══ Metric_ID=13: EOH（Amt/Unit 模式路由）═══
VAR __EOH_Act = IF(__IsAmt, __MsrpInvAmt_End, __InvQty_End)

// ═══ Metric_ID=5: ST%（Amt/Unit 结构一致，直接复用模式路由后的 SLS 与 EOH）═══
// Amt: net_sales_amt / (net_sales_amt + msrp_inv_amt)
// Unit: net_sales_qty / (net_sales_qty + inv_qty)
// 分子为整个 This Period 区间，分母为期末快照日（跨 sales + inv 双表）
VAR __STPct_Act = DIVIDE(__SLS_Act, __SLS_Act + __EOH_Act)

// ═══ Metric_ID=7: AVG MD（Amt/Unit 同一套逻辑，直接复用）═══
// 1 - sum(md_net_sales_amt) / sum(msrp_net_sales_amt)
// 分母空/0 时返回 BLANK，避免 1 - BLANK() = 1 的失真
VAR __AVGMD_Act =
    IF(
        ISBLANK(__MsrpNetSalesAmt_Act) || __MsrpNetSalesAmt_Act = 0,
        BLANK(),
        1 - DIVIDE(__MDNetSalesAmt_Act, __MsrpNetSalesAmt_Act)
    )

// ═══ Metric_ID=9: Fullprice%（Amt/Unit 公式不同，口径已确认）═══
// Amt: sum(net_sales_amt where md_type = "FP") / sum(net_sales_amt)
// Unit: sum(msrp_net_sales_amt) / sum(net_sales_amt)
VAR __FullpricePct_Act =
    IF(
        __IsAmt,
        DIVIDE(__FPNetSalesAmt_Act, __NetSalesAmt_Act),
        DIVIDE(__MsrpNetSalesAmt_Act, __NetSalesAmt_Act)
    )

// ═══ Metric_ID=11: AUR（Amt/Unit 同一套逻辑，直接复用；金额类双模式均换算）═══
// sum(net_sales_amt) / sum(net_sales_qty)
VAR __AUR_Act = DIVIDE(__NetSalesAmt_Act, __NetSalesQty_Act)

// ═══ Metric_ID=15: In-Transit Inventory（Amt/Unit 模式路由，无附属指标）═══
VAR __InTransit_Act = IF(__IsAmt, __MsrpInTransInvAmt_End, __InTransInvQty_End)

// ═══ Metric_ID=16: O2O Inventory（Amt/Unit 模式路由，无附属指标）═══
VAR __O2O_Act = IF(__IsAmt, __MsrpO2OInvAmt_End, __O2OInvQty_End)

// ═══ Metric_ID=17: Inbound（Amt/Unit 模式路由）═══
VAR __Inbound_Act = IF(__IsAmt, __MsrpInboundAmt_Act, __InboundQty_Act)

// ═══ Metric_ID=19: Outbound（Amt/Unit 模式路由）═══
VAR __Outbound_Act = IF(__IsAmt, __MDOutboundAmt_Act, __OutboundQty_Act)

RETURN
    SWITCH(
        __MetricID,
        1,  __SLS_Act,          // SLS
        5,  __STPct_Act,        // ST%
        7,  __AVGMD_Act,        // AVG MD
        9,  __FullpricePct_Act, // Fullprice%
        11, __AUR_Act,          // AUR
        13, __EOH_Act,          // EOH
        15, __InTransit_Act,    // In-Transit Inventory
        16, __O2O_Act,          // O2O Inventory
        17, __Inbound_Act,      // Inbound
        19, __Outbound_Act,     // Outbound
        BLANK()
    )
```

### 4.2 Merchandising Core KPI LY Base Value（Last Period 基础值）

```dax
Merchandising Core KPI LY Base Value =
// ========================================
// 度量值: Merchandising Core KPI LY Base Value
// Display Folder: Base Metrics
// 用途: Last Period 基础值（vs LY 对比基线），结构与 Act Base Value 完全一致，
//       仅时间范围替换为 Last Period 筛选器（Min_Last / Max_Last 表）
// 依赖: 'IsAmtUnitFilter'[Sort]
//       'IsProductTagFilter'[computed_product_tag]
//       'Dim_ColMetric_Merchandising_Core_KPI'[Metric_ID]
//       Slicer_Time_Frame_Min_Last[TimeFrame_Min] / Slicer_Time_Frame_Max_Last[TimeFrame_Max]
// 说明: LY 直接读 Last Period 筛选器的 TimeFrame_Min / TimeFrame_Max（非 _LY 字段对称映射），
//       依赖模型中 Min_Last / Max_Last 与主时间筛选器的既有关系配置
// 汇率换算: 不在此度量值处理，保持原始 RMB
// ========================================

// ── 模式路由：Amt / Unit ──
VAR __AmtUnitSort = SELECTEDVALUE('IsAmtUnitFilter'[Sort], 10)
VAR __IsAmt = (__AmtUnitSort = 10)

// ── 商品标签路由：ALL / Hero Model / Slow Mover / Normal ──
VAR __ProductTag = SELECTEDVALUE('IsProductTagFilter'[computed_product_tag], "ALL")

// ── 列维度路由：Metric_ID ──
VAR __MetricID = SELECTEDVALUE('Dim_ColMetric_Merchandising_Core_KPI'[Metric_ID])

// ── Last Period 时间区间（区间类指标）──
VAR __PeriodMin_LY = SELECTEDVALUE(Slicer_Time_Frame_Min_Last[TimeFrame_Min])
VAR __PeriodMax_LY = SELECTEDVALUE(Slicer_Time_Frame_Max_Last[TimeFrame_Max])

// ── End Period LY 时间范围（期末时点类指标）──
VAR __EndPeriodMin_LY = SELECTEDVALUE(Slicer_Time_Frame_Max_Last[TimeFrame_Min])
VAR __EndPeriodMax_LY = SELECTEDVALUE(Slicer_Time_Frame_Max_Last[TimeFrame_Max])

// ── 期末快照日（LY）：end period LY 范围内最后一个有数据的日期 ──
VAR __EndPeriodDate_LY =
    CALCULATE(
        MAX('a02_e2e_product_performance_inv_summary_d'[data_date]),
        REMOVEFILTERS('a02_e2e_product_performance_inv_summary_d'),
        'a02_e2e_product_performance_inv_summary_d'[data_date] >= __EndPeriodMin_LY,
        'a02_e2e_product_performance_inv_summary_d'[data_date] <= __EndPeriodMax_LY
    )

// ── 商品标签过滤器（sales 表）──
VAR __TagFilter_Sales =
    UNION(
        FILTER(
            ALL('a02_e2e_product_performance_sales_summary_d'[computed_product_tag]),
            __ProductTag = "ALL"
                && 'a02_e2e_product_performance_sales_summary_d'[computed_product_tag]
                    IN {"hero model", "slow mover", "normal"}
        ),
        FILTER(
            ALL('a02_e2e_product_performance_sales_summary_d'[computed_product_tag]),
            __ProductTag <> "ALL"
                && 'a02_e2e_product_performance_sales_summary_d'[computed_product_tag] = __ProductTag
        )
    )

// ── 商品标签过滤器（inv 表）──
VAR __TagFilter_Inv =
    UNION(
        FILTER(
            ALL('a02_e2e_product_performance_inv_summary_d'[computed_product_tag]),
            __ProductTag = "ALL"
                && 'a02_e2e_product_performance_inv_summary_d'[computed_product_tag]
                    IN {"hero model", "slow mover", "normal"}
        ),
        FILTER(
            ALL('a02_e2e_product_performance_inv_summary_d'[computed_product_tag]),
            __ProductTag <> "ALL"
                && 'a02_e2e_product_performance_inv_summary_d'[computed_product_tag] = __ProductTag
        )
    )

// ═══ 公共聚合：sales 表 Last Period 区间 ═══
VAR __NetSalesAmt_LY =
    CALCULATE(
        SUM('a02_e2e_product_performance_sales_summary_d'[net_sales_amt]),
        __TagFilter_Sales,
        'a02_e2e_product_performance_sales_summary_d'[data_date] >= __PeriodMin_LY,
        'a02_e2e_product_performance_sales_summary_d'[data_date] <= __PeriodMax_LY
    )
VAR __NetSalesQty_LY =
    CALCULATE(
        SUM('a02_e2e_product_performance_sales_summary_d'[net_sales_qty]),
        __TagFilter_Sales,
        'a02_e2e_product_performance_sales_summary_d'[data_date] >= __PeriodMin_LY,
        'a02_e2e_product_performance_sales_summary_d'[data_date] <= __PeriodMax_LY
    )
VAR __MDNetSalesAmt_LY =
    CALCULATE(
        SUM('a02_e2e_product_performance_sales_summary_d'[md_net_sales_amt]),
        __TagFilter_Sales,
        'a02_e2e_product_performance_sales_summary_d'[data_date] >= __PeriodMin_LY,
        'a02_e2e_product_performance_sales_summary_d'[data_date] <= __PeriodMax_LY
    )
VAR __MsrpNetSalesAmt_LY =
    CALCULATE(
        SUM('a02_e2e_product_performance_sales_summary_d'[msrp_net_sales_amt]),
        __TagFilter_Sales,
        'a02_e2e_product_performance_sales_summary_d'[data_date] >= __PeriodMin_LY,
        'a02_e2e_product_performance_sales_summary_d'[data_date] <= __PeriodMax_LY
    )
VAR __FPNetSalesAmt_LY =
    CALCULATE(
        SUM('a02_e2e_product_performance_sales_summary_d'[net_sales_amt]),
        __TagFilter_Sales,
        'a02_e2e_product_performance_sales_summary_d'[md_type] = "FP",
        'a02_e2e_product_performance_sales_summary_d'[data_date] >= __PeriodMin_LY,
        'a02_e2e_product_performance_sales_summary_d'[data_date] <= __PeriodMax_LY
    )
VAR __MsrpInboundAmt_LY =
    CALCULATE(
        SUM('a02_e2e_product_performance_sales_summary_d'[msrp_inbound_amt]),
        __TagFilter_Sales,
        'a02_e2e_product_performance_sales_summary_d'[data_date] >= __PeriodMin_LY,
        'a02_e2e_product_performance_sales_summary_d'[data_date] <= __PeriodMax_LY
    )
VAR __InboundQty_LY =
    CALCULATE(
        SUM('a02_e2e_product_performance_sales_summary_d'[inbound_qty]),
        __TagFilter_Sales,
        'a02_e2e_product_performance_sales_summary_d'[data_date] >= __PeriodMin_LY,
        'a02_e2e_product_performance_sales_summary_d'[data_date] <= __PeriodMax_LY
    )
VAR __MDOutboundAmt_LY =
    CALCULATE(
        SUM('a02_e2e_product_performance_sales_summary_d'[md_outbound_amt]),
        __TagFilter_Sales,
        'a02_e2e_product_performance_sales_summary_d'[data_date] >= __PeriodMin_LY,
        'a02_e2e_product_performance_sales_summary_d'[data_date] <= __PeriodMax_LY
    )
VAR __OutboundQty_LY =
    CALCULATE(
        SUM('a02_e2e_product_performance_sales_summary_d'[outbound_qty]),
        __TagFilter_Sales,
        'a02_e2e_product_performance_sales_summary_d'[data_date] >= __PeriodMin_LY,
        'a02_e2e_product_performance_sales_summary_d'[data_date] <= __PeriodMax_LY
    )

// ═══ 公共聚合：inv 表期末快照日（LY，单日时点）═══
VAR __MsrpInvAmt_End_LY =
    CALCULATE(
        SUM('a02_e2e_product_performance_inv_summary_d'[msrp_inv_amt]),
        __TagFilter_Inv,
        'a02_e2e_product_performance_inv_summary_d'[data_date] = __EndPeriodDate_LY
    )
VAR __InvQty_End_LY =
    CALCULATE(
        SUM('a02_e2e_product_performance_inv_summary_d'[inv_qty]),
        __TagFilter_Inv,
        'a02_e2e_product_performance_inv_summary_d'[data_date] = __EndPeriodDate_LY
    )
VAR __MsrpInTransInvAmt_End_LY =
    CALCULATE(
        SUM('a02_e2e_product_performance_inv_summary_d'[msrp_in_trans_inv_amt]),
        __TagFilter_Inv,
        'a02_e2e_product_performance_inv_summary_d'[data_date] = __EndPeriodDate_LY
    )
VAR __InTransInvQty_End_LY =
    CALCULATE(
        SUM('a02_e2e_product_performance_inv_summary_d'[in_trans_inv_qty]),
        __TagFilter_Inv,
        'a02_e2e_product_performance_inv_summary_d'[data_date] = __EndPeriodDate_LY
    )
VAR __MsrpO2OInvAmt_End_LY =
    CALCULATE(
        SUM('a02_e2e_product_performance_inv_summary_d'[msrp_o2o_inv_amt]),
        __TagFilter_Inv,
        'a02_e2e_product_performance_inv_summary_d'[data_date] = __EndPeriodDate_LY
    )
VAR __O2OInvQty_End_LY =
    CALCULATE(
        SUM('a02_e2e_product_performance_inv_summary_d'[o2o_inv_qty]),
        __TagFilter_Inv,
        'a02_e2e_product_performance_inv_summary_d'[data_date] = __EndPeriodDate_LY
    )

// ═══ Metric_ID=1: SLS LY ═══
VAR __SLS_LY = IF(__IsAmt, __NetSalesAmt_LY, __NetSalesQty_LY)

// ═══ Metric_ID=13: EOH LY ═══
VAR __EOH_LY = IF(__IsAmt, __MsrpInvAmt_End_LY, __InvQty_End_LY)

// ═══ Metric_ID=5: ST% LY ═══
VAR __STPct_LY = DIVIDE(__SLS_LY, __SLS_LY + __EOH_LY)

// ═══ Metric_ID=7: AVG MD LY ═══
VAR __AVGMD_LY =
    IF(
        ISBLANK(__MsrpNetSalesAmt_LY) || __MsrpNetSalesAmt_LY = 0,
        BLANK(),
        1 - DIVIDE(__MDNetSalesAmt_LY, __MsrpNetSalesAmt_LY)
    )

// ═══ Metric_ID=9: Fullprice% LY ═══
VAR __FullpricePct_LY =
    IF(
        __IsAmt,
        DIVIDE(__FPNetSalesAmt_LY, __NetSalesAmt_LY),
        DIVIDE(__MsrpNetSalesAmt_LY, __NetSalesAmt_LY)
    )

// ═══ Metric_ID=11: AUR LY ═══
VAR __AUR_LY = DIVIDE(__NetSalesAmt_LY, __NetSalesQty_LY)

// ═══ Metric_ID=15: In-Transit Inventory LY ═══
VAR __InTransit_LY = IF(__IsAmt, __MsrpInTransInvAmt_End_LY, __InTransInvQty_End_LY)

// ═══ Metric_ID=16: O2O Inventory LY ═══
VAR __O2O_LY = IF(__IsAmt, __MsrpO2OInvAmt_End_LY, __O2OInvQty_End_LY)

// ═══ Metric_ID=17: Inbound LY ═══
VAR __Inbound_LY = IF(__IsAmt, __MsrpInboundAmt_LY, __InboundQty_LY)

// ═══ Metric_ID=19: Outbound LY ═══
VAR __Outbound_LY = IF(__IsAmt, __MDOutboundAmt_LY, __OutboundQty_LY)

RETURN
    SWITCH(
        __MetricID,
        1,  __SLS_LY,           // SLS
        5,  __STPct_LY,         // ST%
        7,  __AVGMD_LY,         // AVG MD
        9,  __FullpricePct_LY,  // Fullprice%
        11, __AUR_LY,           // AUR
        13, __EOH_LY,           // EOH
        15, __InTransit_LY,     // In-Transit Inventory
        16, __O2O_LY,           // O2O Inventory
        17, __Inbound_LY,       // Inbound
        19, __Outbound_LY,      // Outbound
        BLANK()
    )
```

### 4.3 Merchandising Core KPI TAR Base Value（TAR 类三指标：actual ÷ target）

```dax
Merchandising Core KPI TAR Base Value =
// ========================================
// 度量值: Merchandising Core KPI TAR Base Value
// Display Folder: Base Metrics
// 用途: TAR 类三指标（Metric_ID=21 TAR ACH% / 3 MTD TAR Progress / 4 YTD TAR Progress），
//       按 current 列 Metric_ID 分支（在自身 Metric_ID 上下文内计算，无需重路由；
//       由 Base Value 总路由在 21/3/4 分支调用；矩阵列与卡片图视觉筛选固定 ColName 均生效）
// actual: This Period 区间 sales 聚合，按 Amt/Unit 模式路由字段
//       （Amt = sum(net_sales_amt) / Unit = sum(net_sales_qty)），受商品标签按钮过滤
// target: a05 聚合，按模式路由字段（Amt = sum(fcst_sales_amt) / Unit = sum(fcst_sales_qty)）；
//       a05 无 computed_product_tag 字段，target 侧无法按标签过滤（物理限制，
//       分子分母标签口径不对称）；渠道 / 商品维度切片器与 a05 一对多自动传导
// 粒度分支（时间粒度读 Slicer_Time_Frame[TimeFrame_ID]）:
//   TAR ACH% (21)   全粒度 This actual / This target（date to date）
//   MTD TAR Progress (3): Day/Week 不跨财月取所在财月汇总 target、跨财月不计算；
//                          Month This/This；Quarter/Year 不计算
//   YTD TAR Progress (4): Day/Week/Month/Quarter 不跨财年取所在财年汇总 target、
//                          跨财年不计算；Year 始终计算且 This/This
// 汇率换算: 不在此度量值处理（actual/target 同模式同币种相除，比率不受币种影响）
// ========================================

// ── 模式路由：Amt / Unit ──
VAR __AmtUnitSort = SELECTEDVALUE('IsAmtUnitFilter'[Sort], 10)
VAR __IsAmt = (__AmtUnitSort = 10)

// ── 列维度路由：Metric_ID（21 / 3 / 4）──
VAR __MetricID = SELECTEDVALUE('Dim_ColMetric_Merchandising_Core_KPI'[Metric_ID])

// ── 商品标签路由：ALL / Hero Model / Slow Mover / Normal ──
VAR __ProductTag = SELECTEDVALUE('IsProductTagFilter'[computed_product_tag], "ALL")

// ── This Period 时间区间（actual；TAR ACH% 与 Month/Year 的 This/This 分母）──
VAR __PeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Min_This[TimeFrame_Min])
VAR __PeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

// ── TAR 分母区间（均以 TimeFrame_Max 所在财月 / 财年框定）──
VAR __MonthFirstDay = SELECTEDVALUE(Slicer_Time_Frame_Max_This[Fiscal_Month_First_Day])
VAR __MonthLastDay = SELECTEDVALUE(Slicer_Time_Frame_Max_This[Fiscal_Month_Last_Day])
VAR __YearFirstDay = SELECTEDVALUE(Slicer_Time_Frame_Max_This[Fiscal_Year_First_Day])
VAR __YearLastDay = SELECTEDVALUE(Slicer_Time_Frame_Max_This[Fiscal_Year_Last_Day])

// ── 时间粒度与跨期判定（判定不区分粒度，直接比较财月 / 财年 value 文本）──
VAR __TimeFrameID = SELECTEDVALUE(Slicer_Time_Frame[TimeFrame_ID])
VAR __IsCrossMonth =
    SELECTEDVALUE(Slicer_Time_Frame_Min_This[TimeFrame_Min_Month_Value])
        <> SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max_Month_Value])
VAR __IsCrossYear =
    SELECTEDVALUE(Slicer_Time_Frame_Min_This[TimeFrame_Min_Year_Value])
        <> SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max_Year_Value])

// ── 商品标签过滤器（sales 表；UNION+FILTER 保证表类型稳定）──
VAR __TagFilter_Sales =
    UNION(
        FILTER(
            ALL('a02_e2e_product_performance_sales_summary_d'[computed_product_tag]),
            __ProductTag = "ALL"
                && 'a02_e2e_product_performance_sales_summary_d'[computed_product_tag]
                    IN {"hero model", "slow mover", "normal"}
        ),
        FILTER(
            ALL('a02_e2e_product_performance_sales_summary_d'[computed_product_tag]),
            __ProductTag <> "ALL"
                && 'a02_e2e_product_performance_sales_summary_d'[computed_product_tag] = __ProductTag
        )
    )

// ═══ actual：This Period 区间 sales 聚合（按模式路由金额 / 数量，受标签过滤）═══
VAR __Actual =
    CALCULATE(
        IF(
            __IsAmt,
            SUM('a02_e2e_product_performance_sales_summary_d'[net_sales_amt]),
            SUM('a02_e2e_product_performance_sales_summary_d'[net_sales_qty])
        ),
        __TagFilter_Sales,
        'a02_e2e_product_performance_sales_summary_d'[data_date] >= __PeriodMin,
        'a02_e2e_product_performance_sales_summary_d'[data_date] <= __PeriodMax
    )

// ═══ target：a05 三区间聚合（按模式路由金额 / 数量目标；a05 与日期筛选器断开维度，显式过滤）═══
// a05 无 computed_product_tag 字段，target 侧不施加标签过滤（物理限制）
VAR __Fcst_This =
    CALCULATE(
        IF(
            __IsAmt,
            SUM('a05_e2e_product_fcst_data_d'[fcst_sales_amt]),
            SUM('a05_e2e_product_fcst_data_d'[fcst_sales_qty])
        ),
        'a05_e2e_product_fcst_data_d'[data_date] >= __PeriodMin,
        'a05_e2e_product_fcst_data_d'[data_date] <= __PeriodMax
    )
VAR __Fcst_MTD =
    CALCULATE(
        IF(
            __IsAmt,
            SUM('a05_e2e_product_fcst_data_d'[fcst_sales_amt]),
            SUM('a05_e2e_product_fcst_data_d'[fcst_sales_qty])
        ),
        'a05_e2e_product_fcst_data_d'[data_date] >= __MonthFirstDay,
        'a05_e2e_product_fcst_data_d'[data_date] <= __MonthLastDay
    )
VAR __Fcst_YTD =
    CALCULATE(
        IF(
            __IsAmt,
            SUM('a05_e2e_product_fcst_data_d'[fcst_sales_amt]),
            SUM('a05_e2e_product_fcst_data_d'[fcst_sales_qty])
        ),
        'a05_e2e_product_fcst_data_d'[data_date] >= __YearFirstDay,
        'a05_e2e_product_fcst_data_d'[data_date] <= __YearLastDay
    )

// ═══ MTD TAR Progress：actual 恒为 This Period，分母区间随粒度分支 ═══
VAR __MTDProgress =
    SWITCH(
        TRUE(),
        // Day / Week：不跨财月 → This actual / 所在财月汇总 target；跨财月 → 不计算
        __TimeFrameID IN {"Day", "Week"},
            IF(__IsCrossMonth, BLANK(), DIVIDE(__Actual, __Fcst_MTD)),
        // Month：分子分母始终和 This Period 区间一致
        __TimeFrameID = "Month",
            DIVIDE(__Actual, __Fcst_This),
        // Quarter / Year 及其他：不计算
        BLANK()
    )

// ═══ YTD TAR Progress：actual 恒为 This Period，分母区间随粒度分支 ═══
VAR __YTDProgress =
    SWITCH(
        TRUE(),
        // Day / Week / Month / Quarter：不跨财年 → This actual / 所在财年汇总 target；跨财年 → 不计算
        __TimeFrameID IN {"Day", "Week", "Month", "Quarter"},
            IF(__IsCrossYear, BLANK(), DIVIDE(__Actual, __Fcst_YTD)),
        // Year：始终计算，分子分母始终和 This Period 区间一致
        __TimeFrameID = "Year",
            DIVIDE(__Actual, __Fcst_This),
        // 其他：不计算
        BLANK()
    )

RETURN
    SWITCH(
        __MetricID,
        21, DIVIDE(__Actual, __Fcst_This),   // TAR ACH%（date to date，全粒度）
        3,  __MTDProgress,                   // MTD TAR Progress
        4,  __YTDProgress,                   // YTD TAR Progress
        BLANK()
    )

// ========================================
// 尾部注释: TAR 三指标 × 五粒度计算矩阵（actual 恒为 This Period 区间，模式路由金额/数量）
//   指标              Day              Week            Month           Quarter        Year
//   TAR ACH%(21)      This/This        This/This       This/This       This/This      This/This
//   MTD(3)            不跨月:This/财月  跨月:BLANK      同Day           This/This      BLANK
//   YTD(4)            不跨年:This/财年  跨年:BLANK      同Day           同Day          This/This
//   财月区间 = [Fiscal_Month_First_Day, Fiscal_Month_Last_Day]（TimeFrame_Max 所在财月）
//   财年区间 = [Fiscal_Year_First_Day, Fiscal_Year_Last_Day]（TimeFrame_Max 所在财年）
// ========================================
```

### 4.4 Merchandising Core KPI Base Value（总路由）

```dax
Merchandising Core KPI Base Value =
// ========================================
// 度量值: Merchandising Core KPI Base Value
// Display Folder: Base Metrics
// 用途: 总路由，按 Metric_ID 分发到 Act / vs LY（变化率 / 差值 bp）/ TAR 类三指标
// 依赖: [Merchandising Core KPI Act Base Value],
//       [Merchandising Core KPI LY Base Value],
//       [Merchandising Core KPI TAR Base Value],
//       'Dim_ColMetric_Merchandising_Core_KPI'[Metric_ID]
//
// Metric_ID 路由规则（10 组 21 列）:
//   Act 基础指标 ID   : 1, 5, 7, 9, 11, 13, 15, 16, 17, 19
//   vs LY 变化率 ID   : 2（SLS）, 12（AUR）, 14（EOH）, 18（Inbound）, 20（Outbound）
//   vs LY 差值 bp ID  : 6（ST%）, 8（AVG MD）, 10（Fullprice%）
//   TAR 类 ID         : 21（TAR ACH%）, 3（MTD TAR Progress）, 4（YTD TAR Progress）
//                       → TAR Base Value（actual ÷ target，粒度分支在彼处实现）
//
// 派生规则:
//   vs LY 变化率 = Act / LY - 1（比率类附属指标，口径全局逻辑）
//   vs LY 差值 bp = Act - LY（ST%/AVG MD/Fullprice% 比率类差值；×10000 转 bp 在 Cell Display 实现）
//   TAR 类三指标 = actual ÷ target（在自身 Metric_ID 上下文内计算，直接调用 TAR Base Value）
//
// REMOVEFILTERS 机制:
//   派生列需先 REMOVEFILTERS 清除断开维度的所有筛选，再应用目标 Metric_ID，
//   否则矩阵行/列标题保留的筛选器会导致冲突返回 BLANK
// ========================================
    VAR __MetricID = SELECTEDVALUE('Dim_ColMetric_Merchandising_Core_KPI'[Metric_ID])

    // ═══════════════════════════════════════
    // vs LY 派生：变化率（SLS/AUR/EOH/Inbound/Outbound）
    // ═══════════════════════════════════════
    VAR __IsVsLYRate = __MetricID IN {2, 12, 14, 18, 20}

    // ═══════════════════════════════════════
    // vs LY 派生：差值 bp（ST%/AVG MD/Fullprice%）
    // ═══════════════════════════════════════
    VAR __IsVsLYBp = __MetricID IN {6, 8, 10}

    // ── 派生列 → 目标 Act Metric_ID 映射 ──
    VAR __ActMetricID =
        SWITCH(
            __MetricID,
            2,  1,   // SLS vs LY        → SLS
            6,  5,   // ST% vs LY        → ST%
            8,  7,   // AVG MD vs LY     → AVG MD
            10, 9,   // Fullprice% vs LY → Fullprice%
            12, 11,  // AUR vs LY        → AUR
            14, 13,  // EOH vs LY        → EOH
            18, 17,  // Inbound vs LY    → Inbound
            20, 19   // Outbound vs LY   → Outbound
        )

    // ── Act 值（在派生分支内按目标 Metric_ID 重路由）──
    VAR __ActValue =
        IF(
            __IsVsLYRate || __IsVsLYBp,
            CALCULATE(
                [Merchandising Core KPI Act Base Value],
                REMOVEFILTERS('Dim_ColMetric_Merchandising_Core_KPI'),
                'Dim_ColMetric_Merchandising_Core_KPI'[Metric_ID] = __ActMetricID
            )
        )

    // ── LY 值（同目标 Metric_ID，Last Period 时间范围）──
    VAR __LYValue =
        IF(
            __IsVsLYRate || __IsVsLYBp,
            CALCULATE(
                [Merchandising Core KPI LY Base Value],
                REMOVEFILTERS('Dim_ColMetric_Merchandising_Core_KPI'),
                'Dim_ColMetric_Merchandising_Core_KPI'[Metric_ID] = __ActMetricID
            )
        )

    // ── vs LY 变化率：this period / last period - 1 ──
    VAR __VsLYRateResult =
        IF(
            __IsVsLYRate,
            IF(
                ISBLANK(__LYValue) || __LYValue = 0,
                BLANK(),
                DIVIDE(__ActValue, __LYValue) - 1
            )
        )

    // ── vs LY 差值 bp：this period - last period（×10000 转 bp 在 Cell Display 实现）──
    VAR __VsLYBpResult =
        IF(
            __IsVsLYBp,
            IF(
                ISBLANK(__ActValue) || ISBLANK(__LYValue),
                BLANK(),
                __ActValue - __LYValue
            )
        )

    RETURN
        SWITCH(
            __MetricID,
            // ─── Act 基础指标（10 个）───
            1,  [Merchandising Core KPI Act Base Value],   // SLS
            5,  [Merchandising Core KPI Act Base Value],   // ST%
            7,  [Merchandising Core KPI Act Base Value],   // AVG MD
            9,  [Merchandising Core KPI Act Base Value],   // Fullprice%
            11, [Merchandising Core KPI Act Base Value],   // AUR
            13, [Merchandising Core KPI Act Base Value],   // EOH
            15, [Merchandising Core KPI Act Base Value],   // In-Transit Inventory
            16, [Merchandising Core KPI Act Base Value],   // O2O Inventory
            17, [Merchandising Core KPI Act Base Value],   // Inbound
            19, [Merchandising Core KPI Act Base Value],   // Outbound
            // ─── vs LY 变化率（5 个）───
            2,  __VsLYRateResult,    // SLS vs LY
            12, __VsLYRateResult,    // AUR vs LY
            14, __VsLYRateResult,    // EOH vs LY
            18, __VsLYRateResult,    // Inbound vs LY
            20, __VsLYRateResult,    // Outbound vs LY
            // ─── vs LY 差值 bp（3 个）───
            6,  __VsLYBpResult,      // ST% vs LY
            8,  __VsLYBpResult,      // AVG MD vs LY
            10, __VsLYBpResult,      // Fullprice% vs LY
            // ─── TAR 类三指标（actual ÷ target，粒度分支在 TAR Base Value 内）───
            21, [Merchandising Core KPI TAR Base Value],  // TAR ACH%（date to date）
            3,  [Merchandising Core KPI TAR Base Value],  // MTD TAR Progress
            4,  [Merchandising Core KPI TAR Base Value],  // YTD TAR Progress
            BLANK()
        )
```

### 4.5 Merchandising Core KPI Cell Value（对外值，含模式相关汇率换算）

```dax
Merchandising Core KPI Cell Value =
// ========================================
// 度量值: Merchandising Core KPI Cell Value
// Display Folder: Cell Values
// 用途: 对外暴露的单元格值
//       - 当前模式下格式为 "currency" 的列（金额类 Act）→ 按汇率换算
//       - 其余（Unit 模式数量类、比率类 Act、全部 vs LY / TAR 类派生列）→ 直接返回 Base Value
// 依赖: [Merchandising Core KPI Base Value],
//       'Dim_ColMetric_Merchandising_Core_KPI'[Metric_Format_Amt, Metric_Format_Unit],
//       Slicer_Currency_Selection[Currency_ExchangeRate]
//
// 金额类判定（模式相关，Dim 表设计原则第 4 条）:
//   IF(__IsAmt, Metric_Format_Amt = "currency", Metric_Format_Unit = "currency")
//   - Amt 模式：SLS/EOH/In-Transit/O2O/Inbound/Outbound/AUR 的 Act → 换算
//   - Unit 模式：仅 AUR 的 Act → 换算（其余 6 组为 integer）
//   - 注：Metric_IsCurrencyAmount 为 Amt 口径静态标记，不能直接用于 Unit 模式判断
//
// 汇率换算规则:
//   - 数据底表存储 RMB 原始值，USD 时通过 ÷ Currency_ExchangeRate 换算
//   - RMB 时 Currency_ExchangeRate = 1，换算前后值相同
//   - 仅当前模式金额类触发换算（vs LY / TAR ACH% 为比率 delta，不涉及换算）
//   - Base Value 层始终保留 RMB 原始值，确保派生计算口径一致；换算集中在展示层，便于管理
// ========================================
    VAR __BaseValue = [Merchandising Core KPI Base Value]
    VAR __AmtUnitSort = SELECTEDVALUE('IsAmtUnitFilter'[Sort], 10)
    VAR __IsAmt = (__AmtUnitSort = 10)
    VAR __Format =
        IF(
            __IsAmt,
            SELECTEDVALUE('Dim_ColMetric_Merchandising_Core_KPI'[Metric_Format_Amt]),
            SELECTEDVALUE('Dim_ColMetric_Merchandising_Core_KPI'[Metric_Format_Unit])
        )
    VAR __IsCurrencyAmount = (__Format = "currency")
    VAR __ExchangeRate = SELECTEDVALUE(Slicer_Currency_Selection[Currency_ExchangeRate], 1)

    RETURN
        IF(
            ISBLANK(__BaseValue),
            BLANK(),
            IF(
                __IsCurrencyAmount,
                DIVIDE(__BaseValue, __ExchangeRate),   // 当前模式金额类: 汇率换算
                __BaseValue                            // 其他: 不换算
            )
        )
```

### 4.6 Merchandising Core KPI Cell Display（格式化显示，模式相关格式 + delta_bp 转 bp）

```dax
Merchandising Core KPI Cell Display =
// ========================================
// 度量值: Merchandising Core KPI Cell Display
// Display Folder: Formatting
// 用途: 按当前模式的 Metric_Format（Metric_Format_Amt / Metric_Format_Unit 取一）格式化显示
// 依赖: [Merchandising Core KPI Cell Value],
//       'Dim_ColMetric_Merchandising_Core_KPI'[Metric_Format_Amt, Metric_Format_Unit],
//       Slicer_Currency_Selection[Currency_Symbol]
//
// 格式类型（严格遵循口径文档数据类型 + 模版复用/数据类型和格式总览.md）:
//   currency      → __CurrencySymbol & FORMAT(__Value, "#,##0")（金额类 Act，符号由币种切片器决定）
//   integer       → FORMAT(__Value, "#,##0") 整数千分位（Unit 模式数量类 Act）
//   percent_0dp   → FORMAT(__Value, "#,##0%") 百分比整数，不含正号（ST%/AVG MD/Fullprice% Act / TAR ACH%）
//   percent_1dp   → FORMAT(__Value, "#,##0.0%") 百分比一位小数，不含正号（MTD / YTD TAR Progress）
//   delta_pct_0dp → IF(>0,"+","") & FORMAT(#,##0%) 百分比整数变化，含正号（vs LY 变化率）
//   delta_bp      → 基点，含正负号，值×10000 转 bp 在本层实现（ST%/AVG MD/Fullprice% vs LY）
// 说明:
//   - BLANK 显示为 "-"
//   - Cell Value 层已完成汇率换算，Display 层只负责符号拼接
// ========================================
    VAR __Value = [Merchandising Core KPI Cell Value]
    VAR __AmtUnitSort = SELECTEDVALUE('IsAmtUnitFilter'[Sort], 10)
    VAR __IsAmt = (__AmtUnitSort = 10)
    VAR __Format =
        IF(
            __IsAmt,
            SELECTEDVALUE('Dim_ColMetric_Merchandising_Core_KPI'[Metric_Format_Amt]),
            SELECTEDVALUE('Dim_ColMetric_Merchandising_Core_KPI'[Metric_Format_Unit])
        )
    VAR __CurrencySymbol = SELECTEDVALUE(Slicer_Currency_Selection[Currency_Symbol], "¥")

    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            SWITCH(
                __Format,
                // ─── 金额类（货币符号 + 千分位整数）───
                "currency",
                    __CurrencySymbol & FORMAT(__Value, "#,##0"),                                    // ¥1,000
                // ─── 整数千分位（Unit 模式数量类）───
                "integer",
                    FORMAT(__Value, "#,##0"),                                                       // 1,000
                // ─── 百分比整数，不含正号（比率类 Act）───
                "percent_0dp",
                    FORMAT(__Value, "#,##0%"),                                                      // 62%
                // ─── 百分比整数变化，含正号（vs LY 变化率 / TAR ACH%）───
                "delta_pct_0dp",
                    IF(__Value > 0, "+", "") & FORMAT(__Value, "#,##0%"),                           // +15% / -3%
                // ─── 基点，含正负号（vs LY 差值，×10000 转 bp）───
                "delta_bp",
                    IF(__Value > 0, "+", "") & FORMAT(__Value * 10000, "#,##0") & "bp",             // +400bp / -80bp
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
                    FORMAT(__Value, "#,##0.0%"),                                                    // 62.5%
                "delta_pct_1dp",
                    IF(__Value > 0, "+", "") & FORMAT(__Value, "#,##0.0%"),                         // +14.5%
                "delta_pts",
                    IF(__Value > 0, "+", "") & FORMAT(__Value * 100, "#,##0") & "pts",              // +120pts
                "decimal_1dp",
                    FORMAT(__Value, "#,##0.0"),                                                     // 1.5
                // ─── 默认 ─────────────────────────────────
                FORMAT(__Value, "#,##0.00")
            )
        )
```

### 4.7 Merchandising Core KPI Cell Font Color（字体颜色）

```dax
Merchandising Core KPI Cell Font Color =
// ========================================
// 度量值: Merchandising Core KPI Cell Font Color
// Display Folder: Formatting
// 用途: 按 Metric_ColorRule 字段分发字体颜色
// 依赖: [Merchandising Core KPI Cell Value],
//       'Dim_ColMetric_Merchandising_Core_KPI'[Metric_ColorRule, Metric_ColorPositive/Negative/Zero/Default]
//
// 颜色规则:
//   1. 全部主指标 Act 列（Metric_ID=1,5,7,9,11,13,15,16,17,19）固定 #252423 → "fixed_black"
//   2. 全部 vs LY / TAR 类附属列（11 列，比率为正/负/零三色）→ "pos_neg_zero"
// ========================================
    VAR __Value = [Merchandising Core KPI Cell Value]
    VAR __ColorRule = SELECTEDVALUE('Dim_ColMetric_Merchandising_Core_KPI'[Metric_ColorRule], "fixed_default")
    VAR __ColorPositive = SELECTEDVALUE('Dim_ColMetric_Merchandising_Core_KPI'[Metric_ColorPositive], "#1A9018")
    VAR __ColorNegative = SELECTEDVALUE('Dim_ColMetric_Merchandising_Core_KPI'[Metric_ColorNegative], "#D64550")
    VAR __ColorZero = SELECTEDVALUE('Dim_ColMetric_Merchandising_Core_KPI'[Metric_ColorZero], "#E1C233")
    VAR __ColorDefault = SELECTEDVALUE('Dim_ColMetric_Merchandising_Core_KPI'[Metric_ColorDefault], "#5F6165")

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

### 4.8 Merchandising Core KPI Cell Background Color（背景色）

```dax
Merchandising Core KPI Cell Background Color =
// ========================================
// 度量值: Merchandising Core KPI Cell Background Color
// Display Folder: Formatting
// 用途: 区分 KPIGroup 层与 ColName 层的背景色
// 依赖: ISINSCOPE('Dim_ColMetric_Merchandising_Core_KPI'[ColName])
// ========================================
    VAR __IsKPICol = ISINSCOPE('Dim_ColMetric_Merchandising_Core_KPI'[ColName])
    RETURN
        IF(
            __IsKPICol,
            "#FFFFFF",   // ColName 层（指标列）: 白色
            "#E6D9C7"    // KPIGroup 层（分组列）: 中米色
        )
```

---

## 5. 度量值清单与 Display Folder

| 序号 | 度量值名称                                   | Display Folder | 用途                                                                                          |
| ---- | -------------------------------------------- | -------------- | --------------------------------------------------------------------------------------------- |
| 1    | Merchandising Core KPI Act Base Value        | Base Metrics   | This Period 基础值（区间类 + 期末时点类）；Amt/Unit + 商品标签 + Metric_ID 三重路由；RMB 原值 |
| 2    | Merchandising Core KPI LY Base Value         | Base Metrics   | Last Period 基础值（vs LY 对比基线，读 Min_Last / Max_Last 筛选器）                           |
| 3    | Merchandising Core KPI TAR Base Value        | Base Metrics   | TAR 类三指标（TAR ACH% / MTD / YTD TAR Progress）：actual ÷ target；Amt/Unit 字段路由 + 时间粒度分支 |
| 4    | Merchandising Core KPI Base Value            | Base Metrics   | 总路由（Act + vs LY 变化率 / 差值 bp + TAR 类三分支 + REMOVEFILTERS）；21 列全覆盖            |
| 5    | Merchandising Core KPI Cell Value            | Cell Values    | 对外值：当前模式金额类触发汇率换算（÷ Currency_ExchangeRate），其余直接返回                  |
| 6    | Merchandising Core KPI Cell Display          | Formatting     | 格式化显示文本（模式相关 Metric_Format；percent_1dp；delta_bp ×10000 转 bp；币种符号拼接）    |
| 7    | Merchandising Core KPI Cell Font Color       | Formatting     | 字体颜色（Act=fixed_black；vs LY / TAR 类=pos_neg_zero 三色）                                 |
| 8    | Merchandising Core KPI Cell Background Color | Formatting     | 背景色（KPIGroup 层#E6D9C7 vs ColName 层 #FFFFFF）                                            |

---

## 6. 血缘关系图

```
┌─────────────────────────────────────────────────────────────────────┐
│                        数据源层                                      │
│  a02_e2e_product_performance_sales_summary_d（销售类，日粒度）       │
│  字段: data_date, platform, shop_name, label, division,             │
│        product_type, framework, category, ax_class,                 │
│        category_summary, special_supply, predictive_buy,            │
│        super_season, md_type, computed_product_tag,                 │
│        net_sales_amt/qty, md_net_sales_amt, msrp_net_sales_amt,     │
│        msrp_inbound_amt, inbound_qty, md_outbound_amt, outbound_qty │
│  a02_e2e_product_performance_inv_summary_d（库存类，日快照）        │
│  字段: data_date + 商品维度（无 platform/shop_name）,                │
│        msrp_inv_amt, inv_qty, msrp_in_trans_inv_amt,                │
│        in_trans_inv_qty, msrp_o2o_inv_amt, o2o_inv_qty              │
│  a05_e2e_product_fcst_data_d（目标类，无 computed_product_tag）     │
│  字段: data_date, platform, shop_name, brand, framework,            │
│        category, fcst_sales_amt, fcst_sales_qty                     │
└──────────────────────────────┬──────────────────────────────────────┘
                               │ 渠道/商品切片器 1:N 自动传递（无需 DAX）
                               ▼
┌─────────────────────────────────────────────────────────────────────┐
│                        度量值层                                      │
│                                                                     │
│  ┌───────────────────────────┐   ┌───────────────────────────┐      │
│  │ Merchandising Core KPI    │   │ Merchandising Core KPI    │      │
│  │ Act Base Value            │   │ LY Base Value             │      │
│  │ (This Period 区间/期末)   │   │ (Last Period 区间/期末)   │      │
│  └────────────┬──────────────┘   └────────────┬──────────────┘      │
│               │        ┌──────────────────────────────┐             │
│               │◄───────│ IsAmtUnitFilter              │             │
│               │        │ (Sort=10 Amt / =20 Unit)     │             │
│               │        ├──────────────────────────────┤             │
│               │◄───────│ IsProductTagFilter           │             │
│               │        │ (ALL/Hero/Slow/Normal)       │             │
│               │        ├──────────────────────────────┤             │
│               │◄───────│ Slicer_Time_Frame_Min/Max_   │             │
│               │        │ This / Min/Max_Last          │             │
│               ▼        └──────────────────────────────┘             │
│  ┌──────────────────────────────────────────────────────┐           │
│  │ Merchandising Core KPI TAR Base Value                │           │
│  │ (TAR ACH% / MTD / YTD: actual ÷ target;              │           │
│  │  Amt/Unit 字段路由 + 时间粒度分支;                    │           │
│  │  actual←sales, target←a05[fcst_sales_amt/qty])       │           │
│  │          ▲ Slicer_Time_Frame[TimeFrame_ID]           │           │
│  │          │ + 财月/财年区间与跨期判定字段              │           │
│  └───────────────────────┬──────────────────────────────┘           │
│                          ▼                                          │
│  ┌──────────────────────────────────────────────────────┐           │
│  │ Merchandising Core KPI Base Value                    │           │
│  │ (总路由: Act + vs LY 变化率/差值bp + TAR 类三分支)    │           │
│  │ REMOVEFILTERS + 目标 Metric_ID                        │           │
│  │          ▲ Dim_ColMetric_Merchandising_Core_KPI      │           │
│  │          │ (Metric_ID, Metric_Format_Amt/Unit,       │           │
│  │          │  Metric_IsCurrencyAmount, ColorRule)      │           │
│  └───────────────────────┬──────────────────────────────┘           │
│                          ▼                                          │
│  ┌──────────────────────────────────────────────────────┐           │
│  │ Merchandising Core KPI Cell Value                    │           │
│  │ (当前模式金额类汇率换算 ÷ Currency_ExchangeRate)      │           │
│  │          ▲ Slicer_Currency_Selection                 │           │
│  └───────────────────────┬──────────────────────────────┘           │
│                          ▼                                          │
│  ┌──────────────────────────────────────────────────────┐           │
│  │ Merchandising Core KPI Cell Display                  │           │
│  │ (Metric_Format_Amt/Unit 按模式取一; delta_bp ×10000)  │           │
│  └───────────────────────┬──────────────────────────────┘           │
│                          ▼                                          │
│  ┌──────────────────────────────────────────────────────┐           │
│  │ Cell Font Color / Cell Background Color               │           │
│  └──────────────────────────────────────────────────────┘           │
└─────────────────────────────────────────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────────┐
│                        可视化层（矩阵 / 卡片图）                      │
│  矩阵:                                                               │
│    列: 'Dim_ColMetric_Merchandising_Core_KPI'[KPIGroup] > [ColName] │
│        （ColName_Sort / KPIGroup_Sort 排序）                        │
│    行/切片: 'IsProductTagFilter'[Label]（或作按钮切片器）           │
│    按钮: 'IsAmtUnitFilter'[Label]（Amt / Unit 切换）                │
│    值: [Merchandising Core KPI Cell Display]                        │
│    条件格式: 字体颜色 → Cell Font Color；背景色 → Cell Background   │
│  卡片图:                                                              │
│    每张卡片通过视觉级筛选器固定 Dim[ColName] 为唯一值                │
│    （ColName 带 Metric_ID 前缀，全局唯一，保证 Metric_ID 路由生效）  │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 7. 注意事项

1. **TAR 类三指标真实现（占位符已废弃）**：TAR ACH%（Metric_ID=21）= This actual / This target（date to date，全粒度）；MTD TAR Progress（3）actual 恒为 This Period 区间，Day/Week 不跨财月取 TimeFrame_Max 所在财月汇总 target（跨财月不计算）、Month This/This、Quarter/Year 不计算；YTD TAR Progress（4）Day/Week/Month/Quarter 不跨财年取所在财年汇总 target（跨财年不计算）、Year 始终计算且 This/This。计算在 TAR Base Value 内完成（粒度分支 + 跨期判定），“不计算”返回 BLANK → Display 显示 "-"（卡片显示空）。
2. **LY = Last Period 筛选器**：本方案 LY 直接读 Slicer_Time_Frame_Min_Last[TimeFrame_Min] / Slicer_Time_Frame_Max_Last[TimeFrame_Max]（非 _LY 字段对称映射，与 Customer 模块不同）；期末时点类 LY 读 Max_Last 表的 TimeFrame_Min / TimeFrame_Max 范围。依赖模型中 Last 表与主时间筛选器的既有关系配置。
3. **期末时点口径**：EOH / In-Transit / O2O / ST% 分母取 end period 范围 [Max_This[TimeFrame_Min], Max_This[TimeFrame_Max]] 内**最后一个快照日**（快照缺数时自动回退到范围内最近一天）；快照表按日存储，只取单日，对整段区间求和会重复计数库存。__EndPeriodDate 用 REMOVEFILTERS(inv) 计算，保证快照日不随商品切片器或矩阵上下文漂移。
4. **ST% 跨双表口径**：分子（sales）为整个 This Period 区间汇总，分母（inv）为期末快照日单日值，两者时间口径不同，不可混用（提示词第 4 点）。
5. **inv 表无渠道字段**：a02_e2e_product_performance_inv_summary_d 无 platform / shop_name 字段，渠道筛选（Slicer_Platform_Selection / Slicer_Store_Name）不影响 EOH / In-Transit / O2O 及 ST% 分母；ST% 分子（sales 侧）受渠道筛选影响，分母不受影响，需业务知悉该口径影响。
6. **Fullprice% 双公式**：Amt = sum(case when md_type = "FP" then net_sales_amt else 0 end) / sum(net_sales_amt)；Unit = sum(msrp_net_sales_amt) / sum(net_sales_amt)（口径已确认，Unit 版分子分母均为金额字段）。
7. **AVG MD 与 AUR 双模式共享**：口径标注【Amt】【Unit】同一套逻辑，DAX 中不重复计算（同一组聚合变量两个模式复用）。
8. **商品标签过滤**：UNION+FILTER 构造表类型稳定的过滤器（避免 IF 退化表变量）；ALL(computed_product_tag) 全量替换该列筛选（该列不是切片器字段，筛选仅来自 IsProductTagFilter 按钮）。选中 "ALL" → IN {"hero model", "slow mover", "normal"} 三值；未选或多选时默认 "ALL"。IsProductTagFilter 作矩阵行或按钮切片器均兼容（SELECTEDVALUE 逐行取值，汇总行回退 ALL）。
9. **Amt/Unit 默认值**：SELECTEDVALUE('IsAmtUnitFilter'[Sort], 10)，未选择时默认 Amt 逻辑。
10. **REMOVEFILTERS 机制**：vs LY 派生列取值必须先 REMOVEFILTERS('Dim_ColMetric_Merchandising_Core_KPI') 再应用目标 Metric_ID，否则矩阵行/列标题保留的筛选器会导致冲突返回 BLANK；TAR 类三指标在自身 Metric_ID 上下文内计算（TAR Base Value），无需重路由。
11. **Metric_ID 路由生效前提**：SELECTEDVALUE(Dim[Metric_ID]) 依赖矩阵列（KPIGroup > ColName）将 Dim 表筛选到单行；ColName 带 Metric_ID 前缀全局唯一是前提（同名区分机制）。KPIGroup 层汇总单元格无唯一 ColName → BLANK → 显示 "-"。
12. **汇率换算分层**：Base Value 层始终保留 RMB 原始值（Act / LY 派生计算口径一致）；换算集中在展示层 Cell Value（÷ Currency_ExchangeRate，RMB 时汇率 = 1）；Cell Display 只拼接 Currency_Symbol。金额类判定为模式相关：IF(__IsAmt, Metric_Format_Amt = "currency", Metric_Format_Unit = "currency")，Unit 模式下仅 AUR 换算。
13. **delta_bp 转换位置**：Base Value 返回原始差值（如 0.04），Cell Display 中 ×10000 转 bp（+400bp），乘法不落在 Base 层，保证派生值可复用。
14. **vs LY 派生空值规则**：变化率在 LY 空或 0 时返回 BLANK；差值 bp 在 Act 或 LY 任一为空时返回 BLANK。
15. **AVG MD 空值保护**：分母（msrp_net_sales_amt）空或 0 时返回 BLANK，避免 1 - BLANK() = 1（即 100% 折扣）的失真。
16. **字段名已核对数据字典**：net_sales_amt / net_sales_qty / md_net_sales_amt / msrp_net_sales_amt / msrp_inbound_amt / inbound_qty / md_outbound_amt / outbound_qty（sales 表）；msrp_inv_amt / inv_qty / msrp_in_trans_inv_amt / in_trans_inv_qty / msrp_o2o_inv_amt / o2o_inv_qty（inv 表）；日期字段统一为 data_date（date 类型）。
17. **DAX 语法规范**：文本常量使用双引号（如 [md_type] = "FP"），单引号仅用于表名，列名使用方括号；与解决方案存在争议时一切以口径文档为准。
18. **TAR 类 Amt/Unit 字段路由**：actual = sales[net_sales_amt]（Amt）/ [net_sales_qty]（Unit）；target = a05[fcst_sales_amt]（Amt）/ [fcst_sales_qty]（Unit）。三指标双模式格式列相同（TAR ACH% 为 percent_0dp、MTD / YTD 为 percent_1dp）；比率为同模式同币种相除，不受币种选择影响（Cell Value 层仅 currency 格式触发换算，percent 类不涉及）。
19. **TAR 类标签口径不对称（物理限制）**：actual 侧受 IsProductTagFilter 商品标签过滤（与模块其他指标一致）；a05 无 computed_product_tag 字段，target 侧无法按标签过滤——选中非 ALL 标签时分子分母标签口径不对称，需业务知悉。
20. **a05 关系与日期断开**：a05 与日期筛选器断开维度，target 三区间（This Period / 财月 / 财年）在 TAR Base Value 内 data_date 显式过滤；渠道（platform / shop_name）与商品维度（brand / framework / category 等）切片器与 a05 一对多关联自动传导，actual / target 维度口径天然一致。
