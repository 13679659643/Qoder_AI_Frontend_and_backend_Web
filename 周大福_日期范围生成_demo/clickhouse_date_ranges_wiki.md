# ClickHouse 日期范围生成器 - 技术文档

## 1. 概述

本 SQL 工具用于根据任意输入日期，自动生成四种业务报表所需的日期范围参数，同时输出本期与上期（环比对照期）的完整日期信息，供下游报表系统直接消费。

**适用场景**：周大福运营报表体系中的日期参数自动化生成。

---

## 2. 输入参数

| 参数 | 类型 | 说明 | 示例 |
|------|------|------|------|
| `input_date` | `DATE` | 业务基准日期，通常为当天 | `2026-05-23` |

**使用方式**：

```sql
-- 方式1：指定固定日期（调试/回溯场景）
CAST('2026-05-23' AS DATE) AS input_date

-- 方式2：使用当天日期（生产环境）
today() AS input_date
```

---

## 3. 四种报表类型定义

### 3.1 weekly - 周报

| 项目 | 说明 | 计算公式 |
|------|------|---------|
| **本期开始** | 上周一 | `toMonday(input_date) - 7` |
| **本期结束** | 上周日 | `toMonday(input_date) - 1` |
| **上期开始** | 上上周一 | `toMonday(input_date) - 14` |
| **上期结束** | 上上周日 | `toMonday(input_date) - 8` |

> **对比维度**：周环比（本周 vs 上周 → 上周 vs 上上周）

### 3.2 monthly_cumulative_weekly - 月累计周报

| 项目 | 说明 | 计算公式 |
|------|------|---------|
| **本期开始** | 本月1日 | `toStartOfMonth(input_date)` |
| **本期结束** | 上周日 | `toMonday(input_date) - 1` |
| **上期开始** | 上月1日 | `addMonths(本月1日, -1)` |
| **上期结束** | 上月对应日 | `addMonths(上周日, -1)` |

> **对比维度**：月环比累计（本月截至上周日 vs 上月同期截至日）

### 3.3 monthly - 月报

| 项目 | 说明 | 计算公式 |
|------|------|---------|
| **本期开始** | 上月第一天 | `addMonths(本月1日, -1)` |
| **本期结束** | 上月最后一天 | `本月1日 - INTERVAL 1 DAY` |
| **上期开始** | 上上月第一天 | `addMonths(本月1日, -2)` |
| **上期结束** | 上上月最后一天 | `addMonths(本月1日, -1) - INTERVAL 1 DAY` |

> **对比维度**：月环比（上月整月 vs 上上月整月）

### 3.4 yearly_cumulative_monthly - 年累计月报

| 项目 | 说明 | 计算公式 |
|------|------|---------|
| **本期开始** | 本年1月1日 | `toStartOfYear(input_date)` |
| **本期结束** | 上月最后一天 | `本月1日 - INTERVAL 1 DAY` |
| **上期开始** | 去年1月1日 | `addYears(本年1月1日, -1)` |
| **上期结束** | 去年同期上月最后一天 | `addYears(本月1日, -1) - INTERVAL 1 DAY` |

> **对比维度**：年同比累计（今年截至上月末 vs 去年同期截至上月末）

---

## 4. 输出字段说明

### 4.1 基础信息字段

| 字段 | 类型 | 说明 | 示例 |
|------|------|------|------|
| `report_type` | String | 报表类型标识 | `weekly` |
| `description` | String | 报表中文描述 | `周大福运营周报（上周日期范围）` |

### 4.2 本期字段

| 字段 | 格式 | 说明 | 示例 |
|------|------|------|------|
| `start_date` | `YYYY/MM/DD` | 本期开始日期 | `2026/05/11` |
| `end_date` | `YYYY/MM/DD` | 本期结束日期 | `2026/05/17` |
| `date_range_string` | `开始~结束` | 本期日期范围拼接 | `2026/05/11~2026/05/17` |
| `start_week` | `YYYY-WW` | 开始日期所在 ISO 周 | `2026-20` |
| `end_week` | `YYYY-WW` | 结束日期所在 ISO 周 | `2026-20` |
| `start_month` | `YYYY-MM` | 开始日期所在月份 | `2026-05` |
| `end_month` | `YYYY-MM` | 结束日期所在月份 | `2026-05` |

### 4.3 上期字段

| 字段 | 格式 | 说明 | 示例 |
|------|------|------|------|
| `prev_start_date` | `YYYY/MM/DD` | 上期开始日期 | `2026/05/04` |
| `prev_end_date` | `YYYY/MM/DD` | 上期结束日期 | `2026/05/10` |
| `prev_date_range_string` | `开始~结束` | 上期日期范围拼接 | `2026/05/04~2026/05/10` |
| `prev_start_week` | `YYYY-WW` | 上期开始 ISO 周 | `2026-19` |
| `prev_end_week` | `YYYY-WW` | 上期结束 ISO 周 | `2026-19` |
| `prev_start_month` | `YYYY-MM` | 上期开始月份 | `2026-05` |
| `prev_end_month` | `YYYY-MM` | 上期结束月份 | `2026-05` |

### 4.4 辅助字段

| 字段 | 说明 | 示例 |
|------|------|------|
| `input_date_display` | 当前输入的基准日期 | `2026/05/23` |

---

## 5. 自测验证记录

### 测试用例：input_date = 2026-05-23（星期六）

**基础参数推导**：

```
input_week_start  = toMonday(2026-05-23)        = 2026-05-18（本周一）
input_month_start = toStartOfMonth(2026-05-23)   = 2026-05-01（本月第一天）
input_year_start  = toStartOfYear(2026-05-23)    = 2026-01-01（本年第一天）
```

**预期输出**：

| # | report_type | 本期范围 | 上期范围 |
|---|-------------|---------|---------|
| 1 | weekly | 2026/05/11~2026/05/17 | 2026/05/04~2026/05/10 |
| 2 | monthly_cumulative_weekly | 2026/05/01~2026/05/17 | 2026/04/01~2026/04/17 |
| 3 | monthly | 2026/04/01~2026/04/30 | 2026/03/01~2026/03/31 |
| 4 | yearly_cumulative_monthly | 2026/01/01~2026/04/30 | 2025/01/01~2025/04/30 |

**各类型推演明细**：

#### Type 1 - weekly

```
start_date = 2026-05-18 - 7  = 2026-05-11（上周一）
end_date   = 2026-05-18 - 1  = 2026-05-17（上周日）
prev_start = 2026-05-18 - 14 = 2026-05-04（上上周一）
prev_end   = 2026-05-18 - 8  = 2026-05-10（上上周日）
```

#### Type 2 - monthly_cumulative_weekly

```
start_date = 2026-05-01（本月1日）
end_date   = 2026-05-18 - 1 = 2026-05-17（上周日）
prev_start = addMonths(2026-05-01, -1) = 2026-04-01（上月1日）
prev_end   = addMonths(2026-05-17, -1) = 2026-04-17（上月对应日）
```

#### Type 3 - monthly

```
start_date = addMonths(2026-05-01, -1) = 2026-04-01（上月第一天）
end_date   = 2026-05-01 - INTERVAL 1 DAY = 2026-04-30（上月最后一天）
prev_start = addMonths(2026-05-01, -2) = 2026-03-01（上上月第一天）
prev_end   = addMonths(2026-05-01, -1) - INTERVAL 1 DAY = 2026-04-01 - 1天 = 2026-03-31（上上月最后一天）
```

#### Type 4 - yearly_cumulative_monthly

```
start_date = 2026-01-01（本年第一天）
end_date   = 2026-05-01 - INTERVAL 1 DAY = 2026-04-30（上月最后一天）
prev_start = addYears(2026-01-01, -1) = 2025-01-01（去年第一天）
prev_end   = addYears(2026-05-01, -1) - INTERVAL 1 DAY = 2025-05-01 - 1天 = 2025-04-30（去年同期上月最后一天）
```

---

## 6. SQL 架构说明

整体采用 CTE（公用表表达式）链式结构，共三层：

```
INPUT_PARAM_CTE          -- 第1层：输入参数定义
    ↓
DATE_PARAM_CTE           -- 第2层：基础日期参数派生（周一、月初、年初）
    ↓
DATE_RANGES_RAW_CTE      -- 第3层：四种报表日期范围计算（UNION ALL 合并）
    ↓
最终 SELECT              -- 第4层：格式化输出 + 周/月维度字段拼接
```

### 各层职责

| CTE 层 | 职责 | 输出 |
|--------|------|------|
| `INPUT_PARAM_CTE` | 定义输入日期，隔离参数变更 | `input_date` |
| `DATE_PARAM_CTE` | 根据输入日期派生周一、月初、年初 | `input_week_start`, `input_month_start`, `input_year_start` |
| `DATE_RANGES_RAW_CTE` | 四种报表类型各自计算本期/上期的原始日期（Date 类型） | `start_date_raw`, `end_date_raw`, `prev_start_date_raw`, `prev_end_date_raw` |
| 最终 SELECT | 格式化为字符串，拼接日期范围，计算 ISO 周和月份维度字段 | 全部 17 个输出字段 |

---

## 7. 踩坑记录与注意事项

### 7.1 ClickHouse Date vs Date32 类型陷阱

**问题现象**：`input_month_start - 1` 未能正确减去一天，输出日期与原日期相同。

**根因分析**：

在 UNION ALL 中，不同 SELECT 分支的同一列可能产生不同的日期类型：

- `toMonday()` / `toStartOfMonth()` / `toStartOfYear()` 返回 `Date` 类型
- `addMonths()` / `addYears()` 可能返回 `Date32` 类型

ClickHouse 在 UNION ALL 中进行列类型提升时，`Date` 与 `Date32` 混合后，裸整数减法 `- 1` 的语义可能不被正确解释为"减一天"。

**解决方案**：统一使用 `INTERVAL` 语法进行日期加减，确保类型安全：

```sql
-- 不推荐（可能在 UNION ALL 中失效）
input_month_start - 1

-- 推荐（显式声明减去一天，类型安全）
input_month_start - INTERVAL 1 DAY
```

**影响范围**：所有涉及"月初日期减一天取上月末"的场景（第 3、4 种报表的 `end_date_raw` 和 `prev_end_date_raw`）。

> **最佳实践**：在 ClickHouse 中进行日期加减运算时，建议始终使用 `INTERVAL N DAY` / `INTERVAL N MONTH` 等显式语法，避免依赖裸整数减法，尤其是在 UNION ALL、子查询等可能触发类型提升的上下文中。

### 7.2 年累计月报上期公式错误

**问题现象**：第 4 种报表的 `prev_end_date_raw` 使用 `addMonths(input_month_start, -1)` 仅往前推了一个月，而年累计报表的上期应整体往前推一年。

**错误公式**：`addMonths(input_month_start, -1) - 1` → 计算出"上上月末"

**修正公式**：`addYears(input_month_start, -1) - INTERVAL 1 DAY` → 正确计算"去年同期上月末"

---

## 8. 使用示例

### 8.1 直接查询

```sql
-- 将 SQL 中的 input_date 替换为目标日期
CAST('2026-05-23' AS DATE) AS input_date
```

### 8.2 生产环境集成

```sql
-- 使用 today() 作为输入，每日自动生成当天对应的四组日期范围
today() AS input_date
```

### 8.3 下游使用场景

- 将输出的 `date_range_string` 用作报表标题中的日期区间展示
- 将 `start_date` / `end_date` 用作业务数据查询的 WHERE 条件
- 将 `start_week` / `end_week` 用于按 ISO 周维度筛选数据
- 将 `start_month` / `end_month` 用于按月份维度筛选数据
- 将 `prev_*` 系列字段用于环比/同比数据的对照查询

---

## 9. 关键 ClickHouse 函数参考

| 函数 | 用途 | 返回类型 |
|------|------|---------|
| `toMonday(date)` | 获取日期所在周的周一 | `Date` |
| `toStartOfMonth(date)` | 获取日期所在月的第一天 | `Date` |
| `toStartOfYear(date)` | 获取日期所在年的第一天 | `Date` |
| `addMonths(date, n)` | 日期加减 N 个月 | `Date32` |
| `addYears(date, n)` | 日期加减 N 年 | `Date32` |
| `toISOWeek(date)` | 获取 ISO 8601 周数（1-53） | `UInt8` |
| `toMonth(date)` | 获取月份（1-12） | `UInt8` |
| `formatDateTime(date, fmt)` | 日期格式化为字符串 | `String` |
| `leftPad(str, len, ch)` | 字符串左填充 | `String` |
