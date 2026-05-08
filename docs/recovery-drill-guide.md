# Recovery Drill Guide

## GitHub + NAS dual entry

This recovery system assumes two entry points:
- GitHub repository for recovery-safe templates, scripts, manifests, and docs
- NAS latest/shared trees for staged backup outputs, local high-value state, and drill artifacts

Use both. GitHub provides structure and history; NAS provides the latest host-collected state.

## restore-all

Primary entrypoint:
- `bash restore/restore-all.sh plan --source hybrid`
- `bash restore/restore-all.sh apply --source hybrid`
- `bash restore/restore-all.sh verify --source hybrid`

Recommended drill flow:
1. run `plan`
2. inspect reports and selected source
3. run `apply` into a safe target root
4. run `verify`
5. review generated reports under `state/restore/reports`

## fnos-media-stack

`fnos-media-stack` is treated as a standalone live stack with a recovery-safe template in:
- `restore/templates/services/fnos-media-stack/docker-compose.yml`

The live compose currently runs from:
- `/opt/fnos-media-stack/docker-compose.yml`

Drill expectations:
- secrets remain outside the repo and are injected from local/NAS env files
- Homarr uses explicit bind mounts including `/opt/fnos-media-stack/homarr/appdata`
- media/download payloads stay on NAS; only high-value local state is restored locally

## local high-value state

The drill should verify that these classes of state can be restored:
- `fnos-media-stack` configs
- Homarr appdata
- Hermes OpenWebUI data
- cliproxyapi auths and config
- OpenClaw minimal runtime config

Do not treat logs and caches as primary recovery targets unless explicitly needed.

## runtime audit

Weekly backup now runs:
- `scripts/backup/audit_runtime_state.sh`

The drill should review the published audit report at:
- `shared/restore-guides/latest/runtime-state-audit.md`

Expected audit checks:
- anonymous volume detection
- live compose vs template drift
- missing local state paths
- missing template comparison inputs

## weekly backup verification

Recommended weekly verification checklist:
1. run `bash scripts/backup/run_weekly.sh`
2. confirm snapshot exists under `services/openclaw/snapshots/<timestamp>`
3. confirm shared outputs exist:
   - `shared/version-index/latest/backup_target_manifest.yaml`
   - `shared/restore-guides/latest/restore-order.md`
   - `shared/restore-guides/latest/runtime-state-audit.md`
4. confirm fnOS latest contains expected local high-value state
5. review runtime audit findings and resolve warnings before they accumulate

## drill completion criteria

A drill is considered successful when:
- restore-all plan/apply/verify all complete
- fnOS high-value local state can be restored into target paths
- runtime audit report is published and understandable
- latest/shared artifacts on NAS match the documented recovery flow
