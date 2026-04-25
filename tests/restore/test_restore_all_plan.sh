#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

RESTORE_STATE_ROOT="$TMP/state/restore"
mkdir -p "$RESTORE_STATE_ROOT"

RESTORE_STATE_ROOT="$RESTORE_STATE_ROOT" \
SOURCE_MODE='nas' \
bash "$ROOT/restore/restore-all.sh" plan

SUMMARY_MD="$(find "$RESTORE_STATE_ROOT/reports" -maxdepth 1 -name 'restore-summary-*.md' | head -n 1)"
RESULT_JSON="$(find "$RESTORE_STATE_ROOT/reports" -maxdepth 1 -name 'restore-result-*.json' | head -n 1)"
PLAN_MD="$(find "$RESTORE_STATE_ROOT/plans" -maxdepth 1 -name 'restore-plan-*.md' | head -n 1)"

[[ -n "$SUMMARY_MD" && -f "$SUMMARY_MD" ]] || { echo 'missing restore summary markdown' >&2; exit 1; }
[[ -n "$RESULT_JSON" && -f "$RESULT_JSON" ]] || { echo 'missing restore result json' >&2; exit 1; }
[[ -n "$PLAN_MD" && -f "$PLAN_MD" ]] || { echo 'missing restore plan markdown' >&2; exit 1; }

grep -Fq 'nas' "$SUMMARY_MD" || { echo 'summary missing source mode' >&2; exit 1; }
grep -Fq '"mode": "plan"' "$RESULT_JSON" || { echo 'result json missing mode' >&2; exit 1; }
grep -Fq '"source_mode": "nas"' "$RESULT_JSON" || { echo 'result json missing source mode' >&2; exit 1; }

echo 'PASS test_restore_all_plan'
