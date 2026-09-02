let
    源 = Odbc.Query("dsn=bytehouse_rl", 
    "
    SELECT
    `etl_time`, -- etl时间
    `timeframe_id` AS `TimeFrame_ID`, -- 时间框架ID
    `timeframe_label` AS `TimeFrame_Label`, -- 时间框架标签
    `timeframe_sort` AS `TimeFrame_Sort`, -- 时间框架排序
    `timeframe_value` AS `TimeFrame_Value`, -- 当前时间段名称
    `timeframe_key` AS `TimeFrame_Key`, -- 当前时间段Key
    `id_sort` AS `ID_Sort`, -- ID排序
    `timeframe_min` AS `TimeFrame_Min`, -- 当前时间段起始自然日
    `timeframe_max` AS `TimeFrame_Max`, -- 当前时间段结束自然日
    `ly_timeframe_value` AS `TimeFrame_Value_LY`, -- 去年同期时间段名称
    `ly_timeframe_key` AS `TimeFrame_Key_LY`, -- 去年同期时间段Key
    `ly_timeframe_min` AS `TimeFrame_Min_LY`, -- 去年同期起始自然日
    `ly_timeframe_max` AS `TimeFrame_Max_LY` -- 去年同期结束自然日
FROM 
	    indep_rl_dim.dim_t00_bi_fiscal_calendar t1
WHERE (t1.`TimeFrame_ID` = 'Day' AND t1.`timeframe_value` >='2025-01-01') 
OR (t1.`TimeFrame_ID` = 'Week' AND t1.`TimeFrame_Key` >=202540)
OR (t1.`TimeFrame_ID` = 'Month' AND t1.`TimeFrame_Key` >=202510)
OR (t1.`TimeFrame_ID` = 'Quarter' AND t1.`TimeFrame_Key` >=202504)
OR (t1.`TimeFrame_ID` = 'Year' AND t1.`TimeFrame_Key` >=2025)
ORDER BY ID_Sort DESC
    ")
in
    源