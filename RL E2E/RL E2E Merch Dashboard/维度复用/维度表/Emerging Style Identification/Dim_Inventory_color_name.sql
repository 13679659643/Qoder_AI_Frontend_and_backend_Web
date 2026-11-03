let
    源 = Odbc.Query("dsn=bytehouse_rl", 
    "
  select distinct color_name
from indep_rl_dw.s02_inventory_stock_sales_detail_result_d
where 1=1 AND color_name is not null
  AND color_name <> ''
  AND trim(color_name) <> ''
  AND data_type = 'sku'
;")
in
    源