# a03_e2e_customer_data_m 数据字典

## 表基本信息

| 属性 | 值 |
|------|-----|
| 表名 | a03_e2e_customer_data_m |
| 表注释 | 会员数据汇总月表 |
| 是否分区表 | 是 |
| 备注 | DCom Customer Operation Dashboard看板取数表（除Co Purchase Matrix、Product Path外） |

## 字段明细

| 字段名 | 字段类型 | 字段注释 | 是否主键 | 字段说明 | 值示例 | 备注 |
|--------|----------|----------|----------|----------|--------|------|
| etl_time | String | etl时间 | | | | |
| dt | String | 数据日期 | 是 | | | |
| data_date | String | 数据月份(财月第一天) | | | | |
| data_month | String | 数据月份 | | | 07_Oct | |
| data_month_name | String | 数据月份名称 | | | 2026财年7月 | |
| data_quarter | String | 数据季度 | | | 3 | |
| data_quarter_name | String | 数据季度名称 | | | 2026财年第三季度 | |
| data_year | String | 数据年份 | | | 2026 | |
| data_year_name | String | 数据年份名称 | | | 2026财年 | |
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
| shop_name_en | String | 店铺英文名称 | | | | |
| shop_code | String | 店铺code | | | | |
| pay_amt | decimal(19, 5) | 购买金额 | | demand sales | | |
| pay_order_cnt | bigint | 购买订单数 | | demand sales | | |
| pay_qty | bigint | 购买商品数量 | | demand sales | | |
| net_pay_amt | decimal(19, 5) | net购买金额 | | | | |
| net_pay_order_cnt | bigint | net购买订单数 | | | | |
| net_pay_qty | bigint | net购买商品数量 | | | | |
| last_12m_net_pay_amt | decimal(19, 5) | 过去12个月net购买金额 | | | | |
| last_12m_net_pay_order_cnt | bigint | 过去12个月net购买订单数 | | | | |
| last_12m_net_pay_qty | bigint | 过去12个月net购买商品数量 | | | | |
| last_period_customer_tier | String | 上个周期vic等级 | | T1～T5 | | |
| is_last_period_vic | int | 是否是上个周期vic | | 1:是；0:否 | | |
| last_24m_12m_net_pay_amt | decimal(19, 5) | 过去24~12个月net购买金额 | | | | |
| last_24m_12m_net_pay_order_cnt | bigint | 过去24~12个月net购买订单数 | | | | |
| last_24m_12m_net_pay_qty | bigint | 过去24~12个月net购买商品数量 | | | | |
| is_vic | int | 是否是vic | | 1:是；0:否 | | |
| customer_tier | String | 用户等级 | | T1～T5 | | |
| is_new_vic | int | 是否是new vic | | 1:是；0:否 | | |
| is_direct_vic | int | 是否是direct vic | | 1:是；0:否 | | |
| is_upgrade_vic | int | 是否是upgrade vic | | 1:是；0:否 | | |
| is_retention_vic | int | 是否是retention vic | | 1:是；0:否 | | |
| lp_12m_pay_amt | decimal(19, 5) | 前12个月购买金额 | | 不包括当月 | | |
| lp_12m_pay_order_cnt | bigint | 前12个月购买订单数 | | 不包括当月 | | |
| lp_12m_pay_qty | bigint | 前12个月购买商品数量 | | 不包括当月 | | |
| lp_12m_net_pay_amt | decimal(19, 5) | 前12个月net购买金额 | | 不包括当月 | | |
| lp_12m_net_pay_order_cnt | bigint | 前12个月net购买订单数 | | 不包括当月 | | |
| lp_12m_net_pay_qty | bigint | 前12个月net购买商品数量 | | 不包括当月 | | |
| last_fy_net_pay_amt | decimal(19, 5) | 上个财年net购买金额 | | | | |
| last_fy_net_pay_order_cnt | bigint | 上个财年net购买订单数 | | | | |
| last_fy_net_pay_qty | bigint | 上个财年net购买商品数量 | | | | |
| last_fy_last_order_month | String | 上个财年最后购买月份 | | | | |
| last_fy_last_order_month_type | String | 上个财年最后购买月份分类 | | R3/R4-6/R7-9/R10-12 | | |
| is_fy_vic | int | 是否是上个财年vic | | 1:是；0:否 | | |
| is_fy_retention_vic | int | 是否是上个财年retention vic | | 1:是；0:否 | | |
