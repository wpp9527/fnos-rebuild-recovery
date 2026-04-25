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
PVE_SSH_USER="${PVE_SSH_USER:-root}"
PVE_SSH_PASSWORD="${PVE_SSH_PASSWORD:-}"

ensure_dir "$REPORT_DIR"

if [[ "$PVE_ENABLED" != "1" || -z "$PVE_SSH_HOST" || -z "$PVE_SSH_PASSWORD" ]]; then
  cat > "$REPORT_DIR/pve-not-configured.md" <<EOF
# PVE Backup Status

PVE backup is not configured yet.

Expected future inputs:
- PVE_ENABLED=1
- PVE_SSH_HOST=<ssh-host-or-alias>
- PVE_SSH_PASSWORD=<password>
EOF
  log "collect_pve: not configured"
  exit 0
fi

HOSTNAME_OUT="$(sshpass -p "$PVE_SSH_PASSWORD" ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/tmp/openclaw_known_hosts -o ConnectTimeout=8 "$PVE_SSH_USER@$PVE_SSH_HOST" 'hostname' | tr -d '\r')"
UNAME_OUT="$(sshpass -p "$PVE_SSH_PASSWORD" ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/tmp/openclaw_known_hosts -o ConnectTimeout=8 "$PVE_SSH_USER@$PVE_SSH_HOST" 'uname -a' | tr -d '\r')"

cat > "$REPORT_DIR/pve-connectivity-ok.md" <<EOF
# PVE Backup Status

PVE SSH connectivity verified.

- host: $PVE_SSH_HOST
- user: $PVE_SSH_USER
- hostname: $HOSTNAME_OUT
- uname: $UNAME_OUT
EOF
log "collect_pve: connectivity verified for $PVE_SSH_HOST"
