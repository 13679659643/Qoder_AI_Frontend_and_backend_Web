	WITH 
	-- 提取满足平台条件的去重 Season, Brand, Category 组合作为基础数据
	Base_Data AS (
	    SELECT DISTINCT 
	        season, 
	        brand, 
	        category
	    FROM `indep_rl_ads`.a05_e2e_paid_media_summary_d
	    WHERE platform IN ('JD', 'TM', 'RLE', 'DY')
	),
	-- 将6种Scenario_Type的分组数据通过UNION ALL合并
	Unioned_Data AS (
	    -- 1. Brand->Category->Season
	    SELECT 
	        'Brand->Category->Season' AS Scenario_Type, 
	        1 AS Scenario_Sort,                          
	        'Toatl' AS `Toatl`,                            
	        brand AS `Level 1`,                          
	        category AS `Level 2`,                       
	        season AS `Level 3`                          
	    FROM Base_Data
	    UNION ALL
	    -- 2. Brand->Season->Category
	    SELECT 
	        'Brand->Season->Category' AS Scenario_Type,  
	        2 AS Scenario_Sort,                          
	        'Toatl' AS `Toatl`,                            
	        brand AS `Level 1`,                          
	        season AS `Level 2`,                         
	        category AS `Level 3`                        
	    FROM Base_Data
	    UNION ALL
	    -- 3. Category->Brand->Season
	    SELECT 
	        'Category->Brand->Season' AS Scenario_Type,  
	        3 AS Scenario_Sort,                          
	        'Toatl' AS `Toatl`,                            
	        category AS `Level 1`,                       
	        brand AS `Level 2`,                          
	        season AS `Level 3`                          
	    FROM Base_Data
	    UNION ALL
	    -- 4. Category->Season->Brand
	    SELECT 
	        'Category->Season->Brand' AS Scenario_Type,  
	        4 AS Scenario_Sort,                          
	        'Toatl' AS `Toatl`,                            
	        category AS `Level 1`,                       
	        season AS `Level 2`,                         
	        brand AS `Level 3`                           
	    FROM Base_Data
	    UNION ALL
	    -- 5. Season->Brand->Category
	    SELECT 
	        'Season->Brand->Category' AS Scenario_Type,  
	        5 AS Scenario_Sort,                          
	        'Toatl' AS `Toatl`,                            
	        season AS `Level 1`,                         
	        brand AS `Level 2`,                          
	        category AS `Level 3`                        
	    FROM Base_Data
	    UNION ALL
	    -- 6. Season->Category->Brand
	    SELECT 
	        'Season->Category->Brand' AS Scenario_Type,  
	        6 AS Scenario_Sort,                          
	        'Toatl' AS `Toatl`,                            
	        season AS `Level 1`,                         
	        category AS `Level 2`,                       
	        brand AS `Level 3`                           
	    FROM Base_Data
	),
	-- 使用窗口函数按 Scenario_Type 分组，对 Level 1/2/3 按英文字符顺序进行升序连续排名
	Ranked_Data AS (
	    SELECT 
	        Scenario_Type,
	        Scenario_Sort,
	        `Toatl`,
	        `Level 1`,
	        `Level 2`,
	        `Level 3`,
	        -- Level 1在当前Scenario_Type分组下的英文字符排序值
	        DENSE_RANK() OVER (PARTITION BY Scenario_Type ORDER BY `Level 1`) AS L1_Sort,
	        -- Level 2在当前Scenario_Type及Level 1下的英文字符排序值
	        DENSE_RANK() OVER (PARTITION BY Scenario_Type, `Level 1` ORDER BY `Level 2`) AS L2_Sort,
	        -- Level 3在当前Scenario_Type及Level 1, Level 2下的英文字符排序值
	        DENSE_RANK() OVER (PARTITION BY Scenario_Type, `Level 1`, `Level 2` ORDER BY `Level 3`) AS L3_Sort
	    FROM Unioned_Data
	)
	-- 最终输出计算 ID_Sort 字段并按照指定规则排序
	SELECT 
	    Scenario_Type,                                                              -- 排列组合方式描述
	    Scenario_Sort,                                                              -- 排序编号
	    `Toatl`,                                                                    -- 收缩：Total
	    `Level 1`,                                                                  -- 第一层维度
	    `Level 2`,                                                                  -- 第二层维度
	    `Level 3`,                                                                  -- 第三层维度
	    -- ID_Sort 计算逻辑：
	    -- 公式为：Scenario_Sort * 1000000 + L1_Sort * 100000 + L2_Sort * 10000 + L3_Sort
	    CAST(Scenario_Sort * 1000000 + L1_Sort * 100000 + L2_Sort * 10000 + L3_Sort AS INT) AS ID_Sort 
	FROM Ranked_Data
	-- 按照指定的排序编号以及各维度字段进行排序输出
	ORDER BY 
	    Scenario_Sort, 
	    `Toatl`,
	    `Level 1`, 
	    `Level 2`, 
	    `Level 3`;