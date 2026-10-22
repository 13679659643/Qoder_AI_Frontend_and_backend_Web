Dim_ColMetric_Handbags&Outwear_Sales_ms =
// ========================================
// 表: Dim_ColMetric_Handbags&Outwear_Sales_ms
// 类型: 维度表（Dim_ 前缀），断开维度（不与事实表建立关系，度量值中用 SELECTEDVALUE 调度）
// 用途: 定义 RL E2E Merch Dashboard - Dimension Cross Analysis Tab 的
//       Handbags Sales Performance 矩阵列维度
//       三层结构: ChannelGroup（仅 Store）> Label（页面显示标签）> ColName（指标列）
// 范围: 口径文档/口径Markdown格式/Dimension Cross Analysis.md
//       - 子模块十：Handbags Sales Performance（§43-§47）
// 数据底表（销售类）: s02_trade_sku_data_d（SLS Unit / SLS Amt / SLS Amt% / vs LP 类分子）
// 数据底表（库存类）: s02_inventory_stock_sales_detail_d（EOH / EOH vs LP / ST% 库存分母）
// 规模: 31 行 = Store 组 TTL 7 列（SLS Unit / SLS Amt / SLS Amt% / Amt vs LP / ST% / EOH / EOH vs LP）
//              + 6 店铺 × 4 列（SLS Unit / SLS Amt / SLS Amt% / vs LP，各店铺指标完全一致）
// 矩阵行维度: Slicer_Spu_Model[spu_model]（与 s02_trade_sku_data_d、s02_inventory_stock_sales_detail_d
//            均一对多关系，行筛选自动传导双表，度量值无需显式处理行维度传递；表内含 sort_order
//            排序字段，涉及 ALLSELECTED 时必须针对整张表——规避"按列排序（Sort by Column）"
//            隐藏筛选传播，详见主方案）
// 前置筛选: category IN ("Handbags", "Outerwear")（口径文档 'Outwear' 已确认为笔误，
//          底表实际值为 'Outerwear'）由页面视觉对象筛选器承担，经 Slicer_Category 与
//          trade / inv 双侧一对多关系自动传导，度量值内零品类硬编码（后续品类切换
//          仅改筛选器配置），不在本表处理
//
// Label → 事实表实际值映射（Store 组，度量值中过滤事实表 [shop_name] 字段）:
//     TTL → 特殊标记（ALLSELECTED 处理）；Tmall → TM；JD → JD；RLE → RLE_CN；
//     DY_Family → DY_Family；DY_W → DY_W；DY_MN → DY_M（与 Slicer_Store_Name 取值一致）
//
// 设计原则:
//   1. 无双模式 → 单一 Metric_Format 字段
//   2. Metric_Format 说明（口径文档 §43-§47 已定义数据类型与格式，一切以口径文档为准）:
//      integer       → `#,##0` 整数千分位（SLS Unit / EOH）
//      currency      → `#,##0` + 币种符号（SLS Amt，金额类，Display 中汇率换算 + 符号拼接）
//      percent_0dp   → `#,##0%` 百分比整数，不含正号（SLS Amt% / ST% / Amt vs LP / EOH vs LP）
//      integer_bp    → 值 ×10000 转 bp，FORMAT(#,##0) & "bp"（vs LP，SLS Amt% 占比差值）
//   3. Metric_IsCurrencyAmount（BOOLEAN）:
//      TRUE  → SLS Amt（金额类，涉及汇率换算与币种符号拼接）
//      FALSE → 其余（SLS Unit / EOH 为数量类；SLS Amt% / ST% 为比率类；
//               Amt vs LP / vs LP / EOH vs LP 为派生比率，分子分母同币种不换算）
//   4. 颜色规则通过 Metric_ColorRule 字段标识，由 Cell Font Color 度量值统一调度:
//      fixed_black  → 全部基础指标列（SLS Unit / SLS Amt / SLS Amt% / ST% / EOH）
//      pos_neg_zero → vs LP 类（Amt vs LP / vs LP / EOH vs LP，按值正/负/零三色）
//   5. Display 层 BLANK 一律返回 BLANK()（不返回 "-"）——矩阵检测到该行全部度量值均为
//      BLANK() 时自动隐藏该行（含层级行，需所有指标均为 BLANK()），行可见性由矩阵原生
//      机制承担，无需 IsEmpty 视觉级筛选器
//
// 字段说明:
//   Metric_ID             主键（全局唯一 1-31）
//   ChannelGroup          Level 1: 渠道分组（仅 Store）
//   Label                 Level 2: 页面显示标签（TTL / Tmall / JD / RLE / DY_Family / DY_W / DY_MN）
//   Label_Value           Level 2 对应事实表实际值（映射 trade 表 shop_name 字段；
//                         "TTL" 为特殊标记，度量值中走 ALLSELECTED 全渠道合计）
//   ColName               Level 3: 列名（Metric_ID + 指标名称，避免同名冲突，支持独立排序；
//                         指标名直接使用空格英文单词，如 "SLS Unit"，不还原页面换行态）
//   ChannelGroup_Sort     Level 1 排序（Store=10）
//   Label_Sort            Level 2 排序（TTL=10 首列；Tmall=20, JD=30, RLE=40,
//                         DY_Family=50, DY_W=60, DY_MN=70；对齐 Slicer_Store_Name 店铺顺序）
//   ColName_Sort          Level 3 排序（TTL 列: SLS Unit=100, SLS Amt=200, SLS Amt%=300,
//                         Amt vs LP=400, ST%=500, EOH=600, EOH vs LP=700；
//                         Store 列: SLS Unit=100, SLS Amt=200, SLS Amt%=300, vs LP=400）
//   ColType               列类型标识（即指标路由键，8 种：SLS Unit / SLS Amt / SLS Amt% /
//                         Amt vs LP / ST% / EOH / EOH vs LP / vs LP）
//   Metric_Format         单一格式字段（integer / currency / percent_0dp / integer_bp）
//   Metric_IsCurrencyAmount 是否金额类（TRUE 才涉及汇率换算与币种符号拼接）
//   Metric_ColorRule      字体颜色规则：fixed_black / pos_neg_zero
//   Metric_ColorPositive  正值颜色（pos_neg_zero 规则使用）
//   Metric_ColorNegative  负值颜色（pos_neg_zero 规则使用）
//   Metric_ColorZero      零值颜色（pos_neg_zero 规则使用）
//   Metric_ColorDefault   默认颜色（pos_neg_zero 在 BLANK 时兜底）
//
// 同名区分机制（ColName 加 Metric_ID 前缀）:
//   Power BI Sort by Column 要求同名字段只能绑定一个排序值，且本表同一指标名在
//   7 个 Label 下重复出现（如 "SLS Unit" 出现 7 次），通过在 ColName 开头拼接
//   Metric_ID，使各列在底层字符串不同，支持独立排序与 SELECTEDVALUE 路由。
//
// 表名引用说明:
//   表名含 "&" 字符，DAX 中引用必须加单引号：'Dim_ColMetric_Handbags&Outwear_Sales_ms'[ColType]
//
// 颜色约定:
//   正值（>0）：#1A9018 绿色
//   负值（<0）：#D64550 红色
//   零值（=0）：#E1C233 黄色
//   默认      ：#5F6165 深灰（pos_neg_zero 在 BLANK 时兜底）
//   固定黑色  ：#252423
// ========================================
DATATABLE(
    "Metric_ID",              INTEGER,    // 主键标识（全局唯一 1-31）
    "ChannelGroup",           STRING,     // Level 1: 渠道分组（仅 Store）
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
        // Level 1 = Store（ChannelGroup_Sort=10，过滤事实表 [shop_name] 字段）
        // TTL（Label_Sort=10，特殊标记：ALLSELECTED 全店铺合计，7 列）
        // 颜色规则: 基础指标=固定黑；vs LP 类（Amt vs LP / EOH vs LP）=正负零三色
        // ════════════════════════════════════════════════════════════════
        { 1, "Store", "TTL", "TTL", "1-SLS Unit",   10, 10, 100, "SLS Unit",   "integer",     FALSE, "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 2, "Store", "TTL", "TTL", "2-SLS Amt",    10, 10, 200, "SLS Amt",     "currency",    TRUE,  "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 3, "Store", "TTL", "TTL", "3-SLS Amt%",   10, 10, 300, "SLS Amt%",    "percent_0dp", FALSE, "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 4, "Store", "TTL", "TTL", "4-Amt vs LP",  10, 10, 400, "Amt vs LP",   "percent_0dp", FALSE, "pos_neg_zero", "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 5, "Store", "TTL", "TTL", "5-ST%",        10, 10, 500, "ST%",         "percent_0dp", FALSE, "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 6, "Store", "TTL", "TTL", "6-EOH",        10, 10, 600, "EOH",         "integer",     FALSE, "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 7, "Store", "TTL", "TTL", "7-EOH vs LP",  10, 10, 700, "EOH vs LP",   "percent_0dp", FALSE, "pos_neg_zero", "#1A9018", "#D64550", "#E1C233", "#5F6165" },

        // ════════════════════════════════════════════════════════════════
        // Store / Tmall（Label_Sort=20，shop_name = "TM"，4 列）
        // ════════════════════════════════════════════════════════════════
        { 8,  "Store", "Tmall", "TM", "8-SLS Unit",   10, 20, 100, "SLS Unit",   "integer",     FALSE, "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 9,  "Store", "Tmall", "TM", "9-SLS Amt",    10, 20, 200, "SLS Amt",     "currency",    TRUE,  "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 10, "Store", "Tmall", "TM", "10-SLS Amt%",  10, 20, 300, "SLS Amt%",    "percent_0dp", FALSE, "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 11, "Store", "Tmall", "TM", "11-vs LP",     10, 20, 400, "vs LP",       "integer_bp",  FALSE, "pos_neg_zero", "#1A9018", "#D64550", "#E1C233", "#5F6165" },

        // ════════════════════════════════════════════════════════════════
        // Store / JD（Label_Sort=30，shop_name = "JD"，4 列）
        // ════════════════════════════════════════════════════════════════
        { 12, "Store", "JD", "JD", "12-SLS Unit",   10, 30, 100, "SLS Unit",   "integer",     FALSE, "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 13, "Store", "JD", "JD", "13-SLS Amt",    10, 30, 200, "SLS Amt",     "currency",    TRUE,  "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 14, "Store", "JD", "JD", "14-SLS Amt%",   10, 30, 300, "SLS Amt%",    "percent_0dp", FALSE, "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 15, "Store", "JD", "JD", "15-vs LP",      10, 30, 400, "vs LP",       "integer_bp",  FALSE, "pos_neg_zero", "#1A9018", "#D64550", "#E1C233", "#5F6165" },

        // ════════════════════════════════════════════════════════════════
        // Store / RLE（Label_Sort=40，shop_name = "RLE_CN"，4 列）
        // 注意：页面显示 Label 为 "RLE"，事实表实际值为 "RLE_CN"（与 Slicer_Store_Name 一致）
        // ════════════════════════════════════════════════════════════════
        { 16, "Store", "RLE", "RLE_CN", "16-SLS Unit",   10, 40, 100, "SLS Unit",   "integer",     FALSE, "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 17, "Store", "RLE", "RLE_CN", "17-SLS Amt",    10, 40, 200, "SLS Amt",     "currency",    TRUE,  "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 18, "Store", "RLE", "RLE_CN", "18-SLS Amt%",   10, 40, 300, "SLS Amt%",    "percent_0dp", FALSE, "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 19, "Store", "RLE", "RLE_CN", "19-vs LP",      10, 40, 400, "vs LP",       "integer_bp",  FALSE, "pos_neg_zero", "#1A9018", "#D64550", "#E1C233", "#5F6165" },

        // ════════════════════════════════════════════════════════════════
        // Store / DY_Family（Label_Sort=50，shop_name = "DY_Family"，4 列）
        // ════════════════════════════════════════════════════════════════
        { 20, "Store", "DY_Family", "DY_Family", "20-SLS Unit",   10, 50, 100, "SLS Unit",   "integer",     FALSE, "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 21, "Store", "DY_Family", "DY_Family", "21-SLS Amt",    10, 50, 200, "SLS Amt",     "currency",    TRUE,  "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 22, "Store", "DY_Family", "DY_Family", "22-SLS Amt%",   10, 50, 300, "SLS Amt%",    "percent_0dp", FALSE, "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 23, "Store", "DY_Family", "DY_Family", "23-vs LP",      10, 50, 400, "vs LP",       "integer_bp",  FALSE, "pos_neg_zero", "#1A9018", "#D64550", "#E1C233", "#5F6165" },

        // ════════════════════════════════════════════════════════════════
        // Store / DY_W（Label_Sort=60，shop_name = "DY_W"，4 列）
        // ════════════════════════════════════════════════════════════════
        { 24, "Store", "DY_W", "DY_W", "24-SLS Unit",   10, 60, 100, "SLS Unit",   "integer",     FALSE, "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 25, "Store", "DY_W", "DY_W", "25-SLS Amt",    10, 60, 200, "SLS Amt",     "currency",    TRUE,  "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 26, "Store", "DY_W", "DY_W", "26-SLS Amt%",   10, 60, 300, "SLS Amt%",    "percent_0dp", FALSE, "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 27, "Store", "DY_W", "DY_W", "27-vs LP",      10, 60, 400, "vs LP",       "integer_bp",  FALSE, "pos_neg_zero", "#1A9018", "#D64550", "#E1C233", "#5F6165" },

        // ════════════════════════════════════════════════════════════════
        // Store / DY_MN（Label_Sort=70，shop_name = "DY_M"，4 列）
        // 注意：页面显示 Label 为 "DY_MN"，事实表实际值为 "DY_M"（与 Slicer_Store_Name 一致）
        // ════════════════════════════════════════════════════════════════
        { 28, "Store", "DY_MN", "DY_M", "28-SLS Unit",   10, 70, 100, "SLS Unit",   "integer",     FALSE, "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 29, "Store", "DY_MN", "DY_M", "29-SLS Amt",    10, 70, 200, "SLS Amt",     "currency",    TRUE,  "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 30, "Store", "DY_MN", "DY_M", "30-SLS Amt%",   10, 70, 300, "SLS Amt%",    "percent_0dp", FALSE, "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 31, "Store", "DY_MN", "DY_M", "31-vs LP",      10, 70, 400, "vs LP",       "integer_bp",  FALSE, "pos_neg_zero", "#1A9018", "#D64550", "#E1C233", "#5F6165" }
    }
)
