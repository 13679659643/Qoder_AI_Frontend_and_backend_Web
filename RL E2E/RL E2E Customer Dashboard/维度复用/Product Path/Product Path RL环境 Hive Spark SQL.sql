let
    源 = Odbc.Query(DBConnection, 
    "
select
    s_tbl.dt,
    s_tbl.period,
    s_tbl.data_month,
    s_tbl.data_month_name,
    s_tbl.data_quarter,
    s_tbl.data_quarter_name,
    s_tbl.data_year,
    s_tbl.data_year_name,
    s_tbl.user_id AS user_id_origin,
    MD5(s_tbl.user_id) AS user_id,
    s_tbl.platform,
    s_tbl.customer_type,
    s_tbl.shop_info_id,
    s_tbl.shop_id,
    s_tbl.shop_name,
    s_tbl.shop_name_en,
    s_tbl.shop_code,
    'label' as data_type,
    concat(ds_item, '_1st') as data_source,
    concat(dt_item, '_2nd') as data_target
from (
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
        collect_set(case when payment_time_seq = 1 then brand else null end) as data_source,
        collect_set(case when payment_time_seq = 2 then brand else null end) as data_target
    from dec2_gold.a03_e2e_customer_time_ordered_data_m
    where dt >= '202701'
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
) s_tbl
lateral view explode(s_tbl.data_source) t1 as ds_item
lateral view explode(s_tbl.data_target) t2 as dt_item

union all

select
    s_tbl.dt,
    s_tbl.period,
    s_tbl.data_month,
    s_tbl.data_month_name,
    s_tbl.data_quarter,
    s_tbl.data_quarter_name,
    s_tbl.data_year,
    s_tbl.data_year_name,
    s_tbl.user_id AS user_id_origin,
    MD5(s_tbl.user_id) AS user_id,
    s_tbl.platform,
    s_tbl.customer_type,
    s_tbl.shop_info_id,
    s_tbl.shop_id,
    s_tbl.shop_name,
    s_tbl.shop_name_en,
    s_tbl.shop_code,
    'label' as data_type,
    concat(ds_item, '_2nd') as data_source,
    concat(dt_item, '_3rd') as data_target
from (
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
        collect_set(case when payment_time_seq = 2 then brand else null end) as data_source,
        collect_set(case when payment_time_seq = 3 then brand else null end) as data_target
    from dec2_gold.a03_e2e_customer_time_ordered_data_m
    where dt >= '202701'
    and payment_time_seq in (2, 3)
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
) s_tbl
lateral view explode(s_tbl.data_source) t1 as ds_item
lateral view explode(s_tbl.data_target) t2 as dt_item

union all

select
    s_tbl.dt,
    s_tbl.period,
    s_tbl.data_month,
    s_tbl.data_month_name,
    s_tbl.data_quarter,
    s_tbl.data_quarter_name,
    s_tbl.data_year,
    s_tbl.data_year_name,
    s_tbl.user_id AS user_id_origin,
    MD5(s_tbl.user_id) AS user_id,
    s_tbl.platform,
    s_tbl.customer_type,
    s_tbl.shop_info_id,
    s_tbl.shop_id,
    s_tbl.shop_name,
    s_tbl.shop_name_en,
    s_tbl.shop_code,
    'class' as data_type,
    concat(ds_item, '_1st') as data_source,
    concat(dt_item, '_2nd') as data_target
from (
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
        collect_set(case when payment_time_seq = 1 then category_summary else null end) as data_source,
        collect_set(case when payment_time_seq = 2 then category_summary else null end) as data_target
    from dec2_gold.a03_e2e_customer_time_ordered_data_m
    where dt >= '202701'
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
) s_tbl
lateral view explode(s_tbl.data_source) t1 as ds_item
lateral view explode(s_tbl.data_target) t2 as dt_item

union all

select
    s_tbl.dt,
    s_tbl.period,
    s_tbl.data_month,
    s_tbl.data_month_name,
    s_tbl.data_quarter,
    s_tbl.data_quarter_name,
    s_tbl.data_year,
    s_tbl.data_year_name,
    s_tbl.user_id AS user_id_origin,
    MD5(s_tbl.user_id) AS user_id,
    s_tbl.platform,
    s_tbl.customer_type,
    s_tbl.shop_info_id,
    s_tbl.shop_id,
    s_tbl.shop_name,
    s_tbl.shop_name_en,
    s_tbl.shop_code,
    'class' as data_type,
    concat(ds_item, '_2nd') as data_source,
    concat(dt_item, '_3rd') as data_target
from (
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
        collect_set(case when payment_time_seq = 2 then category_summary else null end) as data_source,
        collect_set(case when payment_time_seq = 3 then category_summary else null end) as data_target
    from dec2_gold.a03_e2e_customer_time_ordered_data_m
    where dt >= '202701'
    and payment_time_seq in (2, 3)
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
) s_tbl
lateral view explode(s_tbl.data_source) t1 as ds_item
lateral view explode(s_tbl.data_target) t2 as dt_item
    ")
in
    源