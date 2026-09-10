let
    源 = Odbc.Query("dsn=bytehouse_rl", 
    "
with top_class as (
    select
        data_month,
        category_summary,
        net_pay_amt,
        net_pay_order_cnt,
        net_pay_qty,
        total_net_pay_amt,
        total_net_pay_order_cnt,
        total_net_pay_qty
    from (
        select
            data_month,
            category_summary,
            net_pay_amt,
            net_pay_order_cnt,
            net_pay_qty,
            total_net_pay_amt,
            total_net_pay_order_cnt,
            total_net_pay_qty,
            row_number() over(partition by data_month order by total_net_pay_amt desc) as rn
        from (
            select
                cal.data_month,
                fact.category_summary,
                sum(fact.net_pay_amt) as net_pay_amt,
                sum(fact.net_pay_order_cnt) as net_pay_order_cnt,
                sum(fact.net_pay_qty) as net_pay_qty,
                sum(sum(fact.net_pay_amt)) over(partition by fact.category_summary order by cal.data_month asc) as total_net_pay_amt,
                sum(sum(fact.net_pay_order_cnt)) over(partition by fact.category_summary order by cal.data_month asc) as total_net_pay_order_cnt,
                sum(sum(fact.net_pay_qty)) over(partition by fact.category_summary order by cal.data_month asc) as total_net_pay_qty
            from indep_rl_dw.t05_customer_order_data_d fact
            join (
                select
                    data_month,
                    min(start_data_date) as start_data_date,
                    max(end_data_date) as end_data_date,
                    max(case when rn = 2 then start_data_date else null end) as last_month_start_data_date,
                    max(case when rn = 2 then end_data_date else null end) as last_month_end_data_date
                from (
                    select
                        min(b.date_key) as date_key,
                        min(b.natural_date) as start_data_date,
                        max(b.natural_date) as end_data_date,
                        concat(a.financial_year, lpad(a.financial_month_num, 2, '0')) as data_month,
                        max(concat(a.financial_year, '-', lpad(a.financial_month_num, 2, '0'))) as data_month_name,
                        max(concat(a.financial_year, lpad(a.financial_quarter_num, 2, '0'))) as data_quarter,
                        max(concat(a.financial_year, ' Q', a.financial_quarter_num)) as data_quarter_name,
                        max(a.financial_year) as data_year,
                        max(a.financial_year_name) as data_year_name,
                        row_number() over(order by concat(a.financial_year, lpad(a.financial_month_num, 2, '0')) desc) as rn
                    from indep_rl_dim.dim_t00_calendar a
                    join indep_rl_dim.dim_t00_calendar b
                    on concat(a.financial_year, lpad(a.financial_month_num, 2, '0')) = concat(b.financial_year, lpad(b.financial_month_num, 2, '0'))
                    where a.natural_date >= '2025-03-30'
                    and a.natural_date < current_date()
                    group by concat(a.financial_year, lpad(a.financial_month_num, 2, '0'))
                    order by concat(a.financial_year, lpad(a.financial_month_num, 2, '0')) desc
                ) tt
                -- where rn >= 2 and rn <= 25
                group by data_month
            ) cal
            on fact.dt >= cal.start_data_date
            and fact.dt <= cal.end_data_date
            group by cal.data_month,
                fact.category_summary
        ) tc
    ) tc_tmp
    where rn <= 10
)
select
    s_tbl.dt,
    s_tbl.period,
    s_tbl.data_month,
    s_tbl.data_month_name,
    s_tbl.data_quarter,
    s_tbl.data_quarter_name,
    s_tbl.data_year,
    s_tbl.data_year_name,
    s_tbl.user_id,
    s_tbl.platform,
    s_tbl.customer_type,
    s_tbl.shop_info_id,
    s_tbl.shop_id,
    s_tbl.shop_name,
    s_tbl.shop_name_en,
    s_tbl.shop_code,
    'label' as data_type,
    concat(arrayJoin(s_tbl.data_source), '_1st') as data_source,
    concat(arrayJoin(s_tbl.data_target), '_2nd') as data_target
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
        arrayDistinct(groupArray(case when payment_time_seq = 1 then brand else null end)) as data_source,
        arrayDistinct(groupArray(case when payment_time_seq = 2 then brand else null end)) as data_target
    from indep_rl_ads.a03_e2e_customer_time_ordered_data_m
    where dt >= '202501'
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
    s_tbl.user_id,
    s_tbl.platform,
    s_tbl.customer_type,
    s_tbl.shop_info_id,
    s_tbl.shop_id,
    s_tbl.shop_name,
    s_tbl.shop_name_en,
    s_tbl.shop_code,
    'label' as data_type,
    concat(arrayJoin(s_tbl.data_source), '_2nd') as data_source,
    concat(arrayJoin(s_tbl.data_target), '_3rd') as data_target
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
        arrayDistinct(groupArray(case when payment_time_seq = 2 then brand else null end)) as data_source,
        arrayDistinct(groupArray(case when payment_time_seq = 3 then brand else null end)) as data_target
    from indep_rl_ads.a03_e2e_customer_time_ordered_data_m
    where dt >= '202501'
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
    s_tbl.user_id,
    s_tbl.platform,
    s_tbl.customer_type,
    s_tbl.shop_info_id,
    s_tbl.shop_id,
    s_tbl.shop_name,
    s_tbl.shop_name_en,
    s_tbl.shop_code,
    'class' as data_type,
    concat(arrayJoin(s_tbl.data_source), '_1st') as data_source,
    concat(arrayJoin(s_tbl.data_target), '_2nd') as data_target
from (
    select
        fact.dt,
        fact.period,
        fact.data_month,
        fact.data_month_name,
        fact.data_quarter,
        fact.data_quarter_name,
        fact.data_year,
        fact.data_year_name,
        fact.user_id,
        fact.platform,
        fact.customer_type,
        fact.shop_info_id,
        fact.shop_id,
        fact.shop_name,
        fact.shop_name_en,
        fact.shop_code,
        arrayDistinct(groupArray(case when fact.payment_time_seq = 1 then fact.category_summary else null end)) as data_source,
        arrayDistinct(groupArray(case when fact.payment_time_seq = 2 then fact.category_summary else null end)) as data_target
    from indep_rl_ads.a03_e2e_customer_time_ordered_data_m fact
    join top_class
    on fact.data_month = top_class.data_month
    and fact.category_summary = top_class.category_summary
    where fact.dt >= '202501'
    and fact.payment_time_seq in (1, 2)
    group by fact.dt,
        fact.period,
        fact.data_month,
        fact.data_month_name,
        fact.data_quarter,
        fact.data_quarter_name,
        fact.data_year,
        fact.data_year_name,
        fact.user_id,
        fact.platform,
        fact.customer_type,
        fact.shop_info_id,
        fact.shop_id,
        fact.shop_name,
        fact.shop_name_en,
        fact.shop_code
) s_tbl

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
    s_tbl.user_id,
    s_tbl.platform,
    s_tbl.customer_type,
    s_tbl.shop_info_id,
    s_tbl.shop_id,
    s_tbl.shop_name,
    s_tbl.shop_name_en,
    s_tbl.shop_code,
    'class' as data_type,
    concat(arrayJoin(s_tbl.data_source), '_2nd') as data_source,
    concat(arrayJoin(s_tbl.data_target), '_3rd') as data_target
from (
    select
        fact.dt,
        fact.period,
        fact.data_month,
        fact.data_month_name,
        fact.data_quarter,
        fact.data_quarter_name,
        fact.data_year,
        fact.data_year_name,
        fact.user_id,
        fact.platform,
        fact.customer_type,
        fact.shop_info_id,
        fact.shop_id,
        fact.shop_name,
        fact.shop_name_en,
        fact.shop_code,
        arrayDistinct(groupArray(case when fact.payment_time_seq = 2 then fact.category_summary else null end)) as data_source,
        arrayDistinct(groupArray(case when fact.payment_time_seq = 3 then fact.category_summary else null end)) as data_target
    from indep_rl_ads.a03_e2e_customer_time_ordered_data_m fact
    join top_class
    on fact.data_month = top_class.data_month
    and fact.category_summary = top_class.category_summary
    where fact.dt >= '202501'
    and fact.payment_time_seq in (2, 3)
    group by fact.dt,
        fact.period,
        fact.data_month,
        fact.data_month_name,
        fact.data_quarter,
        fact.data_quarter_name,
        fact.data_year,
        fact.data_year_name,
        fact.user_id,
        fact.platform,
        fact.customer_type,
        fact.shop_info_id,
        fact.shop_id,
        fact.shop_name,
        fact.shop_name_en,
        fact.shop_code
) s_tbl
    ")
in
    源