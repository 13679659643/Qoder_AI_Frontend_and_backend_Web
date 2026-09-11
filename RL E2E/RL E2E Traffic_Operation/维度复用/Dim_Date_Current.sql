let
    源 = Odbc.Query("dsn=bytehouse_rl", "
-- ======================================== 
-- SQL: 本期日期维度数据 
-- 用途: Power BI 日期表加载，用于""本期""筛选器 
-- 表: indep_rl_ads.a05_e2e_paid_media_channel_data 
-- 说明:  
-- - dt 和 data_date 转为 DATE 类型 
-- - etl_time 保持原始 STRING 保留时间部分 
-- - 提取完整的日期维度字段 
-- ========================================  
SELECT 
    DISTINCT etl_time                           AS `数据更新时间`,
    STR_TO_DATE(dt, '%Y-%m-%d')                 AS `分区字段_数据快照日期`,     
    data_type                                   AS `数据类型`,     
    STR_TO_DATE(data_date, '%Y-%m-%d')          AS `数据日期`,     
    data_week                                   AS `数据周`,     
    data_week_name                              AS `数据周名称`,     
    data_month                                  AS `数据月份`,     
    data_month_name                             AS `数据月份名称`,     
    data_quarter                                AS `数据季度`,     
    data_quarter_name                           AS `数据季度名称`,     
    data_year                                   AS `数据年份`,     
    data_year_name                              AS `数据年份名称` 
FROM indep_rl_ads.a05_e2e_paid_media_channel_data_d 
    WHERE data_type = 'day' ORDER BY STR_TO_DATE(data_date, '%Y-%m-%d');
    "),
    筛选的行 = Table.SelectRows(源, each ([数据日期] <> null))
in
    筛选的行


let
    源 = Odbc.Query(DBConnection, "
-- ======================================== 
-- SQL: 本期日期维度数据 
-- 用途: Power BI 日期表加载，用于""本期""筛选器 
-- 表: indep_rl_ads.a05_e2e_paid_media_channel_data 
-- 说明:  
-- - dt 和 data_date 转为 DATE 类型 
-- - etl_time 保持原始 STRING 保留时间部分 
-- - 提取完整的日期维度字段 
-- ========================================  
SELECT 
    DISTINCT etl_time                           AS `数据更新时间`,
    STR_TO_DATE(dt, '%Y-%m-%d')                 AS `分区字段_数据快照日期`,     
    data_type                                   AS `数据类型`,     
    STR_TO_DATE(data_date, '%Y-%m-%d')          AS `数据日期`,     
    data_week                                   AS `数据周`,     
    data_week_name                              AS `数据周名称`,     
    data_month                                  AS `数据月份`,     
    data_month_name                             AS `数据月份名称`,     
    data_quarter                                AS `数据季度`,     
    data_quarter_name                           AS `数据季度名称`,     
    data_year                                   AS `数据年份`,     
    data_year_name                              AS `数据年份名称` 
FROM indep_rl_ads.a05_e2e_paid_media_channel_data_d 
    WHERE data_type = 'day' ORDER BY STR_TO_DATE(data_date, '%Y-%m-%d');
    "),
    筛选的行 = Table.SelectRows(源, each ([数据日期] <> null))
in
    筛选的行