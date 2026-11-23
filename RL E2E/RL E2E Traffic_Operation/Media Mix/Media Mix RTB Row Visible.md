# 1、Media Mix RTB Row Visible

仅新增一个视觉对象筛选度量，原有 13 项指标、数值度量、显示度量和汇总口径均不修改。

已确认口径：**以本期 This Year 的 13 个指标之和判断；和为 0 时，隐藏整个 RTB 明细渠道及其 This Year、Last Year、YOY 子行。** 即使同期有值，本期满足隐藏条件时也隐藏整个渠道。


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

# 2、层级与布尔判断对照

下表基于现有 `Platform → Channel_Label → Indicator Type` 行结构；RTB 成员以 Scope 查询正确为前提。

| 当前矩阵位置 | ISINSCOPE(Channel_Label) | __IsRTBDetail | NOT(__IsRTBDetail) | 执行结果 |
|--------------|-------------------------|---------------|--------------------|----------|
| 平台小计或矩阵总计 | FALSE | FALSE | TRUE | 直接返回 1 |
| RTB 明细渠道行 | TRUE | TRUE | FALSE | 按本期 13 项之和返回 0 或 1 |
| RTB 明细的 This Year / Last Year / YOY 子行 | TRUE | TRUE | FALSE | 三个子行都按本期和判断 |
| 非 RTB 的 DETAIL 渠道 | TRUE | FALSE | TRUE | 直接返回 1 |
| RTB Total 等 SUMMARY 渠道及其子行 | TRUE | FALSE | TRUE | 直接返回 1，因行类型不是 DETAIL |

`NOT(__IsRTBDetail)` 判断的是“当前行是否不属于处理对象”，不是“指标是否为 0”。只有进入 `IF` 的 FALSE 分支后，才用 `__CurrentSum13 = 0` 判断是否隐藏。

# 3、Media Mix Cost Row Visible（v2.1 增量：Cost=0 行隐藏，按视觉周期自适应）

> 本节为需求变更新增，独立成节；第 1、2 节的原度量 [Media Mix RTB Row Visible]
> 及其口径、注释**保持原样不做任何修改**，保留在模型中随时可回退。

需求变化：不再以“本期 13 项指标之和”作为 RTB 明细的隐藏依据，改为
**Cost 为 0（含 BLANK，即显示“-”）的行一律隐藏**，范围从 RTB 明细扩大到全部行：
DETAIL 明细行、SUMMARY 汇总行（含 RTB Total / JCGP Total / Total）、Platform 分组行均适用。

v2.1 修订（LP 适配）：四个表格分别通过视觉对象筛选器限定了不同的 Indicator Type，
隐藏判断**跟随各视觉对象当前限定的周期自适应**，而不是只看 This Year：

| 视觉对象筛选上下文（Indicator Type） | 判断口径 | 说明 |
|--------------------------------------|----------|------|
| This Year | 本期 Cost 为 0/BLANK → 隐藏 | 同 v2.0 |
| Last Year | **同期（LP）Cost 为 0/BLANK → 隐藏** | LP 日期覆盖与 [Media Mix Cell Value] 的 Last Year 分支同机制 |
| YOY | **同期（LP）Cost 为 0/BLANK → 隐藏** | 同期无花费时 YOY 全行显示“-”，按同期判断 |
| 未限定（完整三行矩阵或折叠行） | 本期与同期**任一非 0 即保留**，两者均为 0 才隐藏 | 兜底口径，避免折叠态误杀仅有历史花费的渠道 |

四个表格**共用同一个度量**，无需为 LP / YOY 单独建度量；
每个表格挂上 `[Media Mix Cost Row Visible] 为 1` 后，按各自筛选窗格里的周期条件自动生效。

## 3.1 度量值定义（新增，与原度量互相独立）

```dax
Media Mix Cost Row Visible =
// ========================================
// 度量值: Media Mix Cost Row Visible（v2.1 LP 适配版）
// 中文名: Media Mix Cost 行可见性（周期自适应）
// Display Folder: Media Mix
// 用途: 矩阵/表视觉对象筛选器，1=保留，0=隐藏。
// 口径（v2.1）: 按当前视觉筛选上下文中的 Indicator Type 自适应判断：
//   This Year → 本期 Cost 为 0/BLANK 隐藏；
//   Last Year → 同期(LP) Cost 为 0/BLANK 隐藏（LP 日期覆盖走 Cell Value 同机制）；
//   YOY       → 同期(LP) Cost 为 0/BLANK 隐藏（同期无花费时 YOY 全行显示“-”）；
//   未限定周期（完整三行矩阵/折叠行）→ 本期与同期任一非 0 即保留，均为 0 才隐藏。
// 适用行: DETAIL、SUMMARY（RTB Total / JCGP Total / Total）、Platform 分组行。
// 差异: 独立于 [Media Mix RTB Row Visible] 新增，不修改任何既有度量；
//       四个视觉对象筛选窗格统一挂本度量（条件=为 1），按各自周期筛选自动生效。
// 依赖: [Media Mix Cell Value]、Dim_Media_Mix_Channel、DIM_ColMetric_Media_Mix、
//       DIM_RowKPIs_Media_Mix、Dim_Date_Current、Dim_Date_Ly、
//       Slicer_DataCaliber_Selection、a05_e2e_paid_media_channel_data_d。
// ========================================
    // ① 读取当前矩阵行的属性。
    VAR __ChannelID =
        SELECTEDVALUE(Dim_Media_Mix_Channel[Channel_ID])
    VAR __Platform =
        SELECTEDVALUE(Dim_Media_Mix_Channel[Platform])
    // 判断周期来自两部分，取值一致：
    //   a) 视觉对象筛选窗格对 Indicator Type 的限定（四个表格各自的配置）；
    //   b) 完整矩阵展开时的子行上下文（This Year / Last Year / YOY 各自判断）。
    // 未限定时为 BLANK → 走“本期与同期任一非 0”兜底分支。
    VAR __Indicator =
        SELECTEDVALUE(DIM_RowKPIs_Media_Mix[Indicator Type])

    // ② 行身份判断：
    //    渠道行 = Channel_Label 层级（DETAIL 与 SUMMARY/Total 行都在此层级）；
    //    平台行 = Platform 层级且不在渠道层级（矩阵最外层分组行）；
    //    其余（如矩阵原生总计行）不新增隐藏规则。
    VAR __IsChannelRow =
        ISINSCOPE(Dim_Media_Mix_Channel[Channel_Label])
            && NOT ISBLANK(__ChannelID)
    VAR __IsPlatformRow =
        ISINSCOPE(Dim_Media_Mix_Channel[Platform])
            && NOT __IsChannelRow

    // ③ 渠道行（DETAIL / SUMMARY 通用）读取两个周期的 Cost。
    //    强制 Indicator Type 后由 [Media Mix Cell Value] 路由：
    //    DETAIL（单渠道）与 SUMMARY（Summary_Scope 枚举聚合）已有统一路径，无需区分；
    //    Last Year 分支内部自动完成 LP 日期覆盖（Dim_Date_Ly → LP 范围），
    //    因此同期判断与页面显示的 LP 数值口径完全一致。
    VAR __TYCost =
        CALCULATE(
            [Media Mix Cell Value],
            // 清除整个指标列维度的筛选（含 Metric_Name 及排序列），再固定为 Cost。
            REMOVEFILTERS(DIM_ColMetric_Media_Mix),
            DIM_ColMetric_Media_Mix[Metric_ID] = 1,
            FILTER(
                ALL(DIM_RowKPIs_Media_Mix),
                DIM_RowKPIs_Media_Mix[Indicator Type] = "This Year"
            )
        )
    VAR __LYCost =
        CALCULATE(
            [Media Mix Cell Value],
            REMOVEFILTERS(DIM_ColMetric_Media_Mix),
            DIM_ColMetric_Media_Mix[Metric_ID] = 1,
            FILTER(
                ALL(DIM_RowKPIs_Media_Mix),
                DIM_RowKPIs_Media_Mix[Indicator Type] = "Last Year"
            )
        )

    // ④ 平台分组行：断开维度在平台层级没有渠道路由（Cell Value 返回 BLANK），
    //    直接按事实表聚合两个周期；同期沿用与 Cell Value 相同的 LP 日期覆盖机制。
    VAR __TransCycle =
        SELECTEDVALUE(Slicer_DataCaliber_Selection[DataCaliber_ID], "T+1")
    VAR __LP_Start =
        MIN(Dim_Date_Ly[LY_数据日期])
    VAR __LP_End =
        MAX(Dim_Date_Ly[LY_数据日期])
    VAR __PlatformTYCost =
        CALCULATE(
            SUM(a05_e2e_paid_media_channel_data_d[cost_amt]),
            a05_e2e_paid_media_channel_data_d[platform] = __Platform,
            a05_e2e_paid_media_channel_data_d[trans_cycle] = __TransCycle
        )
    VAR __PlatformLYCost =
        IF(
            ISBLANK(__LP_Start) || ISBLANK(__LP_End),
            BLANK(),
            CALCULATE(
                SUM(a05_e2e_paid_media_channel_data_d[cost_amt]),
                a05_e2e_paid_media_channel_data_d[platform] = __Platform,
                a05_e2e_paid_media_channel_data_d[trans_cycle] = __TransCycle,
                // 与 [Media Mix Cell Value] 同期分支一致的 LP 日期覆盖：
                // 先移除本期日期筛选，再套用 LP 日期范围。
                REMOVEFILTERS(Dim_Date_Current),
                FILTER(
                    ALL(Dim_Date_Current),
                    Dim_Date_Current[数据日期] >= __LP_Start
                        && Dim_Date_Current[数据日期] <= __LP_End
                )
            )
        )

    RETURN
        IF(
            __IsChannelRow,
            // ⑤ 渠道行：按当前上下文周期自适应。
            SWITCH(
                TRUE(),
                __Indicator = "This Year",
                    // BLANK 按 0 处理；1=保留，0=隐藏，不是指标业务值。
                    IF(COALESCE(__TYCost, 0) = 0, 0, 1),
                __Indicator = "Last Year",
                    IF(COALESCE(__LYCost, 0) = 0, 0, 1),
                __Indicator = "YOY",
                    // YOY 行的 Cost 列显示“-” ⇔ 同期 Cost 为 0/BLANK，故按同期判断。
                    IF(COALESCE(__LYCost, 0) = 0, 0, 1),
                // 未限定周期（完整矩阵折叠行等）：本期与同期任一非 0 即保留。
                IF(
                    COALESCE(__TYCost, 0) = 0 && COALESCE(__LYCost, 0) = 0,
                    0,
                    1
                )
            ),
            IF(
                __IsPlatformRow,
                // ⑥ 平台分组行：与渠道行同一套周期规则，取平台合计 Cost。
                SWITCH(
                    TRUE(),
                    __Indicator = "This Year",
                        IF(COALESCE(__PlatformTYCost, 0) = 0, 0, 1),
                    __Indicator = "Last Year",
                        IF(COALESCE(__PlatformLYCost, 0) = 0, 0, 1),
                    __Indicator = "YOY",
                        IF(COALESCE(__PlatformLYCost, 0) = 0, 0, 1),
                    IF(
                        COALESCE(__PlatformTYCost, 0) = 0
                            && COALESCE(__PlatformLYCost, 0) = 0,
                        0,
                        1
                    )
                ),
                // ⑦ 矩阵原生总计行等其他位置：不新增隐藏规则。
                1
            )
        )
// 判断结果：
// 渠道行（DETAIL / SUMMARY / Total）：按所在表格限定的周期判断 Cost；
//   This Year 表 → 本期为 0 隐藏；Last Year / YOY 表 → 同期为 0 隐藏；
//   未限定周期的视图 → 两个周期均为 0 才隐藏。
// Platform 分组行：与渠道行同规则，取平台合计。
// 矩阵原生总计行：恒为 1，不受本筛选影响（如需隐藏请关闭矩阵“总计”开关）。
```

## 3.2 与原度量 [Media Mix RTB Row Visible] 的行为差异

| 行情况 | RTB Row Visible（原，保留不动） | Cost Row Visible（v2.1，新） |
|--------------------------|----------------------------------|------------------------------|
| RTB 明细，Cost=0 但其他指标非零（13 项和非零） | 保留（1） | **隐藏（0）** |
| RTB 明细，13 项正负抵消和为 0 但 Cost≠0 | 隐藏（0） | **保留（1）** |
| 非 RTB 的 DETAIL 渠道行，Cost=0 | 始终保留（1） | **隐藏（0）** |
| RTB Total / JCGP Total / Total 等 SUMMARY 行，Cost=0 | 始终保留（1） | **隐藏（0）** |
| Platform 分组行，平台整体 Cost=0 | 始终保留（1） | **隐藏（0）** |
| 本期 Cost=0 但同期有花费（LP 表格视角） | 保留（1） | **LP 表格保留（1），TY 表格隐藏（0）** |
| 本期 Cost≠0 但同期为 0（LP 表格视角，显示“-”） | 保留（1） | **LP 表格隐藏（0），TY 表格保留（1）** |
| 本期与同期 Cost 均非 0 | 按 13 项之和判断 | 保留（1） |

两个度量是口径不同的两套规则，**不要同时挂在同一个视觉对象的筛选窗格里**：
同时生效时会取两者隐藏的并集（13 项抵消为 0 的行、以及 Cost=0 的行都被隐藏），既不是旧口径也不是新口径。

## 3.3 应用步骤（四个表格统一操作，逐个执行）

四个视觉对象（表格）的操作完全相同，**不需要按周期分别配置**——
度量会自动读取每个表格筛选窗格里对 Indicator Type 的限定：

1. 选中视觉对象 → 打开“筛选器”（Filters）窗格。
2. 在窗格中**移除**原筛选字段 `[Media Mix RTB Row Visible]`（仅从窗格移除，度量本身保留在模型中，不删除、不修改）。
3. 添加 `[Media Mix Cost Row Visible]`，筛选条件设为 **为 1**（is 1）。
4. 点击“应用筛选器”，四个视觉对象逐一完成。
5. 窗格中原有的其他筛选条件（Indicator Type 限定、日期、口径等）保持不动，本次只替换可见性筛选字段。

## 3.4 回退步骤

把筛选窗格中的 `[Media Mix Cost Row Visible]` 移除，重新拖入
`[Media Mix RTB Row Visible]`，条件设为 **为 1**，即可整体回退到原口径。
两个度量互相独立，回退不需要改任何代码。

## 3.5 验证与注意事项

- **周期自适应是本版本核心**：This Year 表按本期判断，Last Year / YOY 表按同期判断；
  未限定周期的完整视图按“本期与同期任一非 0”兜底。四个表格共用一个度量，无需拆分。
- 同期（LP）判断与页面显示的 LP 数值口径一致：走 [Media Mix Cell Value] 的 Last Year
  分支，LP 日期覆盖（Dim_Date_Ly → REMOVEFILTERS + LP 范围）由其内部自动完成；
  平台行在度量内复刻同一套 LP 日期覆盖。
- LP 日期切片器未选择时，同期 Cost 视为 BLANK → Last Year / YOY 表格整表隐藏（全行“-”，符合口径）；
  如希望“未选 LP 日期时不隐藏”，需另行确认调整。
- YOY 表格按同期判断：同期无花费时 YOY 全行显示“-”故隐藏；本期有花费、同期为 0 的渠道
  在 YOY 表格同样隐藏（其 YOY 显示为“-”）。如业务希望这类行保留显示“-100.0%”，
  把 YOY 分支改为 `IF(COALESCE(__TYCost,0)=0 && COALESCE(__LYCost,0)=0, 0, 1)` 即可。
- Cost 为 BLANK 按 0 处理（COALESCE）。
- 币种切换不影响判断：汇率只做等比缩放，不改变是否为 0（汇率异常为空时 Cost 显示 BLANK，会被按 0 隐藏）。
- 汇总口径不变：RTB Total 仍按 Summary_Scope 聚合全部明细，视觉隐藏不改变聚合计算。
- 父子一致性：SUMMARY 行某周期 Cost=0 ⇒ 其全部明细该周期 Cost 必为 0，父子同隐藏；
  极端场景（明细 Cost 正负抵消使 Total=0 而明细自身 Cost≠0）下，明细保留、Total 行隐藏，以“行为单位各自判断”为准。
- 矩阵原生“总计”行恒显示（返回 1）；如需一并隐藏，关闭矩阵格式的“总计”开关。
- 性能：渠道行执行 2 次 Cell Value 计算（本期 + 同期，各固定 Cost），平台行执行 2 次事实表 SUM，
  均为标量聚合，开销低于原度量的 13 项 SUMX 迭代。

