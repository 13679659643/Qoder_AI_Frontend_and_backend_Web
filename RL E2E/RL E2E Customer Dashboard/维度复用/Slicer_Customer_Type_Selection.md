Slicer_Customer_Type_Selection = 
	// 功能：创建一个会员类型维度表，用于报表中的会员类型筛选和分组
	// 用途：用户可以通过此表选择不同的会员类型（新客/老客）进行分析
	// 参数表名称：Customer_Type
	// 遵循通用参数表模板规范
	DATATABLE(
	    // 基础字段 - 必选字段
	    "Customer_Type_ID", STRING,         // 主键标识，用于唯一标识每个会员类型选项，也用于与订单/客户表关联
	    "Customer_Type_Label", STRING,      // 显示标签，在报表界面中向用户展示的会员类型名称
	    "Customer_Type_Sort", INTEGER,      // 排序顺序，控制选项在切片器中的显示顺序
	    "Customer_Type_Description", STRING, // 详细描述，说明该会员类型的具体特点和业务含义
	    // 扩展字段 - 可选字段
	    "Customer_Type_IsDefault", BOOLEAN,  // 是否默认选中，TRUE表示用户打开报表时默认选择此类型
	    "Customer_Type_IsActive", BOOLEAN,   // 是否激活状态，控制该类型选项是否可用
	    "Customer_Type_Group", STRING,       // 分组标识，用于对相关类型进行逻辑分组（如生命周期阶段等）
	    // 自定义扩展字段 - 根据业务需求添加
	    "Customer_Type_Code", STRING,       // 业务代码：NEW/EXISTING，对应源数据库中的customer_type字段值
	    // 数据行
	    {
	        // 格式说明：每个花括号{}包含一行数据，顺序与上方字段定义一致
	        // NEW - 新会员
	        {
	            "New",                  // 类型代码，新会员的英文标识
	            "新客",                 // 类型显示名称
	            1,                      // 排序顺序，优先展示
	            "在统计周期内首次产生购买行为或注册的会员，代表品牌的新增流量",  // 类型描述
	            TRUE,                   // 默认选中，通常新客分析是重点
	            TRUE,                   // 激活状态，当前可用
	            "会员生命周期",         // 分组，属于生命周期管理
	            "new"                   // 业务代码，对应源系统字段值
	        },
	        // EXISTING - 现有/老会员
	        {
	            "Existing",             // 类型代码，现有会员的英文标识
	            "老客",                 // 类型显示名称
	            2,                      // 排序顺序
	            "在统计周期之前已有购买记录或历史沉淀的会员，代表品牌的留存资产",  // 类型描述
	            FALSE,                  // 非默认选项
	            TRUE,                   // 激活状态，当前可用
	            "会员生命周期",         // 分组，属于生命周期管理
	            "exists"              // 业务代码，对应源系统字段值
	        }
	    }
	)