#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

FNOS_ROOT="$TMP/fnos-root"
STAGING_ROOT="$TMP/staging"
HOMARR_VOL="$TMP/docker-volumes/homarr/_data"

mkdir -p \
  "$FNOS_ROOT/manifests" \
  "$FNOS_ROOT/services/media-stack" \
  "$FNOS_ROOT/services/openclaw/home/.openclaw" \
  "$FNOS_ROOT/services/hermes-openwebui/data" \
  "$FNOS_ROOT/services/docker-stack/ai-proxy/cliproxyapi/auths" \
  "$FNOS_ROOT/fnos-media-stack/radarr/config" \
  "$FNOS_ROOT/fnos-media-stack/sonarr/config" \
  "$FNOS_ROOT/fnos-media-stack/qbittorrent/config" \
  "$HOMARR_VOL/db"

echo 'manifest: yes' > "$FNOS_ROOT/manifests/managed_root_layout.yaml"
echo 'compose: yes' > "$FNOS_ROOT/services/media-stack/docker-compose.yml"
echo '{"ok":true}' > "$FNOS_ROOT/services/openclaw/home/.openclaw/openclaw.json"
echo 'openwebui-db' > "$FNOS_ROOT/services/hermes-openwebui/data/webui.db"
echo 'api-auth' > "$FNOS_ROOT/services/docker-stack/ai-proxy/cliproxyapi/auths/token.json"
echo 'radarr-db' > "$FNOS_ROOT/fnos-media-stack/radarr/config/radarr.db"
echo 'sonarr-db' > "$FNOS_ROOT/fnos-media-stack/sonarr/config/sonarr.db"
echo 'qbit-config' > "$FNOS_ROOT/fnos-media-stack/qbittorrent/config/qBittorrent.conf"
echo 'homarr-db' > "$HOMARR_VOL/db/db.sqlite"

FNOS_LOCAL_ROOT="$FNOS_ROOT" \
STAGING_ROOT="$STAGING_ROOT" \
FNOS_ENABLED=1 \
HOMARR_APPDATA_SOURCE="$HOMARR_VOL" \
bash "$ROOT/scripts/backup/tasks/collect_fnos.sh"

[[ -f "$STAGING_ROOT/fnos/services/hermes-openwebui/data/webui.db" ]] || { echo 'hermes-openwebui data not collected' >&2; exit 1; }
[[ -f "$STAGING_ROOT/fnos/services/docker-stack/ai-proxy/cliproxyapi/auths/token.json" ]] || { echo 'cliproxyapi auths not collected' >&2; exit 1; }
[[ -f "$STAGING_ROOT/fnos/fnos-media-stack/radarr/config/radarr.db" ]] || { echo 'radarr config not collected' >&2; exit 1; }
[[ -f "$STAGING_ROOT/fnos/fnos-media-stack/sonarr/config/sonarr.db" ]] || { echo 'sonarr config not collected' >&2; exit 1; }
[[ -f "$STAGING_ROOT/fnos/fnos-media-stack/qbittorrent/config/qBittorrent.conf" ]] || { echo 'qbittorrent config not collected' >&2; exit 1; }
[[ -f "$STAGING_ROOT/fnos/docker-volumes/homarr-appdata/db/db.sqlite" ]] || { echo 'homarr appdata not collected' >&2; exit 1; }

echo 'PASS test_collect_fnos_local_high_value_dirs'
