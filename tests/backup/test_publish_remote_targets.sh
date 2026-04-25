#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

BACKUP_ROOT="$TMP/nas-backup"
STAGING_ROOT="$TMP/staging"
mkdir -p "$BACKUP_ROOT" "$STAGING_ROOT/openclaw/docs" "$STAGING_ROOT/pve" "$STAGING_ROOT/fnos/services/media-stack" "$STAGING_ROOT/reports"

echo 'hello openclaw' > "$STAGING_ROOT/openclaw/docs/spec.md"
echo 'pvehost' > "$STAGING_ROOT/pve/hostname.txt"
echo 'iface data' > "$STAGING_ROOT/pve/network-interfaces.txt"
echo 'compose: yes' > "$STAGING_ROOT/fnos/services/media-stack/docker-compose.yml"
echo '# PVE ok' > "$STAGING_ROOT/reports/pve-connectivity-ok.md"
echo '# fnOS ok' > "$STAGING_ROOT/reports/fnos-local-collection-ok.md"

BACKUP_ROOT="$BACKUP_ROOT" \
STAGING_ROOT="$STAGING_ROOT" \
TIMESTAMP='2026-04-25-225900' \
bash "$ROOT/scripts/backup/tasks/publish_latest.sh"

[[ -f "$BACKUP_ROOT/services/openclaw/latest/docs/spec.md" ]] || { echo 'missing openclaw latest publish' >&2; exit 1; }
[[ -f "$BACKUP_ROOT/pve/latest/hostname.txt" ]] || { echo 'missing pve latest publish' >&2; exit 1; }
[[ -f "$BACKUP_ROOT/pve/latest/network-interfaces.txt" ]] || { echo 'missing pve network publish' >&2; exit 1; }
[[ -f "$BACKUP_ROOT/fnos/latest/services/media-stack/docker-compose.yml" ]] || { echo 'missing fnos latest publish' >&2; exit 1; }

grep -Fq 'connectivity-ok' "$BACKUP_ROOT/shared/version-index/latest/backup_target_manifest.yaml" || { echo 'manifest missing pve status' >&2; exit 1; }
grep -Fq 'fnos:' "$BACKUP_ROOT/shared/version-index/latest/backup_target_manifest.yaml" || { echo 'manifest missing fnos target' >&2; exit 1; }

echo 'PASS test_publish_remote_targets'
