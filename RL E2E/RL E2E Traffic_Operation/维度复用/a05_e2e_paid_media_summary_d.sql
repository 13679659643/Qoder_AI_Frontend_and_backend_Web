let
    源 = Odbc.Query("dsn=bytehouse_rl", "#(lf)    select * from `indep_rl_ads`.a05_e2e_paid_media_summary_d WHERE platform in ( 'JD','TM')#(lf)"),
    更改的类型 = Table.TransformColumnTypes(源,{{"data_date", type date}})
in
    更改的类型