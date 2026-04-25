#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

RESTORE_STATE_ROOT="$TMP/state/restore"
mkdir -p "$RESTORE_STATE_ROOT"

echo 'case 1: pass/warn'
OUT1="$(RESTORE_STATE_ROOT="$RESTORE_STATE_ROOT" FORCE_GITHUB_ACCESS=1 FORCE_NAS_ACCESS=0 bash "$ROOT/restore/layers/90-verify.sh" preflight)"
printf '%s' "$OUT1" | grep -Fq 'PRECHECK SUMMARY' || { echo 'missing preflight summary' >&2; exit 1; }
printf '%s' "$OUT1" | grep -Eq 'PASS|WARN' || { echo 'missing pass/warn status' >&2; exit 1; }

echo 'case 2: block'
if RESTORE_STATE_ROOT="$RESTORE_STATE_ROOT" FORCE_GITHUB_ACCESS=0 FORCE_NAS_ACCESS=0 bash "$ROOT/restore/layers/90-verify.sh" preflight >"$TMP/preflight-block.txt" 2>&1; then
  echo 'preflight should block when no source available' >&2
  exit 1
fi
grep -Eq 'BLOCK|no restore source available' "$TMP/preflight-block.txt" || { echo 'missing block reason' >&2; exit 1; }

echo 'PASS test_restore_preflight_statuses'
