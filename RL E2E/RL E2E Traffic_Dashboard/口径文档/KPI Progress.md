# KPI Progress 指标口径提示词

> **Dashboard**: DCom Performance Media Dashboard  
> **Tab**: KPI Progress  
> **数据底表（实际值）**: `a05_e2e_paid_media_summary_d` / `a05_e2e_paid_media_product_data` / `a03_e2e_customer_data_m`  
> **数据底表（目标值）**: `a05_e2e_paid_media_fcst_data_m`，日期字段 `data_date`  
> **模块说明**: 本板块为 KPI 进度看板，覆盖 KPIs、Performance Indicators、New Acquisition KPI Trend、Category Growth KPI Trend、KPI by Platform 五个子板块，统计媒体花费、销售达成、新客获取、第二品类增长及分平台表现。

---

## 全局逻辑

| 项目 | 内容 |
|---|---|
| **数据底表（实际值）** | 汇总指标用 `a05_e2e_paid_media_summary_d`；第二品类（Acceleration）系列用 `a05_e2e_paid_media_product_data`；全店新客用 `a03_e2e_customer_data_m` |
| **数据底表（目标值）** | `a05_e2e_paid_media_fcst_data_m`（预测专用表），日期字段 `data_date` |
| **page_type 筛选** | 本板块统一 `page_type="1"`（仅汇总表） |
| **customer_type 筛选** | 按指标区分 `ALL`（全客）或 `NEW`（新客）；媒体新客类指标（`media_member_cnt`/`media_cost_amt`）统一 `customer_type='ALL' AND page_type=1` |
| **日期切片器** | `Slicer_Time_Frame`：`TimeFrame_ID`（时间粒度 Month/Quarter/Year），`TimeFrame_Value`（展示值），所选时间区间 `data_date ∈ [TimeFrame_Min, TimeFrame_Max]` |
| **时间粒度处理** | Month 按所选财月完整日期范围汇总；Quarter 按所选财季完整日期范围汇总；Year 按所选财年完整日期范围汇总 |
| **媒体新客字段聚合** | `media_member_cnt`/`media_cost_amt` 先按 platform、shop_id、data_month_name(包含data_year + data_month属性) 取 `MAX`，再对所选财月及平台 `SUM`；仅支持完整财月、财季、财年，Slicer_Time_Frame[TimeFrame_ID] in ("Day","Week")时不考虑，为空。 |
| **全店新客判定（Net）** | 数据底表 `a03_e2e_customer_data_m`：Step1 在所选时间范围内 `SUM(net_pay_amt) > 0 AND is_member = 0`；Step2 缩小至 `start_period` 往前推 12 个月 `lp_12m_net_pay_amt = 0`（`data_date = 所选时间范围 start_period`）；两步交集即为全店新客。Month 按财月、`platform` 对 `user_id` 去重计数；Quarter、Year 及 `Platform=ALL` 去重范围复用 Customer Dashboard 同 Timeframe、同 Period 逻辑 |
| **第二品类（Acceleration）筛选** | Acceleration 系列实际值从 `a05_e2e_paid_media_product_data` 取数；Cost 类指标分子需 `mix_msg is NULL AND framework='Acceleration'`，分母需 `mix_msg is NULL`（不限制 framework）；SLS 类指标分子需 `framework='Acceleration'`，分母不限制 framework |
| **分子/分母标记** | Excel 中以 `└ 分子` / `└ 分母` 行标注派生指标的分子分母取数，本文件在各指标中合并展示 |
| **派生指标** | Cost vs SLS ACH%、Media Contribution to New Customer Acquisition%、Cost Per New Acquisition、± Acceleration Cost MOB% vs Store SLS MOB% 等为派生指标，本身无独立统计字段，依据其分子/分母行取数计算 |
| **TAR ACH% 结构** | TAR ACH% 类指标采用 Actual / Target / ±Actual vs Target 三段式；Target 取数按 Month/Quarter/Year 粒度来自 `a05_e2e_paid_media_fcst_data_m`；±Actual vs Target 默认 `Actual - Target`（Cost Per New Acquisition 为 `Actual / Target - 1`） |
| **Target 缺失处理** | Target 缺失时，Target 及 ±Actual vs Target 展示"-"；Cost Per New Acquisition 额外处理 Target=0 及 `media_member_cnt`=0 |
| **必须遵守** | 口径文档中定义的所有指标，必须遵守其数据类型和数据格式，如果和解决方案中存在争议的，一切以口径文档为准，必须按照口径文档中的格式进行调整 |
| **DAX 语法规范** | 文本常量必须使用双引号 `" "`，禁止使用单引号；单引号 `' '` 仅用于表名，列名使用方括号 `[ ]`，例如：`[framework] = "Acceleration"`、`[customer_type] = "ALL"` |

---

## 子模块一：KPIs

> **无分组维度**: 只受到筛选器影响，没有分组维度，用于制作PowerBI卡片图。

### 1. Media Cost Rate — 媒体花费占比

| 项目 | 内容 |
|---|---|
| **指标名称** | Media Cost Rate / 媒体花费占比 |
| **业务定义** | 实际总媒体花费占比退后金额的百分比 |
| **计算公式** | Cost / Net Sales × 1.13 / 1.06 |
| **分子** | `cost_amt`（含红包/返佣返货金，字段值本身就含红包、返佣金，不需要额外计算） |
| **分母** | `net_sales_amt` |
| **数据底表** | `a05_e2e_paid_media_summary_d` |
| **筛选条件** | `customer_type='ALL' AND page_type="1"` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%;-#,##0.0%;0.0%` |

---

### 2. Media Cost — 媒体花费

| 项目 | 内容 |
|---|---|
| **指标名称** | Media Cost / 媒体花费 |
| **业务定义** | 实际媒体花费（绝对值） |
| **计算公式** | 同 Cost（实际媒体花费） |
| **统计字段** | `cost_amt`（含红包/返佣返货金，字段值本身就含红包、返佣金，不需要额外计算） |
| **数据底表** | `a05_e2e_paid_media_summary_d` |
| **筛选条件** | `customer_type='ALL' AND page_type="1"` |
| **数据类型** | currency → 货币符号由币种切片器决定，千分位整数 |
| **数据格式** | `#,##0`（在 DAX 中用 `__CurrencySymbol & FORMAT(__Value, "#,##0")` 拼接币种符号） |

---

### 3. Cost ACH% — 花费进度达成

| 项目 | 内容 |
|---|---|
| **指标名称** | Cost ACH% / 花费进度达成 |
| **业务定义** | 目标花费进度达成 |
| **Actual 计算公式** | `SUM(cost_amt) / Cost Target` |
| **Target 计算公式** | `100%`（固定值） |
| **±Actual vs Target** | Actual - Target |
| **Actual 分子数据底表** | `a05_e2e_paid_media_summary_d`，筛选条件：`customer_type='ALL' AND page_type="1"` |
| **Actual 分母数据底表** | `a05_e2e_paid_media_fcst_data_m` |
| **Actual 筛选条件** | 分子：`customer_type='ALL' AND page_type="1"`；分母：根据 `Slicer_Time_Frame[TimeFrame_ID]` 时间粒度的不同，使用不同的字段 `cost_amt`（Month/Quarter）或 `year_cost_amt`（Year） |
| **Actual 时间处理** | Month和Quarter使用platform、shop_id、data_month_name维度分组聚合，Year使用platform、shop_id、data_year维度分组聚合；Month：按所选财月完整日期范围汇总 `cost_amt`，除以该财月 Cost Target（`cost_amt`）；Quarter：汇总所选财季3个财月 `cost_amt`，除以 `SUM(cost_amt)`；Year：按所选财年完整日期范围汇总 `cost_amt`，除以 `MAX(year_cost_amt)`（按 `data_year`） |
| **注意** | Actual = Actual 分子 / Actual 分母；Target 固定为 100%（即1）；±Actual vs Target = Actual - Target |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%;-#,##0.0%;0.0%` |

**Cost ACH% 计算规则矩阵**

| TimeFrame | 选择范围 | 分子（Actual） | 分母（Target） | 说明 |
|---|---|---|---|---|
| Month | 选择单个财月 | `SUM(cost_amt)`（month actual） | `cost_amt` | 单月实际花费 / 月度目标花费 |
| Month | 选择多个财月（不跨财年） | `SUM(cost_amt)`（区间 actual） | `SUM(cost_amt)` | 区间实际花费 / 区间目标花费 |
| Month | 选择多个财月且跨财年 | — | `SUM(cost_amt)`（区间 actual） | `SUM(cost_amt)` | 区间实际花费 / 区间目标花费 |
| Quarter | 选择单个季度且不跨财年 | `SUM(cost_amt)`（quarter actual） | `SUM(cost_amt)` | 季度实际花费 / 季度目标花费 |
| Quarter | 选择多个季度且不跨财年 | `SUM(cost_amt)`（区间 actual） | `SUM(cost_amt)` | 区间实际花费 / 区间目标花费 |
| Quarter | 跨财年 | `SUM(cost_amt)`（区间 actual） | `SUM(cost_amt)` | 区间实际花费 / 区间目标花费 |
| Year | 选择单个财年 | `SUM(cost_amt)`（year actual） | `SUM(year_cost_amt)` | 年度实际花费 / 年度目标花费 |
| Year | 选择多个财年 | `SUM(cost_amt)`（year actual） | `SUM(year_cost_amt)` | 年度实际花费 / 年度目标花费 |

---

### 4. Cost vs SLS ACH% — 花费vs销售达成

| 项目 | 内容 |
|---|---|
| **指标名称** | Cost vs SLS ACH% / 花费vs销售达成 |
| **业务定义** | 花费进度达成 vs 销售进度达成差异 |
| **计算公式** | Cost ACH% − SLS ACH% |
| **数据底表** | 派生指标：Cost ACH%（#3）减 SLS ACH%（#5），无独立底表取数 |
| **筛选条件** | 派生：Cost ACH% − SLS ACH%，根据 Cost ACH% 行和 SLS ACH% 行生成 |
| **数据类型** | delta_bp → 增减基点整数：→ +120bp / -80bp（基点，含正负号，值×10000 转 bp），乘以 10000 的操作可以放在 Cell Display 度量中实现 |
| **数据格式** | `+#,##0bp;-#,##0bp;0bp` |

---

### 5. SLS ACH% — 目标达成率

| 项目 | 内容 |
|---|---|
| **指标名称** | SLS ACH% / 目标达成率 |
| **业务定义** | 退后销售额目标达成率 |
| **Actual 计算公式** | `SUM(net_sales_amt) / Net Sales Target` |
| **Target 计算公式** | `100%`（固定值） |
| **±Actual vs Target** | Actual - Target |
| **Actual 分子数据底表** | `a05_e2e_paid_media_summary_d`，筛选条件：`customer_type='ALL' AND page_type="1"` |
| **Actual 分母数据底表** | `a05_e2e_paid_media_fcst_data_m` |
| **Actual 筛选条件** | 分子：`customer_type='ALL' AND page_type="1"`；分母：根据 `Slicer_Time_Frame[TimeFrame_ID]` 时间粒度的不同，使用不同的字段 `net_sales_amt`（Month/Quarter）或 `year_net_sales_amt`（Year） |
| **Actual 时间处理** | Month和Quarter使用platform、shop_id、data_month_name维度分组聚合，Year使用platform、shop_id、data_year维度分组聚合；Month：按所选财月完整日期范围汇总 `net_sales_amt`，除以该财月 Net Sales Target（`net_sales_amt`）；Quarter：汇总所选财季3个财月 `net_sales_amt`，除以 `SUM(net_sales_amt)`；Year：按所选财年完整日期范围汇总 `net_sales_amt`，除以 `MAX(year_net_sales_amt)`（按 `data_year`） |
| **注意** | Actual = Actual 分子 / Actual 分母；Target 固定为 100%（即1）；±Actual vs Target = Actual - Target |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%;-#,##0.0%;0.0%` |

**SLS ACH% 计算规则矩阵**

| TimeFrame | 选择范围 | 分子（Actual） | 分母（Target） | 说明 |
|---|---|---|---|---|
| Month | 选择单个财月 | `SUM(net_sales_amt)`（month actual） | `net_sales_amt` | 单月实际退后销售额 / 月度目标退后销售额 |
| Month | 选择多个财月（不跨财年） | `SUM(net_sales_amt)`（区间 actual） | `SUM(net_sales_amt)` | 区间实际 / 区间目标 |
| Month | 选择多个财月且跨财年 | `SUM(net_sales_amt)`（区间 actual） | `SUM(net_sales_amt)` | 区间实际 / 区间目标 |
| Quarter | 选择单个季度且不跨财年 | `SUM(net_sales_amt)`（quarter actual） | `SUM(net_sales_amt)` | 季度实际 / 季度目标 |
| Quarter | 选择多个季度且不跨财年 | `SUM(net_sales_amt)`（区间 actual） | `SUM(net_sales_amt)` | 区间实际 / 区间目标 |
| Quarter | 跨财年 | `SUM(net_sales_amt)`（区间 actual） | `SUM(net_sales_amt)` | 区间实际 / 区间目标 |
| Year | 选择单个财年 | `SUM(net_sales_amt)`（year actual） | `MAX(year_net_sales_amt)` | 年度实际 / 年度目标 |
| Year | 选择多个财年 | `SUM(net_sales_amt)`（year actual） | `MAX(year_net_sales_amt)` | 年度实际 / 年度目标 |

---

### 6. SLS DCom — 退后销售额

| 项目 | 内容 |
|---|---|
| **指标名称** | SLS DCom / 退后销售额 |
| **业务定义** | 退后销售额 |
| **计算公式** | `net_sales_amt` 加总 |
| **统计字段** | `net_sales_amt` |
| **数据底表** | `a05_e2e_paid_media_summary_d` |
| **筛选条件** | `customer_type='ALL' AND page_type="1"` |
| **数据类型** | currency → 货币符号由币种切片器决定，千分位整数 |
| **数据格式** | `#,##0`（在 DAX 中用 `__CurrencySymbol & FORMAT(__Value, "#,##0")` 拼接币种符号） |

---

### 7. Media Contribution to New Customer Acquisition% — 媒体新客贡献率

| 项目 | 内容 |
|---|---|
| **指标名称** | Media Contribution to New Customer Acquisition% / 媒体新客贡献率 |
| **业务定义** | 媒体新客贡献率 |
| **Actual 计算公式** | 媒体新客数 / 全店新客数 |
| **分子** | `media_member_cnt`（媒体新客数，`a05_e2e_paid_media_summary_d`） |
| **分子筛选条件** | `customer_type='ALL' AND page_type="1"`；Month、Quarter、Year 先按 platform、shop_id、data_month_name(包含data_year + data_month属性) 取 `MAX(media_member_cnt)`，再对所选财月 `SUM`。仅支持完整财月、财季、财年，Slicer_Time_Frame[TimeFrame_ID] in ("Day","Week")时不考虑，为空。 |
| **分母** | `count(distinct user_id)`（全店新客数，`a03_e2e_customer_data_m`） |
| **分母筛选条件** | Step1：所选时间范围内 `SUM(net_pay_amt) > 0 AND is_member = 0`（`data_date = 所选时间范围`）；Step2：缩小至 `start_period` 往前推 12 个月 `lp_12m_net_pay_amt = 0`（`data_date = 所选时间范围 start_period`）；两步交集。
技术实现直接等价于单一筛选：data_date ∈ [__TimeMin, __TimeMax] AND net_pay_amt > 0 AND is_member = 0 AND lp_12m_net_pay_amt = 0 |
| **数据底表（分子）** | `a05_e2e_paid_media_summary_d` |
| **数据底表（分母）** | `a03_e2e_customer_data_m` |
| **聚合粒度** | `data_date = 所选时间范围`，`platform, shop_info_id` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%;-#,##0.0%;0.0%` |

---

### 8. Media Contribution to New Customer Acquisition% vs LY — 媒体新客贡献率（对比去年同期）

| 项目 | 内容 |
|---|---|
| **指标名称** | Media Contribution to New Customer Acquisition% vs LY / 媒体新客贡献率（对比去年同期） |
| **业务定义** | 媒体新客贡献率今年较去年同期的变化（差值） |
| **计算公式** | 和 Media Contribution to New Customer Acquisition% 逻辑一致，当期值 - 去年同期值（差值，展示时 ×10000 转 bp） |
| **数据底表** | 分子 `a05_e2e_paid_media_summary_d`；分母 `a03_e2e_customer_data_m` |
| **筛选条件** | 同 Media Contribution to New Customer Acquisition% |
| **数据类型** | delta_bp → 增减基点整数：→ +120bp / -80bp（基点，含正负号，值×10000 转 bp），乘以 10000 的操作可以放在 Cell Display 度量中实现 |
| **数据格式** | `+#,##0bp;-#,##0bp;0bp` |

---

### 9. Media Contribution to New Customer Acquisition% TAR ACH% — 媒体新客贡献率进度达成

| 项目 | 内容 |
|---|---|
| **指标名称** | Media Contribution to New Customer Acquisition% TAR ACH% / 媒体新客贡献率进度达成 |
| **业务定义** | 媒体新客贡献率实际值与目标值之比 |
| **Actual 计算公式** | 媒体新客数 / 全店新客数（同 Media Contribution to New Customer Acquisition%） |
| **Target 计算公式** | Month：`media_new_customer_contribution_rate`；Quarter：`SUM(media_new_customer_cnt) / SUM(new_customer_cnt)`（汇总所选财季范围内各财月）；Year：按 `data_year` 取 `MAX(year_media_new_customer_contribution_rate)` |
| **±Actual vs Target** | Actual - Target |
| **Actual 分子数据底表** | `a05_e2e_paid_media_summary_d`，字段 `media_member_cnt` |
| **Actual 分母数据底表** | `a03_e2e_customer_data_m`，按 `platform, shop_info_id` `count(distinct user_id)` |
| **Target 数据底表** | `a05_e2e_paid_media_fcst_data_m`，日期字段 `data_date` |
| **Actual 分子筛选条件** | `customer_type='ALL' AND page_type="1"`；Month、Quarter、Year 先按 platform、shop_id、data_month_name(包含data_year + data_month属性) 取 `MAX(media_member_cnt)`，再对所选财月 `SUM`。仅支持完整财月、财季、财年，Slicer_Time_Frame[TimeFrame_ID] in ("Day","Week")时不考虑，为空。 |
| **Actual 分母筛选条件** | Step1：所选时间范围内 `SUM(net_pay_amt) > 0 AND is_member = 0`（`data_date = 所选时间范围`）；Step2：缩小至 `start_period` 往前推 12 个月 `lp_12m_net_pay_amt = 0`（`data_date = 所选时间范围 start_period`）；两步交集。
技术实现直接等价于单一筛选：data_date ∈ [__TimeMin, __TimeMax] AND net_pay_amt > 0 AND is_member = 0 AND lp_12m_net_pay_amt = 0 |
| **Target 取数逻辑** | Month和Quarter使用platform、shop_id、data_month_name维度分组聚合，Year使用platform、shop_id、data_year维度分组聚合；Month 取所选财月 `SUM(media_new_customer_cnt) / SUM(new_customer_cnt)`；Quarter 汇总所选财季各财月 `SUM(media_new_customer_cnt) / SUM(new_customer_cnt)`；Year 按 `data_year` 取 `MAX(year_media_new_customer_contribution_rate)` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%;-#,##0.0%;0.0%` |

**TAR ACH% 计算规则矩阵（Media Contribution%，分母涉全店新客跨财年判定）**

| TimeFrame | 选择范围 | 分子（Actual） | 分母（Target） | 说明 |
|---|---|---|---|---|
| Month | 选择单个财月 | Media Contribution%（区间 actual） | `SUM(media_new_customer_cnt) / SUM(new_customer_cnt)` | 区间实际 / 区间目标 |
| Month | 选择多个财月（不跨财年） | Media Contribution%（区间 actual） | `SUM(media_new_customer_cnt) / SUM(new_customer_cnt)` | 区间实际 / 区间目标 |
| Month | 选择多个财月且跨财年 | Media Contribution%（区间 actual） | `SUM(media_new_customer_cnt) / SUM(new_customer_cnt)` | 区间实际 / 区间目标 |
| Quarter | 选择单个季度且不跨财年 | Media Contribution%（quarter actual） | `SUM(media_new_customer_cnt) / SUM(new_customer_cnt)` | 季度实际 / 季度目标 |
| Quarter | 选择多个季度且不跨财年 | Media Contribution%（区间 actual） | `SUM(media_new_customer_cnt) / SUM(new_customer_cnt)` | 区间实际 / 区间目标 |
| Quarter | 跨财年 | Media Contribution%（区间 actual） | `SUM(media_new_customer_cnt) / SUM(new_customer_cnt)` | 区间实际 / 区间目标 |
| Year | 选择单个财年 | Media Contribution%（year actual） | `MAX(year_media_new_customer_contribution_rate)` | 年度实际 / 年度目标 |
| Year | 选择多个财年 | Media Contribution%（year actual） | `MAX(year_media_new_customer_contribution_rate)` | 年度实际 / 年度目标 |

> 留空处理：当计算规则标注为「留空」时，该指标在对应场景下显示为空值或隐藏；Target 缺失时 Target 及 ±Actual vs Target 展示"-"。

---

### 10. Media Cost Per New Acquisition — 媒体新客获客成本

| 项目 | 内容 |
|---|---|
| **指标名称** | Cost Per New Acquisition / 媒体新客获客成本 |
| **业务定义** | 总新客花费 / 总媒体新客的数量 |
| **Actual 计算公式** | 新客花费 / 媒体新客数 |
| **分子** | `media_cost_amt`（新客花费 media_new_cost，`a05_e2e_paid_media_summary_d`） |
| **分子筛选条件** | `customer_type='ALL' AND page_type="1"`；Month、Quarter、Year 先按 platform、shop_id、data_month_name(包含data_year + data_month属性) 取 `MAX(media_cost_amt)`，再对所选财月及平台 `SUM`。仅支持完整财月、财季、财年，Slicer_Time_Frame[TimeFrame_ID] in ("Day","Week")时不考虑，为空。 |
| **分母** | `media_member_cnt`（媒体新客数 media_new_customer_no，`a05_e2e_paid_media_summary_d`） |
| **分母筛选条件** | `customer_type='ALL' AND page_type="1"`；Month、Quarter、Year 先按 platform、shop_id、data_month_name(包含data_year + data_month属性) 取 `MAX(media_member_cnt)`再对所选财月及平台 `SUM`。仅支持完整财月、财季、财年，Slicer_Time_Frame[TimeFrame_ID] in ("Day","Week")时不考虑，为空。 |
| **数据底表** | `a05_e2e_paid_media_summary_d` |
| **聚合粒度** | `data_date = 所选时间范围`，`platform, shop_info_id`（先按 platform、shop_id、data_month_name(包含data_year + data_month属性) 取 MAX 再 SUM 后相除） |
| **数据类型** | currency_decimal_1dp → 货币符号由币种切片器决定，千分位保留一位小数 |
| **数据格式** | `#,##0.0`（在 DAX 中用 `__CurrencySymbol & FORMAT(__Value, "#,##0.0")` 拼接币种符号） |
| **边界处理** | 汇总后的 `media_member_cnt` 为 0 时，Actual 展示"-" |

---

### 11. Media Cost Per New Acquisition vs LY — 媒体新客获客成本（对比去年同期）

| 项目 | 内容 |
|---|---|
| **指标名称** | Media Cost Per New Acquisition vs LY / 媒体新客获客成本（对比去年同期） |
| **业务定义** | 媒体新客获客成本今年较去年同期的变化率 |
| **计算公式** | 和 Media Cost Per New Acquisition 逻辑一致，当期值 / 去年同期值 - 1 |
| **数据底表** | `a05_e2e_paid_media_summary_d` |
| **筛选条件** | 同 Media Cost Per New Acquisition |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%;-#,##0.0%;0.0%` |

---

### 12. Media Cost Per New Acquisition TAR ACH% — 媒体新客获客成本进度达成

| 项目 | 内容 |
|---|---|
| **指标名称** | Media Cost Per New Acquisition TAR ACH% / 媒体新客获客成本进度达成 |
| **业务定义** | 媒体新客获客成本实际值与目标值之比 |
| **Actual 计算公式** | `media_cost_amt / media_member_cnt`（同 Media Cost Per New Acquisition，先按 platform、shop_id、data_month_name(包含data_year + data_month属性) 取 MAX 再 SUM 后相除） |
| **Target 计算公式** | Month：`SUM(media_new_customer_cost_amt) / SUM(media_new_customer_cnt)`；Quarter：`SUM(media_new_customer_cost_amt) / SUM(media_new_customer_cnt)`（汇总所选财季范围内各财月）；Year：按 `data_year` 取 `MAX(year_cost_per_new_acquisition)` |
| **±Actual vs Target** | Actual / Target - 1 |
| **Actual 数据底表** | `a05_e2e_paid_media_summary_d` |
| **Target 数据底表** | `a05_e2e_paid_media_fcst_data_m`，日期字段 `data_date` |
| **Actual 筛选条件** | `customer_type='ALL' AND page_type="1"`；Month、Quarter、Year 按 platform、shop_id、data_month_name(包含data_year + data_month属性) 取 `MAX(media_cost_amt)`、`MAX(media_member_cnt)`再对所选财月及平台 `SUM`。仅支持完整财月、财季、财年，Slicer_Time_Frame[TimeFrame_ID] in ("Day","Week")时不考虑，为空。 |
| **Target 取数逻辑** | Month和Quarter使用platform、shop_id、data_month_name维度分组聚合，Year使用platform、shop_id、data_year维度分组聚合；Month 取所选财月 `SUM(media_new_customer_cost_amt) / SUM(media_new_customer_cnt)`；Quarter 汇总所选财季各财月 `SUM(media_new_customer_cost_amt) / SUM(media_new_customer_cnt)`；Year 按 `data_year` 取 `MAX(year_cost_per_new_acquisition)` |
| **边界处理** | Target 缺失或为 0 时，Target 及 ±Actual vs Target 展示"-"；汇总后的 `media_member_cnt` 为 0 时，Actual 及 ±Actual vs Target 展示"-" |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%;-#,##0.0%;0.0%` |

**TAR ACH% 计算规则矩阵（Media Cost Per New Acquisition）**

| TimeFrame | 选择范围 | 分子（Actual） | 分母（Target） | 说明 |
|---|---|---|---|---|
| Month | 选择单个财月 | Media Cost Per New Acquisition（区间 actual） | `SUM(media_new_customer_cost_amt) / SUM(media_new_customer_cnt)` | 区间实际 / 区间目标 |
| Month | 选择多个财月（不跨财年） | Media Cost Per New Acquisition（区间 actual） | `SUM(media_new_customer_cost_amt) / SUM(media_new_customer_cnt)` | 区间实际 / 区间目标 |
| Month | 选择多个财月且跨财年 | Media Cost Per New Acquisition（区间 actual） | `SUM(media_new_customer_cost_amt) / SUM(media_new_customer_cnt)` | 区间实际 / 区间目标 |
| Quarter | 选择单个季度且不跨财年 | Media Cost Per New Acquisition（quarter actual） | `SUM(media_new_customer_cost_amt) / SUM(media_new_customer_cnt)` | 季度实际 / 季度目标 |
| Quarter | 选择多个季度且不跨财年 | Media Cost Per New Acquisition（区间 actual） | `SUM(media_new_customer_cost_amt) / SUM(media_new_customer_cnt)` | 区间实际 / 区间目标 |
| Quarter | 跨财年 | Media Cost Per New Acquisition（区间 actual） | `SUM(media_new_customer_cost_amt) / SUM(media_new_customer_cnt)` | 区间实际 / 区间目标 |
| Year | 选择单个财年 | Media Cost Per New Acquisition（year actual） | `MAX(year_cost_per_new_acquisition)` | 年度实际 / 年度目标 |
| Year | 选择多个财年 | Media Cost Per New Acquisition（year actual） | `MAX(year_cost_per_new_acquisition)` | 年度实际 / 年度目标 |

> 留空处理：当计算规则标注为「留空」时，该指标在对应场景下显示为空值或隐藏；Target 缺失或为 0 时 Target 及 ±Actual vs Target 展示"-"；汇总后的 `media_member_cnt` 为 0 时 Actual 及 ±Actual vs Target 展示"-"。

---

### 13. ± Acceleration Cost MOB% vs. Store SLS MOB% — 第二品类花费MOB%vs门店销售MOB%

| 项目 | 内容 |
|---|---|
| **指标名称** | ± Acceleration Cost MOB% vs. Store SLS MOB% / 第二品类花费MOB%vs门店销售MOB% |
| **业务定义** | 第二品类花费占比 vs 门店销售占比 |
| **计算公式** | Acceleration Cost MOB% − Store SLS MOB%（×10000 转为 bp） |
| **指标类型** | **派生指标**，无独立底表取数 |
| **数据底表** | `a05_e2e_paid_media_product_data` |
| **Acceleration Cost MOB% 计算公式** | 分子：`SUM(cost_amt)`（`mix_msg is NULL AND framework='Acceleration'`）；分母：`SUM(cost_amt)`（`mix_msg is NULL`，不限制 framework） |
| **Store SLS MOB% 计算公式** | 分子：`SUM(net_sales_amt)`（`framework='Acceleration'`）；分母：`SUM(net_sales_amt)`（全部 framework） |
| **筛选条件** | `customer_type='ALL' AND page_type="1"`；Cost MOB% 分子需 `mix_msg is NULL` ，分母不需要|
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%;-#,##0.0%;0.0%` |

---

### 14. ± Acceleration Cost MOB% vs. Store SLS MOB% vs LY — 第二品类花费MOB%vs门店销售MOB%（对比去年同期）

| 项目 | 内容 |
|---|---|
| **指标名称** | ± Acceleration Cost MOB% vs. Store SLS MOB% vs LY / 第二品类花费MOB%vs门店销售MOB%（对比去年同期） |
| **业务定义** | 第二品类花费MOB%vs门店销售MOB%今年较去年同期的变化（差值） |
| **计算公式** | 和 ± Acceleration Cost MOB% vs. Store SLS MOB% 逻辑一致，当期值 - 去年同期值 |
| **数据底表** | `a05_e2e_paid_media_product_data` |
| **筛选条件** | 同 ± Acceleration Cost MOB% vs. Store SLS MOB% |
| **数据类型** | delta_bp → 增减基点整数：→ +120bp / -80bp（基点，含正负号，值×10000 转 bp），乘以 10000 的操作可以放在 Cell Display 度量中实现 |
| **数据格式** | `+#,##0bp;-#,##0bp;0bp` |

---

### 15. ± Acceleration Cost MOB% vs Store SLS MOB% TAR ACH% — 第二品类花费MOB%vs门店销售MOB%进度达成

| 项目 | 内容 |
|---|---|
| **指标名称** | ± Acceleration Cost MOB% vs Store SLS MOB% TAR ACH% / 第二品类花费MOB%vs门店销售MOB%进度达成 |
| **业务定义** | 第二品类花费MOB%vs门店销售MOB%进度达成 |
| **Actual 计算公式** | Acceleration Cost MOB% - Store SLS MOB%（同 ± Acceleration Cost MOB% vs. Store SLS MOB%） |
| **Target 计算公式** | Month：`SUM(acceleration_cost_amt) / SUM(cost_amt) - SUM(acceleration_net_sales_amt) / SUM(net_sales_amt)；Quarter：`SUM(acceleration_cost_amt) / SUM(cost_amt) - SUM(acceleration_net_sales_amt) / SUM(net_sales_amt)`（汇总所选财季范围内各财月）；Year：按 `data_year` 取 `MAX(year_acceleration_cost_rate_vs_net_sales_rate)` |
| **±Actual vs Target** | Actual - Target |
| **Actual 数据底表** | `a05_e2e_paid_media_product_data` |
| **Target 数据底表** | `a05_e2e_paid_media_fcst_data_m`，日期字段 `data_date` |
| **Actual 筛选条件** | 见 ± Acceleration Cost MOB% vs. Store SLS MOB% 计算规则（Cost MOB% 分子分母需 `mix_msg is NULL`） |
| **Target 取数逻辑** |  Month和Quarter使用platform、shop_id、data_month_name维度分组聚合，Year使用platform、shop_id、data_year维度分组聚合；Month 取所选财月 `SUM(acceleration_cost_amt) / SUM(cost_amt) - SUM(acceleration_net_sales_amt) / SUM(net_sales_amt)`；Quarter 汇总所选财季各财月 `SUM(acceleration_cost_amt) / SUM(cost_amt) - SUM(acceleration_net_sales_amt) / SUM(net_sales_amt)`；Year 按 `data_year` 取 `MAX(year_acceleration_cost_rate_vs_net_sales_rate)` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%;-#,##0.0%;0.0%` |

**TAR ACH% 计算规则矩阵（± Acceleration Cost MOB% vs Store SLS MOB%）**

| TimeFrame | 选择范围 | 分子（Actual） | 分母（Target） | 说明 |
|---|---|---|---|---|
| Month | 选择单个财月 | Acceleration Cost MOB% - Store SLS MOB%（区间 actual） | `SUM(acceleration_cost_amt) / SUM(cost_amt) - SUM(acceleration_net_sales_amt) / SUM(net_sales_amt)` | 区间实际 / 区间目标 |
| Month | 选择多个财月（不跨财年） | Acceleration Cost MOB% - Store SLS MOB%（区间 actual） | `SUM(acceleration_cost_amt) / SUM(cost_amt) - SUM(acceleration_net_sales_amt) / SUM(net_sales_amt)` | 区间实际 / 区间目标 |
| Month | 选择多个财月且跨财年 | Acceleration Cost MOB% - Store SLS MOB%（区间 actual） | `SUM(acceleration_cost_amt) / SUM(cost_amt) - SUM(acceleration_net_sales_amt) / SUM(net_sales_amt)` | 区间实际 / 区间目标 |
| Quarter | 选择单个季度且不跨财年 | Acceleration Cost MOB% - Store SLS MOB%（quarter actual） | `SUM(acceleration_cost_amt) / SUM(cost_amt) - SUM(acceleration_net_sales_amt) / SUM(net_sales_amt)` | 季度实际 / 季度目标 |
| Quarter | 选择多个季度且不跨财年 | Acceleration Cost MOB% - Store SLS MOB%（区间 actual） | `SUM(acceleration_cost_amt) / SUM(cost_amt) - SUM(acceleration_net_sales_amt) / SUM(net_sales_amt)` | 区间实际 / 区间目标 |
| Quarter | 跨财年 | Acceleration Cost MOB% - Store SLS MOB%（区间 actual） | `SUM(acceleration_cost_amt) / SUM(cost_amt) - SUM(acceleration_net_sales_amt) / SUM(net_sales_amt)` | 区间实际 / 区间目标 |
| Year | 选择单个财年 | Acceleration Cost MOB% - Store SLS MOB%（year actual） | `MAX(year_acceleration_cost_rate_vs_net_sales_rate)` | 年度实际 / 年度目标 |
| Year | 选择多个财年 | Acceleration Cost MOB% - Store SLS MOB%（year actual） | `MAX(year_acceleration_cost_rate_vs_net_sales_rate)` | 年度实际 / 年度目标 |

> 留空处理：当计算规则标注为「留空」时，该指标在对应场景下显示为空值或隐藏；Target 缺失时 Target 及 ±Actual vs Target 展示"-"。

---

## 子模块二：Performance Indicators

### 16. New Customer No — 新客数量

| 项目 | 内容 |
|---|---|
| **指标名称** | New Customer No / 新客数量 |
| **业务定义** | 店铺新客数 |
| **计算公式** | `COUNT(DISTINCT user_id)`（全店新客） |
| **统计字段** | `user_id` |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | Step1：在所选时间范围内筛选 `SUM(net_pay_amt) > 0` 的 `user_id`（`data_date = 所选时间范围`，`is_member = 0`，`SUM(net_pay_amt) > 0`）；Step2：缩小顾客范围至 `lp_12m_net_pay_amt = 0`（`data_date = 所选时间范围 start_period`）；相当于取 Step1 和 Step2 的交集，最后 `COUNT(DISTINCT user_id)`；技术实现直接等价于单一筛选：data_date ∈ [__TimeMin, __TimeMax] AND net_pay_amt > 0 AND is_member = 0 AND lp_12m_net_pay_amt = 0 |
| **聚合粒度** | `data_date = 所选时间范围`，按 `platform, shop_info_id` 分组；Month 按财月、`platform` 对 `user_id` 去重计数；Quarter、Year 及 `Platform=ALL` 去重范围复用 Customer Dashboard 同 Timeframe、同 Period 逻辑 |
| **数据类型** | integer → 整数，千分位整数 |
| **数据格式** | `#,##0` |

---

### 17. New Customer No vs LY — 新客数量（对比去年同期）

| 项目 | 内容 |
|---|---|
| **指标名称** | New Customer No vs LY / 新客数量（对比去年同期） |
| **业务定义** | 店铺新客数今年较去年同期的变化率 |
| **计算公式** | 当期值 / 去年同期值 - 1 |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | 同 New Customer No |
| **聚合粒度** | `data_date = 所选时间范围`，按 `platform, shop_info_id` 分组 |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%;-#,##0.0%;0.0%` |

---

### 18. New Customer No TAR ACH% — 新客数量进度达成

| 项目 | 内容 |
|---|---|
| **指标名称** | New Customer No TAR ACH% / 新客数量进度达成 |
| **业务定义** | 新客数量实际值与目标值之比 |
| **Actual 计算公式** | `COUNT(DISTINCT user_id)`（全店新客数，同 New Customer No） |
| **Target 计算公式** | Month：`SUM(new_customer_cnt)`；Quarter：`SUM(new_customer_cnt)`（汇总所选财季范围内各财月）；Year：按 `data_year` 取 `MAX(year_new_customer_cnt)` |
| **±Actual vs Target** | Actual / Target |
| **Actual 数据底表** | `a03_e2e_customer_data_m` |
| **Target 数据底表** | `a05_e2e_paid_media_fcst_data_m`，日期字段 `data_date` |
| **Actual 筛选条件** | 见 New Customer No 计算规则（Step1 ∩ Step2） |
| **Target 取数逻辑** | Month和Quarter使用platform、shop_id、data_month_name维度分组聚合，Year使用platform、shop_id、data_year维度分组聚合；Month 取所选财月 `SUM(new_customer_cnt)`；Quarter 汇总所选财季各财月 `SUM(new_customer_cnt)`；Year 按 `data_year` 取 `MAX(year_new_customer_cnt)` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%;-#,##0.0%;0.0%` |

**TAR ACH% 计算规则矩阵（New Customer No，分母涉全店新客跨财年判定）**

| TimeFrame | 选择范围 | 分子（Actual） | 分母（Target） | 说明 |
|---|---|---|---|---|
| Month | 选择单个财月 | New Customer No（区间 actual） | `SUM(new_customer_cnt)` | 区间实际 / 区间目标 |
| Month | 选择多个财月（不跨财年） | New Customer No（区间 actual） | `SUM(new_customer_cnt)` | 区间实际 / 区间目标 |
| Month | 选择多个财月且跨财年 | New Customer No（区间 actual） | `SUM(new_customer_cnt)` | 区间实际 / 区间目标 |
| Quarter | 选择单个季度且不跨财年 | New Customer No（quarter actual） | `SUM(new_customer_cnt)` | 季度实际 / 季度目标 |
| Quarter | 选择多个季度且不跨财年 | New Customer No（区间 actual） | `SUM(new_customer_cnt)` | 区间实际 / 区间目标 |
| Quarter | 跨财年 | New Customer No（区间 actual） | `SUM(new_customer_cnt)` | 区间实际 / 区间目标 |
| Year | 选择单个财年 | New Customer No（year actual） | `MAX(year_new_customer_cnt)` | 年度实际 / 年度目标 |
| Year | 选择多个财年 | New Customer No（year actual） | `MAX(year_new_customer_cnt)` | 年度实际 / 年度目标 |

> 留空处理：当计算规则标注为「留空」时，该指标在对应场景下显示为空值或隐藏；Target 缺失时 Target 及 ±Actual vs Target 展示"-"。

---

### 19. Acceleration SLS — 第二品类退后销售额

| 项目 | 内容 |
|---|---|
| **指标名称** | Acceleration SLS / 第二品类退后销售额 |
| **业务定义** | 第二品类退后销售额 |
| **计算公式** | `SUM(net_sales_amt)`（framework='Acceleration'） |
| **统计字段** | `net_sales_amt` |
| **数据底表** | `a05_e2e_paid_media_product_data` |
| **筛选条件** | `framework='Acceleration'`；`SUM(net_sales_amt)` |
| **数据类型** | currency → 货币符号由币种切片器决定，千分位整数 |
| **数据格式** | `#,##0`（在 DAX 中用 `__CurrencySymbol & FORMAT(__Value, "#,##0")` 拼接币种符号） |

---

### 20. Acceleration SLS vs LY — 第二品类退后销售额（对比去年同期）

| 项目 | 内容 |
|---|---|
| **指标名称** | Acceleration SLS vs LY / 第二品类退后销售额（对比去年同期） |
| **业务定义** | 第二品类退后销售额今年较去年同期的变化率 |
| **计算公式** | 当期值 / 去年同期值 - 1 |
| **数据底表** | `a05_e2e_paid_media_product_data` |
| **筛选条件** | `framework='Acceleration'` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%;-#,##0.0%;0.0%` |

---

### 21. Acceleration SLS TAR ACH% — 第二品类退后销售额进度达成

| 项目 | 内容 |
|---|---|
| **指标名称** | Acceleration SLS TAR ACH% / 第二品类退后销售额进度达成 |
| **业务定义** | 第二品类退后销售额实际值与目标值之比 |
| **Actual 计算公式** | `SUM(net_sales_amt)`（framework='Acceleration'） |
| **Target 计算公式** | Month/Quarter：`acceleration_net_sales_amt`；Year：按 `data_year` 取 `MAX(year_acceleration_net_sales_amt)` |
| **±Actual vs Target** | Actual / Target |
| **Actual 数据底表** | `a05_e2e_paid_media_product_data` |
| **Target 数据底表** | `a05_e2e_paid_media_fcst_data_m`，日期字段 `data_date` |
| **Actual 筛选条件** | `framework='Acceleration'`；`SUM(net_sales_amt)` |
| **Target 取数逻辑** | Month和Quarter使用platform、shop_id、data_month_name维度分组聚合，Year使用platform、shop_id、data_year维度分组聚合；Month 取所选财月 `SUM(acceleration_net_sales_amt)`；Quarter 汇总所选财季各财月 `SUM(acceleration_net_sales_amt)`；Year 按 `data_year` 取 `MAX(year_acceleration_net_sales_amt)` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%;-#,##0.0%;0.0%` |

**TAR ACH% 计算规则矩阵（Acceleration SLS）**

| TimeFrame | 选择范围 | 分子（Actual） | 分母（Target） | 说明 |
|---|---|---|---|---|
| Month | 选择单个财月 | `SUM(net_sales_amt[framework='Acceleration'])`（month actual） | `acceleration_net_sales_amt` | 单月实际 / 月度目标 |
| Month | 选择多个财月（不跨财年） | `SUM(net_sales_amt[framework='Acceleration'])`（区间 actual） | `SUM(acceleration_net_sales_amt)` | 区间实际 / 区间目标 |
| Month | 选择多个财月且跨财年 | `SUM(net_sales_amt[framework='Acceleration'])`（区间 actual） | `SUM(acceleration_net_sales_amt)` | 区间实际 / 区间目标 |
| Quarter | 选择单个季度且不跨财年 | `SUM(net_sales_amt[framework='Acceleration'])`（quarter actual） | `SUM(acceleration_net_sales_amt)` | 季度实际 / 季度目标 |
| Quarter | 选择多个季度且不跨财年 | `SUM(net_sales_amt[framework='Acceleration'])`（区间 actual） | `SUM(acceleration_net_sales_amt)` | 区间实际 / 区间目标 |
| Quarter | 跨财年 | `SUM(net_sales_amt[framework='Acceleration'])`（区间 actual） | `SUM(acceleration_net_sales_amt)` | 区间实际 / 区间目标 |
| Year | 选择单个财年 | `SUM(net_sales_amt[framework='Acceleration'])`（year actual） | `MAX(year_acceleration_net_sales_amt)` | 年度实际 / 年度目标 |
| Year | 选择多个财年 |  `SUM(net_sales_amt[framework='Acceleration'])`（year actual） | `MAX(year_acceleration_net_sales_amt)` | 年度实际 / 年度目标 |

> 留空处理：当计算规则标注为「留空」时，该指标在对应场景下显示为空值或隐藏；Target 缺失时 Target 及 ±Actual vs Target 展示"-"。

---

### 22. Acceleration SLS MOB% — 第二品类退后销售额MOB%

| 项目 | 内容 |
|---|---|
| **指标名称** | Acceleration SLS MOB% / 第二品类退后销售额MOB% |
| **业务定义** | 第二品类退后销售额占比 |
| **计算公式** | Acceleration SLS / TTL SLS |
| **分子** | `SUM(net_sales_amt)`（framework='Acceleration'） |
| **分母** | `SUM(net_sales_amt)`（全部 framework） |
| **数据底表** | `a05_e2e_paid_media_product_data` |
| **筛选条件** | 分子：`framework='Acceleration'`；`SUM(net_sales_amt)`；分母：全部 framework；`SUM(net_sales_amt)` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%;-#,##0.0%;0.0%` |

---

### 23. Acceleration SLS MOB% vs LY — 第二品类退后销售额MOB%（对比去年同期）

| 项目 | 内容 |
|---|---|
| **指标名称** | Acceleration SLS MOB% vs LY / 第二品类退后销售额MOB%（对比去年同期） |
| **业务定义** | 第二品类退后销售额MOB%今年较去年同期的变化（差值） |
| **计算公式** | 当期占比 - 去年同期占比（差值，展示时 ×10000 转 bp） |
| **数据底表** | `a05_e2e_paid_media_product_data` |
| **筛选条件** | 分子：`framework='Acceleration'`；`SUM(net_sales_amt)`；分母：全部 framework；`SUM(net_sales_amt)` |
| **数据类型** | delta_bp → 增减基点整数：→ +120bp / -80bp（基点，含正负号，值×10000 转 bp），乘以 10000 的操作可以放在 Cell Display 度量中实现 |
| **数据格式** | `+#,##0bp;-#,##0bp;0bp` |

---

### 24. Acceleration SLS MOB% TAR ACH% — 第二品类退后销售额MOB%进度达成

| 项目 | 内容 |
|---|---|
| **指标名称** | Acceleration SLS MOB% TAR ACH% / 第二品类退后销售额MOB%进度达成 |
| **业务定义** | 第二品类退后销售额MOB%实际值与目标值之比 |
| **Actual 计算公式** | `SUM(net_sales_amt[framework='Acceleration']) / SUM(net_sales_amt[全部 framework])`（同 Acceleration SLS MOB%） |
| **Target 计算公式** | Month：`acceleration_net_sales_rate`；Quarter：`SUM(acceleration_net_sales_amt) / SUM(net_sales_amt)`（汇总所选财季范围内各财月）；Year：按 `data_year` 取 `MAX(year_acceleration_net_sales_rate)` |
| **±Actual vs Target** | Actual - Target |
| **Actual 数据底表** | `a05_e2e_paid_media_product_data` |
| **Target 数据底表** | `a05_e2e_paid_media_fcst_data_m`，日期字段 `data_date` |
| **Actual 筛选条件** | 分子：`framework='Acceleration'`；`SUM(net_sales_amt)`；分母：全部 framework；`SUM(net_sales_amt)` |
| **Target 取数逻辑** | Month和Quarter使用platform、shop_id、data_month_name维度分组聚合，Year使用platform、shop_id、data_year维度分组聚合；Month 取所选财月 `SUM(acceleration_net_sales_amt) / SUM(net_sales_amt)`；Quarter 汇总所选财季各财月 `SUM(acceleration_net_sales_amt) / SUM(net_sales_amt)`；Year 按 `data_year` 取 `MAX(year_acceleration_net_sales_rate)` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%;-#,##0.0%;0.0%` |

**TAR ACH% 计算规则矩阵（Acceleration SLS MOB%）**

| TimeFrame | 选择范围 | 分子（Actual） | 分母（Target） | 说明 |
|---|---|---|---|---|
| Month | 选择单个财月 | Acceleration SLS MOB%（区间 actual） | `SUM(acceleration_net_sales_amt) / SUM(net_sales_amt)` | 区间实际 / 区间目标 |
| Month | 选择多个财月（不跨财年） | Acceleration SLS MOB%（区间 actual） | `SUM(acceleration_net_sales_amt) / SUM(net_sales_amt)` | 区间实际 / 区间目标 |
| Month | 选择多个财月且跨财年 | Acceleration SLS MOB%（区间 actual） | `SUM(acceleration_net_sales_amt) / SUM(net_sales_amt)` | 区间实际 / 区间目标 |
| Quarter | 选择单个季度且不跨财年 | Acceleration SLS MOB%（quarter actual） | `SUM(acceleration_net_sales_amt) / SUM(net_sales_amt)` | 季度实际 / 季度目标 |
| Quarter | 选择多个季度且不跨财年 | Acceleration SLS MOB%（区间 actual） | `SUM(acceleration_net_sales_amt) / SUM(net_sales_amt)` | 区间实际 / 区间目标 |
| Quarter | 跨财年 | Acceleration SLS MOB%（区间 actual） | `SUM(acceleration_net_sales_amt) / SUM(net_sales_amt)` | 区间实际 / 区间目标 |
| Year | 选择单个财年 | Acceleration SLS MOB%（year actual） | `MAX(year_acceleration_net_sales_rate)` | 年度实际 / 年度目标 |
| Year | 选择多个财年 | Acceleration SLS MOB%（year actual） | `MAX(year_acceleration_net_sales_rate)` | 年度实际 / 年度目标 |

> 留空处理：当计算规则标注为「留空」时，该指标在对应场景下显示为空值或隐藏；Target 缺失时 Target 及 ±Actual vs Target 展示"-"。

---

## 子模块三：New Acquisition KPI Trend

### 25. New Customer No. — 新客数量（趋势）

| 项目 | 内容 |
|---|---|
| **指标名称** | New Customer No / 新客数量 |
| **业务定义** | 新客数量趋势 |
| **计算公式** | `COUNT(DISTINCT user_id)`（全店新客，趋势图） |
| **统计字段** | `user_id` |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | Step1：在趋势图所选 Period 内筛选 `SUM(net_pay_amt) > 0` 的 `user_id`（`data_date = 趋势图所选 Period范围`，`is_member = 0`）；Step2：缩小顾客范围至所选 Period 的 `start_period` 往前推 12 个月 `lp_12m_net_pay_amt = 0`（`data_date = 趋势图所选 Period范围 的 start_period`）；两步交集，技术实现直接等价于单一筛选：data_date ∈ [__TimeMin, __TimeMax] AND net_pay_amt > 0 AND is_member = 0 AND lp_12m_net_pay_amt = 0 |
| **聚合粒度** | 按趋势图所选 Period 及 `platform`、`shop_info_id` 对 `user_id` 去重计数； |
| **数据类型** | integer_M_K_Int_0db → 值 < 1,000        → 千分位整数：999;1,000 ≤ 值 < 1M   → K 单位（1位小数）：1.5K;值 ≥ 1,000,000    → M 单位（1位小数）：1.5M; |
| **数据格式** | dax```IF( __Value < 1000,FORMAT(__Value, "#,##0"),IF(__Value < 1000000,FORMAT(__Value / 1000, "#,##0.0") & "K",FORMAT(__Value / 1000000, "#,##0.0") & "M")), // 999\1.5K¥1.5M; ```|

---

### 26. New Customer% — 新客占比（趋势）

| 项目 | 内容 |
|---|---|
| **指标名称** | New Customer% / 新客占比 |
| **业务定义** | 新客占比趋势 |
| **计算公式** | New Customer No / TTL Buyers |
| **分子** | `COUNT(DISTINCT user_id)`（全店新客数，按 `platform, shop_info_id` 去重）：两步交集，技术实现直接等价于单一筛选：data_date ∈ [__TimeMin, __TimeMax] AND net_pay_amt > 0 AND is_member = 0 AND lp_12m_net_pay_amt = 0 |
| **分母** | `COUNT(DISTINCT user_id)`（全部买家，`data_date = 所选时间范围`，`SUM(net_pay_amt) > 0 AND is_member = 0`） |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | 分子：见全店新客判定（Step1 ∩ Step2）；分母：`data_date = 所选时间范围` `COUNT(DISTINCT user_id) WHERE SUM(net_pay_amt) > 0 AND is_member = 0`。按 Customer Dashboard 同 Timeframe、同 Period 及 Platform 范围分别对 `user_id` 去重后重算 |
| **数据类型** | percent_0dp → 百分比整数，不含正号 |
| **数据格式** | `#,##0%;-#,##0%;0%` |

---

### 27. Media Contribution to New Customer Acquisition% — 媒体新客贡献率（趋势）

| 项目 | 内容 |
|---|---|
| **指标名称** | Media Contribution to New Customer Acquisition% / 媒体新客贡献率 |
| **业务定义** | 新客贡献率趋势 |
| **计算公式** | 媒体新客数 / 全店新客数（趋势图） |
| **分子** | `media_member_cnt`（媒体新客数，`a05_e2e_paid_media_summary_d`） |
| **分子筛选条件** | `customer_type='ALL' AND page_type="1"`；Month、Quarter、Year 先按 platform、shop_id、data_month_name(包含data_year + data_month属性) 取 `MAX(media_member_cnt)`，再对所选财月 `SUM`。仅支持完整财月、财季、财年，Slicer_Time_Frame[TimeFrame_ID] in ("Day","Week")时不考虑，为空。 |
| **分母** | `COUNT(DISTINCT user_id)`（全店新客数，`a03_e2e_customer_data_m`，按 `platform, shop_info_id` 去重） |
| **分母筛选条件** | 两步交集。
技术实现直接等价于单一筛选：data_date ∈ [__TimeMin, __TimeMax] AND net_pay_amt > 0 AND is_member = 0 AND lp_12m_net_pay_amt = 0 |
| **数据底表（分子）** | `a05_e2e_paid_media_summary_d` |
| **数据底表（分母）** | `a03_e2e_customer_data_m` |
| **聚合粒度** | `data_date = 所选时间范围`，`platform, shop_info_id` |
| **数据类型** | percent_0dp → 百分比整数，不含正号 |
| **数据格式** | `#,##0%;-#,##0%;0%` |

---

## 子模块四：Category Growth KPI Trend

### 28. Acceleration SLS — 第二品类退后销售额（趋势）

| 项目 | 内容 |
|---|---|
| **指标名称** | Acceleration SLS / 第二品类退后销售额 |
| **业务定义** | 第二品类退后销售额趋势 |
| **计算公式** | `SUM(net_sales_amt)`（framework='Acceleration'，趋势图） |
| **统计字段** | `net_sales_amt` |
| **数据底表** | `a05_e2e_paid_media_product_data` |
| **筛选条件** | `framework='Acceleration'`；`SUM(net_sales_amt)` |
| **数据类型** | currency_M_K_Int_0db → 货币符号由币种切片器决定，千分位整数，需要在 Cell Display 度量中拼接币种符号，需要判断是否带 K、M、或者就是千分位整数，如果值小于 1000，就直接表示为千分位整数，如果值大于等于 1000，就表示为带 K、M 的格式，1K 为一千，1M 为一百万，都采用千分位的格式 |
| **数据格式** | dax```IF( __Value < 1000,__CurrencySymbol & FORMAT(__Value, "#,##0"),IF(__Value < 1000000,__CurrencySymbol & FORMAT(__Value / 1000, "#,##0.0") & "K",__CurrencySymbol & FORMAT(__Value / 1000000, "#,##0.0") & "M")), // ¥999\¥1.5K\¥1.5M; ```|

---

### 29. Acceleration SLS MOB% — 第二品类退后销售额MOB%（趋势）

| 项目 | 内容 |
|---|---|
| **指标名称** | Acceleration SLS MOB% / 第二品类退后销售额MOB% |
| **业务定义** | 第二品类退后销售额 MOB% 趋势 |
| **计算公式** | Acceleration SLS / TTL SLS（趋势图） |
| **统计字段** | `SUM(net_sales_amt[framework='Acceleration']) / SUM(net_sales_amt[全部 framework])` |
| **数据底表** | `a05_e2e_paid_media_product_data` |
| **筛选条件** | 分子：`framework='Acceleration'`；`SUM(net_sales_amt)`；分母：全部 framework；`SUM(net_sales_amt)` |
| **数据类型** | percent_0dp → 百分比整数，不含正号 |
| **数据格式** | `#,##0%;-#,##0%;0%` |

---

### 30. Acceleration Cost MOB% — 第二品类花费MOB%（趋势）

| 项目 | 内容 |
|---|---|
| **指标名称** | Acceleration Cost MOB% / 第二品类花费MOB% |
| **业务定义** | 第二品类花费 MOB% 趋势 |
| **计算公式** | Acceleration Cost / TTL Cost（趋势图） |
| **统计字段** | `SUM(cost_amt[framework='Acceleration']) / SUM(cost_amt[全部 framework])` |
| **数据底表** | `a05_e2e_paid_media_product_data` |
| **筛选条件** | 分子：先筛 `mix_msg is NULL AND framework='Acceleration'`，再 `SUM(cost_amt)`；分母：先筛 `mix_msg is NULL`（不限制 framework），再 `SUM(cost_amt)` |
| **数据类型** | percent_0dp → 百分比整数，不含正号 |
| **数据格式** | `#,##0%;-#,##0%;0%` |

---

## 子模块五：KPI by Platform

> **分组维度**: 按 `platform` 分组，Slicer_Platform_Selection 1:* ──→ a05_e2e_paid_media_summary_d[platform]

### 31. Media Cost Rate — 费比（分平台）

| 项目 | 内容 |
|---|---|
| **指标名称** | Media Cost Rate / 费比 |
| **业务定义** | 各平台费比 |
| **计算公式** | Cost / SLS × 1.13 / 1.06 |
| **统计字段** | `cost_amt / net_sales_amt` |
| **数据底表** | `a05_e2e_paid_media_summary_d` |
| **筛选条件** | `customer_type='ALL' AND page_type="1"`，按 `platform` 分组 |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%;-#,##0.0%;0.0%` |
| **相关字段格式** | 去年同期值（Media Cost Rate vs LP）：percent_1dp、同比（YOY%）：percent_1dp |

---

### 32. Media Cost — 媒体花费（分平台）

| 项目 | 内容 |
|---|---|
| **指标名称** | Media Cost / 媒体花费 |
| **业务定义** | 各平台实际媒体花费 |
| **计算公式** | 同 Cost（实际媒体花费），按 `platform` 分组 |
| **统计字段** | `cost_amt` |
| **数据底表** | `a05_e2e_paid_media_summary_d` |
| **筛选条件** | `customer_type='ALL' AND page_type="1"`，按 `platform` 分组 |
| **数据类型** | currency → 货币符号由币种切片器决定，千分位整数 |
| **数据格式** | `#,##0`（在 DAX 中用 `__CurrencySymbol & FORMAT(__Value, "#,##0")` 拼接币种符号） |
| **相关字段格式** | 去年同期值（Media Cost vs LP）：currency、（YOY%）：percent_1dp |

---

### 33. ± Acceleration Cost MOB% vs. Store SLS MOB% — 第二品类花费MOB%vs门店销售MOB%（分平台）

| 项目 | 内容 |
|---|---|
| **指标名称** | ± Acceleration Cost MOB% vs. Store SLS MOB% / 第二品类花费MOB%vs门店销售MOB% |
| **业务定义** | 各平台第二品类花费 MOB% vs 门店销售 MOB% |
| **计算公式** | Acceleration Cost MOB% − Store SLS MOB%（by platform，bp） |
| **数据底表** | `a05_e2e_paid_media_product_data` |
| **Acceleration Cost MOB% 计算公式** | 分子：`SUM(cost_amt)`（`mix_msg is NULL AND framework='Acceleration'`）；分母：`SUM(cost_amt)`（`mix_msg is NULL`，不限制 framework） |
| **Store SLS MOB% 计算公式** | 分子：`SUM(net_sales_amt)`（`framework='Acceleration'`）；分母：`SUM(net_sales_amt)`（全部 framework） |
| **筛选条件** | `customer_type='ALL' AND page_type="1"`；Cost MOB% 分子需 `mix_msg is NULL` ，分母不需要|
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%;-#,##0.0%;0.0%` |
| **相关字段格式** | 去年同期值（± Acceleration Cost MOB% vs. Store SLS MOB% vs LP）：percent_1dp、（YOY%）：percent_1dp |

---

### 34. Media Contribution to New Customer Acquisition% — 媒体新客贡献率（分平台）

| 项目 | 内容 |
|---|---|
| **指标名称** | Media Contribution to New Customer Acquisition% / 媒体新客贡献率 |
| **业务定义** | 各平台媒体新客贡献率 |
| **计算公式** | 媒体新客数 / 全店新客数（by platform） |
| **分子** | `media_member_cnt`（媒体新客数，`a05_e2e_paid_media_summary_d`） |
| **分子筛选条件** | `customer_type='ALL' AND page_type="1"`；Month、Quarter、Year 先按 platform、shop_id、data_month_name(包含data_year + data_month属性) 取 `MAX(media_member_cnt)`，再对所选财月 `SUM`。仅支持完整财月、财季、财年，Slicer_Time_Frame[TimeFrame_ID] in ("Day","Week")时不考虑，为空。 |
| **分母** | `COUNT(DISTINCT user_id)`（全店新客数，`a03_e2e_customer_data_m`，按 `platform, shop_info_id` 去重） |
| **分母筛选条件** | Step1：所选时间范围内 `SUM(net_pay_amt) > 0 AND is_member = 0`（`data_date = 所选时间范围`）；Step2：缩小至 `start_period` 往前推 12 个月 `lp_12m_net_pay_amt = 0`（`data_date = 所选时间范围 start_period`）；两步交集。
技术实现直接等价于单一筛选：data_date ∈ [__TimeMin, __TimeMax] AND net_pay_amt > 0 AND is_member = 0 AND lp_12m_net_pay_amt = 0 |
| **数据底表（分子）** | `a05_e2e_paid_media_summary_d` |
| **数据底表（分母）** | `a03_e2e_customer_data_m` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%;-#,##0.0%;0.0%` |
| **相关字段格式** | 去年同期值（Media Contribution to New Customer Acquisition% vs LP）：percent_1dp、（YOY%）：percent_1dp |

---

### 35. Media Cost Per New Acquisition — 媒体新客获客成本（分平台）

| 项目 | 内容 |
|---|---|
| **指标名称** | Media Cost Per New Acquisition / 媒体新客获客成本 |
| **业务定义** | 各平台媒体新客获客成本 |
| **计算公式** | 新客花费 / 媒体新客数（by platform） |
| **分子** | `media_cost_amt`（新客花费 media_new_cost，`a05_e2e_paid_media_summary_d`） |
| **分子筛选条件** | `customer_type='ALL' AND page_type="1"`；Month、Quarter、Year 先按 platform、shop_id、data_month_name(包含data_year + data_month属性) 取 `MAX(media_cost_amt)`，再对所选财月及平台 `SUM`。仅支持完整财月、财季、财年，Slicer_Time_Frame[TimeFrame_ID] in ("Day","Week")时不考虑，为空。 |
| **分母** | `media_member_cnt`（媒体新客数 media_new_customer_no，`a05_e2e_paid_media_summary_d`） |
| **分母筛选条件** | `customer_type='ALL' AND page_type="1"`；Month、Quarter、Year 先按 platform、shop_id、data_month_name(包含data_year + data_month属性) 取 `MAX(media_member_cnt)`再对所选财月及平台 `SUM`。仅支持完整财月、财季、财年，Slicer_Time_Frame[TimeFrame_ID] in ("Day","Week")时不考虑，为空。 |
| **数据底表** | `a05_e2e_paid_media_summary_d` |
| **聚合粒度** | `data_date = 所选时间范围`，`platform, shop_info_id`（先按 platform、shop_id、data_month_name(包含data_year + data_month属性) 取 MAX 再 SUM 后相除） |
| **数据类型** | currency_decimal_1dp → 货币符号由币种切片器决定，千分位保留一位小数 |
| **数据格式** | `#,##0.0`（在 DAX 中用 `__CurrencySymbol & FORMAT(__Value, "#,##0.0")` 拼接币种符号） |
| **相关字段格式** | 去年同期值（Media Cost Per New Acquisition vs LP）：currency_decimal_1dp、（YOY%）：percent_1dp |

---

## 通用规则汇总

| 规则项 | 说明 |
|---|---|
| **数据底表（实际值）** | 汇总指标用 `a05_e2e_paid_media_summary_d`；第二品类（Acceleration）系列用 `a05_e2e_paid_media_product_data`；全店新客用 `a03_e2e_customer_data_m` |
| **数据底表（目标值）** | `a05_e2e_paid_media_fcst_data_m`（预测专用表，按财月/财季/财年粒度取数），日期字段 `data_date` |
| **page_type** | 本板块统一 `page_type="1"` |
| **customer_type** | 媒体新客类指标（`media_member_cnt`/`media_cost_amt`）统一 `customer_type='ALL' AND page_type=1`；其它指标按定义区分 `ALL`/`NEW` |
| **日期切片器** | `Slicer_Time_Frame`：`TimeFrame_ID`（Month/Quarter/Year），`TimeFrame_Value`（展示值），所选时间区间 `data_date ∈ [TimeFrame_Min, TimeFrame_Max]` |
| **时间粒度处理** | Month 按所选财月完整日期范围汇总；Quarter 按所选财季完整日期范围汇总；Year 按所选财年完整日期范围汇总 |
| **媒体新客字段聚合** | `media_member_cnt`/`media_cost_amt` 先按 platform、shop_id、data_month_name(包含data_year + data_month属性) 取 `MAX`，再对所选财月及平台 `SUM`；仅支持完整财月、财季、财年，Slicer_Time_Frame[TimeFrame_ID] in ("Day","Week")时不考虑，为空。 |
| **全店新客判定（Net）** | `a03_e2e_customer_data_m`：Step1 所选时间范围 `SUM(net_pay_amt) > 0 AND is_member = 0` ∩ Step2 `start_period` `lp_12m_net_pay_amt = 0`；Month 按财月、`platform` 去重；Quarter、Year 及 `Platform=ALL` 复用 Customer Dashboard 同 Timeframe、同 Period 去重逻辑 |
| **第二品类（Acceleration）筛选** | Acceleration 系列实际值从 `a05_e2e_paid_media_product_data` 取数；Cost 类指标分子需 `mix_msg is NULL AND framework='Acceleration'`，分母需 `mix_msg is NULL`（不限制 framework）；SLS 类指标分子需 `framework='Acceleration'`，分母不限制 framework |
| **分平台维度** | 子模块五 KPI by Platform 按 `platform` 字段分组 |
| **派生指标** | Cost vs SLS ACH%、± Acceleration Cost MOB% vs Store SLS MOB% 为派生差值，无独立底表取数 |
| **TAR ACH% 结构** | TAR ACH% 类指标采用 Actual / Target / ±Actual vs Target 三段式；Target 取数按 Month/Quarter/Year 粒度来自 `a05_e2e_paid_media_fcst_data_m`；±Actual vs Target 默认 `Actual - Target`（Cost Per New Acquisition 为 `Actual / Target - 1`） |
| **Target 缺失处理** | Target 缺失时，Target 及 ±Actual vs Target 展示"-"；Cost Per New Acquisition 额外处理 Target=0 及 `media_member_cnt`=0 |
| **跨财年判定** | 当所选时间范围跨越两个及以上财年时，视为跨财年场景，TAR ACH% 类指标留空 |
| **必须遵守** | 口径文档中定义的所有指标，必须遵守其数据类型和数据格式，如果和解决方案中存在争议的，一切以口径文档为准，必须按照口径文档中的格式进行调整 |
| **DAX 语法规范** | 文本常量必须使用双引号 `" "`，禁止使用单引号；单引号 `' '` 仅用于表名，列名使用方括号 `[ ]`，例如：`[framework] = "Acceleration"`、`[customer_type] = "ALL"` |
