# TM Category Growth 指标口径提示词

> **Dashboard**: DCom Performance Media Dashboard  
> **Tab**: Category Growth  
> **板块名称**: KPI Breakdown  
> **数据底表**: `a05_e2e_paid_media_summary_d`  
> **模块说明**: 本板块为 KPI 分解矩阵，按 Brand-Category-Framework排列组合 六种动态行维度 分组，通过Scenario筛选器单选筛选，默认筛选设置为Brand->Category->Framework，统计花费占比、销售占比、ROI、新客花费占比等指标，并按渠道（直通车/引力魔方/全站推）拆分。

---

## 全局逻辑

| 项目 | 内容 |
|---|---|
| **数据底表** | `a05_e2e_paid_media_summary_d` |
| **page_type 筛选** | 本板块统一 `page_type=2`、`Total` = 'Total' |
| **customer_type 筛选** | 按指标区分 `ALL`（全客）或 `NEW`（新客） |
| **分组维度** | 按Brand-Category-Framework排列组合 六种动态行维度 分组 |
| **分子/分母标记** | Excel 中以 `└ 分子` / `└ 分母` 行标注派生指标的分子分母取数，本文件在各指标中合并展示 |
| **派生指标** | Cost% vs SLS%、Cost MOB% 系列、ROI 系列、New Customer Cost% 系列均为派生比率指标，本身无独立统计字段，依据其分子/分母行取数计算 |
| **必须遵守** | 口径文档中定义的所有指标，必须遵守其数据类型和数据格式，如果和解决方案中存在争议的，一切以口径文档为准，必须按照口径文档中的格式进行调整 |

---

## 1. Cost% vs SLS% — 花费%vs销售%

| 项目 | 内容 |
|---|---|
| **指标名称** | Cost% vs SLS% / 花费%vs销售% |
| **业务定义** | 花费占比 vs 销售占比差异（pt） |
| **计算公式** | Cost MOB% * 100 − Net Sales% * 100（差值，单位 pt） |
| **Cost MOB%** | `cost_amt`/`cost_amt`（TTL） * 100 |
| **Net Sales%** | `net_sales_amt`/`net_sales_amt`（TTL） * 100 |
| **数据底表** | `a05_e2e_paid_media_summary_d` |
| **筛选条件** | `customer_type='ALL' AND page_type=2` AND `Total`='Total' |
| **数据类型** | decimal_pt_1 → pt，保留一位小数，不含正号，* 100乘以100的操作可以放在Cell Display中实现 |
| **数据格式** | `#,##0.0pt;-#,##0.0pt;0.0pt` |

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
| **筛选条件** | `customer_type='ALL' AND page_type=2` AND `Total`='Total'，按Brand-Category-Framework排列组合 六种动态行维度 分组 |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%;#,##0.0%;0.0%` |

---

## 3. Cost MOB% Total — 花费MOB%合计

| 项目 | 内容 |
|---|---|
| **指标名称** | Cost MOB% Total / 花费MOB%合计 |
| **业务定义** | 花费占比 |
| **计算公式** | 所有channel Cost / TTL Cost |
| **分子** | `cost_amt`（该Brand-Category-Framework排列组合 六种动态行维度分组下的花费） |
| **分母** | `cost_amt`（ TTL，去除分组行维度下的花费） |
| **数据底表** | `a05_e2e_paid_media_summary_d` |
| **筛选条件** | `customer_type='ALL' AND page_type=2` AND channel in ('直通车','引力魔方','全站推') AND `Total`='Total' |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%;#,##0.0%;0.0%` |

---

## 4. Cost MOB% 直通车 — 花费MOB%直通车

| 项目 | 内容 |
|---|---|
| **指标名称** | Cost MOB% 直通车 / 花费MOB%直通车 |
| **业务定义** | 直通车花费占比 |
| **计算公式** | 直通车 Cost / TTL Cost |
| **分子** | `cost_amt`（维度分组下直通车花费） |
| **分母** | `cost_amt`（去除维度分组下 直通车 TTL 花费） |
| **数据底表** | `a05_e2e_paid_media_summary_d` |
| **筛选条件** | `customer_type='ALL' AND page_type=2` AND channel in ('直通车') AND `Total`='Total' |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%;#,##0.0%;0.0%` |

---

## 5. Cost MOB% 引力魔方 — 花费MOB%引力魔方

| 项目 | 内容 |
|---|---|
| **指标名称** | Cost MOB% 引力魔方 / 花费MOB%引力魔方 |
| **业务定义** | 引力魔方花费占比 |
| **计算公式** | 引力魔方 Cost / TTL Cost |
| **分子** | `cost_amt`（维度分组下引力魔方花费） |
| **分母** | `cost_amt`（去除维度分组下 引力魔方 TTL 花费） |
| **数据底表** | `a05_e2e_paid_media_summary_d` |
| **筛选条件** | `customer_type='ALL' AND page_type=2` AND channel in ('引力魔方') AND `Total`='Total' |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%;#,##0.0%;0.0%` |

---

## 6. Cost MOB% 全站推 — 花费MOB%全站推

| 项目 | 内容 |
|---|---|
| **指标名称** | Cost MOB% 全站推 / 花费MOB%全站推 |
| **业务定义** | 全站推花费占比 |
| **计算公式** | 全站推 Cost / TTL Cost |
| **分子** | `cost_amt`（维度分组下全站推花费） |
| **分母** | `cost_amt`（去除维度分组下 全站推 TTL 花费） |
| **数据底表** | `a05_e2e_paid_media_summary_d` |
| **筛选条件** | `customer_type='ALL' AND page_type=2` AND channel in ('全站推') AND `Total`='Total' |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%;#,##0.0%;0.0%` |

---

## 7. ROI Total — ROI合计

| 项目 | 内容 |
|---|---|
| **指标名称** | ROI Total / ROI合计 |
| **业务定义** | 媒体 ROI 合计 |
| **计算公式** | 所有点位 Sales / 所有点位 Cost |
| **分子** | `media_sales_amt`（该Brand-Category-Framework排列组合 六种动态行维度分组下的成交金额，投放带来的销售额，所有 channel('直通车','引力魔方','全站推')） |
| **分母** | `cost_amt`（该Brand-Category-Framework排列组合 六种动态行维度分组下的 花费，所有 channel('直通车','引力魔方','全站推')） |
| **数据底表** | `a05_e2e_paid_media_summary_d` |
| **筛选条件** | `customer_type='ALL' AND page_type=2` AND channel in ('直通车','引力魔方','全站推') AND `Total`='Total' |
| **数据类型** | decimal_1dp → 数值，保留一位小数 |
| **数据格式** | `#,##0.0` |

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
| **筛选条件** | `customer_type='ALL' AND channel='直通车' AND page_type=2` AND `Total`='Total' |
| **数据类型** | decimal_1dp → 数值，保留一位小数 |
| **数据格式** | `#,##0.0` |



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
| **筛选条件** | `customer_type='ALL' AND channel='引力魔方' AND page_type=2` AND `Total`='Total' |
| **数据类型** | decimal_1dp → 数值，保留一位小数 |
| **数据格式** | `#,##0.0` |



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
| **筛选条件** | `customer_type='ALL' AND channel='全站推' AND page_type=2` AND `Total`='Total' |
| **数据类型** | decimal_1dp → 数值，保留一位小数 |
| **数据格式** | `#,##0.0` |

---

## 11. New Customer Cost% Total — 新客花费占比合计

| 项目 | 内容 |
|---|---|
| **指标名称** | New Customer Cost% Total / 新客花费占比合计 |
| **业务定义** | 新客花费占比合计 |
| **计算公式** | 所有channel新客 Cost / TTL Cost |
| **分子** | `cost_amt`（新客花费 New Cost）该Brand-Category-Framework排列组合 六种动态行维度分组下的成交金额，投放带来的销售额，所有 channel('直通车','引力魔方','全站推') |
| **分母** | `cost_amt`（新客花费 + 老客花费，New + Existing Cost）该Brand-Category-Framework排列组合 六种动态行维度分组下的成交金额，投放带来的销售额，所有 channel('直通车','引力魔方','全站推') |
| **数据底表** | `a05_e2e_paid_media_summary_d` |
| **筛选条件** | 分子：`customer_type='NEW' AND page_type=2`AND`Total`='Total' AND channel in ('直通车','引力魔方','全站推')；分母：`customer_type in ('NEW','EXISTING') AND page_type=2` AND `Total`='Total' AND channel in ('直通车','引力魔方','全站推') |

---

## 12. New Customer Cost% 直通车 — 新客花费占比直通车

| 项目 | 内容 |
|---|---|
| **指标名称** | New Customer Cost% 直通车 / 新客花费占比直通车 |
| **业务定义** | 直通车新客花费占比 |
| **计算公式** | 直通车新客 Cost / (New Cost + Existing Cost) |
| **分子** | `cost_amt`（维度分组下直通车新客花费） |
| **分母** | `cost_amt`（维度分组下 直通车新客 + 老客花费） |
| **数据底表** | `a05_e2e_paid_media_summary_d` |
| **筛选条件** | 分子：`customer_type='NEW' AND channel='直通车' AND page_type=2`AND`Total`='Total'；分母：`customer_type in ('NEW','EXISTING') AND channel='直通车' AND page_type=2`AND`Total`='Total' |
| **数据类型** | decimal_1dp → 数值，保留一位小数 |
| **数据格式** | `#,##0.0` |

---

## 13. New Customer Cost% 引力魔方 — 新客花费占比引力魔方

| 项目 | 内容 |
|---|---|
| **指标名称** | New Customer Cost% 引力魔方 / 新客花费占比引力魔方 |
| **业务定义** | 引力魔方新客花费占比 |
| **计算公式** | 引力魔方新客 Cost / (New Cost + Existing Cost) |
| **分子** | `cost_amt`（维度分组下引力魔方新客花费） |
| **分母** | `cost_amt`（维度分组下 引力魔方新客 + 老客花费） |
| **数据底表** | `a05_e2e_paid_media_summary_d` |
| **筛选条件** | 分子：`customer_type='NEW' AND channel='引力魔方' AND page_type=2`AND`Total`='Total'；分母：`customer_type in ('NEW','EXISTING') AND channel='引力魔方' AND page_type=2`AND`Total`='Total' |
| **数据类型** | decimal_1dp → 数值，保留一位小数 |
| **数据格式** | `#,##0.0` |

---

## 14. New Customer Cost% 全站推 — 新客花费占比全站推

| 项目 | 内容 |
|---|---|
| **指标名称** | New Customer Cost% 全站推 / 新客花费占比全站推 |
| **业务定义** | 全站推新客花费占比 |
| **计算公式** | 全站推新客 Cost / (New Cost + Existing Cost) |
| **分子** | `cost_amt`（维度分组下全站推新客花费） |
| **分母** | `cost_amt`（维度分组下 全站推新客 + 老客花费） |
| **数据底表** | `a05_e2e_paid_media_summary_d` |
| **筛选条件** | 分子：`customer_type='NEW' AND channel='全站推' AND page_type=2`AND`Total`='Total'；分母：`customer_type in ('NEW','EXISTING') AND channel='全站推' AND page_type=2`AND`Total`='Total' |
| **数据类型** | decimal_1dp → 数值，保留一位小数 |
| **数据格式** | `#,##0.0` |

---

## 通用规则汇总

| 规则项 | 说明 |
|---|---|
| **数据底表** | 全部指标统一使用 `a05_e2e_paid_media_summary_d` |
| **page_type** | 本板块统一 `page_type=2` |
| **分组维度** | 按 Brand-Category-Framework排列组合 六种动态行维度分组 分组,具体参考RL E2E\RL E2E Traffic_Dashboard\KPI Breakdown\Brand-Category-Framework排列组合.sql文件，不同Scenario_Type对应不同的层次结构，Brand->Category->Framework表和事实表a05_e2e_paid_media_summary_d是断开连接的，也就对应不同的筛选逻辑写法 |
| **渠道拆分** | Cost MOB%、ROI、New Customer Cost% 均按 channel（直通车/引力魔方/全站推）拆分 Total + 三个分渠道指标 |
| **派生指标** | Cost% vs SLS%为派生比率指标 |
| **cost% 分母** | 占比类指标的 TTL 分母需移除当前分组维度（Brand->Category->Framework表中的动态维度） |
| **必须遵守** | 口径文档中定义的所有指标，必须遵守其数据类型和数据格式，如果和解决方案中存在争议的，一切以口径文档为准，必须按照口径文档中的格式进行调整 |
| **DAX 语法规范** | 文本常量必须使用双引号 `" "`，禁止使用单引号；单引号 `' '` 仅用于表名，列名使用方括号 `[ ]`，例如：`[channel] = "直通车"` |
| **TM和JD的channel映射关系** | 直通车 -- 快车  引力魔方 -->触点  全站推-->海投，也就是在`a05_e2e_paid_media_summary_d`表中TM平台的直通车渠道，在JD平台表示为快车。 |

---

---

# JD Category Growth 指标口径提示词

> **Dashboard**: DCom Performance Media Dashboard  
> **Tab**: Category Growth  
> **板块名称**: KPI Breakdown  
> **数据底表**: `a05_e2e_paid_media_summary_d`  
> **模块说明**: 本板块为 KPI 分解矩阵，按 Brand-Category-Framework排列组合 六种动态行维度 分组，通过Scenario筛选器单选筛选，默认筛选设置为Brand->Category->Framework，统计花费占比、销售占比、ROI、新客花费占比等指标，并按渠道（快车/触点/海投）拆分。

---

## 全局逻辑

| 项目 | 内容 |
|---|---|
| **数据底表** | `a05_e2e_paid_media_summary_d` |
| **page_type 筛选** | 本板块统一 `page_type=2`、`Total` = 'Total' |
| **customer_type 筛选** | 按指标区分 `ALL`（全客）或 `NEW`（新客） |
| **分组维度** | 按Brand-Category-Framework排列组合 六种动态行维度 分组 |
| **分子/分母标记** | Excel 中以 `└ 分子` / `└ 分母` 行标注派生指标的分子分母取数，本文件在各指标中合并展示 |
| **派生指标** | Cost% vs SLS%、Cost MOB% 系列、ROI 系列、New Customer Cost% 系列均为派生比率指标，本身无独立统计字段，依据其分子/分母行取数计算 |
| **必须遵守** | 口径文档中定义的所有指标，必须遵守其数据类型和数据格式，如果和解决方案中存在争议的，一切以口径文档为准，必须按照口径文档中的格式进行调整 |
| **TM和JD的channel映射关系** | 直通车 -- 快车  引力魔方 -->触点  全站推-->海投，也就是在`a05_e2e_paid_media_summary_d`表中TM平台的直通车渠道，在JD平台表示为快车。 |

---

## 1. Cost% vs SLS% — 花费%vs销售%

| 项目 | 内容 |
|---|---|
| **指标名称** | Cost% vs SLS% / 花费%vs销售% |
| **业务定义** | 花费占比 vs 销售占比差异（pt） |
| **计算公式** | Cost MOB% * 100 − Net Sales% * 100（差值，单位 pt） |
| **Cost MOB%** | `cost_amt`/`cost_amt`（TTL） * 100 |
| **Net Sales%** | `net_sales_amt`/`net_sales_amt`（TTL） * 100 |
| **数据底表** | `a05_e2e_paid_media_summary_d` |
| **筛选条件** | `customer_type='ALL' AND page_type=2` AND `Total`='Total' |
| **数据类型** | decimal_pt_1 → pt，保留一位小数，不含正号，* 100乘以100的操作可以放在Cell Display中实现 |
| **数据格式** | `#,##0.0pt;-#,##0.0pt;0.0pt` |

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
| **筛选条件** | `customer_type='ALL' AND page_type=2` AND `Total`='Total'，按Brand-Category-Framework排列组合 六种动态行维度 分组 |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%;#,##0.0%;0.0%` |

---

## 3. Cost MOB% Total — 花费MOB%合计

| 项目 | 内容 |
|---|---|
| **指标名称** | Cost MOB% Total / 花费MOB%合计 |
| **业务定义** | 花费占比 |
| **计算公式** | 所有channel Cost / TTL Cost |
| **分子** | `cost_amt`（该Brand-Category-Framework排列组合 六种动态行维度分组下的花费） |
| **分母** | `cost_amt`（ TTL，去除分组行维度下的花费） |
| **数据底表** | `a05_e2e_paid_media_summary_d` |
| **筛选条件** | `customer_type='ALL' AND page_type=2` AND channel in ('快车','触点','海投') AND `Total`='Total' |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%;#,##0.0%;0.0%` |

---

## 4. Cost MOB% 快车 — 花费MOB%快车

| 项目 | 内容 |
|---|---|
| **指标名称** | Cost MOB% 快车 / 花费MOB%快车 |
| **业务定义** | 快车花费占比 |
| **计算公式** | 快车 Cost / TTL Cost |
| **分子** | `cost_amt`（维度分组下快车花费） |
| **分母** | `cost_amt`（去除维度分组下 快车 TTL 花费） |
| **数据底表** | `a05_e2e_paid_media_summary_d` |
| **筛选条件** | `customer_type='ALL' AND page_type=2` AND channel in ('快车') AND `Total`='Total' |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%;#,##0.0%;0.0%` |

---

## 5. Cost MOB% 触点 — 花费MOB%触点

| 项目 | 内容 |
|---|---|
| **指标名称** | Cost MOB% 触点 / 花费MOB%触点 |
| **业务定义** | 触点花费占比 |
| **计算公式** | 触点 Cost / TTL Cost |
| **分子** | `cost_amt`（维度分组下触点花费） |
| **分母** | `cost_amt`（去除维度分组下 触点 TTL 花费） |
| **数据底表** | `a05_e2e_paid_media_summary_d` |
| **筛选条件** | `customer_type='ALL' AND page_type=2` AND channel in ('触点') AND `Total`='Total' |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%;#,##0.0%;0.0%` |

---

## 6. Cost MOB% 海投 — 花费MOB%海投

| 项目 | 内容 |
|---|---|
| **指标名称** | Cost MOB% 海投 / 花费MOB%海投 |
| **业务定义** | 海投花费占比 |
| **计算公式** | 海投 Cost / TTL Cost |
| **分子** | `cost_amt`（维度分组下海投花费） |
| **分母** | `cost_amt`（去除维度分组下 海投 TTL 花费） |
| **数据底表** | `a05_e2e_paid_media_summary_d` |
| **筛选条件** | `customer_type='ALL' AND page_type=2` AND channel in ('海投') AND `Total`='Total' |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%;#,##0.0%;0.0%` |

---

## 7. ROI Total — ROI合计

| 项目 | 内容 |
|---|---|
| **指标名称** | ROI Total / ROI合计 |
| **业务定义** | 媒体 ROI 合计 |
| **计算公式** | 所有点位 Sales / 所有点位 Cost |
| **分子** | `media_sales_amt`（该Brand-Category-Framework排列组合 六种动态行维度分组下的成交金额，投放带来的销售额，所有 channel('快车','触点','海投')） |
| **分母** | `cost_amt`（该Brand-Category-Framework排列组合 六种动态行维度分组下的 花费，所有 channel('快车','触点','海投')） |
| **数据底表** | `a05_e2e_paid_media_summary_d` |
| **筛选条件** | `customer_type='ALL' AND page_type=2` AND channel in ('快车','触点','海投') AND `Total`='Total' |
| **数据类型** | decimal_1dp → 数值，保留一位小数 |
| **数据格式** | `#,##0.0` |

---

## 8. ROI 快车 — ROI快车

| 项目 | 内容 |
|---|---|
| **指标名称** | ROI 快车 / ROI快车 |
| **业务定义** | 快车 ROI |
| **计算公式** | 快车 Sales / Cost |
| **分子** | `media_sales_amt`（快车成交金额） |
| **分母** | `cost_amt`（快车花费） |
| **数据底表** | `a05_e2e_paid_media_summary_d` |
| **筛选条件** | `customer_type='ALL' AND channel='快车' AND page_type=2` AND `Total`='Total' |
| **数据类型** | decimal_1dp → 数值，保留一位小数 |
| **数据格式** | `#,##0.0` |

---

## 9. ROI 触点 — ROI触点

| 项目 | 内容 |
|---|---|
| **指标名称** | ROI 触点 / ROI触点 |
| **业务定义** | 触点 ROI |
| **计算公式** | 触点 Sales / Cost |
| **分子** | `media_sales_amt`（触点成交金额） |
| **分母** | `cost_amt`（触点花费） |
| **数据底表** | `a05_e2e_paid_media_summary_d` |
| **筛选条件** | `customer_type='ALL' AND channel='触点' AND page_type=2` AND `Total`='Total' |
| **数据类型** | decimal_1dp → 数值，保留一位小数 |
| **数据格式** | `#,##0.0` |

---

## 10. ROI 海投 — ROI海投

| 项目 | 内容 |
|---|---|
| **指标名称** | ROI 海投 / ROI海投 |
| **业务定义** | 海投 ROI |
| **计算公式** | 海投 Sales / Cost |
| **分子** | `media_sales_amt`（海投成交金额） |
| **分母** | `cost_amt`（海投花费） |
| **数据底表** | `a05_e2e_paid_media_summary_d` |
| **筛选条件** | `customer_type='ALL' AND channel='海投' AND page_type=2` AND `Total`='Total' |
| **数据类型** | decimal_1dp → 数值，保留一位小数 |
| **数据格式** | `#,##0.0` |

---

## 11. New Customer Cost% Total — 新客花费占比合计

| 项目 | 内容 |
|---|---|
| **指标名称** | New Customer Cost% Total / 新客花费占比合计 |
| **业务定义** | 新客花费占比合计 |
| **计算公式** | 所有channel新客 Cost / TTL Cost |
| **分子** | `cost_amt`（新客花费 New Cost）该Brand-Category-Framework排列组合 六种动态行维度分组下的成交金额，投放带来的销售额，所有 channel('快车','触点','海投') |
| **分母** | `cost_amt`（新客花费 + 老客花费，New + Existing Cost）该Brand-Category-Framework排列组合 六种动态行维度分组下的成交金额，投放带来的销售额，所有 channel('快车','触点','海投') |
| **数据底表** | `a05_e2e_paid_media_summary_d` |
| **筛选条件** | 分子：`customer_type='NEW' AND page_type=2`AND`Total`='Total' AND channel in ('快车','触点','海投')；分母：`customer_type in ('NEW','EXISTING') AND page_type=2` AND `Total`='Total' AND channel in ('快车','触点','海投') |

---

## 12. New Customer Cost% 快车 — 新客花费占比快车

| 项目 | 内容 |
|---|---|
| **指标名称** | New Customer Cost% 快车 / 新客花费占比快车 |
| **业务定义** | 快车新客花费占比 |
| **计算公式** | 快车新客 Cost / (New Cost + Existing Cost) |
| **分子** | `cost_amt`（维度分组下快车新客花费） |
| **分母** | `cost_amt`（维度分组下 快车新客 + 老客花费） |
| **数据底表** | `a05_e2e_paid_media_summary_d` |
| **筛选条件** | 分子：`customer_type='NEW' AND channel='快车' AND page_type=2`AND`Total`='Total'；分母：`customer_type in ('NEW','EXISTING') AND channel='快车' AND page_type=2`AND`Total`='Total' |
| **数据类型** | decimal_1dp → 数值，保留一位小数 |
| **数据格式** | `#,##0.0` |

---

## 13. New Customer Cost% 触点 — 新客花费占比触点

| 项目 | 内容 |
|---|---|
| **指标名称** | New Customer Cost% 触点 / 新客花费占比触点 |
| **业务定义** | 触点新客花费占比 |
| **计算公式** | 触点新客 Cost / (New Cost + Existing Cost) |
| **分子** | `cost_amt`（维度分组下触点新客花费） |
| **分母** | `cost_amt`（维度分组下 触点新客 + 老客花费） |
| **数据底表** | `a05_e2e_paid_media_summary_d` |
| **筛选条件** | 分子：`customer_type='NEW' AND channel='触点' AND page_type=2`AND`Total`='Total'；分母：`customer_type in ('NEW','EXISTING') AND channel='触点' AND page_type=2`AND`Total`='Total' |
| **数据类型** | decimal_1dp → 数值，保留一位小数 |
| **数据格式** | `#,##0.0` |

---

## 14. New Customer Cost% 海投 — 新客花费占比海投

| 项目 | 内容 |
|---|---|
| **指标名称** | New Customer Cost% 海投 / 新客花费占比海投 |
| **业务定义** | 海投新客花费占比 |
| **计算公式** | 海投新客 Cost / (New Cost + Existing Cost) |
| **分子** | `cost_amt`（维度分组下海投新客花费） |
| **分母** | `cost_amt`（维度分组下 海投新客 + 老客花费） |
| **数据底表** | `a05_e2e_paid_media_summary_d` |
| **筛选条件** | 分子：`customer_type='NEW' AND channel='海投' AND page_type=2`AND`Total`='Total'；分母：`customer_type in ('NEW','EXISTING') AND channel='海投' AND page_type=2`AND`Total`='Total' |
| **数据类型** | decimal_1dp → 数值，保留一位小数 |
| **数据格式** | `#,##0.0` |

---

## 通用规则汇总

| 规则项 | 说明 |
|---|---|
| **数据底表** | 全部指标统一使用 `a05_e2e_paid_media_summary_d` |
| **page_type** | 本板块统一 `page_type=2` |
| **分组维度** | 按 Brand-Category-Framework排列组合 六种动态行维度分组 分组,具体参考RL E2E\RL E2E Traffic_Dashboard\KPI Breakdown\Brand-Category-Framework排列组合.sql文件，不同Scenario_Type对应不同的层次结构，Brand->Category->Framework表和事实表a05_e2e_paid_media_summary_d是断开连接的，也就对应不同的筛选逻辑写法 |
| **渠道拆分** | Cost MOB%、ROI、New Customer Cost% 均按 channel（快车/触点/海投）拆分 Total + 三个分渠道指标 |
| **派生指标** | Cost% vs SLS%为派生比率指标 |
| **cost% 分母** | 占比类指标的 TTL 分母需移除当前分组维度（Brand->Category->Framework表中的动态维度） |
| **必须遵守** | 口径文档中定义的所有指标，必须遵守其数据类型和数据格式，如果和解决方案中存在争议的，一切以口径文档为准，必须按照口径文档中的格式进行调整 |
| **DAX 语法规范** | 文本常量必须使用双引号 `" "`，禁止使用单引号；单引号 `' '` 仅用于表名，列名使用方括号 `[ ]`，例如：`[channel] = "快车"` |
| **TM和JD的channel映射关系** | 直通车 -- 快车  引力魔方 -->触点  全站推-->海投，也就是在`a05_e2e_paid_media_summary_d`表中TM平台的直通车渠道，在JD平台表示为快车。 |
