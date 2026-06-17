#!/usr/bin/env bash
set -euo pipefail
FNOS_LATEST_ROOT="${FNOS_LATEST_ROOT:-/mnt/nas/backup/fnos/latest}"
if [[ -d "$FNOS_LATEST_ROOT/manifests" && -d "$FNOS_LATEST_ROOT/services/media-stack" ]]; then
  echo 'PASS fnos-assets: minimal structure present'
else
  echo 'WARN fnos-assets: minimal structure incomplete'
fi
