#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${BACKUP_CONFIG:-$SCRIPT_DIR/../../state/backup/config.env}"

if [[ -f "$CONFIG_FILE" ]]; then
  # shellcheck disable=SC1090
  source "$CONFIG_FILE"
fi

RUN_ARCHIVE=1
export WORKSPACE_ROOT BACKUP_ROOT STAGING_ROOT RUN_ARCHIVE PVE_ENABLED PVE_SSH_HOST FNOS_ENABLED FNOS_SSH_HOST TIMESTAMP

bash "$SCRIPT_DIR/orchestrator.sh"
