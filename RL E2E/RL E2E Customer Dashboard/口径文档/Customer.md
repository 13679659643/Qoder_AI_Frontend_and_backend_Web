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
| **聚合粒度** | 数字卡片：所选时间范围 `dt`；表格：所选时间范围 `dt`，按对应维度聚合 |
| **货币转换规则** | 数据源默认为 RMB，转化为美元需要除以固定值 7 |
| **派生指标** | LY（去年同期）、LP（上期）、vs LY（同比）、vs LP（环比）、占比等为派生指标，依据基础指标计算生成 |
| **必须遵守** | 口径文档中定义的所有指标，必须遵守其数据类型和数据格式，如果和解决方案中存在争议的，一切以口径文档为准，必须按照口径文档中的格式进行调整 |

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
| **聚合粒度** | `dt = 所选时间范围`，`platform, shop_info_id` |
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
| **聚合粒度** | `dt = 所选时间范围`，`platform, shop_info_id` |
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
| **聚合粒度** | `dt = 所选时间范围`，`platform, shop_info_id` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

### 1.3 Monthly TAR ACH% — 月度目标达成率

| 项目 | 内容 |
|---|---|
| **指标名称** | Monthly TAR ACH% |
| **指标名称中文** | 月度目标达成率 |
| **业务定义** | 暂无逻辑，占位，等逻辑确认后再填充 |
| **计算公式** | 待补充 |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `customer_type = new`，`sum(net_pay_amt) > 0`，`is_member = 0` |
| **聚合粒度** | `dt = 所选时间范围`，`platform, shop_info_id` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，含正负号 |
| **数据格式** | `+#,##0.0%;-#,##0.0%;0.0%` |

### 1.4 Yearly TAR ACH% — 年度目标达成率

| 项目 | 内容 |
|---|---|
| **指标名称** | Yearly TAR ACH% |
| **指标名称中文** | 年度目标达成率 |
| **业务定义** | 暂无逻辑，占位，等逻辑确认后再填充 |
| **计算公式** | 待补充 |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `customer_type = new`，`sum(net_pay_amt) > 0`，`is_member = 0` |
| **聚合粒度** | `dt = 所选时间范围`，`platform, shop_info_id` |
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
| **聚合粒度** | `dt = 所选时间范围`，`platform, shop_info_id` |
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
| **聚合粒度** | `dt = 所选时间范围`，`platform, shop_info_id` |
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
| **聚合粒度** | `dt = 所选时间范围`，`platform, shop_info_id` |
| **数据类型** | delta_pts → 增减基点整数： → +120pts / -80pts（基点，含正负号，值×100 转 pts）,乘以100的操作可以放在Cell Display度量中实现，算环比LP：当期值 − 上期值（差值，pts 指标，展示时 ×100 转 pts） |        
| **数据格式** | `+#,##0pts;-#,##0pts;0pts` |

### 2.3 Monthly TAR ACH% — 月度目标达成率

| 项目 | 内容 |
|---|---|
| **指标名称** | Monthly TAR ACH% |
| **指标名称中文** | 月度目标达成率 |
| **业务定义** | 暂无逻辑，占位，等逻辑确认后再填充 |
| **计算公式** | 待补充 |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `sum(net_pay_amt) > 0`，`is_member = 0` |
| **聚合粒度** | `dt = 所选时间范围`，`platform, shop_info_id` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，含正负号 |
| **数据格式** | `+#,##0.0%;-#,##0.0%;0.0%` |

### 2.4 Yearly TAR ACH% — 年度目标达成率

| 项目 | 内容 |
|---|---|
| **指标名称** | Yearly TAR ACH% |
| **指标名称中文** | 年度目标达成率 |
| **业务定义** | 暂无逻辑，占位，等逻辑确认后再填充 |
| **计算公式** | 待补充 |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `sum(net_pay_amt) > 0`，`is_member = 0` |
| **聚合粒度** | `dt = 所选时间范围`，`platform, shop_info_id` |
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
| **聚合粒度** | `dt = 所选时间范围`，`platform, shop_info_id` |
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
| **聚合粒度** | `dt = 所选时间范围`，`platform, shop_info_id` |
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
| **聚合粒度** | `dt = 所选时间范围`，`platform, shop_info_id` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

---

### 2. Customer No.（Net） — 买家人数

| 项目 | 内容 |
|---|---|
| **指标名称** | Customer No. |
| **指标名称中文** | 买家人数 |
| **业务定义** | 净购买买家人数 |
| **计算公式** | count(distinct user_id) |
| **统计字段** | `user_id` |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `sum(net_pay_amt) > 0`，`is_member = 0`，`customer_type = new/exists` |
| **聚合粒度** | `dt = 所选时间范围`，`platform, shop_info_id` |
| **数据类型** | integer → 整数，千分位整数 |
| **数据格式** | `#,##0` |

### 2.1 Customer No. vs LY（Net） — 买家人数同比

| 项目 | 内容 |
|---|---|
| **指标名称** | Customer No. vs LY |
| **指标名称中文** | 买家人数同比 |
| **业务定义** | 买家人数今年较去年同期的变化率 |
| **计算公式** | 今年 / 去年 - 1 |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `sum(net_pay_amt) > 0`，`is_member = 0`，`customer_type = new/exists` |
| **聚合粒度** | `dt = 所选时间范围`，`platform, shop_info_id` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

### 2.2 Customer No. vs LP（Net） — 买家人数环比

| 项目 | 内容 |
|---|---|
| **指标名称** | Customer No. vs LP |
| **指标名称中文** | 买家人数环比 |
| **业务定义** | 买家人数当期较上期的变化率 |
| **计算公式** | 当期 / 上期 - 1 |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `sum(net_pay_amt) > 0`，`is_member = 0`，`customer_type = new/exists` |
| **聚合粒度** | `dt = 所选时间范围`，`platform, shop_info_id` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

---

### 3. ACV（Net） — 客单价

| 项目 | 内容 |
|---|---|
| **指标名称** | ACV |
| **指标名称中文** | 客单价 |
| **业务定义** | 净销售金额/净购买买家人数 |
| **计算公式** | 分子：sum(net_pay_amt)；分母：count(distinct user_id) |
| **分子** | `net_pay_amt` |
| **分母** | `user_id` |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `sum(net_pay_amt) > 0`，`is_member = 0`，`customer_type = new/exists` |
| **聚合粒度** | `dt = 所选时间范围`，`platform, shop_info_id` |
| **数据类型** | currency → 货币符号由币种切片器决定，千分位整数 |
| **数据格式** | `#,##0`（在 DAX 中用 `__CurrencySymbol & FORMAT(__Value, "#,##0")` 拼接币种符号） |

### 3.1 ACV vs LY（Net） — 客单价同比

| 项目 | 内容 |
|---|---|
| **指标名称** | ACV vs LY |
| **指标名称中文** | 客单价同比 |
| **业务定义** | 客单价今年较去年同期的变化率 |
| **计算公式** | 今年 / 去年 - 1 |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `sum(net_pay_amt) > 0`，`is_member = 0`，`customer_type = new/exists` |
| **聚合粒度** | `dt = 所选时间范围`，`platform, shop_info_id` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

### 3.2 ACV vs LP（Net） — 客单价环比

| 项目 | 内容 |
|---|---|
| **指标名称** | ACV vs LP |
| **指标名称中文** | 客单价环比 |
| **业务定义** | 客单价当期较上期的变化率 |
| **计算公式** | 当期 / 上期 - 1 |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `sum(net_pay_amt) > 0`，`is_member = 0`，`customer_type = new/exists` |
| **聚合粒度** | `dt = 所选时间范围`，`platform, shop_info_id` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

---

### 4. AUR（Net） — 件单价

| 项目 | 内容 |
|---|---|
| **指标名称** | AUR |
| **指标名称中文** | 件单价 |
| **业务定义** | 净销售金额/商品净出库件数 |
| **计算公式** | 分子：sum(net_pay_amt)；分母：sum(net_pay_qty) |
| **分子** | `net_pay_amt` |
| **分母** | `net_pay_qty` |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `is_member = 0`，`customer_type = new/exists` |
| **聚合粒度** | `dt = 所选时间范围`，`platform, shop_info_id` |
| **数据类型** | currency → 货币符号由币种切片器决定，千分位整数 |
| **数据格式** | `#,##0`（在 DAX 中用 `__CurrencySymbol & FORMAT(__Value, "#,##0")` 拼接币种符号） |

### 4.1 AUR vs LY（Net） — 件单价同比

| 项目 | 内容 |
|---|---|
| **指标名称** | AUR vs LY |
| **指标名称中文** | 件单价同比 |
| **业务定义** | 件单价今年较去年同期的变化率 |
| **计算公式** | 今年 / 去年 - 1 |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `is_member = 0`，`customer_type = new/exists` |
| **聚合粒度** | `dt = 所选时间范围`，`platform, shop_info_id` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

### 4.2 AUR vs LP（Net） — 件单价环比

| 项目 | 内容 |
|---|---|
| **指标名称** | AUR vs LP |
| **指标名称中文** | 件单价环比 |
| **业务定义** | 件单价当期较上期的变化率 |
| **计算公式** | 当期 / 上期 - 1 |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `is_member = 0`，`customer_type = new/exists` |
| **聚合粒度** | `dt = 所选时间范围`，`platform, shop_info_id` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

---

### 5. Freq.（Net） — 购买频次

| 项目 | 内容 |
|---|---|
| **指标名称** | Freq. |
| **指标名称中文** | 购买频次 |
| **业务定义** | 净订单数/净购买买家人数 |
| **计算公式** | 分子：sum(net_pay_order_cnt)；分母：count(distinct user_id) |
| **分子** | `net_pay_order_cnt` |
| **分母** | `user_id` |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `sum(net_pay_amt) > 0`，`is_member = 0`，`customer_type = new/exists` |
| **聚合粒度** | `dt = 所选时间范围`，`platform, shop_info_id` |
| **数据类型** | decimal_1dp → 小数，保留一位小数，千分位 |
| **数据格式** | `#,##0.0` |

### 5.1 Freq. vs LY（Net） — 购买频次同比

| 项目 | 内容 |
|---|---|
| **指标名称** | Freq. vs LY |
| **指标名称中文** | 购买频次同比 |
| **业务定义** | 购买频次今年较去年同期的变化率 |
| **计算公式** | 今年 / 去年 - 1 |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `sum(net_pay_amt) > 0`，`is_member = 0`，`customer_type = new/exists` |
| **聚合粒度** | `dt = 所选时间范围`，`platform, shop_info_id` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

### 5.2 Freq. vs LP（Net） — 购买频次环比

| 项目 | 内容 |
|---|---|
| **指标名称** | Freq. vs LP |
| **指标名称中文** | 购买频次环比 |
| **业务定义** | 购买频次当期较上期的变化率 |
| **计算公式** | 当期 / 上期 - 1 |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `sum(net_pay_amt) > 0`，`is_member = 0`，`customer_type = new/exists` |
| **聚合粒度** | `dt = 所选时间范围`，`platform, shop_info_id` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

---

### 6. UPT（Net） — 客单件

| 项目 | 内容 |
|---|---|
| **指标名称** | UPT |
| **指标名称中文** | 客单件 |
| **业务定义** | 商品净出库件数/净出库订单数 |
| **计算公式** | 分子：sum(net_pay_qty)；分母：sum(net_pay_order_cnt) |
| **分子** | `net_pay_qty` |
| **分母** | `net_pay_order_cnt` |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `is_member = 0`，`customer_type = new/exists` |
| **聚合粒度** | `dt = 所选时间范围`，`platform, shop_info_id` |
| **数据类型** | decimal_1dp → 小数，保留一位小数，千分位 |
| **数据格式** | `#,##0.0` |

### 6.1 UPT vs LY（Net） — 客单件同比

| 项目 | 内容 |
|---|---|
| **指标名称** | UPT vs LY |
| **指标名称中文** | 客单件同比 |
| **业务定义** | 客单件今年较去年同期的变化率 |
| **计算公式** | 今年 / 去年 - 1 |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `is_member = 0`，`customer_type = new/exists` |
| **聚合粒度** | `dt = 所选时间范围`，`platform, shop_info_id` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

### 6.2 UPT vs LP（Net） — 客单件环比

| 项目 | 内容 |
|---|---|
| **指标名称** | UPT vs LP |
| **指标名称中文** | 客单件环比 |
| **业务定义** | 客单件当期较上期的变化率 |
| **计算公式** | 当期 / 上期 - 1 |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `is_member = 0`，`customer_type = new/exists` |
| **聚合粒度** | `dt = 所选时间范围`，`platform, shop_info_id` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

---

### 7. DCom SLS（Demand） — DCom销售额

| 项目 | 内容 |
|---|---|
| **指标名称** | DCom SLS |
| **指标名称中文** | DCom销售额 |
| **业务定义** | DCom销售额 |
| **计算公式** | sum(pay_amt) |
| **统计字段** | `pay_amt` |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `is_member = 0`，`customer_type = new/exists` |
| **聚合粒度** | `dt = 所选时间范围`，`platform, shop_info_id` |
| **数据类型** | currency → 货币符号由币种切片器决定，千分位整数 |
| **数据格式** | `#,##0`（在 DAX 中用 `__CurrencySymbol & FORMAT(__Value, "#,##0")` 拼接币种符号） |

### 7.1 DCom SLS vs LY（Demand） — DCom销售额同比

| 项目 | 内容 |
|---|---|
| **指标名称** | DCom SLS vs LY |
| **指标名称中文** | DCom销售额同比 |
| **业务定义** | DCom销售额今年较去年同期的变化率 |
| **计算公式** | 今年 / 去年 - 1 |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `is_member = 0`，`customer_type = new/exists` |
| **聚合粒度** | `dt = 所选时间范围`，`platform, shop_info_id` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

### 7.2 DCom SLS vs LP（Demand） — DCom销售额环比

| 项目 | 内容 |
|---|---|
| **指标名称** | DCom SLS vs LP |
| **指标名称中文** | DCom销售额环比 |
| **业务定义** | DCom销售额当期较上期的变化率 |
| **计算公式** | 当期 / 上期 - 1 |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `is_member = 0`，`customer_type = new/exists` |
| **聚合粒度** | `dt = 所选时间范围`，`platform, shop_info_id` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

---

### 8. Customer No.（Demand） — 买家人数

| 项目 | 内容 |
|---|---|
| **指标名称** | Customer No. |
| **指标名称中文** | 买家人数 |
| **业务定义** | 买家人数 |
| **计算公式** | count(distinct user_id) |
| **统计字段** | `user_id` |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `sum(pay_amt) > 0`，`is_member = 0`，`customer_type = new/exists` |
| **聚合粒度** | `dt = 所选时间范围`，`platform, shop_info_id` |
| **数据类型** | integer → 整数，千分位整数 |
| **数据格式** | `#,##0` |

### 8.1 Customer No. vs LY（Demand） — 买家人数同比

| 项目 | 内容 |
|---|---|
| **指标名称** | Customer No. vs LY |
| **指标名称中文** | 买家人数同比 |
| **业务定义** | 买家人数今年较去年同期的变化率 |
| **计算公式** | 今年 / 去年 - 1 |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `sum(pay_amt) > 0`，`is_member = 0`，`customer_type = new/exists` |
| **聚合粒度** | `dt = 所选时间范围`，`platform, shop_info_id` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

### 8.2 Customer No. vs LP（Demand） — 买家人数环比

| 项目 | 内容 |
|---|---|
| **指标名称** | Customer No. vs LP |
| **指标名称中文** | 买家人数环比 |
| **业务定义** | 买家人数当期较上期的变化率 |
| **计算公式** | 当期 / 上期 - 1 |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `sum(pay_amt) > 0`，`is_member = 0`，`customer_type = new/exists` |
| **聚合粒度** | `dt = 所选时间范围`，`platform, shop_info_id` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

---

### 9. ACV（Demand） — 客单价

| 项目 | 内容 |
|---|---|
| **指标名称** | ACV |
| **指标名称中文** | 客单价 |
| **业务定义** | 销售金额/买家人数 |
| **计算公式** | 分子：sum(pay_amt)；分母：count(distinct user_id) |
| **分子** | `pay_amt` |
| **分母** | `user_id` |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `sum(pay_amt) > 0`，`is_member = 0`，`customer_type = new/exists` |
| **聚合粒度** | `dt = 所选时间范围`，`platform, shop_info_id` |
| **数据类型** | currency → 货币符号由币种切片器决定，千分位整数 |
| **数据格式** | `#,##0`（在 DAX 中用 `__CurrencySymbol & FORMAT(__Value, "#,##0")` 拼接币种符号） |

### 9.1 ACV vs LY（Demand） — 客单价同比

| 项目 | 内容 |
|---|---|
| **指标名称** | ACV vs LY |
| **指标名称中文** | 客单价同比 |
| **业务定义** | 客单价今年较去年同期的变化率 |
| **计算公式** | 今年 / 去年 - 1 |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `sum(pay_amt) > 0`，`is_member = 0`，`customer_type = new/exists` |
| **聚合粒度** | `dt = 所选时间范围`，`platform, shop_info_id` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

### 9.2 ACV vs LP（Demand） — 客单价环比

| 项目 | 内容 |
|---|---|
| **指标名称** | ACV vs LP |
| **指标名称中文** | 客单价环比 |
| **业务定义** | 客单价当期较上期的变化率 |
| **计算公式** | 当期 / 上期 - 1 |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `sum(pay_amt) > 0`，`is_member = 0`，`customer_type = new/exists` |
| **聚合粒度** | `dt = 所选时间范围`，`platform, shop_info_id` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

---

### 10. AUR（Demand） — 件单价

| 项目 | 内容 |
|---|---|
| **指标名称** | AUR |
| **指标名称中文** | 件单价 |
| **业务定义** | 销售金额/商品出库件数 |
| **计算公式** | 分子：sum(pay_amt)；分母：sum(pay_qty) |
| **分子** | `pay_amt` |
| **分母** | `pay_qty` |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `is_member = 0`，`customer_type = new/exists` |
| **聚合粒度** | `dt = 所选时间范围`，`platform, shop_info_id` |
| **数据类型** | currency → 货币符号由币种切片器决定，千分位整数 |
| **数据格式** | `#,##0`（在 DAX 中用 `__CurrencySymbol & FORMAT(__Value, "#,##0")` 拼接币种符号） |

### 10.1 AUR vs LY（Demand） — 件单价同比

| 项目 | 内容 |
|---|---|
| **指标名称** | AUR vs LY |
| **指标名称中文** | 件单价同比 |
| **业务定义** | 件单价今年较去年同期的变化率 |
| **计算公式** | 今年 / 去年 - 1 |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `is_member = 0`，`customer_type = new/exists` |
| **聚合粒度** | `dt = 所选时间范围`，`platform, shop_info_id` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

### 10.2 AUR vs LP（Demand） — 件单价环比

| 项目 | 内容 |
|---|---|
| **指标名称** | AUR vs LP |
| **指标名称中文** | 件单价环比 |
| **业务定义** | 件单价当期较上期的变化率 |
| **计算公式** | 当期 / 上期 - 1 |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `is_member = 0`，`customer_type = new/exists` |
| **聚合粒度** | `dt = 所选时间范围`，`platform, shop_info_id` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

---

### 11. Freq.（Demand） — 购买频次

| 项目 | 内容 |
|---|---|
| **指标名称** | Freq. |
| **指标名称中文** | 购买频次 |
| **业务定义** | 订单数/买家人数 |
| **计算公式** | 分子：sum(pay_order_cnt)；分母：count(distinct user_id) |
| **分子** | `pay_order_cnt` |
| **分母** | `user_id` |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `sum(pay_amt) > 0`，`is_member = 0`，`customer_type = new/exists` |
| **聚合粒度** | `dt = 所选时间范围`，`platform, shop_info_id` |
| **数据类型** | decimal_1dp → 小数，保留一位小数，千分位 |
| **数据格式** | `#,##0.0` |

### 11.1 Freq. vs LY（Demand） — 购买频次同比

| 项目 | 内容 |
|---|---|
| **指标名称** | Freq. vs LY |
| **指标名称中文** | 购买频次同比 |
| **业务定义** | 购买频次今年较去年同期的变化率 |
| **计算公式** | 今年 / 去年 - 1 |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `sum(pay_amt) > 0`，`is_member = 0`，`customer_type = new/exists` |
| **聚合粒度** | `dt = 所选时间范围`，`platform, shop_info_id` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

### 11.2 Freq. vs LP（Demand） — 购买频次环比

| 项目 | 内容 |
|---|---|
| **指标名称** | Freq. vs LP |
| **指标名称中文** | 购买频次环比 |
| **业务定义** | 购买频次当期较上期的变化率 |
| **计算公式** | 当期 / 上期 - 1 |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `sum(pay_amt) > 0`，`is_member = 0`，`customer_type = new/exists` |
| **聚合粒度** | `dt = 所选时间范围`，`platform, shop_info_id` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

---

### 12. UPT（Demand） — 客单件

| 项目 | 内容 |
|---|---|
| **指标名称** | UPT |
| **指标名称中文** | 客单件 |
| **业务定义** | 商品出库件数/出库订单数 |
| **计算公式** | 分子：sum(pay_qty)；分母：sum(pay_order_cnt) |
| **分子** | `pay_qty` |
| **分母** | `pay_order_cnt` |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `is_member = 0`，`customer_type = new/exists` |
| **聚合粒度** | `dt = 所选时间范围`，`platform, shop_info_id` |
| **数据类型** | decimal_1dp → 小数，保留一位小数，千分位 |
| **数据格式** | `#,##0.0` |

### 12.1 UPT vs LY（Demand） — 客单件同比

| 项目 | 内容 |
|---|---|
| **指标名称** | UPT vs LY |
| **指标名称中文** | 客单件同比 |
| **业务定义** | 客单件今年较去年同期的变化率 |
| **计算公式** | 今年 / 去年 - 1 |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `is_member = 0`，`customer_type = new/exists` |
| **聚合粒度** | `dt = 所选时间范围`，`platform, shop_info_id` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

### 12.2 UPT vs LP（Demand） — 客单件环比

| 项目 | 内容 |
|---|---|
| **指标名称** | UPT vs LP |
| **指标名称中文** | 客单件环比 |
| **业务定义** | 客单件当期较上期的变化率 |
| **计算公式** | 当期 / 上期 - 1 |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `is_member = 0`，`customer_type = new/exists` |
| **聚合粒度** | `dt = 所选时间范围`，`platform, shop_info_id` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

---

## 子模块三：Customer Breakdown

> **分组维度**: 无额外分组维度，按 Net / Demand 区分

### 1. SLS（Net） — 净销售额

| 项目 | 内容 |
|---|---|
| **指标名称** | SLS |
| **指标名称中文** | 净销售额 |
| **业务定义** | 净销售额 |
| **计算公式** | sum(net_pay_amt) |
| **统计字段** | `net_pay_amt` |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `is_member = 0` |
| **聚合粒度** | `dt = 所选时间范围`，`platform, shop_info_id` |
| **数据类型** | currency → 货币符号由币种切片器决定，千分位整数 |
| **数据格式** | `#,##0`（在 DAX 中用 `__CurrencySymbol & FORMAT(__Value, "#,##0")` 拼接币种符号） |

### 1.1 SLS vs LY（Net） — 净销售额同比

| 项目 | 内容 |
|---|---|
| **指标名称** | SLS vs LY |
| **指标名称中文** | 净销售额同比 |
| **业务定义** | 净销售额今年较去年同期的变化率 |
| **计算公式** | 今年 / 去年 - 1 |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `is_member = 0` |
| **聚合粒度** | `dt = 所选时间范围`，`platform, shop_info_id` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

### 1.2 SLS vs LP（Net） — 净销售额环比

| 项目 | 内容 |
|---|---|
| **指标名称** | SLS vs LP |
| **指标名称中文** | 净销售额环比 |
| **业务定义** | 净销售额当期较上期的变化率 |
| **计算公式** | 当期 / 上期 - 1 |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `is_member = 0` |
| **聚合粒度** | `dt = 所选时间范围`，`platform, shop_info_id` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

---

### 2. SLS（Demand） — 销售额

| 项目 | 内容 |
|---|---|
| **指标名称** | SLS |
| **指标名称中文** | 销售额 |
| **业务定义** | 销售额 |
| **计算公式** | sum(pay_amt) |
| **统计字段** | `pay_amt` |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `is_member = 0` |
| **聚合粒度** | `dt = 所选时间范围`，`platform, shop_info_id` |
| **数据类型** | currency → 货币符号由币种切片器决定，千分位整数 |
| **数据格式** | `#,##0`（在 DAX 中用 `__CurrencySymbol & FORMAT(__Value, "#,##0")` 拼接币种符号） |

### 2.1 SLS vs LY（Demand） — 销售额同比

| 项目 | 内容 |
|---|---|
| **指标名称** | SLS vs LY |
| **指标名称中文** | 销售额同比 |
| **业务定义** | 销售额今年较去年同期的变化率 |
| **计算公式** | 今年 / 去年 - 1 |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `is_member = 0` |
| **聚合粒度** | `dt = 所选时间范围`，`platform, shop_info_id` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

### 2.2 SLS vs LP（Demand） — 销售额环比

| 项目 | 内容 |
|---|---|
| **指标名称** | SLS vs LP |
| **指标名称中文** | 销售额环比 |
| **业务定义** | 销售额当期较上期的变化率 |
| **计算公式** | 当期 / 上期 - 1 |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `is_member = 0` |
| **聚合粒度** | `dt = 所选时间范围`，`platform, shop_info_id` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

---

### 3. New Customer SLS（Net） — 新客净销售额

| 项目 | 内容 |
|---|---|
| **指标名称** | New Customer SLS |
| **指标名称中文** | 新客净销售额 |
| **业务定义** | 新客净销售额 |
| **计算公式** | sum(net_pay_amt) |
| **统计字段** | `net_pay_amt` |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `customer_type = new`，`is_member = 0` |
| **聚合粒度** | `dt = 所选时间范围`，`platform, shop_info_id` |
| **数据类型** | currency → 货币符号由币种切片器决定，千分位整数 |
| **数据格式** | `#,##0`（在 DAX 中用 `__CurrencySymbol & FORMAT(__Value, "#,##0")` 拼接币种符号） |

### 3.1 New Customer SLS占比（Net） — 新客净销售额占比

| 项目 | 内容 |
|---|---|
| **指标名称** | New Customer SLS占比 |
| **指标名称中文** | 新客净销售额占比 |
| **业务定义** | 新客净销售额占全客净销售额的比例 |
| **计算公式** | 分子：sum(net_pay_amt) where customer_type = new；分母：sum(net_pay_amt) |
| **分子** | `net_pay_amt`（`customer_type = new`） |
| **分母** | `net_pay_amt`（全部） |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `is_member = 0` |
| **聚合粒度** | `dt = 所选时间范围`，`platform, shop_info_id` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

### 3.2 New Customer SLS vs LY（Net） — 新客净销售额同比

| 项目 | 内容 |
|---|---|
| **指标名称** | New Customer SLS vs LY |
| **指标名称中文** | 新客净销售额同比 |
| **业务定义** | 新客净销售额今年较去年同期的变化率 |
| **计算公式** | 今年 / 去年 - 1 |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `customer_type = new`，`is_member = 0` |
| **聚合粒度** | `dt = 所选时间范围`，`platform, shop_info_id` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

### 3.3 New Customer SLS vs LP（Net） — 新客净销售额环比

| 项目 | 内容 |
|---|---|
| **指标名称** | New Customer SLS vs LP |
| **指标名称中文** | 新客净销售额环比 |
| **业务定义** | 新客净销售额当期较上期的变化率 |
| **计算公式** | 当期 / 上期 - 1 |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `customer_type = new`，`is_member = 0` |
| **聚合粒度** | `dt = 所选时间范围`，`platform, shop_info_id` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

---

### 4. Existing Customer SLS（Net） — 老客净销售额

| 项目 | 内容 |
|---|---|
| **指标名称** | Existing Customer SLS |
| **指标名称中文** | 老客净销售额 |
| **业务定义** | 老客净销售额 |
| **计算公式** | sum(net_pay_amt) |
| **统计字段** | `net_pay_amt` |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `customer_type = exists`，`is_member = 0` |
| **聚合粒度** | `dt = 所选时间范围`，`platform, shop_info_id` |
| **数据类型** | currency → 货币符号由币种切片器决定，千分位整数 |
| **数据格式** | `#,##0`（在 DAX 中用 `__CurrencySymbol & FORMAT(__Value, "#,##0")` 拼接币种符号） |

### 4.1 Existing Customer SLS占比（Net） — 老客净销售额占比

| 项目 | 内容 |
|---|---|
| **指标名称** | Existing Customer SLS占比 |
| **指标名称中文** | 老客净销售额占比 |
| **业务定义** | 老客净销售额占全客净销售额的比例 |
| **计算公式** | 分子：sum(net_pay_amt) where customer_type = exists；分母：sum(net_pay_amt) |
| **分子** | `net_pay_amt`（`customer_type = exists`） |
| **分母** | `net_pay_amt`（全部） |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `is_member = 0` |
| **聚合粒度** | `dt = 所选时间范围`，`platform, shop_info_id` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

---

### 5. New Customer SLS（Demand） — 新客销售额

| 项目 | 内容 |
|---|---|
| **指标名称** | New Customer SLS |
| **指标名称中文** | 新客销售额 |
| **业务定义** | 新客销售额 |
| **计算公式** | sum(pay_amt) |
| **统计字段** | `pay_amt` |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `customer_type = new`，`is_member = 0` |
| **聚合粒度** | `dt = 所选时间范围`，`platform, shop_info_id` |
| **数据类型** | currency → 货币符号由币种切片器决定，千分位整数 |
| **数据格式** | `#,##0`（在 DAX 中用 `__CurrencySymbol & FORMAT(__Value, "#,##0")` 拼接币种符号） |

### 5.1 New Customer SLS占比（Demand） — 新客销售额占比

| 项目 | 内容 |
|---|---|
| **指标名称** | New Customer SLS占比 |
| **指标名称中文** | 新客销售额占比 |
| **业务定义** | 新客销售额占全客销售额的比例（以附属指标列公式为准） |
| **计算公式** | 分子：sum(net_pay_amt) where customer_type = new；分母：sum(net_pay_amt) |
| **分子** | `net_pay_amt`（`customer_type = new`） |
| **分母** | `net_pay_amt`（全部） |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `is_member = 0` |
| **聚合粒度** | `dt = 所选时间范围`，`platform, shop_info_id` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

### 5.2 New Customer SLS vs LY（Demand） — 新客销售额同比

| 项目 | 内容 |
|---|---|
| **指标名称** | New Customer SLS vs LY |
| **指标名称中文** | 新客销售额同比 |
| **业务定义** | 新客销售额今年较去年同期的变化率 |
| **计算公式** | 今年 / 去年 - 1 |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `customer_type = new`，`is_member = 0` |
| **聚合粒度** | `dt = 所选时间范围`，`platform, shop_info_id` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

### 5.3 New Customer SLS vs LP（Demand） — 新客销售额环比

| 项目 | 内容 |
|---|---|
| **指标名称** | New Customer SLS vs LP |
| **指标名称中文** | 新客销售额环比 |
| **业务定义** | 新客销售额当期较上期的变化率 |
| **计算公式** | 当期 / 上期 - 1 |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `customer_type = new`，`is_member = 0` |
| **聚合粒度** | `dt = 所选时间范围`，`platform, shop_info_id` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

---

### 6. Existing Customer SLS（Demand） — 老客销售额

| 项目 | 内容 |
|---|---|
| **指标名称** | Existing Customer SLS |
| **指标名称中文** | 老客销售额 |
| **业务定义** | 老客销售额 |
| **计算公式** | sum(pay_amt) |
| **统计字段** | `pay_amt` |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `customer_type = exists`，`is_member = 0` |
| **聚合粒度** | `dt = 所选时间范围`，`platform, shop_info_id` |
| **数据类型** | currency → 货币符号由币种切片器决定，千分位整数 |
| **数据格式** | `#,##0`（在 DAX 中用 `__CurrencySymbol & FORMAT(__Value, "#,##0")` 拼接币种符号） |

### 6.1 Existing Customer SLS占比（Demand） — 老客销售额占比

| 项目 | 内容 |
|---|---|
| **指标名称** | Existing Customer SLS占比 |
| **指标名称中文** | 老客销售额占比 |
| **业务定义** | 老客销售额占全客销售额的比例（以附属指标列公式为准） |
| **计算公式** | 分子：sum(net_pay_amt) where customer_type = exists；分母：sum(net_pay_amt) |
| **分子** | `net_pay_amt`（`customer_type = exists`） |
| **分母** | `net_pay_amt`（全部） |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `is_member = 0` |
| **聚合粒度** | `dt = 所选时间范围`，`platform, shop_info_id` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

---

### 7. Customer No.（Net） — 买家人数

| 项目 | 内容 |
|---|---|
| **指标名称** | Customer No. |
| **指标名称中文** | 买家人数 |
| **业务定义** | 净购买买家人数 |
| **计算公式** | count(distinct user_id) |
| **统计字段** | `user_id` |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `sum(net_pay_amt) > 0`，`is_member = 0` |
| **聚合粒度** | `dt = 所选时间范围`，`platform, shop_info_id` |
| **数据类型** | integer → 整数，千分位整数 |
| **数据格式** | `#,##0` |

### 7.1 Customer No. vs LY（Net） — 买家人数同比

| 项目 | 内容 |
|---|---|
| **指标名称** | Customer No. vs LY |
| **指标名称中文** | 买家人数同比 |
| **业务定义** | 买家人数今年较去年同期的变化率 |
| **计算公式** | 今年 / 去年 - 1 |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `sum(net_pay_amt) > 0`，`is_member = 0` |
| **聚合粒度** | `dt = 所选时间范围`，`platform, shop_info_id` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

### 7.2 Customer No. vs LP（Net） — 买家人数环比

| 项目 | 内容 |
|---|---|
| **指标名称** | Customer No. vs LP |
| **指标名称中文** | 买家人数环比 |
| **业务定义** | 买家人数当期较上期的变化率 |
| **计算公式** | 当期 / 上期 - 1 |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `sum(net_pay_amt) > 0`，`is_member = 0` |
| **聚合粒度** | `dt = 所选时间范围`，`platform, shop_info_id` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

---

### 8. Customer No.（Demand） — 买家人数

| 项目 | 内容 |
|---|---|
| **指标名称** | Customer No. |
| **指标名称中文** | 买家人数 |
| **业务定义** | 买家人数 |
| **计算公式** | count(distinct user_id) |
| **统计字段** | `user_id` |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `sum(pay_amt) > 0`，`is_member = 0` |
| **聚合粒度** | `dt = 所选时间范围`，`platform, shop_info_id` |
| **数据类型** | integer → 整数，千分位整数 |
| **数据格式** | `#,##0` |

### 8.1 Customer No. vs LY（Demand） — 买家人数同比

| 项目 | 内容 |
|---|---|
| **指标名称** | Customer No. vs LY |
| **指标名称中文** | 买家人数同比 |
| **业务定义** | 买家人数今年较去年同期的变化率 |
| **计算公式** | 今年 / 去年 - 1 |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `sum(pay_amt) > 0`，`is_member = 0` |
| **聚合粒度** | `dt = 所选时间范围`，`platform, shop_info_id` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

### 8.2 Customer No. vs LP（Demand） — 买家人数环比

| 项目 | 内容 |
|---|---|
| **指标名称** | Customer No. vs LP |
| **指标名称中文** | 买家人数环比 |
| **业务定义** | 买家人数当期较上期的变化率 |
| **计算公式** | 当期 / 上期 - 1 |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `sum(pay_amt) > 0`，`is_member = 0` |
| **聚合粒度** | `dt = 所选时间范围`，`platform, shop_info_id` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

---

### 9. New Customer No.（Net） — 新客人数

| 项目 | 内容 |
|---|---|
| **指标名称** | New Customer No. |
| **指标名称中文** | 新客人数 |
| **业务定义** | 净购买新客人数 |
| **计算公式** | count(distinct user_id) |
| **统计字段** | `user_id` |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `customer_type = new`，`sum(net_pay_amt) > 0`，`is_member = 0` |
| **聚合粒度** | `dt = 所选时间范围`，`platform, shop_info_id` |
| **数据类型** | integer → 整数，千分位整数 |
| **数据格式** | `#,##0` |

### 9.1 New Customer SLS占比（Net） — 新客占比（以附属指标列公式为准）

| 项目 | 内容 |
|---|---|
| **指标名称** | New Customer SLS占比 |
| **指标名称中文** | 新客占比 |
| **业务定义** | 新客人数占全客人数的比例（以附属指标列公式为准） |
| **计算公式** | 分子：count(distinct user_id) where customer_type = new and sum(net_pay_qty) > 0；分母：count(distinct user_id) where sum(net_pay_qty) > 0 |
| **分子** | `user_id`（`customer_type = new` 且 `sum(net_pay_qty) > 0`） |
| **分母** | `user_id`（`sum(net_pay_qty) > 0`） |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `is_member = 0` |
| **聚合粒度** | `dt = 所选时间范围`，`platform, shop_info_id` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

### 9.2 New Customer SLS vs LY（Net） — 新客人数同比

| 项目 | 内容 |
|---|---|
| **指标名称** | New Customer SLS vs LY |
| **指标名称中文** | 新客人数同比 |
| **业务定义** | 新客人数今年较去年同期的变化率（以附属指标列公式为准） |
| **计算公式** | 今年 / 去年 - 1 |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `customer_type = new`，`sum(net_pay_amt) > 0`，`is_member = 0` |
| **聚合粒度** | `dt = 所选时间范围`，`platform, shop_info_id` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

### 9.3 New Customer SLS vs LP（Net） — 新客人数环比

| 项目 | 内容 |
|---|---|
| **指标名称** | New Customer SLS vs LP |
| **指标名称中文** | 新客人数环比 |
| **业务定义** | 新客人数当期较上期的变化率（以附属指标列公式为准） |
| **计算公式** | 当期 / 上期 - 1 |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `customer_type = new`，`sum(net_pay_amt) > 0`，`is_member = 0` |
| **聚合粒度** | `dt = 所选时间范围`，`platform, shop_info_id` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

---

### 10. Existing Customer No.（Net） — 老客人数

| 项目 | 内容 |
|---|---|
| **指标名称** | Existing Customer No. |
| **指标名称中文** | 老客人数 |
| **业务定义** | 净购买老客人数 |
| **计算公式** | count(distinct user_id) |
| **统计字段** | `user_id` |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `customer_type = exists`，`sum(net_pay_amt) > 0`，`is_member = 0` |
| **聚合粒度** | `dt = 所选时间范围`，`platform, shop_info_id` |
| **数据类型** | integer → 整数，千分位整数 |
| **数据格式** | `#,##0` |

### 10.1 Existing Customer SLS占比（Net） — 老客占比（以附属指标列公式为准）

| 项目 | 内容 |
|---|---|
| **指标名称** | Existing Customer SLS占比 |
| **指标名称中文** | 老客占比 |
| **业务定义** | 老客人数占全客人数的比例（以附属指标列公式为准） |
| **计算公式** | 分子：count(distinct user_id) where customer_type = exists and sum(net_pay_qty) > 0；分母：count(distinct user_id) where sum(net_pay_qty) > 0 |
| **分子** | `user_id`（`customer_type = exists` 且 `sum(net_pay_qty) > 0`） |
| **分母** | `user_id`（`sum(net_pay_qty) > 0`） |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `is_member = 0` |
| **聚合粒度** | `dt = 所选时间范围`，`platform, shop_info_id` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

---

### 11. New Customer No.（Demand） — 新客人数

| 项目 | 内容 |
|---|---|
| **指标名称** | New Customer No. |
| **指标名称中文** | 新客人数 |
| **业务定义** | 新客人数 |
| **计算公式** | count(distinct user_id) |
| **统计字段** | `user_id` |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `customer_type = new`，`sum(pay_amt) > 0`，`is_member = 0` |
| **聚合粒度** | `dt = 所选时间范围`，`platform, shop_info_id` |
| **数据类型** | integer → 整数，千分位整数 |
| **数据格式** | `#,##0` |

### 11.1 New Customer SLS占比（Demand） — 新客占比（以附属指标列公式为准）

| 项目 | 内容 |
|---|---|
| **指标名称** | New Customer SLS占比 |
| **指标名称中文** | 新客占比 |
| **业务定义** | 新客人数占全客人数的比例（以附属指标列公式为准） |
| **计算公式** | 分子：count(distinct user_id) where customer_type = new and sum(net_pay_qty) > 0；分母：count(distinct user_id) where sum(net_pay_qty) > 0 |
| **分子** | `user_id`（`customer_type = new` 且 `sum(net_pay_qty) > 0`） |
| **分母** | `user_id`（`sum(net_pay_qty) > 0`） |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `is_member = 0` |
| **聚合粒度** | `dt = 所选时间范围`，`platform, shop_info_id` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

### 11.2 New Customer SLS vs LY（Demand） — 新客人数同比

| 项目 | 内容 |
|---|---|
| **指标名称** | New Customer SLS vs LY |
| **指标名称中文** | 新客人数同比 |
| **业务定义** | 新客人数今年较去年同期的变化率（以附属指标列公式为准） |
| **计算公式** | 今年 / 去年 - 1 |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `customer_type = new`，`sum(pay_amt) > 0`，`is_member = 0` |
| **聚合粒度** | `dt = 所选时间范围`，`platform, shop_info_id` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

### 11.3 New Customer SLS vs LP（Demand） — 新客人数环比

| 项目 | 内容 |
|---|---|
| **指标名称** | New Customer SLS vs LP |
| **指标名称中文** | 新客人数环比 |
| **业务定义** | 新客人数当期较上期的变化率（以附属指标列公式为准） |
| **计算公式** | 当期 / 上期 - 1 |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `customer_type = new`，`sum(pay_amt) > 0`，`is_member = 0` |
| **聚合粒度** | `dt = 所选时间范围`，`platform, shop_info_id` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

---

### 12. Existing Customer No.（Demand） — 老客人数

| 项目 | 内容 |
|---|---|
| **指标名称** | Existing Customer No. |
| **指标名称中文** | 老客人数 |
| **业务定义** | 老客人数 |
| **计算公式** | count(distinct user_id) |
| **统计字段** | `user_id` |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `customer_type = exists`，`sum(pay_amt) > 0`，`is_member = 0` |
| **聚合粒度** | `dt = 所选时间范围`，`platform, shop_info_id` |
| **数据类型** | integer → 整数，千分位整数 |
| **数据格式** | `#,##0` |

### 12.1 Existing Customer SLS占比（Demand） — 老客占比（以附属指标列公式为准）

| 项目 | 内容 |
|---|---|
| **指标名称** | Existing Customer SLS占比 |
| **指标名称中文** | 老客占比 |
| **业务定义** | 老客人数占全客人数的比例（以附属指标列公式为准） |
| **计算公式** | 分子：count(distinct user_id) where customer_type = exists and sum(net_pay_qty) > 0；分母：count(distinct user_id) where sum(net_pay_qty) > 0 |
| **分子** | `user_id`（`customer_type = exists` 且 `sum(net_pay_qty) > 0`） |
| **分母** | `user_id`（`sum(net_pay_qty) > 0`） |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `is_member = 0` |
| **聚合粒度** | `dt = 所选时间范围`，`platform, shop_info_id` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

---

## 子模块四：ACV Breakdown

> **分组维度**: 无额外分组维度，按 Net / Demand 区分

### 1. ACV（Net） — 客单价

| 项目 | 内容 |
|---|---|
| **指标名称** | ACV |
| **指标名称中文** | 客单价 |
| **业务定义** | 净销售金额/净购买买家人数 |
| **计算公式** | 分子：sum(net_pay_amt)；分母：count(distinct user_id) |
| **分子** | `net_pay_amt` |
| **分母** | `user_id` |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `sum(net_pay_amt) > 0`，`is_member = 0` |
| **聚合粒度** | `dt = 所选时间范围`，`platform, shop_info_id` |
| **数据类型** | currency → 货币符号由币种切片器决定，千分位整数 |
| **数据格式** | `#,##0`（在 DAX 中用 `__CurrencySymbol & FORMAT(__Value, "#,##0")` 拼接币种符号） |

### 1.1 ACV vs LY（Net） — 客单价同比

| 项目 | 内容 |
|---|---|
| **指标名称** | ACV vs LY |
| **指标名称中文** | 客单价同比 |
| **业务定义** | 客单价今年较去年同期的变化率 |
| **计算公式** | 今年 / 去年 - 1 |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `sum(net_pay_amt) > 0`，`is_member = 0` |
| **聚合粒度** | `dt = 所选时间范围`，`platform, shop_info_id` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

### 1.2 ACV vs LP（Net） — 客单价环比

| 项目 | 内容 |
|---|---|
| **指标名称** | ACV vs LP |
| **指标名称中文** | 客单价环比 |
| **业务定义** | 客单价当期较上期的变化率 |
| **计算公式** | 当期 / 上期 - 1 |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `sum(net_pay_amt) > 0`，`is_member = 0` |
| **聚合粒度** | `dt = 所选时间范围`，`platform, shop_info_id` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

---

### 2. ACV（Demand） — 客单价

| 项目 | 内容 |
|---|---|
| **指标名称** | ACV |
| **指标名称中文** | 客单价 |
| **业务定义** | 销售金额/买家人数 |
| **计算公式** | 分子：sum(pay_amt)；分母：count(distinct user_id) |
| **分子** | `pay_amt` |
| **分母** | `user_id` |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `sum(pay_amt) > 0`，`is_member = 0` |
| **聚合粒度** | `dt = 所选时间范围`，`platform, shop_info_id` |
| **数据类型** | currency → 货币符号由币种切片器决定，千分位整数 |
| **数据格式** | `#,##0`（在 DAX 中用 `__CurrencySymbol & FORMAT(__Value, "#,##0")` 拼接币种符号） |

### 2.1 ACV vs LY（Demand） — 客单价同比

| 项目 | 内容 |
|---|---|
| **指标名称** | ACV vs LY |
| **指标名称中文** | 客单价同比 |
| **业务定义** | 客单价今年较去年同期的变化率 |
| **计算公式** | 今年 / 去年 - 1 |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `sum(pay_amt) > 0`，`is_member = 0` |
| **聚合粒度** | `dt = 所选时间范围`，`platform, shop_info_id` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

### 2.2 ACV vs LP（Demand） — 客单价环比

| 项目 | 内容 |
|---|---|
| **指标名称** | ACV vs LP |
| **指标名称中文** | 客单价环比 |
| **业务定义** | 客单价当期较上期的变化率 |
| **计算公式** | 当期 / 上期 - 1 |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `sum(pay_amt) > 0`，`is_member = 0` |
| **聚合粒度** | `dt = 所选时间范围`，`platform, shop_info_id` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

---

## 子模块五：AUR Breakdown

> **分组维度**: 无额外分组维度，按 Net / Demand 区分

### 1. AUR（Net） — 件单价

| 项目 | 内容 |
|---|---|
| **指标名称** | AUR |
| **指标名称中文** | 件单价 |
| **业务定义** | 净销售金额/商品净出库件数 |
| **计算公式** | 分子：sum(net_pay_amt)；分母：sum(net_pay_qty) |
| **分子** | `net_pay_amt` |
| **分母** | `net_pay_qty` |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `is_member = 0` |
| **聚合粒度** | `dt = 所选时间范围`，`platform, shop_info_id` |
| **数据类型** | currency → 货币符号由币种切片器决定，千分位整数 |
| **数据格式** | `#,##0`（在 DAX 中用 `__CurrencySymbol & FORMAT(__Value, "#,##0")` 拼接币种符号） |

### 1.1 AUR vs LY（Net） — 件单价同比

| 项目 | 内容 |
|---|---|
| **指标名称** | AUR vs LY |
| **指标名称中文** | 件单价同比 |
| **业务定义** | 件单价今年较去年同期的变化率 |
| **计算公式** | 今年 / 去年 - 1 |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `is_member = 0` |
| **聚合粒度** | `dt = 所选时间范围`，`platform, shop_info_id` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

### 1.2 AUR vs LP（Net） — 件单价环比

| 项目 | 内容 |
|---|---|
| **指标名称** | AUR vs LP |
| **指标名称中文** | 件单价环比 |
| **业务定义** | 件单价当期较上期的变化率 |
| **计算公式** | 当期 / 上期 - 1 |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `is_member = 0` |
| **聚合粒度** | `dt = 所选时间范围`，`platform, shop_info_id` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

---

### 2. AUR（Demand） — 件单价

| 项目 | 内容 |
|---|---|
| **指标名称** | AUR |
| **指标名称中文** | 件单价 |
| **业务定义** | 销售金额/商品出库件数 |
| **计算公式** | 分子：sum(pay_amt)；分母：sum(pay_qty) |
| **分子** | `pay_amt` |
| **分母** | `pay_qty` |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `is_member = 0` |
| **聚合粒度** | `dt = 所选时间范围`，`platform, shop_info_id` |
| **数据类型** | currency → 货币符号由币种切片器决定，千分位整数 |
| **数据格式** | `#,##0`（在 DAX 中用 `__CurrencySymbol & FORMAT(__Value, "#,##0")` 拼接币种符号） |

### 2.1 AUR vs LY（Demand） — 件单价同比

| 项目 | 内容 |
|---|---|
| **指标名称** | AUR vs LY |
| **指标名称中文** | 件单价同比 |
| **业务定义** | 件单价今年较去年同期的变化率 |
| **计算公式** | 今年 / 去年 - 1 |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `is_member = 0` |
| **聚合粒度** | `dt = 所选时间范围`，`platform, shop_info_id` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

### 2.2 AUR vs LP（Demand） — 件单价环比

| 项目 | 内容 |
|---|---|
| **指标名称** | AUR vs LP |
| **指标名称中文** | 件单价环比 |
| **业务定义** | 件单价当期较上期的变化率 |
| **计算公式** | 当期 / 上期 - 1 |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `is_member = 0` |
| **聚合粒度** | `dt = 所选时间范围`，`platform, shop_info_id` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

---

## 子模块六：Freq. Breakdown

> **分组维度**: 无额外分组维度，按 Net / Demand 区分

### 1. Freq.（Net） — 购买频次

| 项目 | 内容 |
|---|---|
| **指标名称** | Freq. |
| **指标名称中文** | 购买频次 |
| **业务定义** | 净订单数/净购买买家人数 |
| **计算公式** | 分子：sum(net_pay_order_cnt)；分母：count(distinct user_id) |
| **分子** | `net_pay_order_cnt` |
| **分母** | `user_id` |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `sum(net_pay_amt) > 0`，`is_member = 0` |
| **聚合粒度** | `dt = 所选时间范围`，`platform, shop_info_id` |
| **数据类型** | decimal_1dp → 小数，保留一位小数，千分位 |
| **数据格式** | `#,##0.0` |

### 1.1 Freq. vs LY（Net） — 购买频次同比

| 项目 | 内容 |
|---|---|
| **指标名称** | Freq. vs LY |
| **指标名称中文** | 购买频次同比 |
| **业务定义** | 购买频次今年较去年同期的变化率 |
| **计算公式** | 今年 / 去年 - 1 |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `sum(net_pay_amt) > 0`，`is_member = 0` |
| **聚合粒度** | `dt = 所选时间范围`，`platform, shop_info_id` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

### 1.2 Freq. vs LP（Net） — 购买频次环比

| 项目 | 内容 |
|---|---|
| **指标名称** | Freq. vs LP |
| **指标名称中文** | 购买频次环比 |
| **业务定义** | 购买频次当期较上期的变化率 |
| **计算公式** | 当期 / 上期 - 1 |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `sum(net_pay_amt) > 0`，`is_member = 0` |
| **聚合粒度** | `dt = 所选时间范围`，`platform, shop_info_id` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

---

### 2. Freq.（Demand） — 购买频次

| 项目 | 内容 |
|---|---|
| **指标名称** | Freq. |
| **指标名称中文** | 购买频次 |
| **业务定义** | 订单数/买家人数 |
| **计算公式** | 分子：sum(pay_order_cnt)；分母：count(distinct user_id) |
| **分子** | `pay_order_cnt` |
| **分母** | `user_id` |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `sum(pay_amt) > 0`，`is_member = 0` |
| **聚合粒度** | `dt = 所选时间范围`，`platform, shop_info_id` |
| **数据类型** | decimal_1dp → 小数，保留一位小数，千分位 |
| **数据格式** | `#,##0.0` |

### 2.1 Freq. vs LY（Demand） — 购买频次同比

| 项目 | 内容 |
|---|---|
| **指标名称** | Freq. vs LY |
| **指标名称中文** | 购买频次同比 |
| **业务定义** | 购买频次今年较去年同期的变化率 |
| **计算公式** | 今年 / 去年 - 1 |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `sum(pay_amt) > 0`，`is_member = 0` |
| **聚合粒度** | `dt = 所选时间范围`，`platform, shop_info_id` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

### 2.2 Freq. vs LP（Demand） — 购买频次环比

| 项目 | 内容 |
|---|---|
| **指标名称** | Freq. vs LP |
| **指标名称中文** | 购买频次环比 |
| **业务定义** | 购买频次当期较上期的变化率 |
| **计算公式** | 当期 / 上期 - 1 |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `sum(pay_amt) > 0`，`is_member = 0` |
| **聚合粒度** | `dt = 所选时间范围`，`platform, shop_info_id` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

---

## 子模块七：UPT Breakdown

> **分组维度**: 无额外分组维度，按 Net / Demand 区分

### 1. UPT（Net） — 客单件

| 项目 | 内容 |
|---|---|
| **指标名称** | UPT |
| **指标名称中文** | 客单件 |
| **业务定义** | 商品出库件数/出库订单数（以CSV定义为准） |
| **计算公式** | 分子：sum(net_pay_qty)；分母：sum(net_pay_order_cnt) |
| **分子** | `net_pay_qty` |
| **分母** | `net_pay_order_cnt` |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `is_member = 0` |
| **聚合粒度** | `dt = 所选时间范围`，`platform, shop_info_id` |
| **数据类型** | decimal_1dp → 小数，保留一位小数，千分位 |
| **数据格式** | `#,##0.0` |

### 1.1 UPT vs LY（Net） — 客单件同比

| 项目 | 内容 |
|---|---|
| **指标名称** | UPT vs LY |
| **指标名称中文** | 客单件同比 |
| **业务定义** | 客单件今年较去年同期的变化率 |
| **计算公式** | 今年 / 去年 - 1 |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `is_member = 0` |
| **聚合粒度** | `dt = 所选时间范围`，`platform, shop_info_id` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

### 1.2 UPT vs LP（Net） — 客单件环比

| 项目 | 内容 |
|---|---|
| **指标名称** | UPT vs LP |
| **指标名称中文** | 客单件环比 |
| **业务定义** | 客单件当期较上期的变化率 |
| **计算公式** | 当期 / 上期 - 1 |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `is_member = 0` |
| **聚合粒度** | `dt = 所选时间范围`，`platform, shop_info_id` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

---

### 2. UPT（Demand） — 客单件

| 项目 | 内容 |
|---|---|
| **指标名称** | UPT |
| **指标名称中文** | 客单件 |
| **业务定义** | 商品净出库件数/净出库订单数（以CSV定义为准） |
| **计算公式** | 分子：sum(pay_qty)；分母：sum(pay_order_cnt) |
| **分子** | `pay_qty` |
| **分母** | `pay_order_cnt` |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `is_member = 0` |
| **聚合粒度** | `dt = 所选时间范围`，`platform, shop_info_id` |
| **数据类型** | decimal_1dp → 小数，保留一位小数，千分位 |
| **数据格式** | `#,##0.0` |

### 2.1 UPT vs LY（Demand） — 客单件同比

| 项目 | 内容 |
|---|---|
| **指标名称** | UPT vs LY |
| **指标名称中文** | 客单件同比 |
| **业务定义** | 客单件今年较去年同期的变化率 |
| **计算公式** | 今年 / 去年 - 1 |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `is_member = 0` |
| **聚合粒度** | `dt = 所选时间范围`，`platform, shop_info_id` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

### 2.2 UPT vs LP（Demand） — 客单件环比

| 项目 | 内容 |
|---|---|
| **指标名称** | UPT vs LP |
| **指标名称中文** | 客单件环比 |
| **业务定义** | 客单件当期较上期的变化率 |
| **计算公式** | 当期 / 上期 - 1 |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `is_member = 0` |
| **聚合粒度** | `dt = 所选时间范围`，`platform, shop_info_id` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

---

## 子模块八：Class x Label Drilldown

> **分组维度**: 按 `platform, shop_info_id`、`brand, framework` 分组

### 1. Customer No.（Net_Customer No.） — 买家人数

| 项目 | 内容 |
|---|---|
| **指标名称** | Customer No. |
| **指标名称中文** | 买家人数 |
| **业务定义** | 净购买买家人数 |
| **计算公式** | 在 dt = 所选时间范围，统计各个 category_summary 下 count(distinct user_id) where sum(net_pay_amt) > 0 |
| **统计字段** | `user_id` |
| **数据底表** | `t05_customer_order_data_d` |
| **筛选条件** | `is_member = 0` |
| **聚合粒度** | `platform, shop_info_id`，`brand, framework` |
| **数据类型** | integer → 整数，千分位整数 |
| **数据格式** | `#,##0` |

---

### 2. New Customer% — 新客占比（Customer No.口径）

| 项目 | 内容 |
|---|---|
| **指标名称** | New Customer% |
| **指标名称中文** | 新客占比 |
| **业务定义** | 各筛选条件下新客占无任何筛选条件全客的比例 |
| **计算公式** | 分子：Step 1 在 `a03_e2e_customer_data_m`，`dt = 所选时间范围`，筛选 `customer_type = new`，框定 user_id 范围；Step 2 在 `t05_customer_order_data_d`，`dt = 所选时间范围`，统计各个 category_summary 下 count(distinct user_id) where user_id in Step 1 框定的 user_id 范围。分母：在 `t05_customer_order_data_d`，`dt = 所选时间范围`，count(distinct user_id) where sum(net_pay_amt) > 0【不受产品筛选器影响】 |
| **分子** | `user_id`（`customer_type = new` 且在 category_summary 下） |
| **分母** | `user_id`（`sum(net_pay_amt) > 0`，不受产品筛选器影响） |
| **数据底表** | `a03_e2e_customer_data_m`、`t05_customer_order_data_d` |
| **筛选条件** | `is_member = 0` |
| **聚合粒度** | `platform, shop_info_id`，`brand, framework` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

---

### 3. TTL Customer% — 全客占比（Customer No.口径）

| 项目 | 内容 |
|---|---|
| **指标名称** | TTL Customer% |
| **指标名称中文** | 全客占比 |
| **业务定义** | 各筛选条件下全客占无任何筛选条件全客的比例 |
| **计算公式** | 分子：在 dt = 所选时间范围，统计各个 category_summary 下 count(distinct user_id) where sum(net_pay_amt) > 0；分母：在 dt = 所选时间范围，count(distinct user_id) where sum(net_pay_amt) > 0【不受产品筛选器影响】 |
| **分子** | `user_id`（在 category_summary 下，`sum(net_pay_amt) > 0`） |
| **分母** | `user_id`（`sum(net_pay_amt) > 0`，不受产品筛选器影响） |
| **数据底表** | `t05_customer_order_data_d` |
| **筛选条件** | 无 |
| **聚合粒度** | `platform, shop_info_id`，`brand, framework` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

---

### 4. ±%（New Customer% - TTL Customer%） — 新客占比和全客占比差值（Customer No.口径）

| 项目 | 内容 |
|---|---|
| **指标名称** | ±%（New Customer% - TTL Customer%） |
| **指标名称中文** | 新客占比和全客占比差值 |
| **业务定义** | 新客占比-全客占比 |
| **计算公式** | New Customer% - TTL Customer% |
| **数据底表** | `t05_customer_order_data_d` |
| **筛选条件** | 无 |
| **聚合粒度** | `platform, shop_info_id`，`brand, framework` |
| **数据类型** | delta_pts → 增减基点整数： → +120pts / -80pts（基点，含正负号，值×100 转 pts）,乘以100的操作可以放在Cell Display度量中实现（差值，pts 指标，展示时 ×100 转 pts） |        
| **数据格式** | `+#,##0pts;-#,##0pts;0pts` |

---

### 5. SLS（Net_Sales） — 净销售额（SLS口径）

| 项目 | 内容 |
|---|---|
| **指标名称** | SLS |
| **指标名称中文** | 净销售额 |
| **业务定义** | 各 category_summary 下净销售额 |
| **计算公式** | 在 dt = 所选时间范围，统计各个 category_summary 下 sum(net_pay_amt) |
| **统计字段** | `net_pay_amt` |
| **数据底表** | `t05_customer_order_data_d` |
| **筛选条件** | 无 |
| **聚合粒度** | `platform, shop_info_id`，`brand, framework` |
| **数据类型** | currency → 货币符号由币种切片器决定，千分位整数 |
| **数据格式** | `#,##0`（在 DAX 中用 `__CurrencySymbol & FORMAT(__Value, "#,##0")` 拼接币种符号） |

---

### 6. New Customer% — 新客占比（SLS口径）

| 项目 | 内容 |
|---|---|
| **指标名称** | New Customer% |
| **指标名称中文** | 新客占比 |
| **业务定义** | 各筛选条件下新客占无任何筛选条件全客的比例 |
| **计算公式** | 分子：Step 1 在 `a03_e2e_customer_data_m`，`dt = 所选时间范围`，筛选 `customer_type = new`，框定 user_id 范围；Step 2 在 `t05_customer_order_data_d`，`dt = 所选时间范围`，统计各个 category_summary 下 sum(net_pay_amt) where user_id in Step 1 框定的 user_id 范围。分母：在 `t05_customer_order_data_d`，`dt = 所选时间范围`，sum(net_pay_amt)【不受产品筛选器影响】 |
| **分子** | `net_pay_amt`（`customer_type = new` 且在 category_summary 下） |
| **分母** | `net_pay_amt`（不受产品筛选器影响） |
| **数据底表** | `a03_e2e_customer_data_m`、`t05_customer_order_data_d` |
| **筛选条件** | `is_member = 0` |
| **聚合粒度** | `platform, shop_info_id`，`brand, framework` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

---

### 7. TTL Customer% — 全客占比（SLS口径）

| 项目 | 内容 |
|---|---|
| **指标名称** | TTL Customer% |
| **指标名称中文** | 全客占比 |
| **业务定义** | 各筛选条件下全客占无任何筛选条件全客的比例 |
| **计算公式** | 分子：在 dt = 所选时间范围，统计各个 category_summary 下 sum(net_pay_amt)；分母：在 dt = 所选时间范围，sum(net_pay_amt)【不受产品筛选器影响】 |
| **分子** | `net_pay_amt`（在 category_summary 下） |
| **分母** | `net_pay_amt`（不受产品筛选器影响） |
| **数据底表** | `t05_customer_order_data_d` |
| **筛选条件** | 无 |
| **聚合粒度** | `platform, shop_info_id`，`brand, framework` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

---

### 8. ±%（New Customer% - TTL Customer%） — 新客占比和全客占比差值（SLS口径）

| 项目 | 内容 |
|---|---|
| **指标名称** | ±%（New Customer% - TTL Customer%） |
| **指标名称中文** | 新客占比和全客占比差值 |
| **业务定义** | 新客占比-全客占比 |
| **计算公式** | New Customer% - TTL Customer% |
| **数据底表** | `t05_customer_order_data_d` |
| **筛选条件** | 无 |
| **聚合粒度** | `platform, shop_info_id`，`brand, framework` |
| **数据类型** | delta_pts → 增减基点整数： → +120pts / -80pts（基点，含正负号，值×100 转 pts）,乘以100的操作可以放在Cell Display度量中实现（差值，pts 指标，展示时 ×100 转 pts） |        
| **数据格式** | `+#,##0pts;-#,##0pts;0pts` |

---

### 9. Customer No.（Net） — 买家人数

| 项目 | 内容 |
|---|---|
| **指标名称** | Customer No. |
| **指标名称中文** | 买家人数 |
| **业务定义** | 净购买买家人数 |
| **统计字段** | `user_id` |
| **数据底表** | `t05_customer_order_data_d` |
| **筛选条件** | `is_member = 0` |
| **聚合粒度** | `platform, shop_info_id` |
| **数据类型** | integer → 整数，千分位整数 |
| **数据格式** | `#,##0` |

### 9.1 Customer No. vs LY（Net） — 买家人数同比

| 项目 | 内容 |
|---|---|
| **指标名称** | Customer No. vs LY |
| **指标名称中文** | 买家人数同比 |
| **业务定义** | 买家人数今年较去年同期的变化率 |
| **计算公式** | 今年 / 去年 - 1 |
| **数据底表** | `t05_customer_order_data_d` |
| **筛选条件** | `is_member = 0` |
| **聚合粒度** | `platform, shop_info_id` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

---

### 10. SLS（Net） — 净销售额

| 项目 | 内容 |
|---|---|
| **指标名称** | SLS |
| **指标名称中文** | 净销售额 |
| **业务定义** | 净销售额 |
| **统计字段** | `net_pay_amt` |
| **数据底表** | `t05_customer_order_data_d` |
| **筛选条件** | `is_member = 0` |
| **聚合粒度** | `platform, shop_info_id` |
| **数据类型** | currency → 货币符号由币种切片器决定，千分位整数 |
| **数据格式** | `#,##0`（在 DAX 中用 `__CurrencySymbol & FORMAT(__Value, "#,##0")` 拼接币种符号） |

### 10.1 SLS vs LY（Net） — 净销售额同比

| 项目 | 内容 |
|---|---|
| **指标名称** | SLS vs LY |
| **指标名称中文** | 净销售额同比 |
| **业务定义** | 净销售额今年较去年同期的变化率 |
| **计算公式** | 今年 / 去年 - 1 |
| **数据底表** | `t05_customer_order_data_d` |
| **筛选条件** | `is_member = 0` |
| **聚合粒度** | `platform, shop_info_id` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

---

## 子模块九：Co-Purchase Matrix

> **分组维度**: 按 `platform, shop_info_id` 分组

### 1. Same-Order Cross-Sell — 同单连带率

| 项目 | 内容 |
|---|---|
| **指标名称** | Same-Order Cross-Sell |
| **指标名称中文** | 同单连带率 |
| **业务定义** | 同一订单中同时购买起点品类 A 和目标品类 B 的订单数 / 购买起点品类 A 的订单数 |
| **数据底表** | `a03_e2e_customer_order_correlation_data_m` |
| **筛选条件** | `is_member = 0` |
| **聚合粒度** | `platform, shop_info_id` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

---

### 2. Cross-Order Cross-Sell — 跨单连带率

| 项目 | 内容 |
|---|---|
| **指标名称** | Cross-Order Cross-Sell |
| **指标名称中文** | 跨单连带率 |
| **业务定义** | 购买起点品类 A 后，在追踪周期内通过不同订单购买目标品类 B 的买家数 / 购买起点品类 A 的买家数 |
| **数据底表** | `a03_e2e_customer_order_correlation_data_m` |
| **筛选条件** | `is_member = 0` |
| **聚合粒度** | `platform, shop_info_id` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

---

## 子模块十：Product Path

> **分组维度**: 无额外分组维度

### 1. Product Path — 商品购买路径

| 项目 | 内容 |
|---|---|
| **指标名称** | Product Path |
| **指标名称中文** | 商品购买路径 |
| **业务定义** | 展示客人第 1/2/3 次购买商品路径，支持选择追踪周期 3/6/9 个月 |
| **数据底表** | `a03_e2e_customer_time_ordered_data_m` |
| **筛选条件** | `is_member = 0` |
| **聚合粒度** | 无 |
| **数据类型** | text → 文本 |
| **数据格式** | 无 |

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
| **TAR ACH% 占位** | Monthly TAR ACH% / Yearly TAR ACH% / TAR ACH% 逻辑暂未确认，先保持子指标占位，数据格式为 percent_1dp：`+#,##0.0%;-#,##0.0%;0.0%`，等逻辑确认后再填充 |
