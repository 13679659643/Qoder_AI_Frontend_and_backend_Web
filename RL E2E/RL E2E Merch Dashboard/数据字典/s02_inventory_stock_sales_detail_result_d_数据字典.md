# s02_inventory_stock_sales_detail_result_d 数据字典

## 表基本信息

| 属性 | 值 |
|------|-----|
| 表名 | s02_inventory_stock_sales_detail_result_d |
| 表注释 | 库存+销售+补货到sku模型表 |
| 是否分区表 | 是 |
| 数据更新方式 | 全量 |
| 存储引擎 | CnchMergeTree |
| 备注 | |

## 唯一键信息

| 类型 | 字段 |
|------|------|
| UNIQUE KEY | dt, sku_id, spu_id, data_type |
| ORDER BY | dt, sku_id, spu_id, data_type |

## 字段明细

| 字段名 | 字段类型 | 字段注释 | 是否主键 | 字段说明 | 值示例 | 备注 |
|--------|----------|----------|----------|----------|--------|------|
| etl_time | String | 数据创建时间 |  |  |  |  |
| dt | String | 数据日期 | 是 |  |  |  |
| sku_id | String | sku id | 是 | AX + color + 码 |  |  |
| sku_name | String | 商品名称 |  |  |  |  |
| bar_code | String | bar_code |  |  |  |  |
| spu_id | String | spu id | 是 | AX + color |  |  |
| spu_name | String | spu名称 |  |  |  |  |
| data_type | String | sku/spu | 是 |  |  |  |
| product_id | String | product_id |  | AX Item |  |  |
| product_name | String | product_name |  |  |  |  |
| is_hero_model | Int32 | 是否是hero_model |  |  | 1:是 0:否 |  |
| is_psr | Int32 | 是否是psr |  |  | 1:是 0:否 |  |
| season_tag | String | season_tag |  |  |  |  |
| brand | String | Label |  |  |  |  |
| division | String | division |  |  |  |  |
| framework | String | framework |  |  |  |  |
| category | String | category |  |  |  |  |
| category_summary | String | category_summary |  |  |  |  |
| ax_class | String | ax_class |  |  |  |  |
| ax_sub_class | String | ax_sub_class |  |  |  |  |
| special_supply | String | special_supply |  |  |  |  |
| special_series | String | special_series |  |  |  |  |
| spu_model | String | spu_model |  |  |  |  |
| sku_size | String | sku_size |  |  |  |  |
| sku_size_category | String | sku_size_category |  |  |  |  |
| spu_img_url | String | 商品图片 |  |  |  |  |
| us_style | String | us_style |  |  |  |  |
| color_code | String | color_code |  |  |  |  |
| color_name | String | color_name |  |  |  |  |
| season | String | season |  |  |  |  |
| super_season | String | super_season |  |  |  |  |
| product_type | String | product_type |  |  |  |  |
| predictive_buy | Int32 | predictive_buy |  |  |  |  |
| launch_time | String | launch_time |  |  |  |  |
| md_type | String | md_type |  |  |  |  |
| md_rate | Float64 | 折扣比例 |  |  |  |  |
| md_diff | Float64 | 折扣差异 |  |  |  |  |
| md_remark | String | 折扣备注 |  |  |  |  |
| msrp_inv_amt | Decimal(19, 4) | 吊牌库存金额 |  |  |  |  |
| md_inv_amt | Decimal(19, 4) | 折扣价库存金额 |  |  |  |  |
| inv_qty | Int64 | 库存数量 |  |  |  |  |
| msrp_occupy_inv_amt | Decimal(19, 4) | 吊牌价占用库存金额 |  |  |  |  |
| md_occupy_inv_amt | Decimal(19, 4) | 折扣价占用库存金额 |  |  |  |  |
| occupy_inv_qty | Int64 | 占用库存 |  |  |  |  |
| msrp_stock_inv_amt | Decimal(19, 4) | 吊牌价在库库存金额 |  |  |  |  |
| md_stock_inv_amt | Decimal(19, 4) | 折扣价在库库存金额 |  |  |  |  |
| stock_inv_qty | Int64 | 在库库存 |  |  |  |  |
| msrp_in_trans_inv_amt | Decimal(19, 4) | 在途吊牌库存金额 |  |  |  |  |
| md_in_trans_inv_amt | Decimal(19, 4) | 在途折扣价库存金额 |  |  |  |  |
| in_trans_inv_qty | Int64 | 在途库存数量 |  |  |  |  |
| msrp_o2o_inv_amt | Decimal(19, 4) | o2o吊牌库存金额 |  |  |  |  |
| md_o2o_inv_amt | Decimal(19, 4) | o2o折扣价库存金额 |  |  |  |  |
| o2o_inv_qty | Int64 | o2o库存数量 |  |  |  |  |
| weeks_cover | Float64 | 库存周转周数 |  |  |  |  |
| msrp_sales_amt | Decimal(19, 4) | 吊牌价NET销售金额 |  |  |  |  |
| md_sales_amt | Decimal(19, 4) | 折扣NET销售金额 |  |  |  |  |
| net_sales_amt | Decimal(19, 4) | 实际NET销售金额 |  |  |  |  |
| sales_qty | Int64 | 销售数量 |  |  |  |  |
| label_cat_sales_qty | Int64 | 同label,category 销售数量 |  |  |  |  |
| last_4week_sales_qty | Int64 | 近4周销售数量 |  |  |  |  |
| last_4week_sales_avg_qty | Float64 | 近4周平均销售数量（除以4） |  |  |  |  |
| last_4week_sales_label_cat_qty | Int64 | 同label,category近4周销售数量 |  |  |  |  |
| last_4week_sales_label_cat_avg_qty | Float64 | 同label,category近4周平均销售数量/SKU 个数 |  |  |  |  |
| computed_product_tag | String | 商品分层标签:hero model,slow mover,normal |  |  |  |  |
| oos_tag | String | 缺货标签 |  |  |  |  |
| promotion_tier_tag | String | 营销分层标签 |  |  |  |  |
| reph_qty | Int64 | 补货数量 |  |  |  |  |
| msrp_reph_amt | Decimal(19, 4) | 吊牌价补货金额 |  |  |  |  |
| md_reph_amt | Decimal(19, 4) | 折扣价补货金额 |  |  |  |  |
