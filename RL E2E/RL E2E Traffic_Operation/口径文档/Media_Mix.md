# Media Mix 指标口径提示词

> **Dashboard**: DCom Performance Media Operation Dashboard  
> **Tab**: Media Mix  
> **板块名称**: Media Mix Details-This Period TM/JD（vs Last Period）  
> **数据底表**: `a05_e2e_paid_media_channel_data`  
> **分组维度**: 按 channel / 广告点位 分组

---

## 1. Cost — 花费

| 项目 | 内容 |
|---|---|
| **指标名称** | Cost / 花费 |
| **业务定义** | 实际总媒体花费 |
| **计算公式** | 各渠道花费加总（by channel） |
| **统计字段** | `cost_amt` |
| **数据底表** | `a05_e2e_paid_media_channel_data` |
| **筛选条件** | 按 channel / 广告点位 分组 |
| **数据类型** | currency → 货币符号由币种切片器决定，千分位整数 |
| **数据格式** | `#,##0`（在 DAX 中用 `__CurrencySymbol & FORMAT(__Value, "#,##0")` 拼接币种符号） |

---

## 2. Cost% — 花费占比

| 项目 | 内容 |
|---|---|
| **指标名称** | Cost% / 花费占比 |
| **业务定义** | 实际媒体花费占比总媒体花费的百分比 |
| **计算公式** | 渠道 Cost / TTL Cost |
| **分子** | `cost_amt`（该 channel） |
| **分母** | `cost_amt`（所有 channel 合计） |
| **数据底表** | `a05_e2e_paid_media_channel_data` |
| **筛选条件** | 按 channel / 广告点位 分组 |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%;#,##0.0%;0.0%` |

---

## 3. ROI — 媒体 ROI

| 项目 | 内容 |
|---|---|
| **指标名称** | ROI / 媒体 ROI |
| **业务定义** | 成交金额 / 花费，计算出 ROI |
| **计算公式** | Sales / Cost |
| **分子** | `media_sales_amt`（成交金额，投放带来） |
| **分母** | `cost_amt`（花费） |
| **数据底表** | `a05_e2e_paid_media_channel_data` |
| **筛选条件** | 按 channel / 广告点位 分组 |
| **数据类型** | decimal_1dp → 数值，保留一位小数 |
| **数据格式** | `#,##0.0` |

---

## 4. Impression — 展现量

| 项目 | 内容 |
|---|---|
| **指标名称** | Impression / 展现量 |
| **业务定义** | 展现量 |
| **计算公式** | 各渠道展示量加总 |
| **统计字段** | `pv` |
| **数据底表** | `a05_e2e_paid_media_channel_data` |
| **筛选条件** | 按 channel / 广告点位 分组 |
| **数据类型** | integer → 千分位整数，不含小数 |
| **数据格式** | `#,##0` |

---

## 5. Click — 点击量

| 项目 | 内容 |
|---|---|
| **指标名称** | Click / 点击量 |
| **业务定义** | 点击量 |
| **计算公式** | 各渠道点击量加总 |
| **统计字段** | `click` |
| **数据底表** | `a05_e2e_paid_media_channel_data` |
| **筛选条件** | 按 channel / 广告点位 分组 |
| **数据类型** | integer → 千分位整数，不含小数 |
| **数据格式** | `#,##0` |

---

## 6. Add to Cart — 加购数

| 项目 | 内容 |
|---|---|
| **指标名称** | Add to Cart / 加购数 |
| **业务定义** | 加购数 |
| **计算公式** | 各渠道加购数加总 |
| **统计字段** | `add_cart_cnt` |
| **数据底表** | `a05_e2e_paid_media_channel_data` |
| **筛选条件** | 按 channel / 广告点位 分组 |
| **数据类型** | integer → 千分位整数，不含小数 |
| **数据格式** | `#,##0` |

---

## 7. Orders — 成交订单数

| 项目 | 内容 |
|---|---|
| **指标名称** | Orders / 成交订单数 |
| **业务定义** | 媒体带来的成交订单数 |
| **计算公式** | 各渠道成交订单数加总 |
| **统计字段** | `media_sales_order_cnt` |
| **数据底表** | `a05_e2e_paid_media_channel_data` |
| **筛选条件** | 按 channel / 广告点位 分组 |
| **数据类型** | integer → 千分位整数，不含小数 |
| **数据格式** | `#,##0` |

---

## 8. GMV — 成交金额

| 项目 | 内容 |
|---|---|
| **指标名称** | GMV / 成交金额 |
| **业务定义** | 媒体带来的成交金额 |
| **计算公式** | 各渠道成交金额加总 |
| **统计字段** | `media_sales_amt` |
| **数据底表** | `a05_e2e_paid_media_channel_data` |
| **筛选条件** | 按 channel / 广告点位 分组 |
| **数据类型** | currency → 货币符号由币种切片器决定，千分位整数 |
| **数据格式** | `#,##0`（在 DAX 中用 `__CurrencySymbol & FORMAT(__Value, "#,##0")` 拼接币种符号） |

---

## 9. CTR — 点击率

| 项目 | 内容 |
|---|---|
| **指标名称** | CTR / 点击率 |
| **业务定义** | Click / Impression |
| **计算公式** | Click / Impression |
| **分子** | `click`（点击量） |
| **分母** | `pv`（展现量） |
| **数据底表** | `a05_e2e_paid_media_channel_data` |
| **筛选条件** | 按 channel / 广告点位 分组 |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%;#,##0.0%;0.0%` |

---

## 10. CPC — 平均点击花费

| 项目 | 内容 |
|---|---|
| **指标名称** | CPC / 平均点击花费 |
| **业务定义** | Cost / Click |
| **计算公式** | Cost / Click |
| **分子** | `cost_amt`（花费） |
| **分母** | `click`（点击量） |
| **数据底表** | `a05_e2e_paid_media_channel_data` |
| **筛选条件** | 按 channel / 广告点位 分组 |
| **数据类型** | currency_decimal_1dp → 货币符号由币种切片器决定，千分位保留一位小数 |
| **数据格式** | `#,##0.0`（在 DAX 中用 `__CurrencySymbol & FORMAT(__Value, "#,##0.0")` 拼接币种符号） |  

---

## 11. CPATC — 加购成本

| 项目 | 内容 |
|---|---|
| **指标名称** | CPATC / 加购成本 |
| **业务定义** | Cost / Add to Cart |
| **计算公式** | Cost / Add to Cart |
| **分子** | `cost_amt`（花费） |
| **分母** | `add_cart_cnt`（加购数） |
| **数据底表** | `a05_e2e_paid_media_channel_data` |
| **筛选条件** | 按 channel / 广告点位 分组 |
| **数据类型** | currency_decimal_1dp → 货币符号由币种切片器决定，千分位保留一位小数 |
| **数据格式** | `#,##0.0`（在 DAX 中用 `__CurrencySymbol & FORMAT(__Value, "#,##0.0")` 拼接币种符号） |  

---

## 12. CVR — 点击转化率

| 项目 | 内容 |
|---|---|
| **指标名称** | CVR / 点击转化率 |
| **业务定义** | Orders / Click |
| **计算公式** | Orders / Click |
| **分子** | `media_sales_order_cnt`（成交订单数） |
| **分母** | `click`（点击量） |
| **数据底表** | `a05_e2e_paid_media_channel_data` |
| **筛选条件** | 按 channel / 广告点位 分组 |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%;#,##0.0%;0.0%` |

---

## 13. AOV — 客单价

| 项目 | 内容 |
|---|---|
| **指标名称** | AOV / 客单价 |
| **业务定义** | GMV / Orders |
| **计算公式** | GMV / Orders |
| **分子** | `media_sales_amt`（成交金额，GMV） |
| **分母** | `media_sales_order_cnt`（成交订单数） |
| **数据底表** | `a05_e2e_paid_media_channel_data` |
| **筛选条件** | 按 channel / 广告点位 分组 |
| **数据类型** | currency_decimal_1dp → 货币符号由币种切片器决定，千分位保留一位小数 |
| **数据格式** | `#,##0.0`（在 DAX 中用 `__CurrencySymbol & FORMAT(__Value, "#,##0.0")` 拼接币种符号） |  

---

## 通用规则汇总

| 规则项 | 说明 |
|---|---|
| **数据底表** | 全部指标统一使用 `a05_e2e_paid_media_channel_data` |
| **分组维度** | 按 channel / 广告点位 分组 |
| **绝对值指标** | Cost、Impression、Click、Add to Cart、Orders、GMV 为直接 sum 的绝对值指标 |
| **比率指标** | Cost%、ROI、CTR、CPC、CPATC、CVR、AOV 为派生比率指标，需分子分母分别计算后再相除 |
| **同期对比** | 板块名称为 "This Period TM/JD（vs Last Period）"，表示本期 vs 同期对比 |
| **数据格式规则** | 以口径中的数据格式为准，不做特殊处理 |
| **在生成 Power BI DAX/Power Query 代码时，严格遵循语法规范** | 文本常量（Text Values）必须使用双引号 " ",禁止使用单引号；单引号 ' '仅用于表名,列名使用方括号 [ ],例如：[framework] = "Acceleration" |
