DIM_Row_LY_Last_Purchase_Time =
// ========================================
// 表: DIM_Row_LY_Last_Purchase_Time
// 类型: 断开维度
// 用途: LY Last Purchase Time 矩阵行维度（去年VIC最后一个订单的购买时间范围）
// 变更: 2026-05-27 23:15创建
// ========================================
DATATABLE(
    "Row Label", STRING,        // 行标签（固定值）
    "Description", STRING,      // 详细描述（购买时间范围）
    "Indicator Order", INTEGER,  // 排序值（起始10，步长10，便于插入）
    {
        {"R3",    "R3：上财年10-12月", 10},
        {"R4-6",  "R4-6：上财年7-9月", 20},
        {"R7-9",  "R7-9：上财年4-6月", 30},
        {"R10-12","R10-12：上财年1-3月",40},
        {"TTL",   "TTL：总计",          50}
    }
)
