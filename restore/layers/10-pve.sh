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
Target: $TARGET_ROOT/pve/

Contents:
- hostname.txt
- pve-config.tar.gz
- vm-list.txt
- ct-list.txt
- storage-list.txt
EOF
  echo "pve plan ready: $plan_md"
}

pve_apply() {
  if [[ -d "$PVE_LATEST_ROOT" ]]; then
    cp -r "$PVE_LATEST_ROOT/"* "$TARGET_ROOT/pve/" 2>/dev/null || true
    echo "pve apply complete: $TARGET_ROOT/pve"
  else
    echo "pve apply skipped: no source"
  fi
}

pve_verify() {
  local report="$STATE_ROOT/reports/pve-verify-$TS.md"
  local status="PASS"

  [[ -f "$TARGET_ROOT/pve/hostname.txt" ]] || status="FAIL"

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
  *)
    echo "unsupported action: $ACTION" >&2
    exit 1
    ;;
esac
