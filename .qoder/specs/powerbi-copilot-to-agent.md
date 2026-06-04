# powerbi_code_copilot 转换为 Qoder AI Agent 方案

## Context

当前 `powerbi_code_copilot/` 是一套结构化的 Markdown 提示词工程包，需要手动加载到 AI 助手中才能发挥作用。目标是将其转换为 Qoder 原生的 Skill + Subagent 架构，使其成为可通过 `/pbi` 命令触发的、具备自动上下文加载、命令路由和子 Agent 调度能力的真正 AI Agent 系统。

**用户需求**：全局级安装、统一入口 + 内部路由、支持 Qoder CLI 和 Cursor/VS Code、支持自然语言输入。

---

## 目标架构

```
用户输入: /pbi dax 写个销售同比  或  "帮我写个度量值"
                    │
    ┌───────────────▼───────────────────────────────┐
    │      /pbi SKILL（主编排器）                      │
    │      ~/.qoder/skills/pbi/SKILL.md              │
    │                                                 │
    │  - 意图路由（自然语言 → 命令映射）                 │
    │  - 上下文加载（rules/ + knowledge/）             │
    │  - 命令执行（/dax /pq /propose 等）              │
    │  - 后置钩子（version-tracker 自动记录变更）       │
    └──────┬──────────────┬──────────────┬────────────┘
           │              │              │
    ┌──────▼──────┐ ┌─────▼──────┐ ┌─────▼──────────┐
    │pbi-model-   │ │pbi-dax-    │ │pbi-perf-       │
    │reviewer     │ │reviewer    │ │reviewer        │
    │(Subagent)   │ │(Subagent)  │ │(Subagent)      │
    │只读审查      │ │只读审查    │ │只读诊断         │
    └─────────────┘ └────────────┘ └────────────────┘
```

---

## 目录结构

### 全局安装（~/.qoder/）

```
~/.qoder/
├── skills/
│   └── pbi/
│       ├── SKILL.md                          # 主 Skill 定义（核心）
│       └── assets/                           # 捆绑的规则和知识库
│           ├── rules/                        # 来自 powerbi_code_copilot/rules/
│           │   ├── dax-style.md
│           │   ├── modeling-standards.md
│           │   ├── visualization-standards.md
│           │   ├── security.md
│           │   └── domain-rules.md
│           ├── knowledge/                    # 来自 powerbi_code_copilot/knowledge/
│           │   ├── index.md
│           │   ├── dax-patterns.md
│           │   ├── power-query-patterns.md
│           │   ├── performance-tips.md
│           │   └── slicer-tips.md
│           └── templates/                    # 来自 powerbi_code_copilot/changes/templates/
│               ├── spec.md
│               ├── tasks.md
│               ├── validation-spec.md
│               └── log.md
│
├── agents/
│   ├── pbi-model-reviewer.md                # 子 Agent：模型合规审查
│   ├── pbi-dax-reviewer.md                  # 子 Agent：DAX 质量审查
│   └── pbi-perf-reviewer.md                 # 子 Agent：性能诊断
```

### 项目级（各 Power BI 项目自动生成）

```
<any-powerbi-project>/
├── rules/
│   └── project-context.md                   # /init 生成的项目上下文
├── changes/                                 # 变更管理工作区
│   └── <change-name>/
│       ├── spec.md / tasks.md / ...
└── changelog.md                             # version-tracker 输出
```

---

## 核心文件设计

### 1. SKILL.md（主 Skill）

SKILL.md 包含以下主要部分：

**a) 身份与核心原则**
- 从 copilot-prompt.md 适配：Spec 驱动哲学、回答框架、原子化任务原则
- 中文输出 + 英文技术术语

**b) 上下文加载协议（两级懒加载）**

| 层级 | 加载时机 | 内容 |
|------|---------|------|
| Tier 1 | 每次激活 | dax-style.md, security.md, knowledge/index.md, project-context.md（如有） |
| Tier 2 | 按命令按需加载 | 见下表 |

| 命令 | 额外加载 |
|------|---------|
| /dax | dax-patterns.md |
| /pq | power-query-patterns.md |
| /model | modeling-standards.md |
| /visual | visualization-standards.md, slicer-tips.md |
| /optimize | performance-tips.md |
| /propose | spec.md, tasks.md 模板 |
| /apply | tasks.md, validation-spec.md 模板 |
| /review | modeling-standards.md（传给 model-reviewer） |

**c) 意图路由表**
- 保留原有的自然语言 → 命令映射表
- 纯技术讨论跳过命令流程
- 歧义情况下先确认再执行

**d) 命令实现**
- /init, /dax, /pq, /propose, /apply, /model, /visual, /archive, 调试流程：Skill 内部直接执行
- /review：委托给 model-reviewer → dax-reviewer 子 Agent（顺序门控）
- /optimize：委托给 perf-reviewer 子 Agent

**e) Version-Tracker 后置钩子（内嵌逻辑）**
- 不单独做 Subagent（因为与主命令输出紧密耦合）
- 首次触发时询问 changelog 路径，会话内记住
- 使用 Qoder update_memory 做跨会话持久化

### 2. 三个 Subagent

| Subagent | 来源 | 职责 | 工具权限 |
|----------|------|------|---------|
| pbi-model-reviewer | agents/model-reviewer.md | Spec 合规 + 模型结构审查 | Read, Grep, Glob |
| pbi-dax-reviewer | agents/dax-reviewer.md | DAX 代码质量审查（含性能评估） | Read, Grep, Glob |
| pbi-perf-reviewer | agents/performance-reviewer.md | 四层性能诊断 | Read, Grep, Glob, Bash |

每个 subagent 文件中**内嵌关键规则**（因为 subagent 无法读取 Skill 的 assets），如 pbi-dax-reviewer 内嵌 dax-style.md 的核心规则。

---

## 关键设计决策

| 决策 | 选择 | 原因 |
|------|------|------|
| 单 Skill vs 多 Skill | **单 /pbi Skill** | 保持统一入口，内部路由处理子命令 |
| Reviewer 做 Subagent vs 内嵌 | **Subagent** | 审查需要上下文隔离，保证客观性 |
| Version-tracker 做 Subagent vs 内嵌 | **内嵌 Skill** | 与命令输出紧耦合，Subagent 会丢失执行上下文 |
| 规则/知识库打包 vs 项目本地 | **打包到 Skill assets** | 必须跨项目共享，项目级 context 仍保持本地 |
| 全量加载 vs 懒加载 | **两级懒加载** | 全量 40KB+ 浪费上下文窗口 |

---

## 实施步骤

### Phase 1: 基础（核心 Skill + /dax 命令）
1. 创建 `~/.qoder/skills/pbi/SKILL.md`（身份、原则、意图路由、/dax 实现、version-tracker）
2. 创建 `~/.qoder/skills/pbi/assets/` 并复制 rules/ 和 knowledge/ 文件
3. 测试：`/pbi dax 计算客户复购率`

### Phase 2: 完整命令集
4. 在 SKILL.md 中添加所有非审查命令：/init, /pq, /propose, /apply, /model, /visual, /archive
5. 复制剩余 knowledge 和 templates 到 assets/
6. 添加 Tier-2 按需加载逻辑

### Phase 3: 审查子 Agent
7. 创建 `~/.qoder/agents/pbi-model-reviewer.md`
8. 创建 `~/.qoder/agents/pbi-dax-reviewer.md`（内嵌 dax-style 核心规则）
9. 创建 `~/.qoder/agents/pbi-perf-reviewer.md`（内嵌 performance-tips 核心知识）
10. 在 SKILL.md 中添加 /review 和 /optimize 的 Subagent 调度协议

### Phase 4: 打磨与多环境
11. 自然语言路由优化（歧义处理、多命令序列）
12. Qoder Memory 集成（changelog 路径持久化）
13. 更新 powerbi_code_copilot/目录结构和设计说明

---

## 验证方案

1. **基础功能**：运行 `/pbi` 无参数，确认展示状态和命令菜单
2. **DAX 开发**：`/pbi dax 计算销售同比` → 验证输出格式、version-tracker 触发
3. **自然语言路由**：输入 "帮我写个度量值" → 验证自动映射到 /dax 并确认
4. **审查流程**：`/pbi review <变更名>` → 验证 model-reviewer 和 dax-reviewer 顺序执行
5. **性能诊断**：`/pbi optimize` → 验证 perf-reviewer 独立执行
6. **知识归档**：`/pbi archive` → 验证 knowledge 文件被正确更新
7. **跨项目**：在不同 Power BI 项目目录中测试，验证全局可用性

---

## 涉及的关键源文件

| 文件 | 作用 |
|------|------|
| `powerbi_code_copilot/agents/copilot-prompt.md` | SKILL.md 的主要素材来源 |
| `powerbi_code_copilot/agents/model-reviewer.md` | pbi-model-reviewer 素材 |
| `powerbi_code_copilot/agents/dax-reviewer.md` | pbi-dax-reviewer 素材 |
| `powerbi_code_copilot/agents/performance-reviewer.md` | pbi-perf-reviewer 素材 |
| `powerbi_code_copilot/agents/version-tracker.md` | version-tracker 内嵌逻辑素材 |
| `powerbi_code_copilot/rules/*.md` | 复制到 assets/rules/ |
| `powerbi_code_copilot/knowledge/*.md` | 复制到 assets/knowledge/ |
| `powerbi_code_copilot/changes/templates/*.md` | 复制到 assets/templates/ |
