#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/common.sh
source "$SCRIPT_DIR/../lib/common.sh"

ACTION="${1:-preflight}"
STATE_ROOT="$(restore_state_root)"
TARGET_ROOT="${RESTORE_TARGET_ROOT:-$STATE_ROOT/target}"
SECRETS_TEMPLATE_PATH="${SECRETS_TEMPLATE_PATH:-$(cd "$SCRIPT_DIR/.." && pwd)/templates/secrets/.env.example}"
SECRETS_REAL_DIR="${SECRETS_REAL_DIR:-/mnt/nas/backup/shared/secrets/latest/openclaw}"
TS="$(restore_now_ts)"

restore_init_dirs "$STATE_ROOT"

run_check() {
  local script="$1"
  bash "$script"
}

preflight() {
  local host_out github_out nas_out secrets_out
  host_out="$(FORCE_GITHUB_ACCESS="${FORCE_GITHUB_ACCESS:-}" FORCE_NAS_ACCESS="${FORCE_NAS_ACCESS:-}" run_check "$SCRIPT_DIR/../checks/check-host-prereqs.sh")"
  github_out="$(FORCE_GITHUB_ACCESS="${FORCE_GITHUB_ACCESS:-}" FORCE_NAS_ACCESS="${FORCE_NAS_ACCESS:-}" run_check "$SCRIPT_DIR/../checks/check-github-access.sh")"
  nas_out="$(FORCE_GITHUB_ACCESS="${FORCE_GITHUB_ACCESS:-}" FORCE_NAS_ACCESS="${FORCE_NAS_ACCESS:-}" run_check "$SCRIPT_DIR/../checks/check-nas-access.sh")"
  secrets_out="$(FORCE_GITHUB_ACCESS="${FORCE_GITHUB_ACCESS:-}" FORCE_NAS_ACCESS="${FORCE_NAS_ACCESS:-}" run_check "$SCRIPT_DIR/../checks/check-secrets.sh")"

  echo 'PRECHECK SUMMARY'
  echo "$host_out"
  echo "$github_out"
  echo "$nas_out"
  echo "$secrets_out"

  if [[ "${FORCE_GITHUB_ACCESS:-}" == "0" && "${FORCE_NAS_ACCESS:-}" == "0" ]]; then
    echo 'BLOCK no restore source available' >&2
    exit 1
  fi
}

verify_layer_fnos() {
  RESTORE_STATE_ROOT="$STATE_ROOT" RESTORE_TARGET_ROOT="$TARGET_ROOT" bash "$SCRIPT_DIR/20-fnos.sh" verify >/dev/null
}

verify_layer_openclaw() {
  RESTORE_STATE_ROOT="$STATE_ROOT" RESTORE_TARGET_ROOT="$TARGET_ROOT" bash "$SCRIPT_DIR/40-openclaw.sh" verify >/dev/null
}

verify_layer_secrets() {
  RESTORE_STATE_ROOT="$STATE_ROOT" RESTORE_TARGET_ROOT="$TARGET_ROOT" SECRETS_TEMPLATE_PATH="$SECRETS_TEMPLATE_PATH" SECRETS_REAL_DIR="$SECRETS_REAL_DIR" bash "$SCRIPT_DIR/50-secrets.sh" verify >/dev/null
}

verify() {
  local fnos_status="PASS" openclaw_status="PASS" secrets_status="PASS" overall="PASS"

  verify_layer_fnos || fnos_status="FAIL"
  verify_layer_openclaw || openclaw_status="FAIL"
  verify_layer_secrets || secrets_status="FAIL"

  [[ "$fnos_status" == "PASS" ]] || overall="FAIL"
  [[ "$openclaw_status" == "PASS" ]] || overall="FAIL"
  [[ "$secrets_status" == "PASS" ]] || overall="FAIL"

  local summary="$STATE_ROOT/reports/verification-summary-$TS.md"
  local result="$STATE_ROOT/reports/verification-result-$TS.json"

  cat > "$summary" <<EOF
# Verification Summary

- fnos: $fnos_status
- openclaw: $openclaw_status
- secrets: $secrets_status
- overall: $overall
EOF

  cat > "$result" <<EOF
{
  "fnos": "$fnos_status",
  "openclaw": "$openclaw_status",
  "secrets": "$secrets_status",
  "overall_status": "$overall"
}
EOF

  if [[ "$overall" == "PASS" ]]; then
    echo "verify summary PASS: $summary"
  else
    echo "verify summary FAIL: $summary" >&2
    exit 1
  fi
}

case "$ACTION" in
  preflight) preflight ;;
  verify) verify ;;
  *)
    echo "unsupported action: $ACTION" >&2
    exit 1
    ;;
esac
