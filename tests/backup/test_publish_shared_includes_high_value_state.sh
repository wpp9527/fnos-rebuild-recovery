#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

STAGING_ROOT="$TMP/staging"
BACKUP_ROOT="$TMP/nas-backup"
mkdir -p "$STAGING_ROOT/openclaw" "$STAGING_ROOT/fnos" "$STAGING_ROOT/reports" "$BACKUP_ROOT"

echo '{"ok":true}' > "$STAGING_ROOT/openclaw/openclaw.json"
echo 'layout: ok' > "$STAGING_ROOT/fnos/managed_root_layout.yaml"
echo 'fnos ok' > "$STAGING_ROOT/reports/fnos-local-collection-ok.md"

STAGING_ROOT="$STAGING_ROOT" BACKUP_ROOT="$BACKUP_ROOT" TIMESTAMP="2026-04-26-020500" bash "$ROOT/scripts/backup/tasks/publish_latest.sh"

GUIDE="$BACKUP_ROOT/shared/restore-guides/latest/restore-order.md"
MANIFEST="$BACKUP_ROOT/shared/version-index/latest/backup_target_manifest.yaml"
[[ -f "$GUIDE" ]] || { echo 'restore guide missing' >&2; exit 1; }
[[ -f "$MANIFEST" ]] || { echo 'backup manifest missing' >&2; exit 1; }
grep -Fq 'high-value local state' "$GUIDE" || { echo 'restore guide missing high-value local state note' >&2; exit 1; }
grep -Fq 'backed_up_local_state' "$MANIFEST" || { echo 'manifest missing must_back_up_local_state' >&2; exit 1; }
echo 'PASS test_publish_shared_includes_high_value_state'
