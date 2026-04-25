#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

BACKUP_ROOT="$TMP/nas-backup"
STAGING_ROOT="$TMP/staging"
mkdir -p "$BACKUP_ROOT/fnos" "$STAGING_ROOT/openclaw/docs" "$STAGING_ROOT/fnos/services/media-stack" "$STAGING_ROOT/reports"

echo 'legacy-file' > "$BACKUP_ROOT/fnos/latest"
echo 'hello openclaw' > "$STAGING_ROOT/openclaw/docs/spec.md"
echo 'compose: yes' > "$STAGING_ROOT/fnos/services/media-stack/docker-compose.yml"
echo '# fnOS ok' > "$STAGING_ROOT/reports/fnos-local-collection-ok.md"

BACKUP_ROOT="$BACKUP_ROOT" \
STAGING_ROOT="$STAGING_ROOT" \
TIMESTAMP='2026-04-25-230100' \
bash "$ROOT/scripts/backup/tasks/publish_latest.sh"

[[ -d "$BACKUP_ROOT/fnos/latest" ]] || { echo 'fnos latest was not replaced with directory' >&2; exit 1; }
[[ -f "$BACKUP_ROOT/fnos/latest/services/media-stack/docker-compose.yml" ]] || { echo 'fnos latest missing expected content after file replacement' >&2; exit 1; }

echo 'PASS test_publish_replaces_file_latest'
