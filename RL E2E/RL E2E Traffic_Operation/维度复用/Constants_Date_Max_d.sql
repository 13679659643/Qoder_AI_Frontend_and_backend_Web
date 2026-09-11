let
    源 = Odbc.Query("dsn=bytehouse_rl", "
    SELECT 
    CONCAT(
        'Data cutoff：',
        DATE_FORMAT(
            MAX(STR_TO_DATE(data_date, '%Y-%m-%d')),
            '%Y-%m-%d'
        )
    ) AS `Constants_Date_Max`
FROM indep_rl_ads.a05_e2e_paid_media_summary_d
    ")
in
    源