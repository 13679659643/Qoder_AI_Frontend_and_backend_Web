let
    源 = Odbc.Query(DBConnection, 
    "
  select distinct color_name
from " & DW & ".s02_inventory_stock_sales_detail_result_d
where 1=1 AND color_name is not null
  AND color_name <> ''
  AND trim(color_name) <> ''
  AND data_type = 'sku'
;")
in
    源