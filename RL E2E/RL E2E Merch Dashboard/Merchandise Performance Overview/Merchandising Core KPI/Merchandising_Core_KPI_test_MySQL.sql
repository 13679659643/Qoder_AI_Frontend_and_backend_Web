-- ========================================
-- 文件: Merchandising_Core_KPI_test_MySQL.sql
-- 模块: RL E2E Merch Dashboard - Merchandise Performance Overview - Merchandising Core KPI
-- 用途: Power BI 度量值对照测试（MySQL 语法，10 个指标组 = 10 段 SQL）
--       覆盖主指标 Act + 附属指标 vs LY + 【Amt】/【Unit】双模式
-- 底表: indep_rl_ads.a02_e2e_product_performance_sales_summary_d（销售类）
--       indep_rl_ads.a02_e2e_product_performance_inv_summary_d（库存类）
--
-- 测试筛选条件（与 Power BI 状态一致）:
--   This Period : data_date ∈ ['2026-03-29', '2026-09-26']
--   Last Period : data_date ∈ ['2025-03-30', '2025-09-27']
--   期末快照日  : This = '2026-09-26'；LY = '2025-09-27'（单日时点）
--   商品标签    : IsProductTagFilter = "ALL"
--                 → computed_product_tag IN ('hero model', 'slow mover', 'normal')
--   其余筛选器  : 全选（platform / shop_name / label / division / ... 不附加条件）
--   sales 表额外对齐 PBI 数据源加载过滤: platform IN ('JD', 'TM', 'RLE', 'DY')
--   （inv 表无 platform / shop_name 维度，不涉及）
--
-- 段落与 PBI 列（Dim_ColMetric_Merchandising_Core_KPI[Metric_ID]）对应关系:
--   段 1  SLS        → 1（Act）/ 2（vs LY）；3,4（TAR ACH% 占位，无 SQL）
--   段 2  ST%        → 5（Act）/ 6（vs LY）
--   段 3  AVG MD     → 7（Act）/ 8（vs LY）
--   段 4  Fullprice% → 9（Act）/ 10（vs LY）
--   段 5  AUR        → 11（Act）/ 12（vs LY）
--   段 6  EOH        → 13（Act）/ 14（vs LY）
--   段 7  In-Transit → 15（Act，无附属指标）
--   段 8  O2O        → 16（Act，无附属指标）
--   段 9  Inbound    → 17（Act）/ 18（vs LY）
--   段 10 Outbound   → 19（Act）/ 20（vs LY）
--
-- 对比说明:
--   1. data_date 在表中为字符串格式（如 '2025-03-18'），ISO 格式字符串比较与日期比较等价，直接字符串比较
--   2. 金额字段均为 RMB 原始值；Power BI 币种选 USD 时 Cell Value 会 ÷ Currency_ExchangeRate，
--      对比前先确认币种切片器（RMB 时汇率 = 1，可直接对比）
--   3. vs LY 变化率 = This / Last - 1（如 0.1523 → PBI 显示 +15%）
--   4. vs LY 差值 bp = This - Last（原始差值，如 -0.0152 → PBI 显示 -152bp，×10000 在展示层）
--   5. TAR ACH% Progress / Target 为占位符（返回 1 / 2），无计算公式，不提供测试 SQL
--   6. 期末快照当日缺数时，Power BI 度量值会回退到 end period 范围内最近一个快照日，
--      SQL 对比时如发现快照日无数据，需相应调整日期
--   7. 除法分母为 0 或 NULL 时 MySQL 返回 NULL，对应 Power BI 的 BLANK（显示 "-"）
-- ========================================


-- ════════════════════════════════════════════════════════════════
-- 段 1：SLS — DCom 净销售额 / 净销售数量（sales 表，区间汇总）
-- 口径: Amt = sum(net_sales_amt)；Unit = sum(net_sales_qty)
-- 附属: vs LY = This / Last - 1（变化率）；TAR ACH%（Metric_ID 3/4）为占位符，无 SQL
-- ════════════════════════════════════════════════════════════════
WITH agg AS (
    SELECT
        -- Amt 模式
        SUM(CASE WHEN data_date BETWEEN '2026-03-29' AND '2026-09-26' THEN net_sales_amt ELSE 0 END) AS sls_amt_this,
        SUM(CASE WHEN data_date BETWEEN '2025-03-30' AND '2025-09-27' THEN net_sales_amt ELSE 0 END) AS sls_amt_last,
        -- Unit 模式
        SUM(CASE WHEN data_date BETWEEN '2026-03-29' AND '2026-09-26' THEN net_sales_qty ELSE 0 END) AS sls_unit_this,
        SUM(CASE WHEN data_date BETWEEN '2025-03-30' AND '2025-09-27' THEN net_sales_qty ELSE 0 END) AS sls_unit_last
    FROM indep_rl_ads.a02_e2e_product_performance_sales_summary_d
    WHERE computed_product_tag IN ('hero model', 'slow mover', 'normal')   -- IsProductTagFilter = ALL
      AND platform IN ('JD', 'TM', 'RLE', 'DY')                            -- 对齐 PBI 数据源加载过滤
      AND (
            data_date BETWEEN '2026-03-29' AND '2026-09-26'                -- This Period
         OR data_date BETWEEN '2025-03-30' AND '2025-09-27'                -- Last Period
      )
)
SELECT
    sls_amt_this,                                                    -- Metric_ID=1  SLS Amt Act（RMB 原值）
    sls_amt_last,                                                    -- LY 基线（对比用，PBI 不显示）
    sls_amt_this  / sls_amt_last  - 1 AS sls_amt_vs_ly,              -- Metric_ID=2  SLS Amt vs LY（0.1523 → +15%）
    sls_unit_this,                                                   -- Metric_ID=1  SLS Unit Act（Unit 模式）
    sls_unit_last,                                                   -- LY 基线（对比用，PBI 不显示）
    sls_unit_this / sls_unit_last - 1 AS sls_unit_vs_ly              -- Metric_ID=2  SLS Unit vs LY
FROM agg;


-- ════════════════════════════════════════════════════════════════
-- 段 2：ST% — 售罄率%（sales 分子区间汇总 + inv 分母期末快照，跨双表）
-- 口径 Amt : net_sales_amt / (net_sales_amt + msrp_inv_amt)
-- 口径 Unit: net_sales_qty / (net_sales_qty + inv_qty)
-- 附属: vs LY = This - Last（差值 bp，展示时 ×10000 转 bp）
-- ════════════════════════════════════════════════════════════════
WITH sales_agg AS (
    SELECT
        -- Amt 模式分子
        SUM(CASE WHEN data_date BETWEEN '2026-03-29' AND '2026-09-26' THEN net_sales_amt ELSE 0 END) AS net_sales_amt_this,
        SUM(CASE WHEN data_date BETWEEN '2025-03-30' AND '2025-09-27' THEN net_sales_amt ELSE 0 END) AS net_sales_amt_last,
        -- Unit 模式分子
        SUM(CASE WHEN data_date BETWEEN '2026-03-29' AND '2026-09-26' THEN net_sales_qty ELSE 0 END) AS net_sales_qty_this,
        SUM(CASE WHEN data_date BETWEEN '2025-03-30' AND '2025-09-27' THEN net_sales_qty ELSE 0 END) AS net_sales_qty_last
    FROM indep_rl_ads.a02_e2e_product_performance_sales_summary_d
    WHERE computed_product_tag IN ('hero model', 'slow mover', 'normal')   -- IsProductTagFilter = ALL
      AND platform IN ('JD', 'TM', 'RLE', 'DY')                            -- 对齐 PBI 数据源加载过滤
      AND (
            data_date BETWEEN '2026-03-29' AND '2026-09-26'                -- This Period（分子 = 整个区间）
         OR data_date BETWEEN '2025-03-30' AND '2025-09-27'                -- Last Period
      )
),
inv_end AS (
    SELECT
        -- Amt 模式分母（期末快照单日时点）
        SUM(CASE WHEN data_date = '2026-09-26' THEN msrp_inv_amt ELSE 0 END) AS msrp_inv_amt_end_this,   -- This 期末
        SUM(CASE WHEN data_date = '2025-09-27' THEN msrp_inv_amt ELSE 0 END) AS msrp_inv_amt_end_last,   -- LY 期末
        -- Unit 模式分母
        SUM(CASE WHEN data_date = '2026-09-26' THEN inv_qty ELSE 0 END)       AS inv_qty_end_this,
        SUM(CASE WHEN data_date = '2025-09-27' THEN inv_qty ELSE 0 END)       AS inv_qty_end_last
    FROM indep_rl_ads.a02_e2e_product_performance_inv_summary_d
    WHERE computed_product_tag IN ('hero model', 'slow mover', 'normal')   -- inv 无渠道维度，仅标签过滤
      AND data_date IN ('2026-09-26', '2025-09-27')                        -- 仅期末快照日（单日，不可区间求和）
)
SELECT
    -- Metric_ID=5  ST% Amt Act（0.6234 → PBI 显示 62%）
    s.net_sales_amt_this / (s.net_sales_amt_this + i.msrp_inv_amt_end_this) AS stpct_amt_this,
    -- LY 基线（对比用）
    s.net_sales_amt_last / (s.net_sales_amt_last + i.msrp_inv_amt_end_last) AS stpct_amt_last,
    -- Metric_ID=6  ST% Amt vs LY（差值 bp，-0.0152 → PBI 显示 -152bp）
    s.net_sales_amt_this / (s.net_sales_amt_this + i.msrp_inv_amt_end_this)
      - s.net_sales_amt_last / (s.net_sales_amt_last + i.msrp_inv_amt_end_last) AS stpct_amt_vs_ly_bp,
    -- Metric_ID=5  ST% Unit Act（Unit 模式）
    s.net_sales_qty_this / (s.net_sales_qty_this + i.inv_qty_end_this) AS stpct_unit_this,
    -- LY 基线（对比用）
    s.net_sales_qty_last / (s.net_sales_qty_last + i.inv_qty_end_last) AS stpct_unit_last,
    -- Metric_ID=6  ST% Unit vs LY（差值 bp）
    s.net_sales_qty_this / (s.net_sales_qty_this + i.inv_qty_end_this)
      - s.net_sales_qty_last / (s.net_sales_qty_last + i.inv_qty_end_last) AS stpct_unit_vs_ly_bp
FROM sales_agg s
CROSS JOIN inv_end i;


-- ════════════════════════════════════════════════════════════════
-- 段 3：AVG MD — 平均折扣（sales 表，区间汇总；Amt/Unit 同一套逻辑，不重复输出）
-- 口径: 1 - sum(md_net_sales_amt) / sum(msrp_net_sales_amt)
-- 附属: vs LY = This - Last（差值 bp，展示时 ×10000 转 bp）
-- ════════════════════════════════════════════════════════════════
WITH agg AS (
    SELECT
        SUM(CASE WHEN data_date BETWEEN '2026-03-29' AND '2026-09-26' THEN md_net_sales_amt ELSE 0 END)   AS md_amt_this,
        SUM(CASE WHEN data_date BETWEEN '2025-03-30' AND '2025-09-27' THEN md_net_sales_amt ELSE 0 END)   AS md_amt_last,
        SUM(CASE WHEN data_date BETWEEN '2026-03-29' AND '2026-09-26' THEN msrp_net_sales_amt ELSE 0 END)  AS msrp_amt_this,
        SUM(CASE WHEN data_date BETWEEN '2025-03-30' AND '2025-09-27' THEN msrp_net_sales_amt ELSE 0 END)  AS msrp_amt_last
    FROM indep_rl_ads.a02_e2e_product_performance_sales_summary_d
    WHERE computed_product_tag IN ('hero model', 'slow mover', 'normal')   -- IsProductTagFilter = ALL
      AND platform IN ('JD', 'TM', 'RLE', 'DY')                            -- 对齐 PBI 数据源加载过滤
      AND (
            data_date BETWEEN '2026-03-29' AND '2026-09-26'                -- This Period
         OR data_date BETWEEN '2025-03-30' AND '2025-09-27'                -- Last Period
      )
)
SELECT
    1 - md_amt_this / msrp_amt_this AS avg_md_this,                  -- Metric_ID=7  AVG MD Act（0.2834 → PBI 显示 28%）
    1 - md_amt_last / msrp_amt_last AS avg_md_last,                  -- LY 基线（对比用）
    (1 - md_amt_this / msrp_amt_this)
      - (1 - md_amt_last / msrp_amt_last) AS avg_md_vs_ly_bp         -- Metric_ID=8  vs LY（差值 bp，0.0121 → +121bp）
FROM agg;


-- ════════════════════════════════════════════════════════════════
-- 段 4：Fullprice% — 全价率（sales 表，区间汇总；Amt/Unit 公式不同）
-- 口径 Amt : sum(net_sales_amt where md_type = 'FP') / sum(net_sales_amt)
-- 口径 Unit: sum(msrp_net_sales_amt) / sum(net_sales_amt)（口径已确认，分子分母均为金额字段）
-- 附属: vs LY = This - Last（差值 bp，展示时 ×10000 转 bp）
-- ════════════════════════════════════════════════════════════════
WITH agg AS (
    SELECT
        -- Amt 模式分子：md_type = 'FP'
        SUM(CASE WHEN data_date BETWEEN '2026-03-29' AND '2026-09-26' AND md_type = 'FP' THEN net_sales_amt ELSE 0 END) AS fp_amt_this,
        SUM(CASE WHEN data_date BETWEEN '2025-03-30' AND '2025-09-27' AND md_type = 'FP' THEN net_sales_amt ELSE 0 END) AS fp_amt_last,
        -- 公共分母：sum(net_sales_amt)
        SUM(CASE WHEN data_date BETWEEN '2026-03-29' AND '2026-09-26' THEN net_sales_amt ELSE 0 END)       AS net_amt_this,
        SUM(CASE WHEN data_date BETWEEN '2025-03-30' AND '2025-09-27' THEN net_sales_amt ELSE 0 END)       AS net_amt_last,
        -- Unit 模式分子：sum(msrp_net_sales_amt)
        SUM(CASE WHEN data_date BETWEEN '2026-03-29' AND '2026-09-26' THEN msrp_net_sales_amt ELSE 0 END)  AS msrp_amt_this,
        SUM(CASE WHEN data_date BETWEEN '2025-03-30' AND '2025-09-27' THEN msrp_net_sales_amt ELSE 0 END)  AS msrp_amt_last
    FROM indep_rl_ads.a02_e2e_product_performance_sales_summary_d
    WHERE computed_product_tag IN ('hero model', 'slow mover', 'normal')   -- IsProductTagFilter = ALL
      AND platform IN ('JD', 'TM', 'RLE', 'DY')                            -- 对齐 PBI 数据源加载过滤
      AND (
            data_date BETWEEN '2026-03-29' AND '2026-09-26'                -- This Period
         OR data_date BETWEEN '2025-03-30' AND '2025-09-27'                -- Last Period
      )
)
SELECT
    -- Metric_ID=9  Fullprice% Amt Act（0.5123 → PBI 显示 51%）
    fp_amt_this / net_amt_this   AS fullprice_pct_amt_this,
    -- LY 基线（对比用）
    fp_amt_last / net_amt_last   AS fullprice_pct_amt_last,
    -- Metric_ID=10 Fullprice% Amt vs LY（差值 bp）
    fp_amt_this / net_amt_this - fp_amt_last / net_amt_last AS fullprice_pct_amt_vs_ly_bp,
    -- Metric_ID=9  Fullprice% Unit Act（Unit 模式）
    msrp_amt_this / net_amt_this AS fullprice_pct_unit_this,
    -- LY 基线（对比用）
    msrp_amt_last / net_amt_last AS fullprice_pct_unit_last,
    -- Metric_ID=10 Fullprice% Unit vs LY（差值 bp）
    msrp_amt_this / net_amt_this - msrp_amt_last / net_amt_last AS fullprice_pct_unit_vs_ly_bp
FROM agg;


-- ════════════════════════════════════════════════════════════════
-- 段 5：AUR — 件单价（sales 表，区间汇总；Amt/Unit 同一套逻辑，不重复输出；金额类）
-- 口径: sum(net_sales_amt) / sum(net_sales_qty)
-- 附属: vs LY = This / Last - 1（变化率）
-- ════════════════════════════════════════════════════════════════
WITH agg AS (
    SELECT
        SUM(CASE WHEN data_date BETWEEN '2026-03-29' AND '2026-09-26' THEN net_sales_amt ELSE 0 END) AS net_amt_this,
        SUM(CASE WHEN data_date BETWEEN '2025-03-30' AND '2025-09-27' THEN net_sales_amt ELSE 0 END) AS net_amt_last,
        SUM(CASE WHEN data_date BETWEEN '2026-03-29' AND '2026-09-26' THEN net_sales_qty ELSE 0 END) AS net_qty_this,
        SUM(CASE WHEN data_date BETWEEN '2025-03-30' AND '2025-09-27' THEN net_sales_qty ELSE 0 END) AS net_qty_last
    FROM indep_rl_ads.a02_e2e_product_performance_sales_summary_d
    WHERE computed_product_tag IN ('hero model', 'slow mover', 'normal')   -- IsProductTagFilter = ALL
      AND platform IN ('JD', 'TM', 'RLE', 'DY')                            -- 对齐 PBI 数据源加载过滤
      AND (
            data_date BETWEEN '2026-03-29' AND '2026-09-26'                -- This Period
         OR data_date BETWEEN '2025-03-30' AND '2025-09-27'                -- Last Period
      )
)
SELECT
    net_amt_this / net_qty_this AS aur_this,                          -- Metric_ID=11 AUR Act（RMB 原值；USD 时 PBI 会 ÷ 汇率）
    net_amt_last / net_qty_last AS aur_last,                          -- LY 基线（对比用）
    (net_amt_this / net_qty_this)
      / (net_amt_last / net_qty_last) - 1 AS aur_vs_ly                -- Metric_ID=12 AUR vs LY（0.0834 → +8%）
FROM agg;


-- ════════════════════════════════════════════════════════════════
-- 段 6：EOH — 期末库存（inv 表，期末快照单日时点；无渠道维度）
-- 口径 Amt: sum(msrp_inv_amt)；Unit: sum(inv_qty)
-- 附属: vs LY = This / Last - 1（变化率）
-- ════════════════════════════════════════════════════════════════
WITH agg AS (
    SELECT
        -- Amt 模式（期末快照单日，不可区间求和）
        SUM(CASE WHEN data_date = '2026-09-26' THEN msrp_inv_amt ELSE 0 END) AS eoh_amt_this,   -- This 期末
        SUM(CASE WHEN data_date = '2025-09-27' THEN msrp_inv_amt ELSE 0 END) AS eoh_amt_last,   -- LY 期末
        -- Unit 模式
        SUM(CASE WHEN data_date = '2026-09-26' THEN inv_qty ELSE 0 END)       AS eoh_unit_this,
        SUM(CASE WHEN data_date = '2025-09-27' THEN inv_qty ELSE 0 END)       AS eoh_unit_last
    FROM indep_rl_ads.a02_e2e_product_performance_inv_summary_d
    WHERE computed_product_tag IN ('hero model', 'slow mover', 'normal')   -- inv 无渠道维度，仅标签过滤
      AND data_date IN ('2026-09-26', '2025-09-27')                        -- 仅期末快照日
)
SELECT
    eoh_amt_this,                                                    -- Metric_ID=13 EOH Amt Act（RMB 原值）
    eoh_amt_last,                                                    -- LY 基线（对比用）
    eoh_amt_this  / eoh_amt_last  - 1 AS eoh_amt_vs_ly,              -- Metric_ID=14 EOH Amt vs LY
    eoh_unit_this,                                                   -- Metric_ID=13 EOH Unit Act（Unit 模式）
    eoh_unit_last,                                                   -- LY 基线（对比用）
    eoh_unit_this / eoh_unit_last - 1 AS eoh_unit_vs_ly              -- Metric_ID=14 EOH Unit vs LY
FROM agg;


-- ════════════════════════════════════════════════════════════════
-- 段 7：In-Transit Inventory — 在途库存（inv 表，期末快照单日时点；无附属指标）
-- 口径 Amt: sum(msrp_in_trans_inv_amt)；Unit: sum(in_trans_inv_qty)
-- ════════════════════════════════════════════════════════════════
SELECT
    SUM(msrp_in_trans_inv_amt) AS in_transit_amt_this,               -- Metric_ID=15 In-Transit Amt Act（RMB 原值）
    SUM(in_trans_inv_qty)      AS in_transit_unit_this               -- Metric_ID=15 In-Transit Unit Act（Unit 模式）
FROM indep_rl_ads.a02_e2e_product_performance_inv_summary_d
WHERE computed_product_tag IN ('hero model', 'slow mover', 'normal')   -- inv 无渠道维度，仅标签过滤
  AND data_date = '2026-09-26';                                         -- This 期末快照日（单日时点）


-- ════════════════════════════════════════════════════════════════
-- 段 8：O2O Inventory — O2O 库存（inv 表，期末快照单日时点；无附属指标）
-- 口径 Amt: sum(msrp_o2o_inv_amt)；Unit: sum(o2o_inv_qty)
-- ════════════════════════════════════════════════════════════════
SELECT
    SUM(msrp_o2o_inv_amt) AS o2o_amt_this,                           -- Metric_ID=16 O2O Amt Act（RMB 原值）
    SUM(o2o_inv_qty)      AS o2o_unit_this                           -- Metric_ID=16 O2O Unit Act（Unit 模式）
FROM indep_rl_ads.a02_e2e_product_performance_inv_summary_d
WHERE computed_product_tag IN ('hero model', 'slow mover', 'normal')   -- inv 无渠道维度，仅标签过滤
  AND data_date = '2026-09-26';                                         -- This 期末快照日（单日时点）


-- ════════════════════════════════════════════════════════════════
-- 段 9：Inbound — 入库（sales 表，区间汇总）
-- 口径 Amt: sum(msrp_inbound_amt)；Unit: sum(inbound_qty)
-- 附属: vs LY = This / Last - 1（变化率）
-- ════════════════════════════════════════════════════════════════
WITH agg AS (
    SELECT
        -- Amt 模式
        SUM(CASE WHEN data_date BETWEEN '2026-03-29' AND '2026-09-26' THEN msrp_inbound_amt ELSE 0 END) AS inbound_amt_this,
        SUM(CASE WHEN data_date BETWEEN '2025-03-30' AND '2025-09-27' THEN msrp_inbound_amt ELSE 0 END) AS inbound_amt_last,
        -- Unit 模式
        SUM(CASE WHEN data_date BETWEEN '2026-03-29' AND '2026-09-26' THEN inbound_qty ELSE 0 END)       AS inbound_unit_this,
        SUM(CASE WHEN data_date BETWEEN '2025-03-30' AND '2025-09-27' THEN inbound_qty ELSE 0 END)       AS inbound_unit_last
    FROM indep_rl_ads.a02_e2e_product_performance_sales_summary_d
    WHERE computed_product_tag IN ('hero model', 'slow mover', 'normal')   -- IsProductTagFilter = ALL
      AND platform IN ('JD', 'TM', 'RLE', 'DY')                            -- 对齐 PBI 数据源加载过滤
      AND (
            data_date BETWEEN '2026-03-29' AND '2026-09-26'                -- This Period
         OR data_date BETWEEN '2025-03-30' AND '2025-09-27'                -- Last Period
      )
)
SELECT
    inbound_amt_this,                                                -- Metric_ID=17 Inbound Amt Act（RMB 原值）
    inbound_amt_last,                                                -- LY 基线（对比用）
    inbound_amt_this  / inbound_amt_last  - 1 AS inbound_amt_vs_ly,  -- Metric_ID=18 Inbound Amt vs LY
    inbound_unit_this,                                               -- Metric_ID=17 Inbound Unit Act（Unit 模式）
    inbound_unit_last,                                               -- LY 基线（对比用）
    inbound_unit_this / inbound_unit_last - 1 AS inbound_unit_vs_ly  -- Metric_ID=18 Inbound Unit vs LY
FROM agg;


-- ════════════════════════════════════════════════════════════════
-- 段 10：Outbound — 出库（sales 表，区间汇总）
-- 口径 Amt: sum(md_outbound_amt)；Unit: sum(outbound_qty)
-- 附属: vs LY = This / Last - 1（变化率）
-- ════════════════════════════════════════════════════════════════
WITH agg AS (
    SELECT
        -- Amt 模式
        SUM(CASE WHEN data_date BETWEEN '2026-03-29' AND '2026-09-26' THEN md_outbound_amt ELSE 0 END) AS outbound_amt_this,
        SUM(CASE WHEN data_date BETWEEN '2025-03-30' AND '2025-09-27' THEN md_outbound_amt ELSE 0 END) AS outbound_amt_last,
        -- Unit 模式
        SUM(CASE WHEN data_date BETWEEN '2026-03-29' AND '2026-09-26' THEN outbound_qty ELSE 0 END)     AS outbound_unit_this,
        SUM(CASE WHEN data_date BETWEEN '2025-03-30' AND '2025-09-27' THEN outbound_qty ELSE 0 END)     AS outbound_unit_last
    FROM indep_rl_ads.a02_e2e_product_performance_sales_summary_d
    WHERE computed_product_tag IN ('hero model', 'slow mover', 'normal')   -- IsProductTagFilter = ALL
      AND platform IN ('JD', 'TM', 'RLE', 'DY')                            -- 对齐 PBI 数据源加载过滤
      AND (
            data_date BETWEEN '2026-03-29' AND '2026-09-26'                -- This Period
         OR data_date BETWEEN '2025-03-30' AND '2025-09-27'                -- Last Period
      )
)
SELECT
    outbound_amt_this,                                               -- Metric_ID=19 Outbound Amt Act（RMB 原值）
    outbound_amt_last,                                               -- LY 基线（对比用）
    outbound_amt_this  / outbound_amt_last  - 1 AS outbound_amt_vs_ly,  -- Metric_ID=20 Outbound Amt vs LY
    outbound_unit_this,                                              -- Metric_ID=19 Outbound Unit Act（Unit 模式）
    outbound_unit_last,                                              -- LY 基线（对比用）
    outbound_unit_this / outbound_unit_last - 1 AS outbound_unit_vs_ly -- Metric_ID=20 Outbound Unit vs LY
FROM agg;
