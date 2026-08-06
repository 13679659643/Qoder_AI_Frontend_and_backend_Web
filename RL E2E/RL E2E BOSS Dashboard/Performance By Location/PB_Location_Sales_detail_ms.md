# Power BI 解决方案 — PB Location：Sales 五指标矩阵（SWITCH 路由）

> status: ready
> created: 2026-08-06
> type: 度量值开发 + 可视化构建
> 口径来源: 口径文档/Overview.md 子模块一 BOSS Core KPI - Sales 分组
> 参考实现: KPI by Platform_matrix_solution.md（总路由 REMOVEFILTERS 范式）
> 源度量: Overview/BOSS Core KPI/Overview_KPIs_ms.md
> 独立度量版本: Performance By Location/PB_Location_Sales_detail.md

---

## 1. 需求理解

为 Performance By Location 页面实现 Sales 分组五指标的中国式矩阵效果：

- **行**：无行维度表，直接拉取事实表字段（store_region / store_type / store_name 等），天然实现行维度分组和筛选，DAX 无需显式处理
- **列**：`Dim_ColMetric_Sales_PB_Location` 的两级层级 `KPIGroup`（父）> `ColName`（子）
  - 5 个 KPI 分组：SLS / Demand SLS / SLS Penetration / Return / Return%
  - 每个 KPI 分组下 3 列：Act / LY / vs LY
  - 共 15 列
- **值**：SWITCH 动态路由，按 `Metric_ID` × `ColType` 分发到 Act / LY / vs LY
- **口径**：一切以口径文档 Overview.md 子模块一 Sales 分组为准
- **筛选器**：
  - Slicer_Time_Frame_Min/Max（断开维度，筛选 data_date）
  - Slicer_Currency_Selection（断开维度，仅金额类指标 ÷ 汇率）

---

## 2. 现状分析

### 2.1 数据底表

| 对象 | 名称 | 出处 |
|------|------|------|
| 事实表 | a02_e2e_boss_performance_summary_d | Overview_KPIs_ms.md 2.1 |
| 关键字段 | data_date, store_name, calc_type, o2o_net_sales_amt, o2o_sales_amt, sales_amt, o2o_return_amt | Overview_KPIs_ms.md 2.1 |

### 2.2 维度表清单

| 维度表 | 类型 | 连接方式 |
|--------|------|---------|
| Slicer_Time_Frame_Min | 断开维度 | SELECTEDVALUE 读取 TimeFrame_Min / TimeFrame_Min_LY |
| Slicer_Time_Frame_Max | 断开维度 | SELECTEDVALUE 读取 TimeFrame_Max / TimeFrame_Max_LY |
| Slicer_Currency_Selection | 断开维度 | SELECTEDVALUE 读取 Currency_ExchangeRate / Currency_Symbol |
| Dim_ColMetric_Sales_PB_Location | 断开维度 | SELECTEDVALUE 读取 Metric_ID / ColType / Metric_Format_*（新建，见 §4.1） |

> 不使用 Slicer_Time_Frame（X 轴维度），不使用 Dim_RowKPIs_BossCoreKPI_Overview（行维度），不使用 Dim_ColKPIs_BossCoreKPI_Overview（列维度）。

---

## 3. 方案设计

### 3.1 整体架构

```
核心思路：断开列维度 + SWITCH 动态路由（Disconnected Dimension + Dispatch Pattern）

Dim_ColMetric_Sales_PB_Location（断开维度，列头）
    │
    │  无关系连接，仅通过 SELECTEDVALUE 读取：
    │  - Metric_ID, ColType, KPIGroup, ColName
    │  - Metric_Format_Act/LY/VsLY, Metric_IsCurrencyAmount
    │
    ▼
    ┌─────────────────────────── Matrix 视觉对象 ──────────────────────────┐
    │  行 = 事实表字段（store_region / store_type / store_name 等，直接拉取）│
    │  列 = 'Dim_ColMetric_Sales_PB_Location'[KPIGroup]                    │
    │        > 'Dim_ColMetric_Sales_PB_Location'[ColName]                   │
    │  值 = [Sales PB Location Cell Display]                                │
    └────────────────────────────────────────────────────────────────────────┘
                                   ▲
                                   │
              SWITCH 动态路由度量值链（按 Metric_ID 分发）
              ┌────────────────────────────────────────────────────┐
              │  [Sales PB Location Cell Value]                      │
              │    └→ [Sales PB Location Base Value]（总路由）       │
              │         ├→ [Sales PB Location Act Base Value]       │
              │         ├→ [Sales PB Location LY Base Value]        │
              │         └→ vs LY 派生（金额类：今年/去年-1，比率类：今年-去年）│
              └────────────────────────────────────────────────────┘
```

### 3.2 度量值模型设计

```
[Sales PB Location Act Base Value]  ← 本期基础值（Metric_ID 1/4/7/10/13）
[Sales PB Location LY Base Value]   ← 去年同期基础值（财历映射，Metric_ID 2/5/8/11/14）
[Sales PB Location Base Value]      ← 总路由（含 vs LY 派生，Metric_ID 3/6/9/12/15）
                                     ← 总路由使用 REMOVEFILTERS 清除断开维度筛选，再应用目标 Metric_ID
[Sales PB Location Cell Value]      ← 对外值 = Base Value
[Sales PB Location Cell Display]    ← 格式化显示文本
[Sales PB Location Cell Font Color] ← 字体颜色（KPIGroup 行 vs KPI 行 × vs LY 列 vs 其他列）
[Sales PB Location Cell Background Color] ← 背景色（KPIGroup 行 vs KPI 行）
[Sales PB Location Cell SVG Icon]   ← SVG 图标（仅 vs LY 列 + KPI 行）
```

### 3.3 筛选器上下文

| 筛选器 | 作用方式 | DAX 处理 |
|--------|---------|---------|
| Slicer_Time_Frame_Min | 断开维度，SELECTEDVALUE 读取 TimeFrame_Min | `data_date >= __TimeMin` |
| Slicer_Time_Frame_Max | 断开维度，SELECTEDVALUE 读取 TimeFrame_Max | `data_date <= __TimeMax` |
| Slicer_Currency_Selection | 断开维度，SELECTEDVALUE 读取 Currency_ExchangeRate, Currency_Symbol | 金额类指标 ÷ Currency_ExchangeRate |
| 事实表分组字段 | 表格行/列直接拉取，模型自动传递筛选 | DAX 无需显式处理 |

> calc_type 在 Sales 分组下固定为 "payment"，直接硬编码。

### 3.4 vs LY 时间偏移规则（财历映射）

直接读取日期表内置 LY 字段：
- 全局 LY 起始日：`Slicer_Time_Frame_Min[TimeFrame_Min_LY]`
- 全局 LY 结束日：`Slicer_Time_Frame_Max[TimeFrame_Max_LY]`
- 无需 EDATE -12 或 Key 偏移计算

### 3.5 vs LY 派生计算分类

| KPI 分类 | vs LY 计算方式 | Metric_Format_VsLY | 展示示例 |
|---------|---------------|-------------------|---------|
| 金额类（SLS / Demand SLS / Return） | 今年 / 去年 − 1 | percent_1dp | 14.5% |
| 比率类（SLS Penetration / Return%） | 今年 − 去年（差值，×10000 转 bp） | delta_bp | +120bp |

### 3.6 格式规范

| 格式类型 | 格式串 | 示例 | 适用度量 |
|---------|--------|------|---------|
| currency | `__CurrencySymbol & FORMAT(__Value, "#,##0")` | ¥1,234 | SLS / Demand SLS / Return 的 Act、LY |
| percent_1dp | `#,##0.0%` | 14.5% | SLS Penetration / Return% 的 Act、LY；金额类 vs LY |
| delta_bp | `IF(ROUND(__Value*10000,0)>0,"+","") & FORMAT(__Value*10000, "#,##0bp;-#,##0bp;0bp")` | +120bp | 比率类 vs LY |

---

## 4. 度量值实现

### 4.1 Dim_ColMetric_Sales_PB_Location（列指标维度表）

```dax
Dim_ColMetric_Sales_PB_Location = 
// ========================================
// 表: Dim_ColMetric_Sales_PB_Location
// 类型: 维度表（Dim_ 前缀），断开维度
// 用途: 定义 PB Location Sales 矩阵的列维度（KPIGroup > ColName）
// 范围: Performance By Location — Sales 五指标矩阵
// 说明: 5 个 KPI 分组（SLS / Demand SLS / SLS Penetration / Return / Return%）
//       每个 KPI 分组下 3 列：Act / LY / vs LY
//       共 15 个列指标
//
// 参考结构:
//   - 行维度 Dim_RowKPIs_BossCoreKPI_Overview（KPI 分组 + KPI 格式 + 汇率标识）
//   - 列维度 Dim_ColKPIs_BossCoreKPI_Overview（列类型 + 颜色）
//   本表将二者合并为单一列维度：KPI 分组从行维度迁移，列类型从列维度保留
//
// 字段说明:
//   Metric_ID              主键（全局唯一），从 1 开始递增
//                          编码规则：KPI分组序号×3 + 列偏移（0=Act, 1=LY, 2=vsLY）
//   KPIGroup               Level 1: KPI 分组名（SLS / Demand SLS / SLS Penetration / Return / Return%）
//   ColName                Level 2: 列名（Act / LY / vs LY），同名区分靠空格
//   KPIGroup_Sort          Level 1 排序（SLS=10, Demand SLS=20, ...步长 10 便于扩展）
//   ColName_Sort           Level 2 排序（全局唯一，跨分组步长 10，组内步长 1）
//   ColType                列类型标识：Act / LY / vs LY
//   KPI_CalcType           calc_type 标识（Sales 分组固定为 payment）
//   Metric_Format_Act      当期 行格式
//   Metric_Format_LY       去年同期 行格式（与 Act 格式一致）
//   Metric_Format_VsLY     YOY/同比 行格式：
//                          - 金额类：percent_1dp（今年/去年-1）
//                          - 比率类：delta_bp（今年-去年，差值bp）
//   Metric_IsCurrencyAmount BOOLEAN → 是否金额类指标
//   Metric_ColorPositive   正值颜色
//   Metric_ColorNegative   负值颜色
//   Metric_ColorZero       零值颜色
//   Metric_ColorDefault    默认颜色
//
// 同名区分机制（仅 ColName 追加空格，KPIGroup 不加空格）:
//   Power BI Sort by Column 要求同名字段只能绑定一个排序值，
//   通过在 ColName 末尾追加不同数量的空格，使各 KPI 同名值在底层字符串不同，
//   从而支持独立排序。
//   SLS              → 0 个空格（基准）
//   Demand SLS       → 1 个空格
//   SLS Penetration  → 2 个空格
//   Return           → 3 个空格
//   Return%          → 4 个空格
//   注: KPIGroup 字段为分组标题，本身各 KPI 值已天然不同，无需追加空格区分
//
// 颜色约定:
//   正值（>0）：#1A9018 绿色
//   负值（<0）：#D64550 红色
//   零值（=0）：#E1C233 黄色
//   默认：#5f6165 深灰
// ========================================
DATATABLE(
    "Metric_ID",              INTEGER,    // 主键标识（全局唯一）
    "KPIGroup",               STRING,     // Level 1: KPI 分组名
    "ColName",                STRING,     // Level 2: 列名（Act / LY / vs LY，同名区分靠空格）
    "KPIGroup_Sort",          INTEGER,    // Level 1 排序（步长 10 便于扩展）
    "ColName_Sort",           INTEGER,    // Level 2 排序（全局唯一，跨分组步长 10，组内步长 1）
    "ColType",                STRING,     // 列类型标识：Act / LY / vs LY
    "KPI_CalcType",           STRING,     // calc_type：payment
    "Metric_Format_Act",      STRING,     // 当期 行格式
    "Metric_Format_LY",       STRING,     // 去年同期 行格式（与本期格式一致）
    "Metric_Format_VsLY",     STRING,     // YOY/同比 行格式
    "Metric_IsCurrencyAmount",BOOLEAN,    // 是否金额类（TRUE 才涉及汇率换算）
    "Metric_ColorPositive",   STRING,     // 正值颜色
    "Metric_ColorNegative",   STRING,     // 负值颜色
    "Metric_ColorZero",       STRING,     // 零值颜色
    "Metric_ColorDefault",    STRING,     // 默认颜色
    {
        // ════════════════════════════════════════════════════════════════
        // SLS 分组 — O2O销售净额（金额类）
        // Act/LY: currency；vs LY: percent_1dp（今年/去年-1）
        // ColName 0 个空格（基准）
        // ════════════════════════════════════════════════════════════════
        { 1,  "SLS",             "Act",    10, 1,  "Act",   "payment", "currency",    "currency",    "percent_1dp", TRUE,  "#1A9018", "#D64550", "#E1C233", "#5f6165" },
        { 2,  "SLS",             "LY",     10, 2,  "LY",    "payment", "currency",    "currency",    "percent_1dp", TRUE,  "#1A9018", "#D64550", "#E1C233", "#5f6165" },
        { 3,  "SLS",             "vs LY",  10, 3,  "vs LY", "payment", "percent_1dp", "percent_1dp", "percent_1dp", TRUE,  "#1A9018", "#D64550", "#E1C233", "#5f6165" },

        // ════════════════════════════════════════════════════════════════
        // Demand SLS 分组 — O2O退前销售额（金额类）
        // Act/LY: currency；vs LY: percent_1dp（今年/去年-1）
        // ColName 1 个空格
        // ════════════════════════════════════════════════════════════════
        { 4,  "Demand SLS",      "Act ",    20, 11, "Act",   "payment", "currency",    "currency",    "percent_1dp", TRUE,  "#1A9018", "#D64550", "#E1C233", "#5f6165" },
        { 5,  "Demand SLS",      "LY ",     20, 12, "LY",    "payment", "currency",    "currency",    "percent_1dp", TRUE,  "#1A9018", "#D64550", "#E1C233", "#5f6165" },
        { 6,  "Demand SLS",      "vs LY ",  20, 13, "vs LY", "payment", "percent_1dp", "percent_1dp", "percent_1dp", TRUE,  "#1A9018", "#D64550", "#E1C233", "#5f6165" },

        // ════════════════════════════════════════════════════════════════
        // SLS Penetration 分组 — O2O销售渗透率（比率类）
        // Act/LY: percent_1dp；vs LY: delta_bp（今年-去年，差值bp）
        // ColName 2 个空格
        // ════════════════════════════════════════════════════════════════
        { 7,  "SLS Penetration", "Act  ",    30, 21, "Act",   "payment", "percent_1dp", "percent_1dp", "delta_bp",    FALSE, "#1A9018", "#D64550", "#E1C233", "#5f6165" },
        { 8,  "SLS Penetration", "LY  ",     30, 22, "LY",    "payment", "percent_1dp", "percent_1dp", "delta_bp",    FALSE, "#1A9018", "#D64550", "#E1C233", "#5f6165" },
        { 9,  "SLS Penetration", "vs LY  ",  30, 23, "vs LY", "payment", "delta_bp",    "delta_bp",    "delta_bp",    FALSE, "#1A9018", "#D64550", "#E1C233", "#5f6165" },

        // ════════════════════════════════════════════════════════════════
        // Return 分组 — O2O退货金额（金额类）
        // Act/LY: currency；vs LY: percent_1dp（今年/去年-1）
        // ColName 3 个空格
        // ════════════════════════════════════════════════════════════════
        { 10, "Return",          "Act   ",    40, 31, "Act",   "payment", "currency",    "currency",    "percent_1dp", TRUE,  "#1A9018", "#D64550", "#E1C233", "#5f6165" },
        { 11, "Return",          "LY   ",     40, 32, "LY",    "payment", "currency",    "currency",    "percent_1dp", TRUE,  "#1A9018", "#D64550", "#E1C233", "#5f6165" },
        { 12, "Return",          "vs LY   ",  40, 33, "vs LY", "payment", "percent_1dp", "percent_1dp", "percent_1dp", TRUE,  "#1A9018", "#D64550", "#E1C233", "#5f6165" },

        // ════════════════════════════════════════════════════════════════
        // Return% 分组 — O2O退货率（金额）（比率类）
        // Act/LY: percent_1dp；vs LY: delta_bp（今年-去年，差值bp）
        // ColName 4 个空格
        // ════════════════════════════════════════════════════════════════
        { 13, "Return%",         "Act    ",    50, 41, "Act",   "payment", "percent_1dp", "percent_1dp", "delta_bp",    FALSE, "#1A9018", "#D64550", "#E1C233", "#5f6165" },
        { 14, "Return%",         "LY    ",     50, 42, "LY",    "payment", "percent_1dp", "percent_1dp", "delta_bp",    FALSE, "#1A9018", "#D64550", "#E1C233", "#5f6165" },
        { 15, "Return%",         "vs LY    ",  50, 43, "vs LY", "payment", "delta_bp",    "delta_bp",    "delta_bp",    FALSE, "#1A9018", "#D64550", "#E1C233", "#5f6165" }
    }
)
```

### 4.2 Sales PB Location Act Base Value（本期基础值）

```dax
Sales PB Location Act Base Value = 
// ========================================
// 度量值: Sales PB Location Act Base Value
// Display Folder: Base Metrics
// 用途: 根据 Metric_ID 路由到本期（Act）基础值
// 依赖: 'Dim_ColMetric_Sales_PB_Location'[Metric_ID, Metric_IsCurrencyAmount],
//       a02_e2e_boss_performance_summary_d
// 口径来源: Overview.md 子模块一 - Sales 分组（RowKPI_ID 10/20/30/40/50 的本期值）
// 筛选上下文:
//   - calc_type = "payment"（硬编码，Sales 分组固定）
//   - data_date ∈ [__TimeMin, __TimeMax]（全局时间范围）
//   - 分组维度由矩阵行字段自动传递，DAX 无需显式处理
//   - 金额类指标（Metric_IsCurrencyAmount=TRUE）÷ __FXRate（汇率）
// ========================================
    VAR __MetricID = SELECTEDVALUE('Dim_ColMetric_Sales_PB_Location'[Metric_ID])
    VAR __IsCurrencyAmount = SELECTEDVALUE('Dim_ColMetric_Sales_PB_Location'[Metric_IsCurrencyAmount], FALSE)
    // ── 时间筛选：本期 ──
    VAR __TimeMin = SELECTEDVALUE(Slicer_Time_Frame_Min[TimeFrame_Min])
    VAR __TimeMax = SELECTEDVALUE(Slicer_Time_Frame_Max[TimeFrame_Max])
    // ── 汇率（金额类指标需要除以汇率）──
    VAR __FXRate = SELECTEDVALUE(Slicer_Currency_Selection[Currency_ExchangeRate], 1)

    // ═══════════════════════════════════════
    // 基础聚合：calc_type = "payment"
    // ═══════════════════════════════════════
    // SLS O2O销售净额 = SUM(o2o_net_sales_amt)
    VAR __SLS_Act =
        CALCULATE(
            SUM('a02_e2e_boss_performance_summary_d'[o2o_net_sales_amt]),
            'a02_e2e_boss_performance_summary_d'[calc_type] = "payment",
            'a02_e2e_boss_performance_summary_d'[data_date] >= __TimeMin,
            'a02_e2e_boss_performance_summary_d'[data_date] <= __TimeMax
        )
    // Demand SLS O2O退前销售额 = SUM(o2o_sales_amt)
    VAR __DemandSLS_Act =
        CALCULATE(
            SUM('a02_e2e_boss_performance_summary_d'[o2o_sales_amt]),
            'a02_e2e_boss_performance_summary_d'[calc_type] = "payment",
            'a02_e2e_boss_performance_summary_d'[data_date] >= __TimeMin,
            'a02_e2e_boss_performance_summary_d'[data_date] <= __TimeMax
        )
    // SLS Penetration O2O销售渗透率 分子 o2o_sales_amt，分母 sales_amt
    VAR __SLS_Penetration_Numerator_Act =
        CALCULATE(
            SUM('a02_e2e_boss_performance_summary_d'[o2o_sales_amt]),
            'a02_e2e_boss_performance_summary_d'[calc_type] = "payment",
            'a02_e2e_boss_performance_summary_d'[data_date] >= __TimeMin,
            'a02_e2e_boss_performance_summary_d'[data_date] <= __TimeMax
        )
    VAR __SLS_Penetration_Denominator_Act =
        CALCULATE(
            SUM('a02_e2e_boss_performance_summary_d'[sales_amt]),
            'a02_e2e_boss_performance_summary_d'[calc_type] = "payment",
            'a02_e2e_boss_performance_summary_d'[data_date] >= __TimeMin,
            'a02_e2e_boss_performance_summary_d'[data_date] <= __TimeMax
        )
    VAR __SLS_Penetration_Act = DIVIDE(__SLS_Penetration_Numerator_Act, __SLS_Penetration_Denominator_Act)
    // Return O2O退货金额 = SUM(o2o_return_amt)
    VAR __Return_Act =
        CALCULATE(
            SUM('a02_e2e_boss_performance_summary_d'[o2o_return_amt]),
            'a02_e2e_boss_performance_summary_d'[calc_type] = "payment",
            'a02_e2e_boss_performance_summary_d'[data_date] >= __TimeMin,
            'a02_e2e_boss_performance_summary_d'[data_date] <= __TimeMax
        )
    // Return% O2O退货率 分子 o2o_return_amt，分母 o2o_sales_amt
    VAR __Return_Pct_Numerator_Act =
        CALCULATE(
            SUM('a02_e2e_boss_performance_summary_d'[o2o_return_amt]),
            'a02_e2e_boss_performance_summary_d'[calc_type] = "payment",
            'a02_e2e_boss_performance_summary_d'[data_date] >= __TimeMin,
            'a02_e2e_boss_performance_summary_d'[data_date] <= __TimeMax
        )
    VAR __Return_Pct_Denominator_Act =
        CALCULATE(
            SUM('a02_e2e_boss_performance_summary_d'[o2o_sales_amt]),
            'a02_e2e_boss_performance_summary_d'[calc_type] = "payment",
            'a02_e2e_boss_performance_summary_d'[data_date] >= __TimeMin,
            'a02_e2e_boss_performance_summary_d'[data_date] <= __TimeMax
        )
    VAR __Return_Pct_Act = DIVIDE(__Return_Pct_Numerator_Act, __Return_Pct_Denominator_Act)

    // ═══════════════════════════════════════
    // 路由分发（按 Metric_ID）
    // 金额类指标 ÷ __FXRate（汇率换算）
    // ═══════════════════════════════════════
    RETURN
        SWITCH(
            __MetricID,
            1,  IF(__IsCurrencyAmount, DIVIDE(__SLS_Act, __FXRate), __SLS_Act),                         // SLS Act
            4,  IF(__IsCurrencyAmount, DIVIDE(__DemandSLS_Act, __FXRate), __DemandSLS_Act),             // Demand SLS Act
            7,  __SLS_Penetration_Act,                                                                    // SLS Penetration Act
            10, IF(__IsCurrencyAmount, DIVIDE(__Return_Act, __FXRate), __Return_Act),                    // Return Act
            13, __Return_Pct_Act,                                                                         // Return% Act
            BLANK()
        )
```

### 4.3 Sales PB Location LY Base Value（去年同期基础值，财历映射）

```dax
Sales PB Location LY Base Value = 
// ========================================
// 度量值: Sales PB Location LY Base Value
// Display Folder: Base Metrics
// 用途: 根据 Metric_ID 路由到去年同期（LY）基础值
// 依赖: 'Dim_ColMetric_Sales_PB_Location'[Metric_ID, Metric_IsCurrencyAmount],
//       Slicer_Time_Frame_Min/Max[TimeFrame_Min_LY, TimeFrame_Max_LY],
//       a02_e2e_boss_performance_summary_d
// 口径来源: Overview.md 子模块一 - Sales 分组（LY 值）
// 时间偏移: 财历映射（直接读取日期表内置 LY 字段）
//   - 全局 LY 起始日: SELECTEDVALUE(Slicer_Time_Frame_Min[TimeFrame_Min_LY])
//   - 全局 LY 结束日: SELECTEDVALUE(Slicer_Time_Frame_Max[TimeFrame_Max_LY])
//   - 无需 EDATE -12 或 Key 偏移计算
// 金额类指标 ÷ __FXRate（汇率换算）
// 前提: 日期表需包含去年同期数据，否则返回 BLANK
// ========================================
    VAR __MetricID = SELECTEDVALUE('Dim_ColMetric_Sales_PB_Location'[Metric_ID])
    VAR __IsCurrencyAmount = SELECTEDVALUE('Dim_ColMetric_Sales_PB_Location'[Metric_IsCurrencyAmount], FALSE)
    // ── 直接读取日期表内置的 LY 时间范围 ──
    VAR __LYTimeMin = SELECTEDVALUE(Slicer_Time_Frame_Min[TimeFrame_Min_LY])
    VAR __LYTimeMax = SELECTEDVALUE(Slicer_Time_Frame_Max[TimeFrame_Max_LY])
    // ── 汇率 ──
    VAR __FXRate = SELECTEDVALUE(Slicer_Currency_Selection[Currency_ExchangeRate], 1)

    // ═══════════════════════════════════════
    // 基础聚合：calc_type = "payment"（去年同期）
    // ═══════════════════════════════════════
    VAR __SLS_LY =
        CALCULATE(
            SUM('a02_e2e_boss_performance_summary_d'[o2o_net_sales_amt]),
            'a02_e2e_boss_performance_summary_d'[calc_type] = "payment",
            'a02_e2e_boss_performance_summary_d'[data_date] >= __LYTimeMin,
            'a02_e2e_boss_performance_summary_d'[data_date] <= __LYTimeMax
        )
    VAR __DemandSLS_LY =
        CALCULATE(
            SUM('a02_e2e_boss_performance_summary_d'[o2o_sales_amt]),
            'a02_e2e_boss_performance_summary_d'[calc_type] = "payment",
            'a02_e2e_boss_performance_summary_d'[data_date] >= __LYTimeMin,
            'a02_e2e_boss_performance_summary_d'[data_date] <= __LYTimeMax
        )
    VAR __SLS_Penetration_Numerator_LY =
        CALCULATE(
            SUM('a02_e2e_boss_performance_summary_d'[o2o_sales_amt]),
            'a02_e2e_boss_performance_summary_d'[calc_type] = "payment",
            'a02_e2e_boss_performance_summary_d'[data_date] >= __LYTimeMin,
            'a02_e2e_boss_performance_summary_d'[data_date] <= __LYTimeMax
        )
    VAR __SLS_Penetration_Denominator_LY =
        CALCULATE(
            SUM('a02_e2e_boss_performance_summary_d'[sales_amt]),
            'a02_e2e_boss_performance_summary_d'[calc_type] = "payment",
            'a02_e2e_boss_performance_summary_d'[data_date] >= __LYTimeMin,
            'a02_e2e_boss_performance_summary_d'[data_date] <= __LYTimeMax
        )
    VAR __SLS_Penetration_LY = DIVIDE(__SLS_Penetration_Numerator_LY, __SLS_Penetration_Denominator_LY)
    VAR __Return_LY =
        CALCULATE(
            SUM('a02_e2e_boss_performance_summary_d'[o2o_return_amt]),
            'a02_e2e_boss_performance_summary_d'[calc_type] = "payment",
            'a02_e2e_boss_performance_summary_d'[data_date] >= __LYTimeMin,
            'a02_e2e_boss_performance_summary_d'[data_date] <= __LYTimeMax
        )
    VAR __Return_Pct_Numerator_LY =
        CALCULATE(
            SUM('a02_e2e_boss_performance_summary_d'[o2o_return_amt]),
            'a02_e2e_boss_performance_summary_d'[calc_type] = "payment",
            'a02_e2e_boss_performance_summary_d'[data_date] >= __LYTimeMin,
            'a02_e2e_boss_performance_summary_d'[data_date] <= __LYTimeMax
        )
    VAR __Return_Pct_Denominator_LY =
        CALCULATE(
            SUM('a02_e2e_boss_performance_summary_d'[o2o_sales_amt]),
            'a02_e2e_boss_performance_summary_d'[calc_type] = "payment",
            'a02_e2e_boss_performance_summary_d'[data_date] >= __LYTimeMin,
            'a02_e2e_boss_performance_summary_d'[data_date] <= __LYTimeMax
        )
    VAR __Return_Pct_LY = DIVIDE(__Return_Pct_Numerator_LY, __Return_Pct_Denominator_LY)

    // ═══════════════════════════════════════
    // 路由分发（按 Metric_ID）
    // 金额类指标 ÷ __FXRate（汇率换算）
    // ═══════════════════════════════════════
    RETURN
        SWITCH(
            __MetricID,
            2,  IF(__IsCurrencyAmount, DIVIDE(__SLS_LY, __FXRate), __SLS_LY),                           // SLS LY
            5,  IF(__IsCurrencyAmount, DIVIDE(__DemandSLS_LY, __FXRate), __DemandSLS_LY),               // Demand SLS LY
            8,  __SLS_Penetration_LY,                                                                    // SLS Penetration LY
            11, IF(__IsCurrencyAmount, DIVIDE(__Return_LY, __FXRate), __Return_LY),                     // Return LY
            14, __Return_Pct_LY,                                                                         // Return% LY
            BLANK()
        )
```

### 4.4 Sales PB Location Base Value（总路由）

```dax
Sales PB Location Base Value = 
// ========================================
// 度量值: Sales PB Location Base Value
// Display Folder: Base Metrics
// 用途: 总路由，根据 Metric_ID 分发到 Act / LY / vs LY
// 依赖: [Sales PB Location Act Base Value], [Sales PB Location LY Base Value],
//       'Dim_ColMetric_Sales_PB_Location'[Metric_ID, Metric_Format_VsLY]
// 说明:
//   Metric_ID 1/4/7/10/13  → Act
//   Metric_ID 2/5/8/11/14  → LY
//   Metric_ID 3/6/9/12/15  → vs LY（派生计算）
//
// vs LY 派生规则:
//   - 金额类（SLS / Demand SLS / Return）：今年 / 去年 − 1（percent_1dp）
//   - 比率类（SLS Penetration / Return%）：今年 − 去年（差值，展示时 ×10000 转 bp）
//
// REMOVEFILTERS 机制（参考 KPI by Platform_matrix_solution.md）:
//   矩阵行标题会保留断开维度的所有列筛选器，
//   仅覆盖 Metric_ID 会导致筛选条件冲突（如 Metric_ID=1 AND ColName="vs LY"）从而返回 BLANK。
//   因此 vs LY 行需先 REMOVEFILTERS 清除断开维度的所有筛选，再应用目标 Metric_ID。
// ========================================
    VAR __MetricID = SELECTEDVALUE('Dim_ColMetric_Sales_PB_Location'[Metric_ID])
    VAR __FormatVsLY = SELECTEDVALUE('Dim_ColMetric_Sales_PB_Location'[Metric_Format_VsLY])
    // 判断当前是否为 vs LY 行
    VAR __IsVsLY = __MetricID IN {3, 6, 9, 12, 15}

    // 修复上下文冲突：vs LY 行需要取 Act 和 LY 的值做派生计算，
    // 但当前筛选上下文下 Metric_ID 指向 vs LY 行，
    // 直接调用 Act/LY 度量会因 Metric_ID 不匹配而返回 BLANK。
    // 解决方案：先 REMOVEFILTERS 清除断开维度的所有筛选，再应用目标 Metric_ID。
    VAR __ActValue = 
        IF(
            __IsVsLY,
            CALCULATE(
                [Sales PB Location Act Base Value], 
                REMOVEFILTERS('Dim_ColMetric_Sales_PB_Location'), 
                'Dim_ColMetric_Sales_PB_Location'[Metric_ID] = __MetricID - 2
            ),
            [Sales PB Location Act Base Value]
        )

    VAR __LYValue = 
        IF(
            __IsVsLY,
            CALCULATE(
                [Sales PB Location LY Base Value], 
                REMOVEFILTERS('Dim_ColMetric_Sales_PB_Location'), 
                'Dim_ColMetric_Sales_PB_Location'[Metric_ID] = __MetricID - 1
            ),
            [Sales PB Location LY Base Value]
        )

    // ── vs LY 派生计算 ──
    // percent_1dp（金额类）：今年 / 去年 − 1
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
            1,  __ActValue,     // SLS Act
            4,  __ActValue,     // Demand SLS Act
            7,  __ActValue,     // SLS Penetration Act
            10, __ActValue,     // Return Act
            13, __ActValue,     // Return% Act
            // ─── LY 去年同期值 ───
            2,  __LYValue,      // SLS LY
            5,  __LYValue,      // Demand SLS LY
            8,  __LYValue,      // SLS Penetration LY
            11, __LYValue,      // Return LY
            14, __LYValue,      // Return% LY
            // ─── vs LY 派生值 ───
            3,  __VSLYGrowth,   // SLS vs LY（percent_1dp）
            6,  __VSLYGrowth,   // Demand SLS vs LY（percent_1dp）
            9,  __VSLYDiff,     // SLS Penetration vs LY（delta_bp，差值）
            12, __VSLYGrowth,   // Return vs LY（percent_1dp）
            15, __VSLYDiff,     // Return% vs LY（delta_bp，差值）
            BLANK()
        )
```

### 4.5 Sales PB Location Cell Value（对外值）

```dax
Sales PB Location Cell Value = 
// ========================================
// 度量值: Sales PB Location Cell Value
// Display Folder: Cell Values
// 用途: 对外暴露的单元格值，等于 Base Value
// 依赖: [Sales PB Location Base Value]
// ========================================
    [Sales PB Location Base Value]
```

### 4.6 Sales PB Location Cell Display（格式化显示）

```dax
Sales PB Location Cell Display = 
// ========================================
// 度量值: Sales PB Location Cell Display
// Display Folder: Formatting
// 用途: 按 ColType 选择对应行格式格式化显示
// 依赖: [Sales PB Location Cell Value],
//       'Dim_ColMetric_Sales_PB_Location'[ColType, Metric_Format_Act/LY/VsLY]
// 格式类型:
//   currency    → 货币符号 + 千分位整数：¥1,000
//   percent_1dp → 百分比一位小数，不含正号：14.5%
//   delta_bp    → 增减基点整数，含正负号：+120bp
//                 （值×10000 转 bp 的操作在此处实现）
// ========================================
    VAR __Value = [Sales PB Location Cell Value]
    VAR __ColType = SELECTEDVALUE('Dim_ColMetric_Sales_PB_Location'[ColType])
    // ── 按 ColType 选择对应行格式 ──
    VAR __Format =
        SWITCH(
            __ColType,
            "Act",   SELECTEDVALUE('Dim_ColMetric_Sales_PB_Location'[Metric_Format_Act]),
            "LY",    SELECTEDVALUE('Dim_ColMetric_Sales_PB_Location'[Metric_Format_LY]),
            "vs LY", SELECTEDVALUE('Dim_ColMetric_Sales_PB_Location'[Metric_Format_VsLY]),
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
                // ─── 百分比（不含正号）──────────────────────
                "percent_1dp",
                    FORMAT(__Value, "#,##0.0%"),                                                               // 14.5%
                // ─── 增减基点（含正负号，值×10000 转 bp）─────
                "delta_bp",
                    IF(ROUND(__Value * 10000, 0) > 0, "+", "") & FORMAT(__Value * 10000, "#,##0bp;-#,##0bp;0bp"), // +120bp
                // ─── 默认 ─────────────────────────────────
                FORMAT(__Value, "#,##0.00")
            )
        )
```

### 4.7 Sales PB Location Cell Font Color（字体颜色）

```dax
Sales PB Location Cell Font Color = 
// ========================================
// 度量值: Sales PB Location Cell Font Color
// Display Folder: Formatting
// 用途: 区分 KPIGroup 行（分组标题行）与 KPI 行，并对 vs LY 列启用正/负/零三色
// 依赖: [Sales PB Location Cell Value],
//       'Dim_ColMetric_Sales_PB_Location'[ColType, Metric_ColorPositive/Negative/Zero/Default],
//       ISINSCOPE('Dim_ColMetric_Sales_PB_Location'[ColName])
// 层级判断:
//   ISINSCOPE('Dim_ColMetric_Sales_PB_Location'[ColName]) = TRUE  → KPI 行（具体指标行）
//   ISINSCOPE('Dim_ColMetric_Sales_PB_Location'[ColName]) = FALSE → KPIGroup 行（分组标题行）
// 颜色规则:
//   ┌─────────────┬───────────────────┬──────────────────────────────────────┐
//   │             │  vs LY 列         │  其他列（Act / LY）                  │
//   ├─────────────┼───────────────────┼──────────────────────────────────────┤
//   │  KPI 行     │  正#1A9018/负#D64550/零#E1C233/默认#5F6165  │  #5F6165（深灰）│
//   │  KPIGroup 行│  #252423（黑色）  │  #252423（黑色）                     │
//   └─────────────┴───────────────────┴──────────────────────────────────────┘
// ========================================
    VAR __Value = [Sales PB Location Cell Value]
    VAR __ColType = SELECTEDVALUE('Dim_ColMetric_Sales_PB_Location'[ColType])
    VAR __IsKPIRow = ISINSCOPE('Dim_ColMetric_Sales_PB_Location'[ColName])
    // ── 颜色取值（来自列维度表）──
    VAR __ColorPositive = SELECTEDVALUE('Dim_ColMetric_Sales_PB_Location'[Metric_ColorPositive], "#1A9018")
    VAR __ColorNegative = SELECTEDVALUE('Dim_ColMetric_Sales_PB_Location'[Metric_ColorNegative], "#D64550")
    VAR __ColorZero = SELECTEDVALUE('Dim_ColMetric_Sales_PB_Location'[Metric_ColorZero], "#E1C233")
    VAR __ColorDefault = SELECTEDVALUE('Dim_ColMetric_Sales_PB_Location'[Metric_ColorDefault], "#5F6165")

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

### 4.8 Sales PB Location Cell Background Color（背景色）

```dax
Sales PB Location Cell Background Color = 
// ========================================
// 度量值: Sales PB Location Cell Background Color
// Display Folder: Formatting
// 用途: 区分 KPIGroup 行（分组标题行）与 KPI 行的背景色
// 依赖: ISINSCOPE('Dim_ColMetric_Sales_PB_Location'[ColName])
// 颜色规则:
//   KPIGroup 行（分组标题行）: #E6D9C7（中米色）
//   KPI 行（具体指标行）     : #FFFFFF（白色）
// ========================================
    VAR __IsKPIRow = ISINSCOPE('Dim_ColMetric_Sales_PB_Location'[ColName])
    RETURN
        IF(
            __IsKPIRow,
            "#FFFFFF",   // KPI 行：白色
            "#E6D9C7"    // KPIGroup 行：中米色
        )
```

### 4.9 Sales PB Location Cell SVG Icon（SVG 图标）

```dax
Sales PB Location Cell SVG Icon = 
// ========================================
// 度量值: Sales PB Location Cell SVG Icon
// Display Folder: Formatting
// 用途: 仅 vs LY 列 + KPI 行返回 SVG 圆形图标
// 依赖: [Sales PB Location Cell Value],
//       'Dim_ColMetric_Sales_PB_Location'[ColType, Metric_ColorPositive/Negative/Zero]
// 配置: 需将此度量值的数据类别设为"图像 URL"
// 图标规则:
//   ┌─────────────┬──────────────────────────────────────┐
//   │             │  vs LY 列                            │
//   ├─────────────┼──────────────────────────────────────┤
//   │  KPI 行     │  正→绿圆 / 负→红圆 / 零→黄圆         │
//   │  KPIGroup 行│  不显示（BLANK）                     │
//   └─────────────┴──────────────────────────────────────┘
//   其他列（Act / LY）：不显示（BLANK）
// 颜色与 Font Color 保持一致（取自 Dim_ColMetric_Sales_PB_Location 的颜色字段）
// ========================================
    VAR __Value = [Sales PB Location Cell Value]
    VAR __ColType = SELECTEDVALUE('Dim_ColMetric_Sales_PB_Location'[ColType])
    VAR __IsKPIRow = ISINSCOPE('Dim_ColMetric_Sales_PB_Location'[ColName])
    // ── 启用图标条件：vs LY 列 + KPI 行 ──
    VAR __NeedsIcon = __ColType = "vs LY" && __IsKPIRow
    // ── 颜色取值（来自列维度表）──
    VAR __ColorPositive = SELECTEDVALUE('Dim_ColMetric_Sales_PB_Location'[Metric_ColorPositive], "#1A9018")
    VAR __ColorNegative = SELECTEDVALUE('Dim_ColMetric_Sales_PB_Location'[Metric_ColorNegative], "#D64550")
    VAR __ColorZero = SELECTEDVALUE('Dim_ColMetric_Sales_PB_Location'[Metric_ColorZero], "#E1C233")
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
| 1 | Sales PB Location Act Base Value | Base Metrics | 本期基础值（Metric_ID 1/4/7/10/13） |
| 2 | Sales PB Location LY Base Value | Base Metrics | 去年同期基础值（财历映射，Metric_ID 2/5/8/11/14） |
| 3 | Sales PB Location Base Value | Base Metrics | 总路由（含 vs LY 派生 + REMOVEFILTERS） |
| 4 | Sales PB Location Cell Value | Cell Values | 对外值 = Base Value |
| 5 | Sales PB Location Cell Display | Formatting | 格式化显示文本 |
| 6 | Sales PB Location Cell Font Color | Formatting | 字体颜色 |
| 7 | Sales PB Location Cell Background Color | Formatting | 背景色 |
| 8 | Sales PB Location Cell SVG Icon | Formatting | SVG 图标（仅 vs LY 列 + KPI 行） |

---

## 6. 血缘关系图

```
┌─────────────────────────────────────────────────────────────────────┐
│                        数据源层                                      │
│  a02_e2e_boss_performance_summary_d（事实表）                        │
│  字段: data_date, store_name, calc_type,                            │
│        o2o_net_sales_amt, o2o_sales_amt, sales_amt, o2o_return_amt  │
└──────────────────────────────┬──────────────────────────────────────┘
                               │
                               │ 模型自动传递（行维度 = 事实表字段直接拉取）
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────────┐
│                        度量值层                                      │
│                                                                     │
│  ┌───────────────────────────────────┐   ┌───────────────────────┐  │
│  │ Sales PB Location Act Base Value  │   │ Sales PB Location     │  │
│  │ (本期 5 个 KPI)                    │   │ LY Base Value         │  │
│  └───────────────┬───────────────────┘   │ (LY 5 个 KPI, 财历映射)│  │
│                  │                        └───────────┬───────────┘  │
│                  │    ┌───────────────────────────────┘              │
│                  │    │                                              │
│                  ▼    ▼                                              │
│  ┌───────────────────────────────────┐   ┌───────────────────────┐  │
│  │ Sales PB Location Base Value      │   │ Dim_ColMetric_Sales_  │  │
│  │ (总路由 + vs LY 派生)              │◄──│ PB_Location           │  │
│  │ REMOVEFILTERS + 目标 Metric_ID     │   │ (断开维度，Metric_ID) │  │
│  └───────────────┬───────────────────┘   └───────────────────────┘  │
│                  │                                                  │
│                  ▼                                                  │
│  ┌───────────────────────────────────┐                              │
│  │ Sales PB Location Cell Value      │                              │
│  │ (= Base Value)                    │                              │
│  └───────────────┬───────────────────┘                              │
│                  │                                                  │
│                  ▼                                                  │
│  ┌───────────────────────────────────┐   ┌───────────────────────┐  │
│  │ Sales PB Location Cell Display    │◄──│ Dim_ColMetric_Sales_  │  │
│  │ (格式化文本)                       │   │ PB_Location           │  │
│  └───────────────┬───────────────────┘   │ (ColType, Format_*)   │  │
│                  │                        └───────────────────────┘  │
│                  ▼                                                  │
│  ┌─────────────────────────────────────────────────────┐            │
│  │  Sales PB Location Cell Font Color                   │            │
│  │  Sales PB Location Cell Background Color             │            │
│  │  Sales PB Location Cell SVG Icon                     │            │
│  │  (条件格式度量值，ISINSCOPE 判断 KPIGroup/KPI 行)     │            │
│  └─────────────────────────────────────────────────────┘            │
└─────────────────────────────────────────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────────┐
│                        可视化层                                      │
│  Matrix 视觉对象                                                     │
│  行: 事实表字段（store_region / store_type / store_name 等，直接拉取）│
│  列: 'Dim_ColMetric_Sales_PB_Location'[KPIGroup]                    │
│      > 'Dim_ColMetric_Sales_PB_Location'[ColName]                   │
│  值: [Sales PB Location Cell Display]                                │
│  条件格式:                                                           │
│    字体颜色 → [Sales PB Location Cell Font Color]                   │
│    背景色   → [Sales PB Location Cell Background Color]             │
│    SVG 图标 → [Sales PB Location Cell SVG Icon]（数据类别=图像 URL） │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 7. 矩阵视觉对象配置

### 7.1 字段配置

| 区域 | 字段 |
|------|------|
| **行** | 事实表字段（store_region / store_type / store_name 等，直接拉取） |
| **列** | 'Dim_ColMetric_Sales_PB_Location'[KPIGroup] > [ColName] |
| **值** | [Sales PB Location Cell Display] |

### 7.2 排序配置

| 字段 | 排序依据 |
|------|---------|
| 'Dim_ColMetric_Sales_PB_Location'[KPIGroup] | KPIGroup_Sort |
| 'Dim_ColMetric_Sales_PB_Location'[ColName] | ColName_Sort |

### 7.3 格式设置

- 关闭"阶梯布局"（Stepped Layout → Off）
- 关闭"+/-"展开按钮
- 列标题：居中对齐，加粗
- 行标题：左对齐
- 值：居中对齐

### 7.4 条件格式

对 [Sales PB Location Cell Display] 值区域设置：

1. **字体颜色**：右键值区域 → 条件格式 → 字体颜色 → 格式样式：字段值 → 基于字段：[Sales PB Location Cell Font Color]
2. **背景颜色**：右键值区域 → 条件格式 → 背景颜色 → 格式样式：字段值 → 基于字段：[Sales PB Location Cell Background Color]
3. **SVG 图标**（可选）：将 [Sales PB Location Cell SVG Icon] 度量值的数据类别设为"图像 URL"

---

## 8. 验证方法

### 8.1 矩阵结构验证

| 验证项 | 方法 |
|--------|------|
| 列数 | 确认 15 列（5 KPI 分组 × 3 列） |
| 列排序 | KPIGroup 按 KPIGroup_Sort（10/20/30/40/50），ColName 按 ColName_Sort |
| 同名区分 | 确认 5 个 Act / 5 个 LY / 5 个 vs LY 行名后缀空格数不同 |
| KPIGroup 行颜色 | 字体黑色 #252423，背景中米色 #E6D9C7 |
| KPI 行颜色 | 非 vs LY 列字体深灰 #5F6165，背景白色 #FFFFFF；vs LY 列正/负/零三色 |
| SVG 图标 | 仅 vs LY 列 + KPI 行显示圆形图标 |

### 8.2 验证 SQL

```sql
-- SLS O2O销售净额（本期，所有 store 汇总）
-- 假设 __TimeMin='2025-06-29', __TimeMax='2025-08-09'
SELECT SUM(o2o_net_sales_amt) AS SLS_Actual
FROM a02_e2e_boss_performance_summary_d
WHERE calc_type = 'payment'
  AND data_date BETWEEN '2025-06-29' AND '2025-08-09';

-- SLS O2O销售净额（去年同期，LY 日期范围来自日期表 ly_timeframe_min / ly_timeframe_max）
SELECT SUM(o2o_net_sales_amt) AS SLS_LY
FROM a02_e2e_boss_performance_summary_d
WHERE calc_type = 'payment'
  AND data_date BETWEEN '__LYTimeMin' AND '__LYTimeMax';

-- SLS vs LY = SLS_Actual / SLS_LY - 1（percent_1dp）

-- SLS Penetration O2O销售渗透率（本期）
SELECT
  SUM(o2o_sales_amt) / SUM(sales_amt) AS SLS_Penetration_Actual
FROM a02_e2e_boss_performance_summary_d
WHERE calc_type = 'payment'
  AND data_date BETWEEN '__TimeMin' AND '__TimeMax';

-- SLS Penetration vs LY = SLS_Penetration_Actual - SLS_Penetration_LY（delta_bp，×10000 转 bp）

-- Return% O2O退货率（本期）
SELECT
  SUM(o2o_return_amt) / SUM(o2o_sales_amt) AS Return_Pct_Actual
FROM a02_e2e_boss_performance_summary_d
WHERE calc_type = 'payment'
  AND data_date BETWEEN '__TimeMin' AND '__TimeMax';

-- Return% vs LY = Return_Pct_Actual - Return_Pct_LY（delta_bp，×10000 转 bp）
```

### 8.3 LY 日期范围获取方式说明

| TimeFrame_ID | LY 范围获取方式 | 说明 |
|--------------|-----------------|------|
| Day / Week / Month / Quarter / Year | 直接读日期表 `ly_timeframe_min` / `ly_timeframe_max` | 日期表已内置，无需 EDATE -12 或 Key 偏移 |

---

## 9. 注意事项

1. **REMOVEFILTERS 机制**：vs LY 行的派生计算必须先 `REMOVEFILTERS('Dim_ColMetric_Sales_PB_Location')` 再应用目标 Metric_ID，否则矩阵行标题保留的筛选器会导致冲突返回 BLANK。这与 KPI by Platform_matrix_solution.md 的总路由范式完全一致。

2. **Metric_ID 编码规则**：KPI分组序号×3 + 列偏移（0=Act, 1=LY, 2=vsLY），vs LY 行的 Act 对应 Metric_ID - 2，LY 对应 Metric_ID - 1。

3. **calc_type 固定**：本方案所有度量值均硬编码 `calc_type = "payment"`，与 Overview_KPIs_ms.md 中通过 KPI_CalcType 动态读取不同。

4. **LY 财历映射**：周/月/季/年粒度按财年定义，LY 采用财历映射（直接读取日期表内置 TimeFrame_Min_LY / TimeFrame_Max_LY 字段），不使用 EDATE -12。

5. **汇率换算**：金额类指标 ÷ Currency_ExchangeRate；比率类分子分母同币种相除自动抵消。vs LY 同比值因相除/相减自动抵消汇率影响。

6. **vs LY 派生分类**：
   - 金额类（SLS / Demand SLS / Return）：今年 / 去年 − 1 → percent_1dp
   - 比率类（SLS Penetration / Return%）：今年 − 去年 → delta_bp（展示时 ×10000 转 bp）

7. **行维度处理**：无行维度表，直接拉取事实表字段（store_region / store_type / store_name 等），天然形成筛选与分组，DAX 度量值无需显式处理。

8. **与 PB_Location_Sales_detail.md 的关系**：本方案为矩阵 SWITCH 路由版本，detail.md 为独立度量版本。两者口径完全一致，仅度量组织方式不同。本方案通过列维度表 + 总路由实现矩阵效果，度量值数量更少（8 个 vs 30 个）。

9. **与 Overview_KPIs_ms.md 差异**：
   - 去除 Dim_RowKPIs_BossCoreKPI_Overview（行维度）依赖，行维度由事实表字段直接拉取
   - 去除 Dim_ColKPIs_BossCoreKPI_Overview（列维度）依赖及 StoreGroup_ID → store_name 筛选
   - 去除 Slicer_Fulfillment_Calc_Type 依赖
   - 新建 Dim_ColMetric_Sales_PB_Location 列维度表，将行维度（KPI 分组 + 格式）和列维度（列类型 + 颜色）合并
   - calc_type 由动态读取改为硬编码 "payment"
