>> Merchandise Performance Overview:
# MPO第一轮提示词:
参考格式文件：D:\gutao\辜涛\Project\Qoder_AI_Frontend_and_backend_Web\RL E2E\RL E2E Customer Dashboard\Customer\Customer KPIs\Dim_ColMetric_Customer_KPIs.md

然后根据口径文档：D:\gutao\辜涛\Project\Qoder_AI_Frontend_and_backend_Web\RL E2E\RL E2E Merch Dashboard\口径文档\口径Markdown格式\Merchandise Performance Overview.md
只关注口径文档中「子模块一：Merchandising Core KPI【Amt】」和 「子模块二：Merchandising Core KPI【Unit】」部分，其他部分不关注。把子模块一和子模块二中的指标包括附属指标，在D:\gutao\辜涛\Project\Qoder_AI_Frontend_and_backend_Web\RL E2E\RL E2E Merch Dashboard\Merchandise Performance Overview\Merchandising Core KPI目录下生成维度表，我好用于后续操作。
数据格式Metric_Format根据口径文档的描述来，有拿不准的就参考D:\gutao\辜涛\Project\Qoder_AI_Frontend_and_backend_Web\RL E2E\模版复用\数据类型和格式总览.md
【Amt】和【Unit】的指标数量、结构一致，所以包括主指标和附属指标一共输出单方面的20个就行了。后续用按钮判断【Amt】和【Unit】使用什么逻辑。

# MPO第二轮提示词:
1、口径文档：D:\gutao\辜涛\Project\Qoder_AI_Frontend_and_backend_Web\RL E2E\RL E2E Merch Dashboard\口径文档\口径Markdown格式\Merchandise Performance Overview.md
只关注口径文档中「子模块一：Merchandising Core KPI【Amt】」和 「子模块二：Merchandising Core KPI【Unit】」部分，其他部分不关注。
2、日期筛选：
Slicer_Time_Frame：D:\gutao\辜涛\Project\Qoder_AI_Frontend_and_backend_Web\RL E2E\RL E2E Merch Dashboard\维度复用\筛选器\日期筛选器\Slicer_Time_Frame.sql
Slicer_Time_Frame_Min_This：D:\gutao\辜涛\Project\Qoder_AI_Frontend_and_backend_Web\RL E2E\RL E2E Merch Dashboard\维度复用\筛选器\日期筛选器\Slicer_Time_Frame_Min_This.sql
Slicer_Time_Frame_Max_This：D:\gutao\辜涛\Project\Qoder_AI_Frontend_and_backend_Web\RL E2E\RL E2E Merch Dashboard\维度复用\筛选器\日期筛选器\Slicer_Time_Frame_Max_This.sql
Slicer_Time_Frame_Min_Last：D:\gutao\辜涛\Project\Qoder_AI_Frontend_and_backend_Web\RL E2E\RL E2E Merch Dashboard\维度复用\筛选器\日期筛选器\Slicer_Time_Frame_Min_Last.sql
Slicer_Time_Frame_Max_Last：D:\gutao\辜涛\Project\Qoder_AI_Frontend_and_backend_Web\RL E2E\RL E2E Merch Dashboard\维度复用\筛选器\日期筛选器\Slicer_Time_Frame_Max_Last.sql
其中，时间粒度：Slicer_Time_Frame[TimeFrame_ID]
This Period: data_date ∈ [Slicer_Time_Frame_Min_This[TimeFrame_Min], Slicer_Time_Frame_Max_This[TimeFrame_Max]]
Last Period: data_date ∈ [Slicer_Time_Frame_Min_Last[TimeFrame_Min], Slicer_Time_Frame_Max_Last[TimeFrame_Max]]
在没有特殊说明的情况下，计算LY的时候，使用Last Period特定筛选器的结果作为上期时间范围对比。
3、Slicer_Platform_Selection、Slicer_Store_Name、Slicer_AX_Class等筛选器和事实表一对多关联，无需dax显示处理；仅涉及到金额类的需要dax显示处理，根据Slicer_Currency_Selection的汇率结果进行转换，在Display度量中处理，便于管理。
4、口径文档中部分描述解释：销售金额：看所选时间范围销售金额之和；期末库存金额：看所选时间范围 end period 最后一天；`sales.net_sales_amt / (sales.net_sales_amt + inv.msrp_inv_amt)`，所以这种一般要留意，sales.net_sales_amt是整个This Period的销售金额，inv.msrp_inv_amt是end period，就只关注data_date ∈ [Slicer_Time_Frame_Max_This[TimeFrame_Min], Slicer_Time_Frame_Max_This[TimeFrame_Max]]范围。
5、按钮控制文件：
IsAmtUnitFilter：D:\gutao\辜涛\Project\Qoder_AI_Frontend_and_backend_Web\RL E2E\RL E2E Merch Dashboard\维度复用\按钮筛选控制\IsAmtUnitFilter
IsProductTagFilter：D:\gutao\辜涛\Project\Qoder_AI_Frontend_and_backend_Web\RL E2E\RL E2E Merch Dashboard\维度复用\按钮筛选控制\IsProductTagFilter；
度量值中用 SELECTEDVALUE('IsAmtUnitFilter'[Sort]) 判断模式：=10 → Amt 逻辑；=20 → Unit 逻辑；IsProductTagFilter同理，其中选中 "ALL"：computed_product_tag 则 in ("hero model", "slow mover", "normal")；
6、TAR ACH% Progress（进度达成）/ TAR ACH% Target（目标达成），口径文档未给出具体计算公式，计算逻辑在后续度量值中实现，目前占位符为1和2就行。
7、列指标维度表：D:\gutao\辜涛\Project\Qoder_AI_Frontend_and_backend_Web\RL E2E\RL E2E Merch Dashboard\Merchandise Performance Overview\Merchandising Core KPI\Dim_ColMetric_Merchandising_Core_KPI.md
综合上述信息，结合D:\gutao\辜涛\Project\Qoder_AI_Frontend_and_backend_Web\RL E2E\RL E2E Customer Dashboard\Customer\Customer Breakdown\Customer_Breakdown_ms.md文件内容，输出Merchandising_Core_KPI解决方案在D:\gutao\辜涛\Project\Qoder_AI_Frontend_and_backend_Web\RL E2E\RL E2E Merch Dashboard\Merchandise Performance Overview\Merchandising Core KPI目录下，我要用于Powerbi卡片图的开发。Customer_Breakdown_ms.md文件内容和目前做的肯定是有差异的，只做参考，具体实施内容以1~7点为准。不懂就问。

# MPO第三轮提示词:
参考格式文件：D:\gutao\辜涛\Project\Qoder_AI_Frontend_and_backend_Web\RL E2E\RL E2E Merch Dashboard\Merchandise Performance Overview\Merchandising Core KPI\Dim_ColMetric_Merchandising_Core_KPI.md

结合图片，在D:\gutao\辜涛\Project\Qoder_AI_Frontend_and_backend_Web\RL E2E\RL E2E Merch Dashboard\Merchandise Performance Overview\Sales Performance Details by Channel目录下生成维度表：Dim_ColMetric_Sales_Performance_Details.md
目前方案没有双模态，只需要一个Metric_Format就行了。

此列指标维度表有三层，
第一层：Platform、Store
第二层：页面显示Label-->Platform包括：TTL、Tmall、JD、RLE、DY;Store包括：TTL、Tmall、JD、RLE、DY_Family、DY_W、DY_MN;
Platform事实表实际值：TLL的时候需要ALLSELECTED函数移除视觉对象内部Platform和Store的筛选，但保留外部切片器的筛选；Tmall对应事实表中的TM、JD-->JD、RLE-->RLE、DY-->DY;
Store事实表实际值：TLL的时候需要ALLSELECTED函数移除视觉对象内部Platform和Store的筛选，但保留外部切片器的筛选；Tmall对应事实表中的TM、JD-->JD、RLE-->RLE_CN、DY_Family-->DY_Family、DY_W-->DY_W、DY_MN-->DY_M;
具体对应关系可以查看D:\gutao\辜涛\Project\Qoder_AI_Frontend_and_backend_Web\RL E2E\RL E2E Merch Dashboard\维度复用\筛选器\固定值筛选器\Slicer_Platform_Selection和D:\gutao\辜涛\Project\Qoder_AI_Frontend_and_backend_Web\RL E2E\RL E2E Merch Dashboard\维度复用\筛选器\固定值筛选器\Slicer_Store_Name文件，所以这里的列指标维度表字段需要多一个Label字段。
第三层：如图所示：TTL之下是：SLS Unit、SLS Amt、YOY、SLS Amt%、LTD ST%、EOH Unit、AUR;
其余每个Platform或者Store之下都是：SLS Unit、SLS Amt、YOY、Vert.‌ Amt% 、Horiz.‌ Amt%、AUR;

综合以上信息，输出维度表：Dim_ColMetric_Sales_Performance_Details.md

# MPO第四轮提示词:
结合口径文档中的## 子模块六：Sales Performance Details by Channel：D:\gutao\辜涛\Project\Qoder_AI_Frontend_and_backend_Web\RL E2E\RL E2E Merch Dashboard\口径文档\口径Markdown格式\Merchandise Performance Overview.md
在D:\gutao\辜涛\Project\Qoder_AI_Frontend_and_backend_Web\RL E2E\RL E2E Merch Dashboard\Merchandise Performance Overview\Sales Performance Details by Channel目录下输出矩阵的完整解决方案；
列指标维度：Dim_ColMetric_Sales_Performance_Details.md
行指标维度：行维度分组分别由以下六个表字段其中一个拉到矩阵中，`Brand` / `super_season` / `product_type` / `category` / `md_type` / `division`，如果存在计算分母类别总计的，使用ALLSELECTED函数移除视觉对象内部的筛选，但保留外部切片器的筛选，由于一次只使用一个字段，我们可以同时ALLSELECTED这六个字段，实现对所有商品维度的统计。

可供参考解决方案格式：D:\gutao\辜涛\Project\Qoder_AI_Frontend_and_backend_Web\RL E2E\RL E2E Merch Dashboard\Merchandise Performance Overview\Merchandising Core KPI\Merchandising_Core_KPI_ms.md

我们做的是一个独立的解决方案，不要出现AI语境类的口语化文本，以及对比某某方案的话术，需要保留必要的dax注释信息。
综合以上信息，不懂就问，输出Sales_Performance_Details_ms.md的完整解决方案。



