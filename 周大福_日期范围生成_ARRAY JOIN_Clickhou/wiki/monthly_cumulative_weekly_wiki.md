# monthly_cumulative_weekly.sql Wiki

> **数据库**: ClickHouse  
> **报表类型**: `monthly_cumulative_weekly`  
> **用途**: 周大福月累计运营周报 -- 生成本月1日至上周日（或当天）的日期范围，并同步生成去年同期日期范围，最终通过 ARRAY JOIN 列转行输出。

---

## 1. 整体架构

SQL 采用 **4层 CTE 链式结构** + **ARRAY JOIN 列转行**：

```
INPUT_PARAM_CTE  -->  DATE_PARAM_CTE  -->  DATE_RANGES_RAW_CTE  -->  DATE_RANGES_CTE  -->  ARRAY JOIN 最终输出
    (输入参数)          (日期锚点)            (原始日期范围)              (格式化字段)          (列转行2行)
```

---

## 2. CTE 详解

### 2.1 INPUT_PARAM_CTE -- 输入参数

```sql
WITH INPUT_PARAM_CTE AS (
    SELECT today() AS input_date
    -- 或 CAST('2026-04-10' AS DATE) AS input_date
)
```

| 字段 | 类型 | 说明 |
|---|---|---|
| `input_date` | `Date` | 输入日期参数，可替换为任意固定日期或 `today()` |

### 2.2 DATE_PARAM_CTE -- 日期锚点计算

```sql
DATE_PARAM_CTE AS (
    SELECT input_date,
           toMonday(input_date)       AS input_week_start,
           toStartOfMonth(input_date) AS input_month_start,
           toStartOfYear(input_date)  AS input_year_start
    FROM INPUT_PARAM_CTE
)
```

| 字段 | 计算方式 | 说明 |
|---|---|---|
| `input_date` | 透传 | 原始输入日期 |
| `input_week_start` | `toMonday(input_date)` | input_date 所在周的周一 |
| `input_month_start` | `toStartOfMonth(input_date)` | input_date 所在月的1号 |
| `input_year_start` | `toStartOfYear(input_date)` | input_date 所在年的1月1日 |

### 2.3 DATE_RANGES_RAW_CTE -- 原始日期范围（核心业务逻辑）

```sql
DATE_RANGES_RAW_CTE AS (
    SELECT 'monthly_cumulative_weekly'                             AS report_type,
           '周大福月累计运营周报（最新月份-上周最后一天日期范围）'   AS description,
           input_month_start                                       AS start_date_raw,
           if(toDayOfMonth(input_date) < 10,
              input_date,
              subtractDays(input_week_start, 1))                   AS end_date_raw,
           subtractYears(input_month_start, 1)                     AS prev_start_date_raw,
           if(toDayOfMonth(input_date) < 10,
              subtractYears(input_date, 1),
              subtractYears(subtractDays(input_week_start, 1), 1)) AS prev_end_date_raw
    FROM DATE_PARAM_CTE
)
```

#### 业务规则：10号分界逻辑

| 条件 | `end_date_raw` | `prev_end_date_raw` | 说明 |
|---|---|---|---|
| `toDayOfMonth(input_date) < 10` | `input_date`（当天） | `subtractYears(input_date, 1)`（去年同日） | 月初不足一周，取当天 |
| `toDayOfMonth(input_date) >= 10` | `subtractDays(input_week_start, 1)`（上周日） | `subtractYears(上周日, 1)`（去年同期上周日） | 正常取上周日 |

#### 本期/上期字段对照

| 字段 | 本期 | 上期 |
|---|---|---|
| 开始日期 | `start_date_raw` = 本月1日 | `prev_start_date_raw` = 去年同月1日 |
| 结束日期 | `end_date_raw` = 上周日或当天 | `prev_end_date_raw` = 去年同期 |

#### 举例

假设 `input_date = 2026-04-15`（15号 >= 10，周三）：

| 字段 | 值 | 计算过程 |
|---|---|---|
| `start_date_raw` | `2026-04-01` | `toStartOfMonth('2026-04-15')` |
| `end_date_raw` | `2026-04-12` | `toMonday('2026-04-15')` = `2026-04-13`，`2026-04-13 - 1天` = `2026-04-12`（周日） |
| `prev_start_date_raw` | `2025-04-01` | `2026-04-01 - 1年` |
| `prev_end_date_raw` | `2025-04-12` | `2026-04-12 - 1年` |

假设 `input_date = 2026-04-07`（7号 < 10，周二）：

| 字段 | 值 | 计算过程 |
|---|---|---|
| `start_date_raw` | `2026-04-01` | `toStartOfMonth('2026-04-07')` |
| `end_date_raw` | `2026-04-07` | 直接取 input_date |
| `prev_start_date_raw` | `2025-04-01` | `2026-04-01 - 1年` |
| `prev_end_date_raw` | `2025-04-07` | `2026-04-07 - 1年` |

### 2.4 DATE_RANGES_CTE -- 格式化与派生字段

此 CTE 从 `DATE_RANGES_RAW_CTE` 的原始 `Date` 类型出发，生成所有格式化字符串字段。

#### 输出字段一览

| 字段 | 格式 | 说明 |
|---|---|---|
| `report_type` | `String` | 固定值 `'monthly_cumulative_weekly'` |
| `description` | `String` | 中文描述 |
| **本期日期** | | |
| `start_date` | `YYYYMMDD` | 本期开始日期 |
| `end_date` | `YYYYMMDD` | 本期结束日期 |
| `date_range_string` | `YYYYMMDD ~ YYYYMMDD` | 本期日期范围拼接 |
| **本期周** | | |
| `start_week` | `YYYY-WW` | 本期开始ISO周（若月1号非周一，取1号后第一个周一的ISO周） |
| `end_week` | `YYYY-WW` | 本期结束ISO周 |
| `start_week_date` | `YYYYMMDD` | `start_week` 对应的周一日期 |
| `end_week_date` | `YYYYMMDD` | `end_week` 对应的周日日期 |
| **本期月** | | |
| `start_month` | `YYYY-MM` | 本期开始月 |
| `end_month` | `YYYY-MM` | 本期结束月 |
| **上期日期** | | |
| `prev_start_date` | `YYYYMMDD` | 上期开始日期 |
| `prev_end_date` | `YYYYMMDD` | 上期结束日期 |
| `prev_date_range_string` | `YYYYMMDD ~ YYYYMMDD` | 上期日期范围拼接 |
| **上期周** | | |
| `prev_start_week` | `YYYY-WW` | 上期开始ISO周 |
| `prev_end_week` | `YYYY-WW` | 上期结束ISO周 |
| `prev_start_week_date` | `YYYYMMDD` | `prev_start_week` 对应的周一日期 |
| `prev_end_week_date` | `YYYYMMDD` | `prev_end_week` 对应的周日日期 |
| **上期月** | | |
| `prev_start_month` | `YYYY-MM` | 上期开始月 |
| `prev_end_month` | `YYYY-MM` | 上期结束月 |
| **其他** | | |
| `input_date_display` | `YYYY/MM/DD` | 输入日期展示用 |

#### start_week 的特殊处理逻辑

当月1号不是周一时，`start_week` 不取1号所在的ISO周，而是取 **1号之后第一个周一** 的ISO周：

```sql
if(toMonday(start_date_raw) = start_date_raw,
   start_date_raw,                          -- 1号本身是周一，直接用
   addDays(toMonday(start_date_raw), 7))    -- 1号不是周一，取下一个周一
```

**原因**: 1号所在周可能大部分属于上个月，业务上认为不应纳入本月第一周。

#### week_date 字段的计算逻辑

| 字段 | 计算方式 | 说明 |
|---|---|---|
| `start_week_date` | 与 `start_week` 相同的日期表达式，只是输出 `YYYYMMDD` 格式 | start_week 对应的那个周一的具体日期 |
| `end_week_date` | `addDays(toMonday(end_date_raw), 6)` | end_week 对应的那个周日的具体日期 |
| `prev_start_week_date` | 同 `start_week_date`，基于 `prev_start_date_raw` | 上期 start_week 的周一日期 |
| `prev_end_week_date` | `addDays(toMonday(prev_end_date_raw), 6)` | 上期 end_week 的周日日期 |

---

## 3. ARRAY JOIN 列转行

最终通过 **ARRAY JOIN** 将每组 `start/end` 对转为 **2行数据**（第1行=start，第2行=end）：

```sql
ARRAY JOIN
    ['start_date', 'end_date']                 AS field_name_date,
    [start_date, end_date]                     AS field_value_date,
    ['start_week', 'end_week']                 AS field_name_week,
    [start_week, end_week]                     AS field_value_week,
    [start_week_date, end_week_date]           AS field_value_week_date,
    ...
```

### 输出结构（2行）

| 行 | field_name_date | field_value_date | field_name_week | field_value_week | field_value_week_date | ... |
|---|---|---|---|---|---|---|
| 1 | `start_date` | `20260401` | `start_week` | `2026-15` | `20260406` | ... |
| 2 | `end_date` | `20260412` | `end_week` | `2026-15` | `20260412` | ... |

### 不参与 ARRAY JOIN 的字段（每行相同）

- `report_type`
- `description`
- `date_range_string`
- `prev_date_range_string`
- `input_date_display`

---

## 4. 完整最终输出字段

| # | 字段名 | 类型 | ARRAY JOIN | 说明 |
|---|---|---|---|---|
| 1 | `report_type` | String | 否 | 报表类型标识 |
| 2 | `description` | String | 否 | 报表中文描述 |
| 3 | `field_name_date` | String | 是 | 日期字段名 (`start_date` / `end_date`) |
| 4 | `field_value_date` | String | 是 | 日期字段值 (YYYYMMDD) |
| 5 | `field_name_week` | String | 是 | 周字段名 (`start_week` / `end_week`) |
| 6 | `field_value_week` | String | 是 | 周字段值 (YYYY-WW) |
| 7 | `field_value_week_date` | String | 是 | 周对应的日期值 (周一/周日, YYYYMMDD) |
| 8 | `field_name_month` | String | 是 | 月字段名 (`start_month` / `end_month`) |
| 9 | `field_value_month` | String | 是 | 月字段值 (YYYY-MM) |
| 10 | `field_name_prev_date` | String | 是 | 上期日期字段名 |
| 11 | `field_value_prev_date` | String | 是 | 上期日期字段值 (YYYYMMDD) |
| 12 | `field_name_prev_week` | String | 是 | 上期周字段名 |
| 13 | `field_value_prev_week` | String | 是 | 上期周字段值 (YYYY-WW) |
| 14 | `prev_field_value_week_date` | String | 是 | 上期周对应的日期值 (周一/周日, YYYYMMDD) |
| 15 | `field_name_prev_month` | String | 是 | 上期月字段名 |
| 16 | `field_value_prev_month` | String | 是 | 上期月字段值 (YYYY-MM) |
| 17 | `date_range_string` | String | 否 | 本期日期范围拼接字符串 |
| 18 | `prev_date_range_string` | String | 否 | 上期日期范围拼接字符串 |
| 19 | `input_date_display` | String | 否 | 输入日期展示 (YYYY/MM/DD) |

---

## 5. 数据流转示例

### 输入: `input_date = 2026-04-15`（>= 10号，周三）

**DATE_PARAM_CTE**:

| input_date | input_week_start | input_month_start |
|---|---|---|
| 2026-04-15 | 2026-04-13 (周一) | 2026-04-01 |

**DATE_RANGES_RAW_CTE**:

| start_date_raw | end_date_raw | prev_start_date_raw | prev_end_date_raw |
|---|---|---|---|
| 2026-04-01 | 2026-04-12 (上周日) | 2025-04-01 | 2025-04-12 |

**最终输出** (2行):

| 行 | field_value_date | field_value_week | field_value_week_date | field_value_month | field_value_prev_date | field_value_prev_week | prev_field_value_week_date |
|---|---|---|---|---|---|---|---|
| 1 | 20260401 | 2026-15 | 20260406 | 2026-04 | 20250401 | 2025-15 | 20250407 |
| 2 | 20260412 | 2026-15 | 20260412 | 2026-04 | 20250412 | 2025-15 | 20250412 |

### 输入: `input_date = 2026-04-07`（< 10号，周二）

**DATE_RANGES_RAW_CTE**:

| start_date_raw | end_date_raw | prev_start_date_raw | prev_end_date_raw |
|---|---|---|---|
| 2026-04-01 | 2026-04-07 (当天) | 2025-04-01 | 2025-04-07 |

**最终输出** (2行):

| 行 | field_value_date | field_value_week | field_value_week_date | field_value_month |
|---|---|---|---|---|
| 1 | 20260401 | 2026-15 | 20260406 | 2026-04 |
| 2 | 20260407 | 2026-15 | 20260412 | 2026-04 |

---

## 6. ClickHouse 函数参考手册

以下是本 SQL 文件中使用的全部 ClickHouse 函数的详细说明。

### 6.1 `today()`

**功能**: 返回当前日期（服务器时区）。

**返回类型**: `Date`

```sql
SELECT today();
-- 结果: 2026-04-07 (假设今天是2026年4月7日)
```

### 6.2 `CAST(x AS T)`

**功能**: 将值 `x` 转换为类型 `T`。

**语法**: `CAST(expression AS type)`

```sql
SELECT CAST('2026-04-15' AS Date);
-- 结果: 2026-04-15 (Date类型)

SELECT CAST(123 AS String);
-- 结果: '123'

SELECT CAST('2026-04-15 10:30:00' AS DateTime);
-- 结果: 2026-04-15 10:30:00
```

### 6.3 `toMonday(date)`

**功能**: 将日期向下取整到 **最近的周一**（即该日期所在周的周一）。

**返回类型**: `Date`

```sql
SELECT toMonday(toDate('2026-04-15'));  -- 2026-04-15 是周三
-- 结果: 2026-04-13 (周一)

SELECT toMonday(toDate('2026-04-13'));  -- 2026-04-13 本身是周一
-- 结果: 2026-04-13

SELECT toMonday(toDate('2026-04-12'));  -- 2026-04-12 是周日
-- 结果: 2026-04-06 (上周一)
```

> **注意**: 周日属于上一周，`toMonday('周日')` 返回的是上周一。

### 6.4 `toStartOfMonth(date)`

**功能**: 将日期向下取整到 **当月第一天**。

**返回类型**: `Date`

```sql
SELECT toStartOfMonth(toDate('2026-04-15'));
-- 结果: 2026-04-01

SELECT toStartOfMonth(toDate('2026-12-31'));
-- 结果: 2026-12-01
```

### 6.5 `toStartOfYear(date)`

**功能**: 将日期向下取整到 **当年第一天**。

**返回类型**: `Date`

```sql
SELECT toStartOfYear(toDate('2026-04-15'));
-- 结果: 2026-01-01

SELECT toStartOfYear(toDate('2026-12-31'));
-- 结果: 2026-01-01
```

### 6.6 `toDayOfMonth(date)`

**功能**: 返回日期在当月中的 **第几天**（1-31）。

**返回类型**: `UInt8`

```sql
SELECT toDayOfMonth(toDate('2026-04-15'));
-- 结果: 15

SELECT toDayOfMonth(toDate('2026-04-01'));
-- 结果: 1

SELECT toDayOfMonth(toDate('2026-02-28'));
-- 结果: 28
```

**本文件用途**: 判断 `input_date` 是否 < 10号，以决定 `end_date_raw` 的取值逻辑。

### 6.7 `toMonth(date)`

**功能**: 返回日期的 **月份**（1-12）。

**返回类型**: `UInt8`

```sql
SELECT toMonth(toDate('2026-04-15'));
-- 结果: 4

SELECT toMonth(toDate('2026-12-01'));
-- 结果: 12
```

### 6.8 `toISOWeek(date)`

**功能**: 返回日期的 **ISO 8601 周数**（1-53）。ISO周以周一为一周的开始，每年第一个包含周四的周为第1周。

**返回类型**: `UInt8`

```sql
SELECT toISOWeek(toDate('2026-01-01'));
-- 结果: 1

SELECT toISOWeek(toDate('2026-04-15'));
-- 结果: 16

SELECT toISOWeek(toDate('2025-12-29'));  -- 可能属于2026年第1周
-- 结果: 1
```

> **注意**: ISO周数可能导致跨年，12月底的日期可能属于下一年的第1周，1月初的日期可能属于上一年的第52/53周。

### 6.9 `subtractDays(date, n)`

**功能**: 从日期中 **减去 n 天**。

**返回类型**: `Date`

```sql
SELECT subtractDays(toDate('2026-04-15'), 1);
-- 结果: 2026-04-14

SELECT subtractDays(toDate('2026-04-01'), 1);
-- 结果: 2026-03-31 (跨月)

SELECT subtractDays(toDate('2026-01-01'), 1);
-- 结果: 2025-12-31 (跨年)
```

**本文件用途**: `subtractDays(input_week_start, 1)` 计算上周日（周一减1天）。

### 6.10 `subtractYears(date, n)`

**功能**: 从日期中 **减去 n 年**。

**返回类型**: `Date`

```sql
SELECT subtractYears(toDate('2026-04-15'), 1);
-- 结果: 2025-04-15

SELECT subtractYears(toDate('2024-02-29'), 1);  -- 闰年2月29日
-- 结果: 2023-02-28 (自动处理闰年)
```

> **注意**: 如果原始日期是闰年2月29日，减去1年后自动变为2月28日。

### 6.11 `addDays(date, n)`

**功能**: 向日期中 **加上 n 天**。

**返回类型**: `Date`

```sql
SELECT addDays(toDate('2026-04-13'), 7);
-- 结果: 2026-04-20 (下周一)

SELECT addDays(toDate('2026-04-13'), 6);
-- 结果: 2026-04-19 (本周日)

SELECT addDays(toDate('2026-04-30'), 1);
-- 结果: 2026-05-01 (跨月)
```

**本文件用途**:
- `addDays(toMonday(start_date_raw), 7)`: 当月1号非周一时，取下一个周一
- `addDays(toMonday(end_date_raw), 6)`: 取 end_week 对应的周日日期

### 6.12 `formatDateTime(date, format)`

**功能**: 将日期/时间按指定格式转为字符串。

**返回类型**: `String`

**常用格式符**:

| 格式符 | 说明 | 示例 |
|---|---|---|
| `%Y` | 4位年份 | `2026` |
| `%m` | 2位月份 (01-12) | `04` |
| `%d` | 2位日期 (01-31) | `15` |

```sql
SELECT formatDateTime(toDate('2026-04-15'), '%Y%m%d');
-- 结果: '20260415'

SELECT formatDateTime(toDate('2026-04-15'), '%Y/%m/%d');
-- 结果: '2026/04/15'

SELECT formatDateTime(toDate('2026-04-15'), '%Y');
-- 结果: '2026'
```

### 6.13 `concat(s1, s2, ...)`

**功能**: 将多个字符串 **拼接** 为一个字符串。

**返回类型**: `String`

```sql
SELECT concat('2026', '-', '04');
-- 结果: '2026-04'

SELECT concat('20260401', ' ~ ', '20260412');
-- 结果: '20260401 ~ 20260412'

SELECT concat(toString(2026), '-W', leftPad(toString(15), 2, '0'));
-- 结果: '2026-W15'
```

### 6.14 `toString(x)`

**功能**: 将任意类型的值转为 **字符串**。

**返回类型**: `String`

```sql
SELECT toString(15);
-- 结果: '15'

SELECT toString(4);
-- 结果: '4'

SELECT toString(toDate('2026-04-15'));
-- 结果: '2026-04-15'
```

### 6.15 `leftPad(s, length, pad_char)`

**功能**: 在字符串左侧填充指定字符，使其达到指定长度。如果原字符串已达到或超过指定长度，则不做处理。

**返回类型**: `String`

```sql
SELECT leftPad(toString(4), 2, '0');
-- 结果: '04'

SELECT leftPad(toString(15), 2, '0');
-- 结果: '15' (已达到2位，不填充)

SELECT leftPad('1', 3, '0');
-- 结果: '001'

SELECT leftPad('hello', 10, '*');
-- 结果: '*****hello'
```

**本文件用途**: 确保ISO周数和月份始终为2位数字（如 `4` -> `04`）。

### 6.16 `if(condition, then, else)`

**功能**: 条件表达式。当 `condition` 为真时返回 `then`，否则返回 `else`。

**返回类型**: 取决于 `then`/`else` 的类型

```sql
SELECT if(1 > 0, 'yes', 'no');
-- 结果: 'yes'

SELECT if(toDayOfMonth(toDate('2026-04-07')) < 10, '月初', '月中后');
-- 结果: '月初'

SELECT if(toDayOfMonth(toDate('2026-04-15')) < 10, '月初', '月中后');
-- 结果: '月中后'

SELECT if(toMonday(toDate('2026-04-01')) = toDate('2026-04-01'),
          toDate('2026-04-01'),
          addDays(toMonday(toDate('2026-04-01')), 7));
-- 2026-04-01是周三，toMonday返回2026-03-30，不等于4月1日
-- 结果: 2026-04-06 (下一个周一)
```

### 6.17 `ARRAY JOIN`

**功能**: ClickHouse 特有的表函数/子句。将数组列展开为多行，每个数组元素生成一行。多个数组并行 ARRAY JOIN 时按位置对齐。

**语法**: `SELECT ... FROM table ARRAY JOIN array_expr AS alias, ...`

```sql
-- 基本用法: 展开单个数组
SELECT
    'report' AS name,
    x
FROM (SELECT 1 AS dummy)
ARRAY JOIN [10, 20, 30] AS x;
-- 结果:
-- | name   | x  |
-- |--------|----|
-- | report | 10 |
-- | report | 20 |
-- | report | 30 |

-- 并行展开多个数组 (按位置对齐)
SELECT
    label,
    value
FROM (SELECT 1 AS dummy)
ARRAY JOIN
    ['start', 'end'] AS label,
    ['20260401', '20260412'] AS value;
-- 结果:
-- | label | value    |
-- |-------|----------|
-- | start | 20260401 |
-- | end   | 20260412 |
```

**本文件用途**: 将 DATE_RANGES_CTE 中的 8 组 start/end 字段对并行展开为 2 行，实现列转行。每组数组都有 2 个元素，因此结果固定为 2 行。

**关键特性**:
- 多个数组并行 JOIN 时，数组长度必须一致，否则报错
- 非数组字段在每行中重复（如 `date_range_string`、`input_date_display`）
- 与普通 JOIN 不同，ARRAY JOIN 不需要关联条件
