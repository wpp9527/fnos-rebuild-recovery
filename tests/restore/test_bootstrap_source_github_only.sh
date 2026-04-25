#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

RESTORE_STATE_ROOT="$TMP/state/restore"
mkdir -p "$RESTORE_STATE_ROOT"

OUT="$(RESTORE_STATE_ROOT="$RESTORE_STATE_ROOT" FORCE_GITHUB_ACCESS=1 FORCE_NAS_ACCESS=0 bash "$ROOT/restore/bootstrap.sh" plan --source github)"

printf '%s' "$OUT" | grep -Fq 'selected source: github' || { echo 'bootstrap did not select github' >&2; exit 1; }
grep -Fq 'SOURCE_MODE=github' "$RESTORE_STATE_ROOT/context.env" || { echo 'context missing github source mode' >&2; exit 1; }
grep -Fq 'SOURCE_SELECTED=github' "$RESTORE_STATE_ROOT/context.env" || { echo 'context missing selected github source' >&2; exit 1; }

echo 'PASS test_bootstrap_source_github_only'
