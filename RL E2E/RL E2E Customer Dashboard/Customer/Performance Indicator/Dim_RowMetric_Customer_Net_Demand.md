Dim_RowMetric_Customer_Net_Demand =
// ========================================
// 表: Dim_RowMetric_Customer_Net_Demand
// 类型: 维度表（Dim_ 前缀），断开维度
// 用途: 定义 Customer Dashboard - Customer Tab 的 Performance Indicator 矩阵行维度（Net / Demand 逻辑区分）
// 范围: 口径文档/Customer/Performance Indicator.md - 子模块二 Performance Indicator（2 个行选项：Net / Demand）
// 数据底表: a03_e2e_customer_data_m
//
// 设计原则:
//   1. Net 与 Demand 指标个数、逻辑完全一致，区别仅在于字段
//      - Net 部分字段: net_pay_amt、net_pay_qty、net_pay_order_cnt
//      - Demand 部分字段: pay_amt、pay_qty、pay_order_cnt
//   2. 新客/老客判定字段同样区分 Net / Demand:
//      - Net: lp_12m_net_pay_amt（前 12 个月 net 购买金额）
//      - Demand: lp_12m_pay_amt（前 12 个月购买金额）
//   3. 通过 SELECTEDVALUE 读取 Row_Code，在 DAX 中用 SWITCH 分支选择对应字段逻辑
//   4. 不选 / 多选 / 全选 → 默认走 Net 逻辑（通过 HASONEVALUE 判定）
//
// 字段说明:
//   Row_ID              主键（1=Net, 2=Demand）
//   Row_Label           显示标签（Net / Demand）
//   Row_Sort            排序顺序
//   Row_Code            业务代码（Net / Demand），DAX 通过 SELECTEDVALUE 读取此字段路由
//   Row_Description     详细描述
//   Row_IsDefault       是否默认选中（Net 为默认）
//   Row_IsActive        是否激活状态
//   Row_Amt_Field       金额字段名（仅作元数据说明，DAX 不动态读取字段名，用 SWITCH 路由）
//   Row_Qty_Field       件数字段名（同上）
//   Row_OrderCnt_Field  订单数字段名（同上）
//   Row_LY_LP_Field     新客/老客判定字段名（同上）
// ========================================
DATATABLE(
    "Row_ID",              INTEGER,    // 主键标识（1=Net, 2=Demand）
    "Row_Label",           STRING,     // 显示标签
    "Row_Sort",            INTEGER,    // 排序顺序
    "Row_Code",            STRING,     // 业务代码（DAX 路由用）
    "Row_Description",     STRING,     // 详细描述
    "Row_IsDefault",       BOOLEAN,    // 是否默认选中
    "Row_IsActive",        BOOLEAN,    // 是否激活状态
    "Row_Amt_Field",       STRING,     // 金额字段名（元数据）
    "Row_Qty_Field",       STRING,     // 件数字段名（元数据）
    "Row_OrderCnt_Field",  STRING,     // 订单数字段名（元数据）
    "Row_LY_LP_Field",     STRING,     // 新客/老客判定字段名（元数据）
    {
        // ── Net 维度（净销售额口径）──
        // 字段: net_pay_amt / net_pay_qty / net_pay_order_cnt / lp_12m_net_pay_amt
        // 口径: 净销售额 = 净销售订单总销售额 - 退货额
        {
            1,
            "Net",
            10,
            "Net",
            "Net 维度（净销售额口径）：基于 net_pay_amt / net_pay_qty / net_pay_order_cnt，新客判定字段 lp_12m_net_pay_amt",
            TRUE,
            TRUE,
            "net_pay_amt",
            "net_pay_qty",
            "net_pay_order_cnt",
            "lp_12m_net_pay_amt"
        },
        // ── Demand 维度（销售额口径）──
        // 字段: pay_amt / pay_qty / pay_order_cnt / lp_12m_pay_amt
        // 口径: 销售额 = 总销售额（含退货前）
        {
            2,
            "Demand",
            20,
            "Demand",
            "Demand 维度（销售额口径）：基于 pay_amt / pay_qty / pay_order_cnt，新客判定字段 lp_12m_pay_amt",
            FALSE,
            TRUE,
            "pay_amt",
            "pay_qty",
            "pay_order_cnt",
            "lp_12m_pay_amt"
        }
    }
)
