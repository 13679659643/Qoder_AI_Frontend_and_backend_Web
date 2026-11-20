let
    源 = Odbc.Query(DBConnection, 
    "
SELECT DISTINCT 
       brand AS label,
       CASE 
         WHEN brand = 'M Polo' THEN 1
         WHEN brand = 'W Polo' THEN 2
         WHEN brand = 'cw' THEN 3
         WHEN brand = 'RRL' THEN 4
         WHEN brand = 'Lauren' THEN 5
         WHEN brand = 'HM' THEN 6
         WHEN brand = 'CL' THEN 7
         WHEN brand = 'PL' THEN 8
         ELSE 99
       END AS sort_order
FROM " & ADS & ".a02_e2e_product_performance_sales_summary_d
WHERE brand IS NOT NULL
  AND TRIM(brand) <> ''
ORDER BY sort_order, label;

;")
in
    源