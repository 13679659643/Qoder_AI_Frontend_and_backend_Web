>> Merchandise Performance Overview:
>>

# DCA Label & Product 第一轮提示词:

1、口径文档：D:\gutao\辜涛\Project\Qoder_AI_Frontend_and_backend_Web\RL E2E\RL E2E Merch Dashboard\口径文档\口径Markdown格式\Dimension Cross Analysis.md
只关注口径文档中子模块一到子模块四，这四部分。
2、日期筛选：
Slicer_Time_Frame：D:\gutao\辜涛\Project\Qoder_AI_Frontend_and_backend_Web\RL E2E\RL E2E Merch Dashboard\维度复用\筛选器\日期筛选器\Slicer_Time_Frame.sql
Slicer_Time_Frame_Min_This：D:\gutao\辜涛\Project\Qoder_AI_Frontend_and_backend_Web\RL E2E\RL E2E Merch Dashboard\维度复用\筛选器\日期筛选器\Slicer_Time_Frame_Min_This.sql
Slicer_Time_Frame_Max_This：D:\gutao\辜涛\Project\Qoder_AI_Frontend_and_backend_Web\RL E2E\RL E2E Merch Dashboard\维度复用\筛选器\日期筛选器\Slicer_Time_Frame_Max_This.sql
Slicer_Time_Frame_Min_Last：D:\gutao\辜涛\Project\Qoder_AI_Frontend_and_backend_Web\RL E2E\RL E2E Merch Dashboard\维度复用\筛选器\日期筛选器\Slicer_Time_Frame_Min_Last.sql
Slicer_Time_Frame_Max_Last：D:\gutao\辜涛\Project\Qoder_AI_Frontend_and_backend_Web\RL E2E\RL E2E Merch Dashboard\维度复用\筛选器\日期筛选器\Slicer_Time_Frame_Max_Last.sql
其中，时间粒度：Slicer_Time_Frame[TimeFrame_ID]
This Period: data_date ∈ [Slicer_Time_Frame_Min_This[TimeFrame_Min], Slicer_Time_Frame_Max_This[TimeFrame_Max]]
Last Period: data_date ∈ [Slicer_Time_Frame_Min_Last[TimeFrame_Min], Slicer_Time_Frame_Max_Last[TimeFrame_Max]]
在没有特殊说明的情况下，计算LY/LP的时候，使用Last Period特定筛选器的结果作为上期时间范围对比。
3、看板整体模型关系：日期、币种和事实表断开维度需要显示处理；Platform、Store Name、以及其余商品维度字段和事实表一对多关联。
4、
在D:\gutao\辜涛\Project\Qoder_AI_Frontend_and_backend_Web\RL E2E\RL E2E Merch Dashboard\Dimension Cross Analysis\1 Label & Product Type Inventory Structure目录下给出完整的解决方案，命名为Label_&_Product_Type_table。
参考格式：D:\gutao\辜涛\Project\Qoder_AI_Frontend_and_backend_Web\RL E2E\RL E2E Merch Dashboard\SKU Sales Tracking\4 Series Sales Performance\Series_Sales_Table.md
5、
由于我们这个场景不是做矩阵，是表格，所以只需要独立输出每个指标的Value和Display，此外附属指标也需要写逻辑输出。
6、子模块一和子模块三：
SLS Amt%、EOH Amt%、SLS Amt% vs LP、EOH Amt% vs LP：分母计算直接ALLSELECTED 六个商品维度切换：label、super_season、product_type、category、md_type、division，这样不管图表处于何种商品维度，一套逻辑就能满足，我理解是这样的。六个商品维度都和事实表一对多关联，无需显示处理dax，所以子模块一和子模块三在这样的操作下是可以共享同一套逻辑的。
7、子模块二和子模块四：
子模块二以 Label 为基数，看所选商品维度(super_season、product_type、category、md_type、division其中之一)在该 Label 的占比；
子模块四以  Product Type 为基数，看所选商品维度(label、super_season、category、md_type、division其中之一)在该  Product Type 的占比；
在柱形图中表示，即x轴是Label或者Product Type，我们需要先移除视觉对象字段筛选影响同时保留外部切片器的影响，然后重新添加x轴当前Label或者Product Type值，这样去算所选商品维度占单个柱形的占比。
所以子模块二和子模块四没法合并为同一套逻辑，需要单独输出。
8、
由于涉及到多个事实表，所以一切维度字段我都是从维度表中拉取的值，比如：Slicer_Label等。
9、
我们做的是一个独立的解决方案，不要出现AI语境类的口语化文本，以及对比某某方案的话术，需要保留必要的dax注释信息。
综合以上信息，不懂就问；我的理解有任何问题都可以指出讨论。

# DCA Label & Division第二轮提示词:
1、
参考文件格式:
D:\gutao\辜涛\Project\Qoder_AI_Frontend_and_backend_Web\RL E2E\RL E2E Merch Dashboard\SKU Sales Tracking\4 Series Sales Performance\Series_Sales_Table.md
2、
由于我们这个场景不是做矩阵，是表格，所以只需要独立输出每个指标的Value和Display，此外附属指标也需要写逻辑输出。
3、
由于涉及到多个事实表，所以一切维度字段我都是从维度表中拉取的值，比如：Slicer_Label、Slicer_Category等。维度表和事实表一对多。
4、
我们做的是一个独立的解决方案，不要出现AI语境类的口语化文本，以及对比某某方案的话术，需要保留必要的dax注释信息。
5、
vs LP：this period - last period（差值，bp 指标，展示时×10000 转 bp）；vs LY：this year - last year（差值，bp 指标，展示时×10000 转 bp）；其中this period、last period分别指两个日期切片器的筛选值;
this year、last year中this year对应data_date ∈ [Slicer_Time_Frame_Min_This[TimeFrame_Min], Slicer_Time_Frame_Max_This[TimeFrame_Max]],last year对应data_date ∈ [Slicer_Time_Frame_Min_This[TimeFrame_Min_LY], Slicer_Time_Frame_Max_This[TimeFrame_Max_LY]];
综合以上信息，不懂就问；我的理解有任何问题都可以指出讨论。
综合以上信息在D:\gutao\辜涛\Project\Qoder_AI_Frontend_and_backend_Web\RL E2E\RL E2E Merch Dashboard\Dimension Cross Analysis\2 Product Type Sales & Inventory Structure目录下给出完整的解决方案，命名为Label_&_Division_table。
输出测试sql文件，测试SQL中，
-- Platform:              'ALL'（全选，等价不筛选，SQL 中不附加条件）
-- Store Name:            'ALL'（全选，等价不筛选，SQL 中不附加条件）
-- This Period:     dt ∈ ['2026-03-29', '2026-07-25']（区间汇总）
-- Last Period:     dt ∈ ['2025-03-30', '2025-09-27']（区间汇总）
-- This Year:   dt ∈ ['2026-03-29', '2026-07-25']（区间汇总）
-- Last Year:   dt ∈ ['2025-03-30', '2025-07-26']（区间汇总）
按Division分组输出一段SQL，即在Division分组下，每个Division对应的所有Category指标情况。
按Label分组输出一段SQL，即在Label分组下，每个Label对应的所有Category指标情况，Label在表中对应brand字段。
一个测试文件中输出两段SQL。

