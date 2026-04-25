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

## fnos-media-stack classification

### must back up
- `/opt/fnos-media-stack/homarr/config`
- `/opt/fnos-media-stack/homarr/appdata`
- `/opt/fnos-media-stack/halo/config`
- `/opt/fnos-media-stack/halo/content`
- `/opt/fnos-media-stack/qbittorrent/config`
- `/opt/fnos-media-stack/jackett/config`
- `/opt/fnos-media-stack/radarr/config`
- `/opt/fnos-media-stack/sonarr/config`
- `/opt/fnos-media-stack/prowlarr/config`
- `/opt/fnos-media-stack/bazarr/config`
- `/opt/fnos-media-stack/seerr/config`

### recommended to back up
- `/opt/fnos-media-stack/jellyfin/config`
- `/opt/fnos-media-stack/stash/config`
- `/opt/fnos-media-stack/stash/metadata`
- `/opt/fnos-media-stack/stash/blobs`
- `/opt/fnos-media-stack/stash/generated`

### safe to ignore or rebuild
- `/opt/fnos-media-stack/jellyfin/cache`
- `/opt/fnos-media-stack/stash/cache`
- logs and temporary runtime outputs under service-specific log directories

## live compose drift control

The live standalone stack currently runs from:
- `/opt/fnos-media-stack/docker-compose.yml`

The recovery-safe template lives in the repo at:
- `restore/templates/services/fnos-media-stack/docker-compose.yml`

Rule:
- treat the repo template as the recovery source of truth
- when the live compose file is changed on-host, mirror any recovery-relevant mount, env, and service-shape changes back into the repo template
- do not store raw secrets in the repo copy; keep real values in local/NAS env files only
- prefer explicit bind mounts over anonymous volumes so backup/restore can track state deterministically
