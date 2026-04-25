#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
STATE_ROOT="$TMP/state/restore"
TARGET_ROOT="$TMP/target"
SECRETS_REAL_DIR="$TMP/secrets"
mkdir -p "$STATE_ROOT" "$TARGET_ROOT/openclaw" "$SECRETS_REAL_DIR"
cat > "$SECRETS_REAL_DIR/openclaw.env" <<'EOF'
# OpenClaw gateway recovery secrets
OPENCLAW_GATEWAY_AUTH_TOKEN=drill-gateway-token-xyz
EOF
SECRETS_TEMPLATE_PATH="$ROOT/restore/templates/secrets/.env.example" \
SECRETS_REAL_DIR="$SECRETS_REAL_DIR" \
RESTORE_STATE_ROOT="$STATE_ROOT" \
RESTORE_TARGET_ROOT="$TARGET_ROOT" \
bash "$ROOT/restore/layers/50-secrets.sh" apply >/dev/null
TARGET_ENV="$TARGET_ROOT/openclaw/.env"
[[ -f "$TARGET_ENV" ]] || { echo 'missing target .env' >&2; exit 1; }
grep -Fq 'OPENCLAW_GATEWAY_AUTH_TOKEN=drill-gateway-token-xyz' "$TARGET_ENV" || { echo 'missing gateway token' >&2; exit 1; }
echo 'PASS test_restore_secrets_reads_from_published'
