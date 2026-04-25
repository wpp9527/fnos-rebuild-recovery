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
  "$FNOS_LATEST_ROOT/services/hermes-openwebui/data" \
  "$FNOS_LATEST_ROOT/services/docker-stack/ai-proxy/cliproxyapi/auths" \
  "$FNOS_LATEST_ROOT/fnos-media-stack/radarr/config" \
  "$FNOS_LATEST_ROOT/docker-volumes/homarr-appdata/db"
echo 'layout: ok' > "$FNOS_LATEST_ROOT/manifests/managed_root_layout.yaml"
echo 'compose: yes' > "$FNOS_LATEST_ROOT/services/media-stack/docker-compose.yml"
echo '{"ok":true}' > "$FNOS_LATEST_ROOT/services/openclaw/openclaw.json"
echo 'webui-db' > "$FNOS_LATEST_ROOT/services/hermes-openwebui/data/webui.db"
echo 'auth' > "$FNOS_LATEST_ROOT/services/docker-stack/ai-proxy/cliproxyapi/auths/token.json"
echo 'radarr-db' > "$FNOS_LATEST_ROOT/fnos-media-stack/radarr/config/radarr.db"
echo 'homarr-db' > "$FNOS_LATEST_ROOT/docker-volumes/homarr-appdata/db/db.sqlite"
RESTORE_STATE_ROOT="$RESTORE_STATE_ROOT" RESTORE_TARGET_ROOT="$RESTORE_TARGET_ROOT" FNOS_LATEST_ROOT="$FNOS_LATEST_ROOT" bash "$ROOT/restore/layers/20-fnos.sh" apply >/dev/null
[[ -f "$RESTORE_TARGET_ROOT/opt/fnos-media/services/hermes-openwebui/data/webui.db" ]] || { echo 'hermes-openwebui data not restored' >&2; exit 1; }
[[ -f "$RESTORE_TARGET_ROOT/opt/fnos-media/services/docker-stack/ai-proxy/cliproxyapi/auths/token.json" ]] || { echo 'cliproxyapi auths not restored' >&2; exit 1; }
[[ -f "$RESTORE_TARGET_ROOT/opt/fnos-media/fnos-media-stack/radarr/config/radarr.db" ]] || { echo 'radarr config not restored' >&2; exit 1; }
[[ -f "$RESTORE_TARGET_ROOT/opt/fnos-media/docker-volumes/homarr-appdata/db/db.sqlite" ]] || { echo 'homarr appdata not restored' >&2; exit 1; }
echo 'PASS test_restore_fnos_high_value_dirs'
