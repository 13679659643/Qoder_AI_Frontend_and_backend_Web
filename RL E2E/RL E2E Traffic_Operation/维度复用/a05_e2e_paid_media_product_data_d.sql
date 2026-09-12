let
    源 = Odbc.Query(
        "
        dsn=bytehouse_rl", 
        "
select  *,
IF(framework IS NOT NULL AND brand IS NOT NULL AND category IS NOT NULL AND channel IS NOT NULL AND mix_msg IS NULL,'other',mix_msg) AS mix_msg_Label_01,
IF(season IS NOT NULL AND brand IS NOT NULL AND category IS NOT NULL AND channel IS NOT NULL AND mix_msg IS NULL,'other',mix_msg) AS mix_msg_Label_02
  from  `indep_rl_ads`.a05_e2e_paid_media_product_data_d 
    WHERE platform IN ('JD', 'TM') 
        "
        ),
    更改的类型 = Table.TransformColumnTypes(源,{{"data_date", type date}})
in
    更改的类型