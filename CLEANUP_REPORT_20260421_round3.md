# Cleanup Report — Round 3 (2026-04-21)

## Removed
- obsolete_disabled_patch: `/opt/fnos-media/services/edict-localized/repo/dashboard/role_arch_runtime_patch.js.disabled.20260415_022339`
- obsolete_disabled_patch: `/opt/fnos-media/services/edict-localized/repo/dashboard/role_arch_sync.js.disabled.20260415_022339`
- empty_runtime_dir: `/opt/fnos-media/services/openclaw/home/.openclaw/clawpanel/cache`
- empty_runtime_dir: `/opt/fnos-media/services/openclaw/home/.openclaw/clawpanel/images`
- empty_runtime_dir: `/opt/fnos-media/services/openclaw/home/.openclaw/clawpanel/sessions`
- empty_runtime_dir: `/opt/fnos-media/services/openclaw/home/.openclaw/qqbot/data`

## Source cleanup
- Updated dashboard source comment: `main` is runtime default entry, not taizi alias
- Updated dashboard label map: `main` → `主控`

## Not touched in this round
- `.openclaw/backups/agent-hubu-20260418-0020.tar` retained
- `dashboard/dist/*` retained (no rebuild performed yet)
- `.openclaw/agents/*` retained