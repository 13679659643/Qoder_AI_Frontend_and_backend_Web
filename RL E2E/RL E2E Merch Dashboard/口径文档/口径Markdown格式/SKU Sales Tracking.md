# SKU Sales Tracking 指标口径提示词

> **Dashboard**: RL E2E Merch Dashboard  
> **Tab**: SKU Sales Tracking  
> **数据底表（销售类）**: `s02_trade_sku_data_d`  
> **数据底表（库存类）**: `s02_inventory_stock_sales_detail_d`  
> **模块说明**: 本板块为 SKU 销售追踪看板，覆盖 Top Size Sales Performance（Sales / Inventory）、Top Color Sales Performance（Sales / Inventory）、Emerging Style Identification（Sales / Inventory）、Series Sales Performance 子板块，统计尺码、颜色、颜色×尺码、系列（AXC）层级下的销售、库存、占比、AUR、MD 及 YTD / LTD 售罄率等指标。

---

## 全局逻辑

| 项目 | 内容 |
|---|---|
| **数据底表（销售类）** | `s02_trade_sku_data_d`：SLS、AUR、MD、YTD / LTD 销售类指标及各占比指标分子分母（区间汇总） |
| **数据底表（库存类）** | `s02_inventory_stock_sales_detail_d`：EOH 及 YTD / LTD ST% 库存分母等期末时点指标 |
| **商品维度切换** | Division = MN / WM / CW / HM（页面级商品维度切换，取值 `division`） |
| **全局支持筛选维度（渠道）** | 渠道：platform（取值 `platform`）、store name（取值 `shop_name`） |
| **全局支持筛选维度（商品）** | 商品：label（取值 `label`）、division（取值 `division`）、product type（取值 `product_type`）、framework（取值 `framework`）、category（取值 `category`）、ax class（取值 `ax_class`）、category summary（取值 `category_summary`）、special supply（取值 `special_supply`）、predictive buy（取值 `predictive_buy`） |
| **数量/金额口径判定** | 以 Name_EN 为准：Unit = 数量口径，Amt = 金额口径；计算字段以原始口径计算指标列为准 |
| **时间口径（区间类）** | SLS、AUR、MD 及各占比分子分母等：看所选时间范围 this period（区间汇总）；原始口径未显式标注时间范围的区间类指标均按此口径处理 |
| **时间口径（期末时点类）** | EOH 及 YTD / LTD ST% 库存分母等：看所选时间范围 end period 最后一天（时点数） |
| **LP 附属口径** | LP SLS Amt%：与主指标同口径，时间范围看 last period（区间）；LP EOH Amt%：时间范围看 last period 最后一天（时点） |
| **vs LP 附属指标（差值 bp）** | this period - last period（差值，bp 指标，展示时 ×10000 转 bp）；仅 Top Size Sales Performance【Sales】/【Inventory】主指标附属 |
| **YTD 口径** | this period 所在财年第一天至 this period 最后一天，与 last period 无关 |
| **LTD 口径** | 开店以来：≤ this period 最后一天（无固定起始日），与 last period 无关 |
| **Series 板块特殊限制** | 仅统计 special_series 有值的商品（含全部指标及占比分母） |
| **数据类型/数据格式** | 原始口径未定义数据类型与数据格式，本文档参照《数据类型和格式总览》及 Merchandise Performance Overview 已确认口径补齐，DAX 实现时以本口径文档为准 |
| **必须遵守** | 口径文档中定义的所有指标，必须遵守其数据类型和数据格式，如果和解决方案中存在争议的，一切以口径文档为准，必须按照口径文档中的格式进行调整 |
| **DAX 语法规范** | 文本常量必须使用双引号 `" "`，禁止使用单引号；单引号 `' '` 仅用于表名，列名使用方括号 `[ ]`，例如：`[md_type] = "FP"` |

---

## 子模块一：Top Size Sales Performance【Sales】

> **行维度**: Category：`category` > Size Category：`sku_size_category` > Size：`sku_size`
> **支持筛选维度**: 渠道：platform，shop_name；商品：label，division，product_type，framework，category，ax_class，category_summary，special_supply，predictive_buy

### 1. SLS Amt% — 销售金额占比

| 项目 | 内容 |
|---|---|
| **指标名称** | SLS Amt% / 销售金额占比 |
| **业务定义** | 该 size 占所属 size category 的比例 |
| **计算公式** | 时间范围看 this period；分子：该 category + size category + size 下 `sum(net_sales_amt)`；分母：该 category + size category 下 `sum(net_sales_amt)` |
| **数据底表** | `s02_trade_sku_data_d` |
| **附属指标** | LP SLS Amt%：时间范围看 last period，分子同本指标（last period 口径）；分母为该 category + size category 层级 last period 汇总，且仅含 This Period 有销售金额的 size（可见 size 集合，2026-10-15 业务确认）；vs LP：this period - last period（差值，bp 指标，展示时 ×10000 转 bp） |
| **数据类型** | percent_0dp → 百分比整数，不含正号 |
| **数据格式** | `#,##0%` |
| **附属指标类型** | LP SLS Amt%:percent_0dp、vs LP:integer_bp |
| **integer_bp数据类型** | integer_bp → 增减基点整数：→ 120bp / -80bp（基点，不含正号，含负号，值×10000 转 bp），乘以 10000 的操作可以放在 Cell Display 度量中实现 |
| **integer_bp数据格式** | `#,##0bp;-#,##0bp;0bp` |

---

## 子模块二：Top Size Sales Performance【Inventory】

> **行维度**: Category：`category` > Size Category：`sku_size_category` > Size：`sku_size`
> **支持筛选维度**: 渠道：platform，shop_name；商品：label，division，product_type，framework，category，ax_class，category_summary，special_supply，predictive_buy

### 2. EOH Amt% — 期末库存金额占比

| 项目 | 内容 |
|---|---|
| **指标名称** | EOH Amt% / 期末库存金额占比 |
| **业务定义** | 该 size 占所属 size category 的比例 |
| **计算公式** | 时间范围看 this period 最后一天；分子：该 category + size category + size 下 `sum(msrp_inv_amt)`；分母：该 category + size category 下 `sum(msrp_inv_amt)` |
| **数据底表** | `s02_inventory_stock_sales_detail_d` |
| **附属指标** | LP EOH Amt%：时间范围看 last period 最后一天，分子同本指标（last period 口径）；分母为该 category + size category 层级 last period 最后一天汇总，且仅含 This Period 有库存金额的 size（可见 size 集合，2026-10-15 业务确认）；vs LP：this period - last period（差值，bp 指标，展示时 ×10000 转 bp） |
| **数据类型** | percent_0dp → 百分比整数，不含正号 |
| **数据格式** | `#,##0%` |
| **附属指标类型** | LP EOH Amt%:percent_0dp、vs LP:integer_bp |
| **integer_bp数据类型** | integer_bp → 增减基点整数：→ 120bp / -80bp（基点，不含正号，含负号，值×10000 转 bp），乘以 10000 的操作可以放在 Cell Display 度量中实现 |
| **integer_bp数据格式** | `#,##0bp;-#,##0bp;0bp` |

---

## 子模块三：Top Color Sales Performance【Sales】

> **行维度**: Color：`color_name`
> **支持筛选维度**: 渠道：platform，shop_name；商品：label，division，product_type，framework，category，ax_class，category_summary，special_supply，predictive_buy

### 3. SLS Amt — DCom净销售额

| 项目 | 内容 |
|---|---|
| **指标名称** | SLS Amt / DCom净销售额 |
| **业务定义** | 统计周期内DCom净销售额 = DCom销售订单总销售额 - 退货额 |
| **计算公式** | 时间范围看 this period；该 color 下 `sum(net_sales_amt)` |
| **数据底表** | `s02_trade_sku_data_d` |
| **数据类型** | currency → 货币符号由币种切片器决定，千分位整数 |
| **数据格式** | `#,##0`（在 DAX 中用 `__CurrencySymbol & FORMAT(__Value, "#,##0")` 拼接币种符号） |

---

### 4. SLS Amt% — 销售金额占比

| 项目 | 内容 |
|---|---|
| **指标名称** | SLS Amt% / 销售金额占比 |
| **业务定义** | 该 color 占 total 的比例 |
| **计算公式** | 时间范围看 this period；分子：该 color 下 `sum(net_sales_amt)`；分母：`sum(net_sales_amt)` |
| **数据底表** | `s02_trade_sku_data_d` |
| **数据类型** | percent_0dp → 百分比整数，不含正号 |
| **数据格式** | `#,##0%` |

---

### 5. SLS Unit — DCom净销售数量

| 项目 | 内容 |
|---|---|
| **指标名称** | SLS Unit / DCom净销售数量 |
| **业务定义** | 统计周期内该 color 下 DCom 销售数量（`product_qty`）之和 |
| **计算公式** | 时间范围看 this period；该 color 下 `sum(product_qty)` |
| **数据底表** | `s02_trade_sku_data_d` |
| **注意** | 原始口径 Definition"统计周期内DCom净销售数量=DCom销售订单总销售数量-退货数量"已确认为笔误，字段口径以计算指标列 `sum(product_qty)` 为准 |
| **数据类型** | integer → 整数，千分位整数 |
| **数据格式** | `#,##0` |

---

### 6. SLS Unit% — DCom净销售数量占比

| 项目 | 内容 |
|---|---|
| **指标名称** | SLS Unit% / DCom净销售数量占比 |
| **业务定义** | 该 color 占 total 的比例 |
| **计算公式** | 时间范围看 this period；分子：该 color 下 `sum(product_qty)`；分母：`sum(sales_qty)` |
| **数据底表** | `s02_trade_sku_data_d` |
| **注意** | 同 SLS Unit：原始口径 Definition 等式已确认为笔误，字段口径以计算指标列 `sum(product_qty)` 为准 |
| **数据类型** | percent_0dp → 百分比整数，不含正号 |
| **数据格式** | `#,##0%` |

---

## 子模块四：Top Color Sales Performance【Inventory】

> **行维度**: Color：`color_name`
> **支持筛选维度**: 渠道：platform，shop_name；商品：label，division，product_type，framework，category，ax_class，category_summary，special_supply，predictive_buy

### 7. EOH Amt — 期末库存金额

| 项目 | 内容 |
|---|---|
| **指标名称** | EOH Amt / 期末库存金额 |
| **业务定义** | EOH Units × msrp |
| **计算公式** | 时间范围看 this period 最后一天；该 color 下 `sum(msrp_inv_amt)` |
| **数据底表** | `s02_inventory_stock_sales_detail_d` |
| **数据类型** | currency → 货币符号由币种切片器决定，千分位整数 |
| **数据格式** | `#,##0`（在 DAX 中用 `__CurrencySymbol & FORMAT(__Value, "#,##0")` 拼接币种符号） |

---

### 8. EOH Amt% — 期末库存金额占比

| 项目 | 内容 |
|---|---|
| **指标名称** | EOH Amt% / 期末库存金额占比 |
| **业务定义** | 该 color 占 total 的比例 |
| **计算公式** | 时间范围看 this period 最后一天；分子：该 color 下 `sum(msrp_inv_amt)`；分母：`sum(msrp_inv_amt)` |
| **数据底表** | `s02_inventory_stock_sales_detail_d` |
| **数据类型** | percent_0dp → 百分比整数，不含正号 |
| **数据格式** | `#,##0%` |

---

### 9. EOH Unit — 期末库存数量

| 项目 | 内容 |
|---|---|
| **指标名称** | EOH Unit / 期末库存数量 |
| **业务定义** | 选定日期业务周期结束时点的期末库存总数量 |
| **计算公式** | 时间范围看 this period 最后一天；该 color 下 `sum(stock_inv_qty)` |
| **数据底表** | `s02_inventory_stock_sales_detail_d` |
| **数据类型** | integer → 整数，千分位整数 |
| **数据格式** | `#,##0` |

---

### 10. EOH Unit% — 期末库存数量占比

| 项目 | 内容 |
|---|---|
| **指标名称** | EOH Unit% / 期末库存数量占比 |
| **业务定义** | 该 color 占 total 的比例 |
| **计算公式** | 时间范围看 this period 最后一天；分子：该 color 下 `sum(stock_inv_qty)`；分母：`sum(stock_inv_qty)` |
| **数据底表** | `s02_inventory_stock_sales_detail_d` |
| **数据类型** | percent_0dp → 百分比整数，不含正号 |
| **数据格式** | `#,##0%` |

---

## 子模块五：Emerging Style Identification【Sales】

> **行维度**: Color：`color_name` > Size：`sku_size`
> **支持筛选维度**: 渠道：platform，shop_name；商品：label，division，product_type，framework，category，ax_class，category_summary，special_supply，predictive_buy

### 11. SLS Amt% — 销售金额占比

| 项目 | 内容 |
|---|---|
| **指标名称** | SLS Amt% / 销售金额占比 |
| **业务定义** | 该 color + size 占该 color 的比例 |
| **计算公式** | 时间范围看 this period；分子：该 color + size 下 `sum(net_sales_amt)`；分母：该 color 下 `sum(net_sales_amt)` |
| **数据底表** | `s02_trade_sku_data_d` |
| **数据类型** | percent_0dp → 百分比整数，不含正号 |
| **数据格式** | `#,##0%` |

---

## 子模块六：Emerging Style Identification【Inventory】

> **行维度**: Color：`color_name` > Size：`sku_size`
> **支持筛选维度**: 渠道：platform，shop_name；商品：label，division，product_type，framework，category，ax_class，category_summary，special_supply，predictive_buy

### 12. EOH Amt% — 期末库存金额占比

| 项目 | 内容 |
|---|---|
| **指标名称** | EOH Amt% / 期末库存金额占比 |
| **业务定义** | 该 color + size 占该 color 的比例 |
| **计算公式** | 时间范围看 this period 最后一天；分子：该 color + size 下 `sum(msrp_inv_amt)`；分母：该 color 下 `sum(msrp_inv_amt)` |
| **数据底表** | `s02_inventory_stock_sales_detail_d` |
| **数据类型** | percent_0dp → 百分比整数，不含正号 |
| **数据格式** | `#,##0%` |

---

## 子模块七：Series Sales Performance

> **行维度**: Series：`special_series`（仅展示有值数据）> AXC：`spu_id`；Image：`spu_img_url`（商品图片列，非数值）
> **支持筛选维度**: 渠道：platform，shop_name；商品：label，division，product_type，framework，category，ax_class，category_summary，special_supply，predictive_buy
> **特殊限制**: 仅统计 special_series 有值的商品（含全部指标及占比分母），销售类指标取 `s02_trade_sku_data_d`，库存类指标取 `s02_inventory_stock_sales_detail_d`

### 13. SLS Amt — DCom净销售额

| 项目 | 内容 |
|---|---|
| **指标名称** | SLS Amt / DCom净销售额 |
| **业务定义** | 统计周期内DCom净销售额 = DCom销售订单总销售额 - 退货额 |
| **计算公式** | 时间范围看 this period；该 spu_id 下 `sum(net_sales_amt)` |
| **数据底表** | `s02_trade_sku_data_d` |
| **数据类型** | currency → 货币符号由币种切片器决定，千分位整数 |
| **数据格式** | `#,##0`（在 DAX 中用 `__CurrencySymbol & FORMAT(__Value, "#,##0")` 拼接币种符号） |

---

### 14. SLS Amt% — 销售金额占比

| 项目 | 内容 |
|---|---|
| **指标名称** | SLS Amt% / 销售金额占比 |
| **业务定义** | 该 AXC 占 total 的比例 |
| **计算公式** | 时间范围看 this period；分子：该 spu_id 下 `sum(net_sales_amt)`；分母：`sum(net_sales_amt)`（special_series 有值范围内） |
| **数据底表** | `s02_trade_sku_data_d` |
| **数据类型** | percent_0dp → 百分比整数，不含正号 |
| **数据格式** | `#,##0%` |

---

### 15. SLS Unit — DCom净销售数量

| 项目 | 内容 |
|---|---|
| **指标名称** | SLS Unit / DCom净销售数量 |
| **业务定义** | 统计周期内该 spu_id 下 DCom 销售数量（`sales_qty`）之和 |
| **计算公式** | 时间范围看 this period；该 spu_id 下 `sum(sales_qty)` |
| **数据底表** | `s02_trade_sku_data_d` |
| **注意** | 字段口径以计算指标列 `sum(sales_qty)` 为准（Unit 类指标 Definition 等式已确认为笔误，见通用规则汇总） |
| **数据类型** | integer → 整数，千分位整数 |
| **数据格式** | `#,##0` |

---

### 16. SLS Unit% — DCom净销售数量占比

| 项目 | 内容 |
|---|---|
| **指标名称** | SLS Unit% / DCom净销售数量占比 |
| **业务定义** | 该 AXC 占 total 的比例 |
| **计算公式** | 时间范围看 this period；分子：该 spu_id 下 `sum(sales_qty)`；分母：`sum(sales_qty)`（special_series 有值范围内） |
| **数据底表** | `s02_trade_sku_data_d` |
| **注意** | 同 SLS Unit：字段口径以计算指标列 `sum(sales_qty)` 为准 |
| **数据类型** | percent_0dp → 百分比整数，不含正号 |
| **数据格式** | `#,##0%` |

---

### 17. EOH Amt — 期末库存金额

| 项目 | 内容 |
|---|---|
| **指标名称** | EOH Amt / 期末库存金额 |
| **业务定义** | EOH Units × msrp |
| **计算公式** | 时间范围看 this period 最后一天；该 spu_id 下 `sum(msrp_inv_amt)` |
| **数据底表** | `s02_inventory_stock_sales_detail_d` |
| **数据类型** | currency → 货币符号由币种切片器决定，千分位整数 |
| **数据格式** | `#,##0`（在 DAX 中用 `__CurrencySymbol & FORMAT(__Value, "#,##0")` 拼接币种符号） |

---

### 18. EOH Amt% — 期末库存金额占比

| 项目 | 内容 |
|---|---|
| **指标名称** | EOH Amt% / 期末库存金额占比 |
| **业务定义** | 该 AXC 占 total 的比例 |
| **计算公式** | 时间范围看 this period 最后一天；分子：该 spu_id 下 `sum(msrp_inv_amt)`；分母：`sum(msrp_inv_amt)`（special_series 有值范围内） |
| **数据底表** | `s02_inventory_stock_sales_detail_d` |
| **数据类型** | percent_0dp → 百分比整数，不含正号 |
| **数据格式** | `#,##0%` |

---

### 19. EOH Unit — 期末库存数量

| 项目 | 内容 |
|---|---|
| **指标名称** | EOH Unit / 期末库存数量 |
| **业务定义** | 选定日期业务周期结束时点的期末库存总数量 |
| **计算公式** | 时间范围看 this period 最后一天；该 spu_id 下 `sum(stock_inv_qty)` |
| **数据底表** | `s02_inventory_stock_sales_detail_d` |
| **数据类型** | integer → 整数，千分位整数 |
| **数据格式** | `#,##0` |

---

### 20. EOH Unit% — 期末库存数量占比

| 项目 | 内容 |
|---|---|
| **指标名称** | EOH Unit% / 期末库存数量占比 |
| **业务定义** | 该 AXC 占 total 的比例 |
| **计算公式** | 时间范围看 this period 最后一天；分子：该 spu_id 下 `sum(stock_inv_qty)`；分母：`sum(stock_inv_qty)`（special_series 有值范围内） |
| **数据底表** | `s02_inventory_stock_sales_detail_d` |
| **数据类型** | percent_0dp → 百分比整数，不含正号 |
| **数据格式** | `#,##0%` |

---

### 21. AUR — 件单价

| 项目 | 内容 |
|---|---|
| **指标名称** | AUR / 件单价 |
| **业务定义** | 净销售金额 / 商品净出库件数 |
| **计算公式** | 时间范围看 this period；该 spu_id 下 `sum(net_sales_amt) / sum(net_sales_qty)` |
| **数据底表** | `s02_trade_sku_data_d` |
| **数据类型** | currency → 货币符号由币种切片器决定，千分位整数 |
| **数据格式** | `#,##0`（在 DAX 中用 `__CurrencySymbol & FORMAT(__Value, "#,##0")` 拼接币种符号） |

---

### 22. MD — 平均折扣

| 项目 | 内容 |
|---|---|
| **指标名称** | MD / 平均折扣 |
| **业务定义** | 1 - 折扣价 / 原价 × 100% |
| **计算公式** | 时间范围看 this period；该 spu_id 下 `1 - sum(md_net_sales_amt) / sum(msrp_net_sales_amt)` |
| **数据底表** | `s02_trade_sku_data_d` |
| **数据类型** | percent_0dp → 百分比整数，不含正号 |
| **数据格式** | `#,##0%` |

---

### 23. YTD SLS Unit — YTD DCom净销售数量

| 项目 | 内容 |
|---|---|
| **指标名称** | YTD SLS Unit / YTD DCom净销售数量 |
| **业务定义** | 年至今该 spu_id 下 DCom 销售数量（`sales_qty`）之和 |
| **计算公式** | 时间范围看 this period 所在财年第一天至 this period 最后一天；该 spu_id 下 `sum(sales_qty)` |
| **数据底表** | `s02_trade_sku_data_d` |
| **注意** | 原始口径 Definition"年至今DCom净销售数量=DCom销售订单总销售数量-退货数量"已确认为笔误，字段口径以计算指标列 `sum(sales_qty)` 为准 |
| **数据类型** | integer → 整数，千分位整数 |
| **数据格式** | `#,##0` |

---

### 24. YTD ST% (Unit) — YTD售罄率%（数量）

| 项目 | 内容 |
|---|---|
| **指标名称** | YTD ST% (Unit) / YTD售罄率%（数量） |
| **业务定义** | 年至今销售数量 /（年至今销售数量 + 期末库存数量）× 100% |
| **计算公式** | 销售数量：时间范围看 this period 所在财年第一天至 this period 最后一天，销售数量之和；期末库存数量：看所选时间范围 end period 最后一天；`sales.net_sales_qty / (sales.net_sales_qty + inv.inv_qty)` |
| **数据底表** | `s02_trade_sku_data_d`（sales）；`s02_inventory_stock_sales_detail_d`（inv） |
| **注意** | 原始口径计算指标描述中"销售金额 / 期末库存金额"字样已确认为笔误，以公式为准（数量口径） |
| **数据类型** | percent_0dp → 百分比整数，不含正号 |
| **数据格式** | `#,##0%` |

---

### 25. YTD ST% (Amt) — YTD售罄率%（金额）

| 项目 | 内容 |
|---|---|
| **指标名称** | YTD ST% (Amt) / YTD售罄率%（金额） |
| **业务定义** | 年至今销售金额 /（年至今销售金额 + 期末库存金额）× 100% |
| **计算公式** | 销售金额：时间范围看 this period 所在财年第一天至 this period 最后一天，销售金额之和；期末库存金额：看所选时间范围 end period 最后一天；`sales.net_sales_amt / (sales.net_sales_amt + inv.msrp_inv_amt)` |
| **数据底表** | `s02_trade_sku_data_d`（sales）；`s02_inventory_stock_sales_detail_d`（inv） |
| **数据类型** | percent_0dp → 百分比整数，不含正号 |
| **数据格式** | `#,##0%` |

---

### 26. LTD SLS Unit — LTD DCom净销售数量

| 项目 | 内容 |
|---|---|
| **指标名称** | LTD SLS Unit / LTD DCom净销售数量 |
| **业务定义** | 开店以来该 spu_id 下 DCom 销售数量（`sales_qty`）之和 |
| **计算公式** | 销售数量：≤ 时间范围 this period 的最后一天；该 spu_id 下 `sum(sales_qty)` |
| **数据底表** | `s02_trade_sku_data_d` |
| **注意** | 原始口径计算指标列写 `sum(net_sales_amt)`（金额字段），已确认为笔误，按 Name_EN（Unit = 数量口径）修正为 `sum(sales_qty)`（与 SLS Unit / YTD SLS Unit 系列一致）；原始 Definition 等式同为笔误 |
| **数据类型** | integer → 整数，千分位整数 |
| **数据格式** | `#,##0` |

---

### 27. LTD ST% (Unit) — LTD售罄率%（数量）

| 项目 | 内容 |
|---|---|
| **指标名称** | LTD ST% (Unit) / LTD售罄率%（数量） |
| **业务定义** | 开店以来销售数量 /（开店以来销售数量 + 期末库存数量）× 100% |
| **计算公式** | 销售数量：≤ 时间范围 this period 的最后一天；期末库存数量：看所选时间范围 end period 最后一天；`sales.net_sales_qty / (sales.net_sales_qty + inv.inv_qty)` |
| **数据底表** | `s02_trade_sku_data_d`（sales）；`s02_inventory_stock_sales_detail_d`（inv） |
| **注意** | 原始口径公式 `sales.net_sales_amt / (sales.net_sales_amt + inv.inv_qty)` 分子分母量纲不匹配，已确认修正为数量口径（与 YTD ST% (Unit) 一致）；描述中"销售金额 / 期末库存金额"字样同为笔误，以公式为准 |
| **数据类型** | percent_0dp → 百分比整数，不含正号 |
| **数据格式** | `#,##0%` |

---

## 通用规则汇总

| 规则项 | 说明 |
|---|---|
| **数据底表** | 销售类指标用 `s02_trade_sku_data_d`；库存类指标用 `s02_inventory_stock_sales_detail_d`；YTD / LTD ST% 跨双表（sales + inv）；Series Sales Performance 板块双表共用且仅统计 special_series 有值的商品 |
| **全局支持筛选维度** | 渠道：platform、shop_name；商品：label，division，product_type，framework，category，ax_class，category_summary，special_supply，predictive_buy |
| **商品维度切换** | Division = MN / WM / CW / HM（页面级，取值 `division`） |
| **数量/金额口径判定** | 以 Name_EN 为准：Unit = 数量口径，Amt = 金额口径；计算字段以原始口径计算指标列为准，Definition 列等式不作为字段依据 |
| **时间口径** | 区间类指标（SLS / AUR / MD / 占比类）：看所选时间范围 this period 汇总；期末库存类指标（EOH / ST% 库存分母）：看所选时间范围 end period 最后一天 |
| **LP 口径** | LP SLS Amt%：last period 区间汇总；LP EOH Amt%：last period 最后一天（时点数）；LP 分母均限定「This Period 有金额的 size」（可见 size 集合，与当期占比的显示行基数对齐，2026-10-15 业务确认） |
| **vs LP 规则** | this period - last period（差值，bp 指标，展示时 ×10000 转 bp）；仅 Top Size Sales Performance【Sales】/【Inventory】主指标附属 |
| **YTD / LTD 口径** | YTD：this period 所在财年第一天至 this period 最后一天；LTD：开店以来（≤ this period 最后一天，无固定起始日）；二者均与 last period 无关 |
| **占比分母层级** | Top Size：分母为该 category + size category 层级；Top Color：分母为 total；Emerging Style：分母为该 color 层级；Series：分母为 special_series 有值范围内的 total |
| **口径笔误修正记录** | ① Unit 类指标 Definition 等式"=总销售数量-退货数量"为笔误，字段以计算指标列 `sum(sales_qty)` 为准；② LTD SLS Unit 计算指标 `sum(net_sales_amt)` 为笔误，修正为 `sum(sales_qty)`；③ LTD ST% (Unit) 公式修正为数量口径 `sales.net_sales_qty / (sales.net_sales_qty + inv.inv_qty)`；④ YTD / LTD ST% (Unit)、LTD SLS Unit 描述中"销售金额 / 期末库存金额"字样为笔误，以公式为准（均已与业务确认） |
| **必须遵守** | 口径文档中定义的所有指标，必须遵守其数据类型和数据格式，如果和解决方案中存在争议的，一切以口径文档为准，必须按照口径文档中的格式进行调整 |
| **DAX 语法规范** | 文本常量必须使用双引号 `" "`，禁止使用单引号；单引号 `' '` 仅用于表名，列名使用方括号 `[ ]`，例如：`[md_type] = "FP"` |
