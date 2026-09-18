# KPIs Measure：分组 Top10 与矩阵花费占比

## 1. 适用范围与配置

- 引力魔方／触点：行层级为 `customer_type / crowed_layer / crowed_type`；每个 `customer_type + crowed_layer` 组分别取 `crowed_type` Top10。
- 直通车／快车：行层级为 `TTL / customer_type / category / keyword_type / keyword_name`；每个 `customer_type + category + keyword_type` 组分别取 `keyword_name` Top10。
- 排名按 Cost 降序、SKIP 跳跃排名，保留排名 ≤10 的全部并列；单组可超过 10 行，矩阵总行数不限制为 10。
- 对应矩阵配置 `Top10 Show Row = 1`，按数值 Cost 降序排序，关闭“显示无数据的项”；末级字段不叠加原生“Top N／前 10 项”筛选。
- Cost% = 当前行 Cost ÷ 整个矩阵入选明细的 Cost 总额。所有层级使用同一分母，分母非零时矩阵总计为 100%；父组不要求各自为 100%。
- 本文件收录 9 个度量；依赖模型中的 Cost Value、ROI Value、日期及币种切片器。Cost% Display 继续引用同名 Value，格式为百分比一位小数。
- 使用字段有效性及零值筛选时，分别配置对应度量等于 1；两个 `IsZero` 的判定独立于展示 Cost%。

## 2. 度量值实现

### 2.4 Cost% — 引力魔方（#8）

```dax
Cost% 引力魔方 Value =
// ========================================
// 度量值: Cost% 引力魔方 Value
// 中文名: 引力魔方／触点矩阵花费占比
// Display Folder: KPIs Measure
// 用途: 当前行 Cost / 整个矩阵入选明细的 Cost 总额
// 数据底表: a05_e2e_paid_media_crowed_data_d
// 行层级: customer_type / crowed_layer / crowed_type
// 筛选条件: channel IN {"引力魔方", "触点"}；本期日期范围
// 口径说明: ALLSELECTED 恢复视觉外层选择，所有父组共用一个分母
// 数据类型: percent_1dp；分子分母均用人民币原值，比值不需要汇率转换
// ========================================
    VAR __TimeMin = SELECTEDVALUE(Slicer_Time_Frame_Min[TimeFrame_Min])
    VAR __TimeMax = SELECTEDVALUE(Slicer_Time_Frame_Max[TimeFrame_Max])
    // ── 分子：当前明细、父级或总计上下文中的 Cost ──
    VAR __Numerator =
        CALCULATE(
            SUM('a05_e2e_paid_media_crowed_data_d'[cost_amt]),
            'a05_e2e_paid_media_crowed_data_d'[channel] IN {"引力魔方", "触点"},
            'a05_e2e_paid_media_crowed_data_d'[data_date] >= __TimeMin,
            'a05_e2e_paid_media_crowed_data_d'[data_date] <= __TimeMax
        )
    // ── 分母：解除当前行定位，保留视觉外层入选组合及切片器筛选 ──
    VAR __Denominator =
        CALCULATE(
            SUM('a05_e2e_paid_media_crowed_data_d'[cost_amt]),
            'a05_e2e_paid_media_crowed_data_d'[channel] IN {"引力魔方", "触点"},
            'a05_e2e_paid_media_crowed_data_d'[data_date] >= __TimeMin,
            'a05_e2e_paid_media_crowed_data_d'[data_date] <= __TimeMax,
            ALLSELECTED(
                'a05_e2e_paid_media_crowed_data_d'[customer_type],
                'a05_e2e_paid_media_crowed_data_d'[crowed_layer],
                'a05_e2e_paid_media_crowed_data_d'[crowed_type]
            )
        )
    RETURN
        DIVIDE(__Numerator, __Denominator)
// 各层级分母一致，不是当前父组 Top10 合计；总计由实际分子/分母计算，不硬编码 1。
// 分母为 0 或 BLANK() 时返回 BLANK()；验证方式与视觉总计适用条件见第 3 节。
```

### 2.8 Cost% — 直通车（#12）

```dax
Cost% 直通车 Value =
// ========================================
// 度量值: Cost% 直通车 Value
// 中文名: 直通车／快车各行层级花费占比
// Display Folder: KPIs Measure
// 用途: 当前行 Cost / 整个矩阵入选明细的 Cost 总额
// 数据底表: a05_e2e_paid_media_keyword_data_d
// 筛选条件: channel IN {"直通车", "快车"}；本期日期范围
// 行层级: TTL / customer_type / category / keyword_type / keyword_name
// 口径说明: ALLSELECTED 恢复视觉外层选择，所有父组共用一个分母
// 数据类型: percent_1dp；分子分母均用人民币原值，比值不需要汇率转换
// ========================================
    // ── 时间筛选：本期 ──
    VAR __TimeMin = SELECTEDVALUE(Slicer_Time_Frame_Min[TimeFrame_Min])
    VAR __TimeMax = SELECTEDVALUE(Slicer_Time_Frame_Max[TimeFrame_Max])
    // ── 分子：当前行层级直通车／快车 Cost ──
    VAR __Numerator =
        CALCULATE(
            SUM('a05_e2e_paid_media_keyword_data_d'[cost_amt]),
            'a05_e2e_paid_media_keyword_data_d'[channel] IN {"直通车", "快车"},
            'a05_e2e_paid_media_keyword_data_d'[data_date] >= __TimeMin,
            'a05_e2e_paid_media_keyword_data_d'[data_date] <= __TimeMax
        )
    // ── 分母：解除当前行定位，保留视觉外层入选组合及切片器筛选 ──
    VAR __Denominator =
        CALCULATE(
            SUM('a05_e2e_paid_media_keyword_data_d'[cost_amt]),
            'a05_e2e_paid_media_keyword_data_d'[channel] IN {"直通车", "快车"},
            'a05_e2e_paid_media_keyword_data_d'[data_date] >= __TimeMin,
            'a05_e2e_paid_media_keyword_data_d'[data_date] <= __TimeMax,
            ALLSELECTED(
                'a05_e2e_paid_media_keyword_data_d'[customer_type],
                'a05_e2e_paid_media_keyword_data_d'[category],
                'a05_e2e_paid_media_keyword_data_d'[keyword_type],
                'a05_e2e_paid_media_keyword_data_d'[keyword_name]
            )
        )
    RETURN
        DIVIDE(__Numerator, __Denominator)
// 各层级分母一致，不是当前父组 Top10 合计；总计由实际分子/分母计算，不硬编码 1。
// 分母为 0 或 BLANK() 时返回 BLANK()；验证方式与视觉总计适用条件见第 3 节。
```

### 2.11 字段筛选任一不为空且非空字符串，即显示

```dax
IsAnyKeywordNotEmpty =
// ========================================
// 度量值: IsAnyKeywordNotEmpty
// 中文名: 直通车／快车行字段有效性筛选
// Display Folder: KPIs Measure
// 用途: 四个行字段中任一字段有效即显示，返回 1 或 0
// 口径说明: 四个行字段采用 OR 判断；keyword_name 使用 TRIM 排除空白字符串
// ========================================
    // ── 获取当前行上下文中的字段值 ──
    VAR CustomerTypeValue = MAX('a05_e2e_paid_media_keyword_data_d'[customer_type])
    VAR CategoryValue = MAX('a05_e2e_paid_media_keyword_data_d'[category])
    VAR KeywordTypeValue = MAX('a05_e2e_paid_media_keyword_data_d'[keyword_type])
    VAR KeywordNameValue = MAX('a05_e2e_paid_media_keyword_data_d'[keyword_name])
    // ── 判断各字段有效性 ──
    VAR IsCustomerTypeValid = NOT ISBLANK(CustomerTypeValue) && CustomerTypeValue <> ""
    VAR IsCategoryValid = NOT ISBLANK(CategoryValue) && CategoryValue <> ""
    VAR IsKeywordTypeValid = NOT ISBLANK(KeywordTypeValue) && KeywordTypeValue <> ""
    VAR IsKeywordNameValid =
        NOT ISBLANK(KeywordNameValue)
            && TRIM(KeywordNameValue) <> ""
            && TRIM(KeywordNameValue) <> " "
    // ── 并集（OR）：任一字段有效即显示 ──
    RETURN
        IF(
            IsCustomerTypeValid || IsCategoryValid || IsKeywordTypeValid || IsKeywordNameValid,
            1,
            0
        )
// 核对点：仅 keyword_type 非空时返回 1；四个行字段全部无效时返回 0。
// 本度量只负责字段有效性，不承担 Top10 筛选。
```

### 2.12 指标加和为零的行过滤

```dax
引力魔方 IsZero =
// ========================================
// 度量值: 引力魔方 IsZero
// 中文名: 引力魔方／触点零值行筛选
// Display Folder: KPIs Measure
// 用途: Cost + 筛选专用花费占比 + ROI 为 0 时返回 0，否则返回 1
// 依赖: [Cost 引力魔方 Value]、[ROI 引力魔方 Value]
// 口径说明: 筛选专用占比分母为当前渠道的全行维度 Cost，独立于展示 Cost%
//           避免以依赖最终入选集合的展示占比决定行是否入选
// ========================================
    VAR __Cost = [Cost 引力魔方 Value]
    VAR __FilterBaseCost =
        CALCULATE(
            [Cost 引力魔方 Value],
            REMOVEFILTERS(
                'a05_e2e_paid_media_crowed_data_d'[customer_type],
                'a05_e2e_paid_media_crowed_data_d'[crowed_layer],
                'a05_e2e_paid_media_crowed_data_d'[crowed_type]
            )
        )
    // ── 本地计算筛选专用比值，不引用 [Cost% 引力魔方 Value] ──
    VAR __FilterCostShare = DIVIDE(__Cost, __FilterBaseCost)
    VAR __ROI = [ROI 引力魔方 Value]
    VAR __Total = COALESCE(__Cost, 0) + COALESCE(__FilterCostShare, 0) + COALESCE(__ROI, 0)
    RETURN
        IF(__Total = 0, 0, 1)
// 空值按 0 参与加和；这是加和判零规则，不是“任一指标非零”规则。
// 渠道、日期与币种口径由基础 Cost 度量提供；币种汇率须为有效非零值。
```

```dax
直通车 IsZero =
// ========================================
// 度量值: 直通车 IsZero
// 中文名: 直通车／快车零值行筛选
// Display Folder: KPIs Measure
// 用途: Cost + 筛选专用花费占比 + ROI 为 0 时返回 0，否则返回 1
// 依赖: [Cost 直通车 Value]、[ROI 直通车 Value]
// 口径说明: 筛选专用占比分母为当前渠道的全行维度 Cost，独立于展示 Cost%
//           仅移除四个行字段，不移除平台、店铺、日期、转化周期等筛选
// ========================================
    VAR __Cost = [Cost 直通车 Value]
    VAR __FilterBaseCost =
        CALCULATE(
            [Cost 直通车 Value],
            REMOVEFILTERS(
                'a05_e2e_paid_media_keyword_data_d'[customer_type],
                'a05_e2e_paid_media_keyword_data_d'[category],
                'a05_e2e_paid_media_keyword_data_d'[keyword_type],
                'a05_e2e_paid_media_keyword_data_d'[keyword_name]
            )
        )
    // ── 本地计算筛选专用比值，不引用 [Cost% 直通车 Value] ──
    VAR __FilterCostShare = DIVIDE(__Cost, __FilterBaseCost)
    VAR __ROI = [ROI 直通车 Value]
    VAR __Total = COALESCE(__Cost, 0) + COALESCE(__FilterCostShare, 0) + COALESCE(__ROI, 0)
    RETURN
        IF(__Total = 0, 0, 1)
// 空值按 0 参与加和；这是加和判零规则，不是“任一指标非零”规则。
// 分子分母使用相同汇率，比值与人民币计算一致；币种汇率须为有效非零值。
```

### 2.13 Cost 排名与 Top10 显示筛选 — 引力魔方／触点

```dax
Cost 引力魔方 Rank =
// ========================================
// 度量值: Cost 引力魔方 Rank
// 中文名: 引力魔方／触点人群名称花费排名
// Display Folder: KPIs Measure
// 用途: 固定 customer_type + crowed_layer，在该组内排名各 crowed_type
// 依赖: [Cost 引力魔方 Value]
// 行层级: customer_type / crowed_layer / crowed_type
// 口径说明: 每个父组独立按 Cost 降序、SKIP 排名，不计算全矩阵统一排名
// 计算方式: 显式匹配父组，按候选完整组合逐项计算 Cost
// 外部筛选: 保留平台、店铺、日期、转化周期及行字段的外部选择
// ========================================
    // ── 识别末级，并确保能唯一确定当前父组 ──
    VAR __IsDetail = ISINSCOPE('a05_e2e_paid_media_crowed_data_d'[crowed_type])
    VAR __HasParentGroup =
        HASONEVALUE('a05_e2e_paid_media_crowed_data_d'[customer_type])
            && HASONEVALUE('a05_e2e_paid_media_crowed_data_d'[crowed_layer])
    VAR __CustomerType = SELECTEDVALUE('a05_e2e_paid_media_crowed_data_d'[customer_type])
    VAR __CrowedLayer = SELECTEDVALUE('a05_e2e_paid_media_crowed_data_d'[crowed_layer])
    RETURN
        IF(
            __IsDetail && __HasParentGroup,
            VAR __CurrentCost = [Cost 引力魔方 Value]
            // ── 第一步：恢复外部选择范围内的行组合，再显式限定当前父组 ──
            VAR __GroupRows =
                FILTER(
                    ALLSELECTED(
                        'a05_e2e_paid_media_crowed_data_d'[customer_type],
                        'a05_e2e_paid_media_crowed_data_d'[crowed_layer],
                        'a05_e2e_paid_media_crowed_data_d'[crowed_type]
                    ),
                    'a05_e2e_paid_media_crowed_data_d'[customer_type] == __CustomerType
                        && 'a05_e2e_paid_media_crowed_data_d'[crowed_layer] == __CrowedLayer
                )
            // ── 第二步：清除当前明细行筛选，以候选完整组合逐行重新计算 Cost ──
            // __GroupRows 已在外部上下文中确定，不会因下方 REMOVEFILTERS 变成全表。
            // 完整列血缘 + 度量上下文转换也会覆盖同列筛选；清理步骤的作用详见第 3 节。
            VAR __RankTable =
                CALCULATETABLE(
                    FILTER(
                        ADDCOLUMNS(
                            __GroupRows,
                            "@RankCost", [Cost 引力魔方 Value]
                        ),
                        NOT ISBLANK([@RankCost])
                    ),
                    REMOVEFILTERS(
                        'a05_e2e_paid_media_crowed_data_d'[customer_type],
                        'a05_e2e_paid_media_crowed_data_d'[crowed_layer],
                        'a05_e2e_paid_media_crowed_data_d'[crowed_type]
                    )
                )
            // ── 第三步：RANKX 的候选表仅包含当前组，不会与其他父组竞争 ──
            RETURN
                IF(
                    NOT ISBLANK(__CurrentCost),
                    RANKX(__RankTable, [@RankCost], __CurrentCost, DESC, SKIP),
                    BLANK()
                ),
            BLANK()
        )
// 层级判断：crowed_type 明细且父组唯一 → 组内排名；父级／TTL → BLANK()。
// 严格相等 == 区分 BLANK() 和空字符串；不能用“父组值为空”判断是否处于父级。
// 候选表保留三列数据血缘，度量引用自动上下文转换，按完整组合计算 Cost。
// 验证：New/OA、New/I、Old/OA 各有 12 个不并列明细 → 各留 10 个，共 30 个明细。
// 同名 crowed_type 在不同父组分别排名；各组均从 1 重新开始。
// 空 Cost 不参与排名；0、负值及名称空值不额外剔除，沿用现有过滤配置。
// 单组示例：Cost=100,100,90,80,80,70 → Rank=1,1,3,4,4,6。
// 排名依据未格式化的 Cost；显示整数相同不代表实际 Cost 完全相等。
```

```dax
引力魔方 Top10 Show Row =
// ========================================
// 度量值: 引力魔方 Top10 Show Row
// 中文名: 引力魔方／触点 Top10 行显示筛选
// Display Folder: KPIs Measure
// 用途: 每个 customer_type + crowed_layer 组各留排名 ≤10 的 crowed_type；非末级返回 1
// 依赖: [Cost 引力魔方 Rank]
// 配置类型: 视觉对象级度量筛选，不作为基础 Cost 的计算条件
// 使用: 加到引力魔方／触点矩阵的“此视觉对象上的筛选器”，设置等于 1
// ========================================
    VAR __IsDetail = ISINSCOPE('a05_e2e_paid_media_crowed_data_d'[crowed_type])
    RETURN
        IF(
            NOT __IsDetail,
            1,
            VAR __Rank = [Cost 引力魔方 Rank]
            RETURN
                IF(NOT ISBLANK(__Rank) && __Rank <= 10, 1, 0)
        )
// 返回对照：父级／TTL=1；末级 Rank≤10=1；末级 Rank>10 或 BLANK()=0。
// 不直接用“Rank≤10”过滤，避免空排名在比较时被当作 0，以及父级空排名的歧义。
// 可与字段有效性及零值筛选共同使用；本度量不负责排序，请按数值 Cost 降序排序。
// 三个行层级必须使用上方事实表字段；若改用独立维表，需同步改写排名和层级判定。
// 必须保留 customer_type、crowed_layer 父组上下文；使用展开层级，不把所有父组混成单层。
// 移除 crowed_type 上额外配置的原生 Top N 筛选，仅以本度量 = 1 实施分组 Top10。
```

### 2.14 Cost 排名与 Top10 显示筛选 — 直通车／快车

```dax
Cost 直通车 Rank =
// ========================================
// 度量值: Cost 直通车 Rank
// 中文名: 直通车／快车关键词花费排名
// Display Folder: KPIs Measure
// 用途: 在每个 customer_type / category / keyword_type 组内排名 keyword_name
// 依赖: [Cost 直通车 Value]
// 行层级: TTL / customer_type / category / keyword_type / keyword_name
// 口径说明: 每个父组独立按 Cost 降序、SKIP 排名，保留全部边界并列
// 计算方式: 显式匹配 customer_type、category、keyword_type 三个父组字段
//           按候选完整组合计算 Cost，平台等非行筛选不移除
// ========================================
    VAR __IsDetail = ISINSCOPE('a05_e2e_paid_media_keyword_data_d'[keyword_name])
    VAR __HasParentGroup =
        HASONEVALUE('a05_e2e_paid_media_keyword_data_d'[customer_type])
            && HASONEVALUE('a05_e2e_paid_media_keyword_data_d'[category])
            && HASONEVALUE('a05_e2e_paid_media_keyword_data_d'[keyword_type])
    VAR __CustomerType = SELECTEDVALUE('a05_e2e_paid_media_keyword_data_d'[customer_type])
    VAR __Category = SELECTEDVALUE('a05_e2e_paid_media_keyword_data_d'[category])
    VAR __KeywordType = SELECTEDVALUE('a05_e2e_paid_media_keyword_data_d'[keyword_type])
    RETURN
        IF(
            __IsDetail && __HasParentGroup,
            VAR __CurrentCost = [Cost 直通车 Value]
            // ── 第一步：只选出当前三个父级字段组合下的关键词候选行 ──
            VAR __GroupRows =
                FILTER(
                    ALLSELECTED(
                        'a05_e2e_paid_media_keyword_data_d'[customer_type],
                        'a05_e2e_paid_media_keyword_data_d'[category],
                        'a05_e2e_paid_media_keyword_data_d'[keyword_type],
                        'a05_e2e_paid_media_keyword_data_d'[keyword_name]
                    ),
                    'a05_e2e_paid_media_keyword_data_d'[customer_type] == __CustomerType
                        && 'a05_e2e_paid_media_keyword_data_d'[category] == __Category
                        && 'a05_e2e_paid_media_keyword_data_d'[keyword_type] == __KeywordType
                )
            // ── 第二步：清理行字段上下文，再逐候选调用基础 Cost 度量 ──
            // 完整列血缘 + 度量上下文转换也会覆盖同列筛选；清理步骤的作用详见第 3 节。
            VAR __RankTable =
                CALCULATETABLE(
                    FILTER(
                        ADDCOLUMNS(
                            __GroupRows,
                            "@RankCost", [Cost 直通车 Value]
                        ),
                        NOT ISBLANK([@RankCost])
                    ),
                    REMOVEFILTERS(
                        'a05_e2e_paid_media_keyword_data_d'[customer_type],
                        'a05_e2e_paid_media_keyword_data_d'[category],
                        'a05_e2e_paid_media_keyword_data_d'[keyword_type],
                        'a05_e2e_paid_media_keyword_data_d'[keyword_name]
                    )
                )
            // ── 第三步：只在当前父组候选表中排名 ──
            RETURN
                IF(
                    NOT ISBLANK(__CurrentCost),
                    RANKX(__RankTable, [@RankCost], __CurrentCost, DESC, SKIP),
                    BLANK()
                ),
            BLANK()
        )
// 层级判断：keyword_name 明细且父组唯一 → 组内排名；其余层级 → BLANK()。
// 同名关键词在不同父组分别排名；同父组内跨 plan_name 的同名关键词合并计算 Cost。
// 候选表保存外部行字段选择；仅剔除空 Cost，不新增名称或零值过滤规则。
// 验证：同一 customer_type/category 下两个 keyword_type 各 12 项 → 各取 10 项，共 20 项。
// 排名使用未格式化 Cost；若数据库浮点精度造成“看似相等但排名不同”，需先确认金额精度口径。
// 单组示例：Cost=100,100,90,80,80,70,60,50,40,30 → Rank=1,1,3,4,4,6,7,8,9,10。
```

```dax
直通车 Top10 Show Row =
// ========================================
// 度量值: 直通车 Top10 Show Row
// 中文名: 直通车／快车 Top10 关键词行显示筛选
// Display Folder: KPIs Measure
// 用途: 仅限制 keyword_name 末级；前三层和 TTL 不按自身 Cost 排名截断
// 依赖: [Cost 直通车 Rank]
// 配置类型: 视觉对象级度量筛选，末级为 keyword_name
// 使用: 加到直通车／快车矩阵的“此视觉对象上的筛选器”，设置等于 1
// ========================================
    VAR __IsDetail = ISINSCOPE('a05_e2e_paid_media_keyword_data_d'[keyword_name])
    RETURN
        IF(
            NOT __IsDetail,
            1,
            VAR __Rank = [Cost 直通车 Rank]
            RETURN
                IF(NOT ISBLANK(__Rank) && __Rank <= 10, 1, 0)
        )
// 返回对照：父级／TTL=1；末级 Rank≤10=1；末级 Rank>10 或 BLANK()=0。
// 可与 [IsAnyKeywordNotEmpty]、[直通车 IsZero] 共同筛选。
// 视觉配置：四个行字段均使用关键词事实表，第三层为 keyword_type；按数值 Cost 降序排序。
// 保留全部三个父组字段上下文；移除 keyword_name 上额外的原生 Top N 筛选。
// 用例：父组 A 的第 1 名不与父组 B 竞争；多个组可同时展示各自的第 1～10 名。
// 两组 Top10 Show Row 各用于对应矩阵，不同时配置到同一个矩阵或页面级筛选器。
// 两组排名共同边界：前 9 行花费较高，第 10～12 行花费相同，则 12 行全部保留。
// 验收：逐级展开、切换父组和日期、测试第 10 名并列／全空／不足 10 项；关闭“显示无数据的项”。
// 注意：非末级返回 1 仅表示不按父级排名过滤；小计/TTL 仍受视觉对象入选集合影响。
// Cost% 使用矩阵视觉总额作分母；部署后按第 3 节验证小计、总计及筛选器的共同作用。
```

## 3. 计算过程与验证

### 3.1 排名第二步如何逐候选计算 Cost

以引力魔方当前单元格 `New / OA / 人群A` 为例，假设同组候选为 A、B、C，Cost 分别为 100、80、60。

1. `__CurrentCost` 在当前单元格上下文中求值，得到 100。它是固定标量，不能用它替代每个候选的 Cost。
2. `__GroupRows` 先恢复外部选择范围内的完整行组合，再筛出 `customer_type=New` 且 `crowed_layer=OA` 的组合。表中保留三个源字段及其数据血缘。
3. `CALCULATETABLE` 在三个行字段筛选被清除的环境中计算其第一个表表达式；平台、店铺等非行字段筛选不动。已经定义的 `__GroupRows` 不会重新变成所有分组。
4. `ADDCOLUMNS` 遍历候选表，每次产生一个候选组合的**行上下文**。引用 `[Cost 引力魔方 Value]` 时，DAX 自动执行上下文转换，把该组合转为**筛选上下文**，然后计算渠道与日期范围内的 Cost。
5. `FILTER` 排除 Cost 为空的候选。`RANKX` 仅比较当前组候选的数值 Cost，按 `DESC, SKIP` 产生排名。

| 当前矩阵单元格   | 正在迭代的候选组合 | 调用 Cost 度量时的行字段筛选 | @RankCost |
| ---------------- | ------------------ | ---------------------------- | --------: |
| New / OA / 人群A | New / OA / 人群A   | New / OA / 人群A             |       100 |
| New / OA / 人群A | New / OA / 人群B   | New / OA / 人群B             |        80 |
| New / OA / 人群A | New / OA / 人群C   | New / OA / 人群C             |        60 |

候选 B 计算的是 **B 的 Cost**，不是当前单元格 A 的 Cost，也不是 New/OA 整组的 Cost。直通车同理，只是候选组合有四个字段。

### 3.2 为什么去掉排名中的 REMOVEFILTERS 也可能不变

当前写法具备两个关键条件：

- `__GroupRows` 保留了参与排名的全部行字段，而且这些列带有源表数据血缘。
- `ADDCOLUMNS` 内部调用的是**度量值**，会自动触发上下文转换；当前基础 Cost 度量没有额外保留冲突行筛选的逻辑。

因此，在通常的同列筛选上下文下，迭代候选 B 时，上下文转换会用 B 的三列或四列组合覆盖同名列上的当前行定位。即使没有先执行外层 `REMOVEFILTERS`，最终计算 Cost 的组合仍然相同。

| 写法                   | 计算候选 B 的路径                                           | 此例结果 |
| ---------------------- | ----------------------------------------------------------- | -------: |
| 带外层 REMOVEFILTERS   | 清除当前行字段筛选 → 候选 B 上下文转换 → 计算 Cost        |       80 |
| 不带外层 REMOVEFILTERS | 当前 A 上下文 → 候选 B 上下文转换覆盖同列定位 → 计算 Cost |       80 |

这里保留 `REMOVEFILTERS` 是为了明确计算边界，**并非组内排名成立的必要条件**。组内范围由 `__GroupRows` 中的父组条件决定；各候选 Cost 由数据血缘与度量上下文转换决定。

这一结论不应泛化到所有迭代：若候选表遗漏行字段、表达式加工破坏血缘、存在其他排序列/关联维表筛选，或使用 `KEEPFILTERS`，筛选行为需要重新核对。若把度量引用换成裸 `SUM(cost_amt)`，则没有自动上下文转换，需要显式 `CALCULATE`。仅把外层清理删除但保留完整候选表和度量引用，是不同于这些情况的。

### 3.3 排名清理与 Cost% 分母不是同一用途

- **排名的 REMOVEFILTERS**：后面还有逐候选上下文转换，会重新施加当前候选的完整行组合。
- **Cost% 分母的 ALLSELECTED**：解除当前矩阵行的定位，恢复该视觉对象外层选择的行组合范围；分母不再被当前父组限制。
- **IsZero 的 REMOVEFILTERS**：专门计算稳定的筛选基数，不读取最终展示占比。其内部比例仅用于判零，不是矩阵展示值。

如果分子已经只包含入选 Cost，而分母放开为未入选数据也参与的全量 Cost，总计就会低于 100%。本方案中，两个 Cost% 均使用完整行字段列表的 `ALLSELECTED` 计算视觉总额，而不是只清末级或对总计硬编码 100%。

`ALLSELECTED` 恢复的是 DAX 查询的外层筛选上下文，并不是扫描屏幕。适用前提是矩阵查询将 Top10 及其他行筛选形成的完整入选组合传递到度量求值阶段。普通矩阵的视觉对象级度量筛选通常符合这一模式；折叠只是显示状态，不等于删除该组入选数据。若将本方案用于不同视觉对象、改变筛选粒度或在其他迭代器内引用 Cost%，需重新验证。

### 3.4 Cost% 数值对照

假设所有组入选明细 Cost 合计为 1,000，其中组 A 为 600，组 B 为 400，某个 A 组明细 Cost 为 100。

| 行         | 当前行 Cost | 矩阵共同分母 | Cost% |
| ---------- | ----------: | -----------: | ----: |
| A 组该明细 |         100 |        1,000 |   10% |
| A 组小计   |         600 |        1,000 |   60% |
| B 组小计   |         400 |        1,000 |   40% |
| 矩阵总计   |       1,000 |        1,000 |  100% |

- 验证未舍入的**末级明细** Cost 合计等于矩阵 Cost 总计，不要把父级与子级重复相加。
- 在不同父组检查 `当前行 Cost ÷ Cost%`：非零明细应还原同一个矩阵 Cost 总额。
- 分母非零时，未舍入的末级 Cost% 合计及矩阵总计均为 100%；父组占比不要求各为 100%。显示一位小数后，相加可能有舍入误差。
- 分母为 0 或空时，Cost% 返回空；若存在正负 Cost 抵消，不强制显示 100%。
- 测试多个父组、同名末级、第 10 名并列、日期/平台/店铺切换、外部行字段筛选及展开/折叠。
- 若总计仍非 100%或末级占比合计不一致，使用 Performance Analyzer 检查视觉查询的过滤表和分母范围；不能仅通过总计强制返回 1 掩盖集合不一致。

### 3.5 依赖与性能

- 排名和 Top10 Show Row 只依赖基础 Cost，不依赖展示 Cost%。
- 两个 IsZero 只依赖基础 Cost 与 ROI；本地筛选占比沿用“金额、占比、ROI 加和判零”的规则，包含负值时可能相互抵消。
- Cost% Value 在矩阵单元格中直接计算；Cost% Display 引用它进行格式化，不引入额外行遍历。
- 分母使用聚合与 ALLSELECTED，不为每个单元格再次计算整套 Top10 排名。排名的主要开销来自当前父组候选数量。
- 基础 Cost、ROI、Cost% Display 和字段有效性度量的完整模型定义仍须存在；本文件不重复收录未涉及的对象。

参考：[Microsoft — CALCULATE](https://learn.microsoft.com/en-us/dax/calculate-function-dax)、[Microsoft — ALLSELECTED](https://learn.microsoft.com/en-us/dax/allselected-function-dax)、[SQLBI — Filtering the top 3 products for each category](https://www.sqlbi.com/articles/filtering-the-top-3-products-for-each-category-in-power-bi/)。
