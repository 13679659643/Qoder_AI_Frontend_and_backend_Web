# KPI Progress 指标口径提示词

> **Dashboard**: DCom Performance Media Dashboard  
> **Tab**: KPI Progress  
> **数据底表**: `a05_e2e_paid_media_summary_d`  
> **模块说明**: 本板块为 KPI 进度看板，覆盖 KPIs、Performance Indicators、New Acquisition KPI Trend、Category Growth KPI Trend、KPI by Platform 五个子板块，统计媒体花费、销售达成、新客获取、第二品类增长及分平台表现。

---

## 全局逻辑

| 项目 | 内容 |
|---|---|
| **数据底表** | `a05_e2e_paid_media_summary_d` |
| **page_type 筛选** | 本板块统一 `page_type=1` |
| **customer_type 筛选** | 按指标定义区分 `ALL` / `NEW` |
| **分子/分母标记** | Excel 中以 `└ 分子` / `└ 分母` 行标注派生指标的分子分母取数，本文件在各指标中合并展示 |
| **派生指标** | Cost ACH%、Cost vs SLS ACH%、Media Contribution to New Customer Acquisition%、Cost Per New Acquisition、± Acceleration cost MOB% vs. store SLS MOB% 等为派生指标，本身无独立统计字段，依据其分子/分母行取数计算 |
| **必须遵守** | 口径文档中定义的所有指标，必须遵守其数据类型和数据格式，如果和解决方案中存在争议的，一切以口径文档为准，必须按照口径文档中的格式进行调整 |

---

## 子模块一：KPIs

### 1. Media Cost Rate — 媒体花费占比

| 项目 | 内容 |
|---|---|
| **指标名称** | Media Cost Rate / 媒体花费占比 |
| **业务定义** | 实际总媒体花费占比退后金额的百分比 |
| **计算公式** | Cost / Net Sales × 1.13 / 1.06 |
| **分子** | `cost_amt（含红包/返佣返货金）` |
| **分母** | `net_sales_amt` |
| **数据底表** | `a05_e2e_paid_media_summary_d` |
| **筛选条件** | `customer_type='ALL' AND page_type=1` |

---

### 2. Media Cost — 媒体花费

| 项目 | 内容 |
|---|---|
| **指标名称** | Media Cost / 媒体花费 |
| **业务定义** | 实际媒体花费（绝对值） |
| **计算公式** | 同 Cost（实际媒体花费） |
| **统计字段** | `cost_amt（含红包/返佣返货金）` |
| **数据底表** | `a05_e2e_paid_media_summary_d` |
| **筛选条件** | `customer_type='ALL' AND page_type=1` |

---

### 3. Cost ACH% — 花费进度达成

| 项目 | 内容 |
|---|---|
| **指标名称** | Cost ACH% / 花费进度达成 |
| **业务定义** | 目标花费进度达成 |
| **计算公式** | 实际花费 / 计划花费 |
| **统计字段** | `cost_amt / fcst_cost_amt` |
| **数据底表** | `a05_e2e_paid_media_summary_d` |
| **筛选条件** | `customer_type='ALL' AND page_type=1` |

---

### 4. Cost vs SLS ACH% — 花费vs销售达成

| 项目 | 内容 |
|---|---|
| **指标名称** | Cost vs SLS ACH% / 花费vs销售达成 |
| **业务定义** | 花费进度达成 vs 销售进度达成差异 |
| **计算公式** | Cost ACH% − SLS ACH% |
| **数据底表** | —（派生指标） |
| **筛选条件** | 派生：Cost ACH% − SLS ACH%，无独立底表取数，根据 Cost ACH% 行和 SLS ACH% 行生成 |

---

### 5. SLS ACH% — 目标达成率

| 项目 | 内容 |
|---|---|
| **指标名称** | SLS ACH% / 目标达成率 |
| **业务定义** | 退后销售额目标达成率 |
| **计算公式** | 实际退后金额 / 计划退后金额（运营也许会直接提供一个百分比的数值，待定） |
| **统计字段** | `net_sales_amt / fcst_net_sales_amt` |
| **数据底表** | `a05_e2e_paid_media_summary_d` |
| **筛选条件** | `customer_type='ALL' AND page_type=1` |

---

### 6. SLS DCom — 退后销售额

| 项目 | 内容 |
|---|---|
| **指标名称** | SLS DCom / 退后销售额 |
| **业务定义** | 退后销售额 |
| **计算公式** | net_sales_amt 加总 |
| **统计字段** | `net_sales_amt` |
| **数据底表** | `a05_e2e_paid_media_summary_d` |
| **筛选条件** | `customer_type='ALL' AND page_type=1` |

---

### 7. Media Contribution to New Customer Acquisition% — 媒体新客贡献率

| 项目 | 内容 |
|---|---|
| **指标名称** | Media Contribution to New Customer Acquisition% / 媒体新客贡献率 |
| **业务定义** | 媒体新客贡献率 |
| **计算公式** | 媒体新客数 / 全店新客数 |
| **分子** | `media_member_cnt`（媒体新客数 media_new_customer_no） |
| **分母** | `member_cnt`（全店新客数） |
| **数据底表** | `a05_e2e_paid_media_summary_d` |
| **筛选条件** | `customer_type='NEW' AND page_type=1` |

---

### 8. Cost Per New Acquisition — 媒体新客获客成本

| 项目 | 内容 |
|---|---|
| **指标名称** | Cost Per New Acquisition / 媒体新客获客成本 |
| **业务定义** | 总新客花费 / 总媒体新客的数量 |
| **计算公式** | 新客花费 / 媒体新客数 |
| **分子** | `media_cost_amt`（新客花费 media_new_cost） |
| **分母** | `media_member_cnt`（媒体新客数 media_new_customer_no） |
| **数据底表** | `a05_e2e_paid_media_summary_d` |
| **筛选条件** | `customer_type='NEW' AND page_type=1` |

---

### 9. ± Acceleration cost MOB% vs. store SLS MOB% — 第二品类花费MOB%vs门店销售MOB%

| 项目 | 内容 |
|---|---|
| **指标名称** | ± Acceleration cost MOB% vs. store SLS MOB% / 第二品类花费MOB%vs门店销售MOB% |
| **业务定义** | 第二品类花费占比 vs 门店销售占比 |
| **计算公式** | Acceleration Cost MOB% − Store SLS MOB%（×100 转为 bp） |
| **数据底表** | —（派生指标） |
| **筛选条件** | 派生：Acceleration Cost MOB% − Store SLS MOB%（×100→bp），无独立底表取数 |

---

## 子模块二：Performance Indicators

### 10. New Customer No — 新客数量

| 项目 | 内容 |
|---|---|
| **指标名称** | New Customer No / 新客数量 |
| **业务定义** | 店铺新客数 |
| **计算公式** | COUNT DISTINCT 买家id（全店新客） |
| **统计字段** | `member_cnt` |
| **数据底表** | `a05_e2e_paid_media_summary_d` |
| **筛选条件** | `customer_type='NEW' AND page_type=1` |

---

### 11. Acceleration SLS — 第二品类退后销售额

| 项目 | 内容 |
|---|---|
| **指标名称** | Acceleration SLS / 第二品类退后销售额 |
| **业务定义** | 第二品类退后销售额 |
| **计算公式** | Net Sales（framework='Acceleration'） |
| **统计字段** | `net_sales_amt` |
| **数据底表** | `a05_e2e_paid_media_summary_d` |
| **筛选条件** | `customer_type='ALL' AND framework='Acceleration' AND page_type=1` |

---

### 12. Acceleration SLS MOB% — 第二品类退后销售额MOB%

| 项目 | 内容 |
|---|---|
| **指标名称** | Acceleration SLS MOB% / 第二品类退后销售额MOB% |
| **业务定义** | 第二品类退后销售额占比 |
| **计算公式** | Acceleration SLS / TTL SLS |
| **分子** | `net_sales_amt`（Acceleration 退后销售额） |
| **分母** | `net_sales_amt`（全店 TTL 退后销售额，全部 framework） |
| **数据底表** | `a05_e2e_paid_media_summary_d` |
| **筛选条件** | 分子：`customer_type='ALL' AND framework='Acceleration' AND page_type=1`；分母：`customer_type='ALL' AND page_type=1` |

---

## 子模块三：New Acquisition KPI Trend

### 13. New Customer No. — 新客数量（趋势）

| 项目 | 内容 |
|---|---|
| **指标名称** | New Customer No. / 新客数量 |
| **业务定义** | 新客数量趋势 |
| **计算公式** | COUNT DISTINCT 买家id（新客趋势） |
| **统计字段** | `member_cnt` |
| **数据底表** | `a05_e2e_paid_media_summary_d` |
| **筛选条件** | `customer_type='NEW' AND page_type=1` |

---

### 14. New Customer% — 新客占比（趋势）

| 项目 | 内容 |
|---|---|
| **指标名称** | New Customer% / 新客占比 |
| **业务定义** | 新客占比趋势 |
| **计算公式** | New Customer No / TTL Buyers |
| **分子** | `member_cnt`（new） |
| **分母** | `member_cnt`（all） |
| **数据底表** | `a05_e2e_paid_media_summary_d` |
| **筛选条件** | 分子 `customer_type='NEW'`；分母 `customer_type='ALL' AND page_type=1` |

---

### 15. Media Contribution to New Customer Acquisition% — 媒体新客贡献率（趋势）

| 项目 | 内容 |
|---|---|
| **指标名称** | Media Contribution to New Customer Acquisition% / 媒体新客贡献率 |
| **业务定义** | 新客贡献率趋势 |
| **计算公式** | 媒体新客数 / 全店新客数（趋势图） |
| **统计字段** | `media_member_cnt（new）/ member_cnt（new）` |
| **数据底表** | `a05_e2e_paid_media_summary_d` |
| **筛选条件** | `customer_type='NEW' AND page_type=1` |

---

## 子模块四：Category Growth KPI Trend

### 16. Acceleration SLS — 第二品类退后销售额（趋势）

| 项目 | 内容 |
|---|---|
| **指标名称** | Acceleration SLS / 第二品类退后销售额 |
| **业务定义** | 第二品类退后销售额趋势 |
| **计算公式** | Net Sales（framework='Acceleration'，趋势图） |
| **统计字段** | `net_sales_amt` |
| **数据底表** | `a05_e2e_paid_media_summary_d` |
| **筛选条件** | `customer_type='ALL' AND framework='Acceleration' AND page_type=1` |

---

### 17. Acceleration SLS MOB% — 第二品类退后销售额MOB%（趋势）

| 项目 | 内容 |
|---|---|
| **指标名称** | Acceleration SLS MOB% / 第二品类退后销售额MOB% |
| **业务定义** | 第二品类退后销售额 MOB% 趋势 |
| **计算公式** | Acceleration SLS / TTL SLS（趋势图） |
| **统计字段** | `net_sales_amt（framework='Acceleration'）/ net_sales_amt（全部 framework）` |
| **数据底表** | `a05_e2e_paid_media_summary_d` |
| **筛选条件** | `customer_type='ALL' AND page_type=1` |

---

### 18. Acceleration Cost MOB% — 第二品类花费MOB%（趋势）

| 项目 | 内容 |
|---|---|
| **指标名称** | Acceleration Cost MOB% / 第二品类花费MOB% |
| **业务定义** | 第二品类花费 MOB% 趋势 |
| **计算公式** | Acceleration Cost / TTL Cost（趋势图） |
| **统计字段** | `cost_amt（framework='Acceleration'）/ cost_amt（全部 framework）` |
| **数据底表** | `a05_e2e_paid_media_summary_d` |
| **筛选条件** | `customer_type='ALL' AND page_type=1` |

---

## 子模块五：KPI by Platform

> **分组维度**: 按 `platform` 分组

### 19. Media Cost Rate — 费比（分平台）

| 项目 | 内容 |
|---|---|
| **指标名称** | Media Cost Rate / 费比 |
| **业务定义** | 各平台费比 |
| **计算公式** | Cost / SLS |
| **统计字段** | `cost_amt / net_sales_amt` |
| **数据底表** | `a05_e2e_paid_media_summary_d` |
| **筛选条件** | `customer_type='ALL' AND page_type=1`，按 platform 分组 |

---

### 20. Media Cost — 媒体花费（分平台）

| 项目 | 内容 |
|---|---|
| **指标名称** | Media Cost / 媒体花费 |
| **业务定义** | 各平台实际媒体花费 |
| **计算公式** | 同 Cost（实际媒体花费），按 platform 分组 |
| **统计字段** | `cost_amt` |
| **数据底表** | `a05_e2e_paid_media_summary_d` |
| **筛选条件** | `customer_type='ALL' AND page_type=1`，按 platform 分组 |

---

### 21. ± Acceleration cost MOB% vs. store SLS MOB% — 第二品类花费MOB%vs门店销售MOB%（分平台）

| 项目 | 内容 |
|---|---|
| **指标名称** | ± Acceleration cost MOB% vs. store SLS MOB% / 第二品类花费MOB%vs门店销售MOB% |
| **业务定义** | 各平台第二品类花费 MOB% vs 门店销售 MOB% |
| **计算公式** | Acceleration Cost MOB% − Store SLS MOB%（by platform，bp） |
| **数据底表** | —（派生指标） |
| **筛选条件** | 派生：Acceleration Cost MOB% − Store SLS MOB%（按 platform，bp），无独立底表取数 |

---

### 22. Media Contribution to New Customer Acquisition% — 媒体新客贡献率（分平台）

| 项目 | 内容 |
|---|---|
| **指标名称** | Media Contribution to New Customer Acquisition% / 媒体新客贡献率 |
| **业务定义** | 各平台媒体新客贡献率 |
| **计算公式** | 媒体新客数 / 全店新客数（by platform） |
| **统计字段** | `media_member_cnt（new）/ member_cnt（new）` |
| **数据底表** | `a05_e2e_paid_media_summary_d` |
| **筛选条件** | `customer_type='NEW' AND page_type=1`，按 platform 分组 |

---

### 23. Media Cost Per New Acquisition — 媒体新客获客成本（分平台）

| 项目 | 内容 |
|---|---|
| **指标名称** | Media Cost Per New Acquisition / 媒体新客获客成本 |
| **业务定义** | 各平台媒体新客获客成本 |
| **计算公式** | 新客花费 / 媒体新客数（by platform） |
| **分子** | `media_cost_amt`（新客花费 media_new_cost） |
| **分母** | `media_member_cnt`（媒体新客数 media_new_customer_no） |
| **数据底表** | `a05_e2e_paid_media_summary_d` |
| **筛选条件** | `customer_type='NEW' AND page_type=1`，按 platform 分组 |

---

## 通用规则汇总

| 规则项 | 说明 |
|---|---|
| **数据底表** | 全部指标统一使用 `a05_e2e_paid_media_summary_d` |
| **page_type** | 本板块统一 `page_type=1` |
| **customer_type** | 按指标区分 `ALL`（全客）或 `NEW`（新客） |
| **派生指标** | Cost vs SLS ACH%、± Acceleration cost MOB% vs. store SLS MOB% 为派生差值，无独立底表取数 |
| **分平台维度** | 子模块五 KPI by Platform 按 `platform` 字段分组 |
| **framework 筛选** | 第二品类（Acceleration）相关指标需叠加 `framework='Acceleration'` 筛选 |
| **必须遵守** | 口径文档中定义的所有指标，必须遵守其数据类型和数据格式，如果和解决方案中存在争议的，一切以口径文档为准，必须按照口径文档中的格式进行调整 |
| **DAX 语法规范** | 文本常量必须使用双引号 `" "`，禁止使用单引号；单引号 `' '` 仅用于表名，列名使用方括号 `[ ]`，例如：`[framework] = "Acceleration"` |
