let
    源 = Odbc.Query("dsn=bytehouse_rl", 
    "
SELECT DISTINCT 
       spu_model
FROM indep_rl_dw.s02_trade_sku_data_d
WHERE spu_model IS NOT NULL
  AND TRIM(spu_model) <> ''
;")
in
    源


SELECT DISTINCT 
       spu_model,
       CASE 
         WHEN spu_model = 'Polo Play' THEN 1
         WHEN spu_model = 'Polo ID' THEN 2
         WHEN spu_model = 'Polo Blaze' THEN 3
         ELSE 99
       END AS sort_order
FROM indep_rl_dw.s02_trade_sku_data_d
WHERE spu_model IS NOT NULL
  AND TRIM(spu_model) <> ''
  AND spu_model IN ('Polo Play', 'Polo ID', 'Polo Blaze')