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

# 业务知识

（随实践积累补充）

# 技术约定

（随实践积累补充）

# 踩坑记录

（随实践积累补充）
