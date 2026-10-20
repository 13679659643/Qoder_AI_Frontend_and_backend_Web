-- ======================================================================
-- 测试 SQL 1/3: 主视图表格（子模块一 Label / 子模块三 Product Type 等，
--                六种行维度切换一次输出）
-- 所属模块: RL E2E Merch Dashboard - Dimension Cross Analysis - Label & Product Type Inventory Structure
-- 关联方案: Label_&_Product_Type_table.md（§4.1~§4.18 主视图度量值）
-- 语法: MySQL 8.0+（CTE / 窗口函数）
-- 结构: 单段独立执行；Row_Dimension 列区分六种行维度，对数时按 PBI
--       当前所切行维度筛选该列（如行切到 Label → 只看 Row_Dimension='label'）
--
-- ★参数区★（当前为字面量直嵌，修改参数时对全文替换对应日期 / 维度值）
-- Platform:              'ALL'（全选，等价不筛选，SQL 中不附加条件）
-- Store Name:            'ALL'（全选，等价不筛选，SQL 中不附加条件）
-- Sales This Period:     dt ∈ ['2026-03-29', '2026-07-25']（区间汇总）
-- Sales Last Period:     dt ∈ ['2025-03-30', '2025-07-26']（区间汇总）
-- Inventory This 时点:   dt = '2026-07-25'（This Period 最后一天，单日快照）
-- Inventory Last 时点:   dt = '2025-07-26'（Last Period 最后一天，单日快照）
-- YTD 财年第一天:        '2026-03-29'（FY27 财年第一天，与 This Period 起点
--                        重合，本参数下 YTD 区间 = This Period；起始月不同时
--                        同步调整 trade_agg 中 ytd_qty 的 CASE 条件）
-- 其余商品维度切片器:    全选（等价不筛选，不附加条件；如需单项筛选，在
--                        trade / inv 两侧 WHERE 按已建关系字段同步附加）
-- sales 表加载过滤:      platform IN ('JD', 'TM', 'RLE', 'DY')（对齐 Power Query
--                        数据源过滤，与切片器无关；inv 表无 platform 字段不涉及）
--
-- 口径还原说明:
--   1. 两张 a02 表日期字段为 data_date（非 dt），ISO 字符串比较与日期比较等价
--   2. 占比分母 = 全量合计（对应 DAX ALLSELECTED 六个商品维度——移除视觉对象
--      内部行维度筛选、保留外部切片器筛选；本参数下外部筛选全选 = 全量）
--   3. 六种行维度 UNION ALL 一次输出（label / super_season / product_type /
--      category / md_type / division），行维度值来自 trade 侧（= Slicer_ 维度
--      表值域，取自 sales 表 distinct），trade 无记录的维度值不出现在行上，
--      对齐 PBI 行为
--   4. 库存类指标按同一维度独立上卷后 LEFT JOIN（inv 侧同维度全量金额，
--      含 trade 侧无记录的子组合；inv 表无渠道字段，不受 Platform / Store 筛选）
--   5. 期末时点只取快照日单日（不可区间求和）；快照当日缺数时 PBI 度量值会
--      回退到 end period 范围内最近一个快照日，SQL 对比时如发现快照日无
--      数据需相应调整日期
--   6. 空值行为对齐 DAX：分子 NULL 时占比 / MD / ST% 整体输出 NULL（对应
--      DAX DIVIDE 分子 BLANK → BLANK，显示 "-"）；YTD ST% 分母加法对 NULL
--      侧按 0 处理（对应 DAX 算术运算 BLANK 当 0：销售侧有值 + 库存侧空 →
--      分母 = 销售侧值）；vs LP 任一期 NULL 时差值输出 NULL（对应 DAX
--      ISBLANK 拦截）；MD 分母（吊牌金额）NULL 或 0 时输出 NULL（对应
--      DAX 显式拦截，避免 1 - BLANK() = 1 失真）
--   7. vs LP 输出原始差值（×10000 转 bp 在 PBI Display 层实现，如 -0.0152
--      → PBI 显示 -152bp）
--   8. 输出列顺序对齐方案 §6.1 值列顺序：SLS Amt% → EOH Amt% →
--      SLS Amt% vs LP → EOH Amt% vs LP → SLS Unit → EOH Unit → YTD ST% → MD
-- ======================================================================

WITH
-- ── trade 侧六维度组合粒度（This / Last / YTD 条件聚合；NULL 传播对应 DAX SUM 空值）──
trade_agg AS (
    SELECT
        brand,
        super_season,
        product_type,
        category,
        md_type,
        division,
        SUM(CASE WHEN data_date BETWEEN '2026-03-29' AND '2026-07-25'
                 THEN net_sales_amt END)                        AS sls_amt_this,
        SUM(CASE WHEN data_date BETWEEN '2025-03-30' AND '2025-07-26'
                 THEN net_sales_amt END)                        AS sls_amt_last,
        SUM(CASE WHEN data_date BETWEEN '2026-03-29' AND '2026-07-25'
                 THEN net_sales_qty END)                        AS sls_unit,
        SUM(CASE WHEN data_date BETWEEN '2026-03-29' AND '2026-07-25'
                 THEN net_sales_qty END)                        AS ytd_qty,      -- YTD 区间 = This（FY27 第一天与 This 起点重合，见参数区）
        SUM(CASE WHEN data_date BETWEEN '2026-03-29' AND '2026-07-25'
                 THEN md_net_sales_amt END)                     AS md_amt,
        SUM(CASE WHEN data_date BETWEEN '2026-03-29' AND '2026-07-25'
                 THEN msrp_net_sales_amt END)                   AS msrp_amt
    FROM indep_rl_ads.a02_e2e_product_performance_sales_summary_d
    WHERE platform IN ('JD', 'TM', 'RLE', 'DY')                 -- 对齐 PBI 数据源加载过滤（与切片器无关）
      AND (
            data_date BETWEEN '2026-03-29' AND '2026-07-25'     -- Sales This Period
         OR data_date BETWEEN '2025-03-30' AND '2025-07-26'     -- Sales Last Period（vs LP 基线）
      )
    GROUP BY brand, super_season, product_type, category, md_type, division
),

-- ── inv 侧六维度组合粒度（双期期末快照单日时点）──
inv_agg AS (
    SELECT
        brand,
        super_season,
        product_type,
        category,
        md_type,
        division,
        SUM(CASE WHEN data_date = '2026-07-25' THEN msrp_inv_amt END)   AS eoh_amt_this,
        SUM(CASE WHEN data_date = '2025-07-26' THEN msrp_inv_amt END)   AS eoh_amt_last,
        SUM(CASE WHEN data_date = '2026-07-25' THEN inv_qty END)        AS eoh_unit
    FROM indep_rl_ads.a02_e2e_product_performance_inv_summary_d
    WHERE data_date IN ('2026-07-25', '2025-07-26')             -- 仅双期期末快照日（单日，不可区间求和）
    GROUP BY brand, super_season, product_type, category, md_type, division
),

-- ── 占比分母：全量合计（对应 DAX ALLSELECTED 六维度；外部筛选全选 = 全量）──
sales_total AS (
    SELECT
        SUM(sls_amt_this)   AS total_sls_amt_this,
        SUM(sls_amt_last)   AS total_sls_amt_last
    FROM trade_agg
),
inv_total AS (
    SELECT
        SUM(eoh_amt_this)   AS total_eoh_amt_this,
        SUM(eoh_amt_last)   AS total_eoh_amt_last
    FROM inv_agg
),

-- ── 六种行维度上卷（trade 驱动行值，inv 同维度独立上卷后 LEFT JOIN）──
rollup AS (
    -- 行维度: label
    SELECT 'label' AS row_dim, tr.dim_val,
           tr.sls_amt_this, tr.sls_amt_last, tr.sls_unit, tr.ytd_qty, tr.md_amt, tr.msrp_amt,
           ir.eoh_amt_this, ir.eoh_amt_last, ir.eoh_unit
    FROM (
        SELECT brand AS dim_val,
               SUM(sls_amt_this) AS sls_amt_this, SUM(sls_amt_last) AS sls_amt_last,
               SUM(sls_unit)     AS sls_unit,     SUM(ytd_qty)      AS ytd_qty,
               SUM(md_amt)       AS md_amt,       SUM(msrp_amt)     AS msrp_amt
        FROM trade_agg GROUP BY brand
    ) tr
    LEFT JOIN (
        SELECT brand AS dim_val,
               SUM(eoh_amt_this) AS eoh_amt_this, SUM(eoh_amt_last) AS eoh_amt_last,
               SUM(eoh_unit)     AS eoh_unit
        FROM inv_agg GROUP BY brand
    ) ir ON tr.dim_val = ir.dim_val

    UNION ALL
    -- 行维度: super_season
    SELECT 'super_season', tr.dim_val,
           tr.sls_amt_this, tr.sls_amt_last, tr.sls_unit, tr.ytd_qty, tr.md_amt, tr.msrp_amt,
           ir.eoh_amt_this, ir.eoh_amt_last, ir.eoh_unit
    FROM (
        SELECT super_season AS dim_val,
               SUM(sls_amt_this) AS sls_amt_this, SUM(sls_amt_last) AS sls_amt_last,
               SUM(sls_unit)     AS sls_unit,     SUM(ytd_qty)      AS ytd_qty,
               SUM(md_amt)       AS md_amt,       SUM(msrp_amt)     AS msrp_amt
        FROM trade_agg GROUP BY super_season
    ) tr
    LEFT JOIN (
        SELECT super_season AS dim_val,
               SUM(eoh_amt_this) AS eoh_amt_this, SUM(eoh_amt_last) AS eoh_amt_last,
               SUM(eoh_unit)     AS eoh_unit
        FROM inv_agg GROUP BY super_season
    ) ir ON tr.dim_val = ir.dim_val

    UNION ALL
    -- 行维度: product_type
    SELECT 'product_type', tr.dim_val,
           tr.sls_amt_this, tr.sls_amt_last, tr.sls_unit, tr.ytd_qty, tr.md_amt, tr.msrp_amt,
           ir.eoh_amt_this, ir.eoh_amt_last, ir.eoh_unit
    FROM (
        SELECT product_type AS dim_val,
               SUM(sls_amt_this) AS sls_amt_this, SUM(sls_amt_last) AS sls_amt_last,
               SUM(sls_unit)     AS sls_unit,     SUM(ytd_qty)      AS ytd_qty,
               SUM(md_amt)       AS md_amt,       SUM(msrp_amt)     AS msrp_amt
        FROM trade_agg GROUP BY product_type
    ) tr
    LEFT JOIN (
        SELECT product_type AS dim_val,
               SUM(eoh_amt_this) AS eoh_amt_this, SUM(eoh_amt_last) AS eoh_amt_last,
               SUM(eoh_unit)     AS eoh_unit
        FROM inv_agg GROUP BY product_type
    ) ir ON tr.dim_val = ir.dim_val

    UNION ALL
    -- 行维度: category
    SELECT 'category', tr.dim_val,
           tr.sls_amt_this, tr.sls_amt_last, tr.sls_unit, tr.ytd_qty, tr.md_amt, tr.msrp_amt,
           ir.eoh_amt_this, ir.eoh_amt_last, ir.eoh_unit
    FROM (
        SELECT category AS dim_val,
               SUM(sls_amt_this) AS sls_amt_this, SUM(sls_amt_last) AS sls_amt_last,
               SUM(sls_unit)     AS sls_unit,     SUM(ytd_qty)      AS ytd_qty,
               SUM(md_amt)       AS md_amt,       SUM(msrp_amt)     AS msrp_amt
        FROM trade_agg GROUP BY category
    ) tr
    LEFT JOIN (
        SELECT category AS dim_val,
               SUM(eoh_amt_this) AS eoh_amt_this, SUM(eoh_amt_last) AS eoh_amt_last,
               SUM(eoh_unit)     AS eoh_unit
        FROM inv_agg GROUP BY category
    ) ir ON tr.dim_val = ir.dim_val

    UNION ALL
    -- 行维度: md_type
    SELECT 'md_type', tr.dim_val,
           tr.sls_amt_this, tr.sls_amt_last, tr.sls_unit, tr.ytd_qty, tr.md_amt, tr.msrp_amt,
           ir.eoh_amt_this, ir.eoh_amt_last, ir.eoh_unit
    FROM (
        SELECT md_type AS dim_val,
               SUM(sls_amt_this) AS sls_amt_this, SUM(sls_amt_last) AS sls_amt_last,
               SUM(sls_unit)     AS sls_unit,     SUM(ytd_qty)      AS ytd_qty,
               SUM(md_amt)       AS md_amt,       SUM(msrp_amt)     AS msrp_amt
        FROM trade_agg GROUP BY md_type
    ) tr
    LEFT JOIN (
        SELECT md_type AS dim_val,
               SUM(eoh_amt_this) AS eoh_amt_this, SUM(eoh_amt_last) AS eoh_amt_last,
               SUM(eoh_unit)     AS eoh_unit
        FROM inv_agg GROUP BY md_type
    ) ir ON tr.dim_val = ir.dim_val

    UNION ALL
    -- 行维度: division
    SELECT 'division', tr.dim_val,
           tr.sls_amt_this, tr.sls_amt_last, tr.sls_unit, tr.ytd_qty, tr.md_amt, tr.msrp_amt,
           ir.eoh_amt_this, ir.eoh_amt_last, ir.eoh_unit
    FROM (
        SELECT division AS dim_val,
               SUM(sls_amt_this) AS sls_amt_this, SUM(sls_amt_last) AS sls_amt_last,
               SUM(sls_unit)     AS sls_unit,     SUM(ytd_qty)      AS ytd_qty,
               SUM(md_amt)       AS md_amt,       SUM(msrp_amt)     AS msrp_amt
        FROM trade_agg GROUP BY division
    ) tr
    LEFT JOIN (
        SELECT division AS dim_val,
               SUM(eoh_amt_this) AS eoh_amt_this, SUM(eoh_amt_last) AS eoh_amt_last,
               SUM(eoh_unit)     AS eoh_unit
        FROM inv_agg GROUP BY division
    ) ir ON tr.dim_val = ir.dim_val
)

SELECT
    row_dim                                                       AS Row_Dimension,   -- 行维度标识（对数时按 PBI 当前行维度筛选）
    dim_val                                                       AS Dimension_Value,
    sls_amt_this / NULLIF(st.total_sls_amt_this, 0)               AS SLS_Amt_Pct,     -- SLS Amt%（0.2634 → PBI 显示 26%）
    eoh_amt_this  / NULLIF(it.total_eoh_amt_this, 0)              AS EOH_Amt_Pct,     -- EOH Amt%（快照日时点）
    sls_amt_this / NULLIF(st.total_sls_amt_this, 0)
      - sls_amt_last / NULLIF(st.total_sls_amt_last, 0)           AS SLS_Amt_Pct_vs_LP,   -- vs LP（原始差值，-0.0152 → PBI 显示 -152bp）
    eoh_amt_this  / NULLIF(it.total_eoh_amt_this, 0)
      - eoh_amt_last  / NULLIF(it.total_eoh_amt_last, 0)          AS EOH_Amt_Pct_vs_LP,   -- vs LP（双期各自快照日）
    sls_unit                                                      AS SLS_Unit,
    eoh_unit                                                      AS EOH_Unit,
    ytd_qty
        / NULLIF(COALESCE(ytd_qty, 0) + COALESCE(eoh_unit, 0), 0) AS YTD_ST_Pct,      -- 跨双表：YTD 区间销量 + This 快照日库存
    1 - md_amt / NULLIF(msrp_amt, 0)                              AS MD_Pct           -- 分母空 / 0 → NULL（对齐 DAX 拦截）
FROM rollup
CROSS JOIN sales_total st
CROSS JOIN inv_total it
ORDER BY
    Row_Dimension ASC,
    Dimension_Value ASC;
