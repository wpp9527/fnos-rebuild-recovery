# DevFlow - 最小人工介入的 AI 开发流水线

## 核心理念

**人工只做决策，AI 执行一切**

```
人工介入点（最少3次）：
  1. 定义需求（一句话 or 文档）     ← 30秒
  2. 审批架构设计（可选，可跳过）   ← 2分钟
  3. 最终验收（可选，可跳过）       ← 5分钟

AI 自动完成：
  - 需求分析 → 设计文档
  - 架构设计 → 技术方案
  - 代码实现 → 多模块并行
  - 自动测试 → 失败自动修复
  - 代码审查 → 质量把关
  - 部署打包 → 交付产物
```

## 减少介入的关键设计

### 1. 自动决策机制
- 遇到歧义？AI 根据上下文推断最优解
- 技术选型？用默认偏好（项目配置文件定义）
- 代码风格？自动遵循语言最佳实践
- **只有真正需要人类判断时才停下来**

### 2. 自动纠错循环
```
写代码 → 跑测试 → 失败？
  ↓
分析错误日志
  ↓
自动修复 → 重跑测试
  ↓
最多 N 轮（默认5轮）
  ↓
还是失败？记录到 blocked_reason，跳过继续下一个模块
```

### 3. 状态持久化（上下文无关）
```
每个阶段的输出写到文件：
  project/
    state.json          ← 当前进度（JSON）
    design.md           ← 需求分析
    architecture.md     ← 架构设计
    src/                ← 代码
    tests/              ← 测试
    logs/               ← 执行日志
    blocked.json        ← 阻塞记录
```

### 4. 智能重试
- 临时错误（网络、超时）→ 自动重试 3 次
- 代码错误 → 进入纠错循环
- 设计错误 → 记录并跳过，最后汇总报告
- **永不因为小问题停下来问人**

### 5. 最小化通知
- 只在以下情况通知：
  - 整个流程完成 ✅
  - 遇到真正的阻塞（需要人工决策）
  - 定时进度报告（可选，默认每小时一次）
- **不要每完成一个小步骤就通知**

## 流水线阶段

```
Phase 0: 解析需求（自动）
  输入: 用户的一句话需求
  输出: project/design.md

Phase 1: 架构设计（自动，可人工审批）
  输入: design.md
  输出: project/architecture.md + project/config.json

Phase 2: 代码实现（自动，并行执行）
  输入: architecture.md
  输出: project/src/

Phase 3: 测试验证（自动纠错）
  输入: src/
  输出: project/tests/ + test_report.md

Phase 4: 代码审查（自动）
  输入: src/ + tests/
  输出: project/review.md

Phase 5: 交付打包（自动）
  输入: 全部产物
  输出: project/dist/
```

## Agent 角色定义

| 角色 | 职责 | 工具 |
|------|------|------|
| PM Agent | 需求分析、用户故事 | file_write, web_search |
| Architect Agent | 架构设计、技术选型 | file_write, file_read |
| Developer Agent | 代码实现 | code_editor, terminal, file_write |
| Tester Agent | 测试编写和执行 | terminal, file_write |
| Reviewer Agent | 代码审查 | file_read, file_write |
| Orchestrator | 流程控制、状态管理 | 全部工具 |

## 配置文件

```yaml
# project/config.json
{
  "name": "my-project",
  "language": "python",          # 或 node/go/rust
  "framework": "fastapi",        # 默认框架
  "testing": "pytest",           # 测试框架
  "max_fix_rounds": 5,           # 最大纠错轮数
  "auto_approve_architecture": true,  # 跳过架构审批
  "notify_every_hour": false,    # 不要每小时通知
  "notify_on_complete": true,    # 完成时通知
  "parallel_agents": 3,          # 并行 agent 数
  "default_preferences": {       # 技术偏好（减少决策）
    "database": "sqlite",
    "cache": "none",
    "auth": "jwt",
    "api_style": "restful"
  }
}
```

## 与 OpenClaw 集成

```
OpenClaw 主 session
  ├── Cron Job（定时推进流水线）
  ├── sessions_spawn（子 agent 执行）
  ├── 文件系统（状态持久化）
  └── 消息通知（完成/阻塞时汇报）
```

## 效果预期

| 指标 | 传统开发 | DevFlow |
|------|----------|---------|
| 人工介入次数 | 持续 | **3-5 次** |
| 单次介入时间 | 不定 | **2-5 分钟** |
| 完成一个功能 | 几小时-几天 | **1-4 小时** |
| 代码质量 | 取决于人 | **自动审查+测试** |
