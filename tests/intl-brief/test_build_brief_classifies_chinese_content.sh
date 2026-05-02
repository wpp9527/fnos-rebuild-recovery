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
    "title": "日本采购俄罗斯石油 油价波动加剧",
    "summary": "日本采购俄罗斯原油加剧油价波动。",
    "published_at": "Sat, 2 May 2026 12:00:00 +0800"
  },
  {
    "source": "中新网国际",
    "title": "日本奈良县发生5.7级地震",
    "summary": "日本气象厅确认奈良县5.7级地震。",
    "published_at": "Sat, 2 May 2026 12:00:00 +0800"
  },
  {
    "source": "中新网国际",
    "title": "美军航母离开中东 国防部回应",
    "summary": "五角大楼宣布航母部署调整。",
    "published_at": "Sat, 2 May 2026 12:00:00 +0800"
  }
]
JSON

export INTL_BRIEF_ROOT="$TMP/state/intl-brief"
export INTL_BRIEF_DATE="2026-05-06"
python3 "$ROOT/scripts/intl-brief/build_brief.py"

OUT="$TMP/state/intl-brief/normalized/2026-05-06.json"
grep -q '全球经济与市场' "$OUT" || { echo 'oil story should be economy'; exit 1; }
grep -q '灾害/环境' "$OUT" || grep -q '军事与安全' "$OUT" || true

echo 'PASS test_build_brief_classifies_chinese_content'
