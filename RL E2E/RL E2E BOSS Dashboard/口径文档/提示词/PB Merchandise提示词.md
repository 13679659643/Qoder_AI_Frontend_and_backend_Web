# 第一轮提示词：
口径文档：D:\gutao\辜涛\Project\Qoder_AI_Frontend_and_backend_Web\RL E2E\RL E2E BOSS Dashboard\口径文档\PB Merchandise.md，只关注子模块一：BOSS Fulfillment - Fulfillment% by Label和子模块二：BOSS M/W POLO Unfulfilled Order by Category。
参考文件：D:\gutao\辜涛\Project\Qoder_AI_Frontend_and_backend_Web\RL E2E\RL E2E BOSS Dashboard\Performance By Location\PB_Location_Sales_detail.md
独立输出每个指标的Value和Display度量，本次指标用于条形图，没用任何x轴的维度，不懂就问，不要访问其他没有提到过的文件，参考文件中提到过的依赖文件除外。
输出新的解决方案在D:\gutao\辜涛\Project\Qoder_AI_Frontend_and_backend_Web\RL E2E\RL E2E BOSS Dashboard\Performance by Merchandise目录下，命名为PB_Merchandise_Trend.md


# 第二轮提示词:
口径文档：D:\gutao\辜涛\Project\Qoder_AI_Frontend_and_backend_Web\RL E2E\RL E2E BOSS Dashboard\口径文档\PB Merchandise.md，只关注子模块三：BOSS Performance Details的4. Avg. No. of Store Passed Before Order Got Accepted — O2O平均订单流转次数开始。
参考列指标文件：D:\gutao\辜涛\Project\Qoder_AI_Frontend_and_backend_Web\RL E2E\RL E2E BOSS Dashboard\Performance By Location\Dim_ColMetric_Fulfillment_PB_Location.md，其中需要注意的是ColType同名的列类型标识，对应ColName_Sort值一样，以参考文档为准。
输出新的解决方案在D:\gutao\辜涛\Project\Qoder_AI_Frontend_and_backend_Web\RL E2E\RL E2E BOSS Dashboard\Performance by Merchandise目录下，命名为Dim_ColMetric_Fulfillment_PB_Merchandise.md，注意分组和指标根据口径文档中的来，4和5为Order Processing Efficiency分组；Fulfillment%分组：6、6.1、6.2；Request Order：7、7.1、7.2、8、8.1、8.2、9、9.1、9.2；Shipped Order：10、10.1、10.2、11、11.1、11.2、12、12.1、12.2；Unfulfillment%：13、13.1、13.2、14、14.1、14.2；Unfulfilled Order：15、15.1、15.2、16、16.1、16.2；Product Volume：17，这个分组下就只有这一个子项。


# 第三轮提示词：
口径文档：D:\gutao\辜涛\Project\Qoder_AI_Frontend_and_backend_Web\RL E2E\RL E2E BOSS Dashboard\口径文档\PB Merchandise.md，只关注子模块三：BOSS Performance Details的4. Avg. No. of Store Passed Before Order Got Accepted — O2O平均订单流转次数开始。
列指标文件：D:\gutao\辜涛\Project\Qoder_AI_Frontend_and_backend_Web\RL E2E\RL E2E BOSS Dashboard\Performance by Merchandise\Dim_ColMetric_Fulfillment_PB_Merchandise.md，
解决方案参考文件：D:\gutao\辜涛\Project\Qoder_AI_Frontend_and_backend_Web\RL E2E\RL E2E BOSS Dashboard\Performance By Location\PB_Location_Fulfillment_detail_ms.md
输出新的解决方案在D:\gutao\辜涛\Project\Qoder_AI_Frontend_and_backend_Web\RL E2E\RL E2E BOSS Dashboard\Performance by Merchandise目录下，命名为PB_Merchandise_Fulfillment_detail_ms.md，事实表分组字段表格行/列直接拉取，模型自动传递筛选DAX 无需显式处理；
需要注意最后一个Product Volume指标：
库存：sum(stock_qty) 【看所选时间范围的期末库存】，库存需要根据筛选日期，只要最后一天的数据。
销量：sum(o2o_fulfillment_shipped_qty) 【看所有时间范围的销量总和】，销量整个筛选周期的数据聚合。
不懂就问。

# 第四轮提示：



# 第五轮提示：


# 第六轮提示:


# 第七轮提示：

# 第八轮提示：

