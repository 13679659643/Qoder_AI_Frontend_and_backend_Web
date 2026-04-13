# Power BI 中国式报表解决方案 — 自定义行列 KPI 矩阵

> status: propose
> created: 2026-04-10
> complexity: 🟡中等
> type: 度量值开发 + 可视化构建

---

## 1. 需求理解

实现一个"中国式报表"矩阵效果：
- **行**：KPI 指标名称（自定义顺序，从 7 开始排序）
- **列**：5 个店铺（TM, JD, DY_Family, DY_WM, RLE_CN）
- **值**：行列唯一确定一个单元格的值（当前阶段使用递增数值占位）
- **特殊要求**：不同 KPI 有不同数据格式和颜色格式，不能用简单的字段拖拽

---

## 2. 整体架构

```
核心思路：维度构造法（Scaffolding Pattern）

DimKPI（KPI维度表）          DimStore（店铺维度表，已有）
    ↓                              ↓
    └────── MatrixData（交叉数据表）──────┘
                    ↓
            DAX 度量值（显示值 + 条件格式）
                    ↓
            Matrix 视觉对象（行=KPI，列=Store）
```

**为什么不能用简单拖拽？**
1. KPI 行头需要自定义排序（非字母序）
2. 不同 KPI 的数据格式不同（金额 $250k、百分比 40%、带正负号 +14%）
3. 需要对不同 KPI 行应用不同的颜色格式
4. 需要对行头标签做精确控制

---

## 3. 实施步骤

### Step 1: 创建 KPI 维度表（DAX 计算表）

在 Power BI Desktop 中，新建 → 新建表 → 输入以下 DAX：

```dax
DimKPI = 
DATATABLE(
    "KPI_ID",       INTEGER,
    "KPI_Name",     STRING,
    "KPI_Sort",     INTEGER,
    "KPI_Format",   STRING,
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

**说明**：
- `KPI_ID`：KPI 的唯一标识（1~17）
- `KPI_Name`：KPI 的显示名称
- `KPI_Sort`：排序值，从 7 开始（7, 8, 9, ... 23）
- `KPI_Format`：格式类型标识，供后续条件格式使用
  - `currency`：货币格式（$250k）
  - `percent`：百分比格式（40%、58%、95%）
  - `delta_pct`：带正负号的百分比（+14%）
  - `number`：数值格式（114k）

### Step 2: 构建 MatrixData 交叉数据表（DAX 计算表）

使用 CROSSJOIN 生成 KPI × Store 的全排列，并赋予递增占位值：

```dax
MatrixData = 
VAR __CrossTable = 
    CROSSJOIN(
        SELECTCOLUMNS(DimKPI, "KPI_ID", DimKPI[KPI_ID]),
        SELECTCOLUMNS(DimStore, "Store_ID", DimStore[Store_ID])
    )
VAR __WithRowNum = 
    ADDCOLUMNS(
        __CrossTable,
        "Value", 
            // 行列递增值：(KPI_ID - 1) * 店铺数量 + Store排序
            // KPI_ID 从 1 开始，每个 KPI 跨 5 个店铺
            VAR __KPI = [KPI_ID]
            VAR __StoreSort = 
                LOOKUPVALUE(DimStore[Store_Sort], DimStore[Store_ID], [Store_ID])
            RETURN
                (__KPI - 1) * 5 + __StoreSort
    )
RETURN
    __WithRowNum
```

> **注意**：这里引用了 `DimStore[Store_Sort]` 字段。根据图3的店铺维度表，Store_Sort 的值为：
> - TM = 1, JD = 2, DY_Family = 3, DY_WM = 4, RLE_CN = 5

**生成的 MatrixData 表结构**：

| KPI_ID | Store_ID   | Value |
|--------|-----------|-------|
| 1      | TM        | 1     |
| 1      | JD        | 2     |
| 1      | DY_Family | 3     |
| 1      | DY_WM     | 4     |
| 1      | RLE_CN    | 5     |
| 2      | TM        | 6     |
| 2      | JD        | 7     |
| ...    | ...       | ...   |
| 17     | RLE_CN    | 85    |

共 17 × 5 = 85 行。

### Step 3: 建立关系

在模型视图中建立以下关系：

```
DimKPI[KPI_ID]    ──1:N──>  MatrixData[KPI_ID]       (单向，DimKPI → MatrixData)
DimStore[Store_ID] ──1:N──>  MatrixData[Store_ID]     (单向，DimStore → MatrixData)
```

关系设置：
- 基数：一对多（1:N）
- 交叉筛选方向：单向（从维度表到数据表）
- 两条关系均设为 **活跃**

### Step 4: 配置 KPI 排序（Sort by Column）

在"数据"视图中，选中 `DimKPI` 表：
1. 选中 `KPI_Name` 列
2. 在功能区 → "按列排序" → 选择 `KPI_Sort`

这样 Matrix 视觉对象中 KPI 行会按 `KPI_Sort`（7, 8, 9...23）的顺序展示，而不是字母序。

### Step 5: 创建核心度量值

#### 5.1 基础显示度量值

```dax
// ========================================
// 度量值: Cell Value
// 用途: 矩阵单元格的原始数值
// 依赖: MatrixData 表
// ========================================
Cell Value = 
    SUM(MatrixData[Value])
```

#### 5.2 格式化显示度量值（核心）

由于不同 KPI 需要不同的显示格式，使用一个统一度量值 + FORMAT 函数：

```dax
// ========================================
// 度量值: Cell Display
// 用途: 根据 KPI 格式类型，返回格式化后的文本
// 依赖: [Cell Value], DimKPI[KPI_Format]
// ========================================
Cell Display = 
    VAR __Value = [Cell Value]
    VAR __Format = SELECTEDVALUE(DimKPI[KPI_Format])
    RETURN
        SWITCH(
            __Format,
            -- 货币格式：$250k
            "currency",   FORMAT(__Value, "$#,##0") & "k",
            -- 百分比格式：40%
            "percent",    FORMAT(__Value, "#,##0") & "%",
            -- 带正负号的百分比：+14%
            "delta_pct",  IF(__Value >= 0, "+", "") & FORMAT(__Value, "#,##0") & "%",
            -- 数值格式：114k
            "number",     FORMAT(__Value, "#,##0") & "k",
            -- 默认
            FORMAT(__Value, "#,##0")
        )
```

> **说明**：当前阶段 `[Cell Value]` 返回的是 1~85 的递增占位值。
> 未来替换为真实数据后，只需修改 MatrixData 表的 Value 来源，
> `Cell Display` 的格式化逻辑不需要改动。

#### 5.3 条件格式度量值（颜色控制）

```dax
// ========================================
// 度量值: Cell Font Color
// 用途: 根据 KPI 类型和值的正负，返回字体颜色
// 依赖: [Cell Value], DimKPI[KPI_Format]
// ========================================
Cell Font Color = 
    VAR __Value = [Cell Value]
    VAR __Format = SELECTEDVALUE(DimKPI[KPI_Format])
    RETURN
        SWITCH(
            TRUE(),
            -- delta 类型：正值绿色，负值红色，零值灰色
            __Format = "delta_pct" && __Value > 0,   "#2E7D32",   // 深绿
            __Format = "delta_pct" && __Value < 0,   "#C62828",   // 深红
            __Format = "delta_pct" && __Value = 0,   "#757575",   // 灰色
            -- 百分比类型：低于阈值红色（示例：低于 50% 标红）
            __Format = "percent" && __Value < 50,    "#E65100",   // 橙色
            -- 默认黑色
            "#212121"
        )
```

```dax
// ========================================
// 度量值: Cell Background Color
// 用途: 根据 KPI 类型返回单元格背景色（偶数行浅灰色）
// 依赖: DimKPI[KPI_Sort]
// ========================================
Cell Background Color = 
    VAR __Sort = SELECTEDVALUE(DimKPI[KPI_Sort])
    RETURN
        IF(
            MOD(__Sort, 2) = 0,
            "#F5F5F5",    // 偶数行：浅灰色
            "#FFFFFF"     // 奇数行：白色
        )
```

### Step 6: 配置 Matrix 视觉对象

1. 在报表页面插入 **矩阵（Matrix）** 视觉对象
2. 字段配置：

| 区域 | 字段 |
|------|------|
| **行** | `DimKPI[KPI_Name]` |
| **列** | `DimStore[Store_ID]`（或 `Store_Label` 用于显示中文名） |
| **值** | `[Cell Display]`（格式化文本度量值） |

3. 排序配置：
   - 行：按 `KPI_Sort` 排序（已通过 Step 4 的 Sort by Column 配置）
   - 列：按 `DimStore[Store_Sort]` 排序（对 `Store_ID` 或 `Store_Label` 列设置 Sort by Column）

4. 格式设置（格式面板）：
   - 关闭"阶梯布局"（Stepped Layout → Off）
   - 关闭"行小计"和"列小计"
   - 关闭"+/-" 展开按钮
   - 列标题：居中对齐，加粗
   - 行标题：左对齐
   - 值：居中对齐

### Step 7: 应用条件格式

对 `[Cell Display]` 值区域设置条件格式：

1. **字体颜色**：
   - 右键值区域 → 条件格式 → 字体颜色
   - 格式样式：字段值
   - 基于字段：`[Cell Font Color]`

2. **背景颜色**：
   - 右键值区域 → 条件格式 → 背景颜色
   - 格式样式：字段值
   - 基于字段：`[Cell Background Color]`

### Step 8: 列标题显示优化（可选）

如果希望列头显示图1中的友好名称（Tmall, JD, DY-FS, DY-WM, RL.CN），
而非 Store_ID 的原始值，有两种方式：

**方式 A：使用 Store_Label 列**
在 Matrix 的列区域使用 `DimStore[Store_Label]` 替代 `Store_ID`，
并对 `Store_Label` 设置 Sort by Column = `Store_Sort`。

**方式 B：新增显示列**
如果 Store_Label 是中文名，可以在 DimStore 中新增一列：

```dax
Store_Display = 
    SWITCH(
        DimStore[Store_ID],
        "TM",        "Tmall",
        "JD",        "JD",
        "DY_Family", "DY-FS",
        "DY_WM",     "DY-WM",
        "RLE_CN",    "RL.CN",
        DimStore[Store_ID]
    )
```

然后对 `Store_Display` 设置 Sort by Column = `Store_Sort`，在 Matrix 列区域使用此列。

---

## 4. 完整数据模型关系图

```
DimKPI                              DimStore
┌──────────────────┐                ┌──────────────────┐
│ KPI_ID (PK)      │                │ Store_ID (PK)    │
│ KPI_Name         │                │ Store_Label      │
│ KPI_Sort         │                │ Store_Sort       │
│ KPI_Format       │                │ Store_Display    │
└────────┬─────────┘                └────────┬─────────┘
         │ 1:N                               │ 1:N
         │                                   │
         ▼                                   ▼
         ┌───────────────────────────────────┐
         │          MatrixData               │
         │ ─────────────────────────────────│
         │ KPI_ID (FK)                       │
         │ Store_ID (FK)                     │
         │ Value                             │
         └───────────────────────────────────┘
```

---

## 5. 递增占位值验证

生成的 MatrixData 表完整预览（17 KPI × 5 Store = 85 行）：

| KPI_Name | TM | JD | DY_Family | DY_WM | RLE_CN |
|----------|----|----|-----------|-------|--------|
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

## 6. 未来扩展方向

### 6.1 接入真实数据
将 `MatrixData[Value]` 替换为真实数据源。两种方式：

**方式 A：直接修改 MatrixData 为查询表**
将 MatrixData 改为从数据库/Excel 导入，保留 KPI_ID + Store_ID + Value 结构。

**方式 B：使用 SWITCH 度量值**
如果数据来自多个事实表，可以用 SWITCH 根据 KPI_ID 调用不同的底层度量值：

```dax
Cell Value = 
    VAR __KPI_ID = SELECTEDVALUE(DimKPI[KPI_ID])
    RETURN
        SWITCH(
            __KPI_ID,
            1,  [Actual Cost],
            2,  [Cost Achievement %],
            3,  [Sales Decomposition],
            4,  [Sales Achievement %],
            5,  [Cost vs Sales ACH%],
            6,  [New Customer Count],
            7,  [New Customer TAR ACH%],
            8,  [New Customer Investment Rate],
            9,  [New Customer Inv Rate TAR ACH%],
            10, [New Customer Investment ROI],
            11, [Cost Per New Acquisition],
            12, [Acquisition Sales],
            13, [Acceleration Sales],
            14, [Acceleration Sales ACH%],
            15, [Acceleration Investment MOB%],
            16, [Acceleration Inv MOB% ACH%],
            17, [Acceleration Cost ROI],
            BLANK()
        )
```

此方式的 `Cell Display` 格式化度量值无需修改，因为 KPI_Format 已内置在 DimKPI 中。

### 6.2 新增 KPI 行
只需在 `DimKPI` 表中追加新行，设置 `KPI_Sort` 值（如 24, 25...），MatrixData 会自动扩展。

### 6.3 新增店铺列
只需在 `DimStore` 维度表中追加新店铺记录，设置 `Store_Sort` 值，MatrixData 的 CROSSJOIN 会自动纳入。

### 6.4 更精细的条件格式
可以为每个 KPI 定义独立的阈值和颜色规则，在 DimKPI 中增加列：

```dax
-- 在 DimKPI 中增加阈值列
DimKPI（扩展版）= 
DATATABLE(
    "KPI_ID", INTEGER,
    "KPI_Name", STRING,
    "KPI_Sort", INTEGER,
    "KPI_Format", STRING,
    "Threshold_Good", DOUBLE,   -- 好的阈值
    "Threshold_Bad", DOUBLE,    -- 差的阈值
    "Color_Good", STRING,       -- 好的颜色
    "Color_Bad", STRING,        -- 差的颜色
    {
        { 1, "Cost", 7, "currency", 200, 300, "#2E7D32", "#C62828" },
        ...
    }
)
```

---

## 7. 注意事项

1. **Cell Display 返回的是文本**：由于不同 KPI 格式不同，统一度量值返回的是 FORMAT 后的文本。如果需要对值本身做排序/筛选，需使用 `[Cell Value]` 数值度量值。

2. **Matrix 排序依赖 Sort by Column**：确保在数据视图中正确配置了 KPI_Name → KPI_Sort 和 Store_Display → Store_Sort 的 Sort by Column 关系。

3. **性能**：当前方案使用计算表，数据量小（85行），性能无压力。接入真实数据后，如果改用 SWITCH 度量值方式（Step 6.1 方式 B），需注意 SWITCH 中每个子度量值的性能。

4. **Store_Sort 字段**：确认 DimStore 表中 Store_Sort 列的值为：TM=1, JD=2, DY_Family=3, DY_WM=4, RLE_CN=5。如果不存在此列，需手动添加。

---

## 8. 操作清单（Checklist）

- [ ] 在 Power BI Desktop 中创建 DimKPI 计算表（Step 1）
- [ ] 创建 MatrixData 计算表（Step 2）
- [ ] 在模型视图中建立两条关系（Step 3）
- [ ] 配置 KPI_Name 的 Sort by Column = KPI_Sort（Step 4）
- [ ] 创建度量值：Cell Value、Cell Display、Cell Font Color、Cell Background Color（Step 5）
- [ ] 插入 Matrix 视觉对象并配置字段（Step 6）
- [ ] 应用条件格式（Step 7）
- [ ] 可选：创建 Store_Display 列优化列标题（Step 8）
- [ ] 验证：确认 17 行 × 5 列全部显示，排序正确，值递增 1~85
