# a05_e2e_paid_media_fcst_data_m 数据字典

## 表基本信息

| 属性 | 值 |
|------|-----|
| 表名 | a05_e2e_paid_media_fcst_data_m |
| 表注释 | 流量target数据月表 |
| 是否分区表 | 是 |
| 备注 |  |

## 字段明细

| 字段名 | 字段类型 | 字段注释 | 是否主键 | 字段说明 | 值示例 | 备注 |
|--------|----------|----------|----------|----------|--------|------|
| etl_time | String | etl时间 |  |  | 2026/8/17 11:30 |  |
| dt | String | 数据日期(财月) | 是 |  | 2026-01 | 不保留上传历史；dt承载业务财月/分区值 |
| data_date | String | 数据日期(财月第一天) |  |  | 2026/3/29 | 对应财月第一天 |
| data_month | String | 数据月份 |  |  | 2026-01 | 与dt同值 |
| data_month_name | String | 数据月份名称 |  |  | 2027财年1月 | 财月显示名称 |
| data_quarter | String | 数据季度 |  |  | 1 | 财季编号 |
| data_quarter_name | String | 数据季度名称 |  |  | 2027财年第一季度 | 财季显示名称 |
| data_year | String | 数据年份 |  |  | 2027 | 财年编号 |
| data_year_name | String | 数据年份名称 |  |  | 2027财年 | 财年显示名称 |
| platform | String | 平台 | 是 |  | TM/JD/ALL | 原始Plan仅有TM/JD； |
| 需要物理生成ALL=TM+JD | indep_rl_view.bbi_upload_Traffic_plan | TM/JD取channel；另生成platform='ALL'行 |  | platform | TRUE | platform |
| shop_info_id | bigint | 店铺唯一键 | 是 |  |  | platform=ALL时为NULL |
| shop_id | String | 店铺ID |  |  |  | platform=ALL时为NULL |
| shop_name | String | 店铺名称 |  |  |  | platform=ALL时为NULL |
| shop_name_en | String | 店铺英文名称 |  |  | NULL | 预留字段 |
| TM、JD、ALL均为NULL。 | 固定值 | TM/JD/ALL：固定写入NULL |  | shop_name_en | TRUE | shop_name_en |
| shop_code | String | 店铺code |  |  |  | platform=ALL时为NULL |
| currency | String | 币种 | 是 |  | RMB | Traffic Plan当前按RMB承载 |
| cost_amt | decimal(19, 5) | 花费金额 |  | Performance Media Cost | 1963135 | TM、JD：对应财月、对应平台的Performance Media Cost； |
| ALL：对应财月TM、JD的合计值。 | indep_rl_view.bbi_upload_Traffic_plan | TM/JD：以TM为例，当 Date_M = 'FY27_01_Apr'、channel = 'TM'、KPI = 'Performance Media Cost' 时取 FCST |  |  |  |  |
| ALL：TM cost_amt ＋ JD cost_amt |  | cost_amt | TRUE | cost_amt | TRUE |  |
| rtb_cost_amt | decimal(19, 5) | RTB花费金额 |  | RTB Cost | 2298020 | TM、JD：对应财月、对应平台的RTB Cost； |
| ALL：对应财月TM、JD的合计值。 | indep_rl_view.bbi_upload_Traffic_plan | TM/JD：以TM为例，当 Date_M = 'FY27_01_Apr'、channel = 'TM'、KPI = 'RTB Cost' 时取 FCST |  |  |  |  |
| ALL：TM rtb_cost_amt ＋ JD rtb_cost_amt |  | rtb_cost_amt | TRUE | rtb_cost_amt | TRUE |  |
| media_cost_rate | double | 媒体花费占比 |  | Media Cost rate | 0.045 | TM、JD：对应财月、对应平台的Media Cost rate； |
| ALL：按对应财月汇总TM、JD的cost_amt和net_sales_amt后重算。 | indep_rl_view.bbi_upload_Traffic_plan | TM/JD：以TM为例，当 Date_M = 'FY27_01_Apr'、channel = 'TM'、KPI = 'Media Cost rate' 时取 FCST |  |  |  |  |
| ALL：(TM cost_amt ＋ JD cost_amt) ÷ (TM net_sales_amt ＋ JD net_sales_amt) × 1.13 ÷ 1.06 |  | media_cost_rate | TRUE | media_cost_rate | TRUE |  |
| media_cost_amt | decimal(19, 5) | 媒体花费金额 |  |  | NULL | 预留字段，当前不参与指标计算； |
| TM、JD、ALL均为NULL。 | 固定值 | TM/JD/ALL：固定写入NULL |  | media_cost_amt | TRUE | media_cost_amt |
| acceleration_cost_rate | double | acceleration花费占比 |  | Acceleration Cost% | 0.327 | TM、JD：对应财月、对应平台的Acceleration Cost%； |
| ALL：按对应财月汇总TM、JD的acceleration_cost_amt和cost_amt后重算。 | indep_rl_view.bbi_upload_Traffic_plan | TM/JD：以TM为例，当 Date_M = 'FY27_01_Apr'、channel = 'TM'、KPI = 'Acceleration Cost%' 时取 FCST |  |  |  |  |
| ALL：(TM acceleration_cost_amt ＋ JD acceleration_cost_amt) ÷ (TM cost_amt ＋ JD cost_amt) |  | acceleration_cost_rate | TRUE | acceleration_cost_rate | TRUE |  |
| acceleration_cost_amt | decimal(19, 5) | acceleration花费金额 |  | 花费金额 × acceleration花费占比 | 641945 | TM、JD：对应财月、对应平台的Acceleration Cost金额； |
| ALL：对应财月TM、JD的合计值。 | indep_rl_view.bbi_upload_Traffic_plan | TM/JD：cost_amt × acceleration_cost_rate |  |  |  |  |
| ALL：TM acceleration_cost_amt ＋ JD acceleration_cost_amt |  | acceleration_cost_amt | TRUE | acceleration_cost_amt | TRUE |  |
| acceleration_cost_rate_vs_net_sales_rate | double | acceleration花费占比vs销售占比 |  | ± Acceleration category cost MOB% vs Acceleration category SLS MOB% | 0.19 | TM、JD：对应财月、对应平台的Acceleration Cost%与Acceleration SLS MOB%差值； |
| 本字段 ＝ ALL acceleration_cost_rate － ALL acceleration_net_sales_rate。 | indep_rl_view.bbi_upload_Traffic_plan | TM/JD：以TM为例，当 Date_M = 'FY27_01_Apr'、channel = 'TM'、KPI = '± Acceleration category cost MOB% vs Acceleration category SLS MOB%' 时取 FCST |  |  |  |  |
| ALL：[(TM acceleration_cost_amt ＋ JD acceleration_cost_amt) ÷ (TM cost_amt ＋ JD cost_amt)] － [(TM acceleration_net_sales_amt ＋ JD acceleration_net_sales_amt) ÷ (TM net_sales_amt ＋ JD net_sales_amt)] |  | acceleration_cost_rate_vs_net_sales_rate | TRUE | acceleration_cost_rate_vs_net_sales_rate | TRUE |  |
| net_sales_amt | decimal(19, 5) | net销售金额 |  | SLS | 46887774 | TM、JD：对应财月、对应平台的SLS，按Net Sales使用； |
| ALL：对应财月TM、JD的合计值。 | indep_rl_view.bbi_upload_Traffic_plan | TM/JD：以TM为例，当 Date_M = 'FY27_01_Apr'、channel = 'TM'、KPI = 'SLS' 时取 FCST |  |  |  |  |
| ALL：TM net_sales_amt ＋ JD net_sales_amt |  | net_sales_amt | TRUE | net_sales_amt | TRUE |  |
| acceleration_net_sales_amt | decimal(19, 5) | acceleration net销售金额 |  | Acceleration category SLS | 7489657 | TM、JD：对应财月、对应平台的Acceleration category SLS； |
| ALL：对应财月TM、JD的合计值。 | indep_rl_view.bbi_upload_Traffic_plan | TM/JD：以TM为例，当 Date_M = 'FY27_01_Apr'、channel = 'TM'、KPI = 'Acceleration category SLS' 时取 FCST |  |  |  |  |
| ALL：TM acceleration_net_sales_amt ＋ JD acceleration_net_sales_amt |  | acceleration_net_sales_amt | TRUE | acceleration_net_sales_amt | TRUE |  |
| acceleration_net_sales_rate | double | acceleration net销售占比 |  | Acceleration SLS MOB% | 0.136 | TM、JD：对应财月、对应平台的Acceleration SLS MOB%； |
| ALL：ALL acceleration_net_sales_rate ＝ (TM acceleration_net_sales_amt ＋ JD acceleration_net_sales_amt) ÷ (TM net_sales_amt ＋ JD net_sales_amt)。 | indep_rl_view.bbi_upload_Traffic_plan | TM/JD：以TM为例，当 Date_M = 'FY27_01_Apr'、channel = 'TM'、KPI = 'Acceleration SLS MOB%' 时取 FCST |  |  |  |  |
| ALL：(TM acceleration_net_sales_amt ＋ JD acceleration_net_sales_amt) ÷ (TM net_sales_amt ＋ JD net_sales_amt) |  | acceleration_net_sales_rate | TRUE | acceleration_net_sales_rate | TRUE |  |
| sales_amt | decimal(19, 5) | demand 销售金额 |  | Demand Sales | 161905950 | TM、JD：对应财月、对应平台的Demand Sales； |
| ALL：对应财月TM、JD的合计值。 | indep_rl_view.bbi_upload_Traffic_plan | TM/JD：以TM为例，当 Date_M = 'FY27_01_Apr'、channel = 'TM'、KPI = 'Demand Sales' 时取 FCST |  |  |  |  |
| ALL：TM sales_amt ＋ JD sales_amt |  | sales_amt | TRUE | sales_amt | TRUE |  |
| new_customer_cnt | bigint | 新客人数 |  | new_customer_cnt | 14027 | TM、JD：对应财月、对应平台范围的Customer财月新客Target； |
| ALL：对应财月TM、JD的合计值。 | a03_e2e_customer_fcst_data_m | TM/JD：按dt、platform、shop_info_id、currency匹配a03_e2e_customer_fcst_data_m，取a03_e2e_customer_fcst_data_m.new_customer_cnt |  |  |  |  |
| ALL：TM new_customer_cnt ＋ JD new_customer_cnt |  | new_customer_cnt | TRUE | new_customer_cnt | TRUE |  |
| media_new_customer_contribution_rate | double | 媒体新客贡献率 |  | media contribution TO New customer acquisition % | 0.79 | TM、JD：对应财月、对应平台的媒体新客贡献率； |
| ALL：ALL media_new_customer_contribution_rate = (TM media_new_customer_cnt + JD media_new_customer_cnt) ÷ (TM new_customer_cnt + JD new_customer_cnt)。 | indep_rl_view.bbi_upload_Traffic_plan | TM/JD：以TM为例，当 Date_M = 'FY27_01_Apr'、channel = 'TM'、KPI = 'media contribution TO New customer acquisition %' 时取 FCST |  |  |  |  |
| ALL：(TM media_new_customer_cnt + JD media_new_customer_cnt) ÷ (TM new_customer_cnt + JD new_customer_cnt) |  | media_new_customer_contribution_rate | TRUE | media_new_customer_contribution_rate | TRUE |  |
| media_new_customer_cnt | bigint | 媒体新客人数 |  | 新客人数 × 媒体新客贡献率 | 11081 | TM、JD：对应财月、对应平台的媒体新客人数，按公式计算； |
| ALL：对应财月TM、JD的合计值。 | 本表计算 | TM/JD：new_customer_cnt × media_new_customer_contribution_rate |  |  |  |  |
| ALL：TM media_new_customer_cnt + JD media_new_customer_cnt |  | media_new_customer_cnt | TRUE | media_new_customer_cnt | TRUE |  |
| cost_per_new_acquisition | decimal(19, 5) | 新客获客成本 |  | Cost per new acquisition | 258 | TM、JD：对应财月、对应平台的新客获客成本； |
| ALL：ALL cost_per_new_acquisition ＝ (TM media_new_customer_cost_amt ＋ JD media_new_customer_cost_amt) ÷ (TM media_new_customer_cnt ＋ JD media_new_customer_cnt)。 | indep_rl_view.bbi_upload_Traffic_plan | TM/JD：以TM为例，当 Date_M = 'FY27_01_Apr'、channel = 'TM'、KPI = 'Cost per new acquisition' 时取 FCST |  |  |  |  |
| ALL：(TM media_new_customer_cost_amt ＋ JD media_new_customer_cost_amt) ÷ (TM media_new_customer_cnt ＋ JD media_new_customer_cnt) |  | cost_per_new_acquisition | TRUE | cost_per_new_acquisition | TRUE |  |
| media_new_customer_cost_amt | decimal(19, 5) | 媒体新客花费 |  | 媒体新客人数 × 新客获客成本 | 2858983.14 | TM、JD：对应财月、对应平台的媒体新客花费，按公式计算； |
| ALL：对应财月TM、JD的合计值。 | 本表计算 | TM/JD：media_new_customer_cnt × cost_per_new_acquisition |  |  |  |  |
| ALL：TM media_new_customer_cost_amt + JD media_new_customer_cost_amt |  | media_new_customer_cost_amt | TRUE | media_new_customer_cost_amt | TRUE |  |
| customer_cnt | bigint | 客户数 |  |  | NULL | 预留字段，当前不参与指标计算； |
| TM、JD、ALL均为NULL。 | 固定值 | TM/JD/ALL：固定写入NULL |  | customer_cnt | TRUE | customer_cnt |
| new_customer_percent | double | 新客占比 |  |  | NULL | 预留字段，当前不参与指标计算； |
| TM、JD、ALL均为NULL。 | 固定值 | TM/JD/ALL：固定写入NULL |  | new_customer_percent | TRUE | new_customer_percent |
| year_cost_amt | decimal(19, 5) | 花费金额 |  | Performance Media Cost | 65428828 | TM、JD：对应FY、对应平台的Performance Media Cost；同一FY的12个财月行重复保存，取单值、不跨月SUM。 |
| ALL：对应FY的TM、JD合计值。 | indep_rl_view.bbi_upload_Traffic_plan | TM/JD：以TM为例，当 Date_M = 'FY27'、channel = 'TM'、KPI = 'Performance Media Cost' 时取 FCST |  |  |  |  |
| ALL：TM year_cost_amt ＋ JD year_cost_amt |  | year_cost_amt | TRUE | year_cost_amt | TRUE |  |
| year_rtb_cost_amt | decimal(19, 5) | RTB花费金额 |  | RTB Cost | 37351958 | TM、JD：对应FY、对应平台的RTB Cost；年度取值规则同year_cost_amt。 |
| ALL：对应FY的TM、JD合计值。 | indep_rl_view.bbi_upload_Traffic_plan | TM/JD：以TM为例，当 Date_M = 'FY27'、channel = 'TM'、KPI = 'RTB Cost' 时取 FCST |  |  |  |  |
| ALL：TM year_rtb_cost_amt ＋ JD year_rtb_cost_amt |  | year_rtb_cost_amt | TRUE | year_rtb_cost_amt | TRUE |  |
| year_media_cost_rate | double | 媒体花费占比 |  | Media Cost rate | 0.105 | TM、JD：对应FY、对应平台的Media Cost rate；年度取值规则同year_cost_amt。 |
| ALL：ALL year_media_cost_rate ＝ (TM year_cost_amt ＋ JD year_cost_amt) ÷ (TM year_net_sales_amt ＋ JD year_net_sales_amt) × 1.13 ÷ 1.06。 | indep_rl_view.bbi_upload_Traffic_plan | TM/JD：以TM为例，当 Date_M = 'FY27'、channel = 'TM'、KPI = 'Media Cost rate' 时取 FCST |  |  |  |  |
| ALL：(TM year_cost_amt ＋ JD year_cost_amt) ÷ (TM year_net_sales_amt ＋ JD year_net_sales_amt) × 1.13 ÷ 1.06 |  | year_media_cost_rate | TRUE | year_media_cost_rate | TRUE |  |
| year_media_cost_amt | decimal(19, 5) | 媒体花费金额 |  |  | NULL | 预留字段，当前不参与指标计算； |
| TM、JD、ALL均为NULL。 | 固定值 | TM/JD/ALL：固定写入NULL |  | year_media_cost_amt | TRUE | year_media_cost_amt |
| year_acceleration_cost_rate | double | acceleration花费占比 |  | Acceleration Cost% | 0.301 | TM、JD：对应FY、对应平台的Acceleration Cost%；年度取值规则同year_cost_amt。 |
| ALL：ALL year_acceleration_cost_rate ＝ (TM year_acceleration_cost_amt ＋ JD year_acceleration_cost_amt) ÷ (TM year_cost_amt ＋ JD year_cost_amt)。 | indep_rl_view.bbi_upload_Traffic_plan | TM/JD：以TM为例，当 Date_M = 'FY27'、channel = 'TM'、KPI = 'Acceleration Cost%' 时取 FCST |  |  |  |  |
| ALL：(TM year_acceleration_cost_amt ＋ JD year_acceleration_cost_amt) ÷ (TM year_cost_amt ＋ JD year_cost_amt) |  | year_acceleration_cost_rate | TRUE | year_acceleration_cost_rate | TRUE |  |
| year_acceleration_cost_amt | decimal(19, 5) | acceleration花费金额 |  | 花费金额 × acceleration花费占比 | 19694077 | TM、JD：对应FY、对应平台的Acceleration Cost金额；年度取值规则同year_cost_amt。 |
| ALL：对应FY的TM、JD合计值。 | indep_rl_view.bbi_upload_Traffic_plan | TM/JD：year_cost_amt × year_acceleration_cost_rate |  |  |  |  |
| ALL：TM year_acceleration_cost_amt ＋ JD year_acceleration_cost_amt |  | year_acceleration_cost_amt | TRUE | year_acceleration_cost_amt | TRUE |  |
| year_acceleration_cost_rate_vs_net_sales_rate | double | acceleration花费占比vs销售占比 |  | ± Acceleration category cost MOB% vs Acceleration category SLS MOB% | 0.093 | TM、JD：对应FY、对应平台的Acceleration Cost%与Acceleration SLS MOB%差值；年度取值规则同year_cost_amt。 |
| 本字段 ＝ ALL year_acceleration_cost_rate － ALL year_acceleration_net_sales_rate。 | indep_rl_view.bbi_upload_Traffic_plan | TM/JD：以TM为例，当 Date_M = 'FY27'、channel = 'TM'、KPI = '± Acceleration category cost MOB% vs Acceleration category SLS MOB%' 时取 FCST |  |  |  |  |
| ALL：[(TM year_acceleration_cost_amt ＋ JD year_acceleration_cost_amt) ÷ (TM year_cost_amt ＋ JD year_cost_amt)] － [(TM year_acceleration_net_sales_amt ＋ JD year_acceleration_net_sales_amt) ÷ (TM year_net_sales_amt ＋ JD year_net_sales_amt)] |  | year_acceleration_cost_rate_vs_net_sales_rate | TRUE | year_acceleration_cost_rate_vs_net_sales_rate | TRUE |  |
| year_net_sales_amt | decimal(19, 5) | net销售金额 |  | SLS | 657402359 | TM、JD：对应FY、对应平台的SLS，按Net Sales使用；年度取值规则同year_cost_amt。 |
| ALL：对应FY的TM、JD合计值。 | indep_rl_view.bbi_upload_Traffic_plan | TM/JD：以TM为例，当 Date_M = 'FY27'、channel = 'TM'、KPI = 'SLS' 时取 FCST |  |  |  |  |
| ALL：TM year_net_sales_amt ＋ JD year_net_sales_amt |  | year_net_sales_amt | TRUE | year_net_sales_amt | TRUE |  |
| year_acceleration_net_sales_amt | decimal(19, 5) | acceleration net销售金额 |  | Acceleration category SLS | 137702034 | TM、JD：对应FY、对应平台的Acceleration category SLS；年度取值规则同year_cost_amt。 |
| ALL：对应FY的TM、JD合计值。 | indep_rl_view.bbi_upload_Traffic_plan | TM/JD：以TM为例，当 Date_M = 'FY27'、channel = 'TM'、KPI = 'Acceleration category SLS' 时取 FCST |  |  |  |  |
| ALL：TM year_acceleration_net_sales_amt ＋ JD year_acceleration_net_sales_amt |  | year_acceleration_net_sales_amt | TRUE | year_acceleration_net_sales_amt | TRUE |  |
| year_acceleration_net_sales_rate | double | acceleration net销售占比 |  | Acceleration SLS MOB% | 0.208 | TM、JD：对应FY、对应平台的Acceleration SLS MOB%；年度取值规则同year_cost_amt。 |
| ALL：ALL year_acceleration_net_sales_rate ＝ (TM year_acceleration_net_sales_amt ＋ JD year_acceleration_net_sales_amt) ÷ (TM year_net_sales_amt ＋ JD year_net_sales_amt)。 | indep_rl_view.bbi_upload_Traffic_plan | TM/JD：以TM为例，当 Date_M = 'FY27'、channel = 'TM'、KPI = 'Acceleration SLS MOB%' 时取 FCST |  |  |  |  |
| ALL：(TM year_acceleration_net_sales_amt ＋ JD year_acceleration_net_sales_amt) ÷ (TM year_net_sales_amt ＋ JD year_net_sales_amt) |  | year_acceleration_net_sales_rate | TRUE | year_acceleration_net_sales_rate | TRUE |  |
| year_sales_amt | decimal(19, 5) | demand 销售金额 |  | Demand Sales | 2296055333 | TM、JD：对应FY、对应平台的Demand Sales；年度取值规则同year_cost_amt。 |
| ALL：对应FY的TM、JD合计值。 | indep_rl_view.bbi_upload_Traffic_plan | TM/JD：以TM为例，当 Date_M = 'FY27'、channel = 'TM'、KPI = 'Demand Sales' 时取 FCST |  |  |  |  |
| ALL：TM year_sales_amt ＋ JD year_sales_amt |  | year_sales_amt | TRUE | year_sales_amt | TRUE |  |
| year_new_customer_cnt | bigint | 新客人数 |  | year_new_customer_cnt | FY27 TM=206614；JD=44406 | TM、JD：对应财年、对应平台范围的Customer独立年度新客Target；同一财年的月度行重复保存同一年度值。 |
| ALL：对应FY的TM、JD合计值。 | a03_e2e_customer_fcst_data_m | TM/JD：按dt、platform、shop_info_id、currency匹配a03_e2e_customer_fcst_data_m，取a03_e2e_customer_fcst_data_m.year_new_customer_cnt |  |  |  |  |
| ALL：TM year_new_customer_cnt ＋ JD year_new_customer_cnt |  | year_new_customer_cnt | TRUE | year_new_customer_cnt | TRUE |  |
| year_media_new_customer_contribution_rate | double | 媒体新客贡献率 |  | media contribution TO New customer acquisition % | 0.726 | TM、JD：对应FY、对应平台的媒体新客贡献率；年度取值规则同year_cost_amt。 |
| ALL：ALL year_media_new_customer_contribution_rate = (TM year_media_new_customer_cnt + JD year_media_new_customer_cnt) ÷ (TM year_new_customer_cnt + JD year_new_customer_cnt)。 | indep_rl_view.bbi_upload_Traffic_plan | TM/JD：以TM为例，当 Date_M = 'FY27'、channel = 'TM'、KPI = 'media contribution TO New customer acquisition %' 时取 FCST |  |  |  |  |
| ALL：(TM year_media_new_customer_cnt + JD year_media_new_customer_cnt) ÷ (TM year_new_customer_cnt + JD year_new_customer_cnt) |  | year_media_new_customer_contribution_rate | TRUE | year_media_new_customer_contribution_rate | TRUE |  |
| year_media_new_customer_cnt | bigint | 媒体新客人数 |  | 新客人数 × 媒体新客贡献率 | NULL | TM、JD：对应FY、对应平台的媒体新客人数，按公式计算；年度取值规则同year_cost_amt。 |
| ALL：对应FY的TM、JD合计值。 | 本表计算 | TM/JD：year_new_customer_cnt × year_media_new_customer_contribution_rate |  |  |  |  |
| ALL：TM year_media_new_customer_cnt + JD year_media_new_customer_cnt |  | year_media_new_customer_cnt | TRUE | year_media_new_customer_cnt | TRUE |  |
| year_cost_per_new_acquisition | decimal(19, 5) | 新客获客成本 |  | Cost per new acquisition | 369 | TM、JD：对应FY、对应平台的新客获客成本；年度取值规则同year_cost_amt。 |
| ALL：ALL year_cost_per_new_acquisition ＝ (TM year_media_new_customer_cost_amt ＋ JD year_media_new_customer_cost_amt) ÷ (TM year_media_new_customer_cnt ＋ JD year_media_new_customer_cnt)。 | indep_rl_view.bbi_upload_Traffic_plan | TM/JD：以TM为例，当 Date_M = 'FY27'、channel = 'TM'、KPI = 'Cost per new acquisition' 时取 FCST |  |  |  |  |
| ALL：(TM year_media_new_customer_cost_amt ＋ JD year_media_new_customer_cost_amt) ÷ (TM year_media_new_customer_cnt ＋ JD year_media_new_customer_cnt) |  | year_cost_per_new_acquisition | TRUE | year_cost_per_new_acquisition | TRUE |  |
| year_media_new_customer_cost_amt | decimal(19, 5) | 媒体新客花费 |  | 媒体新客人数 × 新客获客成本 | NULL | TM、JD：对应FY、对应平台的媒体新客花费，按公式计算；年度取值规则同year_cost_amt。 |
| ALL：对应FY的TM、JD合计值。 | 本表计算 | TM/JD：year_media_new_customer_cnt × year_cost_per_new_acquisition |  |  |  |  |
| ALL：TM year_media_new_customer_cost_amt + JD year_media_new_customer_cost_amt |  | year_media_new_customer_cost_amt | TRUE | year_media_new_customer_cost_amt | TRUE |  |
| year_customer_cnt | bigint | 客户数 |  |  | NULL | 预留字段，当前不参与指标计算； |
| TM、JD、ALL均为NULL。 | 固定值 | TM/JD/ALL：固定写入NULL |  | year_customer_cnt | TRUE | year_customer_cnt |
| year_new_customer_percent | double | 新客占比 |  |  | NULL | 预留字段，当前不参与指标计算； |
| TM、JD、ALL均为NULL。 | 固定值 | TM/JD/ALL：固定写入NULL |  | year_new_customer_percent | TRUE | year_new_customer_percent |
