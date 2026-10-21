-- ======================================================================
-- 测试 SQL: MD Sales Table（division × md_type 全组合，六个指标一次输出）
-- 所属模块: RL E2E Merch Dashboard - Dimension Cross Analysis - MD Sales Structure
-- 关联方案: MD_Sales_table.md
-- 语法: MySQL 8.0+（CTE / 窗口函数）
-- 结构: 单段独立执行；对数时按 Division 切片器当前选择筛选 Division 列后，
--       与 PBI 表格 / 柱形图逐行（逐 md_type）对比
--
-- ★参数区★（当前为字面量直嵌，修改参数时对全文替换对应日期 / 维度值）
-- Platform:              'ALL'（全选，等价不筛选，SQL 中不附加条件）
-- Store Name:            'ALL'（全选，等价不筛选，SQL 中不附加条件）
-- This Period:     dt ∈ ['2026-03-29', '2026-07-25']（区间汇总）
-- Last Period:     dt ∈ ['2025-03-30', '2025-09-27']（区间汇总，vs LP 基线，
--                  对比期由 Last Period 日期切片器决定，调整切片器时同步替换）
-- 其余商品维度切片器:    全选（等价不筛选，不附加条件；如需单项筛选，在
--                        WHERE 中按已建关系字段同步附加）
-- sales 表加载过滤:      platform IN ('JD', 'TM', 'RLE', 'DY')（对齐 Power Query
--                        数据源过滤，与切片器无关）
--
-- 口径还原说明:
--   1. a02 表日期字段为 data_date（非 dt），ISO 字符串比较与日期比较等价
--   2. 占比分母 = 窗口 SUM() OVER (PARTITION BY division)（对应 DAX
--      ALLSELECTED(Slicer_Md_Type[md_type])——移除 md_type 行筛选、保留
--      Division / 渠道 / 商品维度切片器筛选）；Division 单选某值时筛选该值
--      行即为组内占比（之和 = 100%），全选时为全局占比（之和 = 100%）
--   3. 本板块全部指标取自 sales 单表（net_sales_amt / msrp_net_sales_amt），
--      无库存表、无期末时点，两期均为区间汇总
--   4. 行值驱动：md_type 值域 = trade 侧出现值（= Slicer_Md_Type 值域，
--      取自 sales 表 distinct），This 与 LP 任一期有记录的 md_type 均输出
--      （LP 独有值当期指标为 NULL，对应 PBI 中该行 this 侧指标显示 "-"）
--   5. bp 差值 ×10000 在本 SQL 直接输出（对齐方案 Value 层转换位置）：
--      SLS_Amt_Pct_vs_LP_bp / MSRP_Amt_Pct_vs_LP_bp 已是 bp 数值
--      （如 -152 → PBI Display 显示 -152bp，柱形图 Y 轴刻度同值）
--   6. 金额输出 RMB 原始值：PBI Value 层 ÷ Currency_ExchangeRate 换算
--      （RMB 汇率 = 1 时直接对比），Display 层拼接币种符号（#,##0）
--   7. 空值行为对齐 DAX：分子 NULL 时占比输出 NULL（对应 DAX DIVIDE 分子
--      BLANK → BLANK，显示 "-"）；差值任一侧 NULL 时输出 NULL（对应 DAX
--      ISBLANK 拦截）；窗口 SUM 忽略 NULL 行（对应 DAX SUM 聚合忽略 BLANK）
-- ======================================================================

WITH
-- ── trade 侧 (division, md_type) 粒度双期聚合（This ∪ LP 两区间）──
-- 条件聚合还原各时间口径；NULL 传播对应 DAX SUM 空值
trade_agg AS (
    SELECT
        division,
        md_type,
        SUM(CASE WHEN data_date BETWEEN '2026-03-29' AND '2026-07-25'
                 THEN net_sales_amt END)                        AS sls_amt_this,
        SUM(CASE WHEN data_date BETWEEN '2025-03-30' AND '2025-09-27'
                 THEN net_sales_amt END)                        AS sls_amt_lp,
        SUM(CASE WHEN data_date BETWEEN '2026-03-29' AND '2026-07-25'
                 THEN msrp_net_sales_amt END)                   AS msrp_amt_this,
        SUM(CASE WHEN data_date BETWEEN '2025-03-30' AND '2025-09-27'
                 THEN msrp_net_sales_amt END)                   AS msrp_amt_lp
    FROM indep_rl_ads.a02_e2e_product_performance_sales_summary_d
    WHERE platform IN ('JD', 'TM', 'RLE', 'DY')                 -- 对齐 PBI 数据源加载过滤（与切片器无关）
      AND (
            data_date BETWEEN '2026-03-29' AND '2026-07-25'     -- This Period
         OR data_date BETWEEN '2025-03-30' AND '2025-09-27'     -- Last Period（vs LP 基线）
      )
    GROUP BY division, md_type
),

-- ── 组内占比（窗口分母 PARTITION BY division，对应 ALLSELECTED(md_type)）──
pct AS (
    SELECT
        division,
        md_type,
        sls_amt_this / NULLIF(SUM(sls_amt_this) OVER (PARTITION BY division), 0)  AS sls_pct_this,
        sls_amt_lp   / NULLIF(SUM(sls_amt_lp)   OVER (PARTITION BY division), 0)  AS sls_pct_lp,
        msrp_amt_this / NULLIF(SUM(msrp_amt_this) OVER (PARTITION BY division), 0) AS msrp_pct_this,
        msrp_amt_lp   / NULLIF(SUM(msrp_amt_lp)   OVER (PARTITION BY division), 0) AS msrp_pct_lp,
        sls_amt_this,
        msrp_amt_this
    FROM trade_agg
)

SELECT
    division                                                      AS Division,               -- 筛选维度（对数时筛选 Division 切片器当前值）
    md_type                                                       AS MD_Type,
    sls_pct_this                                                  AS SLS_Amt_Pct,            -- SLS Amt%（0.2634 → PBI 显示 26%）
    sls_amt_this                                                  AS SLS_Amt_RMB,            -- SLS Amt 金额附属（RMB 原值；PBI Value 层 ÷ 汇率）
    msrp_pct_this                                                 AS MSRP_Amt_Pct,           -- MSRP Amt%（0.3121 → PBI 显示 31%）
    msrp_amt_this                                                 AS MSRP_Amt_RMB,           -- MSRP Amt 金额附属（RMB 原值）
    -- vs LP 差值 ×10000 直接输出 bp 数值（对齐方案 Value 层转换位置，
    -- 柱形图 Y 轴刻度 / 表格 Display 同值）
    CASE WHEN sls_pct_this IS NULL OR sls_pct_lp IS NULL
         THEN NULL ELSE (sls_pct_this - sls_pct_lp) * 10000 END  AS SLS_Amt_Pct_vs_LP_bp,   -- SLS Amt% vs LP（-152 → PBI 显示 -152bp）
    CASE WHEN msrp_pct_this IS NULL OR msrp_pct_lp IS NULL
         THEN NULL ELSE (msrp_pct_this - msrp_pct_lp) * 10000 END AS MSRP_Amt_Pct_vs_LP_bp  -- MSRP Amt% vs LP（121 → PBI 显示 121bp）
FROM pct
ORDER BY
    Division ASC,
    MD_Type ASC;
