#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

PVE_LATEST_ROOT="$TMP/pve-latest"
BACKUP_ROOT="$TMP/backup"
mkdir -p "$PVE_LATEST_ROOT" "$BACKUP_ROOT/pve/latest"

# Create fake PVE state
echo 'pve-test-host' > "$PVE_LATEST_ROOT/hostname.txt"
echo '192.168.1.190' > "$PVE_LATEST_ROOT/ip.txt"
cat > "$PVE_LATEST_ROOT/pve-version.txt" <<'EOF'
pve-manager/8.0.3/d25bdda90e9e1f66
EOF
cat > "$PVE_LATEST_ROOT/storage.cfg" <<'EOF'
dir: local
	path /var/lib/vz
	content iso,backup,rootdir

lvmthin: local-lvm
	thinpool data
	content rootdir,images
EOF
cat > "$PVE_LATEST_ROOT/nodes.txt" <<'EOF'
pve-test-host
EOF
mkdir -p "$PVE_LATEST_ROOT/lxc"
echo 'lxc-config' > "$PVE_LATEST_ROOT/lxc/100.conf"

# Run collection with fake state
PVE_LATEST_ROOT="$PVE_LATEST_ROOT" BACKUP_ROOT="$BACKUP_ROOT" \
bash "$ROOT/scripts/backup/tasks/collect_pve.sh" 2>/dev/null || true

# Verify
[[ -f "$BACKUP_ROOT/pve/latest/hostname.txt" ]] || { echo 'missing hostname' >&2; exit 1; }
[[ -f "$BACKUP_ROOT/pve/latest/storage.cfg" ]] || { echo 'missing storage.cfg' >&2; exit 1; }
[[ -f "$BACKUP_ROOT/pve/latest/nodes.txt" ]] || { echo 'missing nodes.txt' >&2; exit 1; }
echo 'PASS test_collect_pve_includes_config_files'
