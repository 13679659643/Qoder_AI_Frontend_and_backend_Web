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

| 层级 | 字段 | Sales 表格来源 | Inventory 表格来源 |
|---|---|---|---|
| 1 | Category | s02_trade_sku_data_d[category] | s02_inventory_stock_sales_detail_d[category] |
| 2 | Size Category | s02_trade_sku_data_d[sku_size_category] | s02_inventory_stock_sales_detail_d[sku_size_category] |
| 3 | Size | s02_trade_sku_data_d[sku_size] | s02_inventory_stock_sales_detail_d[sku_size] |

- **Sales Top4**：date + Platform + Store Name + Division 筛选组合下，按 category 粒度 This Period `sum(net_sales_amt)` 降序取前 4
- **Inventory Top4**：date + Division 筛选组合下，按 category 粒度 This Period 最后一天 `sum(msrp_inv_amt)` 降序取前 4
- 表格 1 = Top1 category，表格 2 = Top2 category，依次类推；通过表格视觉级筛选器（Rank 度量值 = N）实现

### 1.3 指标清单

| 视图 | 指标 | 计算公式 | 时间口径 | 数据类型 / 格式 |
|---|---|---|---|---|
| Sales | SLS Amt% | 分子：该 category + size category + size 下 `sum(net_sales_amt)`；分母：该 category + size category 下 `sum(net_sales_amt)` | This Period（区间） | percent_0dp → `#,##0%` |
| Sales | LP SLS Amt% | 分子分母同 SLS Amt%（last period 口径） | Last Period（区间） | percent_0dp → `#,##0%` |
| Sales | vs LP | SLS Amt% - LP SLS Amt%（差值，展示时 ×10000 转 bp） | — | integer_bp → `#,##0bp;-#,##0bp;0bp` |
| Inventory | EOH Amt% | 分子：该 category + size category + size 下 `sum(msrp_inv_amt)`；分母：该 category + size category 下 `sum(msrp_inv_amt)` | This Period 最后一天（时点） | percent_0dp → `#,##0%` |
| Inventory | LP EOH Amt% | 分子分母同 EOH Amt%（last period 口径） | Last Period 最后一天（时点） | percent_0dp → `#,##0%` |
| Inventory | vs LP | EOH Amt% - LP EOH Amt%（差值，展示时 ×10000 转 bp） | — | integer_bp → `#,##0bp;-#,##0bp;0bp` |

### 1.4 时间口径

| 口径 | 时间范围 | 适用指标 |
|---|---|---|
| This Period（区间类） | dt ∈ [Slicer_Time_Frame_Min_This[TimeFrame_Min], Slicer_Time_Frame_Max_This[TimeFrame_Max]] | SLS Amt% 分子分母、Sales Top4 排序 |
| Last Period（区间类） | dt ∈ [Slicer_Time_Frame_Min_Last[TimeFrame_Min], Slicer_Time_Frame_Max_Last[TimeFrame_Max]] | LP SLS Amt% 分子分母 |
| End Period（期末时点类） | end period 范围 [Slicer_Time_Frame_Max_This[TimeFrame_Min], Slicer_Time_Frame_Max_This[TimeFrame_Max]] 内**最后一个快照日** | EOH Amt% 分子分母、Inventory Top4 排序 |
| End Period LP（期末时点类） | end period 范围 [Slicer_Time_Frame_Max_Last[TimeFrame_Min], Slicer_Time_Frame_Max_Last[TimeFrame_Max]] 内**最后一个快照日** | LP EOH Amt% 分子分母 |

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

| 筛选器 | 条件 | 作用 |
|---|---|---|
| Top Size Sales Category Rank | 为 1 | 固定显示 Top1 category 的行（表格 2 为 2，依次类推） |
| Top Size Sales SLS Amt% Value | 不为空 | 仅显示 This Period 有销售数据的 category + size category + size 组合 |

（Inventory 表格对应使用 Top Size Inventory Category Rank 与 Top Size Inventory EOH Amt% Value）

Rank 度量值在 category / size category / size 任意层级行均返回所属 category 的排名：表格行字段为层级展开时，category 筛选在 size category 行与 size 行上依然存在，`SELECTEDVALUE(category)` 逐行可取值，保证 size 行同样被正确筛选。

### 3.3 占比口径分母层级

分母 = 该 category + size category 层级：分母计算中 `REMOVEFILTERS(sku_size)` 仅移除 size 行筛选，保留 category / size category 行筛选与外部切片器（Platform / Store Name / Division）筛选，分母与分子处于同一时间范围。

### 3.4 度量值命名与组织

- 命名规则：模块前缀 `Top Size` + 视图（Sales / Inventory）+ 指标名 + 层次后缀（Rank / Value / Display）
- Display Folder：`Top Size Sales Performance\Rank`、`Top Size Sales Performance\Base Metrics`、`Top Size Sales Performance\Formatting`
- 度量值统一存放于 `_Measures` 隐藏表（与看板既有组织方式一致）

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
//       返回所属 category 的排名；category 为空或本期无销售的组合排名靠后，
//       由视觉级筛选器（=1~4 且 Value 不为空）排除
// ========================================

// ── This Period 时间区间 ──
VAR __PeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Min_This[TimeFrame_Min])
VAR __PeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

// ── 当前行所属 category（层级展开下 category 筛选在任意层级行均存在）──
VAR __CurrentCategory = SELECTEDVALUE('s02_trade_sku_data_d'[category])

// ── 排名表：全部非空 category 及其 This Period 销售金额 ──
// ALL(category) 仅移除 category 列筛选；Platform / Store Name / Division 等外部筛选保留
VAR __Ranking =
    ADDCOLUMNS(
        FILTER(
            ALL('s02_trade_sku_data_d'[category]),
            NOT ISBLANK('s02_trade_sku_data_d'[category])
        ),
        "@Amt",
            CALCULATE(
                SUM('s02_trade_sku_data_d'[net_sales_amt]),
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

RETURN
    IF(
        NOT ISBLANK(__CurrentCategory),
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

// ── 排名表：全部非空 category 及其期末快照日库存金额 ──
VAR __Ranking =
    ADDCOLUMNS(
        FILTER(
            ALL('s02_inventory_stock_sales_detail_d'[category]),
            NOT ISBLANK('s02_inventory_stock_sales_detail_d'[category])
        ),
        "@Amt",
            CALCULATE(
                SUM('s02_inventory_stock_sales_detail_d'[msrp_inv_amt]),
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

RETURN
    IF(
        NOT ISBLANK(__CurrentCategory),
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
// 依赖: Slicer_Time_Frame_Min_Last[TimeFrame_Min] / Slicer_Time_Frame_Max_Last[TimeFrame_Max]
// 口径: 分子分母同 SLS Amt%，时间范围替换为 Last Period 筛选器
// 数据底表: s02_trade_sku_data_d
// ========================================

// ── Last Period 时间区间 ──
VAR __PeriodMin_LY = SELECTEDVALUE(Slicer_Time_Frame_Min_Last[TimeFrame_Min])
VAR __PeriodMax_LY = SELECTEDVALUE(Slicer_Time_Frame_Max_Last[TimeFrame_Max])

// ── 分子：当前行（category + size category + size）Last Period 净销售金额 ──
VAR __Numerator =
    CALCULATE(
        SUM('s02_trade_sku_data_d'[net_sales_amt]),
        's02_trade_sku_data_d'[dt] >= __PeriodMin_LY,
        's02_trade_sku_data_d'[dt] <= __PeriodMax_LY
    )

// ── 分母：该 category + size category 层级 Last Period 净销售金额 ──
VAR __Denominator =
    CALCULATE(
        SUM('s02_trade_sku_data_d'[net_sales_amt]),
        REMOVEFILTERS('s02_trade_sku_data_d'[sku_size]),
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
// 依赖: Slicer_Time_Frame_Max_Last[TimeFrame_Min] / [TimeFrame_Max]
// 口径: 分子分母同 EOH Amt%，时间范围看 last period 最后一天
//       （实现为 end period LP 范围内最后一个快照日）
// 数据底表: s02_inventory_stock_sales_detail_d
// ========================================

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

// ── 分子：当前行（category + size category + size）Last Period 期末库存金额 ──
VAR __Numerator =
    CALCULATE(
        SUM('s02_inventory_stock_sales_detail_d'[msrp_inv_amt]),
        's02_inventory_stock_sales_detail_d'[dt] = __EndPeriodDate_LY
    )

// ── 分母：该 category + size category 层级 Last Period 期末库存金额 ──
VAR __Denominator =
    CALCULATE(
        SUM('s02_inventory_stock_sales_detail_d'[msrp_inv_amt]),
        REMOVEFILTERS('s02_inventory_stock_sales_detail_d'[sku_size]),
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

---

## 5. 度量值清单与 Display Folder

| 序号 | 度量值名称 | Display Folder | 模型格式 | 用途 |
|---|---|---|---|---|
| 1 | Top Size Sales Category Rank | Rank | 整数 | Sales Top4 category 排名（视觉级筛选器） |
| 2 | Top Size Inventory Category Rank | Rank | 整数 | Inventory Top4 category 排名（视觉级筛选器） |
| 3 | Top Size Sales SLS Amt% Value | Base Metrics | 百分比 #,##0% | This Period 销售金额占比 |
| 4 | Top Size Sales LP SLS Amt% Value | Base Metrics | 百分比 #,##0% | Last Period 销售金额占比 |
| 5 | Top Size Sales SLS Amt% vs LP Value | Base Metrics | 小数 | 占比差值（bp 原值） |
| 6 | Top Size Inventory EOH Amt% Value | Base Metrics | 百分比 #,##0% | This Period 期末库存金额占比 |
| 7 | Top Size Inventory LP EOH Amt% Value | Base Metrics | 百分比 #,##0% | Last Period 期末库存金额占比 |
| 8 | Top Size Inventory EOH Amt% vs LP Value | Base Metrics | 小数 | 占比差值（bp 原值） |
| 9 | Top Size Sales SLS Amt% Display | Formatting | 文本 | SLS Amt% 格式化显示 |
| 10 | Top Size Sales LP SLS Amt% Display | Formatting | 文本 | LP SLS Amt% 格式化显示 |
| 11 | Top Size Sales SLS Amt% vs LP Display | Formatting | 文本 | vs LP 转 bp 显示（26bp / -80bp / 0bp） |
| 12 | Top Size Inventory EOH Amt% Display | Formatting | 文本 | EOH Amt% 格式化显示 |
| 13 | Top Size Inventory LP EOH Amt% Display | Formatting | 文本 | LP EOH Amt% 格式化显示 |
| 14 | Top Size Inventory EOH Amt% vs LP Display | Formatting | 文本 | vs LP 转 bp 显示（26bp / -80bp / 0bp） |

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
│        SLS Amt% vs LP Display                                        │
│    视觉级筛选: Sales Category Rank = N 且 SLS Amt% Value 不为空       │
│  Inventory 表格 1~4:                                                 │
│    列: s02_inventory_stock_sales_detail_d[category] >                 │
│        [sku_size_category] > [sku_size]                              │
│    值: EOH Amt% Value / LP EOH Amt% Value /                          │
│        EOH Amt% vs LP Display                                        │
│    视觉级筛选: Inventory Category Rank = N 且 EOH Amt% Value 不为空   │
│  Sales / Inventory 视图切换: 按钮 + 书签控制两组表格显示 / 隐藏        │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 7. 表格视觉对象配置

### 7.1 Sales 表格（4 个并排）

| 配置项 | 内容 |
|---|---|
| 列字段 | s02_trade_sku_data_d[category] → [sku_size_category] → [sku_size]（三列并列，行粒度为 size） |
| 值 1 | [Top Size Sales SLS Amt% Value]（列格式 #,##0%，绑定数据条深蓝 #1F4E79） |
| 值 2 | [Top Size Sales LP SLS Amt% Value]（列格式 #,##0%，绑定数据条中蓝 #5B9BD5） |
| 值 3 | [Top Size Sales SLS Amt% vs LP Display]（文本 bp 后缀，如 26bp / -80bp / 0bp） |
| 视觉级筛选器 | [Top Size Sales Category Rank] 为 N（表格 1→1，表格 2→2，表格 3→3，表格 4→4） |
| 视觉级筛选器 | [Top Size Sales SLS Amt% Value] 不为空 |
| 显示元素 | 关闭总计；数据条最小值固定 0、最大值自动（保证不同表格间条长可比） |

### 7.2 Inventory 表格（4 个并排）

| 配置项 | 内容 |
|---|---|
| 列字段 | s02_inventory_stock_sales_detail_d[category] → [sku_size_category] → [sku_size] |
| 值 1 | [Top Size Inventory EOH Amt% Value]（列格式 #,##0%，数据条深蓝 #1F4E79） |
| 值 2 | [Top Size Inventory LP EOH Amt% Value]（列格式 #,##0%，数据条中蓝 #5B9BD5） |
| 值 3 | [Top Size Inventory EOH Amt% vs LP Display]（文本 bp 后缀） |
| 视觉级筛选器 | [Top Size Inventory Category Rank] 为 N |
| 视觉级筛选器 | [Top Size Inventory EOH Amt% Value] 不为空 |
| 显示元素 | 关闭总计；数据条最小值固定 0、最大值自动 |

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
4. **Top4 排名的筛选范围**：Rank 度量值中 ALL(category) 仅移除 category 列筛选，Platform / Store Name（Sales 侧）/ Division 筛选保留，排名是当前筛选组合下的排名；category 为空的组合不参与排名。
5. **并列排名**：RANKX 默认竞争排名（如 1、1、3），若第 4 名金额并列，rank = 4 的 category 可能多于一个，对应表格会同时显示并列 category 的行；口径未定义并列处理规则，按默认竞争排名实现。
6. **行显示范围**：「Value 不为空」视觉级筛选器保证表格只显示 This Period 有数据（Sales 有销售 / Inventory 有库存快照）的 category + size category + size 组合；This Period 无数据但 Last Period 有数据的组合不显示（vs LP 相应显示 "-" 的场景仅出现在分子分母单侧为空的行内）。
7. **行排序**：sku_size_category / sku_size 无业务排序字段，表格默认按字段名升序；如需业务尺码序（XXS → XS → S → M、0 → 1 → 2 …），需在 Power Query 为两列生成排序列并按排序列排序（口径未定义，默认字母序）。
8. **日期筛选器依赖**：SELECTEDVALUE(Slicer_Time_Frame_Min_This[TimeFrame_Min]) 等依赖日期切片器保持单选且必选；切片器未选或多选时时间边界为 BLANK，指标不可用（与看板既有日期筛选器使用方式一致）。
9. **vs LP 边界规则**：this period 与 last period 任一期占比为 BLANK 时，差值返回 BLANK（显示 "-"），避免单侧缺失产生失真差值；差值 bp 的 ×10000 转换只在 Display 层实现，Value 层保留原始小数可复用。
10. **DIVIDE 空值保护**：占比分母（该 category + size category 层级金额）为空或 0 时 DIVIDE 返回 BLANK，显示 "-"。
11. **DAX 语法规范**：文本常量使用双引号，单引号仅用于表名，列名使用方括号；与口径文档存在争议时一切以口径文档为准。
