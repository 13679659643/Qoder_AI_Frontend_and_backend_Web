let
    源 = Odbc.Query(DBConnection, 
    "
select distinct special_supply from " & ADS & ".a02_e2e_product_performance_sales_summary_d
WHERE special_supply IS NOT NULL
  and special_supply <> ''
  and trim(special_supply) <> ''
;")
in
    源

  

SELECT DISTINCT
    CASE 
        -- 1. 先精准清理 C2A0 和 �(EFBFBD)
        WHEN special_supply = 'Quality Issues' 
        THEN 'Quality Issues'
            
        -- 2. BZ shots 忽略大小写统一为首字母大写
        WHEN LOWER(TRIM(special_supply)) = 'bz shots' 
        THEN 'BZ Shots'
        
        -- 3. 其余所有值绝对原样返回
        ELSE special_supply
    END AS special_supply
FROM " & ADS & ".a02_e2e_product_performance_sales_summary_d
WHERE special_supply IS NOT NULL
  AND trim(special_supply) <> ''