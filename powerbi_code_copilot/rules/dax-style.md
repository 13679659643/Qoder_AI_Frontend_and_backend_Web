---
alwaysApply: true
---

# DAX 编码规范

## 1. 命名约定

### 度量值（Measures）
- 使用清晰的业务语义命名，英文优先
- 前缀规范：
  - 基础度量值：无前缀（`Total Sales`, `Order Count`）
  - 时间智能：以时间周期开头（`YTD Sales`, `MoM Growth %`）
  - 比率/百分比：以 `%` 结尾（`Profit Margin %`, `YoY Growth %`）
  - 排名：以 `Rank` 开头或结尾（`Sales Rank`）
  - 辅助/内部度量值：以 `_` 前缀（`_Base Revenue`）
- 禁止使用拼音或中英混拼

### 计算列（Calculated Columns）
- 以 `CC_` 前缀标识（可选，团队约定）
- 命名体现其业务含义

### 计算表（Calculated Tables）
- 以 `CT_` 前缀标识（可选，团队约定）

### 变量（VAR）
- 使用 `__` 前缀（双下划线）或清晰的描述性命名
- 示例：`__TotalSales`, `__FilteredTable`, `__CurrentDate`

## 2. 格式规范

### 缩进与换行
```dax
// 推荐格式
Revenue YTD = 
    VAR __CurrentDate = MAX('Date'[Date])
    VAR __YTDFilter = 
        FILTER(
            ALL('Date'),
            'Date'[Date] <= __CurrentDate
                && 'Date'[Year] = YEAR(__CurrentDate)
        )
    RETURN
        CALCULATE(
            [Total Revenue],
            __YTDFilter
        )
```

- 每个 VAR 独占一行
- RETURN 与 VAR 同级缩进
- 嵌套函数每层缩进 4 个空格
- 长参数列表每个参数独占一行
- 逻辑运算符（&&, ||）放在行首

### 注释
- 复杂度量值（超过 5 行）必须添加头部注释
- 注释格式：
```dax
// ========================================
// 度量值: Revenue YTD
// 用途: 计算年初至今累计收入
// 依赖: [Total Revenue], Date 表
// 作者: xxx | 日期: YYYY-MM-DD
// ========================================
```

## 3. DAX 编写原则

### 性能优先
- 优先使用 VAR 避免重复计算
- 避免嵌套 CALCULATE（超过 2 层需重构）
- 优先使用 REMOVEFILTERS 替代 FILTER(ALL(...))
- 迭代函数（SUMX, AVERAGEX 等）注意迭代表的大小
- 避免在度量值中使用 IF + 大型表迭代

### 上下文清晰
- 明确区分行上下文和筛选器上下文
- CALCULATE 的每个筛选参数必须有明确意图
- 避免不必要的上下文转换
- 使用 SELECTEDVALUE 替代 VALUES（当期望单值时）

### 可维护性
- 复杂计算分解为多个度量值（基础 → 中间 → 最终）
- 使用 Display Folder 组织度量值
- 每个度量值单一职责

## 4. 禁止事项

- ❌ 禁止使用隐式度量值（直接拖字段到视觉对象值区域）
- ❌ 禁止在度量值中硬编码日期或业务参数
- ❌ 禁止使用 EARLIER（用 VAR 替代）
- ❌ 禁止未经验证的 CALCULATE 嵌套
- ❌ 禁止在计算列中引用度量值
