# BOSS Performance Dashboard 指标口径提示词

> **Dashboard**: BOSS Performance Dashboard  
> **Tab**: Performance By Merchandise  
> **数据底表**: `a02_e2e_boss_performance_summary_d` / `a02_e2e_boss_fulfillment_request_data_d`  
> **模块说明**: 本板块为 BOSS 按 Label/Product Type/Category/Subcategory 维度的绩效看板，覆盖 BOSS Fulfillment - Fulfillment% by Label、BOSS M/W POLO Unfulfilled Order by Category、BOSS Performance Details 三个子板块，统计履约率分布、M/W POLO 失败订单分布及全量 KPI 明细。

---

## 全局逻辑

| 项目 | 内容 |
|---|---|
| **数据底表** | `a02_e2e_boss_performance_summary_d`、`a02_e2e_boss_fulfillment_request_data_d` |
| **筛选逻辑** | 按各指标定义区分 `calc_type = payment` 或 `calc_type = fulfillment`；并按 `fulfillment_calc_type` 区分履约口径（1: Exclude orders cancelled in pay date；2: Exclude orders cancelled in paydate & EC-fulfilled from O2O unfulfilled） |
| **聚合粒度** | 条形图：所选时间范围 `data_date`，聚合在 `brand` 粒度，从高到低进行排序；表格：`brand` 粒度行支持展开看 `product_type` → `category_summary` → `category` 粒度明细数据；M/W POLO 子板块聚合在 `category_summary` 粒度 |
| **货币转换规则** | 数据源默认为 RMB，转化为美元需要除以固定值 7 |
| **派生指标** | LY（去年同期）、vs LY（同比）、占比等附属指标为派生指标，依据基础指标计算生成 |
| **必须遵守** | 口径文档中定义的所有指标，必须遵守其数据类型和数据格式，如果和解决方案中存在争议的，一切以口径文档为准，必须按照口径文档中的格式进行调整 |

---

## 子模块一：BOSS Fulfillment - Fulfillment% by Label

> **分组维度**: 条形图按 `brand` 分组，从高到低进行排序；表格 `brand` 粒度行支持展开看 `product_type` 粒度明细数据

### 1. Fulfillment% — O2O订单履约率

| 项目 | 内容 |
|---|---|
| **指标名称** | Fulfillment% |
| **指标名称中文** | O2O订单履约率 |
| **业务定义** | 订单类型属于门店发货和门店自提，根据订单付款时间，实际发货的订单数量占客户请求门店的总订单数量的比例 by label/product type 拆分统计 |
| **计算公式** | sum(o2o_fulfillment_shipped_order_cnt) / sum(o2o_fulfillment_request_order_cnt) |
| **分子** | `o2o_fulfillment_shipped_order_cnt` |
| **分母** | `o2o_fulfillment_request_order_cnt` |
| **数据底表** | `a02_e2e_boss_performance_summary_d` |
| **筛选条件** | `calc_type = fulfillment`，条形图按 `brand` 分组从高到低排序；表格 `brand` 粒度行支持展开看 `product_type` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

### 1.1 Request Order Qty — O2O销售订单量（分母项）

| 项目 | 内容 |
|---|---|
| **指标名称** | Request Order Qty |
| **指标名称中文** | O2O销售订单量（分母项） |
| **业务定义** | Fulfillment% 的分母项，订单类型属于门店发货和门店自提，根据订单付款时间，所有配货状态（配货状态为待接单、已配货、配货失败、新建等中间状态）的订单量 by label 拆分统计 |
| **计算公式** | sum(o2o_fulfillment_request_order_cnt) |
| **统计字段** | `o2o_fulfillment_request_order_cnt` |
| **数据底表** | `a02_e2e_boss_performance_summary_d` |
| **筛选条件** | `calc_type = fulfillment`，按 `brand` 分组（表格支持展开到 `product_type`） |
| **数据类型** | integer → 整数，千分位整数 |
| **数据格式** | `#,##0` |

### 1.2 Shipped Order Qty — O2O已配货订单量（分子项）

| 项目 | 内容 |
|---|---|
| **指标名称** | Shipped Order Qty |
| **指标名称中文** | O2O已配货订单量（分子项） |
| **业务定义** | Fulfillment% 的分子项，订单类型属于门店发货和门店自提，根据订单付款时间，配货状态是已配货的订单量 by label 拆分统计 |
| **计算公式** | sum(o2o_fulfillment_shipped_order_cnt) |
| **统计字段** | `o2o_fulfillment_shipped_order_cnt` |
| **数据底表** | `a02_e2e_boss_performance_summary_d` |
| **筛选条件** | `calc_type = fulfillment`，按 `brand` 分组（表格支持展开到 `product_type`） |
| **数据类型** | integer → 整数，千分位整数 |
| **数据格式** | `#,##0` |

---

## 子模块二：BOSS M/W POLO Unfulfilled Order by Category

> **分组维度**: 按 `category_summary` 分组（仅看 M/W POLO）

### 1. Total Unfulfilled Order — O2O失败订单数（W Polo + M Polo）

| 项目 | 内容 |
|---|---|
| **指标名称** | Unfulfilled Order |
| **指标名称中文** | O2O失败订单数（W Polo + M Polo） |
| **业务定义** | 订单维度去重统计，根据订单付款时间，统计配货状态是配货失败的订单量 by category 拆分统计（仅看 W Polo + M Polo） |
| **计算公式** | sum(o2o_fulfillment_unshipped_order_cnt) |
| **统计字段** | `o2o_fulfillment_unshipped_order_cnt` |
| **数据底表** | `a02_e2e_boss_performance_summary_d` |
| **筛选条件** | `calc_type = fulfillment`；`brand` in ("W Polo", "M Polo")；图表按 `category_summary` 分组，category_summary我会直接拉取事实表中的对应字段，对模型天然自带筛选和分组属性，所以这里计算总值需要REMOVEFILTERS移除a02_e2e_boss_performance_summary_d[category]字段的影响。 |
| **聚合粒度** | 根据所选时间范围 `data_date`，聚合在 `category_summary` 粒度 |
| **数据类型** | integer → 整数，千分位整数 |
| **数据格式** | `#,##0` |

### 1.1 W Polo Unfulfilled Order — O2O失败订单数（W Polo）

| 项目 | 内容 |
|---|---|
| **指标名称** | Unfulfilled Order |
| **指标名称中文** | O2O失败订单数（W Polo） |
| **业务定义** | 订单维度去重统计，根据订单付款时间，统计配货状态是配货失败的订单量 by category 拆分统计（仅看 W Polo） |
| **计算公式** | sum(o2o_fulfillment_unshipped_order_cnt) |
| **统计字段** | `o2o_fulfillment_unshipped_order_cnt` |
| **数据底表** | `a02_e2e_boss_performance_summary_d` |
| **筛选条件** | `calc_type = fulfillment`；`brand` in ("W Polo")；按 `category_summary` 分组，category_summary我会直接拉取事实表中的对应字段，对模型天然自带筛选和分组属性。 |
| **聚合粒度** | 根据所选时间范围 `data_date`，聚合在 `category_summary` 粒度 |
| **数据类型** | integer → 整数，千分位整数 |
| **数据格式** | `#,##0` |

### 1.2 M Polo Unfulfilled Order — O2O失败订单数（M Polo）

| 项目 | 内容 |
|---|---|
| **指标名称** | Unfulfilled Order |
| **指标名称中文** | O2O失败订单数（M Polo） |
| **业务定义** | 订单维度去重统计，根据订单付款时间，统计配货状态是配货失败的订单量 by category 拆分统计（仅看 M Polo） |
| **计算公式** | sum(o2o_fulfillment_unshipped_order_cnt) |
| **统计字段** | `o2o_fulfillment_unshipped_order_cnt` |
| **数据底表** | `a02_e2e_boss_performance_summary_d` |
| **筛选条件** | `calc_type = fulfillment`；`brand` in ("M Polo")；按 `category_summary` 分组，category_summary我会直接拉取事实表中的对应字段，对模型天然自带筛选和分组属性。 |
| **聚合粒度** | 根据所选时间范围 `data_date`，聚合在 `category_summary` 粒度 |
| **数据类型** | integer → 整数，千分位整数 |
| **数据格式** | `#,##0` |

### 1.3 W Polo Unfulfilled Order Share — W Polo O2O失败订单数占比

| 项目 | 内容 |
|---|---|
| **指标名称** | Unfulfilled Order Share |
| **指标名称中文** | W Polo O2O失败订单数占比 |
| **业务定义** | 每个 `category_summary` 占 W Polo + M Polo 总和的比例 |
| **计算公式** | W Polo Unfulfilled Order / Total Unfulfilled Order |
| **分子** | [M Polo Unfulfilled Order]这里是1.1 W Polo Unfulfilled Order — O2O失败订单数（W Polo）已经计算好的度量 |
| **分母** | [Total Unfulfilled Order]这里是1. Total Unfulfilled Order — O2O失败订单数（W Polo + M Polo）已经计算好的度量 |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

### 1.4 M Polo Unfulfilled Order Share — M Polo O2O失败订单数占比

| 项目 | 内容 |
|---|---|
| **指标名称** | Unfulfilled Order Share |
| **指标名称中文** | M Polo O2O失败订单数占比 |
| **业务定义** | 每个 `category_summary` 占 W Polo + M Polo 总和的比例 |
| **计算公式** | M Polo Unfulfilled Order / Total Unfulfilled Order |
| **分子** | [M Polo Unfulfilled Order]这里是1.2 M Polo Unfulfilled Order — O2O失败订单数（M Polo）已经计算好的度量 |
| **分母** | [Total Unfulfilled Order]这里是1. Total Unfulfilled Order — O2O失败订单数（W Polo + M Polo）已经计算好的度量 |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

---

## 子模块三：BOSS Performance Details

> **分组维度**: 按 `brand` / `product_type` / `category_summary` / `category` 分组；`brand` 粒度行支持展开看 `product_type` → `category_summary` → `category` 粒度明细数据

### 1. SLS — O2O销售净额

| 项目 | 内容 |
|---|---|
| **指标名称** | SLS |
| **指标名称中文** | O2O销售净额 |
| **业务定义** | 订单类型属于门店发货和门店自提，BI中退货入库金额+销售出库金额, 统计时间为出入库时间 by label/product type/category/subcategory 拆分统计 |
| **计算公式** | sum(o2o_net_sales_amt) |
| **统计字段** | `o2o_net_sales_amt` |
| **数据底表** | `a02_e2e_boss_performance_summary_d` |
| **筛选条件** | `calc_type = payment`，按 `brand`/`product_type`/`category_summary`/`category` 分组（`brand` 行支持展开到 `product_type` → `category_summary` → `category`） |
| **数据类型** | currency → 货币符号由币种切片器决定，千分位整数 |
| **数据格式** | `#,##0`（在 DAX 中用 `__CurrencySymbol & FORMAT(__Value, "#,##0")` 拼接币种符号） |

### 1.1 SLS LY — O2O销售净额（对比去年同期）

| 项目 | 内容 |
|---|---|
| **指标名称** | SLS LY |
| **指标名称中文** | O2O销售净额（对比去年同期） |
| **业务定义** | 取去年同期O2O销售净额 |
| **计算公式** | 去年同期 sum(o2o_net_sales_amt) |
| **数据底表** | `a02_e2e_boss_performance_summary_d` |
| **筛选条件** | `calc_type = payment`，按 `brand`/`product_type`/`category_summary`/`category` 分组，取去年同期 |
| **数据类型** | currency → 货币符号由币种切片器决定，千分位整数 |
| **数据格式** | `#,##0`（在 DAX 中用 `__CurrencySymbol & FORMAT(__Value, "#,##0")` 拼接币种符号） |

### 1.2 SLS vs LY — O2O销售净额同比

| 项目 | 内容 |
|---|---|
| **指标名称** | SLS vs LY |
| **指标名称中文** | O2O销售净额同比 |
| **业务定义** | O2O销售净额今年较去年同期的变化率 |
| **计算公式** | 今年 / 去年 − 1 |
| **数据底表** | `a02_e2e_boss_performance_summary_d` |
| **筛选条件** | `calc_type = payment`，按 `brand`/`product_type`/`category_summary`/`category` 分组 |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

---

### 2. Demand SLS — O2O退前销售额

| 项目 | 内容 |
|---|---|
| **指标名称** | Demand SLS |
| **指标名称中文** | O2O退前销售额 |
| **业务定义** | O2O退前销售额（平台付款时间维度GMV数据）by label/product type/category/subcategory 拆分统计 |
| **计算公式** | sum(o2o_sales_amt) |
| **统计字段** | `o2o_sales_amt` |
| **数据底表** | `a02_e2e_boss_performance_summary_d` |
| **筛选条件** | `calc_type = payment`，按 `brand`/`product_type`/`category_summary`/`category` 分组 |
| **数据类型** | currency → 货币符号由币种切片器决定，千分位整数 |
| **数据格式** | `#,##0`（在 DAX 中用 `__CurrencySymbol & FORMAT(__Value, "#,##0")` 拼接币种符号） |

### 2.1 Demand SLS LY — O2O退前销售额（对比去年同期）

| 项目 | 内容 |
|---|---|
| **指标名称** | Demand SLS LY |
| **指标名称中文** | O2O退前销售额（对比去年同期） |
| **业务定义** | 取去年同期O2O退前销售额 |
| **计算公式** | 去年同期 sum(o2o_sales_amt) |
| **数据底表** | `a02_e2e_boss_performance_summary_d` |
| **筛选条件** | `calc_type = payment`，按 `brand`/`product_type`/`category_summary`/`category` 分组，取去年同期 |
| **数据类型** | currency → 货币符号由币种切片器决定，千分位整数 |
| **数据格式** | `#,##0`（在 DAX 中用 `__CurrencySymbol & FORMAT(__Value, "#,##0")` 拼接币种符号） |

### 2.2 Demand SLS vs LY — O2O退前销售额同比

| 项目 | 内容 |
|---|---|
| **指标名称** | Demand SLS vs LY |
| **指标名称中文** | O2O退前销售额同比 |
| **业务定义** | O2O退前销售额今年较去年同期的变化率 |
| **计算公式** | 今年 / 去年 − 1 |
| **数据底表** | `a02_e2e_boss_performance_summary_d` |
| **筛选条件** | `calc_type = payment`，按 `brand`/`product_type`/`category_summary`/`category` 分组 |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

---

### 3. SLS Penetration — O2O销售渗透率

| 项目 | 内容 |
|---|---|
| **指标名称** | SLS Penetration |
| **指标名称中文** | O2O销售渗透率 |
| **业务定义** | O2O出库订单销售额占线上总销售额的比例 by label/product type/category/subcategory 拆分统计 |
| **计算公式** | sum(o2o_sales_amt) / sum(sales_amt) |
| **分子** | `o2o_sales_amt` |
| **分母** | `sales_amt` |
| **数据底表** | `a02_e2e_boss_performance_summary_d` |
| **筛选条件** | `calc_type = payment`，按 `brand`/`product_type`/`category_summary`/`category` 分组 |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

### 3.1 SLS Penetration LY — O2O销售渗透率（对比去年同期）

| 项目 | 内容 |
|---|---|
| **指标名称** | SLS Penetration LY |
| **指标名称中文** | O2O销售渗透率（对比去年同期） |
| **业务定义** | 取去年同期O2O销售渗透率 |
| **计算公式** | 去年同期 sum(o2o_sales_amt) / sum(sales_amt) |
| **数据底表** | `a02_e2e_boss_performance_summary_d` |
| **筛选条件** | `calc_type = payment`，按 `brand`/`product_type`/`category_summary`/`category` 分组，取去年同期 |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

### 3.2 SLS Penetration vs LY — O2O销售渗透率同比

| 项目 | 内容 |
|---|---|
| **指标名称** | SLS Penetration vs LY |
| **指标名称中文** | O2O销售渗透率同比 |
| **业务定义** | O2O销售渗透率今年较去年同期的变化率 |
| **计算公式** | 今年 − 去年（差值，bp 指标，展示时 ×100 转 bp） |
| **数据底表** | `a02_e2e_boss_performance_summary_d` |
| **筛选条件** | `calc_type = payment`，按 `brand`/`product_type`/`category_summary`/`category` 分组 |
| **数据类型** | delta_bp → 增减基点整数： → +120bp / -80bp（基点，含正负号，值×100 转 bp）, 乘以100的操作可以放在 Cell Display 度量中实现，算同比：当期值 − 同期值（差值，bp 指标，展示时 ×100 转 bp） |
| **数据格式** | `+#,##0bp;-#,##0bp;0bp` |

---

### 4. Avg. No. of Store Passed Before Order Got Accepted — O2O平均订单流转次数

| 项目 | 内容 |
|---|---|
| **指标名称** | Avg. No. of Store Passed Before Order Got Accepted |
| **指标名称中文** | O2O平均订单流转次数 |
| **业务定义** | 根据订单付款时间，统计订单在系统中出现的次数（统计配货成功和配货失败的订单）by label/product type/category/subcategory 拆分统计 |
| **计算公式** | sum(o2o_fulfillment_request_times) / sum(o2o_fulfillment_request_sku_qty) |
| **分子** | `o2o_fulfillment_request_times` |
| **分母** | `o2o_fulfillment_request_sku_qty` |
| **数据底表** | `a02_e2e_boss_fulfillment_request_data_d` |
| **筛选条件** | `calc_type = fulfillment`，按 `brand`/`product_type`/`category_summary`/`category` 分组（`brand` 行支持展开到 `product_type` → `category_summary` → `category`） |
| **数据类型** | decimal_1dp → 小数，保留一位小数，千分位 |
| **数据格式** | `#,##0.0` |

---

### 5. Avg. Processing Time(Hour) — O2O平均订单流转时长

| 项目 | 内容 |
|---|---|
| **指标名称** | Avg. Processing Time(Hour) |
| **指标名称中文** | O2O平均订单流转时长 |
| **业务定义** | 剔除换货的订单，根据订单的付款时间和订单最后一次配货失败/配货完成的时间，统计订单商品的平均流转时长（统计配货成功和配货失败的订单）by label/product type/category/subcategory 拆分统计 |
| **计算公式** | sum(o2o_fulfillment_request_duration) / sum(o2o_fulfillment_request_sku_qty) |
| **分子** | `o2o_fulfillment_request_duration` |
| **分母** | `o2o_fulfillment_request_sku_qty` |
| **数据底表** | `a02_e2e_boss_fulfillment_request_data_d` |
| **筛选条件** | `calc_type = fulfillment`，按 `brand`/`product_type`/`category_summary`/`category` 分组 |
| **数据类型** | decimal_1dp → 小数，保留一位小数，千分位 |
| **数据格式** | `#,##0.0` |

---

### 6. Fulfillment% — O2O订单履约率

| 项目 | 内容 |
|---|---|
| **指标名称** | Fulfillment% |
| **指标名称中文** | O2O订单履约率 |
| **业务定义** | 订单类型属于门店发货和门店自提，根据订单付款时间，实际发货的订单数量占客户请求门店的总订单数量的比例 by label/product type/category/subcategory 拆分统计 |
| **计算公式** | sum(o2o_fulfillment_shipped_order_cnt) / sum(o2o_fulfillment_request_order_cnt) |
| **分子** | `o2o_fulfillment_shipped_order_cnt` |
| **分母** | `o2o_fulfillment_request_order_cnt` |
| **数据底表** | `a02_e2e_boss_performance_summary_d` |
| **筛选条件** | `calc_type = fulfillment`，按 `brand`/`product_type`/`category_summary`/`category` 分组 |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

### 6.1 Fulfillment% LY — O2O订单履约率（对比去年同期）

| 项目 | 内容 |
|---|---|
| **指标名称** | Fulfillment% LY |
| **指标名称中文** | O2O订单履约率（对比去年同期） |
| **业务定义** | 取去年同期O2O订单履约率 |
| **计算公式** | 去年同期 sum(o2o_fulfillment_shipped_order_cnt) / sum(o2o_fulfillment_request_order_cnt) |
| **数据底表** | `a02_e2e_boss_performance_summary_d` |
| **筛选条件** | `calc_type = fulfillment`，按 `brand`/`product_type`/`category_summary`/`category` 分组，取去年同期 |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

### 6.2 Fulfillment% vs LY — O2O订单履约率同比

| 项目 | 内容 |
|---|---|
| **指标名称** | Fulfillment% vs LY |
| **指标名称中文** | O2O订单履约率同比 |
| **业务定义** | O2O订单履约率今年较去年同期的变化率 |
| **计算公式** | 今年 − 去年（差值，bp 指标，展示时 ×100 转 bp） |
| **数据底表** | `a02_e2e_boss_performance_summary_d` |
| **筛选条件** | `calc_type = fulfillment`，按 `brand`/`product_type`/`category_summary`/`category` 分组 |
| **数据类型** | delta_bp → 增减基点整数： → +120bp / -80bp（基点，含正负号，值×100 转 bp）, 乘以100的操作可以放在 Cell Display 度量中实现，算同比：当期值 − 同期值（差值，bp 指标，展示时 ×100 转 bp） |
| **数据格式** | `+#,##0bp;-#,##0bp;0bp` |

---

### 7. Request Order Qty — O2O销售订单量

| 项目 | 内容 |
|---|---|
| **指标名称** | Request Order Qty |
| **指标名称中文** | O2O销售订单量 |
| **业务定义** | 订单类型属于门店发货和门店自提，根据订单付款时间，所有配货状态（配货状态为待接单、已配货、配货失败、新建等中间状态）的订单量 by label/product type/category/subcategory 拆分统计 |
| **计算公式** | sum(o2o_fulfillment_request_order_cnt) |
| **统计字段** | `o2o_fulfillment_request_order_cnt` |
| **数据底表** | `a02_e2e_boss_performance_summary_d` |
| **筛选条件** | `calc_type = fulfillment`，按 `brand`/`product_type`/`category_summary`/`category` 分组 |
| **数据类型** | integer → 整数，千分位整数 |
| **数据格式** | `#,##0` |

### 7.1 Request Order Qty LY — O2O销售订单量（对比去年同期）

| 项目 | 内容 |
|---|---|
| **指标名称** | Request Order Qty LY |
| **指标名称中文** | O2O销售订单量（对比去年同期） |
| **业务定义** | 取去年同期O2O销售订单量 |
| **计算公式** | 去年同期 sum(o2o_fulfillment_request_order_cnt) |
| **数据底表** | `a02_e2e_boss_performance_summary_d` |
| **筛选条件** | `calc_type = fulfillment`，按 `brand`/`product_type`/`category_summary`/`category` 分组，取去年同期 |
| **数据类型** | integer → 整数，千分位整数 |
| **数据格式** | `#,##0` |

### 7.2 Request Order Qty vs LY — O2O销售订单量同比

| 项目 | 内容 |
|---|---|
| **指标名称** | Request Order Qty vs LY |
| **指标名称中文** | O2O销售订单量同比 |
| **业务定义** | O2O销售订单量今年较去年同期的变化率 |
| **计算公式** | 今年 / 去年 − 1 |
| **数据底表** | `a02_e2e_boss_performance_summary_d` |
| **筛选条件** | `calc_type = fulfillment`，按 `brand`/`product_type`/`category_summary`/`category` 分组 |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

---

### 8. Request Units — O2O商品销售件数

| 项目 | 内容 |
|---|---|
| **指标名称** | Request Units |
| **指标名称中文** | O2O商品销售件数 |
| **业务定义** | 订单类型属于门店发货和门店自提，根据订单付款时间，所有配货状态（配货状态为待接单、已配货、配货失败、新建等中间状态）的商品数 by label/product type/category/subcategory 拆分统计 |
| **计算公式** | sum(o2o_fulfillment_request_qty) |
| **统计字段** | `o2o_fulfillment_request_qty` |
| **数据底表** | `a02_e2e_boss_performance_summary_d` |
| **筛选条件** | `calc_type = fulfillment`，按 `brand`/`product_type`/`category_summary`/`category` 分组 |
| **数据类型** | integer → 整数，千分位整数 |
| **数据格式** | `#,##0` |

### 8.1 Request Units LY — O2O商品销售件数（对比去年同期）

| 项目 | 内容 |
|---|---|
| **指标名称** | Request Units LY |
| **指标名称中文** | O2O商品销售件数（对比去年同期） |
| **业务定义** | 取去年同期O2O商品销售件数 |
| **计算公式** | 去年同期 sum(o2o_fulfillment_request_qty) |
| **数据底表** | `a02_e2e_boss_performance_summary_d` |
| **筛选条件** | `calc_type = fulfillment`，按 `brand`/`product_type`/`category_summary`/`category` 分组，取去年同期 |
| **数据类型** | integer → 整数，千分位整数 |
| **数据格式** | `#,##0` |

### 8.2 Request Units vs LY — O2O商品销售件数同比

| 项目 | 内容 |
|---|---|
| **指标名称** | Request Units vs LY |
| **指标名称中文** | O2O商品销售件数同比 |
| **业务定义** | O2O商品销售件数今年较去年同期的变化率 |
| **计算公式** | 今年 / 去年 − 1 |
| **数据底表** | `a02_e2e_boss_performance_summary_d` |
| **筛选条件** | `calc_type = fulfillment`，按 `brand`/`product_type`/`category_summary`/`category` 分组 |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

---

### 9. Request Order Amt — O2O销售金额

| 项目 | 内容 |
|---|---|
| **指标名称** | Request Order Amt |
| **指标名称中文** | O2O销售金额 |
| **业务定义** | 订单类型属于门店发货和门店自提，根据订单付款时间，所有配货状态（配货状态为待接单、已配货、配货失败、新建等中间状态）的订单金额 by label/product type/category/subcategory 拆分统计 |
| **计算公式** | sum(o2o_fulfillment_request_sales_amt) |
| **统计字段** | `o2o_fulfillment_request_sales_amt` |
| **数据底表** | `a02_e2e_boss_performance_summary_d` |
| **筛选条件** | `calc_type = fulfillment`，按 `brand`/`product_type`/`category_summary`/`category` 分组 |
| **数据类型** | currency → 货币符号由币种切片器决定，千分位整数 |
| **数据格式** | `#,##0`（在 DAX 中用 `__CurrencySymbol & FORMAT(__Value, "#,##0")` 拼接币种符号） |

### 9.1 Request Order Amt LY — O2O销售金额（对比去年同期）

| 项目 | 内容 |
|---|---|
| **指标名称** | Request Order Amt LY |
| **指标名称中文** | O2O销售金额（对比去年同期） |
| **业务定义** | 取去年同期O2O销售金额 |
| **计算公式** | 去年同期 sum(o2o_fulfillment_request_sales_amt) |
| **数据底表** | `a02_e2e_boss_performance_summary_d` |
| **筛选条件** | `calc_type = fulfillment`，按 `brand`/`product_type`/`category_summary`/`category` 分组，取去年同期 |
| **数据类型** | currency → 货币符号由币种切片器决定，千分位整数 |
| **数据格式** | `#,##0`（在 DAX 中用 `__CurrencySymbol & FORMAT(__Value, "#,##0")` 拼接币种符号） |

### 9.2 Request Order Amt vs LY — O2O销售金额同比

| 项目 | 内容 |
|---|---|
| **指标名称** | Request Order Amt vs LY |
| **指标名称中文** | O2O销售金额同比 |
| **业务定义** | O2O销售金额今年较去年同期的变化率 |
| **计算公式** | 今年 / 去年 − 1 |
| **数据底表** | `a02_e2e_boss_performance_summary_d` |
| **筛选条件** | `calc_type = fulfillment`，按 `brand`/`product_type`/`category_summary`/`category` 分组 |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

---

### 10. Shipped Order Qty — O2O已配货订单量

| 项目 | 内容 |
|---|---|
| **指标名称** | Shipped Order Qty |
| **指标名称中文** | O2O已配货订单量 |
| **业务定义** | 订单类型属于门店发货和门店自提，根据订单付款时间，配货状态是已配货的订单量 by label/product type/category/subcategory 拆分统计 |
| **计算公式** | sum(o2o_fulfillment_shipped_order_cnt) |
| **统计字段** | `o2o_fulfillment_shipped_order_cnt` |
| **数据底表** | `a02_e2e_boss_performance_summary_d` |
| **筛选条件** | `calc_type = fulfillment`，按 `brand`/`product_type`/`category_summary`/`category` 分组 |
| **数据类型** | integer → 整数，千分位整数 |
| **数据格式** | `#,##0` |

### 10.1 Shipped Order Qty LY — O2O已配货订单量（对比去年同期）

| 项目 | 内容 |
|---|---|
| **指标名称** | Shipped Order Qty LY |
| **指标名称中文** | O2O已配货订单量（对比去年同期） |
| **业务定义** | 取去年同期O2O已配货订单量 |
| **计算公式** | 去年同期 sum(o2o_fulfillment_shipped_order_cnt) |
| **数据底表** | `a02_e2e_boss_performance_summary_d` |
| **筛选条件** | `calc_type = fulfillment`，按 `brand`/`product_type`/`category_summary`/`category` 分组，取去年同期 |
| **数据类型** | integer → 整数，千分位整数 |
| **数据格式** | `#,##0` |

### 10.2 Shipped Order Qty vs LY — O2O已配货订单量同比

| 项目 | 内容 |
|---|---|
| **指标名称** | Shipped Order Qty vs LY |
| **指标名称中文** | O2O已配货订单量同比 |
| **业务定义** | O2O已配货订单量今年较去年同期的变化率 |
| **计算公式** | 今年 / 去年 − 1 |
| **数据底表** | `a02_e2e_boss_performance_summary_d` |
| **筛选条件** | `calc_type = fulfillment`，按 `brand`/`product_type`/`category_summary`/`category` 分组 |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

---

### 11. Shipped Units — O2O已配货商品件数

| 项目 | 内容 |
|---|---|
| **指标名称** | Shipped Units |
| **指标名称中文** | O2O已配货商品件数 |
| **业务定义** | 订单类型属于门店发货和门店自提，根据订单付款时间，配货状态是已配货的商品数 by label/product type/category/subcategory 拆分统计 |
| **计算公式** | sum(o2o_fulfillment_shipped_qty) |
| **统计字段** | `o2o_fulfillment_shipped_qty` |
| **数据底表** | `a02_e2e_boss_performance_summary_d` |
| **筛选条件** | `calc_type = fulfillment`，按 `brand`/`product_type`/`category_summary`/`category` 分组 |
| **数据类型** | integer → 整数，千分位整数 |
| **数据格式** | `#,##0` |

### 11.1 Shipped Units LY — O2O已配货商品件数（对比去年同期）

| 项目 | 内容 |
|---|---|
| **指标名称** | Shipped Units LY |
| **指标名称中文** | O2O已配货商品件数（对比去年同期） |
| **业务定义** | 取去年同期O2O已配货商品件数 |
| **计算公式** | 去年同期 sum(o2o_fulfillment_shipped_qty) |
| **数据底表** | `a02_e2e_boss_performance_summary_d` |
| **筛选条件** | `calc_type = fulfillment`，按 `brand`/`product_type`/`category_summary`/`category` 分组，取去年同期 |
| **数据类型** | integer → 整数，千分位整数 |
| **数据格式** | `#,##0` |

### 11.2 Shipped Units vs LY — O2O已配货商品件数同比

| 项目 | 内容 |
|---|---|
| **指标名称** | Shipped Units vs LY |
| **指标名称中文** | O2O已配货商品件数同比 |
| **业务定义** | O2O已配货商品件数今年较去年同期的变化率 |
| **计算公式** | 今年 / 去年 − 1 |
| **数据底表** | `a02_e2e_boss_performance_summary_d` |
| **筛选条件** | `calc_type = fulfillment`，按 `brand`/`product_type`/`category_summary`/`category` 分组 |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

---

### 12. Shipped Order Amt — O2O已配货销售金额

| 项目 | 内容 |
|---|---|
| **指标名称** | Shipped Order Amt |
| **指标名称中文** | O2O已配货销售金额 |
| **业务定义** | 订单类型属于门店发货和门店自提，根据订单付款时间，配货状态是已配货的订单金额 by label/product type/category/subcategory 拆分统计 |
| **计算公式** | sum(o2o_fulfillment_shipped_sales_amt) |
| **统计字段** | `o2o_fulfillment_shipped_sales_amt` |
| **数据底表** | `a02_e2e_boss_performance_summary_d` |
| **筛选条件** | `calc_type = fulfillment`，按 `brand`/`product_type`/`category_summary`/`category` 分组 |
| **数据类型** | currency → 货币符号由币种切片器决定，千分位整数 |
| **数据格式** | `#,##0`（在 DAX 中用 `__CurrencySymbol & FORMAT(__Value, "#,##0")` 拼接币种符号） |

### 12.1 Shipped Order Amt LY — O2O已配货销售金额（对比去年同期）

| 项目 | 内容 |
|---|---|
| **指标名称** | Shipped Order Amt LY |
| **指标名称中文** | O2O已配货销售金额（对比去年同期） |
| **业务定义** | 取去年同期O2O已配货销售金额 |
| **计算公式** | 去年同期 sum(o2o_fulfillment_shipped_sales_amt) |
| **数据底表** | `a02_e2e_boss_performance_summary_d` |
| **筛选条件** | `calc_type = fulfillment`，按 `brand`/`product_type`/`category_summary`/`category` 分组，取去年同期 |
| **数据类型** | currency → 货币符号由币种切片器决定，千分位整数 |
| **数据格式** | `#,##0`（在 DAX 中用 `__CurrencySymbol & FORMAT(__Value, "#,##0")` 拼接币种符号） |

### 12.2 Shipped Order Amt vs LY — O2O已配货销售金额同比

| 项目 | 内容 |
|---|---|
| **指标名称** | Shipped Order Amt vs LY |
| **指标名称中文** | O2O已配货销售金额同比 |
| **业务定义** | O2O已配货销售金额今年较去年同期的变化率 |
| **计算公式** | 今年 / 去年 − 1 |
| **数据底表** | `a02_e2e_boss_performance_summary_d` |
| **筛选条件** | `calc_type = fulfillment`，按 `brand`/`product_type`/`category_summary`/`category` 分组 |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

---

### 13. Unfulfillment% — O2O订单未履约率

| 项目 | 内容 |
|---|---|
| **指标名称** | Unfulfillment% |
| **指标名称中文** | O2O订单未履约率 |
| **业务定义** | 根据订单付款时间，统计订单维度，配货失败的订单数量占客户提交的总订单数量的比例 by label/product type/category/subcategory 拆分统计 |
| **计算公式** | sum(o2o_fulfillment_unshipped_order_cnt) / sum(o2o_fulfillment_request_order_cnt) |
| **分子** | `o2o_fulfillment_unshipped_order_cnt` |
| **分母** | `o2o_fulfillment_request_order_cnt` |
| **数据底表** | `a02_e2e_boss_performance_summary_d` |
| **筛选条件** | `calc_type = fulfillment`，按 `brand`/`product_type`/`category_summary`/`category` 分组 |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

### 13.1 Unfulfillment% LY — O2O订单未履约率（对比去年同期）

| 项目 | 内容 |
|---|---|
| **指标名称** | Unfulfillment% LY |
| **指标名称中文** | O2O订单未履约率（对比去年同期） |
| **业务定义** | 取去年同期O2O订单未履约率 |
| **计算公式** | 去年同期 sum(o2o_fulfillment_unshipped_order_cnt) / sum(o2o_fulfillment_request_order_cnt) |
| **数据底表** | `a02_e2e_boss_performance_summary_d` |
| **筛选条件** | `calc_type = fulfillment`，按 `brand`/`product_type`/`category_summary`/`category` 分组，取去年同期 |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

### 13.2 Unfulfillment% vs LY — O2O订单未履约率同比

| 项目 | 内容 |
|---|---|
| **指标名称** | Unfulfillment% vs LY |
| **指标名称中文** | O2O订单未履约率同比 |
| **业务定义** | O2O订单未履约率今年较去年同期的变化率 |
| **计算公式** | 今年 − 去年（差值，bp 指标，展示时 ×100 转 bp） |
| **数据底表** | `a02_e2e_boss_performance_summary_d` |
| **筛选条件** | `calc_type = fulfillment`，按 `brand`/`product_type`/`category_summary`/`category` 分组 |
| **数据类型** | delta_bp → 增减基点整数： → +120bp / -80bp（基点，含正负号，值×100 转 bp）, 乘以100的操作可以放在 Cell Display 度量中实现，算同比：当期值 − 同期值（差值，bp 指标，展示时 ×100 转 bp） |
| **数据格式** | `+#,##0bp;-#,##0bp;0bp` |

---

### 14. Unfulfilled Order — O2O失败订单数

| 项目 | 内容 |
|---|---|
| **指标名称** | Unfulfilled Order |
| **指标名称中文** | O2O失败订单数 |
| **业务定义** | 订单维度去重统计，根据订单付款时间，统计配货状态是配货失败的订单量 by label/product type/category/subcategory 拆分统计 |
| **计算公式** | sum(o2o_fulfillment_unshipped_order_cnt) |
| **统计字段** | `o2o_fulfillment_unshipped_order_cnt` |
| **数据底表** | `a02_e2e_boss_performance_summary_d` |
| **筛选条件** | `calc_type = fulfillment`，按 `brand`/`product_type`/`category_summary`/`category` 分组 |
| **数据类型** | integer → 整数，千分位整数 |
| **数据格式** | `#,##0` |

### 14.1 Unfulfilled Order LY — O2O失败订单数（对比去年同期）

| 项目 | 内容 |
|---|---|
| **指标名称** | Unfulfilled Order LY |
| **指标名称中文** | O2O失败订单数（对比去年同期） |
| **业务定义** | 取去年同期O2O失败订单数 |
| **计算公式** | 去年同期 sum(o2o_fulfillment_unshipped_order_cnt) |
| **数据底表** | `a02_e2e_boss_performance_summary_d` |
| **筛选条件** | `calc_type = fulfillment`，按 `brand`/`product_type`/`category_summary`/`category` 分组，取去年同期 |
| **数据类型** | integer → 整数，千分位整数 |
| **数据格式** | `#,##0` |

### 14.2 Unfulfilled Order vs LY — O2O失败订单数同比

| 项目 | 内容 |
|---|---|
| **指标名称** | Unfulfilled Order vs LY |
| **指标名称中文** | O2O失败订单数同比 |
| **业务定义** | O2O失败订单数今年较去年同期的变化率 |
| **计算公式** | 今年 / 去年 − 1 |
| **数据底表** | `a02_e2e_boss_performance_summary_d` |
| **筛选条件** | `calc_type = fulfillment`，按 `brand`/`product_type`/`category_summary`/`category` 分组 |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

---

### 15. Unfulfilled Units — O2O失败订单商品件数

| 项目 | 内容 |
|---|---|
| **指标名称** | Unfulfilled Units |
| **指标名称中文** | O2O失败订单商品件数 |
| **业务定义** | 订单维度去重统计，根据订单付款时间，统计配货状态是配货失败的商品件数 by label/product type/category/subcategory 拆分统计 |
| **计算公式** | sum(o2o_fulfillment_unshipped_qty) |
| **统计字段** | `o2o_fulfillment_unshipped_qty` |
| **数据底表** | `a02_e2e_boss_performance_summary_d` |
| **筛选条件** | `calc_type = fulfillment`，按 `brand`/`product_type`/`category_summary`/`category` 分组 |
| **数据类型** | integer → 整数，千分位整数 |
| **数据格式** | `#,##0` |

### 15.1 Unfulfilled Units LY — O2O失败订单商品件数（对比去年同期）

| 项目 | 内容 |
|---|---|
| **指标名称** | Unfulfilled Units LY |
| **指标名称中文** | O2O失败订单商品件数（对比去年同期） |
| **业务定义** | 取去年同期O2O失败订单商品件数 |
| **计算公式** | 去年同期 sum(o2o_fulfillment_unshipped_qty) |
| **数据底表** | `a02_e2e_boss_performance_summary_d` |
| **筛选条件** | `calc_type = fulfillment`，按 `brand`/`product_type`/`category_summary`/`category` 分组，取去年同期 |
| **数据类型** | integer → 整数，千分位整数 |
| **数据格式** | `#,##0` |

### 15.2 Unfulfilled Units vs LY — O2O失败订单商品件数同比

| 项目 | 内容 |
|---|---|
| **指标名称** | Unfulfilled Units vs LY |
| **指标名称中文** | O2O失败订单商品件数同比 |
| **业务定义** | O2O失败订单商品件数今年较去年同期的变化率 |
| **计算公式** | 今年 / 去年 − 1 |
| **数据底表** | `a02_e2e_boss_performance_summary_d` |
| **筛选条件** | `calc_type = fulfillment`，按 `brand`/`product_type`/`category_summary`/`category` 分组 |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

---

### 16. Unfulfilled Amt — O2O失败订单销售金额

| 项目 | 内容 |
|---|---|
| **指标名称** | Unfulfilled Amt |
| **指标名称中文** | O2O失败订单销售金额 |
| **业务定义** | 订单维度去重统计，根据订单付款时间，统计配货状态是配货失败的销售金额 by label/product type/category/subcategory 拆分统计 |
| **计算公式** | sum(o2o_fulfillment_unshipped_sales_amt) |
| **统计字段** | `o2o_fulfillment_unshipped_sales_amt` |
| **数据底表** | `a02_e2e_boss_performance_summary_d` |
| **筛选条件** | `calc_type = fulfillment`，按 `brand`/`product_type`/`category_summary`/`category` 分组 |
| **数据类型** | currency → 货币符号由币种切片器决定，千分位整数 |
| **数据格式** | `#,##0`（在 DAX 中用 `__CurrencySymbol & FORMAT(__Value, "#,##0")` 拼接币种符号） |

### 16.1 Unfulfilled Amt LY — O2O失败订单销售金额（对比去年同期）

| 项目 | 内容 |
|---|---|
| **指标名称** | Unfulfilled Amt LY |
| **指标名称中文** | O2O失败订单销售金额（对比去年同期） |
| **业务定义** | 取去年同期O2O失败订单销售金额 |
| **计算公式** | 去年同期 sum(o2o_fulfillment_unshipped_sales_amt) |
| **数据底表** | `a02_e2e_boss_performance_summary_d` |
| **筛选条件** | `calc_type = fulfillment`，按 `brand`/`product_type`/`category_summary`/`category` 分组，取去年同期 |
| **数据类型** | currency → 货币符号由币种切片器决定，千分位整数 |
| **数据格式** | `#,##0`（在 DAX 中用 `__CurrencySymbol & FORMAT(__Value, "#,##0")` 拼接币种符号） |

### 16.2 Unfulfilled Amt vs LY — O2O失败订单销售金额同比

| 项目 | 内容 |
|---|---|
| **指标名称** | Unfulfilled Amt vs LY |
| **指标名称中文** | O2O失败订单销售金额同比 |
| **业务定义** | O2O失败订单销售金额今年较去年同期的变化率 |
| **计算公式** | 今年 / 去年 − 1 |
| **数据底表** | `a02_e2e_boss_performance_summary_d` |
| **筛选条件** | `calc_type = fulfillment`，按 `brand`/`product_type`/`category_summary`/`category` 分组 |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

---

### 17. Product Volume — SKU商品的数量

| 项目 | 内容 |
|---|---|
| **指标名称** | Product Volume |
| **指标名称中文** | SKU商品的数量 |
| **业务定义** | 在售卖的 sku 商品数量 by label/product type/category/subcategory 拆分统计 |
| **计算公式** | sum(stock_qty) + sum(o2o_fulfillment_shipped_qty) |
| **统计字段** | `stock_qty`（库存需要根据筛选日期，只要最后一天的数据）+ `o2o_fulfillment_shipped_qty`（销量整个筛选周期的数据聚合） |
| **数据底表** | `a02_e2e_boss_performance_summary_d` |
| **筛选条件** | `calc_type = fulfillment`，按 `brand` 分组（`brand` 行支持展开到 `product_type` → `category_summary` → `category`） |
| **聚合粒度** | 根据所选时间范围 `data_date`，聚合在 `brand` 粒度；库存：sum(stock_qty)【看所选时间范围的库存】；销量：sum(o2o_fulfillment_shipped_qty)【看所有时间范围的】 |
| **数据类型** | integer → 整数，千分位整数 |
| **数据格式** | `#,##0` |

---

## 通用规则汇总

| 规则项 | 说明 |
|---|---|
| **数据底表** | `a02_e2e_boss_performance_summary_d`、`a02_e2e_boss_fulfillment_request_data_d` |
| **筛选逻辑** | 统一包含 `calc_type = payment` 或 `calc_type = fulfillment`；M/W POLO 子板块需追加 `brand in ("W Polo", "M Polo")` |
| **货币转换规则** | 数据源默认为 RMB，转化为美元需要除以固定值 7 |
| **派生指标** | LY（去年同期）、vs LY（同比）、占比等为派生指标，依据基础指标计算生成；vs LY 同比口径统一为 `今年 / 去年 − 1`（金额/数量类）或 `今年 − 去年`（差值，bp 指标，展示时 ×100 转 bp，仅用于率类指标） |
| **分组维度** | 根据 `brand`、`product_type`、`category_summary`、`category` 分组；`brand` 粒度行支持展开看 `product_type` → `category_summary` → `category` 粒度明细数据 |
| **必须遵守** | 口径文档中定义的所有指标，必须遵守其数据类型和数据格式，如果和解决方案中存在争议的，一切以口径文档为准，必须按照口径文档中的格式进行调整 |
| **DAX 语法规范** | 文本常量必须使用双引号 `" "`，禁止使用单引号；单引号 `' '` 仅用于表名，列名使用方括号 `[ ]`，例如：`[calc_type] = "payment"` |
