# OpenClaw Restore Notes

Generated: 2026-05-16T02:00:09+08:00
Source workspace: /root/.openclaw/.openclaw/workspace

Contents in this directory are intended for configuration-level recovery.
Restore priority:
1. docs/
2. scripts/
3. workspace governance/baseline files
4. memory/ and references needed for operational context

Excluded from this backup:
- runtime state
- dream artifacts
- caches and temporary files
- installation packages / reproducible software archives
- files larger than 95m (override with OPENCLAW_BACKUP_RSYNC_MAX_SIZE)
