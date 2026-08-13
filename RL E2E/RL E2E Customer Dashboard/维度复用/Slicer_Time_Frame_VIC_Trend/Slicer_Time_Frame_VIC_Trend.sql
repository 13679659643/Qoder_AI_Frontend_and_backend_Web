let
    源 = Odbc.Query("dsn=bytehouse_rl", 
    "
SELECT
    t1.`etl_time`,
    t1.`TimeFrame_ID`,
    t1.`TimeFrame_Label`,
    t1.`TimeFrame_Sort`,
    t1.`TimeFrame_Value`,
    t1.`TimeFrame_Key`,
    t1.`ID_Sort`,
    t1.`TimeFrame_Min`,
    t1.`TimeFrame_Max`,
    t1.`TimeFrame_Value_LY`,
    t1.`TimeFrame_Key_LY`,
    t1.`TimeFrame_Min_LY`,
    t1.`TimeFrame_Max_LY`,
    t1.`TimeFrame_Value_LP`,
    t1.`TimeFrame_Key_LP`,
    t1.`TimeFrame_Min_LP`,
    t1.`TimeFrame_Max_LP`,
    t1.`Last_Fiscal_Month`,
    -- ★ 自关联得到的：Last_Fiscal_Month 对应的最小/最大日期
    t2.`timeframe_min` AS `Last_Fiscal_Month_Min`,
    t2.`timeframe_max` AS `Last_Fiscal_Month_Max`,
    t2.`ly_timeframe_min` AS `Last_Fiscal_Month_Min_LY`,
    t2.`ly_timeframe_max` AS `Last_Fiscal_Month_Max_LY`,
    t2.`lp_timeframe_min` AS `Last_Fiscal_Month_Min_LP`,
    t2.`lp_timeframe_max` AS `Last_Fiscal_Month_Max_LP`
FROM (
    -- 子查询：原始逻辑 + 计算 Last_Fiscal_Month
    SELECT
        `etl_time`,
        `timeframe_id`       AS `TimeFrame_ID`,
        `timeframe_label`    AS `TimeFrame_Label`,
        `timeframe_sort`     AS `TimeFrame_Sort`,
        `timeframe_value`    AS `TimeFrame_Value`,
        `timeframe_key`      AS `TimeFrame_Key`,
        `id_sort`            AS `ID_Sort`,
        `timeframe_min`      AS `TimeFrame_Min`,
        `timeframe_max`      AS `TimeFrame_Max`,
        `ly_timeframe_value` AS `TimeFrame_Value_LY`,
        `ly_timeframe_key`   AS `TimeFrame_Key_LY`,
        `ly_timeframe_min`   AS `TimeFrame_Min_LY`,
        `ly_timeframe_max`   AS `TimeFrame_Max_LY`,
        `lp_timeframe_value` AS `TimeFrame_Value_LP`,
        `lp_timeframe_key`   AS `TimeFrame_Key_LP`,
        `lp_timeframe_min`   AS `TimeFrame_Min_LP`,
        `lp_timeframe_max`   AS `TimeFrame_Max_LP`,
        CASE
            WHEN `timeframe_label` = '年'
                THEN CONCAT(`timeframe_key`, '-12')
            WHEN `timeframe_label` = '季'
                THEN CONCAT(
                         LEFT(`timeframe_key`, 4),
                         '-',
                         LPAD(CAST(RIGHT(`timeframe_key`, 2) AS UNSIGNED) * 3, 2, '0')
                     )

            WHEN `timeframe_label` = '月'
                THEN `timeframe_value`

            ELSE NULL
        END AS `Last_Fiscal_Month`

    FROM indep_rl_dim.dim_t00_bi_fiscal_calendar
) t1

-- ★ 自关联：用 Last_Fiscal_Month 匹配月维度的 timeframe_value
LEFT JOIN indep_rl_dim.dim_t00_bi_fiscal_calendar t2
    ON  t2.`timeframe_label` = '月'
    AND t2.`timeframe_value` = t1.`Last_Fiscal_Month`

ORDER BY t1.`ID_Sort` DESC

    "),
    筛选的行 = Table.SelectRows(源, each ([TimeFrame_ID] = "Month" or [TimeFrame_ID] = "Quarter"))
in
    筛选的行

Day\Week\Month\Quarter\Year
数据样式（含 LY 字段）：
TimeFrame_ID	TimeFrame_Label	TimeFrame_Sort	TimeFrame_Value	TimeFrame_Key	ID_Sort	    TimeFrame_Min	TimeFrame_Max	TimeFrame_Value_LY	TimeFrame_Key_LY	TimeFrame_Min_LY	TimeFrame_Max_LY 	TimeFrame_Value_LP	TimeFrame_Key_LP	TimeFrame_Min_LP	TimeFrame_Max_LP
Week	        周	            2	            2026 Week14	    202614	        10130700	 2025-06-29	    2025-07-05	     2025 Week14	    202514	            2024-06-30	        2024-07-06   		2026 Week13			202613				2025-06-22			2025-06-28 
Week	        周	            2	            2025 Week45	    202545	        10127250	 2025-02-02	    2025-02-08	     2024 Week45	    202445	            2024-02-04	        2024-02-10			2025 Week44			202544				2025-01-26			2025-02-01
Day	            天	            1	            2025-01-01	    20250101	    20250101	 2025-01-01	    2025-01-01	     2024-01-01	        20240101	        2024-01-01	        2024-01-01			2024-12-31			20241231			2024-12-31			2024-12-31
Day	            天	            1	            2025-01-02	    20250102	    20250102	 2025-01-02	    2025-01-02	     2024-01-02	        20240102	        2024-01-02	        2024-01-02			2025-01-01			20250101			2025-01-01			2025-01-01
Quarter	        季	            4	            2026 Q3	        202603	        202603	     2025-09-28	    2025-12-27	     2025 Q3	        202503	            2024-09-29	        2024-12-28			2026 Q2				202602				2025-06-29			2025-09-27
Year	        年	            5	            2026	        2026	        2026	     2025-03-30	    2026-03-28	     2025	            2025	            2024-03-31	        2025-03-29			2025				2025				2024-03-31			2025-03-29
Month	        月	            3	            2026-10	        202610	        2026100	     2025-12-28	    2026-01-24	     2025-10	        202510	            2024-12-29	        2025-01-25			2026-09				202609				2025-11-30			2025-12-27

