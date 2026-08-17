# t05_customer_order_data_d 数据字典

## 表基本信息

| 属性 | 值 |
|------|-----|
| 表名 | t05_customer_order_data_d |
| 表注释 | 会员订单数据模型表 |
| 是否分区表 | 是 |
| 备注 | |

## 字段明细

| 字段名 | 字段类型 | 字段注释 | 是否主键 | 字段说明 | 值示例 | 备注 |
|--------|----------|----------|----------|----------|--------|------|
| etl_time | String | etl时间 | | | | |
| dt | String | 数据日期 | 是 | | | |
| user_id | String | 用户id | 是 | | | |
| user_name | String | 用户名 | | | | |
| platform | String | 平台 | 是 | | | |
| shop_info_id | bigint | 店铺唯一键 | 是 | | | |
| shop_id | String | 店铺ID | | | | |
| shop_name | String | 店铺名称 | | | | |
| shop_code | String | 店铺code | | | | |
| product_id | String | 商品推广主体ID | 是 | | | |
| product_name | String | 商品推广主体名称 | | | | |
| framework | String | framework | | | | |
| brand | String | 品牌名称 | | | | |
| gender | String | 性别 | | | | |
| season | String | season | | | | |
| category | String | category | | | | |
| category_summary | String | 品类归纳 | | | | |
| is_member | int | 是否会员 | | | | |
| register_time | String | 会员注册日期 | | | | |
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
