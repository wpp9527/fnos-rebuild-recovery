#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/common.sh
source "$SCRIPT_DIR/../lib/common.sh"

WORKSPACE_ROOT="${WORKSPACE_ROOT:-$(cd "$SCRIPT_DIR/../../.." && pwd)}"
STAGING_ROOT="${STAGING_ROOT:-$WORKSPACE_ROOT/state/backup/staging}"
BACKUP_ROOT="${BACKUP_ROOT:-/mnt/nas/backup}"
TIMESTAMP="${TIMESTAMP:-$(now_ts)}"

require_dir "$STAGING_ROOT/openclaw"
require_dir "$BACKUP_ROOT"

publish_tree() {
  local source_dir="$1"
  local target_base="$2"
  local target_latest="$target_base/latest"
  local tmp_target="$target_base/.tmp-latest-$TIMESTAMP-$$"

  ensure_dir "$target_base"
  rm -rf "$tmp_target"
  ensure_dir "$tmp_target"
  rsync -rltD --delete "$source_dir/" "$tmp_target/"
  if [[ -e "$target_latest" && ! -d "$target_latest" ]]; then
    rm -f "$target_latest"
  else
    rm -rf "$target_latest"
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
EOF

cat > "$SHARED_ROOT/restore-guides/latest/restore-order.md" <<EOF
# Restore Order

1. Rebuild PVE host base configuration
2. Restore fnOS VM structure and service layout
3. Restore OpenClaw workspace and scripts from services/openclaw/latest
4. Restore remaining service-level configuration
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
EOF

cat > "$SHARED_ROOT/change-log/latest/change-summary-$TIMESTAMP.md" <<EOF
# Backup Change Summary

Generated at: $TIMESTAMP

- openclaw: success
- pve: $PVE_STATUS
- fnos: $FNOS_STATUS
EOF

log "publish_latest complete: $OPENCLAW_TARGET_LATEST"
