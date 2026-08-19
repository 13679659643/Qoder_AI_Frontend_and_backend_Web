# Customer Dashboard 指标口径文档 — Customer

> **Dashboard**: Customer Dashboard  
> **Tab**: Customer  
> **数据底表（实际值）**: `a03_e2e_customer_data_m`、`t05_customer_order_data_d`、`a03_e2e_customer_order_correlation_data_m`、`a03_e2e_customer_time_ordered_data_m`  
> **数据底表（目标值）**: `a03_e2e_customer_fcst_data_m`，日期字段 `data_date`  
> **模块说明**: 本板块为客户核心看板，覆盖 Customer KPI、Performance Indicator、Customer Breakdown、ACV Breakdown、AUR Breakdown、Freq. Breakdown、UPT Breakdown、Class x Label Drilldown、Co-Purchase Matrix、Product Path 等子板块，统计 DCom 新客、买家人数、净销售额、销售额、客单价、件单价、购买频次、客单件及连带率等。

---

## 全局逻辑

| 项目 | 内容 |
|---|---|
| **数据底表（实际值）** | `a03_e2e_customer_data_m`、`t05_customer_order_data_d`、`a03_e2e_customer_order_correlation_data_m`、`a03_e2e_customer_time_ordered_data_m` |
| **数据底表（目标值）** | `a03_e2e_customer_fcst_data_m`，日期字段 `data_date` |
| **筛选逻辑** | Net 维度基于 `net_pay_amt` / `net_pay_qty` / `net_pay_order_cnt`；Demand 维度基于 `pay_amt` / `pay_qty` / `pay_order_cnt`；会员统一 `is_member = 0`（非会员） |
| **聚合粒度** | 数字卡片：所选时间范围 `data_date`；表格：所选时间范围 `data_date`，按对应维度聚合 |
| **货币转换规则** | 数据源默认为 RMB，转化为美元需要除以固定值 7 |
| **派生指标** | LY（去年同期）、LP（上期）、vs LY（同比）、vs LP（环比）、占比、YOY 等为派生指标，依据基础指标计算生成 |
| **必须遵守** | 口径文档中定义的所有指标，必须遵守其数据类型和数据格式，如果和解决方案中存在争议的，一切以口径文档为准，必须按照口径文档中的格式进行调整 |
| **data_date = 所选时间范围** | `data_date` ∈ `[__TimeMin, __TimeMax]`（全局时间范围），Slicer_Time_Frame_Min 和 Slicer_Time_Frame_Max 维度表已经给出具体的 TimeFrame_Min 和 TimeFrame_Max 值；`data_date = 所选时间范围` 即 `data_date ∈ [TimeFrame_Min, TimeFrame_Max]` |
| **新客/老客判定（Net）** | New：`lp_12m_net_pay_amt = 0`（start period 往前推 12 个月无净销售额）；Existing：`lp_12m_net_pay_amt > 0`（start period 往前推 12 个月有净销售额）；All：不限定 `lp_12m_net_pay_amt` |
| **新客/老客判定（Demand）** | New：`lp_12m_pay_amt = 0`；Existing：`lp_12m_pay_amt > 0`；All：不限定 `lp_12m_pay_amt` |
| **DAX 语法规范** | 文本常量必须使用双引号 `" "`，禁止使用单引号；单引号 `' '` 仅用于表名，列名使用方括号 `[ ]`，例如：`[is_member] = 0` |
| **pts 与 bp 区别** | pts 指标：值×100 转 pts（基点，含正负号），数据格式 `+#,##0pts;-#,##0pts;0pts`；bp 指标：值×10000 转 bp，数据格式 `+#,##0bp;-#,##0bp;0bp` |
| **TAR ACH%实现** | 实现方式：SUMX+SUMMARIZE，SUMMARIZE 按所需维度分组去重，再 SUMX 求和；DISTINCT 返回表非标量，不能在 SUMX 内当值用，用 SUMMARIZE 分组等价实现 DISTINCT 去重后再 SUM |
| **VIC 定义** | 在指定日期范围往前 Rolling 12 个财月，net sales >= 20k 的买家 |
| **Tier 分层定义** | T1：≧ 200K；T2：80-200K；T3：20-80K；T4：5-20K；T5：< 5K |
| **Recency 分层定义** | R3：上财年 10-12 月；R4-6：上财年 7-9 月；R7-9：上财年 4-6 月；R10-12：上财年 1-3 月；TTL：全部 |

---

## 子模块一：Customer KPI

> **无分组维度**: 只受到筛选器影响，没有分组维度，用于制作卡片图。

### 1. DCom New Customer No. — DCom新客数

| 项目 | 内容 |
|---|---|
| **指标名称** | DCom New Customer No. |
| **指标名称中文** | DCom新客数 |
| **业务定义** | DCom新客数 |
| **计算公式** | `count(distinct user_id)` |
| **统计字段** | `user_id` |
| **数据底表（实际值）** | `a03_e2e_customer_data_m` |
| **数据底表（目标值）** | `a03_e2e_customer_fcst_data_m`，日期字段 `data_date` |
| **筛选条件** | Step 1：在所选时间范围内筛选 `net_pay_amt > 0` 的 `user_id`（`data_date = 所选时间范围`，`is_member = 0`，`sum(net_pay_amt) > 0`）；Step 2：缩小顾客范围至 `lp_12m_net_pay_amt = 0`（`data_date = 所选时间范围 start_period`） |
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
| **筛选条件** | 同 DCom New Customer No. |
| **聚合粒度** | `data_date = 所选时间范围`，`platform, shop_info_id` |
| **附属指标数据类型** | delta_pct_0dp → 百分比整数，含正号：+15% / -3% |
| **附属指标数据格式** | IF(__Value > 0, "+", "") & FORMAT(__Value, "#,##0%") |

### 1.2 DCom New Customer No. vs LP — DCom新客数环比

| 项目 | 内容 |
|---|---|
| **指标名称** | DCom New Customer No. vs LP |
| **指标名称中文** | DCom新客数环比 |
| **业务定义** | DCom新客数当期较上期的变化率 |
| **计算公式** | 当期 / 上期 - 1 |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | 同 DCom New Customer No. |
| **聚合粒度** | `data_date = 所选时间范围`，`platform, shop_info_id` |
| **附属指标数据类型** | delta_pct_0dp → 百分比整数，含正号：+15% / -3% |
| **附属指标数据格式** | IF(__Value > 0, "+", "") & FORMAT(__Value, "#,##0%") |

### 1.3 Customer Monthly TAR ACH% — 月度新客户目标达成率

| 项目 | 内容 |
|---|---|
| **指标名称** | Customer Monthly TAR ACH% |
| **指标名称中文** | 月度新客户目标达成率 |
| **业务定义** | 新客户数量实际值与月度目标值之比，仅选择单个财月时有值 |
| **计算公式** | 实际值 / 目标值 |
| **实际值** | New Customer No. |
| **目标值取数逻辑** | `data_date = 所选时间范围`，`data_date ∈ [TimeFrame_Min, TimeFrame_Max]`（全局时间范围），目标值 = `SUM(new_customer_cnt)` |
| **目标值底表** | `a03_e2e_customer_fcst_data_m`，日期字段 `data_date` |
| **数据底表（实际值）** | `a03_e2e_customer_data_m` |
| **筛选条件** | `data_date` 筛选 |
| **聚合粒度** | `data_date = 所选时间范围`，`platform, shop_info_id` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

**Monthly TAR ACH% 计算规则矩阵（New Customer No.）、仅选择单个财月有值**

| TimeFrame | 选择范围 | 分子 | 分母 | 说明 |
|---|---|---|---|---|
| Month | 选择单个财月 | New Customer No.（month actual） | `SUM(new_customer_cnt)` | 实际值 / 月度目标值 |
| Month | 选择多个财月 | — | — | **留空**，多个月不计算 Monthly TAR ACH% |
| Month | 选择多个财月且跨财年 | — | — | **留空** |
| Quarter | 任意选择范围 | — | — | **留空**，Quarter 下不计算 Monthly TAR ACH% |
| Year | 任意选择范围 | — | — | **留空**，Year 下不计算 Monthly TAR ACH% |

### 1.4 Customer Yearly TAR ACH% — 年度新客户目标达成率

| 项目 | 内容 |
|---|---|
| **指标名称** | Customer Yearly TAR ACH% |
| **指标名称中文** | 年度新客户目标达成率 |
| **业务定义** | 新客户数量实际值总和与年度目标值之比，仅选择单个财月/单个财年且不跨财年时有值 |
| **计算公式** | 实际值总和 / 年目标值 |
| **实际值** | New Customer No. |
| **目标值取数逻辑** | `data_date = 所选时间范围`，`data_date ∈ [TimeFrame_Min, TimeFrame_Max]`（全局时间范围），目标值 = `SUM(DISTINCT year_new_customer_cnt)` |
| **目标值底表** | `a03_e2e_customer_fcst_data_m`，日期字段 `data_date` |
| **数据底表（实际值）** | `a03_e2e_customer_data_m` |
| **筛选条件** | `data_date` 筛选 |
| **聚合粒度** | `data_date = 所选时间范围`，`platform, shop_info_id` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

**Yearly TAR ACH% 计算规则矩阵（New Customer No.）、仅选择单个财月/年且不跨财年有值**

| TimeFrame | 选择范围 | 分子 | 分母 | 说明 |
|---|---|---|---|---|
| Month | 选择单个财月 | New Customer No.（month actual） | `SUM(DISTINCT year_new_customer_cnt)` | 单月实际 / 年度目标值 |
| Month | 选择多个财月 | — | — | **留空**，多个月不计算 Yearly TAR ACH% |
| Month | 选择多个财月且跨财年 | — | — | **留空** |
| Quarter | 选择单个季度且不跨财年 | New Customer No.（quarter actual） | `SUM(DISTINCT year_new_customer_cnt)` | 季度实际 / 年度目标值 |
| Quarter | 跨财年 | — | — | **留空**，跨财年不计算 Yearly TAR ACH% |
| Year | 选择单个财年 | New Customer No.（year actual） | `SUM(DISTINCT year_new_customer_cnt)` | 年度实际 / 年度目标值 |
| Year | 选择多个财年 | — | — | **留空**，多年不计算 Yearly TAR ACH% |

---

### 2. DCom New Customer% — DCom新客占比

| 项目 | 内容 |
|---|---|
| **指标名称** | DCom New Customer% |
| **指标名称中文** | DCom新客占比 |
| **业务定义** | DCom新客数/DCom总客数 |
| **计算公式** | 分子：`count(distinct user_id) where customer_type = new`；分母：`count(distinct user_id)`（全部） |
| **分子** | `user_id`（`customer_type = new`，即 `lp_12m_net_pay_amt = 0`） |
| **分母** | `user_id`（全部，`is_member = 0` 且 `sum(net_pay_amt) > 0`） |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `data_date = 所选时间范围`，`sum(net_pay_amt) > 0`，`is_member = 0` |
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
| **筛选条件** | `data_date = 所选时间范围`，`sum(net_pay_amt) > 0`，`is_member = 0` |
| **聚合粒度** | `data_date = 所选时间范围`，`platform, shop_info_id` |
| **数据类型** | delta_pts → 增减基点整数：→ +120pts / -80pts（基点，含正负号，值×100 转 pts），乘以100的操作可以放在Cell Display度量中实现，算同比LY：当期值 − 同期值（差值，pts 指标，展示时 ×100 转 pts） |
| **数据格式** | `+#,##0pts;-#,##0pts;0pts` |

### 2.2 DCom New Customer% vs LP — DCom新客占比环比

| 项目 | 内容 |
|---|---|
| **指标名称** | DCom New Customer% vs LP |
| **指标名称中文** | DCom新客占比环比 |
| **业务定义** | DCom新客占比当期较上期的变化（差值） |
| **计算公式** | 当期 - 上期（差值，展示时 ×100 转 pts） |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `data_date = 所选时间范围`，`sum(net_pay_amt) > 0`，`is_member = 0` |
| **聚合粒度** | `data_date = 所选时间范围`，`platform, shop_info_id` |
| **数据类型** | delta_pts → 增减基点整数：→ +120pts / -80pts（基点，含正负号，值×100 转 pts），乘以100的操作可以放在Cell Display度量中实现，算环比LP：当期值 − 上期值（差值，pts 指标，展示时 ×100 转 pts） |
| **数据格式** | `+#,##0pts;-#,##0pts;0pts` |

### 2.3 Customer% Monthly TAR ACH% — 月度新客户占比目标达成率

| 项目 | 内容 |
|---|---|
| **指标名称** | Customer% Monthly TAR ACH% |
| **指标名称中文** | 月度新客户占比目标达成率 |
| **业务定义** | 新客户占比实际值与月度目标值之比，仅选择单个财月且单个 shop 时有值 |
| **计算公式** | 实际值 / 目标值 |
| **实际值** | New Customer% |
| **目标值取数逻辑** | `data_date = 所选时间范围`，`data_date ∈ [TimeFrame_Min, TimeFrame_Max]`（全局时间范围），目标值 = `SUM(new_customer_percent)` |
| **目标值底表** | `a03_e2e_customer_fcst_data_m`，日期字段 `data_date` |
| **数据底表（实际值）** | `a03_e2e_customer_data_m` |
| **筛选条件** | `data_date` 筛选 |
| **聚合粒度** | `data_date = 所选时间范围`，`platform, shop_info_id` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

**Monthly TAR ACH% 计算规则矩阵（New Customer%）、仅选择单个财月且单个 shop 有值**

| TimeFrame | 选择范围 | 分子 | 分母 | 说明 |
|---|---|---|---|---|
| Month | 选择单个财月，且 Slicer_Store_Name[Store_ID] 仅筛选了单个值 | New Customer%（month actual） | `SUM(new_customer_percent)` | 单月占比实际 / 月度占比目标 |
| Month | 选择多个财月 | — | — | **留空**，多个月不计算 Monthly TAR ACH% |
| Month | 选择多个财月且跨财年 | — | — | **留空** |
| Quarter | 任意选择范围 | — | — | **留空**，Quarter 下不计算 Monthly TAR ACH% |
| Year | 任意选择范围 | — | — | **留空**，Year 下不计算 Monthly TAR ACH% |

### 2.4 Customer% Yearly TAR ACH% — 年度新客户占比目标达成率

| 项目 | 内容 |
|---|---|
| **指标名称** | Customer% Yearly TAR ACH% |
| **指标名称中文** | 年度新客户占比目标达成率 |
| **业务定义** | 新客户占比实际值与年度目标值之比，仅选择单个财月/单个财年且单个 shop 时有值 |
| **计算公式** | 实际值 / 年目标值 |
| **实际值** | New Customer% |
| **目标值取数逻辑** | `data_date = 所选时间范围`，`data_date ∈ [TimeFrame_Min, TimeFrame_Max]`（全局时间范围），目标值 = `DISTINCT year_new_customer_percent`（New Customer% 是百分比，不需要 SUM） |
| **目标值底表** | `a03_e2e_customer_fcst_data_m`，日期字段 `data_date` |
| **数据底表（实际值）** | `a03_e2e_customer_data_m` |
| **筛选条件** | `data_date` 筛选 |
| **聚合粒度** | `data_date = 所选时间范围`，`platform, shop_info_id` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

**Yearly TAR ACH% 计算规则矩阵（New Customer%）、仅选择单个财月/年且单个 shop 有值**

| TimeFrame | 选择范围 | 分子 | 分母 | 说明 |
|---|---|---|---|---|
| Month | 选择单个财月，且 Slicer_Store_Name[Store_ID] 仅筛选了单个值 | New Customer%（month actual） | `DISTINCT year_new_customer_percent` | 单月占比实际 / 年度占比目标 |
| Month | 选择多个财月 | — | — | **留空**，多个月不计算 Yearly TAR ACH% |
| Month | 选择多个财月且跨财年 | — | — | **留空** |
| Quarter | 任意选择范围 | — | — | **留空**，Quarter 下不计算 Yearly TAR ACH% |
| Year | 选择单个财年，且 Slicer_Store_Name[Store_ID] 仅筛选了单个值 | New Customer%（year actual） | `DISTINCT year_new_customer_percent` | 年度占比实际 / 年度占比目标 |
| Year | 选择多个财年 | — | — | **留空**，多年不计算 Yearly TAR ACH% |

---

## 子模块二：Performance Indicator

> **无分组维度**: 只受到筛选器影响，没有分组维度，用于制作卡片图。按 Net / Demand 维度区分。

### 1. Net 维度

#### 1.1 DCom SLS（Net） — DCom净销售额

| 项目 | 内容 |
|---|---|
| **指标名称** | DCom SLS（Net） |
| **指标名称中文** | DCom净销售额 |
| **业务定义** | DCom净销售额 = DCom销售订单总销售额 - 退货额 |
| **计算公式** | `sum(net_pay_amt)` |
| **统计字段** | `net_pay_amt` |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | **New**：Step 1 筛选所选时间范围内 `net_pay_amt > 0` 的 `user_id`（`data_date = 所选时间范围`，`sum(net_pay_amt) > 0`，`is_member = 0`），再缩小到 `lp_12m_net_pay_amt = 0`（`data_date = 所选时间范围 start_period`）；Step 2 该 `user_id` 在所选时间范围对应的 `sum(net_pay_amt) where is_member = 0`。<br>**Existing**：同 New，但 `lp_12m_net_pay_amt > 0`。<br>**All**：在所选时间范围对应的 `sum(net_pay_amt) where is_member = 0` |
| **聚合粒度** | `data_date = 所选时间范围`，`platform, shop_info_id` |
| **数据类型** | currency → 货币符号由币种切片器决定，千分位整数 |
| **数据格式** | `#,##0`（在 DAX 中用 `__CurrencySymbol & FORMAT(__Value, "#,##0")` 拼接币种符号） |
| **附属指标** | vs LY：今年 / 去年 - 1；vs LP：当期 / 上期 - 1 |

#### 1.2 Customer No.（Net） — 净购买买家人数

| 项目 | 内容 |
|---|---|
| **指标名称** | Customer No.（Net） |
| **指标名称中文** | 净购买买家人数 |
| **业务定义** | 净购买买家人数 |
| **计算公式** | `count(distinct user_id)` |
| **统计字段** | `user_id` |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | **New**：Step 1 筛选 `net_pay_amt > 0` 的 `user_id`（`data_date = 所选时间范围`，`sum(net_pay_amt) > 0`，`is_member = 0`），再缩小到 `lp_12m_net_pay_amt = 0`。<br>**Existing**：同 New，但 `lp_12m_net_pay_amt > 0`。<br>**All**：`count(distinct user_id)`，`data_date = 所选时间范围`，`sum(net_pay_amt) > 0`，`is_member = 0` |
| **聚合粒度** | `data_date = 所选时间范围`，`platform, shop_info_id` |
| **数据类型** | integer → 整数，千分位整数 |
| **数据格式** | `#,##0` |
| **附属指标** | vs LY：今年 / 去年 - 1；vs LP：当期 / 上期 - 1 |

#### 1.3 ACV（Net） — 客单价

| 项目 | 内容 |
|---|---|
| **指标名称** | ACV（Net） |
| **指标名称中文** | 客单价 |
| **业务定义** | 净销售金额 / 净购买买家人数 |
| **计算公式** | 分子：`sum(net_pay_amt)`；分母：`count(distinct user_id)` |
| **分子** | `net_pay_amt`（`is_member = 0`） |
| **分母** | `user_id`（`sum(net_pay_amt) > 0`，`is_member = 0`） |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | **New**：Step 1 筛选 `net_pay_amt > 0` 的 `user_id`（`is_member = 0`，`lp_12m_net_pay_amt = 0`）；Step 2 `sum(net_pay_amt) where is_member = 0`；Step 3 `sum(net_pay_amt)/count(distinct user_id)`。<br>**Existing**：同 New（`lp_12m_net_pay_amt > 0`）。<br>**All**：分子 `sum(net_pay_amt) where is_member = 0`；分母 `count(distinct user_id)`，`data_date = 所选时间范围`，`sum(net_pay_amt) > 0`，`is_member = 0` |
| **聚合粒度** | `data_date = 所选时间范围`，`platform, shop_info_id` |
| **数据类型** | currency_decimal_1dp → 货币符号 + 千分位一位小数：¥1,000.0 / $1,000.0 |
| **数据格式** | `#,##0.0`（在 DAX 中用 `__CurrencySymbol & FORMAT(__Value, "#,##0.0")` 拼接币种符号） |
| **附属指标** | vs LY：今年 / 去年 - 1；vs LP：当期 / 上期 - 1 |

#### 1.4 AUR（Net） — 件单价

| 项目 | 内容 |
|---|---|
| **指标名称** | AUR（Net） |
| **指标名称中文** | 件单价 |
| **业务定义** | 净销售金额 / 商品净出库件数 |
| **计算公式** | 分子：`sum(net_pay_amt)`；分母：`sum(net_pay_qty)` |
| **分子** | `net_pay_amt`（`is_member = 0`） |
| **分母** | `net_pay_qty`（`is_member = 0`） |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | **New**：Step 1 筛选 `net_pay_amt > 0` 的 `user_id`（`is_member = 0`，`lp_12m_net_pay_amt = 0`）；Step 2 分子 `sum(net_pay_amt) where is_member = 0`；分母 `sum(net_pay_qty) where is_member = 0`。<br>**Existing**：同 New（`lp_12m_net_pay_amt > 0`）。<br>**All**：分子 `sum(net_pay_amt) where is_member = 0`；分母 `sum(net_pay_qty) where is_member = 0` |
| **聚合粒度** | `data_date = 所选时间范围`，`platform, shop_info_id` |
| **数据类型** | currency_decimal_1dp → 货币符号 + 千分位一位小数：¥1,000.0 / $1,000.0 |
| **数据格式** | `#,##0.0`（在 DAX 中用 `__CurrencySymbol & FORMAT(__Value, "#,##0.0")` 拼接币种符号） |
| **附属指标** | vs LY：今年 / 去年 - 1；vs LP：当期 / 上期 - 1 |

#### 1.5 Freq.（Net） — 购买频次

| 项目 | 内容 |
|---|---|
| **指标名称** | Freq.（Net） |
| **指标名称中文** | 购买频次 |
| **业务定义** | 净订单数 / 净购买买家人数 |
| **计算公式** | 分子：`sum(net_pay_order_cnt)`；分母：`count(distinct user_id)` |
| **分子** | `net_pay_order_cnt`（`is_member = 0`） |
| **分母** | `user_id`（`sum(net_pay_amt) > 0`，`is_member = 0`） |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | **New**：Step 1 筛选 `net_pay_amt > 0` 的 `user_id`（`is_member = 0`，`lp_12m_net_pay_amt = 0`）；Step 2 `sum(net_pay_order_cnt) where is_member = 0`；Step 3 `sum(net_pay_order_cnt)/count(distinct user_id)`。<br>**Existing**：同 New（`lp_12m_net_pay_amt > 0`）。<br>**All**：分子 `sum(net_pay_order_cnt) where is_member = 0`；分母 `count(distinct user_id)`，`sum(net_pay_amt) > 0`，`is_member = 0` |
| **聚合粒度** | `data_date = 所选时间范围`，`platform, shop_info_id` |
| **数据类型** | decimal_1dp → 小数，保留一位小数，千分位 |
| **数据格式** | `#,##0.0` |
| **附属指标** | vs LY：今年 / 去年 - 1；vs LP：当期 / 上期 - 1 |

#### 1.6 UPT（Net） — 客单件

| 项目 | 内容 |
|---|---|
| **指标名称** | UPT（Net） |
| **指标名称中文** | 客单件 |
| **业务定义** | 商品净出库件数 / 净出库订单数 |
| **计算公式** | 分子：`sum(net_pay_qty)`；分母：`sum(net_pay_order_cnt)` |
| **分子** | `net_pay_qty`（`is_member = 0`） |
| **分母** | `net_pay_order_cnt`（`is_member = 0`） |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | **New**：Step 1 筛选 `net_pay_amt > 0` 的 `user_id`（`is_member = 0`，`lp_12m_net_pay_amt = 0`）；Step 2 分子 `sum(net_pay_qty) where is_member = 0`；分母 `sum(net_pay_order_cnt) where is_member = 0`。<br>**Existing**：同 New（`lp_12m_net_pay_amt > 0`）。<br>**All**：分子 `sum(net_pay_qty) where is_member = 0`；分母 `sum(net_pay_order_cnt) where is_member = 0` |
| **聚合粒度** | `data_date = 所选时间范围`，`platform, shop_info_id` |
| **数据类型** | decimal_1dp → 小数，保留一位小数，千分位 |
| **数据格式** | `#,##0.0` |
| **附属指标** | vs LY：今年 / 去年 - 1；vs LP：当期 / 上期 - 1 |

### 2. Demand 维度

#### 2.1 DCom SLS（Demand） — DCom销售额

| 项目 | 内容 |
|---|---|
| **指标名称** | DCom SLS（Demand） |
| **指标名称中文** | DCom销售额 |
| **业务定义** | DCom销售额 |
| **计算公式** | `sum(pay_amt)` |
| **统计字段** | `pay_amt` |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | **New**：Step 1 筛选 demand sales > 0 的 `user_id`（`sum(pay_amt) > 0`，`is_member = 0`，`lp_12m_pay_amt = 0`）；Step 2 `sum(pay_amt) where is_member = 0`。<br>**Existing**：同 New（`lp_12m_pay_amt > 0`）。<br>**All**：在所选时间范围对应的 `sum(pay_amt) where is_member = 0` |
| **聚合粒度** | `data_date = 所选时间范围`，`platform, shop_info_id` |
| **数据类型** | currency → 货币符号由币种切片器决定，千分位整数 |
| **数据格式** | `#,##0`（在 DAX 中用 `__CurrencySymbol & FORMAT(__Value, "#,##0")` 拼接币种符号） |
| **附属指标** | vs LY：今年 / 去年 - 1；vs LP：当期 / 上期 - 1 |

#### 2.2 Customer No.（Demand） — 买家人数

| 项目 | 内容 |
|---|---|
| **指标名称** | Customer No.（Demand） |
| **指标名称中文** | 买家人数 |
| **业务定义** | 买家人数 |
| **计算公式** | `count(distinct user_id)` |
| **统计字段** | `user_id` |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | **New**：Step 1 筛选 demand sales > 0 的 `user_id`（`sum(pay_amt) > 0`，`is_member = 0`，`lp_12m_pay_amt = 0`）。<br>**Existing**：同 New（`lp_12m_pay_amt > 0`）。<br>**All**：`count(distinct user_id)`，`data_date = 所选时间范围`，`sum(pay_amt) > 0`，`is_member = 0` |
| **聚合粒度** | `data_date = 所选时间范围`，`platform, shop_info_id` |
| **数据类型** | integer → 整数，千分位整数 |
| **数据格式** | `#,##0` |
| **附属指标** | vs LY：今年 / 去年 - 1；vs LP：当期 / 上期 - 1 |

#### 2.3 ACV（Demand） — 客单价

| 项目 | 内容 |
|---|---|
| **指标名称** | ACV（Demand） |
| **指标名称中文** | 客单价 |
| **业务定义** | 销售金额 / 买家人数 |
| **计算公式** | 分子：`sum(pay_amt)`；分母：`count(distinct user_id)` |
| **分子** | `pay_amt`（`is_member = 0`） |
| **分母** | `user_id`（`sum(pay_amt) > 0`，`is_member = 0`） |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | **New**：Step 1 筛选 demand sales > 0 的 `user_id`（`is_member = 0`，`lp_12m_pay_amt = 0`）；Step 2 `sum(pay_amt) where is_member = 0`；Step 3 `sum(pay_amt)/count(distinct user_id)`。<br>**Existing**：同 New（`lp_12m_pay_amt > 0`）。<br>**All**：分子 `sum(pay_amt) where is_member = 0`；分母 `count(distinct user_id)`，`sum(pay_amt) > 0`，`is_member = 0` |
| **聚合粒度** | `data_date = 所选时间范围`，`platform, shop_info_id` |
| **数据类型** | currency_decimal_1dp → 货币符号 + 千分位一位小数：¥1,000.0 / $1,000.0 |
| **数据格式** | `#,##0.0`（在 DAX 中用 `__CurrencySymbol & FORMAT(__Value, "#,##0.0")` 拼接币种符号） |
| **附属指标** | vs LY：今年 / 去年 - 1；vs LP：当期 / 上期 - 1 |

#### 2.4 AUR（Demand） — 件单价

| 项目 | 内容 |
|---|---|
| **指标名称** | AUR（Demand） |
| **指标名称中文** | 件单价 |
| **业务定义** | 销售金额 / 商品出库件数 |
| **计算公式** | 分子：`sum(pay_amt)`；分母：`sum(pay_qty)` |
| **分子** | `pay_amt`（`is_member = 0`） |
| **分母** | `pay_qty`（`is_member = 0`） |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | **New**：Step 1 筛选 demand sales > 0 的 `user_id`（`is_member = 0`，`lp_12m_pay_amt = 0`）；Step 2 分子 `sum(pay_amt) where is_member = 0`；分母 `sum(pay_qty) where is_member = 0`。<br>**Existing**：同 New（`lp_12m_pay_amt > 0`）。<br>**All**：分子 `sum(pay_amt) where is_member = 0`；分母 `sum(pay_qty) where is_member = 0` |
| **聚合粒度** | `data_date = 所选时间范围`，`platform, shop_info_id` |
| **数据类型** | currency_decimal_1dp → 货币符号 + 千分位一位小数：¥1,000.0 / $1,000.0 |
| **数据格式** | `#,##0.0`（在 DAX 中用 `__CurrencySymbol & FORMAT(__Value, "#,##0.0")` 拼接币种符号） |
| **附属指标** | vs LY：今年 / 去年 - 1；vs LP：当期 / 上期 - 1 |

#### 2.5 Freq.（Demand） — 购买频次

| 项目 | 内容 |
|---|---|
| **指标名称** | Freq.（Demand） |
| **指标名称中文** | 购买频次 |
| **业务定义** | 订单数 / 买家人数 |
| **计算公式** | 分子：`sum(pay_order_cnt)`；分母：`count(distinct user_id)` |
| **分子** | `pay_order_cnt`（`is_member = 0`） |
| **分母** | `user_id`（`sum(pay_amt) > 0`，`is_member = 0`） |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | **New**：Step 1 筛选 demand sales > 0 的 `user_id`（`is_member = 0`，`lp_12m_pay_amt = 0`）；Step 2 `sum(pay_order_cnt) where is_member = 0`；Step 3 `sum(pay_order_cnt)/count(distinct user_id)`。<br>**Existing**：同 New（`lp_12m_pay_amt > 0`）。<br>**All**：分子 `sum(pay_order_cnt) where is_member = 0`；分母 `count(distinct user_id)`，`sum(pay_amt) > 0`，`is_member = 0` |
| **聚合粒度** | `data_date = 所选时间范围`，`platform, shop_info_id` |
| **数据类型** | decimal_1dp → 小数，保留一位小数，千分位 |
| **数据格式** | `#,##0.0` |
| **附属指标** | vs LY：今年 / 去年 - 1；vs LP：当期 / 上期 - 1 |

#### 2.6 UPT（Demand） — 客单件

| 项目 | 内容 |
|---|---|
| **指标名称** | UPT（Demand） |
| **指标名称中文** | 客单件 |
| **业务定义** | 商品出库件数 / 出库订单数 |
| **计算公式** | 分子：`sum(pay_qty)`；分母：`sum(pay_order_cnt)` |
| **分子** | `pay_qty`（`is_member = 0`） |
| **分母** | `pay_order_cnt`（`is_member = 0`） |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | **New**：Step 1 筛选 demand sales > 0 的 `user_id`（`is_member = 0`，`lp_12m_pay_amt = 0`）；Step 2 分子 `sum(pay_qty) where is_member = 0`；分母 `sum(pay_order_cnt) where is_member = 0`。<br>**Existing**：同 New（`lp_12m_pay_amt > 0`）。<br>**All**：分子 `sum(pay_qty) where is_member = 0`；分母 `sum(pay_order_cnt) where is_member = 0` |
| **聚合粒度** | `data_date = 所选时间范围`，`platform, shop_info_id` |
| **数据类型** | decimal_1dp → 小数，保留一位小数，千分位 |
| **数据格式** | `#,##0.0` |
| **附属指标** | vs LY：今年 / 去年 - 1；vs LP：当期 / 上期 - 1 |

---

## 子模块三：Customer Breakdown

> **分组维度**: 按 New / Existing / All 客户类型分组，按 `platform, shop_info_id` 维度聚合。

### 1. Net 维度

#### 1.1 SLS（Net） — 净销售额

| 项目 | 内容 |
|---|---|
| **指标名称** | SLS（Net） |
| **指标名称中文** | 净销售额 |
| **业务定义** | 净销售额 |
| **计算公式** | `sum(net_pay_amt)` |
| **统计字段** | `net_pay_amt` |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `is_member = 0` |
| **聚合粒度** | `data_date = 所选时间范围`，`platform, shop_info_id` |
| **数据类型** | currency → 货币符号由币种切片器决定，千分位整数 |
| **数据格式** | `#,##0`（在 DAX 中用 `__CurrencySymbol & FORMAT(__Value, "#,##0")` 拼接币种符号） |
| **附属指标** | vs LY：今年 / 去年 - 1；vs LP：当期 / 上期 - 1 |

#### 1.2 New Customer SLS（Net） — 新客净销售额

| 项目 | 内容 |
|---|---|
| **指标名称** | New Customer SLS（Net） |
| **指标名称中文** | 新客净销售额 |
| **业务定义** | 新客净销售额 |
| **计算公式** | Step 1 筛选 `net_pay_amt > 0` 的 `user_id`（`is_member = 0`，`lp_12m_net_pay_amt = 0`）；Step 2 `sum(net_pay_amt) where is_member = 0` |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `lp_12m_net_pay_amt = 0`，`is_member = 0` |
| **聚合粒度** | `data_date = 所选时间范围`，`platform, shop_info_id` |
| **数据类型** | currency → 货币符号由币种切片器决定，千分位整数 |
| **数据格式** | `#,##0`（在 DAX 中用 `__CurrencySymbol & FORMAT(__Value, "#,##0")` 拼接币种符号） |
| **附属指标** | New Customer SLS 占比：分子原指标，分母 `sum(net_pay_amt) where is_member = 0`；vs LY：今年 / 去年 - 1；vs LP：当期 / 上期 - 1 |

#### 1.3 Existing Customer SLS（Net） — 老客净销售额

| 项目 | 内容 |
|---|---|
| **指标名称** | Existing Customer SLS（Net） |
| **指标名称中文** | 老客净销售额 |
| **业务定义** | 老客净销售额 |
| **计算公式** | Step 1 筛选 `net_pay_amt > 0` 的 `user_id`（`is_member = 0`，`lp_12m_net_pay_amt > 0`）；Step 2 `sum(net_pay_amt) where is_member = 0` |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `lp_12m_net_pay_amt > 0`，`is_member = 0` |
| **聚合粒度** | `data_date = 所选时间范围`，`platform, shop_info_id` |
| **数据类型** | currency → 货币符号由币种切片器决定，千分位整数 |
| **数据格式** | `#,##0`（在 DAX 中用 `__CurrencySymbol & FORMAT(__Value, "#,##0")` 拼接币种符号） |
| **附属指标** | Existing Customer SLS 占比：分子原指标，分母 `sum(net_pay_amt) where is_member = 0` |

#### 1.4 Customer No.（Net） — 净购买买家人数

| 项目 | 内容 |
|---|---|
| **指标名称** | Customer No.（Net） |
| **指标名称中文** | 净购买买家人数 |
| **业务定义** | 净购买买家人数 |
| **计算公式** | `count(distinct user_id)` |
| **统计字段** | `user_id` |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `sum(net_pay_amt) > 0`，`is_member = 0` |
| **聚合粒度** | `data_date = 所选时间范围`，`platform, shop_info_id` |
| **数据类型** | integer → 整数，千分位整数 |
| **数据格式** | `#,##0` |
| **附属指标** | vs LY：今年 / 去年 - 1；vs LP：当期 / 上期 - 1 |

#### 1.5 New Customer No.（Net） — 净购买新客人数

| 项目 | 内容 |
|---|---|
| **指标名称** | New Customer No.（Net） |
| **指标名称中文** | 净购买新客人数 |
| **业务定义** | 净购买新客人数 |
| **计算公式** | `count(distinct user_id)` |
| **统计字段** | `user_id` |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | Step 1 筛选 `net_pay_amt > 0` 的 `user_id`，`lp_12m_net_pay_amt = 0` |
| **聚合粒度** | `data_date = 所选时间范围`，`platform, shop_info_id` |
| **数据类型** | integer → 整数，千分位整数 |
| **数据格式** | `#,##0` |
| **附属指标** | New Customer No. 占比：分子原指标，分母 `count(distinct user_id) where sum(net_pay_qty) > 0 AND is_member = 0`；vs LY：今年 / 去年 - 1；vs LP：当期 / 上期 - 1 |

#### 1.6 Existing Customer No.（Net） — 净购买老客人数

| 项目 | 内容 |
|---|---|
| **指标名称** | Existing Customer No.（Net） |
| **指标名称中文** | 净购买老客人数 |
| **业务定义** | 净购买老客人数 |
| **计算公式** | `count(distinct user_id)` |
| **统计字段** | `user_id` |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | Step 1 筛选 `net_pay_amt > 0` 的 `user_id`，`lp_12m_net_pay_amt > 0` |
| **聚合粒度** | `data_date = 所选时间范围`，`platform, shop_info_id` |
| **数据类型** | integer → 整数，千分位整数 |
| **数据格式** | `#,##0` |
| **附属指标** | Existing Customer No. 占比：分子原指标，分母 `count(distinct user_id) where sum(net_pay_qty) > 0 AND is_member = 0` |

### 2. Demand 维度

#### 2.1 SLS（Demand） — 销售额

| 项目 | 内容 |
|---|---|
| **指标名称** | SLS（Demand） |
| **指标名称中文** | 销售额 |
| **业务定义** | 销售额 |
| **计算公式** | `sum(pay_amt)` |
| **统计字段** | `pay_amt` |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `is_member = 0` |
| **聚合粒度** | `data_date = 所选时间范围`，`platform, shop_info_id` |
| **数据类型** | currency → 货币符号由币种切片器决定，千分位整数 |
| **数据格式** | `#,##0`（在 DAX 中用 `__CurrencySymbol & FORMAT(__Value, "#,##0")` 拼接币种符号） |
| **附属指标** | vs LY：今年 / 去年 - 1；vs LP：当期 / 上期 - 1 |

#### 2.2 New Customer SLS（Demand） — 新客销售额

| 项目 | 内容 |
|---|---|
| **指标名称** | New Customer SLS（Demand） |
| **指标名称中文** | 新客销售额 |
| **业务定义** | 新客销售额 |
| **计算公式** | Step 1 筛选 demand sales > 0 的 `user_id`（`is_member = 0`，`lp_12m_pay_amt = 0`）；Step 2 `sum(pay_amt) where is_member = 0` |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `lp_12m_pay_amt = 0`，`is_member = 0` |
| **聚合粒度** | `data_date = 所选时间范围`，`platform, shop_info_id` |
| **数据类型** | currency → 货币符号由币种切片器决定，千分位整数 |
| **数据格式** | `#,##0`（在 DAX 中用 `__CurrencySymbol & FORMAT(__Value, "#,##0")` 拼接币种符号） |
| **附属指标** | New Customer SLS 占比：分子原指标，分母 `sum(pay_amt) where is_member = 0`；vs LY：今年 / 去年 - 1；vs LP：当期 / 上期 - 1 |

#### 2.3 Existing Customer SLS（Demand） — 老客销售额

| 项目 | 内容 |
|---|---|
| **指标名称** | Existing Customer SLS（Demand） |
| **指标名称中文** | 老客销售额 |
| **业务定义** | 老客销售额 |
| **计算公式** | Step 1 筛选 demand sales > 0 的 `user_id`（`is_member = 0`，`lp_12m_pay_amt > 0`）；Step 2 `sum(pay_amt) where is_member = 0` |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `lp_12m_pay_amt > 0`，`is_member = 0` |
| **聚合粒度** | `data_date = 所选时间范围`，`platform, shop_info_id` |
| **数据类型** | currency → 货币符号由币种切片器决定，千分位整数 |
| **数据格式** | `#,##0`（在 DAX 中用 `__CurrencySymbol & FORMAT(__Value, "#,##0")` 拼接币种符号） |
| **附属指标** | Existing Customer SLS 占比：分子原指标，分母 `sum(pay_amt) where is_member = 0` |

#### 2.4 Customer No.（Demand） — 买家人数

| 项目 | 内容 |
|---|---|
| **指标名称** | Customer No.（Demand） |
| **指标名称中文** | 买家人数 |
| **业务定义** | 买家人数 |
| **计算公式** | `count(distinct user_id)` |
| **统计字段** | `user_id` |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `sum(pay_amt) > 0`，`is_member = 0` |
| **聚合粒度** | `data_date = 所选时间范围`，`platform, shop_info_id` |
| **数据类型** | integer → 整数，千分位整数 |
| **数据格式** | `#,##0` |
| **附属指标** | vs LY：今年 / 去年 - 1；vs LP：当期 / 上期 - 1 |

#### 2.5 New Customer No.（Demand） — 新客人数

| 项目 | 内容 |
|---|---|
| **指标名称** | New Customer No.（Demand） |
| **指标名称中文** | 新客人数 |
| **业务定义** | 新客人数 |
| **计算公式** | `count(distinct user_id)` |
| **统计字段** | `user_id` |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | Step 1 筛选 demand sales > 0 的 `user_id`，`lp_12m_pay_amt = 0` |
| **聚合粒度** | `data_date = 所选时间范围`，`platform, shop_info_id` |
| **数据类型** | integer → 整数，千分位整数 |
| **数据格式** | `#,##0` |
| **附属指标** | New Customer No. 占比：分子原指标，分母 `count(distinct user_id) where sum(pay_qty) > 0 AND is_member = 0`；vs LY：今年 / 去年 - 1；vs LP：当期 / 上期 - 1 |

#### 2.6 Existing Customer No.（Demand） — 老客人数

| 项目 | 内容 |
|---|---|
| **指标名称** | Existing Customer No.（Demand） |
| **指标名称中文** | 老客人数 |
| **业务定义** | 老客人数 |
| **计算公式** | `count(distinct user_id)` |
| **统计字段** | `user_id` |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | Step 1 筛选 demand sales > 0 的 `user_id`，`lp_12m_pay_amt > 0` |
| **聚合粒度** | `data_date = 所选时间范围`，`platform, shop_info_id` |
| **数据类型** | integer → 整数，千分位整数 |
| **数据格式** | `#,##0` |
| **附属指标** | Existing Customer No. 占比：分子原指标，分母 `count(distinct user_id) where sum(pay_qty) > 0 AND is_member = 0` |

---

## 子模块四：ACV Breakdown

> **分组维度**: 按 New / Existing / All 客户类型分组，按 `platform, shop_info_id` 维度聚合。

### 1. ACV（Net） — 客单价

| 项目 | 内容 |
|---|---|
| **指标名称** | ACV（Net） |
| **指标名称中文** | 客单价 |
| **业务定义** | 净销售金额 / 净购买买家人数 |
| **计算公式** | 分子：`sum(net_pay_amt)`；分母：`count(distinct user_id)` |
| **分子** | `net_pay_amt`（`is_member = 0`） |
| **分母** | `user_id`（`sum(net_pay_amt) > 0`，`is_member = 0`） |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `sum(net_pay_amt) > 0`，`is_member = 0` |
| **聚合粒度** | `data_date = 所选时间范围`，`platform, shop_info_id` |
| **数据类型** | currency_decimal_1dp → 货币符号 + 千分位一位小数：¥1,000.0 / $1,000.0 |
| **数据格式** | `#,##0.0`（在 DAX 中用 `__CurrencySymbol & FORMAT(__Value, "#,##0.0")` 拼接币种符号） |
| **附属指标** | vs LY：今年 / 去年 - 1；vs LP：当期 / 上期 - 1 |

### 2. ACV（Demand） — 客单价

| 项目 | 内容 |
|---|---|
| **指标名称** | ACV（Demand） |
| **指标名称中文** | 客单价 |
| **业务定义** | 销售金额 / 买家人数 |
| **计算公式** | 分子：`sum(pay_amt)`；分母：`count(distinct user_id)` |
| **分子** | `pay_amt`（`is_member = 0`） |
| **分母** | `user_id`（`sum(pay_amt) > 0`，`is_member = 0`） |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `sum(pay_amt) > 0`，`is_member = 0` |
| **聚合粒度** | `data_date = 所选时间范围`，`platform, shop_info_id` |
| **数据类型** | currency_decimal_1dp → 货币符号 + 千分位一位小数：¥1,000.0 / $1,000.0 |
| **数据格式** | `#,##0.0`（在 DAX 中用 `__CurrencySymbol & FORMAT(__Value, "#,##0.0")` 拼接币种符号） |
| **附属指标** | vs LY：今年 / 去年 - 1；vs LP：当期 / 上期 - 1 |

---

## 子模块五：AUR Breakdown

> **分组维度**: 按 New / Existing / All 客户类型分组，按 `platform, shop_info_id` 维度聚合。

### 1. AUR（Net） — 件单价

| 项目 | 内容 |
|---|---|
| **指标名称** | AUR（Net） |
| **指标名称中文** | 件单价 |
| **业务定义** | 净销售金额 / 商品净出库件数 |
| **计算公式** | 分子：`sum(net_pay_amt)`；分母：`sum(net_pay_qty)` |
| **分子** | `net_pay_amt`（`is_member = 0`） |
| **分母** | `net_pay_qty`（`is_member = 0`） |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `is_member = 0` |
| **聚合粒度** | `data_date = 所选时间范围`，`platform, shop_info_id` |
| **数据类型** | currency_decimal_1dp → 货币符号 + 千分位一位小数：¥1,000.0 / $1,000.0 |
| **数据格式** | `#,##0.0`（在 DAX 中用 `__CurrencySymbol & FORMAT(__Value, "#,##0.0")` 拼接币种符号） |
| **附属指标** | vs LY：今年 / 去年 - 1；vs LP：当期 / 上期 - 1 |

### 2. AUR（Demand） — 件单价

| 项目 | 内容 |
|---|---|
| **指标名称** | AUR（Demand） |
| **指标名称中文** | 件单价 |
| **业务定义** | 销售金额 / 商品出库件数 |
| **计算公式** | 分子：`sum(pay_amt)`；分母：`sum(pay_qty)` |
| **分子** | `pay_amt`（`is_member = 0`） |
| **分母** | `pay_qty`（`is_member = 0`） |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `is_member = 0` |
| **聚合粒度** | `data_date = 所选时间范围`，`platform, shop_info_id` |
| **数据类型** | currency_decimal_1dp → 货币符号 + 千分位一位小数：¥1,000.0 / $1,000.0 |
| **数据格式** | `#,##0.0`（在 DAX 中用 `__CurrencySymbol & FORMAT(__Value, "#,##0.0")` 拼接币种符号） |
| **附属指标** | vs LY：今年 / 去年 - 1；vs LP：当期 / 上期 - 1 |

---

## 子模块六：Freq. Breakdown

> **分组维度**: 按 New / Existing / All 客户类型分组，按 `platform, shop_info_id` 维度聚合。

### 1. Freq.（Net） — 购买频次

| 项目 | 内容 |
|---|---|
| **指标名称** | Freq.（Net） |
| **指标名称中文** | 购买频次 |
| **业务定义** | 净订单数 / 净购买买家人数 |
| **计算公式** | 分子：`sum(net_pay_order_cnt)`；分母：`count(distinct user_id)` |
| **分子** | `net_pay_order_cnt`（`is_member = 0`） |
| **分母** | `user_id`（`sum(net_pay_amt) > 0`，`is_member = 0`） |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `sum(net_pay_amt) > 0`，`is_member = 0` |
| **聚合粒度** | `data_date = 所选时间范围`，`platform, shop_info_id` |
| **数据类型** | decimal_1dp → 小数，保留一位小数，千分位 |
| **数据格式** | `#,##0.0` |
| **附属指标** | vs LY：今年 / 去年 - 1；vs LP：当期 / 上期 - 1 |

### 2. Freq.（Demand） — 购买频次

| 项目 | 内容 |
|---|---|
| **指标名称** | Freq.（Demand） |
| **指标名称中文** | 购买频次 |
| **业务定义** | 订单数 / 买家人数 |
| **计算公式** | 分子：`sum(pay_order_cnt)`；分母：`count(distinct user_id)` |
| **分子** | `pay_order_cnt`（`is_member = 0`） |
| **分母** | `user_id`（`sum(pay_amt) > 0`，`is_member = 0`） |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `sum(pay_amt) > 0`，`is_member = 0` |
| **聚合粒度** | `data_date = 所选时间范围`，`platform, shop_info_id` |
| **数据类型** | decimal_1dp → 小数，保留一位小数，千分位 |
| **数据格式** | `#,##0.0` |
| **附属指标** | vs LY：今年 / 去年 - 1；vs LP：当期 / 上期 - 1 |

---

## 子模块七：UPT Breakdown

> **分组维度**: 按 New / Existing / All 客户类型分组，按 `platform, shop_info_id` 维度聚合。

### 1. UPT（Net） — 客单件

| 项目 | 内容 |
|---|---|
| **指标名称** | UPT（Net） |
| **指标名称中文** | 客单件 |
| **业务定义** | 商品净出库件数 / 净出库订单数 |
| **计算公式** | 分子：`sum(net_pay_qty)`；分母：`sum(net_pay_order_cnt)` |
| **分子** | `net_pay_qty`（`is_member = 0`） |
| **分母** | `net_pay_order_cnt`（`is_member = 0`） |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `is_member = 0` |
| **聚合粒度** | `data_date = 所选时间范围`，`platform, shop_info_id` |
| **数据类型** | decimal_1dp → 小数，保留一位小数，千分位 |
| **数据格式** | `#,##0.0` |
| **附属指标** | vs LY：今年 / 去年 - 1；vs LP：当期 / 上期 - 1 |

### 2. UPT（Demand） — 客单件

| 项目 | 内容 |
|---|---|
| **指标名称** | UPT（Demand） |
| **指标名称中文** | 客单件 |
| **业务定义** | 商品出库件数 / 出库订单数 |
| **计算公式** | 分子：`sum(pay_qty)`；分母：`sum(pay_order_cnt)` |
| **分子** | `pay_qty`（`is_member = 0`） |
| **分母** | `pay_order_cnt`（`is_member = 0`） |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `is_member = 0` |
| **聚合粒度** | `data_date = 所选时间范围`，`platform, shop_info_id` |
| **数据类型** | decimal_1dp → 小数，保留一位小数，千分位 |
| **数据格式** | `#,##0.0` |
| **附属指标** | vs LY：今年 / 去年 - 1；vs LP：当期 / 上期 - 1 |

---

## 子模块八：Class x Label Drilldown

> **分组维度**: 按 `category_summary`（Class x Label）维度分组。分母不受产品筛选器影响。

### 1. Net_Customer No. — 按品类汇总的净购买买家人数

| 项目 | 内容 |
|---|---|
| **指标名称** | Net_Customer No. |
| **指标名称中文** | 按品类汇总的净购买买家人数 |
| **业务定义** | 按品类汇总的净购买买家人数 |
| **计算公式** | 各 `category_summary` 下 `count(distinct user_id) where sum(net_pay_amt) > 0` |
| **统计字段** | `user_id` |
| **数据底表** | `t05_customer_order_data_d` |
| **筛选条件** | `data_date = 所选时间范围`，`sum(net_pay_amt) > 0` |
| **聚合粒度** | `platform, shop_info_id`，`brand, framework` |
| **数据类型** | integer → 整数，千分位整数 |
| **数据格式** | `#,##0` |

### 2. Net_SLS — 按品类汇总的净销售额

| 项目 | 内容 |
|---|---|
| **指标名称** | Net_SLS |
| **指标名称中文** | 按品类汇总的净销售额 |
| **业务定义** | 按品类汇总的净销售额 |
| **计算公式** | 各 `category_summary` 下 `sum(net_pay_amt)` |
| **统计字段** | `net_pay_amt` |
| **数据底表** | `t05_customer_order_data_d` |
| **筛选条件** | `data_date = 所选时间范围` |
| **聚合粒度** | `platform, shop_info_id`，`brand, framework` |
| **数据类型** | currency → 货币符号由币种切片器决定，千分位整数 |
| **数据格式** | `#,##0`（在 DAX 中用 `__CurrencySymbol & FORMAT(__Value, "#,##0")` 拼接币种符号） |

### 3. New Customer%（按人数） — 新客占比

| 项目 | 内容 |
|---|---|
| **指标名称** | New Customer%（按人数） |
| **指标名称中文** | 新客占比 |
| **业务定义** | 各筛选条件下新客占无任何筛选条件全客的比例 |
| **计算公式** | 分子：Step 1 在 `a03_e2e_customer_data_m` 筛选 `net_pay_amt > 0` 的 `user_id`（`is_member = 0`，`lp_12m_net_pay_amt = 0`）；Step 2 在 `t05_customer_order_data_d` 中 `data_date = 所选时间范围`，统计各 `category_summary` 下 `count(distinct user_id)` where `user_id` in Step 1 框定的 `user_id` 范围。分母：`t05_customer_order_data_d` 在 `data_date = 所选时间范围` 下 `count(distinct user_id) where sum(net_pay_amt) > 0`（**不受产品筛选器影响**） |
| **分子** | `user_id`（New 客户范围，按 `category_summary` 分组） |
| **分母** | `user_id`（全客，不受产品筛选器影响） |
| **数据底表** | `a03_e2e_customer_data_m`、`t05_customer_order_data_d` |
| **筛选条件** | `data_date = 所选时间范围`，`is_member = 0`，`lp_12m_net_pay_amt = 0`，`sum(net_pay_amt) > 0` |
| **聚合粒度** | 分子：`platform, shop_info_id, brand, framework`；分母：`platform, shop_info_id` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

### 4. TTL Customer%（按人数） — 全客占比

| 项目 | 内容 |
|---|---|
| **指标名称** | TTL Customer%（按人数） |
| **指标名称中文** | 全客占比 |
| **业务定义** | 各筛选条件下全客占无任何筛选条件全客的比例 |
| **计算公式** | 分子：在 `data_date = 所选时间范围`，统计各 `category_summary` 下 `count(distinct user_id) where sum(net_pay_amt) > 0`；分母：在 `data_date = 所选时间范围`，`count(distinct user_id) where sum(net_pay_amt) > 0`（**不受产品筛选器影响**） |
| **分子** | `user_id`（按 `category_summary` 分组） |
| **分母** | `user_id`（全客，不受产品筛选器影响） |
| **数据底表** | `t05_customer_order_data_d` |
| **筛选条件** | `data_date = 所选时间范围`，`sum(net_pay_amt) > 0` |
| **聚合粒度** | 分子：`platform, shop_info_id, brand, framework`；分母：`platform, shop_info_id` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

### 5. ±%（按人数） — 新客占比和全客占比差值（按人数）

| 项目 | 内容 |
|---|---|
| **指标名称** | ±%（按人数） |
| **指标名称中文** | 新客占比和全客占比差值 |
| **业务定义** | 新客占比 - 全客占比 |
| **计算公式** | New Customer%（按人数） - TTL Customer%（按人数） |
| **数据底表** | `t05_customer_order_data_d` |
| **聚合粒度** | `platform, shop_info_id`，`brand, framework` |
| **数据类型** | delta_pts → 增减基点整数：→ +120pts / -80pts（基点，含正负号，值×100 转 pts） |
| **数据格式** | `+#,##0pts;-#,##0pts;0pts` |

### 6. New Customer%（按金额） — 新客占比

| 项目 | 内容 |
|---|---|
| **指标名称** | New Customer%（按金额） |
| **指标名称中文** | 新客占比 |
| **业务定义** | 各筛选条件下新客净销售额占无任何筛选条件全客净销售额的比例 |
| **计算公式** | 分子：Step 1 在 `a03_e2e_customer_data_m` 筛选 `net_pay_amt > 0` 的 `user_id`（`is_member = 0`，`lp_12m_net_pay_amt = 0`）；Step 2 在 `t05_customer_order_data_d` 中 `data_date = 所选时间范围`，统计各 `category_summary` 下 `sum(net_pay_amt)` where `user_id` in Step 1 框定的 `user_id` 范围。分母：`t05_customer_order_data_d` 在 `data_date = 所选时间范围` 下 `sum(net_pay_amt)`（**不受产品筛选器影响**） |
| **分子** | `net_pay_amt`（New 客户范围，按 `category_summary` 分组） |
| **分母** | `net_pay_amt`（全客，不受产品筛选器影响） |
| **数据底表** | `a03_e2e_customer_data_m`、`t05_customer_order_data_d` |
| **筛选条件** | `data_date = 所选时间范围`，`is_member = 0`，`lp_12m_net_pay_amt = 0`，`sum(net_pay_amt) > 0` |
| **聚合粒度** | 分子：`platform, shop_info_id, brand, framework`；分母：`platform, shop_info_id` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

### 7. TTL Customer%（按金额） — 全客占比

| 项目 | 内容 |
|---|---|
| **指标名称** | TTL Customer%（按金额） |
| **指标名称中文** | 全客占比 |
| **业务定义** | 各筛选条件下全客净销售额占无任何筛选条件全客净销售额的比例 |
| **计算公式** | 分子：在 `data_date = 所选时间范围`，统计各 `category_summary` 下 `sum(net_pay_amt)`；分母：在 `data_date = 所选时间范围`，`sum(net_pay_amt)`（**不受产品筛选器影响**） |
| **分子** | `net_pay_amt`（按 `category_summary` 分组） |
| **分母** | `net_pay_amt`（全客，不受产品筛选器影响） |
| **数据底表** | `t05_customer_order_data_d` |
| **筛选条件** | `data_date = 所选时间范围` |
| **聚合粒度** | 分子：`platform, shop_info_id, brand, framework`；分母：`platform, shop_info_id` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

### 8. ±%（按金额） — 新客占比和全客占比差值（按金额）

| 项目 | 内容 |
|---|---|
| **指标名称** | ±%（按金额） |
| **指标名称中文** | 新客占比和全客占比差值 |
| **业务定义** | 新客占比 - 全客占比 |
| **计算公式** | New Customer%（按金额） - TTL Customer%（按金额） |
| **数据底表** | `t05_customer_order_data_d` |
| **聚合粒度** | `platform, shop_info_id`，`brand, framework` |
| **数据类型** | delta_pts → 增减基点整数：→ +120pts / -80pts（基点，含正负号，值×100 转 pts） |
| **数据格式** | `+#,##0pts;-#,##0pts;0pts` |

---

## 子模块九：Product 下钻

> **分组维度**: 按 `product_id` 维度分组，基于 `t05_customer_order_data_d` 表。

### 1. New_Customer No. — 新客买家人数

| 项目 | 内容 |
|---|---|
| **指标名称** | New_Customer No. |
| **指标名称中文** | 新客净购买买家人数 |
| **业务定义** | 新客在所选时间范围内各 `product_id` 下的买家人数 |
| **计算公式** | Step 1 在 `a03_e2e_customer_data_m` 筛选 `net_pay_amt > 0` 的 `user_id`（`is_member = 0`，`lp_12m_net_pay_amt = 0`）；Step 2 在 `t05_customer_order_data_d` 中 `data_date = 所选时间范围`，统计各 `product_id` 下 `count(distinct user_id)` where `user_id` in Step 1 框定的 `user_id` 范围 |
| **统计字段** | `user_id` |
| **数据底表** | `a03_e2e_customer_data_m`、`t05_customer_order_data_d` |
| **筛选条件** | `data_date = 所选时间范围`，`is_member = 0`，`lp_12m_net_pay_amt = 0`，`sum(net_pay_amt) > 0` |
| **聚合粒度** | `platform, shop_info_id`，`brand, framework` |
| **数据类型** | integer → 整数，千分位整数 |
| **数据格式** | `#,##0` |

### 2. New_SLS — 新客净销售额

| 项目 | 内容 |
|---|---|
| **指标名称** | New_SLS |
| **指标名称中文** | 新客净销售额 |
| **业务定义** | 新客在所选时间范围内各 `product_id` 下的净销售额 |
| **计算公式** | Step 1 在 `a03_e2e_customer_data_m` 筛选 `net_pay_amt > 0` 的 `user_id`（`is_member = 0`，`lp_12m_net_pay_amt = 0`）；Step 2 在 `t05_customer_order_data_d` 中 `data_date = 所选时间范围`，统计各 `product_id` 下 `sum(net_pay_amt)` where `user_id` in Step 1 框定的 `user_id` 范围 |
| **统计字段** | `net_pay_amt` |
| **数据底表** | `a03_e2e_customer_data_m`、`t05_customer_order_data_d` |
| **筛选条件** | `data_date = 所选时间范围`，`is_member = 0`，`lp_12m_net_pay_amt = 0`，`sum(net_pay_amt) > 0` |
| **聚合粒度** | `platform, shop_info_id`，`brand, framework` |
| **数据类型** | currency → 货币符号由币种切片器决定，千分位整数 |
| **数据格式** | `#,##0`（在 DAX 中用 `__CurrencySymbol & FORMAT(__Value, "#,##0")` 拼接币种符号） |

### 3. TTL_Customer No. — 全客买家人数

| 项目 | 内容 |
|---|---|
| **指标名称** | TTL_Customer No. |
| **指标名称中文** | 全客净购买买家人数 |
| **业务定义** | 全客在所选时间范围内各 `product_id` 下的买家人数 |
| **计算公式** | 在 `data_date = 所选时间范围`，统计各 `product_id` 下 `count(distinct user_id)` |
| **统计字段** | `user_id` |
| **数据底表** | `t05_customer_order_data_d` |
| **筛选条件** | `data_date = 所选时间范围`，`sum(net_pay_amt) > 0` |
| **聚合粒度** | `platform, shop_info_id`，`brand, framework` |
| **数据类型** | integer → 整数，千分位整数 |
| **数据格式** | `#,##0` |

### 4. TTL_SLS — 全客净销售额

| 项目 | 内容 |
|---|---|
| **指标名称** | TTL_SLS |
| **指标名称中文** | 全客净销售额 |
| **业务定义** | 全客在所选时间范围内各 `product_id` 下的净销售额 |
| **计算公式** | 在 `data_date = 所选时间范围`，统计各 `product_id` 下 `sum(net_pay_amt)` |
| **统计字段** | `net_pay_amt` |
| **数据底表** | `t05_customer_order_data_d` |
| **筛选条件** | `data_date = 所选时间范围` |
| **聚合粒度** | `platform, shop_info_id`，`brand, framework` |
| **数据类型** | currency → 货币符号由币种切片器决定，千分位整数 |
| **数据格式** | `#,##0`（在 DAX 中用 `__CurrencySymbol & FORMAT(__Value, "#,##0")` 拼接币种符号） |

### 5. Existing_Customer No. — 老客买家人数

| 项目 | 内容 |
|---|---|
| **指标名称** | Existing_Customer No. |
| **指标名称中文** | 老客净购买买家人数 |
| **业务定义** | 老客在所选时间范围内各 `product_id` 下的买家人数 |
| **计算公式** | Step 1 在 `a03_e2e_customer_data_m` 筛选 `net_pay_amt > 0` 的 `user_id`（`is_member = 0`，`lp_12m_net_pay_amt > 0`）；Step 2 在 `t05_customer_order_data_d` 中 `data_date = 所选时间范围`，统计各 `product_id` 下 `count(distinct user_id)` where `user_id` in Step 1 框定的 `user_id` 范围 |
| **统计字段** | `user_id` |
| **数据底表** | `a03_e2e_customer_data_m`、`t05_customer_order_data_d` |
| **筛选条件** | `data_date = 所选时间范围`，`is_member = 0`，`lp_12m_net_pay_amt > 0`，`sum(net_pay_amt) > 0` |
| **聚合粒度** | `platform, shop_info_id`，`brand, framework` |
| **数据类型** | integer → 整数，千分位整数 |
| **数据格式** | `#,##0` |

### 6. Existing_SLS — 老客净销售额

| 项目 | 内容 |
|---|---|
| **指标名称** | Existing_SLS |
| **指标名称中文** | 老客净销售额 |
| **业务定义** | 老客在所选时间范围内各 `product_id` 下的净销售额 |
| **计算公式** | Step 1 在 `a03_e2e_customer_data_m` 筛选 `net_pay_amt > 0` 的 `user_id`（`is_member = 0`，`lp_12m_net_pay_amt > 0`）；Step 2 在 `t05_customer_order_data_d` 中 `data_date = 所选时间范围`，统计各 `product_id` 下 `sum(net_pay_amt)` where `user_id` in Step 1 框定的 `user_id` 范围 |
| **统计字段** | `net_pay_amt` |
| **数据底表** | `a03_e2e_customer_data_m`、`t05_customer_order_data_d` |
| **筛选条件** | `data_date = 所选时间范围`，`is_member = 0`，`lp_12m_net_pay_amt > 0`，`sum(net_pay_amt) > 0` |
| **聚合粒度** | `platform, shop_info_id`，`brand, framework` |
| **数据类型** | currency → 货币符号由币种切片器决定，千分位整数 |
| **数据格式** | `#,##0`（在 DAX 中用 `__CurrencySymbol & FORMAT(__Value, "#,##0")` 拼接币种符号） |

---

## 子模块十：Co-Purchase Matrix

> **分组维度**: 按 `customer_type`、`brand, category_summary` 分组，起点品类 A 对目标品类 B 的连带率。

### 1. Same-Order Cross-Sell — 同单连带率

| 项目 | 内容 |
|---|---|
| **指标名称** | Same-Order Cross-Sell |
| **指标名称中文** | 同单连带率 |
| **业务定义** | 同一订单中同时购买起点品类 A 和目标品类 B 的订单数 / 购买起点品类 A 的订单数 |
| **计算公式** | 分子：`sum(net_pay_order_cnt)`；分母：`sum(co_net_pay_order_cnt)` |
| **分子** | `net_pay_order_cnt`（同单同时购买 A 和 B 的订单数） |
| **分母** | `co_net_pay_order_cnt`（购买起点品类 A 的订单数） |
| **数据底表** | `a03_e2e_customer_order_correlation_data_m` |
| **筛选条件** | `data_month = 所选月份`，`correlation_period = 所选时间区间`，`correlation_type = "same_order"` |
| **聚合粒度** | `platform, shop_info_id`，`customer_type`，`brand, category_summary` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

### 2. Cross-Order Cross-Sell — 跨单连带率

| 项目 | 内容 |
|---|---|
| **指标名称** | Cross-Order Cross-Sell |
| **指标名称中文** | 跨单连带率 |
| **业务定义** | 购买起点品类 A 后，在追踪周期内通过不同订单购买目标品类 B 的买家数 / 购买起点品类 A 的买家数 |
| **计算公式** | 分子：`count(distinct user_id)`（追踪周期内购买 B 的买家数）；分母：`count(distinct user_id) where 纵轴 = brand/category_summary`（购买 A 的买家数） |
| **分子** | `user_id`（跨单购买 B 的买家数） |
| **分母** | `user_id`（购买 A 的买家数） |
| **数据底表** | `a03_e2e_customer_order_correlation_data_m` |
| **筛选条件** | `data_month = 所选月份`，`correlation_period = 所选时间区间`，`correlation_type = "cross_order"` |
| **聚合粒度** | `platform, shop_info_id`，`customer_type`，`brand, category_summary` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

---

## 子模块十一：Product Path

> **分组维度**: 按 `customer_type`、`brand, category_summary` 分组，展示客人第 1/2/3 次购买商品路径。

### 1. Product Path — 商品购买路径

| 项目 | 内容 |
|---|---|
| **指标名称** | Product Path |
| **指标名称中文** | 商品购买路径 |
| **业务定义** | 展示客人第 1/2/3 次购买商品路径，支持选择追踪周期 3/6/9 个月 |
| **计算公式** | 在 `brand/category_summary` 粒度，`count(distinct user_id) where payment_time_seq = 1/2/3` |
| **统计字段** | `user_id`、`payment_time_seq` |
| **数据底表** | `a03_e2e_customer_time_ordered_data_m` |
| **筛选条件** | `dt = 所选月份`，`period = 所选时间区间`，`payment_time_seq IN (1, 2, 3)` |
| **聚合粒度** | `platform, shop_info_id`，`customer_type`，`brand, category_summary` |
| **数据类型** | integer → 整数，千分位整数 |
| **数据格式** | `#,##0` |

> **注**: Product Path 模块使用 `a03_e2e_customer_time_ordered_data_m` 表的 `dt` 字段（订单日期），与主数据底表 `a03_e2e_customer_data_m` 的 `data_date` 字段不同。`correlation_period` / `period` 为追踪周期参数。

---

## 通用规则汇总

| 规则项 | 说明 |
|---|---|
| **数据底表（实际值）** | `a03_e2e_customer_data_m`、`t05_customer_order_data_d`、`a03_e2e_customer_order_correlation_data_m`、`a03_e2e_customer_time_ordered_data_m` |
| **数据底表（目标值）** | `a03_e2e_customer_fcst_data_m`，日期字段 `data_date` |
| **目标值聚合方式** | `data_date = 所选时间范围`，`group by platform, shop_info_id` |
| **筛选逻辑** | Net 维度基于 `net_pay_amt` / `net_pay_qty` / `net_pay_order_cnt`；Demand 维度基于 `pay_amt` / `pay_qty` / `pay_order_cnt`；会员统一 `is_member = 0`（非会员） |
| **货币转换规则** | 数据源默认为 RMB，转化为美元需要除以固定值 7 |
| **派生指标** | LY（去年同期）、LP（上期）、vs LY（同比）、vs LP（环比）、占比、YOY、vs Store 等为派生指标，依据基础指标计算生成 |
| **分组维度** | 根据 `platform, shop_info_id`、`brand, framework`、`customer_type`、`category_summary`、`product_id` 等分组 |
| **必须遵守** | 口径文档中定义的所有指标，必须遵守其数据类型和数据格式，如果和解决方案中存在争议的，一切以口径文档为准，必须按照口径文档中的格式进行调整 |
| **DAX 语法规范** | 文本常量必须使用双引号 `" "`，禁止使用单引号；单引号 `' '` 仅用于表名，列名使用方括号 `[ ]`，例如：`[is_member] = 0` |
| **pts 与 bp 区别** | pts 指标：值×100 转 pts（基点，含正负号），数据格式 `+#,##0pts;-#,##0pts;0pts`；bp 指标：值×10000 转 bp，数据格式 `+#,##0bp;-#,##0bp;0bp` |
| **TAR ACH% 计算** | 实现方式：SUMX+SUMMARIZE，SUMMARIZE 按所需维度分组去重，再 SUMX 求和；DISTINCT 返回表非标量，不能在 SUMX 内当值用，用 SUMMARIZE 分组等价实现 DISTINCT 去重后再 SUM |
| **TAR ACH% 通用公式** | TAR ACH% = Actual / Target，结果按 percent_1dp 格式展示 |
| **TAR ACH% 留空处理** | 当计算规则标注为「留空」时，该指标在对应场景下显示为空值或隐藏 |
| **跨财年判定** | 当所选时间范围跨越两个及以上财年时，视为跨财年场景 |
| **单选/多选判定** | 仅选择单个财月或单个财年时计算 TAR ACH%，选择多个时间单位时留空 |
| **VIC 定义** | 在指定日期范围往前 Rolling 12 个财月，net sales >= 20k 的买家 |
| **Tier 分层定义** | T1：≧ 200K；T2：80-200K；T3：20-80K；T4：5-20K；T5：< 5K |
| **Recency 分层定义** | R3：上财年 10-12 月；R4-6：上财年 7-9 月；R7-9：上财年 4-6 月；R10-12：上财年 1-3 月；TTL：全部 |
