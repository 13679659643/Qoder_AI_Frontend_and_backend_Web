let
    源 = Odbc.Query(DBConnection, 
    "
SELECT DISTINCT LOWER(category_summary) AS category_summary
FROM " & ADS & ".a02_e2e_product_performance_sales_summary_d
WHERE category_summary IS NOT NULL
  AND category_summary <> ''
  AND trim(category_summary) <> ''
;")
in
    源