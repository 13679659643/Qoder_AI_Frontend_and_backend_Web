# KPIs Measure 测试案例 — 总计行（total）

> 用途: 对比 PowerBI 页面总计行与数据库计算值是否一致
> 测试范围: KPIs_Measure_solution.md §2.2~§2.9（#6~#13，共 8 个指标）
> 数据库: MySQL (StarRocks 兼容语法)
> 创建时间: 2026-07-15

---

## 1. 测试筛选条件

| 筛选器 | 值 | 说明 |
| ------ | -- | ---- |
| platform | 'TM' | 平台筛选器 |
| stroe_name | 'TM' | 店铺筛选器 |
| trans_cycle | 'T+1' | 数据周期 |
| data_date | '2026-01-01' ~ '2026-07-20' | 时间范围（本期） |
| currency | 'RMB' | 货币（汇率=1，金额类指标无需转换） |

**总计行特点说明**：
- 总计行无任何行维度分组，相当于全量聚合
- #8 Cost% 引力魔方、#12 Cost% 直通车 在总计行下分子=分母（REMOVEFILTERS 无行维度可移除），结果恒为 100%
- #7、#11 分母虽包含四渠道（引力魔方/直通车/快车/触点），但 TM 平台只有引力魔方+直通车，实际分母为这两渠道之和

---

## 2. 单指标测试 SQL

### 2.1 #6 Cost 引力魔方

```sql
-- ============================================
-- 指标: #6 Cost 引力魔方
-- 口径: SUM(cost_amt), channel='引力魔方'
-- 底表: `indep_rl_ads`.a05_e2e_paid_media_crowed_data_d（引力魔方下钻表）
-- 数据类型: currency（RMB 汇率=1，无需转换）
-- 预期: 总计行 = 全量 SUM(cost_amt)
-- ============================================
SELECT
    '#6 Cost 引力魔方' AS metric_name,
    SUM(cost_amt) AS db_value
FROM `indep_rl_ads`.a05_e2e_paid_media_crowed_data_d
WHERE platform = 'TM'
    AND stroe_name = 'TM'
    AND trans_cycle = 'T+1'
    AND data_date BETWEEN '2026-01-01' AND '2026-07-20'
    AND channel = '引力魔方';
```

### 2.2 #7 Cost 引力魔方 触点占比

```sql
-- ============================================
-- 指标: #7 Cost 引力魔方 触点占比
-- 口径: cost_amt(channel IN {'引力魔方','触点'}) / cost_amt(channel IN {'引力魔方','直通车','快车','触点'})
-- 底表: `indep_rl_ads`.a05_e2e_paid_media_crowed_data_d
-- 数据类型: percent_0dp
-- 说明: TM 平台只有引力魔方(无触点)，分母含引力魔方+直通车(TM 下无快车/触点)
--       但 DAX 分母用四渠道 IN，实际数据由 platform 筛选器自动过滤
--       这里按 DAX 口径写，分母四渠道 IN，让数据自行过滤
-- ============================================
-- 分子
SELECT
    '#7 分子 (引力魔方/触点)' AS metric_name,
    SUM(cost_amt) AS db_value
FROM `indep_rl_ads`.a05_e2e_paid_media_crowed_data_d
WHERE platform = 'TM'
    AND stroe_name = 'TM'
    AND trans_cycle = 'T+1'
    AND data_date BETWEEN '2026-01-01' AND '2026-07-20'
    AND channel IN ('引力魔方', '触点');

-- 分母
SELECT
    '#7 分母 (四渠道)' AS metric_name,
    SUM(cost_amt) AS db_value
FROM `indep_rl_ads`.a05_e2e_paid_media_crowed_data_d
WHERE platform = 'TM'
    AND stroe_name = 'TM'
    AND trans_cycle = 'T+1'
    AND data_date BETWEEN '2026-01-01' AND '2026-07-20'
    AND channel IN ('引力魔方', '直通车', '快车', '触点');

-- 最终值（分子/分母）
SELECT
    '#7 Cost 引力魔方 触点占比' AS metric_name,
    ROUND(
        SUM(CASE WHEN channel IN ('引力魔方', '触点') THEN cost_amt ELSE 0 END) /
        NULLIF(SUM(CASE WHEN channel IN ('引力魔方', '直通车', '快车', '触点') THEN cost_amt ELSE 0 END), 0),
        6
    ) AS db_value
FROM `indep_rl_ads`.a05_e2e_paid_media_crowed_data_d
WHERE platform = 'TM'
    AND stroe_name = 'TM'
    AND trans_cycle = 'T+1'
    AND data_date BETWEEN '2026-01-01' AND '2026-07-20';
```

### 2.3 #8 Cost% 引力魔方

```sql
-- ============================================
-- 指标: #8 Cost% 引力魔方
-- 口径: TA层级 Cost / TTL Cost（REMOVEFILTERS 移除行维度）
-- 底表: `indep_rl_ads`.a05_e2e_paid_media_crowed_data_d
-- 数据类型: percent_1dp
-- 总计行预期: 100%（分子=分母，无行维度筛选）
-- ============================================
-- 验证: 总计行下分子=分母，结果应为 1.0 (100%)
SELECT
    '#8 Cost% 引力魔方 (总计行预期100%)' AS metric_name,
    ROUND(
        SUM(CASE WHEN channel = '引力魔方' THEN cost_amt ELSE 0 END) /
        NULLIF(SUM(CASE WHEN channel = '引力魔方' THEN cost_amt ELSE 0 END), 0),
        6
    ) AS db_value
FROM `indep_rl_ads`.a05_e2e_paid_media_crowed_data_d
WHERE platform = 'TM'
    AND stroe_name = 'TM'
    AND trans_cycle = 'T+1'
    AND data_date BETWEEN '2026-01-01' AND '2026-07-20';
-- 预期结果: 1.000000 (即 100%)
```

### 2.4 #9 ROI 引力魔方

```sql
-- ============================================
-- 指标: #9 ROI 引力魔方
-- 口径: SUM(sales_amt) / SUM(cost_amt), channel='引力魔方'
-- 底表: `indep_rl_ads`.a05_e2e_paid_media_crowed_data_d
-- 数据类型: decimal_1dp
-- 说明: ROI = Sales / Cost，不受汇率影响（分子分母同币种）
-- ============================================
SELECT
    '#9 ROI 引力魔方' AS metric_name,
    ROUND(
        SUM(sales_amt) / NULLIF(SUM(cost_amt), 0),
        6
    ) AS db_value
FROM `indep_rl_ads`.a05_e2e_paid_media_crowed_data_d
WHERE platform = 'TM'
    AND stroe_name = 'TM'
    AND trans_cycle = 'T+1'
    AND data_date BETWEEN '2026-01-01' AND '2026-07-20'
    AND channel = '引力魔方';
```

### 2.5 #10 Cost 直通车

```sql
-- ============================================
-- 指标: #10 Cost 直通车
-- 口径: SUM(cost_amt), channel='直通车'
-- 底表: `indep_rl_ads`.a05_e2e_paid_media_keyword_data_d（直通车下钻表）
-- 数据类型: currency（RMB 汇率=1，无需转换）
-- 预期: 总计行 = 全量 SUM(cost_amt)
-- ============================================
SELECT
    '#10 Cost 直通车' AS metric_name,
    SUM(cost_amt) AS db_value
FROM `indep_rl_ads`.a05_e2e_paid_media_keyword_data_d
WHERE platform = 'TM'
    AND stroe_name = 'TM'
    AND trans_cycle = 'T+1'
    AND data_date BETWEEN '2026-01-01' AND '2026-07-20'
    AND channel = '直通车';
```

### 2.6 #11 Cost 直通车 快车占比

```sql
-- ============================================
-- 指标: #11 Cost 直通车 快车占比
-- 口径: cost_amt(channel IN {'直通车','快车'}) / cost_amt(channel IN {'引力魔方','直通车','快车','触点'})
-- 底表: `indep_rl_ads`.a05_e2e_paid_media_keyword_data_d
-- 数据类型: percent_0dp
-- 说明: TM 平台只有直通车(无快车)，分母含引力魔方+直通车(TM 下无快车/触点)
--       DAX 分母用四渠道 IN，实际数据由 platform 筛选器自动过滤
-- ============================================
-- 分子
SELECT
    '#11 分子 (直通车/快车)' AS metric_name,
    SUM(cost_amt) AS db_value
FROM `indep_rl_ads`.a05_e2e_paid_media_keyword_data_d
WHERE platform = 'TM'
    AND stroe_name = 'TM'
    AND trans_cycle = 'T+1'
    AND data_date BETWEEN '2026-01-01' AND '2026-07-20'
    AND channel IN ('直通车', '快车');

-- 分母
SELECT
    '#11 分母 (四渠道)' AS metric_name,
    SUM(cost_amt) AS db_value
FROM `indep_rl_ads`.a05_e2e_paid_media_keyword_data_d
WHERE platform = 'TM'
    AND stroe_name = 'TM'
    AND trans_cycle = 'T+1'
    AND data_date BETWEEN '2026-01-01' AND '2026-07-20'
    AND channel IN ('引力魔方', '直通车', '快车', '触点');

-- 最终值（分子/分母）
SELECT
    '#11 Cost 直通车 快车占比' AS metric_name,
    ROUND(
        SUM(CASE WHEN channel IN ('直通车', '快车') THEN cost_amt ELSE 0 END) /
        NULLIF(SUM(CASE WHEN channel IN ('引力魔方', '直通车', '快车', '触点') THEN cost_amt ELSE 0 END), 0),
        6
    ) AS db_value
FROM `indep_rl_ads`.a05_e2e_paid_media_keyword_data_d
WHERE platform = 'TM'
    AND stroe_name = 'TM'
    AND trans_cycle = 'T+1'
    AND data_date BETWEEN '2026-01-01' AND '2026-07-20';
```

### 2.7 #12 Cost% 直通车

```sql
-- ============================================
-- 指标: #12 Cost% 直通车
-- 口径: 关键词层级 Cost / TTL Cost（REMOVEFILTERS 移除行维度）
-- 底表: `indep_rl_ads`.a05_e2e_paid_media_keyword_data_d
-- 数据类型: percent_1dp
-- 总计行预期: 100%（分子=分母，无行维度筛选）
-- ============================================
-- 验证: 总计行下分子=分母，结果应为 1.0 (100%)
SELECT
    '#12 Cost% 直通车 (总计行预期100%)' AS metric_name,
    ROUND(
        SUM(CASE WHEN channel = '直通车' THEN cost_amt ELSE 0 END) /
        NULLIF(SUM(CASE WHEN channel = '直通车' THEN cost_amt ELSE 0 END), 0),
        6
    ) AS db_value
FROM `indep_rl_ads`.a05_e2e_paid_media_keyword_data_d
WHERE platform = 'TM'
    AND stroe_name = 'TM'
    AND trans_cycle = 'T+1'
    AND data_date BETWEEN '2026-01-01' AND '2026-07-20';
-- 预期结果: 1.000000 (即 100%)
```

### 2.8 #13 ROI 直通车

```sql
-- ============================================
-- 指标: #13 ROI 直通车
-- 口径: SUM(sales_amt) / SUM(cost_amt), channel='直通车'
-- 底表: `indep_rl_ads`.a05_e2e_paid_media_keyword_data_d
-- 数据类型: decimal_1dp
-- 说明: ROI = Sales / Cost，不受汇率影响（分子分母同币种）
-- ============================================
SELECT
    '#13 ROI 直通车' AS metric_name,
    ROUND(
        SUM(sales_amt) / NULLIF(SUM(cost_amt), 0),
        6
    ) AS db_value
FROM `indep_rl_ads`.a05_e2e_paid_media_keyword_data_d
WHERE platform = 'TM'
    AND stroe_name = 'TM'
    AND trans_cycle = 'T+1'
    AND data_date BETWEEN '2026-01-01' AND '2026-07-20'
    AND channel = '直通车';
```

---

## 3. 一键对比 SQL（UNION ALL 汇总）

将 8 个指标的数据库计算值一次性输出，方便与 PowerBI 页面总计行逐行比对。

```sql
-- ============================================
-- 一键对比: 8 个指标总计行数据库值
-- 筛选: platform='TM' AND stroe_name='TM' AND trans_cycle='T+1'
--       AND data_date BETWEEN '2026-01-01' AND '2026-07-20'
--       AND currency='RMB' (汇率=1)
-- 使用 UNION ALL 汇总，每行一个指标
-- ============================================

-- 引力魔方指标（底表: `indep_rl_ads`.a05_e2e_paid_media_crowed_data_d）
SELECT
    '#6 Cost 引力魔方' AS metric_name,
    SUM(cost_amt) AS db_value
FROM `indep_rl_ads`.a05_e2e_paid_media_crowed_data_d
WHERE platform = 'TM' AND stroe_name = 'TM' AND trans_cycle = 'T+1'
    AND data_date BETWEEN '2026-01-01' AND '2026-07-20'
    AND channel = '引力魔方'

UNION ALL

SELECT
    '#7 Cost 引力魔方 触点占比' AS metric_name,
    ROUND(
        SUM(CASE WHEN channel IN ('引力魔方', '触点') THEN cost_amt ELSE 0 END) /
        NULLIF(SUM(CASE WHEN channel IN ('引力魔方', '直通车', '快车', '触点') THEN cost_amt ELSE 0 END), 0),
        6
    ) AS db_value
FROM `indep_rl_ads`.a05_e2e_paid_media_crowed_data_d
WHERE platform = 'TM' AND stroe_name = 'TM' AND trans_cycle = 'T+1'
    AND data_date BETWEEN '2026-01-01' AND '2026-07-20'

UNION ALL

SELECT
    '#8 Cost% 引力魔方 (预期100%)' AS metric_name,
    1.000000 AS db_value  -- 总计行下分子=分母，恒为 100%

UNION ALL

SELECT
    '#9 ROI 引力魔方' AS metric_name,
    ROUND(
        SUM(sales_amt) / NULLIF(SUM(cost_amt), 0),
        6
    ) AS db_value
FROM `indep_rl_ads`.a05_e2e_paid_media_crowed_data_d
WHERE platform = 'TM' AND stroe_name = 'TM' AND trans_cycle = 'T+1'
    AND data_date BETWEEN '2026-01-01' AND '2026-07-20'
    AND channel = '引力魔方'

-- 直通车指标（底表: `indep_rl_ads`.a05_e2e_paid_media_keyword_data_d）
UNION ALL

SELECT
    '#10 Cost 直通车' AS metric_name,
    SUM(cost_amt) AS db_value
FROM `indep_rl_ads`.a05_e2e_paid_media_keyword_data_d
WHERE platform = 'TM' AND stroe_name = 'TM' AND trans_cycle = 'T+1'
    AND data_date BETWEEN '2026-01-01' AND '2026-07-20'
    AND channel = '直通车'

UNION ALL

SELECT
    '#11 Cost 直通车 快车占比' AS metric_name,
    ROUND(
        SUM(CASE WHEN channel IN ('直通车', '快车') THEN cost_amt ELSE 0 END) /
        NULLIF(SUM(CASE WHEN channel IN ('引力魔方', '直通车', '快车', '触点') THEN cost_amt ELSE 0 END), 0),
        6
    ) AS db_value
FROM `indep_rl_ads`.a05_e2e_paid_media_keyword_data_d
WHERE platform = 'TM' AND stroe_name = 'TM' AND trans_cycle = 'T+1'
    AND data_date BETWEEN '2026-01-01' AND '2026-07-20'

UNION ALL

SELECT
    '#12 Cost% 直通车 (预期100%)' AS metric_name,
    1.000000 AS db_value  -- 总计行下分子=分母，恒为 100%

UNION ALL

SELECT
    '#13 ROI 直通车' AS metric_name,
    ROUND(
        SUM(sales_amt) / NULLIF(SUM(cost_amt), 0),
        6
    ) AS db_value
FROM `indep_rl_ads`.a05_e2e_paid_media_keyword_data_d
WHERE platform = 'TM' AND stroe_name = 'TM' AND trans_cycle = 'T+1'
    AND data_date BETWEEN '2026-01-01' AND '2026-07-20'
    AND channel = '直通车';
```

---

## 4. 对比验证表模板

执行上述一键对比 SQL 后，将数据库值与 PowerBI 页面总计行值填入下表进行比对：

| Metric_ID | 指标名称 | PowerBI 页面值 | 数据库值 | 是否一致 | 差异说明 |
| --------- | -------- | -------------- | -------- | -------- | -------- |
| 6 | Cost 引力魔方 | | | | |
| 7 | Cost 引力魔方 触点占比 | | | | |
| 8 | Cost% 引力魔方 | | | | |
| 9 | ROI 引力魔方 | | | | |
| 10 | Cost 直通车 | | | | |
| 11 | Cost 直通车 快车占比 | | | | |
| 12 | Cost% 直通车 | | | | |
| 13 | ROI 直通车 | | | | |

**一致性判定标准**：
- 金额类指标（#6、#10）：允许 ±1 误差（千分位四舍五入）
- 百分比类指标（#7、#8、#11、#12）：允许 ±0.1% 误差（格式化精度）
- ROI 类指标（#9、#13）：允许 ±0.01 误差（一位小数四舍五入）

---

## 5. 关键说明

### 5.1 汇率处理

本次测试 currency='RMB'，汇率=1，金额类指标（#6、#10）无需除汇率。若测试 USD，SQL 中金额需除以 7：

```sql
-- USD 场景下的金额类指标 SQL 调整
-- SUM(cost_amt) / 7
```

### 5.2 总计行 #8、#12 恒为 100% 的原因

#8 Cost% 引力魔方和 #12 Cost% 直通车的分母使用 `REMOVEFILTERS(crowed_layer, crowed_type, crowed_name)` / `REMOVEFILTERS(category, plan_name, keyword_name)` 移除行维度。总计行下无行维度筛选，分子分母计算范围完全一致，结果恒为 100%。

### 5.3 #7、#11 分母四渠道在 TM 平台下的实际表现

DAX 分母用 `channel IN {'引力魔方','直通车','快车','触点'}`，但 TM 平台只有引力魔方和直通车（JD 平台才有快车和触点）。SQL 按四渠道 IN 编写，platform 筛选器会自动过滤，实际分母 = 引力魔方 + 直通车。

### 5.4 底表分布

| 指标 | 底表 | 说明 |
| ---- | ---- | ---- |
| #6~#9 | `indep_rl_ads`.a05_e2e_paid_media_crowed_data_d | 引力魔方下钻表 |
| #10~#13 | `indep_rl_ads`.a05_e2e_paid_media_keyword_data_d | 直通车下钻表 |

### 5.5 sales_amt 字段说明

DAX 中 #9、#13 的分子使用 `sales_amt` 字段（非 `media_sales_amt`），SQL 同步使用 `sales_amt`。若实际表字段名为 `media_sales_amt`，需替换。
