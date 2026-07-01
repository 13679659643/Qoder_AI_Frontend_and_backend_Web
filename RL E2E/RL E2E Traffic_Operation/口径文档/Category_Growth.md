# Category Growth 指标口径提示词

> **Dashboard**: DCom Performance Media Operation Dashboard  
> **Tab**: Category Growth  
> **板块名称**: Framework/Super Season × Label × Category × Ads format  
> **数据底表**: `a05_e2e_paid_media_product_data`  
> **子模块说明**: 本板块统一名称下包含两个子模块，行维度不同，但各指标计算逻辑一致，无需拆分单独取数：
> - 子模块一：Framework × Label × Category × Ads format（行维度含 `framework`）
> - 子模块二：Super Season × Label × Category × Ads format（行维度含 `super_season`）
> **分组维度**: 两个子模块均按 `brand`（对应 Label）/ `category` 分组，并叠加各自首列行维度（子模块一为 `framework`，子模块二为 `super_season`）。下文指标表中统一以"按 framework/brand/category 分组"代表子模块一；子模块二将其中的 `framework` 替换为 `super_season`，其余逻辑相同。

---

## 1. EOH(OMS)% — 库存%

| 项目 | 内容 |
|---|---|
| **指标名称** | EOH(OMS)% / 库存% |
| **业务定义** | 库存占比 |
| **计算公式** | 该分组库存件数 / 总库存件数 |
| **分子** | `stock_qty`（该分组库存数量） |
| **分母** | `stock_qty`（全部分组合计） |
| **数据底表** | `a05_e2e_paid_media_product_data` |
| **筛选条件** | 按 framework/brand/category 分组 |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%;#,##0.0%;0.0%` |

---

## 2. Active IDs — 在推ID数量

| 项目 | 内容 |
|---|---|
| **指标名称** | Active IDs / 在推ID数量 |
| **业务定义** | 推广中SKU数，统计周期最后一天仍在推的商品ID去重计数 |
| **计算公式** | 统计周期最后一天有 cost 记录的在推商品数（ADS 层无 promotion_id，用 `living_sku_cnt`） |
| **统计字段** | `living_sku_cnt` |
| **数据底表** | `a05_e2e_paid_media_product_data` |
| **筛选条件** | 统计周期最后一天有 cost 记录的在推商品；按 framework/brand/category 分组 |
| **数据类型** | integer → 千分位整数，不含小数 |
| **数据格式** | `#,##0` |

---

## 3. Active IDs VS LP — 在推ID数量同期

| 项目 | 内容 |
|---|---|
| **指标名称** | Active IDs VS LP / 在推ID数量同期 |
| **业务定义** | 推广中SKU数，统计周期同期的最后一天仍在推的商品ID去重计数 |
| **计算公式** | 同期(LP)统计周期最后一天有 cost 记录的在推商品数（ADS 层无 promotion_id，用 `living_sku_cnt`） |
| **统计字段** | `living_sku_cnt` |
| **数据底表** | `a05_e2e_paid_media_product_data` |
| **筛选条件** | 同期 LP；统计周期最后一天有 cost 记录的在推商品 |
| **数据类型** | integer → 千分位整数，不含小数 |
| **数据格式** | `#,##0` |

---

## 4. Net Sales% — 退后销售额占比

| 项目 | 内容 |
|---|---|
| **指标名称** | Net Sales% / 退后销售额占比 |
| **业务定义** | 退后销售额占比 |
| **计算公式** | 品类 Net Sales / TTL Net Sales |
| **分子** | `net_sales_amt`（该品类） |
| **分母** | `net_sales_amt`（全店 TTL） |
| **数据底表** | `a05_e2e_paid_media_product_data` |
| **筛选条件** | **不可直接 sum**，根据商品属性 max 之后再求和 |
| **注意** | 分子、分母均需先按商品属性取 max 后再求和，不可直接对明细行 sum |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%;#,##0.0%;0.0%` |

---

## 5. Net Sales% VS LP — 退后销售额占比同期

| 项目 | 内容 |
|---|---|
| **指标名称** | Net Sales% VS LP / 退后销售额占比同期 |
| **业务定义** | 退后销售额占比同期 |
| **计算公式** | 品类 Net Sales / TTL Net Sales（同期 LP） |
| **分子** | `net_sales_amt`（该品类，同期 LP） |
| **分母** | `net_sales_amt`（全店 TTL，同期 LP） |
| **数据底表** | `a05_e2e_paid_media_product_data` |
| **筛选条件** | 同期 LP；**不可直接 sum**，根据商品属性 max 之后再求和 |
| **注意** | 与第4项一致，分子、分母均需先按商品属性取 max 后再求和，不可直接对明细行 sum |
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
| **数据底表** | `a05_e2e_paid_media_product_data` |
| **筛选条件** | 按 framework/brand/category 分组 |
| **数据类型** | currency → 货币符号由币种切片器决定，千分位整数 |
| **数据格式** | `#,##0`（在 DAX 中用 `__CurrencySymbol & FORMAT(__Value, "#,##0")` 拼接币种符号） |

---

## 7. Cost VS LP — 花费同期

| 项目 | 内容 |
|---|---|
| **指标名称** | Cost VS LP / 花费同期 |
| **业务定义** | 同期实际总媒体花费 |
| **计算公式** | 各品类推广花费（同期 LP） |
| **统计字段** | `cost_amt` |
| **数据底表** | `a05_e2e_paid_media_product_data` |
| **筛选条件** | 同期 LP |
| **数据类型** | currency → 货币符号由币种切片器决定，千分位整数 |
| **数据格式** | `#,##0`（在 DAX 中用 `__CurrencySymbol & FORMAT(__Value, "#,##0")` 拼接币种符号） |

---

## 8. Cost% — 花费占比

| 项目 | 内容 |
|---|---|
| **指标名称** | Cost% / 花费占比 |
| **业务定义** | 实际媒体花费占比总媒体花费的百分比 |
| **计算公式** | 品类 Cost / TTL Cost |
| **分子** | `cost_amt`（该品类） |
| **分母** | `cost_amt`（商品表 TTL） |
| **数据底表** | `a05_e2e_paid_media_product_data` |
| **筛选条件** | 按 framework/brand/category 分组 |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%;#,##0.0%;0.0%` |

---

## 9. Cost% VS LP — 花费 MOB% 同期

| 项目 | 内容 |
|---|---|
| **指标名称** | Cost% VS LP / 花费 MOB% 同期 |
| **业务定义** | 同期实际媒体花费占比总媒体花费的百分比 |
| **计算公式** | 品类 Cost / TTL Cost（同期 LP） |
| **统计字段** | `cost_amt`（品类）/ `cost_amt`（TTL） |
| **数据底表** | `a05_e2e_paid_media_product_data` |
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
| **数据底表** | `a05_e2e_paid_media_product_data` |
| **筛选条件** | 按 framework/brand/category 分组 |
| **数据类型** | decimal_1dp → 数值，保留一位小数 |
| **数据格式** | `#,##0.0` |

---

## 11. ROI VS LP — 媒体 ROI 同期

| 项目 | 内容 |
|---|---|
| **指标名称** | ROI VS LP / 媒体 ROI 同期 |
| **业务定义** | 同期花费 / 同期成交金额，计算出 ROI |
| **计算公式** | 品类 Sales / 品类 Cost（同期 LP） |
| **统计字段** | `media_sales_amt` / `cost_amt` |
| **数据底表** | `a05_e2e_paid_media_product_data` |
| **筛选条件** | 同期 LP |
| **数据类型** | decimal_1dp → 数值，保留一位小数 |
| **数据格式** | `#,##0.0` |

---

## 通用规则汇总

| 规则项 | 说明 |
|---|---|
| **数据底表** | 全部指标统一使用 `a05_e2e_paid_media_product_data` |
| **子模块** | 板块含两个子模块：Framework × Label × Category × Ads format、Super Season × Label × Category × Ads format；两者行维度不同但指标计算逻辑一致，无需拆分取数 |
| **分组维度** | 均按 `brand`（对应 Label）/ `category` 分组，并叠加首列行维度：子模块一为 `framework`，子模块二为 `super_season` |
| **同期 LP** | 指标名带 "VS LP" 的表示同期对比，筛选条件为"同期 LP" |
| **Net Sales 特殊处理** | `net_sales_amt` 不可直接 sum，需先按商品属性取 max 后再求和（含 Net Sales% 及 Net Sales% VS LP） |
| **在推商品判定** | 以统计周期最后一天有 cost 记录为准，使用 `living_sku_cnt` 统计 |
| **数据格式规则** | 花费类（Cost、Cost VS LP）用 `currency`（`#,##0`，币种符号由切片器决定）；占比类（EOH(OMS)%、Net Sales% 及 VS LP、Cost% 及 VS LP）用 `percent_1dp`（`#,##0.0%`，不含正号）；ROI 及 ROI VS LP 用 `decimal_1dp`（`#,##0.0`）；数量类（Active IDs 及 VS LP）用 `integer`（`#,##0`）；所有小数均保留一位 |
