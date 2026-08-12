
let
    源 = Odbc.Query("dsn=bytehouse_rl", 
    "
SELECT * FROM indep_rl_ads.a03_e2e_customer_fcst_data_m
    "),
    更改的类型 = Table.TransformColumnTypes(源,{{"data_date", type date}})
in
    更改的类型