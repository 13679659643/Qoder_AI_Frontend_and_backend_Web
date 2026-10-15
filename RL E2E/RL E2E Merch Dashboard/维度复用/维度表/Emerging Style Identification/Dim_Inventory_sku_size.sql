let
    源 = Odbc.Query("dsn=bytehouse_rl", 
    "
select distinct sku_size
from indep_rl_dw.s02_inventory_stock_sales_detail_d
where sku_size is not null
  and sku_size <> ''
  and trim(sku_size) <> ''
;")
in
    源