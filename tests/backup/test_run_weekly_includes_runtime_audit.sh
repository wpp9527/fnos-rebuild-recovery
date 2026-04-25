#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

FAKE_WS="$TMP/workspace"
BACKUP_ROOT="$TMP/nas-backup"
STAGING_ROOT="$TMP/staging"
CONFIG_FILE="$TMP/config.env"

mkdir -p "$FAKE_WS/docs" "$BACKUP_ROOT" "$FAKE_WS/restore/templates/services/fnos-media-stack"
echo 'hello weekly' > "$FAKE_WS/docs/weekly.md"

cat > "$CONFIG_FILE" <<EOF
WORKSPACE_ROOT="$FAKE_WS"
BACKUP_ROOT="$BACKUP_ROOT"
STAGING_ROOT="$STAGING_ROOT"
RUN_ARCHIVE=1
TIMESTAMP="2026-04-25-223000"
EOF

cat > "$FAKE_WS/restore/templates/services/fnos-media-stack/docker-compose.yml" <<'EOF'
services:
  homarr:
    volumes:
      - /opt/fnos-media-stack/homarr/config:/app/data/config
      - /opt/fnos-media-stack/homarr/appdata:/appdata
EOF

BACKUP_CONFIG="$CONFIG_FILE" bash "$ROOT/scripts/backup/run_weekly.sh"

[[ -f "$BACKUP_ROOT/shared/restore-guides/latest/runtime-state-audit.md" ]] || { echo 'weekly run did not publish runtime audit' >&2; exit 1; }
grep -Fq 'Runtime State Audit' "$BACKUP_ROOT/shared/restore-guides/latest/runtime-state-audit.md" || { echo 'runtime audit report malformed' >&2; exit 1; }

echo 'PASS test_run_weekly_includes_runtime_audit'
