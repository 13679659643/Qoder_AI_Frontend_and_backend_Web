# a05_e2e_paid_media_channel_data_d 数据字典

## 表基本信息

| 属性 | 值 |
|------|-----|
| 表名 | a05_e2e_paid_media_channel_data_d |
| 表注释 | 流量数据渠道粒度表 |
| 是否分区表 | 是 |
| 备注 | DCom Performance Media Operation Dashboard看板 Media Mix取数表 |

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
| shop_id | String | 店铺ID |  |  |  |  |
| 关联店铺维表获取 |  | shop_id | TRUE |  |  |  |
| shop_name | String | 店铺名称 |  |  |  |  |
| shop_code | String | 店铺code |  |  |  |  |
| 关联店铺维表获取 |  | shop_code | TRUE |  |  |  |
| channel | String | 广告点位 | 是 |  |  | TM需要把关键词推广处理成直通车；人群推广处理成引力魔方 |
| channel_type | String | 广告点位类型 |  |  | RTB/JCGP等 | 根据去重的channel关联，注意，channel的JCGP有重复值（6.24上传的新表，所以6.25库里才会有此表），且需要把channel的“关键词推广处理成直通车；人群推广处理成引力魔方”，才能批到RTB全部数据 |
| is_controllable_channel | String | 是否controllable广告点位 | 是 |  | 1是；0否 | 根据最新（26.6.24逻辑）可用bbi_upload_channel_type_RTB_JCGP表中的channel字段匹配is_controllable_channel来判断是否是可控渠道，这样后续变更类型，不用改代码 |
| JD不可控: 海投/京选/直投/搜索品专 → 0 |  | channel_type | FALSE |  |  |  |
| trans_cycle | String | 转化周期 | 是 |  |  |  |
| currency | String | 币种 | 是 |  |  |  |
| USD按固定汇率7.25折算 |  | currency | TRUE |  |  |  |
| cost_amt | decimal(19, 5) | 花费 |  |  |  |  |
| pv | bigint | 展现 |  |  |  |  |
| click | bigint | 点击 |  |  |  |  |
| media_sales_amt | decimal(19, 5) | 总成交金额 |  |  |  |  |
| media_sales_order_cnt | bigint | 总成交笔数 |  |  |  |  |
| add_cart_cnt | bigint | 加购 |  |  |  |  |
| collection_cnt | bigint | 收藏 |  |  |  |  |
| product_follows | bigint | 商品关注数 |  |  |  |  |
| TM/DY/RL.CN: 无此指标 |  | origin_media_sales_amt | FALSE |  |  |  |
| sales_user_cnt | bigint | 成交人数 |  |  |  |  |
| new_sales_user_cnt | bigint | 成交新客数 |  |  |  |  |
| new_member_user_cnt | bigint | 入会量 |  |  |  |  |
| member_sales_order_cnt | bigint | 会员成交笔数 |  |  |  |  |
| member_sales_amt | bigint | 会员成交金额 |  |  |  |  |
| first_sales_user_cnt | bigint | 会员首购人数 |  |  |  |  |
| origin_media_sales_amt | decimal(19, 5) | 剔除前的总成交金额 |  |  |  |  |
| origin_media_sales_order_cnt | bigint | 剔除前的总成交笔数 |  |  |  |  |
| origin_add_cart_cnt | bigint | 剔除前的加购 |  |  |  |  |
| origin_collection_cnt | bigint | 剔除前的收藏 |  |  |  |  |
| RL.CN: 无 |  | origin_new_member_cnt | FALSE |  |  |  |
| origin_sales_user_cnt | bigint | 剔除前的成交人数 |  |  |  |  |
| origin_new_sales_user_cnt | bigint | 剔除前的成交新客数 |  |  |  |  |
| origin_new_member_cnt | bigint | 剔除前的入会量 |  |  |  |  |
| origin_member_sales_order_cnt | bigint | 剔除前的会员成交笔数 |  |  |  |  |
| origin_member_sales_amt | bigint | 剔除前的会员成交金额 |  |  |  |  |
| origin_first_sales_member_cnt | bigint | 剔除前的会员首购人数 |  |  |  |  |
| exclude_rate | double | 剔除比例 |  |  |  |  |
