# Power BI 解决方案 — Overview_KPIs_BossCoreKPI 矩阵（子模块一：BOSS Core KPI）

> status: ready
> created: 2026-07-30
> type: 度量值开发 + 可视化构建
> 口径来源: 口径文档/Overview.md 子模块一：BOSS Core KPI（12 个基础 KPI × 3 列 = 36 个单元格指标）
> 行维度: Overview/BOSS Core KPI/Dim_RowKPIs_BossCoreKPI_Overview（2 分组 × 12 KPI）
> 列维度: Overview/BOSS Core KPI/Dim_ColKPIs_BossCoreKPI_Overview（6 店铺 × 3 列）
> 参考: RL E2E Traffic_Dashboard/KPI Progress/KPIS/KPIs_matrix_solution.md

---

## 1. 需求理解

实现 BOSS Performance Dashboard → Overview → BOSS Core KPI 子模块的中国式矩阵效果：

- **行**：`Dim_RowKPIs_BossCoreKPI_Overview` 的两级层级 `KPIGroup`（父）> `KPIName`（子）
  - Sales 分组（calc_type=payment）：SLS / Demand SLS / SLS Penetration / Return / Return%
  - Fulfillment 分组（calc_type=fulfillment）：Fulfillment% / Request Order Qty / Request Units / Request Order Amt / Shipped Order Qty / Shipped Units / Shipped Order Amt
- **列**：`Dim_ColKPIs_BossCoreKPI_Overview` 的两级层级 `StoreGroup`（父）> `ColName`（子）
  - 6 个店铺分组：TM / JD / RLE_CN / DY_Family / DY_W / DY_MN（对应事实表 store_name）
  - 每个店铺分组下 3 列：Act / LY / vs LY
- **值**：SWITCH 动态路由，按 `RowKPI_ID` × `ColType` 分发到本期 / 去年同期 / vs LY 派生值
- **口径**：一切以口径文档 Overview.md 子模块一为准
- **筛选器**：
  - Slicer_Time_Frame_Min/Max（断开维度，筛选 data_date）
  - Slicer_Currency_Selection（断开维度，仅金额类指标 ÷ 汇率）
  - Slicer_Fulfillment_Calc_Type（1:N 关系，模型自动筛选 fulfillment_calc_type）

---

## 2. 现状分析

### 2.1 数据底表

| 对象     | 名称                                                                                                                                                                                                                                                                                                                   | 出处                                              |
| -------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------- |
| 事实表   | a02_e2e_boss_performance_summary_d                                                                                                                                                                                                                                                                                     | 维度复用/a02_e2e_boss_performance_summary_d.sql   |
| 关键字段 | data_date, store_name, calc_type, fulfillment_calc_type,o2o_net_sales_amt, o2o_sales_amt, sales_amt, o2o_return_amt,o2o_fulfillment_shipped_order_cnt, o2o_fulfillment_request_order_cnt,o2o_fulfillment_request_qty, o2o_fulfillment_request_sales_amt,o2o_fulfillment_shipped_qty, o2o_fulfillment_shipped_sales_amt | 口径文档 Overview.md 子模块一 + 参考文件/数据字典 |

### 2.2 维度表清单

| 维度表                           | 类型     | 连接方式                                                                                       | 出处                                                    |
| -------------------------------- | -------- | ---------------------------------------------------------------------------------------------- | ------------------------------------------------------- |
| Slicer_Time_Frame_Min            | 断开维度 | SELECTEDVALUE 读取 TimeFrame_Min                                                               | 维度复用/Slicer_Time_Frame_Min.sql                      |
| Slicer_Time_Frame_Max            | 断开维度 | SELECTEDVALUE 读取 TimeFrame_Max                                                               | 维度复用/Slicer_Time_Frame_Max.sql                      |
| Slicer_Currency_Selection        | 断开维度 | SELECTEDVALUE 读取 Currency_ExchangeRate, Currency_Symbol                                      | 维度复用/Slicer_Currency_Selection                      |
| Slicer_Fulfillment_Calc_Type     | 1:N 关系 | Calc_Type_ID → 事实表[fulfillment_calc_type]（模型自动筛选）                                  | 维度复用/Slicer_Fulfillment_Calc_Type                   |
| Dim_RowKPIs_BossCoreKPI_Overview | 断开维度 | SELECTEDVALUE 读取 RowKPI_ID, KPI_CalcType, Metric_Format_Act/LY/VsLY, Metric_IsCurrencyAmount | Overview/BOSS Core KPI/Dim_RowKPIs_BossCoreKPI_Overview |
| Dim_ColKPIs_BossCoreKPI_Overview | 断开维度 | SELECTEDVALUE 读取 StoreGroup_ID, ColType, Metric_Color*                                       | Overview/BOSS Core KPI/Dim_ColKPIs_BossCoreKPI_Overview |

### 2.3 行维度表（12 个基础 KPI）

| RowKPI_ID | KPIGroup    | KPIName           | KPIName_CN        | KPI_CalcType | Format_Act  | Format_VsLY | IsCurrencyAmount |
| --------- | ----------- | ----------------- | ----------------- | ------------ | ----------- | ----------- | ---------------- |
| 10        | Sales       | SLS               | O2O销售净额       | payment      | currency    | percent_1dp | TRUE             |
| 20        | Sales       | Demand SLS        | O2O退前销售额     | payment      | currency    | percent_1dp | TRUE             |
| 30        | Sales       | SLS Penetration   | O2O销售渗透率     | payment      | percent_1dp | delta_bp    | FALSE            |
| 40        | Sales       | Return            | O2O退货金额       | payment      | currency    | percent_1dp | TRUE             |
| 50        | Sales       | Return%           | O2O退货率（金额） | payment      | percent_1dp | delta_bp    | FALSE            |
| 110       | Fulfillment | Fulfillment%      | O2O订单履约率     | fulfillment  | percent_1dp | delta_bp    | FALSE            |
| 120       | Fulfillment | Request Order Qty | O2O销售订单量     | fulfillment  | integer     | percent_1dp | FALSE            |
| 130       | Fulfillment | Request Units     | O2O商品销售件数   | fulfillment  | integer     | percent_1dp | FALSE            |
| 140       | Fulfillment | Request Order Amt | O2O销售金额       | fulfillment  | currency    | percent_1dp | TRUE             |
| 150       | Fulfillment | Shipped Order Qty | O2O已配货订单量   | fulfillment  | integer     | percent_1dp | FALSE            |
| 160       | Fulfillment | Shipped Units     | O2O已配货商品件数 | fulfillment  | integer     | percent_1dp | FALSE            |
| 170       | Fulfillment | Shipped Order Amt | O2O已配货销售金额 | fulfillment  | currency    | percent_1dp | TRUE             |

### 2.4 列维度表（6 店铺 × 3 列 = 18 列）

| StoreGroup_ID | StoreGroup | ColName       | ColType | StoreGroup_Sort | ColName_Sort |
| ------------- | ---------- | ------------- | ------- | --------------- | ------------ |
| TM            | TM         | Act           | Act     | 10              | 1            |
| TM            | TM         | LY            | LY      | 10              | 2            |
| TM            | TM         | vs LY         | vs LY   | 10              | 3            |
| JD            | JD         | Act (1空格)   | Act     | 20              | 11           |
| JD            | JD         | LY (1空格)    | LY      | 20              | 12           |
| JD            | JD         | vs LY (1空格) | vs LY   | 20              | 13           |
| RLE_CN        | RLE_CN     | Act (2空格)   | Act     | 30              | 21           |
| ...           | ...        | ...           | ...     | ...             | ...          |
| DY_MN         | DY_MN      | vs LY (5空格) | vs LY   | 60              | 53           |

---

## 3. 方案设计

### 3.1 整体架构

```
核心思路：断开维度 + SWITCH 动态路由（Disconnected Dimensions + Dispatch Pattern）

Dim_RowKPIs_BossCoreKPI_Overview（断开维度，行头）      Dim_ColKPIs_BossCoreKPI_Overview（断开维度，列头）
    │                                                          │
    │  无关系连接，仅通过 SELECTEDVALUE 读取：                  │  无关系连接，仅通过 SELECTEDVALUE 读取：
    │  - RowKPI_ID, KPI_CalcType, Metric_Format_*              │  - StoreGroup_ID（用于筛选 store_name）
    │  - Metric_IsCurrencyAmount                               │  - ColType（Act / LY / vs LY）
    │                                                          │  - Metric_Color*
    ▼                                                          ▼
    ┌─────────────────────────── Matrix 视觉对象 ──────────────────────────┐
    │  行 = 'Dim_RowKPIs_BossCoreKPI_Overview'[KPIGroup]                     │
    │        > 'Dim_RowKPIs_BossCoreKPI_Overview'[KPIName]                   │
    │  列 = 'Dim_ColKPIs_BossCoreKPI_Overview'[StoreGroup]                   │
    │        > 'Dim_ColKPIs_BossCoreKPI_Overview'[ColName]                   │
    │  值 = [BOSS Core KPI Cell Display]                                    │
    └────────────────────────────────────────────────────────────────────────┘
                                   ▲
                                   │
              SWITCH 动态路由度量值链（按 RowKPI_ID × ColType 分发）
              ┌────────────────────────────────────────────────────┐
              │  [BOSS Core KPI Cell Value]                          │
              │    └→ [BOSS Core KPI Act Base Value]（本期值）       │
              │    └→ [BOSS Core KPI LY Base Value] （去年同期值）   │
              │    └→ [BOSS Core KPI vs LY Base Value]（派生同比）   │
              └────────────────────────────────────────────────────┘
```

### 3.2 度量值模型设计

```
[BOSS Core KPI Act Base Value]    ← 本期基础值（按 RowKPI_ID 路由，应用时间/store_name/calc_type/汇率筛选）
[BOSS Core KPI LY Base Value]     ← 去年同期基础值（财历映射：Day 用 EDATE -12，其他粒度用 Key 偏移查找）
[BOSS Core KPI vs LY Base Value]  ← vs LY 派生（按 Metric_Format_VsLY 分支：金额/数量类=今年/去年-1，比率类=今年-去年）
[BOSS Core KPI Cell Value]        ← 对外值 = 按 ColType 选择 Act / LY / vs LY
[BOSS Core KPI Cell Display]      ← 格式化显示文本（按 Metric_Format_Act/LY/VsLY 选择格式）
[BOSS Core KPI Cell Font Color]   ← 字体颜色（区分 KPIGroup 行/KPI 行 × vs LY 列/其他列）
[BOSS Core KPI Cell Background Color] ← 背景色（区分 KPIGroup 行/KPI 行）
[BOSS Core KPI Cell SVG Icon]     ← SVG 图标（仅 vs LY 列 + KPI 行）
```

### 3.3 筛选器上下文

| 筛选器                                          | 作用方式                                                            | DAX 处理                            |
| ----------------------------------------------- | ------------------------------------------------------------------- | ----------------------------------- |
| Slicer_Time_Frame_Min                           | 断开维度，SELECTEDVALUE 读取 TimeFrame_Min                          | `data_date >= __TimeMin`          |
| Slicer_Time_Frame_Max                           | 断开维度，SELECTEDVALUE 读取 TimeFrame_Max                          | `data_date <= __TimeMax`          |
| Dim_ColKPIs_BossCoreKPI_Overview[StoreGroup_ID] | 断开维度，SELECTEDVALUE 读取 StoreGroup_ID，空时返回所有店铺汇总    | `__StoreFilterTable`（自适应单店铺/多店铺） |
| Dim_RowKPIs_BossCoreKPI_Overview[KPI_CalcType]  | 断开维度，SELECTEDVALUE 读取 KPI_CalcType                           | `calc_type = __CalcType`          |
| Slicer_Fulfillment_Calc_Type                    | 1:N 关系，模型自动筛选 fulfillment_calc_type                        | 无需显式处理                        |
| Slicer_Currency_Selection                       | 断开维度，SELECTEDVALUE 读取 Currency_ExchangeRate, Currency_Symbol | 金额类指标 ÷ Currency_ExchangeRate |

### 3.4 vs LY 时间偏移规则（财历映射）

**背景**：周/月/季/年粒度按财年定义（财年2026 ≠ 公历2026），如财年2026 = 2025-03-30 ~ 2026-03-28。EDATE -12 基于公历自然日偏移，会因闰年星期错位导致 LY 范围与"去年同编号财周/月/季/年"差1天。因此 LY 必须采用**财历映射**：通过 TimeFrame_Key 偏移查找去年同期同编号时间段的自然日范围。

**Key 偏移规则**（基于 Slicer_Time_Frame.sql 定义）：

| TimeFrame_ID | TimeFrame_Key 公式 | LY Key 计算 | 示例 |
|--------------|-------------------|-------------|------|
| Day | `date_key`（如 20251024） | 用 EDATE -12（自然日无财历概念） | 2025-10-24 → 2024-10-24 |
| Week | `financial_year * 100 + financial_week_num` | `Key - 100` | 202614 → 202514 |
| Month | `financial_year * 100 + financial_month_num` | `Key - 100` | 202610 → 202510 |
| Quarter | `financial_year * 100 + financial_quarter_num` | `Key - 100` | 202603 → 202503 |
| Year | `financial_year` | `Key - 1` | 2026 → 2025 |

**查找流程**（卡片图场景：仅全局日期筛选，无 X 轴）：

```
1. 从 Slicer_Time_Frame_Min[TimeFrame_ID] 读取当前粒度（Min/Max 同粒度）
2. 全局 LY 起始日：
   - 从 Min 切片器读 TimeFrame_Key，按规则计算 LY Key
   - 在 Slicer_Time_Frame_Min 表查找 [TimeFrame_ID] + [LY Key] 匹配行
   - 读取该行 TimeFrame_Min（LY 起始日）
3. 全局 LY 结束日：
   - 从 Max 切片器读 TimeFrame_Key（与 Min 的 Key 不同，独立计算），按规则计算 LY Key
   - 在 Slicer_Time_Frame_Max 表查找 [TimeFrame_ID] + [LY Key] 匹配行
   - 读取该行 TimeFrame_Max（LY 结束日）
4. 用 LY 自然日范围 [__LYTimeMin, __LYTimeMax] 筛选事实表 data_date
```

**示例**（Min = 2026 Week14, Max = 2026 Week19）：

```
当前时间段（TY）:
  __TimeMin = Min 切片器 TimeFrame_Min = 2025-06-29
  __TimeMax = Max 切片器 TimeFrame_Max = 2025-08-09

LY 财历映射:
  Min LY Key = 202614 - 100 = 202514
    → 查 Slicer_Time_Frame_Min 表 Week + Key=202514 → TimeFrame_Min=2024-06-30（假设）
  Max LY Key = 202619 - 100 = 202519
    → 查 Slicer_Time_Frame_Max 表 Week + Key=202519 → TimeFrame_Max=2024-08-04（假设）
  __LYTimeMin = 2024-06-30
  __LYTimeMax = 2024-08-04
```

**关键差异**：
- EDATE -12（错误）：2024-06-29 ~ 2024-08-09（公历偏移，可能跨财周）
- 财历映射（正确）：2024-06-30 ~ 2024-08-04（去年同编号财周的完整定义范围）

**数据要求**：Slicer_Time_Frame(_Min/_Max) 表需包含至少2年历史数据（当前年 + 去年同期）。若数据历史不足1年，LY 查找返回 BLANK，卡片显示"-"，属可接受行为。

### 3.5 vs LY 派生计算分类

| KPI 分类       | vs LY 计算方式                    | Metric_Format_VsLY | 展示示例 |
| -------------- | --------------------------------- | ------------------ | -------- |
| 金额类（5 个） | 今年 / 去年 − 1                  | percent_1dp        | 14.5%    |
| 数量类（4 个） | 今年 / 去年 − 1                  | percent_1dp        | 8.3%     |
| 比率类（3 个） | 今年 − 去年（差值，×10000 转 bp） | delta_bp           | +120bp   |

金额类 KPI：SLS / Demand SLS / Return / Request Order Amt / Shipped Order Amt
数量类 KPI：Request Order Qty / Request Units / Shipped Order Qty / Shipped Units
比率类 KPI：SLS Penetration / Return% / Fulfillment%

---

## 4. 度量值实现

### 4.1 BOSS Core KPI Act Base Value（本期基础值）

```dax
BOSS Core KPI Act Base Value = 
// ========================================
// 度量值: BOSS Core KPI Act Base Value
// Display Folder: Base Metrics
// 用途: 根据 RowKPI_ID 路由到本期（Act）基础值
// 依赖: 'Dim_RowKPIs_BossCoreKPI_Overview'[RowKPI_ID],
//       'Dim_ColKPIs_BossCoreKPI_Overview'[StoreGroup_ID],
//       a02_e2e_boss_performance_summary_d
// 口径来源: Overview.md 子模块一 BOSS Core KPI 的本期值
// 筛选上下文:
//   - data_date ∈ [__TimeMin, __TimeMax]
//   - store_name = __StoreName（来自列维度 StoreGroup_ID）
//   - calc_type = __CalcType（来自行维度 KPI_CalcType：Sales→payment, Fulfillment→fulfillment）
//   - fulfillment_calc_type 由 Slicer_Fulfillment_Calc_Type 1:N 关系自动筛选
//   - 金额类指标（Metric_IsCurrencyAmount=TRUE）÷ __FXRate（汇率）
// ========================================
    VAR __RowKPIID = SELECTEDVALUE('Dim_RowKPIs_BossCoreKPI_Overview'[RowKPI_ID])
    VAR __CalcType = SELECTEDVALUE('Dim_RowKPIs_BossCoreKPI_Overview'[KPI_CalcType])
    VAR __IsCurrencyAmount = SELECTEDVALUE('Dim_RowKPIs_BossCoreKPI_Overview'[Metric_IsCurrencyAmount], FALSE)
 	VAR __StoreNames = VALUES('Dim_ColKPIs_BossCoreKPI_Overview'[StoreGroup_ID])
    // ── 时间筛选：本期 ──
    VAR __TimeMin = SELECTEDVALUE(Slicer_Time_Frame_Min[TimeFrame_Min])
    VAR __TimeMax = SELECTEDVALUE(Slicer_Time_Frame_Max[TimeFrame_Max])
    // ── 汇率（金额类指标需要除以汇率）──
    VAR __FXRate = SELECTEDVALUE(Slicer_Currency_Selection[Currency_ExchangeRate], 1)

    // ═══════════════════════════════════════
    // 基础聚合：calc_type = payment（Sales 分组）
    // ═══════════════════════════════════════
    // SLS O2O销售净额 = SUM(o2o_net_sales_amt)
    VAR __SLS_Act =
        CALCULATE(
            SUM('a02_e2e_boss_performance_summary_d'[o2o_net_sales_amt]),
            'a02_e2e_boss_performance_summary_d'[calc_type] = __CalcType,
            'a02_e2e_boss_performance_summary_d'[store_name] IN __StoreNames,
            'a02_e2e_boss_performance_summary_d'[data_date] >= __TimeMin,
            'a02_e2e_boss_performance_summary_d'[data_date] <= __TimeMax
        )
    // Demand SLS O2O退前销售额 = SUM(o2o_sales_amt)
    VAR __DemandSLS_Act =
        CALCULATE(
            SUM('a02_e2e_boss_performance_summary_d'[o2o_sales_amt]),
            'a02_e2e_boss_performance_summary_d'[calc_type] = __CalcType,
            'a02_e2e_boss_performance_summary_d'[store_name] IN __StoreNames,
            'a02_e2e_boss_performance_summary_d'[data_date] >= __TimeMin,
            'a02_e2e_boss_performance_summary_d'[data_date] <= __TimeMax
        )
    // SLS Penetration O2O销售渗透率 分子 o2o_sales_amt（与 Demand SLS 同字段）
    // 分母 sales_amt 也需在同一筛选上下文下聚合
    VAR __SLS_Penetration_Numerator_Act =
        CALCULATE(
            SUM('a02_e2e_boss_performance_summary_d'[o2o_sales_amt]),
            'a02_e2e_boss_performance_summary_d'[calc_type] = __CalcType,
            'a02_e2e_boss_performance_summary_d'[store_name] IN __StoreNames,
            'a02_e2e_boss_performance_summary_d'[data_date] >= __TimeMin,
            'a02_e2e_boss_performance_summary_d'[data_date] <= __TimeMax
        )
    VAR __SLS_Penetration_Denominator_Act =
        CALCULATE(
            SUM('a02_e2e_boss_performance_summary_d'[sales_amt]),
            'a02_e2e_boss_performance_summary_d'[calc_type] = __CalcType,
            'a02_e2e_boss_performance_summary_d'[store_name] IN __StoreNames,
            'a02_e2e_boss_performance_summary_d'[data_date] >= __TimeMin,
            'a02_e2e_boss_performance_summary_d'[data_date] <= __TimeMax
        )
    VAR __SLS_Penetration_Act = DIVIDE(__SLS_Penetration_Numerator_Act, __SLS_Penetration_Denominator_Act)
    // Return O2O退货金额 = SUM(o2o_return_amt)
    VAR __Return_Act =
        CALCULATE(
            SUM('a02_e2e_boss_performance_summary_d'[o2o_return_amt]),
            'a02_e2e_boss_performance_summary_d'[calc_type] = __CalcType,
            'a02_e2e_boss_performance_summary_d'[store_name] IN __StoreNames,
            'a02_e2e_boss_performance_summary_d'[data_date] >= __TimeMin,
            'a02_e2e_boss_performance_summary_d'[data_date] <= __TimeMax
        )
    // Return% O2O退货率（金额）= SUM(o2o_return_amt) / SUM(o2o_sales_amt)
    VAR __Return_Pct_Numerator_Act =
        CALCULATE(
            SUM('a02_e2e_boss_performance_summary_d'[o2o_return_amt]),
            'a02_e2e_boss_performance_summary_d'[calc_type] = __CalcType,
            'a02_e2e_boss_performance_summary_d'[store_name] IN __StoreNames,
            'a02_e2e_boss_performance_summary_d'[data_date] >= __TimeMin,
            'a02_e2e_boss_performance_summary_d'[data_date] <= __TimeMax
        )
    VAR __Return_Pct_Denominator_Act =
        CALCULATE(
            SUM('a02_e2e_boss_performance_summary_d'[o2o_sales_amt]),
            'a02_e2e_boss_performance_summary_d'[calc_type] = __CalcType,
            'a02_e2e_boss_performance_summary_d'[store_name] IN __StoreNames,
            'a02_e2e_boss_performance_summary_d'[data_date] >= __TimeMin,
            'a02_e2e_boss_performance_summary_d'[data_date] <= __TimeMax
        )
    VAR __Return_Pct_Act = DIVIDE(__Return_Pct_Numerator_Act, __Return_Pct_Denominator_Act)

    // ═══════════════════════════════════════
    // 基础聚合：calc_type = fulfillment（Fulfillment 分组）
    // ═══════════════════════════════════════
    // Fulfillment% O2O订单履约率 = SUM(o2o_fulfillment_shipped_order_cnt) / SUM(o2o_fulfillment_request_order_cnt)
    VAR __Fulfillment_Pct_Numerator_Act =
        CALCULATE(
            SUM('a02_e2e_boss_performance_summary_d'[o2o_fulfillment_shipped_order_cnt]),
            'a02_e2e_boss_performance_summary_d'[calc_type] = __CalcType,
            'a02_e2e_boss_performance_summary_d'[store_name] IN __StoreNames,
            'a02_e2e_boss_performance_summary_d'[data_date] >= __TimeMin,
            'a02_e2e_boss_performance_summary_d'[data_date] <= __TimeMax
        )
    VAR __Fulfillment_Pct_Denominator_Act =
        CALCULATE(
            SUM('a02_e2e_boss_performance_summary_d'[o2o_fulfillment_request_order_cnt]),
            'a02_e2e_boss_performance_summary_d'[calc_type] = __CalcType,
            'a02_e2e_boss_performance_summary_d'[store_name] IN __StoreNames,
            'a02_e2e_boss_performance_summary_d'[data_date] >= __TimeMin,
            'a02_e2e_boss_performance_summary_d'[data_date] <= __TimeMax
        )
    VAR __Fulfillment_Pct_Act = DIVIDE(__Fulfillment_Pct_Numerator_Act, __Fulfillment_Pct_Denominator_Act)
    // Request Order Qty O2O销售订单量 = SUM(o2o_fulfillment_request_order_cnt)
    VAR __Request_Order_Qty_Act =
        CALCULATE(
            SUM('a02_e2e_boss_performance_summary_d'[o2o_fulfillment_request_order_cnt]),
            'a02_e2e_boss_performance_summary_d'[calc_type] = __CalcType,
            'a02_e2e_boss_performance_summary_d'[store_name] IN __StoreNames,
            'a02_e2e_boss_performance_summary_d'[data_date] >= __TimeMin,
            'a02_e2e_boss_performance_summary_d'[data_date] <= __TimeMax
        )
    // Request Units O2O商品销售件数 = SUM(o2o_fulfillment_request_qty)
    VAR __Request_Units_Act =
        CALCULATE(
            SUM('a02_e2e_boss_performance_summary_d'[o2o_fulfillment_request_qty]),
            'a02_e2e_boss_performance_summary_d'[calc_type] = __CalcType,
            'a02_e2e_boss_performance_summary_d'[store_name] IN __StoreNames,
            'a02_e2e_boss_performance_summary_d'[data_date] >= __TimeMin,
            'a02_e2e_boss_performance_summary_d'[data_date] <= __TimeMax
        )
    // Request Order Amt O2O销售金额 = SUM(o2o_fulfillment_request_sales_amt)
    VAR __Request_Order_Amt_Act =
        CALCULATE(
            SUM('a02_e2e_boss_performance_summary_d'[o2o_fulfillment_request_sales_amt]),
            'a02_e2e_boss_performance_summary_d'[calc_type] = __CalcType,
            'a02_e2e_boss_performance_summary_d'[store_name] IN __StoreNames,
            'a02_e2e_boss_performance_summary_d'[data_date] >= __TimeMin,
            'a02_e2e_boss_performance_summary_d'[data_date] <= __TimeMax
        )
    // Shipped Order Qty O2O已配货订单量 = SUM(o2o_fulfillment_shipped_order_cnt)
    VAR __Shipped_Order_Qty_Act =
        CALCULATE(
            SUM('a02_e2e_boss_performance_summary_d'[o2o_fulfillment_shipped_order_cnt]),
            'a02_e2e_boss_performance_summary_d'[calc_type] = __CalcType,
            'a02_e2e_boss_performance_summary_d'[store_name] IN __StoreNames,
            'a02_e2e_boss_performance_summary_d'[data_date] >= __TimeMin,
            'a02_e2e_boss_performance_summary_d'[data_date] <= __TimeMax
        )
    // Shipped Units O2O已配货商品件数 = SUM(o2o_fulfillment_shipped_qty)
    VAR __Shipped_Units_Act =
        CALCULATE(
            SUM('a02_e2e_boss_performance_summary_d'[o2o_fulfillment_shipped_qty]),
            'a02_e2e_boss_performance_summary_d'[calc_type] = __CalcType,
            'a02_e2e_boss_performance_summary_d'[store_name] IN __StoreNames,
            'a02_e2e_boss_performance_summary_d'[data_date] >= __TimeMin,
            'a02_e2e_boss_performance_summary_d'[data_date] <= __TimeMax
        )
    // Shipped Order Amt O2O已配货销售金额 = SUM(o2o_fulfillment_shipped_sales_amt)
    VAR __Shipped_Order_Amt_Act =
        CALCULATE(
            SUM('a02_e2e_boss_performance_summary_d'[o2o_fulfillment_shipped_sales_amt]),
            'a02_e2e_boss_performance_summary_d'[calc_type] = __CalcType,
            'a02_e2e_boss_performance_summary_d'[store_name] IN __StoreNames,
            'a02_e2e_boss_performance_summary_d'[data_date] >= __TimeMin,
            'a02_e2e_boss_performance_summary_d'[data_date] <= __TimeMax
        )

    // ═══════════════════════════════════════
    // 路由分发（按 RowKPI_ID）
    // 金额类指标 ÷ __FXRate（汇率换算）
    // ═══════════════════════════════════════
    RETURN
        SWITCH(
            __RowKPIID,
            // ─── Sales 分组（calc_type=payment）───
            10, IF(__IsCurrencyAmount, DIVIDE(__SLS_Act, __FXRate), __SLS_Act),                             // SLS O2O销售净额
            20, IF(__IsCurrencyAmount, DIVIDE(__DemandSLS_Act, __FXRate), __DemandSLS_Act),                 // Demand SLS O2O退前销售额
            30, __SLS_Penetration_Act,                                                                       // SLS Penetration O2O销售渗透率
            40, IF(__IsCurrencyAmount, DIVIDE(__Return_Act, __FXRate), __Return_Act),                       // Return O2O退货金额
            50, __Return_Pct_Act,                                                                            // Return% O2O退货率（金额）
            // ─── Fulfillment 分组（calc_type=fulfillment）───
            110, __Fulfillment_Pct_Act,                                                                      // Fulfillment% O2O订单履约率
            120, __Request_Order_Qty_Act,                                                                    // Request Order Qty O2O销售订单量
            130, __Request_Units_Act,                                                                        // Request Units O2O商品销售件数
            140, IF(__IsCurrencyAmount, DIVIDE(__Request_Order_Amt_Act, __FXRate), __Request_Order_Amt_Act), // Request Order Amt O2O销售金额
            150, __Shipped_Order_Qty_Act,                                                                    // Shipped Order Qty O2O已配货订单量
            160, __Shipped_Units_Act,                                                                        // Shipped Units O2O已配货商品件数
            170, IF(__IsCurrencyAmount, DIVIDE(__Shipped_Order_Amt_Act, __FXRate), __Shipped_Order_Amt_Act), // Shipped Order Amt O2O已配货销售金额
            BLANK()
        )
```

### 4.2 BOSS Core KPI LY Base Value（去年同期基础值，财历映射）

```dax
BOSS Core KPI LY Base Value = 
// ========================================
// 度量值: BOSS Core KPI LY Base Value
// Display Folder: Base Metrics
// 用途: 根据 RowKPI_ID 路由到去年同期（LY）基础值
// 依赖: 'Dim_RowKPIs_BossCoreKPI_Overview'[RowKPI_ID],
//       'Dim_ColKPIs_BossCoreKPI_Overview'[StoreGroup_ID],
//       Slicer_Time_Frame_Min/Max[TimeFrame_ID, TimeFrame_Key, TimeFrame_Min, TimeFrame_Max],
//       a02_e2e_boss_performance_summary_d
// 口径来源: Overview.md 子模块一 BOSS Core KPI 的 LY 值
// 时间偏移: 财历映射（Day 粒度用 EDATE -12，Week/Month/Quarter/Year 用 Key 偏移查找）
//   - 全局 LY 起始日: 从 Slicer_Time_Frame_Min 查 LY 同编号时间段的 TimeFrame_Min
//   - 全局 LY 结束日: 从 Slicer_Time_Frame_Max 查 LY 同编号时间段的 TimeFrame_Max
//   - Min/Max 各自独立算 LY Key（Key 不同，LY Key 也不同）
// 金额类指标 ÷ __FXRate（汇率换算），与 Act 保持一致
// 卡片图场景: 仅全局日期筛选，无 X 轴
// 前提: Slicer_Time_Frame(_Min/_Max) 表需包含去年同期数据，否则返回 BLANK
// ========================================
    VAR __RowKPIID = SELECTEDVALUE('Dim_RowKPIs_BossCoreKPI_Overview'[RowKPI_ID])
    VAR __CalcType = SELECTEDVALUE('Dim_RowKPIs_BossCoreKPI_Overview'[KPI_CalcType])
    VAR __IsCurrencyAmount = SELECTEDVALUE('Dim_RowKPIs_BossCoreKPI_Overview'[Metric_IsCurrencyAmount], FALSE)
    VAR __StoreNames = VALUES('Dim_ColKPIs_BossCoreKPI_Overview'[StoreGroup_ID])
    // ── 1. 读取全局粒度（Min/Max 同粒度，从 Min 切片器读取）──
    VAR __GlobalTFID = SELECTEDVALUE(Slicer_Time_Frame_Min[TimeFrame_ID])
    // ── 2. 全局 LY 起始日（从 Min 切片器查找）──
    VAR __GlobalMinKey = SELECTEDVALUE(Slicer_Time_Frame_Min[TimeFrame_Key])
    VAR __GlobalMinValue = SELECTEDVALUE(Slicer_Time_Frame_Min[TimeFrame_Min])
    VAR __LY_GlobalMinKey =
        SWITCH(
            __GlobalTFID,
            "Year",   __GlobalMinKey - 1,
            "Week",   __GlobalMinKey - 100,
            "Month",  __GlobalMinKey - 100,
            "Quarter", __GlobalMinKey - 100,
            BLANK()  // Day 走 EDATE 分支
        )
    VAR __LYTimeMin =
        IF(
            __GlobalTFID = "Day",
            EDATE(__GlobalMinValue, -12),
            CALCULATE(
                MIN(Slicer_Time_Frame_Min[TimeFrame_Min]),  // 读 TimeFrame_Min 字段（起始日）
                ALL(Slicer_Time_Frame_Min),
                Slicer_Time_Frame_Min[TimeFrame_ID] = __GlobalTFID,
                Slicer_Time_Frame_Min[TimeFrame_Key] = __LY_GlobalMinKey
            )
        )
    // ── 3. 全局 LY 结束日（从 Max 切片器查找，独立算 LY Key）──
    VAR __GlobalMaxKey = SELECTEDVALUE(Slicer_Time_Frame_Max[TimeFrame_Key])
    VAR __GlobalMaxValue = SELECTEDVALUE(Slicer_Time_Frame_Max[TimeFrame_Max])
    VAR __LY_GlobalMaxKey =
        SWITCH(
            __GlobalTFID,  // Min/Max 同粒度
            "Year",   __GlobalMaxKey - 1,
            "Week",   __GlobalMaxKey - 100,
            "Month",  __GlobalMaxKey - 100,
            "Quarter", __GlobalMaxKey - 100,
            BLANK()
        )
    VAR __LYTimeMax =
        IF(
            __GlobalTFID = "Day",
            EDATE(__GlobalMaxValue, -12),
            CALCULATE(
                MAX(Slicer_Time_Frame_Max[TimeFrame_Max]),  // 读 TimeFrame_Max 字段（结束日）
                ALL(Slicer_Time_Frame_Max),
                Slicer_Time_Frame_Max[TimeFrame_ID] = __GlobalTFID,
                Slicer_Time_Frame_Max[TimeFrame_Key] = __LY_GlobalMaxKey
            )
        )
    // ── 4. 汇率 ──
    VAR __FXRate = SELECTEDVALUE(Slicer_Currency_Selection[Currency_ExchangeRate], 1)

    // ═══════════════════════════════════════
    // 基础聚合：calc_type = payment（Sales 分组，去年同期）
    // ═══════════════════════════════════════
    VAR __SLS_LY =
        CALCULATE(
            SUM('a02_e2e_boss_performance_summary_d'[o2o_net_sales_amt]),
            'a02_e2e_boss_performance_summary_d'[calc_type] = __CalcType,
            'a02_e2e_boss_performance_summary_d'[store_name] IN __StoreNames,
            'a02_e2e_boss_performance_summary_d'[data_date] >= __LYTimeMin,
            'a02_e2e_boss_performance_summary_d'[data_date] <= __LYTimeMax
        )
    VAR __DemandSLS_LY =
        CALCULATE(
            SUM('a02_e2e_boss_performance_summary_d'[o2o_sales_amt]),
            'a02_e2e_boss_performance_summary_d'[calc_type] = __CalcType,
            'a02_e2e_boss_performance_summary_d'[store_name] IN  __StoreNames,
            'a02_e2e_boss_performance_summary_d'[data_date] >= __LYTimeMin,
            'a02_e2e_boss_performance_summary_d'[data_date] <= __LYTimeMax
        )
    VAR __SLS_Penetration_Numerator_LY =
        CALCULATE(
            SUM('a02_e2e_boss_performance_summary_d'[o2o_sales_amt]),
            'a02_e2e_boss_performance_summary_d'[calc_type] = __CalcType,
            'a02_e2e_boss_performance_summary_d'[store_name] IN  __StoreNames,
            'a02_e2e_boss_performance_summary_d'[data_date] >= __LYTimeMin,
            'a02_e2e_boss_performance_summary_d'[data_date] <= __LYTimeMax
        )
    VAR __SLS_Penetration_Denominator_LY =
        CALCULATE(
            SUM('a02_e2e_boss_performance_summary_d'[sales_amt]),
            'a02_e2e_boss_performance_summary_d'[calc_type] = __CalcType,
            'a02_e2e_boss_performance_summary_d'[store_name] IN  __StoreNames,
            'a02_e2e_boss_performance_summary_d'[data_date] >= __LYTimeMin,
            'a02_e2e_boss_performance_summary_d'[data_date] <= __LYTimeMax
        )
    VAR __SLS_Penetration_LY = DIVIDE(__SLS_Penetration_Numerator_LY, __SLS_Penetration_Denominator_LY)
    VAR __Return_LY =
        CALCULATE(
            SUM('a02_e2e_boss_performance_summary_d'[o2o_return_amt]),
            'a02_e2e_boss_performance_summary_d'[calc_type] = __CalcType,
            'a02_e2e_boss_performance_summary_d'[store_name] IN  __StoreNames,
            'a02_e2e_boss_performance_summary_d'[data_date] >= __LYTimeMin,
            'a02_e2e_boss_performance_summary_d'[data_date] <= __LYTimeMax
        )
    VAR __Return_Pct_Numerator_LY =
        CALCULATE(
            SUM('a02_e2e_boss_performance_summary_d'[o2o_return_amt]),
            'a02_e2e_boss_performance_summary_d'[calc_type] = __CalcType,
            'a02_e2e_boss_performance_summary_d'[store_name] IN  __StoreNames,
            'a02_e2e_boss_performance_summary_d'[data_date] >= __LYTimeMin,
            'a02_e2e_boss_performance_summary_d'[data_date] <= __LYTimeMax
        )
    VAR __Return_Pct_Denominator_LY =
        CALCULATE(
            SUM('a02_e2e_boss_performance_summary_d'[o2o_sales_amt]),
            'a02_e2e_boss_performance_summary_d'[calc_type] = __CalcType,
            'a02_e2e_boss_performance_summary_d'[store_name] IN  __StoreNames,
            'a02_e2e_boss_performance_summary_d'[data_date] >= __LYTimeMin,
            'a02_e2e_boss_performance_summary_d'[data_date] <= __LYTimeMax
        )
    VAR __Return_Pct_LY = DIVIDE(__Return_Pct_Numerator_LY, __Return_Pct_Denominator_LY)

    // ═══════════════════════════════════════
    // 基础聚合：calc_type = fulfillment（Fulfillment 分组，去年同期）
    // ═══════════════════════════════════════
    VAR __Fulfillment_Pct_Numerator_LY =
        CALCULATE(
            SUM('a02_e2e_boss_performance_summary_d'[o2o_fulfillment_shipped_order_cnt]),
            'a02_e2e_boss_performance_summary_d'[calc_type] = __CalcType,
            'a02_e2e_boss_performance_summary_d'[store_name] IN  __StoreNames,
            'a02_e2e_boss_performance_summary_d'[data_date] >= __LYTimeMin,
            'a02_e2e_boss_performance_summary_d'[data_date] <= __LYTimeMax
        )
    VAR __Fulfillment_Pct_Denominator_LY =
        CALCULATE(
            SUM('a02_e2e_boss_performance_summary_d'[o2o_fulfillment_request_order_cnt]),
            'a02_e2e_boss_performance_summary_d'[calc_type] = __CalcType,
            'a02_e2e_boss_performance_summary_d'[store_name] IN  __StoreNames,
            'a02_e2e_boss_performance_summary_d'[data_date] >= __LYTimeMin,
            'a02_e2e_boss_performance_summary_d'[data_date] <= __LYTimeMax
        )
    VAR __Fulfillment_Pct_LY = DIVIDE(__Fulfillment_Pct_Numerator_LY, __Fulfillment_Pct_Denominator_LY)
    VAR __Request_Order_Qty_LY =
        CALCULATE(
            SUM('a02_e2e_boss_performance_summary_d'[o2o_fulfillment_request_order_cnt]),
            'a02_e2e_boss_performance_summary_d'[calc_type] = __CalcType,
            'a02_e2e_boss_performance_summary_d'[store_name] IN  __StoreNames,
            'a02_e2e_boss_performance_summary_d'[data_date] >= __LYTimeMin,
            'a02_e2e_boss_performance_summary_d'[data_date] <= __LYTimeMax
        )
    VAR __Request_Units_LY =
        CALCULATE(
            SUM('a02_e2e_boss_performance_summary_d'[o2o_fulfillment_request_qty]),
            'a02_e2e_boss_performance_summary_d'[calc_type] = __CalcType,
            'a02_e2e_boss_performance_summary_d'[store_name] IN  __StoreNames,
            'a02_e2e_boss_performance_summary_d'[data_date] >= __LYTimeMin,
            'a02_e2e_boss_performance_summary_d'[data_date] <= __LYTimeMax
        )
    VAR __Request_Order_Amt_LY =
        CALCULATE(
            SUM('a02_e2e_boss_performance_summary_d'[o2o_fulfillment_request_sales_amt]),
            'a02_e2e_boss_performance_summary_d'[calc_type] = __CalcType,
            'a02_e2e_boss_performance_summary_d'[store_name] IN  __StoreNames,
            'a02_e2e_boss_performance_summary_d'[data_date] >= __LYTimeMin,
            'a02_e2e_boss_performance_summary_d'[data_date] <= __LYTimeMax
        )
    VAR __Shipped_Order_Qty_LY =
        CALCULATE(
            SUM('a02_e2e_boss_performance_summary_d'[o2o_fulfillment_shipped_order_cnt]),
            'a02_e2e_boss_performance_summary_d'[calc_type] = __CalcType,
            'a02_e2e_boss_performance_summary_d'[store_name] IN  __StoreNames,
            'a02_e2e_boss_performance_summary_d'[data_date] >= __LYTimeMin,
            'a02_e2e_boss_performance_summary_d'[data_date] <= __LYTimeMax
        )
    VAR __Shipped_Units_LY =
        CALCULATE(
            SUM('a02_e2e_boss_performance_summary_d'[o2o_fulfillment_shipped_qty]),
            'a02_e2e_boss_performance_summary_d'[calc_type] = __CalcType,
            'a02_e2e_boss_performance_summary_d'[store_name] IN  __StoreNames,
            'a02_e2e_boss_performance_summary_d'[data_date] >= __LYTimeMin,
            'a02_e2e_boss_performance_summary_d'[data_date] <= __LYTimeMax
        )
    VAR __Shipped_Order_Amt_LY =
        CALCULATE(
            SUM('a02_e2e_boss_performance_summary_d'[o2o_fulfillment_shipped_sales_amt]),
            'a02_e2e_boss_performance_summary_d'[calc_type] = __CalcType,
            'a02_e2e_boss_performance_summary_d'[store_name] IN  __StoreNames,
            'a02_e2e_boss_performance_summary_d'[data_date] >= __LYTimeMin,
            'a02_e2e_boss_performance_summary_d'[data_date] <= __LYTimeMax
        )

    // ═══════════════════════════════════════
    // 路由分发（按 RowKPI_ID）
    // 金额类指标 ÷ __FXRate（汇率换算）
    // ═══════════════════════════════════════
    RETURN
        SWITCH(
            __RowKPIID,
            // ─── Sales 分组（calc_type=payment）去年同期 ───
            10, IF(__IsCurrencyAmount, DIVIDE(__SLS_LY, __FXRate), __SLS_LY),                                // SLS O2O销售净额（去年同期）
            20, IF(__IsCurrencyAmount, DIVIDE(__DemandSLS_LY, __FXRate), __DemandSLS_LY),                    // Demand SLS O2O退前销售额（去年同期）
            30, __SLS_Penetration_LY,                                                                         // SLS Penetration O2O销售渗透率（去年同期）
            40, IF(__IsCurrencyAmount, DIVIDE(__Return_LY, __FXRate), __Return_LY),                          // Return O2O退货金额（去年同期）
            50, __Return_Pct_LY,                                                                              // Return% O2O退货率（金额）（去年同期）
            // ─── Fulfillment 分组（calc_type=fulfillment）去年同期 ───
            110, __Fulfillment_Pct_LY,                                                                        // Fulfillment% O2O订单履约率（去年同期）
            120, __Request_Order_Qty_LY,                                                                      // Request Order Qty O2O销售订单量（去年同期）
            130, __Request_Units_LY,                                                                          // Request Units O2O商品销售件数（去年同期）
            140, IF(__IsCurrencyAmount, DIVIDE(__Request_Order_Amt_LY, __FXRate), __Request_Order_Amt_LY),    // Request Order Amt O2O销售金额（去年同期）
            150, __Shipped_Order_Qty_LY,                                                                      // Shipped Order Qty O2O已配货订单量（去年同期）
            160, __Shipped_Units_LY,                                                                          // Shipped Units O2O已配货商品件数（去年同期）
            170, IF(__IsCurrencyAmount, DIVIDE(__Shipped_Order_Amt_LY, __FXRate), __Shipped_Order_Amt_LY),    // Shipped Order Amt O2O已配货销售金额（去年同期）
            BLANK()
        )
```

### 4.3 BOSS Core KPI vs LY Base Value（vs LY 派生值）

```dax
BOSS Core KPI vs LY Base Value = 
// ========================================
// 度量值: BOSS Core KPI vs LY Base Value
// Display Folder: Base Metrics
// 用途: 根据 RowKPI_ID 派生 vs LY（同比）值
// 依赖: [BOSS Core KPI Act Base Value], [BOSS Core KPI LY Base Value],
//       'Dim_RowKPIs_BossCoreKPI_Overview'[Metric_Format_VsLY]
// 口径来源: Overview.md 子模块一 BOSS Core KPI 的 vs LY 值
// 派生规则:
//   - 金额类/数量类（Metric_Format_VsLY = percent_1dp）：今年 / 去年 − 1（增长率）
//   - 比率类（Metric_Format_VsLY = delta_bp）：今年 − 去年（差值，展示时 ×10000 转 bp）
// 注: vs LY 同比值不受 Currency 切片器影响（同比为比率/差值，无金额单位）
//     因此 Act / LY 中已应用的汇率换算在相除/相减时自动抵消
// ========================================
    VAR __RowKPIID = SELECTEDVALUE('Dim_RowKPIs_BossCoreKPI_Overview'[RowKPI_ID])
    VAR __FormatVsLY = SELECTEDVALUE('Dim_RowKPIs_BossCoreKPI_Overview'[Metric_Format_VsLY])

    // ── 取本期值与去年同期值（已含汇率换算，但同比计算会自动抵消）──
    VAR __ActValue = [BOSS Core KPI Act Base Value]
    VAR __LYValue = [BOSS Core KPI LY Base Value]

    // ── vs LY 派生计算 ──
    // percent_1dp（金额类/数量类）：今年 / 去年 − 1
    // delta_bp（比率类）：今年 − 去年（差值，展示时 ×10000 转 bp 在 Cell Display 中实现）
    VAR __VSLYGrowth =
        IF(
            ISBLANK(__LYValue) || __LYValue = 0,
            BLANK(),
            DIVIDE(__ActValue - __LYValue, __LYValue)
        )
    VAR __VSLYDiff = __ActValue - __LYValue

    RETURN
        SWITCH(
            __FormatVsLY,
            "percent_1dp", __VSLYGrowth,    // 金额类/数量类 vs LY（今年/去年−1）
            "delta_bp",    __VSLYDiff,      // 比率类 vs LY（今年−去年，差值）
            BLANK()
        )
```

### 4.4 BOSS Core KPI Cell Value（对外值，按 ColType 路由）

```dax
BOSS Core KPI Cell Value = 
// ========================================
// 度量值: BOSS Core KPI Cell Value
// Display Folder: Cell Values
// 用途: 按 ColType（Act / LY / vs LY）路由到对应基础值
// 依赖: 'Dim_ColKPIs_BossCoreKPI_Overview'[ColType],
//       [BOSS Core KPI Act Base Value], [BOSS Core KPI LY Base Value], [BOSS Core KPI vs LY Base Value]
// ========================================
    VAR __ColType = SELECTEDVALUE('Dim_ColKPIs_BossCoreKPI_Overview'[ColType])
    RETURN
        SWITCH(
            __ColType,
            "Act",   [BOSS Core KPI Act Base Value],     // 当期实际值
            "LY",    [BOSS Core KPI LY Base Value],      // 去年同期值
            "vs LY", [BOSS Core KPI vs LY Base Value],   // 与去年同期对比
            BLANK()
        )
```

### 4.5 BOSS Core KPI Cell Display（格式化显示）

```dax
BOSS Core KPI Cell Display = 
// ========================================
// 度量值: BOSS Core KPI Cell Display
// Display Folder: Formatting
// 用途: 按 ColType 选择对应行格式（Metric_Format_Act / Metric_Format_LY / Metric_Format_VsLY）格式化显示
// 依赖: [BOSS Core KPI Cell Value],
//       'Dim_ColKPIs_BossCoreKPI_Overview'[ColType],
//       'Dim_RowKPIs_BossCoreKPI_Overview'[Metric_Format_Act / Metric_Format_LY / Metric_Format_VsLY]
// 格式类型（严格遵循口径文档 Overview.md 子模块一数据类型定义）:
//   currency       → 货币符号 + 千分位整数：¥1,000        格式串: #,##0
//   integer        → 整数千分位：1,000                      格式串: #,##0
//   percent_1dp    → 百分比一位小数，不含正号：14.5%         格式串: #,##0.0%
//   delta_bp       → 增减基点整数，含正负号：+120bp         格式串: +#,##0bp;-#,##0bp;0bp
//                    （一个百分点是100bp，值×10000 转 bp 的操作在此处实现）
// ========================================
    VAR __Value = [BOSS Core KPI Cell Value]
    VAR __ColType = SELECTEDVALUE('Dim_ColKPIs_BossCoreKPI_Overview'[ColType])
    // ── 按 ColType 选择对应行格式 ──
    VAR __Format =
        SWITCH(
            __ColType,
            "Act",   SELECTEDVALUE('Dim_RowKPIs_BossCoreKPI_Overview'[Metric_Format_Act]),
            "LY",    SELECTEDVALUE('Dim_RowKPIs_BossCoreKPI_Overview'[Metric_Format_LY]),
            "vs LY", SELECTEDVALUE('Dim_RowKPIs_BossCoreKPI_Overview'[Metric_Format_VsLY]),
            BLANK()
        )
    VAR __CurrencySymbol = SELECTEDVALUE(Slicer_Currency_Selection[Currency_Symbol], "¥")
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            SWITCH(
                __Format,
                // ─── 货币（符号由币种切片器决定）─────────────
                "currency",
                    __CurrencySymbol & FORMAT(__Value, "#,##0"),                                              // ¥1,000
                // ─── 整数 ─────────────────────────────────
                "integer",
                    FORMAT(__Value, "#,##0"),                                                                 // 1,000
                // ─── 百分比（不含正号）──────────────────────
                "percent_1dp",
                    FORMAT(__Value, "#,##0.0%"),                                                // 14.5%
                // ─── 增减基点（含正负号，值×10000 转 bp）─────__Value 是小数格式，需要乘以 10000 转换为基点 (如 0.012 -> 120bp)
                "delta_bp",
                    IF(ROUND(__Value * 10000, 0) > 0, "+", "") & FORMAT(__Value * 10000, "#,##0bp;-#,##0bp;0bp"), // +120bp
                // ─── 默认 ─────────────────────────────────
                FORMAT(__Value, "#,##0.00")
            )
        )
```

### 4.6 BOSS Core KPI Cell Font Color（字体颜色）

```dax
BOSS Core KPI Cell Font Color = 
// ========================================
// 度量值: BOSS Core KPI Cell Font Color
// Display Folder: Formatting
// 用途: 区分 KPIGroup 行（总计行）与 KPI 行（其他行），并对 vs LY 列启用正/负/零三色
// 依赖: [BOSS Core KPI Cell Value],
//       'Dim_ColKPIs_BossCoreKPI_Overview'[ColType, Metric_ColorPositive/Negative/Zero/Default],
//       'Dim_RowKPIs_BossCoreKPI_Overview'[KPIName]
// 层级判断:
//   ISINSCOPE('Dim_RowKPIs_BossCoreKPI_Overview'[KPIName]) = TRUE  → KPI 行（其他行）
//   ISINSCOPE('Dim_RowKPIs_BossCoreKPI_Overview'[KPIName]) = FALSE → KPIGroup 行（总计行）
// 颜色规则:
//   ┌─────────────┬───────────────────┬──────────────────────────────────────┐
//   │             │  vs LY 列         │  其他列（Act / LY）                  │
//   ├─────────────┼───────────────────┼──────────────────────────────────────┤
//   │  KPI 行     │  正#1A9018/负#D64550/零#E1C233/默认#5F6165  │  #5F6165（深灰）│
//   │  KPIGroup 行│  #252423（黑色）  │  #252423（黑色）                     │
//   └─────────────┴───────────────────┴──────────────────────────────────────┘
// 颜色字段来源: Dim_ColKPIs_BossCoreKPI_Overview 中的
//              Metric_ColorPositive / Metric_ColorNegative / Metric_ColorZero / Metric_ColorDefault
// ========================================
    VAR __Value = [BOSS Core KPI Cell Value]
    VAR __ColType = SELECTEDVALUE('Dim_ColKPIs_BossCoreKPI_Overview'[ColType])
    VAR __IsKPIRow = ISINSCOPE('Dim_RowKPIs_BossCoreKPI_Overview'[KPIName])  // TRUE=KPI行, FALSE=KPIGroup行
    // ── 颜色取值（来自列维度表）──
    VAR __ColorPositive = SELECTEDVALUE('Dim_ColKPIs_BossCoreKPI_Overview'[Metric_ColorPositive], "#1A9018")
    VAR __ColorNegative = SELECTEDVALUE('Dim_ColKPIs_BossCoreKPI_Overview'[Metric_ColorNegative], "#D64550")
    VAR __ColorZero = SELECTEDVALUE('Dim_ColKPIs_BossCoreKPI_Overview'[Metric_ColorZero], "#E1C233")
    VAR __ColorDefault = SELECTEDVALUE('Dim_ColKPIs_BossCoreKPI_Overview'[Metric_ColorDefault], "#5F6165")

    RETURN 
        SWITCH(
            TRUE(),
            // ─── KPIGroup 行（总计行）：统一黑色 #252423 ───
            NOT __IsKPIRow && __ColType <> "vs LY",          "#252423",
            // ─── 卡片图：启用正/负/零三色 ───
            NOT __IsKPIRow && __ColType = "vs LY" && ISBLANK(__Value),   __ColorDefault,
            NOT __IsKPIRow && __ColType = "vs LY" && __Value > 0,        __ColorPositive,   // 正值：绿
            NOT __IsKPIRow && __ColType = "vs LY" && __Value < 0,        __ColorNegative,   // 负值：红
            NOT __IsKPIRow && __ColType = "vs LY" && __Value = 0,        __ColorZero,       // 零值：黄
            // ─── KPI 行 + 非 vs LY 列：深灰 #5F6165 ───
            __IsKPIRow && __ColType <> "vs LY",          "#5F6165",
            // ─── KPI 行 + vs LY 列：启用正/负/零三色 ───
            __IsKPIRow && __ColType = "vs LY" && ISBLANK(__Value),   __ColorDefault,
            __IsKPIRow && __ColType = "vs LY" && __Value > 0,        __ColorPositive,   // 正值：绿
            __IsKPIRow && __ColType = "vs LY" && __Value < 0,        __ColorNegative,   // 负值：红
            __IsKPIRow && __ColType = "vs LY" && __Value = 0,        __ColorZero,       // 零值：黄
            // ─── 兜底 ───
            "#252423"
        )
```

### 4.7 BOSS Core KPI Cell Background Color（背景色）

```dax
BOSS Core KPI Cell Background Color = 
// ========================================
// 度量值: BOSS Core KPI Cell Background Color
// Display Folder: Formatting
// 用途: 区分 KPIGroup 行（总计行）与 KPI 行（其他行）的背景色
// 依赖: 'Dim_RowKPIs_BossCoreKPI_Overview'[KPIName]
// 层级判断:
//   ISINSCOPE('Dim_RowKPIs_BossCoreKPI_Overview'[KPIName]) = TRUE  → KPI 行（其他行）
//   ISINSCOPE('Dim_RowKPIs_BossCoreKPI_Overview'[KPIName]) = FALSE → KPIGroup 行（总计行）
// 颜色规则:
//   KPIGroup 行（总计行）: #E6D9C7（中米色）
//   KPI 行（其他行）     : #FFFFFF（白色）
// ========================================
    VAR __IsKPIRow = ISINSCOPE('Dim_RowKPIs_BossCoreKPI_Overview'[KPIName])  // TRUE=KPI行, FALSE=KPIGroup行
    RETURN
        IF(
            __IsKPIRow,
            "#FFFFFF",   // KPI 行（其他行）：白色
            "#E6D9C7"    // KPIGroup 行（总计行）：中米色
        )
```

### 4.8 BOSS Core KPI Cell SVG Icon（SVG 图标）

```dax
BOSS Core KPI Cell SVG Icon = 
// ========================================
// 度量值: BOSS Core KPI Cell SVG Icon
// Display Folder: Formatting
// 用途: 仅 vs LY 列 + KPI 行返回 SVG 圆形图标（参考 KPI Breakdown Cell SVG Icon）
// 依赖: [BOSS Core KPI Cell Value],
//       'Dim_ColKPIs_BossCoreKPI_Overview'[ColType, Metric_ColorPositive/Negative/Zero],
//       'Dim_RowKPIs_BossCoreKPI_Overview'[KPIName]
// 配置: 需将此度量值的数据类别设为"图像 URL"
// 图标规则:
//   ┌─────────────┬──────────────────────────────────────┐
//   │             │  vs LY 列                            │
//   ├─────────────┼──────────────────────────────────────┤
//   │  KPI 行     │  正→绿圆 / 负→红圆 / 零→黄圆         │
//   │  KPIGroup 行│  不显示（BLANK）                     │
//   └─────────────┴──────────────────────────────────────┘
//   其他列（Act / LY）：不显示（BLANK）
// 颜色与 Font Color 保持一致（取自 Dim_ColKPIs_BossCoreKPI_Overview 的颜色字段）
// ========================================
    VAR __Value = [BOSS Core KPI Cell Value]
    VAR __ColType = SELECTEDVALUE('Dim_ColKPIs_BossCoreKPI_Overview'[ColType])
    VAR __IsKPIRow = ISINSCOPE('Dim_RowKPIs_BossCoreKPI_Overview'[KPIName])
    // ── 启用图标条件：vs LY 列 + KPI 行 ──
    VAR __NeedsIcon = __ColType = "vs LY" && __IsKPIRow
    // ── 颜色取值（来自列维度表）──
    VAR __ColorPositive = SELECTEDVALUE('Dim_ColKPIs_BossCoreKPI_Overview'[Metric_ColorPositive], "#1A9018")
    VAR __ColorNegative = SELECTEDVALUE('Dim_ColKPIs_BossCoreKPI_Overview'[Metric_ColorNegative], "#D64550")
    VAR __ColorZero = SELECTEDVALUE('Dim_ColKPIs_BossCoreKPI_Overview'[Metric_ColorZero], "#E1C233")
    // ── SVG 圆形图标（颜色动态拼接，# 需 URL 编码为 %23）──
    VAR __GreenSVG =
        "data:image/svg+xml;utf8," &
        "<svg xmlns='http://www.w3.org/2000/svg' width='16' height='16'>" &
        "<circle cx='8' cy='8' r='7' fill='" & __ColorPositive & "'/></svg>"
    VAR __RedSVG =
        "data:image/svg+xml;utf8," &
        "<svg xmlns='http://www.w3.org/2000/svg' width='16' height='16'>" &
        "<circle cx='8' cy='8' r='7' fill='" & __ColorNegative & "'/></svg>"
    VAR __YellowSVG =
        "data:image/svg+xml;utf8," &
        "<svg xmlns='http://www.w3.org/2000/svg' width='16' height='16'>" &
        "<circle cx='8' cy='8' r='7' fill='" & __ColorZero & "'/></svg>"
    RETURN
        SWITCH(
            TRUE(),
            NOT __NeedsIcon,                 BLANK(),
            ISBLANK(__Value),                BLANK(),
            __Value > 0,                     __GreenSVG,    // 正值 → 绿
            __Value < 0,                     __RedSVG,      // 负值 → 红
            __Value = 0,                     __YellowSVG,   // 零值 → 黄
            BLANK()
        )
```

---

## 5. 度量值清单与 Display Folder

| 序号 | 度量值名称                          | Display Folder | 用途                                                    |
| ---- | ----------------------------------- | -------------- | ------------------------------------------------------- |
| 1    | BOSS Core KPI Act Base Value        | Base Metrics   | 本期基础值（12 个 KPI，按 RowKPI_ID 路由）              |
| 2    | BOSS Core KPI LY Base Value         | Base Metrics   | 去年同期基础值（财历映射：Day EDATE-12 / 其他 Key 偏移）|
| 3    | BOSS Core KPI vs LY Base Value      | Base Metrics   | vs LY 派生（金额/数量类=今年/去年-1，比率类=今年-去年） |
| 4    | BOSS Core KPI Cell Value            | Cell Values    | 对外值 = 按 ColType 选择 Act / LY / vs LY               |
| 5    | BOSS Core KPI Cell Display          | Formatting     | 格式化显示文本（按 ColType 选对应行格式）               |
| 6    | BOSS Core KPI Cell Font Color       | Formatting     | 字体颜色（区分 KPIGroup/KPI 行 × vs LY/其他列）        |
| 7    | BOSS Core KPI Cell Background Color | Formatting     | 背景色（KPIGroup 行#E6D9C7 / KPI 行 #FFFFFF）           |
| 8    | BOSS Core KPI Cell SVG Icon         | Formatting     | SVG 图标（仅 vs LY 列 + KPI 行）                        |

---

## 6. 血缘关系图（Lineage Diagram）

```
┌─────────────────────────────────────────────────────────────────────┐
│                        数据源层                                      │
│  a02_e2e_boss_performance_summary_d（事实表）                        │
│  字段: data_date, store_name, calc_type, fulfillment_calc_type,      │
│        o2o_net_sales_amt, o2o_sales_amt, sales_amt, o2o_return_amt,  │
│        o2o_fulfillment_shipped_order_cnt, o2o_fulfillment_request_order_cnt,│
│        o2o_fulfillment_request_qty, o2o_fulfillment_request_sales_amt,│
│        o2o_fulfillment_shipped_qty, o2o_fulfillment_shipped_sales_amt│
└──────────────────────────────┬──────────────────────────────────────┘
                               │
                               │ 1:N 关系（模型自动筛选）
                               │
                               ▼
                   ┌────────────────────────┐
                   │ Slicer_Fulfillment_    │
                   │ Calc_Type              │
                   │ (Calc_Type_ID →        │
                   │  fulfillment_calc_type)│
                   └────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│                        度量值层                                      │
│                                                                     │
│  ┌───────────────────────────────┐   ┌───────────────────────────────┐
│  │ BOSS Core KPI Act Base Value  │   │ BOSS Core KPI LY Base Value   │
│  │ (本期 12 个 RowKPI_ID)         │   │ (同期 12 个 RowKPI_ID, 财历映射)│
│  └───────────┬───────────────────┘   └───────────┬───────────────────┘
│              │                                   │
│              │     ┌─────────────────────────────┘
│              │     │
│              ▼     ▼
│  ┌───────────────────────────────┐
│  │ BOSS Core KPI vs LY Base Value│
│  │ (按 Format_VsLY 分支：         │
│  │  percent_1dp → 今年/去年−1    │
│  │  delta_bp    → 今年−去年)     │
│  └───────────┬───────────────────┘
│              │
│              ▼
│  ┌───────────────────────────────┐   ┌─────────────────────────────┐
│  │ BOSS Core KPI Cell Value      │◄──│ 'Dim_ColKPIs_BossCoreKPI_   │
│  │ (按 ColType 路由 Act/LY/vsLY) │   │  Overview'[ColType]         │
│  └───────────┬───────────────────┘   └─────────────────────────────┘
│              │
│              ▼
│  ┌───────────────────────────────┐   ┌─────────────────────────────┐
│  │ BOSS Core KPI Cell Display    │◄──│ 'Dim_ColKPIs_BossCoreKPI_   │
│  │ (按 ColType 选行格式格式化)    │   │  Overview'[ColType]         │
│  └───────────┬───────────────────┘   │ 'Dim_RowKPIs_BossCoreKPI_   │
│              │                        │  Overview'[Metric_Format_*] │
│              ▼                        └─────────────────────────────┘
│  ┌─────────────────────────────────────────────────┐
│  │  BOSS Core KPI Cell Font Color                   │
│  │  BOSS Core KPI Cell Background Color             │
│  │  BOSS Core KPI Cell SVG Icon                     │
│  │  (条件格式度量值，ISINSCOPE 判断 KPIGroup/KPI 行) │
│  └─────────────────────────────────────────────────┘
└─────────────────────────────────────────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────────┐
│                        可视化层                                      │
│  Matrix 视觉对象                                                     │
│  行: 'Dim_RowKPIs_BossCoreKPI_Overview'[KPIGroup]                    │
│      > 'Dim_RowKPIs_BossCoreKPI_Overview'[KPIName]                   │
│  列: 'Dim_ColKPIs_BossCoreKPI_Overview'[StoreGroup]                  │
│      > 'Dim_ColKPIs_BossCoreKPI_Overview'[ColName]                   │
│  值: [BOSS Core KPI Cell Display]                                    │
│  条件格式:                                                           │
│    字体颜色 → [BOSS Core KPI Cell Font Color]                       │
│    背景色   → [BOSS Core KPI Cell Background Color]                 │
│    SVG 图标 → [BOSS Core KPI Cell SVG Icon]（数据类别=图像 URL）     │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 7. 关键设计说明

### 7.1 筛选器公用说明

- **Slicer_Time_Frame_Min/Max**：断开维度，SELECTEDVALUE 读取时间范围，用于 `data_date` 筛选
- **Slicer_Currency_Selection**：断开维度，仅金额类指标（`Metric_IsCurrencyAmount=TRUE`）÷ `Currency_ExchangeRate`，非金额类指标不受汇率影响
- **Slicer_Fulfillment_Calc_Type**：1:N 关系，模型自动筛选 `fulfillment_calc_type`
- **无 Slicer_Store_Name 筛选器**：store_name 筛选通过列维度 `Dim_ColKPIs_BossCoreKPI_Overview[StoreGroup_ID]` 实现，采用 `__StoreFilterTable` 自适应机制（见 8.6）

---

## 8. 验证方法

### 8.1 矩阵结构验证

| 验证项 | 方法                                                                        |
| ------ | --------------------------------------------------------------------------- |
| 行数   | 确认 12 个 KPI 行 + 2 个 KPIGroup 分组标题行 = 14 行                        |
| 列数   | 确认 18 列（6 店铺 × 3 列）                                                |
| 行排序 | KPIGroup 按 KPIGroup_Sort（Sales=10, Fulfillment=20），KPI 按 KPIName_Sort  |
| 列排序 | StoreGroup 按 StoreGroup_Sort（10/20/30/40/50/60），ColName 按 ColName_Sort |

### 8.2 数据验证 SQL

**LY 财历映射验证步骤**（以 Week 粒度为例）：

```sql
-- 步骤1: 查 Slicer_Time_Frame_Min/Max 当前选择（假设 Min=2026 Week14, Max=2026 Week19）
-- 步骤2: 计算 LY Key: Min LY Key = 202614 - 100 = 202514, Max LY Key = 202619 - 100 = 202519
-- 步骤3: 查 LY 时间范围
--   SELECT TimeFrame_Min FROM slicer_time_frame WHERE TimeFrame_ID='Week' AND TimeFrame_Key=202514
--   SELECT TimeFrame_Max FROM slicer_time_frame WHERE TimeFrame_ID='Week' AND TimeFrame_Key=202519
--   假设结果: LY Min = '2024-06-30', LY Max = '2024-08-04'

-- SLS O2O销售净额（TM 店铺，本期）
SELECT SUM(o2o_net_sales_amt) AS SLS_Act
FROM a02_e2e_boss_performance_summary_d
WHERE calc_type = 'payment'
  AND store_name = 'TM'
  AND data_date BETWEEN '__TimeMin' AND '__TimeMax';
  -- 例如 __TimeMin='2025-06-29', __TimeMax='2025-08-09'

-- SLS O2O销售净额（TM 店铺，去年同编号财周）
SELECT SUM(o2o_net_sales_amt) AS SLS_LY
FROM a02_e2e_boss_performance_summary_d
WHERE calc_type = 'payment'
  AND store_name = 'TM'
  AND data_date BETWEEN '2024-06-30' AND '2024-08-04';
  -- 注意: 不是 DATE_SUB('__TimeMin', INTERVAL 12 MONTH) = '2024-06-29'
  -- 财历映射取去年同编号财周的完整定义范围，可能与 EDATE -12 差1天

-- SLS vs LY = SLS_Act / SLS_LY - 1（percent_1dp）

-- SLS Penetration O2O销售渗透率（TM 店铺，本期）
SELECT
  SUM(o2o_sales_amt) / SUM(sales_amt) AS SLS_Penetration_Act
FROM a02_e2e_boss_performance_summary_d
WHERE calc_type = 'payment'
  AND store_name = 'TM'
  AND data_date BETWEEN '__TimeMin' AND '__TimeMax';

-- SLS Penetration vs LY = SLS_Penetration_Act - SLS_Penetration_LY（delta_bp，×10000 转 bp）

-- Fulfillment% O2O订单履约率（TM 店铺，本期）
SELECT
  SUM(o2o_fulfillment_shipped_order_cnt) / SUM(o2o_fulfillment_request_order_cnt) AS Fulfillment_Pct_Act
FROM a02_e2e_boss_performance_summary_d
WHERE calc_type = 'fulfillment'
  AND store_name = 'TM'
  AND data_date BETWEEN '__TimeMin' AND '__TimeMax';
```

**LY Key 偏移规则速查**：

| TimeFrame_ID | LY Key 计算 | 示例 |
|--------------|-------------|------|
| Day | EDATE -12（不走 Key 偏移） | 2025-06-29 → 2024-06-29 |
| Week | Key - 100 | 202614 → 202514 |
| Month | Key - 100 | 202610 → 202510 |
| Quarter | Key - 100 | 202603 → 202503 |
| Year | Key - 1 | 2026 → 2025 |
---