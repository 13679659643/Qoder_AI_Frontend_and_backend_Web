
# 5. 版本 C — Apache Doris 3.x（MySQL ODBC 协议）

Doris 的分隔符位于第二个参数，不能写 MySQL 的 `SEPARATOR`。先在 scope_first 去重，避免依赖 `DISTINCT + ORDER BY` 组合的版本差异。此段不适用于真正的 MySQL 5.7，也不将所有 MySQL 协议数据库视为 Doris。

```sql
WITH channel_source AS (
    SELECT d.platform, d.channel, d.channel_type,
        CASE
            WHEN d.platform = 'TM' AND d.channel_type = 'RTB' THEN
                CASE d.channel
                    WHEN '直通车' THEN 1 WHEN '引力魔方' THEN 2
                    WHEN '全站推/万相台' THEN 3 WHEN '超级短视频' THEN 4
                    WHEN '超级直播' THEN 5 WHEN '店铺直达' THEN 6 ELSE 0
                END
            WHEN d.platform = 'JD' AND d.channel_type = 'RTB' THEN
                CASE d.channel
                    WHEN '快车' THEN 1 WHEN '触点' THEN 2 WHEN '海投' THEN 3
                    WHEN '直投' THEN 4 WHEN '全站智能推广' THEN 5
                    WHEN '智能化' THEN 6 WHEN '新品推广' THEN 7
                    WHEN '短视频' THEN 8 WHEN '全站营销' THEN 9 ELSE 0
                END
            ELSE 0
        END AS RTB_Order
    FROM (
        SELECT DISTINCT platform, channel, channel_type
        FROM `indep_rl_ads`.a05_e2e_paid_media_channel_data_d
        WHERE platform IN ('JD', 'TM')
            AND channel_type IS NOT NULL AND channel_type != ''
            AND channel_type IN ('JCGP', 'RTB', '品销宝', 'Brandzone', 'Branzone')
    ) d
),
rtb_offset AS (
    SELECT platform,
        SUM(CASE WHEN channel_type = 'RTB' AND RTB_Order = 0 THEN 1 ELSE 0 END) * 10 AS RTB_Offset
    FROM channel_source
    GROUP BY platform
),
detail_data AS (
    SELECT d.platform AS Platform,
        CASE d.platform WHEN 'TM' THEN 1 WHEN 'JD' THEN 2 END AS Platform_Sort,
        d.channel AS Channel,
        CASE
            WHEN d.channel_type = 'RTB' THEN
                CASE WHEN d.RTB_Order > 0 THEN d.RTB_Order * 10
                    ELSE 500 + (ROW_NUMBER() OVER (
                        PARTITION BY d.platform, d.channel_type, d.RTB_Order
                        ORDER BY CASE WHEN d.channel IS NULL THEN 1 ELSE 0 END, d.channel
                    ) - 1) * 10
                END
            WHEN d.platform = 'TM' AND d.channel_type = '品销宝' THEN
                510 + (ROW_NUMBER() OVER (
                    PARTITION BY d.platform, d.channel_type
                    ORDER BY CASE WHEN d.channel IS NULL THEN 1 ELSE 0 END, d.channel
                ) - 1) * 10
            WHEN d.platform = 'TM' AND d.channel_type = 'JCGP' THEN
                1010 + (ROW_NUMBER() OVER (
                    PARTITION BY d.platform, d.channel_type
                    ORDER BY CASE WHEN d.channel IS NULL THEN 1 ELSE 0 END, d.channel
                ) - 1) * 10
            WHEN d.platform = 'JD' AND d.channel_type IN ('Brandzone', 'Branzone') THEN
                510 + (ROW_NUMBER() OVER (
                    PARTITION BY d.platform, d.channel_type
                    ORDER BY CASE WHEN d.channel IS NULL THEN 1 ELSE 0 END, d.channel
                ) - 1) * 10
            WHEN d.platform = 'JD' AND d.channel_type = 'JCGP' THEN
                1010 + (ROW_NUMBER() OVER (
                    PARTITION BY d.platform, d.channel_type
                    ORDER BY CASE WHEN d.channel IS NULL THEN 1 ELSE 0 END, d.channel
                ) - 1) * 10
            ELSE 99999
        END AS Channel_Sort,
        d.channel AS Channel_Label,
        NULL AS Channel_Description,
        'DETAIL' AS Channel_Type,
        CONCAT(d.platform, '_', d.channel) AS Channel_ID,
        CONCAT(d.platform, '_', d.channel) AS Summary_Scope,
        CASE
            WHEN d.platform = 'TM' AND d.channel_type = 'RTB' THEN 'TM_RTB Total'
            WHEN d.platform = 'TM' AND d.channel_type = '品销宝' THEN 'TM_品销宝 Total'
            WHEN d.platform = 'TM' AND d.channel_type = 'JCGP' THEN 'TM_JCGP Total'
            WHEN d.platform = 'JD' AND d.channel_type = 'RTB' THEN 'JD_RTB Total'
            WHEN d.platform = 'JD' AND d.channel_type IN ('Brandzone', 'Branzone') THEN 'JD_Brandzone'
            WHEN d.platform = 'JD' AND d.channel_type = 'JCGP' THEN 'JD_JCGP Total'
            ELSE 'UNKNOWN'
        END AS Parent_Channel_ID
    FROM channel_source d
),
detail_sorted AS (
    SELECT d.Platform, d.Platform_Sort, d.Channel,
        CASE WHEN d.Parent_Channel_ID IN ('TM_RTB Total', 'JD_RTB Total') THEN d.Channel_Sort
            ELSE d.Channel_Sort + COALESCE(o.RTB_Offset, 0)
        END AS Channel_Sort,
        d.Channel_Label, d.Channel_Description, d.Channel_Type,
        d.Channel_ID, d.Summary_Scope, d.Parent_Channel_ID
    FROM detail_data d
    LEFT JOIN rtb_offset o ON d.Platform = o.platform
),
scope_members AS (
    SELECT 'TM_RTB Total' AS Scope_ID, Channel_ID, Channel_Sort
    FROM detail_sorted WHERE Platform = 'TM' AND Parent_Channel_ID = 'TM_RTB Total'
    UNION ALL
    SELECT 'TM_品销宝 Total', Channel_ID, Channel_Sort
    FROM detail_sorted WHERE Platform = 'TM' AND Parent_Channel_ID = 'TM_品销宝 Total'
    UNION ALL
    SELECT 'TM_JCGP Total', Channel_ID, Channel_Sort
    FROM detail_sorted WHERE Platform = 'TM' AND Parent_Channel_ID IN ('TM_JCGP Total')
    UNION ALL
    SELECT 'TM_Total', Channel_ID, Channel_Sort FROM detail_sorted WHERE Platform = 'TM'
    UNION ALL
    SELECT 'TM_Total 不含JCGP', Channel_ID, Channel_Sort
    FROM detail_sorted WHERE Platform = 'TM' AND Parent_Channel_ID NOT IN ('TM_JCGP Total')
    UNION ALL
    SELECT 'JD_RTB Total', Channel_ID, Channel_Sort
    FROM detail_sorted WHERE Platform = 'JD' AND Parent_Channel_ID = 'JD_RTB Total'
    UNION ALL
    SELECT 'JD_RTB Total + 京选店铺', Channel_ID, Channel_Sort
    FROM detail_sorted
    WHERE (Platform = 'JD' AND Parent_Channel_ID IN ('JD_RTB Total')) OR Channel_ID = 'JD_京选店铺'
    UNION ALL
    SELECT 'JD_Brandzone', Channel_ID, Channel_Sort
    FROM detail_sorted WHERE Platform = 'JD' AND Parent_Channel_ID = 'JD_Brandzone'
    UNION ALL
    SELECT 'JD_JCGP Total', Channel_ID, Channel_Sort
    FROM detail_sorted WHERE Platform = 'JD' AND Parent_Channel_ID = 'JD_JCGP Total'
    UNION ALL
    SELECT 'JD_Total', Channel_ID, Channel_Sort FROM detail_sorted WHERE Platform = 'JD'
    UNION ALL
    SELECT 'JD_Total 不含JCGP', Channel_ID, Channel_Sort
    FROM detail_sorted WHERE Platform = 'JD' AND Parent_Channel_ID NOT IN ('JD_JCGP Total', 'UNKNOWN')
),
scope_first AS (
    SELECT Scope_ID, Channel_ID, MIN(Channel_Sort) AS First_Sort
    FROM scope_members
    GROUP BY Scope_ID, Channel_ID
),
dynamic_scope AS (
    SELECT Scope_ID AS Channel_ID,
        GROUP_CONCAT(Channel_ID, '|' ORDER BY First_Sort, Channel_ID) AS Summary_Scope
    FROM scope_first
    GROUP BY Scope_ID
),
summary_base AS (
    SELECT 'TM' AS Platform, 1 AS Platform_Sort, 'RTB Total' AS Channel, 500 AS Channel_Sort, 'RTB Total' AS Channel_Label,
        'TM平台-RTB合计：直通车 + 引力魔方 + 全站推/万象台 + 超级短视频 之和' AS Channel_Description, 'SUMMARY' AS Channel_Type,
        'TM_RTB Total' AS Channel_ID, NULL AS Summary_Scope, 'TM_RTB Total' AS Parent_Channel_ID
    UNION ALL SELECT 'TM', 1, '品销宝 Total', 1000, '品销宝 Total', 'TM平台-品销宝合计：品牌专区相关渠道汇总（品销宝产品线整体）', 'SUMMARY', 'TM_品销宝 Total', NULL, 'TM_品销宝 Total'
    UNION ALL SELECT 'TM', 1, 'JCGP Total', 1500, 'JCGP Total', 'TM平台-JCGP合计：品销宝 Total + 品牌特秀（品牌类渠道整体汇总）', 'SUMMARY', 'TM_JCGP Total', NULL, 'TM_JCGP Total'
    UNION ALL SELECT 'TM', 1, 'Total', 2000, 'Total', 'TM平台-全渠道合计：RTB Total + JCGP Total，即 TM 平台所有渠道总和', 'SUMMARY', 'TM_Total', NULL, 'TM_Total'
    UNION ALL SELECT 'TM', 1, 'Total 不含JCGP', 2500, 'Total 不含JCGP', 'TM平台-全渠道合计（剔除JCGP）：Total - JCGP Total，即纯效果类渠道（RTB类）合计', 'SUMMARY', 'TM_Total 不含JCGP', NULL, 'TM_Total 不含JCGP'
    UNION ALL SELECT 'JD', 2, 'RTB Total', 500, 'RTB Total ', 'JD平台-RTB合计：快车 + 触点 + 海投 + 直投 之和', 'SUMMARY', 'JD_RTB Total', NULL, 'JD_RTB Total'
    UNION ALL SELECT 'JD', 2, 'RTB Total + 京选店铺', 501, 'RTB Total + 京选店铺', 'JD平台-RTB合计（含京选店铺）：RTB Total + 京选店铺，含京选店铺口径的效果类汇总', 'SUMMARY', 'JD_RTB Total + 京选店铺', NULL, 'JD_RTB Total + 京选店铺'
    UNION ALL SELECT 'JD', 2, 'Brandzone', 1000, 'Brandzone', 'JD平台-Brandzone汇总：所有Brandzone类型的品牌展示广告渠道汇总', 'SUMMARY', 'JD_Brandzone', NULL, 'JD_Brandzone'
    UNION ALL SELECT 'JD', 2, 'JCGP Total', 1500, 'JCGP Total ', 'JD平台-JCGP合计：品牌类渠道整体汇总（不含Brandzone）', 'SUMMARY', 'JD_JCGP Total', NULL, 'JD_JCGP Total'
    UNION ALL SELECT 'JD', 2, 'Total', 2500, 'Total ', 'JD平台-全渠道合计：RTB Total + Brandzone + JCGP Total，即 JD 平台所有渠道总和', 'SUMMARY', 'JD_Total', NULL, 'JD_Total'
    UNION ALL SELECT 'JD', 2, 'Total 不含JCGP', 3000, 'Total 不含JCGP ', 'JD平台-全渠道合计（剔除JCGP）：Total - JCGP Total，纯效果类渠道（RTB类）合计', 'SUMMARY', 'JD_Total 不含JCGP', NULL, 'JD_Total 不含JCGP'
),
summary_data AS (
    SELECT s.Platform, s.Platform_Sort, s.Channel, s.Channel_Sort, s.Channel_Label,
        s.Channel_Description, s.Channel_Type, s.Channel_ID,
        COALESCE(d.Summary_Scope, '') AS Summary_Scope, s.Parent_Channel_ID
    FROM summary_base s
    LEFT JOIN dynamic_scope d ON s.Channel_ID = d.Channel_ID
)
SELECT
    ROW_NUMBER() OVER (ORDER BY Platform_Sort, Channel_Sort) AS Channel_PK,
    Platform, Platform_Sort, Channel, Channel_Sort,
    CASE WHEN Platform = 'TM' THEN Channel_Label
        ELSE CONCAT(Channel_Label, CHAR(11)) END AS Channel_Label,
    Channel_Description, Channel_Type, Channel_ID, Summary_Scope,
    CASE WHEN Platform = 'TM' THEN 'TM_Total' ELSE 'JD_Total' END AS Parent_Channel_ID
FROM (
    SELECT c.Platform, c.Platform_Sort, c.Channel,
        CASE WHEN c.Channel_Type = 'DETAIL' THEN c.Channel_Sort
            ELSE c.Channel_Sort + COALESCE(o.RTB_Offset, 0) END AS Channel_Sort,
        c.Channel_Label, c.Channel_Description, c.Channel_Type, c.Channel_ID, c.Summary_Scope
    FROM (
        SELECT * FROM detail_sorted
        UNION ALL
        SELECT * FROM summary_data
    ) c
    LEFT JOIN rtb_offset o ON c.Platform = o.platform
) dim_channel_config
ORDER BY Platform_Sort, Channel_Sort;
```
