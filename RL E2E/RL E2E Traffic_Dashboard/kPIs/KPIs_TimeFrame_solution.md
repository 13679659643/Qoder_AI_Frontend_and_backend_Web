# Power BI 通用时间周期 KPI 计算框架解决方案 — 多指标 SWITCH 分发模式

> status: propose
> created: 2026-04-21
> updated: 2026-04-22
> complexity: 🔴复杂
> type: 度量值开发 + 可视化构建
> naming: 遵循 powerbi_code_copilot/rules/dax-style.md 规范

---

## 1. 需求理解

实现一个通用的时间周期 KPI 计算框架：
- **时间周期筛选器**（TimeFrame_ID）：WTD / MTD / QTD / YTD / DAILY 五种模式
- **日期筛选器**（Date）：仅在 DAILY 模式下生效
- **KPI 指标维度**：10 张卡片 × 32 个 KPI（10 Major + 22 Sub），通过 KPI_ID SWITCH 分发
- **核心规则**：
  - WTD/MTD/QTD/YTD：基于事实表 `KP_KPIs_sample[dt]` 最大日期计算对应时间范围，**日期筛选器不起作用**
  - DAILY：指标**完全受日期筛选器控制**
  - 事实表最大日期必须使用 `MAXX(ALL(...))` ，**不受任何筛选器或上下文影响**
- **时间范围定义**：
  - WTD = 事实表最大日期所在周的周一 ~ 最大日期
  - MTD = 事实表最大日期所在月的 1 日 ~ 最大日期
  - QTD = 事实表最大日期所在季度首日 ~ 最大日期
  - YTD = 事实表最大日期所在年的 1 月 1 日 ~ 最大日期
  - DAILY = 日期筛选器的开始日期 ~ 结束日期
- **KPI 层级**：
  - Major（大指标）：卡片标题值，如 Cost、New Customer No.
  - Sub（子指标）：卡片内的派生指标，如 vs LY、TAR ACH%、vs AVG ROI
  - Sub 的 KPI_Name 跨卡片重复（如 "vs LY" 出现 7 次），必须使用 **KPI_ID** 路由

---

## 2. 整体架构

```
核心思路：时间周期切换 + 断开维度 KPI_ID SWITCH 分发 + 日期上下文覆盖

Slicer_Time_Frame（时间周期筛选器）    Dim_Metric_KPIs（KPI 指标维度，断开）
    │                                        │
    │ SELECTEDVALUE → __SelectedTF             │ SELECTEDVALUE → __SelID（用 KPI_ID）
    │                                        │
    ▼                                        ▼
┌──────────────────── 度量值计算链 ───────────────────────┐
│                                                          │
│  Fact_Last_Date ← MAXX(ALL(KP_KPIs_sample), KP_KPIs_sample[dt])       │
│       │                                                  │
│       ▼                                                  │
│  KPIs Base Value ← SWITCH(__SelID) 纯 KPI 分发           │
│       │            路由 32 个 KPI（10 Major + 22 Sub）    │
│       ▼                                                  │
│  KPIs Cell Value ← 时间周期感知包装器                    │
│       │  IF(__IsDailyMode)                               │
│       │    → [KPIs Base Value]（透传日期筛选器上下文）    │
│       │  ELSE                                            │
│       │    → CALCULATE([KPIs Base Value],                │
│       │        FILTER(ALL(A_日期表), 计算日期范围))       │
│       │                                                  │
│       ├─→ KPIs Cell Display（格式化显示）                │
│       └─→ KPIs Font Color（字体颜色条件格式）            │
│                                                          │
└──────────────────────────────────────────────────────────┘
         ▲
         │ 关系连接（多对一）
         │
    A_日期表[Date] ──→ KP_KPIs_sample[dt]（事实表）
```

### 关键技术点

1. **KPI_ID 路由**：KPI_Name 跨卡片重复（"vs LY"×7、"TAR ACH%"×6），
   SWITCH 必须基于 `KPI_ID`（全局唯一）分发，不能用 `KPI_Name`
2. **时间周期覆盖**：非 DAILY 模式使用 `FILTER(ALL(A_日期表), ...)` 覆盖日期筛选器上下文，
   `ALL(A_日期表)` 移除已有日期筛选，再应用计算出的日期范围；
   其他维度筛选器（Brand、Platform 等）不受影响
3. **DAILY 透传**：DAILY 模式直接调用基础度量值，保留日期筛选器的自然上下文
4. **SWITCH 分发分离**：KPI 选择逻辑集中在 `KPIs Base Value`，时间周期逻辑集中在 `KPIs Cell Value`，
   添加新 KPI 仅需修改 `KPIs Base Value` 的 SWITCH + `Dim_Metric_KPIs` 新增行
5. **事实表最大日期独立**：`MAXX(ALL(KP_KPIs_sample), KP_KPIs_sample[dt])` 通过 `ALL` 确保不受任何上下文影响

---

## 3. 命名规范映射

> 遵循 `powerbi_code_copilot/rules/dax-style.md`

| 类别 | 命名 | 规则 |
|------|------|------|
| 时间周期筛选器 | `Slicer_Time_Frame` | Slicer_ 前缀 |
| KPI 维度表 | `Dim_Metric_KPIs` | Dim_ 前缀，断开维度 |
| 日期表 | `A_日期表` | 已有日期维度表 |
| 度量值表 | `_Measures` | _ 前缀 — 隐藏辅助表 |
| 基础度量值 | `Fact_Last_Date` | Fact 前缀，事实表辅助度量值 |
| 基础度量值 | `KPIs Base Value` | 纯 SWITCH 分发度量值 |
| 核心度量值 | `KPIs Cell Value` | 时间周期感知核心路由 |
| 格式化度量值 | `KPIs Cell Display` | 格式化显示文本 |
| 条件格式度量值 | `KPIs Font Color` | 字体颜色条件格式 |
| 时间周期变量 | `__SelectedTF`, `__IsDailyMode` | __ 前缀局部变量 |
| 日期范围变量 | `__MaxFactDate`, `__StartDate`, `__EndDate` | __ 前缀局部变量 |
| KPI 上下文变量 | `__SelID`, `__Format` | __ 前缀局部变量，用 KPI_ID 路由 |

---

## 4. 实施步骤

### Step 1: 创建时间周期筛选器 `Slicer_Time_Frame`（DAX 计算表）

```dax
Slicer_Time_Frame = 
// 功能：创建一个时间周期维度表，用于报表中的时间周期筛选和分组
// 用途：用户可以通过此表选择不同的时间分析周期（如日、周、月累计、年累计等）
// 参数表名称：TimeFrame
// 遵循通用参数表模板规范
DATATABLE(
    // 基础字段 - 必选字段
    "TimeFrame_ID", STRING,        // 主键标识，用于唯一标识每个时间周期选项
    "TimeFrame_Label", STRING,     // 显示标签，在报表界面中向用户展示的名称
    "TimeFrame_Sort", INTEGER,     // 排序顺序，控制选项在切片器中的显示顺序
    "TimeFrame_Description", STRING, // 详细描述，说明该时间周期的具体含义和用途
    
    // 扩展字段 - 可选字段
    "TimeFrame_IsDefault", BOOLEAN,  // 是否默认选中，TRUE表示用户打开报表时默认选择此项
    "TimeFrame_IsActive", BOOLEAN,   // 是否激活状态，控制该选项是否可用
    "TimeFrame_Group", STRING,       // 分组标识，用于对相关选项进行逻辑分组
    
    // 自定义扩展字段 - 根据业务需求添加
    "Time_Type", STRING,                   // 时间周期类型：基础周期/累计周期
    "Icon", STRING,                       // 图标标识，可用于报表中的可视化显示
    
    // 数据行
    {
        // 基础周期 - 表示固定的时间单位
        {
            "DAILY",                // 基础日周期代码
            "最近七天",              // 显示名称
            2,                      // 排序顺序
            "按天统计的基础时间周期，显示最近7天的数据",  // 详细描述
            FALSE,                  // 非默认选项
            TRUE,                   // 激活状态
            "精确周期",              // 分组
            "累计周期",              // 时间周期类型
            "●"                     // 图标标识
        },
        
        // 累计周期 - 表示从周期开始到当前日期的累计
        {
            "MTD",                  // 本月至今代码
            "本月至今",              // 显示名称
            3,                      // 排序顺序
            "计算从当月第一天到当前日期的累计值，用于月度进度分析",  // 详细描述
            FALSE,                  // 非默认选项
            TRUE,                   // 激活状态
            "累计周期",              // 分组
            "累计周期",              // 时间周期类型
            "📈"                     // 图标标识
        },
        
        {
            "QTD",                  // 本季至今代码
            "本季至今",              // 显示名称
            4,                      // 排序顺序
            "计算从当季第一天到当前日期的累计值，用于季度进度分析",  // 详细描述
            FALSE,                  // 非默认选项
            TRUE,                   // 激活状态
            "累计周期",              // 分组
            "累计周期",              // 时间周期类型
            "📊"                     // 图标标识
        },
        
        {
            "WTD",                  // 本周至今代码
            "本周至今",              // 显示名称
            6,                      // 排序顺序
            "计算从本周第一天到当前日期的累计值，设为默认选项，用于周度分析",  // 详细描述
            TRUE,                   // 默认选中
            TRUE,                   // 激活状态
            "累计周期",              // 分组
            "累计周期",              // 时间周期类型
            "📅"                     // 图标标识
        },
        
        {
            "YTD",                  // 本年至今代码
            "本年至今",              // 显示名称
            7,                      // 排序顺序
            "计算从当年第一天到当前日期的累计值，用于年度进度分析",  // 详细描述
            FALSE,                  // 非默认选项
            TRUE,                   // 激活状态
            "累计周期",              // 分组
            "累计周期",              // 时间周期类型
            "🎯"                     // 图标标识
        }
    }
)
```

### Step 2: 创建 KPI 指标维度表 `Dim_Metric_KPIs`（DAX 计算表）

```dax
Dim_Metric_KPIs = 
// ========================================
// 表: Dim_Metric_KPIs
// 类型: 维度表（Dim_ 前缀），断开维度
// 用途: KPIs 页面指标维度，定义 10 张 KPI 卡片的大指标与子指标
//   - 10 个 Major 大指标（红框卡片标题）
//   - Cost 下 4 个 Sub 子指标；其余 9 个大指标各 2 个 Sub 子指标
//   - 共 32 行
// 层级: KPI_Level = "Major"（大指标） / "Sub"（子指标）
//       KPI_ParentID 指向所属 Major 的 KPI_ID，Major 自身为 0
// 颜色管理:
//   - KPI_ColorPositive / Negative / Zero / Default 四列控制字体颜色
//   - Major 行统一为默认色 #212121（不做条件颜色）
//   - Sub 行启用正/负/零三色，可逐行自定义
//   - 度量值通过 SELECTEDVALUE 直接读取对应颜色列，无需硬编码
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
//   currency      → 货币千分位整数：$2,500
//   currency_dp   → 货币一位小数千分位：$2,500.0
//   currency_2dp  → 货币两位小数千分位：$2,500.00
//   currency_k    → 货币千分位整数带k：$2,500k
//   currency_dp_k → 货币一位小数千分位带k：$2,500.0k
//   currency_2dp_k→ 货币两位小数千分位带k：$2,500.00k
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
DATATABLE(
    "KPI_ID",            INTEGER,    // 主键标识，1~32
    "KPI_Name",          STRING,     // 显示名称
    "KPI_Sort",          INTEGER,    // 排序值，控制显示顺序
    "KPI_Format",        STRING,     // 格式类型标识，供显示度量值使用
    "KPI_Level",         STRING,     // 层级标识："Major" 大指标 / "Sub" 子指标
    "KPI_ParentID",      INTEGER,    // 所属大指标 KPI_ID，Major 为 0
    "KPI_CardIndex",     INTEGER,    // 卡片编号 1~10，同一卡片内的指标共享此值
    "KPI_ColorPositive", STRING,     // 正值字体颜色（值 > 0 时使用）
    "KPI_ColorNegative", STRING,     // 负值字体颜色（值 < 0 时使用）
    "KPI_ColorZero",     STRING,     // 零值字体颜色（值 = 0 时使用）
    "KPI_ColorDefault",  STRING,     // 默认字体颜色（Major 行 / 兜底使用）
    {
        // ═══════════════════════════════════════
        // Card 1: Cost（第一行，4 个子指标）
        // ═══════════════════════════════════════
        //  ID  Name                Sort  Format           Level    Parent Card  Positive   Negative   Zero       Default
        { 1,  "Cost",              1,  "currency",      "Major", 0,  1,  "#212121", "#212121", "#212121", "#212121" },
        { 2,  "Cost ACH%",         2,  "delta_pct_1dp", "Sub",   1,  1,  "#1A9018", "#D64550", "#E1C233", "#212121" },
        { 3,  "Cost vs SLS ACH%",  3,  "delta_bp",      "Sub",   1,  1,  "#1A9018", "#D64550", "#E1C233", "#212121" },
        { 4,  "SLS DCom",          4,  "currency",      "Sub",   1,  1,  "#1A9018", "#D64550", "#E1C233", "#212121" },
        { 5,  "TAR ACH%",          5,  "delta_pct_1dp", "Sub",   1,  1,  "#1A9018", "#D64550", "#E1C233", "#212121" },

        // ═══════════════════════════════════════
        // Card 2: New Customer No.（第一行）
        // ═══════════════════════════════════════
        { 6,  "New Customer No.",       6,  "integer",       "Major", 0,  2,  "#212121", "#212121", "#212121", "#212121" },
        { 7,  "vs LY",                  7,  "delta_pct_1dp", "Sub",   6,  2,  "#1A9018", "#D64550", "#E1C233", "#212121" },
        { 8,  "TAR ACH%",               8,  "delta_pct_1dp", "Sub",   6,  2,  "#1A9018", "#D64550", "#E1C233", "#212121" },

        // ═══════════════════════════════════════
        // Card 3: New Customer Cost%（第一行）
        // ═══════════════════════════════════════
        { 9,  "New Customer Cost%",     9,  "percent_1dp", "Major", 0,  3,  "#212121", "#212121", "#212121", "#212121" },
        { 10, "vs LY",                  10, "delta_bp",  "Sub",   9,  3,  "#1A9018", "#D64550", "#E1C233", "#212121" },
        { 11, "TAR ACH%",               11, "delta_bp",  "Sub",   9,  3,  "#1A9018", "#D64550", "#E1C233", "#212121" },

        // ═══════════════════════════════════════
        // Card 4: New Customer Cost ROI（第一行）
        // ═══════════════════════════════════════
        { 12, "New Customer Cost ROI",  12, "integer",       "Major", 0,  4,  "#212121", "#212121", "#212121", "#212121" },
        { 13, "vs LY",                  13, "delta_pct_1dp", "Sub",   12, 4,  "#1A9018", "#D64550", "#E1C233", "#212121" },
        { 14, "vs AVG ROI",             14, "delta_pct_1dp", "Sub",   12, 4,  "#1A9018", "#D64550", "#E1C233", "#212121" },

        // ═══════════════════════════════════════
        // Card 5: Cost Per New Acquisition（第一行）
        // ═══════════════════════════════════════
        { 15, "Cost Per New Acquisition", 15, "integer",       "Major", 0,  5,  "#212121", "#212121", "#212121", "#212121" },
        { 16, "vs LY",                    16, "delta_pct_1dp", "Sub",   15, 5,  "#1A9018", "#D64550", "#E1C233", "#212121" },
        { 17, "TAR ACH%",                 17, "delta_pct_1dp", "Sub",   15, 5,  "#1A9018", "#D64550", "#E1C233", "#212121" },

        // ═══════════════════════════════════════
        // Card 6: Acceleration SLS（第二行）
        // ═══════════════════════════════════════
        { 18, "Acceleration SLS",       18, "currency",      "Major", 0,  6,  "#212121", "#212121", "#212121", "#212121" },
        { 19, "vs LY",                  19, "delta_pct_1dp", "Sub",   18, 6,  "#1A9018", "#D64550", "#E1C233", "#212121" },
        { 20, "TAR ACH%",               20, "delta_pct_1dp", "Sub",   18, 6,  "#1A9018", "#D64550", "#E1C233", "#212121" },

        // ═══════════════════════════════════════
        // Card 7: Acceleration SLS MOB%（第二行）
        // ═══════════════════════════════════════
        { 21, "Acceleration SLS MOB%",  21, "percent_1dp", "Major", 0,  7,  "#212121", "#212121", "#212121", "#212121" },
        { 22, "vs LY",                  22, "delta_bp",  "Sub",   21, 7,  "#1A9018", "#D64550", "#E1C233", "#212121" },
        { 23, "TAR ACH%",               23, "delta_bp",  "Sub",   21, 7,  "#1A9018", "#D64550", "#E1C233", "#212121" },

        // ═══════════════════════════════════════
        // Card 8: Acceleration Cost%（第二行）
        // ═══════════════════════════════════════
        { 24, "Acceleration Cost%",     24, "percent_1dp", "Major", 0,  8,  "#212121", "#212121", "#212121", "#212121" },
        { 25, "vs LY",                  25, "delta_bp",  "Sub",   24, 8,  "#1A9018", "#D64550", "#E1C233", "#212121" },
        { 26, "TAR ACH%",               26, "delta_bp",  "Sub",   24, 8,  "#1A9018", "#D64550", "#E1C233", "#212121" },

        // ═══════════════════════════════════════
        // Card 9: Acceleration ROI（第二行）
        // ═══════════════════════════════════════
        { 27, "Acceleration ROI",       27, "integer",       "Major", 0,  9,  "#212121", "#212121", "#212121", "#212121" },
        { 28, "vs LY",                  28, "delta_pct_1dp", "Sub",   27, 9,  "#1A9018", "#D64550", "#E1C233", "#212121" },
        { 29, "vs AVG ROI",             29, "delta_pct_1dp", "Sub",   27, 9,  "#1A9018", "#D64550", "#E1C233", "#212121" },

        // ═══════════════════════════════════════
        // Card 10: New Customer Cost（第一行）
        // ═══════════════════════════════════════
        { 30, "New Customer Cost",      30, "currency",      "Major", 0,  10, "#212121", "#212121", "#212121", "#212121" },
        { 31, "vs LY",                  31, "delta_pct_1dp", "Sub",   30, 10, "#1A9018", "#D64550", "#E1C233", "#212121" },
        { 32, "vs AVG ROI",             32, "delta_pct_1dp", "Sub",   30, 10, "#1A9018", "#D64550", "#E1C233", "#212121" }
    }
)

```

### Step 3: 配置排序（Sort by Column）

| 表 | 字段 | Sort by Column |
|----|------|---------------|
| `Dim_Metric_KPIs` | `KPI_Name` | `KPI_Sort` |

### Step 4: 关系说明（无需新建关系）

```
Slicer_Time_Frame（筛选器表）      Dim_Metric_KPIs（断开维度）
┌────────────────────────┐         ┌────────────────────────────┐
│ TimeFrame_ID           │         │ KPI_ID (PK)                │
│ TimeFrame_Label        │← 无关系→│ KPI_Name                   │
│ TimeFrame_Sort         │         │ KPI_Sort / KPI_Format      │
│ TimeFrame_Description  │         │ KPI_Level / KPI_ParentID   │
│ TimeFrame_IsDefault    │         │ KPI_CardIndex              │
│ TimeFrame_IsActive     │         │ KPI_Color*（4 列）         │
│ TimeFrame_Group        │         └────────────────────────────┘
│ Time_Type / Icon       │
└────────────────────────┘
        ↓ SELECTEDVALUE                   ↓ SELECTEDVALUE
        ↓                                 ↓
    度量值中读取当前选择               度量值中读取当前 KPI_ID

已有关系:
    A_日期表[Date] ──── 多对一 ────→ KP_KPIs_sample[dt]
    （确保 A_日期表 与 KP_KPIs_sample[dt] 存在关系连接）
```

### Step 5: 创建基础度量值

> 所有度量值放在 `_Measures` 表中，通过 Display Folder 组织

#### 5.1 事实表最大日期 `Fact_Last_Date`

```dax
Fact_Last_Date = 
// ========================================
// 度量值: Fact_Last_Date
// Display Folder: Base Metrics
// 用途: 获取事实表中 dt 字段的最大日期
// 说明: 使用 ALL() 确保不受任何筛选器或上下文影响
//       作为 WTD/MTD/QTD/YTD 时间范围计算的锚点
// 依赖: KP_KPIs_sample[dt]
// ========================================
    MAXX(
        ALL(KP_KPIs_sample),
        KP_KPIs_sample[dt]
    )
```

#### 5.2 KPI 纯分发度量值 `KPIs Base Value`

```dax
KPIs Base Value = 
// ========================================
// 度量值: KPIs Base Value
// Display Folder: Base Metrics
// 用途: 纯 KPI SWITCH 分发器
//       根据 Dim_Metric_KPIs[KPI_ID] 路由到对应计算逻辑
//       KPI_Name 跨卡片重复（"vs LY"×7），必须用 KPI_ID 路由
//       不含时间周期逻辑，由 KPIs Cell Value 包装时间周期上下文
// 依赖: Dim_Metric_KPIs[KPI_ID], KP_KPIs_sample（事实表）
// 模式: Disconnected Dimension + KPI_ID SWITCH Dispatch
// 扩展: 添加新 KPI 时，在 SWITCH 中新增分支 + Dim_Metric_KPIs 新增行
// ========================================
    VAR __SelID = SELECTEDVALUE(Dim_Metric_KPIs[KPI_ID])
    RETURN
    SWITCH(
        __SelID,

        // ═══════════════════════════════════════════════════════
        // Card 1: Cost
        // ═══════════════════════════════════════════════════════

        // ── ID 1: Cost（Major）── 投放总花费
        1, SUM(KP_KPIs_sample[cost]),

        // ── ID 2: Cost ACH%（Sub）── 花费达成率 = (实际 - 目标) / 目标
        2, DIVIDE(
                SUM(KP_KPIs_sample[cost]) - SUM(KP_KPIs_sample[cost_target]),
                SUM(KP_KPIs_sample[cost_target])
           ),

        // ── ID 3: Cost vs SLS ACH%（Sub）── 花费达成率 - 销售达成率（基点）
        3, DIVIDE(
                SUM(KP_KPIs_sample[cost]) - SUM(KP_KPIs_sample[cost_target]),
                SUM(KP_KPIs_sample[cost_target])
           )
           - DIVIDE(
                SUM(KP_KPIs_sample[pay_amount]) - SUM(KP_KPIs_sample[pay_amount_target]),
                SUM(KP_KPIs_sample[pay_amount_target])
           ),

        // ── ID 4: SLS DCom（Sub）── 销售分解值 = 实际销售
        4, SUM(KP_KPIs_sample[pay_amount]),

        // ── ID 5: TAR ACH%（Sub of Cost）── 花费目标达成率
        5, DIVIDE(
                SUM(KP_KPIs_sample[cost]),
                SUM(KP_KPIs_sample[cost_target])
           ) - 1,

        // ═══════════════════════════════════════════════════════
        // Card 2: New Customer No.
        // ═══════════════════════════════════════════════════════

        // ── ID 6: New Customer No.（Major）── 新客数
        6, SUM(KP_KPIs_sample[new_customer_cnt]),

        // ── ID 7: vs LY（Sub of New Customer No.）
        7, DIVIDE(
                SUM(KP_KPIs_sample[new_customer_cnt]) - SUM(KP_KPIs_sample[new_customer_cnt_ly]),
                SUM(KP_KPIs_sample[new_customer_cnt_ly])
           ),

        // ── ID 8: TAR ACH%（Sub of New Customer No.）
        8, DIVIDE(
                SUM(KP_KPIs_sample[new_customer_cnt]),
                SUM(KP_KPIs_sample[new_customer_cnt_target])
           ) - 1,

        // ═══════════════════════════════════════════════════════
        // Card 3: New Customer Cost%
        // ═══════════════════════════════════════════════════════

        // ── ID 9: New Customer Cost%（Major）── 新客成本占比 = 新客花费 / 总花费
        9, DIVIDE(
                SUM(KP_KPIs_sample[new_customer_cost]),
                SUM(KP_KPIs_sample[cost])
           ),

        // ── ID 10: vs LY（Sub）── 新客成本占比同比差（基点）
        10, DIVIDE(SUM(KP_KPIs_sample[new_customer_cost]), SUM(KP_KPIs_sample[cost]))
            - DIVIDE(SUM(KP_KPIs_sample[new_customer_cost_ly]), SUM(KP_KPIs_sample[cost_ly])),

        // ── ID 11: TAR ACH%（Sub）── 新客成本占比 vs 目标（基点）
        11, DIVIDE(SUM(KP_KPIs_sample[new_customer_cost]), SUM(KP_KPIs_sample[cost]))
            - DIVIDE(SUM(KP_KPIs_sample[new_customer_cost_target]), SUM(KP_KPIs_sample[cost_target])),

        // ═══════════════════════════════════════════════════════
        // Card 4: New Customer Cost ROI
        // ═══════════════════════════════════════════════════════

        // ── ID 12: New Customer Cost ROI（Major）── 新客 ROI = 新客成交 / 新客花费
        12, DIVIDE(
                SUM(KP_KPIs_sample[new_customer_pay_amount]),
                SUM(KP_KPIs_sample[new_customer_cost])
            ),

        // ── ID 13: vs LY（Sub）── 新客 ROI 同比
        13, VAR __Curr = DIVIDE(SUM(KP_KPIs_sample[new_customer_pay_amount]), SUM(KP_KPIs_sample[new_customer_cost]))
            VAR __LY = DIVIDE(SUM(KP_KPIs_sample[new_customer_pay_amount_ly]), SUM(KP_KPIs_sample[new_customer_cost_ly]))
            RETURN DIVIDE(__Curr - __LY, __LY),

        // ── ID 14: vs AVG ROI（Sub）── 新客 ROI vs 总体 ROI
        14, DIVIDE(SUM(KP_KPIs_sample[new_customer_pay_amount]), SUM(KP_KPIs_sample[new_customer_cost]))
            - DIVIDE(SUM(KP_KPIs_sample[pay_amount]), SUM(KP_KPIs_sample[cost])),

        // ═══════════════════════════════════════════════════════
        // Card 5: Cost Per New Acquisition
        // ═══════════════════════════════════════════════════════

        // ── ID 15: Cost Per New Acquisition（Major）── 新客获取成本 = 新客花费 / 新客数
        15, DIVIDE(
                SUM(KP_KPIs_sample[new_customer_cost]),
                SUM(KP_KPIs_sample[new_customer_cnt])
            ),

        // ── ID 16: vs LY（Sub）
        16, VAR __Curr = DIVIDE(SUM(KP_KPIs_sample[new_customer_cost]), SUM(KP_KPIs_sample[new_customer_cnt]))
            VAR __LY = DIVIDE(SUM(KP_KPIs_sample[new_customer_cost_ly]), SUM(KP_KPIs_sample[new_customer_cnt_ly]))
            RETURN DIVIDE(__Curr - __LY, __LY),

        // ── ID 17: TAR ACH%（Sub）
        17, VAR __Curr = DIVIDE(SUM(KP_KPIs_sample[new_customer_cost]), SUM(KP_KPIs_sample[new_customer_cnt]))
            VAR __Tar = DIVIDE(SUM(KP_KPIs_sample[new_customer_cost_target]), SUM(KP_KPIs_sample[new_customer_cnt_target]))
            RETURN DIVIDE(__Curr - __Tar, __Tar),

        // ═══════════════════════════════════════════════════════
        // Card 6: Acceleration SLS
        // ═══════════════════════════════════════════════════════

        // ── ID 18: Acceleration SLS（Major）── Acceleration 框架销售额
        18, CALCULATE(SUM(KP_KPIs_sample[pay_amount]), KP_KPIs_sample[framework] = "Acceleration"),

        // ── ID 19: vs LY（Sub）
        19, DIVIDE(
                CALCULATE(SUM(KP_KPIs_sample[pay_amount]), KP_KPIs_sample[framework] = "Acceleration")
                - CALCULATE(SUM(KP_KPIs_sample[pay_amount_ly]), KP_KPIs_sample[framework] = "Acceleration"),
                CALCULATE(SUM(KP_KPIs_sample[pay_amount_ly]), KP_KPIs_sample[framework] = "Acceleration")
            ),

        // ── ID 20: TAR ACH%（Sub）
        20, DIVIDE(
                CALCULATE(SUM(KP_KPIs_sample[pay_amount]), KP_KPIs_sample[framework] = "Acceleration"),
                CALCULATE(SUM(KP_KPIs_sample[pay_amount_target]), KP_KPIs_sample[framework] = "Acceleration")
            ) - 1,

        // ═══════════════════════════════════════════════════════
        // Card 7: Acceleration SLS MOB%
        // ═══════════════════════════════════════════════════════

        // ── ID 21: Acceleration SLS MOB%（Major）── Acceleration 销售占比
        21, DIVIDE(
                CALCULATE(SUM(KP_KPIs_sample[pay_amount]), KP_KPIs_sample[framework] = "Acceleration"),
                SUM(KP_KPIs_sample[pay_amount])
            ),

        // ── ID 22: vs LY（Sub）── Acceleration 销售占比同比差（基点）
        22, DIVIDE(
                CALCULATE(SUM(KP_KPIs_sample[pay_amount]), KP_KPIs_sample[framework] = "Acceleration"),
                SUM(KP_KPIs_sample[pay_amount])
            )
            - DIVIDE(
                CALCULATE(SUM(KP_KPIs_sample[pay_amount_ly]), KP_KPIs_sample[framework] = "Acceleration"),
                SUM(KP_KPIs_sample[pay_amount_ly])
            ),

        // ── ID 23: TAR ACH%（Sub）── vs 目标占比差（基点）
        23, DIVIDE(
                CALCULATE(SUM(KP_KPIs_sample[pay_amount]), KP_KPIs_sample[framework] = "Acceleration"),
                SUM(KP_KPIs_sample[pay_amount])
            )
            - DIVIDE(
                CALCULATE(SUM(KP_KPIs_sample[pay_amount_target]), KP_KPIs_sample[framework] = "Acceleration"),
                SUM(KP_KPIs_sample[pay_amount_target])
            ),

        // ═══════════════════════════════════════════════════════
        // Card 8: Acceleration Cost%
        // ═══════════════════════════════════════════════════════

        // ── ID 24: Acceleration Cost%（Major）── Acceleration 花费占比
        24, DIVIDE(
                CALCULATE(SUM(KP_KPIs_sample[cost]), KP_KPIs_sample[framework] = "Acceleration"),
                SUM(KP_KPIs_sample[cost])
            ),

        // ── ID 25: vs LY（Sub）── Acceleration 花费占比同比差（基点）
        25, DIVIDE(
                CALCULATE(SUM(KP_KPIs_sample[cost]), KP_KPIs_sample[framework] = "Acceleration"),
                SUM(KP_KPIs_sample[cost])
            )
            - DIVIDE(
                CALCULATE(SUM(KP_KPIs_sample[cost_ly]), KP_KPIs_sample[framework] = "Acceleration"),
                SUM(KP_KPIs_sample[cost_ly])
            ),

        // ── ID 26: TAR ACH%（Sub）── vs 目标占比差（基点）
        26, DIVIDE(
                CALCULATE(SUM(KP_KPIs_sample[cost]), KP_KPIs_sample[framework] = "Acceleration"),
                SUM(KP_KPIs_sample[cost])
            )
            - DIVIDE(
                CALCULATE(SUM(KP_KPIs_sample[cost_target]), KP_KPIs_sample[framework] = "Acceleration"),
                SUM(KP_KPIs_sample[cost_target])
            ),

        // ═══════════════════════════════════════════════════════
        // Card 9: Acceleration ROI
        // ═══════════════════════════════════════════════════════

        // ── ID 27: Acceleration ROI（Major）
        27, DIVIDE(
                CALCULATE(SUM(KP_KPIs_sample[pay_amount]), KP_KPIs_sample[framework] = "Acceleration"),
                CALCULATE(SUM(KP_KPIs_sample[cost]), KP_KPIs_sample[framework] = "Acceleration")
            ),

        // ── ID 28: vs LY（Sub）── Acceleration ROI 同比差（基点）
        28, DIVIDE(
                CALCULATE(SUM(KP_KPIs_sample[pay_amount]), KP_KPIs_sample[framework] = "Acceleration"),
                CALCULATE(SUM(KP_KPIs_sample[cost]), KP_KPIs_sample[framework] = "Acceleration")
            )
            - DIVIDE(
                CALCULATE(SUM(KP_KPIs_sample[pay_amount_ly]), KP_KPIs_sample[framework] = "Acceleration"),
                CALCULATE(SUM(KP_KPIs_sample[cost_ly]), KP_KPIs_sample[framework] = "Acceleration")
            ),

        // ── ID 29: vs AVG ROI（Sub）── Acceleration ROI vs 总体 ROI（基点）
        29, DIVIDE(
                CALCULATE(SUM(KP_KPIs_sample[pay_amount]), KP_KPIs_sample[framework] = "Acceleration"),
                CALCULATE(SUM(KP_KPIs_sample[cost]), KP_KPIs_sample[framework] = "Acceleration")
            )
            - DIVIDE(SUM(KP_KPIs_sample[pay_amount]), SUM(KP_KPIs_sample[cost])),

        // ═══════════════════════════════════════════════════════
        // Card 10: New Customer Cost
        // ═══════════════════════════════════════════════════════

        // ── ID 30: New Customer Cost（Major）── 新客花费总额
        30, SUM(KP_KPIs_sample[new_customer_cost]),

        // ── ID 31: vs LY（Sub）
        31, DIVIDE(
                SUM(KP_KPIs_sample[new_customer_cost]) - SUM(KP_KPIs_sample[new_customer_cost_ly]),
                SUM(KP_KPIs_sample[new_customer_cost_ly])
            ),

        // ── ID 32: vs AVG ROI（Sub）── 新客 ROI vs 总体 ROI
        32, DIVIDE(SUM(KP_KPIs_sample[new_customer_pay_amount]), SUM(KP_KPIs_sample[new_customer_cost]))
            - DIVIDE(SUM(KP_KPIs_sample[pay_amount]), SUM(KP_KPIs_sample[cost])),

        // ─── 默认 ──────────────────────────────────────────
        BLANK()
    )
```

**事实表 `KP_KPIs_sample` 需要的列清单：**

| 类型 | 列名 | 说明 |
|------|------|------|
| 日期 | `dt` | 日期字段 |
| 维度 | `brand`, `framework`, `ads_format` | 品牌/框架/广告工具 |
| 当期值 | `cost`, `pay_amount`, `new_customer_cnt`, `new_customer_cost`, `new_customer_pay_amount` | 当期绝对值 |
| 去年同期 | `cost_ly`, `pay_amount_ly`, `new_customer_cnt_ly`, `new_customer_cost_ly`, `new_customer_pay_amount_ly` | vs LY 计算用 |
| 目标值 | `cost_target`, `pay_amount_target`, `new_customer_cnt_target`, `new_customer_cost_target` | TAR ACH% 计算用 |

### Step 6: 创建核心度量值 `KPIs Cell Value`

```dax
KPIs Cell Value = 
// ========================================
// 度量值: KPIs Cell Value
// Display Folder: Base Metrics
// 用途: 时间周期感知的核心路由度量值
//       根据 TimeFrame 选择，决定日期上下文的来源：
//       - WTD/MTD/QTD/YTD: 基于事实表最大日期计算范围，覆盖日期筛选器
//       - DAILY: 透传日期筛选器的自然上下文
// 依赖: Slicer_Time_Frame[TimeFrame_ID], [KPIs Base Value], A_日期表
// 模式: TimeFrame Switch + Date Context Override
// ========================================

    // ── 事实表最大日期（不受任何筛选器或上下文影响）──
    VAR __MaxFactDate =
        MAXX(
            ALL(KP_KPIs_sample),
            KP_KPIs_sample[dt]
        )

    // ── 时间周期上下文 ──
    VAR __SelectedTF =
        SELECTEDVALUE(
            Slicer_Time_Frame[TimeFrame_ID],
            "DAILY"                                    // 未选择时默认 DAILY
        )
    VAR __IsDailyMode = __SelectedTF = "DAILY"

    // ── 计算日期范围起始日 ──
    // WTD: 当前周周一 ~ 最大日期
    // MTD: 当前月 1 日 ~ 最大日期
    // QTD: 当前季度首日 ~ 最大日期
    // YTD: 当前年 1 月 1 日 ~ 最大日期
    // DAILY: 不计算，使用日期筛选器上下文
    VAR __StartDate =
        SWITCH(
            __SelectedTF,
            // WTD: WEEKDAY(date, 2) → Monday=1..Sunday=7
            //      StartDate = date - weekday + 1 → 回退到周一
            "WTD",
                __MaxFactDate - WEEKDAY(__MaxFactDate, 2) + 1,

            // MTD: 当月 1 日
            "MTD",
                DATE(YEAR(__MaxFactDate), MONTH(__MaxFactDate), 1),

            // QTD: 当季首月 1 日
            //      QuarterStartMonth = (QUARTER - 1) * 3 + 1
            //      Q1→1月, Q2→4月, Q3→7月, Q4→10月
            "QTD",
                DATE(
                    YEAR(__MaxFactDate),
                    (QUARTER(__MaxFactDate) - 1) * 3 + 1,
                    1
                ),

            // YTD: 当年 1 月 1 日
            "YTD",
                DATE(YEAR(__MaxFactDate), 1, 1),

            // DAILY: 不使用此变量
            BLANK()
        )

    // ── 日期范围终止日（非 DAILY 模式统一为事实表最大日期）──
    VAR __EndDate = __MaxFactDate

    RETURN
    IF(
        __IsDailyMode,
        // ════════════════════════════════════════════════
        // DAILY 模式：透传日期筛选器上下文
        // 日期筛选器 A_日期表[Date] 的选择直接生效
        // 其他维度筛选器同样自然生效
        // ════════════════════════════════════════════════
            [KPIs Base Value],

        // ════════════════════════════════════════════════
        // 非 DAILY 模式：覆盖日期上下文为计算范围
        // ALL(A_日期表) 移除日期筛选器的所有影响
        // FILTER 重新施加 __StartDate ~ __EndDate 范围
        // 其他维度筛选器（Brand/Platform 等）不受影响
        // ════════════════════════════════════════════════
            CALCULATE(
                [KPIs Base Value],
                FILTER(
                    ALL('A_日期表'),
                    'A_日期表'[Date] >= __StartDate
                        && 'A_日期表'[Date] <= __EndDate
                )
            )
    )
```

**时间周期计算示例（假设 MaxFactDate = 2026-04-18，周六）：**

| TimeFrame | StartDate | EndDate | 说明 |
|-----------|-----------|---------|------|
| WTD | 2026-04-13（周一） | 2026-04-18 | 周六 - 6 + 1 = 周一 |
| MTD | 2026-04-01 | 2026-04-18 | 4 月 1 日 |
| QTD | 2026-04-01 | 2026-04-18 | Q2 起始月 = (2-1)*3+1 = 4 月 |
| YTD | 2026-01-01 | 2026-04-18 | 年初 |
| DAILY | 日期筛选器选择 | 日期筛选器选择 | 透传 |

### Step 7: 创建格式化显示度量值 `KPIs Cell Display`

```dax
KPIs Cell Display = 
// ========================================
// 度量值: KPIs Cell Display
// Display Folder: Formatting
// 用途: 根据 KPI 的 KPI_Format 类型，返回格式化后的文本
// 依赖: [KPIs Cell Value], Dim_Metric_KPIs[KPI_Format]
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
//   currency      → 货币千分位整数：$2,500
//   currency_dp   → 货币一位小数千分位：$2,500.0
//   currency_2dp  → 货币两位小数千分位：$2,500.00
//   currency_k    → 货币千分位整数带k：$2,500k
//   currency_dp_k → 货币一位小数千分位带k：$2,500.0k
//   currency_2dp_k→ 货币两位小数千分位带k：$2,500.00k
//   ─── 增减百分比 ───────────────────────────────────────────
//   delta_pct     → 增减百分比整数：+14%
//   delta_pct_1dp → 增减百分比1位小数：+14.5%
//   delta_pct_2dp → 增减百分比2位小数：+14.52%
//   ─── 增减点数 ─────────────────────────────────────────────
//   delta_pt      → 增减点数整数：+14pts
//   delta_pt_1dp  → 增减点数1位小数：+14.5pts
//   delta_pt_2dp  → 增减点数2位小数：+14.52pts
//   ─── 增减基点 ─────────────────────────────────────────────
//   delta_bp      → 增减基点整数：+14bp
//   delta_bp_1dp  → 增减基点1位小数：+14.5bp
//   ─── 兼容旧格式 ──────────────────────────────────────────
//   number        → 同 integer_k：114k
// ========================================
    VAR __Value = [KPIs Cell Value]
    VAR __Format = SELECTEDVALUE(Dim_Metric_KPIs[KPI_Format])
    RETURN
        IF(
            ISBLANK(__Value),
            "-",                                                               // 空值显示为 "-"
            SWITCH(
                __Format,
                // ─── 基础数值 ───────────────────────────────────────
                "integer",
                    FORMAT(__Value, "#,##0"),                                   // 整数千分位：1,000
                "integer_k",
                    FORMAT(__Value / 1000, "#,##0") & "k",                     // 整数千分位带k：150k
                "decimal_2",
                    FORMAT(__Value, "#,##0.00"),                                // 两位小数：3.50
                "decimal_2k",
                    FORMAT(__Value / 1000, "#,##0.00") & "k",                  // 两位小数带k：1.50k

                // ─── 百分比 ─────────────────────────────────────────
                "percent",
                    FORMAT(__Value, "0%"),                                      // 百分比整数：40%
                "percent_1dp",
                    FORMAT(__Value, "0.0%"),                                    // 百分比1位小数：40.5%
                "percent_2dp",
                    FORMAT(__Value, "0.00%"),                                   // 百分比2位小数：40.52%

                // ─── 货币 ───────────────────────────────────────────
                "currency",
                    "$" & FORMAT(__Value, "#,##0"),                             // 货币千分位整数：$2,500
                "currency_dp",
                    "$" & FORMAT(__Value, "#,##0.0"),                           // 货币一位小数千分位：$2,500.0
                "currency_2dp",
                    "$" & FORMAT(__Value, "#,##0.00"),                          // 货币两位小数千分位：$2,500.00
                "currency_k",
                    "$" & FORMAT(__Value / 1000, "#,##0") & "k",               // 货币千分位整数带k：$2,500k
                "currency_dp_k",
                    "$" & FORMAT(__Value / 1000, "#,##0.0") & "k",             // 货币一位小数千分位带k：$2,500.0k
                "currency_2dp_k",
                    "$" & FORMAT(__Value / 1000, "#,##0.00") & "k",            // 货币两位小数千分位带k：$2,500.00k

                // ─── 增减百分比 ─────────────────────────────────────
                "delta_pct",
                    IF(__Value >= 0, "+", "") & FORMAT(__Value, "0%"),          // +14%
                "delta_pct_1dp",
                    IF(__Value >= 0, "+", "") & FORMAT(__Value, "0.0%"),        // +14.5%
                "delta_pct_2dp",
                    IF(__Value >= 0, "+", "") & FORMAT(__Value, "0.00%"),       // +14.52%

                // ─── 增减点数 ───────────────────────────────────────
                "delta_pt",
                    IF(__Value >= 0, "+", "") & FORMAT(__Value, "#,##0") & "pts",      // +14pts
                "delta_pt_1dp",
                    IF(__Value >= 0, "+", "") & FORMAT(__Value, "#,##0.0") & "pts",    // +14.5pts
                "delta_pt_2dp",
                    IF(__Value >= 0, "+", "") & FORMAT(__Value, "#,##0.00") & "pts",   // +14.52pts

                // ─── 增减基点 ───────────────────────────────────────
                "delta_bp",
                    IF(__Value >= 0, "+", "") & FORMAT(__Value * 10000, "#,##0") & "bp",       // +14bp
                "delta_bp_1dp",
                    IF(__Value >= 0, "+", "") & FORMAT(__Value * 10000, "#,##0.0") & "bp",     // +14.5bp

                // ─── 兼容旧格式（向后兼容）──────────────────────────
                "number",
                    FORMAT(__Value / 1000, "#,##0") & "k",                     // 同 integer_k：114k

                // ─── 默认 ───────────────────────────────────────────
                FORMAT(__Value, "#,##0.00")                                     // 默认两位小数
            )
        )
```

**delta_bp 基点说明：** 基点（basis point）= 0.01%，即 1bp = 0.0001。
度量值返回的小数值（如 0.0014）乘以 10000 后显示为 14bp。

### Step 8: 创建条件格式度量值 — 字体颜色 `KPIs Font Color`

```dax
KPIs Font Color = 
// ========================================
// 度量值: KPIs Font Color
// Display Folder: Formatting
// 用途: 根据 KPI 值正负和 Dim_Metric_KPIs 中定义的颜色映射，
//       返回对应字体颜色
// 依赖: [KPIs Cell Value], Dim_Metric_KPIs[KPI_Color*]
// 说明:
//   - 每个 KPI 在 Dim_Metric_KPIs 中有独立的 4 色配置
//   - Major 行：统一 #212121 默认黑色（4 色列全部设为 #212121）
//   - Sub 行：启用正/负/零三色，正向=绿色 / 负向=红色
//   - 颜色值在维度表中维护，无需修改度量值即可调整配色
// ========================================
    VAR __Value = [KPIs Cell Value]
    RETURN
        SWITCH(
            TRUE(),
            ISBLANK(__Value),
                SELECTEDVALUE(Dim_Metric_KPIs[KPI_ColorDefault]),       // 空值 → 默认色
            __Value > 0,
                SELECTEDVALUE(Dim_Metric_KPIs[KPI_ColorPositive]),      // 正值 → 正值色
            __Value < 0,
                SELECTEDVALUE(Dim_Metric_KPIs[KPI_ColorNegative]),      // 负值 → 负值色
            __Value = 0,
                SELECTEDVALUE(Dim_Metric_KPIs[KPI_ColorZero]),          // 零值 → 零值色
            SELECTEDVALUE(Dim_Metric_KPIs[KPI_ColorDefault])            // 兜底 → 默认色
        )
```

### Step 9: 配置视觉对象

**当前方式：卡片（Card）**

每张卡片筛选 `Dim_Metric_KPIs[KPI_CardIndex] = N`，内部使用 `[KPIs Cell Display]` 显示值，
`[KPIs Font Color]` 控制字体颜色条件格式。

**通用格式设置：**
- 字体颜色条件格式 → 基于字段 `[KPIs Font Color]`
- KPI_Name 的 Sort by Column → `KPI_Sort`

### Step 10: 配置切片器

**时间周期切片器：**
- 切片器类型：单选（Single Select）
- 字段：`Slicer_Time_Frame[TimeFrame_Label]`
- Sort by Column：`TimeFrame_Sort`
- 默认选择：WTD（`TimeFrame_IsDefault = TRUE`）

**日期范围切片器：**
- 切片器类型：日期范围（Between）
- 字段：`A_日期表[Date]`
- 说明：仅在 TimeFrame = DAILY 时生效

---

## 5. 度量值清单与 Display Folder

### 5.1 度量值目录

| # | 度量值名称 | Display Folder | 用途 | 返回类型 |
|---|-----------|----------------|------|----------|
| 1 | `Fact_Last_Date` | Base Metrics | 事实表最大日期（不受上下文影响） | 日期 |
| 2 | `KPIs Base Value` | Base Metrics | 纯 KPI_ID SWITCH 分发（32 个分支，无时间周期逻辑） | 数值 |
| 3 | `KPIs Cell Value` | Base Metrics | 时间周期感知核心路由 | 数值 |
| 4 | `KPIs Cell Display` | Formatting | 根据 KPI_Format 格式化显示文本（完整格式目录） | 文本 |
| 5 | `KPIs Font Color` | Formatting | 根据 KPI_Color* 条件格式字体颜色 | 颜色代码 |

### 5.2 Display Folder 结构

```
_Measures
├── Base Metrics/
│   ├── Fact_Last_Date
│   ├── KPIs Base Value
│   └── KPIs Cell Value
└── Formatting/
    ├── KPIs Cell Display
    └── KPIs Font Color
```

---

## 6. 血缘关系图（Lineage Diagram）

```
┌───────────────────────────────────┐
│          Slicer_Time_Frame         │
│  ┌───────────────────────────────┐ │
│  │ TimeFrame_ID │ TimeFrame_Label│ │
│  │ TimeFrame_Sort │ Time_Type    │ │
│  │ TimeFrame_Group │ Icon        │ │
│  └───────────────────────────────┘ │
└────────────────┬──────────────────┘
                 │ SELECTEDVALUE → __SelectedTF
                 ▼
┌────────────────────────────────────────────────────────────┐
│                    KPIs Cell Value                           │
│  ├─ __MaxFactDate ← MAXX(ALL(KP_KPIs_sample), KP_KPIs_sample[dt])       │
│  ├─ __SelectedTF, __IsDailyMode (时间周期)                  │
│  ├─ __StartDate, __EndDate (日期范围)                       │
│  └─ 调用 [KPIs Base Value]                                  │
│       ├─ DAILY → 直接调用（透传日期筛选器）                 │
│       └─ 非DAILY → CALCULATE + FILTER(ALL(A_日期表), ...)   │
└───────┬───────────────┬────────────────────────────────────┘
        │               │
        ▼               ▼
┌─────────────┐  ┌──────────────┐
│ KPIs Cell   │  │ KPIs Font    │
│ Display     │  │ Color        │
└─────────────┘  └──────────────┘
        ▲               ▲
        │               │
┌───────┴───────────────┴──────────────────────┐
│              Dim_Metric_KPIs                  │
│  ┌──────────────────────────────────────────┐ │
│  │ KPI_ID │ KPI_Name │ KPI_Sort │ KPI_Format│ │
│  │ KPI_Level │ KPI_ParentID │ KPI_CardIndex │ │
│  │ KPI_Color*（4列）                        │ │
│  └──────────────────────────────────────────┘ │
└──────────────────────────────────────────────┘

┌──────────────────────────────────────┐
│   KP_KPIs_sample（事实表）                    │
│  ┌──────────────────────────────────┐ │
│  │ dt │ brand │ framework           │ │
│  │ cost │ pay_amount │ order_cnt    │ │
│  │ new_customer_cnt/cost/pay_amount │ │
│  │ *_ly（去年同期列）               │ │
│  │ *_target（目标值列）             │ │
│  └──────────────────────────────────┘ │
└──────────────────┬───────────────────┘
                   │ 多对一关系
                   ▼
┌──────────────────────────────────────┐
│      A_日期表（日期维度表）            │
│  ┌──────────────────────────────────┐ │
│  │ Date │ Year │ Month │ Quarter   │ │
│  └──────────────────────────────────┘ │
└──────────────────────────────────────┘
```

**依赖关系汇总：**

| 度量值 | 依赖表 | 依赖度量值 |
|--------|--------|-----------|
| Fact_Last_Date | KP_KPIs_sample | — |
| KPIs Base Value | Dim_Metric_KPIs, KP_KPIs_sample | — |
| KPIs Cell Value | Slicer_Time_Frame, A_日期表, KP_KPIs_sample | KPIs Base Value |
| KPIs Cell Display | Dim_Metric_KPIs | KPIs Cell Value |
| KPIs Font Color | Dim_Metric_KPIs | KPIs Cell Value |

---

## 7. 扩展指南

### 7.1 添加新 KPI

添加新 KPI 仅需两步：

**步骤 1**：在 `Dim_Metric_KPIs` 表中新增一行

```dax
// 示例：添加 Card 11 的 Major KPI "Total ROI"
//  ID   Name         Sort  Format     Level   Parent Card  Positive   Negative   Zero       Default
{ 33, "Total ROI", 33, "decimal_2", "Major", 0,  11, "#212121", "#212121", "#212121", "#212121" }
```

**步骤 2**：在 `KPIs Base Value` 的 SWITCH 中新增分支

```dax
// 在 SWITCH 中添加（使用 KPI_ID = 33 路由）:
33, DIVIDE(SUM(KP_KPIs_sample[pay_amount]), SUM(KP_KPIs_sample[cost])),
```

其余度量值（Cell Value、Cell Display、Font Color）**无需任何改动**。

### 7.2 添加新时间周期

在 `Slicer_Time_Frame` 新增行，并在 `KPIs Cell Value` 的 `__StartDate` SWITCH 中新增分支。

示例：添加 "L7D"（最近 7 天）

```dax
// Slicer_Time_Frame 新增行:
{ "L7D", "最近7天", 8, "基于事实表最大日期回溯7天", FALSE, TRUE, "精确周期", "精确周期", "●" }

// KPIs Cell Value 的 __StartDate SWITCH 新增分支:
"L7D",
    __MaxFactDate - 6,    // 最大日期往前 6 天（含当天共 7 天）
```

### 7.3 添加币种切换

如需按币种切换货币格式，可在 `KPIs Cell Display` 中增加币种判断：

```dax
// 在 KPIs Cell Display 中添加币种上下文变量:
VAR __CurrencySymbol =
    SELECTEDVALUE(Slicer_Currency_Selection[Currency_Symbol], "¥")
...
// 然后在 "currency" 分支中使用:
"currency",
    __CurrencySymbol & FORMAT(__Value, "#,##0"),
```

### 7.4 添加 SVG 圆形图标（表格扩展用）

当从卡片扩展为表格/矩阵时，可添加 SVG 图标度量值为增减指标提供视觉标识。

```dax
KPIs Cell SVG Icon = 
// ========================================
// 度量值: KPIs Cell SVG Icon
// Display Folder: Formatting
// 用途: 为 Sub 行（增减类指标）返回 SVG 圆形图标
//       仅当 KPI_Level = "Sub" 时显示图标
//       Major 行不显示图标（返回 BLANK）
// 依赖: [KPIs Cell Value], Dim_Metric_KPIs[KPI_Level]
// 说明: 需将此度量值的数据类别设为"图像 URL"
//       操作路径："数据"视图 → 选中度量值 → 属性面板 → 数据类别 → 图像 URL
// ========================================
    VAR __Value = [KPIs Cell Value]
    VAR __Level = SELECTEDVALUE(Dim_Metric_KPIs[KPI_Level])
    VAR __NeedsIcon = __Level = "Sub"
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
            NOT __NeedsIcon,    BLANK(),               // Major 行不显示图标
            ISBLANK(__Value),   BLANK(),               // 空值不显示
            __Value > 0,        __GreenSVG,            // 正值 → 绿色圆
            __Value < 0,        __RedSVG,              // 负值 → 红色圆
            __Value = 0,        __YellowSVG,           // 零值 → 黄色圆
            BLANK()
        )
```

**配置要点：**
- 在"数据"视图中选中此度量值 → 属性面板 → 数据类别 → **图像 URL**
- 在 Matrix/Table 中将此度量值放入值区域，与 `[KPIs Cell Display]` 并列

### 7.5 添加交替行背景色（表格扩展用）

当从卡片扩展为表格/矩阵时，可添加交替行背景色度量值提升可读性。

```dax
KPIs Cell Background Color = 
// ========================================
// 度量值: KPIs Cell Background Color
// Display Folder: Formatting
// 用途: 根据 KPI_CardIndex（卡片编号）返回交替行背景色
//       同一卡片内的所有 KPI 共享相同背景色
//       卡片编号为奇数 → 白色，偶数 → 浅灰色
// 依赖: Dim_Metric_KPIs[KPI_CardIndex]
// ========================================
    VAR __CardIndex = SELECTEDVALUE(Dim_Metric_KPIs[KPI_CardIndex])
    VAR __EffCardIndex =
        IF(
            NOT ISBLANK(__CardIndex),
            __CardIndex,
            SUM(Dim_Metric_KPIs[KPI_CardIndex])
        )
    RETURN
        IF(
            MOD(__EffCardIndex, 2) = 0,
            "#F5F5F5",                     // 偶数卡片：浅灰色
            "#FFFFFF"                      // 奇数卡片：白色
        )
```

**配置要点：**
- 在 Matrix/Table 的条件格式中：背景颜色 → 基于字段 → `[KPIs Cell Background Color]`
- 同一卡片内的 Major 和 Sub 行共享相同背景色，形成视觉分组

---

## 8. 注意事项

### 8.1 KPI_ID 路由（关键）

- `KPI_Name` 跨卡片重复：`"vs LY"` 出现 7 次，`"TAR ACH%"` 出现 6 次，`"vs AVG ROI"` 出现 3 次
- `SELECTEDVALUE(Dim_Metric_KPIs[KPI_Name])` 在这些重复行上会返回 BLANK（多值无法确定）
- **必须使用 `KPI_ID`**（全局唯一 1~32）进行 SWITCH 路由
- 每个 KPI_ID 对应独立的计算逻辑，即使 KPI_Name 相同

### 8.2 事实表最大日期

- `MAXX(ALL(KP_KPIs_sample), KP_KPIs_sample[dt])` 中 `ALL()` 确保忽略所有筛选器
- 即使页面上有日期筛选器、Brand 筛选器等，最大日期始终反映事实表全量数据的最新日期
- 在 `KPIs Cell Value` 中内联计算而非引用 `[Fact_Last_Date]`，是为了避免度量值引用链中的上下文传播差异

### 8.3 日期筛选器在非 DAILY 模式下的行为

- `FILTER(ALL(A_日期表), ...)` 中的 `ALL(A_日期表)` 移除 A_日期表 上的**所有**筛选
- 这包括日期范围筛选器的选择，因此非 DAILY 模式下日期筛选器无效
- 其他维度表的筛选器（Brand、Platform 等）不受影响，因为 ALL 仅作用于 A_日期表

### 8.4 DAILY 模式的上下文透传

- DAILY 模式直接调用 `[KPIs Base Value]`，不使用 CALCULATE 包装
- 日期筛选器通过 A_日期表 与 KP_KPIs_sample 的关系自然传递到事实表
- 如果需要额外的筛选器组合逻辑，可在 DAILY 分支中添加 CALCULATE

### 8.5 比率指标在时间范围覆盖下的正确性

- `CALCULATE([KPIs Base Value], FILTER(...))` 修改外部筛选上下文
- `KPIs Base Value` 中的 `DIVIDE(SUM(A), SUM(B))` 在新上下文下计算
- 等效于 `DIVIDE(CALCULATE(SUM(A), 日期范围), CALCULATE(SUM(B), 日期范围))`
- 分子分母均在同一日期范围内聚合，比率结果正确

### 8.6 WEEKDAY 函数说明

- `WEEKDAY(date, 2)` 返回值：Monday=1, Tuesday=2, ..., Sunday=7
- WTD 起始日计算：`date - WEEKDAY(date, 2) + 1` 始终回退到当周周一
- 如业务需要周日为周起始日，改用 `WEEKDAY(date, 1)` 并调整公式

### 8.7 KPI 颜色配置逻辑

- **Major 行**：4 色列全部设为 `#212121`（不做条件颜色），统一黑色显示
- **Sub 行**：启用正/负/零三色 — `#1A9018`(草绿) / `#D64550`(玫瑰红) / `#E1C233`(亮黄)
- 颜色在 `Dim_Metric_KPIs` 表中按行维护，修改颜色无需改动度量值
- 如需个别 Sub 行使用不同配色（如反向 KPI），直接修改该行的颜色列

### 8.8 delta_bp 基点计算

- 基点（basis point）= 0.01%，即 1bp = 0.0001
- 度量值返回的是小数差值（如 New Customer Cost% 同比差 = 0.0014）
- `KPIs Cell Display` 中 `delta_bp` 分支会乘以 10000 转换为基点（0.0014 × 10000 = 14bp）
- `KPIs Base Value` 中占比类指标的 vs LY / TAR ACH% 直接返回小数差值即可

---

## 9. 操作清单（Checklist）

- [ ] 创建 `_Measures` 表并隐藏 Value 列（如已存在则跳过）
- [ ] 创建 `Slicer_Time_Frame` 计算表（5 行 × 9 列）— 已有则跳过
- [ ] 创建 `Dim_Metric_KPIs` 计算表（32 行 × 11 列）— 已有则跳过
- [ ] 配置 Sort by Column：`KPI_Name` → `KPI_Sort`
- [ ] 验证：`Slicer_Time_Frame` 和 `Dim_Metric_KPIs` 不与任何表建立关系
- [ ] 验证：`A_日期表[Date]` 与 `KP_KPIs_sample[dt]` 存在多对一关系
- [ ] 创建度量值 `Fact_Last_Date`（Base Metrics 文件夹）
- [ ] 创建度量值 `KPIs Base Value`（Base Metrics 文件夹，32 个 SWITCH 分支）
- [ ] 创建度量值 `KPIs Cell Value`（Base Metrics 文件夹）
- [ ] 创建度量值 `KPIs Cell Display`（Formatting 文件夹，完整格式目录）
- [ ] 创建度量值 `KPIs Font Color`（Formatting 文件夹）
- [ ] 配置切片器：TimeFrame 单选 + 日期范围
- [ ] 配置卡片视觉对象（按 KPI_CardIndex 筛选）
- [ ] 应用条件格式：字体颜色 → `[KPIs Font Color]`
- [ ] 验证：TimeFrame = WTD 时，日期筛选器无效
- [ ] 验证：TimeFrame = MTD 时，日期筛选器无效
- [ ] 验证：TimeFrame = QTD 时，日期筛选器无效
- [ ] 验证：TimeFrame = YTD 时，日期筛选器无效
- [ ] 验证：TimeFrame = DAILY 时，日期筛选器控制指标范围
- [ ] 验证：32 个 KPI 的 SWITCH 分支均返回正确值
- [ ] 验证：Major 行字体颜色统一为 #212121 黑色
- [ ] 验证：Sub 行字体颜色随正/负/零变化
- [ ] 验证：delta_bp 格式正确显示为基点（如 +14bp）
- [ ] 替换 `KPIs Base Value` 中的示例列名为实际 KP_KPIs_sample 表字段
- [ ] （扩展为表格时）创建 `KPIs Cell SVG Icon` 并设数据类别为图像 URL
- [ ] （扩展为表格时）创建 `KPIs Cell Background Color` 并应用条件格式
