let
    源 = Odbc.Query("dsn=bytehouse_rl", 
    "
SELECT DISTINCT 
    division,
    CASE division 
        WHEN 'MN' THEN 1 
        WHEN 'WM' THEN 2 
        WHEN 'CW' THEN 3 
        WHEN 'HM' THEN 4 
        ELSE 999 
    END AS division_sort
FROM indep_rl_ads.a02_e2e_product_performance_sales_summary_d
WHERE division IS NOT NULL
;")
in
    源