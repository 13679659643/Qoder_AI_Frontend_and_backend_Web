# a05_e2e_paid_media_product_data_d 数据字典

## 表基本信息

| 属性 | 值 |
|------|-----|
| 表名 | a05_e2e_paid_media_product_data_d |
| 表注释 | 流量数据产品粒度表 |
| 是否分区表 | 是 |
| 备注 | DCom Performance Media Operation Dashboard看板Category Growth模块取值表 |

## 字段明细

| 字段名 | 字段类型 | 字段注释 | 是否主键 | 字段说明 | 值示例 | 备注 |
|--------|----------|----------|----------|----------|--------|------|
| etl_time | String | 数据更新时间 |  |  | 2023/12/31 23:59:59 |  |
| dt | String | 分区字段，数据快照日期 | 是 |  | 2024/3/15 |  |
| data_type | String | 数据类型 | 是 |  | day |  |
| data_date | String | 数据日期 | 是 |  | 2024-03-15 |  |
| data_week | String | 数据周 |  |  |  |  |
| data_week_name | String | 数据周名称 |  |  |  |  |
| data_month | String | 数据月份 |  |  |  |  |
| data_month_name | String | 数据月份名称 |  |  |  |  |
| data_quarter | String | 数据季度 |  |  |  |  |
| data_quarter_name | String | 数据季度名称 |  |  |  |  |
| data_year | String | 数据年份 |  |  |  |  |
| data_year_name | String | 数据年份名称 |  |  |  |  |
| platform | String | 平台 | 是 |  |  |  |
| shop_info_id | bigint | 店铺唯一键 | 是 |  |  |  |
| shop_id | String | 店铺ID |  |  |  |  |
| shop_name | String | 店铺名称 |  |  |  |  |
| shop_code | String | 店铺code |  |  |  |  |
| framework | String | framework | 是 |  |  |  |
| brand | String | 品牌名称 | 是 |  |  |  |
| gender | String | 性别 | 是 |  |  |  |
| season | String | season | 是 |  |  |  |
| category | String | category | 是 |  |  |  |
| is_dtc | int | 是否dtc商品 | 是 |  |  |  |
| channel | String | 渠道 | 是 |  |  |  |
| mix_msg | String | 混合信息字段 | 是 | 包含Keyword_type和Crowd_layer的值 |  |  |
| 2.indep_rl_dw.t08_traffic_crowd_data_d | 1.keyword_type |  |  |  |  |  |
| 2.crowd_layer |  | mix_msg | TRUE |  |  |  |
| trans_cycle | String | 转化周期 | 是 |  |  |  |
| currency | String | 币种 | 是 |  |  |  |
| living_sku_cnt | int | 在推商品数量 |  |  |  | 页面自处理 |
| count(distinct spu_id) where cost_cnt=1 |  | living_sku_cnt | TRUE |  |  |  |
| sales_amt | decimal(19, 5) | 销售金额 |  |  |  |  |
| sales_order_cnt | bigint | 销售订单数 |  |  |  |  |
| sales_qty | bigint | 销售件数 |  |  |  |  |
| net_sales_amt | decimal(19, 5) | net销售额 |  |  |  |  |
| net_sales_order_cnt | bigint | net销售订单数 |  |  |  |  |
| net_sales_qty | bigint | net销售数量 |  |  |  |  |
| cost_amt | decimal(19, 5) | 推广花费 |  |  | 1000.00000 |  |
| media_sales_amt | decimal(19, 5) | 推广成交金额(投放带来) |  |  | 1000.00000 |  |
| media_sales_order_cnt | bigint | 推广成交订单数(投放带来) |  |  | 1000 |  |
| add_cart_cnt | bigint | 加购数 |  |  | 1000 |  |
| pv | bigint | 推广展现量 |  |  | 1000 |  |
| click | bigint | 推广点击量 |  |  | 1000 |  |
| stock_amt | decimal(19, 5) | 库存金额 |  |  | 1000.00000 |  |
| stock_qty | bigint | 库存数量 |  |  | 1000 |  |
| fcst_media_cost_amt | decimal(19, 5) | forecast推广花费 |  |  | 1000.00000 | 筛选kpi_name，此表还没开发，因为运营还没给数据，所以fcst两个字段先不写逻辑 |
| fcst_media_sales_amt | decimal(19, 5) | forecast推广成交金费 |  |  | 1000.00000 |  |
