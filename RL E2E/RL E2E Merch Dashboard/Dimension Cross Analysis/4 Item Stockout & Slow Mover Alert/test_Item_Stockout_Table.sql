-- ======================================================================
-- 测试 SQL: Item Stockout Table（两段：SPU 维度 / SKU 维度）
-- 所属模块: RL E2E Merch Dashboard - Dimension Cross Analysis - Item
--           Stockout & Slow Mover Alert【单列主键 Top 100 双表格】
-- 关联方案: Item_Stockout_Table.md（v2.7）
-- 语法: MySQL 8.0+（CTE / 窗口函数 / GROUP_CONCAT）
-- 结构: SQL 1/2 SPU 维度（GROUP BY spu_id）+ SQL 2/2 SKU 维度
--       （GROUP BY sku_id），两段独立执行；每段按 SLS Amt 降序 +
--       主键字母序决胜输出 Top 100（LIMIT 100，对齐 PBI 表格 TopN
--       列筛选器「主键 前 100 个（按 SLS Amt Value 降序）」+ 行排序
--       Rank 升序）
--
-- ★参数区★（当前为字面量直嵌，修改参数时对两段全文替换对应日期 / 维度值）
-- Platform:              'ALL'（全选，等价不筛选，SQL 中不附加条件）
-- Store Name:            'ALL'（全选，等价不筛选，SQL 中不附加条件）
-- This Period:     dt ∈ ['2026-03-29', '2026-07-25']（区间汇总——SLS
--                  Amt / SLS Units / AUR / MD / 属性字段"最新日期"判定）
-- Last Period:     dt ∈ ['2025-03-30', '2025-09-27']（本方案十五个指标（v2.7 含 Price / MD Price）
--                  无 vs LP / vs LY 派生，该组参数不参与计算，仅参数区
--                  留档）
-- This Year:       dt ∈ ['2026-03-29', '2026-07-25']（同上不参与计算）
-- Last Year:       dt ∈ ['2025-03-30', '2025-07-26']（同上不参与计算）
-- end period 最后一天:           '2026-07-25'（This Period 区间最后一天）
--                                  ——库存类指标快照日（快照缺数时 PBI 度量
--                                  回退到 end period 范围内最近一个快照日，
--                                  SQL 对比时如发现快照日无数据需相应调整）
-- end period 所在财月第一天:     '2026-06-28'（MTD SLS Unit 起点
--                                  ['2026-06-28', '2026-07-25']）
-- end period 所在财年第一天:     '2026-03-29'（YTD SLS Unit 起点
--                                  ['2026-03-29', '2026-07-25']——本参数下
--                                  与 This Period 重合，YTD = This Period）
-- 近四周区间（v2.6 废止）:       Weeks Cover 改数仓预计算 weeks_cover 字段直读，
--                                  近四周窗口不再参与计算（v2.5 参数留档废止）
--
-- 口径还原说明:
--   1. 两张 s02 表日期字段为 dt（String 存储，ISO 格式，字符串比较与
--      日期比较等价）；trade 表 net_sales_amt 为 PBI 模型内 Power Query
--      行级列（ROUND(product_qty × sales_price, 6)），数据库无此列，
--      SQL 按行级乘积还原后聚合
--   2. 行主键单列（spu_id / sku_id）：全部指标按主键粒度聚合（跨
--      product_type / special_series / 尺码 / 渠道明细汇总）；值域 =
--      This Period 区间内有记录且主键非空的主键（对齐 PBI 视觉级
--      「主键 不为空」列筛选器；区间外主键 SLS Amt 为 BLANK 排 TopN
--      末尾，不进 Top 100，SQL 值域可不覆盖）
--   3. 属性字段（us_style / ax_class / special_series / spu_img_url /
--      special_supply）："最新值" = This Period 区间内该主键最大 dt 那天的
--      distinct 值顿号拼接（字母序升序；一对一属性自然退化为单值）；空值
--      经 NULLIF(TRIM(x), '') 排除（对齐 DAX FILTER 排空白）；区间内无
--      记录 → 全属性 NULL。Product Type（v2.6）例外：区间内全部 distinct
--      值顿号拼接（独立 C trade_product_type，不 JOIN trade_maxdt）
--   3.5 Price / MD Price（v2.7 新增）：取值规则同属性最新日期值——
--      trade_price C JOIN trade_maxdt 取最新日期当天 MAX(msrp) /
--      MAX(md_price)（数值型防御性 MAX 非拼接，一对一价格属性退化单值；
--      当日全 NULL → NULL；RMB 原始值输出，对齐 PBI Value 层 ÷
--      Currency_ExchangeRate 的换算后口径，RMB 汇率 = 1 时直接对比）
--   4. Product Tag（computed_product_tag，inv 类独有）：SKU 段 = 快照日下该
--      主键全部行的 distinct 值顿号拼接（不套用"最新值"规则——快照日本身
--      即最新），空白值排除；SPU 段（v2.4）= 直取 spu 预聚合表单行值
--   5. Available Sizes：SKU 段 = 快照日下该主键全部尺码 distinct 拼接，仅取
--      inv_qty > 0 的行（口径 §32，不取最新——与属性字段规则区分）；SPU 段
--      （v2.4）= 直读 spu 预聚合表 sku_size 预拼接串（逗号分隔，原样输出）
--   6. Alert 判定（v2.4 业务确认修订）：缺货 = oos_tag = '1'（String）；
--      滞销 = computed_product_tag = 'slow mover'；其他情况 NULL（v2.3
--      '其他'类别废止）；两条件互斥为数据不变量（单行必出且仅出一个状态）；
--      SKU 段（SQL 2/2）单行直判；SPU 段（SQL 1/2）取 v2.4 新增 spu 预聚合
--      表（indep_rl_dw.s02_inventory_stock_sales_detail_result_d 且
--      data_type = 'spu'，快照日每 spu 单行）直判，无最高预警级别聚合；
--      无对应表行 → NULL（对齐 DAX BLANK，PBI 显示 "-"）
--   7. 金额输出 RMB 原始值（PBI Value 层 ÷ Currency_ExchangeRate，RMB
--      汇率 = 1 时直接对比；Display 层拼接币种符号 #,##0）；AUR 同
--   8. MD 空值行为：行级乘积任一字段 NULL 的行不计入分子分母
--      （CASE 拦截对齐 DAX SUMX IF）；分母为 0 或任一侧 NULL → 输出
--      NULL（对齐 DAX 显式拦截，避免 1 - NULL = 1 虚高 100%）
--   9. ST% 跨双口径：销售侧 This Period 区间，库存侧快照日单日——分母加法
--      任一侧 NULL 按 0（对齐 DAX 算术 BLANK 当 0）；销售侧 NULL → 整体
--      NULL（DIVIDE 分子 BLANK）。Weeks Cover（v2.6）：数仓预计算
--      weeks_cover 字段直读——取快照日该主键的值，防御性 MAX（SPU/SKU + day
--      不保证唯一行，单行时 MAX = 行值；SPU 段 inv_agg 整体改 GROUP BY +
--      MAX 对齐 DAX 标量聚合语义）；v2.5 近四周日均分母计算废止；快照日无
--      对应表行 / 字段 NULL → NULL（对齐 DAX BLANK，PBI 显示 "-"）
--  10. Rank = DENSE_RANK() OVER (ORDER BY sls_amt_this DESC, 主键 ASC)
--      ——两键决胜对齐 PBI Rank（金额降序 + 主键字母序，名次唯一，
--      Top 100 恰好 100 行）；ORDER BY + LIMIT 100 对齐 PBI 表格行集与
--      行序（如需对第 100 名边界对数可调大 LIMIT）
--  11. NULL 语义对齐 DAX：分子 NULL → 比率 NULL；MD / AUR 边界拦截；
--      库存类主键无 inv 记录 → NULL（LEFT JOIN）；窗口 DENSE_RANK 中
--      NULL 金额行排末尾（对齐 PBI TopN 降序 BLANK 垫尾，Top 100 内
--      无 NULL 金额行）
-- ======================================================================


-- ======================================================================
-- SQL 1/2: SPU 维度（GROUP BY spu_id；v2.4 inv 类指标取 spu 预聚合表，
--           v2.6 防御性 GROUP BY + MAX（含 weeks_cover 直读）；Alert /
--           Available Sizes / Product Tag 直判直读，无优先级聚合）
-- ======================================================================
WITH
-- ── trade 侧 This Period 区间数据（值域 + 指标聚合 + 属性取值基础）──
trade_base AS (
    SELECT
        spu_id,
        dt,
        product_qty,
        sales_price,
        md_price,
        msrp,
        us_style,
        ax_class,
        product_type,
        special_series,
        spu_img_url,
        special_supply
    FROM indep_rl_dw.s02_trade_sku_data_d
    WHERE spu_id IS NOT NULL AND TRIM(spu_id) <> ''      -- 对齐视觉级「主键 不为空」
      AND dt BETWEEN '2026-03-29' AND '2026-07-25'       -- This Period
),
-- ── 每主键区间内最大 dt（属性"最新日期"判定，非 TimeFrame_Max）──
trade_maxdt AS (
    SELECT spu_id, MAX(dt) AS max_dt
    FROM trade_base
    GROUP BY spu_id
),
-- ── 最新日期当天的 distinct 属性拼接（顿号，字母序升序，空白排除）──
trade_attr AS (
    SELECT
        b.spu_id,
        GROUP_CONCAT(DISTINCT NULLIF(TRIM(b.us_style), '') ORDER BY NULLIF(TRIM(b.us_style), '') SEPARATOR '、')      AS us_style,
        GROUP_CONCAT(DISTINCT NULLIF(TRIM(b.ax_class), '') ORDER BY NULLIF(TRIM(b.ax_class), '') SEPARATOR '、')      AS ax_class,
        GROUP_CONCAT(DISTINCT NULLIF(TRIM(b.special_series), '') ORDER BY NULLIF(TRIM(b.special_series), '') SEPARATOR '、') AS special_series,
        GROUP_CONCAT(DISTINCT NULLIF(TRIM(b.spu_img_url), '') ORDER BY NULLIF(TRIM(b.spu_img_url), '') SEPARATOR '、') AS spu_img_url,
        GROUP_CONCAT(DISTINCT NULLIF(TRIM(b.special_supply), '') ORDER BY NULLIF(TRIM(b.special_supply), '') SEPARATOR '、') AS special_supply
    FROM trade_base b
    JOIN trade_maxdt m
        ON b.spu_id = m.spu_id AND b.dt = m.max_dt
    GROUP BY b.spu_id
),
-- ── Product Type：区间内全部 distinct 值拼接（v2.6，不限定最新日期）──
trade_product_type AS (
    SELECT
        spu_id,
        GROUP_CONCAT(DISTINCT NULLIF(TRIM(product_type), '') ORDER BY NULLIF(TRIM(product_type), '') SEPARATOR '、') AS product_type
    FROM trade_base
    GROUP BY spu_id
),
-- ── Price / MD Price（v2.7）：最新日期当天 msrp / md_price（取值规则同
--    US Style；数值型防御性 MAX，一对一价格属性退化单值；当日全
--    NULL → NULL）──
trade_price AS (
    SELECT
        b.spu_id,
        MAX(b.msrp)     AS price,
        MAX(b.md_price) AS md_price
    FROM trade_base b
    JOIN trade_maxdt m
        ON b.spu_id = m.spu_id AND b.dt = m.max_dt
    GROUP BY b.spu_id
),
-- ── trade 侧指标聚合（主键粒度；net_sales_amt 行级还原）──
trade_agg AS (
    SELECT
        spu_id,
        SUM(ROUND(product_qty * sales_price, 6))                                          AS sls_amt_this,
        SUM(product_qty)                                                                  AS sls_unit_this,
        SUM(CASE WHEN dt BETWEEN '2026-06-28' AND '2026-07-25'
                 THEN product_qty END)                                                    AS mtd_sls_unit,
        SUM(CASE WHEN dt BETWEEN '2026-03-29' AND '2026-07-25'
                 THEN product_qty END)                                                    AS ytd_sls_unit,
        SUM(CASE WHEN product_qty IS NOT NULL AND md_price IS NOT NULL
                 THEN product_qty * md_price END)                                         AS md_amt,
        SUM(CASE WHEN product_qty IS NOT NULL AND msrp IS NOT NULL
                 THEN product_qty * msrp END)                                             AS msrp_amt
    FROM trade_base
    GROUP BY spu_id
),
-- ── inv 侧快照日单日（v2.4：spu 预聚合表；v2.6 防御性 GROUP BY + MAX——
--    SPU/SKU + day 不保证唯一行，单行时 MAX = 行值，对齐 DAX 标量聚合语义；
--    不附加渠道条件——inv 类表无渠道字段）──
inv_agg AS (
    SELECT
        spu_id,
        MAX(stock_inv_qty)                                                                AS eoh_unit,
        MAX(in_trans_inv_qty)                                                             AS in_trans_unit,
        MAX(reph_qty)                                                                     AS reph_count,
        MAX(CASE
            WHEN oos_tag = '1' THEN '缺货'                                                  -- 两条件互斥（数据不变量）
            WHEN computed_product_tag = 'slow mover' THEN '滞销'
            ELSE NULL                                                                     -- 其他情况 BLANK（v2.4）
        END)                                                                              AS alert,
        MAX(sku_size)                                                                     AS available_sizes,   -- 预拼接串（逗号分隔）直读
        MAX(computed_product_tag)                                                         AS product_tag,
        MAX(weeks_cover)                                                                  AS weeks_cover        -- v2.6 数仓预计算字段直读（防御性 MAX）
    FROM indep_rl_dw.s02_inventory_stock_sales_detail_result_d
    WHERE spu_id IS NOT NULL AND TRIM(spu_id) <> ''
      AND data_type = 'spu'                                                               -- spu 预聚合行（对齐 PBI 表 s02_inventory_stock_sales_detail_d_spu）
      AND dt = '2026-07-25'                                                               -- This 期末快照日
    GROUP BY spu_id
)
SELECT
    t.spu_id                                                                              AS SPU_Id,
    a.us_style                                                                            AS US_Style,
    a.ax_class                                                                            AS AX_Class,
    pt.product_type                                                                       AS Product_Type,
    a.special_series                                                                      AS Special_Series,
    a.spu_img_url                                                                         AS SPU_Image,
    a.special_supply                                                                      AS Special_Supply,
    i.product_tag                                                                         AS Product_Tag,
    t.sls_amt_this                                                                        AS SLS_Amt_RMB,
    t.sls_unit_this                                                                       AS SLS_Units,
    i.eoh_unit                                                                            AS EOH_Unit,
    i.in_trans_unit                                                                       AS In_Transit_Unit,
    i.weeks_cover                                                                         AS Weeks_Cover,       -- v2.6 数仓预计算字段直读（快照日防御性 MAX；无 inv 记录 → NULL）
    t.mtd_sls_unit                                                                        AS MTD_SLS_Unit,
    t.ytd_sls_unit                                                                        AS YTD_SLS_Unit,
    CASE
        WHEN t.sls_unit_this IS NULL THEN NULL
        WHEN t.sls_unit_this + COALESCE(i.eoh_unit, 0) = 0 THEN NULL
        ELSE t.sls_unit_this / (t.sls_unit_this + COALESCE(i.eoh_unit, 0))
    END                                                                                   AS ST_Pct,
    CASE
        WHEN t.sls_unit_this IS NULL OR t.sls_unit_this = 0 THEN NULL
        ELSE t.sls_amt_this / t.sls_unit_this
    END                                                                                   AS AUR_RMB,
    CASE
        WHEN t.md_amt IS NULL OR t.msrp_amt IS NULL OR t.msrp_amt = 0 THEN NULL
        ELSE 1 - t.md_amt / t.msrp_amt
    END                                                                                   AS MD_Pct,
    p.price                                                                              AS Price_RMB,       -- v2.7 吊牌价（最新日期当天 MAX(msrp)，RMB 原始值）
    p.md_price                                                                           AS MD_Price_RMB,    -- v2.7 折扣价（最新日期当天 MAX(md_price)，RMB 原始值）
    i.alert                                                                               AS Alert,               -- v2.4 预聚合行直判（其他情况 NULL）
    i.available_sizes                                                                     AS Available_Sizes,
    i.reph_count                                                                          AS Replenishment_Count,
    DENSE_RANK() OVER (ORDER BY t.sls_amt_this DESC, t.spu_id ASC)                        AS Rank
FROM trade_agg t
LEFT JOIN trade_attr a ON a.spu_id = t.spu_id
LEFT JOIN trade_product_type pt ON pt.spu_id = t.spu_id
LEFT JOIN inv_agg   i ON i.spu_id = t.spu_id
LEFT JOIN trade_price p ON p.spu_id = t.spu_id
ORDER BY t.sls_amt_this DESC, t.spu_id ASC
LIMIT 100;


-- ======================================================================
-- SQL 2/2: SKU 维度（GROUP BY sku_id，快照日单行判定——两条件互斥
--          （数据不变量，有多个状态即数据异常），v2.4 其他情况输出
--          NULL；inv 类指标仍取 s02_inventory_stock_sales_detail_d，
--          v2.6 weeks_cover 防御性 MAX 直读）
-- ======================================================================
WITH
trade_base AS (
    SELECT
        sku_id,
        dt,
        product_qty,
        sales_price,
        md_price,
        msrp,
        us_style,
        ax_class,
        product_type,
        special_series,
        spu_img_url,
        special_supply
    FROM indep_rl_dw.s02_trade_sku_data_d
    WHERE sku_id IS NOT NULL AND TRIM(sku_id) <> ''       -- 对齐视觉级「主键 不为空」
      AND dt BETWEEN '2026-03-29' AND '2026-07-25'        -- This Period
),
trade_maxdt AS (
    SELECT sku_id, MAX(dt) AS max_dt
    FROM trade_base
    GROUP BY sku_id
),
trade_attr AS (
    SELECT
        b.sku_id,
        GROUP_CONCAT(DISTINCT NULLIF(TRIM(b.us_style), '') ORDER BY NULLIF(TRIM(b.us_style), '') SEPARATOR '、')      AS us_style,
        GROUP_CONCAT(DISTINCT NULLIF(TRIM(b.ax_class), '') ORDER BY NULLIF(TRIM(b.ax_class), '') SEPARATOR '、')      AS ax_class,
        GROUP_CONCAT(DISTINCT NULLIF(TRIM(b.special_series), '') ORDER BY NULLIF(TRIM(b.special_series), '') SEPARATOR '、') AS special_series,
        GROUP_CONCAT(DISTINCT NULLIF(TRIM(b.spu_img_url), '') ORDER BY NULLIF(TRIM(b.spu_img_url), '') SEPARATOR '、') AS spu_img_url,
        GROUP_CONCAT(DISTINCT NULLIF(TRIM(b.special_supply), '') ORDER BY NULLIF(TRIM(b.special_supply), '') SEPARATOR '、') AS special_supply
    FROM trade_base b
    JOIN trade_maxdt m
        ON b.sku_id = m.sku_id AND b.dt = m.max_dt
    GROUP BY b.sku_id
),
-- ── Product Type：区间内全部 distinct 值拼接（v2.6，不限定最新日期）──
trade_product_type AS (
    SELECT
        sku_id,
        GROUP_CONCAT(DISTINCT NULLIF(TRIM(product_type), '') ORDER BY NULLIF(TRIM(product_type), '') SEPARATOR '、') AS product_type
    FROM trade_base
    GROUP BY sku_id
),
-- ── Price / MD Price（v2.7）：最新日期当天 msrp / md_price（取值规则同
--    US Style；数值型防御性 MAX，一对一价格属性退化单值；当日全
--    NULL → NULL）──
trade_price AS (
    SELECT
        b.sku_id,
        MAX(b.msrp)     AS price,
        MAX(b.md_price) AS md_price
    FROM trade_base b
    JOIN trade_maxdt m
        ON b.sku_id = m.sku_id AND b.dt = m.max_dt
    GROUP BY b.sku_id
),
trade_agg AS (
    SELECT
        sku_id,
        SUM(ROUND(product_qty * sales_price, 6))                                          AS sls_amt_this,
        SUM(product_qty)                                                                  AS sls_unit_this,
        SUM(CASE WHEN dt BETWEEN '2026-06-28' AND '2026-07-25'
                 THEN product_qty END)                                                    AS mtd_sls_unit,
        SUM(CASE WHEN dt BETWEEN '2026-03-29' AND '2026-07-25'
                 THEN product_qty END)                                                    AS ytd_sls_unit,
        SUM(CASE WHEN product_qty IS NOT NULL AND md_price IS NOT NULL
                 THEN product_qty * md_price END)                                         AS md_amt,
        SUM(CASE WHEN product_qty IS NOT NULL AND msrp IS NOT NULL
                 THEN product_qty * msrp END)                                             AS msrp_amt
    FROM trade_base
    GROUP BY sku_id
),
inv_agg AS (
    SELECT
        sku_id,
        SUM(stock_inv_qty)                                                                AS eoh_unit,
        SUM(in_trans_inv_qty)                                                             AS in_trans_unit,
        SUM(reph_qty)                                                                     AS reph_count,
        MAX(CASE WHEN oos_tag = '1' THEN 1 END)                                           AS has_oos,
        MAX(CASE WHEN computed_product_tag = 'slow mover' THEN 1 END)                     AS has_slow,
        COUNT(*)                                                                          AS inv_rows,
        GROUP_CONCAT(DISTINCT CASE WHEN inv_qty > 0 THEN sku_size END
                 ORDER BY CASE WHEN inv_qty > 0 THEN sku_size END SEPARATOR '、')         AS available_sizes,
        GROUP_CONCAT(DISTINCT NULLIF(TRIM(computed_product_tag), '')
                 ORDER BY NULLIF(TRIM(computed_product_tag), '') SEPARATOR '、')          AS product_tag,
        MAX(weeks_cover)                                                                  AS weeks_cover        -- v2.6 数仓预计算字段直读（防御性 MAX）
    FROM indep_rl_dw.s02_inventory_stock_sales_detail_d
    WHERE sku_id IS NOT NULL AND TRIM(sku_id) <> ''
      AND dt = '2026-07-25'                                                               -- This 期末快照日
    GROUP BY sku_id
)
SELECT
    t.sku_id                                                                              AS SKU_Id,
    a.us_style                                                                            AS US_Style,
    a.ax_class                                                                            AS AX_Class,
    pt.product_type                                                                       AS Product_Type,
    a.special_series                                                                      AS Special_Series,
    a.spu_img_url                                                                         AS SPU_Image,
    a.special_supply                                                                      AS Special_Supply,
    i.product_tag                                                                         AS Product_Tag,
    t.sls_amt_this                                                                        AS SLS_Amt_RMB,
    t.sls_unit_this                                                                       AS SLS_Units,
    i.eoh_unit                                                                            AS EOH_Unit,
    i.in_trans_unit                                                                       AS In_Transit_Unit,
    i.weeks_cover                                                                         AS Weeks_Cover,       -- v2.6 数仓预计算字段直读（快照日防御性 MAX；无 inv 记录 → NULL）
    t.mtd_sls_unit                                                                        AS MTD_SLS_Unit,
    t.ytd_sls_unit                                                                        AS YTD_SLS_Unit,
    CASE
        WHEN t.sls_unit_this IS NULL THEN NULL
        WHEN t.sls_unit_this + COALESCE(i.eoh_unit, 0) = 0 THEN NULL
        ELSE t.sls_unit_this / (t.sls_unit_this + COALESCE(i.eoh_unit, 0))
    END                                                                                   AS ST_Pct,
    CASE
        WHEN t.sls_unit_this IS NULL OR t.sls_unit_this = 0 THEN NULL
        ELSE t.sls_amt_this / t.sls_unit_this
    END                                                                                   AS AUR_RMB,
    CASE
        WHEN t.md_amt IS NULL OR t.msrp_amt IS NULL OR t.msrp_amt = 0 THEN NULL
        ELSE 1 - t.md_amt / t.msrp_amt
    END                                                                                   AS MD_Pct,
    p.price                                                                              AS Price_RMB,       -- v2.7 吊牌价（最新日期当天 MAX(msrp)，RMB 原始值）
    p.md_price                                                                           AS MD_Price_RMB,    -- v2.7 折扣价（最新日期当天 MAX(md_price)，RMB 原始值）
    CASE
        WHEN i.inv_rows IS NULL THEN NULL                                                 -- 快照日无 inv 记录
        WHEN i.has_oos = 1 THEN '缺货'                                                     -- 单行互斥（数据不变量），条件顺序无优先级语义
        WHEN i.has_slow = 1 THEN '滞销'
        ELSE NULL                                                                         -- 其他情况 BLANK（v2.4）
    END                                                                                   AS Alert,
    i.available_sizes                                                                     AS Available_Sizes,
    i.reph_count                                                                          AS Replenishment_Count,
    DENSE_RANK() OVER (ORDER BY t.sls_amt_this DESC, t.sku_id ASC)                        AS Rank
FROM trade_agg t
LEFT JOIN trade_attr a ON a.sku_id = t.sku_id
LEFT JOIN trade_product_type pt ON pt.sku_id = t.sku_id
LEFT JOIN inv_agg   i ON i.sku_id = t.sku_id
LEFT JOIN trade_price p ON p.sku_id = t.sku_id
ORDER BY t.sls_amt_this DESC, t.sku_id ASC
LIMIT 100;
