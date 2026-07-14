第一轮提示词：
以RL E2E\RL E2E Traffic_Dashboard\口径文档\Category Growth.md，指标文档为SPEC；在RL E2E\RL E2E Traffic_Dashboard\KPI Breakdown目录下新增KPI Breakdown解决方案文件。

变更记录总结到RL E2E\RL E2E Traffic_Dashboard\changelog.md文件的对应模块，当前面模块是[Category Growth] 模块，注意是追加不是覆盖，不要删除我原有的内容，追加到子板块：KPI Breakdown的最上方。
目前已有可复用的文件：
1、事实表：a05_e2e_paid_media_summary_d；
2、日期筛选器，Slicer_Time_Frame和事实表断开维度，RL E2E\RL E2E Traffic_Dashboard\维度复用\Slicer_Time_Frame.sql，用于页面上的Timeframe(Day\Week\Month\Quarter\Year),对应不同的TimeFrame_Value，需要把年月季周都转化为日，去筛选a05_e2e_paid_media_summary_d表中的data_date字段，String格式，“2025-10-24”；
3、Platform筛选器，Slicer_Platform_Selection，RL E2E\RL E2E Traffic_Dashboard\维度复用\Slicer_Platform_Selection，对应四个平台。对应事实表中的a05_e2e_paid_media_keyword_data_d[platform]；一对多事实表，模型会自动筛选事实表；
4、Store Name筛选器，表Slicer_Store_Name，对应a05_e2e_paid_media_keyword_data_d[store_name]；一对多事实表，模型会自动筛选事实表；
5、trans_cycle筛选器，RL E2E\RL E2E Traffic_Dashboard\维度复用\Slicer_DataCaliber_Selection对应事实表中的a05_e2e_paid_media_keyword_data_d[trans_cycle]；一对多事实表，模型会自动筛选事实表；
6、Currency筛选器，RL E2E\RL E2E Traffic_Dashboard\维度复用\Slicer_Currency_Selection，断开连接，仅金额类指标乘以汇率固定为7；
7、Scenario筛选器，表名Brand->Category->Framework，包括六个排列组合行维度，参考文件RL E2E\RL E2E Traffic_Dashboard\Category Growth\Brand-Category-Framework排列组合.sql，通过SELECTEDVALUE获取到筛选器的值，判断Level 1	Level 2	Level3对应事实表中的字段，然后获取到当前上下文的值，才能准确的筛选事实表对应的字段。我这里虽然是四层结构，Total->Brand->Category->Framework,但只有最后三层是在变换level的，第一层始终是Total，也对应事实表中的 `Total`值字段，这个字段一整列的值都为"Total";
8、行路由维度使用这个表， Brand-Category-Framework，表结构就是由RL E2E\RL E2E Traffic_Dashboard\Category Growth\Brand-Category-Framework排列组合.sql这个文件的SQL语句生成的，包括Scenario_Type	Scenario_Sort	Toatl	Level 1	Level 2	Level 3	ID_Sort这七个字段。和Scenario筛选器同源，通过Scenario_Type单选动态改变Toatl	Level 1	Level 2	Level 3四个层级的值。
9、列维度使用这个表，Dim_ColMetric_KpiBreakdown，由这个文件RL E2E\RL E2E Traffic_Dashboard\Category Growth\Dim_ColMetric_KpiBreakdown的DAX语句生成，包括四个平台，Platform筛选器一对多关联Dim_ColMetric_KpiBreakdown，通过筛选器动态切换不同的列维度，主要是JD和TM在channel字段上的差异，JD的channel有"快车"、"触点"、"海投"，TM的channel有"直通车"、"引力魔方"、"全站推"。

具体要求：
1、只需要输出核心度量部分，必须要有必要的注释信息，参考文件：RL E2E\RL E2E Traffic_Operation\Keyword\Keyword_YOY_matrix_solution结构。
2、参考上述7点可复用文件。
3、以RL E2E\RL E2E Traffic_Dashboard\口径文档\Category Growth.md，指标文档为SPEC；在RL E2E\RL E2E Traffic_Dashboard\KPI Breakdown目录下新增KPI Breakdown解决方案文件。
4、总计行的逻辑需要自定义计算每一个指标，使用ISINSCOPE；不收分组维度的影响，包括所有渠道，Cost% vs SLS%始终为0pt；SLS%始终为100%；Cost MOB%：Total始终为100%、直通车的总计行为直通车渠道值/三个渠道总的、引力魔方为引力魔方渠道值/三个渠道总的、全站推为全站推渠道值/三个渠道总的；ROI和New Customer Cost%的总计逻辑与Cost MOB%部分一致。JD平台虽然channel有差异，但是总计行的逻辑也是一致类似,只是需要把channel对比TM映射一下：直通车 -- 快车  引力魔方 -->触点  全站推-->海投。
5、字体颜色：Total指标列和总计行为"#252423"，其余为"#5F6165"；
6、明细行即第四层级的背景颜色为#F5F5F5，总计行为"#E6D9C7"，其中Total指标列为"#FAF6F1"颜色。其余为"#FFFFFF"白色。
7、仅Cost% vs SLS%指标才有SVG图标。
8、变更记录总结到RL E2E\RL E2E Traffic_Dashboard\changelog.md文件的对应模块，当前面模块是[Category Growth] 模块，注意是追加不是覆盖，不要删除我原有的内容，追加到子板块：KPI Breakdown的最上方。
9、不懂就问、不懂就问、不懂就问。

第二轮提示词：
1、层次判断需要判断到Total层级，VAR __Total = ISINSCOPE('Brand-Category-Framework'[Total]),这样NOT才能准确的判断是否是总计行。
2、Brand-Category-Framework和事实表a05_e2e_paid_media_summary_d是断开连接的，根据你输出的解决方案__L1_Filter, __L2_Filter, __L3_Filter可以实现预期值吗，是什么原理，如何实现的？在Level3层级，事实表需要受到Toatl、Level 1、Level 2、Level 3这四个层级的筛选，才能准确的获取到对应的值。Level 2层级需要受到Toatl、Level 1、Level 2对应值的筛选，以及Level 3在Scenario_Type的所有值；Toatl、Level 1同理。
3、SWITCH路由分发ID的时候，就不能使用in吗，其实TM\RLE\DY指标逻辑值都是一样的，JD和TM的channel差异只是在渠道名称上，所以在分发ID的时候，需要把TM的channel映射一下，JD的"快车"、"触点"、"海投"对应TM的"直通车"、"引力魔方"、"全站推"。你的__ChannelFilter写的没问题，只是需要在SWITCH路由分发ID的时候，可不可以优化一下，太冗余了
4、模型中已建立 Dim_ColMetric_KpiBreakdown[Platform_ID] → Slicer_Platform_Selection[Platform_ID] 的一对多关系，Slicer_Store_Name 、 Slicer_DataCaliber_Selection 与事实表的一对多关系已建立。
5、KPI Breakdown Cell Font Color和KPI Breakdown Cell Background Color也需要判断Total层级，我们做的矩阵是四个层级，最外层的是Total层级，不判断这个，使用NOT __IsLevel1 && NOT __IsLevel2 && NOT __IsLevel3是不准确的。

第三次提示词：
1、总计行的判断必须VAR __IsTotalRow = NOT __IsTotal && NOT __IsLevel1 && NOT __IsLevel2 && NOT __IsLevel3才行，所以层级都为False，才是总计行。赞同我的理解吗。
2、__L1_Filter, __L2_Filter, __L3_Filter这三个一起不是取交集吗。当我在明细行的时候即Level3层级，我的预期效果，比如：__ScenarioType = "Brand->Category->Framework",那Total层级 = "Total"，Level 1 = Brand相关的值，通过这个值去筛选a05_e2e_paid_media_summary_d表中的brand字段，Level 2 = Category相关的值，通过这个值去筛选a05_e2e_paid_media_summary_d表中的category字段，Level 3 = Framework相关的值，通过这个值去筛选a05_e2e_paid_media_summary_d表中的framework_name字段。Brand->Category->Framework中的值就是从a05_e2e_paid_media_summary_d表提取brand、category、framework字段排列组合而成的。当我在Level2层级的时候，同理，区别在于此时Level 3是__ScenarioType = "Brand->Category->Framework"分组下的所有值；level2和Total列同理。

第四轮提示：
根据这三个文件：
RL E2E\RL E2E Traffic_Dashboard\Category Growth\Brand-Category-Framework排列组合.sql
RL E2E\RL E2E Traffic_Dashboard\Category Growth\Dim_ColMetric_KpiBreakdown
RL E2E\RL E2E Traffic_Dashboard\Category Growth\KPI_Breakdown_matrix_solution.md
在RL E2E\RL E2E Traffic_Dashboard\KPI Breakdown目录下输出针对数据库和Powerbi页面的测试SQL，

sql测试参数时间为：2025-01-01~2026-07-14；platform：TM；shop_name：TM;trans_cycle:T+1;brand:M Polo;Category:Sweaters;Framework:Foundation;

Scenario_Type:Category->Framework->Brand
pbi指标：Cost% vs SLS%、Cost MOB% Total、Cost MOB%中直通车、ROI Total、ROI中全站推、New Customer Cost% Total、New Customer Cost% 引力魔法；
给出完整SQL语句，每个指标单独验证。
