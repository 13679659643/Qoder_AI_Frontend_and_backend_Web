-- ======================================================================
-- 测试 SQL: Handbags Sales_ms（四段：总计 / spu_model / spu_model+ax_sub_class
--           / 五维明细，分别对齐字段参数切换的四种行维度状态）
-- 所属模块: RL E2E Merch Dashboard - Dimension Cross Analysis - Handbags
--           Sales Analysis by Dimension【字段参数动态行维度矩阵】
-- 关联方案: Handbags_Sales_ms.md
-- 语法: MySQL 8.0+（CTE / 窗口函数 / NULL 安全等于 <=>）
-- 结构: 四段独立执行，对齐 PBI 矩阵的四种行维度状态：
--       SQL 1/4 总计行（无分组——ISINSCOPE 全 FALSE，分子分母同范围）
--       SQL 2/4 字段参数单选 Model（spu_model 分组）
--       SQL 3/4 字段参数多选 Model + Subclass（spu_model + ax_sub_class 分组）
--       SQL 4/4 字段参数全选五维（spu_model + ax_sub_class + season +
--              category + sku_size 分组，明细级组合）
--
-- ★参数区★（当前为字面量直嵌，修改参数时对四段全文替换对应日期 / 维度值）
-- 渠道 Button_Store_Name: 'TTL'（六店铺实际值 IN：TM / JD / RLE_CN / DY_Family /
--                        DY_W / DY_M；单渠道对数时将 IN (...) 替换为
--                        shop_name = '对应实际值'，四段同步替换）
-- This Period:     dt ∈ ['2026-03-29', '2026-07-25']（区间汇总）
-- Last Period:     dt ∈ ['2025-03-30', '2025-07-26']（区间汇总，vs LP 基线，
--                  对比期由 Last Period 日期切片器决定，调整切片器时同步替换）
-- Inventory This 快照日: dt = '2026-07-25'（This Period 区间最后一天，单日快照）
-- Inventory LP 快照日:   dt = '2025-07-26'（Last Period 区间最后一天，单日快照）
-- 其余商品维度切片器:    全选（等价不筛选，不附加条件；如需单项筛选，在
--                        trade / inv 两侧 WHERE 按已建关系字段同步附加）
--
-- 口径还原说明:
--   1. 两张 s02 表日期字段为 dt（非 data_date）；trade 表 net_sales_amt 为
--      PBI 模型内 Power Query 行级列（ROUND(product_qty × sales_price, 6)），
--      数据库无此列，SQL 按行级乘积还原后聚合；product_qty 直接聚合
--   2. 行值域 = trade WHERE category = 'Handbags' 的分组列 DISTINCT（全期，
--      不受时间 / 渠道限制——dt 与渠道均在度量值 CALCULATE 内显式施加，
--      不参与行值域生成）；inv 侧纯库存组合（trade 无记录）不在行值域，
--      PBI 页面无对应行，SQL 经值域 LEFT JOIN 天然排除；若模型加载层含
--      其他过滤（渠道 / 日期），值域子查询与聚合 WHERE 需同步附加
--   3. 维度列含 NULL 时归为一组（对应 PBI 行显示 (Blank)）；值域与聚合
--      JOIN 使用 NULL 安全等于 <=> 保证 NULL 组合正确关联
--   4. 占比分母 = 窗口 SUM() OVER ()（对应 DAX ALLSELECTED(trade 五个动态
--      维度列) 整体移除行区域分组——分母恒为 Handbags + 当前渠道 + 所选
--      期间全量，与分组粒度 / 字段参数选择无关；LP 分母同理）
--   5. EOH 库存侧不附加渠道条件（inv 表无 shop_name 字段），与 trade 侧
--      渠道口径不对称为模型物理限制（ST% 分子分母同样不对称）
--   6. 期末时点只取快照日单日（不可区间求和）；快照当日缺数时 PBI 度量值
--      回退到对应范围内最近一个快照日，SQL 对比时如发现快照日无数据需
--      相应调整日期
--   7. vs LP 输出原始差值小数（×10000 转 bp 在 PBI Display 层实现，
--      如 -0.0152 → PBI 显示 -152bp）；EOH Unit vs LP 为 this / last - 1
--      变化率（PBI Display 为 #,##0%）
--   8. 空值行为对齐 DAX：分子 NULL 时占比输出 NULL（DIVIDE 分子 BLANK →
--      BLANK，显示 "-"）；vs LP 任一侧 NULL 输出 NULL（ISBLANK 拦截）；
--      EOH Unit vs LP 在任一侧 NULL 或 LP 侧为 0 时输出 NULL；ST% 分母
--      加法任一侧 NULL 按 0 处理（DAX 算术 BLANK 当 0），双侧均 NULL
--      时输出 NULL
--   9. IsEmpty 行可见性：SQL 输出值域全部行，七个指标全为 NULL 的行在
--      PBI 页面被视觉级筛选器隐藏（IsEmpty = 0），对数时忽略
--  10. 金额输出 RMB 原始值（PBI Value 层 ÷ Currency_ExchangeRate，RMB
--      汇率 = 1 时直接对比；Display 层拼接币种符号 #,##0）
-- ======================================================================


-- ======================================================================
-- SQL 1/4: 总计行（无分组；对齐 PBI 矩阵开启总计行时的合计口径——
--          ISINSCOPE 全 FALSE，五谓词全放行，SLS Amt% = 100%）
-- ======================================================================
WITH
trade_total AS (
    SELECT
        SUM(CASE WHEN dt BETWEEN '2026-03-29' AND '2026-07-25'
                 THEN ROUND(product_qty * sales_price, 6) END)     AS sls_amt_this,
        SUM(CASE WHEN dt BETWEEN '2025-03-30' AND '2025-07-26'
                 THEN ROUND(product_qty * sales_price, 6) END)     AS sls_amt_lp,
        SUM(CASE WHEN dt BETWEEN '2026-03-29' AND '2026-07-25'
                 THEN product_qty END)                             AS sls_unit_this
    FROM indep_rl_dw.s02_trade_sku_data_d
    WHERE category = 'Handbags'
      AND shop_name IN ('TM', 'JD', 'RLE_CN', 'DY_Family', 'DY_W', 'DY_M')
      AND (
            dt BETWEEN '2026-03-29' AND '2026-07-25'              -- This Period
         OR dt BETWEEN '2025-03-30' AND '2025-07-26'              -- Last Period（vs LP 基线）
      )
),
inv_total AS (
    SELECT
        SUM(CASE WHEN dt = '2026-07-25' THEN stock_inv_qty END)    AS eoh_unit_this,
        SUM(CASE WHEN dt = '2025-07-26' THEN stock_inv_qty END)    AS eoh_unit_lp,
        SUM(CASE WHEN dt = '2026-07-25' THEN msrp_inv_amt END)     AS inv_amt_this
    FROM indep_rl_dw.s02_inventory_stock_sales_detail_d
    WHERE category = 'Handbags'
      AND dt IN ('2026-07-25', '2025-07-26')
)
SELECT
    'TOTAL'                                                         AS Row_Dimension,
    t.sls_amt_this                                                  AS SLS_Amt_RMB,
    t.sls_amt_this / NULLIF(t.sls_amt_this, 0)                      AS SLS_Amt_Pct,
    CASE
        WHEN t.sls_amt_this IS NULL OR t.sls_amt_lp IS NULL THEN NULL
        ELSE (t.sls_amt_this / NULLIF(t.sls_amt_this, 0))
           - (t.sls_amt_lp   / NULLIF(t.sls_amt_lp,   0))
    END                                                             AS SLS_Amt_Pct_vs_LP,
    t.sls_unit_this                                                 AS SLS_Unit,
    i.eoh_unit_this                                                 AS EOH_Unit,
    CASE
        WHEN i.eoh_unit_this IS NULL OR i.eoh_unit_lp IS NULL
          OR i.eoh_unit_lp = 0 THEN NULL
        ELSE i.eoh_unit_this / i.eoh_unit_lp - 1
    END                                                             AS EOH_Unit_vs_LP,
    COALESCE(t.sls_amt_this, 0)
        / NULLIF(COALESCE(t.sls_amt_this, 0) + COALESCE(i.inv_amt_this, 0), 0)
                                                                    AS ST_Pct
FROM trade_total t
CROSS JOIN inv_total i;


-- ======================================================================
-- SQL 2/4: spu_model 分组（对齐字段参数切片器单选 Model 的矩阵行）
-- ======================================================================
WITH
dim_values AS (
    SELECT DISTINCT spu_model
    FROM indep_rl_dw.s02_trade_sku_data_d
    WHERE category = 'Handbags'
),
trade_agg AS (
    SELECT
        spu_model,
        SUM(CASE WHEN dt BETWEEN '2026-03-29' AND '2026-07-25'
                 THEN ROUND(product_qty * sales_price, 6) END)     AS sls_amt_this,
        SUM(CASE WHEN dt BETWEEN '2025-03-30' AND '2025-07-26'
                 THEN ROUND(product_qty * sales_price, 6) END)     AS sls_amt_lp,
        SUM(CASE WHEN dt BETWEEN '2026-03-29' AND '2026-07-25'
                 THEN product_qty END)                             AS sls_unit_this
    FROM indep_rl_dw.s02_trade_sku_data_d
    WHERE category = 'Handbags'
      AND shop_name IN ('TM', 'JD', 'RLE_CN', 'DY_Family', 'DY_W', 'DY_M')
      AND (
            dt BETWEEN '2026-03-29' AND '2026-07-25'              -- This Period
         OR dt BETWEEN '2025-03-30' AND '2025-07-26'              -- Last Period（vs LP 基线）
      )
    GROUP BY spu_model
),
inv_agg AS (
    SELECT
        spu_model,
        SUM(CASE WHEN dt = '2026-07-25' THEN stock_inv_qty END)    AS eoh_unit_this,
        SUM(CASE WHEN dt = '2025-07-26' THEN stock_inv_qty END)    AS eoh_unit_lp,
        SUM(CASE WHEN dt = '2026-07-25' THEN msrp_inv_amt END)     AS inv_amt_this
    FROM indep_rl_dw.s02_inventory_stock_sales_detail_d
    WHERE category = 'Handbags'
      AND dt IN ('2026-07-25', '2025-07-26')
    GROUP BY spu_model
)
SELECT
    'spu_model'                                                     AS Row_Dimension,
    dv.spu_model                                                    AS SP_Model,
    t.sls_amt_this                                                  AS SLS_Amt_RMB,
    t.sls_amt_this
        / NULLIF(SUM(t.sls_amt_this) OVER (), 0)                    AS SLS_Amt_Pct,
    CASE
        WHEN t.sls_amt_this IS NULL OR t.sls_amt_lp IS NULL THEN NULL
        ELSE (t.sls_amt_this / NULLIF(SUM(t.sls_amt_this) OVER (), 0))
           - (t.sls_amt_lp   / NULLIF(SUM(t.sls_amt_lp)   OVER (), 0))
    END                                                             AS SLS_Amt_Pct_vs_LP,
    t.sls_unit_this                                                 AS SLS_Unit,
    i.eoh_unit_this                                                 AS EOH_Unit,
    CASE
        WHEN i.eoh_unit_this IS NULL OR i.eoh_unit_lp IS NULL
          OR i.eoh_unit_lp = 0 THEN NULL
        ELSE i.eoh_unit_this / i.eoh_unit_lp - 1
    END                                                             AS EOH_Unit_vs_LP,
    COALESCE(t.sls_amt_this, 0)
        / NULLIF(COALESCE(t.sls_amt_this, 0) + COALESCE(i.inv_amt_this, 0), 0)
                                                                    AS ST_Pct
FROM dim_values dv
LEFT JOIN trade_agg t ON dv.spu_model <=> t.spu_model
LEFT JOIN inv_agg   i ON dv.spu_model <=> i.spu_model
ORDER BY dv.spu_model IS NULL, dv.spu_model;


-- ======================================================================
-- SQL 3/4: spu_model + ax_sub_class 分组（对齐字段参数切片器多选
--          Model + Subclass 的矩阵行——两字段并列组合）
-- ======================================================================
WITH
dim_values AS (
    SELECT DISTINCT spu_model, ax_sub_class
    FROM indep_rl_dw.s02_trade_sku_data_d
    WHERE category = 'Handbags'
),
trade_agg AS (
    SELECT
        spu_model,
        ax_sub_class,
        SUM(CASE WHEN dt BETWEEN '2026-03-29' AND '2026-07-25'
                 THEN ROUND(product_qty * sales_price, 6) END)     AS sls_amt_this,
        SUM(CASE WHEN dt BETWEEN '2025-03-30' AND '2025-07-26'
                 THEN ROUND(product_qty * sales_price, 6) END)     AS sls_amt_lp,
        SUM(CASE WHEN dt BETWEEN '2026-03-29' AND '2026-07-25'
                 THEN product_qty END)                             AS sls_unit_this
    FROM indep_rl_dw.s02_trade_sku_data_d
    WHERE category = 'Handbags'
      AND shop_name IN ('TM', 'JD', 'RLE_CN', 'DY_Family', 'DY_W', 'DY_M')
      AND (
            dt BETWEEN '2026-03-29' AND '2026-07-25'              -- This Period
         OR dt BETWEEN '2025-03-30' AND '2025-07-26'              -- Last Period（vs LP 基线）
      )
    GROUP BY spu_model, ax_sub_class
),
inv_agg AS (
    SELECT
        spu_model,
        ax_sub_class,
        SUM(CASE WHEN dt = '2026-07-25' THEN stock_inv_qty END)    AS eoh_unit_this,
        SUM(CASE WHEN dt = '2025-07-26' THEN stock_inv_qty END)    AS eoh_unit_lp,
        SUM(CASE WHEN dt = '2026-07-25' THEN msrp_inv_amt END)     AS inv_amt_this
    FROM indep_rl_dw.s02_inventory_stock_sales_detail_d
    WHERE category = 'Handbags'
      AND dt IN ('2026-07-25', '2025-07-26')
    GROUP BY spu_model, ax_sub_class
)
SELECT
    'spu_model+ax_sub_class'                                        AS Row_Dimension,
    dv.spu_model                                                    AS SP_Model,
    dv.ax_sub_class                                                 AS AX_Sub_Class,
    t.sls_amt_this                                                  AS SLS_Amt_RMB,
    t.sls_amt_this
        / NULLIF(SUM(t.sls_amt_this) OVER (), 0)                    AS SLS_Amt_Pct,
    CASE
        WHEN t.sls_amt_this IS NULL OR t.sls_amt_lp IS NULL THEN NULL
        ELSE (t.sls_amt_this / NULLIF(SUM(t.sls_amt_this) OVER (), 0))
           - (t.sls_amt_lp   / NULLIF(SUM(t.sls_amt_lp)   OVER (), 0))
    END                                                             AS SLS_Amt_Pct_vs_LP,
    t.sls_unit_this                                                 AS SLS_Unit,
    i.eoh_unit_this                                                 AS EOH_Unit,
    CASE
        WHEN i.eoh_unit_this IS NULL OR i.eoh_unit_lp IS NULL
          OR i.eoh_unit_lp = 0 THEN NULL
        ELSE i.eoh_unit_this / i.eoh_unit_lp - 1
    END                                                             AS EOH_Unit_vs_LP,
    COALESCE(t.sls_amt_this, 0)
        / NULLIF(COALESCE(t.sls_amt_this, 0) + COALESCE(i.inv_amt_this, 0), 0)
                                                                    AS ST_Pct
FROM dim_values dv
LEFT JOIN trade_agg t
    ON dv.spu_model  <=> t.spu_model
   AND dv.ax_sub_class <=> t.ax_sub_class
LEFT JOIN inv_agg   i
    ON dv.spu_model  <=> i.spu_model
   AND dv.ax_sub_class <=> i.ax_sub_class
ORDER BY dv.spu_model IS NULL, dv.spu_model, dv.ax_sub_class IS NULL, dv.ax_sub_class;


-- ======================================================================
-- SQL 4/4: 五维明细分组（对齐字段参数切片器全选五个字段的矩阵行——
--          spu_model + ax_sub_class + season + category + sku_size
--          组合，SKU 级明细行；category 列经 Handbags 前置筛选恒为
--          'Handbags'，输出仅作对数定位）
-- ======================================================================
WITH
dim_values AS (
    SELECT DISTINCT spu_model, ax_sub_class, season, category, sku_size
    FROM indep_rl_dw.s02_trade_sku_data_d
    WHERE category = 'Handbags'
),
trade_agg AS (
    SELECT
        spu_model,
        ax_sub_class,
        season,
        category,
        sku_size,
        SUM(CASE WHEN dt BETWEEN '2026-03-29' AND '2026-07-25'
                 THEN ROUND(product_qty * sales_price, 6) END)     AS sls_amt_this,
        SUM(CASE WHEN dt BETWEEN '2025-03-30' AND '2025-07-26'
                 THEN ROUND(product_qty * sales_price, 6) END)     AS sls_amt_lp,
        SUM(CASE WHEN dt BETWEEN '2026-03-29' AND '2026-07-25'
                 THEN product_qty END)                             AS sls_unit_this
    FROM indep_rl_dw.s02_trade_sku_data_d
    WHERE category = 'Handbags'
      AND shop_name IN ('TM', 'JD', 'RLE_CN', 'DY_Family', 'DY_W', 'DY_M')
      AND (
            dt BETWEEN '2026-03-29' AND '2026-07-25'              -- This Period
         OR dt BETWEEN '2025-03-30' AND '2025-07-26'              -- Last Period（vs LP 基线）
      )
    GROUP BY spu_model, ax_sub_class, season, category, sku_size
),
inv_agg AS (
    SELECT
        spu_model,
        ax_sub_class,
        season,
        category,
        sku_size,
        SUM(CASE WHEN dt = '2026-07-25' THEN stock_inv_qty END)    AS eoh_unit_this,
        SUM(CASE WHEN dt = '2025-07-26' THEN stock_inv_qty END)    AS eoh_unit_lp,
        SUM(CASE WHEN dt = '2026-07-25' THEN msrp_inv_amt END)     AS inv_amt_this
    FROM indep_rl_dw.s02_inventory_stock_sales_detail_d
    WHERE category = 'Handbags'
      AND dt IN ('2026-07-25', '2025-07-26')
    GROUP BY spu_model, ax_sub_class, season, category, sku_size
)
SELECT
    'detail_5dim'                                                   AS Row_Dimension,
    dv.spu_model                                                    AS SP_Model,
    dv.ax_sub_class                                                 AS AX_Sub_Class,
    dv.season                                                       AS Season,
    dv.category                                                     AS Category,
    dv.sku_size                                                     AS SKU_Size,
    t.sls_amt_this                                                  AS SLS_Amt_RMB,
    t.sls_amt_this
        / NULLIF(SUM(t.sls_amt_this) OVER (), 0)                    AS SLS_Amt_Pct,
    CASE
        WHEN t.sls_amt_this IS NULL OR t.sls_amt_lp IS NULL THEN NULL
        ELSE (t.sls_amt_this / NULLIF(SUM(t.sls_amt_this) OVER (), 0))
           - (t.sls_amt_lp   / NULLIF(SUM(t.sls_amt_lp)   OVER (), 0))
    END                                                             AS SLS_Amt_Pct_vs_LP,
    t.sls_unit_this                                                 AS SLS_Unit,
    i.eoh_unit_this                                                 AS EOH_Unit,
    CASE
        WHEN i.eoh_unit_this IS NULL OR i.eoh_unit_lp IS NULL
          OR i.eoh_unit_lp = 0 THEN NULL
        ELSE i.eoh_unit_this / i.eoh_unit_lp - 1
    END                                                             AS EOH_Unit_vs_LP,
    COALESCE(t.sls_amt_this, 0)
        / NULLIF(COALESCE(t.sls_amt_this, 0) + COALESCE(i.inv_amt_this, 0), 0)
                                                                    AS ST_Pct
FROM dim_values dv
LEFT JOIN trade_agg t
    ON dv.spu_model    <=> t.spu_model
   AND dv.ax_sub_class <=> t.ax_sub_class
   AND dv.season       <=> t.season
   AND dv.category     <=> t.category
   AND dv.sku_size     <=> t.sku_size
LEFT JOIN inv_agg   i
    ON dv.spu_model    <=> i.spu_model
   AND dv.ax_sub_class <=> i.ax_sub_class
   AND dv.season       <=> i.season
   AND dv.category     <=> i.category
   AND dv.sku_size     <=> i.sku_size
ORDER BY dv.spu_model IS NULL, dv.spu_model,
         dv.ax_sub_class IS NULL, dv.ax_sub_class,
         dv.season IS NULL, dv.season,
         dv.sku_size IS NULL, dv.sku_size;
