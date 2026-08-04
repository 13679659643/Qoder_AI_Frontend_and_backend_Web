-- ============================================================
-- 测试 SQL: Overview_Sales_DemandSLS_SLSPenetration_solution
-- 饼图 + 柱形图/趋势图(Demand SLS, SLS Penetration 的 TY/LY 版本)
-- 测试参数:
--   TY 当期: 2026-01-01 ~ 2026-07-30
--   LY 去年同期: 2025-01-01 ~ 2025-07-30
--   currency: RMB (FXRate=1)
--   fulfillment_calc_type: "Exclude orders cancelled in pay date"
--   calc_type: payment
-- 底表: `indep_rl_ads`.a02_e2e_boss_performance_summary_d
-- ============================================================

-- ------------------------------------------------------------
-- 1. 饼图: Demand SLS by store_name (按店铺占比)
--    公式: SUM(o2o_sales_amt) / FXRate(RMB=1)
--    金额类, 需除汇率
-- ------------------------------------------------------------

-- 1.1 按 store_name 分组的 Demand SLS 及占比
SELECT
    store_name,
    SUM(o2o_sales_amt) / 1.0 AS Demand_SLS_Value,
    SUM(o2o_sales_amt) * 1.0
    / NULLIF(SUM(SUM(o2o_sales_amt)) OVER(), 0) AS Demand_SLS_Share
FROM `indep_rl_ads`.a02_e2e_boss_performance_summary_d
WHERE calc_type = 'payment'
  AND fulfillment_calc_type = 'Exclude orders cancelled in pay date'
  AND data_date BETWEEN '2026-01-01' AND '2026-07-30'
GROUP BY store_name
ORDER BY Demand_SLS_Value DESC;

-- 1.2 全局汇总 Demand SLS
SELECT
    SUM(o2o_sales_amt) / 1.0 AS Demand_SLS_Total
FROM `indep_rl_ads`.a02_e2e_boss_performance_summary_d
WHERE calc_type = 'payment'
  AND fulfillment_calc_type = 'Exclude orders cancelled in pay date'
  AND data_date BETWEEN '2026-01-01' AND '2026-07-30';

-- ------------------------------------------------------------
-- 2. 柱形图/趋势图: TY/LY Demand SLS (所有店铺汇总, 按 timeframe 分组)
--    公式: SUM(o2o_sales_amt) / FXRate(RMB=1)
--    金额类, 需除汇率
--    注: 此处以"月"为粒度展示 TY vs LY 趋势对比
-- ------------------------------------------------------------

-- 2.1 按月分组的 TY/LY Demand SLS
SELECT
    DATE_FORMAT(data_date, '%Y-%m') AS year_month,
    SUM(CASE WHEN data_date BETWEEN '2026-01-01' AND '2026-07-30' THEN o2o_sales_amt ELSE 0 END) / 1.0 AS TY_Demand_SLS,
    SUM(CASE WHEN data_date BETWEEN '2025-01-01' AND '2025-07-30' THEN o2o_sales_amt ELSE 0 END) / 1.0 AS LY_Demand_SLS
FROM `indep_rl_ads`.a02_e2e_boss_performance_summary_d
WHERE calc_type = 'payment'
  AND fulfillment_calc_type = 'Exclude orders cancelled in pay date'
  AND data_date BETWEEN '2025-01-01' AND '2026-07-30'
GROUP BY DATE_FORMAT(data_date, '%Y-%m')
ORDER BY year_month;

-- 2.2 全局 TY/LY Demand SLS 汇总(整个时间区间)
SELECT
    SUM(CASE WHEN data_date BETWEEN '2026-01-01' AND '2026-07-30' THEN o2o_sales_amt ELSE 0 END) / 1.0 AS TY_Demand_SLS_Total,
    SUM(CASE WHEN data_date BETWEEN '2025-01-01' AND '2025-07-30' THEN o2o_sales_amt ELSE 0 END) / 1.0 AS LY_Demand_SLS_Total,
    CASE
        WHEN SUM(CASE WHEN data_date BETWEEN '2025-01-01' AND '2025-07-30' THEN o2o_sales_amt ELSE 0 END) = 0 THEN NULL
        ELSE SUM(CASE WHEN data_date BETWEEN '2026-01-01' AND '2026-07-30' THEN o2o_sales_amt ELSE 0 END)
           / SUM(CASE WHEN data_date BETWEEN '2025-01-01' AND '2025-07-30' THEN o2o_sales_amt ELSE 0 END) - 1
    END AS Demand_SLS_vs_LY
FROM `indep_rl_ads`.a02_e2e_boss_performance_summary_d
WHERE calc_type = 'payment'
  AND fulfillment_calc_type = 'Exclude orders cancelled in pay date'
  AND data_date BETWEEN '2025-01-01' AND '2026-07-30';

-- ------------------------------------------------------------
-- 3. 柱形图/趋势图: TY/LY SLS Penetration (所有店铺汇总, 按 timeframe 分组)
--    公式: SUM(o2o_sales_amt) / SUM(sales_amt)
--    比率类, 不除汇率(分子分母同币种相除自动抵消)
-- ------------------------------------------------------------

-- 3.1 按月分组的 TY/LY SLS Penetration
SELECT
    DATE_FORMAT(data_date, '%Y-%m') AS year_month,
    SUM(CASE WHEN data_date BETWEEN '2026-01-01' AND '2026-07-30' THEN o2o_sales_amt ELSE 0 END)
    / NULLIF(SUM(CASE WHEN data_date BETWEEN '2026-01-01' AND '2026-07-30' THEN sales_amt ELSE 0 END), 0) AS TY_SLS_Penetration,
    SUM(CASE WHEN data_date BETWEEN '2025-01-01' AND '2025-07-30' THEN o2o_sales_amt ELSE 0 END)
    / NULLIF(SUM(CASE WHEN data_date BETWEEN '2025-01-01' AND '2025-07-30' THEN sales_amt ELSE 0 END), 0) AS LY_SLS_Penetration
FROM `indep_rl_ads`.a02_e2e_boss_performance_summary_d
WHERE calc_type = 'payment'
  AND fulfillment_calc_type = 'Exclude orders cancelled in pay date'
  AND data_date BETWEEN '2025-01-01' AND '2026-07-30'
GROUP BY DATE_FORMAT(data_date, '%Y-%m')
ORDER BY year_month;

-- 3.2 全局 TY/LY SLS Penetration 汇总
SELECT
    SUM(CASE WHEN data_date BETWEEN '2026-01-01' AND '2026-07-30' THEN o2o_sales_amt ELSE 0 END)
    / NULLIF(SUM(CASE WHEN data_date BETWEEN '2026-01-01' AND '2026-07-30' THEN sales_amt ELSE 0 END), 0) AS TY_SLS_Penetration_Total,
    SUM(CASE WHEN data_date BETWEEN '2025-01-01' AND '2025-07-30' THEN o2o_sales_amt ELSE 0 END)
    / NULLIF(SUM(CASE WHEN data_date BETWEEN '2025-01-01' AND '2025-07-30' THEN sales_amt ELSE 0 END), 0) AS LY_SLS_Penetration_Total,
    (SUM(CASE WHEN data_date BETWEEN '2026-01-01' AND '2026-07-30' THEN o2o_sales_amt ELSE 0 END)
     / NULLIF(SUM(CASE WHEN data_date BETWEEN '2026-01-01' AND '2026-07-30' THEN sales_amt ELSE 0 END), 0))
    -
    (SUM(CASE WHEN data_date BETWEEN '2025-01-01' AND '2025-07-30' THEN o2o_sales_amt ELSE 0 END)
     / NULLIF(SUM(CASE WHEN data_date BETWEEN '2025-01-01' AND '2025-07-30' THEN sales_amt ELSE 0 END), 0)) AS SLS_Penetration_vs_LY
FROM `indep_rl_ads`.a02_e2e_boss_performance_summary_d
WHERE calc_type = 'payment'
  AND fulfillment_calc_type = 'Exclude orders cancelled in pay date'
  AND data_date BETWEEN '2025-01-01' AND '2026-07-30';

-- ------------------------------------------------------------
-- 4. 按店铺分组的 TY/LY Demand SLS & SLS Penetration (饼图 + 趋势图组合验证)
--    用于验证饼图各扇区在 TY/LY 下的对比
-- ------------------------------------------------------------

-- 4.1 按 store_name 分组的 TY/LY Demand SLS
SELECT
    store_name,
    SUM(CASE WHEN data_date BETWEEN '2026-01-01' AND '2026-07-30' THEN o2o_sales_amt ELSE 0 END) / 1.0 AS TY_Demand_SLS,
    SUM(CASE WHEN data_date BETWEEN '2025-01-01' AND '2025-07-30' THEN o2o_sales_amt ELSE 0 END) / 1.0 AS LY_Demand_SLS,
    CASE
        WHEN SUM(CASE WHEN data_date BETWEEN '2025-01-01' AND '2025-07-30' THEN o2o_sales_amt ELSE 0 END) = 0 THEN NULL
        ELSE SUM(CASE WHEN data_date BETWEEN '2026-01-01' AND '2026-07-30' THEN o2o_sales_amt ELSE 0 END)
           / SUM(CASE WHEN data_date BETWEEN '2025-01-01' AND '2025-07-30' THEN o2o_sales_amt ELSE 0 END) - 1
    END AS Demand_SLS_vs_LY
FROM `indep_rl_ads`.a02_e2e_boss_performance_summary_d
WHERE calc_type = 'payment'
  AND fulfillment_calc_type = 'Exclude orders cancelled in pay date'
  AND data_date BETWEEN '2025-01-01' AND '2026-07-30'
GROUP BY store_name
ORDER BY TY_Demand_SLS DESC;

-- 4.2 按 store_name 分组的 TY/LY SLS Penetration
SELECT
    store_name,
    SUM(CASE WHEN data_date BETWEEN '2026-01-01' AND '2026-07-30' THEN o2o_sales_amt ELSE 0 END)
    / NULLIF(SUM(CASE WHEN data_date BETWEEN '2026-01-01' AND '2026-07-30' THEN sales_amt ELSE 0 END), 0) AS TY_SLS_Penetration,
    SUM(CASE WHEN data_date BETWEEN '2025-01-01' AND '2025-07-30' THEN o2o_sales_amt ELSE 0 END)
    / NULLIF(SUM(CASE WHEN data_date BETWEEN '2025-01-01' AND '2025-07-30' THEN sales_amt ELSE 0 END), 0) AS LY_SLS_Penetration
FROM `indep_rl_ads`.a02_e2e_boss_performance_summary_d
WHERE calc_type = 'payment'
  AND fulfillment_calc_type = 'Exclude orders cancelled in pay date'
  AND data_date BETWEEN '2025-01-01' AND '2026-07-30'
GROUP BY store_name
ORDER BY TY_SLS_Penetration DESC;
