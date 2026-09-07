# Customer 新客净销售额 DAX

## 口径说明

基于「Customer.md」已计算的新客 user_id 集合（Step1 EXCEPT Step2），计算这些新客 user_id 在**所选时间范围**（本期/LY/LP 区间）对应的 `SUM(net_pay_amt) where is_member = 0`。

- **新客 user_id 集合**：`EXCEPT(SUMMARIZE(__NewCust_Step1, [user_id]), SUMMARIZE(__OldCust_Step2, [user_id]))`（仅 user_id 单列，已去重到用户级）
- **求和区间**：与 Customer.md 中 Step1 使用的区间一致（本期 / LY / LP 三套）
- **筛选**：`is_member = 0`（Customer KPI 固定非会员）
- **聚合字段**：`net_pay_amt`
- **实现方式**：`TREATAS(__NewCustUsers, 'a03_e2e_customer_data_m'[user_id])` 把新客用户集作为 user_id 列的筛选器，再 `CALCULATE(SUM(net_pay_amt), 区间, is_member=0)`

> 注：新客 user_id 集合本身按 user_id 粒度（不含 shop_info_id），但 TREATAS 到 user_id 列后会自动筛选该用户在所有 shop_info_id 下的明细行，platform/shop_info_id 由模型 1:N 关系自动筛选。

---

## 前置：日期变量（与 Customer.md 一致）

```dax
// ── 本期区间（Step 1 时间范围）──
VAR __PeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Min[TimeFrame_Min])
VAR __PeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Max[TimeFrame_Max])

// ── start_period 区间（Step 2 新客判定时间范围，第一个财月）──
VAR __StartPeriodMin = SELECTEDVALUE(Slicer_Time_Frame_Min[First_Fiscal_Month_Min])
VAR __StartPeriodMax = SELECTEDVALUE(Slicer_Time_Frame_Min[First_Fiscal_Month_Max])

// ── 本期 LY 区间（Step 1 时间范围，LY）──
VAR __PeriodMin_LY = SELECTEDVALUE(Slicer_Time_Frame_Min[TimeFrame_Min_LY])
VAR __PeriodMax_LY = SELECTEDVALUE(Slicer_Time_Frame_Max[TimeFrame_Max_LY])

// ── start_period LY 区间（Step 2 新客判定时间范围，LY）──
VAR __StartPeriodMin_LY = SELECTEDVALUE(Slicer_Time_Frame_Min[First_Fiscal_Month_Min_LY])
VAR __StartPeriodMax_LY = SELECTEDVALUE(Slicer_Time_Frame_Min[First_Fiscal_Month_Max_LY])

// ── 本期 LP 区间（Step 1 时间范围，LP）──
VAR __PeriodMin_LP = SELECTEDVALUE(Slicer_Time_Frame_Min[TimeFrame_Min_LP])
VAR __PeriodMax_LP = SELECTEDVALUE(Slicer_Time_Frame_Max[TimeFrame_Max_LP])

// ── start_period LP 区间（Step 2 新客判定时间范围，LP）──
VAR __StartPeriodMin_LP = SELECTEDVALUE(Slicer_Time_Frame_Min[First_Fiscal_Month_Min_LP])
VAR __StartPeriodMax_LP = SELECTEDVALUE(Slicer_Time_Frame_Min[First_Fiscal_Month_Max_LP])
```

---

## 本期：新客净销售额

```dax
// ═══════════════════════════════════════
// 新客净销售额（本期）：a03_e2e_customer_data_m
// 1. 复用 Customer.md 的 Step1/Step2 逻辑得到新客 user_id 集合
// 2. 对本期区间内 is_member=0 的这些新客 user_id 求 SUM(net_pay_amt)
// ═══════════════════════════════════════

// ── Step1（本期有消费的新客候选）：data_date ∈ [__PeriodMin, __PeriodMax]，is_member = 0，SUM(net_pay_amt) > 0 ──
VAR __NewCust_Step1 =
    SELECTCOLUMNS(
        FILTER(
            CALCULATETABLE(
                SUMMARIZECOLUMNS(
                    'a03_e2e_customer_data_m'[user_id],
                    'a03_e2e_customer_data_m'[shop_info_id],
                    "_net", SUM('a03_e2e_customer_data_m'[net_pay_amt])
                ),
                'a03_e2e_customer_data_m'[data_date] >= __PeriodMin,
                'a03_e2e_customer_data_m'[data_date] <= __PeriodMax,
                'a03_e2e_customer_data_m'[is_member] = 0
            ),
            [_net] > 0
        ),
        "user_id", [user_id],
        "shop_info_id", [shop_info_id]
    )

// ── Step2（第一财月的老客排除集）：data_date ∈ [__StartPeriodMin, __StartPeriodMax]，is_member = 0，SUM(lp_12m_net_pay_amt) > 0 ──
VAR __OldCust_Step2 =
    SELECTCOLUMNS(
        FILTER(
            CALCULATETABLE(
                SUMMARIZECOLUMNS(
                    'a03_e2e_customer_data_m'[user_id],
                    'a03_e2e_customer_data_m'[shop_info_id],
                    "_lp12m", SUM('a03_e2e_customer_data_m'[lp_12m_net_pay_amt])
                ),
                'a03_e2e_customer_data_m'[data_date] >= __StartPeriodMin,
                'a03_e2e_customer_data_m'[data_date] <= __StartPeriodMax,
                'a03_e2e_customer_data_m'[is_member] = 0
            ),
            [_lp12m] > 0
        ),
        "user_id", [user_id],
        "shop_info_id", [shop_info_id]
    )

// ── 新客 user_id 集合（去重到用户级）──
VAR __NewCustUsers =
    EXCEPT(
        SUMMARIZE(__NewCust_Step1, [user_id]),
        SUMMARIZE(__OldCust_Step2, [user_id])
    )

// ── 新客净销售额（本期）：对新客 user_id 在本期区间内求 SUM(net_pay_amt) where is_member = 0 ──
VAR __NewCustNetSales_Act =
    CALCULATE(
        SUM('a03_e2e_customer_data_m'[net_pay_amt]),
        'a03_e2e_customer_data_m'[data_date] >= __PeriodMin,
        'a03_e2e_customer_data_m'[data_date] <= __PeriodMax,
        'a03_e2e_customer_data_m'[is_member] = 0,
        TREATAS(__NewCustUsers, 'a03_e2e_customer_data_m'[user_id])
    )
```

---

## vs LY：新客净销售额（去年同期）

```dax
// ═══════════════════════════════════════
// 新客净销售额（去年同期）：a03_e2e_customer_data_m
// Step1+Step2 区间全部改为 LY，求 SUM(net_pay_amt) where is_member = 0
// ═══════════════════════════════════════

VAR __NewCust_Step1_LY =
    SELECTCOLUMNS(
        FILTER(
            CALCULATETABLE(
                SUMMARIZECOLUMNS(
                    'a03_e2e_customer_data_m'[user_id],
                    'a03_e2e_customer_data_m'[shop_info_id],
                    "_net", SUM('a03_e2e_customer_data_m'[net_pay_amt])
                ),
                'a03_e2e_customer_data_m'[data_date] >= __PeriodMin_LY,
                'a03_e2e_customer_data_m'[data_date] <= __PeriodMax_LY,
                'a03_e2e_customer_data_m'[is_member] = 0
            ),
            [_net] > 0
        ),
        "user_id", [user_id],
        "shop_info_id", [shop_info_id]
    )

VAR __OldCust_Step2_LY =
    SELECTCOLUMNS(
        FILTER(
            CALCULATETABLE(
                SUMMARIZECOLUMNS(
                    'a03_e2e_customer_data_m'[user_id],
                    'a03_e2e_customer_data_m'[shop_info_id],
                    "_lp12m", SUM('a03_e2e_customer_data_m'[lp_12m_net_pay_amt])
                ),
                'a03_e2e_customer_data_m'[data_date] >= __StartPeriodMin_LY,
                'a03_e2e_customer_data_m'[data_date] <= __StartPeriodMax_LY,
                'a03_e2e_customer_data_m'[is_member] = 0
            ),
            [_lp12m] > 0
        ),
        "user_id", [user_id],
        "shop_info_id", [shop_info_id]
    )

VAR __NewCustUsers_LY =
    EXCEPT(
        SUMMARIZE(__NewCust_Step1_LY, [user_id]),
        SUMMARIZE(__OldCust_Step2_LY, [user_id])
    )

VAR __NewCustNetSales_LY =
    CALCULATE(
        SUM('a03_e2e_customer_data_m'[net_pay_amt]),
        'a03_e2e_customer_data_m'[data_date] >= __PeriodMin_LY,
        'a03_e2e_customer_data_m'[data_date] <= __PeriodMax_LY,
        'a03_e2e_customer_data_m'[is_member] = 0,
        TREATAS(__NewCustUsers_LY, 'a03_e2e_customer_data_m'[user_id])
    )
```

---

## vs LP：新客净销售额（上期）

```dax
// ═══════════════════════════════════════
// 新客净销售额（上期）：a03_e2e_customer_data_m
// Step1+Step2 区间全部改为 LP，求 SUM(net_pay_amt) where is_member = 0
// ═══════════════════════════════════════

VAR __NewCust_Step1_LP =
    SELECTCOLUMNS(
        FILTER(
            CALCULATETABLE(
                SUMMARIZECOLUMNS(
                    'a03_e2e_customer_data_m'[user_id],
                    'a03_e2e_customer_data_m'[shop_info_id],
                    "_net", SUM('a03_e2e_customer_data_m'[net_pay_amt])
                ),
                'a03_e2e_customer_data_m'[data_date] >= __PeriodMin_LP,
                'a03_e2e_customer_data_m'[data_date] <= __PeriodMax_LP,
                'a03_e2e_customer_data_m'[is_member] = 0
            ),
            [_net] > 0
        ),
        "user_id", [user_id],
        "shop_info_id", [shop_info_id]
    )

VAR __OldCust_Step2_LP =
    SELECTCOLUMNS(
        FILTER(
            CALCULATETABLE(
                SUMMARIZECOLUMNS(
                    'a03_e2e_customer_data_m'[user_id],
                    'a03_e2e_customer_data_m'[shop_info_id],
                    "_lp12m", SUM('a03_e2e_customer_data_m'[lp_12m_net_pay_amt])
                ),
                'a03_e2e_customer_data_m'[data_date] >= __StartPeriodMin_LP,
                'a03_e2e_customer_data_m'[data_date] <= __StartPeriodMax_LP,
                'a03_e2e_customer_data_m'[is_member] = 0
            ),
            [_lp12m] > 0
        ),
        "user_id", [user_id],
        "shop_info_id", [shop_info_id]
    )

VAR __NewCustUsers_LP =
    EXCEPT(
        SUMMARIZE(__NewCust_Step1_LP, [user_id]),
        SUMMARIZE(__OldCust_Step2_LP, [user_id])
    )

VAR __NewCustNetSales_LP =
    CALCULATE(
        SUM('a03_e2e_customer_data_m'[net_pay_amt]),
        'a03_e2e_customer_data_m'[data_date] >= __PeriodMin_LP,
        'a03_e2e_customer_data_m'[data_date] <= __PeriodMax_LP,
        'a03_e2e_customer_data_m'[is_member] = 0,
        TREATAS(__NewCustUsers_LP, 'a03_e2e_customer_data_m'[user_id])
    )
```

---

## 实现要点

1. **新客集合与求和区间必须同源**：本期新客集合 → 本期区间求和；LY 新客集合 → LY 区间求和；LP 同理。不能跨区间混用。
2. **TREATAS 用法**：`TREATAS(__NewCustUsers, 'a03_e2e_customer_data_m'[user_id])` 把内存表（单列 user_id）作为筛选器应用到 fact 表的 user_id 列，比 `FILTER(..., [user_id] IN __NewCustUsers)` 性能更好且不依赖关系。
3. **去重粒度**：`__NewCustUsers` 只含 user_id 单列（已 SUMMARIZE 去重），TREATAS 后会自动筛选该用户在所有 shop_info_id 下的明细行——platform/shop_info_id 由模型 1:N 关系自动筛选，与 Customer.md 新客数口径保持一致。
4. **Step1 内部聚合粒度**：Step1/Step2 内部按 `user_id + shop_info_id` 聚合做 SUM 判定（与 Customer.md 一致），最终 EXCEPT 前各自 SUMMARIZE 去重到 user_id。
5. **字段名**：严格按口径文档使用 `lp_12m_net_pay_amt`（数据字典实际为 `last_12m_net_pay_amt`，若 PBI 报错需按实际字段名调整）。
