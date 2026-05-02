#!/usr/bin/env bash
# Collect container data volumes (not covered by collect_fnos or collect_openclaw)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"

STAGING_ROOT="${STAGING_ROOT:-$(cd "$SCRIPT_DIR/../../../state" && pwd)/backup/staging}"
VOLUMES_STAGE_DIR="$STAGING_ROOT/container-volumes"

# Source the backup config for volume paths
CONFIG_FILE="${BACKUP_CONFIG:-$(cd "$SCRIPT_DIR/../.." && pwd)/state/backup/config.env}"
[[ -f "$CONFIG_FILE" ]] && source "$CONFIG_FILE"

FNOS_MEDIA_STACK="${FNOS_MEDIA_STACK:-/opt/fnos-media-stack}"

ensure_dir "$VOLUMES_STAGE_DIR"
rm -rf "$VOLUMES_STAGE_DIR"
ensure_dir "$VOLUMES_STAGE_DIR"

# Volumes to back up (from must_back_up_local_state in backup_target_manifest.yaml)
VOLUMES=(
  "$FNOS_MEDIA_STACK/homarr/config"
  "$FNOS_MEDIA_STACK/homarr/appdata"
  "$FNOS_MEDIA_STACK/halo/config"
  "$FNOS_MEDIA_STACK/halo/content"
  "$FNOS_MEDIA_STACK/qbittorrent/config"
  "$FNOS_MEDIA_STACK/jackett/config"
  "$FNOS_MEDIA_STACK/radarr/config"
  "$FNOS_MEDIA_STACK/sonarr/config"
  "$FNOS_MEDIA_STACK/prowlarr/config"
  "$FNOS_MEDIA_STACK/bazarr/config"
  "$FNOS_MEDIA_STACK/seerr/config"
)

COPIED=0
SKIPPED=0

for vol in "${VOLUMES[@]}"; do
  if [[ -d "$vol" ]]; then
    rel="${vol#$FNOS_MEDIA_STACK/}"
    dst="$VOLUMES_STAGE_DIR/$rel"
    ensure_dir "$(dirname "$dst")"
    # Exclude caches, logs, large binaries
    rsync -rltD --quiet \
      --exclude='*.log' \
      --exclude='__pycache__/' \
      --exclude='*.pyc' \
      --exclude='.cache/' \
      --exclude='cache/' \
      --exclude='logs/' \
      --exclude='tmp/' \
      --exclude='.tmp/' \
      --exclude='MediaCover/'       --exclude='Backups/'       --exclude='Sentry/'       --exclude='asp/'       --exclude='Definitions/'       --exclude='GeoDB/'       --exclude='logs.db*'       --exclude='*.db.bak-*'       "$vol/" "$dst/"
    COPIED=$((COPIED + 1))
  else
    SKIPPED=$((SKIPPED + 1))
  fi
done

# Also capture any additional compose-level config not under FNOS_MEDIA_STACK
ADDITIONAL_PATHS=(
  /opt/fnos-media/services/hermes-openwebui/data
  /opt/fnos-media/services/docker-stack/ai-proxy/cliproxyapi/auths
)
for ap in "${ADDITIONAL_PATHS[@]}"; do
  if [[ -d "$ap" ]]; then
    rel="${ap#/}"
    dst="$VOLUMES_STAGE_DIR/additional/$rel"
    ensure_dir "$(dirname "$dst")"
    rsync -rltD --quiet "$ap/" "$dst/"
    log "collect_container_volumes: backed up $ap"
    COPIED=$((COPIED + 1))
  fi
done

cat > "$VOLUMES_STAGE_DIR/manifest.yaml" <<MANIFEST_EOF
# Container Volumes Backup Manifest
generated: $(date -Is)
source_root: $FNOS_MEDIA_STACK
volumes_backed_up: $COPIED
volumes_skipped: $SKIPPED
MANIFEST_EOF

# Log summary
for vol in "${VOLUMES[@]}"; do
  if [[ -d "$vol" ]]; then
    rel="${vol#$FNOS_MEDIA_STACK/}"
    size="$(du -sh "$VOLUMES_STAGE_DIR/$rel" 2>/dev/null | cut -f1)"
    log "collect_container_volumes: $rel ($size)"
  fi
done

log "collect_container_volumes: complete ($COPIED volumes, $SKIPPED skipped)"
