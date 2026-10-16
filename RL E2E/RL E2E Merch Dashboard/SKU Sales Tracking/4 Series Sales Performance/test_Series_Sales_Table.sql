-- ======================================================================
-- 测试 SQL: Series Sales Performance 表格（明细行 + series 汇总行）
-- 所属模块: RL E2E Merch Dashboard - SKU Sales Tracking - Series Sales Performance
-- 关联方案: Series_Sales_Table.md
-- 语法: MySQL 8.0+（CTE / 窗口函数）
-- 结构: SQL 1/2 明细行（三元组粒度）+ SQL 2/2 series 汇总行，两段独立执行
--
-- ★参数区★（当前为字面量直嵌，修改参数时对两段全文替换对应日期 / 维度值）
-- Division:              'CW' / 'HM' / 'MN' / 'WM' 四值全选（对应切片器全选，
--                        等价不筛选；如需单选，将 division IN (...) 替换为
--                        division = 'WM'）
-- Sales This Period:     dt ∈ ['2026-03-29', '2026-07-25']（区间汇总）
-- End Period 期末时点:   dt = '2026-07-25'（this period 最后一天，模型窗口内
--                        最后一个有数据快照日，对应 DAX 快照回退取值）
-- YTD 财年第一天:        '2026-03-29'（FY27 财年第一天 = TimeFrame_Min，
--                        本参数下 YTD 区间与 This Period 重合）
-- Platform / Store Name / 其余商品维度: 全选（等价不筛选；如需单项筛选，
--                        在两段 WHERE 中按需附加条件，trade 侧与 inv 侧
--                        已建关系的字段才会同时影响两侧）
--
-- 口径还原说明:
--   1. 两表实际日期字段为 dt（非 data_date），已按数据字典核对
--   2. net_sales_amt 为 Power Query 取数新增列（数据库不存在），按行级
--      ROUND(product_qty × sales_price, 6) 等价还原后再聚合
--   3. 行结构 = special_series > spu_id > spu_img_url 三元组（spu_img_url 为
--      PBI 行区域第三层图片列，正常与 spu_id 一对一）：SQL 1/2 输出明细行
--      （Row 粒度 = 三元组），SQL 2/2 输出 series 汇总行（对应 PBI 行小计）；
--      一对多异常时同一 spu 按 url 拆多行，销售类指标按 (spu, url) 记录
--      归属拆分，库存按 spu_id 精确匹配（url 行显示该 spu 全部库存）
--   4. 特殊限制：仅统计 special_series 有值的商品（含全部指标及占比分母）——
--      两段 trade 侧 WHERE 均过滤空白 series；销售占比分母在全量有效 series
--      上汇总（对应 DAX REMOVEFILTERS(三列，含 spu_img_url 行筛选) + series
--      非空还原）；库存占比分母加 inv 侧 series 非空过滤
--   5. 两张事实表间无模型关系：明细行库存按 spu_id 精确匹配（对应 DAX
--      TREATAS(VALUES(trade[spu_id]), inv[spu_id])）；series 汇总行库存按
--      special_series 值匹配（对应 TREATAS(VALUES(trade[special_series]),
--      inv[special_series])，覆盖该 series 全部库存，含 trade 侧无销售
--      记录的 spu，不受渠道筛选影响——inv 表无 platform / shop_name 字段）
--   6. EOH / ST% 库存加项取期末单日时点（dt = '2026-07-25'）；ST% 库存字段
--      为 inv_qty（≠ EOH Unit 的 stock_inv_qty），按口径文档分别使用
--   7. 空值行为对齐 DAX：分子为 NULL 时占比 / AUR / MD / ST% 整体输出
--      NULL（对应 DAX DIVIDE 分子 BLANK → BLANK，显示 "-"）；ST% 分母的
--      加法对 NULL 侧按 0 处理（对应 DAX 算术运算 BLANK 当 0：销售侧有值
--      + 库存侧空 → 分母 = 销售侧值）；MD 在分子分母任一为 NULL 时输出
--      NULL（对应 DAX IF 显式拦截）
--   8. SLS Amt / EOH Amt / AUR 输出 RMB 原始值（不含币种换算）：币种换算
--      在 PBI Value 层完成（原始值 ÷ 汇率），SQL 侧验证原始口径
--   9. Sort Key = Series_Rank × 1,000,000 + Spu_Rank：Series_Rank = series
--      粒度当期净销售金额降序 + special_series 升序决胜（明细行与汇总行
--      同 series 共享名次）；Spu_Rank = series 内 spu 粒度当期净销售金额
--      降序 + spu_id 升序决胜（L2 排名依据为 spu 粒度金额（跨 url 上卷，
--      对应 DAX 候选金额 REMOVEFILTERS(spu_img_url) 上卷），一对多异常时
--      同一 spu 的多个 url 行共享同一 Spu_Rank）；series 汇总行（SQL 2/2）
--      Spu_Rank 编码 999,999 = 组内最后；当期无金额行（明细行看 (spu, url)
--      三元组粒度金额、汇总行看 series 粒度金额）Sort_Key = 1,000,000,000,000
--      垫底——对应 DAX RANK(DENSE, ..., ORDERBY(金额 DESC, 维度值 ASC))
--      编码（双列 ORDER BY 元组唯一时名次唯一）
-- 10. 模型加载窗口对齐：两段 SQL 附加与 Power Query 取数相同的窗口条件
--      （trade: 2026-03-29 ~ 2026-09-26 ∪ 2025-03-30 ~ 2025-09-27；
--      inv: 2026-03-29 ~ 2026-07-25 ∪ 2025-03-30 ~ 2025-07-26），YTD /
--      LTD 的模型值受窗口截断（实际统计 = 窗口 ∩ 口径区间）；删除两段
--      的窗口条件即为全量口径（开店以来 / 财年第一天起）
-- 11. 行序 = Sort_Key 升序（series 金额降序分组 → series 内 AXC 金额降序，
--      汇总行组内最后，对应 PBI 侧按 Sort Key 列升序排序）
-- ======================================================================

-- ======================================================================
-- SQL 1/2: 明细行（(special_series, spu_id, spu_img_url) 三元组粒度，
--          库存按 spu_id 精确匹配）
-- ======================================================================
WITH
-- ── trade 侧 (special_series, spu_id, spu_img_url) 三元组粒度各期聚合（series 非空）──
-- 条件聚合还原各时间口径：This Period / YTD / LTD；NULL 传播对应 DAX SUM 空值；
-- spu_img_url 进入分组（对应 PBI 行区域第三层图片列，一对多异常时按 url 拆行）
trade_agg AS (
    SELECT
        special_series,
        spu_id,
        spu_img_url,
        SUM(CASE WHEN dt >= '2026-03-29' AND dt <= '2026-07-25'
                 THEN ROUND(product_qty * sales_price, 6) END)                       AS spu_sls_amt,
        SUM(CASE WHEN dt >= '2026-03-29' AND dt <= '2026-07-25'
                 THEN product_qty END)                                               AS spu_sls_unit,
        SUM(CASE WHEN dt >= '2026-03-29' AND dt <= '2026-07-25'
                 THEN product_qty END)                                               AS spu_ytd_qty,
        SUM(CASE WHEN dt >= '2026-03-29' AND dt <= '2026-07-25'
                 THEN ROUND(product_qty * sales_price, 6) END)                       AS spu_ytd_amt,
        SUM(CASE WHEN dt <= '2026-07-25'
                 THEN product_qty END)                                               AS spu_ltd_qty,
        SUM(CASE WHEN dt >= '2026-03-29' AND dt <= '2026-07-25'
                 THEN product_qty * md_price END)                                    AS spu_md_amt,
        SUM(CASE WHEN dt >= '2026-03-29' AND dt <= '2026-07-25'
                 THEN product_qty * msrp END)                                        AS spu_msrp_amt
    FROM indep_rl_dw.s02_trade_sku_data_d
    WHERE special_series IS NOT NULL                    -- 仅统计 special_series 有值的商品（对应视觉级筛选器 + DAX 内部条件）
      AND TRIM(special_series) <> ''
      AND division IN ('CW', 'HM', 'MN', 'WM')         -- Division 切片器四值全选（等价不筛选）
      AND ((dt >= '2026-03-29' AND dt <= '2026-09-26') OR (dt >= '2025-03-30' AND dt <= '2025-09-27'))   -- 模型加载窗口（去窗口即全量 LTD / YTD 口径）
    GROUP BY special_series, spu_id, spu_img_url
),

-- ── trade 侧 (special_series, spu_id) 粒度当期金额（L2 排名依据，跨 url 上卷）──
-- 对应 DAX Sort Key L2 候选金额 REMOVEFILTERS(spu_img_url) 上卷到 spu 粒度
trade_spu AS (
    SELECT
        special_series,
        spu_id,
        SUM(spu_sls_amt)    AS spu_rank_amt
    FROM trade_agg
    GROUP BY special_series, spu_id
),

-- ── trade 侧 series 粒度汇总（L1 排名依据）──
trade_series AS (
    SELECT
        special_series,
        SUM(spu_sls_amt)    AS series_sls_amt
    FROM trade_agg
    GROUP BY special_series
),

-- ── inv 侧 spu 粒度期末聚合（明细行库存数据源，spu_id 精确匹配）──
-- GROUP BY spu_id（不带 series）：对齐 DAX TREATAS 按 spu_id 精确传递
inv_spu AS (
    SELECT
        spu_id,
        SUM(CASE WHEN dt = '2026-07-25' THEN msrp_inv_amt END)                       AS spu_eoh_amt,
        SUM(CASE WHEN dt = '2026-07-25' THEN stock_inv_qty END)                      AS spu_eoh_unit,
        SUM(CASE WHEN dt = '2026-07-25' THEN inv_qty END)                            AS spu_end_inv_qty
    FROM indep_rl_dw.s02_inventory_stock_sales_detail_d
    WHERE division IN ('CW', 'HM', 'MN', 'WM')          -- inv 无渠道字段，仅 Division 等已建关系维度影响库存侧
      AND ((dt >= '2026-03-29' AND dt <= '2026-07-25') OR (dt >= '2025-03-30' AND dt <= '2025-07-26'))   -- 模型加载窗口
    GROUP BY spu_id
),

-- ── 占比分母：全量有效 series（trade This Period；inv 期末时点）──
-- 对应 DAX 销售侧 REMOVEFILTERS(三列，含 spu_img_url 行筛选) + series 非空 / 库存侧显式 series 非空
sales_total AS (
    SELECT
        SUM(spu_sls_amt)    AS total_sls_amt,
        SUM(spu_sls_unit)   AS total_sls_unit
    FROM trade_agg
),
inv_total AS (
    SELECT
        SUM(CASE WHEN dt = '2026-07-25' THEN msrp_inv_amt END)                     AS total_eoh_amt,
        SUM(CASE WHEN dt = '2026-07-25' THEN stock_inv_qty END)                    AS total_eoh_unit
    FROM indep_rl_dw.s02_inventory_stock_sales_detail_d
    WHERE special_series IS NOT NULL                -- 库存占比分母仅统计 special_series 有值的商品
      AND TRIM(special_series) <> ''
      AND division IN ('CW', 'HM', 'MN', 'WM')
      AND ((dt >= '2026-03-29' AND dt <= '2026-07-25') OR (dt >= '2025-03-30' AND dt <= '2025-07-26'))   -- 模型加载窗口
),

-- ── 明细行（三元组粒度，库存按 spu_id 匹配）──
detail_rows AS (
    SELECT
        t.special_series                                     AS series,
        t.spu_id                                             AS axc,
        t.spu_img_url                                        AS image_url,
        t.spu_sls_amt                                        AS sls_amt_rmb,
        t.spu_sls_amt / NULLIF(st.total_sls_amt, 0)          AS sls_amt_pct,
        t.spu_sls_unit                                       AS sls_unit,
        t.spu_sls_unit / NULLIF(st.total_sls_unit, 0)        AS sls_unit_pct,
        i.spu_eoh_amt                                        AS eoh_amt_rmb,
        i.spu_eoh_amt / NULLIF(it.total_eoh_amt, 0)          AS eoh_amt_pct,
        i.spu_eoh_unit                                       AS eoh_unit,
        i.spu_eoh_unit / NULLIF(it.total_eoh_unit, 0)        AS eoh_unit_pct,
        t.spu_sls_amt / NULLIF(t.spu_sls_unit, 0)            AS aur_rmb,
        1 - t.spu_md_amt / NULLIF(t.spu_msrp_amt, 0)          AS md_pct,
        t.spu_ytd_qty                                        AS ytd_sls_unit,
        t.spu_ytd_qty
            / NULLIF(COALESCE(t.spu_ytd_qty, 0) + COALESCE(i.spu_end_inv_qty, 0), 0)     AS ytd_st_unit_pct,
        t.spu_ytd_amt
            / NULLIF(COALESCE(t.spu_ytd_amt, 0) + COALESCE(i.spu_eoh_amt, 0), 0)         AS ytd_st_amt_pct,
        t.spu_ltd_qty                                        AS ltd_sls_unit,
        t.spu_ltd_qty
            / NULLIF(COALESCE(t.spu_ltd_qty, 0) + COALESCE(i.spu_end_inv_qty, 0), 0)     AS ltd_st_unit_pct,
        ts.series_sls_amt                                    AS series_amt,   -- L1 排名依据（series 粒度）
        t.spu_sls_amt                                        AS spu_amt,      -- 当期无金额垫底判定（三元组行粒度，对应 DAX __CurrentAmt）
        tp.spu_rank_amt                                      AS spu_rank_amt  -- L2 排名依据（spu 粒度，跨 url 上卷）
    FROM trade_agg t
    LEFT JOIN inv_spu i
        ON t.spu_id = i.spu_id
    LEFT JOIN trade_series ts
        ON t.special_series = ts.special_series
    LEFT JOIN trade_spu tp
        ON t.special_series = tp.special_series
        AND t.spu_id = tp.spu_id
    CROSS JOIN sales_total st
    CROSS JOIN inv_total it
)

SELECT
    series                                               AS Series,
    axc                                                  AS AXC,
    image_url                                            AS Image_URL,
    sls_amt_rmb                                          AS SLS_Amt_RMB,
    sls_amt_pct                                          AS SLS_Amt_Pct,
    sls_unit                                             AS SLS_Unit,
    sls_unit_pct                                         AS SLS_Unit_Pct,
    eoh_amt_rmb                                          AS EOH_Amt_RMB,
    eoh_amt_pct                                          AS EOH_Amt_Pct,
    eoh_unit                                             AS EOH_Unit,
    eoh_unit_pct                                         AS EOH_Unit_Pct,
    aur_rmb                                              AS AUR_RMB,
    md_pct                                               AS MD_Pct,
    ytd_sls_unit                                         AS YTD_SLS_Unit,
    ytd_st_unit_pct                                      AS YTD_ST_Unit_Pct,
    ytd_st_amt_pct                                       AS YTD_ST_Amt_Pct,
    ltd_sls_unit                                         AS LTD_SLS_Unit,
    ltd_st_unit_pct                                      AS LTD_ST_Unit_Pct,
    -- L1 series 排名：series 粒度当期金额降序 + special_series 升序决胜
    -- （无金额 series 排最后但被垫底值覆盖，不影响有效 series 名次，
    --   对应 DAX relation 排除无金额候选）
    DENSE_RANK() OVER (ORDER BY series_amt DESC, series ASC)                AS Series_Rank,
    -- L2 series 内 spu 排名：spu 粒度当期金额降序 + spu_id 升序决胜
    -- （排名依据 spu_rank_amt = spu 粒度金额（跨 url 上卷，对应 DAX L2 候选
    --   REMOVEFILTERS(spu_img_url)）；无金额 spu 排最后不占有效名次；
    --   一对多异常时同一 spu 的多个 url 行共享名次）
    DENSE_RANK() OVER (
        PARTITION BY series
        ORDER BY spu_rank_amt DESC, axc ASC
    )                                                    AS Spu_Rank,
    -- Sort Key：Series_Rank × 1,000,000 + Spu_Rank；当期无金额行垫底
    -- （垫底判定看 (spu, url) 三元组粒度金额（spu_amt），对应 DAX __CurrentAmt）
    CASE
        WHEN spu_amt IS NULL
            THEN 1000000000000
        ELSE DENSE_RANK() OVER (ORDER BY series_amt DESC, series ASC) * 1000000
             + DENSE_RANK() OVER (
                   PARTITION BY series
                   ORDER BY spu_rank_amt DESC, axc ASC
               )
    END                                                  AS Sort_Key
FROM detail_rows
ORDER BY
    Sort_Key ASC,
    series ASC,
    axc ASC;                                             -- 行序对应 PBI 侧 Sort Key 升序（垫底行内按 series / AXC 决胜）

-- ======================================================================
-- SQL 2/2: series 汇总行（仅 special_series 维度，special_series 不为空，
--          库存按 special_series 值匹配，对应 PBI 行小计）
-- ======================================================================
WITH
-- ── trade 侧 series 粒度各期聚合（series 非空）──
trade_series AS (
    SELECT
        special_series,
        SUM(CASE WHEN dt >= '2026-03-29' AND dt <= '2026-07-25'
                 THEN ROUND(product_qty * sales_price, 6) END)                       AS series_sls_amt,
        SUM(CASE WHEN dt >= '2026-03-29' AND dt <= '2026-07-25'
                 THEN product_qty END)                                               AS series_sls_unit,
        SUM(CASE WHEN dt >= '2026-03-29' AND dt <= '2026-07-25'
                 THEN product_qty END)                                               AS series_ytd_qty,
        SUM(CASE WHEN dt >= '2026-03-29' AND dt <= '2026-07-25'
                 THEN ROUND(product_qty * sales_price, 6) END)                       AS series_ytd_amt,
        SUM(CASE WHEN dt <= '2026-07-25'
                 THEN product_qty END)                                               AS series_ltd_qty,
        SUM(CASE WHEN dt >= '2026-03-29' AND dt <= '2026-07-25'
                 THEN product_qty * md_price END)                                    AS series_md_amt,
        SUM(CASE WHEN dt >= '2026-03-29' AND dt <= '2026-07-25'
                 THEN product_qty * msrp END)                                        AS series_msrp_amt
    FROM indep_rl_dw.s02_trade_sku_data_d
    WHERE special_series IS NOT NULL                    -- 仅统计 special_series 有值的商品
      AND TRIM(special_series) <> ''
      AND division IN ('CW', 'HM', 'MN', 'WM')         -- Division 切片器四值全选（等价不筛选）
      AND ((dt >= '2026-03-29' AND dt <= '2026-09-26') OR (dt >= '2025-03-30' AND dt <= '2025-09-27'))   -- 模型加载窗口（去窗口即全量 LTD / YTD 口径）
    GROUP BY special_series
),

-- ── inv 侧 series 粒度期末聚合（series 值匹配：覆盖该 series 全部库存，
--    含 trade 侧无销售记录的 spu；inv 表无渠道字段）──
inv_series AS (
    SELECT
        special_series,
        SUM(CASE WHEN dt = '2026-07-25' THEN msrp_inv_amt END)                       AS series_eoh_amt,
        SUM(CASE WHEN dt = '2026-07-25' THEN stock_inv_qty END)                      AS series_eoh_unit,
        SUM(CASE WHEN dt = '2026-07-25' THEN inv_qty END)                            AS series_end_inv_qty
    FROM indep_rl_dw.s02_inventory_stock_sales_detail_d
    WHERE special_series IS NOT NULL                    -- series 值匹配语义：空白 series 不属于任何有效 series 汇总
      AND TRIM(special_series) <> ''
      AND division IN ('CW', 'HM', 'MN', 'WM')
      AND ((dt >= '2026-03-29' AND dt <= '2026-07-25') OR (dt >= '2025-03-30' AND dt <= '2025-07-26'))   -- 模型加载窗口
    GROUP BY special_series
),

-- ── 占比分母：全量有效 series（trade This Period；inv 期末时点）──
-- 对应 DAX 销售侧 REMOVEFILTERS(三列) + series 非空 / 库存侧显式 series 非空
sales_total AS (
    SELECT
        SUM(series_sls_amt)    AS total_sls_amt,
        SUM(series_sls_unit)   AS total_sls_unit
    FROM trade_series
),
inv_total AS (
    SELECT
        SUM(series_eoh_amt)    AS total_eoh_amt,
        SUM(series_eoh_unit)   AS total_eoh_unit
    FROM inv_series
)

SELECT
    ts.special_series                                    AS Series,
    ts.series_sls_amt                                    AS SLS_Amt_RMB,
    ts.series_sls_amt / NULLIF(st.total_sls_amt, 0)      AS SLS_Amt_Pct,
    ts.series_sls_unit                                   AS SLS_Unit,
    ts.series_sls_unit / NULLIF(st.total_sls_unit, 0)    AS SLS_Unit_Pct,
    i.series_eoh_amt                                     AS EOH_Amt_RMB,
    i.series_eoh_amt / NULLIF(it.total_eoh_amt, 0)       AS EOH_Amt_Pct,
    i.series_eoh_unit                                    AS EOH_Unit,
    i.series_eoh_unit / NULLIF(it.total_eoh_unit, 0)     AS EOH_Unit_Pct,
    ts.series_sls_amt / NULLIF(ts.series_sls_unit, 0)    AS AUR_RMB,
    1 - ts.series_md_amt / NULLIF(ts.series_msrp_amt, 0)  AS MD_Pct,
    ts.series_ytd_qty                                    AS YTD_SLS_Unit,
    ts.series_ytd_qty
        / NULLIF(COALESCE(ts.series_ytd_qty, 0) + COALESCE(i.series_end_inv_qty, 0), 0)     AS YTD_ST_Unit_Pct,
    ts.series_ytd_amt
        / NULLIF(COALESCE(ts.series_ytd_amt, 0) + COALESCE(i.series_eoh_amt, 0), 0)         AS YTD_ST_Amt_Pct,
    ts.series_ltd_qty                                    AS LTD_SLS_Unit,
    ts.series_ltd_qty
        / NULLIF(COALESCE(ts.series_ltd_qty, 0) + COALESCE(i.series_end_inv_qty, 0), 0)     AS LTD_ST_Unit_Pct,
    -- L1 series 排名：series 粒度当期金额降序 + special_series 升序决胜
    DENSE_RANK() OVER (ORDER BY ts.series_sls_amt DESC, ts.special_series ASC)          AS Series_Rank,
    -- series 汇总行 Spu_Rank 编码 999,999 = 组内最后（对应 DAX Sort Key 汇总行分支）
    999999                                               AS Spu_Rank,
    -- Sort Key：Series_Rank × 1,000,000 + 999,999；当期无金额 series 垫底
    -- （垫底判定看 series 粒度金额，对应 DAX __CurrentAmt 汇总行粒度）
    CASE
        WHEN ts.series_sls_amt IS NULL
            THEN 1000000000000
        ELSE DENSE_RANK() OVER (ORDER BY ts.series_sls_amt DESC, ts.special_series ASC) * 1000000
             + 999999
    END                                                  AS Sort_Key
FROM trade_series ts
LEFT JOIN inv_series i
    ON ts.special_series = i.special_series
CROSS JOIN sales_total st
CROSS JOIN inv_total it
ORDER BY
    Sort_Key ASC,
    Series ASC;                                          -- 行序对应 PBI 侧 Sort Key 升序（垫底行内按 series 决胜）
