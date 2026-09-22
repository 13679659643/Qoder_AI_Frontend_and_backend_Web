# 变更日志 — RL E2E CustomerBOS Dashboard

> 本文件记录 RL E2ECustomer Dashboard 看板的代码创建与修改历史。
> 看板模块：Customer · Member · VICPerformance by Merchandis
> 口径文档：

---

## 模块索引

## [ Customer ] 模块

## [Member] 模块

## [VIC] 模块

## [2026-08-12 17:30] DAX — VIC KPI 矩阵 SWITCH 路由解决方案（列指标维度表 + DAX 度量值链）

- **模块**: VIC
- **任务**: 基于 VIC KPI 口径文档输出列指标维度表与矩阵解决方案
- **操作**: 新建
- **变更内容**:
  - 新建 `Dim_ColMetric_VIC_KPIs` 列指标维度表（5 个 KPI 分组共 28 列指标）
    - 分组 1: VIC No.（5 列：Act / vs LY / vs LP / Monthly TAR / Yearly TAR）
    - 分组 2: VIC Retention%（4 列：Act / vs LY / vs LP / TAR ACH%）
    - 分组 3: T4-5 Upgrade No.（7 列：Act / vs LY / vs LP / TAR ACH% / Share / Share vs LY / Share vs LP）
    - 分组 4: Retention VIC No.（6 列：Act / vs LY / vs LP / Share / Share vs LY / Share vs LP）
    - 分组 5: Direct VIC No.（6 列：Act / vs LY / vs LP / Share / Share vs LY / Share vs LP）
    - 仅保留单一 `Metric_Format` 字段（严格遵循口径文档数据类型）
    - 颜色规则通过 `Metric_ColorRule` 字段三值标识（fixed_black / pos_neg_zero / fixed_default）
  - 新建 8 个 DAX 度量值（Display Folder: Base Metrics / Cell Values / Formatting）
    - `VIC KPIs Act Base Value` — 本期基础值（end period 当月 DISTINCTCOUNT）
    - `VIC KPIs LY Base Value` — 去年同期基础值（财历映射 Last_Fiscal_Month_*_LY）
    - `VIC KPIs LP Base Value` — 上期基础值（财历映射 Last_Fiscal_Month_*_LP）
    - `VIC KPIs Base Value` — 总路由（含 vs LY / vs LP / TAR ACH% / Share 派生 + REMOVEFILTERS）
    - `VIC KPIs Cell Value` — 对外值 = Base Value
    - `VIC KPIs Cell Display` — 格式化显示（按 Metric_Format 单字段分发，含扩展格式）
    - `VIC KPIs Cell Font Color` — 字体颜色（按 Metric_ColorRule 分发）
    - `VIC KPIs Cell Background Color` — 背景色（KPIGroup 行 vs KPI 行）
- **关联文件**:
  - `VIC/VIC KPI/Dim_ColMetric_VIC_KPIs.md`
  - `VIC/VIC KPI/VIC_KPIs_Table.md`
  - 口径来源: `口径文档/VIC KPI.md`
  - 参考实现: `RL E2E BOSS Dashboard/Performance by Merchandise/PB_Merchandise_Fulfillment_detail_ms.md`
- **备注**:
  - end period 时间范围使用 Slicer_Time_Frame_Max 内置的 Last_Fiscal_Month 系列字段（含 LY/LP）
  - is_member 默认 0（TTL VIC），is_employee 默认 1（Yes）
  - TAR ACH% 指标占位值 1，待逻辑确认后填充
  - Retention VIC No. vs LY 使用 percent_1dp_nosign 格式（严格遵循口径文档 4.1）
  - 行维度直接拉取事实表字段（platform / shop_info_id），DAX 无需显式处理

---

## [2026-08-12 18:10] DAX — VIC KPI 矩阵解决方案修订（格式字段精简 + Rolling 12 分母重写）

- **模块**: VIC
- **任务**: 根据用户第二轮反馈调整 Dim_ColMetric_VIC_KPIs 与 VIC_KPIs_Table
- **操作**: 修改
- **变更内容**:
  - **Dim_ColMetric_VIC_KPIs 调整（格式字段精简）**:
    - 移除 `percent_1dp_signed` / `percent_1dp_nosign` 两个格式
    - 所有"不含正号的百分比"统一为 `percent_1dp`（格式串 `#,##0.0%`）
    - 所有"含正号的百分比变化"统一为 `delta_pct_1dp`（格式串 `IF(__Value>0,"+","") & FORMAT(__Value,"#,##0.0%")`）
    - TAR ACH% 类指标（Metric_ID 4/5/9/13）格式从 `percent_1dp_signed` 调整为 `percent_1dp`（不含正号）
    - Retention VIC No. vs LY（Metric_ID 18）格式从 `percent_1dp_nosign` 调整为 `percent_1dp`
    - 维度表头部注释新增格式取值对应关系说明，并明确"不存在 percent_1dp_signed / percent_1dp_nosign"
  - **VIC_KPIs_Table 调整（Rolling 12 个财月分母重写）**:
    - 纠正 VIC Retention% 分母逻辑：Rolling 12 个财月 = 当前月 + 往前 11 个月，共 12 个月的 `count(distinct user_id)` 区间 DISTINCT 汇总（同一用户只计一次，非按月 SUM 累加）
    - 仅 VIC Retention% 分组（Metric_ID 6/7/8）的分母使用此 Rolling 12 区间；Share 类指标分母仍为 end period 当月 is_vic=1
    - 新增 3 个独立度量值 `VIC KPIs Rolling12 VIC Denominator Act / LY / LP`（Display Folder: Base Metrics）
    - Rolling 12 区间起始日获取：`EDATE(Last_Fiscal_Month_Min, -11)` 得到起始月，再用该月作为 `TimeFrame_Value` 去 `Slicer_Time_Frame_Max` 中匹配查找 `TimeFrame_Min`；区间结束日 = `Last_Fiscal_Month_Max`
    - VIC KPIs Base Value 总路由中新增 VIC Retention% 分支，分别调用 Act/LY/LP 三套 Rolling12 分母
    - 度量值总数从 8 个增加到 11 个
  - **格式相关同步调整**:
    - Cell Display 度量值按精简后的 Metric_Format 单字段分发，保留扩展格式（percent_0dp / delta_bp 等）便于后续调整
    - 方案文档第 1.3 / 3.5 / 3.7 / 8 等章节同步更新格式说明
- **关联文件**:
  - `VIC/VIC KPI/Dim_ColMetric_VIC_KPIs.md`
  - `VIC/VIC KPI/VIC_KPIs_Table.md`
  - 参考列维度表: `RL E2E BOSS Dashboard/Performance by Merchandise/Dim_ColMetric_Fulfillment_PB_Merchandise.md`
- **备注**:
  - 用户反馈1：参考列维度表已调整格式定义，不存在 `percent_1dp_signed` / `percent_1dp_nosign`，应统一为 `percent_1dp` / `delta_pct_1dp`，TAR ACH% 也用 `percent_1dp`
  - 用户反馈2：Rolling 12 个财月 = 当前月 + 往前 11 个月共 12 个月的 `count(distinct user_id)` 汇总，仅 VIC Retention% 指标使用，分母中
  - 通过 AskUserQuestion 两次澄清：聚合方式为"区间 DISTINCT 汇总"；Rolling 12 起始日通过 EDATE + 维度表查 TimeFrame_Min 获取
  - Share 类指标分母保持不变（end period 当月 is_vic=1，等价 Metric_ID=1）
---

## [2026-09-12 11:32] DAX 修改 — VIC Retention%（Metric_ID=6）分母由 Rolling 12 区间调整为"往前推 12 个月单月"

- **模块**: VIC
- **任务**: VIC_KPIs_Table.md Metric_ID=6 分母口径调整（用户需求）
- **操作**: 修改
- **变更内容**:
  - **VIC KPIs Act Base Value（Metric_ID=6 分支）**:
    - 分母弃用 Rolling 12 区间（原：起始月 EDATE(-11) → 区间 [起始月 TimeFrame_Min, Last_Fiscal_Month_Max]）
    - 新逻辑：分母目标月 = end period 直接往前推 12 个月（如 "2027-09" → "2026-09"），按 TimeFrame_Value 查目标月 TimeFrame_Min/TimeFrame_Max，分母 = 目标月单月区间内 is_vic=1 的 DISTINCTCOUNT(user_id)
    - 旧 Rolling 12 逻辑以 /* */ 块注释保留，如需回退取消注释即可
  - **VIC KPIs LY Base Value（Metric_ID=6 分支）**:
    - 分母目标月 = Last_Fiscal_Month EDATE(-12) 得 LY 月份字符串，再 EDATE(-12)（等价往前推 24 个月，如 "2027-09" → "2025-09"）
    - 区间起止日均取目标月行 TimeFrame_Min/TimeFrame_Max（不再复用 Last_Fiscal_Month_Max_LY）；旧逻辑块注释保留
  - **VIC KPIs LP Base Value（Metric_ID=6 分支）**:
    - 分母目标月 = Last_Fiscal_Month EDATE(-1) 得 LP 月份字符串，再 EDATE(-12)（等价往前推 13 个月，如 "2027-09" → "2027-08" → "2026-08"）
    - 区间起止日均取目标月行 TimeFrame_Min/TimeFrame_Max（不再复用 Last_Fiscal_Month_Max_LP）；旧逻辑块注释保留
  - **其余指标逻辑不变**：分子（is_retention_vic=1 end period 当月）、其他 Metric_ID 分支、总路由/Display/颜色度量值均未改动（仅同步描述性注释）
  - **文档同步**：头部 revised、1.4 节（新口径 + 历史口径备查块）、2.2/3.1/3.2/3.3/3.6/4.1、4.2-4.5 度量值注释、第 5 章度量值清单、第 6 章血缘图、第 7 章注意事项（item 4 重写 + item 6/14 措辞）同步更新
- **关联文件**:
  - `VIC/1 VIC KPI/VIC_KPIs_Table.md`
- **备注**:
  - 分母目标月依赖 Slicer_Time_Frame_Max 的 TimeFrame_Max 字段（此前仅用 TimeFrame_Min），该字段已存在于维度表 SQL 中无需改表
  - 如需回退 Rolling 12 口径：删除/注释各 Base Value 中"新逻辑"段，取消"旧逻辑"块注释
---

## [2026-09-12 12:18] 口径文档修改 — VIC KPI.md VIC Retention%（Metric_ID=6）分母定义同步为"往前推 12 个月单月"

- **模块**: VIC
- **任务**: 口径文档同步 VIC_KPIs_Table.md Metric_ID=6 分母口径调整（用户需求）
- **操作**: 修改
- **变更内容**:
  - **头部引用块**: 新增"口径修订: 2026-09-12"行（分母由 Rolling 12 个财月区间调整为"以 end period 为基准往前推 12 个月的单月"，ACT=-12 / LY=-24 / LP=-13）
  - **§2 VIC Retention% 表格**: 业务定义 / 计算公式 / 分母三行由 Rolling 12 区间改为"以所选时间范围 end period 为基准往前推 12 个月的单月"（分母计算方式：目标月单月区间内 count(distinct user_id) where is_vic = 1）
  - **§2 表格后新增说明块**: 分母目标月基准（ACT/LY/LP 三条偏移示例，与 VIC_KPIs_Table.md 第 1.4 节措辞一致）+ 历史 Rolling 12 口径（2026-09-12 弃用，保留备查，含旧 DAX 块注释回退提示）
  - **其余内容零改动**: VIC No. / Direct VIC No. / 通用规则汇总中的 "Rolling 12" 为 VIC 买家定义（net sales >= 20k），与 Retention 分母无关，未改动；其他指标口径未改动
- **关联文件**:
  - `口径文档/VIC/VIC KPI.md`
  - 关联解决方案文档: `VIC/1 VIC KPI/VIC_KPIs_Table.md`（第 1.4 节为措辞基准）
- **备注**:
  - 措辞与 VIC_KPIs_Table.md 第 1.4 节保持一致；实现细节（财月字段偏移、TimeFrame_Min/Max 查询）仍归解决方案文档，口径文档仅保留业务口径定义
---

## [2026-09-12 17:04] 解决方案修改 — VIC_Segment_Table.md SLS 类指标 Step1+Step2 由"合并为 end period 当月"调整为分步实现

- **模块**: VIC
- **任务**: VIC Segment 表格 SLS 类指标（口径文档指标 5/7/9/10/11/12）Step1+Step2 口径调整（用户需求：两步时间范围不同不能合并，需分步计算，参考"新客 No."度量值分步范式）
- **操作**: 修改
- **变更内容**:
  - **头部**: 新增 revised 行（Step1 在 end period 当月框定 user_id，Step2 在所选时间范围 TimeFrame 区间聚合，两步时间范围不同不能合并）
  - **§1.1**: 重写为"end period 时间筛选与所选时间范围筛选"，区分两套时间范围（Step1 = Last_Fiscal_Month_*；Step2 = TimeFrame_Min/Max，TimeFrame_Min 读 Slicer_Time_Frame_Min，TimeFrame_Max 读 Slicer_Time_Frame_Max；各自含 LY 偏移）
  - **§1.4**: 重写为"Step 1 + Step 2 口径（分步计算，不能合并）"，新增 2026-09-12 口径修订说明（Step2 "所选时间范围"即切片器所选完整时间范围，回归口径文档原文本意），旧"合并实现"口径降级为历史口径备查块
  - **§2.2**: 维度表清单新增 Slicer_Time_Frame_Min（TimeFrame_Min / TimeFrame_Min_LY，Step2 区间起点），Slicer_Time_Frame_Max 行补充 TimeFrame_Max / TimeFrame_Max_LY
  - **§3.1/3.2/3.3/3.4/3.5**: 架构图、Base 层描述、筛选器上下文表（拆为 Step1/Step2 四行 + DIM_Row_VIC_Tier 分步处理说明）、时间偏移规则（两套区间不能合并）、指标公式表（指标 5/7/9/10/11/12 明确 Step 时间范围）同步更新
  - **§4.1.5/4.1.6 _SLS Base Act/LY**: 重写为分步实现——Step1 `CALCULATETABLE(VALUES(user_id), ...)` end period 当月按当前行 customer_tier 框定 user_id 集合；Step2 `TREATAS(__TierUsers, user_id)` + TimeFrame 区间聚合 + `REMOVEFILTERS(DIM_Row_VIC_Tier)`（Step2 只按 user_id 主体聚合）；旧单步逻辑以 /* */ 块注释保留可回退
  - **§4.1.7/4.1.8 _SLS Total Base Act/LY**: 分母时间范围由 end period 当月调整为所选时间范围（TimeFrame 区间，与分子 Step2 对齐；分母为全量口径不涉及 Step1 user_id 框定）；旧逻辑块注释保留
  - **§4.1.9~4.1.12 _Net Pay Qty / _Net Pay Order Cnt Base Act/LY**: 同 _SLS Base 模式重写为分步实现（SUM(net_pay_qty) / SUM(net_pay_order_cnt)）；旧逻辑块注释保留
  - **§4.1.1~4.1.4 Customer 类 Base 度量值**: 不变（单步 end period 当月口径，不涉及 Step1+Step2；指标 1~4 及 ACV/Freq. 分母仍为 end period 当月 count(distinct user_id)）
  - **§4.2 Value 层**: SLS / SLS vs LY / SLS% / SLS% vs LY / ACV / AUR / UPT / Freq. 8 个 Value 度量值注释同步分步口径（DAX 表达式不变，仍引用 Base 层）
  - **§5/§6/§7**: 度量值清单（序号 5~12 用途标注分步）、血缘关系图（数据源层新增 Slicer_Time_Frame_Min/Max，_SLS/Qty/OrderCnt Base 标注 Step1+2，传递链标注 Step1 保留 tier / Step2 REMOVEFILTERS）、注意事项（item 1/5/9/10/16/17/18 重写或微调）同步更新
- **关联文件**:
  - `VIC/4 VIC Segment/VIC_Segment_Table.md`
- **备注**:
  - Step2 所需 TimeFrame_Min / TimeFrame_Min_LY 字段已存在于 Slicer_Time_Frame_Min 维度表 SQL（维度复用/Slicer_Time_Frame/Slicer_Time_Frame_Min.sql），无需改表
  - Step2 的 REMOVEFILTERS(DIM_Row_VIC_Tier) 语义：口径中 customer_tier 仅用于 Step1 框定 user_id，Step2 只按 user_id 主体聚合；platform / shop_info_id 分组维度由模型自动传递保留
  - 如需回退合并口径：各 Base 度量值中注释"新逻辑"段并取消"旧逻辑"块注释即可
---

## [2026-09-12 18:00] 解决方案修改 — VIC_Segment_Table.md Step2 移除误加的 REMOVEFILTERS，占比类分母统一 ALLSELECTED(Row Label)

- **模块**: VIC
- **任务**: 纠正 Step1+Step2 分步度量值中误加的 REMOVEFILTERS(DIM_Row_VIC_Tier)（用户指正：行维度 DIM_Row_VIC_Tier[Row Label] 与事实表 1:N 关联自动传递分组，Step2 无需也无需显式移除；只有占比类分母才需要移除且用 ALLSELECTED 保留外部切片器影响）
- **操作**: 修改
- **变更内容**:
  - **§4.1.5/4.1.6 _SLS Base Act/LY、§4.1.9~4.1.12 _Net Pay Qty / _Net Pay Order Cnt Base Act/LY（6 个 Step1+Step2 分步度量值）**: Step2 CALCULATE 中删除 REMOVEFILTERS(DIM_Row_VIC_Tier)——customer_tier / platform / shop_info_id 分组维度由模型自动传递保留（Step2 与 Step1 行上下文一致，分组维度无需显式 DAX 处理），同步修正头部注释；旧逻辑块注释不受影响
  - **§4.1.7/4.1.8 _SLS Total Base Act/LY**: REMOVEFILTERS(DIM_Row_VIC_Tier) → ALLSELECTED('DIM_Row_VIC_Tier'[Row Label])，与用户已修改的 _Customer Total Base Act/LY（4.1.3/4.1.4）实现方式统一：移除视觉行上下文的 customer_tier 筛选传递（分母=全部 Tier 合计），保留外部切片器/筛选器影响（口径文档第 157 行原话）；旧逻辑块注释保留原样（备查）
  - **§1 行维度/§1.4 Step2 描述/§1.7 差异表/§3.1 架构图/§3.2 度量值模型/§3.3 筛选器上下文表**: 行维度字段名修正 Tier ID → Row Label（Tier ID 为 1:N 关系关联列，Row Label 为图片展示行标签）；Step2 描述改为"不移除分组维度筛选"；DIM_Row_VIC_Tier 传递规则改为"Step1/Step2 均保留自动传递，仅占比类分母用 ALLSELECTED(Row Label)"
  - **§3.5 公式表/§6 血缘图/§7 注意事项**: 指标 0 行维度字段、数据源层传递链（Step1/Step2 均保留 tier 自动传递）、_SLS Total 框（ALLSELECTED(RowLbl)）、item 4/5/9/15/18 同步更新（item 5 明确"Step2 不移除任何分组维度筛选，若加 REMOVEFILTERS 会破坏行上下文分组传递"；item 9 改为 ALLSELECTED 实现说明）
- **关联文件**:
  - `VIC/4 VIC Segment/VIC_Segment_Table.md`
- **备注**:
  - 行维度实际承载列为 DIM_Row_VIC_Tier[Row Label]（图片展示行标签，如 "T1 (≧ 200K)"），Tier ID 为与事实表 customer_tier 的 1:N 关系关联列（见 DIM_Row_VIC_Tier.md）
  - 6 个 Step1+Step2 分步度量值的旧逻辑块注释（合并为 end period 当月版本）不受影响，保留可回退
  - 用户在 4.1.3/4.1.4 手工修改的 ALLSELECTED（本条变更前已存在）保留不动，本次将 4.1.7/4.1.8 统一为同款写法
---

## [2026-09-12 18:26] 口径文档修改 — VIC Segment.md 同步 Step1+Step2 分步口径澄清与 ALLSELECTED 说明；解决方案文档指标 4 描述文字修正（差值 pts）

- **模块**: VIC
- **任务**: 将解决方案文档 Step1+Step2 分步调整（17:04）与 Step2 分组维度修正/占比类分母 ALLSELECTED 统一（18:00）同步回口径文档；同步核对过程中发现并修正解决方案文档指标 4（Customer% vs LY）描述文字与 DAX 实现/口径文档不一致问题
- **操作**: 修改
- **变更内容**:
  - **口径文档/VIC/VIC Segment.md**:
    - 头部新增口径修订行（2026-09-12）
    - 全局逻辑 end period 说明示例笔误修正（"比如2026-09，只关注2023-09" → "比如 2023-09 ~ 2026-09，只关注 2026-09"，按"区间→ end period"模式修复）
    - 子模块四：DIM_Row_VIC_Tier.md 参考文件路径修正（VIC\VIC Segment → VIC\4 VIC Segment）；新增行维度列职责说明（Row Label 行标签 / Tier ID 关联列）；新增 Step 1 + Step 2 分步口径集中说明块（适用指标 5/7/9/10/11/12；两步时间范围不同不能合并；Step 2 = 切片器所选完整时间范围；Step 1/Step 2 均不移除分组维度；仅占比类分母 ALLSELECTED；LY 版本双区间偏移）
    - 指标 3：分母补"全部 customer_tier，需移除 customer_tier 影响但保留外部切片器（ALLSELECTED）"说明（与指标 7 分母对齐）
    - 指标 5：计算公式显式 Step 1 = end period 当月单月 / Step 2 = 切片器所选完整时间范围 + 不能合并；聚合粒度补两步时间范围
    - 指标 6：聚合粒度修正（原误标 dt = 所选时间范围 end period，实际继承指标 5 分步口径，今年/去年均先分步计算再求 YOY，LY 版本双区间）
    - 指标 7：分子补不能合并；分母补"与分子 Step 2 同一完整区间、全量口径不框定 user_id"
    - 指标 8：聚合粒度补同指标 7 口径说明
    - 通用规则汇总：新增 Step1+Step2 分步口径规则行
  - **VIC/4 VIC Segment/VIC_Segment_Table.md（指标 4 Customer% vs LY 描述文字修正，共 12 处；DAX 实现与口径文档本就一致，无代码改动）**:
    - §1.6：指标 2/6（比值 YOY）与指标 4/8（差值 YOY）分组说明重写；Customer% vs LY 派生公式由"今年%/去年%-1"改为"今年% - 去年%（差值，×100 转 pts）"
    - §2.3 架构图 / §3.2 度量值模型：Customer% vs LY Value 描述改为差值；Display 由 percent_1dp 改为 integer_pts 格式
    - §3.5 公式表：指标 4 行改为"今年 - 去年（差值，×100 转 pts）/ integer_pts / #,##0pts;-#,##0pts;0pts"；YOY 格式说明改为指标 2/6 与指标 4/8 两组
    - 4.2.4 注释：计算公式修正为"今年买家人数占比 - 去年买家人数占比（差值，pts 指标）"；4.3.4 注释：数据格式修正为 integer_pts 差值 pts 格式
    - §5 度量值清单（序号 16/28）/ §6 血缘图 / §7 注意事项（item 10 拆分、item 11 重新分组）：同步修正
- **关联文件**:
  - `口径文档/VIC/VIC Segment.md`
  - `VIC/4 VIC Segment/VIC_Segment_Table.md`
- **备注**:
  - 指标 4 的 DAX 实现（4.2.4 Value 差值 ActCustomer - LYCustomer、4.3.4 Display FORMAT pts 格式）与口径文档指标 4（差值 + integer_pts）本就一致，本次仅修正解决方案文档描述文字，无 DAX 代码改动
  - 指标 9/10/11/12 计算公式未改动：与指标 5/7 共用同一 Step 模板，语义由子模块四新增分步口径说明块统一定义
  - 口径文档为业务口径权威（"一切以口径文档为准"），本次同步方向：解决方案口径变更回写口径文档（澄清/修正），并以口径文档为准反向修正解决方案描述文字
---

## [2026-09-12 19:13] 解决方案修改 — VIC_Breakdown_ms.md Step1+Step2 分步口径调整（SLS/SLS%/ACV/UPT/AUR/Freq.）

- **模块**: VIC
- **任务**: 按用户要求将 VIC Breakdown 矩阵中 "Step 1: dt = 所选时间范围 end period；Step 2: 再看所选时间范围" 口径的指标由"合并为 end period 当月单步聚合"调整为分步实现（分步范式参考用户已验证的"新客" DAX，即 Customer Breakdown Trend 的 TREATAS 模式）；两套区间字段均从 Slicer_Time_Frame_Max_VIC_Breakdown 读取（日期表不改动，防止日期表互相依赖）
- **操作**: 修改
- **变更内容**:
  - **§4.2 Act Base Value**: 重写为 Step1（end period 当月 UNION+FILTER 框定 is_xxx_vic=1 user_id 集合，避免 IF 返回表被降级为标量）+ Step2（TREATAS 传递 + TimeFrame_Min~Max 区间聚合，不再施加 is_xxx_vic=1）；__UserCount_Act（ACV/Freq. 分母）保持 end period 当月单步口径（COUNTROWS(Step1 集合)，口径文档明确"dt = 所选时间范围 end period"）；旧逻辑块注释保留可回退
  - **§4.3 LY Base Value / §4.4 LP Base Value**: 与 Act 对称分步重写，Step1 用 Last_Fiscal_Month_*_LY/LP，Step2 用 TimeFrame_Min/Max_LY/LP（均从 Max 表读取）；__UserCount_LY/LP 单步口径保持；旧逻辑块注释保留
  - **§4.5 Store Base Value**: 聚合类（SLS/qty/order_cnt）区间由 Last_Fiscal_Month 路由改为 TimeFrame 路由（Metric_ID 5/27→LY TimeFrame、6/28→LP TimeFrame、其他→Act TimeFrame），与分子 Step2 对齐（SLS% 分母口径文档明确"所选时间范围"）；__UserCount_Store（ACV/Freq. vs Store 分母）改用本期 end period 当月（Last_Fiscal_Month_Min/Max），与 VIC 侧口径对齐；旧逻辑块注释保留
  - **§头部/§1.2/§3.2/§3.3/§3.4/§3.6（第一批，17:50 前完成）**: 头部 revised 行；§1.2 Step1+Step2 分步说明块与历史口径说明；§3.2 度量值模型设计分步描述；§3.3 筛选器上下文两套区间表；§3.4 两套区间（Step1 end period / Step2 TimeFrame 及 LY/LP 偏移）；§3.6 SLS% 分子分母时间口径说明
  - **§4.6 总路由注释 / §5 度量值清单 / §6 血缘图 / §7 注意事项**: SLS% 派生规则注释补分步口径；清单 1-4 行用途说明；血缘图四个 Base Value 框说明；item 2 重写为两套区间、item 8 SLS% 分母改 TimeFrame 区间、item 11 补"Step2 不移除分组维度（REMOVEFILTERS 会破坏行上下文分组传递），全客分母保留行分组无需 ALLSELECTED"、item 12 重写为分步实现说明（原"时间范围一致合并"说法废弃）
- **关联文件**:
  - `VIC/5 VIC Breakdown/VIC_Breakdown_ms.md`
- **备注**:
  - Step2 所需 TimeFrame_Min/Max 及 LY/LP 偏移字段均已内置在 Slicer_Time_Frame_Max_VIC_Breakdown.sql（L17-26/L45-54），无需改表；Slicer_Time_Frame_Min_VIC_Breakdown 本方案不使用，避免日期表互相依赖
  - VIC Breakdown 行维度为事实表字段（platform/shop_info_id）直接拉取，与 VIC Segment 的断开维度表 DIM_Row_VIC_Tier 不同：Step2 无需 ALLSELECTED（无占比类分母移除行上下文需求，SLS%/vs Store 全客分母保留行分组为行内占比口径）
  - 如需回退合并口径：4.2/4.3/4.4/4.5 中注释"新逻辑"段并取消"旧逻辑"块注释即可
---

## [2026-09-12 19:16] 口径文档修改 — VIC Breakdown KPI.md 同步 Step1+Step2 分步口径澄清与 vs Store 全客分母时间口径

- **模块**: VIC
- **任务**: 将解决方案文档 VIC_Breakdown_ms.md 的 Step1+Step2 分步口径调整（19:13）同步回口径文档（业务口径权威），补充 vs Store 全客分母时间口径（原口径文档未明示，按与分子对齐原则处理）
- **操作**: 修改
- **变更内容**:
  - **头部**: 新增口径修订行（2026-09-12，指向子模块五分步口径说明）
  - **全局逻辑 end period 说明**: 示例笔误修正（"比如2026-09，只关注2023-09" → "比如 2023-09 ~ 2026-09，只关注 2026-09"，与 VIC Segment.md 同款笔误同款修复）
  - **子模块五**: 分组维度说明补"基于 dt = 所选时间范围 end period 的情况下 New/Retention VIC 的区别仅在于 is_new_vic=1 / is_retention_vic=1 筛选条件"；新增 Step 1 + Step 2 分步口径集中说明块（Step1 end period 当月框定 is_xxx_vic=1 user_id / Step2 TimeFrame 区间聚合且不再施加 is_xxx_vic=1、分组维度自动传递不移除 / 例外：ACV、Freq. 分母 count(distinct user_id) 保持 end period 当月单步 / 全客分母：SLS% 与 vs Store 聚合为所选时间范围全量、user_id 计数为 end period 当月 / LY、LP 版本双区间偏移）
  - **指标 1 SLS / 2 SLS% / 3 ACV / 4 UPT / 5 AUR / 6 Freq.**: 计算公式改写为分步表述（SLS、UPT、AUR 分子分母均分步；SLS% 分子分步、分母所选时间范围全量；ACV、Freq. 分子分步、分母 end period 当月单步）
  - **指标 3.3 ACV vs Store / 4.3 UPT vs Store / 5.3 AUR vs Store / 6.3 Freq. vs Store**: 计算公式补充时间口径说明（ACV/Freq.：sum 聚合 = Step1+Step2 所选时间范围、count(distinct user_id) = end period 当月；UPT/AUR：分子分母聚合均 Step1+Step2；全客为 is_xxx_vic in (0,1) 全量口径无 Step 1 框定）
  - **通用规则汇总**: 新增 Step1+Step2 分步口径规则行
- **关联文件**:
  - `口径文档/VIC/VIC Breakdown KPI.md`
- **备注**:
  - vs Store 全客分母时间口径原口径文档未明示，本次按与分子对齐原则补充（聚合 sum = 所选时间范围、user_id 计数为 end period 当月），如与业务理解不符请指正
  - 口径文档为业务口径权威（"一切以口径文档为准"），本次同步方向：解决方案口径变更回写口径文档（澄清/补充）
---

## [2026-09-12 20:24] 解决方案修改 — VIC_Breakdown_ms.md Step1+Step2 分步口径调整（回退后重新应用）

- **模块**: VIC
- **任务**: VIC_Breakdown_ms.md 此前被整体回退至原始版本（1650 行），本次基于回退后状态将 Step1+Step2 分步口径调整完整重新应用（用户指示"重新修改一份就好了，不要纠结我有没有回退"）；变更明细与 [2026-09-12 19:13] 条目完全一致，解决方案文档以本条目对应版本为准
- **操作**: 修改
- **变更内容**: 按 19:13 条目重新落盘全部七批编辑（文件 1650 → 1711 行）:
  - 头部 revised 行 / §1 筛选器两套区间说明 / §1.2 Step1+Step2 分步说明块与历史口径说明
  - §2.2 维度表清单 / §3.2 度量值模型分步描述 / §3.3 筛选器上下文两套区间表 / §3.4 两套区间 / §3.6 SLS% 分子分母时间口径
  - §4.2 Act / §4.3 LY / §4.4 LP Base Value 分步重写（Step1 end period 当月 UNION+FILTER 框定 is_xxx_vic=1 user_id 集合 + Step2 TREATAS + TimeFrame 区间聚合；__UserCount 保持 end period 当月单步口径；旧逻辑块注释保留可回退）
  - §4.5 Store Base Value（聚合类按 Metric_ID 路由 TimeFrame 区间 + __UserCount_Store 固定本期 end period 当月）
  - §4.6 总路由注释 / §5 度量值清单 / §6 血缘图 / §7 注意事项（item 2/8/11/12）同步更新
- **关联文件**:
  - `VIC/5 VIC Breakdown/VIC_Breakdown_ms.md`
- **备注**:
  - 口径文档 VIC Breakdown KPI.md 未受文件回退影响，[2026-09-12 19:16] 条目对应的同步编辑完整在位，本次验证后无需重做
  - 重新应用后已验证：TREATAS 传递 10 处（Act/LY/LP 各 3 + §7 说明 1）、旧逻辑块 4 处、两套区间字段（Last_Fiscal_Month_* / TimeFrame_* 含 _LY/_LP 偏移）全部落盘
  - 完整变更明细见 [2026-09-12 19:13] 条目，本条目仅记录重新应用事实，避免重复
---

## [2026-09-12 20:47] 解决方案修改 — VIC Breakdown Store Base Value 全客分母 Step1+Step2 分步化 + 口径文档同步

- **模块**: VIC
- **任务**: 按用户澄清，VIC Breakdown 的全客分母（Store Base Value，vs Store / SLS% 分母）由"单步 TimeFrame 区间聚合（is_xxx_vic IN {0,1} 施加于聚合本身，无 Step 1 框定）"调整为 Step1+Step2 分步——与 VIC 侧分子对称，唯一区别是 Step 1 的筛选条件（IN {0,1} 全客 vs =1 VIC）；单步版人群包含"TimeFrame 内活跃但 end period 当月不活跃"的 user，与分子（end period 当月框定人群）基准不一致
- **操作**: 修改
- **变更内容**:
  - **§4.5 Store Base Value**: 分步重写——Step 1 新增 __EndPeriodMin/__EndPeriodMax 按 Metric_ID 路由 end period 当月（5/27→LY、6/28→LP、其他→本期）+ __AllUsers UNION+FILTER 框定 is_xxx_vic IN {0,1} 全客 user_id 集合；Step 2 __SLS_Store/__NetPayQty_Store/__NetPayOrderCnt_Store 改 TREATAS(__AllUsers) + 路由后 TimeFrame 区间（is_xxx_vic IN {0,1} 不再施加）；__UserCount_Store 改 COUNTROWS(__AllUsers)；旧逻辑块更新为两段演进说明（演进一 Last_Fiscal_Month 路由单步 / 演进二单步 TimeFrame 版含完整可回退 DAX）
  - **正文同步**: 头部 revised 行；§1.2 SLS% 分母说明；§1.6 vs Store（分母同样分步）；§3.2 Store 框；§3.6 标题/表格分母列/说明块；§5 清单第 4 行；§6 血缘图 Store 框；§7 item 6（含人群基准不一致原因与 UNION+FILTER 实现方式）/ item 8（SLS% 分母分步表述 + Act/LY/LP 两套区间路由）/ item 12（补全客分母同样分步）
  - **§4.6 总路由注释**: 派生规则 SLS% Act 注释、SLS% 计算注释、Store Base Value 两套区间路由注释、SLS% 分母注释同步分步口径（代码逻辑不变，仅注释）
  - **口径文档同步**: 口径文档/VIC/VIC Breakdown KPI.md 共 8 处——头部口径修订行、子模块五全客分母口径行（改写为同样分步）、SLS% 计算公式（分母补 Step1/Step2 分步表述）、ACV/UPT/AUR/Freq. vs Store 四个计算公式（分子分母口径对称分步表述）、通用规则汇总 Step1+Step2 分步口径行
- **关联文件**:
  - `VIC/5 VIC Breakdown/VIC_Breakdown_ms.md`
  - `口径文档/VIC/VIC Breakdown KPI.md`
- **备注**:
  - Step 1 区间按 Metric_ID 路由：SLS% vs LY（5/27）分母的 Step 1 用 LY end period 当月、SLS% vs LP（6/28）用 LP end period 当月、其他（vs Store 分母 10/14/18/22/32/36/40/44、SLS% Act 分母 4/26）用本期 end period 当月——与 Step 2 TimeFrame 路由同步，SLS% vs LY/LP 的分子分母期间完全对齐
  - __UserCount_Store 从"固定本期 end period 当月 DISTINCTCOUNT"改为 COUNTROWS(__AllUsers)：vs Store 场景路由结果即本期 end period 当月，口径等价且实现统一
  - 如需回退单步口径：§4.5 旧逻辑块内含演进二（单步 TimeFrame 版）完整实现与恢复步骤
---

## [2026-09-12 21:04] 解决方案修改 — VIC_Breakdown_Trend.md Step1+Step2 分步口径调整

- **模块**: VIC
- **任务**: 按用户要求将 VIC Breakdown Trend 柱形图 4 个 Value 度量（Metric_ID 1/4/23/26，SLS Act / SLS% Act × New/Retention VIC）由"X 轴时间点 end period 当月单步聚合"改为 Step1+Step2 分步（与主表 VIC_Breakdown_ms.md 同步，范式参考 Customer Breakdown Trend 的 TREATAS 模式）；两套区间均从 Slicer_Time_Frame_VIC_Breakdown（X 轴表）读取，日期表不改动
- **操作**: 修改
- **变更内容**:
  - **§4.2 / §4.6 SLS Trend Value (New/Retention VIC)**: Step 1 新增 __CurrentTFMin/Max 变量（X 轴表 TimeFrame_Min/Max）+ __VICUsers CALCULATETABLE 框定 end period 当月（Last_Fiscal_Month_Min/Max）is_xxx_vic=1 user_id 集合；Step 2 __Result 改 TREATAS(__VICUsers) + X 轴时间点自身范围（+全局冗余，is_xxx_vic=1 不再施加）；旧逻辑块注释保留可回退
  - **§4.4 / §4.8 SLS% Trend Value (New/Retention VIC)**: 分子分母均分步——Step 1 各自框定 __VICUsers（is_xxx_vic=1）与 __AllUsers（is_xxx_vic IN {0,1}，与分子唯一区别是筛选条件，与主表 Store 分母分步化一致）；Step 2 各自 TREATAS + TimeFrame 区间聚合；旧逻辑块注释保留
  - **正文同步**: 头部 revised 行；§1 指标表计算方式分步表述；§1 核心设计原则；§1.2 分步范式说明（含 Month/Quarter 粒度两步区间差异说明）；§2.2 X 轴表字段说明补 TimeFrame_Min/Max；§3.1 筛选上下文表拆 Step 1/Step 2 两行；§7.1/§7.2 验证 SQL 改分步版（WITH CTE 框定集合 + JOIN 聚合）；§8 item 3 重写分步说明、item 4 补 Step 1 表述与"无需 UNION 分支"说明、item 9 重写口径等价性
- **关联文件**:
  - `VIC/5 VIC Breakdown/VIC_Breakdown_Trend.md`
- **备注**:
  - Trend 场景与主表的关键差异：主表两套区间从 Slicer_Time_Frame_Max_VIC_Breakdown（切片器所选范围）读取；Trend 从 Slicer_Time_Frame_VIC_Breakdown（X 轴当前时间点）读取——Step 1 = 该时间点 end period 当月，Step 2 = 该时间点自身时间范围，每个柱子独立代表一个时间点
  - Month 粒度时 Step 1 与 Step 2 区间重合（同为当月），但 Step 1 有 is_xxx_vic 筛选而 Step 2 无（语义：当月被识别为 VIC 的人在当月的消费）；Quarter 粒度时 Step 1 为季末当月、Step 2 为整季
  - 每个度量值 VICType 固定，Step 1 直接 CALCULATETABLE 框定，无需主表的 UNION+FILTER 分支（主表因单度量值动态路由 VICType 才需要）
  - X 轴表 Slicer_Time_Frame_VIC_Breakdown.sql 已内置 TimeFrame_Min/Max（L17-18/L45-46），无需改表；口径文档 VIC Breakdown KPI.md 的分步口径说明（子模块五）已覆盖 Trend 场景，无需另行同步
---

## [2026-09-14 10:30] 解决方案修改 — VIC_Trend.md VIC Retention% 分母由 Rolling 12 区间调整为"往前推 12 个月单月"（与主表口径对齐）

- **模块**: VIC
- **任务**: VIC Trend 柱形图 3 个 VIC Retention% 基础度量值（Act/LY/LP）分母口径同步主表 VIC_KPIs_Table.md 2026-09-12 的 Metric_ID=6 分母调整（用户需求）
- **操作**: 修改
- **变更内容**:
  - **VIC Retention% Trend Act Value**: 分母弃用 Rolling 12 区间（原：X 轴 Last_Fiscal_Month EDATE(-11) 起始月 → 区间 [起始月 TimeFrame_Min, Last_Fiscal_Month_Max]）；新逻辑：分母目标月 = X 轴 end period 直接往前推 12 个月（如 "2026-09" → "2025-09"），按 TimeFrame_Value 查目标月 TimeFrame_Min/TimeFrame_Max，分母 = 目标月单月区间内 is_vic=1 的 DISTINCTCOUNT(user_id)；旧 Rolling 12 逻辑以 /* */ 块注释保留，如需回退取消注释即可
  - **VIC Retention% Trend LY Value**: 分母目标月 = X 轴 Last_Fiscal_Month EDATE(-12) 得 LY 月份字符串，再 EDATE(-12)（等价往前推 24 个月，如 "2026-09" → "2024-09"）；区间起止日均取目标月行 TimeFrame_Min/TimeFrame_Max（不再复用 Last_Fiscal_Month_Max_LY）；旧逻辑块注释保留
  - **VIC Retention% Trend LP Value**: 分母目标月 = X 轴 Last_Fiscal_Month EDATE(-1) 得 LP 月份字符串，再 EDATE(-12)（等价往前推 13 个月，如 "2026-09" → "2026-08" → "2025-08"）；区间起止日均取目标月行 TimeFrame_Min/TimeFrame_Max（不再复用 Last_Fiscal_Month_Max_LP）；旧逻辑块注释保留
  - **其余指标逻辑不变**：分子（is_retention_vic=1 X 轴 end period 当月）、VIC No. / T4-5 Upgrade No. 系列、Share 分母、Value/Display 对外度量均未改动（仅同步描述性注释）
  - **文档同步**：头部 revised、§1 指标表/核心设计原则、§1.3 重写（新口径 + 柱形图适配差异 + 历史口径备查块）、§2.2 日期表结构假设、§3.1 筛选器上下文表（新增分母目标月行）、§3.2 架构图、§4.5-4.7 度量值（标题+头部注释+分母逻辑）、§4.17/4.19/4.21 注释、§7.2 验证 SQL（分母改单月区间 2025-09）、§8 注意事项（item 4 重写 + item 7 措辞）同步更新
- **关联文件**:
  - `VIC/2 VIC Trend/VIC_Trend.md`
- **备注**:
  - 分母目标月基于 X 轴当前时间点（Slicer_Time_Frame_VIC_Trend[Last_Fiscal_Month]）推导而非主表的全局 end period（Slicer_Time_Frame_Max），每个柱子独立计算自己的目标月——Trend 场景与主表的唯一差异
  - 所需 TimeFrame_Min/TimeFrame_Max 字段已存在于 X 轴日期表（结构与 Slicer_Time_Frame_Max 一致，支持按 TimeFrame_Value 查任意月份起止日），无需改表
  - 口径文档 VIC KPI.md 的分母定义（2026-09-12 已修订为"往前推 12 个月单月"）已覆盖 Trend 场景，无需另行同步
  - 如需回退 Rolling 12 口径：删除/注释各基础度量值中"新逻辑"段，取消"旧逻辑"块注释
---

## [2026-09-14 14:00] 解决方案修改 — VIC_Segment_Table.md 占比类分母口径调整（Total = 五行加总）

- **模块**: VIC
- **任务**: 按用户口径调整占比类分母：_Customer Total 与分子完全对称（去掉 net_pay_amt>0），_SLS Total 改为与 _SLS 同结构 Step1+Step2 分步，customer_tier 均扩为全部 T1-T5，Total = T1+T2+T3+T4+T5 加总；LY 版本同步；旧逻辑块注释删除
- **操作**: 修改
- **变更内容**:
  - **4.1.3 _Customer Total Base Act**: 删除 net_pay_amt > 0 行级筛选，与分子完全对称（end period 当月 + is_member/is_employee + ALLSELECTED(Row Label) 扩 tier 为全部 T1-T5）；标题与注释同步
  - **4.1.4 _Customer Total Base LY**: 同 4.1.3 的 LY 版本对称调整
  - **4.1.7 _SLS Total Base Act**: 由"所选时间范围单步聚合 + ALLSELECTED"重写为与 4.1.5 _SLS Base Act 完全同结构的 Step1（end period 当月 CALCULATETABLE(VALUES(user_id)) + ALLSELECTED(Row Label) 框定全部 tier user_id）+ Step2（TREATAS + TimeFrame 区间 + ALLSELECTED(Row Label) 聚合）；旧逻辑块注释删除（end period 版与 TimeFrame 单步版均不再保留）
  - **4.1.8 _SLS Total Base LY**: 同 4.1.7 的 LY 版本分步重写（LY Step1 + LY Step2 + ALLSELECTED）；旧逻辑块注释删除
  - **正文同步**: 头部 revised 行；§1.1 Step1/Step2 适用范围（指标 7 分母纳入 Step1）；§1.4 占比类分母 ALLSELECTED 说明；§3.1 架构图；§3.2 度量值模型设计；§3.3 筛选器上下文表（DIM_Row_VIC_Tier 行补视觉对象筛选"Tier ≠ 空白"记录）；§3.5 指标 3/指标 7 计算公式；4.2.3/4.2.7 计算公式注释；§5 度量值清单第 3/4/7/8 条；§6 血缘图；§7 item 9 重写为"占比类分母 ALLSELECTED + Total 加总口径"
  - **口径文档同步**: 口径文档/VIC/VIC Segment.md 头部新增 2026-09-14 口径修订行；子模块四集中说明块（占比类分母描述）；指标 3 计算公式/分母；指标 7 计算公式/分母；指标 8 聚合粒度；通用规则汇总 Step1+Step2 行
- **关联文件**:
  - VIC/4 VIC Segment/VIC_Segment_Table.md
  - 口径文档/VIC/VIC Segment.md
- **备注**:
  - 调整后 Customer% / SLS% 五行加总 = 100%（分子分母同 tier 范围对称口径）；Total 在 tier 月度稳定时严格等于各行加总
  - 本次仅删除 4.1.7/4.1.8 的旧逻辑块注释（用户要求删除冗余）；4.1.5/4.1.6/4.1.9~4.1.12 的"合并实现"历史块注释不在本次调整范围，仍保留可回退
  - 视觉对象筛选"Tier ≠ 空白"补录至 §3.3（上轮审查发现的文档缺失项），ALLSELECTED 保留其影响以确保分母 tier 范围 = T1-T5
---

## [2026-09-14 15:30] 解决方案修改 — VIC_Breakdown_ms.md Step 2 区间起点修复（TimeFrame_Min 误读 Max 表，调整起始月不生效）

- **模块**: VIC
- **任务**: 修复 VIC Breakdown 矩阵 Step1+Step2 分步度量值中 Step 2 区间起点误读 Max 表的 bug（用户实证：日期范围 202701~202704，调整 end period 卡片值变化、调整起始月不变；理论上调整起始月也应变化）
- **操作**: 修改
- **变更内容**:
  - **根因**: Slicer_Time_Frame_Max_VIC_Breakdown 为每行一个财历周期（Month/Quarter）的静态表，每行 TimeFrame_Min/Max 是该行周期自身的起止自然日；分步改造时 Step 2 起点误从 Max 表[TimeFrame_Min] 读取，读到的是 end period 所选周期自身的起始日而非用户所选起始月——Step 2 实际区间退化为 end period 当月单月（与起始月切片器完全无关），调整起始月不生效、调 end period 才变化，且看板值实际仍是旧"合并口径"（单月）的结果
  - **§4.2 Act / §4.3 LY / §4.4 LP Base Value**: Step 2 区间起点改读 Slicer_Time_Frame_Min_VIC_Breakdown（Act: TimeFrame_Min；LY: TimeFrame_Min_LY；LP: TimeFrame_Min_LP），终点 TimeFrame_Max 系列与 Step 1 Last_Fiscal_Month_* 系列仍从 Max 表读取（终点=end period 周期自身结束日=所选范围终点，Step 1 本就正确）；各度量值头部依赖注释与 Step 2 说明同步
  - **§4.5 Store Base Value**: __PeriodMin 按 Metric_ID 路由的三分支起点（LY/LP/Act）全部改读 Min 表，__PeriodMax 三分支终点保持 Max 表
  - **演进记录**: 四个 Base Value 旧逻辑块前追加"演进记录（2026-09-14 修复: Step 2 区间起点误读 Max 表）"说明块，含根因、用户实证现象与回退方法（改回 SELECTEDVALUE(Max 表[TimeFrame_Min]) 即可）
  - **文档同步**: 头部追加 revised 2026-09-14 行；§1 筛选器清单（Min 表由"本方案不使用"改为"起始月切片器，读取 Step 2 区间起点"）；§1.2/§2.2/§3.2/§3.3/§3.4/§5/§6 血缘图（数据源层新增 Min/Max 日期表框）/§7 item 2（重写，含根因与切片器绑定检查提示）+ item 6 同步
- **关联文件**:
  - `VIC/5 VIC Breakdown/VIC_Breakdown_ms.md`
- **备注**:
  - 口径本身未变（Step 2 = 切片器所选完整时间范围），本次为实现层 bug 修复，口径文档 VIC Breakdown KPI.md 无需同步
  - "防止日期表互相依赖"约束重新诠释：Min/Max 两表各自独立被切片器筛选、互相无关系（度量值内 SELECTEDVALUE 后拼接区间），不构成日期表互相依赖；与 VIC Segment 模式一致（Step 2 起点读 Slicer_Time_Frame_Min，已验证）
  - 所需 TimeFrame_Min/TimeFrame_Min_LY/TimeFrame_Min_LP 字段已存在于 Slicer_Time_Frame_Min_VIC_Breakdown.sql（L17-26），无需改表
  - 用户需在 Power BI 页面确认：起始月切片器绑定 Slicer_Time_Frame_Min_VIC_Breakdown、end period 切片器绑定 Slicer_Time_Frame_Max_VIC_Breakdown（均单选），修复后调整起始月卡片值应正常变化
  - 如需回退错误版本：将各度量值起点 SELECTEDVALUE 改回 Max 表对应字段（各演进记录块内有说明）
---

## [2026-09-15] 口径文档修改 — VIC Breakdown KPI.md 四个 vs Store 指标全客分母口径修订（依据 VIC vs Store.sql）

- **模块**: VIC
- **任务**: 依据数据方 SQL（`口径文档/VIC/VIC vs Store.sql`）修订子模块五 ACV vs Store / UPT vs Store / AUR vs Store / Freq. vs Store 四个指标的全客分母口径表述，供后续 Power BI DAX 编写使用
- **操作**: 修改
- **变更内容**:
  - **核心口径变更（全客分母）**: 由"Step 1 + Step 2 分步（Step 1 在 end period 当月筛选 is_xxx_vic in (0,1) 框定全客集合，Step 2 所选时间范围聚合）"改为**单步**——直接在所选时间范围（TimeFrame 区间）筛选 `net_pay_amt > 0`（含 is_member/is_employee 筛选）做 sum / count(distinct user_id) 聚合，不框定 user_id 集合、不施加任何 is_xxx_vic 筛选；New VIC 与 Retention VIC 共用同一全客分母（与 is_xxx_vic 无关）
  - **VIC 侧分子维持分步不变**: Step 1 在 end period 当月筛选 is_xxx_vic = 1 框定 user_id 集合，Step 2 在所选时间范围对该集合聚合（is_xxx_vic = 1 不再施加）；ACV / Freq. 分子的 count(distinct user_id) 为 Step 2 区间对 Step 1 集合计数，数值等价于本体指标 end period 当月单步分母（DAX 可直接复用 ACV / Freq. 度量值）
  - **文档同步 7 处**: 头部新增 2026-09-15 口径修订行；子模块五"全客分母口径"说明拆分为"SLS% 全客分母口径（分步）"与"vs Store 全客分母口径（单步）"两条；ACV/UPT/AUR/Freq. vs Store 四个指标的计算公式/分子/分母/筛选条件行重写；通用规则汇总 Step1+Step2 分步口径行拆分同步
  - **SLS% 分母口径不变**: 维持 2026-09-12 分步口径（VIC vs Store.sql 未覆盖 SLS%，是否对齐单步口径待用户确认）
- **关联文件**:
  - `口径文档/VIC/VIC Breakdown KPI.md`
  - 口径依据: `口径文档/VIC/VIC vs Store.sql`
- **备注**:
  - 分子分母人群口径不再对称（分子 = Step 1 框定集合，分母 = 区间内 net_pay_amt > 0 全部买家），为 SQL 原文口径
  - 解决方案文档 `VIC/5 VIC Breakdown/VIC_Breakdown_ms.md` §4.5 Store Base Value 当前仍为分步 + is_xxx_vic IN {0,1} 实现，与本次修订口径不一致，后续 DAX 编写/调整时需按新口径改写（旧逻辑按规范以块注释保留可回退）——已于同日落实（见下一条目）
---

## [2026-09-15] 解决方案修改 — VIC_Breakdown_ms.md Store Base Value vs Store 分母单步化 + Cell Display 新增 currency_M_K_Int_0db 格式

- **模块**: VIC
- **任务**: 依据 2026-09-15 修订后的 vs Store 口径（VIC vs Store.sql），将 VIC Breakdown Store Base Value 的 vs Store 全客分母由分步改为单步（SLS% 分母维持分步）；Cell Display 新增 currency_M_K_Int_0db 货币自适应缩写格式；验证总路由 vs Store 比值自然匹配新口径
- **操作**: 修改
- **变更内容**:
  - **§4.5 Store Base Value 双口径化**:
    - vs Store 分母（Metric_ID 10/14/18/22/32/36/40/44）改为单步——新增 `__TimeFrameMin/__TimeFrameMax`（本期区间，起点 Min 表 + 终点 Max 表）与 `__TTL_SLS/__TTL_UserCount/__TTL_NetPayQty/__TTL_NetPayOrderCnt` 4 个单步聚合变量（TimeFrame 区间 + net_pay_amt > 0 + is_member/is_employee，无 is_xxx_vic 筛选、不框定 user_id 集合，New/Retention VIC 共用同一全客分母）；RETURN SWITCH 的 8 个 vs Store 分支改用 __TTL_* 组合（10/32→SLS/UserCount、14/36→Qty/OrderCnt、18/40→SLS/Qty、22/44→OrderCnt/UserCount）
    - SLS% 分母（Metric_ID 4/5/6/26/27/28）维持 2026-09-12 分步不变（__AllUsers 框定 is_xxx_vic IN {0,1} + __SLS_Store TREATAS 区间按 Metric_ID 路由），相关变量与注释全部标注"仅 SLS% 分母使用"
    - 旧分步实现（__UserCount_Store/__NetPayQty_Store/__NetPayOrderCnt_Store）以"演进记录（2026-09-15 修订）"块注释保留，含回退说明
  - **vs Store 比值验证结论（总路由 §4.6 无需改动）**: `__VsStoreResult = DIVIDE(__StoreNumeratorAct, __StoreDenominator) - 1` 结构不变即自然匹配新口径——分子 = Act Base Value（Step1+Step2 分步）；分母 = Store Base Value 单步（__TTL_*）；ACV/Freq. 分子复用 Act Base Value 的 COUNTROWS(Step 1 集合)，数值等价口径文档 vs Store 分子的 Step 2 区间 count(distinct user_id)（end period 当月 ⊆ 所选范围，集合用户在区间内必有记录）；ACV/AUR vs Store 汇率分子分母同除 __FXRate 抵消；BLANK/0 分母保护依然有效
  - **§4.8 Cell Display 新增格式**: currency_M_K_Int_0db——值 < 1,000 → 货币符号+千分位整数（¥999）；1,000 ≤ 值 < 1M → 货币符号+K 单位 1 位小数（¥1.5K）；值 ≥ 1M → 货币符号+M 单位 1 位小数（¥1.5M）；嵌套 IF + FORMAT 实现，插入货币格式区（currency_k 之后）
  - **文档同步**: 头部 revised 2026-09-15 行；§1.6 重写（vs Store 全客对比——全客分母单步）；§3.2 架构图 Store Base Value 框；§3.7 格式表新增 currency_M_K_Int_0db 行；§4.6 总路由 vs Store 注释块与分母注释；§5 度量值清单第 4 行；§6 血缘图 Store Base Value 框（双口径）；§7 item 6 重写 + item 12 更新
- **关联文件**:
  - `VIC/5 VIC Breakdown/VIC_Breakdown_ms.md`
  - 口径依据: `口径文档/VIC/VIC vs Store.sql`、`口径文档/VIC/VIC Breakdown KPI.md`（2026-09-15 修订版）
- **备注**:
  - 落实上一条目（口径文档修订）备注中"解决方案 §4.5 需按新口径改写"事项
  - SLS% 分母维持分步（VIC vs Store.sql 未覆盖 SLS%），如数据方后续确认 SLS% 也需单步，仅需将 SWITCH 中 4/5/6/26/27/28 分支的 __SLS_Store 引用改为单步实现（演进记录块有说明）
  - currency_M_K_Int_0db 当前无指标使用（预留格式），如需启用在 Dim_ColMetric_New_Retention_VIC 的 Metric_Format 字段配置即可
---

## [2026-09-21 15:51] DAX 修改 — VIC_KPIs_Table.md is_member 筛选重构 + VIC Retention% 分母口径调整（含口径文档同步）

- **模块**: VIC（1 VIC KPI）
- **任务**: IsMemberFilter 切片器逻辑调整（is_member=1 时事实表筛选改用 is_member=0 AND register_date <= end_period_date）+ VIC Retention%（Metric_ID=6）分母口径调整（end period 当月 last_fy_net_pay_amt >= 20000）
- **操作**: 修改
- **变更内容**:
  - **is_member 筛选重构（Act/LY/LP 三个 Base Value 全量生效）**:
    - 新增 `__EndPeriodDate` 变量：Member VIC（IsMember=1）时取对应期 end period 末日（Act=Last_Fiscal_Month_Max / LY=Last_Fiscal_Month_Max_LY / LP=Last_Fiscal_Month_Max_LP），TTL VIC 时取哨兵日期 DATE(9999,12,31) 恒真不设限
    - 事实表谓词统一改为 `is_member = 0` + `register_date <= __EndPeriodDate`（TTL VIC 逻辑不变；Member VIC 不再筛 is_member=1，改用注册日期界定会员人群）；共 15 处 CALCULATE 谓词（3 个度量值 × 5 处：4 个基础聚合 + Metric_ID=6 分母）
    - 旧分母块注释（Rolling 12 / 单月偏移两代旧逻辑）全部删除，不再保留（用户要求）
  - **VIC Retention% 分母口径调整（Metric_ID=6，分子不变）**: 分母由"往前推 12 个月的单月 is_vic=1 人数"改为"对应期 end period 当月 last_fy_net_pay_amt >= 20000 的 count(distinct user_id)"（Act/LY/LP 各取各自期 end period 当月区间 [Last_Fiscal_Month_Min(_LY/_LP), Last_Fiscal_Month_Max(_LY/_LP)]；不再筛 is_vic=1，不再做财月字符串 EDATE 偏移推导目标月）
  - **文档同步（VIC_KPIs_Table.md）**: 头部 revised 2026-09-21 行；§1.2 is_member 筛选规则表；§1.4 分母定义重写；§2.1/§2.2 关键字段与维度表清单；§3.1/§3.2/§3.3/§3.6；§4.1 表 Metric_ID=6 行；§4.2/§4.3/§4.4 标题+头部注释+VAR区+基础聚合+Retention块+SWITCH注释；§4.5 总路由派生注释+TAR ACH% 实际值注释；§5 度量值清单；§6 血缘图（字段清单+内化描述）；§7 item 2/4/6/14
  - **口径文档同步（VIC KPI.md）**: 头部新增 2026-09-21 口径修订行；模块全局影响说明/is_member使用（头部引用块+全局逻辑表共 4 处）更新 Member VIC 筛选描述；§2 VIC Retention% 业务定义/计算公式/分母行重写 + 分母目标月基准块改为分母期间基准块（含历史口径沿革）
- **关联文件**:
  - `VIC/1 VIC KPI/VIC_KPIs_Table.md`
  - `口径文档/VIC/VIC KPI.md`
- **备注**:
  - TAR ACH%（Metric_ID=9）实际值复用 Act Base Value(Metric_ID=6)，自动继承新口径，无需改 DAX
  - 其他 VIC 模块（VIC_Segment_Table.md / VIC_Breakdown_ms.md / VIC_Breakdown_Trend.md 等）同样使用 IsMemberFilter[IsMember] 直筛事实表 is_member 的模式，本次未调整；如需同步 is_member=0+register_date 新规则，需另行确认
  - Share 类指标分母（end period 当月 is_vic=1）不受本次调整影响（VIC_KPIs_Table.md §7 item 5）
---

## [2026-09-21 16:04] DAX 修改 — LY Last Purchase Time 会员筛选调整，Retention% 保持原口径（含口径文档同步）

- **模块**: VIC（3 LY Last Purchase Time）
- **任务**: 按用户最终确认结果调整会员筛选，并明确本模块 Retention% 与 VIC KPI 模块 VIC Retention% 的口径区别
- **操作**: 修改
- **变更内容**:
  - **会员筛选调整（6 个基础度量值）**: `_LY VIC No. Base Act / Base LY`、`_VIC Repurchase No. Base Act / Base LY`、`_VIC Retention No. Base Act / Base LY` 均保留 `SELECTEDVALUE(IsMemberFilter[IsMember], 0)`；TTL VIC（0）维持事实表 `is_member = 0`，不追加注册日期限制；Member VIC（1）改为事实表 `is_member = 0 AND register_date <= end_period_date`。
  - **期间对应与筛选保留**: 本期注册截止日取 `Slicer_Time_Frame_Max[Last_Fiscal_Month_Max]`，LY 取 `Last_Fiscal_Month_Max_LY`，包含截止当天；使用 `KEEPFILTERS` 保留已有注册日期筛选。员工、行分组和 end period 当月时间筛选保持不变，本文件不涉及 LP。
  - **Retention% 原口径恢复**: 本模块为 `Retention% = Retention No. / LY VIC No.`，不适用 VIC KPI 模块的 VIC Retention% 分母调整。`VIC Retention% Value` 恢复引用 `_VIC Retention No. Base Act` / `_LY VIC No. Base Act`；`VIC Retention% YOY Value` 的本期、LY 比率均恢复复用各自期间的 Retention No. / LY VIC No.，再计算今年 / 去年 - 1。分子仍筛选 `is_fy_retention_vic = 1`，分母仍筛选 `is_fy_vic = 1` 后对 `user_id` 去重计数。
  - **清理误增实现**: 删除本轮曾误增的 `_VIC Retention Denominator Base Act / Base LY` 及金额门槛分母相关引用、字段依赖、说明和验证用例；最终维持 6 个 Base、7 个 Value、7 个 Display，共 20 个度量值。复购率公式、Display 格式和空值保护保持不变，不保留旧逻辑注释。
  - **文档同步**: 更新解决方案的会员规则、指标公式、依赖注释、度量值清单、血缘图和验收用例；原始口径文档同步会员筛选与 Retention% 定义，明确现有 `VIC Retention%` / `VIC Retention No.` 命名保留，但业务口径不与 VIC KPI 模块混用。
- **关联文件**:
  - `VIC/3 LY Last Purchase Time/LY_Last_Purchase_Time_Table.md`
  - `口径文档/VIC/LY Last Purchase Time.md`
- **备注**:
  - 用户已确认最终方案；`IsMemberFilter` 维度表及日期维度表未修改。
  - 已完成静态核对：6 处会员注册日期筛选保留，误增专用分母及金额条件无残留，Retention% 与 YOY 引用恢复；`git diff --check` 通过，未在 Power BI DAX 引擎中执行验证。
---

## [2026-09-21 16:13] 知识沉淀 — 模块关键点提炼.md 新增第 17 点：哨兵日期恒真模式

- **模块**: 项目配置（模版复用知识库）
- **任务**: 将 VIC_KPIs_Table.md is_member 筛选重构中的"哨兵日期恒真模式"（register_date 上限变量化 __EndPeriodDate）沉淀为通用关键点，供后续 AI 对话关键词输入
- **操作**: 修改
- **变更内容**:
  - 六、关键指标计算逻辑新增第 17 点"哨兵日期恒真模式：register_date 上限变量化（TTL 档谓词恒真）"，紧接第 16 点（同业务的 KEEPFILTERS + OR 实现）之后，含：核心机制（变量级开关 + DATE(9999,12,31) 哨兵恒真）、VAR 定义区完整 DAX 示例、开关与谓词效果对照表、与第 16 点的选型对照表（开关位置/同列筛选关系/谓词书写/适用场景 4 维度）、复用边界（Act/LY/LP 期间字段切换、哨兵值前提、BLANK 语义、只复用筛选模式）
- **关联文件**:
  - `模版复用/模块关键点提炼.md`
  - 模式来源: `VIC/1 VIC KPI/VIC_KPIs_Table.md`
- **备注**:
  - 第 16 点（KEEPFILTERS + OR，行级开关）与第 17 点（哨兵日期，变量级开关）为同一业务（IsMember 模式开关 + register_date 上限）的两种实现，选型对照表已注明各自适用场景：外部存在 register_date 筛选需保留交集时选第 16 点；度量值全权接管谓词、多 CALCULATE/多期别统一书写时选第 17 点
---

## [2026-09-21 16:23] DAX 修改 — VIC Segment 会员筛选调整（含口径文档同步）

- **模块**: DAX / VIC（4 VIC Segment）
- **任务**: 将 VIC Segment 的会员筛选统一为事实表 is_member=0，Member VIC 追加 register_date 不晚于对应期间最后财月末，并保留既有指标计算口径
- **操作**: 修改
- **变更内容**:
  - **12 个基础度量值、20 处筛选**: `_Customer No. Base Act / Base LY`、`_Customer Total Base Act / Base LY` 各 1 处；`_SLS Base Act / Base LY`、`_SLS Total Base Act / Base LY`、`_Net Pay Qty Base Act / Base LY`、`_Net Pay Order Cnt Base Act / Base LY` 的 Step 1 / Step 2 各 1 处。
  - **会员模式**: 保留 `SELECTEDVALUE(IsMemberFilter[IsMember], 0)`；两档事实表均筛 `is_member = 0`。TTL VIC（0）不追加注册日期限制；Member VIC（1）使用 `KEEPFILTERS(__IsMemberFilter = 0 || register_date <= 对应财月末)` 与已有注册日期筛选取交集，不增加注册日期下限。
  - **期间对应**: Act 注册截止日读取 `Slicer_Time_Frame_Max[Last_Fiscal_Month_Max]`，LY 读取 `Last_Fiscal_Month_Max_LY`；Customer 单步分别使用 `__PeriodMax / __LYMax`，双步两阶段分别使用 `__EndPeriodMax / __EndPeriodMax_LY`，不误用 Step 2 的 `TimeFrame_Max / TimeFrame_Max_LY`。本模块无 LP，不新增 LP 分支。
  - **保持原计算**: Step1 end period 框定用户、Step2 所选完整区间聚合，以及员工筛选、TREATAS、分组关系、占比分母 ALLSELECTED、全部 Value / Display / SVG 代码不变；本模块不涉及 VIC Retention%，不变更指标分子、分母公式。
  - **文档与清理**: 同步方案会员规则、register_date 字段依赖、Base 注释、筛选上下文、血缘字段及验收用例；原口径头部、全局规则、12 个指标筛选条件和汇总同步。删除受影响 Base 中 6 段历史合并计算块注释及其回退指引，不新增旧逻辑注释。
- **关联文件**:
  - `VIC/4 VIC Segment/VIC_Segment_Table.md`
  - `口径文档/VIC/VIC Segment.md`
- **备注**:
  - 静态核验：20/20 处会员条件覆盖；去除注释与会员谓词后 Base 代码与修改前一致，12 个 Value、12 个 Display、2 个 SVG 代码块无变化；两份文档无旧会员直筛映射残留，`git diff --check` 通过。
  - 未运行 Power BI DAX 引擎；实际模型需确认 register_date 与财月末字段为 Date 且日期切片器提供有效单值。未新增非空过滤，BLANK 注册日期可能通过 <= 比较，其业务处理需另行确认。
  - `IsMemberFilter`、事实查询、日期维度和模型关系未修改。
---

## [2026-09-21 16:35] DAX 修改 — VIC_Trend.md is_member 筛选重构 + VIC Retention% 分母口径调整（含口径文档同步）

- **模块**: VIC（2 VIC Trend）
- **任务**: 与 VIC_KPIs_Table.md 同步两项口径调整：IsMemberFilter 切片器逻辑（is_member=1 时事实表筛选改用 is_member=0 AND register_date <= X 轴 end period 末日）+ VIC Retention%（Metric_ID=6）分母口径调整（end period 当月 last_fy_net_pay_amt >= 20000）
- **操作**: 修改
- **变更内容**:
  - **is_member 筛选重构（9 个基础度量值全量生效: VIC No. / VIC Retention% / T4-5 Upgrade No. 各 Act/LY/LP）**:
    - 各度量值新增 `__EndPeriodDate` 变量：Member VIC（IsMember=1）时取 X 轴对应期 end period 末日（Act=Last_Fiscal_Month_Max / LY=Last_Fiscal_Month_Max_LY / LP=Last_Fiscal_Month_Max_LP，均读自 Slicer_Time_Frame_VIC_Trend 行级字段），TTL VIC 时取哨兵日期 DATE(9999,12,31) 恒真不设限
    - 事实表谓词统一改为 `is_member = 0` + `register_date <= __EndPeriodDate`，共 12 处 CALCULATE 谓词（VIC No. 3 处 + Retention 分子/分母 6 处 + T4-5 3 处）
  - **VIC Retention% 分母口径调整（分子不变）**: 分母由"往前推 12 个月的单月 is_vic=1 人数（EDATE 目标月推导）"改为"X 轴对应期 end period 当月 last_fy_net_pay_amt >= 20000 的 count(distinct user_id)"（Act/LY/LP 各取 X 轴当前柱对应期 end period 当月区间，与分子同期间同人群；不再筛 is_vic=1、不再做目标月字符串推导）
  - **旧逻辑清理**: 三个 Retention% 度量值中 Rolling 12 区间块注释（2026-09-14 弃用版）与"往前推 12 个月单月"现行旧逻辑（EDATE 推导约 40 行/处）全部删除，共 -273 行，不再保留（用户要求）
  - **文档同步（VIC_Trend.md）**: 头部 revised 2026-09-21 行；§1 需求表 Metric_ID=6 行 + 核心设计原则；§1.3 分母节整节重写（含历史沿革）；§2.1 关键字段加 register_date/last_fy_net_pay_amt；§3.1 筛选上下文表 2 行；§3.2 架构图；§4.2-4.10 标题+注释头+VAR区+谓词；指标 6 引言 + §4.17/§4.19/§4.21 依赖注释；§7.1/§7.2 验证 SQL；§8 item 4/6/7
  - **口径文档同步（VIC KPI.md）**: is_member 使用说明 2 处（头部引用块+全局逻辑表）补充"VIC Trend 柱形图中上述期末日取 X 轴各柱自己的时间点"；§2 分母期间基准块新增 VIC Trend 柱形图适配说明
- **关联文件**:
  - `VIC/2 VIC Trend/VIC_Trend.md`
  - `口径文档/VIC/VIC KPI.md`
- **备注**:
  - 每柱独立计算：与主表（Slicer_Time_Frame_Max 全局 end period）不同，本方案 end period/register_date 上限/分母区间均基于 X 轴各柱自己的时间点
  - Metric_ID=14（T4-5 Upgrade No. Share）分母复用 [VIC No. Trend Act Value]，自动继承 is_member 新口径；Share 类分母本身不变
  - 静态核验：旧谓词 `is_member = __IsMemberFilter` 0 残留；新谓词 12+12 处一一配对；__EndPeriodDate 9 处定义（Act/LY/LP 取值各 3 处）；未运行 Power BI DAX 引擎
---

## [2026-09-21 16:47] DAX 修改 — VIC_KPIs_Pie_Chart.md is_member 筛选重构（仅 is_member，不涉及 Retention%）

- **模块**: VIC（1 VIC KPI / Pie Chart）
- **任务**: 与 VIC_KPIs_Table.md 同步 is_member 筛选重构；本方案仅本期 Act 快照、无比率指标（Retention VIC No. 为人数口径，即 VIC Retention% 分子，分子口径不变），不涉及 VIC Retention% 分母调整
- **操作**: 修改
- **变更内容**:
  - **is_member 筛选重构（3 个 Value 度量: T4-5 Upgrade No. / Retention VIC No. / Direct VIC No. Pie Value）**:
    - 各度量值新增 `__EndPeriodDate` 变量：Member VIC（IsMember=1）时取 `Slicer_Time_Frame_Max[Last_Fiscal_Month_Max]`（全局 end period 末日，与主表 Act 一致），TTL VIC 时取哨兵日期 DATE(9999,12,31) 恒真不设限
    - 事实表谓词统一改为 `is_member = 0` + `register_date <= __EndPeriodDate`，共 3 处 CALCULATE 谓词
  - **文档同步（VIC_KPIs_Pie_Chart.md）**: 头部新增 revised 2026-09-21 行；§2.1 关键字段加 register_date；§3.1 IsMemberFilter 筛选行；§4.1/4.3/4.5 注释头+VAR区+谓词；§7.1 验证 SQL 补充 Member VIC register_date 说明；§8 item 3
- **关联文件**:
  - `VIC/1 VIC KPI/VIC_KPIs_Pie_Chart.md`
- **备注**:
  - Display 度量（§4.2/4.4/4.6）仅引用 Value 度量，自动继承新口径，无需修改
  - 口径文档 VIC KPI.md 无需同步：is_member 使用说明已覆盖"本期取 Last_Fiscal_Month_Max"，本方案与主表 Act 同源；§4 Retention VIC No.（人数）定义不涉及分母
  - 静态核验：旧谓词 0 残留；新谓词 3+3 处一一配对；未运行 Power BI DAX 引擎
---

## [2026-09-22 17:27] DAX 修改 — VIC Segment SUM 类按 end period Tier 归属

- **模块**: VIC（4 VIC Segment）
- **任务**: 对齐用户提供的 SQL：期末按 customer_tier 圈定 user_id，再汇总所选区间，不限制历史 Tier
- **操作**: 修改
- **变更内容**:
  - `_SLS Base Act/LY`、`_Net Pay Qty Base Act/LY`、`_Net Pay Order Cnt Base Act/LY`：Step1 保持期末 Tier 圈人；Step2 外层 CALCULATE 移除维度表及事实表 customer_tier 筛选，内层应用原日期、人群条件和 TREATAS 聚合，避免历史 Tier 限制及同层筛选参数提前求值影响。
  - `_SLS Total Base Act/LY`：SUMX 遍历 ALLSELECTED 保留的非空 Tier，逐行复用对应 SLS Base 后加总，保持 Total = 选中 Tier 行金额之和。
  - Customer No./Customer Total Act/LY 不变；SLS、ACV、AUR、UPT、Freq.、SLS% 及相关同比通过基础度量自动继承。会员、员工、注册日期、平台、门店、日期与 Value/Display 公式保留。
  - 同步现有口径文档、分组说明、必要注释及简要核对要点；直接更新新逻辑，不保留旧 DAX 块注释。
- **关联文件**:
  - `VIC/4 VIC Segment/VIC_Segment_Table.md`
  - `口径文档/VIC/VIC Segment.md`
- **备注**: 按用户要求简化验证，仅作必要文本核对；未在 Power BI 模型中实测，实际数值需在相同筛选下与 SQL 对照。

---
