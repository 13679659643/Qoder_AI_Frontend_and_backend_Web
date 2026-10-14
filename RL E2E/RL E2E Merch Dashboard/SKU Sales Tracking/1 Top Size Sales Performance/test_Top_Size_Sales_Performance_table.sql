-- ======================================================================
-- 测试 SQL: Top Size Sales Performance 表格（Sales Top1~4 + Inventory Top1~4）
-- 所属模块: RL E2E Merch Dashboard - SKU Sales Tracking - Top Size Sales Performance
-- 关联方案: Top_Size_Sales Performance_table.md
-- 语法: MySQL 8.0+（CTE / 窗口函数 / 用户变量；低于 8.0 不支持）
-- 用途: 验证 Power BI 八个表格视觉对象的数值口径
--       Sales: SLS Amt% / LP SLS Amt% / vs LP；Inventory: EOH Amt% / LP EOH Amt% / vs LP
--
-- ★参数区★（修改 @division 后需重新执行 SET 语句及全部八段；单独执行任一段前需先执行 SET）
-- Division:              'WM'（单选，可选 WM / CW / HM / MN，每次只选一个值）
-- Platform:              'ALL'（全选，等价不筛选，SQL 中不附加条件）
-- Store Name:            'ALL'（全选，等价不筛选，SQL 中不附加条件）
-- Sales This Period:     dt ∈ ['2026-03-29', '2026-09-26']（区间汇总）
-- Sales Last Period:     dt ∈ ['2025-03-30', '2025-09-27']（区间汇总）
-- Inventory This 时点:   dt = '2026-07-25'（This Period 最后一天，单日快照）
-- Inventory Last 时点:   dt = '2025-07-26'（Last Period 最后一天，单日快照）
--
-- 口径还原说明:
--   1. 两表实际日期字段为 dt（非 data_date），已按数据字典核对
--   2. net_sales_amt 为 Power Query 取数新增列（数据库不存在），按行级
--      ROUND(product_qty × sales_price, 6) 等价还原后再聚合
--   3. category 为 NULL / 空字符 / 纯空格时排除（对应 DAX LEN(TRIM()) > 0）
--   4. 排名用 RANK() 竞争排名，与 DAX RANKX(SKIP) 一致；金额并列时同
--      名次 category 同时返回（若并列第 1，则无 rank=2，Top2 段返回空集）
--   5. 占比分母 = category + sku_size_category 层级（窗口 PARTITION 对应
--      DAX REMOVEFILTERS(sku_size)）
--   6. CASE 无 ELSE：行组合在对应期间无记录或金额全为 NULL 时聚合结果
--      为 NULL，对应 DAX SUM 空集返回 BLANK；占比或分母为空 → 整行过滤
--      （对应视觉级筛选器「Value 不为空」）
--   7. vs LP = this % - last %（任一侧为 NULL 则差值为 NULL，对应 DAX
--      任一期 BLANK 返回 BLANK）；Vs_LP_Bp 为 ×10000 转 bp
--   8. 行序对应 Sort Key：L1 字母尺码 > 数字尺码 > 其余；L2 分组当期金额
--      降序；L3 组内占比升序
-- ======================================================================

SET @division := 'WM';

-- ======================================================================
-- SQL 1/8: Sales Top1（Category Rank = 1）
-- ======================================================================
WITH cat_rank AS (
    SELECT
        category,
        SUM(ROUND(product_qty * sales_price, 6))                                AS cat_net_sales_amt,
        RANK() OVER (ORDER BY SUM(ROUND(product_qty * sales_price, 6)) DESC)    AS cat_rank_no
    FROM indep_rl_dw.s02_trade_sku_data_d
    WHERE dt >= '2026-03-29'
      AND dt <= '2026-09-26'
      AND division = @division
      AND category IS NOT NULL
      AND TRIM(category) <> ''
    GROUP BY category
),
top_category AS (
    SELECT category, cat_rank_no, cat_net_sales_amt
    FROM cat_rank
    WHERE cat_rank_no = 1
),
row_amt AS (
    SELECT
        t.category,
        t.sku_size_category,
        t.sku_size,
        SUM(CASE WHEN t.dt >= '2026-03-29' AND t.dt <= '2026-09-26'
                 THEN ROUND(t.product_qty * t.sales_price, 6) END)              AS this_amt,
        SUM(CASE WHEN t.dt >= '2025-03-30' AND t.dt <= '2025-09-27'
                 THEN ROUND(t.product_qty * t.sales_price, 6) END)              AS last_amt
    FROM indep_rl_dw.s02_trade_sku_data_d t
    WHERE t.division = @division
      AND ( (t.dt >= '2026-03-29' AND t.dt <= '2026-09-26')
         OR (t.dt >= '2025-03-30' AND t.dt <= '2025-09-27') )
      AND t.category IN (SELECT category FROM top_category)
    GROUP BY t.category, t.sku_size_category, t.sku_size
),
pct AS (
    SELECT
        r.*,
        SUM(r.this_amt) OVER (PARTITION BY r.category, r.sku_size_category)    AS this_denom,
        SUM(r.last_amt) OVER (PARTITION BY r.category, r.sku_size_category)    AS last_denom
    FROM row_amt r
)
SELECT
    tc.cat_rank_no        AS Category_Rank,
    tc.cat_net_sales_amt  AS Category_Amt,
    p.category,
    p.sku_size_category,
    p.sku_size,
    p.this_amt                                                                  AS SLS_Amt_Value,
    p.this_amt  / NULLIF(p.this_denom, 0)                                       AS SLS_Amt_Pct,
    p.last_amt  / NULLIF(p.last_denom, 0)                                       AS LP_SLS_Amt_Pct,
    (p.this_amt / NULLIF(p.this_denom, 0)) - (p.last_amt / NULLIF(p.last_denom, 0))
                                                                                AS Vs_LP,
    ((p.this_amt / NULLIF(p.this_denom, 0)) - (p.last_amt / NULLIF(p.last_denom, 0))) * 10000
                                                                                AS Vs_LP_Bp
FROM pct p
JOIN top_category tc
  ON p.category = tc.category
WHERE p.this_amt IS NOT NULL       -- This Period 有记录且金额非全 NULL（对应 DAX SUM 空集 = BLANK）
  AND p.this_denom IS NOT NULL
  AND p.this_denom <> 0            -- 分组分母为空/零 → 占比 BLANK → 行过滤（对应「Value 不为空」）
ORDER BY
    CASE WHEN p.sku_size_category LIKE '%字母尺码%' THEN 0
         WHEN p.sku_size_category LIKE '%数字尺码%' THEN 1
         ELSE 2 END,                                                          -- L1 分组优先级
    p.this_denom DESC,                                                        -- L2 分组当期金额降序
    p.this_amt / NULLIF(p.this_denom, 0) ASC;                                 -- L3 组内占比升序

-- ======================================================================
-- SQL 2/8: Sales Top2（Category Rank = 2）
-- ======================================================================
WITH cat_rank AS (
    SELECT
        category,
        SUM(ROUND(product_qty * sales_price, 6))                                AS cat_net_sales_amt,
        RANK() OVER (ORDER BY SUM(ROUND(product_qty * sales_price, 6)) DESC)    AS cat_rank_no
    FROM indep_rl_dw.s02_trade_sku_data_d
    WHERE dt >= '2026-03-29'
      AND dt <= '2026-09-26'
      AND division = @division
      AND category IS NOT NULL
      AND TRIM(category) <> ''
    GROUP BY category
),
top_category AS (
    SELECT category, cat_rank_no, cat_net_sales_amt
    FROM cat_rank
    WHERE cat_rank_no = 2
),
row_amt AS (
    SELECT
        t.category,
        t.sku_size_category,
        t.sku_size,
        SUM(CASE WHEN t.dt >= '2026-03-29' AND t.dt <= '2026-09-26'
                 THEN ROUND(t.product_qty * t.sales_price, 6) END)              AS this_amt,
        SUM(CASE WHEN t.dt >= '2025-03-30' AND t.dt <= '2025-09-27'
                 THEN ROUND(t.product_qty * t.sales_price, 6) END)              AS last_amt
    FROM indep_rl_dw.s02_trade_sku_data_d t
    WHERE t.division = @division
      AND ( (t.dt >= '2026-03-29' AND t.dt <= '2026-09-26')
         OR (t.dt >= '2025-03-30' AND t.dt <= '2025-09-27') )
      AND t.category IN (SELECT category FROM top_category)
    GROUP BY t.category, t.sku_size_category, t.sku_size
),
pct AS (
    SELECT
        r.*,
        SUM(r.this_amt) OVER (PARTITION BY r.category, r.sku_size_category)    AS this_denom,
        SUM(r.last_amt) OVER (PARTITION BY r.category, r.sku_size_category)    AS last_denom
    FROM row_amt r
)
SELECT
    tc.cat_rank_no        AS Category_Rank,
    tc.cat_net_sales_amt  AS Category_Amt,
    p.category,
    p.sku_size_category,
    p.sku_size,
    p.this_amt                                                                  AS SLS_Amt_Value,
    p.this_amt  / NULLIF(p.this_denom, 0)                                       AS SLS_Amt_Pct,
    p.last_amt  / NULLIF(p.last_denom, 0)                                       AS LP_SLS_Amt_Pct,
    (p.this_amt / NULLIF(p.this_denom, 0)) - (p.last_amt / NULLIF(p.last_denom, 0))
                                                                                AS Vs_LP,
    ((p.this_amt / NULLIF(p.this_denom, 0)) - (p.last_amt / NULLIF(p.last_denom, 0))) * 10000
                                                                                AS Vs_LP_Bp
FROM pct p
JOIN top_category tc
  ON p.category = tc.category
WHERE p.this_amt IS NOT NULL
  AND p.this_denom IS NOT NULL
  AND p.this_denom <> 0
ORDER BY
    CASE WHEN p.sku_size_category LIKE '%字母尺码%' THEN 0
         WHEN p.sku_size_category LIKE '%数字尺码%' THEN 1
         ELSE 2 END,
    p.this_denom DESC,
    p.this_amt / NULLIF(p.this_denom, 0) ASC;

-- ======================================================================
-- SQL 3/8: Sales Top3（Category Rank = 3）
-- ======================================================================
WITH cat_rank AS (
    SELECT
        category,
        SUM(ROUND(product_qty * sales_price, 6))                                AS cat_net_sales_amt,
        RANK() OVER (ORDER BY SUM(ROUND(product_qty * sales_price, 6)) DESC)    AS cat_rank_no
    FROM indep_rl_dw.s02_trade_sku_data_d
    WHERE dt >= '2026-03-29'
      AND dt <= '2026-09-26'
      AND division = @division
      AND category IS NOT NULL
      AND TRIM(category) <> ''
    GROUP BY category
),
top_category AS (
    SELECT category, cat_rank_no, cat_net_sales_amt
    FROM cat_rank
    WHERE cat_rank_no = 3
),
row_amt AS (
    SELECT
        t.category,
        t.sku_size_category,
        t.sku_size,
        SUM(CASE WHEN t.dt >= '2026-03-29' AND t.dt <= '2026-09-26'
                 THEN ROUND(t.product_qty * t.sales_price, 6) END)              AS this_amt,
        SUM(CASE WHEN t.dt >= '2025-03-30' AND t.dt <= '2025-09-27'
                 THEN ROUND(t.product_qty * t.sales_price, 6) END)              AS last_amt
    FROM indep_rl_dw.s02_trade_sku_data_d t
    WHERE t.division = @division
      AND ( (t.dt >= '2026-03-29' AND t.dt <= '2026-09-26')
         OR (t.dt >= '2025-03-30' AND t.dt <= '2025-09-27') )
      AND t.category IN (SELECT category FROM top_category)
    GROUP BY t.category, t.sku_size_category, t.sku_size
),
pct AS (
    SELECT
        r.*,
        SUM(r.this_amt) OVER (PARTITION BY r.category, r.sku_size_category)    AS this_denom,
        SUM(r.last_amt) OVER (PARTITION BY r.category, r.sku_size_category)    AS last_denom
    FROM row_amt r
)
SELECT
    tc.cat_rank_no        AS Category_Rank,
    tc.cat_net_sales_amt  AS Category_Amt,
    p.category,
    p.sku_size_category,
    p.sku_size,
    p.this_amt                                                                  AS SLS_Amt_Value,
    p.this_amt  / NULLIF(p.this_denom, 0)                                       AS SLS_Amt_Pct,
    p.last_amt  / NULLIF(p.last_denom, 0)                                       AS LP_SLS_Amt_Pct,
    (p.this_amt / NULLIF(p.this_denom, 0)) - (p.last_amt / NULLIF(p.last_denom, 0))
                                                                                AS Vs_LP,
    ((p.this_amt / NULLIF(p.this_denom, 0)) - (p.last_amt / NULLIF(p.last_denom, 0))) * 10000
                                                                                AS Vs_LP_Bp
FROM pct p
JOIN top_category tc
  ON p.category = tc.category
WHERE p.this_amt IS NOT NULL
  AND p.this_denom IS NOT NULL
  AND p.this_denom <> 0
ORDER BY
    CASE WHEN p.sku_size_category LIKE '%字母尺码%' THEN 0
         WHEN p.sku_size_category LIKE '%数字尺码%' THEN 1
         ELSE 2 END,
    p.this_denom DESC,
    p.this_amt / NULLIF(p.this_denom, 0) ASC;

-- ======================================================================
-- SQL 4/8: Sales Top4（Category Rank = 4）
-- ======================================================================
WITH cat_rank AS (
    SELECT
        category,
        SUM(ROUND(product_qty * sales_price, 6))                                AS cat_net_sales_amt,
        RANK() OVER (ORDER BY SUM(ROUND(product_qty * sales_price, 6)) DESC)    AS cat_rank_no
    FROM indep_rl_dw.s02_trade_sku_data_d
    WHERE dt >= '2026-03-29'
      AND dt <= '2026-09-26'
      AND division = @division
      AND category IS NOT NULL
      AND TRIM(category) <> ''
    GROUP BY category
),
top_category AS (
    SELECT category, cat_rank_no, cat_net_sales_amt
    FROM cat_rank
    WHERE cat_rank_no = 4
),
row_amt AS (
    SELECT
        t.category,
        t.sku_size_category,
        t.sku_size,
        SUM(CASE WHEN t.dt >= '2026-03-29' AND t.dt <= '2026-09-26'
                 THEN ROUND(t.product_qty * t.sales_price, 6) END)              AS this_amt,
        SUM(CASE WHEN t.dt >= '2025-03-30' AND t.dt <= '2025-09-27'
                 THEN ROUND(t.product_qty * t.sales_price, 6) END)              AS last_amt
    FROM indep_rl_dw.s02_trade_sku_data_d t
    WHERE t.division = @division
      AND ( (t.dt >= '2026-03-29' AND t.dt <= '2026-09-26')
         OR (t.dt >= '2025-03-30' AND t.dt <= '2025-09-27') )
      AND t.category IN (SELECT category FROM top_category)
    GROUP BY t.category, t.sku_size_category, t.sku_size
),
pct AS (
    SELECT
        r.*,
        SUM(r.this_amt) OVER (PARTITION BY r.category, r.sku_size_category)    AS this_denom,
        SUM(r.last_amt) OVER (PARTITION BY r.category, r.sku_size_category)    AS last_denom
    FROM row_amt r
)
SELECT
    tc.cat_rank_no        AS Category_Rank,
    tc.cat_net_sales_amt  AS Category_Amt,
    p.category,
    p.sku_size_category,
    p.sku_size,
    p.this_amt                                                                  AS SLS_Amt_Value,
    p.this_amt  / NULLIF(p.this_denom, 0)                                       AS SLS_Amt_Pct,
    p.last_amt  / NULLIF(p.last_denom, 0)                                       AS LP_SLS_Amt_Pct,
    (p.this_amt / NULLIF(p.this_denom, 0)) - (p.last_amt / NULLIF(p.last_denom, 0))
                                                                                AS Vs_LP,
    ((p.this_amt / NULLIF(p.this_denom, 0)) - (p.last_amt / NULLIF(p.last_denom, 0))) * 10000
                                                                                AS Vs_LP_Bp
FROM pct p
JOIN top_category tc
  ON p.category = tc.category
WHERE p.this_amt IS NOT NULL
  AND p.this_denom IS NOT NULL
  AND p.this_denom <> 0
ORDER BY
    CASE WHEN p.sku_size_category LIKE '%字母尺码%' THEN 0
         WHEN p.sku_size_category LIKE '%数字尺码%' THEN 1
         ELSE 2 END,
    p.this_denom DESC,
    p.this_amt / NULLIF(p.this_denom, 0) ASC;

-- ======================================================================
-- SQL 5/8: Inventory Top1（Category Rank = 1）
-- 排名与指标均为期末时点：This = dt '2026-07-25'，Last = dt '2025-07-26'
-- inv 表无 platform / shop_name 字段，筛选仅 date + Division（口径限制见方案文档注意事项 1）
-- ======================================================================
WITH cat_rank AS (
    SELECT
        category,
        SUM(msrp_inv_amt)                                                       AS cat_eoh_amt,
        RANK() OVER (ORDER BY SUM(msrp_inv_amt) DESC)                            AS cat_rank_no
    FROM indep_rl_dw.s02_inventory_stock_sales_detail_d
    WHERE dt = '2026-07-25'
      AND division = @division
      AND category IS NOT NULL
      AND TRIM(category) <> ''
    GROUP BY category
),
top_category AS (
    SELECT category, cat_rank_no, cat_eoh_amt
    FROM cat_rank
    WHERE cat_rank_no = 1
),
row_amt AS (
    SELECT
        t.category,
        t.sku_size_category,
        t.sku_size,
        SUM(CASE WHEN t.dt = '2026-07-25' THEN t.msrp_inv_amt END)               AS this_amt,
        SUM(CASE WHEN t.dt = '2025-07-26' THEN t.msrp_inv_amt END)               AS last_amt
    FROM indep_rl_dw.s02_inventory_stock_sales_detail_d t
    WHERE t.division = @division
      AND t.dt IN ('2026-07-25', '2025-07-26')
      AND t.category IN (SELECT category FROM top_category)
    GROUP BY t.category, t.sku_size_category, t.sku_size
),
pct AS (
    SELECT
        r.*,
        SUM(r.this_amt) OVER (PARTITION BY r.category, r.sku_size_category)     AS this_denom,
        SUM(r.last_amt) OVER (PARTITION BY r.category, r.sku_size_category)     AS last_denom
    FROM row_amt r
)
SELECT
    tc.cat_rank_no        AS Category_Rank,
    tc.cat_eoh_amt        AS Category_Amt,
    p.category,
    p.sku_size_category,
    p.sku_size,
    p.this_amt                                                                  AS EOH_Amt_Value,
    p.this_amt  / NULLIF(p.this_denom, 0)                                       AS EOH_Amt_Pct,
    p.last_amt  / NULLIF(p.last_denom, 0)                                       AS LP_EOH_Amt_Pct,
    (p.this_amt / NULLIF(p.this_denom, 0)) - (p.last_amt / NULLIF(p.last_denom, 0))
                                                                                AS Vs_LP,
    ((p.this_amt / NULLIF(p.this_denom, 0)) - (p.last_amt / NULLIF(p.last_denom, 0))) * 10000
                                                                                AS Vs_LP_Bp
FROM pct p
JOIN top_category tc
  ON p.category = tc.category
WHERE p.this_amt IS NOT NULL       -- This 时点有快照记录且金额非全 NULL（对应 DAX SUM 空集 = BLANK）
  AND p.this_denom IS NOT NULL
  AND p.this_denom <> 0            -- 分组分母为空/零 → 占比 BLANK → 行过滤（对应「Value 不为空」）
ORDER BY
    CASE WHEN p.sku_size_category LIKE '%字母尺码%' THEN 0
         WHEN p.sku_size_category LIKE '%数字尺码%' THEN 1
         ELSE 2 END,                                                          -- L1 分组优先级
    p.this_denom DESC,                                                        -- L2 分组当期期末库存金额降序
    p.this_amt / NULLIF(p.this_denom, 0) ASC;                                 -- L3 组内占比升序

-- ======================================================================
-- SQL 6/8: Inventory Top2（Category Rank = 2）
-- ======================================================================
WITH cat_rank AS (
    SELECT
        category,
        SUM(msrp_inv_amt)                                                       AS cat_eoh_amt,
        RANK() OVER (ORDER BY SUM(msrp_inv_amt) DESC)                            AS cat_rank_no
    FROM indep_rl_dw.s02_inventory_stock_sales_detail_d
    WHERE dt = '2026-07-25'
      AND division = @division
      AND category IS NOT NULL
      AND TRIM(category) <> ''
    GROUP BY category
),
top_category AS (
    SELECT category, cat_rank_no, cat_eoh_amt
    FROM cat_rank
    WHERE cat_rank_no = 2
),
row_amt AS (
    SELECT
        t.category,
        t.sku_size_category,
        t.sku_size,
        SUM(CASE WHEN t.dt = '2026-07-25' THEN t.msrp_inv_amt END)               AS this_amt,
        SUM(CASE WHEN t.dt = '2025-07-26' THEN t.msrp_inv_amt END)               AS last_amt
    FROM indep_rl_dw.s02_inventory_stock_sales_detail_d t
    WHERE t.division = @division
      AND t.dt IN ('2026-07-25', '2025-07-26')
      AND t.category IN (SELECT category FROM top_category)
    GROUP BY t.category, t.sku_size_category, t.sku_size
),
pct AS (
    SELECT
        r.*,
        SUM(r.this_amt) OVER (PARTITION BY r.category, r.sku_size_category)     AS this_denom,
        SUM(r.last_amt) OVER (PARTITION BY r.category, r.sku_size_category)     AS last_denom
    FROM row_amt r
)
SELECT
    tc.cat_rank_no        AS Category_Rank,
    tc.cat_eoh_amt        AS Category_Amt,
    p.category,
    p.sku_size_category,
    p.sku_size,
    p.this_amt                                                                  AS EOH_Amt_Value,
    p.this_amt  / NULLIF(p.this_denom, 0)                                       AS EOH_Amt_Pct,
    p.last_amt  / NULLIF(p.last_denom, 0)                                       AS LP_EOH_Amt_Pct,
    (p.this_amt / NULLIF(p.this_denom, 0)) - (p.last_amt / NULLIF(p.last_denom, 0))
                                                                                AS Vs_LP,
    ((p.this_amt / NULLIF(p.this_denom, 0)) - (p.last_amt / NULLIF(p.last_denom, 0))) * 10000
                                                                                AS Vs_LP_Bp
FROM pct p
JOIN top_category tc
  ON p.category = tc.category
WHERE p.this_amt IS NOT NULL
  AND p.this_denom IS NOT NULL
  AND p.this_denom <> 0
ORDER BY
    CASE WHEN p.sku_size_category LIKE '%字母尺码%' THEN 0
         WHEN p.sku_size_category LIKE '%数字尺码%' THEN 1
         ELSE 2 END,
    p.this_denom DESC,
    p.this_amt / NULLIF(p.this_denom, 0) ASC;

-- ======================================================================
-- SQL 7/8: Inventory Top3（Category Rank = 3）
-- ======================================================================
WITH cat_rank AS (
    SELECT
        category,
        SUM(msrp_inv_amt)                                                       AS cat_eoh_amt,
        RANK() OVER (ORDER BY SUM(msrp_inv_amt) DESC)                            AS cat_rank_no
    FROM indep_rl_dw.s02_inventory_stock_sales_detail_d
    WHERE dt = '2026-07-25'
      AND division = @division
      AND category IS NOT NULL
      AND TRIM(category) <> ''
    GROUP BY category
),
top_category AS (
    SELECT category, cat_rank_no, cat_eoh_amt
    FROM cat_rank
    WHERE cat_rank_no = 3
),
row_amt AS (
    SELECT
        t.category,
        t.sku_size_category,
        t.sku_size,
        SUM(CASE WHEN t.dt = '2026-07-25' THEN t.msrp_inv_amt END)               AS this_amt,
        SUM(CASE WHEN t.dt = '2025-07-26' THEN t.msrp_inv_amt END)               AS last_amt
    FROM indep_rl_dw.s02_inventory_stock_sales_detail_d t
    WHERE t.division = @division
      AND t.dt IN ('2026-07-25', '2025-07-26')
      AND t.category IN (SELECT category FROM top_category)
    GROUP BY t.category, t.sku_size_category, t.sku_size
),
pct AS (
    SELECT
        r.*,
        SUM(r.this_amt) OVER (PARTITION BY r.category, r.sku_size_category)     AS this_denom,
        SUM(r.last_amt) OVER (PARTITION BY r.category, r.sku_size_category)     AS last_denom
    FROM row_amt r
)
SELECT
    tc.cat_rank_no        AS Category_Rank,
    tc.cat_eoh_amt        AS Category_Amt,
    p.category,
    p.sku_size_category,
    p.sku_size,
    p.this_amt                                                                  AS EOH_Amt_Value,
    p.this_amt  / NULLIF(p.this_denom, 0)                                       AS EOH_Amt_Pct,
    p.last_amt  / NULLIF(p.last_denom, 0)                                       AS LP_EOH_Amt_Pct,
    (p.this_amt / NULLIF(p.this_denom, 0)) - (p.last_amt / NULLIF(p.last_denom, 0))
                                                                                AS Vs_LP,
    ((p.this_amt / NULLIF(p.this_denom, 0)) - (p.last_amt / NULLIF(p.last_denom, 0))) * 10000
                                                                                AS Vs_LP_Bp
FROM pct p
JOIN top_category tc
  ON p.category = tc.category
WHERE p.this_amt IS NOT NULL
  AND p.this_denom IS NOT NULL
  AND p.this_denom <> 0
ORDER BY
    CASE WHEN p.sku_size_category LIKE '%字母尺码%' THEN 0
         WHEN p.sku_size_category LIKE '%数字尺码%' THEN 1
         ELSE 2 END,
    p.this_denom DESC,
    p.this_amt / NULLIF(p.this_denom, 0) ASC;

-- ======================================================================
-- SQL 8/8: Inventory Top4（Category Rank = 4）
-- ======================================================================
WITH cat_rank AS (
    SELECT
        category,
        SUM(msrp_inv_amt)                                                       AS cat_eoh_amt,
        RANK() OVER (ORDER BY SUM(msrp_inv_amt) DESC)                            AS cat_rank_no
    FROM indep_rl_dw.s02_inventory_stock_sales_detail_d
    WHERE dt = '2026-07-25'
      AND division = @division
      AND category IS NOT NULL
      AND TRIM(category) <> ''
    GROUP BY category
),
top_category AS (
    SELECT category, cat_rank_no, cat_eoh_amt
    FROM cat_rank
    WHERE cat_rank_no = 4
),
row_amt AS (
    SELECT
        t.category,
        t.sku_size_category,
        t.sku_size,
        SUM(CASE WHEN t.dt = '2026-07-25' THEN t.msrp_inv_amt END)               AS this_amt,
        SUM(CASE WHEN t.dt = '2025-07-26' THEN t.msrp_inv_amt END)               AS last_amt
    FROM indep_rl_dw.s02_inventory_stock_sales_detail_d t
    WHERE t.division = @division
      AND t.dt IN ('2026-07-25', '2025-07-26')
      AND t.category IN (SELECT category FROM top_category)
    GROUP BY t.category, t.sku_size_category, t.sku_size
),
pct AS (
    SELECT
        r.*,
        SUM(r.this_amt) OVER (PARTITION BY r.category, r.sku_size_category)     AS this_denom,
        SUM(r.last_amt) OVER (PARTITION BY r.category, r.sku_size_category)     AS last_denom
    FROM row_amt r
)
SELECT
    tc.cat_rank_no        AS Category_Rank,
    tc.cat_eoh_amt        AS Category_Amt,
    p.category,
    p.sku_size_category,
    p.sku_size,
    p.this_amt                                                                  AS EOH_Amt_Value,
    p.this_amt  / NULLIF(p.this_denom, 0)                                       AS EOH_Amt_Pct,
    p.last_amt  / NULLIF(p.last_denom, 0)                                       AS LP_EOH_Amt_Pct,
    (p.this_amt / NULLIF(p.this_denom, 0)) - (p.last_amt / NULLIF(p.last_denom, 0))
                                                                                AS Vs_LP,
    ((p.this_amt / NULLIF(p.this_denom, 0)) - (p.last_amt / NULLIF(p.last_denom, 0))) * 10000
                                                                                AS Vs_LP_Bp
FROM pct p
JOIN top_category tc
  ON p.category = tc.category
WHERE p.this_amt IS NOT NULL
  AND p.this_denom IS NOT NULL
  AND p.this_denom <> 0
ORDER BY
    CASE WHEN p.sku_size_category LIKE '%字母尺码%' THEN 0
         WHEN p.sku_size_category LIKE '%数字尺码%' THEN 1
         ELSE 2 END,
    p.this_denom DESC,
    p.this_amt / NULLIF(p.this_denom, 0) ASC;
