let
    源 = Odbc.Query("dsn=bytehouse_rl", 
    "	-- ========================================
-- SQL: 获取事实表最大财月
-- 表: indep_rl_ads.a03_e2e_customer_data_m
-- 说明: data_month 为 String 类型，格式 YYYYMM
-- 输出：财月 Data cutoff：2027-05
-- ========================================
SELECT 
    CONCAT(
        '财月 Data cutoff：',
        DATE_FORMAT(
            STR_TO_DATE(CONCAT(MAX(data_month), '01'), '%Y%m%d'),
            '%Y-%m'
        )
    ) AS `Constants_Date_Max_m`
FROM indep_rl_ads.a03_e2e_customer_data_m

")
in
    源