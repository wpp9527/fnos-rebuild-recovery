#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
RESTORE_STATE_ROOT="$TMP/state/restore"
RESTORE_TARGET_ROOT="$TMP/target"
mkdir -p "$RESTORE_STATE_ROOT" "$RESTORE_TARGET_ROOT/openclaw" "$RESTORE_TARGET_ROOT/services/media-stack"
cat > "$RESTORE_TARGET_ROOT/openclaw/.env" <<'EOF'
OPENCLAW_BASE_URL=https://example.local
OPENCLAW_API_TOKEN=secret-token
PRIMARY_CHANNEL_TOKEN=primary-secret
EOF
OUT="$(RESTORE_STATE_ROOT="$RESTORE_STATE_ROOT" RESTORE_TARGET_ROOT="$RESTORE_TARGET_ROOT" bash "$ROOT/restore/layers/30-services.sh" plan)"
printf '%s' "$OUT" | grep -Fq 'services plan ready' || { echo 'missing services plan output' >&2; exit 1; }
PLAN_MD="$(find "$RESTORE_STATE_ROOT/plans" -maxdepth 1 -name 'services-plan-*.md' | head -n 1)"
[[ -f "$PLAN_MD" ]] || { echo 'missing services plan markdown' >&2; exit 1; }
grep -Fq 'openclaw' "$PLAN_MD" || { echo 'plan missing openclaw service' >&2; exit 1; }
echo 'PASS test_restore_services_plan'
