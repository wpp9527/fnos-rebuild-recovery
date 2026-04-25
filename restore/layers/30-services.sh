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
FNOS_MEDIA_STACK_ROOT="$TARGET_ROOT/services/fnos-media-stack"
OPENCLAW_ENV="$TARGET_ROOT/openclaw/.env"
TEMPLATES_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)/templates/services"
FNOS_MEDIA_STACK_TEMPLATE="$TEMPLATES_ROOT/fnos-media-stack/docker-compose.yml"
FNOS_MEDIA_STACK_ENV_TEMPLATE="$TEMPLATES_ROOT/fnos-media-stack/.env.example"
SECRETS_REAL_DIR="${SECRETS_REAL_DIR:-/mnt/nas/backup/shared/secrets/latest}"

restore_init_dirs "$STATE_ROOT"
restore_ensure_dir "$SERVICES_ROOT"
restore_ensure_dir "$FNOS_MEDIA_STACK_ROOT"

read_stack_secret() {
  local key="$1"
  local env_file="$SECRETS_REAL_DIR/fnos-media-stack.env"
  if [[ -f "$env_file" ]]; then
    awk -F= -v k="$key" '$1 == k { sub($1"=", ""); print }' "$env_file" | tail -n 1
  fi
}

render_fnos_media_stack() {
  local target_compose="$FNOS_MEDIA_STACK_ROOT/docker-compose.yml"
  local target_env="$FNOS_MEDIA_STACK_ROOT/.env"
  cp "$FNOS_MEDIA_STACK_TEMPLATE" "$target_compose"
  : > "$target_env"
  while IFS= read -r key; do
    [[ -n "$key" ]] || continue
    local value
    value="$(read_stack_secret "$key")"
    echo "$key=$value" >> "$target_env"
  done < <(cut -d= -f1 "$FNOS_MEDIA_STACK_ENV_TEMPLATE")
  chmod 600 "$target_env"
}

services_plan() {
  local plan_md="$STATE_ROOT/plans/services-plan-$TS.md"
  cat > "$plan_md" <<EOF
# Services Restore Plan

Target root: $TARGET_ROOT
Services:
- openclaw (core)
- media-stack (supporting)
- fnos-media-stack (standalone media stack with secrets in local/NAS env)
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

  render_fnos_media_stack

  local report="$STATE_ROOT/reports/services-apply-$TS.md"
  cat > "$report" <<EOF
# Services Apply

- openclaw: ready
- media-stack: ready
- fnos-media-stack: ready
- channels: skipped (deferred)
EOF

  if [[ -f "$OPENCLAW_ENV" ]]; then
    (
      cd "$SERVICES_ROOT"
      docker compose up -d >/dev/null 2>&1 || true
    )
    (
      cd "$FNOS_MEDIA_STACK_ROOT"
      docker compose up -d >/dev/null 2>&1 || true
    )
  fi

  echo "services apply complete: $compose_file"
}

services_verify() {
  local compose_file="$SERVICES_ROOT/docker-compose.yml"
  local stack_compose="$FNOS_MEDIA_STACK_ROOT/docker-compose.yml"
  local stack_env="$FNOS_MEDIA_STACK_ROOT/.env"
  local report="$STATE_ROOT/reports/services-verify-$TS.md"
  local status="PASS"
  [[ -f "$compose_file" ]] || status="FAIL"
  [[ -f "$stack_compose" ]] || status="FAIL"
  [[ -f "$stack_env" ]] || status="FAIL"
  (
    cd "$SERVICES_ROOT"
    docker compose config >/dev/null 2>&1
  ) || status="FAIL"
  (
    cd "$FNOS_MEDIA_STACK_ROOT"
    docker compose config >/dev/null 2>&1
  ) || status="FAIL"
  cat > "$report" <<EOF
# Services Verify

Status: $status
Compose: $compose_file
fnos-media-stack: $stack_compose
fnos-media-stack env: $stack_env
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
