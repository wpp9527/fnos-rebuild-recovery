#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

ACTION="${1:-plan}"
if [[ "$ACTION" != "plan" ]]; then
  echo "unsupported action: $ACTION" >&2
  exit 1
fi

STATE_ROOT="$(restore_state_root)"
SOURCE_MODE="${SOURCE_MODE:-hybrid}"
TS="$(restore_now_ts)"

restore_init_dirs "$STATE_ROOT"
restore_write_context "$STATE_ROOT" "$SOURCE_MODE" "$TS"
restore_write_plan "$STATE_ROOT" "$SOURCE_MODE" "$TS"

echo "[restore] bootstrap plan generated: $STATE_ROOT"
