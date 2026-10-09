let
    源 = Odbc.Query("dsn=bytehouse_rl", 
    "select 
*
FROM `indep_rl_ads`.a02_e2e_product_performance_sales_summary_d
WHERE platform IN ('JD', 'TM', 'RLE', 'DY');"),
    更改的类型 = Table.TransformColumnTypes(源,{{"data_date", type date}})
in
    更改的类型