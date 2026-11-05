let
    源 = Odbc.Query(DBConnection, 
    "
select distinct product_type from " & ADS & ".a02_e2e_product_performance_sales_summary_d
WHERE product_type IS NOT NULL
;")
in
    源