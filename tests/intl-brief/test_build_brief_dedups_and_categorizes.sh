#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

mkdir -p "$TMP/state/intl-brief/raw" "$TMP/state/intl-brief/normalized"
cat > "$TMP/state/intl-brief/raw/2026-05-06.json" <<JSON
[
  {
    "source": "Reuters",
    "title": "Fed signals higher-for-longer rates as markets reprice",
    "summary": "Global markets adjusted after hawkish Fed remarks.",
    "published_at": "2026-05-05T18:00:00Z"
  },
  {
    "source": "AP",
    "title": "Markets reprice after Fed keeps hawkish tone",
    "summary": "Investors adjusted expectations after the latest Fed signaling.",
    "published_at": "2026-05-05T18:05:00Z"
  },
  {
    "source": "BBC",
    "title": "Ceasefire talks continue in Middle East",
    "summary": "Negotiators say progress was made but core disputes remain.",
    "published_at": "2026-05-05T20:00:00Z"
  }
]
JSON

export INTL_BRIEF_ROOT="$TMP/state/intl-brief"
export INTL_BRIEF_DATE="2026-05-06"
python3 "$ROOT/scripts/intl-brief/build_brief.py"

OUT="$TMP/state/intl-brief/normalized/2026-05-06.json"
test -f "$OUT" || { echo 'normalized output missing'; exit 1; }
grep -q '"source_count": 2' "$OUT" || { echo 'expected deduped fed event with source_count 2'; exit 1; }
grep -q '全球经济与市场' "$OUT" || { echo 'expected economy category'; exit 1; }
grep -q '国际政治' "$OUT" || { echo 'expected politics category'; exit 1; }

echo 'PASS test_build_brief_dedups_and_categorizes'
