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
-- 任一维度为 NULL 的组合在六场景中都会被排除；
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
-- 三个维度的全量字典来自同一 Valid_Data，不随场景、父节点或后代数量变化。
Dimension_Labels AS (
    SELECT 'Brand' AS Dim_Type, LOWER(TRIM(brand)) AS Sort_Key
    FROM Valid_Data
    UNION ALL
    SELECT 'Category' AS Dim_Type, LOWER(TRIM(category)) AS Sort_Key
    FROM Valid_Data
    UNION ALL
    SELECT 'Framework' AS Dim_Type, LOWER(TRIM(framework)) AS Sort_Key
    FROM Valid_Data
),
Dimension_Values AS (
    -- 同维度、同一规范化键只保留一行，避免连接放大，不改变原始展示标签。
    SELECT DISTINCT Dim_Type, Sort_Key
    FROM Dimension_Labels
),
Dimension_Fixed AS (
    SELECT
        d.*,
        CASE Dim_Type
            WHEN 'Brand' THEN
                CASE Sort_Key
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
                CASE Sort_Key
                    WHEN 'foundation' THEN 10
                    WHEN 'acceleration' THEN 20
                    WHEN 'complementary' THEN 30
                    WHEN 'other' THEN 40
                END
        END AS Fixed_Sort
    FROM Dimension_Values d
),
Dimension_Sort_Map AS (
    SELECT
        Dim_Type,
        Sort_Key,
        CAST(CASE
            WHEN Fixed_Sort IS NOT NULL THEN Fixed_Sort
            ELSE
                CASE Dim_Type WHEN 'Brand' THEN 80 WHEN 'Framework' THEN 40 ELSE 0 END
                + CAST(DENSE_RANK() OVER (
                    -- 固定项单独分区，不占新增项排名；这里没有场景或父节点分区。
                    PARTITION BY Dim_Type, CASE WHEN Fixed_Sort IS NULL THEN 0 ELSE 1 END
                    ORDER BY CASE WHEN Sort_Key = '' THEN 1 ELSE 0 END, Sort_Key
                ) AS BIGINT) * 10
        END AS BIGINT) AS Global_Sort
    FROM Dimension_Fixed
),
Ranked_Data AS (
    SELECT
        u.*,
        -- Sort_Key 已经 LOWER/TRIM；Other 在乘倍数之外统一覆盖，避免跨维度产生不同编号。
        CASE
            WHEN d1.Sort_Key = 'other' THEN CAST(99999999 AS BIGINT)
            ELSE d1.Global_Sort * CASE u.L1_Type
                WHEN 'Brand' THEN 1
                WHEN 'Framework' THEN 100
                WHEN 'Category' THEN 100000
            END
        END AS L1_Sort,
        CASE
            WHEN d2.Sort_Key = 'other' THEN CAST(99999999 AS BIGINT)
            ELSE d2.Global_Sort * CASE u.L2_Type
                WHEN 'Brand' THEN 1
                WHEN 'Framework' THEN 100
                WHEN 'Category' THEN 100000
            END
        END AS L2_Sort,
        CASE
            WHEN d3.Sort_Key = 'other' THEN CAST(99999999 AS BIGINT)
            ELSE d3.Global_Sort * CASE u.L3_Type
                WHEN 'Brand' THEN 1
                WHEN 'Framework' THEN 100
                WHEN 'Category' THEN 100000
            END
        END AS L3_Sort
    FROM Unioned_Data u
    INNER JOIN Dimension_Sort_Map d1
        ON u.L1_Type = d1.Dim_Type AND LOWER(TRIM(u.`Level 1`)) = d1.Sort_Key
    INNER JOIN Dimension_Sort_Map d2
        ON u.L2_Type = d2.Dim_Type AND LOWER(TRIM(u.`Level 2`)) = d2.Sort_Key
    INNER JOIN Dimension_Sort_Map d3
        ON u.L3_Type = d3.Dim_Type AND LOWER(TRIM(u.`Level 3`)) = d3.Sort_Key
)
SELECT
    Scenario_Type,
    Scenario_Sort,
    `Total`,
    `Level 1`,
    `Level 2`,
    `Level 3`,
    -- 保留原第七列 ID_Sort；先排父层及其原标签，再排子层，保证原始父节点连续输出。
    -- HEX 仅用于调试行顺序的并列处理，不参与显示值的全局业务排名。
    CAST(ROW_NUMBER() OVER (
        ORDER BY Scenario_Sort,
            L1_Sort, `Level 1`, HEX(`Level 1`),
            L2_Sort, `Level 2`, HEX(`Level 2`),
            L3_Sort, `Level 3`, HEX(`Level 3`)
    ) AS BIGINT) * 10 AS ID_Sort,
    L1_Sort,
    L2_Sort,
    L3_Sort,
    L1_Type,
    L2_Type,
    L3_Type
FROM Ranked_Data
-- ID_Sort 与上述完整静态顺序一致；不是报表中动态指标的排序依据。
ORDER BY ID_Sort;
