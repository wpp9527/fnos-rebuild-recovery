# Example: debug/refactor compaction

## Goal
- 修复看板前后台不一致，并稳定 edict 多 agent 链路。

## Constraints & Preferences
- 用户允许持续修复，必要时可整体重构。
- 优先保核心链稳定，不随意更动关键主模型。

## Progress
### Done
- [x] 核心 edict 轻量闭环已成功。
- [x] 已定位“多数据源 + 异步刷新 + JSON/Edict 双轨”是主要根因链。
- [x] 已回调 4 个不稳辅助 agent 主模型。

### In Progress
- [ ] 验证 dashboard 是否已实际使用 canonical data source。
- [ ] 复测回调后的辅助 agent。

### Blocked
- 当前 workspace 不是 git 仓库，无法在该目录直接提交。

## Key Decisions
- 固定 canonical 数据源优先，避免 server 读 B、脚本写 A。
- 仅回调不稳辅助 agent，不动核心链主骨架。

## Evidence / Exact identifiers
- `JJC-20260421-002`
- `agent:taizi:main`
- `data/tasks_source.json`
- `/opt/fnos-media/services/openclaw/home/.openclaw/workspace-taizi/.openclaw/JJC-20260421-002-gongbu-proof.txt`

## Pending user asks
- 一直修复；必要时可整体重构。

## Recommended next step
1. 验证 live_status.json / tasks_source.json 是否同源。
2. 复测回调后的 `xingbu` / `qingbaoshi` / `libu_hr` / `taixuesi`。
3. 若仍分叉，继续把看板读写路径彻底单源化。
