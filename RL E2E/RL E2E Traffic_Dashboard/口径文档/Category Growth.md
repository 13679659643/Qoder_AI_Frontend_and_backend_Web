# Category Growth 指标口径提示词

> **Dashboard**: DCom Performance Media Dashboard  
> **Tab**: Category Growth  
> **板块名称**: KPI Breakdown  
> **数据底表**: `a05_e2e_paid_media_summary_d`  
> **模块说明**: 本板块为 KPI 分解矩阵，按 brand/category 分组，统计花费占比、销售占比、ROI、新客花费占比等指标，并按渠道（直通车/引力魔方/全站推）拆分。

---

## 全局逻辑

| 项目 | 内容 |
|---|---|
| **数据底表** | `a05_e2e_paid_media_summary_d` |
| **page_type 筛选** | 本板块统一 `page_type=2` |
| **customer_type 筛选** | 按指标区分 `ALL`（全客）或 `NEW`（新客） |
| **分组维度** | 按 `brand` / `category` 分组 |
| **分子/分母标记** | Excel 中以 `└ 分子` / `└ 分母` 行标注派生指标的分子分母取数，本文件在各指标中合并展示 |
| **派生指标** | Cost% vs SLS%、Cost MOB% 系列、ROI 系列、New Customer Cost% 系列均为派生比率指标，本身无独立统计字段，依据其分子/分母行取数计算 |
| **必须遵守** | 口径文档中定义的所有指标，必须遵守其数据类型和数据格式，如果和解决方案中存在争议的，一切以口径文档为准，必须按照口径文档中的格式进行调整 |

---

## 1. Cost% vs SLS% — 花费%vs销售%

| 项目 | 内容 |
|---|---|
| **指标名称** | Cost% vs SLS% / 花费%vs销售% |
| **业务定义** | 花费占比 vs 销售占比差异（pt） |
| **计算公式** | Cost MOB% − Net Sales%（差值，单位 pt） |
| **数据底表** | —（派生指标） |
| **筛选条件** | 派生：Cost MOB% − Net Sales%（pt），无独立底表取数 |

---

## 2. SLS% — 退后销售额占比

| 项目 | 内容 |
|---|---|
| **指标名称** | SLS% / 退后销售额占比 |
| **业务定义** | 退后销售额占比 |
| **计算公式** | 品类 Net Sales / TTL Net Sales |
| **分子** | `net_sales_amt`（该 brand/category） |
| **分母** | `net_sales_amt`（全店 TTL） |
| **数据底表** | `a05_e2e_paid_media_summary_d` |
| **筛选条件** | `customer_type='ALL' AND page_type=2`，按 brand/category 分组 |

---

## 3. Cost MOB% Total — 花费MOB%合计

| 项目 | 内容 |
|---|---|
| **指标名称** | Cost MOB% Total / 花费MOB%合计 |
| **业务定义** | 花费占比 |
| **计算公式** | 所有点位 Cost / TTL Cost |
| **分子** | `cost_amt`（该 brand/category，所有 channel） |
| **分母** | `cost_amt`（全店 TTL，所有 channel） |
| **数据底表** | `a05_e2e_paid_media_summary_d` |
| **筛选条件** | `customer_type='ALL' AND page_type=2` |

---

## 4. Cost MOB% 直通车 — 花费MOB%直通车

| 项目 | 内容 |
|---|---|
| **指标名称** | Cost MOB% 直通车 / 花费MOB%直通车 |
| **业务定义** | 直通车花费占比 |
| **计算公式** | 直通车 Cost / TTL Cost |
| **分子** | `cost_amt`（直通车花费） |
| **分母** | `cost_amt`（所有点位 TTL 花费，所有 channel） |
| **数据底表** | `a05_e2e_paid_media_summary_d` |
| **筛选条件** | 分子：`customer_type='ALL' AND channel='直通车' AND page_type=2`；分母：`customer_type='ALL' AND page_type=2` |

---

## 5. Cost MOB% 引力魔方 — 花费MOB%引力魔方

| 项目 | 内容 |
|---|---|
| **指标名称** | Cost MOB% 引力魔方 / 花费MOB%引力魔方 |
| **业务定义** | 引力魔方花费占比 |
| **计算公式** | 引力魔方 Cost / TTL Cost |
| **分子** | `cost_amt`（引力魔方花费） |
| **分母** | `cost_amt`（所有点位 TTL 花费，所有 channel） |
| **数据底表** | `a05_e2e_paid_media_summary_d` |
| **筛选条件** | 分子：`customer_type='ALL' AND channel='引力魔方' AND page_type=2`；分母：`customer_type='ALL' AND page_type=2` |

---

## 6. Cost MOB% 全站推 — 花费MOB%全站推

| 项目 | 内容 |
|---|---|
| **指标名称** | Cost MOB% 全站推 / 花费MOB%全站推 |
| **业务定义** | 全站推花费占比 |
| **计算公式** | 全站推 Cost / TTL Cost |
| **分子** | `cost_amt`（全站推花费） |
| **分母** | `cost_amt`（所有点位 TTL 花费，所有 channel） |
| **数据底表** | `a05_e2e_paid_media_summary_d` |
| **筛选条件** | 分子：`customer_type='ALL' AND channel='全站推' AND page_type=2`；分母：`customer_type='ALL' AND page_type=2` |

---

## 7. ROI Total — ROI合计

| 项目 | 内容 |
|---|---|
| **指标名称** | ROI Total / ROI合计 |
| **业务定义** | 媒体 ROI 合计 |
| **计算公式** | 所有点位 Sales / 所有点位 Cost |
| **分子** | `media_sales_amt`（成交金额，投放带来，所有 channel） |
| **分母** | `cost_amt`（所有点位 TTL 花费，所有 channel） |
| **数据底表** | `a05_e2e_paid_media_summary_d` |
| **筛选条件** | `customer_type='ALL' AND page_type=2` |

---

## 8. ROI 直通车 — ROI直通车

| 项目 | 内容 |
|---|---|
| **指标名称** | ROI 直通车 / ROI直通车 |
| **业务定义** | 直通车 ROI |
| **计算公式** | 直通车 Sales / Cost |
| **分子** | `media_sales_amt`（直通车成交金额） |
| **分母** | `cost_amt`（直通车花费） |
| **数据底表** | `a05_e2e_paid_media_summary_d` |
| **筛选条件** | `customer_type='ALL' AND channel='直通车' AND page_type=2` |

---

## 9. ROI 引力魔方 — ROI引力魔方

| 项目 | 内容 |
|---|---|
| **指标名称** | ROI 引力魔方 / ROI引力魔方 |
| **业务定义** | 引力魔方 ROI |
| **计算公式** | 引力魔方 Sales / Cost |
| **分子** | `media_sales_amt`（引力魔方成交金额） |
| **分母** | `cost_amt`（引力魔方花费） |
| **数据底表** | `a05_e2e_paid_media_summary_d` |
| **筛选条件** | `customer_type='ALL' AND channel='引力魔方' AND page_type=2` |

---

## 10. ROI 全站推 — ROI全站推

| 项目 | 内容 |
|---|---|
| **指标名称** | ROI 全站推 / ROI全站推 |
| **业务定义** | 全站推 ROI |
| **计算公式** | 全站推 Sales / Cost |
| **分子** | `media_sales_amt`（全站推成交金额） |
| **分母** | `cost_amt`（全站推花费） |
| **数据底表** | `a05_e2e_paid_media_summary_d` |
| **筛选条件** | `customer_type='ALL' AND channel='全站推' AND page_type=2` |

---

## 11. New Customer Cost% Total — 新客花费占比合计

| 项目 | 内容 |
|---|---|
| **指标名称** | New Customer Cost% Total / 新客花费占比合计 |
| **业务定义** | 新客花费占比合计 |
| **计算公式** | 所有点位新客 Cost / TTL Cost |
| **分子** | `cost_amt`（新客花费 New Cost） |
| **分母** | `cost_amt`（新客花费 + 老客花费，New + Existing Cost） |
| **数据底表** | `a05_e2e_paid_media_summary_d` |
| **筛选条件** | 分子：`customer_type='NEW' AND page_type=2`；分母：`customer_type in ('NEW','EXISTING') AND page_type=2` |

---

## 12. New Customer Cost% 直通车 — 新客花费占比直通车

| 项目 | 内容 |
|---|---|
| **指标名称** | New Customer Cost% 直通车 / 新客花费占比直通车 |
| **业务定义** | 直通车新客花费占比 |
| **计算公式** | 直通车新客 Cost / (New Cost + Existing Cost) |
| **分子** | `cost_amt`（直通车新客花费） |
| **分母** | `cost_amt`（直通车新客 + 老客花费） |
| **数据底表** | `a05_e2e_paid_media_summary_d` |
| **筛选条件** | 分子：`customer_type='NEW' AND channel='直通车' AND page_type=2`；分母：`customer_type in ('NEW','EXISTING') AND channel='直通车' AND page_type=2` |

---

## 13. New Customer Cost% 引力魔方 — 新客花费占比引力魔方

| 项目 | 内容 |
|---|---|
| **指标名称** | New Customer Cost% 引力魔方 / 新客花费占比引力魔方 |
| **业务定义** | 引力魔方新客花费占比 |
| **计算公式** | 引力魔方新客 Cost / (New Cost + Existing Cost) |
| **分子** | `cost_amt`（引力魔方新客花费） |
| **分母** | `cost_amt`（引力魔方新客 + 老客花费） |
| **数据底表** | `a05_e2e_paid_media_summary_d` |
| **筛选条件** | 分子：`customer_type='NEW' AND channel='引力魔方' AND page_type=2`；分母：`customer_type in ('NEW','EXISTING') AND channel='引力魔方' AND page_type=2` |

---

## 14. New Customer Cost% 全站推 — 新客花费占比全站推

| 项目 | 内容 |
|---|---|
| **指标名称** | New Customer Cost% 全站推 / 新客花费占比全站推 |
| **业务定义** | - |
| **计算公式** | - |
| **数据底表** | — |
| **筛选条件** | 全站推不区分新老客，无数据 |

---

## 通用规则汇总

| 规则项 | 说明 |
|---|---|
| **数据底表** | 全部指标统一使用 `a05_e2e_paid_media_summary_d` |
| **page_type** | 本板块统一 `page_type=2` |
| **分组维度** | 按 `brand` / `category` 分组 |
| **渠道拆分** | Cost MOB%、ROI、New Customer Cost% 均按 channel（直通车/引力魔方/全站推）拆分 Total + 三个分渠道指标 |
| **全站推限制** | 全站推不区分新老客，New Customer Cost% 全站推无数据 |
| **派生指标** | Cost% vs SLS%、Cost MOB% 系列、ROI 系列、New Customer Cost% 系列为派生比率指标 |
| **TTL 分母** | 占比类指标的 TTL 分母需移除当前分组维度（brand/category） |
| **必须遵守** | 口径文档中定义的所有指标，必须遵守其数据类型和数据格式，如果和解决方案中存在争议的，一切以口径文档为准，必须按照口径文档中的格式进行调整 |
| **DAX 语法规范** | 文本常量必须使用双引号 `" "`，禁止使用单引号；单引号 `' '` 仅用于表名，列名使用方括号 `[ ]`，例如：`[channel] = "直通车"` |
