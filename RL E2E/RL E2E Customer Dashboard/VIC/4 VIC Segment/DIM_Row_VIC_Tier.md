DIM_Row_VIC_Tier =
// ========================================
// 表: DIM_Row_VIC_Tier
// 类型: 断开维度
// 用途: VIC分层矩阵行维度（VIC (T1-T3) 汇总 + T1 - T5 + Total 汇总，共 7 行）
// 变更: 2026-05-28 11:24创建
// 变更: 2026-11-12 14:45 新增 Row Type 列与两行汇总行：
//       VIC (T1-T3)（Indicator Order=5，置于 T1 之前）、Total（Indicator Order=60，置于 T5 之后）
//       两行 Tier ID 在事实表 customer_tier 无对应值（1:N 关系不产生事实筛选），
//       由 VIC_Segment_Table.md 各 Base 度量值的 __ChildTiers Tier 作用域显式计算
// Row Type 说明:
//   Detail = 明细行（T1-T5，Tier ID 与事实表 customer_tier 1:N 匹配）
//   Group  = 组合汇总行（VIC (T1-T3) = T1+T2+T3）
//   Total  = 总计行（Total = T1-T5）
//   SLS Total 分母（_SLS Total Base Act/LY）迭代仅取 Detail 行，避免汇总行重复加总
// ========================================
DATATABLE(
"Tier ID", STRING, // 层级ID（明细行 T1-T5 与事实表匹配；汇总行为逻辑ID）
"Row Label", STRING, // 行标签（图片展示样式）
"Description", STRING, // 详细描述（买家分层金额范围）
"Indicator Order", INTEGER, // 排序值（起始10，步长10，便于插入）
"Row Type", STRING, // 行类型（Detail=明细；Group=组合汇总；Total=总计）
{
{"VIC (T1-T3)", "VIC (T1-T3)", "VIC (T1-T3)：T1+T2+T3 汇总", 5, "Group"},
{"T1", "T1 (≧ 200K)", "T1：≧ 200K", 10, "Detail"},
{"T2", "T2 (80-200K)", "T2：80-200K", 20, "Detail"},
{"T3", "T3 (20-80K)", "T3：20-80K", 30, "Detail"},
{"T4", "T4 (5-20K)", "T4：5-20K", 40, "Detail"},
{"T5", "T5 (< 5K)", "T5：< 5K", 50, "Detail"},
{"Total", "Total", "Total：T1-T5 汇总", 60, "Total"}
}
)