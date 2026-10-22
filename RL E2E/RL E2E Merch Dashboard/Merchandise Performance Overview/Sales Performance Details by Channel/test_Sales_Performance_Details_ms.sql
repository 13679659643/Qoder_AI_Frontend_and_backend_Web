-- ============================================================
-- 测试 SQL: Sales_Performance_Details_ms（Sales Performance Details by Channel 矩阵）
-- 对齐方案: Merchandise Performance Overview/Sales Performance Details by Channel/Sales_Performance_Details_ms.md
-- 语法: MySQL 8.0+（CTE / NULL 安全等于 <=>），字面量直嵌，不支持变量
--
-- SQL 参数（修改时对下述值全文替换）:
-- This Period:            data_date ∈ ['2026-03-29', '2026-07-25']（区间汇总）
-- Last Period:            data_date ∈ ['2025-03-30', '2025-07-26']（区间汇总，vs LP 基线）
-- 期末快照日 This:        '2026-07-25'（end period 范围内最后一天，单日时点，EOH Unit / LTD ST% 库存侧）
-- LTD 起算日:             '2026-03-29'（end period 所在财年第一天 = Fiscal_Year_First_Day，
--                         FY27 起点与 This Period 起点重合，本参数下 LTD 区间 = This Period）
-- 行维度:                 brand（本文件只按 brand 对数；其余五维同构替换分组列即可）
--
-- 文件结构（四段独立执行）:
--   段 1: Platform TTL   —— 8 指标（SLS Unit / SLS Amt / vs LP / SLS Amt% / LTD ST% / EOH Unit / AUR / MD），行 = brand
--   段 2: Platform 各个  —— 7 指标（SLS Unit / SLS Amt / vs LP / Vert. Amt% / Horiz. Amt% / AUR / MD），行 = platform × brand
--   段 3: Store TTL      —— 8 指标（同段 1），行 = brand
--   段 4: Store 各个     —— 7 指标（同段 2），行 = shop_name × brand
--
-- 渠道上下文对齐（对齐方案 §3.2）:
--   TTL（两组）   = ALLSELECTED(platform) + ALLSELECTED(shop_name) → 全渠道，SQL 不带渠道条件
--   Platform 非 TTL = platform = Label_Value（TM/JD/RLE/DY），shop_name 不限
--   Store 非 TTL    = shop_name = Label_Value（TM/JD/RLE_CN/DY_Family/DY_W/DY_M），platform 不限
--   platform 数据源层已过滤 IN ('JD','TM','RLE','DY')
--
-- 对数要点:
--   1. 行值域 = sales 表 brand DISTINCT（全期，不受时间/渠道限制——dt 与渠道均在度量值
--      CALCULATE 内显式施加，不参与行值域生成）；brand 含 NULL 归为一组对应页面 (Blank) 行
--   2. 段 1 与段 3 应完全同值（TTL 渠道上下文相同），可互验
--   3. 段 2 与段 4 的 Horiz. Amt% 同 brand 同值（分母均为该 brand 全渠道合计）
--   4. SLS Amt% / Vert. Amt% 分母对齐 ALLSELECTED 六商品字段（本文件行 = brand 即移除 brand
--      分组、保留渠道 + 时间）：段 1/3 为全渠道全 brand 合计（每列一行），段 2/4 为每渠道全
--      brand 合计；Horiz. Amt% 分母不 ALLSELECTED 商品字段（保留行 brand），改为每 brand
--      全渠道合计（不限 platform / shop_name）
--   5. LTD ST% 分子 = LTD 区间（财年第一天至 This end）销售金额，TTL 全渠道；库存侧 = inv 表
--      快照日单日 msrp_inv_amt（TREATAS(brand) 传递，无渠道字段不受渠道影响）
--   6. NULL 语义逐项对齐 DAX:
--      SLS Unit / SLS Amt / EOH Unit 无记录 → NULL（页面 BLANK，Display 显示 "-"）
--      vs LP: Last NULL 或 0 → NULL；this NULL 按 0 处理（DIVIDE(BLANK,x)=0 → 结果 -1）
--      占比类（SLS Amt% / Vert. / Horiz.）: 分母 NULL → NULL；分子 NULL → 0（DIVIDE(BLANK,x)=0）
--      LTD ST%: 双侧 NULL → NULL；单侧 NULL 按 0（对齐加法 BLANK 当 0）
--      AUR: SLS Unit NULL → NULL（DIVIDE(x,BLANK)=BLANK）；Unit 非 NULL 且 Amt NULL → 0
--      MD: msrp 合计 NULL 或 0 → NULL（方案空值保护，避免 1-0=100% 伪值）；
--          msrp 非 NULL 时 md NULL 按 0（1 - 0/msrp = 100% 折扣，对齐 DIVIDE(BLANK,x)=0）
--   7. 金额为底表 RMB 原值（Cell Value 层汇率换算与 Display 符号拼接不在 SQL 范围）；
--      vs LP 页面显示含正号（+26%），SQL 输出原始小数；MD / 占比 / LTD ST% 页面 #,##0% 不含正号
--   8. 对数假设无外部切片器筛选（Slicer_Platform_Selection / Slicer_Store_Name /
--      Slicer_AX_Class 等全选状态）；若页面存在外部筛选，两侧需同步收窄
--   9. 全部指标为 NULL 的行页面经矩阵设置隐藏或不显示，对数时以页面实际展示为准
-- ============================================================

-- ══════════════════════════════════════════════════════════════
-- 段 1: Platform TTL —— Platform 组 TTL 列（Label_Value = "TTL"）
-- 渠道上下文 = ALLSELECTED(platform) + ALLSELECTED(shop_name) = 全渠道（无渠道条件）
-- 行 = brand，8 指标
-- ══════════════════════════════════════════════════════════════
WITH
-- 行值域: brand 全值域（全期，不限渠道）
dim_values AS (
    SELECT DISTINCT brand
    FROM indep_rl_ads.a02_e2e_product_performance_sales_summary_d
),
-- This Period 销售聚合（TTL 全渠道）
trade_this AS (
    SELECT brand,
           SUM(net_sales_qty)     AS sls_unit,
           SUM(net_sales_amt)     AS sls_amt,
           SUM(md_net_sales_amt)  AS md_amt,
           SUM(msrp_net_sales_amt) AS msrp_amt
    FROM indep_rl_ads.a02_e2e_product_performance_sales_summary_d
    WHERE data_date BETWEEN '2026-03-29' AND '2026-07-25'
    GROUP BY brand
),
-- Last Period 销售聚合（vs LP 分母）
trade_last AS (
    SELECT brand,
           SUM(net_sales_amt) AS sls_amt
    FROM indep_rl_ads.a02_e2e_product_performance_sales_summary_d
    WHERE data_date BETWEEN '2025-03-30' AND '2025-07-26'
    GROUP BY brand
),
-- SLS Amt% 分母: ALLSELECTED 六商品字段 + TTL 渠道 = 全 brand 全渠道合计（单行）
trade_total AS (
    SELECT SUM(net_sales_amt) AS sls_amt_total
    FROM indep_rl_ads.a02_e2e_product_performance_sales_summary_d
    WHERE data_date BETWEEN '2026-03-29' AND '2026-07-25'
),
-- LTD 销售聚合（LTD 区间 = 财年第一天至 This end；TTL 全渠道）
ltd_sales AS (
    SELECT brand,
           SUM(net_sales_amt) AS ltd_amt
    FROM indep_rl_ads.a02_e2e_product_performance_sales_summary_d
    WHERE data_date BETWEEN '2026-03-29' AND '2026-07-25'
    GROUP BY brand
),
-- This 期末快照日库存聚合（单日时点；TREATAS(brand) 传递；inv 无渠道字段）
inv_this AS (
    SELECT brand,
           SUM(inv_qty)     AS eoh_unit,
           SUM(msrp_inv_amt) AS inv_amt
    FROM indep_rl_ads.a02_e2e_product_performance_inv_summary_d
    WHERE data_date = '2026-07-25'
    GROUP BY brand
)
SELECT
    dv.brand                          AS brand,         -- 行维度
    t.sls_unit                        AS sls_unit,      -- SLS Unit
    t.sls_amt                         AS sls_amt,       -- SLS Amt（RMB 原值）
    CASE WHEN l.sls_amt IS NULL OR l.sls_amt = 0 THEN NULL
         ELSE COALESCE(t.sls_amt, 0) / l.sls_amt - 1
    END                               AS vs_lp,         -- vs LP（变化率，页面 +26% 含正号）
    CASE WHEN tt.sls_amt_total IS NULL THEN NULL
         ELSE COALESCE(t.sls_amt, 0) / tt.sls_amt_total
    END                               AS sls_amt_pct,   -- SLS Amt%
    CASE WHEN ls.ltd_amt IS NULL AND i.inv_amt IS NULL THEN NULL
         ELSE COALESCE(ls.ltd_amt, 0)
              / (COALESCE(ls.ltd_amt, 0) + COALESCE(i.inv_amt, 0))
    END                               AS ltd_st_pct,    -- LTD ST%（金额口径）
    i.eoh_unit                        AS eoh_unit,      -- EOH Unit
    CASE WHEN t.sls_unit IS NULL THEN NULL
         ELSE COALESCE(t.sls_amt, 0) / t.sls_unit
    END                               AS aur,           -- AUR（件单价）
    CASE WHEN t.msrp_amt IS NULL OR t.msrp_amt = 0 THEN NULL
         ELSE 1 - COALESCE(t.md_amt, 0) / t.msrp_amt
    END                               AS md             -- MD（平均折扣，本次新增）
FROM dim_values dv
LEFT JOIN trade_this  t  ON dv.brand <=> t.brand
LEFT JOIN trade_last  l  ON dv.brand <=> l.brand
LEFT JOIN ltd_sales   ls ON dv.brand <=> ls.brand
LEFT JOIN inv_this    i  ON dv.brand <=> i.brand
CROSS JOIN trade_total tt
ORDER BY dv.brand;


-- ══════════════════════════════════════════════════════════════
-- 段 2: Platform 各个 —— Platform 组 Tmall / JD / RLE / DY 列
-- 渠道上下文 = platform = Label_Value（shop_name 不限）
-- 行 = platform × brand，7 指标
-- ══════════════════════════════════════════════════════════════
WITH
-- 行值域: brand 全值域
dim_values AS (
    SELECT DISTINCT brand
    FROM indep_rl_ads.a02_e2e_product_performance_sales_summary_d
),
-- 平台映射: 页面 Label → 事实表 platform
platforms AS (
    SELECT 'Tmall' AS platform_label, 'TM' AS platform_value
    UNION ALL SELECT 'JD', 'JD'
    UNION ALL SELECT 'RLE', 'RLE'
    UNION ALL SELECT 'DY', 'DY'
),
-- This Period 销售聚合（按平台 × brand）
trade_this AS (
    SELECT platform, brand,
           SUM(net_sales_qty)      AS sls_unit,
           SUM(net_sales_amt)      AS sls_amt,
           SUM(md_net_sales_amt)   AS md_amt,
           SUM(msrp_net_sales_amt) AS msrp_amt
    FROM indep_rl_ads.a02_e2e_product_performance_sales_summary_d
    WHERE data_date BETWEEN '2026-03-29' AND '2026-07-25'
      AND platform IN ('TM', 'JD', 'RLE', 'DY')
    GROUP BY platform, brand
),
-- Last Period 销售聚合（vs LP 分母）
trade_last AS (
    SELECT platform, brand,
           SUM(net_sales_amt) AS sls_amt
    FROM indep_rl_ads.a02_e2e_product_performance_sales_summary_d
    WHERE data_date BETWEEN '2025-03-30' AND '2025-07-26'
      AND platform IN ('TM', 'JD', 'RLE', 'DY')
    GROUP BY platform, brand
),
-- Vert. Amt% 分母: 该平台全部 brand 合计（ALLSELECTED 六商品字段 + platform = Label_Value）
vert_total AS (
    SELECT platform,
           SUM(net_sales_amt) AS sls_amt_total
    FROM indep_rl_ads.a02_e2e_product_performance_sales_summary_d
    WHERE data_date BETWEEN '2026-03-29' AND '2026-07-25'
      AND platform IN ('TM', 'JD', 'RLE', 'DY')
    GROUP BY platform
),
-- Horiz. Amt% 分母: 该 brand 全渠道合计（保留行 brand，ALLSELECTED platform / shop_name）
horiz_total AS (
    SELECT brand,
           SUM(net_sales_amt) AS sls_amt_total
    FROM indep_rl_ads.a02_e2e_product_performance_sales_summary_d
    WHERE data_date BETWEEN '2026-03-29' AND '2026-07-25'
    GROUP BY brand
)
SELECT
    p.platform_label                  AS platform_label, -- 页面平台 Label
    dv.brand                          AS brand,          -- 行维度
    t.sls_unit                        AS sls_unit,       -- SLS Unit
    t.sls_amt                         AS sls_amt,        -- SLS Amt（RMB 原值）
    CASE WHEN l.sls_amt IS NULL OR l.sls_amt = 0 THEN NULL
         ELSE COALESCE(t.sls_amt, 0) / l.sls_amt - 1
    END                               AS vs_lp,          -- vs LP（变化率）
    CASE WHEN vt.sls_amt_total IS NULL THEN NULL
         ELSE COALESCE(t.sls_amt, 0) / vt.sls_amt_total
    END                               AS vert_amt_pct,   -- Vert. Amt%（纵向占比）
    CASE WHEN ht.sls_amt_total IS NULL THEN NULL
         ELSE COALESCE(t.sls_amt, 0) / ht.sls_amt_total
    END                               AS horiz_amt_pct,  -- Horiz. Amt%（横向占比，与段 4 同 brand 同值）
    CASE WHEN t.sls_unit IS NULL THEN NULL
         ELSE COALESCE(t.sls_amt, 0) / t.sls_unit
    END                               AS aur,            -- AUR（件单价）
    CASE WHEN t.msrp_amt IS NULL OR t.msrp_amt = 0 THEN NULL
         ELSE 1 - COALESCE(t.md_amt, 0) / t.msrp_amt
    END                               AS md              -- MD（平均折扣）
FROM dim_values dv
CROSS JOIN platforms p
LEFT JOIN trade_this  t  ON p.platform_value <=> t.platform AND dv.brand <=> t.brand
LEFT JOIN trade_last  l  ON p.platform_value <=> l.platform AND dv.brand <=> l.brand
LEFT JOIN vert_total  vt ON p.platform_value <=> vt.platform
LEFT JOIN horiz_total ht ON dv.brand <=> ht.brand
ORDER BY FIELD(p.platform_label, 'Tmall', 'JD', 'RLE', 'DY'), dv.brand;


-- ══════════════════════════════════════════════════════════════
-- 段 3: Store TTL —— Store 组 TTL 列（Label_Value = "TTL"）
-- 渠道上下文 = ALLSELECTED(platform) + ALLSELECTED(shop_name) = 全渠道（与段 1 相同）
-- 行 = brand，8 指标；数值应与段 1 完全一致（互验）
-- ══════════════════════════════════════════════════════════════
WITH
dim_values AS (
    SELECT DISTINCT brand
    FROM indep_rl_ads.a02_e2e_product_performance_sales_summary_d
),
trade_this AS (
    SELECT brand,
           SUM(net_sales_qty)      AS sls_unit,
           SUM(net_sales_amt)      AS sls_amt,
           SUM(md_net_sales_amt)   AS md_amt,
           SUM(msrp_net_sales_amt) AS msrp_amt
    FROM indep_rl_ads.a02_e2e_product_performance_sales_summary_d
    WHERE data_date BETWEEN '2026-03-29' AND '2026-07-25'
    GROUP BY brand
),
trade_last AS (
    SELECT brand,
           SUM(net_sales_amt) AS sls_amt
    FROM indep_rl_ads.a02_e2e_product_performance_sales_summary_d
    WHERE data_date BETWEEN '2025-03-30' AND '2025-07-26'
    GROUP BY brand
),
trade_total AS (
    SELECT SUM(net_sales_amt) AS sls_amt_total
    FROM indep_rl_ads.a02_e2e_product_performance_sales_summary_d
    WHERE data_date BETWEEN '2026-03-29' AND '2026-07-25'
),
ltd_sales AS (
    SELECT brand,
           SUM(net_sales_amt) AS ltd_amt
    FROM indep_rl_ads.a02_e2e_product_performance_sales_summary_d
    WHERE data_date BETWEEN '2026-03-29' AND '2026-07-25'
    GROUP BY brand
),
inv_this AS (
    SELECT brand,
           SUM(inv_qty)      AS eoh_unit,
           SUM(msrp_inv_amt) AS inv_amt
    FROM indep_rl_ads.a02_e2e_product_performance_inv_summary_d
    WHERE data_date = '2026-07-25'
    GROUP BY brand
)
SELECT
    dv.brand                          AS brand,
    t.sls_unit                        AS sls_unit,
    t.sls_amt                         AS sls_amt,
    CASE WHEN l.sls_amt IS NULL OR l.sls_amt = 0 THEN NULL
         ELSE COALESCE(t.sls_amt, 0) / l.sls_amt - 1
    END                               AS vs_lp,
    CASE WHEN tt.sls_amt_total IS NULL THEN NULL
         ELSE COALESCE(t.sls_amt, 0) / tt.sls_amt_total
    END                               AS sls_amt_pct,
    CASE WHEN ls.ltd_amt IS NULL AND i.inv_amt IS NULL THEN NULL
         ELSE COALESCE(ls.ltd_amt, 0)
              / (COALESCE(ls.ltd_amt, 0) + COALESCE(i.inv_amt, 0))
    END                               AS ltd_st_pct,
    i.eoh_unit                        AS eoh_unit,
    CASE WHEN t.sls_unit IS NULL THEN NULL
         ELSE COALESCE(t.sls_amt, 0) / t.sls_unit
    END                               AS aur,
    CASE WHEN t.msrp_amt IS NULL OR t.msrp_amt = 0 THEN NULL
         ELSE 1 - COALESCE(t.md_amt, 0) / t.msrp_amt
    END                               AS md
FROM dim_values dv
LEFT JOIN trade_this  t  ON dv.brand <=> t.brand
LEFT JOIN trade_last  l  ON dv.brand <=> l.brand
LEFT JOIN ltd_sales   ls ON dv.brand <=> ls.brand
LEFT JOIN inv_this    i  ON dv.brand <=> i.brand
CROSS JOIN trade_total tt
ORDER BY dv.brand;


-- ══════════════════════════════════════════════════════════════
-- 段 4: Store 各个 —— Store 组 Tmall / JD / RLE / DY_Family / DY_W / DY_MN 列
-- 渠道上下文 = shop_name = Label_Value（platform 不限）
-- 行 = shop_name × brand，7 指标
-- ══════════════════════════════════════════════════════════════
WITH
dim_values AS (
    SELECT DISTINCT brand
    FROM indep_rl_ads.a02_e2e_product_performance_sales_summary_d
),
-- 店铺映射: 页面 Label → 事实表 shop_name（对齐 Slicer_Store_Name）
stores AS (
    SELECT 'Tmall' AS store_label, 'TM' AS shop_value
    UNION ALL SELECT 'JD', 'JD'
    UNION ALL SELECT 'RLE', 'RLE_CN'
    UNION ALL SELECT 'DY_Family', 'DY_Family'
    UNION ALL SELECT 'DY_W', 'DY_W'
    UNION ALL SELECT 'DY_MN', 'DY_M'
),
-- This Period 销售聚合（按店铺 × brand）
trade_this AS (
    SELECT shop_name, brand,
           SUM(net_sales_qty)      AS sls_unit,
           SUM(net_sales_amt)      AS sls_amt,
           SUM(md_net_sales_amt)   AS md_amt,
           SUM(msrp_net_sales_amt) AS msrp_amt
    FROM indep_rl_ads.a02_e2e_product_performance_sales_summary_d
    WHERE data_date BETWEEN '2026-03-29' AND '2026-07-25'
      AND shop_name IN ('TM', 'JD', 'RLE_CN', 'DY_Family', 'DY_W', 'DY_M')
    GROUP BY shop_name, brand
),
-- Last Period 销售聚合（vs LP 分母）
trade_last AS (
    SELECT shop_name, brand,
           SUM(net_sales_amt) AS sls_amt
    FROM indep_rl_ads.a02_e2e_product_performance_sales_summary_d
    WHERE data_date BETWEEN '2025-03-30' AND '2025-07-26'
      AND shop_name IN ('TM', 'JD', 'RLE_CN', 'DY_Family', 'DY_W', 'DY_M')
    GROUP BY shop_name, brand
),
-- Vert. Amt% 分母: 该店铺全部 brand 合计（ALLSELECTED 六商品字段 + shop_name = Label_Value）
vert_total AS (
    SELECT shop_name,
           SUM(net_sales_amt) AS sls_amt_total
    FROM indep_rl_ads.a02_e2e_product_performance_sales_summary_d
    WHERE data_date BETWEEN '2026-03-29' AND '2026-07-25'
      AND shop_name IN ('TM', 'JD', 'RLE_CN', 'DY_Family', 'DY_W', 'DY_M')
    GROUP BY shop_name
),
-- Horiz. Amt% 分母: 该 brand 全渠道合计（保留行 brand，ALLSELECTED platform / shop_name，
-- 与段 2 的 horiz 分母相同）
horiz_total AS (
    SELECT brand,
           SUM(net_sales_amt) AS sls_amt_total
    FROM indep_rl_ads.a02_e2e_product_performance_sales_summary_d
    WHERE data_date BETWEEN '2026-03-29' AND '2026-07-25'
    GROUP BY brand
)
SELECT
    s.store_label                     AS store_label,   -- 页面店铺 Label
    dv.brand                          AS brand,         -- 行维度
    t.sls_unit                        AS sls_unit,      -- SLS Unit
    t.sls_amt                         AS sls_amt,       -- SLS Amt（RMB 原值）
    CASE WHEN l.sls_amt IS NULL OR l.sls_amt = 0 THEN NULL
         ELSE COALESCE(t.sls_amt, 0) / l.sls_amt - 1
    END                               AS vs_lp,         -- vs LP（变化率）
    CASE WHEN vt.sls_amt_total IS NULL THEN NULL
         ELSE COALESCE(t.sls_amt, 0) / vt.sls_amt_total
    END                               AS vert_amt_pct,  -- Vert. Amt%（纵向占比）
    CASE WHEN ht.sls_amt_total IS NULL THEN NULL
         ELSE COALESCE(t.sls_amt, 0) / ht.sls_amt_total
    END                               AS horiz_amt_pct, -- Horiz. Amt%（横向占比，与段 2 同 brand 同值）
    CASE WHEN t.sls_unit IS NULL THEN NULL
         ELSE COALESCE(t.sls_amt, 0) / t.sls_unit
    END                               AS aur,           -- AUR（件单价）
    CASE WHEN t.msrp_amt IS NULL OR t.msrp_amt = 0 THEN NULL
         ELSE 1 - COALESCE(t.md_amt, 0) / t.msrp_amt
    END                               AS md             -- MD（平均折扣）
FROM dim_values dv
CROSS JOIN stores s
LEFT JOIN trade_this  t  ON s.shop_value <=> t.shop_name AND dv.brand <=> t.brand
LEFT JOIN trade_last  l  ON s.shop_value <=> l.shop_name AND dv.brand <=> l.brand
LEFT JOIN vert_total  vt ON s.shop_value <=> vt.shop_name
LEFT JOIN horiz_total ht ON dv.brand <=> ht.brand
ORDER BY FIELD(s.store_label, 'Tmall', 'JD', 'RLE', 'DY_Family', 'DY_W', 'DY_MN'), dv.brand;
