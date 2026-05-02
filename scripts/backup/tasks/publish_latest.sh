#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/common.sh
source "$SCRIPT_DIR/../lib/common.sh"

WORKSPACE_ROOT="${WORKSPACE_ROOT:-$(cd "$SCRIPT_DIR/../../.." && pwd)}"
STAGING_ROOT="${STAGING_ROOT:-$WORKSPACE_ROOT/state/backup/staging}"
BACKUP_ROOT="${BACKUP_ROOT:-/mnt/nas/backup}"
TIMESTAMP="${TIMESTAMP:-$(now_ts)}"
LOCAL_TMP_ROOT="${LOCAL_TMP_ROOT:-/tmp/openclaw-backup-publish}"

require_dir "$STAGING_ROOT/openclaw"
require_dir "$BACKUP_ROOT"

publish_tree() {
  local source_dir="$1"
  local target_base="$2"
  local target_latest="$target_base/latest"
  local tmp_target="$target_base/.tmp-latest-$TIMESTAMP-$$"
  local backup_latest="$target_base/.prev-latest-$TIMESTAMP-$$"
  local local_tmp_target="$LOCAL_TMP_ROOT/$(basename "$target_base")-$TIMESTAMP-$$"

  ensure_dir "$target_base"
  ensure_dir "$LOCAL_TMP_ROOT"
  rm -rf "$tmp_target"
  rm -rf "$local_tmp_target"
  ensure_dir "$local_tmp_target"
  rsync -rltD --delete "$source_dir/" "$local_tmp_target/"
  ensure_dir "$tmp_target"
  timeout 120 rsync -rltD --quiet "$local_tmp_target/". "$tmp_target/" || {
    log "rsync to NFS timed out; cleaning up local_tmp"
    rm -rf "$local_tmp_target"
    rm -rf "$tmp_target"
    return 1
  }
  rm -rf "$local_tmp_target"
  if [[ -e "$target_latest" && ! -d "$target_latest" ]]; then
    rm -f "$target_latest"
  elif [[ -d "$target_latest" ]]; then
    mv "$target_latest" "$backup_latest"
  fi
  mv "$tmp_target" "$target_latest"
}

OPENCLAW_TARGET_BASE="$BACKUP_ROOT/services/openclaw"
OPENCLAW_TARGET_LATEST="$OPENCLAW_TARGET_BASE/latest"
publish_tree "$STAGING_ROOT/openclaw" "$OPENCLAW_TARGET_BASE"

PVE_STATUS="not-configured"
PVE_TARGET_LATEST=""
if [[ -d "$STAGING_ROOT/pve" ]]; then
  publish_tree "$STAGING_ROOT/pve" "$BACKUP_ROOT/pve"
  PVE_TARGET_LATEST="$BACKUP_ROOT/pve/latest"
fi

FNOS_STATUS="not-configured"
FNOS_TARGET_LATEST=""
if [[ -d "$STAGING_ROOT/fnos" ]]; then
  publish_tree "$STAGING_ROOT/fnos" "$BACKUP_ROOT/fnos"
  FNOS_TARGET_LATEST="$BACKUP_ROOT/fnos/latest"
fi

LXC_PROXY_TARGET_LATEST=""
if [[ -d "$STAGING_ROOT/lxc-proxy" ]]; then
  publish_tree "$STAGING_ROOT/lxc-proxy" "$BACKUP_ROOT/lxc-proxy"
  LXC_PROXY_TARGET_LATEST="$BACKUP_ROOT/lxc-proxy/latest"
fi

CONTAINER_VOLUMES_TARGET_LATEST=""
if [[ -d "$STAGING_ROOT/container-volumes" ]]; then
  publish_tree "$STAGING_ROOT/container-volumes" "$BACKUP_ROOT/container-volumes"
  CONTAINER_VOLUMES_TARGET_LATEST="$BACKUP_ROOT/container-volumes/latest"
fi

SHARED_ROOT="$BACKUP_ROOT/shared"
ensure_dir "$SHARED_ROOT/version-index/latest"
ensure_dir "$SHARED_ROOT/restore-guides/latest"
ensure_dir "$SHARED_ROOT/change-log/latest"
ensure_dir "$SHARED_ROOT/network-map/latest"

[[ -f "$STAGING_ROOT/reports/pve-connectivity-ok.md" ]] && PVE_STATUS="connectivity-ok"
[[ -f "$STAGING_ROOT/reports/fnos-local-collection-ok.md" ]] && FNOS_STATUS="success"

cat > "$SHARED_ROOT/version-index/latest/backup_target_manifest.yaml" <<EOF
version: 1
generated_at: "$TIMESTAMP"
targets:
  openclaw:
    status: success
    latest_path: "$OPENCLAW_TARGET_LATEST"
  pve:
    status: $PVE_STATUS
    latest_path: "$PVE_TARGET_LATEST"
  fnos:
    status: $FNOS_STATUS
    latest_path: "$FNOS_TARGET_LATEST"
container_volumes:
    status: collected
    source: container-volumes/latest
backed_up_local_state:
  - /opt/fnos-media-stack/homarr/config
  - /opt/fnos-media-stack/homarr/appdata
  - /opt/fnos-media-stack/halo/config
  - /opt/fnos-media-stack/halo/content
  - /opt/fnos-media-stack/qbittorrent/config
  - /opt/fnos-media-stack/jackett/config
  - /opt/fnos-media-stack/radarr/config
  - /opt/fnos-media-stack/sonarr/config
  - /opt/fnos-media-stack/prowlarr/config
  - /opt/fnos-media-stack/bazarr/config
  - /opt/fnos-media-stack/seerr/config
  - /opt/fnos-media/services/hermes-openwebui/data
  - /opt/fnos-media/services/docker-stack/ai-proxy/cliproxyapi/auths
EOF

cat > "$SHARED_ROOT/restore-guides/latest/restore-order.md" <<EOF
# Restore Order

1. Rebuild PVE host base configuration
2. Restore PVE inventory from pve/latest
3. Restore fnOS VM structure and service layout
4. Restore fnOS config set from fnos/latest
5. Restore high-value local state (fnos-media-stack configs, Homarr appdata, Hermes OpenWebUI data, cliproxyapi auths)
6. Restore OpenClaw workspace and scripts from services/openclaw/latest
7. Restore remaining service-level configuration
EOF

cat > "$SHARED_ROOT/network-map/latest/host-service-map.yaml" <<EOF
version: 1
generated_at: "$TIMESTAMP"
hosts:
  control:
    role: openclaw-controller
    backup_root: "$BACKUP_ROOT"
services:
  openclaw:
    latest_path: "$OPENCLAW_TARGET_LATEST"
  pve:
    latest_path: "$PVE_TARGET_LATEST"
  fnos:
    latest_path: "$FNOS_TARGET_LATEST"
EOF

cat > "$SHARED_ROOT/change-log/latest/change-summary-$TIMESTAMP.md" <<EOF
# Backup Change Summary

Generated at: $TIMESTAMP

- openclaw: success
- pve: $PVE_STATUS
- fnos: $FNOS_STATUS
EOF

log "publish_latest complete: $OPENCLAW_TARGET_LATEST"
