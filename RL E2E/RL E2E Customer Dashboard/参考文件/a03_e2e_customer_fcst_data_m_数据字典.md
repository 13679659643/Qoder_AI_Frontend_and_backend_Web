# a03_e2e_customer_fcst_data_m 数据字典

## 表基本信息

| 属性 | 值 |
|------|-----|
| 表名 | a03_e2e_customer_fcst_data_m |
| 表注释 | 会员target数据月表 |
| 是否分区表 | 是 |
| 备注 | |

## 字段明细

| 字段名 | 字段类型 | 字段注释 | 是否主键 | 字段说明 | 值示例 | 备注 |
|--------|----------|----------|----------|----------|--------|------|
| etl_time | String | etl时间 | | | | |
| dt | String | 数据日期(财月) | 是 | | | |
| data_date | String | 数据日期(财月第一天) | | | | |
| data_month | String | 数据月份 | | | | |
| data_month_name | String | 数据月份名称 | | | | |
| data_quarter | String | 数据季度 | | | | |
| data_quarter_name | String | 数据季度名称 | | | | |
| data_year | String | 数据年份 | | | | |
| data_year_name | String | 数据年份名称 | | | | |
| platform | String | 平台 | 是 | | | |
| shop_info_id | bigint | 店铺唯一键 | 是 | | | |
| shop_id | String | 店铺ID | | | | |
| shop_name | String | 店铺名称 | | | | |
| shop_name_en | String | 店铺英文名称 | | | | |
| shop_code | String | 店铺code | | | | |
| new_customer_cnt | bigint | 新客户数 | | | | |
| customer_cnt | bigint | 客户数 | | | | |
| new_customer_percent | double | 新客占比 | | | | |
| vic_customer_cnt | bigint | vic客户数 | | | | |
| vic_retention_percent | double | vic留存占比 | | | | |
| upgrade_customer_cnt | bigint | T4-5升级客户数 | | | | |
| year_new_customer_cnt | bigint | 年度新客户数 | | | | |
| year_customer_cnt | bigint | 年度客户数 | | | | |
| year_new_customer_percent | double | 年度新客占比 | | | | |
| year_vic_customer_cnt | bigint | 年度vic客户数 | | | | |
| year_vic_retention_percent | double | 年度vic留存占比 | | | | |
| year_upgrade_customer_cnt | bigint | 年度T4-5升级客户数 | | | | |
