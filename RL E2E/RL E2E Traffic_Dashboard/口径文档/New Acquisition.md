# New Acquisition 指标口径提示词

> **Dashboard**: DCom Performance Media Dashboard  
> **Tab**: New Acquisition  
> **数据底表（实际值）**: `a05_e2e_paid_media_summary_d` / `a05_e2e_paid_media_crowed_data_d` / `a05_e2e_paid_media_keyword_data_d` / `a03_e2e_customer_data_m`  
> **数据底表（目标值）**: `a05_e2e_paid_media_fcst_data_m`，日期字段 `data_date`  
> **模块说明**: 本板块聚焦新客获取，覆盖 KPIs、Ads Format Cost%、Controllable Ads Format Cost% Trend、Controllable Ads format breakdown 四个子板块，统计新客贡献率、获客成本、可控/不可控花费占比及渠道下钻层级指标。

---

## 全局逻辑

| 项目 | 内容 |
|---|---|
| **数据底表（实际值）** | 汇总指标用 `a05_e2e_paid_media_summary_d`；引力魔方 TA 下钻用 `a05_e2e_paid_media_crowed_data_d`；直通车关键词/计划下钻用 `a05_e2e_paid_media_keyword_data_d`；全店新客分母用 `a03_e2e_customer_data_m` |
| **数据底表（目标值）** | `a05_e2e_paid_media_fcst_data_m`（预测专用表），日期字段 `data_date` |
| **page_type 筛选** | 本板块统一 `page_type=1`（仅汇总表；下钻表无 page_type 筛选） |
| **customer_type 筛选** | 按指标区分 `ALL`（全客）或 `NEW`（新客）；媒体新客类指标（`media_member_cnt`/`media_cost_amt`）统一 `customer_type='ALL' AND page_type=1` |
| **日期切片器** | `Slicer_Time_Frame`：`TimeFrame_ID`（时间粒度 Month/Quarter/Year），`TimeFrame_Value`（展示值），所选时间区间 `data_date ∈ [TimeFrame_Min, TimeFrame_Max]` |
| **媒体新客字段聚合** | `media_member_cnt`/`media_cost_amt` 先按 `platform + data_year + data_month` 取 `MAX`，再对所选财月及平台 `SUM`；仅支持完整财月、财季、财年 |
| **全店新客判定（Net）** | 数据底表 `a03_e2e_customer_data_m`：Step1 在所选时间范围内 `SUM(net_pay_amt) > 0 AND is_member = 0`；Step2 缩小至 `start_period` 往前推 12 个月 `lp_12m_net_pay_amt = 0`（`data_date = 所选时间范围 start_period`）；两步交集即为全店新客。Month 按财月、`platform` 对 `user_id` 去重计数；Quarter、Year 及 `Platform=ALL` 去重范围复用 Customer Dashboard 同 Timeframe、同 Period 逻辑 |
| **分子/分母标记** | Excel 中以 `└ 分子` / `└ 分母` 行标注派生指标的分子分母取数，本文件在各指标中合并展示 |
| **派生指标** | Media Contribution to New Customer Acquisition%、Cost per new acquisition、Cost% 系列均为派生比率指标，本身无独立统计字段，依据其分子/分母行取数计算 |
| **TAR ACH% 结构** | TAR ACH% 类指标采用 Actual / Target / ±Actual vs Target 三段式；Target 取数按 Month/Quarter/Year 粒度来自 `a05_e2e_paid_media_fcst_data_m`；±Actual vs Target 默认 `Actual - Target`（Cost Per New Acquisition 为 `Actual / Target - 1`） |
| **Target 缺失处理** | Target 缺失时，Target 及 ±Actual vs Target 展示"-"；Cost Per New Acquisition 额外处理 Target=0 及 `media_member_cnt`=0 |
| **必须遵守** | 口径文档中定义的所有指标，必须遵守其数据类型和数据格式，如果和解决方案中存在争议的，一切以口径文档为准，必须按照口径文档中的格式进行调整 |
| **DAX 语法规范** | 文本常量必须使用双引号 `" "`，禁止使用单引号；单引号 `' '` 仅用于表名，列名使用方括号 `[ ]`，例如：`[channel] = "引力魔方"`、`[is_controllable_channel] = 1` |

---

## 子模块一：KPIs

### 1. Media Contribution to New Customer Acquisition% — 媒体新客贡献率

| 项目 | 内容 |
|---|---|
| **指标名称** | Media Contribution to New Customer Acquisition% / 媒体新客贡献率 |
| **业务定义** | 媒体新客贡献率 |
| **Actual 计算公式** | 媒体新客数 / 全店新客数 |
| **分子** | `media_member_cnt`（媒体新客数，`a05_e2e_paid_media_summary_d`） |
| **分子筛选条件** | `customer_type='ALL' AND page_type="1"`；Month 按 `platform + data_year + data_month` 取 `MAX(media_member_cnt)`；Quarter、Year 及 `Platform=ALL` 先按 `platform + data_year + data_month` 取 `MAX(media_member_cnt)`，再对所选财月及平台 `SUM`。仅支持完整财月、财季、财年 |
| **分母** | `count(distinct user_id)`（全店新客数，`a03_e2e_customer_data_m`） |
| **分母筛选条件** | Step1：所选时间范围内 `SUM(net_pay_amt) > 0 AND is_member = 0`（`dt = 所选时间范围`）；Step2：缩小至 `start_period` 往前推 12 个月 `lp_12m_net_pay_amt = 0`（`dt = 所选时间范围 start_period`）；两步交集。Month 按财月、`platform` 对 `user_id` 去重计数；Quarter、Year 及 `Platform=ALL` 去重范围复用 Customer Dashboard 同 Timeframe、同 Period 逻辑 |
| **数据底表（分子）** | `a05_e2e_paid_media_summary_d` |
| **数据底表（分母）** | `a03_e2e_customer_data_m` |
| **聚合粒度** | `data_date = 所选时间范围`，`platform, shop_info_id` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%;-#,##0.0%;0.0%` |

---

### 2. Media Contribution to New Customer Acquisition% vs LY — 媒体新客贡献率（对比去年同期）

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

### 3. Media Contribution to New Customer Acquisition% TAR ACH% — 媒体新客贡献率进度达成

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
| **Actual 分子筛选条件** | `customer_type='ALL' AND page_type="1"`；Month 按 `platform + data_year + data_month` 取 `MAX(media_member_cnt)`；Quarter、Year 及 `Platform=ALL` 先取 `MAX` 再对所选财月及平台 `SUM`。仅支持完整财月、财季、财年 |
| **Actual 分母筛选条件** | Step1：所选时间范围 `SUM(net_pay_amt) > 0 AND is_member = 0`；Step2：`start_period` `lp_12m_net_pay_amt = 0`；两步交集。Month 按财月、`platform` 去重；Quarter、Year 及 `Platform=ALL` 复用 Customer Dashboard 同 Timeframe、同 Period 去重逻辑 |
| **Target 取数逻辑** | Month 取所选财月 `media_new_customer_contribution_rate`；Quarter 汇总所选财季各财月 `SUM(media_new_customer_cnt) / SUM(new_customer_cnt)`；Year 按 `data_year` 取 `MAX(year_media_new_customer_contribution_rate)` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%;-#,##0.0%;0.0%` |

**TAR ACH% 计算规则矩阵（Media Contribution%，分母涉全店新客跨财年判定）**

| TimeFrame | 选择范围 | 分子（Actual） | 分母（Target） | 说明 |
|---|---|---|---|---|
| Month | 选择单个财月 | Media Contribution%（month actual） | `media_new_customer_contribution_rate` | 单月实际 / 月度目标 |
| Month | 选择多个财月（不跨财年） | Media Contribution%（区间 actual） | `SUM(media_new_customer_cnt) / SUM(new_customer_cnt)` | 区间实际 / 区间目标 |
| Month | 选择多个财月且跨财年 | — | — | **留空**，跨财年不计算 |
| Quarter | 选择单个季度且不跨财年 | Media Contribution%（quarter actual） | `SUM(media_new_customer_cnt) / SUM(new_customer_cnt)` | 季度实际 / 季度目标 |
| Quarter | 选择多个季度且不跨财年 | Media Contribution%（区间 actual） | `SUM(media_new_customer_cnt) / SUM(new_customer_cnt)` | 区间实际 / 区间目标 |
| Quarter | 跨财年 | — | — | **留空**，跨财年不计算 |
| Year | 选择单个财年 | Media Contribution%（year actual） | `MAX(year_media_new_customer_contribution_rate)` | 年度实际 / 年度目标 |
| Year | 选择多个财年 | — | — | **留空**，多年不计算 |

> 留空处理：当计算规则标注为「留空」时，该指标在对应场景下显示为空值或隐藏；Target 缺失时 Target 及 ±Actual vs Target 展示"-"。

---

### 4. Media Cost Per New Acquisition — 媒体新客获客成本

| 项目 | 内容 |
|---|---|
| **指标名称** | Cost Per New Acquisition / 媒体新客获客成本 |
| **业务定义** | 总新客花费 / 总媒体新客的数量 |
| **Actual 计算公式** | 新客花费 / 媒体新客数 |
| **分子** | `media_cost_amt`（新客花费 media_new_cost，`a05_e2e_paid_media_summary_d`） |
| **分子筛选条件** | `customer_type='ALL' AND page_type="1"`；Month 按 `platform + data_year + data_month` 取 `MAX(media_cost_amt)`；Quarter、Year 及 `Platform=ALL` 先按 `platform + data_year + data_month` 取 `MAX(media_cost_amt)`，再对所选财月及平台 `SUM`。仅支持完整财月、财季、财年 |
| **分母** | `media_member_cnt`（媒体新客数 media_new_customer_no，`a05_e2e_paid_media_summary_d`） |
| **分母筛选条件** | `customer_type='ALL' AND page_type="1"`；Month 按 `platform + data_year + data_month` 取 `MAX(media_member_cnt)`；Quarter、Year 及 `Platform=ALL` 先取 `MAX` 再对所选财月及平台 `SUM`。仅支持完整财月、财季、财年 |
| **数据底表** | `a05_e2e_paid_media_summary_d` |
| **聚合粒度** | `data_date = 所选时间范围`，`platform, shop_info_id`（先按 `platform + data_year + data_month` 取 MAX 再 SUM 后相除） |
| **数据类型** | currency_decimal_1dp → 货币符号由币种切片器决定，千分位保留一位小数 |
| **数据格式** | `#,##0.0`（在 DAX 中用 `__CurrencySymbol & FORMAT(__Value, "#,##0.0")` 拼接币种符号） |
| **边界处理** | 汇总后的 `media_member_cnt` 为 0 时，Actual 展示"-" |

---

### 5. Media Cost Per New Acquisition vs LY — 媒体新客获客成本（对比去年同期）

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

### 6. Media Cost Per New Acquisition TAR ACH% — 媒体新客获客成本进度达成

| 项目 | 内容 |
|---|---|
| **指标名称** | Media Cost Per New Acquisition TAR ACH% / 媒体新客获客成本进度达成 |
| **业务定义** | 媒体新客获客成本实际值与目标值之比 |
| **Actual 计算公式** | `media_cost_amt / media_member_cnt`（同 Media Cost Per New Acquisition，先按 `platform + data_year + data_month` 取 MAX 再 SUM 后相除） |
| **Target 计算公式** | Month：`cost_per_new_acquisition`；Quarter：`SUM(media_new_customer_cost_amt) / SUM(media_new_customer_cnt)`（汇总所选财季范围内各财月）；Year：按 `data_year` 取 `MAX(year_cost_per_new_acquisition)` |
| **±Actual vs Target** | Actual / Target - 1 |
| **Actual 数据底表** | `a05_e2e_paid_media_summary_d` |
| **Target 数据底表** | `a05_e2e_paid_media_fcst_data_m`，日期字段 `data_date` |
| **Actual 筛选条件** | `customer_type='ALL' AND page_type="1"`；Month 按 `platform + data_year + data_month` 取 `MAX(media_cost_amt)`、`MAX(media_member_cnt)`；Quarter、Year 及 `Platform=ALL` 先取 `MAX` 再对所选财月及平台 `SUM`。仅支持完整财月、财季、财年 |
| **Target 取数逻辑** | Month 取所选财月 `cost_per_new_acquisition`；Quarter 汇总所选财季各财月 `SUM(media_new_customer_cost_amt) / SUM(media_new_customer_cnt)`；Year 按 `data_year` 取 `MAX(year_cost_per_new_acquisition)` |
| **边界处理** | Target 缺失或为 0 时，Target 及 ±Actual vs Target 展示"-"；汇总后的 `media_member_cnt` 为 0 时，Actual 及 ±Actual vs Target 展示"-" |
| **时间粒度支持** | 仅支持完整财月、财季、财年；跨财年或不完整区间 Actual/Target 留空 |
| **数据类型** | currency_decimal_1dp → 货币符号由币种切片器决定，千分位保留一位小数 |
| **数据格式** | `#,##0.0`（在 DAX 中用 `__CurrencySymbol & FORMAT(__Value, "#,##0.0")` 拼接币种符号） |

---

## 子模块二：Ads Format Cost%

### 7. Media Cost — 媒体花费（分平台）

| 项目 | 内容 |
|---|---|
| **指标名称** | Media Cost / 媒体花费 |
| **业务定义** | 各平台实际媒体花费 |
| **计算公式** | 同 Cost（实际媒体花费） |
| **统计字段** | `cost_amt` |
| **数据底表** | `a05_e2e_paid_media_summary_d` |
| **筛选条件** | `customer_type='ALL' AND page_type="1"` |
| **数据类型** | currency_M_K_Int_0db → 货币符号由币种切片器决定，千分位整数,需要在Cell Display度量中拼接币种符号，需要判断是否带K、M、或者就是千分位整数，如果值小于1000，就直接表示为千分位整数，如果值大于等于1000，就表示为带K、M的格式，1K为一千，1M为一百万，都采用千分位的格式 |
| **数据格式** | `#,##0`（在 DAX 中用 `__CurrencySymbol & FORMAT(__Value, "#,##0")` 拼接币种符号） |
| **TM和JD的channel映射关系**| 直通车 -- 快车  引力魔方 -->触点  全站推-->海投，也就是在 `a05_e2e_paid_media_summary_d`表中TM平台的直通车渠道，在JD平台表示为快车,DY和RLE的暂时不管。|

### 8. 直通车 Cost% — 直通车花费占比

| 项目 | 内容 |
|---|---|
| **指标名称** | 直通车 Cost% / 直通车花费占比 |
| **业务定义** | 直通车花费占比（可控广告） |
| **计算公式** | 直通车 Cost / TTL Cost |
| **分子** | `cost_amt`（直通车花费） |
| **分母** | `cost_amt`（所有点位 TTL 花费，所有 channel） |
| **数据底表** | `a05_e2e_paid_media_summary_d` |
| **筛选条件** | 分子：`customer_type='ALL' AND channel='直通车' AND page_type=1`；分母：`customer_type='ALL' AND page_type=1` |
| **TM和JD的channel映射关系**| 直通车 -- 快车  引力魔方 -->触点  全站推-->海投，也就是在 `a05_e2e_paid_media_summary_d`表中TM平台的直通车渠道，在JD平台表示为快车。|
| **数据类型** | percent_0dp → 百分比，保留整数，不含正号 |
| **数据格式** | `#,##0%;#,##0%;0%` |

---

### 9. 引力魔方 Cost% — 引力魔方花费占比

| 项目 | 内容 |
|---|---|
| **指标名称** | 引力魔方 Cost% / 引力魔方花费占比 |
| **业务定义** | 引力魔方花费占比（可控广告） |
| **计算公式** | 引力魔方 Cost / TTL Cost |
| **分子** | `cost_amt`（引力魔方花费） |
| **分母** | `cost_amt`（所有点位 TTL 花费，所有 channel） |
| **数据底表** | `a05_e2e_paid_media_summary_d` |
| **筛选条件** | 分子：`customer_type='ALL' AND channel='引力魔方' AND page_type=1`；分母：`customer_type='ALL' AND page_type=1` |
| **TM和JD的channel映射关系**| 直通车 -- 快车  引力魔方 -->触点  全站推-->海投，也就是在 `a05_e2e_paid_media_summary_d`表中TM平台的直通车渠道，在JD平台表示为快车。|
| **数据类型** | percent_0dp → 百分比，保留整数，不含正号 |
| **数据格式** | `#,##0%;#,##0%;0%` |


---

### 10. Uncontrollable Ads Format Cost% — 不可控广告花费占比

| 项目 | 内容 |
|---|---|
| **指标名称** | Uncontrollable Ads Format Cost% / 不可控广告花费占比 |
| **业务定义** | 不可控广告花费占比 |
| **计算公式** | 不可控广告 Cost / TTL Cost |
| **分子** | `cost_amt`（不可控广告花费，JCGP + 品专 + 明星 + 超级直播） |
| **分母** | `cost_amt`（所有点位 TTL 花费，所有 channel） |
| **数据底表** | `a05_e2e_paid_media_summary_d` |
| **筛选条件** | 分子：`customer_type='ALL' AND is_controllable_channel=0 AND page_type=1`；分母：`customer_type='ALL' AND page_type=1` |
| **TM和JD的channel映射关系**| 直通车 -- 快车  引力魔方 -->触点  全站推-->海投，也就是在 `a05_e2e_paid_media_summary_d`表中TM平台的直通车渠道，在JD平台表示为快车。|
| **数据类型** | percent_0dp → 百分比，保留整数，不含正号 |
| **数据格式** | `#,##0%;#,##0%;0%` |

---

## 子模块三：Controllable Ads Format Cost% Trend

### 11. Controllable% — 可控花费占比（趋势）

| 项目 | 内容 |
|---|---|
| **指标名称** | Controllable% / 可控花费占比 |
| **业务定义** | 可控广告花费占比趋势 |
| **计算公式** | 可控广告 Cost / TTL Cost（趋势），即 is_controllable_channel="1"/（is_controllable_channel="0" + is_controllable_channel="1"） |
| **分子** | `cost_amt`（可控广告花费，is_controllable_channel="1" ，比如：直通车 + 引力魔方） |
| **分母** | `cost_amt`（所有点位 TTL 花费，所有 channel，即is_controllable_channel="0" + is_controllable_channel="1"的部分） | 
| **数据底表** | `a05_e2e_paid_media_summary_d` |
| **筛选条件** | 分子：`customer_type='ALL' AND is_controllable_channel="1" AND page_type=1`；分母：`customer_type='ALL' AND page_type=1 AND is_controllable_channel IN {"0","1"}` |
| **数据类型** | percent_0dp → 百分比，保留整数，不含正号 |
| **数据格式** | `#,##0%;#,##0%;0%` |

---

### 12. Uncontrollable% — 不可控花费占比（趋势）

| 项目 | 内容 |
|---|---|
| **指标名称** | Uncontrollable% / 不可控花费占比 |
| **业务定义** | 不可控广告花费占比趋势 |
| **计算公式** | 不可控广告 Cost / TTL Cost（趋势），即 is_controllable_channel="0"/（is_controllable_channel="0" + is_controllable_channel="1"） |
| **分子** | `cost_amt`（不可控广告花费，is_controllable_channel="0" ，比如：JCGP + 品专 + 明星 + 超级直播） |
| **分母** | `cost_amt`（所有点位 TTL 花费，所有 channel，即is_controllable_channel="0" + is_controllable_channel="1"的部分） | 
| **数据底表** | `a05_e2e_paid_media_summary_d` |
| **筛选条件** | 分子：`customer_type='ALL' AND is_controllable_channel="0" AND page_type=1`；分母：`customer_type='ALL' AND page_type=1 AND is_controllable_channel IN {"0","1"}` |    
| **数据类型** | percent_0dp → 百分比，保留整数，不含正号 |
| **数据格式** | `#,##0%;#,##0%;0%` |

---

### 13. Controllable Cost — 可控花费（趋势）

| 项目 | 内容 |
|---|---|
| **指标名称** | Controllable Cost / 可控花费 |
| **业务定义** | 可控广告花费趋势 |
| **计算公式** | 可控广告花费（绝对金额，趋势） |
| **统计字段** | `cost_amt` |
| **数据底表** | `a05_e2e_paid_media_summary_d` |
| **筛选条件** | `customer_type='ALL' AND is_controllable_channel=1 AND page_type=1` |
| **数据类型** | currency_M_K_Int_0db → 货币符号由币种切片器决定，千分位整数,需要在Cell Display度量中拼接币种符号，需要判断是否带K、M、或者就是千分位整数，如果值小于1000，就直接表示为千分位整数，如果值大于等于1000，就表示为带K、M的格式，1K为一千，1M为一百万，都采用千分位的格式 |
| **数据格式** | `#,##0`（在 DAX 中用 `__CurrencySymbol & FORMAT(__Value, "#,##0")` 拼接币种符号） |
| **TM和JD的channel映射关系**| 直通车 -- 快车  引力魔方 -->触点  全站推-->海投，也就是在 `a05_e2e_paid_media_summary_d`表中TM平台的直通车渠道，在JD平台表示为快车,DY和RLE的暂时不管。|

---

### 14. Uncontrollable Cost — 不可控花费（趋势）

| 项目 | 内容 |
|---|---|
| **指标名称** | Uncontrollable Cost / 不可控花费 |
| **业务定义** | 不可控广告花费趋势 |
| **计算公式** | 不可控广告花费（绝对金额，趋势） |
| **统计字段** | `cost_amt` |
| **数据底表** | `a05_e2e_paid_media_summary_d` |
| **筛选条件** | `customer_type='ALL' AND is_controllable_channel=0 AND page_type=1` |
| **数据类型** | currency_M_K_Int_0db → 货币符号由币种切片器决定，千分位整数,需要在Cell Display度量中拼接币种符号，需要判断是否带K、M、或者就是千分位整数，如果值小于1000，就直接表示为千分位整数，如果值大于等于1000，就表示为带K、M的格式，1K为一千，1M为一百万，都采用千分位的格式 |
| **数据格式** | `#,##0`（在 DAX 中用 `__CurrencySymbol & FORMAT(__Value, "#,##0")` 拼接币种符号） |
| **TM和JD的channel映射关系**| 直通车 -- 快车  引力魔方 -->触点  全站推-->海投，也就是在 `a05_e2e_paid_media_summary_d`表中TM平台的直通车渠道，在JD平台表示为快车,DY和RLE的暂时不管。|

---

## 子模块四：Controllable Ads format breakdown: 引力魔方

> **数据底表**: `a05_e2e_paid_media_crowed_data_d`  
> **分组维度**: 按 TA 层级（`crowed_layer` / `crowed_type` / `crowed_name`）分组  
> **筛选条件**: `channel='引力魔方'`

### 15. Cost — 花费（引力魔方 TA 层级）

| 项目 | 内容 |
|---|---|
| **指标名称** | Cost / 花费 |
| **业务定义** | 引力魔方 TA/新老/OAIPL 层级花费 |
| **计算公式** | 引力魔方各 TA 层级花费 |
| **统计字段** | `cost_amt` |
| **数据底表** | `a05_e2e_paid_media_crowed_data_d` |
| **筛选条件** | `channel='引力魔方'`，按 TA 层级（crowed_layer/crowed_type/crowed_name）分组 |
| **数据类型** | currency → 货币符号由币种切片器决定，千分位整数 |
| **数据格式** | `#,##0`（在 DAX 中用 `__CurrencySymbol & FORMAT(__Value, "#,##0")` 拼接币种符号） |
| **TM和JD的channel映射关系**| 直通车 -- 快车  引力魔方 -->触点  全站推-->海投，也就是在 `a05_e2e_paid_media_summary_d`表中TM平台的直通车渠道，在JD平台表示为快车,DY和RLE的暂时不管。|

---

### 16. Cost 引力魔方 触点占比 — 引力魔方 触点 花费（引力魔方/触点 + 直通车/快车）

| 项目 | 内容 |
|---|---|
| **指标名称** | Cost 引力魔方 触点占比/引力魔方 触点 花费 |
| **业务定义** | (引力魔方/触点) / (引力魔方/触点 + 直通车/快车) 的占比|
| **计算公式** | `cost_amt`（引力魔方/触点） / `cost_amt`（引力魔方/触点 + 直通车/快车） |
| **统计字段** | `cost_amt` |
| **数据底表** | `a05_e2e_paid_media_crowed_data_d` |
| **筛选条件** | 分子：`channel in {'引力魔方','触点'}`，分母：`channel in {'引力魔方','直通车','快车','触点'}`,筛选器platform会通过平台对应渠道channel的。比如：TM的引力魔方和直通车，在JD平台就表示为：触点和快车 |
| **数据类型** | percent_0dp → 百分比，保留整数，不含正号 |
| **数据格式** | `#,##0%;#,##0%;0%` |
| **TM和JD的channel映射关系**| 直通车 -- 快车  引力魔方 -->触点  全站推-->海投，也就是在 `a05_e2e_paid_media_summary_d`表中TM平台的直通车渠道，在JD平台表示为快车,DY和RLE的暂时不管。|

---

### 17. Cost 直通车 快车占比 — 直通车 快车 花费（引力魔方/触点 + 直通车/快车）

| 项目 | 内容 |
|---|---|
| **指标名称** | Cost 直通车 快车占比/直通车 快车 花费 |
| **业务定义** | (直通车/快车) / (引力魔方/触点 + 直通车/快车) 的占比|
| **计算公式** | `cost_amt`（直通车/快车） / `cost_amt`（引力魔方/触点 + 直通车/快车） |
| **统计字段** | `cost_amt` |
| **数据底表** | `a05_e2e_paid_media_crowed_data_d` |
| **筛选条件** | 分子：`channel in {'直通车','快车'}`，分母：`channel in {'引力魔方','直通车','快车','触点'}`,筛选器platform会通过平台对应渠道channel的。比如：TM的引力魔方和直通车，在JD平台就表示为：触点和快车 |
| **数据类型** | percent_0dp → 百分比，保留整数，不含正号 |
| **数据格式** | `#,##0%;#,##0%;0%` |
| **TM和JD的channel映射关系**| 直通车 -- 快车  引力魔方 -->触点  全站推-->海投，也就是在 `a05_e2e_paid_media_summary_d`表中TM平台的直通车渠道，在JD平台表示为快车,DY和RLE的暂时不管。|

---

### 18. Cost% — 花费占比（引力魔方 TA 层级）

| 项目 | 内容 |
|---|---|
| **指标名称** | Cost% / 花费占比 |
| **业务定义** | 引力魔方 TA/新老/OAIPL 层级花费占比 |
| **计算公式** | TA 层级引力魔方 Cost / TTL Cost |
| **分子** | `cost_amt`（该 TA 层级） |
| **分母** | `cost_amt`（该广告点位 TA 合计，移除所有行维度） |
| **数据底表** | `a05_e2e_paid_media_crowed_data_d` |
| **筛选条件** | `channel='引力魔方'` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%;-#,##0.0%;0.0%` |

---

### 19. ROI — ROI（引力魔方 TA 层级）

| 项目 | 内容 |
|---|---|
| **指标名称** | ROI / ROI |
| **业务定义** | 引力魔方 TA/新老/OAIPL 层级 ROI |
| **计算公式** | 引力魔方 TA 层级 Sales / Cost |
| **分子** | `sales_amt`（引力魔方 TA 层级成交金额） |
| **分母** | `cost_amt`（引力魔方 TA 层级花费） |
| **数据底表** | `a05_e2e_paid_media_crowed_data_d` |
| **筛选条件** | `channel='引力魔方'` |
| **数据类型** | decimal_1dp → 数值，保留一位小数                                                |
| **数据格式** | `#,##0.0`                                                                      |

---

## 子模块五：Controllable Ads format breakdown: 直通车

> **数据底表**: `a05_e2e_paid_media_keyword_data_d`  
> **分组维度**: 按 Category / 计划 / 关键词 分组  
> **筛选条件**: `channel='直通车'`

### 20. Cost — 花费（直通车关键词/计划层级）

| 项目 | 内容 |
|---|---|
| **指标名称** | Cost / 花费 |
| **业务定义** | 直通车新老/计划层级花费 |
| **计算公式** | 直通车各关键词/计划层级花费 |
| **统计字段** | `cost_amt` |
| **数据底表** | `a05_e2e_paid_media_keyword_data_d` |
| **筛选条件** | `channel='直通车'`，按 Category/计划/关键词 分组 |
| **数据类型** | currency → 货币符号由币种切片器决定，千分位整数 |
| **数据格式** | `#,##0`（在 DAX 中用 `__CurrencySymbol & FORMAT(__Value, "#,##0")` 拼接币种符号） |
| **TM和JD的channel映射关系**| 直通车 -- 快车  引力魔方 -->触点  全站推-->海投，也就是在 `a05_e2e_paid_media_summary_d`表中TM平台的直通车渠道，在JD平台表示为快车,DY和RLE的暂时不管。|

---

### 14. Cost% — 花费占比（直通车关键词/计划层级）

| 项目 | 内容 |
|---|---|
| **指标名称** | Cost% / 花费占比 |
| **业务定义** | 直通车新老/计划层级花费占比 |
| **计算公式** | 关键词/计划层级 Cost / TTL Cost |
| **分子** | `cost_amt`（该 关键词/计划 层级） |
| **分母** | `cost_amt`（该广告点位合计，移除所有行维度） |
| **数据底表** | `a05_e2e_paid_media_keyword_data_d` |
| **筛选条件** | `channel='直通车'` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%;-#,##0.0%;0.0%` |

---

### 15. ROI — ROI（直通车关键词/计划层级）

| 项目 | 内容 |
|---|---|
| **指标名称** | ROI / ROI |
| **业务定义** | 直通车新老/计划层级 ROI |
| **计算公式** | 直通车关键词层级 Sales / Cost |
| **分子** | `sales_amt`（直通车关键词层级成交金额） |
| **分母** | `cost_amt`（直通车关键词层级花费） |
| **数据底表** | `a05_e2e_paid_media_keyword_data_d` |
| **筛选条件** | `channel='直通车'` |
| **数据类型** | decimal_1dp → 数值，保留一位小数                                                |
| **数据格式** | `#,##0.0`                                                                      |

---

## 通用规则汇总

| 规则项 | 说明 |
|---|---|
| **数据底表（实际值）** | 汇总指标用 `a05_e2e_paid_media_summary_d`；引力魔方 TA 下钻用 `a05_e2e_paid_media_crowed_data_d`；直通车关键词/计划下钻用 `a05_e2e_paid_media_keyword_data_d`；全店新客分母用 `a03_e2e_customer_data_m` |
| **数据底表（目标值）** | `a05_e2e_paid_media_fcst_data_m`（预测专用表，按财月/财季/财年粒度取数），日期字段 `data_date` |
| **page_type** | 本板块统一 `page_type=1`（仅汇总表；下钻表无 page_type 筛选） |
| **customer_type** | 媒体新客类指标（`media_member_cnt`/`media_cost_amt`）统一 `customer_type='ALL' AND page_type=1`；其它指标按定义区分 `ALL`/`NEW` |
| **日期切片器** | `Slicer_Time_Frame`：`TimeFrame_ID`（Month/Quarter/Year），`TimeFrame_Value`（展示值），所选时间区间 `data_date ∈ [TimeFrame_Min, TimeFrame_Max]` |
| **媒体新客字段聚合** | `media_member_cnt`/`media_cost_amt` 先按 `platform + data_year + data_month` 取 `MAX`，再对所选财月及平台 `SUM`；仅支持完整财月、财季、财年 |
| **全店新客判定（Net）** | `a03_e2e_customer_data_m`：Step1 所选时间范围 `SUM(net_pay_amt) > 0 AND is_member = 0` ∩ Step2 `start_period` `lp_12m_net_pay_amt = 0`；Month 按财月、`platform` 去重；Quarter、Year 及 `Platform=ALL` 复用 Customer Dashboard 同 Timeframe、同 Period 去重逻辑 |
| **可控/不可控** | 通过 `is_controllable_channel` 区分（1=可控，0=不可控）；可控广告 = 直通车 + 引力魔方，不可控广告 = JCGP + 品专 + 明星 + 超级直播 |
| **派生指标** | Media Contribution to New Customer Acquisition%、Cost per new acquisition、Cost% 系列为派生比率指标，需分子分母分别计算后再相除 |
| **TAR ACH% 结构** | TAR ACH% 类指标采用 Actual / Target / ±Actual vs Target 三段式；Target 取数按 Month/Quarter/Year 粒度来自 `a05_e2e_paid_media_fcst_data_m`；±Actual vs Target 默认 `Actual - Target`（Cost Per New Acquisition 为 `Actual / Target - 1`） |
| **Target 缺失处理** | Target 缺失时，Target 及 ±Actual vs Target 展示"-"；Cost Per New Acquisition 额外处理 Target=0 及 `media_member_cnt`=0 |
| **下钻分组维度** | 引力魔方按 TA 层级（crowed_layer/crowed_type/crowed_name）；直通车按 Category/计划/关键词 |
| **必须遵守** | 口径文档中定义的所有指标，必须遵守其数据类型和数据格式，如果和解决方案中存在争议的，一切以口径文档为准，必须按照口径文档中的格式进行调整 |
| **DAX 语法规范** | 文本常量必须使用双引号 `" "`，禁止使用单引号；单引号 `' '` 仅用于表名，列名使用方括号 `[ ]`，例如：`[channel] = "引力魔方"`、`[is_controllable_channel] = 1` |
