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

restore_detect_github_access() {
  if [[ "${FORCE_GITHUB_ACCESS:-}" == "1" ]]; then
    echo 1
    return
  fi
  if [[ "${FORCE_GITHUB_ACCESS:-}" == "0" ]]; then
    echo 0
    return
  fi
  echo 1
}

restore_detect_nas_access() {
  if [[ "${FORCE_NAS_ACCESS:-}" == "1" ]]; then
    echo 1
    return
  fi
  if [[ "${FORCE_NAS_ACCESS:-}" == "0" ]]; then
    echo 0
    return
  fi
  if [[ -d /mnt/nas/backup ]]; then
    echo 1
  else
    echo 0
  fi
}

restore_select_source() {
  local mode="$1"
  local github_access="$2"
  local nas_access="$3"

  case "$mode" in
    github)
      [[ "$github_access" == "1" ]] && { echo github; return 0; }
      return 1
      ;;
    nas)
      [[ "$nas_access" == "1" ]] && { echo nas; return 0; }
      return 1
      ;;
    hybrid)
      if [[ "$github_access" == "1" ]]; then
        echo github
        return 0
      fi
      if [[ "$nas_access" == "1" ]]; then
        echo nas
        return 0
      fi
      return 1
      ;;
    *)
      return 1
      ;;
  esac
}

restore_write_context() {
  local root="$1"
  local mode="$2"
  local selected="$3"
  local github_access="$4"
  local nas_access="$5"
  local ts="$6"
  cat > "$root/context.env" <<EOF
RESTORE_STATE_ROOT=$root
SOURCE_MODE=$mode
SOURCE_SELECTED=$selected
GITHUB_ACCESS=$github_access
NAS_ACCESS=$nas_access
RESTORE_TIMESTAMP=$ts
EOF
}

restore_write_plan() {
  local root="$1"
  local mode="$2"
  local selected="$3"
  local ts="$4"
  cat > "$root/plans/restore-plan-$ts.md" <<EOF
# Restore Plan

- mode: plan
- source_mode: $mode
- selected_source: $selected
- timestamp: $ts
EOF
  cat > "$root/plans/restore-plan-$ts.json" <<EOF
{
  "mode": "plan",
  "source_mode": "$mode",
  "selected_source": "$selected",
  "timestamp": "$ts"
}
EOF
}

restore_write_report() {
  local root="$1"
  local source_mode="$2"
  local selected="$3"
  local ts="$4"
  local run_mode="$5"
  local status="$6"
  cat > "$root/reports/restore-summary-$ts.md" <<EOF
# Restore Summary

- mode: $run_mode
- source_mode: $source_mode
- selected_source: $selected
- timestamp: $ts
- status: $status
EOF
  cat > "$root/reports/restore-result-$ts.json" <<EOF
{
  "mode": "$run_mode",
  "source_mode": "$source_mode",
  "selected_source": "$selected",
  "timestamp": "$ts",
  "status": "$status"
}
EOF
}
