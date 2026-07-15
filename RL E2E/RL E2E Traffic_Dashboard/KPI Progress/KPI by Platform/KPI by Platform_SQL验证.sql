-- ============================================================
-- 文件: KPI by Platform_SQL验证.sql
-- 用途: 验证 KPI by Platform 矩阵 15 个指标的 DAX 计算结果
-- 口径来源: 口径文档/KPI Progress.md 子模块五：KPI by Platform
-- 测试参数:
--   本期时间: 2026-01-01 ~ 2026-07-14
--   同期时间: 2025-01-01 ~ 2025-07-14（往前推一年）
--   trans_cycle: T+1
--   分组维度: store_name（含 Total 汇总行）
-- 指标分组（5 组 × 3 列 + 1 组 Total 行验证 = 6 组 SQL）:
--   第1组: Media Cost Rate（费比）          — customer_type='ALL'
--   第2组: Media Cost（媒体花费）            — customer_type='ALL'
--   第3组: ± Accel cost MOB% vs. store SLS MOB% — customer_type='ALL', framework 区分
--   第4组: Media Contribution to New Cust%   — customer_type='NEW'
--   第5组: Cost Per New Acquisition          — customer_type='NEW'
--   第6组: Total 行专项验证（所有店铺汇总）
-- 语法: MySQL 8.0+（兼容 StarRocks/ByteHouse）
-- ============================================================


-- ════════════════════════════════════════════════════════════
-- 第1组：Media Cost Rate（费比）
-- 口径: cost_amt / net_sales_amt
-- 筛选: customer_type='ALL', page_type=1, trans_cycle='T+1'
-- 指标: Media Cost Rate(本期) / Media Cost Rate vs LP(同期) / YOY%
-- ════════════════════════════════════════════════════════════

WITH base AS (
    -- 按 store_name 分组聚合本期与同期的基础值
    SELECT 
        store_name,
        -- 本期聚合（2026-01-01 ~ 2026-07-14）
        SUM(CASE WHEN data_date BETWEEN '2026-01-01' AND '2026-07-14' THEN cost_amt ELSE 0 END)       AS cur_cost,
        SUM(CASE WHEN data_date BETWEEN '2026-01-01' AND '2026-07-14' THEN net_sales_amt ELSE 0 END) AS cur_sls,
        -- 同期聚合（2025-01-01 ~ 2025-07-14）
        SUM(CASE WHEN data_date BETWEEN '2025-01-01' AND '2025-07-14' THEN cost_amt ELSE 0 END)       AS lp_cost,
        SUM(CASE WHEN data_date BETWEEN '2025-01-01' AND '2025-07-14' THEN net_sales_amt ELSE 0 END) AS lp_sls
    FROM `indep_rl_ads`.`a05_e2e_paid_media_summary_d`
    WHERE customer_type = 'ALL'
      AND page_type = 1
      AND trans_cycle = 'T+1'
      AND data_date BETWEEN '2025-01-01' AND '2026-07-14'
    GROUP BY store_name
)
-- 明细行：按 store_name 分组
SELECT 
    store_name                                                                 AS store_name,
    cur_cost / NULLIF(cur_sls, 0)                                              AS media_cost_rate_current,   -- 本期 Media Cost Rate
    lp_cost  / NULLIF(lp_sls, 0)                                               AS media_cost_rate_vslp,     -- 同期 Media Cost Rate vs LP
    (cur_cost / NULLIF(cur_sls, 0) - lp_cost / NULLIF(lp_sls, 0)) 
        / NULLIF(lp_cost / NULLIF(lp_sls, 0), 0)                               AS yoy_pct                    -- YOY% = (本期-同期)/同期
FROM base
UNION ALL
-- Total 汇总行：所有店铺合计
SELECT 
    'Total'                                                                    AS store_name,
    SUM(cur_cost) / NULLIF(SUM(cur_sls), 0)                                    AS media_cost_rate_current,
    SUM(lp_cost)  / NULLIF(SUM(lp_sls), 0)                                     AS media_cost_rate_vslp,
    (SUM(cur_cost) / NULLIF(SUM(cur_sls), 0) - SUM(lp_cost) / NULLIF(SUM(lp_sls), 0)) 
        / NULLIF(SUM(lp_cost) / NULLIF(SUM(lp_sls), 0), 0)                     AS yoy_pct
FROM base;


-- ════════════════════════════════════════════════════════════
-- 第2组：Media Cost（媒体花费）
-- 口径: SUM(cost_amt)
-- 筛选: customer_type='ALL', page_type=1, trans_cycle='T+1'
-- 指标: Media Cost(本期) / Media Cost vs LP(同期) / YOY %
-- ════════════════════════════════════════════════════════════

WITH base AS (
    SELECT 
        store_name,
        -- 本期媒体花费
        SUM(CASE WHEN data_date BETWEEN '2026-01-01' AND '2026-07-14' THEN cost_amt ELSE 0 END) AS cur_cost,
        -- 同期媒体花费
        SUM(CASE WHEN data_date BETWEEN '2025-01-01' AND '2025-07-14' THEN cost_amt ELSE 0 END) AS lp_cost
    FROM `indep_rl_ads`.`a05_e2e_paid_media_summary_d`
    WHERE customer_type = 'ALL'
      AND page_type = 1
      AND trans_cycle = 'T+1'
      AND data_date BETWEEN '2025-01-01' AND '2026-07-14'
    GROUP BY store_name
)
SELECT 
    store_name                                           AS store_name,
    cur_cost                                             AS media_cost_current,   -- 本期 Media Cost
    lp_cost                                              AS media_cost_vslp,      -- 同期 Media Cost vs LP
    (cur_cost - lp_cost) / NULLIF(lp_cost, 0)            AS yoy_pct               -- YOY % = (本期-同期)/同期
FROM base
UNION ALL
SELECT 
    'Total'                                              AS store_name,
    SUM(cur_cost)                                        AS media_cost_current,
    SUM(lp_cost)                                         AS media_cost_vslp,
    (SUM(cur_cost) - SUM(lp_cost)) / NULLIF(SUM(lp_cost), 0) AS yoy_pct
FROM base;


-- ════════════════════════════════════════════════════════════
-- 第3组：± Acceleration cost MOB% vs. store SLS MOB%
-- 口径: Acceleration Cost MOB% - Store SLS MOB%
--       Acceleration Cost MOB% = cost_amt(framework='Acceleration') / cost_amt(全部 framework)
--       Store SLS MOB%         = net_sales_amt(framework='Acceleration') / net_sales_amt(全部 framework)
-- 筛选: customer_type='ALL', page_type=1, trans_cycle='T+1'
-- 指标: ± Accel cost MOB%(本期) / vs LP(同期) / YOY  %
-- ════════════════════════════════════════════════════════════

WITH base AS (
    SELECT 
        store_name,
        -- 本期：Acceleration 框架与全部框架的 cost / sls
        SUM(CASE WHEN data_date BETWEEN '2026-01-01' AND '2026-07-14' AND framework = 'Acceleration' THEN cost_amt ELSE 0 END)       AS cur_accel_cost,
        SUM(CASE WHEN data_date BETWEEN '2026-01-01' AND '2026-07-14' THEN cost_amt ELSE 0 END)                                     AS cur_total_cost,
        SUM(CASE WHEN data_date BETWEEN '2026-01-01' AND '2026-07-14' AND framework = 'Acceleration' THEN net_sales_amt ELSE 0 END) AS cur_accel_sls,
        SUM(CASE WHEN data_date BETWEEN '2026-01-01' AND '2026-07-14' THEN net_sales_amt ELSE 0 END)                                 AS cur_total_sls,
        -- 同期：Acceleration 框架与全部框架的 cost / sls
        SUM(CASE WHEN data_date BETWEEN '2025-01-01' AND '2025-07-14' AND framework = 'Acceleration' THEN cost_amt ELSE 0 END)       AS lp_accel_cost,
        SUM(CASE WHEN data_date BETWEEN '2025-01-01' AND '2025-07-14' THEN cost_amt ELSE 0 END)                                      AS lp_total_cost,
        SUM(CASE WHEN data_date BETWEEN '2025-01-01' AND '2025-07-14' AND framework = 'Acceleration' THEN net_sales_amt ELSE 0 END)  AS lp_accel_sls,
        SUM(CASE WHEN data_date BETWEEN '2025-01-01' AND '2025-07-14' THEN net_sales_amt ELSE 0 END)                                  AS lp_total_sls
    FROM `indep_rl_ads`.`a05_e2e_paid_media_summary_d`
    WHERE customer_type = 'ALL'
      AND page_type = 1
      AND trans_cycle = 'T+1'
      AND data_date BETWEEN '2025-01-01' AND '2026-07-14'
    GROUP BY store_name
),
calc AS (
    -- 计算本期/同期的 ± Accel cost MOB% vs. store SLS MOB%
    SELECT 
        store_name,
        -- 本期：Accel Cost MOB% - Store SLS MOB%
        (cur_accel_cost / NULLIF(cur_total_cost, 0)) - (cur_accel_sls / NULLIF(cur_total_sls, 0))   AS cur_value,
        -- 同期
        (lp_accel_cost / NULLIF(lp_total_cost, 0)) - (lp_accel_sls / NULLIF(lp_total_sls, 0))       AS lp_value
    FROM base
)
SELECT 
    store_name                                                  AS store_name,
    cur_value                                                   AS accel_cost_mob_vs_sls_current,   -- 本期
    lp_value                                                    AS accel_cost_mob_vs_sls_vslp,      -- 同期
    (cur_value - lp_value) / NULLIF(lp_value, 0)                AS yoy_pct                          -- YOY  %
FROM calc
UNION ALL
-- Total 汇总行
SELECT 
    'Total'                                                     AS store_name,
    (SUM(cur_accel_cost) / NULLIF(SUM(cur_total_cost), 0)) - (SUM(cur_accel_sls) / NULLIF(SUM(cur_total_sls), 0)) AS accel_cost_mob_vs_sls_current,
    (SUM(lp_accel_cost) / NULLIF(SUM(lp_total_cost), 0)) - (SUM(lp_accel_sls) / NULLIF(SUM(lp_total_sls), 0))     AS accel_cost_mob_vs_sls_vslp,
    ((SUM(cur_accel_cost) / NULLIF(SUM(cur_total_cost), 0)) - (SUM(cur_accel_sls) / NULLIF(SUM(cur_total_sls), 0))
     - ((SUM(lp_accel_cost) / NULLIF(SUM(lp_total_cost), 0)) - (SUM(lp_accel_sls) / NULLIF(SUM(lp_total_sls), 0))))
    / NULLIF((SUM(lp_accel_cost) / NULLIF(SUM(lp_total_cost), 0)) - (SUM(lp_accel_sls) / NULLIF(SUM(lp_total_sls), 0)), 0) AS yoy_pct
FROM base;


-- ════════════════════════════════════════════════════════════
-- 第4组：Media Contribution to New Customer Acquisition%
-- 口径: media_member_cnt / member_cnt（媒体新客数 / 全店新客数）
-- 筛选: customer_type='NEW', page_type=1, trans_cycle='T+1'
-- 指标: Media Contribution%(本期) / vs LP(同期) / YOY   %
-- ════════════════════════════════════════════════════════════

WITH base AS (
    SELECT 
        store_name,
        -- 本期：媒体新客数 / 全店新客数
        SUM(CASE WHEN data_date BETWEEN '2026-01-01' AND '2026-07-14' THEN media_member_cnt ELSE 0 END) AS cur_media_new_cust,
        SUM(CASE WHEN data_date BETWEEN '2026-01-01' AND '2026-07-14' THEN member_cnt ELSE 0 END)       AS cur_total_new_cust,
        -- 同期
        SUM(CASE WHEN data_date BETWEEN '2025-01-01' AND '2025-07-14' THEN media_member_cnt ELSE 0 END) AS lp_media_new_cust,
        SUM(CASE WHEN data_date BETWEEN '2025-01-01' AND '2025-07-14' THEN member_cnt ELSE 0 END)       AS lp_total_new_cust
    FROM `indep_rl_ads`.`a05_e2e_paid_media_summary_d`
    WHERE customer_type = 'NEW'
      AND page_type = 1
      AND trans_cycle = 'T+1'
      AND data_date BETWEEN '2025-01-01' AND '2026-07-14'
    GROUP BY store_name
),
calc AS (
    SELECT 
        store_name,
        cur_media_new_cust / NULLIF(cur_total_new_cust, 0) AS cur_value,
        lp_media_new_cust  / NULLIF(lp_total_new_cust, 0)  AS lp_value
    FROM base
)
SELECT 
    store_name                                       AS store_name,
    cur_value                                        AS media_new_cust_contrib_current,  -- 本期
    lp_value                                         AS media_new_cust_contrib_vslp,      -- 同期
    (cur_value - lp_value) / NULLIF(lp_value, 0)     AS yoy_pct                           -- YOY   %
FROM calc
UNION ALL
SELECT 
    'Total'                                          AS store_name,
    SUM(cur_media_new_cust) / NULLIF(SUM(cur_total_new_cust), 0) AS media_new_cust_contrib_current,
    SUM(lp_media_new_cust)  / NULLIF(SUM(lp_total_new_cust), 0)  AS media_new_cust_contrib_vslp,
    (SUM(cur_media_new_cust) / NULLIF(SUM(cur_total_new_cust), 0) - SUM(lp_media_new_cust) / NULLIF(SUM(lp_total_new_cust), 0))
    / NULLIF(SUM(lp_media_new_cust) / NULLIF(SUM(lp_total_new_cust), 0), 0) AS yoy_pct
FROM base;


-- ════════════════════════════════════════════════════════════
-- 第5组：Cost Per New Acquisition（媒体新客获客成本）
-- 口径: media_cost_amt / media_member_cnt（新客花费 / 媒体新客数）
-- 筛选: customer_type='NEW', page_type=1, trans_cycle='T+1'
-- 指标: Cost Per New Acq(本期) / vs LP(同期) / YOY    %
-- ════════════════════════════════════════════════════════════

WITH base AS (
    SELECT 
        store_name,
        -- 本期：新客花费 / 媒体新客数
        SUM(CASE WHEN data_date BETWEEN '2026-01-01' AND '2026-07-14' THEN media_cost_amt ELSE 0 END)   AS cur_media_new_cost,
        SUM(CASE WHEN data_date BETWEEN '2026-01-01' AND '2026-07-14' THEN media_member_cnt ELSE 0 END) AS cur_media_new_cust,
        -- 同期
        SUM(CASE WHEN data_date BETWEEN '2025-01-01' AND '2025-07-14' THEN media_cost_amt ELSE 0 END)   AS lp_media_new_cost,
        SUM(CASE WHEN data_date BETWEEN '2025-01-01' AND '2025-07-14' THEN media_member_cnt ELSE 0 END) AS lp_media_new_cust
    FROM `indep_rl_ads`.`a05_e2e_paid_media_summary_d`
    WHERE customer_type = 'NEW'
      AND page_type = 1
      AND trans_cycle = 'T+1'
      AND data_date BETWEEN '2025-01-01' AND '2026-07-14'
    GROUP BY store_name
),
calc AS (
    SELECT 
        store_name,
        cur_media_new_cost / NULLIF(cur_media_new_cust, 0) AS cur_value,
        lp_media_new_cost  / NULLIF(lp_media_new_cust, 0)  AS lp_value
    FROM base
)
SELECT 
    store_name                                       AS store_name,
    cur_value                                        AS cost_per_new_acq_current,   -- 本期
    lp_value                                         AS cost_per_new_acq_vslp,       -- 同期
    (cur_value - lp_value) / NULLIF(lp_value, 0)     AS yoy_pct                      -- YOY    %
FROM calc
UNION ALL
SELECT 
    'Total'                                          AS store_name,
    SUM(cur_media_new_cost) / NULLIF(SUM(cur_media_new_cust), 0) AS cost_per_new_acq_current,
    SUM(lp_media_new_cost)  / NULLIF(SUM(lp_media_new_cust), 0)  AS cost_per_new_acq_vslp,
    (SUM(cur_media_new_cost) / NULLIF(SUM(cur_media_new_cust), 0) - SUM(lp_media_new_cost) / NULLIF(SUM(lp_media_new_cust), 0))
    / NULLIF(SUM(lp_media_new_cost) / NULLIF(SUM(lp_media_new_cust), 0), 0) AS yoy_pct
FROM base;


-- ════════════════════════════════════════════════════════════
-- 第6组：Total 行专项验证（所有店铺汇总，不按 store_name 分组）
-- 用途: 与第1~5组 UNION ALL 的 Total 行交叉验证，确保汇总逻辑一致
-- 口径: 同上5组，但去除 GROUP BY store_name，直接全表汇总
-- ════════════════════════════════════════════════════════════

SELECT 
    'Total' AS store_name,
    
    -- ─── 第1组：Media Cost Rate ───
    SUM(CASE WHEN data_date BETWEEN '2026-01-01' AND '2026-07-14' AND customer_type = 'ALL' THEN cost_amt ELSE 0 END)
        / NULLIF(SUM(CASE WHEN data_date BETWEEN '2026-01-01' AND '2026-07-14' AND customer_type = 'ALL' THEN net_sales_amt ELSE 0 END), 0) 
        AS g1_media_cost_rate_current,
    SUM(CASE WHEN data_date BETWEEN '2025-01-01' AND '2025-07-14' AND customer_type = 'ALL' THEN cost_amt ELSE 0 END)
        / NULLIF(SUM(CASE WHEN data_date BETWEEN '2025-01-01' AND '2025-07-14' AND customer_type = 'ALL' THEN net_sales_amt ELSE 0 END), 0) 
        AS g1_media_cost_rate_vslp,
    
    -- ─── 第2组：Media Cost ───
    SUM(CASE WHEN data_date BETWEEN '2026-01-01' AND '2026-07-14' AND customer_type = 'ALL' THEN cost_amt ELSE 0 END) 
        AS g2_media_cost_current,
    SUM(CASE WHEN data_date BETWEEN '2025-01-01' AND '2025-07-14' AND customer_type = 'ALL' THEN cost_amt ELSE 0 END) 
        AS g2_media_cost_vslp,
    
    -- ─── 第3组：± Accel cost MOB% vs. store SLS MOB% ───
    (SUM(CASE WHEN data_date BETWEEN '2026-01-01' AND '2026-07-14' AND customer_type = 'ALL' AND framework = 'Acceleration' THEN cost_amt ELSE 0 END)
        / NULLIF(SUM(CASE WHEN data_date BETWEEN '2026-01-01' AND '2026-07-14' AND customer_type = 'ALL' THEN cost_amt ELSE 0 END), 0))
    - (SUM(CASE WHEN data_date BETWEEN '2026-01-01' AND '2026-07-14' AND customer_type = 'ALL' AND framework = 'Acceleration' THEN net_sales_amt ELSE 0 END)
        / NULLIF(SUM(CASE WHEN data_date BETWEEN '2026-01-01' AND '2026-07-14' AND customer_type = 'ALL' THEN net_sales_amt ELSE 0 END), 0))
        AS g3_accel_cost_mob_vs_sls_current,
    (SUM(CASE WHEN data_date BETWEEN '2025-01-01' AND '2025-07-14' AND customer_type = 'ALL' AND framework = 'Acceleration' THEN cost_amt ELSE 0 END)
        / NULLIF(SUM(CASE WHEN data_date BETWEEN '2025-01-01' AND '2025-07-14' AND customer_type = 'ALL' THEN cost_amt ELSE 0 END), 0))
    - (SUM(CASE WHEN data_date BETWEEN '2025-01-01' AND '2025-07-14' AND customer_type = 'ALL' AND framework = 'Acceleration' THEN net_sales_amt ELSE 0 END)
        / NULLIF(SUM(CASE WHEN data_date BETWEEN '2025-01-01' AND '2025-07-14' AND customer_type = 'ALL' THEN net_sales_amt ELSE 0 END), 0))
        AS g3_accel_cost_mob_vs_sls_vslp,
    
    -- ─── 第4组：Media Contribution to New Customer Acquisition% ───
    SUM(CASE WHEN data_date BETWEEN '2026-01-01' AND '2026-07-14' AND customer_type = 'NEW' THEN media_member_cnt ELSE 0 END)
        / NULLIF(SUM(CASE WHEN data_date BETWEEN '2026-01-01' AND '2026-07-14' AND customer_type = 'NEW' THEN member_cnt ELSE 0 END), 0)
        AS g4_media_new_cust_contrib_current,
    SUM(CASE WHEN data_date BETWEEN '2025-01-01' AND '2025-07-14' AND customer_type = 'NEW' THEN media_member_cnt ELSE 0 END)
        / NULLIF(SUM(CASE WHEN data_date BETWEEN '2025-01-01' AND '2025-07-14' AND customer_type = 'NEW' THEN member_cnt ELSE 0 END), 0)
        AS g4_media_new_cust_contrib_vslp,
    
    -- ─── 第5组：Cost Per New Acquisition ───
    SUM(CASE WHEN data_date BETWEEN '2026-01-01' AND '2026-07-14' AND customer_type = 'NEW' THEN media_cost_amt ELSE 0 END)
        / NULLIF(SUM(CASE WHEN data_date BETWEEN '2026-01-01' AND '2026-07-14' AND customer_type = 'NEW' THEN media_member_cnt ELSE 0 END), 0)
        AS g5_cost_per_new_acq_current,
    SUM(CASE WHEN data_date BETWEEN '2025-01-01' AND '2025-07-14' AND customer_type = 'NEW' THEN media_cost_amt ELSE 0 END)
        / NULLIF(SUM(CASE WHEN data_date BETWEEN '2025-01-01' AND '2025-07-14' AND customer_type = 'NEW' THEN media_member_cnt ELSE 0 END), 0)
        AS g5_cost_per_new_acq_vslp

FROM `indep_rl_ads`.`a05_e2e_paid_media_summary_d`
WHERE page_type = 1
  AND trans_cycle = 'T+1'
  AND data_date BETWEEN '2025-01-01' AND '2026-07-14';
