
let
    源 = Odbc.Query("dsn=bytehouse_rl", 
    "
SELECT DISTINCT category_summary FROM indep_rl_ads.a03_e2e_customer_order_correlation_data_m
WHERE user_name = 'class'
    ")
in
    源