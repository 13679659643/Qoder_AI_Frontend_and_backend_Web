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


含义：
子查询先找出所有曾经有过 net_pay_amt > 0 的 user_id 列表（即“付费过的用户”）。
主查询再找出这些用户在表中的全部记录（无论这笔记录的 net_pay_amt 是否大于 0，哪怕是负数、0 或 NULL 都会被查出来）。
结果：不仅包含这些用户的付费成功记录，还包含他们的未付费记录、退款记录等所有其他行为数据。