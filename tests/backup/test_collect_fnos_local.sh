#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

FNOS_ROOT="$TMP/fnos-root"
STAGING_ROOT="$TMP/staging"

mkdir -p \
  "$FNOS_ROOT/manifests" \
  "$FNOS_ROOT/services/openclaw/home/.openclaw" \
  "$FNOS_ROOT/services/openclaw/home/.cache" \
  "$FNOS_ROOT/services/media-stack" \
  "$FNOS_ROOT/services/huge-data" \
  "$FNOS_ROOT/backups" \
  "$FNOS_ROOT/logs"

echo 'manifest: yes' > "$FNOS_ROOT/manifests/managed_root_layout.yaml"
echo 'compose: yes' > "$FNOS_ROOT/services/media-stack/docker-compose.yml"
echo '{"ok":true}' > "$FNOS_ROOT/services/openclaw/home/.openclaw/openclaw.json"
echo 'cache' > "$FNOS_ROOT/services/openclaw/home/.cache/tmp.bin"
echo 'skip me' > "$FNOS_ROOT/services/huge-data/big.bin"
echo 'old-backup' > "$FNOS_ROOT/backups/archive.tar.gz"
echo 'runtime-log' > "$FNOS_ROOT/logs/app.log"

FNOS_LOCAL_ROOT="$FNOS_ROOT" \
STAGING_ROOT="$STAGING_ROOT" \
FNOS_ENABLED=1 \
bash "$ROOT/scripts/backup/tasks/collect_fnos.sh"

[[ -f "$STAGING_ROOT/fnos/manifests/managed_root_layout.yaml" ]] || { echo 'fnos manifest not collected' >&2; exit 1; }
[[ -f "$STAGING_ROOT/fnos/services/media-stack/docker-compose.yml" ]] || { echo 'fnos media-stack compose not collected' >&2; exit 1; }
[[ -f "$STAGING_ROOT/fnos/services/openclaw/home/.openclaw/openclaw.json" ]] || { echo 'fnos openclaw config not collected' >&2; exit 1; }
[[ -f "$STAGING_ROOT/fnos/restore-notes.md" ]] || { echo 'fnos restore notes missing' >&2; exit 1; }
[[ ! -e "$STAGING_ROOT/fnos/services/openclaw/home/.cache/tmp.bin" ]] || { echo 'openclaw cache should be excluded' >&2; exit 1; }
[[ ! -e "$STAGING_ROOT/fnos/services/huge-data/big.bin" ]] || { echo 'unlisted fnos service should be excluded' >&2; exit 1; }
[[ ! -e "$STAGING_ROOT/fnos/backups/archive.tar.gz" ]] || { echo 'fnos backup archive should be excluded' >&2; exit 1; }
[[ ! -e "$STAGING_ROOT/fnos/logs/app.log" ]] || { echo 'fnos logs should be excluded' >&2; exit 1; }

echo 'PASS test_collect_fnos_local'
