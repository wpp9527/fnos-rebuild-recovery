#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
CATALOG="$TMP/service-catalog.yaml"
REPORT_ROOT="$TMP/reports"
mkdir -p "$REPORT_ROOT"

# Catalog with incomplete mapping
cat > "$CATALOG" <<'EOF'
services:
  - name: fnos-media-stack
    compose_path: /opt/fnos-media-stack/docker-compose.yml
    must_back_up:
      - /opt/fnos-media-stack/homarr/config
EOF

# Test that audit warns about missing service mappings
SERVICE_CATALOG_PATH="$CATALOG" AUDIT_REPORT_ROOT="$REPORT_ROOT" \
bash "$ROOT/scripts/backup/audit_runtime_state.sh" 2>/dev/null || true

REPORT="$(find "$REPORT_ROOT" -maxdepth 1 -name 'runtime-state-audit-*.md' | head -n 1)"
[[ -f "$REPORT" ]] || { echo 'missing audit report' >&2; exit 1; }

# Should have unmapped running containers warning
grep -Fq 'running container missing recovery mapping' "$REPORT" || { echo 'missing unmapped container warning' >&2; exit 1; }
echo 'PASS test_audit_reports_missing_service_mappings'
