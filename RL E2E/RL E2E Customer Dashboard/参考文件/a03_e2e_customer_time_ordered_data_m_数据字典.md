# a03_e2e_customer_time_ordered_data_m 数据字典

## 表基本信息

| 属性 | 值 |
|------|-----|
| 表名 | a03_e2e_customer_time_ordered_data_m |
| 表注释 | 用户在当月及后12个月中购买前3单的数据汇总月表 |
| 是否分区表 | 是 |
| 备注 | DCom Customer Operation Dashboard看板customer页面Product Path模块取数表 |

## 字段明细

| 字段名 | 字段类型 | 字段注释 | 是否主键 | 字段说明 | 值示例 | 备注 |
|--------|----------|----------|----------|----------|--------|------|
| etl_time | String | etl时间 | | | | |
| dt | String | 数据月份 | 是 | | | |
| period | String | 周期（3M/6M/9M/12M） | 是 | | | |
| data_month | String | 数据月份 | | | | |
| data_month_name | String | 数据月份名称 | | | | |
| data_quarter | String | 数据季度 | | | | |
| data_quarter_name | String | 数据季度名称 | | | | |
| data_year | String | 数据年份 | | | | |
| data_year_name | String | 数据年份名称 | | | | |
| user_id | String | 用户id | 是 | | | |
| user_name | String | 用户名 | | | | |
| platform | String | 平台 | 是 | | | |
| register_date | String | 注册日期 | | | | |
| is_employee | int | 是否员工 | | 1:是；0:否 | | |
| is_member | int | 是否会员 | | 1:是；0:否 | | |
| customer_type | String | 用户类型 | | new/exists | | |
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
| payment_time_seq | int | 订单时间序列 | 是 | | | |
