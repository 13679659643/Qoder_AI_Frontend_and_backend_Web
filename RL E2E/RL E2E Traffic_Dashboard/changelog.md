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
