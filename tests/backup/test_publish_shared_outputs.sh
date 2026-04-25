#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

FAKE_WS="$TMP/workspace"
BACKUP_ROOT="$TMP/nas-backup"
STAGING_ROOT="$TMP/staging"

mkdir -p "$FAKE_WS/docs" "$BACKUP_ROOT"
echo 'hello spec' > "$FAKE_WS/docs/spec.md"

WORKSPACE_ROOT="$FAKE_WS" \
BACKUP_ROOT="$BACKUP_ROOT" \
STAGING_ROOT="$STAGING_ROOT" \
RUN_ARCHIVE=0 \
bash "$ROOT/scripts/backup/orchestrator.sh"

assert_exists() {
  local p="$1"
  if [[ ! -e "$p" ]]; then
    echo "ASSERT FAIL: expected path to exist: $p" >&2
    exit 1
  fi
}

assert_contains() {
  local p="$1"
  local needle="$2"
  if ! grep -Fq "$needle" "$p"; then
    echo "ASSERT FAIL: expected '$needle' in $p" >&2
    exit 1
  fi
}

MANIFEST="$BACKUP_ROOT/shared/version-index/latest/backup_target_manifest.yaml"
RESTORE_ORDER="$BACKUP_ROOT/shared/restore-guides/latest/restore-order.md"
HOST_MAP="$BACKUP_ROOT/shared/network-map/latest/host-service-map.yaml"
CHANGE_DIR="$BACKUP_ROOT/shared/change-log/latest"

assert_exists "$BACKUP_ROOT/services/openclaw/latest/docs/spec.md"
assert_exists "$MANIFEST"
assert_exists "$RESTORE_ORDER"
assert_exists "$HOST_MAP"
assert_exists "$CHANGE_DIR"
assert_contains "$MANIFEST" 'openclaw:'
assert_contains "$MANIFEST" 'status: success'
assert_contains "$MANIFEST" 'pve:'
assert_contains "$MANIFEST" 'status: not-configured'
assert_contains "$RESTORE_ORDER" 'Restore OpenClaw workspace and scripts'
assert_contains "$HOST_MAP" 'openclaw-controller'

change_count=$(find "$CHANGE_DIR" -maxdepth 1 -type f | wc -l | tr -d ' ')
if [[ "$change_count" -lt 1 ]]; then
  echo "ASSERT FAIL: expected at least one change summary" >&2
  exit 1
fi

echo 'PASS test_publish_shared_outputs'
