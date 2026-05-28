# 切片器知识库

> Power BI 切片器（Slicer）设计、参数表规范与断开维度的核心知识和实践经验。

## 1. 参数表（Slicer 维度表）规范

### 核心概念
参数表（Parameter Table）是一种使用 `DATATABLE` 函数硬编码在 DAX 中的断开维度表，不与数据模型中的任何事实表建立关系，专用于驱动切片器选项和报表动态行为。

### 通用字段模板
每张参数表应包含以下标准字段：

**必选字段**
| 字段名 | 类型 | 说明 |
|--------|------|------|
| `{Entity}_ID` | STRING / INTEGER | 主键标识，唯一标识每个选项，可用于 SELECTEDVALUE 读取 |
| `{Entity}_Label` | STRING | 显示标签，在切片器界面向用户展示的名称 |
| `{Entity}_Sort` | INTEGER | 排序顺序，控制选项在切片器中的显示顺序 |
| `{Entity}_Description` | STRING | 详细描述，说明该选项的具体含义 |

**可选字段**
| 字段名 | 类型 | 说明 |
|--------|------|------|
| `{Entity}_IsDefault` | BOOLEAN | 是否默认选中，TRUE 表示报表初始状态默认选择此项 |
| `{Entity}_IsActive` | BOOLEAN | 是否激活状态，控制该选项是否可用 |
| `{Entity}_Group` | STRING | 分组标识，用于对相关选项进行逻辑分组 |

### DATATABLE 基本结构
```dax
Slicer_TableName = 
DATATABLE(
    "Entity_ID",          STRING,
    "Entity_Label",       STRING,
    "Entity_Sort",        INTEGER,
    "Entity_Description", STRING,
    "Entity_IsDefault",   BOOLEAN,
    "Entity_IsActive",    BOOLEAN,
    "Entity_Group",       STRING,
    {
        { "ID_1", "显示名称1", 1, "描述1", TRUE,  TRUE, "分组A" },
        { "ID_2", "显示名称2", 2, "描述2", FALSE, TRUE, "分组A" }
    }
)
```

---

## 2. 平台切片器（Platform）示例

### 完整示例
```dax
Slicer_Platform_Selection = 
DATATABLE(
    "Platform_ID",          STRING,
    "Platform_Label",       STRING,
    "Platform_Sort",        INTEGER,
    "Platform_Description", STRING,
    "Platform_IsDefault",   BOOLEAN,
    "Platform_IsActive",    BOOLEAN,
    "Platform_Group",       STRING,
    "Platform_Type",        STRING,
    "Platform_Icon",        STRING,
    {
        // TM - 天猫
        {
            "TM", "天猫", 5,
            "阿里巴巴集团旗下的B2C电商平台，定位为品质购物商城，主要销售品牌商品",
            TRUE, TRUE, "B2C综合平台", "综合电商", "🐱"
        },
        // JD - 京东
        {
            "JD", "京东", 6,
            "中国自营式电商平台，以物流快速和正品保障著称，主要销售电子产品、家电等",
            FALSE, TRUE, "B2C综合平台", "综合电商", "🐶"
        }
    }
)
```

### 设计要点
- `Platform_ID` 使用统一的平台代码（TM / JD / PDD 等），便于在度量值中用 `SELECTEDVALUE` 匹配
- `Platform_Sort` 控制切片器的显示顺序，数值越小排越前
- `Platform_IsDefault = TRUE` 表示报表打开时该平台默认被选中
- 自定义扩展字段（如 `Platform_Type`、`Platform_Icon`）按业务需求添加，不影响基础规范

---

## 3. 断开维度表（KPI 列维度）

### 核心概念
断开维度（Disconnected Dimension）用于驱动矩阵/表格的列选项，不与任何事实表建立物理关系，度量值通过 `SELECTEDVALUE` 动态读取所选行的配置，从而实现一个度量值驱动多列逻辑。

### DIM_ColMetric_Overview 示例
用于 KPIs Overview 矩阵的列维度，内嵌格式、颜色、汇率标记等配置：

```dax
DIM_ColMetric_Overview = 
DATATABLE(
    "Metric_ID",               INTEGER,
    "Metric_Name",             STRING,
    "Metric_Sort",             INTEGER,
    "Metric_Format_Current",   STRING,
    "Metric_Format_LP",        STRING,
    "Metric_Format_VsLP",      STRING,
    "Metric_IsCurrencyAmount", BOOLEAN,
    "Metric_ColorPositive",    STRING,
    "Metric_ColorNegative",    STRING,
    "Metric_ColorZero",        STRING,
    "Metric_ColorDefault",     STRING,
    {
        { 1,  "Cost",           1,  "currency",    "currency",    "delta_pct_1dp", TRUE,  "#1A9018", "#D64550", "#E1C233", "#212121" },
        { 2,  "红包",           2,  "currency",    "currency",    "delta_pct_1dp", TRUE,  "#1A9018", "#D64550", "#E1C233", "#212121" },
        { 3,  "Cost进度",       3,  "percent_1dp", "percent_1dp", "delta_pct_1dp", FALSE, "#1A9018", "#D64550", "#E1C233", "#212121" },
        { 4,  "NetSales进度",   4,  "percent_1dp", "percent_1dp", "delta_pct_1dp", FALSE, "#1A9018", "#D64550", "#E1C233", "#212121" },
        { 5,  "DemandSales进度",5,  "percent_1dp", "percent_1dp", "delta_pct_1dp", FALSE, "#1A9018", "#D64550", "#E1C233", "#212121" },
        { 6,  "费比",           6,  "percent_1dp", "percent_1dp", "delta_pct_1dp", FALSE, "#1A9018", "#D64550", "#E1C233", "#212121" },
        { 7,  "含红包费比",     7,  "percent_1dp", "percent_1dp", "delta_pct_1dp", FALSE, "#1A9018", "#D64550", "#E1C233", "#212121" },
        { 8,  "ROI",            8,  "decimal_2",   "decimal_2",   "delta_pct_1dp", FALSE, "#1A9018", "#D64550", "#E1C233", "#212121" },
        { 9,  "新客花费占比",   9,  "percent_1dp", "percent_1dp", "delta_pct_1dp", FALSE, "#1A9018", "#D64550", "#E1C233", "#212121" },
        { 10, "新客成本",       10, "currency",    "currency",    "delta_pct_1dp", TRUE,  "#1A9018", "#D64550", "#E1C233", "#212121" },
        { 11, "Acc花费占比",    11, "percent_1dp", "percent_1dp", "delta_pct_1dp", FALSE, "#1A9018", "#D64550", "#E1C233", "#212121" },
        { 12, "Acc ROI",        12, "decimal_2",   "decimal_2",   "delta_pct_1dp", FALSE, "#1A9018", "#D64550", "#E1C233", "#212121" }
    }
)
```

### 字段说明
| 字段 | 说明 |
|------|------|
| `Metric_ID` | 主键，1~N 整数 |
| `Metric_Name` | 矩阵列标题显示名称 |
| `Metric_Sort` | 排序值，控制列顺序 |
| `Metric_Format_Current` | 本期行的数值格式类型 |
| `Metric_Format_LP` | 同期（Last Period）行的数值格式类型 |
| `Metric_Format_VsLP` | vs LP 对比行的数值格式类型，通常为 `delta_pct_1dp` |
| `Metric_IsCurrencyAmount` | TRUE = 金额类，切换币种时乘以汇率；FALSE = 比率/计数类，不受汇率影响 |
| `Metric_ColorPositive` | vs LP 正值颜色（通常为绿色 `#1A9018`）|
| `Metric_ColorNegative` | vs LP 负值颜色（通常为红色 `#D64550`）|
| `Metric_ColorZero` | vs LP 零值颜色（通常为黄色 `#E1C233`）|
| `Metric_ColorDefault` | 本期/同期行统一颜色（通常为黑色 `#212121`）|

### 条件颜色规则
- **vs LP 行**：根据数值正负零启用条件颜色（`Metric_ColorPositive` / `Metric_ColorNegative` / `Metric_ColorZero`）
- **本期行 / 同期行**：统一使用 `Metric_ColorDefault`，不受条件颜色影响

---

## 4. 格式类型（Format Type）完整清单

度量值通过 `SELECTEDVALUE(DIM[Metric_Format_Current])` 读取格式类型字符串，再用 `SWITCH` 分支处理展示逻辑。

### 基础数值
| 格式类型 | 示例输出 | 说明 |
|----------|---------|------|
| `integer` | 1,000 | 整数千分位 |
| `integer_k` | 1,000k | 整数千分位带 k |
| `decimal_2` | 1,000.00 | 两位小数千分位 |
| `decimal_2k` | 1,000.00k | 两位小数千分位带 k |

### 百分比
| 格式类型 | 示例输出 | 说明 |
|----------|---------|------|
| `percent` | 40% | 百分比整数 |
| `percent_1dp` | 40.5% | 百分比 1 位小数 |
| `percent_2dp` | 40.52% | 百分比 2 位小数 |

### 货币
| 格式类型 | 示例输出 | 说明 |
|----------|---------|------|
| `currency` | $2,500 | 货币千分位整数 |
| `currency_dp` | $2,500.0 | 货币 1 位小数千分位 |
| `currency_2dp` | $2,500.00 | 货币 2 位小数千分位 |
| `currency_k` | $2,500k | 货币千分位整数带 k |
| `currency_dp_k` | $2,500.0k | 货币 1 位小数千分位带 k |
| `currency_2dp_k` | $2,500.00k | 货币 2 位小数千分位带 k |

### 增减百分比（带正负号）
| 格式类型 | 示例输出 | 说明 |
|----------|---------|------|
| `delta_pct` | +14% | 增减百分比整数 |
| `delta_pct_1dp` | +14.5% | 增减百分比 1 位小数 |
| `delta_pct_2dp` | +14.52% | 增减百分比 2 位小数 |

### 增减点数
| 格式类型 | 示例输出 | 说明 |
|----------|---------|------|
| `delta_pt` | +14pts | 增减点数整数 |
| `delta_pt_1dp` | +14.5pts | 增减点数 1 位小数 |
| `delta_pt_2dp` | +14.52pts | 增减点数 2 位小数 |

### 增减基点
| 格式类型 | 示例输出 | 说明 |
|----------|---------|------|
| `delta_bp` | +14bp | 增减基点整数 |
| `delta_bp_1dp` | +14.5bp | 增减基点 1 位小数 |

### 兼容旧格式
| 格式类型 | 等同于 | 示例输出 |
|----------|--------|---------|
| `number` | `integer_k` | 114k |

---

## 5. 度量值中读取参数表的标准模式

### SELECTEDVALUE 读取单选值
```dax
// 读取当前选中的平台 ID
__SelectedPlatform = SELECTEDVALUE(Slicer_Platform_Selection[Platform_ID])

// 读取当前选中的格式类型
__Format = SELECTEDVALUE(DIM_ColMetric_Overview[Metric_Format_Current], "currency")
```

### SWITCH 格式化分支模板
```dax
Formatted_Value = 
VAR __Value  = [Base Measure]
VAR __Format = SELECTEDVALUE(DIM_ColMetric_Overview[Metric_Format_Current], "currency")
RETURN
    SWITCH(
        __Format,
        "currency",      FORMAT(__Value, "$#,0"),
        "currency_dp",   FORMAT(__Value, "$#,0.0"),
        "currency_2dp",  FORMAT(__Value, "$#,0.00"),
        "integer",       FORMAT(__Value, "#,0"),
        "decimal_2",     FORMAT(__Value, "#,0.00"),
        "percent_1dp",   FORMAT(__Value, "0.0%"),
        "delta_pct_1dp", IF(__Value >= 0,
                             "+" & FORMAT(__Value, "0.0%"),
                             FORMAT(__Value, "0.0%")),
        FORMAT(__Value, "#,0")  // 默认回退
    )
```

### 条件颜色度量值模板
```dax
Color_VsLP = 
VAR __VsLP   = [Vs LP Measure]
VAR __Pos    = SELECTEDVALUE(DIM_ColMetric_Overview[Metric_ColorPositive],  "#1A9018")
VAR __Neg    = SELECTEDVALUE(DIM_ColMetric_Overview[Metric_ColorNegative],  "#D64550")
VAR __Zero   = SELECTEDVALUE(DIM_ColMetric_Overview[Metric_ColorZero],      "#E1C233")
VAR __Default = SELECTEDVALUE(DIM_ColMetric_Overview[Metric_ColorDefault],  "#212121")
RETURN
    // 仅 vs LP 行启用条件颜色，其余行用默认颜色
    IF(
        [Is_VsLP_Row],  // 判断当前行是否为 vs LP 行的标记度量值
        SWITCH(
            TRUE(),
            __VsLP > 0,  __Pos,
            __VsLP < 0,  __Neg,
            __Zero
        ),
        __Default
    )
```

---

## 6. 最佳实践

### 命名规范
- 参数表以 `Slicer_` 前缀命名（如 `Slicer_Platform_Selection`）
- 断开维度以 `DIM_` 前缀命名（如 `DIM_ColMetric_Overview`）
- 字段名使用 `{TableAlias}_{FieldName}` 格式，避免跨表混淆

### 结构设计
- 优先使用 `DATATABLE` 硬编码，避免引入外部 CSV/Excel 参数文件（减少数据源依赖）
- 每个参数表只服务于一个明确的业务维度，不要将不同类型的选项混入同一张表
- `_Sort` 字段始终使用整数，切片器排序设置为"按列排序" → 选择 `_Sort` 列

### 性能注意事项
- 参数表行数通常很小（< 100 行），不存在性能问题
- 断开维度不建立物理关系，避免误触发筛选上下文传播
- `SELECTEDVALUE` 在没有选中值时使用第二个参数作为默认值，防止空值导致度量值报错

### 切片器配置建议
- 单选场景：切片器设置为"单选"，确保 `SELECTEDVALUE` 始终返回非空值
- 多选场景：使用 `ISFILTERED` 或 `VALUES` 遍历所有选中值，配合 `CONTAINSROW` 判断
- 默认值处理：若需要"全部"选项，在 `_Label` 中加入"全部"行，`_ID` 设为空字符串或 `"ALL"`
