# Power BI 中国式报表解决方案 — 多层级 KPI Breakdown 矩阵

> status: propose
> created: 2026-04-14
> updated: 2026-04-14
> complexity: 🔴复杂
> type: 度量值开发 + 可视化构建
> naming: 遵循 powerbi_code_copilot/rules/dax-style.md 规范

---

## 1. 需求理解

实现一个"KPI Breakdown"多层级矩阵效果：
- **行**：3 级层次结构 — Brand(M Polo/W Polo/Total) > Framework(Acceleration/Foundation...) > Category(Outerwear/Sweatshirt...)
  - Total 作为 Brand 的一个值（与 M Polo/W Polo 同级，位于最后）
  - Total 行的 Framework/Category 为空，事实表中无此字段值
- **列**：2 级层次结构 — MetricGroup > MetricName
  - SLS: Cost% vs SLS%, SLS%
  - Cost MOB%: Total, 直通车, 引力魔方, 全站推
  - ROI: Total, 直通车, 引力魔方, 全站推
  - New Customer Cost%: Total, 直通车, 引力魔方, 全站推
- **值**：静态占位值 = RowKPI_ID × ColMetric_ID，未来逐个替换为 CALCULATE 引用真实度量值
- **特殊要求**：
  - SWITCH 按列头（__SelR1 一级、__SelR2 二级）分发，方便逐个替换
  - Total 行单独判断（不筛选事实表行字段）
  - 不同列格式不同（delta_pt + SVG 图标、percent、number）
  - 参差层级（T-shirt、Complemen 为 Framework 级叶节点，无 Category 子级）
  - 所有排序起始值从 7 开始（遵循 domain-rules.md）

---

## 2. 整体架构

```
核心思路：双维度断开 + 列头 SWITCH 分发 + ISINSCOPE 层级检测

Dim_RowKPI_KpiBreakdown（行维度表）      Dim_ColMetric_KpiBreakdown（列维度表）
    │                                           │
    │  断开维度，无关系连接                      │  断开维度，无关系连接
    │                                           │
    ▼                                           ▼
    ┌───────────────── Matrix 视觉对象 ────────────────────┐
    │  行 = Brand > Framework > Category（3 级层次）        │
    │  列 = MetricGroup > MetricName（2 级层次）            │
    │  值 = [KPI Breakdown Cell Value]                     │
    │        ↓ SWITCH(__SelR1, __SelR2) 分发到 14 个指标    │
    │        ↓ 行上下文: __Brand, __Framework, __Category   │
    │        ↓ __IsTotal 时不筛选事实表行字段               │
    └──────────────────────────────────────────────────────┘
```

### 关键技术点

1. **列头 SWITCH 分发**：度量值先提取列上下文 `__SelR1`（MetricGroup）和 `__SelR2`（MetricName），
   通过 SWITCH(TRUE(), __SelR1 = "SLS" && __SelR2 = "Cost% vs SLS%", ...) 分发到 14 个指标，
   每个分支可独立替换为真实 CALCULATE 表达式
2. **Total 行前置分支**：事实表无 "Total" 字段值，通过 `IF(__IsTotal)` 前置判断，
   Total 和非 Total 各自拥有独立 SWITCH 分发块；Total 分支未来直接调用基础度量值（不加 CALCULATE 行筛选），
   非 Total 分支未来替换为 `CALCULATE([度量值], 事实表行筛选条件)`
3. **参差层级处理**：T-shirt、Complemen 是 Framework 级叶节点（无 Category 子级），
   通过 Category = Framework 同名占位 + 度量值返回 BLANK() 抑制冗余子行
4. **占位值**：静态阶段 Cell Value = RowKPI_ID × ColMetric_ID（非递增值），
   小计行使用 SUM(RowKPI_ID) × ColMetric_ID

---

## 3. 命名规范映射

> 遵循 `powerbi_code_copilot/rules/dax-style.md`

| 类别 | 命名 | 规则 |
|------|------|------|
| 行维度表 | `Dim_RowKPI_KpiBreakdown` | Dim_ 前缀 + _矩阵名 后缀，区分不同矩阵 |
| 列维度表 | `Dim_ColMetric_KpiBreakdown` | Dim_ 前缀 + _矩阵名 后缀 |
| 度量值表 | `_Measures` | _ 前缀 — 隐藏辅助表 |
| 度量值 | `KPI Breakdown Cell Value` 等 | 带矩阵名称前缀，区分不同矩阵的度量值 |
| 主键列 | `RowKPI_ID`, `ColMetric_ID` | Key/ID 后缀 |
| 行属性列 | `Brand`, `Framework`, `Category` | PascalCase |
| 排序列 | `Brand_Sort`, `Framework_Sort`, `Category_Sort` 等 | _Sort 后缀 |
| 列上下文变量 | `__SelR1`, `__SelR2` | 一级/二级列头 |
| 行上下文变量 | `__Brand`, `__Framework`, `__Category` | 行筛选用变量 |
| 特殊标识变量 | `__IsTotal` | Total 行判断 |

---

## 4. 实施步骤

### Step 1: 创建度量值表 `_Measures`

```dax
// ========================================
// 表: _Measures
// 类型: 隐藏辅助表（_ 前缀）
// 用途: 存放所有度量值的容器表
// 说明: 创建后隐藏 Value 列，仅保留度量值
// ========================================
_Measures = {BLANK()}
```

创建后在"数据"视图中右键 `_Measures[Value]` 列 → 隐藏。

### Step 2: 创建行维度表 `Dim_RowKPI_KpiBreakdown`（DAX 计算表）

```dax
Dim_RowKPI_KpiBreakdown = 
// ========================================
// 表: Dim_RowKPI_KpiBreakdown
// 类型: 维度表（Dim_ 前缀），断开维度
// 用途: 定义 3 级行层次结构
//   Level 1 (Brand):     M Polo, W Polo, Total
//   Level 2 (Framework): Acceleration, Foundation, T-shirt, Complemen
//   Level 3 (Category):  Outerwear, Sweatshirt, Polo shirt 等
// 说明:
//   - Total 作为 Brand 的一个值（排在 M Polo、W Polo 之后）
//   - Total 行的 Framework/Category 为同名占位 "Total"，运行时抑制其子行
//   - T-shirt、Complemen 为 Framework 级叶节点，Category = 同名占位
// 排序: 所有排序列起始值从 7 开始（遵循 domain-rules.md）
// ========================================
DATATABLE(
    "RowKPI_ID",       INTEGER,        // 主键标识
    "Brand",           STRING,         // Level 1: 品牌（原 Category 字段）
    "Framework",       STRING,         // Level 2: 框架
    "Category",        STRING,         // Level 3: 品类（原 Scenario 字段）
    "Brand_Sort",      INTEGER,        // Level 1 排序
    "Framework_Sort",  INTEGER,        // Level 2 排序
    "Category_Sort",   INTEGER,        // Level 3 排序
    {
        // ─── M Polo > Acceleration ───
        { 1,  "M Polo", "Acceleration", "Outerwear",    7, 7,  7  },
        { 2,  "M Polo", "Acceleration", "Sweatshirt",   7, 7,  8  },
        // ─── M Polo > Foundation ───
        { 3,  "M Polo", "Foundation",   "Polo shirt",   7, 8,  9  },
        { 4,  "M Polo", "Foundation",   "Sport shirts", 7, 8,  10 },
        { 5,  "M Polo", "Foundation",   "T-shirt",      7, 8,  11 },
        { 6,  "M Polo", "Foundation",   "Sweaters",     7, 8,  12 },
        // ─── M Polo > T-shirt（Framework 级叶节点，Category = 同名占位）───
        { 7,  "M Polo", "T-shirt",      "T-shirt",      7, 9,  11 },
        // ─── M Polo > Complemen（Framework 级叶节点，Category = 同名占位）───
        { 8,  "M Polo", "Complemen",    "Complemen",    7, 10, 13 },
        // ─── W Polo > Acceleration ───
        { 9,  "W Polo", "Acceleration", "Dresses",      8, 7,  14 },
        { 10, "W Polo", "Acceleration", "Pants",        8, 7,  15 },
        { 11, "W Polo", "Acceleration", "Handbags",     8, 7,  16 },
        // ─── W Polo > Foundation ───
        { 12, "W Polo", "Foundation",   "Sweaters",     8, 8,  12 },
        // ─── Total（Brand 级叶节点，Framework/Category = 同名占位，运行时抑制子行）───
        { 13, "Total",  "Total",        "Total",        9, 11, 17 }
    }
)
```

### Step 3: 创建列维度表 `Dim_ColMetric_KpiBreakdown`（DAX 计算表）

```dax
Dim_ColMetric_KpiBreakdown =
// ========================================
// 表: Dim_ColMetric_KpiBreakdown
// 类型: 维度表（Dim_ 前缀），断开维度
// 用途: 定义 2 级列层次结构（MetricGroup > MetricName）
// 说明: 14 个指标列，跨 4 个分组
//       MetricName 有重复值（Total/直通车/引力魔方/全站推），
//       需保证同名值 MetricName_Sort 一致（Sort by Column 约束）
// 排序: 起始值从 7 开始
// 格式类型:
//   delta_pt → 带正负号的点数 + SVG 图标（如 "🟢 +14pt"）
//   percent  → 百分比，保留 1 位小数（如 "58.3%"）
//   number   → 整数（如 "140"）
// ======================================== 
DATATABLE(
    "ColMetric_ID",       INTEGER,     // 主键标识（全局唯一）
    "MetricGroup",        STRING,      // Level 1: 指标分组（__SelR1）
    "MetricName",         STRING,      // Level 2: 指标名称（__SelR2）
    "MetricGroup_Sort",   INTEGER,     // Level 1 排序
    "MetricName_Sort",    INTEGER,     // Level 2 排序（同名值必须一致）
    "MetricFormat",       STRING,      // 格式类型标识
    {
        // ─── SLS 分组 ───
        { 1,  "SLS",                "Cost% vs SLS%", 7,  7,  "delta_pt" },
        { 2,  "SLS",                "SLS%",          7,  8,  "percent"  },
        // ─── Cost MOB% 分组 ───
        { 3,  "Cost MOB%",          "Total",         8,  9,  "percent"  },
        { 4,  "Cost MOB%",          "直通车",         8,  10, "percent"  },
        { 5,  "Cost MOB%",          "引力魔方",       8,  11, "percent"  },
        { 6,  "Cost MOB%",          "全站推",         8,  12, "percent"  },
        // ─── ROI 分组 ───
        { 7,  "ROI",                "Total",         9,  9,  "number"   },
        { 8,  "ROI",                "直通车",         9,  10, "number"   },
        { 9,  "ROI",                "引力魔方",       9,  11, "number"   },
        { 10, "ROI",                "全站推",         9,  12, "number"   },
        // ─── New Customer Cost% 分组 ───
        { 11, "New Customer Cost%", "Total",         10, 9,  "percent"  },
        { 12, "New Customer Cost%", "直通车",         10, 10, "percent"  },
        { 13, "New Customer Cost%", "引力魔方",       10, 11, "percent"  },
        { 14, "New Customer Cost%", "全站推",         10, 12, "percent"  }
    }
)
```

### Step 4: 配置排序（Sort by Column）

| 表 | 字段 | Sort by Column |
|----|------|---------------|
| `Dim_RowKPI_KpiBreakdown` | `Brand` | `Brand_Sort` |
| `Dim_RowKPI_KpiBreakdown` | `Framework` | `Framework_Sort` |
| `Dim_RowKPI_KpiBreakdown` | `Category` | `Category_Sort` |
| `Dim_ColMetric_KpiBreakdown` | `MetricGroup` | `MetricGroup_Sort` |
| `Dim_ColMetric_KpiBreakdown` | `MetricName` | `MetricName_Sort` |

### Step 5: 关系说明（无需新建关系）

```
Dim_RowKPI_KpiBreakdown（断开维度）     Dim_ColMetric_KpiBreakdown（断开维度）
┌────────────────────────┐              ┌────────────────────────┐
│ RowKPI_ID (PK)         │              │ ColMetric_ID (PK)      │
│ Brand                  │  ← 无关系 →  │ MetricGroup            │
│ Framework              │              │ MetricName             │
│ Category               │              │ MetricFormat           │
│ *_Sort 列              │              │ *_Sort 列              │
└────────────────────────┘              └────────────────────────┘

两表完全独立，不与任何其他表建立关系
Matrix 视觉对象自动对行列维度做笛卡尔积
SWITCH 度量值通过 SELECTEDVALUE 分别获取当前行列上下文
```

### Step 6: 创建核心度量值

> 所有度量值放在 `_Measures` 表中，通过 Display Folder 组织

#### 6.1 核心路由度量值 `KPI Breakdown Cell Value`

```dax
KPI Breakdown Cell Value = 
// ========================================
// 度量值: KPI Breakdown Cell Value
// Display Folder: Base Metrics
// 用途: 列头 SWITCH 分发器
//       按 __SelR1（一级列头 MetricGroup）和 __SelR2（二级列头 MetricName）
//       路由到对应指标的占位值，每个 SWITCH 分支可独立替换为真实度量值
// 占位值: RowKPI_ID × ColMetric_ID（小计行用 SUM(RowKPI_ID) × ColMetric_ID）
// 依赖: Dim_RowKPI_KpiBreakdown, Dim_ColMetric_KpiBreakdown
// 模式: Disconnected Dimensions + Column-first SWITCH Dispatch
// ========================================
    // ── 行上下文（未来用于 CALCULATE 筛选事实表行字段）──
    VAR __Brand     = SELECTEDVALUE(Dim_RowKPI_KpiBreakdown[Brand])
    VAR __Framework = SELECTEDVALUE(Dim_RowKPI_KpiBreakdown[Framework])
    VAR __Category  = SELECTEDVALUE(Dim_RowKPI_KpiBreakdown[Category])
    VAR __RowID     = SELECTEDVALUE(Dim_RowKPI_KpiBreakdown[RowKPI_ID])
    VAR __IsTotal   = (__Brand = "Total")
        // Total: 事实表中无此字段值，未来替换时不加行筛选条件
    // ── 列上下文（用于 SWITCH 路由到目标指标）──
    VAR __ColID = SELECTEDVALUE(Dim_ColMetric_KpiBreakdown[ColMetric_ID])
    VAR __SelR1 = SELECTEDVALUE(Dim_ColMetric_KpiBreakdown[MetricGroup])   // 一级列头
    VAR __SelR2 = SELECTEDVALUE(Dim_ColMetric_KpiBreakdown[MetricName])    // 二级列头
    // ── 占位值（RowID × ColID）──
    // 叶节点: SELECTEDVALUE 返回具体 RowID
    // 小计行: SELECTEDVALUE 返回 BLANK，改用 SUM 作为替代
    VAR __EffRowID =
        IF(
            NOT ISBLANK(__RowID),
            __RowID,                                                       // 叶节点
            SUM(Dim_RowKPI_KpiBreakdown[RowKPI_ID])                        // 小计行
        )
    VAR __StaticValue = __EffRowID * __ColID
    // ── 参差层级抑制（仅处理 Framework 级叶节点的冗余 Category 子行）──
    // Total 不在此处隐藏，而是通过 IF(__IsTotal) 前置分支单独路由
    VAR __Suppress =
        ISINSCOPE(Dim_RowKPI_KpiBreakdown[Category])
            && __Category = __Framework
            // T-shirt=T-shirt、Complemen=Complemen、Total=Total → 抑制冗余 Category 子行
    RETURN
        IF(
            ISBLANK(__ColID) || __Suppress,
            BLANK(),
            IF(
                __IsTotal,
                // ════════════════════════════════════════════════
                // Total 分支（前置判断）
                // 未来替换：直接调用基础度量值，不加事实表行筛选条件
                // ════════════════════════════════════════════════
                SWITCH(
                    TRUE(),
                // ─── SLS > Cost% vs SLS% ───
                __Brand = "Total",
                    __StaticValue,
                BLANK()
                ),

                // ════════════════════════════════════════════════
                // 非 Total 分支
                // 未来替换：CALCULATE([度量值],
                //           '事实表'[Brand] = __Brand,
                //           '事实表'[Framework] = __Framework,
                //           '事实表'[Category] = __Category)
                // ════════════════════════════════════════════════
                SWITCH(
                    TRUE(),
                    // ─── SLS > Cost% vs SLS% ───
                    __SelR1 = "SLS" && __SelR2 = "Cost% vs SLS%",
                        __StaticValue,
                        // → 未来替换为:
                        //   CALCULATE([CAL_CostVsSLSDelta],
                        //       '事实表'[Brand] = __Brand,
                        //       '事实表'[Framework] = __Framework,
                        //       '事实表'[Category] = __Category
                        //   )

                    // ─── SLS > SLS% ───
                    __SelR1 = "SLS" && __SelR2 = "SLS%",
                        __StaticValue,
                        // → 未来替换为: CALCULATE([RATIO_SalesShare], ...)

                    // ─── Cost MOB% > Total ───
                    __SelR1 = "Cost MOB%" && __SelR2 = "Total",
                        __StaticValue,

                    // ─── Cost MOB% > 直通车 ───
                    __SelR1 = "Cost MOB%" && __SelR2 = "直通车",
                        __StaticValue,

                    // ─── Cost MOB% > 引力魔方 ───
                    __SelR1 = "Cost MOB%" && __SelR2 = "引力魔方",
                        __StaticValue,

                    // ─── Cost MOB% > 全站推 ───
                    __SelR1 = "Cost MOB%" && __SelR2 = "全站推",
                        __StaticValue,

                    // ─── ROI > Total ───
                    __SelR1 = "ROI" && __SelR2 = "Total",
                        __StaticValue,

                    // ─── ROI > 直通车 ───
                    __SelR1 = "ROI" && __SelR2 = "直通车",
                        __StaticValue,

                    // ─── ROI > 引力魔方 ───
                    __SelR1 = "ROI" && __SelR2 = "引力魔方",
                        __StaticValue,

                    // ─── ROI > 全站推 ───
                    __SelR1 = "ROI" && __SelR2 = "全站推",
                        __StaticValue,

                    // ─── New Customer Cost% > Total ───
                    __SelR1 = "New Customer Cost%" && __SelR2 = "Total",
                        __StaticValue,

                    // ─── New Customer Cost% > 直通车 ───
                    __SelR1 = "New Customer Cost%" && __SelR2 = "直通车",
                        __StaticValue,

                    // ─── New Customer Cost% > 引力魔方 ───
                    __SelR1 = "New Customer Cost%" && __SelR2 = "引力魔方",
                        __StaticValue,

                    // ─── New Customer Cost% > 全站推 ───
                    __SelR1 = "New Customer Cost%" && __SelR2 = "全站推",
                        __StaticValue,

                    BLANK()
                )
            )
        )
```

**IF(__IsTotal) 前置分支的工作原理：**

```
用户在 Matrix 中看到的每个单元格：
    行上下文 → Dim_RowKPI_KpiBreakdown 筛选
        → __Brand, __Framework, __Category
        → __IsTotal = Brand 是否为 "Total"
    列上下文 → Dim_ColMetric_KpiBreakdown 筛选
        → __SelR1 = 一级列头, __SelR2 = 二级列头

    IF(__IsTotal)
        → Total 分支: SWITCH(__SelR1 + __SelR2) 路由
          当前返回 EffRowID × ColID
          未来替换为基础度量值（不加事实表行筛选条件）
    ELSE
        → 非 Total 分支: SWITCH(__SelR1 + __SelR2) 路由
          当前返回 EffRowID × ColID
          未来替换为 CALCULATE([度量值], 事实表行筛选条件)
```

**小计行行为：**
- **叶节点**（Category 层）：`SELECTEDVALUE(RowKPI_ID)` 返回具体 ID → `RowID × ColID`
- **Framework 小计**：`SELECTEDVALUE` 返回 BLANK → 改用 `SUM(RowKPI_ID) × ColID`
- **Brand 小计**：同上，`SUM` 范围扩大到该 Brand 下所有 RowKPI_ID
- **Total Brand**：仅有 1 行（ID=13），`SELECTEDVALUE` 直接返回 13 → `13 × ColID`

#### 6.2 格式化显示度量值 `KPI Breakdown Cell Display`

```dax
KPI Breakdown Cell Display = 
// ========================================
// 度量值: KPI Breakdown Cell Display
// Display Folder: Formatting
// 用途: 根据列的 MetricFormat 类型，返回格式化后的文本
// 依赖: [KPI Breakdown Cell Value], Dim_ColMetric_KpiBreakdown[MetricFormat]
// 格式类型:
//   ─── 基础数值 ─────────────────────────────────────────────
//   integer       → 整数千分位：1,000
//   integer_k     → 整数千分位带k：1,000k
//   decimal_2     → 两位小数千分位：1,000.00
//   decimal_2k    → 两位小数千分位带k：1,000.00k
//   ─── 百分比 ───────────────────────────────────────────────
//   percent       → 百分比整数：40%
//   percent_1dp   → 百分比1位小数：40.5%
//   percent_2dp   → 百分比2位小数：40.52%
//   ─── 货币 ─────────────────────────────────────────────────
//   currency      → 货币整数带k：$250k
//   currency_2dp  → 货币两位小数带k：$250.50k
//   ─── 增减指标 ─────────────────────────────────────────────
//   delta_pct     → 增减百分比整数：+14%
//   delta_pct_1dp → 增减百分比1位小数：+14.5%
//   delta_pct_2dp → 增减百分比2位小数：+14.52%
//   delta_pt      → 增减点数整数：+14pts
//   delta_pt_1dp  → 增减点数1位小数：+14.5pts
//   delta_pt_2dp  → 增减点数2位小数：+14.52pts
//   delta_bp      → 增减基点整数：+14bp
//   delta_bp_1dp  → 增减基点1位小数：+14.5bp
//   ─── 兼容旧格式（保持向后兼容）───────────────────────────
//   number        → 同 integer_k：114k
// ========================================
    VAR __Value = [KPI Breakdown Cell Value]
    VAR __Format = SELECTEDVALUE(Dim_ColMetric_KpiBreakdown[MetricFormat])
    RETURN
        IF(
            ISBLANK(__Value),
            BLANK(),
            SWITCH(
                __Format,
                // ─── 基础数值 ───────────────────────────────────────
                "integer",
                    FORMAT(__Value, "#,##0"),                                          // 整数千分位：1,000
                "integer_k",
                    FORMAT(__Value, "#,##0") & "k",                                    // 整数千分位带k：1,000k
                "decimal_2",
                    FORMAT(__Value, "#,##0.00"),                                       // 两位小数千分位：1,000.00
                "decimal_2k",
                    FORMAT(__Value, "#,##0.00") & "k",                                 // 两位小数千分位带k：1,000.00k

                // ─── 百分比 ───────────────────────────────────────────
                "percent",
                    FORMAT(__Value, "#,##0") & "%",                                    // 百分比整数：40%
                "percent_1dp",
                    FORMAT(__Value, "#,##0.0") & "%",                                  // 百分比1位小数：40.5%
                "percent_2dp",
                    FORMAT(__Value, "#,##0.00") & "%",                                 // 百分比2位小数：40.52%

                // ─── 货币 ─────────────────────────────────────────────
                "currency",
                    FORMAT(__Value, "$#,##0") & "k",                                   // 货币整数带k：$250k
                "currency_2dp",
                    FORMAT(__Value, "$#,##0.00") & "k",                                // 货币两位小数带k：$250.50k

                // ─── 增减百分比 ───────────────────────────────────────
                "delta_pct",
                    IF(__Value >= 0, "+", "") & FORMAT(__Value * 100, "#,##0") & "%",  // 增减百分比整数：+14%
                "delta_pct_1dp",
                    IF(__Value >= 0, "+", "") & FORMAT(__Value * 100, "#,##0.0") & "%",// 增减百分比1位小数：+14.5%
                "delta_pct_2dp",
                    IF(__Value >= 0, "+", "") & FORMAT(__Value * 100, "#,##0.00") & "%",// 增减百分比2位小数：+14.52%

                // ─── 增减点数 ─────────────────────────────────────────
                "delta_pt",
                    IF(__Value >= 0, "+", "") & FORMAT(__Value, "#,##0") & "pts",      // 增减点数整数：+14pts
                "delta_pt_1dp",
                    IF(__Value >= 0, "+", "") & FORMAT(__Value, "#,##0.0") & "pts",    // 增减点数1位小数：+14.5pts
                "delta_pt_2dp",
                    IF(__Value >= 0, "+", "") & FORMAT(__Value, "#,##0.00") & "pts",   // 增减点数2位小数：+14.52pts

                // ─── 增减基点 ─────────────────────────────────────────
                "delta_bp",
                    IF(__Value >= 0, "+", "") & FORMAT(__Value, "#,##0") & "bp",       // 增减基点整数：+14bp
                "delta_bp_1dp",
                    IF(__Value >= 0, "+", "") & FORMAT(__Value, "#,##0.0") & "bp",     // 增减基点1位小数：+14.5bp

                // ─── 兼容旧格式（向后兼容）────────────────────────────
                "number",
                    FORMAT(__Value, "#,##0") & "k",                                    // 同 integer_k：114k

                // ─── 默认 ─────────────────────────────────────────────
                FORMAT(__Value, "#,##0.00")                                            // 默认：两位小数千分位
            )
        )
```

#### 6.3 条件格式度量值 — 字体颜色

```dax
KPI Breakdown Cell Font Color = 
// ========================================
// 度量值: KPI Breakdown Cell Font Color
// Display Folder: Formatting
// 用途: 根据列格式类型和值正负返回字体颜色
// 依赖: [KPI Breakdown Cell Value], Dim_ColMetric_KpiBreakdown[MetricFormat]
// 说明: 仅 delta_pt 类型启用正负颜色标记，其余默认黑色
// ========================================
    VAR __Value = [KPI Breakdown Cell Value]
    VAR __Format = SELECTEDVALUE(Dim_ColMetric_KpiBreakdown[MetricFormat])
    RETURN
        SWITCH(
            TRUE(),
            __Format = "delta_pt" && __Value > 0,  "#1A9018",   // 正值 → 草绿色
            __Format = "delta_pt" && __Value < 0,  "#D64550",   // 负值 → 玫瑰红
            __Format = "delta_pt" && __Value = 0,  "#E1C233",   // 零值 → 亮黄色
            "#212121"                                            // 默认 → 黑色
        )
```

#### 6.4 条件格式度量值 — SVG 图标

```dax
KPI Breakdown Cell SVG Icon = 
// ========================================
// 度量值: KPI Breakdown Cell SVG Icon
// Display Folder: Formatting
// 用途: 为 delta_pt 类型列返回 SVG 圆形图标
// 依赖: [KPI Breakdown Cell Value], Dim_ColMetric_KpiBreakdown[MetricFormat]
// 说明: 需将此度量值的数据类别设为"图像 URL"
// ========================================
    VAR __Value = [KPI Breakdown Cell Value]
    VAR __Format = SELECTEDVALUE(Dim_ColMetric_KpiBreakdown[MetricFormat])
    VAR __NeedsIcon = __Format = "delta_pt"
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

#### 6.5 条件格式度量值 — 交替行背景色

```dax
KPI Breakdown Cell Background Color = 
// ========================================
// 度量值: KPI Breakdown Cell Background Color
// Display Folder: Formatting
// 用途: 根据行 ID 返回交替行背景色
// 依赖: Dim_RowKPI_KpiBreakdown[RowKPI_ID]
// ========================================
    VAR __RowID = SELECTEDVALUE(Dim_RowKPI_KpiBreakdown[RowKPI_ID])
    VAR __EffRowID =
        IF(NOT ISBLANK(__RowID), __RowID, SUM(Dim_RowKPI_KpiBreakdown[RowKPI_ID]))
    RETURN
        IF(
            MOD(__EffRowID, 2) = 0,
            "#F5F5F5",                     // 偶数行：浅灰色
            "#FFFFFF"                      // 奇数行：白色
        )
```

### Step 7: 配置 Matrix 视觉对象

| 区域 | 字段 |
|------|------|
| **行** | `Dim_RowKPI_KpiBreakdown[Brand]` > `[Framework]` > `[Category]`（3 级层次） |
| **列** | `Dim_ColMetric_KpiBreakdown[MetricGroup]` > `[MetricName]`（2 级层次） |
| **值** | `[KPI Breakdown Cell Display]` |

格式设置：
- 阶梯布局（Stepped Layout）→ **ON**
- 行小计 → **ON**
- 列小计 → **OFF**
- Grand Total → **OFF**
- "Show items with no data" → **OFF**（隐藏 Total 和 Framework 级叶节点的冗余子行）
- 行标题第 1 列：重命名显示为 "Brand Level"

### Step 8: 应用条件格式

1. **字体颜色**：基于字段 `[KPI Breakdown Cell Font Color]`
2. **背景颜色**：基于字段 `[KPI Breakdown Cell Background Color]`
3. **图标**：`[KPI Breakdown Cell SVG Icon]` 数据类别设为"图像 URL"

---

## 5. 接入真实数据（SWITCH 替换指南）

接入真实数据时，**逐个替换 `KPI Breakdown Cell Value` 中两个 SWITCH 的对应分支**。
由于 Total 和非 Total 已拆分为独立 SWITCH 块，每个分支只需直接替换 `__StaticValue`：
- **Total SWITCH 分支**：替换为基础度量值（不加行筛选条件）
- **非 Total SWITCH 分支**：替换为 `CALCULATE([度量值], 事实表行筛选条件)`

其余度量值（Display、Font Color、SVG Icon、Background Color）无需改动。

### 替换模式

```dax
// ────────────────────────────────────────────────────
// Total SWITCH 中的分支替换（不加事实表行筛选）
// ────────────────────────────────────────────────────
__SelR1 = "SLS" && __SelR2 = "SLS%",
    [RATIO_SalesShare],                                 // 直接调用基础度量值

// ────────────────────────────────────────────────────
// 非 Total SWITCH 中的对应分支替换（加事实表行筛选）
// ────────────────────────────────────────────────────
__SelR1 = "SLS" && __SelR2 = "SLS%",
    CALCULATE(
        [RATIO_SalesShare],
        '事实表'[Brand] = __Brand,
        '事实表'[Framework] = __Framework,
        '事实表'[Category] = __Category
    ),

// ────────────────────────────────────────────────────
// 注意: 小计行的行为
// ────────────────────────────────────────────────────
// Framework 小计层: __Category = BLANK()
//   → CALCULATE 中 '事实表'[Category] = BLANK() 可能无匹配
//   → 推荐: 在基础度量值中使用 ISINSCOPE 判断层级
//   → 或改用 CALCULATETABLE + FILTER 方式，忽略 BLANK 筛选条件
//
// Brand 小计层: __Framework = BLANK(), __Category = BLANK()
//   → 同理，需在子度量值中处理
//
// 推荐的子度量值层级处理模式:
//   VAR __BrandFilter =
//       IF(NOT ISBLANK(__Brand),
//           TREATAS({__Brand}, '事实表'[Brand]), ALL('事实表'[Brand]))
//   -- 类似处理 Framework 和 Category
```

---

## 6. 度量值清单与 Display Folder

### 6.1 度量值目录

| # | 度量值名称 | Display Folder | 用途 | 格式类型 |
|---|-----------|----------------|------|----------|
| 1 | `KPI Breakdown Cell Value` | Base Metrics | 列头 SWITCH 分发器，核心路由度量值 | 数值 |
| 2 | `KPI Breakdown Cell Display` | Formatting | 根据 MetricFormat 格式化显示文本 | 文本 |
| 3 | `KPI Breakdown Cell Font Color` | Formatting | delta_pt 类型正负颜色标记 | 颜色代码 |
| 4 | `KPI Breakdown Cell SVG Icon` | Formatting | delta_pt 类型圆形状态图标 | 图像 URL |
| 5 | `KPI Breakdown Cell Background Color` | Formatting | 交替行背景色 | 颜色代码 |

### 6.2 Display Folder 结构

```
_Measures
├── Base Metrics/
│   └── KPI Breakdown Cell Value
└── Formatting/
    ├── KPI Breakdown Cell Display
    ├── KPI Breakdown Cell Font Color
    ├── KPI Breakdown Cell SVG Icon
    └── KPI Breakdown Cell Background Color
```

---

## 7. 血缘关系图（Lineage Diagram）

```
┌──────────────────────────────────────────────┐
│            Dim_RowKPI_KpiBreakdown            │
│  ┌──────────────────────────────────────────┐ │
│  │ RowKPI_ID │ Brand │ Framework │ Category │ │
│  │ Brand_Sort│Framework_Sort│Category_Sort  │ │
│  └──────────────────────────────────────────┘ │
└──────────────────┬───────────────────────────┘
                   │
                   │ SELECTEDVALUE / SUM
                   ▼
┌──────────────────────────────────────────────────────────┐
│              KPI Breakdown Cell Value                     │
│  ├─ __Brand, __Framework, __Category (行上下文)           │
│  ├─ __SelR1, __SelR2 (列上下文 → SWITCH 路由)            │
│  ├─ __IsTotal (Total 行判断)                              │
│  ├─ __EffRowID (叶节点=RowID / 小计=SUM)                 │
│  └─ __Suppress (参差层级 + Total 子行抑制)               │
└─────┬────────┬────────┬────────┬────────────────────────┘
      │        │        │        │
      ▼        ▼        ▼        ▼
┌─────────┐┌──────────┐┌─────────┐┌──────────────────────┐
│  Cell   ││Cell Font ││Cell SVG ││Cell Background Color │
│ Display ││  Color   ││  Icon   ││                      │
└─────────┘└──────────┘└─────────┘└──────────────────────┘
                   ▲
                   │ SELECTEDVALUE
                   │
┌──────────────────┴───────────────────────────┐
│           Dim_ColMetric_KpiBreakdown          │
│  ┌──────────────────────────────────────────┐ │
│  │ ColMetric_ID │ MetricGroup │ MetricName  │ │
│  │ MetricGroup_Sort │ MetricName_Sort       │ │
│  │ MetricFormat                             │ │
│  └──────────────────────────────────────────┘ │
└──────────────────────────────────────────────┘
```

**依赖关系汇总：**

| 度量值 | 依赖表 | 依赖度量值 |
|--------|--------|-----------|
| KPI Breakdown Cell Value | Dim_RowKPI_KpiBreakdown, Dim_ColMetric_KpiBreakdown | — |
| KPI Breakdown Cell Display | Dim_ColMetric_KpiBreakdown | KPI Breakdown Cell Value |
| KPI Breakdown Cell Font Color | Dim_ColMetric_KpiBreakdown | KPI Breakdown Cell Value |
| KPI Breakdown Cell SVG Icon | Dim_ColMetric_KpiBreakdown | KPI Breakdown Cell Value |
| KPI Breakdown Cell Background Color | Dim_RowKPI_KpiBreakdown | — |

---

## 8. 最终矩阵效果示意

> 占位值 = EffRowID × ColMetric_ID
> 缩进表示层级：无缩进 = Brand 小计，2 格 = Framework 小计/叶节点，4 格 = Category 叶节点
> 加粗行 = 小计行

### 8.1 可见行 EffRowID 索引

| # | 层级 | 行标签 | 所属 Brand | EffRowID 计算 | EffRowID |
|---|------|--------|-----------|---------------|----------|
| 1 | Brand 小计 | M Polo | M Polo | SUM(1..8) | 36 |
| 2 | Framework 小计 | Acceleration | M Polo | SUM(1,2) | 3 |
| 3 | Category 叶 | Outerwear | M Polo | ID=1 | 1 |
| 4 | Category 叶 | Sweatshirt | M Polo | ID=2 | 2 |
| 5 | Framework 小计 | Foundation | M Polo | SUM(3,4,5,6) | 18 |
| 6 | Category 叶 | Polo shirt | M Polo | ID=3 | 3 |
| 7 | Category 叶 | Sport shirts | M Polo | ID=4 | 4 |
| 8 | Category 叶 | T-shirt | M Polo | ID=5 | 5 |
| 9 | Category 叶 | Sweaters | M Polo | ID=6 | 6 |
| 10 | Framework 叶 | T-shirt | M Polo | ID=7 | 7 |
| 11 | Framework 叶 | Complemen | M Polo | ID=8 | 8 |
| 12 | Brand 小计 | W Polo | W Polo | SUM(9..12) | 42 |
| 13 | Framework 小计 | Acceleration | W Polo | SUM(9,10,11) | 30 |
| 14 | Category 叶 | Dresses | W Polo | ID=9 | 9 |
| 15 | Category 叶 | Pants | W Polo | ID=10 | 10 |
| 16 | Category 叶 | Handbags | W Polo | ID=11 | 11 |
| 17 | Framework 小计 | Foundation | W Polo | SUM(12) | 12 |
| 18 | Category 叶 | Sweaters | W Polo | ID=12 | 12 |
| 19 | Brand 小计 | Total | — | SUM(13) | 13 |
| 20 | Framework 小计 | Total | Total | ID=13 | 13 |

### 8.2 矩阵数据表 — SLS（ColID 1~2）

| Brand Level | Framework | Category | Cost% vs SLS% (×1) | SLS% (×2) |
|------------|-----------|----------|:---:|:---:|
| **M Polo** | | | **36** | **72** |
| | **Acceleration** | | **3** | **6** |
| | | Outerwear | 1 | 2 |
| | | Sweatshirt | 2 | 4 |
| | **Foundation** | | **18** | **36** |
| | | Polo shirt | 3 | 6 |
| | | Sport shirts | 4 | 8 |
| | | T-shirt | 5 | 10 |
| | | Sweaters | 6 | 12 |
| | **T-shirt** | | 7 | 14 |
| | **Complemen** | | 8 | 16 |
| **W Polo** | | | **42** | **84** |
| | **Acceleration** | | **30** | **60** |
| | | Dresses | 9 | 18 |
| | | Pants | 10 | 20 |
| | | Handbags | 11 | 22 |
| | **Foundation** | | **12** | **24** |
| | | Sweaters | 12 | 24 |
| **Total** | | | **13** | **26** |
| | **Total** | | **13** | **26** |

### 8.3 矩阵数据表 — Cost MOB%（ColID 3~6）

| Brand Level | Framework | Category | Total (×3) | 直通车 (×4) | 引力魔方 (×5) | 全站推 (×6) |
|------------|-----------|----------|:---:|:---:|:---:|:---:|
| **M Polo** | | | **108** | **144** | **180** | **216** |
| | **Acceleration** | | **9** | **12** | **15** | **18** |
| | | Outerwear | 3 | 4 | 5 | 6 |
| | | Sweatshirt | 6 | 8 | 10 | 12 |
| | **Foundation** | | **54** | **72** | **90** | **108** |
| | | Polo shirt | 9 | 12 | 15 | 18 |
| | | Sport shirts | 12 | 16 | 20 | 24 |
| | | T-shirt | 15 | 20 | 25 | 30 |
| | | Sweaters | 18 | 24 | 30 | 36 |
| | **T-shirt** | | 21 | 28 | 35 | 42 |
| | **Complemen** | | 24 | 32 | 40 | 48 |
| **W Polo** | | | **126** | **168** | **210** | **252** |
| | **Acceleration** | | **90** | **120** | **150** | **180** |
| | | Dresses | 27 | 36 | 45 | 54 |
| | | Pants | 30 | 40 | 50 | 60 |
| | | Handbags | 33 | 44 | 55 | 66 |
| | **Foundation** | | **36** | **48** | **60** | **72** |
| | | Sweaters | 36 | 48 | 60 | 72 |
| **Total** | | | **39** | **52** | **65** | **78** |
| | **Total** | | **39** | **52** | **65** | **78** |

### 8.4 矩阵数据表 — ROI（ColID 7~10）

| Brand Level | Framework | Category | Total (×7) | 直通车 (×8) | 引力魔方 (×9) | 全站推 (×10) |
|------------|-----------|----------|:---:|:---:|:---:|:---:|
| **M Polo** | | | **252** | **288** | **324** | **360** |
| | **Acceleration** | | **21** | **24** | **27** | **30** |
| | | Outerwear | 7 | 8 | 9 | 10 |
| | | Sweatshirt | 14 | 16 | 18 | 20 |
| | **Foundation** | | **126** | **144** | **162** | **180** |
| | | Polo shirt | 21 | 24 | 27 | 30 |
| | | Sport shirts | 28 | 32 | 36 | 40 |
| | | T-shirt | 35 | 40 | 45 | 50 |
| | | Sweaters | 42 | 48 | 54 | 60 |
| | **T-shirt** | | 49 | 56 | 63 | 70 |
| | **Complemen** | | 56 | 64 | 72 | 80 |
| **W Polo** | | | **294** | **336** | **378** | **420** |
| | **Acceleration** | | **210** | **240** | **270** | **300** |
| | | Dresses | 63 | 72 | 81 | 90 |
| | | Pants | 70 | 80 | 90 | 100 |
| | | Handbags | 77 | 88 | 99 | 110 |
| | **Foundation** | | **84** | **96** | **108** | **120** |
| | | Sweaters | 84 | 96 | 108 | 120 |
| **Total** | | | **91** | **104** | **117** | **130** |
| | **Total** | | **91** | **104** | **117** | **130** |

### 8.5 矩阵数据表 — New Customer Cost%（ColID 11~14）

| Brand Level | Framework | Category | Total (×11) | 直通车 (×12) | 引力魔方 (×13) | 全站推 (×14) |
|------------|-----------|----------|:---:|:---:|:---:|:---:|
| **M Polo** | | | **396** | **432** | **468** | **504** |
| | **Acceleration** | | **33** | **36** | **39** | **42** |
| | | Outerwear | 11 | 12 | 13 | 14 |
| | | Sweatshirt | 22 | 24 | 26 | 28 |
| | **Foundation** | | **198** | **216** | **234** | **252** |
| | | Polo shirt | 33 | 36 | 39 | 42 |
| | | Sport shirts | 44 | 48 | 52 | 56 |
| | | T-shirt | 55 | 60 | 65 | 70 |
| | | Sweaters | 66 | 72 | 78 | 84 |
| | **T-shirt** | | 77 | 84 | 91 | 98 |
| | **Complemen** | | 88 | 96 | 104 | 112 |
| **W Polo** | | | **462** | **504** | **546** | **588** |
| | **Acceleration** | | **330** | **360** | **390** | **420** |
| | | Dresses | 99 | 108 | 117 | 126 |
| | | Pants | 110 | 120 | 130 | 140 |
| | | Handbags | 121 | 132 | 143 | 154 |
| | **Foundation** | | **132** | **144** | **156** | **168** |
| | | Sweaters | 132 | 144 | 156 | 168 |
| **Total** | | | **143** | **156** | **169** | **182** |
| | **Total** | | **143** | **156** | **169** | **182** |

### 8.6 格式化显示示例（SLS 分组）

| Brand Level | Framework | Category | Cost% vs SLS% | SLS% |
|------------|-----------|----------|:---:|:---:|
| **M Polo** | | | +36pt | 72.0% |
| | **Acceleration** | | +3pt | 6.0% |
| | | Outerwear | +1pt | 2.0% |
| | | Sweatshirt | +2pt | 4.0% |
| | **Foundation** | | +18pt | 36.0% |
| **Total** | | | +13pt | 26.0% |
| | **Total** | | +13pt | 26.0% |

> 注：格式化显示由 `KPI Breakdown Cell Display` 度量值完成，此处仅示意
> delta_pt → "+Npt" 带 SVG 圆形图标；percent → "N.0%"；number → "N"

---

## 9. 注意事项

### 9.1 参差层级（Ragged Hierarchy）

- **T-shirt** 和 **Complemen** 是 Framework 级叶节点，没有 Category 子级
- 数据表中 Category = Framework 同名值（如 `"T-shirt"/"T-shirt"`、`"Complemen"/"Complemen"`）
- 度量值通过 `__Suppress` 逻辑返回 BLANK() 抑制冗余 Category 子行
- 条件：`ISINSCOPE(Category) && __Category = __Framework`
- Total 的 Category 子行（Total=Total）同样被此条件捕获抑制

### 9.2 Total 行特殊处理

- **Total** 作为 Brand 字段的一个值（与 M Polo/W Polo 同级，排序值最大，位于最后）
- 数据表中 Framework="Total" / Category="Total" 为同名占位
- Total 的 Category 子行通过 `__Suppress`（`__Category = __Framework`）抑制
- Total 在 Brand 小计层和 Framework 小计层均显示值
- EffRowID = 13（RowKPI_ID 直接由 `SELECTEDVALUE` 返回，因为只有 1 条记录）
- 通过 `IF(__IsTotal)` 前置分支，Total 和非 Total 各自拥有独立 SWITCH 分发块
- **未来接入真实数据时**：Total SWITCH 分支直接调用基础度量值，不加事实表行筛选条件

### 9.3 小计行 EffRowID

- 叶节点：`SELECTEDVALUE(RowKPI_ID)` 返回该行的 ID
- 小计行：`SELECTEDVALUE` 返回 BLANK → 使用 `SUM(RowKPI_ID)` 代替
- **注意**：SUM 值在未来替换时不参与计算逻辑，仅用于当前占位阶段生成可区分的数值
- M Polo Brand 小计 EffRowID = SUM(1+2+3+4+5+6+7+8) = 36
- W Polo Brand 小计 EffRowID = SUM(9+10+11+12) = 42

### 9.4 Sort by Column 约束

- 所有排序列起始值从 **7** 开始（遵循 domain-rules.md）
- 跨组同名 MetricName（如 "Total"、"直通车" 等）的 MetricName_Sort 值必须**完全一致**
  - 例如：Cost MOB%/Total(Sort=9) = ROI/Total(Sort=9) = New Customer Cost%/Total(Sort=9)
- Power BI 的 Sort by Column 要求：同名字段只能绑定一个排序值

### 9.5 SVG 图标配置

- `KPI Breakdown Cell SVG Icon` 的数据类别需设为**"图像 URL"**
- 操作路径："数据"视图 → 选中度量值 → 属性面板 → 数据类别 → 图像 URL

### 9.6 断开维度说明

- `Dim_RowKPI_KpiBreakdown` 和 `Dim_ColMetric_KpiBreakdown` **不与任何表建立关系**
- Matrix 视觉对象自动对行列维度做笛卡尔积
- 所有数据通过度量值中的 `SELECTEDVALUE` 获取当前行列上下文

---

## 10. 操作清单（Checklist）

- [ ] 创建 `_Measures` 表并隐藏 Value 列
- [ ] 创建 `Dim_RowKPI_KpiBreakdown` 计算表（13 行 × 7 列）
- [ ] 创建 `Dim_ColMetric_KpiBreakdown` 计算表（14 行 × 6 列）
- [ ] 配置 Sort by Column（5 对字段排序绑定）
- [ ] 验证：两个 Dim 表不与任何表建立关系
- [ ] 创建度量值 `KPI Breakdown Cell Value`（Base Metrics 文件夹）
- [ ] 创建度量值 `KPI Breakdown Cell Display`（Formatting 文件夹）
- [ ] 创建度量值 `KPI Breakdown Cell Font Color`（Formatting 文件夹）
- [ ] 创建度量值 `KPI Breakdown Cell SVG Icon`（Formatting 文件夹，数据类别=图像 URL）
- [ ] 创建度量值 `KPI Breakdown Cell Background Color`（Formatting 文件夹）
- [ ] 配置 Matrix 视觉对象（行 3 级 / 列 2 级 / 值 = Cell Display）
- [ ] 应用条件格式（字体颜色 / 背景颜色 / 图标）
- [ ] 验证：Matrix 显示 20 行 × 14 列（含小计行，不含被抑制行）
- [ ] 验证：Total 行在 Brand/Framework 层显示（Category 层被抑制）
- [ ] 验证：T-shirt/Complemen 在 Framework 层显示值（Category 层被抑制）
- [ ] 验证：Cell Value 占位值 = EffRowID × ColMetric_ID
- [ ] 验证：最右下角单元格（Total × 全站推 Col14）= 13 × 14 = 182
