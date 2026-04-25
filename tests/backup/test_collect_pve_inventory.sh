#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

STAGING_ROOT="$TMP/staging"
REPORT_DIR="$STAGING_ROOT/reports"
mkdir -p "$REPORT_DIR"

PVE_ENABLED=1 \
PVE_SSH_HOST='192.168.1.190' \
PVE_SSH_USER='root' \
PVE_SSH_PASSWORD='wp930803' \
STAGING_ROOT="$STAGING_ROOT" \
bash "$ROOT/scripts/backup/tasks/collect_pve.sh"

PVE_STAGE="$STAGING_ROOT/pve"
REPORT="$REPORT_DIR/pve-connectivity-ok.md"

[[ -f "$PVE_STAGE/hostname.txt" ]] || { echo 'missing pve hostname.txt' >&2; exit 1; }
[[ -f "$PVE_STAGE/uname.txt" ]] || { echo 'missing pve uname.txt' >&2; exit 1; }
[[ -f "$PVE_STAGE/ip-address.txt" ]] || { echo 'missing pve ip-address.txt' >&2; exit 1; }
[[ -f "$PVE_STAGE/pve-version.txt" ]] || { echo 'missing pve version info' >&2; exit 1; }
[[ -f "$PVE_STAGE/vm-list.txt" ]] || { echo 'missing pve vm list' >&2; exit 1; }
[[ -f "$PVE_STAGE/storage-list.txt" ]] || { echo 'missing pve storage list' >&2; exit 1; }
[[ -f "$PVE_STAGE/network-interfaces.txt" ]] || { echo 'missing pve network interfaces' >&2; exit 1; }
[[ -f "$PVE_STAGE/restore-notes.md" ]] || { echo 'missing pve restore notes' >&2; exit 1; }
[[ -f "$REPORT" ]] || { echo 'missing pve report' >&2; exit 1; }

grep -Fq 'pve' "$PVE_STAGE/hostname.txt" || { echo 'unexpected hostname content' >&2; exit 1; }
grep -Eq 'vmid|VMID|NAME' "$PVE_STAGE/vm-list.txt" || { echo 'vm list lacks expected headers/content' >&2; exit 1; }
grep -Eq 'dir|lvm|zfspool|storage' "$PVE_STAGE/storage-list.txt" || { echo 'storage list lacks expected content' >&2; exit 1; }

echo 'PASS test_collect_pve_inventory'
