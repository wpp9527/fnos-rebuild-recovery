#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

REPORT_DIR="$TMP/staging/reports"
mkdir -p "$REPORT_DIR"

PVE_ENABLED=1 \
PVE_SSH_HOST='192.168.1.190' \
PVE_SSH_USER='root' \
PVE_SSH_PASSWORD='wp930803' \
STAGING_ROOT="$TMP/staging" \
bash "$ROOT/scripts/backup/tasks/collect_pve.sh"

[[ -f "$REPORT_DIR/pve-connectivity-ok.md" ]] || { echo 'missing pve connectivity report' >&2; exit 1; }
grep -Fq 'hostname: pve' "$REPORT_DIR/pve-connectivity-ok.md" || { echo 'missing pve hostname in report' >&2; exit 1; }

echo 'PASS test_pve_ssh_connectivity_only'
