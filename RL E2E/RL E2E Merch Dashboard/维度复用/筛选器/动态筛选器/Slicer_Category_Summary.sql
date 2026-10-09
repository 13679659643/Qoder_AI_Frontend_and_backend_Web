let
    源 = Odbc.Query("dsn=bytehouse_rl", 
    "
select distinct category_summary from indep_rl_ads.a02_e2e_product_performance_sales_summary_d
WHERE category_summary IS NOT NULL
  and category_summary <> ''
  and trim(category_summary) <> ''
;")
in
    源