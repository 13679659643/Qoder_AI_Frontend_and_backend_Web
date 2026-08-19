Dim_ColMetric_Customer_KPIs =
// ========================================
// 表: Dim_ColMetric_Customer_KPIs
// 类型: 维度表（Dim_ 前缀），断开维度
// 用途: 定义 Customer Dashboard - Customer Tab 的 Customer KPI 矩阵列维度（KPIGroup > ColName）
// 范围: 口径文档/Customer/Customer KPI.md - 子模块一 Customer KPI（2 个 KPI 分组，共 10 列指标）
// 数据底表（实际值）: a03_e2e_customer_data_m
// 数据底表（目标值）: a03_e2e_customer_fcst_data_m
//
// 设计原则（遵循口径文档要求）:
//   1. 每个指标对应一个格式 → 仅保留单个 Metric_Format 字段（不再分 Act/LY/VsLY）
//   2. 行格式严格遵循口径文档数据类型定义
//   3. 颜色规则通过 Metric_ColorRule 字段标识，由 Cell Font Color 度量值统一调度
//      - "fixed_black"       → 始终 #252423（Customer No. 基础指标 Act 列）
//      - "pos_neg_zero"     → 按值正/负/零取色（vs LY / vs LP / TAR ACH%）
//      - "fixed_default"    → 取 Metric_ColorDefault（Customer% 基础指标 Act 列，避免与黑色冲突）
//
// 字段说明:
//   Metric_ID              主键（全局唯一 1-10）
//   KPIGroup               Level 1: KPI 分组名（2 个：Customer No. / Customer%）
//   ColName                Level 2: 列名（Metric_ID + 指标名称，避免同名冲突，支持独立排序）
//   KPIGroup_Sort          Level 1 排序（步长 10）
//   ColName_Sort           Level 2 排序（同组内 Act=100, vs LY=200, vs LP=300, Monthly TAR=400, Yearly TAR=410）
//   ColType                列类型标识：Act / vs LY / vs LP / TAR ACH% Monthly / TAR ACH% Yearly
//   Metric_Format          单一格式字段（严格对应口径文档数据类型）
//                          取值: integer / percent_1dp / delta_pct_1dp / delta_pts
//   Metric_ColorRule       字体颜色规则：fixed_black / pos_neg_zero / fixed_default
//   Metric_ColorPositive   正值颜色（pos_neg_zero 规则使用）
//   Metric_ColorNegative   负值颜色（pos_neg_zero 规则使用）
//   Metric_ColorZero       零值颜色（pos_neg_zero 规则使用）
//   Metric_ColorDefault    默认颜色（fixed_default 规则使用，以及 pos_neg_zero 在 BLANK 时兜底）
//
// Metric_Format 取值与口径文档数据类型对应关系:
//   integer         → `#,##0`                              整数千分位（DCom New Customer No. Act）
//   percent_1dp     → `#,##0.0%`                           百分比一位小数，不含正号（DCom New Customer% Act / 4 个 TAR ACH%）
//   delta_pct_1dp   → `IF(__Value>0,"+","") & FORMAT(__Value,"#,##0.0%")`  百分比变化，含正号（Customer No. vs LY / vs LP）
//   delta_pts       → `+#,##0pts;-#,##0pts;0pts`           基点（pts），含正负号，值×100 转 pts 在 Cell Display 中实现（Customer% vs LY / vs LP）
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
    "Metric_ID",              INTEGER,    // 主键标识（全局唯一 1-10）
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
        // 分组 1：Customer No. — DCom 新客数（5 列）
        // 口径: count(distinct user_id) where net_pay_amt>0 AND lp_12m_net_pay_amt=0 AND is_member=0
        // 颜色规则: Act=固定黑；vs LY/vs LP/TAR ACH% Monthly/TAR ACH% Yearly=正负零三色
        // ════════════════════════════════════════════════════════════════
        { 1,  "Customer No.", "1-DCom New Customer No.",            10, 100, "Act",              "integer",       "fixed_black",   "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 2,  "Customer No.", "2-DCom New Customer No. vs LY",     10, 200, "vs LY",            "delta_pct_0dp", "pos_neg_zero",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 3,  "Customer No.", "3-DCom New Customer No. vs LP",     10, 300, "vs LP",            "delta_pct_0dp", "pos_neg_zero",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 4,  "Customer No.", "4-Customer Monthly TAR ACH%",       10, 400, "TAR ACH% Monthly", "percent_1dp",   "pos_neg_zero",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 5,  "Customer No.", "5-Customer Yearly TAR ACH%",        10, 410, "TAR ACH% Yearly",  "percent_1dp",   "pos_neg_zero",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },

        // ════════════════════════════════════════════════════════════════
        // 分组 2：Customer% — DCom 新客占比（5 列）
        // 口径: 分子 DCom New Customer No.；分母 count(distinct user_id) where net_pay_amt>0 AND is_member=0
        // 颜色规则: Act=默认色；vs LY/vs LP=正负零三色；TAR ACH% Monthly/TAR ACH% Yearly=正负零三色
        // ════════════════════════════════════════════════════════════════
        { 6,  "Customer%",    "6-DCom New Customer%",               20, 100, "Act",              "percent_1dp",   "fixed_default", "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 7,  "Customer%",    "7-DCom New Customer% vs LY",        20, 200, "vs LY",            "delta_pts",     "pos_neg_zero",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 8,  "Customer%",    "8-DCom New Customer% vs LP",        20, 300, "vs LP",            "delta_pts",     "pos_neg_zero",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 9,  "Customer%",    "9-Customer% Monthly TAR ACH%",      20, 400, "TAR ACH% Monthly", "percent_1dp",   "pos_neg_zero",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 10, "Customer%",    "10-Customer% Yearly TAR ACH%",      20, 410, "TAR ACH% Yearly",  "percent_1dp",   "pos_neg_zero",  "#1A9018", "#D64550", "#E1C233", "#5F6165" }
    }
)
