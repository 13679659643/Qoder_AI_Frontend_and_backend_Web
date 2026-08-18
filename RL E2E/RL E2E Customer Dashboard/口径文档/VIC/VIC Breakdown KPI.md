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

---

## 子模块五：DCom VIC Breakdown

> **分组维度**: 按 VIC 类型（New VIC / Retention VIC）区分，都是基于dt = 所选时间范围end period的情况下，New VIC和Retention VIC的区别仅在于is_new_vic = 1和is_retention_vic = 1的筛选条件。其他的，按 `platform, shop_info_id`分组维度由表字段自动传递，DAX 无需显式处理分组。

### 1. SLS（Net_New VIC） — 净销售额

| 项目 | 内容 |
|---|---|
| **指标名称** | SLS |
| **指标名称中文** | 净销售额 |
| **业务定义** | New VIC 买家净销售额 |
| **计算公式** | Step 1：在 dt = 所选时间范围 end period，筛选 is_new_vic = 1，框定 user_id 范围；Step 2：再看该 user_id 在所选时间范围对应的 sum(net_pay_amt) |
| **统计字段** | `net_pay_amt`、`is_new_vic` |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `is_new_vic` = 1；`is_member`和`is_employee`筛选 |
| **聚合粒度** | `platform, shop_info_id`分组维度由表字段自动传递，DAX 无需显式处理 |
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
| **筛选条件** | `is_new_vic = 1`；`is_member`和`is_employee`筛选 |
| **聚合粒度** | `platform, shop_info_id`分组维度由表字段自动传递，DAX 无需显式处理 |
| **数据类型** | delta_pct_0dp → 百分比整数，含正号：+15% / -3% |
| **数据格式** | IF(__Value > 0, "+", "") & FORMAT(__Value, "#,##0%") |

### 1.2 SLS vs LP（Net_New VIC） — 净销售额环比

| 项目 | 内容 |
|---|---|
| **指标名称** | SLS vs LP |
| **指标名称中文** | 净销售额环比 |
| **业务定义** | New VIC 买家净销售额当期较上期的变化率 |
| **计算公式** | 当期 / 上期 - 1 |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `is_new_vic = 1`；`is_member`和`is_employee`筛选 |
| **聚合粒度** | `platform, shop_info_id`分组维度由表字段自动传递，DAX 无需显式处理 |
| **数据类型** | delta_pct_0dp → 百分比整数，含正号：+15% / -3% |
| **数据格式** | IF(__Value > 0, "+", "") & FORMAT(__Value, "#,##0%") |

---

### 2. SLS%（Net_New VIC） — 净销售额占比

| 项目 | 内容 |
|---|---|
| **指标名称** | SLS% |
| **指标名称中文** | 净销售额占比 |
| **业务定义** | New VIC 买家净销售额/总买家净销售额 |
| **计算公式** | 分子：Step 1 在 dt = 所选时间范围 end period，筛选 is_new_vic = 1，框定 user_id 范围；Step 2 再看该 user_id 在所选时间范围对应的 sum(net_pay_amt)。分母：所选时间范围对应的 sum(net_pay_amt) |
| **分子** | `net_pay_amt`（`is_new_vic = 1`） |
| **分母** | `net_pay_amt`（`is_new_vic in (0, 1)`） |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `is_member`和`is_employee`筛选 |
| **聚合粒度** | `platform, shop_info_id`分组维度由表字段自动传递，DAX 无需显式处理 |
| **数据类型** | percent_0dp → 百分比整数，不含正号 |
| **数据格式** | `#,##0%` |

### 2.1 SLS% vs LY（Net_New VIC） — 净销售额占比同比

| 项目 | 内容 |
|---|---|
| **指标名称** | SLS% vs LY |
| **指标名称中文** | 净销售额占比同比 |
| **业务定义** | New VIC 买家净销售额占比今年较去年同期的变化（差值） |
| **计算公式** | 今年 - 去年（差值，展示时 ×100 转 pts） |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `is_member`和`is_employee`筛选 |
| **聚合粒度** | `platform, shop_info_id`分组维度由表字段自动传递，DAX 无需显式处理 |
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
| **筛选条件** | `is_member`和`is_employee`筛选 |
| **聚合粒度** | `platform, shop_info_id`分组维度由表字段自动传递，DAX 无需显式处理 |
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
| **筛选条件** | `is_member`和`is_employee`筛选 |
| **聚合粒度** | `platform, shop_info_id`分组维度由表字段自动传递，DAX 无需显式处理 |
| **数据类型** | currency_decimal_1dp  → 货币符号 + 千分位一位小数：¥1,000.0 / $1,000.0 |
| **数据格式** | `#,##0.0`（在 DAX 中用 `__CurrencySymbol & FORMAT(__Value, "#,##0.0")` 拼接币种符号） |

### 3.1 ACV vs LY（Net_New VIC） — 客单价同比

| 项目 | 内容 |
|---|---|
| **指标名称** | ACV vs LY |
| **指标名称中文** | 客单价同比 |
| **业务定义** | New VIC 客单价今年较去年同期的变化率 |
| **计算公式** | 今年 / 去年 - 1 |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `is_new_vic = 1`；`is_member`和`is_employee`筛选 |
| **聚合粒度** | `platform, shop_info_id`分组维度由表字段自动传递，DAX 无需显式处理 |
| **数据类型** | delta_pct_0dp → 百分比整数，含正号：+15% / -3% |
| **数据格式** | IF(__Value > 0, "+", "") & FORMAT(__Value, "#,##0%") |

### 3.2 ACV vs LP（Net_New VIC） — 客单价环比

| 项目 | 内容 |
|---|---|
| **指标名称** | ACV vs LP |
| **指标名称中文** | 客单价环比 |
| **业务定义** | New VIC 客单价当期较上期的变化率 |
| **计算公式** | 当期 / 上期 - 1 |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `is_new_vic = 1`；`is_member`和`is_employee`筛选 |
| **聚合粒度** | `platform, shop_info_id`分组维度由表字段自动传递，DAX 无需显式处理 |
| **数据类型** | delta_pct_0dp → 百分比整数，含正号：+15% / -3% |
| **数据格式** | IF(__Value > 0, "+", "") & FORMAT(__Value, "#,##0%") |

### 3.3 ACV vs Store（Net_New VIC） — 客单价对比全客

| 项目 | 内容 |
|---|---|
| **指标名称** | ACV vs Store |
| **指标名称中文** | 客单价对比全客 |
| **业务定义** | New VIC 客单价相对全客客单价的变化率 |
| **计算公式** | New VIC ACV / 全客 ACV - 1 |
| **分子** | New VIC ACV：`net_pay_amt`（`is_new_vic = 1`）；全客 ACV：`net_pay_amt`（`is_new_vic in (0, 1)`） |
| **分母** | New VIC ACV：`user_id`（`is_new_vic = 1`）；全客 ACV：`user_id`（`is_new_vic in (0, 1)`） |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | New VIC ACV：`is_new_vic = 1`、`is_member`和`is_employee`筛选；全客 ACV：`is_new_vic in (0, 1)`、`is_member`和`is_employee`筛选 |
| **聚合粒度** | `platform, shop_info_id`分组维度由表字段自动传递，DAX 无需显式处理 |
| **数据类型** | delta_pct_0dp → 百分比整数，含正号：+15% / -3% |
| **数据格式** | IF(__Value > 0, "+", "") & FORMAT(__Value, "#,##0%") |

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
| **筛选条件** | `is_member`和`is_employee`筛选 |
| **聚合粒度** | `platform, shop_info_id`分组维度由表字段自动传递，DAX 无需显式处理 |
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
| **筛选条件** | `is_new_vic = 1`；`is_member`和`is_employee`筛选 |
| **聚合粒度** | `platform, shop_info_id`分组维度由表字段自动传递，DAX 无需显式处理 |
| **数据类型** | delta_pct_0dp → 百分比整数，含正号：+15% / -3% |
| **数据格式** | IF(__Value > 0, "+", "") & FORMAT(__Value, "#,##0%") |

### 4.2 UPT vs LP（Net_New VIC） — 客单件环比

| 项目 | 内容 |
|---|---|
| **指标名称** | UPT vs LP |
| **指标名称中文** | 客单件环比 |
| **业务定义** | New VIC 客单件当期较上期的变化率 |
| **计算公式** | 当期 / 上期 - 1 |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `is_new_vic = 1`；`is_member`和`is_employee`筛选 |
| **聚合粒度** | `platform, shop_info_id`分组维度由表字段自动传递，DAX 无需显式处理 |
| **数据类型** | delta_pct_0dp → 百分比整数，含正号：+15% / -3% |
| **数据格式** | IF(__Value > 0, "+", "") & FORMAT(__Value, "#,##0%") |

### 4.3 UPT vs Store（Net_New VIC） — 客单件对比全客

| 项目 | 内容 |
|---|---|
| **指标名称** | UPT vs Store |
| **指标名称中文** | 客单件对比全客 |
| **业务定义** | New VIC 客单件相对全客客单件的变化率 |
| **计算公式** | New VIC UPT / 全客 UPT - 1 |
| **分子** | New VIC UPT：`net_pay_qty`（`is_new_vic = 1`）；全客 UPT：`net_pay_qty`（`is_new_vic in (0, 1)`） |
| **分母** | New VIC UPT：`net_pay_order_cnt`（`is_new_vic = 1`）；全客 UPT：`net_pay_order_cnt`（`is_new_vic in (0, 1)`） |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | New VIC UPT：`is_new_vic = 1`、`is_member`和`is_employee`筛选；全客 UPT：`is_new_vic in (0, 1)`、`is_member`和`is_employee`筛选； |
| **聚合粒度** | `platform, shop_info_id`分组维度由表字段自动传递，DAX 无需显式处理 |
| **数据类型** | delta_pct_0dp → 百分比整数，含正号：+15% / -3% |
| **数据格式** | IF(__Value > 0, "+", "") & FORMAT(__Value, "#,##0%") |

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
| **筛选条件** | `is_member`和`is_employee`筛选 |
| **聚合粒度** | `platform, shop_info_id`分组维度由表字段自动传递，DAX 无需显式处理 |
| **数据类型** | currency_decimal_1dp  → 货币符号 + 千分位一位小数：¥1,000.0 / $1,000.0 |
| **数据格式** | `#,##0.0`（在 DAX 中用 `__CurrencySymbol & FORMAT(__Value, "#,##0.0")` 拼接币种符号） |

### 5.1 AUR vs LY（Net_New VIC） — 件单价同比

| 项目 | 内容 |
|---|---|
| **指标名称** | AUR vs LY |
| **指标名称中文** | 件单价同比 |
| **业务定义** | New VIC 件单价今年较去年同期的变化率 |
| **计算公式** | 今年 / 去年 - 1 |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `is_new_vic = 1`；`is_member`和`is_employee`筛选 |
| **聚合粒度** | `platform, shop_info_id`分组维度由表字段自动传递，DAX 无需显式处理 |
| **数据类型** | delta_pct_0dp → 百分比整数，含正号：+15% / -3% |
| **数据格式** | IF(__Value > 0, "+", "") & FORMAT(__Value, "#,##0%") |

### 5.2 AUR vs LP（Net_New VIC） — 件单价环比

| 项目 | 内容 |
|---|---|
| **指标名称** | AUR vs LP |
| **指标名称中文** | 件单价环比 |
| **业务定义** | New VIC 件单价当期较上期的变化率 |
| **计算公式** | 当期 / 上期 - 1 |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `is_new_vic = 1`；`is_member`和`is_employee`筛选 |
| **聚合粒度** | `platform, shop_info_id`分组维度由表字段自动传递，DAX 无需显式处理 |
| **数据类型** | delta_pct_0dp → 百分比整数，含正号：+15% / -3% |
| **数据格式** | IF(__Value > 0, "+", "") & FORMAT(__Value, "#,##0%") |

### 5.3 AUR vs Store（Net_New VIC） — 件单价对比全客

| 项目 | 内容 |
|---|---|
| **指标名称** | AUR vs Store |
| **指标名称中文** | 件单价对比全客 |
| **业务定义** | New VIC 件单价相对全客件单价的变化率 |
| **计算公式** | New VIC AUR / 全客 AUR - 1 |
| **分子** | New VIC AUR：`net_pay_amt`（`is_new_vic = 1`）；全客 AUR：`net_pay_amt`（`is_new_vic in (0, 1)`） |
| **分母** | New VIC AUR：`net_pay_qty`（`is_new_vic = 1`）；全客 AUR：`net_pay_qty`（`is_new_vic in (0, 1)`） |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `is_new_vic = 1`；`is_member`和`is_employee`筛选 |
| **聚合粒度** | `platform, shop_info_id`分组维度由表字段自动传递，DAX 无需显式处理 |
| **数据类型** | delta_pct_0dp → 百分比整数，含正号：+15% / -3% |
| **数据格式** | IF(__Value > 0, "+", "") & FORMAT(__Value, "#,##0%") |

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
| **筛选条件** | `is_member`和`is_employee`筛选 |
| **聚合粒度** | `platform, shop_info_id`分组维度由表字段自动传递，DAX 无需显式处理 |
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
| **筛选条件** | `is_new_vic = 1`；`is_member`和`is_employee`筛选 |
| **聚合粒度** | `platform, shop_info_id`分组维度由表字段自动传递，DAX 无需显式处理 |
| **数据类型** | delta_pct_0dp → 百分比整数，含正号：+15% / -3% |
| **数据格式** | IF(__Value > 0, "+", "") & FORMAT(__Value, "#,##0%") |

### 6.2 Freq. vs LP（Net_New VIC） — 购买频次环比

| 项目 | 内容 |
|---|---|
| **指标名称** | Freq. vs LP |
| **指标名称中文** | 购买频次环比 |
| **业务定义** | New VIC 购买频次当期较上期的变化率 |
| **计算公式** | 当期 / 上期 - 1 |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `is_new_vic = 1`；`is_member`和`is_employee`筛选 |
| **聚合粒度** | `platform, shop_info_id`分组维度由表字段自动传递，DAX 无需显式处理 |
| **数据类型** | delta_pct_0dp → 百分比整数，含正号：+15% / -3% |
| **数据格式** | IF(__Value > 0, "+", "") & FORMAT(__Value, "#,##0%") |

### 6.3 Freq. vs Store（Net_New VIC） — 购买频次对比全客

| 项目 | 内容 |
|---|---|
| **指标名称** | Freq. vs Store |
| **指标名称中文** | 购买频次对比全客 |
| **业务定义** | New VIC 购买频次相对全客购买频次的变化率 |
| **计算公式** | New VIC Freq. / 全客 Freq. - 1 |
| **分子** | New VIC Freq.：`net_pay_order_cnt`（`is_new_vic = 1`）；全客 Freq.：`net_pay_order_cnt`（`is_new_vic in (0, 1)`） |
| **分母** | New VIC Freq.：`user_id`（`is_new_vic = 1`）；全客 Freq.：`user_id`（`is_new_vic in (0, 1)`） |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | New VIC Freq.：`is_new_vic = 1`；`is_member`和`is_employee`筛选；全客 Freq.：`is_new_vic in (0, 1)`；`is_member`和`is_employee`筛选 |
| **聚合粒度** | `platform, shop_info_id`分组维度由表字段自动传递，DAX 无需显式处理 |
| **数据类型** | delta_pct_0dp → 百分比整数，含正号：+15% / -3% |
| **数据格式** | IF(__Value > 0, "+", "") & FORMAT(__Value, "#,##0%") |

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
