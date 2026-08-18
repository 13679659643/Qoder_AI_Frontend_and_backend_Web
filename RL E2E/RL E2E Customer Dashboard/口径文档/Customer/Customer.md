# Customer Dashboard 指标口径提示词

> **Dashboard**: Customer Dashboard  
> **Tab**: Customer  
> **数据底表**: `a03_e2e_customer_data_m` / `t05_customer_order_data_d` / `a03_e2e_customer_order_correlation_data_m` / `a03_e2e_customer_time_ordered_data_m`  
> **模块说明**: 本板块为客户核心看板，覆盖 Customer KPI、Performance Indicator、Customer Breakdown、ACV Breakdown、AUR Breakdown、Freq. Breakdown、UPT Breakdown、Class x Label Drilldown、Co-Purchase Matrix、Product Path 等子板块，统计 DCom 新客、买家人数、净销售额、销售额、客单价、件单价、购买频次、客单件及连带率等。

---

## 全局逻辑

| 项目 | 内容 |
|---|---|
| **数据底表** | `a03_e2e_customer_data_m`、`t05_customer_order_data_d`、`a03_e2e_customer_order_correlation_data_m`、`a03_e2e_customer_time_ordered_data_m` |
| **筛选逻辑** | Net 维度基于 `net_pay_amt` / `net_pay_qty` / `net_pay_order_cnt`；Demand 维度基于 `pay_amt` / `pay_qty` / `pay_order_cnt`；会员统一 `is_member = 0`（非会员） |
| **聚合粒度** | 数字卡片：所选时间范围 `data_date`；表格：所选时间范围 `data_date`，按对应维度聚合 |
| **货币转换规则** | 数据源默认为 RMB，转化为美元需要除以固定值 7 |
| **派生指标** | LY（去年同期）、LP（上期）、vs LY（同比）、vs LP（环比）、占比等为派生指标，依据基础指标计算生成 |
| **必须遵守** | 口径文档中定义的所有指标，必须遵守其数据类型和数据格式，如果和解决方案中存在争议的，一切以口径文档为准，必须按照口径文档中的格式进行调整 |
| **data_date = 所选时间范围** | 涉及到t05_customer_order_data_d表计算，data_date = 所选时间范围，所选时间范围的计算,data_date ∈ [__TimeMin, __TimeMax]（全局时间范围），Slicer_Time_Frame_Min和Slicer_Time_Frame_Max维度表已经给出了具体的TimeFrame_Min和TimeFrame_Max值 |

---

## 子模块一：Customer KPI

> **无分组维度**: 只受到筛选器影响，没有分组维度，用于制作卡片图。

### 1. DCom New Customer No. — DCom新客数

| 项目 | 内容 |
|---|---|
| **指标名称** | DCom New Customer No. |
| **指标名称中文** | DCom新客数 |
| **业务定义** | DCom新客数 |
| **计算公式** | count(distinct user_id) |
| **统计字段** | `user_id` |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `customer_type = new`，`sum(net_pay_amt) > 0`，`is_member = 0` |
| **聚合粒度** | `data_date = 所选时间范围`，`platform, shop_info_id` |
| **数据类型** | integer → 整数，千分位整数 |
| **数据格式** | `#,##0` |

### 1.1 DCom New Customer No. vs LY — DCom新客数同比

| 项目 | 内容 |
|---|---|
| **指标名称** | DCom New Customer No. vs LY |
| **指标名称中文** | DCom新客数同比 |
| **业务定义** | DCom新客数今年较去年同期的变化率 |
| **计算公式** | 今年 / 去年 - 1 |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `customer_type = new`，`sum(net_pay_amt) > 0`，`is_member = 0` |
| **聚合粒度** | `data_date = 所选时间范围`，`platform, shop_info_id` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

### 1.2 DCom New Customer No. vs LP — DCom新客数环比

| 项目 | 内容 |
|---|---|
| **指标名称** | DCom New Customer No. vs LP |
| **指标名称中文** | DCom新客数环比 |
| **业务定义** | DCom新客数当期较上期的变化率 |
| **计算公式** | 当期 / 上期 - 1 |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `customer_type = new`，`sum(net_pay_amt) > 0`，`is_member = 0` |
| **聚合粒度** | `data_date = 所选时间范围`，`platform, shop_info_id` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

### 1.3 Customer Monthly TAR ACH% — 月度目标达成率

| 项目 | 内容 |
|---|---|
| **指标名称** | Customer Monthly TAR ACH% |
| **指标名称中文** | 月度目标达成率 |
| **业务定义** | 暂无逻辑，占位，等逻辑确认后再填充 |
| **计算公式** | 待补充 |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `customer_type = new`，`sum(net_pay_amt) > 0`，`is_member = 0` |
| **聚合粒度** | `data_date = 所选时间范围`，`platform, shop_info_id` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，含正负号 |
| **数据格式** | `+#,##0.0%;-#,##0.0%;0.0%` |

### 1.4 Customer Yearly TAR ACH% — 年度目标达成率

| 项目 | 内容 |
|---|---|
| **指标名称** | Customer Yearly TAR ACH% |
| **指标名称中文** | 年度目标达成率 |
| **业务定义** | 暂无逻辑，占位，等逻辑确认后再填充 |
| **计算公式** | 待补充 |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `customer_type = new`，`sum(net_pay_amt) > 0`，`is_member = 0` |
| **聚合粒度** | `data_date = 所选时间范围`，`platform, shop_info_id` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，含正负号 |
| **数据格式** | `+#,##0.0%;-#,##0.0%;0.0%` |

---

### 2. DCom New Customer% — DCom新客占比

| 项目 | 内容 |
|---|---|
| **指标名称** | DCom New Customer% |
| **指标名称中文** | DCom新客占比 |
| **业务定义** | DCom新客数/DCom总客数 |
| **计算公式** | 分子：count(distinct user_id) where customer_type = new；分母：count(distinct user_id) |
| **分子** | `user_id`（`customer_type = new`） |
| **分母** | `user_id`（全部） |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `sum(net_pay_amt) > 0`，`is_member = 0` |
| **聚合粒度** | `data_date = 所选时间范围`，`platform, shop_info_id` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

### 2.1 DCom New Customer% vs LY — DCom新客占比同比

| 项目 | 内容 |
|---|---|
| **指标名称** | DCom New Customer% vs LY |
| **指标名称中文** | DCom新客占比同比 |
| **业务定义** | DCom新客占比今年较去年同期的变化（差值） |
| **计算公式** | 今年 - 去年（差值，展示时 ×100 转 pts） |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `sum(net_pay_amt) > 0`，`is_member = 0` |
| **聚合粒度** | `data_date = 所选时间范围`，`platform, shop_info_id` |
| **数据类型** | delta_pts → 增减基点整数： → +120pts / -80pts（基点，含正负号，值×100 转 pts）,乘以100的操作可以放在Cell Display度量中实现，算同比LY：当期值 − 同期值（差值，pts 指标，展示时 ×100 转 pts） |        
| **数据格式** | `+#,##0pts;-#,##0pts;0pts` |

### 2.2 DCom New Customer% vs LP — DCom新客占比环比

| 项目 | 内容 |
|---|---|
| **指标名称** | DCom New Customer% vs LP |
| **指标名称中文** | DCom新客占比环比 |
| **业务定义** | DCom新客占比当期较上期的变化（差值） |
| **计算公式** | 当期 - 上期（差值，展示时 ×100 转 pts） |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `sum(net_pay_amt) > 0`，`is_member = 0` |
| **聚合粒度** | `data_date = 所选时间范围`，`platform, shop_info_id` |
| **数据类型** | delta_pts → 增减基点整数： → +120pts / -80pts（基点，含正负号，值×100 转 pts）,乘以100的操作可以放在Cell Display度量中实现，算环比LP：当期值 − 上期值（差值，pts 指标，展示时 ×100 转 pts） |        
| **数据格式** | `+#,##0pts;-#,##0pts;0pts` |

### 2.3 Customer% Monthly TAR ACH% — 月度目标达成率

| 项目 | 内容 |
|---|---|
| **指标名称** | Customer% Monthly TAR ACH% |
| **指标名称中文** | 月度目标达成率 |
| **业务定义** | 暂无逻辑，占位，等逻辑确认后再填充 |
| **计算公式** | 待补充 |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `sum(net_pay_amt) > 0`，`is_member = 0` |
| **聚合粒度** | `data_date = 所选时间范围`，`platform, shop_info_id` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，含正负号 |
| **数据格式** | `+#,##0.0%;-#,##0.0%;0.0%` |

### 2.4 Customer% Yearly TAR ACH% — 年度目标达成率

| 项目 | 内容 |
|---|---|
| **指标名称** | Customer% Yearly TAR ACH% |
| **指标名称中文** | 年度目标达成率 |
| **业务定义** | 暂无逻辑，占位，等逻辑确认后再填充 |
| **计算公式** | 待补充 |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `sum(net_pay_amt) > 0`，`is_member = 0` |
| **聚合粒度** | `data_date = 所选时间范围`，`platform, shop_info_id` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，含正负号 |
| **数据格式** | `+#,##0.0%;-#,##0.0%;0.0%` |

---

## 子模块二：Performance Indicator

> **无分组维度**: 只受到筛选器影响，没有分组维度，用于制作卡片图。按 Net / Demand 维度区分。

### 1. DCom SLS（Net） — DCom净销售额

| 项目 | 内容 |
|---|---|
| **指标名称** | DCom SLS |
| **指标名称中文** | DCom净销售额 |
| **业务定义** | DCom净销售额=DCom销售订单总销售额-退货额 |
| **计算公式** | sum(net_pay_amt) |
| **统计字段** | `net_pay_amt` |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `is_member = 0`，`customer_type = new/exists` |
| **聚合粒度** | `data_date = 所选时间范围`，`platform, shop_info_id` |
| **数据类型** | currency → 货币符号由币种切片器决定，千分位整数 |
| **数据格式** | `#,##0`（在 DAX 中用 `__CurrencySymbol & FORMAT(__Value, "#,##0")` 拼接币种符号） |

### 1.1 DCom SLS vs LY（Net） — DCom净销售额同比

| 项目 | 内容 |
|---|---|
| **指标名称** | DCom SLS vs LY |
| **指标名称中文** | DCom净销售额同比 |
| **业务定义** | DCom净销售额今年较去年同期的变化率 |
| **计算公式** | 今年 / 去年 - 1 |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `is_member = 0`，`customer_type = new/exists` |
| **聚合粒度** | `data_date = 所选时间范围`，`platform, shop_info_id` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

### 1.2 DCom SLS vs LP（Net） — DCom净销售额环比

| 项目 | 内容 |
|---|---|
| **指标名称** | DCom SLS vs LP |
| **指标名称中文** | DCom净销售额环比 |
| **业务定义** | DCom净销售额当期较上期的变化率 |
| **计算公式** | 当期 / 上期 - 1 |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `is_member = 0`，`customer_type = new/exists` |
| **聚合粒度** | `data_date = 所选时间范围`，`platform, shop_info_id` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

---


## 通用规则汇总

| 规则项 | 说明 |
|---|---|
| **数据底表** | `a03_e2e_customer_data_m`、`t05_customer_order_data_d`、`a03_e2e_customer_order_correlation_data_m`、`a03_e2e_customer_time_ordered_data_m` |
| **筛选逻辑** | Net 维度基于 `net_pay_amt` / `net_pay_qty` / `net_pay_order_cnt`；Demand 维度基于 `pay_amt` / `pay_qty` / `pay_order_cnt`；会员统一 `is_member = 0`（非会员） |
| **货币转换规则** | 数据源默认为 RMB，转化为美元需要除以固定值 7 |
| **派生指标** | LY（去年同期）、LP（上期）、vs LY（同比）、vs LP（环比）、占比等为派生指标，依据基础指标计算生成 |
| **分组维度** | 根据 `platform, shop_info_id`、`brand, framework` 分组 |
| **必须遵守** | 口径文档中定义的所有指标，必须遵守其数据类型和数据格式，如果和解决方案中存在争议的，一切以口径文档为准，必须按照口径文档中的格式进行调整 |
| **DAX 语法规范** | 文本常量必须使用双引号 `" "`，禁止使用单引号；单引号 `' '` 仅用于表名，列名使用方括号 `[ ]`，例如：`[is_member] = 0` |
| **pts 与 bp 区别** | pts 指标：值×100 转 pts（基点，含正负号），数据格式 `+#,##0pts;-#,##0pts;0pts`；bp 指标：值×10000 转 bp，数据格式 `+#,##0bp;-#,##0bp;0bp` |
| **TAR ACH%实现** | 实现方式：SUMX+SUMMARIZE，SUMMARIZE 按所需维度分组去重，再 SUMX 求和；DISTINCT 返回表非标量，不能在 SUMX 内当值用，用 SUMMARIZE 分组等价实现 DISTINCT 去重后再 SUM |
