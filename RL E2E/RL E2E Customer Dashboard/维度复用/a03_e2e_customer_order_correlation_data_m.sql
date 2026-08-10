let
    源 = Odbc.Query("dsn=bytehouse_rl", 
    "
    SELECT * ,
        LAST_DAY(
                DATE_SUB(
                    STR_TO_DATE(CONCAT(data_month, '01'), '%Y%m%d'),
                    INTERVAL 10 MONTH
                )
            ) AS data_date
    FROM indep_rl_ads.a03_e2e_customer_order_correlation_data_m
    "),
    更改的类型 = Table.TransformColumnTypes(源,{{"data_date", type date}})
in
    更改的类型