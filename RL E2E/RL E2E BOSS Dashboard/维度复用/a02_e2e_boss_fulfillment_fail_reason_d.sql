let
    源 = Odbc.Query("dsn=bytehouse_rl", 
    "
    SELECT * FROM `indep_rl_ads`.a02_e2e_boss_fulfillment_fail_reason_d
    "),
    更改的类型 = Table.TransformColumnTypes(源,{{"data_date", type date}})
in
    更改的类型