let
    源 = Odbc.Query("dsn=bytehouse_rl", 
    "
select distinct product_type from indep_rl_ads.a02_e2e_product_performance_sales_summary_d
WHERE product_type IS NOT NULL
;")
in
    源