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
| **数据格式** | `#,##0.0%;#,##0.0%;0.0%` |

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
| **数据格式** | `#,##0.0%;#,##0.0%;0.0%` |

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
| **数据格式** | `#,##0.0%;#,##0.0%;0.0%` |

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
| **数据格式** | `#,##0.0%;#,##0.0%;0.0%` |

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
| **数据格式** | `#,##0.0%;#,##0.0%;0.0%` |

---

## 板块二：Growth Overview-Target Achievement

### 11. Cost Rate — 目标花费占比

| 项目 | 内容 |
|---|---|
| **指标名称** | Cost Rate / 目标花费占比 |
| **业务定义** | 目标总媒体花费占比目标退后金额的百分比 |
| **Actual 统计字段** | `cost_amt / net_sales_amt` × 1.13 / 1.06 |
| **Target 统计字段** | `fcst_cost_amt / fcst_net_sales_amt` |
| **数据底表** | `a05_e2e_paid_media_summary_d` |
| **筛选条件** | `customer_type="ALL" AND page_type="1"` |
| **系数说明** | 结果需乘以 1.13 再除以 1.06 |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%;#,##0.0%;0.0%` |

---

### 12. RTB Cost ACH% — 目标 RTB 花费进度达成

| 项目 | 内容 |
|---|---|
| **指标名称** | RTB Cost ACH% / 目标 RTB 花费进度达成 |
| **业务定义** | 目标 RTB 花费进度达成 |
| **计算公式** | cost_amt / fcst_cost_amt |
| **统计字段** | `cost_amt / fcst_cost_amt` |
| **Actual 统计字段** | `cost_amt`（分子，Actual） |
| **Target 统计字段** | `fcst_cost_amt`（分母，Target） |
| **数据底表** | `a05_e2e_paid_media_summary_d` |
| **筛选条件** | `customer_type="ALL" AND channel_type="RTB" AND page_type="1"` |
| **注意** | 仅统计 RTB 渠道（`channel_type="RTB"`） |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%;#,##0.0%;0.0%` |

---

### 13. Cost ACH% — 目标花费进度达成

| 项目 | 内容 |
|---|---|
| **指标名称** | Cost ACH% / 目标花费进度达成 |
| **业务定义** | 目标花费进度达成 |
| **计算公式** | cost_amt / fcst_cost_amt |
| **统计字段** | `cost_amt / fcst_cost_amt` |
| **Actual 统计字段** | `cost_amt`（分子，Actual） |
| **Target 统计字段** | `fcst_cost_amt`（分母，Target） |
| **数据底表** | `a05_e2e_paid_media_summary_d` |
| **筛选条件** | `customer_type="ALL" AND page_type="1"` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%;#,##0.0%;0.0%` |

---

### 14. Cost (Exclude Refund) ACH% — 目标花费（剔除红包/返佣返货金）进度达成

| 项目 | 内容 |
|---|---|
| **指标名称** | Cost (Exclude Refund) ACH% / 目标花费（剔除红包/返佣返货金）进度达成 |
| **业务定义** | 目标花费（剔除红包/返佣返货金）进度达成 |
| **计算公式** | (cost_amt - red_packet - rebate) / fcst_cost_amt |
| **统计字段** | `(cost_amt - red_packet - rebate) / fcst_cost_amt` |
| **Actual 统计字段** | `cost_amt - red_packet - rebate`（分子，Actual） |
| **Target 统计字段** | `fcst_cost_amt`（分母，Target） |
| **数据底表** | `a05_e2e_paid_media_summary_d` |
| **筛选条件** | `customer_type="ALL" AND page_type="1"` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%;#,##0.0%;0.0%` |

---

### 15. Net Sales ACH% — 目标退后销售金额进度达成

| 项目 | 内容 |
|---|---|
| **指标名称** | Net Sales ACH% / 目标退后销售金额进度达成 |
| **业务定义** | 目标退后销售金额进度达成 |
| **计算公式** | net_sales_amt / fcst_net_sales_amt |
| **统计字段** | `net_sales_amt / fcst_net_sales_amt` |
| **Actual 统计字段** | `net_sales_amt`（分子，Actual） |
| **Target 统计字段** | `fcst_net_sales_amt`（分母，Target） |
| **数据底表** | `a05_e2e_paid_media_summary_d` |
| **筛选条件** | `customer_type="ALL" AND page_type="1"` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%;#,##0.0%;0.0%` |

---

### 16. Demand Sales ACH% — 目标销售额进度达成

| 项目 | 内容 |
|---|---|
| **指标名称** | Demand Sales ACH% / 目标销售额进度达成 |
| **业务定义** | 目标销售额进度达成 |
| **计算公式** | sales_amt / fcst_sales_amt（Demand = 总销售额） |
| **统计字段** | `sales_amt / fcst_sales_amt` |
| **Actual 统计字段** | `sales_amt`（分子，Actual） |
| **Target 统计字段** | `fcst_sales_amt`（分母，Target） |
| **数据底表** | `a05_e2e_paid_media_summary_d` |
| **筛选条件** | `customer_type="ALL" AND page_type="1"` |
| **注意** | Demand = 总销售额（非退后销售额） |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%;#,##0.0%;0.0%` |

---

### 17. Acceleration Cost% — 目标第二品类花费占比

| 项目 | 内容 |
|---|---|
| **指标名称** | Acceleration Cost% / 目标第二品类花费占比 |
| **业务定义** | 目标第二品类花费占比总目标花费 |
| **Actual 统计字段** | `cost_amt[framework="Acceleration"] / cost_amt[TTL]` |
| **Target 统计字段** | `fcst_cost_amt[framework="Acceleration"] / fcst_cost_amt[TTL]` |
| **数据底表** | `a05_e2e_paid_media_summary_d` |
| **筛选条件** | `customer_type="ALL" AND page_type="1"` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%;#,##0.0%;0.0%` |

---

### 18. Acceleration Net Sales% — 第二品类退后销售额占比

| 项目 | 内容 |
|---|---|
| **指标名称** | Acceleration Net Sales% / 第二品类退后销售额占比 |
| **业务定义** | 目标退后销售额占比 |
| **Actual 统计字段** | `net_sales_amt[framework="Acceleration"] / net_sales_amt[TTL]` |
| **Target 统计字段** | `fcst_net_sales_amt[framework="Acceleration"] / fcst_net_sales_amt[TTL]` |
| **数据底表** | `a05_e2e_paid_media_summary_d` |
| **筛选条件** | `customer_type="ALL" AND page_type="1"` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%;#,##0.0%;0.0%` |

---

### 19. Media Contribution to New Customer Acquisition% — 媒体新客贡献率

| 项目 | 内容 |
|---|---|
| **指标名称** | Media Contribution to New Customer Acquisition% / 媒体新客贡献率 |
| **业务定义** | 目标媒体新客贡献率 |
| **Actual 统计字段** | `media_member_cnt / member_cnt` |
| **Target 统计字段** | `fcst_media_member_cnt / fcst_member_cnt` |
| **数据底表** | `a05_e2e_paid_media_summary_d` |
| **筛选条件** | `customer_type="NEW" AND page_type="1"` |
| **注意** | 仅统计新客（`customer_type="NEW"`） |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%;#,##0.0%;0.0%` |

---

### 20. Cost Per New Acquisition — 目标媒体新客获客成本

| 项目 | 内容 |
|---|---|
| **指标名称** | Cost Per New Acquisition / 目标媒体新客获客成本 |
| **业务定义** | 目标总新客花费 / 目标总媒体新客的数量 |
| **Actual 统计字段** | `media_cost_amt / media_member_cnt` |
| **Target 统计字段** | `fcst_media_cost_amt / fcst_media_member_cnt` |
| **数据底表** | `a05_e2e_paid_media_summary_d` |
| **筛选条件** | `customer_type="NEW" AND page_type="1"` |
| **注意** | 仅统计新客（`customer_type="NEW"`） |
| **数据类型** | currency_decimal_1dp → 货币符号由币种切片器决定，千分位保留一位小数 |
| **数据格式** | `#,##0.0`（在 DAX 中用 `__CurrencySymbol & FORMAT(__Value, "#,##0.0")` 拼接币种符号） |  

---

## 通用规则汇总

| 规则项 | 说明 |
|---|---|
| **数据底表** | 全部指标统一使用 `a05_e2e_paid_media_summary_d` |
| **通用筛选条件** | `customer_type="ALL" AND page_type="1"`（除非指标另有说明） |
| **新客相关指标** | 使用 `customer_type="NEW" AND page_type="1"` |
| **RTB 渠道指标** | 使用 `customer_type="ALL" AND channel_type="RTB" AND page_type="1"` |
| **Acceleration 品类** | 分子需额外加 `framework="Acceleration"` 筛选 |
| **Cost Rate 系数** | Cost Rate 和 Cost Rate (Exclude Refund) 需乘以 1.13 再除以 1.06 |
| **红包/返佣返货金** | 带 "Exclude Refund" 的指标使用 `cost_amt - red_packet - rebate` |
| **Target Achievement 指标** | 同时包含 Actual 和 Target 两套计算逻辑，Actual 用实际值，Target 用 `fcst_` 前缀字段 |
| **派生指标** | ±Acceleration Cost% vs Net Sales% 为派生指标，由两个已有指标相减得到，不直接查询底表 |
| **数据格式规则** | 花费金额类用 `currency`（`#,##0`，币种符号由切片器决定）；占比/达成率类用 `percent_1dp`（`#,##0.0%`，不含正号）；ROI 用 `decimal_1dp`（`#,##0.0`）；bp 派生指标用 `delta_bp_1dp`（带正负号，`+#,##0.0'bp'`）；所有小数均保留一位 |
| **在生成 Power BI DAX/Power Query 代码时，严格遵循语法规范** | 文本常量（Text Values）必须使用双引号 " ",禁止使用单引号；单引号 ' '仅用于表名,列名使用方括号 [ ],例如：[framework] = "Acceleration" |
| **仅版块二受此规则** | Target 针对日期筛选有特别之处，不满一个月的情况，补满一个月，比如日期切片器选择2026-05-05~2026-06-19，Target 范围应该为2026-05-01~2026-06-30 |

---

## 板块二 Actual / Target 行数据格式

> 来源：`Overview\目标达成\KPIs Overview_Target_matrix_solution`（v4）

### Actual 行（`__Indicator = "Actual"`）

- 度量值：`KPIs Overview Target Actual Base Value`，最终返回 `__ActualConverted`
- 日期范围：切片器选择的日期范围（通过关系自然传递）
- 数据源字段：实际字段（`cost_amt`、`net_sales_amt`、`sales_amt` 等）
- 金额类指标（`Metric_IsCurrencyAmount=TRUE`）× ExchangeRate；比率类指标汇率约分抵消

| # | Metric_Name | 计算公式 | 筛选条件 | 格式 |
|---|-------------|---------|----------|------|
| 1 | Cost Rate | `SUM(cost_amt) / SUM(net_sales_amt)` | `customer_type="ALL" AND page_type="1"` | percent_1dp |
| 2 | RTB Cost ACH% | `SUM(cost_amt)` | `customer_type="ALL" AND channel_type="RTB" AND page_type="1"` | currency |
| 3 | Cost ACH% | `SUM(cost_amt)` | `customer_type="ALL" AND page_type="1"` | currency |
| 4 | Cost ACH%(Exclude Refund) | `SUMX(cost_amt - red_packet - rebate)` | `customer_type="ALL" AND page_type="1"` | currency |
| 5 | Net Sales ACH% | `SUM(net_sales_amt)` | `customer_type="ALL" AND page_type="1"` | currency |
| 6 | Demand Sales ACH% | `SUM(sales_amt)` | `customer_type="ALL" AND page_type="1"` | currency |
| 7 | Acceleration Cost% | `SUM(cost_amt[framework="Acceleration"]) / SUM(cost_amt)` | `customer_type="ALL" AND page_type="1"` | percent_1dp |
| 8 | Acceleration Net Sales% | `SUM(net_sales_amt[framework="Acceleration"]) / SUM(net_sales_amt)` | `customer_type="ALL" AND page_type="1"` | percent_1dp |
| 9 | Media Contribution to New Customer Acquisition% | `SUM(media_member_cnt) / SUM(member_cnt)` | `customer_type="NEW" AND page_type="1"` | percent_1dp |
| 10 | Cost Per New Acquisition | `SUM(media_cost_amt) / SUM(media_member_cnt)` | `customer_type="NEW" AND page_type="1"` | currency_decimal_1dp |

### Target 行（`__Indicator = "Target"`）

- 度量值：`KPIs Overview Target Target Base Value`，最终返回 `__TargetConverted`
- 日期范围：补满月（`__MonthStart = DATE(YEAR(__MinDate), MONTH(__MinDate), 1)`，`__MonthEnd = EOMONTH(__MaxDate, 0)`）
- 数据源字段：预测字段（`fcst_cost_amt`、`fcst_net_sales_amt`、`fcst_sales_amt` 等）
- 日期实现：`REMOVEFILTERS(Dim_Date_Current)` + 重施加 `__MonthStart ~ __MonthEnd` 直接筛选事实表 `data_date`
- 其余筛选条件（Platform / customer_type / page_type / trans_cycle）与 Actual 行一致

| # | Metric_Name | 计算公式 | 筛选条件 | 格式 |
|---|-------------|---------|----------|------|
| 1 | Cost Rate | `SUM(fcst_cost_amt) / SUM(fcst_net_sales_amt)` | 同 Actual | percent_1dp |
| 2 | RTB Cost ACH% | `SUM(fcst_cost_amt)` | 同 Actual | currency |
| 3 | Cost ACH% | `SUM(fcst_cost_amt)` | 同 Actual | currency |
| 4 | Cost ACH%(Exclude Refund) | `SUM(fcst_cost_amt)` | 同 Actual | currency |
| 5 | Net Sales ACH% | `SUM(fcst_net_sales_amt)` | 同 Actual | currency |
| 6 | Demand Sales ACH% | `SUM(fcst_sales_amt)` | 同 Actual | currency |
| 7 | Acceleration Cost% | `SUM(fcst_cost_amt[framework="Acceleration"]) / SUM(fcst_cost_amt)` | 同 Actual | percent_1dp |
| 8 | Acceleration Net Sales% | `SUM(fcst_net_sales_amt[framework="Acceleration"]) / SUM(fcst_net_sales_amt)` | 同 Actual | percent_1dp |
| 9 | Media Contribution to New Customer Acquisition% | `SUM(fcst_media_member_cnt) / SUM(fcst_member_cnt)` | 同 Actual | percent_1dp |
| 10 | Cost Per New Acquisition | `SUM(fcst_media_cost_amt) / SUM(fcst_media_member_cnt)` | 同 Actual | currency_decimal_1dp |

> 注意：ID 4 Actual 行使用 `SUMX(cost_amt - red_packet - rebate)` 三项相减，Target 行仅使用 `SUM(fcst_cost_amt)`（预测字段已包含退款剔除逻辑）。


