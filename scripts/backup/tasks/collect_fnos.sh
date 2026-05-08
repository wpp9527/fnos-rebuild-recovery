#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/common.sh
source "$SCRIPT_DIR/../lib/common.sh"

WORKSPACE_ROOT="${WORKSPACE_ROOT:-/root/.openclaw/.openclaw/workspace}"
STAGING_ROOT="${STAGING_ROOT:-$WORKSPACE_ROOT/state/backup/staging}"
REPORT_DIR="$STAGING_ROOT/reports"
FNOS_ENABLED="${FNOS_ENABLED:-0}"
FNOS_LOCAL_ROOT="${FNOS_LOCAL_ROOT:-/opt/fnos-media}"
FNOS_STAGE_DIR="$STAGING_ROOT/fnos"

ensure_dir "$REPORT_DIR"

if [[ "$FNOS_ENABLED" != "1" ]]; then
  cat > "$REPORT_DIR/fnos-not-configured.md" <<EOF
# fnOS Backup Status

fnOS backup is not configured yet.

Expected future inputs:
- FNOS_ENABLED=1
EOF
  log "collect_fnos: not configured"
  exit 0
fi

require_dir "$FNOS_LOCAL_ROOT"
rm -rf "$FNOS_STAGE_DIR"
ensure_dir "$FNOS_STAGE_DIR"
ensure_dir "$REPORT_DIR"

copy_if_exists() {
  local rel="$1"
  local src="$FNOS_LOCAL_ROOT/$rel"
  local dst="$FNOS_STAGE_DIR/$rel"
  if [[ -e "$src" ]]; then
    ensure_dir "$(dirname "$dst")"
    rsync -rltD "$src" "$dst"
  fi
}

copy_dir_contents_if_exists() {
  local rel="$1"
  local src="$FNOS_LOCAL_ROOT/$rel"
  local dst="$FNOS_STAGE_DIR/$rel"
  if [[ -d "$src" ]]; then
    ensure_dir "$dst"
    if [[ "$rel" == "services/openclaw" ]]; then
      rsync -rltD --delete \
        --exclude='home/.openclaw/workspace/state/backup/' \
        --exclude='home/.cache/' \
        --exclude='home/.npm/' \
        --exclude='home/.local/share/Trash/' \
        --exclude='home/.openclaw/workspace/' \
        --exclude='home/.openclaw/memory/' \
        --exclude='home/.openclaw/logs/' \
        --exclude='home/.openclaw/agents/' \
        --exclude='home/.openclaw/flows/' \
        --exclude='home/.openclaw/canvas/' \
        --exclude='home/.openclaw/sessions/' \
        "$src/" "$dst/"
    else
      rsync -rltD --delete "$src/" "$dst/"
    fi
  fi
}

copy_dir_contents_if_exists "manifests"
copy_dir_contents_if_exists "bin"
copy_dir_contents_if_exists "reports"
copy_if_exists "README.md"

for service in \
  media-stack \
  docker-stack \
  easytier \
  openclaw-governance \
  openclaw-channels
  do
  copy_dir_contents_if_exists "services/$service"
done

# High-value local state that is small enough to keep in config-level backup.
copy_dir_contents_if_exists "services/hermes-openwebui/data"
copy_dir_contents_if_exists "services/docker-stack/ai-proxy/cliproxyapi/auths"
copy_if_exists "services/docker-stack/ai-proxy/cliproxyapi/config.yaml"
copy_dir_contents_if_exists "services/docker-stack/channels"
copy_dir_contents_if_exists "fnos-media-stack"

if [[ -n "${HOMARR_APPDATA_SOURCE:-}" ]]; then
  ensure_dir "$FNOS_STAGE_DIR/docker-volumes/homarr-appdata"
  rsync -rltD --delete "$HOMARR_APPDATA_SOURCE/" "$FNOS_STAGE_DIR/docker-volumes/homarr-appdata/"
fi

# OpenClaw service: copy only minimal recovery-critical config.
# After reinstall, OpenClaw config moved to /root/.openclaw/
OPENCLAW_HOME="${OPENCLAW_HOME:-/root/.openclaw}"
if [[ -d "$OPENCLAW_HOME" ]]; then
  ensure_dir "$FNOS_STAGE_DIR/services/openclaw/home/.openclaw"
  copy_if_exists_fnos() {
    local rel="$1"
    local src="$OPENCLAW_HOME/$rel"
    local dst="$FNOS_STAGE_DIR/services/openclaw/home/.openclaw/$rel"
    if [[ -e "$src" ]]; then
      rsync -rltD "$src" "$dst"
    fi
  }
  copy_if_exists_fnos "openclaw.json"
  copy_if_exists_fnos "openclaw.json.last-good"
  copy_if_exists_fnos "clawpanel.json"
  copy_if_exists_fnos "clawpanel-device-key.json"
  copy_if_exists_fnos "exec-approvals.json"
fi

cat > "$FNOS_STAGE_DIR/restore-notes.md" <<EOF
# fnOS Restore Notes

Generated: $(date -Is)
Source root: $FNOS_LOCAL_ROOT

Contents in this directory are intended for configuration-level recovery of fnOS-hosted services.
Included:
- manifests/
- bin/
- reports/
- selected service config trees: media-stack, docker-stack, easytier, openclaw-governance, openclaw-channels
- high-value local state: hermes-openwebui/data, cliproxyapi/auths, cliproxyapi/config.yaml, channels/*, fnos-media-stack/
- homarr anonymous appdata volume when HOMARR_APPDATA_SOURCE is provided
- minimal OpenClaw runtime config files only

Excluded from this backup:
- backup archives
- logs
- large media/download payloads already stored on NAS
- caches and temporary files not needed for rebuild
- OpenClaw workspace trees already backed up separately
EOF

cat > "$REPORT_DIR/fnos-local-collection-ok.md" <<EOF
# fnOS Backup Status

fnOS local collection complete.
Source root: $FNOS_LOCAL_ROOT
Stage path: $FNOS_STAGE_DIR
EOF
log "collect_fnos: local collection complete"
