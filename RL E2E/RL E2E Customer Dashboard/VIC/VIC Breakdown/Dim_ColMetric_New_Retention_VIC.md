Dim_ColMetric_New_Retention_VIC =
// ========================================
// 表: Dim_ColMetric_New_Retention_VIC
// 类型: 维度表（Dim_ 前缀），断开维度
// 用途: 定义 Customer Dashboard - VIC Tab 的 DCom VIC Breakdown 矩阵列维度（VICType > KPIGroup > ColName）
// 范围: 口径文档/VIC Breakdown KPI.md - 子模块五 DCom VIC Breakdown（2 个大分组 × 6 个 KPI 分组，共 44 列指标）
// 数据底表: a03_e2e_customer_data_m
//
// 设计原则（遵循口径文档要求）:
//   1. 每个指标对应一个格式 → 仅保留单个 Metric_Format 字段
//   2. 行格式严格遵循口径文档数据类型定义（口径文档为 delta_pct_0dp 即 delta_pct_0dp，不做转换）
//   3. 颜色规则通过 Metric_ColorRule 字段标识，由 Cell Font Color 度量值统一调度
//      - "fixed_black"   → 始终 #252423（主指标 Act 类型）
//      - "pos_neg_zero"  → 按值正/负/零取色（vs LY / vs LP / vs Store 等子指标）
//
// 大分组（VICType）说明:
//   - "New VIC"       → 筛选条件 is_new_vic = 1（全客对比时 is_new_vic in (0, 1)）
//   - "Retention VIC" → 筛选条件 is_retention_vic = 1（全客对比时 is_retention_vic in (0, 1)）
//   两个大分组指标完全一致，唯一区别是筛选字段不同。
//
// 字段说明:
//   Metric_ID              主键（全局唯一 1-44）
//   VICType                Level 1: VIC 大分组（New VIC / Retention VIC）
//   KPIGroup               Level 2: KPI 分组名（SLS / SLS% / ACV / UPT / AUR / Freq.）
//   ColName                Level 3: 列名（Metric_ID + 指标名称，避免同名冲突，支持独立排序）
//   VICType_Sort           Level 1 排序（New VIC=10, Retention VIC=20）
//   KPIGroup_Sort          Level 2 排序（步长 10：SLS=10, SLS%=20, ACV=30, UPT=40, AUR=50, Freq.=60）
//   ColName_Sort           Level 3 排序（同组内 Act=100, vs LY=200, vs LP=300, vs Store=400）
//   ColType                列类型标识：Act / vs LY / vs LP / vs Store
//   Metric_Format          单一格式字段（严格对应口径文档数据类型）
//                          取值: currency / delta_pct_0dp / percent_0dp / delta_pts / currency_decimal_1dp / decimal_1dp
//   Metric_ColorRule       字体颜色规则：fixed_black / pos_neg_zero
//   Metric_ColorPositive   正值颜色（pos_neg_zero 规则使用）
//   Metric_ColorNegative   负值颜色（pos_neg_zero 规则使用）
//   Metric_ColorZero       零值颜色（pos_neg_zero 规则使用）
//   Metric_ColorDefault    默认颜色（pos_neg_zero 在 BLANK 时兜底）
//
// Metric_Format 取值与口径文档数据类型对应关系:
//   currency              → `__CurrencySymbol & FORMAT(__Value, "#,##0")`              货币符号 + 整数千分位（SLS）
//   currency_decimal_1dp  → `__CurrencySymbol & FORMAT(__Value, "#,##0.0")`            货币符号 + 一位小数千分位（ACV / AUR）
//   decimal_1dp           → `#,##0.0`                                                  小数一位小数千分位（UPT / Freq.）
//   percent_0dp           → `#,##0%`                                                   百分比整数，不含正号（SLS%）
//   delta_pct_0dp         → `IF(__Value>0,"+","") & FORMAT(__Value,"#,##0%")`          百分比整数变化，含正号（vs LY / vs LP / vs Store）
//   delta_pts             → `+#,##0pts;-#,##0pts;0pts`                                 基点（pts），含正负号，值×100 转 pts 在 Cell Display 中实现（SLS% vs LY / SLS% vs LP）
//
// 同名区分机制（ColName 加 Metric_ID 前缀）:
//   Power BI Sort by Column 要求同名字段只能绑定一个排序值，
//   通过在 ColName 开头拼接 Metric_ID，使各 KPI 同名值在底层字符串不同，支持独立排序。
//
// 颜色约定:
//   正值（>0）：#1A9018 绿色
//   负值（<0）：#D64550 红色
//   零值（=0）：#E1C233 黄色
//   固定黑色  ：#252423
// ========================================
DATATABLE(
    "Metric_ID",              INTEGER,    // 主键标识（全局唯一 1-44）
    "VICType",                STRING,     // Level 1: VIC 大分组（New VIC / Retention VIC）
    "KPIGroup",               STRING,     // Level 2: KPI 分组名（SLS / SLS% / ACV / UPT / AUR / Freq.）
    "ColName",                STRING,     // Level 3: 列名（Metric_ID + 指标名称）
    "VICType_Sort",           INTEGER,    // Level 1 排序（New VIC=10, Retention VIC=20）
    "KPIGroup_Sort",          INTEGER,    // Level 2 排序（步长 10）
    "ColName_Sort",           INTEGER,    // Level 3 排序
    "ColType",                STRING,     // 列类型标识
    "Metric_Format",          STRING,     // 单一格式字段（严格对应口径文档数据类型）
    "Metric_ColorRule",       STRING,     // 字体颜色规则
    "Metric_ColorPositive",   STRING,     // 正值颜色
    "Metric_ColorNegative",   STRING,     // 负值颜色
    "Metric_ColorZero",       STRING,     // 零值颜色
    "Metric_ColorDefault",    STRING,     // 默认颜色
    {
        // ════════════════════════════════════════════════════════════════════════
        // 大分组 1：New VIC — 筛选条件 is_new_vic = 1（全客对比 is_new_vic in (0, 1)）
        // 共 6 个 KPI 分组，22 列指标
        // ════════════════════════════════════════════════════════════════════════

        // ── KPI 分组 1：SLS（New VIC）— 净销售额（3 列）
        // 口径: Step1 dt=end period 筛选 is_new_vic=1 框定 user_id；Step2 该 user_id 在所选时间范围 sum(net_pay_amt)
        // 颜色规则: Act=固定黑；vs LY/vs LP=正负零三色
        { 1,  "New VIC", "SLS",   "1-SLS",           10, 10, 100, "Act",              "currency",             "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 2,  "New VIC", "SLS",   "2-SLS vs LY",     10, 10, 200, "vs LY",            "delta_pct_0dp",        "pos_neg_zero", "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 3,  "New VIC", "SLS",   "3-SLS vs LP",     10, 10, 300, "vs LP",            "delta_pct_0dp",        "pos_neg_zero", "#1A9018", "#D64550", "#E1C233", "#5F6165" },

        // ── KPI 分组 2：SLS%（New VIC）— 净销售额占比（3 列）
        // 口径: 分子 net_pay_amt(is_new_vic=1) / 分母 net_pay_amt(is_new_vic in (0,1))
        // 颜色规则: Act=固定黑；vs LY/vs LP=正负零三色
        { 4,  "New VIC", "SLS%",  "4-SLS%",          10, 20, 100, "Act",              "percent_0dp",          "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 5,  "New VIC", "SLS%",  "5-SLS% vs LY",    10, 20, 200, "vs LY",            "delta_pts",            "pos_neg_zero", "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 6,  "New VIC", "SLS%",  "6-SLS% vs LP",    10, 20, 300, "vs LP",            "delta_pts",            "pos_neg_zero", "#1A9018", "#D64550", "#E1C233", "#5F6165" },

        // ── KPI 分组 3：ACV（New VIC）— 客单价（4 列）
        // 口径: 分子 SLS(is_new_vic=1) / 分母 count(distinct user_id)(is_new_vic=1)
        // vs Store: New VIC ACV / 全客 ACV(is_new_vic in (0,1)) - 1
        // 颜色规则: Act=固定黑；vs LY/vs LP/vs Store=正负零三色
        { 7,  "New VIC", "ACV",   "7-ACV",           10, 30, 100, "Act",              "currency_decimal_1dp", "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 8,  "New VIC", "ACV",   "8-ACV vs LY",     10, 30, 200, "vs LY",            "delta_pct_0dp",        "pos_neg_zero", "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 9,  "New VIC", "ACV",   "9-ACV vs LP",     10, 30, 300, "vs LP",            "delta_pct_0dp",        "pos_neg_zero", "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 10, "New VIC", "ACV",   "10-ACV vs Store", 10, 30, 400, "vs Store",         "delta_pct_0dp",        "pos_neg_zero", "#1A9018", "#D64550", "#E1C233", "#5F6165" },

        // ── KPI 分组 4：UPT（New VIC）— 客单件（4 列）
        // 口径: 分子 sum(net_pay_qty)(is_new_vic=1) / 分母 sum(net_pay_order_cnt)(is_new_vic=1)
        // vs Store: New VIC UPT / 全客 UPT(is_new_vic in (0,1)) - 1
        // 颜色规则: Act=固定黑；vs LY/vs LP/vs Store=正负零三色
        { 11, "New VIC", "UPT",   "11-UPT",          10, 40, 100, "Act",              "decimal_1dp",          "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 12, "New VIC", "UPT",   "12-UPT vs LY",    10, 40, 200, "vs LY",            "delta_pct_0dp",        "pos_neg_zero", "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 13, "New VIC", "UPT",   "13-UPT vs LP",    10, 40, 300, "vs LP",            "delta_pct_0dp",        "pos_neg_zero", "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 14, "New VIC", "UPT",   "14-UPT vs Store", 10, 40, 400, "vs Store",         "delta_pct_0dp",        "pos_neg_zero", "#1A9018", "#D64550", "#E1C233", "#5F6165" },

        // ── KPI 分组 5：AUR（New VIC）— 件单价（4 列）
        // 口径: 分子 sum(net_pay_amt)(is_new_vic=1) / 分母 sum(net_pay_qty)(is_new_vic=1)
        // vs Store: New VIC AUR / 全客 AUR(is_new_vic in (0,1)) - 1
        // 颜色规则: Act=固定黑；vs LY/vs LP/vs Store=正负零三色
        { 15, "New VIC", "AUR",   "15-AUR",          10, 50, 100, "Act",              "currency_decimal_1dp", "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 16, "New VIC", "AUR",   "16-AUR vs LY",    10, 50, 200, "vs LY",            "delta_pct_0dp",        "pos_neg_zero", "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 17, "New VIC", "AUR",   "17-AUR vs LP",    10, 50, 300, "vs LP",            "delta_pct_0dp",        "pos_neg_zero", "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 18, "New VIC", "AUR",   "18-AUR vs Store", 10, 50, 400, "vs Store",         "delta_pct_0dp",        "pos_neg_zero", "#1A9018", "#D64550", "#E1C233", "#5F6165" },

        // ── KPI 分组 6：Freq.（New VIC）— 购买频次（4 列）
        // 口径: 分子 sum(net_pay_order_cnt)(is_new_vic=1) / 分母 count(distinct user_id)(is_new_vic=1)
        // vs Store: New VIC Freq. / 全客 Freq.(is_new_vic in (0,1)) - 1
        // 颜色规则: Act=固定黑；vs LY/vs LP/vs Store=正负零三色
        { 19, "New VIC", "Freq.", "19-Freq.",          10, 60, 100, "Act",              "decimal_1dp",          "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 20, "New VIC", "Freq.", "20-Freq. vs LY",    10, 60, 200, "vs LY",            "delta_pct_0dp",        "pos_neg_zero", "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 21, "New VIC", "Freq.", "21-Freq. vs LP",    10, 60, 300, "vs LP",            "delta_pct_0dp",        "pos_neg_zero", "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 22, "New VIC", "Freq.", "22-Freq. vs Store", 10, 60, 400, "vs Store",         "delta_pct_0dp",        "pos_neg_zero", "#1A9018", "#D64550", "#E1C233", "#5F6165" },

        // ════════════════════════════════════════════════════════════════════════
        // 大分组 2：Retention VIC — 筛选条件 is_retention_vic = 1（全客对比 is_retention_vic in (0, 1)）
        // 共 6 个 KPI 分组，22 列指标（与 New VIC 完全一致，仅筛选字段不同）
        // ════════════════════════════════════════════════════════════════════════

        // ── KPI 分组 1：SLS（Retention VIC）— 净销售额（3 列）
        // 口径: Step1 dt=end period 筛选 is_retention_vic=1 框定 user_id；Step2 该 user_id 在所选时间范围 sum(net_pay_amt)
        // 颜色规则: Act=固定黑；vs LY/vs LP=正负零三色
        { 23, "Retention VIC", "SLS",   "23-SLS",           20, 10, 100, "Act",              "currency",             "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 24, "Retention VIC", "SLS",   "24-SLS vs LY",     20, 10, 200, "vs LY",            "delta_pct_0dp",        "pos_neg_zero", "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 25, "Retention VIC", "SLS",   "25-SLS vs LP",     20, 10, 300, "vs LP",            "delta_pct_0dp",        "pos_neg_zero", "#1A9018", "#D64550", "#E1C233", "#5F6165" },

        // ── KPI 分组 2：SLS%（Retention VIC）— 净销售额占比（3 列）
        // 口径: 分子 net_pay_amt(is_retention_vic=1) / 分母 net_pay_amt(is_retention_vic in (0,1))
        // 颜色规则: Act=固定黑；vs LY/vs LP=正负零三色
        { 26, "Retention VIC", "SLS%",  "26-SLS%",          20, 20, 100, "Act",              "percent_0dp",          "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 27, "Retention VIC", "SLS%",  "27-SLS% vs LY",    20, 20, 200, "vs LY",            "delta_pts",            "pos_neg_zero", "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 28, "Retention VIC", "SLS%",  "28-SLS% vs LP",    20, 20, 300, "vs LP",            "delta_pts",            "pos_neg_zero", "#1A9018", "#D64550", "#E1C233", "#5F6165" },

        // ── KPI 分组 3：ACV（Retention VIC）— 客单价（4 列）
        // 口径: 分子 SLS(is_retention_vic=1) / 分母 count(distinct user_id)(is_retention_vic=1)
        // vs Store: Retention VIC ACV / 全客 ACV(is_retention_vic in (0,1)) - 1
        // 颜色规则: Act=固定黑；vs LY/vs LP/vs Store=正负零三色
        { 29, "Retention VIC", "ACV",   "29-ACV",           20, 30, 100, "Act",              "currency_decimal_1dp", "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 30, "Retention VIC", "ACV",   "30-ACV vs LY",     20, 30, 200, "vs LY",            "delta_pct_0dp",        "pos_neg_zero", "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 31, "Retention VIC", "ACV",   "31-ACV vs LP",     20, 30, 300, "vs LP",            "delta_pct_0dp",        "pos_neg_zero", "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 32, "Retention VIC", "ACV",   "32-ACV vs Store",  20, 30, 400, "vs Store",         "delta_pct_0dp",        "pos_neg_zero", "#1A9018", "#D64550", "#E1C233", "#5F6165" },

        // ── KPI 分组 4：UPT（Retention VIC）— 客单件（4 列）
        // 口径: 分子 sum(net_pay_qty)(is_retention_vic=1) / 分母 sum(net_pay_order_cnt)(is_retention_vic=1)
        // vs Store: Retention VIC UPT / 全客 UPT(is_retention_vic in (0,1)) - 1
        // 颜色规则: Act=固定黑；vs LY/vs LP/vs Store=正负零三色
        { 33, "Retention VIC", "UPT",   "33-UPT",           20, 40, 100, "Act",              "decimal_1dp",          "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 34, "Retention VIC", "UPT",   "34-UPT vs LY",     20, 40, 200, "vs LY",            "delta_pct_0dp",        "pos_neg_zero", "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 35, "Retention VIC", "UPT",   "35-UPT vs LP",     20, 40, 300, "vs LP",            "delta_pct_0dp",        "pos_neg_zero", "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 36, "Retention VIC", "UPT",   "36-UPT vs Store",  20, 40, 400, "vs Store",         "delta_pct_0dp",        "pos_neg_zero", "#1A9018", "#D64550", "#E1C233", "#5F6165" },

        // ── KPI 分组 5：AUR（Retention VIC）— 件单价（4 列）
        // 口径: 分子 sum(net_pay_amt)(is_retention_vic=1) / 分母 sum(net_pay_qty)(is_retention_vic=1)
        // vs Store: Retention VIC AUR / 全客 AUR(is_retention_vic in (0,1)) - 1
        // 颜色规则: Act=固定黑；vs LY/vs LP/vs Store=正负零三色
        { 37, "Retention VIC", "AUR",   "37-AUR",           20, 50, 100, "Act",              "currency_decimal_1dp", "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 38, "Retention VIC", "AUR",   "38-AUR vs LY",     20, 50, 200, "vs LY",            "delta_pct_0dp",        "pos_neg_zero", "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 39, "Retention VIC", "AUR",   "39-AUR vs LP",     20, 50, 300, "vs LP",            "delta_pct_0dp",        "pos_neg_zero", "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 40, "Retention VIC", "AUR",   "40-AUR vs Store",  20, 50, 400, "vs Store",         "delta_pct_0dp",        "pos_neg_zero", "#1A9018", "#D64550", "#E1C233", "#5F6165" },

        // ── KPI 分组 6：Freq.（Retention VIC）— 购买频次（4 列）
        // 口径: 分子 sum(net_pay_order_cnt)(is_retention_vic=1) / 分母 count(distinct user_id)(is_retention_vic=1)
        // vs Store: Retention VIC Freq. / 全客 Freq.(is_retention_vic in (0,1)) - 1
        // 颜色规则: Act=固定黑；vs LY/vs LP/vs Store=正负零三色
        { 41, "Retention VIC", "Freq.", "41-Freq.",           20, 60, 100, "Act",              "decimal_1dp",          "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 42, "Retention VIC", "Freq.", "42-Freq. vs LY",     20, 60, 200, "vs LY",            "delta_pct_0dp",        "pos_neg_zero", "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 43, "Retention VIC", "Freq.", "43-Freq. vs LP",     20, 60, 300, "vs LP",            "delta_pct_0dp",        "pos_neg_zero", "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 44, "Retention VIC", "Freq.", "44-Freq. vs Store",  20, 60, 400, "vs Store",         "delta_pct_0dp",        "pos_neg_zero", "#1A9018", "#D64550", "#E1C233", "#5F6165" }
    }
)
