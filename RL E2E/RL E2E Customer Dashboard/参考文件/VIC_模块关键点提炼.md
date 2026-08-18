# VIC 模块关键点提炼（AI 关键词输入参考）

> 来源：VIC 目录下全部 12 个方案文件
> 用途：作为后续 AI 对话的关键词输入，方便快速理解 VIC 模块核心技术点
> 编写原则：仅提炼关键、有价值、总结性的点，难理解处附带必要 DAX 参考

---

## 一、整体架构范式

### 1. 断开维度 + SWITCH 动态路由范式

来源：VIC_KPIs_Table / VIC_Breakdown_ms

- 列维度表（如 `Dim_ColMetric_VIC_KPIs` / `Dim_ColMetric_New_Retention_VIC`）与事实表**无模型关系**
- 通过 `SELECTEDVALUE(Metric_ID)` 读取用户点击的列，再用 `SWITCH(Metric_ID, ...)` 分发到对应计算分支
- 派生指标（vs LY / vs LP / vs Store）通过 `CALCULATE + REMOVEFILTERS(断开维度) + Metric_ID = x` 覆盖上下文获取分子分母
- 一个 `[Cell Value]` 度量值统管所有指标，配合 `[Cell Display]` / `[Cell Font Color]` 单字段分发格式与颜色

```dax
// 范式参考
CALCULATE(
    [VIC Breakdown Act Base Value],
    REMOVEFILTERS('Dim_ColMetric_New_Retention_VIC'),
    'Dim_ColMetric_New_Retention_VIC'[Metric_ID] = __QtyActMetricID_LY
)
```

### 2. 独立 Value/Display 度量值范式（无 SWITCH 路由）

来源：VIC_KPIs_Pie_Chart / VIC_Trend / LY_Last_Purchase_Time_Table / VIC_Segment_Table / Class_x_Label_Drilldown_list / VIC_Breakdown_Trend

- 每个指标单独输出 Value（值）+ Display（格式化显示）两个度量值
- 适用于：饼图、柱形图、表格（非 Matrix）
- 优点：逻辑独立、便于维护；缺点：度量值数量多（N 对/指标）

### 3. 度量值分层架构

来源：VIC_KPIs_Table / VIC_Breakdown_ms

```
[Cell Value]（对外值）
  └→ [Base Value]（总路由）
       ├→ [Act Base Value]（本期值）
       ├→ [LY Base Value]（去年同期值）
       ├→ [LP Base Value]（上期值）
       ├→ [Store Base Value]（全客值）
       └→ 派生：vs LY / vs LP / vs Store / SLS%
```

---

## 二、时间筛选核心规则

### 1. vs LY / vs LP 时间偏移规则（财历映射）

来源：VIC_Breakdown_ms / VIC_KPIs_Table / VIC_Segment_Table

- 本期：`Last_Fiscal_Month_Min` ~ `Last_Fiscal_Month_Max`
- LY：`Last_Fiscal_Month_Min_LY` ~ `Last_Fiscal_Month_Max_LY`
- LP：`Last_Fiscal_Month_Min_LP` ~ `Last_Fiscal_Month_Max_LP`
- **无需 EDATE -12 或 Key 偏移计算**（字段已在 `Slicer_Time_Frame_Max` 系列表中预算）
- 仅 VIC Retention% 的 Rolling 12 起始月例外，需用月份字符串 EDATE 推导

### 2. end period 时间筛选（多数模块通用）

来源：VIC_KPIs_Table / VIC_Breakdown_ms / VIC_Segment_Table / LY_Last_Purchase_Time_Table

- **end period 定义**：所选时间范围的最后一个财月
  - 月：2026-09 → 只关注 2026-09
  - 季：2026 Q2 → 只关注 2026-06
  - 年：财年 2026 → 只关注 2026-12
- **只关注 `Slicer_Time_Frame_Max` 值**（Min 仅辅助）
- 筛选：`data_date ∈ [Last_Fiscal_Month_Min, Last_Fiscal_Month_Max]`

### 3. 全局时间范围筛选（Step 2 专用 / 柱形图冗余保护）

来源：Class_x_Label_Drilldown_list / VIC_Trend / VIC_Breakdown_Trend

- `dt ∈ [TimeFrame_Min, TimeFrame_Max]`
- 读取 `Slicer_Time_Frame_Min[TimeFrame_Min]` 和 `Slicer_Time_Frame_Max[TimeFrame_Max]`
- 柱形图中作为冗余保护，防止 X 轴超出全局范围

### 4. VIC Breakdown 专用日期表（与其他模块隔离）

来源：VIC_Breakdown_ms / VIC_Breakdown_Trend

| 原日期表（其他模块）  | VIC Breakdown 专用日期表            |
| --------------------- | ----------------------------------- |
| Slicer_Time_Frame     | Slicer_Time_Frame_VIC_Breakdown     |
| Slicer_Time_Frame_Max | Slicer_Time_Frame_Max_VIC_Breakdown |
| Slicer_Time_Frame_Min | Slicer_Time_Frame_Min_VIC_Breakdown |

- 字段结构完全一致（含 `Last_Fiscal_Month_*` 系列）
- 目的：避免与其他 VIC 模块的日期切片器互相干扰

### 5. VIC Trend 专用日期表（柱形图 X 轴）

来源：VIC_Trend

- `Slicer_Time_Frame_VIC_Trend` / `_Min_VIC_Trend` / `_Max_VIC_Trend`
- X 轴 = `Slicer_Time_Frame_VIC_Trend[TimeFrame_Value]`
- 同样含 `Last_Fiscal_Month_*` 系列字段，每个 X 轴时间点都自带 end period 区间

### 6. IsTimeFrameVisible 范式（柱形图 X 轴视觉对象级别筛选器）

来源：VIC_Trend / VIC_Breakdown_Trend

- 判断 X 轴当前遍历的 timeframe 是否落在起止切片器选定的范围内
- 筛选条件：**同粒度 + Key 在 [MinKey, MaxKey] 区间**
- 用作柱形图 X 轴的视觉对象级别筛选器（`IsTimeFrameVisible = 1`）

```dax
VAR __IsSameGranularity =
    NOT ISBLANK(__CurrentTimeFrameID)
    && __CurrentTimeFrameID = __MinTimeFrameID
    && __CurrentTimeFrameID = __MaxTimeFrameID
RETURN
    IF(
        NOT __IsSameGranularity, 0,
        IF(__CurrentKey >= __MinKey && __CurrentKey <= __MaxKey, 1, 0)
    )
```

---

## 三、VIC 标识字段体系

### 1. VIC 标识字段分类

来源：VIC_KPIs_Table / VIC_Breakdown_ms / Class_x_Label_Drilldown_list

| 字段                    | 含义                                   | 用途                                                                 |
| ----------------------- | -------------------------------------- | -------------------------------------------------------------------- |
| `is_vic`              | VIC（高价值客户）标识                  | VIC No. / VIC Retention% 分母                                        |
| `is_new_vic`          | 新 VIC                                 | VIC Breakdown - New VIC 大分组                                       |
| `is_retention_vic`    | 留存 VIC                               | VIC Breakdown - Retention VIC 大分组 / Class x Label - Net_Retention |
| `is_upgrade_vic`      | T4-5 升级 VIC                          | T4-5 Upgrade No. / Class x Label - Net_T4-5 Upgrade                  |
| `is_direct_vic`       | 直接买成 VIC                           | Direct VIC No. / Class x Label - Net_Direct                          |
| `is_fy_vic`           | 财年 VIC（LY Last Purchase Time 专用） | LY VIC No.                                                           |
| `is_fy_retention_vic` | 财年留存 VIC                           | VIC Retention No.（LY Last Purchase Time 模块）                      |
| `customer_tier`       | 客户分层（T1-T5）                      | VIC Segment 分组维度                                                 |

### 2. New VIC / Retention VIC 双大分组（仅筛选字段不同）

来源：VIC_Breakdown_ms

- **New VIC** 大分组（Metric_ID 1-22）：Step1 筛选 `is_new_vic = 1`
- **Retention VIC** 大分组（Metric_ID 23-44）：Step1 筛选 `is_retention_vic = 1`
- 两个大分组指标完全对称，唯一区别是筛选字段
- 实现方式：`__IsNewVIC = (VICType = "New VIC")` 布尔变量 + IF 分支（**不能用 TREATAS**，因 SWITCH 返回标量而非列引用）

---

## 四、人群筛选规则

### 1. is_member / is_employee 双重筛选

来源：所有 VIC 模块

- `__IsMemberFilter = SELECTEDVALUE(IsMemberFilter[IsMember], 0)` → 默认 TTL VIC
- `__IsEmployeeFilter = SELECTEDVALUE(Slicer_Is_Employee_Selection[IsEmployee_Code], 1)` → 默认 Yes
- 应用到 `a03_e2e_customer_data_m[is_member]` / `[is_employee]`

### 2. is_member 在 a03 vs t05 表的语义差异（关键）

来源：Class_x_Label_Drilldown_list

- **ads 层（a03 表）**：`is_member = 0` 代表所有订单，`is_member = 1` 代表会员订单
- **dw 层（t05 表）**：`is_member = 0` 代表非会员订单，`is_member = 1` 代表会员订单
- Step 2 中 `t05[is_member]` 筛选按 `__IsMemberFilter` 分支：
  - `__IsMemberFilter = 0`（TTL VIC）→ `t05[is_member] IN {0, 1}`（全部）
  - `__IsMemberFilter = 1`（会员 VIC）→ `t05[is_member] = 1`（仅会员）

```dax
(
    __IsMemberFilter = 0 && 't05_customer_order_data_d'[is_member] IN {0, 1}
)
|| (
    __IsMemberFilter = 1 && 't05_customer_order_data_d'[is_member] = 1
)
```

### 3. is_employee 仅 Step 1 应用

来源：Class_x_Label_Drilldown_list

- `t05_customer_order_data_d` 表无 `is_employee` 字段
- `is_employee` 仅在 Step 1（a03 表）应用，Step 2 不涉及

---

## 五、Step1 + Step2 两步法

### 1. 单步法（Step1 + Step2 合并）

来源：VIC_Segment_Table / VIC_Breakdown_ms

- 业务确认 Step2 时间 = end period 当月（与 Step1 一致）
- 实现时直接在 end period 当月区间内应用筛选，等价于单步聚合
- 无需 TREATAS / CONTAINS 做 user_id 传递

### 2. 两步法（Step1 框定 user_id + Step2 TREATAS 传递）

来源：Class_x_Label_Drilldown_list

- **Step 1**：在 `a03_e2e_customer_data_m` 中，`dt = end period`，筛选 VIC 标识 = 1，用 `VALUES(user_id)` 框定范围
- **Step 2**：在 `t05_customer_order_data_d` 中，`dt ∈ 全局时间范围`，用 `TREATAS` 将 Step 1 的 user_id 传递到 t05，做 `DISTINCTCOUNT(user_id)`
- **采用 TREATAS 的原因**：a03 和 t05 之间无直接模型关系（user_id 多对多），user_id 集合需显式传递

```dax
VAR __VICUserIds =
    CALCULATETABLE(
        VALUES('a03_e2e_customer_data_m'[user_id]),
        'a03_e2e_customer_data_m'[is_retention_vic] = 1,
        'a03_e2e_customer_data_m'[data_date] >= __PeriodMin,
        'a03_e2e_customer_data_m'[data_date] <= __PeriodMax
    )
VAR __Result =
    CALCULATE(
        DISTINCTCOUNT('t05_customer_order_data_d'[user_id]),
        't05_customer_order_data_d'[dt] >= __TimeMin,
        't05_customer_order_data_d'[dt] <= __TimeMax,
        TREATAS(__VICUserIds, 't05_customer_order_data_d'[user_id])
    )
```

### 3. 两表跨表传递的桥梁：共享切片器维度表

来源：Class_x_Label_Drilldown_list

| 切片器维度表                  | 与 a03 关系           | 与 t05 关系        | 传递字段                 |
| ----------------------------- | --------------------- | ------------------ | ------------------------ |
| `Slicer_Platform_Selection` | 1:N a03[platform]     | 1:N t05[platform]  | platform                 |
| `Slicer_Store_Name`         | 1:N a03[shop_name_en] | 1:N t05[shop_name] | shop（字段名不同但桥接） |

- `tier` / `category_summary` / `framework` / `product_id` / `brand` 仅影响所在事实表聚合，**不跨表传递**

---

## 六、关键指标计算逻辑

### 1. VIC Retention% 的 Rolling 12 个财月分母（仅此指标使用）

来源：VIC_KPIs_Table / VIC_Trend

- 分子：`is_retention_vic = 1`（end period 当月）DISTINCTCOUNT(user_id)
- 分母：end period 往前 Rolling 12 个财月 `is_vic = 1` 的 DISTINCTCOUNT(user_id)
- **区间 DISTINCT 汇总**：同一用户在 12 个月区间内只计一次（非按月 SUM 累加）
- 区间 = `[起始月 TimeFrame_Min, Last_Fiscal_Month_Max]`

**起始月推导**（基于财月字符串，不用天日期 EDATE）：

- 当期：`Last_Fiscal_Month` EDATE(-11)
- LY：`Last_Fiscal_Month` EDATE(-12) 得 LY 月份，再 EDATE(-11)（等价于往前推 23 个月）
- LP：`Last_Fiscal_Month` EDATE(-1) 得 LP 月份，再 EDATE(-11)（等价于往前推 12 个月）

```dax
// Rolling 12 起始月字符串
VAR __LFM = SELECTEDVALUE(Slicer_Time_Frame_Max[Last_Fiscal_Month])  // 如 "2026-09"
VAR __StartMonth = FORMAT(EDATE(DATE(LEFT(__LFM,4), RIGHT(__LFM,2), 1), -11), "yyyy-MM")
// 再用 __StartMonth 去 Slicer_Time_Frame_Max 查 TimeFrame_Label='月' AND TimeFrame_Value=__StartMonth 的 TimeFrame_Min
```

### 2. SLS Step1 + Step2 合并实现

来源：VIC_Segment_Table

- 业务确认 Step2 时间 = end period 当月
- 直接在 end period 当月对事实表按当前 customer_tier 行上下文做 SUM
- 无需显式用 TREATAS/CONTAINS 做 user_id 传递

### 3. SLS% 分母的 REMOVEFILTERS 机制（VIC Segment）

来源：VIC_Segment_Table

- SLS% 分母需移除 customer_tier 筛选以获取全客 SLS
- `REMOVEFILTERS(DIM_Row_VIC_Tier)` 移除 customer_tier
- 同时保留 platform / shop_info_id 筛选

### 4. SLS% 分子在 VIC Breakdown 中的特殊路由（关键修正）

来源：VIC_Breakdown_ms

- SLS% 分子（is_xxx_vic=1）用 `__SLSActMetricID` 路由到 SLS Act Metric_ID（New VIC: 1, Retention VIC: 23）
- SLS% 分母（全客）通过 `[VIC Breakdown Store Base Value]` 获取
- **关键修正**：不能用 `[Metric_ID]=4 + [ColType]="vs LP"` 冲突筛选
  - 原因：维度表中 Metric_ID=4 的 ColType 恒为 "Act"，冲突筛选会导致 SELECTEDVALUE 返回 BLANK
- 正确做法：按 VICType 映射 SLS% Metric_ID → Store Base Value 内部按 Metric_ID 自动推导时间区间

```dax
// SLS% vs LY = SLS%(Act) - SLS%(LY)
// 分母 Act 部分用 SLS% Act 的 Metric_ID（4/26）→ Store Base Value 路由到 Act 区间
// 分母 LY 部分用当前 Metric_ID（5/27）→ Store Base Value 路由到 LY 区间
VAR __SLSPctActMetricID = IF(__MetricID IN {4, 5, 6}, 4, 26)
VAR __SLSDenominatorAct = CALCULATE(
    [VIC Breakdown Store Base Value],
    REMOVEFILTERS('Dim_ColMetric_New_Retention_VIC'),
    'Dim_ColMetric_New_Retention_VIC'[Metric_ID] = __SLSPctActMetricID  // 4/26 → Act 区间
)
VAR __SLSDenominatorLY = CALCULATE(
    [VIC Breakdown Store Base Value],
    REMOVEFILTERS('Dim_ColMetric_New_Retention_VIC'),
    'Dim_ColMetric_New_Retention_VIC'[Metric_ID] = __MetricID  // 5/27 → LY 区间
)
```

### 5. Store Base Value 时间区间路由（关键修正）

来源：VIC_Breakdown_ms

- 本度量值被总路由通过 `CALCULATE + Metric_ID = x` 调用，外层会覆盖 Metric_ID
- **不能读 ColType**：维度表中 Metric_ID 与 ColType 一一绑定，覆盖 Metric_ID 后 SELECTEDVALUE(ColType) 会读到新 Metric_ID 对应行的 ColType，而非外层期望的区间
- **正确做法**：直接按 Metric_ID 推导时间区间

| Metric_ID               | 含义            | 时间区间 |
| ----------------------- | --------------- | -------- |
| 5/27                    | SLS% vs LY 分母 | LY 区间  |
| 6/28                    | SLS% vs LP 分母 | LP 区间  |
| 4/26                    | SLS% Act 分母   | Act 区间 |
| 10/14/18/22/32/36/40/44 | vs Store 分母   | Act 区间 |

```dax
VAR __PeriodMin =
    IF(
        __MetricID IN {5, 27},
        SELECTEDVALUE(Slicer_Time_Frame_Max_VIC_Breakdown[Last_Fiscal_Month_Min_LY]),
        IF(
            __MetricID IN {6, 28},
            SELECTEDVALUE(Slicer_Time_Frame_Max_VIC_Breakdown[Last_Fiscal_Month_Min_LP]),
            SELECTEDVALUE(Slicer_Time_Frame_Max_VIC_Breakdown[Last_Fiscal_Month_Min])  // Act / vs Store
        )
    )
```

### 6. vs Store 全客对比

来源：VIC_Breakdown_ms

- 分子：New VIC 或 Retention VIC 的 Act 值（`is_xxx_vic = 1`）
- 分母：全客值（`is_xxx_vic IN {0, 1}`）
- 计算：`分子 / 分母 - 1`
- vs Store 仅 ACV / UPT / AUR / Freq. 四个 KPI 分组有（SLS / SLS% 无 vs Store）

### 7. TAR ACH% 实际值/目标值

来源：VIC_KPIs_Table / Dim_ColMetric_VIC_KPIs

- 数据源：`a03_e2e_customer_fcst_data_m`（目标值表）
- TAR ACH% = 实际值 / 目标值
- 分 Monthly / Yearly 两种 ColType
- 口径文档标注"含正负号"，但按用户要求统一为 `percent_1dp`（不含正号）

### 8. VIC Customer Count 分组去重逻辑

来源：VIC_KPIs_Table

- **写法一（MAX 版）**：`SUMMARIZE(platform, shop_info_id)` + `CALCULATE(MAX(year_vic_customer_cnt))`
  - 本质：先按维度分组，再对指标列做聚合。
  - 适用场景：强依赖业务约束，即一个 `platform + shop_info_id` 组合下，`year_vic_customer_cnt` 必须唯一。
  - **关键风险**：若同一分组下存在多个不同数值（脏数据），`MAX` 会静默取最大值，导致分子被高估且不易察觉。
- **写法二（SUMMARIZE 三列版）**：`SUMMARIZE(platform, shop_info_id, year_vic_customer_cnt)` + 直接引用列
  - 本质：`SUMMARIZE` 引入指标列天然等价于 `DISTINCT`，直接对去重后的值求和。
  - 适用场景：标准的“分组去重后汇总”逻辑，不假设数据唯一性。
  - **关键优势**：语义清晰（等价于 SQL `GROUP BY` 三列），性能更优（减少上下文转换），且对 `NULL/BLANK` 分组处理一致；当数据存在多值风险时，能如实反映全量数据，避免逻辑黑洞。

```dax
// 推荐写法：语义准确，性能更好
VAR __VICCustomerSum =
CALCULATE(
    SUMX(
        SUMMARIZE(
            'a03_e2e_customer_fcst_data_m',
            'a03_e2e_customer_fcst_data_m'[platform],
            'a03_e2e_customer_fcst_data_m'[shop_info_id],
            'a03_e2e_customer_fcst_data_m'[year_vic_customer_cnt]
        ),
        'a03_e2e_customer_fcst_data_m'[year_vic_customer_cnt]
    ),
    'a03_e2e_customer_fcst_data_m'[data_date] >= __TimeMin,
    'a03_e2e_customer_fcst_data_m'[data_date] <= __TimeMax
)
```

---

### 9. BLANK 分组在聚合中的处理机制

来源：VIC_KPIs_Table

- **SUMMARIZE 对 NULL 的包容性行为**：`SUMMARIZE` 函数不会自动过滤 `BLANK` 值，`(BLANK, BLANK)` 会被视为合法的分组键参与计算。
- **视觉对象与计算逻辑的差异**：报表矩阵/表格默认隐藏全 `BLANK` 行，但 `SUMX` 迭代聚合时已包含该分组的值，导致“视觉汇总行”与“度量值结果”看似不一致。
- **正确做法**：若业务要求剔除未知维度（如“未知平台/店铺”），需显式使用 `FILTER + ISBLANK` 进行过滤；若需保留（如“未归类”统计），则当前 `SUMMARIZE` 逻辑已满足需求。

```dax
// 若需剔除 NULL 分组的写法示例
VAR __VICCustomerSum_ExcludeBlank =
CALCULATE(
    SUMX(
        SUMMARIZE(
            FILTER(
                'a03_e2e_customer_fcst_data_m',
                NOT ISBLANK('a03_e2e_customer_fcst_data_m'[platform]) &&
                NOT ISBLANK('a03_e2e_customer_fcst_data_m'[shop_info_id])
            ),
            'a03_e2e_customer_fcst_data_m'[platform],
            'a03_e2e_customer_fcst_data_m'[shop_info_id],
            'a03_e2e_customer_fcst_data_m'[year_vic_customer_cnt]
        ),
        'a03_e2e_customer_fcst_data_m'[year_vic_customer_cnt]
    ),
    'a03_e2e_customer_fcst_data_m'[data_date] >= __TimeMin,
    'a03_e2e_customer_fcst_data_m'[data_date] <= __TimeMax
)
```

---

## 七、派生指标分类与计算方式

### 1. 数量类 vs LY / vs LP / vs Store

来源：VIC_Breakdown_ms / VIC_KPIs_Table

- 计算：`今年 / 去年 - 1` / `当期 / 上期 - 1` / `New VIC / 全客 - 1`
- 格式：`delta_pct_0dp`（VIC Breakdown）/ `delta_pct_1dp`（VIC KPI）
- 适用：SLS / ACV / UPT / AUR / Freq. / VIC No. / T4-5 Upgrade No. / Direct VIC No.

### 2. 比率类 vs LY / vs LP（差值）

来源：VIC_Breakdown_ms / VIC_KPIs_Table

- 计算：`今年 - 去年`（差值，×100 转 pts）
- 格式：`delta_pts`
- 适用：SLS% / VIC Retention% / Share 类

```dax
// delta_pts 格式
IF(ROUND(__Value * 100, 0) > 0, "+", "") & FORMAT(__Value * 100, "#,##0pts;-#,##0pts;0pts")
// +120pts / -80pts / 0pts
```

### 3. YOY 派生指标的"去年"定义（LY Last Purchase Time 专用）

来源：LY_Last_Purchase_Time_Table / VIC_Segment_Table

- VIC Repurchase% YOY = (今年 VIC Repurchase No. / 今年 LY VIC No.) / (去年 VIC Repurchase No. / 去年 LY VIC No.) - 1
- VIC Retention% YOY = (今年 VIC Retention No. / 今年 LY VIC No.) / (去年 VIC Retention No. / 去年 LY VIC No.) - 1
- "去年" = LY end period 时间偏移（`Last_Fiscal_Month_Min_LY/Max_LY`）

---

## 八、货币转换规则

来源：VIC_Breakdown_ms / VIC_Segment_Table / VIC_Breakdown_Trend

- 汇率字段：`Slicer_Currency_Selection[Currency_ExchangeRate]`，默认 1（RMB）
- 货币符号字段：`Slicer_Currency_Selection[Currency_Symbol]`，默认 "¥"
- **金额类**（SLS / ACV / AUR）：`DIVIDE(SUM(net_pay_amt), __FXRate)` 做汇率换算
- **比率类**（SLS% / UPT / Freq. / vs Store）：不除（分子分母同币种抵消）
- RMB = 1，USD = 7

```dax
// SLS Value
VAR __SLS_Act = DIVIDE(SUM(net_pay_amt), __FXRate)
// Display
__CurrencySymbol & FORMAT(__Value, "#,##0")  // ¥1,000 / $1,000
```

---

## 九、Metric_Format 单字段格式化分发

来源：VIC_Breakdown_ms / Dim_ColMetric_VIC_KPIs / Dim_ColMetric_New_Retention_VIC

| Metric_Format            | 格式串                                                                                 | 示例       | 适用指标                        |
| ------------------------ | -------------------------------------------------------------------------------------- | ---------- | ------------------------------- |
| `integer`              | `FORMAT(__Value, "#,##0")`                                                           | 1,000      | VIC No. / T4-5 Upgrade No.      |
| `decimal_1dp`          | `FORMAT(__Value, "#,##0.0")`                                                         | 1.5        | UPT / Freq.                     |
| `currency`             | `__CurrencySymbol & FORMAT(__Value, "#,##0")`                                        | ¥1,000    | SLS Act                         |
| `currency_decimal_1dp` | `__CurrencySymbol & FORMAT(__Value, "#,##0.0")`                                      | ¥1,000.0  | ACV / AUR                       |
| `currency_k`           | `__CurrencySymbol & FORMAT(__Value/1000, "#,##0") & "k"`                             | ¥1k       | SLS Trend                       |
| `percent_0dp`          | `FORMAT(__Value, "#,##0%")`                                                          | 15%        | SLS%                            |
| `percent_1dp`          | `FORMAT(__Value, "0.0%")`                                                            | 40.5%      | TAR ACH% / VIC Retention%       |
| `delta_pct_0dp`        | `IF(__Value>0,"+","") & FORMAT(__Value,"#,##0%")`                                    | +15% / -3% | 数量类 vs LY / vs LP / vs Store |
| `delta_pts`            | `IF(ROUND(__Value*100,0)>0,"+","") & FORMAT(__Value*100,"+#,##0pts;-#,##0pts;0pts")` | +120pts    | SLS% vs LY / vs LP              |

---

## 十、Metric_ColorRule 三值调度

来源：VIC_Breakdown_ms / Dim_ColMetric_VIC_KPIs

| ColorRule         | 含义         | 颜色                                                                             | 适用                     |
| ----------------- | ------------ | -------------------------------------------------------------------------------- | ------------------------ |
| `fixed_black`   | 固定黑色     | `#252423`                                                                      | Act 列基础指标           |
| `pos_neg_zero`  | 正/负/零三色 | 正=`#1A9018` 绿 / 负=`#D64550` 红 / 零=`#E1C233` 黄 / BLANK=`#5F6165` 灰 | vs LY / vs LP / vs Store |
| `fixed_default` | 固定默认色   | `Metric_ColorDefault`                                                          | Share / 占比类           |

```dax
SWITCH(
    __ColorRule,
    "fixed_black", "#252423",
    "pos_neg_zero",
        SWITCH(
            TRUE(),
            ISBLANK(__Value), __ColorDefault,
            __Value > 0,      __ColorPositive,
            __Value < 0,      __ColorNegative,
            __Value = 0,      __ColorZero,
            __ColorDefault
        ),
    __ColorDefault
)
```

---

## 十一、维度表结构

### 1. Dim_ColMetric_VIC_KPIs（VIC KPI 列指标维度表）

来源：Dim_ColMetric_VIC_KPIs

- 28 行（5 个 KPI 分组 × 多列指标）
- 5 个 KPI 分组：VIC No. / VIC Retention% / T4-5 Upgrade No. / Retention VIC No. / Direct VIC No.
- ColType：Act / vs LY / vs LP / TAR ACH% Monthly / TAR ACH% Yearly / TAR ACH% / Share / Share vs LY / Share vs LP
- ColName 加 Metric_ID 前缀（支持同名独立排序，规避 Power BI Sort by Column 限制）

### 2. Dim_ColMetric_New_Retention_VIC（VIC Breakdown 列指标维度表）

来源：Dim_ColMetric_New_Retention_VIC

- 44 行（2 大分组 × 22 列）
- 三级列头：`VICType`（父）> `KPIGroup`（中）> `ColName`（子）
- 2 大分组：New VIC（Metric_ID 1-22）/ Retention VIC（Metric_ID 23-44）
- 6 个 KPI 分组：SLS / SLS% / ACV / UPT / AUR / Freq.
- ColType：Act / vs LY / vs LP / vs Store

### 3. DIM_Row_VIC_Tier（VIC Segment 行维度表）

来源：DIM_Row_VIC_Tier / VIC_Segment_Table

- 1:N 维度表（与 a03[customer_tier] 建立 1:N 关系）
- 5 个分层：T1(≧200K) / T2(80-200K) / T3(20-80K) / T4(5-20K) / T5(<5K)
- 分组维度由模型自动传递

### 4. DIM_Row_LY_Last_Purchase_Time（LY Last Purchase Time 行维度表）

来源：DIM_Row_LY_Last_Purchase_Time

- 断开维度表
- 行标签：R3 / R4-6 / R7-9 / R10-12 / TTL
- 实际表格方案直接拉事实表字段 `last_fy_last_order_month_type`，不使用此维度表

---

## 十二、Metric_ID 路由全景

### 1. VIC KPI Metric_ID（1-28）

来源：VIC_KPIs_Table / Dim_ColMetric_VIC_KPIs

- 1-5：VIC No.（Act / vs LY / vs LP / TAR Monthly / TAR Yearly）
- 6-9：VIC Retention%（Act / vs LY / vs LP / TAR ACH%）
- 10-16：T4-5 Upgrade No.（Act / vs LY / vs LP / TAR / Share / Share vs LY / Share vs LP）
- 17-22：Retention VIC No.（同 T4-5 Upgrade 结构）
- 23-28：Direct VIC No.（同 T4-5 Upgrade 结构）

### 2. VIC Breakdown Metric_ID（1-44）

来源：VIC_Breakdown_ms / Dim_ColMetric_New_Retention_VIC

- 1-22：New VIC
  - 1/4/7/11/15/19：SLS/SLS%/ACV/UPT/AUR/Freq. Act
  - 2/8/12/16/20：数量类 vs LY
  - 3/9/13/17/21：数量类 vs LP
  - 10/14/18/22：vs Store（仅 ACV/UPT/AUR/Freq.）
  - 5/6：SLS% vs LY / vs LP（比率类差值）
- 23-44：Retention VIC（与 New VIC 完全对称，仅 is_xxx_vic 字段不同）

---

## 十三、数据底表与关键字段

### 1. a03_e2e_customer_data_m（月度聚合表）

来源：所有 VIC 模块

- 月度聚合表（每用户每月一行）
- `data_date` 为月末日期，Power Query 中通过 `LAST_DAY(DATE_SUB(STR_TO_DATE(CONCAT(data_month,'01'),'%Y%m%d'), INTERVAL 10 MONTH))` 计算
- 关键字段：
  - 时间：`data_date`
  - 分组：`platform`, `shop_info_id`, `shop_name_en`, `customer_tier`, `last_fy_last_order_month_type`
  - 用户：`user_id`
  - 人群：`is_member`, `is_employee`
  - VIC 标识：`is_vic`, `is_new_vic`, `is_retention_vic`, `is_upgrade_vic`, `is_direct_vic`, `is_fy_vic`, `is_fy_retention_vic`
  - 金额：`net_pay_amt`, `net_pay_qty`, `net_pay_order_cnt`
  - 滚动金额：`last_12m_net_pay_amt`

### 2. t05_customer_order_data_d（订单明细表）

来源：Class_x_Label_Drilldown_list

- 订单明细表，`dt` 为订单日期
- 用于 Step 2 全局时间范围 DISTINCTCOUNT(user_id)
- 关键字段：`dt`, `platform`, `shop_name`, `user_id`, `is_member`, `category_summary`, `framework`, `product_id`, `brand`
- **无 `is_employee` 字段**

### 3. a03_e2e_customer_fcst_data_m（目标值表）

来源：VIC_KPIs_Table

- 用于 TAR ACH% 指标的目标值

---

## 十四、背景色分发（Matrix 层级行区分）

来源：VIC_Breakdown_ms

```dax
// ISINSCOPE 判断当前行层级
IF(
    ISINSCOPE('Dim_ColMetric_New_Retention_VIC'[ColName]),
    "#FFFFFF",   // ColName 行：白色
    IF(
        ISINSCOPE('Dim_ColMetric_New_Retention_VIC'[KPIGroup]),
        "#F0E6D2",  // KPIGroup 行：浅米色
        "#E6D9C7"   // VICType 行：中米色
    )
)
```

---

## 十五、模块间关键差异速查

| 模块                    | 视觉对象      | 路由方式    | 时间筛选                          | 计算模式                   | 数据底表       |
| ----------------------- | ------------- | ----------- | --------------------------------- | -------------------------- | -------------- |
| VIC KPI                 | Matrix        | SWITCH 路由 | end period                        | 单步法                     | a03 单表       |
| VIC KPI Pie Chart       | 饼图          | 独立度量值  | end period                        | 单步法                     | a03 单表       |
| VIC Trend               | 柱形图        | 独立度量值  | X 轴 end period + 全局范围冗余    | 单步法                     | a03 单表       |
| LY Last Purchase Time   | 表格          | 独立度量值  | end period + YOY 用 LY            | 单步法                     | a03 单表       |
| VIC Segment             | 表格          | 独立度量值  | end period                        | 单步法（Step1+Step2 合并） | a03 单表       |
| VIC Breakdown           | Matrix        | SWITCH 路由 | end period                        | 单步法                     | a03 单表       |
| VIC Breakdown Trend     | 柱形图        | 独立度量值  | X 轴 end period + 全局范围冗余    | 单步法                     | a03 单表       |
| Class x Label Drilldown | 条形图 + 表格 | 独立度量值  | Step1 end period + Step2 全局范围 | 两步法（TREATAS）          | a03 + t05 双表 |

---

## 十六、关键注意事项（Lessons Learned）

来源：VIC_Breakdown_ms（项目记忆）

1. **Metric_ID=4 时 ColType 必为 'Act'**：不能用 `[Metric_ID]=4 + [ColType]='vs LP'` 冲突筛选
2. **Store Base Value 时间区间必须从 Metric_ID 推导**：不能用 ColType，否则外层覆盖 Metric_ID 后冲突
3. **SLS% 分母 Act 部分用 `__SLSPctActMetricID`（4/26）**：不能用当前 Metric_ID
4. **vs Store 分母不能包含冗余 `[ColType]='vs Store'` 覆盖**：会与 Metric_ID 推导冲突
5. **Act/LY/LP Base Value 对 SLS% 应返回 BLANK()**：实际 SLS% 计算在总路由中完成
6. **文档必须随核心路由方法变更更新**：如 ColType → Metric_ID 推导的变更需同步更新逻辑描述
7. **SWITCH 返回标量而非列引用**：不能用于 TREATAS，改用布尔变量 + IF 分支
8. **a03 与 t05 的 is_member 语义不同**：ads 层 0=所有订单，dw 层 0=非会员订单
