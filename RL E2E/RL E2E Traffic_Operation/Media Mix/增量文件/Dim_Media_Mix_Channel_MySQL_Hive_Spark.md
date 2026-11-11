# Dim_Media_Mix_Channel — MySQL / Hive / Spark SQL 兼容版

## 1. 使用范围

基准为同目录 `Dim_Media_Mix_Channel.md` 中的 SQL。仅替换数据库方言；原文件不修改，不新增 Cost 筛选，不调整汇总口径。

有序字符串聚合没有一套能直接覆盖这些数据库的通用语法，因此本文件提供三段独立完整 SQL，选择实际引擎对应的一段执行。

**当前 ODBC 报错的入口**：同一连接先后拒绝 `x.2` 和 `collect_list(struct<...>)`，说明版本 B 的聚合写法不适用于该后端。连接特征指向 Doris；若确认是 Doris，请完整复制 §5 版本 C，而不是继续修改版本 B 的 struct 字段类型。C 不使用 `COLLECT_LIST`、`NAMED_STRUCT` 或数组字段投影，直接对预先去重的 ID 有序拼接。实际数据库产品及版本仍需核实，不能仅凭 MySQL 驱动名称判定。

| 版本 | 执行引擎 | 入口 |
| --- | --- | --- |
| A | MySQL 8.0.17+ | §3：`GROUP_CONCAT(... ORDER BY ... SEPARATOR ...)` |
| B | Hive 4.1+ / Spark SQL 3.x+ | §4：排序 struct 数组，再投影 ID 并连接 |
| C | Apache Doris 3.x | §5：`GROUP_CONCAT(..., 分隔符 ORDER BY ...)` |

- MySQL ODBC 是连接协议，不代表后端一定是 MySQL。报错中的 `mysqld-5.7.99`、9030 端口和 `errCode = 2` 与 Doris 的连接特征相符，但仍须确认实际产品和版本；若为 Doris，选 C，不要使用 MySQL 的 `SEPARATOR` 写法。
- 可在现有连接执行 `SELECT VERSION();`，结合数据库管理端确认产品。真正的 MySQL 5.7 不支持本方案使用的 `WITH` / `ROW_NUMBER()`，不能直接使用 A。
- B 的 Hive 支持范围保守限定为 4.1+：早期版本的 struct 数组字段投影存在优化器兼容差异；不将 Spark 的 lambda 语法当作 Hive 通用语法。
- 以下 SQL 不包含连接信息或凭据；数据源仍为 `indep_rl_ads.a05_e2e_paid_media_channel_data_d`。

## 2. 方言替换与逻辑不变量

| 原表达式 | 替换方式 | 保留的含义 |
| --- | --- | --- |
| `indexOf([...], channel)` | 嵌套 `CASE` | 固定 RTB 排序 1～N；未列举渠道为 0 |
| `countIf(条件)` | `SUM(CASE WHEN 条件 THEN 1 ELSE 0 END)` | 每平台未列举 RTB 数量 × 10 |
| `groupUniqArray` / `arraySort` / `arrayMap(x -> x.2)` / `arrayDistinct` | 按 Scope、Channel_ID 取最小 Channel_Sort，再有序聚合 | 每个 ID 保留排序后的首次出现位置 |
| `arrayStringConcat(..., '|')` | 各引擎的有序字符串连接 | 分隔符不变，空集合仍为空字符串 |
| `ifNull` / `IF` | `COALESCE` / `CASE` | 空偏移取 0，平台分支不变 |
| 名称升序 | 增加显式 NULL 末尾排序；MySQL 源字段使用二进制、NO PAD 排序规则 | 对齐 ClickHouse 的字符串比较及默认 NULL 末尾顺序 |
| `CHAR(8203)` | A：`CHAR(11 USING utf8mb4)`；B：`CHR(11)`；C：`CHAR(11)` | 保留原 ClickHouse 的实际字节 `0B`，而不是改成 U+200B |

**标签字符特别说明**：ClickHouse 的 `char` 会将参数转换为 UInt8，8203 溢出后为 11，因此原表达式实际追加的是 U+000B，不是零宽空格 U+200B。MySQL / Doris 的 `CHAR(8203)` 又会产生不同的多字节结果。为严格保持原 SQL 的实际输出，本文件显式保留 `0B`；如需改为真正的 U+200B，应作为单独的标签变更，不包含在这次语法迁移中。原 SUMMARY 标签中已有的尾随普通空格也原样保留。

### 2.1 排序与 Scope

- TM 固定 RTB：直通车、引力魔方、全站推/万相台、超级短视频、超级直播、店铺直达。
- JD 固定 RTB：快车、触点、海投、直投、全站智能推广、智能化、新品推广、短视频、全站营销。
- 未枚举 RTB 从 500 开始，按名称每项递增 10；非 RTB 明细和所有 SUMMARY 增加该平台的 `10 × 未枚举RTB数量`。
- 同一 Scope 中同一 Channel_ID 对应多个排序值时，只保留最小排序值；等价于原逻辑“排序元组 → 取 ID → 按首次出现去重”。不同 ID 同排序值时按 ID 升序。
- `TM_Total 不含JCGP` 保留原 SQL 的“排除 JCGP”条件，包含品销宝；不按原注释中的“仅 RTB”重新解释。
- `TM_JCGP Total` 仍只包含 JCGP 明细；`JD_RTB Total + 京选店铺` 仍按原 OR 条件纳入 `JD_京选店铺`。
- `Brandzone` 与 `Branzone` 的取数和窗口分区仍保留原样，不合并源类别。
- 最终 Parent_Channel_ID 仍统一为 TM_Total / JD_Total；不输出中间分类父级。
- 原 SQL 没有引用 cost_amt，本文件也不增加零 Cost 渠道过滤；既有视觉对象隐藏规则不变。

### 2.2 输出字段及顺序

`Channel_PK, Platform, Platform_Sort, Channel, Channel_Sort, Channel_Label, Channel_Description, Channel_Type, Channel_ID, Summary_Scope, Parent_Channel_ID`

共 11 列，字段名、顺序及业务取值规则不变。Channel_PK 仍只按 `Platform_Sort, Channel_Sort` 编号；若原数据存在同平台同排序值，并列记录的 PK 分配原本就不确定，本文件不擅自增加决胜字段。物理字符串长度、整数位宽等元数据由各引擎推导，导入 Power BI 时继续沿用原字段类型设置。

## 3. 版本 A — MySQL 8.0.17+

MySQL 默认 `group_concat_max_len` 只有 1024 字节，可能截断 Summary_Scope。执行查询前，须在**同一个物理连接的会话**设置足够的上限，并确保 `max_allowed_packet` 不小于实际输出需求。例如下面的 16 MiB 是配置示例，不是对任意数据量的保证；若 Scope 更长，需进一步增大。不要把 SET 和 SELECT 直接拼成一条要求单语句的 Power BI 原生查询，也不要假设另一连接里的 SET 会生效。

```sql
SET SESSION group_concat_max_len = 16777216;
```

此处 `utf8mb4_0900_bin` 从 MySQL 8.0.17 起提供，是二进制 NO PAD 排序规则，避免默认不区分大小写、忽略尾随空格的比较改变 DISTINCT、名称排名或 Scope 去重结果；更早的 MySQL 8.0 小版本不能直接执行本段。

```sql
-- ============================================================================
-- 整体思路（CTE 管线）：
--   channel_source  去重渠道维度，并用嵌套 CASE 复刻 ClickHouse indexOf 的固定 RTB 顺序
--   rtb_offset      统计每平台'未枚举 RTB'数量 N，得到顺延步长 10*N
--   detail_data     计算明细基础排序（已枚举 RTB=顺序*10；未枚举 RTB 从 500 起按名称追加）
--   detail_sorted   非 RTB 明细统一加 RTB_Offset，得到明细最终排序
--   scope_members   11 个汇总 Scope 各自收集底层明细成员
--   scope_first     每个 (Scope_ID, Channel_ID) 取最小排序值去重
--   dynamic_scope   按排序值有序拼接成员 ID 为 '|' 分隔字符串（各引擎语法不同）
--   summary_base    11 条写死的 SUMMARY 汇总行
--   summary_data    SUMMARY 关联动态 Scope（无成员则空字符串）
--   最终 SELECT     明细+SUMMARY 合并、SUMMARY 再加偏移、打 Channel_PK 输出 11 列
-- 三段 SQL 仅数据库方言不同，业务逻辑与输出字段均与 ClickHouse 基准完全一致。
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
        FROM (
            -- CONVERT(... USING utf8mb4) COLLATE utf8mb4_0900_bin：强制二进制 NO PAD 排序规则，
            -- 避免 MySQL 默认不区分大小写/忽略尾随空格的比较改变 DISTINCT、名称排名与 Scope 去重；
            -- utf8mb4_0900_bin 自 MySQL 8.0.17 起提供，更早小版本不能执行本段。
            SELECT
                CONVERT(platform USING utf8mb4) COLLATE utf8mb4_0900_bin AS platform,
                CONVERT(channel USING utf8mb4) COLLATE utf8mb4_0900_bin AS channel,
                CONVERT(channel_type USING utf8mb4) COLLATE utf8mb4_0900_bin AS channel_type
            FROM `indep_rl_ads`.a05_e2e_paid_media_channel_data_d
        ) raw_source
        WHERE platform IN ('JD', 'TM')
            AND channel_type IS NOT NULL AND channel_type != ''
            AND channel_type IN ('JCGP', 'RTB', '品销宝', 'Brandzone', 'Branzone')
    ) d
),
-- SUM(CASE WHEN ... THEN 1 ELSE 0 END) 复刻 ClickHouse countIf：按平台统计未枚举 RTB 渠道数 N，
-- 乘 10 得顺延步长 RTB_Offset=10*N，供非 RTB 明细与所有 SUMMARY 整体后移。
rtb_offset AS (
    SELECT platform,
        SUM(CASE WHEN channel_type = 'RTB' AND RTB_Order = 0 THEN 1 ELSE 0 END) * 10 AS RTB_Offset
    FROM channel_source
    GROUP BY platform
),
-- 明细基础排序：已枚举 RTB=顺序*10（10,20,...）；未枚举 RTB 从 500 起按名称升序每项 +10。
-- 所有按名称升序的窗口都用 CASE WHEN channel IS NULL THEN 1 ELSE 0 END 把 NULL 排到末尾，
-- 对齐 ClickHouse 默认 NULL 末尾顺序。非 RTB 的 510/1010 是顺延前基础值，detail_sorted 再加偏移。
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
-- 仅非 RTB 明细加 RTB_Offset（RTB 明细已在 500 段内自然排好）；COALESCE 把无偏移平台的 NULL 取 0。
-- 此处用尚未覆盖为平台 Total 的父级标识识别 RTB 明细，明细最终排序在此定稿供 Scope 与输出共用。
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
-- 11 个 UNION ALL 分支：每个汇总 Scope 按其口径收集底层明细成员（同一 ID 可归属多个 Scope）。
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
-- 关键去重：同一 Scope 内同一 Channel_ID 可能对应多个排序值，取 MIN(Channel_Sort) 定位首次出现。
-- 等价于原 ClickHouse 'arraySort(排序元组) → arrayMap 取 ID → arrayDistinct 按首次出现去重'。
scope_first AS (
    SELECT Scope_ID, Channel_ID, MIN(Channel_Sort) AS First_Sort
    FROM scope_members
    GROUP BY Scope_ID, Channel_ID
),
dynamic_scope AS (
    SELECT Scope_ID AS Channel_ID,
        -- MySQL 有序字符串聚合：GROUP_CONCAT(表达式 ORDER BY ... SEPARATOR '|')，分隔符用 SEPARATOR 关键字。
        -- 入参已在 scope_first 去重，无需 DISTINCT；默认 group_concat_max_len=1024 字节，须先在同会话调大以防截断。
        GROUP_CONCAT(Channel_ID ORDER BY First_Sort, Channel_ID SEPARATOR '|') AS Summary_Scope
    FROM scope_first
    GROUP BY Scope_ID
),
-- 11 条写死的 SUMMARY 行：Channel_Sort 为 500 的倍数（JD 扩展汇总用 501），Summary_Scope 置空待动态匹配。
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
-- SUMMARY 关联动态 Scope；COALESCE(..., '') 保证无成员的汇总行 Scope 为空字符串而非 NULL。
summary_data AS (
    SELECT s.Platform, s.Platform_Sort, s.Channel, s.Channel_Sort, s.Channel_Label,
        s.Channel_Description, s.Channel_Type, s.Channel_ID,
        COALESCE(d.Summary_Scope, '') AS Summary_Scope, s.Parent_Channel_ID
    FROM summary_base s
    LEFT JOIN dynamic_scope d ON s.Channel_ID = d.Channel_ID
)
-- 最终输出：明细排序已定稿，此处仅给所有 SUMMARY 行加 RTB_Offset，再按 Platform_Sort,Channel_Sort 打 Channel_PK。
-- Parent_Channel_ID 统一强制为 TM_Total / JD_Total，不输出中间分类父级；JD 标签追加的控制字符见各版本 CHAR 注释。
SELECT
    ROW_NUMBER() OVER (ORDER BY Platform_Sort, Channel_Sort) AS Channel_PK,
    Platform, Platform_Sort, Channel, Channel_Sort,
    CASE WHEN Platform = 'TM' THEN Channel_Label
        -- CHAR(11 USING utf8mb4) 保留原 ClickHouse CHAR(8203) 的实际字节 0x0B（8203 溢出 UInt8 后为 11），仅 JD 标签追加。
        ELSE CONCAT(Channel_Label, CHAR(11 USING utf8mb4)) END AS Channel_Label,
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

## 4. 版本 B — Hive 4.1+ / Spark SQL 3.x+

仅在实际由 Hive / Spark SQL 执行查询时使用；当前返回 `No matching function with signature: collect_list(struct<...>)` 的 ODBC 连接不要继续使用本段，确认 Doris 后改用 §5 的完整 SQL。

先按每个 ID 的最小排序值构造 struct，再对聚合结果排序，最后取 `member_id` 数组。不能直接 `concat_ws('|', collect_set(Channel_ID))`，也不能仅在聚合前 `ORDER BY`：这些写法不能保证最终 Scope 顺序。各 UNION 分支显式保持相同列名，避免 Hive 的联合查询 schema 校验差异。

```sql
-- ============================================================================
-- 整体思路（CTE 管线）：
--   channel_source  去重渠道维度，并用嵌套 CASE 复刻 ClickHouse indexOf 的固定 RTB 顺序
--   rtb_offset      统计每平台'未枚举 RTB'数量 N，得到顺延步长 10*N
--   detail_data     计算明细基础排序（已枚举 RTB=顺序*10；未枚举 RTB 从 500 起按名称追加）
--   detail_sorted   非 RTB 明细统一加 RTB_Offset，得到明细最终排序
--   scope_members   11 个汇总 Scope 各自收集底层明细成员
--   scope_first     每个 (Scope_ID, Channel_ID) 取最小排序值去重
--   dynamic_scope   按排序值有序拼接成员 ID 为 '|' 分隔字符串（各引擎语法不同）
--   summary_base    11 条写死的 SUMMARY 汇总行
--   summary_data    SUMMARY 关联动态 Scope（无成员则空字符串）
--   最终 SELECT     明细+SUMMARY 合并、SUMMARY 再加偏移、打 Channel_PK 输出 11 列
-- 三段 SQL 仅数据库方言不同，业务逻辑与输出字段均与 ClickHouse 基准完全一致。
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
-- SUM(CASE WHEN ... THEN 1 ELSE 0 END) 复刻 ClickHouse countIf：按平台统计未枚举 RTB 渠道数 N，
-- 乘 10 得顺延步长 RTB_Offset=10*N，供非 RTB 明细与所有 SUMMARY 整体后移。
rtb_offset AS (
    SELECT platform,
        SUM(CASE WHEN channel_type = 'RTB' AND RTB_Order = 0 THEN 1 ELSE 0 END) * 10 AS RTB_Offset
    FROM channel_source
    GROUP BY platform
),
-- 明细基础排序：已枚举 RTB=顺序*10（10,20,...）；未枚举 RTB 从 500 起按名称升序每项 +10。
-- 所有按名称升序的窗口都用 CASE WHEN channel IS NULL THEN 1 ELSE 0 END 把 NULL 排到末尾，
-- 对齐 ClickHouse 默认 NULL 末尾顺序。非 RTB 的 510/1010 是顺延前基础值，detail_sorted 再加偏移。
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
-- 仅非 RTB 明细加 RTB_Offset（RTB 明细已在 500 段内自然排好）；COALESCE 把无偏移平台的 NULL 取 0。
-- 此处用尚未覆盖为平台 Total 的父级标识识别 RTB 明细，明细最终排序在此定稿供 Scope 与输出共用。
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
-- 11 个 UNION ALL 分支：每个汇总 Scope 按其口径收集底层明细成员（同一 ID 可归属多个 Scope）。
scope_members AS (
    SELECT 'TM_RTB Total' AS Scope_ID, Channel_ID, Channel_Sort
    FROM detail_sorted WHERE Platform = 'TM' AND Parent_Channel_ID = 'TM_RTB Total'
    UNION ALL
    SELECT 'TM_品销宝 Total' AS Scope_ID, Channel_ID, Channel_Sort
    FROM detail_sorted WHERE Platform = 'TM' AND Parent_Channel_ID = 'TM_品销宝 Total'
    UNION ALL
    SELECT 'TM_JCGP Total' AS Scope_ID, Channel_ID, Channel_Sort
    FROM detail_sorted WHERE Platform = 'TM' AND Parent_Channel_ID IN ('TM_JCGP Total')
    UNION ALL
    SELECT 'TM_Total' AS Scope_ID, Channel_ID, Channel_Sort FROM detail_sorted WHERE Platform = 'TM'
    UNION ALL
    SELECT 'TM_Total 不含JCGP' AS Scope_ID, Channel_ID, Channel_Sort
    FROM detail_sorted WHERE Platform = 'TM' AND Parent_Channel_ID NOT IN ('TM_JCGP Total')
    UNION ALL
    SELECT 'JD_RTB Total' AS Scope_ID, Channel_ID, Channel_Sort
    FROM detail_sorted WHERE Platform = 'JD' AND Parent_Channel_ID = 'JD_RTB Total'
    UNION ALL
    SELECT 'JD_RTB Total + 京选店铺' AS Scope_ID, Channel_ID, Channel_Sort
    FROM detail_sorted
    WHERE (Platform = 'JD' AND Parent_Channel_ID IN ('JD_RTB Total')) OR Channel_ID = 'JD_京选店铺'
    UNION ALL
    SELECT 'JD_Brandzone' AS Scope_ID, Channel_ID, Channel_Sort
    FROM detail_sorted WHERE Platform = 'JD' AND Parent_Channel_ID = 'JD_Brandzone'
    UNION ALL
    SELECT 'JD_JCGP Total' AS Scope_ID, Channel_ID, Channel_Sort
    FROM detail_sorted WHERE Platform = 'JD' AND Parent_Channel_ID = 'JD_JCGP Total'
    UNION ALL
    SELECT 'JD_Total' AS Scope_ID, Channel_ID, Channel_Sort FROM detail_sorted WHERE Platform = 'JD'
    UNION ALL
    SELECT 'JD_Total 不含JCGP' AS Scope_ID, Channel_ID, Channel_Sort
    FROM detail_sorted WHERE Platform = 'JD' AND Parent_Channel_ID NOT IN ('JD_JCGP Total', 'UNKNOWN')
),
-- 关键去重：同一 Scope 内同一 Channel_ID 可能对应多个排序值，取 MIN(Channel_Sort) 定位首次出现。
-- 等价于原 ClickHouse 'arraySort(排序元组) → arrayMap 取 ID → arrayDistinct 按首次出现去重'。
scope_first AS (
    SELECT Scope_ID, Channel_ID, MIN(Channel_Sort) AS First_Sort
    FROM scope_members
    GROUP BY Scope_ID, Channel_ID
),
-- Hive/Spark 无有序字符串聚合函数，改用'排序 struct 数组'思路：
-- COLLECT_LIST 把每个成员聚合成 NAMED_STRUCT('sort_key', First_Sort, 'member_id', Channel_ID)，
-- SORT_ARRAY 按 struct 字段顺序（先 sort_key 再 member_id）升序排序，得到有序成员数组 Members。
sorted_scope AS (
    SELECT Scope_ID,
        SORT_ARRAY(COLLECT_LIST(NAMED_STRUCT('sort_key', First_Sort, 'member_id', Channel_ID))) AS Members
    FROM scope_first
    WHERE Channel_ID IS NOT NULL
    GROUP BY Scope_ID
),
dynamic_scope AS (
    -- Members.member_id 是'数组<struct> 的字段投影'，一次性取出所有成员的 member_id 组成数组；
    -- CONCAT_WS('|', 数组) 再用 '|' 连接。不能直接 concat_ws('|', collect_set(...))，那样无法保证顺序。
    SELECT Scope_ID AS Channel_ID, CONCAT_WS('|', Members.member_id) AS Summary_Scope
    FROM sorted_scope
),
-- 11 条写死的 SUMMARY 行：Channel_Sort 为 500 的倍数（JD 扩展汇总用 501），Summary_Scope 置空待动态匹配。
summary_base AS (
    SELECT 'TM' AS Platform, 1 AS Platform_Sort, 'RTB Total' AS Channel, 500 AS Channel_Sort, 'RTB Total' AS Channel_Label,
        'TM平台-RTB合计：直通车 + 引力魔方 + 全站推/万象台 + 超级短视频 之和' AS Channel_Description, 'SUMMARY' AS Channel_Type,
        'TM_RTB Total' AS Channel_ID, NULL AS Summary_Scope, 'TM_RTB Total' AS Parent_Channel_ID
    UNION ALL
    SELECT 'TM' AS Platform, 1 AS Platform_Sort, '品销宝 Total' AS Channel, 1000 AS Channel_Sort, '品销宝 Total' AS Channel_Label,
        'TM平台-品销宝合计：品牌专区相关渠道汇总（品销宝产品线整体）' AS Channel_Description, 'SUMMARY' AS Channel_Type,
        'TM_品销宝 Total' AS Channel_ID, NULL AS Summary_Scope, 'TM_品销宝 Total' AS Parent_Channel_ID
    UNION ALL
    SELECT 'TM' AS Platform, 1 AS Platform_Sort, 'JCGP Total' AS Channel, 1500 AS Channel_Sort, 'JCGP Total' AS Channel_Label,
        'TM平台-JCGP合计：品销宝 Total + 品牌特秀（品牌类渠道整体汇总）' AS Channel_Description, 'SUMMARY' AS Channel_Type,
        'TM_JCGP Total' AS Channel_ID, NULL AS Summary_Scope, 'TM_JCGP Total' AS Parent_Channel_ID
    UNION ALL
    SELECT 'TM' AS Platform, 1 AS Platform_Sort, 'Total' AS Channel, 2000 AS Channel_Sort, 'Total' AS Channel_Label,
        'TM平台-全渠道合计：RTB Total + JCGP Total，即 TM 平台所有渠道总和' AS Channel_Description, 'SUMMARY' AS Channel_Type,
        'TM_Total' AS Channel_ID, NULL AS Summary_Scope, 'TM_Total' AS Parent_Channel_ID
    UNION ALL
    SELECT 'TM' AS Platform, 1 AS Platform_Sort, 'Total 不含JCGP' AS Channel, 2500 AS Channel_Sort, 'Total 不含JCGP' AS Channel_Label,
        'TM平台-全渠道合计（剔除JCGP）：Total - JCGP Total，即纯效果类渠道（RTB类）合计' AS Channel_Description, 'SUMMARY' AS Channel_Type,
        'TM_Total 不含JCGP' AS Channel_ID, NULL AS Summary_Scope, 'TM_Total 不含JCGP' AS Parent_Channel_ID
    UNION ALL
    SELECT 'JD' AS Platform, 2 AS Platform_Sort, 'RTB Total' AS Channel, 500 AS Channel_Sort, 'RTB Total ' AS Channel_Label,
        'JD平台-RTB合计：快车 + 触点 + 海投 + 直投 之和' AS Channel_Description, 'SUMMARY' AS Channel_Type,
        'JD_RTB Total' AS Channel_ID, NULL AS Summary_Scope, 'JD_RTB Total' AS Parent_Channel_ID
    UNION ALL
    SELECT 'JD' AS Platform, 2 AS Platform_Sort, 'RTB Total + 京选店铺' AS Channel, 501 AS Channel_Sort, 'RTB Total + 京选店铺' AS Channel_Label,
        'JD平台-RTB合计（含京选店铺）：RTB Total + 京选店铺，含京选店铺口径的效果类汇总' AS Channel_Description, 'SUMMARY' AS Channel_Type,
        'JD_RTB Total + 京选店铺' AS Channel_ID, NULL AS Summary_Scope, 'JD_RTB Total + 京选店铺' AS Parent_Channel_ID
    UNION ALL
    SELECT 'JD' AS Platform, 2 AS Platform_Sort, 'Brandzone' AS Channel, 1000 AS Channel_Sort, 'Brandzone' AS Channel_Label,
        'JD平台-Brandzone汇总：所有Brandzone类型的品牌展示广告渠道汇总' AS Channel_Description, 'SUMMARY' AS Channel_Type,
        'JD_Brandzone' AS Channel_ID, NULL AS Summary_Scope, 'JD_Brandzone' AS Parent_Channel_ID
    UNION ALL
    SELECT 'JD' AS Platform, 2 AS Platform_Sort, 'JCGP Total' AS Channel, 1500 AS Channel_Sort, 'JCGP Total ' AS Channel_Label,
        'JD平台-JCGP合计：品牌类渠道整体汇总（不含Brandzone）' AS Channel_Description, 'SUMMARY' AS Channel_Type,
        'JD_JCGP Total' AS Channel_ID, NULL AS Summary_Scope, 'JD_JCGP Total' AS Parent_Channel_ID
    UNION ALL
    SELECT 'JD' AS Platform, 2 AS Platform_Sort, 'Total' AS Channel, 2500 AS Channel_Sort, 'Total ' AS Channel_Label,
        'JD平台-全渠道合计：RTB Total + Brandzone + JCGP Total，即 JD 平台所有渠道总和' AS Channel_Description, 'SUMMARY' AS Channel_Type,
        'JD_Total' AS Channel_ID, NULL AS Summary_Scope, 'JD_Total' AS Parent_Channel_ID
    UNION ALL
    SELECT 'JD' AS Platform, 2 AS Platform_Sort, 'Total 不含JCGP' AS Channel, 3000 AS Channel_Sort, 'Total 不含JCGP ' AS Channel_Label,
        'JD平台-全渠道合计（剔除JCGP）：Total - JCGP Total，纯效果类渠道（RTB类）合计' AS Channel_Description, 'SUMMARY' AS Channel_Type,
        'JD_Total 不含JCGP' AS Channel_ID, NULL AS Summary_Scope, 'JD_Total 不含JCGP' AS Parent_Channel_ID
),
-- SUMMARY 关联动态 Scope；COALESCE(..., '') 保证无成员的汇总行 Scope 为空字符串而非 NULL。
summary_data AS (
    SELECT s.Platform, s.Platform_Sort, s.Channel, s.Channel_Sort, s.Channel_Label,
        s.Channel_Description, s.Channel_Type, s.Channel_ID,
        COALESCE(d.Summary_Scope, '') AS Summary_Scope, s.Parent_Channel_ID
    FROM summary_base s
    LEFT JOIN dynamic_scope d ON s.Channel_ID = d.Channel_ID
)
-- 最终输出：明细排序已定稿，此处仅给所有 SUMMARY 行加 RTB_Offset，再按 Platform_Sort,Channel_Sort 打 Channel_PK。
-- Parent_Channel_ID 统一强制为 TM_Total / JD_Total，不输出中间分类父级；JD 标签追加的控制字符见各版本 CHAR 注释。
SELECT
    ROW_NUMBER() OVER (ORDER BY Platform_Sort, Channel_Sort) AS Channel_PK,
    Platform, Platform_Sort, Channel, Channel_Sort,
    CASE WHEN Platform = 'TM' THEN Channel_Label
        -- Hive/Spark 的字符函数是 CHR（不是 CHAR）；CHR(11) 同样保留原 ClickHouse CHAR(8203) 的实际字节 0x0B。
        ELSE CONCAT(Channel_Label, CHR(11)) END AS Channel_Label,
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

## 5. 版本 C — Apache Doris 3.x（MySQL ODBC 协议）

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
--   dynamic_scope   按排序值有序拼接成员 ID 为 '|' 分隔字符串（各引擎语法不同）
--   summary_base    11 条写死的 SUMMARY 汇总行
--   summary_data    SUMMARY 关联动态 Scope（无成员则空字符串）
--   最终 SELECT     明细+SUMMARY 合并、SUMMARY 再加偏移、打 Channel_PK 输出 11 列
-- 三段 SQL 仅数据库方言不同，业务逻辑与输出字段均与 ClickHouse 基准完全一致。
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
-- SUM(CASE WHEN ... THEN 1 ELSE 0 END) 复刻 ClickHouse countIf：按平台统计未枚举 RTB 渠道数 N，
-- 乘 10 得顺延步长 RTB_Offset=10*N，供非 RTB 明细与所有 SUMMARY 整体后移。
rtb_offset AS (
    SELECT platform,
        SUM(CASE WHEN channel_type = 'RTB' AND RTB_Order = 0 THEN 1 ELSE 0 END) * 10 AS RTB_Offset
    FROM channel_source
    GROUP BY platform
),
-- 明细基础排序：已枚举 RTB=顺序*10（10,20,...）；未枚举 RTB 从 500 起按名称升序每项 +10。
-- 所有按名称升序的窗口都用 CASE WHEN channel IS NULL THEN 1 ELSE 0 END 把 NULL 排到末尾，
-- 对齐 ClickHouse 默认 NULL 末尾顺序。非 RTB 的 510/1010 是顺延前基础值，detail_sorted 再加偏移。
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
-- 仅非 RTB 明细加 RTB_Offset（RTB 明细已在 500 段内自然排好）；COALESCE 把无偏移平台的 NULL 取 0。
-- 此处用尚未覆盖为平台 Total 的父级标识识别 RTB 明细，明细最终排序在此定稿供 Scope 与输出共用。
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
-- 11 个 UNION ALL 分支：每个汇总 Scope 按其口径收集底层明细成员（同一 ID 可归属多个 Scope）。
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
-- 关键去重：同一 Scope 内同一 Channel_ID 可能对应多个排序值，取 MIN(Channel_Sort) 定位首次出现。
-- 等价于原 ClickHouse 'arraySort(排序元组) → arrayMap 取 ID → arrayDistinct 按首次出现去重'。
scope_first AS (
    SELECT Scope_ID, Channel_ID, MIN(Channel_Sort) AS First_Sort
    FROM scope_members
    GROUP BY Scope_ID, Channel_ID
),
dynamic_scope AS (
    SELECT Scope_ID AS Channel_ID,
        -- Doris 有序字符串聚合：GROUP_CONCAT(表达式, 分隔符 ORDER BY ...)，分隔符 '|' 是第二个位置参数，
        -- 不支持 MySQL 的 SEPARATOR 关键字；入参已在 scope_first 去重，无需 DISTINCT，避免 DISTINCT+ORDER BY 版本差异。
        GROUP_CONCAT(Channel_ID, '|' ORDER BY First_Sort, Channel_ID) AS Summary_Scope
    FROM scope_first
    GROUP BY Scope_ID
),
-- 11 条写死的 SUMMARY 行：Channel_Sort 为 500 的倍数（JD 扩展汇总用 501），Summary_Scope 置空待动态匹配。
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
-- SUMMARY 关联动态 Scope；COALESCE(..., '') 保证无成员的汇总行 Scope 为空字符串而非 NULL。
summary_data AS (
    SELECT s.Platform, s.Platform_Sort, s.Channel, s.Channel_Sort, s.Channel_Label,
        s.Channel_Description, s.Channel_Type, s.Channel_ID,
        COALESCE(d.Summary_Scope, '') AS Summary_Scope, s.Parent_Channel_ID
    FROM summary_base s
    LEFT JOIN dynamic_scope d ON s.Channel_ID = d.Channel_ID
)
-- 最终输出：明细排序已定稿，此处仅给所有 SUMMARY 行加 RTB_Offset，再按 Platform_Sort,Channel_Sort 打 Channel_PK。
-- Parent_Channel_ID 统一强制为 TM_Total / JD_Total，不输出中间分类父级；JD 标签追加的控制字符见各版本 CHAR 注释。
SELECT
    ROW_NUMBER() OVER (ORDER BY Platform_Sort, Channel_Sort) AS Channel_PK,
    Platform, Platform_Sort, Channel, Channel_Sort,
    CASE WHEN Platform = 'TM' THEN Channel_Label
        -- CHAR(11) 保留原 ClickHouse CHAR(8203) 的实际字节 0x0B（8203 溢出 UInt8 后为 11），仅 JD 标签追加。
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

## 6. 验证要求

### 6.1 逻辑对照

| 场景 | 预期 |
| --- | --- |
| TM/JD 只有已枚举 RTB | 明细顺序分别为 10～60、10～90；RTB Total=500 |
| 某平台新增 N 个未枚举 RTB | 从 500 到 500+10×(N−1)；RTB Total=500+10×N |
| N=12 | 新增 RTB 为 500～610；RTB Total=620；下一组原 510 的明细变为 630 |
| 原始事实记录重复 | 相同 platform/channel/channel_type 只生成一条明细 |
| 同一 Channel_ID 属于多个类别 | 明细仍分别保留；同一 Scope 的 ID 只出现一次，按最小排序值定位 |
| JD_京选店铺 属于非 RTB | 扩展 RTB 汇总仍包含它；普通 RTB Total 不额外包含它 |
| 平台无明细 / 数据源为空 | 固定 11 条 SUMMARY 仍保留，对应 Summary_Scope 为空字符串 |
| 渠道名为 NULL | 保留原取数范围，参与未枚举计数，名称窗口中排最后；NULL ID 不拼入 Scope |
| 大小写或尾随空格不同的渠道名 | 按原 ClickHouse 字符串比较区分，不随 MySQL 默认排序规则合并 |
| JD 标签末尾字符 | 十六进制末尾为 0B；原标签已有空格仍在 0B 之前 |
| 超过 1024 字节的 Scope | MySQL 调整同会话上限后完整输出，不得截断 |

### 6.2 数据库验收

1. 对同一份数据分别执行原引擎查询和目标版本，核对 11 个输出字段、行数、SUMMARY 文案以及每个平台的 Channel_Sort。
2. Summary_Scope 同时比较成员集合和完整字符串顺序，不能只比较成员数；不要先拆分再排序掩盖顺序差异。
3. MySQL 查询后检查截断警告以及最长 Scope 的实际字节数；确认 Power BI 刷新使用的连接也应用了相同会话参数。
4. 同排序值记录比较业务列集合；不将原 SQL 未定义的并列 Channel_PK 分配视为迁移保证。
5. 本文件不读取实时 cost_amt、不改变视觉过滤；仍在报表中验证原有渠道显示/隐藏行为。

### 6.3 已完成的本地检查

- 634 项断言通过：三段查询结构、11 个输出字段、11 组 Scope 筛选、11 条 SUMMARY 原始字面量（含尾随空格）、每版 15 项固定渠道映射。
- 500 组合成 Scope 数据对比“排序元组后按 ID 首次去重”与“按 ID 取最小排序值后拼接”，结果一致；覆盖重复、空集合、NULL ID、大小写、尾随空格和含分隔符的名称。
- 检查 N=0/1/2/12/60/120 的追加与顺延公式、超过 1024 字节的 Scope 样例以及 JD 标签末字节。

验证边界：未连接用户数据库，目标引擎的实际解析、执行、数据规模和 Power BI 刷新仍需在对应环境验收；本地静态核对与合成数据模拟不等于数据库执行通过。

## 7. 官方依据

- [MySQL 8.0 聚合函数与 GROUP_CONCAT 限制](https://dev.mysql.com/doc/refman/8.0/en/aggregate-functions.html)
- [Hive 集合、字符串函数](https://hive.apache.org/docs/latest/language/languagemanual-udf/)
- [Hive 复杂数据类型与字段访问](https://hive.apache.org/docs/latest/language/languagemanual-types/)
- [Hive struct 数组字段访问优化器修正](https://issues.apache.org/jira/browse/HIVE-28408)
- [Spark SQL 函数参考](https://archive.apache.org/dist/spark/docs/2.4.8/api/sql/index.html)
- [Doris MySQL 协议连接](https://doris.apache.org/docs/4.x/connection-integration/mysql-proto/)
- [Doris GROUP_CONCAT](https://doris.apache.org/docs/3.x/sql-manual/sql-functions/aggregate-functions/group-concat/)
- [Doris CHAR](https://doris.apache.org/docs/3.x/sql-manual/sql-functions/scalar-functions/string-functions/char/)
- [ClickHouse char 参数转换语义](https://clickhouse.com/docs/sql-reference/functions/encoding-functions#char)
