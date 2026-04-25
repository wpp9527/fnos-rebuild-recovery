#!/usr/bin/env bash
set -euo pipefail

restore_now_ts() {
  date +%Y-%m-%d-%H%M%S
}

restore_state_root() {
  printf '%s\n' "${RESTORE_STATE_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/state/restore}"
}

restore_ensure_dir() {
  mkdir -p "$1"
}

restore_init_dirs() {
  local root="$1"
  restore_ensure_dir "$root"
  restore_ensure_dir "$root/plans"
  restore_ensure_dir "$root/reports"
}

restore_write_context() {
  local root="$1"
  local mode="$2"
  local ts="$3"
  cat > "$root/context.env" <<EOF
RESTORE_STATE_ROOT=$root
SOURCE_MODE=$mode
RESTORE_TIMESTAMP=$ts
EOF
}

restore_write_plan() {
  local root="$1"
  local mode="$2"
  local ts="$3"
  cat > "$root/plans/restore-plan-$ts.md" <<EOF
# Restore Plan

- mode: plan
- source: $mode
- timestamp: $ts
EOF
  cat > "$root/plans/restore-plan-$ts.json" <<EOF
{
  "mode": "plan",
  "source_mode": "$mode",
  "timestamp": "$ts"
}
EOF
}

restore_write_report() {
  local root="$1"
  local mode="$2"
  local ts="$3"
  cat > "$root/reports/restore-summary-$ts.md" <<EOF
# Restore Summary

- mode: plan
- source: $mode
- timestamp: $ts
EOF
  cat > "$root/reports/restore-result-$ts.json" <<EOF
{
  "mode": "plan",
  "source_mode": "$mode",
  "timestamp": "$ts",
  "status": "planned"
}
EOF
}
