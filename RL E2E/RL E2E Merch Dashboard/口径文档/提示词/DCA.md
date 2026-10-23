>> Merchandise Performance Overview:
>>

# DCA 1 Label & Product 第一轮提示词:

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

# DCA 2 Label & Division第二轮提示词:
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

# DCA 3 MD Sales 第三轮提示词:
1、
参考文件格式:
D:\gutao\辜涛\Project\Qoder_AI_Frontend_and_backend_Web\RL E2E\RL E2E Merch Dashboard\Dimension Cross Analysis\2 Product Type Sales & Inventory Structure\Label_&_Division_table.md
2、
只关注口径文档中的子模块六：MD Sales Structure
3、
由于我们这个场景不是做矩阵，是表格，所以只需要独立输出每个指标的Value和Display，此外附属指标也需要写逻辑输出。本次方案一共就六个指标：SLS Amt%、SLS Amt：currency、SLS Amt% vs LP:integer_bp、MSRP Amt%、MSRP Amt：currency、MSRP Amt% vs LP:integer_bp；其中integer_bp类型的，展示时×10000 转 bp，这个步骤放在Value中，这样我Y轴刻度数才是正确的。
4、
我们做的是一个独立的解决方案，不要出现AI语境类的口语化文本，以及对比某某方案的话术，需要保留必要的dax注释信息。
本次方案和之前做的Label_&_Division_table方案类似，之前的是统计各 Category比例，本次是各 md_type；参考Label_&_Division_table方案输出解决方案和测试SQL文件。
综合以上信息，不懂就问；我的理解有任何问题都可以指出讨论。
综合以上信息在D:\gutao\辜涛\Project\Qoder_AI_Frontend_and_backend_Web\RL E2E\RL E2E Merch Dashboard\Dimension Cross Analysis\3 MD Sales Structure目录下给出完整的解决方案，命名为
MD_Sales_table。


# DCA 8 Handbags Sales 第四轮提示词:
1、
参考文件格式:
D:\gutao\辜涛\Project\Qoder_AI_Frontend_and_backend_Web\RL E2E\RL E2E Merch Dashboard\Dimension Cross Analysis\3 MD Sales Structure\MD_Sales_table.md
2、
只关注口径文档中的子模块十一：Handbags Sales Analysis by Dimension，我们跳着做的不用惊讶。
3、
只需要独立输出每个指标的Value和Display，此外附属指标也需要写逻辑输出。本次方案一共就七个指标：SLS Amt、SLS Amt%、SLS Amt% vs LP、SLS Unit、EOH Unit、EOH Unit vs LP、ST%；
4、
涉及两张数据表，s02_trade_sku_data_d、s02_inventory_stock_sales_detail_d，其中库存表是没有平台、店铺渠道属性的。
5、
字段参数，D:\gutao\辜涛\Project\Qoder_AI_Frontend_and_backend_Web\RL E2E\RL E2E Merch Dashboard\维度复用\筛选器\字段参数\Field_Parameter_Store_Name，矩阵行字段使用字段参数表的Field_Parameter_Store_Name字段，通过字段参数实现动态维度切换，参数表字段都来自于s02_trade_sku_data_d表，所以矩阵行维度也是，两个事实表之间没有建立关系，维度字段无法传递，需要显示处理涉及到s02_inventory_stock_sales_detail_d表的指标。类似的参考案例涉及多个事实表作用于同一个矩阵：
D:\gutao\辜涛\Project\Qoder_AI_Frontend_and_backend_Web\RL E2E\RL E2E Merch Dashboard\SKU Sales Tracking\4 Series Sales Performance\Series_Sales_Table.md
D:\gutao\辜涛\Project\Qoder_AI_Frontend_and_backend_Web\RL E2E\RL E2E BOSS Dashboard\Performance by Merchandise\PB_Merchandise_Fulfillment_detail_ms.md
6、
渠道按钮切片器，始终单选：
D:\gutao\辜涛\Project\Qoder_AI_Frontend_and_backend_Web\RL E2E\RL E2E Merch Dashboard\维度复用\筛选器\按钮筛选器\Button_Store_Name
使用其中的ActualValue实际值对应表中的s02_trade_sku_data_d[shop_name]字段，TTL的时候就是全部，使用IN 所有的shop_name字段值。
7、参考一下dax输出七个指标非空的度量：
```dax
MD Sales Table IsEmpty =
// ========================================
// 度量值: MD Sales Table IsEmpty
// 中文名: 行非空判定
// Display Folder: MD Sales Table IsEmpty\IsEmpty
// 用途: 行可见性判定——该行全部核心指标为空时返回 0，任一有值返回 1；
//       用于表格视觉级筛选器（IsEmpty = 1 仅显示有数据的行，
// ========================================
    IF(
        ISBLANK([MD Sales Table SLS Amt% Value]) &&
        ISBLANK([MD Sales Table SLS Amt% vs LP Value]) &&
        ISBLANK([MD Sales Table MSRP Amt% Value]) &&
        ISBLANK([MD Sales Table MSRP Amt% vs LP Value]),
        0,
        1
    )
```
8、
我们做的是一个独立的解决方案，不要出现AI语境类的口语化文本，以及对比某某方案的话术，需要保留必要的dax注释信息。

综合以上信息，评估一下，是否可以实现，通过字段参数切片器实现矩阵行维度的动态变化，指标值也会根据行维度变化而变化，不懂就问；我的理解有任何问题都可以指出讨论。
综合以上信息在D:\gutao\辜涛\Project\Qoder_AI_Frontend_and_backend_Web\RL E2E\RL E2E Merch Dashboard\Dimension Cross Analysis\4 Handbags Sales Analysis by Dimension目录下给出完整的解决方案，命名为
Handbags_Sales_ms。


# DCA 4 Item Stockout & Slow Mover Alert  第五轮提示词:
口径文档:
D:\gutao\辜涛\Project\Qoder_AI_Frontend_and_backend_Web\RL E2E\RL E2E Merch Dashboard\口径文档\口径Markdown格式\Dimension Cross Analysis.md
只关注口径文档中的子模块七：Item Stockout & Slow Mover Alert，我们跳着做的不用惊讶。
排名参考文档：D:\gutao\辜涛\Project\Qoder_AI_Frontend_and_backend_Web\RL E2E\RL E2E Merch Dashboard\SKU Sales Tracking\2 Top Color Sales Performance\Top_Color_Sales_Performance_table.md
多事实表桥接参考文档：D:\gutao\辜涛\Project\Qoder_AI_Frontend_and_backend_Web\RL E2E\RL E2E Merch Dashboard\Dimension Cross Analysis\8 Handbags Sales Analysis by Dimension\Handbags_Sales_ms.md

需求场景：我有两个按钮一个SPU一个SKU，对应s02_trade_sku_data_d[spu_id]\s02_trade_sku_data_d[sku_id],Powerbi中我要做的是spu_id维度的一张表，sku_id维度的一张表，注意是表不是矩阵，通过按钮去切换。仅取 Top 100，排序依据SLS Amt排序，降序取最大的100条。所有需要给出排序度量Dax，排名：RANK 窗口函数（金额降序 + Item：`spu_id` / SKU：`sku_id` 字母序决胜，唯一名次），所以要有两个排序度量；
表维度字段：spu_id/sku_id、us_style、ax_class、product_type、special_series、spu_img_url，区别仅在于spu_id/sku_id，同一个spu_id/sku_id后面五个属性业务上是一样的，所以只需要通过spu_id/sku_id去过滤行就行了。我以s02_trade_sku_data_d表中的字段作为表维度，所以涉及到s02_inventory_stock_sales_detail_d表的指标需要显示处理。
能否每个指标只写一个度量，就可以满足spu_id/sku_id，如果不行的话就只有分开写。注意这里是表只有总计，由页面提供，没用小计没有层级。

综合上述信息，在D:\gutao\辜涛\Project\Qoder_AI_Frontend_and_backend_Web\RL E2E\RL E2E Merch Dashboard\Dimension Cross Analysis\4 Item Stockout & Slow Mover Alert目录下输出Item_Stockout_Table;

上述维度有问题，我们讨论一下：
表中现在是涉及到以下八个表字段相关的：spu_id/sku_id、us_style、ax_class、product_type、special_series、spu_img_url、computed_product_tag、special_supply
现在需求变化，一切计算都按spu_id/sku_id维度计算了，其他字段存在多行的都只展示最新的那行，用户选择了一个时间段，也只展示最新的那条，比如先筛选条件以及当前行上下文的筛选下，us_style如果存在多少，那么表中只展示当前spu_id/sku_id下，dt+us_style最新的那条数据。
相当于这个模块的维度只有spu_id/sku_id，其余所有字段，都当成指标去写逻辑处理了，最终展示的一定是不重复的spu_id/sku_id；
排名也是按照spu_id/sku_id维度去排名。
computed_product_tag字段只存在于s02_inventory_stock_sales_detail_d表，那就从这个表去，其余维度值在s02_trade_sku_data_d取。
最特殊的这个Available sizes指标，不是取最新，而是spu_id/sku_id下所有的尺码顿号拼接。

-- Platform:              'ALL'（全选，等价不筛选，SQL 中不附加条件）
-- Store Name:            'ALL'（全选，等价不筛选，SQL 中不附加条件）
-- This Period:     dt ∈ ['2026-03-29', '2026-07-25']（区间汇总）
-- Last Period:     dt ∈ ['2025-03-30', '2025-09-27']（区间汇总）
-- This Year:   dt ∈ ['2026-03-29', '2026-07-25']（区间汇总）
-- Last Year:   dt ∈ ['2025-03-30', '2025-07-26']（区间汇总）
-- end period最后一天：'2026-07-25'
-- end period所在财年第一天：'2026-03-29'
-- end period所在财月第一天：'2026-06-28'


# DCA 5 Top & OPP SKUs Analysis  第六轮提示词 Top:
口径文档:
D:\gutao\辜涛\Project\Qoder_AI_Frontend_and_backend_Web\RL E2E\RL E2E Merch Dashboard\口径文档\口径Markdown格式\Dimension Cross Analysis.md
只关注口径文档中的子模块九：Top & OPP SKUs Analysis，这个模块其实包括了两个部分，我们先做简单的Top部分。
维度值取最新一条参考文档:
D:\gutao\辜涛\Project\Qoder_AI_Frontend_and_backend_Web\RL E2E\RL E2E Merch Dashboard\Dimension Cross Analysis\4 Item Stockout & Slow Mover Alert\Item_Stockout_Table.md
排序参考文档：
D:\gutao\辜涛\Project\Qoder_AI_Frontend_and_backend_Web\RL E2E\RL E2E Merch Dashboard\SKU Sales Tracking\1 Top Size Sales Performance\Top_Size_Sales Performance_table.md

需求场景：
还是涉及两个表：s02_trade_sku_data_d、s02_inventory_stock_sales_detail_d，表中的字段依旧是使用s02_trade_sku_data_d表的字段，所以涉及库存相关的指标需要桥接。
我会前置筛选即再视觉对象筛选处，筛选Slicer_Framework[framework]='Foundation',维度表和事实表一对多关联，无需显示处理。
表字段有以下，口径文档可能没有显示全:
1、
category：s02_trade_sku_data_d[category]
sku_id：s02_trade_sku_data_d[sku_id]
spu_img_url：筛选条件下，取category+sku_id+dt最新的一条数据，排序参考文档中有参考。
product_type：筛选条件下，取category+sku_id+dt最新的一条数据，排序参考文档中有参考。
md_price：筛选条件下，取category+sku_id+dt最新的一条数据，排序参考文档中有参考。
Weeks Cover：口径文档40. Weeks Cover — 库存周转周数
SLS Units：口径文档41. SLS Units — DCom净销售数量
EOH：口径文档42. EOH — 期末库存数量
Predictive Buy：s02_trade_sku_data_d[predictive_buy]为String类型，值包括"1"\"0"\空。筛选条件下，取category+sku_id+dt最新的一条数据，排序参考文档中有参考，并且如果为"1"，输出为"Y","0"对应"N",其余为空。
隐藏指标，SLS Amt — DCom净销售额：该 category+sku_id分组 下 `sum(net_sales_amt)`，排序规则使用此字段值降序排序。
筛选条件下，每个category会有多个sku_id，需要生成Sort Key表格行排序键，然后用于视觉对象筛选中过滤Top3的，这样每个category分组下就只有三个SKU。

综合上述信息，在D:\gutao\辜涛\Project\Qoder_AI_Frontend_and_backend_Web\RL E2E\RL E2E Merch Dashboard\Dimension Cross Analysis\5 Top & OPP SKUs Analysis目录下输出Top_SKUs_Analysis_Table;