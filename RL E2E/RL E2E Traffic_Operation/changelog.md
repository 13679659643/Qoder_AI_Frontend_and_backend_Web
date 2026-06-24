# 变更日志 — RL E2E Traffic_Operation

> 本文件记录 RL E2E Traffic_Operation 看板的代码创建与修改历史。
> 看板模块：Overview · Media Mix · Category Growth · Keyword · Crowd

---

## 模块索引

| 模块                      | 说明              | 子页面              |
| ------------------------- | ----------------- | ------------------- |
| **Overview**        | KPIs 总览矩阵看板 | TTL汇总 · 目标达成 |
| **Media Mix**       | 媒体组合分析      | —                  |
| **Category Growth** | 品类增长分析      | —                  |
| **Keyword**         | 关键词分析        | —                  |
| **Crowd**           | 人群分析          | —                  |

---

## [Overview] 模块

---

## [2026-06-24 11:05] 修改 — KPIs Overview 目标达成矩阵列维度重构为 10 指标 + Cost Rate 口径填充

- **模块**: Overview > 目标达成
- **任务**: KPIs Overview 目标达成矩阵 v4 — 列维度重构为 10 个指标并补充 Cost Rate 口径
- **操作**: 修改
- **变更内容**:
  - `DIM_ColMetric_Target`：列维度从 9 个指标重构为 10 个指标，严格按以下顺序：Cost Rate / RTB Cost ACH% / Cost ACH% / Cost ACH%(Exclude Refund) / Net Sales ACH% / Demand Sales ACH% / Acceleration Cost% / Acceleration Net Sales% / Media Contribution to New Customer Acquisition% / Cost Per New Acquisition；新增 Cost ACH%(Exclude Refund)（ID 4）、Acceleration Net Sales%（ID 8）、Media Contribution to New Customer Acquisition%（ID 9）；移除 Media New Customer Coverage%（原 ID 6）、Net Sales%（原 ID 9）；Acceleration Cost% 由原 ID 8 调整至 ID 7；Cost Per New Acquisition 由原 ID 7 调整至 ID 10（列尾，保留 currency 格式与 Metric_IsCurrencyAmount=TRUE）；Metric_Sort 步长 10（10~100）
  - `KPIs Overview Target Actual Base Value`：SWITCH 分发器从 9 分支扩展为 10 分支；ID 1 Cost Rate 填充真实口径 `DIVIDE(SUM(a05_e2e_paid_media_summary_d[cost_amt]), SUM(a05_e2e_paid_media_summary_d[net_sales_amt]))`，含 Platform 单选/ALL 精确筛选（TTL → IN {"TM","JD"}，单平台 → = __ChannelID）与 trans_cycle 单选筛选；其余 9 个分支（ID 2~10）保留占位值 1 与口径注释框架
  - `KPIs Overview Target Target Base Value`：SWITCH 分发器从 9 分支扩展为 10 分支；所有分支（ID 1~10）保留 TargetPeriod 粒度路由占位值，待目标表就绪后填充
- **关联文件**: `Overview/目标达成/KPIs Overview_Target_matrix_solution`
- **备注**: 其余架构（行维度 Actual/Target/±Actual vs Target、断开维度、汇率转换、Platform 单选+ALL 精确筛选、TargetPeriod 粒度路由、行路由、格式化、条件颜色、SVG 图标、交替行背景色）保持不变；Cost ACH%(Exclude Refund) / Acceleration Net Sales% / Media Contribution to New Customer Acquisition% 口径待业务确认后填充

---

## [2026-06-24 10:15] 修改 — KPIs Overview TTL汇总矩阵列维度重构为 9 指标 + Cost 口径填充

- **模块**: Overview > TTL汇总
- **任务**: KPIs Overview TTL汇总矩阵 v3 — 列维度重构为 9 个指标并补充 Cost 口径
- **操作**: 修改
- **变更内容**:
  - `DIM_ColMetric_Overview`：列维度从 8 个指标重构为 9 个指标，严格按以下顺序：Cost / Cost Rate / Cost (Exclude Refund) / Cost Rate (Exclude Refund) / Net Sales / ROI / Acceleration Cost% / ±Acceleration Cost% vs Net Sales% / New Customer Cost%；新增 Cost (Exclude Refund)（ID 3）、Cost Rate (Exclude Refund)（ID 4）；移除 Cost Rate (include Refund)（原 ID 3）；New Customer Cost% 由原 ID 6 调整至 ID 9（列尾）；Metric_Sort 步长 10（10~90）
  - `KPIs Overview Base Value`：SWITCH 分发器从 8 分支扩展为 9 分支；ID 1 Cost 填充真实口径 `SUM(a05_e2e_paid_media_summary_d[cost_amt])`，含 Platform 单选/ALL 精确筛选（TTL → IN {"TM","JD"}，单平台 → = __ChannelID）与 trans_cycle 单选筛选；其余 8 个分支（ID 2~9）保留占位值 1 与口径注释框架
- **关联文件**: `Overview/TTL汇总/KPIs Overview_matrix_solution`
- **备注**: 其余架构（断开维度、日期覆盖机制、汇率转换、Platform 单选+ALL 精确筛选、行路由、格式化、条件颜色、SVG 图标、交替行背景色）保持不变；Cost (Exclude Refund) / Cost Rate (Exclude Refund) 口径待业务确认后填充

---

## [2026-05-28 09:32] 修改 — KPIs Overview TTL汇总矩阵 Platform ALL 筛选逻辑修复

- **模块**: Overview > TTL汇总
- **任务**: Platform ALL 筛选从"不施加筛选"改为显式 FILTER platform IN {"TM","JD"}
- **操作**: 修改
- **变更内容**:
  - `KPIs Overview Base Value`：TTL 行平台筛选逻辑由"不施加筛选"改为 `FILTER platform IN {"TM","JD"}`，精确圈定 TM+JD，避免未来新增平台被误聚合；废弃 `__IsAllPlatform` 不筛选方案，改用 `__PlatformFilter` 变量传递显式筛选条件
- **关联文件**: `Overview/TTL汇总/KPIs Overview_matrix_solution`
- **备注**: 该变更为防御性修复，不影响当前占位值（=1）的显示结果；原多选 VALUES+IN 模式已废弃，统一改为单选 SELECTEDVALUE + 显式 IN 模式

---

## [2026-05-27 17:09] 修改 — KPIs Overview TTL汇总矩阵重构（列结构+行标签+Platform切片器）

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

## [2026-04-29 16:13] 新建 — KPIs Overview TTL汇总矩阵初始方案

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

## [2026-05-28 14:59] 修改 — KPIs Overview 目标达成矩阵 Base Value 拆分重构

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

## [2026-05-27 16:00] 修改 — KPIs Overview 目标达成矩阵 Platform 切片器改为单选并新增 ALL 选项

- **模块**: Overview > 目标达成
- **任务**: 目标达成矩阵 Platform 交互升级（与 TTL汇总保持一致）
- **操作**: 修改
- **变更内容**:
  - `Slicer_Platform_Selection`：目标达成矩阵复用 TTL汇总的 Platform 参数表；切片器类型从多选改为单选（Single select = On）；新增 ALL 选项（Platform_ID = "ALL"，代表 TM + JD 精确聚合）
  - `KPIs Overview Target Base Value`（当时版本）：Base Value 中平台筛选逻辑更新：ALL → `FILTER platform IN {"TM","JD"}`（精确圈定）；TM/JD → `platform = __ChannelID`（单平台精确筛选）；废弃原多选的 VALUES + IN 模式
- **关联文件**: `Overview/目标达成/KPIs Overview_Target_matrix_solution`
- **备注**: 3.3节完整定义与 TTL汇总方案保持一致，直接复用 Slicer_Platform_Selection 表

---

## [2026-04-29 15:00] 新建 — KPIs Overview 目标达成矩阵初始方案

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

---

## [2026-06-01 HH:MM] 修改 — Media Mix 矩阵方案 v1.8.2 冗余变量清除 + 关联字段规范修正

- **模块**: Media Mix
- **任务**: 三项修正：删除未使用 DAX 变量 / 关联事实表字段从 Channel_Label 改为 Channel / 更新相关注释与架构说明
- **操作**: 修改
- **变更内容**:
  - `Media Mix Base Value`（DAX 代码精简）：
    - **删除冗余变量** `__ChannelLabel` 和 `__ChannelType`：这两个变量在 v1.8 统一 SELECTCOLUMNS 路径后
      已无任何引用，属于死代码，予以删除
    - **关联字段修正**：`__Labels` / `__ParentLabels` 的 `SELECTCOLUMNS` 中，
      取值字段从 `Dim_Media_Mix_Channel[Channel_Label]` 改为 `Dim_Media_Mix_Channel[Channel]`；
      列别名从 `"@Label"` 改为 `"@Channel"`
      **根本原因**：`Channel_Label` 是展示标签（v1.8.1 中 JD 重名行已加全角空格后缀），
      与事实表 `[channel]` 字段不一致，导致 `channel IN __Labels` 筛选失败，
      绝大多数 DETAIL 行 Cost 返回空值，仅个别行因偶然一致而有值（如超级短视频）；
      `Channel` 字段存储原始渠道名，与事实表保持一致，是正确的关联键
  - `Media_Mix_matrix_solution` 文档（注释/说明全面更新）：
    - Section 3 变更记录：更新条目 3/4，去除旧 `__ChannelLabel`/`__ChannelType` 引用
    - Section 4.3 联动方式：移除旧变量列表，新增 Channel vs Channel_Label 使用规范说明
    - Section 4.4 字段映射：标题/内容从 `Channel_Label` 改为 `Channel`，补充禁止使用 Channel_Label 关联的警告
    - Section 5.1 头部注释：更新条目 3/4，依赖字段列表更新为 `Channel/Parent_Channel_ID`
    - Section 9.1 聚合机制：架构版本更新为 v1.8，`__Labels` 描述改为 Channel 字段，补充约束 d
    - Section 9.5 诊断：标注原因 A 已修复，更新排查步骤用 `Channel` 而非 `Channel_Label` 对比
    - Section 11 血缘图：更新 FILTER 描述从旧双路径改为统一 `__Labels` 路径
- **关联文件**: `Media Mix/Media_Mix_matrix_solution`
- **备注**:
  - Power BI 中需重新加载 `Dim_Media_Mix_Channel`（确保含 `Channel`、`Summary_Scope`、`Parent_Channel_ID` 字段）
  - 事实表 `[channel]` 字段应存储原始中文渠道名（无全角空格），与 `Dim_Media_Mix_Channel[Channel]` 完全一致

---

## [2026-06-01 HH:MM] 修改 — Media Mix 矩阵方案 v1.8.1 Background Color 刻度修正 + SQL 排序冲突修复 + 数据诊断

- **模块**: Media Mix
- **任务**: 三项独立修复：交替行背景色计算错误 / Channel_Label 重名导致排序冲突 / 仅超级短视频有cost值的原因诊断
- **操作**: 修改
- **变更内容**:
  - `Media Mix Cell Background Color`（DAX 修复）：
    - Indicator Order 刻度从 1/2/3 升级为 10/20/30 后，`MOD(__EffRowID, 2)` 失效
      修复：新增 `VAR __RowPos = INT(__EffRowID / 10)` 还原行位次，改用 `MOD(__RowPos, 2)` 判断
      10→1（This Year=白）、20→2（Last Year=灰）、30→3（YOY=白）
  - `Media_Mix_SQL`（排序冲突修复，v1.8.1）：
    - Power BI Sort-by-Column 要求 Channel_Label 与 Platform_Sort 1:1 映射"RTB Total" / "JCGP Total" / "Total" / "Total 不含JCGP" 同时出现在 TM（Sort=1）和 JD（Sort=2）导致报错JD 内两个"品牌动态秀"（JD_PPDTX_1 / JD_PPDTX_2）也重名修复：JD 侧重名 Channel_Label 末尾追加全角空格（U+3000），视觉无差异但字符串唯一：`'RTB Total　'` / `'JCGP Total　'` / `'Total　'` / `'Total 不含JCGP　'` / `'品牌动态秀　'`（第二个）
    - ⚠️ DAX __Labels 用 Channel_ID 匹配（不受 Channel_Label 变化影响），但事实表 channel 字段
      若依赖 Channel_Label 关联则需同步更新（见备注）
  - `Media_Mix_matrix_solution` Section 9.5（新增常见问题排查）：
    - 记录"仅超级短视频有值"问题的三种可能原因及 DAX 查询排查步骤
      原因A：事实表 channel 字段值与 Channel_Label 不一致（最高概率）
      原因B：Dim_Media_Mix_Channel 未刷新，其他 DETAIL 行 Summary_Scope 仍为 NULL
      原因C：Parent_Channel_ID 字段未加载（仅影响 Cost%，不影响 Cost 绝对值）
  - Checklist 中 Cost% 验证项更新为正确口径（直通车 / RTB Total，非平台 Total）
- **关联文件**: `Media Mix/Media_Mix_matrix_solution`, `Media Mix/Media_Mix_SQL`
- **备注**:
  - JD Channel_Label 加全角空格后，若事实表 channel 字段存的是 Channel_Label 原值（无后缀），则 `channel IN __Labels` 仍能正常匹配（因为 __Labels 来自 Dim_Media_Mix_Channel，会随维度表刷新而更新）但需确认：事实表 [channel] 的值 **不包含** 全角空格后缀（即仍为原始中文名）→ 若事实表数据是原始渠道名，则无需改事实表；若事实表数据和维度表同源，需排查
  - 诊断步骤详见 `Media_Mix_matrix_solution` Section 9.5

---

## [2026-06-01 HH:MM] 修改 — Media Mix 矩阵方案 v1.8 DAX 语法修复 + Cost% 口径修正 + SQL 结构升级

- **模块**: Media Mix
- **任务**: v1.7 遗留问题修复 — IF()无法返回表 + DETAIL行Summary_Scope为空 + Cost%分母口径错误
- **操作**: 修改
- **变更内容**:
  - `Media_Mix_SQL`（结构升级）：
    - **DETAIL 行 Summary_Scope**：从 `NULL` 改为自身 `Channel_ID`（如 `'TM_ZTC'`）使 DAX 中 CONTAINSSTRING 在 DETAIL 行也能命中自己，无需 IF 分支
    - **新增 `Parent_Channel_ID` 字段**：标识每行 Cost% 分母所属的 SUMMARY 行DETAIL 行 → 所属最近上级 SUMMARY（如 TM_ZTC → TM_RTB_TOTAL）SUMMARY 行 → 自身（如 TM_RTB_TOTAL → TM_RTB_TOTAL，Cost%=100%）
    - 全部 31 行数据已同步更新
  - `Media Mix Base Value`（DAX 语法修复 + 口径重写）：
    - **__Labels 变量**：去掉 `IF()` 包裹（DAX 中 IF 无法返回表），改为统一 `SELECTCOLUMNS(FILTER(...))`因 DETAIL 行 Summary_Scope 现为自身 Channel_ID，CONTAINSSTRING 自然命中
    - **Cost% 口径修正**：
      旧口径：当前行 cost / 平台所有 DETAIL channel cost 之和（= Total）
      新口径：当前行 cost / `Parent_Channel_ID` 对应 SUMMARY 行的 cost
      新增 `__ParentID` / `__ParentScope` / `__ParentLabels` / `__TotalCost` 变量链实现
      SUMMARY 行分母 = 自身（Parent 自指）→ Cost% 恒为 100%
  - `Media_Mix_matrix_solution` 文件头：版本号 v1.7 → v1.8，变更摘要补充
- **关联文件**: `Media Mix/Media_Mix_SQL`, `Media Mix/Media_Mix_matrix_solution`
- **备注**:
  - Dim_Media_Mix_Channel 在 Power BI 中需重新加载以获取新字段 `Parent_Channel_ID` 和更新的 `Summary_Scope`
  - 下游度量值（Cell Value / Cell Display / Font Color 等）无需修改，仅依赖 Base Value 返回值
  - v1.7 的修复（去 ALL、边界包裹、列级条件）保持有效，v1.8 在其基础上进一步修正

---

## [2026-06-01 HH:MM] 修改 — Media Mix 矩阵方案 v1.7 架构重大修复

- **模块**: Media Mix
- **任务**: Media Mix Base Value 架构重大问题修复 — ALL(事实表) 日期筛选失效 + DETAIL/SUMMARY路径合并 + CONTAINSSTRING 精确匹配
- **操作**: 修改
- **变更内容**:
  - `Media Mix Base Value`（架构重写）：
    - **[致命修复]** 移除 `FILTER(ALL(a05_e2e_paid_media_channel_data_d), ...)` 滥用原方案 `ALL(事实表)` 清空了通过 `Dim_Date_Current` 关系传递的 `data_date` 筛选，导致：① 用户切换日期切片器时矩阵数据不变；② Cell Value 层 LP 日期覆盖失效 → Last Year ≡ This Year → YOY ≡ 0修正为 CALCULATE + 列级条件过滤（`[channel] IN __Labels, [platform]=..., [trans_cycle]=...`），日期上下文由 `Dim_Date_Current` 关系自然传递，不在度量值中显式管理
    - **[设计加固]** CONTAINSSTRING 边界包裹：`CONTAINSSTRING("|" & __SummaryScope & "|", "|" & Channel_ID & "|")`防止子串误匹配（如 Channel_ID="TM_Z" 误命中 "TM_ZTC|TM_YLMF"）
    - **[架构精简]** DETAIL / SUMMARY 路径合并为统一 `channel IN __Labels`：DETAIL 行 `__Labels = ROW("@Label", __ChannelLabel)`（单元素）SUMMARY 行 `__Labels = SELECTCOLUMNS(FILTER(...))`（多元素）13 个指标共用同一 `__Labels`，代码量减半；废弃 `__IsDetail`/`__IsSummary`/`__Cost_Detail`/`__Cost_Summary` 分支
    - **[性能优化]** `__Labels` 用 `IF(__ChannelType = "SUMMARY", ...)` 延迟计算，DETAIL 行直接 ROW 构造，不扫描 `Dim_Media_Mix_Channel`
    - **[新增]** Section 5.1 末尾追加"后续指标口径填充模板"，规定统一聚合模式
  - `Section 9.1`（重写）：SUMMARY 行聚合机制更新为 v1.7 架构（4步说明 + 3条约束）
- **关联文件**: `Media Mix/Media_Mix_matrix_solution`
- **备注**:
  - Cell Value / Cell Display / Cell Font Color 等下游度量值无需修改（仅依赖 `[Media Mix Base Value]` 返回值）
  - SWITCH 部分口径不变（ID 1=__Cost, ID 2=__CostPct, ID 3-13=占位1）
  - 此修复为 v1.6（Summary_Scope 格式修复）的后续，两者组合才能使矩阵完整正常工作

---

## [2026-05-29 10:00] 新建 — Media Mix Channel 维度配置 SQL（写死结构，保留扩展性）

- **模块**: Media Mix
- **任务**: 构建 Media Mix Channel 维度配置数据源，覆盖 TM / JD 双平台全部渠道，含明细行与汇总行
- **操作**: 新建
- **变更内容**:
  - `Media_Mix_SQL`（新建）：纯 `SELECT … UNION ALL` 结构，无建表语句，当前阶段写死全部渠道数据；输出字段：`Channel_PK / Platform / Platform_Sort / Channel / Channel_Sort / Channel_Label / Channel_Description / Channel_Type / Channel_ID / Summary_Scope`
  - **TM 平台（11行）**：
    - DETAIL：直通车 / 引力魔方 / 全站推/万象台 / 超级短视频 / 品牌专区 / 品牌特秀
    - SUMMARY：RTB Total（直通车+引力魔方+全站推/万象台+超级短视频）/ 品销宝 Total（含品牌专区）/ JCGP Total（品销宝 Total+品牌特秀）/ Total / Total 不含JCGP
  - **JD 平台（20行）**：
    - DETAIL：快车 / 触点 / 海投 / 直投 / 京选店铺 / 搜索品专 / Branzone / 联合活动 / 开屏 / 吸顶通栏 / 营销阵地 / 品牌动态秀×2 / 首焦 / 京腾-腾讯闪屏
    - SUMMARY：RTB Total / RTB Total + 京选店铺 / JCGP Total / Total / Total 不含JCGP
  - **Channel_Type 区分规则**：图中红框圈出的行（RTB Total、品销宝 Total、JCGP Total、Total、Total 不含JCGP 等）标记为 `SUMMARY`，其余明细行标记为 `DETAIL`
  - **Channel_ID**：与事实表 `channel` 字段值对齐（如 `TM_ZTC`、`JD_QC`），便于后续 JOIN 替代写死数据
  - **Summary_Scope**：汇总行记录聚合范围（以 Channel_ID 枚举），DAX 端可据此 FILTER 明细行实现动态聚合；明细行为 NULL
- **关联文件**: `Media Mix/Media_Mix_SQL`
- **扩展性保留**:
  - 后续从事实表动态读取 Channel 时，将 DETAIL 行的 `UNION ALL SELECT` 替换为 `DISTINCT channel FROM` 事实表查询，SUMMARY 行仍写死
  - `channel_sort` 按间隔 10 预留空位，新增渠道直接插入中间值
  - Platform ALL 筛选遵循项目规范：`FILTER(platform IN {"TM","JD"})`，禁止无条件不筛选
- **备注**: 字段别名统一使用英文（`Channel_PK` 等），遵循 SQL 字段英文命名规范

---

## [2026-05-29 11:00] 新建 — Media Mix 渠道粒度矩阵看板初始方案

- **模块**: Media Mix
- **任务**: Media Mix 矩阵看板 v1 — 全渠道粒度，含 DETAIL/SUMMARY 双路径聚合，13 列指标
- **操作**: 新建
- **变更内容**:
  - `DIM_RowKPIs_Media_Mix`（新建）：断开维度，3 行（This Year / Last Year / YOY），结构与 `DIM_RowKPIs_Overview` 同构，独立建表避免跨页干扰
  - `DIM_ColMetric_Media_Mix`（新建）：断开维度，13 列指标（Cost / Cost% / ROI / Impression / Click / Add to Cart / Orders / GMV / CTR / CPC / CPATC / CVR / AOV）；内嵌三套格式列 + 四色列 + 汇率标记；成本类指标（Cost / Cost% / CPC / CPATC）YOY 颜色已在维度表中反转（正向=红/负向=绿）
  - `Media Mix Base Value`（新建）：13 分支 SWITCH 纯指标分发器；含 DETAIL/SUMMARY 双路径聚合逻辑：DETAIL 行通过 `channel = Channel_Label` 精确过滤，SUMMARY 行通过 `CONTAINSSTRING(Summary_Scope, Channel_ID)` 解析 `Summary_Scope` 字段获取对应 DETAIL 行 Label 集合，再 `channel IN` 枚举聚合；Platform 由矩阵行上下文 `SELECTEDVALUE(Dim_Media_Mix_Channel[Platform])` 自然获取，无外部切片器依赖；已有口径：Cost（`SUM(cost_amt)`）、Cost%（当前行 cost / 当前平台所有 DETAIL channel cost 之和）；其余 ID 3~13 返回占位值 1
  - `Media Mix Cell Value`（新建）：行路由度量值（This Year / Last Year / YOY）+ LP 日期覆盖 + 汇率换算，机制与 `KPIs Overview Cell Value` 完全一致
  - `Media Mix Cell Display`（新建）：格式化显示度量值，支持 currency / integer / decimal_2 / percent_1dp / delta_pct_1dp 等格式，货币符号动态读取
  - `Media Mix Cell Font Color`（新建）：YOY 行条件颜色（正/负/零），This Year / Last Year 统一 `#5f6165`
  - `Media Mix Cell SVG Icon`（新建）：YOY 行箭头图标，数据类别需设为"图像 URL"
  - `Media Mix Cell Background Color`（新建）：交替行背景色（This Year=白 / Last Year=浅灰 / YOY=白）
- **关联文件**: `Media Mix/Media_Mix_matrix_solution`
- **备注**: Dim_Media_Mix_Channel 已由 Media_Mix_SQL 加载，无需重建；Platform 切片器直接使用 `Dim_Media_Mix_Channel[Platform]` 字段（单选），Power BI 对断开维度行上下文天然隔离，无需辅助度量值；切片器不选 = 全平台（ALL 等效）

---

## [2026-05-29 14:00] 修改 — Media Mix 矩阵方案 v1.1 架构修订（删除冗余设计）

- **模块**: Media Mix
- **任务**: Media Mix 矩阵看板架构修订 — Platform 筛选机制简化
- **操作**: 修改
- **变更内容**:
  - `Media_Mix_matrix_solution`（修改）：移除第 1 节 `Dim_Media_Mix_Channel` DATATABLE 代码（表已由 SQL 加载，无需 DAX 重建）；保留字段说明和 Sort by Column 配置
  - `Media Mix Channel Platform Filter`（删除/不创建）：原设计通过 `Slicer_Platform_Selection` + 辅助度量值控制矩阵行可见性，因两者均为断开维度且无关联，逻辑冗余；正确方案为直接使用 `Dim_Media_Mix_Channel[Platform]` 作切片器字段，行上下文天然隔离，无需辅助度量值
  - `Media Mix Base Value`（注释修订）：明确 Platform 上下文来源为行维度自然传入，删除 `Slicer_Platform_Selection` 相关引用注释
  - `5.7 节`（内容替换）：由"辅助度量值"变更为"[可选扩展] ALL 场景说明"，记录方案A（不选=ALL）和方案B（独立参数表切片器）两种 ALL 处理策略
  - 度量值总数：7 个 → 6 个（删除 `Media Mix Channel Platform Filter`）
  - 第 6.3 节（切片器配置）：Platform 切片器字段从 `Slicer_Platform_Selection[Platform_Label]` 改为 `Dim_Media_Mix_Channel[Platform]`
  - 第 10 节（操作清单）：对应更新，删除 `Slicer_Platform_Selection` 和 `Channel Platform Filter` 相关条目
- **关联文件**: `Media Mix/Media_Mix_matrix_solution`
- **备注**: 架构简化原则：断开维度的行上下文由 Power BI 矩阵自然管理，外部切片器选择 `Dim_Media_Mix_Channel[Platform]` 时，矩阵对断开维度施加筛选上下文，每行 `__RowPlatform` 值唯一确定，聚合不会跨平台混淆

---

## [2026-06-01 09:30] 修改 — Media Mix 矩阵方案 v1.2 规范合规修订

- **模块**: Media Mix
- **任务**: Media Mix 矩阵看板规范合规修订 — 修正 domain-rule 违规 + 消除 v1.1 后遗留的陈旧引用
- **操作**: 修改
- **变更内容**:
  - `DIM_ColMetric_Media_Mix`（DATATABLE Metric_Sort 字段修正）：原值 `1,2,3...13` 违反 domain-rule「排序字段起始值从7开始」修正为 `7,8,9,10,11,12,13,14,15,16,17,18,19`（起始 7，步长 1）
  - `Section 4.2 断开维度列表`（修正）：移除 `Slicer_Platform_Selection` 条目（v1.1 已废弃）；补充注释说明 Platform 筛选通过 `Dim_Media_Mix_Channel[Platform]` 直接切片器实现
  - `Section 9.2 平台筛选技术说明`（修正）：移除旧方案描述（辅助度量值 + 视觉层筛选器）；改写为 v1.1 正确方案（直接切片器方案）
  - `Section 11 血缘关系图`（修正）：
    移除 `Slicer_Platform_Selection` 和 `[Channel Platform Filter]` 旧方框；补充 `Slicer_DataCaliber_Selection` 和 `Slicer_Currency_Selection` 方框
- **关联文件**: `Media Mix/Media_Mix_matrix_solution`
- **备注**:
  - Metric_ColorPositive/Negative 按指标差异化（成本类反转）属于有意的业务设计，非违规；domain-rule 颜色为 fallback 默认值，维度表驱动差异化颜色是断开维度模式标准做法
  - 本次修订无 DAX 逻辑变更，仅修正排序字段值和陈旧文档内容

---

## [2026-06-01 10:30] 修改 — Media Mix 矩阵方案 v1.3 颜色规则统一修正

- **模块**: Media Mix
- **任务**: DIM_ColMetric_Media_Mix 颜色规则修正 — 统一按数值正负判断，不区分指标业务性质
- **操作**: 修改
- **变更内容**:
  - `DIM_ColMetric_Media_Mix`（DATATABLE 颜色列修正）：将 Cost / Cost% / CPC / CPATC 四个指标的 `Metric_ColorPositive` 从 `#D64550`（红）改回 `#1A9018`（绿），`Metric_ColorNegative` 从 `#1A9018`（绿）改回 `#D64550`（红）；所有 13 个指标颜色规则统一：正值（>0）= 绿色，负值（<0）= 红色，零值 = 黄色
  - Section 3 颜色约定注释（修正）：移除"Cost/Cost% 业务上正向不好，可在此反转"误导性描述
  - Section 8 YOY 颜色方向说明（修正）：改为"不区分指标业务性质，只看数值正负"
- **关联文件**: `Media Mix/Media_Mix_matrix_solution`
- **备注**: 参考 KPIs Overview_matrix_solution（`DIM_ColMetric_Overview`）的颜色配置，确认 Overview 方案中 Cost 等成本指标同样使用统一颜色规则（无反转）

---

## [2026-06-01 11:30] 修改 — Media Mix 矩阵方案 v1.4 排序字段步长规范修订

- **模块**: Media Mix
- **任务**: 排序字段步长规范修订 — slicer-tips.md 规则更新后对齐，步长改为 10 提升扩展性
- **操作**: 修改
- **变更内容**:
  - `DIM_RowKPIs_Media_Mix`（Indicator Order 字段修正）：`1, 2, 3` → `7, 17, 27`（起始7，步长10，便于后续在行间插入新类型）
  - `DIM_ColMetric_Media_Mix`（Metric_Sort 字段修正）：`7, 8, 9, ..., 19`（步长1）→ `7, 17, 27, 37, 47, 57, 67, 77, 87, 97, 107, 117, 127`（步长10）起始值 7 保持不变（符合 domain-rule），步长从 1 改为 10
  - `Media_Mix_matrix_solution` 文件头部日志清理：移除文件内全量历史变更日志，只保留最新版本摘要（v1.4）；历史详细记录统一归档至 `changelog.md`
  - Section 10 验证清单颜色描述（顺带修正）：
    "Cost 正向=红色，ROI 正向=绿色" → "正值=绿色，负值=红色，零值=黄色，全指标统一"
- **关联文件**: `Media Mix/Media_Mix_matrix_solution`
- **备注**:
  - slicer-tips.md 规范：`_Sort` 字段尽量不从1开始，步长不能为1，便于后续新增字段扩展
  - domain-rules.md 规范：排序字段起始值从7开始（⚠️ 已被 v1.5 修订为起始10）
  - 两条规则组合结果：起始7，步长10（7, 17, 27...）（⚠️ 已被 v1.5 修订为起始10，步长10）

---

## [2026-06-01 12:30] 修改 — Media Mix 矩阵方案 v1.5 排序起始值修正（7→10）

- **模块**: Media Mix
- **任务**: domain-rules.md 排序规范起始值修正后同步更新 — 起始值 7 → 10
- **操作**: 修改
- **变更内容**:
  - `domain-rules.md`（用户已直接修改）：`起始值从7开始` → `起始值从10开始，步长用 10，便于后续插入`
  - `DIM_RowKPIs_Media_Mix`（Indicator Order 修正）：`7, 17, 27` → `10, 20, 30`
  - `DIM_ColMetric_Media_Mix`（Metric_Sort 修正）：`7, 17, 27, ..., 127` → `10, 20, 30, 40, 50, 60, 70, 80, 90, 100, 110, 120, 130`
  - `Media_Mix_matrix_solution` 文件头版本摘要更新至 v1.5
- **关联文件**: `Media Mix/Media_Mix_matrix_solution`, `powerbi_code_copilot/rules/domain-rules.md`
- **备注**: 同步清理 memory 中旧的"起始值7"规范条目，保留最新的"起始10步长10"规范

---

## [2026-06-01 13:30] 修改 — powerbi_code_copilot 规范文件更新

- **模块**: 项目配置
- **任务**: powerbi_code_copilot 规范同步 — domain-rules.md 与 slicer-tips.md 内容更新
- **操作**: 修改
- **变更内容**:
  - `powerbi_code_copilot/rules/domain-rules.md`（修改）：
    排序字段规范由「起始值从7开始」修订为「起始值从10开始，步长用 10，便于后续插入」
  - `powerbi_code_copilot/knowledge/slicer-tips.md`（修改）：
    - 参数表通用字段模板 `{Entity}_Sort` 说明补充：步长不能为1，步长用 10
    - 平台切片器示例 `Platform_Sort` 值从 `{2, 3}` 更新为 `{50, 60}`
    - `DIM_ColMetric_Overview` 示例 `Metric_Sort` 从连续 `{1,2,...,12}` 更新为 `{20,30,40,...,130}`
    - `Metric_ColorDefault` 示例值从 `#5f6165`（深灰）更新为 `#212121`（近黑）
- **关联文件**: `powerbi_code_copilot/rules/domain-rules.md`, `powerbi_code_copilot/knowledge/slicer-tips.md`
- **备注**: 规范变更影响所有新建/存量方案中的排序字段值，存量方案（含 Media Mix v1.5）的 Metric_Sort / Indicator_Order 均已遵循新规（起始10，步长10），Metric_ColorDefault 待各方案下次迭代时同步更新为 #212121

---

## [2026-06-01 14:30] 修改 — Media Mix 矩阵方案 v1.6 Summary_Scope Bug 修复

- **模块**: Media Mix
- **任务**: Summary_Scope 格式 Bug 修复 — 统一 | 分隔符 + 嵌套 SUMMARY 展开为底层 DETAIL
- **操作**: 修改
- **变更内容**:
  - `Media_Mix_SQL`（修改）：所有 SUMMARY 行 Summary_Scope 字段修正，共两类问题：
    - **格式问题**：分隔符从 `+`（含空格）统一改为 `|`（无空格），与文档注释保持一致
    - **嵌套展开问题**：以下行原引用中间层 SUMMARY Channel_ID，改为直接枚举底层 DETAIL Channel_ID：
      - `TM_JCGP_TOTAL`：`TM_PXB_TOTAL + TM_PPTX` → `TM_PPZQ|TM_PPTX`
      - `TM_TOTAL`：`TM_RTB_TOTAL + TM_JCGP_TOTAL` → `TM_ZTC|TM_YLMF|TM_QZT|TM_DSP|TM_PPZQ|TM_PPTX`
      - `TM_TOTAL_EX_JCGP`：`TM_TOTAL - TM_JCGP_TOTAL` → `TM_ZTC|TM_YLMF|TM_QZT|TM_DSP`
      - `JD_RTB_TOTAL_INC_JXMP`：`JD_RTB_TOTAL + JD_JXMP` → `JD_QC|JD_CD|JD_HT|JD_ZT|JD_JXMP`
      - `JD_TOTAL`：`JD_RTB_TOTAL + JD_JCGP_TOTAL` → 15个底层DETAIL全枚举
      - `JD_TOTAL_EX_JCGP`：`JD_TOTAL - JD_JCGP_TOTAL` → `JD_QC|JD_CD|JD_HT|JD_ZT`
    - 文件头部注释补充 `Summary_Scope` 维护规则（格式要求 + 禁止引用 SUMMARY Channel_ID）
  - `Media_Mix_matrix_solution`（修改）：
    - 版本号 v1.5 → v1.6，变更摘要补充 Bug 修复说明
    - Section 1 字段说明：`Summary_Scope` 行补充展开规则和嵌套禁止说明，示例新增 JCGP Total / Total 的展开示例
    - Section 4.3 / 4.4：更新 SUMMARY 聚合描述，明确底层 DETAIL 限制
    - Section 5.1 度量值注释：`__ScopeIDs` 变量块补充 `⚠️` 约束说明
    - Section 9.1 SUMMARY 行聚合机制：补充三个展开示例（RTB Total / JCGP Total / Total）及 Bug 根因说明
- **关联文件**: `Media Mix/Media_Mix_SQL`, `Media Mix/Media_Mix_matrix_solution`
- **备注**: Bug 根因：DAX 中 `CONTAINSSTRING(__SummaryScope, Channel_ID) && Channel_Type="DETAIL"` 过滤逻辑正确，但 Summary_Scope 含 SUMMARY Channel_ID（如 `TM_RTB_TOTAL`）时，`Channel_Type="DETAIL"` 过滤器会将其排除，导致该 SUMMARY 行无法找到任何明细行，计算结果为 BLANK/0；修复方案：SQL 层将所有嵌套 SUMMARY 展开为底层 DETAIL，DAX 无需改动

---

## [Category Growth] 模块

---

## [2026-06-23 16:30] 新建 — Category Growth 品类增长矩阵方案 v1（表结构 + 24 度量值）

- **模块**: Category Growth
- **任务**: Category Growth 品类增长矩阵看板 v1 — 初始架构搭建，表结构 + 24 个度量值
- **操作**: 新建
- **变更内容**:
  - `Category_Growth_matrix_solution`（新建）：表结构方案，5 级行维度 + 11 列独立度量值
  - **行维度**（5 级，直接来自事实表字段，无需构建断开维度表）：framework → brand → category → channel → season
  - **视觉对象**：Table（非 Matrix），每列直接绑定一个独立度量值
  - **切片器**：复用 Overview 三个切片器，无专属切片器
    - Slicer_DataCaliber_Selection（trans_cycle 口径，单选）
    - Slicer_Currency_Selection（币种，单选，含 ExchangeRate/Symbol）
    - Slicer_Platform_Selection（平台，单选含 ALL，ALL → platform IN {"TM","JD"} 精确圈定）
  - **核心度量值**（11 个，按页面展示顺序）：
    - `Category Growth EOH(OMS)%`：占位=1（比率类，不乘汇率）
    - `Category Growth Active IDs`：占位=1（计数类，不乘汇率）
    - `Category Growth Active IDs VS LP`：占位=1（同比增长率，不乘汇率）
    - `Category Growth Net Sales%`：占位=1（比率类，不乘汇率）
    - `Category Growth SLS% VS LP`：占位=1（同比增长率，不乘汇率）
    - `Category Growth Cost`：SUM(promotion_cost_amt) × ExchangeRate（金额类，乘汇率）
    - `Category Growth Cost VS LP`：(本期 Cost - 同期 Cost) / 同期 Cost（同比增长率，不乘汇率）
    - `Category Growth Cost%`：DIVIDE(当前行 promotion_cost_amt, 总计 promotion_cost_amt)（比率类，不乘汇率；分母 REMOVEFILTERS 全部 5 个行维度）
    - `Category Growth Cost% VS LP`：(本期 Cost% - 同期 Cost%) / 同期 Cost%（同比增长率，不乘汇率）
    - `Category Growth ROI`：占位=1（比率类，不乘汇率）
    - `Category Growth ROI VS LP`：占位=1（同比增长率，不乘汇率）
  - **Display 格式化显示度量值**（11 个）：FORMAT 函数输出文本，对应 11 个核心度量值
    - 百分比类：0.0%;-0.0%;0.0%
    - 增长率百分比（带正负号）：+0.0%;-0.0%;0.0%
    - 金额类：#,##0.00;(#,##0.00);0.00（前置货币符号，由 Slicer_Currency_Selection[Currency_Symbol] 动态决定）
    - 整数类：#,##0;(#,##0);0
    - 小数类：#,##0.00;-#,##0.00;0.00
  - **辅助度量值**（2 个）：
    - `Category Growth Cell Font Color`：总计行 #252423（近黑，强调），其余 #5F6165（深灰）；ISINSCOPE 5 级判断
    - `Category Growth Cell Background Color`：5 级层次背景色（framework 行 + 总计行 #DBC6A8 深米色 / brand 小计行 #E6D9C7 中米色 / category 小计行 #F4ECE4 浅米色 / channel 小计行 #FAF6F1 淡米色 / season 明细行 #FFFFFF 白色）；SWITCH 自底向上判断
  - **同比机制**（5 个 VS LP 度量值）：
    - 本期 = Dim_Date_Current 关系自然筛选
    - 同期 = Dim_Date_Ly 断开维度，MIN/MAX 取范围，CALCULATE + REMOVEFILTERS(Dim_Date_Current) + FILTER(ALL(Dim_Date_Current)) 覆盖日期上下文
    - 增长率 = (本期 - 同期) / 同期
    - 边界：同期为 0/空 → BLANK；本期为 0/空且同期有值 → -1
  - **Display Folder 结构**：Category Growth / Category Growth > Display / Category Growth > Formatting
- **关联文件**: `Category Growth/Category_Growth_matrix_solution`
- **备注**:
  - 事实表：a05_e2e_paid_media_product_data_d（产品粒度）
  - 度量值总数：11 核心 + 11 Display + 2 辅助 = 24 个
  - 有口径指标 3 个（Cost / Cost VS LP / Cost% / Cost% VS LP），占位指标 7 个（EOH(OMS)% / Active IDs / Active IDs VS LP / Net Sales% / SLS% VS LP / ROI / ROI VS LP）
  - 汇率转换：仅 Cost（金额类）乘汇率；Cost% / Cost VS LP / Cost% VS LP（比率/增长率类）不乘汇率
  - Cost% 分母：REMOVEFILTERS 全部 5 个行维度（framework / brand / category / channel / season），保留切片器筛选
  - 行维度直接来自事实表字段，无需构建断开维度表
  - ISINSCOPE 替代 HASONEVALUE：支持 5 级行层级精确判断
  - 当前仅输出度量值，架构、概述等文字信息待逻辑确认后补充

---

## [2026-06-23 17:00] 新建 — Category Growth Diff 方案（行维度重排序 5→5 + 字段替换 framework→gender，7 项变更）

- **模块**: Category Growth
- **任务**: 新建 Category_Growth_matrix_Diff_solution — 派生自 Category_Growth_matrix_solution，行维度顺序从 framework→brand→category→channel→season 调整为 season→brand→category→channel→gender（移除 framework、新增 gender），全部度量值重命名为 Category Growth Diff 前缀
- **操作**: 新建
- **变更内容**:
  - `Category_Growth_matrix_Diff_solution`（新建）：派生自 Category_Growth_matrix_solution，7 项变更
  - **行维度变更**（变更 1）：
    - 原：framework → brand → category → channel → season（5 级）
    - 新：season → brand → category → channel → gender（5 级）
    - 移除 framework，新增 gender，season 由最深层提升为顶层
    - 中间层 brand / category / channel 顺序保持不变
  - **度量值命名重命名**：全部 24 个度量值前缀从 `Category Growth` 改为 `Category Growth Diff`
    - 核心：Category Growth Cost → Category Growth Diff Cost（11 个）
    - Display：Category Growth Cost Display → Category Growth Diff Cost Display（11 个）
    - 辅助：Category Growth Cell Font Color → Category Growth Diff Cell Font Color / Background Color（2 个）
    - Display Folder：Category Growth → Category Growth Diff / Category Growth > Display → Category Growth Diff > Display / Category Growth > Formatting → Category Growth Diff > Formatting
  - `Category Growth Diff Cost%`（变更 2，REMOVEFILTERS 字段替换）：
    - REMOVEFILTERS 字段集合变化：移除 framework，新增 gender
    - 5 个 REMOVEFILTERS：season / brand / category / channel / gender
  - `Category Growth Diff Cost% VS LP`（变更 3，引用名变更）：
    - 内部引用名从 [Category Growth Cost%] 改为 [Category Growth Diff Cost%]（2 处：本期 VAR + 同期 CALCULATE）
    - 原因：Cost% 的 REMOVEFILTERS 已从 framework 改为 gender（变更 2），Cost% VS LP 必须引用 Diff 版本的 Cost% 才能继承 gender 行维度逻辑，否则会引用原方案 Cost%（REMOVEFILTERS framework），导致 Cost% VS LP 计算错误
  - `Category Growth Diff Cell Font Color`（变更 4，ISINSCOPE 字段替换）：
    - ISINSCOPE 字段变化：移除 __IsFramework，新增 __IsGender
    - 总计行判断：NOT(__IsSeason) && NOT(__IsBrand) && NOT(__IsCategory) && NOT(__IsChannel) && NOT(__IsGender)
  - `Category Growth Diff Cell Background Color`（变更 5，层次映射调整）：
    - 维度顺序变化导致层次映射调整：
      - framework（原顶层 #DBC6A8 深米色）移除
      - gender（新最深层 #FFFFFF 白色）新增
      - season 由最深层（白色）提升为顶层（深米色）
      - 中间层 brand / category / channel 颜色不变
    - SWITCH 判断顺序：__IsGender（最深）→ __IsChannel → __IsCategory → __IsBrand → default（season + 总计行）
  - `Category Growth Diff Cost% Display`（变更 6，引用名变更）：
    - 引用名从 [Category Growth Cost%] 改为 [Category Growth Diff Cost%]
  - `Category Growth Diff Cost% VS LP Display`（变更 7，引用名变更）：
    - 引用名从 [Category Growth Cost% VS LP] 改为 [Category Growth Diff Cost% VS LP]
    - 原因：Cost% VS LP 的内部引用已改为 Diff 版本 Cost%（变更 3），Display 必须引用 Diff 版本的 Cost% VS LP 才能显示正确数值
  - **无差异度量值**（9 核心 + 9 Display + 0 辅助 = 18 个，仅命名前缀不同）：
    - EOH(OMS)% / Active IDs / Active IDs VS LP / Net Sales% / SLS% VS LP / Cost / Cost VS LP / ROI / ROI VS LP（9 核心，DAX 逻辑无变化）
    - 对应 9 个 Display 度量值（Cost% Display / Cost% VS LP Display 除外，已在变更 6/7 列出）
    - 以上度量值 DAX 逻辑与原方案完全一致，仅命名前缀和 Display Folder 不同
- **关联文件**: `Category Growth/Category_Growth_matrix_Diff_solution`
- **备注**:
  - 本方案为 Category_Growth_matrix_solution 的派生版本，适用于行维度以 season 为顶层、gender 为最深层、移除 framework 的业务场景
  - 与原方案的核心差异：行维度顺序、framework→gender 字段替换、度量值命名前缀
  - 切片器、筛选逻辑、汇率转换、同比机制、Display 格式字符串等与原方案完全一致
  - 废弃 Category_Growth_matrix_TA_solution（原仅顺序调整、无字段替换的版本），已删除
  - 引用链完整性：Cost% → Cost% VS LP → Cost% VS LP Display 三级引用链均已同步改为 Diff 版本，避免引用原方案度量值导致计算错误

---

## [2026-06-24 09:30] 新建 — Category Growth 数据库对账测试案例（framework→...→season + season→...→gender，4 指标 × 3 场景）

- **模块**: Category Growth
- **任务**: 新建两个测试文件，针对 Cost / Cost VS LP / Cost% / Cost% VS LP 四个指标，验证 Power BI 页面数据与数据库一致性
- **操作**: 新建
- **变更内容**:
  - `Category_Growth_matrix_test`（新建）：framework → brand → category → channel → season 方案的数据库对账测试案例
    - 测试指标：Cost / Cost VS LP / Cost% / Cost% VS LP（4 个）
    - 测试场景（2 个）：
      - 场景 1：总计行验证（对标 Power BI Table 总计行），2 步 SQL（本期总计 Cost + 同期总计 Cost）
      - 场景 2：四级小计行验证（framework='Acceleration' AND brand='M Polo' AND category='Outerwear' AND channel='触点'），4 步 SQL（本期当前行 Cost + 本期总计 Cost + 同期当前行 Cost + 同期总计 Cost）
    - SQL 风格：MySQL 分步查询，每个场景拆分为独立 SQL，不冗余合并
  - `Category_Growth_matrix_Diff_test`（新建）：season → brand → category → channel → gender 方案的数据库对账测试案例
    - 测试指标：Cost / Cost VS LP / Cost% / Cost% VS LP（4 个）
    - 测试场景（2 个）：
      - 场景 1：总计行验证（对标 Power BI Table 总计行），2 步 SQL（本期总计 Cost + 同期总计 Cost）
      - 场景 2：明细行验证（season IS NULL AND brand='M Polo' AND category='Outerwear' AND channel='关键词推广' AND gender='MN'），4 步 SQL（本期当前行 Cost + 本期总计 Cost + 同期当前行 Cost + 同期总计 Cost）
    - SQL 风格：MySQL 分步查询，每个场景拆分为独立 SQL，不冗余合并
  - **统一筛选条件**（两个文件共享）：
    - 本期时间：platform IN ('JD','TM') AND trans_cycle = 'T+1' AND data_date >= '2026-01-01' AND data_date <= '2026-06-09'
    - 同期时间：platform IN ('JD','TM') AND trans_cycle = 'T+1' AND data_date >= '2025-01-01' AND data_date <= '2025-06-09'
    - 数据库表：`indep_rl_ads`.a05_e2e_paid_media_product_data_d
    - 币种：RMB（ExchangeRate = 1）
  - **指标口径说明**（文件内注释）：
    - Cost = SUM(promotion_cost_amt) × ExchangeRate（金额类，乘汇率；RMB 下 = SUM 原始值）
    - Cost VS LP = (本期 Cost - 同期 Cost) / 同期 Cost（增长率，不乘汇率；边界：同期 0/NULL→BLANK，本期 0/NULL 且同期有值→-1）
    - Cost% = DIVIDE(当前行 promotion_cost_amt, 总计 promotion_cost_amt)（比率类，不乘汇率；分母 REMOVEFILTERS 全部 5 个行维度）
    - Cost% VS LP = (本期 Cost% - 同期 Cost%) / 同期 Cost%（增长率，不乘汇率；边界同 Cost VS LP）
  - **场景分配**（3 种场景对应 2 个文件）：
    - 总计行验证：两个文件均包含（共享场景）
    - 四级小计行验证：仅 Category_Growth_matrix_test（framework→...→season 方案）
    - 明细行验证：仅 Category_Growth_matrix_Diff_test（season→...→gender 方案）
- **关联文件**: `Category Growth/Category_Growth_matrix_test`, `Category Growth/Category_Growth_matrix_Diff_test`
- **备注**:
  - 仅测试 4 个指标（Cost / Cost VS LP / Cost% / Cost% VS LP），不涉及占位指标
  - SQL 采用分步查询设计，每个场景拆分为 2~4 个独立 SQL，便于手动逐步验证
  - 需求中"season→ brand→ category→ channel→ framework 明细行验证"的 framework 为 gender 笔误（验证条件使用 gender='MN'），实际为 season→ brand→ category→ channel→ gender
  - Cost% 分母验证：通过独立的"总计 Cost"SQL 查询实现 REMOVEFILTERS 语义（移除全部行维度，保留切片器筛选）
  - 手动计算公式在文件末尾 Step 中给出，可直接套用 SQL 结果计算 4 个指标值

---

## [2026-06-24 10:15] 修改 — Category Growth 测试案例场景2追加合并查询SQL

- **模块**: Category Growth
- **任务**: 两个测试文件场景2末尾追加合并后的 SQL，一次性输出 4 个指标最终值，免去手动除法
- **操作**: 修改
- **变更内容**:
  - `Category_Growth_matrix_test`（修改）：场景2（四级小计行验证）末尾新增 Step 6 合并查询
  - `Category_Growth_matrix_Diff_test`（修改）：场景2（明细行验证）末尾新增 Step 6 合并查询
  - 合并查询结构：WITH CTE（curr_row / curr_total / lp_row / lp_total 4 个子查询）+ SELECT 输出 4 列（Cost / Cost VS LP / Cost% / Cost% VS LP）
  - 边界条件用 CASE WHEN 实现，与 DAX 口径一致：
    - Cost VS LP：同期 Cost 为 0/NULL → NULL；本期 Cost 为 0/NULL 且同期有值 → -1
    - Cost%：分母(总计)为 0/NULL → NULL（DIVIDE 语义）
    - Cost% VS LP：同期 Cost% 为 0/NULL → NULL；本期 Cost% 为 0/NULL 且同期有值 → -1
- **关联文件**: `Category Growth/Category_Growth_matrix_test`, `Category Growth/Category_Growth_matrix_Diff_test`
- **备注**:
  - 合并查询直接输出 4 个指标的最终计算结果，无需手动套用除法公式
  - 4 个 CTE 分别对应 Step 1~4 的分步查询，逻辑完全等价，仅合并为单条 SQL 执行
  - 原 Step 1~5 分步查询保留，便于逐步排查；Step 6 合并查询用于一次性获取最终值

---

## [Keyword] 模块

---

## [2026-06-22 16:30] 修改 — Keyword 方案字段映射修正（crowed_* → season/category/brand）

- **模块**: Keyword
- **任务**: 三个 Keyword 方案文件字段映射全面修正 — DAX FILTER 块、SQL 注释、文档说明、TestSQL 切片器引用
- **操作**: 修改
- **变更内容**:
  - `Keyword_X_matrix_solution`（修改）：
    - **DAX FILTER 块**：`crowed_layer` → `season`、`crowed_name` → `category`、`crowed_type` → `brand`（全量替换，覆盖 9 个核心度量值 + Cost% 分母）
    - **架构图切片器描述**：从"基于 crowed_*"改为"事实表字段 season/category/brand"
    - **SQL 字段映射注释**：增加双模块映射说明（Crowd 模块用 crowed_*，Keyword X 模块用 season/category/brand）
    - **FILTER(VALUES()) 交集模式说明**：伪代码从 crowed_* 更新为 season/category/brand
    - **公共筛选逻辑注释**：同步更新
  - `Keyword_matrix_solution`（修改）：
    - **DAX FILTER 块**：`crowed_layer` → `season`、`crowed_type` → `brand`（分子 FILTER(VALUES()) + 分母 FILTER(ALL())）
    - **Table 行配置**：`crowed_name` → `keyword_type`
    - **Cost% 分母逻辑修正**：`FILTER(ALL(keyword_type))` 改为 `FILTER(ALL(category))`，因为 category 才是同时在行维度和切片器中的字段
    - **注释修正**：season 仅在切片器中、category 同时在行维度和切片器中、brand 仅在切片器中
  - `Keyword_X_matrix_solution_TestSQL`（修改）：
    - **参数区**：`KW Type/Plan` → `Category/Label`
    - **0.2 探查 SQL**：`keyword_type/plan_name` → `category/brand`
    - **PART 5 切片器模拟**：全部 `keyword_type` → `category`、`plan_name` → `brand`
    - **底部比对说明**：更新引用为 Category/Label
- **关联文件**: `Keyword/Keyword_X_matrix_solution`, `Keyword/Keyword_matrix_solution`, `Keyword/Keyword_X_matrix_solution_TestSQL`
- **备注**:
  - 字段映射规则：Super Season ← season、Category ← category、Label ← brand
  - Dim_Crowd_Season_C_Label SQL 保持不变（仍从 crowd 事实表 a05_e2e_paid_media_crowed_data_d 读取 crowed_layer/crowed_name/crowed_type）
  - Keyword 模块 DAX 中引用 keyword 事实表 a05_e2e_paid_media_keyword_data_d 时使用 season/category/brand
  - Keyword_matrix_solution Cost% 分母中发现并修复了逻辑错误：keyword_type 不是切片器维度，不应用 FILTER(ALL())

---

## [2026-06-22 14:30] 修改 — Keyword 方案切片器共享 + 命名前缀修正

- **模块**: Keyword
- **任务**: 三个专属切片器与 Crowd 模块共享 Dim_Crowd_Season_C_Label + 命名前缀规范化
- **操作**: 修改
- **变更内容**:
  - `Keyword_X_matrix_solution`（修改）：
    - **切片器引用**：从 Dim_Keyword_Season_Type_Plan 改为 Dim_Crowd_Season_C_Label（复用 Crowd）
    - **变量名**：`__SuperSeasonVals` / `__CategoryVals` / `__LabelVals`（与 Crowd 一致）
    - **命名前缀**：全部 20 个度量值前缀统一为 `Keyword X`
    - **Display Folder**：Keyword X / Keyword X > Display / Keyword X > Formatting
  - `Keyword_matrix_solution`（修改）：
    - **切片器引用**：同步改为 Dim_Crowd_Season_C_Label
    - **命名前缀**：从 `Keyword TA` 改为 `Keyword`
    - **Display Folder**：Keyword / Keyword > Display / Keyword > Formatting
  - `Keyword_X_matrix_solution_TestSQL`（新建）：
    - 数据验证测试 SQL，9 个 PART：数据探查 / 总计行 / channel 行 / channel+brand 行 / Cost%分母 / 切片器模拟 / 日期粒度 / 汇率转换 / 数据完整性
- **关联文件**: `Keyword/Keyword_X_matrix_solution`, `Keyword/Keyword_matrix_solution`, `Keyword/Keyword_X_matrix_solution_TestSQL`
- **备注**:
  - 切片器共享策略：Crowd 和 Keyword 两个模块共用同一张 Dim_Crowd_Season_C_Label 断开维度表
  - DAX 中 FILTER(VALUES()) 交集模式的字段名在两个模块中不同：Crowd 用 crowed_layer/crowed_name/crowed_type，Keyword 用 season/category/brand

---

## [2026-06-22 09:30] 新建 — Keyword X 完整方案 + Keyword 差异补丁方案

- **模块**: Keyword
- **任务**: 参考 Crowd_matrix_solution 和 Crowd_matrix_TA_solution，新建 Keyword 模块两个解决方案文件
- **操作**: 新建
- **变更内容**:
  - `Keyword_X_matrix_solution`（新建）：完整方案，10 个章节
    - **行维度**：5 级 channel → brand → framework → category → customer_type
    - **度量值**：20 个（9 核心 + 9 Display + 2 辅助）
    - **核心度量值**：Keyword X Cost（金额类×汇率）/ Cost%（REMOVEFILTERS 5 行维度 + FILTER(ALL())）/ ROI（占位=1）/ Click / CPC / CTR / CVR / Add to Cart / CPATC
    - **切片器**：复用 Overview 三个（Platform/DataCaliber/Currency）+ Dim_Crowd_Season_C_Label 三列同源多选级联
    - **辅助度量值**：Cell Font Color（总计行 #252423，其余 #5F6165）/ Cell Background Color（5 级层次 #dbc6a8/#e6d9c7/#f4ece4/#faf6f1/#ffffff）
    - **视觉对象**：Table（非 Matrix），5 行维度 + 9 度量值
  - `Keyword_matrix_solution`（新建）：差异补丁文件，仅记录与 Keyword_X 的差异
    - **行维度**：4 级 category → keyword_type → channel → keyword_name
    - **5 个变更**：行维度 5→4 重排序 / Cost% REMOVEFILTERS 4 字段 / Cell Font Color 4 级 / Cell Background Color 4 级 / Cost% Display 引用名
    - **其余 8 个核心度量值**：DAX 逻辑与 Keyword_X 完全一致（仅前缀不同）
- **关联文件**: `Keyword/Keyword_X_matrix_solution`, `Keyword/Keyword_matrix_solution`
- **备注**:
  - 参考来源：Crowd_matrix_solution（5 级行维度完整方案）+ Crowd_matrix_TA_solution（4 级行维度差异补丁）
  - 事实表：a05_e2e_paid_media_keyword_data_d（关键词粒度）
  - 无同比逻辑，不涉及 Dim_Date_Ly
  - Platform ALL 筛选遵循项目规范：FILTER platform IN {"TM","JD"}

---

## [Crowd] 模块

---

## [2026-06-17 18:00] 新建 — Crowd TA 方案（行维度重排 4 级 + 度量值重命名）

- **模块**: Crowd
- **任务**: 新建 Crowd_matrix_TA_solution — 基于 Crowd_matrix_solution v6 派生，行维度从 5 级调整为 4 级并重新排序，全部度量值重命名为 Crowd TA 前缀
- **操作**: 新建
- **变更内容**:
  - `Crowd_matrix_TA_solution`（新建）：派生自 Crowd_matrix_solution，核心 DAX 调整如下
  - **行维度变更**（Section 0 / 6.1）：
    - 原：channel → crowed_layer → crowed_name → crowed_type → customer_type（5 级）
    - 新：crowed_layer → channel → crowed_name → crowed_type（4 级）
    - 移除 customer_type 维度，crowed_layer 提升为顶层维度
  - **度量值命名重命名**：全部 20 个度量值前缀从 `Crowd` 改为 `Crowd TA`
    - 核心：Crowd Cost → Crowd TA Cost（9 个）
    - Display：Crowd Cost Display → Crowd TA Cost Display（9 个）
    - 辅助：Crowd Cell Font Color → Crowd TA Cell Font Color / Background Color（2 个）
    - Display Folder：Crowd → Crowd TA / Crowd > Display → Crowd TA > Display
  - `Crowd TA Cost%` REMOVEFILTERS 调整（Section 3.3）：
    - 移除 4 个行维度筛选（crowed_layer / channel / crowed_name / crowed_type）
    - 移除 customer_type 对应的 REMOVEFILTERS
  - `Crowd TA Cell Font Color`（Section 5.1）：
    - ISINSCOPE 从 5 级减为 4 级（移除 __IsCustomerType）
    - 总计行判断：NOT(Layer) && NOT(Channel) && NOT(Name) && NOT(Type)
  - `Crowd TA Cell Background Color`（Section 5.2）：
    - 从 5 级层次减为 4 级（移除 #FFFFFF 白色层）
    - crowed_layer 行 + 总计行 → #DBC6A8 / channel 行 → #E6D9C7 / crowed_name → #F4ECE4 / crowed_type → #FAF6F1
    - SWITCH 顺序调整：__IsType → __IsName → __IsChannel → default
  - **文档同步更新**（Section 7-10）：度量值清单、指标口径表、技术说明、验证清单全部同步为 4 级维度 + TA 命名
- **关联文件**: `Crowd/Crowd_matrix_TA_solution`
- **备注**:
  - 本方案为 Crowd_matrix_solution 的派生版本，适用于行维度以 crowed_layer 为顶层的业务场景
  - 与现方案的核心差异：行维度顺序、维度数量（4 vs 5）、度量值命名前缀
  - 切片器、筛选逻辑、汇率转换、Display 格式字符串等与现方案完全一致

---

## [2026-06-17 15:00] 修改 — Crowd 方案 v6 新增 CPATC 指标 + 行维度扩展 5 级 + 颜色体系重写

- **模块**: Crowd
- **任务**: Crowd_matrix_solution 五项重大变更：新增第 9 指标 CPATC / 行维度 2→5 / Cost% REMOVEFILTERS 扩展 / 字体颜色重写 / 背景颜色 5 级层次
- **操作**: 修改
- **变更内容**:
  - `Crowd CPATC`（新增，Section 3.10）：
    - 口径：DIVIDE(SUM(cost_amt), SUM(add_cart_cnt))，单次加购成本
    - 类型：比率类，不乘汇率
    - 格式字符串：`#,##0.00;-#,##0.00;0.00`
  - `Crowd CPATC Display`（新增，Section 4.9）：
    - FORMAT([Crowd CPATC], "#,##0.00;-#,##0.00;0.00")
  - **行维度扩展 2→5**（Section 0 / 6.1）：
    - 原：channel → crowed_layer（2 级）
    - 新：channel → crowed_layer → crowed_name → crowed_type → customer_type（5 级）
    - 行维度直接来自事实表字段，无需构建断开维度表
  - `Crowd Cost%` REMOVEFILTERS 扩展（Section 3.3）：
    - 分母移除全部 5 个行维度筛选（channel / crowed_layer / crowed_name / crowed_type / customer_type）
    - 原仅移除 2 个（channel / crowed_layer）
  - `Crowd Cell Font Color`（重写，Section 5.1）：
    - 总计行（所有 ISINSCOPE = FALSE）→ #252423（近黑，强调）
    - 所有小计行和明细行 → #5F6165（深灰）
    - 使用 ISINSCOPE 5 级判断（替代原 HASONEVALUE 2 级判断）
  - `Crowd Cell Background Color`（重写，Section 5.2）：
    - channel 行 + 总计行 → #dbc6a8（深米色）
    - crowed_layer 小计行 → #e6d9c7（中米色）
    - crowed_name 小计行 → #f4ece4（浅米色）
    - crowed_type 小计行 → #faf6f1（淡米色）
    - customer_type 明细行 → #ffffff（白色）
    - SWITCH 从最深层级开始判断（自底向上），保证匹配到最具体层级
  - **文档全面更新**（Section 7-10）：
    - Section 7 度量值清单：18 个 → 20 个（新增 CPATC #9 + CPATC Display #18，重编号至 #20）
    - Section 8 指标口径表：新增 #9 CPATC 行
    - Section 9.3：HASONEVALUE → ISINSCOPE（5 级行维度）
    - Section 9.5：Cost% 分母说明更新（REMOVEFILTERS 5 个行维度）
    - Section 10 验证清单：多项更新（Cost% 5 维度 / CPATC / 9 Display / 5 级背景色 / 5 行 + 9 值 Table）
- **关联文件**: `Crowd/Crowd_matrix_solution`
- **备注**:
  - 度量值总数：8 核心 + 9 Display + 2 辅助 + 1 字体颜色 = 20 个
  - ISINSCOPE 替代 HASONEVALUE：支持 5 级行层级精确判断，HASONEVALUE 仅能判断单值/多值，无法区分层级
  - CPATC 与 CPC 同类：比率型指标（分子分母同币种），不乘汇率
  - Table 视觉对象配置：5 行维度 + 9 度量值，条件格式绑定字体颜色 + 背景颜色度量值

---

## [2026-06-17 10:00] 新建 — Crowd 数据验证测试 SQL（Cost + Cost%）

- **模块**: Crowd
- **任务**: 新建 Crowd_matrix_solution_TestSQL — 验证数据库数据与 Power BI Crowd 表一致性
- **操作**: 新建
- **变更内容**:
  - `Crowd_matrix_solution_TestSQL`（新建）：数据验证测试 SQL 文件，对标 Crowd Cost / Crowd Cost% 的 DAX 计算口径
  - PART 0 — 数据探查：检查事实表平台/口径/人群维度分布、NULL 值分布、currency 字段值
  - PART 1 — 总计行验证：全平台 Cost 聚合 + Cost% = 100% 校验
  - PART 2 — channel 行验证（一级行头）：按 channel 聚合 Cost + Cost%，含 ALL / TM / JD 三种平台场景
  - PART 3 — channel + crowed_layer 明细行验证（二级行头）：最细粒度 Cost + Cost%，含 ALL / TM / JD 三种平台场景
  - PART 4 — Cost% 分母验证：确认 REMOVEFILTERS + FILTER(ALL()) 语义，分母始终为总计 Cost；含 Cost% 加和校验（SUM ≈ 100%）
  - PART 5 — 专属切片器筛选模拟：Super Season / Category / Label 单条件 + 组合条件筛选，含占位符供替换实际值
  - PART 6 — 日期粒度明细：按日 / 按日+平台 / 按日+平台+crowed_layer 三级展开，用于定位差异日期
  - PART 7 — 汇率转换验证：USD 场景 Cost × 汇率乘数，Cost% 不受汇率影响
  - PART 8 — 数据完整性检查：日期范围、trans_cycle 值、零值/空值占比、三层 Cost 一致性交叉校验
- **关联文件**: `Crowd/Crowd_matrix_solution_TestSQL`
- **备注**: 当前仅覆盖 Cost 和 Cost% 两个指标；测试时间段 2026-01-01 ~ 2026-06-17；SQL 对标 Crowd_matrix_solution v5 的 FILTER(VALUES()) 交集模式 + Cost% 分母 FILTER(ALL()) 逻辑

---

## [2026-06-16 20:00] 修改 — Crowd Cost% 分母 FILTER(VALUES()) → FILTER(ALL()) 修复

- **模块**: Crowd
- **任务**: Crowd Cost% 每行始终为 1 的 Bug 修复
- **操作**: 修改
- **变更内容**:
  - `Crowd Cost%`（DAX 修复）：
    - 分母 `__TotalCostAmt` 中 3 个 `FILTER(VALUES(...))` 改为 `FILTER(ALL(...))`
    - 移除 `__LayerFilter` / `__NameFilter` / `__TypeFilter` 三个变量（不能跨 CALCULATE 复用）
    - 分子 `__CostAmt` 保持 `FILTER(VALUES())` 交集模式（保留行维度）
    - 分母 `__TotalCostAmt` 改用 `FILTER(ALL())` 仅切片器模式（移除行维度后不回填）
  - 新增 Section 9.5「Cost% 分母：FILTER(VALUES()) vs FILTER(ALL())」技术说明
- **关联文件**: `Crowd/Crowd_matrix_solution`
- **根因**:
  - `FILTER(VALUES(列), 列 IN 切片器值)` 作为 VAR 定义时，在行上下文中求值
  - VALUES 返回当前行的值 → 固化为表变量 → 在 __TotalCostAmt 中重新施加
  - REMOVEFILTERS 被固化的变量抵消 → 分母 ≈ 分子 → Cost% ≈ 1
- **修复后行为**:
  - 分子：保留行维度（FILTER(VALUES()) 交集模式）
  - 分母：移除行维度 + 仅保留切片器（REMOVEFILTERS + FILTER(ALL())）
  - 总计行：Cost% = 100%（自身/自身）
  - 明细行：Cost% < 100%（各行花费/总花费）

---

## [2026-06-16 18:00] 回滚 — Crowd 方案 v6.2 紧急回滚至 v5 变量化版本

- **模块**: Crowd
- **任务**: v6.1 计算表方案语义错误紧急回滚
- **操作**: 回滚（v6.1 → v5）
- **变更内容**:
  - 8 个业务度量值全部回滚至 v5 变量化版本（恢复 6 个变量 + 5 个 FILTER 块内联）
  - 废弃对计算表 'Crowd Base Filter Context' 的引用
  - 同步清理文档：移除 Section 3.10、5.0、9.5-9.8、验证清单 22-40 等 v6.x 专章
  - 解决方案文件回归纯净状态：仅保留 v5 业务代码 + 指向 changelog.md 的版本索引
- **关联文件**: `Crowd/Crowd_matrix_solution`
- **回滚根因**: v6.1 使用 `ALL('Crowd Base Filter Context')` 作为 CALCULATE 筛选参数会**重置筛选上下文**，导致 8 个业务度量值完全不受切片器筛选影响（用户实测发现）
- **教训**:
  - 1. ALL('表名') 在 CALCULATE 中是"重置筛选"，不是"应用筛选"——语义反转
  - 2. 任何 DAX 重构方案必须经过 Power BI Desktop 实际验证，未经验证的方案不可交付
  - 3. 重构应小步快跑、逐步验证，避免一次性大跨度变更

---

## [2026-06-16 16:30] 废弃 — Crowd 方案 v6.1 计算表模式（语义错误，已回滚）

- **模块**: Crowd
- **任务**: 试图通过计算表封装公共筛选逻辑减少代码重复
- **操作**: 废弃（v6.1 → v6.2 紧急回滚）
- **变更内容**:
  - 新建计算表 `Crowd Base Filter Context`（CALCULATETABLE 返回筛选后的事实表）
  - 封装 v5 的 6 个变量 + 5 个 FILTER 块
  - 8 个业务度量值改为 `CALCULATE(..., ALL('Crowd Base Filter Context'))` 引用
- **严重错误**:
  - 现象：8 个业务度量值完全不受切片器筛选影响（始终显示全量数据）
  - 根本原因：`ALL('表名')` 在 CALCULATE 筛选参数位置会**移除该表上的所有筛选上下文**
  - 与设计意图"应用计算表封装的筛选"完全相反
- **关联文件**: `Crowd/Crowd_matrix_solution`
- **备注**:
  - 失误责任：AI 助手未在 Power BI Desktop 实际验证，直接交付方案
  - 辅助封装公共筛选的正确方法：GENERATE / TREATAS / 显式列出筛选条件，**不要**使用 ALL
  - v6.1 在 v6 失败后沿用错误引用方式，连续两次失误

---

## [2026-06-16 15:00] 废弃 — Crowd 方案 v6 度量值方案（语法错误，已被 v6.1 取代）

- **模块**: Crowd
- **任务**: 试图将公共筛选逻辑封装为单一度量值
- **操作**: 废弃（v6 → v6.1）
- **变更内容**:
  - 试图创建度量值 `Crowd Base Filter Context` 封装公共筛选
  - 度量值内部使用 `CALCULATETABLE(...)` 返回筛选后的事实表
- **错误**:
  - 现象：DAX 编译报错"该表达式引用多列。多列不能转换为标量值"
  - 根本原因：CALCULATETABLE 返回多列表，度量值必须返回标量值
- **关联文件**: `Crowd/Crowd_matrix_solution`
- **备注**:
  - 度量值只能返回标量值，多列表应使用计算表（但计算表的引用方式仍需正确，见 v6.1 失败记录）
  - v6 失败后试图通过 v6.1 改为计算表，但引用方式继续错误

---

## [2026-06-16 11:30] 修改 — Crowd 方案 v5 DAX 变量化优化（方案 A + 方案 B）

- **模块**: Crowd
- **任务**: Crowd 方案 DAX 性能与可读性优化 — 变量化公共筛选模式
- **操作**: 修改
- **变更内容**:
  - `Crowd Cost`（DAX 优化，v5）：
    - 方案 A — 新增 3 个变量：`__SuperSeasonVals` / `__CategoryVals` / __LabelVals（VALUES(Dim_Crowd_Season_C_Label[...]) 提取）
    - 方案 B — 新增 1 个变量：`__PlatformFilter`（FILTER(ALL(platform), IF(...)) 整段提取）
    - 废弃变量：`__IsAllPlatform`（逻辑内联到 `__PlatformFilter` 中）
    - 净收益：代码量 -42%，切片器字段引用 24 处 → 8 处
  - `Crowd Cost%`（DAX 优化，v5）：
    - 同上 4 个变量；特别地，`__PlatformFilter` 在 `__CostAmt` / `__TotalCostAmt` 两个 CALCULATE 中复用
    - v4 构造次数：2 次 Platform FILTER + 6 次专属 FILTER → v5：1 次 Platform FILTER + 6 次专属 FILTER
  - `Crowd CPC` / `Crowd CTR` / `Crowd CVR`（DAX 优化，v5）：
    - 同上 4 个变量；`__PlatformFilter` 在两个 CALCULATE 中复用
    - 节省 1 次 Platform FILTER 表构造
  - `Crowd Click` / `Crowd Add to Cart`（DAX 优化，v5）：
    - 同上 4 个变量；单 CALCULATE 度量值
  - `Crowd ROI`（占位度量值）：
    - 头部注释追加「变更: v5 添加变更标记」标识
  - 文档更新：
    - `Crowd_matrix_solution` Section 3.1 公共筛选逻辑说明：重写为 v5 变量化版本
    - 新增 Section 9.5「v5 变量化优化技术说明」（6 个子节：动机 / 方案 / 收益分析 / 不变量化的原因）
    - Section 10 验证清单追加 5 项 v5 专项验证（数值等价性、变量定义、废弃变量、双 CALCULATE 复用、DAX 编译）
    - 文件头版本：v4 → v5
- **关联文件**: `Crowd/Crowd_matrix_solution`
- **备注**:
  - 行为完全等价：所有筛选语义与 v4 一致，仅 DAX 写法变更
  - 性能预估：≤ 10% 提升（DAX 引擎对 VALUES(同列) 内部已去重缓存，主要收益是可读性）
  - 方案 C（FILTER(VALUES(...)) 块变量化）暂不采纳，存在上下文继承风险，留作 v6 优化方向
  - 8 个 Display 度量值无需修改（仅引用基础度量值）

---

## [2026-06-12 15:35] 新建 — Crowd 人群粒度矩阵方案

- **模块**: Crowd
- **任务**: Crowd 人群粒度矩阵看板 — 初始架构搭建
- **操作**: 新建
- **变更内容**:
  - `DIM_ColMetric_Crowd`：新建列维度表（断开维度），8 列指标（Cost / Cost% / ROI / Click / CPC / CTR / CVR / Add to Cart），内嵌格式与颜色定义；`Metric_Sort` 起始值 = 10，步长 = 10（遵循 domain-rules 规范）；`Metric_ColorDefault` = `#5f6165`
  - `Slicer_Super_Season_Selection`：新建 Super Season 参数表（断开维度，单选含 ALL），基于事实表 `crowed_layer` 字段；ALL 选项表示全选（不施加 crowed_layer 筛选）；默认选中 ALL
  - `Slicer_Category_Selection`：新建 Category 参数表（断开维度，单选含 ALL），基于事实表 `crowed_type` 字段；ALL 选项表示全选（不施加 crowed_type 筛选）；默认选中 ALL
  - `Slicer_Label_Selection`：新建 Label 参数表（断开维度，单选含 ALL），基于事实表 `crowed_name` 字段；ALL 选项表示全选（不施加 crowed_name 筛选）；默认选中 ALL
  - `Crowd Base Value`：新建纯指标 SWITCH 分发度量值（8 分支）
    - ID 1 Cost：有口径，SUM(a05_e2e_paid_media_crowed_data_d[cost_amt])
    - ID 2 Cost%：有口径，DIVIDE(SUM(cost_amt), SUM(sales_amt))
    - ID 3~8：占位值 = 1，保留口径注释供后续填充
    - 含 Platform 单选/ALL 筛选（复用 Slicer_Platform_Selection，ALL → FILTER platform IN {"TM","JD"}）
    - 含 trans_cycle 筛选（复用 Slicer_DataCaliber_Selection）
    - 含 crowed_layer / crowed_type / crowed_name 专属切片器筛选（ALL 时不施加对应字段筛选）
  - `Crowd Cell Value`：新建单元格值度量值，无 This Year/Last Year/YOY 行路由（本模块无同比逻辑），金额类指标乘以 Currency_ExchangeRate 汇率
  - `Crowd Cell Display`：新建格式化显示度量值，支持 currency / integer / decimal_2 / percent_1dp 四种格式
  - `Crowd Cell Font Color`：新建字体颜色度量值，统一返回 `#5f6165` 深灰色（本模块无 YOY 条件色）
  - `Crowd Cell Background Color`：新建行背景色度量值，channel 行/总计行 → `#f8f5f1`（浅米色），crowed_layer 明细行 → `#ffffff`（白色）；通过 `HASONEVALUE(crowed_layer)` 判断行类型
- **关联文件**: `Crowd/Crowd_matrix_solution`
- **备注**:
  - 行维度直接来自事实表字段（channel + crowed_layer），无需构建断开维度表
  - 三个专属切片器（Super Season / Category / Label）仅影响 Crowd 模块，不与其他模块共享
  - 当前专属切片器参数表仅含 ALL + 一个占位值，建议后续通过 Power Query 动态提取 DISTINCT 值
  - 无同比逻辑，不涉及 Dim_Date_Ly
  - 复用切片器：Slicer_Platform_Selection / Slicer_DataCaliber_Selection / Slicer_Currency_Selection（复用 Overview 方案）

---

## [2026-06-12 16:20] 修改 — Crowd 方案 v2 架构调整（SWITCH→独立度量 + SQL动态切片器 + Table视觉对象）

- **模块**: Crowd
- **任务**: Crowd 方案架构调整 — 适配 Table 视觉对象
- **操作**: 修改
- **变更内容**:
  - `Crowd_matrix_solution`（修改）：
    - **架构调整**：度量值从 SWITCH 分发改为 8 个独立度量值（Crowd Cost / Crowd Cost% / Crowd ROI / Crowd Click / Crowd CPC / Crowd CTR / Crowd CVR / Crowd Add to Cart）
      原因：行维度直接来自事实表字段，无自定义结构，不采用 Matrix，改用 Table 视觉对象
    - **废弃**：Crowd Base Value / Crowd Cell Value / Crowd Cell Display / DIM_ColMetric_Crowd 列维度表
    - **视觉对象**：从 Matrix 改为 Table，每列直接绑定一个独立度量值
    - **专属切片器**：从 DAX DATATABLE 改为 SQL 动态查询，从数据源获取 DISTINCT 值并加入 ALL 行
      - Slicer_Super_Season_Selection：SQL 基于 crowed_layer，ALL=10，其余按字母排序
      - Slicer_Category_Selection：SQL 基于 crowed_type，排序 = SuperSeason_Sort*1000 + 字母序（体现层级分组）
      - Slicer_Label_Selection：SQL 基于 crowed_name，排序 = Category_Sort*1000 + 字母序（体现层级分组）
    - **指标口径更新**：Click / CPC / CTR / CVR / Add to Cart 从占位值=1 更新为实际口径（基于数据字典字段）
    - 版本号 v1 → v2
- **关联文件**: `Crowd/Crowd_matrix_solution`
- **备注**:
  - SQL 切片器字段命名为 Super Season / Category / Label，便于后续直接替换表字段上线
  - 层级排序规则：Super Season 按字母；Category = SuperSeason_Sort*1000 + 字母序；Label = Category_Sort*1000 + 字母序
  - ROI 指标仍为占位值=1，待确认口径

---

## [2026-06-12 16:50] 修改 — Crowd 方案 v4（专属切片器改为多选，移除 ALL 逻辑）

- **模块**: Crowd
- **任务**: Crowd 方案 v5 — Cost%口径修正 + 中文名/数据字典注释 + FILTER(VALUES())交集模式
- **操作**: 修改
- **变更内容**:
  - `Crowd_matrix_solution`（修改）：
    - **切片器多选化**：Slicer_Crowd_Selection 三个切片器从单选改为多选
      - SQL 移除所有 ALL 相关 UNION ALL 行，简化为纯 DISTINCT 查询
      - DAX 废弃 SELECTEDVALUE + IF(<> "ALL") 模式，改用多列 TREATAS(VALUES(表)) 元组筛选
      - 多选模式下"全选"= 选中所有项，无需 ALL 占位值
    - **多列 TREATAS**：三个独立 TREATAS 合并为一个多列 TREATAS
      - TREATAS(VALUES(Slicer_Crowd_Selection), 事实表[crowed_layer], 事实表[crowed_name], 事实表[crowed_type])
      - 按元组组合筛选，不产生幽灵组合，语义与同源级联切片器天然对齐
      - 代码更简洁（一行替代三行）
    - **表名修正**：Slicer_Crowd_Selection → Dim_Crowd_Season_C_Label（与实际 Power BI 表名一致）
    - **Platform 筛选修正**：IF 直接返回列筛选表达式改为 FILTER(ALL(table[platform]), IF(...)) 模式
      解决 DAX 中 IF 返回列筛选表达式时无法解析列名的问题
    - **Cost% 口径修正**：从 DIVIDE(cost_amt, sales_amt) 改为 DIVIDE(当前行 cost_amt, 总计 cost_amt)
      分母使用 REMOVEFILTERS(channel, crowed_layer) 移除行维度筛选，保留切片器筛选
      Cost% 语义：每行花费占总计花费的百分比
    - **中文名称 + 数据字典注释**：所有 8 个度量值及 8 个 Display 度量值添加中文名称和数据字典字段注释
      Cost=花费(cost_amt), Cost%=花费占比, ROI=投资回报率, Click=点击量(click),
      CPC=单次点击成本(cost_amt,click), CTR=点击率(click,pv), CVR=转化率(sales_order_cnt,click),
      Add to Cart=总加购数(add_cart_cnt)
    - **筛选模式修正**：IN + VALUES 覆盖模式改为 FILTER(VALUES()) 交集模式
      原因：行维度（crowed_layer / crowed_name / crowed_type）来自事实表字段
      CALCULATE 筛选参数会覆盖同一列的外部筛选上下文
      直接用 "列 IN VALUES(切片器)" 会覆盖行维度筛选，导致每行显示总计值
      FILTER(VALUES(事实表列), 列 IN VALUES(切片器列)) 先读取当前行维度值，再与切片器取交集
      全选时：交集 = 行维度值 → 等价于仅行维度筛选
      部分选择时：交集 = 行维度值 ∩ 选中值
    - 版本号 v4 → v5
- **关联文件**: `Crowd/Crowd_matrix_solution`
- **备注**:
  - FILTER(VALUES()) 是行维度来自事实表时的标准断开维度筛选模式
  - 全选时交集 = 行维度值，等价于仅行维度筛选

---

## [2026-06-12 17:00] 修改 — Crowd 方案 v3（级联切片器 + CPC逻辑修正 + Display度量值）

- **模块**: Crowd
- **任务**: Crowd 方案 v3 — 切片器级联 + 度量值逻辑修正 + Display 格式化
- **操作**: 修改
- **变更内容**:
  - `Crowd_matrix_solution`（修改）：
    - **切片器重构**：3 个独立 SQL 表合并为单一 Slicer_Crowd_Selection（三列同源），Power BI 同表列自动交叉筛选实现级联
      - 废弃 Slicer_Super_Season_Selection / Slicer_Category_Selection / Slicer_Label_Selection 三表
      - 废弃排序字段（筛选器不关注排序）
      - SQL 补充 ALL 行：每列 ALL 值关联所有其他列组合，确保选 ALL 时子级切片器显示全部值
    - **CPC 逻辑修正**：移除汇率乘法，CPC = DIVIDE(cost_amt, click) 为比率型指标，不乘汇率
      仅 Cost（纯金额）需要乘汇率
    - **新增 8 个 Display 格式化显示度量值**：FORMAT 函数输出文本，明确数据类型与格式字符串
      - Cost: "#,##0.00;(#,##0.00);0.00"（金额，负数括号）
      - Cost%: "0.0%;-0.0%;0.0%"（百分比一位小数）
      - ROI: "#,##0.00;-#,##0.00;0.00"（小数两位，正负号）
      - Click: "#,##0;(#,##0);0"（整数）
      - CPC: "#,##0.00;-#,##0.00;0.00"（小数两位）
      - CTR: "0.0%;-0.0%;0.0%"（百分比一位小数）
      - CVR: "0.0%;-0.0%;0.0%"（百分比一位小数）
      - Add to Cart: "#,##0;(#,##0);0"（整数）
    - **HASONEVALUE 函数说明**：5.2 节补充函数语法、行为详解、等价写法、本场景应用
    - 版本号 v2 → v3
- **关联文件**: `Crowd/Crowd_matrix_solution`
- **备注**:
  - Display 度量值返回文本类型，用于需要格式化文本输出的场景；Table 视觉对象中可直接在度量值属性设置格式字符串
  - CPC 不乘汇率的理由：分子分母同币种，比值无币种维度，除完再乘汇率会改变比率数值

---
