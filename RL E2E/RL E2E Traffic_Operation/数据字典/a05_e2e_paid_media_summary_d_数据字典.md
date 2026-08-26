# a05_e2e_paid_media_summary_d 数据字典

## 表基本信息

| 属性 | 值 |
|------|-----|
| 表名 | a05_e2e_paid_media_summary_d |
| 表注释 | 流量数据聚合表 |
| 是否分区表 | 是 |
| 备注 | DCom Performance Media Dashboard看板取数表，不包括到人群和计划粒度的表格 |

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
| page_type | String | 页面类型：1和2 | 是 |  |  |  |
| shop_info_id | bigint | 店铺唯一键 | 是 |  |  |  |
| shop_id | String | 店铺ID |  |  |  |  |
| shop_name | String | 店铺名称cn |  |  |  |  |
| store_name | String | 店铺名称 |  |  |  |  |
| shop_code | String | 店铺code |  |  |  |  |
| framework | String | framework | 是 |  |  |  |
| brand | String | 品牌名称 | 是 |  |  |  |
| season | String | season | 是 |  |  |  |
| category | String | category | 是 |  |  |  |
| division | String | 性别 | 是 |  |  |  |
| channel | String | 广告点位 | 是 |  |  |  |
| channel_type | String | 广告点位类型 |  |  | RTB/JCGP等 |  |
| is_controllable_channel | String | 是否controllable广告点位 | 是 |  | 1是；0否 |  |
| customer_type | String | 会员类型 | 是 |  | all/new/existing |  |
| t08_traffic_keyword_detail_d | 通过计算新客，手动定义new/人群/关键词的新老客标签 |  |  |  |  |  |
| trans_cycle | String | 转化周期 | 是 |  |  |  |
| t08_traffic_keyword_detail_d | trans_cycle |  |  |  |  |  |
| currency | String | 币种 | 是 |  |  |  |
| member_cnt | bigint | 会员人数 |  | 全店，customer_type in('all', 'new')时才会有值 | 1000 | 只有customer_type维度，维度到平台，店铺 |
| sales_amt | decimal(19, 5) | 销售金额 |  |  | 1000.00000 | Demand Sales，日粒度，维度到平台、店铺 |
| sales_order_cnt | bigint | 销售订单数 |  |  | 1000 |  |
| sales_qty | bigint | 销售件数 |  |  | 1000 |  |
| net_sales_amt | decimal(19, 5) | net销售额 |  |  | 1000.00000 | net sales,维度到平台，店铺，.dim_t00_sku_info的framework，label（brand)，category，season等，日期用支付时间 |
| net_sales_order_cnt | bigint | net销售订单数 |  |  | 1000 |  |
| net_sales_qty | bigint | net销售数量 |  |  | 1000 |  |
| cost_amt | decimal(19, 5) | 花费金额 |  |  | 1000 | 维度到平台，店铺，channel，customer_type，framework，label（brand)，division，season等 |
| t08_traffic_keyword_detail_d | 1.各投放点位花费加总 |  |  |  |  |  |
| adj_cost_amt | decimal(19, 5) | 调整花费金额 |  | JD平台需要通过系数调整cost | 1000.00000 |  |
| red_packet | decimal(19, 5) | 红包 |  |  |  | JD（限制type=红包），TM有两部分JCGP和RTB，关联条件：shop_info_id和日期作为关联条件。 |
| JD红包表indep_rl_db.dws_s01_consumer_fin_expense_rec_jzt_d | TM：1.JCGP结案后的表 |  |  |  |  |  |
| rebate | decimal(19, 5) | 返佣/返货金 |  |  |  | 只有JD有，type=返佣返货金，关联条件：shop_info_id和日期作为关联条件。 |
| media_sales_amt | decimal(19, 5) | 媒体成交金额 |  | customer_type in('all', 'new')时才会有值 |  |  |
| 4.t08_traffic_keyword_detail_d | 1.total_deal_amt |  |  |  |  |  |
| media_member_cnt | bigint | 媒体人数 |  | customer_type in('all', 'new')时才会有值 | 1000 | 维度到平台，到店铺，且时间最细到月度，其次季度，年，季度和年用月度加总 |
| media_net_sales_amt | decimal(19, 5) | 媒体net销售额 |  | customer_type in('all', 'new')时才会有值 | 1000.00000 | 维度到平台，到店铺，且时间最细到月度，其次季度，年，季度和年用月度加总 |
| media_cost_amt | decimal(19, 5) | 媒体花费 |  | customer_type in('all', 'new')时才会有值 |  | 维度到平台，到店铺，且时间最细到月度，其次季度，年，季度和年用月度加总 |
