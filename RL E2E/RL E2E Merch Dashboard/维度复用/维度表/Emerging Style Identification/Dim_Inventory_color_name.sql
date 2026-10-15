let
    源 = Odbc.Query("dsn=bytehouse_rl", 
    "
  select distinct color_name
from indep_rl_dw.s02_inventory_stock_sales_detail_d
where color_name is not null
  and color_name <> ''
  and trim(color_name) <> ''
;")
in
    源