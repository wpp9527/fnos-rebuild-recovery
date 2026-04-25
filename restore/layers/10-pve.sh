#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/common.sh
source "$SCRIPT_DIR/../lib/common.sh"

ACTION="${1:-plan}"
STATE_ROOT="$(restore_state_root)"
TARGET_ROOT="${RESTORE_TARGET_ROOT:-$STATE_ROOT/target}"
PVE_LATEST_ROOT="${PVE_LATEST_ROOT:-/mnt/nas/backup/pve/latest}"
TS="$(restore_now_ts)"
restore_init_dirs "$STATE_ROOT"
restore_ensure_dir "$TARGET_ROOT/pve"

pve_plan() {
  local plan_md="$STATE_ROOT/plans/pve-plan-$TS.md"
  cat > "$plan_md" <<EOF
# PVE Restore Plan

Source: $PVE_LATEST_ROOT
Target: $TARGET_ROOT/pve

Detected source content:
$(find "$PVE_LATEST_ROOT" -maxdepth 2 -mindepth 1 2>/dev/null | sed 's#^#- #' | sed -n '1,80p')
EOF
  echo "pve plan ready: $plan_md"
}

copy_file_if_exists() {
  local src_rel="$1"
  local src="$PVE_LATEST_ROOT/$src_rel"
  local dst="$TARGET_ROOT/pve/$src_rel"
  if [[ -f "$src" ]]; then
    restore_ensure_dir "$(dirname "$dst")"
    cp -a "$src" "$dst"
  fi
}

pve_apply() {
  copy_file_if_exists hostname.txt
  copy_file_if_exists uname.txt
  copy_file_if_exists vm-list.txt
  copy_file_if_exists network-interfaces.txt
  copy_file_if_exists pve-version.txt
  copy_file_if_exists storage-list.txt
  copy_file_if_exists ct-list.txt
  echo "pve apply complete: $TARGET_ROOT/pve"
}

pve_verify() {
  local report="$STATE_ROOT/reports/pve-verify-$TS.md"
  local status="PASS"
  [[ -f "$TARGET_ROOT/pve/hostname.txt" ]] || status="FAIL"
  [[ -f "$TARGET_ROOT/pve/uname.txt" ]] || status="FAIL"
  [[ -f "$TARGET_ROOT/pve/vm-list.txt" ]] || status="FAIL"
  [[ -f "$TARGET_ROOT/pve/network-interfaces.txt" ]] || status="FAIL"
  cat > "$report" <<EOF
# PVE Verify

Status: $status
Target: $TARGET_ROOT/pve
EOF
  if [[ "$status" == "PASS" ]]; then
    echo "pve verify PASS: $report"
  else
    echo "pve verify FAIL: $report" >&2
    exit 1
  fi
}

case "$ACTION" in
  plan) pve_plan ;;
  apply) pve_apply ;;
  verify) pve_verify ;;
  *) echo "unsupported action: $ACTION" >&2; exit 1 ;;
esac
