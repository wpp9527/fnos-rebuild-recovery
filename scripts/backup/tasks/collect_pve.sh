#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/common.sh
source "$SCRIPT_DIR/../lib/common.sh"

WORKSPACE_ROOT="${WORKSPACE_ROOT:-$(cd "$SCRIPT_DIR/../../.." && pwd)}"
STAGING_ROOT="${STAGING_ROOT:-$WORKSPACE_ROOT/state/backup/staging}"
REPORT_DIR="$STAGING_ROOT/reports"
PVE_STAGE_DIR="$STAGING_ROOT/pve"
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

run_remote() {
  local remote_cmd="$1"
  sshpass -p "$PVE_SSH_PASSWORD" ssh \
    -o StrictHostKeyChecking=no \
    -o UserKnownHostsFile=/tmp/openclaw_known_hosts \
    -o ConnectTimeout=8 \
    "$PVE_SSH_USER@$PVE_SSH_HOST" "$remote_cmd"
}

rm -rf "$PVE_STAGE_DIR"
ensure_dir "$PVE_STAGE_DIR"

HOSTNAME_OUT="$(run_remote 'hostname' | tr -d '\r')"
UNAME_OUT="$(run_remote 'uname -a' | tr -d '\r')"
run_remote 'hostname' > "$PVE_STAGE_DIR/hostname.txt"
run_remote 'uname -a' > "$PVE_STAGE_DIR/uname.txt"
run_remote 'ip -br addr || ip addr' > "$PVE_STAGE_DIR/ip-address.txt"
run_remote 'pveversion -v || pveversion' > "$PVE_STAGE_DIR/pve-version.txt"
run_remote 'qm list || true' > "$PVE_STAGE_DIR/vm-list.txt"
run_remote 'pct list || true' > "$PVE_STAGE_DIR/ct-list.txt"
run_remote 'pvesm status || true' > "$PVE_STAGE_DIR/storage-list.txt"
run_remote 'cat /etc/network/interfaces' > "$PVE_STAGE_DIR/network-interfaces.txt"

# Collect /etc/pve configuration
run_remote 'mkdir -p /tmp/pve-backup && cp -r /etc/pve/* /tmp/pve-backup/ 2>/dev/null || true' || true
run_remote 'tar -czf /tmp/pve-config.tar.gz -C /tmp/pve-backup . 2>/dev/null || true' || true
sshpass -p "$PVE_SSH_PASSWORD" scp \
  -o StrictHostKeyChecking=no \
  -o UserKnownHostsFile=/tmp/openclaw_known_hosts \
  "$PVE_SSH_USER@$PVE_SSH_HOST:/tmp/pve-config.tar.gz" "$PVE_STAGE_DIR/pve-config.tar.gz" 2>/dev/null || true
run_remote 'rm -rf /tmp/pve-backup /tmp/pve-config.tar.gz' || true

cat > "$PVE_STAGE_DIR/restore-notes.md" <<EOF
# PVE Restore Notes

Generated: $(date -Is)
Source host: $PVE_SSH_HOST

Collected in this phase:
- hostname
- uname
- IP addressing
- pveversion
- VM list
- CT list
- storage status
- /etc/network/interfaces

Next upgrade target:
- pve-config.tar.gz contains /etc/pve exports
EOF

cat > "$REPORT_DIR/pve-connectivity-ok.md" <<EOF
# PVE Backup Status

PVE SSH connectivity verified.

- host: $PVE_SSH_HOST
- user: $PVE_SSH_USER
- hostname: $HOSTNAME_OUT
- uname: $UNAME_OUT
- stage_path: $PVE_STAGE_DIR
EOF
log "collect_pve: connectivity and inventory captured for $PVE_SSH_HOST"
