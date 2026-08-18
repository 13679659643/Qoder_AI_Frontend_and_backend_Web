# 第一轮提示词：
1、四个达成率口径：D:\gutao\辜涛\Project\Qoder_AI_Frontend_and_backend_Web\RL E2E\RL E2E Customer Dashboard\口径文档\Customer\Customer_TAR_ACH_Calculation_Spec.md，包括：、Customer Monthly TAR ACH% — 月度目标达成率、Customer Yearly TAR ACH% — 年度目标达成率、Customer% Monthly TAR ACH% — 月度目标达成率、Customer% Yearly TAR ACH% — 年度目标达成率
2、矩阵解决方案参考文件，其中有目标值的标准逻辑写法：D:\gutao\辜涛\Project\Qoder_AI_Frontend_and_backend_Web\RL E2E\RL E2E Customer Dashboard\VIC\1 VIC KPI\VIC_KPIs_Table.md
3、口径文档：D:\gutao\辜涛\Project\Qoder_AI_Frontend_and_backend_Web\RL E2E\RL E2E Customer Dashboard\口径文档\Customer\Customer.md
4、列指标文件参考：D:\gutao\辜涛\Project\Qoder_AI_Frontend_and_backend_Web\RL E2E\RL E2E Customer Dashboard\VIC\1 VIC KPI\Dim_ColMetric_VIC_KPIs.md
5、Cell Display参考模板，方便拓展版本：D:\gutao\辜涛\Project\Qoder_AI_Frontend_and_backend_Web\RL E2E\RL E2E Customer Dashboard\口径文档\Customer\Cell Display模板文件.md
6、判断是否是选择单个财月/年，我理解，可以直接判断Slicer_Time_Frame[TimeFrame_ID]是否等于"Month"或者"Year"、并且Slicer_Time_Frame_Min[TimeFrame_Value]和Slicer_Time_Frame_Max[TimeFrame_Value]是否相等,我这里使用了两个切片器来实现日期区间的效果，所以可以直接判断是否相等，如果相等，说明是选择了单个财月/年，比如Slicer_Time_Frame_Min[TimeFrame_Value]="2027-04"，Slicer_Time_Frame_Max[TimeFrame_Value]="2027-04"，说明是选择了2027年4月。
7、Slicer_Time_Frame[TimeFrame_ID]等于"Month"或者"Quarter"，存在个别目标的逻辑需要判断是否跨财年，我理解，可以直接判断Slicer_Time_Frame_Min[TimeFrame_Value]和Slicer_Time_Frame_Max[TimeFrame_Value]的年部分，比如Slicer_Time_Frame_Min[TimeFrame_Value]="2027-04"，年部分为2027，Slicer_Time_Frame_Max[TimeFrame_Value]="2028-03"，年部分为2028，说明是跨财年。
先参考列指标文件，输出当前指标的列指标KPIs表，包括Customer No.和Customer%两个大的分组，每个分组下有五个指标，输出文件Dim_ColMetric_Customer_KPIs.md在D:\gutao\辜涛\Project\Qoder_AI_Frontend_and_backend_Web\RL E2E\RL E2E Customer Dashboard\Customer\1 Customer KPIs目录下。
综合上述信息，输出新的解决方案在D:\gutao\辜涛\Project\Qoder_AI_Frontend_and_backend_Web\RL E2E\RL E2E Customer Dashboard\Customer\1 Customer KPIs目录下，命名为Customer_KPIs_ms.md，行维度直接拉取事实表字段实现自动传递，模型自动传递筛选，DAX 无需显式处理，不懂就问。

# 第二轮提示词:
取数逻辑：D:\gutao\辜涛\Project\Qoder_AI_Frontend_and_backend_Web\RL E2E\RL E2E Customer Dashboard\参考文件\Customer 取数逻辑for PBI.xlsx
只关注sheet页为PBI取数逻辑，其他sheet页为其他取数逻辑，不关注。
参考模板文件：D:\gutao\辜涛\Project\Qoder_AI_Frontend_and_backend_Web\RL E2E\RL E2E Customer Dashboard\口径文档\VIC\VIC Breakdown KPI.md
四个达成率口径详情：D:\gutao\辜涛\Project\Qoder_AI_Frontend_and_backend_Web\RL E2E\RL E2E Customer Dashboard\口径文档\Customer\Customer_TAR_ACH_Calculation_Spec.md，包括：、Customer Monthly TAR ACH% — 月度目标达成率、Customer Yearly TAR ACH% — 年度目标达成率、Customer% Monthly TAR ACH% — 月度目标达成率、Customer% Yearly TAR ACH% — 年度目标达成率
综合以上信息，在D:\gutao\辜涛\Project\Qoder_AI_Frontend_and_backend_Web\RL E2E\RL E2E Customer Dashboard\口径文档目录下，输出全部口径的文档Customer.md，日期字段是data_date，不是dt，不懂就问。
# 第三轮提示词：

