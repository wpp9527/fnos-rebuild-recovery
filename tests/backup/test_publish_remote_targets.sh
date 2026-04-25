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

MANIFEST="$BACKUP_ROOT/shared/version-index/latest/backup_target_manifest.yaml"
RESTORE_GUIDE="$BACKUP_ROOT/shared/restore-guides/latest/restore-order.md"
NETWORK_MAP="$BACKUP_ROOT/shared/network-map/latest/host-service-map.yaml"
CHANGE_SUMMARY="$BACKUP_ROOT/shared/change-log/latest/change-summary-2026-04-25-225900.md"

grep -Fq 'connectivity-ok' "$MANIFEST" || { echo 'manifest missing pve status' >&2; exit 1; }
grep -Fq 'fnos:' "$MANIFEST" || { echo 'manifest missing fnos target' >&2; exit 1; }
grep -Fq 'latest_path: "'$BACKUP_ROOT'/services/openclaw/latest"' "$MANIFEST" || { echo 'manifest missing openclaw latest path' >&2; exit 1; }
grep -Fq 'latest_path: "'$BACKUP_ROOT'/pve/latest"' "$MANIFEST" || { echo 'manifest missing pve latest path' >&2; exit 1; }
grep -Fq 'latest_path: "'$BACKUP_ROOT'/fnos/latest"' "$MANIFEST" || { echo 'manifest missing fnos latest path' >&2; exit 1; }

grep -Fq 'Restore OpenClaw workspace and scripts from services/openclaw/latest' "$RESTORE_GUIDE" || { echo 'restore guide missing openclaw step' >&2; exit 1; }
grep -Fq 'Restore PVE inventory from pve/latest' "$RESTORE_GUIDE" || { echo 'restore guide missing pve latest step' >&2; exit 1; }
grep -Fq 'Restore fnOS config set from fnos/latest' "$RESTORE_GUIDE" || { echo 'restore guide missing fnos latest step' >&2; exit 1; }

grep -Fq 'openclaw:' "$NETWORK_MAP" || { echo 'network map missing openclaw service' >&2; exit 1; }
grep -Fq 'pve:' "$NETWORK_MAP" || { echo 'network map missing pve service' >&2; exit 1; }
grep -Fq 'fnos:' "$NETWORK_MAP" || { echo 'network map missing fnos service' >&2; exit 1; }

grep -Fq -- '- pve: connectivity-ok' "$CHANGE_SUMMARY" || { echo 'change summary missing pve status' >&2; exit 1; }
grep -Fq -- '- fnos: success' "$CHANGE_SUMMARY" || { echo 'change summary missing fnos status' >&2; exit 1; }

echo 'PASS test_publish_remote_targets'
