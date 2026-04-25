# Backup Automation

## Config
Runtime config file:
- `state/backup/config.env`

Template to copy from:
- `scripts/backup/config.env.example`

## Manual runs
Daily backup:
- `bash scripts/backup/run_daily.sh`

Weekly backup + snapshot:
- `bash scripts/backup/run_weekly.sh`

## What it currently does
- Collects OpenClaw recovery assets
- Collects fnOS local recovery assets from `/opt/fnos-media`
- Verifies PVE SSH connectivity and records host metadata
- Publishes `services/openclaw/latest`
- Publishes shared indexes and restore guides
- Creates weekly OpenClaw snapshots

## Important notes
- Backup target is expected at `/mnt/nas/backup`
- fnOS is treated as the local host where OpenClaw runs
- PVE is currently collected as connectivity + metadata only; full remote config export is the next upgrade
- Runtime secrets such as `PVE_SSH_PASSWORD` live in `state/backup/config.env` and are not committed
