```需求
TM&JD 表头顺序调整为与日报一致，隐藏无cost的渠道

1. RTB明细行的顺序和日报一致
TM：直通车、引力魔方、全站推/万相台、超级短视频、超级直播、店铺直达
JD：快车、触点、海投、直投、全站智能推广、智能化、新品推广、短视频、全站营销
2. RTB明细行中Cost为0的行记录不展示
3. RTB明细行如有新增渠道直接追加在上述渠道顺序后面
```



```sql
WITH channel_source AS (
    -- 保留原始取数条件，仅增加 RTB 日报顺序标记；未枚举渠道标记为 0。
    SELECT
        d.platform,
        d.channel,
        d.channel_type,
        -- indexOf(数组, 值)：返回第一次匹配的位置，从 1 开始；未匹配返回 0。
        -- 此处数组顺序就是日报顺序，如 TM 的直通车=1、引力魔方=2；之后乘以 10 得到固定排序。
        CASE
            WHEN d.platform = 'TM' AND d.channel_type = 'RTB' THEN
                indexOf(
                    ['直通车', '引力魔方', '全站推/万相台', '超级短视频', '超级直播', '店铺直达'],
                    d.channel
                )
            WHEN d.platform = 'JD' AND d.channel_type = 'RTB' THEN
                indexOf(
                    ['快车', '触点', '海投', '直投', '全站智能推广', '智能化', '新品推广', '短视频', '全站营销'],
                    d.channel
                )
            ELSE 0
        END AS RTB_Order
    FROM (
        SELECT DISTINCT
            platform,
            channel,
            channel_type
        FROM `indep_rl_ads`.a05_e2e_paid_media_channel_data_d
        WHERE platform IN ('JD', 'TM')
          AND channel_type IS NOT NULL
          AND channel_type != ''
          AND channel_type IN ('JCGP', 'RTB', '品销宝', 'Brandzone', 'Branzone')
    ) d
),
rtb_offset AS (
    -- 原 RTB Total 已占用 500：每新增一个未枚举 RTB 渠道，后续行顺延 10。
    SELECT
        platform,
        -- countIf(条件)：统计组内满足条件的行数；此处按平台统计未枚举 RTB 渠道数 N。
        -- 上游已按 platform/channel/channel_type 去重，因此统计的是渠道数，不是事实表记录数。
        -- 必须同时限定 RTB：非 RTB 行的 RTB_Order 也为 0，不能计入偏移量。
        countIf(channel_type = 'RTB' AND RTB_Order = 0) * 10 AS RTB_Offset
    FROM channel_source
    GROUP BY platform
),
detail_data AS (
    SELECT
        d.platform AS Platform,
        CASE d.platform WHEN 'TM' THEN 1 WHEN 'JD' THEN 2 END AS Platform_Sort,
        d.channel AS Channel,
        CASE
            -- 枚举渠道固定为 10、20……；其他 RTB 渠道按原始名称升序从 500 追加。
            WHEN d.channel_type = 'RTB' THEN
                CASE
                    WHEN d.RTB_Order > 0 THEN d.RTB_Order * 10
                    -- 未枚举 RTB 的 RTB_Order=0，单独组成窗口分区，不受已枚举渠道数量影响。
                    -- ROW_NUMBER 按名称升序从 1 编号；减 1 后，第一个未枚举渠道正好取 500。
                    ELSE 500 + (
                        ROW_NUMBER() OVER (
                            PARTITION BY d.platform, d.channel_type, d.RTB_Order
                            ORDER BY d.channel ASC
                        ) - 1
                    ) * 10
                END
            -- 非 RTB 明细的原基础排序逻辑不变，在 detail_sorted 中统一顺延。
            -- 下方 510/1010 是顺延前的基础值，不是最终输出值；最终统一加该平台的 10*N。
            -- 中间 CTE 可暂时与新增 RTB 出现同值，最终查询完成顺延后才生成 Channel_PK。
            WHEN d.platform = 'TM' AND d.channel_type = '品销宝' THEN
                510 + (ROW_NUMBER() OVER (PARTITION BY d.platform, d.channel_type ORDER BY d.channel) - 1) * 10
            WHEN d.platform = 'TM' AND d.channel_type = 'JCGP' THEN
                1010 + (ROW_NUMBER() OVER (PARTITION BY d.platform, d.channel_type ORDER BY d.channel) - 1) * 10
            WHEN d.platform = 'JD' AND d.channel_type IN ('Brandzone', 'Branzone') THEN
                510 + (ROW_NUMBER() OVER (PARTITION BY d.platform, d.channel_type ORDER BY d.channel) - 1) * 10
            WHEN d.platform = 'JD' AND d.channel_type = 'JCGP' THEN
                1010 + (ROW_NUMBER() OVER (PARTITION BY d.platform, d.channel_type ORDER BY d.channel) - 1) * 10
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
    -- 明细在此完成最终排序计算，供 Scope 拼接与最终输出共用；后续不再给明细加偏移。
    SELECT
        d.Platform,
        d.Platform_Sort,
        d.Channel,
        CASE
            -- 使用尚未覆盖为平台 Total 的父级标识识别 RTB 明细。
            WHEN d.Parent_Channel_ID IN ('TM_RTB Total', 'JD_RTB Total')
                THEN d.Channel_Sort
            ELSE d.Channel_Sort + ifNull(o.RTB_Offset, 0)
        END AS Channel_Sort,
        d.Channel_Label,
        d.Channel_Description,
        d.Channel_Type,
        d.Channel_ID,
        d.Summary_Scope,
        d.Parent_Channel_ID
    FROM detail_data d
    LEFT JOIN rtb_offset o ON d.Platform = o.platform
),
dynamic_scope AS (
    -- 各分支仍只收集原范围内的底层明细；detail_sorted.Channel_Sort 已是最终排序值。
    -- groupUniqArray 收集去重的 (排序值, Channel_ID) 元组；x.1 为排序值，x.2 为 ID。
    -- arraySort 先按最终排序值升序，再按 ID 升序；arrayMap 取出排序后的 ID。
    -- arrayDistinct 按首次出现的位置对 ID 去重，避免同一 ID 在不同排序值下重复拼接。
    -- arrayStringConcat 用 | 连接；这里只稳定 Scope 文本顺序，DAX 成员判断不变。
    SELECT 'TM_RTB Total' AS Channel_ID,
        arrayStringConcat(
            arrayDistinct(
                arrayMap(x -> x.2,
                    arraySort(x -> (x.1, x.2), groupUniqArray((Channel_Sort, Channel_ID)))
                )
            ),
            '|'
        ) AS Summary_Scope
    FROM detail_sorted WHERE Platform = 'TM' AND Parent_Channel_ID = 'TM_RTB Total'
    UNION ALL
    SELECT 'TM_品销宝 Total', arrayStringConcat(arrayDistinct(arrayMap(x -> x.2, arraySort(x -> (x.1, x.2), groupUniqArray((Channel_Sort, Channel_ID))))), '|')
    FROM detail_sorted WHERE Platform = 'TM' AND Parent_Channel_ID = 'TM_品销宝 Total'
    UNION ALL
    -- TM_JCGP Total 需要包含： JCGP明细
    SELECT 'TM_JCGP Total', arrayStringConcat(arrayDistinct(arrayMap(x -> x.2, arraySort(x -> (x.1, x.2), groupUniqArray((Channel_Sort, Channel_ID))))), '|')
    FROM detail_sorted WHERE Platform = 'TM' AND Parent_Channel_ID IN ('TM_JCGP Total')
    UNION ALL
    SELECT 'TM_Total', arrayStringConcat(arrayDistinct(arrayMap(x -> x.2, arraySort(x -> (x.1, x.2), groupUniqArray((Channel_Sort, Channel_ID))))), '|')
    FROM detail_sorted WHERE Platform = 'TM'
    UNION ALL
    -- TM_Total 不含JCGP（仅含RTB）
    SELECT 'TM_Total 不含JCGP', arrayStringConcat(arrayDistinct(arrayMap(x -> x.2, arraySort(x -> (x.1, x.2), groupUniqArray((Channel_Sort, Channel_ID))))), '|')
    FROM detail_sorted WHERE Platform = 'TM' AND Parent_Channel_ID NOT IN ('TM_JCGP Total')
    UNION ALL
    SELECT 'JD_RTB Total', arrayStringConcat(arrayDistinct(arrayMap(x -> x.2, arraySort(x -> (x.1, x.2), groupUniqArray((Channel_Sort, Channel_ID))))), '|')
    FROM detail_sorted WHERE Platform = 'JD' AND Parent_Channel_ID = 'JD_RTB Total'
    UNION ALL
    -- 包含“京选店铺”
    SELECT 'JD_RTB Total + 京选店铺', arrayStringConcat(arrayDistinct(arrayMap(x -> x.2, arraySort(x -> (x.1, x.2), groupUniqArray((Channel_Sort, Channel_ID))))), '|')
    FROM detail_sorted WHERE Platform = 'JD' AND Parent_Channel_ID IN ('JD_RTB Total') OR  Channel_ID = 'JD_京选店铺'
    UNION ALL
    SELECT 'JD_Brandzone', arrayStringConcat(arrayDistinct(arrayMap(x -> x.2, arraySort(x -> (x.1, x.2), groupUniqArray((Channel_Sort, Channel_ID))))), '|')
    FROM detail_sorted WHERE Platform = 'JD' AND Parent_Channel_ID = 'JD_Brandzone'
    UNION ALL
    SELECT 'JD_JCGP Total', arrayStringConcat(arrayDistinct(arrayMap(x -> x.2, arraySort(x -> (x.1, x.2), groupUniqArray((Channel_Sort, Channel_ID))))), '|')
    FROM detail_sorted WHERE Platform = 'JD' AND Parent_Channel_ID = 'JD_JCGP Total'
    UNION ALL
    SELECT 'JD_Total', arrayStringConcat(arrayDistinct(arrayMap(x -> x.2, arraySort(x -> (x.1, x.2), groupUniqArray((Channel_Sort, Channel_ID))))), '|')
    FROM detail_sorted WHERE Platform = 'JD'
    UNION ALL
    -- JD_Total 不含JCGP（即剔除JCGP，保留 RTB + Brandzone）
    SELECT 'JD_Total 不含JCGP', arrayStringConcat(arrayDistinct(arrayMap(x -> x.2, arraySort(x -> (x.1, x.2), groupUniqArray((Channel_Sort, Channel_ID))))), '|')
    FROM detail_sorted WHERE Platform = 'JD' AND Parent_Channel_ID NOT IN ('JD_JCGP Total', 'UNKNOWN')
),
summary_base AS (
    -- 写死的 SUMMARY 汇总行基础属性（Channel_Sort 固定为 500 的倍数，Summary_Scope 置空待动态匹配）
    -- 以下是原有基础排序值（含 JD 扩展汇总 501）；最终所有 SUMMARY 行同样加 10*N。
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
    -- 将汇总行基础属性与动态拼接的 Scope 关联
    SELECT
        s.Platform,
        s.Platform_Sort,
        s.Channel,
        s.Channel_Sort,
        s.Channel_Label,
        s.Channel_Description,
        s.Channel_Type,
        s.Channel_ID,
        COALESCE(d.Summary_Scope, '') AS Summary_Scope,
        s.Parent_Channel_ID
    FROM summary_base s
    LEFT JOIN dynamic_scope d ON s.Channel_ID = d.Channel_ID
)
-- 最终合并输出并打序号：先完成排序顺延，再生成 Channel_PK。
SELECT
    ROW_NUMBER() OVER (ORDER BY Platform_Sort, Channel_Sort) AS Channel_PK,
    Platform,
    Platform_Sort,
    Channel,
    Channel_Sort,
    IF(Platform = 'TM', Channel_Label, CONCAT(Channel_Label, CHAR(8203))) AS Channel_Label,
    Channel_Description,
    Channel_Type,
    Channel_ID,
    Summary_Scope,
    IF(Platform = 'TM', 'TM_Total', 'JD_Total') AS Parent_Channel_ID
FROM (
    SELECT
        c.Platform,
        c.Platform_Sort,
        c.Channel,
        CASE
            -- 所有明细都已在 detail_sorted 中计算最终排序值，此处直接复用。
            WHEN c.Channel_Type = 'DETAIL' THEN c.Channel_Sort
            -- 非 RTB 明细已提前顺延；此处仅为所有 SUMMARY 行加 10*N。
            -- N>0 时，新增 RTB 末条=500+10*(N-1)，RTB Total=500+10*N，下一组首条=510+10*N。
            -- 例如 N=12：新增 RTB 为 500～610，RTB Total 为 620，下一组首条为 630，不会互相碰撞。
            -- ifNull(值, 0)：平台偏移量关联结果为 NULL 时按 0 处理，保留基础排序值。
            ELSE c.Channel_Sort + ifNull(o.RTB_Offset, 0)
        END AS Channel_Sort,
        c.Channel_Label,
        c.Channel_Description,
        c.Channel_Type,
        c.Channel_ID,
        c.Summary_Scope
    FROM (
        SELECT * FROM detail_sorted
        UNION ALL
        SELECT * FROM summary_data
    ) c
    LEFT JOIN rtb_offset o ON c.Platform = o.platform
) AS dim_channel_config
ORDER BY Platform_Sort, Channel_Sort
;
```