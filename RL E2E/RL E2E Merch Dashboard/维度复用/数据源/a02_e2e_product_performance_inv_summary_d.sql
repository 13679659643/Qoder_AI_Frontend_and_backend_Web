let
    源 = Odbc.Query(DBConnection, 
    "
select 
*
FROM " & ADS & ".a02_e2e_product_performance_inv_summary_d
;"),
    更改的类型 = Table.TransformColumnTypes(源,{{"data_date", type date}})
in
    更改的类型