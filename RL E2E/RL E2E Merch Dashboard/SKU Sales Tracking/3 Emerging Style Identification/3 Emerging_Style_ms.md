# Emerging Style Identification 矩阵解决方案

> **版本**: v2.0（行列维度表化改造：矩阵行列表改为从维度表获取，占比分母限定维度表字段值，新增行列可见性与 SVG 热力度量）
> **模块**: RL E2E Merch Dashboard - SKU Sales Tracking Tab - Emerging Style Identification
> **关联口径**: 口径文档/口径Markdown格式/SKU Sales Tracking.md - 子模块五 Emerging Style Identification【Sales】（§11）+ 子模块六 Emerging Style Identification【Inventory】（§12）
> **数据底表（销售类）**: s02_trade_sku_data_d
> **数据底表（库存类）**: s02_inventory_stock_sales_detail_d
> **关联维度**: Slicer_Time_Frame_Min_This / Max_This（时间，断开维度）；Dim_Sales_color_name / Dim_Sales_sku_size / Dim_Inventory_color_name / Dim_Inventory_sku_size（矩阵行列维度表）
> **筛选影响范围**: date + Platform + Store Name + Division（其余商品维度切片器对图表的筛选在页面编辑交互中取消）

---

## 1. 需求理解

### 1.1 模块定位

Emerging Style Identification 是 SKU Sales Tracking Tab 的颜色 × 尺码结构子模块，以两个并排热力矩阵展示各 color 下 size 的销售 / 期末库存结构占比，用于识别新兴款式（color × size 组合）：

- **Sales 矩阵**：行 = color，列 = size，值 = SLS Amt%（该 color + size 占该 color 的销售金额比例），单元格以 SVG 热力图呈现
- **Inventory 矩阵**：行 = color，列 = size，值 = EOH Amt%（该 color + size 占该 color 的期末库存金额比例），单元格以 SVG 热力图呈现
- 两矩阵独立呈现、同时可见

### 1.2 矩阵结构与行列维度表

| 区域 | 字段  | Sales 矩阵来源                   | Inventory 矩阵来源                   |
| ---- | ----- | -------------------------------- | ------------------------------------ |
| 行   | Color | Dim_Sales_color_name[color_name] | Dim_Inventory_color_name[color_name] |
| 列   | Size  | Dim_Sales_sku_size[sku_size]     | Dim_Inventory_sku_size[sku_size]     |
| 值   | 占比  | SLS Amt% Value（SVG 热力呈现）   | EOH Amt% Value（SVG 热力呈现）       |

四张行列维度表（位于 维度复用\维度表\Emerging Style Identification，均取自对应事实表 distinct 值并**过滤空白**——`where 字段 is not null and 字段 <> '' and trim(字段) <> ''`）：

| 维度表                   | 取数来源                                       | 过滤                             |
| ------------------------ | ---------------------------------------------- | -------------------------------- |
| Dim_Sales_color_name     | s02_trade_sku_data_d[color_name]               | 非空白（NULL / 空字符 / 纯空格） |
| Dim_Sales_sku_size       | s02_trade_sku_data_d[sku_size]                 | 非空白                           |
| Dim_Inventory_color_name | s02_inventory_stock_sales_detail_d[color_name] | 非空白                           |
| Dim_Inventory_sku_size   | s02_inventory_stock_sales_detail_d[sku_size]   | 非空白                           |

**占比口径限定**：矩阵行列从维度表获取（行列值天然非空白，不出现 (Blank) 行 / 列）；占比分母**只包括维度表中的字段值**——事实表中空白 color_name / sku_size 记录的金额不进入分子分母，**矩阵整行（同一 color 的全部 size 列）占比相加 = 100%**。

### 1.3 指标清单

| 视图      | 指标     | 计算公式                                                                                                                       | 时间口径                     | 数据类型 / 格式          |
| --------- | -------- | ------------------------------------------------------------------------------------------------------------------------------ | ---------------------------- | ------------------------ |
| Sales     | SLS Amt% | 分子：该 color + sku_size 下`sum(net_sales_amt)`；分母：该 color 下 `sum(net_sales_amt)`（**仅维度表 size 值范围**） | This Period（区间）          | percent_0dp →`#,##0%` |
| Inventory | EOH Amt% | 分子：该 color + sku_size 下`sum(msrp_inv_amt)`；分母：该 color 下 `sum(msrp_inv_amt)`（**仅维度表 size 值范围**）   | This Period 最后一天（时点） | percent_0dp →`#,##0%` |

### 1.4 时间口径

| 口径                     | 时间范围                                                                                                                          | 适用指标          |
| ------------------------ | --------------------------------------------------------------------------------------------------------------------------------- | ----------------- |
| This Period（区间类）    | dt ∈ [Slicer_Time_Frame_Min_This[TimeFrame_Min], Slicer_Time_Frame_Max_This[TimeFrame_Max]]                                      | SLS Amt% 分子分母 |
| End Period（期末时点类） | end period 范围 [Slicer_Time_Frame_Max_This[TimeFrame_Min], Slicer_Time_Frame_Max_This[TimeFrame_Max]] 内**最后一个快照日** | EOH Amt% 分子分母 |

说明：

- 期末时点口径实现为「end period 范围内最后一个有数据的快照日」：口径定义为 this period 最后一天（TimeFrame_Max），快照缺数时自动回退到范围内最近一天，避免整段空值
- 快照表按日存储，期末时点**只取单日**，对 end period 整段区间求和会把库存重复计数

---

## 2. 现状分析

- 数据底表 `s02_trade_sku_data_d`（SKU 粒度交易表，dt 日粒度）：net_sales_amt 为 Power Query 取数时新增列（`ROUND(product_qty * sales_price, 6) AS net_sales_amt`），业务已确认；维度含 dt、platform、shop_name、division、color_name、sku_size 及其余商品维度
- 数据底表 `s02_inventory_stock_sales_detail_d`（库存+销售+补货 SKU 模型表，dt 日快照）：msrp_inv_amt（吊牌库存金额）为期末库存金额口径字段；维度含 dt、division、color_name、sku_size 等；**无 platform / shop_name 字段**（渠道筛选不影响库存侧指标，口径限制见注意事项 1）
- **行列维度表**：四张单列维度表（Dim_Sales_color_name / Dim_Sales_sku_size / Dim_Inventory_color_name / Dim_Inventory_sku_size），取对应事实表 distinct 值且已过滤空白——维度表值集合 = 事实表全部非空白值；矩阵行列绑定维度表字段，行列值与指标计算经 SELECTEDVALUE + 显式等值桥接传递到事实表（维度表与事实表间是否建立模型关系均可——建立一对多关系时筛选自动传递，不建立时由度量值内部显式桥接，两种建模下度量行为一致）
- 模型关系：日期筛选器（Slicer_Time_Frame_Min_This / Max_This）为断开维度，时间范围在 DAX 中显式筛选；Platform（Slicer_Platform_Selection）、Store Name（Slicer_Store_Name）、Division（Slicer_Division）与两张事实表一对多关联，筛选自动传递
- 本模块指标均为占比类，不涉及币种兑换
- 字段名已逐一核对数据字典（两表日期字段统一为 dt，date 类型）

---

## 3. 方案设计

### 3.1 度量值分层

```
Value（口径计算，保留小数原值）
←  行列值经 SELECTEDVALUE 从维度表读取，显式等值桥接到事实表
←  分母 TREATAS(ALLSELECTED(列维度表)) 限定维度表 size 值范围（整行占比加总 = 100%）
↓
Display（格式化显示）
←  percent_0dp: FORMAT(#,##0%)；BLANK 显示 "-"
↓
Is_Matrix_Row / Is_Matrix_Col（行列可见性）
←  MAXX 遍历 ALLSELECTED(对侧维度表)，严格复刻单元格 Value 判定行/列是否有真实数据
↓
SVG（热力图单元格）
←  背景/字体四点三段插值；双 ISINSCOPE 限定明细单元格；
←  空值单元格按行列可见性决定灰色占位 SVG 或 BLANK（配合矩阵空值抑制隐藏全空行列）
```

### 3.2 维度表桥接与占比口径

矩阵单元格的行列值从维度表读取，指标计算显式桥接到事实表：

- **行列值读取**：`SELECTEDVALUE(Dim_xxx[color_name])` / `SELECTEDVALUE(Dim_xxx[sku_size])` 在矩阵单元格上下文中取得当前行 / 列值（维度表值非空白）
- **分子桥接**：`CALCULATE(SUM(事实表[金额]), 事实表[color_name] = 当前行值, 事实表[sku_size] = 当前列值, 时间筛选)`——显式等值筛选，事实表空白记录天然不匹配
- **分母桥接**：`事实表[color_name] = 当前行值` 保留行维度；`TREATAS(ALLSELECTED(Dim_xxx[sku_size]), 事实表[sku_size])` 将维度表全部 size 值（ALLSELECTED 移除矩阵列头筛选、保留外部切片器筛选；页面无 size 切片器时 = 全部维度表值）映射为事实表 size 筛选——**分母限定在维度表 size 值范围内**（空白 sku_size 金额不进入分母）
- **整行加总 = 100%**：矩阵列 = 维度表 size 值（非空白），各列分子之和 = 该 color 非空白 size 金额之和 = 分母，同一 color 行的全部 size 列占比相加恰为 100%

### 3.3 行列可见性与 SVG 空值抑制

热力矩阵需要隐藏全空行列、保留有效行列交叉处的空占位（灰色 "-"）：

- **Is_Matrix_Row / Is_Matrix_Col**：严格按度量值结果判断——当前行（列）是否至少有一个列（行）存在非空 Value；MAXX 遍历 `ALLSELECTED(对侧维度表)`，逐候选复刻单元格 Value 计算（CALCULATE 上下文转换使 Value 内部 SELECTEDVALUE 读到候选值）
- **SVG 空值抑制**：明细单元格（双 ISINSCOPE——行字段与列字段均处于分组层级）Value 为空时，仅当所在行、所在列均存在有效数据（两个可见性度量 = 1）才返回灰色 "-" 占位 SVG；行全空或列全空返回**真正的 BLANK()**（而非空白图片——图片会把全空行列撑出来），该行列上全部单元格 BLANK 后由矩阵空值抑制机制（关闭「显示无数据的项」）隐藏整行 / 整列
- **可见性度量的使用位置**：两个可见性度量均在 SVG 度量内部调用（不配置为视觉级筛选器——视觉对象筛选器按行字段确定粒度，列字段不参与该粒度判断，列方向无法用筛选器对称过滤；SVG 内调用实现行列双向抑制）

### 3.4 度量值命名与组织

- 命名规则：模块前缀 `Emerging Style` + 视图（Sales / Inventory）+ 指标名 / 用途 + 层次后缀（Value / Display / Is_Matrix_Row / Is_Matrix_Col / SVG）
- Display Folder：`Emerging Style Identification\Base Metrics`、`Emerging Style Identification\Formatting`、`Emerging Style Identification\Matrix Visibility`、`Emerging Style Identification\SVG`
- 度量值统一存放于 `_Measures` 隐藏表（与看板既有组织方式一致）

---

## 4. 度量值实现

### 4.1 Emerging Style Sales SLS Amt% Value（当期销售金额占比）

```dax
Emerging Style Sales SLS Amt% Value =
// ========================================
// 度量值: Emerging Style Sales SLS Amt% Value
// 中文名: 当期销售金额占比（color × size 结构）
// Display Folder: Emerging Style Identification\Base Metrics
// 用途: Sales 矩阵单元格（color 行 × size 列）的销售金额占比——
//       该 color + sku_size 占该 color 的比例（This Period 区间）
// 依赖: Slicer_Time_Frame_Min_This[TimeFrame_Min] / Slicer_Time_Frame_Max_This[TimeFrame_Max]
//       Dim_Sales_color_name[color_name] / Dim_Sales_sku_size[sku_size]
// 口径: 分子：该 color + sku_size 下 sum(net_sales_amt)；
//       分母：该 color 下 sum(net_sales_amt)，且 size 限定在维度表值范围内
//       （空白 sku_size 金额不进入分母，矩阵整行占比相加 = 100%）
// 数据底表: s02_trade_sku_data_d
// 桥接: 行列值经 SELECTEDVALUE 从维度表读取，显式等值桥接事实表；
//       维度表与事实表是否建立模型关系均可（等值桥接对两种建模一致）
// 位置: 按明细单元格设计——行/列未展开的位置（小计/总计）SELECTEDVALUE 取
//       BLANK，等值桥接不匹配有效记录；小计/总计已关闭并由 SVG 层双
//       ISINSCOPE 排除，不依赖本度量在汇总位置的取值
// ========================================

// ── This Period 时间区间 ──
VAR __PeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Min_This[TimeFrame_Min])
VAR __PeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

// ── 当前行 / 列值（从维度表读取，非空白）──
VAR __CurrentColor = SELECTEDVALUE(Dim_Sales_color_name[color_name])
VAR __CurrentSize = SELECTEDVALUE(Dim_Sales_sku_size[sku_size])

// ── 分子：该 color + sku_size This Period 净销售金额（显式等值桥接）──
VAR __Numerator =
    CALCULATE(
        SUM('s02_trade_sku_data_d'[net_sales_amt]),
        's02_trade_sku_data_d'[color_name] = __CurrentColor,
        's02_trade_sku_data_d'[sku_size] = __CurrentSize,
        's02_trade_sku_data_d'[dt] >= __PeriodMin,
        's02_trade_sku_data_d'[dt] <= __PeriodMax
    )

// ── 分母：该 color 层级 This Period 净销售金额（size 限定维度表值范围）──
// ALLSELECTED 移除矩阵列头 size 筛选、保留外部切片器筛选（页面无 size 切片器
// 时 = 全部维度表值）；TREATAS 将维度表值集合映射为事实表 sku_size 筛选——
// 事实表空白 sku_size 记录不进入分母，整行占比加总 = 100%
VAR __Denominator =
    CALCULATE(
        SUM('s02_trade_sku_data_d'[net_sales_amt]),
        's02_trade_sku_data_d'[color_name] = __CurrentColor,
        TREATAS(
            ALLSELECTED(Dim_Sales_sku_size[sku_size]),
            's02_trade_sku_data_d'[sku_size]
        ),
        's02_trade_sku_data_d'[dt] >= __PeriodMin,
        's02_trade_sku_data_d'[dt] <= __PeriodMax
    )

RETURN
    DIVIDE(__Numerator, __Denominator)
```

### 4.2 Emerging Style Sales SLS Amt% Display（当期销售金额占比显示）

```dax
Emerging Style Sales SLS Amt% Display =
// ========================================
// 度量值: Emerging Style Sales SLS Amt% Display
// 中文名: 当期销售金额占比显示
// Display Folder: Emerging Style Identification\Formatting
// 用途: percent_0dp 格式化（百分比整数，不含正号）；BLANK 显示 "-"
//       （热力图呈现走 SVG 度量；本度量为无图像场景的文本格式化备用输出）
// 依赖: [Emerging Style Sales SLS Amt% Value]
// 数据格式: #,##0%（如 26%）
// ========================================
    VAR __Value = [Emerging Style Sales SLS Amt% Value]
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            FORMAT(__Value, "#,##0%")
        )
```

### 4.3 Emerging Style Sales Is_Matrix_Row（Sales 行可见性）

```dax
Emerging Style Sales Is_Matrix_Row =
// ========================================
// 度量值: Emerging Style Sales Is_Matrix_Row
// 中文名: Sales 矩阵行可见性
// Display Folder: Emerging Style Identification\Matrix Visibility
// 用途: 严格按度量值结果判断，当前 color (行) 是否至少有一个 size (列) 有真实数据
// 返回值: 1 (该行有效), 0 (该行全空)
// 使用位置: SVG 度量内部调用（不配置为视觉级筛选器——视觉对象筛选器按行字段
//       确定粒度，列方向无法对称过滤；行列双向抑制均在 SVG 内实现）
// 机制: MAXX 遍历 ALLSELECTED(Dim_Sales_sku_size)——移除矩阵列头筛选、保留
//       外部切片器筛选；CALCULATE 上下文转换使 [Value] 内部 SELECTEDVALUE
//       读到候选 size 值，逐候选严格复刻单元格 Value 计算
// ========================================
VAR __CurrentColor = SELECTEDVALUE(Dim_Sales_color_name[color_name])

// 当前筛选上下文下全部可见的 size 列表（维度表值集合）
VAR __AllVisibleSizes = ALLSELECTED(Dim_Sales_sku_size[sku_size])

// 迭代检查：遍历该行的全部 size 候选，任一列 Value 非空即行有效
VAR __HasValidDataInRow =
    MAXX(
        __AllVisibleSizes,
        VAR __CurrentSize = Dim_Sales_sku_size[sku_size]

        // 严格复刻单元格计算逻辑（上下文转换使 Value 读到候选值）
        VAR __CellResult =
            CALCULATE(
                [Emerging Style Sales SLS Amt% Value],
                's02_trade_sku_data_d'[color_name] = __CurrentColor,
                's02_trade_sku_data_d'[sku_size] = __CurrentSize
            )
        RETURN
            IF(NOT ISBLANK(__CellResult), 1, 0)
    )

RETURN
    IF(__HasValidDataInRow = 1, 1, 0)
```

### 4.4 Emerging Style Sales Is_Matrix_Col（Sales 列可见性）

```dax
Emerging Style Sales Is_Matrix_Col =
// ========================================
// 度量值: Emerging Style Sales Is_Matrix_Col
// 中文名: Sales 矩阵列可见性
// Display Folder: Emerging Style Identification\Matrix Visibility
// 用途: 严格按度量值结果判断，当前 size (列) 是否至少有一个 color (行) 有真实数据
// 返回值: 1 (该列有效), 0 (该列全空)
// 使用位置: SVG 度量内部调用（列方向空值抑制的唯一实现途径）
// 机制: 同 Is_Matrix_Row——MAXX 遍历 ALLSELECTED(Dim_Sales_color_name)，
//       逐候选严格复刻单元格 Value 计算
// ========================================
VAR __CurrentSize = SELECTEDVALUE(Dim_Sales_sku_size[sku_size])

// 当前筛选上下文下全部可见的 color 列表（维度表值集合）
VAR __AllVisibleColors = ALLSELECTED(Dim_Sales_color_name[color_name])

// 迭代检查：遍历该列的全部 color 候选，任一行 Value 非空即列有效
VAR __HasValidDataInCol =
    MAXX(
        __AllVisibleColors,
        VAR __CurrentColor = Dim_Sales_color_name[color_name]

        // 严格复刻单元格计算逻辑（上下文转换使 Value 读到候选值）
        VAR __CellResult =
            CALCULATE(
                [Emerging Style Sales SLS Amt% Value],
                's02_trade_sku_data_d'[color_name] = __CurrentColor,
                's02_trade_sku_data_d'[sku_size] = __CurrentSize
            )
        RETURN
            IF(NOT ISBLANK(__CellResult), 1, 0)
    )

RETURN
    IF(__HasValidDataInCol = 1, 1, 0)
```

### 4.5 Emerging Style Sales SLS Amt% SVG（Sales 热力图单元格）

```dax
Emerging Style Sales SLS Amt% SVG =
// ========================================
// 度量值: Emerging Style Sales SLS Amt% SVG
// 中文名: Sales 热力矩阵图单元格
// Display Folder: Emerging Style Identification\SVG
// 用途: 热力矩阵图单元格，背景/字体颜色按值四点三段插值自适应
// 背景插值: 0%→#d8dee5, 30%→#95afcf, 50%→#0c2340, 100%→#000000
// 字体插值: 0%→#737373, 30%→#333333, 35%→#ffffff, 100%→#ffffff（白色提前到35%）
// 基础度量: [Emerging Style Sales SLS Amt% Value]
// 空值抑制: 明细单元格 Value 为空时，行/列均存在有效数据才返回灰色 "-"
//       占位 SVG；行全空或列全空返回 BLANK()（配合矩阵关闭「显示无数据
//       的项」隐藏全空行列），有值直接返回 SVG
// ========================================

// ── 1. 读取基础值 ──
VAR _RawValue = [Emerging Style Sales SLS Amt% Value]
VAR _IsBlank = ISBLANK(_RawValue)
VAR _Value = MIN(MAX(_RawValue, 0), 1)
VAR _Pct = FORMAT(_Value, "#,##0%;#,##0%;0%")

// ── 2. 背景颜色三段插值（0%→30%→50%→100%）──
// 0%: #d8dee5 = rgb(216,222,229)
// 30%: #95afcf = rgb(149,175,207)
// 50%: #0c2340 = rgb(12,35,64)
// 100%: #000000 = rgb(0,0,0)
VAR _BR0 = 216
VAR _BG0 = 222
VAR _BB0 = 229
VAR _BR30 = 149
VAR _BG30 = 175
VAR _BB30 = 207
VAR _BR50 = 12
VAR _BG50 = 35
VAR _BB50 = 64
VAR _BR100 = 0
VAR _BG100 = 0
VAR _BB100 = 0

VAR _BR = IF(
    _Value <= 0.3,
    _BR0 + (_BR30 - _BR0) * (_Value / 0.3),
    IF(
        _Value <= 0.5,
        _BR30 + (_BR50 - _BR30) * ((_Value - 0.3) / 0.2),
        _BR50 + (_BR100 - _BR50) * ((_Value - 0.5) / 0.5)
    )
)
VAR _BG = IF(
    _Value <= 0.3,
    _BG0 + (_BG30 - _BG0) * (_Value / 0.3),
    IF(
        _Value <= 0.5,
        _BG30 + (_BG50 - _BG30) * ((_Value - 0.3) / 0.2),
        _BG50 + (_BG100 - _BG50) * ((_Value - 0.5) / 0.5)
    )
)
VAR _BB = IF(
    _Value <= 0.3,
    _BB0 + (_BB30 - _BB0) * (_Value / 0.3),
    IF(
        _Value <= 0.5,
        _BB30 + (_BB50 - _BB30) * ((_Value - 0.3) / 0.2),
        _BB50 + (_BB100 - _BB50) * ((_Value - 0.5) / 0.5)
    )
)
VAR _BgColor = "rgb(" & INT(_BR) & "," & INT(_BG) & "," & INT(_BB) & ")"

// ── 3. 字体颜色三段插值（0%→30%→35%→100%，白色提前到35%）──
// 0%: #737373 = rgb(115,115,115)
// 30%: #333333 = rgb(51,51,51)
// 35%: #ffffff = rgb(255,255,255)  ← 白色节点从50%提前到35%
// 100%: #ffffff = rgb(255,255,255)
VAR _FR0 = 115
VAR _FG0 = 115
VAR _FB0 = 115
VAR _FR30 = 51
VAR _FG30 = 51
VAR _FB30 = 51
VAR _FR35 = 255
VAR _FG35 = 255
VAR _FB35 = 255
VAR _FR100 = 255
VAR _FG100 = 255
VAR _FB100 = 255

VAR _FR = IF(
    _Value <= 0.3,
    _FR0 + (_FR30 - _FR0) * (_Value / 0.3),
    IF(
        _Value <= 0.35,
        _FR30 + (_FR35 - _FR30) * ((_Value - 0.3) / 0.05),
        _FR35 + (_FR100 - _FR35) * ((_Value - 0.35) / 0.65)
    )
)
VAR _FG = IF(
    _Value <= 0.3,
    _FG0 + (_FG30 - _FG0) * (_Value / 0.3),
    IF(
        _Value <= 0.35,
        _FG30 + (_FG35 - _FG30) * ((_Value - 0.3) / 0.05),
        _FG35 + (_FG100 - _FG35) * ((_Value - 0.35) / 0.65)
    )
)
VAR _FB = IF(
    _Value <= 0.3,
    _FB0 + (_FB30 - _FB0) * (_Value / 0.3),
    IF(
        _Value <= 0.35,
        _FB30 + (_FB35 - _FB30) * ((_Value - 0.3) / 0.05),
        _FB35 + (_FB100 - _FB35) * ((_Value - 0.35) / 0.65)
    )
)
VAR _FontColor = "rgb(" & INT(_FR) & "," & INT(_FG) & "," & INT(_FB) & ")"

// ── 4. BLANK 处理：置灰显示 "-" ──
VAR _FinalBg = IF(_IsBlank, "rgb(215,222,228)", _BgColor)
VAR _FinalFont = IF(_IsBlank, "rgb(179,179,179)", _FontColor)
VAR _FinalText = IF(_IsBlank, "-", _Pct)

// ── 5. SVG 输出（圆角 4px，88x33 单元格）──
VAR _URL =
"data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' width='88' height='33' viewBox='0 0 88 33' preserveAspectRatio='none'>
<rect rx='4' ry='4' x='0' y='0' width='88' height='33' fill='" & _FinalBg & "' stroke='none'/>
<text x='44' y='16.5' text-anchor='middle' dominant-baseline='central' font-size='12' font-family='Segoe UI' font-weight='normal' font-style='normal' fill='" & _FinalFont & "'>" & _FinalText & "</text>
</svg>"

// ── 6. 行列可见性：隐藏全空行列，保留内部空白占位 ──
// 双 ISINSCOPE 仅区分明细单元格与总计位置（不检测空值）；
// 空值单元格按行列可见性决定占位 SVG 或 BLANK
VAR __IsDetailCell =
    ISINSCOPE(Dim_Sales_color_name[color_name])
        && ISINSCOPE(Dim_Sales_sku_size[sku_size])

RETURN
    IF(
        NOT __IsDetailCell,
        // 总计位置不绘制 SVG
        BLANK(),
        IF(
            _IsBlank,
            // 当前单元格为空：行、列均存在有效数据时保留灰色 "-" 占位；
            // 行全空或列全空返回真正的 BLANK()，由矩阵空值抑制隐藏整行/整列
            IF(
                [Emerging Style Sales Is_Matrix_Row] = 1
                    && [Emerging Style Sales Is_Matrix_Col] = 1,
                _URL,
                BLANK()
            ),
            // 当前单元格有值，所在行、列必然有效，直接绘制百分比 SVG
            _URL
        )
    )
```

### 4.6 Emerging Style Inventory EOH Amt% Value（当期期末库存金额占比）

```dax
Emerging Style Inventory EOH Amt% Value =
// ========================================
// 度量值: Emerging Style Inventory EOH Amt% Value
// 中文名: 当期期末库存金额占比（color × size 结构，时点数）
// Display Folder: Emerging Style Identification\Base Metrics
// 用途: Inventory 矩阵单元格（color 行 × size 列）的期末库存金额占比——
//       该 color + sku_size 占该 color 的比例（This Period 最后一天）
// 依赖: Slicer_Time_Frame_Max_This[TimeFrame_Min] / [TimeFrame_Max]
//       Dim_Inventory_color_name[color_name] / Dim_Inventory_sku_size[sku_size]
// 口径: 分子：该 color + sku_size 下 sum(msrp_inv_amt)；分母：该 color 下
//       sum(msrp_inv_amt)，且 size 限定在维度表值范围内（空白 sku_size
//       金额不进入分母，矩阵整行占比相加 = 100%）；时间范围看 this period
//       最后一天（实现为 end period 范围内最后一个快照日）
// 数据底表: s02_inventory_stock_sales_detail_d
// 桥接: 行列值经 SELECTEDVALUE 从维度表读取，显式等值桥接事实表
// 位置: 按明细单元格设计（同 Sales Value，小计/总计关闭且由 SVG 层排除）
// ========================================

// ── End Period 时间范围（期末时点类）──
VAR __EndPeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Min])
VAR __EndPeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

// ── 期末快照日：end period 范围内最后一个有数据的日期（单日时点）──
// REMOVEFILTERS 保证快照日不随切片器 / 矩阵行列上下文漂移
VAR __EndPeriodDate =
    CALCULATE(
        MAX('s02_inventory_stock_sales_detail_d'[dt]),
        REMOVEFILTERS('s02_inventory_stock_sales_detail_d'),
        's02_inventory_stock_sales_detail_d'[dt] >= __EndPeriodMin,
        's02_inventory_stock_sales_detail_d'[dt] <= __EndPeriodMax
    )

// ── 当前行 / 列值（从维度表读取，非空白）──
VAR __CurrentColor = SELECTEDVALUE(Dim_Inventory_color_name[color_name])
VAR __CurrentSize = SELECTEDVALUE(Dim_Inventory_sku_size[sku_size])

// ── 分子：该 color + sku_size 期末库存金额（快照日单日值，显式等值桥接）──
VAR __Numerator =
    CALCULATE(
        SUM('s02_inventory_stock_sales_detail_d'[msrp_inv_amt]),
        's02_inventory_stock_sales_detail_d'[color_name] = __CurrentColor,
        's02_inventory_stock_sales_detail_d'[sku_size] = __CurrentSize,
        's02_inventory_stock_sales_detail_d'[dt] = __EndPeriodDate
    )

// ── 分母：该 color 层级期末库存金额（size 限定维度表值范围，快照日单日值）──
// TREATAS(ALLSELECTED(Dim_Inventory_sku_size)) 限定分母 size 范围为维度表值，
// 空白 sku_size 金额不进入分母，整行占比加总 = 100%
VAR __Denominator =
    CALCULATE(
        SUM('s02_inventory_stock_sales_detail_d'[msrp_inv_amt]),
        's02_inventory_stock_sales_detail_d'[color_name] = __CurrentColor,
        TREATAS(
            ALLSELECTED(Dim_Inventory_sku_size[sku_size]),
            's02_inventory_stock_sales_detail_d'[sku_size]
        ),
        's02_inventory_stock_sales_detail_d'[dt] = __EndPeriodDate
    )

RETURN
    DIVIDE(__Numerator, __Denominator)
```

### 4.7 Emerging Style Inventory EOH Amt% Display（当期期末库存金额占比显示）

```dax
Emerging Style Inventory EOH Amt% Display =
// ========================================
// 度量值: Emerging Style Inventory EOH Amt% Display
// 中文名: 当期期末库存金额占比显示
// Display Folder: Emerging Style Identification\Formatting
// 用途: percent_0dp 格式化（百分比整数，不含正号）；BLANK 显示 "-"
//       （热力图呈现走 SVG 度量；本度量为无图像场景的文本格式化备用输出）
// 依赖: [Emerging Style Inventory EOH Amt% Value]
// 数据格式: #,##0%（如 26%）
// ========================================
    VAR __Value = [Emerging Style Inventory EOH Amt% Value]
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            FORMAT(__Value, "#,##0%")
        )
```

### 4.8 Emerging Style Inventory Is_Matrix_Row（Inventory 行可见性）

```dax
Emerging Style Inventory Is_Matrix_Row =
// ========================================
// 度量值: Emerging Style Inventory Is_Matrix_Row
// 中文名: Inventory 矩阵行可见性
// Display Folder: Emerging Style Identification\Matrix Visibility
// 用途: 严格按度量值结果判断，当前 color (行) 是否至少有一个 size (列) 有真实数据
// 返回值: 1 (该行有效), 0 (该行全空)
// 使用位置: SVG 度量内部调用（不配置为视觉级筛选器，行列双向抑制均在 SVG 内实现）
// 机制: 同 Sales 侧——MAXX 遍历 ALLSELECTED(Dim_Inventory_sku_size)，
//       CALCULATE 上下文转换使 [Value] 内部 SELECTEDVALUE 读到候选值
// ========================================
VAR __CurrentColor = SELECTEDVALUE(Dim_Inventory_color_name[color_name])

// 当前筛选上下文下全部可见的 size 列表（维度表值集合）
VAR __AllVisibleSizes = ALLSELECTED(Dim_Inventory_sku_size[sku_size])

// 迭代检查：遍历该行的全部 size 候选，任一列 Value 非空即行有效
VAR __HasValidDataInRow =
    MAXX(
        __AllVisibleSizes,
        VAR __CurrentSize = Dim_Inventory_sku_size[sku_size]

        VAR __CellResult =
            CALCULATE(
                [Emerging Style Inventory EOH Amt% Value],
                's02_inventory_stock_sales_detail_d'[color_name] = __CurrentColor,
                's02_inventory_stock_sales_detail_d'[sku_size] = __CurrentSize
            )
        RETURN
            IF(NOT ISBLANK(__CellResult), 1, 0)
    )

RETURN
    IF(__HasValidDataInRow = 1, 1, 0)
```

### 4.9 Emerging Style Inventory Is_Matrix_Col（Inventory 列可见性）

```dax
Emerging Style Inventory Is_Matrix_Col =
// ========================================
// 度量值: Emerging Style Inventory Is_Matrix_Col
// 中文名: Inventory 矩阵列可见性
// Display Folder: Emerging Style Identification\Matrix Visibility
// 用途: 严格按度量值结果判断，当前 size (列) 是否至少有一个 color (行) 有真实数据
// 返回值: 1 (该列有效), 0 (该列全空)
// 使用位置: SVG 度量内部调用（列方向空值抑制的唯一实现途径）
// 机制: 同 Sales 侧——MAXX 遍历 ALLSELECTED(Dim_Inventory_color_name)
// ========================================
VAR __CurrentSize = SELECTEDVALUE(Dim_Inventory_sku_size[sku_size])

// 当前筛选上下文下全部可见的 color 列表（维度表值集合）
VAR __AllVisibleColors = ALLSELECTED(Dim_Inventory_color_name[color_name])

// 迭代检查：遍历该列的全部 color 候选，任一行 Value 非空即列有效
VAR __HasValidDataInCol =
    MAXX(
        __AllVisibleColors,
        VAR __CurrentColor = Dim_Inventory_color_name[color_name]

        VAR __CellResult =
            CALCULATE(
                [Emerging Style Inventory EOH Amt% Value],
                's02_inventory_stock_sales_detail_d'[color_name] = __CurrentColor,
                's02_inventory_stock_sales_detail_d'[sku_size] = __CurrentSize
            )
        RETURN
            IF(NOT ISBLANK(__CellResult), 1, 0)
    )

RETURN
    IF(__HasValidDataInCol = 1, 1, 0)
```

### 4.10 Emerging Style Inventory EOH Amt% SVG（Inventory 热力图单元格）

```dax
Emerging Style Inventory EOH Amt% SVG =
// ========================================
// 度量值: Emerging Style Inventory EOH Amt% SVG
// 中文名: Inventory 热力矩阵图单元格
// Display Folder: Emerging Style Identification\SVG
// 用途: 热力矩阵图单元格，背景/字体颜色按值四点三段插值自适应
// 背景插值: 0%→#d8dee5, 30%→#95afcf, 50%→#0c2340, 100%→#000000
// 字体插值: 0%→#737373, 30%→#333333, 35%→#ffffff, 100%→#ffffff（白色提前到35%）
// 基础度量: [Emerging Style Inventory EOH Amt% Value]
// 空值抑制: 明细单元格 Value 为空时，行/列均存在有效数据才返回灰色 "-"
//       占位 SVG；行全空或列全空返回 BLANK()（配合矩阵关闭「显示无数据
//       的项」隐藏全空行列），有值直接返回 SVG
// ========================================

// ── 1. 读取基础值 ──
VAR _RawValue = [Emerging Style Inventory EOH Amt% Value]
VAR _IsBlank = ISBLANK(_RawValue)
VAR _Value = MIN(MAX(_RawValue, 0), 1)
VAR _Pct = FORMAT(_Value, "#,##0%;#,##0%;0%")

// ── 2. 背景颜色三段插值（0%→30%→50%→100%）──
VAR _BR0 = 216
VAR _BG0 = 222
VAR _BB0 = 229
VAR _BR30 = 149
VAR _BG30 = 175
VAR _BB30 = 207
VAR _BR50 = 12
VAR _BG50 = 35
VAR _BB50 = 64
VAR _BR100 = 0
VAR _BG100 = 0
VAR _BB100 = 0

VAR _BR = IF(
    _Value <= 0.3,
    _BR0 + (_BR30 - _BR0) * (_Value / 0.3),
    IF(
        _Value <= 0.5,
        _BR30 + (_BR50 - _BR30) * ((_Value - 0.3) / 0.2),
        _BR50 + (_BR100 - _BR50) * ((_Value - 0.5) / 0.5)
    )
)
VAR _BG = IF(
    _Value <= 0.3,
    _BG0 + (_BG30 - _BG0) * (_Value / 0.3),
    IF(
        _Value <= 0.5,
        _BG30 + (_BG50 - _BG30) * ((_Value - 0.3) / 0.2),
        _BG50 + (_BG100 - _BG50) * ((_Value - 0.5) / 0.5)
    )
)
VAR _BB = IF(
    _Value <= 0.3,
    _BB0 + (_BB30 - _BB0) * (_Value / 0.3),
    IF(
        _Value <= 0.5,
        _BB30 + (_BB50 - _BB30) * ((_Value - 0.3) / 0.2),
        _BB50 + (_BB100 - _BB50) * ((_Value - 0.5) / 0.5)
    )
)
VAR _BgColor = "rgb(" & INT(_BR) & "," & INT(_BG) & "," & INT(_BB) & ")"

// ── 3. 字体颜色三段插值（0%→30%→35%→100%，白色提前到35%）──
VAR _FR0 = 115
VAR _FG0 = 115
VAR _FB0 = 115
VAR _FR30 = 51
VAR _FG30 = 51
VAR _FB30 = 51
VAR _FR35 = 255
VAR _FG35 = 255
VAR _FB35 = 255
VAR _FR100 = 255
VAR _FG100 = 255
VAR _FB100 = 255

VAR _FR = IF(
    _Value <= 0.3,
    _FR0 + (_FR30 - _FR0) * (_Value / 0.3),
    IF(
        _Value <= 0.35,
        _FR30 + (_FR35 - _FR30) * ((_Value - 0.3) / 0.05),
        _FR35 + (_FR100 - _FR35) * ((_Value - 0.35) / 0.65)
    )
)
VAR _FG = IF(
    _Value <= 0.3,
    _FG0 + (_FG30 - _FG0) * (_Value / 0.3),
    IF(
        _Value <= 0.35,
        _FG30 + (_FG35 - _FG30) * ((_Value - 0.3) / 0.05),
        _FG35 + (_FG100 - _FG35) * ((_Value - 0.35) / 0.65)
    )
)
VAR _FB = IF(
    _Value <= 0.3,
    _FB0 + (_FB30 - _FB0) * (_Value / 0.3),
    IF(
        _Value <= 0.35,
        _FB30 + (_FB35 - _FB30) * ((_Value - 0.3) / 0.05),
        _FB35 + (_FB100 - _FB35) * ((_Value - 0.35) / 0.65)
    )
)
VAR _FontColor = "rgb(" & INT(_FR) & "," & INT(_FG) & "," & INT(_FB) & ")"

// ── 4. BLANK 处理：置灰显示 "-" ──
VAR _FinalBg = IF(_IsBlank, "rgb(215,222,228)", _BgColor)
VAR _FinalFont = IF(_IsBlank, "rgb(179,179,179)", _FontColor)
VAR _FinalText = IF(_IsBlank, "-", _Pct)

// ── 5. SVG 输出（圆角 4px，88x33 单元格）──
VAR _URL =
"data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' width='88' height='33' viewBox='0 0 88 33' preserveAspectRatio='none'>
<rect rx='4' ry='4' x='0' y='0' width='88' height='33' fill='" & _FinalBg & "' stroke='none'/>
<text x='44' y='16.5' text-anchor='middle' dominant-baseline='central' font-size='12' font-family='Segoe UI' font-weight='normal' font-style='normal' fill='" & _FinalFont & "'>" & _FinalText & "</text>
</svg>"

// ── 6. 行列可见性：隐藏全空行列，保留内部空白占位 ──
VAR __IsDetailCell =
    ISINSCOPE(Dim_Inventory_color_name[color_name])
        && ISINSCOPE(Dim_Inventory_sku_size[sku_size])

RETURN
    IF(
        NOT __IsDetailCell,
        // 总计位置不绘制 SVG
        BLANK(),
        IF(
            _IsBlank,
            // 当前单元格为空：行、列均存在有效数据时保留灰色 "-" 占位；
            // 行全空或列全空返回真正的 BLANK()，由矩阵空值抑制隐藏整行/整列
            IF(
                [Emerging Style Inventory Is_Matrix_Row] = 1
                    && [Emerging Style Inventory Is_Matrix_Col] = 1,
                _URL,
                BLANK()
            ),
            // 当前单元格有值，所在行、列必然有效，直接绘制百分比 SVG
            _URL
        )
    )
```

---

## 5. 度量值清单与 Display Folder

| 序号 | 度量值名称                                | Display Folder    | 类型             | 用途                                                           |
| ---- | ----------------------------------------- | ----------------- | ---------------- | -------------------------------------------------------------- |
| 1    | Emerging Style Sales SLS Amt% Value       | Base Metrics      | percent_0dp      | Sales 矩阵值（该 color + size 占该 color，分母限维度表值）     |
| 2    | Emerging Style Sales SLS Amt% Display     | Formatting        | 文本             | SLS Amt% 格式化显示（备用输出）                                |
| 3    | Emerging Style Sales Is_Matrix_Row        | Matrix Visibility | 0 / 1            | Sales 行可见性（SVG 内调用）                                   |
| 4    | Emerging Style Sales Is_Matrix_Col        | Matrix Visibility | 0 / 1            | Sales 列可见性（SVG 内调用）                                   |
| 5    | Emerging Style Sales SLS Amt% SVG         | SVG               | 文本（data URI） | Sales 热力图单元格（含空值抑制）                               |
| 6    | Emerging Style Inventory EOH Amt% Value   | Base Metrics      | percent_0dp      | Inventory 矩阵值（该 color + size 占该 color，分母限维度表值） |
| 7    | Emerging Style Inventory EOH Amt% Display | Formatting        | 文本             | EOH Amt% 格式化显示（备用输出）                                |
| 8    | Emerging Style Inventory Is_Matrix_Row    | Matrix Visibility | 0 / 1            | Inventory 行可见性（SVG 内调用）                               |
| 9    | Emerging Style Inventory Is_Matrix_Col    | Matrix Visibility | 0 / 1            | Inventory 列可见性（SVG 内调用）                               |
| 10   | Emerging Style Inventory EOH Amt% SVG     | SVG               | 文本（data URI） | Inventory 热力图单元格（含空值抑制）                           |

---

## 6. 血缘关系图

```
┌─────────────────────────────────────────────────────────────────────┐
│                        数据源层                                      │
│  s02_trade_sku_data_d（销售类，dt 日粒度）                            │
│  字段: dt, platform, shop_name, division, color_name, sku_size,      │
│        net_sales_amt（Power Query 取数新增列）                        │
│  s02_inventory_stock_sales_detail_d（库存类，dt 日快照）              │
│  字段: dt, division, color_name, sku_size, msrp_inv_amt              │
│        （无 platform / shop_name）                                    │
└──────────────────────────────────┬──────────────────────────────────┘
│ Platform / Store Name / Division 一对多关联自动传递（无需 DAX）
▼
┌─────────────────────────────────────────────────────────────────────┐
│                     行列维度表（distinct + 非空白过滤）               │
│  Dim_Sales_color_name / Dim_Sales_sku_size                           │
│  Dim_Inventory_color_name / Dim_Inventory_sku_size                   │
│  矩阵行列绑定维度表字段；Value 内 SELECTEDVALUE 读行列值 +           │
│  显式等值桥接事实表；分母 TREATAS(ALLSELECTED(列维度表)) 限定          │
│  维度表值范围（整行占比加总 = 100%）                                  │
└──────────────────────────────────┬──────────────────────────────────┘
                                   ▼
┌─────────────────────────────────────────────────────────────────────┐
│                        度量值层                                      │
│  SLS Amt% Value / EOH Amt% Value                                    │
│    （This Period 区间 / 期末快照日单日时点；分母限维度表 size 值）      │
│        ↓                                                             │
│  SLS Amt% Display / EOH Amt% Display（percent_0dp 备用输出）         │
│        ↓                                                             │
│  Is_Matrix_Row / Is_Matrix_Col（×2 视图）                            │
│    （MAXX 遍历 ALLSELECTED 对侧维度表，复刻单元格 Value 判定）         │
│        ↓                                                             │
│  SLS Amt% SVG / EOH Amt% SVG                                        │
│    （四点三段插值 + 双 ISINSCOPE 明细判定 + 空值行列抑制）             │
│        ▲ Slicer_Time_Frame_Min_This / Max_This（断开维度，            │
│          DAX 显式时间筛选）                                           │
└─────────────────────────────────────────────────────────────────────┘
                                   │
                                   ▼
┌─────────────────────────────────────────────────────────────────────┐
│                        可视化层（热力矩阵 × 2）                       │
│  Sales 矩阵:                                                         │
│    行: Dim_Sales_color_name[color_name]                              │
│    列: Dim_Sales_sku_size[sku_size]                                  │
│    值: SLS Amt% Value + 图像 URL 条件格式 → SLS Amt% SVG             │
│  Inventory 矩阵:                                                     │
│    行: Dim_Inventory_color_name[color_name]                          │
│    列: Dim_Inventory_sku_size[sku_size]                              │
│    值: EOH Amt% Value + 图像 URL 条件格式 → EOH Amt% SVG             │
│  两矩阵: 关闭小计/总计与「显示无数据的项」（空值抑制前提）             │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 7. 矩阵视觉对象配置

### 7.1 Sales 矩阵

| 配置项   | 内容                                                                                                |
| -------- | --------------------------------------------------------------------------------------------------- |
| 行字段   | Dim_Sales_color_name[color_name]                                                                    |
| 列字段   | Dim_Sales_sku_size[sku_size]                                                                        |
| 值       | [Emerging Style Sales SLS Amt% Value]（列格式 #,##0%）                                              |
| 条件格式 | 值字段 → 条件格式 → 图像 URL → 绑定 [Emerging Style Sales SLS Amt% SVG]（单元格以热力 SVG 呈现） |
| 显示元素 | 关闭行小计 / 列总计 / 总计；**关闭「显示无数据的项」**（空值抑制前提，见注意事项 7）          |

### 7.2 Inventory 矩阵

| 配置项   | 内容                                                                                                    |
| -------- | ------------------------------------------------------------------------------------------------------- |
| 行字段   | Dim_Inventory_color_name[color_name]                                                                    |
| 列字段   | Dim_Inventory_sku_size[sku_size]                                                                        |
| 值       | [Emerging Style Inventory EOH Amt% Value]（列格式 #,##0%）                                              |
| 条件格式 | 值字段 → 条件格式 → 图像 URL → 绑定 [Emerging Style Inventory EOH Amt% SVG]（单元格以热力 SVG 呈现） |
| 显示元素 | 关闭行小计 / 列总计 / 总计；**关闭「显示无数据的项」**                                            |

### 7.3 呈现与空值抑制说明

- 单元格显示：值字段配置图像 URL 条件格式后，单元格以 SVG 图像呈现（SVG 内含百分比文本与插值背景色）；如需切换为纯数值呈现，移除图像 URL 条件格式即可（值字段列格式 #,##0% 生效），或改绑 Display 文本输出
- **空值抑制链路**：全空行 / 全空列上的每个单元格由 SVG 度量返回真正的 BLANK()（非空白图片）→ 矩阵关闭「显示无数据的项」后整行 / 整列隐藏；有效行列交叉处的空单元格保留灰色 "-" 占位 SVG
- 可见性度量不配置为视觉级筛选器：视觉对象筛选器按行字段确定粒度、列字段不参与该粒度判断，列方向无法用筛选器对称过滤——行、列双向抑制统一在 SVG 度量内部调用两个可见性度量实现

---

## 8. 注意事项

1. **inv 表无渠道字段**：s02_inventory_stock_sales_detail_d 无 platform / shop_name 字段，Inventory 矩阵（EOH Amt%）不受 Platform / Store Name 筛选影响，仅受 date + Division 影响；Sales 矩阵（SLS Amt%）受 date + Platform + Store Name + Division 四组筛选影响。该口径限制已与业务确认。
2. **期末时点只取单日**：EOH Amt% 分子分母取 end period 范围内最后一个快照日的单日值；快照表按日存储，对整段区间求和会把库存重复计数。快照缺数时在 end period 窗口内自动回退到最近一天（口径定义为 this period 最后一天）。
3. **快照日 REMOVEFILTERS 机制**：__EndPeriodDate 用 REMOVEFILTERS(整表) 计算，保证快照日不随 Division / color / size 矩阵行列上下文或切片器漂移，全表确定性取值。
4. **占比分母限定维度表值范围**：分母 size 范围 = ALLSELECTED(列维度表)（页面无 size 切片器时 = 全部维度表值，已过滤空白）→ 事实表空白 sku_size 记录金额不进入分母；**同一 color 行的全部 size 列占比相加 = 100%**。行桥接的 color 值同样来自维度表（非空白），事实表空白 color_name 记录不进入任何行。如未来页面增加 size 相关切片器，分母范围随外部筛选变化（ALLSELECTED 语义）。
5. **行列维度表与事实表关系可选**：维度表与事实表间是否建立一对多模型关系均可——显式等值桥接对两种建模行为一致（建立关系时筛选自动传递且与等值桥接等价叠加；不建立时由度量值内部桥接）。建议建立一对多关系以获得行列值自动分组与筛选传递。
6. **Value 度量的汇总位置行为**：Value 按明细单元格设计——行 / 列未展开的位置（小计 / 总计）SELECTEDVALUE 取 BLANK，等值桥接不匹配有效记录（`事实表[sku_size] = BLANK()` 会匹配空白记录，数值不可用）；小计 / 总计已关闭且 SVG 层双 ISINSCOPE 排除总计位置，不依赖 Value 在汇总位置的取值。
7. **空值抑制依赖矩阵设置**：必须关闭「显示无数据的项」（矩阵格式设置），且 SVG 度量在行 / 列全空时返回真正的 BLANK()——返回空白图片（含灰色 "-" 的 data URI）会把全空行列撑出来，无法隐藏。
8. **可见性度量的遍历成本**：Is_Matrix_Row / Is_Matrix_Col 逐候选复刻单元格 Value（MAXX 遍历对侧维度表全部值）；维度表值为 distinct 字段值（数量级为字段基数），仅由 SVG 在空值单元格触发调用，有值单元格与总计位置不触发，整体成本可控。
9. **SVG 插值色标与值域**：背景 0%→#d8dee5、30%→#95afcf、50%→#0c2340、100%→#000000；字体 0%→#737373、30%→#333333、35%→#ffffff、100%→#ffffff（白色提前到 35% 保证深底可读）；值域经 MIN(MAX(值, 0), 1) 截断到 0~100%（占比理论上限 100%）。SVG 画布 88x33、圆角 4px，preserveAspectRatio='none' 自动拉伸适应列宽。
10. **日期筛选器依赖**：SELECTEDVALUE(Slicer_Time_Frame_Min_This[TimeFrame_Min]) 等依赖日期切片器保持单选且必选；切片器未选或多选时时间边界为 BLANK，指标不可用（与看板既有日期筛选器使用方式一致）。
11. **DIVIDE 空值保护**：分母（该 color 层级、限维度表 size 值范围的金额）为空或 0 时 DIVIDE 返回 BLANK——SVG 呈现灰色 "-"（行列有效时）或 BLANK（行列全空时被抑制）；Display 呈现 "-"。
12. **行 / 列排序**：口径未定义矩阵行列排序规则，默认按维度表字段值顺序呈现（color_name / sku_size 字典序或数据源顺序）。如需业务尺码序（XXS → XS → S …、0 → 1 → 2 …）需为维度表增加排序列（`select distinct sku_size` 基础上追加排序列）并按该列排序。
13. **DAX 语法规范**：文本常量使用双引号，单引号仅用于表名，列名使用方括号；与口径文档存在争议时一切以口径文档为准。
