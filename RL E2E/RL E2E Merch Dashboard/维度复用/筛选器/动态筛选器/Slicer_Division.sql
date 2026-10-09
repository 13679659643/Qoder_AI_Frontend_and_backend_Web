let
    源 = Odbc.Query("dsn=bytehouse_rl", 
    "
select distinct division from indep_rl_ads.a02_e2e_product_performance_sales_summary_d
WHERE division IS NOT NULL
;")
in
    源