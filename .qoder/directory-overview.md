# .qoder 目录总览

> 生成时间：2026-06-04

## 目录结构

```
.qoder/
├── agents/                          # AI Agent 定义（PBI 审查子代理）
│   ├── pbi-dax-reviewer.md          # DAX 代码质量与性能审查 Agent
│   ├── pbi-model-reviewer.md        # 星型模型合规性与业务规则审查 Agent
│   └── pbi-perf-reviewer.md         # Power BI 性能诊断 Agent
│
├── repowiki/                        # 仓库知识库（RepoWiki 生成）
│   ├── knowledge/zh/                # 知识卡片（精简摘要）
│   │   ├── _index.yaml              # 知识库索引
│   │   ├── AI 编码协作规范与流程引擎/
│   │   │   ├── _module.yaml
│   │   │   ├── 概述.md
│   │   │   ├── 架构设计.md
│   │   │   ├── 技术栈.md
│   │   │   └── 编码规范.md
│   │   ├── Power BI 智能协作与规范治理/
│   │   │   ├── _module.yaml
│   │   │   ├── 概述.md
│   │   │   ├── 架构设计.md
│   │   │   └── 编码规范.md
│   │   ├── QuickBI 门店分析与 ClickHouse 日期范围生成/
│   │   │   ├── _module.yaml
│   │   │   ├── 概述.md
│   │   │   ├── 架构设计.md
│   │   │   ├── 技术栈.md
│   │   │   └── 编码规范.md
│   │   ├── RL E2E 流量运营分析看板/
│   │   │   ├── _module.yaml
│   │   │   ├── 概述.md
│   │   │   ├── 架构设计.md
│   │   │   ├── 技术栈.md
│   │   │   └── 编码规范.md
│   │   └── 多域智能协作与规范治理平台/
│   │       ├── _module.yaml
│   │       ├── 概述.md
│   │       ├── 架构设计.md
│   │       └── 编码规范.md
│   └── zh/                          # 仓库文档（完整内容）
│       ├── content/
│       │   ├── 快速开始.md
│       │   ├── 知识库和最佳实践.md
│       │   ├── Power BI优化模块/
│       │   │   ├── DAX模式识别与最佳实践.md
│       │   │   ├── DAX表达式审查.md
│       │   │   ├── Power BI优化模块.md
│       │   │   ├── Power BI规则与标准.md
│       │   │   ├── 性能评估与优化.md
│       │   │   └── 数据模型验证.md
│       │   ├── SQL性能优化模块/
│       │   │   ├── ClickHouse查询优化.md
│       │   │   ├── SQL性能优化模块.md
│       │   │   └── 日期范围生成与处理.md
│       │   ├── 代码质量控制模块/
│       │   │   ├── 代码规范和规则定义.md
│       │   │   ├── 代码质量审查.md
│       │   │   ├── 代码质量控制模块.md
│       │   │   ├── 变更管理和模板系统.md
│       │   │   └── 规范符合性检查.md
│       │   ├── 开发者指南/
│       │   │   ├── API参考文档.md
│       │   │   ├── 开发者指南.md
│       │   │   ├── 环境配置.md
│       │   │   ├── 贡献指南.md
│       │   │   └── 部署运维.md
│       │   ├── 营销效果分析模块/
│       │   │   ├── KPI分解矩阵分析.md
│       │   │   ├── 平台维度分析.md
│       │   │   ├── 数据演示和样例.md
│       │   │   ├── 流量监控仪表板.md
│       │   │   └── 营销效果分析模块.md
│       │   └── 项目概述/
│       │       ├── 业务价值.md
│       │       ├── 技术架构.md
│       │       ├── 目标用户群体.md
│       │       ├── 项目介绍.md
│       │       ├── 项目概述.md
│       │       └── 核心模块概览/
│       │           ├── 核心模块概览.md
│       │           ├── Power BI优化模块/
│       │           │   ├── DAX模式与知识库.md
│       │           │   ├── DAX表达式审查.md
│       │           │   ├── Power BI优化模块.md
│       │           │   ├── 性能评估.md
│       │           │   └── 数据模型验证.md
│       │           ├── SQL性能优化模块/
│       │           │   ├── ClickHouse查询优化.md
│       │           │   ├── SQL优化最佳实践.md
│       │           │   ├── SQL性能优化模块.md
│       │           │   └── 日期范围生成与处理.md
│       │           ├── 代码质量控制模块/
│       │           │   ├── 代码规则系统.md
│       │           │   ├── 代码质量审查器.md
│       │           │   ├── 代码质量控制模块.md
│       │           │   ├── 变更管理模板.md
│       │           │   ├── 知识库系统.md
│       │           │   └── 规格审查器.md
│       │           └── 营销效果分析模块/
│       │               ├── KPI分解矩阵分析.md
│       │               ├── 平台维度分析.md
│       │               ├── 数据演示和样例.md
│       │               ├── 流量监控仪表板.md
│       │               └── 营销效果分析模块.md
│       └── meta/
│           └── repowiki-metadata.json    # 仓库元数据（273KB）
│
├── skills/                          # Qoder Skill 定义
│   └── pbi/                         # Power BI Copilot Skill
│       ├── SKILL.md                 # Skill 入口（12KB，意图路由 + 工作流）
│       └── assets/
│           ├── knowledge/           # 知识支撑
│           │   ├── index.md
│           │   ├── dax-patterns.md         # DAX 模式库
│           │   ├── performance-tips.md     # 性能优化技巧
│           │   ├── power-query-patterns.md # Power Query 模式
│           │   └── slicer-tips.md          # 切片器配置技巧
│           ├── rules/               # 规范约束
│           │   ├── dax-style.md            # DAX 编码风格
│           │   ├── domain-rules.md         # 业务域规则
│           │   ├── modeling-standards.md   # 建模标准
│           │   ├── security.md             # 安全红线
│           │   └── visualization-standards.md  # 可视化规范
│           └── templates/           # 变更模板
│               ├── log.md                  # 变更日志模板
│               ├── project-context-template.md  # 项目上下文模板
│               ├── spec.md                 # 需求规格模板
│               ├── tasks.md                # 任务拆解模板
│               └── validation-spec.md      # 验证规格模板
│
└── specs/                           # 需求规格文档
    └── powerbi-copilot-to-agent.md  # PBI Copilot 迁移至 Agent 的 Spec
```

## 分层说明

| 目录 | 职责 | 核心原则 |
|------|------|----------|
| `agents/` | 专业化审查子代理 | 分阶段阻断式审查：DAX质量 → 模型合规 → 性能诊断 |
| `repowiki/knowledge/` | 知识卡片（精简摘要） | 每个模块 4 个卡片：概述、架构设计、技术栈、编码规范 |
| `repowiki/zh/content/` | 仓库文档（完整内容） | 5 大模块 + 开发者指南 + 项目概述 |
| `skills/pbi/` | PBI Copilot Skill | Spec 驱动（No Spec, No Change），意图路由 + 多维审查 |
| `specs/` | 需求规格 | 所有模型/报表修改必须先有对应 Spec |
