#!/usr/bin/env bash
set -euo pipefail
DRILL_ROOT="${DRILL_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/reports}"
mkdir -p "$DRILL_ROOT"
TS="$(date +%Y-%m-%d-%H%M%S)"
REPORT="$DRILL_ROOT/restore-drill-$TS.md"
cat > "$REPORT" <<EOF
# Restore Drill Report

Generated: $TS

Steps:
- bootstrap plan
- preflight
- verify review

Result:
- drill scaffold complete
EOF
echo "restore drill report generated: $REPORT"
