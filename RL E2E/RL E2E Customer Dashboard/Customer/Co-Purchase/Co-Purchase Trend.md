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

| 项目 | 说明 |
| --- | --- |
| **无需 DAX 显式处理时间/周期/类型筛选** | `data_month`、`correlation_period`、`correlation_type`、`dt`、`period` 由模型关系或表字段自动传递，DAX 不显式处理 |
| **Class/Label 按钮决定图表** | 指标 1 用于 Class 图表，指标 2 用于 Label 图表；度量内部通过 `Slicer_Co_Purchase_Type_Selection` 切换 Same-Order / Cross-Order 公式 |
| **行维度直接拉取事实表字段** | `co_brand` / `co_category_summary` / `brand` / `category_summary` 从事实表直接拉取，自动分组与筛选 |
| **Cross-Order 分母移除图表维度** | Class 图表分母用 `ALLSELECTED(co_category_summary)`，Label 图表分母用 `ALLSELECTED(co_brand)`，保留外部切片器筛选 |
| **货币转换** | 本模块均为百分比/整数指标，不涉及汇率换算 |

### 1.3 5 个指标清单

| # | 指标名称 | 子模块 | 适用图表 | 分组维度 | 类型 | 数据格式 |
| - | -------- | ------ | -------- | -------- | ---- | -------- |
| 1 | Co-Purchase Cross-Sell-Class | Co-Purchase Matrix | Class 图表 | co_category_summary | percent_0dp | #,##0% |
| 2 | Co-Purchase Cross-Sell-Label | Co-Purchase Matrix | Label 图表 | co_brand | percent_0dp | #,##0% |
| 3 | Product Path 1st Class | Product Path | 通用 | brand, category_summary | integer | #,##0 |
| 4 | Product Path 2st Class | Product Path | 通用 | brand, category_summary | integer | #,##0 |
| 5 | Product Path 3st Class | Product Path | 通用 | brand, category_summary | integer | #,##0 |

### 1.4 指标 1/2 分支口径（按 Slicer_Co_Purchase_Type_Selection 切换）

**Slicer_Co_Purchase_Type_Selection[CoPurchase_Type_Label]** 取值：`"Same-Order Cross-Sell"` / `"Cross-Order Cross-Sell"`

| 指标 | 按钮上下文 | 切片器取值 | 输出公式 |
| ---- | ---------- | ---------- | -------- |
| 1 Co-Purchase Cross-Sell-Class | Class 图表 | "Same-Order Cross-Sell" | `sum(co_net_pay_order_cnt) / sum(net_pay_order_cnt)`（直接聚合） |
| 1 Co-Purchase Cross-Sell-Class | Class 图表 | "Cross-Order Cross-Sell" | `count(distinct user_id) / count(distinct user_id) ALLSELECTED(co_category_summary)` |
| 2 Co-Purchase Cross-Sell-Label | Label 图表 | "Same-Order Cross-Sell" | `sum(co_net_pay_order_cnt) / sum(net_pay_order_cnt)`（直接聚合） |
| 2 Co-Purchase Cross-Sell-Label | Label 图表 | "Cross-Order Cross-Sell" | `count(distinct user_id) / count(distinct user_id) ALLSELECTED(co_brand)` |

### 1.5 指标 3/4/5 口径

- **指标 3 Product Path 1st Class**：`count(distinct user_id) where payment_time_seq = 1`
- **指标 4 Product Path 2st Class**：`count(distinct user_id) where payment_time_seq = 2`
- **指标 5 Product Path 3st Class**：`count(distinct user_id) where payment_time_seq = 3`

---

## 2. 现状分析

### 2.1 数据底表

| 表名 | 日期字段 | 用途 | 关键字段 |
| --- | --- | --- | --- |
| `a03_e2e_customer_order_correlation_data_m` | `data_month` | 连带率聚合 | `co_net_pay_order_cnt`, `net_pay_order_cnt`, `user_id`, `co_brand`, `co_category_summary`, `brand`, `category_summary` |
| `a03_e2e_customer_time_ordered_data_m` | `dt` | 商品路径聚合 | `user_id`, `payment_time_seq`, `brand`, `category_summary` |

### 2.2 切片器表

| 表名 | 关键列 | 取值 | 用途 |
| --- | --- | --- | --- |
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

| 数据格式 | 格式串 | 示例 | 适用指标 |
| --- | --- | --- | --- |
| `percent_0dp` | `FORMAT(__Value, "#,##0%")` | 30% | 指标 1/2 |
| `integer` | `FORMAT(__Value, "#,##0")` | 1,234 | 指标 3/4/5 |

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
// 分支 Cross-Order: count(distinct user_id) / count(distinct user_id) ALLSELECTED(co_category_summary)
// 数据底表: a03_e2e_customer_order_correlation_data_m
// 筛选处理: 时间/周期/类型由模型关系自动传递；Cross-Order 分母显式移除图表 co_category_summary 维度
// 行维度: co_category_summary 直接拉取，自动分组
// 数据格式: percent_0dp（Display 层处理）
// ========================================
VAR __CoPurchaseType = SELECTEDVALUE(Slicer_Co_Purchase_Type_Selection[CoPurchase_Type_Label])

RETURN
    SWITCH(
        __CoPurchaseType,
        // ── Same-Order 分支: 同单连带率，直接聚合 ──
        "Same-Order Cross-Sell",
            DIVIDE(
                SUM('a03_e2e_customer_order_correlation_data_m'[co_net_pay_order_cnt]),
                SUM('a03_e2e_customer_order_correlation_data_m'[net_pay_order_cnt])
            ),
        // ── Cross-Order 分支: 跨单连带率，分母移除图表 co_category_summary 维度 ──
        "Cross-Order Cross-Sell",
            DIVIDE(
                DISTINCTCOUNT('a03_e2e_customer_order_correlation_data_m'[user_id]),
                CALCULATE(
                    DISTINCTCOUNT('a03_e2e_customer_order_correlation_data_m'[user_id]),
                    ALLSELECTED('a03_e2e_customer_order_correlation_data_m'[co_category_summary])
                )
            ),
        BLANK()
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

### 4.2 Co-Purchase Cross-Sell-Label（指标 2 — Label 图表）

#### 4.2.1 Co-Purchase Cross-Sell-Label Value

```dax
Co-Purchase Cross-Sell-Label Value =
// ========================================
// 度量值: Co-Purchase Cross-Sell-Label Value
// 用途: Label 图表的连带率，按 Slicer_Co_Purchase_Type_Selection 切换 Same-Order / Cross-Order 公式
// 分支 Same-Order:  sum(co_net_pay_order_cnt) / sum(net_pay_order_cnt)（直接聚合）
// 分支 Cross-Order: count(distinct user_id) / count(distinct user_id) ALLSELECTED(co_brand)
// 数据底表: a03_e2e_customer_order_correlation_data_m
// 筛选处理: 时间/周期/类型由模型关系自动传递；Cross-Order 分母显式移除图表 co_brand 维度
// 行维度: co_brand 直接拉取，自动分组
// 数据格式: percent_0dp（Display 层处理）
// ========================================
VAR __CoPurchaseType = SELECTEDVALUE(Slicer_Co_Purchase_Type_Selection[CoPurchase_Type_Label])

RETURN
    SWITCH(
        __CoPurchaseType,
        // ── Same-Order 分支: 同单连带率，直接聚合 ──
        "Same-Order Cross-Sell",
            DIVIDE(
                SUM('a03_e2e_customer_order_correlation_data_m'[co_net_pay_order_cnt]),
                SUM('a03_e2e_customer_order_correlation_data_m'[net_pay_order_cnt])
            ),
        // ── Cross-Order 分支: 跨单连带率，分母移除图表 co_brand 维度 ──
        "Cross-Order Cross-Sell",
            DIVIDE(
                DISTINCTCOUNT('a03_e2e_customer_order_correlation_data_m'[user_id]),
                CALCULATE(
                    DISTINCTCOUNT('a03_e2e_customer_order_correlation_data_m'[user_id]),
                    ALLSELECTED('a03_e2e_customer_order_correlation_data_m'[co_brand])
                )
            ),
        BLANK()
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

| # | 度量值名称 | 类型 | 数据格式 | 用途 |
| --- | --- | --- | --- | --- |
| 1 | Co-Purchase Cross-Sell-Class Value | Value | percent_0dp | Class 图表连带率（SWITCH 切换 Same/Cross-Order） |
| 2 | Co-Purchase Cross-Sell-Class Display | Display | #,##0% | 百分比整数不含正号 |
| 3 | Co-Purchase Cross-Sell-Label Value | Value | percent_0dp | Label 图表连带率（SWITCH 切换 Same/Cross-Order） |
| 4 | Co-Purchase Cross-Sell-Label Display | Display | #,##0% | 百分比整数不含正号 |
| 5 | Product Path 1st Class Value | Value | integer | 第 1 次购买买家人数 |
| 6 | Product Path 1st Class Display | Display | #,##0 | 整数千分位 |
| 7 | Product Path 2st Class Value | Value | integer | 第 2 次购买买家人数 |
| 8 | Product Path 2st Class Display | Display | #,##0 | 整数千分位 |
| 9 | Product Path 3st Class Value | Value | integer | 第 3 次购买买家人数 |
| 10 | Product Path 3st Class Display | Display | #,##0 | 整数千分位 |

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
