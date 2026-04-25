#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

BACKUP_ROOT="$TMP/nas-backup"
mkdir -p \
  "$BACKUP_ROOT/services/openclaw/latest/docs" \
  "$BACKUP_ROOT/pve/latest" \
  "$BACKUP_ROOT/fnos/latest/services/media-stack" \
  "$BACKUP_ROOT/shared/version-index/latest" \
  "$BACKUP_ROOT/shared/restore-guides/latest" \
  "$BACKUP_ROOT/shared/network-map/latest"

echo ok > "$BACKUP_ROOT/services/openclaw/latest/docs/spec.md"
echo ok > "$BACKUP_ROOT/pve/latest/hostname.txt"
echo ok > "$BACKUP_ROOT/fnos/latest/services/media-stack/docker-compose.yml"
cat > "$BACKUP_ROOT/shared/version-index/latest/backup_target_manifest.yaml" <<'EOF'
version: 1
generated_at: "2026-04-26-010000"
targets:
  openclaw:
    status: success
    latest_path: "/tmp/nas-backup/services/openclaw/latest"
  pve:
    status: connectivity-ok
    latest_path: "/tmp/nas-backup/pve/latest"
  fnos:
    status: success
    latest_path: "/tmp/nas-backup/fnos/latest"
EOF
cat > "$BACKUP_ROOT/shared/restore-guides/latest/restore-order.md" <<'EOF'
# Restore Order
EOF
cat > "$BACKUP_ROOT/shared/network-map/latest/host-service-map.yaml" <<'EOF'
version: 1
EOF

OUT="$(BACKUP_ROOT="$BACKUP_ROOT" bash "$ROOT/scripts/backup/verify_latest.sh")"
printf '%s' "$OUT" | grep -Fq 'backup verify PASS' || { echo 'backup verify did not pass' >&2; exit 1; }

echo 'PASS test_backup_verify_three_targets'
