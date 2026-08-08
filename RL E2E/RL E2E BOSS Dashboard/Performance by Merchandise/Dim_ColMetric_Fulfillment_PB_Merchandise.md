Dim_ColMetric_Fulfillment_PB_Merchandise =
// ========================================
// 表: Dim_ColMetric_Fulfillment_PB_Merchandise
// 类型: 维度表（Dim_ 前缀），断开维度
// 用途: 定义 PB Merchandise 矩阵的列维度（KPIGroup > ColName）
// 范围: Performance By Merchandise — 子模块三 BOSS Performance Details
//       从 4. Avg. No. of Store Passed Before Order Got Accepted 开始
// 说明: 7 个 KPI 分组，覆盖流转效率、比率、订单量、件数、金额等维度
//       指标 4、5 数据底表为 a02_e2e_boss_fulfillment_request_data_d
//       其余指标数据底表为 a02_e2e_boss_performance_summary_d
//
// 字段说明:
//   Metric_ID              主键（全局唯一），从 1 开始递增
//   KPIGroup               Level 1: KPI 分组名
//   ColName                Level 2: 列名（由于同名指标太多，格式为 Metric_ID+指标名称，如 1-Act, 2-LY）
//   KPIGroup_Sort          Level 1 排序（步长 10 便于扩展）
//   ColName_Sort           Level 2 排序（同名 ColType 对应相同 ColName_Sort）
//   ColType                列类型标识：Act / LY / vs LY / Orders / Units / Amt / Times / Hours / Volume
//   KPI_CalcType           calc_type 标识（此部分指标均为 fulfillment）
//   Metric_Format_Act      当期 行格式
//   Metric_Format_LY       去年同期 行格式（与 Act 格式一致）
//   Metric_Format_VsLY     YOY/同比 行格式：
//                          - 金额/数量类：percent_1dp（今年/去年-1）
//                          - 比率类：delta_bp（今年-去年，差值bp）
//   Metric_IsCurrencyAmount BOOLEAN → 是否金额类指标（仅 Amt 类指标为 TRUE）
//   Metric_ColorPositive   正值颜色
//   Metric_ColorNegative   负值颜色
//   Metric_ColorZero       零值颜色
//   Metric_ColorDefault    默认颜色
//
// ColType → ColName_Sort 映射:
//   Act     → 100
//   LY      → 200
//   vs LY   → 300
//   Orders  → 11
//   Units   → 14
//   Amt     → 17
//   Times   → 21
//   Hours   → 22
//   Volume  → 23
//
// 同名区分机制（使用 Metric_ID 前缀）:
//   Power BI Sort by Column 要求同名字段只能绑定一个排序值，
//   通过在 ColName 开头拼接 Metric_ID，使各 KPI 同名值在底层字符串不同，
//   从而支持独立排序。
//
// 颜色约定:
//   正值（>0）：#1A9018 绿色
//   负值（<0）：#D64550 红色
//   零值（=0）：#E1C233 黄色
//   默认：#5f6165 深灰
// ========================================
DATATABLE(
    "Metric_ID",              INTEGER,    // 主键标识（全局唯一）
    "KPIGroup",               STRING,     // Level 1: KPI 分组名
    "ColName",                STRING,     // Level 2: 列名（Metric_ID + 指标名称，如 1-Act）
    "KPIGroup_Sort",          INTEGER,    // Level 1 排序（步长 10 便于扩展）
    "ColName_Sort",           INTEGER,    // Level 2 排序（同名 ColType 对应相同值，以参考文档为准）
    "ColType",                STRING,     // 列类型标识：Act / LY / vs LY / Orders / Units / Amt / Times / Hours / Volume
    "KPI_CalcType",           STRING,     // calc_type：fulfillment
    "Metric_Format_Act",      STRING,     // 当期 行格式
    "Metric_Format_LY",       STRING,     // 去年同期 行格式（与本期格式一致）
    "Metric_Format_VsLY",     STRING,     // YOY/同比 行格式
    "Metric_IsCurrencyAmount",BOOLEAN,    // 是否金额类（TRUE 才涉及汇率换算）
    "Metric_ColorPositive",   STRING,     // 正值颜色
    "Metric_ColorNegative",   STRING,     // 负值颜色
    "Metric_ColorZero",       STRING,     // 零值颜色
    "Metric_ColorDefault",    STRING,     // 默认颜色
    {
        // ════════════════════════════════════════════════════════════════
        // Order Processing Efficiency 分组 — O2O订单流转效率（小数类，独立指标无 LY/vs LY）
        // 数据底表: a02_e2e_boss_fulfillment_request_data_d
        // Act: decimal_1dp（保留一位小数，千分位）
        // ════════════════════════════════════════════════════════════════
        { 1,  "Order Processing Efficiency", "1-Avg. No. of Store Passed Before Order Got Accepted",  10, 1, "Avg. No. of Store Passed Before Order Got Accepted",  "fulfillment", "decimal_1dp", "decimal_1dp", "decimal_1dp", FALSE, "#1A9018", "#D64550", "#E1C233", "#5f6165" },
        { 2,  "Order Processing Efficiency", "2-Avg. Processing Time(Hour)",  10, 2, "Avg. Processing Time(Hour)",  "fulfillment", "decimal_1dp", "decimal_1dp", "decimal_1dp", FALSE, "#1A9018", "#D64550", "#E1C233", "#5f6165" },

        // ════════════════════════════════════════════════════════════════
        // Fulfillment% 分组 — O2O订单履约率（比率类）
        // 数据底表: a02_e2e_boss_performance_summary_d
        // Act/LY: percent_1dp；vs LY: delta_bp（今年-去年，差值bp）
        // ════════════════════════════════════════════════════════════════
        { 3,  "Fulfillment%",             "3-Act",    20, 100, "Act",   "fulfillment", "percent_1dp", "percent_1dp", "delta_bp",    FALSE, "#1A9018", "#D64550", "#E1C233", "#5f6165" },
        { 4,  "Fulfillment%",             "4-LY",     20, 200, "LY",    "fulfillment", "percent_1dp", "percent_1dp", "delta_bp",    FALSE, "#1A9018", "#D64550", "#E1C233", "#5f6165" },
        { 5,  "Fulfillment%",             "5-vs LY",  20, 300, "vs LY", "fulfillment", "delta_bp",    "delta_bp",    "delta_bp",    FALSE, "#1A9018", "#D64550", "#E1C233", "#5f6165" },

        // ════════════════════════════════════════════════════════════════
        // Request Order 分组 — O2O销售订单量/件数/金额（数量/金额类）
        // 数据底表: a02_e2e_boss_performance_summary_d
        // Act/LY: integer 或 currency；vs LY: percent_1dp
        // ════════════════════════════════════════════════════════════════
        { 6,  "Request Order",            "6-Orders",  30, 11,  "Orders", "fulfillment", "integer",     "integer",     "percent_1dp", FALSE, "#1A9018", "#D64550", "#E1C233", "#5f6165" },
        { 7,  "Request Order",            "7-LY",      30, 200, "LY",     "fulfillment", "integer",     "integer",     "percent_1dp", FALSE, "#1A9018", "#D64550", "#E1C233", "#5f6165" },
        { 8,  "Request Order",            "8-vs LY",   30, 300, "vs LY",  "fulfillment", "percent_1dp", "percent_1dp", "percent_1dp", FALSE, "#1A9018", "#D64550", "#E1C233", "#5f6165" },
        { 9,  "Request Order",            "9-Units",   30, 301,  "Units", "fulfillment", "integer",     "integer",     "percent_1dp", FALSE, "#1A9018", "#D64550", "#E1C233", "#5f6165" },
        { 10, "Request Order",            "10-LY",     30, 400, "LY ",    "fulfillment", "integer",     "integer",     "percent_1dp", FALSE, "#1A9018", "#D64550", "#E1C233", "#5f6165" },
        { 11, "Request Order",            "11-vs LY",  30, 500, "vs LY ", "fulfillment", "percent_1dp", "percent_1dp", "percent_1dp", FALSE, "#1A9018", "#D64550", "#E1C233", "#5f6165" },
        { 12, "Request Order",            "12-Amt",    30, 501,  "Amt",   "fulfillment", "currency",    "currency",    "percent_1dp", TRUE,  "#1A9018", "#D64550", "#E1C233", "#5f6165" },
        { 13, "Request Order",            "13-LY",     30, 600, "LY  ",   "fulfillment", "currency",    "currency",    "percent_1dp", TRUE,  "#1A9018", "#D64550", "#E1C233", "#5f6165" },
        { 14, "Request Order",            "14-vs LY",  30, 700, "vs LY  ","fulfillment", "percent_1dp", "percent_1dp", "percent_1dp", TRUE,  "#1A9018", "#D64550", "#E1C233", "#5f6165" },

        // ════════════════════════════════════════════════════════════════
        // Shipped Order 分组 — O2O已配货订单量/件数/金额（数量/金额类）
        // 数据底表: a02_e2e_boss_performance_summary_d
        // Act/LY: integer 或 currency；vs LY: percent_1dp
        // ════════════════════════════════════════════════════════════════
        { 15, "Shipped Order",            "15-Orders", 40, 11,  "Orders", "fulfillment", "integer",     "integer",     "percent_1dp", FALSE, "#1A9018", "#D64550", "#E1C233", "#5f6165" },
        { 16, "Shipped Order",            "16-LY",     40, 200, "LY",     "fulfillment", "integer",     "integer",     "percent_1dp", FALSE, "#1A9018", "#D64550", "#E1C233", "#5f6165" },
        { 17, "Shipped Order",            "17-vs LY",  40, 300, "vs LY",  "fulfillment", "percent_1dp", "percent_1dp", "percent_1dp", FALSE, "#1A9018", "#D64550", "#E1C233", "#5f6165" },
        { 18, "Shipped Order",            "18-Units",  40, 301, "Units",  "fulfillment", "integer",     "integer",     "percent_1dp", FALSE, "#1A9018", "#D64550", "#E1C233", "#5f6165" },
        { 19, "Shipped Order",            "19-LY",     40, 400, "LY ",    "fulfillment", "integer",     "integer",     "percent_1dp", FALSE, "#1A9018", "#D64550", "#E1C233", "#5f6165" },
        { 20, "Shipped Order",            "20-vs LY",  40, 500, "vs LY ", "fulfillment", "percent_1dp", "percent_1dp", "percent_1dp", FALSE, "#1A9018", "#D64550", "#E1C233", "#5f6165" },
        { 21, "Shipped Order",            "21-Amt",    40, 501, "Amt",    "fulfillment", "currency",    "currency",    "percent_1dp", TRUE,  "#1A9018", "#D64550", "#E1C233", "#5f6165" },
        { 22, "Shipped Order",            "22-LY",     40, 600, "LY  ",   "fulfillment", "currency",    "currency",    "percent_1dp", TRUE,  "#1A9018", "#D64550", "#E1C233", "#5f6165" },
        { 23, "Shipped Order",            "23-vs LY",  40, 700, "vs LY  ","fulfillment", "percent_1dp", "percent_1dp", "percent_1dp", TRUE,  "#1A9018", "#D64550", "#E1C233", "#5f6165" },

        // ════════════════════════════════════════════════════════════════
        // Unfulfillment% 分组 — O2O订单未履约率（比率类）
        // 数据底表: a02_e2e_boss_performance_summary_d
        // Act/LY: percent_1dp；vs LY: delta_bp
        // ════════════════════════════════════════════════════════════════
        { 24, "Unfulfillment%",           "24-Act",    50, 100, "Act",   "fulfillment", "percent_1dp", "percent_1dp", "delta_bp",    FALSE, "#1A9018", "#D64550", "#E1C233", "#5f6165" },
        { 25, "Unfulfillment%",           "25-LY",     50, 200, "LY",    "fulfillment", "percent_1dp", "percent_1dp", "delta_bp",    FALSE, "#1A9018", "#D64550", "#E1C233", "#5f6165" },
        { 26, "Unfulfillment%",           "26-vs LY",  50, 300, "vs LY", "fulfillment", "delta_bp",    "delta_bp",    "delta_bp",    FALSE, "#1A9018", "#D64550", "#E1C233", "#5f6165" },

        // ════════════════════════════════════════════════════════════════
        // Unfulfilled Order 分组 — O2O失败订单数/件数/金额（数量/金额类）
        // 数据底表: a02_e2e_boss_performance_summary_d
        // Act/LY: integer 或 currency；vs LY: percent_1dp
        // ════════════════════════════════════════════════════════════════
        { 27, "Unfulfilled Order",        "27-Orders", 60, 11,  "Orders", "fulfillment", "integer",     "integer",     "percent_1dp", FALSE, "#1A9018", "#D64550", "#E1C233", "#5f6165" },
        { 28, "Unfulfilled Order",        "28-LY",     60, 200, "LY",     "fulfillment", "integer",     "integer",     "percent_1dp", FALSE, "#1A9018", "#D64550", "#E1C233", "#5f6165" },
        { 29, "Unfulfilled Order",        "29-vs LY",  60, 300, "vs LY",  "fulfillment", "percent_1dp", "percent_1dp", "percent_1dp", FALSE, "#1A9018", "#D64550", "#E1C233", "#5f6165" },
        { 30, "Unfulfilled Order",        "30-Units",  60, 301, "Units",  "fulfillment", "integer",     "integer",     "percent_1dp", FALSE, "#1A9018", "#D64550", "#E1C233", "#5f6165" },
        { 31, "Unfulfilled Order",        "31-LY",     60, 400, "LY ",    "fulfillment", "integer",     "integer",     "percent_1dp", FALSE, "#1A9018", "#D64550", "#E1C233", "#5f6165" },
        { 32, "Unfulfilled Order",        "32-vs LY",  60, 500, "vs LY ", "fulfillment", "percent_1dp", "percent_1dp", "percent_1dp", FALSE, "#1A9018", "#D64550", "#E1C233", "#5f6165" },
        { 33, "Unfulfilled Order",        "33-Amt",    60, 501, "Amt",    "fulfillment", "currency",    "currency",    "percent_1dp", TRUE,  "#1A9018", "#D64550", "#E1C233", "#5f6165" },
        { 34, "Unfulfilled Order",        "34-LY",     60, 600, "LY  ",   "fulfillment", "currency",    "currency",    "percent_1dp", TRUE,  "#1A9018", "#D64550", "#E1C233", "#5f6165" },
        { 35, "Unfulfilled Order",        "35-vs LY",  60, 700, "vs LY  ","fulfillment", "percent_1dp", "percent_1dp", "percent_1dp", TRUE,  "#1A9018", "#D64550", "#E1C233", "#5f6165" },

        // ════════════════════════════════════════════════════════════════
        // Product Volume 分组 — SKU商品的数量（整数类，独立指标无 LY/vs LY）
        // 数据底表: a02_e2e_boss_performance_summary_d
        // Act: integer
        // ════════════════════════════════════════════════════════════════
        { 36, "Product Volume", "36-Product Volume", 70, 23,  "          ", "fulfillment", "integer", "integer", "percent_1dp", FALSE, "#1A9018", "#D64550", "#E1C233", "#5f6165" }
    }
)
