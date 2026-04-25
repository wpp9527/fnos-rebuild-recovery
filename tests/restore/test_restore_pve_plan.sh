#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
RESTORE_STATE_ROOT="$TMP/state/restore"
PVE_LATEST_ROOT="$TMP/pve-latest"
mkdir -p "$RESTORE_STATE_ROOT" "$PVE_LATEST_ROOT"
echo 'pvehost' > "$PVE_LATEST_ROOT/hostname.txt"
echo 'Linux' > "$PVE_LATEST_ROOT/uname.txt"
echo 'vmid name' > "$PVE_LATEST_ROOT/vm-list.txt"
echo 'iface' > "$PVE_LATEST_ROOT/network-interfaces.txt"
OUT="$(RESTORE_STATE_ROOT="$RESTORE_STATE_ROOT" PVE_LATEST_ROOT="$PVE_LATEST_ROOT" bash "$ROOT/restore/layers/10-pve.sh" plan)"
printf '%s' "$OUT" | grep -Fq 'pve plan ready' || { echo 'missing pve plan output' >&2; exit 1; }
PLAN_MD="$(find "$RESTORE_STATE_ROOT/plans" -maxdepth 1 -name 'pve-plan-*.md' | head -n 1)"
[[ -f "$PLAN_MD" ]] || { echo 'missing pve plan markdown' >&2; exit 1; }
grep -Fq 'vm-list.txt' "$PLAN_MD" || { echo 'plan missing vm-list reference' >&2; exit 1; }
echo 'PASS test_restore_pve_plan'
