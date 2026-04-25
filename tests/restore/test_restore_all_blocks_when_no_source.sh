#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

RESTORE_STATE_ROOT="$TMP/state/restore"
mkdir -p "$RESTORE_STATE_ROOT"

if RESTORE_STATE_ROOT="$RESTORE_STATE_ROOT" FORCE_GITHUB_ACCESS=0 FORCE_NAS_ACCESS=0 bash "$ROOT/restore/restore-all.sh" plan >"$TMP/out.txt" 2>&1; then
  echo 'restore-all should have failed with no source available' >&2
  exit 1
fi

grep -Eq 'no restore source available|BLOCK' "$TMP/out.txt" || { echo 'missing block message for no source available' >&2; exit 1; }

echo 'PASS test_restore_all_blocks_when_no_source'
