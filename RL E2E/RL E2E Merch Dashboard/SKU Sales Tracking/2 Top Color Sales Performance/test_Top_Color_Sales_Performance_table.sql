-- ======================================================================
-- 测试 SQL: Top Color Sales Performance 表格（Sales Top10 + Inventory Top10）
-- 所属模块: RL E2E Merch Dashboard - SKU Sales Tracking - Top Color Sales Performance
-- 关联方案: Top_Color_Sales_Performance_table.md
-- 语法: MySQL 8.0+（CTE / 窗口函数 / 用户变量；低于 8.0 不支持）
-- 用途: 验证 Power BI 两个表格视觉对象的数值口径
--       Sales: SLS Amt / SLS Amt% / SLS Unit / SLS Unit%
--       Inventory: EOH Amt / EOH Amt% / EOH Unit / EOH Unit%
--
-- ★参数区★（修改 @division 后需重新执行 SET 语句及全部两段；单独执行任一段前需先执行 SET）
-- Division:              'WM'（单选，可选 WM / CW / HM / MN，每次只选一个值）
-- Platform:              'ALL'（全选，等价不筛选，SQL 中不附加条件）
-- Store Name:            'ALL'（全选，等价不筛选，SQL 中不附加条件）
-- Sales This Period:     dt ∈ ['2026-03-29', '2026-09-26']（区间汇总）
-- Inventory This 时点:   dt = '2026-07-25'（This Period 最后一天，单日快照）
--
-- 口径还原说明:
--   1. 两表实际日期字段为 dt（非 data_date），已按数据字典核对
--   2. net_sales_amt 为 Power Query 取数新增列（数据库不存在），按行级
--      ROUND(product_qty × sales_price, 6) 等价还原后再聚合
--   3. Top10 排名 = 金额降序 + color_name 字母序升序决胜（DENSE_RANK
--      双列 ORDER BY），名次严格连续唯一（1,2,3,4），对应 DAX
--      RANK(DENSE, ..., ORDERBY(金额 DESC, color_name ASC))；
--      排名候选排除 NULL / 空字符 / 纯空格 color_name（对应 DAX
--      LEN(TRIM()) > 0），并排除聚合金额为 NULL 的 color（对应当期
--      无有效金额时 DAX Rank 返回 BLANK 被筛选器排除）
--   4. 排名 <= 10 的行返回——(金额, color_name) 元组唯一时名次即
--      行位置，恰好 10 行、Top10 边界确定，对应视觉级筛选器
--      「Rank 介于 1 与 10」语义
--   5. 占比（Amt% / Unit%）分母 = 全量 color 汇总（含 Top10 之外的
--      color，含 NULL / 空字符 color_name 的金额与数量，不加 color
--      过滤），对应 DAX REMOVEFILTERS(color_name)；Top10 行占比加总
--      < 100%
--   6. SLS Unit% 分母 = SUM(product_qty)：口径文档原文 sum(sales_qty)
--      字段在 s02_trade_sku_data_d 数据字典与取数 SQL 中均不存在，
--      经业务确认修正为 product_qty（与分子同字段，全部 color 占比
--      加总 = 100%，2026-10-15 确认）
--   7. SLS Amt / EOH Amt 输出 RMB 原始值（不含币种换算）：币种换算在
--      PBI Value 层完成（原始值 ÷ 汇率），SQL 侧验证原始口径
--   8. EOH 系列取期末单日时点（dt = '2026-07-25'）；快照缺数回退在
--      DAX 层实现（end period 范围内最后一个有数据快照日），SQL 按
--      口径定义的 end period 最后一天验证
--   9. inv 表无 platform / shop_name 字段，Inventory 段仅 date +
--      Division 筛选（渠道筛选不影响库存侧指标）
-- 10. 行序 = 排名升序（= 金额降序 + color_name 字母序决胜，对应
--      PBI 侧按 Color Rank 升序排序）
-- ======================================================================

SET @division := 'WM';

-- ======================================================================
-- SQL 1/2: Sales Top10（color 维度排名）
-- ======================================================================
WITH row_agg AS (
    SELECT
        color_name,
        SUM(ROUND(product_qty * sales_price, 6))    AS color_net_sales_amt,
        SUM(product_qty)                            AS color_product_qty
    FROM indep_rl_dw.s02_trade_sku_data_d
    WHERE dt >= '2026-03-29'
      AND dt <= '2026-09-26'
      AND division = @division
    GROUP BY color_name                                   -- NULL color_name 归为一组，进入分母汇总
),
color_rank AS (
    SELECT
        color_name,
        color_net_sales_amt,
        color_product_qty,
        DENSE_RANK() OVER (ORDER BY color_net_sales_amt DESC, color_name ASC)    AS color_rank_no
    FROM row_agg
    WHERE color_name IS NOT NULL                          -- 排名候选排除空白/空字符（对应 DAX LEN(TRIM()) > 0）
      AND TRIM(color_name) <> ''
      AND color_net_sales_amt IS NOT NULL                 -- 当期无有效金额不参与排名（对应 DAX Rank 返回 BLANK）
),
total AS (
    SELECT
        SUM(color_net_sales_amt)                          AS total_net_sales_amt,
        SUM(color_product_qty)                            AS total_product_qty
    FROM row_agg                                          -- 全量 color 汇总（含 Top10 之外与空白 color，对应 REMOVEFILTERS(color_name)）
)
SELECT
    cr.color_rank_no                                      AS Color_Rank,
    cr.color_name                                         AS Color_Name,
    cr.color_net_sales_amt                                AS SLS_Amt_Value_RMB,
    cr.color_net_sales_amt  / NULLIF(t.total_net_sales_amt, 0)    AS SLS_Amt_Pct,
    cr.color_product_qty                                  AS SLS_Unit_Value,
    cr.color_product_qty    / NULLIF(t.total_product_qty, 0)      AS SLS_Unit_Pct
FROM color_rank cr
CROSS JOIN total t
WHERE cr.color_rank_no <= 10                              -- Top10 行（名次唯一，恰好 10 行，与 PBI 筛选器语义一致）
ORDER BY
    cr.color_rank_no ASC;                                 -- 行序对应 PBI 侧 Color Rank 升序（金额降序 + 名称决胜）

-- ======================================================================
-- SQL 2/2: Inventory Top10（color 维度排名，期末单日时点）
-- ======================================================================
WITH row_agg AS (
    SELECT
        color_name,
        SUM(msrp_inv_amt)                                 AS color_eoh_amt,
        SUM(stock_inv_qty)                                AS color_stock_qty
    FROM indep_rl_dw.s02_inventory_stock_sales_detail_d
    WHERE dt = '2026-07-25'
      AND division = @division
    GROUP BY color_name                                   -- NULL color_name 归为一组，进入分母汇总
),
color_rank AS (
    SELECT
        color_name,
        color_eoh_amt,
        color_stock_qty,
        DENSE_RANK() OVER (ORDER BY color_eoh_amt DESC, color_name ASC)           AS color_rank_no
    FROM row_agg
    WHERE color_name IS NOT NULL                          -- 排名候选排除空白/空字符（对应 DAX LEN(TRIM()) > 0）
      AND TRIM(color_name) <> ''
      AND color_eoh_amt IS NOT NULL                       -- 快照日无有效库存金额不参与排名（对应 DAX Rank 返回 BLANK）
),
total AS (
    SELECT
        SUM(color_eoh_amt)                                AS total_eoh_amt,
        SUM(color_stock_qty)                              AS total_stock_qty
    FROM row_agg                                          -- 全量 color 汇总（含 Top10 之外与空白 color，对应 REMOVEFILTERS(color_name)）
)
SELECT
    cr.color_rank_no                                      AS Color_Rank,
    cr.color_name                                         AS Color_Name,
    cr.color_eoh_amt                                      AS EOH_Amt_Value_RMB,
    cr.color_eoh_amt        / NULLIF(t.total_eoh_amt, 0)         AS EOH_Amt_Pct,
    cr.color_stock_qty                                    AS EOH_Unit_Value,
    cr.color_stock_qty      / NULLIF(t.total_stock_qty, 0)       AS EOH_Unit_Pct
FROM color_rank cr
CROSS JOIN total t
WHERE cr.color_rank_no <= 10                              -- Top10 行（名次唯一，恰好 10 行，与 PBI 筛选器语义一致）
ORDER BY
    cr.color_rank_no ASC;                                 -- 行序对应 PBI 侧 Color Rank 升序（金额降序 + 名称决胜）
