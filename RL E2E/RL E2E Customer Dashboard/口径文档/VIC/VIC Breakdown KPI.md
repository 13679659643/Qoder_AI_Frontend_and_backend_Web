# Customer Dashboard 指标口径提示词

> **Dashboard**: Customer Dashboard  
> **Tab**: VIC  
> **数据底表**: `a03_e2e_customer_data_m` / `t05_customer_order_data_d`  
> **模块全局影响说明**:  会员模式与员工筛选：切片器 0 = TTL VIC、1 = Member VIC；两档事实表均筛选 `is_member = 0`，Member VIC 追加 `register_date <= end_period_date`；员工筛选保持现行 `VALUES` + `IN`
> **is_member使用**: `VAR __IsMemberFilter = SELECTEDVALUE(IsMemberFilter[IsMember], 0)`；无唯一选值时默认 TTL VIC。事实表固定 `a03_e2e_customer_data_m[is_member] = 0`，通过 `KEEPFILTERS(__IsMemberFilter = 0 || 'a03_e2e_customer_data_m'[register_date] <= end_period_date)` 按需追加上限，与已有注册日期筛选取交集；TTL 不追加注册日期限制
> **is_employee使用**: `VAR __IsEmployeeFilter = VALUES(Slicer_Is_Employee_Selection[IsEmployee_Code])`，按当前可见员工选值集合筛选 `a03_e2e_customer_data_m[is_employee] IN __IsEmployeeFilter`；沿用现有代码，不改员工筛选行为
> **is_member和is_employee维度表路径**:is_member： D:\gutao\辜涛\Project\Qoder_AI_Frontend_and_backend_Web\RL E2E\RL E2E Customer Dashboard\维度复用\IsMemberFilter；is_employee： D:\gutao\辜涛\Project\Qoder_AI_Frontend_and_backend_Web\RL E2E\RL E2E Customer Dashboard\维度复用\Slicer_Is_Employee_Selection
> **口径修订**: 2026-09-12 — 澄清子模块五 DCom VIC Breakdown 的 Step 1 + Step 2 分步口径（两步时间范围不同不能合并，Step 2 = 切片器所选完整时间范围，见子模块五说明）；全客分母（vs Store / SLS% 分母）同样 Step 1 + Step 2 分步，与 VIC 侧唯一区别是 Step 1 的筛选条件（is_xxx_vic in (0,1) vs =1）；修正全局逻辑 end period 说明示例笔误
> **口径修订**: 2026-09-15 — 依据《口径文档/VIC/VIC vs Store.sql》修订子模块五 ACV / UPT / AUR / Freq. vs Store 四个指标的全客分母口径：由"Step 1 + Step 2 分步（Step 1 筛选 is_xxx_vic in (0,1) 框定全客集合）"改为单步——直接在所选时间范围（TimeFrame 区间）筛选 net_pay_amt > 0 聚合，不框定 user_id 集合、不施加任何 is_xxx_vic 筛选；VIC 侧分子维持 Step 1 + Step 2 分步不变；SLS% 分母维持 2026-09-12 分步口径不变（VIC vs Store.sql 未覆盖 SLS%）

---

> **口径修订**: 2026-09-21 — 仅修改会员筛选，其余计算保持现有有效 DAX 不变；注释和口径以现有代码为准。矩阵 SLS% 的 4/5/6/26/27/28 分支均返回本期单步 `__TTL_SLS`，不使用分步 `__SLS_Store`；本次同步该现状，不改变分母路由。趋势图沿用 Month 行级、Quarter 分子分步及当前柱正金额全客分母。以下现行说明取代前述历史修订中的不一致表述。

## 全局逻辑

| 项目 | 内容 |
|---|---|
| **数据底表** | `a03_e2e_customer_data_m`、`t05_customer_order_data_d` |
| **筛选逻辑** | 本模块所有基础计算及分子、分母均应用全局会员模式（两档事实 `is_member=0`，Member 追加相应期末注册上限）和现有员工筛选；派生指标继承基础值筛选  |
| **聚合粒度** | 数字卡片：所选时间范围 `dt`（多数为 end period），所选时间范围的最后一个财月，只关注Max；表格：按对应维度聚合 |
| **货币转换规则** | 数据源默认为 RMB，转化为美元需要除以固定值 7 |
| **派生指标** | LY（去年同期）、LP（上期）、vs LY（同比）、vs LP（环比）、占比、YOY 等为派生指标，依据基础指标计算生成 |
| **必须遵守** | 口径文档中定义的所有指标，必须遵守其数据类型和数据格式，如果和解决方案中存在争议的，一切以口径文档为准，必须按照口径文档中的格式进行调整 |
| **模块全局影响说明** | 会员筛选（见全局 0/1 规则）及 `is_employee` 筛选,人群细分 ：TTL VIC `is_member = 0` / Member VIC `is_member = 1` / Is Employee `is_employee = 1` or `is_employee = 0`  |
| **is_member使用** | VAR __IsMemberFilter = SELECTEDVALUE(IsMemberFilter[IsMember], 0)，如果没有筛选，则默认TTL VIC。这样过滤事实表a03_e2e_customer_data_m[is_member] = __IsMemberFilter |
| **is_employee使用** | VAR __IsEmployeeFilter = SELECTEDVALUE(Slicer_Is_Employee_Selection[IsEmployee_Code], 1)，如果没有筛选，则默认Yes。这样过滤事实表a03_e2e_customer_data_m[is_employee] = __IsEmployeeFilter |
| **is_member和is_employee维度表路径** | is_member： D:\gutao\辜涛\Project\Qoder_AI_Frontend_and_backend_Web\RL E2E\RL E2E Customer Dashboard\维度复用\IsMemberFilter；is_employee： D:\gutao\辜涛\Project\Qoder_AI_Frontend_and_backend_Web\RL E2E\RL E2E Customer Dashboard\维度复用\Slicer_Is_Employee_Selection |
| **end period说明** | 矩阵从 `Slicer_Time_Frame_Max_VIC_Breakdown` 读取最后财月字段：Act 注册截止为 `Last_Fiscal_Month_Max`，LY 为 `Last_Fiscal_Month_Max_LY`，LP 为 `Last_Fiscal_Month_Max_LP`；不自行计算月末，不用 `TimeFrame_Max` 替代。Step 2 起点仍读 `Slicer_Time_Frame_Min_VIC_Breakdown`，终点读 Max 表。趋势图注册截止读当前柱 `Slicer_Time_Frame_VIC_Breakdown[Last_Fiscal_Month_Max]`，不是全局结束日期。 |
| **注册上限适用范围** | VIC 侧 Act/LY/LP 的 Step 1、Step 2 均使用各自财月末；矩阵全客返回值 `__TTL_*` 始终使用本期所选区间，注册上限也始终为本期财月末（含 SLS% vs LY/LP 所调用的分母）；仍保留的 `__AllUsers` / `__SLS_Store` 按现有 Metric_ID 使用对应期末，但当前 RETURN 不引用它们。趋势图月分子、季度两步、全客分母均使用当前柱财月末；不新增注册日期下限。 |
| **日期前提** | 模型中 `register_date` 及财月末字段须为 Date，日期切片器须提供有效单值。未额外排除 BLANK 注册日期；DAX 的日期比较可能纳入 BLANK，需单独验证，不擅自增加非空筛选。 |

---

## 子模块五：DCom VIC Breakdown

> **分组维度**: 按 VIC 类型（New VIC / Retention VIC）区分，都是基于dt = 所选时间范围end period的情况下，New VIC和Retention VIC的区别仅在于is_new_vic = 1和is_retention_vic = 1的筛选条件。其他的，按 `platform, shop_info_id`分组维度由表字段自动传递，DAX 无需显式处理分组。
>
> **Step 1 + Step 2 分步口径（2026-09-12 澄清）**: SLS / SLS% / ACV / UPT / AUR / Freq. 的计算公式均为两步法，**两步时间范围不同，不能合并区间计算**：
> - **Step 1**（end period 当月框定 VIC 买家）: `dt = 所选时间范围 end period`（`Last_Fiscal_Month_Min ~ Last_Fiscal_Month_Max` 当月单月），筛选 `is_new_vic = 1`（或 `is_retention_vic = 1`），框定 user_id 范围
> - **Step 2**（所选时间范围聚合）: 切片器所选完整时间范围（`TimeFrame_Min ~ TimeFrame_Max`），对 Step 1 框定的 user_id 集合做 `sum(net_pay_amt)` / `sum(net_pay_qty)` / `sum(net_pay_order_cnt)` 聚合；`is_xxx_vic = 1` 仅用于 Step 1 框定，Step 2 不再施加；`platform, shop_info_id` 分组维度由模型自动传递保留（Step 2 不移除分组维度，DAX 无需显式处理）
> - **例外（单步口径）**: ACV / Freq. 分母 `count(distinct user_id)` 口径明确为 "dt = 所选时间范围 end period，筛选 is_xxx_vic = 1"，保持 end period 当月单步聚合（即 Step 1 框定的 user_id 数量）
> - **矩阵 SLS% 全客分母口径（以现有 RETURN 为准）**: `VIC Breakdown Store Base Value` 的 Metric_ID 4/5/6/26/27/28 均返回 `__TTL_SLS`：在本期所选 `TimeFrame` 区间筛选 `net_pay_amt > 0` 单步汇总，不框定用户集合、不施加任何 `is_xxx_vic` 筛选。LY/LP 分子仍取各自期间，但对应占比分母仍为本期值；不将保留但未被 RETURN 引用的 `__SLS_Store` 分步变量视为实际分母。New/Retention 共用同一全客分母。本次不改变该计算，Member 模式下此分母注册截止仍取本期财月末。
> - **vs Store 全客分母口径（单步，2026-09-15 依据《VIC vs Store.sql》修订）**: ACV / UPT / AUR / Freq. vs Store 的全客分母为单步——直接在所选时间范围（TimeFrame 区间）筛选 `net_pay_amt > 0`（含 `is_member`/`is_employee` 筛选）做 sum / count(distinct user_id) 聚合，不经过 Step 1 框定 user_id 集合、不施加任何 `is_xxx_vic` 筛选；New VIC 与 Retention VIC 共用同一全客分母（与 is_xxx_vic 无关）。VIC 侧分子仍为 Step 1 + Step 2 分步（Step 1 在 end period 当月筛选 `is_xxx_vic = 1` 框定集合，Step 2 在所选时间范围对该集合聚合，`is_xxx_vic = 1` 不再施加）——分子分母人群口径不对称（分子 = Step 1 框定集合，分母 = 区间内 `net_pay_amt > 0` 全部买家）
> - **VIC 侧 LY / LP 版本**: Step 1 用 Max 表 `Last_Fiscal_Month_*_LY/LP`；Step 2 起点用 Min 表 `TimeFrame_Min_LY/LP`，终点用 Max 表 `TimeFrame_Max_LY/LP`。两步会员注册截止都用 Max 表对应 `Last_Fiscal_Month_Max_LY/LP`；不改变数据日期区间。
> - **会员筛选覆盖**: 下列全部指标、New/Retention 两类人群及全客分母均遵循全局会员规则。两档事实 `is_member=0`；Member 才追加对应计算期间的注册上限；所有涉及事实表的筛选阶段均应用，既有员工、分组、金额门槛、汇率和比率公式保持不变。

### 1. SLS（Net_New VIC） — 净销售额

| 项目 | 内容 |
|---|---|
| **指标名称** | SLS |
| **指标名称中文** | 净销售额 |
| **业务定义** | New VIC 买家净销售额 |
| **计算公式** | Step 1：在 dt = 所选时间范围 end period，筛选 is_new_vic = 1，框定 user_id 范围；Step 2：再看该 user_id 在所选时间范围对应的 sum(net_pay_amt) |
| **统计字段** | `net_pay_amt`、`is_new_vic` |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | `is_new_vic` = 1；会员筛选（见全局 0/1 规则）及 `is_employee` 筛选 |
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
| **筛选条件** | `is_new_vic = 1`；会员筛选（见全局 0/1 规则）及 `is_employee` 筛选 |
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
| **筛选条件** | `is_new_vic = 1`；会员筛选（见全局 0/1 规则）及 `is_employee` 筛选 |
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
| **计算公式** | 分子：Step 1 在 end period 当月筛选 is_new_vic=1 框定 user_id，Step 2 在所选时间范围汇总该集合的 sum(net_pay_amt)。分母：本期所选时间范围内 net_pay_amt > 0 行单步 sum(net_pay_amt)，对应现有 __TTL_SLS；不框定全客集合、不施加 VIC 标记。分子分母各除相同 FXRate 后相除 |
| **分子** | `net_pay_amt`（`is_new_vic = 1`） |
| **分母** | `net_pay_amt`（本期所选 TimeFrame 区间内 `net_pay_amt > 0` 的全客行，`__TTL_SLS`） |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | 会员筛选（见全局 0/1 规则）及 `is_employee` 筛选 |
| **聚合粒度** | `platform, shop_info_id`分组维度由表字段自动传递，DAX 无需显式处理 |
| **数据类型** | percent_0dp → 百分比整数，不含正号 |
| **数据格式** | `#,##0%` |

### 2.1 SLS% vs LY（Net_New VIC） — 净销售额占比同比

| 项目 | 内容 |
|---|---|
| **指标名称** | SLS% vs LY |
| **指标名称中文** | 净销售额占比同比 |
| **业务定义** | New VIC 买家净销售额占比今年较去年同期的变化（差值） |
| **计算公式** | 今年 - 去年（差值，展示时 ×100 转 pts）；现有代码为 `DIVIDE(Act SLS, 本期全客 SLS) - DIVIDE(LY SLS, 本期全客 SLS)`，两项分母均为本期 `__TTL_SLS`，不切换为 LY 分母 |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | 会员筛选（见全局 0/1 规则）及 `is_employee` 筛选 |
| **聚合粒度** | `platform, shop_info_id`分组维度由表字段自动传递，DAX 无需显式处理 |
| **数据类型** | delta_pts → 增减基点整数： → +120pts / -80pts（基点，含正负号，值×100 转 pts）,乘以100的操作可以放在Cell Display度量中实现，算同比LY：当期值 − 同期值（差值，pts 指标，展示时 ×100 转 pts） |        
| **数据格式** | `+#,##0pts;-#,##0pts;0pts` |

### 2.2 SLS% vs LP（Net_New VIC） — 净销售额占比环比

| 项目 | 内容 |
|---|---|
| **指标名称** | SLS% vs LP |
| **指标名称中文** | 净销售额占比环比 |
| **业务定义** | New VIC 买家净销售额占比当期较上期的变化（差值） |
| **计算公式** | 当期 - 上期（差值，展示时 ×100 转 pts）；现有代码为 `DIVIDE(Act SLS, 本期全客 SLS) - DIVIDE(LP SLS, 本期全客 SLS)`，两项分母均为本期 `__TTL_SLS`，不切换为 LP 分母 |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | 会员筛选（见全局 0/1 规则）及 `is_employee` 筛选 |
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
| **筛选条件** | 会员筛选（见全局 0/1 规则）及 `is_employee` 筛选 |
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
| **筛选条件** | `is_new_vic = 1`；会员筛选（见全局 0/1 规则）及 `is_employee` 筛选 |
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
| **筛选条件** | `is_new_vic = 1`；会员筛选（见全局 0/1 规则）及 `is_employee` 筛选 |
| **聚合粒度** | `platform, shop_info_id`分组维度由表字段自动传递，DAX 无需显式处理 |
| **数据类型** | delta_pct_0dp → 百分比整数，含正号：+15% / -3% |
| **数据格式** | IF(__Value > 0, "+", "") & FORMAT(__Value, "#,##0%") |

### 3.3 ACV vs Store（Net_New VIC） — 客单价对比全客

| 项目 | 内容 |
|---|---|
| **指标名称** | ACV vs Store |
| **指标名称中文** | 客单价对比全客 |
| **业务定义** | New VIC 客单价相对全客客单价的变化率 |
| **计算公式** | New VIC ACV / 全客 ACV - 1。分子 New VIC ACV：Step 1 在 dt = 所选时间范围 end period 当月，筛选 is_new_vic = 1，框定 user_id 集合；Step 2 在所选时间范围（TimeFrame 区间）限定该集合（不再施加 is_new_vic = 1），sum(net_pay_amt) / count(distinct user_id)。分母全客 ACV：单步口径，直接在所选时间范围（TimeFrame 区间）筛选 net_pay_amt > 0，sum(net_pay_amt) / count(distinct user_id)，不框定 user_id 集合、不施加任何 is_xxx_vic 筛选（分子分母人群口径不对称，见子模块五 vs Store 全客分母口径说明） |
| **分子** | New VIC ACV：sum(`net_pay_amt`)（Step 2 所选时间范围 × Step 1 框定集合，`is_new_vic = 1` 仅用于 Step 1）；全客 ACV：sum(`net_pay_amt`)（所选时间范围单步，`net_pay_amt > 0` 行） |
| **分母** | New VIC ACV：count(distinct `user_id`)（Step 2 所选时间范围 × Step 1 框定集合，数值等价于 ACV 指标的 end period 当月单步分母，DAX 可直接复用 ACV 度量值）；全客 ACV：count(distinct `user_id`)（所选时间范围单步，`net_pay_amt > 0` 行） |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | New VIC ACV：Step 1 `is_new_vic = 1` + 会员筛选（见全局 0/1 规则）及 `is_employee` 筛选，Step 2 仅保留会员筛选（见全局 0/1 规则）及 `is_employee` 筛选；全客 ACV：`net_pay_amt > 0` + 会员筛选（见全局 0/1 规则）及 `is_employee` 筛选（不施加 is_new_vic 筛选） |
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
| **筛选条件** | 会员筛选（见全局 0/1 规则）及 `is_employee` 筛选 |
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
| **筛选条件** | `is_new_vic = 1`；会员筛选（见全局 0/1 规则）及 `is_employee` 筛选 |
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
| **筛选条件** | `is_new_vic = 1`；会员筛选（见全局 0/1 规则）及 `is_employee` 筛选 |
| **聚合粒度** | `platform, shop_info_id`分组维度由表字段自动传递，DAX 无需显式处理 |
| **数据类型** | delta_pct_0dp → 百分比整数，含正号：+15% / -3% |
| **数据格式** | IF(__Value > 0, "+", "") & FORMAT(__Value, "#,##0%") |

### 4.3 UPT vs Store（Net_New VIC） — 客单件对比全客

| 项目 | 内容 |
|---|---|
| **指标名称** | UPT vs Store |
| **指标名称中文** | 客单件对比全客 |
| **业务定义** | New VIC 客单件相对全客客单件的变化率 |
| **计算公式** | New VIC UPT / 全客 UPT - 1。分子 New VIC UPT：Step 1 在 dt = 所选时间范围 end period 当月，筛选 is_new_vic = 1，框定 user_id 集合；Step 2 在所选时间范围（TimeFrame 区间）限定该集合（不再施加 is_new_vic = 1），sum(net_pay_qty) / sum(net_pay_order_cnt)。分母全客 UPT：单步口径，直接在所选时间范围（TimeFrame 区间）筛选 net_pay_amt > 0，sum(net_pay_qty) / sum(net_pay_order_cnt)，不框定 user_id 集合、不施加任何 is_xxx_vic 筛选（分子分母人群口径不对称，见子模块五 vs Store 全客分母口径说明） |
| **分子** | New VIC UPT：sum(`net_pay_qty`)（Step 2 所选时间范围 × Step 1 框定集合，`is_new_vic = 1` 仅用于 Step 1）；全客 UPT：sum(`net_pay_qty`)（所选时间范围单步，`net_pay_amt > 0` 行） |
| **分母** | New VIC UPT：sum(`net_pay_order_cnt`)（Step 2 所选时间范围 × Step 1 框定集合）；全客 UPT：sum(`net_pay_order_cnt`)（所选时间范围单步，`net_pay_amt > 0` 行） |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | New VIC UPT：Step 1 `is_new_vic = 1` + 会员筛选（见全局 0/1 规则）及 `is_employee` 筛选，Step 2 仅保留会员筛选（见全局 0/1 规则）及 `is_employee` 筛选；全客 UPT：`net_pay_amt > 0` + 会员筛选（见全局 0/1 规则）及 `is_employee` 筛选（不施加 is_new_vic 筛选） |
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
| **筛选条件** | 会员筛选（见全局 0/1 规则）及 `is_employee` 筛选 |
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
| **筛选条件** | `is_new_vic = 1`；会员筛选（见全局 0/1 规则）及 `is_employee` 筛选 |
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
| **筛选条件** | `is_new_vic = 1`；会员筛选（见全局 0/1 规则）及 `is_employee` 筛选 |
| **聚合粒度** | `platform, shop_info_id`分组维度由表字段自动传递，DAX 无需显式处理 |
| **数据类型** | delta_pct_0dp → 百分比整数，含正号：+15% / -3% |
| **数据格式** | IF(__Value > 0, "+", "") & FORMAT(__Value, "#,##0%") |

### 5.3 AUR vs Store（Net_New VIC） — 件单价对比全客

| 项目 | 内容 |
|---|---|
| **指标名称** | AUR vs Store |
| **指标名称中文** | 件单价对比全客 |
| **业务定义** | New VIC 件单价相对全客件单价的变化率 |
| **计算公式** | New VIC AUR / 全客 AUR - 1。分子 New VIC AUR：Step 1 在 dt = 所选时间范围 end period 当月，筛选 is_new_vic = 1，框定 user_id 集合；Step 2 在所选时间范围（TimeFrame 区间）限定该集合（不再施加 is_new_vic = 1），sum(net_pay_amt) / sum(net_pay_qty)。分母全客 AUR：单步口径，直接在所选时间范围（TimeFrame 区间）筛选 net_pay_amt > 0，sum(net_pay_amt) / sum(net_pay_qty)，不框定 user_id 集合、不施加任何 is_xxx_vic 筛选（分子分母人群口径不对称，见子模块五 vs Store 全客分母口径说明） |
| **分子** | New VIC AUR：sum(`net_pay_amt`)（Step 2 所选时间范围 × Step 1 框定集合，`is_new_vic = 1` 仅用于 Step 1）；全客 AUR：sum(`net_pay_amt`)（所选时间范围单步，`net_pay_amt > 0` 行） |
| **分母** | New VIC AUR：sum(`net_pay_qty`)（Step 2 所选时间范围 × Step 1 框定集合）；全客 AUR：sum(`net_pay_qty`)（所选时间范围单步，`net_pay_amt > 0` 行） |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | New VIC AUR：Step 1 `is_new_vic = 1` + 会员筛选（见全局 0/1 规则）及 `is_employee` 筛选，Step 2 仅保留会员筛选（见全局 0/1 规则）及 `is_employee` 筛选；全客 AUR：`net_pay_amt > 0` + 会员筛选（见全局 0/1 规则）及 `is_employee` 筛选（不施加 is_new_vic 筛选） |
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
| **筛选条件** | 会员筛选（见全局 0/1 规则）及 `is_employee` 筛选 |
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
| **筛选条件** | `is_new_vic = 1`；会员筛选（见全局 0/1 规则）及 `is_employee` 筛选 |
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
| **筛选条件** | `is_new_vic = 1`；会员筛选（见全局 0/1 规则）及 `is_employee` 筛选 |
| **聚合粒度** | `platform, shop_info_id`分组维度由表字段自动传递，DAX 无需显式处理 |
| **数据类型** | delta_pct_0dp → 百分比整数，含正号：+15% / -3% |
| **数据格式** | IF(__Value > 0, "+", "") & FORMAT(__Value, "#,##0%") |

### 6.3 Freq. vs Store（Net_New VIC） — 购买频次对比全客

| 项目 | 内容 |
|---|---|
| **指标名称** | Freq. vs Store |
| **指标名称中文** | 购买频次对比全客 |
| **业务定义** | New VIC 购买频次相对全客购买频次的变化率 |
| **计算公式** | New VIC Freq. / 全客 Freq. - 1。分子 New VIC Freq.：Step 1 在 dt = 所选时间范围 end period 当月，筛选 is_new_vic = 1，框定 user_id 集合；Step 2 在所选时间范围（TimeFrame 区间）限定该集合（不再施加 is_new_vic = 1），sum(net_pay_order_cnt) / count(distinct user_id)。分母全客 Freq.：单步口径，直接在所选时间范围（TimeFrame 区间）筛选 net_pay_amt > 0，sum(net_pay_order_cnt) / count(distinct user_id)，不框定 user_id 集合、不施加任何 is_xxx_vic 筛选（分子分母人群口径不对称，见子模块五 vs Store 全客分母口径说明） |
| **分子** | New VIC Freq.：sum(`net_pay_order_cnt`)（Step 2 所选时间范围 × Step 1 框定集合，`is_new_vic = 1` 仅用于 Step 1）；全客 Freq.：sum(`net_pay_order_cnt`)（所选时间范围单步，`net_pay_amt > 0` 行） |
| **分母** | New VIC Freq.：count(distinct `user_id`)（Step 2 所选时间范围 × Step 1 框定集合，数值等价于 Freq. 指标的 end period 当月单步分母，DAX 可直接复用 Freq. 度量值）；全客 Freq.：count(distinct `user_id`)（所选时间范围单步，`net_pay_amt > 0` 行） |
| **数据底表** | `a03_e2e_customer_data_m` |
| **筛选条件** | New VIC Freq.：Step 1 `is_new_vic = 1` + 会员筛选（见全局 0/1 规则）及 `is_employee` 筛选，Step 2 仅保留会员筛选（见全局 0/1 规则）及 `is_employee` 筛选；全客 Freq.：`net_pay_amt > 0` + 会员筛选（见全局 0/1 规则）及 `is_employee` 筛选（不施加 is_new_vic 筛选） |
| **聚合粒度** | `platform, shop_info_id`分组维度由表字段自动传递，DAX 无需显式处理 |
| **数据类型** | delta_pct_0dp → 百分比整数，含正号：+15% / -3% |
| **数据格式** | IF(__Value > 0, "+", "") & FORMAT(__Value, "#,##0%") |

---

## 趋势图现行口径（VIC_Breakdown_Trend.md）

- 仅 New VIC / Retention VIC 的 SLS、SLS% Act，共四个 Value；不新增 LY/LP。
- Month 分子：当前柱财月内直接筛选 `is_new_vic=1` 或 `is_retention_vic=1` 汇总；不框定 user_id 集合。
- Quarter 分子：Step 1 在当前柱最后财月框定 VIC 用户，Step 2 通过 `TREATAS` 汇总该柱整季消费，不重复施加 VIC 标记。
- SLS% 分母：月/季均在当前柱 `TimeFrame_Min/Max` 内筛选 `net_pay_amt > 0` 单步汇总；不框定全客集合。分子不新增正金额条件。
- 月分子、季度 Step 2、全客分母保留已有全局日期范围；季度 Step 1 保持季末月区间。注册截止统一使用当前柱 `Last_Fiscal_Month_Max`，不受全局结束日期替代。
- 会员规则覆盖月分子、季度两步和全客分母；员工、分组、格式、汇率及返回逻辑均保持现行代码。

## 通用规则汇总

| 规则项 | 说明 |
|---|---|
| **数据底表** | `a03_e2e_customer_data_m`、`t05_customer_order_data_d` |
| **筛选逻辑** | 本模块所有基础计算及分子、分母均应用全局会员模式（两档事实 `is_member=0`，Member 追加相应期末注册上限）和现有员工筛选；派生指标继承基础值筛选  |
| **货币转换规则** | 数据源默认为 RMB，转化为美元需要除以固定值 7 |
| **派生指标** | LY（去年同期）、LP（上期）、vs LY（同比）、vs LP（环比）、占比、YOY、vs Store 等为派生指标，依据基础指标计算生成 |
| **现行分步与单步口径** | 矩阵 VIC 侧维持 Step 1 end period 当月框定用户 + Step 2 所选区间聚合；ACV/Freq. 人数分母为 Step 1 集合数量。矩阵 SLS% 及 vs Store 全客返回值均采用本期单步 `__TTL_*`（`net_pay_amt > 0`，不框定集合），SLS% LY/LP 部分也使用本期全客分母。保留的 `__SLS_Store` 分步变量当前不被 RETURN 引用。趋势 Month 行级、Quarter VIC 分子分步，SLS% 全客分母为当前柱期间单步；会员注册上限按各计算值实际期间取值。 |
| **分组维度** | 根据 `platform, shop_info_id`分组维度由表字段自动传递，DAX 无需显式处理、`timeframe`（Month/Quarter/Year）、`customer_tier`（T1/T2/T3/T4/T5）、`last_fy_last_order_month_type`（R3/R4-6/R7-9/R10-12/TTL）、VIC 类型（New VIC/Retention VIC/Direct VIC/T4-5 Upgrade）分组 |
| **必须遵守** | 口径文档中定义的所有指标，必须遵守其数据类型和数据格式，如果和解决方案中存在争议的，一切以口径文档为准，必须按照口径文档中的格式进行调整 |
| **DAX 语法规范** | 文本常量必须使用双引号 `" "`，禁止使用单引号；单引号 `' '` 仅用于表名，列名使用方括号 `[ ]`，例如：`[is_vic] = 1` |
| **pts 与 bp 区别** | pts 指标：值×100 转 pts（基点，含正负号），数据格式 `+#,##0pts;-#,##0pts;0pts`；bp 指标：值×10000 转 bp，数据格式 `+#,##0bp;-#,##0bp;0bp` |
| **TAR ACH% 占位** | Monthly TAR ACH% / Yearly TAR ACH% / TAR ACH% 逻辑暂未确认，先保持子指标占位，数据格式为 percent_1dp："#,##0.0%"，等逻辑确认后再填充 |
| **VIC 定义** | 在指定日期范围往前 Rolling 12 个财月，net sales >= 20k 的买家 |
| **Tier 分层定义** | T1：≧ 200K；T2：80-200K；T3：20-80K；T4：5-20K；T5：< 5K |
| **Recency 分层定义** | R3：上财年 10-12 月；R4-6：上财年 7-9 月；R7-9：上财年 4-6 月；R10-12：上财年 1-3 月；TTL：全部 |
