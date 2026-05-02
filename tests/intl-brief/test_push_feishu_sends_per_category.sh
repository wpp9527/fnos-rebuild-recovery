#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/state/intl-brief/normalized" "$TMP/state/intl-brief/runs"
cat > "$TMP/state/intl-brief/normalized/2026-05-06.json" <<JSON
{
  "events": [
    {
      "canonical_title": "日本采购俄罗斯石油",
      "category": "全球经济与市场",
      "summary": "日本首次采购俄罗斯石油。",
      "status_label": "多源基本一致",
      "importance_score": 3,
      "source_count": 1
    },
    {
      "canonical_title": "日本奈良县发生5.7级地震",
      "category": "灾害与环境",
      "summary": "日本气象厅确认。",
      "status_label": "多源基本一致",
      "importance_score": 4,
      "source_count": 2
    }
  ],
  "source_errors": []
}
JSON
printf '{"status":"ok","date":"2026-05-06"}\n' > "$TMP/state/intl-brief/runs/latest.json"
export INTL_BRIEF_ROOT="$TMP/state/intl-brief"
export INTL_BRIEF_DATE="2026-05-06"
python3 "$ROOT/scripts/intl-brief/push_feishu.py" 2>/dev/null; RC=$?
OUT="$TMP/state/intl-brief/runs/latest.json"
grep -q 'global_market' "$OUT" || { echo 'expected per-category push tracking'; exit 1; }
grep -q 'disaster' "$OUT" || { echo 'expected disaster category push'; exit 1; }
echo 'PASS test_push_feishu_sends_per_category'
