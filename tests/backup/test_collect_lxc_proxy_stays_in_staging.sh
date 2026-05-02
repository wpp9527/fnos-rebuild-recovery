#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

BACKUP_ROOT="$TMP/nas-backup"
STAGING_ROOT="$TMP/local-staging"
mkdir -p "$BACKUP_ROOT/lxc-proxy/latest" "$STAGING_ROOT"

echo 'keep-me' > "$BACKUP_ROOT/lxc-proxy/latest/existing.txt"

FAKEBIN="$TMP/fakebin"
mkdir -p "$FAKEBIN"
cat > "$FAKEBIN/sshpass" <<'SH'
#!/usr/bin/env bash
shift 2
if [[ "$*" == *"pct list"* ]]; then
  printf '213 running\n'
  exit 0
fi
if [[ "$*" == *"pct config 213"* ]]; then
  printf 'arch: amd64\n'
  exit 0
fi
case "$*" in
  *"cat /opt/mihomo/config.yaml"*) printf 'mixed-port: 7890\n' ;;
  *"cat /opt/mihomo/sub1.yaml"*) printf 'proxy-providers: {}\n' ;;
  *"cat /opt/mihomo/sub2.yaml"*) printf 'rules: []\n' ;;
  *"cat /opt/proxybox/subs/sub1.txt"*) printf 'sub1\n' ;;
  *"cat /opt/proxybox/subs/sub2.txt"*) printf 'sub2\n' ;;
  *"ls -la /opt/mihomo/scripts/"*) printf 'total 0\n' ;;
  *"ls /opt/mihomo/scripts/*.sh 2>/dev/null"*) exit 0 ;;
  *"cat /etc/systemd/system/mihomo.service"*) printf '[Unit]\n' ;;
  *"cat /etc/systemd/system/mihomo-fast.service"*) printf '[Unit]\n' ;;
  *"cat /etc/systemd/system/mihomo-stable.service"*) printf '[Unit]\n' ;;
  *) printf '' ;;
esac
SH
chmod +x "$FAKEBIN/sshpass"

PATH="$FAKEBIN:$PATH" \
BACKUP_ROOT="$BACKUP_ROOT" \
STAGING_ROOT="$STAGING_ROOT/lxc-proxy" \
PVE_SSH_HOST='192.168.1.190' \
PVE_SSH_USER='root' \
PVE_SSH_PASSWORD='test' \
LXC_VMID='213' \
bash "$ROOT/scripts/backup/tasks/collect_lxc_proxy.sh"

[[ -f "$STAGING_ROOT/lxc-proxy/manifest.yaml" ]] || { echo 'missing local lxc staging manifest' >&2; exit 1; }
[[ -f "$STAGING_ROOT/lxc-proxy/systemd/mihomo.service" ]] || { echo 'missing local lxc staging systemd export' >&2; exit 1; }
[[ -f "$BACKUP_ROOT/lxc-proxy/latest/existing.txt" ]] || { echo 'collect_lxc_proxy should not mutate backup latest directly' >&2; exit 1; }
[[ ! -f "$BACKUP_ROOT/lxc-proxy/latest/manifest.yaml" ]] || { echo 'collect_lxc_proxy should not publish latest directly' >&2; exit 1; }

echo 'PASS test_collect_lxc_proxy_stays_in_staging'
