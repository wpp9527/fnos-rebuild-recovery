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

## 2026-05-06 OpenClaw 升级与 doctor --fix 标准流程

### 本轮结果
- OpenClaw 已从 `2026.4.29-beta.4` 升级到 `2026.5.4`，但 `openclaw update status --json` 后续显示 registry 最新已变为 `2026.5.5`，因此存在新的可升级版本。
- 当前安装识别：`installKind=package`，`root=/usr/lib/node_modules/openclaw`，CLI 仍通过 `/opt/fnos-media/services/openclaw/home/bin/openclaw` wrapper 调用 `/usr/lib/node_modules/openclaw/openclaw.mjs`。
- 当前运行框架仍正确绑定：`HOME=/opt/fnos-media/services/openclaw/home`，`OPENCLAW_HOME=/opt/fnos-media/services/openclaw/home`，配置与数据在 `/opt/fnos-media/services/openclaw/home/.openclaw`。
- 已按要求执行 `openclaw doctor --fix`，日志：`/opt/fnos-media/services/openclaw/home/.openclaw/memory/openclaw-upgrade-doctorfix-20260506-171259.log`。
- doctor --fix 前备份：`/opt/fnos-media/services/openclaw/home/.openclaw/backups/doctorfix-20260506-171259/`，包含 `openclaw.json`、`plugins-installs.json`、`sandbox-containers.json`。

### doctor --fix 结果
- `doctor_exit=0`。
- 成功迁移 sandbox containers registry：`$OPENCLAW_HOME/.openclaw/sandbox/containers.json` → `1 shard`。
- 刷新插件 registry：`67/92 enabled plugins indexed`。
- `plugins.entries` 保持 `active-memory`、`memory-core`、`ollama`、`openai` 不变。
- doctor 新增 `skills.entries` 并禁用 43 个当前 runtime 不可用/缺依赖的 skills（如 1password、discord、slack、voice-call、task-orchestra、xurl 等）。这是 doctor --fix 的主要配置改动，非插件卸载。
- `openclaw health` 返回 `health_exit=0`，但提示 Gateway event loop degraded，原因包括 `event_loop_utilization,cpu`。
- `openclaw gateway status` 显示存在 gateway 进程监听 `*:18789`：`pid 1221512 root: openclaw (*:18789)`；同时新探测进程 `pid 1231308` 连接 `127.0.0.1:18789` 出现 `ECONNREFUSED`，状态有冲突，需要后续单独检查，避免误判。
- doctor 仍提示未配置 `commands.ownerAllowFrom`，这是 owner-only 命令/审批的治理风险；配置前需确认具体渠道 user id。
- doctor 提示 `Gateway bound to "lan" (0.0.0.0)`，网络可访问，应确保认证强度；如要加固，优先考虑 loopback + Tailscale/SSH tunnel。
- doctor 提示 `16 agent directories on disk without matching agents.list entry`，包括 bingbu、duzhisi、gongbu 等；这与三省六部角色体系有关，后续应把关键角色迁入显式 agents/list 配置，而不是立即删除目录。
- doctor 提示 `19 orphan transcript files`，可归档但不要在未确认前删除。

### 后续版本升级标准流程
1. 暂停业务改动，记录当前任务进度。
2. 检查实际运行框架：`HOME`、`OPENCLAW_HOME`、`PWD` 必须指向 `/opt/fnos-media/services/openclaw/home`。
3. 检查版本与更新：`openclaw update status --json`、`npm view openclaw version`、`/usr/lib/node_modules/openclaw/package.json`。
4. 升级前备份：至少备份 `$OPENCLAW_HOME/.openclaw/openclaw.json`、`plugins/installs.json`、`sandbox/containers.json`、必要时备份 memory/session 关键 sqlite/jsonl。
5. 优先使用官方 `openclaw update`；若失败，再使用 `npm install -g openclaw@latest`，升级后立即验证并重启/检查 Gateway。
6. 升级后执行：`openclaw update status --json`、`openclaw doctor`，确认风险；只有用户明确要求或已备份后再执行 `openclaw doctor --fix`。
7. `doctor --fix` 后必须记录日志路径、备份路径、配置改动摘要、health/gateway status 结果。
8. 任何 `/opt` npm-global 迁移必须单独立项：先设计 prefix、PATH、systemd、wrapper，再执行；不能简单移动 `/usr/lib/node_modules/openclaw`。
