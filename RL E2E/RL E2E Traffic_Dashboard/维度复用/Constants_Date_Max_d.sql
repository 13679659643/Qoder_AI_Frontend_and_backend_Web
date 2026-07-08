-- ========================================
-- SQL: 获取事实表最大日期
-- 表: indep_rl_ads.a05_e2e_paid_media_summary_d
-- 说明: data_date 为 String 类型，格式 YYYY-MM-DD
-- 输出：数据截至：2026-04-20/Data cutoff：2026-04-20
-- ========================================

SELECT 
    CONCAT(
        'Data cutoff：',
        DATE_FORMAT(
            MAX(STR_TO_DATE(data_date, '%Y-%m-%d')),
            '%Y-%m-%d'
        )
    ) AS `Constants_Date_Max`
FROM indep_rl_ads.a05_e2e_paid_media_summary_d




let
    源 = Odbc.Query("dsn=bytehouse_rl", 
    "	-- ========================================
-- SQL: 获取事实表最大日期
-- 表: indep_rl_ads.a05_e2e_paid_media_summary_d
-- 说明: data_date 为 String 类型，格式 YYYY-MM-DD
-- 输出：数据截至：2026-04-20/Data cutoff：2026-04-20
-- ========================================

SELECT 
    CONCAT(
        'Data cutoff：',
        DATE_FORMAT(
            MAX(STR_TO_DATE(data_date, '%Y-%m-%d')),
            '%Y-%m-%d'
        )
    ) AS `Constants_Date_Max`
FROM indep_rl_ads.a05_e2e_paid_media_summary_d")
in
    源