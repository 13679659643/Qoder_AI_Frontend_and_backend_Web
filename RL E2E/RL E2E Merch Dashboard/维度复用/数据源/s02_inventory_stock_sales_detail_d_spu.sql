let
    源 = Odbc.Query("dsn=bytehouse_rl", 
    "
SELECT 
    A.*,
    B_min.size_rank
FROM `indep_rl_dw`.s02_inventory_stock_sales_detail_result_d A
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
where A.data_type = 'spu'
;"),
    更改的类型 = Table.TransformColumnTypes(源,{{"dt", type date}})
in
    更改的类型



let
    源 = Odbc.Query("dsn=bytehouse_rl", 
    "
SELECT 
    A.*,
    B_min.size_rank
FROM `indep_rl_dw`.s02_inventory_stock_sales_detail_result_d A
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
where ((A.dt>='2026-03-29' AND A.dt<='2026-07-25') OR (A.dt>='2025-03-30' AND A.dt<='2025-07-26'))
AND A.data_type = 'spu'
;"),
    更改的类型 = Table.TransformColumnTypes(源,{{"dt", type date}})
in
    更改的类型


SELECT 
    A.*,
    B_min.size_rank
FROM `indep_rl_dw`.s02_inventory_stock_sales_detail_result_d A
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
where ((A.dt>='2026-03-29' AND A.dt<='2026-07-25') OR (A.dt>='2025-03-30' AND A.dt<='2025-07-26'))
AND A.data_type = 'spu'
 