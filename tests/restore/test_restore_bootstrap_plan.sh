#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

RESTORE_STATE_ROOT="$TMP/state/restore"
mkdir -p "$RESTORE_STATE_ROOT"

RESTORE_STATE_ROOT="$RESTORE_STATE_ROOT" \
SOURCE_MODE='github' \
bash "$ROOT/restore/bootstrap.sh" plan

[[ -f "$RESTORE_STATE_ROOT/context.env" ]] || { echo 'missing restore context.env' >&2; exit 1; }
PLAN_MD="$(find "$RESTORE_STATE_ROOT/plans" -maxdepth 1 -name 'restore-plan-*.md' | head -n 1)"
PLAN_JSON="$(find "$RESTORE_STATE_ROOT/plans" -maxdepth 1 -name 'restore-plan-*.json' | head -n 1)"

[[ -n "$PLAN_MD" && -f "$PLAN_MD" ]] || { echo 'missing restore plan markdown' >&2; exit 1; }
[[ -n "$PLAN_JSON" && -f "$PLAN_JSON" ]] || { echo 'missing restore plan json' >&2; exit 1; }

grep -Fq 'SOURCE_MODE=github' "$RESTORE_STATE_ROOT/context.env" || { echo 'context missing source mode' >&2; exit 1; }
grep -Fq 'github' "$PLAN_MD" || { echo 'plan markdown missing source mode' >&2; exit 1; }
grep -Fq '"source_mode": "github"' "$PLAN_JSON" || { echo 'plan json missing source mode' >&2; exit 1; }

echo 'PASS test_restore_bootstrap_plan'
