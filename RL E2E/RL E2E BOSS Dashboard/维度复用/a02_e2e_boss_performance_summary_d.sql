let
    源 = Odbc.Query("dsn=bytehouse_rl", 
    "
    select * from `indep_rl_ads`.a02_e2e_boss_performance_summary_d
    "),
    更改的类型 = Table.TransformColumnTypes(源,{{"data_date", type date}})
in
    更改的类型