# 知识索引

> Power BI 领域知识的轻量索引。每条用一句话说清核心逻辑。
> 格式：- **触发关键词**: 一句话核心逻辑 → `相关度量值/表名`（可选）

# DAX 模式库

> 详见 dax-patterns.md

- **累计求和**: CALCULATE + 日期筛选器实现 Running Total → 见 dax-patterns.md §1
- **同比环比**: 时间智能函数 SAMEPERIODLASTYEAR / DATEADD → 见 dax-patterns.md §2
- **动态 TopN**: TOPN + RANKX 组合实现动态排名 → 见 dax-patterns.md §3
- **ABC 分析**: 帕累托分析的标准 DAX 模式 → 见 dax-patterns.md §4

# Power Query 模式库

> 详见 power-query-patterns.md

- **增量加载**: 参数化查询 + 查询折叠实现增量数据加载 → 见 power-query-patterns.md §1
- **动态列**: List.Transform + Table.FromColumns 实现动态列处理 → 见 power-query-patterns.md §2

# 性能优化技巧

> 详见 performance-tips.md

# 切片器知识库

> 详见 slicer-tips.md

- **参数表规范**: DATATABLE 构建断开维度表的通用字段模板（必选/可选字段）→ 见 slicer-tips.md §1
- **平台切片器**: Slicer_Platform_Selection 完整示例，Platform_ID 用于 SELECTEDVALUE 匹配 → 见 slicer-tips.md §2
- **断开维度列配置**: DIM_ColMetric_Overview 内嵌格式类型、颜色、汇率标记，驱动矩阵多列逻辑 → 见 slicer-tips.md §3
- **格式类型清单**: 所有 Format Type 字符串定义（integer / percent / currency / delta_pct / delta_pt / delta_bp 等）→ 见 slicer-tips.md §4
- **SELECTEDVALUE 读取模式**: SWITCH 格式化分支模板 + 条件颜色度量值标准写法 → 见 slicer-tips.md §5
- **切片器最佳实践**: 命名规范（Slicer\_ / DIM\_ 前缀）、单选/多选配置、默认值处理 → 见 slicer-tips.md §6
- **按列排序函数依赖**: 被排序列→排序列必须多对一（每个值一个排序号，一个排序号可给多个值）；细排粗可以、粗排细报错；排序号按指标全局统一，不按分组压缩编号；附自检 DAX → 见 slicer-tips.md §7，规范见 rules/modeling-standards.md §6

# 业务知识

（随实践积累补充）

# 技术约定

（随实践积累补充）

# 踩坑记录

- **ColType 按 ColName_Sort 排序失败**: TTL 组 9 列、渠道组 5 列分别编号，TAR ACH% / MTD TAR Progress / YTD TAR Progress 各对应两个排序号 → 统一为 700/800/900，空档位不补 → 见 slicer-tips.md §7
