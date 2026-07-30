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
在RL E2E\RL E2E BOSS Dashboard\维度复用目录下，我已经完成了一些维度表的设计工作，都是可服用的如下，以及设计表的DAX语句、SQL语句：
1、事实表，powerbi中命名为：a02_e2e_boss_performance_summary_d；
2、日期筛选器，Slicer_Time_Frame_Min和Slicer_Time_Frame_Max，与事实表断开维度，Slicer_Time_Frame用于页面上的Timeframe(Day\Week\Month\Quarter\Year)筛选,通过关联Slicer_Time_Frame_Min和Slicer_Time_Frame_Max对应不同的TimeFrame_Value，需要把年月季周都转化为日，去筛选a02_e2e_boss_performance_summary_d表中的data_date字段。
3、Currency筛选器，断开连接，仅金额类指标除以汇率固定为7；
4、事实表数据字典：RL E2E\RL E2E BOSS Dashboard\参考文件\a02_e2e_boss_performance_summary_d_数据字典.md
5、指标列维度，RL E2E\RL E2E BOSS Dashboard\Overview\BOSS Core KPI\Dim_ColKPIs_BossCoreKPI_Overview，列有两级，第一级为store_name对应a02_e2e_boss_performance_summary_d[store_name]，第二级为Act、LY、vs LY，对应口径文档RL E2E\RL E2E BOSS Dashboard\口径文档\Overview.md中的子模块一：BOSS Core KPI口径。
6、行维度，RL E2E\RL E2E BOSS Dashboard\Overview\BOSS Core KPI\Dim_RowKPIs_BossCoreKPI_Overview，包含Sales和Fulfillment分组，Sales分组下包括：SLS、Demand SLS、SLS Penetration、Return、Return%；Fulfillment分组下包括：Fulfillment%、Request Order Qty、Request Units、Request Order Amt、Shipped Order Qty、Shipped Units、Shipped Order Amt。
需求：
在RL E2E\RL E2E BOSS Dashboard\Overview\BOSS Core KPI目录下，输出Overview_KPIs_BossCoreKPI矩阵的powerbi解决方案。
1、本次矩阵只关注子模块一：BOSS Core KPI口径，一切指标都按照子模块一的口径进行计算，不懂就问。
2、可以参考RL E2E\RL E2E Traffic_Dashboard\KPI Progress\KPIS\KPIs_matrix_solution.md解决方案。
3、BOSS Core KPI Cell Font Color仅对vs LY指标启用正/负/零三色，使用Dim_ColKPIs_BossCoreKPI_Overview中的Metric_ColorPositive、Metric_ColorNegative、Metric_ColorZero、Metric_ColorDefault字段，区别总计行和其他行，总计行字体颜色为黑色#252423，其他行字体颜色为5F6165（深灰）。通过ISINSCOPE('Dim_RowKPIs_BossCoreKPI_Overview'[KPIName])进行层级判断。
4、BOSS Core KPI Cell Background Color区别总计行和其他行，总计行背景颜色为#E6D9C7（中米色），其他行背景颜色为白色#FFFFFF。
5、BOSS Core KPI Cell SVG Icon只关注vs LY列指标，其他指标不关注，SVG Icon就使用KPI Breakdown Cell SVG Icon中的图标。
6、输出的dax必须带有必要注释信息，指标名称的注释需要有指标名称和指标名称中文一起，例如："SLS O2O销售净额"、"SLS O2O销售净额（去年同期）"、"SLS O2O销售净额（与去年同期对比）"。
7、一切口径以指标口径文档RL E2E\RL E2E BOSS Dashboard\口径文档\Overview.md中的子模块一：BOSS Core KPI部分为准，不懂就问。

第二轮提示：

第三轮提示：

不懂就问。

第四轮提示:

第五轮提示：
