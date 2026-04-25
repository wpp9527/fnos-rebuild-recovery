#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

RESTORE_STATE_ROOT="$TMP/state/restore"
mkdir -p "$RESTORE_STATE_ROOT"

OUT="$(RESTORE_STATE_ROOT="$RESTORE_STATE_ROOT" FORCE_GITHUB_ACCESS=0 FORCE_NAS_ACCESS=1 bash "$ROOT/restore/bootstrap.sh" plan --source nas)"

printf '%s' "$OUT" | grep -Fq 'selected source: nas' || { echo 'bootstrap did not select nas' >&2; exit 1; }
grep -Fq 'SOURCE_MODE=nas' "$RESTORE_STATE_ROOT/context.env" || { echo 'context missing nas source mode' >&2; exit 1; }
grep -Fq 'SOURCE_SELECTED=nas' "$RESTORE_STATE_ROOT/context.env" || { echo 'context missing selected nas source' >&2; exit 1; }

echo 'PASS test_bootstrap_source_nas_only'
