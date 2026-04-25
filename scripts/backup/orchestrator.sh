#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

WORKSPACE_ROOT="${WORKSPACE_ROOT:-$(cd "$SCRIPT_DIR/../.." && pwd)}"
BACKUP_ROOT="${BACKUP_ROOT:-/mnt/nas/backup}"
STAGING_ROOT="${STAGING_ROOT:-$WORKSPACE_ROOT/state/backup/staging}"
RUN_ARCHIVE="${RUN_ARCHIVE:-0}"

require_dir "$WORKSPACE_ROOT"
require_dir "$BACKUP_ROOT"
ensure_dir "$STAGING_ROOT"

log "orchestrator start"
WORKSPACE_ROOT="$WORKSPACE_ROOT" STAGING_ROOT="$STAGING_ROOT" bash "$SCRIPT_DIR/tasks/collect_openclaw.sh"
WORKSPACE_ROOT="$WORKSPACE_ROOT" STAGING_ROOT="$STAGING_ROOT" PVE_ENABLED="${PVE_ENABLED:-0}" PVE_SSH_HOST="${PVE_SSH_HOST:-}" bash "$SCRIPT_DIR/tasks/collect_pve.sh"
WORKSPACE_ROOT="$WORKSPACE_ROOT" STAGING_ROOT="$STAGING_ROOT" FNOS_ENABLED="${FNOS_ENABLED:-0}" FNOS_SSH_HOST="${FNOS_SSH_HOST:-}" bash "$SCRIPT_DIR/tasks/collect_fnos.sh"
WORKSPACE_ROOT="$WORKSPACE_ROOT" STAGING_ROOT="$STAGING_ROOT" BACKUP_ROOT="$BACKUP_ROOT" TIMESTAMP="${TIMESTAMP:-}" bash "$SCRIPT_DIR/tasks/publish_latest.sh"

if [[ "$RUN_ARCHIVE" == "1" ]]; then
  WORKSPACE_ROOT="$WORKSPACE_ROOT" BACKUP_ROOT="$BACKUP_ROOT" TIMESTAMP="${TIMESTAMP:-}" bash "$SCRIPT_DIR/tasks/archive_snapshot.sh"
fi

log "orchestrator done"
