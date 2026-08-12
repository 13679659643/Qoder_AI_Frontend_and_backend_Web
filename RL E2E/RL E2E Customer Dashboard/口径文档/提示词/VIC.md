# 第一轮提示词：

1、涉及到的维度表：
IsMemberFilter：D:\gutao\辜涛\Project\Qoder_AI_Frontend_and_backend_Web\RL E2E\RL E2E Customer Dashboard\维度复用\IsMemberFilter
Slicer_Is_Employee_Selection：D:\gutao\辜涛\Project\Qoder_AI_Frontend_and_backend_Web\RL E2E\RL E2E Customer Dashboard\维度复用\Slicer_Is_Employee_Selection
Slicer_Currency_Selection：D:\gutao\辜涛\Project\Qoder_AI_Frontend_and_backend_Web\RL E2E\RL E2E Customer Dashboard\维度复用\Slicer_Currency_Selection
Slicer_Time_Frame_Max：D:\gutao\辜涛\Project\Qoder_AI_Frontend_and_backend_Web\RL E2E\RL E2E Customer Dashboard\维度复用\Slicer_Time_Frame_Max
Slicer_Time_Frame_Min：D:\gutao\辜涛\Project\Qoder_AI_Frontend_and_backend_Web\RL E2E\RL E2E Customer Dashboard\维度复用\Slicer_Time_Frame_Min.sql
Slicer_Platform_Selection：D:\gutao\辜涛\Project\Qoder_AI_Frontend_and_backend_Web\RL E2E\RL E2E Customer Dashboard\维度复用\Slicer_Platform_Selection
Slicer_Platform_Selection：D:\gutao\辜涛\Project\Qoder_AI_Frontend_and_backend_Web\RL E2E\RL E2E Customer Dashboard\维度复用\Slicer_Platform_Selection
解决方案参考文件：D:\gutao\辜涛\Project\Qoder_AI_Frontend_and_backend_Web\RL E2E\RL E2E BOSS Dashboard\Performance by Merchandise\PB_Merchandise_Fulfillment_detail_ms.md
口径文档：D:\gutao\辜涛\Project\Qoder_AI_Frontend_and_backend_Web\RL E2E\RL E2E Customer Dashboard\口径文档\VIC KPI.md
列指标维度表：D:\gutao\辜涛\Project\Qoder_AI_Frontend_and_backend_Web\RL E2E\RL E2E BOSS Dashboard\Performance by Merchandise\Dim_ColMetric_Fulfillment_PB_Merchandise.md
2、口径文档中的业务定义不要过渡关注，具体逻辑还是以计算公式、数据底表、筛选条件、聚合粒度等为准。
3、无特殊说明，口径文档中的`is_upgrade_vic`字段名，和事实表中的字段名称一致,比如：a03_e2e_customer_data_m[is_upgrade_vic]。
4、无特殊说明，指标都要判断`is_member`和`is_employee`筛选。
5、在D:\gutao\辜涛\Project\Qoder_AI_Frontend_and_backend_Web\RL E2E\RL E2E Customer Dashboard\VIC\VIC KPI目录下，输出列指标维度表，命名为Dim_ColMetric_VIC_KPIs.md,这里需要调整一下，只需要一个Metric_Format字段就行了，因为每个指标对应一个格式，行格式（严格遵循口径文档数据类型定义）
6、Cell Display：格式化显示度量，不仅要包括已有的数据格式，还需要拓展一些格式，比如百分比整数等，便于后续快速调整。
7、Cell Font Color：字体颜色度量，VIC No.、VIC Retention%、T4-5 Upgrade No.这三个指标为#252423，涉及到vs LY、vs LP、占比的指标、达成率的指标使用列维度表的颜色取值取值字段，其余指标为列指标维度中的Metric_ColorDefault默认颜色。
8、Slicer_Time_Frame_Max日期维度表中已新增Last_Fiscal_Month字段(月/季/年的最后一个月即`end period`)以及Last_Fiscal_Month_Min、Last_Fiscal_Month_Max、Last_Fiscal_Month_Min_LY、Last_Fiscal_Month_Max_LY、Last_Fiscal_Month_Min_LP、Last_Fiscal_Month_Max_LP其余六个字段，可以直接获取，用于筛选事实表的时间范围。我理解`end period`只需要关注Slicer_Time_Frame_Max日期维度表就行了。
9、分组维度直接拉取事实表字段实现自动传递，模型自动传递筛选，DAX 无需显式处理，不动就问。输出新的解决方案在D:\gutao\辜涛\Project\Qoder_AI_Frontend_and_backend_Web\RL E2E\RL E2E Customer Dashboard\VIC\VIC KPI目录下，命名为VIC_KPIs_Table.md

# 第二轮提示词:

口径文档：D:\gutao\辜涛\Project\Qoder_AI_Frontend_and_backend_Web\RL E2E\RL E2E Customer Dashboard\口径文档\Member.md
参考文件：D:\gutao\辜涛\Project\Qoder_AI_Frontend_and_backend_Web\RL E2E\RL E2E BOSS Dashboard\Performance by Merchandise\PB_Merchandise_Trend.md
独立输出每个指标的Value和Display度量，本次指标用于卡片图，没用任何x轴的维度，不懂就问，不要访问其他没有提到过的文件，参考文件中提到过的依赖文件除外。
分组维度直接拉取事实表字段实现自动传递，模型自动传递筛选，DAX 无需显式处理。
需要注意的是，口径中的一些指标存在两种数据格式，需要输出为两个不同的Display度量，例如：DCom New Member Recruitment vs LY（Net/Demand）percent_1dp和DCom New Member Recruitment vs LY（Net/Demand）delta_pct_1dp。
输出新的解决方案在D:\gutao\辜涛\Project\Qoder_AI_Frontend_and_backend_Web\RL E2E\RL E2E Customer Dashboard\Member目录下，命名为Customer_Member_Indicator.md

# 第三轮提示词：

# 第四轮提示：

# 第五轮提示：

# 第六轮提示:

# 第七轮提示：

# 第八轮提示：
