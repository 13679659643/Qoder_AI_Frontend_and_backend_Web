SELECT 
	    'Day' AS TimeFrame_ID,                                                          -- 时间框架ID：天
	    '天' AS TimeFrame_Label,                                                        -- 时间框架标签：天
	    1 AS TimeFrame_Sort,                                                            -- 时间框架排序：1
	    CAST(natural_date AS CHAR) AS TimeFrame_Value,                                  -- 值：自然日（字符串类型）
	    date_key AS TimeFrame_Key,                                                      -- 编号：日期键（数值类型）
	    date_key AS ID_Sort,                                                            -- ID排序：天的值取编号（日期键）
	    natural_date AS TimeFrame_Min,                                                  -- 最小自然日
	    natural_date AS TimeFrame_Max                                                   -- 最大自然日
	FROM `indep_rl_dim`.dim_t00_calendar
	WHERE natural_date >= (SELECT MIN(data_date) FROM `indep_rl_ads`.a05_e2e_paid_media_summary_d)
	  AND natural_date <= (SELECT MAX(data_date) FROM `indep_rl_ads`.a05_e2e_paid_media_summary_d)
	UNION ALL
	-- 周维度数据抽取
	SELECT 
	    'Week' AS TimeFrame_ID,                                                         -- 时间框架ID：周
	    '周' AS TimeFrame_Label,                                                        -- 时间框架标签：周
	    2 AS TimeFrame_Sort,                                                            -- 时间框架排序：2
	    CONCAT(financial_year, ' Week', financial_week_num) AS TimeFrame_Value,          -- 值：财年+Week+财周数（字符串类型）
	    financial_year * 100 + financial_week_num AS TimeFrame_Key,                     -- 编号：财年*100+财周数（数值类型）
	    (financial_year * 100 + financial_week_num) * 50 AS ID_Sort,                    -- ID排序：周对应的日期键*50
	    MIN(natural_date) AS TimeFrame_Min,                                             -- 当前财周范围内最小自然日
	    MAX(natural_date) AS TimeFrame_Max                                              -- 当前财周范围内最大自然日
	FROM `indep_rl_dim`.dim_t00_calendar
	WHERE natural_date >= (SELECT MIN(data_date) FROM `indep_rl_ads`.a05_e2e_paid_media_summary_d)
	  AND natural_date <= (SELECT MAX(data_date) FROM `indep_rl_ads`.a05_e2e_paid_media_summary_d)
	GROUP BY financial_year, financial_week_num
	UNION ALL
	-- 月维度数据抽取
	SELECT 
	    'Month' AS TimeFrame_ID,                                                        -- 时间框架ID：月
	    '月' AS TimeFrame_Label,                                                        -- 时间框架标签：月
	    3 AS TimeFrame_Sort,                                                            -- 时间框架排序：3
	    CONCAT(financial_year, '-', LPAD(financial_month_num, 2, '0')) AS TimeFrame_Value, -- 值：财年-两位财月数（字符串类型）
	    financial_year * 100 + financial_month_num AS TimeFrame_Key,                    -- 编号：财年*100+财月数（数值类型）
	    (financial_year * 100 + financial_month_num) * 10 AS ID_Sort,                   -- ID排序：月对应的日期键*10
	    MIN(natural_date) AS TimeFrame_Min,                                             -- 当前财月范围内最小自然日
	    MAX(natural_date) AS TimeFrame_Max                                              -- 当前财月范围内最大自然日
	FROM `indep_rl_dim`.dim_t00_calendar
	WHERE natural_date >= (SELECT MIN(data_date) FROM `indep_rl_ads`.a05_e2e_paid_media_summary_d)
	  AND natural_date <= (SELECT MAX(data_date) FROM `indep_rl_ads`.a05_e2e_paid_media_summary_d)
	GROUP BY financial_year, financial_month_num
	UNION ALL
	-- 季度维度数据抽取
	SELECT 
	    'Quarter' AS TimeFrame_ID,                                                      -- 时间框架ID：季
	    '季' AS TimeFrame_Label,                                                        -- 时间框架标签：季
	    4 AS TimeFrame_Sort,                                                            -- 时间框架排序：4
	    CONCAT(financial_year, ' Q', financial_quarter_num) AS TimeFrame_Value,          -- 值：财年+Q+财季数（字符串类型）
	    financial_year * 100 + financial_quarter_num AS TimeFrame_Key,                  -- 编号：财年*100+财季数（数值类型）
	    financial_year * 100 + financial_quarter_num AS ID_Sort,                        -- ID排序：季对应的日期键不变
	    MIN(natural_date) AS TimeFrame_Min,                                             -- 当前财季范围内最小自然日
	    MAX(natural_date) AS TimeFrame_Max                                              -- 当前财季范围内最大自然日
	FROM `indep_rl_dim`.dim_t00_calendar
	WHERE natural_date >= (SELECT MIN(data_date) FROM `indep_rl_ads`.a05_e2e_paid_media_summary_d)
	  AND natural_date <= (SELECT MAX(data_date) FROM `indep_rl_ads`.a05_e2e_paid_media_summary_d)
	GROUP BY financial_year, financial_quarter_num
	UNION ALL
	-- 年维度数据抽取
	SELECT 
	    'Year' AS TimeFrame_ID,                                                         -- 时间框架ID：年
	    '年' AS TimeFrame_Label,                                                        -- 时间框架标签：年
	    5 AS TimeFrame_Sort,                                                            -- 时间框架排序：5
	    CAST(financial_year AS CHAR) AS TimeFrame_Value,                                -- 值：财年（字符串类型）
	    financial_year AS TimeFrame_Key,                                                -- 编号：财年（数值类型）
	    financial_year AS ID_Sort,                                                      -- ID排序：年对应的日期键不变
	    MIN(natural_date) AS TimeFrame_Min,                                             -- 当前财年范围内最小自然日
	    MAX(natural_date) AS TimeFrame_Max                                              -- 当前财年范围内最大自然日
	FROM `indep_rl_dim`.dim_t00_calendar
	WHERE natural_date >= (SELECT MIN(data_date) FROM `indep_rl_ads`.a05_e2e_paid_media_summary_d)
	  AND natural_date <= (SELECT MAX(data_date) FROM `indep_rl_ads`.a05_e2e_paid_media_summary_d)
	GROUP BY financial_year



let
    源 = Odbc.Query("dsn=bytehouse_rl", 
    "
	"),
    更改的类型 = Table.TransformColumnTypes(源,{{"TimeFrame_Min", type date}, {"TimeFrame_Max", type date}})
in
    更改的类型

Day\Week\Month\Quarter\Year
数据样式：
TimeFrame_ID	TimeFrame_Label	TimeFrame_Sort	TimeFrame_Value	TimeFrame_Key	ID_Sort	TimeFrame_Min	TimeFrame_Max
Week	周	2	2026 Week14	202614	10130700	2025-06-29	2025-07-05
Week	周	2	2025 Week45	202545	10127250	2025-02-02	2025-02-08
Week	周	2	2026 Week19	202619	10130950	2025-08-03	2025-08-09
Day	天	1	2025-01-01	20250101	20250101	2025-01-01	2025-01-01
Day	天	1	2025-01-02	20250102	20250102	2025-01-02	2025-01-02
Day	天	1	2025-01-03	20250103	20250103	2025-01-03	2025-01-03
Quarter	季	4	2026 Q3	202603	202603	2025-09-28	2025-12-27
Quarter	季	4	2026 Q2	202602	202602	2025-06-29	2025-09-27
Quarter	季	4	2027 Q1	202701	202701	2026-03-29	2026-06-27
Year	年	5	2026	2026	2026	2025-03-30	2026-03-28
Year	年	5	2025	2025	2025	2025-01-01	2025-03-29
Year	年	5	2027	2027	2027	2026-03-29	2026-08-05
Month	月	3	2026-10	202610	2026100	2025-12-28	2026-01-24
Month	月	3	2027-02	202702	2027020	2026-04-26	2026-05-23
Month	月	3	2026-06	202606	2026060	2025-08-24	2025-09-27
