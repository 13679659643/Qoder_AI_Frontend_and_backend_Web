let
    源 = Odbc.Query(DBConnection, 
    "
select distinct ax_class from " & ADS & ".a02_e2e_product_performance_sales_summary_d
WHERE ax_class IS NOT NULL
  and ax_class <> ''
  and trim(ax_class) <> ''
;")
in
    源