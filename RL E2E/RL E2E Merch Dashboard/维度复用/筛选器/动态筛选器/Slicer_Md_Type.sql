let
    源 = Odbc.Query("dsn=bytehouse_rl", 
    "
SELECT DISTINCT 
       md_type,
       CASE 
         WHEN md_type = 'FP' THEN 1
         WHEN md_type = '50%OFF' THEN 2
         WHEN md_type = '30%OFF' THEN 3
         ELSE 99
       END AS sort_order
FROM indep_rl_ads.a02_e2e_product_performance_sales_summary_d
WHERE md_type IS NOT NULL
  AND md_type <> ''
  AND TRIM(md_type) <> ''
ORDER BY sort_order;
;")
in
    源