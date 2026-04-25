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
RUN_ARCHIVE=0 \
bash "$ROOT/scripts/backup/orchestrator.sh"

PVE_REPORT="$STAGING_ROOT/reports/pve-not-configured.md"
FNOS_REPORT="$STAGING_ROOT/reports/fnos-not-configured.md"
MANIFEST="$BACKUP_ROOT/shared/version-index/latest/backup_target_manifest.yaml"

[[ -f "$PVE_REPORT" ]] || { echo 'missing pve report' >&2; exit 1; }
[[ -f "$FNOS_REPORT" ]] || { echo 'missing fnos report' >&2; exit 1; }
grep -Fq 'not configured' "$PVE_REPORT" || { echo 'pve report content mismatch' >&2; exit 1; }
grep -Fq 'not configured' "$FNOS_REPORT" || { echo 'fnos report content mismatch' >&2; exit 1; }
grep -Fq 'pve:' "$MANIFEST" || { echo 'manifest missing pve section' >&2; exit 1; }
grep -Fq 'fnos:' "$MANIFEST" || { echo 'manifest missing fnos section' >&2; exit 1; }

echo 'PASS test_remote_not_configured'
