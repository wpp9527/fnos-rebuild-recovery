#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
LIVE_COMPOSE="$TMP/live-compose.yml"
TEMPLATE_COMPOSE="$TMP/template-compose.yml"
REPORT_ROOT="$TMP/reports"
mkdir -p "$REPORT_ROOT" "$TMP/opt/fnos-media-stack/homarr/config"
cat > "$LIVE_COMPOSE" <<'EOF'
services:
  homarr:
    volumes:
      - TMPROOT/opt/fnos-media-stack/homarr/config:/app/data/config
      - TMPROOT/opt/fnos-media-stack/homarr/appdata:/appdata
EOF
sed -i "s#TMPROOT#$TMP#g" "$LIVE_COMPOSE"
cp "$LIVE_COMPOSE" "$TEMPLATE_COMPOSE"
OUT="$(LIVE_COMPOSE_PATH="$LIVE_COMPOSE" TEMPLATE_COMPOSE_PATH="$TEMPLATE_COMPOSE" AUDIT_REPORT_ROOT="$REPORT_ROOT" bash "$ROOT/scripts/backup/audit_runtime_state.sh")"
REPORT="$(find "$REPORT_ROOT" -maxdepth 1 -name 'runtime-state-audit-*.md' | head -n 1)"
[[ -f "$REPORT" ]] || { echo 'missing audit report' >&2; exit 1; }
grep -Fq 'missing local state path' "$REPORT" || { echo 'missing local state warning' >&2; exit 1; }
echo 'PASS test_audit_runtime_state_detects_missing_local_dirs'
