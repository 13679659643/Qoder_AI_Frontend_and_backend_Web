let
    源 = Odbc.Query("dsn=bytehouse_rl", 
    "
select 
    etl_time,
    dt,
    data_date,
    data_month,
    data_month_name,
    data_quarter,
    data_quarter_name,
    data_year,
    data_year_name,
    user_id as user_id_origin,
    MD5(user_id) as user_id,
    user_name,
    platform,
    register_date,
    is_employee,
    is_member,
    customer_type,
    shop_info_id,
    shop_id,
    shop_name,
    shop_name_en,
    shop_code,
    pay_amt,
    pay_order_cnt,
    pay_qty,
    net_pay_amt,
    net_pay_order_cnt,
    net_pay_qty,
    last_12m_net_pay_amt,
    last_12m_net_pay_order_cnt,
    last_12m_net_pay_qty,
    last_period_customer_tier,
    is_last_period_vic,
    last_24m_12m_net_pay_amt,
    last_24m_12m_net_pay_order_cnt,
    last_24m_12m_net_pay_qty,
    is_vic,
    customer_tier,
    is_new_vic,
    is_direct_vic,
    is_upgrade_vic,
    is_retention_vic,
    lp_12m_pay_amt,
    lp_12m_pay_order_cnt,
    lp_12m_pay_qty,
    lp_12m_net_pay_amt,
    lp_12m_net_pay_order_cnt,
    lp_12m_net_pay_qty,
    last_fy_net_pay_amt,
    last_fy_net_pay_order_cnt,
    last_fy_net_pay_qty,
    last_fy_last_order_month,
    last_fy_last_order_month_type,
    is_fy_vic,
    is_fy_retention_vic
from indep_rl_ads.a03_e2e_customer_data_m
where user_id in (
    select user_id
    from indep_rl_ads.a03_e2e_customer_data_m
    where net_pay_amt > 0
)
    "),
    更改的类型 = Table.TransformColumnTypes(源,{{"data_date", type date}})
in
    更改的类型