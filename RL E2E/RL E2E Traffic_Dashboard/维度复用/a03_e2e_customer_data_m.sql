let
    源 = Odbc.Query("dsn=bytehouse_rl", 
    "
select *
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