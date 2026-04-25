#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

RESTORE_STATE_ROOT="$TMP/state/restore"
mkdir -p "$RESTORE_STATE_ROOT"

OUT="$(RESTORE_STATE_ROOT="$RESTORE_STATE_ROOT" FORCE_GITHUB_ACCESS=1 FORCE_NAS_ACCESS=0 bash "$ROOT/restore/bootstrap.sh" plan --source hybrid)"

printf '%s' "$OUT" | grep -Fq 'selected source: github' || { echo 'hybrid fallback did not select github' >&2; exit 1; }
grep -Fq 'SOURCE_MODE=hybrid' "$RESTORE_STATE_ROOT/context.env" || { echo 'context missing hybrid source mode' >&2; exit 1; }
grep -Fq 'SOURCE_SELECTED=github' "$RESTORE_STATE_ROOT/context.env" || { echo 'context missing fallback github selection' >&2; exit 1; }
grep -Fq 'GITHUB_ACCESS=1' "$RESTORE_STATE_ROOT/context.env" || { echo 'context missing github access flag' >&2; exit 1; }
grep -Fq 'NAS_ACCESS=0' "$RESTORE_STATE_ROOT/context.env" || { echo 'context missing nas access flag' >&2; exit 1; }

echo 'PASS test_bootstrap_source_hybrid_fallback'
