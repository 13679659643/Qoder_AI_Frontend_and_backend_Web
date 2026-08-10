# Customer Dashboard 指标口径提示词

> **Dashboard**: Customer Dashboard  
> **Tab**: VIC  
> **数据底表**: `a03_e2e_customer_data_m` / `t05_customer_order_data_d`  
> **模块说明**: 本板块为 VIC（Very Important Customer）核心看板，覆盖 VIC KPI、VIC Trend、VIC Composition & By Recency Repurchase、VIC Segment、DCom VIC Breakdown、Class x Label Drilldown 等子板块，统计 VIC 数量、留存率、T4-5 升级人数、复购/留存情况、分层销售与人数等。VIC 定义为在指定日期范围往前 Rolling 12 个财月，net sales >= 20k 的买家。

---

## 全局逻辑

| 项目 | 内容 |
|---|---|
| **数据底表** | `a03_e2e_customer_data_m`、`t05_customer_order_data_d` |
| **筛选逻辑** | VIC 统一 `is_vic = 1`；人群细分：TTL VIC（`is_member = 0`）、Member VIC（`is_member = 1`）、Is Employee（`is_employee = 1`） |
| **聚合粒度** | 数字卡片：所选时间范围 `dt`（多数为 end period）；表格：按对应维度聚合 |
| **货币转换规则** | 数据源默认为 RMB，转化为美元需要除以固定值 7 |
| **派生指标** | LY（去年同期）、LP（上期）、vs LY（同比）、vs LP（环比）、占比、YOY 等为派生指标，依据基础指标计算生成 |
| **必须遵守** | 口径文档中定义的所有指标，必须遵守其数据类型和数据格式，如果和解决方案中存在争议的，一切以口径文档为准，必须按照口径文档中的格式进行调整 |

---

## 子模块一：VIC KPI

> **无分组维度**: 只受到筛选器影响，没有分组维度，用于制作卡片图。

### 1. VIC No. — VIC数量

| 项目 | 内容 |
|---|---|
| **指标名称** | VIC No. |
| **指标名称中文** | VIC数量 |
| **业务定义** | 在指定日期范围往前 Rolling 12 个财月，net sales >= 20k 的买家数量 |
| **计算公式** | count(distinct user_id) |
| **统计字段** | `user_id` |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `is_vic = 1`；人群细分：TTL VIC `is_member = 0` / Member VIC `is_member = 1` / Is Employee `is_employee = 1` |
| **聚合粒度** | `dt = 所选时间范围 end period`，`platform, shop_info_id` |
| **数据类型** | integer → 整数，千分位整数 |
| **数据格式** | `#,##0` |

### 1.1 VIC No. vs LY — VIC数量同比

| 项目 | 内容 |
|---|---|
| **指标名称** | VIC No. vs LY |
| **指标名称中文** | VIC数量同比 |
| **业务定义** | VIC数量今年较去年同期的变化率 |
| **计算公式** | 今年 / 去年 - 1 |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `is_vic = 1`；人群细分：TTL VIC `is_member = 0` / Member VIC `is_member = 1` / Is Employee `is_employee = 1` |
| **聚合粒度** | `dt = 所选时间范围 end period`，`platform, shop_info_id` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

### 1.2 VIC No. vs LP — VIC数量环比

| 项目 | 内容 |
|---|---|
| **指标名称** | VIC No. vs LP |
| **指标名称中文** | VIC数量环比 |
| **业务定义** | VIC数量当期较上期的变化率 |
| **计算公式** | 当期 / 上期 - 1 |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `is_vic = 1`；人群细分：TTL VIC `is_member = 0` / Member VIC `is_member = 1` / Is Employee `is_employee = 1` |
| **聚合粒度** | `dt = 所选时间范围 end period`，`platform, shop_info_id` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

### 1.3 Monthly TAR ACH% — 月度目标达成率

| 项目 | 内容 |
|---|---|
| **指标名称** | Monthly TAR ACH% |
| **指标名称中文** | 月度目标达成率 |
| **业务定义** | 暂无逻辑，占位，等逻辑确认后再填充 |
| **计算公式** | 待补充 |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `is_vic = 1`；人群细分：TTL VIC `is_member = 0` / Member VIC `is_member = 1` / Is Employee `is_employee = 1` |
| **聚合粒度** | `dt = 所选时间范围 end period`，`platform, shop_info_id` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，含正负号 |
| **数据格式** | `+#,##0.0%;-#,##0.0%;0.0%` |

### 1.4 Yearly TAR ACH% — 年度目标达成率

| 项目 | 内容 |
|---|---|
| **指标名称** | Yearly TAR ACH% |
| **指标名称中文** | 年度目标达成率 |
| **业务定义** | 暂无逻辑，占位，等逻辑确认后再填充 |
| **计算公式** | 待补充 |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `is_vic = 1`；人群细分：TTL VIC `is_member = 0` / Member VIC `is_member = 1` / Is Employee `is_employee = 1` |
| **聚合粒度** | `dt = 所选时间范围 end period`，`platform, shop_info_id` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，含正负号 |
| **数据格式** | `+#,##0.0%;-#,##0.0%;0.0%` |

---

### 2. VIC Retention% — VIC留存率

| 项目 | 内容 |
|---|---|
| **指标名称** | VIC Retention% |
| **指标名称中文** | VIC留存率 |
| **业务定义** | 在指定日期范围仍为 VIC 且上一周期也是 VIC 的人数/上一周期 VIC 人数 |
| **计算公式** | 分子：count(distinct user_id) where is_retention_vic = 1；分母：所选时间范围 end period 往前 Rolling 12 个财月 count(distinct user_id) where is_vic = 1 |
| **分子** | `user_id`（`is_retention_vic = 1`） |
| **分母** | `user_id`（上周期 `is_vic = 1`） |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | 人群细分：TTL VIC `is_member = 0` / Member VIC `is_member = 1` / Is Employee `is_employee = 1` |
| **聚合粒度** | `dt = 所选时间范围 end period`，`platform, shop_info_id` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

### 2.1 VIC Retention% vs LY — VIC留存率同比

| 项目 | 内容 |
|---|---|
| **指标名称** | VIC Retention% vs LY |
| **指标名称中文** | VIC留存率同比 |
| **业务定义** | VIC留存率今年较去年同期的变化（差值） |
| **计算公式** | 今年 - 去年（差值，展示时 ×100 转 pts） |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | 人群细分：TTL VIC `is_member = 0` / Member VIC `is_member = 1` / Is Employee `is_employee = 1` |
| **聚合粒度** | `dt = 所选时间范围 end period`，`platform, shop_info_id` |
| **数据类型** | delta_pts → 增减基点整数： → +120pts / -80pts（基点，含正负号，值×100 转 pts）,乘以100的操作可以放在Cell Display度量中实现，算同比LY：当期值 − 同期值（差值，pts 指标，展示时 ×100 转 pts） |        
| **数据格式** | `+#,##0pts;-#,##0pts;0pts` |

### 2.2 VIC Retention% vs LP — VIC留存率环比

| 项目 | 内容 |
|---|---|
| **指标名称** | VIC Retention% vs LP |
| **指标名称中文** | VIC留存率环比 |
| **业务定义** | VIC留存率当期较上期的变化（差值） |
| **计算公式** | 当期 - 上期（差值，展示时 ×100 转 pts） |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | 人群细分：TTL VIC `is_member = 0` / Member VIC `is_member = 1` / Is Employee `is_employee = 1` |
| **聚合粒度** | `dt = 所选时间范围 end period`，`platform, shop_info_id` |
| **数据类型** | delta_pts → 增减基点整数： → +120pts / -80pts（基点，含正负号，值×100 转 pts）,乘以100的操作可以放在Cell Display度量中实现，算环比LP：当期值 − 上期值（差值，pts 指标，展示时 ×100 转 pts） |        
| **数据格式** | `+#,##0pts;-#,##0pts;0pts` |

### 2.3 TAR ACH% — 目标达成率

| 项目 | 内容 |
|---|---|
| **指标名称** | TAR ACH% |
| **指标名称中文** | 目标达成率 |
| **业务定义** | 暂无逻辑，占位，等逻辑确认后再填充 |
| **计算公式** | 待补充 |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | 人群细分：TTL VIC `is_member = 0` / Member VIC `is_member = 1` / Is Employee `is_employee = 1` |
| **聚合粒度** | `dt = 所选时间范围 end period`，`platform, shop_info_id` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，含正负号 |
| **数据格式** | `+#,##0.0%;-#,##0.0%;0.0%` |

---

### 3. T4-5 Upgrade No. — T4-5升级为VIC人数

| 项目 | 内容 |
|---|---|
| **指标名称** | T4-5 Upgrade No. |
| **指标名称中文** | T4-5升级为VIC人数 |
| **业务定义** | 上一周期为 T4/T5 且在指定日期范围内升级成为 VIC 的买家人数（T4：上一周期 net sales 为 5-20K 的买家；T5：上一周期 net sales < 5K 的买家） |
| **计算公式** | count(distinct user_id) |
| **统计字段** | `user_id` |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `is_upgrade_vic = 1`；人群细分：TTL VIC `is_member = 0` / Member VIC `is_member = 1` / Is Employee `is_employee = 1` |
| **聚合粒度** | `dt = 所选时间范围 end period`，`platform, shop_info_id` |
| **数据类型** | integer → 整数，千分位整数 |
| **数据格式** | `#,##0` |

### 3.1 T4-5 Upgrade No. vs LY — T4-5升级为VIC人数同比

| 项目 | 内容 |
|---|---|
| **指标名称** | T4-5 Upgrade No. vs LY |
| **指标名称中文** | T4-5升级为VIC人数同比 |
| **业务定义** | T4-5升级为VIC人数今年较去年同期的变化率 |
| **计算公式** | 今年 / 去年 - 1 |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `is_upgrade_vic = 1`；人群细分：TTL VIC `is_member = 0` / Member VIC `is_member = 1` / Is Employee `is_employee = 1` |
| **聚合粒度** | `dt = 所选时间范围 end period`，`platform, shop_info_id` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

### 3.2 T4-5 Upgrade No. vs LP — T4-5升级为VIC人数环比

| 项目 | 内容 |
|---|---|
| **指标名称** | T4-5 Upgrade No. vs LP |
| **指标名称中文** | T4-5升级为VIC人数环比 |
| **业务定义** | T4-5升级为VIC人数当期较上期的变化率 |
| **计算公式** | 当期 / 上期 - 1 |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `is_upgrade_vic = 1`；人群细分：TTL VIC `is_member = 0` / Member VIC `is_member = 1` / Is Employee `is_employee = 1` |
| **聚合粒度** | `dt = 所选时间范围 end period`，`platform, shop_info_id` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

### 3.3 TAR ACH% — 目标达成率

| 项目 | 内容 |
|---|---|
| **指标名称** | TAR ACH% |
| **指标名称中文** | 目标达成率 |
| **业务定义** | 暂无逻辑，占位，等逻辑确认后再填充 |
| **计算公式** | 待补充 |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `is_upgrade_vic = 1`；人群细分：TTL VIC `is_member = 0` / Member VIC `is_member = 1` / Is Employee `is_employee = 1` |
| **聚合粒度** | `dt = 所选时间范围 end period`，`platform, shop_info_id` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，含正负号 |
| **数据格式** | `+#,##0.0%;-#,##0.0%;0.0%` |

---

## 子模块二：VIC Trend

> **分组维度**: 按所选 `timeframe`（Month/Quarter/Year）分组

### 1. VIC No. — VIC数量（趋势）

| 项目 | 内容 |
|---|---|
| **指标名称** | VIC No. |
| **指标名称中文** | VIC数量 |
| **业务定义** | 在指定日期范围往前 Rolling 12 个财月，net sales >= 20k 的买家数量 |
| **计算公式** | count(distinct user_id) |
| **统计字段** | `user_id` |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `is_vic = 1`；人群细分：TTL VIC `is_member = 0` / Member VIC `is_member = 1` / Is Employee `is_employee = 1` |
| **聚合粒度** | 根据所选 timeframe：Month → `dt = 选择时间范围的每个月`；Quarter → `dt = 所选时间范围每季的最后一个财月`；Year → `dt = 所选时间范围每年的最后一个财月`；`platform, shop_info_id` |
| **数据类型** | integer → 整数，千分位整数 |
| **数据格式** | `#,##0` |

### 1.1 VIC No. vs LY — VIC数量同比（趋势）

| 项目 | 内容 |
|---|---|
| **指标名称** | VIC No. vs LY |
| **指标名称中文** | VIC数量同比 |
| **业务定义** | VIC数量今年较去年同期的变化率 |
| **计算公式** | 今年 / 去年 - 1 |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `is_vic = 1`；人群细分：TTL VIC `is_member = 0` / Member VIC `is_member = 1` / Is Employee `is_employee = 1` |
| **聚合粒度** | 根据所选 timeframe：Month → `dt = 选择时间范围的每个月`；Quarter → `dt = 所选时间范围每季的最后一个财月`；Year → `dt = 所选时间范围每年的最后一个财月`；`platform, shop_info_id` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

### 1.2 VIC No. vs LP — VIC数量环比（趋势）

| 项目 | 内容 |
|---|---|
| **指标名称** | VIC No. vs LP |
| **指标名称中文** | VIC数量环比 |
| **业务定义** | VIC数量当期较上期的变化率 |
| **计算公式** | 当期 / 上期 - 1 |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `is_vic = 1`；人群细分：TTL VIC `is_member = 0` / Member VIC `is_member = 1` / Is Employee `is_employee = 1` |
| **聚合粒度** | 根据所选 timeframe：Month → `dt = 选择时间范围的每个月`；Quarter → `dt = 所选时间范围每季的最后一个财月`；Year → `dt = 所选时间范围每年的最后一个财月`；`platform, shop_info_id` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

---

### 2. VIC Retention% — VIC留存率（趋势）

| 项目 | 内容 |
|---|---|
| **指标名称** | VIC Retention% |
| **指标名称中文** | VIC留存率 |
| **业务定义** | 在指定日期范围仍为 VIC 且上一周期也是 VIC 的人数/上一周期 VIC 人数 |
| **计算公式** | 分子：count(distinct user_id) where is_retention_vic = 1；分母：所选时间范围 end period 往前 Rolling 12 个财月 count(distinct user_id) where is_vic = 1 |
| **分子** | `user_id`（`is_retention_vic = 1`） |
| **分母** | `user_id`（上周期 `is_vic = 1`） |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | 人群细分：TTL VIC `is_member = 0` / Member VIC `is_member = 1` / Is Employee `is_employee = 1` |
| **聚合粒度** | 根据所选 timeframe：Month → `dt = 选择时间范围的每个月`；Quarter → `dt = 所选时间范围每季的最后一个财月`；Year → `dt = 所选时间范围每年的最后一个财月`；`platform, shop_info_id` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

### 2.1 VIC Retention% vs LY — VIC留存率同比（趋势）

| 项目 | 内容 |
|---|---|
| **指标名称** | VIC Retention% vs LY |
| **指标名称中文** | VIC留存率同比 |
| **业务定义** | VIC留存率今年较去年同期的变化（差值） |
| **计算公式** | 今年 - 去年（差值，展示时 ×100 转 pts） |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | 人群细分：TTL VIC `is_member = 0` / Member VIC `is_member = 1` / Is Employee `is_employee = 1` |
| **聚合粒度** | 根据所选 timeframe：Month → `dt = 选择时间范围的每个月`；Quarter → `dt = 所选时间范围每季的最后一个财月`；Year → `dt = 所选时间范围每年的最后一个财月`；`platform, shop_info_id` |
| **数据类型** | delta_pts → 增减基点整数： → +120pts / -80pts（基点，含正负号，值×100 转 pts）,乘以100的操作可以放在Cell Display度量中实现，算同比LY：当期值 − 同期值（差值，pts 指标，展示时 ×100 转 pts） |        
| **数据格式** | `+#,##0pts;-#,##0pts;0pts` |

### 2.2 VIC Retention% vs LP — VIC留存率环比（趋势）

| 项目 | 内容 |
|---|---|
| **指标名称** | VIC Retention% vs LP |
| **指标名称中文** | VIC留存率环比 |
| **业务定义** | VIC留存率当期较上期的变化（差值） |
| **计算公式** | 当期 - 上期（差值，展示时 ×100 转 pts） |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | 人群细分：TTL VIC `is_member = 0` / Member VIC `is_member = 1` / Is Employee `is_employee = 1` |
| **聚合粒度** | 根据所选 timeframe：Month → `dt = 选择时间范围的每个月`；Quarter → `dt = 所选时间范围每季的最后一个财月`；Year → `dt = 所选时间范围每年的最后一个财月`；`platform, shop_info_id` |
| **数据类型** | delta_pts → 增减基点整数： → +120pts / -80pts（基点，含正负号，值×100 转 pts）,乘以100的操作可以放在Cell Display度量中实现，算环比LP：当期值 − 上期值（差值，pts 指标，展示时 ×100 转 pts） |        
| **数据格式** | `+#,##0pts;-#,##0pts;0pts` |

---

### 3. T4-5 Upgrade No. — T4-5升级为VIC人数（趋势）

| 项目 | 内容 |
|---|---|
| **指标名称** | T4-5 Upgrade No. |
| **指标名称中文** | T4-5升级为VIC人数 |
| **业务定义** | 上一周期为 T4/T5 且在指定日期范围内升级成为 VIC 的买家人数（T4：上一周期 net sales 为 5-20K 的买家；T5：上一周期 net sales < 5K 的买家） |
| **计算公式** | count(distinct user_id) |
| **统计字段** | `user_id` |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `is_upgrade_vic = 1`；人群细分：TTL VIC `is_member = 0` / Member VIC `is_member = 1` / Is Employee `is_employee = 1` |
| **聚合粒度** | 根据所选 timeframe：Month → `dt = 选择时间范围的每个月`；Quarter → `dt = 所选时间范围每季的最后一个财月`；Year → `dt = 所选时间范围每年的最后一个财月`；`platform, shop_info_id` |
| **数据类型** | integer → 整数，千分位整数 |
| **数据格式** | `#,##0` |

### 3.1 T4-5 Upgrade No. vs LY — T4-5升级为VIC人数同比（趋势）

| 项目 | 内容 |
|---|---|
| **指标名称** | T4-5 Upgrade No. vs LY |
| **指标名称中文** | T4-5升级为VIC人数同比 |
| **业务定义** | T4-5升级为VIC人数今年较去年同期的变化率 |
| **计算公式** | 今年 / 去年 - 1 |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `is_upgrade_vic = 1`；人群细分：TTL VIC `is_member = 0` / Member VIC `is_member = 1` / Is Employee `is_employee = 1` |
| **聚合粒度** | 根据所选 timeframe：Month → `dt = 选择时间范围的每个月`；Quarter → `dt = 所选时间范围每季的最后一个财月`；Year → `dt = 所选时间范围每年的最后一个财月`；`platform, shop_info_id` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

### 3.2 T4-5 Upgrade No. vs LP — T4-5升级为VIC人数环比（趋势）

| 项目 | 内容 |
|---|---|
| **指标名称** | T4-5 Upgrade No. vs LP |
| **指标名称中文** | T4-5升级为VIC人数环比 |
| **业务定义** | T4-5升级为VIC人数当期较上期的变化率 |
| **计算公式** | 当期 / 上期 - 1 |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `is_upgrade_vic = 1`；人群细分：TTL VIC `is_member = 0` / Member VIC `is_member = 1` / Is Employee `is_employee = 1` |
| **聚合粒度** | 根据所选 timeframe：Month → `dt = 选择时间范围的每个月`；Quarter → `dt = 所选时间范围每季的最后一个财月`；Year → `dt = 所选时间范围每年的最后一个财月`；`platform, shop_info_id` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

### 3.3 T4-5 Upgrade% — T4-5升级率（趋势，附属指标）

| 项目 | 内容 |
|---|---|
| **指标名称** | T4-5 Upgrade% |
| **指标名称中文** | T4-5升级率 |
| **业务定义** | T4-5 升级为 VIC 的人数占 VIC 总人数的比例 |
| **计算公式** | 分子：count(distinct user_id) where is_upgrade_vic = 1；分母：count(distinct user_id) where is_vic = 1 |
| **分子** | `user_id`（`is_upgrade_vic = 1`） |
| **分母** | `user_id`（`is_vic = 1`） |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | 人群细分：TTL VIC `is_member = 0` / Member VIC `is_member = 1` / Is Employee `is_employee = 1` |
| **聚合粒度** | 根据所选 timeframe：Month → `dt = 选择时间范围的每个月`；Quarter → `dt = 所选时间范围每季的最后一个财月`；Year → `dt = 所选时间范围每年的最后一个财月`；`platform, shop_info_id` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

---

## 子模块三：VIC Composition & By Recency Repurchase

> **分组维度**: 按 `platform, shop_info_id` 分组；按 Recency 分层（R3 / R4-6 / R7-9 / R10-12 / TTL）

### 1. Retention VIC No. — 留存VIC人数

| 项目 | 内容 |
|---|---|
| **指标名称** | Retention VIC No. |
| **指标名称中文** | 留存VIC人数 |
| **业务定义** | 在指定日期范围仍为 VIC 且上一周期也是 VIC 的人数 |
| **计算公式** | count(distinct user_id) |
| **统计字段** | `user_id` |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `is_retention_vic = 1`；人群细分：TTL VIC `is_member = 0` / Member VIC `is_member = 1` / Is Employee `is_employee = 1` |
| **聚合粒度** | `dt = 所选时间范围 end period`，`platform, shop_info_id` |
| **数据类型** | integer → 整数，千分位整数 |
| **数据格式** | `#,##0` |

### 1.1 Retention VIC No. vs LY — 留存VIC人数同比

| 项目 | 内容 |
|---|---|
| **指标名称** | Retention VIC No. vs LY |
| **指标名称中文** | 留存VIC人数同比 |
| **业务定义** | 留存VIC人数今年较去年同期的变化率 |
| **计算公式** | 今年 / 去年 - 1 |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `is_retention_vic = 1`；人群细分：TTL VIC `is_member = 0` / Member VIC `is_member = 1` / Is Employee `is_employee = 1` |
| **聚合粒度** | `dt = 所选时间范围 end period`，`platform, shop_info_id` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

### 1.2 Retention VIC No. vs LP — 留存VIC人数环比

| 项目 | 内容 |
|---|---|
| **指标名称** | Retention VIC No. vs LP |
| **指标名称中文** | 留存VIC人数环比 |
| **业务定义** | 留存VIC人数当期较上期的变化率 |
| **计算公式** | 当期 / 上期 - 1 |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `is_retention_vic = 1`；人群细分：TTL VIC `is_member = 0` / Member VIC `is_member = 1` / Is Employee `is_employee = 1` |
| **聚合粒度** | `dt = 所选时间范围 end period`，`platform, shop_info_id` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

### 1.3 Retention VIC占比 — 留存VIC占比

| 项目 | 内容 |
|---|---|
| **指标名称** | Retention VIC占比 |
| **指标名称中文** | 留存VIC占比 |
| **业务定义** | 留存VIC人数占VIC总人数的比例 |
| **计算公式** | 分子：count(distinct user_id) where is_retention_vic = 1；分母：count(distinct user_id) where is_vic = 1 |
| **分子** | `user_id`（`is_retention_vic = 1`） |
| **分母** | `user_id`（`is_vic = 1`） |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | 人群细分：TTL VIC `is_member = 0` / Member VIC `is_member = 1` / Is Employee `is_employee = 1` |
| **聚合粒度** | `dt = 所选时间范围 end period`，`platform, shop_info_id` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

### 1.4 Retention VIC占比 vs LY — 留存VIC占比同比

| 项目 | 内容 |
|---|---|
| **指标名称** | Retention VIC占比 vs LY |
| **指标名称中文** | 留存VIC占比同比 |
| **业务定义** | 留存VIC占比今年较去年同期的变化（差值） |
| **计算公式** | 今年 - 去年（差值，展示时 ×100 转 pts） |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | 人群细分：TTL VIC `is_member = 0` / Member VIC `is_member = 1` / Is Employee `is_employee = 1` |
| **聚合粒度** | `dt = 所选时间范围 end period`，`platform, shop_info_id` |
| **数据类型** | delta_pts → 增减基点整数： → +120pts / -80pts（基点，含正负号，值×100 转 pts）,乘以100的操作可以放在Cell Display度量中实现，算同比LY：当期值 − 同期值（差值，pts 指标，展示时 ×100 转 pts） |        
| **数据格式** | `+#,##0pts;-#,##0pts;0pts` |

### 1.5 Retention VIC占比 vs LP — 留存VIC占比环比

| 项目 | 内容 |
|---|---|
| **指标名称** | Retention VIC占比 vs LP |
| **指标名称中文** | 留存VIC占比环比 |
| **业务定义** | 留存VIC占比当期较上期的变化（差值） |
| **计算公式** | 当期 - 上期（差值，展示时 ×100 转 pts） |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | 人群细分：TTL VIC `is_member = 0` / Member VIC `is_member = 1` / Is Employee `is_employee = 1` |
| **聚合粒度** | `dt = 所选时间范围 end period`，`platform, shop_info_id` |
| **数据类型** | delta_pts → 增减基点整数： → +120pts / -80pts（基点，含正负号，值×100 转 pts）,乘以100的操作可以放在Cell Display度量中实现，算环比LP：当期值 − 上期值（差值，pts 指标，展示时 ×100 转 pts） |        
| **数据格式** | `+#,##0pts;-#,##0pts;0pts` |

---

### 2. T4-5 Upgrade No. — T4-5升级为VIC人数

| 项目 | 内容 |
|---|---|
| **指标名称** | T4-5 Upgrade No. |
| **指标名称中文** | T4-5升级为VIC人数 |
| **业务定义** | 上一周期为 T4/T5 且在指定日期范围内升级成为 VIC 的买家人数（T4：上一周期 net sales 为 5-20K 的买家；T5：上一周期 net sales < 5K 的买家） |
| **计算公式** | count(distinct user_id) |
| **统计字段** | `user_id` |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `is_upgrade_vic = 1`；人群细分：TTL VIC `is_member = 0` / Member VIC `is_member = 1` / Is Employee `is_employee = 1` |
| **聚合粒度** | `dt = 所选时间范围 end period`，`platform, shop_info_id` |
| **数据类型** | integer → 整数，千分位整数 |
| **数据格式** | `#,##0` |

### 2.1 T4-5 Upgrade No. vs LY — T4-5升级为VIC人数同比

| 项目 | 内容 |
|---|---|
| **指标名称** | T4-5 Upgrade No. vs LY |
| **指标名称中文** | T4-5升级为VIC人数同比 |
| **业务定义** | T4-5升级为VIC人数今年较去年同期的变化率 |
| **计算公式** | 今年 / 去年 - 1 |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `is_upgrade_vic = 1`；人群细分：TTL VIC `is_member = 0` / Member VIC `is_member = 1` / Is Employee `is_employee = 1` |
| **聚合粒度** | `dt = 所选时间范围 end period`，`platform, shop_info_id` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

### 2.2 T4-5 Upgrade No. vs LP — T4-5升级为VIC人数环比

| 项目 | 内容 |
|---|---|
| **指标名称** | T4-5 Upgrade No. vs LP |
| **指标名称中文** | T4-5升级为VIC人数环比 |
| **业务定义** | T4-5升级为VIC人数当期较上期的变化率 |
| **计算公式** | 当期 / 上期 - 1 |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `is_upgrade_vic = 1`；人群细分：TTL VIC `is_member = 0` / Member VIC `is_member = 1` / Is Employee `is_employee = 1` |
| **聚合粒度** | `dt = 所选时间范围 end period`，`platform, shop_info_id` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

### 2.3 T4-5 Upgrade占比 — T4-5升级占比

| 项目 | 内容 |
|---|---|
| **指标名称** | T4-5 Upgrade占比 |
| **指标名称中文** | T4-5升级占比 |
| **业务定义** | T4-5 升级为 VIC 的人数占 VIC 总人数的比例 |
| **计算公式** | 分子：count(distinct user_id) where is_upgrade_vic = 1；分母：count(distinct user_id) where is_vic = 1 |
| **分子** | `user_id`（`is_upgrade_vic = 1`） |
| **分母** | `user_id`（`is_vic = 1`） |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | 人群细分：TTL VIC `is_member = 0` / Member VIC `is_member = 1` / Is Employee `is_employee = 1` |
| **聚合粒度** | `dt = 所选时间范围 end period`，`platform, shop_info_id` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

### 2.4 T4-5 Upgrade占比 vs LY — T4-5升级占比同比

| 项目 | 内容 |
|---|---|
| **指标名称** | T4-5 Upgrade占比 vs LY |
| **指标名称中文** | T4-5升级占比同比 |
| **业务定义** | T4-5升级占比今年较去年同期的变化（差值） |
| **计算公式** | 今年 - 去年（差值，展示时 ×100 转 pts） |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | 人群细分：TTL VIC `is_member = 0` / Member VIC `is_member = 1` / Is Employee `is_employee = 1` |
| **聚合粒度** | `dt = 所选时间范围 end period`，`platform, shop_info_id` |
| **数据类型** | delta_pts → 增减基点整数： → +120pts / -80pts（基点，含正负号，值×100 转 pts）,乘以100的操作可以放在Cell Display度量中实现，算同比LY：当期值 − 同期值（差值，pts 指标，展示时 ×100 转 pts） |        
| **数据格式** | `+#,##0pts;-#,##0pts;0pts` |

### 2.5 T4-5 Upgrade占比 vs LP — T4-5升级占比环比

| 项目 | 内容 |
|---|---|
| **指标名称** | T4-5 Upgrade占比 vs LP |
| **指标名称中文** | T4-5升级占比环比 |
| **业务定义** | T4-5升级占比当期较上期的变化（差值） |
| **计算公式** | 当期 - 上期（差值，展示时 ×100 转 pts） |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | 人群细分：TTL VIC `is_member = 0` / Member VIC `is_member = 1` / Is Employee `is_employee = 1` |
| **聚合粒度** | `dt = 所选时间范围 end period`，`platform, shop_info_id` |
| **数据类型** | delta_pts → 增减基点整数： → +120pts / -80pts（基点，含正负号，值×100 转 pts）,乘以100的操作可以放在Cell Display度量中实现，算环比LP：当期值 − 上期值（差值，pts 指标，展示时 ×100 转 pts） |        
| **数据格式** | `+#,##0pts;-#,##0pts;0pts` |

---

### 3. Direct VIC No. — 直接买成VIC人数

| 项目 | 内容 |
|---|---|
| **指标名称** | Direct VIC No. |
| **指标名称中文** | 直接买成VIC人数 |
| **业务定义** | 在指定日期范围往前 Rolling 12 个财月，net sales >= 20k 且在上一周期不是 VIC 的买家数量 |
| **计算公式** | count(distinct user_id) |
| **统计字段** | `user_id` |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `is_direct_vic = 1`；人群细分：TTL VIC `is_member = 0` / Member VIC `is_member = 1` / Is Employee `is_employee = 1` |
| **聚合粒度** | `dt = 所选时间范围 end period`，`platform, shop_info_id` |
| **数据类型** | integer → 整数，千分位整数 |
| **数据格式** | `#,##0` |

### 3.1 Direct VIC No. vs LY — 直接买成VIC人数同比

| 项目 | 内容 |
|---|---|
| **指标名称** | Direct VIC No. vs LY |
| **指标名称中文** | 直接买成VIC人数同比 |
| **业务定义** | 直接买成VIC人数今年较去年同期的变化率 |
| **计算公式** | 今年 / 去年 - 1 |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `is_direct_vic = 1`；人群细分：TTL VIC `is_member = 0` / Member VIC `is_member = 1` / Is Employee `is_employee = 1` |
| **聚合粒度** | `dt = 所选时间范围 end period`，`platform, shop_info_id` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

### 3.2 Direct VIC No. vs LP — 直接买成VIC人数环比

| 项目 | 内容 |
|---|---|
| **指标名称** | Direct VIC No. vs LP |
| **指标名称中文** | 直接买成VIC人数环比 |
| **业务定义** | 直接买成VIC人数当期较上期的变化率 |
| **计算公式** | 当期 / 上期 - 1 |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `is_direct_vic = 1`；人群细分：TTL VIC `is_member = 0` / Member VIC `is_member = 1` / Is Employee `is_employee = 1` |
| **聚合粒度** | `dt = 所选时间范围 end period`，`platform, shop_info_id` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

### 3.3 Direct VIC占比 — 直接买成VIC占比

| 项目 | 内容 |
|---|---|
| **指标名称** | Direct VIC占比 |
| **指标名称中文** | 直接买成VIC占比 |
| **业务定义** | 直接买成VIC人数占VIC总人数的比例 |
| **计算公式** | 分子：count(distinct user_id) where is_direct_vic = 1；分母：count(distinct user_id) where is_vic = 1 |
| **分子** | `user_id`（`is_direct_vic = 1`） |
| **分母** | `user_id`（`is_vic = 1`） |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | 人群细分：TTL VIC `is_member = 0` / Member VIC `is_member = 1` / Is Employee `is_employee = 1` |
| **聚合粒度** | `dt = 所选时间范围 end period`，`platform, shop_info_id` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

### 3.4 Direct VIC占比 vs LY — 直接买成VIC占比同比

| 项目 | 内容 |
|---|---|
| **指标名称** | Direct VIC占比 vs LY |
| **指标名称中文** | 直接买成VIC占比同比 |
| **业务定义** | 直接买成VIC占比今年较去年同期的变化（差值） |
| **计算公式** | 今年 - 去年（差值，展示时 ×100 转 pts） |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | 人群细分：TTL VIC `is_member = 0` / Member VIC `is_member = 1` / Is Employee `is_employee = 1` |
| **聚合粒度** | `dt = 所选时间范围 end period`，`platform, shop_info_id` |
| **数据类型** | delta_pts → 增减基点整数： → +120pts / -80pts（基点，含正负号，值×100 转 pts）,乘以100的操作可以放在Cell Display度量中实现，算同比LY：当期值 − 同期值（差值，pts 指标，展示时 ×100 转 pts） |        
| **数据格式** | `+#,##0pts;-#,##0pts;0pts` |

### 3.5 Direct VIC占比 vs LP — 直接买成VIC占比环比

| 项目 | 内容 |
|---|---|
| **指标名称** | Direct VIC占比 vs LP |
| **指标名称中文** | 直接买成VIC占比环比 |
| **业务定义** | 直接买成VIC占比当期较上期的变化（差值） |
| **计算公式** | 当期 - 上期（差值，展示时 ×100 转 pts） |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | 人群细分：TTL VIC `is_member = 0` / Member VIC `is_member = 1` / Is Employee `is_employee = 1` |
| **聚合粒度** | `dt = 所选时间范围 end period`，`platform, shop_info_id` |
| **数据类型** | delta_pts → 增减基点整数： → +120pts / -80pts（基点，含正负号，值×100 转 pts）,乘以100的操作可以放在Cell Display度量中实现，算环比LP：当期值 − 上期值（差值，pts 指标，展示时 ×100 转 pts） |        
| **数据格式** | `+#,##0pts;-#,##0pts;0pts` |

---

### 4. LY Last Purchase Time — 去年VIC最后一个订单的购买时间范围

| 项目 | 内容 |
|---|---|
| **指标名称** | LY Last Purchase Time |
| **指标名称中文** | 去年VIC最后一个订单的购买时间范围 |
| **业务定义** | R3：上财年 10-12 月；R4-6：上财年 7-9 月；R7-9：上财年 4-6 月；R10-12：上财年 1-3 月 |
| **计算公式** | 固定值：R3, R4-6, R7-9, R10-12, TTL |
| **数据底表** | 无（固定维度值） |
| **筛选条件** | 无 |
| **聚合粒度** | 无 |
| **数据类型** | text → 文本 |
| **数据格式** | 无 |

---

### 5. LY VIC No. — 去年VIC人数

| 项目 | 内容 |
|---|---|
| **指标名称** | LY VIC No. |
| **指标名称中文** | 去年VIC人数 |
| **业务定义** | R3：这一财年的 VIC，且上财年最后一单落在上财年 10-12 月的 VIC 人数；R4-6：这一财年的 VIC，且上财年最后一单落在上财年 7-9 月的 VIC 人数；R7-9：这一财年的 VIC，且上财年最后一单落在上财年 4-6 月的 VIC 人数；R10-12：这一财年的 VIC，且上财年最后一单落在上财年 1-3 月的 VIC 人数 |
| **计算公式** | Step 1：在 dt = 所选时间范围 end period，筛选 is_fy_vic = 1，框定 user_id 范围；Step 2：根据 last_fy_last_order_month_type，count(distinct user_id) |
| **统计字段** | `user_id`、`last_fy_last_order_month_type` |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | 人群细分：TTL VIC `is_member = 0` / Member VIC `is_member = 1` / Is Employee `is_employee = 1` |
| **聚合粒度** | `platform, shop_info_id` |
| **数据类型** | integer → 整数，千分位整数 |
| **数据格式** | `#,##0` |

---

### 6. Repurchase No. — 复购VIC人数

| 项目 | 内容 |
|---|---|
| **指标名称** | Repurchase No. |
| **指标名称中文** | 复购VIC人数 |
| **业务定义** | R3：这一财年的 VIC，且上财年最后一单落在上财年 10-12 月，并且所选时间范围 end period 往前推 12 个月有复购的 VIC 人数；R4-6：这一财年的 VIC，且上财年最后一单落在上财年 7-9 月，并且所选时间范围 end period 往前推 12 个月有复购的 VIC 人数；R7-9：这一财年的 VIC，且上财年最后一单落在上财年 4-6 月，并且所选时间范围 end period 往前推 12 个月有复购的 VIC 人数；R10-12：这一财年的 VIC，且上财年最后一单落在上财年 1-3 月，并且所选时间范围 end period 往前推 12 个月有复购的 VIC 人数 |
| **计算公式** | Step 1：在 dt = 所选时间范围 end period，筛选 is_fy_vic = 1，框定 user_id 范围；Step 2：用 step1 所框定的 user_id，统计 dt = 所选时间范围 end period 对应的 sum(last_12m_net_pay_amt)；Step 3：根据 last_fy_last_order_month_type，count(distinct user_id) where sum(last_12m_net_pay_amt) > 0 |
| **统计字段** | `user_id`、`last_fy_last_order_month_type`、`last_12m_net_pay_amt` |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | 人群细分：TTL VIC `is_member = 0` / Member VIC `is_member = 1` / Is Employee `is_employee = 1` |
| **聚合粒度** | `platform, shop_info_id` |
| **数据类型** | integer → 整数，千分位整数 |
| **数据格式** | `#,##0` |

---

### 7. Retention No. — 留存VIC人数

| 项目 | 内容 |
|---|---|
| **指标名称** | Retention No. |
| **指标名称中文** | 留存VIC人数 |
| **业务定义** | R3：这一财年的 VIC，且上财年最后一单落在上财年 10-12 月，并且所选时间范围 end period 往前推 12 个月留存为 VIC 的人数；R4-6：这一财年的 VIC，且上财年最后一单落在上财年 7-9 月，并且所选时间范围 end period 往前推 12 个月留存为 VIC 的人数；R7-9：这一财年的 VIC，且上财年最后一单落在上财年 4-6 月，并且所选时间范围 end period 往前推 12 个月留存为 VIC 的人数；R10-12：这一财年的 VIC，且上财年最后一单落在上财年 1-3 月，并且所选时间范围 end period 往前推 12 个月留存为 VIC 的人数 |
| **计算公式** | 根据 last_fy_last_order_month_type，count(distinct user_id) where is_fy_retention_vic = 1 |
| **统计字段** | `user_id`、`last_fy_last_order_month_type`、`is_fy_retention_vic` |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | 人群细分：TTL VIC `is_member = 0` / Member VIC `is_member = 1` / Is Employee `is_employee = 1` |
| **聚合粒度** | `platform, shop_info_id` |
| **数据类型** | integer → 整数，千分位整数 |
| **数据格式** | `#,##0` |

---

### 8. Repurchase% — 复购VIC占比

| 项目 | 内容 |
|---|---|
| **指标名称** | Repurchase% |
| **指标名称中文** | 复购VIC占比 |
| **业务定义** | 该分层下复购 VIC 人数/总 VIC 人数 |
| **计算公式** | 分子：Repurchase No.；分母：LY VIC No. |
| **分子** | Repurchase No. |
| **分母** | LY VIC No. |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | 人群细分：TTL VIC `is_member = 0` / Member VIC `is_member = 1` / Is Employee `is_employee = 1` |
| **聚合粒度** | `platform, shop_info_id` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

---

### 9. Repurchase% YOY — 复购VIC占比YOY

| 项目 | 内容 |
|---|---|
| **指标名称** | Repurchase% YOY |
| **指标名称中文** | 复购VIC占比YOY |
| **业务定义** | 该分层下复购率和去年的对比 |
| **计算公式** | 今年 / 去年 - 1 |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | 人群细分：TTL VIC `is_member = 0` / Member VIC `is_member = 1` / Is Employee `is_employee = 1` |
| **聚合粒度** | `platform, shop_info_id` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

---

### 10. Retention% — 留存VIC占比

| 项目 | 内容 |
|---|---|
| **指标名称** | Retention% |
| **指标名称中文** | 留存VIC占比 |
| **业务定义** | 该分层下留存 VIC 人数/总 VIC 人数 |
| **计算公式** | 分子：Retention No.；分母：LY VIC No. |
| **分子** | Retention No. |
| **分母** | LY VIC No. |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | 人群细分：TTL VIC `is_member = 0` / Member VIC `is_member = 1` / Is Employee `is_employee = 1` |
| **聚合粒度** | `platform, shop_info_id` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

---

### 11. Retention% YOY — 留存VIC占比YOY

| 项目 | 内容 |
|---|---|
| **指标名称** | Retention% YOY |
| **指标名称中文** | 留存VIC占比YOY |
| **业务定义** | 该分层下留存率和去年的对比 |
| **计算公式** | 今年 / 去年 - 1 |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | 人群细分：TTL VIC `is_member = 0` / Member VIC `is_member = 1` / Is Employee `is_employee = 1` |
| **聚合粒度** | `platform, shop_info_id` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

---

## 子模块四：VIC Segment

> **分组维度**: 按 `customer_tier`（T1/T2/T3/T4/T5）分组，固定值

### 0. Tier — 买家分层

| 项目 | 内容 |
|---|---|
| **指标名称** | Tier |
| **指标名称中文** | 买家分层 |
| **业务定义** | 买家分层，固定值：T1：≧ 200K；T2：80-200K；T3：20-80K；T4：5-20K；T5：< 5K |
| **计算公式** | 固定值 |
| **数据底表** | 无（固定维度值） |
| **筛选条件** | 无 |
| **聚合粒度** | 无 |
| **数据类型** | text → 文本 |
| **数据格式** | 无 |

---

### 1. Customer No. — 买家人数

| 项目 | 内容 |
|---|---|
| **指标名称** | Customer No. |
| **指标名称中文** | 买家人数 |
| **业务定义** | 该分层下买家人数 |
| **计算公式** | count(distinct user_id) |
| **统计字段** | `user_id` |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `customer_tier = T1/T2/T3/T4/T5`；人群细分：TTL VIC `is_member = 0` / Member VIC `is_member = 1` / Is Employee `is_employee = 1` |
| **聚合粒度** | `dt = 所选时间范围 end period`，`platform, shop_info_id` |
| **数据类型** | integer → 整数，千分位整数 |
| **数据格式** | `#,##0` |

---

### 2. Customer No. vs. LY — 买家人数YOY

| 项目 | 内容 |
|---|---|
| **指标名称** | Customer No. vs. LY |
| **指标名称中文** | 买家人数YOY |
| **业务定义** | 该分层下买家人数和去年的对比 |
| **计算公式** | 今年 / 去年 - 1 |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `customer_tier = T1/T2/T3/T4/T5`；人群细分：TTL VIC `is_member = 0` / Member VIC `is_member = 1` / Is Employee `is_employee = 1` |
| **聚合粒度** | `dt = 所选时间范围 end period`，`platform, shop_info_id` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

---

### 3. % of Total — 买家人数占比

| 项目 | 内容 |
|---|---|
| **指标名称** | % of Total |
| **指标名称中文** | 买家人数占比 |
| **业务定义** | 该分层下买家人数/总买家数量 |
| **计算公式** | 分子：count(distinct user_id) where customer_tier = T1/T2/T3/T4/T5；分母：count(distinct user_id) where sum(net_pay_amt) > 0 |
| **分子** | `user_id`（`customer_tier = T1/T2/T3/T4/T5`） |
| **分母** | `user_id`（`sum(net_pay_amt) > 0`） |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | 人群细分：TTL VIC `is_member = 0` / Member VIC `is_member = 1` / Is Employee `is_employee = 1` |
| **聚合粒度** | `dt = 所选时间范围 end period`，`platform, shop_info_id` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

---

### 4. Customer% vs. LY — 买家人数占比YOY

| 项目 | 内容 |
|---|---|
| **指标名称** | Customer% vs. LY |
| **指标名称中文** | 买家人数占比YOY |
| **业务定义** | 该分层下买家人数占比和去年的对比 |
| **计算公式** | 今年 / 去年 - 1 |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `customer_tier = T1/T2/T3/T4/T5`；人群细分：TTL VIC `is_member = 0` / Member VIC `is_member = 1` / Is Employee `is_employee = 1` |
| **聚合粒度** | `dt = 所选时间范围 end period`，`platform, shop_info_id` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

---

### 5. SLS (in K) — 净销售额

| 项目 | 内容 |
|---|---|
| **指标名称** | SLS (in K) |
| **指标名称中文** | 净销售额 |
| **业务定义** | 该分层下买家净销售额 |
| **计算公式** | Step 1：在 dt = 所选时间范围 end period，筛选 customer_tier = T1/T2/T3/T4/T5，框定 user_id 范围；Step 2：再看该 user_id 在所选时间范围对应的 sum(net_pay_amt) |
| **统计字段** | `net_pay_amt`、`customer_tier` |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | 人群细分：TTL VIC `is_member = 0` / Member VIC `is_member = 1` / Is Employee `is_employee = 1` |
| **聚合粒度** | `platform, shop_info_id` |
| **数据类型** | currency → 货币符号由币种切片器决定，千分位整数 |
| **数据格式** | `#,##0`（在 DAX 中用 `__CurrencySymbol & FORMAT(__Value, "#,##0")` 拼接币种符号） |

---

### 6. SLS vs. LY — 净销售额YOY

| 项目 | 内容 |
|---|---|
| **指标名称** | SLS vs. LY |
| **指标名称中文** | 净销售额YOY |
| **业务定义** | 该分层下买家净销售额和去年的对比 |
| **计算公式** | 今年 / 去年 - 1 |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `customer_tier = T1/T2/T3/T4/T5`；人群细分：TTL VIC `is_member = 0` / Member VIC `is_member = 1` / Is Employee `is_employee = 1` |
| **聚合粒度** | `dt = 所选时间范围 end period`，`platform, shop_info_id` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

---

### 7. % of Total — 净销售额占比

| 项目 | 内容 |
|---|---|
| **指标名称** | % of Total |
| **指标名称中文** | 净销售额占比 |
| **业务定义** | 该分层下买家净销售额/总买家净销售额 |
| **计算公式** | 分子：Step 1 在 dt = 所选时间范围 end period，筛选 customer_tier = T1/T2/T3/T4/T5，框定 user_id 范围；Step 2 再看该 user_id 在所选时间范围对应的 sum(net_pay_amt)。分母：所选时间范围对应的 sum(net_pay_amt) |
| **分子** | `net_pay_amt`（`customer_tier = T1/T2/T3/T4/T5`） |
| **分母** | `net_pay_amt`（全部） |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | 人群细分：TTL VIC `is_member = 0` / Member VIC `is_member = 1` / Is Employee `is_employee = 1` |
| **聚合粒度** | `platform, shop_info_id` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

---

### 8. SLS % vs. LY — 净销售额占比YOY

| 项目 | 内容 |
|---|---|
| **指标名称** | SLS % vs. LY |
| **指标名称中文** | 净销售额占比YOY |
| **业务定义** | 该分层下买家净销售额占比和去年的对比 |
| **计算公式** | 今年 / 去年 - 1 |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `customer_tier = T1/T2/T3/T4/T5`；人群细分：TTL VIC `is_member = 0` / Member VIC `is_member = 1` / Is Employee `is_employee = 1` |
| **聚合粒度** | `platform, shop_info_id` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

---

### 9. ACV — 客单价

| 项目 | 内容 |
|---|---|
| **指标名称** | ACV |
| **指标名称中文** | 客单价 |
| **业务定义** | 该分层下净销售金额/净购买买家人数 |
| **计算公式** | 分子：SLS（Step 1 在 dt = 所选时间范围 end period，筛选 customer_tier = T1/T2/T3/T4/T5，框定 user_id 范围；Step 2 再看该 user_id 在所选时间范围对应的 sum(net_pay_amt)）；分母：dt = 所选时间范围 end period，筛选 customer_tier = T1/T2/T3/T4/T5，count(distinct user_id) |
| **分子** | `net_pay_amt`（分层） |
| **分母** | `user_id`（分层） |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | 人群细分：TTL VIC `is_member = 0` / Member VIC `is_member = 1` / Is Employee `is_employee = 1` |
| **聚合粒度** | `platform, shop_info_id` |
| **数据类型** | currency → 货币符号由币种切片器决定，千分位整数 |
| **数据格式** | `#,##0`（在 DAX 中用 `__CurrencySymbol & FORMAT(__Value, "#,##0")` 拼接币种符号） |

---

### 10. AUR — 件单价

| 项目 | 内容 |
|---|---|
| **指标名称** | AUR |
| **指标名称中文** | 件单价 |
| **业务定义** | 该分层下净销售金额/商品净出库件数 |
| **计算公式** | 分子：Step 1 在 dt = 所选时间范围 end period，筛选 customer_tier = T1/T2/T3/T4/T5，框定 user_id 范围；Step 2 再看该 user_id 在所选时间范围对应的 sum(net_pay_amt)。分母：Step 1 在 dt = 所选时间范围 end period，筛选 customer_tier = T1/T2/T3/T4/T5，框定 user_id 范围；Step 2 再看该 user_id 在所选时间范围对应的 sum(net_pay_qty) |
| **分子** | `net_pay_amt`（分层） |
| **分母** | `net_pay_qty`（分层） |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | 人群细分：TTL VIC `is_member = 0` / Member VIC `is_member = 1` / Is Employee `is_employee = 1` |
| **聚合粒度** | `platform, shop_info_id` |
| **数据类型** | currency → 货币符号由币种切片器决定，千分位整数 |
| **数据格式** | `#,##0`（在 DAX 中用 `__CurrencySymbol & FORMAT(__Value, "#,##0")` 拼接币种符号） |

---

### 11. UPT — 客单件

| 项目 | 内容 |
|---|---|
| **指标名称** | UPT |
| **指标名称中文** | 客单件 |
| **业务定义** | 该分层下商品净出库件数/净出库订单数 |
| **计算公式** | 分子：Step 1 在 dt = 所选时间范围 end period，筛选 customer_tier = T1/T2/T3/T4/T5，框定 user_id 范围；Step 2 再看该 user_id 在所选时间范围对应的 sum(net_pay_qty)。分母：Step 1 在 dt = 所选时间范围 end period，筛选 customer_tier = T1/T2/T3/T4/T5，框定 user_id 范围；Step 2 再看该 user_id 在所选时间范围对应的 sum(net_pay_order_cnt) |
| **分子** | `net_pay_qty`（分层） |
| **分母** | `net_pay_order_cnt`（分层） |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | 人群细分：TTL VIC `is_member = 0` / Member VIC `is_member = 1` / Is Employee `is_employee = 1` |
| **聚合粒度** | `platform, shop_info_id` |
| **数据类型** | decimal_1dp → 小数，保留一位小数，千分位 |
| **数据格式** | `#,##0.0` |

---

### 12. Freq. — 购买频次

| 项目 | 内容 |
|---|---|
| **指标名称** | Freq. |
| **指标名称中文** | 购买频次 |
| **业务定义** | 该分层下净订单数/净购买买家人数 |
| **计算公式** | 分子：Step 1 在 dt = 所选时间范围 end period，筛选 customer_tier = T1/T2/T3/T4/T5，框定 user_id 范围；Step 2 再看该 user_id 在所选时间范围对应的 sum(net_pay_order_cnt)。分母：dt = 所选时间范围 end period，筛选 customer_tier = T1/T2/T3/T4/T5，count(distinct user_id) |
| **分子** | `net_pay_order_cnt`（分层） |
| **分母** | `user_id`（分层） |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | 人群细分：TTL VIC `is_member = 0` / Member VIC `is_member = 1` / Is Employee `is_employee = 1` |
| **聚合粒度** | `platform, shop_info_id` |
| **数据类型** | decimal_1dp → 小数，保留一位小数，千分位 |
| **数据格式** | `#,##0.0` |

---

## 子模块五：DCom VIC Breakdown

> **分组维度**: 按 VIC 类型（New VIC / Retention VIC）区分，按 `platform, shop_info_id` 分组

### 1. SLS（Net_New VIC） — 净销售额

| 项目 | 内容 |
|---|---|
| **指标名称** | SLS |
| **指标名称中文** | 净销售额 |
| **业务定义** | New VIC 买家净销售额 |
| **计算公式** | Step 1：在 dt = 所选时间范围 end period，筛选 is_new_vic = 1，框定 user_id 范围；Step 2：再看该 user_id 在所选时间范围对应的 sum(net_pay_amt) |
| **统计字段** | `net_pay_amt`、`is_new_vic` |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | 人群细分：TTL VIC `is_member = 0` / Member VIC `is_member = 1` / Is Employee `is_employee = 1` |
| **聚合粒度** | `platform, shop_info_id` |
| **数据类型** | currency → 货币符号由币种切片器决定，千分位整数 |
| **数据格式** | `#,##0`（在 DAX 中用 `__CurrencySymbol & FORMAT(__Value, "#,##0")` 拼接币种符号） |

### 1.1 SLS vs LY（Net_New VIC） — 净销售额同比

| 项目 | 内容 |
|---|---|
| **指标名称** | SLS vs LY |
| **指标名称中文** | 净销售额同比 |
| **业务定义** | New VIC 买家净销售额今年较去年同期的变化率 |
| **计算公式** | 今年 / 去年 - 1 |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `is_new_vic = 1`；人群细分：TTL VIC `is_member = 0` / Member VIC `is_member = 1` / Is Employee `is_employee = 1` |
| **聚合粒度** | `platform, shop_info_id` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

### 1.2 SLS vs LP（Net_New VIC） — 净销售额环比

| 项目 | 内容 |
|---|---|
| **指标名称** | SLS vs LP |
| **指标名称中文** | 净销售额环比 |
| **业务定义** | New VIC 买家净销售额当期较上期的变化率 |
| **计算公式** | 当期 / 上期 - 1 |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `is_new_vic = 1`；人群细分：TTL VIC `is_member = 0` / Member VIC `is_member = 1` / Is Employee `is_employee = 1` |
| **聚合粒度** | `platform, shop_info_id` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

---

### 2. SLS%（Net_New VIC） — 净销售额占比

| 项目 | 内容 |
|---|---|
| **指标名称** | SLS% |
| **指标名称中文** | 净销售额占比 |
| **业务定义** | New VIC 买家净销售额/总买家净销售额 |
| **计算公式** | 分子：Step 1 在 dt = 所选时间范围 end period，筛选 is_new_vic = 1，框定 user_id 范围；Step 2 再看该 user_id 在所选时间范围对应的 sum(net_pay_amt)。分母：所选时间范围对应的 sum(net_pay_amt) |
| **分子** | `net_pay_amt`（`is_new_vic = 1`） |
| **分母** | `net_pay_amt`（全部） |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | 人群细分：TTL VIC `is_member = 0` / Member VIC `is_member = 1` / Is Employee `is_employee = 1` |
| **聚合粒度** | `platform, shop_info_id` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

### 2.1 SLS% vs LY（Net_New VIC） — 净销售额占比同比

| 项目 | 内容 |
|---|---|
| **指标名称** | SLS% vs LY |
| **指标名称中文** | 净销售额占比同比 |
| **业务定义** | New VIC 买家净销售额占比今年较去年同期的变化（差值） |
| **计算公式** | 今年 - 去年（差值，展示时 ×100 转 pts） |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | 人群细分：TTL VIC `is_member = 0` / Member VIC `is_member = 1` / Is Employee `is_employee = 1` |
| **聚合粒度** | `platform, shop_info_id` |
| **数据类型** | delta_pts → 增减基点整数： → +120pts / -80pts（基点，含正负号，值×100 转 pts）,乘以100的操作可以放在Cell Display度量中实现，算同比LY：当期值 − 同期值（差值，pts 指标，展示时 ×100 转 pts） |        
| **数据格式** | `+#,##0pts;-#,##0pts;0pts` |

### 2.2 SLS% vs LP（Net_New VIC） — 净销售额占比环比

| 项目 | 内容 |
|---|---|
| **指标名称** | SLS% vs LP |
| **指标名称中文** | 净销售额占比环比 |
| **业务定义** | New VIC 买家净销售额占比当期较上期的变化（差值） |
| **计算公式** | 当期 - 上期（差值，展示时 ×100 转 pts） |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | 人群细分：TTL VIC `is_member = 0` / Member VIC `is_member = 1` / Is Employee `is_employee = 1` |
| **聚合粒度** | `platform, shop_info_id` |
| **数据类型** | delta_pts → 增减基点整数： → +120pts / -80pts（基点，含正负号，值×100 转 pts）,乘以100的操作可以放在Cell Display度量中实现，算环比LP：当期值 − 上期值（差值，pts 指标，展示时 ×100 转 pts） |        
| **数据格式** | `+#,##0pts;-#,##0pts;0pts` |

---

### 3. ACV（Net_New VIC） — 客单价

| 项目 | 内容 |
|---|---|
| **指标名称** | ACV |
| **指标名称中文** | 客单价 |
| **业务定义** | New VIC 净销售金额/净购买买家人数 |
| **计算公式** | 分子：SLS（Step 1 在 dt = 所选时间范围 end period，筛选 is_new_vic = 1，框定 user_id 范围；Step 2 再看该 user_id 在所选时间范围对应的 sum(net_pay_amt)）；分母：dt = 所选时间范围 end period，筛选 is_new_vic = 1，count(distinct user_id) |
| **分子** | `net_pay_amt`（`is_new_vic = 1`） |
| **分母** | `user_id`（`is_new_vic = 1`） |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | 人群细分：TTL VIC `is_member = 0` / Member VIC `is_member = 1` / Is Employee `is_employee = 1` |
| **聚合粒度** | `platform, shop_info_id` |
| **数据类型** | currency → 货币符号由币种切片器决定，千分位整数 |
| **数据格式** | `#,##0`（在 DAX 中用 `__CurrencySymbol & FORMAT(__Value, "#,##0")` 拼接币种符号） |

### 3.1 ACV vs LY（Net_New VIC） — 客单价同比

| 项目 | 内容 |
|---|---|
| **指标名称** | ACV vs LY |
| **指标名称中文** | 客单价同比 |
| **业务定义** | New VIC 客单价今年较去年同期的变化率 |
| **计算公式** | 今年 / 去年 - 1 |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `is_new_vic = 1`；人群细分：TTL VIC `is_member = 0` / Member VIC `is_member = 1` / Is Employee `is_employee = 1` |
| **聚合粒度** | `platform, shop_info_id` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

### 3.2 ACV vs LP（Net_New VIC） — 客单价环比

| 项目 | 内容 |
|---|---|
| **指标名称** | ACV vs LP |
| **指标名称中文** | 客单价环比 |
| **业务定义** | New VIC 客单价当期较上期的变化率 |
| **计算公式** | 当期 / 上期 - 1 |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `is_new_vic = 1`；人群细分：TTL VIC `is_member = 0` / Member VIC `is_member = 1` / Is Employee `is_employee = 1` |
| **聚合粒度** | `platform, shop_info_id` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

### 3.3 ACV vs Store（Net_New VIC） — 客单价对比全客

| 项目 | 内容 |
|---|---|
| **指标名称** | ACV vs Store |
| **指标名称中文** | 客单价对比全客 |
| **业务定义** | New VIC 客单价相对全客客单价的变化率 |
| **计算公式** | New VIC ACV / 全客 ACV - 1 |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `is_new_vic = 1`；人群细分：TTL VIC `is_member = 0` / Member VIC `is_member = 1` / Is Employee `is_employee = 1` |
| **聚合粒度** | `platform, shop_info_id` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

---

### 4. UPT（Net_New VIC） — 客单件

| 项目 | 内容 |
|---|---|
| **指标名称** | UPT |
| **指标名称中文** | 客单件 |
| **业务定义** | New VIC 商品净出库件数/净出库订单数 |
| **计算公式** | 分子：Step 1 在 dt = 所选时间范围 end period，筛选 is_new_vic = 1，框定 user_id 范围；Step 2 再看该 user_id 在所选时间范围对应的 sum(net_pay_qty)。分母：Step 1 在 dt = 所选时间范围 end period，筛选 is_new_vic = 1，框定 user_id 范围；Step 2 再看该 user_id 在所选时间范围对应的 sum(net_pay_order_cnt) |
| **分子** | `net_pay_qty`（`is_new_vic = 1`） |
| **分母** | `net_pay_order_cnt`（`is_new_vic = 1`） |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | 人群细分：TTL VIC `is_member = 0` / Member VIC `is_member = 1` / Is Employee `is_employee = 1` |
| **聚合粒度** | `platform, shop_info_id` |
| **数据类型** | decimal_1dp → 小数，保留一位小数，千分位 |
| **数据格式** | `#,##0.0` |

### 4.1 UPT vs LY（Net_New VIC） — 客单件同比

| 项目 | 内容 |
|---|---|
| **指标名称** | UPT vs LY |
| **指标名称中文** | 客单件同比 |
| **业务定义** | New VIC 客单件今年较去年同期的变化率 |
| **计算公式** | 今年 / 去年 - 1 |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `is_new_vic = 1`；人群细分：TTL VIC `is_member = 0` / Member VIC `is_member = 1` / Is Employee `is_employee = 1` |
| **聚合粒度** | `platform, shop_info_id` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

### 4.2 UPT vs LP（Net_New VIC） — 客单件环比

| 项目 | 内容 |
|---|---|
| **指标名称** | UPT vs LP |
| **指标名称中文** | 客单件环比 |
| **业务定义** | New VIC 客单件当期较上期的变化率 |
| **计算公式** | 当期 / 上期 - 1 |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `is_new_vic = 1`；人群细分：TTL VIC `is_member = 0` / Member VIC `is_member = 1` / Is Employee `is_employee = 1` |
| **聚合粒度** | `platform, shop_info_id` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

### 4.3 UPT vs Store（Net_New VIC） — 客单件对比全客

| 项目 | 内容 |
|---|---|
| **指标名称** | UPT vs Store |
| **指标名称中文** | 客单件对比全客 |
| **业务定义** | New VIC 客单件相对全客客单件的变化率 |
| **计算公式** | New VIC UPT / 全客 UPT - 1 |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `is_new_vic = 1`；人群细分：TTL VIC `is_member = 0` / Member VIC `is_member = 1` / Is Employee `is_employee = 1` |
| **聚合粒度** | `platform, shop_info_id` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

---

### 5. AUR（Net_New VIC） — 件单价

| 项目 | 内容 |
|---|---|
| **指标名称** | AUR |
| **指标名称中文** | 件单价 |
| **业务定义** | New VIC 净销售金额/商品净出库件数 |
| **计算公式** | 分子：Step 1 在 dt = 所选时间范围 end period，筛选 is_new_vic = 1，框定 user_id 范围；Step 2 再看该 user_id 在所选时间范围对应的 sum(net_pay_amt)。分母：Step 1 在 dt = 所选时间范围 end period，筛选 is_new_vic = 1，框定 user_id 范围；Step 2 再看该 user_id 在所选时间范围对应的 sum(net_pay_qty) |
| **分子** | `net_pay_amt`（`is_new_vic = 1`） |
| **分母** | `net_pay_qty`（`is_new_vic = 1`） |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | 人群细分：TTL VIC `is_member = 0` / Member VIC `is_member = 1` / Is Employee `is_employee = 1` |
| **聚合粒度** | `platform, shop_info_id` |
| **数据类型** | currency → 货币符号由币种切片器决定，千分位整数 |
| **数据格式** | `#,##0`（在 DAX 中用 `__CurrencySymbol & FORMAT(__Value, "#,##0")` 拼接币种符号） |

### 5.1 AUR vs LY（Net_New VIC） — 件单价同比

| 项目 | 内容 |
|---|---|
| **指标名称** | AUR vs LY |
| **指标名称中文** | 件单价同比 |
| **业务定义** | New VIC 件单价今年较去年同期的变化率 |
| **计算公式** | 今年 / 去年 - 1 |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `is_new_vic = 1`；人群细分：TTL VIC `is_member = 0` / Member VIC `is_member = 1` / Is Employee `is_employee = 1` |
| **聚合粒度** | `platform, shop_info_id` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

### 5.2 AUR vs LP（Net_New VIC） — 件单价环比

| 项目 | 内容 |
|---|---|
| **指标名称** | AUR vs LP |
| **指标名称中文** | 件单价环比 |
| **业务定义** | New VIC 件单价当期较上期的变化率 |
| **计算公式** | 当期 / 上期 - 1 |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `is_new_vic = 1`；人群细分：TTL VIC `is_member = 0` / Member VIC `is_member = 1` / Is Employee `is_employee = 1` |
| **聚合粒度** | `platform, shop_info_id` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

### 5.3 AUR vs Store（Net_New VIC） — 件单价对比全客

| 项目 | 内容 |
|---|---|
| **指标名称** | AUR vs Store |
| **指标名称中文** | 件单价对比全客 |
| **业务定义** | New VIC 件单价相对全客件单价的变化率 |
| **计算公式** | New VIC AUR / 全客 AUR - 1 |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `is_new_vic = 1`；人群细分：TTL VIC `is_member = 0` / Member VIC `is_member = 1` / Is Employee `is_employee = 1` |
| **聚合粒度** | `platform, shop_info_id` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

---

### 6. Freq.（Net_New VIC） — 购买频次

| 项目 | 内容 |
|---|---|
| **指标名称** | Freq. |
| **指标名称中文** | 购买频次 |
| **业务定义** | New VIC 净订单数/买家人数 |
| **计算公式** | 分子：Step 1 在 dt = 所选时间范围 end period，筛选 is_new_vic = 1，框定 user_id 范围；Step 2 再看该 user_id 在所选时间范围对应的 sum(net_pay_order_cnt)。分母：dt = 所选时间范围 end period，筛选 is_new_vic = 1，count(distinct user_id) |
| **分子** | `net_pay_order_cnt`（`is_new_vic = 1`） |
| **分母** | `user_id`（`is_new_vic = 1`） |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | 人群细分：TTL VIC `is_member = 0` / Member VIC `is_member = 1` / Is Employee `is_employee = 1` |
| **聚合粒度** | `platform, shop_info_id` |
| **数据类型** | decimal_1dp → 小数，保留一位小数，千分位 |
| **数据格式** | `#,##0.0` |

### 6.1 Freq. vs LY（Net_New VIC） — 购买频次同比

| 项目 | 内容 |
|---|---|
| **指标名称** | Freq. vs LY |
| **指标名称中文** | 购买频次同比 |
| **业务定义** | New VIC 购买频次今年较去年同期的变化率 |
| **计算公式** | 今年 / 去年 - 1 |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `is_new_vic = 1`；人群细分：TTL VIC `is_member = 0` / Member VIC `is_member = 1` / Is Employee `is_employee = 1` |
| **聚合粒度** | `platform, shop_info_id` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

### 6.2 Freq. vs LP（Net_New VIC） — 购买频次环比

| 项目 | 内容 |
|---|---|
| **指标名称** | Freq. vs LP |
| **指标名称中文** | 购买频次环比 |
| **业务定义** | New VIC 购买频次当期较上期的变化率 |
| **计算公式** | 当期 / 上期 - 1 |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `is_new_vic = 1`；人群细分：TTL VIC `is_member = 0` / Member VIC `is_member = 1` / Is Employee `is_employee = 1` |
| **聚合粒度** | `platform, shop_info_id` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

### 6.3 Freq. vs Store（Net_New VIC） — 购买频次对比全客

| 项目 | 内容 |
|---|---|
| **指标名称** | Freq. vs Store |
| **指标名称中文** | 购买频次对比全客 |
| **业务定义** | New VIC 购买频次相对全客购买频次的变化率 |
| **计算公式** | New VIC Freq. / 全客 Freq. - 1 |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `is_new_vic = 1`；人群细分：TTL VIC `is_member = 0` / Member VIC `is_member = 1` / Is Employee `is_employee = 1` |
| **聚合粒度** | `platform, shop_info_id` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

---

### 7. SLS（Net_Retention VIC） — 净销售额

| 项目 | 内容 |
|---|---|
| **指标名称** | SLS |
| **指标名称中文** | 净销售额 |
| **业务定义** | Retention VIC 买家净销售额 |
| **计算公式** | Step 1：在 dt = 所选时间范围 end period，筛选 is_retention_vic = 1，框定 user_id 范围；Step 2：再看该 user_id 在所选时间范围对应的 sum(net_pay_amt) |
| **统计字段** | `net_pay_amt`、`is_retention_vic` |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | 人群细分：TTL VIC `is_member = 0` / Member VIC `is_member = 1` / Is Employee `is_employee = 1` |
| **聚合粒度** | `platform, shop_info_id` |
| **数据类型** | currency → 货币符号由币种切片器决定，千分位整数 |
| **数据格式** | `#,##0`（在 DAX 中用 `__CurrencySymbol & FORMAT(__Value, "#,##0")` 拼接币种符号） |

### 7.1 SLS vs LY（Net_Retention VIC） — 净销售额同比

| 项目 | 内容 |
|---|---|
| **指标名称** | SLS vs LY |
| **指标名称中文** | 净销售额同比 |
| **业务定义** | Retention VIC 买家净销售额今年较去年同期的变化率 |
| **计算公式** | 今年 / 去年 - 1 |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `is_retention_vic = 1`；人群细分：TTL VIC `is_member = 0` / Member VIC `is_member = 1` / Is Employee `is_employee = 1` |
| **聚合粒度** | `platform, shop_info_id` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

### 7.2 SLS vs LP（Net_Retention VIC） — 净销售额环比

| 项目 | 内容 |
|---|---|
| **指标名称** | SLS vs LP |
| **指标名称中文** | 净销售额环比 |
| **业务定义** | Retention VIC 买家净销售额当期较上期的变化率 |
| **计算公式** | 当期 / 上期 - 1 |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `is_retention_vic = 1`；人群细分：TTL VIC `is_member = 0` / Member VIC `is_member = 1` / Is Employee `is_employee = 1` |
| **聚合粒度** | `platform, shop_info_id` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

---

### 8. SLS%（Net_Retention VIC） — 净销售额占比

| 项目 | 内容 |
|---|---|
| **指标名称** | SLS% |
| **指标名称中文** | 净销售额占比 |
| **业务定义** | Retention VIC 买家净销售额/总买家净销售额 |
| **计算公式** | 分子：Step 1 在 dt = 所选时间范围 end period，筛选 is_retention_vic = 1，框定 user_id 范围；Step 2 再看该 user_id 在所选时间范围对应的 sum(net_pay_amt)。分母：所选时间范围对应的 sum(net_pay_amt) |
| **分子** | `net_pay_amt`（`is_retention_vic = 1`） |
| **分母** | `net_pay_amt`（全部） |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | 人群细分：TTL VIC `is_member = 0` / Member VIC `is_member = 1` / Is Employee `is_employee = 1` |
| **聚合粒度** | `platform, shop_info_id` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

### 8.1 SLS% vs LY（Net_Retention VIC） — 净销售额占比同比

| 项目 | 内容 |
|---|---|
| **指标名称** | SLS% vs LY |
| **指标名称中文** | 净销售额占比同比 |
| **业务定义** | Retention VIC 买家净销售额占比今年较去年同期的变化（差值） |
| **计算公式** | 今年 - 去年（差值，展示时 ×100 转 pts） |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | 人群细分：TTL VIC `is_member = 0` / Member VIC `is_member = 1` / Is Employee `is_employee = 1` |
| **聚合粒度** | `platform, shop_info_id` |
| **数据类型** | delta_pts → 增减基点整数： → +120pts / -80pts（基点，含正负号，值×100 转 pts）,乘以100的操作可以放在Cell Display度量中实现，算同比LY：当期值 − 同期值（差值，pts 指标，展示时 ×100 转 pts） |        
| **数据格式** | `+#,##0pts;-#,##0pts;0pts` |

### 8.2 SLS% vs LP（Net_Retention VIC） — 净销售额占比环比

| 项目 | 内容 |
|---|---|
| **指标名称** | SLS% vs LP |
| **指标名称中文** | 净销售额占比环比 |
| **业务定义** | Retention VIC 买家净销售额占比当期较上期的变化（差值） |
| **计算公式** | 当期 - 上期（差值，展示时 ×100 转 pts） |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | 人群细分：TTL VIC `is_member = 0` / Member VIC `is_member = 1` / Is Employee `is_employee = 1` |
| **聚合粒度** | `platform, shop_info_id` |
| **数据类型** | delta_pts → 增减基点整数： → +120pts / -80pts（基点，含正负号，值×100 转 pts）,乘以100的操作可以放在Cell Display度量中实现，算环比LP：当期值 − 上期值（差值，pts 指标，展示时 ×100 转 pts） |        
| **数据格式** | `+#,##0pts;-#,##0pts;0pts` |

---

### 9. ACV（Net_Retention VIC） — 客单价

| 项目 | 内容 |
|---|---|
| **指标名称** | ACV |
| **指标名称中文** | 客单价 |
| **业务定义** | Retention VIC 净销售金额/净购买买家人数 |
| **计算公式** | 分子：SLS（Step 1 在 dt = 所选时间范围 end period，筛选 is_retention_vic = 1，框定 user_id 范围；Step 2 再看该 user_id 在所选时间范围对应的 sum(net_pay_amt)）；分母：dt = 所选时间范围 end period，筛选 is_retention_vic = 1，count(distinct user_id) |
| **分子** | `net_pay_amt`（`is_retention_vic = 1`） |
| **分母** | `user_id`（`is_retention_vic = 1`） |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | 人群细分：TTL VIC `is_member = 0` / Member VIC `is_member = 1` / Is Employee `is_employee = 1` |
| **聚合粒度** | `platform, shop_info_id` |
| **数据类型** | currency → 货币符号由币种切片器决定，千分位整数 |
| **数据格式** | `#,##0`（在 DAX 中用 `__CurrencySymbol & FORMAT(__Value, "#,##0")` 拼接币种符号） |

### 9.1 ACV vs LY（Net_Retention VIC） — 客单价同比

| 项目 | 内容 |
|---|---|
| **指标名称** | ACV vs LY |
| **指标名称中文** | 客单价同比 |
| **业务定义** | Retention VIC 客单价今年较去年同期的变化率 |
| **计算公式** | 今年 / 去年 - 1 |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `is_retention_vic = 1`；人群细分：TTL VIC `is_member = 0` / Member VIC `is_member = 1` / Is Employee `is_employee = 1` |
| **聚合粒度** | `platform, shop_info_id` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

### 9.2 ACV vs LP（Net_Retention VIC） — 客单价环比

| 项目 | 内容 |
|---|---|
| **指标名称** | ACV vs LP |
| **指标名称中文** | 客单价环比 |
| **业务定义** | Retention VIC 客单价当期较上期的变化率 |
| **计算公式** | 当期 / 上期 - 1 |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `is_retention_vic = 1`；人群细分：TTL VIC `is_member = 0` / Member VIC `is_member = 1` / Is Employee `is_employee = 1` |
| **聚合粒度** | `platform, shop_info_id` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

### 9.3 ACV vs Store（Net_Retention VIC） — 客单价对比全客

| 项目 | 内容 |
|---|---|
| **指标名称** | ACV vs Store |
| **指标名称中文** | 客单价对比全客 |
| **业务定义** | Retention VIC 客单价相对全客客单价的变化率 |
| **计算公式** | Retention VIC ACV / 全客 ACV - 1 |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `is_retention_vic = 1`；人群细分：TTL VIC `is_member = 0` / Member VIC `is_member = 1` / Is Employee `is_employee = 1` |
| **聚合粒度** | `platform, shop_info_id` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

---

### 10. UPT（Net_Retention VIC） — 客单件

| 项目 | 内容 |
|---|---|
| **指标名称** | UPT |
| **指标名称中文** | 客单件 |
| **业务定义** | Retention VIC 商品净出库件数/净出库订单数 |
| **计算公式** | 分子：Step 1 在 dt = 所选时间范围 end period，筛选 is_retention_vic = 1，框定 user_id 范围；Step 2 再看该 user_id 在所选时间范围对应的 sum(net_pay_qty)。分母：Step 1 在 dt = 所选时间范围 end period，筛选 is_retention_vic = 1，框定 user_id 范围；Step 2 再看该 user_id 在所选时间范围对应的 sum(net_pay_order_cnt) |
| **分子** | `net_pay_qty`（`is_retention_vic = 1`） |
| **分母** | `net_pay_order_cnt`（`is_retention_vic = 1`） |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | 人群细分：TTL VIC `is_member = 0` / Member VIC `is_member = 1` / Is Employee `is_employee = 1` |
| **聚合粒度** | `platform, shop_info_id` |
| **数据类型** | decimal_1dp → 小数，保留一位小数，千分位 |
| **数据格式** | `#,##0.0` |

### 10.1 UPT vs LY（Net_Retention VIC） — 客单件同比

| 项目 | 内容 |
|---|---|
| **指标名称** | UPT vs LY |
| **指标名称中文** | 客单件同比 |
| **业务定义** | Retention VIC 客单件今年较去年同期的变化率 |
| **计算公式** | 今年 / 去年 - 1 |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `is_retention_vic = 1`；人群细分：TTL VIC `is_member = 0` / Member VIC `is_member = 1` / Is Employee `is_employee = 1` |
| **聚合粒度** | `platform, shop_info_id` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

### 10.2 UPT vs LP（Net_Retention VIC） — 客单件环比

| 项目 | 内容 |
|---|---|
| **指标名称** | UPT vs LP |
| **指标名称中文** | 客单件环比 |
| **业务定义** | Retention VIC 客单件当期较上期的变化率 |
| **计算公式** | 当期 / 上期 - 1 |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `is_retention_vic = 1`；人群细分：TTL VIC `is_member = 0` / Member VIC `is_member = 1` / Is Employee `is_employee = 1` |
| **聚合粒度** | `platform, shop_info_id` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

### 10.3 UPT vs Store（Net_Retention VIC） — 客单件对比全客

| 项目 | 内容 |
|---|---|
| **指标名称** | UPT vs Store |
| **指标名称中文** | 客单件对比全客 |
| **业务定义** | Retention VIC 客单件相对全客客单件的变化率 |
| **计算公式** | Retention VIC UPT / 全客 UPT - 1 |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `is_retention_vic = 1`；人群细分：TTL VIC `is_member = 0` / Member VIC `is_member = 1` / Is Employee `is_employee = 1` |
| **聚合粒度** | `platform, shop_info_id` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

---

### 11. AUR（Net_Retention VIC） — 件单价

| 项目 | 内容 |
|---|---|
| **指标名称** | AUR |
| **指标名称中文** | 件单价 |
| **业务定义** | Retention VIC 净销售金额/商品净出库件数 |
| **计算公式** | 分子：Step 1 在 dt = 所选时间范围 end period，筛选 is_retention_vic = 1，框定 user_id 范围；Step 2 再看该 user_id 在所选时间范围对应的 sum(net_pay_amt)。分母：Step 1 在 dt = 所选时间范围 end period，筛选 is_retention_vic = 1，框定 user_id 范围；Step 2 再看该 user_id 在所选时间范围对应的 sum(net_pay_qty) |
| **分子** | `net_pay_amt`（`is_retention_vic = 1`） |
| **分母** | `net_pay_qty`（`is_retention_vic = 1`） |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | 人群细分：TTL VIC `is_member = 0` / Member VIC `is_member = 1` / Is Employee `is_employee = 1` |
| **聚合粒度** | `platform, shop_info_id` |
| **数据类型** | currency → 货币符号由币种切片器决定，千分位整数 |
| **数据格式** | `#,##0`（在 DAX 中用 `__CurrencySymbol & FORMAT(__Value, "#,##0")` 拼接币种符号） |

### 11.1 AUR vs LY（Net_Retention VIC） — 件单价同比

| 项目 | 内容 |
|---|---|
| **指标名称** | AUR vs LY |
| **指标名称中文** | 件单价同比 |
| **业务定义** | Retention VIC 件单价今年较去年同期的变化率 |
| **计算公式** | 今年 / 去年 - 1 |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `is_retention_vic = 1`；人群细分：TTL VIC `is_member = 0` / Member VIC `is_member = 1` / Is Employee `is_employee = 1` |
| **聚合粒度** | `platform, shop_info_id` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

### 11.2 AUR vs LP（Net_Retention VIC） — 件单价环比

| 项目 | 内容 |
|---|---|
| **指标名称** | AUR vs LP |
| **指标名称中文** | 件单价环比 |
| **业务定义** | Retention VIC 件单价当期较上期的变化率 |
| **计算公式** | 当期 / 上期 - 1 |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `is_retention_vic = 1`；人群细分：TTL VIC `is_member = 0` / Member VIC `is_member = 1` / Is Employee `is_employee = 1` |
| **聚合粒度** | `platform, shop_info_id` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

### 11.3 AUR vs Store（Net_Retention VIC） — 件单价对比全客

| 项目 | 内容 |
|---|---|
| **指标名称** | AUR vs Store |
| **指标名称中文** | 件单价对比全客 |
| **业务定义** | Retention VIC 件单价相对全客件单价的变化率 |
| **计算公式** | Retention VIC AUR / 全客 AUR - 1 |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `is_retention_vic = 1`；人群细分：TTL VIC `is_member = 0` / Member VIC `is_member = 1` / Is Employee `is_employee = 1` |
| **聚合粒度** | `platform, shop_info_id` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

---

### 12. Freq.（Net_Retention VIC） — 购买频次

| 项目 | 内容 |
|---|---|
| **指标名称** | Freq. |
| **指标名称中文** | 购买频次 |
| **业务定义** | Retention VIC 净订单数/买家人数 |
| **计算公式** | 分子：Step 1 在 dt = 所选时间范围 end period，筛选 is_retention_vic = 1，框定 user_id 范围；Step 2 再看该 user_id 在所选时间范围对应的 sum(net_pay_order_cnt)。分母：dt = 所选时间范围 end period，筛选 is_retention_vic = 1，count(distinct user_id) |
| **分子** | `net_pay_order_cnt`（`is_retention_vic = 1`） |
| **分母** | `user_id`（`is_retention_vic = 1`） |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | 人群细分：TTL VIC `is_member = 0` / Member VIC `is_member = 1` / Is Employee `is_employee = 1` |
| **聚合粒度** | `platform, shop_info_id` |
| **数据类型** | decimal_1dp → 小数，保留一位小数，千分位 |
| **数据格式** | `#,##0.0` |

### 12.1 Freq. vs LY（Net_Retention VIC） — 购买频次同比

| 项目 | 内容 |
|---|---|
| **指标名称** | Freq. vs LY |
| **指标名称中文** | 购买频次同比 |
| **业务定义** | Retention VIC 购买频次今年较去年同期的变化率 |
| **计算公式** | 今年 / 去年 - 1 |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `is_retention_vic = 1`；人群细分：TTL VIC `is_member = 0` / Member VIC `is_member = 1` / Is Employee `is_employee = 1` |
| **聚合粒度** | `platform, shop_info_id` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

### 12.2 Freq. vs LP（Net_Retention VIC） — 购买频次环比

| 项目 | 内容 |
|---|---|
| **指标名称** | Freq. vs LP |
| **指标名称中文** | 购买频次环比 |
| **业务定义** | Retention VIC 购买频次当期较上期的变化率 |
| **计算公式** | 当期 / 上期 - 1 |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `is_retention_vic = 1`；人群细分：TTL VIC `is_member = 0` / Member VIC `is_member = 1` / Is Employee `is_employee = 1` |
| **聚合粒度** | `platform, shop_info_id` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

### 12.3 Freq. vs Store（Net_Retention VIC） — 购买频次对比全客

| 项目 | 内容 |
|---|---|
| **指标名称** | Freq. vs Store |
| **指标名称中文** | 购买频次对比全客 |
| **业务定义** | Retention VIC 购买频次相对全客购买频次的变化率 |
| **计算公式** | Retention VIC Freq. / 全客 Freq. - 1 |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `is_retention_vic = 1`；人群细分：TTL VIC `is_member = 0` / Member VIC `is_member = 1` / Is Employee `is_employee = 1` |
| **聚合粒度** | `platform, shop_info_id` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

---

### 13. VIC SLS（Net_New VIC，趋势） — 净销售额

| 项目 | 内容 |
|---|---|
| **指标名称** | VIC SLS |
| **指标名称中文** | 净销售额 |
| **业务定义** | New VIC 买家净销售额 |
| **计算公式** | 根据所选 timeframe：Month → dt = 选择时间范围的每个月，筛选 is_new_vic = 1，框定 user_id 范围；Quarter → dt = 所选时间范围每季的最后一个财月，筛选 is_new_vic = 1，框定 user_id 范围；Year → dt = 所选时间范围每年的最后一个财月，筛选 is_new_vic = 1，框定 user_id 范围；Step 2 再看该 user_id 在所选时间范围对应的 sum(net_pay_amt) |
| **统计字段** | `net_pay_amt`、`is_new_vic` |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | 人群细分：TTL VIC `is_member = 0` / Member VIC `is_member = 1` / Is Employee `is_employee = 1` |
| **聚合粒度** | `platform, shop_info_id` |
| **数据类型** | currency → 货币符号由币种切片器决定，千分位整数 |
| **数据格式** | `#,##0`（在 DAX 中用 `__CurrencySymbol & FORMAT(__Value, "#,##0")` 拼接币种符号） |

---

### 14. VIC SLS%（Net_New VIC，趋势） — 净销售额占比

| 项目 | 内容 |
|---|---|
| **指标名称** | VIC SLS% |
| **指标名称中文** | 净销售额占比 |
| **业务定义** | New VIC 买家净销售额/总买家净销售额 |
| **计算公式** | 分子：Step 1 根据所选 timeframe：Month → dt = 选择时间范围的每个月，筛选 is_new_vic = 1，框定 user_id 范围；Quarter → dt = 所选时间范围每季的最后一个财月，筛选 is_new_vic = 1，框定 user_id 范围；Year → dt = 所选时间范围每年的最后一个财月，筛选 is_new_vic = 1，框定 user_id 范围；Step 2 再看该 user_id 在所选时间范围对应的 sum(net_pay_amt)。分母：所选时间范围对应的 sum(net_pay_amt) |
| **分子** | `net_pay_amt`（`is_new_vic = 1`） |
| **分母** | `net_pay_amt`（全部） |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | 人群细分：TTL VIC `is_member = 0` / Member VIC `is_member = 1` / Is Employee `is_employee = 1` |
| **聚合粒度** | `platform, shop_info_id` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

---

### 15. VIC SLS（Net_Retention VIC，趋势） — 净销售额

| 项目 | 内容 |
|---|---|
| **指标名称** | VIC SLS |
| **指标名称中文** | 净销售额 |
| **业务定义** | Retention VIC 买家净销售额 |
| **计算公式** | 根据所选 timeframe：Month → dt = 选择时间范围的每个月，筛选 is_retention_vic = 1，框定 user_id 范围；Quarter → dt = 所选时间范围每季的最后一个财月，筛选 is_retention_vic = 1，框定 user_id 范围；Year → dt = 所选时间范围每年的最后一个财月，筛选 is_retention_vic = 1，框定 user_id 范围；Step 2 再看该 user_id 在所选时间范围对应的 sum(net_pay_amt) |
| **统计字段** | `net_pay_amt`、`is_retention_vic` |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | 人群细分：TTL VIC `is_member = 0` / Member VIC `is_member = 1` / Is Employee `is_employee = 1` |
| **聚合粒度** | `platform, shop_info_id` |
| **数据类型** | currency → 货币符号由币种切片器决定，千分位整数 |
| **数据格式** | `#,##0`（在 DAX 中用 `__CurrencySymbol & FORMAT(__Value, "#,##0")` 拼接币种符号） |

---

### 16. VIC SLS%（Net_Retention VIC，趋势） — 净销售额占比

| 项目 | 内容 |
|---|---|
| **指标名称** | VIC SLS% |
| **指标名称中文** | 净销售额占比 |
| **业务定义** | Retention VIC 买家净销售额/总买家净销售额 |
| **计算公式** | 分子：Step 1 根据所选 timeframe：Month → dt = 选择时间范围的每个月，筛选 is_retention_vic = 1，框定 user_id 范围；Quarter → dt = 所选时间范围每季的最后一个财月，筛选 is_retention_vic = 1，框定 user_id 范围；Year → dt = 所选时间范围每年的最后一个财月，筛选 is_retention_vic = 1，框定 user_id 范围；Step 2 再看该 user_id 在所选时间范围对应的 sum(net_pay_amt)。分母：所选时间范围对应的 sum(net_pay_amt) |
| **分子** | `net_pay_amt`（`is_retention_vic = 1`） |
| **分母** | `net_pay_amt`（全部） |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | 人群细分：TTL VIC `is_member = 0` / Member VIC `is_member = 1` / Is Employee `is_employee = 1` |
| **聚合粒度** | `platform, shop_info_id` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

---

## 子模块六：Class x Label Drilldown

> **分组维度**: 按 `platform, shop_info_id` 分组；按 VIC 类型（Retention VIC / T4-5 Upgrade / Direct VIC / New VIC）区分

### 1. VIC No.（Net_Retention VIC） — VIC数量

| 项目 | 内容 |
|---|---|
| **指标名称** | VIC No. |
| **指标名称中文** | VIC数量 |
| **业务定义** | 在指定日期范围往前 Rolling 12 个财月，net sales >= 20k 的买家数量 |
| **统计字段** | `user_id` |
| **数据底表** | `t05_customer_order_data_d` |
| **筛选条件** | `is_retention_vic = 1`；人群细分：TTL VIC `is_member = 0` / Member VIC `is_member = 1` / Is Employee `is_employee = 1` |
| **聚合粒度** | `platform, shop_info_id` |
| **数据类型** | integer → 整数，千分位整数 |
| **数据格式** | `#,##0` |

---

### 2. VIC No.（Net_T4-5 Upgrade） — VIC数量

| 项目 | 内容 |
|---|---|
| **指标名称** | VIC No. |
| **指标名称中文** | VIC数量 |
| **业务定义** | 在指定日期范围往前 Rolling 12 个财月，net sales >= 20k 的买家数量 |
| **统计字段** | `user_id` |
| **数据底表** | `t05_customer_order_data_d` |
| **筛选条件** | `is_upgrade_vic = 1`；人群细分：TTL VIC `is_member = 0` / Member VIC `is_member = 1` / Is Employee `is_employee = 1` |
| **聚合粒度** | `platform, shop_info_id` |
| **数据类型** | integer → 整数，千分位整数 |
| **数据格式** | `#,##0` |

---

### 3. VIC No.（Net_Direct VIC） — VIC数量

| 项目 | 内容 |
|---|---|
| **指标名称** | VIC No. |
| **指标名称中文** | VIC数量 |
| **业务定义** | 在指定日期范围往前 Rolling 12 个财月，net sales >= 20k 的买家数量 |
| **统计字段** | `user_id` |
| **数据底表** | `t05_customer_order_data_d` |
| **筛选条件** | `is_direct_vic = 1`；人群细分：TTL VIC `is_member = 0` / Member VIC `is_member = 1` / Is Employee `is_employee = 1` |
| **聚合粒度** | `platform, shop_info_id` |
| **数据类型** | integer → 整数，千分位整数 |
| **数据格式** | `#,##0` |

---

### 4. VIC No.（Net_New VIC） — VIC数量

| 项目 | 内容 |
|---|---|
| **指标名称** | VIC No. |
| **指标名称中文** | VIC数量 |
| **业务定义** | 在指定日期范围往前 Rolling 12 个财月，net sales >= 20k 的买家数量 |
| **统计字段** | `user_id` |
| **数据底表** | `t05_customer_order_data_d` |
| **筛选条件** | `is_new_vic = 1`；人群细分：TTL VIC `is_member = 0` / Member VIC `is_member = 1` / Is Employee `is_employee = 1` |
| **聚合粒度** | `platform, shop_info_id` |
| **数据类型** | integer → 整数，千分位整数 |
| **数据格式** | `#,##0` |

---

## 通用规则汇总

| 规则项 | 说明 |
|---|---|
| **数据底表** | `a03_e2e_customer_data_m`、`t05_customer_order_data_d` |
| **筛选逻辑** | VIC 统一 `is_vic = 1`；人群细分：TTL VIC（`is_member = 0`）、Member VIC（`is_member = 1`）、Is Employee（`is_employee = 1`） |
| **货币转换规则** | 数据源默认为 RMB，转化为美元需要除以固定值 7 |
| **派生指标** | LY（去年同期）、LP（上期）、vs LY（同比）、vs LP（环比）、占比、YOY、vs Store 等为派生指标，依据基础指标计算生成 |
| **分组维度** | 根据 `platform, shop_info_id`、`timeframe`（Month/Quarter/Year）、`customer_tier`（T1/T2/T3/T4/T5）、`last_fy_last_order_month_type`（R3/R4-6/R7-9/R10-12/TTL）、VIC 类型（New VIC/Retention VIC/Direct VIC/T4-5 Upgrade）分组 |
| **必须遵守** | 口径文档中定义的所有指标，必须遵守其数据类型和数据格式，如果和解决方案中存在争议的，一切以口径文档为准，必须按照口径文档中的格式进行调整 |
| **DAX 语法规范** | 文本常量必须使用双引号 `" "`，禁止使用单引号；单引号 `' '` 仅用于表名，列名使用方括号 `[ ]`，例如：`[is_vic] = 1` |
| **pts 与 bp 区别** | pts 指标：值×100 转 pts（基点，含正负号），数据格式 `+#,##0pts;-#,##0pts;0pts`；bp 指标：值×10000 转 bp，数据格式 `+#,##0bp;-#,##0bp;0bp` |
| **TAR ACH% 占位** | Monthly TAR ACH% / Yearly TAR ACH% / TAR ACH% 逻辑暂未确认，先保持子指标占位，数据格式为 percent_1dp：`+#,##0.0%;-#,##0.0%;0.0%`，等逻辑确认后再填充 |
| **VIC 定义** | 在指定日期范围往前 Rolling 12 个财月，net sales >= 20k 的买家 |
| **Tier 分层定义** | T1：≧ 200K；T2：80-200K；T3：20-80K；T4：5-20K；T5：< 5K |
| **Recency 分层定义** | R3：上财年 10-12 月；R4-6：上财年 7-9 月；R7-9：上财年 4-6 月；R10-12：上财年 1-3 月；TTL：全部 |
