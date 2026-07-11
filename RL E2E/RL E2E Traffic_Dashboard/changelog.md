# 变更日志 — RL E2E Traffic_Dashboard

> 本文件记录 RL E2E Traffic_Dashboard 看板的代码创建与修改历史。
> 看板模块：KPI Progress · Category Growth · New Acquisition
> 口径文档：[KPI Progress.md](./口径文档/KPI%20Progress.md) · [Category Growth.md](./口径文档/Category%20Growth.md) · [New Acquisition.md](./口径文档/New%20Acquisition.md)

---

## 模块索引

| 模块                      | 说明                       | 子板块                                                                                                                                                                                                   |
| ------------------------- | -------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **KPI Progress**          | KPI 进度矩阵模块           | KPIs · Performance Indicators · New Acquisition KPI Trend · Category Growth KPI Trend · KPI by Platform                                                                                                  |
| **Category Growth**       | 品类增长分析模块           | KPI Breakdown                                                                                                                                                                                             |
| **New Acquisition**       | 新用户 acquisition 分析模块 | KPIs · Ads Format Cost% · Controllable Ads Format Cost% Trend · Controllable Ads format breakdown（引力魔方 / 直通车）                                                                                   |

---

## [KPI Progress] 模块

### 子板块：KPIs

---

### 子板块：Performance Indicators

---

### 子板块：New Acquisition KPI Trend

---

### 子板块：Category Growth KPI Trend

---

### 子板块：KPI by Platform

---

---

## [Category Growth] 模块

### 子板块：KPI Breakdown

## [2026-07-10 14:30] 新建 — KPI Breakdown 矩阵解决方案文件

- **模块**: Category Growth > KPI Breakdown
- **任务**: 以 Category Growth.md 口径文档为 SPEC，新增 KPI Breakdown 矩阵解决方案，实现 14 指标 × 4 平台 = 56 列动态矩阵
- **操作**: 新建
- **变更内容**:
  - 新增文件 `KPI Breakdown/KPI_Breakdown_matrix_solution.md`
  - 度量值 `KPI Breakdown Base Value`：列头 SWITCH 分发器，14 指标统一聚合分发
    * 行维度 TREATAS 动态筛选：根据 `Brand-Category-Framework[Scenario_Type]` 动态映射 Level 1/2/3 到事实表 brand/category/framework 字段
    * ISINSCOPE 层级判断：Total 行 / Level 1 / Level 2 / Level 3 四级层级
    * Total 行自定义口径：Cost% vs SLS%=0pt、SLS%=100%、Cost MOB% Total=100%
    * Total 行渠道列口径：Cost MOB% 渠道 = 渠道 cost / 三渠道总 cost；ROI/New Customer Cost% Total 列 = 三渠道汇总、渠道列 = 单渠道自身比值
    * channel 动态映射：TM/RLE/DY → 直通车/引力魔方/全站推；JD → 快车/触点/海投
  - 度量值 `KPI Breakdown Cell Value`：行路由度量值，直接调用 Base Value
  - 度量值 `KPI Breakdown Cell Display`：格式化显示
    * decimal_pt_1（Cost% vs SLS%）→ #,##0.0'pt';-#,##0.0'pt';0.0'pt'
    * percent_1dp（SLS% / Cost MOB%）→ #,##0.0%;#,##0.0%;0.0%
    * decimal_1dp（ROI / New Customer Cost%）→ #,##0.0
  - 度量值 `KPI Breakdown Cell Font Color`：Total 指标列和总计行 #252423，其余 #5F6165
  - 度量值 `KPI Breakdown Cell SVG Icon`：仅 Cost% vs SLS% 显示 SVG 圆形图标（绿/红/黄）
  - 度量值 `KPI Breakdown Cell Background Color`：
    * 明细行（Level 3）→ #F5F5F5
    * 总计行 → #E6D9C7（Total 指标列 #FAF6F1）
    * 其余行 → #FFFFFF（Total 指标列 #FAF6F1）
- **关联文件**: KPI Breakdown/KPI_Breakdown_matrix_solution.md、口径文档/Category Growth.md、KPI Breakdown/Brand-Category-Framework排列组合.sql、KPI Breakdown/Dim_ColMetric_KpiBreakdown、维度复用/Slicer_Time_Frame.sql、维度复用/Slicer_Platform_Selection、维度复用/Slicer_Store_Name、维度复用/Slicer_DataCaliber_Selection、维度复用/Slicer_Currency_Selection
- **备注**: 行维度表 `Brand-Category-Framework` 与事实表断开，通过 DAX 内 TREATAS 动态筛选；列维度表 `Dim_ColMetric_KpiBreakdown` 通过 Platform_ID 一对多关联 Slicer_Platform_Selection；Time_Frame 断开维度通过 TimeFrame_Min/Max 筛选 data_date；Currency 筛选器对本板块不生效（全为比率类指标）

---

## [2026-07-07 16:00] 修改 — Dim_ColMetric_KpiBreakdown 多平台扩展

- **模块**: Category Growth > KPI Breakdown
- **任务**: 新增 JD / RLE / DY 平台指标，对齐口径文档格式与颜色配置
- **操作**: 修改
- **变更内容**:
  - 指标行数 14 → 56（新增 JD 14 行、RLE 14 行、DY 14 行）
  - 平台区分：MetricGroup/MetricName 追加空格（TM 0 / JD 1 / RLE 2 / DY 3）
  - 排序倍数：MetricGroup_Sort/MetricName_Sort（TM ×1 / JD ×10 / RLE ×100 / DY ×1000）
  - JD 渠道映射：直通车→快车、引力魔方→触点、全站推→海投
  - 格式类型对齐 Category Growth.md 口径：Cost% vs SLS% → delta_pt_1dp；SLS%/Cost MOB% → percent_1dp；ROI/New Customer Cost% → decimal_1dp（原 integer/percent）
  - 新增列：Metric_ColorPositive / Metric_ColorNegative / Metric_ColorZero / Metric_ColorDefault（参考 DIM_ColMetric_Keyword_Crowd）
- **关联文件**: KPI Breakdown/Dim_ColMetric_KpiBreakdown、口径文档/Category Growth.md
- **备注**: 未新增 Metric_IsCurrencyAmount（KPI Breakdown 无金额绝对值指标）；RLE/DY 渠道名称与 TM 一致

---

---

## [New Acquisition] 模块

### 子板块：KPIs

---

### 子板块：Ads Format Cost%

---

### 子板块：Controllable Ads Format Cost% Trend

---

### 子板块：Controllable Ads format breakdown — 引力魔方

---

### 子板块：Controllable Ads format breakdown — 直通车

---
