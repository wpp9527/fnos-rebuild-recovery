#!/usr/bin/env bash
set -euo pipefail
PVE_LATEST_ROOT="${PVE_LATEST_ROOT:-/mnt/nas/backup/pve/latest}"
if [[ -f "$PVE_LATEST_ROOT/hostname.txt" && -f "$PVE_LATEST_ROOT/vm-list.txt" ]]; then
  echo 'PASS pve-assets: minimal inventory present'
else
  echo 'WARN pve-assets: minimal inventory incomplete'
fi
