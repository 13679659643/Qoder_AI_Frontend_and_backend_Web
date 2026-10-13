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

## [2026-10-13 10:30] DAX 新建 — Top Size Sales Performance 表格解决方案

- **模块**: SKU Sales Tracking - Top Size Sales Performance
- **任务**: Sales / Inventory 双视图 Top4 category 尺码结构占比表格（SLS Amt% / LP SLS Amt% / vs LP；EOH Amt% / LP EOH Amt% / vs LP）
- **操作**: 新建
- **变更内容**:
  - 新建解决方案文档 `SKU Sales Tracking/1 Top Size Sales Performance/Top_Size_Sales Performance_table.md`（14 个度量值 + 表格视觉对象配置）
  - Rank 度量值 2 个：`Top Size Sales Category Rank`（This Period sum(net_sales_amt) 降序）、`Top Size Inventory Category Rank`（This Period 最后一天 sum(msrp_inv_amt) 降序），用于表格视觉级筛选器固定 Top1~Top4 category
  - Sales 三指标 Value + Display：SLS Amt% / LP SLS Amt%（分母 category + size category 层级，REMOVEFILTERS(sku_size)）、vs LP（差值 bp，×10000 在 Display 层）
  - Inventory 三指标 Value + Display：EOH Amt% / LP EOH Amt%（期末快照日单日时点，end period 范围内最后一天回退保护）、vs LP
  - 表格行筛选机制：视觉级筛选器 Rank = N 且 Value 不为空，仅显示本期有数据的 category + size category + size 组合
- **关联文件**: SKU Sales Tracking/1 Top Size Sales Performance/Top_Size_Sales Performance_table.md
- **备注**: net_sales_amt 为取数新增列（ROUND(product_qty × sales_price, 6)，业务确认）；inv 表无 platform / shop_name 字段，Inventory 指标不受渠道筛选影响（业务确认接受）；Sales/Inventory 视图切换由页面按钮 + 书签实现，不在度量值范围内

