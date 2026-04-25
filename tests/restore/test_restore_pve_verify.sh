#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
RESTORE_STATE_ROOT="$TMP/state/restore"
RESTORE_TARGET_ROOT="$TMP/target"
mkdir -p "$RESTORE_STATE_ROOT/reports" "$RESTORE_TARGET_ROOT/pve"
echo 'pvehost' > "$RESTORE_TARGET_ROOT/pve/hostname.txt"
echo 'Linux' > "$RESTORE_TARGET_ROOT/pve/uname.txt"
echo 'vmid name' > "$RESTORE_TARGET_ROOT/pve/vm-list.txt"
echo 'iface' > "$RESTORE_TARGET_ROOT/pve/network-interfaces.txt"
OUT="$(RESTORE_STATE_ROOT="$RESTORE_STATE_ROOT" RESTORE_TARGET_ROOT="$RESTORE_TARGET_ROOT" bash "$ROOT/restore/layers/10-pve.sh" verify)"
printf '%s' "$OUT" | grep -Fq 'pve verify PASS' || { echo 'pve verify did not pass' >&2; exit 1; }
REPORT="$(find "$RESTORE_STATE_ROOT/reports" -maxdepth 1 -name 'pve-verify-*.md' | head -n 1)"
[[ -f "$REPORT" ]] || { echo 'missing pve verify report' >&2; exit 1; }
grep -Fq 'PASS' "$REPORT" || { echo 'pve verify report missing PASS' >&2; exit 1; }
echo 'PASS test_restore_pve_verify'
