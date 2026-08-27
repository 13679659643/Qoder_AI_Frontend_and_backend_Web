 # Overview 指标口径提示词

> **Dashboard**: DCom Performance Media Operation Dashboard  
> **Tab**: Overview  
> **数据底表**: `a05_e2e_paid_media_summary_d`  
> **额外通用筛选条件**: `customer_type="ALL" AND page_type="1"`
 **额外说明**: 本身业务逻辑上的筛选条件不变，例如：切片器上下文;这点会在dax中体现出来。

---

## 板块一：Growth Overview-All/TM/JD

### 1. Cost — 花费

| 项目 | 内容 |
|---|---|
| **指标名称** | Cost / 花费 |
| **业务定义** | 实际总媒体花费（默认含红包/返佣返货金） |
| **统计字段** | `cost_amt`（字段值本身就含红包/返佣返货金） |
| **数据底表** | `a05_e2e_paid_media_summary_d` |
| **筛选条件** | `customer_type="ALL" AND page_type="1"` |
| **数据类型** | currency → 货币符号由币种切片器决定，千分位整数 |
| **数据格式** | `#,##0`（在 DAX 中用 `__CurrencySymbol & FORMAT(__Value, "#,##0")` 拼接币种符号） |

---

### 2. Cost Rate — 花费占比

| 项目 | 内容 |
|---|---|
| **指标名称** | Cost Rate / 花费占比 |
| **业务定义** | 实际总媒体花费占比退后金额的百分比（默认含红包/返佣返货金） |
| **计算公式** | Cost / Net Sales × 1.13 / 1.06 |
| **分子** | `cost_amt`（含红包/返佣返货金） |
| **分母** | `net_sales_amt`（退后销售额） |
| **数据底表** | `a05_e2e_paid_media_summary_d` |
| **筛选条件** | `customer_type="ALL" AND page_type="1"` |
| **系数说明** | 结果需乘以 1.13 再除以 1.06 |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%;-#,##0.0%;0.0%` |

---

### 3. Cost (Exclude Refund) — 花费（剔除红包/返佣返货金）

| 项目 | 内容 |
|---|---|
| **指标名称** | Cost (Exclude Refund) / 花费（剔除红包/返佣返货金） |
| **业务定义** | 实际媒体花费，剔除红包/返佣返货金（纯媒体 charge，不含返还） |
| **计算公式** | 各投放表 cost 加总（不含红包/返佣返货金） |
| **统计字段** | `cost_amt - red_packet - rebate` |
| **数据底表** | `a05_e2e_paid_media_summary_d` |
| **筛选条件** | `customer_type="ALL" AND page_type="1"` |
| **数据类型** | currency → 货币符号由币种切片器决定，千分位整数 |
| **数据格式** | `#,##0`（在 DAX 中用 `__CurrencySymbol & FORMAT(__Value, "#,##0")` 拼接币种符号） |

---

### 4. Cost Rate (Exclude Refund) — 花费占比（剔除红包/返佣返货金）

| 项目 | 内容 |
|---|---|
| **指标名称** | Cost Rate (Exclude Refund) / 花费占比（剔除红包/返佣返货金） |
| **业务定义** | 实际媒体花费（剔除红包/返佣返货金）占比退后金额的百分比 |
| **计算公式** | Cost(Exclude Refund) / Net Sales × 1.13 / 1.06 |
| **分子** | `cost_amt - red_packet - rebate`（剔除红包/返佣返货金） |
| **分母** | `net_sales_amt`（退后销售额） |
| **数据底表** | `a05_e2e_paid_media_summary_d` |
| **筛选条件** | `customer_type="ALL" AND page_type="1"` |
| **系数说明** | 结果需乘以 1.13 再除以 1.06 |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%;-#,##0.0%;0.0%` |

---

### 5. Net Sales — 退后销售额

| 项目 | 内容 |
|---|---|
| **指标名称** | Net Sales / 退后销售额 |
| **统计字段** | `net_sales_amt` |
| **数据底表** | `a05_e2e_paid_media_summary_d` |
| **筛选条件** | `customer_type="ALL" AND page_type="1"` |
| **数据类型** | currency → 货币符号由币种切片器决定，千分位整数 |
| **数据格式** | `#,##0`（在 DAX 中用 `__CurrencySymbol & FORMAT(__Value, "#,##0")` 拼接币种符号） |

---

### 6. ROI — 媒体 ROI

| 项目 | 内容 |
|---|---|
| **指标名称** | ROI / 媒体 ROI |
| **业务定义** | 成交金额 / 花费，计算出 ROI |
| **计算公式** | 成交金额(投放) / Cost |
| **分子** | `media_sales_amt`（成交金额，投放带来） |
| **分母** | `cost_amt`（花费，ROI 分母含红包） |
| **数据底表** | `a05_e2e_paid_media_summary_d` |
| **筛选条件** | `customer_type="ALL" AND page_type="1"` |
| **注意** | 分母使用含红包/返佣返货金的 `cost_amt` |
| **数据类型** | decimal_1dp → 数值，保留一位小数 |
| **数据格式** | `#,##0.0` |

---

### 7. Acceleration Cost% — 第二品类花费%

| 项目 | 内容 |
|---|---|
| **指标名称** | Acceleration Cost% / 第二品类花费% |
| **业务定义** | 第二品类的花费占比总花费 |
| **计算公式** | Acceleration Cost / TTL Cost |
| **分子** | `cost_amt`（Acceleration 商品花费，即 `framework="Acceleration"`） |
| **分母** | `cost_amt`（商品表 TTL 花费，所有 framework） |
| **数据底表** | `a05_e2e_paid_media_summary_d` |
| **分子筛选** | `customer_type="ALL" AND framework="Acceleration" AND page_type="1"` |
| **分母筛选** | `customer_type="ALL" AND page_type="1"`（全部 framework） |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%;-#,##0.0%;0.0%` |

---

### 8. Acceleration SLS MOB% — 第二品类退后销售额 MOB%

| 项目 | 内容 |
|---|---|
| **指标名称** | Acceleration SLS MOB% / 第二品类退后销售额 MOB% |
| **业务定义** | 第二品类退后销售额占比 |
| **计算公式** | Acceleration SLS / TTL SLS |
| **分子** | `net_sales_amt`（Acceleration 退后销售额，即 `framework="Acceleration"`） |
| **分母** | `net_sales_amt`（全店 TTL 退后销售额，全部 framework） |
| **数据底表** | `a05_e2e_paid_media_summary_d` |
| **分子筛选** | `customer_type="ALL" AND framework="Acceleration" AND page_type="1"` |
| **分母筛选** | `customer_type="ALL"（全部 framework） AND page_type="1"` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%;-#,##0.0%;0.0%` |

---

### 9. ±Acceleration Cost% vs Net Sales% — 第二品类花费% vs Net Sales%

| 项目 | 内容 |
|---|---|
| **指标名称** | ±Acceleration Cost% vs Net Sales% / 第二品类花费% vs Net Sales% |
| **业务定义** | 第二品类的花费占比总花费 vs 零售净销售额占比 |
| **计算公式** | Acceleration Cost MOB% − Store SLS MOB%（×100 转为 bp） |
| **指标类型** | **派生指标**，无独立底表取数 |
| **计算逻辑** | 用 "Acceleration Cost%" 减去 "Acceleration SLS MOB%"，结果乘以 100 转为 basis points（bp） |
| **注意** | 此指标为两个已有指标相减得到，不直接查询底表 |
| **数据类型** | delta_bp_1dp → 值×100，带正负 bp（基点），保留一位小数 |
| **数据格式** | `"+#,##0.0'bp';-#,##0.0'bp';0.0'bp'"` |
| **YOY** | 本期bp - 去年bp，区别于传统的YOY，这里是对比本期与去年的bp变化，而不是对比本期与去年的百分比变化 |

---
### 10. New Customer Cost% — 招募新客花费占比

| 项目 | 内容 |
|---|---|
| **指标名称** | New Customer Cost% / 招募新客花费占比 |
| **业务定义** | New Customer Investment / NEW+EXISTING Total 花费 |
| **计算公式** | New Cost / (New Cost + Existing Cost) = New Cost / TTL Cost |
| **分子** | `cost_amt`（新客花费，即 `customer_type="NEW",包括(EXISTING、NEW、ALL)`） |
| **分母** | `cost_amt`（新客花费 + 老客花费，即 `customer_type="ALL"`） |
| **数据底表** | `a05_e2e_paid_media_summary_d` |
| **分子筛选** | `customer_type="NEW" AND page_type="2" AND channel in ("直通车","引力魔方","快车","触点")` |
| **分母筛选** | `customer_type in ("EXISTING","NEW") AND page_type="2" AND channel in ("直通车","引力魔方","快车","触点") ` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%;-#,##0.0%;0.0%` |

---

## 板块二：Growth Overview-Target Achievement

> **Actual 数据底表**：`a05_e2e_paid_media_summary_d`（默认）；Acceleration 系列用 `a05_e2e_paid_media_product_data`；Media Contribution 分母用 `a03_e2e_customer_data_m`
> **Target 数据底表**：`a05_e2e_paid_media_fcst_data_m`（预测专用表）
> **通用筛选条件**：`customer_type="ALL" AND page_type="1"`（除非指标另有说明）
> **日期切片器**：`Slicer_Time_Frame`，`TimeFrame_ID` 为前端展示的时间粒度（Month/Year），`TimeFrame_Value` 为展示值，slicer 所选时间区间 `data_date ∈ [TimeFrame_Min, TimeFrame_Max]`
> **时间粒度处理**：Month 按所选财月对应的完整日期范围汇总；Year 按所选财年对应的完整日期范围汇总
> **Target 缺失处理**：Target 缺失时，Target 及 ±Actual vs Target 展示"-"

---

### 11. Cost Rate — 目标花费占比

| 项目 | 内容 |
|---|---|
| **指标名称** | Cost Rate / 目标花费占比 |
| **业务定义** | 目标总媒体花费占比目标退后金额的百分比 |
| **Actual 计算公式** | `SUM(cost_amt) / SUM(net_sales_amt) × 1.13 / 1.06` |
| **Target 计算公式** | Month：`media_cost_rate`；Year：`year_media_cost_rate`（按 data_year） |
| **±Actual vs Target** | Actual - Target |
| **Actual 数据底表** | `a05_e2e_paid_media_summary_d` |
| **Target 数据底表** | `a05_e2e_paid_media_fcst_data_m` |
| **Actual 筛选条件** | `customer_type="ALL" AND page_type="1"` |
| **Actual 时间处理** | Month/Year 按所选财月/财年完整日期范围汇总 `cost_amt`、`net_sales_amt` 后按公式重算 |
| **Target 取数逻辑** | Month 取所选财月 `media_cost_rate`；Year 取所选财年 `year_media_cost_rate` |
| **系数说明** | Actual 结果需乘以 1.13 再除以 1.06 |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%;-#,##0.0%;0.0%` |

---

### 12. RTB Cost ACH% — 目标 RTB 花费进度达成

| 项目 | 内容 |
|---|---|
| **指标名称** | RTB Cost ACH% / 目标 RTB 花费进度达成 |
| **业务定义** | 目标 RTB 花费进度达成 |
| **Actual 计算公式** | `SUM(cost_amt) / rtb_cost_amt` |
| **Target 计算公式** | `100%`（固定值） |
| **±Actual vs Target** | Actual - Target |
| **Actual 分子数据底表** | `a05_e2e_paid_media_summary_d` ，筛选条件：`customer_type="ALL" AND channel_type="RTB" AND page_type="1"` |
| **Actual 分母数据底表** | `a05_e2e_paid_media_fcst_data_m` |
| **Actual 筛选条件** | 分子：`customer_type="ALL" AND channel_type="RTB" AND page_type="1"`；分母：根据Slicer_Time_Frame[TimeFrame_ID]时间粒度的不同，使用不同的字段`rtb_cost_amt`（Month）或`year_rtb_cost_amt`（Year） |
| **Actual 时间处理** | Month：按所选财月完整日期范围汇总 `cost_amt`，除以该财月 `rtb_cost_amt`；Year：按所选财年完整日期范围汇总 `cost_amt`，除以 `year_rtb_cost_amt`（按 data_year） |
| **注意** | 仅统计 RTB 渠道（`channel_type="RTB"`），Actual - Target中的Target固定位100%，即1 |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%;-#,##0.0%;0.0%` |

---

### 13. Cost ACH% — 目标花费进度达成

| 项目 | 内容 |
|---|---|
| **指标名称** | Cost ACH% / 目标花费进度达成 |
| **业务定义** | 目标花费进度达成 |
| **Actual 计算公式** | `SUM(cost_amt) / Cost Target` |
| **Target 计算公式** | `100%`（固定值） |
| **±Actual vs Target** | Actual - Target |
| **Actual 分子数据底表** | `a05_e2e_paid_media_summary_d`，筛选条件：`customer_type="ALL" AND page_type="1"` |
| **Actual 分母数据底表** | `a05_e2e_paid_media_fcst_data_m` |
| **Actual 筛选条件** | 分子：`customer_type="ALL" AND page_type="1"`；分母：根据Slicer_Time_Frame[TimeFrame_ID]时间粒度的不同，使用不同的字段`cost_amt`（Month）或`year_cost_amt`（Year）  |
| **Actual 时间处理** | Month：按所选财月完整日期范围汇总 `cost_amt`，除以该财月 Cost Target（`cost_amt`）；Year：按所选财年完整日期范围汇总 `cost_amt`，除以 `year_cost_amt`（按 data_year） |
| **注意** |Actual：Actual 分子/Actual 分母;Target:固定位100%，即1;±Actual vs Target:Actual - Target |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%;-#,##0.0%;0.0%` |

---

### 14. Cost (Exclude Refund) ACH% — 目标花费（剔除红包/返佣返货金）进度达成

| 项目 | 内容 |
|---|---|
| **指标名称** | Cost (Exclude Refund) ACH% / 目标花费（剔除红包/返佣返货金）进度达成 |
| **业务定义** | 目标花费（剔除红包/返佣返货金）进度达成 |
| **Actual 计算公式** | `(SUM(cost_amt) - SUM(red_packet) - SUM(rebate)) / Cost Target` |
| **Target 计算公式** | `100%`（固定值） |
| **±Actual vs Target** | Actual - Target |
| **Actual 分子数据底表** | `a05_e2e_paid_media_summary_d`，筛选条件：`customer_type="ALL" AND page_type="1"` |
| **Actual 分母数据底表** | `a05_e2e_paid_media_fcst_data_m` |
| **Actual 筛选条件** | 分子：`customer_type="ALL" AND page_type="1"`；分母：根据Slicer_Time_Frame[TimeFrame_ID]时间粒度的不同，使用不同的字段`cost_amt`（Month）或`year_cost_amt`（Year） |
| **Actual 时间处理** | Month：按所选财月完整日期范围汇总 `cost_amt`、`red_packet`、`rebate`，以 `SUM(cost_amt)-SUM(red_packet)-SUM(rebate)` 除以该财月 Cost Target；Year：按所选财年完整日期范围汇总同一组组成项，除以 `year_cost_amt`（按 data_year） |
| **注意** |Actual：Actual 分子/Actual 分母;Target:固定位100%，即1;±Actual vs Target:Actual - Target |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%;-#,##0.0%;0.0%` |

---

### 15. Net Sales ACH% — 目标退后销售金额进度达成

| 项目 | 内容 |
|---|---|
| **指标名称** | Net Sales ACH% / 目标退后销售金额进度达成 |
| **业务定义** | 目标退后销售金额进度达成 |
| **Actual 计算公式** | `SUM(net_sales_amt) / Net Sales Target` |
| **Target 计算公式** | `100%`（固定值） |
| **±Actual vs Target** | Actual - Target |
| **Actual 分子数据底表** | `a05_e2e_paid_media_summary_d`,筛选条件：`customer_type="ALL" AND page_type="1"` |
| **Actual 分母数据底表** | `a05_e2e_paid_media_fcst_data_m` |
| **Actual 筛选条件** | 分子：`customer_type="ALL" AND page_type="1"`；分母：根据Slicer_Time_Frame[TimeFrame_ID]时间粒度的不同，使用不同的字段`net_sales_amt`（Month）或`year_net_sales_amt`（Year） |
| **Actual 时间处理** | Month：按所选财月完整日期范围汇总 `net_sales_amt`，除以该财月 Net Sales Target（`net_sales_amt`）；Year：按所选财年完整日期范围汇总 `net_sales_amt`，除以 `MAX(year_net_sales_amt)`（按 data_year） |
| **注意** |Actual：Actual 分子/Actual 分母;Target:固定位100%，即1;±Actual vs Target:Actual - Target |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%;-#,##0.0%;0.0%` |

---

### 16. Demand Sales ACH% — 目标销售额进度达成

| 项目 | 内容 |
|---|---|
| **指标名称** | Demand Sales ACH% / 目标销售额进度达成 |
| **业务定义** | 目标销售额进度达成 |
| **Actual 计算公式** | `SUM(sales_amt) / Demand Sales Target` |
| **Target 计算公式** | `100%`（固定值） |
| **±Actual vs Target** | Actual - Target |
| **Actual 分子数据底表** | `a05_e2e_paid_media_summary_d`,筛选条件：`customer_type="ALL" AND page_type="1"` |
| **Actual 分母数据底表** | `a05_e2e_paid_media_fcst_data_m` |
| **Actual 筛选条件** | 分子：`customer_type="ALL" AND page_type="1"`；分母：根据Slicer_Time_Frame[TimeFrame_ID]时间粒度的不同，使用不同的字段`sales_amt`（Month）或`year_sales_amt`（Year） |
| **Actual 时间处理** | Month：按所选财月完整日期范围汇总 `sales_amt`，除以该财月 Demand Sales Target（`sales_amt`）；Year：按所选财年完整日期范围汇总 `sales_amt`，除以 `MAX(year_sales_amt)`（按 data_year） |
| **注意** | Demand = 总销售额（非退后销售额） |
| **注意** |Actual：Actual 分子/Actual 分母;Target:固定位100%，即1;±Actual vs Target:Actual - Target |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%;-#,##0.0%;0.0%` |

---

### 17. Acceleration Cost% — 目标第二品类花费占比

| 项目 | 内容 |
|---|---|
| **指标名称** | Acceleration Cost% / 目标第二品类花费占比 |
| **业务定义** | 目标第二品类花费占比总目标花费 |
| **Actual 计算公式** | `SUM(cost_amt[framework="Acceleration"]) / SUM(cost_amt[全部 framework])` |
| **Target 计算公式** | Month：`acceleration_cost_rate`；Year：`year_acceleration_cost_rate`（按 data_year） |
| **±Actual vs Target** | Actual - Target |
| **Actual 数据底表** | `a05_e2e_paid_media_product_data`,筛选条件：`customer_type="ALL" AND page_type="1"` |
| **Target 数据底表** | `a05_e2e_paid_media_fcst_data_m` |
| **Actual 筛选条件** | `customer_type="ALL" AND page_type="1"` |
| **Actual 时间处理** | Month：在所选财月完整日期范围内，分别汇总 `framework="Acceleration"` 的 `cost_amt` 和全部 framework 的 `cost_amt` 后重算占比；Year：在所选财年完整日期范围内，按同一方式汇总分子、分母后重算占比 |
| **Target 取数逻辑** | Month 取所选财月 `acceleration_cost_rate`；Year 取所选财年 `year_acceleration_cost_rate` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%;-#,##0.0%;0.0%` |

---

### 18. Acceleration Net Sales% — 第二品类退后销售额占比

| 项目 | 内容 |
|---|---|
| **指标名称** | Acceleration Net Sales% / 第二品类退后销售额占比 |
| **业务定义** | 目标退后销售额占比 |
| **Actual 计算公式** | `SUM(net_sales_amt[framework="Acceleration"]) / SUM(net_sales_amt[全部 framework])` |
| **Target 计算公式** | Month：`acceleration_net_sales_rate`；Year：`year_acceleration_net_sales_rate`（按 data_year） |
| **±Actual vs Target** | Actual - Target |
| **Actual 数据底表** | `a05_e2e_paid_media_product_data`,筛选条件：`customer_type="ALL" AND page_type="1"` |
| **Target 数据底表** | `a05_e2e_paid_media_fcst_data_m` |
| **Actual 筛选条件** | `customer_type="ALL" AND page_type="1"` |
| **Actual 时间处理** | Month：在所选财月完整日期范围内，分别汇总 `framework="Acceleration"` 的 `net_sales_amt` 和全部 framework 的 `net_sales_amt` 后重算占比；Year：在所选财年完整日期范围内，按同一方式汇总分子、分母后重算占比 |
| **Target 取数逻辑** | Month 取所选财月 `acceleration_net_sales_rate`；Year 取所选财年 `year_acceleration_net_sales_rate` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%;-#,##0.0%;0.0%` |

---

### 19. Media Contribution to New Customer Acquisition% — 媒体新客贡献率

| 项目 | 内容 |
|---|---|
| **指标名称** | Media Contribution to New Customer Acquisition% / 媒体新客贡献率 |
| **业务定义** | 目标媒体新客贡献率 |
| **Actual 计算公式** | 媒体新客数 / 全店新客数 |
| **Actual 分子** | `media_member_cnt`（来自 `a05_e2e_paid_media_summary_d`） |
| **Actual 分母** | `count(distinct user_id)`（来自 `a03_e2e_customer_data_m`） |
| **Target 计算公式** | Month：`media_new_customer_contribution_rate`；Year：`year_media_new_customer_contribution_rate`（按 data_year） |
| **±Actual vs Target** | Actual - Target |
| **Target 数据底表** | `a05_e2e_paid_media_fcst_data_m` |
| **Actual 分子筛选条件** | `customer_type="ALL" AND page_type="1"` |
| **Actual 分子时间处理** | Month：按 `platform + data_year + data_month` 取 `media_member_cnt`；Year 及 Platform="ALL"：先按 `platform + data_year + data_month` 取 `media_member_cnt`，再对所选财月及平台 SUM。仅支持完整财月、财年 |
| **Actual 分母计算逻辑** | data_date ∈ start_period AND net_pay_amt > 0 AND is_member = 0 AND lp_12m_net_pay_amt = 0 （Step1：筛选在所选时间范围内 net sales > 0 的 user_id（`dt = 所选时间范围, SUM(net_pay_amt) > 0 WHERE is_member = 0`）；Step2：缩小顾客范围至 start period 往前推 12 个月无消费（`dt = 所选时间范围 start_period, lp_12m_net_pay_amt = 0`）；两步交集即为全店新客） |
| **Target 取数逻辑** | Month 取所选财月 `media_new_customer_contribution_rate`；Year 取所选财年 `year_media_new_customer_contribution_rate` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%;-#,##0.0%;0.0%` |

---

### 20. Cost Per New Acquisition — 目标媒体新客获客成本

| 项目 | 内容 |
|---|---|
| **指标名称** | Cost Per New Acquisition / 目标媒体新客获客成本 |
| **业务定义** | 目标总新客花费 / 目标总媒体新客的数量 |
| **Actual 计算公式** | `media_cost_amt / media_member_cnt`（先按 platform + data_year + data_month 取 MAX 再 SUM 后相除） |
| **Target 计算公式** | Month：`cost_per_new_acquisition`；Year：`year_cost_per_new_acquisition`（按 data_year） |
| **±Actual vs Target** | Actual / Target - 1 |
| **Actual 数据底表** | `a05_e2e_paid_media_summary_d` |
| **Target 数据底表** | `a05_e2e_paid_media_fcst_data_m` |
| **Actual 筛选条件** | `customer_type="ALL" AND page_type="1"` |
| **Actual 时间处理** | Month：按所选财月完整日期范围，先按 `platform + data_year + data_month` 分别取 `media_cost_amt`、`media_member_cnt`，再对所选平台 SUM，以汇总后的 `media_cost_amt / media_member_cnt` 计算；Year：按所选财年完整日期范围，先按 `platform + data_year + data_month` 分别取 `media_cost_amt`、`media_member_cnt`，再对所选财年及平台 SUM，以汇总后的 `media_cost_amt / media_member_cnt` 计算,Platform="ALL"同理。 |
| **Target 取数逻辑** | Month 取所选财月 `cost_per_new_acquisition`；Year 取所选财年 `year_cost_per_new_acquisition` |
| **边界处理** | Target 缺失或为 0 时，Target 及 ±Actual vs Target 展示"-"；汇总后的 `media_member_cnt` 为 0 时，Actual 及 ±Actual vs Target 展示"-" |
| **数据类型** | currency_decimal_1dp → 货币符号由币种切片器决定，千分位保留一位小数 |
| **数据格式** | `#,##0.0`（在 DAX 中用 `__CurrencySymbol & FORMAT(__Value, "#,##0.0")` 拼接币种符号） |

---

## 通用规则汇总

| 规则项 | 说明 |
|---|---|
| **Actual 数据底表** | `a05_e2e_paid_media_summary_d`（默认）；Acceleration 系列用 `a05_e2e_paid_media_product_data`；Media Contribution 分母用 `a03_e2e_customer_data_m` |
| **Target 数据底表** | `a05_e2e_paid_media_fcst_data_m`（预测专用表，按财月/财年粒度取数） |
| **通用筛选条件** | `customer_type="ALL" AND page_type="1"`（除非指标另有说明） |
| **RTB 渠道指标** | 使用 `customer_type="ALL" AND channel_type="RTB" AND page_type="1"` |
| **Acceleration 品类** | 分子需额外加 `framework="Acceleration"` 筛选，数据源 `a05_e2e_paid_media_product_data` |
| **Cost Rate 系数** | Cost Rate 的 Actual 需乘以 1.13 再除以 1.06 |
| **红包/返佣返货金** | Cost (Exclude Refund) ACH% 使用 `SUM(cost_amt)-SUM(red_packet)-SUM(rebate)` |
| **日期切片器** | `Slicer_Time_Frame`：`TimeFrame_ID`（时间粒度 Month/Year），`TimeFrame_Value`（展示值），所选时间区间 `data_date ∈ [TimeFrame_Min, TimeFrame_Max]` |
| **Month 时间处理** | 按所选财月对应的完整日期范围（`TimeFrame_Min ~ TimeFrame_Max`）汇总 |
| **Year 时间处理** | 按所选财年对应的完整日期范围（`TimeFrame_Min ~ TimeFrame_Max`）汇总 |
| **Target 取数规则** | Month Target 取对应 rate 字段；Year Target 按 `data_year` 取 `MAX(year_*_rate)` |
| **ACH% 类指标（ID 12-16）** | Target 固定 100%，Actual = 实际值 / 该财月/财年 Target 值（Target 值来自 `a05_e2e_paid_media_fcst_data_m`） |
| **Target 缺失处理** | Target 缺失时，Target 及 ±Actual vs Target 展示"-"；Cost Per New Acquisition 额外处理 Target=0 及 `media_member_cnt`=0 |
| **派生指标** | ±Acceleration Cost% vs Net Sales% 为派生指标，由两个已有指标相减得到，不直接查询底表 |
| **数据格式规则** | 花费金额类用 `currency`（`#,##0`）；占比/达成率类用 `percent_1dp`（`#,##0.0%`，不含正号）；货币小数类用 `currency_decimal_1dp`（`#,##0.0`）；所有小数均保留一位 |
| **在生成 Power BI DAX/Power Query 代码时，严格遵循语法规范** | 文本常量（Text Values）必须使用双引号 " ",禁止使用单引号；单引号 ' '仅用于表名,列名使用方括号 [ ],例如：[framework] = "Acceleration" |

---

## 板块二 Actual / Target 行数据格式

> 来源：`Overview\目标达成\KPIs Overview_Target_matrix_solution`
> 日期切片器：`Slicer_Time_Frame`，`TimeFrame_ID` 为时间粒度（Month/Year），`TimeFrame_Value` 为展示值，所选时间区间 `data_date ∈ [TimeFrame_Min, TimeFrame_Max]`

### Actual 行（`__Indicator = "Actual"`）

- 度量值：`KPIs Overview Target Actual Base Value`，最终返回 `__ActualConverted`
- 日期范围：切片器选择的日期范围（`data_date ∈ [TimeFrame_Min, TimeFrame_Max]`，与事实表断开连接，之前的Dim_Date_Current ── 1:* ──→ a05_e2e_paid_media_summary_d / product_data_d，所以在涉及到a05_e2e_paid_media_summary_d / product_data_d计算时需要移除Dim_Date_Current表的影响，再添加新的日期范围筛选，日期字段为a05_e2e_paid_media_summary_d[data_date]\a05_e2e_paid_media_fcst_data_m[data_date]。）
- 数据源字段：实际字段（`cost_amt`、`net_sales_amt`、`sales_amt` 等）
- 金额类指标（`Metric_IsCurrencyAmount=TRUE`）× ExchangeRate；比率类指标汇率约分抵消

| # | Metric_Name | 计算公式 | 筛选条件 | 格式 |
|---|-------------|---------|----------|------|
| 1 | Cost Rate | `SUM(cost_amt) / SUM(net_sales_amt) × 1.13 / 1.06` | `customer_type="ALL" AND page_type="1"` | percent_1dp |
| 2 | RTB Cost ACH% | `SUM(cost_amt) / rtb_cost_amt` | `customer_type="ALL" AND channel_type="RTB" AND page_type="1"` | percent_1dp |
| 3 | Cost ACH% | `SUM(cost_amt) / Cost Target` | `customer_type="ALL" AND page_type="1"` | percent_1dp |
| 4 | Cost ACH%(Exclude Refund) | `(SUM(cost_amt)-SUM(red_packet)-SUM(rebate)) / Cost Target` | `customer_type="ALL" AND page_type="1"` | percent_1dp |
| 5 | Net Sales ACH% | `SUM(net_sales_amt) / Net Sales Target` | `customer_type="ALL" AND page_type="1"` | percent_1dp |
| 6 | Demand Sales ACH% | `SUM(sales_amt) / Demand Sales Target` | `customer_type="ALL" AND page_type="1"` | percent_1dp |
| 7 | Acceleration Cost% | `SUM(cost_amt[framework="Acceleration"]) / SUM(cost_amt)` | `customer_type="ALL" AND page_type="1"`（数据源 `a05_e2e_paid_media_product_data`） | percent_1dp |
| 8 | Acceleration Net Sales% | `SUM(net_sales_amt[framework="Acceleration"]) / SUM(net_sales_amt)` | `customer_type="ALL" AND page_type="1"`（数据源 `a05_e2e_paid_media_product_data`） | percent_1dp |
| 9 | Media Contribution to New Customer Acquisition% | `媒体新客数(media_member_cnt) / 全店新客数(count distinct user_id)` | 分子：`customer_type="ALL" AND page_type="1"`；分母：`a03_e2e_customer_data_m` 按 platform, shop_info_id 去重 | percent_1dp |
| 10 | Cost Per New Acquisition | `SUM(media_cost_amt) / SUM(media_member_cnt)`（先按 platform + data_year + data_month 取 MAX 再 SUM） | `customer_type="ALL" AND page_type="1"` | currency_decimal_1dp |

### Target 行（`__Indicator = "Target"`）

- 度量值：`KPIs Overview Target Target Base Value`，最终返回 `__TargetConverted`
- 数据底表：`a05_e2e_paid_media_fcst_data_m`（预测专用表）
- 日期范围：按 `Slicer_Time_Frame` 的 `TimeFrame_Min ~ TimeFrame_Max` 对应的完整财月/财年
- ACH% 类指标（ID 2-6）：Target 固定 100%
- 比率类指标（ID 1, 7-9）：Month 取对应 rate 字段，Year 取 `MAX(year_*_rate)`（按 data_year）
- 金额类指标（ID 10）：Month 取 `cost_per_new_acquisition`，Year 取 `year_cost_per_new_acquisition`

| # | Metric_Name | 计算公式 | 筛选条件 | 格式 |
|---|-------------|---------|----------|------|
| 1 | Cost Rate | Month：`media_cost_rate`；Year：`year_media_cost_rate` | 同 Actual | percent_1dp |
| 2 | RTB Cost ACH% | `100%`（固定值） | 同 Actual | percent_1dp |
| 3 | Cost ACH% | `100%`（固定值） | 同 Actual | percent_1dp |
| 4 | Cost ACH%(Exclude Refund) | `100%`（固定值） | 同 Actual | percent_1dp |
| 5 | Net Sales ACH% | `100%`（固定值） | 同 Actual | percent_1dp |
| 6 | Demand Sales ACH% | `100%`（固定值） | 同 Actual | percent_1dp |
| 7 | Acceleration Cost% | Month：`acceleration_cost_rate`；Year：`year_acceleration_cost_rate` | 同 Actual | percent_1dp |
| 8 | Acceleration Net Sales% | Month：`acceleration_net_sales_rate`；Year：`year_acceleration_net_sales_rate` | 同 Actual | percent_1dp |
| 9 | Media Contribution to New Customer Acquisition% | Month：`media_new_customer_contribution_rate`；Year：`year_media_new_customer_contribution_rate` | 同 Actual | percent_1dp |
| 10 | Cost Per New Acquisition | Month：`cost_per_new_acquisition`；Year：`year_cost_per_new_acquisition` | 同 Actual | currency_decimal_1dp |

> 注意：
> - ACH% 类指标（ID 2-6）Target 固定 100%，Actual = 实际值 / 该财月/财年 Target 值（Target 值来自 `a05_e2e_paid_media_fcst_data_m` 对应字段）
> - 比率类指标（ID 1, 7-9）Target 缺失时，Target 及 ±Actual vs Target 展示"-"
> - Cost Per New Acquisition（ID 10）：Target 缺失或为 0 时展示"-"；汇总后的 `media_member_cnt` 为 0 时，Actual 及 ±Actual vs Target 展示"-"
> - ID 10 ±Actual vs Target = Actual / Target - 1（区别于其他指标的 Actual - Target）
> - ID 19 分母新客判定：Step1（所选时间范围 `SUM(net_pay_amt) > 0 AND is_member = 0`）∩ Step2（start_period `lp_12m_net_pay_amt = 0`）


