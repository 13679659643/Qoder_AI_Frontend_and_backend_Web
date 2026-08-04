WITH base AS (
    -- ── Day 维度 ──
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
    -- 修改点：最小日期往前推12个月
    WHERE natural_date >= DATE_SUB((SELECT MIN(data_date) FROM `indep_rl_ads`.a02_e2e_boss_performance_summary_d), INTERVAL 12 MONTH)
      AND natural_date <= (SELECT MAX(data_date) FROM `indep_rl_ads`.a02_e2e_boss_performance_summary_d)

    UNION ALL
    -- ── Week 维度 ──
    SELECT
        'Week' AS TimeFrame_ID,                                                         -- 时间框架ID：周
        '周' AS TimeFrame_Label,                                                        -- 时间框架标签：周
        2 AS TimeFrame_Sort,                                                            -- 时间框架排序：2
        CONCAT(financial_year, ' Week', financial_week_num) AS TimeFrame_Value,         -- 值：财年+Week+财周数（字符串类型）
        financial_year * 100 + financial_week_num AS TimeFrame_Key,                     -- 编号：财年*100+财周数（数值类型）
        (financial_year * 100 + financial_week_num) * 50 AS ID_Sort,                   -- ID排序：周对应的日期键*50
        MIN(natural_date) AS TimeFrame_Min,                                             -- 当前财周范围内最小自然日
        MAX(natural_date) AS TimeFrame_Max                                              -- 当前财周范围内最大自然日
    FROM `indep_rl_dim`.dim_t00_calendar
    -- 修改点：最小日期往前推12个月
    WHERE natural_date >= DATE_SUB((SELECT MIN(data_date) FROM `indep_rl_ads`.a02_e2e_boss_performance_summary_d), INTERVAL 12 MONTH)
      AND natural_date <= (SELECT MAX(data_date) FROM `indep_rl_ads`.a02_e2e_boss_performance_summary_d)
    GROUP BY financial_year, financial_week_num

    UNION ALL
    -- ── Month 维度 ──
    SELECT
        'Month' AS TimeFrame_ID,                                                        -- 时间框架ID：月
        '月' AS TimeFrame_Label,                                                        -- 时间框架标签：月
        3 AS TimeFrame_Sort,                                                            -- 时间框架排序：3
        CONCAT(financial_year, '-', LPAD(financial_month_num, 2, '0')) AS TimeFrame_Value, -- 值：财年-两位财月数（字符串类型）
        financial_year * 100 + financial_month_num AS TimeFrame_Key,                    -- 编号：财年*100+财月数（数值类型）
        (financial_year * 100 + financial_month_num) * 10 AS ID_Sort,                  -- ID排序：月对应的日期键*10
        MIN(natural_date) AS TimeFrame_Min,                                             -- 当前财月范围内最小自然日
        MAX(natural_date) AS TimeFrame_Max                                              -- 当前财月范围内最大自然日
    FROM `indep_rl_dim`.dim_t00_calendar
    -- 修改点：最小日期往前推12个月
    WHERE natural_date >= DATE_SUB((SELECT MIN(data_date) FROM `indep_rl_ads`.a02_e2e_boss_performance_summary_d), INTERVAL 12 MONTH)
      AND natural_date <= (SELECT MAX(data_date) FROM `indep_rl_ads`.a02_e2e_boss_performance_summary_d)
    GROUP BY financial_year, financial_month_num

    UNION ALL
    -- ── Quarter 维度 ──
    SELECT
        'Quarter' AS TimeFrame_ID,                                                      -- 时间框架ID：季
        '季' AS TimeFrame_Label,                                                        -- 时间框架标签：季
        4 AS TimeFrame_Sort,                                                            -- 时间框架排序：4
        CONCAT(financial_year, ' Q', financial_quarter_num) AS TimeFrame_Value,         -- 值：财年+Q+财季数（字符串类型）
        financial_year * 100 + financial_quarter_num AS TimeFrame_Key,                  -- 编号：财年*100+财季数（数值类型）
        financial_year * 100 + financial_quarter_num AS ID_Sort,                        -- ID排序：季对应的日期键不变
        MIN(natural_date) AS TimeFrame_Min,                                             -- 当前财季范围内最小自然日
        MAX(natural_date) AS TimeFrame_Max                                              -- 当前财季范围内最大自然日
    FROM `indep_rl_dim`.dim_t00_calendar
    -- 修改点：最小日期往前推12个月
    WHERE natural_date >= DATE_SUB((SELECT MIN(data_date) FROM `indep_rl_ads`.a02_e2e_boss_performance_summary_d), INTERVAL 12 MONTH)
      AND natural_date <= (SELECT MAX(data_date) FROM `indep_rl_ads`.a02_e2e_boss_performance_summary_d)
    GROUP BY financial_year, financial_quarter_num

    UNION ALL
    -- ── Year 维度 ──
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
    -- 修改点：最小日期往前推12个月
    WHERE natural_date >= DATE_SUB((SELECT MIN(data_date) FROM `indep_rl_ads`.a02_e2e_boss_performance_summary_d), INTERVAL 12 MONTH)
      AND natural_date <= (SELECT MAX(data_date) FROM `indep_rl_ads`.a02_e2e_boss_performance_summary_d)
    GROUP BY financial_year
)

SELECT
    a.TimeFrame_ID,
    a.TimeFrame_Label,
    a.TimeFrame_Sort,
    a.TimeFrame_Value,
    a.TimeFrame_Key,
    a.ID_Sort,
    a.TimeFrame_Min,
    a.TimeFrame_Max,
    -- ── LY 字段：去年同期同编号时间段（self-join 查找）──
    b.TimeFrame_Value AS TimeFrame_Value_LY,                                            -- LY 时间段名称（如 2026 Week14 -> 2025 Week14）
    b.TimeFrame_Key   AS TimeFrame_Key_LY,                                              -- LY Key（如 202614 -> 202514）
    b.TimeFrame_Min   AS TimeFrame_Min_LY,                                              -- LY 起始自然日（用于事实表 data_date >= __LYTimeMin）
    b.TimeFrame_Max   AS TimeFrame_Max_LY                                               -- LY 结束自然日（用于事实表 data_date <= __LYTimeMax）
FROM base a
LEFT JOIN base b
    ON a.TimeFrame_ID = b.TimeFrame_ID
    AND (
        -- Day 粒度：自然日 -12 个月（等价 EDATE(-12)）
        (a.TimeFrame_ID = 'Day'   AND b.TimeFrame_Min = DATE_SUB(a.TimeFrame_Min, INTERVAL 12 MONTH))
        -- Week/Month/Quarter 粒度：Key - 100（财年*100+期数，减100即去年同编号）
        OR (a.TimeFrame_ID IN ('Week', 'Month', 'Quarter') AND b.TimeFrame_Key = a.TimeFrame_Key - 100)
        -- Year 粒度：Key - 1（财年减1即上一年）
        OR (a.TimeFrame_ID = 'Year' AND b.TimeFrame_Key = a.TimeFrame_Key - 1)
    )
ORDER BY a.TimeFrame_Sort, a.ID_Sort