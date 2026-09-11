let
    源 = Odbc.Query("dsn=bytehouse_rl", "
    	WITH detail_data AS (
	    -- 动态抽取明细渠道数据，过滤掉空值与总计类型
	    SELECT
	        d.platform AS Platform,
	        CASE d.platform WHEN 'TM' THEN 1 WHEN 'JD' THEN 2 END AS Platform_Sort,
	        d.channel AS Channel,
	        -- 动态生成 Channel_Sort：按 channel_type 分组排序，明细步长为 10
	        CASE 
	            -- TM 排序逻辑：RTB(10起), 品销宝(510起), JCGP(1010起)
	            WHEN d.platform = 'TM' AND d.channel_type = 'RTB'      THEN 10 + (ROW_NUMBER() OVER (PARTITION BY d.platform, d.channel_type ORDER BY d.channel) - 1) * 10
	            WHEN d.platform = 'TM' AND d.channel_type = '品销宝'    THEN 510 + (ROW_NUMBER() OVER (PARTITION BY d.platform, d.channel_type ORDER BY d.channel) - 1) * 10
	            WHEN d.platform = 'TM' AND d.channel_type = 'JCGP'     THEN 1010 + (ROW_NUMBER() OVER (PARTITION BY d.platform, d.channel_type ORDER BY d.channel) - 1) * 10
	            -- JD 排序逻辑：RTB(10起), Brandzone(510起), JCGP(1010起)
	            WHEN d.platform = 'JD' AND d.channel_type = 'RTB'      THEN 10 + (ROW_NUMBER() OVER (PARTITION BY d.platform, d.channel_type ORDER BY d.channel) - 1) * 10
	            WHEN d.platform = 'JD' AND d.channel_type IN ('Brandzone','Branzone') THEN 510 + (ROW_NUMBER() OVER (PARTITION BY d.platform, d.channel_type ORDER BY d.channel) - 1) * 10
	            WHEN d.platform = 'JD' AND d.channel_type = 'JCGP'     THEN 1010 + (ROW_NUMBER() OVER (PARTITION BY d.platform, d.channel_type ORDER BY d.channel) - 1) * 10
	            ELSE 99999 -- 兜底未识别类型
	        END AS Channel_Sort,
	        d.channel AS Channel_Label,
	        NULL AS Channel_Description,
	        'DETAIL' AS Channel_Type,
	        CONCAT(d.platform, '_', d.channel) AS Channel_ID,
	        CONCAT(d.platform, '_', d.channel) AS Summary_Scope, -- 明细行的 Scope 为自身
	        -- 动态匹配父级 SUMMARY 行
	        CASE 
	            -- TM 归属逻辑
	            WHEN d.platform = 'TM' AND d.channel_type = 'RTB'      THEN 'TM_RTB Total'
	            WHEN d.platform = 'TM' AND d.channel_type = '品销宝'    THEN 'TM_品销宝 Total'
	            WHEN d.platform = 'TM' AND d.channel_type = 'JCGP'     THEN 'TM_JCGP Total'
	            -- JD 归属逻辑
	            WHEN d.platform = 'JD' AND d.channel_type = 'RTB'      THEN 'JD_RTB Total'
	            WHEN d.platform = 'JD' AND d.channel_type IN ('Brandzone','Branzone') THEN 'JD_Brandzone'
	            WHEN d.platform = 'JD' AND d.channel_type = 'JCGP'     THEN 'JD_JCGP Total'
	            ELSE 'UNKNOWN' 
	        END AS Parent_Channel_ID
	    FROM (
	        SELECT DISTINCT 
	            platform, 
	            channel, 
	            channel_type 
	        FROM `indep_rl_ads`.a05_e2e_paid_media_channel_data_d 
	        WHERE platform IN ('JD', 'TM') 
	          AND channel_type IS NOT NULL 
	          AND channel_type != ''
	          AND channel_type IN ('JCGP', 'RTB', '品销宝', 'Brandzone','Branzone')
	    ) d
	),
	dynamic_scope AS (
	    -- 【新增】基于明细行的 Channel_ID 和 Parent_Channel_ID，按层级动态拼接 Summary_Scope
	    -- 适配 ClickHouse：使用 arrayStringConcat(groupUniqArray(...), '|') 进行去重并拼接
	    SELECT 'TM_RTB Total' AS Channel_ID, arrayStringConcat(groupUniqArray(Channel_ID), '|') AS Summary_Scope 
	    FROM detail_data WHERE Platform = 'TM' AND Parent_Channel_ID = 'TM_RTB Total'
	    UNION ALL
	    SELECT 'TM_品销宝 Total', arrayStringConcat(groupUniqArray(Channel_ID), '|') 
	    FROM detail_data WHERE Platform = 'TM' AND Parent_Channel_ID = 'TM_品销宝 Total'
	    UNION ALL
	    -- TM_JCGP Total 需要包含： JCGP明细
	    SELECT 'TM_JCGP Total', arrayStringConcat(groupUniqArray(Channel_ID), '|') 
	    FROM detail_data WHERE Platform = 'TM' AND Parent_Channel_ID IN ('TM_JCGP Total')
	    UNION ALL
	    SELECT 'TM_Total', arrayStringConcat(groupUniqArray(Channel_ID), '|') 
	    FROM detail_data WHERE Platform = 'TM'
	    UNION ALL
	    -- TM_Total 不含JCGP（仅含RTB）
	    SELECT 'TM_Total 不含JCGP', arrayStringConcat(groupUniqArray(Channel_ID), '|') 
	    FROM detail_data WHERE Platform = 'TM' AND Parent_Channel_ID NOT IN ('TM_JCGP Total')
	    UNION ALL
	    SELECT 'JD_RTB Total', arrayStringConcat(groupUniqArray(Channel_ID), '|') 
	    FROM detail_data WHERE Platform = 'JD' AND Parent_Channel_ID = 'JD_RTB Total'
	    UNION ALL
	    -- 包含“京选店铺”
	    SELECT 'JD_RTB Total + 京选店铺', arrayStringConcat(groupUniqArray(Channel_ID), '|') 
	    FROM detail_data WHERE Platform = 'JD' AND Parent_Channel_ID IN ('JD_RTB Total') OR  Channel_ID = 'JD_京选店铺'
	    UNION ALL
	    SELECT 'JD_Brandzone', arrayStringConcat(groupUniqArray(Channel_ID), '|') 
	    FROM detail_data WHERE Platform = 'JD' AND Parent_Channel_ID = 'JD_Brandzone'
	    UNION ALL
	    SELECT 'JD_JCGP Total', arrayStringConcat(groupUniqArray(Channel_ID), '|') 
	    FROM detail_data WHERE Platform = 'JD' AND Parent_Channel_ID = 'JD_JCGP Total'
	    UNION ALL
	    SELECT 'JD_Total', arrayStringConcat(groupUniqArray(Channel_ID), '|') 
	    FROM detail_data WHERE Platform = 'JD'
	    UNION ALL
	    -- JD_Total 不含JCGP（即剔除JCGP，保留 RTB + Brandzone）
	    SELECT 'JD_Total 不含JCGP', arrayStringConcat(groupUniqArray(Channel_ID), '|') 
	    FROM detail_data WHERE Platform = 'JD' AND Parent_Channel_ID NOT IN ('JD_JCGP Total', 'UNKNOWN')
	),
	summary_base AS (
	    -- 写死的 SUMMARY 汇总行基础属性（Channel_Sort 固定为 500 的倍数，Summary_Scope 置空待动态匹配）
	    SELECT 'TM' AS Platform, 1 AS Platform_Sort, 'RTB Total' AS Channel, 500 AS Channel_Sort, 'RTB Total' AS Channel_Label, 
	           'TM平台-RTB合计：直通车 + 引力魔方 + 全站推/万象台 + 超级短视频 之和' AS Channel_Description, 'SUMMARY' AS Channel_Type, 
	           'TM_RTB Total' AS Channel_ID, NULL AS Summary_Scope, 'TM_RTB Total' AS Parent_Channel_ID
	    UNION ALL SELECT 'TM', 1, '品销宝 Total', 1000, '品销宝 Total', 'TM平台-品销宝合计：品牌专区相关渠道汇总（品销宝产品线整体）', 'SUMMARY', 'TM_品销宝 Total', NULL, 'TM_品销宝 Total'
	    UNION ALL SELECT 'TM', 1, 'JCGP Total', 1500, 'JCGP Total', 'TM平台-JCGP合计：品销宝 Total + 品牌特秀（品牌类渠道整体汇总）', 'SUMMARY', 'TM_JCGP Total', NULL, 'TM_JCGP Total'
	    UNION ALL SELECT 'TM', 1, 'Total', 2000, 'Total', 'TM平台-全渠道合计：RTB Total + JCGP Total，即 TM 平台所有渠道总和', 'SUMMARY', 'TM_Total', NULL, 'TM_Total'
	    UNION ALL SELECT 'TM', 1, 'Total 不含JCGP', 2500, 'Total 不含JCGP', 'TM平台-全渠道合计（剔除JCGP）：Total - JCGP Total，即纯效果类渠道（RTB类）合计', 'SUMMARY', 'TM_Total 不含JCGP', NULL, 'TM_Total 不含JCGP'
	    UNION ALL SELECT 'JD', 2, 'RTB Total', 500, 'RTB Total ', 'JD平台-RTB合计：快车 + 触点 + 海投 + 直投 之和', 'SUMMARY', 'JD_RTB Total', NULL, 'JD_RTB Total'
	    UNION ALL SELECT 'JD', 2, 'RTB Total + 京选店铺', 501, 'RTB Total + 京选店铺', 'JD平台-RTB合计（含京选店铺）：RTB Total + 京选店铺，含京选店铺口径的效果类汇总', 'SUMMARY', 'JD_RTB Total + 京选店铺', NULL, 'JD_RTB Total + 京选店铺'
	    UNION ALL SELECT 'JD', 2, 'Brandzone', 1000, 'Brandzone', 'JD平台-Brandzone汇总：所有Brandzone类型的品牌展示广告渠道汇总', 'SUMMARY', 'JD_Brandzone', NULL, 'JD_Brandzone'
	    UNION ALL SELECT 'JD', 2, 'JCGP Total', 1500, 'JCGP Total ', 'JD平台-JCGP合计：品牌类渠道整体汇总（不含Brandzone）', 'SUMMARY', 'JD_JCGP Total', NULL, 'JD_JCGP Total'
	    UNION ALL SELECT 'JD', 2, 'Total', 2500, 'Total ', 'JD平台-全渠道合计：RTB Total + Brandzone + JCGP Total，即 JD 平台所有渠道总和', 'SUMMARY', 'JD_Total', NULL, 'JD_Total'
	    UNION ALL SELECT 'JD', 2, 'Total 不含JCGP', 3000, 'Total 不含JCGP ', 'JD平台-全渠道合计（剔除JCGP）：Total - JCGP Total，纯效果类渠道（RTB类）合计', 'SUMMARY', 'JD_Total 不含JCGP', NULL, 'JD_Total 不含JCGP'
	),
	summary_data AS (
	    -- 将汇总行基础属性与动态拼接的 Scope 关联
	    SELECT 
	        s.Platform, 
	        s.Platform_Sort, 
	        s.Channel, 
	        s.Channel_Sort, 
	        s.Channel_Label, 
	        s.Channel_Description, 
	        s.Channel_Type, 
	        s.Channel_ID, 
	        COALESCE(d.Summary_Scope, '') AS Summary_Scope, 
	        s.Parent_Channel_ID
	    FROM summary_base s
	    LEFT JOIN dynamic_scope d ON s.Channel_ID = d.Channel_ID
	)
	-- 最终合并输出并打序号
	SELECT 
	    ROW_NUMBER() OVER (ORDER BY Platform_Sort, Channel_Sort) AS Channel_PK,
	    Platform,
	    Platform_Sort,
	    Channel,
	     IF(Platform = 'TM',Channel_Sort,Channel_Sort*10) AS Channel_Sort,
		--  Channel_Label,
	    IF(Platform = 'TM',Channel_Label,CONCAT(Channel_Label,CHAR(8203))) AS Channel_Label,
	    Channel_Description,
	    Channel_Type,
	    Channel_ID,
	    Summary_Scope,
	    IF(Platform = 'TM','TM_Total','JD_Total') AS Parent_Channel_ID
	FROM (
	    SELECT * FROM detail_data
	    UNION ALL
	    SELECT * FROM summary_data
	) AS dim_channel_config
	ORDER BY Platform_Sort, Channel_Sort
	;
    ")
in
    源