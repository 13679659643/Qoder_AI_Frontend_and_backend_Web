# a02_e2e_boss_fulfillment_fail_reason_d 数据字典

## 表基本信息

| 属性       | 值                                                                      |
| ---------- | ----------------------------------------------------------------------- |
| 表名       | a02_e2e_boss_fulfillment_fail_reason_d                                  |
| 表注释     | O2O订单履约失败原因明细表                                               |
| 是否分区表 | 是                                                                      |
| 备注       | BOSS Order Fulfillment Dashboard看板 Failed Request by Reason模块取数表 |

## 字段明细

| 字段名                | 字段类型       | 字段注释        | 是否主键 | 字段说明 | 值示例                                                                                                                  | 备注 |
| --------------------- | -------------- | --------------- | -------- | -------- | ----------------------------------------------------------------------------------------------------------------------- | ---- |
| etl_time              | String         | 数据更新时间    |          |          |                                                                                                                         |      |
| dt                    | String         | 日期            | 是       |          |                                                                                                                         |      |
| data_type             | String         | 数据类型        | 是       |          | day                                                                                                                     |      |
| data_date             | String         | 数据日期        | 是       |          | 2024-03-15                                                                                                              |      |
| data_week             | String         | 数据周          |          |          | 30                                                                                                                      |      |
| data_week_name        | String         | 数据周名称      |          |          | FW202630                                                                                                                |      |
| data_month            | String         | 数据月份        |          |          | 07_Oct                                                                                                                  |      |
| data_month_name       | String         | 数据月份名称    |          |          | 2026财年7月                                                                                                             |      |
| data_quarter          | String         | 数据季度        |          |          | 3                                                                                                                       |      |
| data_quarter_name     | String         | 数据季度名称    |          |          | 2026财年第三季度                                                                                                        |      |
| data_year             | String         | 数据年份        |          |          | 2026                                                                                                                    |      |
| data_year_name        | String         | 数据年份名称    |          |          | 2026财年                                                                                                                |      |
| fulfillment_calc_type | String         | 履约计算方式    | 是       |          | 1:Exclude orders cancelled in pay date`<br>`2:Exclude orders cancelled in paydate & EC-fulfilled from O2O unfulfilled |      |
| store_code            | String         | 门店code        | 是       |          | JDRALPHL                                                                                                                |      |
| store_type            | String         | 门店类型        |          |          | POLO W                                                                                                                  |      |
| store_region          | String         | 门店所属区域    |          |          | WEST/EAST等                                                                                                             |      |
| failure_reason        | String         | 配货失败原因    | 是       |          |                                                                                                                         |      |
| currency              | String         | 币种            | 是       |          |                                                                                                                         |      |
| sales_amt             | decimal(19, 5) | o2o订单金额     |          |          |                                                                                                                         |      |
| sales_order_cnt       | bigint         | o2o订单量       |          |          |                                                                                                                         |      |
| sales_qty             | bigint         | o2o订单件数     |          |          |                                                                                                                         |      |
| request_times         | bigint         | o2o履约流转次数 |          |          |                                                                                                                         |      |
