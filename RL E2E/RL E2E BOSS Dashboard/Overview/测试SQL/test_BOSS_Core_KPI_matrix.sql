-- ============================================================
-- 测试 SQL: Overview_KPIs_BossCoreKPI_matrix_solution
-- 矩阵结构: 12 个 KPI 行 × 6 店铺 × 3 列(Act / LY / vs LY)
-- 测试参数:
--   TY 当期: 2026-01-01 ~ 2026-07-30
--   LY 去年同期: 2025-01-01 ~ 2025-07-30
--   currency: RMB (FXRate=1)
--   fulfillment_calc_type: "Exclude orders cancelled in pay date"
--   calc_type: payment(Sales 分组) / fulfillment(Fulfillment 分组)
-- 底表: `indep_rl_ads`.a02_e2e_boss_performance_summary_d
-- 注: 6 个店铺分组 = TM / JD / RLE_CN / DY_Family / DY_W / DY_MN
-- ============================================================

-- ------------------------------------------------------------
-- 1. Sales 分组 (calc_type = 'payment')
--    KPI: SLS / Demand SLS / SLS Penetration / Return / Return%
-- ------------------------------------------------------------

-- 1.1 SLS (O2O销售净额) = SUM(o2o_net_sales_amt) —— Act / LY / vs LY
--     金额类 ÷ FXRate(RMB=1), vs LY = 今年/去年 - 1
SELECT
    store_name,
    -- Act 当期
    SUM(CASE WHEN data_date BETWEEN '2026-01-01' AND '2026-07-30' THEN o2o_net_sales_amt ELSE 0 END) / 1.0 AS SLS_Act,
    -- LY 去年同期
    SUM(CASE WHEN data_date BETWEEN '2025-01-01' AND '2025-07-30' THEN o2o_net_sales_amt ELSE 0 END) / 1.0 AS SLS_LY,
    -- vs LY = 今年/去年 - 1
    CASE
        WHEN SUM(CASE WHEN data_date BETWEEN '2025-01-01' AND '2025-07-30' THEN o2o_net_sales_amt ELSE 0 END) = 0 THEN NULL
        ELSE SUM(CASE WHEN data_date BETWEEN '2026-01-01' AND '2026-07-30' THEN o2o_net_sales_amt ELSE 0 END)
           / SUM(CASE WHEN data_date BETWEEN '2025-01-01' AND '2025-07-30' THEN o2o_net_sales_amt ELSE 0 END) - 1
    END AS SLS_vs_LY
FROM `indep_rl_ads`.a02_e2e_boss_performance_summary_d
WHERE calc_type = 'payment'
  AND fulfillment_calc_type = 'Exclude orders cancelled in pay date'
  AND store_name IN ('TM', 'JD', 'RLE_CN', 'DY_Family', 'DY_W', 'DY_MN')
  AND data_date BETWEEN '2025-01-01' AND '2026-07-30'
GROUP BY store_name
ORDER BY store_name;

-- 1.2 Demand SLS (O2O退前销售额) = SUM(o2o_sales_amt) —— Act / LY / vs LY
SELECT
    store_name,
    SUM(CASE WHEN data_date BETWEEN '2026-01-01' AND '2026-07-30' THEN o2o_sales_amt ELSE 0 END) / 1.0 AS DemandSLS_Act,
    SUM(CASE WHEN data_date BETWEEN '2025-01-01' AND '2025-07-30' THEN o2o_sales_amt ELSE 0 END) / 1.0 AS DemandSLS_LY,
    CASE
        WHEN SUM(CASE WHEN data_date BETWEEN '2025-01-01' AND '2025-07-30' THEN o2o_sales_amt ELSE 0 END) = 0 THEN NULL
        ELSE SUM(CASE WHEN data_date BETWEEN '2026-01-01' AND '2026-07-30' THEN o2o_sales_amt ELSE 0 END)
           / SUM(CASE WHEN data_date BETWEEN '2025-01-01' AND '2025-07-30' THEN o2o_sales_amt ELSE 0 END) - 1
    END AS DemandSLS_vs_LY
FROM `indep_rl_ads`.a02_e2e_boss_performance_summary_d
WHERE calc_type = 'payment'
  AND fulfillment_calc_type = 'Exclude orders cancelled in pay date'
  AND store_name IN ('TM', 'JD', 'RLE_CN', 'DY_Family', 'DY_W', 'DY_MN')
  AND data_date BETWEEN '2025-01-01' AND '2026-07-30'
GROUP BY store_name
ORDER BY store_name;

-- 1.3 SLS Penetration (O2O销售渗透率) = SUM(o2o_sales_amt) / SUM(sales_amt) —— 比率类, delta_bp
SELECT
    store_name,
    -- Act
    SUM(CASE WHEN data_date BETWEEN '2026-01-01' AND '2026-07-30' THEN o2o_sales_amt ELSE 0 END)
    / NULLIF(SUM(CASE WHEN data_date BETWEEN '2026-01-01' AND '2026-07-30' THEN sales_amt ELSE 0 END), 0) AS SLS_Penetration_Act,
    -- LY
    SUM(CASE WHEN data_date BETWEEN '2025-01-01' AND '2025-07-30' THEN o2o_sales_amt ELSE 0 END)
    / NULLIF(SUM(CASE WHEN data_date BETWEEN '2025-01-01' AND '2025-07-30' THEN sales_amt ELSE 0 END), 0) AS SLS_Penetration_LY,
    -- vs LY = 今年 - 去年 (差值, ×10000 转 bp)
    (SUM(CASE WHEN data_date BETWEEN '2026-01-01' AND '2026-07-30' THEN o2o_sales_amt ELSE 0 END)
     / NULLIF(SUM(CASE WHEN data_date BETWEEN '2026-01-01' AND '2026-07-30' THEN sales_amt ELSE 0 END), 0))
    -
    (SUM(CASE WHEN data_date BETWEEN '2025-01-01' AND '2025-07-30' THEN o2o_sales_amt ELSE 0 END)
     / NULLIF(SUM(CASE WHEN data_date BETWEEN '2025-01-01' AND '2025-07-30' THEN sales_amt ELSE 0 END), 0)) AS SLS_Penetration_vs_LY
FROM `indep_rl_ads`.a02_e2e_boss_performance_summary_d
WHERE calc_type = 'payment'
  AND fulfillment_calc_type = 'Exclude orders cancelled in pay date'
  AND store_name IN ('TM', 'JD', 'RLE_CN', 'DY_Family', 'DY_W', 'DY_MN')
  AND data_date BETWEEN '2025-01-01' AND '2026-07-30'
GROUP BY store_name
ORDER BY store_name;

-- 1.4 Return (O2O退货金额) = SUM(o2o_return_amt) —— 金额类
SELECT
    store_name,
    SUM(CASE WHEN data_date BETWEEN '2026-01-01' AND '2026-07-30' THEN o2o_return_amt ELSE 0 END) / 1.0 AS Return_Act,
    SUM(CASE WHEN data_date BETWEEN '2025-01-01' AND '2025-07-30' THEN o2o_return_amt ELSE 0 END) / 1.0 AS Return_LY,
    CASE
        WHEN SUM(CASE WHEN data_date BETWEEN '2025-01-01' AND '2025-07-30' THEN o2o_return_amt ELSE 0 END) = 0 THEN NULL
        ELSE SUM(CASE WHEN data_date BETWEEN '2026-01-01' AND '2026-07-30' THEN o2o_return_amt ELSE 0 END)
           / SUM(CASE WHEN data_date BETWEEN '2025-01-01' AND '2025-07-30' THEN o2o_return_amt ELSE 0 END) - 1
    END AS Return_vs_LY
FROM `indep_rl_ads`.a02_e2e_boss_performance_summary_d
WHERE calc_type = 'payment'
  AND fulfillment_calc_type = 'Exclude orders cancelled in pay date'
  AND store_name IN ('TM', 'JD', 'RLE_CN', 'DY_Family', 'DY_W', 'DY_MN')
  AND data_date BETWEEN '2025-01-01' AND '2026-07-30'
GROUP BY store_name
ORDER BY store_name;

-- 1.5 Return% (O2O退货率) = SUM(o2o_return_amt) / SUM(o2o_sales_amt) —— 比率类, delta_bp
SELECT
    store_name,
    SUM(CASE WHEN data_date BETWEEN '2026-01-01' AND '2026-07-30' THEN o2o_return_amt ELSE 0 END)
    / NULLIF(SUM(CASE WHEN data_date BETWEEN '2026-01-01' AND '2026-07-30' THEN o2o_sales_amt ELSE 0 END), 0) AS Return_Pct_Act,
    SUM(CASE WHEN data_date BETWEEN '2025-01-01' AND '2025-07-30' THEN o2o_return_amt ELSE 0 END)
    / NULLIF(SUM(CASE WHEN data_date BETWEEN '2025-01-01' AND '2025-07-30' THEN o2o_sales_amt ELSE 0 END), 0) AS Return_Pct_LY,
    (SUM(CASE WHEN data_date BETWEEN '2026-01-01' AND '2026-07-30' THEN o2o_return_amt ELSE 0 END)
     / NULLIF(SUM(CASE WHEN data_date BETWEEN '2026-01-01' AND '2026-07-30' THEN o2o_sales_amt ELSE 0 END), 0))
    -
    (SUM(CASE WHEN data_date BETWEEN '2025-01-01' AND '2025-07-30' THEN o2o_return_amt ELSE 0 END)
     / NULLIF(SUM(CASE WHEN data_date BETWEEN '2025-01-01' AND '2025-07-30' THEN o2o_sales_amt ELSE 0 END), 0)) AS Return_Pct_vs_LY
FROM `indep_rl_ads`.a02_e2e_boss_performance_summary_d
WHERE calc_type = 'payment'
  AND fulfillment_calc_type = 'Exclude orders cancelled in pay date'
  AND store_name IN ('TM', 'JD', 'RLE_CN', 'DY_Family', 'DY_W', 'DY_MN')
  AND data_date BETWEEN '2025-01-01' AND '2026-07-30'
GROUP BY store_name
ORDER BY store_name;

-- ------------------------------------------------------------
-- 2. Fulfillment 分组 (calc_type = 'fulfillment')
--    KPI: Fulfillment% / Request Order Qty / Request Units /
--         Request Order Amt / Shipped Order Qty / Shipped Units / Shipped Order Amt
-- ------------------------------------------------------------

-- 2.1 Fulfillment% (O2O订单履约率) = SUM(shipped_order_cnt) / SUM(request_order_cnt) —— 比率类, delta_bp
SELECT
    store_name,
    SUM(CASE WHEN data_date BETWEEN '2026-01-01' AND '2026-07-30' THEN o2o_fulfillment_shipped_order_cnt ELSE 0 END)
    / NULLIF(SUM(CASE WHEN data_date BETWEEN '2026-01-01' AND '2026-07-30' THEN o2o_fulfillment_request_order_cnt ELSE 0 END), 0) AS Fulfillment_Pct_Act,
    SUM(CASE WHEN data_date BETWEEN '2025-01-01' AND '2025-07-30' THEN o2o_fulfillment_shipped_order_cnt ELSE 0 END)
    / NULLIF(SUM(CASE WHEN data_date BETWEEN '2025-01-01' AND '2025-07-30' THEN o2o_fulfillment_request_order_cnt ELSE 0 END), 0) AS Fulfillment_Pct_LY,
    (SUM(CASE WHEN data_date BETWEEN '2026-01-01' AND '2026-07-30' THEN o2o_fulfillment_shipped_order_cnt ELSE 0 END)
     / NULLIF(SUM(CASE WHEN data_date BETWEEN '2026-01-01' AND '2026-07-30' THEN o2o_fulfillment_request_order_cnt ELSE 0 END), 0))
    -
    (SUM(CASE WHEN data_date BETWEEN '2025-01-01' AND '2025-07-30' THEN o2o_fulfillment_shipped_order_cnt ELSE 0 END)
     / NULLIF(SUM(CASE WHEN data_date BETWEEN '2025-01-01' AND '2025-07-30' THEN o2o_fulfillment_request_order_cnt ELSE 0 END), 0)) AS Fulfillment_Pct_vs_LY
FROM `indep_rl_ads`.a02_e2e_boss_performance_summary_d
WHERE calc_type = 'fulfillment'
  AND fulfillment_calc_type = 'Exclude orders cancelled in pay date'
  AND store_name IN ('TM', 'JD', 'RLE_CN', 'DY_Family', 'DY_W', 'DY_MN')
  AND data_date BETWEEN '2025-01-01' AND '2026-07-30'
GROUP BY store_name
ORDER BY store_name;

-- 2.2 Request Order Qty (O2O销售订单量) = SUM(o2o_fulfillment_request_order_cnt) —— 数量类
SELECT
    store_name,
    SUM(CASE WHEN data_date BETWEEN '2026-01-01' AND '2026-07-30' THEN o2o_fulfillment_request_order_cnt ELSE 0 END) AS Request_Order_Qty_Act,
    SUM(CASE WHEN data_date BETWEEN '2025-01-01' AND '2025-07-30' THEN o2o_fulfillment_request_order_cnt ELSE 0 END) AS Request_Order_Qty_LY,
    CASE
        WHEN SUM(CASE WHEN data_date BETWEEN '2025-01-01' AND '2025-07-30' THEN o2o_fulfillment_request_order_cnt ELSE 0 END) = 0 THEN NULL
        ELSE SUM(CASE WHEN data_date BETWEEN '2026-01-01' AND '2026-07-30' THEN o2o_fulfillment_request_order_cnt ELSE 0 END)
           / SUM(CASE WHEN data_date BETWEEN '2025-01-01' AND '2025-07-30' THEN o2o_fulfillment_request_order_cnt ELSE 0 END) - 1
    END AS Request_Order_Qty_vs_LY
FROM `indep_rl_ads`.a02_e2e_boss_performance_summary_d
WHERE calc_type = 'fulfillment'
  AND fulfillment_calc_type = 'Exclude orders cancelled in pay date'
  AND store_name IN ('TM', 'JD', 'RLE_CN', 'DY_Family', 'DY_W', 'DY_MN')
  AND data_date BETWEEN '2025-01-01' AND '2026-07-30'
GROUP BY store_name
ORDER BY store_name;

-- 2.3 Request Units (O2O商品销售件数) = SUM(o2o_fulfillment_request_qty) —— 数量类
SELECT
    store_name,
    SUM(CASE WHEN data_date BETWEEN '2026-01-01' AND '2026-07-30' THEN o2o_fulfillment_request_qty ELSE 0 END) AS Request_Units_Act,
    SUM(CASE WHEN data_date BETWEEN '2025-01-01' AND '2025-07-30' THEN o2o_fulfillment_request_qty ELSE 0 END) AS Request_Units_LY,
    CASE
        WHEN SUM(CASE WHEN data_date BETWEEN '2025-01-01' AND '2025-07-30' THEN o2o_fulfillment_request_qty ELSE 0 END) = 0 THEN NULL
        ELSE SUM(CASE WHEN data_date BETWEEN '2026-01-01' AND '2026-07-30' THEN o2o_fulfillment_request_qty ELSE 0 END)
           / SUM(CASE WHEN data_date BETWEEN '2025-01-01' AND '2025-07-30' THEN o2o_fulfillment_request_qty ELSE 0 END) - 1
    END AS Request_Units_vs_LY
FROM `indep_rl_ads`.a02_e2e_boss_performance_summary_d
WHERE calc_type = 'fulfillment'
  AND fulfillment_calc_type = 'Exclude orders cancelled in pay date'
  AND store_name IN ('TM', 'JD', 'RLE_CN', 'DY_Family', 'DY_W', 'DY_MN')
  AND data_date BETWEEN '2025-01-01' AND '2026-07-30'
GROUP BY store_name
ORDER BY store_name;

-- 2.4 Request Order Amt (O2O销售金额) = SUM(o2o_fulfillment_request_sales_amt) —— 金额类
SELECT
    store_name,
    SUM(CASE WHEN data_date BETWEEN '2026-01-01' AND '2026-07-30' THEN o2o_fulfillment_request_sales_amt ELSE 0 END) / 1.0 AS Request_Order_Amt_Act,
    SUM(CASE WHEN data_date BETWEEN '2025-01-01' AND '2025-07-30' THEN o2o_fulfillment_request_sales_amt ELSE 0 END) / 1.0 AS Request_Order_Amt_LY,
    CASE
        WHEN SUM(CASE WHEN data_date BETWEEN '2025-01-01' AND '2025-07-30' THEN o2o_fulfillment_request_sales_amt ELSE 0 END) = 0 THEN NULL
        ELSE SUM(CASE WHEN data_date BETWEEN '2026-01-01' AND '2026-07-30' THEN o2o_fulfillment_request_sales_amt ELSE 0 END)
           / SUM(CASE WHEN data_date BETWEEN '2025-01-01' AND '2025-07-30' THEN o2o_fulfillment_request_sales_amt ELSE 0 END) - 1
    END AS Request_Order_Amt_vs_LY
FROM `indep_rl_ads`.a02_e2e_boss_performance_summary_d
WHERE calc_type = 'fulfillment'
  AND fulfillment_calc_type = 'Exclude orders cancelled in pay date'
  AND store_name IN ('TM', 'JD', 'RLE_CN', 'DY_Family', 'DY_W', 'DY_MN')
  AND data_date BETWEEN '2025-01-01' AND '2026-07-30'
GROUP BY store_name
ORDER BY store_name;

-- 2.5 Shipped Order Qty (O2O已配货订单量) = SUM(o2o_fulfillment_shipped_order_cnt) —— 数量类
SELECT
    store_name,
    SUM(CASE WHEN data_date BETWEEN '2026-01-01' AND '2026-07-30' THEN o2o_fulfillment_shipped_order_cnt ELSE 0 END) AS Shipped_Order_Qty_Act,
    SUM(CASE WHEN data_date BETWEEN '2025-01-01' AND '2025-07-30' THEN o2o_fulfillment_shipped_order_cnt ELSE 0 END) AS Shipped_Order_Qty_LY,
    CASE
        WHEN SUM(CASE WHEN data_date BETWEEN '2025-01-01' AND '2025-07-30' THEN o2o_fulfillment_shipped_order_cnt ELSE 0 END) = 0 THEN NULL
        ELSE SUM(CASE WHEN data_date BETWEEN '2026-01-01' AND '2026-07-30' THEN o2o_fulfillment_shipped_order_cnt ELSE 0 END)
           / SUM(CASE WHEN data_date BETWEEN '2025-01-01' AND '2025-07-30' THEN o2o_fulfillment_shipped_order_cnt ELSE 0 END) - 1
    END AS Shipped_Order_Qty_vs_LY
FROM `indep_rl_ads`.a02_e2e_boss_performance_summary_d
WHERE calc_type = 'fulfillment'
  AND fulfillment_calc_type = 'Exclude orders cancelled in pay date'
  AND store_name IN ('TM', 'JD', 'RLE_CN', 'DY_Family', 'DY_W', 'DY_MN')
  AND data_date BETWEEN '2025-01-01' AND '2026-07-30'
GROUP BY store_name
ORDER BY store_name;

-- 2.6 Shipped Units (O2O已配货商品件数) = SUM(o2o_fulfillment_shipped_qty) —— 数量类
SELECT
    store_name,
    SUM(CASE WHEN data_date BETWEEN '2026-01-01' AND '2026-07-30' THEN o2o_fulfillment_shipped_qty ELSE 0 END) AS Shipped_Units_Act,
    SUM(CASE WHEN data_date BETWEEN '2025-01-01' AND '2025-07-30' THEN o2o_fulfillment_shipped_qty ELSE 0 END) AS Shipped_Units_LY,
    CASE
        WHEN SUM(CASE WHEN data_date BETWEEN '2025-01-01' AND '2025-07-30' THEN o2o_fulfillment_shipped_qty ELSE 0 END) = 0 THEN NULL
        ELSE SUM(CASE WHEN data_date BETWEEN '2026-01-01' AND '2026-07-30' THEN o2o_fulfillment_shipped_qty ELSE 0 END)
           / SUM(CASE WHEN data_date BETWEEN '2025-01-01' AND '2025-07-30' THEN o2o_fulfillment_shipped_qty ELSE 0 END) - 1
    END AS Shipped_Units_vs_LY
FROM `indep_rl_ads`.a02_e2e_boss_performance_summary_d
WHERE calc_type = 'fulfillment'
  AND fulfillment_calc_type = 'Exclude orders cancelled in pay date'
  AND store_name IN ('TM', 'JD', 'RLE_CN', 'DY_Family', 'DY_W', 'DY_MN')
  AND data_date BETWEEN '2025-01-01' AND '2026-07-30'
GROUP BY store_name
ORDER BY store_name;

-- 2.7 Shipped Order Amt (O2O已配货销售金额) = SUM(o2o_fulfillment_shipped_sales_amt) —— 金额类
SELECT
    store_name,
    SUM(CASE WHEN data_date BETWEEN '2026-01-01' AND '2026-07-30' THEN o2o_fulfillment_shipped_sales_amt ELSE 0 END) / 1.0 AS Shipped_Order_Amt_Act,
    SUM(CASE WHEN data_date BETWEEN '2025-01-01' AND '2025-07-30' THEN o2o_fulfillment_shipped_sales_amt ELSE 0 END) / 1.0 AS Shipped_Order_Amt_LY,
    CASE
        WHEN SUM(CASE WHEN data_date BETWEEN '2025-01-01' AND '2025-07-30' THEN o2o_fulfillment_shipped_sales_amt ELSE 0 END) = 0 THEN NULL
        ELSE SUM(CASE WHEN data_date BETWEEN '2026-01-01' AND '2026-07-30' THEN o2o_fulfillment_shipped_sales_amt ELSE 0 END)
           / SUM(CASE WHEN data_date BETWEEN '2025-01-01' AND '2025-07-30' THEN o2o_fulfillment_shipped_sales_amt ELSE 0 END) - 1
    END AS Shipped_Order_Amt_vs_LY
FROM `indep_rl_ads`.a02_e2e_boss_performance_summary_d
WHERE calc_type = 'fulfillment'
  AND fulfillment_calc_type = 'Exclude orders cancelled in pay date'
  AND store_name IN ('TM', 'JD', 'RLE_CN', 'DY_Family', 'DY_W', 'DY_MN')
  AND data_date BETWEEN '2025-01-01' AND '2026-07-30'
GROUP BY store_name
ORDER BY store_name;

-- ------------------------------------------------------------
-- 3. 全店铺汇总(All Stores) —— 对应矩阵中 StoreGroup_ID 为空时的总计行
-- ------------------------------------------------------------

-- 3.1 Sales 分组汇总 (calc_type = 'payment')
SELECT
    'All Stores' AS store_name,
    SUM(CASE WHEN data_date BETWEEN '2026-01-01' AND '2026-07-30' THEN o2o_net_sales_amt ELSE 0 END) / 1.0 AS SLS_Act,
    SUM(CASE WHEN data_date BETWEEN '2025-01-01' AND '2025-07-30' THEN o2o_net_sales_amt ELSE 0 END) / 1.0 AS SLS_LY,
    CASE
        WHEN SUM(CASE WHEN data_date BETWEEN '2025-01-01' AND '2025-07-30' THEN o2o_net_sales_amt ELSE 0 END) = 0 THEN NULL
        ELSE SUM(CASE WHEN data_date BETWEEN '2026-01-01' AND '2026-07-30' THEN o2o_net_sales_amt ELSE 0 END)
           / SUM(CASE WHEN data_date BETWEEN '2025-01-01' AND '2025-07-30' THEN o2o_net_sales_amt ELSE 0 END) - 1
    END AS SLS_vs_LY,
    SUM(CASE WHEN data_date BETWEEN '2026-01-01' AND '2026-07-30' THEN o2o_sales_amt ELSE 0 END) / 1.0 AS DemandSLS_Act,
    SUM(CASE WHEN data_date BETWEEN '2025-01-01' AND '2025-07-30' THEN o2o_sales_amt ELSE 0 END) / 1.0 AS DemandSLS_LY,
    SUM(CASE WHEN data_date BETWEEN '2026-01-01' AND '2026-07-30' THEN o2o_return_amt ELSE 0 END) / 1.0 AS Return_Act,
    SUM(CASE WHEN data_date BETWEEN '2025-01-01' AND '2025-07-30' THEN o2o_return_amt ELSE 0 END) / 1.0 AS Return_LY
FROM `indep_rl_ads`.a02_e2e_boss_performance_summary_d
WHERE calc_type = 'payment'
  AND fulfillment_calc_type = 'Exclude orders cancelled in pay date'
  AND store_name IN ('TM', 'JD', 'RLE_CN', 'DY_Family', 'DY_W', 'DY_MN')
  AND data_date BETWEEN '2025-01-01' AND '2026-07-30';

-- 3.2 Fulfillment 分组汇总 (calc_type = 'fulfillment')
SELECT
    'All Stores' AS store_name,
    SUM(CASE WHEN data_date BETWEEN '2026-01-01' AND '2026-07-30' THEN o2o_fulfillment_shipped_order_cnt ELSE 0 END)
    / NULLIF(SUM(CASE WHEN data_date BETWEEN '2026-01-01' AND '2026-07-30' THEN o2o_fulfillment_request_order_cnt ELSE 0 END), 0) AS Fulfillment_Pct_Act,
    SUM(CASE WHEN data_date BETWEEN '2025-01-01' AND '2025-07-30' THEN o2o_fulfillment_shipped_order_cnt ELSE 0 END)
    / NULLIF(SUM(CASE WHEN data_date BETWEEN '2025-01-01' AND '2025-07-30' THEN o2o_fulfillment_request_order_cnt ELSE 0 END), 0) AS Fulfillment_Pct_LY,
    SUM(CASE WHEN data_date BETWEEN '2026-01-01' AND '2026-07-30' THEN o2o_fulfillment_request_order_cnt ELSE 0 END) AS Request_Order_Qty_Act,
    SUM(CASE WHEN data_date BETWEEN '2025-01-01' AND '2025-07-30' THEN o2o_fulfillment_request_order_cnt ELSE 0 END) AS Request_Order_Qty_LY,
    SUM(CASE WHEN data_date BETWEEN '2026-01-01' AND '2026-07-30' THEN o2o_fulfillment_shipped_order_cnt ELSE 0 END) AS Shipped_Order_Qty_Act,
    SUM(CASE WHEN data_date BETWEEN '2025-01-01' AND '2025-07-30' THEN o2o_fulfillment_shipped_order_cnt ELSE 0 END) AS Shipped_Order_Qty_LY
FROM `indep_rl_ads`.a02_e2e_boss_performance_summary_d
WHERE calc_type = 'fulfillment'
  AND fulfillment_calc_type = 'Exclude orders cancelled in pay date'
  AND store_name IN ('TM', 'JD', 'RLE_CN', 'DY_Family', 'DY_W', 'DY_MN')
  AND data_date BETWEEN '2025-01-01' AND '2026-07-30';
