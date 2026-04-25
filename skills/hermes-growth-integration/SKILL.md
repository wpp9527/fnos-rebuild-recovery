---
name: hermes-growth-integration
description: 整合 Hermes Agent 成长机制到 OpenClaw — 技能提取、轨迹分析、元学习反馈。当需要自我改进、技能自动提取、跨会话学习时触发。
version: 1.0.0
author: OpenClaw
license: MIT
metadata:
  hermes:
    tags: [growth, meta-learning, skill-extraction, hermes-integration]
    related_skills: [self-improving-agent, proactive-agent, context-compaction]
---

# Hermes Growth Integration

将 Hermes Agent 的成长机制整合到 OpenClaw，实现：

1. **技能自动提取** — 从成功任务中提取可复用过程
2. **轨迹分析** — 分析会话轨迹，发现改进点
3. **元学习反馈** — 持续优化 agent 行为

## 架构对齐

```
Hermes 成长机制               OpenClaw 对应
─────────────────            ──────────────────
skill_extraction        →    self-improving-agent
trajectory_saving       →    session-logs skill
context_compressor      →    context-compaction
memory_backends         →    MEMORY.md + memory/
```

## 使用方式

### 1. 提取技能（从成功任务）

```bash
# 手动触发技能提取
/skill-extract --from-last-session

# 输出: skills/extracted/YYYY-MM-DD-task-name.md
```

### 2. 分析轨迹

```bash
# 分析最近的会话轨迹
/trajectory-analyze --days 7

# 输出: 改进建议、常见错误、效率指标
```

### 3. 元学习反馈

```bash
# 查看成长指标
/growth-metrics

# 输出: 技能增长、错误减少、效率提升
```

## 与 Hermes 本地实例协作

本地 Hermes Agent 位于：
- 安装: `/opt/fnos-media/services/hermes-agent/`
- 配置: `~/.hermes/config.yaml`
- 技能: `~/.hermes/skills/`
- 服务: `hermes-gateway.service` (运行中)

### 技能共享

```bash
# Hermes 技能引用
ls references/hermes-agent/hermes-skills/

# 可用技能类别
autonomous-ai-agents/  # 包含 hermes-agent 技能
creative/              # 创意工具
devops/               # DevOps 工具
github/               # GitHub 集成
```

### 成长机制对比

| 机制 | Hermes | OpenClaw | 整合方式 |
|------|--------|----------|---------|
| 技能提取 | 自动 | 手动触发 | 复用 Hermes 逻辑 |
| 轨迹保存 | trajectory.py | session-logs | 格式转换 |
| 记忆后端 | SQLite FTS5 | MEMORY.md | 双向同步 |
| 元学习 | MetaClaw 论文 | self-improving | 增强 |

## 实施步骤

### Phase 1: 技能互操作 ✅
- [x] 创建 Hermes 技能引用链接
- [x] 创建统一架构配置
- [ ] 实现 Hermes 技能导入脚本

### Phase 2: 记忆同步
- [ ] 设计 MEMORY.md ↔ SQLite 同步
- [ ] 实现增量同步脚本
- [ ] 添加冲突解决机制

### Phase 3: 元学习增强
- [ ] 分析 MetaClaw 论文实现细节
- [ ] 设计元学习反馈循环
- [ ] 集成到 proactive-agent

## 配置

```yaml
# state/integration/hermes-bridge.yaml
integration:
  skill_sharing: true
  memory_sync: false  # 需要显式同步
  session_bridge: false  # 格式不同

growth_mechanisms:
  openclaw:
    - self-improving-agent
    - proactive-agent
    - context-compaction
  
  hermes:
    - skill_extraction
    - trajectory_saving
    - context_compressor
```

## 关键文件

| 文件 | 用途 |
|------|------|
| `references/hermes-agent/deep-analysis.md` | 深度分析报告 |
| `references/hermes-agent/hermes-skills/` | Hermes 技能软链接 |
| `state/integration/hermes-bridge.yaml` | 桥接配置 |
| `~/.hermes/config.yaml` | Hermes 主配置 |

## 参考资源

- Hermes 文档: https://hermes-agent.nousresearch.com/docs/
- MetaClaw 论文: https://arxiv.org/abs/2603.17187
- 本地 SKILL.md: `~/.hermes/skills/autonomous-ai-agents/hermes-agent/SKILL.md`
