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
| **新客/老客判定（Net）** | New：`lp_12m_net_pay_amt = 0`（start period 往前推 12 个月无净销售额）；Existing：`lp_12m_net_pay_amt > 0`（start period 往前推 12 个月有净销售额）；All：不限定 `lp_12m_net_pay_amt` |
| **新客/老客判定（Demand）** | New：`lp_12m_pay_amt = 0`；Existing：`lp_12m_pay_amt > 0`；All：不限定 `lp_12m_pay_amt` |
| **DAX 语法规范** | 文本常量必须使用双引号 `" "`，禁止使用单引号；单引号 `' '` 仅用于表名，列名使用方括号 `[ ]`，例如：`[is_member] = 0` |
| **pts 与 bp 区别** | pts 指标：值×100 转 pts（基点，含正负号），数据格式 `+#,##0pts;-#,##0pts;0pts`；bp 指标：值×10000 转 bp，数据格式 `+#,##0bp;-#,##0bp;0bp` |
| **TAR ACH%实现** | 实现方式：SUMX+SUMMARIZE，SUMMARIZE 按所需维度分组去重，再 SUMX 求和；DISTINCT 返回表非标量，不能在 SUMX 内当值用，用 SUMMARIZE 分组等价实现 DISTINCT 去重后再 SUM |
| **VIC 定义** | 在指定日期范围往前 Rolling 12 个财月，net sales >= 20k 的买家 |
| **Tier 分层定义** | T1：≧ 200K；T2：80-200K；T3：20-80K；T4：5-20K；T5：< 5K |
| **Recency 分层定义** | R3：上财年 10-12 月；R4-6：上财年 7-9 月；R7-9：上财年 4-6 月；R10-12：上财年 1-3 月；TTL：全部 |
| **start_period说明** | `data_date ∈ [First_Fiscal_Month_Min, First_Fiscal_Month_Max]`，所选时间范围的第一个财月,Slicer_Time_Frame_Min维度表已经给出了具体的First_Fiscal_Month、First_Fiscal_Month_Min等字段，只关注Slicer_Time_Frame_Min值,比如2026-09，只关注2023-09；2026 Q2，只关注2026-04；财年2026，对应最后一个财月只关注2026-01，然后都转化为具体的天维度范围； |
| **end period说明** | `data_date ∈ [Last_Fiscal_Month_Min, Last_Fiscal_Month_Max]`，所选时间范围的最后一个财月,Slicer_Time_Frame_Max维度表已经给出了具体的Last_Fiscal_Month、Last_Fiscal_Month_Min等字段，只关注Slicer_Time_Frame_Max值,比如2026-09，只关注2023-09；2026 Q2，只关注2026-06；财年2026，对应最后一个财月只关注2026-12，然后都转化为具体的天维度范围； |
| **data_date = 所选时间范围** | `data_date` ∈ `[__TimeMin, __TimeMax]`（全局时间范围），Slicer_Time_Frame_Min 和 Slicer_Time_Frame_Max 维度表已经给出具体的 TimeFrame_Min 和 TimeFrame_Max 值；`data_date = 所选时间范围` 即 `data_date ∈ [TimeFrame_Min, TimeFrame_Max]`，TimeFrame_Min从Slicer_Time_Frame_Min表取值，TimeFrame_Max从Slicer_Time_Frame_Max表取值|
| **platform, shop_info_id维度分组说明** | 在没有特殊说明的情况下，由表字段自动传递，DAX 无需显式处理分组|

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
| **筛选条件** | Step 1：在所选时间范围内筛选 `net_pay_amt > 0` 的 `user_id`（`data_date = 所选时间范围`，`is_member = 0`，`net_pay_amt > 0`）；Step 2：缩小顾客范围至 `lp_12m_net_pay_amt = 0`（`data_date = 所选时间范围 start_period`）；相当于取Step 1和Step 2的交集，最后count(distinct user_id) |
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
| **数据类型** | delta_pct_1dp → 百分比，保留一位小数，含正号：+14.5% / -3.2% |
| **数据格式** | IF(__Value > 0, "+", "") & FORMAT(__Value, "#,##0.0%") |

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
| **数据类型** | delta_pct_1dp → 百分比，保留一位小数，含正号：+14.5% / -3.2% |
| **数据格式** | IF(__Value > 0, "+", "") & FORMAT(__Value, "#,##0.0%") |

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
| Month | 选择多个财月 |  New Customer No.（month actual） | `SUM(new_customer_cnt)` | 实际值 / 月度目标值 |
| Month | 选择多个财月且跨财年 |  New Customer No.（month actual） | `SUM(new_customer_cnt)` | 实际值 / 月度目标值 |
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
| **目标值取数逻辑** | `data_date = 所选时间范围`，`data_date ∈ [TimeFrame_Min, TimeFrame_Max]`（全局时间范围），目标值 = `SUM(DISTINCT year_new_customer_cnt)`；Slicer_Time_Frame[TimeFrame_ID]等于"Month"或者"Quarter"，这里需要判断是否跨财年 |
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
| Month | 选择多个财月 |  New Customer No.（month actual） | `SUM(DISTINCT year_new_customer_cnt)` | 单月实际 / 年度目标值 |
| Month | 选择多个财月且跨财年 | — | — | **留空** |
| Quarter | 选择单个季度且不跨财年 | New Customer No.（quarter actual） | `SUM(DISTINCT year_new_customer_cnt)` | 季度实际 / 年度目标值 |
| Quarter | 选择多个季度且不跨财年 | New Customer No.（quarter actual） | `SUM(DISTINCT year_new_customer_cnt)` | 季度实际 / 年度目标值 |
| Quarter | 跨财年 | — | — | **留空**，跨财年不计算 Yearly TAR ACH% |
| Year | 选择单个财年 | New Customer No.（year actual） | `SUM(DISTINCT year_new_customer_cnt)` | 年度实际 / 年度目标值 |
| Year | 选择多个财年 | New Customer No.（year actual） | `SUM(DISTINCT year_new_customer_cnt)` | 年度实际 / 年度目标值 |

---

### 2. DCom New Customer% — DCom新客占比

| 项目 | 内容 |
|---|---|
| **指标名称** | DCom New Customer% |
| **指标名称中文** | DCom新客占比 |
| **业务定义** | DCom新客数/DCom总客数 |
| **计算公式** | 分子：DCom New Customer No. — DCom新客数；分母：`count(distinct user_id)`（全部） |
| **分子** | DCom New Customer No. — DCom新客数 |
| **分母** | count(distinct user_id) ：`user_id`（全部，`is_member = 0` 且 `net_pay_amt > 0`） |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `data_date = 所选时间范围`，`net_pay_amt > 0`，`is_member = 0` |
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
| **筛选条件** | `data_date = 所选时间范围`，`net_pay_amt > 0`，`is_member = 0` |
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
| **筛选条件** | `data_date = 所选时间范围`，`net_pay_amt > 0`，`is_member = 0` |
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
