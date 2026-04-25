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
restore_ensure_dir "$TARGET_ROOT"

fnos_plan() {
  local plan_md="$STATE_ROOT/plans/fnos-plan-$TS.md"
  cat > "$plan_md" <<EOF
# fnOS Restore Plan

Source: $FNOS_LATEST_ROOT
Target: $TARGET_ROOT

Expected tier1 roots:
- /opt/fnos-media/manifests
- /opt/fnos-media/services/media-stack
- /opt/fnos-media/services/openclaw

Detected source content:
$(find "$FNOS_LATEST_ROOT" -maxdepth 3 -mindepth 1 2>/dev/null | sed 's#^#- #' | sed -n '1,80p')
EOF
  echo "fnos plan ready: $plan_md"
}

copy_tree_if_exists() {
  local src_rel="$1"
  local dst_rel="$2"
  local src="$FNOS_LATEST_ROOT/$src_rel"
  local dst="$TARGET_ROOT/$dst_rel"
  if [[ -d "$src" ]]; then
    restore_ensure_dir "$dst"
    cp -a "$src/." "$dst/"
  fi
}

fnos_apply() {
  # tier1: restore structure + source content
  restore_ensure_dir "$TARGET_ROOT/opt/fnos-media/manifests"
  restore_ensure_dir "$TARGET_ROOT/opt/fnos-media/services/media-stack"
  restore_ensure_dir "$TARGET_ROOT/opt/fnos-media/services/openclaw"
  restore_ensure_dir "$TARGET_ROOT/opt/fnos-media/services/hermes-openwebui/data"
  restore_ensure_dir "$TARGET_ROOT/opt/fnos-media/services/docker-stack/ai-proxy/cliproxyapi/auths"
  restore_ensure_dir "$TARGET_ROOT/opt/fnos-media/services/docker-stack/ai-proxy/cliproxyapi"
  restore_ensure_dir "$TARGET_ROOT/opt/fnos-media/services/docker-stack/channels"
  restore_ensure_dir "$TARGET_ROOT/opt/fnos-media/fnos-media-stack"
  restore_ensure_dir "$TARGET_ROOT/opt/fnos-media/docker-volumes/homarr-appdata"

  # tier2: create empty dirs only
  restore_ensure_dir "$TARGET_ROOT/opt/fnos-media/downloads"
  restore_ensure_dir "$TARGET_ROOT/opt/fnos-media/cache"

  copy_tree_if_exists "manifests" "opt/fnos-media/manifests"
  copy_tree_if_exists "services/media-stack" "opt/fnos-media/services/media-stack"
  copy_tree_if_exists "services/openclaw" "opt/fnos-media/services/openclaw"
  copy_tree_if_exists "services/hermes-openwebui/data" "opt/fnos-media/services/hermes-openwebui/data"
  copy_tree_if_exists "services/docker-stack/ai-proxy/cliproxyapi/auths" "opt/fnos-media/services/docker-stack/ai-proxy/cliproxyapi/auths"
  copy_tree_if_exists "services/docker-stack/ai-proxy/cliproxyapi" "opt/fnos-media/services/docker-stack/ai-proxy/cliproxyapi"
  copy_tree_if_exists "services/docker-stack/channels" "opt/fnos-media/services/docker-stack/channels"
  copy_tree_if_exists "fnos-media-stack" "opt/fnos-media/fnos-media-stack"
  copy_tree_if_exists "docker-volumes/homarr-appdata" "opt/fnos-media/docker-volumes/homarr-appdata"

  echo "fnos apply complete: $TARGET_ROOT"
}

fnos_verify() {
  local report="$STATE_ROOT/reports/fnos-verify-$TS.md"
  local status="PASS"

  [[ -d "$TARGET_ROOT/opt/fnos-media/manifests" ]] || status="FAIL"
  [[ -d "$TARGET_ROOT/opt/fnos-media/services/media-stack" ]] || status="FAIL"
  [[ -d "$TARGET_ROOT/opt/fnos-media/services/openclaw" ]] || status="FAIL"
  [[ -d "$TARGET_ROOT/opt/fnos-media/services/hermes-openwebui/data" ]] || status="FAIL"
  [[ -d "$TARGET_ROOT/opt/fnos-media/services/docker-stack/ai-proxy/cliproxyapi/auths" ]] || status="FAIL"
  [[ -d "$TARGET_ROOT/opt/fnos-media/services/docker-stack/ai-proxy/cliproxyapi" ]] || status="FAIL"
  [[ -d "$TARGET_ROOT/opt/fnos-media/services/docker-stack/channels" ]] || status="FAIL"
  [[ -d "$TARGET_ROOT/opt/fnos-media/fnos-media-stack" ]] || status="FAIL"
  [[ -d "$TARGET_ROOT/opt/fnos-media/docker-volumes/homarr-appdata" ]] || status="FAIL"
  [[ -f "$TARGET_ROOT/opt/fnos-media/services/media-stack/docker-compose.yml" ]] || status="FAIL"
  [[ -f "$TARGET_ROOT/opt/fnos-media/services/openclaw/openclaw.json" ]] || status="FAIL"

  cat > "$report" <<EOF
# fnOS Verify

Status: $status
Target: $TARGET_ROOT
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
