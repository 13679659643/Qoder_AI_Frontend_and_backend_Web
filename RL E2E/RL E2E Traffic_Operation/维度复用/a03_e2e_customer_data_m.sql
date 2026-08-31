let
    源 = Odbc.Query("dsn=bytehouse_rl", 
    "
select *
from indep_rl_ads.a03_e2e_customer_data_m
where net_pay_amt > 0
    "),
    更改的类型 = Table.TransformColumnTypes(源,{{"data_date", type date}})
in
    更改的类型