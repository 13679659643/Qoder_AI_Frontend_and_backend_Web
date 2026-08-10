# Customer Dashboard 指标口径提示词

> **Dashboard**: Customer Dashboard  
> **Tab**: Member  
> **数据底表**: `a03_e2e_customer_data_m`  
> **模块说明**: 本板块为会员核心看板，覆盖 Performance Indicator、Member Breakdown 两个子板块，统计 DCom 新增会员数、DCom 会员净销售额及占比等。

---

## 全局逻辑

| 项目 | 内容 |
|---|---|
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选逻辑** | 会员统一 `is_member = 1`；Net 维度基于 `member_net_pay_amt` / `net_pay_amt`；Demand 维度基于 `member_pay_amt` / `pay_amt` |
| **聚合粒度** | 数字卡片：所选时间范围 `data_date`；表格：所选时间范围 `data_date`，按对应维度聚合 ，特殊情况：DCom New Member Recruitment（Net/Demand） — DCom新增会员数，按 `register_date` 聚合 |
| **货币转换规则** | 数据源默认为 RMB，转化为美元需要除以固定值 7 |
| **派生指标** | LY（去年同期）、LP（上期）、vs LY（同比）、vs LP（环比）、占比等为派生指标，依据基础指标计算生成 |
| **必须遵守** | 口径文档中定义的所有指标，必须遵守其数据类型和数据格式，如果和解决方案中存在争议的，一切以口径文档为准，必须按照口径文档中的格式进行调整 |

---

## 子模块一：Performance Indicator

> **无分组维度**: 只受到筛选器影响，没有分组维度，用于制作卡片图。按 Net / Demand 维度区分。

### 1. DCom New Member Recruitment（Net/Demand） — DCom新增会员数

| 项目 | 内容 |
|---|---|
| **指标名称** | DCom New Member Recruitment |
| **指标名称中文** | DCom新增会员数 |
| **业务定义** | 注册日期在指定日期范围内的会员人数 |
| **计算公式** | count(distinct user_id) |
| **统计字段** | `user_id` |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `is_member = 1`，`register_date` 在所选时间范围内,即a03_e2e_customer_data_m[register_date]在[__TimeMin, __TimeMax]中的数据 |
| **聚合粒度** | `register_date = 所选时间范围`，`platform, shop_info_id`分组维度由表字段自动传递，DAX 无需显式处理 |
| **数据类型** | integer → 整数，千分位整数 |
| **数据格式** | `#,##0` |

### 1.1 DCom New Member Recruitment vs LY（Net/Demand） — DCom新增会员数同比

| 项目 | 内容 |
|---|---|
| **指标名称** | DCom New Member Recruitment vs LY |
| **指标名称中文** | DCom新增会员数同比 |
| **业务定义** | DCom新增会员数今年较去年同期的变化率 |
| **计算公式** | 今年 / 去年 - 1 |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `is_member = 1`，`register_date` 在所选时间范围内,即a03_e2e_customer_data_m[register_date]在[__TimeMin, __TimeMax]中的数据 |
| **聚合粒度** | `register_date = 所选时间范围`，`platform, shop_info_id`分组维度由表字段自动传递，DAX 无需显式处理 |
| **数据类型** | 两种数据格式：percent_1dp → 百分比，保留一位小数，不含正号 或者 delta_pct_1dp → 百分比，保留一位小数，含正号：+14.5% / -3.2%|
| **数据格式** | `#,##0.0%`/IF(__Value > 0, "+", "") & FORMAT(__Value, "0.0%") |

### 1.2 DCom New Member Recruitment vs LP（Net/Demand） — DCom新增会员数环比

| 项目 | 内容 |
|---|---|
| **指标名称** | DCom New Member Recruitment vs LP |
| **指标名称中文** | DCom新增会员数环比 |
| **业务定义** | DCom新增会员数当期较上期的变化率 |
| **计算公式** | 当期 / 上期 - 1 |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `is_member = 1`，`register_date` 在所选时间范围内,即a03_e2e_customer_data_m[register_date]在[__TimeMin, __TimeMax]中的数据 |
| **聚合粒度** | `register_date = 所选时间范围`，`platform, shop_info_id`分组维度由表字段自动传递，DAX 无需显式处理 |
| **数据类型** | 两种数据格式：percent_1dp → 百分比，保留一位小数，不含正号 或者 delta_pct_1dp → 百分比，保留一位小数，含正号：+14.5% / -3.2%|
| **数据格式** | `#,##0.0%`/IF(__Value > 0, "+", "") & FORMAT(__Value, "0.0%") |

---

### 2. DCom Member SLS（Net） — DCom会员净销售额

| 项目 | 内容 |
|---|---|
| **指标名称** | DCom Member SLS |
| **指标名称中文** | DCom会员净销售额 |
| **业务定义** | 统计周期内下单时是会员的净销售额 |
| **计算公式** | sum(member_net_pay_amt) |
| **统计字段** | `member_net_pay_amt` |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `is_member = 1` |
| **聚合粒度** | `data_date = 所选时间范围`，`platform, shop_info_id`分组维度由表字段自动传递，DAX 无需显式处理 |
| **数据类型** | 两种数据格式：currency → 货币符号由币种切片器决定，千分位整数 或者 currency_k  →  货币符号由币种切片器决定，整数以K为单位，¥1k / $5k |
| **数据格式** | `#,##0`（在 DAX 中用 `__CurrencySymbol & FORMAT(__Value, "#,##0")` 拼接币种符号） / __CurrencySymbol & FORMAT(__Value / 1000, "#,##0") & "k"|

### 2.1 DCom Member SLS vs LY（Net） — DCom会员净销售额同比

| 项目 | 内容 |
|---|---|
| **指标名称** | DCom Member SLS vs LY |
| **指标名称中文** | DCom会员净销售额同比 |
| **业务定义** | DCom会员净销售额今年较去年同期的变化率 |
| **计算公式** | 今年 / 去年 - 1 |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `is_member = 1` |
| **聚合粒度** | `data_date = 所选时间范围`，`platform, shop_info_id`分组维度由表字段自动传递，DAX 无需显式处理 |
| **数据类型** | 两种数据格式：percent_1dp → 百分比，保留一位小数，不含正号 或者 delta_pct_1dp → 百分比，保留一位小数，含正号：+14.5% / -3.2%|
| **数据格式** | `#,##0.0%`/IF(__Value > 0, "+", "") & FORMAT(__Value, "0.0%") |

### 2.2 DCom Member SLS vs LP（Net） — DCom会员净销售额环比

| 项目 | 内容 |
|---|---|
| **指标名称** | DCom Member SLS vs LP |
| **指标名称中文** | DCom会员净销售额环比 |
| **业务定义** | DCom会员净销售额当期较上期的变化率 |
| **计算公式** | 当期 / 上期 - 1 |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `is_member = 1` |
| **聚合粒度** | `data_date = 所选时间范围`，`platform, shop_info_id`分组维度由表字段自动传递，DAX 无需显式处理 |
| **数据类型** | 两种数据格式：percent_1dp → 百分比，保留一位小数，不含正号 或者 delta_pct_1dp → 百分比，保留一位小数，含正号：+14.5% / -3.2%|
| **数据格式** | `#,##0.0%`/IF(__Value > 0, "+", "") & FORMAT(__Value, "0.0%") |

---

### 3. DCom Member SLS%（Net） — DCom会员净销售额占比

| 项目 | 内容 |
|---|---|
| **指标名称** | DCom Member SLS% |
| **指标名称中文** | DCom会员净销售额占比 |
| **业务定义** | 统计周期内会员净销售额/全店净销售额 |
| **计算公式** | 分子：sum(member_net_pay_amt) where is_member = 1；分母：sum(net_pay_amt) |
| **分子** | `member_net_pay_amt`（`is_member = 1`） |
| **分母** | `net_pay_amt`（全部） |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | 无 |
| **聚合粒度** | `data_date = 所选时间范围`，`platform, shop_info_id`分组维度由表字段自动传递，DAX 无需显式处理 |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

### 3.1 DCom Member SLS% vs LY（Net） — DCom会员净销售额占比同比

| 项目 | 内容 |
|---|---|
| **指标名称** | DCom Member SLS% vs LY |
| **指标名称中文** | DCom会员净销售额占比同比 |
| **业务定义** | DCom会员净销售额占比今年较去年同期的变化（差值） |
| **计算公式** | 今年 - 去年（差值，展示时 ×100 转 pts） |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | 无 |
| **聚合粒度** | `data_date = 所选时间范围`，`platform, shop_info_id`分组维度由表字段自动传递，DAX 无需显式处理 |
| **数据类型** | 两种数据格式：delta_pts → 增减基点整数： → +120pts / -80pts（基点，含正负号，值×100 转 pts）,乘以100的操作可以放在Cell Display度量中实现，算同比LY：当期值 − 同期值（差值，pts 指标，展示时 ×100 转 pts） 或者 integer_pts → 整数，千分位整数pts, 不含正号，例如：120pts / -80pts |        
| **数据格式** | `+#,##0pts;-#,##0pts;0pts` /`#,##0pts;-#,##0pts;0pts`|

### 3.2 DCom Member SLS% vs LP（Net） — DCom会员净销售额占比环比

| 项目 | 内容 |
|---|---|
| **指标名称** | DCom Member SLS% vs LP |
| **指标名称中文** | DCom会员净销售额占比环比 |
| **业务定义** | DCom会员净销售额占比当期较上期的变化（差值） |
| **计算公式** | 当期 - 上期（差值，展示时 ×100 转 pts） |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | 无 |
| **聚合粒度** | `data_date = 所选时间范围`，`platform, shop_info_id`分组维度由表字段自动传递，DAX 无需显式处理 |
| **数据类型** | 两种数据格式：delta_pts → 增减基点整数： → +120pts / -80pts（基点，含正负号，值×100 转 pts）,乘以100的操作可以放在Cell Display度量中实现，算同比LY：当期值 − 同期值（差值，pts 指标，展示时 ×100 转 pts） 或者 integer_pts → 整数，千分位整数pts, 不含正号，例如：120pts / -80pts |        
| **数据格式** | `+#,##0pts;-#,##0pts;0pts` /`#,##0pts;-#,##0pts;0pts`|

---

### 4. DCom Member SLS（Demand） — DCom会员净销售额

| 项目 | 内容 |
|---|---|
| **指标名称** | DCom Member SLS |
| **指标名称中文** | DCom会员净销售额 |
| **业务定义** | 统计周期内下单时是会员的销售额 |
| **计算公式** | sum(member_pay_amt) |
| **统计字段** | `member_pay_amt` |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `is_member = 1` |
| **聚合粒度** | `data_date = 所选时间范围`，`platform, shop_info_id`分组维度由表字段自动传递，DAX 无需显式处理 |
| **数据类型** | 两种数据格式：currency → 货币符号由币种切片器决定，千分位整数 或者 currency_k  →  货币符号由币种切片器决定，整数以K为单位，¥1k / $5k |
| **数据格式** | `#,##0`（在 DAX 中用 `__CurrencySymbol & FORMAT(__Value, "#,##0")` 拼接币种符号） / __CurrencySymbol & FORMAT(__Value / 1000, "#,##0") & "k"|

### 4.1 DCom Member SLS vs LY（Demand） — DCom会员净销售额同比

| 项目 | 内容 |
|---|---|
| **指标名称** | DCom Member SLS vs LY |
| **指标名称中文** | DCom会员净销售额同比 |
| **业务定义** | DCom会员净销售额今年较去年同期的变化率 |
| **计算公式** | 今年 / 去年 - 1 |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `is_member = 1` |
| **聚合粒度** | `data_date = 所选时间范围`，`platform, shop_info_id`分组维度由表字段自动传递，DAX 无需显式处理 |
| **数据类型** | 两种数据格式：percent_1dp → 百分比，保留一位小数，不含正号 或者 delta_pct_1dp → 百分比，保留一位小数，含正号：+14.5% / -3.2%|
| **数据格式** | `#,##0.0%`/IF(__Value > 0, "+", "") & FORMAT(__Value, "0.0%") |

### 4.2 DCom Member SLS vs LP（Demand） — DCom会员净销售额环比

| 项目 | 内容 |
|---|---|
| **指标名称** | DCom Member SLS vs LP |
| **指标名称中文** | DCom会员净销售额环比 |
| **业务定义** | DCom会员净销售额当期较上期的变化率 |
| **计算公式** | 当期 / 上期 - 1 |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `is_member = 1` |
| **聚合粒度** | `data_date = 所选时间范围`，`platform, shop_info_id`分组维度由表字段自动传递，DAX 无需显式处理 |
| **数据类型** | 两种数据格式：percent_1dp → 百分比，保留一位小数，不含正号 或者 delta_pct_1dp → 百分比，保留一位小数，含正号：+14.5% / -3.2%|
| **数据格式** | `#,##0.0%`/IF(__Value > 0, "+", "") & FORMAT(__Value, "0.0%") |

---

### 5. DCom Member SLS%（Demand） — DCom会员净销售额占比

| 项目 | 内容 |
|---|---|
| **指标名称** | DCom Member SLS% |
| **指标名称中文** | DCom会员净销售额占比 |
| **业务定义** | 统计周期内会员销售额/全店销售额 |
| **计算公式** | 分子：sum(member_pay_amt) where is_member = 1；分母：sum(pay_amt) |
| **分子** | `member_pay_amt`（`is_member = 1`） |
| **分母** | `pay_amt`（全部） |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | 无 |
| **聚合粒度** | `data_date = 所选时间范围`，`platform, shop_info_id`分组维度由表字段自动传递，DAX 无需显式处理 |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

### 5.1 DCom Member SLS% vs LY（Demand） — DCom会员净销售额占比同比

| 项目 | 内容 |
|---|---|
| **指标名称** | DCom Member SLS% vs LY |
| **指标名称中文** | DCom会员净销售额占比同比 |
| **业务定义** | DCom会员净销售额占比今年较去年同期的变化（差值） |
| **计算公式** | 今年 - 去年（差值，展示时 ×100 转 pts） |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | 无 |
| **聚合粒度** | `data_date = 所选时间范围`，`platform, shop_info_id`分组维度由表字段自动传递，DAX 无需显式处理 |
| **数据类型** | 两种数据格式：delta_pts → 增减基点整数： → +120pts / -80pts（基点，含正负号，值×100 转 pts）,乘以100的操作可以放在Cell Display度量中实现，算同比LY：当期值 − 同期值（差值，pts 指标，展示时 ×100 转 pts） 或者 integer_pts → 整数，千分位整数pts, 不含正号，例如：120pts / -80pts |        
| **数据格式** | `+#,##0pts;-#,##0pts;0pts` /`#,##0pts;-#,##0pts;0pts`|

### 5.2 DCom Member SLS% vs LP（Demand） — DCom会员净销售额占比环比

| 项目 | 内容 |
|---|---|
| **指标名称** | DCom Member SLS% vs LP |
| **指标名称中文** | DCom会员净销售额占比环比 |
| **业务定义** | DCom会员净销售额占比当期较上期的变化（差值） |
| **计算公式** | 当期 - 上期（差值，展示时 ×100 转 pts） |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | 无 |
| **聚合粒度** | `data_date = 所选时间范围`，`platform, shop_info_id`分组维度由表字段自动传递，DAX 无需显式处理 |
| **数据类型** | 两种数据格式：delta_pts → 增减基点整数： → +120pts / -80pts（基点，含正负号，值×100 转 pts）,乘以100的操作可以放在Cell Display度量中实现，算同比LY：当期值 − 同期值（差值，pts 指标，展示时 ×100 转 pts） 或者 integer_pts → 整数，千分位整数pts, 不含正号，例如：120pts / -80pts |        
| **数据格式** | `+#,##0pts;-#,##0pts;0pts` /`#,##0pts;-#,##0pts;0pts`|

---

## 通用规则汇总

| 规则项 | 说明 |
|---|---|
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选逻辑** | 会员统一 `is_member = 1`；Net 维度基于 `member_net_pay_amt` / `net_pay_amt`；Demand 维度基于 `member_pay_amt` / `pay_amt` |
| **货币转换规则** | 数据源默认为 RMB，转化为美元需要除以固定值 7 |
| **派生指标** | LY（去年同期）、LP（上期）、vs LY（同比）、vs LP（环比）、占比等为派生指标，依据基础指标计算生成 |
| **分组维度** | 根据 `platform, shop_info_id`分组维度由表字段自动传递，DAX 无需显式处理 分组 |
| **必须遵守** | 口径文档中定义的所有指标，必须遵守其数据类型和数据格式，如果和解决方案中存在争议的，一切以口径文档为准，必须按照口径文档中的格式进行调整 |
| **DAX 语法规范** | 文本常量必须使用双引号 `" "`，禁止使用单引号；单引号 `' '` 仅用于表名，列名使用方括号 `[ ]`，例如：`[is_member] = 1` |
| **pts 与 bp 区别** | pts 指标：值×100 转 pts（基点，含正负号），数据格式 `+#,##0pts;-#,##0pts;0pts`；bp 指标：值×10000 转 bp，数据格式 `+#,##0bp;-#,##0bp;0bp` |
| **TAR ACH% 占位** | Monthly TAR ACH% / Yearly TAR ACH% / TAR ACH% 逻辑暂未确认，先保持子指标占位，数据格式为 percent_1dp：`+#,##0.0%;-#,##0.0%;0.0%`，等逻辑确认后再填充 |
| **Comment 备注** | CSV 中 Comment 列提到："新增会员如果没有购买是否需要统计，如果需要统计，当前的设计需要调整" — 此问题待业务确认 |
