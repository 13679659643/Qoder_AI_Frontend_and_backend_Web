let
    源 = Odbc.Query("dsn=bytehouse_rl", 
    "
SELECT DISTINCT 
       framework,
       CASE 
         WHEN framework = 'Foundation' THEN 1
         WHEN framework = 'Acceleration' THEN 2
         WHEN framework = 'Complementary' THEN 3
         ELSE 99
       END AS sort_order
FROM indep_rl_ads.a02_e2e_product_performance_sales_summary_d
WHERE framework IS NOT NULL
  AND TRIM(framework) <> ''
ORDER BY sort_order;
;")
in
    源