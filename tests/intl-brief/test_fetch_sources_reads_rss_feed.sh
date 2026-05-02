#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

cat > "$TMP/feed.xml" <<XML
<rss version="2.0">
  <channel>
    <title>Sample World Feed</title>
    <item>
      <title>Global markets slide after Fed remarks</title>
      <link>https://example.com/fed</link>
      <description>Stocks and bonds moved lower after the latest Fed commentary.</description>
      <pubDate>Fri, 01 May 2026 18:00:00 GMT</pubDate>
    </item>
    <item>
      <title>Ceasefire talks continue in Middle East</title>
      <link>https://example.com/mideast</link>
      <description>Negotiators reported progress but said core disputes remain.</description>
      <pubDate>Fri, 01 May 2026 20:00:00 GMT</pubDate>
    </item>
  </channel>
</rss>
XML

export INTL_BRIEF_ROOT="$TMP/state/intl-brief"
export INTL_BRIEF_DATE="2026-05-02"
export INTL_BRIEF_FEEDS="Sample=file://$TMP/feed.xml"
python3 "$ROOT/scripts/intl-brief/fetch_sources.py"

OUT="$TMP/state/intl-brief/raw/2026-05-02.json"
test -f "$OUT" || { echo 'raw output missing'; exit 1; }
grep -q 'Global markets slide after Fed remarks' "$OUT" || { echo 'rss story missing'; exit 1; }
if grep -q 'bootstrap' "$OUT"; then
  echo 'bootstrap fallback should not be used when rss feed succeeds'
  exit 1
fi

echo 'PASS test_fetch_sources_reads_rss_feed'
