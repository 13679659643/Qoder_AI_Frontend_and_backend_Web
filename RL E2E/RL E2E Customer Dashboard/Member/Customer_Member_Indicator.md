# Power BI 解决方案 — Customer Member：Performance Indicator Value/Display 度量

> status: ready
> created: 2026-08-11
> type: 度量值开发 + 卡片图视觉对象
> 口径来源: 口径文档/Member.md Performance Indicator 子板块
> 参考实现: Performance By Location/PB_Location_Sales_detail.md（Value/Display 范式、LY 财历映射）
> 底表: a03_e2e_customer_data_m

---

## 1. 需求理解

为 Customer Dashboard - Member 页面 Performance Indicator 子板块输出卡片图所用的独立度量值（Value + Display），无 X 轴维度，仅受全局筛选器影响。

**指标清单**：

| 序号 | 指标 | 中文名 | 维度 | 时间聚合字段 | 分类 | 底表字段 |
|------|------|--------|------|------------|------|---------|
| 1 | DCom New Member Recruitment（Net/Demand） | DCom新增会员数 | Net/Demand 共用 | register_date | 数量类 | user_id（DISTINCTCOUNT） |
| 1.1 | DCom New Member Recruitment vs LY（Net/Demand） | DCom新增会员数同比 | Net/Demand 共用 | register_date | 数量类派生 | 今年/去年-1 |
| 1.2 | DCom New Member Recruitment vs LP（Net/Demand） | DCom新增会员数环比 | Net/Demand 共用 | register_date | 数量类派生 | 当期/上期-1 |
| 2 | DCom Member SLS（Net） | DCom会员净销售额 | Net | data_date | 金额类 | net_pay_amt |
| 2.1 | DCom Member SLS vs LY（Net） | DCom会员净销售额同比 | Net | data_date | 金额类派生 | 今年/去年-1 |
| 2.2 | DCom Member SLS vs LP（Net） | DCom会员净销售额环比 | Net | data_date | 金额类派生 | 当期/上期-1 |
| 3 | DCom Member SLS%（Net） | DCom会员净销售额占比 | Net | data_date | 比率类 | net_pay_amt / net_pay_amt |
| 3.1 | DCom Member SLS% vs LY（Net） | DCom会员净销售额占比同比 | Net | data_date | 比率类派生 | 今年-去年（差值，pts） |
| 3.2 | DCom Member SLS% vs LP（Net） | DCom会员净销售额占比环比 | Net | data_date | 比率类派生 | 当期-上期（差值，pts） |
| 4 | DCom Member SLS（Demand） | DCom会员销售额 | Demand | data_date | 金额类 | pay_amt |
| 4.1 | DCom Member SLS vs LY（Demand） | DCom会员销售额同比 | Demand | data_date | 金额类派生 | 今年/去年-1 |
| 4.2 | DCom Member SLS vs LP（Demand） | DCom会员销售额环比 | Demand | data_date | 金额类派生 | 当期/上期-1 |
| 5 | DCom Member SLS%（Demand） | DCom会员销售额占比 | Demand | data_date | 比率类 | pay_amt / pay_amt |
| 5.1 | DCom Member SLS% vs LY（Demand） | DCom会员销售额占比同比 | Demand | data_date | 比率类派生 | 今年-去年（差值，pts） |
| 5.2 | DCom Member SLS% vs LP（Demand） | DCom会员销售额占比环比 | Demand | data_date | 比率类派生 | 当期-上期（差值，pts） |

**核心设计原则**：
- 每个指标独立输出 Value 度量（原始数值）+ Display 度量（格式化文本）
- 口径中存在两种数据格式的指标，输出为两个不同的 Display 度量（如 `percent_1dp` 和 `delta_pct_1dp`）
- 无分组维度：卡片图场景，仅受全局筛选器影响，DAX 无需显式处理分组
- 分组维度（platform、shop_info_id）由模型自动传递筛选，DAX 无需显式处理
- LY 采用财历映射（读取日期表 `TimeFrame_Min_LY` / `TimeFrame_Max_LY`）
- LP 采用财历映射（读取日期表 `TimeFrame_Min_LP` / `TimeFrame_Max_LP`，日期表已新增）
- 金额类指标 ÷ `Currency_ExchangeRate` 汇率换算；比率类不除汇率（分子分母同币种相除抵消）
- vs LY / vs LP 同比值（今年/去年-1）不受 Currency 切片器影响（汇率相除抵消）
- 一切口径以口径文档 Member.md Performance Indicator 为准

---

## 2. 现状分析

### 2.1 数据底表

| 对象 | 名称 | 出处 |
|------|------|------|
| 事实表 | a03_e2e_customer_data_m | Member.md 全局逻辑 |
| 关键字段 | data_date, register_date, user_id, is_member, platform, shop_info_id, net_pay_amt, net_pay_amt, pay_amt, pay_amt | Member.md |

### 2.2 维度表清单（断开维度，沿用项目现有切片器）

| 维度表 | 类型 | 连接方式 |
|--------|------|---------|
| Slicer_Time_Frame_Min | 断开维度 | 起始切片器；SELECTEDVALUE 读取 TimeFrame_Min / TimeFrame_Min_LY / TimeFrame_Min_LP |
| Slicer_Time_Frame_Max | 断开维度 | 结束切片器；SELECTEDVALUE 读取 TimeFrame_Max / TimeFrame_Max_LY / TimeFrame_Max_LP |
| Slicer_Currency_Selection | 断开维度 | SELECTEDVALUE 读取 Currency_ExchangeRate / Currency_Symbol |

> 不使用 X 轴时间段维度（卡片图场景）。

---

## 3. 方案设计

### 3.1 筛选上下文

| 筛选器 | 作用方式 | DAX 处理 |
|--------|---------|---------|
| Slicer_Time_Frame_Min | 断开维度，SELECTEDVALUE 读取 TimeFrame_Min | `data_date / register_date >= __TimeMin` |
| Slicer_Time_Frame_Max | 断开维度，SELECTEDVALUE 读取 TimeFrame_Max | `data_date / register_date <= __TimeMax` |
| Slicer_Currency_Selection | 断开维度，SELECTEDVALUE 读取 Currency_ExchangeRate, Currency_Symbol | 金额类指标 ÷ Currency_ExchangeRate |
| 事实表分组字段（platform / shop_info_id） | 模型自动传递筛选 | DAX 无需显式处理 |

### 3.2 时间偏移规则（LY / LP — 财历映射）

直接读取日期表内置 LY / LP 字段：
- 全局 LY 起始日：`Slicer_Time_Frame_Min[TimeFrame_Min_LY]`
- 全局 LY 结束日：`Slicer_Time_Frame_Max[TimeFrame_Max_LY]`
- 全局 LP 起始日：`Slicer_Time_Frame_Min[TimeFrame_Min_LP]`
- 全局 LP 结束日：`Slicer_Time_Frame_Max[TimeFrame_Max_LP]`
- 无需 EDATE -12 或 Key 偏移计算

> 指标 1.x（新增会员数）按 `register_date` 聚合，LY/LP 时同样使用 register_date 配合 LY/LP 时间范围筛选。
> 指标 2.x ~ 5.x（销售额、占比）按 `data_date` 聚合，LY/LP 时使用 data_date 配合 LY/LP 时间范围筛选。

### 3.3 vs LY / vs LP 派生计算分类

| KPI 分类 | vs LY / vs LP 计算方式 | 格式类型 | 展示示例 |
|---------|----------------------|---------|---------|
| 数量类（New Member Recruitment） | 今年 / 去年 − 1 | percent_1dp / delta_pct_1dp | 14.5% / +14.5% |
| 金额类（Member SLS Net / Demand） | 今年 / 去年 − 1 | percent_1dp / delta_pct_1dp | 14.5% / +14.5% |
| 比率类（Member SLS% Net / Demand） | 今年 − 去年（差值，×100 转 pts） | delta_pts / integer_pts | +120pts / 120pts |

### 3.4 格式规范

| 格式类型 | 格式串 | 示例 | 适用度量 |
|---------|--------|------|---------|
| integer | `#,##0` | 1,234 | New Member Recruitment Value/Display |
| currency | `__CurrencySymbol & FORMAT(__Value, "#,##0")` | ¥1,234 | Member SLS Net/Demand |
| currency_k | `__CurrencySymbol & FORMAT(__Value / 1000, "#,##0") & "k"` | ¥1k / $5k | Member SLS Net/Demand |
| percent_1dp | `#,##0.0%` | 14.5% | vs LY/LP（数量类、金额类）不含正号；Member SLS% |
| delta_pct_1dp | `IF(__Value > 0, "+", "") & FORMAT(__Value, "0.0%")` | +14.5% / -3.2% | vs LY/LP（数量类、金额类）含正号 |
| delta_pts | `FORMAT(__Value * 100, "+#,##0pts;-#,##0pts;0pts")` | +120pts / -80pts | vs LY/LP（比率类）含正号 |
| integer_pts | `FORMAT(__Value * 100, "#,##0pts;-#,##0pts;0pts")` | 120pts / -80pts | vs LY/LP（比率类）不含正号 |

### 3.5 Display 度量命名规则

- 单一格式指标：Display 度量用格式类型后缀（如 `integer`、`percent_1dp`）
- 双格式指标：输出两个 Display 度量，分别用格式类型后缀（如 `percent_1dp` + `delta_pct_1dp`，或 `delta_pts` + `integer_pts`）
- Value 度量统一用 `Value` 后缀

---

## 4. 度量值实现

---

## 指标 1：DCom New Member Recruitment（Net/Demand）— DCom新增会员数

> 数量类 · Net/Demand 共用（新增会员数不区分 Net/Demand）· DISTINCTCOUNT(user_id)
> 按 register_date 聚合 · 不除汇率（数量类）

### 4.1 DCom New Member Recruitment Value

```dax
DCom New Member Recruitment Value =
// ========================================
// 度量值: DCom New Member Recruitment Value
// Display Folder: Member
// 用途: DCom新增会员数（卡片图数值）
// 口径来源: Member.md Performance Indicator - 1. DCom New Member Recruitment
// 计算公式: DISTINCTCOUNT(user_id)
// 筛选条件:
//   - is_member = 1
//   - register_date ∈ [__TimeMin, __TimeMax]（全局时间范围）
//   - Net/Demand 共用：新增会员数不区分 Net/Demand 维度
//   - 分组维度 platform / shop_info_id 由模型自动传递筛选，DAX 无需显式处理
//   - 数量类，不除汇率
// 数据类型: integer → 整数，千分位整数
// ========================================
    VAR __TimeMin = SELECTEDVALUE(Slicer_Time_Frame_Min[TimeFrame_Min])
    VAR __TimeMax = SELECTEDVALUE(Slicer_Time_Frame_Max[TimeFrame_Max])
    VAR __Result =
        CALCULATE(
            DISTINCTCOUNT('a03_e2e_customer_data_m'[user_id]),
            'a03_e2e_customer_data_m'[is_member] = 1,
            'a03_e2e_customer_data_m'[register_date] >= __TimeMin,
            'a03_e2e_customer_data_m'[register_date] <= __TimeMax
        )
    RETURN __Result
```

### 4.2 DCom New Member Recruitment integer

```dax
DCom New Member Recruitment integer =
// ========================================
// 度量值: DCom New Member Recruitment integer
// Display Folder: Member
// 用途: DCom新增会员数 格式化显示
// 依赖: [DCom New Member Recruitment Value]
// 格式类型: integer → #,##0
// ========================================
    VAR __Value = [DCom New Member Recruitment Value]
    RETURN
        IF(ISBLANK(__Value), "-", FORMAT(__Value, "#,##0"))
```

---

### 指标 1.1：DCom New Member Recruitment vs LY（Net/Demand）— 同比

> 数量类派生 · 今年 / 去年 - 1 · 按 register_date 聚合
> 两种 Display 格式：percent_1dp（不含正号）/ delta_pct_1dp（含正号）

### 4.3 DCom New Member Recruitment LY Value

```dax
DCom New Member Recruitment LY Value =
// ========================================
// 度量值: DCom New Member Recruitment LY Value
// Display Folder: Member
// 用途: LY DCom新增会员数（去年同期）
// 口径来源: Member.md Performance Indicator - 1.1 vs LY
// 计算公式: 去年同期 DISTINCTCOUNT(user_id)
// 时间偏移: 财历映射（读取日期表内置 LY 字段）
//   全局范围: Slicer_Time_Frame_Min[TimeFrame_Min_LY] / Slicer_Time_Frame_Max[TimeFrame_Max_LY]
//   按 register_date 聚合，LY 时使用 register_date 配合 LY 时间范围
//   数量类，不除汇率
// 数据类型: integer
// ========================================
    VAR __LYTimeMin = SELECTEDVALUE(Slicer_Time_Frame_Min[TimeFrame_Min_LY])
    VAR __LYTimeMax = SELECTEDVALUE(Slicer_Time_Frame_Max[TimeFrame_Max_LY])
    VAR __Result =
        CALCULATE(
            DISTINCTCOUNT('a03_e2e_customer_data_m'[user_id]),
            'a03_e2e_customer_data_m'[is_member] = 1,
            'a03_e2e_customer_data_m'[register_date] >= __LYTimeMin,
            'a03_e2e_customer_data_m'[register_date] <= __LYTimeMax
        )
    RETURN __Result
```

### 4.4 DCom New Member Recruitment vs LY Value

```dax
DCom New Member Recruitment vs LY Value =
// ========================================
// 度量值: DCom New Member Recruitment vs LY Value
// Display Folder: Member
// 用途: DCom新增会员数同比（今年/去年-1）
// 口径来源: Member.md Performance Indicator - 1.1 vs LY
// 计算公式: [DCom New Member Recruitment Value] / [DCom New Member Recruitment LY Value] - 1
// 派生类型: 数量类 → percent_1dp / delta_pct_1dp（今年/去年-1）
// 注: vs LY 同比值不受 Currency 切片器影响（数量类不涉及汇率）
// 数据类型: decimal（比率，-1~∞）
// ========================================
    VAR __TY = [DCom New Member Recruitment Value]
    VAR __LY = [DCom New Member Recruitment LY Value]
    RETURN
        IF(
            ISBLANK(__LY) || __LY = 0,
            BLANK(),
            DIVIDE(__TY, __LY) - 1
        )
```

### 4.5 DCom New Member Recruitment vs LY percent_1dp

```dax
DCom New Member Recruitment vs LY percent_1dp =
// ========================================
// 度量值: DCom New Member Recruitment vs LY percent_1dp
// Display Folder: Member
// 用途: DCom新增会员数同比 格式化显示（不含正号）
// 依赖: [DCom New Member Recruitment vs LY Value]
// 格式类型: percent_1dp → #,##0.0%
// ========================================
    VAR __Value = [DCom New Member Recruitment vs LY Value]
    RETURN
        IF(ISBLANK(__Value), "-", FORMAT(__Value, "#,##0.0%"))
```

### 4.6 DCom New Member Recruitment vs LY delta_pct_1dp

```dax
DCom New Member Recruitment vs LY delta_pct_1dp =
// ========================================
// 度量值: DCom New Member Recruitment vs LY delta_pct_1dp
// Display Folder: Member
// 用途: DCom新增会员数同比 格式化显示（含正号）
// 依赖: [DCom New Member Recruitment vs LY Value]
// 格式类型: delta_pct_1dp → 百分比，保留一位小数，含正号：+14.5% / -3.2%
//   格式串: IF(__Value > 0, "+", "") & FORMAT(__Value, "0.0%")
// ========================================
    VAR __Value = [DCom New Member Recruitment vs LY Value]
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            IF(__Value > 0, "+", "") & FORMAT(__Value, "0.0%")
        )
```

---

### 指标 1.2：DCom New Member Recruitment vs LP（Net/Demand）— 环比

> 数量类派生 · 当期 / 上期 - 1 · 按 register_date 聚合
> 两种 Display 格式：percent_1dp / delta_pct_1dp

### 4.7 DCom New Member Recruitment LP Value

```dax
DCom New Member Recruitment LP Value =
// ========================================
// 度量值: DCom New Member Recruitment LP Value
// Display Folder: Member
// 用途: LP DCom新增会员数（上期）
// 口径来源: Member.md Performance Indicator - 1.2 vs LP
// 计算公式: 上期 DISTINCTCOUNT(user_id)
// 时间偏移: 财历映射（读取日期表内置 LP 字段，日期表已新增）
//   全局范围: Slicer_Time_Frame_Min[TimeFrame_Min_LP] / Slicer_Time_Frame_Max[TimeFrame_Max_LP]
//   按 register_date 聚合，LP 时使用 register_date 配合 LP 时间范围
//   数量类，不除汇率
// 数据类型: integer
// ========================================
    VAR __LPTimeMin = SELECTEDVALUE(Slicer_Time_Frame_Min[TimeFrame_Min_LP])
    VAR __LPTimeMax = SELECTEDVALUE(Slicer_Time_Frame_Max[TimeFrame_Max_LP])
    VAR __Result =
        CALCULATE(
            DISTINCTCOUNT('a03_e2e_customer_data_m'[user_id]),
            'a03_e2e_customer_data_m'[is_member] = 1,
            'a03_e2e_customer_data_m'[register_date] >= __LPTimeMin,
            'a03_e2e_customer_data_m'[register_date] <= __LPTimeMax
        )
    RETURN __Result
```

### 4.8 DCom New Member Recruitment vs LP Value

```dax
DCom New Member Recruitment vs LP Value =
// ========================================
// 度量值: DCom New Member Recruitment vs LP Value
// Display Folder: Member
// 用途: DCom新增会员数环比（当期/上期-1）
// 口径来源: Member.md Performance Indicator - 1.2 vs LP
// 计算公式: [DCom New Member Recruitment Value] / [DCom New Member Recruitment LP Value] - 1
// 派生类型: 数量类 → percent_1dp / delta_pct_1dp（当期/上期-1）
// 注: vs LP 同比值不受 Currency 切片器影响（数量类不涉及汇率）
// 数据类型: decimal（比率，-1~∞）
// ========================================
    VAR __TY = [DCom New Member Recruitment Value]
    VAR __LP = [DCom New Member Recruitment LP Value]
    RETURN
        IF(
            ISBLANK(__LP) || __LP = 0,
            BLANK(),
            DIVIDE(__TY, __LP) - 1
        )
```

### 4.9 DCom New Member Recruitment vs LP percent_1dp

```dax
DCom New Member Recruitment vs LP percent_1dp =
// ========================================
// 度量值: DCom New Member Recruitment vs LP percent_1dp
// Display Folder: Member
// 用途: DCom新增会员数环比 格式化显示（不含正号）
// 依赖: [DCom New Member Recruitment vs LP Value]
// 格式类型: percent_1dp → #,##0.0%
// ========================================
    VAR __Value = [DCom New Member Recruitment vs LP Value]
    RETURN
        IF(ISBLANK(__Value), "-", FORMAT(__Value, "#,##0.0%"))
```

### 4.10 DCom New Member Recruitment vs LP delta_pct_1dp

```dax
DCom New Member Recruitment vs LP delta_pct_1dp =
// ========================================
// 度量值: DCom New Member Recruitment vs LP delta_pct_1dp
// Display Folder: Member
// 用途: DCom新增会员数环比 格式化显示（含正号）
// 依赖: [DCom New Member Recruitment vs LP Value]
// 格式类型: delta_pct_1dp → 百分比，保留一位小数，含正号：+14.5% / -3.2%
//   格式串: IF(__Value > 0, "+", "") & FORMAT(__Value, "0.0%")
// ========================================
    VAR __Value = [DCom New Member Recruitment vs LP Value]
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            IF(__Value > 0, "+", "") & FORMAT(__Value, "0.0%")
        )
```

---

## 指标 2：DCom Member SLS（Net）— DCom会员净销售额

> 金额类 · Net 维度 · SUM(net_pay_amt) · 按 data_date 聚合 · 除汇率
> 两种 Display 格式：currency / currency_k

### 4.11 DCom Member SLS Net Value

```dax
DCom Member SLS Net Value =
// ========================================
// 度量值: DCom Member SLS Net Value
// Display Folder: Member
// 用途: DCom会员净销售额 Net（卡片图数值）
// 口径来源: Member.md Performance Indicator - 2. DCom Member SLS Net
// 计算公式: SUM(net_pay_amt)
// 筛选条件:
//   - is_member = 1
//   - data_date ∈ [__TimeMin, __TimeMax]（全局时间范围）
//   - 分组维度 platform / shop_info_id 由模型自动传递筛选，DAX 无需显式处理
//   - 金额类指标 ÷ __FXRate（汇率换算）
// 数据类型: currency → 货币符号由币种切片器决定，千分位整数
// ========================================
    VAR __TimeMin = SELECTEDVALUE(Slicer_Time_Frame_Min[TimeFrame_Min])
    VAR __TimeMax = SELECTEDVALUE(Slicer_Time_Frame_Max[TimeFrame_Max])
    VAR __FXRate = SELECTEDVALUE('Slicer_Currency_Selection'[Currency_ExchangeRate], 1)
    VAR __Result =
        CALCULATE(
            SUM('a03_e2e_customer_data_m'[net_pay_amt]),
            'a03_e2e_customer_data_m'[is_member] = 1,
            'a03_e2e_customer_data_m'[data_date] >= __TimeMin,
            'a03_e2e_customer_data_m'[data_date] <= __TimeMax
        )
    RETURN DIVIDE(__Result, __FXRate)
```

### 4.12 DCom Member SLS Net currency

```dax
DCom Member SLS Net currency =
// ========================================
// 度量值: DCom Member SLS Net currency
// Display Folder: Member
// 用途: DCom会员净销售额 Net 格式化显示（千分位整数）
// 依赖: [DCom Member SLS Net Value], Slicer_Currency_Selection
// 格式类型: currency → __CurrencySymbol & FORMAT(__Value, "#,##0")
// ========================================
    VAR __Value = [DCom Member SLS Net Value]
    VAR __CurrencySymbol = SELECTEDVALUE('Slicer_Currency_Selection'[Currency_Symbol], "¥")
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            __CurrencySymbol & FORMAT(__Value, "#,##0")
        )
```

### 4.13 DCom Member SLS Net currency_k

```dax
DCom Member SLS Net currency_k =
// ========================================
// 度量值: DCom Member SLS Net currency_k
// Display Folder: Member
// 用途: DCom会员净销售额 Net 格式化显示（以 K 为单位）
// 依赖: [DCom Member SLS Net Value], Slicer_Currency_Selection
// 格式类型: currency_k → __CurrencySymbol & FORMAT(__Value / 1000, "#,##0") & "k"
// ========================================
    VAR __Value = [DCom Member SLS Net Value]
    VAR __CurrencySymbol = SELECTEDVALUE('Slicer_Currency_Selection'[Currency_Symbol], "¥")
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            __CurrencySymbol & FORMAT(__Value / 1000, "#,##0") & "k"
        )
```

---

### 指标 2.1：DCom Member SLS vs LY（Net）— 同比

> 金额类派生 · 今年 / 去年 - 1 · 按 data_date 聚合
> 两种 Display 格式：percent_1dp / delta_pct_1dp

### 4.14 DCom Member SLS Net LY Value

```dax
DCom Member SLS Net LY Value =
// ========================================
// 度量值: DCom Member SLS Net LY Value
// Display Folder: Member
// 用途: LY DCom会员净销售额 Net（去年同期）
// 口径来源: Member.md Performance Indicator - 2.1 vs LY
// 计算公式: 去年同期 SUM(net_pay_amt)
// 时间偏移: 财历映射（读取日期表内置 LY 字段）
//   全局范围: Slicer_Time_Frame_Min[TimeFrame_Min_LY] / Slicer_Time_Frame_Max[TimeFrame_Max_LY]
//   按 data_date 聚合，LY 时使用 data_date 配合 LY 时间范围
//   金额类指标 ÷ __FXRate（汇率换算）
// 数据类型: currency
// ========================================
    VAR __LYTimeMin = SELECTEDVALUE(Slicer_Time_Frame_Min[TimeFrame_Min_LY])
    VAR __LYTimeMax = SELECTEDVALUE(Slicer_Time_Frame_Max[TimeFrame_Max_LY])
    VAR __FXRate = SELECTEDVALUE('Slicer_Currency_Selection'[Currency_ExchangeRate], 1)
    VAR __Result =
        CALCULATE(
            SUM('a03_e2e_customer_data_m'[net_pay_amt]),
            'a03_e2e_customer_data_m'[is_member] = 1,
            'a03_e2e_customer_data_m'[data_date] >= __LYTimeMin,
            'a03_e2e_customer_data_m'[data_date] <= __LYTimeMax
        )
    RETURN DIVIDE(__Result, __FXRate)
```

### 4.15 DCom Member SLS Net vs LY Value

```dax
DCom Member SLS Net vs LY Value =
// ========================================
// 度量值: DCom Member SLS Net vs LY Value
// Display Folder: Member
// 用途: DCom会员净销售额 Net 同比（今年/去年-1）
// 口径来源: Member.md Performance Indicator - 2.1 vs LY
// 计算公式: [DCom Member SLS Net Value] / [DCom Member SLS Net LY Value] - 1
// 派生类型: 金额类 → percent_1dp / delta_pct_1dp（今年/去年-1）
// 注: vs LY 同比值不受 Currency 切片器影响（汇率在相除时自动抵消）
// 数据类型: decimal（比率，-1~∞）
// ========================================
    VAR __TY = [DCom Member SLS Net Value]
    VAR __LY = [DCom Member SLS Net LY Value]
    RETURN
        IF(
            ISBLANK(__LY) || __LY = 0,
            BLANK(),
            DIVIDE(__TY, __LY) - 1
        )
```

### 4.16 DCom Member SLS Net vs LY percent_1dp

```dax
DCom Member SLS Net vs LY percent_1dp =
// ========================================
// 度量值: DCom Member SLS Net vs LY percent_1dp
// Display Folder: Member
// 用途: DCom会员净销售额 Net 同比 格式化显示（不含正号）
// 依赖: [DCom Member SLS Net vs LY Value]
// 格式类型: percent_1dp → #,##0.0%
// ========================================
    VAR __Value = [DCom Member SLS Net vs LY Value]
    RETURN
        IF(ISBLANK(__Value), "-", FORMAT(__Value, "#,##0.0%"))
```

### 4.17 DCom Member SLS Net vs LY delta_pct_1dp

```dax
DCom Member SLS Net vs LY delta_pct_1dp =
// ========================================
// 度量值: DCom Member SLS Net vs LY delta_pct_1dp
// Display Folder: Member
// 用途: DCom会员净销售额 Net 同比 格式化显示（含正号）
// 依赖: [DCom Member SLS Net vs LY Value]
// 格式类型: delta_pct_1dp → 百分比，保留一位小数，含正号：+14.5% / -3.2%
//   格式串: IF(__Value > 0, "+", "") & FORMAT(__Value, "0.0%")
// ========================================
    VAR __Value = [DCom Member SLS Net vs LY Value]
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            IF(__Value > 0, "+", "") & FORMAT(__Value, "0.0%")
        )
```

---

### 指标 2.2：DCom Member SLS vs LP（Net）— 环比

> 金额类派生 · 当期 / 上期 - 1 · 按 data_date 聚合
> 两种 Display 格式：percent_1dp / delta_pct_1dp

### 4.18 DCom Member SLS Net LP Value

```dax
DCom Member SLS Net LP Value =
// ========================================
// 度量值: DCom Member SLS Net LP Value
// Display Folder: Member
// 用途: LP DCom会员净销售额 Net（上期）
// 口径来源: Member.md Performance Indicator - 2.2 vs LP
// 计算公式: 上期 SUM(net_pay_amt)
// 时间偏移: 财历映射（读取日期表内置 LP 字段，日期表已新增）
//   全局范围: Slicer_Time_Frame_Min[TimeFrame_Min_LP] / Slicer_Time_Frame_Max[TimeFrame_Max_LP]
//   按 data_date 聚合，LP 时使用 data_date 配合 LP 时间范围
//   金额类指标 ÷ __FXRate（汇率换算）
// 数据类型: currency
// ========================================
    VAR __LPTimeMin = SELECTEDVALUE(Slicer_Time_Frame_Min[TimeFrame_Min_LP])
    VAR __LPTimeMax = SELECTEDVALUE(Slicer_Time_Frame_Max[TimeFrame_Max_LP])
    VAR __FXRate = SELECTEDVALUE('Slicer_Currency_Selection'[Currency_ExchangeRate], 1)
    VAR __Result =
        CALCULATE(
            SUM('a03_e2e_customer_data_m'[net_pay_amt]),
            'a03_e2e_customer_data_m'[is_member] = 1,
            'a03_e2e_customer_data_m'[data_date] >= __LPTimeMin,
            'a03_e2e_customer_data_m'[data_date] <= __LPTimeMax
        )
    RETURN DIVIDE(__Result, __FXRate)
```

### 4.19 DCom Member SLS Net vs LP Value

```dax
DCom Member SLS Net vs LP Value =
// ========================================
// 度量值: DCom Member SLS Net vs LP Value
// Display Folder: Member
// 用途: DCom会员净销售额 Net 环比（当期/上期-1）
// 口径来源: Member.md Performance Indicator - 2.2 vs LP
// 计算公式: [DCom Member SLS Net Value] / [DCom Member SLS Net LP Value] - 1
// 派生类型: 金额类 → percent_1dp / delta_pct_1dp（当期/上期-1）
// 注: vs LP 同比值不受 Currency 切片器影响（汇率在相除时自动抵消）
// 数据类型: decimal（比率，-1~∞）
// ========================================
    VAR __TY = [DCom Member SLS Net Value]
    VAR __LP = [DCom Member SLS Net LP Value]
    RETURN
        IF(
            ISBLANK(__LP) || __LP = 0,
            BLANK(),
            DIVIDE(__TY, __LP) - 1
        )
```

### 4.20 DCom Member SLS Net vs LP percent_1dp

```dax
DCom Member SLS Net vs LP percent_1dp =
// ========================================
// 度量值: DCom Member SLS Net vs LP percent_1dp
// Display Folder: Member
// 用途: DCom会员净销售额 Net 环比 格式化显示（不含正号）
// 依赖: [DCom Member SLS Net vs LP Value]
// 格式类型: percent_1dp → #,##0.0%
// ========================================
    VAR __Value = [DCom Member SLS Net vs LP Value]
    RETURN
        IF(ISBLANK(__Value), "-", FORMAT(__Value, "#,##0.0%"))
```

### 4.21 DCom Member SLS Net vs LP delta_pct_1dp

```dax
DCom Member SLS Net vs LP delta_pct_1dp =
// ========================================
// 度量值: DCom Member SLS Net vs LP delta_pct_1dp
// Display Folder: Member
// 用途: DCom会员净销售额 Net 环比 格式化显示（含正号）
// 依赖: [DCom Member SLS Net vs LP Value]
// 格式类型: delta_pct_1dp → 百分比，保留一位小数，含正号：+14.5% / -3.2%
//   格式串: IF(__Value > 0, "+", "") & FORMAT(__Value, "0.0%")
// ========================================
    VAR __Value = [DCom Member SLS Net vs LP Value]
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            IF(__Value > 0, "+", "") & FORMAT(__Value, "0.0%")
        )
```

---

## 指标 3：DCom Member SLS%（Net）— DCom会员净销售额占比

> 比率类 · Net 维度 · SUM(net_pay_amt where is_member=1) / SUM(net_pay_amt is_member=0)
> 按 data_date 聚合 · 不除汇率（分子分母同币种相除抵消）
> 单一 Display 格式：percent_1dp

### 4.22 DCom Member SLS% Net Value

```dax
DCom Member SLS% Net Value =
// ========================================
// 度量值: DCom Member SLS% Net Value
// Display Folder: Member
// 用途: DCom会员净销售额占比 Net（卡片图数值）
// 口径来源: Member.md Performance Indicator - 3. DCom Member SLS% Net
// 计算公式: SUM(net_pay_amt where is_member=1) / SUM(net_pay_amt where is_member=0)
//   分子: net_pay_amt（is_member = 1）
//   分母: net_pay_amt（is_member=0）
// 筛选条件:
//   - data_date ∈ [__TimeMin, __TimeMax]（全局时间范围）
//   - 分组维度 platform / shop_info_id 由模型自动传递筛选，DAX 无需显式处理
//   - 比率类，不除汇率（分子分母同币种，相除自动抵消）
// 数据类型: percent_1dp → 百分比，保留一位小数，不含正号
// ========================================
    VAR __TimeMin = SELECTEDVALUE(Slicer_Time_Frame_Min[TimeFrame_Min])
    VAR __TimeMax = SELECTEDVALUE(Slicer_Time_Frame_Max[TimeFrame_Max])
    // 分子：net_pay_amt（is_member = 1）
    VAR __Numerator =
        CALCULATE(
            SUM('a03_e2e_customer_data_m'[net_pay_amt]),
            'a03_e2e_customer_data_m'[is_member] = 1,
            'a03_e2e_customer_data_m'[data_date] >= __TimeMin,
            'a03_e2e_customer_data_m'[data_date] <= __TimeMax
        )
    // 分母：net_pay_amt（is_member=0）
    VAR __Denominator =
        CALCULATE(
            SUM('a03_e2e_customer_data_m'[net_pay_amt]),
            'a03_e2e_customer_data_m'[is_member] = 0,
            'a03_e2e_customer_data_m'[data_date] >= __TimeMin,
            'a03_e2e_customer_data_m'[data_date] <= __TimeMax
        )
    RETURN DIVIDE(__Numerator, __Denominator)
```

### 4.23 DCom Member SLS% Net percent_1dp

```dax
DCom Member SLS% Net percent_1dp =
// ========================================
// 度量值: DCom Member SLS% Net percent_1dp
// Display Folder: Member
// 用途: DCom会员净销售额占比 Net 格式化显示
// 依赖: [DCom Member SLS% Net Value]
// 格式类型: percent_1dp → #,##0.0%
// ========================================
    VAR __Value = [DCom Member SLS% Net Value]
    RETURN
        IF(ISBLANK(__Value), "-", FORMAT(__Value, "#,##0.0%"))
```

---

### 指标 3.1：DCom Member SLS% vs LY（Net）— 占比同比

> 比率类派生 · 今年 - 去年（差值，×100 转 pts）· 按 data_date 聚合
> 两种 Display 格式：delta_pts（含正号）/ integer_pts（不含正号）
> Value 度量返回原始差值（小数），Display 度量乘以 100 转 pts

### 4.24 DCom Member SLS% Net LY Value

```dax
DCom Member SLS% Net LY Value =
// ========================================
// 度量值: DCom Member SLS% Net LY Value
// Display Folder: Member
// 用途: LY DCom会员净销售额占比 Net（去年同期）
// 口径来源: Member.md Performance Indicator - 3.1 vs LY
// 计算公式: 去年同期 SUM(net_pay_amt where is_member=1) / SUM(net_pay_amt is_member=0)
// 时间偏移: 财历映射（读取日期表内置 LY 字段）
//   全局范围: Slicer_Time_Frame_Min[TimeFrame_Min_LY] / Slicer_Time_Frame_Max[TimeFrame_Max_LY]
//   按 data_date 聚合，LY 时使用 data_date 配合 LY 时间范围
//   比率类，不除汇率
// 数据类型: percent_1dp
// ========================================
    VAR __LYTimeMin = SELECTEDVALUE(Slicer_Time_Frame_Min[TimeFrame_Min_LY])
    VAR __LYTimeMax = SELECTEDVALUE(Slicer_Time_Frame_Max[TimeFrame_Max_LY])
    // 分子：net_pay_amt（is_member = 1，去年同期）
    VAR __Numerator =
        CALCULATE(
            SUM('a03_e2e_customer_data_m'[net_pay_amt]),
            'a03_e2e_customer_data_m'[is_member] = 1,
            'a03_e2e_customer_data_m'[data_date] >= __LYTimeMin,
            'a03_e2e_customer_data_m'[data_date] <= __LYTimeMax
        )
    // 分母：net_pay_amt（is_member=0，去年同期）
    VAR __Denominator =
        CALCULATE(
            SUM('a03_e2e_customer_data_m'[net_pay_amt]),
            'a03_e2e_customer_data_m'[is_member] = 0,
            'a03_e2e_customer_data_m'[data_date] >= __LYTimeMin,
            'a03_e2e_customer_data_m'[data_date] <= __LYTimeMax
        )
    RETURN DIVIDE(__Numerator, __Denominator)
```

### 4.25 DCom Member SLS% Net vs LY Value

```dax
DCom Member SLS% Net vs LY Value =
// ========================================
// 度量值: DCom Member SLS% Net vs LY Value
// Display Folder: Member
// 用途: DCom会员净销售额占比 Net 同比（今年-去年，差值）
// 口径来源: Member.md Performance Indicator - 3.1 vs LY
// 计算公式: [DCom Member SLS% Net Value] - [DCom Member SLS% Net LY Value]
// 派生类型: 比率类 → delta_pts / integer_pts（今年-去年，差值，展示时 ×100 转 pts）
// 注: 乘以 100 的操作在 Display 度量中实现，Value 度量返回原始差值（小数）
// 数据类型: decimal（差值，-1~1 范围小数）
// ========================================
    VAR __TY = [DCom Member SLS% Net Value]
    VAR __LY = [DCom Member SLS% Net LY Value]
    RETURN __TY - __LY
```

### 4.26 DCom Member SLS% Net vs LY delta_pts

```dax
DCom Member SLS% Net vs LY delta_pts =
// ========================================
// 度量值: DCom Member SLS% Net vs LY delta_pts
// Display Folder: Member
// 用途: DCom会员净销售额占比 Net 同比 格式化显示（含正号）
// 依赖: [DCom Member SLS% Net vs LY Value]
// 格式类型: delta_pts → 增减基点整数，含正负号，值×100 转 pts
//   格式串: FORMAT(__Value * 100, "+#,##0pts;-#,##0pts;0pts")
//   示例: +120pts / -80pts / 0pts
// ========================================
    VAR __Value = [DCom Member SLS% Net vs LY Value]
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            FORMAT(__Value * 100, "+#,##0pts;-#,##0pts;0pts")
        )
```

### 4.27 DCom Member SLS% Net vs LY integer_pts

```dax
DCom Member SLS% Net vs LY integer_pts =
// ========================================
// 度量值: DCom Member SLS% Net vs LY integer_pts
// Display Folder: Member
// 用途: DCom会员净销售额占比 Net 同比 格式化显示（不含正号）
// 依赖: [DCom Member SLS% Net vs LY Value]
// 格式类型: integer_pts → 整数，千分位整数 pts，不含正号
//   格式串: FORMAT(__Value * 100, "#,##0pts;-#,##0pts;0pts")
//   示例: 120pts / -80pts / 0pts
// ========================================
    VAR __Value = [DCom Member SLS% Net vs LY Value]
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            FORMAT(__Value * 100, "#,##0pts;-#,##0pts;0pts")
        )
```

---

### 指标 3.2：DCom Member SLS% vs LP（Net）— 占比环比

> 比率类派生 · 当期 - 上期（差值，×100 转 pts）· 按 data_date 聚合
> 两种 Display 格式：delta_pts / integer_pts

### 4.28 DCom Member SLS% Net LP Value

```dax
DCom Member SLS% Net LP Value =
// ========================================
// 度量值: DCom Member SLS% Net LP Value
// Display Folder: Member
// 用途: LP DCom会员净销售额占比 Net（上期）
// 口径来源: Member.md Performance Indicator - 3.2 vs LP
// 计算公式: 上期 SUM(net_pay_amt where is_member=1) / SUM(net_pay_amt is_member=0)
// 时间偏移: 财历映射（读取日期表内置 LP 字段，日期表已新增）
//   全局范围: Slicer_Time_Frame_Min[TimeFrame_Min_LP] / Slicer_Time_Frame_Max[TimeFrame_Max_LP]
//   按 data_date 聚合，LP 时使用 data_date 配合 LP 时间范围
//   比率类，不除汇率
// 数据类型: percent_1dp
// ========================================
    VAR __LPTimeMin = SELECTEDVALUE(Slicer_Time_Frame_Min[TimeFrame_Min_LP])
    VAR __LPTimeMax = SELECTEDVALUE(Slicer_Time_Frame_Max[TimeFrame_Max_LP])
    // 分子：net_pay_amt（is_member = 1，上期）
    VAR __Numerator =
        CALCULATE(
            SUM('a03_e2e_customer_data_m'[net_pay_amt]),
            'a03_e2e_customer_data_m'[is_member] = 1,
            'a03_e2e_customer_data_m'[data_date] >= __LPTimeMin,
            'a03_e2e_customer_data_m'[data_date] <= __LPTimeMax
        )
    // 分母：net_pay_amt（is_member=0，上期）
    VAR __Denominator =
        CALCULATE(
            SUM('a03_e2e_customer_data_m'[net_pay_amt]),
            'a03_e2e_customer_data_m'[is_member] = 0,
            'a03_e2e_customer_data_m'[data_date] >= __LPTimeMin,
            'a03_e2e_customer_data_m'[data_date] <= __LPTimeMax
        )
    RETURN DIVIDE(__Numerator, __Denominator)
```

### 4.29 DCom Member SLS% Net vs LP Value

```dax
DCom Member SLS% Net vs LP Value =
// ========================================
// 度量值: DCom Member SLS% Net vs LP Value
// Display Folder: Member
// 用途: DCom会员净销售额占比 Net 环比（当期-上期，差值）
// 口径来源: Member.md Performance Indicator - 3.2 vs LP
// 计算公式: [DCom Member SLS% Net Value] - [DCom Member SLS% Net LP Value]
// 派生类型: 比率类 → delta_pts / integer_pts（当期-上期，差值，展示时 ×100 转 pts）
// 注: 乘以 100 的操作在 Display 度量中实现，Value 度量返回原始差值（小数）
// 数据类型: decimal（差值，-1~1 范围小数）
// ========================================
    VAR __TY = [DCom Member SLS% Net Value]
    VAR __LP = [DCom Member SLS% Net LP Value]
    RETURN __TY - __LP
```

### 4.30 DCom Member SLS% Net vs LP delta_pts

```dax
DCom Member SLS% Net vs LP delta_pts =
// ========================================
// 度量值: DCom Member SLS% Net vs LP delta_pts
// Display Folder: Member
// 用途: DCom会员净销售额占比 Net 环比 格式化显示（含正号）
// 依赖: [DCom Member SLS% Net vs LP Value]
// 格式类型: delta_pts → 增减基点整数，含正负号，值×100 转 pts
//   格式串: FORMAT(__Value * 100, "+#,##0pts;-#,##0pts;0pts")
//   示例: +120pts / -80pts / 0pts
// ========================================
    VAR __Value = [DCom Member SLS% Net vs LP Value]
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            FORMAT(__Value * 100, "+#,##0pts;-#,##0pts;0pts")
        )
```

### 4.31 DCom Member SLS% Net vs LP integer_pts

```dax
DCom Member SLS% Net vs LP integer_pts =
// ========================================
// 度量值: DCom Member SLS% Net vs LP integer_pts
// Display Folder: Member
// 用途: DCom会员净销售额占比 Net 环比 格式化显示（不含正号）
// 依赖: [DCom Member SLS% Net vs LP Value]
// 格式类型: integer_pts → 整数，千分位整数 pts，不含正号
//   格式串: FORMAT(__Value * 100, "#,##0pts;-#,##0pts;0pts")
//   示例: 120pts / -80pts / 0pts
// ========================================
    VAR __Value = [DCom Member SLS% Net vs LP Value]
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            FORMAT(__Value * 100, "#,##0pts;-#,##0pts;0pts")
        )
```

---

## 指标 4：DCom Member SLS（Demand）— DCom会员销售额

> 金额类 · Demand 维度 · SUM(pay_amt) · 按 data_date 聚合 · 除汇率
> 两种 Display 格式：currency / currency_k

### 4.32 DCom Member SLS Demand Value

```dax
DCom Member SLS Demand Value =
// ========================================
// 度量值: DCom Member SLS Demand Value
// Display Folder: Member
// 用途: DCom会员销售额 Demand（卡片图数值）
// 口径来源: Member.md Performance Indicator - 4. DCom Member SLS Demand
// 计算公式: SUM(pay_amt)
// 筛选条件:
//   - is_member = 1
//   - data_date ∈ [__TimeMin, __TimeMax]（全局时间范围）
//   - 分组维度 platform / shop_info_id 由模型自动传递筛选，DAX 无需显式处理
//   - 金额类指标 ÷ __FXRate（汇率换算）
// 数据类型: currency → 货币符号由币种切片器决定，千分位整数
// ========================================
    VAR __TimeMin = SELECTEDVALUE(Slicer_Time_Frame_Min[TimeFrame_Min])
    VAR __TimeMax = SELECTEDVALUE(Slicer_Time_Frame_Max[TimeFrame_Max])
    VAR __FXRate = SELECTEDVALUE('Slicer_Currency_Selection'[Currency_ExchangeRate], 1)
    VAR __Result =
        CALCULATE(
            SUM('a03_e2e_customer_data_m'[pay_amt]),
            'a03_e2e_customer_data_m'[is_member] = 1,
            'a03_e2e_customer_data_m'[data_date] >= __TimeMin,
            'a03_e2e_customer_data_m'[data_date] <= __TimeMax
        )
    RETURN DIVIDE(__Result, __FXRate)
```

### 4.33 DCom Member SLS Demand currency

```dax
DCom Member SLS Demand currency =
// ========================================
// 度量值: DCom Member SLS Demand currency
// Display Folder: Member
// 用途: DCom会员销售额 Demand 格式化显示（千分位整数）
// 依赖: [DCom Member SLS Demand Value], Slicer_Currency_Selection
// 格式类型: currency → __CurrencySymbol & FORMAT(__Value, "#,##0")
// ========================================
    VAR __Value = [DCom Member SLS Demand Value]
    VAR __CurrencySymbol = SELECTEDVALUE('Slicer_Currency_Selection'[Currency_Symbol], "¥")
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            __CurrencySymbol & FORMAT(__Value, "#,##0")
        )
```

### 4.34 DCom Member SLS Demand currency_k

```dax
DCom Member SLS Demand currency_k =
// ========================================
// 度量值: DCom Member SLS Demand currency_k
// Display Folder: Member
// 用途: DCom会员销售额 Demand 格式化显示（以 K 为单位）
// 依赖: [DCom Member SLS Demand Value], Slicer_Currency_Selection
// 格式类型: currency_k → __CurrencySymbol & FORMAT(__Value / 1000, "#,##0") & "k"
// ========================================
    VAR __Value = [DCom Member SLS Demand Value]
    VAR __CurrencySymbol = SELECTEDVALUE('Slicer_Currency_Selection'[Currency_Symbol], "¥")
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            __CurrencySymbol & FORMAT(__Value / 1000, "#,##0") & "k"
        )
```

---

### 指标 4.1：DCom Member SLS vs LY（Demand）— 同比

> 金额类派生 · 今年 / 去年 - 1 · 按 data_date 聚合
> 两种 Display 格式：percent_1dp / delta_pct_1dp

### 4.35 DCom Member SLS Demand LY Value

```dax
DCom Member SLS Demand LY Value =
// ========================================
// 度量值: DCom Member SLS Demand LY Value
// Display Folder: Member
// 用途: LY DCom会员销售额 Demand（去年同期）
// 口径来源: Member.md Performance Indicator - 4.1 vs LY
// 计算公式: 去年同期 SUM(pay_amt)
// 时间偏移: 财历映射（读取日期表内置 LY 字段）
//   全局范围: Slicer_Time_Frame_Min[TimeFrame_Min_LY] / Slicer_Time_Frame_Max[TimeFrame_Max_LY]
//   按 data_date 聚合，LY 时使用 data_date 配合 LY 时间范围
//   金额类指标 ÷ __FXRate（汇率换算）
// 数据类型: currency
// ========================================
    VAR __LYTimeMin = SELECTEDVALUE(Slicer_Time_Frame_Min[TimeFrame_Min_LY])
    VAR __LYTimeMax = SELECTEDVALUE(Slicer_Time_Frame_Max[TimeFrame_Max_LY])
    VAR __FXRate = SELECTEDVALUE('Slicer_Currency_Selection'[Currency_ExchangeRate], 1)
    VAR __Result =
        CALCULATE(
            SUM('a03_e2e_customer_data_m'[pay_amt]),
            'a03_e2e_customer_data_m'[is_member] = 1,
            'a03_e2e_customer_data_m'[data_date] >= __LYTimeMin,
            'a03_e2e_customer_data_m'[data_date] <= __LYTimeMax
        )
    RETURN DIVIDE(__Result, __FXRate)
```

### 4.36 DCom Member SLS Demand vs LY Value

```dax
DCom Member SLS Demand vs LY Value =
// ========================================
// 度量值: DCom Member SLS Demand vs LY Value
// Display Folder: Member
// 用途: DCom会员销售额 Demand 同比（今年/去年-1）
// 口径来源: Member.md Performance Indicator - 4.1 vs LY
// 计算公式: [DCom Member SLS Demand Value] / [DCom Member SLS Demand LY Value] - 1
// 派生类型: 金额类 → percent_1dp / delta_pct_1dp（今年/去年-1）
// 注: vs LY 同比值不受 Currency 切片器影响（汇率在相除时自动抵消）
// 数据类型: decimal（比率，-1~∞）
// ========================================
    VAR __TY = [DCom Member SLS Demand Value]
    VAR __LY = [DCom Member SLS Demand LY Value]
    RETURN
        IF(
            ISBLANK(__LY) || __LY = 0,
            BLANK(),
            DIVIDE(__TY, __LY) - 1
        )
```

### 4.37 DCom Member SLS Demand vs LY percent_1dp

```dax
DCom Member SLS Demand vs LY percent_1dp =
// ========================================
// 度量值: DCom Member SLS Demand vs LY percent_1dp
// Display Folder: Member
// 用途: DCom会员销售额 Demand 同比 格式化显示（不含正号）
// 依赖: [DCom Member SLS Demand vs LY Value]
// 格式类型: percent_1dp → #,##0.0%
// ========================================
    VAR __Value = [DCom Member SLS Demand vs LY Value]
    RETURN
        IF(ISBLANK(__Value), "-", FORMAT(__Value, "#,##0.0%"))
```

### 4.38 DCom Member SLS Demand vs LY delta_pct_1dp

```dax
DCom Member SLS Demand vs LY delta_pct_1dp =
// ========================================
// 度量值: DCom Member SLS Demand vs LY delta_pct_1dp
// Display Folder: Member
// 用途: DCom会员销售额 Demand 同比 格式化显示（含正号）
// 依赖: [DCom Member SLS Demand vs LY Value]
// 格式类型: delta_pct_1dp → 百分比，保留一位小数，含正号：+14.5% / -3.2%
//   格式串: IF(__Value > 0, "+", "") & FORMAT(__Value, "0.0%")
// ========================================
    VAR __Value = [DCom Member SLS Demand vs LY Value]
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            IF(__Value > 0, "+", "") & FORMAT(__Value, "0.0%")
        )
```

---

### 指标 4.2：DCom Member SLS vs LP（Demand）— 环比

> 金额类派生 · 当期 / 上期 - 1 · 按 data_date 聚合
> 两种 Display 格式：percent_1dp / delta_pct_1dp

### 4.39 DCom Member SLS Demand LP Value

```dax
DCom Member SLS Demand LP Value =
// ========================================
// 度量值: DCom Member SLS Demand LP Value
// Display Folder: Member
// 用途: LP DCom会员销售额 Demand（上期）
// 口径来源: Member.md Performance Indicator - 4.2 vs LP
// 计算公式: 上期 SUM(pay_amt)
// 时间偏移: 财历映射（读取日期表内置 LP 字段，日期表已新增）
//   全局范围: Slicer_Time_Frame_Min[TimeFrame_Min_LP] / Slicer_Time_Frame_Max[TimeFrame_Max_LP]
//   按 data_date 聚合，LP 时使用 data_date 配合 LP 时间范围
//   金额类指标 ÷ __FXRate（汇率换算）
// 数据类型: currency
// ========================================
    VAR __LPTimeMin = SELECTEDVALUE(Slicer_Time_Frame_Min[TimeFrame_Min_LP])
    VAR __LPTimeMax = SELECTEDVALUE(Slicer_Time_Frame_Max[TimeFrame_Max_LP])
    VAR __FXRate = SELECTEDVALUE('Slicer_Currency_Selection'[Currency_ExchangeRate], 1)
    VAR __Result =
        CALCULATE(
            SUM('a03_e2e_customer_data_m'[pay_amt]),
            'a03_e2e_customer_data_m'[is_member] = 1,
            'a03_e2e_customer_data_m'[data_date] >= __LPTimeMin,
            'a03_e2e_customer_data_m'[data_date] <= __LPTimeMax
        )
    RETURN DIVIDE(__Result, __FXRate)
```

### 4.40 DCom Member SLS Demand vs LP Value

```dax
DCom Member SLS Demand vs LP Value =
// ========================================
// 度量值: DCom Member SLS Demand vs LP Value
// Display Folder: Member
// 用途: DCom会员销售额 Demand 环比（当期/上期-1）
// 口径来源: Member.md Performance Indicator - 4.2 vs LP
// 计算公式: [DCom Member SLS Demand Value] / [DCom Member SLS Demand LP Value] - 1
// 派生类型: 金额类 → percent_1dp / delta_pct_1dp（当期/上期-1）
// 注: vs LP 同比值不受 Currency 切片器影响（汇率在相除时自动抵消）
// 数据类型: decimal（比率，-1~∞）
// ========================================
    VAR __TY = [DCom Member SLS Demand Value]
    VAR __LP = [DCom Member SLS Demand LP Value]
    RETURN
        IF(
            ISBLANK(__LP) || __LP = 0,
            BLANK(),
            DIVIDE(__TY, __LP) - 1
        )
```

### 4.41 DCom Member SLS Demand vs LP percent_1dp

```dax
DCom Member SLS Demand vs LP percent_1dp =
// ========================================
// 度量值: DCom Member SLS Demand vs LP percent_1dp
// Display Folder: Member
// 用途: DCom会员销售额 Demand 环比 格式化显示（不含正号）
// 依赖: [DCom Member SLS Demand vs LP Value]
// 格式类型: percent_1dp → #,##0.0%
// ========================================
    VAR __Value = [DCom Member SLS Demand vs LP Value]
    RETURN
        IF(ISBLANK(__Value), "-", FORMAT(__Value, "#,##0.0%"))
```

### 4.42 DCom Member SLS Demand vs LP delta_pct_1dp

```dax
DCom Member SLS Demand vs LP delta_pct_1dp =
// ========================================
// 度量值: DCom Member SLS Demand vs LP delta_pct_1dp
// Display Folder: Member
// 用途: DCom会员销售额 Demand 环比 格式化显示（含正号）
// 依赖: [DCom Member SLS Demand vs LP Value]
// 格式类型: delta_pct_1dp → 百分比，保留一位小数，含正号：+14.5% / -3.2%
//   格式串: IF(__Value > 0, "+", "") & FORMAT(__Value, "0.0%")
// ========================================
    VAR __Value = [DCom Member SLS Demand vs LP Value]
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            IF(__Value > 0, "+", "") & FORMAT(__Value, "0.0%")
        )
```

---

## 指标 5：DCom Member SLS%（Demand）— DCom会员销售额占比

> 比率类 · Demand 维度 · SUM(pay_amt where is_member=1) / SUM(pay_amt is_member=0)
> 按 data_date 聚合 · 不除汇率（分子分母同币种相除抵消）
> 单一 Display 格式：percent_1dp

### 4.43 DCom Member SLS% Demand Value

```dax
DCom Member SLS% Demand Value =
// ========================================
// 度量值: DCom Member SLS% Demand Value
// Display Folder: Member
// 用途: DCom会员销售额占比 Demand（卡片图数值）
// 口径来源: Member.md Performance Indicator - 5. DCom Member SLS% Demand
// 计算公式: SUM(pay_amt where is_member=1) / SUM(pay_amt is_member=0)
//   分子: pay_amt（is_member = 1）
//   分母: pay_amt（is_member=0）
// 筛选条件:
//   - data_date ∈ [__TimeMin, __TimeMax]（全局时间范围）
//   - 分组维度 platform / shop_info_id 由模型自动传递筛选，DAX 无需显式处理
//   - 比率类，不除汇率（分子分母同币种，相除自动抵消）
// 数据类型: percent_1dp → 百分比，保留一位小数，不含正号
// ========================================
    VAR __TimeMin = SELECTEDVALUE(Slicer_Time_Frame_Min[TimeFrame_Min])
    VAR __TimeMax = SELECTEDVALUE(Slicer_Time_Frame_Max[TimeFrame_Max])
    // 分子：pay_amt（is_member = 1）
    VAR __Numerator =
        CALCULATE(
            SUM('a03_e2e_customer_data_m'[pay_amt]),
            'a03_e2e_customer_data_m'[is_member] = 1,
            'a03_e2e_customer_data_m'[data_date] >= __TimeMin,
            'a03_e2e_customer_data_m'[data_date] <= __TimeMax
        )
    // 分母：pay_amt（is_member=0）
    VAR __Denominator =
        CALCULATE(
            SUM('a03_e2e_customer_data_m'[pay_amt]),
            'a03_e2e_customer_data_m'[is_member] = 0,
            'a03_e2e_customer_data_m'[data_date] >= __TimeMin,
            'a03_e2e_customer_data_m'[data_date] <= __TimeMax
        )
    RETURN DIVIDE(__Numerator, __Denominator)
```

### 4.44 DCom Member SLS% Demand percent_1dp

```dax
DCom Member SLS% Demand percent_1dp =
// ========================================
// 度量值: DCom Member SLS% Demand percent_1dp
// Display Folder: Member
// 用途: DCom会员销售额占比 Demand 格式化显示
// 依赖: [DCom Member SLS% Demand Value]
// 格式类型: percent_1dp → #,##0.0%
// ========================================
    VAR __Value = [DCom Member SLS% Demand Value]
    RETURN
        IF(ISBLANK(__Value), "-", FORMAT(__Value, "#,##0.0%"))
```

---

### 指标 5.1：DCom Member SLS% vs LY（Demand）— 占比同比

> 比率类派生 · 今年 - 去年（差值，×100 转 pts）· 按 data_date 聚合
> 两种 Display 格式：delta_pts / integer_pts

### 4.45 DCom Member SLS% Demand LY Value

```dax
DCom Member SLS% Demand LY Value =
// ========================================
// 度量值: DCom Member SLS% Demand LY Value
// Display Folder: Member
// 用途: LY DCom会员销售额占比 Demand（去年同期）
// 口径来源: Member.md Performance Indicator - 5.1 vs LY
// 计算公式: 去年同期 SUM(pay_amt where is_member=1) / SUM(pay_amt is_member=0)
// 时间偏移: 财历映射（读取日期表内置 LY 字段）
//   全局范围: Slicer_Time_Frame_Min[TimeFrame_Min_LY] / Slicer_Time_Frame_Max[TimeFrame_Max_LY]
//   按 data_date 聚合，LY 时使用 data_date 配合 LY 时间范围
//   比率类，不除汇率
// 数据类型: percent_1dp
// ========================================
    VAR __LYTimeMin = SELECTEDVALUE(Slicer_Time_Frame_Min[TimeFrame_Min_LY])
    VAR __LYTimeMax = SELECTEDVALUE(Slicer_Time_Frame_Max[TimeFrame_Max_LY])
    // 分子：pay_amt（is_member = 1，去年同期）
    VAR __Numerator =
        CALCULATE(
            SUM('a03_e2e_customer_data_m'[pay_amt]),
            'a03_e2e_customer_data_m'[is_member] = 1,
            'a03_e2e_customer_data_m'[data_date] >= __LYTimeMin,
            'a03_e2e_customer_data_m'[data_date] <= __LYTimeMax
        )
    // 分母：pay_amt（is_member=0，去年同期）
    VAR __Denominator =
        CALCULATE(
            SUM('a03_e2e_customer_data_m'[pay_amt]),
            'a03_e2e_customer_data_m'[is_member] = 0,
            'a03_e2e_customer_data_m'[data_date] >= __LYTimeMin,
            'a03_e2e_customer_data_m'[data_date] <= __LYTimeMax
        )
    RETURN DIVIDE(__Numerator, __Denominator)
```

### 4.46 DCom Member SLS% Demand vs LY Value

```dax
DCom Member SLS% Demand vs LY Value =
// ========================================
// 度量值: DCom Member SLS% Demand vs LY Value
// Display Folder: Member
// 用途: DCom会员销售额占比 Demand 同比（今年-去年，差值）
// 口径来源: Member.md Performance Indicator - 5.1 vs LY
// 计算公式: [DCom Member SLS% Demand Value] - [DCom Member SLS% Demand LY Value]
// 派生类型: 比率类 → delta_pts / integer_pts（今年-去年，差值，展示时 ×100 转 pts）
// 注: 乘以 100 的操作在 Display 度量中实现，Value 度量返回原始差值（小数）
// 数据类型: decimal（差值，-1~1 范围小数）
// ========================================
    VAR __TY = [DCom Member SLS% Demand Value]
    VAR __LY = [DCom Member SLS% Demand LY Value]
    RETURN __TY - __LY
```

### 4.47 DCom Member SLS% Demand vs LY delta_pts

```dax
DCom Member SLS% Demand vs LY delta_pts =
// ========================================
// 度量值: DCom Member SLS% Demand vs LY delta_pts
// Display Folder: Member
// 用途: DCom会员销售额占比 Demand 同比 格式化显示（含正号）
// 依赖: [DCom Member SLS% Demand vs LY Value]
// 格式类型: delta_pts → 增减基点整数，含正负号，值×100 转 pts
//   格式串: FORMAT(__Value * 100, "+#,##0pts;-#,##0pts;0pts")
//   示例: +120pts / -80pts / 0pts
// ========================================
    VAR __Value = [DCom Member SLS% Demand vs LY Value]
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            FORMAT(__Value * 100, "+#,##0pts;-#,##0pts;0pts")
        )
```

### 4.48 DCom Member SLS% Demand vs LY integer_pts

```dax
DCom Member SLS% Demand vs LY integer_pts =
// ========================================
// 度量值: DCom Member SLS% Demand vs LY integer_pts
// Display Folder: Member
// 用途: DCom会员销售额占比 Demand 同比 格式化显示（不含正号）
// 依赖: [DCom Member SLS% Demand vs LY Value]
// 格式类型: integer_pts → 整数，千分位整数 pts，不含正号
//   格式串: FORMAT(__Value * 100, "#,##0pts;-#,##0pts;0pts")
//   示例: 120pts / -80pts / 0pts
// ========================================
    VAR __Value = [DCom Member SLS% Demand vs LY Value]
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            FORMAT(__Value * 100, "#,##0pts;-#,##0pts;0pts")
        )
```

---

### 指标 5.2：DCom Member SLS% vs LP（Demand）— 占比环比

> 比率类派生 · 当期 - 上期（差值，×100 转 pts）· 按 data_date 聚合
> 两种 Display 格式：delta_pts / integer_pts

### 4.49 DCom Member SLS% Demand LP Value

```dax
DCom Member SLS% Demand LP Value =
// ========================================
// 度量值: DCom Member SLS% Demand LP Value
// Display Folder: Member
// 用途: LP DCom会员销售额占比 Demand（上期）
// 口径来源: Member.md Performance Indicator - 5.2 vs LP
// 计算公式: 上期 SUM(pay_amt where is_member=1) / SUM(pay_amt is_member=0)
// 时间偏移: 财历映射（读取日期表内置 LP 字段，日期表已新增）
//   全局范围: Slicer_Time_Frame_Min[TimeFrame_Min_LP] / Slicer_Time_Frame_Max[TimeFrame_Max_LP]
//   按 data_date 聚合，LP 时使用 data_date 配合 LP 时间范围
//   比率类，不除汇率
// 数据类型: percent_1dp
// ========================================
    VAR __LPTimeMin = SELECTEDVALUE(Slicer_Time_Frame_Min[TimeFrame_Min_LP])
    VAR __LPTimeMax = SELECTEDVALUE(Slicer_Time_Frame_Max[TimeFrame_Max_LP])
    // 分子：pay_amt（is_member = 1，上期）
    VAR __Numerator =
        CALCULATE(
            SUM('a03_e2e_customer_data_m'[pay_amt]),
            'a03_e2e_customer_data_m'[is_member] = 1,
            'a03_e2e_customer_data_m'[data_date] >= __LPTimeMin,
            'a03_e2e_customer_data_m'[data_date] <= __LPTimeMax
        )
    // 分母：pay_amt（is_member=0，上期）
    VAR __Denominator =
        CALCULATE(
            SUM('a03_e2e_customer_data_m'[pay_amt]),
            'a03_e2e_customer_data_m'[is_member] = 0,
            'a03_e2e_customer_data_m'[data_date] >= __LPTimeMin,
            'a03_e2e_customer_data_m'[data_date] <= __LPTimeMax
        )
    RETURN DIVIDE(__Numerator, __Denominator)
```

### 4.50 DCom Member SLS% Demand vs LP Value

```dax
DCom Member SLS% Demand vs LP Value =
// ========================================
// 度量值: DCom Member SLS% Demand vs LP Value
// Display Folder: Member
// 用途: DCom会员销售额占比 Demand 环比（当期-上期，差值）
// 口径来源: Member.md Performance Indicator - 5.2 vs LP
// 计算公式: [DCom Member SLS% Demand Value] - [DCom Member SLS% Demand LP Value]
// 派生类型: 比率类 → delta_pts / integer_pts（当期-上期，差值，展示时 ×100 转 pts）
// 注: 乘以 100 的操作在 Display 度量中实现，Value 度量返回原始差值（小数）
// 数据类型: decimal（差值，-1~1 范围小数）
// ========================================
    VAR __TY = [DCom Member SLS% Demand Value]
    VAR __LP = [DCom Member SLS% Demand LP Value]
    RETURN __TY - __LP
```

### 4.51 DCom Member SLS% Demand vs LP delta_pts

```dax
DCom Member SLS% Demand vs LP delta_pts =
// ========================================
// 度量值: DCom Member SLS% Demand vs LP delta_pts
// Display Folder: Member
// 用途: DCom会员销售额占比 Demand 环比 格式化显示（含正号）
// 依赖: [DCom Member SLS% Demand vs LP Value]
// 格式类型: delta_pts → 增减基点整数，含正负号，值×100 转 pts
//   格式串: FORMAT(__Value * 100, "+#,##0pts;-#,##0pts;0pts")
//   示例: +120pts / -80pts / 0pts
// ========================================
    VAR __Value = [DCom Member SLS% Demand vs LP Value]
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            FORMAT(__Value * 100, "+#,##0pts;-#,##0pts;0pts")
        )
```

### 4.52 DCom Member SLS% Demand vs LP integer_pts

```dax
DCom Member SLS% Demand vs LP integer_pts =
// ========================================
// 度量值: DCom Member SLS% Demand vs LP integer_pts
// Display Folder: Member
// 用途: DCom会员销售额占比 Demand 环比 格式化显示（不含正号）
// 依赖: [DCom Member SLS% Demand vs LP Value]
// 格式类型: integer_pts → 整数，千分位整数 pts，不含正号
//   格式串: FORMAT(__Value * 100, "#,##0pts;-#,##0pts;0pts")
//   示例: 120pts / -80pts / 0pts
// ========================================
    VAR __Value = [DCom Member SLS% Demand vs LP Value]
    RETURN
        IF(
            ISBLANK(__Value),
            "-",
            FORMAT(__Value * 100, "#,##0pts;-#,##0pts;0pts")
        )
```

---

## 5. 度量值清单与 Display Folder

| 序号 | 度量值名称 | Display Folder | 指标 | 维度 | 类型 | 格式 |
|------|-----------|----------------|------|------|------|------|
| 1 | DCom New Member Recruitment Value | Member | New Member Recruitment | Net/Demand | Value | integer |
| 2 | DCom New Member Recruitment integer | Member | New Member Recruitment | Net/Demand | Display | integer |
| 3 | DCom New Member Recruitment LY Value | Member | New Member Recruitment | Net/Demand | Value (LY) | integer |
| 4 | DCom New Member Recruitment vs LY Value | Member | New Member Recruitment vs LY | Net/Demand | Value (vs LY) | decimal |
| 5 | DCom New Member Recruitment vs LY percent_1dp | Member | New Member Recruitment vs LY | Net/Demand | Display | percent_1dp |
| 6 | DCom New Member Recruitment vs LY delta_pct_1dp | Member | New Member Recruitment vs LY | Net/Demand | Display | delta_pct_1dp |
| 7 | DCom New Member Recruitment LP Value | Member | New Member Recruitment | Net/Demand | Value (LP) | integer |
| 8 | DCom New Member Recruitment vs LP Value | Member | New Member Recruitment vs LP | Net/Demand | Value (vs LP) | decimal |
| 9 | DCom New Member Recruitment vs LP percent_1dp | Member | New Member Recruitment vs LP | Net/Demand | Display | percent_1dp |
| 10 | DCom New Member Recruitment vs LP delta_pct_1dp | Member | New Member Recruitment vs LP | Net/Demand | Display | delta_pct_1dp |
| 11 | DCom Member SLS Net Value | Member | Member SLS | Net | Value | currency |
| 12 | DCom Member SLS Net currency | Member | Member SLS | Net | Display | currency |
| 13 | DCom Member SLS Net currency_k | Member | Member SLS | Net | Display | currency_k |
| 14 | DCom Member SLS Net LY Value | Member | Member SLS | Net | Value (LY) | currency |
| 15 | DCom Member SLS Net vs LY Value | Member | Member SLS vs LY | Net | Value (vs LY) | decimal |
| 16 | DCom Member SLS Net vs LY percent_1dp | Member | Member SLS vs LY | Net | Display | percent_1dp |
| 17 | DCom Member SLS Net vs LY delta_pct_1dp | Member | Member SLS vs LY | Net | Display | delta_pct_1dp |
| 18 | DCom Member SLS Net LP Value | Member | Member SLS | Net | Value (LP) | currency |
| 19 | DCom Member SLS Net vs LP Value | Member | Member SLS vs LP | Net | Value (vs LP) | decimal |
| 20 | DCom Member SLS Net vs LP percent_1dp | Member | Member SLS vs LP | Net | Display | percent_1dp |
| 21 | DCom Member SLS Net vs LP delta_pct_1dp | Member | Member SLS vs LP | Net | Display | delta_pct_1dp |
| 22 | DCom Member SLS% Net Value | Member | Member SLS% | Net | Value | percent_1dp |
| 23 | DCom Member SLS% Net percent_1dp | Member | Member SLS% | Net | Display | percent_1dp |
| 24 | DCom Member SLS% Net LY Value | Member | Member SLS% | Net | Value (LY) | percent_1dp |
| 25 | DCom Member SLS% Net vs LY Value | Member | Member SLS% vs LY | Net | Value (vs LY) | decimal |
| 26 | DCom Member SLS% Net vs LY delta_pts | Member | Member SLS% vs LY | Net | Display | delta_pts |
| 27 | DCom Member SLS% Net vs LY integer_pts | Member | Member SLS% vs LY | Net | Display | integer_pts |
| 28 | DCom Member SLS% Net LP Value | Member | Member SLS% | Net | Value (LP) | percent_1dp |
| 29 | DCom Member SLS% Net vs LP Value | Member | Member SLS% vs LP | Net | Value (vs LP) | decimal |
| 30 | DCom Member SLS% Net vs LP delta_pts | Member | Member SLS% vs LP | Net | Display | delta_pts |
| 31 | DCom Member SLS% Net vs LP integer_pts | Member | Member SLS% vs LP | Net | Display | integer_pts |
| 32 | DCom Member SLS Demand Value | Member | Member SLS | Demand | Value | currency |
| 33 | DCom Member SLS Demand currency | Member | Member SLS | Demand | Display | currency |
| 34 | DCom Member SLS Demand currency_k | Member | Member SLS | Demand | Display | currency_k |
| 35 | DCom Member SLS Demand LY Value | Member | Member SLS | Demand | Value (LY) | currency |
| 36 | DCom Member SLS Demand vs LY Value | Member | Member SLS vs LY | Demand | Value (vs LY) | decimal |
| 37 | DCom Member SLS Demand vs LY percent_1dp | Member | Member SLS vs LY | Demand | Display | percent_1dp |
| 38 | DCom Member SLS Demand vs LY delta_pct_1dp | Member | Member SLS vs LY | Demand | Display | delta_pct_1dp |
| 39 | DCom Member SLS Demand LP Value | Member | Member SLS | Demand | Value (LP) | currency |
| 40 | DCom Member SLS Demand vs LP Value | Member | Member SLS vs LP | Demand | Value (vs LP) | decimal |
| 41 | DCom Member SLS Demand vs LP percent_1dp | Member | Member SLS vs LP | Demand | Display | percent_1dp |
| 42 | DCom Member SLS Demand vs LP delta_pct_1dp | Member | Member SLS vs LP | Demand | Display | delta_pct_1dp |
| 43 | DCom Member SLS% Demand Value | Member | Member SLS% | Demand | Value | percent_1dp |
| 44 | DCom Member SLS% Demand percent_1dp | Member | Member SLS% | Demand | Display | percent_1dp |
| 45 | DCom Member SLS% Demand LY Value | Member | Member SLS% | Demand | Value (LY) | percent_1dp |
| 46 | DCom Member SLS% Demand vs LY Value | Member | Member SLS% vs LY | Demand | Value (vs LY) | decimal |
| 47 | DCom Member SLS% Demand vs LY delta_pts | Member | Member SLS% vs LY | Demand | Display | delta_pts |
| 48 | DCom Member SLS% Demand vs LY integer_pts | Member | Member SLS% vs LY | Demand | Display | integer_pts |
| 49 | DCom Member SLS% Demand LP Value | Member | Member SLS% | Demand | Value (LP) | percent_1dp |
| 50 | DCom Member SLS% Demand vs LP Value | Member | Member SLS% vs LP | Demand | Value (vs LP) | decimal |
| 51 | DCom Member SLS% Demand vs LP delta_pts | Member | Member SLS% vs LP | Demand | Display | delta_pts |
| 52 | DCom Member SLS% Demand vs LP integer_pts | Member | Member SLS% vs LP | Demand | Display | integer_pts |

---

## 6. 视觉对象配置

### 6.1 卡片图（Card）

| 配置项 | 值 |
|--------|-----|
| 值 | 拉取对应的 Display 度量（如 `DCom New Member Recruitment integer`） |
| 全局筛选器 | Slicer_Time_Frame_Min、Slicer_Time_Frame_Max、Slicer_Currency_Selection |
| 分组维度筛选 | platform / shop_info_id 由模型自动传递，无需显式拉取 |

### 6.2 度量值拉取示例

| 卡片场景 | 拉取度量 |
|---------|---------|
| DCom新增会员数（本期） | [DCom New Member Recruitment integer] |
| DCom新增会员数同比（不含正号） | [DCom New Member Recruitment vs LY percent_1dp] |
| DCom新增会员数同比（含正号） | [DCom New Member Recruitment vs LY delta_pct_1dp] |
| DCom新增会员数环比（不含正号） | [DCom New Member Recruitment vs LP percent_1dp] |
| DCom新增会员数环比（含正号） | [DCom New Member Recruitment vs LP delta_pct_1dp] |
| DCom会员净销售额（本期，千分位） | [DCom Member SLS Net currency] |
| DCom会员净销售额（本期，K 单位） | [DCom Member SLS Net currency_k] |
| DCom会员净销售额同比（不含正号） | [DCom Member SLS Net vs LY percent_1dp] |
| DCom会员净销售额同比（含正号） | [DCom Member SLS Net vs LY delta_pct_1dp] |
| DCom会员净销售额环比（不含正号） | [DCom Member SLS Net vs LP percent_1dp] |
| DCom会员净销售额环比（含正号） | [DCom Member SLS Net vs LP delta_pct_1dp] |
| DCom会员净销售额占比（本期） | [DCom Member SLS% Net percent_1dp] |
| DCom会员净销售额占比同比（含正号 pts） | [DCom Member SLS% Net vs LY delta_pts] |
| DCom会员净销售额占比同比（不含正号 pts） | [DCom Member SLS% Net vs LY integer_pts] |
| DCom会员净销售额占比环比（含正号 pts） | [DCom Member SLS% Net vs LP delta_pts] |
| DCom会员净销售额占比环比（不含正号 pts） | [DCom Member SLS% Net vs LP integer_pts] |
| DCom会员销售额（Demand，千分位） | [DCom Member SLS Demand currency] |
| DCom会员销售额（Demand，K 单位） | [DCom Member SLS Demand currency_k] |
| DCom会员销售额同比（Demand，不含正号） | [DCom Member SLS Demand vs LY percent_1dp] |
| DCom会员销售额同比（Demand，含正号） | [DCom Member SLS Demand vs LY delta_pct_1dp] |
| DCom会员销售额环比（Demand，不含正号） | [DCom Member SLS Demand vs LP percent_1dp] |
| DCom会员销售额环比（Demand，含正号） | [DCom Member SLS Demand vs LP delta_pct_1dp] |
| DCom会员销售额占比（Demand，本期） | [DCom Member SLS% Demand percent_1dp] |
| DCom会员销售额占比同比（Demand，含正号 pts） | [DCom Member SLS% Demand vs LY delta_pts] |
| DCom会员销售额占比同比（Demand，不含正号 pts） | [DCom Member SLS% Demand vs LY integer_pts] |
| DCom会员销售额占比环比（Demand，含正号 pts） | [DCom Member SLS% Demand vs LP delta_pts] |
| DCom会员销售额占比环比（Demand，不含正号 pts） | [DCom Member SLS% Demand vs LP integer_pts] |

---

## 7. 验证方法

### 7.1 验证 SQL

```sql
-- 指标1：DCom新增会员数（本期，按 register_date 筛选）
-- 假设 __TimeMin='2025-06-29', __TimeMax='2025-08-09'
SELECT COUNT(DISTINCT user_id) AS New_Member_Recruitment
FROM a03_e2e_customer_data_m
WHERE is_member = 1
  AND register_date BETWEEN '2025-06-29' AND '2025-08-09';

-- 指标1 LY：DCom新增会员数（去年同期，register_date 配合 LY 范围）
SELECT COUNT(DISTINCT user_id) AS New_Member_Recruitment_LY
FROM a03_e2e_customer_data_m
WHERE is_member = 1
  AND register_date BETWEEN '__LYTimeMin' AND '__LYTimeMax';

-- 指标1 vs LY = New_Member_Recruitment / New_Member_Recruitment_LY - 1（percent_1dp / delta_pct_1dp）

-- 指标2：DCom会员净销售额 Net（本期，按 data_date 筛选）
SELECT SUM(net_pay_amt) AS Member_SLS_Net
FROM a03_e2e_customer_data_m
WHERE is_member = 1
  AND data_date BETWEEN '__TimeMin' AND '__TimeMax';

-- 指标2 LY：DCom会员净销售额 Net（去年同期，data_date 配合 LY 范围）
SELECT SUM(net_pay_amt) AS Member_SLS_Net_LY
FROM a03_e2e_customer_data_m
WHERE is_member = 1
  AND data_date BETWEEN '__LYTimeMin' AND '__LYTimeMax';

-- 指标2 vs LY = Member_SLS_Net / Member_SLS_Net_LY - 1（percent_1dp / delta_pct_1dp）

-- 指标3：DCom会员净销售额占比 Net（本期）
SELECT
  SUM(CASE WHEN is_member = 1 THEN net_pay_amt ELSE 0 END) * 1.0
  / SUM(net_pay_amt) AS Member_SLS_Pct_Net
FROM a03_e2e_customer_data_m
WHERE data_date BETWEEN '__TimeMin' AND '__TimeMax';

-- 指标3 vs LY = Member_SLS_Pct_Net - Member_SLS_Pct_Net_LY（delta_pts / integer_pts，×100 转 pts）

-- 指标4：DCom会员销售额 Demand（本期）
SELECT SUM(pay_amt) AS Member_SLS_Demand
FROM a03_e2e_customer_data_m
WHERE is_member = 1
  AND data_date BETWEEN '__TimeMin' AND '__TimeMax';

-- 指标5：DCom会员销售额占比 Demand（本期）
SELECT
  SUM(CASE WHEN is_member = 1 THEN pay_amt ELSE 0 END) * 1.0
  / SUM(pay_amt) AS Member_SLS_Pct_Demand
FROM a03_e2e_customer_data_m
WHERE data_date BETWEEN '__TimeMin' AND '__TimeMax';

-- 指标5 vs LY = Member_SLS_Pct_Demand - Member_SLS_Pct_Demand_LY（delta_pts / integer_pts，×100 转 pts）
```

### 7.2 LY / LP 日期范围获取方式说明

| TimeFrame_ID | LY 范围获取方式 | LP 范围获取方式 |
|--------------|-----------------|-----------------|
| Day / Week / Month / Quarter / Year | 直接读日期表 `TimeFrame_Min_LY` / `TimeFrame_Max_LY` | 直接读日期表 `TimeFrame_Min_LP` / `TimeFrame_Max_LP` |

---

## 8. 注意事项

1. **Net/Demand 共用指标**：指标 1（DCom New Member Recruitment）的 Net/Demand 维度共用同一度量值，因为新增会员数（DISTINCTCOUNT user_id）不区分 Net/Demand 销售额口径。口径文档中标注 (Net/Demand) 表示该指标同时服务于两个维度的卡片展示。

2. **register_date vs data_date**：
   - 指标 1.x（新增会员数）：按 `register_date` 聚合，LY/LP 时使用 register_date 配合 LY/LP 时间范围筛选
   - 指标 2.x ~ 5.x（销售额、占比）：按 `data_date` 聚合，LY/LP 时使用 data_date 配合 LY/LP 时间范围筛选

3. **LY / LP 财历映射**：周/月/季/年粒度按财年定义，LY/LP 均采用财历映射（直接读取日期表内置 `TimeFrame_Min_LY` / `TimeFrame_Max_LY` / `TimeFrame_Min_LP` / `TimeFrame_Max_LP` 字段），不使用 EDATE -12。日期表需包含至少 2 年历史数据。若数据历史不足，LY/LP 字段返回 BLANK，显示"-"，属可接受行为。

4. **汇率换算**：
   - 金额类指标（Member SLS Net / Demand）：÷ `Currency_ExchangeRate`
   - 比率类（Member SLS% Net / Demand）：分子分母同币种相除自动抵消，不除汇率
   - vs LY / vs LP 同比值（今年/去年-1）：汇率在相除时自动抵消
   - vs LY / vs LP 差值（今年-去年，pts）：比率类差值，不涉及汇率

5. **vs LY / vs LP 派生分类**：
   - 数量类（New Member Recruitment）：今年 / 去年 − 1 → `percent_1dp` / `delta_pct_1dp`
   - 金额类（Member SLS Net / Demand）：今年 / 去年 − 1 → `percent_1dp` / `delta_pct_1dp`
   - 比率类（Member SLS% Net / Demand）：今年 − 去年 → `delta_pts` / `integer_pts`（展示时 ×100 转 pts，乘以 100 的操作在 Display 度量中实现）

6. **Member SLS% 分母规则**：占比指标的分子过滤 `is_member = 1`，分母不过滤 `is_member`（全店销售额 net_pay_amt / pay_amt），与口径文档一致。

7. **分组维度传递**：platform / shop_info_id 等分组字段由模型自动传递筛选，DAX 度量值无需显式处理分组逻辑。

8. **无 X 轴时间维度**：本方案仅用全局时间范围筛选（Slicer_Time_Frame_Min / Slicer_Time_Frame_Max），卡片图场景不涉及 X 轴时间段双层筛选。

9. **双格式 Display 度量**：口径中存在两种数据格式的指标，输出为两个独立的 Display 度量，命名采用格式类型后缀（如 `percent_1dp` + `delta_pct_1dp`、`currency` + `currency_k`、`delta_pts` + `integer_pts`），便于卡片图按需拉取不同展示格式。

10. **pts 与 bp 区别**：pts 指标值 ×100 转 pts（基点），数据格式 `+#,##0pts;-#,##0pts;0pts`；bp 指标值 ×10000 转 bp，数据格式 `+#,##0bp;-#,##0bp;0bp`。本方案占比同比/环比使用 pts（非 bp），与口径文档一致。

11. **Display 命名约定**：遵循用户要求，双格式指标的 Display 度量以格式类型命名（如 `DCom New Member Recruitment vs LY percent_1dp` 和 `DCom New Member Recruitment vs LY delta_pct_1dp`），而非统一的 "Display" 后缀。

12. **Comment 备注待确认**：口径文档通用规则汇总中提到"新增会员如果没有购买是否需要统计，如果需要统计，当前的设计需要调整" — 此问题待业务确认。本方案按当前口径文档定义实现（注册日期在范围内即统计，不要求有购买行为）。

## 9. 拓展度量
> 颜色约定:
> 正值（>0）：#1A9018 绿色
> 负值（<0）：#D64550 红色
> 零值（=0）：#E1C233 黄色
> 默认：#5f6165 深灰
### 9.1 DCom Member SLS Demand Value

```dax
New Member Recruitment vs LY Color = 
VAR _Value = [DCom New Member Recruitment vs LY Value]
RETURN
SWITCH(
    TRUE(),
    _Value = 0, "#E1C233",  -- 等于0：黄色
    _Value > 0, "#1A9018",  -- 大于0：深绿色
    _Value < 0, "#D64550",  -- 小于0：红色
    "#5f6165"  -- 其他情况
)
```
