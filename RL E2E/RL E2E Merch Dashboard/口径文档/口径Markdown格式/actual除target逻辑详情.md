# actual除target逻辑详情


---

## 全局逻辑

| This Period（区间类）     | data_date ∈ [Slicer_Time_Frame_Min_This[TimeFrame_Min], Slicer_Time_Frame_Max_This[TimeFrame_Max]]
| Last Period（vs LP 基线） | data_date ∈ [Slicer_Time_Frame_Min_Last[TimeFrame_Min], Slicer_Time_Frame_Max_Last[TimeFrame_Max]]
| End Period（期末时点类）  | end period 范围 [Slicer_Time_Frame_Max_This[TimeFrame_Min], Slicer_Time_Frame_Max_This[TimeFrame_Max]] 内**最后一个快照日**
This Period区间包括Slicer_Time_Frame_Min_This、Slicer_Time_Frame_Max_This，其中Slicer_Time_Frame_Min_This有TimeFrame_Min 所在月/年的 timeframe_value，即TimeFrame_Min_Month_Value和TimeFrame_Min_Year_Value；Slicer_Time_Frame_Max_This有TimeFrame_Max 所在月/年的 timeframe_value，即TimeFrame_Max_Month_Value、TimeFrame_Max_Year_Value用于判断This Period区间是否跨年、跨月；TimeFrame_Min_Month_Value和TimeFrame_Max_Month_Value值举例：2027-08；TimeFrame_Min_Year_Value和TimeFrame_Max_Year_Value举例：2027；这里的月年都是指财月年，文本类型。
target MTD：以时间筛选器end period所在财月第一天至所在财月最后一天，Slicer_Time_Frame_Max_This[Fiscal_Month_First_Day]~Slicer_Time_Frame_Max_This[Fiscal_Month_Last_Day]
target YTD：以时间筛选器end period所在财年第一天至所在财年最后一天，Slicer_Time_Frame_Max_This[Fiscal_Year_First_Day]~Slicer_Time_Frame_Max_This[Fiscal_Year_Last_Day]
字段：
actual：a02_e2e_product_performance_sales_summary_d[net_sales_amt]
target：a05_e2e_product_fcst_data_d[fcst_sales_amt]
说明：
- vs LP 是 this period 和 last period 对比，受 last period 时间筛选器影响
- 期末时点类实现为 end period 范围内最后一个有数据的快照日：口径为 end period 最后一天，快照缺数时自动回退到范围内最近一天；快照表按日存储只取单日，整段区间求和会重复计数库存

---

### 1.Timeframe = Day

MTD 进度跨月不计算，YTD 进度 跨年不计算。
| 不跨月（Period = 2026-03-29 ~ 2026-04-03） | 跨月（Period = 2026-03-29 ~ 2026-05-03） |  |  |说明|
|---|---|---|---|---|
| **Timeframe = day** | **Target** | **Timeframe = day** | **Target** |**说明**|
| **达成率** | 2026-03-29 ~ 2026-04-03 | **达成率** | 2026-03-29 ~ 2026-05-03 |分子分母始终和This Period区间一致|
| **MTD 进度** | FY2701<br>2026-03-29 ~ 2026-04-25 | **MTD 进度** | 不计算 |actual：This Period区间；target：MTD区间Slicer_Time_Frame_Max_This[Fiscal_Month_First_Day]~Slicer_Time_Frame_Max_This[Fiscal_Month_Last_Day]|
| **YTD 进度** | FY27<br>2026-03-29 ~ 2027-04-03 | **YTD 进度** | FY27<br>2026-03-29 ~ 2027-04-03 |actual：This Period区间；target：YTD区间Slicer_Time_Frame_Max_This[Fiscal_Year_First_Day]~Slicer_Time_Frame_Max_This[Fiscal_Year_Last_Day]|


### 2.Timeframe = Week
MTD 进度跨月不计算，YTD 进度 跨年不计算。
| 不跨月（FY27 week1 ~ week2） | 跨月（FY27 week1 ~ week7） |  |  |说明|
| **Timeframe = week** | **Target** | **Timeframe = week** | **Target** |**说明**|
| **达成率** | 分子分母始终和This Period区间一致 |
| **MTD 进度** | FY2701<br>2026-03-29 ~ 2026-04-25 | **MTD 进度** | 不计算 |actual：This Period区间；target：MTD区间Slicer_Time_Frame_Max_This[Fiscal_Month_First_Day]~Slicer_Time_Frame_Max_This[Fiscal_Month_Last_Day]|
| **YTD 进度** | FY27<br>2026-03-29 ~ 2027-04-03 | **YTD 进度** | FY27<br>2026-03-29 ~ 2027-04-03 |actual：This Period区间；target：YTD区间Slicer_Time_Frame_Max_This[Fiscal_Year_First_Day]~Slicer_Time_Frame_Max_This[Fiscal_Year_Last_Day]|

### 3.Timeframe = Month

仅YTD 进度 跨年不计算
| 不跨月（FY2701 ~ FY2701） | 跨月（FY2701 ~ FY2702） |  |  |说明|
| **Timeframe = month** | **Target** | **Timeframe = month** | **Target** |**说明**|
| **达成率** |  分子分母始终和This Period区间一致 |
| **MTD 进度** |  分子分母始终和This Period区间一致 |
| **YTD 进度** | FY27<br>2026-03-29 ~ 2027-04-03 | **YTD 进度** | FY27<br>2026-03-29 ~ 2027-04-03 |actual：This Period区间；target：YTD区间Slicer_Time_Frame_Max_This[Fiscal_Year_First_Day]~Slicer_Time_Frame_Max_This[Fiscal_Year_Last_Day]|

### 4.Timeframe = Quarter
MTD 进度 跨季度和不跨季都不计算，YTD 进度 跨年不计算
| 不跨季（FY27 Q1 ~ Q1） | 跨季（FY27 Q1 ~ Q2） |  |  |
| **Timeframe = quarter** | **Target** | **Timeframe = quarter** | **Target** |
| **达成率** |  分子分母始终和This Period区间一致 |
| **MTD 进度** | 不计算 | **MTD 进度** | 不计算 |
| **YTD 进度** | FY27<br>2026-03-29 ~ 2027-04-03 | **YTD 进度** | FY27<br>2026-03-29 ~ 2027-04-03 |actual：This Period区间；target：YTD区间Slicer_Time_Frame_Max_This[Fiscal_Year_First_Day]~Slicer_Time_Frame_Max_This[Fiscal_Year_Last_Day]|

### 4.Timeframe = Year
MTD 进度 跨季度和不跨季都不计算。YTD 进度都需要计算。
| 不跨年（FY27） | 跨年（FY27 ～ FY28） |  |  |
| **Timeframe = year** | **Target** | **Timeframe = year** | **Target** |
| **达成率** |  分子分母始终和This Period区间一致 |
| **MTD 进度** | 不计算 | **MTD 进度** | 不计算 |
| **YTD 进度** |  分子分母始终和This Period区间一致 |

**跨财年判定**：

- 所有ALL`TimeFrame_ID  时判断
- 比较 `Slicer_Time_Frame_Min_This[TimeFrame_Min_Year_Value]` 与 `Slicer_Time_Frame_Max_This[TimeFrame_Max_Year_Value]` 的所在年
- 不相等 → 跨财年

**跨财月判定**：

- 所有ALL`TimeFrame_ID  时判断
- 比较 `Slicer_Time_Frame_Min_This[TimeFrame_Min_Month_Value]` 与 `Slicer_Time_Frame_Max_This[TimeFrame_Max_Month_Value]` 的所在月
- 不相等 → 跨财月
