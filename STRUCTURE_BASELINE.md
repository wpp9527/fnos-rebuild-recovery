# /opt/fnos-media/services 结构基线

## 目标
消除“两个太子”语义冲突，并明确 /opt/fnos-media/services 下三层职责边界。

## 唯一真源原则
- 正式语义角色真源：`taizi`
- OpenClaw 运行时默认入口：`main`
- 结论：`main` 只能是运行时入口，不能再在展示层/生成层占用“太子”语义。

## 推荐结构
### 1. 运行根
- `/opt/fnos-media/services/openclaw`
- 作用：OpenClaw 服务本体与 `home/.openclaw` 运行时目录

关键运行目录：
- `/opt/fnos-media/services/openclaw/home/.openclaw/openclaw.json`
- `/opt/fnos-media/services/openclaw/home/.openclaw/workspace`
- `/opt/fnos-media/services/openclaw/home/.openclaw/workspace-main`
- `/opt/fnos-media/services/openclaw/home/.openclaw/workspace-taizi`
- `/opt/fnos-media/services/openclaw/home/.openclaw/agents/*`

### 2. 业务仓/安装仓
- `/opt/fnos-media/services/edict-localized`
- 作用：前台、dashboard、安装脚本、同步脚本、文档、审计资产

关键位置：
- `repo/install.sh`
- `repo/scripts/sync_agent_config.py`
- `repo/dashboard/server.py`
- `repo/edict/frontend/src/config/generated/officialRoles.ts`

### 3. 重建/派生产物仓
- `/opt/fnos-media/services/edict-rebuild`
- 作用：重建数据、runtime 派生产物、审计中间层

关键位置：
- `runtime/data/*`

## 本次问题的结构根因
1. `openclaw.json` 的 `agents.list` 同时存在 `main` 与 `taizi`
2. `sync_agent_config.py` 把 `main` 也映射成“太子”
3. 生成后的 `agent_config.json` 因此出现两条 label=太子
4. dashboard 虽然有“跳过 main”的兼容逻辑，但数据层已经先脏了

## 修复策略
### 已实施
- 在生成链 `sync_agent_config.py` 中：
  - `taizi` 保持正式“太子”
  - `main` 改为运行时“主控/默认主入口”
  - `main.workspace` 优先指向 OpenClaw 默认 workspace，而不是伪造 `workspace-main` 语义角色空间

### 后续建议
- 若允许更进一步收口：
  1. 从 `openclaw.json` 的 `agents.list` 中移除 `main` 的显式展示配置，只保留运行时默认入口机制
  2. 保留 dashboard 对 `main` 的过滤兼容，直到旧数据完全清空
  3. 将 `workspace-main` 明确标记为 legacy/canonical-data 兼容层，避免再次被当成正式角色工作区

## 判定标准
修复后应满足：
- `agent_config.json` 中只有一个 `label=太子`
- 该条目的 `id` 必须是 `taizi`
- `main` 若仍存在，只能显示为主控/默认主入口，不得再显示为太子
- 所有核心路径均保持在 `/opt/fnos-media/services` 树内
