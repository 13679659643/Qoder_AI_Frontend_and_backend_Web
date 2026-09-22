# Customer Dashboard 指标口径提示词

> **Dashboard**: Customer Dashboard  
> **Tab**: VIC  
> **数据底表**: `a03_e2e_customer_data_m` / `t05_customer_order_data_d`  
> **模块全局影响说明**:  人群细分：切片器 TTL VIC（`IsMember = 0`）→ 事实表 `is_member = 0`；Member VIC（`IsMember = 1`）→ 事实表 `is_member = 0 AND register_date <= end_period_date`；Is Employee `is_employee = 1` or `is_employee = 0`
> **is_member使用**: `VAR __IsMemberFilter = SELECTEDVALUE(IsMemberFilter[IsMember], 0)`，默认 TTL VIC。维度表与事实表断开，由 DAX 显式处理：两档均筛选 `a03_e2e_customer_data_m[is_member] = 0`；仅当选择 Member VIC（1）时，追加 `register_date <= end_period_date`。本期截止日取 `Slicer_Time_Frame_Max[Last_Fiscal_Month_Max]`，LY 截止日取 `Last_Fiscal_Month_Max_LY`；本表格无 LP 指标
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
| **模块全局影响说明** | 人群细分：切片器 TTL VIC（`IsMember = 0`）→ 事实表 `is_member = 0`；Member VIC（`IsMember = 1`）→ 事实表 `is_member = 0 AND register_date <= end_period_date`；Is Employee `is_employee = 1` or `is_employee = 0` |
| **is_member使用** | `VAR __IsMemberFilter = SELECTEDVALUE(IsMemberFilter[IsMember], 0)`，默认 TTL VIC。维度表与事实表断开，由 DAX 显式处理：两档均筛选 `a03_e2e_customer_data_m[is_member] = 0`；仅当选择 Member VIC（1）时，追加 `register_date <= end_period_date`。本期截止日取 `Slicer_Time_Frame_Max[Last_Fiscal_Month_Max]`，LY 截止日取 `Last_Fiscal_Month_Max_LY`；本表格无 LP 指标 |
| **is_employee使用** | VAR __IsEmployeeFilter = SELECTEDVALUE(Slicer_Is_Employee_Selection[IsEmployee_Code], 1)，如果没有筛选，则默认Yes。这样过滤事实表a03_e2e_customer_data_m[is_employee] = __IsEmployeeFilter |
| **is_member和is_employee维度表路径** | is_member： D:\gutao\辜涛\Project\Qoder_AI_Frontend_and_backend_Web\RL E2E\RL E2E Customer Dashboard\维度复用\IsMemberFilter；is_employee： D:\gutao\辜涛\Project\Qoder_AI_Frontend_and_backend_Web\RL E2E\RL E2E Customer Dashboard\维度复用\Slicer_Is_Employee_Selection |
| **end period说明** | 所选时间范围的最后一个财月，只关注 `Slicer_Time_Frame_Max`：本期 `data_date` 筛选 `Last_Fiscal_Month_Min` ~ `Last_Fiscal_Month_Max`，LY 筛选 `Last_Fiscal_Month_Min_LY` ~ `Last_Fiscal_Month_Max_LY`；`end_period_date` 为对应区间的最后一天，不按自然月自行推算 |

---

## 子模块三：VIC Composition & By Recency Repurchase

> **分组维度**: 固定值：R3, R4-6, R7-9, R10-12, TTL,已有DIM_Row_LY_Last_Purchase_Time行维度字段，参考文件：D:\Users\QiYe\BaoZun\Project\Qoder_AI_Frontend_and_backend_Web\RL E2E\RL E2E Customer Dashboard\VIC\LY Last Purchase Time\DIM_Row_LY_Last_Purchase_Time.md,DIM_Row_LY_Last_Purchase_Time和a03_e2e_customer_data_m表，模型关系为1:N，所以分组维度由模型自动传递，DAX 无需显式处理分组；

---

### 1. LY Last Purchase Time — 去年VIC最后一个订单的购买时间范围

| 项目 | 内容 |
|---|---|
| **指标名称** | LY Last Purchase Time |
| **指标名称中文** | 去年VIC最后一个订单的购买时间范围 |
| **业务定义** | R3：上财年 10-12 月；R4-6：上财年 7-9 月；R7-9：上财年 4-6 月；R10-12：上财年 1-3 月 |
| **计算公式** | a03_e2e_customer_data_m[last_fy_last_order_month_type],字段值包括：R3, R4-6, R7-9, R10-12 |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | 分组维度由表字段自动传递，DAX 无需显式处理 分组 |

---

### 2. LY VIC No. — 去年VIC人数

| 项目 | 内容 |
|---|---|
| **指标名称** | LY VIC No. |
| **指标名称中文** | 去年VIC人数 |
| **业务定义** | R3：这一财年的 VIC，且上财年最后一单落在上财年 10-12 月的 VIC 人数；R4-6：这一财年的 VIC，且上财年最后一单落在上财年 7-9 月的 VIC 人数；R7-9：这一财年的 VIC，且上财年最后一单落在上财年 4-6 月的 VIC 人数；R10-12：这一财年的 VIC，且上财年最后一单落在上财年 1-3 月的 VIC 人数 |
| **计算公式** | count(distinct user_id) |
| **统计字段** | `user_id` |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `is_fy_vic = 1`;`is_member`和`is_employee`筛选 |
| **聚合粒度** | `dt = 所选时间范围 end period`，`platform, shop_info_id`分组维度由表字段自动传递，DAX 无需显式处理 |
| **数据类型** | integer → 整数，千分位整数 |
| **数据格式** | `#,##0` |

---

### 3. VIC Repurchase No. — 复购VIC人数

| 项目 | 内容 |
|---|---|
| **指标名称** | VIC Repurchase No. |
| **指标名称中文** | 复购VIC人数 |
| **业务定义** | R3：这一财年的 VIC，且上财年最后一单落在上财年 10-12 月，并且所选时间范围 end period 往前推 12 个月有复购的 VIC 人数；R4-6：这一财年的 VIC，且上财年最后一单落在上财年 7-9 月，并且所选时间范围 end period 往前推 12 个月有复购的 VIC 人数；R7-9：这一财年的 VIC，且上财年最后一单落在上财年 4-6 月，并且所选时间范围 end period 往前推 12 个月有复购的 VIC 人数；R10-12：这一财年的 VIC，且上财年最后一单落在上财年 1-3 月，并且所选时间范围 end period 往前推 12 个月有复购的 VIC 人数 |
| **计算公式** | count(distinct user_id) |
| **统计字段** | `user_id` |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `is_fy_vic = 1`;`last_12m_net_pay_amt` > 0;`is_member`和`is_employee`筛选 |
| **聚合粒度** | `dt = 所选时间范围 end period`，`platform, shop_info_id`分组维度由表字段自动传递，DAX 无需显式处理 |
| **数据类型** | integer → 整数，千分位整数 |
| **数据格式** | `#,##0` |

---

### 4. VIC Retention No. — 留存VIC人数

| 项目 | 内容 |
|---|---|
| **指标名称** | VIC Retention No. |
| **指标名称中文** | 留存VIC人数 |
| **业务定义** | R3：这一财年的 VIC，且上财年最后一单落在上财年 10-12 月，并且所选时间范围 end period 往前推 12 个月留存为 VIC 的人数；R4-6：这一财年的 VIC，且上财年最后一单落在上财年 7-9 月，并且所选时间范围 end period 往前推 12 个月留存为 VIC 的人数；R7-9：这一财年的 VIC，且上财年最后一单落在上财年 4-6 月，并且所选时间范围 end period 往前推 12 个月留存为 VIC 的人数；R10-12：这一财年的 VIC，且上财年最后一单落在上财年 1-3 月，并且所选时间范围 end period 往前推 12 个月留存为 VIC 的人数 |
| **计算公式** | count(distinct user_id) |
| **统计字段** | `user_id` |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `is_fy_retention_vic = 1`;`is_member`和`is_employee`筛选 |
| **聚合粒度** | `dt = 所选时间范围 end period`，`platform, shop_info_id`分组维度由表字段自动传递，DAX 无需显式处理 |
| **数据类型** | integer → 整数，千分位整数 |
| **数据格式** | `#,##0` |

---

### 5. VIC Repurchase% — 复购VIC占比

| 项目 | 内容 |
|---|---|
| **指标名称** | VIC Repurchase% |
| **指标名称中文** | 复购VIC占比 |
| **业务定义** | 该分层下复购 VIC 人数/总 VIC 人数 |
| **计算公式** | 分子：VIC Repurchase No.；分母：LY VIC No.;复购VIC人数/去年VIC人数 |
| **分子** | VIC Repurchase No. |
| **分母** | LY VIC No. |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `is_member`和`is_employee`筛选 |
| **聚合粒度** | `dt = 所选时间范围 end period`，`platform, shop_info_id`分组维度由表字段自动传递，DAX 无需显式处理 |
| **数据类型** | percent_0dp → 百分比整数，不含正号 |
| **数据格式** | `#,##0%` |

---

### 6. VIC Repurchase% YOY — 复购VIC占比YOY

| 项目 | 内容 |
|---|---|
| **指标名称** | VIC Repurchase% YOY |
| **指标名称中文** | 复购VIC占比YOY |
| **业务定义** | 该分层下复购率和去年的对比 |
| **计算公式** | 今年 / 去年 - 1 |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `is_member`和`is_employee`筛选 |
| **聚合粒度** | `dt = 所选时间范围 end period`，`platform, shop_info_id`分组维度由表字段自动传递，DAX 无需显式处理 |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

---

### 7. VIC Retention% — 留存VIC占比

| 项目 | 内容 |
|---|---|
| **指标名称** | VIC Retention% |
| **指标名称中文** | 留存VIC占比 |
| **业务定义** | 该分层下 Retention No. / LY VIC No. |
| **计算公式** | 分子：Retention No.；分母：LY VIC No. |
| **分子** | Retention No.（沿用现有指标名称 VIC Retention No.），筛选 `is_fy_retention_vic = 1` 后对 `user_id` 去重计数 |
| **分母** | LY VIC No.，筛选 `is_fy_vic = 1` 后对 `user_id` 去重计数；分子、分母均取对应 end period 当月，保留当前分层、platform、shop_info_id 和全局人群筛选 |
| **指标区分** | 本模块业务指标为 Retention%，沿用现有 VIC Retention% 命名，不适用其他模块 VIC Retention% 的分母调整口径 |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `is_member`和`is_employee`筛选 |
| **聚合粒度** | `dt = 所选时间范围 end period`，`platform, shop_info_id`分组维度由表字段自动传递，DAX 无需显式处理 |
| **数据类型** | percent_0dp → 百分比整数，不含正号 |
| **数据格式** | `#,##0%` |

---

### 8. VIC Retention% YOY — 留存VIC占比YOY

| 项目 | 内容 |
|---|---|
| **指标名称** | VIC Retention% YOY |
| **指标名称中文** | 留存VIC占比YOY |
| **业务定义** | 该分层下留存率和去年的对比 |
| **计算公式** | 今年 Retention% / 去年 Retention% - 1；两期分别按指标 7 的 Retention No. / LY VIC No. 计算 |
| **分母时间与字段** | 今年 Retention% 分母取本期 end period 当月的 LY VIC No.；去年 Retention% 分母取 LY end period 当月的 LY VIC No.，均沿用 `is_fy_vic = 1` 的去重人数口径 |
| **会员截止日** | Member VIC 模式下，本期分子、分母追加 `register_date <= Last_Fiscal_Month_Max`；LY 分子、分母追加 `register_date <= Last_Fiscal_Month_Max_LY`；两期事实表均筛选 `is_member = 0` |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `is_member`和`is_employee`筛选 |
| **聚合粒度** | `dt = 所选时间范围 end period`，`platform, shop_info_id`分组维度由表字段自动传递，DAX 无需显式处理 |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

---

## 通用规则汇总

| 规则项 | 说明 |
|---|---|
| **数据底表** | `a03_e2e_customer_data_m`、`t05_customer_order_data_d` |
| **筛选逻辑** | 模块全局影响：除了特殊说明之外的指标不需要判断is_member和is_employee，其余都默认需要判断is_member和is_employee来确定筛选事实表的值  |
| **货币转换规则** | 数据源默认为 RMB，转化为美元需要除以固定值 7 |
| **派生指标** | LY（去年同期）、LP（上期）、vs LY（同比）、vs LP（环比）、占比、YOY、vs Store 等为派生指标，依据基础指标计算生成 |
| **分组维度** | 根据 `platform, shop_info_id`分组维度由表字段自动传递，DAX 无需显式处理、`timeframe`（Month/Quarter/Year）、`customer_tier`（T1/T2/T3/T4/T5）、`last_fy_last_order_month_type`（R3/R4-6/R7-9/R10-12/TTL）、VIC 类型（New VIC/Retention VIC/Direct VIC/T4-5 Upgrade）分组 |
| **必须遵守** | 口径文档中定义的所有指标，必须遵守其数据类型和数据格式，如果和解决方案中存在争议的，一切以口径文档为准，必须按照口径文档中的格式进行调整 |
| **DAX 语法规范** | 文本常量必须使用双引号 `" "`，禁止使用单引号；单引号 `' '` 仅用于表名，列名使用方括号 `[ ]`，例如：`[is_vic] = 1` |
| **pts 与 bp 区别** | pts 指标：值×100 转 pts（基点，含正负号），数据格式 `+#,##0pts;-#,##0pts;0pts`；bp 指标：值×10000 转 bp，数据格式 `+#,##0bp;-#,##0bp;0bp` |
| **TAR ACH% 占位** | Monthly TAR ACH% / Yearly TAR ACH% / TAR ACH% 逻辑暂未确认，先保持子指标占位，数据格式为 percent_1dp："#,##0.0%"，等逻辑确认后再填充 |
| **VIC 定义** | 在指定日期范围往前 Rolling 12 个财月，net sales >= 20k 的买家 |
| **Tier 分层定义** | T1：≧ 200K；T2：80-200K；T3：20-80K；T4：5-20K；T5：< 5K |
| **Recency 分层定义** | R3：上财年 10-12 月；R4-6：上财年 7-9 月；R7-9：上财年 4-6 月；R10-12：上财年 1-3 月；TTL：全部 |
| **会员筛选** | 指标 2~8 及其派生计算均采用全局会员规则：TTL VIC 仅筛事实表 `is_member = 0`；Member VIC 在此基础上追加注册日期不晚于对应 end period 最后一天 |
| **Retention% 口径** | 指标 7 为 Retention No. / LY VIC No.，指标 8 基于两期相同口径计算 YOY；复用既有 LY VIC No. 分母，无独立分母计算 |
