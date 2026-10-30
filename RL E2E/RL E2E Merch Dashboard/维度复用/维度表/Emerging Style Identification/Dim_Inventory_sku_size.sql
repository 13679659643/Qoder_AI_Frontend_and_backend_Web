let
    源 = Odbc.Query("dsn=bytehouse_rl", 
    "
SELECT 
    sku_size_category,
    sku_size,
    size_rank,
    category_sort,
    category_sort * 1000000 + COALESCE(size_rank, 0) AS global_sort_key
FROM (
    SELECT DISTINCT 
        A.sku_size_category,
        A.sku_size,
        B_min.size_rank,
        DENSE_RANK() OVER (ORDER BY A.sku_size_category ASC) AS category_sort
    FROM indep_rl_dw.s02_inventory_stock_sales_detail_result_d A
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
    WHERE 1=1
      AND A.sku_size IS NOT NULL
      AND TRIM(A.sku_size) <> ''
) t
WHERE t.size_rank IS NOT NULL
;")
in
    源