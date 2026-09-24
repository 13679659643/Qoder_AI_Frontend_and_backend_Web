# Media_Mix_matrix_solution 增量

仅新增一个视觉对象筛选度量，原有 13 项指标、数值度量、显示度量和汇总口径均不修改。

已确认口径：**以本期 This Year 的 13 个指标之和判断；和为 0 时，隐藏整个 RTB 明细渠道及其 This Year、Last Year、YOY 子行。** 即使同期有值，本期满足隐藏条件时也隐藏整个渠道。

## 1. 新增度量值

在原方案度量值区域追加以下度量，无需替换任何原有度量。

```dax
Media Mix RTB Row Visible =
// ========================================
// 度量值: Media Mix RTB Row Visible
// 中文名: Media Mix RTB 明细渠道可见性
// Display Folder: Media Mix
// 用途: 矩阵视觉对象筛选器，1=保留，0=隐藏。
// 口径: 本期 13 个指标的未格式化数值之和为 0，隐藏整个 RTB 明细渠道。
//       BLANK 按 0 参与求和；非 RTB 明细及 SUMMARY 行不受此规则影响。
// 差异: 仅新增行筛选，不改变原有指标计算或汇总口径。
// 依赖: [Media Mix Cell Value]、Dim_Media_Mix_Channel、
//       DIM_ColMetric_Media_Mix、DIM_RowKPIs_Media_Mix。
// ========================================
    // ① 读取当前矩阵行的属性。
    // SELECTEDVALUE：当前筛选上下文中只有一个不同值时返回该值，否则默认返回 BLANK。
    // Channel_ID 用于成员判断；Channel_Label 仅用于展示及识别矩阵层级。
    VAR __Platform =
        SELECTEDVALUE(Dim_Media_Mix_Channel[Platform])
    VAR __ChannelID =
        SELECTEDVALUE(Dim_Media_Mix_Channel[Channel_ID])
    VAR __ChannelType =
        SELECTEDVALUE(Dim_Media_Mix_Channel[Channel_Type])

    // ② 查找同平台 RTB Total 汇总行包含的全部明细 Channel_ID。
    // 最终 Parent_Channel_ID 已统一为平台 Total，改从 RTB Total 的 Scope 识别成员。
    // ALL 临时移除渠道维度筛选，否则当前明细行会阻止查到 RTB Total 汇总行。
    // FILTER 再定位到 __Platform 对应的 SUMMARY 行，如 TM_RTB Total。
    // 此处的 ALL 仅服务于 Scope 查询，不会清除后续指标求和中的当前渠道筛选。
    // SELECTEDVALUE 的备用值为 ""：查不到唯一 Scope 时返回空字符串。
    VAR __RTBScope =
        CALCULATE(
            SELECTEDVALUE(Dim_Media_Mix_Channel[Summary_Scope], ""),
            FILTER(
                ALL(Dim_Media_Mix_Channel),
                Dim_Media_Mix_Channel[Platform] = __Platform
                    && Dim_Media_Mix_Channel[Channel_Type] = "SUMMARY"
                    && Dim_Media_Mix_Channel[Channel_ID] = __Platform & "_RTB Total"
            )
        )
    // ③ 判断当前行是否是本次需要检查零值的 RTB 明细；四个条件必须同时成立。
    VAR __IsRTBDetail =
        // ISINSCOPE：当前矩阵分组是否包含 Channel_Label 层级。
        // 渠道行及其 This Year / Last Year / YOY 子行均为 TRUE；平台小计为 FALSE。
        ISINSCOPE(Dim_Media_Mix_Channel[Channel_Label])
            // 业务行类型必须是 DETAIL，避免把 RTB Total 等 SUMMARY 行当作明细。
            && __ChannelType = "DETAIL"
            // 必须能取得当前渠道 ID，防止无唯一渠道时继续按成员身份判断。
            && NOT ISBLANK(__ChannelID)
            // PATHCONTAINS(path, item)：检查以 | 分隔的文本中是否包含完整成员 item。
            // 此处 path=RTB Total 的 Summary_Scope，item=当前行的 Channel_ID。
            // 例：Scope="TM_直通车|TM_引力魔方"，查找 "TM_直通车" 为 TRUE，"TM_直" 为 FALSE。
            // 这里借用其成员匹配能力，不是在计算父子层级，也不要求 Scope 来自 PATH 函数。
            && PATHCONTAINS(__RTBScope, __ChannelID)

    RETURN
        IF(
            // NOT 是布尔取反：不是 RTB 明细时为 TRUE，是 RTB 明细时为 FALSE。
            // IF(条件, TRUE 分支, FALSE 分支)：非目标行直接返回 1，目标行才按本期和判断。
            NOT(__IsRTBDetail),
            1,
            // ④ 仅对 RTB 明细执行本期指标求和；1=保留，0=隐藏，不是指标业务值。
            // 清除当前指标列限制后逐项求和，始终读取完整的 13 项指标。
            // 用完整行维度替换当前子行筛选，使 This Year / Last Year / YOY 判断一致。
            VAR __CurrentSum13 =
                // 外层 CALCULATE 先建立下方指定的筛选上下文，再在其中计算 SUMX。
                CALCULATE(
                    // VALUES 取得去重后的指标 ID；SUMX 对每个 ID 求值后相加。
                    SUMX(
                        VALUES(DIM_ColMetric_Media_Mix[Metric_ID]),
                        // COALESCE：指标为 BLANK 时按 0 求和，不改动原度量的显示结果。
                        COALESCE(
                            // 内层 CALCULATE 将当前迭代的 Metric_ID 行上下文转换为筛选上下文，
                            // 使 Cell Value 每次读取一个指标，而不是在多指标上下文中返回空值。
                            CALCULATE([Media Mix Cell Value]),
                            0
                        )
                    ),
                    // 清除整个指标列维度的筛选，不能只清除 Metric_ID；
                    // 否则当前 Metric_Name 或排序列仍可能把求和限制在某一个指标。
                    REMOVEFILTERS(DIM_ColMetric_Media_Mix),
                    // 先移除行指标维度的全部筛选（包括子行名称及排序列），再固定为本期。
                    // 即使当前显示 Last Year / YOY，也用同一份 This Year 结果决定渠道去留。
                    // 不移除当前日期、渠道、数据口径或币种筛选。
                    FILTER(
                        ALL(DIM_RowKPIs_Media_Mix),
                        DIM_RowKPIs_Media_Mix[Indicator Type] = "This Year"
                    )
                )
            RETURN
                // 判断“和为 0”，不是“每项都为 0”；正负抵消也会隐藏，不做舍入或取绝对值。
                IF(__CurrentSum13 = 0, 0, 1)
        )
// 判断结果：
// RTB DETAIL：本期 13 项之和为 0 → 0；否则 → 1，三个时间子行使用同一结果。
// 非 RTB DETAIL / SUMMARY / 平台小计：返回 1，不新增隐藏规则。
// 注意：返回 1 仅表示本筛选器放行，其他视觉筛选器仍可能隐藏该行。
```

## 2. Power BI 配置

1. 创建上述度量，将其拖入 Media Mix 矩阵的“此视觉对象上的筛选器”。
2. 设置 `Media Mix RTB Row Visible` **等于 1**，应用筛选器。
3. 保持原矩阵配置：行是 `Platform → Channel_Label → Indicator Type`，列是 `Metric_Name`，值是 `[Media Mix Cell Display]`。新增度量不放入值区域。

## 3. 口径与验证

求和范围为现有列维度的 13 个指标：Cost、Cost%、ROI、Impression、Click、Add to Cart、Orders、GMV、CTR、CPC、CPATC、CVR、AOV。

- 复用 `[Media Mix Cell Value]` 的 This Year 分支，保留本期日期、平台、渠道、数据口径及现有币种换算；不会将 Last Year 或 YOY 加入判断。
- `REMOVEFILTERS(DIM_ColMetric_Media_Mix)` 清除指标名称、ID、排序列等筛选，同一渠道不会因当前矩阵列不同而产生不同可见性。
- `PATHCONTAINS` 对 `Summary_Scope` 中的完整 Channel_ID 判断成员关系，不按展示标签、不按固定渠道清单识别 RTB；刷新后新增 RTB 渠道自动适用。
- 严格采用“数值相加等于 0”，不改成“仅 Cost 为 0”“逐项全为 0”或“绝对值之和为 0”，不增加舍入容差。

| 行类型及数据情况 | 返回值 | 展示结果 |
|------------------|--------|----------|
| RTB 明细，本期 13 项均为 0 或 BLANK | 0 | 整个渠道及三个时间子行隐藏 |
| RTB 明细，本期和为 0、同期有值 | 0 | 整个渠道隐藏，按已确认的本期口径执行 |
| RTB 明细，Cost 为 0，但其他指标使本期总和非零 | 1 | 整个渠道保留 |
| RTB 明细，本期非零指标正负抵消后和为 0 | 0 | 整个渠道隐藏 |
| RTB 明细，本期和非零，即使同期或 YOY 为空 | 1 | 整个渠道保留 |
| 新增 RTB 明细 | 按本期和判断 | 与枚举渠道规则相同 |
| 非 RTB 明细、RTB Total 或其他 SUMMARY | 1 | 不受本次新增筛选影响 |

应用后检查：展开、折叠 RTB 渠道，三个时间子行的可见性应一致；切换本期日期或数据口径后重新判断；汇总值仍沿用原来的 `Summary_Scope` 聚合，不因视觉隐藏而改为只累加可见明细。

性能：新增筛选在 RTB 明细上迭代 13 行指标维度，不遍历整张事实表。SQL 与 DAX 均为待应用增量，实际查询兼容性和矩阵筛选效果仍需在 ClickHouse、Power BI 中验证。

## 4. 判断分支与后续扩展

### 层级与布尔判断对照

下表基于现有 `Platform → Channel_Label → Indicator Type` 行结构；RTB 成员以 Scope 查询正确为前提。

| 当前矩阵位置 | ISINSCOPE(Channel_Label) | __IsRTBDetail | NOT(__IsRTBDetail) | 执行结果 |
|--------------|-------------------------|---------------|--------------------|----------|
| 平台小计或矩阵总计 | FALSE | FALSE | TRUE | 直接返回 1 |
| RTB 明细渠道行 | TRUE | TRUE | FALSE | 按本期 13 项之和返回 0 或 1 |
| RTB 明细的 This Year / Last Year / YOY 子行 | TRUE | TRUE | FALSE | 三个子行都按本期和判断 |
| 非 RTB 的 DETAIL 渠道 | TRUE | FALSE | TRUE | 直接返回 1 |
| RTB Total 等 SUMMARY 渠道及其子行 | TRUE | FALSE | TRUE | 直接返回 1，因行类型不是 DETAIL |

`NOT(__IsRTBDetail)` 判断的是“当前行是否不属于处理对象”，不是“指标是否为 0”。只有进入 `IF` 的 FALSE 分支后，才用 `__CurrentSum13 = 0` 判断是否隐藏。

### 扩展时需要维护的位置

- **新增 RTB 渠道**：不改 DAX 渠道名单。SQL 刷新后，其 Channel_ID 纳入对应 RTB Total 的 `Summary_Scope` 即自动适用。ID 本身不能含分隔符 `|`，且 Scope 中的成员文本须与 Channel_ID 一致。
- **调整 RTB 汇总 ID 或处理其他渠道分类**：同步调整 `__RTBScope` 的汇总行定位条件；不能直接用最终 `Parent_Channel_ID` 判断 RTB。Scope 缺失或不唯一时，当前规则不会将该行识别为 RTB 明细，应先核对维度数据。
- **新增指标**：当前求和遍历整个指标维度的不同 Metric_ID，并未硬编码 1–13。增加指标配置且原数值度量支持该指标后，会自动纳入求和；若业务仍限定原 13 项，需要另行明确限制指标集合。
- **调整判断期间**：维护 `Indicator Type = "This Year"` 这一固定路由。仅删除它会使结果重新依赖当前时间子行，无法保证整个渠道统一隐藏。
- **调整矩阵行字段**：若不再用 `Channel_Label` 作渠道行头，需同步调整 `ISINSCOPE` 的字段引用，并重验渠道层及三个子行的判断。
