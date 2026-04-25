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
echo 'hello daily' > "$FAKE_WS/docs/daily.md"

cat > "$CONFIG_FILE" <<EOF
WORKSPACE_ROOT="$FAKE_WS"
BACKUP_ROOT="$BACKUP_ROOT"
STAGING_ROOT="$STAGING_ROOT"
RUN_ARCHIVE=0
EOF

BACKUP_CONFIG="$CONFIG_FILE" bash "$ROOT/scripts/backup/run_daily.sh"

[[ -f "$BACKUP_ROOT/services/openclaw/latest/docs/daily.md" ]] || { echo 'daily run did not publish latest' >&2; exit 1; }
[[ -f "$BACKUP_ROOT/shared/version-index/latest/backup_target_manifest.yaml" ]] || { echo 'daily run missing manifest' >&2; exit 1; }

echo 'PASS test_run_daily_uses_config'
