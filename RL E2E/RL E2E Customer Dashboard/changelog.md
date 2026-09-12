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
