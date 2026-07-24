# Category Growth 指标口径提示词

> **Dashboard**: DCom Performance Media Operation Dashboard  
> **Tab**: Category Growth  
> **板块名称**: Framework/Super Season × Label × Category × channel × mix_msg  
> **数据底表**: `a05_e2e_paid_media_product_data_d`  
> **子模块说明**: 本板块统一名称下包含两个子模块，行维度不同，但各指标计算逻辑一致，无需拆分单独取数：
> - 子模块一：Framework × Label × Category ×  channel × mix_msg（行维度含 `framework`）
> - 子模块二：Super Season × Label × Category × channel × mix_msg（行维度含 `super_season`）
> **分组维度**: 两个子模块均按 `brand`（对应 Label）/ `category` 分组，并叠加各自首列行维度（子模块一为 `framework`，子模块二为 `super_season`）。下文指标表中统一以"按 framework/brand/category 分组"代表子模块一；子模块二将其中的 `framework` 替换为 `super_season`，其余逻辑相同。

---

## 全局逻辑

| 项目 | 内容 |
|---|---|
| **vs LP** | 本期/对比同期LP的指标 -1|
| **模块一** | Framework × Label × Category × channel × mix_msg 对应为表中五个字段, 分别为 framework/brand/category/channel/mix_msg ,筛选以此字段名称为准|
| **模块二** | Super Season × Label × Category × channel × mix_msg 对应为表中五个字段, 分别为 season /brand/category/channel/mix_msg ,筛选以此字段名称为准|
| **全局筛选** | 五个字段对应五个层次,在powerbi中1~4层级，即framework/brand/category/channel或者super_season/brand/category/channel，计算指标的时候必须加上mix_msg is null的筛选条件，第五个层级为mix_msg的时候，筛选mix_msg is not null|
| **参考DAX** | 可以参考以下DAX，使用ISINSCOPE函数判断当前行是否在5个维度中的某个层级，以此来计算指标|
```
Category Growth Cell Background Color =
// ========================================
// 度量值: Category Growth Cell Background Color
// 中文名: 品类增长单元格背景色
// Display Folder: Category Growth > Formatting
// 用途: 根据表行层级返回背景色（5 级层次）
// 表结构: 行维度 = framework/brand/category/channel/mix_msg（五级）
// 颜色层次:
//   第5层 mix_msg（五级） 明细行   -> #FFFFFF（白色）
//   第4层 channel 小计行  -> #FAF6F1（淡米色）
//   第3层 category 小计行 -> #F4ECE4（浅米色）
//   第2层 brand 小计行    -> #E6D9C7（中米色）
//   第1层 framework 行 + 总计行 -> #DBC6A8（深米色）
// 注意: 当 framework 下只有一个子级时，ISINSCOPE(brand) 也会返回 TRUE，
//       此时该行会被染成 brand 颜色（中米色），无法染成 framework 颜色（深米色）。
//       这是 Power BI 表阶梯式布局的已知限制，非代码问题。
// ========================================
    VAR __IsSeason = ISINSCOPE(a05_e2e_paid_media_product_data_d[mix_msg（五级）])
    VAR __IsChannel = ISINSCOPE(a05_e2e_paid_media_product_data_d[channel])
    VAR __IsCategory = ISINSCOPE(a05_e2e_paid_media_product_data_d[category])
    VAR __IsBrand = ISINSCOPE(a05_e2e_paid_media_product_data_d[brand])
    VAR __IsFramework = ISINSCOPE(a05_e2e_paid_media_product_data_d[framework])

    RETURN
        SWITCH(
            TRUE(),
            // ── 第5层：mix_msg（五级） 明细行 ────────
            // 特征：5 个 ISINSCOPE 全部 = TRUE
            __IsSeason, "#FFFFFF",

            // ── 第4层：channel 小计行 ─────────
            // 特征：Channel=T, Season=F
            __IsChannel, "#FAF6F1",

            // ── 第3层：category 小计行 ─────────
            // 特征：Category=T, Channel=F
            __IsCategory, "#F4ECE4",

            // ── 第2层：brand 小计行 ────────
            // 特征：Brand=T, Category=F
            __IsBrand, "#E6D9C7",

            // ── 第1层：framework 行 + 总计行 ────────
            // framework 行特征：Framework=T, Brand=F
            // 总计行特征：全部 = FALSE
            "#DBC6A8"
        )
```



---

## 1. EOH(OMS)% — 库存%

| 项目 | 内容 |
|---|---|
| **指标名称** | EOH(OMS)% / 库存% |
| **业务定义** | 库存占比 |
| **计算公式** | 该分组库存件数 / 总库存件数 |
| **分子** | `stock_qty`（该分组库存数量） |
| **分母** | `stock_qty`（全部分组合计、移除全部 5 个行维度） |
| **数据底表** | `a05_e2e_paid_media_product_data_d` |
| **筛选条件** | 按 framework/brand/category 分组 |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%;#,##0.0%;0.0%` |

---

## 2. Active IDs — 在推ID数量

| 项目 | 内容 |
|---|---|
| **指标名称** | Active IDs / 在推ID数量 |
| **业务定义** | 推广中SKU数，统计周期最后一天仍在推的商品ID去重计数 |
| **计算公式** | 获取当前时间周期的最大日期，然后对living_sku_cnt聚合SUM |
| **统计字段** | `living_sku_cnt` |
| **数据底表** | `a05_e2e_paid_media_product_data_d` |
| **筛选条件** | 需要判断层级，如果当前上下文在第5层级，则需要过滤其他四个层级字段值为ALL，在其他层级的时候逻辑一致，比如现在在framework层级，需要过滤brand、category、channel、mix_msg字段值为ALL |
| **具体逻辑** | 统计周期最后一天有 cost 记录的在推商品；
行维度结构：framework/season -> brand -> category -> channel -> mix_msg
第1层 framework：
按 framework 分组，限制 mix_msg is null and channel = 'ALL'
第2层 brand：
按 framework/brand 分组，限制 mix_msg is null and channel = 'ALL'
第3层 category：
按 framework/brand/category 分组，限制 mix_msg is null and channel = 'ALL'
第4层 channel：
按 framework/brand/category/channel 分组，限制 mix_msg is null，不限制 channel = 'ALL'
第5层 mix_msg：
按 framework/brand/category/channel/mix_msg 分组，channel 取当前渠道，mix_msg 取当前明细值 |
| **数据类型** | integer → 千分位整数，不含小数 |
| **数据格式** | `#,##0;(#,##0);0` |


---

## 3. Active IDs VS LP — 在推ID数量同期

| 项目 | 内容 |
|---|---|
| **指标名称** | Active IDs VS LP / 在推ID数量同期 |
| **业务定义** | 推广中SKU数，统计周期同期的最后一天仍在推的商品ID去重计数 |
| **计算公式** | YOY同比：本期值/同期(LP)统计周期最后一天对living_sku_cnt聚合SUM - 1 |
| **统计字段** | `living_sku_cnt` |
| **数据底表** | `a05_e2e_paid_media_product_data_d` |
| **筛选条件** | 同期 LP；也需要判断层级，如果当前上下文在第5层级，则需要过滤其他四个层级字段值为ALL，在其他层级的时候逻辑一致，比如现在在framework层级，需要过滤brand、category、channel、mix_msg字段值为ALL |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%;#,##0.0%;0.0%` |

---

## 4. Net Sales% — 退后销售额占比

| 项目 | 内容 |
|---|---|
| **指标名称** | Net Sales% / 退后销售额占比 |
| **业务定义** | 退后销售额占比 |
| **计算公式** | 品类 Net Sales / TTL Net Sales |
| **分子** | `net_sales_amt`（该品类） |
| **分母** | `net_sales_amt`（全店 TTL、移除全部 5 个行维度） |
| **数据底表** | `a05_e2e_paid_media_product_data_d` |
| **筛选条件** | 全局筛选的条件下直接 sum |
| **注意** | 注意带上全局筛选的条件 |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%;#,##0.0%;0.0%` |

---

## 5. SLS% VS LP — 后推销售额占比同期

| 项目 | 内容 |
|---|---|
| **指标名称** | SLS% VS LP / 后推销售额占比同期 |
| **业务定义** | 后推销售额占比同期 |
| **计算公式** | YOY同比：本期值/（品类 Net Sales / TTL Net Sales（同期 LP）） - 1 |
| **分子** | `net_sales_amt`（该品类，同期 LP） |
| **分母** | `net_sales_amt`（全店 TTL，同期 LP、移除全部 5 个行维度） |
| **数据底表** | `a05_e2e_paid_media_product_data_d` |
| **筛选条件** | 全局筛选的条件下直接 sum |
| **注意** | 注意带上全局筛选的条件 |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%;#,##0.0%;0.0%` |

---

## 6. Cost — 花费

| 项目 | 内容 |
|---|---|
| **指标名称** | Cost / 花费 |
| **业务定义** | 实际总媒体花费 |
| **计算公式** | 各品类推广花费加总 |
| **统计字段** | `cost_amt` |
| **数据底表** | `a05_e2e_paid_media_product_data_d` |
| **筛选条件** | 全局筛选的条件下直接 sum |
| **注意** | 注意带上全局筛选的条件 |
| **数据类型** | currency → 货币符号由币种切片器决定，千分位整数 |
| **数据格式** | `#,##0`（在 DAX 中用 `__CurrencySymbol & FORMAT(__Value, "#,##0")` 拼接币种符号） |

---

## 7. Cost VS LP — 花费同期

| 项目 | 内容 |
|---|---|
| **指标名称** | Cost VS LP / 花费同期 |
| **业务定义** | 同期实际总媒体花费 |
| **计算公式** | YOY同比：本期值/各品类推广花费（同期 LP）-1 |
| **统计字段** | `cost_amt` |
| **数据底表** | `a05_e2e_paid_media_product_data_d` |
| **筛选条件** | 同期 LP：全局筛选的条件下直接 sum  |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%;#,##0.0%;0.0%` |

---

## 8. Cost% — 花费占比

| 项目 | 内容 |
|---|---|
| **指标名称** | Cost% / 花费占比 |
| **业务定义** | 实际媒体花费占比总媒体花费的百分比 |
| **计算公式** | 品类 Cost / TTL Cost |
| **分子** | `cost_amt`（该品类） |
| **分母** | `cost_amt`（商品表 TTL、移除全部 5 个行维度） |
| **数据底表** | `a05_e2e_paid_media_product_data_d` |
| **筛选条件** | 按 framework/brand/category 分组 |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%;#,##0.0%;0.0%` |

---

## 9. Cost% VS LP — 花费 MOB% 同期

| 项目 | 内容 |
|---|---|
| **指标名称** | Cost% VS LP / 花费 MOB% 同期 |
| **业务定义** | 同期实际媒体花费占比总媒体花费的百分比 |
| **计算公式** | YOY同比：本期值/（品类 Cost / TTL Cost（同期 LP）） - 1 |
| **统计字段** | `cost_amt`（品类）/ `cost_amt`（TTL） |
| **数据底表** | `a05_e2e_paid_media_product_data_d` |
| **筛选条件** | 同期 LP |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%;#,##0.0%;0.0%` |

---

## 10. ROI — 媒体 ROI

| 项目 | 内容 |
|---|---|
| **指标名称** | ROI / 媒体 ROI |
| **业务定义** | 成交金额 / 花费，计算出 ROI |
| **计算公式** | 品类 Sales / 品类 Cost |
| **分子** | `media_sales_amt`（投放带来成交金额） |
| **分母** | `cost_amt`（品类花费） |
| **数据底表** | `a05_e2e_paid_media_product_data_d` |
| **筛选条件** | 按 framework/brand/category 分组 |
| **数据类型** | decimal_1dp → 数值，保留一位小数 |
| **数据格式** | `#,##0.0;-#,##0.0;0.0` |

---

## 11. ROI VS LP — 媒体 ROI 同期

| 项目 | 内容 |
|---|---|
| **指标名称** | ROI VS LP / 媒体 ROI 同期 |
| **业务定义** | 同期花费 / 同期成交金额，计算出 ROI |
| **计算公式** | YOY同比：本期值/（品类 Sales / 品类 Cost（同期 LP）） - 1 |
| **统计字段** | `media_sales_amt` / `cost_amt` |
| **数据底表** | `a05_e2e_paid_media_product_data_d` |
| **筛选条件** | 同期 LP |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%;#,##0.0%;0.0%` |

---

## 通用规则汇总

| 规则项 | 说明 |
|---|---|
| **数据底表** | 全部指标统一使用 `a05_e2e_paid_media_product_data_d` |
| **子模块** | 板块含两个子模块：Framework × Label × Category × Ads format、Super Season × Label × Category × Ads format；两者行维度不同但指标计算逻辑一致，仅个别指标有移除维度的差异，无需拆分取数 |
| **分组维度** | 均按 `brand`（对应 Label）/ `category` 分组，并叠加首列行维度：子模块一为 `framework`，子模块二为 `super_season` |
| **同期 LP** | 指标名带 "VS LP" 的表示同期对比，筛选条件为"同期 LP" |
| **在推商品判定** | 以统计周期最后一天有 cost 记录为准，使用 `living_sku_cnt` 统计 |
