#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
RESTORE_STATE_ROOT="$TMP/state/restore"
RESTORE_TARGET_ROOT="$TMP/target"
FNOS_LATEST_ROOT="$TMP/fnos-latest"
mkdir -p \
  "$RESTORE_STATE_ROOT" "$RESTORE_TARGET_ROOT" \
  "$FNOS_LATEST_ROOT/manifests" \
  "$FNOS_LATEST_ROOT/services/media-stack" \
  "$FNOS_LATEST_ROOT/services/openclaw" \
  "$FNOS_LATEST_ROOT/services/docker-stack/ai-proxy/cliproxyapi/auths" \
  "$FNOS_LATEST_ROOT/services/docker-stack/ai-proxy/cliproxyapi"
echo 'layout: ok' > "$FNOS_LATEST_ROOT/manifests/managed_root_layout.yaml"
echo 'compose: yes' > "$FNOS_LATEST_ROOT/services/media-stack/docker-compose.yml"
echo '{"ok":true}' > "$FNOS_LATEST_ROOT/services/openclaw/openclaw.json"
echo 'api-key' > "$FNOS_LATEST_ROOT/services/docker-stack/ai-proxy/cliproxyapi/auths/token.json"
echo 'providers: []' > "$FNOS_LATEST_ROOT/services/docker-stack/ai-proxy/cliproxyapi/config.yaml"
RESTORE_STATE_ROOT="$RESTORE_STATE_ROOT" RESTORE_TARGET_ROOT="$RESTORE_TARGET_ROOT" FNOS_LATEST_ROOT="$FNOS_LATEST_ROOT" bash "$ROOT/restore/layers/20-fnos.sh" apply >/dev/null
[[ -f "$RESTORE_TARGET_ROOT/opt/fnos-media/services/docker-stack/ai-proxy/cliproxyapi/auths/token.json" ]] || { echo 'cliproxyapi auths not restored' >&2; exit 1; }
[[ -f "$RESTORE_TARGET_ROOT/opt/fnos-media/services/docker-stack/ai-proxy/cliproxyapi/config.yaml" ]] || { echo 'cliproxyapi config not restored' >&2; exit 1; }
echo 'PASS test_restore_fnos_cliproxyapi_state'
