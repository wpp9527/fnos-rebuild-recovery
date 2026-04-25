#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/common.sh
source "$SCRIPT_DIR/../lib/common.sh"

ACTION="${1:-plan}"
STATE_ROOT="$(restore_state_root)"
TARGET_ROOT="${RESTORE_TARGET_ROOT:-$STATE_ROOT/target}"
FNOS_LATEST_ROOT="${FNOS_LATEST_ROOT:-/mnt/nas/backup/fnos/latest}"
TS="$(restore_now_ts)"

restore_init_dirs "$STATE_ROOT"
restore_ensure_dir "$TARGET_ROOT/config"
restore_ensure_dir "$TARGET_ROOT/data"

fnos_plan() {
  local plan_md="$STATE_ROOT/plans/fnos-plan-$TS.md"
  cat > "$plan_md" <<EOF
# fnOS Restore Plan

Source: $FNOS_LATEST_ROOT
Target: $TARGET_ROOT/

Unified structure:
- config/fnos-media-stack/     - Service configs
- config/channels/             - Channel configs
- config/cliproxyapi/          - AI proxy configs
- config/hermes-openwebui/     - Hermes configs
- data/                        - Service data
EOF
  echo "fnos plan ready: $plan_md"
}

copy_tree_if_exists() {
  local src_rel="$1"
  local dst="$2"
  local src="$FNOS_LATEST_ROOT/$src_rel"
  if [[ -d "$src" ]]; then
    restore_ensure_dir "$dst"
    cp -a "$src/." "$dst/"
  fi
}

fnos_apply() {
  # fnos-media-stack configs -> config/fnos-media-stack/
  copy_tree_if_exists "fnos-media-stack" "$TARGET_ROOT/config/fnos-media-stack"
  
  # Separate data from config
  for svc in homarr halo jellyfin radarr sonarr prowlarr bazarr seerr stash qbittorrent jackett; do
    if [[ -d "$TARGET_ROOT/config/fnos-media-stack/$svc" ]]; then
      # Move data dirs to data/ if they exist
      for data_dir in appdata content metadata blobs generated cache; do
        if [[ -d "$TARGET_ROOT/config/fnos-media-stack/$svc/$data_dir" ]]; then
          mv "$TARGET_ROOT/config/fnos-media-stack/$svc/$data_dir" "$TARGET_ROOT/data/${svc}-${data_dir}/" 2>/dev/null || true
        fi
      done
    fi
  done

  # Channels -> config/channels/
  restore_ensure_dir "$TARGET_ROOT/config/channels"
  copy_tree_if_exists "services/docker-stack/channels/feishu" "$TARGET_ROOT/config/channels/feishu"
  copy_tree_if_exists "services/docker-stack/channels/qq" "$TARGET_ROOT/config/channels/qq"

  # Hermes -> config/hermes-openwebui/
  copy_tree_if_exists "services/hermes-openwebui/data" "$TARGET_ROOT/data/hermes-openwebui"

  # cliproxyapi -> config/cliproxyapi/
  copy_tree_if_exists "services/docker-stack/ai-proxy/cliproxyapi/auths" "$TARGET_ROOT/config/cliproxyapi/auths"
  if [[ -f "$FNOS_LATEST_ROOT/services/docker-stack/ai-proxy/cliproxyapi/config.yaml" ]]; then
    restore_ensure_dir "$TARGET_ROOT/config/cliproxyapi"
    cp "$FNOS_LATEST_ROOT/services/docker-stack/ai-proxy/cliproxyapi/config.yaml" "$TARGET_ROOT/config/cliproxyapi/"
  fi

  echo "fnos apply complete: $TARGET_ROOT"
}

fnos_verify() {
  local report="$STATE_ROOT/reports/fnos-verify-$TS.md"
  local status="PASS"

  [[ -d "$TARGET_ROOT/config" ]] || status="FAIL"
  [[ -d "$TARGET_ROOT/data" ]] || status="FAIL"

  cat > "$report" <<EOF
# fnOS Verify

Status: $status
Target: $TARGET_ROOT
Config: $TARGET_ROOT/config
Data: $TARGET_ROOT/data
EOF

  if [[ "$status" == "PASS" ]]; then
    echo "fnos verify PASS: $report"
  else
    echo "fnos verify FAIL: $report" >&2
    exit 1
  fi
}

case "$ACTION" in
  plan) fnos_plan ;;
  apply) fnos_apply ;;
  verify) fnos_verify ;;
  *)
    echo "unsupported action: $ACTION" >&2
    exit 1
    ;;
esac
