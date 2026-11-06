let
    源 = Odbc.Query(DBConnection, 
    "
SELECT 
    A.*,
    B_min.size_rank,
    ROUND(A.product_qty * A.sales_price, 6) AS net_sales_amt
FROM " & DW & ".s02_trade_sku_data_d A
LEFT JOIN (
    SELECT 
        size,
        MIN(rank) AS size_rank
    FROM " & DIM & ".dim_t00_size_category_mapping
    GROUP BY size
) B_min
  ON A.sku_size = B_min.size
 where 1=1
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
        MIN(rank) AS size_rank
    FROM indep_rl_dim.dim_t00_size_category_mapping
    GROUP BY size
) B_min
  ON A.sku_size = B_min.size
 where (A.dt>='2026-03-29' AND A.dt<='2026-09-26') OR (A.dt>='2025-03-30' AND A.dt<='2025-09-27')
 