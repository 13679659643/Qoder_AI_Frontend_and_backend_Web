# Power BI 解决方案 — PB Merchandise：Fulfillment 指标矩阵（SWITCH 路由）

> status: ready
> created: 2026-08-08
> type: 度量值开发 + 可视化构建
> 口径来源: 口径文档/PB Merchandise.md 子模块三 BOSS Performance Details 从 4. Avg. No. of Store Passed Before Order Got Accepted 起的剩余指标
> 参考实现: PB_Location_Fulfillment_detail_ms.md（总路由 REMOVEFILTERS 范式）
> 列指标维度表: Dim_ColMetric_Fulfillment_PB_Merchandise（36 行，覆盖 7 个 KPI 分组）

---

## 1. 需求理解

为 Performance By Merchandise 页面实现 Fulfillment 分组（子模块三从 4. Avg. No. of Store Passed Before Order Got Accepted 开始的剩余指标）的中国式矩阵效果：

- **行**：无行维度表，直接拉取事实表字段（brand / product_type / category_summary / category），天然实现行维度分组和筛选，DAX 无需显式处理
- **列**：`Dim_ColMetric_Fulfillment_PB_Merchandise` 的两级层级 `KPIGroup`（父）> `ColName`（子）
  - 7 个 KPI 分组：Order Processing Efficiency / Fulfillment% / Request Order / Shipped Order / Unfulfillment% / Unfulfilled Order / Product Volume
  - 共 36 列指标
- **值**：SWITCH 动态路由，按 `Metric_ID` × `ColType` 分发到 Act / LY / vs LY（或 Orders / Units / Amt 等组内列类型）
- **口径**：一切以口径文档 PB Merchandise.md 子模块三从 4. 起的口径为准
- **筛选器**：
  - Slicer_Time_Frame_Min/Max（断开维度，筛选 data_date）
  - Slicer_Currency_Selection（断开维度，仅金额类指标 ÷ 汇率）

### 1.1 关键特殊逻辑一：双数据底表

口径文档明确要求（指标 4、5）：
> 数据底表为 `a02_e2e_boss_fulfillment_request_data_d`

其余指标（6-17）数据底表为 `a02_e2e_boss_performance_summary_d`。因此 Act Base Value 需要同时聚合两张事实表：
- Metric_ID 1, 2（Order Processing Efficiency 分组）→ `a02_e2e_boss_fulfillment_request_data_d`
- Metric_ID 3-36（其余分组）→ `a02_e2e_boss_performance_summary_d`

### 1.2 关键特殊逻辑二：Product Volume 库存期末取末日 + 销量区间聚合

口径文档明确要求（指标 17 Product Volume）：
> 库存：sum(stock_qty)【看所选时间范围的期末库存】，库存需要根据筛选日期，只要最后一天的数据。
> 销量：sum(o2o_fulfillment_shipped_qty)【看所有时间范围的销量总和】，销量整个筛选周期的数据聚合。

因此 Product Volume（Metric_ID 36）的聚合为：
- 库存部分：取 `__TimeMax`（本期末日）当天的 `SUM(stock_qty)`
- 销量部分：取 `[__TimeMin, __TimeMax]` 区间的 `SUM(o2o_fulfillment_shipped_qty)`
- 最终值 = 末日库存 + 区间销量

---

## 2. 现状分析

### 2.1 数据底表

| 对象 | 名称 | 出处 |
|------|------|------|
| 事实表 1 | a02_e2e_boss_performance_summary_d | PB Merchandise.md 全局逻辑 |
| 事实表 2 | a02_e2e_boss_fulfillment_request_data_d | PB Merchandise.md 指标 4、5 |
| 关键字段（summary 表） | data_date, brand, product_type, category_summary, category, calc_type, o2o_fulfillment_shipped_order_cnt, o2o_fulfillment_request_order_cnt, o2o_fulfillment_request_qty, o2o_fulfillment_request_sales_amt, o2o_fulfillment_shipped_qty, o2o_fulfillment_shipped_sales_amt, o2o_fulfillment_unshipped_order_cnt, o2o_fulfillment_unshipped_qty, o2o_fulfillment_unshipped_sales_amt, stock_qty | PB Merchandise.md 子模块三 6-17 |
| 关键字段（request_data 表） | data_date, brand, product_type, category_summary, category, calc_type, o2o_fulfillment_request_times, o2o_fulfillment_request_duration, o2o_fulfillment_request_sku_qty | PB Merchandise.md 子模块三 4、5 |

### 2.2 维度表清单

| 维度表 | 类型 | 连接方式 |
|--------|------|---------|
| Slicer_Time_Frame_Min | 断开维度 | SELECTEDVALUE 读取 TimeFrame_Min / TimeFrame_Min_LY |
| Slicer_Time_Frame_Max | 断开维度 | SELECTEDVALUE 读取 TimeFrame_Max / TimeFrame_Max_LY |
| Slicer_Currency_Selection | 断开维度 | SELECTEDVALUE 读取 Currency_ExchangeRate / Currency_Symbol |
| Dim_ColMetric_Fulfillment_PB_Merchandise | 断开维度 | SELECTEDVALUE 读取 Metric_ID / ColType / Metric_Format_* |

> 不使用行维度表，行字段直接拉取事实表字段。calc_type 在本方案所有指标下固定为 "fulfillment"，直接硬编码。

---

## 3. 方案设计

### 3.1 整体架构

```
核心思路：断开列维度 + SWITCH 动态路由（Disconnected Dimension + Dispatch Pattern）

Dim_ColMetric_Fulfillment_PB_Merchandise（断开维度，列头）
    │
    │  无关系连接，仅通过 SELECTEDVALUE 读取：
    │  - Metric_ID, ColType, KPIGroup, ColName
    │  - Metric_Format_Act/LY/VsLY, Metric_IsCurrencyAmount
    │
    ▼
    ┌─────────────────────────── Matrix 视觉对象 ──────────────────────────┐
    │  行 = 事实表字段（brand / product_type / category_summary / category）│
    │  列 = 'Dim_ColMetric_Fulfillment_PB_Merchandise'[KPIGroup]           │
    │        > 'Dim_ColMetric_Fulfillment_PB_Merchandise'[ColName]         │
    │  值 = [Fulfillment PB Merchandise Cell Display]                     │
    └────────────────────────────────────────────────────────────────────────┘
                                   ▲
                                   │
              SWITCH 动态路由度量值链（按 Metric_ID 分发）
              ┌────────────────────────────────────────────────────┐
              │  [Fulfillment PB Merchandise Cell Value]            │
              │    └→ [Fulfillment PB Merchandise Base Value]（总路由）│
              │         ├→ [Fulfillment PB Merchandise Act Base Value]│
              │         ├→ [Fulfillment PB Merchandise LY Base Value] │
              │         └→ vs LY 派生（金额/数量类：今年/去年-1，   │
              │            比率类：今年-去年）                       │
              │         注：Order Processing Efficiency（1/2）和     │
              │            Product Volume（36）无 LY/vs LY，直接返回 │
              │            Act 值                                   │
              └────────────────────────────────────────────────────┘
```

### 3.2 度量值模型设计

```
[Fulfillment PB Merchandise Act Base Value]  ← 本期基础值
                                            ← Metric_ID 1,2：a02_e2e_boss_fulfillment_request_data_d 区间 SUM
                                            ← Metric_ID 3-35：a02_e2e_boss_performance_summary_d 区间 SUM
                                            ← Metric_ID 36：末日库存 + 区间销量
[Fulfillment PB Merchandise LY Base Value]   ← 去年同期基础值（财历映射，区间 SUM）
                                            ← 仅 5 个有 LY 列的分组（11 个 LY Metric_ID）
                                            ← Order Processing Efficiency 和 Product Volume 无 LY
[Fulfillment PB Merchandise Base Value]      ← 总路由（含 vs LY 派生）
                                            ← 总路由使用 REMOVEFILTERS 清除断开维度筛选，再应用目标 Metric_ID
                                            ← Order Processing Efficiency 和 Product Volume 无 vs LY，直接返回 Act
[Fulfillment PB Merchandise Cell Value]      ← 对外值 = Base Value
[Fulfillment PB Merchandise Cell Display]    ← 格式化显示文本
[Fulfillment PB Merchandise Cell Font Color] ← 字体颜色（KPIGroup 行 vs KPI 行 × vs LY 列 vs 其他列）
[Fulfillment PB Merchandise Cell Background Color] ← 背景色
[Fulfillment PB Merchandise Cell SVG Icon]   ← SVG 图标（仅 vs LY 列 + KPI 行）
```

### 3.3 筛选器上下文

| 筛选器 | 作用方式 | DAX 处理 |
|--------|---------|---------|
| Slicer_Time_Frame_Min | 断开维度，SELECTEDVALUE 读取 TimeFrame_Min | `data_date >= __TimeMin`（区间指标） |
| Slicer_Time_Frame_Max | 断开维度，SELECTEDVALUE 读取 TimeFrame_Max | `data_date <= __TimeMax`（区间指标）；`data_date = __TimeMax`（Product Volume 库存部分末日） |
| Slicer_Currency_Selection | 断开维度，SELECTEDVALUE 读取 Currency_ExchangeRate, Currency_Symbol | 金额类指标 ÷ Currency_ExchangeRate |
| 事实表分组字段 | 表格行/列直接拉取，模型自动传递筛选 | DAX 无需显式处理 |

> calc_type 在本方案所有指标下固定为 "fulfillment"，直接硬编码。

### 3.4 vs LY 时间偏移规则（财历映射）

直接读取日期表内置 LY 字段：
- 全局 LY 起始日：`Slicer_Time_Frame_Min[TimeFrame_Min_LY]`
- 全局 LY 结束日：`Slicer_Time_Frame_Max[TimeFrame_Max_LY]`
- 无需 EDATE -12 或 Key 偏移计算

### 3.5 vs LY 派生计算分类

| KPI 分类 | vs LY 计算方式 | Metric_Format_VsLY | 展示示例 |
|---------|---------------|-------------------|---------|
| 数量类（Request Order Qty/Units、Shipped Order Qty/Units、Unfulfilled Order Qty/Units） | 今年 / 去年 − 1 | percent_1dp | 14.5% |
| 金额类（Request Order Amt、Shipped Order Amt、Unfulfilled Amt） | 今年 / 去年 − 1 | percent_1dp | 14.5% |
| 比率类（Fulfillment%、Unfulfillment%） | 今年 − 去年（差值，×10000 转 bp） | delta_bp | +120bp |

> Order Processing Efficiency 分组（Metric_ID 1, 2）和 Product Volume 分组（Metric_ID 36）只含单列，无 LY 与 vs LY 列，不需要派生计算。

### 3.6 格式规范

| 格式类型 | 格式串 | 示例 | 适用度量 |
|---------|--------|------|---------|
| integer | `#,##0` | 1,234 | 所有数量类 Act、LY；Product Volume |
| currency | `__CurrencySymbol & FORMAT(__Value, "#,##0")` | ¥1,234 | Request Order Amt / Shipped Order Amt / Unfulfilled Amt 的 Act、LY |
| percent_1dp | `#,##0.0%` | 14.5% | 比率类 Act、LY；数量/金额类 vs LY |
| delta_bp | `IF(ROUND(__Value*10000,0)>0,"+","") & FORMAT(__Value*10000, "#,##0bp;-#,##0bp;0bp")` | +120bp | 比率类 vs LY |
| decimal_1dp | `#,##0.0` | 1,234.5 | Order Processing Efficiency 分组（Avg. No. of Store Passed / Avg. Processing Time） |

---

## 4. 度量值实现

### 4.1 Dim_ColMetric_Fulfillment_PB_Merchandise（列指标维度表）

> 维度表已存在于 `Dim_ColMetric_Fulfillment_PB_Merchandise.md`，此处不再重复定义，直接引用。下文明晰映射关系：

| Metric_ID | KPIGroup | ColName | ColType | 口径文档对应指标 | Act 字段 | LY 字段 | 数据底表 |
|-----------|----------|---------|---------|-----------------|---------|---------|---------|
| 1 | Order Processing Efficiency | 1-Avg. No. of Store Passed Before Order Got Accepted | Avg. No. of Store Passed Before Order Got Accepted | 4. Avg. No. of Store Passed | o2o_fulfillment_request_times / o2o_fulfillment_request_sku_qty | — | request_data 表 |
| 2 | Order Processing Efficiency | 2-Avg. Processing Time(Hour) | Avg. Processing Time(Hour) | 5. Avg. Processing Time(Hour) | o2o_fulfillment_request_duration / o2o_fulfillment_request_sku_qty | — | request_data 表 |
| 3 | Fulfillment% | 3-Act | Act | 6. Fulfillment%（本期） | o2o_fulfillment_shipped_order_cnt / o2o_fulfillment_request_order_cnt | — | summary 表 |
| 4 | Fulfillment% | 4-LY | LY | 6.1 Fulfillment% LY | — | 同上（LY 区间） | summary 表 |
| 5 | Fulfillment% | 5-vs LY | vs LY | 6.2 Fulfillment% vs LY | — | — | summary 表 |
| 6 | Request Order | 6-Orders | Orders | 7. Request Order Qty | o2o_fulfillment_request_order_cnt | — | summary 表 |
| 7 | Request Order | 7-LY | LY | 7.1 Request Order Qty LY | — | o2o_fulfillment_request_order_cnt | summary 表 |
| 8 | Request Order | 8-vs LY | vs LY | 7.2 Request Order Qty vs LY | — | — | summary 表 |
| 9 | Request Order | 9-Units | Units | 8. Request Units | o2o_fulfillment_request_qty | — | summary 表 |
| 10 | Request Order | 10-LY | LY | 8.1 Request Units LY | — | o2o_fulfillment_request_qty | summary 表 |
| 11 | Request Order | 11-vs LY | vs LY | 8.2 Request Units vs LY | — | — | summary 表 |
| 12 | Request Order | 12-Amt | Amt | 9. Request Order Amt | o2o_fulfillment_request_sales_amt | — | summary 表 |
| 13 | Request Order | 13-LY | LY | 9.1 Request Order Amt LY | — | o2o_fulfillment_request_sales_amt | summary 表 |
| 14 | Request Order | 14-vs LY | vs LY | 9.2 Request Order Amt vs LY | — | — | summary 表 |
| 15 | Shipped Order | 15-Orders | Orders | 10. Shipped Order Qty | o2o_fulfillment_shipped_order_cnt | — | summary 表 |
| 16 | Shipped Order | 16-LY | LY | 10.1 Shipped Order Qty LY | — | o2o_fulfillment_shipped_order_cnt | summary 表 |
| 17 | Shipped Order | 17-vs LY | vs LY | 10.2 Shipped Order Qty vs LY | — | — | summary 表 |
| 18 | Shipped Order | 18-Units | Units | 11. Shipped Units | o2o_fulfillment_shipped_qty | — | summary 表 |
| 19 | Shipped Order | 19-LY | LY | 11.1 Shipped Units LY | — | o2o_fulfillment_shipped_qty | summary 表 |
| 20 | Shipped Order | 20-vs LY | vs LY | 11.2 Shipped Units vs LY | — | — | summary 表 |
| 21 | Shipped Order | 21-Amt | Amt | 12. Shipped Order Amt | o2o_fulfillment_shipped_sales_amt | — | summary 表 |
| 22 | Shipped Order | 22-LY | LY | 12.1 Shipped Order Amt LY | — | o2o_fulfillment_shipped_sales_amt | summary 表 |
| 23 | Shipped Order | 23-vs LY | vs LY | 12.2 Shipped Order Amt vs LY | — | — | summary 表 |
| 24 | Unfulfillment% | 24-Act | Act | 13. Unfulfillment% | o2o_fulfillment_unshipped_order_cnt / o2o_fulfillment_request_order_cnt | — | summary 表 |
| 25 | Unfulfillment% | 25-LY | LY | 13.1 Unfulfillment% LY | — | 同上（LY 区间） | summary 表 |
| 26 | Unfulfillment% | 26-vs LY | vs LY | 13.2 Unfulfillment% vs LY | — | — | summary 表 |
| 27 | Unfulfilled Order | 27-Orders | Orders | 14. Unfulfilled Order | o2o_fulfillment_unshipped_order_cnt | — | summary 表 |
| 28 | Unfulfilled Order | 28-LY | LY | 14.1 Unfulfilled Order LY | — | o2o_fulfillment_unshipped_order_cnt | summary 表 |
| 29 | Unfulfilled Order | 29-vs LY | vs LY | 14.2 Unfulfilled Order vs LY | — | — | summary 表 |
| 30 | Unfulfilled Order | 30-Units | Units | 15. Unfulfilled Units | o2o_fulfillment_unshipped_qty | — | summary 表 |
| 31 | Unfulfilled Order | 31-LY | LY | 15.1 Unfulfilled Units LY | — | o2o_fulfillment_unshipped_qty | summary 表 |
| 32 | Unfulfilled Order | 32-vs LY | vs LY | 15.2 Unfulfilled Units vs LY | — | — | summary 表 |
| 33 | Unfulfilled Order | 33-Amt | Amt | 16. Unfulfilled Amt | o2o_fulfillment_unshipped_sales_amt | — | summary 表 |
| 34 | Unfulfilled Order | 34-LY | LY | 16.1 Unfulfilled Amt LY | — | o2o_fulfillment_unshipped_sales_amt | summary 表 |
| 35 | Unfulfilled Order | 35-vs LY | vs LY | 16.2 Unfulfilled Amt vs LY | — | — | summary 表 |
| 36 | Product Volume | 36-Product Volume | Product Volume | 17. Product Volume | stock_qty（末日）+ o2o_fulfillment_shipped_qty（区间） | — | summary 表 |

> 注：Order Processing Efficiency 分组（1/2）和 Product Volume 分组（36）只有单列，无 LY/vs LY 列。这些组在总路由中直接返回 Act 值，不进入 vs LY 派生分支。

### 4.2 Fulfillment PB Merchandise Act Base Value（本期基础值）

```dax
Fulfillment PB Merchandise Act Base Value = 
// ========================================
// 度量值: Fulfillment PB Merchandise Act Base Value
// Display Folder: Base Metrics
// 用途: 根据 Metric_ID 路由到本期（Act）基础值
// 依赖: 'Dim_ColMetric_Fulfillment_PB_Merchandise'[Metric_ID, Metric_IsCurrencyAmount],
//       a02_e2e_boss_performance_summary_d, a02_e2e_boss_fulfillment_request_data_d
// 口径来源: PB Merchandise.md 子模块三 - 从 4. Avg. No. of Store Passed 起的本期值
// 筛选上下文:
//   - calc_type = "fulfillment"（硬编码，本方案所有指标固定）
//   - data_date ∈ [__TimeMin, __TimeMax]（全局时间范围，区间 SUM）
//   - Product Volume（Metric_ID 36）特殊处理：库存取 data_date = __TimeMax（末日 SUM），销量取区间 SUM
//   - 金额类指标（Metric_IsCurrencyAmount=TRUE）÷ __FXRate（汇率）
// 数据底表:
//   - Metric_ID 1, 2 → a02_e2e_boss_fulfillment_request_data_d
//   - Metric_ID 3-36 → a02_e2e_boss_performance_summary_d
// ========================================
    VAR __MetricID = SELECTEDVALUE('Dim_ColMetric_Fulfillment_PB_Merchandise'[Metric_ID])
    VAR __IsCurrencyAmount = SELECTEDVALUE('Dim_ColMetric_Fulfillment_PB_Merchandise'[Metric_IsCurrencyAmount], FALSE)
    // ── 时间筛选：本期 ──
    VAR __TimeMin = SELECTEDVALUE(Slicer_Time_Frame_Min[TimeFrame_Min])
    VAR __TimeMax = SELECTEDVALUE(Slicer_Time_Frame_Max[TimeFrame_Max])
    // ── 汇率（金额类指标需要除以汇率）──
    VAR __FXRate = SELECTEDVALUE(Slicer_Currency_Selection[Currency_ExchangeRate], 1)

    // ═══════════════════════════════════════
    // a02_e2e_boss_fulfillment_request_data_d 基础聚合（Metric_ID 1, 2 专用）
    // calc_type = "fulfillment"（本期区间 SUM）
    // ═══════════════════════════════════════
    VAR __RequestTimes_Act =
        CALCULATE(
            SUM('a02_e2e_boss_fulfillment_request_data_d'[o2o_fulfillment_request_times]),
            'a02_e2e_boss_fulfillment_request_data_d'[calc_type] = "fulfillment",
            'a02_e2e_boss_fulfillment_request_data_d'[data_date] >= __TimeMin,
            'a02_e2e_boss_fulfillment_request_data_d'[data_date] <= __TimeMax
        )
    VAR __RequestDuration_Act =
        CALCULATE(
            SUM('a02_e2e_boss_fulfillment_request_data_d'[o2o_fulfillment_request_duration]),
            'a02_e2e_boss_fulfillment_request_data_d'[calc_type] = "fulfillment",
            'a02_e2e_boss_fulfillment_request_data_d'[data_date] >= __TimeMin,
            'a02_e2e_boss_fulfillment_request_data_d'[data_date] <= __TimeMax
        )
    VAR __RequestSkuQty_Act =
        CALCULATE(
            SUM('a02_e2e_boss_fulfillment_request_data_d'[o2o_fulfillment_request_sku_qty]),
            'a02_e2e_boss_fulfillment_request_data_d'[calc_type] = "fulfillment",
            'a02_e2e_boss_fulfillment_request_data_d'[data_date] >= __TimeMin,
            'a02_e2e_boss_fulfillment_request_data_d'[data_date] <= __TimeMax
        )

    // ═══════════════════════════════════════
    // a02_e2e_boss_performance_summary_d 基础聚合（Metric_ID 3-36）
    // calc_type = "fulfillment"（本期区间 SUM）
    // ═══════════════════════════════════════
    VAR __ShippedOrderCnt_Act =
        CALCULATE(
            SUM('a02_e2e_boss_performance_summary_d'[o2o_fulfillment_shipped_order_cnt]),
            'a02_e2e_boss_performance_summary_d'[calc_type] = "fulfillment",
            'a02_e2e_boss_performance_summary_d'[data_date] >= __TimeMin,
            'a02_e2e_boss_performance_summary_d'[data_date] <= __TimeMax
        )
    VAR __RequestOrderCnt_Act =
        CALCULATE(
            SUM('a02_e2e_boss_performance_summary_d'[o2o_fulfillment_request_order_cnt]),
            'a02_e2e_boss_performance_summary_d'[calc_type] = "fulfillment",
            'a02_e2e_boss_performance_summary_d'[data_date] >= __TimeMin,
            'a02_e2e_boss_performance_summary_d'[data_date] <= __TimeMax
        )
    VAR __RequestQty_Act =
        CALCULATE(
            SUM('a02_e2e_boss_performance_summary_d'[o2o_fulfillment_request_qty]),
            'a02_e2e_boss_performance_summary_d'[calc_type] = "fulfillment",
            'a02_e2e_boss_performance_summary_d'[data_date] >= __TimeMin,
            'a02_e2e_boss_performance_summary_d'[data_date] <= __TimeMax
        )
    VAR __RequestSalesAmt_Act =
        CALCULATE(
            SUM('a02_e2e_boss_performance_summary_d'[o2o_fulfillment_request_sales_amt]),
            'a02_e2e_boss_performance_summary_d'[calc_type] = "fulfillment",
            'a02_e2e_boss_performance_summary_d'[data_date] >= __TimeMin,
            'a02_e2e_boss_performance_summary_d'[data_date] <= __TimeMax
        )
    VAR __ShippedQty_Act =
        CALCULATE(
            SUM('a02_e2e_boss_performance_summary_d'[o2o_fulfillment_shipped_qty]),
            'a02_e2e_boss_performance_summary_d'[calc_type] = "fulfillment",
            'a02_e2e_boss_performance_summary_d'[data_date] >= __TimeMin,
            'a02_e2e_boss_performance_summary_d'[data_date] <= __TimeMax
        )
    VAR __ShippedSalesAmt_Act =
        CALCULATE(
            SUM('a02_e2e_boss_performance_summary_d'[o2o_fulfillment_shipped_sales_amt]),
            'a02_e2e_boss_performance_summary_d'[calc_type] = "fulfillment",
            'a02_e2e_boss_performance_summary_d'[data_date] >= __TimeMin,
            'a02_e2e_boss_performance_summary_d'[data_date] <= __TimeMax
        )
    VAR __UnshippedOrderCnt_Act =
        CALCULATE(
            SUM('a02_e2e_boss_performance_summary_d'[o2o_fulfillment_unshipped_order_cnt]),
            'a02_e2e_boss_performance_summary_d'[calc_type] = "fulfillment",
            'a02_e2e_boss_performance_summary_d'[data_date] >= __TimeMin,
            'a02_e2e_boss_performance_summary_d'[data_date] <= __TimeMax
        )
    VAR __UnshippedQty_Act =
        CALCULATE(
            SUM('a02_e2e_boss_performance_summary_d'[o2o_fulfillment_unshipped_qty]),
            'a02_e2e_boss_performance_summary_d'[calc_type] = "fulfillment",
            'a02_e2e_boss_performance_summary_d'[data_date] >= __TimeMin,
            'a02_e2e_boss_performance_summary_d'[data_date] <= __TimeMax
        )
    VAR __UnshippedSalesAmt_Act =
        CALCULATE(
            SUM('a02_e2e_boss_performance_summary_d'[o2o_fulfillment_unshipped_sales_amt]),
            'a02_e2e_boss_performance_summary_d'[calc_type] = "fulfillment",
            'a02_e2e_boss_performance_summary_d'[data_date] >= __TimeMin,
            'a02_e2e_boss_performance_summary_d'[data_date] <= __TimeMax
        )

    // ═══════════════════════════════════════
    // 库存期末取末日聚合（Product Volume 专用，Metric_ID 36）
    // 口径：库存看所选时间范围的期末库存，只要最后一天的数据。
    // ═══════════════════════════════════════
    VAR __StockQty_Act =
        CALCULATE(
            SUM('a02_e2e_boss_performance_summary_d'[stock_qty]),
            'a02_e2e_boss_performance_summary_d'[calc_type] = "fulfillment",
            'a02_e2e_boss_performance_summary_d'[data_date] = __TimeMax
        )

    // ═══════════════════════════════════════
    // 路由分发（按 Metric_ID）
    // 金额类指标 ÷ __FXRate（汇率换算）
    // ═══════════════════════════════════════
    RETURN
        SWITCH(
            __MetricID,
            // ── Order Processing Efficiency 分组（a02_e2e_boss_fulfillment_request_data_d）──
            1,  DIVIDE(__RequestTimes_Act, __RequestSkuQty_Act),                                           // Avg. No. of Store Passed Act
            2,  DIVIDE(__RequestDuration_Act, __RequestSkuQty_Act),                                        // Avg. Processing Time(Hour) Act
            // ── Fulfillment% 分组 ──
            3,  DIVIDE(__ShippedOrderCnt_Act, __RequestOrderCnt_Act),                                      // Fulfillment% Act
            // ── Request Order 分组 ──
            6,  __RequestOrderCnt_Act,                                                                     // Request Order Qty Act
            9,  __RequestQty_Act,                                                                          // Request Units Act
            12, IF(__IsCurrencyAmount, DIVIDE(__RequestSalesAmt_Act, __FXRate), __RequestSalesAmt_Act),   // Request Order Amt Act
            // ── Shipped Order 分组 ──
            15, __ShippedOrderCnt_Act,                                                                     // Shipped Order Qty Act
            18, __ShippedQty_Act,                                                                          // Shipped Units Act
            21, IF(__IsCurrencyAmount, DIVIDE(__ShippedSalesAmt_Act, __FXRate), __ShippedSalesAmt_Act),   // Shipped Order Amt Act
            // ── Unfulfillment% 分组 ──
            24, DIVIDE(__UnshippedOrderCnt_Act, __RequestOrderCnt_Act),                                    // Unfulfillment% Act
            // ── Unfulfilled Order 分组 ──
            27, __UnshippedOrderCnt_Act,                                                                   // Unfulfilled Order Qty Act
            30, __UnshippedQty_Act,                                                                        // Unfulfilled Units Act
            33, IF(__IsCurrencyAmount, DIVIDE(__UnshippedSalesAmt_Act, __FXRate), __UnshippedSalesAmt_Act), // Unfulfilled Amt Act
            // ── Product Volume 分组（末日库存 + 区间销量）──
            36, __StockQty_Act + __ShippedQty_Act,                                                         // Product Volume Act
            BLANK()
        )
```

### 4.3 Fulfillment PB Merchandise LY Base Value（去年同期基础值，财历映射）

```dax
Fulfillment PB Merchandise LY Base Value = 
// ========================================
// 度量值: Fulfillment PB Merchandise LY Base Value
// Display Folder: Base Metrics
// 用途: 根据 Metric_ID 路由到去年同期（LY）基础值
// 依赖: 'Dim_ColMetric_Fulfillment_PB_Merchandise'[Metric_ID, Metric_IsCurrencyAmount],
//       Slicer_Time_Frame_Min/Max[TimeFrame_Min_LY, TimeFrame_Max_LY],
//       a02_e2e_boss_performance_summary_d
// 口径来源: PB Merchandise.md 子模块三 - 从 4. 起的 LY 值
// 时间偏移: 财历映射（直接读取日期表内置 LY 字段）
//   - 全局 LY 起始日: SELECTEDVALUE(Slicer_Time_Frame_Min[TimeFrame_Min_LY])
//   - 全局 LY 结束日: SELECTEDVALUE(Slicer_Time_Frame_Max[TimeFrame_Max_LY])
//   - 无需 EDATE -12 或 Key 偏移计算
// 金额类指标 ÷ __FXRate（汇率换算）
// 注：Order Processing Efficiency（1/2）和 Product Volume（36）无 LY 列，返回 BLANK
// ========================================
    VAR __MetricID = SELECTEDVALUE('Dim_ColMetric_Fulfillment_PB_Merchandise'[Metric_ID])
    VAR __IsCurrencyAmount = SELECTEDVALUE('Dim_ColMetric_Fulfillment_PB_Merchandise'[Metric_IsCurrencyAmount], FALSE)
    // ── 直接读取日期表内置的 LY 时间范围 ──
    VAR __LYTimeMin = SELECTEDVALUE(Slicer_Time_Frame_Min[TimeFrame_Min_LY])
    VAR __LYTimeMax = SELECTEDVALUE(Slicer_Time_Frame_Max[TimeFrame_Max_LY])
    // ── 汇率 ──
    VAR __FXRate = SELECTEDVALUE(Slicer_Currency_Selection[Currency_ExchangeRate], 1)

    // ═══════════════════════════════════════
    // 基础聚合：calc_type = "fulfillment"（去年同期区间 SUM）
    // 注：LY 仅涉及 summary 表，request_data 表的指标 4、5 无 LY 列
    // ═══════════════════════════════════════
    VAR __ShippedOrderCnt_LY =
        CALCULATE(
            SUM('a02_e2e_boss_performance_summary_d'[o2o_fulfillment_shipped_order_cnt]),
            'a02_e2e_boss_performance_summary_d'[calc_type] = "fulfillment",
            'a02_e2e_boss_performance_summary_d'[data_date] >= __LYTimeMin,
            'a02_e2e_boss_performance_summary_d'[data_date] <= __LYTimeMax
        )
    VAR __RequestOrderCnt_LY =
        CALCULATE(
            SUM('a02_e2e_boss_performance_summary_d'[o2o_fulfillment_request_order_cnt]),
            'a02_e2e_boss_performance_summary_d'[calc_type] = "fulfillment",
            'a02_e2e_boss_performance_summary_d'[data_date] >= __LYTimeMin,
            'a02_e2e_boss_performance_summary_d'[data_date] <= __LYTimeMax
        )
    VAR __RequestQty_LY =
        CALCULATE(
            SUM('a02_e2e_boss_performance_summary_d'[o2o_fulfillment_request_qty]),
            'a02_e2e_boss_performance_summary_d'[calc_type] = "fulfillment",
            'a02_e2e_boss_performance_summary_d'[data_date] >= __LYTimeMin,
            'a02_e2e_boss_performance_summary_d'[data_date] <= __LYTimeMax
        )
    VAR __RequestSalesAmt_LY =
        CALCULATE(
            SUM('a02_e2e_boss_performance_summary_d'[o2o_fulfillment_request_sales_amt]),
            'a02_e2e_boss_performance_summary_d'[calc_type] = "fulfillment",
            'a02_e2e_boss_performance_summary_d'[data_date] >= __LYTimeMin,
            'a02_e2e_boss_performance_summary_d'[data_date] <= __LYTimeMax
        )
    VAR __ShippedQty_LY =
        CALCULATE(
            SUM('a02_e2e_boss_performance_summary_d'[o2o_fulfillment_shipped_qty]),
            'a02_e2e_boss_performance_summary_d'[calc_type] = "fulfillment",
            'a02_e2e_boss_performance_summary_d'[data_date] >= __LYTimeMin,
            'a02_e2e_boss_performance_summary_d'[data_date] <= __LYTimeMax
        )
    VAR __ShippedSalesAmt_LY =
        CALCULATE(
            SUM('a02_e2e_boss_performance_summary_d'[o2o_fulfillment_shipped_sales_amt]),
            'a02_e2e_boss_performance_summary_d'[calc_type] = "fulfillment",
            'a02_e2e_boss_performance_summary_d'[data_date] >= __LYTimeMin,
            'a02_e2e_boss_performance_summary_d'[data_date] <= __LYTimeMax
        )
    VAR __UnshippedOrderCnt_LY =
        CALCULATE(
            SUM('a02_e2e_boss_performance_summary_d'[o2o_fulfillment_unshipped_order_cnt]),
            'a02_e2e_boss_performance_summary_d'[calc_type] = "fulfillment",
            'a02_e2e_boss_performance_summary_d'[data_date] >= __LYTimeMin,
            'a02_e2e_boss_performance_summary_d'[data_date] <= __LYTimeMax
        )
    VAR __UnshippedQty_LY =
        CALCULATE(
            SUM('a02_e2e_boss_performance_summary_d'[o2o_fulfillment_unshipped_qty]),
            'a02_e2e_boss_performance_summary_d'[calc_type] = "fulfillment",
            'a02_e2e_boss_performance_summary_d'[data_date] >= __LYTimeMin,
            'a02_e2e_boss_performance_summary_d'[data_date] <= __LYTimeMax
        )
    VAR __UnshippedSalesAmt_LY =
        CALCULATE(
            SUM('a02_e2e_boss_performance_summary_d'[o2o_fulfillment_unshipped_sales_amt]),
            'a02_e2e_boss_performance_summary_d'[calc_type] = "fulfillment",
            'a02_e2e_boss_performance_summary_d'[data_date] >= __LYTimeMin,
            'a02_e2e_boss_performance_summary_d'[data_date] <= __LYTimeMax
        )

    // ═══════════════════════════════════════
    // 路由分发（按 Metric_ID）
    // 金额类指标 ÷ __FXRate（汇率换算）
    // ═══════════════════════════════════════
    RETURN
        SWITCH(
            __MetricID,
            // ── Fulfillment% 分组 ──
            4,  DIVIDE(__ShippedOrderCnt_LY, __RequestOrderCnt_LY),                                       // Fulfillment% LY
            // ── Request Order 分组 ──
            7,  __RequestOrderCnt_LY,                                                                      // Request Order Qty LY
            10, __RequestQty_LY,                                                                           // Request Units LY
            13, IF(__IsCurrencyAmount, DIVIDE(__RequestSalesAmt_LY, __FXRate), __RequestSalesAmt_LY),     // Request Order Amt LY
            // ── Shipped Order 分组 ──
            16, __ShippedOrderCnt_LY,                                                                      // Shipped Order Qty LY
            19, __ShippedQty_LY,                                                                           // Shipped Units LY
            22, IF(__IsCurrencyAmount, DIVIDE(__ShippedSalesAmt_LY, __FXRate), __ShippedSalesAmt_LY),     // Shipped Order Amt LY
            // ── Unfulfillment% 分组 ──
            25, DIVIDE(__UnshippedOrderCnt_LY, __RequestOrderCnt_LY),                                     // Unfulfillment% LY
            // ── Unfulfilled Order 分组 ──
            28, __UnshippedOrderCnt_LY,                                                                    // Unfulfilled Order Qty LY
            31, __UnshippedQty_LY,                                                                         // Unfulfilled Units LY
            34, IF(__IsCurrencyAmount, DIVIDE(__UnshippedSalesAmt_LY, __FXRate), __UnshippedSalesAmt_LY), // Unfulfilled Amt LY
            // ── 其他分组（Order Processing Efficiency / Product Volume）无 LY 列 ──
            BLANK()
        )
```

### 4.4 Fulfillment PB Merchandise Base Value（总路由）

```dax
Fulfillment PB Merchandise Base Value = 
// ========================================
// 度量值: Fulfillment PB Merchandise Base Value
// Display Folder: Base Metrics
// 用途: 总路由，根据 Metric_ID 分发到 Act / LY / vs LY
// 依赖: [Fulfillment PB Merchandise Act Base Value], [Fulfillment PB Merchandise LY Base Value],
//       'Dim_ColMetric_Fulfillment_PB_Merchandise'[Metric_ID, Metric_Format_VsLY]
// 说明:
//   有 LY/vs LY 的分组（5 个 KPI 分组）：
//     Fulfillment% / Request Order / Shipped Order / Unfulfillment% / Unfulfilled Order
//     Metric_ID 路由规则：
//       - Act  列：Metric_ID ∈ {3,6,9,12,15,18,21,24,27,30,33}
//       - LY   列：Metric_ID ∈ {4,7,10,13,16,19,22,25,28,31,34}
//       - vs LY列：Metric_ID ∈ {5,8,11,14,17,20,23,26,29,32,35}
//     vs LY 行的 Act 对应 Metric_ID - 2，LY 对应 Metric_ID - 1
//   无 LY/vs LY 的分组（2 个 KPI 分组）：
//     Order Processing Efficiency / Product Volume
//     Metric_ID ∈ {1,2,36} 直接返回 Act 值
//
// vs LY 派生规则:
//   - 数量类/金额类：今年 / 去年 − 1（percent_1dp）
//   - 比率类（Fulfillment% / Unfulfillment%）：今年 − 去年（差值，展示时 ×10000 转 bp）
//
// REMOVEFILTERS 机制（参考 PB_Location_Fulfillment_detail_ms.md）:
//   矩阵行标题会保留断开维度的所有列筛选器，
//   仅覆盖 Metric_ID 会导致筛选条件冲突（如 Metric_ID=5 AND ColName="vs LY"）从而返回 BLANK。
//   因此 vs LY 行需先 REMOVEFILTERS 清除断开维度的所有筛选，再应用目标 Metric_ID。
// ========================================
    VAR __MetricID = SELECTEDVALUE('Dim_ColMetric_Fulfillment_PB_Merchandise'[Metric_ID])
    // 判断当前是否为 vs LY 行（仅 5 个有 vs LY 列的分组，共 11 个 vs LY Metric_ID）
    VAR __IsVsLY = __MetricID IN {5, 8, 11, 14, 17, 20, 23, 26, 29, 32, 35}

    // 修复上下文冲突：vs LY 行需要取 Act 和 LY 的值做派生计算，
    // 但当前筛选上下文下 Metric_ID 指向 vs LY 行，
    // 直接调用 Act/LY 度量会因 Metric_ID 不匹配而返回 BLANK。
    // 解决方案：先 REMOVEFILTERS 清除断开维度的所有筛选，再应用目标 Metric_ID。
    VAR __ActValue = 
        IF(
            __IsVsLY,
            CALCULATE(
                [Fulfillment PB Merchandise Act Base Value], 
                REMOVEFILTERS('Dim_ColMetric_Fulfillment_PB_Merchandise'), 
                'Dim_ColMetric_Fulfillment_PB_Merchandise'[Metric_ID] = __MetricID - 2
            ),
            [Fulfillment PB Merchandise Act Base Value]
        )

    VAR __LYValue = 
        IF(
            __IsVsLY,
            CALCULATE(
                [Fulfillment PB Merchandise LY Base Value], 
                REMOVEFILTERS('Dim_ColMetric_Fulfillment_PB_Merchandise'), 
                'Dim_ColMetric_Fulfillment_PB_Merchandise'[Metric_ID] = __MetricID - 1
            ),
            [Fulfillment PB Merchandise LY Base Value]
        )

    // ── vs LY 派生计算 ──
    // percent_1dp（数量/金额类）：今年 / 去年 − 1
    // delta_bp（比率类）：今年 − 去年（差值，展示时 ×10000 转 bp 在 Cell Display 中实现）
    VAR __VSLYGrowth =
        IF(
            ISBLANK(__LYValue) || __LYValue = 0,
            BLANK(),
            DIVIDE(__ActValue, __LYValue) - 1
        )
    VAR __VSLYDiff = __ActValue - __LYValue

    RETURN
        SWITCH(
            __MetricID,
            // ─── Act 本期值 ───
            1,  __ActValue,     // Avg. No. of Store Passed Act
            2,  __ActValue,     // Avg. Processing Time(Hour) Act
            3,  __ActValue,     // Fulfillment% Act
            6,  __ActValue,     // Request Order Qty Act
            9,  __ActValue,     // Request Units Act
            12, __ActValue,     // Request Order Amt Act
            15, __ActValue,     // Shipped Order Qty Act
            18, __ActValue,     // Shipped Units Act
            21, __ActValue,     // Shipped Order Amt Act
            24, __ActValue,     // Unfulfillment% Act
            27, __ActValue,     // Unfulfilled Order Qty Act
            30, __ActValue,     // Unfulfilled Units Act
            33, __ActValue,     // Unfulfilled Amt Act
            36, __ActValue,     // Product Volume Act
            // ─── LY 去年同期值 ───
            4,  __LYValue,      // Fulfillment% LY
            7,  __LYValue,      // Request Order Qty LY
            10, __LYValue,      // Request Units LY
            13, __LYValue,      // Request Order Amt LY
            16, __LYValue,      // Shipped Order Qty LY
            19, __LYValue,      // Shipped Units LY
            22, __LYValue,      // Shipped Order Amt LY
            25, __LYValue,      // Unfulfillment% LY
            28, __LYValue,      // Unfulfilled Order Qty LY
            31, __LYValue,      // Unfulfilled Units LY
            34, __LYValue,      // Unfulfilled Amt LY
            // ─── vs LY 派生值 ───
            5,  __VSLYDiff,     // Fulfillment% vs LY（delta_bp，差值）
            8,  __VSLYGrowth,   // Request Order Qty vs LY（percent_1dp）
            11, __VSLYGrowth,   // Request Units vs LY（percent_1dp）
            14, __VSLYGrowth,   // Request Order Amt vs LY（percent_1dp）
            17, __VSLYGrowth,   // Shipped Order Qty vs LY（percent_1dp）
            20, __VSLYGrowth,   // Shipped Units vs LY（percent_1dp）
            23, __VSLYGrowth,   // Shipped Order Amt vs LY（percent_1dp）
            26, __VSLYDiff,     // Unfulfillment% vs LY（delta_bp，差值）
            29, __VSLYGrowth,   // Unfulfilled Order Qty vs LY（percent_1dp）
            32, __VSLYGrowth,   // Unfulfilled Units vs LY（percent_1dp）
            35, __VSLYGrowth,   // Unfulfilled Amt vs LY（percent_1dp）
            BLANK()
        )
```

### 4.5 Fulfillment PB Merchandise Cell Value（对外值）

```dax
Fulfillment PB Merchandise Cell Value = 
// ========================================
// 度量值: Fulfillment PB Merchandise Cell Value
// Display Folder: Cell Values
// 用途: 对外暴露的单元格值，等于 Base Value
// 依赖: [Fulfillment PB Merchandise Base Value]
// ========================================
    [Fulfillment PB Merchandise Base Value]
```

### 4.6 Fulfillment PB Merchandise Cell Display（格式化显示）

```dax
Fulfillment PB Merchandise Cell Display = 
// ========================================
// 度量值: Fulfillment PB Merchandise Cell Display
// Display Folder: Formatting
// 用途: 按 ColType 选择对应行格式格式化显示
// 依赖: [Fulfillment PB Merchandise Cell Value],
//       'Dim_ColMetric_Fulfillment_PB_Merchandise'[ColType, Metric_Format_Act/LY/VsLY]
// 格式类型:
//   integer    → 千分位整数：1,000
//   currency   → 货币符号 + 千分位整数：¥1,000
//   percent_1dp → 百分比一位小数，不含正号：14.5%
//   delta_bp   → 增减基点整数，含正负号：+120bp
//                （值×10000 转 bp 的操作在此处实现）
//   decimal_1dp → 小数一位小数，千分位：1,234.5
// 说明：
//   - 无 LY/vs LY 的分组（Order Processing Efficiency / Product Volume）
//     ColType 不是 Act/LY/vs LY，而是具体指标名称或 "Product Volume"
//     这些列类型均使用 Metric_Format_Act 格式（与 Act 一致），因此 SWITCH 中统一映射。
// ========================================
    VAR __Value = [Fulfillment PB Merchandise Cell Value]
    VAR __ColType = SELECTEDVALUE('Dim_ColMetric_Fulfillment_PB_Merchandise'[ColType])
    // ── 按 ColType 选择对应行格式 ──
    // 对于无 LY/vs LY 的分组，ColType 不是 Act/LY/vs LY，此时直接取 Metric_Format_Act
    VAR __Format =
        SWITCH(
            __ColType,
            "Act",   SELECTEDVALUE('Dim_ColMetric_Fulfillment_PB_Merchandise'[Metric_Format_Act]),
            "LY",    SELECTEDVALUE('Dim_ColMetric_Fulfillment_PB_Merchandise'[Metric_Format_LY]),
            "vs LY", SELECTEDVALUE('Dim_ColMetric_Fulfillment_PB_Merchandise'[Metric_Format_VsLY]),
            // 无 LY/vs LY 分组的列类型，统一使用 Act 格式
            SELECTEDVALUE('Dim_ColMetric_Fulfillment_PB_Merchandise'[Metric_Format_Act])
        )
    VAR __CurrencySymbol = SELECTEDVALUE(Slicer_Currency_Selection[Currency_Symbol], "¥")
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            SWITCH(
                __Format,
                // ─── 整数（千分位）──────────────────────────
                "integer",
                    FORMAT(__Value, "#,##0"),                                                                     // 1,000
                // ─── 货币（符号由币种切片器决定）─────────────
                "currency",
                    __CurrencySymbol & FORMAT(__Value, "#,##0"),                                                  // ¥1,000
                // ─── 百分比（不含正号）──────────────────────
                "percent_1dp",
                    FORMAT(__Value, "#,##0.0%"),                                                                  // 14.5%
                // ─── 增减基点（含正负号，值×10000 转 bp）─────
                "delta_bp",
                    IF(ROUND(__Value * 10000, 0) > 0, "+", "") & FORMAT(__Value * 10000, "#,##0bp;-#,##0bp;0bp"), // +120bp
                // ─── 小数（一位小数，千分位）────────────────
                "decimal_1dp",
                    FORMAT(__Value, "#,##0.0"),                                                                   // 1,234.5
                // ─── 默认 ─────────────────────────────────
                FORMAT(__Value, "#,##0.00")
            )
        )
```

### 4.7 Fulfillment PB Merchandise Cell Font Color（字体颜色）

```dax
Fulfillment PB Merchandise Cell Font Color = 
// ========================================
// 度量值: Fulfillment PB Merchandise Cell Font Color
// Display Folder: Formatting
// 用途: 区分 KPIGroup 行（分组标题行）与 KPI 行，并对 vs LY 列启用正/负/零三色
// 依赖: [Fulfillment PB Merchandise Cell Value],
//       'Dim_ColMetric_Fulfillment_PB_Merchandise'[ColType, Metric_ColorPositive/Negative/Zero/Default],
//       ISINSCOPE('Dim_ColMetric_Fulfillment_PB_Merchandise'[ColName])
// 层级判断:
//   ISINSCOPE('Dim_ColMetric_Fulfillment_PB_Merchandise'[ColName]) = TRUE  → KPI 行（具体指标行）
//   ISINSCOPE('Dim_ColMetric_Fulfillment_PB_Merchandise'[ColName]) = FALSE → KPIGroup 行（分组标题行）
// 颜色规则:
//   ┌─────────────┬───────────────────┬──────────────────────────────────────┐
//   │             │  vs LY 列         │  其他列（Act / LY / Orders / 率等）  │
//   ├─────────────┼───────────────────┼──────────────────────────────────────┤
//   │  KPI 行     │  正#1A9018/负#D64550/零#E1C233/默认#5F6165  │  #5F6165（深灰）│
//   │  KPIGroup 行│  #252423（黑色）  │  #252423（黑色）                     │
//   └─────────────┴───────────────────┴──────────────────────────────────────┘
// ========================================
    VAR __Value = [Fulfillment PB Merchandise Cell Value]
    VAR __ColType = SELECTEDVALUE('Dim_ColMetric_Fulfillment_PB_Merchandise'[ColType])
    VAR __IsKPIRow = ISINSCOPE('Dim_ColMetric_Fulfillment_PB_Merchandise'[ColName])
    // ── 颜色取值（来自列维度表）──
    VAR __ColorPositive = SELECTEDVALUE('Dim_ColMetric_Fulfillment_PB_Merchandise'[Metric_ColorPositive], "#1A9018")
    VAR __ColorNegative = SELECTEDVALUE('Dim_ColMetric_Fulfillment_PB_Merchandise'[Metric_ColorNegative], "#D64550")
    VAR __ColorZero = SELECTEDVALUE('Dim_ColMetric_Fulfillment_PB_Merchandise'[Metric_ColorZero], "#E1C233")
    VAR __ColorDefault = SELECTEDVALUE('Dim_ColMetric_Fulfillment_PB_Merchandise'[Metric_ColorDefault], "#5F6165")

    RETURN 
        SWITCH(
            TRUE(),
            // ─── KPIGroup 行（分组标题行）：统一黑色 #252423 ───
            NOT __IsKPIRow && __ColType <> "vs LY",          "#252423",
            NOT __IsKPIRow && __ColType = "vs LY" && ISBLANK(__Value),   __ColorDefault,
            NOT __IsKPIRow && __ColType = "vs LY" && __Value > 0,        __ColorPositive,
            NOT __IsKPIRow && __ColType = "vs LY" && __Value < 0,        __ColorNegative,
            NOT __IsKPIRow && __ColType = "vs LY" && __Value = 0,        __ColorZero,
            // ─── KPI 行 + 非 vs LY 列：深灰 #5F6165 ───
            __IsKPIRow && __ColType <> "vs LY",          "#5F6165",
            // ─── KPI 行 + vs LY 列：启用正/负/零三色 ───
            __IsKPIRow && __ColType = "vs LY" && ISBLANK(__Value),   __ColorDefault,
            __IsKPIRow && __ColType = "vs LY" && __Value > 0,        __ColorPositive,
            __IsKPIRow && __ColType = "vs LY" && __Value < 0,        __ColorNegative,
            __IsKPIRow && __ColType = "vs LY" && __Value = 0,        __ColorZero,
            // ─── 兜底 ───
            "#252423"
        )
```

### 4.8 Fulfillment PB Merchandise Cell Background Color（背景色）

```dax
Fulfillment PB Merchandise Cell Background Color = 
// ========================================
// 度量值: Fulfillment PB Merchandise Cell Background Color
// Display Folder: Formatting
// 用途: 区分 KPIGroup 行（分组标题行）与 KPI 行的背景色
// 依赖: ISINSCOPE('Dim_ColMetric_Fulfillment_PB_Merchandise'[ColName])
// 颜色规则:
//   KPIGroup 行（分组标题行）: #E6D9C7（中米色）
//   KPI 行（具体指标行）     : #FFFFFF（白色）
// ========================================
    VAR __IsKPIRow = ISINSCOPE('Dim_ColMetric_Fulfillment_PB_Merchandise'[ColName])
    RETURN
        IF(
            __IsKPIRow,
            "#FFFFFF",   // KPI 行：白色
            "#E6D9C7"    // KPIGroup 行：中米色
        )
```

### 4.9 Fulfillment PB Merchandise Cell SVG Icon（SVG 图标）

```dax
Fulfillment PB Merchandise Cell SVG Icon = 
// ========================================
// 度量值: Fulfillment PB Merchandise Cell SVG Icon
// Display Folder: Formatting
// 用途: 仅 vs LY 列 + KPI 行返回 SVG 圆形图标
// 依赖: [Fulfillment PB Merchandise Cell Value],
//       'Dim_ColMetric_Fulfillment_PB_Merchandise'[ColType, Metric_ColorPositive/Negative/Zero]
// 配置: 需将此度量值的数据类别设为"图像 URL"
// 图标规则:
//   ┌─────────────┬──────────────────────────────────────┐
//   │             │  vs LY 列                            │
//   ├─────────────┼──────────────────────────────────────┤
//   │  KPI 行     │  正→绿圆 / 负→红圆 / 零→黄圆         │
//   │  KPIGroup 行│  不显示（BLANK）                     │
//   └─────────────┴──────────────────────────────────────┘
//   其他列（Act / LY / Orders / 率等）：不显示（BLANK）
// 颜色与 Font Color 保持一致（取自 Dim_ColMetric_Fulfillment_PB_Merchandise 的颜色字段）
// ========================================
    VAR __Value = [Fulfillment PB Merchandise Cell Value]
    VAR __ColType = SELECTEDVALUE('Dim_ColMetric_Fulfillment_PB_Merchandise'[ColType])
    VAR __IsKPIRow = ISINSCOPE('Dim_ColMetric_Fulfillment_PB_Merchandise'[ColName])
    // ── 启用图标条件：vs LY 列 + KPI 行 ──
    VAR __NeedsIcon = __ColType = "vs LY" && __IsKPIRow
    // ── 颜色取值（来自列维度表）──
    VAR __ColorPositive = SELECTEDVALUE('Dim_ColMetric_Fulfillment_PB_Merchandise'[Metric_ColorPositive], "#1A9018")
    VAR __ColorNegative = SELECTEDVALUE('Dim_ColMetric_Fulfillment_PB_Merchandise'[Metric_ColorNegative], "#D64550")
    VAR __ColorZero = SELECTEDVALUE('Dim_ColMetric_Fulfillment_PB_Merchandise'[Metric_ColorZero], "#E1C233")
    // ── SVG 圆形图标 ──
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
            __Value > 0,                     __GreenSVG,
            __Value < 0,                     __RedSVG,
            __Value = 0,                     __YellowSVG,
            BLANK()
        )
```

---

## 5. 度量值清单与 Display Folder

| 序号 | 度量值名称 | Display Folder | 用途 |
|------|-----------|----------------|------|
| 1 | Fulfillment PB Merchandise Act Base Value | Base Metrics | 本期基础值（区间 SUM；Product Volume 末日库存+区间销量；双数据底表） |
| 2 | Fulfillment PB Merchandise LY Base Value | Base Metrics | 去年同期基础值（财历映射，区间 SUM） |
| 3 | Fulfillment PB Merchandise Base Value | Base Metrics | 总路由（含 vs LY 派生 + REMOVEFILTERS） |
| 4 | Fulfillment PB Merchandise Cell Value | Cell Values | 对外值 = Base Value |
| 5 | Fulfillment PB Merchandise Cell Display | Formatting | 格式化显示文本 |
| 6 | Fulfillment PB Merchandise Cell Font Color | Formatting | 字体颜色 |
| 7 | Fulfillment PB Merchandise Cell Background Color | Formatting | 背景色 |
| 8 | Fulfillment PB Merchandise Cell SVG Icon | Formatting | SVG 图标（仅 vs LY 列 + KPI 行） |

---

## 6. 血缘关系图

```
┌─────────────────────────────────────────────────────────────────────┐
│                        数据源层                                      │
│  a02_e2e_boss_performance_summary_d（事实表 1）                      │
│  字段: data_date, brand, product_type, category_summary, category,  │
│        calc_type, o2o_fulfillment_shipped_order_cnt,                │
│        o2o_fulfillment_request_order_cnt,                           │
│        o2o_fulfillment_request_qty, o2o_fulfillment_request_sales_amt,│
│        o2o_fulfillment_shipped_qty, o2o_fulfillment_shipped_sales_amt,│
│        o2o_fulfillment_unshipped_order_cnt,                         │
│        o2o_fulfillment_unshipped_qty,                               │
│        o2o_fulfillment_unshipped_sales_amt, stock_qty               │
│                                                                     │
│  a02_e2e_boss_fulfillment_request_data_d（事实表 2）                 │
│  字段: data_date, brand, product_type, category_summary, category,  │
│        calc_type, o2o_fulfillment_request_times,                    │
│        o2o_fulfillment_request_duration,                            │
│        o2o_fulfillment_request_sku_qty                              │
└──────────────────────────────┬──────────────────────────────────────┘
                               │
                               │ 模型自动传递（行维度 = 事实表字段直接拉取）
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────────┐
│                        度量值层                                      │
│                                                                     │
│  ┌───────────────────────────────────┐   ┌───────────────────────┐  │
│  │ Fulfillment PB Merchandise        │   │ Fulfillment PB        │  │
│  │ Act Base Value                    │   │ Merchandise LY Base   │  │
│  │ (本期, 双底表, 区间 SUM +         │   │ Value (LY, 财历映射,  │  │
│  │  Product Volume 末日库存+区间销量) │   │  区间 SUM)            │  │
│  └───────────────┬───────────────────┘   └───────────┬───────────┘  │
│                  │                        ────────────┘              │
│                  │    ┌───────────────────────────────┘              │
│                  ▼    ▼                                              │
│  ┌───────────────────────────────────┐   ┌───────────────────────┐  │
│  │ Fulfillment PB Merchandise        │   │ Dim_ColMetric_        │  │
│  │ Base Value                        │◄──│ Fulfillment_PB_       │  │
│  │ (总路由 + vs LY 派生)              │   │ Merchandise           │  │
│  │ REMOVEFILTERS + 目标 Metric_ID     │   │ (断开维度, Metric_ID) │  │
│  │ Order Processing Efficiency 和     │   └───────────────────────┘  │
│  │ Product Volume 无 vs LY，直返 Act  │                              │
│  └───────────────┬───────────────────┘                              │
│                  │                                                  │
│                  ▼                                                  │
│  ┌───────────────────────────────────┐                              │
│  │ Fulfillment PB Merchandise        │                              │
│  │ Cell Value (= Base Value)         │                              │
│  └───────────────┬───────────────────┘                              │
│                  │                                                  │
│                  ▼                                                  │
│  ┌───────────────────────────────────┐   ┌───────────────────────┐  │
│  │ Fulfillment PB Merchandise        │◄──│ Dim_ColMetric_        │  │
│  │ Cell Display (格式化文本)          │   │ Fulfillment_PB_       │  │
│  └───────────────┬───────────────────┘   │ Merchandise           │  │
│                  │                        │ (ColType, Format_*)   │  │
│                  ▼                        └───────────────────────┘  │
│  ┌─────────────────────────────────────────────────────┐            │
│  │  Fulfillment PB Merchandise Cell Font Color          │            │
│  │  Fulfillment PB Merchandise Cell Background Color    │            │
│  │  Fulfillment PB Merchandise Cell SVG Icon            │            │
│  │  (条件格式度量值，ISINSCOPE 判断 KPIGroup/KPI 行)     │            │
│  └─────────────────────────────────────────────────────┘            │
└─────────────────────────────────────────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────────┐
│                        可视化层                                      │
│  Matrix 视觉对象                                                     │
│  行: 事实表字段（brand / product_type / category_summary / category）│
│  列: 'Dim_ColMetric_Fulfillment_PB_Merchandise'[KPIGroup]            │
│      > 'Dim_ColMetric_Fulfillment_PB_Merchandise'[ColName]           │
│  值: [Fulfillment PB Merchandise Cell Display]                      │
│  条件格式:                                                           │
│    字体颜色 → [Fulfillment PB Merchandise Cell Font Color]          │
│    背景色   → [Fulfillment PB Merchandise Cell Background Color]    │
│    SVG 图标 → [Fulfillment PB Merchandise Cell SVG Icon]（数据类别=图像URL）│
└─────────────────────────────────────────────────────────────────────┘
```

---

## 7. 矩阵视觉对象配置

### 7.1 字段配置

| 区域 | 字段 |
|------|------|
| **行** | 事实表字段（brand / product_type / category_summary / category，直接拉取） |
| **列** | 'Dim_ColMetric_Fulfillment_PB_Merchandise'[KPIGroup] > [ColName] |
| **值** | [Fulfillment PB Merchandise Cell Display] |

### 7.2 排序配置

| 字段 | 排序依据 |
|------|---------|
| 'Dim_ColMetric_Fulfillment_PB_Merchandise'[KPIGroup] | KPIGroup_Sort |
| 'Dim_ColMetric_Fulfillment_PB_Merchandise'[ColName] | ColName_Sort |

### 7.3 格式设置

- 关闭"阶梯布局"（Stepped Layout → Off）
- 关闭"+/-"展开按钮
- 列标题：居中对齐，加粗
- 行标题：左对齐
- 值：居中对齐

### 7.4 条件格式

对 [Fulfillment PB Merchandise Cell Display] 值区域设置：

1. **字体颜色**：右键值区域 → 条件格式 → 字体颜色 → 格式样式：字段值 → 基于字段：[Fulfillment PB Merchandise Cell Font Color]
2. **背景颜色**：右键值区域 → 条件格式 → 背景颜色 → 格式样式：字段值 → 基于字段：[Fulfillment PB Merchandise Cell Background Color]
3. **SVG 图标**（可选）：将 [Fulfillment PB Merchandise Cell SVG Icon] 度量值的数据类别设为"图像 URL"

---

## 8. 验证方法

### 8.1 矩阵结构验证

| 验证项 | 方法 |
|--------|------|
| 列数 | 确认 36 列（7 KPI 分组：2 个独立单列 + 5 个 3 列组 × 3 + 1 个独立单列） |
| 列排序 | KPIGroup 按 KPIGroup_Sort（10/20/.../70），ColName 按 ColName_Sort |
| 同名区分 | 确认各 KPI 同名 Act/LY/vs LY 在 ColName 中通过 Metric_ID 前缀区分 |
| KPIGroup 行颜色 | 字体黑色 #252423，背景中米色 #E6D9C7 |
| KPI 行颜色 | 非 vs LY 列字体深灰 #5F6165，背景白色 #FFFFFF；vs LY 列正/负/零三色 |
| SVG 图标 | 仅 vs LY 列 + KPI 行显示圆形图标 |
| 行展开 | brand 粒度行支持展开到 product_type → category_summary → category |

### 8.2 验证 SQL

```sql
-- Avg. No. of Store Passed Before Order Got Accepted（本期，a02_e2e_boss_fulfillment_request_data_d）
-- 计算公式：sum(o2o_fulfillment_request_times) / sum(o2o_fulfillment_request_sku_qty)
-- 假设 __TimeMin='2025-06-29', __TimeMax='2025-08-09'
SELECT
  SUM(o2o_fulfillment_request_times) * 1.0 / SUM(o2o_fulfillment_request_sku_qty) AS Avg_Store_Passed_Actual
FROM a02_e2e_boss_fulfillment_request_data_d
WHERE calc_type = 'fulfillment'
  AND data_date BETWEEN '2025-06-29' AND '2025-08-09';

-- Avg. Processing Time(Hour)（本期，a02_e2e_boss_fulfillment_request_data_d）
-- 计算公式：sum(o2o_fulfillment_request_duration) / sum(o2o_fulfillment_request_sku_qty)
SELECT
  SUM(o2o_fulfillment_request_duration) * 1.0 / SUM(o2o_fulfillment_request_sku_qty) AS Avg_Processing_Time_Actual
FROM a02_e2e_boss_fulfillment_request_data_d
WHERE calc_type = 'fulfillment'
  AND data_date BETWEEN '2025-06-29' AND '2025-08-09';

-- Fulfillment% O2O订单履约率（本期，a02_e2e_boss_performance_summary_d）
-- 计算公式：sum(o2o_fulfillment_shipped_order_cnt) / sum(o2o_fulfillment_request_order_cnt)
SELECT
  SUM(o2o_fulfillment_shipped_order_cnt) * 1.0 / SUM(o2o_fulfillment_request_order_cnt) AS Fulfillment_Pct_Actual
FROM a02_e2e_boss_performance_summary_d
WHERE calc_type = 'fulfillment'
  AND data_date BETWEEN '2025-06-29' AND '2025-08-09';

-- Fulfillment% vs LY = Fulfillment_Pct_Actual - Fulfillment_Pct_LY（delta_bp，×10000 转 bp）

-- Request Order Qty（本期）
SELECT SUM(o2o_fulfillment_request_order_cnt) AS Request_Order_Qty_Actual
FROM a02_e2e_boss_performance_summary_d
WHERE calc_type = 'fulfillment'
  AND data_date BETWEEN '__TimeMin' AND '__TimeMax';

-- Shipped Order Amt（本期，金额类需 ÷ 汇率）
SELECT SUM(o2o_fulfillment_shipped_sales_amt) AS Shipped_Order_Amt_Actual
FROM a02_e2e_boss_performance_summary_d
WHERE calc_type = 'fulfillment'
  AND data_date BETWEEN '__TimeMin' AND '__TimeMax';

-- Product Volume（本期，库存取末日 + 销量取区间）
-- 库存：sum(stock_qty) WHERE data_date = __TimeMax（仅最后一天）
-- 销量：sum(o2o_fulfillment_shipped_qty) WHERE data_date BETWEEN __TimeMin AND __TimeMax（整个筛选周期）
SELECT
  (SELECT SUM(stock_qty) FROM a02_e2e_boss_performance_summary_d
   WHERE calc_type = 'fulfillment' AND data_date = '__TimeMax')  -- 末日库存
  +
  (SELECT SUM(o2o_fulfillment_shipped_qty) FROM a02_e2e_boss_performance_summary_d
   WHERE calc_type = 'fulfillment' AND data_date BETWEEN '__TimeMin' AND '__TimeMax')  -- 区间销量
  AS Product_Volume_Actual;

-- Unfulfillment% O2O订单未履约率（本期）
-- 计算公式：sum(o2o_fulfillment_unshipped_order_cnt) / sum(o2o_fulfillment_request_order_cnt)
SELECT
  SUM(o2o_fulfillment_unshipped_order_cnt) * 1.0 / SUM(o2o_fulfillment_request_order_cnt) AS Unfulfillment_Pct_Actual
FROM a02_e2e_boss_performance_summary_d
WHERE calc_type = 'fulfillment'
  AND data_date BETWEEN '__TimeMin' AND '__TimeMax';
```

### 8.3 LY 日期范围获取方式说明

| TimeFrame_ID | LY 范围获取方式 | 说明 |
|--------------|-----------------|------|
| Day / Week / Month / Quarter / Year | 直接读日期表 `TimeFrame_Min_LY` / `TimeFrame_Max_LY` | 日期表已内置，无需 EDATE -12 或 Key 偏移 |

---

## 9. 注意事项

1. **双数据底表（关键逻辑）**：Order Processing Efficiency 分组（Metric_ID 1, 2）的数据底表为 `a02_e2e_boss_fulfillment_request_data_d`，字段为 `o2o_fulfillment_request_times` / `o2o_fulfillment_request_duration` / `o2o_fulfillment_request_sku_qty`；其余分组（Metric_ID 3-36）的数据底表为 `a02_e2e_boss_performance_summary_d`。Act Base Value 度量值同时聚合两张事实表，按 Metric_ID 路由分发。

2. **Product Volume 库存期末取末日 + 销量区间聚合（关键逻辑）**：Product Volume（Metric_ID 36）的聚合为 `SUM(stock_qty) WHERE data_date = __TimeMax`（末日库存）+ `SUM(o2o_fulfillment_shipped_qty) WHERE data_date ∈ [__TimeMin, __TimeMax]`（区间销量）。此口径严格遵循 PB Merchandise.md 指标 17 的要求：库存看所选时间范围的期末库存，只要最后一天的数据；销量看所有时间范围的销量总和，整个筛选周期的数据聚合。

3. **REMOVEFILTERS 机制**：vs LY 行的派生计算必须先 `REMOVEFILTERS('Dim_ColMetric_Fulfillment_PB_Merchandise')` 再应用目标 Metric_ID，否则矩阵行标题保留的筛选器会导致冲突返回 BLANK。这与 PB_Location_Fulfillment_detail_ms.md 的总路由范式完全一致。

4. **Metric_ID 编码规则**：
   - 有 LY/vs LY 的分组：Act = 组内首 ID，LY = Act + 1，vs LY = Act + 2；vs LY 行的 Act 对应 Metric_ID - 2，LY 对应 Metric_ID - 1
   - 无 LY/vs LY 的分组（Order Processing Efficiency / Product Volume）：Metric_ID 直接返回 Act 值，不进入 vs LY 派生分支

5. **calc_type 固定**：本方案所有度量值均硬编码 `calc_type = "fulfillment"`。

6. **LY 财历映射**：周/月/季/年粒度按财年定义，LY 采用财历映射（直接读取日期表内置 TimeFrame_Min_LY / TimeFrame_Max_LY 字段），不使用 EDATE -12。

7. **汇率换算**：金额类指标 ÷ Currency_ExchangeRate；比率类分子分母同币种相除自动抵消。vs LY 同比值因相除/相减自动抵消汇率影响。

8. **vs LY 派生分类**：
   - 数量类（Request Order Qty/Units、Shipped Order Qty/Units、Unfulfilled Order Qty/Units）：今年 / 去年 − 1 → percent_1dp
   - 金额类（Request Order Amt、Shipped Order Amt、Unfulfilled Amt）：今年 / 去年 − 1 → percent_1dp
   - 比率类（Fulfillment%、Unfulfillment%）：今年 − 去年 → delta_bp（展示时 ×10000 转 bp）

9. **无 LY/vs LY 分组的处理**：Order Processing Efficiency 分组（Metric_ID 1, 2）和 Product Volume 分组（Metric_ID 36）在列指标维度表中只设计了单列，没有 LY 和 vs LY 列。总路由中对这些 Metric_ID 直接返回 Act 值，Cell Display 中 ColType 非 Act/LY/vs LY 时统一使用 Metric_Format_Act 格式。

10. **行维度处理**：无行维度表，直接拉取事实表字段（brand / product_type / category_summary / category），天然形成筛选与分组，DAX 度量值无需显式处理。支持 brand 粒度行展开看 product_type → category_summary → category 粒度明细数据。

11. **与 PB_Location_Fulfillment_detail_ms.md 的关系**：本方案为 PB Merchandise Fulfillment 部分的矩阵 SWITCH 路由版本，与 PB Location 版本共享相同的架构范式（断开列维度 + SWITCH 动态路由 + REMOVEFILTERS 修复上下文），差异在于：
    - 行维度由 store 字段改为 merchandise 字段（brand/product_type/category_summary/category）
    - 列指标维度表替换为 Dim_ColMetric_Fulfillment_PB_Merchandise（36 行 vs 46 行）
    - 新增双数据底表逻辑（Metric_ID 1, 2 用 a02_e2e_boss_fulfillment_request_data_d）
    - Product Volume 为末日库存 + 区间销量的组合逻辑（vs Location 的 Inventory 为纯末日库存）
    - KPI 分组精简为 7 个（vs Location 的 11 个），不含 Rejected/Overdue/Customer/Others/Failed/Inventory 等 Location 特有分组
