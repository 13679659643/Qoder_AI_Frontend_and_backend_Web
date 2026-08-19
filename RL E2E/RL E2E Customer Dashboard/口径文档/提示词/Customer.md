# Customer第一轮提示词:
取数逻辑：D:\gutao\辜涛\Project\Qoder_AI_Frontend_and_backend_Web\RL E2E\RL E2E Customer Dashboard\参考文件\Customer 取数逻辑for PBI.xlsx
只关注sheet页为PBI取数逻辑，其他sheet页为其他取数逻辑，不关注。
参考模板文件：D:\gutao\辜涛\Project\Qoder_AI_Frontend_and_backend_Web\RL E2E\RL E2E Customer Dashboard\口径文档\VIC\VIC Breakdown KPI.md
四个达成率口径详情：D:\gutao\辜涛\Project\Qoder_AI_Frontend_and_backend_Web\RL E2E\RL E2E Customer Dashboard\口径文档\Customer\Customer_TAR_ACH_Calculation_Spec.md，包括：、Customer Monthly TAR ACH% — 月度目标达成率、Customer Yearly TAR ACH% — 年度目标达成率、Customer% Monthly TAR ACH% — 月度目标达成率、Customer% Yearly TAR ACH% — 年度目标达成率
综合以上信息，在D:\gutao\辜涛\Project\Qoder_AI_Frontend_and_backend_Web\RL E2E\RL E2E Customer Dashboard\口径文档目录下，输出全部口径的文档Customer.md，日期字段是data_date，不是dt，不懂就问。

# Customer_KPIs第二轮提示词：
1、四个达成率口径：D:\gutao\辜涛\Project\Qoder_AI_Frontend_and_backend_Web\RL E2E\RL E2E Customer Dashboard\口径文档\Customer\Customer_TAR_ACH_Calculation_Spec.md，包括：、Customer Monthly TAR ACH% — 月度目标达成率、Customer Yearly TAR ACH% — 年度目标达成率、Customer% Monthly TAR ACH% — 月度目标达成率、Customer% Yearly TAR ACH% — 年度目标达成率
2、矩阵解决方案参考文件，其中有目标值的标准逻辑写法：D:\gutao\辜涛\Project\Qoder_AI_Frontend_and_backend_Web\RL E2E\RL E2E Customer Dashboard\VIC\1 VIC KPI\VIC_KPIs_Table.md
3、口径文档：D:\gutao\辜涛\Project\Qoder_AI_Frontend_and_backend_Web\RL E2E\RL E2E Customer Dashboard\口径文档\Customer\Customer KPI.md
4、列指标文件参考：D:\gutao\辜涛\Project\Qoder_AI_Frontend_and_backend_Web\RL E2E\RL E2E Customer Dashboard\VIC\1 VIC KPI\Dim_ColMetric_VIC_KPIs.md
5、Cell Display参考模板，方便拓展版本：D:\gutao\辜涛\Project\Qoder_AI_Frontend_and_backend_Web\RL E2E\RL E2E Customer Dashboard\口径文档\Customer\Cell Display模板文件.md
6、判断是否是选择单个财月/年，我理解，可以直接判断Slicer_Time_Frame[TimeFrame_ID]是否等于"Month"或者"Year"、并且Slicer_Time_Frame_Min[TimeFrame_Value]和Slicer_Time_Frame_Max[TimeFrame_Value]是否相等,我这里使用了两个切片器来实现日期区间的效果，所以可以直接判断是否相等，如果相等，说明是选择了单个财月/年，比如Slicer_Time_Frame_Min[TimeFrame_Value]="2027-04"，Slicer_Time_Frame_Max[TimeFrame_Value]="2027-04"，说明是选择了2027年4月。
7、Slicer_Time_Frame[TimeFrame_ID]等于"Month"或者"Quarter"，存在个别目标的逻辑需要判断是否跨财年，我理解，可以直接判断Slicer_Time_Frame_Min[TimeFrame_Value]和Slicer_Time_Frame_Max[TimeFrame_Value]的年部分，比如Slicer_Time_Frame_Min[TimeFrame_Value]="2027-04"，年部分为2027，Slicer_Time_Frame_Max[TimeFrame_Value]="2028-03"，年部分为2028，说明是跨财年。
先参考列指标文件，输出当前指标的列指标KPIs表，包括Customer No.和Customer%两个大的分组，每个分组下有五个指标，输出文件Dim_ColMetric_Customer_KPIs.md在D:\gutao\辜涛\Project\Qoder_AI_Frontend_and_backend_Web\RL E2E\RL E2E Customer Dashboard\Customer\Customer KPIs目录下。
综合上述信息，输出新的解决方案在D:\gutao\辜涛\Project\Qoder_AI_Frontend_and_backend_Web\RL E2E\RL E2E Customer Dashboard\Customer\Customer KPIs目录下，命名为Customer_KPIs_ms.md，行维度直接拉取事实表字段实现自动传递，模型自动传递筛选，DAX 无需显式处理，不懂就问。

# Customer_KPIs第三轮提示词：
1、Slicer_Time_Frame_Min.sql 已扩展 First_Fiscal_Month 系列字段。
2、a03_e2e_customer_data_m_数据字典新增：data_date、shop_name_en、lp_12m_pay_amt、lp_12m_pay_order_cnt、lp_12m_pay_qty、lp_12m_net_pay_amt、lp_12m_net_pay_order_cnt、lp_12m_net_pay_qty等字段。严格按照口径文档中的内容使用lp_12m_net_pay_amt字段。
3、DCom 新客判定 = Step1 + Step2 交集：Slicer_Time_Frame_Min 和 Slicer_Time_Frame_Max 是两个独立切片器（用户分别选起始时间段和结束时间段）,slicer所选时间区间（data_date ∈ [Slicer_Time_Frame_Min[TimeFrame_Min], Slicer_Time_Frame_Max[TimeFrame_Max]]）内首次发生付费且非会员（net_pay_amt > 0，is_member = 0），且该用户的历史start_period（data_date ∈ Slicer_Time_Frame_Min[First_Fiscal_Month_Min], Slicer_Time_Frame_Min[First_Fiscal_Month_Max]）完全落在所选时间区间内，并在该首财月内无 12 个月累计消费记录（lp_12m_net_pay_amt = 0）,我理解start_period 是 slicer 区间的子集，技术实现上可以“合并区间”，用于判断 lp_12m_net_pay_amt = 0 的行，一定也在 slicer 区间内。
总结:技术上实现直接等价于 = data_date ∈ start_period and net_pay_amt > 0 and is_member = 0 and lp_12m_net_pay_amt = 0
4、解决方式是独立的，给你的参考文件是帮助你写方案，不要把相关依赖说明写入方案文件中，比如：
本方案无 IsMemberFilter / Slicer_Is_Employee_Selection（Customer KPI 口径固定 `is_member = 0`，无 `is_employee` 筛选）
不是 VIC 方案的 end period 当月（`Last_Fiscal_Month_Min/Max`）
等等这种冗余的文本，和本方案无关。
5、各 TAR ACH% 触发条件判定有调整，具体以现在最新的口径文档中的为准，只调整了四个TAR ACH%指标。
口径文档：D:\gutao\辜涛\Project\Qoder_AI_Frontend_and_backend_Web\RL E2E\RL E2E Customer Dashboard\口径文档\Customer\Customer KPI.md
- Metric_ID=4: Customer Monthly TAR ACH% → SUM(new_customer_cnt)
- Metric_ID=5: Customer Yearly TAR ACH% → SUM(DISTINCT year_new_customer_cnt)
- Metric_ID=9: Customer% Monthly TAR ACH% → SUM(new_customer_percent)
- Metric_ID=10: Customer% Yearly TAR ACH% → SUM(DISTINCT year_new_customer_percent)


# 第三轮提示词：
"Metric_IsCurrencyAmount",BOOLEAN,    // 是否金额类（TRUE 才涉及汇率换算与币种符号拼接）
Slicer_Time_Frame_Min 和 Slicer_Time_Frame_Max 是两个独立切片器（用户分别选起始时间段和结束时间段）
实际值时间口径 ：按所选时间范围 区间聚合 （ data_date ∈ [Slicer_Time_Frame_Min[TimeFrame_Min], Slicer_Time_Frame_Max[TimeFrame_Max]] ）
新客判定 ：Step 1 + Step 2 交集。
- Step 1：在所选时间范围（区间）内 net_pay_amt > 0 AND is_member = 0 的 user_id 。
- Step 2：在 start_period（即 data_date ∈ [First_Fiscal_Month_Min, First_Fiscal_Month_Max] ）内 lp_12m_net_pay_amt = 0 的 user_id 。
- 这里你修正了 start_period 定义 = 第一个财月（不是最后一个），使用 Slicer_Time_Frame_Min 的 First_Fiscal_Month_Min/Max 系列字段