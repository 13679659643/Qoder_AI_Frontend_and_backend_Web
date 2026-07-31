# a02_e2e_boss_fulfillment_request_data_d 数据字典

## 表基本信息

| 属性 | 值 |
|------|-----|
| 表名 | a02_e2e_boss_fulfillment_request_data_d |
| 表注释 | BOSS数据履约流转数据日表 |
| 是否分区表 | 是 |
| 备注 | BOSS Order Fulfillment Dashboard看板Order Processing Effificiency by Label模块取数表 |

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
| framework | String | framework | 是 | | | |
| gender | String | 性别 | 是 | | | |
| brand | String | 品牌 | 是 | | | |
| product_type | String | 产品类型 | 是 | | | |
| category_summary | String | 品类归纳 | 是 | | | |
| category | String | 品类 | 是 | | | |
| calc_type | String | 指标计算方式 | 是 | | payment；fulfillment | |
| fulfillment_calc_type | String | 履约计算方式 | 是 | | 1:Exclude orders cancelled in pay date<br>2:Exclude orders cancelled in paydate & EC-fulfilled from O2O unfulfilled | |
| currency | String | 币种 | 是 | | | |
| o2o_fulfillment_request_failed_times | bigint | o2o履约流转失败次数 | | | | |
| o2o_fulfillment_request_times | bigint | o2o履约流转次数 | | | | |
| o2o_fulfillment_request_duration | double | o2o履约流转时长 | | | | |
| o2o_fulfillment_request_sku_qty | bigint | o2o履约order+sku去重数 | | | | |
