# Power BI 中国式报表解决方案 — KPI by Platform 矩阵

> status: ready
> created: 2026-07-14
> complexity: 🟡中等
> type: 度量值开发 + 可视化构建
> 口径来源: 口径文档/KPI Progress.md 子模块五：KPI by Platform
> 参考: Category Growth/参考文件/KPI By Platform_matrix_solution.md、KPI Breakdown Cell SVG Icon

---

## 1. 需求理解

实现"KPI by Platform"中国式矩阵效果：

- **行**：店铺维度 Slicer_Store_Name[Store_ID]，复用已有店铺维度表
- **列**：指标维度 'Dim_ColMetric_KPI by Platform'[Metric_Name]，15 个指标（Metric_ID 1~21，跳号）
- **值**：SWITCH 动态路由，按 Metric_ID 分发到本期 / vs LP / YOY%
- **口径**：一切以口径文档 KPI Progress.md 子模块五为准
- **特殊要求**：
  - YOY% 行后缀空格数不同（YOY% / YOY % / YOY  % / YOY   % / YOY    %）以区分同名指标
  - 总计行（非 ISINSCOPE）字体黑色 #252423、背景中米色 #E6D9C7
  - 其他行字体深灰 #5F6165、背景白色 #FFFFFF
  - 仅 YOY% 指标显示 SVG 图标（复用 KPI Breakdown Cell SVG Icon 设计）

---

## 2. 现状分析

### 2.1 数据底表

| 对象     | 名称                                                                                                                                                     | 出处                                      |
| -------- | -------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------- |
| 事实表   | a05_e2e_paid_media_summary_d                                                                                                                             | 维度复用/a05_e2e_paid_media_summary_d.sql |
| 关键字段 | data_date, platform, store_name, trans_cycle, customer_type, page_type, framework, cost_amt, net_sales_amt, media_member_cnt, member_cnt, media_cost_amt | 口径文档 KPI Progress.md 子模块五         |

### 2.2 维度表清单

| 维度表                        | 类型     | 连接方式                                                  | 出处                                       |
| ----------------------------- | -------- | --------------------------------------------------------- | ------------------------------------------ |
| Slicer_Time_Frame_Min         | 断开维度 | SELECTEDVALUE 读取 TimeFrame_Min                          | 维度复用/Slicer_Time_Frame_Min.sql         |
| Slicer_Time_Frame_Max         | 断开维度 | SELECTEDVALUE 读取 TimeFrame_Max                          | 维度复用/Slicer_Time_Frame_Max.sql         |
| Slicer_Platform_Selection     | 1:N 关系 | Platform_ID → 事实表[platform]                           | 维度复用/Slicer_Platform_Selection         |
| Slicer_Store_Name             | 1:N 关系 | Store_ID → 事实表[store_name]                            | 维度复用/Slicer_Store_Name                 |
| Slicer_Currency_Selection     | 断开维度 | SELECTEDVALUE 读取 Currency_ExchangeRate, Currency_Symbol | 维度复用/Slicer_Currency_Selection         |
| trans_cycle 筛选器            | 1:N 关系 | → 事实表[trans_cycle]（模型自动筛选）                    | 用户需求                                   |
| Dim_ColMetric_KPI by Platform | 断开维度 | SELECTEDVALUE 读取 Metric_ID, Metric_Format               | KPI Progress/Dim_ColMetric_KPI by Platform |

### 2.3 指标维度表（Dim_ColMetric_KPI by Platform）15 个指标

| Metric_ID | Metric_Name                                           | Metric_Sort | Metric_Format        | IsCurrencyAmount |
| --------- | ----------------------------------------------------- | ----------- | -------------------- | ---------------- |
| 1         | Media Cost Rate                                       | 10          | percent_1dp          | FALSE            |
| 2         | Media Cost Rate vs LP                                 | 20          | percent_1dp          | FALSE            |
| 3         | YOY%                                                  | 30          | delta_pct_1dp        | FALSE            |
| 4         | Media Cost                                            | 40          | currency             | TRUE             |
| 5         | Media Cost vs LP                                      | 50          | currency             | TRUE             |
| 6         | YOY %                                                 | 60          | delta_pct_1dp        | FALSE            |
| 13        | ± Acceleration cost MOB% vs. store SLS MOB%          | 130         | percent_1dp          | FALSE            |
| 14        | ± Acceleration cost MOB% vs. store SLS MOB% vs LP    | 140         | percent_1dp          | FALSE            |
| 15        | YOY  %                                                | 150         | delta_pct_1dp        | FALSE            |
| 16        | Media Contribution to New Customer Acquisition%       | 160         | percent_1dp          | FALSE            |
| 17        | Media Contribution to New Customer Acquisition% vs LP | 170         | percent_1dp          | FALSE            |
| 18        | YOY   %                                               | 180         | delta_pct_1dp        | FALSE            |
| 19        | Cost Per New Acquisition                              | 190         | currency_decimal_1dp | TRUE             |
| 20        | Cost Per New Acquisition vs LP                        | 200         | currency_decimal_1dp | TRUE             |
| 21        | YOY    %                                              | 210         | delta_pct_1dp        | FALSE            |

---

## 3. 方案设计

### 3.1 整体架构

```
核心思路：双维度断开 + SWITCH 动态路由（Disconnected Dimensions + Dispatch Pattern）

Dim_ColMetric_KPI by Platform（断开维度，列头）    Slicer_Store_Name（已有维度，行头，1:N→事实表）
    │                                                      │
    │  无关系连接，仅通过 SELECTEDVALUE 读取                  │  已有关系连接到事实表
    │                                                      │
    ▼                                                      ▼
    ┌─────────────────── Matrix 视觉对象 ──────────────────┐
    │  行 = Slicer_Store_Name[Store_ID]                     │
    │  列 = 'Dim_ColMetric_KPI by Platform'[Metric_Name]    │
    │  值 = [KPI by Platform Cell Display]                  │
    └───────────────────────────────────────────────────────┘
           ▲
           │
    SWITCH 动态路由度量值链
    ┌────────────────────────────────────────────────────┐
    │  [KPI by Platform Cell Value]                        │
    │    └→ [KPI by Platform Base Value]（总路由）          │
    │         ├→ [KPI by Platform Current Base Value]     │
    │         ├→ [KPI by Platform vsLP Base Value]       │
    │         └→ YOY% = (Current - vsLP) / vsLP          │
    └────────────────────────────────────────────────────┘
```

### 3.2 度量值模型设计（拆分 Current / vsLP）

按用户建议，将 Base Value 拆分为两个子项，便于维护和复用：

```
[KPI by Platform Current Base Value]  ← 本期基础值（Metric_ID 1/4/13/16/19）
[KPI by Platform vsLP Base Value]     ← 同期基础值（Metric_ID 2/5/14/17/20）
[KPI by Platform Base Value]          ← 总路由（含 YOY% 计算，Metric_ID 3/6/15/18/21）
[KPI by Platform Cell Value]         ← 对外值 = Base Value
[KPI by Platform Cell Display]       ← 格式化显示文本
[KPI by Platform Cell Font Color]    ← 字体颜色（总计行 vs 其他行）
[KPI by Platform Cell Background Color] ← 背景色（总计行 vs 其他行）
[KPI by Platform Cell SVG Icon]      ← SVG 图标（仅 YOY% 行）
```

### 3.3 筛选器上下文

| 筛选器                    | 作用方式                                   | DAX 处理                            |
| ------------------------- | ------------------------------------------ | ----------------------------------- |
| Slicer_Time_Frame_Min     | 断开维度，SELECTEDVALUE 读取 TimeFrame_Min | `data_date >= __TimeMin`          |
| Slicer_Time_Frame_Max     | 断开维度，SELECTEDVALUE 读取 TimeFrame_Max | `data_date <= __TimeMax`          |
| Slicer_Platform_Selection | 1:N 关系，模型自动筛选                     | 无需显式处理                        |
| Slicer_Store_Name         | 1:N 关系，模型自动筛选                     | 无需显式处理                        |
| trans_cycle               | 1:N 关系，模型自动筛选                     | 无需显式处理                        |
| Slicer_Currency_Selection | 断开维度，SELECTEDVALUE 读取汇率和符号     | 金额类指标 × Currency_ExchangeRate |

### 3.4 vs LP 时间偏移规则

```
当前时间段：__TimeMin ~ __TimeMax（由 Slicer_Time_Frame_Min/Max 决定）
vs LP 时间段：EDATE(__TimeMin, -12) ~ EDATE(__TimeMax, -12)

示例：
  当前 2025-10-24 ~ 2025-10-31
  vs LP 2024-10-24 ~ 2024-10-31
```

---

## 4. 度量值实现

### 4.1 KPI by Platform Current Base Value（本期基础值）

```dax
KPI by Platform Current Base Value = 
// ========================================
// 度量值: KPI by Platform Current Base Value
// Display Folder: Base Metrics
// 用途: 根据 Metric_ID 路由到本期（Current）基础值
// 依赖: 'Dim_ColMetric_KPI by Platform'[Metric_ID], a05_e2e_paid_media_summary_d
// 口径来源: KPI Progress.md 子模块五（指标 19~23 的本期值）
// 筛选: customer_type='ALL' 或 'NEW'，page_type="1"
// ========================================
    VAR __MetricID = SELECTEDVALUE('Dim_ColMetric_KPI by Platform'[Metric_ID])
    // ── 时间筛选：本期 ──
    VAR __TimeMin = SELECTEDVALUE(Slicer_Time_Frame_Min[TimeFrame_Min])
    VAR __TimeMax = SELECTEDVALUE(Slicer_Time_Frame_Max[TimeFrame_Max])
    // ── 汇率（金额类指标需要乘以汇率）──
    VAR __FXRate = SELECTEDVALUE(Slicer_Currency_Selection[Currency_ExchangeRate], 1)
    // ── 基础聚合：ALL 口径（Media Cost Rate / Media Cost / ± Accel cost MOB%）──
    // Media Cost = SUM(cost_amt)，customer_type='ALL', page_type="1"
    VAR __Cost_ALL = 
        CALCULATE(
            SUM('a05_e2e_paid_media_summary_d'[cost_amt]),
            'a05_e2e_paid_media_summary_d'[customer_type] = "ALL",
            'a05_e2e_paid_media_summary_d'[page_type] = "1",
            'a05_e2e_paid_media_summary_d'[data_date] >= __TimeMin,
            'a05_e2e_paid_media_summary_d'[data_date] <= __TimeMax
        )
    // Media SLS = SUM(net_sales_amt)，customer_type='ALL', page_type="1"
    VAR __SLS_ALL = 
        CALCULATE(
            SUM('a05_e2e_paid_media_summary_d'[net_sales_amt]),
            'a05_e2e_paid_media_summary_d'[customer_type] = "ALL",
            'a05_e2e_paid_media_summary_d'[page_type] = "1",
            'a05_e2e_paid_media_summary_d'[data_date] >= __TimeMin,
            'a05_e2e_paid_media_summary_d'[data_date] <= __TimeMax
        )
    // Acceleration Cost = SUM(cost_amt), framework='Acceleration'
    VAR __AccelCost_ALL = 
        CALCULATE(
            SUM('a05_e2e_paid_media_summary_d'[cost_amt]),
            'a05_e2e_paid_media_summary_d'[customer_type] = "ALL",
            'a05_e2e_paid_media_summary_d'[page_type] = "1",
            'a05_e2e_paid_media_summary_d'[framework] = "Acceleration",
            'a05_e2e_paid_media_summary_d'[data_date] >= __TimeMin,
            'a05_e2e_paid_media_summary_d'[data_date] <= __TimeMax
        )
    // Acceleration SLS = SUM(net_sales_amt), framework='Acceleration'
    VAR __AccelSLS_ALL = 
        CALCULATE(
            SUM('a05_e2e_paid_media_summary_d'[net_sales_amt]),
            'a05_e2e_paid_media_summary_d'[customer_type] = "ALL",
            'a05_e2e_paid_media_summary_d'[page_type] = "1",
            'a05_e2e_paid_media_summary_d'[framework] = "Acceleration",
            'a05_e2e_paid_media_summary_d'[data_date] >= __TimeMin,
            'a05_e2e_paid_media_summary_d'[data_date] <= __TimeMax
        )
    // ── 基础聚合：NEW 口径（Media New Cust Contribution% / Cost Per New Acq）──
    // Media New Customer = SUM(media_member_cnt), customer_type='NEW', page_type="1"
    VAR __MediaNewCust_NEW = 
        CALCULATE(
            SUM('a05_e2e_paid_media_summary_d'[media_member_cnt]),
            'a05_e2e_paid_media_summary_d'[customer_type] = "NEW",
            'a05_e2e_paid_media_summary_d'[page_type] = "1",
            'a05_e2e_paid_media_summary_d'[data_date] >= __TimeMin,
            'a05_e2e_paid_media_summary_d'[data_date] <= __TimeMax
        )
    // Total New Customer = SUM(member_cnt), customer_type='NEW', page_type="1"
    VAR __TotalNewCust_NEW = 
        CALCULATE(
            SUM('a05_e2e_paid_media_summary_d'[member_cnt]),
            'a05_e2e_paid_media_summary_d'[customer_type] = "NEW",
            'a05_e2e_paid_media_summary_d'[page_type] = "1",
            'a05_e2e_paid_media_summary_d'[data_date] >= __TimeMin,
            'a05_e2e_paid_media_summary_d'[data_date] <= __TimeMax
        )
    // Media New Cost = SUM(media_cost_amt), customer_type='NEW', page_type="1"
    VAR __MediaNewCost_NEW = 
        CALCULATE(
            SUM('a05_e2e_paid_media_summary_d'[media_cost_amt]),
            'a05_e2e_paid_media_summary_d'[customer_type] = "NEW",
            'a05_e2e_paid_media_summary_d'[page_type] = "1",
            'a05_e2e_paid_media_summary_d'[data_date] >= __TimeMin,
            'a05_e2e_paid_media_summary_d'[data_date] <= __TimeMax
        )
    // ── 派生指标 ──
    // Media Cost Rate = Cost / SLS
    VAR __MediaCostRate = DIVIDE(__Cost_ALL, __SLS_ALL)
    // Acceleration Cost MOB% = Accel Cost / Total Cost
    VAR __AccelCostMOB = DIVIDE(__AccelCost_ALL, __Cost_ALL)
    // Store SLS MOB% = Accel SLS / Total SLS
    VAR __StoreSLSMOB = DIVIDE(__AccelSLS_ALL, __SLS_ALL)
    // ± Acceleration cost MOB% vs. store SLS MOB% = Accel Cost MOB% - Store SLS MOB%
    VAR __AccelCostMOBvsSLS = __AccelCostMOB - __StoreSLSMOB
    // Media Contribution to New Customer Acquisition% = Media New Cust / Total New Cust
    VAR __MediaNewCustContrib = DIVIDE(__MediaNewCust_NEW, __TotalNewCust_NEW)
    // Cost Per New Acquisition = Media New Cost / Media New Cust
    VAR __CostPerNewAcq = DIVIDE(__MediaNewCost_NEW, __MediaNewCust_NEW)
    RETURN
        SWITCH(
            __MetricID,
            1,  DIVIDE(__MediaCostRate * 1.13 , 1.06) ,                    // Media Cost Rate（本期）
            4,  DIVIDE(__Cost_ALL , __FXRate),              // Media Cost（本期，金额×汇率）
            7, __AccelCostMOBvsSLS,                // ± Accel cost MOB% vs. store SLS MOB%（本期）
            10, __MediaNewCustContrib,              // Media Contribution to New Cust%（本期）
            13, DIVIDE(__CostPerNewAcq , __FXRate),         // Cost Per New Acq（本期，金额×汇率）
            BLANK()
        )
```

### 4.2 KPI by Platform vsLP Base Value（同期基础值）

```dax
KPI by Platform vsLP Base Value = 
// ========================================
// 度量值: KPI by Platform vsLP Base Value
// Display Folder: Base Metrics
// 用途: 根据 Metric_ID 路由到同期（vs LP）基础值
// 依赖: 'Dim_ColMetric_KPI by Platform'[Metric_ID], a05_e2e_paid_media_summary_d
// 口径来源: KPI Progress.md 子模块五（指标 19~23 的 vs LP 值）
// 说明: vs LP = 当前时间段往前推一年（EDATE -12 个月）
//       例如：当前 2025-10-24 ~ 2025-10-31，vs LP = 2024-10-24 ~ 2024-10-31
// ========================================
    VAR __MetricID = SELECTEDVALUE('Dim_ColMetric_KPI by Platform'[Metric_ID])
    // ── 时间筛选：同期（vs LP），往前推一年 ──
    VAR __TimeMin = SELECTEDVALUE(Slicer_Time_Frame_Min[TimeFrame_Min])
    VAR __TimeMax = SELECTEDVALUE(Slicer_Time_Frame_Max[TimeFrame_Max])
    VAR __LPTimeMin = EDATE(__TimeMin, -12)
    VAR __LPTimeMax = EDATE(__TimeMax, -12)
    // ── 汇率 ──
    VAR __FXRate = SELECTEDVALUE(Slicer_Currency_Selection[Currency_ExchangeRate], 1)
    // ── 基础聚合：ALL 口径 ──
    VAR __Cost_ALL = 
        CALCULATE(
            SUM('a05_e2e_paid_media_summary_d'[cost_amt]),
            'a05_e2e_paid_media_summary_d'[customer_type] = "ALL",
            'a05_e2e_paid_media_summary_d'[page_type] = "1",
            'a05_e2e_paid_media_summary_d'[data_date] >= __LPTimeMin,
            'a05_e2e_paid_media_summary_d'[data_date] <= __LPTimeMax
        )
    VAR __SLS_ALL = 
        CALCULATE(
            SUM('a05_e2e_paid_media_summary_d'[net_sales_amt]),
            'a05_e2e_paid_media_summary_d'[customer_type] = "ALL",
            'a05_e2e_paid_media_summary_d'[page_type] = "1",
            'a05_e2e_paid_media_summary_d'[data_date] >= __LPTimeMin,
            'a05_e2e_paid_media_summary_d'[data_date] <= __LPTimeMax
        )
    VAR __AccelCost_ALL = 
        CALCULATE(
            SUM('a05_e2e_paid_media_summary_d'[cost_amt]),
            'a05_e2e_paid_media_summary_d'[customer_type] = "ALL",
            'a05_e2e_paid_media_summary_d'[page_type] = "1",
            'a05_e2e_paid_media_summary_d'[framework] = "Acceleration",
            'a05_e2e_paid_media_summary_d'[data_date] >= __LPTimeMin,
            'a05_e2e_paid_media_summary_d'[data_date] <= __LPTimeMax
        )
    VAR __AccelSLS_ALL = 
        CALCULATE(
            SUM('a05_e2e_paid_media_summary_d'[net_sales_amt]),
            'a05_e2e_paid_media_summary_d'[customer_type] = "ALL",
            'a05_e2e_paid_media_summary_d'[page_type] = "1",
            'a05_e2e_paid_media_summary_d'[framework] = "Acceleration",
            'a05_e2e_paid_media_summary_d'[data_date] >= __LPTimeMin,
            'a05_e2e_paid_media_summary_d'[data_date] <= __LPTimeMax
        )
    // ── 基础聚合：NEW 口径 ──
    VAR __MediaNewCust_NEW = 
        CALCULATE(
            SUM('a05_e2e_paid_media_summary_d'[media_member_cnt]),
            'a05_e2e_paid_media_summary_d'[customer_type] = "NEW",
            'a05_e2e_paid_media_summary_d'[page_type] = "1",
            'a05_e2e_paid_media_summary_d'[data_date] >= __LPTimeMin,
            'a05_e2e_paid_media_summary_d'[data_date] <= __LPTimeMax
        )
    VAR __TotalNewCust_NEW = 
        CALCULATE(
            SUM('a05_e2e_paid_media_summary_d'[member_cnt]),
            'a05_e2e_paid_media_summary_d'[customer_type] = "NEW",
            'a05_e2e_paid_media_summary_d'[page_type] = "1",
            'a05_e2e_paid_media_summary_d'[data_date] >= __LPTimeMin,
            'a05_e2e_paid_media_summary_d'[data_date] <= __LPTimeMax
        )
    VAR __MediaNewCost_NEW = 
        CALCULATE(
            SUM('a05_e2e_paid_media_summary_d'[media_cost_amt]),
            'a05_e2e_paid_media_summary_d'[customer_type] = "NEW",
            'a05_e2e_paid_media_summary_d'[page_type] = "1",
            'a05_e2e_paid_media_summary_d'[data_date] >= __LPTimeMin,
            'a05_e2e_paid_media_summary_d'[data_date] <= __LPTimeMax
        )
    // ── 派生指标 ──
    VAR __MediaCostRate = DIVIDE(__Cost_ALL, __SLS_ALL)
    VAR __AccelCostMOB = DIVIDE(__AccelCost_ALL, __Cost_ALL)
    VAR __StoreSLSMOB = DIVIDE(__AccelSLS_ALL, __SLS_ALL)
    VAR __AccelCostMOBvsSLS = __AccelCostMOB - __StoreSLSMOB
    VAR __MediaNewCustContrib = DIVIDE(__MediaNewCust_NEW, __TotalNewCust_NEW)
    VAR __CostPerNewAcq = DIVIDE(__MediaNewCost_NEW, __MediaNewCust_NEW)
    RETURN
        SWITCH(
            __MetricID,
            2,  DIVIDE(__MediaCostRate * 1.13 , 1.06),                    // Media Cost Rate vs LP
            5,  DIVIDE(__Cost_ALL , __FXRate),              // Media Cost vs LP
            8, __AccelCostMOBvsSLS,                // ± Accel cost MOB% vs. store SLS MOB% vs LP
            11, __MediaNewCustContrib,              // Media Contribution to New Cust% vs LP
            14, DIVIDE(__CostPerNewAcq , __FXRate),         // Cost Per New Acq vs LP
            BLANK()
        )
```

### 4.3 KPI by Platform Base Value（总路由）

```dax
KPI by Platform Base Value = 
	// ========================================
	// 度量值: KPI by Platform Base Value
	// Display Folder: Base Metrics
	// 用途: 总路由，根据 Metric_ID 分发到 Current / vsLP / YOY%
	// 依赖: [KPI by Platform Current Base Value], [KPI by Platform vsLP Base Value]
	// 说明: 
	//   Metric_ID 1/4/13/16/19 → Current
	//   Metric_ID 2/5/14/17/20 → vsLP
	//   Metric_ID 3/6/18/21    → YOY% (常规同比百分比，含边界判断)
	//   Metric_ID 15           → YOY% (bp 指标特例：本期bp - 去年bp 差值)
	// ========================================
	    VAR __MetricID = SELECTEDVALUE('Dim_ColMetric_KPI by Platform'[Metric_ID])
	    // 判断当前是否为 YOY 行
        VAR __IsYOY = __MetricID IN {3, 6, 9, 12, 15}
    
        // 修复上下文冲突：矩阵行标题会保留 Metric_Name 等所有列的筛选器，
        // 仅覆盖 Metric_ID 会导致筛选条件冲突（如 Metric_ID=1 AND Metric_Name="YOY%"）从而返回 BLANK。
        // 因此需先 REMOVEFILTERS 清除断开维度的所有筛选，再应用目标 Metric_ID。
        VAR __CurrentValue = 
            IF(
                __IsYOY,
                CALCULATE(
                    [KPI by Platform Current Base Value], 
                    REMOVEFILTERS('Dim_ColMetric_KPI by Platform'), 
                    'Dim_ColMetric_KPI by Platform'[Metric_ID] = __MetricID - 2
                ),
                [KPI by Platform Current Base Value]
            )
            
        VAR __LP_Value = 
            IF(
                __IsYOY,
                CALCULATE(
                    [KPI by Platform vsLP Base Value], 
                    REMOVEFILTERS('Dim_ColMetric_KPI by Platform'), 
                    'Dim_ColMetric_KPI by Platform'[Metric_ID] = __MetricID - 1
                ),
                [KPI by Platform vsLP Base Value]
            )
	    VAR __CurrIsEmpty = ISBLANK(__CurrentValue) || __CurrentValue = 0
	    VAR __LPIsEmpty = ISBLANK(__LP_Value) || __LP_Value = 0
	    // ── YOY 同比计算（含边界判断）──
	    // 判断逻辑：
	    //   同期为 0 或空 → 本期为 0 或空返回 BLANK()，本期有值返回 -1 (即 -100%)
	    //   本期为 0 或空，同期有值 → -1 (即 -100%)
	    //   双方均有值 → (This Year - Last Year) / Last Year
	    VAR __YOY_Result =
	        IF(
	            __LPIsEmpty,
	            BLANK(),
	                IF(__CurrIsEmpty, -1, DIVIDE(__CurrentValue - __LP_Value, __LP_Value))
	        )
	    // // ── YOY 特例（bp 指标差值计算）──
	    // // 特例（如 ID15 bp 指标）：YOY = 本期bp - 去年bp（差值，非增长率）
	    // VAR __YOY_Bp = __Current - __vsLP
	    RETURN
	        SWITCH(
	            __MetricID,
	            // ─── 本期值 ───
	            1,  __CurrentValue,    // Media Cost Rate
	            4,  __CurrentValue,    // Media Cost
	            7, __CurrentValue,    // ± Accel cost MOB% vs. store SLS MOB%
	            10, __CurrentValue,    // Media Contribution to New Cust%
	            13, __CurrentValue,    // Cost Per New Acquisition
	            // ─── vs LP 值 ───
	            2,  __LP_Value,       // Media Cost Rate vs LP
	            5,  __LP_Value,       // Media Cost vs LP
	            8, __LP_Value,       // ± Accel cost MOB% vs. store SLS MOB% vs LP
	            11, __LP_Value,       // Media Contribution to New Cust% vs LP
	            14, __LP_Value,       // Cost Per New Acquisition vs LP
	            // ─── YOY% 计算 ───
	            3,  __YOY_Result,    // YOY% (Media Cost Rate)
	            6,  __YOY_Result,    // YOY % (Media Cost)
	            9, __YOY_Result,     // YOY % (± Accel cost MOB%)
	            12, __YOY_Result,    // YOY % (Media New Cust Contribution%)
	            15, __YOY_Result,    // YOY % (Cost Per New Acq)
	            BLANK()
	        )
```

### 4.4 KPI by Platform Cell Value（对外值）

```dax
KPI by Platform Cell Value = 
// ========================================
// 度量值: KPI by Platform Cell Value
// Display Folder: Cell Values
// 用途: 对外暴露的单元格值，等于 Base Value
// 依赖: [KPI by Platform Base Value]
// 说明: 保持命名一致性，与 KPI Breakdown 解决方案对齐
// ========================================
    [KPI by Platform Base Value]
```

### 4.5 KPI by Platform Cell Display（格式化显示）

```dax
KPI by Platform Cell Display = 
// ========================================
// 度量值: KPI by Platform Cell Display
// Display Folder: Formatting
// 用途: 根据 Metric_Format 返回格式化后的文本
// 依赖: [KPI by Platform Cell Value], 'Dim_ColMetric_KPI by Platform'[Metric_Format]
// 格式类型:
//   currency              → 货币符号 + 千分位整数：¥1,000 / $1,000
//   currency_decimal_1dp  → 货币符号 + 千分位一位小数：¥1,000.0 / $1,000.0
//   percent_1dp           → 百分比一位小数，不含正号：14.5%
//   delta_pct_1dp         → 增减百分比一位小数，含正号：+14.5%
// 口径来源: KPI Progress.md 子模块五（数据格式列）
// ========================================
    VAR __Value = [KPI by Platform Cell Value]
    VAR __Format = SELECTEDVALUE('Dim_ColMetric_KPI by Platform'[Metric_Format])
    VAR __CurrencySymbol = SELECTEDVALUE(Slicer_Currency_Selection[Currency_Symbol], "¥")
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            SWITCH(
                __Format,
                // ─── 货币（符号由币种切片器决定）─────────────
                "currency",
                    __CurrencySymbol & FORMAT(__Value, "#,##0"),                          // ¥1,000
                "currency_decimal_1dp",
                    __CurrencySymbol & FORMAT(__Value, "#,##0.0"),                         // ¥1,000.0
                // ─── 百分比（不含正号）──────────────────────────
                "percent_1dp",
                    FORMAT(__Value, "#,##0.0%;#,##0.0%;0.0%"),                             // 14.5%
                // ─── 增减百分比（含正号）──────────────────────
                "delta_pct_1dp",
                    IF(__Value > 0, "+", "") & FORMAT(__Value, "#,##0.0%;-#,##0.0%;0.0%"), // +14.5%
                // ─── 默认 ─────────────────────────────────────
                FORMAT(__Value, "#,##0.00")
            )
        )
```

### 4.6 KPI by Platform Cell Font Color（字体颜色）

```dax
KPI by Platform Cell Font Color = 
// ========================================
// 度量值: KPI by Platform Cell Font Color
// Display Folder: Formatting
// 用途: 区别总计行和其他行的字体颜色
// 依赖: ISINSCOPE(Slicer_Store_Name[Store_ID])
// 说明: 总计行（非 ISINSCOPE）→ #252423（黑色）
//       其他行（ISINSCOPE）→ #5F6165（深灰）
// 注意: 若行字段改为 store_name，请替换为 ISINSCOPE(Slicer_Store_Name[store_name])
// ========================================
    IF(
        ISINSCOPE(Slicer_Store_Name[Store_ID]),
        "#5F6165",    // 非总计行：深灰
        "#252423"     // 总计行：黑色
    )
```

### 4.7 KPI by Platform Cell Background Color（背景色）

```dax
KPI by Platform Cell Background Color = 
// ========================================
// 度量值: KPI by Platform Cell Background Color
// Display Folder: Formatting
// 用途: 区别总计行和其他行的背景颜色
// 依赖: ISINSCOPE(Slicer_Store_Name[Store_ID])
// 说明: 总计行（非 ISINSCOPE）→ #E6D9C7（中米色）
//       其他行（ISINSCOPE）→ #FFFFFF（白色）
// 注意: 若行字段改为 store_name，请替换为 ISINSCOPE(Slicer_Store_Name[store_name])
// ========================================
    IF(
        ISINSCOPE(Slicer_Store_Name[Store_ID]),
        "#FFFFFF",    // 非总计行：白色
        "#E6D9C7"     // 总计行：中米色
    )
```

### 4.8 KPI by Platform Cell SVG Icon（SVG 图标）

```dax
KPI by Platform Cell SVG Icon = 
// ========================================
// 度量值: KPI by Platform Cell SVG Icon
// Display Folder: Formatting
// 用途: 仅 YOY% 指标返回 SVG 圆形图标
// 依赖: [KPI by Platform Cell Value], 'Dim_ColMetric_KPI by Platform'[Metric_Format]
// 说明: 需将此度量值的数据类别设为"图像 URL"
//       YOY% 的 Metric_Format = delta_pct_1dp
//       正值 → 绿色圆，负值 → 红色圆，零值 → 黄色圆
//       图标复用 KPI Breakdown Cell SVG Icon 的设计
// ========================================
    VAR __Value = [KPI by Platform Cell Value]
    VAR __Format = SELECTEDVALUE('Dim_ColMetric_KPI by Platform'[Metric_Format])
    VAR __NeedsIcon = __Format = "delta_pct_1dp"
    VAR __GreenSVG =
        "data:image/svg+xml;utf8," &
        "<svg xmlns='http://www.w3.org/2000/svg' width='16' height='16'>" &
        "<circle cx='8' cy='8' r='7' fill='%234CAF50'/></svg>"
    VAR __RedSVG =
        "data:image/svg+xml;utf8," &
        "<svg xmlns='http://www.w3.org/2000/svg' width='16' height='16'>" &
        "<circle cx='8' cy='8' r='7' fill='%23F44336'/></svg>"
    VAR __YellowSVG =
        "data:image/svg+xml;utf8," &
        "<svg xmlns='http://www.w3.org/2000/svg' width='16' height='16'>" &
        "<circle cx='8' cy='8' r='7' fill='%23E1C233'/></svg>"
    RETURN
        SWITCH(
            TRUE(),
            __NeedsIcon && __Value > 0,  __GreenSVG,       // 正值 → 绿色圆
            __NeedsIcon && __Value < 0,  __RedSVG,          // 负值 → 红色圆
            __NeedsIcon && __Value = 0,  __YellowSVG,       // 零值 → 黄色圆
            BLANK()
        )
```

---

## 5. 度量值清单与 Display Folder

| 序号 | 度量值名称                            | Display Folder | 用途                                 |
| ---- | ------------------------------------- | -------------- | ------------------------------------ |
| 1    | KPI by Platform Current Base Value    | Base Metrics   | 本期基础值（Metric_ID 1/4/13/16/19） |
| 2    | KPI by Platform vsLP Base Value       | Base Metrics   | 同期基础值（Metric_ID 2/5/14/17/20） |
| 3    | KPI by Platform Base Value            | Base Metrics   | 总路由（含 YOY% 计算）               |
| 4    | KPI by Platform Cell Value            | Cell Values    | 对外值 = Base Value                  |
| 5    | KPI by Platform Cell Display          | Formatting     | 格式化显示文本                       |
| 6    | KPI by Platform Cell Font Color       | Formatting     | 字体颜色                             |
| 7    | KPI by Platform Cell Background Color | Formatting     | 背景色                               |
| 8    | KPI by Platform Cell SVG Icon         | Formatting     | SVG 图标（仅 YOY%）                  |

---

## 6. 指标口径来源对照

| Metric_ID | Metric_Name                                 | 口径文档出处        | 计算公式                         | 统计字段                                                                                                        | customer_type | framework           |
| --------- | ------------------------------------------- | ------------------- | -------------------------------- | --------------------------------------------------------------------------------------------------------------- | ------------- | ------------------- |
| 1         | Media Cost Rate                             | 子模块五 §19       | Cost / SLS                       | cost_amt / net_sales_amt                                                                                        | ALL           | -                   |
| 2         | Media Cost Rate vs LP                       | 子模块五 §19 vs LP | 同上，时间往前推一年             | 同上                                                                                                            | ALL           | -                   |
| 3         | YOY%                                        | 子模块五 §19 YOY%  | (Current - vsLP) / vsLP          | -                                                                                                               | -             | -                   |
| 4         | Media Cost                                  | 子模块五 §20       | SUM(cost_amt)                    | cost_amt                                                                                                        | ALL           | -                   |
| 5         | Media Cost vs LP                            | 子模块五 §20 vs LP | 同上，时间往前推一年             | 同上                                                                                                            | ALL           | -                   |
| 6         | YOY %                                       | 子模块五 §20 YOY%  | (Current - vsLP) / vsLP          | -                                                                                                               | -             | -                   |
| 13        | ± Accel cost MOB% vs. store SLS MOB%       | 子模块五 §21       | Accel Cost MOB% - Store SLS MOB% | cost_amt(framework='Acceleration')/cost_amt(全部) - net_sales_amt(framework='Acceleration')/net_sales_amt(全部) | ALL           | Acceleration + 全部 |
| 14        | ± Accel cost MOB% vs. store SLS MOB% vs LP | 子模块五 §21 vs LP | 同上，时间往前推一年             | 同上                                                                                                            | ALL           | Acceleration + 全部 |
| 15        | YOY  %                                      | 子模块五 §21 YOY%  | (Current - vsLP) / vsLP          | -                                                                                                               | -             | -                   |
| 16        | Media Contribution to New Cust%             | 子模块五 §22       | Media New Cust / Total New Cust  | media_member_cnt / member_cnt                                                                                   | NEW           | -                   |
| 17        | Media Contribution to New Cust% vs LP       | 子模块五 §22 vs LP | 同上，时间往前推一年             | 同上                                                                                                            | NEW           | -                   |
| 18        | YOY   %                                     | 子模块五 §22 YOY%  | (Current - vsLP) / vsLP          | -                                                                                                               | -             | -                   |
| 19        | Cost Per New Acquisition                    | 子模块五 §23       | Media New Cost / Media New Cust  | media_cost_amt / media_member_cnt                                                                               | NEW           | -                   |
| 20        | Cost Per New Acquisition vs LP              | 子模块五 §23 vs LP | 同上，时间往前推一年             | 同上                                                                                                            | NEW           | -                   |
| 21        | YOY    %                                    | 子模块五 §23 YOY%  | (Current - vsLP) / vsLP          | -                                                                                                               | -             | -                   |

---

## 7. 血缘关系图（Lineage Diagram）

```
┌─────────────────────────────────────────────────────────────────────┐
│                        数据源层                                      │
│  a05_e2e_paid_media_summary_d（事实表）                              │
│  字段: data_date, platform, store_name, trans_cycle,                │
│        customer_type, page_type, framework,                         │
│        cost_amt, net_sales_amt, media_member_cnt,                   │
│        member_cnt, media_cost_amt                                   │
└──────────────────────────────┬──────────────────────────────────────┘
                               │
                               │ 1:N 关系（模型自动筛选）
                               │
              ┌────────────────┼────────────────┐
              │                │                │
              ▼                ▼                ▼
┌──────────────────┐ ┌──────────────────┐ ┌──────────────────┐
│ Slicer_Platform_  │ │ Slicer_Store_    │ │ trans_cycle     │
│ Selection         │ │ Name             │ │ 筛选器           │
│ (Platform_ID)     │ │ (Store_ID)       │ │ (trans_cycle)   │
└──────────────────┘ └──────────────────┘ └──────────────────┘
              │                │
              │  ┌─────────────┘
              │  │ ISINSCOPE 判断总计行
              │  │
              ▼  ▼
┌─────────────────────────────────────────────────────────────────────┐
│                        度量值层                                      │
│                                                                     │
│  ┌─────────────────────────┐   ┌─────────────────────────┐          │
│  │ KPI by Platform         │   │ KPI by Platform         │          │
│  │ Current Base Value      │   │ vsLP Base Value         │          │
│  │ (Metric_ID 1/4/13/16/19)│   │ (Metric_ID 2/5/14/17/20)│         │
│  └───────────┬─────────────┘   └───────────┬─────────────┘          │
│              │                              │                        │
│              │    ┌─────────────────────────┘                        │
│              │    │                                                  │
│              ▼    ▼                                                  │
│  ┌─────────────────────────┐   ┌─────────────────────────┐          │
│  │ KPI by Platform         │   │ Slicer_Time_Frame_Min   │          │
│  │ Base Value              │◄──│ Slicer_Time_Frame_Max   │          │
│  │ (总路由 + YOY%)         │   │ (断开维度，SELECTEDVALUE) │          │
│  └───────────┬─────────────┘   └─────────────────────────┘          │
│              │                                                      │
│              │ EDATE(-12) 用于 vsLP                                  │
│              ▼                                                      │
│  ┌─────────────────────────┐                                        │
│  │ KPI by Platform         │   ┌─────────────────────────┐          │
│  │ Cell Value              │◄──│ Slicer_Currency_        │          │
│  │ (= Base Value)          │   │ Selection               │          │
│  └───────────┬─────────────┘   │ (断开维度，汇率×金额)    │          │
│              │                  └─────────────────────────┘          │
│              ▼                                                      │
│  ┌─────────────────────────┐                                        │
│  │ KPI by Platform         │   ┌─────────────────────────┐          │
│  │ Cell Display            │◄──│ 'Dim_ColMetric_KPI by   │          │
│  │ (格式化文本)             │   │ Platform'              │          │
│  └───────────┬─────────────┘   │ (断开维度，Metric_Format)│         │
│              │                  └─────────────────────────┘          │
│              ▼                                                      │
│  ┌─────────────────────────────────────────────────┐                │
│  │  KPI by Platform Cell Font Color                 │                │
│  │  KPI by Platform Cell Background Color           │                │
│  │  KPI by Platform Cell SVG Icon                   │                │
│  │  (条件格式度量值)                                 │                │
│  └─────────────────────────────────────────────────┘                │
└─────────────────────────────────────────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────────┐
│                        可视化层                                      │
│  Matrix 视觉对象                                                     │
│  行: Slicer_Store_Name[Store_ID]                                    │
│  列: 'Dim_ColMetric_KPI by Platform'[Metric_Name]                   │
│  值: [KPI by Platform Cell Display]                                  │
│  条件格式:                                                           │
│    字体颜色 → [KPI by Platform Cell Font Color]                     │
│    背景色   → [KPI by Platform Cell Background Color]               │
│    SVG 图标 → [KPI by Platform Cell SVG Icon]（数据类别=图像 URL）   │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 8. Matrix 视觉对象配置

### 8.1 字段配置

| 区域         | 字段                                         |
| ------------ | -------------------------------------------- |
| **行** | Slicer_Store_Name[Store_ID]                  |
| **列** | 'Dim_ColMetric_KPI by Platform'[Metric_Name] |
| **值** | [KPI by Platform Cell Display]               |

### 8.2 排序配置

| 字段                                         | 排序依据    |
| -------------------------------------------- | ----------- |
| Slicer_Store_Name[Store_ID]                  | Store_Sort  |
| 'Dim_ColMetric_KPI by Platform'[Metric_Name] | Metric_Sort |

### 8.3 格式设置

- 关闭"阶梯布局"（Stepped Layout → Off）
- 关闭"行小计"（仅保留总计行用于汇总）
- 关闭"+/-"展开按钮
- 列标题：居中对齐，加粗
- 行标题：左对齐
- 值：居中对齐

### 8.4 条件格式

对 [KPI by Platform Cell Display] 值区域设置：

1. **字体颜色**：

   - 右键值区域 → 条件格式 → 字体颜色
   - 格式样式：字段值
   - 基于字段：[KPI by Platform Cell Font Color]
2. **背景颜色**：

   - 右键值区域 → 条件格式 → 背景颜色
   - 格式样式：字段值
   - 基于字段：[KPI by Platform Cell Background Color]
3. **SVG 图标**（可选）：

   - 将 [KPI by Platform Cell SVG Icon] 度量值的数据类别设为"图像 URL"
   - 在矩阵中单独添加为图像列，或使用自定义视觉对象

---

## 9. 验证方法

### 9.1 占位值验证（当前阶段）

当前度量值已接入真实数据，可通过以下方式验证：

| 验证项     | 方法                                                                                         |
| ---------- | -------------------------------------------------------------------------------------------- |
| 矩阵形状   | 确认 6 行（5 个 Store + 1 个总计）× 15 列（15 个 Metric）= 90 个单元格                      |
| 排序       | 行按 Store_Sort 排序（TM=1, JD=2, RLE_CN=3, DY_Family=4, DY_W=5, DY_MN=6）                   |
| 列排序     | 列按 Metric_Sort 排序（10, 20, 30, 40, 50, 60, 130, 140, 150, 160, 170, 180, 190, 200, 210） |
| YOY% 行名  | 确认 5 个 YOY% 行名后缀空格数不同（YOY% / YOY % / YOY  % / YOY   % / YOY    %）              |
| 总计行颜色 | 总计行字体黑色 #252423，背景中米色 #E6D9C7                                                   |
| 其他行颜色 | 其他行字体深灰 #5F6165，背景白色 #FFFFFF                                                     |
| SVG 图标   | 仅 YOY% 行显示圆形图标（正值绿、负值红、零值黄）                                             |

### 9.2 数据验证

| 指标                         | 验证 SQL                                                                                                                                                                                 |
| ---------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Media Cost Rate              | `SELECT SUM(cost_amt)/SUM(net_sales_amt) FROM a05_e2e_paid_media_summary_d WHERE customer_type='ALL' AND page_type="1" AND data_date BETWEEN '...' AND '...' AND platform='TM'`          |
| Media Cost                   | `SELECT SUM(cost_amt) FROM a05_e2e_paid_media_summary_d WHERE customer_type='ALL' AND page_type="1" AND data_date BETWEEN '...' AND '...' AND platform='TM'`                             |
| ± Accel cost MOB%           | `SELECT (SUM(CASE WHEN framework='Acceleration' THEN cost_amt END)/SUM(cost_amt)) - (SUM(CASE WHEN framework='Acceleration' THEN net_sales_amt END)/SUM(net_sales_amt)) FROM ...`      |
| Media New Cust Contribution% | `SELECT SUM(media_member_cnt)/SUM(member_cnt) FROM a05_e2e_paid_media_summary_d WHERE customer_type='NEW' AND page_type="1" AND data_date BETWEEN '...' AND '...' AND platform='TM'`     |
| Cost Per New Acq             | `SELECT SUM(media_cost_amt)/SUM(media_member_cnt) FROM a05_e2e_paid_media_summary_d WHERE customer_type='NEW' AND page_type="1" AND data_date BETWEEN '...' AND '...' AND platform='TM'` |

### 9.3 vs LP 验证

验证 vs LP 值时，将 SQL 中的日期范围往前推一年（EDATE -12），对比 DAX 计算结果。

---

## 10. 性能考量

| 考量项         | 评估                                                                                        |
| -------------- | ------------------------------------------------------------------------------------------- |
| 矩阵规模       | 6 行 × 15 列 = 90 个单元格，规模适中                                                       |
| CALCULATE 调用 | 每个单元格最多触发 5 次 CALCULATE（Current/vsLP 各 5 个基础聚合），总计约 450 次            |
| 时间筛选       | 使用布尔筛选器 `data_date >= __TimeMin`，等价于 `FILTER(ALL(data_date), ...)`，性能良好 |
| 变量复用       | Current 和 vsLP 的基础聚合在各自度量值内定义为变量，避免重复计算                            |
| 优化建议       | 如性能不佳，可将基础聚合（如 __Cost_ALL）提取为独立度量值，利用 Power BI 缓存               |
