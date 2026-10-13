# s02_inventory_stock_sales_detail_d 数据字典

## 表基本信息

| 属性 | 值 |
|------|-----|
| 表名 | s02_inventory_stock_sales_detail_d |
| 表注释 | 库存+销售+补货到sku模型表 |
| 是否分区表 | 未定义（建表语句未提供 PARTITION BY） |
| 存储引擎 | CnchMergeTree |
| 备注 | 字段、字段类型及唯一键信息以 ClickHouse 建表语句为准 |

## 字段明细

| 字段名 | 字段类型 | 字段注释 | 是否主键 | 字段说明 | 值示例 | 备注 |
|--------|----------|----------|----------|----------|--------|------|
| etl_time | Nullable(String) | 数据创建时间 |  | 数据记录创建时间 |  |  |
| dt | Nullable(String) | 数据日期 | 是 | 数据所属日期 | 2024-03-15 | 唯一键字段 |
| sku_id | Nullable(String) | sku id | 是 | SKU唯一标识，由 AX、颜色及尺码组成 |  | 唯一键字段 |
| sku_name | Nullable(String) | 商品名称 |  | SKU名称 |  |  |
| bar_code | Nullable(String) | bar_code |  | 商品条码 |  |  |
| spu_id | Nullable(String) | spu id |  | SPU唯一标识，由 AX、颜色组成 |  |  |
| spu_name | Nullable(String) | spu名称 |  | SPU名称 |  |  |
| product_id | Nullable(String) | product_id |  | AX Item 标识 |  |  |
| product_name | Nullable(String) | product_name |  | 产品名称 |  |  |
| is_hero_model | Nullable(Int32) | 是否是hero_model |  | 是否 hero model：1 表示是，0 表示否 | 1 |  |
| is_psr | Nullable(Int32) | 是否是psr |  | 是否 PSR：1 表示是，0 表示否 | 1 |  |
| season_tag | Nullable(String) | season_tag |  | 季节标签 |  |  |
| brand | Nullable(String) | Label |  | 品牌标签 |  |  |
| division | Nullable(String) | division |  | 事业部/性别维度 |  |  |
| framework | Nullable(String) | framework |  | 产品框架 |  |  |
| category | Nullable(String) | category |  | 品类 |  |  |
| category_summary | Nullable(String) | category_summary |  | 品类汇总/归纳层级 |  |  |
| ax_class | Nullable(String) | ax_class |  | AX分类 |  |  |
| ax_sub_class | Nullable(String) | ax_sub_class |  | AX子分类 |  |  |
| special_supply | Nullable(String) | special_supply |  | 特供标识 |  |  |
| special_series | Nullable(String) | special_series |  | 特别系列 |  |  |
| spu_model | Nullable(String) | spu_model |  | SPU款号/模型 |  |  |
| sku_size | Nullable(String) | sku_size |  | SKU尺码 |  |  |
| sku_size_category | Nullable(String) | sku_size_category |  | SKU尺码分类 |  |  |
| spu_img_url | Nullable(String) | 商品图片 |  | SPU商品图片链接 |  |  |
| us_style | Nullable(String) | us_style |  | US款号/风格标识 |  |  |
| color_code | Nullable(String) | color_code |  | 颜色编码 |  |  |
| color_name | Nullable(String) | color_name |  | 颜色名称 |  |  |
| season | Nullable(String) | season |  | 季节 |  |  |
| super_season | Nullable(String) | super_season |  | 超级季节/大季维度 |  | season_final |
| product_type | Nullable(String) | product_type |  | 产品类型 |  |  |
| predictive_buy | Nullable(Int32) | predictive_buy |  | 是否 predictive buy：1 表示是，0 表示否 | 1 |  |
| launch_time | Nullable(String) | launch_time |  | 上架时间 |  |  |
| md_type | Nullable(String) | md_type |  | 折扣类型 |  |  |
| md_rate | Nullable(Float64) | 折扣比例 |  | 折扣比例 |  |  |
| md_diff | Nullable(Float64) | 折扣差异 |  | 折扣差异 |  |  |
| md_remark | Nullable(String) | 折扣备注 |  | 折扣相关备注 |  |  |
| msrp_inv_amt | Nullable(Decimal(19, 4)) | 吊牌库存金额 |  | 库存按吊牌价计算的金额 |  |  |
| md_inv_amt | Nullable(Decimal(19, 4)) | 折扣价库存金额 |  | 库存按折扣价计算的金额 |  |  |
| inv_qty | Nullable(Int64) | 库存数量 |  | 库存数量 |  |  |
| msrp_occupy_inv_amt | Nullable(Decimal(19, 4)) | 吊牌价占用库存金额 |  | 占用库存按吊牌价计算的金额 |  |  |
| md_occupy_inv_amt | Nullable(Decimal(19, 4)) | 折扣价占用库存金额 |  | 占用库存按折扣价计算的金额 |  |  |
| occupy_inv_qty | Nullable(Int64) | 占用库存 |  | 占用库存数量 |  |  |
| msrp_stock_inv_amt | Nullable(Decimal(19, 4)) | 吊牌价在库库存金额 |  | 在库库存按吊牌价计算的金额 |  |  |
| md_stock_inv_amt | Nullable(Decimal(19, 4)) | 折扣价在库库存金额 |  | 在库库存按折扣价计算的金额 |  |  |
| stock_inv_qty | Nullable(Int64) | 在库库存 |  | 在库库存数量 |  |  |
| msrp_in_trans_inv_amt | Nullable(Decimal(19, 4)) | 在途吊牌库存金额 |  | 在途库存按吊牌价计算的金额 |  |  |
| md_in_trans_inv_amt | Nullable(Decimal(19, 4)) | 在途折扣价库存金额 |  | 在途库存按折扣价计算的金额 |  |  |
| in_trans_inv_qty | Nullable(Int64) | 在途库存数量 |  | 在途库存数量 |  |  |
| msrp_o2o_inv_amt | Nullable(Decimal(19, 4)) | o2o吊牌库存金额 |  | O2O库存按吊牌价计算的金额 |  |  |
| md_o2o_inv_amt | Nullable(Decimal(19, 4)) | o2o折扣价库存金额 |  | O2O库存按折扣价计算的金额 |  |  |
| o2o_inv_qty | Nullable(Int64) | o2o库存数量 |  | O2O库存数量 |  |  |
| weeks_cover | Nullable(Float64) | 库存周转周数 |  | 按当前库存及销售速度计算的库存周转周数 |  |  |
| msrp_sales_amt | Nullable(Decimal(19, 4)) | 吊牌价NET销售金额 |  | NET销售金额按吊牌价计算的金额 |  |  |
| md_sales_amt | Nullable(Decimal(19, 4)) | 折扣NET销售金额 |  | NET销售金额按折扣价计算的金额 |  |  |
| net_sales_amt | Nullable(Decimal(19, 4)) | 实际NET销售金额 |  | 实际NET销售金额 |  |  |
| sales_qty | Nullable(Int64) | 销售数量 |  | 销售数量 |  |  |
| label_cat_sales_qty | Nullable(Int64) | 同label,category 销售数量 |  | 同 label、category 下销售数量，口径为出库减入库 |  |  |
| last_4week_sales_qty | Nullable(Int64) | 近4周销售数量 |  | 近4周销售数量，口径为出库减入库 |  |  |
| last_4week_sales_avg_qty | Nullable(Float64) | 近4周平均销售数量（除以4） |  | 近4周平均销售数量，口径为出库减入库 |  |  |
| last_4week_sales_label_cat_qty | Nullable(Int64) | 同label,category近4周销售数量 |  | 同 label、category 近4周销售数量，口径为出库减入库 |  |  |
| last_4week_sales_label_cat_avg_qty | Nullable(Float64) | 同label,category近4周平均销售数量/SKU 个数 |  | 同 label、category 近4周平均销售数量，按 SKU 个数平均 |  |  |
| computed_product_tag | Nullable(String) | 商品分层标签:hero model,slow mover,normal |  | 商品分层标签 | hero model |  |
| oos_tag | Nullable(String) | 缺货标签 |  | 商品缺货标签 |  |  |
| promotion_tier_tag | Nullable(String) | 营销分层标签 |  | 商品营销分层标签 |  |  |
| reph_qty | Nullable(Int64) | 补货数量 |  | 建议或计划补货数量 |  |  |
| msrp_reph_amt | Nullable(Decimal(19, 4)) | 吊牌价补货金额 |  | 补货数量按吊牌价计算的金额 |  |  |
| md_reph_amt | Nullable(Decimal(19, 4)) | 折扣价补货金额 |  | 补货数量按折扣价计算的金额 |  |  |

## 唯一键信息

建表语句未显式定义 `PRIMARY KEY`，定义了以下唯一键：

`dt, sku_id`

排序键 `ORDER BY` 同样按以下顺序定义：

`dt, sku_id`
