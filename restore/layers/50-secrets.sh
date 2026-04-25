#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/common.sh
source "$SCRIPT_DIR/../lib/common.sh"

ACTION="${1:-plan}"
STATE_ROOT="$(restore_state_root)"
TARGET_ROOT="${RESTORE_TARGET_ROOT:-$STATE_ROOT/target}"
SECRETS_TEMPLATE_PATH="${SECRETS_TEMPLATE_PATH:-$(cd "$SCRIPT_DIR/.." && pwd)/templates/secrets/.env.example}"
SECRETS_REAL_DIR="${SECRETS_REAL_DIR:-/mnt/nas/backup/shared/secrets/latest/openclaw}"
TS="$(restore_now_ts)"

restore_init_dirs "$STATE_ROOT"
restore_ensure_dir "$TARGET_ROOT/openclaw"

read_real_value() {
  local key="$1"
  local env_file="$SECRETS_REAL_DIR/openclaw.env"
  if [[ -f "$env_file" ]]; then
    awk -F= -v k="$key" '$1 == k { sub($1"=", ""); print }' "$env_file" | tail -n 1
  fi
}

required_keys() {
  printf '%s\n' OPENCLAW_BASE_URL OPENCLAW_API_TOKEN PRIMARY_CHANNEL_TOKEN
}

blocking_keys() {
  printf '%s\n' OPENCLAW_API_TOKEN
}

secrets_plan() {
  echo "secrets plan ready: template=$SECRETS_TEMPLATE_PATH real_dir=$SECRETS_REAL_DIR"
}

secrets_apply() {
  local target_env="$TARGET_ROOT/openclaw/.env"
  local missing=0
  : > "$target_env"

  while IFS= read -r key; do
    [[ -n "$key" ]] || continue
    local value
    value="$(read_real_value "$key")"
    if [[ -z "$value" ]]; then
      if printf '%s\n' "$(blocking_keys)" | grep -Fxq "$key"; then
        echo "BLOCK missing blocking secret: $key" >&2
        missing=1
      fi
      echo "$key=" >> "$target_env"
    else
      echo "$key=$value" >> "$target_env"
    fi
  done < <(cut -d= -f1 "$SECRETS_TEMPLATE_PATH")

  chmod 600 "$target_env"

  if [[ "$missing" -ne 0 ]]; then
    exit 1
  fi

  echo "secrets apply complete: $target_env"
}

secrets_verify() {
  local report="$STATE_ROOT/reports/secrets-verify-$TS.md"
  local status="PASS"
  {
    echo "# Secrets Verify"
    echo
    while IFS= read -r key; do
      [[ -n "$key" ]] || continue
      value="$(read_real_value "$key")"
      if [[ -n "$value" ]]; then
        echo "$key: present"
      else
        echo "$key: missing"
        if printf '%s\n' "$(blocking_keys)" | grep -Fxq "$key"; then
          status="FAIL"
        fi
      fi
    done < <(cut -d= -f1 "$SECRETS_TEMPLATE_PATH")
    echo
    echo "Status: $status"
  } > "$report"

  if [[ "$status" == "PASS" ]]; then
    echo "secrets verify PASS: $report"
  else
    echo "secrets verify FAIL: $report" >&2
    exit 1
  fi
}

case "$ACTION" in
  plan) secrets_plan ;;
  apply) secrets_apply ;;
  verify) secrets_verify ;;
  *)
    echo "unsupported action: $ACTION" >&2
    exit 1
    ;;
esac
