# 变更日志 — RL E2E Traffic_Operation

> 本文件记录 RL E2E Traffic_Operation 看板的代码创建与修改历史。
> 看板模块：Overview · Media Mix · Category Growth · Keyword · Crowd

---

## 模块索引

| 模块 | 说明 | 子页面 |
|------|------|--------|
| **Overview** | KPIs 总览矩阵看板 | TTL汇总 · 目标达成 |
| **Media Mix** | 媒体组合分析 | — |
| **Category Growth** | 品类增长分析 | — |
| **Keyword** | 关键词分析 | — |
| **Crowd** | 人群分析 | — |

---

## [Overview] 模块

---

## [2026-05-28] 修改 — KPIs Overview TTL汇总矩阵 Platform ALL 筛选逻辑修复

- **模块**: Overview > TTL汇总
- **任务**: Platform ALL 筛选从"不施加筛选"改为显式 FILTER platform IN {"TM","JD"}
- **操作**: 修改
- **变更内容**:
  - `KPIs Overview Base Value`：TTL 行平台筛选逻辑由"不施加筛选"改为 `FILTER platform IN {"TM","JD"}`，精确圈定 TM+JD，避免未来新增平台被误聚合；废弃 `__IsAllPlatform` 不筛选方案，改用 `__PlatformFilter` 变量传递显式筛选条件
- **关联文件**: `Overview/TTL汇总/KPIs Overview_matrix_solution`
- **备注**: 该变更为防御性修复，不影响当前占位值（=1）的显示结果；原多选 VALUES+IN 模式已废弃，统一改为单选 SELECTEDVALUE + 显式 IN 模式

---

## [2026-05-27] 修改 — KPIs Overview TTL汇总矩阵重构（列结构+行标签+Platform切片器）

- **模块**: Overview > TTL汇总
- **任务**: KPIs Overview TTL汇总矩阵 v2 — 列结构重构与交互升级
- **操作**: 修改
- **变更内容**:
  - `DIM_RowKPIs_Overview`：行标签由中文改为英文（本期→This Year / 同期→Last Year / vs LP→YOY）
  - `DIM_ColMetric_Overview`：列结构从 12 列重构为 8 列，指标全部改为英文列名（Cost / Cost Rate / Cost Rate (include Refund) / Net Sales / ROI / New Customer Cost% / Acceleration Cost% / ±Acceleration Cost% vs Net Sales%）；格式列由单列拆分为三套（Metric_Format_Current / Metric_Format_LP / Metric_Format_VsLP）
  - `Slicer_Platform_Selection`：切片器类型从多选改为单选（Single select = On）；新增 ALL 选项（Platform_ID = "ALL"，代表 TM + JD 精确聚合）
  - `KPIs Overview Base Value`：所有分支当前无口径，统一返回 1（占位值）；保留原始 SWITCH 路由框架和口径注释；平台筛选逻辑随单选切片器更新
  - `KPIs Overview Cell Font Color`：字体颜色规则更新，仅 YOY 行启用条件颜色，This Year / Last Year 统一使用默认色 `#5f6165`；行标识由 "vs LP" 改为 "YOY"
  - `KPIs Overview Cell SVG Icon`：行标识由 "vs LP" 改为 "YOY"，逻辑不变
- **关联文件**: `Overview/TTL汇总/KPIs Overview_matrix_solution`
- **备注**: 交替行背景色、日期覆盖机制、汇率转换架构保持不变；Base Value 所有分支返回占位值 1，格式验证阶段预期行为正常

---

## [2026-04-29] 新建 — KPIs Overview TTL汇总矩阵初始方案

- **模块**: Overview > TTL汇总
- **任务**: KPIs Overview TTL汇总矩阵 v1 — 初始架构搭建
- **操作**: 新建
- **变更内容**:
  - `DIM_RowKPIs_Overview`：新建行维度表（断开维度），3 行：本期 / 同期 / vs LP
  - `DIM_ColMetric_Overview`：新建列维度表（断开维度），12 列，内嵌格式与颜色定义
  - `Slicer_DataCaliber_Selection`：新建数据口径参数表（T+1 / T+15）
  - `Slicer_Currency_Selection`：新建币种参数表（RMB / USD），含汇率乘数字段
  - `Slicer_Platform_Selection`：新建平台参数表（多选，TM / JD）
  - `KPIs Overview Base Value`：新建纯指标 SWITCH 分发度量值（12 分支，占位值 = 1）
  - `KPIs Overview Cell Value`：新建行路由度量值（本期 / 同期 LP 日期覆盖 / vs LP 增长率）；含币种汇率转换逻辑
  - `KPIs Overview Cell Display`：新建格式化显示度量值，支持 currency / integer / decimal_2 / percent_1dp / delta_pct_1dp 五种格式
  - `KPIs Overview Cell Font Color`：新建字体颜色条件格式度量值
  - `KPIs Overview Cell SVG Icon`：新建 SVG 箭头图标度量值（仅 vs LP 行）
  - `KPIs Overview Cell Background Color`：新建交替行背景色度量值
- **关联文件**: `Overview/TTL汇总/KPIs Overview_matrix_solution`
- **备注**: 初始版本，事实表字段口径均为占位值；架构设计：断开维度 + Metric_ID SWITCH 分发 + 同期日期 CALCULATE 覆盖 + 汇率乘数转换

---

## [2026-05-28] 修改 — KPIs Overview 目标达成矩阵 Base Value 拆分重构

- **模块**: Overview > 目标达成
- **任务**: 目标达成矩阵 Context Transition 问题修复 — Base Value 拆分为 Actual + Target 两个独立度量值
- **操作**: 修改
- **变更内容**:
  - `KPIs Overview Target Actual Base Value`（新增）：从原 Base Value 拆分，纯 Actual 实际值 SWITCH 分发器，9 分支，不含行类型判断；所有分支当前返回 1（占位值）
  - `KPIs Overview Target Target Base Value`（新增）：从原 Base Value 拆分，纯 Target 目标值 SWITCH 分发器，含 TargetPeriod 粒度路由（`SWITCH(__TargetPeriodID, 1,1, 2,2, 3,3, 4,4, 10)`）；所有分支当前返回占位测试值；待目标表就绪后填充真实口径
  - `KPIs Overview Target Base Value`（废弃）：原合并度量值中 `IF(__Indicator="Actual",...)` 模式废弃，因 CALCULATE 覆盖行上下文时 SELECTEDVALUE 在 Context Transition 后取值不稳定
- **关联文件**: `Overview/目标达成/KPIs Overview_Target_matrix_solution`
- **备注**: 修复根因：Cell Value 层通过 CALCULATE 覆盖行上下文分别取 Actual/Target 值时，`__Indicator` 的 SELECTEDVALUE 在某些情况下未能正确感知覆盖，导致 ±Actual vs Target 行计算错误；拆分后彻底消除不确定性

---

## [2026-05-27] 修改 — KPIs Overview 目标达成矩阵 Platform 切片器改为单选并新增 ALL 选项

- **模块**: Overview > 目标达成
- **任务**: 目标达成矩阵 Platform 交互升级（与 TTL汇总保持一致）
- **操作**: 修改
- **变更内容**:
  - `Slicer_Platform_Selection`：目标达成矩阵复用 TTL汇总的 Platform 参数表；切片器类型从多选改为单选（Single select = On）；新增 ALL 选项（Platform_ID = "ALL"，代表 TM + JD 精确聚合）
  - `KPIs Overview Target Base Value`（当时版本）：Base Value 中平台筛选逻辑更新：ALL → `FILTER platform IN {"TM","JD"}`（精确圈定）；TM/JD → `platform = __ChannelID`（单平台精确筛选）；废弃原多选的 VALUES + IN 模式
- **关联文件**: `Overview/目标达成/KPIs Overview_Target_matrix_solution`
- **备注**: 3.3节完整定义与 TTL汇总方案保持一致，直接复用 Slicer_Platform_Selection 表

---

## [2026-04-29] 新建 — KPIs Overview 目标达成矩阵初始方案

- **模块**: Overview > 目标达成
- **任务**: KPIs Overview 目标达成矩阵 v1 — 初始架构搭建
- **操作**: 新建
- **变更内容**:
  - `DIM_RowKPIs_Overview_Target`：新建行维度表（断开维度，仅目标达成矩阵使用），3 行：Actual / Target / ±Actual vs Target；`Sort by Column`：Indicator_Type → Indicator_Order
  - `DIM_ColMetric_Target`：新建列维度表（断开维度），9 列（Cost Rate / RTB Cost ACH% / Cost ACH% / Net Sales ACH% / Demand Sales ACH% / Media New Customer Coverage% / Cost Per New Acquisition / Acceleration Cost% / Net Sales%）；内嵌格式与颜色定义；`Metric_Sort` 起始值 = 7（遵循 domain-rules 规范）
  - `Slicer_TargetPeriod_Selection`（新增）：新建时间粒度参数表，4 个选项（Week=1 / Month=2 / Quarter=3 / Year=4），单选，默认选中 Month；用于按粒度切换 Target 目标值
  - `Slicer_DataCaliber_Selection`：复用 TTL汇总方案，无需重建
  - `Slicer_Currency_Selection`：复用 TTL汇总方案，无需重建
  - `KPIs Overview Target Base Value`（初始版）：新建度量值，行×列 SWITCH 双路由（3行×9列）；含 TargetPeriod 粒度路由框架；当前值全部填充 1（占位值）；Platform 由 Slicer_Platform_Selection 单选控制
  - `KPIs Overview Target Cell Value`：新建行路由度量值（Actual / Target / ±Actual vs Target）；金额类指标含汇率换算；±Actual vs Target = (Actual - Target) / Target，不受汇率影响
  - `KPIs Overview Target Cell Display`：新建格式化显示度量值；±Actual vs Target 行固定使用 delta_pct_1dp 格式
  - `KPIs Overview Target Cell Font Color`：新建字体颜色度量值；仅 ±Actual vs Target 行启用正/负/零三色；Actual / Target 行统一使用 `#5f6165`
  - `KPIs Overview Target Cell SVG Icon`：新建 SVG 箭头图标度量值（仅 ±Actual vs Target 行）
  - `KPIs Overview Target Cell Background Color`：新建交替行背景色度量值（Actual=白 / Target=浅灰 / ±Actual vs Target=白）
- **关联文件**: `Overview/目标达成/KPIs Overview_Target_matrix_solution`
- **备注**: 事实表（a05_e2e_paid_media_channel/summary/product_data_d）和目标表尚未开发完成，所有字段口径为预留占位；路由框架已保留，待数据就绪后填充真实口径；与 TTL汇总矩阵的主要差异：行维度为 Actual/Target/±delta（非 This Year/Last Year/YOY），无需 Dim_Date_Ly

---

## [Media Mix] 模块

> 暂无变更记录

---

## [Category Growth] 模块

> 暂无变更记录

---

## [Keyword] 模块

> 暂无变更记录

---

## [Crowd] 模块

> 暂无变更记录
