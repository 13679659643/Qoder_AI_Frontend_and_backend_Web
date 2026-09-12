# Customer Dashboard 指标口径提示词

> **Dashboard**: Customer Dashboard  
> **Tab**: VIC  
> **数据底表**: `a03_e2e_customer_data_m` / `t05_customer_order_data_d`  
> **模块全局影响说明**:  `is_member`和`is_employee`筛选,人群细分 ：TTL VIC `is_member = 0` / Member VIC `is_member = 1` / Is Employee `is_employee = 1` or `is_employee = 0`
> **is_member使用**: VAR __IsMemberFilter = SELECTEDVALUE(IsMemberFilter[IsMember], 0)，如果没有筛选，则默认TTL VIC。这样过滤事实表a03_e2e_customer_data_m[is_member] = __IsMemberFilter
> **is_employee使用**: VAR __IsEmployeeFilter = SELECTEDVALUE(Slicer_Is_Employee_Selection[IsEmployee_Code], 1)，如果没有筛选，则默认Yes。这样过滤事实表a03_e2e_customer_data_m[is_employee] = __IsEmployeeFilter
> **is_member和is_employee维度表路径**:is_member： D:\gutao\辜涛\Project\Qoder_AI_Frontend_and_backend_Web\RL E2E\RL E2E Customer Dashboard\维度复用\IsMemberFilter；is_employee： D:\gutao\辜涛\Project\Qoder_AI_Frontend_and_backend_Web\RL E2E\RL E2E Customer Dashboard\维度复用\Slicer_Is_Employee_Selection
> **口径修订**: 2026-09-12 — 澄清 Step 1 + Step 2 分步口径（两步时间范围不同不能合并，Step 2 = 切片器所选完整时间范围，见子模块四说明）；修正指标 6 聚合粒度（继承指标 5 分步口径）；补充指标 3 分母移除 customer_tier 说明（ALLSELECTED，与指标 7 分母对齐）；修正全局逻辑 end period 说明示例笔误

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
| **end period说明** | 所选时间范围的最后一个财月,Slicer_Time_Frame_Max维度表已经给出了具体的Last_Fiscal_Month、Last_Fiscal_Month_Min等字段，只关注Slicer_Time_Frame_Max值,比如 2023-09 ~ 2026-09，只关注 2026-09；2026 Q2，只关注2026-06；财年2026，对应最后一个财月只关注2026-12； |

---

## 子模块四：VIC Segment

> **分组维度**: 按 `customer_tier`（T1/T2/T3/T4/T5）分组，固定值：T1：≧ 200K；T2：80-200K；T3：20-80K；T4：5-20K；T5：< 5K;已有DIM_Row_VIC_Tier行维度字段，参考文件：D:\gutao\辜涛\Project\Qoder_AI_Frontend_and_backend_Web\RL E2E\RL E2E Customer Dashboard\VIC\4 VIC Segment\DIM_Row_VIC_Tier.md，DIM_Row_VIC_Tier和a03_e2e_customer_data_m表，模型关系为1:N，所以分组维度由模型自动传递，DAX 无需显式处理分组；
> **行维度列职责**: 表格行维度实际承载列为 DIM_Row_VIC_Tier[Row Label]（图片展示行标签，如 "T1 (≧ 200K)"）；Tier ID 为与事实表 customer_tier 的 1:N 关系关联列；
> **Step 1 + Step 2 分步口径（2026-09-12 澄清）**: 指标 5（SLS）、指标 7（% of Total 净销售额占比分子）、指标 9（ACV 分子）、指标 10（AUR 分子/分母）、指标 11（UPT 分子/分母）、指标 12（Freq. 分子）均采用 Step 1 + Step 2 两步口径——**Step 1**：在 dt = 所选时间范围 end period（end period 当月单月），筛选 customer_tier = T1/T2/T3/T4/T5，框定 user_id 范围；**Step 2**：再看该 user_id 在所选时间范围（切片器所选完整时间范围）对应的 sum(net_pay_amt) / sum(net_pay_qty) / sum(net_pay_order_cnt)。两步时间范围不一致（Step 1 = end period 当月，Step 2 = 所选时间范围完整区间），**不能直接合并区间计算**，必须分步实现；Step 1 / Step 2 均不移除 customer_tier / platform / shop_info_id 分组维度（由模型 1:N 关系自动传递保留，与行上下文一致，DAX 无需显式处理）；仅占比类分母（指标 3 分母、指标 7 分母）需要移除 customer_tier 字段对表的影响但同时需要保留外部切片器的影响（我理解使用ALLSELECTED）；LY 派生版本：Step 1 用 LY end period 当月，Step 2 用 LY 所选时间范围完整区间；

### 0. Tier — 买家分层

| 项目 | 内容 |
|---|---|
| **指标名称** | Tier |
| **指标名称中文** | 买家分层 |
| **业务定义** | 买家分层，固定值：T1：≧ 200K；T2：80-200K；T3：20-80K；T4：5-20K；T5：< 5K |
| **计算公式** | a03_e2e_customer_data_m[customer_tier],字段值包括：T1/T2/T3/T4/T5 |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | 分组维度由表字段自动传递，DAX 无需显式处理 分组 |

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
| **筛选条件** | `is_member`和`is_employee`筛选 |
| **聚合粒度** | `dt = 所选时间范围 end period`，`platform, shop_info_id`分组维度由表字段自动传递，DAX 无需显式处理 |
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
| **筛选条件** | `is_member`和`is_employee`筛选 |
| **聚合粒度** | `dt = 所选时间范围 end period`，`platform, shop_info_id`分组维度由表字段自动传递，DAX 无需显式处理 |
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
| **分子** | `user_id` |
| **分母** | `user_id`（`net_pay_amt > 0`，全部 customer_tier，需要移除a03_e2e_customer_data_m中customer_tier字段对表的影响，但同时需要保留外部切片器的影响，我理解使用ALLSELECTED） |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `is_member`和`is_employee`筛选 |
| **聚合粒度** | `dt = 所选时间范围 end period`，`platform, shop_info_id`分组维度由表字段自动传递，DAX 无需显式处理 |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

---

### 4. Customer% vs. LY — 买家人数占比YOY

| 项目 | 内容 |
|---|---|
| **指标名称** | Customer% vs. LY |
| **指标名称中文** | 买家人数占比YOY |
| **业务定义** | 该分层下买家人数占比和去年的对比 |
| **计算公式** | 今年买家人数占比 - 去年买家人数占比 |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `is_member`和`is_employee`筛选 |
| **聚合粒度** | `dt = 所选时间范围 end period`，`platform, shop_info_id`分组维度由表字段自动传递，DAX 无需显式处理 |
| **数据类型** | integer_pts → 整数，千分位整数pts, 不含正号，例如：120pts / -80pts,直接使用FORMAT(__Value * 100, "#,##0pts;-#,##0pts;0pts")，算同比LY：当期值 − 同期值（差值，pts 指标，展示时 ×100 转 pts） |        
| **数据格式** | `#,##0pts;-#,##0pts;0pts` |

---

### 5. SLS (in K) — 净销售额

| 项目 | 内容 |
|---|---|
| **指标名称** | SLS (in K) |
| **指标名称中文** | 净销售额 |
| **业务定义** | 该分层下买家净销售额 |
| **计算公式** | Step 1：在 dt = 所选时间范围 end period（end period 当月单月），筛选 customer_tier = T1/T2/T3/T4/T5，框定 user_id 范围；Step 2：再看该 user_id 在所选时间范围（切片器所选完整时间范围）对应的 sum(net_pay_amt)。两步时间范围不同，不能合并区间计算，必须分步 |
| **统计字段** | `net_pay_amt` |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | 报表上看到的数值 = 实际金额 ÷ 1,000，所以得到的值需要÷1000；`is_member`和`is_employee`筛选 |
| **聚合粒度** | Step 1：end period 当月单月；Step 2：所选时间范围完整区间；`platform, shop_info_id`分组维度由表字段自动传递，DAX 无需显式处理（Step 1 / Step 2 均保留分组维度自动传递） |
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
| **筛选条件** |  `is_member`和`is_employee`筛选 |
| **聚合粒度** | 同指标 5 的 Step 1 + Step 2 分步口径（今年值与去年值均先分步计算再求 YOY；LY 版本：Step 1 = LY end period 当月，Step 2 = LY 所选时间范围完整区间），`platform, shop_info_id`分组维度由表字段自动传递，DAX 无需显式处理 |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

---

### 7. % of Total — 净销售额占比

| 项目 | 内容 |
|---|---|
| **指标名称** | % of Total |
| **指标名称中文** | 净销售额占比 |
| **业务定义** | 该分层下买家净销售额/总买家净销售额 |
| **计算公式** | 分子：Step 1 在 dt = 所选时间范围 end period（end period 当月单月），筛选 customer_tier = T1/T2/T3/T4/T5，框定 user_id 范围；Step 2 再看该 user_id 在所选时间范围（切片器所选完整时间范围）对应的 sum(net_pay_amt)，两步不能合并区间计算。分母：所选时间范围（与分子 Step 2 同一完整区间）对应的 sum(net_pay_amt)，全量口径不框定 user_id |
| **分子** | `net_pay_amt` |
| **分母** | `net_pay_amt`（全部 customer_tier，时间范围与分子 Step 2 对齐为所选时间范围完整区间，需要移除a03_e2e_customer_data_m中customer_tier字段对表的影响，但同时需要保留外部切片器的影响，我理解使用ALLSELECTED） |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `is_member`和`is_employee`筛选 |
| **聚合粒度** | `platform, shop_info_id`分组维度由表字段自动传递，DAX 无需显式处理 |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%` |

---

### 8. SLS % vs. LY — 净销售额占比YOY

| 项目 | 内容 |
|---|---|
| **指标名称** | SLS % vs. LY |
| **指标名称中文** | 净销售额占比YOY |
| **业务定义** | 该分层下买家净销售额占比和去年的对比（差值） |
| **计算公式** | 今年 - 去年（差值，展示时 ×100 转 pts） |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `is_member`和`is_employee`筛选 |
| **聚合粒度** | 同指标 7 口径（分子 Step 1 + Step 2 分步，分母所选时间范围全量；今年 SLS% 与去年 SLS% 均按指标 7 计算，LY 版本：Step 1 = LY end period 当月，Step 2 = LY 所选时间范围完整区间），`platform, shop_info_id`分组维度由表字段自动传递，DAX 无需显式处理 |
| **数据类型** | integer_pts → 整数，千分位整数pts, 不含正号，例如：120pts / -80pts,直接使用FORMAT(__Value * 100, "#,##0pts;-#,##0pts;0pts")，算同比LY：当期值 − 同期值（差值，pts 指标，展示时 ×100 转 pts） |        
| **数据格式** | `#,##0pts;-#,##0pts;0pts` |

---

### 9. ACV — 客单价

| 项目 | 内容 |
|---|---|
| **指标名称** | ACV |
| **指标名称中文** | 客单价 |
| **业务定义** | 该分层下净销售金额/净购买买家人数 |
| **计算公式** | 分子：SLS（Step 1 在 dt = 所选时间范围 end period，筛选 customer_tier = T1/T2/T3/T4/T5，框定 user_id 范围；Step 2 再看该 user_id 在所选时间范围对应的 sum(net_pay_amt)）；分母：dt = 所选时间范围 end period，筛选 customer_tier = T1/T2/T3/T4/T5，count(distinct user_id) |
| **分子** | `net_pay_amt`、 sum(net_pay_amt)|
| **分母** | `user_id` 、count(distinct user_id)|
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `is_member`和`is_employee`筛选 |
| **聚合粒度** | `platform, shop_info_id`分组维度由表字段自动传递，DAX 无需显式处理 |
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
| **分子** | `net_pay_amt`、sum(net_pay_amt) |
| **分母** | `net_pay_qty`、sum(net_pay_qty) |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `is_member`和`is_employee`筛选 |
| **聚合粒度** | `platform, shop_info_id`分组维度由表字段自动传递，DAX 无需显式处理 |
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
| **分子** | `net_pay_qty`、sum(net_pay_qty) |
| **分母** | `net_pay_order_cnt`、sum(net_pay_order_cnt) |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `is_member`和`is_employee`筛选 |
| **聚合粒度** | `platform, shop_info_id`分组维度由表字段自动传递，DAX 无需显式处理 |
| **数据类型** | integer → 整数，千分位整数 |
| **数据格式** | `#,##0` |

---

### 12. Freq. — 购买频次

| 项目 | 内容 |
|---|---|
| **指标名称** | Freq. |
| **指标名称中文** | 购买频次 |
| **业务定义** | 该分层下净订单数/净购买买家人数 |
| **计算公式** | 分子：Step 1 在 dt = 所选时间范围 end period，筛选 customer_tier = T1/T2/T3/T4/T5，框定 user_id 范围；Step 2 再看该 user_id 在所选时间范围对应的 sum(net_pay_order_cnt)。分母：dt = 所选时间范围 end period，筛选 customer_tier = T1/T2/T3/T4/T5，count(distinct user_id) |
| **分子** | `net_pay_order_cnt`、sum(net_pay_order_cnt) |
| **分母** | `user_id`、count(distinct user_id) |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `is_member`和`is_employee`筛选 |
| **聚合粒度** | `platform, shop_info_id`分组维度由表字段自动传递，DAX 无需显式处理 |
| **数据类型** | decimal_1dp → 小数，保留一位小数，千分位 |
| **数据格式** | `#,##0.0` |

---


## 通用规则汇总

| 规则项 | 说明 |
|---|---|
| **数据底表** | `a03_e2e_customer_data_m`、`t05_customer_order_data_d` |
| **筛选逻辑** | 模块全局影响：除了特殊说明之外的指标不需要判断is_member和is_employee，其余都默认需要判断is_member和is_employee来确定筛选事实表的值  |
| **货币转换规则** | 数据源默认为 RMB，转化为美元需要除以固定值 7 |
| **派生指标** | LY（去年同期）、LP（上期）、vs LY（同比）、vs LP（环比）、占比、YOY、vs Store 等为派生指标，依据基础指标计算生成 |
| **分组维度** | 根据 `platform, shop_info_id`分组维度由表字段自动传递，DAX 无需显式处理、`timeframe`（Month/Quarter/Year）、`customer_tier`（T1/T2/T3/T4/T5）、`last_fy_last_order_month_type`（R3/R4-6/R7-9/R10-12/TTL）、VIC 类型（New VIC/Retention VIC/Direct VIC/T4-5 Upgrade）分组 |
| **Step1+Step2 分步口径** | 指标 5/7/9/10/11/12：Step 1 在 end period 当月框定分层 user_id；Step 2 该 user_id 在所选时间范围完整区间聚合；两步时间范围不同，不能合并区间计算；Step 1 / Step 2 均不移除分组维度（模型 1:N 关系自动传递）；LY 版本 Step 1 / Step 2 分别用 LY end period 当月 / LY 所选时间范围；仅占比类分母（指标 3 / 指标 7）移除 customer_tier 影响但保留外部切片器（ALLSELECTED） |
| **必须遵守** | 口径文档中定义的所有指标，必须遵守其数据类型和数据格式，如果和解决方案中存在争议的，一切以口径文档为准，必须按照口径文档中的格式进行调整 |
| **DAX 语法规范** | 文本常量必须使用双引号 `" "`，禁止使用单引号；单引号 `' '` 仅用于表名，列名使用方括号 `[ ]`，例如：`[is_vic] = 1` |
| **pts 与 bp 区别** | pts 指标：值×100 转 pts（基点，含正负号），数据格式 `+#,##0pts;-#,##0pts;0pts`；bp 指标：值×10000 转 bp，数据格式 `+#,##0bp;-#,##0bp;0bp` |
| **TAR ACH% 占位** | Monthly TAR ACH% / Yearly TAR ACH% / TAR ACH% 逻辑暂未确认，先保持子指标占位，数据格式为 percent_1dp："#,##0.0%"，等逻辑确认后再填充 |
| **VIC 定义** | 在指定日期范围往前 Rolling 12 个财月，net sales >= 20k 的买家 |
| **Tier 分层定义** | T1：≧ 200K；T2：80-200K；T3：20-80K；T4：5-20K；T5：< 5K |
| **Recency 分层定义** | R3：上财年 10-12 月；R4-6：上财年 7-9 月；R7-9：上财年 4-6 月；R10-12：上财年 1-3 月；TTL：全部 |
