# 系统设计知识库引用

## System Design Primer

**位置:** `/references/system-design-primer`

**用途:** 架构设计参考、系统设计面试准备

### 核心内容

- **系统设计原则:** 可扩展性、可用性、一致性
- **常见架构模式:** 负载均衡、缓存、数据库分片
- **面试题库:** 设计 Twitter、URL 短链接、聊天系统等

### 适用角色

- 中书省（方案规划）
- 门下省（架构审查）
- 兵部（工程架构）
- 工部（技术执行）
- 太学寺（知识管理）

### 使用方式

在任务执行时，参考：
```
/references/system-design-primer/README-zh-Hans.md
```

---

## Andrej Karpathy Skills

**位置:** `/references/andrej-karpathy-skills`

**用途:** 编码最佳实践、LLM 编码陷阱避免

### 四大原则

1. **Think Before Coding**
   - 明确假设，不要默默选择
   - 提出多个解释，寻求澄清
   - 困惑时停下来

2. **Simplicity First**
   - 最小代码解决问题
   - 不要过度工程
   - 如果 200 行可以是 50 行，重写

3. **Surgical Changes**
   - 只修改必要的
   - 匹配现有风格
   - 每个修改都应该追溯到用户请求

4. **Goal-Driven Execution**
   - 定义成功标准
   - 循环直到验证

### 适用角色

所有参与代码开发的角色

### 使用方式

已在核心 agent 的 workspace 中添加 `CLAUDE.md`

---

## 技能安装清单

### 已安装

| 技能 | 版本 | 用途 |
|------|------|------|
| `proactive-agent-skill` | 1.0.0 | 主动工作、WAL 协议 |
| `agent-team-orchestration` | 1.0.0 | 团队编排、任务生命周期 |
| `task-orchestra` | 1.0.0 | 复杂任务编排 |
| `proactive-tasks` | 1.2.3 | 主动任务管理 |
| `workflow` | 1.0.0 | 工作流设计 |
| `agent-orchestrator` | 1.0.0 | agent 编排 |
| `agent-autonomy-kit` | 1.0.0 | agent 自主工作 |
| `self-improving-agent` | 3.0.6 | 自我改进 |
| `summarize` | 1.0.0 | 内容总结 |
| `find-skills` | 0.1.0 | 技能发现 |

### 系统内置

| 技能 | 用途 |
|------|------|
| `healthcheck` | 系统健康检查、安全审计 |
| `skill-creator` | 技能创建和管理 |
| `taskflow` | 任务流管理 |
| `video-frames` | 视频处理 |
| `weather` | 天气查询 |

---

## 角色技能映射

### 核心角色（正一品以上）

| 角色 | 核心技能 | 辅助技能 | 知识库 |
|------|---------|---------|--------|
| 太子 | proactive-agent, agent-team-orchestration | task-orchestra, context-compaction | Karpathy |
| 中书省 | workflow, task-orchestra | agentic-workflow-automation | System Design, Karpathy |
| 门下省 | healthcheck, skill-scanner | task-review-workflow | System Design, Karpathy |
| 尚书省 | agent-team-orchestration, task-orchestra | proactive-tasks | Karpathy |

### 六部（正二品）

| 角色 | 核心技能 | 知识库 |
|------|---------|--------|
| 工部 | healthcheck, video-frames, weather | System Design |
| 户部 | proactive-tasks | - |
| 礼部 | skill-creator | - |
| 兵部 | healthcheck | System Design |
| 刑部 | healthcheck, skill-scanner | - |
| 吏部 | skill-creator, proactive-tasks | - |

### 辅助角色

| 角色 | 核心技能 | 知识库 |
|------|---------|--------|
| 钦天监 | weather | - |
| 太学寺 | skill-creator | System Design |
| 情报使 | weather | - |
| 锦衣卫 | healthcheck, skill-scanner | - |
| 技能导师 | skill-creator | - |
| 度支司 | proactive-tasks | - |

---

## 下一步

### Phase 1: 已完成 ✅
- [x] 角色技能推荐配置
- [x] 核心技能安装
- [x] 知识库克隆
- [x] Karpathy Skills 部署到核心 agent

### Phase 2: 待完成
- [ ] 为每个 agent 创建完整的 SKILL.md
- [ ] 在 agent_config.json 中注册技能
- [ ] 测试技能调用
- [ ] 建立技能使用监控

### Phase 3: 长期
- [ ] 基于使用情况优化技能配置
- [ ] 创建自定义技能
- [ ] 集成 Multica 和 CrewAI 的设计理念
