#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/common.sh
source "$SCRIPT_DIR/../lib/common.sh"

ACTION="${1:-plan}"
STATE_ROOT="$(restore_state_root)"
TARGET_ROOT="${RESTORE_TARGET_ROOT:-$STATE_ROOT/target}"
OPENCLAW_LATEST_ROOT="${OPENCLAW_LATEST_ROOT:-/mnt/nas/backup/services/openclaw/latest}"
TS="$(restore_now_ts)"

restore_init_dirs "$STATE_ROOT"
restore_ensure_dir "$TARGET_ROOT"

openclaw_plan() {
  local plan_md="$STATE_ROOT/plans/openclaw-plan-$TS.md"
  cat > "$plan_md" <<EOF
# OpenClaw Restore Plan

Source: $OPENCLAW_LATEST_ROOT
Target: $TARGET_ROOT/openclaw

Expected restore roots:
- docs/
- scripts/backup/
- memory/

Detected source content:
$(find "$OPENCLAW_LATEST_ROOT" -maxdepth 3 -mindepth 1 2>/dev/null | sed 's#^#- #' | sed -n '1,80p')
EOF
  echo "openclaw plan ready: $plan_md"
}

copy_tree_if_exists() {
  local src_rel="$1"
  local dst_rel="$2"
  local src="$OPENCLAW_LATEST_ROOT/$src_rel"
  local dst="$TARGET_ROOT/openclaw/$dst_rel"
  if [[ -d "$src" ]]; then
    restore_ensure_dir "$dst"
    cp -a "$src/." "$dst/"
  fi
}

openclaw_apply() {
  restore_ensure_dir "$TARGET_ROOT/openclaw/docs"
  restore_ensure_dir "$TARGET_ROOT/openclaw/scripts/backup"
  restore_ensure_dir "$TARGET_ROOT/openclaw/memory"

  copy_tree_if_exists "docs" "docs"
  copy_tree_if_exists "scripts/backup" "scripts/backup"
  copy_tree_if_exists "memory" "memory"

  if [[ -f "$TARGET_ROOT/openclaw/scripts/backup/run.sh" ]]; then
    chmod +x "$TARGET_ROOT/openclaw/scripts/backup/run.sh"
  fi

  echo "openclaw apply complete: $TARGET_ROOT/openclaw"
}

openclaw_verify() {
  local report="$STATE_ROOT/reports/openclaw-verify-$TS.md"
  local status="PASS"

  [[ -d "$TARGET_ROOT/openclaw/docs" ]] || status="FAIL"
  [[ -d "$TARGET_ROOT/openclaw/scripts/backup" ]] || status="FAIL"
  [[ -d "$TARGET_ROOT/openclaw/memory" ]] || status="FAIL"
  [[ -f "$TARGET_ROOT/openclaw/docs/restore.md" ]] || status="FAIL"
  [[ -f "$TARGET_ROOT/openclaw/scripts/backup/run.sh" ]] || status="FAIL"
  [[ -x "$TARGET_ROOT/openclaw/scripts/backup/run.sh" ]] || status="FAIL"
  [[ -f "$TARGET_ROOT/openclaw/memory/notes.md" ]] || status="FAIL"

  cat > "$report" <<EOF
# OpenClaw Verify

Status: $status
Target: $TARGET_ROOT/openclaw
EOF

  if [[ "$status" == "PASS" ]]; then
    echo "openclaw verify PASS: $report"
  else
    echo "openclaw verify FAIL: $report" >&2
    exit 1
  fi
}

case "$ACTION" in
  plan) openclaw_plan ;;
  apply) openclaw_apply ;;
  verify) openclaw_verify ;;
  *)
    echo "unsupported action: $ACTION" >&2
    exit 1
    ;;
esac
