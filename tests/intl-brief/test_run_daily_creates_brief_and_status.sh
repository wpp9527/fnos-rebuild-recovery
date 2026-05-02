#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

mkdir -p "$TMP/state/intl-brief/raw" "$TMP/state/intl-brief/normalized" "$TMP/state/intl-brief/briefs" "$TMP/state/intl-brief/runs"
export INTL_BRIEF_ROOT="$TMP/state/intl-brief"
export INTL_BRIEF_DATE="2026-05-02"

bash "$ROOT/scripts/intl-brief/run_daily.sh"

test -f "$TMP/state/intl-brief/briefs/2026-05-02.md" || { echo 'missing brief output'; exit 1; }
test -f "$TMP/state/intl-brief/runs/latest.json" || { echo 'missing latest run status'; exit 1; }

grep -q '国际大事简讯' "$TMP/state/intl-brief/briefs/2026-05-02.md" || { echo 'brief title missing'; exit 1; }
grep -q '"status": "ok"' "$TMP/state/intl-brief/runs/latest.json" || { echo 'run status not ok'; exit 1; }

echo 'PASS test_run_daily_creates_brief_and_status'
