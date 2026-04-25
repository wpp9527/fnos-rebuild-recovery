#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

RESTORE_STATE_ROOT="$TMP/state/restore"
RESTORE_TARGET_ROOT="$TMP/target"
SECRETS_TEMPLATE="$TMP/templates/.env.example"
SECRETS_REAL_DIR="$TMP/real"
mkdir -p "$RESTORE_STATE_ROOT" "$RESTORE_TARGET_ROOT/openclaw" "$TMP/templates" "$SECRETS_REAL_DIR"

cat > "$SECRETS_TEMPLATE" <<'EOF'
OPENCLAW_BASE_URL=
OPENCLAW_API_TOKEN=
PRIMARY_CHANNEL_TOKEN=
EOF

cat > "$SECRETS_REAL_DIR/openclaw.env" <<'EOF'
OPENCLAW_BASE_URL=https://example.local
OPENCLAW_API_TOKEN=secret-token
PRIMARY_CHANNEL_TOKEN=primary-secret
EOF

RESTORE_STATE_ROOT="$RESTORE_STATE_ROOT" \
RESTORE_TARGET_ROOT="$RESTORE_TARGET_ROOT" \
SECRETS_TEMPLATE_PATH="$SECRETS_TEMPLATE" \
SECRETS_REAL_DIR="$SECRETS_REAL_DIR" \
bash "$ROOT/restore/layers/50-secrets.sh" apply

TARGET_ENV="$RESTORE_TARGET_ROOT/openclaw/.env"
[[ -f "$TARGET_ENV" ]] || { echo 'target env not created' >&2; exit 1; }
grep -Fq 'OPENCLAW_BASE_URL=https://example.local' "$TARGET_ENV" || { echo 'base url not rendered' >&2; exit 1; }
grep -Fq 'OPENCLAW_API_TOKEN=secret-token' "$TARGET_ENV" || { echo 'api token not rendered' >&2; exit 1; }
grep -Fq 'PRIMARY_CHANNEL_TOKEN=primary-secret' "$TARGET_ENV" || { echo 'channel token not rendered' >&2; exit 1; }

echo 'PASS test_restore_secrets_render'
