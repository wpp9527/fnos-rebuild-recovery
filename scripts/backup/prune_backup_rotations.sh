#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

BACKUP_ROOT="${BACKUP_ROOT:-/mnt/nas/backup}"
require_dir "$BACKUP_ROOT"

prune_rotations_under() {
  local target_base="$1"
  [[ -d "$target_base" ]] || return 0

  find "$target_base" -mindepth 1 -maxdepth 1 \( -name '.tmp-latest-*' -o -name '.prev-latest-*' \) -print0 |
  while IFS= read -r -d '' path; do
    log "prune rotation: $path"
    rm -rf "$path"
  done
}

prune_rotations_under "$BACKUP_ROOT/services/openclaw"
prune_rotations_under "$BACKUP_ROOT/pve"
prune_rotations_under "$BACKUP_ROOT/fnos"
prune_rotations_under "$BACKUP_ROOT/lxc-proxy"

log "prune_backup_rotations complete"
