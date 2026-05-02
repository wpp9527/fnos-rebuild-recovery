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

# Collect LXC proxy if PVE is enabled
if [[ "${PVE_ENABLED:-0}" == "1" && -n "${PVE_SSH_HOST:-}" ]]; then
  STAGING_ROOT="$STAGING_ROOT/lxc-proxy" \
  BACKUP_ROOT="$BACKUP_ROOT" \
  PVE_SSH_HOST="${PVE_SSH_HOST:-}" \
  PVE_SSH_PASSWORD="${PVE_SSH_PASSWORD:-}" \
  bash "$SCRIPT_DIR/tasks/collect_lxc_proxy.sh" || log "collect_lxc_proxy: failed"
fi
WORKSPACE_ROOT="$WORKSPACE_ROOT" STAGING_ROOT="$STAGING_ROOT" BACKUP_ROOT="$BACKUP_ROOT" TIMESTAMP="${TIMESTAMP:-}" bash "$SCRIPT_DIR/tasks/publish_latest.sh"

# Publish recovery-critical secrets to NAS
OPENCLAW_CONFIG="${OPENCLAW_CONFIG:-/opt/fnos-media/services/openclaw/home/.openclaw/openclaw.json}" \
FNOS_MEDIA_ENV="${FNOS_MEDIA_ENV:-/opt/fnos-media-stack/.env}" \
BACKUP_ROOT="$BACKUP_ROOT" \
bash "$SCRIPT_DIR/tasks/publish_secrets.sh" || log "publish_secrets: skipped or partial"

RUNTIME_AUDIT_STATUS="not-configured"
if [[ -x "$SCRIPT_DIR/audit_runtime_state.sh" ]]; then
  AUDIT_REPORT_ROOT="$BACKUP_ROOT/shared/restore-guides/latest" \
  LIVE_COMPOSE_PATH="${LIVE_COMPOSE_PATH:-/opt/fnos-media-stack/docker-compose.yml}" \
  TEMPLATE_COMPOSE_PATH="${TEMPLATE_COMPOSE_PATH:-$WORKSPACE_ROOT/restore/templates/services/fnos-media-stack/docker-compose.yml}" \
  bash "$SCRIPT_DIR/audit_runtime_state.sh" || true
  RUNTIME_AUDIT_STATUS="success"
fi

if [[ "$RUN_ARCHIVE" == "1" ]]; then
  WORKSPACE_ROOT="$WORKSPACE_ROOT" BACKUP_ROOT="$BACKUP_ROOT" TIMESTAMP="${TIMESTAMP:-}" bash "$SCRIPT_DIR/tasks/archive_snapshot.sh"
fi

log "orchestrator done"
