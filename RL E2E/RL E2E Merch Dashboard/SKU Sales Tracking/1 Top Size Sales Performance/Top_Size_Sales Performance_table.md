# Top Size Sales Performance 表格解决方案

> **版本**: v1.0
> **模块**: RL E2E Merch Dashboard - SKU Sales Tracking Tab - Top Size Sales Performance
> **关联口径**: 口径文档/口径Markdown格式/SKU Sales Tracking.md - 子模块一【Sales】（§1）+ 子模块二【Inventory】（§2）
> **数据底表（销售类）**: s02_trade_sku_data_d
> **数据底表（库存类）**: s02_inventory_stock_sales_detail_d
> **关联维度**: Slicer_Time_Frame_Min_This / Max_This / Min_Last / Max_Last（时间，断开维度）
> **筛选影响范围**: date + Platform + Store Name + Division（其余商品维度切片器对图表的筛选在页面编辑交互中取消）

---

## 1. 需求理解

### 1.1 模块定位

Top Size Sales Performance 是 SKU Sales Tracking Tab 的第一个子模块，展示销售金额 / 期末库存金额视角下 Top4 category 的尺码（size）结构占比：

- **Sales 视图**（4 个并排表格）：Top4 category 按 This Period `sum(net_sales_amt)` 排序，每个表格展示该 category 下 SLS Amt% / LP SLS Amt% / vs LP 三列指标
- **Inventory 视图**（4 个并排表格）：Top4 category 按 This Period 最后一天 `sum(msrp_inv_amt)` 排序，每个表格展示该 category 下 EOH Amt% / LP EOH Amt% / vs LP 三列指标
- Sales 与 Inventory 视图通过按钮 + 书签控制两套表格的显示 / 隐藏（显隐切换由页面书签实现，不在本方案度量值范围内）

### 1.2 行维度与 Top4 机制

| 层级 | 字段          | Sales 表格来源                          | Inventory 表格来源                                    |
| ---- | ------------- | --------------------------------------- | ----------------------------------------------------- |
| 1    | Category      | s02_trade_sku_data_d[category]          | s02_inventory_stock_sales_detail_d[category]          |
| 2    | Size Category | s02_trade_sku_data_d[sku_size_category] | s02_inventory_stock_sales_detail_d[sku_size_category] |
| 3    | Size          | s02_trade_sku_data_d[sku_size]          | s02_inventory_stock_sales_detail_d[sku_size]          |

- **Sales Top4**：date + Platform + Store Name + Division 筛选组合下，按 category 粒度 This Period `sum(net_sales_amt)` 降序取前 4
- **Inventory Top4**：date + Division 筛选组合下，按 category 粒度 This Period 最后一天 `sum(msrp_inv_amt)` 降序取前 4
- 表格 1 = Top1 category，表格 2 = Top2 category，依次类推；通过表格视觉级筛选器（Rank 度量值 = N）实现

### 1.3 指标清单

| 视图      | 指标        | 计算公式                                                                                                                       | 时间口径                     | 数据类型 / 格式                       |
| --------- | ----------- | ------------------------------------------------------------------------------------------------------------------------------ | ---------------------------- | ------------------------------------- |
| Sales     | SLS Amt%    | 分子：该 category + size category + size 下`sum(net_sales_amt)`；分母：该 category + size category 下 `sum(net_sales_amt)` | This Period（区间）          | percent_0dp →`#,##0%`              |
| Sales     | LP SLS Amt% | 分子同 SLS Amt%（last period）；分母：该 category + size category 层级 last period 汇总，且仅含 This Period 有销售金额的 size（可见 size 集合）                                                                                        | Last Period（区间）          | percent_0dp →`#,##0%`              |
| Sales     | vs LP       | SLS Amt% - LP SLS Amt%（差值，展示时 ×10000 转 bp）                                                                           | —                           | integer_bp →`#,##0bp;-#,##0bp;0bp` |
| Inventory | EOH Amt%    | 分子：该 category + size category + size 下`sum(msrp_inv_amt)`；分母：该 category + size category 下 `sum(msrp_inv_amt)`   | This Period 最后一天（时点） | percent_0dp →`#,##0%`              |
| Inventory | LP EOH Amt% | 分子同 EOH Amt%（last period 最后一天）；分母：该 category + size category 层级 last period 最后一天汇总，且仅含 This Period 有库存金额的 size（可见 size 集合）                                                          | Last Period 最后一天（时点） | percent_0dp →`#,##0%`              |
| Inventory | vs LP       | EOH Amt% - LP EOH Amt%（差值，展示时 ×10000 转 bp）                                                                           | —                           | integer_bp →`#,##0bp;-#,##0bp;0bp` |

### 1.4 时间口径

| 口径                        | 时间范围                                                                                                                          | 适用指标                               |
| --------------------------- | --------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------- |
| This Period（区间类）       | dt ∈ [Slicer_Time_Frame_Min_This[TimeFrame_Min], Slicer_Time_Frame_Max_This[TimeFrame_Max]]                                      | SLS Amt% 分子分母、Sales Top4 排序     |
| Last Period（区间类）       | dt ∈ [Slicer_Time_Frame_Min_Last[TimeFrame_Min], Slicer_Time_Frame_Max_Last[TimeFrame_Max]]                                      | LP SLS Amt% 分子分母                   |
| End Period（期末时点类）    | end period 范围 [Slicer_Time_Frame_Max_This[TimeFrame_Min], Slicer_Time_Frame_Max_This[TimeFrame_Max]] 内**最后一个快照日** | EOH Amt% 分子分母、Inventory Top4 排序 |
| End Period LP（期末时点类） | end period 范围 [Slicer_Time_Frame_Max_Last[TimeFrame_Min], Slicer_Time_Frame_Max_Last[TimeFrame_Max]] 内**最后一个快照日** | LP EOH Amt% 分子分母                   |

说明：

- 没有特殊说明的情况下，计算 LY / LP 时使用 Last Period 特定筛选器的结果作为上期时间范围对比
- 期末时点口径实现为「end period 范围内最后一个有数据的快照日」：口径定义为 this period / last period 最后一天（两口径的最后一个自然日相同，均为所选最后一个周期的 TimeFrame_Max），快照缺数时自动回退到范围内最近一天，避免整段空值
- 快照表按日存储，期末时点**只取单日**，对 end period 整段区间求和会把库存重复计数

---

## 2. 现状分析

- 数据底表 `s02_trade_sku_data_d`（SKU 粒度交易表，dt 日粒度）：net_sales_amt 为 Power Query 取数时新增列（`ROUND(product_qty * sales_price, 6) AS net_sales_amt`），业务已确认；维度含 dt、platform、shop_name、division、category、sku_size_category、sku_size 及其余商品维度
- 数据底表 `s02_inventory_stock_sales_detail_d`（库存+销售+补货 SKU 模型表，dt 日快照）：msrp_inv_amt（吊牌库存金额）为期末库存金额口径字段；维度含 dt、division、category、sku_size_category、sku_size 等；**无 platform / shop_name 字段**（渠道筛选不影响库存侧指标，口径限制见注意事项）
- 模型关系：日期筛选器（Slicer_Time_Frame_Min_This / Max_This / Min_Last / Max_Last）为断开维度，时间范围在 DAX 中显式筛选，不依赖模型关系传递；Platform（Slicer_Platform_Selection）、Store Name（Slicer_Store_Name）、Division（Slicer_Division）与两张事实表一对多关联，筛选自动传递，DAX 无需显式处理
- 本模块指标均为占比 / 差值比率类，不涉及币种兑换
- 字段名已逐一核对数据字典（两表日期字段统一为 dt，date 类型）

---

## 3. 方案设计

### 3.1 度量值分层

```
Category Rank（视觉级筛选）
    ←  Top4 category 排名（Sales 按 This Period 区间净销售、Inventory 按 This Period 期末库存金额）
    ↓
Value（口径计算，保留小数原值）
    ←  分子 / 分母时间范围显式筛选 + 分母 REMOVEFILTERS(sku_size)
    ↓
Display（格式化显示）
    ←  percent_0dp: FORMAT(#,##0%)；integer_bp: ×10000 转 bp
```

### 3.2 Top4 行筛选机制

每个表格视觉对象配置两条视觉级筛选器（以 Sales 表格 1 为例）：

| 筛选器                        | 条件   | 作用                                                                 |
| ----------------------------- | ------ | -------------------------------------------------------------------- |
| Top Size Sales Category Rank  | 为 1   | 固定显示 Top1 category 的行（表格 2 为 2，依次类推）                 |
| Top Size Sales SLS Amt% Value | 不为空 | 仅显示 This Period 有销售数据的 category + size category + size 组合 |

（Inventory 表格对应使用 Top Size Inventory Category Rank 与 Top Size Inventory EOH Amt% Value）

Rank 度量值在 category / size category / size 任意层级行均返回所属 category 的排名：表格行字段为层级展开时，category 筛选在 size category 行与 size 行上依然存在，`SELECTEDVALUE(category)` 逐行可取值，保证 size 行同样被正确筛选。

### 3.3 占比口径分母层级

分母 = 该 category + size category 层级：分母计算中 `REMOVEFILTERS(sku_size)` 仅移除 size 行筛选，保留 category / size category 行筛选与外部切片器（Platform / Store Name / Division）筛选，分母与分子处于同一时间范围。

**LP 分母额外限定可见 size 集合**（2026-10-15 业务确认）：上期占比的分母在分组层级汇总后，仅统计「This Period 有金额的 size」（判定与视觉级「Value 不为空」筛选器一致）——当期空、上期有值行的上期金额不进入 LP 分母，使 LP 占比基数与当期占比同为显示行汇总，vs LP 差值两期基于同一尺码集合；当期占比无需同款限定（空行当期金额为 0，全量汇总与显示行汇总数值恒等）。

### 3.4 度量值命名与组织

- 命名规则：模块前缀 `Top Size` + 视图（Sales / Inventory）+ 指标名 + 层次后缀（Rank / Value / Display）
- Display Folder：`Top Size Sales Performance\Rank`、`Top Size Sales Performance\Base Metrics`、`Top Size Sales Performance\Formatting`
- 度量值统一存放于 `_Measures` 隐藏表（与看板既有组织方式一致）

### 3.5 行排序机制（排序键编码）

表格视觉对象仅支持单键排序（点击列标题按该列升/降序），四级行排序规则通过排序键度量编码为一个整数，表格按该键升序排序：

| 层级          | 规则                                                                                              | 编码贡献                        |
| ------------- | ------------------------------------------------------------------------------------------------- | ------------------------------- |
| L1 分组优先级 | sku_size_category 含"字母尺码" > 含"数字尺码" > 其余                                              | 优先级（0/1/2）× 1,000,000,000 |
| L2 分组顺序   | 同优先级内按分组当期金额（SLS Amt Value / EOH Amt Value 上卷至分组粒度）降序                      | 分组排名 × 1,000,000           |
| L3 组内顺序   | 分组内按占比值（SLS Amt% Value / EOH Amt% Value）升序；同一分组内分母相同，占比升序与金额升序等价；当期占比为空的行排在分组最后（空值垫底） | 组内排名 × 1,000               |
| L4 决胜顺序   | 按 sku_size 名称字典序升序（仅 L3 占比精确相等并列时生效，保证排序键全局唯一、行序确定）          | 决胜排名 × 1                   |

排序键 = L1 + L2 + L3 + L4，升序排序后行序为：字母尺码分组 → 数字尺码分组 → 其余分组（按分组当期金额降序），每个分组组内占比升序；占比精确相等并列的行按 sku_size 名称字典序升序决胜，行序确定。

**并列语义**：L3 为 RANKX 竞争排名（SKIP）——占比**精确相等**的行共享名次，其后名次跳号（并列第 3 则无第 4、直接第 5）；同分组分母相同，占比相等 ⟺ 当期金额分毫不差。占比展示值经四舍五入，肉眼相同不代表底层并列，判断是否真并列需查看未舍入的底层值。

**空值垫底（L3）**：当期占比为 BLANK（该组合当期无记录，显示 "-"）的行排在分组最后——升序 RANKX 中 BLANK 被计为更小值，若不处理会浮到组内最前；实现为候选 [@Pct] 与 value 参数双侧把 BLANK 映射为 1E15 哨兵值参与排名（仅作用于空值，不占正序名次，候选与 value 同构避免两阶段语义不一致）。注意区分两类"看起来像空"：真 BLANK（无记录）适用垫底；占比极小四舍五入显示 0% 的行为有值（如 0.4%），按真实值参与升序排序、不适用垫底（若需 0% 显示行也垫底，需另行确认阈值规则，如当前值 < 0.5% 视为有效零）。

**候选上下文净化（L2/L3）**：视觉级度量筛选器（Rank = N）生效后落地为对行组合的跨列组合筛选，单列 ALL/REMOVEFILTERS 无法清除，会污染候选迭代——曾致当前行自身的 size 候选在 RANKX 迭代阶段取 BLANK（FILTER 物化阶段非空、两阶段不一致），升序下被计入“小于当前值”使名次虚增 1（实证：XXL 行 PctRank 2→3、Sort Key 1002→1003，取消筛选器后恢复）。修复模式：候选值用 REMOVEFILTERS(三列组合) 清除行筛选与复合筛选（保留 Division/Platform/Store 外部筛选）+ TREATAS 重建候选三元组，一次计算物化为 [@Pct]/[@GroupValue] 列，FILTER 与 RANKX 共用物化值，消除两阶段不一致。

**L2 分组排名说明**（分组金额 = SLS Amt Value / EOH Amt Value 上卷至 category + sku_size_category 粒度，同分组所有行共享）。
示例（金额故意与优先级错开，展示各层分工）：

| 分组 (sku_size_category) | 分组当期金额 | L1 优先级 | L2 分组排名（金额降序） | 排序键区间       |
| ------------------------ | ------------ | --------- | ----------------------- | ---------------- |
| 字母尺码 (XS-XXL)        | ¥800,000    | 0         | 2                       | 2,001,001 起     |
| 数字尺码 (00-18)         | ¥150,000    | 1         | 3                       | 1,003,001,001 起 |
| Knit                     | ¥900,000    | 2         | 1                       | 2,001,001,001 起 |

- L1 定层：Knit 金额最大（L2 排名 1）但属其余层（优先级 2），×1,000,000,000 权重使排序键必然最后 —— 跨优先级顺序由 L1 主导，L2 排名值大小不改变跨层顺序
- L2 定同层内先后：同优先级存在多个分组时（如多个其余分组 Knit / 其他），金额大的分组排前
- L3 定组内行序：分组定了之后，组内 size 行按占比升序
- __GroupRank 对当前 category 内全部分组统一排名（不按优先级分层各自排），同层内相对顺序依然正确，分层排名逻辑更简

---

## 4. 度量值实现

### 4.1 Top Size Sales Category Rank（Sales Top4 排名）

```dax
Top Size Sales Category Rank =
// ========================================
// 度量值: Top Size Sales Category Rank
// 中文名: Sales 板块 Category Top4 排名
// Display Folder: Top Size Sales Performance\Rank
// 用途: 计算当前行所属 category 按 This Period sum(net_sales_amt) 的降序排名，
//       用于 Sales 表格视觉级筛选器固定 Top1~Top4 category
// 依赖: Slicer_Time_Frame_Min_This[TimeFrame_Min] / Slicer_Time_Frame_Max_This[TimeFrame_Max]
// 口径: date + Platform + Store Name + Division 筛选组合下，
//       按 category 粒度 This Period sum(net_sales_amt) 降序排名
// 说明: 排名基于 category 粒度金额（非当前行金额），size category / size 层级行
//       返回所属 category 的排名；空白/空字符/本期无销售的 category 不参与排名
// 空白/空字符排除: category 同时存在 NULL 与空字符 ""，空字符非 BLANK、金额最大，
//       NOT ISBLANK 无法排除（会占据排名 1）；视觉级 category 筛选器会被候选集的
//       ALL(category) 移除而失效，故必须在度量值内部用 LEN(TRIM()) > 0 排除
// ========================================

// ── This Period 时间区间 ──
VAR __PeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Min_This[TimeFrame_Min])
VAR __PeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

// ── 当前行所属 category（层级展开下 category 筛选在任意层级行均存在）──
VAR __CurrentCategory = SELECTEDVALUE('s02_trade_sku_data_d'[category])

// ── 排名表：全部有效 category 及其 This Period 销售金额（category 粒度）──
// 有效 = 非空白且非空字符（LEN(TRIM()) > 0 同时排除 NULL、""、纯空格）
// ALL(category) 仅移除 category 列筛选；Platform / Store Name / Division 等外部筛选保留
// 关键：ALL(sku_size_category, sku_size) 必须显式移除表格行残留的尺码筛选，
//       否则每个候选 category 的金额被限制在当前行尺码内，与 __CurrentCategoryAmt
//       （category 粒度真实金额）口径不一致，RANKX 将恒返回 1
VAR __Ranking =
    ADDCOLUMNS(
        FILTER(
            ALL('s02_trade_sku_data_d'[category]),
            NOT ISBLANK('s02_trade_sku_data_d'[category])
                && LEN(TRIM('s02_trade_sku_data_d'[category])) > 0
        ),
        "@Amt",
            CALCULATE(
                SUM('s02_trade_sku_data_d'[net_sales_amt]),
                ALL('s02_trade_sku_data_d'[sku_size_category], 's02_trade_sku_data_d'[sku_size]),  // 收敛到 category 粒度，与 __CurrentCategoryAmt 同口径
                's02_trade_sku_data_d'[dt] >= __PeriodMin,
                's02_trade_sku_data_d'[dt] <= __PeriodMax
            )
    )

// ── 当前行所属 category 的 This Period 销售金额 ──
// 移除 size 层级筛选，保留 category 筛选与外部筛选，得到 category 粒度金额
VAR __CurrentCategoryAmt =
    CALCULATE(
        SUM('s02_trade_sku_data_d'[net_sales_amt]),
        ALL('s02_trade_sku_data_d'[sku_size_category], 's02_trade_sku_data_d'[sku_size]),
        's02_trade_sku_data_d'[dt] >= __PeriodMin,
        's02_trade_sku_data_d'[dt] <= __PeriodMax
    )

// 空白/空字符 category 行返回 BLANK（被 Rank = N 视觉级筛选器排除），真实 category 排名从 1 起
RETURN
    IF(
        NOT ISBLANK(__CurrentCategory)
            && LEN(TRIM(__CurrentCategory)) > 0,
        RANKX(__Ranking, [@Amt], __CurrentCategoryAmt, DESC)
    )
```

### 4.2 Top Size Inventory Category Rank（Inventory Top4 排名）

```dax
Top Size Inventory Category Rank =
// ========================================
// 度量值: Top Size Inventory Category Rank
// 中文名: Inventory 板块 Category Top4 排名
// Display Folder: Top Size Sales Performance\Rank
// 用途: 计算当前行所属 category 按 This Period 最后一天 sum(msrp_inv_amt) 的降序排名，
//       用于 Inventory 表格视觉级筛选器固定 Top1~Top4 category
// 依赖: Slicer_Time_Frame_Max_This[TimeFrame_Min] / [TimeFrame_Max]
// 口径: date + Division 筛选组合下，按 category 粒度 This Period 最后一天
//       sum(msrp_inv_amt) 降序排名（期末时点数）
// 说明: inv 表无 platform / shop_name 字段，排名不受渠道筛选影响（口径限制见注意事项 1）
//       空白/空字符 category 在度量值内部排除（LEN(TRIM()) > 0，机制同 Sales Rank）
// ========================================

// ── End Period 时间范围（期末时点类）──
VAR __EndPeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Min])
VAR __EndPeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

// ── 期末快照日：end period 范围内最后一个有数据的日期 ──
// REMOVEFILTERS 保证快照日不随切片器 / 表格行上下文漂移
VAR __EndPeriodDate =
    CALCULATE(
        MAX('s02_inventory_stock_sales_detail_d'[dt]),
        REMOVEFILTERS('s02_inventory_stock_sales_detail_d'),
        's02_inventory_stock_sales_detail_d'[dt] >= __EndPeriodMin,
        's02_inventory_stock_sales_detail_d'[dt] <= __EndPeriodMax
    )

// ── 当前行所属 category ──
VAR __CurrentCategory = SELECTEDVALUE('s02_inventory_stock_sales_detail_d'[category])

// ── 排名表：全部有效 category 及其期末快照日库存金额（category 粒度）──
// 有效 = 非空白且非空字符（LEN(TRIM()) > 0；视觉级 category 筛选器会被 ALL(category) 移除而无效）
// 关键：ALL(sku_size_category, sku_size) 移除表格行残留的尺码筛选，保证候选金额
//       与 __CurrentCategoryAmt 同为 category 粒度（否则 RANKX 恒返回 1）
VAR __Ranking =
    ADDCOLUMNS(
        FILTER(
            ALL('s02_inventory_stock_sales_detail_d'[category]),
            NOT ISBLANK('s02_inventory_stock_sales_detail_d'[category])
                && LEN(TRIM('s02_inventory_stock_sales_detail_d'[category])) > 0
        ),
        "@Amt",
            CALCULATE(
                SUM('s02_inventory_stock_sales_detail_d'[msrp_inv_amt]),
                ALL('s02_inventory_stock_sales_detail_d'[sku_size_category], 's02_inventory_stock_sales_detail_d'[sku_size]),  // 收敛到 category 粒度，与 __CurrentCategoryAmt 同口径
                's02_inventory_stock_sales_detail_d'[dt] = __EndPeriodDate
            )
    )

// ── 当前行所属 category 的期末库存金额 ──
// 移除 size 层级筛选，保留 category 筛选与 Division 筛选
VAR __CurrentCategoryAmt =
    CALCULATE(
        SUM('s02_inventory_stock_sales_detail_d'[msrp_inv_amt]),
        ALL('s02_inventory_stock_sales_detail_d'[sku_size_category], 's02_inventory_stock_sales_detail_d'[sku_size]),
        's02_inventory_stock_sales_detail_d'[dt] = __EndPeriodDate
    )

// 空白/空字符 category 行返回 BLANK（被 Rank = N 视觉级筛选器排除），真实 category 排名从 1 起
RETURN
    IF(
        NOT ISBLANK(__CurrentCategory)
            && LEN(TRIM(__CurrentCategory)) > 0,
        RANKX(__Ranking, [@Amt], __CurrentCategoryAmt, DESC)
    )
```

### 4.3 Top Size Sales SLS Amt% Value（This Period 销售金额占比）

```dax
Top Size Sales SLS Amt% Value =
// ========================================
// 度量值: Top Size Sales SLS Amt% Value
// 中文名: 销售金额占比（This Period）
// Display Folder: Top Size Sales Performance\Base Metrics
// 用途: 该 size 占所属 category + size category 的销售金额比例（This Period 区间）
// 依赖: Slicer_Time_Frame_Min_This[TimeFrame_Min] / Slicer_Time_Frame_Max_This[TimeFrame_Max]
// 口径: 分子：该 category + size category + size 下 sum(net_sales_amt)；
//       分母：该 category + size category 下 sum(net_sales_amt)
// 数据底表: s02_trade_sku_data_d
// ========================================

// ── This Period 时间区间 ──
VAR __PeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Min_This[TimeFrame_Min])
VAR __PeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

// ── 分子：当前行（category + size category + size）This Period 净销售金额 ──
VAR __Numerator =
    CALCULATE(
        SUM('s02_trade_sku_data_d'[net_sales_amt]),
        's02_trade_sku_data_d'[dt] >= __PeriodMin,
        's02_trade_sku_data_d'[dt] <= __PeriodMax
    )

// ── 分母：该 category + size category 层级 This Period 净销售金额 ──
// REMOVEFILTERS(sku_size) 移除 size 行筛选，保留 category / size category 筛选与外部切片器筛选
VAR __Denominator =
    CALCULATE(
        SUM('s02_trade_sku_data_d'[net_sales_amt]),
        REMOVEFILTERS('s02_trade_sku_data_d'[sku_size]),
        's02_trade_sku_data_d'[dt] >= __PeriodMin,
        's02_trade_sku_data_d'[dt] <= __PeriodMax
    )

RETURN
    DIVIDE(__Numerator, __Denominator)
```

### 4.4 Top Size Sales LP SLS Amt% Value（Last Period 销售金额占比）

```dax
Top Size Sales LP SLS Amt% Value =
// ========================================
// 度量值: Top Size Sales LP SLS Amt% Value
// 中文名: 销售金额占比（Last Period）
// Display Folder: Top Size Sales Performance\Base Metrics
// 用途: 该 size 占所属 category + size category 的销售金额比例（Last Period 区间）
// 依赖: Slicer_Time_Frame_Min_This[TimeFrame_Min] / Slicer_Time_Frame_Max_This[TimeFrame_Max]
//       Slicer_Time_Frame_Min_Last[TimeFrame_Min] / Slicer_Time_Frame_Max_Last[TimeFrame_Max]
// 口径: 分子：该 category + size category + size 下 sum(net_sales_amt)（Last Period）；
//       分母：该 category + size category 下 sum(net_sales_amt)（Last Period），
//             且仅汇总「This Period 有销售金额的 size」（可见 size 集合）
// 说明: LP 分母限定可见 size 集合（2026-10-15 业务确认）——当期空 size（当期无销售、
//       上期有值的行）的上期金额不进入分母，LP 占比基数与当期占比同为显示行汇总，
//       vs LP 差值两期基于同一尺码集合；当期占比无需同款限定（空行当期金额为 0，
//       全量汇总与显示行汇总数值相同）
// 数据底表: s02_trade_sku_data_d
// ========================================

// ── This Period 时间区间（可见 size 判定用）──
VAR __PeriodMin_This = SELECTEDVALUE(Slicer_Time_Frame_Min_This[TimeFrame_Min])
VAR __PeriodMax_This = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

// ── Last Period 时间区间 ──
VAR __PeriodMin_LY = SELECTEDVALUE(Slicer_Time_Frame_Min_Last[TimeFrame_Min])
VAR __PeriodMax_LY = SELECTEDVALUE(Slicer_Time_Frame_Max_Last[TimeFrame_Max])

// ── 可见 size 集合：该分组内 This Period 有销售金额的 size ──
// 判定与视觉级「SLS Amt% Value 不为空」筛选器一致（占比非空 ⟺ 当期分子非空）；
// REMOVEFILTERS(sku_size) 使 VALUES 取分组内全部 size，逐 size 计算当期金额后过滤
VAR __VisibleSizes =
    CALCULATETABLE(
        FILTER(
            VALUES('s02_trade_sku_data_d'[sku_size]),
            NOT ISBLANK(
                CALCULATE(
                    SUM('s02_trade_sku_data_d'[net_sales_amt]),
                    's02_trade_sku_data_d'[dt] >= __PeriodMin_This,
                    's02_trade_sku_data_d'[dt] <= __PeriodMax_This
                )
            )
        ),
        REMOVEFILTERS('s02_trade_sku_data_d'[sku_size])
    )

// ── 分子：当前行（category + size category + size）Last Period 净销售金额 ──
VAR __Numerator =
    CALCULATE(
        SUM('s02_trade_sku_data_d'[net_sales_amt]),
        's02_trade_sku_data_d'[dt] >= __PeriodMin_LY,
        's02_trade_sku_data_d'[dt] <= __PeriodMax_LY
    )

// ── 分母：可见 size 集合的 Last Period 净销售金额（category + size category 层级）──
// REMOVEFILTERS(sku_size) 上卷至分组层级后，按 __VisibleSizes 限定 size 范围
VAR __Denominator =
    CALCULATE(
        SUM('s02_trade_sku_data_d'[net_sales_amt]),
        REMOVEFILTERS('s02_trade_sku_data_d'[sku_size]),
        __VisibleSizes,
        's02_trade_sku_data_d'[dt] >= __PeriodMin_LY,
        's02_trade_sku_data_d'[dt] <= __PeriodMax_LY
    )

RETURN
    DIVIDE(__Numerator, __Denominator)
```

### 4.5 Top Size Sales SLS Amt% vs LP Value（差值）

```dax
Top Size Sales SLS Amt% vs LP Value =
// ========================================
// 度量值: Top Size Sales SLS Amt% vs LP Value
// 中文名: 销售金额占比 vs LP（差值）
// Display Folder: Top Size Sales Performance\Base Metrics
// 用途: this period - last period 占比差值（原始小数，×10000 转 bp 在 Display 层实现）
// 依赖: [Top Size Sales SLS Amt% Value], [Top Size Sales LP SLS Amt% Value]
// 口径: this period - last period（差值，bp 指标）
// 边界: 任一期为 BLANK 时返回 BLANK，避免单侧缺失产生失真差值
// ========================================
    VAR __ThisPct = [Top Size Sales SLS Amt% Value]
    VAR __LastPct = [Top Size Sales LP SLS Amt% Value]

    RETURN
        IF(
            ISBLANK(__ThisPct) || ISBLANK(__LastPct),
            BLANK(),
            __ThisPct - __LastPct
        )
```

### 4.6 Top Size Inventory EOH Amt% Value（This Period 期末库存金额占比）

```dax
Top Size Inventory EOH Amt% Value =
// ========================================
// 度量值: Top Size Inventory EOH Amt% Value
// 中文名: 期末库存金额占比（This Period）
// Display Folder: Top Size Sales Performance\Base Metrics
// 用途: 该 size 占所属 category + size category 的期末库存金额比例（时点数）
// 依赖: Slicer_Time_Frame_Max_This[TimeFrame_Min] / [TimeFrame_Max]
// 口径: 分子：该 category + size category + size 下 sum(msrp_inv_amt)；
//       分母：该 category + size category 下 sum(msrp_inv_amt)；
//       时间范围看 this period 最后一天（实现为 end period 范围内最后一个快照日）
// 数据底表: s02_inventory_stock_sales_detail_d
// 说明: inv 表无 platform / shop_name 字段，指标不受渠道筛选影响（口径限制见注意事项 1）
// ========================================

// ── End Period 时间范围（期末时点类）──
VAR __EndPeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Min])
VAR __EndPeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

// ── 期末快照日：end period 范围内最后一个有数据的日期（单日时点）──
VAR __EndPeriodDate =
    CALCULATE(
        MAX('s02_inventory_stock_sales_detail_d'[dt]),
        REMOVEFILTERS('s02_inventory_stock_sales_detail_d'),
        's02_inventory_stock_sales_detail_d'[dt] >= __EndPeriodMin,
        's02_inventory_stock_sales_detail_d'[dt] <= __EndPeriodMax
    )

// ── 分子：当前行（category + size category + size）期末库存金额 ──
VAR __Numerator =
    CALCULATE(
        SUM('s02_inventory_stock_sales_detail_d'[msrp_inv_amt]),
        's02_inventory_stock_sales_detail_d'[dt] = __EndPeriodDate
    )

// ── 分母：该 category + size category 层级期末库存金额 ──
// REMOVEFILTERS(sku_size) 移除 size 行筛选，保留 category / size category 筛选与 Division 筛选
VAR __Denominator =
    CALCULATE(
        SUM('s02_inventory_stock_sales_detail_d'[msrp_inv_amt]),
        REMOVEFILTERS('s02_inventory_stock_sales_detail_d'[sku_size]),
        's02_inventory_stock_sales_detail_d'[dt] = __EndPeriodDate
    )

RETURN
    DIVIDE(__Numerator, __Denominator)
```

### 4.7 Top Size Inventory LP EOH Amt% Value（Last Period 期末库存金额占比）

```dax
Top Size Inventory LP EOH Amt% Value =
// ========================================
// 度量值: Top Size Inventory LP EOH Amt% Value
// 中文名: 期末库存金额占比（Last Period）
// Display Folder: Top Size Sales Performance\Base Metrics
// 用途: 该 size 占所属 category + size category 的期末库存金额比例（时点数）
// 依赖: Slicer_Time_Frame_Max_This[TimeFrame_Min] / [TimeFrame_Max]
//       Slicer_Time_Frame_Max_Last[TimeFrame_Min] / [TimeFrame_Max]
// 口径: 分子：该 category + size category + size 下 sum(msrp_inv_amt)（Last Period 最后一天）；
//       分母：该 category + size category 下 sum(msrp_inv_amt)（Last Period 最后一天），
//             且仅汇总「This Period 有库存金额的 size」（可见 size 集合）
// 说明: LP 分母限定可见 size 集合（2026-10-15 业务确认，机制同 Sales LP 占比）；
//       当期空 size（当期无快照、上期有值的行）的上期金额不进入分母
// 数据底表: s02_inventory_stock_sales_detail_d
// ========================================

// ── End Period（This）时间范围与快照日（可见 size 判定用）──
VAR __EndPeriodMin_This = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Min])
VAR __EndPeriodMax_This = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])
VAR __EndPeriodDate_This =
    CALCULATE(
        MAX('s02_inventory_stock_sales_detail_d'[dt]),
        REMOVEFILTERS('s02_inventory_stock_sales_detail_d'),
        's02_inventory_stock_sales_detail_d'[dt] >= __EndPeriodMin_This,
        's02_inventory_stock_sales_detail_d'[dt] <= __EndPeriodMax_This
    )

// ── End Period LP 时间范围（期末时点类）──
VAR __EndPeriodMin_LY = SELECTEDVALUE(Slicer_Time_Frame_Max_Last[TimeFrame_Min])
VAR __EndPeriodMax_LY = SELECTEDVALUE(Slicer_Time_Frame_Max_Last[TimeFrame_Max])

// ── 期末快照日（LP）：end period LP 范围内最后一个有数据的日期 ──
VAR __EndPeriodDate_LY =
    CALCULATE(
        MAX('s02_inventory_stock_sales_detail_d'[dt]),
        REMOVEFILTERS('s02_inventory_stock_sales_detail_d'),
        's02_inventory_stock_sales_detail_d'[dt] >= __EndPeriodMin_LY,
        's02_inventory_stock_sales_detail_d'[dt] <= __EndPeriodMax_LY
    )

// ── 可见 size 集合：该分组内 This Period 快照日有库存金额的 size ──
// 判定与视觉级「EOH Amt% Value 不为空」筛选器一致
VAR __VisibleSizes =
    CALCULATETABLE(
        FILTER(
            VALUES('s02_inventory_stock_sales_detail_d'[sku_size]),
            NOT ISBLANK(
                CALCULATE(
                    SUM('s02_inventory_stock_sales_detail_d'[msrp_inv_amt]),
                    's02_inventory_stock_sales_detail_d'[dt] = __EndPeriodDate_This
                )
            )
        ),
        REMOVEFILTERS('s02_inventory_stock_sales_detail_d'[sku_size])
    )

// ── 分子：当前行（category + size category + size）Last Period 期末库存金额 ──
VAR __Numerator =
    CALCULATE(
        SUM('s02_inventory_stock_sales_detail_d'[msrp_inv_amt]),
        's02_inventory_stock_sales_detail_d'[dt] = __EndPeriodDate_LY
    )

// ── 分母：可见 size 集合的 Last Period 期末库存金额（category + size category 层级）──
VAR __Denominator =
    CALCULATE(
        SUM('s02_inventory_stock_sales_detail_d'[msrp_inv_amt]),
        REMOVEFILTERS('s02_inventory_stock_sales_detail_d'[sku_size]),
        __VisibleSizes,
        's02_inventory_stock_sales_detail_d'[dt] = __EndPeriodDate_LY
    )

RETURN
    DIVIDE(__Numerator, __Denominator)
```

### 4.8 Top Size Inventory EOH Amt% vs LP Value（差值）

```dax
Top Size Inventory EOH Amt% vs LP Value =
// ========================================
// 度量值: Top Size Inventory EOH Amt% vs LP Value
// 中文名: 期末库存金额占比 vs LP（差值）
// Display Folder: Top Size Sales Performance\Base Metrics
// 用途: this period - last period 占比差值（原始小数，×10000 转 bp 在 Display 层实现）
// 依赖: [Top Size Inventory EOH Amt% Value], [Top Size Inventory LP EOH Amt% Value]
// 口径: this period - last period（差值，bp 指标）
// 边界: 任一期为 BLANK 时返回 BLANK，避免单侧缺失产生失真差值
// ========================================
    VAR __ThisPct = [Top Size Inventory EOH Amt% Value]
    VAR __LastPct = [Top Size Inventory LP EOH Amt% Value]

    RETURN
        IF(
            ISBLANK(__ThisPct) || ISBLANK(__LastPct),
            BLANK(),
            __ThisPct - __LastPct
        )
```

### 4.9 Top Size Sales SLS Amt% Display

```dax
Top Size Sales SLS Amt% Display =
// ========================================
// 度量值: Top Size Sales SLS Amt% Display
// 中文名: 销售金额占比（This Period）显示
// Display Folder: Top Size Sales Performance\Formatting
// 用途: percent_0dp 格式化（百分比整数，不含正号）；BLANK 显示 "-"
// 依赖: [Top Size Sales SLS Amt% Value]
// ========================================
    VAR __Value = [Top Size Sales SLS Amt% Value]
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            FORMAT(__Value, "#,##0%")
        )
```

### 4.10 Top Size Sales LP SLS Amt% Display

```dax
Top Size Sales LP SLS Amt% Display =
// ========================================
// 度量值: Top Size Sales LP SLS Amt% Display
// 中文名: 销售金额占比（Last Period）显示
// Display Folder: Top Size Sales Performance\Formatting
// 用途: percent_0dp 格式化（百分比整数，不含正号）；BLANK 显示 "-"
// 依赖: [Top Size Sales LP SLS Amt% Value]
// ========================================
    VAR __Value = [Top Size Sales LP SLS Amt% Value]
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            FORMAT(__Value, "#,##0%")
        )
```

### 4.11 Top Size Sales SLS Amt% vs LP Display

```dax
Top Size Sales SLS Amt% vs LP Display =
// ========================================
// 度量值: Top Size Sales SLS Amt% vs LP Display
// 中文名: 销售金额占比 vs LP 显示
// Display Folder: Top Size Sales Performance\Formatting
// 用途: integer_bp 格式化：值 ×10000 转 bp，不含正号，含负号，零值 0bp；BLANK 显示 "-"
// 依赖: [Top Size Sales SLS Amt% vs LP Value]
// 数据格式: #,##0bp;-#,##0bp;0bp
// ========================================
    VAR __Value = [Top Size Sales SLS Amt% vs LP Value]
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            FORMAT(__Value * 10000, "#,##0") & "bp"   // 负数自带负号，零值 0bp
        )
```

### 4.12 Top Size Inventory EOH Amt% Display

```dax
Top Size Inventory EOH Amt% Display =
// ========================================
// 度量值: Top Size Inventory EOH Amt% Display
// 中文名: 期末库存金额占比（This Period）显示
// Display Folder: Top Size Sales Performance\Formatting
// 用途: percent_0dp 格式化（百分比整数，不含正号）；BLANK 显示 "-"
// 依赖: [Top Size Inventory EOH Amt% Value]
// ========================================
    VAR __Value = [Top Size Inventory EOH Amt% Value]
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            FORMAT(__Value, "#,##0%")
        )
```

### 4.13 Top Size Inventory LP EOH Amt% Display

```dax
Top Size Inventory LP EOH Amt% Display =
// ========================================
// 度量值: Top Size Inventory LP EOH Amt% Display
// 中文名: 期末库存金额占比（Last Period）显示
// Display Folder: Top Size Sales Performance\Formatting
// 用途: percent_0dp 格式化（百分比整数，不含正号）；BLANK 显示 "-"
// 依赖: [Top Size Inventory LP EOH Amt% Value]
// ========================================
    VAR __Value = [Top Size Inventory LP EOH Amt% Value]
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            FORMAT(__Value, "#,##0%")
        )
```

### 4.14 Top Size Inventory EOH Amt% vs LP Display

```dax
Top Size Inventory EOH Amt% vs LP Display =
// ========================================
// 度量值: Top Size Inventory EOH Amt% vs LP Display
// 中文名: 期末库存金额占比 vs LP 显示
// Display Folder: Top Size Sales Performance\Formatting
// 用途: integer_bp 格式化：值 ×10000 转 bp，不含正号，含负号，零值 0bp；BLANK 显示 "-"
// 依赖: [Top Size Inventory EOH Amt% vs LP Value]
// 数据格式: #,##0bp;-#,##0bp;0bp
// ========================================
    VAR __Value = [Top Size Inventory EOH Amt% vs LP Value]
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            FORMAT(__Value * 10000, "#,##0") & "bp"   // 负数自带负号，零值 0bp
        )
```

### 4.15 Top Size Sales SLS Amt Value（当期净销售金额）

```dax
Top Size Sales SLS Amt Value =
// ========================================
// 度量值: Top Size Sales SLS Amt Value
// 中文名: 当期净销售金额
// Display Folder: Top Size Sales Performance\Base Metrics
// 用途: 当前行（category + size category + size）This Period 净销售金额具体值，
//       用于行排序键的分组金额计算与交叉验证（如需表格展示可另配 Display 度量）
// 依赖: Slicer_Time_Frame_Min_This[TimeFrame_Min] / Slicer_Time_Frame_Max_This[TimeFrame_Max]
// 口径: This Period 区间 sum(net_sales_amt)
// 数据底表: s02_trade_sku_data_d
// ========================================

// ── This Period 时间区间 ──
VAR __PeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Min_This[TimeFrame_Min])
VAR __PeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

RETURN
    CALCULATE(
        SUM('s02_trade_sku_data_d'[net_sales_amt]),
        's02_trade_sku_data_d'[dt] >= __PeriodMin,
        's02_trade_sku_data_d'[dt] <= __PeriodMax
    )
```

### 4.16 Top Size Inventory EOH Amt Value（当期期末库存金额）

```dax
Top Size Inventory EOH Amt Value =
// ========================================
// 度量值: Top Size Inventory EOH Amt Value
// 中文名: 当期期末库存金额
// Display Folder: Top Size Sales Performance\Base Metrics
// 用途: 当前行（category + size category + size）This Period 最后一天期末库存金额具体值
//       （时点数），用于行排序键的分组金额计算与交叉验证
// 依赖: Slicer_Time_Frame_Max_This[TimeFrame_Min] / [TimeFrame_Max]
// 口径: 时间范围看 this period 最后一天；sum(msrp_inv_amt)
// 数据底表: s02_inventory_stock_sales_detail_d
// 说明: inv 表无 platform / shop_name 字段，不受渠道筛选影响（口径限制见注意事项 1）
// ========================================

// ── End Period 时间范围（期末时点类）──
VAR __EndPeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Min])
VAR __EndPeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

// ── 期末快照日：end period 范围内最后一个有数据的日期（单日时点）──
VAR __EndPeriodDate =
    CALCULATE(
        MAX('s02_inventory_stock_sales_detail_d'[dt]),
        REMOVEFILTERS('s02_inventory_stock_sales_detail_d'),
        's02_inventory_stock_sales_detail_d'[dt] >= __EndPeriodMin,
        's02_inventory_stock_sales_detail_d'[dt] <= __EndPeriodMax
    )

RETURN
    CALCULATE(
        SUM('s02_inventory_stock_sales_detail_d'[msrp_inv_amt]),
        's02_inventory_stock_sales_detail_d'[dt] = __EndPeriodDate
    )
```

### 4.17 Top Size Sales Sort Key（Sales 表格行排序键）

```dax
Top Size Sales Sort Key =
// ========================================
// 度量值: Top Size Sales Sort Key
// 中文名: Sales 表格行排序键
// Display Folder: Top Size Sales Performance\Rank
// 用途: Sales 表格行排序键（升序），表格视觉对象仅支持单键排序，
//       将四级排序规则编码为一个整数键：
//   L1 分组优先级：sku_size_category 含"字母尺码" → 0、含"数字尺码" → 1、其余 → 2
//   L2 分组顺序：同优先级内按分组当期销售金额（SLS Amt Value 上卷分组粒度）降序
//   L3 组内顺序：按 SLS Amt% Value 升序（同一分组内分母相同，占比升序与金额升序等价）；
//             当期占比为空的行排在分组最后（空值垫底规则）
//   L4 决胜顺序：按 sku_size 名称字典序升序（仅 L3 并列时生效，保证排序键全局唯一）
// 依赖: [Top Size Sales SLS Amt Value], [Top Size Sales SLS Amt% Value]
// 使用: 拖入表格值区域，点击该列标题按升序排序（配置见 §7.1）
// 编码: Key = 优先级 × 1,000,000,000 + 分组排名 × 1,000,000 + 组内排名 × 1,000 + 决胜排名
//       （单表格内分组数 / 单分组内 size 数需 < 1,000，超出需调大系数）
// 并列语义: L3 为 RANKX 竞争排名（SKIP），占比精确相等的行共享名次、下一名次跳号；
//       同分组分母相同，占比相等 ⟺ 当期金额分毫不差（展示值舍入后肉眼不可辨）
// 上下文净化: L2/L3 候选值用 REMOVEFILTERS(三列组合) + TREATAS 重建候选三元组后一次计算物化为列
//       （视觉级度量筛选器落地为跨列组合筛选，单列 ALL/REMOVEFILTERS 清不掉，
//       曾致当前行 size 候选在 RANKX 迭代阶段取 BLANK、L3 名次虚增 1，见注意事项 16）
// ========================================

// ── L1 分组优先级：字母尺码 > 数字尺码 > 其余 ──
VAR __SizeCategory = SELECTEDVALUE('s02_trade_sku_data_d'[sku_size_category])
VAR __GroupPriority =
    SWITCH(
        TRUE(),
        CONTAINSSTRING(__SizeCategory, "字母尺码"), 0,   // 字母尺码分组固定最前
        CONTAINSSTRING(__SizeCategory, "数字尺码"), 1,   // 数字尺码分组第二
        2                                                 // 其余分组
    )

// ── 分组锚点：候选上下文重建所需（行上下文取值）──
VAR __Category = SELECTEDVALUE('s02_trade_sku_data_d'[category])

// ── L2 分组金额：当前分组（category + size category 粒度）当期销售金额 ──
// REMOVEFILTERS(三列组合) 清除行筛选与视觉级复合组合筛选，保留 Division/Platform/Store 外部筛选；
// TREATAS 重建 (category, 分组) 后计算，与候选 @GroupValue 同口径
VAR __GroupValue =
    CALCULATE(
        [Top Size Sales SLS Amt Value],
        REMOVEFILTERS(
            's02_trade_sku_data_d'[category],
            's02_trade_sku_data_d'[sku_size_category],
            's02_trade_sku_data_d'[sku_size]
        ),
        TREATAS(
            ROW(
                "Category", __Category,
                "SizeCategory", __SizeCategory
            ),
            's02_trade_sku_data_d'[category],
            's02_trade_sku_data_d'[sku_size_category]
        )
    )

// ── L2 分组候选：当前 category 内全部有效 sku_size_category 及其分组金额 ──
// 逐候选 REMOVEFILTERS(三列组合) + TREATAS 重建 (category, 候选分组)，不依赖上下文转换，
// 候选值一次计算物化为 [@GroupValue] 列，消除 FILTER 与 RANKX 两阶段取值不一致
VAR __GroupCandidates =
    ADDCOLUMNS(
        FILTER(
            ALL('s02_trade_sku_data_d'[sku_size_category]),
            NOT ISBLANK('s02_trade_sku_data_d'[sku_size_category])
                && LEN(TRIM('s02_trade_sku_data_d'[sku_size_category])) > 0
        ),
        "@GroupValue",
            CALCULATE(
                [Top Size Sales SLS Amt Value],
                REMOVEFILTERS(
                    's02_trade_sku_data_d'[category],
                    's02_trade_sku_data_d'[sku_size_category],
                    's02_trade_sku_data_d'[sku_size]
                ),
                TREATAS(
                    ROW(
                        "Category", __Category,
                        "SizeCategory", 's02_trade_sku_data_d'[sku_size_category]   // 行上下文候选分组
                    ),
                    's02_trade_sku_data_d'[category],
                    's02_trade_sku_data_d'[sku_size_category]
                )
            )
    )

// ── L2 分组排名：按分组金额降序（优先级在 Key 的 L1 主导，跨优先级排名也正确）──
VAR __GroupRank =
    RANKX(__GroupCandidates, [@GroupValue], __GroupValue, DESC)

// ── L3 组内排名：按 SLS Amt% Value 升序，当期占比为空的行排在分组最后（空值垫底）──
// 逐候选 REMOVEFILTERS(三列组合) + TREATAS 重建 (category, 分组, 候选 size)，一次计算物化为 [@Pct]；
// @RankValue 标记当期占比为空的候选（升序排名下用超大值垫底，仅作用于空值、不占正序名次）；
// value 参数同构垫底：当期行为空时用超大值参与排名，避免与 @Pct 候选两阶段语义不一致
VAR __PctRank =
    RANKX(
        FILTER(
            ADDCOLUMNS(
                ADDCOLUMNS(
                    FILTER(
                        ALL('s02_trade_sku_data_d'[sku_size]),
                        NOT ISBLANK('s02_trade_sku_data_d'[sku_size])
                            && LEN(TRIM('s02_trade_sku_data_d'[sku_size])) > 0
                    ),
                    "@Pct",
                        CALCULATE(
                            [Top Size Sales SLS Amt% Value],
                            REMOVEFILTERS(
                                's02_trade_sku_data_d'[category],
                                's02_trade_sku_data_d'[sku_size_category],
                                's02_trade_sku_data_d'[sku_size]
                            ),
                            TREATAS(
                                ROW(
                                    "Category", __Category,
                                    "SizeCategory", __SizeCategory,
                                    "Size", 's02_trade_sku_data_d'[sku_size]   // 行上下文候选尺码
                                ),
                                's02_trade_sku_data_d'[category],
                                's02_trade_sku_data_d'[sku_size_category],
                                's02_trade_sku_data_d'[sku_size]
                            )
                        )
                ),
                "@RankValue", IF(ISBLANK([@Pct]), 1E15, [@Pct])   // 当期空占比垫底：超大值仅作用于空值
            ),
            NOT ISBLANK([@Pct])
        ),
        [@RankValue],
        IF(ISBLANK([Top Size Sales SLS Amt% Value]), 1E15, [Top Size Sales SLS Amt% Value]),
        ASC
    )

// ── L4 决胜排名：按 sku_size 名称字典序升序（L3 并列时保证排序键全局唯一、行序确定）──
// 对全部 distinct sku_size 计数，名称序为确定性规则（非尺码业务序）
VAR __TieRank =
    COUNTROWS(                          -- ④ 数一数：过滤后剩了几行
        FILTER(                         -- ② 对这张表逐行过滤
            ALL('s02_trade_sku_data_d'[sku_size]),    -- ① 拿到所有不重复的尺码值（无视外部筛选）
            's02_trade_sku_data_d'[sku_size]          -- ③ 当前迭代的尺码
            <                                   
            SELECTEDVALUE('s02_trade_sku_data_d'[sku_size])  -- ③ 表格当前行的尺码
        )
    ) + 1                               -- ⑤ 加 1：排名从 1 开始

RETURN
    __GroupPriority * 1000000000 + __GroupRank * 1000000 + __PctRank * 1000 + __TieRank
```

### 4.18 Top Size Inventory Sort Key（Inventory 表格行排序键）

```dax
Top Size Inventory Sort Key =
// ========================================
// 度量值: Top Size Inventory Sort Key
// 中文名: Inventory 表格行排序键
// Display Folder: Top Size Sales Performance\Rank
// 用途: Inventory 表格行排序键（升序），编码规则与 Sales 排序键一致：
//   L1 分组优先级：sku_size_category 含"字母尺码" → 0、含"数字尺码" → 1、其余 → 2
//   L2 分组顺序：同优先级内按分组当期期末库存金额（EOH Amt Value 上卷分组粒度）降序
//   L3 组内顺序：按 EOH Amt% Value 升序（同一分组内分母相同，占比升序与金额升序等价）；
//             当期占比为空的行排在分组最后（空值垫底规则）
//   L4 决胜顺序：按 sku_size 名称字典序升序（仅 L3 并列时生效，保证排序键全局唯一）
// 依赖: [Top Size Inventory EOH Amt Value], [Top Size Inventory EOH Amt% Value]
// 使用: 拖入表格值区域，点击该列标题按升序排序（配置见 §7.2）
// 编码: Key = 优先级 × 1,000,000,000 + 分组排名 × 1,000,000 + 组内排名 × 1,000 + 决胜排名
// 并列语义: 同 Sales 排序键（占比精确相等 ⟺ 期末库存金额分毫不差）
// 上下文净化: 同 Sales 排序键（REMOVEFILTERS(三列组合) + TREATAS 重建候选三元组，见注意事项 16）
// ========================================

// ── L1 分组优先级：字母尺码 > 数字尺码 > 其余 ──
VAR __SizeCategory = SELECTEDVALUE('s02_inventory_stock_sales_detail_d'[sku_size_category])
VAR __GroupPriority =
    SWITCH(
        TRUE(),
        CONTAINSSTRING(__SizeCategory, "字母尺码"), 0,   // 字母尺码分组固定最前
        CONTAINSSTRING(__SizeCategory, "数字尺码"), 1,   // 数字尺码分组第二
        2                                                 // 其余分组
    )

// ── 分组锚点：候选上下文重建所需（行上下文取值）──
VAR __Category = SELECTEDVALUE('s02_inventory_stock_sales_detail_d'[category])

// ── L2 分组金额：当前分组（category + size category 粒度）期末库存金额（时点数）──
// REMOVEFILTERS(三列组合) 清除行筛选与视觉级复合组合筛选，保留 Division 外部筛选
VAR __GroupValue =
    CALCULATE(
        [Top Size Inventory EOH Amt Value],
        REMOVEFILTERS(
            's02_inventory_stock_sales_detail_d'[category],
            's02_inventory_stock_sales_detail_d'[sku_size_category],
            's02_inventory_stock_sales_detail_d'[sku_size]
        ),
        TREATAS(
            ROW(
                "Category", __Category,
                "SizeCategory", __SizeCategory
            ),
            's02_inventory_stock_sales_detail_d'[category],
            's02_inventory_stock_sales_detail_d'[sku_size_category]
        )
    )

// ── L2 分组候选：当前 category 内全部有效 sku_size_category 及其分组金额 ──
// 逐候选 REMOVEFILTERS(三列组合) + TREATAS 重建 (category, 候选分组)，一次计算物化为 [@GroupValue]
VAR __GroupCandidates =
    ADDCOLUMNS(
        FILTER(
            ALL('s02_inventory_stock_sales_detail_d'[sku_size_category]),
            NOT ISBLANK('s02_inventory_stock_sales_detail_d'[sku_size_category])
                && LEN(TRIM('s02_inventory_stock_sales_detail_d'[sku_size_category])) > 0
        ),
        "@GroupValue",
            CALCULATE(
                [Top Size Inventory EOH Amt Value],
                REMOVEFILTERS(
                    's02_inventory_stock_sales_detail_d'[category],
                    's02_inventory_stock_sales_detail_d'[sku_size_category],
                    's02_inventory_stock_sales_detail_d'[sku_size]
                ),
                TREATAS(
                    ROW(
                        "Category", __Category,
                        "SizeCategory", 's02_inventory_stock_sales_detail_d'[sku_size_category]   // 行上下文候选分组
                    ),
                    's02_inventory_stock_sales_detail_d'[category],
                    's02_inventory_stock_sales_detail_d'[sku_size_category]
                )
            )
    )

// ── L2 分组排名：按分组金额降序 ──
VAR __GroupRank =
    RANKX(__GroupCandidates, [@GroupValue], __GroupValue, DESC)

// ── L3 组内排名：按 EOH Amt% Value 升序，当期占比为空的行排在分组最后（空值垫底，机制同 Sales）──
VAR __PctRank =
    RANKX(
        FILTER(
            ADDCOLUMNS(
                ADDCOLUMNS(
                    FILTER(
                        ALL('s02_inventory_stock_sales_detail_d'[sku_size]),
                        NOT ISBLANK('s02_inventory_stock_sales_detail_d'[sku_size])
                            && LEN(TRIM('s02_inventory_stock_sales_detail_d'[sku_size])) > 0
                    ),
                    "@Pct",
                        CALCULATE(
                            [Top Size Inventory EOH Amt% Value],
                            REMOVEFILTERS(
                                's02_inventory_stock_sales_detail_d'[category],
                                's02_inventory_stock_sales_detail_d'[sku_size_category],
                                's02_inventory_stock_sales_detail_d'[sku_size]
                            ),
                            TREATAS(
                                ROW(
                                    "Category", __Category,
                                    "SizeCategory", __SizeCategory,
                                    "Size", 's02_inventory_stock_sales_detail_d'[sku_size]   // 行上下文候选尺码
                                ),
                                's02_inventory_stock_sales_detail_d'[category],
                                's02_inventory_stock_sales_detail_d'[sku_size_category],
                                's02_inventory_stock_sales_detail_d'[sku_size]
                            )
                        )
                ),
                "@RankValue", IF(ISBLANK([@Pct]), 1E15, [@Pct])   // 当期空占比垫底：超大值仅作用于空值
            ),
            NOT ISBLANK([@Pct])
        ),
        [@RankValue],
        IF(ISBLANK([Top Size Inventory EOH Amt% Value]), 1E15, [Top Size Inventory EOH Amt% Value]),
        ASC
    )

// ── L4 决胜排名：按 sku_size 名称字典序升序（机制同 Sales 排序键）──
VAR __TieRank =
    COUNTROWS(                          -- ④ 数一数：过滤后剩了几行
        FILTER(                         -- ② 对这张表逐行过滤
            ALL('s02_inventory_stock_sales_detail_d'[sku_size]),    -- ① 拿到所有不重复的尺码值（无视外部筛选）
            's02_inventory_stock_sales_detail_d'[sku_size]          -- ③ 当前迭代的尺码
            <                                   
            SELECTEDVALUE('s02_inventory_stock_sales_detail_d'[sku_size])  -- ③ 表格当前行的尺码
        )
    ) + 1                               -- ⑤ 加 1：排名从 1 开始

RETURN
    __GroupPriority * 1000000000 + __GroupRank * 1000000 + __PctRank * 1000 + __TieRank
```

### 4.19 Top Size Sales IsEmpty（过滤整行为空值）

```dax
Top Size Sales IsEmpty = 
    IF(
        ISBLANK([Top Size Sales SLS Amt% Value]) &&
        ISBLANK([Top Size Sales LP SLS Amt% Value]) &&
        ISBLANK([Top Size Sales SLS Amt% vs LP Value]),
        0,
        1
    )
```

### 4.20 Top Size Inventory IsEmpty（过滤整行为空值）

```dax
Top Size Inventory IsEmpty = 
    IF(
        ISBLANK([Top Size Inventory EOH Amt% Value]) &&
        ISBLANK([Top Size Inventory LP EOH Amt% Value]) &&
        ISBLANK([Top Size Inventory EOH Amt% vs LP Value]),
        0,
        1
    )
```

---

## 5. 度量值清单与 Display Folder

| 序号 | 度量值名称                                | Display Folder | 模型格式      | 用途                                                                             |
| ---- | ----------------------------------------- | -------------- | ------------- | -------------------------------------------------------------------------------- |
| 1    | Top Size Sales Category Rank              | Rank           | 整数          | Sales Top4 category 排名（视觉级筛选器）                                         |
| 2    | Top Size Inventory Category Rank          | Rank           | 整数          | Inventory Top4 category 排名（视觉级筛选器）                                     |
| 3    | Top Size Sales SLS Amt% Value             | Base Metrics   | 百分比 #,##0% | This Period 销售金额占比                                                         |
| 4    | Top Size Sales LP SLS Amt% Value          | Base Metrics   | 百分比 #,##0% | Last Period 销售金额占比                                                         |
| 5    | Top Size Sales SLS Amt% vs LP Value       | Base Metrics   | 小数          | 占比差值（bp 原值）                                                              |
| 6    | Top Size Inventory EOH Amt% Value         | Base Metrics   | 百分比 #,##0% | This Period 期末库存金额占比                                                     |
| 7    | Top Size Inventory LP EOH Amt% Value      | Base Metrics   | 百分比 #,##0% | Last Period 期末库存金额占比                                                     |
| 8    | Top Size Inventory EOH Amt% vs LP Value   | Base Metrics   | 小数          | 占比差值（bp 原值）                                                              |
| 9    | Top Size Sales SLS Amt% Display           | Formatting     | 文本          | SLS Amt% 格式化显示                                                              |
| 10   | Top Size Sales LP SLS Amt% Display        | Formatting     | 文本          | LP SLS Amt% 格式化显示                                                           |
| 11   | Top Size Sales SLS Amt% vs LP Display     | Formatting     | 文本          | vs LP 转 bp 显示（26bp / -80bp / 0bp）                                           |
| 12   | Top Size Inventory EOH Amt% Display       | Formatting     | 文本          | EOH Amt% 格式化显示                                                              |
| 13   | Top Size Inventory LP EOH Amt% Display    | Formatting     | 文本          | LP EOH Amt% 格式化显示                                                           |
| 14   | Top Size Inventory EOH Amt% vs LP Display | Formatting     | 文本          | vs LP 转 bp 显示（26bp / -80bp / 0bp）                                           |
| 15   | Top Size Sales SLS Amt Value              | Base Metrics   | 数值          | 当期净销售金额具体值（排序键分组金额 / 验证用）                                  |
| 16   | Top Size Inventory EOH Amt Value          | Base Metrics   | 数值          | 当期期末库存金额具体值（时点数，排序键分组金额 / 验证用）                        |
| 17   | Top Size Sales Sort Key                   | Rank           | 整数          | Sales 表格行排序键（字母尺码 > 数字尺码 > 其余，组内占比升序，并列按尺码名决胜） |
| 18   | Top Size Inventory Sort Key               | Rank           | 整数          | Inventory 表格行排序键（规则同 Sales，并列按尺码名决胜）                         |

> 表格视觉对象值区域的绑定选择见 §7：占比两列绑定 Value（数值格式 + 数据条），vs LP 列绑定 Display（文本 bp 后缀）；Display 层全部输出，占比列如无需数据条可整体改绑 Display。

---

## 6. 血缘关系图

```
┌─────────────────────────────────────────────────────────────────────┐
│                        数据源层                                      │
│  s02_trade_sku_data_d（销售类，dt 日粒度）                            │
│  字段: dt, platform, shop_name, division, category,                  │
│        sku_size_category, sku_size, net_sales_amt                    │
│        （net_sales_amt = ROUND(product_qty × sales_price, 6)）       │
│  s02_inventory_stock_sales_detail_d（库存类，dt 日快照）              │
│  字段: dt, division, category, sku_size_category, sku_size,          │
│        msrp_inv_amt（无 platform / shop_name）                        │
└──────────────────────────────┬──────────────────────────────────────┘
                               │ Platform / Store Name / Division
                               │ 一对多关联自动传递（无需 DAX）
                               ▼
┌─────────────────────────────────────────────────────────────────────┐
│                        度量值层                                      │
│                                                                     │
│  ┌─────────────────────────────┐  ┌─────────────────────────────┐   │
│  │ Top Size Sales              │  │ Top Size Inventory          │   │
│  │ Category Rank               │  │ Category Rank               │   │
│  │ (This Period 区间净销售排名) │  │ (This Period 期末库存排名)   │   │
│  └──────────────┬──────────────┘  └──────────────┬──────────────┘   │
│                 │ 视觉级筛选器 = 1~4              │                  │
│                 ▼                                 ▼                  │
│  ┌─────────────────────────────┐  ┌─────────────────────────────┐   │
│  │ SLS Amt% Value              │  │ EOH Amt% Value              │   │
│  │ LP SLS Amt% Value           │  │ LP EOH Amt% Value           │   │
│  │ SLS Amt% vs LP Value        │  │ EOH Amt% vs LP Value        │   │
│  │ SLS Amt Value / Sort Key    │  │ EOH Amt Value / Sort Key    │   │
│  │ (分子分母 + REMOVEFILTERS)   │  │ (期末快照日单日时点)         │   │
│  └──────────────┬──────────────┘  └──────────────┬──────────────┘   │
│                 ▼                                 ▼                  │
│  ┌─────────────────────────────┐  ┌─────────────────────────────┐   │
│  │ SLS Amt% / LP SLS Amt% /    │  │ EOH Amt% / LP EOH Amt% /    │   │
│  │ vs LP Display (×10000 转 bp) │  │ vs LP Display (×10000 转 bp) │   │
│  └─────────────────────────────┘  └─────────────────────────────┘   │
│                    ▲ Slicer_Time_Frame_Min/Max_This                   │
│                    ▲ Slicer_Time_Frame_Min/Max_Last                   │
│                      （断开维度，DAX 显式时间筛选）                     │
└─────────────────────────────────────────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────────┐
│                        可视化层（表格 × 8）                           │
│  Sales 表格 1~4:                                                     │
│    列: s02_trade_sku_data_d[category] > [sku_size_category] >        │
│        [sku_size]                                                    │
│    值: SLS Amt% Value / LP SLS Amt% Value /                          │
│        SLS Amt% vs LP Display / Sales Sort Key（升序排序）           │
│    视觉级筛选: Sales Category Rank = N 且 SLS Amt% Value 不为空       │
│  Inventory 表格 1~4:                                                 │
│    列: s02_inventory_stock_sales_detail_d[category] >                 │
│        [sku_size_category] > [sku_size]                              │
│    值: EOH Amt% Value / LP EOH Amt% Value /                          │
│        EOH Amt% vs LP Display / Inventory Sort Key（升序排序）       │
│    视觉级筛选: Inventory Category Rank = N 且 EOH Amt% Value 不为空   │
│  Sales / Inventory 视图切换: 按钮 + 书签控制两组表格显示 / 隐藏        │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 7. 表格视觉对象配置

### 7.1 Sales 表格（4 个并排）

| 配置项       | 内容                                                                                                                                               |
| ------------ | -------------------------------------------------------------------------------------------------------------------------------------------------- |
| 列字段       | s02_trade_sku_data_d[category] → [sku_size_category] → [sku_size]（三列并列，行粒度为 size）                                                     |
| 值 1         | [Top Size Sales SLS Amt% Value]（列格式 #,##0%，绑定数据条深蓝#1F4E79）                                                                            |
| 值 2         | [Top Size Sales LP SLS Amt% Value]（列格式 #,##0%，绑定数据条中蓝#5B9BD5）                                                                         |
| 值 3         | [Top Size Sales SLS Amt% vs LP Display]（文本 bp 后缀，如 26bp / -80bp / 0bp）                                                                     |
| 值 4         | [Top Size Sales Sort Key]（排序辅助列，置于最后一列并收窄列宽）                                                                                    |
| 排序         | 点击 Sort Key 列标题按升序排序：字母尺码分组 → 数字尺码分组 → 其余分组（按分组当期金额降序），组内按 SLS Amt% 升序（占比并列时按尺码名升序决胜） |
| 视觉级筛选器 | [Top Size Sales Category Rank] 为 N（表格 1→1，表格 2→2，表格 3→3，表格 4→4）                                                                  |
| 视觉级筛选器 | [Top Size Sales SLS Amt% Value] 不为空                                                                                                             |
| 视觉级筛选器 | 无需为 category 添加空白/空字符筛选：Rank 度量值内部已排除，且该列视觉级筛选会被候选集 ALL(category) 移除、对排名无效                              |
| 显示元素     | 关闭总计；数据条最小值固定 0、最大值自动（保证不同表格间条长可比）                                                                                 |

### 7.2 Inventory 表格（4 个并排）

| 配置项       | 内容                                                                                                                         |
| ------------ | ---------------------------------------------------------------------------------------------------------------------------- |
| 列字段       | s02_inventory_stock_sales_detail_d[category] → [sku_size_category] → [sku_size]                                            |
| 值 1         | [Top Size Inventory EOH Amt% Value]（列格式 #,##0%，数据条深蓝#1F4E79）                                                      |
| 值 2         | [Top Size Inventory LP EOH Amt% Value]（列格式 #,##0%，数据条中蓝#5B9BD5）                                                   |
| 值 3         | [Top Size Inventory EOH Amt% vs LP Display]（文本 bp 后缀）                                                                  |
| 值 4         | [Top Size Inventory Sort Key]（排序辅助列，置于最后一列并收窄列宽）                                                          |
| 排序         | 点击 Sort Key 列标题按升序排序（规则同 Sales：分组金额为当期期末库存金额，组内按 EOH Amt% 升序，占比并列时按尺码名升序决胜） |
| 视觉级筛选器 | [Top Size Inventory Category Rank] 为 N                                                                                      |
| 视觉级筛选器 | [Top Size Inventory EOH Amt% Value] 不为空                                                                                   |
| 显示元素     | 关闭总计；数据条最小值固定 0、最大值自动                                                                                     |

### 7.3 数据条说明

- 占比两列（SLS Amt% / LP SLS Amt%、EOH Amt% / LP EOH Amt%）绑定数值型 Value 度量值并配置条件格式数据条；文本型 Display 度量值不支持数据条
- vs LP 列为文本 bp 显示，不配置数据条；如需正负着色，可对该列追加字体颜色条件格式（正值 #1A9018 / 负值 #D64550 / 零值 #E1C233，或统一灰色 #5F6165）
- 各表格数据条最小值统一固定为 0：四个表格为不同 category 的占比结构，固定下限保证条长在同一标尺下可比

### 7.4 Sales / Inventory 视图切换

- 页面放置 Sales / Inventory 两个按钮，分别关联两组书签：书签 A 仅显示 Sales 表格 1~4（隐藏 Inventory 表格），书签 B 仅显示 Inventory 表格 1~4
- 两组表格的视觉级筛选器与度量值相互独立（Rank、Value、Display 均按视图分套），切换不产生口径串扰
- 显隐控制仅涉及视觉对象显示状态，不影响日期 / 渠道 / Division 筛选器的公共作用

---

## 8. 注意事项

1. **inv 表无渠道字段**：s02_inventory_stock_sales_detail_d 无 platform / shop_name 字段，Inventory 全部指标（EOH Amt% / LP EOH Amt% / vs LP）与 Inventory Top4 排名不受 Platform / Store Name 筛选影响，仅受 date + Division 影响；Sales 全部指标受 date + Platform + Store Name + Division 四组筛选影响。该口径限制已与业务确认。
2. **期末时点只取单日**：EOH 系列分子分母取 end period 范围内最后一个快照日的单日值；快照表按日存储，对整段区间求和会把库存重复计数。快照缺数时在 end period 窗口内自动回退到最近一天（口径定义为 this period / last period 最后一天，两者最后一个自然日一致）。
3. **快照日 REMOVEFILTERS 机制**：__EndPeriodDate 用 REMOVEFILTERS(整表) 计算，保证快照日不随 Division / category / size 行上下文或切片器漂移，全表确定性取值。
4. **Top4 排名的筛选范围**：Rank 度量值中 ALL(category) 仅移除 category 列筛选，Platform / Store Name（Sales 侧）/ Division 筛选保留，排名是当前筛选组合下的排名；空白与空字符 category（数据中 NULL 与 "" 并存，空字符金额最大）在度量值内部用 LEN(TRIM()) > 0 排除，不参与排名。注意：视觉级 category 筛选器会被候选集的 ALL(category) 移除而无法影响排名，空白排除必须在度量值内部实现。
5. **并列排名**：RANKX 默认竞争排名（如 1、1、3），若第 4 名金额并列，rank = 4 的 category 可能多于一个，对应表格会同时显示并列 category 的行；口径未定义并列处理规则，按默认竞争排名实现。
6. **行显示范围与空值边界**：「Value 不为空」视觉级筛选器排除当期真 BLANK（该组合当期无任何记录）的行；当期有记录但金额极小的行为零值/小值（非 BLANK），占比显示 0%，保留显示并按真实值（0.00x）参与组内升序排序。当期真空但 Last Period 有值的行会被该筛选器排除——若需展示此类行（承载上期信息），应移除该筛选器，由空值垫底规则（注意事项 17）将其排在分组最后，而非依赖零值语义。
7. **行排序（排序键）**：表格行序由 Sort Key 度量值控制（点击该列升序排序，机制见 §3.5）：L1 字母尺码分组 > 数字尺码分组 > 其余（同优先级按分组当期金额降序），L3 组内按占比值升序（同一分组内分母相同，占比升序与金额升序等价），L4 并列决胜按 sku_size 名称字典序升序保证排序键全局唯一。如需改为业务尺码序（XXS → XS → S → M、0 → 1 → 2 …），需在 Power Query 为 sku_size 生成排序列并调整排序键 L3 编码（口径未定义，暂按占比升序）。
8. **日期筛选器依赖**：SELECTEDVALUE(Slicer_Time_Frame_Min_This[TimeFrame_Min]) 等依赖日期切片器保持单选且必选；切片器未选或多选时时间边界为 BLANK，指标不可用（与看板既有日期筛选器使用方式一致）。
9. **vs LP 边界规则**：this period 与 last period 任一期占比为 BLANK 时，差值返回 BLANK（显示 "-"），避免单侧缺失产生失真差值；差值 bp 的 ×10000 转换只在 Display 层实现，Value 层保留原始小数可复用。
10. **DIVIDE 空值保护**：占比分母（该 category + size category 层级金额）为空或 0 时 DIVIDE 返回 BLANK，显示 "-"。
11. **DAX 语法规范**：文本常量使用双引号，单引号仅用于表名，列名使用方括号；与口径文档存在争议时一切以口径文档为准。
12. **排名候选集口径一致**：Rank 度量值中 __Ranking 候选集的 @Amt 与 __CurrentCategoryAmt 必须同为 category 粒度（CALCULATE 内显式 ALL(sku_size_category, sku_size) 移除表格行残留的尺码筛选）。上下文转换只添加候选 category 筛选、不清除行残留的 sku_size_category / sku_size 筛选，若候选金额被限制在当前行尺码内而对比值为 category 全尺码金额，RANKX 将恒返回 1，导致视觉级筛选器 Rank = 1 放行全部行。
13. **Rank 显示值的上下文差异（验证现象）**：视觉级筛选器对 Rank 的取值发生在筛选生效前（筛选器不对自身生效），Top1~Top4 表格按真实排名 1~4 保留行；筛选生效后视觉内仅剩单个 category，此时拖入表格验证的 Rank 显示值在筛选后上下文中重新评估——__Ranking 候选中其余 category 与视觉级组合筛选（category + sku_size_category + sku_size）冲突取 BLANK，唯一保留的 category 在剩余候选中排名第一，故四个表格拖入 Rank 均显示 1。该现象不影响筛选正确性；验证真实排名需临时移除该视觉级筛选器。Rank 为视觉级筛选辅助度量，不建议作为列展示给最终用户。
14. **排序键使用限制**：排序键度量必须位于表格值区域才能作为排序依据（无法隐藏，建议置于最后一列并收窄列宽）；编码系数（1e9 / 1e6 / 1e3 / 1）要求单表格内分组数与单分组内 size 数均 < 1,000，超出时需按 10 倍调大系数；升序 RANKX 中 BLANK 候选会被计为更小值（BLANK < 任意正数），L3 组内排名候选必须 FILTER 排除 BLANK（组外 size / 无值 size），否则组内排名被虚增。
15. **组内排名并列语义与决胜**：L3 为 RANKX 竞争排名（SKIP），占比精确相等的行共享名次且下一有效名次跳号（并列第 3 则无第 4），属预期行为而非计算错误；同分组分母相同，占比相等 ⟺ 当期金额分毫不差，占比列展示值经四舍五入、需以未舍入值判断是否真并列。L4 按 sku_size 名称字典序决胜保证排序键全局唯一、行序确定；若不同尺码当期金额分毫不差，建议同步核查源数据是否存在尺码标签错位或重复行（真实数据中精确到分相同的概率极低）。
16. **视觉级度量筛选器污染候选迭代（已修复）**：Rank = N 视觉级筛选器落地为对 (category, sku_size_category, sku_size) 的跨列组合筛选，度量值内部候选迭代（RANKX/ADDCOLUMNS 的上下文转换）与该组合筛选取交集时，**当前行自身的 size 候选会在 RANKX 迭代阶段取 BLANK**，升序排名中被计入“小于当前值”，导致该行名次虚增 1（实证：XXL 行 PctRank 2→3、Sort Key 1002→1003，仅受影响行出错、其余行全对，取消筛选器后恢复正确——与注意事项 13 的 Rank 显示恒 1 同源）。修复：候选值计算用 REMOVEFILTERS(三列组合) 清除复合筛选（不能只 ALL/REMOVEFILTERS 单列，也不能 REMOVEFILTERS 整表否则连外部筛选一并丢失）+ TREATAS 重建候选三元组，一次计算物化为列后 FILTER 与 RANKX 共用，消除两阶段不一致。注意事项 13 的 Rank 恒 1 现象不受此修复影响（Rank 仅作筛选、显示值无需准确）。
17. **当期空值行排序与上期值口径**：① 空值垫底——当期占比真 BLANK 的行排序键 L3 用 1E15 哨兵值垫底（候选与 value 双侧同构，见 §3.5 空值垫底说明）；② LP 分母限定可见 size 集合（2026-10-15 业务确认，替代此前“分母含被过滤行上期金额”的旧结论）——LP 类 Value 分母经 REMOVEFILTERS(sku_size) 上卷至分组层级后，按 __VisibleSizes（This Period 有金额的 size，判定与「Value 不为空」筛选器一致）限定汇总范围：当期空、上期有值行（如上期 1.8%）的上期金额不进入 LP 分母，LP 占比基数 = 显示行汇总；限定在度量值内部实现，与页面是否配置「不为空」筛选器无关——过滤与否剩余行 LP 值一致；若保留空行显示（垫底），其 LP 行基于同一分母，显示行 LP% 合计可超 100%（基数不含未显示贡献）；当期占比无需同款限定（空行当期金额为 0，全量汇总与显示行汇总数值恒等）；③ 零值与真空区分：占比 0%（有记录、金额极小）非空，不会被「不为空」筛选器排除，也不适用垫底规则。
