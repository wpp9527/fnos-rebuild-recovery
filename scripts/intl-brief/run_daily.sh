#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BRIEF_ROOT="${INTL_BRIEF_ROOT:-$ROOT_DIR/state/intl-brief}"
RUN_DATE="${INTL_BRIEF_DATE:-$(date +%F)}"

mkdir -p "$BRIEF_ROOT/raw" "$BRIEF_ROOT/normalized" "$BRIEF_ROOT/briefs" "$BRIEF_ROOT/runs"

python3 "$ROOT_DIR/scripts/intl-brief/fetch_sources.py"
python3 "$ROOT_DIR/scripts/intl-brief/build_brief.py"
python3 "$ROOT_DIR/scripts/intl-brief/render_brief.py"

BRIEF_PATH="$BRIEF_ROOT/briefs/$RUN_DATE.md"
NORMALIZED_PATH="$BRIEF_ROOT/normalized/$RUN_DATE.json"
RAW_PATH="$BRIEF_ROOT/raw/$RUN_DATE.json"

cat > "$BRIEF_ROOT/runs/latest.json" <<JSON
{
  "status": "ok",
  "date": "$RUN_DATE",
  "stage": "rendered",
  "brief_path": "$BRIEF_PATH",
  "normalized_path": "$NORMALIZED_PATH",
  "raw_path": "$RAW_PATH"
}
JSON

python3 "$ROOT_DIR"/scripts/intl-brief/push_feishu.py
