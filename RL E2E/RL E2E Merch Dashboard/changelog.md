# 变更日志 — RL E2E Merch Dashboard

> 本文件记录 RL E2E Merch Dashboard 看板的代码创建与修改历史。
> 看板模块：Merchandise Performance Overview · Dimension Cross Analysis · SKU Sales Tracking
> 口径文档：

---

## 模块索引


## [ Merchandise Performance Overview ] 模块

## [2026-10-12 17:09] DAX 修复 — Sales Performance Details Base Value YOY 分子始终空值

- **模块**: Merchandise Performance Overview - Sales Performance Details by Channel
- **任务**: 修复 4.3 总路由中度量值 YOY 分子 `__SLSAmt_This` 始终返回 BLANK 的问题
- **操作**: 修改
- **变更内容**:
  - `Sales Performance Details Base Value`：YOY 分子重路由由 `REMOVEFILTERS(Dim[ColName]) + ColType = "SLS Amt"` 改为「CALCULATE 外捕获 ChannelGroup / Label_Value 标量 + `REMOVEFILTERS(整表)` + 三条件重建」
  - 根因：矩阵列头 ChannelGroup > Label > ColName 在视觉对象查询（SUMMARIZECOLUMNS）中以 GroupBy 组合筛选形式存在，单列 REMOVEFILTERS 无法剥离 ColName 部分，残留筛选与 `ColType = "SLS Amt"` 互斥 → Dim 表空集 → 始终 BLANK（同坑在 Merchandising Core KPI 已实证沉淀）
  - 同步更新方案文档 3.1 分层图 / 4.3 代码与注释 / 度量值清单 / 血缘图 / 注意事项 7、12
- **关联文件**: Sales Performance Details by Channel/Sales_Performance_Details_ms.md
- **备注**: 分母 LY Base Value 无重路由、不受影响；ChannelGroup / Label 层汇总单元格显示 "-" 的行为不变

## [Dimension Cross Analysis] 模块


## [SKU Sales Tracking] 模块

