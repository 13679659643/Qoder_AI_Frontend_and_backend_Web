Dim_ColMetric_Sales_Performance_Details =
// ========================================
// 表: Dim_ColMetric_Sales_Performance_Details
// 类型: 维度表（Dim_ 前缀），断开维度（不与事实表建立关系，度量值中用 SELECTEDVALUE 调度）
// 用途: 定义 RL E2E Merch Dashboard - Merchandise Performance Overview Tab 的
//       Sales Performance Details by Channel 矩阵列维度
//       三层结构: ChannelGroup（Platform / Store）> Label（页面显示标签）> ColName（指标列）
// 范围: 口径文档/口径Markdown格式/Merchandise Performance Overview.md
//       - 子模块六：Sales Performance Details by Channel（§33-§41）+ 页面设计截图
// 数据底表（销售类）: a02_e2e_product_performance_sales_summary_d（SLS / vs LP / 占比 / AUR / LTD ST% 分子）
// 数据底表（库存类）: a02_e2e_product_performance_inv_summary_d（EOH Unit / LTD ST% 分母）
// 规模: 86 行 = Platform 组 36 行（TTL 8 列 + 4 渠道 × 7 列）
//              + Store 组 50 行（TTL 8 列 + 6 店铺 × 7 列）
// MD 指标（新增，12 列，每组末位 ColName_Sort=600）: 1 - sum(md_net_sales_amt) / sum(msrp_net_sales_amt)，
//       This Period 区间，percent_0dp 不含正号；口径来源为业务新增指令（原口径文档 §33-§41 未含 MD）
// 矩阵行维度: 商品维度切换 Label / Super Season / Product type / Category / MD type / Division
//            （同 Trend 板块，口径子模块六：依据占比指标公式中的维度；页面截图行为 product_type）
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
//   2. Metric_Format 说明（口径文档未定义本模块数据格式，按页面截图展示样式
//      + 模版复用/数据类型和格式总览.md 推定默认，业务确认后可调整）:
//      integer       → `#,##0` 整数千分位（SLS Unit / EOH Unit）
//      currency      → `#,##0` + 币种符号（SLS Amt / AUR，金额类，Display 中汇率换算 + 符号拼接）
//      percent_0dp → IF(__Value>0,"+","") & FORMAT(__Value,"#,##0%") 百分比整数变化，含正号（vs LP）
//      percent_0dp   → `#,##0%` 百分比整数，不含正号（SLS Amt% / Vert. Amt% / Horiz. Amt% / LTD ST% / MD）
//   3. Metric_IsCurrencyAmount（BOOLEAN）:
//      TRUE  → SLS Amt / AUR（金额类，涉及汇率换算与币种符号拼接）
//      FALSE → 其余（SLS Unit / EOH Unit 为数量类；占比 / LTD ST% / MD 为比率类；vs LP 为派生比率）
//   4. 颜色规则通过 Metric_ColorRule 字段标识，由 Cell Font Color 度量值统一调度:
//      fixed_black  → 全部基础指标列（SLS Unit / SLS Amt / SLS Amt% / Vert. Amt% / Horiz. Amt%
//                      / LTD ST% / EOH Unit / AUR / MD）
//      pos_neg_zero → vs LP（按值正/负/零三色）
//
// 字段说明:
//   Metric_ID             主键（全局唯一 1-86）
//   ChannelGroup          Level 1: 渠道分组（Platform / Store）
//   Label                 Level 2: 页面显示标签（TTL / Tmall / JD / RLE / DY / DY_Family / DY_W / DY_MN）
//   Label_Value           Level 2 对应事实表实际值（Platform 组映射 platform 字段；Store 组映射
//                         shop_name 字段；"TTL" 为特殊标记，度量值中走 ALLSELECTED 全渠道合计）
//   ColName               Level 3: 列名（Metric_ID + 指标名称，避免同名冲突，支持独立排序）
//   ChannelGroup_Sort     Level 1 排序（Platform=10, Store=20）
//   Label_Sort            Level 2 排序（TTL=10 首列；Tmall=20, JD=30, RLE=40, DY=50；
//                         Store 组 DY_Family=50, DY_W=60, DY_MN=70）
//   ColName_Sort          Level 3 排序（SLS Unit=100, SLS Amt=200, vs LP=300, SLS Amt%=400,
//                         Vert. Amt%=410, Horiz. Amt%=420, LTD ST%=430, EOH Unit=440, AUR=500,
//                         MD=600——每组末位）
//   ColType               列类型标识（即指标路由键，详见上方 ColType 口径）
//   Metric_Format         单一格式字段（integer / currency / percent_0dp / percent_0dp）
//   Metric_IsCurrencyAmount 是否金额类（TRUE 才涉及汇率换算与币种符号拼接）
//   Metric_ColorRule      字体颜色规则：fixed_black / pos_neg_zero
//   Metric_ColorPositive  正值颜色（pos_neg_zero 规则使用）
//   Metric_ColorNegative  负值颜色（pos_neg_zero 规则使用）
//   Metric_ColorZero      零值颜色（pos_neg_zero 规则使用）
//   Metric_ColorDefault   默认颜色（pos_neg_zero 在 BLANK 时兜底）
//
// 同名区分机制（ColName 加 Metric_ID 前缀）:
//   Power BI Sort by Column 要求同名字段只能绑定一个排序值，且本表同一指标名在
//   12 个 Label 下重复出现（如 "SLS Unit" 出现 12 次），通过在 ColName 开头拼接
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
    "Metric_ID",              INTEGER,    // 主键标识（全局唯一 1-86）
    "ChannelGroup",           STRING,     // Level 1: 渠道分组（Platform / Store）
    "Label",                  STRING,     // Level 2: 页面显示标签
    "Label_Value",            STRING,     // Level 2 对应事实表实际值（"TTL" 为特殊标记）
    "ColName",                STRING,     // Level 3: 列名（Metric_ID + 指标名称）
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
        // TTL（Label_Sort=10，特殊标记：ALLSELECTED 全渠道合计，8 列）
        // 颜色规则: 基础指标=固定黑；vs LP=正负零三色
        // ════════════════════════════════════════════════════════════════
        { 1,  "Platform", "TTL", "TTL", "1-SLS Unit",    10, 10, 100, "SLS Unit",    "integer",       FALSE, "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 2,  "Platform", "TTL", "TTL", "2-SLS Amt",     10, 10, 200, "SLS Amt",      "currency",      TRUE,  "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 3,  "Platform", "TTL", "TTL", "3-vs LP",         10, 10, 300, "vs LP",          "percent_0dp", FALSE, "pos_neg_zero", "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 4,  "Platform", "TTL", "TTL", "4-SLS Amt%",    10, 10, 400, "SLS Amt%",     "percent_0dp",   FALSE, "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 5,  "Platform", "TTL", "TTL", "5-LTD ST%",     10, 10, 430, "LTD ST%",      "percent_0dp",   FALSE, "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 6,  "Platform", "TTL", "TTL", "6-EOH Unit",    10, 10, 440, "EOH Unit",     "integer",       FALSE, "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 7,  "Platform", "TTL", "TTL", "7-AUR",         10, 10, 500, "AUR",          "currency",      TRUE,  "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 75, "Platform", "TTL", "TTL", "75-MD",         10, 10, 600, "MD",           "percent_0dp",   FALSE, "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },

        // ════════════════════════════════════════════════════════════════
        // Platform / Tmall（Label_Sort=20，platform = "TM"，7 列）
        // ════════════════════════════════════════════════════════════════
        { 8,  "Platform", "Tmall", "TM", "8-SLS Unit",     10, 20, 100, "SLS Unit",    "integer",       FALSE, "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 9,  "Platform", "Tmall", "TM", "9-SLS Amt",      10, 20, 200, "SLS Amt",      "currency",      TRUE,  "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 10, "Platform", "Tmall", "TM", "10-vs LP",         10, 20, 300, "vs LP",          "percent_0dp", FALSE, "pos_neg_zero", "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 11, "Platform", "Tmall", "TM", "11-Vert. Amt%",  10, 20, 410, "Vert. Amt%",   "percent_0dp",   FALSE, "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 12, "Platform", "Tmall", "TM", "12-Horiz. Amt%", 10, 20, 420, "Horiz. Amt%",  "percent_0dp",   FALSE, "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 13, "Platform", "Tmall", "TM", "13-AUR",         10, 20, 500, "AUR",          "currency",      TRUE,  "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 76, "Platform", "Tmall", "TM", "76-MD",         10, 20, 600, "MD",           "percent_0dp",   FALSE, "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },

        // ════════════════════════════════════════════════════════════════
        // Platform / JD（Label_Sort=30，platform = "JD"，7 列）
        // ════════════════════════════════════════════════════════════════
        { 14, "Platform", "JD", "JD", "14-SLS Unit",     10, 30, 100, "SLS Unit",    "integer",       FALSE, "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 15, "Platform", "JD", "JD", "15-SLS Amt",      10, 30, 200, "SLS Amt",      "currency",      TRUE,  "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 16, "Platform", "JD", "JD", "16-vs LP",          10, 30, 300, "vs LP",          "percent_0dp", FALSE, "pos_neg_zero", "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 17, "Platform", "JD", "JD", "17-Vert. Amt%",   10, 30, 410, "Vert. Amt%",   "percent_0dp",   FALSE, "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 18, "Platform", "JD", "JD", "18-Horiz. Amt%",  10, 30, 420, "Horiz. Amt%",  "percent_0dp",   FALSE, "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 19, "Platform", "JD", "JD", "19-AUR",          10, 30, 500, "AUR",          "currency",      TRUE,  "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 77, "Platform", "JD", "JD", "77-MD",         10, 30, 600, "MD",           "percent_0dp",   FALSE, "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },

        // ════════════════════════════════════════════════════════════════
        // Platform / RLE（Label_Sort=40，platform = "RLE"，7 列）
        // ════════════════════════════════════════════════════════════════
        { 20, "Platform", "RLE", "RLE", "20-SLS Unit",     10, 40, 100, "SLS Unit",    "integer",       FALSE, "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 21, "Platform", "RLE", "RLE", "21-SLS Amt",      10, 40, 200, "SLS Amt",      "currency",      TRUE,  "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 22, "Platform", "RLE", "RLE", "22-vs LP",          10, 40, 300, "vs LP",          "percent_0dp", FALSE, "pos_neg_zero", "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 23, "Platform", "RLE", "RLE", "23-Vert. Amt%",   10, 40, 410, "Vert. Amt%",   "percent_0dp",   FALSE, "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 24, "Platform", "RLE", "RLE", "24-Horiz. Amt%",  10, 40, 420, "Horiz. Amt%",  "percent_0dp",   FALSE, "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 25, "Platform", "RLE", "RLE", "25-AUR",         10, 40, 500, "AUR",          "currency",      TRUE,  "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 78, "Platform", "RLE", "RLE", "78-MD",         10, 40, 600, "MD",           "percent_0dp",   FALSE, "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },

        // ════════════════════════════════════════════════════════════════
        // Platform / DY（Label_Sort=50，platform = "DY"，7 列）
        // ════════════════════════════════════════════════════════════════
        { 26, "Platform", "DY", "DY", "26-SLS Unit",     10, 50, 100, "SLS Unit",    "integer",       FALSE, "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 27, "Platform", "DY", "DY", "27-SLS Amt",      10, 50, 200, "SLS Amt",      "currency",      TRUE,  "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 28, "Platform", "DY", "DY", "28-vs LP",          10, 50, 300, "vs LP",          "percent_0dp", FALSE, "pos_neg_zero", "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 29, "Platform", "DY", "DY", "29-Vert. Amt%",   10, 50, 410, "Vert. Amt%",   "percent_0dp",   FALSE, "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 30, "Platform", "DY", "DY", "30-Horiz. Amt%",  10, 50, 420, "Horiz. Amt%",  "percent_0dp",   FALSE, "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 31, "Platform", "DY", "DY", "31-AUR",          10, 50, 500, "AUR",          "currency",      TRUE,  "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 79, "Platform", "DY", "DY", "79-MD",         10, 50, 600, "MD",           "percent_0dp",   FALSE, "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },

        // ════════════════════════════════════════════════════════════════
        // Level 1 = Store（ChannelGroup_Sort=20，过滤事实表 [shop_name] 字段）
        // TTL（Label_Sort=10，特殊标记：ALLSELECTED 全店铺合计，8 列）
        // ════════════════════════════════════════════════════════════════
        { 32, "Store", "TTL", "TTL", "32-SLS Unit",    20, 10, 100, "SLS Unit",    "integer",       FALSE, "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 33, "Store", "TTL", "TTL", "33-SLS Amt",     20, 10, 200, "SLS Amt",      "currency",      TRUE,  "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 34, "Store", "TTL", "TTL", "34-vs LP",         20, 10, 300, "vs LP",          "percent_0dp", FALSE, "pos_neg_zero", "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 35, "Store", "TTL", "TTL", "35-SLS Amt%",    20, 10, 400, "SLS Amt%",     "percent_0dp",   FALSE, "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 36, "Store", "TTL", "TTL", "36-LTD ST%",     20, 10, 430, "LTD ST%",      "percent_0dp",   FALSE, "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 37, "Store", "TTL", "TTL", "37-EOH Unit",    20, 10, 440, "EOH Unit",     "integer",       FALSE, "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 38, "Store", "TTL", "TTL", "38-AUR",         20, 10, 500, "AUR",          "currency",      TRUE,  "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 80, "Store", "TTL", "TTL", "80-MD",         20, 10, 600, "MD",           "percent_0dp",   FALSE, "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },

        // ════════════════════════════════════════════════════════════════
        // Store / Tmall（Label_Sort=20，shop_name = "TM"，7 列）
        // ════════════════════════════════════════════════════════════════
        { 39, "Store", "Tmall", "TM", "39-SLS Unit",     20, 20, 100, "SLS Unit",    "integer",       FALSE, "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 40, "Store", "Tmall", "TM", "40-SLS Amt",      20, 20, 200, "SLS Amt",      "currency",      TRUE,  "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 41, "Store", "Tmall", "TM", "41-vs LP",          20, 20, 300, "vs LP",          "percent_0dp", FALSE, "pos_neg_zero", "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 42, "Store", "Tmall", "TM", "42-Vert. Amt%",   20, 20, 410, "Vert. Amt%",   "percent_0dp",   FALSE, "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 43, "Store", "Tmall", "TM", "43-Horiz. Amt%",  20, 20, 420, "Horiz. Amt%",  "percent_0dp",   FALSE, "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 44, "Store", "Tmall", "TM", "44-AUR",          20, 20, 500, "AUR",          "currency",      TRUE,  "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 81, "Store", "Tmall", "TM", "81-MD",         20, 20, 600, "MD",           "percent_0dp",   FALSE, "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },

        // ════════════════════════════════════════════════════════════════
        // Store / JD（Label_Sort=30，shop_name = "JD"，7 列）
        // ════════════════════════════════════════════════════════════════
        { 45, "Store", "JD", "JD", "45-SLS Unit",     20, 30, 100, "SLS Unit",    "integer",       FALSE, "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 46, "Store", "JD", "JD", "46-SLS Amt",      20, 30, 200, "SLS Amt",      "currency",      TRUE,  "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 47, "Store", "JD", "JD", "47-vs LP",          20, 30, 300, "vs LP",          "percent_0dp", FALSE, "pos_neg_zero", "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 48, "Store", "JD", "JD", "48-Vert. Amt%",   20, 30, 410, "Vert. Amt%",   "percent_0dp",   FALSE, "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 49, "Store", "JD", "JD", "49-Horiz. Amt%",  20, 30, 420, "Horiz. Amt%",  "percent_0dp",   FALSE, "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 50, "Store", "JD", "JD", "50-AUR",          20, 30, 500, "AUR",          "currency",      TRUE,  "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 82, "Store", "JD", "JD", "82-MD",         20, 30, 600, "MD",           "percent_0dp",   FALSE, "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },

        // ════════════════════════════════════════════════════════════════
        // Store / RLE（Label_Sort=40，shop_name = "RLE_CN"，7 列）
        // 注意：Store 组 RLE 对应事实表 shop_name = "RLE_CN"（与 Platform 组的 "RLE" 不同）
        // ════════════════════════════════════════════════════════════════
        { 51, "Store", "RLE", "RLE_CN", "51-SLS Unit",     20, 40, 100, "SLS Unit",    "integer",       FALSE, "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 52, "Store", "RLE", "RLE_CN", "52-SLS Amt",      20, 40, 200, "SLS Amt",      "currency",      TRUE,  "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 53, "Store", "RLE", "RLE_CN", "53-vs LP",          20, 40, 300, "vs LP",          "percent_0dp", FALSE, "pos_neg_zero", "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 54, "Store", "RLE", "RLE_CN", "54-Vert. Amt%",   20, 40, 410, "Vert. Amt%",   "percent_0dp",   FALSE, "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 55, "Store", "RLE", "RLE_CN", "55-Horiz. Amt%",  20, 40, 420, "Horiz. Amt%",  "percent_0dp",   FALSE, "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 56, "Store", "RLE", "RLE_CN", "56-AUR",          20, 40, 500, "AUR",          "currency",      TRUE,  "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 83, "Store", "RLE", "RLE_CN", "83-MD",         20, 40, 600, "MD",           "percent_0dp",   FALSE, "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },

        // ════════════════════════════════════════════════════════════════
        // Store / DY_Family（Label_Sort=50，shop_name = "DY_Family"，7 列）
        // ════════════════════════════════════════════════════════════════
        { 57, "Store", "DY_Family", "DY_Family", "57-SLS Unit",     20, 50, 100, "SLS Unit",    "integer",       FALSE, "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 58, "Store", "DY_Family", "DY_Family", "58-SLS Amt",      20, 50, 200, "SLS Amt",      "currency",      TRUE,  "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 59, "Store", "DY_Family", "DY_Family", "59-vs LP",          20, 50, 300, "vs LP",          "percent_0dp", FALSE, "pos_neg_zero", "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 60, "Store", "DY_Family", "DY_Family", "60-Vert. Amt%",   20, 50, 410, "Vert. Amt%",   "percent_0dp",   FALSE, "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 61, "Store", "DY_Family", "DY_Family", "61-Horiz. Amt%",  20, 50, 420, "Horiz. Amt%",  "percent_0dp",   FALSE, "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 62, "Store", "DY_Family", "DY_Family", "62-AUR",          20, 50, 500, "AUR",          "currency",      TRUE,  "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 84, "Store", "DY_Family", "DY_Family", "84-MD",         20, 50, 600, "MD",           "percent_0dp",   FALSE, "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },

        // ════════════════════════════════════════════════════════════════
        // Store / DY_W（Label_Sort=60，shop_name = "DY_W"，7 列）
        // ════════════════════════════════════════════════════════════════
        { 63, "Store", "DY_W", "DY_W", "63-SLS Unit",     20, 60, 100, "SLS Unit",    "integer",       FALSE, "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 64, "Store", "DY_W", "DY_W", "64-SLS Amt",      20, 60, 200, "SLS Amt",      "currency",      TRUE,  "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 65, "Store", "DY_W", "DY_W", "65-vs LP",          20, 60, 300, "vs LP",          "percent_0dp", FALSE, "pos_neg_zero", "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 66, "Store", "DY_W", "DY_W", "66-Vert. Amt%",   20, 60, 410, "Vert. Amt%",   "percent_0dp",   FALSE, "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 67, "Store", "DY_W", "DY_W", "67-Horiz. Amt%",  20, 60, 420, "Horiz. Amt%",  "percent_0dp",   FALSE, "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 68, "Store", "DY_W", "DY_W", "68-AUR",          20, 60, 500, "AUR",          "currency",      TRUE,  "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 85, "Store", "DY_W", "DY_W", "85-MD",         20, 60, 600, "MD",           "percent_0dp",   FALSE, "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },

        // ════════════════════════════════════════════════════════════════
        // Store / DY_MN（Label_Sort=70，shop_name = "DY_M"，7 列）
        // 注意：页面显示 Label 为 "DY_MN"，事实表实际值为 "DY_M"（与 Slicer_Store_Name 一致）
        // ════════════════════════════════════════════════════════════════
        { 69, "Store", "DY_MN", "DY_M", "69-SLS Unit",     20, 70, 100, "SLS Unit",    "integer",       FALSE, "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 70, "Store", "DY_MN", "DY_M", "70-SLS Amt",      20, 70, 200, "SLS Amt",      "currency",      TRUE,  "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 71, "Store", "DY_MN", "DY_M", "71-vs LP",          20, 70, 300, "vs LP",          "percent_0dp", FALSE, "pos_neg_zero", "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 72, "Store", "DY_MN", "DY_M", "72-Vert. Amt%",   20, 70, 410, "Vert. Amt%",   "percent_0dp",   FALSE, "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 73, "Store", "DY_MN", "DY_M", "73-Horiz. Amt%",  20, 70, 420, "Horiz. Amt%",  "percent_0dp",   FALSE, "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 74, "Store", "DY_MN", "DY_M", "74-AUR",          20, 70, 500, "AUR",          "currency",      TRUE,  "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 86, "Store", "DY_MN", "DY_M", "86-MD",         20, 70, 600, "MD",           "percent_0dp",   FALSE, "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" }
    }
)
