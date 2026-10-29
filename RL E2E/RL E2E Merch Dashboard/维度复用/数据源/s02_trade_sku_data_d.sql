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
ROUND(product_qty*sales_price,6) as net_sales_amt from indep_rl_dw.s02_trade_sku_data_d 
where (dt>='2026-03-29' AND dt<='2026-09-26') OR (dt>='2025-03-30' AND dt<='2025-09-27')
;"),
    更改的类型 = Table.TransformColumnTypes(源,{{"dt", type date}})
in
    更改的类型


SELECT 
    A.*,
    B_min.size_rank,
    ROUND(A.product_qty * A.sales_price, 6) AS net_sales_amt
FROM `indep_rl_dw`.s02_trade_sku_data_d A
LEFT JOIN (
    SELECT 
        size,
        size_category,
        MIN(rank) AS size_rank
    FROM indep_rl_dim.dim_t00_size_category_mapping
    GROUP BY size, size_category
) B_min
  ON A.sku_size = B_min.size
 AND A.sku_size_category = B_min.size_category
 where (A.dt>='2026-03-29' AND A.dt<='2026-09-26') OR (A.dt>='2025-03-30' AND A.dt<='2025-09-27')
 