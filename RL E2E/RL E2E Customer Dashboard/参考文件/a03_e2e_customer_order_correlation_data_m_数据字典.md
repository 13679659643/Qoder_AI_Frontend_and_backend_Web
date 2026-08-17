# a03_e2e_customer_order_correlation_data_m 数据字典

## 表基本信息

| 属性 | 值 |
|------|-----|
| 表名 | a03_e2e_customer_order_correlation_data_m |
| 表注释 | 用户订单关联数据月表 |
| 是否分区表 | 是 |
| 备注 | DCom Customer Operation Dashboard看板customer页面Co Purchase Matrix模块取数表 |

## 字段明细

| 字段名 | 字段类型 | 字段注释 | 是否主键 | 字段说明 | 值示例 | 备注 |
|--------|----------|----------|----------|----------|--------|------|
| etl_time | String | etl时间 | | | | |
| dt | String | 数据日期 | 是 | | | |
| data_month | String | 数据月份 | | | | |
| data_month_name | String | 数据月份名称 | | | 2026财年7月 | |
| data_quarter | String | 数据季度 | | | 3 | |
| data_quarter_name | String | 数据季度名称 | | | 2026财年第三季度 | |
| data_year | String | 数据年份 | | | 2026 | |
| data_year_name | String | 数据年份名称 | | | 2026财年 | |
| correlation_period | String | 订单关联周期 | 是 | 3M/6M/9M/12M | | |
| user_id | String | 用户id | 是 | | | |
| user_name | String | 用户名 | | | | |
| customer_type | String | 用户类型 | 是 | new/exists | | |
| platform | String | 平台 | 是 | | | |
| shop_info_id | bigint | 店铺唯一键 | 是 | | | |
| shop_id | String | 店铺ID | | | | |
| shop_name | String | 店铺名称 | | | | |
| shop_code | String | 店铺code | | | | |
| correlation_type | String | 关联方式 | 是 | same order/crocs order | | |
| product_id | String | 商品推广主体ID | 是 | | | |
| product_name | String | 商品推广主体名称 | | | | |
| framework | String | framework | | | | |
| brand | String | 品牌名称 | | | | |
| gender | String | 性别 | | | | |
| season | String | season | | | | |
| category | String | category | | | | |
| category_summary | String | 品类归纳 | | | | |
| co_product_id | String | 关联商品推广主体ID | 是 | | | |
| co_product_name | String | 关联商品推广主体名称 | | | | |
| co_framework | String | 关联framework | | | | |
| co_brand | String | 关联品牌名称 | | | | |
| co_gender | String | 关联性别 | | | | |
| co_season | String | 关联season | | | | |
| co_category | String | 关联category | | | | |
| co_category_summary | String | 品类归纳 | | | | |
| pay_amt | decimal(19, 5) | 购买金额 | | | | |
| pay_order_cnt | bigint | 购买订单数 | | | | |
| pay_qty | bigint | 购买商品数量 | | | | |
| net_pay_amt | decimal(19, 5) | net购买金额 | | | | |
| net_pay_order_cnt | bigint | net购买订单数 | | | | |
| net_pay_qty | bigint | net购买商品数量 | | | | |
| return_amt | decimal(19, 5) | 退款金额 | | | | |
| return_order_cnt | bigint | 退款订单数 | | | | |
| return_qty | bigint | 退款商品数量 | | | | |
| cancel_amt | decimal(19, 5) | 取消金额 | | | | |
| cancel_order_cnt | bigint | 取消订单数 | | | | |
| cancel_qty | bigint | 取消商品数量 | | | | |
| co_pay_amt | decimal(19, 5) | 关联购买金额 | | | | |
| co_pay_order_cnt | bigint | 关联购买订单数 | | | | |
| co_pay_qty | bigint | 关联购买商品数量 | | | | |
| co_net_pay_amt | decimal(19, 5) | 关联net购买金额 | | | | |
| co_net_pay_order_cnt | bigint | 关联net购买订单数 | | | | |
| co_net_pay_qty | bigint | 关联net购买商品数量 | | | | |
| co_return_amt | decimal(19, 5) | 关联退款金额 | | | | |
| co_return_order_cnt | bigint | 关联退款订单数 | | | | |
| co_return_qty | bigint | 关联退款商品数量 | | | | |
| co_cancel_amt | decimal(19, 5) | 关联取消金额 | | | | |
| co_cancel_order_cnt | bigint | 关联取消订单数 | | | | |
| co_cancel_qty | bigint | 关联取消商品数量 | | | | |
