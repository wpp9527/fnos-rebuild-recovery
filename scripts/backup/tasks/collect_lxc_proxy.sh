#!/usr/bin/env bash
# Collect LXC proxy container (fnos-proxy) backup
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"

BACKUP_ROOT="${BACKUP_ROOT:-/mnt/nas/backup}"
PVE_SSH_HOST="${PVE_SSH_HOST:-192.168.1.190}"
PVE_SSH_USER="${PVE_SSH_USER:-root}"
PVE_SSH_PASSWORD="${PVE_SSH_PASSWORD:-}"
LXC_VMID="${LXC_VMID:-213}"
STAGING_ROOT="${STAGING_ROOT:-$BACKUP_ROOT/lxc-proxy/staging}"
TS="$(date +%Y-%m-%d-%H%M%S)"

run_remote() {
  sshpass -p "$PVE_SSH_PASSWORD" ssh -o StrictHostKeyChecking=no "$PVE_SSH_USER@$PVE_SSH_HOST" "$@"
}

run_in_container() {
  run_remote "pct exec $LXC_VMID -- $@"
}

log "collect_lxc_proxy: start for VMID $LXC_VMID"

# Check if container exists
if ! run_remote "pct list | grep -q $LXC_VMID" 2>/dev/null; then
  log "collect_lxc_proxy: container $LXC_VMID not found"
  exit 0
fi

ensure_dir "$STAGING_ROOT"

# 1. Export container config
log "collect_lxc_proxy: exporting container config"
run_remote "pct config $LXC_VMID" > "$STAGING_ROOT/lxc-$LXC_VMID-config.conf"

# 2. Export mihomo configs
log "collect_lxc_proxy: exporting mihomo configs"
mkdir -p "$STAGING_ROOT/mihomo"
run_in_container "cat /opt/mihomo/config.yaml" > "$STAGING_ROOT/mihomo/config.yaml" 2>/dev/null || true
run_in_container "cat /opt/mihomo/sub1.yaml" > "$STAGING_ROOT/mihomo/sub1.yaml" 2>/dev/null || true
run_in_container "cat /opt/mihomo/sub2.yaml" > "$STAGING_ROOT/mihomo/sub2.yaml" 2>/dev/null || true

# 3. Export subscription files
log "collect_lxc_proxy: exporting subscription files"
mkdir -p "$STAGING_ROOT/subscriptions"
run_in_container "cat /opt/proxybox/subs/sub1.txt" > "$STAGING_ROOT/subscriptions/sub1.txt" 2>/dev/null || true
run_in_container "cat /opt/proxybox/subs/sub2.txt" > "$STAGING_ROOT/subscriptions/sub2.txt" 2>/dev/null || true

# 4. Export scripts
log "collect_lxc_proxy: exporting scripts"
mkdir -p "$STAGING_ROOT/scripts"
run_in_container "ls -la /opt/mihomo/scripts/" > "$STAGING_ROOT/scripts/list.txt" 2>/dev/null || true
for script in $(run_in_container "ls /opt/mihomo/scripts/*.sh 2>/dev/null" 2>/dev/null || true); do
  script_name=$(basename "$script")
  run_in_container "cat $script" > "$STAGING_ROOT/scripts/$script_name" 2>/dev/null || true
done

# 5. Export systemd services
log "collect_lxc_proxy: exporting systemd services"
mkdir -p "$STAGING_ROOT/systemd"
run_in_container "cat /etc/systemd/system/mihomo.service" > "$STAGING_ROOT/systemd/mihomo.service" 2>/dev/null || true
run_in_container "cat /etc/systemd/system/mihomo-fast.service" > "$STAGING_ROOT/systemd/mihomo-fast.service" 2>/dev/null || true
run_in_container "cat /etc/systemd/system/mihomo-stable.service" > "$STAGING_ROOT/systemd/mihomo-stable.service" 2>/dev/null || true

# 6. Create manifest
cat > "$STAGING_ROOT/manifest.yaml" <<EOF
# LXC Proxy Backup Manifest
vmid: $LXC_VMID
hostname: fnos-proxy
timestamp: $TS
source_host: $PVE_SSH_HOST
contents:
  - lxc-$LXC_VMID-config.conf
  - mihomo/
  - subscriptions/
  - scripts/
  - systemd/
EOF

# 7. Publish to latest
LATEST_ROOT="$BACKUP_ROOT/lxc-proxy/latest"
ensure_dir "$LATEST_ROOT"
rm -rf "$LATEST_ROOT/"*
cp -r "$STAGING_ROOT/"* "$LATEST_ROOT/"

log "collect_lxc_proxy: complete -> $LATEST_ROOT"
