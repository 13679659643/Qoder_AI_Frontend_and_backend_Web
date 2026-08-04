-- ════════════════════════════════════════════════════════════════════
-- Slicer_Time_Frame 维度表（含 LY 字段）
-- 在原 Slicer_Time_Frame.sql 的 8 个字段基础上新增 4 个 LY 字段：
--   TimeFrame_Value_LY / TimeFrame_Key_LY / TimeFrame_Min_LY / TimeFrame_Max_LY
--
-- LY 含义：当前行的"去年同期同编号时间段"
--   Day     -> addMonths(Min, -12) -> 去年同日
--   Week    -> Key - 100           -> 去年同编号财周
--   Month   -> Key - 100           -> 去年同编号财月
--   Quarter -> Key - 100           -> 去年同编号财季
--   Year    -> Key - 1             -> 上一年
--
-- 实现方式：CTE base 先生成原始 8 字段，再 self-join 找 LY 行
-- ════════════════════════════════════════════════════════════════════

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



let
    源 = Odbc.Query("dsn=bytehouse_rl", 
    "
	"),
    更改的类型 = Table.TransformColumnTypes(源,{{"TimeFrame_Min", type date}, {"TimeFrame_Max", type date}, {"TimeFrame_Min_LY", type date}, {"TimeFrame_Max_LY", type date}})
in
    更改的类型

Day\Week\Month\Quarter\Year
数据样式（含 LY 字段）：
TimeFrame_ID	TimeFrame_Label	TimeFrame_Sort	TimeFrame_Value	TimeFrame_Key	ID_Sort	    TimeFrame_Min	TimeFrame_Max	TimeFrame_Value_LY	TimeFrame_Key_LY	TimeFrame_Min_LY	TimeFrame_Max_LY
Week	        周	            2	            2026 Week14	    202614	        10130700	 2025-06-29	    2025-07-05	     2025 Week14	    202514	            2024-06-30	        2024-07-06
Week	        周	            2	            2025 Week45	    202545	        10127250	 2025-02-02	    2025-02-08	     2024 Week45	    202445	            2024-02-04	        2024-02-10
Day	            天	            1	            2025-01-01	    20250101	    20250101	 2025-01-01	    2025-01-01	     2024-01-01	        20240101	        2024-01-01	        2024-01-01
Day	            天	            1	            2025-01-02	    20250102	    20250102	 2025-01-02	    2025-01-02	     2024-01-02	        20240102	        2024-01-02	        2024-01-02
Quarter	        季	            4	            2026 Q3	        202603	        202603	     2025-09-28	    2025-12-27	     2025 Q3	        202503	            2024-09-29	        2024-12-28
Year	        年	            5	            2026	        2026	        2026	     2025-03-30	    2026-03-28	     2025	            2025	            2024-03-31	        2025-03-29
Month	        月	            3	            2026-10	        202610	        2026100	     2025-12-28	    2026-01-24	     2025-10	        202510	            2024-12-29	        2025-01-25

注意：
1. LY 字段为 NULL 的情况：当期行已是维度表最早一期，self-join 找不到去年/上期对应行（如 Day 2025-01-01 减12月是 2024-01-01，若日历表不含 2024 年数据则 NULL）。DAX 中用 SELECTEDVALUE 读取会返回 BLANK，Display 度量应显示"-"。
2. Power Query 步骤"更改的类型"已同步添加 TimeFrame_Min_LY / TimeFrame_Max_LY 的日期类型转换。
3. ORDER BY 用于结果展示稳定排序，不影响 Power Query 导入。
