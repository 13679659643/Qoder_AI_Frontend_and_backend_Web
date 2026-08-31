let
    源 = Odbc.Query("dsn=bytehouse_rl", "SELECT #(lf)    CONCAT(#(lf)        'Data cutoff：',#(lf)        DATE_FORMAT(#(lf)            MAX(STR_TO_DATE(data_date, '%Y-%m-%d')),#(lf)            '%Y-%m-%d'#(lf)        )#(lf)    ) AS `Constants_Date_Max`#(lf)FROM indep_rl_ads.a05_e2e_paid_media_summary_d")
in
    源