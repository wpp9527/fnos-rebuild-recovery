#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
LIVE_COMPOSE="$TMP/live-compose.yml"
TEMPLATE_COMPOSE="$TMP/template-compose.yml"
REPORT_ROOT="$TMP/reports"
mkdir -p "$REPORT_ROOT"
cat > "$LIVE_COMPOSE" <<'EOF'
services:
  homarr:
    volumes:
      - /opt/fnos-media-stack/homarr/config:/app/data/config
      - /var/lib/docker/volumes/anon/_data:/appdata
EOF
cat > "$TEMPLATE_COMPOSE" <<'EOF'
services:
  homarr:
    volumes:
      - /opt/fnos-media-stack/homarr/config:/app/data/config
      - /opt/fnos-media-stack/homarr/appdata:/appdata
EOF
OUT="$(LIVE_COMPOSE_PATH="$LIVE_COMPOSE" TEMPLATE_COMPOSE_PATH="$TEMPLATE_COMPOSE" AUDIT_REPORT_ROOT="$REPORT_ROOT" bash "$ROOT/scripts/backup/audit_runtime_state.sh")"
printf '%s' "$OUT" | grep -Fq 'audit report:' || { echo 'missing audit output' >&2; exit 1; }
REPORT="$(find "$REPORT_ROOT" -maxdepth 1 -name 'runtime-state-audit-*.md' | head -n 1)"
[[ -f "$REPORT" ]] || { echo 'missing audit report' >&2; exit 1; }
grep -Fq 'anonymous volume detected' "$REPORT" || { echo 'missing anonymous volume finding' >&2; exit 1; }
grep -Fq 'compose drift detected' "$REPORT" || { echo 'missing compose drift finding' >&2; exit 1; }
echo 'PASS test_audit_runtime_state_detects_homarr_volume_and_drift'
