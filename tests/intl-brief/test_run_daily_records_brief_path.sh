#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

export INTL_BRIEF_ROOT="$TMP/state/intl-brief"
export INTL_BRIEF_DATE="2026-05-04"

bash "$ROOT/scripts/intl-brief/run_daily.sh"

grep -q '"brief_path"' "$TMP/state/intl-brief/runs/latest.json" || { echo 'brief_path missing from latest.json'; exit 1; }
grep -q '2026-05-04.md' "$TMP/state/intl-brief/runs/latest.json" || { echo 'brief_path should point to dated brief'; exit 1; }

echo 'PASS test_run_daily_records_brief_path'
