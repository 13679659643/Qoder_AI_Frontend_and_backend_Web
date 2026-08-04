-- ============================================================
-- 测试 SQL: Overview_Fulfillment_Summary_solution
-- 三个子模块(仅当期值, 不涉及 LY):
--   子模块五: Fulfillment% by Label (条形图, 按 brand 分组)
--   子模块六: Order Processing Efficiency by Label (条形图, 按 brand 分组)
--   子模块七: Penalty by Platform (堆积柱形图, 按 store_name 分组)
-- 测试参数:
--   当期: 2026-01-01 ~ 2026-07-30
--   currency: RMB (FXRate=1)
--   fulfillment_calc_type: "Exclude orders cancelled in pay date"
--   calc_type: fulfillment
-- 底表:
--   `indep_rl_ads`.a02_e2e_boss_performance_summary_d
--   `indep_rl_ads`.a02_e2e_boss_fulfillment_request_data_d
-- ============================================================

-- ------------------------------------------------------------
-- 子模块五: Fulfillment% by Label (按 brand 分组)
-- 公式: SUM(shipped_order_cnt) / SUM(request_order_cnt)
-- 比率类, 不除汇率
-- ------------------------------------------------------------

-- 5.1 按 brand 分组的 Fulfillment%
SELECT
    brand,
    SUM(o2o_fulfillment_shipped_order_cnt) * 1.0
    / NULLIF(SUM(o2o_fulfillment_request_order_cnt), 0) AS Fulfillment_Pct
FROM `indep_rl_ads`.a02_e2e_boss_performance_summary_d
WHERE calc_type = 'fulfillment'
  AND fulfillment_calc_type = 'Exclude orders cancelled in pay date'
  AND data_date BETWEEN '2026-01-01' AND '2026-07-30'
GROUP BY brand
ORDER BY Fulfillment_Pct DESC;

-- 5.2 全局汇总 Fulfillment%(所有 brand 合计)
SELECT
    SUM(o2o_fulfillment_shipped_order_cnt) * 1.0
    / NULLIF(SUM(o2o_fulfillment_request_order_cnt), 0) AS Fulfillment_Pct_Total
FROM `indep_rl_ads`.a02_e2e_boss_performance_summary_d
WHERE calc_type = 'fulfillment'
  AND fulfillment_calc_type = 'Exclude orders cancelled in pay date'
  AND data_date BETWEEN '2026-01-01' AND '2026-07-30';

-- ------------------------------------------------------------
-- 子模块六: Order Processing Efficiency by Label (按 brand 分组)
-- 底表: a02_e2e_boss_fulfillment_request_data_d
-- 公式:
--   Avg Store Passed   = SUM(request_times) / SUM(request_sku_qty)
--   Avg Processing Time = SUM(request_duration) / SUM(request_sku_qty)
-- 比率类, 不除汇率
-- ------------------------------------------------------------

-- 6.1 按 brand 分组的 Avg Store Passed & Avg Processing Time
SELECT
    brand,
    SUM(o2o_fulfillment_request_times) * 1.0
    / NULLIF(SUM(o2o_fulfillment_request_sku_qty), 0) AS Avg_Store_Passed,
    SUM(o2o_fulfillment_request_duration) * 1.0
    / NULLIF(SUM(o2o_fulfillment_request_sku_qty), 0) AS Avg_Processing_Time
FROM `indep_rl_ads`.a02_e2e_boss_fulfillment_request_data_d
WHERE calc_type = 'fulfillment'
  AND data_date BETWEEN '2026-01-01' AND '2026-07-30'
GROUP BY brand
ORDER BY Avg_Store_Passed DESC;

-- 6.2 全局汇总
SELECT
    SUM(o2o_fulfillment_request_times) * 1.0
    / NULLIF(SUM(o2o_fulfillment_request_sku_qty), 0) AS Avg_Store_Passed_Total,
    SUM(o2o_fulfillment_request_duration) * 1.0
    / NULLIF(SUM(o2o_fulfillment_request_sku_qty), 0) AS Avg_Processing_Time_Total
FROM `indep_rl_ads`.a02_e2e_boss_fulfillment_request_data_d
WHERE calc_type = 'fulfillment'
  AND data_date BETWEEN '2026-01-01' AND '2026-07-30';

-- ------------------------------------------------------------
-- 子模块七: Penalty by Platform (按 store_name 分组)
-- 金额类 ÷ FXRate(RMB=1); 整数类/比率类不除汇率
-- ------------------------------------------------------------

-- 7.1 金额类: Penalty Amt / OOS Penalty Amt / Delay Penalty Amt + Share
--     Penalty Amt = OOS + Delay (独立聚合再相加, 避免堆积柱形图双计)
SELECT
    store_name,
    -- 原始 RMB 值(金额类 ÷ FXRate=1)
    SUM(o2o_penalty_oos_amt) / 1.0 AS OOS_Penalty_Amt,
    SUM(o2o_penalty_delay_amt) / 1.0 AS Delay_Penalty_Amt,
    (SUM(o2o_penalty_oos_amt) + SUM(o2o_penalty_delay_amt)) / 1.0 AS Penalty_Amt,
    -- Share 类(比率, 不除汇率, 用原始 RMB 值相除)
    SUM(o2o_penalty_oos_amt) * 1.0
    / NULLIF(SUM(o2o_penalty_oos_amt) + SUM(o2o_penalty_delay_amt), 0) AS OOS_Penalty_Amt_Share,
    SUM(o2o_penalty_delay_amt) * 1.0
    / NULLIF(SUM(o2o_penalty_oos_amt) + SUM(o2o_penalty_delay_amt), 0) AS Delay_Penalty_Amt_Share
FROM `indep_rl_ads`.a02_e2e_boss_performance_summary_d
WHERE calc_type = 'fulfillment'
  AND fulfillment_calc_type = 'Exclude orders cancelled in pay date'
  AND data_date BETWEEN '2026-01-01' AND '2026-07-30'
GROUP BY store_name
ORDER BY Penalty_Amt DESC;

-- 7.2 订单数类: Penalty Order / OOS Penalty Order / Delay Penalty Order + Share
--     整数类, 不除汇率
SELECT
    store_name,
    SUM(o2o_penalty_oos_order_cnt) AS OOS_Penalty_Order,
    SUM(o2o_penalty_delay_order_cnt) AS Delay_Penalty_Order,
    SUM(o2o_penalty_oos_order_cnt) + SUM(o2o_penalty_delay_order_cnt) AS Penalty_Order,
    -- Share 类(比率, 不除汇率)
    SUM(o2o_penalty_oos_order_cnt) * 1.0
    / NULLIF(SUM(o2o_penalty_oos_order_cnt) + SUM(o2o_penalty_delay_order_cnt), 0) AS OOS_Penalty_Order_Share,
    SUM(o2o_penalty_delay_order_cnt) * 1.0
    / NULLIF(SUM(o2o_penalty_oos_order_cnt) + SUM(o2o_penalty_delay_order_cnt), 0) AS Delay_Penalty_Order_Share
FROM `indep_rl_ads`.a02_e2e_boss_performance_summary_d
WHERE calc_type = 'fulfillment'
  AND fulfillment_calc_type = 'Exclude orders cancelled in pay date'
  AND data_date BETWEEN '2026-01-01' AND '2026-07-30'
GROUP BY store_name
ORDER BY Penalty_Order DESC;

-- 7.3 全局汇总(所有店铺合计)
SELECT
    'All Stores' AS store_name,
    SUM(o2o_penalty_oos_amt) / 1.0 AS OOS_Penalty_Amt_Total,
    SUM(o2o_penalty_delay_amt) / 1.0 AS Delay_Penalty_Amt_Total,
    (SUM(o2o_penalty_oos_amt) + SUM(o2o_penalty_delay_amt)) / 1.0 AS Penalty_Amt_Total,
    SUM(o2o_penalty_oos_order_cnt) AS OOS_Penalty_Order_Total,
    SUM(o2o_penalty_delay_order_cnt) AS Delay_Penalty_Order_Total,
    SUM(o2o_penalty_oos_order_cnt) + SUM(o2o_penalty_delay_order_cnt) AS Penalty_Order_Total
FROM `indep_rl_ads`.a02_e2e_boss_performance_summary_d
WHERE calc_type = 'fulfillment'
  AND fulfillment_calc_type = 'Exclude orders cancelled in pay date'
  AND data_date BETWEEN '2026-01-01' AND '2026-07-30';
