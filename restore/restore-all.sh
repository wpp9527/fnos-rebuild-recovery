#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

ACTION="${1:-plan}"
shift || true
case "$ACTION" in
  plan|apply|verify) ;;
  *)
    echo "unsupported action: $ACTION" >&2
    exit 1
    ;;
esac

SOURCE_MODE="${SOURCE_MODE:-hybrid}"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --source)
      SOURCE_MODE="${2:-}"
      shift 2
      ;;
    *)
      echo "unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

STATE_ROOT="$(restore_state_root)"
TS="$(restore_now_ts)"
GITHUB_ACCESS="$(restore_detect_github_access)"
NAS_ACCESS="$(restore_detect_nas_access)"

if ! SOURCE_SELECTED="$(restore_select_source "$SOURCE_MODE" "$GITHUB_ACCESS" "$NAS_ACCESS")"; then
  echo "BLOCK no restore source available for mode=$SOURCE_MODE" >&2
  exit 1
fi

restore_init_dirs "$STATE_ROOT"
restore_write_context "$STATE_ROOT" "$SOURCE_MODE" "$SOURCE_SELECTED" "$GITHUB_ACCESS" "$NAS_ACCESS" "$TS"
restore_write_plan "$STATE_ROOT" "$SOURCE_MODE" "$SOURCE_SELECTED" "$TS"

case "$ACTION" in
  plan)
    restore_write_report "$STATE_ROOT" "$SOURCE_MODE" "$SOURCE_SELECTED" "$TS" "plan" "planned"
    echo "[restore] restore-all plan generated: $STATE_ROOT"
    echo "[restore] selected source: $SOURCE_SELECTED"
    ;;
  apply)
    PVE_LATEST_ROOT="${PVE_LATEST_ROOT:-/mnt/nas/backup/pve/latest}"
    RESTORE_STATE_ROOT="$STATE_ROOT" RESTORE_TARGET_ROOT="${RESTORE_TARGET_ROOT:-$STATE_ROOT/target}" PVE_LATEST_ROOT="$PVE_LATEST_ROOT" bash "$SCRIPT_DIR/layers/10-pve.sh" apply
    RESTORE_STATE_ROOT="$STATE_ROOT" RESTORE_TARGET_ROOT="${RESTORE_TARGET_ROOT:-$STATE_ROOT/target}" FNOS_LATEST_ROOT="${FNOS_LATEST_ROOT:-/mnt/nas/backup/fnos/latest}" bash "$SCRIPT_DIR/layers/20-fnos.sh" apply
    RESTORE_STATE_ROOT="$STATE_ROOT" RESTORE_TARGET_ROOT="${RESTORE_TARGET_ROOT:-$STATE_ROOT/target}" OPENCLAW_LATEST_ROOT="${OPENCLAW_LATEST_ROOT:-/mnt/nas/backup/services/openclaw/latest}" bash "$SCRIPT_DIR/layers/40-openclaw.sh" apply
    RESTORE_STATE_ROOT="$STATE_ROOT" RESTORE_TARGET_ROOT="${RESTORE_TARGET_ROOT:-$STATE_ROOT/target}" SECRETS_TEMPLATE_PATH="${SECRETS_TEMPLATE_PATH:-$SCRIPT_DIR/templates/secrets/.env.example}" SECRETS_REAL_DIR="${SECRETS_REAL_DIR:-/mnt/nas/backup/shared/secrets/latest/openclaw}" bash "$SCRIPT_DIR/layers/50-secrets.sh" apply
    RESTORE_STATE_ROOT="$STATE_ROOT" RESTORE_TARGET_ROOT="${RESTORE_TARGET_ROOT:-$STATE_ROOT/target}" bash "$SCRIPT_DIR/layers/30-services.sh" apply
    restore_write_report "$STATE_ROOT" "$SOURCE_MODE" "$SOURCE_SELECTED" "$TS" "apply" "PASS"
    echo "restore-all apply complete: $STATE_ROOT"
    ;;
  verify)
    RESTORE_STATE_ROOT="$STATE_ROOT" RESTORE_TARGET_ROOT="${RESTORE_TARGET_ROOT:-$STATE_ROOT/target}" PVE_LATEST_ROOT="${PVE_LATEST_ROOT:-/mnt/nas/backup/pve/latest}" bash "$SCRIPT_DIR/layers/10-pve.sh" verify >/dev/null
    RESTORE_STATE_ROOT="$STATE_ROOT" RESTORE_TARGET_ROOT="${RESTORE_TARGET_ROOT:-$STATE_ROOT/target}" bash "$SCRIPT_DIR/layers/90-verify.sh" verify >/dev/null
    restore_write_report "$STATE_ROOT" "$SOURCE_MODE" "$SOURCE_SELECTED" "$TS" "verify" "PASS"
    echo "restore-all verify PASS: $STATE_ROOT"
    ;;
esac
