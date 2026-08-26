# a05_e2e_paid_media_crowed_data_d 数据字典

## 表基本信息

| 属性 | 值 |
|------|-----|
| 表名 | a05_e2e_paid_media_crowed_data_d |
| 表注释 | 流量数据人群粒度表 |
| 是否分区表 | 是 |
| 备注 | DCom Performance Media Operation Dashboard看板Crowd模块取数表 |

## 字段明细

| 字段名 | 字段类型 | 字段注释 | 是否主键 | 字段说明 | 值示例 | 备注 |
|--------|----------|----------|----------|----------|--------|------|
| etl_time | String | 数据更新时间 |  |  | 2023/12/31 23:59:59 |  |
| dt | String | 分区字段，数据快照日期 | 是 |  | 2024/3/15 |  |
| data_type | String | 数据类型 | 是 |  | day |  |
| data_date | String | 数据日期 | 是 |  | 2024-03-15 |  |
| data_week | String | 数据周 |  |  | 30 |  |
| data_week_name | String | 数据周名称 |  |  | FW202630 |  |
| data_month | String | 数据月份 |  |  | 07_Oct |  |
| data_month_name | String | 数据月份名称 |  |  | 2026财年7月 |  |
| data_quarter | String | 数据季度 |  |  | 3 |  |
| data_quarter_name | String | 数据季度名称 |  |  | 2026财年第三季度 |  |
| data_year | String | 数据年份 |  |  | 2026 |  |
| data_year_name | String | 数据年份名称 |  |  | 2026财年 |  |
| platform | String | 平台 | 是 |  | JD |  |
| 自定义: TM/JD |  | platform | TRUE |  |  |  |
| shop_info_id | bigint | 店铺唯一键 | 是 |  | 100110848 |  |
| TM: shop_info_id; JD: shop_info_id |  | shop_info_id | TRUE |  |  |  |
| shop_id | String | 店铺ID |  |  | 10848 |  |
| TM: shop_id; JD: 无 |  | shop_id | TRUE |  |  |  |
| shop_name | String | 店铺名称 |  |  | Polo Ralph Lauren京东旗舰店 |  |
| stroe_name | String | 店铺名称 |  |  |  |  |
| shop_code | String | 店铺code |  |  | JDRALPHL |  |
| channel | String | 广告点位 | 是 |  | 触点 |  |
| 4.t08_traffic_channel_detail_d（channel_type=RTB)RTB作为一个channel，同步过来一个汇总数据 | 都是channel |  | trans_cycle | FALSE |  |  |
| is_controllable_channel | String | 是否controllable广告点位 | 是 |  | 1是；0否 |  |
| JD可控(快车/触点)→1; 其他→0 |  | channel | FALSE |  |  |  |
| framework | String | framework | 是 |  |  |  |
| brand | String | 品牌名称 | 是 |  |  |  |
| gender | String | 性别 | 是 |  |  |  |
| season | String | season | 是 |  |  |  |
| category | String | category | 是 |  |  |  |
| crowed_type | String | 人群分类 | 是 |  | 行业人群_平台高价值人群 |  |
| crowed_name | String | 人群名称 | 是 |  | 【年货节】站内高潜_奢侈品 |  |
| crowed_layer | String | 人群分层 | 是 |  | OA1 |  |
| 2.t08_traffic_keyword_detail_d | crowd_layer，keyword_type |  | season | FALSE |  |  |
| trans_cycle | String | 转化周期 | 是 |  |  |  |
| currency | String | 币种 | 是 |  |  |  |
| pv | bigint | 展现量 |  |  |  |  |
| click | bigint | 点击量 |  |  | 1000 |  |
| cost_amt | decimal(19, 5) | 花费 |  |  | 1000.00000 |  |
| presale_sales_amt | decimal(19, 5) | 预售成交金额 |  |  | 1000.00000 |  |
| presale_sales_order_cnt | bigint | 预售成交笔数 |  |  | 1000 |  |
| media_sales_amt | decimal(19, 5) | 总成交金额(投放带来) |  |  | 1000.00000 |  |
| media_sales_order_cnt | bigint | 总成交笔数(投放带来) |  |  | 1000 |  |
| add_cart_num | bigint | 总加购数 |  |  | 1000 |  |
| customer_type |  |  |  |  |  |  |
