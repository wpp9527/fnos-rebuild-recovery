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
- Publishes `services/openclaw/latest`
- Publishes shared indexes and restore guides
- Creates weekly OpenClaw snapshots
- Marks PVE / fnOS as `not configured` until SSH access is set up

## Important notes
- Backup target is expected at `/mnt/nas/backup`
- Current remote collection for PVE / fnOS is placeholder-only
- SSH integration should be enabled later by editing `state/backup/config.env`
