# Top Color Sales Performance 表格解决方案

> **版本**: v1.0
> **模块**: RL E2E Merch Dashboard - SKU Sales Tracking Tab - Top Color Sales Performance
> **关联口径**: 口径文档/口径Markdown格式/SKU Sales Tracking.md - 子模块三 Top Color Sales Performance【Sales】（§3~§6）+ 子模块四 Top Color Sales Performance【Inventory】（§7~§10）
> **数据底表（销售类）**: s02_trade_sku_data_d
> **数据底表（库存类）**: s02_inventory_stock_sales_detail_d
> **关联维度**: Slicer_Time_Frame_Min_This / Max_This（时间，断开维度）；Slicer_Currency_Selection（币种，断开维度）
> **筛选影响范围**: date + Platform + Store Name + Division（其余商品维度切片器对图表的筛选在页面编辑交互中取消）

---

## 1. 需求理解

### 1.1 模块定位

Top Color Sales Performance 是 SKU Sales Tracking Tab 的颜色维度子模块，以两张并排表格展示 Top10 颜色的销售与期末库存表现：

- **Sales 表格**：Top10 color 按 This Period `sum(net_sales_amt)` 降序排列，展示 SLS Amt / SLS Amt% / SLS Unit / SLS Unit% 四列指标
- **Inventory 表格**：Top10 color 按 This Period 最后一天 `sum(msrp_inv_amt)` 降序排列，展示 EOH Amt / EOH Amt% / EOH Unit / EOH Unit% 四列指标
- 两表独立呈现、同时可见，无书签切换

### 1.2 行维度与 Top10 机制

| 层级 | 字段  | Sales 表格来源                   | Inventory 表格来源                             |
| ---- | ----- | -------------------------------- | ---------------------------------------------- |
| 1    | Color | s02_trade_sku_data_d[color_name] | s02_inventory_stock_sales_detail_d[color_name] |

- **Sales Top10**：date + Platform + Store Name + Division 筛选组合下，按 color 粒度 This Period `sum(net_sales_amt)` 降序取排名前 10
- **Inventory Top10**：date + Division 筛选组合下，按 color 粒度 This Period 最后一天 `sum(msrp_inv_amt)` 降序取排名前 10
- **排名语义**：金额降序为第一序，金额相同的 color 按 color_name 字母序升序决胜，名次严格连续唯一（1、2、3、……）——名称决胜后不存在共享名次，Top10 恒为 10 行、边界确定（见注意事项 5）
- 通过表格视觉级筛选器（Color Rank 介于 1 与 10）固定行范围，无需为表格单独构建维度表
- **占比分母为全量 color**（含 Top10 之外颜色的金额，非 Top10 集合）：Top10 行的 Amt% / Unit% 加总小于 100%；拓展为 Top10 集合分母的修改方式见 §9

### 1.3 指标清单

| 视图      | 指标      | 计算公式                                                                            | 时间口径                     | 数据类型 / 格式                 |
| --------- | --------- | ----------------------------------------------------------------------------------- | ---------------------------- | ------------------------------- |
| Sales     | SLS Amt   | 该 color 下`sum(net_sales_amt)`                                                   | This Period（区间）          | currency → 币种符号 +`#,##0` |
| Sales     | SLS Amt%  | 分子：该 color 下`sum(net_sales_amt)`；分母：全量 color 下 `sum(net_sales_amt)` | This Period（区间）          | percent_0dp →`#,##0%`        |
| Sales     | SLS Unit  | 该 color 下`sum(product_qty)`                                                     | This Period（区间）          | integer →`#,##0`             |
| Sales     | SLS Unit% | 分子：该 color 下`sum(product_qty)`；分母：全量 color 下 `sum(product_qty)`     | This Period（区间）          | percent_0dp →`#,##0%`        |
| Inventory | EOH Amt   | 该 color 下`sum(msrp_inv_amt)`                                                    | This Period 最后一天（时点） | currency → 币种符号 +`#,##0` |
| Inventory | EOH Amt%  | 分子：该 color 下`sum(msrp_inv_amt)`；分母：全量 color 下 `sum(msrp_inv_amt)`   | This Period 最后一天（时点） | percent_0dp →`#,##0%`        |
| Inventory | EOH Unit  | 该 color 下`sum(stock_inv_qty)`                                                   | This Period 最后一天（时点） | integer →`#,##0`             |
| Inventory | EOH Unit% | 分子：该 color 下`sum(stock_inv_qty)`；分母：全量 color 下 `sum(stock_inv_qty)` | This Period 最后一天（时点） | percent_0dp →`#,##0%`        |

### 1.4 时间口径

| 口径                     | 时间范围                                                                                                                          | 适用指标                               |
| ------------------------ | --------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------- |
| This Period（区间类）    | dt ∈ [Slicer_Time_Frame_Min_This[TimeFrame_Min], Slicer_Time_Frame_Max_This[TimeFrame_Max]]                                      | SLS 系列全部指标、Sales Top10 排序     |
| End Period（期末时点类） | end period 范围 [Slicer_Time_Frame_Max_This[TimeFrame_Min], Slicer_Time_Frame_Max_This[TimeFrame_Max]] 内**最后一个快照日** | EOH 系列全部指标、Inventory Top10 排序 |

说明：

- 期末时点口径实现为「end period 范围内最后一个有数据的快照日」：口径定义为 this period 最后一天（TimeFrame_Max），快照缺数时自动回退到范围内最近一天，避免整段空值
- 快照表按日存储，期末时点**只取单日**，对 end period 整段区间求和会把库存重复计数

### 1.5 币种口径

- SLS Amt / EOH Amt 为 currency 类指标：货币符号由币种切片器（Slicer_Currency_Selection）决定，千分位整数
- 数据底表金额仅存储 RMB：选择 USD 时按 `Currency_ExchangeRate`（动态取自数仓 dim_t00_currency 表 USD→CNY 最新有效汇率）换算。**Value 层完成汇率换算**（输出当前币种金额 = 原始 RMB 值 ÷ 汇率），**Display 层仅拼接币种符号**；RMB 时汇率为 1，换算前后值相同
- 占比类（Amt% / Unit%）与数量类（Unit）不涉及币种换算：占比分子分母同币种，换算与否比值不变

---

## 2. 现状分析

- 数据底表 `s02_trade_sku_data_d`（SKU 粒度交易表，dt 日粒度）：net_sales_amt 为 Power Query 取数时新增列（`ROUND(product_qty * sales_price, 6) AS net_sales_amt`），业务已确认；数量口径字段为 product_qty（商品购买数量，即净销售数量口径——net_sales_amt 由 product_qty × sales_price 行级计算而来，二者同源）；维度含 dt、platform、shop_name、division、color_name 及其余商品维度
- 数据底表 `s02_inventory_stock_sales_detail_d`（库存+销售+补货 SKU 模型表，dt 日快照）：msrp_inv_amt（吊牌库存金额）为期末库存金额口径字段；stock_inv_qty（在库库存数量）为期末库存数量口径字段；维度含 dt、division、color_name 等；**无 platform / shop_name 字段**（渠道筛选不影响库存侧指标，口径限制见注意事项 1）
- 模型关系：日期筛选器（Slicer_Time_Frame_Min_This / Max_This）为断开维度，时间范围在 DAX 中显式筛选，不依赖模型关系传递；Platform（Slicer_Platform_Selection）、Store Name（Slicer_Store_Name）、Division（Slicer_Division）与两张事实表一对多关联，筛选自动传递，DAX 无需显式处理；Slicer_Currency_Selection 为断开维度，币种符号与汇率经 SELECTEDVALUE 读取
- 字段名已逐一核对数据字典与取数 SQL（两表日期字段统一为 dt，date 类型）
- **SLS Unit% 分母口径修正记录**：口径文档原文分母为 `sum(sales_qty)`，该字段在 s02_trade_sku_data_d 数据字典与 Power Query 取数 SQL 中均不存在（取数仅新增 net_sales_amt 一列），经业务确认修正为 `sum(product_qty)`——与分子同字段，全部 color 占比加总 = 100%（2026-10-15 业务确认）

---

## 3. 方案设计

### 3.1 度量值分层

```
Color Rank（视觉级筛选 + 行排序依据）
←  Top10 color 排名（Sales 按 This Period 区间净销售、Inventory 按 This Period 期末库存金额，金额降序 + 名称字母序决胜）
↓
Value（口径计算，保留小数原值）
←  分子 / 分母时间范围显式筛选；占比分母 REMOVEFILTERS(color_name) 上卷至全量
←  金额类 Value 层完成币种汇率换算（原始 RMB ÷ Currency_ExchangeRate）
↓
Display（格式化显示）
←  currency: 币种符号 & FORMAT(#,##0)；integer: FORMAT(#,##0)；percent_0dp: FORMAT(#,##0%)
```

### 3.2 Top10 行筛选机制

每个表格视觉对象配置两条视觉级筛选器：

| 筛选器                        | 条件               | 作用                                                                           |
| ----------------------------- | ------------------ | ------------------------------------------------------------------------------ |
| Top Color Sales Color Rank    | 介于 1 与 10（含） | 仅显示排名前 10 的 color 行（名次唯一，恰好 10 行）                            |
| Top Color Sales SLS Amt Value | 不为空             | 仅显示 This Period 有销售数据的 color（Rank 对当期无金额行返回 BLANK，双保险） |

（Inventory 表格对应使用 Top Color Inventory Color Rank 与 Top Color Inventory EOH Amt Value）

机制说明：

- 视觉级筛选器对 Rank 的取值发生在筛选生效前（真实排名），行按真实名次保留
- Rank 度量对空白 / 空字符 / 当期无金额的 color 返回 BLANK；数值筛选器「介于 1 与 10」对 BLANK 判定为不在区间内（BLANK 视为 0），此类行被排除——**不可仅配置「小于或等于 10」**，BLANK 会被放行
- 视觉级 Rank 筛选器落地为 color_name 单列筛选，会被占比分母的 `REMOVEFILTERS(color_name)` 一并移除，分母不受 Top10 行筛选影响（占比始终按全量口径）

### 3.3 占比口径分母层级

分母 = 全量 color 汇总（该 color 占 total 的比例）：分母计算中 `REMOVEFILTERS(color_name)` 移除 color 行筛选与视觉级 Top10 筛选落地的列筛选，保留外部切片器（Platform / Store Name / Division）筛选，分母与分子处于同一时间范围。

- 分母覆盖全部 color（含 Top10 之外颜色的金额，亦含空白 color_name 记录的金额）：Top10 行的 Amt% / Unit% 加总小于 100%
- 金额类分子分母均为原始 RMB 聚合（不经汇率换算），占比不受币种选择影响

### 3.4 度量值命名与组织

- 命名规则：模块前缀 `Top Color` + 视图（Sales / Inventory）+ 指标名 + 层次后缀（Rank / Value / Display）
- Display Folder：`Top Color Sales Performance\Rank`、`Top Color Sales Performance\Base Metrics`、`Top Color Sales Performance\Formatting`
- 度量值统一存放于 `_Measures` 隐藏表（与看板既有组织方式一致）

### 3.5 行排序机制

表格行按主指标降序排列（金额相同的 color 按 color_name 字母序分先后）：

- Sales 表格：按 Color Rank 升序（行序 = 当期净销售金额降序 + color_name 字母序决胜）
- Inventory 表格：按 Color Rank 升序（行序 = 期末库存金额降序 + color_name 字母序决胜）

实现方式：将对应 Rank 度量拖入表格值区域（置于最后一列并收窄列宽），点击该列标题按升序排序。Rank 名次严格唯一连续（金额降序 + 名称字母序决胜，与 Top10 筛选同一排序口径），升序行序与主指标降序完全一致、金额并列行序确定；主指标 Display 为文本（含币种符号）无法直接作数值排序依据，Value 为当前币种金额（金额完全相等的行序以表格呈现为准），确定性均不如 Rank 升序（见注意事项 5、9）。

---

## 4. 度量值实现

### 4.1 Top Color Sales Color Rank（Sales Top10 排名）

```dax
Top Color Sales Color Rank =
// ========================================
// 度量值: Top Color Sales Color Rank
// 中文名: Sales 表格 Color Top10 排名
// Display Folder: Top Color Sales Performance\Rank
// 用途: 计算当前行 color 按 This Period sum(net_sales_amt) 的降序排名，
//       用于 Sales 表格视觉级筛选器固定 Top10 color 并作为行排序依据
// 依赖: Slicer_Time_Frame_Min_This[TimeFrame_Min] / Slicer_Time_Frame_Max_This[TimeFrame_Max]
// 口径: date + Platform + Store Name + Division 筛选组合下，按 color 粒度
//       This Period sum(net_sales_amt) 降序排名
// 排名语义: 金额降序为第一序，金额相同的 color 按 color_name 字母序升序决胜，
//       名次严格连续唯一（1、2、3、……）——名称决胜后不存在共享名次，
//       Top10 恒为 10 行、边界确定（见注意事项 5）
// 函数: RANK 窗口函数（Power BI Desktop 2022 年 9 月及以后版本可用）——
//       无 value 参数，当前行经 ORDERBY 中的 relation 列（color_name）与
//       relation 行匹配确定名次；DENSE 保证名次连续不跳号（元组唯一时
//       名次即排序位置）
// 说明: 排名基于 color 粒度金额（原始 RMB 聚合，不经币种换算——除以同一
//       正汇率不改变相对顺序）；relation 为 ALL(color_name)——移除 color
//       列全部筛选（含视觉级筛选器落地筛选），保留外部切片器筛选；ORDERBY
//       表达式在 relation 每行的行上下文中评估（上下文转换以候选 color
//       覆盖当前行 color 筛选，与候选金额同口径）
// 空白/空字符与无金额排除: color_name 存在 NULL 与空字符时，视觉级筛选器
//       无法排除空字符行（空字符非 BLANK、可能金额最大占据排名 1），必须在
//       relation 内部用 LEN(TRIM()) > 0 排除；当期无销售金额的候选同样排除
//       （不占名次，避免其排序位置使有效 color 名次整体偏移导致区间筛选
//       误排，见注意事项 15）；当前行为空白 / 无金额时返回 BLANK 被筛选器
//       排除（relation 无匹配行 + 外层 IF 显式拦截，双保险）
// ========================================

// ── This Period 时间区间 ──
VAR __PeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Min_This[TimeFrame_Min])
VAR __PeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

// ── 当前行 color（空白/空字符拦截的判定依据）──
VAR __CurrentColor = SELECTEDVALUE('s02_trade_sku_data_d'[color_name])

// ── 当前行 color 的 This Period 净销售金额（无金额行返回 BLANK 的拦截依据）──
VAR __CurrentColorAmt =
    CALCULATE(
        SUM('s02_trade_sku_data_d'[net_sales_amt]),
        's02_trade_sku_data_d'[dt] >= __PeriodMin,
        's02_trade_sku_data_d'[dt] <= __PeriodMax
    )

// ── 排名：RANK 窗口函数（金额降序 + color_name 字母序决胜，唯一名次）──
// relation：全部有效且当期有金额的 color 候选；
// ORDERBY：第一键金额降序（金额大 = 名次靠前），第二键 color_name 字母序
// 升序决胜（金额相同的 color 按名称分先后，名次相邻不并列）
RETURN
    IF(
        NOT ISBLANK(__CurrentColor) && LEN(TRIM(__CurrentColor)) > 0,
        IF(
            ISBLANK(__CurrentColorAmt),
            BLANK(),
            RANK(
                DENSE,
                FILTER(
                    ALL('s02_trade_sku_data_d'[color_name]),
                    NOT ISBLANK('s02_trade_sku_data_d'[color_name])
                        && LEN(TRIM('s02_trade_sku_data_d'[color_name])) > 0
                        && NOT ISBLANK(
                            CALCULATE(
                                SUM('s02_trade_sku_data_d'[net_sales_amt]),
                                's02_trade_sku_data_d'[dt] >= __PeriodMin,
                                's02_trade_sku_data_d'[dt] <= __PeriodMax
                            )
                        )
                ),
                ORDERBY(
                    CALCULATE(
                        SUM('s02_trade_sku_data_d'[net_sales_amt]),
                        's02_trade_sku_data_d'[dt] >= __PeriodMin,
                        's02_trade_sku_data_d'[dt] <= __PeriodMax
                    ), DESC,
                    's02_trade_sku_data_d'[color_name], ASC    // 金额相同按名称字母序决胜
                )
            )
        )
    )
```

### 4.2 Top Color Inventory Color Rank（Inventory Top10 排名）

```dax
Top Color Inventory Color Rank =
// ========================================
// 度量值: Top Color Inventory Color Rank
// 中文名: Inventory 表格 Color Top10 排名
// Display Folder: Top Color Sales Performance\Rank
// 用途: 计算当前行 color 按 This Period 最后一天 sum(msrp_inv_amt) 的降序排名，
//       用于 Inventory 表格视觉级筛选器固定 Top10 color 并作为行排序依据
// 依赖: Slicer_Time_Frame_Max_This[TimeFrame_Min] / [TimeFrame_Max]
// 口径: date + Division 筛选组合下，按 color 粒度 This Period 最后一天
//       sum(msrp_inv_amt) 降序排名（期末时点数）
// 排名语义: 金额降序 + color_name 字母序升序决胜，名次严格连续唯一
//       （同 Sales Rank，见注意事项 5）；排名用原始 RMB 金额聚合，不经币种换算
// 函数: RANK 窗口函数（机制同 Sales Rank，见注意事项 15）
// 说明: inv 表无 platform / shop_name 字段，排名不受渠道筛选影响（口径限制见
//       注意事项 1）；期末快照日经 REMOVEFILTERS(整表) 全表确定性取值；
//       relation 排除空白/空字符与快照日无库存金额的 color（不占名次），
//       当前行为空白 / 无金额时返回 BLANK 被筛选器排除（双保险）
// ========================================

// ── End Period 时间范围（期末时点类）──
VAR __EndPeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Min])
VAR __EndPeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

// ── 期末日期：end period 最后一天 = Max_This 表 TimeFrame_Max（直接单日过滤）──
VAR __EndPeriodDate = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

// ── 当前行 color（空白/空字符拦截的判定依据）──
VAR __CurrentColor = SELECTEDVALUE('s02_inventory_stock_sales_detail_d'[color_name])

// ── 当前行 color 的期末库存金额（无金额行返回 BLANK 的拦截依据）──
VAR __CurrentColorAmt =
    CALCULATE(
        SUM('s02_inventory_stock_sales_detail_d'[msrp_inv_amt]),
        's02_inventory_stock_sales_detail_d'[dt] = __EndPeriodDate
    )

// ── 排名：RANK 窗口函数（期末库存金额降序 + color_name 字母序决胜，唯一名次）──
RETURN
    IF(
        NOT ISBLANK(__CurrentColor) && LEN(TRIM(__CurrentColor)) > 0,
        IF(
            ISBLANK(__CurrentColorAmt),
            BLANK(),
            RANK(
                DENSE,
                FILTER(
                    ALL('s02_inventory_stock_sales_detail_d'[color_name]),
                    NOT ISBLANK('s02_inventory_stock_sales_detail_d'[color_name])
                        && LEN(TRIM('s02_inventory_stock_sales_detail_d'[color_name])) > 0
                        && NOT ISBLANK(
                            CALCULATE(
                                SUM('s02_inventory_stock_sales_detail_d'[msrp_inv_amt]),
                                's02_inventory_stock_sales_detail_d'[dt] = __EndPeriodDate
                            )
                        )
                ),
                ORDERBY(
                    CALCULATE(
                        SUM('s02_inventory_stock_sales_detail_d'[msrp_inv_amt]),
                        's02_inventory_stock_sales_detail_d'[dt] = __EndPeriodDate
                    ), DESC,
                    's02_inventory_stock_sales_detail_d'[color_name], ASC    // 金额相同按名称字母序决胜
                )
            )
        )
    )
```

### 4.3 Top Color Sales SLS Amt Value（当期净销售金额）

```dax
Top Color Sales SLS Amt Value =
// ========================================
// 度量值: Top Color Sales SLS Amt Value
// 中文名: 当期净销售金额
// Display Folder: Top Color Sales Performance\Base Metrics
// 用途: 该 color This Period 净销售金额（当前币种），用于表格展示排序依据与交叉验证
// 依赖: Slicer_Time_Frame_Min_This[TimeFrame_Min] / Slicer_Time_Frame_Max_This[TimeFrame_Max]
//       Slicer_Currency_Selection[Currency_ExchangeRate]
// 口径: 时间范围看 this period（区间汇总）；该 color 下 sum(net_sales_amt)
// 数据底表: s02_trade_sku_data_d
// 币种: 数据底表仅存 RMB，Value 层换算为当前币种金额（原始值 ÷ 汇率）；
//       RMB 汇率 = 1 时换算前后值相同；除以同一正汇率不改变 color 间相对大小（排序不受币种选择影响）
// ========================================

// ── This Period 时间区间 ──
VAR __PeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Min_This[TimeFrame_Min])
VAR __PeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

// ── 币种汇率（RMB = 1；USD 动态取自数仓汇率表）──
VAR __ExchangeRate = SELECTEDVALUE(Slicer_Currency_Selection[Currency_ExchangeRate], 1)

// ── 该 color This Period 净销售金额（原始 RMB）──
VAR __BaseValue =
    CALCULATE(
        SUM('s02_trade_sku_data_d'[net_sales_amt]),
        's02_trade_sku_data_d'[dt] >= __PeriodMin,
        's02_trade_sku_data_d'[dt] <= __PeriodMax
    )

RETURN
    DIVIDE(__BaseValue, __ExchangeRate)   // BLANK ÷ 汇率 = BLANK（当期无销售数据行返回空）
```

### 4.4 Top Color Sales SLS Amt% Value（当期销售金额占比）

```dax
Top Color Sales SLS Amt% Value =
// ========================================
// 度量值: Top Color Sales SLS Amt% Value
// 中文名: 当期销售金额占比
// Display Folder: Top Color Sales Performance\Base Metrics
// 用途: 该 color 占 total 的销售金额比例（This Period 区间）
// 依赖: Slicer_Time_Frame_Min_This[TimeFrame_Min] / Slicer_Time_Frame_Max_This[TimeFrame_Max]
// 口径: 分子：该 color 下 sum(net_sales_amt)；分母：全量 color 下 sum(net_sales_amt)
// 数据底表: s02_trade_sku_data_d
// 说明: 分母为全量 color 汇总（含 Top10 之外颜色的金额）——Top10 行占比加总小于 100%，
//       占比基数不随 Top10 行筛选变化；视觉级 Rank 筛选落地为 color_name 单列筛选，
//       被分母 REMOVEFILTERS(color_name) 一并移除，分母不受行筛选影响；
//       拓展为 Top10 color 集合分母的修改方式见 §9
// ========================================

// ── This Period 时间区间 ──
VAR __PeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Min_This[TimeFrame_Min])
VAR __PeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

// ── 分子：当前行 color This Period 净销售金额（原始 RMB）──
VAR __Numerator =
    CALCULATE(
        SUM('s02_trade_sku_data_d'[net_sales_amt]),
        's02_trade_sku_data_d'[dt] >= __PeriodMin,
        's02_trade_sku_data_d'[dt] <= __PeriodMax
    )

// ── 分母：全量 color This Period 净销售金额 ──
// REMOVEFILTERS(color_name) 移除 color 行筛选与视觉级 Top10 筛选落地筛选，
// 保留 Platform / Store Name / Division 外部切片器筛选
VAR __Denominator =
    CALCULATE(
        SUM('s02_trade_sku_data_d'[net_sales_amt]),
        REMOVEFILTERS('s02_trade_sku_data_d'[color_name]),
        's02_trade_sku_data_d'[dt] >= __PeriodMin,
        's02_trade_sku_data_d'[dt] <= __PeriodMax
    )

RETURN
    DIVIDE(__Numerator, __Denominator)
```

### 4.5 Top Color Sales SLS Unit Value（当期净销售数量）

```dax
Top Color Sales SLS Unit Value =
// ========================================
// 度量值: Top Color Sales SLS Unit Value
// 中文名: 当期净销售数量
// Display Folder: Top Color Sales Performance\Base Metrics
// 用途: 该 color This Period 净销售数量
// 依赖: Slicer_Time_Frame_Min_This[TimeFrame_Min] / Slicer_Time_Frame_Max_This[TimeFrame_Max]
// 口径: 时间范围看 this period；该 color 下 sum(product_qty)
// 数据底表: s02_trade_sku_data_d
// 说明: product_qty 为净销售数量口径字段（net_sales_amt = product_qty × sales_price 行级
//       计算而来，二者同源）；数量类不涉及币种换算
// ========================================

// ── This Period 时间区间 ──
VAR __PeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Min_This[TimeFrame_Min])
VAR __PeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

RETURN
    CALCULATE(
        SUM('s02_trade_sku_data_d'[product_qty]),
        's02_trade_sku_data_d'[dt] >= __PeriodMin,
        's02_trade_sku_data_d'[dt] <= __PeriodMax
    )
```

### 4.6 Top Color Sales SLS Unit% Value（当期净销售数量占比）

```dax
Top Color Sales SLS Unit% Value =
// ========================================
// 度量值: Top Color Sales SLS Unit% Value
// 中文名: 当期净销售数量占比
// Display Folder: Top Color Sales Performance\Base Metrics
// 用途: 该 color 占 total 的净销售数量比例（This Period 区间）
// 依赖: Slicer_Time_Frame_Min_This[TimeFrame_Min] / Slicer_Time_Frame_Max_This[TimeFrame_Max]
// 口径: 分子：该 color 下 sum(product_qty)；分母：全量 color 下 sum(product_qty)
// 数据底表: s02_trade_sku_data_d
// 口径修正: 口径文档原文分母为 sum(sales_qty)，该字段在数据字典与取数 SQL 中均不存在，
//       经业务确认修正为 sum(product_qty)（与分子同字段，全部 color 占比加总 = 100%，
//       2026-10-15 确认）
// 说明: 分母为全量 color 汇总（含 Top10 之外颜色的数量），机制同 SLS Amt% Value
// ========================================

// ── This Period 时间区间 ──
VAR __PeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Min_This[TimeFrame_Min])
VAR __PeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

// ── 分子：当前行 color This Period 净销售数量 ──
VAR __Numerator =
    CALCULATE(
        SUM('s02_trade_sku_data_d'[product_qty]),
        's02_trade_sku_data_d'[dt] >= __PeriodMin,
        's02_trade_sku_data_d'[dt] <= __PeriodMax
    )

// ── 分母：全量 color This Period 净销售数量 ──
// REMOVEFILTERS(color_name) 上卷至全量，保留外部切片器筛选
VAR __Denominator =
    CALCULATE(
        SUM('s02_trade_sku_data_d'[product_qty]),
        REMOVEFILTERS('s02_trade_sku_data_d'[color_name]),
        's02_trade_sku_data_d'[dt] >= __PeriodMin,
        's02_trade_sku_data_d'[dt] <= __PeriodMax
    )

RETURN
    DIVIDE(__Numerator, __Denominator)
```

### 4.7 Top Color Inventory EOH Amt Value（当期期末库存金额）

```dax
Top Color Inventory EOH Amt Value =
// ========================================
// 度量值: Top Color Inventory EOH Amt Value
// 中文名: 当期期末库存金额（当前币种）
// Display Folder: Top Color Sales Performance\Base Metrics
// 用途: 该 color This Period 最后一天期末库存金额（时点数），用于表格展示排序依据与交叉验证
// 依赖: Slicer_Time_Frame_Max_This[TimeFrame_Min] / [TimeFrame_Max]
//       Slicer_Currency_Selection[Currency_ExchangeRate]
// 口径: 时间范围看 this period 最后一天；该 color 下 sum(msrp_inv_amt)
// 数据底表: s02_inventory_stock_sales_detail_d
// 币种: 数据底表仅存 RMB，Value 层换算为当前币种金额（原始值 ÷ 汇率）；
//       排序不受币种选择影响（除以同一正汇率不改变 color 间相对大小）
// 说明: inv 表无 platform / shop_name 字段，不受渠道筛选影响（口径限制见注意事项 1）
// ========================================

// ── End Period 时间范围（期末时点类）──
VAR __EndPeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Min])
VAR __EndPeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

// ── 期末日期：end period 最后一天 = Max_This 表 TimeFrame_Max（直接单日过滤）──
VAR __EndPeriodDate = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

// ── 币种汇率（RMB = 1；USD 动态取自数仓汇率表）──
VAR __ExchangeRate = SELECTEDVALUE(Slicer_Currency_Selection[Currency_ExchangeRate], 1)

// ── 该 color 期末库存金额（原始 RMB，期末快照日单日值）──
VAR __BaseValue =
    CALCULATE(
        SUM('s02_inventory_stock_sales_detail_d'[msrp_inv_amt]),
        's02_inventory_stock_sales_detail_d'[dt] = __EndPeriodDate
    )

RETURN
    DIVIDE(__BaseValue, __ExchangeRate)   // BLANK ÷ 汇率 = BLANK（快照日无库存数据行返回空）
```

### 4.8 Top Color Inventory EOH Amt% Value（当期期末库存金额占比）

```dax
Top Color Inventory EOH Amt% Value =
// ========================================
// 度量值: Top Color Inventory EOH Amt% Value
// 中文名: 当期期末库存金额占比
// Display Folder: Top Color Sales Performance\Base Metrics
// 用途: 该 color 占 total 的期末库存金额比例（时点数）
// 依赖: Slicer_Time_Frame_Max_This[TimeFrame_Min] / [TimeFrame_Max]
// 口径: 分子：该 color 下 sum(msrp_inv_amt)；分母：全量 color 下 sum(msrp_inv_amt)；
//       时间范围看 this period 最后一天（实现为 end period 范围内最后一个快照日）
// 数据底表: s02_inventory_stock_sales_detail_d
// 说明: 分母为全量 color 汇总（含 Top10 之外颜色的金额）；分子分母均为原始 RMB 聚合，
//       占比不受币种选择影响；inv 表无渠道字段，指标不受渠道筛选影响（见注意事项 1）；
//       拓展为 Top10 color 集合分母的修改方式见 §9
// ========================================

// ── End Period 时间范围（期末时点类）──
VAR __EndPeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Min])
VAR __EndPeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

// ── 期末日期：end period 最后一天 = Max_This 表 TimeFrame_Max（直接单日过滤）──
VAR __EndPeriodDate = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

// ── 分子：当前行 color 期末库存金额（期末快照日单日值）──
VAR __Numerator =
    CALCULATE(
        SUM('s02_inventory_stock_sales_detail_d'[msrp_inv_amt]),
        's02_inventory_stock_sales_detail_d'[dt] = __EndPeriodDate
    )

// ── 分母：全量 color 期末库存金额 ──
// REMOVEFILTERS(color_name) 移除 color 行筛选与视觉级 Top10 筛选落地筛选，保留 Division 外部筛选
VAR __Denominator =
    CALCULATE(
        SUM('s02_inventory_stock_sales_detail_d'[msrp_inv_amt]),
        REMOVEFILTERS('s02_inventory_stock_sales_detail_d'[color_name]),
        's02_inventory_stock_sales_detail_d'[dt] = __EndPeriodDate
    )

RETURN
    DIVIDE(__Numerator, __Denominator)
```

### 4.9 Top Color Inventory EOH Unit Value（当期期末库存数量）

```dax
Top Color Inventory EOH Unit Value =
// ========================================
// 度量值: Top Color Inventory EOH Unit Value
// 中文名: 当期期末库存数量
// Display Folder: Top Color Sales Performance\Base Metrics
// 用途: 该 color This Period 最后一天期末库存数量（时点数）
// 依赖: Slicer_Time_Frame_Max_This[TimeFrame_Min] / [TimeFrame_Max]
// 口径: 时间范围看 this period 最后一天；该 color 下 sum(stock_inv_qty)
// 数据底表: s02_inventory_stock_sales_detail_d
// 说明: stock_inv_qty 为在库库存数量口径字段；数量类不涉及币种换算；
//       inv 表无渠道字段，指标不受渠道筛选影响（见注意事项 1）
// ========================================

// ── End Period 时间范围（期末时点类）──
VAR __EndPeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Min])
VAR __EndPeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

// ── 期末日期：end period 最后一天 = Max_This 表 TimeFrame_Max（直接单日过滤）──
VAR __EndPeriodDate = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

RETURN
    CALCULATE(
        SUM('s02_inventory_stock_sales_detail_d'[stock_inv_qty]),
        's02_inventory_stock_sales_detail_d'[dt] = __EndPeriodDate
    )
```

### 4.10 Top Color Inventory EOH Unit% Value（当期期末库存数量占比）

```dax
Top Color Inventory EOH Unit% Value =
// ========================================
// 度量值: Top Color Inventory EOH Unit% Value
// 中文名: 当期期末库存数量占比
// Display Folder: Top Color Sales Performance\Base Metrics
// 用途: 该 color 占 total 的期末库存数量比例（时点数）
// 依赖: Slicer_Time_Frame_Max_This[TimeFrame_Min] / [TimeFrame_Max]
// 口径: 分子：该 color 下 sum(stock_inv_qty)；分母：全量 color 下 sum(stock_inv_qty)；
//       时间范围看 this period 最后一天（实现为 end period 范围内最后一个快照日）
// 数据底表: s02_inventory_stock_sales_detail_d
// 说明: 分母为全量 color 汇总（含 Top10 之外颜色的数量），机制同 EOH Amt% Value；
//       inv 表无渠道字段，指标不受渠道筛选影响（见注意事项 1）
// ========================================

// ── End Period 时间范围（期末时点类）──
VAR __EndPeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Min])
VAR __EndPeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

// ── 期末日期：end period 最后一天 = Max_This 表 TimeFrame_Max（直接单日过滤）──
VAR __EndPeriodDate = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

// ── 分子：当前行 color 期末库存数量（期末快照日单日值）──
VAR __Numerator =
    CALCULATE(
        SUM('s02_inventory_stock_sales_detail_d'[stock_inv_qty]),
        's02_inventory_stock_sales_detail_d'[dt] = __EndPeriodDate
    )

// ── 分母：全量 color 期末库存数量 ──
// REMOVEFILTERS(color_name) 上卷至全量，保留 Division 外部筛选
VAR __Denominator =
    CALCULATE(
        SUM('s02_inventory_stock_sales_detail_d'[stock_inv_qty]),
        REMOVEFILTERS('s02_inventory_stock_sales_detail_d'[color_name]),
        's02_inventory_stock_sales_detail_d'[dt] = __EndPeriodDate
    )

RETURN
    DIVIDE(__Numerator, __Denominator)
```

### 4.11 Top Color Sales SLS Amt Display（当期净销售金额显示）

```dax
Top Color Sales SLS Amt Display =
// ========================================
// 度量值: Top Color Sales SLS Amt Display
// 中文名: 当期净销售金额显示
// Display Folder: Top Color Sales Performance\Formatting
// 用途: currency 格式化（币种符号 + 千分位整数，符号由币种切片器决定）；BLANK 显示 "-"
// 依赖: [Top Color Sales SLS Amt Value], Slicer_Currency_Selection[Currency_Symbol]
// 数据格式: 币种符号 & #,##0（如 ¥1,000 / $1,000）
// ========================================
    VAR __Value = [Top Color Sales SLS Amt Value]
    VAR __CurrencySymbol = SELECTEDVALUE(Slicer_Currency_Selection[Currency_Symbol], "¥")
    RETURN
        IF(
            ISBLANK(__Value),
    // 该行所有度量均为 BLANK() 时，通常会自动隐藏该行（包括层级行），需要所有指标都为 BLANK() 才会自动隐藏该行。
            BLANK(),
            __CurrencySymbol & FORMAT(__Value, "#,##0")
        )
```

### 4.12 Top Color Sales SLS Amt% Display（当期销售金额占比显示）

```dax
Top Color Sales SLS Amt% Display =
// ========================================
// 度量值: Top Color Sales SLS Amt% Display
// 中文名: 当期销售金额占比显示
// Display Folder: Top Color Sales Performance\Formatting
// 用途: percent_0dp 格式化（百分比整数，不含正号）；BLANK 显示 "-"
// 依赖: [Top Color Sales SLS Amt% Value]
// 数据格式: #,##0%（如 26%）
// ========================================
    VAR __Value = [Top Color Sales SLS Amt% Value]
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            FORMAT(__Value, "#,##0%")
        )
```

### 4.13 Top Color Sales SLS Unit Display（当期净销售数量显示）

```dax
Top Color Sales SLS Unit Display =
// ========================================
// 度量值: Top Color Sales SLS Unit Display
// 中文名: 当期净销售数量显示
// Display Folder: Top Color Sales Performance\Formatting
// 用途: integer 格式化（整数千分位）；BLANK 显示 "-"
// 依赖: [Top Color Sales SLS Unit Value]
// 数据格式: #,##0（如 1,234）
// ========================================
    VAR __Value = [Top Color Sales SLS Unit Value]
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            FORMAT(__Value, "#,##0")
        )
```

### 4.14 Top Color Sales SLS Unit% Display（当期净销售数量占比显示）

```dax
Top Color Sales SLS Unit% Display =
// ========================================
// 度量值: Top Color Sales SLS Unit% Display
// 中文名: 当期净销售数量占比显示
// Display Folder: Top Color Sales Performance\Formatting
// 用途: percent_0dp 格式化（百分比整数，不含正号）；BLANK 显示 "-"
// 依赖: [Top Color Sales SLS Unit% Value]
// 数据格式: #,##0%（如 26%）
// ========================================
    VAR __Value = [Top Color Sales SLS Unit% Value]
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            FORMAT(__Value, "#,##0%")
        )
```

### 4.15 Top Color Inventory EOH Amt Display（当期期末库存金额显示）

```dax
Top Color Inventory EOH Amt Display =
// ========================================
// 度量值: Top Color Inventory EOH Amt Display
// 中文名: 当期期末库存金额显示
// Display Folder: Top Color Sales Performance\Formatting
// 用途: currency 格式化（币种符号 + 千分位整数，符号由币种切片器决定）；BLANK 显示 "-"
// 依赖: [Top Color Inventory EOH Amt Value], Slicer_Currency_Selection[Currency_Symbol]
// 数据格式: 币种符号 & #,##0（如 ¥3,160 / $3,160）
// ========================================
    VAR __Value = [Top Color Inventory EOH Amt Value]
    VAR __CurrencySymbol = SELECTEDVALUE(Slicer_Currency_Selection[Currency_Symbol], "¥")
    RETURN
        IF(
            ISBLANK(__Value),
    // 该行所有度量均为 BLANK() 时，通常会自动隐藏该行（包括层级行），需要所有指标都为 BLANK() 才会自动隐藏该行。
            BLANK(),
            __CurrencySymbol & FORMAT(__Value, "#,##0")
        )
```

### 4.16 Top Color Inventory EOH Amt% Display（当期期末库存金额占比显示）

```dax
Top Color Inventory EOH Amt% Display =
// ========================================
// 度量值: Top Color Inventory EOH Amt% Display
// 中文名: 当期期末库存金额占比显示
// Display Folder: Top Color Sales Performance\Formatting
// 用途: percent_0dp 格式化（百分比整数，不含正号）；BLANK 显示 "-"
// 依赖: [Top Color Inventory EOH Amt% Value]
// 数据格式: #,##0%（如 26%）
// ========================================
    VAR __Value = [Top Color Inventory EOH Amt% Value]
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            FORMAT(__Value, "#,##0%")
        )
```

### 4.17 Top Color Inventory EOH Unit Display（当期期末库存数量显示）

```dax
Top Color Inventory EOH Unit Display =
// ========================================
// 度量值: Top Color Inventory EOH Unit Display
// 中文名: 当期期末库存数量显示
// Display Folder: Top Color Sales Performance\Formatting
// 用途: integer 格式化（整数千分位）；BLANK 显示 "-"
// 依赖: [Top Color Inventory EOH Unit Value]
// 数据格式: #,##0（如 3,160）
// ========================================
    VAR __Value = [Top Color Inventory EOH Unit Value]
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            FORMAT(__Value, "#,##0")
        )
```

### 4.18 Top Color Inventory EOH Unit% Display（当期期末库存数量占比显示）

```dax
Top Color Inventory EOH Unit% Display =
// ========================================
// 度量值: Top Color Inventory EOH Unit% Display
// 中文名: 当期期末库存数量占比显示
// Display Folder: Top Color Sales Performance\Formatting
// 用途: percent_0dp 格式化（百分比整数，不含正号）；BLANK 显示 "-"
// 依赖: [Top Color Inventory EOH Unit% Value]
// 数据格式: #,##0%（如 26%）
// ========================================
    VAR __Value = [Top Color Inventory EOH Unit% Value]
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            FORMAT(__Value, "#,##0%")
        )
```

### 4.19 动态文本_Division（用于页面文本提示）

```dax
动态文本_Division = 
SELECTEDVALUE('Slicer_Division'[division],"切片器和按钮交集为空！")
```

---

## 5. 度量值清单与 Display Folder

| 序号 | 度量值名称                            | Display Folder | 模型格式      | 用途                                                     |
| ---- | ------------------------------------- | -------------- | ------------- | -------------------------------------------------------- |
| 1    | Top Color Sales Color Rank            | Rank           | 整数          | Sales Top10 排名（金额降序 + 名称决胜，筛选 + 排序）     |
| 2    | Top Color Inventory Color Rank        | Rank           | 整数          | Inventory Top10 排名（金额降序 + 名称决胜，筛选 + 排序） |
| 3    | Top Color Sales SLS Amt Value         | Base Metrics   | 数值          | 当期净销售金额（当前币种，验证用）                       |
| 4    | Top Color Sales SLS Amt% Value        | Base Metrics   | 百分比 #,##0% | 当期销售金额占比（全量分母）                             |
| 5    | Top Color Sales SLS Unit Value        | Base Metrics   | 整数 #,##0    | 当期净销售数量                                           |
| 6    | Top Color Sales SLS Unit% Value       | Base Metrics   | 百分比 #,##0% | 当期净销售数量占比（全量分母）                           |
| 7    | Top Color Inventory EOH Amt Value     | Base Metrics   | 数值          | 当期期末库存金额（当前币种，验证用）                     |
| 8    | Top Color Inventory EOH Amt% Value    | Base Metrics   | 百分比 #,##0% | 当期期末库存金额占比（全量分母）                         |
| 9    | Top Color Inventory EOH Unit Value    | Base Metrics   | 整数 #,##0    | 当期期末库存数量                                         |
| 10   | Top Color Inventory EOH Unit% Value   | Base Metrics   | 百分比 #,##0% | 当期期末库存数量占比（全量分母）                         |
| 11   | Top Color Sales SLS Amt Display       | Formatting     | 文本          | SLS Amt 格式化显示（币种符号 + 千分位整数）              |
| 12   | Top Color Sales SLS Amt% Display      | Formatting     | 文本          | SLS Amt% 格式化显示（百分比整数）                        |
| 13   | Top Color Sales SLS Unit Display      | Formatting     | 文本          | SLS Unit 格式化显示（整数千分位）                        |
| 14   | Top Color Sales SLS Unit% Display     | Formatting     | 文本          | SLS Unit% 格式化显示（百分比整数）                       |
| 15   | Top Color Inventory EOH Amt Display   | Formatting     | 文本          | EOH Amt 格式化显示（币种符号 + 千分位整数）              |
| 16   | Top Color Inventory EOH Amt% Display  | Formatting     | 文本          | EOH Amt% 格式化显示（百分比整数）                        |
| 17   | Top Color Inventory EOH Unit Display  | Formatting     | 文本          | EOH Unit 格式化显示（整数千分位）                        |
| 18   | Top Color Inventory EOH Unit% Display | Formatting     | 文本          | EOH Unit% 格式化显示（百分比整数）                       |

> 表格视觉对象值区域的绑定选择见 §7：四列指标绑定 Display（文本格式化统一，金额列含动态币种符号），排序依据 Rank 置于最后一列并收窄列宽；如需为占比 / 数量列配置数据条，可整体改绑对应 Value 度量并设置列格式（数值格式支持数据条，文本格式不支持）。

---

## 6. 血缘关系图

```
┌─────────────────────────────────────────────────────────────────────┐
│                        数据源层                                      │
│  s02_trade_sku_data_d（销售类，dt 日粒度）                            │
│  字段: dt, platform, shop_name, division, color_name,                │
│        product_qty, net_sales_amt                                    │
│        （net_sales_amt = ROUND(product_qty × sales_price, 6)，       │
│          Power Query 取数新增列）                                     │
│  s02_inventory_stock_sales_detail_d（库存类，dt 日快照）              │
│  字段: dt, division, color_name, msrp_inv_amt, stock_inv_qty         │
│        （无 platform / shop_name）                                    │
└──────────────────────────────────┬──────────────────────────────────┘
│ Platform / Store Name / Division 一对多关联自动传递（无需 DAX）
▼
┌─────────────────────────────────────────────────────────────────────┐
│                        度量值层                                      │
│  ┌────────────────────────────┐  ┌────────────────────────────┐     │
│  │ Top Color Sales            │  │ Top Color Inventory        │     │
│  │ Color Rank                 │  │ Color Rank                 │     │
│  │ (This Period 区间净销售    │  │ (This Period 期末库存金额  │     │
│  │  名称决胜排名)             │  │  名称决胜排名)             │     │
│  └─────────────┬──────────────┘  └─────────────┬──────────────┘     │
│                │ 视觉级筛选器 介于 1 与 10      │                    │
│                ▼                                 ▼                   │
│  ┌────────────────────────────┐  ┌────────────────────────────┐     │
│  │ SLS Amt / SLS Amt% /       │  │ EOH Amt / EOH Amt% /       │     │
│  │ SLS Unit / SLS Unit%       │  │ EOH Unit / EOH Unit%       │     │
│  │ Value                      │  │ Value                      │     │
│  │ (占比分母 REMOVEFILTERS(    │  │ (期末快照日单日时点 +      │     │
│  │  color_name) 上卷全量；     │  │  占比分母 REMOVEFILTERS(    │     │
│  │  金额类 Value 层汇率换算)   │  │  color_name) 上卷全量)     │     │
│  └─────────────┬──────────────┘  └─────────────┬──────────────┘     │
│                ▼                                 ▼                   │
│  ┌────────────────────────────┐  ┌────────────────────────────┐     │
│  │ 四列 Display               │  │ 四列 Display               │     │
│  │ (currency / integer /      │  │ (currency / integer /      │     │
│  │  percent_0dp 格式化)       │  │  percent_0dp 格式化)       │     │
│  └────────────────────────────┘  └────────────────────────────┘     │
│        ▲ Slicer_Time_Frame_Min_This / Max_This（断开维度，            │
│          DAX 显式时间筛选）                                           │
│        ▲ Slicer_Currency_Selection（币种符号 + 汇率）                 │
└─────────────────────────────────────────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────────┐
│                        可视化层（表格 × 2）                           │
│  Sales 表格:                                                         │
│    行: s02_trade_sku_data_d[color_name]                              │
│    值: SLS Amt / SLS Amt% / SLS Unit / SLS Unit% Display             │
│        + Color Rank（排序依据，升序）                                 │
│    视觉级筛选: Color Rank 介于 1 与 10 且 SLS Amt Value 不为空        │
│  Inventory 表格:                                                     │
│    行: s02_inventory_stock_sales_detail_d[color_name]                │
│    值: EOH Amt / EOH Amt% / EOH Unit / EOH Unit% Display             │
│        + Color Rank（排序依据，升序）                                 │
│    视觉级筛选: Color Rank 介于 1 与 10 且 EOH Amt Value 不为空        │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 7. 表格视觉对象配置

### 7.1 Sales 表格

| 配置项       | 内容                                                                            |
| ------------ | ------------------------------------------------------------------------------- |
| 行字段       | s02_trade_sku_data_d[color_name]（行粒度为 color）                              |
| 值 1         | [Top Color Sales SLS Amt Display]（文本：币种符号 + 千分位整数）                |
| 值 2         | [Top Color Sales SLS Amt% Display]（文本：百分比整数）                          |
| 值 3         | [Top Color Sales SLS Unit Display]（文本：整数千分位）                          |
| 值 4         | [Top Color Sales SLS Unit% Display]（文本：百分比整数）                         |
| 值 5         | [Top Color Sales Color Rank]（排序依据列，置于最后一列并收窄列宽）              |
| 排序         | 点击 Color Rank 列标题按升序排序（行序 = 当期净销售金额降序 + 名称字母序决胜）  |
| 视觉级筛选器 | [Top Color Sales Color Rank] 介于 1 与 10（含边界）                             |
| 视觉级筛选器 | [Top Color Sales SLS Amt Value] 不为空（排除当期无销售数据的 color 行，双保险） |
| 显示元素     | 关闭总计                                                                        |

### 7.2 Inventory 表格

| 配置项       | 内容                                                                                  |
| ------------ | ------------------------------------------------------------------------------------- |
| 行字段       | s02_inventory_stock_sales_detail_d[color_name]（行粒度为 color）                      |
| 值 1         | [Top Color Inventory EOH Amt Display]（文本：币种符号 + 千分位整数）                  |
| 值 2         | [Top Color Inventory EOH Amt% Display]（文本：百分比整数）                            |
| 值 3         | [Top Color Inventory EOH Unit Display]（文本：整数千分位）                            |
| 值 4         | [Top Color Inventory EOH Unit% Display]（文本：百分比整数）                           |
| 值 5         | [Top Color Inventory Color Rank]（排序依据列，置于最后一列并收窄列宽）                |
| 排序         | 点击 Color Rank 列标题按升序排序（行序 = 期末库存金额降序 + 名称字母序决胜）          |
| 视觉级筛选器 | [Top Color Inventory Color Rank] 介于 1 与 10（含边界）                               |
| 视觉级筛选器 | [Top Color Inventory EOH Amt Value] 不为空（排除快照日无库存数据的 color 行，双保险） |
| 显示元素     | 关闭总计                                                                              |

### 7.3 绑定与排序说明

- 四列指标绑定 Display 度量（文本）：金额列含动态币种符号（列静态格式无法实现运行时符号切换，必须在 Display 层拼接）；BLANK 统一显示 "-"
- 排序依据 Rank 列必须位于值区域才能作为排序依据（无法隐藏，建议置于最后一列并收窄列宽）；Rank 名次严格唯一连续（金额降序 + 名称字母序决胜），升序行序与主指标降序完全一致且金额并列行序确定；如需按当前币种金额排序可改用 Value 列降序（金额完全相等的行序以表格呈现为准，确定性不如 Rank 升序）
- 如需为 SLS Amt% / SLS Unit% / EOH Amt% / EOH Unit% 列配置条件格式数据条，需改绑对应 Value 度量并设置列格式（数据条仅支持数值绑定；两表数据条最小值统一固定为 0，保证两表条长在同一标尺下可比）

---

## 8. 注意事项

1. **inv 表无渠道字段**：s02_inventory_stock_sales_detail_d 无 platform / shop_name 字段，Inventory 全部指标（EOH Amt / EOH Amt% / EOH Unit / EOH Unit%）与 Inventory Top10 排名不受 Platform / Store Name 筛选影响，仅受 date + Division 影响；Sales 全部指标受 date + Platform + Store Name + Division 四组筛选影响。该口径限制已与业务确认。
2. **期末时点只取单日**：EOH 系列指标取 end period 范围内最后一个快照日的单日值；快照表按日存储，对整段区间求和会把库存重复计数。快照缺数时在 end period 窗口内自动回退到最近一天（口径定义为 this period 最后一天）。
3. **快照日 REMOVEFILTERS 机制**：__EndPeriodDate 用 // ── 期末日期：end period 最后一天 = Max_This 表 TimeFrame_Max（直接单日过滤）──
VAR __EndPeriodDate = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])
4. **Top10 排名的筛选范围**：Rank 度量值中 ALL(color_name) 仅移除 color 列筛选，Platform / Store Name（Sales 侧）/ Division 筛选保留，排名是当前筛选组合下的排名；空白与空字符 color_name（数据中 NULL 与 "" 并存）在度量值内部用 LEN(TRIM()) > 0 排除，不参与排名。注意：视觉级 color_name 列筛选器会被候选集的 ALL(color_name) 移除而无法影响排名，空白排除必须在度量值内部实现。
5. **名称决胜的排名语义**：RANK 的 ORDERBY 以金额降序为第一序、color_name 字母序升序为第二序——金额相同的 color 因名称不同而名次相邻不并列（金额 [100, 95, 95, 90] → 排名 [1, 2, 3, 4]），名次严格连续唯一；只有金额与 color_name 都相同才会共享名次（color_name 唯一时不存在），「Rank 介于 1 与 10」恒放行恰好 10 行、Top10 边界确定。金额展示值经四舍五入，肉眼相同不代表底层并列；名称决胜使名次与行序不依赖底层是否真并列（DENSE 保证连续不跳号，元组唯一时名次即排序位置）。
6. **占比分母为全量**：Amt% / Unit% 分母经 REMOVEFILTERS(color_name) 上卷至全部 color（含 Top10 之外颜色、含空白 color_name 记录的金额/数量），Top10 行占比加总小于 100%；占比基数不随 Top10 行筛选与币种选择变化。拓展为 Top10 color 集合分母的修改方式见 §9。
7. **视觉级筛选器配置边界**：Rank 筛选器必须配置「介于 1 与 10」（含下界）；Rank 度量对空白 / 空字符 / 当期无金额的 color 返回 BLANK，数值筛选「介于」对 BLANK 判定为不在区间内（BLANK 视为 0）自动排除，仅配「小于或等于 10」会把 BLANK 行放行。筛选器对 Rank 的取值发生在筛选生效前（真实排名），行按真实排名保留。
8. **Rank 显示值验证**：视觉级筛选器对 Rank 的取值发生在筛选生效前（真实排名），行按真实名次保留。拖入表格验证显示值时，RANK 的 relation 为 ALL(color_name)（移除 color 列全部筛选，含视觉级落地筛选），ORDERBY 表达式的上下文转换以候选 color 覆盖当前行 color 筛选（表格行维度仅 color 一列，同列覆盖有效），显示值应为真实排名；若发现显示值异常（如恒为 1、普遍偏小），应检查视觉上是否叠加了其他多列组合筛选——跨列组合筛选无法被单列上下文转换清除，会使候选金额取 BLANK、排名失真。Rank 兼任行排序依据列（值区域最后一列收窄，点击升序）。
9. **行排序**：行序由值区域的 SLS Amt Value / EOH Amt Value 列降序控制（点击列标题）；金额完全相等的并列行共享 DENSE 排名，表格内行序以呈现为准。如需业务固定颜色顺序（如固定色系排序），需在 Power Query 为 color_name 生成排序列并改按该列排序。
10. **日期筛选器依赖**：SELECTEDVALUE(Slicer_Time_Frame_Min_This[TimeFrame_Min]) 等依赖日期切片器保持单选且必选；切片器未选或多选时时间边界为 BLANK，指标不可用（与看板既有日期筛选器使用方式一致）。
11. **币种换算层次**：金额类 Value 层输出当前币种金额（原始 RMB ÷ Currency_ExchangeRate），Display 层仅拼接币种符号；占比类 Value 分子分母均为原始 RMB 聚合（不经换算），占比不受币种选择影响。数据源仅存储 RMB，USD 汇率动态取自数仓 dim_t00_currency 表（随数据刷新自动更新）。
12. **DIVIDE 空值保护**：占比分母（全量金额/数量汇总）为空或 0 时 DIVIDE 返回 BLANK，显示 "-"；金额 / 数量类 Value 在对应期间（或快照日）无记录时 SUM 返回 BLANK，显示 "-"。
13. **DAX 语法规范**：文本常量使用双引号，单引号仅用于表名，列名使用方括号；与口径文档存在争议时一切以口径文档为准。
14. **SLS Unit% 分母口径修正记录**：口径文档原文分母为 sum(sales_qty)（该字段在 s02_trade_sku_data_d 数据字典与取数 SQL 中均不存在），经业务确认修正为 sum(product_qty)（与分子同字段，全部 color 占比加总 = 100%，2026-10-15 确认）；口径文档后续如更新字段定义，以更新后口径为准。
15. **RANK 窗口函数版本要求与无金额候选排除**：RANK / ORDERBY 为 Power BI Desktop 2022 年 9 月引入的新版窗口函数，旧版本不可用；RANK 无 value 参数，当前行经 ORDERBY 中的 relation 列（color_name）与 relation 行匹配确定名次。relation 同时排除空白 / 空字符与当期无金额的 color——无金额候选不占名次，避免其排序位置（BLANK 在 ORDERBY 中的默认排序方向随引擎实现）使有效 color 名次整体偏移、导致「介于 1 与 10」误排；当前行为空白 / 无金额时 relation 无匹配行且外层 IF 显式拦截，返回 BLANK 被筛选器排除（双保险）。

---

## 9. 拓展说明：占比分母改为 Top10 color 集合

当前占比（SLS Amt% / SLS Unit% / EOH Amt% / EOH Unit%）分母为全量 color 汇总，Top10 行占比加总小于 100%。如需改为「Top10 color 集合内占比」（Top10 行占比加总 = 100%），将对应占比度量的分母替换为 Top10 集合限定版本（以 Top Color Sales SLS Amt% Value 为例）：

```dax
// ── 拓展版分母：仅汇总 Top10 color 集合的 This Period 净销售金额 ──
// __Top10Colors 在 REMOVEFILTERS(color_name) 上下文中逐 color 评估 Rank
// （FILTER 行上下文中度量值引用自动发生上下文转换），判定与视觉级
// 「Rank 介于 1 与 10」筛选器同源，保证分子分母基于同一 Top10 集合
VAR __Top10Colors =
    CALCULATETABLE(
        FILTER(
            VALUES('s02_trade_sku_data_d'[color_name]),
            [Top Color Sales Color Rank] >= 1
                && [Top Color Sales Color Rank] <= 10
        ),
        REMOVEFILTERS('s02_trade_sku_data_d'[color_name])
    )

VAR __Denominator =
    CALCULATE(
        SUM('s02_trade_sku_data_d'[net_sales_amt]),
        REMOVEFILTERS('s02_trade_sku_data_d'[color_name]),   // 先上卷至全量，再以 __Top10Colors 限定回 Top10
        __Top10Colors,
        's02_trade_sku_data_d'[dt] >= __PeriodMin,
        's02_trade_sku_data_d'[dt] <= __PeriodMax
    )
```

修改要点：

- 仅替换分母 VAR，分子与其余逻辑不变；SLS Unit% 替换聚合字段为 `SUM(product_qty)`，EOH Amt% / EOH Unit% 替换底表为 `s02_inventory_stock_sales_detail_d`（聚合字段 `SUM(msrp_inv_amt)` / `SUM(stock_inv_qty)`，时间筛选为 `dt = __EndPeriodDate`）并同步替换 Rank 引用为 [Top Color Inventory Color Rank]
- __Top10Colors 的 Rank 判定与视觉级筛选器同源（同一度量值、同一区间），分子分母基于同一集合，修改后 Top10 行占比加总 = 100%（分母 = Top10 行金额/数量之和）
- 名称决胜下 Top10 集合恒为 10 行（名次唯一连续），分母覆盖该 10 行的金额 / 数量之和，占比加总 = 100%
- 拓展实施时建议同步更新口径文档中对应指标的「计算公式」描述（分母由全量改为 Top10 color 集合），保持口径与实现一致
