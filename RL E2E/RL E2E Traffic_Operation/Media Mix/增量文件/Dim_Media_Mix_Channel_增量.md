# Dim_Media_Mix_Channel 增量

原文件不修改。以下为已整合 RTB 排序及 `Summary_Scope` 有序拼接改动的完整 SQL，可整体复制到 `Dim_Media_Mix_Channel` 数据源查询中使用，无需手工拼接。Scope 按明细的最终 `Channel_Sort` 升序拼接，同值时按 `Channel_ID` 升序；原有汇总成员、渠道属性、最终排序值及父级字段逻辑保持不变。

## 1. 完整 SQL

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

## 2. 排序结果与应用配置

| 平台 | 固定 RTB 顺序 | 固定排序值 |
|------|---------------|------------|
| TM | 直通车 → 引力魔方 → 全站推/万相台 → 超级短视频 → 超级直播 → 店铺直达 | 10、20、30、40、50、60 |
| JD | 快车 → 触点 → 海投 → 直投 → 全站智能推广 → 智能化 → 新品推广 → 短视频 → 全站营销 | 10、20、30、40、50、60、70、80、90 |

- 每个平台的未枚举 RTB 渠道按 `channel ASC` 排序，取值为 `500、510、520……`。枚举名称严格按本次需求匹配，不增加别名映射；源数据中不存在的枚举渠道不补造行。
- 设某平台未枚举 RTB 渠道数为 `N`：该平台 `RTB Total` 为 `500 + 10 × N`，其余非 RTB 行也在原始排序值上增加 `10 × N`。例如 `N=2` 时：两个新渠道为 `500、510`，`RTB Total` 为 `520`，JD 的 `RTB Total + 京选店铺` 为 `521`，后续分组首个明细为 `530`。这样新 RTB 不会与原汇总行、后续分组发生排序碰撞。
- 最终输出不再对 JD 的 `Channel_Sort` 乘以 10，确保两平台的枚举值均落在 1–100 内，新增渠道均从 500 开始。平台内排序独立，跨平台相同排序值允许存在；原有 JD 展示标签处理保留。
- 刷新维度表后，继续设置 `Channel_Label` 按 `Channel_Sort` 排序；矩阵保持 `Platform → Channel_Label → Indicator Type` 行结构，并按行标签升序，不能改成按 Cost 排序。
- `Summary_Scope` 的成员范围与 ID 去重口径不变，改为按明细最终 `Channel_Sort` 升序拼接；同值时按 `Channel_ID` 升序，仅稳定 Scope 文本顺序，不改变原有排序值。最终 `Parent_Channel_ID`、数据源过滤条件均保持原逻辑，不在 SQL 中删除零值渠道，不调整指标口径。

验证：分别检查无新增渠道、两个新增渠道、大量新增渠道三种情况；枚举排序固定，所有新增 RTB 排在枚举之后、RTB Total 之前，非 RTB 分组相对顺序不变。将各汇总行的 Scope 按 `|` 拆分，核对成员集合与原版一致，并按对应明细的最终排序值递增；平台 Total 内也应先 RTB、再后续分组。若同一 ID 对应多条明细，Scope 仅保留一次，位置取其最小最终排序值。

## 3. 增量修改部分

本节用于在原始 `Dim_Media_Mix_Channel` SQL 上分段应用改动，与第 1 节完整 SQL 的实现一致。两种应用方式任选其一：已使用第 1 节完整 SQL 的，无需再次执行本节替换。

### 3.1 替换开头的 detail_data CTE

替换位置：原 SQL 从 `WITH detail_data AS (` 开始，到 `dynamic_scope AS (` 前面的 `),` 为止。

用下面四个 CTE 整体替换。代码末尾保留逗号，后面接第 3.2 节替换后的 `dynamic_scope AS (`，不要另加 `WITH`。

改动内容：新增 `channel_source` 标记日报枚举顺序，新增 `rtb_offset` 计算后续行顺延量，修改 `detail_data` 的 RTB 排序及数据来源，并新增 `detail_sorted` 提前计算明细最终排序值。

```sql
WITH channel_source AS (
    -- 保留原始取数条件，仅增加 RTB 日报顺序标记；未枚举渠道标记为 0。
    SELECT
        d.platform,
        d.channel,
        d.channel_type,
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
                    ELSE 500 + (
                        ROW_NUMBER() OVER (
                            PARTITION BY d.platform, d.channel_type, d.RTB_Order
                            ORDER BY d.channel ASC
                        ) - 1
                    ) * 10
                END
            -- 非 RTB 明细的原基础排序逻辑不变，在 detail_sorted 中统一顺延。
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
```

### 3.2 替换 dynamic_scope CTE

替换位置：原 SQL 从 `dynamic_scope AS (` 开始，到 `summary_base AS (` 前面的 `),` 为止。

用下面代码整体替换。各汇总分支的筛选条件不变，改为读取 `detail_sorted`，按最终排序值拼接 ID；后面的 `summary_base`、`summary_data` 保持原样。

```sql
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
```

### 3.3 替换最终 SELECT

替换位置：原 SQL 从 `-- 最终合并输出并打序号` 开始，到最终查询的分号 `;` 为止。

用下面代码整体替换。`dynamic_scope` 已按第 3.2 节更新，`summary_base`、`summary_data` 保持原样。

改动内容：合并 `detail_sorted` 与 `summary_data`，明细直接使用已算好的最终排序值，仅对汇总行增加 `rtb_offset`，避免非 RTB 明细重复顺延；按最终排序生成 `Channel_PK`，`Channel_Sort` 直接输出，不再对 JD 乘以 10。

```sql
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

上述三处替换需配套应用；`summary_base`、`summary_data` 及其余 SQL 不变。零值隐藏仍由 DAX 视觉筛选度量实现，不在这些 SQL 片段中增加过滤条件。
