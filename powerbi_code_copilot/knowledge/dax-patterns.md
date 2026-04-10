# DAX 常用模式库

> 经过验证的高质量 DAX 模式，可直接复用。每个模式包含：场景、代码、解释、性能说明。

## 1. Running Total（累计求和）

### 场景
按日期维度展示从期初到当前日期的累计值。

### 代码
```dax
Running Total = 
    VAR __LastDate = MAX('Date'[Date])
    RETURN
        CALCULATE(
            [Total Sales],
            'Date'[Date] <= __LastDate,
            ALL('Date')
        )
```

### 解释
- 使用 ALL('Date') 移除日期表上的所有筛选器
- 再用 <= __LastDate 重新应用从最早日期到当前日期的筛选
- VAR 缓存当前上下文的最大日期，避免重复计算

### 性能说明
🟢 性能良好，适合大多数场景。

---

## 2. 同比 / 环比（YoY / MoM）

### 场景
计算同比增长率和环比增长率。

### 代码
```dax
// 同比增长率
YoY Growth % = 
    VAR __CurrentValue = [Total Sales]
    VAR __PriorYearValue = 
        CALCULATE(
            [Total Sales],
            SAMEPERIODLASTYEAR('Date'[Date])
        )
    RETURN
        IF(
            NOT ISBLANK(__PriorYearValue) && __PriorYearValue <> 0,
            DIVIDE(__CurrentValue - __PriorYearValue, __PriorYearValue),
            BLANK()
        )

// 环比增长率
MoM Growth % = 
    VAR __CurrentValue = [Total Sales]
    VAR __PriorMonthValue = 
        CALCULATE(
            [Total Sales],
            DATEADD('Date'[Date], -1, MONTH)
        )
    RETURN
        IF(
            NOT ISBLANK(__PriorMonthValue) && __PriorMonthValue <> 0,
            DIVIDE(__CurrentValue - __PriorMonthValue, __PriorMonthValue),
            BLANK()
        )
```

### 解释
- SAMEPERIODLASTYEAR 返回上一年同期日期集
- DATEADD 将日期平移指定数量的时间单位
- 必须处理前期值为空或零的情况，避免除零错误

### 性能说明
🟢 时间智能函数经过引擎优化，性能良好。前提是日期表已正确标记。

---

## 3. 动态 Top N

### 场景
根据用户选择的 N 值，动态展示排名前 N 的项目，并将其余项目归为"其他"。

### 代码
```dax
// 假设有一个 What-If 参数 'Top N Value'[Top N Value]
Is Top N = 
    VAR __SelectedN = SELECTEDVALUE('Top N Value'[Top N Value], 10)
    VAR __CurrentProduct = SELECTEDVALUE('Product'[ProductName])
    VAR __RankTable = 
        ADDCOLUMNS(
            VALUES('Product'[ProductName]),
            "@Sales", [Total Sales]
        )
    VAR __Rank = 
        RANKX(__RankTable, [@Sales],, DESC, Dense)
    RETURN
        IF(__Rank <= __SelectedN, 1, 0)
```

### 性能说明
🟡 中等开销。RANKX 在大型维度表上需注意性能，建议维度基数 < 10,000。

---

## 4. ABC 分析（帕累托分析）

### 场景
将产品/客户按贡献度分为 A/B/C 三类（如 A 类贡献 80% 营收）。

### 代码
```dax
ABC Category = 
    VAR __CurrentSales = [Total Sales]
    VAR __AllSales = 
        CALCULATE([Total Sales], ALL('Product'))
    VAR __CumulativePct = 
        DIVIDE(
            CALCULATE(
                [Total Sales],
                FILTER(
                    ALL('Product'),
                    [Total Sales] >= __CurrentSales
                )
            ),
            __AllSales
        )
    RETURN
        SWITCH(
            TRUE(),
            __CumulativePct <= 0.8, "A",
            __CumulativePct <= 0.95, "B",
            "C"
        )
```

### 性能说明
🟡 中等开销。嵌套 CALCULATE + FILTER 在大型数据集上可能较慢，考虑预计算为计算列。

---

## 5. 移动平均（Moving Average）

### 场景
计算 N 天/月的移动平均值，平滑趋势线。

### 代码
```dax
Moving Average 3M = 
    VAR __Period = 3
    VAR __LastDate = MAX('Date'[Date])
    VAR __DateRange = 
        DATESINPERIOD(
            'Date'[Date],
            __LastDate,
            -__Period,
            MONTH
        )
    RETURN
        CALCULATE(
            AVERAGEX(
                VALUES('Date'[YearMonth]),
                [Total Sales]
            ),
            __DateRange
        )
```

### 性能说明
🟢 性能良好。DATESINPERIOD 是优化过的时间智能函数。

---

## 6. 半加性度量值（Semi-Additive Measures）

### 场景
库存、余额等快照数据，不能跨时间直接求和，需取最后一天的值。

### 代码
```dax
Closing Balance = 
    CALCULATE(
        [Balance Amount],
        LASTDATE('Date'[Date])
    )

// 或者处理非连续日期的场景
Closing Balance Safe = 
    VAR __LastDateWithData = 
        CALCULATE(
            MAX('Date'[Date]),
            REMOVEFILTERS('Date'),
            VALUES('Date'[YearMonth])  // 保留月份筛选
        )
    RETURN
        CALCULATE(
            [Balance Amount],
            'Date'[Date] = __LastDateWithData
        )
```

### 性能说明
🟢 性能良好。LASTDATE 是高效的标量函数。
