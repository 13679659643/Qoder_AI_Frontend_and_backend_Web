let
    源 = Odbc.Query("dsn=bytehouse_rl", 
    "
select 
*
FROM `indep_rl_dw`.s02_inventory_stock_sales_detail_d
;"),
    更改的类型 = Table.TransformColumnTypes(源,{{"dt", type date}})
in
    更改的类型



let
    源 = Odbc.Query("dsn=bytehouse_rl", 
    "
select * from indep_rl_dw.s02_inventory_stock_sales_detail_d where (dt>='2026-03-29' AND dt<='2026-07-25') OR (dt>='2025-03-30' AND dt<='2025-07-26')
;"),
    更改的类型 = Table.TransformColumnTypes(源,{{"dt", type date}})
in
    更改的类型