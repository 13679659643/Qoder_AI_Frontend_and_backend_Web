第一轮提示词：
参考RL E2E\RL E2E Traffic_Dashboard\KPI Progress\KPI_Trend\KPI_Trend_solution.md文档，
给出口径文档RL E2E\RL E2E Traffic_Dashboard\口径文档\New Acquisition实际使用版本.md中的子模块三：Controllable Ads Format Cost% Trend的解决方案，即2-5，共4个指标；
每个口径还是输出Value和Display度量，我用于柱状图和趋势图；输出在RL E2E\RL E2E Traffic_Dashboard\New Acquisition\Controllable Trend目录下。
不懂就问。

第二轮提示：
叫你参考RL E2E\RL E2E Traffic_Dashboard\KPI Progress\KPI_Trend\KPI_Trend_solution.md文档，
谁用了Slicer_Time_Frame_Min/Max这个全局筛选器？睁大你的狗眼看清楚是 KPI_Trend_solution.md 165-170 Slicer_Month_Period_Min、
Slicer_Month_Period_Max、
Slicer_Month_Period；
我要做的是矩阵不是卡片图。还有汇率是从人民币转美元，是除法。

第三轮提示：
参考RL E2E\RL E2E Traffic_Dashboard\KPI Progress\KPI_Trend\KPI_Trend_solution.md文档，
给出口径文档RL E2E\RL E2E Traffic_Dashboard\口径文档\New Acquisition实际使用版本.md中的子模块二：Ads Format Cost%、子模块四：Controllable Ads format breakdown: 引力魔方、子模块五：Controllable Ads format breakdown: 直通车的解决方案，即第1个指标，以及6-13，共9个指标；
每个口径还是输出Value和Display度量，但是区别与上述Controllable_Trend_solution.md1-4的指标，现在我是用于卡片图，所以没有x轴，日期使用
Slicer_Time_Frame_Min、Slicer_Time_Frame_Max (断开维度，SELECTEDVALUE)，全局的日期筛选，可以参考：
    // ── 时间筛选：本期 ──
    VAR __TimeMin = SELECTEDVALUE(Slicer_Time_Frame_Min[TimeFrame_Min])
    VAR __TimeMax = SELECTEDVALUE(Slicer_Time_Frame_Max[TimeFrame_Max])
    // ── 汇率（金额类指标需要除以汇率）──
    VAR __FXRate = SELECTEDVALUE(Slicer_Currency_Selection[Currency_ExchangeRate], 1)
输出在RL E2E\RL E2E Traffic_Dashboard\New Acquisition\KPIs Measure目录下。
不懂就问。汇率是从人民币转美元，是除法。

第四轮提示：
在这个文件RL E2E\RL E2E Traffic_Dashboard\New Acquisition\Controllable Trend\Controllable_Trend_solution.md中新增一个2.6 Cost amt Un controllable% Value，基于Cost amt Value的计算方式不变，使用这个值作为分子；
分母为移除了Un_Controllable_Group维度的值，包括了筛选器筛选Un_Controllable_Group这个字段的维度。

第五轮提示：
针对RL E2E\RL E2E Traffic_Dashboard\New Acquisition\KPIs Measure\KPIs_Measure_solution.md文件，给出2.2~2.9，针对总计行total的一个mysql测试案例，即对比powerbi页面和数据库的值是否一致。
​powerbi页面筛选有：
platform in ( 'TM')
AND stroe_name in ( 'TM')
AND trans_cycle = 'T+1'
AND data_date BETWEEN '2026-01-01' AND '2026-07-20'
AND currency = 'RMB'
输出sql测试案例在RL E2E\RL E2E Traffic_Dashboard\New Acquisition\KPIs Measure目录下。