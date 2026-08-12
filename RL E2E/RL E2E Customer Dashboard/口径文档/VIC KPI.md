# Customer Dashboard 指标口径提示词

> **Dashboard**: Customer Dashboard  
> **Tab**: VIC  
> **数据底表**: `a03_e2e_customer_data_m` / `t05_customer_order_data_d`  
> **模块全局影响说明**:  人群细分：TTL VIC `is_member = 0` / Member VIC `is_member = 1` / Is Employee `is_employee = 1` or `is_employee = 0`
> **is_member使用**: VAR __IsMemberFilter = SELECTEDVALUE(IsMemberFilter[IsMember], 0)，如果没有筛选，则默认TTL VIC。这样过滤事实表a03_e2e_customer_data_m[is_member] = __IsMemberFilter
> **is_employee使用**: VAR __IsEmployeeFilter = SELECTEDVALUE(Slicer_Is_Employee_Selection[IsEmployee_Code], 1)，如果没有筛选，则默认Yes。这样过滤事实表a03_e2e_customer_data_m[is_employee] = __IsEmployeeFilter
> **is_member和is_employee维度表路径**:is_member： D:\gutao\辜涛\Project\Qoder_AI_Frontend_and_backend_Web\RL E2E\RL E2E Customer Dashboard\维度复用\IsMemberFilter；is_employee： D:\gutao\辜涛\Project\Qoder_AI_Frontend_and_backend_Web\RL E2E\RL E2E Customer Dashboard\维度复用\Slicer_Is_Employee_Selection

---

## 全局逻辑

| 项目 | 内容 |
|---|---|
| **数据底表** | `a03_e2e_customer_data_m`、`t05_customer_order_data_d` |
| **筛选逻辑** | 模块全局影响：除了特殊说明之外的指标不需要判断is_member和is_employee，其余都默认需要判断is_member和is_employee来确定筛选事实表的值  |
| **聚合粒度** | 数字卡片：所选时间范围 `dt`（多数为 end period），所选时间范围的最后一个财月，只关注Max；表格：按对应维度聚合 |
| **货币转换规则** | 数据源默认为 RMB，转化为美元需要除以固定值 7 |
| **派生指标** | LY（去年同期）、LP（上期）、vs LY（同比）、vs LP（环比）、占比、YOY 等为派生指标，依据基础指标计算生成 |
| **必须遵守** | 口径文档中定义的所有指标，必须遵守其数据类型和数据格式，如果和解决方案中存在争议的，一切以口径文档为准，必须按照口径文档中的格式进行调整 |
| **模块全局影响说明** | 人群细分：TTL VIC `is_member = 0` / Member VIC `is_member = 1` / Is Employee `is_employee = 1` or `is_employee = 0`  |
| **is_member使用** | VAR __IsMemberFilter = SELECTEDVALUE(IsMemberFilter[IsMember], 0)，如果没有筛选，则默认TTL VIC。这样过滤事实表a03_e2e_customer_data_m[is_member] = __IsMemberFilter |
| **is_employee使用** | VAR __IsEmployeeFilter = SELECTEDVALUE(Slicer_Is_Employee_Selection[IsEmployee_Code], 1)，如果没有筛选，则默认Yes。这样过滤事实表a03_e2e_customer_data_m[is_employee] = __IsEmployeeFilter |
| **is_member和is_employee维度表路径** | is_member： D:\gutao\辜涛\Project\Qoder_AI_Frontend_and_backend_Web\RL E2E\RL E2E Customer Dashboard\维度复用\IsMemberFilter；is_employee： D:\gutao\辜涛\Project\Qoder_AI_Frontend_and_backend_Web\RL E2E\RL E2E Customer Dashboard\维度复用\Slicer_Is_Employee_Selection |
| **end period说明** | 所选时间范围的最后一个财月，只关注Slicer_Time_Frame_Max值,比如2026-09，只关注2023-09；2026 Q2，只关注2026-06；财年2026，对应最后一个财月只关注2026-12； |

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
| **筛选条件** | `is_vic = 1`、`is_member`和`is_employee`筛选   |
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
| **筛选条件** | `is_vic = 1`、`is_member`和`is_employee`筛选   |
| **聚合粒度** | `dt = 所选时间范围 end period`，`platform, shop_info_id` |
| **数据类型** | delta_pct_1dp → 百分比，保留一位小数，含正号：+14.5% / -3.2% |
| **数据格式** | IF(__Value > 0, "+", "") & FORMAT(__Value, "#,##0.0%") |

### 1.2 VIC No. vs LP — VIC数量环比

| 项目 | 内容 |
|---|---|
| **指标名称** | VIC No. vs LP |
| **指标名称中文** | VIC数量环比 |
| **业务定义** | VIC数量当期较上期的变化率 |
| **计算公式** | 当期 / 上期 - 1 |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `is_vic = 1`、`is_member`和`is_employee`筛选   |
| **聚合粒度** | `dt = 所选时间范围 end period`，`platform, shop_info_id` |
| **数据类型** | delta_pct_1dp → 百分比，保留一位小数，含正号：+14.5% / -3.2% |
| **数据格式** | IF(__Value > 0, "+", "") & FORMAT(__Value, "#,##0.0%") |

### 1.3 VIC Monthly TAR ACH% — 月度目标达成率

| 项目 | 内容 |
|---|---|
| **指标名称** | VIC Monthly TAR ACH% |
| **指标名称中文** | 月度目标达成率 |
| **业务定义** | 暂无逻辑，占位，等逻辑确认后再填充 |
| **计算公式** | 占位值为1  |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `is_vic = 1`；`is_member`和`is_employee`筛选   |
| **聚合粒度** | `dt = 所选时间范围 end period`，`platform, shop_info_id` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，含正负号 |
| **数据格式** | "#,##0.0%" |

### 1.4 VIC Yearly TAR ACH% — 年度目标达成率

| 项目 | 内容 |
|---|---|
| **指标名称** | VIC Yearly TAR ACH% |
| **指标名称中文** | 年度目标达成率 |
| **业务定义** | 暂无逻辑，占位，等逻辑确认后再填充 |
| **计算公式** | 占位值为1 |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `is_vic = 1`；`is_member`和`is_employee`筛选   |
| **聚合粒度** | `dt = 所选时间范围 end period`，`platform, shop_info_id` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，含正负号 |
| **数据格式** | "#,##0.0%" |

---

### 2. VIC Retention% — VIC留存率

| 项目 | 内容 |
|---|---|
| **指标名称** | VIC Retention% |
| **指标名称中文** | VIC留存率 |
| **业务定义** | 在指定日期范围仍为 VIC 且上一周期也是 VIC 的人数/上一周期 VIC 人数 |
| **计算公式** | 分子：count(distinct user_id) where is_retention_vic = 1；分母：所选时间范围 end period 往前 Rolling 12 个财月 count(distinct user_id) where is_vic = 1 |
| **分子** | `user_id`（`is_retention_vic = 1`） |
| **分母** | `user_id`（所选时间范围 end period 往前 Rolling 12 个财月 count(distinct user_id)，Rolling 12 个财月 = 当前月 + 往前 11 个月，共 12 个月、 `is_vic = 1`） |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** |  `is_member`和`is_employee`筛选  |
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
| **筛选条件** |  `is_member`和`is_employee`筛选  |
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
| **筛选条件** |  `is_member`和`is_employee`筛选  |
| **聚合粒度** | `dt = 所选时间范围 end period`，`platform, shop_info_id` |
| **数据类型** | delta_pts → 增减基点整数： → +120pts / -80pts（基点，含正负号，值×100 转 pts）,乘以100的操作可以放在Cell Display度量中实现，算环比LP：当期值 − 上期值（差值，pts 指标，展示时 ×100 转 pts） |        
| **数据格式** | `+#,##0pts;-#,##0pts;0pts` |

### 2.3 VIC Retention% TAR ACH% — 目标达成率

| 项目 | 内容 |
|---|---|
| **指标名称** | VIC Retention% TAR ACH% |
| **指标名称中文** | 目标达成率 |
| **业务定义** | 暂无逻辑，占位，等逻辑确认后再填充 |
| **计算公式** | 占位值为1 |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** |  `is_member`和`is_employee`筛选  |
| **聚合粒度** | `dt = 所选时间范围 end period`，`platform, shop_info_id` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，含正负号 |
| **数据格式** | "#,##0.0%" |

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
| **筛选条件** | `is_upgrade_vic = 1`；`is_member`和`is_employee`筛选   |
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
| **筛选条件** | `is_upgrade_vic = 1`；`is_member`和`is_employee`筛选   |
| **聚合粒度** | `dt = 所选时间范围 end period`，`platform, shop_info_id` |
| **数据类型** | delta_pct_1dp → 百分比，保留一位小数，含正号：+14.5% / -3.2% |
| **数据格式** | IF(__Value > 0, "+", "") & FORMAT(__Value, "#,##0.0%") |

### 3.2 T4-5 Upgrade No. vs LP — T4-5升级为VIC人数环比

| 项目 | 内容 |
|---|---|
| **指标名称** | T4-5 Upgrade No. vs LP |
| **指标名称中文** | T4-5升级为VIC人数环比 |
| **业务定义** | T4-5升级为VIC人数当期较上期的变化率 |
| **计算公式** | 当期 / 上期 - 1 |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `is_upgrade_vic = 1`； `is_member`和`is_employee`筛选  |
| **聚合粒度** | `dt = 所选时间范围 end period`，`platform, shop_info_id` |
| **数据类型** | delta_pct_1dp → 百分比，保留一位小数，含正号：+14.5% / -3.2% |
| **数据格式** | IF(__Value > 0, "+", "") & FORMAT(__Value, "#,##0.0%") |

### 3.3 T4-5 Upgrade No. TAR ACH% — 目标达成率

| 项目 | 内容 |
|---|---|
| **指标名称** | T4-5 Upgrade No. TAR ACH% |
| **指标名称中文** | 目标达成率 |
| **业务定义** | 暂无逻辑，占位，等逻辑确认后再填充 |
| **计算公式** | 占位值为1 |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `is_upgrade_vic = 1`； `is_member`和`is_employee`筛选  |
| **聚合粒度** | `dt = 所选时间范围 end period`，`platform, shop_info_id` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，含正负号 |
| **数据格式** | "#,##0.0%" |

### 3.4 T4-5 Upgrade No. Share — T4-5升级占比

| 项目 | 内容 |
|---|---|
| **指标名称** | T4-5 Upgrade No. Share |
| **指标名称中文** | T4-5升级占比 |
| **业务定义** | T4-5 升级为 VIC 的人数占 VIC 总人数的比例 |
| **计算公式** | 分子：count(distinct user_id) where is_upgrade_vic = 1；分母：count(distinct user_id) where is_vic = 1 |
| **分子** | `user_id`（`is_upgrade_vic = 1`） |
| **分母** | `user_id`（`is_vic = 1`） |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `is_member`和`is_employee`筛选 |
| **聚合粒度** | `dt = 所选时间范围 end period`，`platform, shop_info_id` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

### 3.5 T4-5 Upgrade No. Share vs LY — T4-5升级占比同比

| 项目 | 内容 |
|---|---|
| **指标名称** | T4-5 Upgrade No. Share vs LY | 
| **指标名称中文** | T4-5升级占比同比 |
| **业务定义** | T4-5升级占比今年较去年同期的变化（差值） |
| **计算公式** | 今年 - 去年（差值，展示时 ×100 转 pts） |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `is_member`和`is_employee`筛选 |
| **聚合粒度** | `dt = 所选时间范围 end period`，`platform, shop_info_id` |
| **数据类型** | delta_pts → 增减基点整数： → +120pts / -80pts（基点，含正负号，值×100 转 pts）,乘以100的操作可以放在Cell Display度量中实现，算同比LY：当期值 − 同期值（差值，pts 指标，展示时 ×100 转 pts） |        
| **数据格式** | `+#,##0pts;-#,##0pts;0pts` |

### 3.6 T4-5 Upgrade No. Share vs LP — T4-5升级占比环比

| 项目 | 内容 |
|---|---|
| **指标名称** | T4-5 Upgrade No. Share vs LP | 
| **指标名称中文** | T4-5升级占比环比 |
| **业务定义** | T4-5升级占比当期较上期的变化（差值） |
| **计算公式** | 当期 - 上期（差值，展示时 ×100 转 pts） |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `is_member`和`is_employee`筛选 |
| **聚合粒度** | `dt = 所选时间范围 end period`，`platform, shop_info_id` |
| **数据类型** | delta_pts → 增减基点整数： → +120pts / -80pts（基点，含正负号，值×100 转 pts）,乘以100的操作可以放在Cell Display度量中实现，算环比LP：当期值 − 上期值（差值，pts 指标，展示时 ×100 转 pts） |        
| **数据格式** | `+#,##0pts;-#,##0pts;0pts` |

---
### 4. Retention VIC No. — 留存VIC人数

| 项目 | 内容 |
|---|---|
| **指标名称** | Retention VIC No. |
| **指标名称中文** | 留存VIC人数 |
| **业务定义** | 在指定日期范围仍为 VIC 且上一周期也是 VIC 的人数 |
| **计算公式** | count(distinct user_id) |
| **统计字段** | `user_id` |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `is_retention_vic = 1`；`is_member`和`is_employee`筛选 |
| **聚合粒度** | `dt = 所选时间范围 end period`，`platform, shop_info_id` |
| **数据类型** | integer → 整数，千分位整数 |
| **数据格式** | `#,##0` |

### 4.1 Retention VIC No. vs LY — 留存VIC人数同比

| 项目 | 内容 |
|---|---|
| **指标名称** | Retention VIC No. vs LY |
| **指标名称中文** | 留存VIC人数同比 |
| **业务定义** | 留存VIC人数今年较去年同期的变化率 |
| **计算公式** | 今年 / 去年 - 1 |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `is_retention_vic = 1`；`is_member`和`is_employee`筛选 |
| **聚合粒度** | `dt = 所选时间范围 end period`，`platform, shop_info_id` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

### 4.2 Retention VIC No. vs LP — 留存VIC人数环比

| 项目 | 内容 |
|---|---|
| **指标名称** | Retention VIC No. vs LP |
| **指标名称中文** | 留存VIC人数环比 |
| **业务定义** | 留存VIC人数当期较上期的变化率 |
| **计算公式** | 当期 / 上期 - 1 |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `is_retention_vic = 1`；`is_member`和`is_employee`筛选 |
| **聚合粒度** | `dt = 所选时间范围 end period`，`platform, shop_info_id` |
| **数据类型** | delta_pct_1dp → 百分比，保留一位小数，含正号：+14.5% / -3.2% |
| **数据格式** | IF(__Value > 0, "+", "") & FORMAT(__Value, "#,##0.0%") |

### 4.3 Retention VIC No. Share — 留存VIC占比

| 项目 | 内容 |
|---|---|
| **指标名称** | Retention VIC No. Share |
| **指标名称中文** | 留存VIC占比 |
| **业务定义** | 留存VIC人数占VIC总人数的比例 |
| **计算公式** | 分子：count(distinct user_id) where is_retention_vic = 1；分母：count(distinct user_id) where is_vic = 1 |
| **分子** | `user_id`（`is_retention_vic = 1`） |
| **分母** | `user_id`（`is_vic = 1`） |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `is_member`和`is_employee`筛选 |
| **聚合粒度** | `dt = 所选时间范围 end period`，`platform, shop_info_id` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

### 4.4 Retention VIC No. Share vs LY — 留存VIC占比同比

| 项目 | 内容 |
|---|---|
| **指标名称** | Retention VIC No. Share vs LY |
| **指标名称中文** | 留存VIC占比同比 |
| **业务定义** | 留存VIC占比今年较去年同期的变化（差值） |
| **计算公式** | 今年 - 去年（差值，展示时 ×100 转 pts） |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `is_member`和`is_employee`筛选 |
| **聚合粒度** | `dt = 所选时间范围 end period`，`platform, shop_info_id` |
| **数据类型** | delta_pts → 增减基点整数： → +120pts / -80pts（基点，含正负号，值×100 转 pts）,乘以100的操作可以放在Cell Display度量中实现，算同比LY：当期值 − 同期值（差值，pts 指标，展示时 ×100 转 pts） |        
| **数据格式** | `+#,##0pts;-#,##0pts;0pts` |

### 4.5 Retention VIC No. Share vs LP — 留存VIC占比环比

| 项目 | 内容 |
|---|---|
| **指标名称** | Retention VIC No. Share vs LP |
| **指标名称中文** | 留存VIC占比环比 |
| **业务定义** | 留存VIC占比当期较上期的变化（差值） |
| **计算公式** | 当期 - 上期（差值，展示时 ×100 转 pts） |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `is_member`和`is_employee`筛选 |
| **聚合粒度** | `dt = 所选时间范围 end period`，`platform, shop_info_id` |
| **数据类型** | delta_pts → 增减基点整数： → +120pts / -80pts（基点，含正负号，值×100 转 pts）,乘以100的操作可以放在Cell Display度量中实现，算环比LP：当期值 − 上期值（差值，pts 指标，展示时 ×100 转 pts） |        
| **数据格式** | `+#,##0pts;-#,##0pts;0pts` |

---

### 5. Direct VIC No. — 直接买成VIC人数

| 项目 | 内容 |
|---|---|
| **指标名称** | Direct VIC No. |
| **指标名称中文** | 直接买成VIC人数 |
| **业务定义** | 在指定日期范围往前 Rolling 12 个财月，net sales >= 20k 且在上一周期不是 VIC 的买家数量 |
| **计算公式** | count(distinct user_id) |
| **统计字段** | `user_id` |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `is_direct_vic = 1`；`is_member`和`is_employee`筛选 |
| **聚合粒度** | `dt = 所选时间范围 end period`，`platform, shop_info_id` |
| **数据类型** | integer → 整数，千分位整数 |
| **数据格式** | `#,##0` |

### 5.1 Direct VIC No. vs LY — 直接买成VIC人数同比

| 项目 | 内容 |
|---|---|
| **指标名称** | Direct VIC No. vs LY |
| **指标名称中文** | 直接买成VIC人数同比 |
| **业务定义** | 直接买成VIC人数今年较去年同期的变化率 |
| **计算公式** | 今年 / 去年 - 1 |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `is_direct_vic = 1`；`is_member`和`is_employee`筛选 |
| **聚合粒度** | `dt = 所选时间范围 end period`，`platform, shop_info_id` |
| **数据类型** | delta_pct_1dp → 百分比，保留一位小数，含正号：+14.5% / -3.2% |
| **数据格式** | IF(__Value > 0, "+", "") & FORMAT(__Value, "#,##0.0%") |

### 5.2 Direct VIC No. vs LP — 直接买成VIC人数环比

| 项目 | 内容 |
|---|---|
| **指标名称** | Direct VIC No. vs LP |
| **指标名称中文** | 直接买成VIC人数环比 |
| **业务定义** | 直接买成VIC人数当期较上期的变化率 |
| **计算公式** | 当期 / 上期 - 1 |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `is_direct_vic = 1`；`is_member`和`is_employee`筛选 |
| **聚合粒度** | `dt = 所选时间范围 end period`，`platform, shop_info_id` |
| **数据类型** | delta_pct_1dp → 百分比，保留一位小数，含正号：+14.5% / -3.2% |
| **数据格式** | IF(__Value > 0, "+", "") & FORMAT(__Value, "#,##0.0%") |

### 5.3 Direct VIC No. Share — 直接买成VIC占比

| 项目 | 内容 |
|---|---|
| **指标名称** | Direct VIC No. Share |
| **指标名称中文** | 直接买成VIC占比 |
| **业务定义** | 直接买成VIC人数占VIC总人数的比例 |
| **计算公式** | 分子：count(distinct user_id) where is_direct_vic = 1；分母：count(distinct user_id) where is_vic = 1 |
| **分子** | `user_id`（`is_direct_vic = 1`） |
| **分母** | `user_id`（`is_vic = 1`） |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** |`is_member`和`is_employee`筛选 |
| **聚合粒度** | `dt = 所选时间范围 end period`，`platform, shop_info_id` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

### 5.4 Direct VIC No. Share vs LY — 直接买成VIC占比同比

| 项目 | 内容 |
|---|---|
| **指标名称** | Direct VIC No. Share vs LY |
| **指标名称中文** | 直接买成VIC占比同比 |
| **业务定义** | 直接买成VIC占比今年较去年同期的变化（差值） |
| **计算公式** | 今年 - 去年（差值，展示时 ×100 转 pts） |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `is_member`和`is_employee`筛选 |
| **聚合粒度** | `dt = 所选时间范围 end period`，`platform, shop_info_id` |
| **数据类型** | delta_pts → 增减基点整数： → +120pts / -80pts（基点，含正负号，值×100 转 pts）,乘以100的操作可以放在Cell Display度量中实现，算同比LY：当期值 − 同期值（差值，pts 指标，展示时 ×100 转 pts） |        
| **数据格式** | `+#,##0pts;-#,##0pts;0pts` |

### 5.5 Direct VIC No. Share vs LP — 直接买成VIC占比环比

| 项目 | 内容 |
|---|---|
| **指标名称** | Direct VIC No. Share vs LP |
| **指标名称中文** | 直接买成VIC占比环比 |
| **业务定义** | 直接买成VIC占比当期较上期的变化（差值） |
| **计算公式** | 当期 - 上期（差值，展示时 ×100 转 pts） |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `is_member`和`is_employee`筛选 |
| **聚合粒度** | `dt = 所选时间范围 end period`，`platform, shop_info_id` |
| **数据类型** | delta_pts → 增减基点整数： → +120pts / -80pts（基点，含正负号，值×100 转 pts）,乘以100的操作可以放在Cell Display度量中实现，算环比LP：当期值 − 上期值（差值，pts 指标，展示时 ×100 转 pts） |        
| **数据格式** | `+#,##0pts;-#,##0pts;0pts` |

---

## 通用规则汇总

| 规则项 | 说明 |
|---|---|
| **数据底表** | `a03_e2e_customer_data_m`、`t05_customer_order_data_d` |
| **筛选逻辑** | 模块全局影响：除了特殊说明之外的指标不需要判断is_member和is_employee，其余都默认需要判断is_member和is_employee来确定筛选事实表的值  |
| **货币转换规则** | 数据源默认为 RMB，转化为美元需要除以固定值 7 |
| **派生指标** | LY（去年同期）、LP（上期）、vs LY（同比）、vs LP（环比）、占比、YOY、vs Store 等为派生指标，依据基础指标计算生成 |
| **分组维度** | 根据 `platform, shop_info_id`、`timeframe`（Month/Quarter/Year）、`customer_tier`（T1/T2/T3/T4/T5）、`last_fy_last_order_month_type`（R3/R4-6/R7-9/R10-12/TTL）、VIC 类型（New VIC/Retention VIC/Direct VIC/T4-5 Upgrade）分组 |
| **必须遵守** | 口径文档中定义的所有指标，必须遵守其数据类型和数据格式，如果和解决方案中存在争议的，一切以口径文档为准，必须按照口径文档中的格式进行调整 |
| **DAX 语法规范** | 文本常量必须使用双引号 `" "`，禁止使用单引号；单引号 `' '` 仅用于表名，列名使用方括号 `[ ]`，例如：`[is_vic] = 1` |
| **pts 与 bp 区别** | pts 指标：值×100 转 pts（基点，含正负号），数据格式 `+#,##0pts;-#,##0pts;0pts`；bp 指标：值×10000 转 bp，数据格式 `+#,##0bp;-#,##0bp;0bp` |
| **TAR ACH% 占位** | Monthly TAR ACH% / Yearly TAR ACH% / TAR ACH% 逻辑暂未确认，先保持子指标占位，数据格式为 percent_1dp："#,##0.0%"，等逻辑确认后再填充 |
| **VIC 定义** | 在指定日期范围往前 Rolling 12 个财月，net sales >= 20k 的买家 |
| **Tier 分层定义** | T1：≧ 200K；T2：80-200K；T3：20-80K；T4：5-20K；T5：< 5K |
| **Recency 分层定义** | R3：上财年 10-12 月；R4-6：上财年 7-9 月；R7-9：上财年 4-6 月；R10-12：上财年 1-3 月；TTL：全部 |
