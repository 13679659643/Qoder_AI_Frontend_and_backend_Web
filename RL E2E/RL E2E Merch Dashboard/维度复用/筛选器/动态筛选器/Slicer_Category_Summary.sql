let
    源 = Odbc.Query("dsn=bytehouse_rl", 
    "
SELECT DISTINCT LOWER(category_summary) AS category_summary
FROM indep_rl_ads.a02_e2e_product_performance_sales_summary_d
WHERE category_summary IS NOT NULL
  AND category_summary <> ''
  AND trim(category_summary) <> ''
;")
in
    源