
let
    源 = Odbc.Query("dsn=bytehouse_rl", 
    "
SELECT DISTINCT co_category as co_category FROM indep_rl_ads.a03_e2e_customer_order_correlation_data_m
WHERE user_name = 'category'
AND TRIM(co_category) <> ''
AND co_category IS NOT NULL
    ")
in
    源


    