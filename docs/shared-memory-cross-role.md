# Shared Memory Cross-Role Layer

## Goal
Allow role-specific workspaces such as 太子 to recover the user's core preferences without depending on one sandbox's local files.

## Shared Source
- `~/.openclaw/shared-memory/USER.md`
- `~/.openclaw/shared-memory/MEMORY.md`

## Current Consumers
- `workspace-taizi/USER.md`
- `workspace-taizi/MEMORY.md`
- `workspace-taizi/HEARTBEAT.md`

## Current Strategy
- Shared files store the authoritative cross-role user preference baseline.
- Role-local files cache the same summary so startup and direct file reads still work even if shared reads are skipped.
- Empty role templates should never override a populated shared baseline.

## Next Expansion
- Sync the same shared baseline into other role workspaces when needed.
- Add a small sync utility if cross-role drift appears.

## Addressing Enforcement
- Shared preference recovery is not enough by itself; role prompts must also require that known user addressing preferences appear in actual replies.
- Current enforcement added for 太子: when replying to the current user, default to “皇上” unless explicitly changed.
