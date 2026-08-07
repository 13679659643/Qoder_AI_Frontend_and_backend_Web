# 第一轮提示词：
参考RL E2E\RL E2E BOSS Dashboard\口径文档\Overview.md的格式，根据文件D:\gutao\辜涛\Project\Qoder_AI_Frontend_and_backend_Web\RL E2E\RL E2E BOSS Dashboard\参考文件\取数逻辑for PBI.xlsx中的Tab为Performance By Location和Performance By Merchandise部分，分别输出这两部分的口径文档，在RL E2E\RL E2E BOSS Dashboard\口径文档目录下。execl文件中附属指标列，也需要列为子指标项，Overview.md中有类似情况，按照该文件的格式输出，记得检查计算指标是否一致，这是口径很重要很严格，不能出错，不懂就问。

# 第二轮提示词:
参考这个文件，D:\gutao\辜涛\Project\Qoder_AI_Frontend_and_backend_Web\RL E2E\RL E2E BOSS Dashboard\Overview\Sales\Overview_Sales_ms.md
根据所选timeframe聚合，如果是Month，则聚合在月粒度，展示所选时间范围每月的聚合值；如果是Year，则聚合在年粒度，展示所选时间范围每年的聚合值。
柱形图 + 趋势图，无需矩阵 SWITCH 路由分发，每个指标独立编写 Value / Display 度量，分组维度我会直接拉取数据表中的字段，无需在PBI中添加分组维度。
一切口径以指标口径文档RL E2E\RL E2E BOSS Dashboard\口径文档\PB Location.md为准，输出其中的子模块一到四的Value和Display度量。
不懂就问，输出方案文件在D:\gutao\辜涛\Project\Qoder_AI_Frontend_and_backend_Web\RL E2E\RL E2E BOSS Dashboard\Performance By Location目录下。需要必要注释，不是所有的柱形图的X轴都是TimeFrame_Value，有些是store_region，有些是store_type，需要在注释中说明。

# 第三轮提示词：
参考D:\gutao\辜涛\Project\Qoder_AI_Frontend_and_backend_Web\RL E2E\RL E2E BOSS Dashboard\Performance By Location\PB_Location_Trend.md文件结构，
把D:\gutao\辜涛\Project\Qoder_AI_Frontend_and_backend_Web\RL E2E\RL E2E BOSS Dashboard\Overview\BOSS Core KPI\Overview_KPIs_ms.md中的Sales相关五个指标单独输出Value和Display度量，按照PB_Location_Trend.md文件的格式输出。
现在我不是矩阵，我是独立输出每个指标的Value和Display度量。比如：Sales下的SLS指标，我需要输出SLS Actual Value和SLS Actual Display、SLS LY Value和SLS LY Display、SLS vs LY Value和SLS vs LY Display。其余四个同理。不懂就问，不要访问其他没有提到过的文件，参考文件中提到过的依赖文件除外。
输出新的解决方案在D:\gutao\辜涛\Project\Qoder_AI_Frontend_and_backend_Web\RL E2E\RL E2E BOSS Dashboard\Performance By Location目录下，命名为PB_Location_Sales_detail.md


# 第四轮提示：
根据上述SLS等五个指标的分组情况，把value和display度量整合，通过Switch路由分发实现，首先需要先构建新的列指标维度，根绝D:\gutao\辜涛\Project\Qoder_AI_Frontend_and_backend_Web\RL E2E\RL E2E BOSS Dashboard\Overview\BOSS Core KPI\Dim_RowKPIs_BossCoreKPI_Overview和D:\gutao\辜涛\Project\Qoder_AI_Frontend_and_backend_Web\RL E2E\RL E2E BOSS Dashboard\Overview\BOSS Core KPI\Dim_ColKPIs_BossCoreKPI_Overview构建新的列指标维度，维度名称为Dim_ColMetric_Sales_PB_Location，这里我是要用于矩阵的，但这里没有行维度，我会直接拉取数据表中的字段，天然实现行维度分组和筛选，无需在Dax中添加，列维度为SLS为分组，其下有Act、LY、vs LY三个指标部分，其余四个分组按序同理。
参考文件：D:\gutao\辜涛\Project\Qoder_AI_Frontend_and_backend_Web\RL E2E\RL E2E Traffic_Dashboard\KPI Progress\KPI by Platform\KPI by Platform_matrix_solution.md，尤其是总路由部分，需先 REMOVEFILTERS 清除断开维度的所有筛选，再应用目标 Metric_ID；
输出新的解决方案在D:\gutao\辜涛\Project\Qoder_AI_Frontend_and_backend_Web\RL E2E\RL E2E BOSS Dashboard\Performance By Location目录下，命名为PB_Location_Sales_detail_ms.md

# 第五轮提示：
逻辑文件：D:\gutao\辜涛\Project\Qoder_AI_Frontend_and_backend_Web\RL E2E\RL E2E BOSS Dashboard\口径文档\PB Location.md，从子模块五：BOSS Performance Details的6. Fulfillment% — O2O订单履约率开始。
列指标文件：D:\gutao\辜涛\Project\Qoder_AI_Frontend_and_backend_Web\RL E2E\RL E2E BOSS Dashboard\Performance By Location\Dim_ColMetric_Fulfillment_PB_Location.md，
参考文件：D:\gutao\辜涛\Project\Qoder_AI_Frontend_and_backend_Web\RL E2E\RL E2E BOSS Dashboard\Performance By Location\PB_Location_Sales_detail_ms.md
输出新的解决方案在D:\gutao\辜涛\Project\Qoder_AI_Frontend_and_backend_Web\RL E2E\RL E2E BOSS Dashboard\Performance By Location目录下，命名为PB_Location_Fulfillment_detail_ms.md，需要注意最后三个库存数量指标，根据所选时间范围的期末库存，即统计结束时间的期末库存数量，需要根据筛选日期，只要最后一天的数据。


# 第六轮提示:


# 第七轮提示：

# 第八轮提示：

