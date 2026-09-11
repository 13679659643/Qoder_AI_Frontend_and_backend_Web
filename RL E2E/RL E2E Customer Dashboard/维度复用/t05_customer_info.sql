let
    源 = Odbc.Query("dsn=bytehouse_rl", 
    "
select *
from `indep_rl_dw`.`t05_customer_info`
    "),
    更改的类型 = Table.TransformColumnTypes(源,{{"register_date", type date}})
in
    更改的类型