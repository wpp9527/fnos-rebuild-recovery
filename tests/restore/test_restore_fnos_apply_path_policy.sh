#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

RESTORE_STATE_ROOT="$TMP/state/restore"
RESTORE_TARGET_ROOT="$TMP/target"
FNOS_LATEST_ROOT="$TMP/fnos-latest"
mkdir -p "$RESTORE_STATE_ROOT" "$RESTORE_TARGET_ROOT" \
  "$FNOS_LATEST_ROOT/services/media-stack" \
  "$FNOS_LATEST_ROOT/services/openclaw" \
  "$FNOS_LATEST_ROOT/manifests"

echo 'compose: yes' > "$FNOS_LATEST_ROOT/services/media-stack/docker-compose.yml"
echo '{"ok":true}' > "$FNOS_LATEST_ROOT/services/openclaw/openclaw.json"
echo 'layout: ok' > "$FNOS_LATEST_ROOT/manifests/managed_root_layout.yaml"

RESTORE_STATE_ROOT="$RESTORE_STATE_ROOT" \
RESTORE_TARGET_ROOT="$RESTORE_TARGET_ROOT" \
FNOS_LATEST_ROOT="$FNOS_LATEST_ROOT" \
bash "$ROOT/restore/layers/20-fnos.sh" apply

[[ -d "$RESTORE_TARGET_ROOT/opt/fnos-media/manifests" ]] || { echo 'tier1 manifests dir not created' >&2; exit 1; }
[[ -d "$RESTORE_TARGET_ROOT/opt/fnos-media/services/media-stack" ]] || { echo 'tier1 media-stack dir not created' >&2; exit 1; }
[[ -d "$RESTORE_TARGET_ROOT/opt/fnos-media/services/openclaw" ]] || { echo 'tier1 openclaw dir not created' >&2; exit 1; }
[[ -d "$RESTORE_TARGET_ROOT/opt/fnos-media/downloads" ]] || { echo 'tier2 downloads dir not created' >&2; exit 1; }
[[ -d "$RESTORE_TARGET_ROOT/opt/fnos-media/cache" ]] || { echo 'tier2 cache dir not created' >&2; exit 1; }
[[ ! -e "$RESTORE_TARGET_ROOT/opt/fnos-media/media" ]] || { echo 'tier3 media dir should not be created' >&2; exit 1; }
[[ -f "$RESTORE_TARGET_ROOT/opt/fnos-media/services/media-stack/docker-compose.yml" ]] || { echo 'media-stack file not restored' >&2; exit 1; }
[[ -f "$RESTORE_TARGET_ROOT/opt/fnos-media/services/openclaw/openclaw.json" ]] || { echo 'openclaw config not restored' >&2; exit 1; }

echo 'PASS test_restore_fnos_apply_path_policy'
