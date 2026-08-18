# Customer Dashboard 指标口径提示词 — TAR ACH%

> **Dashboard**: Customer Dashboard  
> **Tab**: VIC  
> **数据底表**: `a03_e2e_customer_data_m` / `a03_e2e_customer_fcst_data_m`  
> **data_date = 所选时间范围** | 实际值之前已经写了计算逻辑，目标值使用a03_e2e_customer_fcst_data_m表计算，data_date = 所选时间范围，所选时间范围的计算,data_date ∈ [__TimeMin, __TimeMax]（全局时间范围），Slicer_Time_Frame_Min和Slicer_Time_Frame_Max维度表已经给出了具体的TimeFrame_Min和TimeFrame_Max值

---

## 全局逻辑

| 项目 | 内容 |
|---|---|
| **数据底表（实际值）** | `a03_e2e_customer_data_m`、`t05_customer_order_data_d` |
| **数据底表（目标值）** | `a03_e2e_customer_fcst_data_m`，日期字段 `data_date` |
| **聚合粒度** | 数字卡片：所选时间范围 `data_date`（end period），所选时间范围的最后一个财月，只关注Max；表格：按对应维度聚合 |
| **货币转换规则** | 数据源默认为 RMB，转化为美元需要除以固定值 7 |
| **派生指标** | LY（去年同期）、LP（上期）、vs LY（同比）、vs LP（环比）、占比、YOY 等为派生指标，依据基础指标计算生成 |
| **必须遵守** | 口径文档中定义的所有指标，必须遵守其数据类型和数据格式，如果和解决方案中存在争议的，一切以口径文档为准，必须按照口径文档中的格式进行调整 |
| **end period说明** | 所选时间范围的最后一个财月，只关注Slicer_Time_Frame_Max值，比如2026-09，只关注2026-09；2026 Q2，只关注2026-06；财年2026，对应最后一个财月只关注2026-12； |
| **TAR ACH% 通用说明** | TAR ACH% = Actual / Target，根据TimeFrame选择（Month/Quarter/Year）和选择范围（单个/多个）决定分子和分母的取数逻辑；仅选择单个财月/单个财年时有值，多选时留空 |
| **目标值表说明** | 目标值均取自 `a03_e2e_customer_fcst_data_m`，日期字段为 `data_date`，按 `data_date = 所选时间范围`，`group by platform, shop_info_id` 聚合 |
| **data_date = 所选时间范围** | 实际值之前已经写了计算逻辑，目标值使用a03_e2e_customer_fcst_data_m表计算，data_date = 所选时间范围，所选时间范围的计算,data_date ∈ [__TimeMin, __TimeMax]（全局时间范围），Slicer_Time_Frame_Min和Slicer_Time_Frame_Max维度表已经给出了具体的TimeFrame_Min和TimeFrame_Max值 |

---

## 子模块一：VIC Monthly TAR ACH% — 月度目标达成率

| 项目 | 内容 |
|---|---|
| **指标名称** | VIC Monthly TAR ACH% |
| **指标名称中文** | VIC月度目标达成率 |
| **业务定义** | VIC数量实际值与月度目标值之比，仅选择单个财月时有值 |
| **计算公式** | 实际值 / 目标值 |
| **实际值** | VIC No. |
| **目标值取数逻辑** | `data_date = 所选时间范围`，data_date ∈ [TimeFrame_Min, TimeFrame_Max]（全局时间范围），目标值 = SUM(`vic_customer_cnt`) |
| **目标值底表** | `a03_e2e_customer_fcst_data_m`，日期字段 `data_date` |
| **数据底表（实际值）** | `a03_e2e_customer_data_m` |
| **筛选条件** | `data_date`筛选 |
| **聚合粒度** | `data_date = 所选时间范围`，data_date ∈ [TimeFrame_Min, TimeFrame_Max]（全局时间范围） |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

**Monthly TAR ACH% 计算规则矩阵（VIC No.）、仅选择单个财月/年有值**

| TimeFrame | 选择范围 | 分子 | 分母 | 说明 |
|---|---|---|---|---|
| Month | 选择单个财月 | VIC No.（month actual） | SUM(`vic_customer_cnt`) | 实际值 / 月度目标值 |
| Month | 选择多个财月 | — | — | **留空**，多个月不计算Monthly TAR ACH% |
| Month | 选择多个财月且跨财年 | — | — | **留空** |
| Quarter | 任意选择范围 | — | — | **留空**，Quarter下不计算Monthly TAR ACH% |
| Year | 任意选择范围 | — | — | **留空**，Year下不计算Monthly TAR ACH% |

---

## 子模块二：VIC Yearly TAR ACH% — 年度目标达成率

| 项目 | 内容 |
|---|---|
| **指标名称** | VIC Yearly TAR ACH% |
| **指标名称中文** | VIC年度目标达成率 |
| **业务定义** | VIC数量实际值总和与年度目标值之比，仅选择单个财月/单个财年时有值 |
| **计算公式** | 实际值总和 / 年目标值 |
| **实际值** | VIC No. |
| **目标值取数逻辑** | `data_date = 所选时间范围`，data_date ∈ [TimeFrame_Min, TimeFrame_Max]（全局时间范围），目标值 = SUM(DISTINCT `year_vic_customer_cnt`) |
| **目标值底表** | `a03_e2e_customer_fcst_data_m`，日期字段 `data_date` |
| **数据底表（实际值）** | `a03_e2e_customer_data_m` |
| **筛选条件** | `data_date`筛选 |
| **聚合粒度** | `data_date = 所选时间范围`，data_date ∈ [TimeFrame_Min, TimeFrame_Max]（全局时间范围） |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

**Yearly TAR ACH% 计算规则矩阵（VIC No.）、仅选择单个财月/年有值**

| TimeFrame | 选择范围 | 分子 | 分母 | 说明 |
|---|---|---|---|---|
| Month | 选择单个财月 | VIC No.（month actual） | SUM(DISTINCT `year_vic_customer_cnt`) | 单月实际 / 年度目标值 |
| Month | 选择多个财月 | — | — | **留空**，多个月不计算Yearly TAR ACH% |
| Month | 选择多个财月且跨财年 | — | — | **留空** |
| Quarter | 任意选择范围 | — | — | **留空**，Quarter下不计算Yearly TAR ACH% |
| Year | 选择单个财年 | VIC No.（year actual） | SUM(DISTINCT `year_vic_customer_cnt`) | 年度实际 / 年度目标值 |
| Year | 选择多个财年 | — | — | **留空**，多年不计算Yearly TAR ACH% |

---

## 子模块三：VIC Retention% TAR ACH% — 目标达成率

| 项目 | 内容 |
|---|---|
| **指标名称** | VIC Retention% TAR ACH% |
| **指标名称中文** | VIC留存率目标达成率 |
| **业务定义** | VIC留存率实际值与年度目标值之比，仅选择单个财月/单个财年且单个shop时有值 |
| **计算公式** | 实际值 / 年目标值 |
| **实际值** | VIC Retention% |
| **目标值取数逻辑** | `data_date = 所选时间范围`，data_date ∈ [TimeFrame_Min, TimeFrame_Max]（全局时间范围），目标值 = DISTINCT `year_vic_retention_percent` ,这里没有SUM，是因为VIC Retention%是个百分比，不需要SUM；|
| **目标值底表** | `a03_e2e_customer_fcst_data_m`，日期字段 `data_date` |
| **数据底表（实际值）** | `a03_e2e_customer_data_m` |
| **筛选条件** | `data_date`筛选 |
| **聚合粒度** | `data_date = 所选时间范围`，data_date ∈ [TimeFrame_Min, TimeFrame_Max]（全局时间范围）， |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

**TAR ACH% 计算规则矩阵（VIC Retention%）、仅选择单个财月/年，单个shop有值**

| TimeFrame | 选择范围 | 分子 | 分母 | 说明 |
|---|---|---|---|---|
| Month | 选择单个财月，且Slicer_Store_Name[Store_ID]仅筛选了单个值，Slicer_Store_Name[Store_ID]作为筛选器，这里是多选，在计算VIC Retention% TAR ACH%仅筛选单个值得情况才有意义 | VIC Retention%（month actual） | DISTINCT `year_vic_retention_percent` | 单月留存率实际 / 年度留存率目标 |
| Month | 选择多个财月 | — | — | **留空**，多个月不计算TAR ACH% |
| Month | 选择多个财月且跨财年 | — | — | **留空** |
| Quarter | 任意选择范围 | — | — | **留空**，Quarter下不计算TAR ACH% |
| Year | 选择单个财年，且Slicer_Store_Name[Store_ID]仅筛选了单个值，Slicer_Store_Name[Store_ID]作为筛选器，这里是多选，在计算VIC Retention% TAR ACH%仅筛选单个值得情况才有意义 | VIC Retention%（year actual） | DISTINCT `year_vic_retention_percent` | 年度留存率实际 / 年度留存率目标 |
| Year | 选择多个财年 | — | — | **留空**，多年不计算TAR ACH% |

---

## 子模块四：T4-5 Upgrade No. TAR ACH% — 目标达成率

| 项目 | 内容 |
|---|---|
| **指标名称** | T4-5 Upgrade No. TAR ACH% |
| **指标名称中文** | T4-5升级为VIC人数目标达成率 |
| **业务定义** | T4-5升级为VIC人数实际值总和与年度目标值之比，仅选择单个财月/单个财年时有值 |
| **计算公式** | 实际值总和 / 年目标值 |
| **实际值** | T4-5 Upgrade No. |
| **目标值取数逻辑** | `data_date = 所选时间范围`，data_date ∈ [TimeFrame_Min, TimeFrame_Max]（全局时间范围），目标值 = SUM(DISTINCT `year_upgrade_customer_cnt`) |
| **目标值底表** | `a03_e2e_customer_fcst_data_m`，日期字段 `data_date` |
| **数据底表（实际值）** | `a03_e2e_customer_data_m` |
| **筛选条件** | `is_upgrade_vic = 1`；`data_date`筛选 |
| **聚合粒度** | `data_date = 所选时间范围`，data_date ∈ [TimeFrame_Min, TimeFrame_Max]（全局时间范围）， |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

**TAR ACH% 计算规则矩阵（T4-5 Upgrade No.）、仅选择单个财月/年有值**

| TimeFrame | 选择范围 | 分子 | 分母 | 说明 |
|---|---|---|---|---|
| Month | 选择单个财月 | T4-5 Upgrade No.（month actual） | SUM(DISTINCT `year_upgrade_customer_cnt`) | 单月实际 / 年度目标值 |
| Month | 选择多个财月 | — | — | **留空**，多个月不计算TAR ACH% |
| Month | 选择多个财月且跨财年 | — | — | **留空** |
| Quarter | 任意选择范围 | — | — | **留空**，Quarter下不计算TAR ACH% |
| Year | 选择单个财年 | T4-5 Upgrade No.（year actual） | SUM(DISTINCT `year_upgrade_customer_cnt`) | 年度实际 / 年度目标值 |
| Year | 选择多个财年 | — | — | **留空**，多年不计算TAR ACH% |

---

## 通用规则汇总

| 规则项 | 说明 |
|---|---|
| **数据底表（实际值）** | `a03_e2e_customer_data_m`、`t05_customer_order_data_d` |
| **数据底表（目标值）** | `a03_e2e_customer_fcst_data_m`，日期字段 `data_date` |
| **目标值聚合方式** | `data_date = 所选时间范围`，`group by platform, shop_info_id` |
| **筛选逻辑** | 模块全局影响：除了特殊说明之外的指标不需要判断is_member和is_employee，其余都默认需要判断is_member和is_employee来确定筛选事实表的值 |
| **货币转换规则** | 数据源默认为 RMB，转化为美元需要除以固定值 7 |
| **派生指标** | LY（去年同期）、LP（上期）、vs LY（同比）、vs LP（环比）、占比、YOY、vs Store 等为派生指标，依据基础指标计算生成 |
| **必须遵守** | 口径文档中定义的所有指标，必须遵守其数据类型和数据格式，如果和解决方案中存在争议的，一切以口径文档为准，必须按照口径文档中的格式进行调整 |
| **DAX 语法规范** | 文本常量必须使用双引号 `" "`，禁止使用单引号；单引号 `' '` 仅用于表名，列名使用方括号 `[ ]`，例如：`[is_vic] = 1` |
| **TAR ACH% 计算通用公式** | TAR ACH% = Actual / Target，结果按 percent_1dp 格式展示 |
| **留空处理** | 当计算规则标注为「留空」时，该指标在对应场景下显示为空值或隐藏 |
| **跨财年判定** | 当所选时间范围跨越两个及以上财年时，视为跨财年场景 |
| **单选/多选判定** | 仅选择单个财月或单个财年时计算TAR ACH%，选择多个时间单位时留空 |
| **VIC 定义** | 在指定日期范围往前 Rolling 12 个财月，net sales >= 20k 的买家 |
| **Tier 分层定义** | T1：≧ 200K；T2：80-200K；T3：20-80K；T4：5-20K；T5：< 5K |
| **Recency 分层定义** | R3：上财年 10-12 月；R4-6：上财年 7-9 月；R7-9：上财年 4-6 月；R10-12：上财年 1-3 月；TTL：全部 |
