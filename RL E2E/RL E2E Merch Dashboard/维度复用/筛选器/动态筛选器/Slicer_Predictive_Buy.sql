let
    源 = Odbc.Query(DBConnection, 
    "
select distinct predictive_buy from " & ADS & ".a02_e2e_product_performance_sales_summary_d
WHERE predictive_buy IS NOT NULL
;")
in
    源