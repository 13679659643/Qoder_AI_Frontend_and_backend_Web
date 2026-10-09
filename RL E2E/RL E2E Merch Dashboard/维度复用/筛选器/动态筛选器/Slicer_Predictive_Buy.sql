let
    源 = Odbc.Query("dsn=bytehouse_rl", 
    "
select distinct predictive_buy from indep_rl_ads.a02_e2e_product_performance_sales_summary_d
WHERE predictive_buy IS NOT NULL
  and predictive_buy <> ''
  and trim(predictive_buy) <> ''
;")
in
    源