# Power BI 中国式报表解决方案 — 自定义行列 KPI 矩阵

> status: propose
> created: 2026-04-10
> updated: 2026-04-13
> complexity: 🟡中等
> type: 度量值开发 + 可视化构建
> naming: 遵循 powerbi_code_copilot/rules/dax-style.md 规范

---

## 1. 需求理解

实现一个"中国式报表"矩阵效果：
- **行**：KPI 指标名称（自定义顺序，从 7 开始排序）
- **列**：5 个店铺（TM, JD, DY_Family, DY_WM, RLE_CN），引用 `Dim_Store[Store_ID]`
- **值**：行列唯一确定一个单元格的值（当前阶段使用递增数值占位，未来 SWITCH 路由到真实度量值）
- **特殊要求**：不同 KPI 有不同数据格式和颜色格式，不能用简单的字段拖拽

---

## 2. 整体架构

```
核心思路：维度脚手架 + SWITCH 动态路由（Scaffold + Dispatch Pattern）

Dim_KPI（KPI维度表）           Dim_Store（店铺维度表，已有）
    ↓                                ↓
    └────── CT_Scaffold（脚手架表）──────┘
                  ↓                        无 Value 列，仅 FK 骨架
            SWITCH 动态路由度量值           根据行列上下文自动分发
                  ↓
            Matrix 视觉对象（行=KPI，列=Store）
```

### 与旧方案的核心区别

| 对比项 | 旧方案（物理交叉表） | 新方案（SWITCH 动态路由） |
|--------|---------------------|------------------------|
| 数据存储 | CT_Scaffold 表存储 Value 列 | CT_Scaffold 仅存储 KPI_ID + Store_ID 骨架 |
| 值计算 | SUM(Value) 直接聚合 | SWITCH 根据 KPI_ID 路由到对应子度量值 |
| 扩展性 | 改数据需重建交叉表 | 新增 KPI 只需在 SWITCH 中添加一行 |
| 接入真实数据 | 需替换整个交叉表 | 只需替换 SWITCH 中的占位值为真实度量值 |
| 灵活度 | 每个 KPI 只能有一个固定值 | 每个 KPI 可路由到任意复杂度量值 |

**为什么不能用简单拖拽？**
1. KPI 行头需要自定义排序（非字母序）
2. 不同 KPI 的数据格式不同（金额 $250k、百分比 40%、带正负号 +14%）
3. 需要对不同 KPI 行应用不同的颜色格式
4. 需要对行头标签做精确控制

---

## 3. 命名规范映射

> 遵循 `powerbi_code_copilot/rules/dax-style.md`

| 类别 | 命名 | 规则出处 |
|------|------|---------|
| KPI 维度表 | `Dim_KPI` | Dim_ 前缀 — 维度表 |
| 店铺维度表 | `Dim_Store` | Dim_ 前缀 — 维度表（已有） |
| 脚手架表 | `CT_Scaffold` | CT_ 前缀 — DAX 计算表 |
| 度量值表 | `_Measures` | _ 前缀 — 隐藏辅助表 |
| 主键列 | `KPI_ID`, `Store_ID` | Key/ID 后缀 |
| 属性列 | `KPI_Name`, `KPI_Sort`, `KPI_Format` | PascalCase 或项目统一风格 |
| 变量 | `__KPIID`, `__StoreSort`, `__Value` | __ 双下划线前缀 |
| 内部度量值 | `_Cost Placeholder`, `_CostAch Placeholder` | _ 前缀 — 辅助度量值 |

---

## 4. 实施步骤

### Step 1: 创建 KPI 维度表 `Dim_KPI`（DAX 计算表）

在 Power BI Desktop 中，新建 → 新建表 → 输入以下 DAX：

```dax
// ========================================
// 表: Dim_KPI
// 类型: 维度表（Dim_ 前缀）
// 用途: KPI 指标维度，定义行头名称、排序、格式类型
// ========================================
Dim_KPI = 
DATATABLE(
    "KPI_ID",       INTEGER,       // 主键标识，唯一标识每个 KPI
    "KPI_Name",     STRING,        // 显示名称，用于 Matrix 行头
    "KPI_Sort",     INTEGER,       // 排序值，从 7 开始
    "KPI_Format",   STRING,        // 格式类型标识，供条件格式使用
    {
        { 1,  "Cost",                                    7,  "currency"   },
        { 2,  "Cost Ach%",                               8,  "percent"    },
        { 3,  "SLS Dcom",                                9,  "currency"   },
        { 4,  "SLS Ach%",                                10, "percent"    },
        { 5,  "Cost vs SLS ACH%",                        11, "delta_pct"  },
        { 6,  "New customer No",                         12, "number"     },
        { 7,  "New customer No TAR ACH%",                13, "percent"    },
        { 8,  "New customer investment Rate",            14, "percent"    },
        { 9,  "New customer investment Rate TAR ACH%",   15, "delta_pct"  },
        { 10, "New Customer Investment ROI",             16, "percent"    },
        { 11, "Cost per new acquisition",                17, "currency"   },
        { 12, "Acquisition SLS",                         18, "currency"   },
        { 13, "Acceleration SLS",                        19, "currency"   },
        { 14, "Acceleration SLS ach%",                   20, "percent"    },
        { 15, "Acceleration Investment MOB%",            21, "percent"    },
        { 16, "Acceleration Investment MOB% ach%",       22, "delta_pct"  },
        { 17, "Acceleration Cost ROI",                   23, "percent"    }
    }
)
```

**字段说明**：
- `KPI_ID`：主键，1~17
- `KPI_Name`：Matrix 行头显示名称
- `KPI_Sort`：排序值，从 7 开始（7, 8, 9, ... 23）
- `KPI_Format`：格式类型标识
  - `currency`：货币格式（$250k）
  - `percent`：百分比格式（40%、58%、95%）
  - `delta_pct`：带正负号的百分比（+14%）
  - `number`：数值格式（114k）

### Step 2: 构建脚手架表 `CT_Scaffold`（仅骨架，无 Value 列）

脚手架表只存储 KPI 与 Store 的笛卡尔积骨架，**不包含任何数据列**。
所有值由 SWITCH 度量值动态计算：

```dax
// ========================================
// 表: CT_Scaffold
// 类型: 计算表（CT_ 前缀）
// 用途: KPI × Store 的笛卡尔积骨架，确保 Matrix 网格完整
// 说明: 仅含外键列，无 Value 列，所有值由 SWITCH 度量值动态路由
// ========================================
CT_Scaffold = 
CROSSJOIN(
    SELECTCOLUMNS(Dim_KPI, "KPI_ID", Dim_KPI[KPI_ID]),
    SELECTCOLUMNS(Dim_Store, "Store_ID", Dim_Store[Store_ID])
)
```

**生成结果**：17 × 5 = 85 行，每行仅有 `KPI_ID` + `Store_ID` 两列，无任何数据列。

| KPI_ID | Store_ID   |
|--------|-----------|
| 1      | TM        |
| 1      | JD        |
| 1      | DY_Family |
| ...    | ...       |
| 17     | RLE_CN    |

### Step 3: 建立关系

在模型视图中建立以下关系：

```
Dim_KPI[KPI_ID]      ──1:N──>  CT_Scaffold[KPI_ID]     (单向，Dim_KPI → CT_Scaffold)
Dim_Store[Store_ID]   ──1:N──>  CT_Scaffold[Store_ID]   (单向，Dim_Store → CT_Scaffold)
```

关系设置：
- 基数：一对多（1:N）
- 交叉筛选方向：单向（从维度表到脚手架表）
- 两条关系均设为 **活跃**

### Step 4: 配置 KPI 排序（Sort by Column）

在"数据"视图中，选中 `Dim_KPI` 表：
1. 选中 `KPI_Name` 列
2. 在功能区 → "按列排序" → 选择 `KPI_Sort`

这样 Matrix 视觉对象中 KPI 行会按 `KPI_Sort`（7, 8, 9...23）的顺序展示，而不是字母序。

### Step 5: 创建核心度量值（SWITCH 动态路由）

> 所有度量值建议放在 `_Measures` 隐藏表或使用 Display Folder 组织

#### 5.1 核心路由度量值 — Cell Value（SWITCH 分发器）

这是整个方案的核心：根据当前行上下文（KPI_ID）和列上下文（Store_ID），
通过 SWITCH 动态路由到对应的子度量值。

```dax
// ========================================
// 度量值: Cell Value
// 用途: SWITCH 动态路由分发器，根据 KPI_ID 路由到对应子度量值
// 依赖: Dim_KPI[KPI_ID], Dim_Store[Store_Sort]
// 模式: Scaffold + Dispatch Pattern
// ========================================
Cell Value = 
    VAR __KPIID = SELECTEDVALUE(Dim_KPI[KPI_ID])
    VAR __StoreSort = SELECTEDVALUE(Dim_Store[Store_Sort])
    RETURN
        SWITCH(
            __KPIID,
            // ─── 成本模块 ───
            1,  (__KPIID - 1) * 5 + __StoreSort,     // Cost
                // → 未来替换为: [Actual Cost]
            2,  (__KPIID - 1) * 5 + __StoreSort,     // Cost Ach%
                // → 未来替换为: [KPI_CostAchievement]
            3,  (__KPIID - 1) * 5 + __StoreSort,     // SLS Dcom
                // → 未来替换为: [Total SLS Dcom]
            4,  (__KPIID - 1) * 5 + __StoreSort,     // SLS Ach%
                // → 未来替换为: [KPI_SLSAchievement]
            5,  (__KPIID - 1) * 5 + __StoreSort,     // Cost vs SLS ACH%
                // → 未来替换为: [CAL_CostVsSalesACH]
            // ─── 新客模块 ───
            6,  (__KPIID - 1) * 5 + __StoreSort,     // New customer No
                // → 未来替换为: [New Customer Count]
            7,  (__KPIID - 1) * 5 + __StoreSort,     // New customer No TAR ACH%
                // → 未来替换为: [KPI_NewCustTARAch]
            8,  (__KPIID - 1) * 5 + __StoreSort,     // New customer investment Rate
                // → 未来替换为: [RATIO_NewCustInvestRate]
            9,  (__KPIID - 1) * 5 + __StoreSort,     // New customer investment Rate TAR ACH%
                // → 未来替换为: [KPI_NewCustInvRateTARAch]
            10, (__KPIID - 1) * 5 + __StoreSort,     // New Customer Investment ROI
                // → 未来替换为: [KPI_NewCustInvestROI]
            11, (__KPIID - 1) * 5 + __StoreSort,     // Cost per new acquisition
                // → 未来替换为: [CAL_CostPerAcquisition]
            // ─── 获客与加速模块 ───
            12, (__KPIID - 1) * 5 + __StoreSort,     // Acquisition SLS
                // → 未来替换为: [Total Acquisition SLS]
            13, (__KPIID - 1) * 5 + __StoreSort,     // Acceleration SLS
                // → 未来替换为: [Total Acceleration SLS]
            14, (__KPIID - 1) * 5 + __StoreSort,     // Acceleration SLS ach%
                // → 未来替换为: [KPI_AccelSLSAch]
            15, (__KPIID - 1) * 5 + __StoreSort,     // Acceleration Investment MOB%
                // → 未来替换为: [RATIO_AccelInvestMOB]
            16, (__KPIID - 1) * 5 + __StoreSort,     // Acceleration Investment MOB% ach%
                // → 未来替换为: [KPI_AccelInvestMOBAch]
            17, (__KPIID - 1) * 5 + __StoreSort,     // Acceleration Cost ROI
                // → 未来替换为: [KPI_AccelCostROI]
            BLANK()
        )
```

**SWITCH 分发的工作原理**：
```
用户在 Matrix 中看到的每个单元格：
    行上下文 → Dim_KPI 筛选 → SELECTEDVALUE(KPI_ID) = 当前 KPI
    列上下文 → Dim_Store 筛选 → SELECTEDVALUE(Store_Sort) = 当前店铺
    SWITCH 匹配 KPI_ID → 路由到对应的计算逻辑
    结果 → 返回该单元格的值
```

**当前阶段**：所有 KPI 统一返回递增占位值 `(KPI_ID - 1) * 5 + StoreSort`。
**未来接入真实数据**：只需将每行的占位表达式替换为真实度量值引用（注释中已标注）。

#### 5.2 格式化显示度量值（核心）

```dax
// ========================================
// 度量值: Cell Display
// 用途: 根据 KPI 格式类型，返回格式化后的文本
// 依赖: [Cell Value], Dim_KPI[KPI_Format]
// ========================================
Cell Display = 
    VAR __Value = [Cell Value]
    VAR __Format = SELECTEDVALUE(Dim_KPI[KPI_Format])
    RETURN
        SWITCH(
            __Format,
            "currency",   FORMAT(__Value, "$#,##0") & "k",                           // 货币：$250k
            "percent",    FORMAT(__Value, "#,##0") & "%",                             // 百分比：40%
            "delta_pct",  IF(__Value >= 0, "+", "") & FORMAT(__Value, "#,##0") & "%", // 增减：+14%
            "number",     FORMAT(__Value, "#,##0") & "k",                             // 数值：114k
            FORMAT(__Value, "#,##0")                                                  // 默认
        )
```

#### 5.3 条件格式度量值（颜色控制）

```dax
// ========================================
// 度量值: Cell Font Color
// 用途: 根据 KPI 类型和值的正负，返回字体颜色
// 依赖: [Cell Value], Dim_KPI[KPI_Format]
// ========================================
Cell Font Color = 
    VAR __Value = [Cell Value]
    VAR __Format = SELECTEDVALUE(Dim_KPI[KPI_Format])
    RETURN
        SWITCH(
            TRUE(),
            __Format = "delta_pct" && __Value > 0,   "#2E7D32",   // delta 正值 → 深绿
            __Format = "delta_pct" && __Value < 0,   "#C62828",   // delta 负值 → 深红
            __Format = "delta_pct" && __Value = 0,   "#757575",   // delta 零值 → 灰色
            __Format = "percent" && __Value < 50,    "#E65100",   // 百分比低值 → 橙色
            "#212121"                                              // 默认 → 黑色
        )
```

```dax
// ========================================
// 度量值: Cell Background Color
// 用途: 根据 KPI 行号返回单元格背景色（交替行底色）
// 依赖: Dim_KPI[KPI_Sort]
// ========================================
Cell Background Color = 
    VAR __Sort = SELECTEDVALUE(Dim_KPI[KPI_Sort])
    RETURN
        IF(
            MOD(__Sort, 2) = 0,
            "#F5F5F5",    // 偶数行：浅灰色
            "#FFFFFF"     // 奇数行：白色
        )
```

### Step 6: 列标题显示优化

在 `Dim_Store` 中新增计算列用于 Matrix 列头显示：

```dax
// ========================================
// 计算列: Dim_Store[Store_Display]
// 用途: Matrix 列头友好显示名称
// ========================================
Store_Display = 
    SWITCH(
        Dim_Store[Store_ID],
        "TM",        "Tmall",
        "JD",        "JD",
        "DY_Family", "DY-FS",
        "DY_WM",     "DY-WM",
        "RLE_CN",    "RL.CN",
        Dim_Store[Store_ID]
    )
```

对 `Store_Display` 设置 Sort by Column = `Store_Sort`。

### Step 7: 配置 Matrix 视觉对象

1. 在报表页面插入 **矩阵（Matrix）** 视觉对象
2. 字段配置：

| 区域 | 字段 |
|------|------|
| **行** | `Dim_KPI[KPI_Name]` |
| **列** | `Dim_Store[Store_Display]` |
| **值** | `[Cell Display]`（格式化文本度量值） |

3. 排序配置：
   - 行：`KPI_Name` 按 `KPI_Sort` 排序（已通过 Step 4 的 Sort by Column 配置）
   - 列：`Store_Display` 按 `Store_Sort` 排序

4. 格式设置（格式面板）：
   - 关闭"阶梯布局"（Stepped Layout → Off）
   - 关闭"行小计"和"列小计"
   - 关闭"+/-" 展开按钮
   - 列标题：居中对齐，加粗
   - 行标题：左对齐
   - 值：居中对齐

### Step 8: 应用条件格式

对 `[Cell Display]` 值区域设置条件格式：

1. **字体颜色**：
   - 右键值区域 → 条件格式 → 字体颜色
   - 格式样式：字段值
   - 基于字段：`[Cell Font Color]`

2. **背景颜色**：
   - 右键值区域 → 条件格式 → 背景颜色
   - 格式样式：字段值
   - 基于字段：`[Cell Background Color]`

---

## 5. 完整数据模型关系图

```
Dim_KPI (维度表)                      Dim_Store (维度表，已有)
┌──────────────────────┐              ┌──────────────────────┐
│ KPI_ID (PK)          │              │ Store_ID (PK)        │
│ KPI_Name             │              │ Store_Label          │
│ KPI_Sort             │              │ Store_Sort           │
│ KPI_Format           │              │ Store_Display (新增)  │
└──────────┬───────────┘              └──────────┬───────────┘
           │ 1:N                                 │ 1:N
           ▼                                     ▼
           ┌─────────────────────────────────────┐
           │        CT_Scaffold (脚手架表)         │
           │ ───────────────────────────────────  │
           │  KPI_ID (FK)                         │
           │  Store_ID (FK)                       │
           │  【无 Value 列 — 值由 SWITCH 动态计算】│
           └─────────────────────────────────────┘
                          ▲
                          │ 被引用
                          │
           ┌─────────────────────────────────────┐
           │     SWITCH 动态路由度量值              │
           │ ───────────────────────────────────  │
           │  [Cell Value]      → 路由到子度量值    │
           │  [Cell Display]    → 格式化显示        │
           │  [Cell Font Color] → 字体颜色         │
           │  [Cell Background Color] → 背景色     │
           └─────────────────────────────────────┘
```

---

## 6. SWITCH 动态路由的值验证

当前占位公式 `(KPI_ID - 1) * 5 + Store_Sort` 生成的矩阵：

| KPI_Name | Tmall | JD | DY-FS | DY-WM | RL.CN |
|----------|-------|----|-------|-------|-------|
| Cost | 1 | 2 | 3 | 4 | 5 |
| Cost Ach% | 6 | 7 | 8 | 9 | 10 |
| SLS Dcom | 11 | 12 | 13 | 14 | 15 |
| SLS Ach% | 16 | 17 | 18 | 19 | 20 |
| Cost vs SLS ACH% | 21 | 22 | 23 | 24 | 25 |
| New customer No | 26 | 27 | 28 | 29 | 30 |
| New customer No TAR ACH% | 31 | 32 | 33 | 34 | 35 |
| New customer investment Rate | 36 | 37 | 38 | 39 | 40 |
| New customer investment Rate TAR ACH% | 41 | 42 | 43 | 44 | 45 |
| New Customer Investment ROI | 46 | 47 | 48 | 49 | 50 |
| Cost per new acquisition | 51 | 52 | 53 | 54 | 55 |
| Acquisition SLS | 56 | 57 | 58 | 59 | 60 |
| Acceleration SLS | 61 | 62 | 63 | 64 | 65 |
| Acceleration SLS ach% | 66 | 67 | 68 | 69 | 70 |
| Acceleration Investment MOB% | 71 | 72 | 73 | 74 | 75 |
| Acceleration Investment MOB% ach% | 76 | 77 | 78 | 79 | 80 |
| Acceleration Cost ROI | 81 | 82 | 83 | 84 | 85 |

---

## 7. 接入真实数据（SWITCH 替换指南）

接入真实数据时，**只需修改 `Cell Value` 度量值中 SWITCH 的每一行**，
将占位表达式替换为对应的真实子度量值。其他所有度量值（Cell Display、颜色）无需改动。

### 替换示例

```dax
// ========================================
// 度量值: Cell Value（真实数据版本）
// 用途: SWITCH 动态路由分发器 — 真实度量值版
// 依赖: 各业务子度量值 + Dim_KPI[KPI_ID]
// 说明: 每个 KPI 路由到独立的业务度量值，
//       子度量值已通过 Dim_Store 关系自动筛选到当前店铺
// ========================================
Cell Value = 
    VAR __KPIID = SELECTEDVALUE(Dim_KPI[KPI_ID])
    RETURN
        SWITCH(
            __KPIID,
            // ─── 成本模块 ───
            1,  [Actual Cost],                  // Cost
            2,  [KPI_CostAchievement],          // Cost Ach%
            3,  [Total SLS Dcom],               // SLS Dcom
            4,  [KPI_SLSAchievement],           // SLS Ach%
            5,  [CAL_CostVsSalesACH],           // Cost vs SLS ACH%
            // ─── 新客模块 ───
            6,  [New Customer Count],           // New customer No
            7,  [KPI_NewCustTARAch],            // New customer No TAR ACH%
            8,  [RATIO_NewCustInvestRate],       // New customer investment Rate
            9,  [KPI_NewCustInvRateTARAch],     // New customer investment Rate TAR ACH%
            10, [KPI_NewCustInvestROI],          // New Customer Investment ROI
            11, [CAL_CostPerAcquisition],       // Cost per new acquisition
            // ─── 获客与加速模块 ───
            12, [Total Acquisition SLS],        // Acquisition SLS
            13, [Total Acceleration SLS],       // Acceleration SLS
            14, [KPI_AccelSLSAch],              // Acceleration SLS ach%
            15, [RATIO_AccelInvestMOB],          // Acceleration Investment MOB%
            16, [KPI_AccelInvestMOBAch],         // Acceleration Investment MOB% ach%
            17, [KPI_AccelCostROI],              // Acceleration Cost ROI
            BLANK()
        )
```

**关键点**：
- 每个子度量值（如 `[Actual Cost]`）从各自的事实表中计算
- Store 维度的筛选通过 `Dim_Store → CT_Scaffold` 的关系自动传播
- 子度量值本身不需要关心当前选中了哪个店铺，筛选器上下文会自动处理
- 子度量值命名遵循 dax-style.md 前缀规范：`KPI_`、`CAL_`、`RATIO_`、无前缀（基础聚合）

### 子度量值命名约定

| 子度量值名称 | 命名前缀 | 说明 |
|-------------|---------|------|
| `Actual Cost` | 无前缀 | 基础聚合 SUM |
| `Total SLS Dcom` | 无前缀 | 基础聚合 SUM |
| `New Customer Count` | 无前缀 | 基础聚合 DISTINCTCOUNT |
| `KPI_CostAchievement` | KPI_ | 关键绩效指标（达成率） |
| `KPI_SLSAchievement` | KPI_ | 关键绩效指标（达成率） |
| `CAL_CostVsSalesACH` | CAL_ | 复杂计算指标（对比） |
| `CAL_CostPerAcquisition` | CAL_ | 复杂计算指标（单位成本） |
| `RATIO_NewCustInvestRate` | RATIO_ | 比率指标 |
| `RATIO_AccelInvestMOB` | RATIO_ | 比率指标 |

---

## 8. 扩展方向

### 8.1 新增 KPI 行
1. 在 `Dim_KPI` 表中追加新行，设置 `KPI_Sort` 值（如 24, 25...）
2. 在 `Cell Value` 的 SWITCH 中追加对应路由行
3. `CT_Scaffold` 的 CROSSJOIN 会自动扩展骨架

### 8.2 新增店铺列
只需在 `Dim_Store` 维度表中追加新店铺记录，设置 `Store_Sort` 值。
CT_Scaffold 和 SWITCH 均自动适配，无需改动。

### 8.3 更精细的条件格式
可以为每个 KPI 定义独立的阈值和颜色规则，在 `Dim_KPI` 中增加列：

```dax
// Dim_KPI 扩展版 — 增加阈值列
Dim_KPI = 
DATATABLE(
    "KPI_ID",         INTEGER,
    "KPI_Name",       STRING,
    "KPI_Sort",       INTEGER,
    "KPI_Format",     STRING,
    "ThresholdGood",  DOUBLE,       // 好的阈值
    "ThresholdBad",   DOUBLE,       // 差的阈值
    "ColorGood",      STRING,       // 好的颜色
    "ColorBad",       STRING,       // 差的颜色
    {
        { 1, "Cost", 7, "currency", 200, 300, "#2E7D32", "#C62828" },
        ...
    }
)
```

---

## 9. 注意事项

1. **Cell Display 返回的是文本**：由于不同 KPI 格式不同，统一度量值返回 FORMAT 后的文本。如需对值排序/筛选，使用 `[Cell Value]` 数值度量值。

2. **Matrix 排序依赖 Sort by Column**：确保在数据视图中正确配置了 `KPI_Name` → `KPI_Sort` 和 `Store_Display` → `Store_Sort` 的 Sort by Column 关系。

3. **性能**：CT_Scaffold 仅 85 行（17×5），无性能压力。SWITCH 度量值在当前规模（17 路由）下性能良好。接入真实数据后，需关注各子度量值本身的性能。

4. **Store_Sort 字段**：确认 `Dim_Store` 表中 `Store_Sort` 列值为：TM=1, JD=2, DY_Family=3, DY_WM=4, RLE_CN=5。

5. **SWITCH 的 BLANK() 兜底**：当 `KPI_ID` 不匹配任何已定义值时返回 BLANK()，避免 Matrix 中显示错误数据。

---

## 10. 操作清单（Checklist）

- [ ] 创建 `Dim_KPI` 计算表（Step 1）
- [ ] 创建 `CT_Scaffold` 脚手架表（Step 2）
- [ ] 在模型视图中建立两条 1:N 关系（Step 3）
- [ ] 配置 `KPI_Name` 的 Sort by Column = `KPI_Sort`（Step 4）
- [ ] 创建 SWITCH 路由度量值 `[Cell Value]`（Step 5.1）
- [ ] 创建格式化度量值 `[Cell Display]`（Step 5.2）
- [ ] 创建条件格式度量值 `[Cell Font Color]`、`[Cell Background Color]`（Step 5.3）
- [ ] 创建 `Dim_Store[Store_Display]` 计算列（Step 6）
- [ ] 插入 Matrix 视觉对象并配置字段（Step 7）
- [ ] 应用条件格式（Step 8）
- [ ] 验证：确认 17 行 × 5 列全部显示，排序正确，值递增 1~85
