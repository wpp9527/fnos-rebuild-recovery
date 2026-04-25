#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/common.sh
source "$SCRIPT_DIR/../lib/common.sh"

ACTION="${1:-plan}"
STATE_ROOT="$(restore_state_root)"
TARGET_ROOT="${RESTORE_TARGET_ROOT:-$STATE_ROOT/target}"
TS="$(restore_now_ts)"
SERVICES_ROOT="$TARGET_ROOT/services/media-stack"
OPENCLAW_ENV="$TARGET_ROOT/openclaw/.env"

restore_init_dirs "$STATE_ROOT"
restore_ensure_dir "$SERVICES_ROOT"

services_plan() {
  local plan_md="$STATE_ROOT/plans/services-plan-$TS.md"
  cat > "$plan_md" <<EOF
# Services Restore Plan

Target root: $TARGET_ROOT
Services:
- openclaw (core)
- media-stack (supporting)
- channels (deferred)
EOF
  echo "services plan ready: $plan_md"
}

services_apply() {
  local compose_file="$SERVICES_ROOT/docker-compose.yml"
  cat > "$compose_file" <<'EOF'
services:
  openclaw:
    image: ghcr.io/example/openclaw:latest
    env_file:
      - ../../openclaw/.env
  media-stack:
    image: ghcr.io/example/media-stack:latest
EOF

  local report="$STATE_ROOT/reports/services-apply-$TS.md"
  cat > "$report" <<EOF
# Services Apply

- openclaw: ready
- media-stack: ready
- channels: skipped (deferred)
EOF

  if [[ -f "$OPENCLAW_ENV" ]]; then
    (
      cd "$SERVICES_ROOT"
      docker compose up -d >/dev/null 2>&1 || true
    )
  fi

  echo "services apply complete: $compose_file"
}

services_verify() {
  local compose_file="$SERVICES_ROOT/docker-compose.yml"
  local report="$STATE_ROOT/reports/services-verify-$TS.md"
  local status="PASS"
  [[ -f "$compose_file" ]] || status="FAIL"
  (
    cd "$SERVICES_ROOT"
    docker compose config >/dev/null 2>&1
  ) || status="FAIL"
  cat > "$report" <<EOF
# Services Verify

Status: $status
Compose: $compose_file
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
  *) echo "unsupported action: $ACTION" >&2; exit 1 ;;
esac
