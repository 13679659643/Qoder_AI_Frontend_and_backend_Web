let
    源 = Odbc.Query("dsn=bytehouse_rl", 
    "
WITH dim_t00_bi_fiscal_calendar AS (
    SELECT t1.*
    FROM indep_rl_dim.dim_t00_bi_fiscal_calendar t1
    -- where t1.timeframe_max < current_date()
),
-- ★ 财年小维表：每年只有一行（新增 timeframe_value）
fiscal_year AS (
    SELECT
        timeframe_key      AS fiscal_year_key,
        timeframe_value    AS fiscal_year_value,          -- ★ 新增
        timeframe_min      AS fiscal_year_first_day,
        timeframe_max      AS fiscal_year_last_day
    FROM indep_rl_dim.dim_t00_bi_fiscal_calendar
    WHERE timeframe_id = 'Year'
)
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
    t2.`lp_timeframe_max` AS `Last_Fiscal_Month_Max_LP`,
    -- ★ 财年第一天
    fy.`fiscal_year_first_day` AS `Fiscal_Year_First_Day`,
    -- ★ 财年最后一天
    fy.`fiscal_year_last_day` AS `Fiscal_Year_Last_Day`,
    -- ★ 财月第一天（TimeFrame_Max 所在财月）
    fm.`timeframe_min` AS `Fiscal_Month_First_Day`,
    -- ★ 财月最后一天（TimeFrame_Max 所在财月）
    fm.`timeframe_max` AS `Fiscal_Month_Last_Day`,

    -- ★★★ 新增：TimeFrame_Max 所在月/年的 timeframe_value ★★★
    fm.`timeframe_value`  AS `TimeFrame_Max_Month_Value`,
    fy.`fiscal_year_value` AS `TimeFrame_Max_Year_Value`,

    -- ★★★ 新增：TimeFrame_Min 所在月/年的 timeframe_value ★★★
    fm_min.`timeframe_value` AS `TimeFrame_Min_Month_Value`,
    fy_min.`fiscal_year_value` AS `TimeFrame_Min_Year_Value`

FROM (
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
                         LPAD(CAST(RIGHT(`timeframe_key`, 2) AS INT) * 3, 2, '0')
                     )
            WHEN `timeframe_label` = '月'
                THEN `timeframe_value`
            ELSE NULL
        END AS `Last_Fiscal_Month`
    FROM dim_t00_bi_fiscal_calendar
) t1

-- ★ 自关联：Last_Fiscal_Month
LEFT JOIN dim_t00_bi_fiscal_calendar t2
    ON  t2.`timeframe_label` = '月'
    AND t2.`timeframe_value` = t1.`Last_Fiscal_Month`

-- ★ 财年关联（TimeFrame_Max 所在年）
LEFT JOIN fiscal_year fy
    ON t1.`TimeFrame_Max` BETWEEN fy.`fiscal_year_first_day` AND fy.`fiscal_year_last_day`

-- ★ 财月关联（TimeFrame_Max 所在月）
LEFT JOIN dim_t00_bi_fiscal_calendar fm
    ON  fm.`timeframe_label` = '月'
    AND t1.`TimeFrame_Max` BETWEEN fm.`timeframe_min` AND fm.`timeframe_max`

-- ★★★ 新增：TimeFrame_Min 所在月 ★★★
LEFT JOIN dim_t00_bi_fiscal_calendar fm_min
    ON  fm_min.`timeframe_label` = '月'
    AND t1.`TimeFrame_Min` BETWEEN fm_min.`timeframe_min` AND fm_min.`timeframe_max`

-- ★★★ 新增：TimeFrame_Min 所在年 ★★★
LEFT JOIN fiscal_year fy_min
    ON t1.`TimeFrame_Min` BETWEEN fy_min.`fiscal_year_first_day` AND fy_min.`fiscal_year_last_day`

WHERE (t1.`TimeFrame_ID` = 'Day' AND t1.`timeframe_value` >='2025-01-01' AND t1.`timeframe_value` < CURDATE())
   OR (t1.`TimeFrame_ID` = 'Week' AND t1.`TimeFrame_Key` >=202540)
   OR (t1.`TimeFrame_ID` = 'Month' AND t1.`TimeFrame_Key` >=202510)
   OR (t1.`TimeFrame_ID` = 'Quarter' AND t1.`TimeFrame_Key` >=202504)
   OR (t1.`TimeFrame_ID` = 'Year' AND t1.`TimeFrame_Key` >=2025)
ORDER BY t1.`ID_Sort` DESC;

    ")
in
    源