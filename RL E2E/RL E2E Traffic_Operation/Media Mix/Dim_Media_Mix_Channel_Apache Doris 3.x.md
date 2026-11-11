# 5. 版本 C — Apache Doris 3.x（MySQL ODBC 协议）

Doris 的分隔符位于第二个参数，不能写 MySQL 的 `SEPARATOR`。先在 scope_first 去重，避免依赖 `DISTINCT + ORDER BY` 组合的版本差异。此段不适用于真正的 MySQL 5.7，也不将所有 MySQL 协议数据库视为 Doris。

```sql
-- ============================================================================
-- 整体思路（CTE 管线）：
--   channel_source  去重渠道维度，并用嵌套 CASE 复刻 ClickHouse indexOf 的固定 RTB 顺序
--   rtb_offset      统计每平台'未枚举 RTB'数量 N，得到顺延步长 10*N
--   detail_data     计算明细基础排序（已枚举 RTB=顺序*10；未枚举 RTB 从 500 起按名称追加）
--   detail_sorted   非 RTB 明细统一加 RTB_Offset，得到明细最终排序
--   scope_members   11 个汇总 Scope 各自收集底层明细成员
--   scope_first     每个 (Scope_ID, Channel_ID) 取最小排序值去重
--   dynamic_scope   按排序值有序拼接成员 ID 为 '|' 分隔字符串
--   summary_base    11 条写死的 SUMMARY 汇总行
--   summary_data    SUMMARY 关联动态 Scope（无成员则空字符串）
--   最终 SELECT     明细+SUMMARY 合并、SUMMARY 再加偏移、打 Channel_PK 输出 11 列
-- 本段仅替换为 Doris 方言，业务逻辑与输出字段与 ClickHouse 基准完全一致。
-- ============================================================================
WITH channel_source AS (
    -- 嵌套 CASE 复刻 ClickHouse 的 indexOf([...], channel)：命中固定 RTB 渠道返回日报顺序 1~N，
    -- 未命中返回 0（标记为'未枚举'，后续按名称升序追加）。
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
        -- 先按 platform/channel/channel_type 去重，保证后续统计的是渠道数而非事实记录数。
        SELECT DISTINCT platform, channel, channel_type
        FROM `indep_rl_ads`.a05_e2e_paid_media_channel_data_d
        WHERE platform IN ('JD', 'TM')
            AND channel_type IS NOT NULL AND channel_type != ''
            AND channel_type IN ('JCGP', 'RTB', '品销宝', 'Brandzone', 'Branzone')
    ) d
),
rtb_offset AS (
    -- SUM(CASE WHEN ... THEN 1 ELSE 0 END) 复刻 ClickHouse countIf：按平台统计未枚举 RTB 渠道数 N，
    -- 乘 10 得顺延步长 RTB_Offset=10*N，供非 RTB 明细与所有 SUMMARY 整体后移。
    SELECT platform,
        SUM(CASE WHEN channel_type = 'RTB' AND RTB_Order = 0 THEN 1 ELSE 0 END) * 10 AS RTB_Offset
    FROM channel_source
    GROUP BY platform
),
detail_data AS (
    -- 明细基础排序：已枚举 RTB=顺序*10（10,20,...）；未枚举 RTB 从 500 起按名称升序每项 +10。
    -- 所有按名称升序的窗口都用 CASE WHEN channel IS NULL THEN 1 ELSE 0 END 把 NULL 排到末尾，
    -- 对齐 ClickHouse 默认 NULL 末尾顺序。非 RTB 的 510/1010 是顺延前基础值，detail_sorted 再加偏移。
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
    -- 仅非 RTB 明细加 RTB_Offset（RTB 明细已在 500 段内自然排好）；COALESCE 把无偏移平台的 NULL 取 0。
    -- 此处用尚未覆盖为平台 Total 的父级标识识别 RTB 明细，明细最终排序在此定稿供 Scope 与输出共用。
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
    -- 11 个 UNION ALL 分支：每个汇总 Scope 按其口径收集底层明细成员（同一 ID 可归属多个 Scope）。
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
    -- 关键去重：同一 Scope 内同一 Channel_ID 可能对应多个排序值，取 MIN(Channel_Sort) 定位首次出现。
    -- 等价于原 ClickHouse 'arraySort(排序元组) → arrayMap 取 ID → arrayDistinct 按首次出现去重'。
    SELECT Scope_ID, Channel_ID, MIN(Channel_Sort) AS First_Sort
    FROM scope_members
    GROUP BY Scope_ID, Channel_ID
),
dynamic_scope AS (
    -- Doris 有序字符串聚合：GROUP_CONCAT(表达式, 分隔符 ORDER BY ...)。
    -- 注意分隔符 '|' 是第二个位置参数，Doris 不支持 MySQL 的 SEPARATOR 关键字；
    -- 入参已在 scope_first 去重，故无需 DISTINCT，避免 DISTINCT+ORDER BY 组合的版本差异。
    SELECT Scope_ID AS Channel_ID,
        GROUP_CONCAT(Channel_ID, '|' ORDER BY First_Sort, Channel_ID) AS Summary_Scope
    FROM scope_first
    GROUP BY Scope_ID
),
summary_base AS (
    -- 11 条写死的 SUMMARY 行：Channel_Sort 为 500 的倍数（JD 扩展汇总用 501），Summary_Scope 置空待动态匹配。
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
    -- SUMMARY 关联动态 Scope；COALESCE(..., '') 保证无成员的汇总行 Scope 为空字符串而非 NULL。
    SELECT s.Platform, s.Platform_Sort, s.Channel, s.Channel_Sort, s.Channel_Label,
        s.Channel_Description, s.Channel_Type, s.Channel_ID,
        COALESCE(d.Summary_Scope, '') AS Summary_Scope, s.Parent_Channel_ID
    FROM summary_base s
    LEFT JOIN dynamic_scope d ON s.Channel_ID = d.Channel_ID
)
-- 最终输出：明细排序已定稿，此处仅给所有 SUMMARY 行加 RTB_Offset，再按 Platform_Sort,Channel_Sort 打 Channel_PK。
-- CHAR(11) 保留原 ClickHouse CHAR(8203) 的实际字节 0x0B（8203 溢出 UInt8 后为 11），仅 JD 标签追加；
-- Parent_Channel_ID 统一强制为 TM_Total / JD_Total，不输出中间分类父级。
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
