#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
LIVE_COMPOSE="$TMP/live-compose.yml"
REPORT_ROOT="$TMP/reports"
mkdir -p "$REPORT_ROOT"
cat > "$LIVE_COMPOSE" <<'EOF'
services:
  homarr:
    volumes:
      - /opt/fnos-media-stack/homarr/config:/app/data/config
EOF
OUT="$(LIVE_COMPOSE_PATH="$LIVE_COMPOSE" TEMPLATE_COMPOSE_PATH="$TMP/missing-template.yml" AUDIT_REPORT_ROOT="$REPORT_ROOT" bash "$ROOT/scripts/backup/audit_runtime_state.sh")"
REPORT="$(find "$REPORT_ROOT" -maxdepth 1 -name 'runtime-state-audit-*.md' | head -n 1)"
[[ -f "$REPORT" ]] || { echo 'missing audit report' >&2; exit 1; }
grep -Fq 'compose comparison skipped' "$REPORT" || { echo 'missing template warning' >&2; exit 1; }
echo 'PASS test_audit_runtime_state_detects_missing_template'
