第一轮提示词：
参考D:\gutao\辜涛\Project\Qoder_AI_Frontend_and_backend_Web\RL E2E\RL E2E Traffic_Dashboard\Category Growth\Dim_ColMetric_KpiBreakdown，
1、设计矩阵的行维度文件Dim_RowKPIs_BossCoreKPI_Overview，包含Sales和Fulfillment分组，Sales分组下包括：SLS、Demand SLS、SLS Penetration、Return、Return%；Fulfillment分组下包括：Fulfillment%、Request Order Qty、Request Units、Request Order Amt、Shipped Order Qty、Shipped Units、Shipped Order Amt；新增"Metric_IsCurrencyAmount", BOOLEAN, 仅金额类才会涉及到汇率转化，Currency筛选器改变时，vs LY同比值，不受影响，以及货币符号的拼接，根据Slicer_Currency_Selection表得到具体的Currency_ExchangeRate，除以得到的固定值，转化为美元，输出文件在RL E2E\RL E2E BOSS Dashboard\Overview\BOSS Core KPI目录下，命名为Dim_RowKPIs_BossCoreKPI_Overview。
2、设计矩阵的列维度文件Dim_ColKPIs_BossCoreKPI_Overview，包含TM、JD、RLE_CN、DY_Family、DY_W、DY_MN六个店铺分组，对应事实表的store_name字段，每个店铺分组下，都包括，Act、LY、vs LY，对应指标的实际值、去年值、与去年同比值；MetricName 追加空格实现同名区分；说明: Power BI Sort by Column 要求同名字段只能绑定一个排序值，通过追加空格使各平台同名值在底层字符串不同，从而支持独立排序；不同分组之间间隔10，便于后续拓展字段无缝接入。输出文件在RL E2E\RL E2E BOSS Dashboard\Overview\BOSS Core KPI目录下，命名为Dim_ColKPIs_BossCoreKPI_Overview。
格式类型（与 D:\gutao\辜涛\Project\Qoder_AI_Frontend_and_backend_Web\RL E2E\RL E2E BOSS Dashboard\口径文档\提示词\Overview提示词.md 口径文档一致），目前涉及的范围只包括子模块一：BOSS Core KPI，不懂就问，必须附带必要的DAX注释信息。



第二轮提示词:
1、去除Dim_ColKPIs_BossCoreKPI_Overview中StoreGroup字段的空格，这个不需要同名区分靠空格；
2、Dim_RowKPIs_BossCoreKPI_Overview中移除一下三个冗余的字段：
    "Metric_Numerator",       STRING,    // 分子字段名（派生指标用）
    "Metric_Denominator",     STRING,    // 分母字段名（派生指标用）
    "Metric_StatField",       STRING,    // 统计字段名（基础金额/数量类指标用）
3、"MetricFormat",           STRING,    // 格式类型标识
替换为三个字段以区别Act、LY、vs LY：
    "Metric_Format_Act",  STRING,     // 当期 行格式
    "Metric_Format_LY",       STRING,     // 去年同期 行格式（与本期格式一致）
    "Metric_Format_VsLY",     STRING,     // YOY、同比 行格式

第三轮提示词：
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

第三轮提示：

不懂就问。

第四轮提示:

第五轮提示：
