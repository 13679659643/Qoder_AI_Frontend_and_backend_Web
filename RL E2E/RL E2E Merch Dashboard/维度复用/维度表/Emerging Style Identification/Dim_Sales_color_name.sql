let
    源 = Odbc.Query(DBConnection, 
    "
select distinct color_name
from " & DW & ".s02_trade_sku_data_d
where color_name is not null
  and color_name <> ''
  and trim(color_name) <> ''
;")
in
    源

