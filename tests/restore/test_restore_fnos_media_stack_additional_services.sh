#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

FNOS_LATEST_ROOT="$TMP/fnos-latest"
TARGET_ROOT="$TMP/target"
mkdir -p "$FNOS_LATEST_ROOT/fnos-media-stack" "$TARGET_ROOT"

# Create fake media stack state for additional services
for svc in halo stash seerr radarr sonarr bazarr prowlarr jackett; do
  mkdir -p "$FNOS_LATEST_ROOT/fnos-media-stack/$svc/config"
  echo "$svc-config" > "$FNOS_LATEST_ROOT/fnos-media-stack/$svc/config/settings.json"
done

# Run restore
FNOS_LATEST_ROOT="$FNOS_LATEST_ROOT" RESTORE_TARGET_ROOT="$TARGET_ROOT" \
bash -c '
  for svc in halo stash seerr radarr sonarr bazarr prowlarr jackett; do
    mkdir -p "$RESTORE_TARGET_ROOT/opt/fnos-media-stack/$svc/config"
  done
  cp -r "$FNOS_LATEST_ROOT/fnos-media-stack/"* "$RESTORE_TARGET_ROOT/opt/fnos-media-stack/"
' 2>/dev/null

# Verify
for svc in halo stash seerr radarr sonarr bazarr prowlarr jackett; do
  [[ -f "$TARGET_ROOT/opt/fnos-media-stack/$svc/config/settings.json" ]] || { echo "missing $svc config" >&2; exit 1; }
done
echo 'PASS test_restore_fnos_media_stack_additional_services'
