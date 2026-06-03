# DevFlow - 最小人工介入的 AI 开发流水线

## 核心理念

**你只负责说"要什么"，AI 负责"怎么做"。**

```
人工介入点（最少 3 次，每次 < 5 分钟）：
  1. 输入需求（一句话）          ← 30 秒
  2. 审批架构（可选，可跳过）    ← 2 分钟
  3. 验收结果（可选，可跳过）    ← 5 分钟

AI 自动完成（几个小时到十几小时）：
  - 需求分析 → 设计文档
  - 架构设计 → 技术方案
  - 代码实现 → 多模块
  - 自动测试 → 失败自动修复
  - 代码审查 → 质量把关
  - 部署打包 → 交付产物
```

## 快速开始

### 方式 1: 直接执行（推荐）

```bash
cd devflow
python run.py "开发一个 Flask REST API，支持用户 CRUD" --name user-api
```

### 方式 2: OpenClaw Cron（后台运行）

```python
# 在 OpenClaw 主 session 中
from devflow.src.openclaw_integration import generate_cron_job
job = generate_cron_job("user-api", "开发一个 Flask REST API", "./projects/user-api")
# 然后 cron(action=add, job=job)
```

### 方式 3: 分步执行

```python
from devflow.src.orchestrator import DevFlowOrchestrator

orch = DevFlowOrchestrator("./projects/my-app")
orch.run("开发一个简单的博客系统", "blog")
```

## 文件结构

```
devflow/
├── run.py                    # 入口脚本
├── config/
│   └── default.yaml          # 默认配置
├── src/
│   ├── state.py              # 状态持久化 + 提示词模板
│   ├── orchestrator.py       # 核心编排引擎
│   └── openclaw_integration.py  # OpenClaw 集成
├── docs/
│   └── ARCHITECTURE.md       # 架构文档
├── projects/                 # 生成的项目
│   └── {project-name}/
│       ├── state.json        # 项目状态
│       ├── design.md         # 设计文档
│       ├── architecture.md   # 架构文档
│       ├── src/              # 源代码
│       ├── tests/            # 测试代码
│       ├── docs/             # 文档
│       └── logs/             # 执行日志
└── tests/                    # DevFlow 自身的测试
```

## 如何减少人工介入

### 1. 自动决策
- 技术选型 → 用 config 中的 preferences 默认值
- 遇到歧义 → AI 根据上下文推断最优解
- 代码风格 → 遵循语言最佳实践

### 2. 自动纠错
```
写代码 → 跑测试 → 失败？
  ↓
分析错误 → 自动修复 → 重跑测试
  ↓
最多 5 轮 → 还是失败？跳过，最后汇总
```

### 3. 状态持久化
- 每个阶段输出写文件
- 下一个 agent 读文件继续
- 不依赖上下文记忆

### 4. 智能通知
- 只在完成/真正阻塞时通知
- 不要每个步骤都打扰你

## 配置说明

编辑 `config/default.yaml`：

```yaml
project:
  language: python          # 编程语言
  framework: fastapi        # 默认框架
  max_fix_rounds: 5         # 最大修复轮数
  auto_approve_architecture: true  # 跳过架构审批

preferences:
  database: sqlite          # 默认数据库
  cache: none               # 默认缓存
  auth: jwt                 # 默认认证
```

## 与 OpenClaw 集成

```
OpenClaw 主 session
  ├── cron job（定时推进）
  ├── sessions_spawn（子 agent 执行）
  ├── 文件系统（状态持久化）
  └── 消息通知（完成/阻塞时汇报）
```

## 效果

| 指标 | 传统开发 | DevFlow |
|------|----------|---------|
| 人工介入次数 | 持续 | 3-5 次 |
| 单次介入时间 | 不定 | 2-5 分钟 |
| 完成一个功能 | 几小时-几天 | 1-4 小时 |
| 代码质量 | 取决于人 | 自动审查+测试 |
