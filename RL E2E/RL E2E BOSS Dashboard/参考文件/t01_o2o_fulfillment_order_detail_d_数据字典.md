# t01_o2o_fulfillment_order_detail_d 数据字典

## 表基本信息

| 属性 | 值 |
|------|-----|
| 表名 | t01_o2o_fulfillment_order_detail_d |
| 表注释 | O2O履约订单明细表 |
| 是否分区表 | 是 |
| 备注 | O2O订单的履约流转明细，基于indep_rl_view.v_hive_ads_o2o_daily_report，订单明细级别 |

## 字段明细

| 字段名 | 字段类型 | 字段注释 | 是否主键 | 字段说明 | 值示例 | 备注 |
|--------|----------|----------|----------|----------|--------|------|
| etl_time | String | 数据更新时间 | | | | |
| dt | String | shopdog生成日期 | 是 | create_time到日期的值 | | |
| order_type_cd | String | 订单类型代码 | 是 | | | |
| code | String | 宝尊订单号 | 是 | | | |
| order_code | String | 平台订单号 | 是 | | | |
| shop_info_id | bigint | 店铺唯一键 | 是 | | | |
| shop_id | String | 店铺ID | | | | |
| shop_name | String | 店铺名称 | | | | |
| shop_code | String | 店铺code | | | | |
| channel_name | String | 渠道名称 | | | | |
| store_name | String | 门店名称 | | | | |
| store_code | String | 门店编码 | 是 | | | |
| province | String | 门店所在省份 | | | | |
| city | String | 门店所在城市 | | | | |
| payment_time | String | 订单付款时间 | | | | |
| order_type | String | 订单类型 | 是 | | | |
| order_status | String | 订单状态 | | | | |
| deli_order_store_id | bigint | 门店接单id | 是 | | | |
| refund_id | bigint | 退款订单行id | 是 | | | |
| exchange_id | bigint | 换货行id | 是 | | | |
| store_order_id | bigint | 门店下单行id | 是 | | | |
| push_no | String | 推送标识:0.代表最近推送的一批 | | | | |
| come_times | String | 订单过仓驻店宝次数 | | | | |
| push_time | String | 推送时间 | | | | |
| expired_time | String | 过期时间 | | | | |
| create_time | String | shopdog生成时间 | | | | |
| distribute_finish_time | String | 配货完成时间 | | | | |
| pick_status | String | 接单状态 | | | | |
| distribution_status | String | 配货状态 | | | | |
| failure_remark | String | 配货失败标记 | | | | |
| failure_detail | String | 配货失败原因 | | | | |
| package_status | String | 包裹状态 | | | | |
| destination_province | String | 目的地省份 | | | | |
| exchange_type | String | 换货类型 | 是 | | | |
| sku_code | String | sku_code | 是 | | | |
| ext_code2 | String | 商品（修改项） | | | | |
| unit_price | decimal(19, 5) | 商品总金额 | | | | |
| quantity | int | 商品总数 | | | | |
| login_name | String | operator | | | | |
