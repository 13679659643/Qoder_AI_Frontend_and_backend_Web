-- ClickHouse 日期范围生成器 - 周大福月累计运营周报（最新月份-上周最后一天日期范围）
-- 周大福_日期范围生成_monthly_cumulative_weekly
WITH INPUT_PARAM_CTE AS (SELECT
-- CAST('2026-04-10' AS DATE) AS input_date
today() AS input_date
), -- 可替换为任意日期
     DATE_PARAM_CTE AS (SELECT input_date,                                      -- 参数日期
                               toMonday(input_date)       AS input_week_start,  -- 本周的周一
                               toStartOfMonth(input_date) AS input_month_start, -- 本月第一天
                               toStartOfYear(input_date)  AS input_year_start   -- 本年第一天
                        FROM INPUT_PARAM_CTE),
     -- 2. 月累计周报：本月1日到上周日
     DATE_RANGES_RAW_CTE AS (SELECT 'monthly_cumulative_weekly'                             AS report_type,
                                    '周大福月累计运营周报（最新月份-上周最后一天日期范围）'   AS description,
                                    input_month_start                                       AS start_date_raw,      -- 本月1日
                                    if(toDayOfMonth(input_date) < 10,
                                       input_date, -- <10号：end_date为input_date当天
                                       subtractDays(input_week_start, 1))                   AS end_date_raw,        -- >=10号：上周日
                                    subtractYears(input_month_start, 1)                     AS prev_start_date_raw, -- 去年同月1日
                                    if(toDayOfMonth(input_date) < 10,
                                       subtractYears(input_date, 1), -- <10号：去年同期对应当天
                                       subtractYears(subtractDays(input_week_start, 1), 1)) AS prev_end_date_raw    -- >=10号：去年同期对应日
                             FROM DATE_PARAM_CTE
         -- 注释掉了每月10号以后的限制
         -- WHERE toDayOfMonth(input_date) > 10  -- 业务规则：每月10号以后
     ),
     DATE_RANGES_CTE AS (SELECT report_type,
                                description,
                                -- 本期日期范围
                                formatDateTime(start_date_raw, '%Y%m%d')                             AS start_date,             -- 格式化开始日期为 YYYYMMDD
                                formatDateTime(end_date_raw, '%Y%m%d')                               AS end_date,               -- 格式化结束日期为 YYYYMMDD
                                concat(start_date, ' ~ ', end_date)                                  AS date_range_string,      -- 拼接日期范围字符串，格式：YYYYMMDD ~ YYYYMMDD
                                -- 本期周/月字段（当月1号非周一时，start_week取1号后第一个周一的ISO周）
                                concat(
                                        formatDateTime(
                                                if(toMonday(start_date_raw) = start_date_raw, start_date_raw,
                                                   addDays(toMonday(start_date_raw), 7)),
                                                '%Y'), -- 年份
                                        '-',
                                        leftPad(toString(toISOWeek(
                                                if(toMonday(start_date_raw) = start_date_raw, start_date_raw,
                                                   addDays(toMonday(start_date_raw), 7))
                                                         )), 2, '0') -- ISO周数，补零到2位
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
                                -- 上期周/月字段（去年同月1号非周一时，prev_start_week取1号后第一个周一的ISO周）
                                concat(
                                        formatDateTime(
                                                if(toMonday(prev_start_date_raw) = prev_start_date_raw,
                                                   prev_start_date_raw,
                                                   addDays(toMonday(prev_start_date_raw), 7)),
                                                '%Y'), -- 年份
                                        '-',
                                        leftPad(toString(toISOWeek(
                                                if(toMonday(prev_start_date_raw) = prev_start_date_raw,
                                                   prev_start_date_raw,
                                                   addDays(toMonday(prev_start_date_raw), 7))
                                                         )), 2, '0') -- ISO周数，补零到2位
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
                                -- 本期周日期字段（start_week周一日期、end_week周日日期）
                                formatDateTime(
                                        if(toMonday(start_date_raw) = start_date_raw, start_date_raw,
                                           addDays(toMonday(start_date_raw), 7)),
                                        '%Y%m%d')                                                    AS start_week_date,        -- start_week对应的周一日期
                                formatDateTime(addDays(toMonday(end_date_raw), 6), '%Y%m%d')         AS end_week_date,          -- end_week对应的周日日期
                                -- 上期周日期字段（prev_start_week周一日期、prev_end_week周日日期）
                                formatDateTime(
                                        if(toMonday(prev_start_date_raw) = prev_start_date_raw, prev_start_date_raw,
                                           addDays(toMonday(prev_start_date_raw), 7)),
                                        '%Y%m%d')                                                    AS prev_start_week_date,   -- prev_start_week对应的周一日期
                                formatDateTime(addDays(toMonday(prev_end_date_raw), 6), '%Y%m%d')    AS prev_end_week_date,     -- prev_end_week对应的周日日期
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
       field_value_week_date,
       field_name_month,
       field_value_month,
       field_name_prev_date,
       field_value_prev_date,
       field_name_prev_week,
       field_value_prev_week,
       prev_field_value_week_date,
       field_name_prev_month,
       field_value_prev_month,
       date_range_string,
       prev_date_range_string,
       input_date_display
FROM DATE_RANGES_CTE ARRAY
         JOIN
   ['start_date'
   , 'end_date'] AS field_name_date
   , [start_date
   , end_date] AS field_value_date
   , ['start_week'
   , 'end_week'] AS field_name_week
   , [start_week
   , end_week] AS field_value_week
   , [start_week_date
   , end_week_date] AS field_value_week_date
   , ['start_month'
   , 'end_month'] AS field_name_month
   , [start_month
   , end_month] AS field_value_month
   , ['prev_start_date'
   , 'prev_end_date'] AS field_name_prev_date
   , [prev_start_date
   , prev_end_date] AS field_value_prev_date
   , ['prev_start_week'
   , 'prev_end_week'] AS field_name_prev_week
   , [prev_start_week
   , prev_end_week] AS field_value_prev_week
   , [prev_start_week_date
   , prev_end_week_date] AS prev_field_value_week_date
   , ['prev_start_month'
   , 'prev_end_month'] AS field_name_prev_month
   , [prev_start_month
   , prev_end_month] AS field_value_prev_month