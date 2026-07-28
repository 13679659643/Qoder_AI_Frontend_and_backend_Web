# BOSS Performance Dashboard 指标口径提示词

> **Dashboard**: BOSS Performance Dashboard  
> **Tab**: Overview  
> **数据底表**: `a02_e2e_boss_performance_summary_d` / `a02_e2e_boss_fulfillment_request_data_d`  
> **模块说明**: 本板块为 BOSS 核心绩效看板，覆盖 BOSS Core KPI、Demand SLS by Platform、Demand SLS by Division、SLS Penetration Trend、Fulfillment% by Label、Order Processing Efficiency by Label、Penalty by Platform 七个子板块，统计O2O销售净额、退前销售额、履约情况及订单处理效率等。

---

## 全局逻辑

| 项目 | 内容 |
|---|---|
| **数据底表** | `a02_e2e_boss_performance_summary_d`、`a02_e2e_boss_fulfillment_request_data_d` |
| **筛选逻辑** | 按各指标定义区分 `calc_type = payment` 或 `calc_type = fulfillment` |
| **聚合粒度** | 数字卡片：所选时间范围 `data_date`；表格：所选时间范围 `data_date`，按对应维度聚合 |
| **货币转换规则** | 数据源默认为 RMB，转化为美元需要除以固定值 7 |
| **派生指标** | LY（去年同期）、vs LY（同比）、占比等附属指标为派生指标，依据基础指标计算生成 |
| **必须遵守** | 口径文档中定义的所有指标，必须遵守其数据类型和数据格式，如果和解决方案中存在争议的，一切以口径文档为准，必须按照口径文档中的格式进行调整 |

---

## 子模块一：BOSS Core KPI

> **无分组维度**: 只受到筛选器影响，没有分组维度，用于制作卡片图。

### 1. SLS — O2O销售净额

| 项目 | 内容 |
|---|---|
| **指标名称** | SLS |
| **指标名称中文** | O2O销售净额 |
| **业务定义** | 订单类型属于门店发货和门店自提，BI中退货入库金额+销售出库金额, 统计时间为出入库时间 |
| **计算公式** | sum(o2o_net_sales_amt) |
| **统计字段** | `o2o_net_sales_amt` |
| **数据底表** | `a02_e2e_boss_performance_summary_d` |
| **筛选条件** | `calc_type = payment` |
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
| **筛选条件** | `calc_type = payment`，取去年同期 |
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
| **筛选条件** | `calc_type = payment` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%;#,##0.0%;0.0%` |

---

### 2. Demand SLS — O2O退前销售额

| 项目 | 内容 |
|---|---|
| **指标名称** | Demand SLS |
| **指标名称中文** | O2O退前销售额 |
| **业务定义** | O2O退前销售额（平台付款时间维度GMV数据） |
| **计算公式** | sum(o2o_sales_amt) |
| **统计字段** | `o2o_sales_amt` |
| **数据底表** | `a02_e2e_boss_performance_summary_d` |
| **筛选条件** | `calc_type = payment` |
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
| **筛选条件** | `calc_type = payment`，取去年同期 |
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
| **筛选条件** | `calc_type = payment` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%;#,##0.0%;0.0%` |

---

### 3. SLS Penetration — O2O销售渗透率

| 项目 | 内容 |
|---|---|
| **指标名称** | SLS Penetration |
| **指标名称中文** | O2O销售渗透率 |
| **业务定义** | O2O出库订单销售额占线上总销售额的比例 |
| **计算公式** | sum(o2o_sales_amt) / sum(sales_amt) |
| **分子** | `o2o_sales_amt` |
| **分母** | `sales_amt` |
| **数据底表** | `a02_e2e_boss_performance_summary_d` |
| **筛选条件** | `calc_type = payment` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%;#,##0.0%;0.0%` |

### 3.1 SLS Penetration LY — O2O销售渗透率（对比去年同期）

| 项目 | 内容 |
|---|---|
| **指标名称** | SLS Penetration LY |
| **指标名称中文** | O2O销售渗透率（对比去年同期） |
| **业务定义** | 取去年同期O2O销售渗透率 |
| **计算公式** | 去年同期 sum(o2o_sales_amt) / sum(sales_amt) |
| **数据底表** | `a02_e2e_boss_performance_summary_d` |
| **筛选条件** | `calc_type = payment`，取去年同期 |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%;#,##0.0%;0.0%` |

### 3.2 SLS Penetration vs LY — O2O销售渗透率同比

| 项目 | 内容 |
|---|---|
| **指标名称** | SLS Penetration vs LY |
| **指标名称中文** | O2O销售渗透率同比 |
| **业务定义** | O2O销售渗透率今年较去年同期的变化率 |
| **计算公式** | 今年 / 去年 |
| **数据底表** | `a02_e2e_boss_performance_summary_d` |
| **筛选条件** | `calc_type = payment` |
| **数据类型** | delta_bp → 增减基点整数： → +120bp / -80bp（基点，含正负号，值×100 转 bp）,乘以100的操作可以放在Cell Display度量中实现，算同比：当期值 − 同期值（差值，bp 指标，展示时 ×100 转 bp） |        
| **数据格式** | `+#,##0bp;-#,##0bp;0bp` |

---

### 4. Return — O2O退货金额

| 项目 | 内容 |
|---|---|
| **指标名称** | Return |
| **指标名称中文** | O2O退货金额 |
| **业务定义** | 订单类型属于门店发货和门店自提的退货入库金额, 包含门店发货后退货到EC仓的入库金额，统计时间为出入库时间 |
| **计算公式** | sum(o2o_return_amt) |
| **统计字段** | `o2o_return_amt` |
| **数据底表** | `a02_e2e_boss_performance_summary_d` |
| **筛选条件** | `calc_type = payment` |
| **数据类型** | currency → 货币符号由币种切片器决定，千分位整数 |
| **数据格式** | `#,##0`（在 DAX 中用 `__CurrencySymbol & FORMAT(__Value, "#,##0")` 拼接币种符号） |

### 4.1 Return LY — O2O退货金额（对比去年同期）

| 项目 | 内容 |
|---|---|
| **指标名称** | Return LY |
| **指标名称中文** | O2O退货金额（对比去年同期） |
| **业务定义** | 取去年同期O2O退货金额 |
| **计算公式** | 去年同期 sum(o2o_return_amt) |
| **数据底表** | `a02_e2e_boss_performance_summary_d` |
| **筛选条件** | `calc_type = payment`，取去年同期 |
| **数据类型** | currency → 货币符号由币种切片器决定，千分位整数 |
| **数据格式** | `#,##0`（在 DAX 中用 `__CurrencySymbol & FORMAT(__Value, "#,##0")` 拼接币种符号） |

### 4.2 Return vs LY — O2O退货金额同比

| 项目 | 内容 |
|---|---|
| **指标名称** | Return vs LY |
| **指标名称中文** | O2O退货金额同比 |
| **业务定义** | O2O退货金额今年较去年同期的变化率 |
| **计算公式** | 今年 / 去年 − 1 |
| **数据底表** | `a02_e2e_boss_performance_summary_d` |
| **筛选条件** | `calc_type = payment` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%;#,##0.0%;0.0%` |

---

### 5. Return% — O2O退货率（金额）

| 项目 | 内容 |
|---|---|
| **指标名称** | Return% |
| **指标名称中文** | O2O退货率（金额） |
| **业务定义** | 订单类型属于门店发货和门店自提的退货入库订单，退货入库/销售出库，以金额计算 |
| **计算公式** | sum(o2o_return_amt) / sum(o2o_sales_amt) |
| **分子** | `o2o_return_amt` |
| **分母** | `o2o_sales_amt` |
| **数据底表** | `a02_e2e_boss_performance_summary_d` |
| **筛选条件** | `calc_type = payment` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%;#,##0.0%;0.0%` |

### 5.1 Return% LY — O2O退货率（金额）（对比去年同期）

| 项目 | 内容 |
|---|---|
| **指标名称** | Return% LY |
| **指标名称中文** | O2O退货率（金额）（对比去年同期） |
| **业务定义** | 取去年同期O2O退货率（金额） |
| **计算公式** | 去年同期 sum(o2o_return_amt) / sum(o2o_sales_amt) |
| **数据底表** | `a02_e2e_boss_performance_summary_d` |
| **筛选条件** | `calc_type = payment`，取去年同期 |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%;#,##0.0%;0.0%` |

### 5.2 Return% vs LY — O2O退货率（金额）同比

| 项目 | 内容 |
|---|---|
| **指标名称** | Return% vs LY |
| **指标名称中文** | O2O退货率（金额）同比 |
| **业务定义** | O2O退货率（金额）今年较去年同期的变化率 |
| **计算公式** | 今年 / 去年 |
| **数据底表** | `a02_e2e_boss_performance_summary_d` |
| **筛选条件** | `calc_type = payment` |
| **数据类型** | delta_bp → 增减基点整数： → +120bp / -80bp（基点，含正负号，值×100 转 bp）,乘以100的操作可以放在Cell Display度量中实现，算同比：当期值 − 同期值（差值，bp 指标，展示时 ×100 转 bp） |        
| **数据格式** | `+#,##0bp;-#,##0bp;0bp` |

---

### 6. Fulfillment% — O2O订单履约率

| 项目 | 内容 |
|---|---|
| **指标名称** | Fulfillment% |
| **指标名称中文** | O2O订单履约率 |
| **业务定义** | 订单类型属于门店发货和门店自提，根据订单付款时间，实际发货的订单数量占客户请求门店的总订单数量的比例 |
| **计算公式** | sum(o2o_fulfillment_shipped_order_cnt) / sum(o2o_fulfillment_request_order_cnt) |
| **分子** | `o2o_fulfillment_shipped_order_cnt` |
| **分母** | `o2o_fulfillment_request_order_cnt` |
| **数据底表** | `a02_e2e_boss_performance_summary_d` |
| **筛选条件** | `calc_type = fulfillment` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%;#,##0.0%;0.0%` |

### 6.1 Fulfillment% LY — O2O订单履约率（对比去年同期）

| 项目 | 内容 |
|---|---|
| **指标名称** | Fulfillment% LY |
| **指标名称中文** | O2O订单履约率（对比去年同期） |
| **业务定义** | 取去年同期O2O订单履约率 |
| **计算公式** | 去年同期 sum(o2o_fulfillment_shipped_order_cnt) / sum(o2o_fulfillment_request_order_cnt) |
| **数据底表** | `a02_e2e_boss_performance_summary_d` |
| **筛选条件** | `calc_type = fulfillment`，取去年同期 |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%;#,##0.0%;0.0%` |

### 6.2 Fulfillment% vs LY — O2O订单履约率同比

| 项目 | 内容 |
|---|---|
| **指标名称** | Fulfillment% vs LY |
| **指标名称中文** | O2O订单履约率同比 |
| **业务定义** | O2O订单履约率今年较去年同期的变化率 |
| **计算公式** | 今年 / 去年 |
| **数据底表** | `a02_e2e_boss_performance_summary_d` |
| **筛选条件** | `calc_type = fulfillment` |
| **数据类型** | delta_bp → 增减基点整数： → +120bp / -80bp（基点，含正负号，值×100 转 bp）,乘以100的操作可以放在Cell Display度量中实现，算同比：当期值 − 同期值（差值，bp 指标，展示时 ×100 转 bp） |        
| **数据格式** | `+#,##0bp;-#,##0bp;0bp` |

---

### 7. Request Order Qty — O2O销售订单量

| 项目 | 内容 |
|---|---|
| **指标名称** | Request Order Qty |
| **指标名称中文** | O2O销售订单量 |
| **业务定义** | 订单类型属于门店发货和门店自提，根据订单付款时间，所有配货状态（配货状态为待接单、已配货、配货失败、新建等中间状态）的订单量 |
| **计算公式** | sum(o2o_fulfillment_request_order_cnt) |
| **统计字段** | `o2o_fulfillment_request_order_cnt` |
| **数据底表** | `a02_e2e_boss_performance_summary_d` |
| **筛选条件** | `calc_type = fulfillment` |
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
| **筛选条件** | `calc_type = fulfillment`，取去年同期 |
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
| **筛选条件** | `calc_type = fulfillment` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%;#,##0.0%;0.0%` |

---

### 8. Request Units — O2O商品销售件数

| 项目 | 内容 |
|---|---|
| **指标名称** | Request Units |
| **指标名称中文** | O2O商品销售件数 |
| **业务定义** | 订单类型属于门店发货和门店自提，根据订单付款时间，所有配货状态（配货状态为待接单、已配货、配货失败、新建等中间状态）的商品数 |
| **计算公式** | sum(o2o_fulfillment_request_qty) |
| **统计字段** | `o2o_fulfillment_request_qty` |
| **数据底表** | `a02_e2e_boss_performance_summary_d` |
| **筛选条件** | `calc_type = fulfillment` |
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
| **筛选条件** | `calc_type = fulfillment`，取去年同期 |
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
| **筛选条件** | `calc_type = fulfillment` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%;#,##0.0%;0.0%` |

---

### 9. Request Order Amt — O2O销售金额

| 项目 | 内容 |
|---|---|
| **指标名称** | Request Order Amt |
| **指标名称中文** | O2O销售金额 |
| **业务定义** | 订单类型属于门店发货和门店自提，根据订单付款时间，所有配货状态（配货状态为待接单、已配货、配货失败、新建等中间状态）的订单金额 |
| **计算公式** | sum(o2o_fulfillment_request_sales_amt) |
| **统计字段** | `o2o_fulfillment_request_sales_amt` |
| **数据底表** | `a02_e2e_boss_performance_summary_d` |
| **筛选条件** | `calc_type = fulfillment` |
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
| **筛选条件** | `calc_type = fulfillment`，取去年同期 |
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
| **筛选条件** | `calc_type = fulfillment` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%;#,##0.0%;0.0%` |

---

### 10. Shipped Order Qty — O2O已配货订单量

| 项目 | 内容 |
|---|---|
| **指标名称** | Shipped Order Qty |
| **指标名称中文** | O2O已配货订单量 |
| **业务定义** | 订单类型属于门店发货和门店自提，根据订单付款时间，配货状态是已配货的订单量 |
| **计算公式** | sum(o2o_fulfillment_shipped_order_cnt) |
| **统计字段** | `o2o_fulfillment_shipped_order_cnt` |
| **数据底表** | `a02_e2e_boss_performance_summary_d` |
| **筛选条件** | `calc_type = fulfillment` |
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
| **筛选条件** | `calc_type = fulfillment`，取去年同期 |
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
| **筛选条件** | `calc_type = fulfillment` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%;#,##0.0%;0.0%` |

---

### 11. Shipped Units — O2O已配货商品件数

| 项目 | 内容 |
|---|---|
| **指标名称** | Shipped Units |
| **指标名称中文** | O2O已配货商品件数 |
| **业务定义** | 订单类型属于门店发货和门店自提，根据订单付款时间，配货状态是已配货的商品数 |
| **计算公式** | sum(o2o_fulfillment_shipped_qty) |
| **统计字段** | `o2o_fulfillment_shipped_qty` |
| **数据底表** | `a02_e2e_boss_performance_summary_d` |
| **筛选条件** | `calc_type = fulfillment` |
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
| **筛选条件** | `calc_type = fulfillment`，取去年同期 |
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
| **筛选条件** | `calc_type = fulfillment` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%;#,##0.0%;0.0%` |

---

### 12. Shipped Order Amt — O2O已配货销售金额

| 项目 | 内容 |
|---|---|
| **指标名称** | Shipped Order Amt |
| **指标名称中文** | O2O已配货销售金额 |
| **业务定义** | 订单类型属于门店发货和门店自提，根据订单付款时间，配货状态是已配货的订单金额 |
| **计算公式** | sum(o2o_fulfillment_shipped_sales_amt) |
| **统计字段** | `o2o_fulfillment_shipped_sales_amt` |
| **数据底表** | `a02_e2e_boss_performance_summary_d` |
| **筛选条件** | `calc_type = fulfillment` |
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
| **筛选条件** | `calc_type = fulfillment`，取去年同期 |
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
| **筛选条件** | `calc_type = fulfillment` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%;#,##0.0%;0.0%` |

---

## 子模块二：Demand SLS by Platform

> **分组维度**: 按 `shop_info_id/shop_name` 分组

### 1. Demand SLS — O2O退前销售额

| 项目 | 内容 |
|---|---|
| **指标名称** | Demand SLS |
| **指标名称中文** | O2O退前销售额 |
| **业务定义** | O2O退前销售额（平台付款时间维度GMV数据）by platform拆分统计 |
| **计算公式** | sum(o2o_sales_amt) |
| **统计字段** | `o2o_sales_amt` |
| **数据底表** | `a02_e2e_boss_performance_summary_d` |
| **筛选条件** | `calc_type = payment`，按 `shop_info_id/shop_name` 分组 |
| **数据类型** | currency → 货币符号由币种切片器决定，千分位整数 |
| **数据格式** | `#,##0`（在 DAX 中用 `__CurrencySymbol & FORMAT(__Value, "#,##0")` 拼接币种符号） |

### 1.1 Demand SLS Share — O2O退前销售额占比

| 项目 | 内容 |
|---|---|
| **指标名称** | Demand SLS Share |
| **指标名称中文** | O2O退前销售额占比 |
| **业务定义** | 每个shop占所有shop的比例 |
| **计算公式** | shop的 sum(o2o_sales_amt) / 所有shop的 sum(o2o_sales_amt) |
| **分子** | `o2o_sales_amt`（当前shop） |
| **分母** | `o2o_sales_amt`（所有shop） |
| **数据底表** | `a02_e2e_boss_performance_summary_d` |
| **筛选条件** | `calc_type = payment`，按 `shop_info_id/shop_name` 分组 |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%;#,##0.0%;0.0%` |

---

## 子模块三：Demand SLS by Division

> **分组维度**: 按 `gender` 分组

### 1. Demand SLS — O2O退前销售额

| 项目 | 内容 |
|---|---|
| **指标名称** | Demand SLS |
| **指标名称中文** | O2O退前销售额 |
| **业务定义** | O2O退前销售额（平台付款时间维度GMV数据）by divison拆分统计 |
| **计算公式** | sum(o2o_sales_amt) |
| **统计字段** | `o2o_sales_amt` |
| **数据底表** | `a02_e2e_boss_performance_summary_d` |
| **筛选条件** | `calc_type = payment`，按 `gender` 分组 |
| **数据类型** | currency → 货币符号由币种切片器决定，千分位整数 |
| **数据格式** | `#,##0`（在 DAX 中用 `__CurrencySymbol & FORMAT(__Value, "#,##0")` 拼接币种符号） |

### 1.1 Demand SLS Share — O2O退前销售额占比

| 项目 | 内容 |
|---|---|
| **指标名称** | Demand SLS Share |
| **指标名称中文** | O2O退前销售额占比 |
| **业务定义** | 每个gender占所有gender的比例 |
| **计算公式** | gender的 sum(o2o_sales_amt) / 所有gender的 sum(o2o_sales_amt) |
| **分子** | `o2o_sales_amt`（当前gender） |
| **分母** | `o2o_sales_amt`（所有gender） |
| **数据底表** | `a02_e2e_boss_performance_summary_d` |
| **筛选条件** | `calc_type = payment`，按 `gender` 分组 |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%;#,##0.0%;0.0%` |

---

## 子模块四：SLS Penetration Trend

> **分组维度**: 按所选 `timeframe` (财日/周/月/季/年) 分组

### 1. Demand SLS — O2O退前销售额（趋势）

| 项目 | 内容 |
|---|---|
| **指标名称** | Demand SLS |
| **指标名称中文** | O2O退前销售额 |
| **业务定义** | 今年/去年O2O退前销售额（平台付款时间维度GMV数据）by 财日/周/月/季/年看趋势变化 |
| **计算公式** | sum(o2o_sales_amt) |
| **统计字段** | `o2o_sales_amt` |
| **数据底表** | `a02_e2e_boss_performance_summary_d` |
| **筛选条件** | `calc_type = fulfillment`，按 `timeframe` 分组 |
| **数据类型** | currency_M_K_Int_0db → 货币符号由币种切片器决定，千分位整数,需要在Cell Display度量中拼接币种符号，需要判断是否带K、M、或者就是千分位整数，如果值小于1000，就直接表示为千分位整数，如果值大于等于1000，就表示为带K、M的格式，1K为一千，1M为一百万，都采用千分位的格式 |
| **数据格式** | `#,##0`（在 DAX 中用 `__CurrencySymbol & FORMAT(__Value, "#,##0")` 拼接币种符号） |

### 1.1 Demand SLS LY — O2O退前销售额（趋势）（对比去年同期）

| 项目 | 内容 |
|---|---|
| **指标名称** | Demand SLS LY |
| **指标名称中文** | O2O退前销售额（趋势）（对比去年同期） |
| **业务定义** | 取去年同期O2O退前销售额趋势变化 |
| **计算公式** | 去年同期 sum(o2o_sales_amt) |
| **数据底表** | `a02_e2e_boss_performance_summary_d` |
| **筛选条件** | `calc_type = fulfillment`，按 `timeframe` 分组，取去年同期 |
| **数据类型** | currency_M_K_Int_0db → 货币符号由币种切片器决定，千分位整数,需要在Cell Display度量中拼接币种符号，需要判断是否带K、M、或者就是千分位整数，如果值小于1000，就直接表示为千分位整数，如果值大于等于1000，就表示为带K、M的格式，1K为一千，1M为一百万，都采用千分位的格式 |
| **数据格式** | `#,##0`（在 DAX 中用 `__CurrencySymbol & FORMAT(__Value, "#,##0")` 拼接币种符号） |

---

### 2. SLS Penetration — O2O销售渗透率（趋势）

| 项目 | 内容 |
|---|---|
| **指标名称** | SLS Penetration |
| **指标名称中文** | O2O销售渗透率 |
| **业务定义** | 今年/去年O2O出库订单销售额占线上总销售额的比例by 财日/周/月/季/年看趋势变化 |
| **计算公式** | sum(o2o_sales_amt) / sum(sales_amt) |
| **统计字段** | `o2o_sales_amt` / `sales_amt` |
| **数据底表** | `a02_e2e_boss_performance_summary_d` |
| **筛选条件** | `calc_type = fulfillment`，按 `timeframe` 分组 |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%;#,##0.0%;0.0%` |

### 2.1 SLS Penetration LY — O2O销售渗透率（趋势）（对比去年同期）

| 项目 | 内容 |
|---|---|
| **指标名称** | SLS Penetration LY |
| **指标名称中文** | O2O销售渗透率（趋势）（对比去年同期） |
| **业务定义** | 取去年同期O2O销售渗透率趋势变化 |
| **计算公式** | 去年同期 sum(o2o_sales_amt) / sum(sales_amt) |
| **数据底表** | `a02_e2e_boss_performance_summary_d` |
| **筛选条件** | `calc_type = fulfillment`，按 `timeframe` 分组，取去年同期 |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%;#,##0.0%;0.0%` |

---

## 子模块五：Fulfillment% by Label

> **分组维度**: 按 `brand` 分组，从高到低进行排序

### 1. Fulfillment% — O2O订单履约率

| 项目 | 内容 |
|---|---|
| **指标名称** | Fulfillment% |
| **指标名称中文** | O2O订单履约率 |
| **业务定义** | 订单类型属于门店发货和门店自提，根据订单付款时间，实际发货的订单数量占客户请求门店的总订单数量的比例by label拆分统计 |
| **计算公式** | sum(o2o_fulfillment_shipped_order_cnt) / sum(o2o_fulfillment_request_order_cnt) |
| **分子** | `o2o_fulfillment_shipped_order_cnt` |
| **分母** | `o2o_fulfillment_request_order_cnt` |
| **数据底表** | `a02_e2e_boss_performance_summary_d` |
| **筛选条件** | `calc_type = fulfillment`，按 `brand` 分组 |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%;#,##0.0%;0.0%` |

---

## 子模块六：Order Processing Efficiency by Label

> **分组维度**: 按 `brand` 分组，从高到低进行排序

### 1. Avg. No. of Store Passed Before Order Got Accepted — O2O平均订单流转次数

| 项目 | 内容 |
|---|---|
| **指标名称** | Avg. No. of Store Passed Before Order Got Accepted |
| **指标名称中文** | O2O平均订单流转次数 |
| **业务定义** | 根据订单付款时间，统计订单在系统中出现的次数（统计配货成功和配货失败的订单）by label拆分统计 |
| **计算公式** | sum(o2o_fulfillment_request_times) / sum(o2o_fulfillment_request_sku_qty) |
| **分子** | `o2o_fulfillment_request_times` |
| **分母** | `o2o_fulfillment_request_sku_qty` |
| **数据底表** | `a02_e2e_boss_fulfillment_request_data_d` |
| **筛选条件** | `calc_type = fulfillment`，按 `brand` 分组 |
| **数据类型** | decimal_1dp → 小数，保留一位小数，千分位 |
| **数据格式** | `#,##0.0` |

---

### 2. Avg. Processing Time — O2O平均订单流转时长

| 项目 | 内容 |
|---|---|
| **指标名称** | Avg. Processing Time |
| **指标名称中文** | O2O平均订单流转时长 |
| **业务定义** | 剔除换货的订单，根据订单的付款时间和订单最后一次配货失败/配货完成的时间，统计订单商品的平均流转时长（统计配货成功和配货失败的订单）by label拆分统计 |
| **计算公式** | sum(o2o_fulfillment_request_duration) / sum(o2o_fulfillment_request_sku_qty) |
| **分子** | `o2o_fulfillment_request_duration` |
| **分母** | `o2o_fulfillment_request_sku_qty` |
| **数据底表** | `a02_e2e_boss_fulfillment_request_data_d` |
| **筛选条件** | `calc_type = fulfillment`，按 `brand` 分组 |
| **数据类型** | decimal_1dp → 小数，保留一位小数，千分位 |
| **数据格式** | `#,##0.0` |

---

## 子模块七：Penalty by Platform

> **分组维度**: 按 `shop_info_id/shop_name` 分组

### 1. Penalty Amt — O2O赔付金额

| 项目 | 内容 |
|---|---|
| **指标名称** | Penalty Amt |
| **指标名称中文** | O2O赔付金额 |
| **业务定义** | 延迟发货/缺货的订单金额，数据源自客服手工记录。一个柱子的总赔付金额 = OOS赔付金额 + Delay赔付金额 |
| **计算公式** | sum(o2o_penalty_oos_amt) + sum(o2o_penalty_delay_amt) |
| **统计字段** | `o2o_penalty_oos_amt`, `o2o_penalty_delay_amt` |
| **数据底表** | `a02_e2e_boss_performance_summary_d` |
| **筛选条件** | `calc_type = fulfillment`，按 `shop_info_id/shop_name` 分组 |
| **数据类型** | currency → 货币符号由币种切片器决定，千分位整数 |
| **数据格式** | `#,##0`（在 DAX 中用 `__CurrencySymbol & FORMAT(__Value, "#,##0")` 拼接币种符号） |

### 1.1 OOS Penalty Amt — OOS赔付金额

| 项目 | 内容 |
|---|---|
| **指标名称** | OOS Penalty Amt |
| **指标名称中文** | OOS赔付金额 |
| **业务定义** | 缺货的订单金额，数据源自客服手工记录 |
| **计算公式** | sum(o2o_penalty_oos_amt) |
| **统计字段** | `o2o_penalty_oos_amt` |
| **数据底表** | `a02_e2e_boss_performance_summary_d` |
| **筛选条件** | `calc_type = fulfillment`，按 `shop_info_id/shop_name` 分组 |
| **数据类型** | currency → 货币符号由币种切片器决定，千分位整数 |
| **数据格式** | `#,##0`（在 DAX 中用 `__CurrencySymbol & FORMAT(__Value, "#,##0")` 拼接币种符号） |

### 1.2 Delay Penalty Amt — Delay赔付金额

| 项目 | 内容 |
|---|---|
| **指标名称** | Delay Penalty Amt |
| **指标名称中文** | Delay赔付金额 |
| **业务定义** | 延迟发货的订单金额，数据源自客服手工记录 |
| **计算公式** | sum(o2o_penalty_delay_amt) |
| **统计字段** | `o2o_penalty_delay_amt` |
| **数据底表** | `a02_e2e_boss_performance_summary_d` |
| **筛选条件** | `calc_type = fulfillment`，按 `shop_info_id/shop_name` 分组 |
| **数据类型** | currency → 货币符号由币种切片器决定，千分位整数 |
| **数据格式** | `#,##0`（在 DAX 中用 `__CurrencySymbol & FORMAT(__Value, "#,##0")` 拼接币种符号） |

### 1.3 OOS Penalty Amt Share — OOS赔付金额占比

| 项目 | 内容 |
|---|---|
| **指标名称** | OOS Penalty Amt Share |
| **指标名称中文** | OOS赔付金额占比 |
| **业务定义** | OOS占比 = OOS赔付金额 / (OOS赔付金额 + Delay赔付金额) |
| **计算公式** | sum(o2o_penalty_oos_amt) / ( sum(o2o_penalty_oos_amt) + sum(o2o_penalty_delay_amt) ) |
| **分子** | `o2o_penalty_oos_amt` |
| **分母** | `o2o_penalty_oos_amt + o2o_penalty_delay_amt` |
| **数据底表** | `a02_e2e_boss_performance_summary_d` |
| **筛选条件** | `calc_type = fulfillment`，按 `shop_info_id/shop_name` 分组 |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%;#,##0.0%;0.0%` |

### 1.4 Delay Penalty Amt Share — Delay赔付金额占比

| 项目 | 内容 |
|---|---|
| **指标名称** | Delay Penalty Amt Share |
| **指标名称中文** | Delay赔付金额占比 |
| **业务定义** | Delay占比 = Delay赔付金额 / (OOS赔付金额 + Delay赔付金额) |
| **计算公式** | sum(o2o_penalty_delay_amt) / ( sum(o2o_penalty_oos_amt) + sum(o2o_penalty_delay_amt) ) |
| **分子** | `o2o_penalty_delay_amt` |
| **分母** | `o2o_penalty_oos_amt + o2o_penalty_delay_amt` |
| **数据底表** | `a02_e2e_boss_performance_summary_d` |
| **筛选条件** | `calc_type = fulfillment`，按 `shop_info_id/shop_name` 分组 |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%;#,##0.0%;0.0%` |

---

### 2. Penalty Order — O2O赔付订单数

| 项目 | 内容 |
|---|---|
| **指标名称** | Penalty Order |
| **指标名称中文** | O2O赔付订单数 |
| **业务定义** | 延迟发货/缺货的订单数，数据源自客服手工记录。一个柱子的总赔付订单数 = OOS赔付订单数 + Delay赔付订单数 |
| **计算公式** | sum(o2o_penalty_oos_order_cnt) + sum(o2o_penalty_delay_order_cnt) |
| **统计字段** | `o2o_penalty_oos_order_cnt`, `o2o_penalty_delay_order_cnt` |
| **数据底表** | `a02_e2e_boss_performance_summary_d` |
| **筛选条件** | `calc_type = fulfillment`，按 `shop_info_id/shop_name` 分组 |
| **数据类型** | integer → 整数，千分位整数 |
| **数据格式** | `#,##0` |

### 2.1 OOS Penalty Order — OOS赔付订单数

| 项目 | 内容 |
|---|---|
| **指标名称** | OOS Penalty Order |
| **指标名称中文** | OOS赔付订单数 |
| **业务定义** | 缺货的订单数，数据源自客服手工记录 |
| **计算公式** | sum(o2o_penalty_oos_order_cnt) |
| **统计字段** | `o2o_penalty_oos_order_cnt` |
| **数据底表** | `a02_e2e_boss_performance_summary_d` |
| **筛选条件** | `calc_type = fulfillment`，按 `shop_info_id/shop_name` 分组 |
| **数据类型** | integer → 整数，千分位整数 |
| **数据格式** | `#,##0` |

### 2.2 Delay Penalty Order — Delay赔付订单数

| 项目 | 内容 |
|---|---|
| **指标名称** | Delay Penalty Order |
| **指标名称中文** | Delay赔付订单数 |
| **业务定义** | 延迟发货的订单数，数据源自客服手工记录 |
| **计算公式** | sum(o2o_penalty_delay_order_cnt) |
| **统计字段** | `o2o_penalty_delay_order_cnt` |
| **数据底表** | `a02_e2e_boss_performance_summary_d` |
| **筛选条件** | `calc_type = fulfillment`，按 `shop_info_id/shop_name` 分组 |
| **数据类型** | integer → 整数，千分位整数 |
| **数据格式** | `#,##0` |

### 2.3 OOS Penalty Order Share — OOS赔付订单数占比

| 项目 | 内容 |
|---|---|
| **指标名称** | OOS Penalty Order Share |
| **指标名称中文** | OOS赔付订单数占比 |
| **业务定义** | OOS占比 = OOS赔付订单数 / (OOS赔付订单数 + Delay赔付订单数) |
| **计算公式** | sum(o2o_penalty_oos_order_cnt) / ( sum(o2o_penalty_oos_order_cnt) + sum(o2o_penalty_delay_order_cnt) ) |
| **分子** | `o2o_penalty_oos_order_cnt` |
| **分母** | `o2o_penalty_oos_order_cnt + o2o_penalty_delay_order_cnt` |
| **数据底表** | `a02_e2e_boss_performance_summary_d` |
| **筛选条件** | `calc_type = fulfillment`，按 `shop_info_id/shop_name` 分组 |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%;#,##0.0%;0.0%` |

### 2.4 Delay Penalty Order Share — Delay赔付订单数占比

| 项目 | 内容 |
|---|---|
| **指标名称** | Delay Penalty Order Share |
| **指标名称中文** | Delay赔付订单数占比 |
| **业务定义** | Delay占比 = Delay赔付订单数 / (OOS赔付订单数 + Delay赔付订单数) |
| **计算公式** | sum(o2o_penalty_delay_order_cnt) / ( sum(o2o_penalty_oos_order_cnt) + sum(o2o_penalty_delay_order_cnt) ) |
| **分子** | `o2o_penalty_delay_order_cnt` |
| **分母** | `o2o_penalty_oos_order_cnt + o2o_penalty_delay_order_cnt` |
| **数据底表** | `a02_e2e_boss_performance_summary_d` |
| **筛选条件** | `calc_type = fulfillment`，按 `shop_info_id/shop_name` 分组 |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%;#,##0.0%;0.0%` |

---

## 通用规则汇总

| 规则项 | 说明 |
|---|---|
| **数据底表** | `a02_e2e_boss_performance_summary_d` / `a02_e2e_boss_fulfillment_request_data_d` |
| **筛选逻辑** | 统一包含 `calc_type = payment` 或 `calc_type = fulfillment` |
| **货币转换规则** | 数据源默认为 RMB，转化为美元需要除以固定值 7 |
| **派生指标** | LY（去年同期）、vs LY（同比）、占比等为派生指标，依据基础指标计算生成 |
| **分组维度** | 根据 `shop_info_id/shop_name`、`gender`、`timeframe` 或 `brand` 分组 |
| **必须遵守** | 口径文档中定义的所有指标，必须遵守其数据类型和数据格式，如果和解决方案中存在争议的，一切以口径文档为准，必须按照口径文档中的格式进行调整 |
| **DAX 语法规范** | 文本常量必须使用双引号 `" "`，禁止使用单引号；单引号 `' '` 仅用于表名，列名使用方括号 `[ ]`，例如：`[calc_type] = "payment"` |