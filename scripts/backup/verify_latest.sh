#!/usr/bin/env bash
set -euo pipefail

BACKUP_ROOT="${BACKUP_ROOT:-/mnt/nas/backup}"
MAX_AGE_HOURS="${MAX_AGE_HOURS:-48}"
FAILED=0

log_fail() {
  echo "FAIL: $1" >&2
  FAILED=$((FAILED + 1))
}

require_dir() {
  [[ -d "$1" ]] || log_fail "missing required dir: $1"
}

require_file() {
  [[ -f "$1" ]] || log_fail "missing required file: $1"
}

# --- Structural checks ---
require_dir "$BACKUP_ROOT/services/openclaw/latest"
require_dir "$BACKUP_ROOT/pve/latest"
require_dir "$BACKUP_ROOT/fnos/latest"
require_dir "$BACKUP_ROOT/lxc-proxy/latest"
require_dir "$BACKUP_ROOT/container-volumes/latest"
require_file "$BACKUP_ROOT/shared/version-index/latest/backup_target_manifest.yaml"
require_file "$BACKUP_ROOT/shared/restore-guides/latest/restore-order.md"
require_file "$BACKUP_ROOT/shared/network-map/latest/host-service-map.yaml"
require_file "$BACKUP_ROOT/shared/secrets/latest/openclaw.env"

# --- File count minimums ---
check_min_files() {
  local path="$1"
  local min="$2"
  local label="$3"
  local count
  count=$(find "$path" -type f 2>/dev/null | wc -l)
  if [[ "$count" -lt "$min" ]]; then
    log_fail "$label: only $count files (min $min)"
  fi
}

check_min_files "$BACKUP_ROOT/services/openclaw/latest" 50 "openclaw"
check_min_files "$BACKUP_ROOT/pve/latest" 5 "pve"
check_min_files "$BACKUP_ROOT/fnos/latest" 10 "fnos"
check_min_files "$BACKUP_ROOT/lxc-proxy/latest" 3 "lxc-proxy"
check_min_files "$BACKUP_ROOT/container-volumes/latest" 5 "container-volumes"

# --- Freshness check (newest file not older than MAX_AGE_HOURS) ---
check_freshness() {
  local path="$1"
  local label="$2"
  local newest
  newest=$(find "$path" -type f -printf '%T@\n' 2>/dev/null | sort -rn | head -1 | sed 's/\..*//')
  if [ -z "$newest" ]; then
    log_fail "$label: no files to check freshness"
    return
  fi
  local now
  now=$(date +%s)
  local age_hours
  age_hours=$(( (now - newest) / 3600 ))
  if [ "$age_hours" -gt "$MAX_AGE_HOURS" ]; then
    log_fail "$label: newest file is ${age_hours}h old (max ${MAX_AGE_HOURS}h)"
  fi
}

check_freshness "$BACKUP_ROOT/services/openclaw/latest" "openclaw"
check_freshness "$BACKUP_ROOT/pve/latest" "pve"
check_freshness "$BACKUP_ROOT/container-volumes/latest" "container-volumes"

# --- Integrity checks ---
# manifest should have targets section
grep -q 'targets:' "$BACKUP_ROOT/shared/version-index/latest/backup_target_manifest.yaml" || \
  log_fail "manifest missing targets section"

if [[ "$FAILED" -eq 0 ]]; then
  echo 'backup verify PASS'
else
  echo "backup verify FAILED ($FAILED checks failed)"
  exit 1
fi
