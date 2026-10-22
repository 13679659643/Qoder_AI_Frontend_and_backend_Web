-- ============================================================
-- 测试 SQL: Handbags_&_Outwear_ms（Handbags Sales Performance 矩阵）
-- 对齐方案: Dimension Cross Analysis/7 Handbags Sales Performance/Handbags_&_Outwear_ms.md
-- 语法: MySQL 8.0+（CTE / NULL 安全等于 <=>），字面量直嵌，不支持变量
--
-- SQL 参数（修改时对下述值全文替换）:
-- Store Name:        TTL + 六个 Store（页面 Label → 事实表 shop_name:
--                    Tmall=TM / JD=JD / RLE=RLE_CN / DY_Family=DY_Family / DY_W=DY_W / DY_MN=DY_M）
-- This Period:       dt ∈ ['2026-03-29', '2026-07-25']（区间汇总）
-- Last Period:       dt ∈ ['2025-03-30', '2025-07-26']（区间汇总）
-- 库存相关 end period 最后一天 This: '2026-07-25'（快照日单日时点）
-- 库存相关 end period 最后一天 Last: '2025-07-26'（快照日单日时点）
--
-- 文件结构（两段独立执行）:
--   段 1: TTL 列 7 指标（SLS Unit / SLS Amt / SLS Amt% / Amt vs LP / ST% / EOH / EOH vs LP）
--         行 = spu_model（Slicer_Spu_Model 值域三值）
--   段 2: 六 Store 列 4 指标（SLS Unit / SLS Amt / SLS Amt% / vs LP bp 差值）
--         行 = Store × spu_model（18 行，Store_Label 列区分）
--
-- 对数要点:
--   1. 行值域 = Slicer_Spu_Model 全集（trade DISTINCT 三值，不限品类/时间/渠道）；
--      全部指标均为 NULL 的行在页面经矩阵 BLANK 自动隐藏机制不显示，对数时忽略
--   2. net_sales_amt 数据库无此列，按行级 ROUND(product_qty * sales_price, 6) 还原
--   3. 占比分母对齐 ALLSELECTED('Slicer_Spu_Model') 整表 = 移除行分组、保留
--      品类 + 渠道 + 时间（每渠道列一列全量合计）
--   4. TTL = ALLSELECTED([shop_name])（外部筛选下的全值域），SQL 按六值 IN 对数；
--      若底表存在六值外 shop_name（含空串/NULL），页面会包含该部分，差异需核对
--   5. 品类筛选对齐视觉对象筛选器（Slicer_Category = Handbags/Outerwear 经双侧
--      关系传导）：trade / inv 两侧 WHERE 均带 category IN ('Handbags', 'Outerwear')
--   6. EOH / ST% 库存侧不受渠道影响（inv 无渠道字段）；ST% 分子含六值渠道、
--      库存侧不限渠道，分子分母渠道口径不对称为模型物理限制
--   7. NULL 语义逐项对齐 DAX:
--      SLS Unit / SLS Amt / EOH 无记录 → NULL（页面 BLANK）
--      SLS Amt% 分子 NULL → 0（分母非 NULL，对齐 DIVIDE(BLANK,x)=0）；分母 NULL → NULL
--      Amt vs LP: LP NULL 或 0 → NULL；this NULL 按 0 处理（对齐 DIVIDE(BLANK,x)=0 → -1）
--      ST%: 双侧 NULL → NULL；单侧 NULL 按 0（对齐加法 BLANK 当 0）
--      EOH vs LP: 任一侧 NULL 或 LP 侧 0 → NULL
--      vs LP(bp): 任一侧占比 NULL → NULL；输出原始差值小数（页面 ×10000 转 bp:
--      -0.0152 → -152bp）
--   8. 对数假设无外部渠道切片器筛选（TTL / 店铺列均按全量口径）；若页面存在
--      外部 Slicer_Store_Name 筛选，两侧需同步收窄
-- ============================================================

-- ══════════════════════════════════════════════════════════════
-- 段 1: TTL 列（7 指标）—— 矩阵 Store 组 TTL（Label_Value = "TTL"）
-- 渠道上下文 = 六店铺实际值 IN；行 = spu_model
-- ══════════════════════════════════════════════════════════════
WITH
-- 行值域: Slicer_Spu_Model 全集（对齐维度表取数 SQL，不限品类/时间/渠道）
dim_values AS (
    SELECT DISTINCT spu_model
    FROM indep_rl_dw.s02_trade_sku_data_d
    WHERE spu_model IS NOT NULL
      AND TRIM(spu_model) <> ''
      AND spu_model IN ('Polo Play', 'Polo ID', 'Polo Blaze')
),
-- This Period 销售聚合（TTL = 六店铺实际值 IN；品类经视觉对象筛选器传导）
trade_this AS (
    SELECT spu_model,
           SUM(product_qty)                         AS sls_unit,
           SUM(ROUND(product_qty * sales_price, 6)) AS sls_amt
    FROM indep_rl_dw.s02_trade_sku_data_d
    WHERE dt >= '2026-03-29' AND dt <= '2026-07-25'
      AND category IN ('Handbags', 'Outerwear')
      AND shop_name IN ('TM', 'JD', 'RLE_CN', 'DY_Family', 'DY_W', 'DY_M')
    GROUP BY spu_model
),
-- Last Period 销售聚合（Amt vs LP 分母）
trade_last AS (
    SELECT spu_model,
           SUM(ROUND(product_qty * sales_price, 6)) AS sls_amt
    FROM indep_rl_dw.s02_trade_sku_data_d
    WHERE dt >= '2025-03-30' AND dt <= '2025-07-26'
      AND category IN ('Handbags', 'Outerwear')
      AND shop_name IN ('TM', 'JD', 'RLE_CN', 'DY_Family', 'DY_W', 'DY_M')
    GROUP BY spu_model
),
-- SLS Amt% 分母: ALLSELECTED 整表 = 移除行分组（不 GROUP BY spu_model），
-- 保留品类 + 渠道 + 时间（聚合查询恒返回一行，无匹配时为 NULL）
trade_total AS (
    SELECT SUM(ROUND(product_qty * sales_price, 6)) AS sls_amt_total
    FROM indep_rl_dw.s02_trade_sku_data_d
    WHERE dt >= '2026-03-29' AND dt <= '2026-07-25'
      AND category IN ('Handbags', 'Outerwear')
      AND shop_name IN ('TM', 'JD', 'RLE_CN', 'DY_Family', 'DY_W', 'DY_M')
),
-- This 期末快照日库存聚合（单日时点；行维度 / 品类均经关系传导；不限渠道）
inv_this AS (
    SELECT spu_model,
           SUM(stock_inv_qty) AS eoh_unit,
           SUM(msrp_inv_amt)  AS inv_amt
    FROM indep_rl_dw.s02_inventory_stock_sales_detail_d
    WHERE dt = '2026-07-25'
      AND category IN ('Handbags', 'Outerwear')
    GROUP BY spu_model
),
-- LP 期末快照日库存聚合（EOH vs LP 分母）
inv_last AS (
    SELECT spu_model,
           SUM(stock_inv_qty) AS eoh_unit
    FROM indep_rl_dw.s02_inventory_stock_sales_detail_d
    WHERE dt = '2025-07-26'
      AND category IN ('Handbags', 'Outerwear')
    GROUP BY spu_model
)
SELECT
    dv.spu_model                       AS spu_model,     -- 行维度
    t.sls_unit                         AS sls_unit,      -- SLS Unit
    t.sls_amt                          AS sls_amt,       -- SLS Amt
    CASE WHEN tt.sls_amt_total IS NULL THEN NULL
         ELSE COALESCE(t.sls_amt, 0) / tt.sls_amt_total
    END                                AS sls_amt_pct,   -- SLS Amt%
    CASE WHEN l.sls_amt IS NULL OR l.sls_amt = 0 THEN NULL
         ELSE COALESCE(t.sls_amt, 0) / l.sls_amt - 1
    END                                AS amt_vs_lp,     -- Amt vs LP（变化率）
    CASE WHEN t.sls_amt IS NULL AND i.inv_amt IS NULL THEN NULL
         ELSE COALESCE(t.sls_amt, 0)
              / (COALESCE(t.sls_amt, 0) + COALESCE(i.inv_amt, 0))
    END                                AS st_pct,        -- ST%（金额口径）
    i.eoh_unit                         AS eoh,           -- EOH
    CASE WHEN i.eoh_unit IS NULL OR il.eoh_unit IS NULL OR il.eoh_unit = 0 THEN NULL
         ELSE i.eoh_unit / il.eoh_unit - 1
    END                                AS eoh_vs_lp      -- EOH vs LP（变化率）
FROM dim_values dv
LEFT JOIN trade_this  t  ON dv.spu_model <=> t.spu_model
LEFT JOIN trade_last  l  ON dv.spu_model <=> l.spu_model
LEFT JOIN inv_this    i  ON dv.spu_model <=> i.spu_model
LEFT JOIN inv_last    il ON dv.spu_model <=> il.spu_model
CROSS JOIN trade_total tt
ORDER BY FIELD(dv.spu_model, 'Polo Play', 'Polo ID', 'Polo Blaze');


-- ══════════════════════════════════════════════════════════════
-- 段 2: 六 Store 列（4 指标）—— Store 组 Tmall / JD / RLE / DY_Family / DY_W / DY_MN
-- 渠道上下文 = shop_name = Label_Value（单店铺精确匹配）；行 = Store × spu_model
-- ══════════════════════════════════════════════════════════════
WITH
-- 行值域: Slicer_Spu_Model 全集（同段 1）
dim_values AS (
    SELECT DISTINCT spu_model
    FROM indep_rl_dw.s02_trade_sku_data_d
    WHERE spu_model IS NOT NULL
      AND TRIM(spu_model) <> ''
      AND spu_model IN ('Polo Play', 'Polo ID', 'Polo Blaze')
),
-- 店铺映射: 页面 Label → 事实表 shop_name（对齐 Slicer_Store_Name）
stores AS (
    SELECT 'Tmall' AS store_label, 'TM' AS shop_name
    UNION ALL SELECT 'JD', 'JD'
    UNION ALL SELECT 'RLE', 'RLE_CN'
    UNION ALL SELECT 'DY_Family', 'DY_Family'
    UNION ALL SELECT 'DY_W', 'DY_W'
    UNION ALL SELECT 'DY_MN', 'DY_M'
),
-- This Period 销售聚合（按店铺分组）
trade_this AS (
    SELECT shop_name, spu_model,
           SUM(product_qty)                         AS sls_unit,
           SUM(ROUND(product_qty * sales_price, 6)) AS sls_amt
    FROM indep_rl_dw.s02_trade_sku_data_d
    WHERE dt >= '2026-03-29' AND dt <= '2026-07-25'
      AND category IN ('Handbags', 'Outerwear')
      AND shop_name IN ('TM', 'JD', 'RLE_CN', 'DY_Family', 'DY_W', 'DY_M')
    GROUP BY shop_name, spu_model
),
-- Last Period 销售聚合（按店铺分组）
trade_last AS (
    SELECT shop_name, spu_model,
           SUM(ROUND(product_qty * sales_price, 6)) AS sls_amt
    FROM indep_rl_dw.s02_trade_sku_data_d
    WHERE dt >= '2025-03-30' AND dt <= '2025-07-26'
      AND category IN ('Handbags', 'Outerwear')
      AND shop_name IN ('TM', 'JD', 'RLE_CN', 'DY_Family', 'DY_W', 'DY_M')
    GROUP BY shop_name, spu_model
),
-- SLS Amt% 分母（This，按店铺分组）: ALLSELECTED 整表 = 移除行分组、保留店铺渠道
trade_total_this AS (
    SELECT shop_name, SUM(ROUND(product_qty * sales_price, 6)) AS sls_amt_total
    FROM indep_rl_dw.s02_trade_sku_data_d
    WHERE dt >= '2026-03-29' AND dt <= '2026-07-25'
      AND category IN ('Handbags', 'Outerwear')
      AND shop_name IN ('TM', 'JD', 'RLE_CN', 'DY_Family', 'DY_W', 'DY_M')
    GROUP BY shop_name
),
-- SLS Amt% 分母（Last，按店铺分组）
trade_total_last AS (
    SELECT shop_name, SUM(ROUND(product_qty * sales_price, 6)) AS sls_amt_total
    FROM indep_rl_dw.s02_trade_sku_data_d
    WHERE dt >= '2025-03-30' AND dt <= '2025-07-26'
      AND category IN ('Handbags', 'Outerwear')
      AND shop_name IN ('TM', 'JD', 'RLE_CN', 'DY_Family', 'DY_W', 'DY_M')
    GROUP BY shop_name
),
-- 占比中间层: This / LP 双期占比（分子 NULL 按 0，分母 NULL 则占比 NULL）
pct_base AS (
    SELECT
        s.store_label,
        dv.spu_model,
        t.sls_unit,
        t.sls_amt,
        CASE WHEN tt.sls_amt_total IS NULL THEN NULL
             ELSE COALESCE(t.sls_amt, 0) / tt.sls_amt_total
        END AS pct_this,
        CASE WHEN tl.sls_amt_total IS NULL THEN NULL
             ELSE COALESCE(l.sls_amt, 0) / tl.sls_amt_total
        END AS pct_lp
    FROM dim_values dv
    CROSS JOIN stores s
    LEFT JOIN trade_this       t  ON s.shop_name <=> t.shop_name  AND dv.spu_model <=> t.spu_model
    LEFT JOIN trade_last       l  ON s.shop_name <=> l.shop_name  AND dv.spu_model <=> l.spu_model
    LEFT JOIN trade_total_this tt ON s.shop_name <=> tt.shop_name
    LEFT JOIN trade_total_last tl ON s.shop_name <=> tl.shop_name
)
SELECT
    store_label                        AS store_label,   -- 页面店铺 Label
    spu_model                          AS spu_model,     -- 行维度
    sls_unit                           AS sls_unit,      -- SLS Unit
    sls_amt                            AS sls_amt,       -- SLS Amt
    pct_this                           AS sls_amt_pct,   -- SLS Amt%
    CASE WHEN pct_this IS NULL OR pct_lp IS NULL THEN NULL
         ELSE pct_this - pct_lp
    END                                AS vs_lp           -- vs LP（bp 差值原始小数，页面 ×10000 转 bp）
FROM pct_base
ORDER BY FIELD(store_label, 'Tmall', 'JD', 'RLE', 'DY_Family', 'DY_W', 'DY_MN'),
         FIELD(spu_model, 'Polo Play', 'Polo ID', 'Polo Blaze');
