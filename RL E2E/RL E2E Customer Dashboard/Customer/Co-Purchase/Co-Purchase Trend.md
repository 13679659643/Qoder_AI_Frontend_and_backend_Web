# Co-Purchase Trend 解决方案

> **版本**: v2.0
> **模块**: Customer Dashboard - Customer Tab - Co-Purchase
> **关联口径**: 口径文档/Customer/Co-Purchase.md
> **数据底表**: `a03_e2e_customer_order_correlation_data_m`（连带率）、`a03_e2e_customer_time_ordered_data_m`（商品路径）
> **关联维度**: Slicer_Time_Frame、`Slicer_Co_Purchase_Type_Selection`（时间/周期/类型由模型关系自动传递，DAX 无需显式处理）
> **用途**: 用于条形图和表格，每个指标独立拉取，无 x 轴
> **行维度**: `co_brand` / `co_category_summary` / `brand` / `category_summary` 直接拉取事实表字段，表关系自动传递

---

## 1. 需求理解

### 1.1 模块定位

Co-Purchase Trend 是 Customer Tab 的连带购买与商品路径模块，共 **5 个指标**，每个指标独立输出 **Value 度量 + Display 度量**，共 10 个度量值。分为两个子模块：

- **子模块十：Co-Purchase Matrix**（连带率，2 个指标，对应 Class / Label 两张图表）
- **子模块十一：Product Path**（商品购买路径，3 个指标）

### 1.2 全局规则

| 项目                                          | 说明                                                                                                                                 |
| --------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------ |
| **无需 DAX 显式处理时间/周期/类型筛选** | `data_month`、`correlation_period`、`correlation_type`、`dt`、`period` 由模型关系或表字段自动传递，DAX 不显式处理          |
| **Class/Label 按钮决定图表**            | 指标 1 用于 Class 图表，指标 2 用于 Label 图表；度量内部通过`Slicer_Co_Purchase_Type_Selection` 切换 Same-Order / Cross-Order 公式 |
| **行维度直接拉取事实表字段**            | `co_brand` / `co_category_summary` / `brand` / `category_summary` 从事实表直接拉取，自动分组与筛选                           |
| **Cross-Order 分母移除图表维度**        | Class 图表分母用`ALLSELECTED(co_category_summary)`，Label 图表分母用 `ALLSELECTED(co_brand)`，保留外部切片器筛选                 |
| **货币转换**                            | 本模块均为百分比/整数指标，不涉及汇率换算                                                                                            |

### 1.3 5 个指标清单

| # | 指标名称                     | 子模块             | 适用图表   | 分组维度                | 类型        | 数据格式 |
| - | ---------------------------- | ------------------ | ---------- | ----------------------- | ----------- | -------- |
| 1 | Co-Purchase Cross-Sell-Class | Co-Purchase Matrix | Class 图表 | co_category_summary     | percent_0dp | #,##0%   |
| 2 | Co-Purchase Cross-Sell-Label | Co-Purchase Matrix | Label 图表 | co_brand                | percent_0dp | #,##0%   |
| 3 | Product Path 1st Class       | Product Path       | 通用       | brand, category_summary | integer     | #,##0    |
| 4 | Product Path 2st Class       | Product Path       | 通用       | brand, category_summary | integer     | #,##0    |
| 5 | Product Path 3st Class       | Product Path       | 通用       | brand, category_summary | integer     | #,##0    |

### 1.4 指标 1/2 分支口径（按 Slicer_Co_Purchase_Type_Selection 切换）

**Slicer_Co_Purchase_Type_Selection[CoPurchase_Type_Label]** 取值：`"Same-Order Cross-Sell"` / `"Cross-Order Cross-Sell"`

| 指标                           | 按钮上下文 | 切片器取值               | 输出公式                                                                               |
| ------------------------------ | ---------- | ------------------------ | -------------------------------------------------------------------------------------- |
| 1 Co-Purchase Cross-Sell-Class | Class 图表 | "Same-Order Cross-Sell"  | `sum(co_net_pay_order_cnt) / sum(net_pay_order_cnt)`（直接聚合）                     |
| 1 Co-Purchase Cross-Sell-Class | Class 图表 | "Cross-Order Cross-Sell" | `count(distinct user_id) / count(distinct user_id) ALLSELECTED(co_category_summary)` |
| 2 Co-Purchase Cross-Sell-Label | Label 图表 | "Same-Order Cross-Sell"  | `sum(co_net_pay_order_cnt) / sum(net_pay_order_cnt)`（直接聚合）                     |
| 2 Co-Purchase Cross-Sell-Label | Label 图表 | "Cross-Order Cross-Sell" | `count(distinct user_id) / count(distinct user_id) ALLSELECTED(co_brand)`            |

### 1.5 指标 3/4/5 口径

- **指标 3 Product Path 1st Class**：`count(distinct user_id) where payment_time_seq = 1`
- **指标 4 Product Path 2st Class**：`count(distinct user_id) where payment_time_seq = 2`
- **指标 5 Product Path 3st Class**：`count(distinct user_id) where payment_time_seq = 3`

---

## 2. 现状分析

### 2.1 数据底表

| 表名                                          | 日期字段       | 用途         | 关键字段                                                                                                                             |
| --------------------------------------------- | -------------- | ------------ | ------------------------------------------------------------------------------------------------------------------------------------ |
| `a03_e2e_customer_order_correlation_data_m` | `data_month` | 连带率聚合   | `co_net_pay_order_cnt`, `net_pay_order_cnt`, `user_id`, `co_brand`, `co_category_summary`, `brand`, `category_summary` |
| `a03_e2e_customer_time_ordered_data_m`      | `dt`         | 商品路径聚合 | `user_id`, `payment_time_seq`, `brand`, `category_summary`                                                                   |

### 2.2 切片器表

| 表名                                  | 关键列                    | 取值                                                       | 用途                    |
| ------------------------------------- | ------------------------- | ---------------------------------------------------------- | ----------------------- |
| `Slicer_Co_Purchase_Type_Selection` | `CoPurchase_Type_Label` | `"Same-Order Cross-Sell"` / `"Cross-Order Cross-Sell"` | 切换同单/跨单连带率公式 |

### 2.3 关键说明

- 时间/周期/类型筛选由模型关系自动传递，DAX 无需显式处理 `data_month`、`correlation_period`、`correlation_type`、`dt`、`period`
- 指标 1/2 通过 `SELECTEDVALUE(Slicer_Co_Purchase_Type_Selection[CoPurchase_Type_Label])` 切换 Same-Order / Cross-Order 公式
- `payment_time_seq` 是指标 3/4/5 的核心业务定义（区分第 1/2/3 次购买），需在 DAX 中显式筛选
- Cross-Order 分母用 `ALLSELECTED` 移除图表维度，保留外部切片器筛选

---

## 3. 方案设计

### 3.1 度量值分层

```
Value 度量（5 个）  ←  直接计算指标值（指标 1/2 内部 SWITCH 切换公式）
    ↓
Display 度量（5 个） ←  按数据格式格式化
```

### 3.2 数据格式规范

| 数据格式        | 格式串                        | 示例  | 适用指标   |
| --------------- | ----------------------------- | ----- | ---------- |
| `percent_0dp` | `FORMAT(__Value, "#,##0%")` | 30%   | 指标 1/2   |
| `integer`     | `FORMAT(__Value, "#,##0")`  | 1,234 | 指标 3/4/5 |

### 3.3 指标 1/2 分支切换模式

```dax
// 通用 SWITCH 模式（指标 1/2 共用结构，仅 Cross-Order 分母的 ALLSELECTED 字段不同）
VAR __CoPurchaseType = SELECTEDVALUE(Slicer_Co_Purchase_Type_Selection[CoPurchase_Type_Label])
RETURN
    SWITCH(
        __CoPurchaseType,
        "Same-Order Cross-Sell",   <Same-Order 公式>,
        "Cross-Order Cross-Sell",  <Cross-Order 公式>,
        BLANK()
    )
```

---

## 4. 度量值实现

### 4.1 Co-Purchase Cross-Sell-Class（指标 1 — Class 图表）

#### 4.1.1 Co-Purchase Cross-Sell-Class Value

```dax
Co-Purchase Cross-Sell-Class Value = 
// ========================================
// 度量值: Co-Purchase Cross-Sell-Class Value
// 用途: Class 图表的连带率，按 Slicer_Co_Purchase_Type_Selection 切换 Same-Order / Cross-Order 公式
// 分支 Same-Order:  sum(co_net_pay_order_cnt) / sum(net_pay_order_cnt)（直接聚合）
// 分支 Cross-Order: 同Same-Order逻辑
// 数据底表: a03_e2e_customer_order_correlation_data_m
// 筛选处理: 时间/周期/类型由模型关系自动传递；
// 行维度: co_category_summary 直接拉取，自动分组
// 数据格式: percent_0dp（Display 层处理）
// ========================================
// 获取当前上下文的行和列值
VAR __CurrentCategory_Summary = SELECTEDVALUE(Dim_Category_Summary[category_summary])
VAR __CurrentCo_Category_Summary = SELECTEDVALUE(Dim_Co_Category_Summary[co_category_summary])
VAR __co_net_pay_order_cnt = 
    CALCULATE(
        SUM('a03_e2e_customer_order_correlation_data_m'[co_net_pay_order_cnt]),
        a03_e2e_customer_order_correlation_data_m[category_summary] = __CurrentCategory_Summary,
        a03_e2e_customer_order_correlation_data_m[co_category_summary] = __CurrentCo_Category_Summary
    )
VAR __net_pay_order_cnt = 
    CALCULATE(
        SUM('a03_e2e_customer_order_correlation_data_m'[net_pay_order_cnt]),
        a03_e2e_customer_order_correlation_data_m[category_summary] = __CurrentCategory_Summary,
        a03_e2e_customer_order_correlation_data_m[co_category_summary] = __CurrentCo_Category_Summary
    )

RETURN
    DIVIDE(
                __co_net_pay_order_cnt,
                __net_pay_order_cnt
            )
```

#### 4.1.2 Co-Purchase Cross-Sell-Class Display

```dax
Co-Purchase Cross-Sell-Class Display =
// ========================================
// 度量值: Co-Purchase Cross-Sell-Class Display
// 用途: 按 percent_0dp 格式化（百分比整数，不含正号）
// ========================================
VAR __Value = [Co-Purchase Cross-Sell-Class Value]
RETURN
    IF(
        ISBLANK(__Value),
        "-",
        FORMAT(__Value, "#,##0%")
    )
```

#### 4.1.3 Is_Matrix_Row_Visible_Category

```dax
Is_Matrix_Row_Visible_Category = 
// ========================================
// 用途：严格按度量值结果判断，当前 Category_Summary (行) 是否至少有一个 Co_Category_Summary (列) 有真实数据
// 返回值：1 (显示该行), 0 (隐藏该行)
// ========================================

VAR __CurrentCategory = SELECTEDVALUE(Dim_Category_Summary[category_summary])

// 获取当前筛选上下文下，所有可见的 Co_Category_Summary 列表
VAR __AllVisibleCoCategories = ALLSELECTED(Dim_Co_Category_Summary[co_category_summary])

// 迭代检查：遍历这一行所有的 Co_Category_Summary
VAR __HasValidDataInRow = 
    MAXX(
        __AllVisibleCoCategories,
        VAR __CurrentCoCategory = Dim_Co_Category_Summary[co_category_summary]
  
        // 严格复刻单元格计算逻辑
        VAR __CellResult = 
            CALCULATE(
                [Co-Purchase Cross-Sell-Class Value], 
                'a03_e2e_customer_order_correlation_data_m'[category_summary] = __CurrentCategory,
                'a03_e2e_customer_order_correlation_data_m'[co_category_summary] = __CurrentCoCategory
            )
    
        RETURN
            IF(NOT ISBLANK(__CellResult), 1, 0)
    )

RETURN
    IF(__HasValidDataInRow = 1, 1, 0)
```

#### 4.1.4 Is_Matrix_Col_Visible_CoCategory

```dax
Is_Matrix_Col_Visible_CoCategory = 
// ========================================
// 用途：严格按度量值结果判断，当前 Co_Category_Summary (列) 是否至少有一个 Category_Summary (行) 有真实数据
// 返回值：1 (显示该列), 0 (隐藏该列)
// ========================================

VAR __CurrentCoCategory = SELECTEDVALUE(Dim_Co_Category_Summary[co_category_summary])

// 获取当前筛选上下文下，所有可见的 Category_Summary 列表
VAR __AllVisibleCategories = ALLSELECTED(Dim_Category_Summary[category_summary])

// 迭代检查：遍历这一列所有的 Category_Summary
VAR __HasValidDataInCol = 
    MAXX(
        __AllVisibleCategories,
        VAR __CurrentCategory = Dim_Category_Summary[category_summary]
  
        VAR __CellResult = 
            CALCULATE(
                [Co-Purchase Cross-Sell-Class Value], 
                'a03_e2e_customer_order_correlation_data_m'[category_summary] = __CurrentCategory,
                'a03_e2e_customer_order_correlation_data_m'[co_category_summary] = __CurrentCoCategory
            )
    
        RETURN
            IF(NOT ISBLANK(__CellResult), 1, 0)
    )

RETURN
    IF(__HasValidDataInCol = 1, 1, 0)
```
#### 4.1.5 Co-Purchase Cross-Sell-Class SVG
```dax
Co-Purchase Cross-Sell-Class SVG = 
// ========================================
// 度量值: Co-Purchase Cross-Sell-Class SVG
// 用途: 热力矩阵图单元格，背景/字体颜色按值四点三段插值自适应
// 背景插值: 0%→#d8dee5, 30%→#95afcf, 50%→#0c2340, 100%→#000000
// 字体插值: 0%→#737373, 30%→#333333, 35%→#ffffff, 100%→#ffffff（白色提前到35%）
// 无百分比切片器，全部视为范围内
// 基础度量: [Co-Purchase Cross-Sell-Class Value]
// ========================================

// ── 1. 读取基础值 ──
VAR _RawValue = [Co-Purchase Cross-Sell-Class Value]
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
VAR __IsDetailCell =
    ISINSCOPE(Dim_Category_Summary[category_summary])
        && ISINSCOPE(Dim_Co_Category_Summary[co_category_summary])

RETURN
    IF(
        NOT __IsDetailCell,
        // 总计位置不绘制 SVG
        BLANK(),
        IF(
            _IsBlank,
            // 当前单元格为空时，检查所在行、列是否分别存在有效值
            IF(
                [Is_Matrix_Row_Visible_Category] = 1
                    && [Is_Matrix_Col_Visible_CoCategory] = 1,
                _URL,
                BLANK()
            ),
            // 当前单元格有值，所在行、列必然有效
            _URL
        )
    )

```

### 4.2 Co-Purchase Cross-Sell-Label（指标 2 — Label 图表）

#### 4.2.1 Co-Purchase Cross-Sell-Label Value

```dax
Co-Purchase Cross-Sell-Label Value = 
// ========================================
// 度量值: Co-Purchase Cross-Sell-Label Value
// 用途: Label 图表的连带率，按 Slicer_Co_Purchase_Type_Selection 切换 Same-Order / Cross-Order 公式
// 分支 Same-Order:  sum(co_net_pay_order_cnt) / sum(net_pay_order_cnt)（直接聚合）
// 分支 Cross-Order: 同Same-Order逻辑
// 数据底表: a03_e2e_customer_order_correlation_data_m
// 筛选处理: 时间/周期/类型由模型关系自动传递；
// 行维度: co_brand 直接拉取，自动分组
// 数据格式: percent_0dp（Display 层处理）
// ========================================
// 获取当前上下文的行和列值
VAR __CurrentBrand = SELECTEDVALUE(Dim_Brand[brand])
VAR __CurrentCoBrand = SELECTEDVALUE(Dim_Co_Brand[co_brand])
VAR __co_net_pay_order_cnt = 
    CALCULATE(
        SUM('a03_e2e_customer_order_correlation_data_m'[co_net_pay_order_cnt]),
        a03_e2e_customer_order_correlation_data_m[brand] = __CurrentBrand,
        a03_e2e_customer_order_correlation_data_m[co_brand] = __CurrentCoBrand
    )
VAR __net_pay_order_cnt = 
    CALCULATE(
        SUM('a03_e2e_customer_order_correlation_data_m'[net_pay_order_cnt]),
        a03_e2e_customer_order_correlation_data_m[brand] = __CurrentBrand,
        a03_e2e_customer_order_correlation_data_m[co_brand] = __CurrentCoBrand
    )

RETURN
    DIVIDE(
                __co_net_pay_order_cnt,
                __net_pay_order_cnt
            )
```

#### 4.2.2 Co-Purchase Cross-Sell-Label Display

```dax
Co-Purchase Cross-Sell-Label Display =
// ========================================
// 度量值: Co-Purchase Cross-Sell-Label Display
// 用途: 按 percent_0dp 格式化（百分比整数，不含正号）
// ========================================
VAR __Value = [Co-Purchase Cross-Sell-Label Value]
RETURN
    IF(
        ISBLANK(__Value),
        "-",
        FORMAT(__Value, "#,##0%")
    )
```

#### 4.2.3 Is_Matrix_Row_Visible_Brand

```dax
Is_Matrix_Row_Visible_Brand = 
// ========================================
// 用途：严格按度量值结果判断，当前 Brand (行) 是否至少有一个 Co_Brand (列) 有真实数据
// 返回值：1 (显示该行), 0 (隐藏该行)
// ========================================

VAR __CurrentBrand = SELECTEDVALUE(Dim_Brand[brand])

// 获取当前筛选上下文下，所有可见的 Co_Brand 列表
VAR __AllVisibleCoBrands = ALLSELECTED(Dim_Co_Brand[co_brand])

// 迭代检查：遍历这一行所有的 Co_Brand
VAR __HasValidDataInRow = 
    MAXX(
        __AllVisibleCoBrands,
        VAR __CurrentCoBrand = Dim_Co_Brand[co_brand]
      
        // 严格复刻单元格计算逻辑，直接调用核心度量值
        VAR __CellResult = 
            CALCULATE(
                [Co-Purchase Cross-Sell-Label Value], 
                a03_e2e_customer_order_correlation_data_m[brand] = __CurrentBrand,
                a03_e2e_customer_order_correlation_data_m[co_brand] = __CurrentCoBrand
            )
          
        RETURN
            IF(NOT ISBLANK(__CellResult), 1, 0)
    )

RETURN
    IF(__HasValidDataInRow = 1, 1, 0)
```

#### 4.2.4 Is_Matrix_Col_Visible_CoBrand

```dax
Is_Matrix_Col_Visible_CoBrand = 
// ========================================
// 用途：严格按度量值结果判断，当前 Co_Brand (列) 是否至少有一个 Brand (行) 有真实数据
// 返回值：1 (显示该列), 0 (隐藏该列)
// ========================================

VAR __CurrentCoBrand = SELECTEDVALUE(Dim_Co_Brand[co_brand])

// 获取当前筛选上下文下，所有可见的 Brand 列表
VAR __AllVisibleBrands = ALLSELECTED(Dim_Brand[brand])

// 迭代检查：遍历这一列所有的 Brand
VAR __HasValidDataInCol = 
    MAXX(
        __AllVisibleBrands,
        VAR __CurrentBrand = Dim_Brand[brand]
    
        VAR __CellResult = 
            CALCULATE(
                [Co-Purchase Cross-Sell-Label Value], 
                a03_e2e_customer_order_correlation_data_m[brand] = __CurrentBrand,
                a03_e2e_customer_order_correlation_data_m[co_brand] = __CurrentCoBrand
            )
        
        RETURN
            IF(NOT ISBLANK(__CellResult), 1, 0)
    )

RETURN
    IF(__HasValidDataInCol = 1, 1, 0)
```

#### 4.2.5 Co-Purchase Cross-Sell-Label SVG
```dax
Co-Purchase Cross-Sell-Label SVG = 
// ========================================
// 度量值: Co-Purchase Cross-Sell-Label SVG
// 用途: 热力矩阵图单元格，背景/字体颜色按值四点三段插值自适应
// 背景插值: 0%→#d8dee5, 30%→#95afcf, 50%→#0c2340, 100%→#000000
// 字体插值: 0%→#737373, 30%→#333333, 35%→#ffffff, 100%→#ffffff（白色提前到35%）
// 无百分比切片器，全部视为范围内
// 基础度量: [Co-Purchase Cross-Sell-Label Value]
// ========================================

// ── 1. 读取基础值 ──
VAR _RawValue = [Co-Purchase Cross-Sell-Label Value]
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

// ── 6. 判断当前计算位置 ──
// 两个字段都处于分组层级，表示当前是 Brand × CoBrand 交叉明细。
// 这里只区分明细与总计，不检查当前单元格是否存在业务数据。
VAR __IsDetailCell =
    ISINSCOPE(Dim_Brand[brand])
        && ISINSCOPE(Dim_Co_Brand[co_brand])

RETURN
    IF(
        NOT __IsDetailCell,

        // 情况一：总计位置。
        // 不绘制 SVG，也不使用仅适用于明细的行列可见性判断。
        BLANK(),

        IF(
            _IsBlank,

            // 情况二：当前交叉点的基础 Value 为空。
            // 不能直接绘制灰色图片，否则全空行列也会被图片撑出来。
            // 必须分别检查当前交叉点所在的整行、整列是否应当保留。
            IF(
                // 行有效：固定当前 Brand，
                // 扫描所选 CoBrand，至少一个 Value 非空。
                [Is_Matrix_Row_Visible_Brand] = 1

                    // 列有效：固定当前 CoBrand，
                    // 扫描所选 Brand，至少一个 Value 非空。
                    && [Is_Matrix_Col_Visible_CoBrand] = 1,

                // 行列均有效：
                // 当前空值属于有效矩阵内部的缺口，保留灰色 "-" SVG。
                _URL,

                // 行全空或列全空：
                // 返回真正的 BLANK()，而不是空白图片或 "-" 字符串。
                // 该无效行/列上的每个单元格都会因此返回 BLANK()，
                // 由矩阵自身的空值抑制机制隐藏整行或整列。
                BLANK()
            ),

            // 情况三：当前交叉点的基础 Value 非空。
            // 当前单元格本身已证明所在行、所在列都有有效数据，
            // 无需再扫描两个方向，直接绘制百分比 SVG。
            // 0% 也属于非空有效值，会正常保留。
            _URL
        )
    )

```
### 4.3 Product Path 1st Class（指标 3）

#### 4.3.1 Product Path 1st Class Value

```dax
Product Path 1st Class Value =
// ========================================
// 度量值: Product Path 1st Class Value
// 用途: 第 1 次购买商品的买家人数
// 计算: count(distinct user_id) where payment_time_seq = 1
// 数据底表: a03_e2e_customer_time_ordered_data_m
// 筛选处理: dt/period 由模型关系自动传递；payment_time_seq = 1 为核心业务定义，需显式筛选
// 行维度: brand, category_summary 直接拉取，自动分组
// 数据格式: integer（Display 层处理）
// ========================================
CALCULATE(
    DISTINCTCOUNT('a03_e2e_customer_time_ordered_data_m'[user_id]),
    'a03_e2e_customer_time_ordered_data_m'[payment_time_seq] = 1
)
```

#### 4.3.2 Product Path 1st Class Display

```dax
Product Path 1st Class Display =
// ========================================
// 度量值: Product Path 1st Class Display
// 用途: 按 integer 格式化（整数千分位）
// ========================================
VAR __Value = [Product Path 1st Class Value]
RETURN
    IF(
        ISBLANK(__Value),
        "-",
        FORMAT(__Value, "#,##0")
    )
```

### 4.4 Product Path 2st Class（指标 4）

#### 4.4.1 Product Path 2st Class Value

```dax
Product Path 2st Class Value =
// ========================================
// 度量值: Product Path 2st Class Value
// 用途: 第 2 次购买商品的买家人数
// 计算: count(distinct user_id) where payment_time_seq = 2
// 数据底表: a03_e2e_customer_time_ordered_data_m
// 筛选处理: dt/period 由模型关系自动传递；payment_time_seq = 2 为核心业务定义，需显式筛选
// 行维度: brand, category_summary 直接拉取，自动分组
// 数据格式: integer（Display 层处理）
// ========================================
CALCULATE(
    DISTINCTCOUNT('a03_e2e_customer_time_ordered_data_m'[user_id]),
    'a03_e2e_customer_time_ordered_data_m'[payment_time_seq] = 2
)
```

#### 4.4.2 Product Path 2st Class Display

```dax
Product Path 2st Class Display =
// ========================================
// 度量值: Product Path 2st Class Display
// 用途: 按 integer 格式化（整数千分位）
// ========================================
VAR __Value = [Product Path 2st Class Value]
RETURN
    IF(
        ISBLANK(__Value),
        "-",
        FORMAT(__Value, "#,##0")
    )
```

### 4.5 Product Path 3st Class（指标 5）

#### 4.5.1 Product Path 3st Class Value

```dax
Product Path 3st Class Value =
// ========================================
// 度量值: Product Path 3st Class Value
// 用途: 第 3 次购买商品的买家人数
// 计算: count(distinct user_id) where payment_time_seq = 3
// 数据底表: a03_e2e_customer_time_ordered_data_m
// 筛选处理: dt/period 由模型关系自动传递；payment_time_seq = 3 为核心业务定义，需显式筛选
// 行维度: brand, category_summary 直接拉取，自动分组
// 数据格式: integer（Display 层处理）
// ========================================
CALCULATE(
    DISTINCTCOUNT('a03_e2e_customer_time_ordered_data_m'[user_id]),
    'a03_e2e_customer_time_ordered_data_m'[payment_time_seq] = 3
)
```

#### 4.5.2 Product Path 3st Class Display

```dax
Product Path 3st Class Display =
// ========================================
// 度量值: Product Path 3st Class Display
// 用途: 按 integer 格式化（整数千分位）
// ========================================
VAR __Value = [Product Path 3st Class Value]
RETURN
    IF(
        ISBLANK(__Value),
        "-",
        FORMAT(__Value, "#,##0")
    )
```

---

## 5. 度量值清单

| #  | 度量值名称                           | 类型    | 数据格式    | 用途                                             |
| -- | ------------------------------------ | ------- | ----------- | ------------------------------------------------ |
| 1  | Co-Purchase Cross-Sell-Class Value   | Value   | percent_0dp | Class 图表连带率（SWITCH 切换 Same/Cross-Order） |
| 2  | Co-Purchase Cross-Sell-Class Display | Display | #,##0%      | 百分比整数不含正号                               |
| 3  | Co-Purchase Cross-Sell-Label Value   | Value   | percent_0dp | Label 图表连带率（SWITCH 切换 Same/Cross-Order） |
| 4  | Co-Purchase Cross-Sell-Label Display | Display | #,##0%      | 百分比整数不含正号                               |
| 5  | Product Path 1st Class Value         | Value   | integer     | 第 1 次购买买家人数                              |
| 6  | Product Path 1st Class Display       | Display | #,##0       | 整数千分位                                       |
| 7  | Product Path 2st Class Value         | Value   | integer     | 第 2 次购买买家人数                              |
| 8  | Product Path 2st Class Display       | Display | #,##0       | 整数千分位                                       |
| 9  | Product Path 3st Class Value         | Value   | integer     | 第 3 次购买买家人数                              |
| 10 | Product Path 3st Class Display       | Display | #,##0       | 整数千分位                                       |

---

## 6. 注意事项

1. **指标 1/2 合并逻辑**：原 3 个指标（Same-Order / Cross-Order-Class / Cross-Order-Label）合并为 2 个，分别对应 Class 图表和 Label 图表。度量内部通过 `SELECTEDVALUE(Slicer_Co_Purchase_Type_Selection[CoPurchase_Type_Label])` 切换 Same-Order（直接聚合）与 Cross-Order（分母 ALLSELECTED 移除图表维度）公式。
2. **Class/Label 按钮决定图表**：指标 1 放在 Class 图表（行维度 `co_category_summary`），指标 2 放在 Label 图表（行维度 `co_brand`）。按钮切换显示对应图表，度量内部不需要判断 Class/Label，只需判断 `Slicer_Co_Purchase_Type_Selection`。
3. **无需 DAX 显式处理时间/周期/类型筛选**：`data_month`、`correlation_period`、`correlation_type`、`dt`、`period` 由模型关系或表字段自动传递，DAX 不显式处理。此为 Co-Purchase 模块与其他模块（如 Class x Label Drilldown 显式处理 `dt` 区间）的关键差异。
4. **行维度直接拉取事实表字段**：`co_brand` / `co_category_summary` / `brand` / `category_summary` 从事实表直接拉取，表关系自动传递分组与筛选，DAX 无需显式处理。
5. **Cross-Order 分母移除图表维度（指标 1/2 的 Cross-Order 分支）**：

   - 指标 1（Class）：分母用 `ALLSELECTED('a03_e2e_customer_order_correlation_data_m'[co_category_summary])` 移除图表 `co_category_summary` 维度，保留外部切片器筛选
   - 指标 2（Label）：分母用 `ALLSELECTED('a03_e2e_customer_order_correlation_data_m'[co_brand])` 移除图表 `co_brand` 维度，保留外部切片器筛选
   - `ALLSELECTED` 仅移除图表行维度的筛选，保留外部切片器对该字段的筛选
6. **payment_time_seq 为核心业务定义（指标 3/4/5）**：`payment_time_seq = 1/2/3` 是区分第 1/2/3 次购买的核心业务定义，需在 DAX 中显式筛选；`dt`/`period` 时间筛选由模型关系自动传递。
7. **SWITCH 短路求值**：指标 1/2 使用 `SWITCH` 内联表达式，DAX 仅计算匹配分支的公式，非匹配分支不求值，避免 Same-Order 与 Cross-Order 公式互相干扰。
8. **BLANK 处理**：所有 Display 度量在 Value 为 BLANK 时显示 `"-"`，避免空白单元格影响可读性。
9. **本模块不涉及汇率换算**：5 个指标均为百分比或整数类型，无量纲金额，无需 `Currency_ExchangeRate` 换算。
