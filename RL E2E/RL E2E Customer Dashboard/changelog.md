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
