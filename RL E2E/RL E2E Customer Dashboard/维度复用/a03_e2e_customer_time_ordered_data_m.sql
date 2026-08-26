let
    源 = Odbc.Query("dsn=bytehouse_rl", 
    "
select
    dt,
    period,
    data_month,
    data_month_name,
    data_quarter,
    data_quarter_name,
    data_year,
    data_year_name,
    user_id,
    platform,
    customer_type,
    shop_info_id,
    shop_id,
    shop_name,
    shop_name_en,
    shop_code,
    max(case when payment_time_seq = 1 then concat(brand, '_1') else null end) as brand_source,
    max(case when payment_time_seq = 2 then concat(brand, '_2') else null end) as brand_target,
    max(case when payment_time_seq = 1 then concat(category_summary, '_1') else null end) as category_summary_source,
    max(case when payment_time_seq = 2 then concat(category_summary, '_2') else null end) as category_summary_target
from indep_rl_ads.a03_e2e_customer_time_ordered_data_m
where dt >= '202606'
and payment_time_seq in (1, 2)
group by dt,
    period,
    data_month,
    data_month_name,
    data_quarter,
    data_quarter_name,
    data_year,
    data_year_name,
    user_id,
    platform,
    customer_type,
    shop_info_id,
    shop_id,
    shop_name,
    shop_name_en,
    shop_code

union all


select
    dt,
    period,
    data_month,
    data_month_name,
    data_quarter,
    data_quarter_name,
    data_year,
    data_year_name,
    user_id,
    platform,
    customer_type,
    shop_info_id,
    shop_id,
    shop_name,
    shop_name_en,
    shop_code,
    max(case when payment_time_seq = 2 then concat(brand, '_2') else null end) as brand_source,
    max(case when payment_time_seq = 3 then concat(brand, '_3') else null end) as brand_target,
    max(case when payment_time_seq = 2 then concat(category_summary, '_2') else null end) as category_summary_source,
    max(case when payment_time_seq = 3 then concat(category_summary, '_3') else null end) as category_summary_target
from indep_rl_ads.a03_e2e_customer_time_ordered_data_m
where dt >= '202606'
and payment_time_seq in (1, 2)
group by dt,
    period,
    data_month,
    data_month_name,
    data_quarter,
    data_quarter_name,
    data_year,
    data_year_name,
    user_id,
    platform,
    customer_type,
    shop_info_id,
    shop_id,
    shop_name,
    shop_name_en,
    shop_code
    ")
in
    源