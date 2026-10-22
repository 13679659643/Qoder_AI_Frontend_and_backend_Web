# Dimension Cross Analysis 指标口径提示词

> **Dashboard**: RL E2E Merch Dashboard  
> **Tab**: Dimension Cross Analysis  
> **数据底表（销售汇总类）**: `a02_e2e_product_performance_sales_summary_d`  
> **数据底表（库存汇总类）**: `a02_e2e_product_performance_inv_summary_d`  
> **数据底表（销售明细类）**: `s02_trade_sku_data_d`  
> **数据底表（库存明细类）**: `s02_inventory_stock_sales_detail_d`  
> **数据底表（目标类）**: `a05_e2e_product_fcst_data_d`  
> **模块说明**: 本板块为商品维度交叉分析看板，覆盖 Label Sales & Inventory Structure（Label / 交叉视图）、Product Type Sales & Inventory Structure（Product Type / 交叉视图 / Category×Division/Label）、MD Sales Structure、Item Stockout & Slow Mover Alert、Platform Merchandising Performance、Top & OPP SKUs Analysis、Handbags Sales Performance、Handbags Sales Analysis by Dimension 子板块，统计各商品维度层级下的销售、库存、占比、售罄率、AUR、MD、库存周转周数、补货及 TAR 达成等指标。

---

## 全局逻辑

| 项目 | 内容 |
|---|---|
| **数据底表（销售汇总类）** | `a02_e2e_product_performance_sales_summary_d`：Label / Product Type / Category×Division/Label / MD Sales Structure / Platform Merchandising Performance 板块的销售类指标及占比分子分母（区间汇总） |
| **数据底表（库存汇总类）** | `a02_e2e_product_performance_inv_summary_d`：对应板块的 EOH 类期末时点指标及 ST% 库存分母 |
| **数据底表（销售明细类）** | `s02_trade_sku_data_d`：Item Stockout & Slow Mover Alert、Top & OPP SKUs Analysis、Handbags 两个板块的销售类指标（SKU 明细粒度） |
| **数据底表（库存明细类）** | `s02_inventory_stock_sales_detail_d`：对应板块的 EOH / In-transit / ST% 库存分母 / Alert / Available sizes / Replenishment Count 等指标 |
| **数据底表（目标类）** | `a05_e2e_product_fcst_data_d`：Platform Merchandising Performance 板块 TAR 类指标的 target 来源 |
| **全局支持筛选维度** | 原始口径「支持筛选维度」列为空，未定义全局筛选维度；各板块行维度与维度切换见子模块说明，外部筛选维度 DAX 实现时需与业务确认 |
| **板块级商品维度切换** | Label / Product Type 板块：Label、Super Season、Product type、Category、MD type、Division（切换聚合视图）；Category×Division/Label 板块：Label / Division；MD Sales Structure：Division；Item 预警板块：Item（spu_id）/ SKU（sku_id）；Platform Merchandising：Platform（platform）/ Store（shop_name）；Top & OPP：TOP / OPP；Handbags Performance：前置筛选 category = Handbags/Outwear；Handbags by Dimension：渠道 TTL/TMALL/JD/RLE/DY/DY_W/DY_MN + 商品维度组合 |
| **数量/金额口径判定** | 以 Name_EN 为准：Unit = 数量口径，Amt = 金额口径；Name_EN 无 Unit/Amt 后缀的 ST% 类指标为数量口径（本次已确认）；计算字段以原始口径计算指标列为准，与名称量纲冲突处按已确认结论修正（见通用规则汇总修正记录） |
| **时间口径（区间类）** | SLS、AUR、MD 及各占比分子分母等：看所选时间范围 this period（区间汇总） |
| **时间口径（期末时点类）** | EOH、In-transit、ST% 库存分母、Available sizes、Replenishment Count 等：看所选时间范围 end period 最后一天（时点数） |
| **时间口径（MTD/YTD 类）** | MTD：end period 所在财月第一天至 end period 最后一天；YTD：end period 所在财年第一天至 end period 最后一天；均与 last period 无关 |
| **vs LP 附属指标（差值 bp）** | 占比类主指标的 vs LP：this period - last period（差值，bp 指标，展示时 ×10000 转 bp） |
| **vs LP 附属指标（变化率）** | 数值类主指标的 vs LP（Amt vs LP / EOH vs LP 等）：this period / last period - 1 |
| **vs LY 附属指标（差值 bp）** | 今年 - 去年（差值，bp 指标，展示时 ×10000 转 bp）；「今年/去年」时间范围原始口径未细化，按今年同期 - 上个财年同期固定对比理解（见待确认项汇总） |
| **数据类型/数据格式** | 原始口径未定义数据类型与数据格式，本文档参照《数据类型和格式总览》及同看板已确认口径补齐，DAX 实现时以本口径文档为准 |
| **必须遵守** | 口径文档中定义的所有指标，必须遵守其数据类型和数据格式，如果和解决方案中存在争议的，一切以口径文档为准，必须按照口径文档中的格式进行调整 |
| **DAX 语法规范** | 文本常量必须使用双引号 `" "`，禁止使用单引号；单引号 `' '` 仅用于表名，列名使用方括号 `[ ]`，例如：`[md_type] = "FP"` |

---

## 子模块一：Label Sales & Inventory Structure【Label】

> **行维度**: Label：`label`（板块商品维度切换：Label / Super Season：`super_season` / Product type：`product_type` / Category：`category` / MD type：`md_type` / Division：`division`，本视图聚合在 Label 粒度）

### 1. SLS Amt% — 销售金额占比

| 项目 | 内容 |
|---|---|
| **指标名称** | SLS Amt% / 销售金额占比 |
| **业务定义** | 单品类占总品类的比例 |
| **计算公式** | 时间范围看 this period；分子：各 label 下 `sum(net_sales_amt)`；分母：`sum(net_sales_amt)` |
| **数据底表** | `a02_e2e_product_performance_sales_summary_d` |
| **附属指标** | SLS Amt% vs LP：this period - last period（差值，bp 指标，展示时 ×10000 转 bp） |
| **数据类型** | percent_0dp → 百分比整数，不含正号 |
| **数据格式** | `#,##0%` |
| **附属指标类型** | SLS Amt% vs LP:delta_bp |

---

### 2. EOH Amt% — 期末库存金额占比

| 项目 | 内容 |
|---|---|
| **指标名称** | EOH Amt% / 期末库存金额占比 |
| **业务定义** | 根据所筛选维度统计对应 EOH amt 占比 |
| **计算公式** | 看所选时间范围 end period 最后一天；分子：各 label 下 `sum(msrp_inv_amt)`；分母：`sum(msrp_inv_amt)` |
| **数据底表** | `a02_e2e_product_performance_inv_summary_d` |
| **附属指标** | EOH Amt% vs LP：this period - last period（差值，bp 指标，展示时 ×10000 转 bp） |
| **数据类型** | percent_0dp → 百分比整数，不含正号 |
| **数据格式** | `#,##0%` |
| **附属指标类型** | EOH Amt% vs LP:delta_bp |

---

### 3. SLS Unit — DCom净销售数量

| 项目 | 内容 |
|---|---|
| **指标名称** | SLS Unit / DCom净销售数量 |
| **业务定义** | 统计周期内该 label 下净销售数量之和 |
| **计算公式** | 时间范围看 this period；该 label 下 `sum(net_sales_qty)` |
| **数据底表** | `a02_e2e_product_performance_sales_summary_d` |
| **数据类型** | integer → 整数，千分位整数 |
| **数据格式** | `#,##0` |

---

### 4. EOH Unit — 期末库存数量

| 项目 | 内容 |
|---|---|
| **指标名称** | EOH Unit / 期末库存数量 |
| **业务定义** | 选定日期业务周期结束时点的期末库存总数量 |
| **计算公式** | 看所选时间范围 end period 最后一天；该 label 下 `sum(inv_qty)` |
| **数据底表** | `a02_e2e_product_performance_inv_summary_d` |
| **数据类型** | integer → 整数，千分位整数 |
| **数据格式** | `#,##0` |

---

### 5. YTD ST% — YTD售罄率%

| 项目 | 内容 |
|---|---|
| **指标名称** | YTD ST% / YTD售罄率% |
| **业务定义** | 所选财年年初至今销售数量 /（销售数量 + 期末库存数量）× 100% |
| **计算公式** | 销售数量：看所选时间范围 end period 所在财年第一天至 end period 最后一天销售数量之和；期末库存数量：看所选时间范围 end period 最后一天；该 label 下 `sales.net_sales_qty / (sales.net_sales_qty + inv.inv_qty)` |
| **数据底表** | `a02_e2e_product_performance_sales_summary_d`（sales）；`a02_e2e_product_performance_inv_summary_d`（inv） |
| **注意** | 原始口径公式为金额口径 `sales.net_sales_amt/(sales.net_sales_amt+inv.msrp_inv_amt)`，已确认修正为数量口径；原始描述中"销售金额/期末库存金额"字样以公式为准（数量口径） |
| **数据类型** | percent_0dp → 百分比整数，不含正号 |
| **数据格式** | `#,##0%` |

---

### 6. MD — 平均折扣

| 项目 | 内容 |
|---|---|
| **指标名称** | MD / 平均折扣 |
| **业务定义** | 1 - 折扣价 / 原价 × 100% |
| **计算公式** | 时间范围看 this period；该 label 下 `1 - sum(md_net_sales_amt) / sum(msrp_net_sales_amt)` |
| **数据底表** | `a02_e2e_product_performance_sales_summary_d` |
| **数据类型** | percent_0dp → 百分比整数，不含正号 |
| **数据格式** | `#,##0%` |

---

## 子模块二：Label Sales & Inventory Structure【Super Season/Product Type/Category/MD Type/Division】

> **行维度**: Label：`label` × 所选商品维度（Super Season：`super_season` / Product type：`product_type` / Category：`category` / MD type：`md_type` / Division：`division`）
> **视图说明**: 以 Label 为基数，看所选商品维度在该 Label 的占比

### 7. SLS Amt% — 销售金额占比

| 项目 | 内容 |
|---|---|
| **指标名称** | SLS Amt% / 销售金额占比 |
| **业务定义** | 以 Label 为基数，看所选商品维度在该 Label 的占比 |
| **计算公式** | 时间范围看 this period；分子：该 label 下各 super_season / product_type / category / md_type / division `sum(net_sales_amt)`；分母：该 label 下 `sum(net_sales_amt)` |
| **数据底表** | `a02_e2e_product_performance_sales_summary_d` |
| **注意** | 已确认修正为金额字段（与 Name_EN 及【Label】视图口径一致）`sum(net_sales_amt)` |
| **数据类型** | percent_0dp → 百分比整数，不含正号 |
| **数据格式** | `#,##0%` |
| **附属指标类型** | SLS Amt:currency |

---

### 8. EOH Amt% — 期末库存金额占比

| 项目 | 内容 |
|---|---|
| **指标名称** | EOH Amt% / 期末库存金额占比 |
| **业务定义** | 以 Label 为基数，看所选商品维度在该 Label 的占比 |
| **计算公式** | 看所选时间范围 end period 最后一天；分子：该 label 下各 super_season / product_type / category / md_type / division `sum(msrp_inv_amt)`；分母：该 label 下 `sum(msrp_inv_amt)` |
| **数据底表** | `a02_e2e_product_performance_inv_summary_d` |
| **注意** | 已确认修正为金额字段 `msrp_inv_amt` |
| **数据类型** | percent_0dp → 百分比整数，不含正号 |
| **数据格式** | `#,##0%` |
| **附属指标类型** | EOH Amt:currency |

---

## 子模块三：Product Type Sales & Inventory Structure【Product Type】

> **行维度**: Product type：`product_type`（板块商品维度切换同子模块一，本视图聚合在 Product Type 粒度）

### 9. SLS Amt% — 销售金额占比

| 项目 | 内容 |
|---|---|
| **指标名称** | SLS Amt% / 销售金额占比 |
| **业务定义** | 单品类占总品类的比例 |
| **计算公式** | 时间范围看 this period；分子：各 product_type 下 `sum(net_sales_amt)`；分母：`sum(net_sales_amt)` |
| **数据底表** | `a02_e2e_product_performance_sales_summary_d` |
| **附属指标** | SLS Amt% vs LP：this period - last period（差值，bp 指标，展示时 ×10000 转 bp） |
| **数据类型** | percent_0dp → 百分比整数，不含正号 |
| **数据格式** | `#,##0%` |
| **附属指标类型** | SLS Amt% vs LP:delta_bp |

---

### 10. EOH Amt% — 期末库存金额占比

| 项目 | 内容 |
|---|---|
| **指标名称** | EOH Amt% / 期末库存金额占比 |
| **业务定义** | 根据所筛选维度统计对应 EOH amt 占比 |
| **计算公式** | 看所选时间范围 end period 最后一天；分子：各 product_type 下 `sum(msrp_inv_amt)`；分母：`sum(msrp_inv_amt)` |
| **数据底表** | `a02_e2e_product_performance_inv_summary_d` |
| **附属指标** | EOH Amt% vs LP：this period - last period（差值，bp 指标，展示时 ×10000 转 bp） |
| **数据类型** | percent_0dp → 百分比整数，不含正号 |
| **数据格式** | `#,##0%` |
| **附属指标类型** | EOH Amt% vs LP:delta_bp |

---

### 11. SLS Unit — DCom净销售数量

| 项目 | 内容 |
|---|---|
| **指标名称** | SLS Unit / DCom净销售数量 |
| **业务定义** | 统计周期内该 product_type 下净销售数量之和 |
| **计算公式** | 时间范围看 this period；该 product_type 下 `sum(net_sales_qty)` |
| **数据底表** | `a02_e2e_product_performance_sales_summary_d` |
| **数据类型** | integer → 整数，千分位整数 |
| **数据格式** | `#,##0` |

---

### 12. EOH Unit — 期末库存数量

| 项目 | 内容 |
|---|---|
| **指标名称** | EOH Unit / 期末库存数量 |
| **业务定义** | 选定日期业务周期结束时点的期末库存总数量 |
| **计算公式** | 看所选时间范围 end period 最后一天；该 product_type 下 `sum(inv_qty)` |
| **数据底表** | `a02_e2e_product_performance_inv_summary_d` |
| **数据类型** | integer → 整数，千分位整数 |
| **数据格式** | `#,##0` |

---

### 13. YTD ST% — YTD售罄率%

| 项目 | 内容 |
|---|---|
| **指标名称** | YTD ST% / YTD售罄率% |
| **业务定义** | 所选财年年初至今销售数量 /（销售数量 + 期末库存数量）× 100% |
| **计算公式** | 销售数量：看所选时间范围 end period 所在财年第一天至 end period 最后一天销售数量之和；期末库存数量：看所选时间范围 end period 最后一天；该 product_type 下 `sales.net_sales_qty / (sales.net_sales_qty + inv.inv_qty)` |
| **数据底表** | `a02_e2e_product_performance_sales_summary_d`（sales）；`a02_e2e_product_performance_inv_summary_d`（inv） |
| **注意** | 原始口径公式为金额口径，已确认修正为数量口径（同子模块一 YTD ST%） |
| **数据类型** | percent_0dp → 百分比整数，不含正号 |
| **数据格式** | `#,##0%` |

---

### 14. MD — 平均折扣

| 项目 | 内容 |
|---|---|
| **指标名称** | MD / 平均折扣 |
| **业务定义** | 1 - 折扣价 / 原价 × 100% |
| **计算公式** | 时间范围看 this period；该 product_type 下 `1 - sum(md_net_sales_amt) / sum(msrp_net_sales_amt)` |
| **数据底表** | `a02_e2e_product_performance_sales_summary_d` |
| **数据类型** | percent_0dp → 百分比整数，不含正号 |
| **数据格式** | `#,##0%` |

---

## 子模块四：Product Type Sales & Inventory Structure【Super Season/Label/Category/MD Type/Division】

> **行维度**: Product type：`product_type` × 所选商品维度（Super Season：`super_season` / Label：`label` / Category：`category` / MD type：`md_type` / Division：`division`）
> **视图说明**: 以 Product Type 为基数，看所选商品维度在该 Product Type 的占比

### 15. SLS Amt% — 销售金额占比

| 项目 | 内容 |
|---|---|
| **指标名称** | SLS Amt% / 销售金额占比 |
| **业务定义** | 以 Product Type 为基数，看所选商品维度在该 Product Type 的占比 |
| **计算公式** | 时间范围看 this period；分子：该 product_type 下各 label / category / super_season / md_type / division `sum(net_sales_amt)`；分母：该 product_type 下 `sum(net_sales_amt)` |
| **数据底表** | `a02_e2e_product_performance_sales_summary_d` |
| **注意** | 原始口径计算指标列分子分母为 `sum(net_sales_qty)`（数量字段），已确认修正为金额字段 |
| **数据类型** | percent_0dp → 百分比整数，不含正号 |
| **数据格式** | `#,##0%` |
| **附属指标类型** | SLS Amt:currency |

---

### 16. EOH Amt% — 期末库存金额占比

| 项目 | 内容 |
|---|---|
| **指标名称** | EOH Amt% / 期末库存金额占比 |
| **业务定义** | 以 Product Type 为基数，看所选商品维度在该 Product Type 的占比 |
| **计算公式** | 看所选时间范围 end period 最后一天；分子：该 product_type 下各 label / category / super_season / md_type / division `sum(msrp_inv_amt)`；分母：该 product_type 下 `sum(msrp_inv_amt)` |
| **数据底表** | `a02_e2e_product_performance_inv_summary_d` |
| **注意** | 原始口径计算指标列分子分母为 `sum(inv_qty)`（数量字段），已确认修正为金额字段 `msrp_inv_amt` |
| **数据类型** | percent_0dp → 百分比整数，不含正号 |
| **数据格式** | `#,##0%` |
| **附属指标类型** | EOH Amt:currency |

---

## 子模块五：Product Type Sales & Inventory Structure【Category × Division/Label】

> **商品维度切换**: Label：`label` / Division：`division`
> **视图说明**: 横坐标及表格行固定聚合在 Category 粒度（`category`），统计各 Category 占对应 Division/Label 的比例
> **附属指标说明**: vs LP：this period - last period（差值，bp 指标，展示时×10000 转 bp）；vs LY：this year - last year（差值，bp 指标，展示时×10000 转 bp）；其中this period、last period分别指两个日期切片器的筛选值;this year、last year中this year对应data_date ∈ [Slicer_Time_Frame_Min_This[TimeFrame_Min], Slicer_Time_Frame_Max_This[TimeFrame_Max]],last year对应data_date ∈ [Slicer_Time_Frame_Min_This[TimeFrame_Min_LY], Slicer_Time_Frame_Max_This[TimeFrame_Max_LY]];

### 17. SLS Amt% — 销售金额占比

| 项目 | 内容 |
|---|---|
| **指标名称** | SLS Amt% / 销售金额占比 |
| **业务定义** | 横坐标及表格行固定聚合在 Category 粒度，统计各 Category 占所有 Category的比例 |
| **计算公式** | 时间范围看 this period；分子：各 category 下 `sum(net_sales_amt)`；分母：ALL `sum(net_sales_amt)` |
| **数据底表** | `a02_e2e_product_performance_sales_summary_d` |
| **附属指标** | vs LP：this period - last period（差值，bp 指标，展示时 ×10000 转 bp）；vs LY：今年 - 去年（差值，bp 指标，展示时 ×10000 转 bp） |
| **注意** | 分母原始公式仅写 `sum(net_sales_amt)`，按业务定义"占对应 Division/Label 的比例"理解为对应 Division/Label 分组内合计；vs LY 的「今年/去年」时间范围见待确认项汇总 |
| **数据类型** | percent_0dp → 百分比整数，不含正号 |
| **数据格式** | `#,##0%` |
| **附属指标类型** | vs LP:delta_bp、vs LY:delta_bp |

---

### 18. EOH Amt% — 期末库存金额占比

| 项目 | 内容 |
|---|---|
| **指标名称** | EOH Amt% / 期末库存金额占比 |
| **业务定义** | 横坐标及表格行固定聚合在 Category 粒度，统计各 Category 占所有 Category的比例|
| **计算公式** | 看所选时间范围 end period 最后一天；分子：各 category 下 `sum(msrp_inv_amt)`；分母：ALL `sum(msrp_inv_amt)` |
| **数据底表** | `a02_e2e_product_performance_inv_summary_d` |
| **附属指标** | vs LP：this period - last period（差值，bp 指标，展示时 ×10000 转 bp）；vs LY：今年 - 去年（差值，bp 指标，展示时 ×10000 转 bp） |
| **注意** | 计算指标列及全局规范 ×10000 转 bp；为 EOH Amt% vs LP |
| **数据类型** | percent_0dp → 百分比整数，不含正号 |
| **数据格式** | `#,##0%` |
| **附属指标类型** | vs LP:delta_bp、vs LY:delta_bp |

---

## 子模块六：MD Sales Structure

> **商品维度**: Division（`division`，原始口径未标注取值清单与切换方式）
> **行维度**: MD type：`md_type`

### 19. SLS Amt% — 销售金额占比

| 项目 | 内容 |
|---|---|
| **指标名称** | SLS Amt% / 销售金额占比 |
| **业务定义** | 各 MD type 销售金额占 total 销售金额的比例 |
| **计算公式** | 时间范围看 this period；分子：各 md_type 下 `sum(net_sales_amt)`；分母：`sum(net_sales_amt)` |
| **数据底表** | `a02_e2e_product_performance_sales_summary_d` |
| **附属指标** | SLS Amt% vs LP：this period - last period（差值，bp 指标，展示时 ×10000 转 bp） |
| **注意** | 原始口径 Definition 与计算指标列均写"今年 - 去年"，已确认以指标名为准修正为 this period - last period（公式列为笔误） |
| **数据类型** | percent_0dp → 百分比整数，不含正号 |
| **数据格式** | `#,##0%` |
| **附属指标类型** | SLS Amt：currency、SLS Amt% vs LP:integer_bp |

---

### 20. MSRP Amt% — 货值占比

| 项目 | 内容 |
|---|---|
| **指标名称** | MSRP Amt% / 货值占比 |
| **业务定义** | 各 MD type 货值占 total 货值的比例 |
| **计算公式** | 时间范围看 this period；分子：各 md_type 下 `sum(msrp_net_sales_amt)`；分母：`sum(msrp_net_sales_amt)` |
| **数据底表** | `a02_e2e_product_performance_sales_summary_d` |
| **附属指标** | MSRP Amt% vs LP：this period - last period（差值，bp 指标，展示时 ×10000 转 bp） |
| **注意** | 原始口径 Definition 与计算指标列均写"今年 - 去年"，已确认以指标名为准修正为 this period - last period（公式列为笔误） |
| **数据类型** | percent_0dp → 百分比整数，不含正号 |
| **数据格式** | `#,##0%` |
| **附属指标类型** | MSRP Amt：currency、MSRP Amt% vs LP:integer_bp |

---

## 子模块七：Item Stockout & Slow Mover Alert

> **商品维度切换**: Item：`spu_id` / SKU：`sku_id`（仅取 Top 10，排序依据SLS Amt排序，降序取最大的十条。所有需要给出排序度量Dax，排名：RANK 窗口函数（金额降序 + Item：`spu_id` / SKU：`sku_id` 字母序决胜，唯一名次），所以要有两个排序度量）
> **属性列**: US（`us_style`）、Class（`ax_class`）、Type（`product_type`）、Series（`special_series`）、Image（`spu_img_url`，商品图片）、Product tag（`computed_product_tag`）、Special Supply（`special_supply`）；其中 Product tag / Special Supply 底表为 `s02_inventory_stock_sales_detail_d`

### 21. SLS Amt — DCom净销售额

| 项目 | 内容 |
|---|---|
| **指标名称** | SLS Amt / DCom净销售额 |
| **业务定义** | 统计周期内DCom净销售额 = DCom销售订单总销售额 - 退货额 |
| **计算公式** | 时间范围看 this period；该 spu_id/sku_id 下 `sum(net_sales_amt)` |
| **数据底表** | `s02_trade_sku_data_d` |
| **数据类型** | currency → 货币符号由币种切片器决定，千分位整数 |
| **数据格式** | `#,##0`（在 DAX 中用 `__CurrencySymbol & FORMAT(__Value, "#,##0")` 拼接币种符号） |

---

### 22. SLS Units — DCom净销售数量

| 项目 | 内容 |
|---|---|
| **指标名称** | SLS Units / DCom净销售数量 |
| **业务定义** | 统计周期内该 spu_id/sku_id 下销售数量之和 |
| **计算公式** | 时间范围看 this period；该 spu_id/sku_id 下 `sum(product_qty)` |
| **数据底表** | `s02_trade_sku_data_d` |
| **数据类型** | integer → 整数，千分位整数 |
| **数据格式** | `#,##0` |

---

### 23. EOH — 期末库存数量

| 项目 | 内容 |
|---|---|
| **指标名称** | EOH / 期末库存数量 |
| **业务定义** | 选定日期业务周期结束时点的期末库存总数量 |
| **计算公式** | 时间范围看 this period 最后一天；该 spu_id/sku_id 下 `sum(stock_inv_qty)` |
| **数据底表** | `s02_inventory_stock_sales_detail_d` |
| **数据类型** | integer → 整数，千分位整数 |
| **数据格式** | `#,##0` |

---

### 24. In-transit Inventory — 在途库存数量

| 项目 | 内容 |
|---|---|
| **指标名称** | In-transit Inventory / 在途库存数量（原始口径 Name_EN 拼写为 In-transit Invontory） |
| **业务定义** | 已出库尚未入库到仓的货品总件数 |
| **计算公式** | 看所选时间范围 end period 最后一天；该 spu_id/sku_id 下 `sum(in_trans_inv_qty)` |
| **数据底表** | `s02_inventory_stock_sales_detail_d` |
| **数据类型** | integer → 整数，千分位整数 |
| **数据格式** | `#,##0` |

---

### 25. Weeks Cover — 库存周转周数

| 项目 | 内容 |
|---|---|
| **指标名称** | Weeks Cover / 库存周转周数 |
| **业务定义** | 统计周期内的（期末库存数量 + 在途库存数量）/ 销售数量 |
| **计算公式** | 销售数量：看所选时间范围销售数量之和（this period 区间）；库存相关：看所选时间范围 end period 最后一天；分子：`sum(stock_inv_qty) + sum(in_trans_inv_qty)`；分母：`sum(product_qty)`（该 spu_id/sku_id 下） |
| **数据底表** | `s02_trade_sku_data_d`（sales）；`s02_inventory_stock_sales_detail_d`（inv） |
| **注意** | 原始口径计算指标列分子分母写反（分子 `sum(product_qty)`、分母库存+在途），已确认以业务定义为准修正 |
| **数据类型** | decimal_1dp → 1 位小数，千分位 |
| **数据格式** | `#,##0.0`（原始口径未定义格式，按周数语义取 1 位小数） |

---

### 26. MTD SLS Unit — 月至今DCom净销售数量

| 项目 | 内容 |
|---|---|
| **指标名称** | MTD SLS Unit / 月至今DCom净销售数量 |
| **业务定义** | 所选时间范围 end period 所在财月第一天至 end period 最后一天的净销售数量 |
| **计算公式** | 时间范围看 this period 的 end period 所在财月第一天至 end period 最后一天；该 spu_id/sku_id 下 `sum(product_qty)` |
| **数据底表** | `s02_trade_sku_data_d` |
| **注意** | 原始口径计算指标列写"时间范围看this period"，按 Definition 的 MTD 区间理解（见待确认项汇总） |
| **数据类型** | integer → 整数，千分位整数 |
| **数据格式** | `#,##0` |

---

### 27. YTD SLS Unit — 年至今DCom净销售数量

| 项目 | 内容 |
|---|---|
| **指标名称** | YTD SLS Unit / 年至今DCom净销售数量 |
| **业务定义** | 所选时间范围 end period 所在财年第一天至 end period 最后一天的净销售数量 |
| **计算公式** | 时间范围看 this period 的 end period 所在财年第一天至 end period 最后一天；该 spu_id/sku_id 下 `sum(product_qty)` |
| **数据底表** | `s02_trade_sku_data_d` |
| **注意** | 大于等于，财年第一天，日期表有对应字段：Slicer_Time_Frame_Max_This[Fiscal_Year_First_Day] ；小于等于end period最后一天，Slicer_Time_Frame_Max_This[TimeFrame_Max]|
| **数据类型** | integer → 整数，千分位整数 |
| **数据格式** | `#,##0` |

---

### 28. ST% — 售罄率%

| 项目 | 内容 |
|---|---|
| **指标名称** | ST% / 售罄率% |
| **业务定义** | 统计周期内销售数量 /（销售数量 + 期末库存数量）× 100% |
| **计算公式** | 销售数量：看所选时间范围销售数量之和（this period 区间）；期末库存数量：看所选时间范围 end period 最后一天；该 spu_id/sku_id 下 `sales.sum(product_qty) / (sales.sum(product_qty) + inv.sum(stock_inv_qty))` |
| **数据底表** | `s02_trade_sku_data_d`（sales）；`s02_inventory_stock_sales_detail_d`（inv） |
| **注意** | 原始口径公式为金额口径 `sales.sum(net_sales_amt)/(sales.sum(net_sales_amt)+inv.sum(msrp_inv_amt))`，已确认修正为数量口径；原始描述中"销售金额/期末库存金额"字样以公式为准（数量口径） |
| **数据类型** | percent_0dp → 百分比整数，不含正号 |
| **数据格式** | `#,##0%` |

---

### 29. AUR — 件单价

| 项目 | 内容 |
|---|---|
| **指标名称** | AUR / 件单价 |
| **业务定义** | 净销售金额 / 商品净出库件数 |
| **计算公式** | 时间范围看 this period；该 spu_id/sku_id 下 `sum(net_sales_amt) / sum(product_qty)` |
| **数据底表** | `s02_trade_sku_data_d` |
| **数据类型** | currency → 货币符号由币种切片器决定，千分位整数 |
| **数据格式** | `#,##0`（在 DAX 中用 `__CurrencySymbol & FORMAT(__Value, "#,##0")` 拼接币种符号） |

---

### 30. MD — 平均折扣

| 项目 | 内容 |
|---|---|
| **指标名称** | MD / 平均折扣 |
| **业务定义** | 1 - 折扣价 / 原价 × 100% |
| **计算公式** | 时间范围看 this period；该 spu_id/sku_id 下 `1 - sum(product_qty*md_price) / sum(product_qty*msrp)` |
| **数据底表** | `s02_trade_sku_data_d` |
| **数据类型** | percent_0dp → 百分比整数，不含正号 |
| **数据格式** | `#,##0%` |

---

### 31. Alert — 判断规则

| 项目 | 内容 |
|---|---|
| **指标名称** | Alert / 判断规则 |
| **业务定义** | 缺货 oos → 感叹号；slow mover → 下降符号 |
| **计算公式** | `oos_tag = ？` → 感叹号；`computed_product_tag = "slow mover"` → 下降符号 |
| **数据底表** | `s02_inventory_stock_sales_detail_d` |
| **注意** | 原始口径"oos_tag =  -> 感叹号"中判定值为空，待业务确认（见待确认项汇总） |
| **数据类型** | 文本/图标（感叹号 / 下降符号），无数值格式 |
| **数据格式** | 无 |

---

### 32. Available sizes — 在库尺码

| 项目 | 内容 |
|---|---|
| **指标名称** | Available sizes / 在库尺码 |
| **业务定义** | 期末在库库存的尺码枚举值 |
| **计算公式** | 看所选时间范围 end period 最后一天；该 spu_id/sku_id 下 distinct `sku_size` where `inv_qty > 0` |
| **数据底表** | `s02_inventory_stock_sales_detail_d` |
| **注意** | 原始口径字段名 `inv_qty` 与同模块 EOH 字段（`stock_inv_qty`）不一致，DAX 实现时需对照数据字典确认 |
| **数据类型** | 文本枚举，无数值格式 |
| **数据格式** | 无 |

---

### 33. Replenishment Count — 补货数量

| 项目 | 内容 |
|---|---|
| **指标名称** | Replenishment Count / 补货数量 |
| **业务定义** | 近4周的销售数量平均值 * 5/3/1 -（期末库存数量 + 在途库存数量） |
| **计算公式** | 看所选时间范围 end period 最后一天；该 spu_id/sku_id 下 `sum(reph_qty)` |
| **数据底表** | `s02_inventory_stock_sales_detail_d` |
| **注意** | 计算指标列直接取 `reph_qty` 字段（以字段为准，Definition 公式由数仓预计算实现）；"5/3/1"倍数含义待业务确认（见待确认项汇总） |
| **数据类型** | integer → 整数，千分位整数 |
| **数据格式** | `#,##0` |

---

## 子模块八：Platform Merchandising Performance

> **渠道维度切换**: Platform：`platform` / Store：`shop_name`
> **TAR 类指标（待确认，本子模块两处同口径）**: TAR ACH%：所选时间范围 actual / 所选时间范围 target（date to date，实际值和目标值日期范围一致）；MTD TAR Progress：所选时间范围 actual / 所选时间范围所在财月汇总 target；YTD TAR Progress：所选时间范围 actual / 所选时间范围所在财年汇总 target；原始口径标注「详情见待确认交互细节」，计算逻辑待业务确认；数据底表：`a02_e2e_product_performance_sales_summary_d`（actual）+ `a05_e2e_product_fcst_data_d`（target）

### 34. Foundation — Foundation销售金额占比

| 项目 | 内容 |
|---|---|
| **指标名称** | Foundation / Foundation销售金额占比 |
| **业务定义** | framework = 'Foundation' 的销售金额占 total 的比例 |
| **计算公式** | 时间范围看 this period；分子：framework = 'Foundation' 下 `sum(net_sales_amt)`；分母：`sum(net_sales_amt)` |
| **数据底表** | `a02_e2e_product_performance_sales_summary_d`（该行 Data_Source 同时列出 `a05_e2e_product_fcst_data_d`，为 TAR 类指标所需） |
| **附属指标** | vs LP：this period - last period（差值，bp 指标，展示时 ×10000 转 bp；Foundation/Acceleration/Complementary 三个占比共用） |
| **数据类型** | percent_0dp → 百分比整数，不含正号 |
| **数据格式** | `#,##0%` |
| **附属指标类型** | vs LP:delta_bp |

---

### 35. Acceleration — Acceleration销售金额占比

| 项目 | 内容 |
|---|---|
| **指标名称** | Acceleration / Acceleration销售金额占比 |
| **业务定义** | framework = 'Acceleration' 的销售金额占 total 的比例 |
| **计算公式** | 时间范围看 this period；分子：framework = 'Acceleration' 下 `sum(net_sales_amt)`；分母：`sum(net_sales_amt)` |
| **数据底表** | `a02_e2e_product_performance_sales_summary_d`（含 TAR 所需 `a05_e2e_product_fcst_data_d`） |
| **附属指标** | vs LP：this period - last period（差值，bp 指标，展示时 ×10000 转 bp） |
| **数据类型** | percent_0dp → 百分比整数，不含正号 |
| **数据格式** | `#,##0%` |
| **附属指标类型** | vs LP:delta_bp |

---

### 36. Complementary — Complementary销售金额占比

| 项目 | 内容 |
|---|---|
| **指标名称** | Complementary / Complementary销售金额占比 |
| **业务定义** | framework = 'Complementary' 的销售金额占 total 的比例 |
| **计算公式** | 时间范围看 this period；分子：framework = 'Complementary' 下 `sum(net_sales_amt)`；分母：`sum(net_sales_amt)` |
| **数据底表** | `a02_e2e_product_performance_sales_summary_d`（含 TAR 所需 `a05_e2e_product_fcst_data_d`） |
| **附属指标** | vs LP：this period - last period（差值，bp 指标，展示时 ×10000 转 bp） |
| **数据类型** | percent_0dp → 百分比整数，不含正号 |
| **数据格式** | `#,##0%` |
| **附属指标类型** | vs LP:delta_bp |

---

### 37. SLS Amt% — 销售金额占比（Category 部分）

| 项目 | 内容 |
|---|---|
| **指标名称** | SLS Amt% / 销售金额占比 |
| **业务定义** | Framework + Category 粒度下各平台 SLS Amt% |
| **计算公式** | 时间范围看 this period；分子：该 category 下 `sum(net_sales_amt)`；分母：`sum(net_sales_amt)` |
| **数据底表** | `a02_e2e_product_performance_sales_summary_d` |
| **附属指标** | vs LP：this period - last period（差值，bp 指标，展示时 ×10000 转 bp） |
| **注意** | 占比分母范围原始口径未明确（该 Category 下全渠道合计 / 该渠道下合计 / 全局合计），DAX 实现时需与业务确认（见待确认项汇总） |
| **数据类型** | percent_0dp → 百分比整数，不含正号 |
| **数据格式** | `#,##0%` |
| **附属指标类型** | vs LP:delta_bp |

---

### 38. EOH — 期末库存金额

| 项目 | 内容 |
|---|---|
| **指标名称** | EOH / 期末库存金额 |
| **业务定义** | EOH Units × msrp |
| **计算公式** | 看所选时间范围 end period 最后一天；`sum(msrp_inv_amt)` |
| **数据底表** | `a02_e2e_product_performance_inv_summary_d` |
| **数据类型** | currency → 货币符号由币种切片器决定，千分位整数 |
| **数据格式** | `#,##0`（在 DAX 中用 `__CurrencySymbol & FORMAT(__Value, "#,##0")` 拼接币种符号） |

---

### 39. ST% — 售罄率%（金额）

| 项目 | 内容 |
|---|---|
| **指标名称** | ST% / 售罄率%（金额） |
| **业务定义** | 统计周期内销售金额 /（销售金额 + 期末库存金额）× 100% |
| **计算公式** | 销售金额：看所选时间范围销售金额之和；期末库存金额：看所选时间范围 end period 最后一天；`sales.net_sales_amt / (sales.net_sales_amt + inv.msrp_inv_amt)` |
| **数据底表** | `a02_e2e_product_performance_sales_summary_d`（sales）；`a02_e2e_product_performance_inv_summary_d`（inv） |
| **数据类型** | percent_0dp → 百分比整数，不含正号 |
| **数据格式** | `#,##0%` |

---

## 子模块九：Top & OPP SKUs Analysis

> **商品维度切换**: TOP：在相应（原文不完整，见待确认项汇总）下，按照 SLS Amt 降序排序，取 top 3 sku；OPP：上架时间（launch_time）> 2周，售罄率（ST%）< 均值，EOH Units > 同 Label & CLASS 下 sku 的均值，Weeks Cover > 均值，按照库存降序排序，取 top 3 sku
> **未在前端展示但参与 OPP 判断的计算**: launch_time（`launch_time`，上架时间，该行底表未标注、按模块上下文 s02 双表理解）；ST%（售罄率%（金额）：销售金额看 this period 区间、期末库存金额看 end period 最后一天，`sales.net_sales_amt/(sales.net_sales_amt+inv.msrp_inv_amt)`）
> **属性列**: Product Photo（`spu_img_url`，商品图片）、Product Type（`product_type`，该 TOP/OPP 商品对应的 product type）、Price（`md_price`，如果是折扣价则展示折扣价，如果是吊牌价则展示吊牌价）、Predictive Buy（`predictive_buy`，该 TOP/OPP 商品对应的 Predictive Buy 标签）

### 40. Weeks Cover — 库存周转周数

| 项目 | 内容 |
|---|---|
| **指标名称** | Weeks Cover / 该TOP/OPP商品对应的库存周转周数 |
| **业务定义** | 统计周期内的（期末库存数量 + 在途库存数量）/ 销售数量 |
| **计算公式** | 销售数量：看所选时间范围销售数量之和（this period 区间）；库存相关：看所选时间范围 end period 最后一天；分子：`sum(stock_inv_qty) + sum(in_trans_inv_qty)`；分母：`sum(product_qty)`（该 TOP/OPP 商品 sku_id 下） |
| **数据底表** | `s02_trade_sku_data_d`（sales）；`s02_inventory_stock_sales_detail_d`（inv） |
| **注意** | 原始口径计算指标列分子分母写反，已确认以业务定义为准修正（同子模块七 Weeks Cover） |
| **数据类型** | decimal_1dp → 1 位小数，千分位 |
| **数据格式** | `#,##0.0`（原始口径未定义格式，按周数语义取 1 位小数） |

---

### 41. SLS Units — DCom净销售数量

| 项目 | 内容 |
|---|---|
| **指标名称** | SLS Units / DCom净销售数量 |
| **业务定义** | 统计周期内该 sku_id 下销售数量之和 |
| **计算公式** | 时间范围看 this period；该 sku_id 下 `sum(product_qty)` |
| **数据底表** | `s02_trade_sku_data_d` |
| **数据类型** | integer → 整数，千分位整数 |
| **数据格式** | `#,##0` |

---

### 42. EOH — 期末库存数量

| 项目 | 内容 |
|---|---|
| **指标名称** | EOH / 该TOP/OPP商品对应的期末库存数量 |
| **业务定义** | 选定日期业务周期结束时点的期末库存总数量 |
| **计算公式** | 时间范围看 this period 最后一天；该 sku_id 下 `sum(stock_inv_qty)` |
| **数据底表** | `s02_inventory_stock_sales_detail_d` |
| **数据类型** | integer → 整数，千分位整数 |
| **数据格式** | `#,##0` |

---

## 子模块十：Handbags Sales Performance

> **前置筛选**: 整个模块需要先筛选 category = 'Handbags'/'Outwear'（'Outwear' 疑似 'Outerwear'，以底表实际取值为准）
> **行维度**: Model：`spu_model`

### 43. SLS Unit — DCom净销售数量

| 项目 | 内容 |
|---|---|
| **指标名称** | SLS Unit / DCom净销售数量 |
| **业务定义** | 统计周期内该 spu_model 下销售数量之和 |
| **计算公式** | 时间范围看 this period；该 spu_model 下 `sum(product_qty)` |
| **数据底表** | `s02_trade_sku_data_d` |
| **数据类型** | integer → 整数，千分位整数 |
| **数据格式** | `#,##0` |

---

### 44. SLS Amt — DCom净销售额

| 项目 | 内容 |
|---|---|
| **指标名称** | SLS Amt / DCom净销售额 |
| **业务定义** | 统计周期内DCom净销售额 = DCom销售订单总销售额 - 退货额 |
| **计算公式** | 时间范围看 this period；该 spu_model 下 `sum(net_sales_amt)` |
| **数据底表** | `s02_trade_sku_data_d` |
| **附属指标** | Amt vs LP：this period / last period - 1 |
| **数据类型** | currency → 货币符号由币种切片器决定，千分位整数 |
| **数据格式** | `#,##0`（在 DAX 中用 `__CurrencySymbol & FORMAT(__Value, "#,##0")` 拼接币种符号） |
| **附属指标类型** | Amt vs LP:percent_0dp → 百分比整数，不含正号 |

---

### 45. SLS Amt% — 销售金额占比

| 项目 | 内容 |
|---|---|
| **指标名称** | SLS Amt% / 销售金额占比 |
| **业务定义** | 该 model 占 total 的比例 |
| **计算公式** | 时间范围看 this period；分子：该 spu_model 下 `sum(net_sales_amt)`；分母：`sum(net_sales_amt)`（Handbags/Outwear 筛选范围内） |
| **数据底表** | `s02_trade_sku_data_d` |
| **附属指标** | vs LP：this period - last period（差值，bp 指标，展示时 ×10000 转 bp） |
| **数据类型** | percent_0dp → 百分比整数，不含正号 |
| **数据格式** | `#,##0%` |
| **附属指标类型** | vs LP:integer_bp |

---

### 46. ST% — 售罄率%（金额）

| 项目 | 内容 |
|---|---|
| **指标名称** | ST% / 售罄率%（金额） |
| **业务定义** | 统计周期内销售金额 /（销售金额 + 期末库存金额）× 100% |
| **计算公式** | 销售金额：看所选时间范围销售金额之和；期末库存金额：看所选时间范围 end period 最后一天；该 spu_model 下 `sales.sum(net_sales_amt) / (sales.sum(net_sales_amt) + inv.sum(msrp_inv_amt))` |
| **数据底表** | `s02_trade_sku_data_d`（sales）；`s02_inventory_stock_sales_detail_d`（inv） |
| **数据类型** | percent_0dp → 百分比整数，不含正号 |
| **数据格式** | `#,##0%` |

---

### 47. EOH — 期末库存数量

| 项目 | 内容 |
|---|---|
| **指标名称** | EOH / 期末库存数量 |
| **业务定义** | 选定日期业务周期结束时点的期末库存总数量 |
| **计算公式** | 时间范围看 this period 最后一天；该 spu_model 下 `sum(stock_inv_qty)` |
| **数据底表** | `s02_inventory_stock_sales_detail_d` |
| **附属指标** | EOH vs LP：this period / last period - 1 |
| **数据类型** | integer → 整数，千分位整数 |
| **数据格式** | `#,##0` |
| **附属指标类型** | EOH vs LP:percent_0dp → 百分比整数，不含正号 |

---

## 子模块十一：Handbags Sales Analysis by Dimension

> **前置筛选**: 整个模块需要先筛选 category = 'Handbags'，这个我在页面视觉对象筛选就行，来源表为Slicer_Category
> **渠道维度**: TTL/TMALL/JD/RLE/DY/DY_W/DY_MN（固定渠道值；指标计算受所选渠道筛选影响，TTL 为全部渠道口径；取值映射参照 Button_Store_Name）
> **商品维度组合（用户选择）**: Model：`spu_model` / Subclass：`ax_sub_class` / Season：`season` / Category：`category` / Size：`sku_size`

### 48. SLS Amt — DCom净销售额

| 项目 | 内容 |
|---|---|
| **指标名称** | SLS Amt / DCom净销售额 |
| **业务定义** | 统计周期内DCom净销售额 = DCom销售订单总销售额 - 退货额 |
| **计算公式** | 时间范围看 this period；该 dimension（商品维度组合）下 `sum(net_sales_amt)` |
| **数据底表** | `s02_trade_sku_data_d` |
| **数据类型** | currency → 货币符号由币种切片器决定，千分位整数 |
| **数据格式** | `#,##0`（在 DAX 中用 `__CurrencySymbol & FORMAT(__Value, "#,##0")` 拼接币种符号） |

---

### 49. SLS Amt% — 销售金额占比

| 项目 | 内容 |
|---|---|
| **指标名称** | SLS Amt% / 销售金额占比 |
| **业务定义** | 该 dimension 占 Handbags total 的比例 |
| **计算公式** | 时间范围看 this period；分子：该 dimension 下 `sum(net_sales_amt)`；分母：`sum(net_sales_amt)`（Handbags 筛选范围内） |
| **数据底表** | `s02_trade_sku_data_d` |
| **附属指标** | vs LP：this period - last period（差值，bp 指标，展示时 ×10000 转 bp），这里我用于表格，在Display中×10000 |
| **数据类型** | percent_0dp → 百分比整数，不含正号 |
| **数据格式** | `#,##0%` |
| **附属指标类型** | vs LP:integer_bp |

---

### 50. SLS Unit — DCom净销售数量

| 项目 | 内容 |
|---|---|
| **指标名称** | SLS Unit / DCom净销售数量 |
| **业务定义** | 统计周期内该 dimension 下销售数量之和 |
| **计算公式** | 时间范围看 this period；该 dimension 下 `sum(product_qty)` |
| **数据底表** | `s02_trade_sku_data_d` |
| **数据类型** | integer → 整数，千分位整数 |
| **数据格式** | `#,##0` |

---

### 51. EOH Unit — 期末库存数量

| 项目 | 内容 |
|---|---|
| **指标名称** | EOH Unit / 期末库存数量 |
| **业务定义** | 选定日期业务周期结束时点的期末库存总数量 |
| **计算公式** | 时间范围看 this period 最后一天；该 dimension 下 `sum(stock_inv_qty)` |
| **数据底表** | `s02_inventory_stock_sales_detail_d` |
| **附属指标** | vs LP：this period / last period - 1 |
| **数据类型** | integer → 整数，千分位整数 |
| **数据格式** | `#,##0` |
| **附属指标类型** | vs LP:percent_0dp → 百分比整数，不含正号 |

---

### 52. ST% — 售罄率%（金额）

| 项目 | 内容 |
|---|---|
| **指标名称** | ST% / 售罄率%（金额） |
| **业务定义** | 统计周期内销售金额 /（销售金额 + 期末库存金额）× 100% |
| **计算公式** | 销售金额：看所选时间范围销售金额之和；期末库存金额：看所选时间范围 end period 最后一天；该 dimension 下 `sales.sum(net_sales_amt) / (sales.sum(net_sales_amt) + inv.sum(msrp_inv_amt))` |
| **数据底表** | `s02_trade_sku_data_d`（sales）；`s02_inventory_stock_sales_detail_d`（inv） |
| **数据类型** | percent_0dp → 百分比整数，不含正号 |
| **数据格式** | `#,##0%` |

---

## 待确认项汇总（原始口径遗留）

| # | 待确认项 | 位置 | 说明 |
|---|---|---|---|
| 1 | Item/SKU Top 100 排序依据 | 子模块七 | 原始口径仅写"仅取Top 100"，未标注按什么指标排序取前 100 |
| 2 | Alert 的 oos_tag 判定值 | 子模块七 | 原始口径"oos_tag =  -> 感叹号"中判定值为空 |
| 3 | Platform Merchandising Category SLS Amt% 分母范围 | 子模块八 | 分子分母仅写 `sum(net_sales_amt)`，"各平台SLS Amt%"的分母范围（该 Category 下全渠道合计 / 该渠道下合计 / 全局合计）未明确 |
| 4 | TAR ACH% / MTD TAR Progress / YTD TAR Progress 计算逻辑 | 子模块八 | 原始口径标注"详情见待确认交互细节"，仅给出 actual/target 框架 |
| 5 | TOP 的"在相应下"分组范围 | 子模块九 | 原始口径"在相应下，按照SLS Amt降序排序"文字不完整，未写明在相应什么维度下取 top 3 |
| 6 | Replenishment Count 的 5/3/1 含义 | 子模块七 | Definition"近4周的销售数量平均值 * 5/3/1 -(期末库存数量+在途库存数量)"中 5/3/1 倍数含义未说明；计算指标列直接取 `sum(reph_qty)` 字段（以字段为准） |
| 7 | Available sizes 的库存字段名 | 子模块七 | 原始口径写"distinct sku_size where inv_qty > 0"，字段名 `inv_qty` 与同模块 EOH 字段（`stock_inv_qty`）不一致 |
| 8 | vs LY「今年/去年」时间范围 | 子模块五 | "今年 - 去年"未细化，按"今年同期占比 - 上个财年同期占比"固定对比理解（不受 last period 时间筛选器影响） |
| 9 | 'Outwear' 拼写 | 子模块十 | 疑似 'Outerwear'，以底表实际取值为准 |
| 10 | launch_time 底表归属 | 子模块九 | 该行未标注 Data_Source，按模块上下文（s02 双表）理解，需对照数据字典确认 |
| 11 | MTD/YTD SLS Unit 时间范围 | 子模块七 | 计算指标列写"时间范围看this period"，按 Definition 的 MTD/YTD 区间（end period 所在财月/财年第一天至 end period 最后一天）理解 |
| 12 | Handbags by Dimension 渠道映射 | 子模块十一 | TTL/TMALL/JD/RLE/DY/DY_W/DY_MN 与事实表渠道字段取值映射，参照 Slicer_Platform_Selection / Slicer_Store_Name 确认 |

---

## 通用规则汇总

| 规则项 | 说明 |
|---|---|
| **数据底表** | 汇总类板块（Label / Product Type / Category×Division/Label / MD Sales Structure / Platform Merchandising）用 `a02_e2e_product_performance_sales_summary_d` + `a02_e2e_product_performance_inv_summary_d`；明细类板块（Item 预警 / Top & OPP / Handbags 两个）用 `s02_trade_sku_data_d` + `s02_inventory_stock_sales_detail_d`；ST% / Weeks Cover 跨双表；TAR 类指标另需 `a05_e2e_product_fcst_data_d` |
| **板块级维度切换** | 各板块商品维度切换见「全局逻辑」及各子模块说明；渠道维度切换仅 Platform Merchandising（platform/shop_name）与 Handbags by Dimension（固定渠道值） |
| **数量/金额口径判定** | 以 Name_EN 为准：Unit = 数量，Amt = 金额；Name_EN 无 Unit/Amt 后缀的 ST% 类指标为数量口径（本次确认）；计算字段以原始口径计算指标列为准，冲突处按修正记录处理 |
| **时间口径** | 区间类：this period 汇总；期末时点类（EOH / In-transit / ST% 库存分母 / Available sizes / Replenishment）：end period 最后一天；MTD：end period 所在财月第一天至 end period 最后一天；YTD：end period 所在财年第一天至 end period 最后一天 |
| **vs LP 规则** | 占比类主指标：this period - last period（差值，bp 指标，展示时 ×10000 转 bp）；数值类主指标（SLS Amt / EOH 等）：this period / last period - 1 |
| **vs LY 规则** | 今年 - 去年（差值，bp 指标，展示时 ×10000 转 bp）；「今年/去年」时间范围按上个财年同期固定对比理解（待确认项 #8） |
| **Weeks Cover 方向** | （期末库存数量 + 在途库存数量）/ 销售数量（原始公式列分子分母写反，已确认以业务定义为准） |
| **口径笔误修正记录（已与业务确认）** | ① YTD ST%（Label / Product Type 板块）与 Item 板块 ST%：公式修正为数量口径（a02 表 `sales.net_sales_qty/(sales.net_sales_qty+inv.inv_qty)`；s02 表 `sales.sum(product_qty)/(sales.sum(product_qty)+inv.sum(stock_inv_qty))`）；② Label / Product Type 交叉视图 SLS Amt% / EOH Amt%：分子分母修正为金额字段（`net_sales_amt` / `msrp_inv_amt`）；③ MD Sales Structure 的 SLS Amt% vs LP / MSRP Amt% vs LP：以指标名为准，修正为 this period - last period（原始公式列"今年 - 去年"为笔误）；④ Weeks Cover：以业务定义为准，（库存+在途）/ 销售数量（原始公式列分子分母写反）；⑤ 子模块五 EOH Amt% vs LP 的 Definition"×100 转 bp"为笔误，按 ×10000 转 bp |
| **必须遵守** | 口径文档中定义的所有指标，必须遵守其数据类型和数据格式，如果和解决方案中存在争议的，一切以口径文档为准，必须按照口径文档中的格式进行调整 |
| **DAX 语法规范** | 文本常量必须使用双引号 `" "`，禁止使用单引号；单引号 `' '` 仅用于表名，列名使用方括号 `[ ]`，例如：`[md_type] = "FP"` |
