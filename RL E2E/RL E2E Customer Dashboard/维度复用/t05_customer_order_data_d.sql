
let
    源 = Odbc.Query("dsn=bytehouse_rl", 
    "
SELECT * FROM indep_rl_dw.t05_customer_order_data_d
    "),
    更改的类型 = Table.TransformColumnTypes(源,{{"dt", type date}})
in
    更改的类型