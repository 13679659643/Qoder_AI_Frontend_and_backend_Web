
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
参考这个文件：RL E2E\RL E2E Traffic_Dashboard\KPI Progress\KPI by Platform\Dim_ColMetric_KPI by Platform；
根据口径文档中的子模块一和子模块二，即1~24个指标，生成Dim_ColMetric_KPIs，指标维度文件，
输出在RL E2E\RL E2E Traffic_Dashboard\KPI Progress\KPIS目录下，严格遵守指标文档的数据格式和数据类型，以及指标命名，比如：1. Media Cost Rate — 媒体花费占比，Metric_Name就是： Media Cost Rate；
不懂就问。

第四轮提示:
背景：正在开发PowerBI看板，KPI by Platform是整个看板的一个子模块，对应的解决方案文件我已经写好了，参考：RL E2E\RL E2E Traffic_Dashboard\KPI Progress\KPI by Platform\KPI by Platform_matrix_solution.md;接下来我要开发其他模块。
KPI 计算框架解决方案 — 多指标 SWITCH 分发模式需求：
1、24个指标的数据格式、类型、颜色、是否金额类指标（需要汇率转换）参考RL E2E\RL E2E Traffic_Dashboard\KPI Progress\KPIS\Dim_ColMetric_KPIs文件：展示使用Dim_ColMetric_KPIs维度表的Metric_Name字段，使用Metric_ID进行路由分发。
2、指标口径文档RL E2E\RL E2E Traffic_Dashboard\口径文档\KPI Progress.md的子模块一：KPIs和子模块二：Performance Indicators部分，即1-24个指标，一切以口径文档为准，不懂就问。
3、参考：RL E2E\RL E2E Traffic_Dashboard\KPI Progress\KPI by Platform\KPI by Platform_matrix_solution.md解决方案，只需要包括以下内容就行：
度量：KPI by Platform Base Value、KPI by Platform Cell Value、KPI by Platform Cell Display、KPI by Platform Cell Font Color、KPI by Platform Cell Background Color、KPI by Platform Cell SVG Icon
清单：度量值清单与 Display Folder、指标口径来源对照、血缘关系图（Lineage Diagram）
4、计算vs LY（对比去年同期）的时候，会用到上期值vs LP， 上期值根据当前时间往前推一年就行了，比如当前时间是2025-10-24到2025-10-31，那么vs LP 上期值就是2024-10-24到2024-10-31。
5、KPI by Platform Cell Font Color，只配置Cost vs SLS ACH%、SLS DCom、以及所有vs LY指标的颜色，其余指标颜色为#252423；在 Dim_Metric_KPIs 中有独立的 4 色配置，启用正/负/零三色，颜色值在维度表中维护，无需修改度量值即可调整配色；可以参考这个文件：RL E2E\RL E2E Traffic_Dashboard\KPI Progress\参考指标\Font Color；
6、一切口径以指标口径文档RL E2E\RL E2E Traffic_Dashboard\口径文档\KPI Progress.md中的的子模块一：KPIs和子模块二为准，不懂就问。
7、由于是一个看板的不同模块，所以筛选器是公用的，具体用法和RL E2E\RL E2E Traffic_Dashboard\Category Growth\KPI_Breakdown_matrix_solution解决方案中的筛选器用法一致。比如：Currency筛选器，断开连接，仅金额类指标乘以汇率固定为7；
在RL E2E\RL E2E Traffic_Dashboard\KPI Progress\KPIS目录下输出解决方案。

第五轮提示：
KPI Trend计算框架解决方案 — 多指标 需求：
1、指标口径文档RL E2E\RL E2E Traffic_Dashboard\口径文档\KPI Progress.md的子模块三：New Acquisition KPI Trend和子模块四：Category Growth KPI Trend部分，即25-30，共六个指标口径，一切以口径文档为准，不懂就问。
2、可以参考：RL E2E\RL E2E Traffic_Dashboard\KPI Progress\KPIS\KPIs_matrix_solution.md解决方案，但是没那么复杂，我只适用于柱形图和趋势图的展示，所以不需要矩阵的路由分发，单独写每个度量就行，只需要包括以下内容就行：
New Customer No. Value、New Customer No. Display、
New Customer% Value、New Customer% Display、
Media Contribution to New Customer Acquisition% Value、Media Contribution to New Customer Acquisition% Display、
Acceleration SLS Value、Acceleration SLS Display、
Acceleration SLS MOB% Value、Acceleration SLS MOB% Display、
Acceleration Cost MOB% Value、Acceleration Cost MOB% Display；
对应六个指标的值和数据格式度量。
清单：度量值清单与 Display Folder、指标口径来源对照、血缘关系图（Lineage Diagram）
3、在RL E2E\RL E2E Traffic_Dashboard\KPI Progress\KPI_Trend目录下生成KPI_Trend_solution解决方案文件，文件开头，参考以下固定格式：
KPI_Trend_solution 解决方案：
> status: updated
> created: 2026-06-23
> updated: 2026-07-03
> complexity: 🟡中等
> type: 度量值开发
> naming: 遵循 dax-style.md 规范
> 口径来源: KPI Progress.md（最新口径，2026-07-03 同步）