
let
    源 = Odbc.Query("dsn=bytehouse_rl", 
    "
SELECT DISTINCT brand FROM indep_rl_ads.a03_e2e_customer_order_correlation_data_m
WHERE user_name = 'label'
    ")
in
    源