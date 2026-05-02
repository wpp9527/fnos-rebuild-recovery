#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

export INTL_BRIEF_ROOT="$TMP/state/intl-brief"
export INTL_BRIEF_DATE="2026-05-03"

bash "$ROOT/scripts/intl-brief/run_daily.sh"

for d in raw normalized briefs runs; do
  test -d "$TMP/state/intl-brief/$d" || { echo "missing dir: $d"; exit 1; }
done

test -s "$TMP/state/intl-brief/briefs/2026-05-03.md" || { echo 'brief should be non-empty'; exit 1; }

echo 'PASS test_run_daily_initializes_all_state_dirs'
