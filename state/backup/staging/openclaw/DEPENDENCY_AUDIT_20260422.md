# edict-rebuild / openclaw-channels 现实依赖审计（2026-04-22）

## 结论摘要

### 1. `edict-rebuild`：**当前仍是现实依赖，不可整目录删除**
原因：
- `edict-rebuild/runtime/data` 仍承载运行态数据：
  - `tasks_source.json`
  - `live_status.json`
  - `agent_config.json`
  - `agents_status.json`
  - `pending_model_changes.json`
  - `model_change_log.json`
  - `sync_status.json`
  - `wal/WAL-2026-04-21.log`
- `edict-rebuild/continuation/repo/data` 不是独立数据目录，而是**符号链接到**：
  - `/opt/fnos-media/services/edict-rebuild/runtime/data`
- `edict-rebuild/continuation/repo` 仍包含完整的看板/安装/同步链：
  - `dashboard/server.py`
  - `scripts/refresh_live_data.py`
  - `scripts/sync_agent_config.py`
  - `scripts/unified_sync_from_api.py`
  - `install.sh`
  - `start.sh`
  - `Dockerfile`
- 现有环境里曾多次直接从 `edict-rebuild/continuation/repo` 启动看板和调试链路，说明它不是纯归档。
- 历史结论也表明：`edict-localized` 当前是主业务仓，但部分脚本/软链仍借道 `edict-rebuild/continuation/repo`。

#### 可删范围（仅限局部，不是整目录）
可进一步考虑局部裁剪：
- `edict-rebuild/upstream/edict`（上游镜像参考仓，若本地不再需要可归档/删除）
- `edict-rebuild/audit/`（大量历史审计产物与 `.bak`）
- `edict-rebuild/continuation/repo/docs/`（如只保运行可移出）
- `edict-rebuild/continuation/repo/examples/`
- `edict-rebuild/continuation/repo/tests/`
- `edict-rebuild/continuation/repo/*.bak.*`

#### 当前建议
- **不要删除整个 `edict-rebuild`**
- 若要继续瘦身，应走“运行态保留、文档/审计/上游镜像外移或打包归档”的方式。

---

### 2. `openclaw-channels`：**当前更像历史渠道工件仓，不是运行时硬依赖**
证据：
- 当前 Docker 挂载实际使用的是：
  - `/opt/fnos-media/services/openclaw-governance/runtime`
  - `/opt/fnos-media/services/openclaw-governance/scripts`
  - `/opt/fnos-media/services/docker-stack/channels/.../logs`
  - `/opt/fnos-media/services/docker-stack/ai-proxy/cliproxyapi/...`
- 没有发现现运行容器直接挂载 `/opt/fnos-media/services/openclaw-channels`。
- `openclaw-channels` 目录内容主要是：
  - `telegram/logs`
  - `telegram/run`
  - `telegram/manifest`
  - `telegram/config`
  - `telegram/secrets`
  - 以及 `discord / qq / feishu` 等渠道目录
- 从内容结构看，它更像：
  - 渠道接入调试工件库
  - 历史 layout / manifest 留档
  - 一部分本地 secrets 承载目录

#### 风险点
- 目录内存在 `secrets/`，说明里面可能有真实凭据或接入信息。
- 即使不是运行时硬依赖，也不应直接粗暴删除；更适合：
  1. 先脱敏备份
  2. 再移出或归档

#### 当前建议
- **不属于当前运行时硬依赖**
- 若要瘦身，优先方案是：
  - 打包备份 `openclaw-channels` 为离线归档
  - 然后从在线运行机移除
- 若后续准备做“空白机一键安装”，这个目录更适合作为：
  - `optional/channels-seed/` 备份输入
  - 而不是强绑定运行根

---

## 对空白机器安装方案的影响

### 建议保留为“核心运行组件”的目录
- `openclaw`：OpenClaw 运行根
- `edict-localized/repo`：当前业务主仓 / 看板主仓
- `clawpanel/app`：面板
- `hermes-openwebui`：Hermes/Open WebUI 容器编排
- `docker-stack` 或 `/opt/fnos-media-stack`：媒体/附属服务编排（若需要）

### 建议保留但只做“兼容/迁移层”的目录
- `edict-rebuild`：作为兼容层/运行数据保留，直到脚本链彻底从中剥离

### 建议转为“可选归档输入”的目录
- `openclaw-channels`
- 各类历史 `.bak` / `manifest` / `logs`

---

## 推荐的最终收敛目标

### Phase A：现机稳定
- 保留 `edict-rebuild/runtime/data`
- 保留 `edict-localized/repo`
- 继续把真实运行脚本逐步收敛到 `edict-localized/repo`

### Phase B：可迁移安装包
拆成 4 层：
1. `core/openclaw`
2. `apps/edict-dashboard`
3. `apps/clawpanel`
4. `apps/hermes-openwebui`
5. `optional/channels-seed`
6. `optional/media-stack`

### Phase C：空白机一键装
总脚本负责：
- 依赖检查
- 目录创建
- 配置模板生成
- 启动 OpenClaw
- 启动看板
- 启动 ClawPanel
- 启动 Hermes/OpenWebUI
- 可选启媒体栈与渠道种子

---

## 当前操作建议

### 可以继续做
- 清理 `edict-rebuild/audit`
- 清理 `edict-rebuild/upstream/edict`
- 归档 `openclaw-channels`
- 编写统一 bootstrap 脚本

### 现在不要做
- 删除整个 `edict-rebuild`
- 在未脱敏前删除或外传 `openclaw-channels/secrets`
