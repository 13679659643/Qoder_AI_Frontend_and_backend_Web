Dim_ColMetric_Customer_Performance_Indicator =
// ========================================
// 表: Dim_ColMetric_Customer_Performance_Indicator
// 类型: 维度表（Dim_ 前缀），断开维度
// 用途: 定义 Customer Dashboard - Customer Tab 的 Performance Indicator 矩阵列维度（KPIGroup > ColName）
// 范围: 口径文档/Customer/Performance Indicator.md - 子模块二（6 个 KPI 分组，共 18 列指标）
// 数据底表: a03_e2e_customer_data_m
//
// 设计原则（遵循口径文档要求）:
//   1. 每个指标对应一个格式 → 仅保留单个 Metric_Format 字段
//   2. 行格式严格遵循口径文档数据类型定义
//   3. 颜色规则通过 Metric_ColorRule 字段标识，由 Cell Font Color 度量值统一调度
//      - "fixed_black"   → 始终 #252423（Act 基础指标，含金额类与数量类）
//      - "pos_neg_zero"  → 按值正/负/零取色（vs LY / vs LP 派生指标）
//   4. 新增 Metric_IsCurrencyAmount（BOOLEAN）字段：
//      - TRUE  → 金额类指标（DCom SLS / ACV / AUR 的 Act 列），涉及汇率换算与币种符号拼接
//      - FALSE → 非金额类指标（Customer No. / Freq. / UPT 的 Act 列，以及全部 vs LY / vs LP 列）
//      注意：vs LY / vs LP 为派生百分比指标，无论主指标是否金额类，均不涉及汇率换算 → FALSE
//
// 字段说明:
//   Metric_ID                主键（全局唯一 1-18）
//   KPIGroup                 Level 1: KPI 分组名（6 个：DCom SLS / Customer No. / ACV / AUR / Freq. / UPT）
//   ColName                  Level 2: 列名（Metric_ID + 指标名称，避免同名冲突，支持独立排序）
//   KPIGroup_Sort            Level 1 排序（步长 10）
//   ColName_Sort             Level 2 排序（同组内 Act=100, vs LY=200, vs LP=300）
//   ColType                  列类型标识：Act / vs LY / vs LP
//   Metric_Format            单一格式字段（严格对应口径文档数据类型）
//                            取值: currency / integer / delta_pct_0dp
//   Metric_IsCurrencyAmount  是否金额类（TRUE 才涉及汇率换算与币种符号拼接）
//   Metric_ColorRule         字体颜色规则：fixed_black / pos_neg_zero
//   Metric_ColorPositive     正值颜色（pos_neg_zero 规则使用）
//   Metric_ColorNegative     负值颜色（pos_neg_zero 规则使用）
//   Metric_ColorZero         零值颜色（pos_neg_zero 规则使用）
//   Metric_ColorDefault      默认颜色（pos_neg_zero 在 BLANK 时兜底）
//
// Metric_Format 取值与口径文档数据类型对应关系（严格遵循口径文档）:
//   currency       → __CurrencySymbol & FORMAT(__Value, "#,##0")   货币符号+整数千分位（SLS / ACV / AUR 的 Act 列）
//   integer        → FORMAT(__Value, "#,##0")                      整数千分位（Customer No. / Freq. / UPT 的 Act 列）
//   delta_pct_0dp  → IF(__Value>0,"+","") & FORMAT(__Value,"#,##0%")  百分比整数变化含正号（全部 vs LY / vs LP）
//
// 口径文档明确: 所有附属指标数据类型 = delta_pct_0dp（百分比整数，含正号：+15% / -3%）
//
// 同名区分机制（ColName 加 Metric_ID 前缀）:
//   Power BI Sort by Column 要求同名字段只能绑定一个排序值，
//   通过在 ColName 开头拼接 Metric_ID，使各 KPI 同名值在底层字符串不同，支持独立排序。
//
// 颜色约定:
//   正值（>0）：#1A9018 绿色
//   负值（<0）：#D64550 红色
//   零值（=0）：#E1C233 黄色
//   默认      ：#5F6165 深灰（pos_neg_zero 在 BLANK 时兜底）
//   固定黑色  ：#252423
// ========================================
DATATABLE(
    "Metric_ID",                INTEGER,    // 主键标识（全局唯一 1-18）
    "KPIGroup",                 STRING,     // Level 1: KPI 分组名
    "ColName",                  STRING,     // Level 2: 列名（Metric_ID + 指标名称）
    "KPIGroup_Sort",            INTEGER,    // Level 1 排序（步长 10）
    "ColName_Sort",             INTEGER,    // Level 2 排序
    "ColType",                  STRING,     // 列类型标识：Act / vs LY / vs LP
    "Metric_Format",            STRING,     // 单一格式字段（严格对应口径文档数据类型）
    "Metric_IsCurrencyAmount",  BOOLEAN,    // 是否金额类（TRUE 才涉及汇率换算与币种符号拼接）
    "Metric_ColorRule",         STRING,     // 字体颜色规则
    "Metric_ColorPositive",     STRING,     // 正值颜色
    "Metric_ColorNegative",     STRING,     // 负值颜色
    "Metric_ColorZero",         STRING,     // 零值颜色
    "Metric_ColorDefault",      STRING,     // 默认颜色
    {
        // ════════════════════════════════════════════════════════════════
        // 分组 1：DCom SLS — 销售额（3 列）
        // 口径: sum(amt)（Net: net_pay_amt / Demand: pay_amt）
        // 数据类型: currency（货币符号+整数千分位）
        // 颜色规则: Act=固定黑；vs LY/vs LP=正负零三色
        // ════════════════════════════════════════════════════════════════
        { 1,  "DCom SLS",     "1-DCom SLS",          10, 100, "Act",   "currency",       TRUE,  "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 2,  "DCom SLS",     "2-DCom SLS vs LY",    10, 200, "vs LY", "delta_pct_0dp",  FALSE, "pos_neg_zero", "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 3,  "DCom SLS",     "3-DCom SLS vs LP",    10, 300, "vs LP", "delta_pct_0dp",  FALSE, "pos_neg_zero", "#1A9018", "#D64550", "#E1C233", "#5F6165" },

        // ════════════════════════════════════════════════════════════════
        // 分组 2：Customer No. — 买家人数（3 列）
        // 口径: count(distinct user_id)
        // 数据类型: integer（整数千分位）
        // 颜色规则: Act=固定黑；vs LY/vs LP=正负零三色
        // ════════════════════════════════════════════════════════════════
        { 4,  "Customer No.", "4-Customer No.",          20, 100, "Act",   "integer",       FALSE, "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 5,  "Customer No.", "5-Customer No. vs LY",    20, 200, "vs LY", "delta_pct_0dp",  FALSE, "pos_neg_zero", "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 6,  "Customer No.", "6-Customer No. vs LP",    20, 300, "vs LP", "delta_pct_0dp",  FALSE, "pos_neg_zero", "#1A9018", "#D64550", "#E1C233", "#5F6165" },

        // ════════════════════════════════════════════════════════════════
        // 分组 3：ACV — 客单价（3 列）
        // 口径: 分子 sum(amt)；分母 count(distinct user_id)
        // 数据类型: currency（货币符号+整数千分位）
        // 颜色规则: Act=固定黑；vs LY/vs LP=正负零三色
        // ════════════════════════════════════════════════════════════════
        { 7,  "ACV",          "7-ACV",          30, 100, "Act",   "currency",       TRUE,  "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 8,  "ACV",          "8-ACV vs LY",    30, 200, "vs LY", "delta_pct_0dp",  FALSE, "pos_neg_zero", "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 9,  "ACV",          "9-ACV vs LP",    30, 300, "vs LP", "delta_pct_0dp",  FALSE, "pos_neg_zero", "#1A9018", "#D64550", "#E1C233", "#5F6165" },

        // ════════════════════════════════════════════════════════════════
        // 分组 4：AUR — 件单价（3 列）
        // 口径: 分子 sum(amt)；分母 sum(qty)
        // 数据类型: currency（货币符号+整数千分位）
        // 颜色规则: Act=固定黑；vs LY/vs LP=正负零三色
        // ════════════════════════════════════════════════════════════════
        { 10, "AUR",          "10-AUR",          40, 100, "Act",   "currency",       TRUE,  "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 11, "AUR",          "11-AUR vs LY",    40, 200, "vs LY", "delta_pct_0dp",  FALSE, "pos_neg_zero", "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 12, "AUR",          "12-AUR vs LP",    40, 300, "vs LP", "delta_pct_0dp",  FALSE, "pos_neg_zero", "#1A9018", "#D64550", "#E1C233", "#5F6165" },

        // ════════════════════════════════════════════════════════════════
        // 分组 5：Freq. — 购买频次（3 列）
        // 口径: 分子 sum(order_cnt)；分母 count(distinct user_id)
        // 数据类型: integer（整数千分位）
        // 颜色规则: Act=固定黑；vs LY/vs LP=正负零三色
        // ════════════════════════════════════════════════════════════════
        { 13, "Freq.",        "13-Freq.",        50, 100, "Act",   "integer",       FALSE, "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 14, "Freq.",        "14-Freq. vs LY",  50, 200, "vs LY", "delta_pct_0dp", FALSE, "pos_neg_zero", "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 15, "Freq.",        "15-Freq. vs LP",  50, 300, "vs LP", "delta_pct_0dp", FALSE, "pos_neg_zero", "#1A9018", "#D64550", "#E1C233", "#5F6165" },

        // ════════════════════════════════════════════════════════════════
        // 分组 6：UPT — 客单件（3 列）
        // 口径: 分子 sum(qty)；分母 sum(order_cnt)
        // 数据类型: integer（整数千分位）
        // 颜色规则: Act=固定黑；vs LY/vs LP=正负零三色
        // ════════════════════════════════════════════════════════════════
        { 16, "UPT",          "16-UPT",          60, 100, "Act",   "integer",       FALSE, "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 17, "UPT",          "17-UPT vs LY",    60, 200, "vs LY", "delta_pct_0dp", FALSE, "pos_neg_zero", "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 18, "UPT",          "18-UPT vs LP",    60, 300, "vs LP", "delta_pct_0dp", FALSE, "pos_neg_zero", "#1A9018", "#D64550", "#E1C233", "#5F6165" }
    }
)
