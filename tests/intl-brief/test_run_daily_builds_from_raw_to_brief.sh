#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

mkdir -p "$TMP/state/intl-brief/raw"
cat > "$TMP/state/intl-brief/raw/2026-05-07.json" <<JSON
[
  {
    "source": "Reuters",
    "title": "Fed signals higher-for-longer rates as markets reprice",
    "summary": "Global markets adjusted after hawkish Fed remarks.",
    "published_at": "2026-05-06T18:00:00Z"
  },
  {
    "source": "BBC",
    "title": "Ceasefire talks continue in Middle East",
    "summary": "Negotiators say progress was made but core disputes remain.",
    "published_at": "2026-05-06T20:00:00Z"
  }
]
JSON

export INTL_BRIEF_ROOT="$TMP/state/intl-brief"
export INTL_BRIEF_DATE="2026-05-07"

bash "$ROOT/scripts/intl-brief/run_daily.sh"

test -f "$TMP/state/intl-brief/normalized/2026-05-07.json" || { echo 'normalized file missing'; exit 1; }
test -f "$TMP/state/intl-brief/briefs/2026-05-07.md" || { echo 'brief file missing'; exit 1; }
grep -q '## 分类补充' "$TMP/state/intl-brief/briefs/2026-05-07.md" || { echo 'brief missing category section'; exit 1; }
grep -Eq '全球经济与市场|国际政治' "$TMP/state/intl-brief/briefs/2026-05-07.md" || { echo 'brief missing expected category heading'; exit 1; }

echo 'PASS test_run_daily_builds_from_raw_to_brief'
