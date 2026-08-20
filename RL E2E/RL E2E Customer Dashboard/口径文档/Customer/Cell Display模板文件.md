xxx Cell Display =
// ========================================
// 度量值: xxx Cell Display
// Display Folder: Formatting
// 用途: 按 Metric_Format 单字段格式化显示
// 依赖: [xxx Cell Value],
//       'Dim_ColMetric_xxx'[Metric_Format],
//       Slicer_Currency_Selection[Currency_Symbol]
// 格式类型（严格遵循口径文档数据类型定义，以 Dim_ColMetric_xxx 为准）:
//   integer               → 整数千分位：1,000
//   decimal_1dp           → 小数一位小数千分位：1.5（UPT / Freq.）
//   decimal_2dp           → 小数两位小数千分位：1,000.00
//   currency              → 货币符号 + 整数千分位：¥1,000 / $1,000（SLS）
//   currency_decimal_1dp  → 货币符号 + 一位小数千分位：¥1,000.0 / $1,000.0（ACV / AUR）
//   currency_k            → 货币符号 + 千位缩写：¥1k / $5k
//   currency_M_K_Int_0db  → 货币符号 + 整数/M/K 单位（0位小数）：¥999\¥1.5K\¥1.5M
//   percent_0dp           → 百分比整数，不含正号：15%（SLS%）
//   percent_1dp           → 百分比一位小数：40.5%
//   percent_2dp           → 百分比两位小数：40.50%
//   delta_pct_0dp         → 百分比整数变化，含正号：+15% / -3%（vs LY / vs LP / vs Store）
//   delta_pct_1dp         → 百分比一位小数变化，含正号：+14.5% / -3.2%
//   delta_pct_2dp         → 百分比两位小数变化，含正号：+14.50%
//   delta_pts             → 增减基点整数（小数×100 转 pts）：+120pts / -80pts / 0pts
//   integer_pts           → 基点整数（小数×100 转 pts）：120pts / 80pts / 0pts
//   delta_bp              → 增减基点整数（小数×10000 转 bp）：+120bp / -80bp
//   delta_bp_1dp          → 增减基点一位小数（值本身已是基点）：+120.5bp / -80.0bp
// 说明:
//   - BLANK 显示为 "-"
//   - 货币符号由 Slicer_Currency_Selection[Currency_Symbol] 决定（默认 "¥"）
// ========================================
    VAR __Value = [xxx Cell Value]
    VAR __Format = SELECTEDVALUE('Dim_ColMetric_xxx'[Metric_Format])
    VAR __CurrencySymbol = SELECTEDVALUE(Slicer_Currency_Selection[Currency_Symbol], "¥")

    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            SWITCH(
                __Format,

    // ─── 1. 整数与小数 ──────────────────────────────────────────
                "integer",
                    FORMAT(__Value, "#,##0"),                                    // 1,000

    "decimal_1dp",
                    FORMAT(__Value, "#,##0.0"),                                  // 1.5

    "decimal_2dp",
                    FORMAT(__Value, "#,##0.00"),                                 // 1,000.00

    // ─── 2. 货币格式 ────────────────────────────────────────────
                "currency",
                    __CurrencySymbol & FORMAT(__Value, "#,##0"),                 // ¥1,000 / $1,000

    "currency_decimal_1dp",
                    __CurrencySymbol & FORMAT(__Value, "#,##0.0"),               // ¥1,000.0 / $1,000.0

    "currency_k",
                    __CurrencySymbol & FORMAT(__Value / 1000, "#,##0") & "k",    // ¥1k / $5k
    
    "currency_M_K_Int_0db",
                    IF(
                __Value < 1000,
                __CurrencySymbol & FORMAT(__Value, "#,##0"),
                IF(
                    __Value < 1000000,
                    __CurrencySymbol & FORMAT(__Value / 1000, "#,##0.0") & "K",
                    __CurrencySymbol & FORMAT(__Value / 1000000, "#,##0.0") & "M"
                )
            ), // ¥999\¥1.5K\¥1.5M

    // ─── 3. 百分比格式（纯显示，不含正负号）───────────────────────
                "percent_0dp",
                    FORMAT(__Value, "#,##0%"),                                   // 15%

    "percent_1dp",
                    FORMAT(__Value, "0.0%"),                                     // 40.5%

    "percent_2dp",
                    FORMAT(__Value, "0.00%"),                                    // 40.50%

    // ─── 4. 增减百分比（Delta %，自动添加正负号）────────────────
                "delta_pct_0dp",
                    IF(__Value > 0, "+", "") & FORMAT(__Value, "#,##0%"),        // +15% / -3%

    "delta_pct_1dp",
                    IF(__Value > 0, "+", "") & FORMAT(__Value, "0.0%"),          // +14.5% / -3.2%

    "delta_pct_2dp",
                    IF(__Value > 0, "+", "") & FORMAT(__Value, "0.00%"),         // +14.50%

    // ─── 5. 增减基点 ───────────────────────────────────────────
    // 5.1 __Value 为小数，需 ×100 转换为 pts（整数）,含正号
    "delta_pts",
        IF(ROUND(__Value * 100, 0) > 0, "+", "") & FORMAT(__Value * 100, "#,##0pts;-#,##0pts;0pts"),
                                                                                 // +120pts / -80pts / 0pts
    // 5.2 __Value 为小数，需 ×100 转换为 pts（整数）,不含正号
    "delta_pts",
        `FORMAT(__Value * 100, "#,##0pts;-#,##0pts;0pts")`,
                                                                                 // 120pts / -80pts / 0pts                                                                         

    // 5.3 __Value 为小数，需 ×10000 转换为 bp（整数）
                "delta_bp",
                    IF(__Value > 0, "+", "") & FORMAT(__Value * 10000, "#,##0") & "bp",
                                                                                 // +120bp / -80bp

    // 5.4 __Value 本身已是基点值，保留 1 位小数
                "delta_bp_1dp",
                    IF(__Value > 0, "+", "") & FORMAT(__Value, "#,##0.0") & "bp",// +120.5bp / -80.0bp

    // ─── 默认 ───────────────────────────────────────────────────
                FORMAT(__Value, "#,##0.00")
            )
        )
