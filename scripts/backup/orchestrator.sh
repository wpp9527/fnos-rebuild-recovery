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
WORKSPACE_ROOT="$WORKSPACE_ROOT" STAGING_ROOT="$STAGING_ROOT" BACKUP_ROOT="$BACKUP_ROOT" bash "$SCRIPT_DIR/tasks/publish_latest.sh"

if [[ "$RUN_ARCHIVE" == "1" ]]; then
  log "archive step not implemented yet"
fi

log "orchestrator done"
