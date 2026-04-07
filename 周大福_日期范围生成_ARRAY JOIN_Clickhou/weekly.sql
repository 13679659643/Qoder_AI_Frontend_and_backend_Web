-- ClickHouse 日期范围生成器 - 周大福运营周报（上周日期范围）
-- 周大福_日期范围生成_weekly
WITH INPUT_PARAM_CTE AS (SELECT
-- CAST('2026-05-23' AS DATE) AS input_date
today() AS input_date), -- 可替换为任意日期
     DATE_PARAM_CTE AS (SELECT input_date,                                      -- 参数日期
                               toMonday(input_date)       AS input_week_start,  -- 本周的周一
                               toStartOfMonth(input_date) AS input_month_start, -- 本月第一天
                               toStartOfYear(input_date)  AS input_year_start   -- 本年第一天
                        FROM INPUT_PARAM_CTE),
     -- 1. 周报：上周日期范围
     DATE_RANGES_RAW_CTE AS (
         SELECT 'weekly'                           AS report_type,
                '周大福运营周报（上周日期范围）'     AS description,
                subtractDays(input_week_start, 7)  AS start_date_raw,      -- 上周一
                subtractDays(input_week_start, 1)  AS end_date_raw,        -- 上周日
                -- 去年同ISO周的周一：通过去年1月4日定位ISO第1周周一，再偏移到同周数
                addDays(
                    toMonday(toDate(concat(toString(toISOYear(subtractDays(input_week_start, 7)) - 1), '-01-04'))),
                    (toISOWeek(subtractDays(input_week_start, 7)) - 1) * 7
                )                                  AS prev_start_date_raw, -- 去年同周周一
                -- 去年同ISO周的周日
                addDays(
                    toMonday(toDate(concat(toString(toISOYear(subtractDays(input_week_start, 7)) - 1), '-01-04'))),
                    (toISOWeek(subtractDays(input_week_start, 7)) - 1) * 7 + 6
                )                                  AS prev_end_date_raw    -- 去年同周周日
         FROM DATE_PARAM_CTE),
     DATE_RANGES_CTE AS (
         SELECT report_type,
                description,
                -- 本期日期范围
                formatDateTime(start_date_raw, '%Y%m%d')                             AS start_date,             -- 格式化开始日期为 YYYYMMDD
                formatDateTime(end_date_raw, '%Y%m%d')                               AS end_date,               -- 格式化结束日期为 YYYYMMDD
                concat(start_date, ' ~ ', end_date)                                  AS date_range_string,      -- 拼接日期范围字符串，格式：YYYYMMDD ~ YYYYMMDD
                -- 本期周/月字段
                concat(
                        formatDateTime(start_date_raw, '%Y'), -- 年份
                        '-',
                        leftPad(toString(toISOWeek(start_date_raw)), 2, '0') -- ISO周数，补零到2位
                )                                                                    AS start_week,             -- 开始周字段
                concat(
                        formatDateTime(end_date_raw, '%Y'), -- 年份
                        '-',
                        leftPad(toString(toISOWeek(end_date_raw)), 2, '0') -- ISO周数，补零到2位
                )                                                                    AS end_week,               -- 结束周字段
                concat(
                        formatDateTime(start_date_raw, '%Y'), -- 年份
                        '-',
                        leftPad(toString(toMonth(start_date_raw)), 2, '0') -- 月份，补零到2位
                )                                                                    AS start_month,            -- 开始月字段
                concat(
                        formatDateTime(end_date_raw, '%Y'), -- 年份
                        '-',
                        leftPad(toString(toMonth(end_date_raw)), 2, '0') -- 月份，补零到2位
                )                                                                    AS end_month,              -- 结束月字段
                -- 上期日期范围
                formatDateTime(prev_start_date_raw, '%Y%m%d')                        AS prev_start_date,        -- 上期开始日期，格式为 YYYYMMDD
                formatDateTime(prev_end_date_raw, '%Y%m%d')                          AS prev_end_date,          -- 上期结束日期，格式为 YYYYMMDD
                concat(prev_start_date, ' ~ ', prev_end_date)                        AS prev_date_range_string, -- 上期日期范围字符串，格式：YYYYMMDD ~ YYYYMMDD
                -- 上期周/月字段
                concat(
                        formatDateTime(prev_start_date_raw, '%Y'), -- 年份
                        '-',
                        leftPad(toString(toISOWeek(prev_start_date_raw)), 2, '0') -- ISO周数，补零到2位
                )                                                                    AS prev_start_week,        -- 上期开始周
                concat(
                        formatDateTime(prev_end_date_raw, '%Y'), -- 年份
                        '-',
                        leftPad(toString(toISOWeek(prev_end_date_raw)), 2, '0') -- ISO周数，补零到2位
                )                                                                    AS prev_end_week,          -- 上期结束周
                concat(
                        formatDateTime(prev_start_date_raw, '%Y'), -- 年份
                        '-',
                        leftPad(toString(toMonth(prev_start_date_raw)), 2, '0') -- 月份，补零到2位
                )                                                                    AS prev_start_month,       -- 上期开始月
                concat(
                        formatDateTime(prev_end_date_raw, '%Y'), -- 年份
                        '-',
                        leftPad(toString(toMonth(prev_end_date_raw)), 2, '0') -- 月份，补零到2位
                )                                                                    AS prev_end_month,         -- 上期结束月
                -- 额外信息：当前输入日期
                formatDateTime((SELECT input_date FROM INPUT_PARAM_CTE), '%Y/%m/%d') AS input_date_display
         FROM DATE_RANGES_RAW_CTE)
-- 列转行：6组 start/end 成对字段并行 ARRAY JOIN，输出2行数据
-- date_range_string、prev_date_range_string、input_date_display 保持不变
SELECT report_type,
       description,
       field_name_date,
       field_value_date,
       field_name_week,
       field_value_week,
       field_name_month,
       field_value_month,
       field_name_prev_date,
       field_value_prev_date,
       field_name_prev_week,
       field_value_prev_week,
       field_name_prev_month,
       field_value_prev_month,
       date_range_string,
       prev_date_range_string,
       input_date_display
FROM DATE_RANGES_CTE
         ARRAY JOIN
    ['start_date', 'end_date']                 AS field_name_date,
    [start_date, end_date]                     AS field_value_date,
    ['start_week', 'end_week']                 AS field_name_week,
    [start_week, end_week]                     AS field_value_week,
    ['start_month', 'end_month']               AS field_name_month,
    [start_month, end_month]                   AS field_value_month,
    ['prev_start_date', 'prev_end_date']       AS field_name_prev_date,
    [prev_start_date, prev_end_date]           AS field_value_prev_date,
    ['prev_start_week', 'prev_end_week']       AS field_name_prev_week,
    [prev_start_week, prev_end_week]           AS field_value_prev_week,
    ['prev_start_month', 'prev_end_month']     AS field_name_prev_month,
    [prev_start_month, prev_end_month]         AS field_value_prev_month
