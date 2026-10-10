Dim_ColMetric_Merchandising_Core_KPI =
// ========================================
// 表: Dim_ColMetric_Merchandising_Core_KPI
// 类型: 维度表（Dim_ 前缀），断开维度（不与事实表建立关系，度量值中用 SELECTEDVALUE/TREATAS 调度）
// 用途: 定义 RL E2E Merch Dashboard - Merchandise Performance Overview Tab 的 Merchandising Core KPI 矩阵列维度（KPIGroup > ColName）
// 范围: 口径文档/口径Markdown格式/Merchandise Performance Overview.md
//       - 子模块一：Merchandising Core KPI【Amt】（§1-§10）
//       - 子模块二：Merchandising Core KPI【Unit】（§11-§20）
//       【Amt】与【Unit】指标数量、结构完全一致 → 单套 20 列共用（10 个 KPI 分组，含主指标与附属指标）
// 数据底表（销售类）: indep_rl_ads.a02_e2e_product_performance_sales_summary_d（SLS、AVG MD、Fullprice%、AUR、Inbound、Outbound 及 ST% 分子）
// 数据底表（库存类）: indep_rl_ads.a02_e2e_product_performance_inv_summary_d（EOH、In-Transit、O2O 及 ST% 分母）
// 矩阵行维度: 商品维度切换 ALL / Hero Model / Slow Mover / Normal（computed_product_tag，配合 IsProductTagFilter）
//
// 【Amt】/【Unit】按钮切换设计（配合 维度复用/按钮筛选控制/IsAmtUnitFilter）:
//   1. 本表只输出单套 20 列，不拆分【Amt】/【Unit】两套行
//   2. 度量值中用 SELECTEDVALUE('IsAmtUnitFilter'[Sort]) 判断模式：=10 → Amt 逻辑；=20 → Unit 逻辑
//   3. 格式采用双列设计（相对参考格式 Dim_ColMetric_Customer_KPIs 的结构差异：双格式列 + Metric_IsCurrencyAmount 字段）:
//      - Metric_Format_Amt  → 【Amt】模式展示格式（子模块一口径）
//      - Metric_Format_Unit → 【Unit】模式展示格式（子模块二口径）
//      - 6 组金额/数量类主指标（SLS / EOH / In-Transit Inventory / O2O Inventory / Inbound / Outbound）双列不同（currency vs integer）
//      - 共享指标（ST% / AVG MD / Fullprice% / AUR）及全部附属指标（vs LY / TAR ACH%）双列相同
//   4. KPIGroup / ColName 采用模式中性命名（如 "SLS" 而非 "SLS Amt"/"SLS Unit"），当前模式由按钮状态表达，列名不重复标注
//
// 各主指标 Amt/Unit 计算逻辑差异备注（后续度量值实现依据，口径文档 §1-§10 vs §11-§20，字段名已核对数据字典）:
//   - AVG MD、AUR：口径标注【Amt】【Unit】同一套逻辑，可直接复用，不用重复计算
//   - SLS：Amt = sum(net_sales_amt)；Unit = sum(net_sales_qty)（区间汇总）
//   - ST%：Amt = net_sales_amt / (net_sales_amt + msrp_inv_amt)；Unit = net_sales_qty / (net_sales_qty + inv_qty)
//         （分子区间汇总，分母 end period 最后一天，跨 sales + inv 双表）
//   - Fullprice%：Amt = sum(case when md_type = "FP" then net_sales_amt else 0 end) / sum(net_sales_amt)；
//                 Unit = sum(msrp_net_sales_amt) / sum(net_sales_amt)（口径已确认，Amt/Unit 公式不同但格式相同）
//   - EOH：Amt = sum(msrp_inv_amt)；Unit = sum(inv_qty)（end period 最后一天）
//   - In-Transit Inventory：Amt = sum(msrp_in_trans_inv_amt)；Unit = sum(in_trans_inv_qty)（end period 最后一天）
//   - O2O Inventory：Amt = sum(msrp_o2o_inv_amt)；Unit = sum(o2o_inv_qty)（end period 最后一天）
//   - Inbound：Amt = sum(msrp_inbound_amt)；Unit = sum(inbound_qty)（区间汇总）
//   - Outbound：Amt = sum(md_outbound_amt)；Unit = sum(outbound_qty)（区间汇总）
//
// 时间口径备注:
//   - 区间类（SLS、AVG MD、Fullprice%、AUR、Inbound、Outbound、ST% 分子）：看所选时间范围（This Period 区间汇总）
//   - 期末时点类（EOH、In-Transit、O2O、ST% 分母）：看所选时间范围 end period 最后一天
//   - vs LY：无特殊说明时 LY 用 Last Period 特定筛选器结果作为上期时间范围对比（MPO 第二轮提示词约定）
//
// 设计原则（遵循口径文档要求）:
//   1. 每个指标对应 Amt/Unit 双格式 → Metric_Format_Amt + Metric_Format_Unit 两个字段
//   2. 行格式严格遵循口径文档数据类型定义；与解决方案存在争议时，一切以口径文档为准
//   3. 颜色规则通过 Metric_ColorRule 字段标识，由 Cell Font Color 度量值统一调度
//      - "fixed_black"  → 始终 #252423（全部主指标 Act 列）
//      - "pos_neg_zero" → 按值正/负/零取色（全部 vs LY / TAR ACH% 附属指标列）
//   4. 金额类换算：仅 Amt 模式下的金额类指标（Metric_Format_Amt = "currency"，含双模式的 AUR）
//      需按 Slicer_Currency_Selection 汇率结果在 Display 度量中换算并拼接币种符号；Unit 模式及比率/派生列不涉及
//
// 字段说明:
//   Metric_ID            主键（全局唯一 1-20）
//   KPIGroup             Level 1: KPI 分组名（10 个，模式中性命名）
//   ColName              Level 2: 列名（Metric_ID + 指标名称，避免同名冲突，支持独立排序）
//   KPIGroup_Sort        Level 1 排序（步长 10：10-100，按口径文档指标顺序）
//   ColName_Sort         Level 2 排序（同组内 Act=100, vs LY=200, TAR ACH% Progress=400, TAR ACH% Target=410）
//   ColType              列类型标识：Act / vs LY / TAR ACH% Progress（进度达成）/ TAR ACH% Target（目标达成）
//   Metric_Format_Amt    【Amt】模式展示格式（SELECTEDVALUE('IsAmtUnitFilter'[Sort])=10 时取用）
//   Metric_Format_Unit   【Unit】模式展示格式（SELECTEDVALUE('IsAmtUnitFilter'[Sort])=20 时取用）
//   Metric_ColorRule     字体颜色规则：fixed_black / pos_neg_zero
//   Metric_ColorPositive 正值颜色（pos_neg_zero 规则使用）
//   Metric_ColorNegative 负值颜色（pos_neg_zero 规则使用）
//   Metric_ColorZero     零值颜色（pos_neg_zero 规则使用）
//   Metric_ColorDefault  默认颜色（pos_neg_zero 在 BLANK 时兜底）
//
// Metric_Format 取值与口径文档数据类型对应关系（参考 模版复用/数据类型和格式总览.md）:
//   currency      → `#,##0`，DAX 中 __CurrencySymbol & FORMAT(__Value, "#,##0") 拼接币种符号
//                   （SLS/EOH/In-Transit Inventory/O2O Inventory/Inbound/Outbound 的 Amt 格式；AUR 双模式格式）
//   integer       → `#,##0` 整数千分位
//                   （SLS/EOH/In-Transit Inventory/O2O Inventory/Inbound/Outbound 的 Unit 格式）
//   percent_0dp   → `#,##0%` 百分比整数，不含正号（ST% / AVG MD / Fullprice% Act 列，双模式相同）
//   delta_pct_0dp → IF(__Value>0,"+","") & FORMAT(__Value,"#,##0%") 百分比整数变化，含正号
//                   （SLS/EOH/AUR/Inbound/Outbound 的 vs LY；SLS 的 TAR ACH% Progress/Target，口径明确为 delta_pct_0dp）
//   delta_bp      → `+#,##0bp;-#,##0bp;0bp` 基点，含正负号，值×10000 转 bp 在 Cell Display 中实现
//                   （ST% / AVG MD / Fullprice% 的 vs LY，比率类差值指标）
//
// TAR ACH% 说明:
//   仅 SLS 附属 TAR ACH% 两列（口径全局逻辑：仅 SLS Amt、SLS Unit 附属 TAR ACH%）
//   - TAR ACH% Progress（进度达成）/ TAR ACH% Target（目标达成），口径文档未给出具体计算公式，计算逻辑在后续度量值中实现
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
    "Metric_ID",             INTEGER,    // 主键标识（全局唯一 1-20）
    "KPIGroup",              STRING,     // Level 1: KPI 分组名（模式中性命名）
    "ColName",               STRING,     // Level 2: 列名（Metric_ID + 指标名称）
    "KPIGroup_Sort",         INTEGER,    // Level 1 排序（步长 10）
    "ColName_Sort",          INTEGER,    // Level 2 排序
    "ColType",               STRING,     // 列类型标识：Act / vs LY / TAR ACH% Progress / TAR ACH% Target
    "Metric_Format_Amt",     STRING,     // 【Amt】模式展示格式（子模块一口径）
    "Metric_Format_Unit",    STRING,     // 【Unit】模式展示格式（子模块二口径）
    "Metric_IsCurrencyAmount", BOOLEAN,  // 是否金额类（TRUE 才涉及汇率换算与币种符号拼接）
    "Metric_ColorRule",      STRING,     // 字体颜色规则
    "Metric_ColorPositive",  STRING,     // 正值颜色
    "Metric_ColorNegative",  STRING,     // 负值颜色
    "Metric_ColorZero",      STRING,     // 零值颜色
    "Metric_ColorDefault",   STRING,     // 默认颜色
    {
        // ════════════════════════════════════════════════════════════════
        // 分组 1：SLS — DCom 净销售额 / 净销售数量（4 列，唯一附属 TAR ACH% 的分组）
        // 口径 Amt: sum(net_sales_amt)；Unit: sum(net_sales_qty)（区间汇总，sales 表）
        // 附属: vs LY = this period / last period - 1（delta_pct_0dp）；
        //       TAR ACH% Progress 进度达成 / TAR ACH% Target 目标达成（delta_pct_0dp，公式后续度量值实现）
        // 颜色规则: Act=固定黑；vs LY / TAR ACH%=正负零三色
        // ════════════════════════════════════════════════════════════════
        { 1,  "SLS", "1-SLS",                   10, 100, "Act",               "currency",      "integer",      TRUE,           "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 2,  "SLS", "2-SLS vs LY",             10, 200, "vs LY",             "delta_pct_0dp", "delta_pct_0dp", FALSE,          "pos_neg_zero", "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 3,  "SLS", "3-SLS TAR ACH% Progress", 10, 400, "TAR ACH% Progress", "delta_pct_0dp", "delta_pct_0dp", FALSE,          "pos_neg_zero", "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 4,  "SLS", "4-SLS TAR ACH% Target",   10, 410, "TAR ACH% Target",   "delta_pct_0dp", "delta_pct_0dp", FALSE,          "pos_neg_zero", "#1A9018", "#D64550", "#E1C233", "#5F6165" },

        // ════════════════════════════════════════════════════════════════
        // 分组 2：ST% — 售罄率%（2 列）
        // 口径 Amt: net_sales_amt / (net_sales_amt + msrp_inv_amt)；
        //      Unit: net_sales_qty / (net_sales_qty + inv_qty)
        //      （分子区间汇总，分母 end period 最后一天，跨 sales + inv 双表）
        // 附属: vs LY = this period - last period（差值 bp，展示时 ×10000 转 bp）
        // 颜色规则: Act=固定黑；vs LY=正负零三色
        // ════════════════════════════════════════════════════════════════
        { 5,  "ST%", "5-ST%",       20, 100, "Act",   "percent_0dp", "percent_0dp", FALSE,          "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 6,  "ST%", "6-ST% vs LY", 20, 200, "vs LY", "delta_bp",    "delta_bp",    FALSE,          "pos_neg_zero", "#1A9018", "#D64550", "#E1C233", "#5F6165" },

        // ════════════════════════════════════════════════════════════════
        // 分组 3：AVG MD — 平均折扣（2 列）
        // 口径: 1 - sum(md_net_sales_amt) / sum(msrp_net_sales_amt)
        //      （【Amt】【Unit】同一套逻辑，直接复用，不用重复计算；区间汇总，sales 表）
        // 附属: vs LY = this period - last period（差值 bp）
        // 颜色规则: Act=固定黑；vs LY=正负零三色
        // ════════════════════════════════════════════════════════════════
        { 7,  "AVG MD", "7-AVG MD",       30, 100, "Act",   "percent_0dp", "percent_0dp", FALSE,          "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 8,  "AVG MD", "8-AVG MD vs LY", 30, 200, "vs LY", "delta_bp",    "delta_bp",    FALSE,          "pos_neg_zero", "#1A9018", "#D64550", "#E1C233", "#5F6165" },

        // ════════════════════════════════════════════════════════════════
        // 分组 4：Fullprice% — 全价率（2 列）
        // 口径 Amt: sum(case when md_type = "FP" then net_sales_amt else 0 end) / sum(net_sales_amt)；
        //      Unit: sum(msrp_net_sales_amt) / sum(net_sales_amt)
        //      （口径已确认；Amt/Unit 公式不同但格式相同；区间汇总，sales 表）
        // 附属: vs LY = this period - last period（差值 bp）
        // 颜色规则: Act=固定黑；vs LY=正负零三色
        // ════════════════════════════════════════════════════════════════
        { 9,  "Fullprice%", "9-Fullprice%",       40, 100, "Act",   "percent_0dp", "percent_0dp", FALSE,          "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 10, "Fullprice%", "10-Fullprice% vs LY", 40, 200, "vs LY", "delta_bp",    "delta_bp",    FALSE,          "pos_neg_zero", "#1A9018", "#D64550", "#E1C233", "#5F6165" },

        // ════════════════════════════════════════════════════════════════
        // 分组 5：AUR — 件单价（2 列）
        // 口径: sum(net_sales_amt) / sum(net_sales_qty)
        //      （【Amt】【Unit】同一套逻辑，直接复用；金额类，双模式均需汇率换算 + 币种符号；区间汇总，sales 表）
        // 附属: vs LY = this period / last period - 1
        // 颜色规则: Act=固定黑；vs LY=正负零三色
        // ════════════════════════════════════════════════════════════════
        { 11, "AUR", "11-AUR",       50, 100, "Act",   "currency",     "currency",     TRUE,           "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 12, "AUR", "12-AUR vs LY", 50, 200, "vs LY", "delta_pct_0dp", "delta_pct_0dp", FALSE,          "pos_neg_zero", "#1A9018", "#D64550", "#E1C233", "#5F6165" },

        // ════════════════════════════════════════════════════════════════
        // 分组 6：EOH — 期末库存（2 列）
        // 口径 Amt: sum(msrp_inv_amt)；Unit: sum(inv_qty)（end period 最后一天，inv 表）
        // 附属: vs LY = this period / last period - 1
        // 颜色规则: Act=固定黑；vs LY=正负零三色
        // ════════════════════════════════════════════════════════════════
        { 13, "EOH", "13-EOH",       60, 100, "Act",   "currency",     "integer",      TRUE,           "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 14, "EOH", "14-EOH vs LY", 60, 200, "vs LY", "delta_pct_0dp", "delta_pct_0dp", FALSE,          "pos_neg_zero", "#1A9018", "#D64550", "#E1C233", "#5F6165" },

        // ════════════════════════════════════════════════════════════════
        // 分组 7：In-Transit Inventory — 在途库存（1 列，无附属指标）
        // 口径 Amt: sum(msrp_in_trans_inv_amt)；Unit: sum(in_trans_inv_qty)（end period 最后一天，inv 表）
        // 颜色规则: Act=固定黑
        // ════════════════════════════════════════════════════════════════
        { 15, "In-Transit Inventory", "15-In-Transit Inventory", 70, 100, "Act", "currency", "integer", TRUE,           "fixed_black", "#1A9018", "#D64550", "#E1C233", "#5F6165" },

        // ════════════════════════════════════════════════════════════════
        // 分组 8：O2O Inventory — O2O 库存（1 列，无附属指标）
        // 口径 Amt: sum(msrp_o2o_inv_amt)；Unit: sum(o2o_inv_qty)（end period 最后一天，inv 表）
        // 颜色规则: Act=固定黑
        // ════════════════════════════════════════════════════════════════
        { 16, "O2O Inventory", "16-O2O Inventory", 80, 100, "Act", "currency", "integer", TRUE,           "fixed_black", "#1A9018", "#D64550", "#E1C233", "#5F6165" },

        // ════════════════════════════════════════════════════════════════
        // 分组 9：Inbound — 入库（2 列）
        // 口径 Amt: sum(msrp_inbound_amt)；Unit: sum(inbound_qty)（区间汇总，sales 表）
        // 附属: vs LY = this period / last period - 1
        // 颜色规则: Act=固定黑；vs LY=正负零三色
        // ════════════════════════════════════════════════════════════════
        { 17, "Inbound", "17-Inbound",       90, 100, "Act",   "currency",     "integer",      TRUE,           "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 18, "Inbound", "18-Inbound vs LY", 90, 200, "vs LY", "delta_pct_0dp", "delta_pct_0dp", FALSE,          "pos_neg_zero", "#1A9018", "#D64550", "#E1C233", "#5F6165" },

        // ════════════════════════════════════════════════════════════════
        // 分组 10：Outbound — 出库（2 列）
        // 口径 Amt: sum(md_outbound_amt)；Unit: sum(outbound_qty)（区间汇总，sales 表）
        // 附属: vs LY = this period / last period - 1
        // 颜色规则: Act=固定黑；vs LY=正负零三色
        // ════════════════════════════════════════════════════════════════
        { 19, "Outbound", "19-Outbound",       100, 100, "Act",   "currency",     "integer",      TRUE,           "fixed_black",  "#1A9018", "#D64550", "#E1C233", "#5F6165" },
        { 20, "Outbound", "20-Outbound vs LY", 100, 200, "vs LY", "delta_pct_0dp", "delta_pct_0dp", FALSE,          "pos_neg_zero", "#1A9018", "#D64550", "#E1C233", "#5F6165" }
    }
)
