#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/common.sh
source "$SCRIPT_DIR/../lib/common.sh"

ACTION="${1:-plan}"
STATE_ROOT="$(restore_state_root)"
TARGET_ROOT="${RESTORE_TARGET_ROOT:-$STATE_ROOT/target}"
TS="$(restore_now_ts)"

restore_init_dirs "$STATE_ROOT"

services_plan() {
  local plan_md="$STATE_ROOT/plans/services-plan-$TS.md"
  cat > "$plan_md" <<EOF
# Services Restore Plan

Target: $TARGET_ROOT/config/

Will restore:
- fnos-media-stack/docker-compose.yml
- fnos-media-stack/.env (merged with secrets)
EOF
  echo "services plan ready: $plan_md"
}

services_apply() {
  local stack_dir="$TARGET_ROOT/config/fnos-media-stack"
  restore_ensure_dir "$stack_dir"
  
  # Copy template compose
  local template_compose="$SCRIPT_DIR/../templates/services/fnos-media-stack/docker-compose.yml"
  if [[ -f "$template_compose" ]]; then
    cp "$template_compose" "$stack_dir/docker-compose.yml"
  fi
  
  # Merge secrets into .env
  local env_file="$stack_dir/.env"
  {
    echo "# fnos-media-stack environment"
    echo "# Generated: $(date -Is)"
    echo
    # Include secrets if available
    if [[ -f "$TARGET_ROOT/config/fnos-media-stack.env" ]]; then
      cat "$TARGET_ROOT/config/fnos-media-stack.env"
    fi
  } > "$env_file"
  
  chmod 600 "$env_file"
  
  echo "services apply complete: $stack_dir"
}

services_verify() {
  local report="$STATE_ROOT/reports/services-verify-$TS.md"
  local status="PASS"
  
  [[ -f "$TARGET_ROOT/config/fnos-media-stack/docker-compose.yml" ]] || status="FAIL"
  [[ -f "$TARGET_ROOT/config/fnos-media-stack/.env" ]] || status="FAIL"
  
  cat > "$report" <<EOF
# Services Verify

Status: $status
Target: $TARGET_ROOT/config/fnos-media-stack
EOF

  if [[ "$status" == "PASS" ]]; then
    echo "services verify PASS: $report"
  else
    echo "services verify FAIL: $report" >&2
    exit 1
  fi
}

case "$ACTION" in
  plan) services_plan ;;
  apply) services_apply ;;
  verify) services_verify ;;
  *)
    echo "unsupported action: $ACTION" >&2
    exit 1
    ;;
esac
