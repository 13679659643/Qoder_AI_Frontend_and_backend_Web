createOrReplace

	table A_页面权限
		lineageTag: 8af9ebd5-1496-4e85-a57c-ddc533aa114e

		column 用户名
			lineageTag: 7050d95d-45e5-4e01-a034-60e609ab54b0
			summarizeBy: none
			isNameInferred
			sourceColumn: [用户名]

			annotation SummarizationSetBy = Automatic

		column 账号
			lineageTag: b3e2641c-c1b7-4707-a0e3-e56b57a13155
			summarizeBy: none
			isNameInferred
			sourceColumn: [账号]

			annotation SummarizationSetBy = Automatic

		column 邮箱
			lineageTag: 73a1c5ae-5771-43fa-8de7-a9f4ad4f42df
			summarizeBy: none
			isNameInferred
			sourceColumn: [邮箱]

			annotation SummarizationSetBy = Automatic

		column 页面权限
			lineageTag: 9461688b-bf53-42e4-8fc4-0aff4e44281b
			summarizeBy: none
			isNameInferred
			sourceColumn: [页面权限]

			annotation SummarizationSetBy = Automatic

		partition A_页面权限 = calculated
			mode: import
			source = ```
					
						-- ==============================================
						-- 计算表：A_页面权限
						-- 作用：解决报表中 "Cannot find table 'A_页面权限'" 的警告报错，
						--      根据 image.png 中的内容构建对应的表结构与数据。
						-- ==============================================
						DATATABLE(
						    "用户名", STRING,       -- 定义列：ABC用户名，数据类型为文本
						    "账号", STRING,         -- 定义列：ABC账号，数据类型为文本
						    "邮箱", STRING,         -- 定义列：ABC邮箱，数据类型为文本
						    "页面权限", STRING,     -- 定义列：ABC页面权限，数据类型为文本
						    {
						        -- 插入数据行
						        -- 根据提取的文本内容，"1" 推测为序号或ID，将 "BAOZUN\jm043195" 映射为账号，
						        -- "tao.gu_ext@baozun.com" 映射为邮箱，"RL_推广数据追踪" 映射为页面权限。
						        { "辜涛", "BAOZUN\jm043195", "tao.gu_ext@baozun.com", "RL_推广数据追踪" }
						    }
						)
					```

		annotation PBI_Id = 2a0d3afaaf0348409f81b9668e365a1f

