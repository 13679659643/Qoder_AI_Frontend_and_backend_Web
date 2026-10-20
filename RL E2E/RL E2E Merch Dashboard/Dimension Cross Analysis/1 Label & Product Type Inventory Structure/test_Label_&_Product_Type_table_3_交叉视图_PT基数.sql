-- ======================================================================
-- 测试 SQL 3/3: 交叉柱形图（子模块四，Product Type 基数，五种图例维度一次输出）
-- 所属模块: RL E2E Merch Dashboard - Dimension Cross Analysis - Label & Product Type Inventory Structure
-- 关联方案: Label_&_Product_Type_table.md（§4.23~§4.26 占比度量值 + §4.31~§4.34 金额附属）
-- 语法: MySQL 8.0+（CTE / 窗口函数）
-- 结构: 单段独立执行；Cross_Dimension 列区分五种图例维度，对数时按 PBI
--       当前图例维度筛选该列（如图例切到 Label → 只看
--       Cross_Dimension='label'）；本视图无 vs LP 类指标，
--       Last Period 参数不适用
--
-- ★参数区★（当前为字面量直嵌，修改参数时对全文替换对应日期 / 维度值）
-- Platform:              'ALL'（全选，等价不筛选，SQL 中不附加条件）
-- Store Name:            'ALL'（全选，等价不筛选，SQL 中不附加条件）
-- Sales This Period:     dt ∈ ['2026-03-29', '2026-07-25']（区间汇总）
-- Inventory This 时点:   dt = '2026-07-25'（This Period 最后一天，单日快照）
-- 其余商品维度切片器:    全选（等价不筛选，不附加条件；如需单项筛选，在
--                        trade / inv 两侧 WHERE 按已建关系字段同步附加）
-- sales 表加载过滤:      platform IN ('JD', 'TM', 'RLE', 'DY')（对齐 Power Query
--                        数据源过滤，与切片器无关；inv 表无 platform 字段不涉及）
--
-- 口径还原说明:
--   1. 两张 a02 表日期字段为 data_date（非 dt），ISO 字符串比较与日期比较等价
--   2. 占比分母 = 该 Product Type 柱形内合计（窗口 SUM() OVER (PARTITION BY
--      Cross_Dimension, Product_Type)，对应 DAX ALLSELECTED 五个交叉维度——
--      移除图例维度筛选、保留 x 轴 Product Type 柱形筛选与外部切片器筛选）
--   3. 五种图例维度一次输出（label / super_season / category / md_type /
--      division），Product Type 基数视图图例不可切 product_type 自身；
--      与 Label 基数视图（测试 SQL 2/3）的交叉维度集合互异，两视图独立对数
--   4. 行组合 = trade ∪ inv（UNION ALL 再聚合还原 FULL OUTER 语义）：
--      PBI 柱形图数据点由度量值非空驱动——SLS_Amt_Pct 为 NULL 的行在
--      SLS Amt% 图上不存在，EOH_Amt_Pct 为 NULL 的行在 EOH Amt% 图上
--      不存在，对数时按对应图忽略另一侧 NULL 行
--   5. 金额类附属（SLS_Amt_RMB / EOH_Amt_RMB）输出 RMB 原始值：PBI Value 层
--      ÷ Currency_ExchangeRate 换算（RMB 汇率 = 1 时直接对比），Display 层
--      拼接币种符号（#,##0）
--   6. 期末时点只取快照日单日；快照当日缺数时 PBI 回退到 end period 范围内
--      最近一个快照日，SQL 对比时相应调整日期
--   7. 空值行为对齐 DAX：分子 NULL 时占比输出 NULL（对应 DAX DIVIDE 分子
--      BLANK → BLANK，显示 "-"）
--   8. inv 表无渠道字段：EOH Amt% / EOH_Amt_RMB 不受 Platform / Store 筛选
--      影响；SLS 侧受渠道筛选影响（本参数全选 = 不筛选）
-- ======================================================================

WITH
-- ── trade 侧六维度组合粒度（This 条件聚合；NULL 传播对应 DAX SUM 空值）──
trade_agg AS (
    SELECT
        brand,
        super_season,
        product_type,
        category,
        md_type,
        division,
        SUM(CASE WHEN data_date BETWEEN '2026-03-29' AND '2026-07-25'
                 THEN net_sales_amt END)                        AS sls_amt
    FROM indep_rl_ads.a02_e2e_product_performance_sales_summary_d
    WHERE platform IN ('JD', 'TM', 'RLE', 'DY')                 -- 对齐 PBI 数据源加载过滤（与切片器无关）
      AND data_date BETWEEN '2026-03-29' AND '2026-07-25'       -- Sales This Period
    GROUP BY brand, super_season, product_type, category, md_type, division
),

-- ── inv 侧六维度组合粒度（This 期末快照单日时点）──
inv_agg AS (
    SELECT
        brand,
        super_season,
        product_type,
        category,
        md_type,
        division,
        SUM(CASE WHEN data_date = '2026-07-25' THEN msrp_inv_amt END)   AS eoh_amt
    FROM indep_rl_ads.a02_e2e_product_performance_inv_summary_d
    WHERE data_date = '2026-07-25'                              -- This 期末快照日（单日，不可区间求和）
    GROUP BY brand, super_season, product_type, category, md_type, division
),

-- ── trade 长表：五种图例维度 × Product Type（投影展开，不聚合）──
-- 注意：label 图例取自 brand 字段（口径 Label 维度 = 事实表 brand 字段）
trade_long AS (
    SELECT 'label'        AS cross_dim, product_type AS product_type, brand        AS cross_val, sls_amt FROM trade_agg
    UNION ALL
    SELECT 'super_season', product_type, super_season, sls_amt FROM trade_agg
    UNION ALL
    SELECT 'category',     product_type, category,     sls_amt FROM trade_agg
    UNION ALL
    SELECT 'md_type',      product_type, md_type,      sls_amt FROM trade_agg
    UNION ALL
    SELECT 'division',     product_type, division,     sls_amt FROM trade_agg
),

-- ── inv 长表：同结构（eoh_amt）──
inv_long AS (
    SELECT 'label'        AS cross_dim, product_type AS product_type, brand        AS cross_val, eoh_amt FROM inv_agg
    UNION ALL
    SELECT 'super_season', product_type, super_season, eoh_amt FROM inv_agg
    UNION ALL
    SELECT 'category',     product_type, category,     eoh_amt FROM inv_agg
    UNION ALL
    SELECT 'md_type',      product_type, md_type,      eoh_amt FROM inv_agg
    UNION ALL
    SELECT 'division',     product_type, division,     eoh_amt FROM inv_agg
),

-- ── 行组合 = trade ∪ inv（UNION ALL 再聚合还原 FULL OUTER；单侧 NULL 保留，
--    双侧 NULL → NULL，对齐 DAX 分子 BLANK 显示 "-" 的数据点缺失行为）──
cross_rollup AS (
    SELECT
        cross_dim,
        product_type,
        cross_val,
        SUM(sls_amt)    AS sls_amt,
        SUM(eoh_amt)    AS eoh_amt
    FROM (
        SELECT cross_dim, product_type, cross_val, sls_amt, NULL AS eoh_amt FROM trade_long
        UNION ALL
        SELECT cross_dim, product_type, cross_val, NULL,         eoh_amt    FROM inv_long
    ) u
    GROUP BY cross_dim, product_type, cross_val
)

SELECT
    cross_dim                                                     AS Cross_Dimension, -- 图例维度标识（对数时按 PBI 当前图例维度筛选）
    product_type                                                  AS Product_Type,    -- x 轴（基数维度）
    cross_val                                                     AS Cross_Value,     -- 图例维度值
    sls_amt                                                       AS SLS_Amt_RMB,     -- 金额附属（RMB 原值；PBI Value 层 ÷ 汇率）
    eoh_amt                                                       AS EOH_Amt_RMB,     -- 金额附属（快照日时点，RMB 原值）
    sls_amt / NULLIF(SUM(sls_amt) OVER (PARTITION BY cross_dim, product_type), 0)   AS SLS_Amt_Pct,  -- 该交叉维度值占所属 Product Type 柱形的比例
    eoh_amt / NULLIF(SUM(eoh_amt) OVER (PARTITION BY cross_dim, product_type), 0)   AS EOH_Amt_Pct   -- 期末库存金额占比（快照日时点）
FROM cross_rollup
ORDER BY
    Cross_Dimension ASC,
    Product_Type ASC,
    Cross_Value ASC;
