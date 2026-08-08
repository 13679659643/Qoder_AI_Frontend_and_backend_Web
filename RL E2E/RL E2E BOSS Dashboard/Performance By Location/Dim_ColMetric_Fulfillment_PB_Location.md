Dim_ColMetric_Fulfillment_PB_Location = 
// ========================================
// 表: Dim_ColMetric_Sales_PB_Location
// 类型: 维度表（Dim_ 前缀），断开维度
// 用途: 定义 PB Location Sales 矩阵的列维度（KPIGroup > ColName）
// 范围: Performance By Location — 从 6. Fulfillment% 开始的剩余指标
// 说明: 11 个 KPI 分组，覆盖比率、订单量、件数、金额等维度
//       KPIGroup 分组从行维度迁移，列类型从列维度保留
//
// 字段说明:
//   Metric_ID              主键（全局唯一），从 1 开始递增
//   KPIGroup               Level 1: KPI 分组名
//   ColName                Level 2: 列名（由于同名指标太多，格式为 Metric_ID+指标名称，如 1-Act, 2-LY）
//   KPIGroup_Sort          Level 1 排序（步长 10 便于扩展）
//   ColName_Sort           Level 2 排序（全局唯一，跨分组步长 10，组内步长 1）
//   ColType                列类型标识：Act / LY / vs LY 或 Orders / Units / Amt 等
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
    "ColName_Sort",           INTEGER,    // Level 2 排序（全局唯一，跨分组步长 10，组内步长 1）
    "ColType",                STRING,     // 列类型标识：Act / LY / vs LY / Orders / Units / Amt 等
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
        // Fulfillment% 分组 — O2O订单履约率（比率类）
        // Act/LY: percent_1dp；vs LY: delta_bp（今年-去年，差值bp）
        // ════════════════════════════════════════════════════════════════
        { 1,  "Fulfillment%",             "1-Act",    10, 1,  "Act",   "fulfillment", "percent_1dp", "percent_1dp", "delta_bp",    FALSE, "#1A9018", "#D64550", "#E1C233", "#5f6165" },
        { 2,  "Fulfillment%",             "2-LY",     10, 200,  "LY",    "fulfillment", "percent_1dp", "percent_1dp", "delta_bp",    FALSE, "#1A9018", "#D64550", "#E1C233", "#5f6165" },
        { 3,  "Fulfillment%",             "3-vs LY",  10, 300,  "vs LY", "fulfillment", "delta_bp",    "delta_bp",    "delta_bp",    FALSE, "#1A9018", "#D64550", "#E1C233", "#5f6165" },

        // ════════════════════════════════════════════════════════════════
        // Request Order 分组 — O2O销售订单量/件数/金额（数量/金额类）
        // Act/LY: integer 或 currency；vs LY: percent_1dp
        // ════════════════════════════════════════════════════════════════
        { 4,  "Request Order",            "4-Orders",  20, 11, "Orders", "fulfillment", "integer",     "integer",     "percent_1dp", FALSE, "#1A9018", "#D64550", "#E1C233", "#5f6165" },
        { 5,  "Request Order",            "5-LY",      20, 200, "LY",     "fulfillment", "integer",     "integer",     "percent_1dp", FALSE, "#1A9018", "#D64550", "#E1C233", "#5f6165" },
        { 6,  "Request Order",            "6-vs LY",   20, 300, "vs LY",  "fulfillment", "percent_1dp", "percent_1dp", "percent_1dp", FALSE, "#1A9018", "#D64550", "#E1C233", "#5f6165" },
        { 7,  "Request Order",            "7-Units",   20, 301, "Units",  "fulfillment", "integer",     "integer",     "percent_1dp", FALSE, "#1A9018", "#D64550", "#E1C233", "#5f6165" },
        { 8,  "Request Order",            "8-LY",      20, 400, "LY ",     "fulfillment", "integer",     "integer",     "percent_1dp", FALSE, "#1A9018", "#D64550", "#E1C233", "#5f6165" },
        { 9,  "Request Order",            "9-vs LY",   20, 500, "vs LY ",  "fulfillment", "percent_1dp", "percent_1dp", "percent_1dp", FALSE, "#1A9018", "#D64550", "#E1C233", "#5f6165" },
        { 10, "Request Order",            "10-Amt",    20, 501, "Amt",    "fulfillment", "currency",    "currency",    "percent_1dp", TRUE,  "#1A9018", "#D64550", "#E1C233", "#5f6165" },
        { 11, "Request Order",            "11-LY",     20, 600, "LY  ",     "fulfillment", "currency",    "currency",    "percent_1dp", TRUE,  "#1A9018", "#D64550", "#E1C233", "#5f6165" },
        { 12, "Request Order",            "12-vs LY",  20, 700, "vs LY  ",  "fulfillment", "percent_1dp", "percent_1dp", "percent_1dp", TRUE,  "#1A9018", "#D64550", "#E1C233", "#5f6165" },

        // ════════════════════════════════════════════════════════════════
        // Shipped Order 分组 — O2O已配货订单量/件数/金额（数量/金额类）
        // Act/LY: integer 或 currency；vs LY: percent_1dp
        // ════════════════════════════════════════════════════════════════
        { 13, "Shipped Order",            "13-Orders", 30, 11, "Orders", "fulfillment", "integer",     "integer",     "percent_1dp", FALSE, "#1A9018", "#D64550", "#E1C233", "#5f6165" },
        { 14, "Shipped Order",            "14-LY",     30, 200, "LY",     "fulfillment", "integer",     "integer",     "percent_1dp", FALSE, "#1A9018", "#D64550", "#E1C233", "#5f6165" },
        { 15, "Shipped Order",            "15-vs LY",  30, 300, "vs LY",  "fulfillment", "percent_1dp", "percent_1dp", "percent_1dp", FALSE, "#1A9018", "#D64550", "#E1C233", "#5f6165" },
        { 16, "Shipped Order",            "16-Units",  30, 301, "Units",  "fulfillment", "integer",     "integer",     "percent_1dp", FALSE, "#1A9018", "#D64550", "#E1C233", "#5f6165" },
        { 17, "Shipped Order",            "17-LY",     30, 400, "LY ",     "fulfillment", "integer",     "integer",     "percent_1dp", FALSE, "#1A9018", "#D64550", "#E1C233", "#5f6165" },
        { 18, "Shipped Order",            "18-vs LY",  30, 500, "vs LY ",  "fulfillment", "percent_1dp", "percent_1dp", "percent_1dp", FALSE, "#1A9018", "#D64550", "#E1C233", "#5f6165" },
        { 19, "Shipped Order",            "19-Amt",    30, 501, "Amt",    "fulfillment", "currency",    "currency",    "percent_1dp", TRUE,  "#1A9018", "#D64550", "#E1C233", "#5f6165" },
        { 20, "Shipped Order",            "20-LY",     30, 600, "LY  ",     "fulfillment", "currency",    "currency",    "percent_1dp", TRUE,  "#1A9018", "#D64550", "#E1C233", "#5f6165" },
        { 21, "Shipped Order",            "21-vs LY",  30, 700, "vs LY  ",  "fulfillment", "percent_1dp", "percent_1dp", "percent_1dp", TRUE,  "#1A9018", "#D64550", "#E1C233", "#5f6165" },

        // ════════════════════════════════════════════════════════════════
        // Unfulfillment% 分组 — O2O订单未履约率（比率类）
        // Act/LY: percent_1dp；vs LY: delta_bp
        // ════════════════════════════════════════════════════════════════
        { 22, "Unfulfillment%",           "22-Act",    40, 1, "Act",   "fulfillment", "percent_1dp", "percent_1dp", "delta_bp",    FALSE, "#1A9018", "#D64550", "#E1C233", "#5f6165" },
        { 23, "Unfulfillment%",           "23-LY",     40, 200, "LY",    "fulfillment", "percent_1dp", "percent_1dp", "delta_bp",    FALSE, "#1A9018", "#D64550", "#E1C233", "#5f6165" },
        { 24, "Unfulfillment%",           "24-vs LY",  40, 300, "vs LY", "fulfillment", "delta_bp",    "delta_bp",    "delta_bp",    FALSE, "#1A9018", "#D64550", "#E1C233", "#5f6165" },

        // ════════════════════════════════════════════════════════════════
        // Unfulfilled Order 分组 — O2O失败订单数/件数/金额（数量/金额类）
        // Act/LY: integer 或 currency；vs LY: percent_1dp
        // ════════════════════════════════════════════════════════════════
        { 25, "Unfulfilled Order",        "25-Orders", 50, 11, "Orders", "fulfillment", "integer",     "integer",     "percent_1dp", FALSE, "#1A9018", "#D64550", "#E1C233", "#5f6165" },
        { 26, "Unfulfilled Order",        "26-LY",     50, 200, "LY",     "fulfillment", "integer",     "integer",     "percent_1dp", FALSE, "#1A9018", "#D64550", "#E1C233", "#5f6165" },
        { 27, "Unfulfilled Order",        "27-vs LY",  50, 300, "vs LY",  "fulfillment", "percent_1dp", "percent_1dp", "percent_1dp", FALSE, "#1A9018", "#D64550", "#E1C233", "#5f6165" },
        { 28, "Unfulfilled Order",        "28-Units",  50, 301, "Units",  "fulfillment", "integer",     "integer",     "percent_1dp", FALSE, "#1A9018", "#D64550", "#E1C233", "#5f6165" },
        { 29, "Unfulfilled Order",        "29-LY",     50, 400, "LY",     "fulfillment", "integer",     "integer",     "percent_1dp", FALSE, "#1A9018", "#D64550", "#E1C233", "#5f6165" },
        { 30, "Unfulfilled Order",        "30-vs LY",  50, 500, "vs LY",  "fulfillment", "percent_1dp", "percent_1dp", "percent_1dp", FALSE, "#1A9018", "#D64550", "#E1C233", "#5f6165" },
        { 31, "Unfulfilled Order",        "31-Amt",    50, 501, "Amt",    "fulfillment", "currency",    "currency",    "percent_1dp", TRUE,  "#1A9018", "#D64550", "#E1C233", "#5f6165" },
        { 32, "Unfulfilled Order",        "32-LY",     50, 600, "LY",     "fulfillment", "currency",    "currency",    "percent_1dp", TRUE,  "#1A9018", "#D64550", "#E1C233", "#5f6165" },
        { 33, "Unfulfilled Order",        "33-vs LY",  50, 700, "vs LY",  "fulfillment", "percent_1dp", "percent_1dp", "percent_1dp", TRUE,  "#1A9018", "#D64550", "#E1C233", "#5f6165" },

        // ════════════════════════════════════════════════════════════════
        // Rejected Order 分组 — 拒单订单量与拒单率
        // ════════════════════════════════════════════════════════════════
        { 34, "Rejected Order",           "34-Orders",  60, 11, "Orders",  "fulfillment", "integer",     "integer",     "percent_1dp", FALSE, "#1A9018", "#D64550", "#E1C233", "#5f6165" },
        { 35, "Rejected Order",           "35-Reject%", 60, 52, "Reject%", "fulfillment", "percent_1dp", "percent_1dp", "delta_bp",    FALSE, "#1A9018", "#D64550", "#E1C233", "#5f6165" },

        // ════════════════════════════════════════════════════════════════
        // Cancelled Order by Overdue 分组 — 超时订单量与超时率
        // ════════════════════════════════════════════════════════════════
        { 36, "Cancelled Order by Overdue", "36-Orders",  70, 11, "Orders",   "fulfillment", "integer",     "integer",     "percent_1dp", FALSE, "#1A9018", "#D64550", "#E1C233", "#5f6165" },
        { 37, "Cancelled Order by Overdue", "37-Overdue%", 70, 62, "Overdue%", "fulfillment", "percent_1dp", "percent_1dp", "delta_bp",    FALSE, "#1A9018", "#D64550", "#E1C233", "#5f6165" },

        // ════════════════════════════════════════════════════════════════
        // Cancelled Order by Customer 分组 — 顾客取消订单量与顾客取消率
        // ════════════════════════════════════════════════════════════════
        { 38, "Cancelled Order by Customer", "38-Orders",  80, 11, "Orders",    "fulfillment", "integer",     "integer",     "percent_1dp", FALSE, "#1A9018", "#D64550", "#E1C233", "#5f6165" },
        { 39, "Cancelled Order by Customer", "39-Customer%", 80, 72, "Customer%", "fulfillment", "percent_1dp", "percent_1dp", "delta_bp",    FALSE, "#1A9018", "#D64550", "#E1C233", "#5f6165" },

        // ════════════════════════════════════════════════════════════════
        // Others 分组 — 其他失败订单量与失败率
        // ════════════════════════════════════════════════════════════════
        { 40, "Others",                  "40-Orders",  90, 11, "Orders",  "fulfillment", "integer",     "integer",     "percent_1dp", FALSE, "#1A9018", "#D64550", "#E1C233", "#5f6165" },
        { 41, "Others",                  "41-Others%", 90, 82, "Others%", "fulfillment", "percent_1dp", "percent_1dp", "delta_bp",    FALSE, "#1A9018", "#D64550", "#E1C233", "#5f6165" },

        // ════════════════════════════════════════════════════════════════
        // Failed Request 分组 — 失败次数与失败率
        // ════════════════════════════════════════════════════════════════
        { 42, "Failed Request",          "42-Request",  100, 91, "Request", "fulfillment", "integer",     "integer",     "percent_1dp", FALSE, "#1A9018", "#D64550", "#E1C233", "#5f6165" },
        { 43, "Failed Request",          "43-Failed%",  100, 92, "Failed%", "fulfillment", "percent_1dp", "percent_1dp", "delta_bp",    FALSE, "#1A9018", "#D64550", "#E1C233", "#5f6165" },

        // ════════════════════════════════════════════════════════════════
        // Inventory 分组 — 商品库存件数 (Total/BSR/Seasonal)
        // ════════════════════════════════════════════════════════════════
        { 44, "Inventory",               "44-Total Units",    110, 101, "Total Units",    "fulfillment", "integer",     "integer",     "percent_1dp", FALSE, "#1A9018", "#D64550", "#E1C233", "#5f6165" },
        { 45, "Inventory",               "45-BSR Units",      110, 102, "BSR Units",      "fulfillment", "integer",     "integer",     "percent_1dp", FALSE, "#1A9018", "#D64550", "#E1C233", "#5f6165" },
        { 46, "Inventory",               "46-Seasonal Units", 110, 103, "Seasonal Units", "fulfillment", "integer",     "integer",     "percent_1dp", FALSE, "#1A9018", "#D64550", "#E1C233", "#5f6165" }
    }
)