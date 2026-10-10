# Merchandise Performance Overview 指标口径提示词

> **Dashboard**: RL E2E Merch Dashboard  
> **Tab**: Merchandise Performance Overview  
> **数据底表（销售类）**: `indep_rl_ads.a02_e2e_product_performance_sales_summary_d`  
> **数据底表（库存类）**: `indep_rl_ads.a02_e2e_product_performance_inv_summary_d`  
> **模块说明**: 本板块为商品绩效看板，覆盖 Merchandising Core KPI（Amt / Unit）、Sales & Inventory Penetration Trend（Sales / Inventory / Sales&Inventory 明细表）、Sales Performance Details by Channel 子板块，统计净销售、售罄率、折扣、全价率、库存、出入库及各类占比指标。

---

## 全局逻辑

| 项目 | 内容 |
|---|---|
| **数据底表（销售类）** | `indep_rl_ads.a02_e2e_product_performance_sales_summary_d`：SLS、AVG MD、Fullprice%、AUR、Inbound、Outbound 及 ST% 分子等区间汇总指标 |
| **数据底表（库存类）** | `indep_rl_ads.a02_e2e_product_performance_inv_summary_d`：EOH、In-Transit、O2O 等期末库存指标及 ST% 分母 |
| **全局支持筛选维度（渠道）** | 渠道：platform（取值 `platform`）、store name（取值 `shop_name`） |
| **全局支持筛选维度（商品）** | 商品：label（取值 `label`）、division（取值 `division`）、product type（取值 `product_type`）、framework（取值 `framework`）、category（取值 `category`）、ax class（取值 `ax_class`）、category summary（取值 `category_summary`）、special supply（取值 `special_supply`）、predictive buy（取值 `predictive_buy`）；取值清单见文末附录 |
| **商品维度切换（Core KPI 板块）** | ALL / Hero Model：`computed_product_tag = "hero model"` / Slow Mover：`computed_product_tag = "slow mover"` / Normal：`computed_product_tag = "normal"` |
| **商品维度切换（Trend 及明细板块）** | Label：`label` / Super Season：`super_season` / Product type：`product_type` / Category：`category` / MD type：`md_type` / Division：`division` |
| **时间口径（区间类）** | SLS、AUR、Inbound、Outbound 及 ST% 分子等：看所选时间范围（区间汇总） |
| **时间口径（期末时点类）** | EOH、In-Transit、O2O 及 ST% 分母等：看所选时间范围 end period 最后一天（时点数） |
| **vs LY 附属指标（变化率）** | SLS、AUR、EOH、Inbound、Outbound 等：`this period / last period - 1` |
| **vs LY 附属指标（差值 bp）** | ST%、AVG MD、Fullprice% 等比率类：`this period - last period`（差值，bp 指标，展示时 ×10000 转 bp） |
| **TAR ACH% 附属指标** | 仅 SLS Amt、SLS Unit 附属 TAR ACH% |
| **数据类型/数据格式** | 原始口径未定义数据类型与数据格式，DAX 实现时展示格式待业务确认 |
| **必须遵守** | 口径文档中定义的所有指标，必须遵守其数据类型和数据格式，如果和解决方案中存在争议的，一切以口径文档为准，必须按照口径文档中的格式进行调整 |
| **DAX 语法规范** | 文本常量必须使用双引号 `" "`，禁止使用单引号；单引号 `' '` 仅用于表名，列名使用方括号 `[ ]`，例如：`[md_type] = "FP"` |

---

## 子模块一：Merchandising Core KPI【Amt】

> **商品维度切换**: ALL / Hero Model：`computed_product_tag = "hero model"` / Slow Mover：`computed_product_tag = "slow mover"` / Normal：`computed_product_tag = "normal"`
> **支持筛选维度**: 渠道：platform，shop_name；商品：label，division，product_type，framework，category，ax_class，category_summary，special_supply，predictive_buy

### 1. SLS Amt — DCom净销售额，这个附属指标有三个

| 项目 | 内容 |
|---|---|
| **指标名称** | SLS Amt / DCom净销售额 |
| **业务定义** | 统计周期内DCom净销售额 = DCom销售订单总销售额 - 退货额 |
| **计算公式** | `sum(net_sales_amt)` |
| **数据底表** | `indep_rl_ads.a02_e2e_product_performance_sales_summary_d` |
| **附属指标** | vs LY：this period / last period - 1；TAR ACH%进度达成；TAR ACH%目标达成； |
| **数据类型** | currency → 货币符号由币种切片器决定，千分位整数 |
| **数据格式** | `#,##0`（在 DAX 中用 `__CurrencySymbol & FORMAT(__Value, "#,##0")` 拼接币种符号） |
| **附属指标类型** | vs LY:delta_pct_0dp、TAR ACH%进度达成:delta_pct_0dp、TAR ACH%目标达成:delta_pct_0dp |

---

### 2. ST% — 售罄率%（金额）

| 项目 | 内容 |
|---|---|
| **指标名称** | ST% / 售罄率%（金额） |
| **业务定义** | 统计周期内销售金额 /（销售金额 + 期末库存金额）× 100% |
| **计算公式** | 销售金额：看所选时间范围销售金额之和；期末库存金额：看所选时间范围 end period 最后一天；`sales.net_sales_amt / (sales.net_sales_amt + inv.msrp_inv_amt)` |
| **数据底表** | `indep_rl_ads.a02_e2e_product_performance_sales_summary_d`（sales）；`indep_rl_ads.a02_e2e_product_performance_inv_summary_d`（inv） |
| **附属指标** | vs LY：this period - last period（差值，bp 指标，展示时 ×10000 转 bp） |
| **数据类型** | percent_0dp → 百分比整数，不含正号 |
| **数据格式** | `#,##0%` |
| **附属指标类型** | vs LY:delta_bp |

---

### 3. AVG MD — 平均折扣(【Amt】和【Unit】的是同一套逻辑可直接复用，不用重复计算)

| 项目 | 内容 |
|---|---|
| **指标名称** | AVG MD / 平均折扣 |
| **业务定义** | 1 - 折扣价 / 原价 × 100% |
| **计算公式** | `1 - sum(md_net_sales_amt) / sum(msrp_net_sales_amt)` |
| **数据底表** | `indep_rl_ads.a02_e2e_product_performance_sales_summary_d` |
| **附属指标** | vs LY：this period - last period（差值，bp 指标，展示时 ×10000 转 bp） |
| **数据类型** | percent_0dp → 百分比整数，不含正号 |
| **数据格式** | `#,##0%` |
| **附属指标类型** | vs LY:delta_bp |

---

### 4. Fullprice% — 全价率

| 项目 | 内容 |
|---|---|
| **指标名称** | Fullprice% / 全价率 |
| **业务定义** | 全价商品销售额 / 总销售额 × 100% |
| **计算公式** | `sum(case when md_type = 'FP' then net_sales_amt else 0 end) / sum(net_sales_amt)` |
| **数据底表** | `indep_rl_ads.a02_e2e_product_performance_sales_summary_d` |
| **附属指标** | vs LY：this period - last period（差值，bp 指标，展示时 ×10000 转 bp） |
| **数据类型** | percent_0dp → 百分比整数，不含正号 |
| **数据格式** | `#,##0%` |
| **附属指标类型** | vs LY:delta_bp |

---

### 5. AUR — 件单价(【Amt】和【Unit】的是同一套逻辑可直接复用，不用重复计算)

| 项目 | 内容 |
|---|---|
| **指标名称** | AUR / 件单价 |
| **业务定义** | 净销售金额 / 商品净出库件数 |
| **计算公式** | `sum(net_sales_amt) / sum(net_sales_qty)` |
| **数据底表** | `indep_rl_ads.a02_e2e_product_performance_sales_summary_d` |
| **附属指标** | vs LY：this period / last period - 1 |
| **数据类型** | currency → 货币符号由币种切片器决定，千分位整数 |
| **数据格式** | `#,##0`（在 DAX 中用 `__CurrencySymbol & FORMAT(__Value, "#,##0")` 拼接币种符号） |
| **附属指标类型** | vs LY:delta_pct_0dp |

---

### 6. EOH Amt — 期末库存金额

| 项目 | 内容 |
|---|---|
| **指标名称** | EOH Amt / 期末库存金额 |
| **业务定义** | EOH Units × msrp |
| **计算公式** | 看所选时间范围 end period 最后一天；`sum(msrp_inv_amt)` |
| **数据底表** | `indep_rl_ads.a02_e2e_product_performance_inv_summary_d` |
| **附属指标** | vs LY：this period / last period - 1 |
| **数据类型** | currency → 货币符号由币种切片器决定，千分位整数 |
| **数据格式** | `#,##0`（在 DAX 中用 `__CurrencySymbol & FORMAT(__Value, "#,##0")` 拼接币种符号） |
| **附属指标类型** | vs LY:delta_pct_0dp |

---

### 7. In-Transit Inventory Amt — 在途库存金额，这个没有附属指标。

| 项目 | 内容 |
|---|---|
| **指标名称** | In-Transit Inventory Amt / 在途库存金额 |
| **业务定义** | In-Transit Inventory Unit × msrp |
| **计算公式** | 看所选时间范围 end period 最后一天；`sum(msrp_in_trans_inv_amt)` |
| **数据底表** | `indep_rl_ads.a02_e2e_product_performance_inv_summary_d` |
| **数据类型** | currency → 货币符号由币种切片器决定，千分位整数 |
| **数据格式** | `#,##0`（在 DAX 中用 `__CurrencySymbol & FORMAT(__Value, "#,##0")` 拼接币种符号） |

---

### 8. O2O Inventory Amt — O2O，这个没有附属指标。

| 项目 | 内容 |
|---|---|
| **指标名称** | O2O Inventory Amt / O2O库存金额 |
| **业务定义** | O2O Inventory Unit × msrp |
| **计算公式** | 看所选时间范围 end period 最后一天；`sum(msrp_o2o_inv_amt)` |
| **数据底表** | `indep_rl_ads.a02_e2e_product_performance_inv_summary_d` |
| **数据类型** | currency → 货币符号由币种切片器决定，千分位整数 |
| **数据格式** | `#,##0`（在 DAX 中用 `__CurrencySymbol & FORMAT(__Value, "#,##0")` 拼接币种符号） |

---

### 9. Inbound Amt — 入库金额

| 项目 | 内容 |
|---|---|
| **指标名称** | Inbound Amt / 入库金额 |
| **业务定义** | Inbound Unit × msrp |
| **计算公式** | `sum(msrp_inbound_amt)` |
| **数据底表** | `indep_rl_ads.a02_e2e_product_performance_sales_summary_d` |
| **附属指标** | vs LY：this period / last period - 1 |
| **数据类型** | currency → 货币符号由币种切片器决定，千分位整数 |
| **数据格式** | `#,##0`（在 DAX 中用 `__CurrencySymbol & FORMAT(__Value, "#,##0")` 拼接币种符号） |
| **附属指标类型** | vs LY:delta_pct_0dp |

---

### 10. Outbound Amt — 出库金额

| 项目 | 内容 |
|---|---|
| **指标名称** | Outbound Amt / 出库金额 |
| **业务定义** | Outbound Amt × msrp |
| **计算公式** | `sum(md_outbound_amt)` |
| **数据底表** | `indep_rl_ads.a02_e2e_product_performance_sales_summary_d` |
| **附属指标** | vs LY：this period / last period - 1 |
| **数据类型** | currency → 货币符号由币种切片器决定，千分位整数 |
| **数据格式** | `#,##0`（在 DAX 中用 `__CurrencySymbol & FORMAT(__Value, "#,##0")` 拼接币种符号） |
| **附属指标类型** | vs LY:delta_pct_0dp |

---

## 子模块二：Merchandising Core KPI【Unit】

> **商品维度切换**: ALL / Hero Model：`computed_product_tag = "hero model"` / Slow Mover：`computed_product_tag = "slow mover"` / Normal：`computed_product_tag = "normal"`
> **支持筛选维度**: 渠道：platform，shop_name；商品：label，division，product_type，framework，category，ax_class，category_summary，special_supply，predictive_buy

### 11. SLS Unit — DCom净销售数量，这个附属指标有三个。

| 项目 | 内容 |
|---|---|
| **指标名称** | SLS Unit / DCom净销售数量 |
| **业务定义** | 统计周期内DCom净销售数量 = DCom销售订单总销售数量 - 退货数量 |
| **计算公式** | `sum(net_sales_qty)` |
| **数据底表** | `indep_rl_ads.a02_e2e_product_performance_sales_summary_d` |
| **附属指标** | vs LY：this period / last period - 1；TAR ACH% |
| **数据类型** | integer → 整数，千分位整数 |
| **数据格式** | `#,##0` |
| **附属指标类型** | vs LY:delta_pct_0dp、TAR ACH%进度达成:delta_pct_0dp、TAR ACH%目标达成:delta_pct_0dp |
---

### 12. ST% — 售罄率%（数量）

| 项目 | 内容 |
|---|---|
| **指标名称** | ST% / 售罄率%（数量） |
| **业务定义** | 统计周期内销售数量 /（销售数量 + 期末库存数量）× 100% |
| **计算公式** | 销售数量：看所选时间范围销售数量之和；期末库存数量：看所选时间范围 end period 最后一天；`sales.net_sales_qty / (sales.net_sales_qty + inv.inv_qty)` |
| **数据底表** | `indep_rl_ads.a02_e2e_product_performance_sales_summary_d`（sales）；`indep_rl_ads.a02_e2e_product_performance_inv_summary_d`（inv） |
| **附属指标** | vs LY：this period - last period（差值，bp 指标，展示时 ×10000 转 bp） |
| **数据类型** | percent_0dp → 百分比整数，不含正号 |
| **数据格式** | `#,##0%` |
| **附属指标类型** | vs LY:delta_bp |
---

### 13. AVG MD — 平均折扣(【Amt】和【Unit】的是同一套逻辑可直接复用，不用重复计算)

| 项目 | 内容 |
|---|---|
| **指标名称** | AVG MD / 平均折扣 |
| **业务定义** | 1 - 折扣价 / 原价 × 100% |
| **计算公式** | `1 - sum(md_net_sales_amt) / sum(msrp_net_sales_amt)` |
| **数据底表** | `indep_rl_ads.a02_e2e_product_performance_sales_summary_d` |
| **附属指标** | vs LY：this period - last period（差值，bp 指标，展示时 ×10000 转 bp） |
| **数据类型** | percent_0dp → 百分比整数，不含正号 |
| **数据格式** | `#,##0%` |
| **附属指标类型** | vs LY:delta_bp |
---

### 14. Fullprice% — 全价率

| 项目 | 内容 |
|---|---|
| **指标名称** | Fullprice% / 全价率 |
| **业务定义** | 全价商品销售额 / 总销售额 × 100% |
| **计算公式** | `sum(msrp_net_sales_amt) / sum(net_sales_amt)` |
| **数据底表** | `indep_rl_ads.a02_e2e_product_performance_sales_summary_d` |
| **附属指标** | vs LY：this period - last period（差值，bp 指标，展示时 ×10000 转 bp） |
| **注意** | 原始口径该行公式与子模块一 Fullprice%（`md_type = 'FP'` 口径）不同，DAX 实现时需与业务确认：已确认，此处直接sum(msrp_net_sales_amt) |
| **数据类型** | percent_0dp → 百分比整数，不含正号 |
| **数据格式** | `#,##0%` |
| **附属指标类型** | vs LY:delta_bp |
---

### 15. AUR — 件单价(【Amt】和【Unit】的是同一套逻辑可直接复用，不用重复计算)

| 项目 | 内容 |
|---|---|
| **指标名称** | AUR / 件单价 |
| **业务定义** | 净销售金额 / 商品净出库件数 |
| **计算公式** | `sum(net_sales_amt) / sum(net_sales_qty)` |
| **数据底表** | `indep_rl_ads.a02_e2e_product_performance_sales_summary_d` |
| **附属指标** | vs LY：this period / last period - 1 |
| **数据类型** | currency → 货币符号由币种切片器决定，千分位整数 |
| **数据格式** | `#,##0`（在 DAX 中用 `__CurrencySymbol & FORMAT(__Value, "#,##0")` 拼接币种符号） |
| **附属指标类型** | vs LY:delta_pct_0dp |
---

### 16. EOH Unit — 期末库存数量

| 项目 | 内容 |
|---|---|
| **指标名称** | EOH Unit / 期末库存数量 |
| **业务定义** | 选定日期业务周期结束时点的期末库存总数量 |
| **计算公式** | 看所选时间范围 end period 最后一天；`sum(inv_qty)` |
| **数据底表** | `indep_rl_ads.a02_e2e_product_performance_inv_summary_d` |
| **附属指标** | vs LY：this period / last period - 1 |
| **数据类型** | integer → 整数，千分位整数 |
| **数据格式** | `#,##0` |
| **附属指标类型** | vs LY:delta_pct_0dp |
---

### 17. In-Transit Inventory Unit — 在途库存数量，这个没有附属指标。

| 项目 | 内容 |
|---|---|
| **指标名称** | In-Transit Inventory Unit / 在途库存数量 |
| **业务定义** | 已出库尚未入库到仓的货品总件数 |
| **计算公式** | 看所选时间范围 end period 最后一天；`sum(in_trans_inv_qty)` |
| **数据底表** | `indep_rl_ads.a02_e2e_product_performance_inv_summary_d` |
| **数据类型** | integer → 整数，千分位整数 |
| **数据格式** | `#,##0` |
---

### 18. O2O Inventory Unit — O2O库存数量，这个没有附属指标。

| 项目 | 内容 |
|---|---|
| **指标名称** | O2O Inventory Unit / O2O库存数量 |
| **业务定义** | 支持线上线下履约调拨的可用于 O2O 渠道发货的库存总件数 |
| **计算公式** | 看所选时间范围 end period 最后一天；`sum(o2o_inv_qty)` |
| **数据底表** | `indep_rl_ads.a02_e2e_product_performance_inv_summary_d` |
| **数据类型** | integer → 整数，千分位整数 |
| **数据格式** | `#,##0` |

---

### 19. Inbound Unit — 入库数量

| 项目 | 内容 |
|---|---|
| **指标名称** | Inbound Unit / 入库数量 |
| **业务定义** | 所选周期范围内货品完成入库的总库存数量 |
| **计算公式** | `sum(inbound_qty)` |
| **数据底表** | `indep_rl_ads.a02_e2e_product_performance_sales_summary_d` |
| **附属指标** | vs LY：this period / last period - 1 |
| **数据类型** | integer → 整数，千分位整数 |
| **数据格式** | `#,##0` |
| **附属指标类型** | vs LY:delta_pct_0dp |
---

### 20. Outbound Unit — 出库数量

| 项目 | 内容 |
|---|---|
| **指标名称** | Outbound Unit / 出库数量 |
| **业务定义** | 所选周期范围内货品完成出库的总库存数量 |
| **计算公式** | `sum(outbound_qty)` |
| **数据底表** | `indep_rl_ads.a02_e2e_product_performance_sales_summary_d` |
| **附属指标** | vs LY：this period / last period - 1 |
| **数据类型** | integer → 整数，千分位整数 |
| **数据格式** | `#,##0` |
| **附属指标类型** | vs LY:delta_pct_0dp |
---

## 子模块三：Sales & Inventory Penetration Trend【Sales】

> **商品维度切换**: Label：`label` / Super Season：`super_season` / Product type：`product_type` / Category：`category` / MD type：`md_type` / Division：`division`
> **支持筛选维度**: 渠道：platform，shop_name；商品：label，division，product_type，framework，category，ax_class，category_summary，special_supply，predictive_buy

### 21. SLS Amt% — 销售金额占比

| 项目 | 内容 |
|---|---|
| **指标名称** | SLS Amt% / 销售金额占比 |
| **业务定义** | 单品类占总品类的比例 |
| **计算公式** | 分子：各 label / super_season / product_type / category / md_type / division 下 `sum(net_sales_amt)`；分母：`sum(net_sales_amt)` |
| **数据底表** | `indep_rl_ads.a02_e2e_product_performance_sales_summary_d` |
| **特殊说明** | Week / Month / Year 和全局时间筛选器的关系（原始口径问题列待确认项） |

---

## 子模块四：Sales & Inventory Penetration Trend【Inventory】

> **商品维度切换**: Label：`label` / Super Season：`super_season` / Product type：`product_type` / Category：`category` / MD type：`md_type` / Division：`division`

### 22. EOH Amt% — 期末库存金额占比

| 项目 | 内容 |
|---|---|
| **指标名称** | EOH Amt% / 期末库存金额占比 |
| **业务定义** | 根据所筛选维度统计对应 EOH amt 占比 |
| **计算公式** | 分子：各 label / super_season / product_type / category / md_type / division 下，看所选时间范围 end period 最后一天，`sum(msrp_inv_amt)`；分母：看所选时间范围 end period 最后一天，`sum(msrp_inv_amt)` |
| **数据底表** | `indep_rl_ads.a02_e2e_product_performance_inv_summary_d` |

---

## 子模块五：Sales & Inventory Penetration Trend【Sales/Inventory 展示一样】

> **表格列受左边柱状图影响**；这里的 YOY 是固定对比上个财年同期，不受 last period 时间筛选器影响
> **商品维度切换**: Label：`label` / Super Season：`super_season` / Product type：`product_type` / Category：`category` / MD type：`md_type` / Division：`division`
> **支持筛选维度**: 渠道：platform，shop_name；商品：label，division，product_type，framework，category，ax_class，category_summary，special_supply，predictive_buy

### 23. EOH Unit（TY）— 期末库存数量

| 项目 | 内容 |
|---|---|
| **指标名称** | EOH Unit（TY）/ 期末库存数量 |
| **业务定义** | 选定日期业务周期结束时点的期末库存总数量 |
| **计算公式** | 看所选时间范围 end period 最后一天；`sum(inv_qty)` |
| **数据底表** | `indep_rl_ads.a02_e2e_product_performance_inv_summary_d` |

---

### 24. EOH Amt（TY）— 期末库存金额

| 项目 | 内容 |
|---|---|
| **指标名称** | EOH Amt（TY）/ 期末库存金额 |
| **业务定义** | EOH Units × msrp |
| **计算公式** | 看所选时间范围 end period 最后一天；`sum(msrp_inv_amt)` |
| **数据底表** | `indep_rl_ads.a02_e2e_product_performance_inv_summary_d` |

---

### 25. In-transit Unit（TY）— 在途库存数量

| 项目 | 内容 |
|---|---|
| **指标名称** | In-transit Unit（TY）/ 在途库存数量 |
| **业务定义** | 已出库尚未入库到仓的货品总件数 |
| **计算公式** | 看所选时间范围 end period 最后一天；`sum(in_trans_inv_qty)` |
| **数据底表** | `indep_rl_ads.a02_e2e_product_performance_inv_summary_d` |

---

### 26. ST%（TY）— 售罄率%（金额）

| 项目 | 内容 |
|---|---|
| **指标名称** | ST%（TY）/ 售罄率%（金额） |
| **业务定义** | 统计周期内销售金额 /（销售金额 + 期末库存金额）× 100% |
| **计算公式** | 销售金额：看所选时间范围销售金额之和；期末库存金额：看所选时间范围 end period 最后一天；`sales.net_sales_amt / (sales.net_sales_amt + inv.msrp_inv_amt)` |
| **数据底表** | `indep_rl_ads.a02_e2e_product_performance_sales_summary_d`（sales）；`indep_rl_ads.a02_e2e_product_performance_inv_summary_d`（inv） |

---

### 27. EOH Unit（LY）— 期末库存数量

| 项目 | 内容 |
|---|---|
| **指标名称** | EOH Unit（LY）/ 期末库存数量 |
| **业务定义** | 选定日期业务周期结束时点的期末库存总数量 |
| **计算公式** | 看所选时间范围去年同期 end period 最后一天；`sum(inv_qty)` |
| **数据底表** | `indep_rl_ads.a02_e2e_product_performance_inv_summary_d` |

---

### 28. EOH Amt（LY）— 期末库存金额

| 项目 | 内容 |
|---|---|
| **指标名称** | EOH Amt（LY）/ 期末库存金额 |
| **业务定义** | EOH Units × msrp |
| **计算公式** | 看所选时间范围去年同期 end period 最后一天；`sum(msrp_inv_amt)` |
| **数据底表** | `indep_rl_ads.a02_e2e_product_performance_inv_summary_d` |

---

### 29. In-transit Unit（LY）— 在途库存数量

| 项目 | 内容 |
|---|---|
| **指标名称** | In-transit Unit（LY）/ 在途库存数量 |
| **业务定义** | 已出库尚未入库到仓的货品总件数 |
| **计算公式** | 看所选时间范围去年同期 end period 最后一天；`sum(in_trans_inv_qty)` |
| **数据底表** | `indep_rl_ads.a02_e2e_product_performance_inv_summary_d` |

---

### 30. ST%（LY）— 售罄率%（金额）

| 项目 | 内容 |
|---|---|
| **指标名称** | ST%（LY）/ 售罄率%（金额） |
| **业务定义** | 统计周期内销售金额 /（销售金额 + 期末库存金额）× 100% |
| **计算公式** | 销售金额：看所选时间范围销售金额之和；期末库存金额：看所选时间范围 end period 最后一天；`sales.net_sales_amt / (sales.net_sales_amt + inv.msrp_inv_amt)` |
| **数据底表** | `indep_rl_ads.a02_e2e_product_performance_sales_summary_d`（sales）；`indep_rl_ads.a02_e2e_product_performance_inv_summary_d`（inv） |
| **注意** | 原始口径该行公式与 ST%（TY）完全一致（未区分 LY 时间范围），结合板块说明「YOY 固定对比上个财年同期」，DAX 实现时需与业务确认 LY 的销售/库存时间范围 |

---

### 31. SLS Amt YOY — DCom净销售额YOY

| 项目 | 内容 |
|---|---|
| **指标名称** | SLS Amt YOY / DCom净销售额YOY |
| **业务定义** | 今年 / 去年 - 1 |
| **计算公式** | `sum(net_sales_amt)`，今年 / 去年 - 1 |
| **数据底表** | `indep_rl_ads.a02_e2e_product_performance_sales_summary_d` |
| **特殊说明** | 本板块 YOY 固定对比上个财年同期，不受 last period 时间筛选器影响 |

---

### 32. SLS Unit YOY — DCom净销售数量YOY

| 项目 | 内容 |
|---|---|
| **指标名称** | SLS Unit YOY / DCom净销售数量YOY |
| **业务定义** | 今年 / 去年 - 1 |
| **计算公式** | `sum(net_sales_qty)`，今年 / 去年 - 1 |
| **数据底表** | `indep_rl_ads.a02_e2e_product_performance_sales_summary_d` |
| **特殊说明** | 本板块 YOY 固定对比上个财年同期，不受 last period 时间筛选器影响 |

---

## 子模块六：Sales Performance Details by Channel

> **YOY 口径**: YOY 是 this period 和 last period 对比
> **商品维度切换**: Label：`label` / Super Season：`super_season` / Product type：`product_type` / Category：`category` / MD type：`md_type` / Division：`division`（同 Trend 板块，依据占比指标公式中的维度）

### 33. SLS Unit — DCom净销售数量

| 项目 | 内容 |
|---|---|
| **指标名称** | SLS Unit / DCom净销售数量 |
| **业务定义** | 统计周期内DCom净销售数量 = DCom销售订单总销售数量 - 退货数量 |
| **计算公式** | `sum(net_sales_qty)` |
| **数据底表** | `indep_rl_ads.a02_e2e_product_performance_sales_summary_d` |

---

### 34. SLS Amt — DCom净销售额

| 项目 | 内容 |
|---|---|
| **指标名称** | SLS Amt / DCom净销售额 |
| **业务定义** | 统计周期内DCom净销售额 = DCom销售订单总销售额 - 退货额 |
| **计算公式** | `sum(net_sales_amt)` |
| **数据底表** | `indep_rl_ads.a02_e2e_product_performance_sales_summary_d` |

---

### 35. SLS Amt YOY — DCom净销售额YOY

| 项目 | 内容 |
|---|---|
| **指标名称** | SLS Amt YOY / DCom净销售额YOY |
| **业务定义** | 今年 / 去年 - 1 |
| **计算公式** | `sum(net_sales_amt)`，this period / last period - 1 |
| **数据底表** | `indep_rl_ads.a02_e2e_product_performance_sales_summary_d` |
| **特殊说明** | YOY 是 this period 和 last period 对比（受 last period 时间筛选器影响） |

---

### 36. SLS Amt% — 销售金额占比

| 项目 | 内容 |
|---|---|
| **指标名称** | SLS Amt% / 销售金额占比 |
| **业务定义** | 单品类占总品类的比例 |
| **计算公式** | 分子：各 label / super_season / product_type / category / md_type / division 下 `sum(net_sales_amt)`；分母：`sum(net_sales_amt)` |
| **数据底表** | `indep_rl_ads.a02_e2e_product_performance_sales_summary_d` |

---

### 37. Vert. Amt% — 纵向金额占比

| 项目 | 内容 |
|---|---|
| **指标名称** | Vert. Amt% / 根据所选维度统计表格内纵向金额占比 |
| **业务定义** | 当前单元格 SLS Amt / 该列渠道 Total SLS Amt |
| **计算公式** | 分子：各 platform / shop_name × 商品维度下 `sum(net_sales_amt)`；分母：各 platform / shop_name 下 `sum(net_sales_amt)` |
| **数据底表** | `indep_rl_ads.a02_e2e_product_performance_sales_summary_d` |

---

### 38. Horiz. Amt% — 横向金额占比

| 项目 | 内容 |
|---|---|
| **指标名称** | Horiz. Amt% / 根据所选维度统计表格内横向金额占比 |
| **业务定义** | 当前单元格 SLS Amt / 该行商品维度 Total SLS Amt |
| **计算公式** | 分子：各 platform / shop_name × 商品维度下 `sum(net_sales_amt)`；分母：各商品维度下 `sum(net_sales_amt)` |
| **数据底表** | `indep_rl_ads.a02_e2e_product_performance_sales_summary_d` |

---

### 39. LTD ST% — LTD售罄率%（金额）

| 项目 | 内容 |
|---|---|
| **指标名称** | LTD ST% / LTD售罄率%（金额） |
| **业务定义** | 开店以来销售数量 /（销售数量 + 期末库存数量）× 100% |
| **计算公式** | 销售金额：2024-01-01 至今销售金额之和（待定）；期末库存金额：看所选时间范围 end period 最后一天；`sales.net_sales_amt / (sales.net_sales_amt + inv.msrp_inv_amt)` |
| **数据底表** | `indep_rl_ads.a02_e2e_product_performance_sales_summary_d`（sales）；`indep_rl_ads.a02_e2e_product_performance_inv_summary_d`（inv） |
| **特殊说明** | 销售区间为 2024 年至筛选器所选 end period（原始口径标注「待定」） |

---

### 40. EOH Unit — 期末库存数量

| 项目 | 内容 |
|---|---|
| **指标名称** | EOH Unit / 期末库存数量 |
| **业务定义** | 选定日期业务周期结束时点的期末库存总数量 |
| **计算公式** | 看所选时间范围 end period 最后一天；`sum(msrp_inv_amt)` |
| **数据底表** | `indep_rl_ads.a02_e2e_product_performance_inv_summary_d` |
| **注意** | 原始口径该行计算指标写作 `sum(msrp_inv_amt)`（金额字段），与「期末库存数量」定义存在差异（子模块二 EOH Unit 为 `sum(inv_qty)`），DAX 实现时需与业务确认 |

---

### 41. AUR — 件单价

| 项目 | 内容 |
|---|---|
| **指标名称** | AUR / 件单价 |
| **业务定义** | 净销售金额 / 商品净出库件数 |
| **计算公式** | `sum(net_sales_amt) / sum(net_sales_qty)` |
| **数据底表** | `indep_rl_ads.a02_e2e_product_performance_sales_summary_d` |

---

## 通用规则汇总

| 规则项 | 说明 |
|---|---|
| **数据底表** | 销售类指标用 `indep_rl_ads.a02_e2e_product_performance_sales_summary_d`；库存类指标用 `indep_rl_ads.a02_e2e_product_performance_inv_summary_d`；ST% / LTD ST% 跨双表（sales + inv） |
| **全局支持筛选维度** | 渠道：platform、shop_name；商品：label，division，product_type，framework，category，ax_class，category_summary，special_supply，predictive_buy |
| **商品维度切换** | Core KPI 板块：ALL / Hero Model / Slow Mover / Normal（`computed_product_tag`）；Trend 及明细板块：label / super_season / product_type / category / md_type / division |
| **时间口径** | 区间类指标：看所选时间范围汇总；期末库存类指标（EOH / In-Transit / O2O / ST% 分母）：看所选时间范围 end period 最后一天；LY 库存列：看所选时间范围去年同期 end period 最后一天 |
| **vs LY 规则** | 常规指标：this period / last period - 1（变化率）；ST% / AVG MD / Fullprice% 等比率类：this period - last period（差值，bp 指标，展示时 ×10000 转 bp） |
| **TAR ACH%** | 仅 SLS Amt、SLS Unit 附属 TAR ACH% |
| **YOY 口径差异** | Sales & Inventory Penetration Trend 明细表：YOY 固定对比上个财年同期，不受 last period 时间筛选器影响；Sales Performance Details by Channel：YOY 是 this period 和 last period 对比 |
| **LTD ST% 特殊区间** | 销售部分固定 2024-01-01 起算（原始口径标注待定），库存部分取所选时间范围 end period 最后一天 |
| **明细表联动** | Sales & Inventory Penetration Trend 明细表表格列受左边柱状图影响 |
| **必须遵守** | 口径文档中定义的所有指标，必须遵守其数据类型和数据格式，如果和解决方案中存在争议的，一切以口径文档为准，必须按照口径文档中的格式进行调整 |
| **DAX 语法规范** | 文本常量必须使用双引号 `" "`，禁止使用单引号；单引号 `' '` 仅用于表名，列名使用方括号 `[ ]`，例如：`[md_type] = "FP"` |

---

## 附录：商品筛选维度取值清单

> 来自原始口径「全局支持筛选维度」商品维度行的取值清单，供切片器/维度表建设参考；渠道维度（platform、shop_name）取值以数据表为准。

| 筛选维度 | 取值字段 | 取值清单（原始口径） |
|---|---|---|
| label | `label` | W Polo、FJ、CL、PL、CW、M Polo、RRL、HM、Lauren |
| division | `division` | WM、FJ、CW、HM、MN |
| product type | `product_type` | 618 Commercial、BSR、CYO/DTG、Carryover、Commercial、D11 Commercial、Excess、FA23、FA24、FA25、FA26、GWP、HO23、HO24、HO25、HO26、PF23、PF24、PF25、PF26、PS23、PS24、PS25、PS26、PSR、SP23、SP24、SP25、SP26、SP27、SU23、SU24、SU25、SU26、SU27 |
| framework | `framework` | Acceleration、Complementary、Foundation、Secondary、Primary |
| category | `category` | Sportcoat、Sweatshirt、Handbags、Swim、Footwear、Jewelry、Sweaters、Sport shirts、Belts、Dresses、T-shirt、Sneakers、Denim、Caps、Shirt、Belts/Small Accessories、Small Leathergoods、Polo shirt、Jeans、Outerwear、Pant、Sleepwear、Shirts、Sport Shirt、Skirt、Belts/small accessories、Luggage/Bags、T-Shirt、Sweater、Headwear、Pants、Skirts |
| ax class | `ax_class` | Large Leathergoods、Top Coat、OVERALL、Legging、Mens Fragrance、HEADWEAR、Trouser、Sport Shirt、Hdwr/umbrla/glv/scrv、NECKWEAR、GIFTS、SETS、ACCESSORIES、DRESSES、Fashion Jewelry、SMALL ACCESSORIES、SPORTS EQUIPMENT、Childrenswear Small Accessories、SCARF、Casual Footwear、Coverall、Skirt、Hats/gloves、Eyewear、Hosiery、Hats/Gloves、Gifts、Neckwear、T-Shirt、EYEWEAR、WOMENS FRAGRANCE、OUTERWEAR、Luggage、Sweater、Headwear、Bath、LUGGAGE、TABLETOP、SKIRT、Pet Apparel、COVERALL、Tailored Casual Footwear、MENS FRAGRANCE、VEST、JACKET、PANT、SHORT、Bags、Fine Jewelry、SWEATER、TROUSER、Underwear、Childrenswear Socks/Underwear/Hosiery、TOP COAT、Gloves、SUIT、Braces、HANDBAGS、BATH、Home Accessories、Sports Equipment、SLEEPWEAR、DRESS SHIRT、Childrenswear Footwear、Sportcoat、ONE PIECE、Jumpsuit、Knit、Handbags、UNDERWEAR、Childrenswear Cold Weather、Sets、Suit、Personal Towel、SWIM、Swim、Footwear、Dress Footwear、Childrenswear Socks/underwear/hosiery、Scarf、HOSIERY、Jewelry、One Piece、Small Accessories、SMALL LEATHERGOODS、BEDDING、Hdwr/Umbrla/Glv/Scrv、Womens Fragrance、FASHION JEWELRY、Belts、T-SHIRT、SHIRT、DENIM、Dresses、BAGS、T-shirt、Vest、Denim、LEGGING、Shirt、PET APPAREL、Umbrellas、Small Leathergoods、BELTS、Bedding、Dress Shirt、HOME ACCESSORIES、HDWR/UMBRLA/GLV/SCRV、Bottoms、JUMPSUIT、Jacket、Tabletop、Watch Accessories、Home Fragrance、SPORT SHIRT、Overall、Short、FOOTWEAR、KNIT、GLOVES、Outerwear、Decorative Home、Pant、JEWELRY、HOME FRAGRANCE、Accessories、SPORTCOAT、Sleepwear、Fine Watches |
| category summary | `category_summary` | 领带/领结/领夹、水壶、羽绒马甲、短袖POLO衫、双肩包、裙裤、披风/斗篷、围裙、短袖T恤、蕾丝衫、靴子、长袖Polo衫、羽绒服、毛衣/针织衫、马克杯、手机壳、风衣外套、沐浴/润肤系列、表带、运动毛巾、披肩、短裤、背心、家居裤、香薰摆件、背带裤、平角内裤、饰品、口袋巾、枕头、糕点礼盒、大衣、浴垫、沙滩巾、月饼车厢、睡裤、盒子、棉服、迷你毛巾、项链、皮裤、别针、吊坠、滑板贴纸、装饰品、手袋、宠物包、短袖Polo衫、抹胸、西装外套、连衣裤、长袖polo衫、月饼组合、摆件、西服套装、毛衣、雪纺衫/蕾丝衫、宠物餐具、吊饰、毛巾/面巾/洗脸巾、手套、抱毯、针织衫、蜡烛、婴儿礼盒、长袖上衣、连衣裙、卡包/钱包/手包、围巾套装、枕芯、香氛系列、收纳托盘、休闲衬衫、FY27-月饼、饼干组合、背心/吊带、香水、毛衣/针织衫-短袖、盘子套装、长袖衬衫、皮衣、毯子、鞋、地毯/地垫、睡衣套装、皮带、毛呢大衣、连体衣、其他配件、半身裙、太阳镜、沙滩裤、宠物玩具、家居服套装、抱枕套装、眼镜盒、滑轮、茶巾、牛仔衬衫、宠物配件、地毯、月饼、内裤、西裤、""、被子、套装、火车头模型、背带、牛仔裤、连体衣/连体裤、滑扣、卫衣、床单、连体裤、长裤、滑板、餐垫、枕套、托特包、手巾、餐具套装、杯子、挂件、短袖衬衫/上衣、意大利、耳环、家居服、卫裤、防风罩、袜子、腰带、马甲/背心、外套/夹克、书、围兜、床单/床笠、短袖上衣、背心吊带、被套、防晒衣、挂饰、盘、毛巾套装、背心毛衫、擦手巾、礼服、手表、泳裤/沙滩裤、围巾、伞、帽子、背心/马甲、牛仔夹克、香氛、围巾、宠物服装、领巾、短袖衬衫、方巾套装、打底裤、正装衬衫、收纳袋、长袖T恤、洗脸巾、风衣、包、外套/夹克、休闲裤、围巾/丝巾、帽子套装、首饰、领带、礼品套装、短袖polo衫、餐具类、领带夹、皮草、棉裤、西服、抱枕、浴巾、毛巾/面巾、领带/领结、袖扣、斗篷、相框、呢大衣、马甲、毛巾、毛毯、杯垫套装、长袖POLO衫、手链 |
| special supply | `special_supply` | TM、JD |
| predictive buy | `predictive_buy` | 1、0 |
