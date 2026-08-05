# BOSS Performance Dashboard 指标口径提示词

> **Dashboard**: BOSS Performance Dashboard  
> **Tab**: Performance By Location  
> **数据底表**: `a02_e2e_boss_performance_summary_d` / `a02_e2e_boss_fulfillment_request_data_d` / `a02_e2e_boss_fulfillment_fail_reason_d` / `t01_o2o_fulfillment_order_detail_d`  
> **模块说明**: 本板块为 BOSS 按 Region/Store Type 维度的绩效看板，覆盖 BOSS Fulfillment - Fulfilled Order by Region/Store Type、Fulfillment% Trend、BOSS Unfulfillment - Unfulfilled Order by Region、BOSS Unfulfillment - Failed Request by Reason、BOSS Performance Details 五个子板块，统计已配货订单量/金额、履约率趋势、未履约订单分布、失败原因分布及全量 KPI 明细。

---

## 全局逻辑

| 项目 | 内容 |
|---|---|
| **数据底表** | `a02_e2e_boss_performance_summary_d`、`a02_e2e_boss_fulfillment_request_data_d`、`a02_e2e_boss_fulfillment_fail_reason_d`、`t01_o2o_fulfillment_order_detail_d` |
| **筛选逻辑** | 按各指标定义区分 `calc_type = payment` 或 `calc_type = fulfillment`；并按 `fulfillment_calc_type` 区分履约口径（1: Exclude orders cancelled in pay date；2: Exclude orders cancelled in paydate & EC-fulfilled from O2O unfulfilled） |
| **聚合粒度** | 数字卡片：所选时间范围 `data_date`；表格：所选时间范围 `data_date`，选择 Region 则聚合在 `store_region` 粒度，选择 Store Type 则聚合在 `store_type` 粒度；趋势图：按所选 `timeframe` (财日/周/月/季/年) 聚合 |
| **货币转换规则** | 数据源默认为 RMB，转化为美元需要除以固定值 7 |
| **派生指标** | LY（去年同期）、vs LY（同比）、占比等附属指标为派生指标，依据基础指标计算生成 |
| **必须遵守** | 口径文档中定义的所有指标，必须遵守其数据类型和数据格式，如果和解决方案中存在争议的，一切以口径文档为准，必须按照口径文档中的格式进行调整 |

---

## 子模块一：BOSS Fulfillment - Fulfilled Order by Region/Store Type

> **分组维度**: 选择 Region 则按 `store_region` 分组；选择 Store Type 则按 `store_type` 分组

### 1. Shipped Order Qty — O2O已配货订单量

| 项目 | 内容 |
|---|---|
| **指标名称** | Shipped Order Qty |
| **指标名称中文** | O2O已配货订单量 |
| **业务定义** | 订单类型属于门店发货和门店自提，根据订单付款时间，配货状态是已配货的订单量 by region/store type 拆分统计 |
| **计算公式** | sum(o2o_fulfillment_shipped_order_cnt) |
| **统计字段** | `o2o_fulfillment_shipped_order_cnt` |
| **数据底表** | `a02_e2e_boss_performance_summary_d` |
| **筛选条件** | `calc_type = fulfillment`，按 `store_region` 或 `store_type` 分组 |
| **数据类型** | integer → 整数，千分位整数 |
| **数据格式** | `#,##0` |

### 1.1 LY Fulfilled Order Qty — O2O已配货订单量（对比去年同期）

| 项目 | 内容 |
|---|---|
| **指标名称** | LY Fulfilled Order Qty |
| **指标名称中文** | O2O已配货订单量（对比去年同期） |
| **业务定义** | 取去年同期O2O已配货订单量 |
| **计算公式** | 去年同期 sum(o2o_fulfillment_shipped_order_cnt) |
| **数据底表** | `a02_e2e_boss_performance_summary_d` |
| **筛选条件** | `calc_type = fulfillment`，按 `store_region` 或 `store_type` 分组，取去年同期 |
| **数据类型** | integer → 整数，千分位整数 |
| **数据格式** | `#,##0` |

### 1.2 YOY — O2O已配货订单量同比

| 项目 | 内容 |
|---|---|
| **指标名称** | YOY |
| **指标名称中文** | O2O已配货订单量同比 |
| **业务定义** | O2O已配货订单量今年较去年同期的变化率 |
| **计算公式** | 今年 / 去年 − 1 |
| **数据底表** | `a02_e2e_boss_performance_summary_d` |
| **筛选条件** | `calc_type = fulfillment`，按 `store_region` 或 `store_type` 分组 |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

---

### 2. Shipped Order Amt — O2O已配货销售金额

| 项目 | 内容 |
|---|---|
| **指标名称** | Shipped Order Amt |
| **指标名称中文** | O2O已配货销售金额 |
| **业务定义** | 订单类型属于门店发货和门店自提，根据订单付款时间，配货状态是已配货的订单金额 by region/store type 拆分统计 |
| **计算公式** | sum(o2o_fulfillment_shipped_sales_amt) |
| **统计字段** | `o2o_fulfillment_shipped_sales_amt` |
| **数据底表** | `a02_e2e_boss_performance_summary_d` |
| **筛选条件** | `calc_type = fulfillment`，按 `store_region` 或 `store_type` 分组 |
| **数据类型** | currency → 货币符号由币种切片器决定，千分位整数 |
| **数据格式** | `#,##0`（在 DAX 中用 `__CurrencySymbol & FORMAT(__Value, "#,##0")` 拼接币种符号） |

### 2.1 LY Fulfilled Order Amt — O2O已配货销售金额（对比去年同期）

| 项目 | 内容 |
|---|---|
| **指标名称** | LY Fulfilled Order Amt |
| **指标名称中文** | O2O已配货销售金额（对比去年同期） |
| **业务定义** | 取去年同期O2O已配货销售金额 |
| **计算公式** | 去年同期 sum(o2o_fulfillment_shipped_sales_amt) |
| **数据底表** | `a02_e2e_boss_performance_summary_d` |
| **筛选条件** | `calc_type = fulfillment`，按 `store_region` 或 `store_type` 分组，取去年同期 |
| **数据类型** | currency → 货币符号由币种切片器决定，千分位整数 |
| **数据格式** | `#,##0`（在 DAX 中用 `__CurrencySymbol & FORMAT(__Value, "#,##0")` 拼接币种符号） |

### 2.2 YOY — O2O已配货销售金额同比

| 项目 | 内容 |
|---|---|
| **指标名称** | YOY |
| **指标名称中文** | O2O已配货销售金额同比 |
| **业务定义** | O2O已配货销售金额今年较去年同期的变化率 |
| **计算公式** | 今年 / 去年 − 1 |
| **数据底表** | `a02_e2e_boss_performance_summary_d` |
| **筛选条件** | `calc_type = fulfillment`，按 `store_region` 或 `store_type` 分组 |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

---

## 子模块二：Fulfillment% Trend

> **分组维度**: 按所选 `timeframe` (财日/周/月/季/年) 分组；如果选择 Region，则折线代表各个 `store_region`；如果选择 Store Type，则折线代表各个 `store_type`

### 1. Fulfillment% — O2O订单履约率（趋势）

| 项目 | 内容 |
|---|---|
| **指标名称** | Fulfillment% |
| **指标名称中文** | O2O订单履约率 |
| **业务定义** | 订单类型属于门店发货和门店自提，根据订单付款时间，实际发货的订单数量占客户请求门店的总订单数量的比例 by region/store type 看财日/周/月/季/年看趋势变化 |
| **计算公式** | sum(o2o_fulfillment_shipped_order_cnt) / sum(o2o_fulfillment_request_order_cnt) |
| **分子** | `o2o_fulfillment_shipped_order_cnt` |
| **分母** | `o2o_fulfillment_request_order_cnt` |
| **数据底表** | `a02_e2e_boss_performance_summary_d` |
| **筛选条件** | `calc_type = fulfillment`（固定筛选），按 `timeframe` 分组，并按 `store_region` 或 `store_type` 拆分折线 |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

---

## 子模块三：BOSS Unfulfillment - Unfulfilled Order by Region

> **分组维度**: 按 `failure_remark` 分类 + `store_region` 或 `store_type` 分组

### 1. Unfulfilled Order — O2O失败订单数，这个不同于其他指标在于，这里需要输出四个子指标项：Rejected Order by Store、Cancelled Order by Overdue、Cancelled Order by Customer、Cancelled Order by Other，四个的子指标项的计算口径是一致的，只是分类不同，即四个Value+四个Display度量。

| 项目 | 内容 |
|---|---|
| **指标名称** | Unfulfilled Order |
| **指标名称中文** | O2O失败订单数 |
| **业务定义** | 订单维度去重统计，根据订单付款时间，统计配货状态是配货失败的订单量 by region/store type 看配货失败原因的分布情况 |
| **计算公式** | count(distinct order_code) |
| **统计字段** | `order_code`（去重计数） |
| **数据底表** | `t01_o2o_fulfillment_order_detail_d` |
| **筛选条件** | Unfulfilled Order Scope 在 PBI 上实现；按 `failure_remark` + `store_region` 或 `store_type` 聚合 |
| **聚合步骤** | 根据所选时间范围 data_date ∈ [__TimeMin, __TimeMax]（全局时间范围）， 按照 `failure_remark`分类对order_code进行去重计数 ， `region` 或 `store_type` 分组维度我会拉取数据表中的字段到柱形图或者折线图上，无需在PBI中添加分组维度，天然自带分组属性 |
| **failure_remark 分类逻辑** | - Rejected Order by Store：`failure_remark` in ('门店拒绝接单','门店接单后取消配货')<br>- Cancelled Order by Overdue：`failure_remark` in ('待接单超时','门店接单后超时未处理','接单超时')<br>- Cancelled Order by Customer：`failure_remark` in ('顾客取消订单','消费者取消')<br>- Cancelled Order by Other：`failure_remark` not in ('门店拒绝接单','门店接单后取消配货','待接单超时','门店接单后超时未处理','接单超时','顾客取消订单','消费者取消') |
| **数据类型** | integer → 整数，千分位整数 |
| **数据格式** | `#,##0` |

### 1.1 Unfulfilled Order Share — O2O失败订单数占比，这里也是需要输出四个子指标项：Rejected Order Share by Store、Cancelled Order Share by Overdue、Cancelled Order Share by Customer、Cancelled Order Share by Other，四个的子指标项的计算口径是一致的，只是分类不同，即四个Value+四个Display度量。

| 项目 | 内容 |
|---|---|
| **指标名称** | Unfulfilled Order Share |
| **指标名称中文** | O2O失败订单数占比 |
| **业务定义** | 每个 reject reason 占所有拒单数量的比例 |
| **计算公式** | 当前 reject reason 的 count(distinct order_code) / 所有 reject reason 的 count(distinct order_code)，这里使用四个指标相加作为分母，不使用REMOVEFILTERS函数 |
| **分子** | `order_code`（当前 reject reason） |
| **分母** | `order_code`（所有 reject reason） |
| **数据底表** | `t01_o2o_fulfillment_order_detail_d` |
| **筛选条件** | Unfulfilled Order Scope 在 PBI 上实现；按 `failure_remark` + `store_region` 或 `store_type` 聚合 |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

---

### 1.2 Unfulfilled Order Tooltip Display

| 项目 | 内容 |
|---|---|
| **指标名称** | Unfulfilled Order Tooltip Display |
| **指标名称中文** | Unfulfilled Order工具提示 |
| **业务定义** | 工具提示 |
| **计算公式** | 拼接当前分组维度字段，这里暂时使用order_type + "失败订单数" + "占比" |
| **格式** | order_type：{order_type}
Rejected by Store：{Rejected Order by Store} 占比：{Rejected Order Share by Store}
Cancelled by Overdue：{Cancelled Order by Overdue} 占比：{Cancelled Order Share by Overdue}
Cancelled by Customer：{Cancelled Order by Customer} 占比：{Cancelled Order Share by Customer}
Cancelled by Other：{Cancelled Order by Other} 占比：{Cancelled Order Share by Other}
这里记得换行，共五行 |

---

## 子模块四：BOSS Unfulfillment - Failed Request by Reason

> **分组维度**: 所选时间范围 `data_date`；Region 筛选器默认选中所有 region，数据展示所有 region 的总和

### 1. Failed Request — O2O门店订单失败次数

| 项目 | 内容 |
|---|---|
| **指标名称** | Failed Request |
| **指标名称中文** | O2O门店订单失败次数 |
| **业务定义** | 根据订单付款时间，统计订单流转到门店的次数（不去重）by region/store type 看配货失败原因的分布情况 |
| **计算公式** | sum(request_times) |
| **统计字段** | `request_times` |
| **数据底表** | `a02_e2e_boss_fulfillment_fail_reason_d` |
| **筛选条件** | Region 筛选器默认选中所有 region，数据展示所有 region 的总和 |
| **数据类型** | integer → 整数，千分位整数 |
| **数据格式** | `#,##0` |

---

## 子模块五：BOSS Performance Details

> **分组维度**: 选择 Region 则按 `store_region` 分组；选择 Store Type 则按 `store_type` 分组；`store_region`/`store_type` 粒度行支持展开看 `shop_code` 粒度明细数据

### 1. SLS — O2O销售净额

| 项目 | 内容 |
|---|---|
| **指标名称** | SLS |
| **指标名称中文** | O2O销售净额 |
| **业务定义** | 订单类型属于门店发货和门店自提，BI中退货入库金额+销售出库金额, 统计时间为出入库时间 by region/store type/store 拆分统计 |
| **计算公式** | sum(o2o_net_sales_amt) |
| **统计字段** | `o2o_net_sales_amt` |
| **数据底表** | `a02_e2e_boss_performance_summary_d` |
| **筛选条件** | `calc_type = payment`，按 `store_region` 或 `store_type` 分组（支持展开到 `shop_code`） |
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
| **筛选条件** | `calc_type = payment`，按 `store_region` 或 `store_type` 分组，取去年同期 |
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
| **筛选条件** | `calc_type = payment`，按 `store_region` 或 `store_type` 分组 |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

---

### 2. Demand SLS — O2O退前销售额

| 项目 | 内容 |
|---|---|
| **指标名称** | Demand SLS |
| **指标名称中文** | O2O退前销售额 |
| **业务定义** | O2O退前销售额（平台付款时间维度GMV数据）by region/store type/store 拆分统计 |
| **计算公式** | sum(o2o_sales_amt) |
| **统计字段** | `o2o_sales_amt` |
| **数据底表** | `a02_e2e_boss_performance_summary_d` |
| **筛选条件** | `calc_type = payment`，按 `store_region` 或 `store_type` 分组（支持展开到 `shop_code`） |
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
| **筛选条件** | `calc_type = payment`，按 `store_region` 或 `store_type` 分组，取去年同期 |
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
| **筛选条件** | `calc_type = payment`，按 `store_region` 或 `store_type` 分组 |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

---

### 3. SLS Penetration — O2O销售渗透率

| 项目 | 内容 |
|---|---|
| **指标名称** | SLS Penetration |
| **指标名称中文** | O2O销售渗透率 |
| **业务定义** | O2O出库订单销售额占线上总销售额的比例 by region/store type/store 拆分统计 |
| **计算公式** | sum(o2o_sales_amt) / sum(sales_amt) |
| **分子** | `o2o_sales_amt` |
| **分母** | `sales_amt` |
| **数据底表** | `a02_e2e_boss_performance_summary_d` |
| **筛选条件** | `calc_type = payment`，按 `store_region` 或 `store_type` 分组（支持展开到 `shop_code`） |
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
| **筛选条件** | `calc_type = payment`，按 `store_region` 或 `store_type` 分组，取去年同期 |
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
| **筛选条件** | `calc_type = payment`，按 `store_region` 或 `store_type` 分组 |
| **数据类型** | delta_bp → 增减基点整数： → +120bp / -80bp（基点，含正负号，值×100 转 bp）, 乘以100的操作可以放在 Cell Display 度量中实现，算同比：当期值 − 同期值（差值，bp 指标，展示时 ×100 转 bp） |
| **数据格式** | `+#,##0bp;-#,##0bp;0bp` |

---

### 4. Return — O2O退货金额

| 项目 | 内容 |
|---|---|
| **指标名称** | Return |
| **指标名称中文** | O2O退货金额 |
| **业务定义** | 订单类型属于门店发货和门店自提的退货入库金额, 包含门店发货后退货到EC仓的入库金额，统计时间为出入库时间 by region/store type/store 拆分统计 |
| **计算公式** | sum(o2o_return_amt) |
| **统计字段** | `o2o_return_amt` |
| **数据底表** | `a02_e2e_boss_performance_summary_d` |
| **筛选条件** | `calc_type = payment`，按 `store_region` 或 `store_type` 分组（支持展开到 `shop_code`） |
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
| **筛选条件** | `calc_type = payment`，按 `store_region` 或 `store_type` 分组，取去年同期 |
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
| **筛选条件** | `calc_type = payment`，按 `store_region` 或 `store_type` 分组 |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

---

### 5. Return% — O2O退货率（金额）

| 项目 | 内容 |
|---|---|
| **指标名称** | Return% |
| **指标名称中文** | O2O退货率（金额） |
| **业务定义** | 订单类型属于门店发货和门店自提的退货入库订单，退货入库/销售出库，以金额计算 by region/store type/store 拆分统计 |
| **计算公式** | sum(o2o_return_amt) / sum(o2o_sales_amt) |
| **分子** | `o2o_return_amt` |
| **分母** | `o2o_sales_amt` |
| **数据底表** | `a02_e2e_boss_performance_summary_d` |
| **筛选条件** | `calc_type = payment`，按 `store_region` 或 `store_type` 分组（支持展开到 `shop_code`） |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

### 5.1 Return% LY — O2O退货率（金额）（对比去年同期）

| 项目 | 内容 |
|---|---|
| **指标名称** | Return% LY |
| **指标名称中文** | O2O退货率（金额）（对比去年同期） |
| **业务定义** | 取去年同期O2O退货率（金额） |
| **计算公式** | 去年同期 sum(o2o_return_amt) / sum(o2o_sales_amt) |
| **数据底表** | `a02_e2e_boss_performance_summary_d` |
| **筛选条件** | `calc_type = payment`，按 `store_region` 或 `store_type` 分组，取去年同期 |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

### 5.2 Return% vs LY — O2O退货率（金额）同比

| 项目 | 内容 |
|---|---|
| **指标名称** | Return% vs LY |
| **指标名称中文** | O2O退货率（金额）同比 |
| **业务定义** | O2O退货率（金额）今年较去年同期的变化率 |
| **计算公式** | 今年 − 去年（差值，bp 指标，展示时 ×100 转 bp） |
| **数据底表** | `a02_e2e_boss_performance_summary_d` |
| **筛选条件** | `calc_type = payment`，按 `store_region` 或 `store_type` 分组 |
| **数据类型** | delta_bp → 增减基点整数： → +120bp / -80bp（基点，含正负号，值×100 转 bp）, 乘以100的操作可以放在 Cell Display 度量中实现，算同比：当期值 − 同期值（差值，bp 指标，展示时 ×100 转 bp） |
| **数据格式** | `+#,##0bp;-#,##0bp;0bp` |

---

### 6. Fulfillment% — O2O订单履约率

| 项目 | 内容 |
|---|---|
| **指标名称** | Fulfillment% |
| **指标名称中文** | O2O订单履约率 |
| **业务定义** | 订单类型属于门店发货和门店自提，根据订单付款时间，实际发货的订单数量占客户请求门店的总订单数量的比例 by region/store type/store 拆分统计 |
| **计算公式** | sum(o2o_fulfillment_shipped_order_cnt) / sum(o2o_fulfillment_request_order_cnt) |
| **分子** | `o2o_fulfillment_shipped_order_cnt` |
| **分母** | `o2o_fulfillment_request_order_cnt` |
| **数据底表** | `a02_e2e_boss_performance_summary_d` |
| **筛选条件** | `calc_type = fulfillment`，按 `store_region` 或 `store_type` 分组（支持展开到 `shop_code`） |
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
| **筛选条件** | `calc_type = fulfillment`，按 `store_region` 或 `store_type` 分组，取去年同期 |
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
| **筛选条件** | `calc_type = fulfillment`，按 `store_region` 或 `store_type` 分组 |
| **数据类型** | delta_bp → 增减基点整数： → +120bp / -80bp（基点，含正负号，值×100 转 bp）, 乘以100的操作可以放在 Cell Display 度量中实现，算同比：当期值 − 同期值（差值，bp 指标，展示时 ×100 转 bp） |
| **数据格式** | `+#,##0bp;-#,##0bp;0bp` |

---

### 7. Request Order Qty — O2O销售订单量

| 项目 | 内容 |
|---|---|
| **指标名称** | Request Order Qty |
| **指标名称中文** | O2O销售订单量 |
| **业务定义** | 订单类型属于门店发货和门店自提，根据订单付款时间，所有配货状态（配货状态为待接单、已配货、配货失败、新建等中间状态）的订单量 by region/store type/store 拆分统计 |
| **计算公式** | sum(o2o_fulfillment_request_order_cnt) |
| **统计字段** | `o2o_fulfillment_request_order_cnt` |
| **数据底表** | `a02_e2e_boss_performance_summary_d` |
| **筛选条件** | `calc_type = fulfillment`，按 `store_region` 或 `store_type` 分组（支持展开到 `shop_code`） |
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
| **筛选条件** | `calc_type = fulfillment`，按 `store_region` 或 `store_type` 分组，取去年同期 |
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
| **筛选条件** | `calc_type = fulfillment`，按 `store_region` 或 `store_type` 分组 |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

---

### 8. Request Units — O2O商品销售件数

| 项目 | 内容 |
|---|---|
| **指标名称** | Request Units |
| **指标名称中文** | O2O商品销售件数 |
| **业务定义** | 订单类型属于门店发货和门店自提，根据订单付款时间，所有配货状态（配货状态为待接单、已配货、配货失败、新建等中间状态）的商品数 by region/store type/store 拆分统计 |
| **计算公式** | sum(o2o_fulfillment_request_qty) |
| **统计字段** | `o2o_fulfillment_request_qty` |
| **数据底表** | `a02_e2e_boss_performance_summary_d` |
| **筛选条件** | `calc_type = fulfillment`，按 `store_region` 或 `store_type` 分组（支持展开到 `shop_code`） |
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
| **筛选条件** | `calc_type = fulfillment`，按 `store_region` 或 `store_type` 分组，取去年同期 |
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
| **筛选条件** | `calc_type = fulfillment`，按 `store_region` 或 `store_type` 分组 |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

---

### 9. Request Order Amt — O2O销售金额

| 项目 | 内容 |
|---|---|
| **指标名称** | Request Order Amt |
| **指标名称中文** | O2O销售金额 |
| **业务定义** | 订单类型属于门店发货和门店自提，根据订单付款时间，所有配货状态（配货状态为待接单、已配货、配货失败、新建等中间状态）的订单金额 by region/store type/store 拆分统计 |
| **计算公式** | sum(o2o_fulfillment_request_sales_amt) |
| **统计字段** | `o2o_fulfillment_request_sales_amt` |
| **数据底表** | `a02_e2e_boss_performance_summary_d` |
| **筛选条件** | `calc_type = fulfillment`，按 `store_region` 或 `store_type` 分组（支持展开到 `shop_code`） |
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
| **筛选条件** | `calc_type = fulfillment`，按 `store_region` 或 `store_type` 分组，取去年同期 |
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
| **筛选条件** | `calc_type = fulfillment`，按 `store_region` 或 `store_type` 分组 |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

---

### 10. Shipped Order Qty — O2O已配货订单量

| 项目 | 内容 |
|---|---|
| **指标名称** | Shipped Order Qty |
| **指标名称中文** | O2O已配货订单量 |
| **业务定义** | 订单类型属于门店发货和门店自提，根据订单付款时间，配货状态是已配货的订单量 by region/store type/store 拆分统计 |
| **计算公式** | sum(o2o_fulfillment_shipped_order_cnt) |
| **统计字段** | `o2o_fulfillment_shipped_order_cnt` |
| **数据底表** | `a02_e2e_boss_performance_summary_d` |
| **筛选条件** | `calc_type = fulfillment`，按 `store_region` 或 `store_type` 分组（支持展开到 `shop_code`） |
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
| **筛选条件** | `calc_type = fulfillment`，按 `store_region` 或 `store_type` 分组，取去年同期 |
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
| **筛选条件** | `calc_type = fulfillment`，按 `store_region` 或 `store_type` 分组 |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

---

### 11. Shipped Units — O2O已配货商品件数

| 项目 | 内容 |
|---|---|
| **指标名称** | Shipped Units |
| **指标名称中文** | O2O已配货商品件数 |
| **业务定义** | 订单类型属于门店发货和门店自提，根据订单付款时间，配货状态是已配货的商品数 by region/store type/store 拆分统计 |
| **计算公式** | sum(o2o_fulfillment_shipped_qty) |
| **统计字段** | `o2o_fulfillment_shipped_qty` |
| **数据底表** | `a02_e2e_boss_performance_summary_d` |
| **筛选条件** | `calc_type = fulfillment`，按 `store_region` 或 `store_type` 分组（支持展开到 `shop_code`） |
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
| **筛选条件** | `calc_type = fulfillment`，按 `store_region` 或 `store_type` 分组，取去年同期 |
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
| **筛选条件** | `calc_type = fulfillment`，按 `store_region` 或 `store_type` 分组 |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

---

### 12. Shipped Order Amt — O2O已配货销售金额

| 项目 | 内容 |
|---|---|
| **指标名称** | Shipped Order Amt |
| **指标名称中文** | O2O已配货销售金额 |
| **业务定义** | 订单类型属于门店发货和门店自提，根据订单付款时间，配货状态是已配货的订单金额 by region/store type/store 拆分统计 |
| **计算公式** | sum(o2o_fulfillment_shipped_sales_amt) |
| **统计字段** | `o2o_fulfillment_shipped_sales_amt` |
| **数据底表** | `a02_e2e_boss_performance_summary_d` |
| **筛选条件** | `calc_type = fulfillment`，按 `store_region` 或 `store_type` 分组（支持展开到 `shop_code`） |
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
| **筛选条件** | `calc_type = fulfillment`，按 `store_region` 或 `store_type` 分组，取去年同期 |
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
| **筛选条件** | `calc_type = fulfillment`，按 `store_region` 或 `store_type` 分组 |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

---

### 13. Unfulfillment% — O2O订单未履约率

| 项目 | 内容 |
|---|---|
| **指标名称** | Unfulfillment% |
| **指标名称中文** | O2O订单未履约率 |
| **业务定义** | 根据订单付款时间，统计订单维度，配货失败的订单数量占客户提交的总订单数量的比例 by region/store type/store 拆分统计 |
| **计算公式** | sum(o2o_fulfillment_unshipped_order_cnt) / sum(o2o_fulfillment_request_order_cnt) |
| **分子** | `o2o_fulfillment_unshipped_order_cnt` |
| **分母** | `o2o_fulfillment_request_order_cnt` |
| **数据底表** | `a02_e2e_boss_performance_summary_d` |
| **筛选条件** | `calc_type = fulfillment`，按 `store_region` 或 `store_type` 分组（支持展开到 `shop_code`） |
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
| **筛选条件** | `calc_type = fulfillment`，按 `store_region` 或 `store_type` 分组，取去年同期 |
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
| **筛选条件** | `calc_type = fulfillment`，按 `store_region` 或 `store_type` 分组 |
| **数据类型** | delta_bp → 增减基点整数： → +120bp / -80bp（基点，含正负号，值×100 转 bp）, 乘以100的操作可以放在 Cell Display 度量中实现，算同比：当期值 − 同期值（差值，bp 指标，展示时 ×100 转 bp） |
| **数据格式** | `+#,##0bp;-#,##0bp;0bp` |

---

### 14. Unfulfilled Order — O2O失败订单数

| 项目 | 内容 |
|---|---|
| **指标名称** | Unfulfilled Order |
| **指标名称中文** | O2O失败订单数 |
| **业务定义** | 订单维度去重统计，根据订单付款时间，统计配货状态是配货失败的订单量 by region/store type/store 拆分统计 |
| **计算公式** | sum(o2o_fulfillment_unshipped_order_cnt) |
| **统计字段** | `o2o_fulfillment_unshipped_order_cnt` |
| **数据底表** | `a02_e2e_boss_performance_summary_d` |
| **筛选条件** | `calc_type = fulfillment`，按 `store_region` 或 `store_type` 分组（支持展开到 `shop_code`） |
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
| **筛选条件** | `calc_type = fulfillment`，按 `store_region` 或 `store_type` 分组，取去年同期 |
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
| **筛选条件** | `calc_type = fulfillment`，按 `store_region` 或 `store_type` 分组 |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

---

### 15. Unfulfilled Units — O2O失败订单商品件数

| 项目 | 内容 |
|---|---|
| **指标名称** | Unfulfilled Units |
| **指标名称中文** | O2O失败订单商品件数 |
| **业务定义** | 订单维度去重统计，根据订单付款时间，统计配货状态是配货失败的商品件数 by region/store type/store 拆分统计 |
| **计算公式** | sum(o2o_fulfillment_unshipped_qty) |
| **统计字段** | `o2o_fulfillment_unshipped_qty` |
| **数据底表** | `a02_e2e_boss_performance_summary_d` |
| **筛选条件** | `calc_type = fulfillment`，按 `store_region` 或 `store_type` 分组（支持展开到 `shop_code`） |
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
| **筛选条件** | `calc_type = fulfillment`，按 `store_region` 或 `store_type` 分组，取去年同期 |
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
| **筛选条件** | `calc_type = fulfillment`，按 `store_region` 或 `store_type` 分组 |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

---

### 16. Unfulfilled Amt — O2O失败订单销售金额

| 项目 | 内容 |
|---|---|
| **指标名称** | Unfulfilled Amt |
| **指标名称中文** | O2O失败订单销售金额 |
| **业务定义** | 订单维度去重统计，根据订单付款时间，统计配货状态是配货失败的销售金额 by region/store type/store 拆分统计 |
| **计算公式** | sum(o2o_fulfillment_unshipped_sales_amt) |
| **统计字段** | `o2o_fulfillment_unshipped_sales_amt` |
| **数据底表** | `a02_e2e_boss_performance_summary_d` |
| **筛选条件** | `calc_type = fulfillment`，按 `store_region` 或 `store_type` 分组（支持展开到 `shop_code`） |
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
| **筛选条件** | `calc_type = fulfillment`，按 `store_region` 或 `store_type` 分组，取去年同期 |
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
| **筛选条件** | `calc_type = fulfillment`，按 `store_region` 或 `store_type` 分组 |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

---

### 17. Rejected Order — O2O门店拒绝接单的订单数量

| 项目 | 内容 |
|---|---|
| **指标名称** | Rejected Order |
| **指标名称中文** | O2O门店拒绝接单的订单数量 |
| **业务定义** | 根据订单付款时间，状态包含门店拒绝接单，门店接单后取消配货的订单数量 by region/store type/store 拆分统计 |
| **计算公式** | sum(o2o_fulfillment_unshipped_store_rejected_order_cnt) |
| **统计字段** | `o2o_fulfillment_unshipped_store_rejected_order_cnt` |
| **数据底表** | `a02_e2e_boss_performance_summary_d` |
| **筛选条件** | `calc_type = fulfillment`，按 `store_region` 或 `store_type` 分组（支持展开到 `shop_code`） |
| **数据类型** | integer → 整数，千分位整数 |
| **数据格式** | `#,##0` |

---

### 18. Rejected% — O2O门店拒单率

| 项目 | 内容 |
|---|---|
| **指标名称** | Rejected% |
| **指标名称中文** | O2O门店拒单率 |
| **业务定义** | 拒单订单量占顾客下单的总订单的比例 by region/store type/store 拆分统计 |
| **计算公式** | sum(o2o_fulfillment_unshipped_store_rejected_order_cnt) / sum(o2o_fulfillment_request_order_cnt) |
| **分子** | `o2o_fulfillment_unshipped_store_rejected_order_cnt` |
| **分母** | `o2o_fulfillment_request_order_cnt` |
| **数据底表** | `a02_e2e_boss_performance_summary_d` |
| **筛选条件** | `calc_type = fulfillment`，按 `store_region` 或 `store_type` 分组（支持展开到 `shop_code`） |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

---

### 19. Cancelled Order by Overdue — O2O超时的订单数量

| 项目 | 内容 |
|---|---|
| **指标名称** | Cancelled Order by Overdue |
| **指标名称中文** | O2O超时的订单数量 |
| **业务定义** | 根据订单付款时间，状态包含待接单超时和门店接单后超时未处理的订单数量 by region/store type/store 拆分统计 |
| **计算公式** | sum(o2o_fulfillment_unshipped_overdue_order_cnt) |
| **统计字段** | `o2o_fulfillment_unshipped_overdue_order_cnt` |
| **数据底表** | `a02_e2e_boss_performance_summary_d` |
| **筛选条件** | `calc_type = fulfillment`，按 `store_region` 或 `store_type` 分组（支持展开到 `shop_code`） |
| **数据类型** | integer → 整数，千分位整数 |
| **数据格式** | `#,##0` |

---

### 20. Overdue% — O2O超时订单率

| 项目 | 内容 |
|---|---|
| **指标名称** | Overdue% |
| **指标名称中文** | O2O超时订单率 |
| **业务定义** | 超时订单量占顾客下单的总订单的比例 by region/store type/store 拆分统计 |
| **计算公式** | sum(o2o_fulfillment_unshipped_overdue_order_cnt) / sum(o2o_fulfillment_request_order_cnt) |
| **分子** | `o2o_fulfillment_unshipped_overdue_order_cnt` |
| **分母** | `o2o_fulfillment_request_order_cnt` |
| **数据底表** | `a02_e2e_boss_performance_summary_d` |
| **筛选条件** | `calc_type = fulfillment`，按 `store_region` 或 `store_type` 分组（支持展开到 `shop_code`） |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

---

### 21. Cancelled Order by Customer — O2O顾客取消的订单数量

| 项目 | 内容 |
|---|---|
| **指标名称** | Cancelled Order by Customer |
| **指标名称中文** | O2O顾客取消的订单数量 |
| **业务定义** | 根据订单付款时间，状态包含消费者取消，顾客取消订单的订单数量 by region/store type/store 拆分统计 |
| **计算公式** | sum(o2o_fulfillment_unshipped_customer_cancelled_order_cnt) |
| **统计字段** | `o2o_fulfillment_unshipped_customer_cancelled_order_cnt` |
| **数据底表** | `a02_e2e_boss_performance_summary_d` |
| **筛选条件** | `calc_type = fulfillment`，按 `store_region` 或 `store_type` 分组（支持展开到 `shop_code`） |
| **数据类型** | integer → 整数，千分位整数 |
| **数据格式** | `#,##0` |

---

### 22. Customer% — O2O顾客取消订单率

| 项目 | 内容 |
|---|---|
| **指标名称** | Customer% |
| **指标名称中文** | O2O顾客取消订单率 |
| **业务定义** | 顾客取消订单量占顾客下单的总订单的比例 by region/store type/store 拆分统计 |
| **计算公式** | sum(o2o_fulfillment_unshipped_customer_cancelled_order_cnt) / sum(o2o_fulfillment_request_order_cnt) |
| **分子** | `o2o_fulfillment_unshipped_customer_cancelled_order_cnt` |
| **分母** | `o2o_fulfillment_request_order_cnt` |
| **数据底表** | `a02_e2e_boss_performance_summary_d` |
| **筛选条件** | `calc_type = fulfillment`，按 `store_region` 或 `store_type` 分组（支持展开到 `shop_code`） |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

---

### 23. Cancelled Order by Other — O2O其他原因失败的订单数量

| 项目 | 内容 |
|---|---|
| **指标名称** | Cancelled Order by Other |
| **指标名称中文** | O2O其他原因失败的订单数量 |
| **业务定义** | 根据订单付款时间，状态包含平台修改地址或商品，人工撤回，门店歇业的订单数量 by region/store type/store 拆分统计 |
| **计算公式** | sum(o2o_fulfillment_unshipped_others_order_cnt) |
| **统计字段** | `o2o_fulfillment_unshipped_others_order_cnt` |
| **数据底表** | `a02_e2e_boss_performance_summary_d` |
| **筛选条件** | `calc_type = fulfillment`，按 `store_region` 或 `store_type` 分组（支持展开到 `shop_code`） |
| **数据类型** | integer → 整数，千分位整数 |
| **数据格式** | `#,##0` |

---

### 24. Other% — O2O其他失败订单率

| 项目 | 内容 |
|---|---|
| **指标名称** | Other% |
| **指标名称中文** | O2O其他失败订单率 |
| **业务定义** | 其他原因失败的订单量占顾客下单的总订单的比例 by region/store type/store 拆分统计 |
| **计算公式** | sum(o2o_fulfillment_unshipped_others_order_cnt) / sum(o2o_fulfillment_request_order_cnt) |
| **分子** | `o2o_fulfillment_unshipped_others_order_cnt` |
| **分母** | `o2o_fulfillment_request_order_cnt` |
| **数据底表** | `a02_e2e_boss_performance_summary_d` |
| **筛选条件** | `calc_type = fulfillment`，按 `store_region` 或 `store_type` 分组（支持展开到 `shop_code`） |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

---

### 25. Failed Request — O2O门店订单失败次数

| 项目 | 内容 |
|---|---|
| **指标名称** | Failed Request |
| **指标名称中文** | O2O门店订单失败次数 |
| **业务定义** | 根据订单付款时间，统计订单流转到门店的次数（不去重） by region/store type/store 拆分统计 |
| **计算公式** | sum(o2o_fulfillment_request_failed_times) |
| **统计字段** | `o2o_fulfillment_request_failed_times` |
| **数据底表** | `a02_e2e_boss_performance_summary_d` |
| **筛选条件** | `calc_type = fulfillment`，按 `store_region` 或 `store_type` 分组（支持展开到 `shop_code`） |
| **数据类型** | integer → 整数，千分位整数 |
| **数据格式** | `#,##0` |

---

### 26. Failed% — O2O门店订单失败率

| 项目 | 内容 |
|---|---|
| **指标名称** | Failed% |
| **指标名称中文** | O2O门店订单失败率 |
| **业务定义** | 根据订单付款时间，订单流转到门店的次数（不去重）占总请求门店次数的比例 by region/store type/store 拆分统计 |
| **计算公式** | sum(o2o_fulfillment_request_failed_times) / sum(o2o_fulfillment_request_times) |
| **分子** | `o2o_fulfillment_request_failed_times` |
| **分母** | `o2o_fulfillment_request_times` |
| **数据底表** | `a02_e2e_boss_performance_summary_d` |
| **筛选条件** | `calc_type = fulfillment`，按 `store_region` 或 `store_type` 分组（支持展开到 `shop_code`） |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

---

### 27. Inventory — 商品库存件数

| 项目 | 内容 |
|---|---|
| **指标名称** | Inventory |
| **指标名称中文** | 商品库存件数 |
| **业务定义** | 截止统计结束时间的期末库存数量 = 买货数量 − 销售数量 by region/store type/store 拆分统计 |
| **计算公式** | sum(stock_qty) |
| **统计字段** | `stock_qty` |
| **数据底表** | `a02_e2e_boss_performance_summary_d` |
| **筛选条件** | `calc_type = fulfillment`，选择 Region 则聚合在 `store_region` 粒度；选择 Store Type 则聚合在 `store_type` 粒度（支持展开到 `shop_code`） |
| **数据类型** | integer → 整数，千分位整数 |
| **数据格式** | `#,##0` |

---

### 28. BSR Inventory — BSR商品库存件数

| 项目 | 内容 |
|---|---|
| **指标名称** | BSR Inventory |
| **指标名称中文** | BSR商品库存件数 |
| **业务定义** | 截止统计结束时间的期末库存数量 = 买货数量 − 销售数量（BSR类型的商品） by region/store type/store 拆分统计 |
| **计算公式** | sum(bsr_stock_qty) |
| **统计字段** | `bsr_stock_qty` |
| **数据底表** | `a02_e2e_boss_performance_summary_d` |
| **筛选条件** | `calc_type = fulfillment`，按 `store_region` 或 `store_type` 分组（支持展开到 `shop_code`） |
| **数据类型** | integer → 整数，千分位整数 |
| **数据格式** | `#,##0` |

---

### 29. Seasonal Inventory — Seasonal商品库存件数

| 项目 | 内容 |
|---|---|
| **指标名称** | Seasonal Inventory |
| **指标名称中文** | Seasonal商品库存件数 |
| **业务定义** | 截止统计结束时间的期末库存数量 = 买货数量 − 销售数量（Seasonal类型的商品） by region/store type/store 拆分统计 |
| **计算公式** | sum(seasonal_stock_qty) |
| **统计字段** | `seasonal_stock_qty` |
| **数据底表** | `a02_e2e_boss_performance_summary_d` |
| **筛选条件** | `calc_type = fulfillment`，按 `store_region` 或 `store_type` 分组（支持展开到 `shop_code`） |
| **数据类型** | integer → 整数，千分位整数 |
| **数据格式** | `#,##0` |

---

## 通用规则汇总

| 规则项 | 说明 |
|---|---|
| **数据底表** | `a02_e2e_boss_performance_summary_d`、`a02_e2e_boss_fulfillment_request_data_d`、`a02_e2e_boss_fulfillment_fail_reason_d`、`t01_o2o_fulfillment_order_detail_d` |
| **筛选逻辑** | 统一包含 `calc_type = payment` 或 `calc_type = fulfillment`；Fulfillment% Trend 子模块的 `calc_type = fulfillment` 为固定筛选 |
| **货币转换规则** | 数据源默认为 RMB，转化为美元需要除以固定值 7 |
| **派生指标** | LY（去年同期）、vs LY / YOY（同比）、占比等为派生指标，依据基础指标计算生成；YOY / vs LY 同比口径统一为 `今年 / 去年 − 1`（金额/数量类）或 `今年 − 去年`（差值，bp 指标，展示时 ×100 转 bp，仅用于率类指标） |
| **分组维度** | 根据 `store_region`、`store_type`、`timeframe`、`failure_remark` 分组；`store_region`/`store_type` 粒度行支持展开看 `shop_code` 粒度明细数据 |
| **必须遵守** | 口径文档中定义的所有指标，必须遵守其数据类型和数据格式，如果和解决方案中存在争议的，一切以口径文档为准，必须按照口径文档中的格式进行调整 |
| **DAX 语法规范** | 文本常量必须使用双引号 `" "`，禁止使用单引号；单引号 `' '` 仅用于表名，列名使用方括号 `[ ]`，例如：`[calc_type] = "payment"` |
