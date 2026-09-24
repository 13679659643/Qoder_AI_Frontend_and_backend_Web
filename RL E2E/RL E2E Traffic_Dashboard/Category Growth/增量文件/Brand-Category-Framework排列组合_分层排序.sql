-- 用途：六种维度排列的分层静态排序；不计算 Cost MOB% Total 或其动态排名。
-- 目标数据库引擎及版本尚未确认；使用 MySQL 8 / Doris 常见的 CTE、窗口函数方言。
-- ROW_NUMBER / DENSE_RANK 返回 BIGINT，乘整数 10 生成 BIGINT 排序值。
-- 不使用 MySQL 8 不支持的 CAST AS BIGINT；实际连接器类型与执行计划需在目标环境核验。
-- 无新增库、表或函数依赖；本文件仅包含一条只读查询，所有说明和示例均为注释。
--
-- 字段契约：
-- Scenario_Type 与 Scenario_Sort：保留原六场景和编号；兼容例外为编号仍是 1..6，不乘 10。
-- Total 固定为 'Total'；Level 1 / Level 2 / Level 3 原字段名、原标签及层级含义不变。
-- L1_Type / L2_Type / L3_Type：对应层实际维度类型，取值为 Brand / Category / Framework。
-- L1_Sort：当前场景第一层排序；L2_Sort：当前场景、第一层父节点内的第二层排序。
-- Brand 固定规则：M Polo=10、W Polo=20、Lauren=30、RRL=40、CW=50、CL=60、PL=70、HM=80。
-- Framework 固定规则：Foundation=10、Acceleration=20、Complementary=30、Other=40。
-- Category：当前父节点内按标签英文字母升序连续排名，取 10、20、30……。
-- 未知 Brand / Framework：分别从 90 / 50 开始，按名称升序连续编号；空串排在非空值之后。
-- 上述 80 / 40 是已知规则最大值而非哨兵上限；窗口排名不限制未知值或空串的数量。
-- L3_Sort：当前场景、第一层及第二层父节点内，仅按第三层标签字母升序排名并乘 10。
-- 第三层即使是 Brand / Framework 也不套固定规则；仅供 DAX 在当前父节点内打破指标同值或空值并列。
-- 不对 Cost MOB% Total 做预计算、不规定指标空值主排序、不替代随筛选上下文变化的 DAX 排名。
-- 同一场景、父节点、当前标签的序号不随其后代组合变化；不同父节点的序号允许重复。
-- 固定规则匹配使用 LOWER(TRIM(...))；大小写或首尾空格变体保留原标签，但命中同一固定编号。
-- 字母排序使用 LOWER(TRIM(...))；匹配后相同时用原标签 HEX 值打破并列，避免依赖固定哨兵。
-- 空字符串及仅含普通空格的标签原样保留、排序放末；应在源数据治理，不自动转换为 Other。
-- 原始去重仍沿用源字段的数据库排序规则；非英文字符顺序及大小写等价关系需核验目标排序规则。
-- L1_Sort / L2_Sort 不能直接作为 Level 标签的 Power BI Sort-by-Column：跨场景、维度或父节点映射不唯一。
-- ID_Sort：按完整静态顺序产生的 ROW_NUMBER * 10，仅供调试；增删数据后可能变化。
-- ID_Sort 不是稳定业务键，不得用于模型关系或按列排序，也不是任何业务指标的排名。
--
-- 注释示例：未知品牌 Alpha Brand 在 L1/L2 排在 HM 之后；空品牌排在所有非空品牌之后。
-- 注释示例：Framework 作为 L3 时，Acceleration 在 Foundation 之前，与 L1/L2 固定规则不同。
WITH
-- 保留原 Base：仅 JD、TM 平台，并对原始 framework、brand、category 组合去重。
Base_Data AS (
    SELECT DISTINCT
        framework,
        brand,
        category
    FROM `indep_rl_ads`.a05_e2e_paid_media_summary_d
    WHERE platform IN ('JD', 'TM')
),
-- 任一维度为 NULL 的组合在六场景中都会被排除；提前过滤与原最终过滤的保留行语义一致。
-- 只排除 SQL NULL，不排除空字符串，不进行 COALESCE / NULLIF / Other 替换。
Valid_Data AS (
    SELECT framework, brand, category
    FROM Base_Data
    WHERE framework IS NOT NULL
        AND brand IS NOT NULL
        AND category IS NOT NULL
),
Unioned_Data AS (
    -- 场景 1：Brand / Category / Framework。
    SELECT
        'Brand->Category->Framework' AS Scenario_Type,
        1 AS Scenario_Sort,
        'Total' AS `Total`,
        brand AS `Level 1`,
        category AS `Level 2`,
        framework AS `Level 3`,
        'Brand' AS L1_Type,
        'Category' AS L2_Type,
        'Framework' AS L3_Type
    FROM Valid_Data
    UNION ALL
    -- 场景 2：Brand / Framework / Category。
    SELECT
        'Brand->Framework->Category' AS Scenario_Type,
        2 AS Scenario_Sort,
        'Total' AS `Total`,
        brand AS `Level 1`,
        framework AS `Level 2`,
        category AS `Level 3`,
        'Brand' AS L1_Type,
        'Framework' AS L2_Type,
        'Category' AS L3_Type
    FROM Valid_Data
    UNION ALL
    -- 场景 3：Category / Brand / Framework。
    SELECT
        'Category->Brand->Framework' AS Scenario_Type,
        3 AS Scenario_Sort,
        'Total' AS `Total`,
        category AS `Level 1`,
        brand AS `Level 2`,
        framework AS `Level 3`,
        'Category' AS L1_Type,
        'Brand' AS L2_Type,
        'Framework' AS L3_Type
    FROM Valid_Data
    UNION ALL
    -- 场景 4：Category / Framework / Brand。
    SELECT
        'Category->Framework->Brand' AS Scenario_Type,
        4 AS Scenario_Sort,
        'Total' AS `Total`,
        category AS `Level 1`,
        framework AS `Level 2`,
        brand AS `Level 3`,
        'Category' AS L1_Type,
        'Framework' AS L2_Type,
        'Brand' AS L3_Type
    FROM Valid_Data
    UNION ALL
    -- 场景 5：Framework / Brand / Category。
    SELECT
        'Framework->Brand->Category' AS Scenario_Type,
        5 AS Scenario_Sort,
        'Total' AS `Total`,
        framework AS `Level 1`,
        brand AS `Level 2`,
        category AS `Level 3`,
        'Framework' AS L1_Type,
        'Brand' AS L2_Type,
        'Category' AS L3_Type
    FROM Valid_Data
    UNION ALL
    -- 场景 6：Framework / Category / Brand。
    SELECT
        'Framework->Category->Brand' AS Scenario_Type,
        6 AS Scenario_Sort,
        'Total' AS `Total`,
        framework AS `Level 1`,
        category AS `Level 2`,
        brand AS `Level 3`,
        'Framework' AS L1_Type,
        'Category' AS L2_Type,
        'Brand' AS L3_Type
    FROM Valid_Data
),
-- 只计算排序辅助值，不修改展示标签；Category、未知值和空串返回 NULL，交由窗口排序。
Fixed_Data AS (
    SELECT
        u.*,
        CASE L1_Type
            WHEN 'Brand' THEN
                CASE LOWER(TRIM(`Level 1`))
                    WHEN 'm polo' THEN 10
                    WHEN 'w polo' THEN 20
                    WHEN 'lauren' THEN 30
                    WHEN 'rrl' THEN 40
                    WHEN 'cw' THEN 50
                    WHEN 'cl' THEN 60
                    WHEN 'pl' THEN 70
                    WHEN 'hm' THEN 80
                END
            WHEN 'Framework' THEN
                CASE LOWER(TRIM(`Level 1`))
                    WHEN 'foundation' THEN 10
                    WHEN 'acceleration' THEN 20
                    WHEN 'complementary' THEN 30
                    WHEN 'other' THEN 40
                END
        END AS L1_Fixed_Sort,
        CASE L2_Type
            WHEN 'Brand' THEN
                CASE LOWER(TRIM(`Level 2`))
                    WHEN 'm polo' THEN 10
                    WHEN 'w polo' THEN 20
                    WHEN 'lauren' THEN 30
                    WHEN 'rrl' THEN 40
                    WHEN 'cw' THEN 50
                    WHEN 'cl' THEN 60
                    WHEN 'pl' THEN 70
                    WHEN 'hm' THEN 80
                END
            WHEN 'Framework' THEN
                CASE LOWER(TRIM(`Level 2`))
                    WHEN 'foundation' THEN 10
                    WHEN 'acceleration' THEN 20
                    WHEN 'complementary' THEN 30
                    WHEN 'other' THEN 40
                END
        END AS L2_Fixed_Sort
    FROM Unioned_Data u
),
Ranked_Data AS (
    SELECT
        f.*,
        CASE
            WHEN L1_Fixed_Sort IS NOT NULL THEN L1_Fixed_Sort
            ELSE
                CASE L1_Type WHEN 'Brand' THEN 80 WHEN 'Framework' THEN 40 ELSE 0 END
                + DENSE_RANK() OVER (
                    -- 已知值单独分区，不占用未知值及空串的连续排名。
                    PARTITION BY Scenario_Sort,
                        CASE WHEN L1_Fixed_Sort IS NULL THEN 0 ELSE 1 END
                    ORDER BY
                        CASE WHEN LOWER(TRIM(`Level 1`)) = '' THEN 1 ELSE 0 END,
                        LOWER(TRIM(`Level 1`)),
                        HEX(`Level 1`)
                ) * 10
        END AS L1_Sort,
        CASE
            WHEN L2_Fixed_Sort IS NOT NULL THEN L2_Fixed_Sort
            ELSE
                CASE L2_Type WHEN 'Brand' THEN 80 WHEN 'Framework' THEN 40 ELSE 0 END
                + DENSE_RANK() OVER (
                    -- 原父标签及其 HEX 共同分区，避免大小写或空格不同的父标签混排。
                    PARTITION BY Scenario_Sort, `Level 1`, HEX(`Level 1`),
                        CASE WHEN L2_Fixed_Sort IS NULL THEN 0 ELSE 1 END
                    ORDER BY
                        CASE WHEN LOWER(TRIM(`Level 2`)) = '' THEN 1 ELSE 0 END,
                        LOWER(TRIM(`Level 2`)),
                        HEX(`Level 2`)
                ) * 10
        END AS L2_Sort,
        -- DENSE_RANK 保证相同父节点、相同标签只有一个序号，不受后代重复行影响。
        DENSE_RANK() OVER (
            PARTITION BY Scenario_Sort, `Level 1`, HEX(`Level 1`), `Level 2`, HEX(`Level 2`)
            ORDER BY
                CASE WHEN LOWER(TRIM(`Level 3`)) = '' THEN 1 ELSE 0 END,
                LOWER(TRIM(`Level 3`)),
                HEX(`Level 3`)
        ) * 10 AS L3_Sort
    FROM Fixed_Data f
)
SELECT
    Scenario_Type,
    Scenario_Sort,
    `Total`,
    `Level 1`,
    `Level 2`,
    `Level 3`,
    -- 保留原第七列 ID_Sort；后续新增字段，便于原接口按字段名读取。
    -- 先按层级序号，再按原标签打破并列；HEX 补足不区分大小写排序规则下的标签并列。
    ROW_NUMBER() OVER (
        ORDER BY Scenario_Sort, L1_Sort, L2_Sort, L3_Sort,
            `Level 1`, HEX(`Level 1`), `Level 2`, HEX(`Level 2`), `Level 3`, HEX(`Level 3`)
    ) * 10 AS ID_Sort,
    L1_Sort,
    L2_Sort,
    L3_Sort,
    L1_Type,
    L2_Type,
    L3_Type
FROM Ranked_Data
-- ID_Sort 与上述完整静态顺序一致；不是报表中动态指标的排序依据。
ORDER BY ID_Sort;
