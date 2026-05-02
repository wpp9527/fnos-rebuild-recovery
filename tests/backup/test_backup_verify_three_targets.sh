#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

BACKUP_ROOT="$TMP/nas-backup"

# Create all required dirs with subdirs for file counts
mkdir -p \
  "$BACKUP_ROOT/services/openclaw/latest/docs" \
  "$BACKUP_ROOT/pve/latest" \
  "$BACKUP_ROOT/fnos/latest/services/media-stack" \
  "$BACKUP_ROOT/lxc-proxy/latest" \
  "$BACKUP_ROOT/container-volumes/latest/homarr" \
  "$BACKUP_ROOT/container-volumes/latest/radarr" \
  "$BACKUP_ROOT/container-volumes/latest/sonarr" \
  "$BACKUP_ROOT/container-volumes/latest/qbittorrent" \
  "$BACKUP_ROOT/container-volumes/latest/jackett" \
  "$BACKUP_ROOT/shared/version-index/latest" \
  "$BACKUP_ROOT/shared/restore-guides/latest" \
  "$BACKUP_ROOT/shared/network-map/latest" \
  "$BACKUP_ROOT/shared/secrets/latest"

# Minimum file counts: openclaw>=50, pve>=5, fnos>=10, lxc>=3, container-volumes>=5
for i in $(seq 1 55); do echo "doc$i" > "$BACKUP_ROOT/services/openclaw/latest/docs/doc$i.md"; done
for i in $(seq 1 6); do echo "file$i" > "$BACKUP_ROOT/pve/latest/file$i.txt"; done
for i in $(seq 1 12); do echo "file$i" > "$BACKUP_ROOT/fnos/latest/file$i.txt"; done
echo "cfg" > "$BACKUP_ROOT/lxc-proxy/latest/lxc-213-config.conf"
echo "cfg" > "$BACKUP_ROOT/lxc-proxy/latest/config.yaml"
echo "cfg" > "$BACKUP_ROOT/lxc-proxy/latest/manifest.yaml"
echo "data" > "$BACKUP_ROOT/container-volumes/latest/homarr/config.json"
echo "data" > "$BACKUP_ROOT/container-volumes/latest/radarr/config.xml"
echo "data" > "$BACKUP_ROOT/container-volumes/latest/sonarr/config.xml"
echo "data" > "$BACKUP_ROOT/container-volumes/latest/qbittorrent/qBittorrent.conf"
echo "data" > "$BACKUP_ROOT/container-volumes/latest/jackett/config.yaml"
echo "secret" > "$BACKUP_ROOT/shared/secrets/latest/openclaw.env"

cat > "$BACKUP_ROOT/shared/version-index/latest/backup_target_manifest.yaml" <<'YAML'
version: 1
targets:
  openclaw:
    status: success
  pve:
    status: connectivity-ok
  fnos:
    status: success
YAML
cat > "$BACKUP_ROOT/shared/restore-guides/latest/restore-order.md" <<'EOF'
# Restore Order
EOF
cat > "$BACKUP_ROOT/shared/network-map/latest/host-service-map.yaml" <<'EOF'
version: 1
targets:
  - openclaw
  - pve
  - fnos
EOF

OUT="$(BACKUP_ROOT="$BACKUP_ROOT" MAX_AGE_HOURS="720" bash "$ROOT/scripts/backup/verify_latest.sh")"
printf '%s' "$OUT" | grep -Fq 'backup verify PASS' || { echo 'backup verify did not pass' >&2; echo "$OUT" >&2; exit 1; }

echo 'PASS test_backup_verify_three_targets'
