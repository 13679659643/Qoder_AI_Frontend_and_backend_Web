# a02_e2e_boss_performance_summary_d 数据字典

## 表基本信息

| 属性 | 值 |
|------|-----|
| 表名 | a02_e2e_boss_performance_summary_d |
| 表注释 | BOSS数据汇总表 |
| 是否分区表 | 是 |
| 备注 | BOSS Order Fulfillment Dashboard看板取数表（不包含Unfulfilled Order by Region、Unfulfilled Order by Store Type、Failed Request by Reason模块） |

## 字段明细

| 字段名 | 字段类型 | 字段注释 | 是否主键 | 字段说明 | 值示例 | 备注 |
|--------|----------|----------|----------|----------|--------|------|
| etl_time | String | 数据更新时间 | | | 2023/12/31 23:59:59 | |
| dt | String | 分区字段，数据快照日期 | 是 | | 2024/3/15 | |
| data_type | String | 数据类型 | 是 | | day | |
| data_date | String | 数据日期 | 是 | | 2024-03-15 | |
| data_week | String | 数据周 | | | 30 | |
| data_week_name | String | 数据周名称 | | | FW202630 | |
| data_month | String | 数据月份 | | | 07_Oct | |
| data_month_name | String | 数据月份名称 | | | 2026财年7月 | |
| data_quarter | String | 数据季度 | | | 3 | |
| data_quarter_name | String | 数据季度名称 | | | 2026财年第三季度 | |
| data_year | String | 数据年份 | | | 2026 | |
| data_year_name | String | 数据年份名称 | | | 2026财年 | |
| platform | String | 平台 | 是 | | JD | |
| shop_info_id | bigint | 店铺唯一键 | 是 | | 100110848 | |
| shop_id | String | 店铺ID | | | 10848 | |
| shop_name | String | 店铺名称 | | | Polo Ralph Lauren京东旗舰店 | |
| shop_code | String | 店铺code | | | JDRALPHL | |
| store_code | String | 门店code | 是 | | | |
| store_name | String | 门店名字 | | | | |
| store_type | String | 店铺类型 | 是 | | POLO W | |
| store_region | String | 店铺所属区域 | 是 | | WEST/EAST等 | |
| framework | String | framework | 是 | | | |
| gender | String | 性别 | 是 | | | |
| brand | String | 品牌 | 是 | | | |
| product_type | String | 产品类型 | 是 | | | |
| category_summary | String | 品类归纳 | 是 | | | |
| category | String | 品类 | 是 | | | |
| calc_type | String | 指标计算方式 | 是 | | payment；fulfillment | |
| fulfillment_calc_type | String | 履约计算方式 | 是 | | 1:Exclude orders cancelled in pay date<br>2:Exclude orders cancelled in paydate & EC-fulfilled from O2O unfulfilled | |
| currency | String | 币种 | 是 | | | |
| sales_amt | decimal(19, 5) | 销售金额 | | | | |
| sales_order_cnt | bigint | 销售订单数 | | | | |
| sales_qty | bigint | 销售件数 | | | | |
| net_sales_amt | decimal(19, 5) | net销售额 | | | | |
| net_sales_order_cnt | bigint | net销售订单数 | | | | |
| net_sales_qty | bigint | net销售数量 | | | | |
| o2o_sales_amt | decimal(19, 5) | o2o销售金额 | | | | |
| o2o_sales_order_cnt | bigint | o2o销售订单数 | | | | |
| o2o_sales_qty | bigint | o2o销售件数 | | | | |
| o2o_net_sales_amt | decimal(19, 5) | o2o net销售额 | | | | |
| o2o_net_sales_order_cnt | bigint | o2onet销售订单数 | | | | |
| o2o_net_sales_qty | bigint | o2onet销售数量 | | | | |
| return_amt | decimal(19, 5) | 退货金额 | | | | |
| return_order_cnt | bigint | 退货订单数 | | | | |
| return_qty | bigint | 退货件数 | | | | |
| o2o_return_amt | decimal(19, 5) | o2o退货金额 | | | | |
| o2o_return_order_cnt | bigint | o2o退货订单数 | | | | |
| o2o_return_qty | bigint | o2o退货件数 | | | | |
| cancel_amt | decimal(19, 5) | 取消金额 | | | | |
| cancel_order_cnt | bigint | 取消订单数 | | | | |
| cancel_qty | bigint | 取消件数 | | | | |
| o2o_cancel_amt | decimal(19, 5) | o2o取消金额 | | | | |
| o2o_cancel_order_cnt | bigint | o2o取消订单数 | | | | |
| o2o_cancel_qty | bigint | o2o取消件数 | | | | |
| o2o_fulfillment_request_sales_amt | decimal(19, 5) | o2o履约销售订单金额 | | | | |
| o2o_fulfillment_request_order_cnt | bigint | o2o履约销售订单量 | | | | |
| o2o_fulfillment_request_qty | bigint | o2o履约销售件数 | | | | |
| o2o_fulfillment_shipped_sales_amt | decimal(19, 5) | o2o履约发货订单金额 | | | | |
| o2o_fulfillment_shipped_order_cnt | bigint | o2o履约发货订单量 | | | | |
| o2o_fulfillment_shipped_qty | bigint | o2o履约发货件数 | | | | |
| o2o_fulfillment_unshipped_sales_amt | decimal(19, 5) | o2o履约未发货订单金额 | | | | |
| o2o_fulfillment_unshipped_order_cnt | bigint | o2o履约未发货订单量 | | | | |
| o2o_fulfillment_unshipped_qty | bigint | o2o履约未发货件数 | | | | |
| o2o_fulfillment_unshipped_store_rejected_sales_amt | decimal(19, 5) | o2o履约未发货门店拒单订单金额 | | | | |
| o2o_fulfillment_unshipped_store_rejected_order_cnt | bigint | o2o履约未发货门店拒单订单量 | | | | |
| o2o_fulfillment_unshipped_store_rejected_qty | bigint | o2o履约未发货门店拒单件数 | | | | |
| o2o_fulfillment_unshipped_overdue_sales_amt | decimal(19, 5) | o2o履约未发货超时订单金额 | | | | |
| o2o_fulfillment_unshipped_overdue_order_cnt | bigint | o2o履约未发货超时订单量 | | | | |
| o2o_fulfillment_unshipped_overdue_qty | bigint | o2o履约未发货超时件数 | | | | |
| o2o_fulfillment_unshipped_customer_cancelled_sales_amt | decimal(19, 5) | o2o履约未发货用户取消订单金额 | | | | |
| o2o_fulfillment_unshipped_customer_cancelled_order_cnt | bigint | o2o履约未发货用户取消订单量 | | | | |
| o2o_fulfillment_unshipped_customer_cancelled_qty | bigint | o2o履约未发货用户取消件数 | | | | |
| o2o_fulfillment_unshipped_others_sales_amt | decimal(19, 5) | o2o履约未发货其他原因订单金额 | | | | |
| o2o_fulfillment_unshipped_others_order_cnt | bigint | o2o履约未发货其他原因订单量 | | | | |
| o2o_fulfillment_unshipped_others_qty | bigint | o2o履约未发货其他原因件数 | | | | |
| o2o_penalty_oos_amt | decimal(19, 5) | o2o赔付oos赔付金额 | | | | |
| o2o_penalty_oos_order_cnt | bigint | o2o赔付oos赔付订单数 | | | | |
| o2o_penalty_delay_amt | decimal(19, 5) | o2o赔付delay赔付金额 | | | | |
| o2o_penalty_delay_order_cnt | bigint | o2o赔付delay赔付订单数 | | | | |
| stock_amt | decimal(19, 5) | 库存金额 | | | | |
| stock_qty | bigint | 库存商品数量 | | | | |
| bsr_stock_amt | decimal(19, 5) | BSR库存金额 | | | | |
| bsr_stock_qty | bigint | BSR库存商品数量 | | | | |
| seasonal_stock_amt | decimal(19, 5) | Seasonal库存金额 | | | | |
| seasonal_stock_qty | bigint | Seasonal库存商品数量 | | | | |
