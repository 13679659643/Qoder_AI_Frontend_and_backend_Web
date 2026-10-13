let
    源 = Odbc.Query("dsn=bytehouse_rl", 
    "
select 
*,
ROUND(product_qty*sales_price,6) as net_sales_amt
FROM `indep_rl_dw`.s02_trade_sku_data_d
;"),
    更改的类型 = Table.TransformColumnTypes(源,{{"dt", type date}})
in
    更改的类型




let
    源 = Odbc.Query("dsn=bytehouse_rl", 
    "
select *,
ROUND(product_qty*sales_price,6) as net_sales_amt from indep_rl_dw.s02_trade_sku_data_d where (dt>='2026-03-29' AND dt<='2026-09-26') OR (dt>='2025-03-30' AND dt<='2025-09-27')
;"),
    更改的类型 = Table.TransformColumnTypes(源,{{"dt", type date}})
in
    更改的类型