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
3、DCom 新客判定 = Step1 + Step2 交集：Slicer_Time_Frame_Min 和 Slicer_Time_Frame_Max 是两个独立切片器（用户分别选起始时间段和结束时间段）,slicer所选时间区间（data_date ∈ [Slicer_Time_Frame_Min[TimeFrame_Min], Slicer_Time_Frame_Max[TimeFrame_Max]]）内首次发生付费且非会员（net_pay_amt > 0，is_member = 0），且该用户的历史start_period（data_date ∈ [Slicer_Time_Frame_Min[First_Fiscal_Month_Min], Slicer_Time_Frame_Min[First_Fiscal_Month_Max]]）完全落在所选时间区间内，并在该首财月内无 12 个月累计消费记录（lp_12m_net_pay_amt = 0）,我理解start_period 是 slicer 区间的子集，技术实现上可以“合并区间”，用于判断 lp_12m_net_pay_amt = 0 的行，一定也在 slicer 区间内。
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


# Performance Indicator第三轮提示词：
1、参考文件：
Customer_Type维度表路径，断开连接，无关系连接，仅通过 SELECTEDVALUE 读取：D:\gutao\辜涛\Project\Qoder_AI_Frontend_and_backend_Web\RL E2E\RL E2E Customer Dashboard\维度复用\Slicer_Customer_Type_Selection
列指标维度表：D:\gutao\辜涛\Project\Qoder_AI_Frontend_and_backend_Web\RL E2E\RL E2E Customer Dashboard\Customer\Customer KPIs\Dim_ColMetric_Customer_KPIs.md
矩阵解决方案文件：D:\gutao\辜涛\Project\Qoder_AI_Frontend_and_backend_Web\RL E2E\RL E2E Customer Dashboard\Customer\Customer KPIs\Customer_KPIs_ms.md
Slicer_Currency_Selection：D:\gutao\辜涛\Project\Qoder_AI_Frontend_and_backend_Web\RL E2E\RL E2E Customer Dashboard\维度复用\Slicer_Currency_Selection
New Existing All口径详情说明，其他类似指标可借鉴：D:\gutao\辜涛\Project\Qoder_AI_Frontend_and_backend_Web\RL E2E\RL E2E Customer Dashboard\口径文档\Customer\New Existing All口径.md
Performance Indicator模块口径文档：D:\gutao\辜涛\Project\Qoder_AI_Frontend_and_backend_Web\RL E2E\RL E2E Customer Dashboard\口径文档\Customer\Performance Indicator.md

2、D:\gutao\辜涛\Project\Qoder_AI_Frontend_and_backend_Web\RL E2E\RL E2E Customer Dashboard\Customer\Performance Indicator目录下新增文件Dim_RowMetric_Customer_Net_Demand.md，Dim_RowMetric_Customer_Net_Demand维度表，包括Net和Demand两部分，对应口径中Net / Demand 维度区分，Net和Demand指标个数、逻辑都一致，区别仅在于字段，比如：Net部分字段为net_pay_amt、net_pay_qty、net_pay_order_cnt，Demand部分字段为pay_amt、pay_qty、pay_order_cnt。通过 SELECTEDVALUE 读取，实现我选择Net就使用Net的逻辑，选择Demand就使用Demand的逻辑。

3、参考列指标维度表Dim_ColMetric_Customer_KPIs，在D:\gutao\辜涛\Project\Qoder_AI_Frontend_and_backend_Web\RL E2E\RL E2E Customer Dashboard\Customer\Performance Indicator目录下生成新的列指标维度表Dim_ColMetric_Customer_Performance_Indicator.md，包括DCom SLS、Customer No.、ACV、AUR、Freq.、UPT六个大的分组，每个分组下有三个指标，一个本身实际值、一个vs LY、一个vs LP，输出文件Dim_ColMetric_Customer_KPIs_Performance.md在D:\gutao\辜涛\Project\Qoder_AI_Frontend_and_backend_Web\RL E2E\RL E2E Customer Dashboard\Customer\Performance Indicator目录下。此外，需要新增一个判断金额类的字段，"Metric_IsCurrencyAmount",BOOLEAN,    // 是否金额类（TRUE 才涉及汇率换算与币种符号拼接）。数据格式、类型以口径文档的为准。

4、Slicer_Time_Frame_Min 和 Slicer_Time_Frame_Max 是两个独立切片器（用户分别选起始时间段和结束时间段）
实际值时间口径 ：按所选时间范围 区间聚合 （ data_date ∈ [Slicer_Time_Frame_Min[TimeFrame_Min], Slicer_Time_Frame_Max[TimeFrame_Max]] ）
start_period（data_date ∈ [Slicer_Time_Frame_Min[First_Fiscal_Month_Min], Slicer_Time_Frame_Min[First_Fiscal_Month_Max]]）
start_period（第一个财月）是 slicer 区间的子集；

综合上述信息，在D:\gutao\辜涛\Project\Qoder_AI_Frontend_and_backend_Web\RL E2E\RL E2E Customer Dashboard\Customer\Performance Indicator目录下，输出Prformance Indicator模块矩阵解决方案文件，命名为Customer_KPIs_Performance_ms.md；其中通过Dim_RowMetric_Customer_Net_Demand维度表实现Net / Demand 逻辑区分。通过Slicer_Customer_Type_Selection区别New、Existing、All逻辑，Slicer_Customer_Type_Selection中Customer_Type_ID只有New和Existing，这里需要判断一下，如果不选或者多选、全选，就是ALL的逻辑，单选New或者单选Existing对应New和Existing的逻辑。你看如何设计更优，给出解决方案。口径文档中有关New、Existing、All逻辑不清楚的可以参考D:\gutao\辜涛\Project\Qoder_AI_Frontend_and_backend_Web\RL E2E\RL E2E Customer Dashboard\口径文档\Customer\New Existing All口径.md文件，这是关于用户数和净销售额的详细定义，其余ACV\AUR等指标都是类似逻辑处理。

# Customer Breakdown ms第四轮提示词：
1、根据D:\gutao\辜涛\Project\Qoder_AI_Frontend_and_backend_Web\RL E2E\RL E2E Customer Dashboard\Customer\Performance Indicator\Customer_KPIs_Performance_ms.md解决方案，把其中All 分支的逻辑单独提取出来，也就是本方案不受到`Slicer_Customer_Type_Selection`的影响，逻辑始终为`FALSE` → 不选 / 多选（同时选 New+Existing）/ 全选，统一走 All 分支的情况。
2、基于1的情况，Net / Demand 字段映射这部分需要保留。
3、根据D:\gutao\辜涛\Project\Qoder_AI_Frontend_and_backend_Web\RL E2E\RL E2E Customer Dashboard\Customer\Performance Indicator\Dim_ColMetric_Customer_KPIs_Performance.md，重新输出一份新的列指标维度表Dim_ColMetric_Customer_Breakdown.md，金额类的数据类型改为这个，currency_M_K_Int_0db，详细信息如下:
值 < 1,000        → 货币符号 + 千分位整数：¥999;
1,000 ≤ 值 < 1M   → 货币符号 + K 单位（1位小数）：¥1.5K;
值 ≥ 1,000,000    → 货币符号 + M 单位（1位小数）：¥1.5M;
IF(
                __Value < 1000,
                __CurrencySymbol & FORMAT(__Value, "#,##0"),
                IF(
                    __Value < 1000000,
                    __CurrencySymbol & FORMAT(__Value / 1000, "#,##0.0") & "K",
                    __CurrencySymbol & FORMAT(__Value / 1000000, "#,##0.0") & "M"
                )
            ), // ¥999\¥1.5K\¥1.5M;
其余指标不变，此外，ColType中的Act改为对应的分组名称，比如：DCom SLS、Customer No.、ACV、AUR、Freq.、UPT。
总结：综合上述信息，在D:\gutao\辜涛\Project\Qoder_AI_Frontend_and_backend_Web\RL E2E\RL E2E Customer Dashboard\Customer\Customer Breakdown目录下输出列指标维度表Dim_ColMetric_Customer_Breakdown.md和矩阵解决方案文件Customer_Breakdown_ms.md。区别在于列指标维度表的调整，以及度量只受到net/demand按钮影响，相关维度表可复用，不受到New/Existing的影响了，相当于就是算的Customer Type = ALL的情况；矩阵行维度直接拉取事实表字段实现自动传递，模型自动传递筛选，DAX 无需显式处理，不懂就问。

# Customer Breakdown Trend第五轮提示词：3+6+3+6
全局影响：
本方案不受到`Slicer_Customer_Type_Selection`的影响，直接得出单个Customer_Type的度量，受到net/demand按钮影响，相关维度表可复用。
Slicer_Time_Frame、Slicer_Time_Frame_Min、Slicer_Time_Frame_Max三个日期表，分别改为Slicer_Time_Frame_Customer_Breakdown、Slicer_Time_Frame_Min_Customer_Breakdown、Slicer_Time_Frame_Max_Customer_Breakdown，结构完全一模一样，只是为了避免日期和其他模块相互影响，所有本次方案使用新的日期表。
根据矩阵解决方案D:\gutao\辜涛\Project\Qoder_AI_Frontend_and_backend_Web\RL E2E\RL E2E Customer Dashboard\Customer\Performance Indicator\Customer_KPIs_Performance_ms.md中的逻辑，以及口径文档D:\gutao\辜涛\Project\Qoder_AI_Frontend_and_backend_Web\RL E2E\RL E2E Customer Dashboard\口径文档\Customer\Customer Breakdown Trend.md中的数据格式、数据类型、附属指标格式、类型，输出以下指标的解决方案：
1、SLS Breakdown、SLS Breakdown vs LY、SLS Breakdown vs LP 对应DCom SLS — 销售额  All 分支的情况；
2、New Customer SLS、New Customer SLS vs LY、New Customer SLS vs LP 对应DCom SLS — 新客销售额  New 分支的情况；Existing Customer SLS 对应DCom SLS — 老客销售额  Existing 分支的情况，老客不用计算vs LY和vs LP；New Customer SLS Share — 新客销售额占比：分子原指标，分母 ：New 分支 + Existing 分支；Existing Customer SLS Share — 老客销售额占比：分子原指标，分母 ：New 分支 + Existing 分支；
3、Customer No. Breakdown、Customer No. Breakdown vs LY、Customer No. Breakdown vs LP 对应Customer No. — 买家人数  All 分支的情况；
4、New Customer No.、New Customer No. vs LY、New Customer No. vs LP 对应Customer No. — 买家人数  New 分支的情况；Existing Customer No. 对应Customer No. — 买家人数  Existing 分支的情况，老客不用计算vs LY和vs LP；New Customer No. Share — 新客人数占比：分子原指标，分母 ：New 分支 + Existing 分支；Existing Customer No. Share — 老客人数占比：分子原指标，分母 ：New 分支 + Existing 分支；
综合上述信息，独立输出每个指标的Value和Display度量，共18个指标，本次指标用于条形图和表格，不是矩阵，可以直接拉取度量值，没用任何x轴，不需要处理x轴上的当前时间，不要访问其他没有提到过的文件，参考文件中提到过的依赖文件除外。在D:\gutao\辜涛\Project\Qoder_AI_Frontend_and_backend_Web\RL E2E\RL E2E Customer Dashboard\Customer\Customer Breakdown Trend目录下输出，命名为Customer Breakdown Trend.md，不懂就问。
记得读取 Currency_ExchangeRate 做汇率换算。