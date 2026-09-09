# 新客 No. 模板详解

New Customer No. 模板详解 = 

// ═══════════════════════════════════════════════════════════
// 变量定义区
// ── 时间筛选：去年同期（直接读取日期表内置 LY 字段）──
VAR __LPTimeMin = SELECTEDVALUE(Slicer_Time_Frame_Min[TimeFrame_Min_LY])
VAR __LPTimeMax = SELECTEDVALUE(Slicer_Time_Frame_Max[TimeFrame_Max_LY])
// ── 第一财月区间（去年同期，新客 Step2 的 start_period）──
VAR __LPFirstFiscalMonthMin = SELECTEDVALUE(Slicer_Time_Frame_Min[First_Fiscal_Month_Min_LY])
VAR __LPFirstFiscalMonthMax = SELECTEDVALUE(Slicer_Time_Frame_Min[First_Fiscal_Month_Max_LY])
// ═══════════════════════════════════════════════════════════

// ── 日期范围（模拟筛选器，正式使用时取消注释下方两行）──
VAR __TimeMin = DATEVALUE("2026-05-24")
VAR __TimeMax = DATEVALUE("2026-07-25")
// VAR __TimeMin = SELECTEDVALUE(Slicer_Month_Period_Min[TimeFrame_Min])
// VAR __TimeMax = SELECTEDVALUE(Slicer_Month_Period_Max[TimeFrame_Max])

// ── 第一财月区间（Step2 使用的 data_date 范围）──
VAR __FirstFiscalMonthMin = DATEVALUE("2026-05-24")
VAR __FirstFiscalMonthMax = DATEVALUE("2026-06-27")
// VAR __FirstFiscalMonthMin = SELECTEDVALUE(Slicer_Time_Frame_Min[First_Fiscal_Month_Min])
// VAR __FirstFiscalMonthMax = SELECTEDVALUE(Slicer_Time_Frame_Min[First_Fiscal_Month_Max])

// ── 时间粒度判断：Day/Week 不计算 ──
VAR __TimeFrameID = SELECTEDVALUE(Slicer_Time_Frame[TimeFrame_ID])
VAR __IsDayOrWeek = __TimeFrameID IN {"Day", "Week"}

// ═══════════════════════════════════════════════════════════
// 提前短路：Day/Week 粒度直接返回空，不执行后续任何计算
// ═══════════════════════════════════════════════════════════
RETURN
IF(
    __IsDayOrWeek,
    BLANK(),

// ═══════════════════════════════════════════════════════════
// 子查询a（对应SQL的 FROM ... WHERE data_month IN (...) GROUP BY）
//
// 逻辑：在所选时间范围内，非会员有消费的记录，按 user_id + shop_name_en 聚合
//
// 关于多选筛选器（shop_name_en / platform）：
//   CALCULATETABLE() 在当前筛选上下文中执行，
//   外部筛选器（视觉对象上的多选Slicer）会自动注入筛选上下文，
//   无需在DAX中手动添加。
//
// 关于 CALCULATETABLE：
//   将筛选条件作为参数传入，由 VertiPaq 引擎在列存储层面执行过滤，
//   比 FILTER(表, ...) 逐行扫描更高效。
//
// 关于 SUMMARIZECOLUMNS：
//   存储引擎原生聚合函数，自动生成最优查询计划，
//   性能优于 SUMMARIZE + FILTER 的组合。
// ═══════════════════════════════════════════════════════════
    VAR _New = 
        SELECTCOLUMNS(
            FILTER(
                CALCULATETABLE(
                    SUMMARIZECOLUMNS(
                        'a03_e2e_customer_data_m'[user_id],
                        'a03_e2e_customer_data_m'[shop_name_en],
                        "_net", SUM('a03_e2e_customer_data_m'[net_pay_amt])
                    ),
                    'a03_e2e_customer_data_m'[data_date] >= __TimeMin,
                    'a03_e2e_customer_data_m'[data_date] <= __TimeMax,
                    'a03_e2e_customer_data_m'[is_member] = 0
                ),
                [_net] > 0
            ),
            "user_id", [user_id],
            "shop_name_en", [shop_name_en]
        )

// ═══════════════════════════════════════════════════════════
// 排除集（对应SQL中需要排除的用户）
//
// 逻辑：在第一财月区间内，非会员且过去12个月消费 > 0 的用户
//
// 注意：这里只筛选 [_lp12m] > 0 的用户（老客），
//       后续用 EXCEPT 从 _New 中减去。
//
// 为什么用 > 0 而不是 = 0：
//   SQL 的保留条件是 (IS NULL OR = 0)
//   等价于排除条件是 > 0
//   所以这里收集的是"需要排除的用户"
// ═══════════════════════════════════════════════════════════
    VAR _Old = 
        SELECTCOLUMNS(
            FILTER(
                CALCULATETABLE(
                    SUMMARIZECOLUMNS(
                        'a03_e2e_customer_data_m'[user_id],
                        'a03_e2e_customer_data_m'[shop_name_en],
                        "_lp12m", SUM('a03_e2e_customer_data_m'[lp_12m_net_pay_amt])
                    ),
                    'a03_e2e_customer_data_m'[data_date] >= __FirstFiscalMonthMin,
                    'a03_e2e_customer_data_m'[data_date] <= __FirstFiscalMonthMax,
                    'a03_e2e_customer_data_m'[is_member] = 0
                ),
                [_lp12m] > 0
            ),
            "user_id", [user_id],
            "shop_name_en", [shop_name_en]
        )

// ═══════════════════════════════════════════════════════════
// EXCEPT 详解：
//
// 功能：集合差集运算，返回在 _New 中存在但在 _Old 中不存在的行。
//
// 为什么 EXCEPT 等价于 SQL 的 LEFT JOIN + (IS NULL OR = 0)：
//
//   SQL 的保留条件：b.lp_12m_net_pay_amt IS NULL OR = 0
//   等价于排除条件：b.lp_12m_net_pay_amt > 0
//
//   ┌──────────────────────────────────────────────────────────────┐
//   │ 用户情况                      │ _Old 中是否存在 │ 是否保留  │
//   ├──────────────────────────────────────────────────────────────┤
//   │ 开始月份无记录（IS NULL）     │ ❌ 不存在       │ ✅ 保留   │
//   │ 开始月份有记录，lp12m = 0     │ ❌ 不存在       │ ✅ 保留   │
//   │ 开始月份有记录，lp12m > 0     │ ✅ 存在         │ ❌ 排除   │
//   └──────────────────────────────────────────────────────────────┘
//
//   EXCEPT(_New, _Old) = _New 全集 - _Old 中的用户
//   恰好保留了上述前两种情况。
//
// 等价SQL：
//   SELECT a.user_id, a.shop_name_en
//   FROM _New a
//   LEFT JOIN _Old b 
//     ON a.user_id = b.user_id AND a.shop_name_en = b.shop_name_en
//   WHERE b.user_id IS NULL
//
// 相比 NATURALLEFTOUTERJOIN 的优势：
//   - 少构建一个中间表（无需 _Joined），内存占用更低
//   - 无需 ISBLANK() 判断，逻辑更简洁
//   - 引擎对 EXCEPT 有专门优化，大数据量下更快
// ═══════════════════════════════════════════════════════════
    RETURN
        COUNTROWS(
        EXCEPT (
        SUMMARIZE ( _New, [user_id] ), -- 去重到用户级
        SUMMARIZE ( _Old, [user_id] )
    ))
