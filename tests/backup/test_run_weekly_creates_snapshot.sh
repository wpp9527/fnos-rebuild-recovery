#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

FAKE_WS="$TMP/workspace"
BACKUP_ROOT="$TMP/nas-backup"
STAGING_ROOT="$TMP/staging"
CONFIG_FILE="$TMP/config.env"

mkdir -p "$FAKE_WS/docs" "$BACKUP_ROOT"
echo 'hello weekly' > "$FAKE_WS/docs/weekly.md"

cat > "$CONFIG_FILE" <<EOF
WORKSPACE_ROOT="$FAKE_WS"
BACKUP_ROOT="$BACKUP_ROOT"
STAGING_ROOT="$STAGING_ROOT"
RUN_ARCHIVE=1
TIMESTAMP="2026-04-25-223000"
EOF

BACKUP_CONFIG="$CONFIG_FILE" bash "$ROOT/scripts/backup/run_weekly.sh"

[[ -f "$BACKUP_ROOT/services/openclaw/snapshots/2026-04-25-223000/docs/weekly.md" ]] || { echo 'weekly run did not create snapshot' >&2; exit 1; }
[[ -f "$BACKUP_ROOT/shared/version-index/latest/archive-index.yaml" ]] || { echo 'weekly run missing archive index' >&2; exit 1; }

echo 'PASS test_run_weekly_creates_snapshot'
