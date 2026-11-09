-- 用途：保留六种维度排列，全局基础排序按维度类型乘固定倍数；不计算 Cost MOB% Total 或其动态排名。
-- 本文件仅包含一条只读查询，不新增持久化库、表或函数；下面的说明与验证示例均为注释。
--
-- 兼容目标基线（语法设计范围，未在四库实测，不表示最低支持版本）：
-- Hive 3.1+、Spark SQL 3.5+、ClickHouse 24.8+、Doris 2.1+。
-- 使用非递归 CTE、UNION ALL、等值 JOIN、CASE、DISTINCT、DENSE_RANK / ROW_NUMBER、TRIM / LOWER / HEX。
-- 排名先 CAST AS BIGINT 再乘 10，避免 Spark 原生 INT 乘法溢出及 ClickHouse UInt64 类型差异。
-- ClickHouse 的 BIGINT 是 Int64 别名；连接器中仍须确认排序列导入为 Power BI 整数。
-- Hive 必须启用反引号标识符支持（hive.support.quoted.identifiers=column）。
-- Hive 若启用严格的无限制 ORDER BY 检查，末尾全局 ORDER BY 可能被拒绝；
-- 可由管理员允许无限制排序（相关配置 hive.mapred.mode、hive.strict.checks.orderby.no.limit），
-- 或仅移除末尾 ORDER BY ID_Sort，保留窗口中的 ORDER BY；不影响 Power BI 按列排序，不要用 LIMIT 截断数据。
-- Power BI 连接器须支持此 CTE 原生查询；包装原生 SQL 不兼容时使用 Import 模式，必要时去掉末尾分号。
-- 数据库/表名需在目标引擎存在；输入维度为文本类型，NULL、排序规则及连接器类型需在实际环境验证。
-- 字符升序定义为 LOWER(TRIM(...)) 后的字典序；四库一致性以英文 ASCII 与二进制排序规则为基线。
-- 非英文大小写折叠、重音/宽度等价、非普通空格与模型排序规则须另行统一，不能视作四库天然一致。
-- 参考：https://hive.apache.org/docs/latest/language/languagemanual-sortby/
-- 参考：https://clickhouse.com/docs/sql-reference/data-types/int-uint
--
-- 字段契约与排序口径：
-- Scenario_Type / Scenario_Sort 保留六场景与编号 1..6；Total 固定为 'Total'。
-- Level 1 / Level 2 / Level 3 保留原字段名、原始标签、原有组合，供现有 DAX 取数/筛选使用。
-- L1_Type / L2_Type / L3_Type 取值为 Brand / Category / Framework。
-- 非 Other 项：L1_Sort / L2_Sort / L3_Sort = 对应维度的全局基础排序 * 类型倍数，不按场景或父节点重新编号。
-- Other 特例：LOWER(TRIM(标签))='other' 时，所有维度、场景、层级的最终排序值统一为 99999999，不再乘倍数。
-- 此特例覆盖 Other 原有的字符位置及 Framework 优先级位置；其余标签基础排名和倍数保持不变。
-- 99999999 是指定的固定编号，不保证在任意数据规模下始终最大。
-- 类型倍数固定为 Brand=1、Framework=100、Category=100000；三个层级分别根据各自的 Lx_Type 应用。
-- 倍数跟随维度类型，不跟随层级位置：Framework 位于任意层均乘 100，Category 位于任意层均乘 100000。
-- 例如 M polo 在所有层级均为 10，Foundation 均为 1000；Category 基础排序 10 对应 1000000（Other 除外）。
-- 以下为乘倍数之前的基础排序：
-- Brand：M polo=10、W polo=20、Lauren=30、RRL=40、CW=50、CL=60、PL=70、HM=80。
-- Framework：Foundation=10、acceleration=20、complementary=30、other=40；other 的基础位置保留，最终值由特例覆盖。
-- 新增 Brand / Framework 分别从 90 / 50 起按字符升序编号；已知值不占用新增值的排名。
-- Category 在全体有效类别中按字符升序编号为 10、20、30……；父节点缺少某类别时允许跳号。
-- 上述规则对三个层级完全一致，特别是第三层的 Brand / Framework 也应用固定优先级。
-- 任一维度为 NULL 的组合仍整体排除；空串与普通空格串保留、归为同一排序项，基础排名在本维度非空值之后。
-- 最终排序中 Other 特例优先，因此不再保证空串一定排在 Other 之后。
-- 大小写及普通首尾空格变体共用规范化键与排序值；不再用原始 HEX 为这些变体分配不同业务排名。
-- 每个“维度类型 + 规范化标签”只保留一个基础排序；不新增替代显示列，不修改原 Level 1/2/3 文本。
-- 全局字典按整个查询数据集生成；新增值可能使后续序号变化，因此本表应全量刷新，不宜对排名做增量分区刷新。
--
-- Power BI：矩阵行继续使用 Total、Level 1、Level 2、Level 3，页面 Scenario_Type 单选。
-- Scenario_Type 可按 Scenario_Sort 排序；Total 只有一个值，无须额外排序列。
-- 目标绑定：Level 1 -> L1_Sort、Level 2 -> L2_Sort、Level 3 -> L3_Sort；排序列设置为整数。
-- 绑定前须检查整张模型表中每个原始显示值只对应一个排序值，按 Power BI 的文本等价规则检查。
-- 类型倍数保证同一维度的同一规范化标签在所有层级、所有场景的排序值一致，不保证跨维度同名文本一致。
-- Other 已跨维度统一为 99999999；以后若新增其他跨维度同名文本仍须检查，Scenario_Type 单选不会取消模型级校验。
-- 不同标签共用一个排序数字不构成校验错误；固定倍数也不是永久互不重叠的号段，新增值不设置数量上限。
-- 校验通过后，视觉对象选择类别升序，不要继续按 Cost MOB% 或其他度量值排序。
-- 本次只修改 SQL，不自动修改既有 DAX、矩阵或 Power BI 模型属性；最终 ORDER BY 不会设置模型排序。
-- ID_Sort 保留第七列位置，为完整静态顺序的 ROW_NUMBER * 10；仅供调试，不是稳定业务键或按列排序列。
--
-- 验收示例：场景 1/3 的第三层 Foundation 在 acceleration 前；场景 4/6 的第三层 M polo 在 HM 前。
-- 验收示例：M polo 下 Alpha/Beta、W polo 下 Beta，同维度 Category 的 Beta 在所有层级与父节点拥有同一排序值。
-- 验收示例：同维度的 Alpha Brand / alpha brand / ' Alpha Brand ' 共用排名，原始标签保留；空标签基础排名后置。
-- 验收示例：Other / OTHER / ' Other ' 无论属于哪个维度、位于哪个层级，最终排序值均为 99999999。
-- 验收方法：除检查单场景顺序外，还应对全表原 Level n 分组检查 COUNT(DISTINCT Ln_Sort)；大于 1 即不能按列排序。
-- 验收方法：保持原有效组合数 * 6 行，验证平台过滤、NULL 排除、六种排列和已知/新增/空值次序。
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
