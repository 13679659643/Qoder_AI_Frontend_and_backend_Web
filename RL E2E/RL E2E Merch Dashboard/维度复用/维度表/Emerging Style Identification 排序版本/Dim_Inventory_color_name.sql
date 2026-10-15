let
    源 = Odbc.Query("dsn=bytehouse_rl", 
    "
SELECT 
    color_name,
    ROW_NUMBER() OVER (ORDER BY color_name ASC) AS color_sort_key
FROM (
    SELECT DISTINCT color_name
    FROM indep_rl_dw.s02_inventory_stock_sales_detail_d
    WHERE color_name IS NOT NULL
      AND color_name <> ''
      AND trim(color_name) <> ''
)
ORDER BY color_name ASC
;")
in
    源