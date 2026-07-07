# New Acquisition 指标口径提示词

> **Dashboard**: DCom Performance Media Dashboard  
> **Tab**: New Acquisition  
> **数据底表**: `a05_e2e_paid_media_summary_d` / `a05_e2e_paid_media_crowed_data_d` / `a05_e2e_paid_media_keyword_data_d`  
> **模块说明**: 本板块聚焦新客获取，覆盖 KPIs、Ads Format Cost%、Controllable Ads Format Cost% Trend、Controllable Ads format breakdown 四个子板块，统计新客贡献率、获客成本、可控/不可控花费占比及渠道下钻层级指标。

---

## 全局逻辑

| 项目 | 内容 |
|---|---|
| **数据底表** | 汇总指标使用 `a05_e2e_paid_media_summary_d`；引力魔方 TA 下钻使用 `a05_e2e_paid_media_crowed_data_d`；直通车关键词/计划下钻使用 `a05_e2e_paid_media_keyword_data_d` |
| **page_type 筛选** | 本板块统一 `page_type=1` |
| **customer_type 筛选** | 按指标区分 `ALL`（全客）或 `NEW`（新客） |
| **分子/分母标记** | Excel 中以 `└ 分子` / `└ 分母` 行标注派生指标的分子分母取数，本文件在各指标中合并展示 |
| **派生指标** | Media Contribution to New Customer Acquisition%、Cost per new acquisition、Cost% 系列均为派生比率指标，本身无独立统计字段，依据其分子/分母行取数计算 |
| **必须遵守** | 口径文档中定义的所有指标，必须遵守其数据类型和数据格式，如果和解决方案中存在争议的，一切以口径文档为准，必须按照口径文档中的格式进行调整 |

---

## 子模块一：KPIs

### 1. Media Contribution to New Customer Acquisition% — 媒体新客贡献率

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

### 2. Cost per new acquisition — 媒体新客获客成本

| 项目 | 内容 |
|---|---|
| **指标名称** | Cost per new acquisition / 媒体新客获客成本 |
| **业务定义** | 总新客花费 / 总媒体新客的数量 |
| **计算公式** | 新客花费 / 媒体新客数 |
| **分子** | `media_cost_amt`（新客花费 media_new_cost） |
| **分母** | `media_member_cnt`（媒体新客数 media_new_customer_no） |
| **数据底表** | `a05_e2e_paid_media_summary_d` |
| **筛选条件** | `customer_type='NEW' AND page_type=1` |

---

## 子模块二：Ads Format Cost%

### 3. 直通车 Cost% — 直通车花费占比

| 项目 | 内容 |
|---|---|
| **指标名称** | 直通车 Cost% / 直通车花费占比 |
| **业务定义** | 直通车花费占比（可控广告） |
| **计算公式** | 直通车 Cost / TTL Cost |
| **分子** | `cost_amt`（直通车花费） |
| **分母** | `cost_amt`（所有点位 TTL 花费，所有 channel） |
| **数据底表** | `a05_e2e_paid_media_summary_d` |
| **筛选条件** | 分子：`customer_type='ALL' AND channel='直通车' AND page_type=1`；分母：`customer_type='ALL' AND page_type=1` |

---

### 4. 引力魔方 Cost% — 引力魔方花费占比

| 项目 | 内容 |
|---|---|
| **指标名称** | 引力魔方 Cost% / 引力魔方花费占比 |
| **业务定义** | 引力魔方花费占比（可控广告） |
| **计算公式** | 引力魔方 Cost / TTL Cost |
| **分子** | `cost_amt`（引力魔方花费） |
| **分母** | `cost_amt`（所有点位 TTL 花费，所有 channel） |
| **数据底表** | `a05_e2e_paid_media_summary_d` |
| **筛选条件** | 分子：`customer_type='ALL' AND channel='引力魔方' AND page_type=1`；分母：`customer_type='ALL' AND page_type=1` |

---

### 5. Uncontrollable Ads Format Cost% — 不可控广告花费占比

| 项目 | 内容 |
|---|---|
| **指标名称** | Uncontrollable Ads Format Cost% / 不可控广告花费占比 |
| **业务定义** | 不可控广告花费占比 |
| **计算公式** | 不可控广告 Cost / TTL Cost |
| **分子** | `cost_amt`（不可控广告花费，JCGP + 品专 + 明星 + 超级直播） |
| **分母** | `cost_amt`（所有点位 TTL 花费，所有 channel） |
| **数据底表** | `a05_e2e_paid_media_summary_d` |
| **筛选条件** | 分子：`customer_type='ALL' AND is_controllable_channel=0 AND page_type=1`；分母：`customer_type='ALL' AND page_type=1` |

---

## 子模块三：Controllable Ads Format Cost% Trend

### 6. Controllable% — 可控花费占比（趋势）

| 项目 | 内容 |
|---|---|
| **指标名称** | Controllable% / 可控花费占比 |
| **业务定义** | 可控广告花费占比趋势 |
| **计算公式** | 可控广告 Cost / TTL Cost（趋势） |
| **分子** | `cost_amt`（可控广告花费，直通车 + 引力魔方） |
| **分母** | `cost_amt`（所有点位 TTL 花费，所有 channel） |
| **数据底表** | `a05_e2e_paid_media_summary_d` |
| **筛选条件** | 分子：`customer_type='ALL' AND is_controllable_channel=1 AND page_type=1`；分母：`customer_type='ALL' AND page_type=1` |

---

### 7. Uncontrollable% — 不可控花费占比（趋势）

| 项目 | 内容 |
|---|---|
| **指标名称** | Uncontrollable% / 不可控花费占比 |
| **业务定义** | 不可控广告花费占比趋势 |
| **计算公式** | 不可控广告 Cost / TTL Cost（趋势） |
| **分子** | `cost_amt`（不可控广告花费） |
| **分母** | `cost_amt`（所有点位 TTL 花费，所有 channel） |
| **数据底表** | `a05_e2e_paid_media_summary_d` |
| **筛选条件** | 分子：`customer_type='ALL' AND is_controllable_channel=0 AND page_type=1`；分母：`customer_type='ALL' AND page_type=1` |

---

### 8. Controllable Cost — 可控花费（趋势）

| 项目 | 内容 |
|---|---|
| **指标名称** | Controllable Cost / 可控花费 |
| **业务定义** | 可控广告花费趋势 |
| **计算公式** | 可控广告花费（绝对金额，趋势） |
| **统计字段** | `cost_amt` |
| **数据底表** | `a05_e2e_paid_media_summary_d` |
| **筛选条件** | `customer_type='ALL' AND is_controllable_channel=1 AND page_type=1` |

---

### 9. Uncontrollable Cost — 不可控花费（趋势）

| 项目 | 内容 |
|---|---|
| **指标名称** | Uncontrollable Cost / 不可控花费 |
| **业务定义** | 不可控广告花费趋势 |
| **计算公式** | 不可控广告花费（绝对金额，趋势） |
| **统计字段** | `cost_amt` |
| **数据底表** | `a05_e2e_paid_media_summary_d` |
| **筛选条件** | `customer_type='ALL' AND is_controllable_channel=0 AND page_type=1` |

---

## 子模块四：Controllable Ads format breakdown: 引力魔方

> **数据底表**: `a05_e2e_paid_media_crowed_data_d`  
> **分组维度**: 按 TA 层级（`crowed_layer` / `crowed_type` / `crowed_name`）分组  
> **筛选条件**: `channel='引力魔方'`

### 10. Cost — 花费（引力魔方 TA 层级）

| 项目 | 内容 |
|---|---|
| **指标名称** | Cost / 花费 |
| **业务定义** | 引力魔方 TA/新老/OAIPL 层级花费 |
| **计算公式** | 引力魔方各 TA 层级花费 |
| **统计字段** | `cost_amt` |
| **数据底表** | `a05_e2e_paid_media_crowed_data_d` |
| **筛选条件** | `channel='引力魔方'`，按 TA 层级（crowed_layer/crowed_type/crowed_name）分组 |

---

### 11. Cost% — 花费占比（引力魔方 TA 层级）

| 项目 | 内容 |
|---|---|
| **指标名称** | Cost% / 花费占比 |
| **业务定义** | 引力魔方 TA/新老/OAIPL 层级花费占比 |
| **计算公式** | TA 层级引力魔方 Cost / TTL Cost |
| **分子** | `cost_amt`（该 TA 层级） |
| **分母** | `cost_amt`（该广告点位 TA 合计） |
| **数据底表** | `a05_e2e_paid_media_crowed_data_d` |
| **筛选条件** | `channel='引力魔方'` |

---

### 12. ROI — ROI（引力魔方 TA 层级）

| 项目 | 内容 |
|---|---|
| **指标名称** | ROI / ROI |
| **业务定义** | 引力魔方 TA/新老/OAIPL 层级 ROI |
| **计算公式** | 引力魔方 TA 层级 Sales / Cost |
| **分子** | `media_sales_amt`（引力魔方 TA 层级成交金额） |
| **分母** | `cost_amt`（引力魔方 TA 层级花费） |
| **数据底表** | `a05_e2e_paid_media_crowed_data_d` |
| **筛选条件** | `channel='引力魔方'` |

---

## 子模块五：Controllable Ads format breakdown: 直通车

> **数据底表**: `a05_e2e_paid_media_keyword_data_d`  
> **分组维度**: 按 Category / 计划 / 关键词 分组  
> **筛选条件**: `channel='直通车'`

### 13. Cost — 花费（直通车关键词/计划层级）

| 项目 | 内容 |
|---|---|
| **指标名称** | Cost / 花费 |
| **业务定义** | 直通车新老/计划层级花费 |
| **计算公式** | 直通车各关键词/计划层级花费 |
| **统计字段** | `cost_amt` |
| **数据底表** | `a05_e2e_paid_media_keyword_data_d` |
| **筛选条件** | `channel='直通车'`，按 Category/计划/关键词 分组 |

---

### 14. Cost% — 花费占比（直通车关键词/计划层级）

| 项目 | 内容 |
|---|---|
| **指标名称** | Cost% / 花费占比 |
| **业务定义** | 直通车新老/计划层级花费占比 |
| **计算公式** | 关键词/计划层级 Cost / TTL Cost |
| **分子** | `cost_amt`（该 关键词/计划 层级） |
| **分母** | `cost_amt`（该广告点位合计） |
| **数据底表** | `a05_e2e_paid_media_keyword_data_d` |
| **筛选条件** | `channel='直通车'` |

---

### 15. ROI — ROI（直通车关键词/计划层级）

| 项目 | 内容 |
|---|---|
| **指标名称** | ROI / ROI |
| **业务定义** | 直通车新老/计划层级 ROI |
| **计算公式** | 直通车关键词层级 Sales / Cost |
| **分子** | `media_sales_amt`（直通车关键词层级成交金额） |
| **分母** | `cost_amt`（直通车关键词层级花费） |
| **数据底表** | `a05_e2e_paid_media_keyword_data_d` |
| **筛选条件** | `channel='直通车'` |

---

## 通用规则汇总

| 规则项 | 说明 |
|---|---|
| **数据底表** | 汇总指标用 `a05_e2e_paid_media_summary_d`；引力魔方 TA 下钻用 `a05_e2e_paid_media_crowed_data_d`；直通车关键词/计划下钻用 `a05_e2e_paid_media_keyword_data_d` |
| **page_type** | 本板块统一 `page_type=1`（仅汇总表；下钻表无 page_type 筛选） |
| **可控/不可控** | 通过 `is_controllable_channel` 区分（1=可控，0=不可控）；可控广告 = 直通车 + 引力魔方，不可控广告 = JCGP + 品专 + 明星 + 超级直播 |
| **派生指标** | Media Contribution to New Customer Acquisition%、Cost per new acquisition、Cost% 系列为派生比率指标，需分子分母分别计算后再相除 |
| **下钻分组维度** | 引力魔方按 TA 层级（crowed_layer/crowed_type/crowed_name）；直通车按 Category/计划/关键词 |
| **必须遵守** | 口径文档中定义的所有指标，必须遵守其数据类型和数据格式，如果和解决方案中存在争议的，一切以口径文档为准，必须按照口径文档中的格式进行调整 |
| **DAX 语法规范** | 文本常量必须使用双引号 `" "`，禁止使用单引号；单引号 `' '` 仅用于表名，列名使用方括号 `[ ]`，例如：`[channel] = "引力魔方"`、`[is_controllable_channel] = 1` |
