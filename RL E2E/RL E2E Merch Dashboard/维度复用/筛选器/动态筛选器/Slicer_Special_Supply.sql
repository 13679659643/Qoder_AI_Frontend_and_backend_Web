let
    源 = Odbc.Query(DBConnection, 
    "
select distinct special_supply from " & ADS & ".a02_e2e_product_performance_sales_summary_d
WHERE special_supply IS NOT NULL
  and special_supply <> ''
  and trim(special_supply) <> ''
;")
in
    源