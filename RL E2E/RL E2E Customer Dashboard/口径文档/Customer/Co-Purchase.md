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
| **start_period说明** | `data_date ∈ [First_Fiscal_Month_Min, First_Fiscal_Month_Max]`，所选时间范围的第一个财月,Slicer_Time_Frame_Min维度表已经给出了具体的First_Fiscal_Month、First_Fiscal_Month_Min等字段，只关注Slicer_Time_Frame_Min值,比如2026-09，只关注2023-09；2026 Q2，只关注2026-04；财年2026，对应最后一个财月只关注2026-01，然后都转化为具体的天维度范围； |
| **end period说明** | `data_date ∈ [Last_Fiscal_Month_Min, Last_Fiscal_Month_Max]`，所选时间范围的最后一个财月,Slicer_Time_Frame_Max维度表已经给出了具体的Last_Fiscal_Month、Last_Fiscal_Month_Min等字段，只关注Slicer_Time_Frame_Max值,比如2026-09，只关注2023-09；2026 Q2，只关注2026-06；财年2026，对应最后一个财月只关注2026-12，然后都转化为具体的天维度范围； |
| **data_date = 所选时间范围** | `data_date` ∈ `[__TimeMin, __TimeMax]`（全局时间范围），Slicer_Time_Frame_Min 和 Slicer_Time_Frame_Max 维度表已经给出具体的 TimeFrame_Min 和 TimeFrame_Max 值；`data_date = 所选时间范围` 即 `data_date ∈ [TimeFrame_Min, TimeFrame_Max]`，TimeFrame_Min从Slicer_Time_Frame_Min表取值，TimeFrame_Max从Slicer_Time_Frame_Max表取值|
| **platform, shop_info_id维度分组说明** | 在没有特殊说明的情况下，由表字段自动传递，DAX 无需显式处理分组|
| **净销售额New、Existing、All三种情况总结** | start_period（data_date ∈ [Slicer_Time_Frame_Min[First_Fiscal_Month_Min], Slicer_Time_Frame_Min[First_Fiscal_Month_Max]]）、slicer所选时间区间（data_date ∈ [Slicer_Time_Frame_Min[TimeFrame_Min], Slicer_Time_Frame_Max[TimeFrame_Max]]）；start_period 是 slicer 区间的子集，技术实现上可以“合并区间”，用于判断 lp_12m_net_pay_amt = 0 或者 lp_12m_net_pay_amt > 0的行，一定也在 slicer 区间内 ，所以，
New：distinct user_id WHERE data_date ∈ start_period AND net_pay_amt > 0 AND is_member = 0 AND lp_12m_net_pay_amt = 0得到新客的user_id，然后再SUM(net_pay_amt) WHERE data_date ∈ [Slicer_Time_Frame_Min[TimeFrame_Min], Slicer_Time_Frame_Max[TimeFrame_Max]]  AND is_member = 0 AND user_id in (新客user_id)；
Existing:distinct user_id WHERE data_date ∈ start_period AND net_pay_amt > 0 AND is_member = 0 AND lp_12m_net_pay_amt > 0得到老客的user_id，然后再SUM(net_pay_amt) WHERE data_date ∈ [Slicer_Time_Frame_Min[TimeFrame_Min], Slicer_Time_Frame_Max[TimeFrame_Max]]  AND is_member = 0 AND user_id in (老客user_id)；
ALL: SUM(net_pay_amt) WHERE data_date ∈ [Slicer_Time_Frame_Min[TimeFrame_Min], Slicer_Time_Frame_Max[TimeFrame_Max]]  AND is_member = 0|

---

## 子模块十：Co-Purchase Matrix

> **分组维度**: 按 `customer_type`、`brand, category_summary` 分组，起点品类 A 对目标品类 B 的连带率。

### 1. Same-Order Cross-Sell — 同单连带率

| 项目 | 内容 |
|---|---|
| **指标名称** | Same-Order Cross-Sell |
| **指标名称中文** | 同单连带率 |
| **业务定义** | 同一订单中同时购买起点品类 A 和目标品类 B 的订单数 / 购买起点品类 A 的订单数 |
| **计算公式** | 分子：`sum(co_net_pay_order_cnt)`；分母：`sum(net_pay_order_cnt)` |
| **分子** | `co_net_pay_order_cnt`（同单同时购买 A 和 B 的订单数） |
| **分母** | `net_pay_order_cnt`（购买起点品类 A 的订单数） |
| **数据底表** | `a03_e2e_customer_order_correlation_data_m` |
| **筛选条件** | `data_month = 所选月份`，`correlation_period = 所选时间区间`，`correlation_type = "same_order"`，这里和其他模块不同，无需使用Dax显示处理筛选，我已经做了模型关系或者直接使用的表字段，关系会自动处理筛选 |
| **聚合粒度** | `platform, shop_info_id`，`customer_type`，`brand, category_summary` |
| **数据类型** | percent_0dp → 百分比整数，不含正号 |
| **数据格式** | `#,##0%` |

### 2. Cross-Order Cross-Sell — 跨单连带率

| 项目 | 内容 |
|---|---|
| **指标名称** | Cross-Order Cross-Sell |
| **指标名称中文** | 跨单连带率 |
| **业务定义** | 购买起点品类 A 后，在追踪周期内通过不同订单购买目标品类 B 的买家数 / 购买起点品类 A 的买家数 |
| **计算公式** | 分子：`count(distinct user_id)`（追踪周期内购买 B 的买家数）；分母：`count(distinct user_id) where 纵轴 = brand/category_summary`（购买 A 的买家数），移除图表中a03_e2e_customer_order_correlation_data_m[co_brand]或者[co_category_summary]字段筛选，同时保留外部筛选器的筛选,根据Class和Label按钮选择。 |
| **分子** | `user_id`（跨单购买 B 的买家数） |
| **分母** | `user_id`（购买 A 的买家数） |
| **数据底表** | `a03_e2e_customer_order_correlation_data_m` |
| **筛选条件** | `data_month = 所选月份`，`correlation_period = 所选时间区间`，`correlation_type = "cross_order"`，这里和其他模块不同，无需使用Dax显示处理筛选，我已经做了模型关系或者直接使用的表字段，关系会自动处理筛选 |
| **聚合粒度** | `platform, shop_info_id`，`customer_type`，`brand, category_summary` |
| **数据类型** | percent_0dp → 百分比整数，不含正号 |
| **数据格式** | `#,##0%` |

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
| **筛选条件** | `dt = 所选月份`，`period = 所选时间区间`，dt和period无需使用Dax显示处理筛选，我已经做了模型关系或者直接使用的表字段，关系会自动处理筛选，`payment_time_seq IN (1, 2, 3)`需要分为三个度量输出，依次为`user_id where payment_time_seq = 1`、`user_id where payment_time_seq = 2`、`user_id where payment_time_seq = 3` |
| **聚合粒度** | `platform, shop_info_id`，`customer_type`，`brand, category_summary` |
| **数据类型** | integer → 整数，千分位整数 |
| **数据格式** | `#,##0` |

> **注**: `correlation_period` / `period` 为追踪周期参数，直接取自表字段，无需使用Dax显示处理筛选。

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
