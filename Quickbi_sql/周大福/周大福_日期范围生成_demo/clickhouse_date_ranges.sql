-- ============================================================================
-- ClickHouse 日期范围生成器（含上期值）
-- ============================================================================
-- 功能说明：根据任意输入日期生成四种业务日期范围，包含本期和上期的开始/结束周/月字段
--
-- 四种报表类型：
--   1. weekly                    - 周报：上周日期范围
--   2. monthly_cumulative_weekly - 月累计周报：本月1日到上周日
--   3. monthly                   - 月报：上月日期范围
--   4. yearly_cumulative_monthly - 年累计月报：本年1月1日到上月最后一天
--
-- ============================================================================
-- BUG FIX 记录：
--   1. [原BUG] 第4种报表 prev_end_date_raw 使用 addMonths 应为 addYears（逻辑错误）
--   2. [原BUG] 所有涉及"月初日期 - 1"的写法（如 input_month_start - 1）在 ClickHouse 中
--      由于 UNION ALL 导致 Date/Date32 类型混合，裸整数减法 "- 1" 未能正确减去一天。
--      修正方案：统一使用 INTERVAL 1 DAY 语法替代裸整数减法，确保类型安全。
--      受影响位置：
--        - 第3种 end_date_raw:      input_month_start - 1 → input_month_start - INTERVAL 1 DAY
--        - 第3种 prev_end_date_raw: addMonths(...) - 1    → addMonths(...) - INTERVAL 1 DAY
--        - 第4种 end_date_raw:      input_month_start - 1 → input_month_start - INTERVAL 1 DAY
--        - 第4种 prev_end_date_raw: addYears(...) - 1     → addYears(...) - INTERVAL 1 DAY
--   3. 拼接符号从 "-" 改为 "~"
--
-- ============================================================================
-- 自测记录（input_date = 2026-05-23，星期六）
-- 基础参数：
--   input_week_start  = toMonday(2026-05-23)       = 2026-05-18（本周一）
--   input_month_start = toStartOfMonth(2026-05-23)  = 2026-05-01
--   input_year_start  = toStartOfYear(2026-05-23)   = 2026-01-01
--
-- 1. weekly（周报）:
--    本期: 2026/05/11 ~ 2026/05/17
--    上期: 2026/05/04 ~ 2026/05/10
--
-- 2. monthly_cumulative_weekly（月累计周报）:
--    本期: 2026/05/01 ~ 2026/05/17
--    上期: 2026/04/01 ~ 2026/04/17
--
-- 3. monthly（月报）:
--    本期: 2026/04/01 ~ 2026/04/30  （input_month_start - INTERVAL 1 DAY = 2026-05-01 - 1天 = 2026-04-30）
--    上期: 2026/03/01 ~ 2026/03/31  （addMonths(2026-05-01,-1) - INTERVAL 1 DAY = 2026-04-01 - 1天 = 2026-03-31）
--
-- 4. yearly_cumulative_monthly（年累计月报）:
--    本期: 2026/01/01 ~ 2026/04/30  （input_month_start - INTERVAL 1 DAY = 2026-05-01 - 1天 = 2026-04-30）
--    上期: 2025/01/01 ~ 2025/04/30  （addYears(2026-05-01,-1) - INTERVAL 1 DAY = 2025-05-01 - 1天 = 2025-04-30）
-- ============================================================================

WITH INPUT_PARAM_CTE AS (
  SELECT
    CAST('2026-05-23' AS DATE) AS input_date
    -- today() AS input_date  -- 生产环境可替换为 today()
),

DATE_PARAM_CTE AS (
  SELECT
    input_date,                                        -- 参数日期
    toMonday(input_date) AS input_week_start,          -- 本周的周一
    toStartOfMonth(input_date) AS input_month_start,   -- 本月第一天
    toStartOfYear(input_date) AS input_year_start      -- 本年第一天
  FROM
    INPUT_PARAM_CTE
),

DATE_RANGES_RAW_CTE AS (

  -- ========================================================================
  -- 1. 周报：上周日期范围
  --    本期：上周一 ~ 上周日
  --    上期：上上周一 ~ 上上周日（往前推一周）
  -- ========================================================================
  SELECT
    1 AS sort_order,
    'weekly' AS report_type,
    '周大福运营周报（上周日期范围）' AS description,
    input_week_start - 7 AS start_date_raw,       -- 上周一（toMonday结果是Date类型，整数减法正常）
    input_week_start - 1 AS end_date_raw,          -- 上周日
    input_week_start - 14 AS prev_start_date_raw,  -- 上上周一
    input_week_start - 8 AS prev_end_date_raw      -- 上上周日
  FROM
    DATE_PARAM_CTE

  UNION ALL

  -- ========================================================================
  -- 2. 月累计周报：本月1日到上周日
  --    本期：本月1日 ~ 上周日
  --    上期：上月1日 ~ 上月对应日（往前推一个月）
  -- ========================================================================
  SELECT
    2 AS sort_order,
    'monthly_cumulative_weekly' AS report_type,
    '周大福月累计运营周报（最新月份~上周最后一天日期范围）' AS description,
    input_month_start AS start_date_raw,                        -- 本月1日
    input_week_start - 1 AS end_date_raw,                       -- 上周日
    addMonths(input_month_start, -1) AS prev_start_date_raw,    -- 上月1日
    addMonths(input_week_start - 1, -1) AS prev_end_date_raw    -- 上月对应日
  FROM
    DATE_PARAM_CTE

  UNION ALL

  -- ========================================================================
  -- 3. 月报：上月日期范围
  --    本期：上月第一天 ~ 上月最后一天
  --    上期：上上月第一天 ~ 上上月最后一天（往前推一个月）
  --    [FIX] 使用 INTERVAL 1 DAY 替代裸整数 - 1，避免 Date/Date32 类型混合问题
  -- ========================================================================
  SELECT
    3 AS sort_order,
    'monthly' AS report_type,
    '周大福运营月报（上月日期范围）' AS description,
    addMonths(input_month_start, -1) AS start_date_raw,                      -- 上月第一天
    input_month_start - INTERVAL 1 DAY AS end_date_raw,                      -- [FIXED] 上月最后一天（本月1日减1天）
    addMonths(input_month_start, -2) AS prev_start_date_raw,                 -- 上上月第一天
    addMonths(input_month_start, -1) - INTERVAL 1 DAY AS prev_end_date_raw   -- [FIXED] 上上月最后一天（上月1日减1天）
  FROM
    DATE_PARAM_CTE

  UNION ALL

  -- ========================================================================
  -- 4. 年累计月报：本年1月1日到上月最后一天
  --    本期：本年1月1日 ~ 上月最后一天
  --    上期：去年1月1日 ~ 去年同期上月最后一天（往前推一年）
  --    [FIX] prev_end 原公式 addMonths(...,-1)-1 逻辑错误，改为 addYears(...,-1)
  --    [FIX] 使用 INTERVAL 1 DAY 替代裸整数 - 1
  -- ========================================================================
  SELECT
    4 AS sort_order,
    'yearly_cumulative_monthly' AS report_type,
    '周大福年累计运营月报（最新年份~上月最后一天日期范围）' AS description,
    input_year_start AS start_date_raw,                                      -- 本年1月1日
    input_month_start - INTERVAL 1 DAY AS end_date_raw,                      -- [FIXED] 上月最后一天（本月1日减1天）
    addYears(input_year_start, -1) AS prev_start_date_raw,                   -- 去年1月1日
    addYears(input_month_start, -1) - INTERVAL 1 DAY AS prev_end_date_raw    -- [FIXED] 去年同期上月最后一天
  FROM
    DATE_PARAM_CTE
)

SELECT
  report_type,
  description,

  -- 本期日期范围
  formatDateTime(start_date_raw, '%Y/%m/%d') AS start_date,       -- 格式化开始日期
  formatDateTime(end_date_raw, '%Y/%m/%d') AS end_date,           -- 格式化结束日期
  concat(start_date, '~', end_date) AS date_range_string,         -- 拼接日期范围字符串（用 ~ 分隔）

  -- 本期周字段（ISO周，格式：YYYY-WW）
  concat(
    formatDateTime(start_date_raw, '%Y'),
    '-',
    leftPad(toString(toISOWeek(start_date_raw)), 2, '0')
  ) AS start_week,

  concat(
    formatDateTime(end_date_raw, '%Y'),
    '-',
    leftPad(toString(toISOWeek(end_date_raw)), 2, '0')
  ) AS end_week,

  -- 本期月字段（格式：YYYY-MM）
  concat(
    formatDateTime(start_date_raw, '%Y'),
    '-',
    leftPad(toString(toMonth(start_date_raw)), 2, '0')
  ) AS start_month,

  concat(
    formatDateTime(end_date_raw, '%Y'),
    '-',
    leftPad(toString(toMonth(end_date_raw)), 2, '0')
  ) AS end_month,

  -- 上期日期范围
  formatDateTime(prev_start_date_raw, '%Y/%m/%d') AS prev_start_date,     -- 上期开始日期
  formatDateTime(prev_end_date_raw, '%Y/%m/%d') AS prev_end_date,         -- 上期结束日期
  concat(prev_start_date, '~', prev_end_date) AS prev_date_range_string,  -- 上期日期范围字符串（用 ~ 分隔）

  -- 上期周字段（ISO周，格式：YYYY-WW）
  concat(
    formatDateTime(prev_start_date_raw, '%Y'),
    '-',
    leftPad(toString(toISOWeek(prev_start_date_raw)), 2, '0')
  ) AS prev_start_week,

  concat(
    formatDateTime(prev_end_date_raw, '%Y'),
    '-',
    leftPad(toString(toISOWeek(prev_end_date_raw)), 2, '0')
  ) AS prev_end_week,

  -- 上期月字段（格式：YYYY-MM）
  concat(
    formatDateTime(prev_start_date_raw, '%Y'),
    '-',
    leftPad(toString(toMonth(prev_start_date_raw)), 2, '0')
  ) AS prev_start_month,

  concat(
    formatDateTime(prev_end_date_raw, '%Y'),
    '-',
    leftPad(toString(toMonth(prev_end_date_raw)), 2, '0')
  ) AS prev_end_month,

  -- 额外信息：当前输入日期
  formatDateTime((SELECT input_date FROM INPUT_PARAM_CTE), '%Y/%m/%d') AS input_date_display

FROM
  DATE_RANGES_RAW_CTE
ORDER BY
  sort_order;
