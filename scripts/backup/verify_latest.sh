#!/usr/bin/env bash
set -euo pipefail

BACKUP_ROOT="${BACKUP_ROOT:-/mnt/nas/backup}"

require_file() {
  [[ -f "$1" ]] || { echo "missing required file: $1" >&2; exit 1; }
}

require_dir() {
  [[ -d "$1" ]] || { echo "missing required dir: $1" >&2; exit 1; }
}

require_dir "$BACKUP_ROOT/services/openclaw/latest"
require_dir "$BACKUP_ROOT/pve/latest"
require_dir "$BACKUP_ROOT/fnos/latest"
require_file "$BACKUP_ROOT/shared/version-index/latest/backup_target_manifest.yaml"
require_file "$BACKUP_ROOT/shared/restore-guides/latest/restore-order.md"
require_file "$BACKUP_ROOT/shared/network-map/latest/host-service-map.yaml"

echo 'backup verify PASS'
