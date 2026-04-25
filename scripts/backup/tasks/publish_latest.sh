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

TARGET_BASE="$BACKUP_ROOT/services/openclaw"
TARGET_LATEST="$TARGET_BASE/latest"
TMP_TARGET="$(stage_tmp_dir "$TARGET_BASE" latest)"

ensure_dir "$TARGET_BASE"
rm -rf "$TMP_TARGET"
ensure_dir "$TMP_TARGET"
rsync -rltD --delete "$STAGING_ROOT/openclaw/" "$TMP_TARGET/"
rm -rf "$TARGET_LATEST"
mv "$TMP_TARGET" "$TARGET_LATEST"

SHARED_ROOT="$BACKUP_ROOT/shared"
ensure_dir "$SHARED_ROOT/version-index/latest"
ensure_dir "$SHARED_ROOT/restore-guides/latest"
ensure_dir "$SHARED_ROOT/change-log/latest"
ensure_dir "$SHARED_ROOT/network-map/latest"

cat > "$SHARED_ROOT/version-index/latest/backup_target_manifest.yaml" <<EOF
version: 1
generated_at: "$TIMESTAMP"
targets:
  openclaw:
    status: success
    latest_path: "$TARGET_LATEST"
  pve:
    status: not-configured
  fnos:
    status: not-configured
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
    latest_path: "$TARGET_LATEST"
EOF

cat > "$SHARED_ROOT/change-log/latest/change-summary-$TIMESTAMP.md" <<EOF
# Backup Change Summary

Generated at: $TIMESTAMP

- openclaw: success
- pve: not-configured
- fnos: not-configured
EOF

log "publish_latest complete: $TARGET_LATEST"
