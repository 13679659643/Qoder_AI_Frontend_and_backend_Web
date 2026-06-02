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

## [⚠️ 请补填具体时间 2026-06-01 HH:MM] 修改 — Media Mix 矩阵方案 v1.8.2 冗余变量清除 + 关联字段规范修正

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

## [⚠️ 请补填具体时间 2026-06-01 HH:MM] 修改 — Media Mix 矩阵方案 v1.8.1 Background Color 刻度修正 + SQL 排序冲突修复 + 数据诊断

- **模块**: Media Mix
- **任务**: 三项独立修复：交替行背景色计算错误 / Channel_Label 重名导致排序冲突 / 仅超级短视频有cost值的原因诊断
- **操作**: 修改
- **变更内容**:
  - `Media Mix Cell Background Color`（DAX 修复）：
    - Indicator Order 刻度从 1/2/3 升级为 10/20/30 后，`MOD(__EffRowID, 2)` 失效  
      修复：新增 `VAR __RowPos = INT(__EffRowID / 10)` 还原行位次，改用 `MOD(__RowPos, 2)` 判断  
      10→1（This Year=白）、20→2（Last Year=灰）、30→3（YOY=白）
  - `Media_Mix_SQL`（排序冲突修复，v1.8.1）：
    - Power BI Sort-by-Column 要求 Channel_Label 与 Platform_Sort 1:1 映射  
      "RTB Total" / "JCGP Total" / "Total" / "Total 不含JCGP" 同时出现在 TM（Sort=1）和 JD（Sort=2）导致报错  
      JD 内两个"品牌动态秀"（JD_PPDTX_1 / JD_PPDTX_2）也重名  
      修复：JD 侧重名 Channel_Label 末尾追加全角空格（U+3000），视觉无差异但字符串唯一：  
      `'RTB Total　'` / `'JCGP Total　'` / `'Total　'` / `'Total 不含JCGP　'` / `'品牌动态秀　'`（第二个）  
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
  - JD Channel_Label 加全角空格后，若事实表 channel 字段存的是 Channel_Label 原值（无后缀），  
    则 `channel IN __Labels` 仍能正常匹配（因为 __Labels 来自 Dim_Media_Mix_Channel，会随维度表刷新而更新）  
    但需确认：事实表 [channel] 的值 **不包含** 全角空格后缀（即仍为原始中文名）  
    → 若事实表数据是原始渠道名，则无需改事实表；若事实表数据和维度表同源，需排查
  - 诊断步骤详见 `Media_Mix_matrix_solution` Section 9.5

---

## [⚠️ 请补填具体时间 2026-06-01 HH:MM] 修改 — Media Mix 矩阵方案 v1.8 DAX 语法修复 + Cost% 口径修正 + SQL 结构升级

- **模块**: Media Mix
- **任务**: v1.7 遗留问题修复 — IF()无法返回表 + DETAIL行Summary_Scope为空 + Cost%分母口径错误
- **操作**: 修改
- **变更内容**:
  - `Media_Mix_SQL`（结构升级）：
    - **DETAIL 行 Summary_Scope**：从 `NULL` 改为自身 `Channel_ID`（如 `'TM_ZTC'`）  
      使 DAX 中 CONTAINSSTRING 在 DETAIL 行也能命中自己，无需 IF 分支
    - **新增 `Parent_Channel_ID` 字段**：标识每行 Cost% 分母所属的 SUMMARY 行  
      DETAIL 行 → 所属最近上级 SUMMARY（如 TM_ZTC → TM_RTB_TOTAL）  
      SUMMARY 行 → 自身（如 TM_RTB_TOTAL → TM_RTB_TOTAL，Cost%=100%）
    - 全部 31 行数据已同步更新
  - `Media Mix Base Value`（DAX 语法修复 + 口径重写）：
    - **__Labels 变量**：去掉 `IF()` 包裹（DAX 中 IF 无法返回表），改为统一 `SELECTCOLUMNS(FILTER(...))`  
      因 DETAIL 行 Summary_Scope 现为自身 Channel_ID，CONTAINSSTRING 自然命中
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

## [⚠️ 请补填具体时间 2026-06-01 HH:MM] 修改 — Media Mix 矩阵方案 v1.7 架构重大修复

- **模块**: Media Mix
- **任务**: Media Mix Base Value 架构重大问题修复 — ALL(事实表) 日期筛选失效 + DETAIL/SUMMARY路径合并 + CONTAINSSTRING 精确匹配
- **操作**: 修改
- **变更内容**:
  - `Media Mix Base Value`（架构重写）：
    - **[致命修复]** 移除 `FILTER(ALL(a05_e2e_paid_media_channel_data_d), ...)` 滥用  
      原方案 `ALL(事实表)` 清空了通过 `Dim_Date_Current` 关系传递的 `data_date` 筛选，  
      导致：① 用户切换日期切片器时矩阵数据不变；  
      ② Cell Value 层 LP 日期覆盖失效 → Last Year ≡ This Year → YOY ≡ 0  
      修正为 CALCULATE + 列级条件过滤（`[channel] IN __Labels, [platform]=..., [trans_cycle]=...`），  
      日期上下文由 `Dim_Date_Current` 关系自然传递，不在度量值中显式管理
    - **[设计加固]** CONTAINSSTRING 边界包裹：  
      `CONTAINSSTRING("|" & __SummaryScope & "|", "|" & Channel_ID & "|")`  
      防止子串误匹配（如 Channel_ID="TM_Z" 误命中 "TM_ZTC|TM_YLMF"）
    - **[架构精简]** DETAIL / SUMMARY 路径合并为统一 `channel IN __Labels`：  
      DETAIL 行 `__Labels = ROW("@Label", __ChannelLabel)`（单元素）  
      SUMMARY 行 `__Labels = SELECTCOLUMNS(FILTER(...))`（多元素）  
      13 个指标共用同一 `__Labels`，代码量减半；废弃 `__IsDetail`/`__IsSummary`/`__Cost_Detail`/`__Cost_Summary` 分支
    - **[性能优化]** `__Labels` 用 `IF(__ChannelType = "SUMMARY", ...)` 延迟计算，  
      DETAIL 行直接 ROW 构造，不扫描 `Dim_Media_Mix_Channel`
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
  - `DIM_ColMetric_Media_Mix`（DATATABLE Metric_Sort 字段修正）：  
    原值 `1,2,3...13` 违反 domain-rule「排序字段起始值从7开始」  
    修正为 `7,8,9,10,11,12,13,14,15,16,17,18,19`（起始 7，步长 1）
  - `Section 4.2 断开维度列表`（修正）：  
    移除 `Slicer_Platform_Selection` 条目（v1.1 已废弃）；补充注释说明 Platform 筛选通过 `Dim_Media_Mix_Channel[Platform]` 直接切片器实现
  - `Section 9.2 平台筛选技术说明`（修正）：  
    移除旧方案描述（辅助度量值 + 视觉层筛选器）；改写为 v1.1 正确方案（直接切片器方案）
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
  - `DIM_ColMetric_Media_Mix`（DATATABLE 颜色列修正）：  
    将 Cost / Cost% / CPC / CPATC 四个指标的 `Metric_ColorPositive` 从 `#D64550`（红）改回 `#1A9018`（绿），  
    `Metric_ColorNegative` 从 `#1A9018`（绿）改回 `#D64550`（红）；  
    所有 13 个指标颜色规则统一：正值（>0）= 绿色，负值（<0）= 红色，零值 = 黄色
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
  - `DIM_RowKPIs_Media_Mix`（Indicator Order 字段修正）：  
    `1, 2, 3` → `7, 17, 27`（起始7，步长10，便于后续在行间插入新类型）
  - `DIM_ColMetric_Media_Mix`（Metric_Sort 字段修正）：  
    `7, 8, 9, ..., 19`（步长1）→ `7, 17, 27, 37, 47, 57, 67, 77, 87, 97, 107, 117, 127`（步长10）  
    起始值 7 保持不变（符合 domain-rule），步长从 1 改为 10
  - `Media_Mix_matrix_solution` 文件头部日志清理：  
    移除文件内全量历史变更日志，只保留最新版本摘要（v1.4）；  
    历史详细记录统一归档至 `changelog.md`
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
  - `domain-rules.md`（用户已直接修改）：  
    `起始值从7开始` → `起始值从10开始，步长用 10，便于后续插入`
  - `DIM_RowKPIs_Media_Mix`（Indicator Order 修正）：  
    `7, 17, 27` → `10, 20, 30`
  - `DIM_ColMetric_Media_Mix`（Metric_Sort 修正）：  
    `7, 17, 27, ..., 127` → `10, 20, 30, 40, 50, 60, 70, 80, 90, 100, 110, 120, 130`
  - `Media_Mix_matrix_solution` 文件头版本摘要更新至 v1.5
- **关联文件**: `Media Mix/Media_Mix_matrix_solution`, `powerbi_code_copilot/rules/domain-rules.md`
- **备注**: 同步清理 memory 中旧的"起始值7"规范条目，保留最新的"起始10步长10"规范

---

## [⚠️ 请补填具体时间 2026-06-01 13:30] 修改 — powerbi_code_copilot 规范文件更新

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

## [⚠️ 请补填具体时间 2026-06-01 14:30] 修改 — Media Mix 矩阵方案 v1.6 Summary_Scope Bug 修复

- **模块**: Media Mix
- **任务**: Summary_Scope 格式 Bug 修复 — 统一 | 分隔符 + 嵌套 SUMMARY 展开为底层 DETAIL
- **操作**: 修改
- **变更内容**:
  - `Media_Mix_SQL`（修改）：所有 SUMMARY 行 Summary_Scope 字段修正，共两类问题：
    - **格式问题**：分隔符从 ` + `（含空格）统一改为 `|`（无空格），与文档注释保持一致
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

> 暂无变更记录

---

## [Keyword] 模块

> 暂无变更记录

---

## [Crowd] 模块

> 暂无变更记录
