let
    源 = Odbc.Query("dsn=bytehouse_rl", 
    "
select * from  indep_rl_ads.a05_e2e_product_fcst_data_d
;"),
    更改的类型 = Table.TransformColumnTypes(源,{{"data_date", type date}})
in
    更改的类型