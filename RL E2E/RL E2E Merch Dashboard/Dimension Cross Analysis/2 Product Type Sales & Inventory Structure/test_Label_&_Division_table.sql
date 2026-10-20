-- ======================================================================
-- 测试 SQL: Label & Division Table（两段：Division 分组 / Label 分组）
-- 所属模块: RL E2E Merch Dashboard - Dimension Cross Analysis - Product Type
--           Sales & Inventory Structure【Category × Division/Label】
-- 关联方案: Label_&_Division_table.md
-- 语法: MySQL 8.0+（CTE / 窗口函数）
-- 结构: SQL 1/2 Division 分组 + SQL 2/2 Label 分组，两段独立执行
--
-- ★参数区★（当前为字面量直嵌，修改参数时对两段全文替换对应日期 / 维度值）
-- Platform:              'ALL'（全选，等价不筛选，SQL 中不附加条件）
-- Store Name:            'ALL'（全选，等价不筛选，SQL 中不附加条件）
-- This Period:     dt ∈ ['2026-03-29', '2026-07-25']（区间汇总）
-- Last Period:     dt ∈ ['2025-03-30', '2025-09-27']（区间汇总）
-- This Year:       dt ∈ ['2026-03-29', '2026-07-25']（区间汇总，与 This Period
--                  同读 Min_This / Max_This 切片器，本参数下二者相同——
--                  vs LY 的 this 侧即 SLS_Amt_Pct 的 this 侧，SQL 不重复聚合）
-- Last Year:       dt ∈ ['2025-03-30', '2025-07-26']（区间汇总，_LY 字段财年
--                  同期映射，与 Last Period 切片器无关）
-- Inventory This 快照日: dt = '2026-07-25'（This Period 区间最后一天，单日快照）
-- Inventory LP 快照日:   dt = '2025-09-27'（Last Period 区间最后一天，单日快照）
-- Inventory LY 快照日:   dt = '2025-07-26'（Last Year 区间最后一天，单日快照）
-- 其余商品维度切片器:    全选（等价不筛选，不附加条件；如需单项筛选，在
--                        trade / inv 两侧 WHERE 按已建关系字段同步附加）
-- sales 表加载过滤:      platform IN ('JD', 'TM', 'RLE', 'DY')（对齐 Power Query
--                        数据源过滤，与切片器无关；inv 表无 platform 字段不涉及）
--
-- 口径还原说明:
--   1. 两张 a02 表日期字段为 data_date（非 dt），ISO 字符串比较与日期比较等价
--   2. 占比分母 = 组内全量合计（窗口 SUM() OVER (PARTITION BY 分组键)，对应
--      DAX ALLSELECTED(Slicer_Category[category])——移除 Category 行筛选、
--      保留 Division / Label 视觉对象筛选器（分组条件）与外部切片器筛选；
--      组内各 Category 的 SLS Amt% / EOH Amt% 之和 = 100%
--   3. 对数方式：PBI 页面每个表格的视觉对象筛选器固定一个分组值
--      （Division 表单选 CW/HM/MN/WM 之一；Label 表单选一个 Label 值）——
--      SQL 结果按分组列筛选该值后，与对应 PBI 表的 Category 行逐行对比
--   4. Label 在事实表中对应 brand 字段（Slicer_Label 值域 = sales 表 brand
--      distinct，别名 label）
--   5. 行组合 = trade ∪ inv（UNION ALL 再聚合还原 FULL OUTER 语义）：
--      PBI 表格行由度量值非空驱动，六个指标全为 BLANK 的 Category 行自动
--      隐藏——对数时忽略 SQL 中六个指标全为 NULL 的行；某 Category 仅单一
--      期有数据时，无数据期的占比 / 差值列为 NULL（对齐 DAX BLANK "-"）
--   6. 期末时点只取快照日单日（不可区间求和）；快照当日缺数时 PBI 度量值
--      回退到对应范围内最近一个快照日，SQL 对比时如发现快照日无数据需
--      相应调整日期
--   7. 空值行为对齐 DAX：分子 NULL 时占比输出 NULL（对应 DAX DIVIDE 分子
--      BLANK → BLANK，显示 "-"）；差值任一侧 NULL 时输出 NULL（对应 DAX
--      ISBLANK 拦截）；窗口 SUM 忽略 NULL 行（对应 DAX SUM 聚合忽略 BLANK，
--      组内分母 = 非空值之和）
--   8. vs LP / vs LY 输出原始差值（×10000 转 bp 在 PBI Display 层实现，
--      如 -0.0152 → PBI 显示 -152bp）
--   9. inv 表无渠道字段：EOH 系列分子分母均不受 Platform / Store 筛选影响；
--      SLS 系列受渠道筛选影响（本参数全选 = 不筛选）
-- ======================================================================


-- ======================================================================
-- SQL 1/2: Division 分组（每个 Division 对应的所有 Category 指标情况，
--          对数时按视觉对象筛选器固定的 division 值筛选本段结果）
-- ======================================================================
WITH
-- ── trade 侧 (division, category) 粒度各期聚合（覆盖 This ∪ LP ∪ LY 三区间）──
-- 条件聚合还原各时间口径；NULL 传播对应 DAX SUM 空值
trade_agg AS (
    SELECT
        division,
        category,
        SUM(CASE WHEN data_date BETWEEN '2026-03-29' AND '2026-07-25'
                 THEN net_sales_amt END)                        AS sls_amt_this,
        SUM(CASE WHEN data_date BETWEEN '2025-03-30' AND '2025-09-27'
                 THEN net_sales_amt END)                        AS sls_amt_lp,
        SUM(CASE WHEN data_date BETWEEN '2025-03-30' AND '2025-07-26'
                 THEN net_sales_amt END)                        AS sls_amt_ly
    FROM indep_rl_ads.a02_e2e_product_performance_sales_summary_d
    WHERE platform IN ('JD', 'TM', 'RLE', 'DY')                 -- 对齐 PBI 数据源加载过滤（与切片器无关）
      AND (
            data_date BETWEEN '2026-03-29' AND '2026-07-25'     -- This Period（= This Year）
         OR data_date BETWEEN '2025-03-30' AND '2025-09-27'     -- Last Period（vs LP 基线）
         OR data_date BETWEEN '2025-03-30' AND '2025-07-26'     -- Last Year（vs LY 基线）
      )
    GROUP BY division, category
),

-- ── inv 侧 (division, category) 粒度三快照日聚合 ──
inv_agg AS (
    SELECT
        division,
        category,
        SUM(CASE WHEN data_date = '2026-07-25' THEN msrp_inv_amt END)   AS eoh_amt_this,
        SUM(CASE WHEN data_date = '2025-09-27' THEN msrp_inv_amt END)   AS eoh_amt_lp,
        SUM(CASE WHEN data_date = '2025-07-26' THEN msrp_inv_amt END)   AS eoh_amt_ly
    FROM indep_rl_ads.a02_e2e_product_performance_inv_summary_d
    WHERE data_date IN ('2026-07-25', '2025-09-27', '2025-07-26')   -- 仅三个快照日（单日，不可区间求和）
    GROUP BY division, category
),

-- ── 行组合 = trade ∪ inv（UNION ALL 再聚合还原 FULL OUTER；单侧 NULL 保留）──
group_agg AS (
    SELECT
        division,
        category,
        SUM(sls_amt_this)  AS sls_amt_this,
        SUM(sls_amt_lp)    AS sls_amt_lp,
        SUM(sls_amt_ly)    AS sls_amt_ly,
        SUM(eoh_amt_this)  AS eoh_amt_this,
        SUM(eoh_amt_lp)    AS eoh_amt_lp,
        SUM(eoh_amt_ly)    AS eoh_amt_ly
    FROM (
        SELECT division, category, sls_amt_this, sls_amt_lp, sls_amt_ly,
               NULL AS eoh_amt_this, NULL AS eoh_amt_lp, NULL AS eoh_amt_ly
        FROM trade_agg
        UNION ALL
        SELECT division, category, NULL, NULL, NULL,
               eoh_amt_this, eoh_amt_lp, eoh_amt_ly
        FROM inv_agg
    ) u
    GROUP BY division, category
),

-- ── 组内占比（窗口分母 PARTITION BY division，对应 ALLSELECTED(Category)）──
pct AS (
    SELECT
        division,
        category,
        sls_amt_this / NULLIF(SUM(sls_amt_this) OVER (PARTITION BY division), 0)  AS sls_pct_this,
        sls_amt_lp   / NULLIF(SUM(sls_amt_lp)   OVER (PARTITION BY division), 0)  AS sls_pct_lp,
        sls_amt_ly   / NULLIF(SUM(sls_amt_ly)   OVER (PARTITION BY division), 0)  AS sls_pct_ly,
        eoh_amt_this / NULLIF(SUM(eoh_amt_this) OVER (PARTITION BY division), 0)  AS eoh_pct_this,
        eoh_amt_lp   / NULLIF(SUM(eoh_amt_lp)   OVER (PARTITION BY division), 0)  AS eoh_pct_lp,
        eoh_amt_ly   / NULLIF(SUM(eoh_amt_ly)   OVER (PARTITION BY division), 0)  AS eoh_pct_ly
    FROM group_agg
)

SELECT
    division                                                      AS Division,           -- 分组键（对数时筛选视觉对象筛选器固定的值）
    category                                                      AS Category,
    sls_pct_this                                                  AS SLS_Amt_Pct,        -- SLS Amt%（0.2634 → PBI 显示 26%）
    CASE WHEN sls_pct_this IS NULL OR sls_pct_lp IS NULL
         THEN NULL ELSE sls_pct_this - sls_pct_lp END             AS SLS_Amt_Pct_vs_LP,  -- vs LP（原始差值，-0.0152 → PBI 显示 -152bp）
    CASE WHEN sls_pct_this IS NULL OR sls_pct_ly IS NULL
         THEN NULL ELSE sls_pct_this - sls_pct_ly END             AS SLS_Amt_Pct_vs_LY,  -- vs LY（原始差值）
    eoh_pct_this                                                  AS EOH_Amt_Pct,        -- EOH Amt%（This 快照日时点）
    CASE WHEN eoh_pct_this IS NULL OR eoh_pct_lp IS NULL
         THEN NULL ELSE eoh_pct_this - eoh_pct_lp END             AS EOH_Amt_Pct_vs_LP,  -- vs LP（LP 快照日 '2025-09-27'）
    CASE WHEN eoh_pct_this IS NULL OR eoh_pct_ly IS NULL
         THEN NULL ELSE eoh_pct_this - eoh_pct_ly END             AS EOH_Amt_Pct_vs_LY   -- vs LY（LY 快照日 '2025-07-26'）
FROM pct
ORDER BY
    Division ASC,
    Category ASC;


-- ======================================================================
-- SQL 2/2: Label 分组（每个 Label 对应的所有 Category 指标情况，
--          Label 在表中对应 brand 字段；对数时按视觉对象筛选器固定的
--          label 值筛选本段结果）
-- ======================================================================
WITH
-- ── trade 侧 (brand, category) 粒度各期聚合（覆盖 This ∪ LP ∪ LY 三区间）──
trade_agg AS (
    SELECT
        brand,
        category,
        SUM(CASE WHEN data_date BETWEEN '2026-03-29' AND '2026-07-25'
                 THEN net_sales_amt END)                        AS sls_amt_this,
        SUM(CASE WHEN data_date BETWEEN '2025-03-30' AND '2025-09-27'
                 THEN net_sales_amt END)                        AS sls_amt_lp,
        SUM(CASE WHEN data_date BETWEEN '2025-03-30' AND '2025-07-26'
                 THEN net_sales_amt END)                        AS sls_amt_ly
    FROM indep_rl_ads.a02_e2e_product_performance_sales_summary_d
    WHERE platform IN ('JD', 'TM', 'RLE', 'DY')                 -- 对齐 PBI 数据源加载过滤（与切片器无关）
      AND (
            data_date BETWEEN '2026-03-29' AND '2026-07-25'     -- This Period（= This Year）
         OR data_date BETWEEN '2025-03-30' AND '2025-09-27'     -- Last Period（vs LP 基线）
         OR data_date BETWEEN '2025-03-30' AND '2025-07-26'     -- Last Year（vs LY 基线）
      )
    GROUP BY brand, category
),

-- ── inv 侧 (brand, category) 粒度三快照日聚合 ──
inv_agg AS (
    SELECT
        brand,
        category,
        SUM(CASE WHEN data_date = '2026-07-25' THEN msrp_inv_amt END)   AS eoh_amt_this,
        SUM(CASE WHEN data_date = '2025-09-27' THEN msrp_inv_amt END)   AS eoh_amt_lp,
        SUM(CASE WHEN data_date = '2025-07-26' THEN msrp_inv_amt END)   AS eoh_amt_ly
    FROM indep_rl_ads.a02_e2e_product_performance_inv_summary_d
    WHERE data_date IN ('2026-07-25', '2025-09-27', '2025-07-26')   -- 仅三个快照日（单日，不可区间求和）
    GROUP BY brand, category
),

-- ── 行组合 = trade ∪ inv（UNION ALL 再聚合还原 FULL OUTER；单侧 NULL 保留）──
group_agg AS (
    SELECT
        brand,
        category,
        SUM(sls_amt_this)  AS sls_amt_this,
        SUM(sls_amt_lp)    AS sls_amt_lp,
        SUM(sls_amt_ly)    AS sls_amt_ly,
        SUM(eoh_amt_this)  AS eoh_amt_this,
        SUM(eoh_amt_lp)    AS eoh_amt_lp,
        SUM(eoh_amt_ly)    AS eoh_amt_ly
    FROM (
        SELECT brand, category, sls_amt_this, sls_amt_lp, sls_amt_ly,
               NULL AS eoh_amt_this, NULL AS eoh_amt_lp, NULL AS eoh_amt_ly
        FROM trade_agg
        UNION ALL
        SELECT brand, category, NULL, NULL, NULL,
               eoh_amt_this, eoh_amt_lp, eoh_amt_ly
        FROM inv_agg
    ) u
    GROUP BY brand, category
),

-- ── 组内占比（窗口分母 PARTITION BY brand，对应 ALLSELECTED(Category)）──
pct AS (
    SELECT
        brand,
        category,
        sls_amt_this / NULLIF(SUM(sls_amt_this) OVER (PARTITION BY brand), 0)  AS sls_pct_this,
        sls_amt_lp   / NULLIF(SUM(sls_amt_lp)   OVER (PARTITION BY brand), 0)  AS sls_pct_lp,
        sls_amt_ly   / NULLIF(SUM(sls_amt_ly)   OVER (PARTITION BY brand), 0)  AS sls_pct_ly,
        eoh_amt_this / NULLIF(SUM(eoh_amt_this) OVER (PARTITION BY brand), 0)  AS eoh_pct_this,
        eoh_amt_lp   / NULLIF(SUM(eoh_amt_lp)   OVER (PARTITION BY brand), 0)  AS eoh_pct_lp,
        eoh_amt_ly   / NULLIF(SUM(eoh_amt_ly)   OVER (PARTITION BY brand), 0)  AS eoh_pct_ly
    FROM group_agg
)

SELECT
    brand                                                         AS Label,              -- 分组键（brand 字段 = Label 维度，对数时筛选视觉对象筛选器固定的值）
    category                                                      AS Category,
    sls_pct_this                                                  AS SLS_Amt_Pct,        -- SLS Amt%（0.2634 → PBI 显示 26%）
    CASE WHEN sls_pct_this IS NULL OR sls_pct_lp IS NULL
         THEN NULL ELSE sls_pct_this - sls_pct_lp END             AS SLS_Amt_Pct_vs_LP,  -- vs LP（原始差值，-0.0152 → PBI 显示 -152bp）
    CASE WHEN sls_pct_this IS NULL OR sls_pct_ly IS NULL
         THEN NULL ELSE sls_pct_this - sls_pct_ly END             AS SLS_Amt_Pct_vs_LY,  -- vs LY（原始差值）
    eoh_pct_this                                                  AS EOH_Amt_Pct,        -- EOH Amt%（This 快照日时点）
    CASE WHEN eoh_pct_this IS NULL OR eoh_pct_lp IS NULL
         THEN NULL ELSE eoh_pct_this - eoh_pct_lp END             AS EOH_Amt_Pct_vs_LP,  -- vs LP（LP 快照日 '2025-09-27'）
    CASE WHEN eoh_pct_this IS NULL OR eoh_pct_ly IS NULL
         THEN NULL ELSE eoh_pct_this - eoh_pct_ly END             AS EOH_Amt_Pct_vs_LY   -- vs LY（LY 快照日 '2025-07-26'）
FROM pct
ORDER BY
    Label ASC,
    Category ASC;
