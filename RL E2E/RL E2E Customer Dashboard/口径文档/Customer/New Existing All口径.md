# 1、用户数口径（New / Existing / All）

## 时间定义

| 时间区间               | 定义                                                                                                                           |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------------ |
| **slicer 区间**  | `data_date ∈ [TimeFrame_Min, TimeFrame_Max]`                                                                                |
| **start_period** | `data_date ∈ [First_Fiscal_Month_Min, First_Fiscal_Month_Max]`（由 `Slicer_Time_Frame_Min` 派生，且为 slicer 区间的子集） |

---

## New（新客人数）

在 **start_period** 内同时满足：

- `net_pay_amt > 0`
- `is_member = 0`
- `lp_12m_net_pay_amt = 0`

统计：

- `COUNT(DISTINCT user_id)`

---

## Existing（老客人数）

在 **start_period** 内同时满足：

- `net_pay_amt > 0`
- `is_member = 0`
- `lp_12m_net_pay_amt > 0`

统计：

- `COUNT(DISTINCT user_id)`

---

## All（非会员用户数）

在 **slicer 区间** 内：

- `COUNT(DISTINCT user_id)`
- 且仅包含 `is_member = 0` 的交易

---

## 口径校验关系

- ✅ New 与 Existing 用户互斥
- ✅ New + Existing ≤ All（All 为 slicer 区间内非会员人数，覆盖更广）
- ✅ 用户身份由 **start_period** 唯一决定
- ✅ 人数统计不依赖 slicer 区间

# 2、净销售额口径（New / Existing / All）

## 时间定义

| 时间区间               | 定义                                                                                                                           |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------------ |
| **slicer 区间**  | `data_date ∈ [TimeFrame_Min, TimeFrame_Max]`                                                                                |
| **start_period** | `data_date ∈ [First_Fiscal_Month_Min, First_Fiscal_Month_Max]`（由 `Slicer_Time_Frame_Min` 派生，且为 slicer 区间的子集） |

---

## New（新客净销售额）

### 用户判定（身份口径）

在 **start_period** 内同时满足：

- `net_pay_amt > 0`
- `is_member = 0`
- `lp_12m_net_pay_amt = 0`

### 销售额汇总口径

对上述用户，在 **slicer 区间** 内汇总：

- `SUM(net_pay_amt)`
- 且仅包含 `is_member = 0` 的交易

---

## Existing（老客净销售额）

### 用户判定（身份口径）

在 **start_period** 内同时满足：

- `net_pay_amt > 0`
- `is_member = 0`
- `lp_12m_net_pay_amt > 0`

### 销售额汇总口径

对上述用户，在 **slicer 区间** 内汇总：

- `SUM(net_pay_amt)`
- 且仅包含 `is_member = 0` 的交易

---

## All（非会员净销售额）

在 **slicer 区间** 内：

- `SUM(net_pay_amt)`
- 且仅包含 `is_member = 0` 的交易

---

## 口径校验关系

- ✅ New 与 Existing 用户互斥
- ✅ `New + Existing = All`（在 `is_member = 0` 口径下）
- ✅ 新客 / 老客身份由 **start_period** 决定
- ✅ 销售额汇总统一基于 **slicer 区间**
