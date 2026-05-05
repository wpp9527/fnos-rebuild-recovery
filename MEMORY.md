# MEMORY

- 当前基线为 factory reinstall v7.2.0

## 2026-04-21 GitHub 项目集成与角色技能配置

### 已完成的集成

**1. GitHub 项目**
- ✅ System Design Primer (`donnemartin/system-design-primer`) → `/references/system-design-primer`
- ✅ Andrej Karpathy Skills → `/references/andrej-karpathy-skills`

**2. 核心技能安装**
- proactive-agent-skill, agent-team-orchestration, task-orchestra
- proactive-tasks, workflow, agent-orchestrator
- self-improving-agent, summarize, find-skills
- context-compaction, skillhub-preference

**3. 角色技能部署**
- ✅ taizi, zhongshu, menxia, shangshu, gongbu, bingbu 已部署 CLAUDE.md（Karpathy Skills）
- ✅ 角色技能推荐配置已保存

**4. 职责说明**
- 太子：任务分拣、协调各省、回奏皇上
- 中书省：起草任务令、方案规划
- 门下省：审议封驳、质量把关
- 尚书省：任务派发、资源调度
- 工部：基础设施、技术执行
- 兵部：工程实现、代码开发
- 刑部：合规审计、安全审查
- 吏部：人事培训、Agent 管理

**详细报告:**
- `/memory/integration-final-report.md`
- `/memory/role-skills-recommendation.json`
- `/memory/knowledge-bases-and-skills.md`

## Promoted From Short-Term Memory (2026-05-04)

<!-- openclaw-memory-promotion:memory:memory/2026-04-26.md:26:28 -->
- - 修复方向已确定并完成：将 ClawPanel 从 `nginx:alpine` 的静态模式切换为 `node scripts/serve.js` 的 headless 模式；修复后 `http://127.0.0.1:1420/__api/health` 返回 `HTTP/1.1 200 OK` + `Content-Type: application/json` + `{"ok":true,...}`，`http://127.0.0.1:1420/__api/auth_check` 返回 JSON，`http://127.0.0.1:1420/` 仍正常返回前端页面。 - 另一个已确认的接入问题：ClawPanel 之前误读的是 `/root/.openclaw`，而当前机器真实运行的 OpenClaw home 是 `/opt/fnos-media/services/openclaw/home/.openclaw`；因此面板会错误提示未接入/未安装。已确认 `/root/.openclaw/openclaw.json` 是旧实例配置，`/opt/fnos-media/services/openclaw/home/.openclaw/openclaw.json` 才是当前有效实例配置。 - ClawPanel 当前应绑定的关键路径/二进制：`openclawDir=/opt/fnos-media/services/openclaw/home/.openclaw`、`openclawCliPath=/usr/bin/openclaw`、`gitPath=/usr/bin/git`；用户后续若再遇到“检测不到 OpenClaw”，优先检查是否又回退到 `/root/.openclaw`。 [score=0.896 recalls=0 avg=0.620 source=memory/2026-04-26.md:26-28]
