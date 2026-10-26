Dim_ColMetric_Platform_Merchandising_Performance =
// ========================================
// 表: Dim_ColMetric_Platform_Merchandising_Performance
// 类型: 维度表（Dim_ 前缀），断开维度（不与事实表建立关系，度量值中用 SELECTEDVALUE 调度）
// 用途: 定义 RL E2E Merch Dashboard - Merchandise Performance Overview Tab 的
//       Platform Merchandising Performance 矩阵列维度
//       三层结构: ChannelGroup（Platform / Store）> Label（页面显示标签）> ColName（指标列）
// 范围: 口径文档/口径Markdown格式/Merchandise Performance Overview.md
//       - 子模块八：Platform Merchandising Performance（§34-§39 + TAR 类口径）+ 页面设计截图
// 数据底表（销售类）: a02_e2e_product_performance_sales_summary_d（SLS Amt% 分子/分母 / ST% 销售金额 / TAR actual）
// 数据底表（库存类）: a02_e2e_product_performance_inv_summary_d（EOH = sum(msrp_inv_amt) / ST% 期末库存金额）
// 数据底表（目标类）: a05_e2e_product_fcst_data_d（TAR ACH% / MTD TAR Progress / YTD TAR Progress 的 target）
// 规模: 64 行 = Platform 组 27 行（TTL 7 列 + 4 渠道 × 5 列）
//              + Store 组 37 行（TTL 7 列 + 6 店铺 × 5 列）
// 列结构（与页面截图一致）:
//   TTL 组 7 列: SLS Amt% / vs LP / EOH / ST% / TAR ACH% / MTD TAR Progress / YTD TAR Progress
//   渠道组 5 列: SLS Amt% / vs LP / TAR ACH% / MTD TAR Progress / YTD TAR Progress
//   （EOH / ST% 仅 TTL 组展示——库存售罄类指标按全渠道口径（inv 表无渠道字段）；
//     TAR 三指标（TAR ACH% / MTD / YTD TAR Progress）按渠道口径在全部 Label 组展示）
// §34-§36 占比（Foundation / Acceleration / Complementary 销售金额占比）说明:
//   三者为「framework 维度切换」下的 SLS Amt% 取值，非独立列——矩阵行维度切到 framework 时，
//   本表 ColType="SLS Amt%" 列即承载 §34-§36 占比；行维度切到 category 时承载 §37 占比。
//   故本列指标表不单独建 Foundation/Acceleration/Complementary 列，统一由 SLS Amt% 路由键
//   + 行维度切换实现（同参考表占比列随行维度变化的口径设计）。
// TAR 类指标口径（口径文档/口径Markdown格式/actual除target逻辑详情.md）:
//   actual = a02[net_sales_amt]（恒为 This Period 区间）；target = a05[fcst_sales_amt]
//   TAR ACH% = This actual / This target（date to date，全粒度）
//   MTD TAR Progress = This actual / 所在财月汇总 target（Day/Week 不跨月；Month = This/This；
//     Quarter/Year 不计算；跨财月不计算）
//   YTD TAR Progress = This actual / 所在财年汇总 target（Day/Week/Month/Quarter 不跨年；
//     Year = This/This 始终计算；跨财年不计算）
// 矩阵行维度: Slicer_Framework[framework] > Slicer_Category[category]（层级行维度，
//            维度表与三张事实表一对多关联，行筛选关系自动传导）
//
// Label → 事实表实际值映射:
//   Platform 组（度量值中过滤事实表 [platform] 字段）:
//     TTL → 特殊标记（ALLSELECTED 处理）；Tmall → TM；JD → JD；RLE → RLE；DY → DY
//   Store 组（度量值中过滤事实表 [shop_name] 字段）:
//     TTL → 特殊标记（ALLSELECTED 处理）；Tmall → TM；JD → JD；RLE → RLE_CN；
//     DY_Family → DY_Family；DY_W → DY_W；DY_MN → DY_M
//
// 设计原则:
//   1. 无双模式 → 单一 Metric_Format 字段
//   2. Metric_Format 说明（按口径文档子模块八 §34-§39 数据类型 + 附属指标类型）:
//      integer_bp    → vs LP: this period - last period 差值，bp 指标，展示时 ×10000 转 bp
//                      （§34-§37 附属指标类型 vs LP:integer_bp；Foundation/Acceleration/
//                       Complementary/SLS Amt% 四个占比共用此附属指标）
//      currency      → EOH: 期末库存金额 = EOH Units × msrp，看所选时间范围 end period 最后一天；
//                      `#,##0` + 币种符号（DAX 中 __CurrencySymbol & FORMAT(__Value,"#,##0") 拼接，§38）
//      percent_0dp   → 其余: `#,##0%` 百分比整数，不含正号
//                      （SLS Amt% §34-§37 / ST% §39 / TAR ACH% / MTD TAR Progress / YTD TAR Progress）
//   3. Metric_IsCurrencyAmount（BOOLEAN）:
//      TRUE  → EOH（金额类，涉及汇率换算与币种符号拼接）
//      FALSE → 其余（SLS Amt% / ST% / TAR 类为比率类；vs LP 为 bp 差值类）
//   4. 颜色规则通过 Metric_ColorRule 字段标识，由 Cell Font Color 度量值统一调度:
//      fixed_black  → 全部基础指标列（SLS Amt% / EOH / ST% / TAR ACH% / MTD TAR Progress / YTD TAR Progress）
//      pos_neg_zero → vs LP（按值正/负/零三色）
//
// 字段说明:
//   Metric_ID             主键（全局唯一 1-64）
//   ChannelGroup          Level 1: 渠道分组（Platform / Store）
//   Label                 Level 2: 页面显示标签（TTL / Tmall / JD / RLE / DY / DY_Family / DY_W / DY_MN）
//   Label_Value           Level 2 对应事实表实际值（Platform 组映射 platform 字段；Store 组映射
//                         shop_name 字段；"TTL" 为特殊标记，度量值中走 ALLSELECTED 全渠道合计）
//   ColName               Level 3: 列名（Metric_ID + 指标名称，避免同名冲突，支持独立排序；
//                         单行空格分隔英文单词，不还原页面截图换行态，如 "MTD TAR Progress"）
//   ChannelGroup_Sort     Level 1 排序（Platform=10, Store=20）
//   Label_Sort            Level 2 排序（TTL=10 首列；Tmall=20, JD=30, RLE=40, DY=50；
//                         Store 组 DY_Family=50, DY_W=60, DY_MN=70）
//   ColName_Sort          Level 3 排序（SLS Amt%=100, vs LP=200, EOH=300（仅 TTL）, ST%=400（仅 TTL）,
//                         TAR ACH%=500, MTD TAR Progress=600, YTD TAR Progress=700）
//   ColType               列类型标识（即指标路由键，详见上方 ColType 口径）
//   Metric_Format         单一格式字段（integer_bp / currency / percent_0dp）
//   Metric_IsCurrencyAmount 是否金额类（TRUE 才涉及汇率换算与币种符号拼接）
//   Metric_ColorRule      字体颜色规则：fixed_black / pos_neg_zero
//   Metric_ColorPositive  正值颜色（pos_neg_zero 规则使用）
//   Metric_ColorNegative  负值颜色（pos_neg_zero 规则使用）
//   Metric_ColorZero      零值颜色（pos_neg_zero 规则使用）
//   Metric_ColorDefault   默认颜色（pos_neg_zero 在 BLANK 时兜底）
//
// 同名区分机制（ColName 加 Metric_ID 前缀）:
//   Power BI Sort by Column 要求同名字段只能绑定一个排序值，且本表同一指标名在
//   12 个 Label 下重复出现（如 "SLS Amt%" 出现 12 次），通过在 ColName 开头拼接
//   Metric_ID，使各列在底层字符串不同，支持独立排序与 SELECTEDVALUE 路由。
//
// 颜色约定:
//   正值（>0）：#1A9018 绿色
//   负值（<0）：#D64550 红色
//   零值（=0）：#E1C233 黄色
//   默认      ：#5F6165 深灰（pos_neg_zero 在 BLANK 时兜底）
//   固定黑色  ：#252423
// ========================================
DATATABLE(
    "Metric_ID",              INTEGER,    // 主键标识（全局唯一 1-64）
    "ChannelGroup",           STRING,     // Level 1: 渠道分组（Platform / Store）
    "Label",                  STRING,     // Level 2: 页面显示标签
    "Label_Value",            STRING,     // Level 2 对应事实表实际值（"TTL" 为特殊标记）
    "ColName",                STRING,     // Level 3: 列名（Metric_ID + 指标名称，单行空格分隔）
    "ChannelGroup_Sort",      INTEGER,    // Level 1 排序
    "Label_Sort",             INTEGER,    // Level 2 排序
    "ColName_Sort",           INTEGER,    // Level 3 排序
    "ColType",                STRING,     // 列类型标识（指标路由键）
    "Metric_Format",          STRING,     // 单一格式字段（无双模式）
    "Metric_IsCurrencyAmount", BOOLEAN,   // 是否金额类（TRUE 才涉及汇率换算与币种符号拼接）
    "Metric_ColorRule",       STRING,     // 字体颜色规则
    "Metric_ColorPositive",   STRING,     // 正值颜色
    "Metric_ColorNegative",   STRING,     // 负值颜色
    "Metric_ColorZero",       STRING,     // 零值颜色
    "Metric_ColorDefault",    STRING,     // 默认颜色
    {
        // ════════════════════════════════════════════════════════════════
        // Level 1 = Platform（ChannelGroup_Sort=10，过滤事实表 [platform] 字段）
        // TTL（Label_Sort=10，特殊标记：ALLSELECTED 全渠道合计，7 列）
        // 颜色规则: 基础指标=固定黑；vs LP=正负零三色
        // ════════════════════════════════════════════════════════════════
        { 1,  "Platform", "TTL", "TTL", "1-SLS Amt%",         10, 10, 100, "SLS Amt%",         "percent_0dp", FALSE, "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 2,  "Platform", "TTL", "TTL", "2-vs LP",            10, 10, 200, "vs LP",            "integer_bp",  FALSE, "pos_neg_zero", "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 3,  "Platform", "TTL", "TTL", "3-EOH",              10, 10, 300, "EOH",              "currency",    TRUE,  "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 4,  "Platform", "TTL", "TTL", "4-ST%",              10, 10, 400, "ST%",              "percent_0dp", FALSE, "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 5,  "Platform", "TTL", "TTL", "5-TAR ACH%",         10, 10, 500, "TAR ACH%",         "percent_0dp", FALSE, "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 6,  "Platform", "TTL", "TTL", "6-MTD TAR Progress", 10, 10, 600, "MTD TAR Progress", "percent_0dp", FALSE, "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 7,  "Platform", "TTL", "TTL", "7-YTD TAR Progress", 10, 10, 700, "YTD TAR Progress", "percent_0dp", FALSE, "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },

        // ════════════════════════════════════════════════════════════════
        // Platform / Tmall（Label_Sort=20，platform = "TM"，5 列）
        // ════════════════════════════════════════════════════════════════
        { 8,  "Platform", "Tmall", "TM", "8-SLS Amt%",          10, 20, 100, "SLS Amt%",         "percent_0dp", FALSE, "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 9,  "Platform", "Tmall", "TM", "9-vs LP",             10, 20, 200, "vs LP",            "integer_bp",  FALSE, "pos_neg_zero", "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 10, "Platform", "Tmall", "TM", "10-TAR ACH%",         10, 20, 500, "TAR ACH%",         "percent_0dp", FALSE, "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 11, "Platform", "Tmall", "TM", "11-MTD TAR Progress", 10, 20, 600, "MTD TAR Progress", "percent_0dp", FALSE, "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 12, "Platform", "Tmall", "TM", "12-YTD TAR Progress", 10, 20, 700, "YTD TAR Progress", "percent_0dp", FALSE, "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },

        // ════════════════════════════════════════════════════════════════
        // Platform / JD（Label_Sort=30，platform = "JD"，5 列）
        // ════════════════════════════════════════════════════════════════
        { 13, "Platform", "JD", "JD", "13-SLS Amt%",          10, 30, 100, "SLS Amt%",         "percent_0dp", FALSE, "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 14, "Platform", "JD", "JD", "14-vs LP",             10, 30, 200, "vs LP",            "integer_bp",  FALSE, "pos_neg_zero", "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 15, "Platform", "JD", "JD", "15-TAR ACH%",          10, 30, 500, "TAR ACH%",         "percent_0dp", FALSE, "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 16, "Platform", "JD", "JD", "16-MTD TAR Progress",  10, 30, 600, "MTD TAR Progress", "percent_0dp", FALSE, "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 17, "Platform", "JD", "JD", "17-YTD TAR Progress",  10, 30, 700, "YTD TAR Progress", "percent_0dp", FALSE, "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },

        // ════════════════════════════════════════════════════════════════
        // Platform / RLE（Label_Sort=40，platform = "RLE"，5 列）
        // ════════════════════════════════════════════════════════════════
        { 18, "Platform", "RLE", "RLE", "18-SLS Amt%",          10, 40, 100, "SLS Amt%",         "percent_0dp", FALSE, "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 19, "Platform", "RLE", "RLE", "19-vs LP",             10, 40, 200, "vs LP",            "integer_bp",  FALSE, "pos_neg_zero", "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 20, "Platform", "RLE", "RLE", "20-TAR ACH%",          10, 40, 500, "TAR ACH%",         "percent_0dp", FALSE, "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 21, "Platform", "RLE", "RLE", "21-MTD TAR Progress",  10, 40, 600, "MTD TAR Progress", "percent_0dp", FALSE, "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 22, "Platform", "RLE", "RLE", "22-YTD TAR Progress",  10, 40, 700, "YTD TAR Progress", "percent_0dp", FALSE, "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },

        // ════════════════════════════════════════════════════════════════
        // Platform / DY（Label_Sort=50，platform = "DY"，5 列）
        // ════════════════════════════════════════════════════════════════
        { 23, "Platform", "DY", "DY", "23-SLS Amt%",          10, 50, 100, "SLS Amt%",         "percent_0dp", FALSE, "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 24, "Platform", "DY", "DY", "24-vs LP",             10, 50, 200, "vs LP",            "integer_bp",  FALSE, "pos_neg_zero", "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 25, "Platform", "DY", "DY", "25-TAR ACH%",          10, 50, 500, "TAR ACH%",         "percent_0dp", FALSE, "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 26, "Platform", "DY", "DY", "26-MTD TAR Progress",  10, 50, 600, "MTD TAR Progress", "percent_0dp", FALSE, "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 27, "Platform", "DY", "DY", "27-YTD TAR Progress",  10, 50, 700, "YTD TAR Progress", "percent_0dp", FALSE, "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },

        // ════════════════════════════════════════════════════════════════
        // Level 1 = Store（ChannelGroup_Sort=20，过滤事实表 [shop_name] 字段）
        // TTL（Label_Sort=10，特殊标记：ALLSELECTED 全店铺合计，7 列）
        // ════════════════════════════════════════════════════════════════
        { 28, "Store", "TTL", "TTL", "28-SLS Amt%",         20, 10, 100, "SLS Amt%",         "percent_0dp", FALSE, "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 29, "Store", "TTL", "TTL", "29-vs LP",            20, 10, 200, "vs LP",            "integer_bp",  FALSE, "pos_neg_zero", "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 30, "Store", "TTL", "TTL", "30-EOH",              20, 10, 300, "EOH",              "currency",    TRUE,  "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 31, "Store", "TTL", "TTL", "31-ST%",              20, 10, 400, "ST%",              "percent_0dp", FALSE, "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 32, "Store", "TTL", "TTL", "32-TAR ACH%",         20, 10, 500, "TAR ACH%",         "percent_0dp", FALSE, "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 33, "Store", "TTL", "TTL", "33-MTD TAR Progress", 20, 10, 600, "MTD TAR Progress", "percent_0dp", FALSE, "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 34, "Store", "TTL", "TTL", "34-YTD TAR Progress", 20, 10, 700, "YTD TAR Progress", "percent_0dp", FALSE, "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },

        // ════════════════════════════════════════════════════════════════
        // Store / Tmall（Label_Sort=20，shop_name = "TM"，5 列）
        // ════════════════════════════════════════════════════════════════
        { 35, "Store", "Tmall", "TM", "35-SLS Amt%",          20, 20, 100, "SLS Amt%",         "percent_0dp", FALSE, "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 36, "Store", "Tmall", "TM", "36-vs LP",             20, 20, 200, "vs LP",            "integer_bp",  FALSE, "pos_neg_zero", "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 37, "Store", "Tmall", "TM", "37-TAR ACH%",          20, 20, 500, "TAR ACH%",         "percent_0dp", FALSE, "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 38, "Store", "Tmall", "TM", "38-MTD TAR Progress",  20, 20, 600, "MTD TAR Progress", "percent_0dp", FALSE, "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 39, "Store", "Tmall", "TM", "39-YTD TAR Progress",  20, 20, 700, "YTD TAR Progress", "percent_0dp", FALSE, "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },

        // ════════════════════════════════════════════════════════════════
        // Store / JD（Label_Sort=30，shop_name = "JD"，5 列）
        // ════════════════════════════════════════════════════════════════
        { 40, "Store", "JD", "JD", "40-SLS Amt%",          20, 30, 100, "SLS Amt%",         "percent_0dp", FALSE, "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 41, "Store", "JD", "JD", "41-vs LP",             20, 30, 200, "vs LP",            "integer_bp",  FALSE, "pos_neg_zero", "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 42, "Store", "JD", "JD", "42-TAR ACH%",          20, 30, 500, "TAR ACH%",         "percent_0dp", FALSE, "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 43, "Store", "JD", "JD", "43-MTD TAR Progress",  20, 30, 600, "MTD TAR Progress", "percent_0dp", FALSE, "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 44, "Store", "JD", "JD", "44-YTD TAR Progress",  20, 30, 700, "YTD TAR Progress", "percent_0dp", FALSE, "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },

        // ════════════════════════════════════════════════════════════════
        // Store / RLE（Label_Sort=40，shop_name = "RLE_CN"，5 列）
        // 注意：Store 组 RLE 对应事实表 shop_name = "RLE_CN"（与 Platform 组的 "RLE" 不同）
        // ════════════════════════════════════════════════════════════════
        { 45, "Store", "RLE", "RLE_CN", "45-SLS Amt%",          20, 40, 100, "SLS Amt%",         "percent_0dp", FALSE, "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 46, "Store", "RLE", "RLE_CN", "46-vs LP",             20, 40, 200, "vs LP",            "integer_bp",  FALSE, "pos_neg_zero", "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 47, "Store", "RLE", "RLE_CN", "47-TAR ACH%",          20, 40, 500, "TAR ACH%",         "percent_0dp", FALSE, "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 48, "Store", "RLE", "RLE_CN", "48-MTD TAR Progress",  20, 40, 600, "MTD TAR Progress", "percent_0dp", FALSE, "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 49, "Store", "RLE", "RLE_CN", "49-YTD TAR Progress",  20, 40, 700, "YTD TAR Progress", "percent_0dp", FALSE, "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },

        // ════════════════════════════════════════════════════════════════
        // Store / DY_Family（Label_Sort=50，shop_name = "DY_Family"，5 列）
        // ════════════════════════════════════════════════════════════════
        { 50, "Store", "DY_Family", "DY_Family", "50-SLS Amt%",          20, 50, 100, "SLS Amt%",         "percent_0dp", FALSE, "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 51, "Store", "DY_Family", "DY_Family", "51-vs LP",             20, 50, 200, "vs LP",            "integer_bp",  FALSE, "pos_neg_zero", "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 52, "Store", "DY_Family", "DY_Family", "52-TAR ACH%",          20, 50, 500, "TAR ACH%",         "percent_0dp", FALSE, "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 53, "Store", "DY_Family", "DY_Family", "53-MTD TAR Progress",  20, 50, 600, "MTD TAR Progress", "percent_0dp", FALSE, "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 54, "Store", "DY_Family", "DY_Family", "54-YTD TAR Progress",  20, 50, 700, "YTD TAR Progress", "percent_0dp", FALSE, "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },

        // ════════════════════════════════════════════════════════════════
        // Store / DY_W（Label_Sort=60，shop_name = "DY_W"，5 列）
        // ════════════════════════════════════════════════════════════════
        { 55, "Store", "DY_W", "DY_W", "55-SLS Amt%",          20, 60, 100, "SLS Amt%",         "percent_0dp", FALSE, "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 56, "Store", "DY_W", "DY_W", "56-vs LP",             20, 60, 200, "vs LP",            "integer_bp",  FALSE, "pos_neg_zero", "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 57, "Store", "DY_W", "DY_W", "57-TAR ACH%",          20, 60, 500, "TAR ACH%",         "percent_0dp", FALSE, "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 58, "Store", "DY_W", "DY_W", "58-MTD TAR Progress",  20, 60, 600, "MTD TAR Progress", "percent_0dp", FALSE, "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 59, "Store", "DY_W", "DY_W", "59-YTD TAR Progress",  20, 60, 700, "YTD TAR Progress", "percent_0dp", FALSE, "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },

        // ════════════════════════════════════════════════════════════════
        // Store / DY_MN（Label_Sort=70，shop_name = "DY_M"，5 列）
        // 注意：页面显示 Label 为 "DY_MN"，事实表实际值为 "DY_M"（与 Slicer_Store_Name 一致）
        // ════════════════════════════════════════════════════════════════
        { 60, "Store", "DY_MN", "DY_M", "60-SLS Amt%",          20, 70, 100, "SLS Amt%",         "percent_0dp", FALSE, "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 61, "Store", "DY_MN", "DY_M", "61-vs LP",             20, 70, 200, "vs LP",            "integer_bp",  FALSE, "pos_neg_zero", "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 62, "Store", "DY_MN", "DY_M", "62-TAR ACH%",          20, 70, 500, "TAR ACH%",         "percent_0dp", FALSE, "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 63, "Store", "DY_MN", "DY_M", "63-MTD TAR Progress",  20, 70, 600, "MTD TAR Progress", "percent_0dp", FALSE, "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 64, "Store", "DY_MN", "DY_M", "64-YTD TAR Progress",  20, 70, 700, "YTD TAR Progress", "percent_0dp", FALSE, "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" }
    }
)
