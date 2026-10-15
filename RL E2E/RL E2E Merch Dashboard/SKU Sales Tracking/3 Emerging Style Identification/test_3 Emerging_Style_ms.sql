-- ======================================================================
-- 测试 SQL: Emerging Style Identification 矩阵（Sales + Inventory）
-- 所属模块: RL E2E Merch Dashboard - SKU Sales Tracking - Emerging Style Identification
-- 关联方案: 3 Emerging_Style_ms.md（v2.0 行列维度表化）
-- 语法: MySQL 8.0+（CTE / 窗口函数 / 用户变量；低于 8.0 不支持）
-- 用途: 验证 Power BI 两个热力矩阵视觉对象的数值口径
--       Sales: SLS Amt%（该 color + size 占该 color，size 限维度表值）
--       Inventory: EOH Amt%（该 color + size 占该 color，期末时点，size 限维度表值）
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
--   3. 占比口径限定维度表值范围：行列维度表（Dim_xxx_color_name /
--      Dim_xxx_sku_size）为 distinct + 非空白过滤单列表——分子分母
--      均仅统计非空白 color_name 与非空白 sku_size 的记录（WHERE 过滤
--      color_name / sku_size 非空白，对应 DAX 行列显式等值桥接 +
--      分母 TREATAS(ALLSELECTED(列维度表))），矩阵同一 color 行的
--      全部 size 列占比相加 = 100%
--   4. 占比分母 = 该 color 层级全 size 汇总（限非空白）：SUM(...) OVER
--      (PARTITION BY color_name) 窗口在 GROUP BY (color_name, sku_size)
--      分组结果上按 color 汇总，对应 DAX 分母的行桥接保留 + size 限定
--   5. 组合在对应期间无记录时 GROUP BY 不产生行，对应 DAX SUM 空集返回
--      BLANK → 单元格空（SVG 灰色占位或行列抑制）
--   6. 分母为空 / 0 → 占比 NULL（对应 DAX DIVIDE 返回 BLANK）
--   7. inv 表无 platform / shop_name 字段，Inventory 段仅 date +
--      Division 筛选（渠道筛选不影响库存侧指标）
--   8. EOH 系列取期末单日时点（dt = '2026-07-25'）；快照缺数回退在
--      DAX 层实现（end period 范围内最后一个有数据快照日），SQL 按
--      口径定义的 end period 最后一天验证
--   9. 行序 = color_name、sku_size 字典序（对应矩阵默认行列顺序）
-- 10. 验证整行加总：按 color_name 分组对 SLS_Amt_Pct / EOH_Amt_Pct
--     求和应 = 1（100%，分母限定非空白 size 与分子范围一致）
-- ======================================================================

SET @division := 'WM';

-- ======================================================================
-- SQL 1/2: Sales 矩阵（color × size 组合占比，分母 = 该 color 层级，限非空白）
-- ======================================================================
WITH cell AS (
    SELECT
        color_name,
        sku_size,
        SUM(ROUND(product_qty * sales_price, 6))                                      AS cell_net_sales_amt,
        SUM(SUM(ROUND(product_qty * sales_price, 6))) OVER (PARTITION BY color_name)  AS color_net_sales_amt
    FROM indep_rl_dw.s02_trade_sku_data_d
    WHERE dt >= '2026-03-29'
      AND dt <= '2026-09-26'
      AND division = @division
      AND color_name IS NOT NULL                          -- 维度表非空白限定（Dim_Sales_color_name）
      AND TRIM(color_name) <> ''
      AND sku_size IS NOT NULL                            -- 维度表非空白限定（Dim_Sales_sku_size）
      AND TRIM(sku_size) <> ''
    GROUP BY color_name, sku_size
)
SELECT
    color_name                                             AS Color_Name,
    sku_size                                               AS Sku_Size,
    cell_net_sales_amt                                     AS Cell_Amt_RMB,
    cell_net_sales_amt / NULLIF(color_net_sales_amt, 0)    AS SLS_Amt_Pct
FROM cell
ORDER BY
    color_name ASC,
    sku_size ASC;

-- ======================================================================
-- SQL 2/2: Inventory 矩阵（color × size 组合占比，分母 = 该 color 层级，期末单日时点，限非空白）
-- ======================================================================
WITH cell AS (
    SELECT
        color_name,
        sku_size,
        SUM(msrp_inv_amt)                                              AS cell_eoh_amt,
        SUM(SUM(msrp_inv_amt)) OVER (PARTITION BY color_name)          AS color_eoh_amt
    FROM indep_rl_dw.s02_inventory_stock_sales_detail_d
    WHERE dt = '2026-07-25'
      AND division = @division
      AND color_name IS NOT NULL                          -- 维度表非空白限定（Dim_Inventory_color_name）
      AND TRIM(color_name) <> ''
      AND sku_size IS NOT NULL                            -- 维度表非空白限定（Dim_Inventory_sku_size）
      AND TRIM(sku_size) <> ''
    GROUP BY color_name, sku_size
)
SELECT
    color_name                                             AS Color_Name,
    sku_size                                               AS Sku_Size,
    cell_eoh_amt                                           AS Cell_Amt_RMB,
    cell_eoh_amt / NULLIF(color_eoh_amt, 0)                AS EOH_Amt_Pct
FROM cell
ORDER BY
    color_name ASC,
    sku_size ASC;
