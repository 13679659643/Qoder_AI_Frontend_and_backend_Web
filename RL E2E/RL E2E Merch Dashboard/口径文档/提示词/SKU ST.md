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

# SKU ST第二轮提示词:
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


# SKU ST第三轮提示词:
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

# SKU ST第四轮提示词:
1、参考文件：D:\gutao\辜涛\Project\Qoder_AI_Frontend_and_backend_Web\RL E2E\RL E2E Merch Dashboard\SKU Sales Tracking\2 Top Color Sales Performance\Top_Color_Sales_Performance_table.md
2、口径文档：
D:\gutao\辜涛\Project\Qoder_AI_Frontend_and_backend_Web\RL E2E\RL E2E Merch Dashboard\口径文档\口径Markdown格式\SKU Sales Tracking.md，只关注其中的子模块七：Series Sales Performance
3、表中维度字段，Series对应s02_trade_sku_data_d[special_series]、AXC对应对应s02_trade_sku_data_d[spu_id]、Image对应对应s02_trade_sku_data_d[spu_img_url]。其中special_series我会在视觉对象筛选器中过滤值不为空，检查后续指标的计算是否符合这个前提。
4、指标的计算会涉及到s02_trade_sku_data_d、s02_inventory_stock_sales_detail_d两张表，但我拉取到表中的字段都来源于s02_trade_sku_data_d表，两张事实表间无模型关系，涉及到s02_inventory_stock_sales_detail_d表的计算时，行维度值无法自动传递，有什么好的解决方法嘛，此外表格我会开启行小计，这个也要保证数据正常。
5、Slicer_Time_Frame_Max_This日期表中我新增了Fiscal_Year_First_Day字段，涉及到YTD财年第一天的计算可以使用该字段；LTD的计算，销售金额只关注：<= 时间范围this period的最后一天、
期末库存金额只关注：看所选时间范围end period最后一天。
6、我在获取数据源的时候ROUND(product_qty*sales_price, 6) as net_sales_amt，有新增一列，所以实际Powerbi模型中是有net_sales_amt字段的。仅此一个字段预计算了，其余完全按照口径文档来。
7、结合：D:\gutao\辜涛\Project\Qoder_AI_Frontend_and_backend_Web\RL E2E\RL E2E Merch Dashboard\SKU Sales Tracking\1 Top Size Sales Performance\Top_Size_Sales Performance_table.md中4.17 Top Size Sales Sort Key（Sales 表格行排序键）、D:\gutao\辜涛\Project\Qoder_AI_Frontend_and_backend_Web\RL E2E\RL E2E Merch Dashboard\SKU Sales Tracking\2 Top Color Sales Performance\Top_Color_Sales_Performance_table.md中的Top Color Sales Color Rank（Sales Top10 排名），排名写法，本方案也需要输出一个排序键Sort Key：先以Series分组通过SLS Amt值降序排列，这个权重比较大，再以Series分组下AXC具体值降序，得到一个排序值。如何金额相同以维度值升序排序，使用新版 RANK 窗口函数更简洁，就不用破局器了。
由于我们这个场景不是做矩阵，是表格，所以只需要独立输出每个指标的Value和Display度量；
我们做的是一个独立的解决方案，不要出现AI语境类的口语化文本，以及对比某某方案的话术，需要保留必要的dax注释信息。
综合以上信息，不懂就问；
综合以上信息，在D:\gutao\辜涛\Project\Qoder_AI_Frontend_and_backend_Web\RL E2E\RL E2E Merch Dashboard\SKU Sales Tracking\4 Series Sales Performance目录下输出Series_Sales_Table完整解决方案，以及测试SQL。


# SKU ST第五轮提示词:

如图所示，现在是这么个情况，行字段漏了一个spu_img_url字段，导致Sort Key都是1000001，涉及到占比的都为1，spu_id和spu_img_url正常情况下都是一对一的，不排除异常情况，我的方案应该如何修改。
此外，参考以下dax，我们也加一个度量，由于SLS Amt为空，SLS Amt%就一定为空，所以涉及到SLS Amt和SLS Amt%类型类似的组合，就只判断SLS Amt就行了。
Top Size Sales IsEmpty = 
    IF(
        ISBLANK([Top Size Sales SLS Amt% Value]) &&
        ISBLANK([Top Size Sales LP SLS Amt% Value]) &&
        ISBLANK([Top Size Sales SLS Amt% vs LP Value]),
        0,
        1
    )

测试SQL中，我不支持这种变量模式，就直接替换。
SET @division :in ( 'CW','HM','MN','WM');
SET @this_min := '2026-03-29';
SET @this_max := '2026-07-25';
SET @end_date := '2026-07-25';
SET @fy_first := '2026-03-29';
你现在输出的是明细行，接着再输出一段SQL仅special_series维度的，special_series不为空。

# SKU ST第六轮提示词:
调整这个解决方案：D:\gutao\辜涛\Project\Qoder_AI_Frontend_and_backend_Web\RL E2E\RL E2E Merch Dashboard\SKU Sales Tracking\3 Emerging Style Identification\3 Emerging_Style_ms.md
主要是涉及到ALLSELECTED(Dim_Sales_sku_size[sku_size])相关的。
之前Dim_Sales_sku_size表只有一个字段，是sku_size，现在新增了四个字段：sku_size_category、size_rank、category_sort、global_sort_key。所以单纯的使用ALLSELECTED+单个字段是不符合我们预期结果的。
参考以下内容：
## Power BI 中“按列排序（Sort by Column）”功能的隐藏筛选传播
### 元宝解释 底层机制：
1. 为什么 ALLSELECTED('Slicer_Md_Type'[md_type]) 会失效（分母等于分子）？
   在 Power BI 的数据模型中，当你为 Slicer_Md_Type 表创建了“实际值”和“排序值”两列，并且对“实际值”设置了“按列排序”（按排序值排序）时，Power BI 底层会将这两个列强绑定。
   当你把 md_type（实际值）放在图表的行上，或者用视觉对象筛选器过滤时，Power BI 为了在后台执行排序，实际上同时对 md_type 和 排序值 两列施加了筛选上下文。
   单列 ALLSELECTED 的局限：ALLSELECTED('Slicer_Md_Type'[md_type]) 只移除了 md_type 这一列的筛选。但是，那个隐藏的“排序值”列的筛选依然存活在筛选上下文中。
   结果：存活的“排序值”筛选通过维度表与事实表的一对多关系，继续向事实表传导，把分母死死限制在了当前行（或当前筛选范围）的数据上。因此，分母等于了分子，占比变成了 100%。
### GLM-5.3:
1. “强绑定”的引擎术语是 auto-existence（同表共存）：md_type 一旦配置按列排序，视觉对象查询的 GroupBy 就不只是 Slicer_Md_Type[md_type] 一列，Slicer_Md_Type[_Sort] 被隐式带入；同表两列共存于查询时引擎将其合并为表粒度的组合筛选。这就是“为了后台执行排序，同时对两列施加筛选上下文”的底层实现——绑定发生在查询生成阶段，不是计算阶段。
2. 为什么存活的 _Sort 一个筛选就足够钉死分母：因为排序键与业务值是 1:1 对应（sort-by-column 的配置前提就是 Sort 在表内唯一）。删掉 mdtype 筛选后，Sort=Y 独自存活，但 1:1 反推回去等价于 mdtype=X——维度表仍被钉在当前行那一行，经一对多关系向事实表传导，分母与分子的聚合范围完全重合。若 Sort 不唯一（多行共享一个排序值），钉死就只是部分的，现象会变成“占比异常但不是恒 100%”——恒 100% 正是 1:1 的指纹。

// ── 期末日期：end period 最后一天 = Max_This 表 TimeFrame_Max（直接单日过滤）──
VAR __EndPeriodDate = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

// ── 期末日期（LY）：end period LY 最后一天 = Max_Last 表 TimeFrame_Max（直接单日过滤）──
VAR __EndPeriodDate_LY = SELECTEDVALUE(Slicer_Time_Frame_Max_Last[TimeFrame_Max])

// ── 期末日期：end period 最后一天 = Max_This 表 TimeFrame_Max（直接单日过滤）──
VAR __EndPeriodDate_This = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max])

// ── 期末日期（LY）：end period LY 最后一天 = Max_This 表 TimeFrame_Max_LY（直接单日过滤）──
VAR __EndPeriodDate_LY = SELECTEDVALUE(Slicer_Time_Frame_Max_This[TimeFrame_Max_LY])

// ── 期末日期（LP）：end period LP 最后一天 = Max_Last 表 TimeFrame_Max（直接单日过滤）──
VAR __EndPeriodDate_LP = SELECTEDVALUE(Slicer_Time_Frame_Max_Last[TimeFrame_Max])