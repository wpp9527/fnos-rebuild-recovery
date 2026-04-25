#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
LIVE_COMPOSE="$TMP/live-compose.yml"
TEMPLATE_COMPOSE="$TMP/template-compose.yml"
CATALOG="$TMP/service-catalog.yaml"
REPORT_ROOT="$TMP/reports"
mkdir -p "$REPORT_ROOT"
cat > "$LIVE_COMPOSE" <<'EOF'
services:
  homarr:
    image: example/homarr
EOF
cp "$LIVE_COMPOSE" "$TEMPLATE_COMPOSE"
cat > "$CATALOG" <<'EOF'
services:
  - name: fnos-media-stack
    compose_path: /opt/fnos-media-stack/docker-compose.yml
EOF
OUT="$(LIVE_COMPOSE_PATH="$LIVE_COMPOSE" TEMPLATE_COMPOSE_PATH="$TEMPLATE_COMPOSE" SERVICE_CATALOG_PATH="$CATALOG" AUDIT_REPORT_ROOT="$REPORT_ROOT" bash "$ROOT/scripts/backup/audit_runtime_state.sh")"
REPORT="$(find "$REPORT_ROOT" -maxdepth 1 -name 'runtime-state-audit-*.md' | head -n 1)"
[[ -f "$REPORT" ]] || { echo 'missing audit report' >&2; exit 1; }
grep -Fq 'runtime service missing recovery mapping' "$REPORT" || { echo 'missing unmapped runtime warning' >&2; exit 1; }
echo 'PASS test_audit_runtime_state_detects_unmapped_runtime_container'
