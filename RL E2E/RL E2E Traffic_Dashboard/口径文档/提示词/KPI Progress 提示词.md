
第一轮提示词:
在RL E2E\RL E2E Traffic_Dashboard\维度复用目录下，我已经完成了一些维度表的设计工作，可服用的如下，以及设计表的DAX语句、SQL语句：
1、事实表：a05_e2e_paid_media_summary_d；
2、日期筛选器，Slicer_Time_Frame_Min和Slicer_Time_Frame_Max，与事实表断开维度，用于页面上的Timeframe(Day\Week\Month\Quarter\Year),对应不同的TimeFrame_Value，需要把年月季周都转化为日，去筛选a05_e2e_paid_media_summary_d表中的data_date字段。
3、Platform筛选器，Slicer_Platform_Selection，对应四个平台。对应事实表中的a05_e2e_paid_media_summary_data_d[platform]；一对多事实表，模型会自动筛选事实表；
4、Store Name筛选器，表Slicer_Store_Name，对应a05_e2e_paid_media_summary_data_d[store_name]；一对多事实表，模型会自动筛选事实表；
5、trans_cycle筛选器，对应事实表中的a05_e2e_paid_media_summary_data_d[trans_cycle]；一对多事实表，模型会自动筛选事实表；
6、Currency筛选器，断开连接，仅金额类指标乘以汇率固定为7；
7、指标列维度，RL E2E\RL E2E Traffic_Dashboard\KPI Progress\Dim_ColMetric_KPI by Platform，Dim_ColMetric_KPI by Platform，包含15个指标，YOY%采用在末尾加不同数量的空格区分。

在RL E2E\RL E2E Traffic_Dashboard\KPI Progress目录下，输出KPI by Platform矩阵的powerbi解决方案。
1、矩阵的行是Store_Name,直接复用店铺维度表Slicer_Store_Name的Store_ID字段。
2、矩阵的列格式是：Dim_ColMetric_KPI by Platform维度表的Metric_Name字段，使用Metric_ID进行路由分发。
3、指标口径文档RL E2E\RL E2E Traffic_Dashboard\口径文档\KPI Progress.md中的子模块五：KPI by Platform部分，本次矩阵只关注子模块五的口径，一切指标都按照子模块五的口径进行计算，不懂就问。
4、可以参考RL E2E\RL E2E Traffic_Dashboard\Category Growth\KPI_Breakdown_matrix_solution解决方案、RL E2E\RL E2E Traffic_Operation\Overview\TTL汇总\KPIs Overview_matrix_solution解决方案。
5、KPI by Platform解决方案中只需要包括以下内容就行：
度量：KPI by Platform Base Value、KPI by Platform Cell Value、KPI by Platform Cell Display、KPI by Platform Cell Font Color、KPI by Platform Cell Background Color、KPI by Platform Cell SVG Icon
清单：度量值清单与 Display Folder、指标口径来源对照、血缘关系图（Lineage Diagram）
6、因为我们需要计算本期和同期的值，所以KPI by Platform Base Value可以考虑拆分为KPI by Platform Current Base Value和KPI by Platform vsLP Base Value两个子项会不会更好维护一些。vx LP 上期值根据当前时间往前推一年就行了，比如当前时间是2025-10-24到2025-10-31，那么vs LP 上期值就是2024-10-24到2024-10-31。你有更好的度量模型方案也可以提供。
7、KPI by Platform Cell Font Color区别总计行和其他行，总计行字体颜色为黑色#252423，其他行字体颜色为5F6165（深灰）。通过ISINSCOPE('Slicer_Store_Name'[store_name])进行层级判断。
8、KPI by Platform Cell Background Color区别总计行和其他行，总计行背景颜色为#E6D9C7（中米色），其他行背景颜色为白色#FFFFFF。
9、KPI by Platform Cell SVG Icon只关注YOY%指标，其他指标不关注SVG Icon。SVG Icon就使用KPI Breakdown Cell SVG Icon中的图标。
10、一切口径以指标口径文档RL E2E\RL E2E Traffic_Dashboard\口径文档\KPI Progress.md中的子模块五：KPI by Platform部分为准，不懂就问。


第二轮提示：
sql测试参数本期时间为：2026-01-01~2026-07-14；则上期时间为2025-01-01~2025-07-14；
shop_name的所有分组，包括所有店铺的group by;trans_cycle:T+1;
pbi指标：15个指标，三个为一组单验证本期、同期、YOY%。共计五组SQL验证语句，以及一组Total行的验证语句。
给出完整SQL语句，mysql语法。
输出在RL E2E\RL E2E Traffic_Dashboard\KPI Progress目录下。

第三轮提示：
