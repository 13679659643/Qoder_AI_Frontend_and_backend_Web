>> Merchandise Performance Overview:
# SKU ST第一轮提示词:
1、口径文档：D:\gutao\辜涛\Project\Qoder_AI_Frontend_and_backend_Web\RL E2E\RL E2E Merch Dashboard\口径文档\口径Markdown格式\Merchandise Performance Overview.md
只关注口径文档中「子模块一：Top Size Sales Performance【Sales】」和 「子模块二：Top Size Sales Performance【Inventory】」部分，其他部分不关注。涉及到的指标也就6个，Sales：Sales SLS Amt%、Sales LP SLS Amt%、Sales vs LP；Inventory：Inventory EOH Amt%、Inventory LP EOH Amt%、Inventory vs LP；
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
3、看板整体模型关系：日期、币种和事实表断开维度需要显示处理，但此模块指标不涉及币种的兑换；Platform、Store Name、以及其余商品维度和事实表一对多关联。目前模块只受到date + Platform + Store Name+Division这四组筛选的影响，其余筛选我会在Powerbi页面编辑交互中取消切片器对图表的筛选效果。
综合上述信息，实现如图所示的Powerbi表格：
我通过Sales和Inventory按钮去动态的显示或者隐藏表格，实现Sales和Inventory指标的切换，这个很好实现，主要是表格内容的实现,以Sales第一个表格为例：
Category：s02_trade_sku_data_d[category]，date + Platform + Store Name+Division这四组筛选的分组下，只要Top4的category，根据sum(net_sales_amt)指标排序。Sales第一个表格就是Top1，Sales第二个表格就是Top2，以此类推。
Size Category：s02_trade_sku_data_d[sku_size_category]，Top4的category对应表字段。
Size：s02_trade_sku_data_d[sku_size]，Top4的category对应表字段。
SLS Amt%：在筛选条件下的sum(net_sales_amt) ，该Category、size占所属size category的比例
LP SLS Amt%：Last Period销售金额占比
vs LP：this period - last period（差值，bp 指标，展示时×10000 转 bp）
在D:\gutao\辜涛\Project\Qoder_AI_Frontend_and_backend_Web\RL E2E\RL E2E Merch Dashboard\SKU Sales Tracking\1 Top Size Sales Performance目录下给出完整的解决方案，命名为Top_Size_Sales Performance_table。
参考格式：D:\gutao\辜涛\Project\Qoder_AI_Frontend_and_backend_Web\RL E2E\RL E2E Merch Dashboard\Merchandise Performance Overview\Merchandising Core KPI\Merchandising_Core_KPI_ms.md
由于我们这个场景不是做矩阵，是表格，所以只需要独立输出每个指标的Value和Display度量；
我们做的是一个独立的解决方案，不要出现AI语境类的口语化文本，以及对比某某方案的话术，需要保留必要的dax注释信息。
综合以上信息，不懂就问；
注意：
1、我在获取数据源的时候ROUND(product_qty*sales_price, 6) as net_sales_amt，有新增一列，所以实际Powerbi模型中是有net_sales_amt字段的。
2、按 this period 最后一天 sum(msrp_inv_amt) 在 category 粒度排名，Inventory 4 个表格独立于 Sales 展示库存视角 Top4
3、s02_inventory_stock_sales_detail_d 无 platform / shop_name 字段，Inventory 指标（EOH Amt% 系列）将不受 Platform / Store Name 筛选影响（只受 date + Division 影响），与 Merchandising Core KPI 中 inv 表的处理一致。

# MPO第二轮提示词:
参考文件：D:\gutao\辜涛\Project\Qoder_AI_Frontend_and_backend_Web\RL E2E\RL E2E Merch Dashboard\SKU Sales Tracking\1 Top Size Sales Performance\Top_Size_Sales Performance_table.md
参考SQL测试：D:\gutao\辜涛\Project\Qoder_AI_Frontend_and_backend_Web\RL E2E\RL E2E Merch Dashboard\SKU Sales Tracking\1 Top Size Sales Performance\test_Top_Size_Sales_Performance_table.sql
口径文档：
D:\gutao\辜涛\Project\Qoder_AI_Frontend_and_backend_Web\RL E2E\RL E2E Merch Dashboard\口径文档\口径Markdown格式\SKU Sales Tracking.md;只关注子模块三：Top Color Sales Performance【Sales】和子模块四：Top Color Sales Performance【Inventory】；

如图所示，现在我们做另外一部分的表格，只有一个行维度Color，分别对应Sales表：s02_trade_sku_data_d[color_name]、Inventory表：s02_inventory_stock_sales_detail_d[color_name];
SLS Amt、SLS Amt%、EOH Amt、EOH Amt%这个四个我理解是可以直接复用参考文件Top_Size_Sales Performance_table.md中的相关指标的。
SLS Unit、SLS Unit%、EOH Unit、EOH Unit%这四个根据口径文档中的逻辑编写Dax。
由于我们这个场景不是做矩阵，是表格，所以只需要独立输出每个指标的Value和Display度量；
我们做的是一个独立的解决方案，不要出现AI语境类的口语化文本，以及对比某某方案的话术，需要保留必要的dax注释信息。
综合以上信息，不懂就问；


# MPO第三轮提示词:
口径文档：
D:\gutao\辜涛\Project\Qoder_AI_Frontend_and_backend_Web\RL E2E\RL E2E Merch Dashboard\口径文档\口径Markdown格式\SKU Sales Tracking.md;只关注子模块五：Emerging Style Identification【Sales】和子模块六：Emerging Style Identification【Inventory】；
Sales：
矩阵行：color_name
矩阵列：sku_size
值：SLS Amt%
Inventory：
矩阵行：color_name
矩阵列：sku_size
值：EOH Amt%

我们做的是一个独立的解决方案，不要出现AI语境类的口语化文本，以及对比某某方案的话术，需要保留必要的dax注释信息。
综合以上信息，在D:\gutao\辜涛\Project\Qoder_AI_Frontend_and_backend_Web\RL E2E\RL E2E Merch Dashboard\SKU Sales Tracking\3 Emerging Style Identification目录下生成解决方案，命名为3 Emerging_Style_ms,不懂就问；