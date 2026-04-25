#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
DRILL_ROOT="$TMP/drill"
mkdir -p "$DRILL_ROOT"
OUT="$(DRILL_ROOT="$DRILL_ROOT" bash "$ROOT/restore/run_restore_drill.sh")"
printf '%s' "$OUT" | grep -Fq 'restore drill report generated' || { echo 'missing drill output' >&2; exit 1; }
REPORT="$(find "$DRILL_ROOT" -maxdepth 1 -name 'restore-drill-*.md' | head -n 1)"
[[ -f "$REPORT" ]] || { echo 'missing drill report' >&2; exit 1; }
grep -Fq 'Restore Drill Report' "$REPORT" || { echo 'drill report missing title' >&2; exit 1; }
echo 'PASS test_restore_drill_report'
