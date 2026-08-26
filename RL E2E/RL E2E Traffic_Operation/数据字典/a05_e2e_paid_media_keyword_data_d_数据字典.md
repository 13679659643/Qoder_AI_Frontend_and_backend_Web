# a05_e2e_paid_media_keyword_data_d 数据字典

## 表基本信息

| 属性 | 值 |
|------|-----|
| 表名 | a05_e2e_paid_media_keyword_data_d |
| 表注释 | 流量数据关键词粒度表 |
| 是否分区表 | 是 |
| 备注 | DCom Performance Media Operation Dashboard看板Keyword模块取值表 |

## 字段明细

| 字段名 | 字段类型 | 字段注释 | 是否主键 | 字段说明 | 值示例 | 备注 |
|--------|----------|----------|----------|----------|--------|------|
| etl_time | String | 数据更新时间 |  |  | 2023/12/31 23:59:59 |  |
| dt | String | 分区字段，数据快照日期 | 是 |  | 2024/3/15 |  |
| data_type | String | 数据类型 | 是 |  | day |  |
| data_date | String | 数据日期 | 是 |  | 2024-03-15 |  |
| data_week | String | 数据周 |  |  |  |  |
| data_week_name | String | 数据周名称 |  |  |  |  |
| data_month | String | 数据月份 |  |  |  |  |
| data_month_name | String | 数据月份名称 |  |  |  |  |
| data_quarter | String | 数据季度 |  |  |  |  |
| data_quarter_name | String | 数据季度名称 |  |  |  |  |
| data_year | String | 数据年份 |  |  |  |  |
| data_year_name | String | 数据年份名称 |  |  |  |  |
| platform | String | 平台 | 是 |  |  |  |
| shop_info_id | bigint | 店铺唯一键 | 是 |  |  |  |
| TM: shop_info_id; JD: shop_info_id |  | shop_info_id | TRUE |  |  |  |
| shop_id | String | 店铺ID |  |  |  |  |
| TM: shop_id; JD: 无 |  | shop_id | TRUE |  |  |  |
| shop_name | String | 店铺名称cn |  |  |  |  |
| stroe_name | String | 店铺名称 |  |  |  |  |
| shop_code | String | 店铺code |  |  |  |  |
| channel | String | 广告点位 | 是 |  | 关键词推广,把人群推广（引力魔方），全站推，万相台，放进来 |  |
| 4.t08_traffic_channel_detail_d（channel_type=RTB)RTB作为一个channel，同步过来一个汇总数据 | 都是channel |  | trans_cycle | FALSE |  |  |
| is_controllable_channel | String | 是否controllable广告点位 |  |  | 1是；0否 |  |
| JD可控(快车/触点)→1; 其他→0 |  | channel | FALSE |  |  |  |
| keyword_name | String | 关键词名称 | 是 |  | 马甲男春秋 |  |
| framework | String | framework | 是 |  |  |  |
| brand | String | 品牌名称 | 是 |  |  |  |
| label |  | framework | FALSE |  |  |  |
| gender | String | 性别 | 是 |  |  |  |
| season | String | season | 是 |  |  |  |
| category | String | category | 是 |  |  |  |
| plan_id | String | 计划id | 是 |  |  |  |
| plan_name | String | 计划名称 |  |  | 600件BSR_WM西装727591853444 |  |
| keyword_type | String | 词类型 | 是 |  | 关键词 |  |
| 2.t08_traffic_crowd_data_d | keyword_type |  |  |  |  |  |
| crowd_layer |  | pv | FALSE |  |  |  |
| trans_cycle | String | 转化周期 | 是 |  |  |  |
| currency | String | 币种 | 是 |  |  |  |
| pv | bigint | 展现量 |  |  |  |  |
| 3.t08_traffic_channel_detail_d   in（全站推,万相台） | impressions，imp_pv，imp_pv |  | presale_sales_amt | FALSE |  |  |
| click | bigint | 点击量 |  |  |  |  |
| 3.t08_traffic_channel_detail_d   in（全站推,万相台） | clicks，clicks，click |  | presale_sales_order_cnt | FALSE |  |  |
| cost_amt | decimal(19, 5) | 花费 |  |  |  |  |
| 3.t08_traffic_channel_detail_d   in（全站推,万相台） | cost，cost，cost |  | sales_amt | FALSE |  |  |
| presale_sales_amt | decimal(19, 5) | 预售成交金额 |  |  |  |  |
| presale_sales_order_cnt | bigint | 预售成交笔数 |  |  |  |  |
| media_sales_amt | decimal(19, 5) | 总成交金额(投放带来) |  |  |  |  |
| 3.t08_traffic_channel_detail_d   in（全站推,万相台） | deal_amt，deal_amt |  | plan_id | FALSE |  |  |
| media_sales_order_cnt | bigint | 总成交笔数(投放带来) |  |  |  |  |
| 3.t08_traffic_channel_detail_d（全站推，万相台） | deal_cnt，deal_cnt |  | plan_name | FALSE |  |  |
| add_cart_num | bigint | 总加购数 |  |  |  |  |
| 3.t08_traffic_channel_detail_d   in（全站推,万相台） | add_cart_cnt，add_cart_num |  | keyword_type | FALSE |  |  |
| customer_type | STRING | 新老客类型(New/Existing) |  |  |  |  |
