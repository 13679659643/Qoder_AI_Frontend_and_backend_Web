Dim_ColMetric_VIC_KPIs =
// ========================================
// 表: Dim_ColMetric_VIC_KPIs
// 类型: 维度表（Dim_ 前缀），断开维度
// 用途: 定义 Customer Dashboard - VIC Tab 的 KPI 矩阵列维度（KPIGroup > ColName）
// 范围: 口径文档/VIC KPI.md - 子模块一 VIC KPI（5 个 KPI 分组，共 28 列指标）
// 数据底表: a03_e2e_customer_data_m
//
// 设计原则（遵循口径文档要求）:
//   1. 每个指标对应一个格式 → 仅保留单个 Metric_Format 字段（不再分 Act/LY/VsLY）
//   2. 行格式严格遵循口径文档数据类型定义
//   3. 颜色规则通过 Metric_ColorRule 字段标识，由 Cell Font Color 度量值统一调度
//      - "fixed_black"       → 始终 #252423（基础指标 VIC No. / VIC Retention% / T4-5 Upgrade No.）
//      - "pos_neg_zero"      → 按值正/负/零取色（vs LY / vs LP / Share vs LY / Share vs LP / TAR ACH%）
//      - "fixed_default"     → 取 Metric_ColorDefault（其余基础/占比指标）
//
// 字段说明:
//   Metric_ID              主键（全局唯一 1-28）
//   KPIGroup               Level 1: KPI 分组名（5 个）
//   ColName                Level 2: 列名（Metric_ID + 指标名称，避免同名冲突，支持独立排序）
//   KPIGroup_Sort          Level 1 排序（步长 10）
//   ColName_Sort           Level 2 排序（同组内 Act=100, vs LY=200, vs LP=300, TAR=400, Share=500, Share vs LY=600, Share vs LP=700）
//   ColType                列类型标识：Act / vs LY / vs LP / TAR ACH% Monthly / TAR ACH% Yearly / TAR ACH% / Share / Share vs LY / Share vs LP
//   Metric_Format          单一格式字段（严格对应口径文档数据类型）
//                          取值: integer / percent_1dp / percent_1dp / delta_pct_1dp / delta_pts
//   Metric_ColorRule       字体颜色规则：fixed_black / pos_neg_zero / fixed_default
//   Metric_ColorPositive   正值颜色（pos_neg_zero 规则使用）
//   Metric_ColorNegative   负值颜色（pos_neg_zero 规则使用）
//   Metric_ColorZero       零值颜色（pos_neg_zero 规则使用）
//   Metric_ColorDefault    默认颜色（fixed_default 规则使用，以及 pos_neg_zero 在 BLANK 时兜底）
//
// Metric_Format 取值与口径文档数据类型对应关系:
//   integer              → `#,##0`                              整数千分位
//   percent_1dp          → `#,##0.0%`                           百分比一位小数不含正负号（TAR ACH%）
//   percent_1dp          → `#,##0.0%`                           百分比一位小数不含正号（VIC Retention% / Share / Retention VIC No. vs LY）
//   delta_pct_1dp        → `IF(__Value>0,"+","") & FORMAT(__Value,"#,##0.0%")`  百分比变化含正号
//   delta_pts            → `+#,##0pts;-#,##0pts;0pts`           基点（pts）含正负号，值×100 转 pts 在 Cell Display 中实现
//
// 同名区分机制（ColName 加 Metric_ID 前缀）:
//   Power BI Sort by Column 要求同名字段只能绑定一个排序值，
//   通过在 ColName 开头拼接 Metric_ID，使各 KPI 同名值在底层字符串不同，支持独立排序。
//
// 颜色约定:
//   正值（>0）：#1A9018 绿色
//   负值（<0）：#D64550 红色
//   零值（=0）：#E1C233 黄色
//   默认      ：#5F6165 深灰
//   固定黑色  ：#252423
// ========================================
DATATABLE(
    "Metric_ID",              INTEGER,    // 主键标识（全局唯一 1-28）
    "KPIGroup",               STRING,     // Level 1: KPI 分组名
    "ColName",                STRING,     // Level 2: 列名（Metric_ID + 指标名称）
    "KPIGroup_Sort",          INTEGER,    // Level 1 排序（步长 10）
    "ColName_Sort",           INTEGER,    // Level 2 排序
    "ColType",                STRING,     // 列类型标识
    "Metric_Format",          STRING,     // 单一格式字段（严格对应口径文档数据类型）
    "Metric_ColorRule",       STRING,     // 字体颜色规则
    "Metric_ColorPositive",   STRING,     // 正值颜色
    "Metric_ColorNegative",   STRING,     // 负值颜色
    "Metric_ColorZero",       STRING,     // 零值颜色
    "Metric_ColorDefault",    STRING,     // 默认颜色
    {
        // ════════════════════════════════════════════════════════════════
        // 分组 1：VIC No. — VIC 数量（5 列）
        // 口径: count(distinct user_id) where is_vic=1，聚合粒度 dt=end period
        // 颜色规则: Act=固定黑；vs LY/vs LP=正负零三色；TAR ACH%=正负零三色
        // ════════════════════════════════════════════════════════════════
        { 1,  "VIC No.",          "1-VIC No.",                  10, 100, "Act",              "integer",            "fixed_black",   "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 2,  "VIC No.",          "2-VIC No. vs LY",            10, 200, "vs LY",            "delta_pct_1dp",      "pos_neg_zero",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 3,  "VIC No.",          "3-VIC No. vs LP",            10, 300, "vs LP",            "delta_pct_1dp",      "pos_neg_zero",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 4,  "VIC No.",          "4-VIC Monthly TAR ACH%",     10, 400, "TAR ACH% Monthly", "percent_1dp",        "pos_neg_zero",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 5,  "VIC No.",          "5-VIC Yearly TAR ACH%",      10, 410, "TAR ACH% Yearly",  "percent_1dp",        "pos_neg_zero",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },

        // ════════════════════════════════════════════════════════════════
        // 分组 2：VIC Retention% — VIC 留存率（4 列）
        // 口径: 分子 is_retention_vic=1 / 分母 is_vic=1，聚合粒度 dt=end period
        // 颜色规则: Act=固定黑；vs LY/vs LP=正负零三色；TAR ACH%=正负零三色
        // ════════════════════════════════════════════════════════════════
        { 6,  "VIC Retention%",   "6-VIC Retention%",            20, 100, "Act",              "percent_1dp",       "fixed_black",   "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 7,  "VIC Retention%",   "7-VIC Retention% vs LY",     20, 200, "vs LY",            "delta_pts",          "pos_neg_zero",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 8,  "VIC Retention%",   "8-VIC Retention% vs LP",     20, 300, "vs LP",            "delta_pts",          "pos_neg_zero",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 9,  "VIC Retention%",   "9-VIC Retention% TAR ACH%",  20, 420, "TAR ACH%",         "percent_1dp",        "pos_neg_zero",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },

        // ════════════════════════════════════════════════════════════════
        // 分组 3：T4-5 Upgrade No. — T4-5 升级为 VIC 人数（7 列）
        // 口径: 主指标 count(distinct user_id) where is_upgrade_vic=1
        //       Share 分子 is_upgrade_vic=1，分母 is_vic=1
        // 颜色规则: Act=固定黑；vs LY/vs LP/TAR ACH%/Share vs LY/Share vs LP=正负零三色；Share=默认色
        // ════════════════════════════════════════════════════════════════
        { 10, "T4-5 Upgrade No.", "10-T4-5 Upgrade No.",                 30, 100, "Act",         "integer",            "fixed_black",   "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 11, "T4-5 Upgrade No.", "11-T4-5 Upgrade No. vs LY",           30, 200, "vs LY",       "delta_pct_1dp",      "pos_neg_zero",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 12, "T4-5 Upgrade No.", "12-T4-5 Upgrade No. vs LP",           30, 300, "vs LP",       "delta_pct_1dp",      "pos_neg_zero",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 13, "T4-5 Upgrade No.", "13-T4-5 Upgrade No. TAR ACH%",        30, 420, "TAR ACH%",    "percent_1dp",        "pos_neg_zero",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 14, "T4-5 Upgrade No.", "14-T4-5 Upgrade No. Share",           30, 500, "Share",       "percent_1dp",        "fixed_default", "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 15, "T4-5 Upgrade No.", "15-T4-5 Upgrade No. Share vs LY",     30, 600, "Share vs LY", "delta_pts",          "pos_neg_zero",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 16, "T4-5 Upgrade No.", "16-T4-5 Upgrade No. Share vs LP",     30, 700, "Share vs LP", "delta_pts",          "pos_neg_zero",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },

        // ════════════════════════════════════════════════════════════════
        // 分组 4：Retention VIC No. — 留存 VIC 人数（6 列）
        // 口径: 主指标 count(distinct user_id) where is_retention_vic=1
        //       Share 分子 is_retention_vic=1，分母 is_vic=1
        // 注意 4.1 vs LY 数据类型为 percent_1dp（严格遵循口径文档）
        // 颜色规则: Act/Share=默认色；vs LY/vs LP/Share vs LY/Share vs LP=正负零三色
        // ════════════════════════════════════════════════════════════════
        { 17, "Retention VIC No.", "17-Retention VIC No.",                 40, 100, "Act",         "integer",            "fixed_default", "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 18, "Retention VIC No.", "18-Retention VIC No. vs LY",           40, 200, "vs LY",       "percent_1dp",        "pos_neg_zero",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 19, "Retention VIC No.", "19-Retention VIC No. vs LP",           40, 300, "vs LP",       "delta_pct_1dp",      "pos_neg_zero",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 20, "Retention VIC No.", "20-Retention VIC No. Share",           40, 500, "Share",       "percent_1dp",        "fixed_default", "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 21, "Retention VIC No.", "21-Retention VIC No. Share vs LY",     40, 600, "Share vs LY", "delta_pts",          "pos_neg_zero",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 22, "Retention VIC No.", "22-Retention VIC No. Share vs LP",     40, 700, "Share vs LP", "delta_pts",          "pos_neg_zero",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },

        // ════════════════════════════════════════════════════════════════
        // 分组 5：Direct VIC No. — 直接买成 VIC 人数（6 列）
        // 口径: 主指标 count(distinct user_id) where is_direct_vic=1
        //       Share 分子 is_direct_vic=1，分母 is_vic=1
        // 颜色规则: Act/Share=默认色；vs LY/vs LP/Share vs LY/Share vs LP=正负零三色
        // ════════════════════════════════════════════════════════════════
        { 23, "Direct VIC No.",    "23-Direct VIC No.",                 50, 100, "Act",         "integer",            "fixed_default", "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 24, "Direct VIC No.",    "24-Direct VIC No. vs LY",           50, 200, "vs LY",       "delta_pct_1dp",      "pos_neg_zero",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 25, "Direct VIC No.",    "25-Direct VIC No. vs LP",           50, 300, "vs LP",       "delta_pct_1dp",      "pos_neg_zero",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 26, "Direct VIC No.",    "26-Direct VIC No. Share",           50, 500, "Share",       "percent_1dp",        "fixed_default", "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 27, "Direct VIC No.",    "27-Direct VIC No. Share vs LY",     50, 600, "Share vs LY", "delta_pts",          "pos_neg_zero",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 28, "Direct VIC No.",    "28-Direct VIC No. Share vs LP",     50, 700, "Share vs LP", "delta_pts",          "pos_neg_zero",  "#1A9018", "#D64550", "#E1C233", "#5F6165" }
    }
)
