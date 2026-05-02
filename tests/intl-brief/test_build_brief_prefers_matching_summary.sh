#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

mkdir -p "$TMP/state/intl-brief/raw" "$TMP/state/intl-brief/normalized"
cat > "$TMP/state/intl-brief/raw/2026-05-06.json" <<JSON
[
  {
    "source": "中新网国际",
    "title": "日本奈良县发生5.7级地震",
    "summary": "中新网5月2日电 综合报道，据日本气象厅5月2日消息，当地时间18时28分左右，日本奈良县发生5.7级地震。",
    "published_at": "Sat, 2 May 2026 18:30:00 +0800"
  },
  {
    "source": "中新网国际",
    "title": "美国一小型飞机坠毁 机上5人全部遇难",
    "summary": "中国5月1日开始担任联合国安理会当月轮值主席。",
    "published_at": "Sat, 2 May 2026 17:00:00 +0800"
  }
]
JSON

export INTL_BRIEF_ROOT="$TMP/state/intl-brief"
export INTL_BRIEF_DATE="2026-05-06"
python3 "$ROOT/scripts/intl-brief/build_brief.py"

OUT="$TMP/state/intl-brief/normalized/2026-05-06.json"
grep -q '日本奈良县发生5.7级地震' "$OUT" || { echo 'earthquake title missing'; exit 1; }
grep -q '日本气象厅' "$OUT" || { echo 'matching summary missing'; exit 1; }
if grep -q '联合国安理会当月轮值主席' "$OUT"; then
  echo 'mismatched summary should be filtered or replaced'
  exit 1
fi

echo 'PASS test_build_brief_prefers_matching_summary'
