-- ================================================================================
-- KPI Breakdown Matrix — 数据验证测试 SQL
-- ================================================================================
--
-- 用途：在 MySQL 中执行，验证数据库数据与 Power BI KPI Breakdown 矩阵一致性
-- 对标：KPI_Breakdown_matrix_solution 中 KPI Breakdown Base Value 的 DAX 计算口径
-- 数据库：indep_rl_ads
-- 事实表：a05_e2e_paid_media_summary_d
--
-- ★参数区★（修改这里的值来匹配 Power BI 切片器选择）：
--   日期范围：       '2025-01-01' ~ '2026-07-14'
--   platform：       'TM'
--   store_name：     'TM'
--   trans_cycle：    'T+1'
--   page_type：      '2'
--   Scenario_Type：  'Category->Framework->Brand'
--     → Level 1 = category  = 'Sweaters'
--     → Level 2 = framework = 'Foundation'
--     → Level 3 = brand     = 'M Polo'
--
-- 行维度筛选层级（4 级矩阵层次）：
--   Total 总计行   ：无行维度筛选（移除 brand/category/framework 筛选）
--   Level 1 小计行 ：category = 'Sweaters'
--   Level 2 小计行 ：category = 'Sweaters' AND framework = 'Foundation'
--   Level 3 明细行 ：category = 'Sweaters' AND framework = 'Foundation' AND brand = 'M Polo'
--
-- TM 平台三渠道：直通车 / 引力魔方 / 全站推
--
-- MySQL 语法说明：
--   DAX DIVIDE(分子, 分母) → MySQL 用「分子 / NULLIF(分母, 0)」
--   当分母为 0 或 NULL 时返回 NULL（等价 DAX BLANK），避免除零错误
--
-- 验证指标（7 个，每个单独验证）：
--   1. Cost% vs SLS%            (ColMetric_ID=1,  格式 decimal_pt_1)
--   2. Cost MOB% Total          (ColMetric_ID=3,  格式 percent_1dp)
--   3. Cost MOB% 直通车          (ColMetric_ID=4,  格式 percent_1dp)
--   4. ROI Total                (ColMetric_ID=7,  格式 decimal_1dp)
--   5. ROI 全站推               (ColMetric_ID=10, 格式 decimal_1dp)
--   6. New Customer Cost% Total (ColMetric_ID=11, 格式 decimal_1dp)
--   7. New Customer Cost% 引力魔方(ColMetric_ID=13, 格式 decimal_1dp)
-- ================================================================================


-- ████████████████████████████████████████████████████████████████████████████████
-- PART 0: 数据探查 — 确认事实表数据可用性
-- ████████████████████████████████████████████████████████████████████████████████

-- 0.1 检查事实表在指定参数下的数据分布
SELECT
    platform,
    trans_cycle,
    store_name,
    COUNT(*)                        AS row_cnt,
    COUNT(DISTINCT data_date)       AS date_cnt,
    MIN(data_date)                  AS min_date,
    MAX(data_date)                  AS max_date
FROM indep_rl_ads.a05_e2e_paid_media_summary_d
WHERE platform = 'TM'
  AND trans_cycle = 'T+1'
  AND store_name = 'TM'
  AND page_type = '2'
  AND data_date >= '2025-01-01'
  AND data_date <= '2026-07-14'
GROUP BY platform, trans_cycle, store_name;


-- 0.2 检查 channel 字段值分布（TM 平台三渠道确认）
SELECT
    channel,
    customer_type,
    COUNT(*)                        AS row_cnt,
    SUM(cost_amt)                   AS total_cost,
    SUM(net_sales_amt)              AS total_net_sales,
    SUM(media_sales_amt)            AS total_media_sales
FROM indep_rl_ads.a05_e2e_paid_media_summary_d
WHERE platform = 'TM'
  AND trans_cycle = 'T+1'
  AND store_name = 'TM'
  AND page_type = '2'
  AND data_date >= '2025-01-01'
  AND data_date <= '2026-07-14'
GROUP BY channel, customer_type
ORDER BY channel, customer_type;


-- 0.3 检查目标行维度组合是否存在（category=Sweaters, framework=Foundation, brand=M Polo）
SELECT
    category,
    framework,
    brand,
    COUNT(*)                        AS row_cnt,
    SUM(cost_amt)                   AS total_cost
FROM indep_rl_ads.a05_e2e_paid_media_summary_d
WHERE platform = 'TM'
  AND trans_cycle = 'T+1'
  AND store_name = 'TM'
  AND page_type = '2'
  AND data_date >= '2025-01-01'
  AND data_date <= '2026-07-14'
  AND category = 'Sweaters'
  AND framework = 'Foundation'
  AND brand = 'M Polo'
GROUP BY category, framework, brand;


-- ████████████████████████████████████████████████████████████████████████████████
-- PART 1: Cost% vs SLS%（ColMetric_ID=1，格式 decimal_pt_1，单位 pt）
-- ████████████████████████████████████████████████████████████████████████████████
-- DAX 口径：
--   Total 行 = 0 pt
--   明细行 = (Cost MOB% - Net Sales%) * 100
--     Cost MOB%  = 三渠道 cost(行维度) / 三渠道 cost(TTL，移除行维度)
--     Net Sales% = 全渠道 net_sales(行维度) / 全渠道 net_sales(TRL，移除行维度)
--
-- 注意：__NetSales_ALL_TTL 不施加 channel 筛选（全渠道），与 Cost MOB% 分母不同

WITH
-- ── 三渠道 cost TTL（分母，移除行维度，保留三渠道 + 日期筛选）──
cost_3ch_ttl AS (
    SELECT
        SUM(cost_amt) AS cost_val
    FROM indep_rl_ads.a05_e2e_paid_media_summary_d
    WHERE platform = 'TM' AND trans_cycle = 'T+1' AND store_name = 'TM'
      AND page_type = '2' AND 1=1
      AND customer_type = 'ALL'
      AND channel IN ('直通车', '引力魔方', '全站推')
      AND data_date >= '2025-01-01' AND data_date <= '2026-07-14'
),
-- ── 全渠道 net_sales TTL（分母，移除行维度）──
net_sales_all_ttl AS (
    SELECT
        SUM(net_sales_amt) AS sales_val
    FROM indep_rl_ads.a05_e2e_paid_media_summary_d
    WHERE platform = 'TM' AND trans_cycle = 'T+1' AND store_name = 'TM'
      AND page_type = '2' AND 1=1
      AND customer_type = 'ALL'
      AND data_date >= '2025-01-01' AND data_date <= '2026-07-14'
)
-- ── 汇总输出 4 个层级 ──
SELECT
    '1. Cost% vs SLS%'                                       AS metric_name,
    'Total 总计行'                                           AS row_level,
    'Total 行始终为 0pt'                                      AS remark,
    0                                                        AS cost_vs_sls_pt
UNION ALL
-- ── Level 1 小计行：category = 'Sweaters' ──
SELECT
    '1. Cost% vs SLS%' AS metric_name,
    'L1: category=Sweaters' AS row_level,
    '(CostMOB% - SLS%) * 100' AS remark,
    (
        (
            (SELECT SUM(cost_amt) FROM indep_rl_ads.a05_e2e_paid_media_summary_d
             WHERE platform='TM' AND trans_cycle='T+1' AND store_name='TM'
               AND page_type='2' AND 1=1 AND customer_type='ALL'
               AND channel IN ('直通车','引力魔方','全站推')
               AND data_date >= '2025-01-01' AND data_date <= '2026-07-14'
               AND category = 'Sweaters')
            / NULLIF((SELECT cost_val FROM cost_3ch_ttl), 0)
        )
        -
        (
            (SELECT SUM(net_sales_amt) FROM indep_rl_ads.a05_e2e_paid_media_summary_d
             WHERE platform='TM' AND trans_cycle='T+1' AND store_name='TM'
               AND page_type='2' AND 1=1 AND customer_type='ALL'
               AND data_date >= '2025-01-01' AND data_date <= '2026-07-14'
               AND category = 'Sweaters')
            / NULLIF((SELECT sales_val FROM net_sales_all_ttl), 0)
        )
    ) * 100 AS cost_vs_sls_pt
UNION ALL
-- ── Level 2 小计行：category='Sweaters' AND framework='Foundation' ──
SELECT
    '1. Cost% vs SLS%' AS metric_name,
    'L2: Sweaters > Foundation' AS row_level,
    '(CostMOB% - SLS%) * 100' AS remark,
    (
        (
            (SELECT SUM(cost_amt) FROM indep_rl_ads.a05_e2e_paid_media_summary_d
             WHERE platform='TM' AND trans_cycle='T+1' AND store_name='TM'
               AND page_type='2' AND 1=1 AND customer_type='ALL'
               AND channel IN ('直通车','引力魔方','全站推')
               AND data_date >= '2025-01-01' AND data_date <= '2026-07-14'
               AND category = 'Sweaters' AND framework = 'Foundation')
            / NULLIF((SELECT cost_val FROM cost_3ch_ttl), 0)
        )
        -
        (
            (SELECT SUM(net_sales_amt) FROM indep_rl_ads.a05_e2e_paid_media_summary_d
             WHERE platform='TM' AND trans_cycle='T+1' AND store_name='TM'
               AND page_type='2' AND 1=1 AND customer_type='ALL'
               AND data_date >= '2025-01-01' AND data_date <= '2026-07-14'
               AND category = 'Sweaters' AND framework = 'Foundation')
            / NULLIF((SELECT sales_val FROM net_sales_all_ttl), 0)
        )
    ) * 100 AS cost_vs_sls_pt
UNION ALL
-- ── Level 3 明细行：category='Sweaters' AND framework='Foundation' AND brand='M Polo' ──
SELECT
    '1. Cost% vs SLS%' AS metric_name,
    'L3: Sweaters > Foundation > M Polo' AS row_level,
    '(CostMOB% - SLS%) * 100' AS remark,
    (
        (
            (SELECT SUM(cost_amt) FROM indep_rl_ads.a05_e2e_paid_media_summary_d
             WHERE platform='TM' AND trans_cycle='T+1' AND store_name='TM'
               AND page_type='2' AND 1=1 AND customer_type='ALL'
               AND channel IN ('直通车','引力魔方','全站推')
               AND data_date >= '2025-01-01' AND data_date <= '2026-07-14'
               AND category = 'Sweaters' AND framework = 'Foundation' AND brand = 'M Polo')
            / NULLIF((SELECT cost_val FROM cost_3ch_ttl), 0)
        )
        -
        (
            (SELECT SUM(net_sales_amt) FROM indep_rl_ads.a05_e2e_paid_media_summary_d
             WHERE platform='TM' AND trans_cycle='T+1' AND store_name='TM'
               AND page_type='2' AND 1=1 AND customer_type='ALL'
               AND data_date >= '2025-01-01' AND data_date <= '2026-07-14'
               AND category = 'Sweaters' AND framework = 'Foundation' AND brand = 'M Polo')
            / NULLIF((SELECT sales_val FROM net_sales_all_ttl), 0)
        )
    ) * 100 AS cost_vs_sls_pt;


-- ████████████████████████████████████████████████████████████████████████████████
-- PART 2: Cost MOB% Total（ColMetric_ID=3，格式 percent_1dp）
-- ████████████████████████████████████████████████████████████████████████████████
-- DAX 口径：
--   Total 行 = 1 (100%)
--   明细行 = 三渠道 cost(行维度) / 三渠道 cost(TTL，移除行维度)
--   channel 范围：直通车 / 引力魔方 / 全站推

WITH
-- ── 三渠道 cost TTL（分母，移除行维度）──
cost_3ch_ttl AS (
    SELECT SUM(cost_amt) AS cost_val
    FROM indep_rl_ads.a05_e2e_paid_media_summary_d
    WHERE platform = 'TM' AND trans_cycle = 'T+1' AND store_name = 'TM'
      AND page_type = '2' AND 1=1 AND customer_type = 'ALL'
      AND channel IN ('直通车', '引力魔方', '全站推')
      AND data_date >= '2025-01-01' AND data_date <= '2026-07-14'
)
SELECT
    '2. Cost MOB% Total'                                    AS metric_name,
    'Total 总计行'                                           AS row_level,
    'Total 行 = 100%'                                        AS remark,
    1.0                                                      AS cost_mob_pct
UNION ALL
-- ── Level 1 小计行：category = 'Sweaters' ──
SELECT
    '2. Cost MOB% Total' AS metric_name,
    'L1: category=Sweaters' AS row_level,
    '三渠道cost(行维度) / 三渠道cost(TTL)' AS remark,
    (SELECT SUM(cost_amt) FROM indep_rl_ads.a05_e2e_paid_media_summary_d
     WHERE platform='TM' AND trans_cycle='T+1' AND store_name='TM'
       AND page_type='2' AND 1=1 AND customer_type='ALL'
       AND channel IN ('直通车','引力魔方','全站推')
       AND data_date >= '2025-01-01' AND data_date <= '2026-07-14'
       AND category = 'Sweaters')
    / NULLIF((SELECT cost_val FROM cost_3ch_ttl), 0) AS cost_mob_pct
UNION ALL
-- ── Level 2 小计行：category='Sweaters' AND framework='Foundation' ──
SELECT
    '2. Cost MOB% Total' AS metric_name,
    'L2: Sweaters > Foundation' AS row_level,
    '三渠道cost(行维度) / 三渠道cost(TTL)' AS remark,
    (SELECT SUM(cost_amt) FROM indep_rl_ads.a05_e2e_paid_media_summary_d
     WHERE platform='TM' AND trans_cycle='T+1' AND store_name='TM'
       AND page_type='2' AND 1=1 AND customer_type='ALL'
       AND channel IN ('直通车','引力魔方','全站推')
       AND data_date >= '2025-01-01' AND data_date <= '2026-07-14'
       AND category = 'Sweaters' AND framework = 'Foundation')
    / NULLIF((SELECT cost_val FROM cost_3ch_ttl), 0) AS cost_mob_pct
UNION ALL
-- ── Level 3 明细行：category='Sweaters' AND framework='Foundation' AND brand='M Polo' ──
SELECT
    '2. Cost MOB% Total' AS metric_name,
    'L3: Sweaters > Foundation > M Polo' AS row_level,
    '三渠道cost(行维度) / 三渠道cost(TTL)' AS remark,
    (SELECT SUM(cost_amt) FROM indep_rl_ads.a05_e2e_paid_media_summary_d
     WHERE platform='TM' AND trans_cycle='T+1' AND store_name='TM'
       AND page_type='2' AND 1=1 AND customer_type='ALL'
       AND channel IN ('直通车','引力魔方','全站推')
       AND data_date >= '2025-01-01' AND data_date <= '2026-07-14'
       AND category = 'Sweaters' AND framework = 'Foundation' AND brand = 'M Polo')
    / NULLIF((SELECT cost_val FROM cost_3ch_ttl), 0) AS cost_mob_pct;


-- ████████████████████████████████████████████████████████████████████████████████
-- PART 3: Cost MOB% 直通车（ColMetric_ID=4，格式 percent_1dp）
-- ████████████████████████████████████████████████████████████████████████████████
-- DAX 口径：
--   Total 行 = 直通车 cost(无行维度) / 三渠道 cost(TTL)
--   明细行 = 直通车 cost(行维度) / 直通车 cost(TTL，移除行维度)
--   __Cost_ALL_Channel_TTL = 移除行维度的当前渠道 TTL cost

WITH
-- ── 三渠道 cost TTL（Total 行分母，移除行维度）──
cost_3ch_ttl AS (
    SELECT SUM(cost_amt) AS cost_val
    FROM indep_rl_ads.a05_e2e_paid_media_summary_d
    WHERE platform = 'TM' AND trans_cycle = 'T+1' AND store_name = 'TM'
      AND page_type = '2' AND 1=1 AND customer_type = 'ALL'
      AND channel IN ('直通车', '引力魔方', '全站推')
      AND data_date >= '2025-01-01' AND data_date <= '2026-07-14'
),
-- ── 直通车 cost TTL（明细行分母，移除行维度，仅保留直通车渠道）──
cost_zhitongche_ttl AS (
    SELECT SUM(cost_amt) AS cost_val
    FROM indep_rl_ads.a05_e2e_paid_media_summary_d
    WHERE platform = 'TM' AND trans_cycle = 'T+1' AND store_name = 'TM'
      AND page_type = '2' AND 1=1 AND customer_type = 'ALL'
      AND channel = '直通车'
      AND data_date >= '2025-01-01' AND data_date <= '2026-07-14'
)
SELECT
    '3. Cost MOB% 直通车'                                   AS metric_name,
    'Total 总计行'                                           AS row_level,
    '直通车cost(无行维度) / 三渠道cost(TTL)'                AS remark,
    (SELECT SUM(cost_amt) FROM indep_rl_ads.a05_e2e_paid_media_summary_d
     WHERE platform='TM' AND trans_cycle='T+1' AND store_name='TM'
       AND page_type='2' AND 1=1 AND customer_type='ALL'
       AND channel = '直通车'
       AND data_date >= '2025-01-01' AND data_date <= '2026-07-14')
    / NULLIF((SELECT cost_val FROM cost_3ch_ttl), 0) AS cost_mob_pct
UNION ALL
-- ── Level 1 小计行：category = 'Sweaters' ──
SELECT
    '3. Cost MOB% 直通车' AS metric_name,
    'L1: category=Sweaters' AS row_level,
    '直通车cost(行维度) / 直通车cost(TTL)' AS remark,
    (SELECT SUM(cost_amt) FROM indep_rl_ads.a05_e2e_paid_media_summary_d
     WHERE platform='TM' AND trans_cycle='T+1' AND store_name='TM'
       AND page_type='2' AND 1=1 AND customer_type='ALL'
       AND channel = '直通车'
       AND data_date >= '2025-01-01' AND data_date <= '2026-07-14'
       AND category = 'Sweaters')
    / NULLIF((SELECT cost_val FROM cost_zhitongche_ttl), 0) AS cost_mob_pct
UNION ALL
-- ── Level 2 小计行：category='Sweaters' AND framework='Foundation' ──
SELECT
    '3. Cost MOB% 直通车' AS metric_name,
    'L2: Sweaters > Foundation' AS row_level,
    '直通车cost(行维度) / 直通车cost(TTL)' AS remark,
    (SELECT SUM(cost_amt) FROM indep_rl_ads.a05_e2e_paid_media_summary_d
     WHERE platform='TM' AND trans_cycle='T+1' AND store_name='TM'
       AND page_type='2' AND 1=1 AND customer_type='ALL'
       AND channel = '直通车'
       AND data_date >= '2025-01-01' AND data_date <= '2026-07-14'
       AND category = 'Sweaters' AND framework = 'Foundation')
    / NULLIF((SELECT cost_val FROM cost_zhitongche_ttl), 0) AS cost_mob_pct
UNION ALL
-- ── Level 3 明细行：category='Sweaters' AND framework='Foundation' AND brand='M Polo' ──
SELECT
    '3. Cost MOB% 直通车' AS metric_name,
    'L3: Sweaters > Foundation > M Polo' AS row_level,
    '直通车cost(行维度) / 直通车cost(TTL)' AS remark,
    (SELECT SUM(cost_amt) FROM indep_rl_ads.a05_e2e_paid_media_summary_d
     WHERE platform='TM' AND trans_cycle='T+1' AND store_name='TM'
       AND page_type='2' AND 1=1 AND customer_type='ALL'
       AND channel = '直通车'
       AND data_date >= '2025-01-01' AND data_date <= '2026-07-14'
       AND category = 'Sweaters' AND framework = 'Foundation' AND brand = 'M Polo')
    / NULLIF((SELECT cost_val FROM cost_zhitongche_ttl), 0) AS cost_mob_pct;


-- ████████████████████████████████████████████████████████████████████████████████
-- PART 4: ROI Total（ColMetric_ID=7，格式 decimal_1dp）
-- ████████████████████████████████████████████████████████████████████████████████
-- DAX 口径：
--   Total 行和明细行口径一致：三渠道 sales / 三渠道 cost
--   Total 行 = TTL 三渠道 sales / TTL 三渠道 cost（无行维度）
--   明细行 = 分组三渠道 sales / 分组三渠道 cost（受行维度筛选）
--   channel 范围：直通车 / 引力魔方 / 全站推

SELECT
    '4. ROI Total'                                           AS metric_name,
    'Total 总计行'                                           AS row_level,
    '三渠道sales(TTL) / 三渠道cost(TTL)'                    AS remark,
    (SELECT SUM(media_sales_amt) FROM indep_rl_ads.a05_e2e_paid_media_summary_d
     WHERE platform='TM' AND trans_cycle='T+1' AND store_name='TM'
       AND page_type='2' AND 1=1 AND customer_type='ALL'
       AND channel IN ('直通车','引力魔方','全站推')
       AND data_date >= '2025-01-01' AND data_date <= '2026-07-14')
    / NULLIF((SELECT SUM(cost_amt) FROM indep_rl_ads.a05_e2e_paid_media_summary_d
     WHERE platform='TM' AND trans_cycle='T+1' AND store_name='TM'
       AND page_type='2' AND 1=1 AND customer_type='ALL'
       AND channel IN ('直通车','引力魔方','全站推')
       AND data_date >= '2025-01-01' AND data_date <= '2026-07-14'), 0) AS roi_val
UNION ALL
-- ── Level 1 小计行：category = 'Sweaters' ──
SELECT
    '4. ROI Total' AS metric_name,
    'L1: category=Sweaters' AS row_level,
    '三渠道sales(行维度) / 三渠道cost(行维度)' AS remark,
    (SELECT SUM(media_sales_amt) FROM indep_rl_ads.a05_e2e_paid_media_summary_d
     WHERE platform='TM' AND trans_cycle='T+1' AND store_name='TM'
       AND page_type='2' AND 1=1 AND customer_type='ALL'
       AND channel IN ('直通车','引力魔方','全站推')
       AND data_date >= '2025-01-01' AND data_date <= '2026-07-14'
       AND category = 'Sweaters')
    / NULLIF((SELECT SUM(cost_amt) FROM indep_rl_ads.a05_e2e_paid_media_summary_d
     WHERE platform='TM' AND trans_cycle='T+1' AND store_name='TM'
       AND page_type='2' AND 1=1 AND customer_type='ALL'
       AND channel IN ('直通车','引力魔方','全站推')
       AND data_date >= '2025-01-01' AND data_date <= '2026-07-14'
       AND category = 'Sweaters'), 0) AS roi_val
UNION ALL
-- ── Level 2 小计行：category='Sweaters' AND framework='Foundation' ──
SELECT
    '4. ROI Total' AS metric_name,
    'L2: Sweaters > Foundation' AS row_level,
    '三渠道sales(行维度) / 三渠道cost(行维度)' AS remark,
    (SELECT SUM(media_sales_amt) FROM indep_rl_ads.a05_e2e_paid_media_summary_d
     WHERE platform='TM' AND trans_cycle='T+1' AND store_name='TM'
       AND page_type='2' AND 1=1 AND customer_type='ALL'
       AND channel IN ('直通车','引力魔方','全站推')
       AND data_date >= '2025-01-01' AND data_date <= '2026-07-14'
       AND category = 'Sweaters' AND framework = 'Foundation')
    / NULLIF((SELECT SUM(cost_amt) FROM indep_rl_ads.a05_e2e_paid_media_summary_d
     WHERE platform='TM' AND trans_cycle='T+1' AND store_name='TM'
       AND page_type='2' AND 1=1 AND customer_type='ALL'
       AND channel IN ('直通车','引力魔方','全站推')
       AND data_date >= '2025-01-01' AND data_date <= '2026-07-14'
       AND category = 'Sweaters' AND framework = 'Foundation'), 0) AS roi_val
UNION ALL
-- ── Level 3 明细行：category='Sweaters' AND framework='Foundation' AND brand='M Polo' ──
SELECT
    '4. ROI Total' AS metric_name,
    'L3: Sweaters > Foundation > M Polo' AS row_level,
    '三渠道sales(行维度) / 三渠道cost(行维度)' AS remark,
    (SELECT SUM(media_sales_amt) FROM indep_rl_ads.a05_e2e_paid_media_summary_d
     WHERE platform='TM' AND trans_cycle='T+1' AND store_name='TM'
       AND page_type='2' AND 1=1 AND customer_type='ALL'
       AND channel IN ('直通车','引力魔方','全站推')
       AND data_date >= '2025-01-01' AND data_date <= '2026-07-14'
       AND category = 'Sweaters' AND framework = 'Foundation' AND brand = 'M Polo')
    / NULLIF((SELECT SUM(cost_amt) FROM indep_rl_ads.a05_e2e_paid_media_summary_d
     WHERE platform='TM' AND trans_cycle='T+1' AND store_name='TM'
       AND page_type='2' AND 1=1 AND customer_type='ALL'
       AND channel IN ('直通车','引力魔方','全站推')
       AND data_date >= '2025-01-01' AND data_date <= '2026-07-14'
       AND category = 'Sweaters' AND framework = 'Foundation' AND brand = 'M Polo'), 0) AS roi_val;


-- ████████████████████████████████████████████████████████████████████████████████
-- PART 5: ROI 全站推（ColMetric_ID=10，格式 decimal_1dp）
-- ████████████████████████████████████████████████████████████████████████████████
-- DAX 口径：
--   Total 行和明细行口径一致：全站推 sales / 全站推 cost
--   Total 行 = TTL 全站推 sales / TTL 全站推 cost（无行维度）
--   明细行 = 分组全站推 sales / 分组全站推 cost（受行维度筛选）
--   channel = '全站推'

SELECT
    '5. ROI 全站推'                                          AS metric_name,
    'Total 总计行'                                           AS row_level,
    '全站推sales(TTL) / 全站推cost(TTL)'                    AS remark,
    (SELECT SUM(media_sales_amt) FROM indep_rl_ads.a05_e2e_paid_media_summary_d
     WHERE platform='TM' AND trans_cycle='T+1' AND store_name='TM'
       AND page_type='2' AND 1=1 AND customer_type='ALL'
       AND channel = '全站推'
       AND data_date >= '2025-01-01' AND data_date <= '2026-07-14')
    / NULLIF((SELECT SUM(cost_amt) FROM indep_rl_ads.a05_e2e_paid_media_summary_d
     WHERE platform='TM' AND trans_cycle='T+1' AND store_name='TM'
       AND page_type='2' AND 1=1 AND customer_type='ALL'
       AND channel = '全站推'
       AND data_date >= '2025-01-01' AND data_date <= '2026-07-14'), 0) AS roi_val
UNION ALL
-- ── Level 1 小计行：category = 'Sweaters' ──
SELECT
    '5. ROI 全站推' AS metric_name,
    'L1: category=Sweaters' AS row_level,
    '全站推sales(行维度) / 全站推cost(行维度)' AS remark,
    (SELECT SUM(media_sales_amt) FROM indep_rl_ads.a05_e2e_paid_media_summary_d
     WHERE platform='TM' AND trans_cycle='T+1' AND store_name='TM'
       AND page_type='2' AND 1=1 AND customer_type='ALL'
       AND channel = '全站推'
       AND data_date >= '2025-01-01' AND data_date <= '2026-07-14'
       AND category = 'Sweaters')
    / NULLIF((SELECT SUM(cost_amt) FROM indep_rl_ads.a05_e2e_paid_media_summary_d
     WHERE platform='TM' AND trans_cycle='T+1' AND store_name='TM'
       AND page_type='2' AND 1=1 AND customer_type='ALL'
       AND channel = '全站推'
       AND data_date >= '2025-01-01' AND data_date <= '2026-07-14'
       AND category = 'Sweaters'), 0) AS roi_val
UNION ALL
-- ── Level 2 小计行：category='Sweaters' AND framework='Foundation' ──
SELECT
    '5. ROI 全站推' AS metric_name,
    'L2: Sweaters > Foundation' AS row_level,
    '全站推sales(行维度) / 全站推cost(行维度)' AS remark,
    (SELECT SUM(media_sales_amt) FROM indep_rl_ads.a05_e2e_paid_media_summary_d
     WHERE platform='TM' AND trans_cycle='T+1' AND store_name='TM'
       AND page_type='2' AND 1=1 AND customer_type='ALL'
       AND channel = '全站推'
       AND data_date >= '2025-01-01' AND data_date <= '2026-07-14'
       AND category = 'Sweaters' AND framework = 'Foundation')
    / NULLIF((SELECT SUM(cost_amt) FROM indep_rl_ads.a05_e2e_paid_media_summary_d
     WHERE platform='TM' AND trans_cycle='T+1' AND store_name='TM'
       AND page_type='2' AND 1=1 AND customer_type='ALL'
       AND channel = '全站推'
       AND data_date >= '2025-01-01' AND data_date <= '2026-07-14'
       AND category = 'Sweaters' AND framework = 'Foundation'), 0) AS roi_val
UNION ALL
-- ── Level 3 明细行：category='Sweaters' AND framework='Foundation' AND brand='M Polo' ──
SELECT
    '5. ROI 全站推' AS metric_name,
    'L3: Sweaters > Foundation > M Polo' AS row_level,
    '全站推sales(行维度) / 全站推cost(行维度)' AS remark,
    (SELECT SUM(media_sales_amt) FROM indep_rl_ads.a05_e2e_paid_media_summary_d
     WHERE platform='TM' AND trans_cycle='T+1' AND store_name='TM'
       AND page_type='2' AND 1=1 AND customer_type='ALL'
       AND channel = '全站推'
       AND data_date >= '2025-01-01' AND data_date <= '2026-07-14'
       AND category = 'Sweaters' AND framework = 'Foundation' AND brand = 'M Polo')
    / NULLIF((SELECT SUM(cost_amt) FROM indep_rl_ads.a05_e2e_paid_media_summary_d
     WHERE platform='TM' AND trans_cycle='T+1' AND store_name='TM'
       AND page_type='2' AND 1=1 AND customer_type='ALL'
       AND channel = '全站推'
       AND data_date >= '2025-01-01' AND data_date <= '2026-07-14'
       AND category = 'Sweaters' AND framework = 'Foundation' AND brand = 'M Polo'), 0) AS roi_val;


-- ████████████████████████████████████████████████████████████████████████████████
-- PART 6: New Customer Cost% Total（ColMetric_ID=11，格式 decimal_1dp）
-- ████████████████████████████████████████████████████████████████████████████████
-- DAX 口径：
--   Total 行和明细行口径一致：三渠道 NEW cost / 三渠道(NEW+EXISTING) cost
--   Total 行 = TTL 三渠道 NEW / TTL 三渠道(NEW+EXISTING)（无行维度）
--   明细行 = 分组三渠道 NEW / 分组三渠道(NEW+EXISTING)（受行维度筛选）
--   channel 范围：直通车 / 引力魔方 / 全站推
--   分子 customer_type = 'NEW'，分母 customer_type IN ('NEW','EXISTING')

SELECT
    '6. New Customer Cost% Total'                            AS metric_name,
    'Total 总计行'                                           AS row_level,
    '三渠道NEW(TTL) / 三渠道(NEW+EXISTING)(TTL)'             AS remark,
    (SELECT SUM(cost_amt) FROM indep_rl_ads.a05_e2e_paid_media_summary_d
     WHERE platform='TM' AND trans_cycle='T+1' AND store_name='TM'
       AND page_type='2' AND 1=1
       AND customer_type = 'NEW'
       AND channel IN ('直通车','引力魔方','全站推')
       AND data_date >= '2025-01-01' AND data_date <= '2026-07-14')
    / NULLIF((SELECT SUM(cost_amt) FROM indep_rl_ads.a05_e2e_paid_media_summary_d
     WHERE platform='TM' AND trans_cycle='T+1' AND store_name='TM'
       AND page_type='2' AND 1=1
       AND customer_type IN ('NEW','EXISTING')
       AND channel IN ('直通车','引力魔方','全站推')
       AND data_date >= '2025-01-01' AND data_date <= '2026-07-14'), 0) AS new_cust_cost_pct
UNION ALL
-- ── Level 1 小计行：category = 'Sweaters' ──
SELECT
    '6. New Customer Cost% Total' AS metric_name,
    'L1: category=Sweaters' AS row_level,
    '三渠道NEW(行维度) / 三渠道(NEW+EXISTING)(行维度)' AS remark,
    (SELECT SUM(cost_amt) FROM indep_rl_ads.a05_e2e_paid_media_summary_d
     WHERE platform='TM' AND trans_cycle='T+1' AND store_name='TM'
       AND page_type='2' AND 1=1
       AND customer_type = 'NEW'
       AND channel IN ('直通车','引力魔方','全站推')
       AND data_date >= '2025-01-01' AND data_date <= '2026-07-14'
       AND category = 'Sweaters')
    / NULLIF((SELECT SUM(cost_amt) FROM indep_rl_ads.a05_e2e_paid_media_summary_d
     WHERE platform='TM' AND trans_cycle='T+1' AND store_name='TM'
       AND page_type='2' AND 1=1
       AND customer_type IN ('NEW','EXISTING')
       AND channel IN ('直通车','引力魔方','全站推')
       AND data_date >= '2025-01-01' AND data_date <= '2026-07-14'
       AND category = 'Sweaters'), 0) AS new_cust_cost_pct
UNION ALL
-- ── Level 2 小计行：category='Sweaters' AND framework='Foundation' ──
SELECT
    '6. New Customer Cost% Total' AS metric_name,
    'L2: Sweaters > Foundation' AS row_level,
    '三渠道NEW(行维度) / 三渠道(NEW+EXISTING)(行维度)' AS remark,
    (SELECT SUM(cost_amt) FROM indep_rl_ads.a05_e2e_paid_media_summary_d
     WHERE platform='TM' AND trans_cycle='T+1' AND store_name='TM'
       AND page_type='2' AND 1=1
       AND customer_type = 'NEW'
       AND channel IN ('直通车','引力魔方','全站推')
       AND data_date >= '2025-01-01' AND data_date <= '2026-07-14'
       AND category = 'Sweaters' AND framework = 'Foundation')
    / NULLIF((SELECT SUM(cost_amt) FROM indep_rl_ads.a05_e2e_paid_media_summary_d
     WHERE platform='TM' AND trans_cycle='T+1' AND store_name='TM'
       AND page_type='2' AND 1=1
       AND customer_type IN ('NEW','EXISTING')
       AND channel IN ('直通车','引力魔方','全站推')
       AND data_date >= '2025-01-01' AND data_date <= '2026-07-14'
       AND category = 'Sweaters' AND framework = 'Foundation'), 0) AS new_cust_cost_pct
UNION ALL
-- ── Level 3 明细行：category='Sweaters' AND framework='Foundation' AND brand='M Polo' ──
SELECT
    '6. New Customer Cost% Total' AS metric_name,
    'L3: Sweaters > Foundation > M Polo' AS row_level,
    '三渠道NEW(行维度) / 三渠道(NEW+EXISTING)(行维度)' AS remark,
    (SELECT SUM(cost_amt) FROM indep_rl_ads.a05_e2e_paid_media_summary_d
     WHERE platform='TM' AND trans_cycle='T+1' AND store_name='TM'
       AND page_type='2' AND 1=1
       AND customer_type = 'NEW'
       AND channel IN ('直通车','引力魔方','全站推')
       AND data_date >= '2025-01-01' AND data_date <= '2026-07-14'
       AND category = 'Sweaters' AND framework = 'Foundation' AND brand = 'M Polo')
    / NULLIF((SELECT SUM(cost_amt) FROM indep_rl_ads.a05_e2e_paid_media_summary_d
     WHERE platform='TM' AND trans_cycle='T+1' AND store_name='TM'
       AND page_type='2' AND 1=1
       AND customer_type IN ('NEW','EXISTING')
       AND channel IN ('直通车','引力魔方','全站推')
       AND data_date >= '2025-01-01' AND data_date <= '2026-07-14'
       AND category = 'Sweaters' AND framework = 'Foundation' AND brand = 'M Polo'), 0) AS new_cust_cost_pct;


-- ████████████████████████████████████████████████████████████████████████████████
-- PART 7: New Customer Cost% 引力魔方（ColMetric_ID=13，格式 decimal_1dp）
-- ████████████████████████████████████████████████████████████████████████████████
-- DAX 口径：
--   Total 行和明细行口径一致：引力魔方 NEW cost / 引力魔方(NEW+EXISTING) cost
--   Total 行 = TTL 引力魔方 NEW / TTL 引力魔方(NEW+EXISTING)（无行维度）
--   明细行 = 分组引力魔方 NEW / 分组引力魔方(NEW+EXISTING)（受行维度筛选）
--   channel = '引力魔方'
--   分子 customer_type = 'NEW'，分母 customer_type IN ('NEW','EXISTING')

SELECT
    '7. New Customer Cost% 引力魔方'                         AS metric_name,
    'Total 总计行'                                           AS row_level,
    '引力魔方NEW(TTL) / 引力魔方(NEW+EXISTING)(TTL)'         AS remark,
    (SELECT SUM(cost_amt) FROM indep_rl_ads.a05_e2e_paid_media_summary_d
     WHERE platform='TM' AND trans_cycle='T+1' AND store_name='TM'
       AND page_type='2' AND 1=1
       AND customer_type = 'NEW'
       AND channel = '引力魔方'
       AND data_date >= '2025-01-01' AND data_date <= '2026-07-14')
    / NULLIF((SELECT SUM(cost_amt) FROM indep_rl_ads.a05_e2e_paid_media_summary_d
     WHERE platform='TM' AND trans_cycle='T+1' AND store_name='TM'
       AND page_type='2' AND 1=1
       AND customer_type IN ('NEW','EXISTING')
       AND channel = '引力魔方'
       AND data_date >= '2025-01-01' AND data_date <= '2026-07-14'), 0) AS new_cust_cost_pct
UNION ALL
-- ── Level 1 小计行：category = 'Sweaters' ──
SELECT
    '7. New Customer Cost% 引力魔方' AS metric_name,
    'L1: category=Sweaters' AS row_level,
    '引力魔方NEW(行维度) / 引力魔方(NEW+EXISTING)(行维度)' AS remark,
    (SELECT SUM(cost_amt) FROM indep_rl_ads.a05_e2e_paid_media_summary_d
     WHERE platform='TM' AND trans_cycle='T+1' AND store_name='TM'
       AND page_type='2' AND 1=1
       AND customer_type = 'NEW'
       AND channel = '引力魔方'
       AND data_date >= '2025-01-01' AND data_date <= '2026-07-14'
       AND category = 'Sweaters')
    / NULLIF((SELECT SUM(cost_amt) FROM indep_rl_ads.a05_e2e_paid_media_summary_d
     WHERE platform='TM' AND trans_cycle='T+1' AND store_name='TM'
       AND page_type='2' AND 1=1
       AND customer_type IN ('NEW','EXISTING')
       AND channel = '引力魔方'
       AND data_date >= '2025-01-01' AND data_date <= '2026-07-14'
       AND category = 'Sweaters'), 0) AS new_cust_cost_pct
UNION ALL
-- ── Level 2 小计行：category='Sweaters' AND framework='Foundation' ──
SELECT
    '7. New Customer Cost% 引力魔方' AS metric_name,
    'L2: Sweaters > Foundation' AS row_level,
    '引力魔方NEW(行维度) / 引力魔方(NEW+EXISTING)(行维度)' AS remark,
    (SELECT SUM(cost_amt) FROM indep_rl_ads.a05_e2e_paid_media_summary_d
     WHERE platform='TM' AND trans_cycle='T+1' AND store_name='TM'
       AND page_type='2' AND 1=1
       AND customer_type = 'NEW'
       AND channel = '引力魔方'
       AND data_date >= '2025-01-01' AND data_date <= '2026-07-14'
       AND category = 'Sweaters' AND framework = 'Foundation')
    / NULLIF((SELECT SUM(cost_amt) FROM indep_rl_ads.a05_e2e_paid_media_summary_d
     WHERE platform='TM' AND trans_cycle='T+1' AND store_name='TM'
       AND page_type='2' AND 1=1
       AND customer_type IN ('NEW','EXISTING')
       AND channel = '引力魔方'
       AND data_date >= '2025-01-01' AND data_date <= '2026-07-14'
       AND category = 'Sweaters' AND framework = 'Foundation'), 0) AS new_cust_cost_pct
UNION ALL
-- ── Level 3 明细行：category='Sweaters' AND framework='Foundation' AND brand='M Polo' ──
SELECT
    '7. New Customer Cost% 引力魔方' AS metric_name,
    'L3: Sweaters > Foundation > M Polo' AS row_level,
    '引力魔方NEW(行维度) / 引力魔方(NEW+EXISTING)(行维度)' AS remark,
    (SELECT SUM(cost_amt) FROM indep_rl_ads.a05_e2e_paid_media_summary_d
     WHERE platform='TM' AND trans_cycle='T+1' AND store_name='TM'
       AND page_type='2' AND 1=1
       AND customer_type = 'NEW'
       AND channel = '引力魔方'
       AND data_date >= '2025-01-01' AND data_date <= '2026-07-14'
       AND category = 'Sweaters' AND framework = 'Foundation' AND brand = 'M Polo')
    / NULLIF((SELECT SUM(cost_amt) FROM indep_rl_ads.a05_e2e_paid_media_summary_d
     WHERE platform='TM' AND trans_cycle='T+1' AND store_name='TM'
       AND page_type='2' AND 1=1
       AND customer_type IN ('NEW','EXISTING')
       AND channel = '引力魔方'
       AND data_date >= '2025-01-01' AND data_date <= '2026-07-14'
       AND category = 'Sweaters' AND framework = 'Foundation' AND brand = 'M Polo'), 0) AS new_cust_cost_pct;


-- ████████████████████████████████████████████████████████████████████████████████
-- 附录：底层明细数据查询（用于排查差异）
-- ████████████████████████████████████████████████████████████████████████████████
-- 查询 Level 3 明细行（Sweaters > Foundation > M Polo）的底层聚合数据
-- 可用于手动复核各指标分子分母

SELECT
    category,
    framework,
    brand,
    channel,
    customer_type,
    SUM(cost_amt)               AS cost_amt,
    SUM(net_sales_amt)          AS net_sales_amt,
    SUM(media_sales_amt)        AS media_sales_amt,
    COUNT(*)                    AS row_cnt,
    COUNT(DISTINCT data_date)   AS date_cnt
FROM indep_rl_ads.a05_e2e_paid_media_summary_d
WHERE platform = 'TM'
  AND trans_cycle = 'T+1'
  AND store_name = 'TM'
  AND page_type = '2'
  AND data_date >= '2025-01-01'
  AND data_date <= '2026-07-14'
  AND category = 'Sweaters'
  AND framework = 'Foundation'
  AND brand = 'M Polo'
GROUP BY category, framework, brand, channel, customer_type
ORDER BY channel, customer_type;
