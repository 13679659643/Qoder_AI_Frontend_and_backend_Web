let
    源 = Odbc.Query("dsn=bytehouse_rl", 
    "
select distinct color_name
from indep_rl_dw.s02_trade_sku_data_d
where color_name is not null
  and color_name <> ''
  and trim(color_name) <> ''
;")
in
    源

