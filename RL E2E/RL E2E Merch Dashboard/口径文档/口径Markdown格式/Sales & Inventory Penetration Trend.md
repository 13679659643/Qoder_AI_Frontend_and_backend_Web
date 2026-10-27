# Sales & Inventory Penetration Trend 指标口径提示词

> **Dashboard**: RL E2E Merch Dashboard  
> **Tab**: Sales & Inventory Penetration Trend  
> **数据底表（销售类）**: `indep_rl_ads.a02_e2e_product_performance_sales_summary_d`  
> **数据底表（库存类）**: `indep_rl_ads.a02_e2e_product_performance_inv_summary_d`  
> **模块说明**: 本板块为销售与库存穿透趋势看板，分为【Sales】与【Inventory】两个子板块：Sales 子板块覆盖 SLS Amt% 销售金额占比、TY/LY 净销售数量与金额、售罄率（ST%）及 YOY 同比指标；Inventory 子板块覆盖 EOH Amt% 期末库存金额占比、TY/LY 期末库存与在途库存、售罄率（ST%）及 YOY 同比指标。

---

## 全局逻辑

| 项目 | 内容 |
|---|---|
| **数据底表（销售类）** | `indep_rl_ads.a02_e2e_product_performance_sales_summary_d`：SLS Unit / SLS Amt、ST% 分子（销售金额）等区间汇总指标及销售类 YOY 指标 |
| **数据底表（库存类）** | `indep_rl_ads.a02_e2e_product_performance_inv_summary_d`：EOH Unit / EOH Amt / In-transit Unit、ST% 分母（期末库存金额）等期末库存指标及库存类 YOY 指标 |
| **全局支持筛选维度（渠道）** | 渠道：platform（取值 `platform`）、store name（取值 `shop_name`） |
| **全局支持筛选维度（商品）** | 商品：label（取值 `label`）、division（取值 `division`）、product type（取值 `product_type`）、framework（取值 `framework`）、category（取值 `category`）、ax class（取值 `ax_class`）、category summary（取值 `category_summary`）、special supply（取值 `special_supply`）、predictive buy（取值 `predictive_buy`）；取值清单见文末附录 |
| **商品维度切换** | Label：`label` / Super Season：`super_season` / Product type：`product_type` / Category：`category` / MD type：`md_type` / Division：`division` |
| **时间口径（区间类）** | SLS Unit（TY）、SLS Amt（TY）及 ST% 分子（销售金额）：看所选时间范围（区间汇总） |
| **时间口径（期末时点类）** | EOH Unit / EOH Amt / In-transit Unit（TY）及 ST% 分母（期末库存金额）：看所选时间范围 end period 最后一天（时点数） |
| **时间口径（LY 销售类）** | SLS Unit（LY）、SLS Amt（LY）及 ST%（LY）销售金额：看所选时间范围去年同期（区间汇总） |
| **时间口径（LY 库存类）** | EOH Unit（LY）、EOH Amt（LY）、In-transit Unit（LY）：看所选时间范围去年同期 end period 最后一天（时点数）；ST%（LY）期末库存金额：仍看所选时间范围 end period 最后一天（当前期末，非去年同期） |
| **YOY 计算口径** | 今年 / 去年 - 1（基于 TY 与 LY 同期对比） |
| **附属指标** | 原始口径「附属指标」列全部为空，本板块所有指标均无附属指标（无 vs LY 附属指标、无 TAR ACH%） |
| **数据类型/数据格式** | 原始口径未定义数据类型与数据格式，本文档按 Merchandise Performance Overview 口径文档同一展示规范标注（currency / integer / percent_0dp），DAX 实现时如与业务需求存在争议需与业务确认 |
| **必须遵守** | 口径文档中定义的所有指标，必须遵守其数据类型和数据格式，如果和解决方案中存在争议的，一切以口径文档为准，必须按照口径文档中的格式进行调整 |
| **DAX 语法规范** | 文本常量必须使用双引号 `" "`，禁止使用单引号；单引号 `' '` 仅用于表名，列名使用方括号 `[ ]`，例如：`[md_type] = "FP"` |

---

## 子模块一：Sales & Inventory Penetration Trend【Sales】

> **商品维度切换**: Label：`label` / Super Season：`super_season` / Product type：`product_type` / Category：`category` / MD type：`md_type` / Division：`division`
> **支持筛选维度**: 渠道：platform，shop_name；商品：label，division，product_type，framework，category，ax_class，category_summary，special_supply，predictive_buy

### 1. SLS Amt% — 销售金额占比

| 项目 | 内容 |
|---|---|
| **指标名称** | SLS Amt% / 销售金额占比 |
| **业务定义** | 单品类占总品类的比例 |
| **计算公式** | 分子：各 label / super_season / product_type / category / md_type / division 下 `sum(net_sales_amt)`；分母：`sum(net_sales_amt)` |
| **数据底表** | `indep_rl_ads.a02_e2e_product_performance_sales_summary_d` |
| **数据类型** | percent_0dp → 百分比整数，不含正号 |
| **数据格式** | `#,##0%` |

---

### 2. SLS Unit（TY）— DCom净销售数量

| 项目 | 内容 |
|---|---|
| **指标名称** | SLS Unit（TY）/ DCom净销售数量 |
| **业务定义** | 统计周期内DCom净销售数量 = DCom销售订单总销售数量 - 退货数量 |
| **计算公式** | `sum(net_sales_qty)` |
| **数据底表** | `indep_rl_ads.a02_e2e_product_performance_sales_summary_d` |
| **数据类型** | integer → 整数，千分位整数 |
| **数据格式** | `#,##0` |

---

### 3. SLS Amt（TY）— DCom净销售额

| 项目 | 内容 |
|---|---|
| **指标名称** | SLS Amt（TY）/ DCom净销售额 |
| **业务定义** | 统计周期内DCom净销售额 = DCom销售订单总销售额 - 退货额 |
| **计算公式** | `sum(net_sales_amt)` |
| **数据底表** | `indep_rl_ads.a02_e2e_product_performance_sales_summary_d` |
| **数据类型** | currency → 货币符号由币种切片器决定，千分位整数 |
| **数据格式** | `#,##0`（在 DAX 中用 `__CurrencySymbol & FORMAT(__Value, "#,##0")` 拼接币种符号） |

---

### 4. ST%（TY）— 售罄率%（金额）

| 项目 | 内容 |
|---|---|
| **指标名称** | ST%（TY）/ 售罄率%（金额） |
| **业务定义** | 统计周期内销售金额 /（销售金额 + 期末库存金额）× 100% |
| **计算公式** | 销售金额：看所选时间范围销售金额之和；期末库存金额：看所选时间范围 end period 最后一天；`sales.net_sales_amt / (sales.net_sales_amt + inv.msrp_inv_amt)` |
| **数据底表** | `indep_rl_ads.a02_e2e_product_performance_sales_summary_d`（sales）；`indep_rl_ads.a02_e2e_product_performance_inv_summary_d`（inv） |
| **数据类型** | percent_0dp → 百分比整数，不含正号 |
| **数据格式** | `#,##0%` |

---

### 5. SLS Unit（LY）— DCom净销售数量

| 项目 | 内容 |
|---|---|
| **指标名称** | SLS Unit（LY）/ DCom净销售数量 |
| **业务定义** | 统计周期内DCom净销售数量 = DCom销售订单总销售数量 - 退货数量 |
| **计算公式** | 看所选时间范围去年同期；`sum(net_sales_qty)` |
| **数据底表** | `indep_rl_ads.a02_e2e_product_performance_sales_summary_d` |
| **数据类型** | integer → 整数，千分位整数 |
| **数据格式** | `#,##0` |

---

### 6. SLS Amt（LY）— DCom净销售额

| 项目 | 内容 |
|---|---|
| **指标名称** | SLS Amt（LY）/ DCom净销售额 |
| **业务定义** | 统计周期内DCom净销售额 = DCom销售订单总销售额 - 退货额 |
| **计算公式** | 看所选时间范围去年同期；`sum(net_sales_amt)` |
| **数据底表** | `indep_rl_ads.a02_e2e_product_performance_sales_summary_d` |
| **数据类型** | currency → 货币符号由币种切片器决定，千分位整数 |
| **数据格式** | `#,##0`（在 DAX 中用 `__CurrencySymbol & FORMAT(__Value, "#,##0")` 拼接币种符号） |

---

### 7. ST%（LY）— 售罄率%（金额）

| 项目 | 内容 |
|---|---|
| **指标名称** | ST%（LY）/ 售罄率%（金额） |
| **业务定义** | 统计周期内销售金额 /（销售金额 + 期末库存金额）× 100% |
| **计算公式** | 销售金额：看所选时间范围去年同期销售金额之和；期末库存金额：看所选时间范围 end period 最后一天；`sales.net_sales_amt / (sales.net_sales_amt + inv.msrp_inv_amt)` |
| **数据底表** | `indep_rl_ads.a02_e2e_product_performance_sales_summary_d`（sales）；`indep_rl_ads.a02_e2e_product_performance_inv_summary_d`（inv） |
| **特殊说明** | LY 的销售金额取去年同期区间，但期末库存金额仍取当前所选时间范围 end period 最后一天（非去年同期期末），原始口径如此定义，DAX 实现时需与业务确认 |
| **数据类型** | percent_0dp → 百分比整数，不含正号 |
| **数据格式** | `#,##0%` |

---

### 8. SLS Amt YOY — DCom净销售额YOY

| 项目 | 内容 |
|---|---|
| **指标名称** | SLS Amt YOY / DCom净销售额YOY |
| **业务定义** | 今年 / 去年 - 1 |
| **计算公式** | `sum(net_sales_amt)`，今年 / 去年 - 1 |
| **数据底表** | `indep_rl_ads.a02_e2e_product_performance_sales_summary_d` |
| **特殊说明** | 原始口径仅定义「今年 / 去年 - 1」，「去年」按本板块 LY 口径理解为去年同期，DAX 实现时需与业务确认 |
| **数据类型** | percent_0dp → 百分比整数，不含正号 |
| **数据格式** | `#,##0%` |

---

### 9. SLS Unit YOY — DCom净销售数量YOY

| 项目 | 内容 |
|---|---|
| **指标名称** | SLS Unit YOY / DCom净销售数量YOY |
| **业务定义** | 今年 / 去年 - 1 |
| **计算公式** | `sum(net_sales_qty)`，今年 / 去年 - 1 |
| **数据底表** | `indep_rl_ads.a02_e2e_product_performance_sales_summary_d` |
| **特殊说明** | 原始口径仅定义「今年 / 去年 - 1」，「去年」按本板块 LY 口径理解为去年同期，DAX 实现时需与业务确认 |
| **数据类型** | percent_0dp → 百分比整数，不含正号 |
| **数据格式** | `#,##0%` |

---

## 子模块二：Sales & Inventory Penetration Trend【Inventory】

> **商品维度切换**: Label：`label` / Super Season：`super_season` / Product type：`product_type` / Category：`category` / MD type：`md_type` / Division：`division`
> **支持筛选维度**: 渠道：platform，shop_name；商品：label，division，product_type，framework，category，ax_class，category_summary，special_supply，predictive_buy

### 10. EOH Amt% — 期末库存金额占比

| 项目 | 内容 |
|---|---|
| **指标名称** | EOH Amt% / 期末库存金额占比 |
| **业务定义** | 根据所筛选维度统计对应 EOH amt 占比 |
| **计算公式** | 分子：各 label / super_season / product_type / category / md_type / division 下，看所选时间范围 end period 最后一天，`sum(msrp_inv_amt)`；分母：看所选时间范围 end period 最后一天，`sum(msrp_inv_amt)` |
| **数据底表** | `indep_rl_ads.a02_e2e_product_performance_inv_summary_d` |
| **数据类型** | percent_0dp → 百分比整数，不含正号 |
| **数据格式** | `#,##0%` |

---

### 11. EOH Unit（TY）— 期末库存数量

| 项目 | 内容 |
|---|---|
| **指标名称** | EOH Unit（TY）/ 期末库存数量 |
| **业务定义** | 选定日期业务周期结束时点的期末库存总数量 |
| **计算公式** | 看所选时间范围 end period 最后一天；`sum(inv_qty)` |
| **数据底表** | `indep_rl_ads.a02_e2e_product_performance_inv_summary_d` |
| **数据类型** | integer → 整数，千分位整数 |
| **数据格式** | `#,##0` |

---

### 12. EOH Amt（TY）— 期末库存金额

| 项目 | 内容 |
|---|---|
| **指标名称** | EOH Amt（TY）/ 期末库存金额 |
| **业务定义** | EOH Units * msrp |
| **计算公式** | 看所选时间范围 end period 最后一天；`sum(msrp_inv_amt)` |
| **数据底表** | `indep_rl_ads.a02_e2e_product_performance_inv_summary_d` |
| **数据类型** | currency → 货币符号由币种切片器决定，千分位整数 |
| **数据格式** | `#,##0`（在 DAX 中用 `__CurrencySymbol & FORMAT(__Value, "#,##0")` 拼接币种符号） |

---

### 13. In-transit Unit（TY）— 在途库存数量

| 项目 | 内容 |
|---|---|
| **指标名称** | In-transit Unit（TY）/ 在途库存数量 |
| **业务定义** | 已出库尚未入库到仓的货品总件数 |
| **计算公式** | 看所选时间范围 end period 最后一天；`sum(in_trans_inv_qty)` |
| **数据底表** | `indep_rl_ads.a02_e2e_product_performance_inv_summary_d` |
| **数据类型** | integer → 整数，千分位整数 |
| **数据格式** | `#,##0` |

---

### 14. ST%（TY）— 售罄率%（金额）

| 项目 | 内容 |
|---|---|
| **指标名称** | ST%（TY）/ 售罄率%（金额） |
| **业务定义** | 统计周期内销售金额 /（销售金额 + 期末库存金额）× 100% |
| **计算公式** | 销售金额：看所选时间范围销售金额之和；期末库存金额：看所选时间范围 end period 最后一天；`sales.net_sales_amt / (sales.net_sales_amt + inv.msrp_inv_amt)` |
| **数据底表** | `indep_rl_ads.a02_e2e_product_performance_sales_summary_d`（sales）；`indep_rl_ads.a02_e2e_product_performance_inv_summary_d`（inv） |
| **特殊说明** | 本行与子模块一 ST%（TY）口径完全一致，两个子板块各展示一次 |
| **数据类型** | percent_0dp → 百分比整数，不含正号 |
| **数据格式** | `#,##0%` |

---

### 15. EOH Unit（LY）— 期末库存数量

| 项目 | 内容 |
|---|---|
| **指标名称** | EOH Unit（LY）/ 期末库存数量 |
| **业务定义** | 选定日期业务周期结束时点的期末库存总数量 |
| **计算公式** | 看所选时间范围去年同期 end period 最后一天；`sum(inv_qty)` |
| **数据底表** | `indep_rl_ads.a02_e2e_product_performance_inv_summary_d` |
| **数据类型** | integer → 整数，千分位整数 |
| **数据格式** | `#,##0` |

---

### 16. EOH Amt（LY）— 期末库存金额

| 项目 | 内容 |
|---|---|
| **指标名称** | EOH Amt（LY）/ 期末库存金额 |
| **业务定义** | EOH Units * msrp |
| **计算公式** | 看所选时间范围去年同期 end period 最后一天；`sum(msrp_inv_amt)` |
| **数据底表** | `indep_rl_ads.a02_e2e_product_performance_inv_summary_d` |
| **数据类型** | currency → 货币符号由币种切片器决定，千分位整数 |
| **数据格式** | `#,##0`（在 DAX 中用 `__CurrencySymbol & FORMAT(__Value, "#,##0")` 拼接币种符号） |

---

### 17. In-transit Unit（LY）— 在途库存数量

| 项目 | 内容 |
|---|---|
| **指标名称** | In-transit Unit（LY）/ 在途库存数量 |
| **业务定义** | 已出库尚未入库到仓的货品总件数 |
| **计算公式** | 看所选时间范围去年同期 end period 最后一天；`sum(in_trans_inv_qty)` |
| **数据底表** | `indep_rl_ads.a02_e2e_product_performance_inv_summary_d` |
| **数据类型** | integer → 整数，千分位整数 |
| **数据格式** | `#,##0` |

---

### 18. ST%（LY）— 售罄率%（金额）

| 项目 | 内容 |
|---|---|
| **指标名称** | ST%（LY）/ 售罄率%（金额） |
| **业务定义** | 统计周期内销售金额 /（销售金额 + 期末库存金额）× 100% |
| **计算公式** | 销售金额：看所选时间范围去年同期销售金额之和；期末库存金额：看所选时间范围 end period 最后一天；`sales.net_sales_amt / (sales.net_sales_amt + inv.msrp_inv_amt)` |
| **数据底表** | `indep_rl_ads.a02_e2e_product_performance_sales_summary_d`（sales）；`indep_rl_ads.a02_e2e_product_performance_inv_summary_d`（inv） |
| **特殊说明** | 与子模块一 ST%（LY）口径一致：LY 销售金额取去年同期区间，期末库存金额仍取当前所选时间范围 end period 最后一天（非去年同期期末），原始口径如此定义，DAX 实现时需与业务确认 |
| **数据类型** | percent_0dp → 百分比整数，不含正号 |
| **数据格式** | `#,##0%` |

---

### 19. EOH Amt YOY — 期末库存YOY

| 项目 | 内容 |
|---|---|
| **指标名称** | EOH Amt YOY / 期末库存YOY（原始口径 Name_CN 为「期末库存数量YOY」） |
| **业务定义** | 今年 / 去年 - 1 |
| **计算公式** | 今年 / 去年 - 1 |
| **数据底表** | `indep_rl_ads.a02_e2e_product_performance_inv_summary_d` |
| **注意** | 原始口径该行 Name_EN 为 EOH Amt YOY、Name_CN 为「期末库存数量YOY」，与下一行 EOH Unit YOY / 「期末库存金额YOY」的 EN/CN 名称交叉错位，DAX 实现时需与业务确认两行指标的对应关系（金额 YOY 对应 EOH Amt（TY）/ EOH Amt（LY），数量 YOY 对应 EOH Unit（TY）/ EOH Unit（LY）） |
| **数据类型** | percent_0dp → 百分比整数，不含正号 |
| **数据格式** | `#,##0%` |

---

### 20. EOH Unit YOY — 期末库存YOY

| 项目 | 内容 |
|---|---|
| **指标名称** | EOH Unit YOY / 期末库存YOY（原始口径 Name_CN 为「期末库存金额YOY」） |
| **业务定义** | 今年 / 去年 - 1 |
| **计算公式** | 今年 / 去年 - 1 |
| **数据底表** | `indep_rl_ads.a02_e2e_product_performance_inv_summary_d` |
| **注意** | 原始口径该行 Name_EN 为 EOH Unit YOY、Name_CN 为「期末库存金额YOY」，与上一行 EOH Amt YOY / 「期末库存数量YOY」的 EN/CN 名称交叉错位，DAX 实现时需与业务确认两行指标的对应关系（金额 YOY 对应 EOH Amt（TY）/ EOH Amt（LY），数量 YOY 对应 EOH Unit（TY）/ EOH Unit（LY）） |
| **数据类型** | percent_0dp → 百分比整数，不含正号 |
| **数据格式** | `#,##0%` |

---

## 通用规则汇总

| 规则项 | 说明 |
|---|---|
| **数据底表** | 销售类指标用 `indep_rl_ads.a02_e2e_product_performance_sales_summary_d`；库存类指标用 `indep_rl_ads.a02_e2e_product_performance_inv_summary_d`；ST% 跨双表（sales + inv） |
| **全局支持筛选维度** | 渠道：platform、shop_name；商品：label，division，product_type，framework，category，ax_class，category_summary，special_supply，predictive_buy |
| **商品维度切换** | Label / super_season / product_type / category / md_type / division（对应占比指标公式分子中的维度） |
| **时间口径** | 区间类（TY 销售及 ST% 分子）：看所选时间范围汇总；期末库存类（EOH / In-transit（TY）及 ST% 分母）：看所选时间范围 end period 最后一天；LY 销售：看所选时间范围去年同期汇总；LY 库存：看所选时间范围去年同期 end period 最后一天；ST%（LY）：销售取去年同期、期末库存取当前 end period 最后一天 |
| **YOY 规则** | 今年 / 去年 - 1，无附属指标，作为独立指标行展示 |
| **附属指标** | 原始口径「附属指标」列全部为空，本板块所有指标均无附属指标（无 vs LY 附属、无 TAR ACH%） |
| **名称交叉错位** | EOH Amt YOY（期末库存数量YOY）与 EOH Unit YOY（期末库存金额YOY）两行原始口径 EN/CN 名称交叉，DAX 实现时需与业务确认对应关系 |
| **必须遵守** | 口径文档中定义的所有指标，必须遵守其数据类型和数据格式，如果和解决方案中存在争议的，一切以口径文档为准，必须按照口径文档中的格式进行调整 |
| **DAX 语法规范** | 文本常量必须使用双引号 `" "`，禁止使用单引号；单引号 `' '` 仅用于表名，列名使用方括号 `[ ]`，例如：`[md_type] = "FP"` |

---

## 附录：商品筛选维度取值清单

> 来自原始口径「全局支持筛选维度」商品维度行的取值清单，供切片器/维度表建设参考；渠道维度（platform、shop_name）取值以数据表为准。注意：原始口径表头的全局维度清单未包含 category summary（仅指标行的支持筛选维度包含 category_summary），category_summary 取值清单请参考 Merchandise Performance Overview 口径文档附录。

| 筛选维度 | 取值字段 | 取值清单（原始口径） |
|---|---|---|
| label | `label` | W Polo、FJ、CL、PL、CW、M Polo、RRL、HM、Lauren |
| division | `division` | WM、FJ、CW、HM、MN |
| product type | `product_type` | 618 Commercial、BSR、CYO/DTG、Carryover、Commercial、D11 Commercial、Excess、FA23、FA24、FA25、FA26、GWP、HO23、HO24、HO25、HO26、PF23、PF24、PF25、PF26、PS23、PS24、PS25、PS26、PSR、SP23、SP24、SP25、SP26、SP27、SU23、SU24、SU25、SU26、SU27 |
| framework | `framework` | Acceleration、Complementary、Foundation、Secondary、Primary |
| category | `category` | Sportcoat、Sweatshirt、Handbags、Swim、Footwear、Jewelry、Sweaters、Sport shirts、Belts、Dresses、T-shirt、Sneakers、Denim、Caps、Shirt、Belts/Small Accessories、Small Leathergoods、Polo shirt、Jeans、Outerwear、Pant、Sleepwear、Shirts、Sport Shirt、Skirt、Belts/small accessories、Luggage/Bags、T-Shirt、Sweater、Headwear、Pants、Skirts |
| ax class | `ax_class` | Large Leathergoods、Top Coat、OVERALL、Legging、Mens Fragrance、HEADWEAR、Trouser、Sport Shirt、Hdwr/umbrla/glv/scrv、NECKWEAR、GIFTS、SETS、ACCESSORIES、DRESSES、Fashion Jewelry、SMALL ACCESSORIES、SPORTS EQUIPMENT、Childrenswear Small Accessories、SCARF、Casual Footwear、Coverall、Skirt、Hats/gloves、Eyewear、Hosiery、Hats/Gloves、Gifts、Neckwear、T-Shirt、EYEWEAR、WOMENS FRAGRANCE、OUTERWEAR、Luggage、Sweater、Headwear、Bath、LUGGAGE、TABLETOP、SKIRT、Pet Apparel、COVERALL、Tailored Casual Footwear、MENS FRAGRANCE、VEST、JACKET、PANT、SHORT、Bags、Fine Jewelry、SWEATER、TROUSER、Underwear、Childrenswear Socks/Underwear/Hosiery、TOP COAT、Gloves、SUIT、Braces、HANDBAGS、BATH、Home Accessories、Sports Equipment、SLEEPWEAR、DRESS SHIRT、Childrenswear Footwear、Sportcoat、ONE PIECE、Jumpsuit、Knit、Handbags、UNDERWEAR、Childrenswear Cold Weather、Sets、Suit、Personal Towel、SWIM、Swim、Footwear、Dress Footwear、Childrenswear Socks/underwear/hosiery、Scarf、HOSIERY、Jewelry、One Piece、Small Accessories、SMALL LEATHERGOODS、BEDDING、Hdwr/Umbrla/Glv/Scrv、Womens Fragrance、FASHION JEWELRY、Belts、T-SHIRT、SHIRT、DENIM、Dresses、BAGS、T-shirt、Vest、Denim、LEGGING、Shirt、PET APPAREL、Umbrellas、Small Leathergoods、BELTS、Bedding、Dress Shirt、HOME ACCESSORIES、HDWR/UMBRLA/GLV/SCRV、Bottoms、JUMPSUIT、Jacket、Tabletop、Watch Accessories、Home Fragrance、SPORT SHIRT、Overall、Short、FOOTWEAR、KNIT、GLOVES、Outerwear、Decorative Home、Pant、JEWELRY、HOME FRAGRANCE、Accessories、SPORTCOAT、Sleepwear、Fine Watches |
| special supply | `special_supply` | TM、JD |
| predictive buy | `predictive_buy` | 1、0 |
