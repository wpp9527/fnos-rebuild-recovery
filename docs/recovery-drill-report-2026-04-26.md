# Recovery Drill Report — 2026-04-26

## Overview

This drill ran `restore-all plan/apply` against a temporary isolated target root, using NAS as the source.

- Source mode: `nas`
- Target: `/tmp/openclaw-restore-drill-XXXXXX/target`
- Date: 2026-04-26 02:26 CST

---

## What Passed

### Layer 10 — PVE
- `pve apply complete`
- PVE latest backup accessible at `/mnt/nas/backup/pve/latest`
- Hostname and basic metadata restored

### Layer 20 — fnOS
- `fnos apply complete`
- fnOS latest backup accessible at `/mnt/nas/backup/fnos/latest`
- High-value local state paths can be restored

### Layer 40 — OpenClaw
- `openclaw apply complete`
- OpenClaw latest backup accessible at `/mnt/nas/backup/services/openclaw/latest`
- Workspace docs and config restored

---

## What Blocked

### Layer 50 — Secrets

```
BLOCK missing blocking secret: OPENCLAW_API_TOKEN
```

**Root cause:**

- Restore expects secrets at:
  - `/mnt/nas/backup/shared/secrets/latest/openclaw/`
  - or `/mnt/nas/backup/shared/secrets/latest/openclaw.env`

- **That path does not exist on NAS.**

- Current backup automation does not publish secrets to `shared/secrets/latest`.

- Actual secrets are stored in:
  - OpenClaw runtime config (`openclaw.json`, `clawpanel.json`)
  - Local `.secrets/` directories
  - Not currently captured by backup automation

---

## Impact

This is a **real recovery blocker**:

- If the machine is lost, `restore-all apply` will fail at the secrets step.
- Secrets required for OpenClaw, fnos-media-stack, and channels are not in the backup tree.
- Manual intervention would be required to re-inject secrets.

---

## Immediate Action Required

### Option A: Extend backup to publish secrets

1. Add a `tasks/publish_secrets.sh` step that:
   - Reads secrets from local runtime config
   - Publishes to `/mnt/nas/backup/shared/secrets/latest/`

2. Ensure `.gitignore` and `.dockerignore` exclude secrets from repo.

3. Update `restore/layers/50-secrets.sh` to read from the published location.

### Option B: Document manual secrets recovery

1. Keep secrets outside automated backup for security.
2. Document manual recovery steps in `docs/secrets-recovery.md`.
3. Accept that secrets require out-of-band injection.

---

## Next Drill Goals

After resolving the secrets blocker:

1. Run `restore-all verify` against the isolated target.
2. Compare restored compose files against running containers.
3. Verify that restored env files contain expected keys (values can be placeholders).
4. Run `audit_runtime_state.sh` against the restored tree.

---

## Summary

| Layer | Result |
|-------|--------|
| PVE | PASS |
| fnOS | PASS |
| OpenClaw | PASS |
| Services | not reached |
| Secrets | BLOCK |

**This drill revealed a critical gap: secrets are not in the backup path.**

Resolving this is required before the system can be considered fully recoverable.
