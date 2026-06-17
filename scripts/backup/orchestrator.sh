#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

WORKSPACE_ROOT="${WORKSPACE_ROOT:-/root/.openclaw/.openclaw/workspace}"
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

STAGING_ROOT="$STAGING_ROOT" bash "$SCRIPT_DIR/tasks/collect_container_volumes.sh" || log "collect_container_volumes: failed"

# 收集所有容器的 docker-compose.yml 和配置文件
STAGING_ROOT="$STAGING_ROOT" bash "$SCRIPT_DIR/tasks/collect_compose_files.sh" || log "collect_compose_files: failed"

# Collect LXC proxy if PVE is enabled
if [[ "${PVE_ENABLED:-0}" == "1" && -n "${PVE_SSH_HOST:-}" ]]; then
  STAGING_ROOT="$STAGING_ROOT/lxc-proxy" \
  BACKUP_ROOT="$BACKUP_ROOT" \
  PVE_SSH_HOST="${PVE_SSH_HOST:-}" \
  PVE_SSH_PASSWORD="${PVE_SSH_PASSWORD:-}" \
  bash "$SCRIPT_DIR/tasks/collect_lxc_proxy.sh" || log "collect_lxc_proxy: failed"
fi
WORKSPACE_ROOT="$WORKSPACE_ROOT" STAGING_ROOT="$STAGING_ROOT" BACKUP_ROOT="$BACKUP_ROOT" TIMESTAMP="${TIMESTAMP:-}" bash "$SCRIPT_DIR/tasks/publish_latest.sh"

WORKSPACE_ROOT="$WORKSPACE_ROOT" \
GITHUB_SYNC_ENABLED="${GITHUB_SYNC_ENABLED:-0}" \
GITHUB_SYNC_REMOTE="${GITHUB_SYNC_REMOTE:-git@github.com:wpp9527/fnos-rebuild-recovery.git}" \
GITHUB_SYNC_DST="${GITHUB_SYNC_DST:-/tmp/fnos-rebuild-recovery-export}" \
GITHUB_SYNC_BRANCH="${GITHUB_SYNC_BRANCH:-main}" \
GITHUB_SYNC_GIT_NAME="${GITHUB_SYNC_GIT_NAME:-wpp9527}" \
GITHUB_SYNC_GIT_EMAIL="${GITHUB_SYNC_GIT_EMAIL:-wangpengpeng9527@gmail.com}" \
bash "$SCRIPT_DIR/tasks/publish_github.sh" || log "publish_github: skipped or failed"

# Publish recovery-critical secrets to NAS
OPENCLAW_CONFIG="${OPENCLAW_CONFIG:-/root/.openclaw/openclaw.json}" \
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

GITHUB_VERIFY_REPORT_ROOT="$BACKUP_ROOT/shared/restore-guides/latest" GITHUB_SYNC_REMOTE="${GITHUB_SYNC_REMOTE:-}" GITHUB_SYNC_BRANCH="${GITHUB_SYNC_BRANCH:-main}" GITHUB_SYNC_ENABLED="${GITHUB_SYNC_ENABLED:-0}" bash "$SCRIPT_DIR/verify_github.sh" || log "verify_github: skipped or failed"

if [[ "$RUN_ARCHIVE" == "1" ]]; then
  WORKSPACE_ROOT="$WORKSPACE_ROOT" BACKUP_ROOT="$BACKUP_ROOT" TIMESTAMP="${TIMESTAMP:-}" bash "$SCRIPT_DIR/tasks/archive_snapshot.sh"
fi

log "orchestrator done"
