# 性能优化知识库

> Power BI 性能优化的核心知识和实践经验。

## 1. 查询折叠（Query Folding）

### 核心概念
查询折叠是指 Power Query 将 M 代码转换为原生数据源查询（如 SQL）在数据源端执行的过程。

### 支持折叠的操作
- Table.SelectRows（→ WHERE）
- Table.SelectColumns（→ SELECT）
- Table.Sort（→ ORDER BY）
- Table.Group（→ GROUP BY）
- Table.Join（→ JOIN）
- Table.FirstN / Table.Skip（→ TOP / OFFSET）

### 阻断折叠的操作
- Table.AddColumn（带自定义函数）
- Table.TransformColumns（带自定义函数）
- Table.Pivot / Table.Unpivot
- 任何使用 try...otherwise 的操作
- 引用其他查询的结果

### 验证方法
在 Power Query 编辑器中，右键步骤 → "查看本机查询"：
- 能看到 SQL → 折叠成功 ✅
- 显示"此步骤不支持查看本机查询" → 折叠中断 ❌

### 最佳实践
- 可折叠的步骤放在前面，不可折叠的步骤放在后面
- 筛选和列选择尽早执行
- 大型表的聚合尽量在数据源端完成

---

## 2. 数据模型优化

### 减小模型体积
- 移除未使用的列（最有效的优化手段）
- 减少文本列的基数（考虑编码或分类）
- 使用整数替代文本键（关系列）
- 关闭自动日期/时间表
- 大型文本描述字段：仅在需要搜索时保留

### 基数影响
```
低基数列（如性别：男/女）      → 压缩率高，性能好
中基数列（如城市：数百个值）    → 正常
高基数列（如订单号：百万级）    → 压缩率低，占用大量内存
超高基数列（如自由文本描述）    → 严重影响性能，应评估是否需要
```

### 存储模式选择
| 模式 | 适用场景 | 优点 | 缺点 |
|------|---------|------|------|
| Import | 默认选择 | 最快查询性能 | 需要刷新，占用内存 |
| DirectQuery | 实时数据需求 | 数据始终最新 | 查询性能受数据源影响 |
| Dual | 维度表 + DQ 事实表 | 平衡性能与实时性 | 配置复杂 |
| 聚合表 | 大型事实表 | 高级别查询用缓存 | 需要设计聚合粒度 |

---

## 3. DAX 性能优化

### 高频优化技巧

#### 使用 VAR 缓存重复计算
```dax
// ❌ 差 — 重复计算
Bad Measure = 
    IF(
        [Total Sales] > 1000,
        [Total Sales] * 0.1,
        [Total Sales] * 0.05
    )

// ✅ 好 — 使用 VAR
Good Measure = 
    VAR __Sales = [Total Sales]
    RETURN
        IF(__Sales > 1000, __Sales * 0.1, __Sales * 0.05)
```

#### 减少 CALCULATE 筛选器的计算量
```dax
// ❌ 差 — FILTER 扫描全表
Bad = CALCULATE([Sales], FILTER(ALL(Product), Product[Color] = "Red"))

// ✅ 好 — 直接使用列筛选
Good = CALCULATE([Sales], Product[Color] = "Red")

// ✅ 好 — 使用 REMOVEFILTERS 替代 ALL
Better = CALCULATE([Sales], REMOVEFILTERS(Product[Color]), Product[Color] = "Red")
```

#### 避免不必要的迭代
```dax
// ❌ 差 — 不必要的迭代
Bad = SUMX(Sales, Sales[Quantity] * Sales[UnitPrice])

// ✅ 好 — 如果已有预计算列
Good = SUM(Sales[LineTotal])

// ⚠️ 迭代函数适合的场景：需要行级上下文的复杂计算
```

### 性能分析工具
- **DAX Studio**：分析 DAX 查询执行计划和耗时
- **Performance Analyzer**：Power BI Desktop 内置，分析视觉对象渲染耗时
- **VertiPaq Analyzer**：分析模型内存占用和列压缩效率
- **ALM Toolkit**：比较和部署模型变更

---

## 4. 可视化层性能

### 单页性能控制
- 视觉对象数量 ≤ 8
- 避免高基数切片器（如日期精确到天的切片器）
- 矩阵/表格限制行数（使用 Top N 筛选）
- 大数据量表格使用分页报表替代

### 交互性能
- 非必要的交叉筛选关闭
- 复杂页面考虑禁用视觉对象间的交互
- 工具提示页面保持简洁

---

## 5. 刷新性能

### 刷新优化策略
- 配置增量刷新（大型事实表）
- 错开多个数据集的刷新时间
- 减少参与刷新的查询数量（移除未使用的查询）
- Power Query 步骤优化（减少转换步骤）
- 使用数据流（Dataflow）预处理共享数据

### 监控指标
- 刷新耗时趋势
- 各表刷新耗时占比
- 刷新失败率和原因
