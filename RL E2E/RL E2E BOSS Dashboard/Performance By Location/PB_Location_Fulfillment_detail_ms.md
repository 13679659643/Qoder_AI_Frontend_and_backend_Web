# Power BI 解决方案 — PB Location：Fulfillment 指标矩阵（SWITCH 路由）

> status: ready
> created: 2026-08-07
> type: 度量值开发 + 可视化构建
> 口径来源: 口径文档/PB Location.md 子模块五 BOSS Performance Details 从 6. Fulfillment% 起的剩余指标
> 参考实现: PB_Location_Sales_detail_ms.md（总路由 REMOVEFILTERS 范式）
> 列指标维度表: Dim_ColMetric_Fulfillment_PB_Location（46 行，覆盖 11 个 KPI 分组）

---

## 1. 需求理解

为 Performance By Location 页面实现 Fulfillment 分组（子模块五从 6. Fulfillment% 开始的剩余指标）的中国式矩阵效果：

- **行**：无行维度表，直接拉取事实表字段（store_region / store_type / shop_code 等），天然实现行维度分组和筛选，DAX 无需显式处理
- **列**：`Dim_ColMetric_Fulfillment_PB_Location` 的两级层级 `KPIGroup`（父）> `ColName`（子）
  - 11 个 KPI 分组：Fulfillment% / Request Order / Shipped Order / Unfulfillment% / Unfulfilled Order / Rejected Order / Cancelled Order by Overdue / Cancelled Order by Customer / Others / Failed Request / Inventory
  - 共 46 列指标
- **值**：SWITCH 动态路由，按 `Metric_ID` × `ColType` 分发到 Act / LY / vs LY（或 Orders / Reject% 等组内列类型）
- **口径**：一切以口径文档 PB Location.md 子模块五从 6. Fulfillment% 起的口径为准
- **筛选器**：
  - Slicer_Time_Frame_Min/Max（断开维度，筛选 data_date）
  - Slicer_Currency_Selection（断开维度，仅金额类指标 ÷ 汇率）

### 1.1 关键特殊逻辑：库存期末取末日

口径文档明确要求（指标 27/28/29 Inventory）：
> 根据所选时间范围的期末库存，即统计结束时间的期末库存数量，需要根据筛选日期，只要最后一天的数据。

因此 Inventory 分组（Metric_ID 44/45/46）在 Act 与 LY 的聚合上：
- 不使用 `[data_date] >= __TimeMin AND [data_date] <= __TimeMax` 的区间 SUM
- 而是取 `__TimeMax`（本期末日）或 `__LYTimeMax`（去年同期末日）当天的 SUM

---

## 2. 现状分析

### 2.1 数据底表

| 对象 | 名称 | 出处 |
|------|------|------|
| 事实表 | a02_e2e_boss_performance_summary_d | PB Location.md 全局逻辑 |
| 关键字段 | data_date, store_region, store_type, shop_code, calc_type, o2o_fulfillment_shipped_order_cnt, o2o_fulfillment_request_order_cnt, o2o_fulfillment_request_qty, o2o_fulfillment_request_sales_amt, o2o_fulfillment_shipped_qty, o2o_fulfillment_shipped_sales_amt, o2o_fulfillment_unshipped_order_cnt, o2o_fulfillment_unshipped_qty, o2o_fulfillment_unshipped_sales_amt, o2o_fulfillment_unshipped_store_rejected_order_cnt, o2o_fulfillment_unshipped_overdue_order_cnt, o2o_fulfillment_unshipped_customer_cancelled_order_cnt, o2o_fulfillment_unshipped_others_order_cnt, o2o_fulfillment_request_failed_times, o2o_fulfillment_request_times, stock_qty, bsr_stock_qty, seasonal_stock_qty | PB Location.md 子模块五 6-29 |

### 2.2 维度表清单

| 维度表 | 类型 | 连接方式 |
|--------|------|---------|
| Slicer_Time_Frame_Min | 断开维度 | SELECTEDVALUE 读取 TimeFrame_Min / TimeFrame_Min_LY |
| Slicer_Time_Frame_Max | 断开维度 | SELECTEDVALUE 读取 TimeFrame_Max / TimeFrame_Max_LY |
| Slicer_Currency_Selection | 断开维度 | SELECTEDVALUE 读取 Currency_ExchangeRate / Currency_Symbol |
| Dim_ColMetric_Fulfillment_PB_Location | 断开维度 | SELECTEDVALUE 读取 Metric_ID / ColType / Metric_Format_* |

> 不使用行维度表，行字段直接拉取事实表字段。calc_type 在 Fulfillment 分组下固定为 "fulfillment"，直接硬编码。

---

## 3. 方案设计

### 3.1 整体架构

```
核心思路：断开列维度 + SWITCH 动态路由（Disconnected Dimension + Dispatch Pattern）

Dim_ColMetric_Fulfillment_PB_Location（断开维度，列头）
    │
    │  无关系连接，仅通过 SELECTEDVALUE 读取：
    │  - Metric_ID, ColType, KPIGroup, ColName
    │  - Metric_Format_Act/LY/VsLY, Metric_IsCurrencyAmount
    │
    ▼
    ┌─────────────────────────── Matrix 视觉对象 ──────────────────────────┐
    │  行 = 事实表字段（store_region / store_type / shop_code 等，直接拉取）│
    │  列 = 'Dim_ColMetric_Fulfillment_PB_Location'[KPIGroup]              │
    │        > 'Dim_ColMetric_Fulfillment_PB_Location'[ColName]            │
    │  值 = [Fulfillment PB Location Cell Display]                        │
    └────────────────────────────────────────────────────────────────────────┘
                                   ▲
                                   │
              SWITCH 动态路由度量值链（按 Metric_ID 分发）
              ┌────────────────────────────────────────────────────┐
              │  [Fulfillment PB Location Cell Value]               │
              │    └→ [Fulfillment PB Location Base Value]（总路由）│
              │         ├→ [Fulfillment PB Location Act Base Value]│
              │         ├→ [Fulfillment PB Location LY Base Value] │
              │         └→ vs LY 派生（金额/数量类：今年/去年-1，  │
              │            比率类：今年-去年）                      │
              │         注：Inventory 分组（44/45/46）Act/LY 直接   │
              │            路由到末日聚合值，无 vs LY 派生          │
              └────────────────────────────────────────────────────┘
```

### 3.2 度量值模型设计

```
[Fulfillment PB Location Act Base Value]  ← 本期基础值（区间 SUM，除 Inventory 外）
                                            ← Inventory（44/45/46）本期末日 SUM
[Fulfillment PB Location LY Base Value]   ← 去年同期基础值（财历映射，区间 SUM，除 Inventory 外）
                                            ← Inventory（44/45/46）去年同期末日 SUM
[Fulfillment PB Location Base Value]      ← 总路由（含 vs LY 派生）
                                            ← 总路由使用 REMOVEFILTERS 清除断开维度筛选，再应用目标 Metric_ID
                                            ← Inventory 分组无 vs LY，直接返回 Act/LY
[Fulfillment PB Location Cell Value]      ← 对外值 = Base Value
[Fulfillment PB Location Cell Display]    ← 格式化显示文本
[Fulfillment PB Location Cell Font Color] ← 字体颜色（KPIGroup 行 vs KPI 行 × vs LY 列 vs 其他列）
[Fulfillment PB Location Cell Background Color] ← 背景色
[Fulfillment PB Location Cell SVG Icon]   ← SVG 图标（仅 vs LY 列 + KPI 行）
```

### 3.3 筛选器上下文

| 筛选器 | 作用方式 | DAX 处理 |
|--------|---------|---------|
| Slicer_Time_Frame_Min | 断开维度，SELECTEDVALUE 读取 TimeFrame_Min | `data_date >= __TimeMin`（区间指标） |
| Slicer_Time_Frame_Max | 断开维度，SELECTEDVALUE 读取 TimeFrame_Max | `data_date <= __TimeMax`（区间指标）；`data_date = __TimeMax`（Inventory 末日） |
| Slicer_Currency_Selection | 断开维度，SELECTEDVALUE 读取 Currency_ExchangeRate, Currency_Symbol | 金额类指标 ÷ Currency_ExchangeRate |
| 事实表分组字段 | 表格行/列直接拉取，模型自动传递筛选 | DAX 无需显式处理 |

> calc_type 在 Fulfillment 分组下固定为 "fulfillment"，直接硬编码。

### 3.4 vs LY 时间偏移规则（财历映射）

直接读取日期表内置 LY 字段：
- 全局 LY 起始日：`Slicer_Time_Frame_Min[TimeFrame_Min_LY]`
- 全局 LY 结束日：`Slicer_Time_Frame_Max[TimeFrame_Max_LY]`
- Inventory LY 末日：`Slicer_Time_Frame_Max[TimeFrame_Max_LY]`
- 无需 EDATE -12 或 Key 偏移计算

### 3.5 vs LY 派生计算分类

| KPI 分类 | vs LY 计算方式 | Metric_Format_VsLY | 展示示例 |
|---------|---------------|-------------------|---------|
| 数量类（Request Order Qty/Units、Shipped Order Qty/Units、Unfulfilled Order Qty/Units、Rejected Order、Cancelled Order ×3、Failed Request） | 今年 / 去年 − 1 | percent_1dp | 14.5% |
| 金额类（Request Order Amt、Shipped Order Amt、Unfulfilled Amt） | 今年 / 去年 − 1 | percent_1dp | 14.5% |
| 比率类（Fulfillment%、Unfulfillment%、Rejected%、Overdue%、Customer%、Others%、Failed%） | 今年 − 去年（差值，×10000 转 bp） | delta_bp | +120bp |

> Inventory 分组（44/45/46）只含 Total/BSR/Seasonal 三列，无 LY 与 vs LY 列，不需要派生计算。

### 3.6 格式规范

| 格式类型 | 格式串 | 示例 | 适用度量 |
|---------|--------|------|---------|
| integer | `#,##0` | 1,234 | 所有数量类 Act、LY |
| currency | `__CurrencySymbol & FORMAT(__Value, "#,##0")` | ¥1,234 | Request Order Amt / Shipped Order Amt / Unfulfilled Amt 的 Act、LY |
| percent_1dp | `#,##0.0%` | 14.5% | 比率类 Act、LY；数量/金额类 vs LY |
| delta_bp | `IF(ROUND(__Value*10000,0)>0,"+","") & FORMAT(__Value*10000, "#,##0bp;-#,##0bp;0bp")` | +120bp | 比率类 vs LY |

---

## 4. 度量值实现

### 4.1 Dim_ColMetric_Fulfillment_PB_Location（列指标维度表）

> 维度表已存在于 `Dim_ColMetric_Fulfillment_PB_Location.md`，此处不再重复定义，直接引用。下文明晰映射关系：

| Metric_ID | KPIGroup | ColName | ColType | 口径文档对应指标 | Act 字段 | LY 字段 |
|-----------|----------|---------|---------|-----------------|---------|---------|
| 1 | Fulfillment% | 1-Act | Act | 6. Fulfillment%（本期） | o2o_fulfillment_shipped_order_cnt / o2o_fulfillment_request_order_cnt | — |
| 2 | Fulfillment% | 2-LY | LY | 6.1 Fulfillment% LY | — | 同上（LY 区间） |
| 3 | Fulfillment% | 3-vs LY | vs LY | 6.2 Fulfillment% vs LY | — | — |
| 4-6 | Request Order | 4-Orders / 5-LY / 6-vs LY | Orders/LY/vs LY | 7. Request Order Qty | o2o_fulfillment_request_order_cnt | — |
| 7-9 | Request Order | 7-Units / 8-LY / 9-vs LY | Units/LY/vs LY | 8. Request Units | o2o_fulfillment_request_qty | — |
| 10-12 | Request Order | 10-Amt / 11-LY / 12-vs LY | Amt/LY/vs LY | 9. Request Order Amt | o2o_fulfillment_request_sales_amt | — |
| 13-15 | Shipped Order | 13-Orders / 14-LY / 15-vs LY | Orders/LY/vs LY | 10. Shipped Order Qty | o2o_fulfillment_shipped_order_cnt | — |
| 16-18 | Shipped Order | 16-Units / 17-LY / 18-vs LY | Units/LY/vs LY | 11. Shipped Units | o2o_fulfillment_shipped_qty | — |
| 19-21 | Shipped Order | 19-Amt / 20-LY / 21-vs LY | Amt/LY/vs LY | 12. Shipped Order Amt | o2o_fulfillment_shipped_sales_amt | — |
| 22-24 | Unfulfillment% | 22-Act / 23-LY / 24-vs LY | Act/LY/vs LY | 13. Unfulfillment% | o2o_fulfillment_unshipped_order_cnt / o2o_fulfillment_request_order_cnt | — |
| 25-27 | Unfulfilled Order | 25-Orders / 26-LY / 27-vs LY | Orders/LY/vs LY | 14. Unfulfilled Order | o2o_fulfillment_unshipped_order_cnt | — |
| 28-30 | Unfulfilled Order | 28-Units / 29-LY / 30-vs LY | Units/LY/vs LY | 15. Unfulfilled Units | o2o_fulfillment_unshipped_qty | — |
| 31-33 | Unfulfilled Order | 31-Amt / 32-LY / 33-vs LY | Amt/LY/vs LY | 16. Unfulfilled Amt | o2o_fulfillment_unshipped_sales_amt | — |
| 34 | Rejected Order | 34-Orders | Orders | 17. Rejected Order | o2o_fulfillment_unshipped_store_rejected_order_cnt | — |
| 35 | Rejected Order | 35-Reject% | Reject% | 18. Rejected% | o2o_fulfillment_unshipped_store_rejected_order_cnt / o2o_fulfillment_request_order_cnt | — |
| 36 | Cancelled Order by Overdue | 36-Orders | Orders | 19. Cancelled Order by Overdue | o2o_fulfillment_unshipped_overdue_order_cnt | — |
| 37 | Cancelled Order by Overdue | 37-Overdue% | Overdue% | 20. Overdue% | o2o_fulfillment_unshipped_overdue_order_cnt / o2o_fulfillment_request_order_cnt | — |
| 38 | Cancelled Order by Customer | 38-Orders | Orders | 21. Cancelled Order by Customer | o2o_fulfillment_unshipped_customer_cancelled_order_cnt | — |
| 39 | Cancelled Order by Customer | 39-Customer% | Customer% | 22. Customer% | o2o_fulfillment_unshipped_customer_cancelled_order_cnt / o2o_fulfillment_request_order_cnt | — |
| 40 | Others | 40-Orders | Orders | 23. Cancelled Order by Other | o2o_fulfillment_unshipped_others_order_cnt | — |
| 41 | Others | 41-Others% | Others% | 24. Other% | o2o_fulfillment_unshipped_others_order_cnt / o2o_fulfillment_request_order_cnt | — |
| 42 | Failed Request | 42-Request | Request | 25. Failed Request | o2o_fulfillment_request_failed_times | — |
| 43 | Failed Request | 43-Failed% | Failed% | 26. Failed% | o2o_fulfillment_request_failed_times / o2o_fulfillment_request_times | — |
| 44 | Inventory | 44-Total | Total | 27. Inventory | stock_qty（末日） | — |
| 45 | Inventory | 45-BSR | BSR | 28. BSR Inventory | bsr_stock_qty（末日） | — |
| 46 | Inventory | 46-Seasonal | Seasonal | 29. Seasonal Inventory | seasonal_stock_qty（末日） | — |

> 注：Rejected/Overdue/Customer/Others/Failed 分组只有 Orders+率 两列，无 LY/vs LY 列；Inventory 分组只有 Total/BSR/Seasonal 三列，无 LY/vs LY 列。这些组在总路由中直接返回 Act 值，不进入 vs LY 派生分支。

### 4.2 Fulfillment PB Location Act Base Value（本期基础值）

```dax
Fulfillment PB Location Act Base Value = 
// ========================================
// 度量值: Fulfillment PB Location Act Base Value
// Display Folder: Base Metrics
// 用途: 根据 Metric_ID 路由到本期（Act）基础值
// 依赖: 'Dim_ColMetric_Fulfillment_PB_Location'[Metric_ID, Metric_IsCurrencyAmount],
//       a02_e2e_boss_performance_summary_d
// 口径来源: PB Location.md 子模块五 - 从 6. Fulfillment% 起的本期值
// 筛选上下文:
//   - calc_type = "fulfillment"（硬编码，Fulfillment 分组固定）
//   - data_date ∈ [__TimeMin, __TimeMax]（全局时间范围，区间 SUM）
//   - Inventory 分组（Metric_ID 44/45/46）特殊处理：data_date = __TimeMax（末日 SUM）
//   - 金额类指标（Metric_IsCurrencyAmount=TRUE）÷ __FXRate（汇率）
// ========================================
    VAR __MetricID = SELECTEDVALUE('Dim_ColMetric_Fulfillment_PB_Location'[Metric_ID])
    VAR __IsCurrencyAmount = SELECTEDVALUE('Dim_ColMetric_Fulfillment_PB_Location'[Metric_IsCurrencyAmount], FALSE)
    // ── 时间筛选：本期 ──
    VAR __TimeMin = SELECTEDVALUE(Slicer_Time_Frame_Min[TimeFrame_Min])
    VAR __TimeMax = SELECTEDVALUE(Slicer_Time_Frame_Max[TimeFrame_Max])
    // ── 汇率（金额类指标需要除以汇率）──
    VAR __FXRate = SELECTEDVALUE(Slicer_Currency_Selection[Currency_ExchangeRate], 1)

    // ═══════════════════════════════════════
    // 基础聚合：calc_type = "fulfillment"（本期区间 SUM）
    // ═══════════════════════════════════════
    // 分子分母字段（区间聚合，用于多次复用）
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
    VAR __StoreRejectedOrderCnt_Act =
        CALCULATE(
            SUM('a02_e2e_boss_performance_summary_d'[o2o_fulfillment_unshipped_store_rejected_order_cnt]),
            'a02_e2e_boss_performance_summary_d'[calc_type] = "fulfillment",
            'a02_e2e_boss_performance_summary_d'[data_date] >= __TimeMin,
            'a02_e2e_boss_performance_summary_d'[data_date] <= __TimeMax
        )
    VAR __OverdueOrderCnt_Act =
        CALCULATE(
            SUM('a02_e2e_boss_performance_summary_d'[o2o_fulfillment_unshipped_overdue_order_cnt]),
            'a02_e2e_boss_performance_summary_d'[calc_type] = "fulfillment",
            'a02_e2e_boss_performance_summary_d'[data_date] >= __TimeMin,
            'a02_e2e_boss_performance_summary_d'[data_date] <= __TimeMax
        )
    VAR __CustomerCancelledOrderCnt_Act =
        CALCULATE(
            SUM('a02_e2e_boss_performance_summary_d'[o2o_fulfillment_unshipped_customer_cancelled_order_cnt]),
            'a02_e2e_boss_performance_summary_d'[calc_type] = "fulfillment",
            'a02_e2e_boss_performance_summary_d'[data_date] >= __TimeMin,
            'a02_e2e_boss_performance_summary_d'[data_date] <= __TimeMax
        )
    VAR __OthersOrderCnt_Act =
        CALCULATE(
            SUM('a02_e2e_boss_performance_summary_d'[o2o_fulfillment_unshipped_others_order_cnt]),
            'a02_e2e_boss_performance_summary_d'[calc_type] = "fulfillment",
            'a02_e2e_boss_performance_summary_d'[data_date] >= __TimeMin,
            'a02_e2e_boss_performance_summary_d'[data_date] <= __TimeMax
        )
    VAR __RequestFailedTimes_Act =
        CALCULATE(
            SUM('a02_e2e_boss_fulfillment_request_data_d'[o2o_fulfillment_request_failed_times]),
            'a02_e2e_boss_fulfillment_request_data_d'[calc_type] = "fulfillment",
            'a02_e2e_boss_fulfillment_request_data_d'[data_date] >= __TimeMin,
            'a02_e2e_boss_fulfillment_request_data_d'[data_date] <= __TimeMax
        )
    VAR __RequestTimes_Act =
        CALCULATE(
            SUM('a02_e2e_boss_fulfillment_request_data_d'[o2o_fulfillment_request_times]),
            'a02_e2e_boss_fulfillment_request_data_d'[calc_type] = "fulfillment",
            'a02_e2e_boss_fulfillment_request_data_d'[data_date] >= __TimeMin,
            'a02_e2e_boss_fulfillment_request_data_d'[data_date] <= __TimeMax
        )

    // ═══════════════════════════════════════
    // 库存期末取末日聚合（Metric_ID 44/45/46）
    // 口径：根据所选时间范围的期末库存，即统计结束时间的期末库存数量，
    //       需要根据筛选日期，只要最后一天的数据。
    // ═══════════════════════════════════════
    VAR __StockQty_Act =
        CALCULATE(
            SUM('a02_e2e_boss_performance_summary_d'[stock_qty]),
            'a02_e2e_boss_performance_summary_d'[calc_type] = "fulfillment",
            'a02_e2e_boss_performance_summary_d'[data_date] = __TimeMax
        )
    VAR __BsrStockQty_Act =
        CALCULATE(
            SUM('a02_e2e_boss_performance_summary_d'[bsr_stock_qty]),
            'a02_e2e_boss_performance_summary_d'[calc_type] = "fulfillment",
            'a02_e2e_boss_performance_summary_d'[data_date] = __TimeMax
        )
    VAR __SeasonalStockQty_Act =
        CALCULATE(
            SUM('a02_e2e_boss_performance_summary_d'[seasonal_stock_qty]),
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
            // ── Fulfillment% 分组 ──
            1,  DIVIDE(__ShippedOrderCnt_Act, __RequestOrderCnt_Act),                                    // Fulfillment% Act
            // ── Request Order 分组 ──
            4,  __RequestOrderCnt_Act,                                                                    // Request Order Qty Act
            7,  __RequestQty_Act,                                                                         // Request Units Act
            10, IF(__IsCurrencyAmount, DIVIDE(__RequestSalesAmt_Act, __FXRate), __RequestSalesAmt_Act),  // Request Order Amt Act
            // ── Shipped Order 分组 ──
            13, __ShippedOrderCnt_Act,                                                                    // Shipped Order Qty Act
            16, __ShippedQty_Act,                                                                         // Shipped Units Act
            19, IF(__IsCurrencyAmount, DIVIDE(__ShippedSalesAmt_Act, __FXRate), __ShippedSalesAmt_Act),  // Shipped Order Amt Act
            // ── Unfulfillment% 分组 ──
            22, DIVIDE(__UnshippedOrderCnt_Act, __RequestOrderCnt_Act),                                  // Unfulfillment% Act
            // ── Unfulfilled Order 分组 ──
            25, __UnshippedOrderCnt_Act,                                                                  // Unfulfilled Order Qty Act
            28, __UnshippedQty_Act,                                                                       // Unfulfilled Units Act
            31, IF(__IsCurrencyAmount, DIVIDE(__UnshippedSalesAmt_Act, __FXRate), __UnshippedSalesAmt_Act), // Unfulfilled Amt Act
            // ── Rejected Order 分组 ──
            34, __StoreRejectedOrderCnt_Act,                                                              // Rejected Order Act
            35, DIVIDE(__StoreRejectedOrderCnt_Act, __RequestOrderCnt_Act),                              // Rejected% Act
            // ── Cancelled Order by Overdue 分组 ──
            36, __OverdueOrderCnt_Act,                                                                    // Cancelled Order by Overdue Act
            37, DIVIDE(__OverdueOrderCnt_Act, __RequestOrderCnt_Act),                                    // Overdue% Act
            // ── Cancelled Order by Customer 分组 ──
            38, __CustomerCancelledOrderCnt_Act,                                                         // Cancelled Order by Customer Act
            39, DIVIDE(__CustomerCancelledOrderCnt_Act, __RequestOrderCnt_Act),                          // Customer% Act
            // ── Others 分组 ──
            40, __OthersOrderCnt_Act,                                                                     // Others Act
            41, DIVIDE(__OthersOrderCnt_Act, __RequestOrderCnt_Act),                                     // Others% Act
            // ── Failed Request 分组 ──
            42, __RequestFailedTimes_Act,                                                                 // Failed Request Act
            43, DIVIDE(__RequestFailedTimes_Act, __RequestTimes_Act),                                    // Failed% Act
            // ── Inventory 分组（期末取末日）──
            44, __StockQty_Act,                                                                           // Inventory Total Act
            45, __BsrStockQty_Act,                                                                        // Inventory BSR Act
            46, __SeasonalStockQty_Act,                                                                   // Inventory Seasonal Act
            BLANK()
        )
```

### 4.3 Fulfillment PB Location LY Base Value（去年同期基础值，财历映射）

```dax
Fulfillment PB Location LY Base Value = 
// ========================================
// 度量值: Fulfillment PB Location LY Base Value
// Display Folder: Base Metrics
// 用途: 根据 Metric_ID 路由到去年同期（LY）基础值
// 依赖: 'Dim_ColMetric_Fulfillment_PB_Location'[Metric_ID, Metric_IsCurrencyAmount],
//       Slicer_Time_Frame_Min/Max[TimeFrame_Min_LY, TimeFrame_Max_LY],
//       a02_e2e_boss_performance_summary_d
// 口径来源: PB Location.md 子模块五 - 从 6. Fulfillment% 起的 LY 值
// 时间偏移: 财历映射（直接读取日期表内置 LY 字段）
//   - 全局 LY 起始日: SELECTEDVALUE(Slicer_Time_Frame_Min[TimeFrame_Min_LY])
//   - 全局 LY 结束日: SELECTEDVALUE(Slicer_Time_Frame_Max[TimeFrame_Max_LY])
//   - Inventory 分组 LY 末日: SELECTEDVALUE(Slicer_Time_Frame_Max[TimeFrame_Max_LY])
//   - 无需 EDATE -12 或 Key 偏移计算
// 金额类指标 ÷ __FXRate（汇率换算）
// 注：Rejected/Overdue/Customer/Others/Failed/Inventory 分组无 LY 列，返回 BLANK
// ========================================
    VAR __MetricID = SELECTEDVALUE('Dim_ColMetric_Fulfillment_PB_Location'[Metric_ID])
    VAR __IsCurrencyAmount = SELECTEDVALUE('Dim_ColMetric_Fulfillment_PB_Location'[Metric_IsCurrencyAmount], FALSE)
    // ── 直接读取日期表内置的 LY 时间范围 ──
    VAR __LYTimeMin = SELECTEDVALUE(Slicer_Time_Frame_Min[TimeFrame_Min_LY])
    VAR __LYTimeMax = SELECTEDVALUE(Slicer_Time_Frame_Max[TimeFrame_Max_LY])
    // ── 汇率 ──
    VAR __FXRate = SELECTEDVALUE(Slicer_Currency_Selection[Currency_ExchangeRate], 1)

    // ═══════════════════════════════════════
    // 基础聚合：calc_type = "fulfillment"（去年同期区间 SUM）
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
    // 库存期末取末日聚合（LY 末日 = TimeFrame_Max_LY）
    // 注：当前列指标维度表 Inventory 分组只设计了 Total/BSR/Seasonal 三列，
    //     没有 LY 列，因此以下三个 LY 末日变量仅作预留，不会进入路由分发。
    // ═══════════════════════════════════════
    VAR __StockQty_LY =
        CALCULATE(
            SUM('a02_e2e_boss_performance_summary_d'[stock_qty]),
            'a02_e2e_boss_performance_summary_d'[calc_type] = "fulfillment",
            'a02_e2e_boss_performance_summary_d'[data_date] = __LYTimeMax
        )
    VAR __BsrStockQty_LY =
        CALCULATE(
            SUM('a02_e2e_boss_performance_summary_d'[bsr_stock_qty]),
            'a02_e2e_boss_performance_summary_d'[calc_type] = "fulfillment",
            'a02_e2e_boss_performance_summary_d'[data_date] = __LYTimeMax
        )
    VAR __SeasonalStockQty_LY =
        CALCULATE(
            SUM('a02_e2e_boss_performance_summary_d'[seasonal_stock_qty]),
            'a02_e2e_boss_performance_summary_d'[calc_type] = "fulfillment",
            'a02_e2e_boss_performance_summary_d'[data_date] = __LYTimeMax
        )

    // ═══════════════════════════════════════
    // 路由分发（按 Metric_ID）
    // 金额类指标 ÷ __FXRate（汇率换算）
    // ═══════════════════════════════════════
    RETURN
        SWITCH(
            __MetricID,
            // ── Fulfillment% 分组 ──
            2,  DIVIDE(__ShippedOrderCnt_LY, __RequestOrderCnt_LY),                                      // Fulfillment% LY
            // ── Request Order 分组 ──
            5,  __RequestOrderCnt_LY,                                                                     // Request Order Qty LY
            8,  __RequestQty_LY,                                                                          // Request Units LY
            11, IF(__IsCurrencyAmount, DIVIDE(__RequestSalesAmt_LY, __FXRate), __RequestSalesAmt_LY),    // Request Order Amt LY
            // ── Shipped Order 分组 ──
            14, __ShippedOrderCnt_LY,                                                                     // Shipped Order Qty LY
            17, __ShippedQty_LY,                                                                          // Shipped Units LY
            20, IF(__IsCurrencyAmount, DIVIDE(__ShippedSalesAmt_LY, __FXRate), __ShippedSalesAmt_LY),    // Shipped Order Amt LY
            // ── Unfulfillment% 分组 ──
            23, DIVIDE(__UnshippedOrderCnt_LY, __RequestOrderCnt_LY),                                    // Unfulfillment% LY
            // ── Unfulfilled Order 分组 ──
            26, __UnshippedOrderCnt_LY,                                                                   // Unfulfilled Order Qty LY
            29, __UnshippedQty_LY,                                                                        // Unfulfilled Units LY
            32, IF(__IsCurrencyAmount, DIVIDE(__UnshippedSalesAmt_LY, __FXRate), __UnshippedSalesAmt_LY), // Unfulfilled Amt LY
            // ── 其他分组（Rejected/Overdue/Customer/Others/Failed/Inventory）无 LY 列 ──
            BLANK()
        )
```

### 4.4 Fulfillment PB Location Base Value（总路由）

```dax
Fulfillment PB Location Base Value = 
// ========================================
// 度量值: Fulfillment PB Location Base Value
// Display Folder: Base Metrics
// 用途: 总路由，根据 Metric_ID 分发到 Act / LY / vs LY
// 依赖: [Fulfillment PB Location Act Base Value], [Fulfillment PB Location LY Base Value],
//       'Dim_ColMetric_Fulfillment_PB_Location'[Metric_ID, Metric_Format_VsLY]
// 说明:
//   有 LY/vs LY 的分组（9 个 KPI 分组）：
//     Fulfillment% / Request Order / Shipped Order / Unfulfillment% / Unfulfilled Order
//     Metric_ID 路由规则：
//       - Act  列：Metric_ID ∈ {1,4,7,10,13,16,19,22,25,28,31}
//       - LY   列：Metric_ID ∈ {2,5,8,11,14,17,20,23,26,29,32}
//       - vs LY列：Metric_ID ∈ {3,6,9,12,15,18,21,24,27,30,33}
//     vs LY 行的 Act 对应 Metric_ID - 2，LY 对应 Metric_ID - 1
//   无 LY/vs LY 的分组（6 个 KPI 分组）：
//     Rejected Order / Cancelled Order by Overdue / Cancelled Order by Customer /
//     Others / Failed Request / Inventory
//     Metric_ID ∈ {34,35,36,37,38,39,40,41,42,43,44,45,46} 直接返回 Act 值
//
// vs LY 派生规则:
//   - 数量类/金额类：今年 / 去年 − 1（percent_1dp）
//   - 比率类（Fulfillment% / Unfulfillment%）：今年 − 去年（差值，展示时 ×10000 转 bp）
//
// REMOVEFILTERS 机制（参考 PB_Location_Sales_detail_ms.md）:
//   矩阵行标题会保留断开维度的所有列筛选器，
//   仅覆盖 Metric_ID 会导致筛选条件冲突（如 Metric_ID=3 AND ColName="vs LY"）从而返回 BLANK。
//   因此 vs LY 行需先 REMOVEFILTERS 清除断开维度的所有筛选，再应用目标 Metric_ID。
// ========================================
    VAR __MetricID = SELECTEDVALUE('Dim_ColMetric_Fulfillment_PB_Location'[Metric_ID])
    VAR __FormatVsLY = SELECTEDVALUE('Dim_ColMetric_Fulfillment_PB_Location'[Metric_Format_VsLY])
    // 判断当前是否为 vs LY 行（仅 9 个有 vs LY 列的分组）
    VAR __IsVsLY = __MetricID IN {3, 6, 9, 12, 15, 18, 21, 24, 27, 30, 33}

    // 修复上下文冲突：vs LY 行需要取 Act 和 LY 的值做派生计算，
    // 但当前筛选上下文下 Metric_ID 指向 vs LY 行，
    // 直接调用 Act/LY 度量会因 Metric_ID 不匹配而返回 BLANK。
    // 解决方案：先 REMOVEFILTERS 清除断开维度的所有筛选，再应用目标 Metric_ID。
    VAR __ActValue = 
        IF(
            __IsVsLY,
            CALCULATE(
                [Fulfillment PB Location Act Base Value], 
                REMOVEFILTERS('Dim_ColMetric_Fulfillment_PB_Location'), 
                'Dim_ColMetric_Fulfillment_PB_Location'[Metric_ID] = __MetricID - 2
            ),
            [Fulfillment PB Location Act Base Value]
        )

    VAR __LYValue = 
        IF(
            __IsVsLY,
            CALCULATE(
                [Fulfillment PB Location LY Base Value], 
                REMOVEFILTERS('Dim_ColMetric_Fulfillment_PB_Location'), 
                'Dim_ColMetric_Fulfillment_PB_Location'[Metric_ID] = __MetricID - 1
            ),
            [Fulfillment PB Location LY Base Value]
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
            1,  __ActValue,     // Fulfillment% Act
            4,  __ActValue,     // Request Order Qty Act
            7,  __ActValue,     // Request Units Act
            10, __ActValue,     // Request Order Amt Act
            13, __ActValue,     // Shipped Order Qty Act
            16, __ActValue,     // Shipped Units Act
            19, __ActValue,     // Shipped Order Amt Act
            22, __ActValue,     // Unfulfillment% Act
            25, __ActValue,     // Unfulfilled Order Qty Act
            28, __ActValue,     // Unfulfilled Units Act
            31, __ActValue,     // Unfulfilled Amt Act
            // ─── 无 LY/vs LY 分组直接返回 Act 值 ───
            34, __ActValue,     // Rejected Order Act
            35, __ActValue,     // Rejected% Act
            36, __ActValue,     // Cancelled Order by Overdue Act
            37, __ActValue,     // Overdue% Act
            38, __ActValue,     // Cancelled Order by Customer Act
            39, __ActValue,     // Customer% Act
            40, __ActValue,     // Others Act
            41, __ActValue,     // Others% Act
            42, __ActValue,     // Failed Request Act
            43, __ActValue,     // Failed% Act
            44, __ActValue,     // Inventory Total Act
            45, __ActValue,     // Inventory BSR Act
            46, __ActValue,     // Inventory Seasonal Act
            // ─── LY 去年同期值 ───
            2,  __LYValue,      // Fulfillment% LY
            5,  __LYValue,      // Request Order Qty LY
            8,  __LYValue,      // Request Units LY
            11, __LYValue,      // Request Order Amt LY
            14, __LYValue,      // Shipped Order Qty LY
            17, __LYValue,      // Shipped Units LY
            20, __LYValue,      // Shipped Order Amt LY
            23, __LYValue,      // Unfulfillment% LY
            26, __LYValue,      // Unfulfilled Order Qty LY
            29, __LYValue,      // Unfulfilled Units LY
            32, __LYValue,      // Unfulfilled Amt LY
            // ─── vs LY 派生值 ───
            3,  __VSLYDiff,     // Fulfillment% vs LY（delta_bp，差值）
            6,  __VSLYGrowth,   // Request Order Qty vs LY（percent_1dp）
            9,  __VSLYGrowth,   // Request Units vs LY（percent_1dp）
            12, __VSLYGrowth,   // Request Order Amt vs LY（percent_1dp）
            15, __VSLYGrowth,   // Shipped Order Qty vs LY（percent_1dp）
            18, __VSLYGrowth,   // Shipped Units vs LY（percent_1dp）
            21, __VSLYGrowth,   // Shipped Order Amt vs LY（percent_1dp）
            24, __VSLYDiff,     // Unfulfillment% vs LY（delta_bp，差值）
            27, __VSLYGrowth,   // Unfulfilled Order Qty vs LY（percent_1dp）
            30, __VSLYGrowth,   // Unfulfilled Units vs LY（percent_1dp）
            33, __VSLYGrowth,   // Unfulfilled Amt vs LY（percent_1dp）
            BLANK()
        )
```

### 4.5 Fulfillment PB Location Cell Value（对外值）

```dax
Fulfillment PB Location Cell Value = 
// ========================================
// 度量值: Fulfillment PB Location Cell Value
// Display Folder: Cell Values
// 用途: 对外暴露的单元格值，等于 Base Value
// 依赖: [Fulfillment PB Location Base Value]
// ========================================
    [Fulfillment PB Location Base Value]
```

### 4.6 Fulfillment PB Location Cell Display（格式化显示）

```dax
Fulfillment PB Location Cell Display = 
// ========================================
// 度量值: Fulfillment PB Location Cell Display
// Display Folder: Formatting
// 用途: 按 ColType 选择对应行格式格式化显示
// 依赖: [Fulfillment PB Location Cell Value],
//       'Dim_ColMetric_Fulfillment_PB_Location'[ColType, Metric_Format_Act/LY/VsLY]
// 格式类型:
//   integer    → 千分位整数：1,000
//   currency   → 货币符号 + 千分位整数：¥1,000
//   percent_1dp → 百分比一位小数，不含正号：14.5%
//   delta_bp   → 增减基点整数，含正负号：+120bp
//                （值×10000 转 bp 的操作在此处实现）
// 说明：
//   - 无 LY/vs LY 的分组（Rejected/Overdue/Customer/Others/Failed/Inventory）
//     ColType 不是 Act/LY/vs LY，而是 Orders/Reject%/Overdue%/Customer%/Others%/Failed%/Total/BSR/Seasonal 等
//     这些列类型均使用 Metric_Format_Act 格式（与 Act 一致），因此 SWITCH 中统一映射。
// ========================================
    VAR __Value = [Fulfillment PB Location Cell Value]
    VAR __ColType = SELECTEDVALUE('Dim_ColMetric_Fulfillment_PB_Location'[ColType])
    // ── 按 ColType 选择对应行格式 ──
    // 对于无 LY/vs LY 的分组，ColType 不是 Act/LY/vs LY，此时直接取 Metric_Format_Act
    VAR __Format =
        SWITCH(
            __ColType,
            "Act",   SELECTEDVALUE('Dim_ColMetric_Fulfillment_PB_Location'[Metric_Format_Act]),
            "LY",    SELECTEDVALUE('Dim_ColMetric_Fulfillment_PB_Location'[Metric_Format_LY]),
            "vs LY", SELECTEDVALUE('Dim_ColMetric_Fulfillment_PB_Location'[Metric_Format_VsLY]),
            // 无 LY/vs LY 分组的列类型，统一使用 Act 格式
            SELECTEDVALUE('Dim_ColMetric_Fulfillment_PB_Location'[Metric_Format_Act])
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
                // ─── 默认 ─────────────────────────────────
                FORMAT(__Value, "#,##0.00")
            )
        )
```

### 4.7 Fulfillment PB Location Cell Font Color（字体颜色）

```dax
Fulfillment PB Location Cell Font Color = 
// ========================================
// 度量值: Fulfillment PB Location Cell Font Color
// Display Folder: Formatting
// 用途: 区分 KPIGroup 行（分组标题行）与 KPI 行，并对 vs LY 列启用正/负/零三色
// 依赖: [Fulfillment PB Location Cell Value],
//       'Dim_ColMetric_Fulfillment_PB_Location'[ColType, Metric_ColorPositive/Negative/Zero/Default],
//       ISINSCOPE('Dim_ColMetric_Fulfillment_PB_Location'[ColName])
// 层级判断:
//   ISINSCOPE('Dim_ColMetric_Fulfillment_PB_Location'[ColName]) = TRUE  → KPI 行（具体指标行）
//   ISINSCOPE('Dim_ColMetric_Fulfillment_PB_Location'[ColName]) = FALSE → KPIGroup 行（分组标题行）
// 颜色规则:
//   ┌─────────────┬───────────────────┬──────────────────────────────────────┐
//   │             │  vs LY 列         │  其他列（Act / LY / Orders / 率等）  │
//   ├─────────────┼───────────────────┼──────────────────────────────────────┤
//   │  KPI 行     │  正#1A9018/负#D64550/零#E1C233/默认#5F6165  │  #5F6165（深灰）│
//   │  KPIGroup 行│  #252423（黑色）  │  #252423（黑色）                     │
//   └─────────────┴───────────────────┴──────────────────────────────────────┘
// ========================================
    VAR __Value = [Fulfillment PB Location Cell Value]
    VAR __ColType = SELECTEDVALUE('Dim_ColMetric_Fulfillment_PB_Location'[ColType])
    VAR __IsKPIRow = ISINSCOPE('Dim_ColMetric_Fulfillment_PB_Location'[ColName])
    // ── 颜色取值（来自列维度表）──
    VAR __ColorPositive = SELECTEDVALUE('Dim_ColMetric_Fulfillment_PB_Location'[Metric_ColorPositive], "#1A9018")
    VAR __ColorNegative = SELECTEDVALUE('Dim_ColMetric_Fulfillment_PB_Location'[Metric_ColorNegative], "#D64550")
    VAR __ColorZero = SELECTEDVALUE('Dim_ColMetric_Fulfillment_PB_Location'[Metric_ColorZero], "#E1C233")
    VAR __ColorDefault = SELECTEDVALUE('Dim_ColMetric_Fulfillment_PB_Location'[Metric_ColorDefault], "#5F6165")

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

### 4.8 Fulfillment PB Location Cell Background Color（背景色）

```dax
Fulfillment PB Location Cell Background Color = 
// ========================================
// 度量值: Fulfillment PB Location Cell Background Color
// Display Folder: Formatting
// 用途: 区分 KPIGroup 行（分组标题行）与 KPI 行的背景色
// 依赖: ISINSCOPE('Dim_ColMetric_Fulfillment_PB_Location'[ColName])
// 颜色规则:
//   KPIGroup 行（分组标题行）: #E6D9C7（中米色）
//   KPI 行（具体指标行）     : #FFFFFF（白色）
// ========================================
    VAR __IsKPIRow = ISINSCOPE('Dim_ColMetric_Fulfillment_PB_Location'[ColName])
    RETURN
        IF(
            __IsKPIRow,
            "#FFFFFF",   // KPI 行：白色
            "#E6D9C7"    // KPIGroup 行：中米色
        )
```

### 4.9 Fulfillment PB Location Cell SVG Icon（SVG 图标）

```dax
Fulfillment PB Location Cell SVG Icon = 
// ========================================
// 度量值: Fulfillment PB Location Cell SVG Icon
// Display Folder: Formatting
// 用途: 仅 vs LY 列 + KPI 行返回 SVG 圆形图标
// 依赖: [Fulfillment PB Location Cell Value],
//       'Dim_ColMetric_Fulfillment_PB_Location'[ColType, Metric_ColorPositive/Negative/Zero]
// 配置: 需将此度量值的数据类别设为"图像 URL"
// 图标规则:
//   ┌─────────────┬──────────────────────────────────────┐
//   │             │  vs LY 列                            │
//   ├─────────────┼──────────────────────────────────────┤
//   │  KPI 行     │  正→绿圆 / 负→红圆 / 零→黄圆         │
//   │  KPIGroup 行│  不显示（BLANK）                     │
//   └─────────────┴──────────────────────────────────────┘
//   其他列（Act / LY / Orders / 率等）：不显示（BLANK）
// 颜色与 Font Color 保持一致（取自 Dim_ColMetric_Fulfillment_PB_Location 的颜色字段）
// ========================================
    VAR __Value = [Fulfillment PB Location Cell Value]
    VAR __ColType = SELECTEDVALUE('Dim_ColMetric_Fulfillment_PB_Location'[ColType])
    VAR __IsKPIRow = ISINSCOPE('Dim_ColMetric_Fulfillment_PB_Location'[ColName])
    // ── 启用图标条件：vs LY 列 + KPI 行 ──
    VAR __NeedsIcon = __ColType = "vs LY" && __IsKPIRow
    // ── 颜色取值（来自列维度表）──
    VAR __ColorPositive = SELECTEDVALUE('Dim_ColMetric_Fulfillment_PB_Location'[Metric_ColorPositive], "#1A9018")
    VAR __ColorNegative = SELECTEDVALUE('Dim_ColMetric_Fulfillment_PB_Location'[Metric_ColorNegative], "#D64550")
    VAR __ColorZero = SELECTEDVALUE('Dim_ColMetric_Fulfillment_PB_Location'[Metric_ColorZero], "#E1C233")
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
| 1 | Fulfillment PB Location Act Base Value | Base Metrics | 本期基础值（区间 SUM；Inventory 末日 SUM） |
| 2 | Fulfillment PB Location LY Base Value | Base Metrics | 去年同期基础值（财历映射，区间 SUM；Inventory 末日 SUM） |
| 3 | Fulfillment PB Location Base Value | Base Metrics | 总路由（含 vs LY 派生 + REMOVEFILTERS） |
| 4 | Fulfillment PB Location Cell Value | Cell Values | 对外值 = Base Value |
| 5 | Fulfillment PB Location Cell Display | Formatting | 格式化显示文本 |
| 6 | Fulfillment PB Location Cell Font Color | Formatting | 字体颜色 |
| 7 | Fulfillment PB Location Cell Background Color | Formatting | 背景色 |
| 8 | Fulfillment PB Location Cell SVG Icon | Formatting | SVG 图标（仅 vs LY 列 + KPI 行） |

---

## 6. 血缘关系图

```
┌─────────────────────────────────────────────────────────────────────┐
│                        数据源层                                      │
│  a02_e2e_boss_performance_summary_d（事实表）                        │
│  字段: data_date, store_region, store_type, shop_code, calc_type,    │
│        o2o_fulfillment_shipped_order_cnt, o2o_fulfillment_request_   │
│        order_cnt, o2o_fulfillment_request_qty, o2o_fulfillment_      │
│        request_sales_amt, o2o_fulfillment_shipped_qty,               │
│        o2o_fulfillment_shipped_sales_amt,                            │
│        o2o_fulfillment_unshipped_order_cnt,                          │
│        o2o_fulfillment_unshipped_qty,                                │
│        o2o_fulfillment_unshipped_sales_amt,                          │
│        o2o_fulfillment_unshipped_store_rejected_order_cnt,           │
│        o2o_fulfillment_unshipped_overdue_order_cnt,                  │
│        o2o_fulfillment_unshipped_customer_cancelled_order_cnt,       │
│        o2o_fulfillment_unshipped_others_order_cnt,                   │
│        o2o_fulfillment_request_failed_times,                         │
│        o2o_fulfillment_request_times,                                │
│        stock_qty, bsr_stock_qty, seasonal_stock_qty                  │
└──────────────────────────────┬──────────────────────────────────────┘
                               │
                               │ 模型自动传递（行维度 = 事实表字段直接拉取）
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────────┐
│                        度量值层                                      │
│                                                                     │
│  ┌───────────────────────────────────┐   ┌───────────────────────┐  │
│  │ Fulfillment PB Location           │   │ Fulfillment PB        │  │
│  │ Act Base Value                    │   │ Location LY Base Value│  │
│  │ (本期，区间 SUM + Inventory 末日)  │   │ (LY, 财历映射,        │  │
│  └───────────────┬───────────────────┘   │  Inventory 末日)      │  │
│                  │                        └───────────┬───────────┘  │
│                  │    ┌───────────────────────────────┘              │
│                  │    │                                              │
│                  ▼    ▼                                              │
│  ┌───────────────────────────────────┐   ┌───────────────────────┐  │
│  │ Fulfillment PB Location           │   │ Dim_ColMetric_        │  │
│  │ Base Value                        │◄──│ Fulfillment_PB_       │  │
│  │ (总路由 + vs LY 派生)              │   │ Location              │  │
│  │ REMOVEFILTERS + 目标 Metric_ID     │   │ (断开维度, Metric_ID) │  │
│  │ Inventory 分组无 vs LY，直返 Act   │   └───────────────────────┘  │
│  └───────────────┬───────────────────┘                              │
│                  │                                                  │
│                  ▼                                                  │
│  ┌───────────────────────────────────┐                              │
│  │ Fulfillment PB Location           │                              │
│  │ Cell Value (= Base Value)         │                              │
│  └───────────────┬───────────────────┘                              │
│                  │                                                  │
│                  ▼                                                  │
│  ┌───────────────────────────────────┐   ┌───────────────────────┐  │
│  │ Fulfillment PB Location           │◄──│ Dim_ColMetric_        │  │
│  │ Cell Display (格式化文本)          │   │ Fulfillment_PB_       │  │
│  └───────────────┬───────────────────┘   │ Location              │  │
│                  │                        │ (ColType, Format_*)   │  │
│                  ▼                        └───────────────────────┘  │
│  ┌─────────────────────────────────────────────────────┐            │
│  │  Fulfillment PB Location Cell Font Color             │            │
│  │  Fulfillment PB Location Cell Background Color       │            │
│  │  Fulfillment PB Location Cell SVG Icon               │            │
│  │  (条件格式度量值，ISINSCOPE 判断 KPIGroup/KPI 行)     │            │
│  └─────────────────────────────────────────────────────┘            │
└─────────────────────────────────────────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────────┐
│                        可视化层                                      │
│  Matrix 视觉对象                                                     │
│  行: 事实表字段（store_region / store_type / shop_code 等，直接拉取）│
│  列: 'Dim_ColMetric_Fulfillment_PB_Location'[KPIGroup]               │
│      > 'Dim_ColMetric_Fulfillment_PB_Location'[ColName]              │
│  值: [Fulfillment PB Location Cell Display]                         │
│  条件格式:                                                           │
│    字体颜色 → [Fulfillment PB Location Cell Font Color]             │
│    背景色   → [Fulfillment PB Location Cell Background Color]       │
│    SVG 图标 → [Fulfillment PB Location Cell SVG Icon]（数据类别=图像URL）│
└─────────────────────────────────────────────────────────────────────┘
```

---

## 7. 矩阵视觉对象配置

### 7.1 字段配置

| 区域 | 字段 |
|------|------|
| **行** | 事实表字段（store_region / store_type / shop_code 等，直接拉取） |
| **列** | 'Dim_ColMetric_Fulfillment_PB_Location'[KPIGroup] > [ColName] |
| **值** | [Fulfillment PB Location Cell Display] |

### 7.2 排序配置

| 字段 | 排序依据 |
|------|---------|
| 'Dim_ColMetric_Fulfillment_PB_Location'[KPIGroup] | KPIGroup_Sort |
| 'Dim_ColMetric_Fulfillment_PB_Location'[ColName] | ColName_Sort |

### 7.3 格式设置

- 关闭"阶梯布局"（Stepped Layout → Off）
- 关闭"+/-"展开按钮
- 列标题：居中对齐，加粗
- 行标题：左对齐
- 值：居中对齐

### 7.4 条件格式

对 [Fulfillment PB Location Cell Display] 值区域设置：

1. **字体颜色**：右键值区域 → 条件格式 → 字体颜色 → 格式样式：字段值 → 基于字段：[Fulfillment PB Location Cell Font Color]
2. **背景颜色**：右键值区域 → 条件格式 → 背景颜色 → 格式样式：字段值 → 基于字段：[Fulfillment PB Location Cell Background Color]
3. **SVG 图标**（可选）：将 [Fulfillment PB Location Cell SVG Icon] 度量值的数据类别设为"图像 URL"

---

## 8. 验证方法

### 8.1 矩阵结构验证

| 验证项 | 方法 |
|--------|------|
| 列数 | 确认 46 列（11 KPI 分组：5 个 3 列 + 5 个 2 列 + 1 个 3 列） |
| 列排序 | KPIGroup 按 KPIGroup_Sort（10/20/.../110），ColName 按 ColName_Sort |
| 同名区分 | 确认各 KPI 同名 Act/LY/vs LY 在 ColName 中通过 Metric_ID 前缀区分 |
| KPIGroup 行颜色 | 字体黑色 #252423，背景中米色 #E6D9C7 |
| KPI 行颜色 | 非 vs LY 列字体深灰 #5F6165，背景白色 #FFFFFF；vs LY 列正/负/零三色 |
| SVG 图标 | 仅 vs LY 列 + KPI 行显示圆形图标 |

### 8.2 验证 SQL

```sql
-- Fulfillment% O2O订单履约率（本期，所有 store 汇总）
-- 假设 __TimeMin='2025-06-29', __TimeMax='2025-08-09'
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

-- Inventory Total（本期，期末取末日 = __TimeMax 当天）
SELECT SUM(stock_qty) AS Inventory_Total_Actual
FROM a02_e2e_boss_performance_summary_d
WHERE calc_type = 'fulfillment'
  AND data_date = '__TimeMax';   -- 仅取最后一天

-- BSR Inventory（本期，期末取末日）
SELECT SUM(bsr_stock_qty) AS BSR_Inventory_Actual
FROM a02_e2e_boss_performance_summary_d
WHERE calc_type = 'fulfillment'
  AND data_date = '__TimeMax';   -- 仅取最后一天

-- Seasonal Inventory（本期，期末取末日）
SELECT SUM(seasonal_stock_qty) AS Seasonal_Inventory_Actual
FROM a02_e2e_boss_performance_summary_d
WHERE calc_type = 'fulfillment'
  AND data_date = '__TimeMax';   -- 仅取最后一天

-- Rejected% O2O门店拒单率（本期）
SELECT
  SUM(o2o_fulfillment_unshipped_store_rejected_order_cnt) * 1.0
  / SUM(o2o_fulfillment_request_order_cnt) AS Rejected_Pct_Actual
FROM a02_e2e_boss_performance_summary_d
WHERE calc_type = 'fulfillment'
  AND data_date BETWEEN '__TimeMin' AND '__TimeMax';

-- Failed% O2O门店订单失败率（本期）
SELECT
  SUM(o2o_fulfillment_request_failed_times) * 1.0
  / SUM(o2o_fulfillment_request_times) AS Failed_Pct_Actual
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

1. **库存期末取末日（关键逻辑）**：Inventory 分组（Metric_ID 44/45/46）的 Act 与 LY 聚合不使用区间 SUM，而是分别取 `data_date = __TimeMax`（本期末日）和 `data_date = __LYTimeMax`（去年同期末日）当天的 SUM。此口径严格遵循 PB Location.md 指标 27/28/29 的要求：根据所选时间范围的期末库存，即统计结束时间的期末库存数量，需要根据筛选日期，只要最后一天的数据。

2. **REMOVEFILTERS 机制**：vs LY 行的派生计算必须先 `REMOVEFILTERS('Dim_ColMetric_Fulfillment_PB_Location')` 再应用目标 Metric_ID，否则矩阵行标题保留的筛选器会导致冲突返回 BLANK。这与 PB_Location_Sales_detail_ms.md 的总路由范式完全一致。

3. **Metric_ID 编码规则**：
   - 有 LY/vs LY 的分组：Act = 组内首 ID，LY = Act + 1，vs LY = Act + 2；vs LY 行的 Act 对应 Metric_ID - 2，LY 对应 Metric_ID - 1
   - 无 LY/vs LY 的分组（Rejected/Overdue/Customer/Others/Failed/Inventory）：Metric_ID 直接返回 Act 值，不进入 vs LY 派生分支

4. **calc_type 固定**：本方案所有度量值均硬编码 `calc_type = "fulfillment"`。

5. **LY 财历映射**：周/月/季/年粒度按财年定义，LY 采用财历映射（直接读取日期表内置 TimeFrame_Min_LY / TimeFrame_Max_LY 字段），不使用 EDATE -12。Inventory LY 末日 = `TimeFrame_Max_LY`。

6. **汇率换算**：金额类指标 ÷ Currency_ExchangeRate；比率类分子分母同币种相除自动抵消。vs LY 同比值因相除/相减自动抵消汇率影响。

7. **vs LY 派生分类**：
   - 数量类（Request Order Qty/Units、Shipped Order Qty/Units、Unfulfilled Order Qty/Units）：今年 / 去年 − 1 → percent_1dp
   - 金额类（Request Order Amt、Shipped Order Amt、Unfulfilled Amt）：今年 / 去年 − 1 → percent_1dp
   - 比率类（Fulfillment%、Unfulfillment%）：今年 − 去年 → delta_bp（展示时 ×10000 转 bp）

8. **无 LY/vs LY 分组的处理**：Rejected Order / Cancelled Order by Overdue / Cancelled Order by Customer / Others / Failed Request / Inventory 这 6 个分组在列指标维度表中只设计了 Orders+率（或 Total/BSR/Seasonal）两类列，没有 LY 和 vs LY 列。总路由中对这些 Metric_ID 直接返回 Act 值，Cell Display 中 ColType 非 Act/LY/vs LY 时统一使用 Metric_Format_Act 格式。

9. **行维度处理**：无行维度表，直接拉取事实表字段（store_region / store_type / shop_code 等），天然形成筛选与分组，DAX 度量值无需显式处理。支持 store_region/store_type 粒度行展开看 shop_code 粒度明细数据。

10. **与 PB_Location_Sales_detail_ms.md 的关系**：本方案为 Fulfillment 部分的矩阵 SWITCH 路由版本，与 Sales 版本共享相同的架构范式（断开列维度 + SWITCH 动态路由 + REMOVEFILTERS 修复上下文），差异在于：
    - calc_type 由 "payment" 改为 "fulfillment"
    - 列指标维度表替换为 Dim_ColMetric_Fulfillment_PB_Location（46 行 vs 15 行）
    - 新增 Inventory 分组的期末取末日特殊逻辑
    - 新增无 LY/vs LY 分组（6 个）的处理分支
