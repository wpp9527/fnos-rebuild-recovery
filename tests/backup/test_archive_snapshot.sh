#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

FAKE_WS="$TMP/workspace"
BACKUP_ROOT="$TMP/nas-backup"
STAGING_ROOT="$TMP/staging"

mkdir -p "$FAKE_WS/docs" "$BACKUP_ROOT"
echo 'hello spec' > "$FAKE_WS/docs/spec.md"

WORKSPACE_ROOT="$FAKE_WS" \
BACKUP_ROOT="$BACKUP_ROOT" \
STAGING_ROOT="$STAGING_ROOT" \
RUN_ARCHIVE=1 \
TIMESTAMP='2026-04-25-222700' \
bash "$ROOT/scripts/backup/orchestrator.sh"

SNAPSHOT_DIR="$BACKUP_ROOT/services/openclaw/snapshots/2026-04-25-222700"
ARCHIVE_INDEX="$BACKUP_ROOT/shared/version-index/latest/archive-index.yaml"

[[ -f "$SNAPSHOT_DIR/docs/spec.md" ]] || { echo 'snapshot missing expected file' >&2; exit 1; }
[[ -f "$ARCHIVE_INDEX" ]] || { echo 'archive index missing' >&2; exit 1; }
grep -Fq '2026-04-25-222700' "$ARCHIVE_INDEX" || { echo 'archive index missing timestamp' >&2; exit 1; }

echo 'PASS test_archive_snapshot'
