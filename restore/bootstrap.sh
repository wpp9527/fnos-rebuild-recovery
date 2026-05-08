#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

ACTION="${1:-plan}"
shift || true
if [[ "$ACTION" != "plan" ]]; then
  echo "unsupported action: $ACTION" >&2
  exit 1
fi

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

echo "[restore] bootstrap plan generated: $STATE_ROOT"
echo "[restore] selected source: $SOURCE_SELECTED"
