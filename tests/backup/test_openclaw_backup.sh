#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

FAKE_WS="$TMP/workspace"
BACKUP_ROOT="$TMP/nas-backup"
STAGING_ROOT="$TMP/staging"

mkdir -p "$FAKE_WS/docs" "$FAKE_WS/scripts" "$FAKE_WS/memory/.dreams" "$FAKE_WS/state"
mkdir -p "$BACKUP_ROOT"

echo 'hello spec' > "$FAKE_WS/docs/spec.md"
echo '#!/usr/bin/env bash
echo hi' > "$FAKE_WS/scripts/tool.sh"
echo 'ignore me' > "$FAKE_WS/memory/.dreams/ephemeral.txt"
echo '{"runtime":true}' > "$FAKE_WS/state/runtime.json"

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

assert_not_exists() {
  local p="$1"
  if [[ -e "$p" ]]; then
    echo "ASSERT FAIL: expected path to be absent: $p" >&2
    exit 1
  fi
}

assert_exists "$STAGING_ROOT/openclaw/docs/spec.md"
assert_exists "$STAGING_ROOT/openclaw/scripts/tool.sh"
assert_exists "$STAGING_ROOT/openclaw/restore-notes.md"
assert_not_exists "$STAGING_ROOT/openclaw/memory/.dreams/ephemeral.txt"
assert_not_exists "$STAGING_ROOT/openclaw/state/runtime.json"

echo 'PASS test_openclaw_backup'
