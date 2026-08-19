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
    t1.`First_Fiscal_Month`,
    -- ★ 自关联得到的：First_Fiscal_Month 对应的最小/最大日期
    t2.`timeframe_min`    AS `First_Fiscal_Month_Min`,
    t2.`timeframe_max`    AS `First_Fiscal_Month_Max`,
    t2.`ly_timeframe_min` AS `First_Fiscal_Month_Min_LY`,
    t2.`ly_timeframe_max` AS `First_Fiscal_Month_Max_LY`,
    t2.`lp_timeframe_min` AS `First_Fiscal_Month_Min_LP`,
    t2.`lp_timeframe_max` AS `First_Fiscal_Month_Max_LP`
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
            -- 年：取第一个财月（01）
            WHEN `timeframe_label` = '年'
                THEN CONCAT(`timeframe_key`, '-01')

            -- 季：取季度第一个月  Q1→01, Q2→04, Q3→07, Q4→10
            WHEN `timeframe_label` = '季'
                THEN CONCAT(
                         LEFT(`timeframe_key`, 4),
                         '-',
                         LPAD(
                             (CAST(RIGHT(`timeframe_key`, 2) AS UNSIGNED) - 1) * 3 + 1,
                             2, '0'
                         )
                     )

            -- 月：start_period 就是自身
            WHEN `timeframe_label` = '月'
                THEN `timeframe_value`

            ELSE NULL
        END AS `First_Fiscal_Month`

    FROM indep_rl_dim.dim_t00_bi_fiscal_calendar
) t1

-- ★ 自关联：用 First_Fiscal_Month 匹配月维度的 timeframe_value
LEFT JOIN indep_rl_dim.dim_t00_bi_fiscal_calendar t2
    ON  t2.`timeframe_label` = '月'
    AND t2.`timeframe_value` = t1.`First_Fiscal_Month`

ORDER BY t1.`ID_Sort` DESC;
    "),
    筛选的行 = Table.SelectRows(源, each ([TimeFrame_ID] <> "Day" and [TimeFrame_ID] <> "Week"))
in
    筛选的行