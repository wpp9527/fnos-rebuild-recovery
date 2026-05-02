#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

BACKUP_ROOT="$TMP/nas-backup"
STAGING_ROOT="$TMP/staging"
mkdir -p "$BACKUP_ROOT" "$STAGING_ROOT/openclaw/docs" "$STAGING_ROOT/lxc-proxy/systemd" "$STAGING_ROOT/reports"

echo 'hello openclaw' > "$STAGING_ROOT/openclaw/docs/spec.md"
echo '[Unit]' > "$STAGING_ROOT/lxc-proxy/systemd/mihomo.service"

BACKUP_ROOT="$BACKUP_ROOT" \
STAGING_ROOT="$STAGING_ROOT" \
TIMESTAMP='2026-05-02-163000' \
bash "$ROOT/scripts/backup/tasks/publish_latest.sh"

[[ -f "$BACKUP_ROOT/services/openclaw/latest/docs/spec.md" ]] || { echo 'missing openclaw latest publish' >&2; exit 1; }
[[ -f "$BACKUP_ROOT/lxc-proxy/latest/systemd/mihomo.service" ]] || { echo 'missing lxc-proxy latest publish' >&2; exit 1; }

echo 'PASS test_publish_lxc_proxy_target'
