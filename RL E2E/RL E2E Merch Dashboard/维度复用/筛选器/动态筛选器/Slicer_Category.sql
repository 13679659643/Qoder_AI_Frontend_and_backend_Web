let
    源 = Odbc.Query(DBConnection, 
    "
select distinct category
from " & ADS & ".a02_e2e_product_performance_sales_summary_d
where category is not null
  and category <> ''
  and trim(category) <> ''
;")
in
    源