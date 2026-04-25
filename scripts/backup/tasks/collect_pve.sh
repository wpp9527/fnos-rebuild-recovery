#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/common.sh
source "$SCRIPT_DIR/../lib/common.sh"

WORKSPACE_ROOT="${WORKSPACE_ROOT:-$(cd "$SCRIPT_DIR/../../.." && pwd)}"
STAGING_ROOT="${STAGING_ROOT:-$WORKSPACE_ROOT/state/backup/staging}"
REPORT_DIR="$STAGING_ROOT/reports"
PVE_ENABLED="${PVE_ENABLED:-0}"
PVE_SSH_HOST="${PVE_SSH_HOST:-}"

ensure_dir "$REPORT_DIR"

if [[ "$PVE_ENABLED" != "1" || -z "$PVE_SSH_HOST" ]]; then
  cat > "$REPORT_DIR/pve-not-configured.md" <<EOF
# PVE Backup Status

PVE backup is not configured yet.

Expected future inputs:
- PVE_ENABLED=1
- PVE_SSH_HOST=<ssh-host-or-alias>
EOF
  log "collect_pve: not configured"
  exit 0
fi

cat > "$REPORT_DIR/pve-configured-placeholder.md" <<EOF
# PVE Backup Status

PVE backup is configured but collection is not implemented in this phase.
Target: $PVE_SSH_HOST
EOF
log "collect_pve: configured placeholder"
