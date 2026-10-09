let
    源 = Odbc.Query("dsn=bytehouse_rl", 
    "
select distinct special_supply from indep_rl_ads.a02_e2e_product_performance_sales_summary_d
WHERE special_supply IS NOT NULL
  and special_supply <> ''
  and trim(special_supply) <> ''
;")
in
    源