# Customer Dashboard 指标口径提示词

> **Dashboard**: Customer Dashboard  
> **Tab**: VIC  
> **数据底表**: `a03_e2e_customer_data_m` / `t05_customer_order_data_d`  
> **模块全局影响说明**:  `is_member`和`is_employee`筛选,人群细分 ：TTL VIC `is_member = 0` / Member VIC `is_member = 1` / Is Employee `is_employee = 1` or `is_employee = 0`
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
| **模块全局影响说明** | `is_member`和`is_employee`筛选,人群细分 ：TTL VIC `is_member = 0` / Member VIC `is_member = 1` / Is Employee `is_employee = 1` or `is_employee = 0`  |
| **is_member使用** | VAR __IsMemberFilter = SELECTEDVALUE(IsMemberFilter[IsMember], 0)，如果没有筛选，则默认TTL VIC。这样过滤事实表a03_e2e_customer_data_m[is_member] = __IsMemberFilter |
| **is_employee使用** | VAR __IsEmployeeFilter = SELECTEDVALUE(Slicer_Is_Employee_Selection[IsEmployee_Code], 1)，如果没有筛选，则默认Yes。这样过滤事实表a03_e2e_customer_data_m[is_employee] = __IsEmployeeFilter |
| **is_member和is_employee维度表路径** | is_member： D:\gutao\辜涛\Project\Qoder_AI_Frontend_and_backend_Web\RL E2E\RL E2E Customer Dashboard\维度复用\IsMemberFilter；is_employee： D:\gutao\辜涛\Project\Qoder_AI_Frontend_and_backend_Web\RL E2E\RL E2E Customer Dashboard\维度复用\Slicer_Is_Employee_Selection |
| **end period说明** | 所选时间范围的最后一个财月,Slicer_Time_Frame_Max维度表已经给出了具体的Last_Fiscal_Month、Last_Fiscal_Month_Min等字段，只关注Slicer_Time_Frame_Max值,比如2026-09，只关注2023-09；2026 Q2，只关注2026-06；财年2026，对应最后一个财月只关注2026-12； |
| **dt = 所选时间范围** | 涉及到t05_customer_order_data_d表计算，dt = 所选时间范围，所选时间范围的计算,dt ∈ [__TimeMin, __TimeMax]（全局时间范围），Slicer_Time_Frame_Min和Slicer_Time_Frame_Max维度表已经给出了具体的TimeFrame_Min和TimeFrame_Max值 |

---

## 子模块：Class x Label Drilldown

> **分组维度**: 按 `platform, shop_info_id, category_summary, framework, tier，product_id` 分组，由表字段自动传递，DAX 无需显式处理分组。
> **计算模式（两步法）**: 
> - Step 1：在 `a03_e2e_customer_data_m` 中，dt = 所选时间范围 end period，筛选对应 VIC 标识（is_retention_vic / is_upgrade_vic / is_direct_vic / is_new_vic = 1），框定 user_id 范围；
> - Step 2：在 `t05_customer_order_data_d` 中，dt = 所选时间范围，限定 user_id ∈ Step 1 框定范围，直接统计 count(distinct user_id)，我理解分组字段会自动进行模型的筛选。platform, shop_info_id,, tier直接拉取`a03_e2e_customer_data_m`表，category_summary, framework,product_id拉取`t05_customer_order_data_d`表中的字段。
> **VIC 类型区分**: 不同 VIC 类型仅 Step 1 的筛选标识不同（is_retention_vic = 1 / is_upgrade_vic = 1 / is_direct_vic = 1 / is_new_vic = 1），Step 2 逻辑完全一致。
> **dt = 所选时间范围** | 涉及到t05_customer_order_data_d表计算，dt = 所选时间范围，所选时间范围的计算,dt ∈ [__TimeMin, __TimeMax]（全局时间范围），Slicer_Time_Frame_Min和Slicer_Time_Frame_Max维度表已经给出了具体的TimeFrame_Min和TimeFrame_Max值

### 1. VIC No.（Net_Retention VIC） — 留存VIC数量

| 项目 | 内容 |
|---|---|
| **指标名称** | VIC No.（Net_Retention VIC） |
| **指标名称中文** | VIC数量 |
| **业务定义** | 在指定日期范围往前 Rolling 12 个财月，net sales >= 20k 的买家数量（留存 VIC） |
| **计算公式** | Step 1：在 `a03_e2e_customer_data_m` 中，dt = 所选时间范围 end period，筛选 is_retention_vic = 1，框定 user_id 范围；Step 2：在 `t05_customer_order_data_d` 中，dt = 所选时间范围，统计各个 product_id 下 count(distinct user_id)，限定 user_id ∈ Step 1 框定范围，product_id由表字段自动传递，DAX 无需显式处理分组。 |
| **统计字段** | `user_id`（Step 2 在 `t05_customer_order_data_d` 中 count distinct） |
| **数据底表** | `a03_e2e_customer_data_m`、`t05_customer_order_data_d` |
| **筛选条件** | Step 1：`is_retention_vic = 1`、`is_member`和`is_employee`筛选；Step 2：`user_id` ∈ Step 1 范围 |
| **聚合粒度** | 按 `platform, shop_info_id, category_summary, framework, tier，product_id` 分组，由表字段自动传递，DAX 无需显式处理分组。 |
| **数据类型** | integer → 整数，千分位整数 |
| **数据格式** | `#,##0` |

---

### 2. VIC No.（Net_T4-5 Upgrade） — T4-5升级VIC数量

| 项目 | 内容 |
|---|---|
| **指标名称** | VIC No.（Net_T4-5 Upgrade） |
| **指标名称中文** | VIC数量 |
| **业务定义** | 在指定日期范围往前 Rolling 12 个财月，net sales >= 20k 的买家数量（T4-5 升级 VIC） |
| **计算公式** | Step 1：在 `a03_e2e_customer_data_m` 中，dt = 所选时间范围 end period，筛选 is_upgrade_vic = 1，框定 user_id 范围；Step 2：在 `t05_customer_order_data_d` 中，dt = 所选时间范围，统计各个 product_id 下 count(distinct user_id)，限定 user_id ∈ Step 1 框定范围 |
| **统计字段** | `user_id`（Step 2 在 `t05_customer_order_data_d` 中 count distinct） |
| **数据底表** | `a03_e2e_customer_data_m`、`t05_customer_order_data_d` |
| **筛选条件** | Step 1：`is_upgrade_vic = 1`、`is_member`和`is_employee`筛选；Step 2：`user_id` ∈ Step 1 范围 |
| **聚合粒度** | 按 `platform, shop_info_id, category_summary, framework, tier，product_id` 分组，由表字段自动传递，DAX 无需显式处理分组。 |
| **数据类型** | integer → 整数，千分位整数 |
| **数据格式** | `#,##0` |

---

### 3. VIC No.（Net_Direct VIC） — 直接买成VIC数量

| 项目 | 内容 |
|---|---|
| **指标名称** | VIC No.（Net_Direct VIC） |
| **指标名称中文** | VIC数量 |
| **业务定义** | 在指定日期范围往前 Rolling 12 个财月，net sales >= 20k 的买家数量（直接买成 VIC） |
| **计算公式** | Step 1：在 `a03_e2e_customer_data_m` 中，dt = 所选时间范围 end period，筛选 is_direct_vic = 1，框定 user_id 范围；Step 2：在 `t05_customer_order_data_d` 中，dt = 所选时间范围，统计各个 product_id 下 count(distinct user_id)，限定 user_id ∈ Step 1 框定范围 |
| **统计字段** | `user_id`（Step 2 在 `t05_customer_order_data_d` 中 count distinct） |
| **数据底表** | `a03_e2e_customer_data_m`、`t05_customer_order_data_d` |
| **筛选条件** | Step 1：`is_direct_vic = 1`、`is_member`和`is_employee`筛选；Step 2：`user_id` ∈ Step 1 范围 |按 `platform, shop_info_id, category_summary, framework, tier，product_id` 分组，由表字段自动传递，DAX 无需显式处理分组。 |
| **数据类型** | integer → 整数，千分位整数 |
| **数据格式** | `#,##0` |

---

### 4. VIC No.（Net_New VIC） — 新VIC数量

| 项目 | 内容 |
|---|---|
| **指标名称** | VIC No.（Net_New VIC） |
| **指标名称中文** | VIC数量 |
| **业务定义** | 在指定日期范围往前 Rolling 12 个财月，net sales >= 20k 的买家数量（新 VIC） |
| **计算公式** | Step 1：在 `a03_e2e_customer_data_m` 中，dt = 所选时间范围 end period，筛选 is_new_vic = 1，框定 user_id 范围；Step 2：在 `t05_customer_order_data_d` 中，dt = 所选时间范围，统计各个 product_id 下 count(distinct user_id)，限定 user_id ∈ Step 1 框定范围 |
| **统计字段** | `user_id`（Step 2 在 `t05_customer_order_data_d` 中 count distinct） |
| **数据底表** | `a03_e2e_customer_data_m`、`t05_customer_order_data_d` |
| **筛选条件** | Step 1：`is_new_vic = 1`、`is_member`和`is_employee`筛选；Step 2：`user_id` ∈ Step 1 范围 |
| **聚合粒度** | 按 `platform, shop_info_id, category_summary, framework, tier，product_id` 分组，由表字段自动传递，DAX 无需显式处理分组。 |
| **数据类型** | integer → 整数，千分位整数 |
| **数据格式** | `#,##0` |

---

## 通用规则汇总

| 规则项 | 说明 |
|---|---|
| **数据底表** | `a03_e2e_customer_data_m`、`t05_customer_order_data_d` |
| **筛选逻辑** | 模块全局影响：除了特殊说明之外的指标不需要判断is_member和is_employee，其余都默认需要判断is_member和is_employee来确定筛选事实表的值  |
| **货币转换规则** | 数据源默认为 RMB，转化为美元需要除以固定值 7 |
| **派生指标** | LY（去年同期）、LP（上期）、vs LY（同比）、vs LP（环比）、占比、YOY、vs Store 等为派生指标，依据基础指标计算生成 |
| **分组维度** | 根据 `platform, shop_info_id, category_summary, framework, tier` 分组维度由表字段自动传递，DAX 无需显式处理、`timeframe`（Month/Quarter/Year）、`customer_tier`（T1/T2/T3/T4/T5）、`last_fy_last_order_month_type`（R3/R4-6/R7-9/R10-12/TTL）、VIC 类型（New VIC/Retention VIC/Direct VIC/T4-5 Upgrade）分组 |
| **必须遵守** | 口径文档中定义的所有指标，必须遵守其数据类型和数据格式，如果和解决方案中存在争议的，一切以口径文档为准，必须按照口径文档中的格式进行调整 |
| **DAX 语法规范** | 文本常量必须使用双引号 `" "`，禁止使用单引号；单引号 `' '` 仅用于表名，列名使用方括号 `[ ]`，例如：`[is_retention_vic] = 1` |
| **pts 与 bp 区别** | pts 指标：值×100 转 pts（基点，含正负号），数据格式 `+#,##0pts;-#,##0pts;0pts`；bp 指标：值×10000 转 bp，数据格式 `+#,##0bp;-#,##0bp;0bp` |
| **TAR ACH% 占位** | Monthly TAR ACH% / Yearly TAR ACH% / TAR ACH% 逻辑暂未确认，先保持子指标占位，数据格式为 percent_1dp："#,##0.0%"，等逻辑确认后再填充 |
| **VIC 定义** | 在指定日期范围往前 Rolling 12 个财月，net sales >= 20k 的买家 |
| **Tier 分层定义** | T1：≧ 200K；T2：80-200K；T3：20-80K；T4：5-20K；T5：< 5K |
| **Recency 分层定义** | R3：上财年 10-12 月；R4-6：上财年 7-9 月；R7-9：上财年 4-6 月；R10-12：上财年 1-3 月；TTL：全部 |
| **两步法计算说明** | 本模块所有 VIC No. 指标均采用两步法：Step 1 在 `a03_e2e_customer_data_m` 中按对应 VIC 标识框定 user_id 范围（dt = end period）；Step 2 在 `t05_customer_order_data_d` 中按 dt = 所选时间范围统计 count(distinct user_id) by product_id，限定 user_id ∈ Step 1 范围 |
| **人群细分** | TTL VIC: `is_member = 0`；Member VIC: `is_member = 1`；Is Employee: `is_employee = 1`（在 `a03_e2e_customer_data_m` 的 Step 1 中应用） |
