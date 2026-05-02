#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

mkdir -p "$TMP/state/intl-brief/normalized" "$TMP/state/intl-brief/briefs"
cat > "$TMP/state/intl-brief/normalized/2026-05-05.json" <<JSON
[
  {
    "canonical_title": "美联储释放维持高利率信号，全球市场重新定价",
    "category": "全球经济与市场",
    "summary": "多家媒体报道称，美联储表态偏鹰，全球债券与股票市场同步调整。",
    "status_label": "多源基本一致"
  },
  {
    "canonical_title": "中东停火谈判出现新进展，但关键条款仍未敲定",
    "category": "国际政治",
    "summary": "有关各方释放继续谈判信号，但核心分歧仍未完全弥合。",
    "status_label": "细节仍在发展"
  }
]
JSON

export INTL_BRIEF_ROOT="$TMP/state/intl-brief"
export INTL_BRIEF_DATE="2026-05-05"
python3 "$ROOT/scripts/intl-brief/render_brief.py"

OUT="$TMP/state/intl-brief/briefs/2026-05-05.md"
test -f "$OUT" || { echo 'rendered brief missing'; exit 1; }
grep -q '## 今日最重要' "$OUT" || { echo 'missing top stories section'; exit 1; }
grep -q '## 分类补充' "$OUT" || { echo 'missing category section'; exit 1; }
grep -q '全球经济与市场' "$OUT" || { echo 'missing economy category'; exit 1; }
grep -q '国际政治' "$OUT" || { echo 'missing politics category'; exit 1; }
grep -q '多源基本一致' "$OUT" || { echo 'missing status label'; exit 1; }

echo 'PASS test_render_brief_from_sample_events'
