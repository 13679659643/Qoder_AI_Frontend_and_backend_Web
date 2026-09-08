let
    源 = Odbc.Query("dsn=bytehouse_rl", "#(lf)select #(lf)*,#(lf)CASE WHEN channel='直通车' THEN 1#(lf)
    WHEN channel='引力魔方' THEN 2#(lf)WHEN channel='全站推' THEN 3#(lf) END AS channel_sort#(lf)
    FROM `indep_rl_ads`.a05_e2e_paid_media_keyword_data_d#(lf)
    WHERE platform IN ('JD', 'TM')
    "),
    更改的类型 = Table.TransformColumnTypes(源,{{"data_date", type date}})
in
    更改的类型