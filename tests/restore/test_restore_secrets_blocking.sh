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
PRIMARY_CHANNEL_TOKEN=primary-secret
EOF

if RESTORE_STATE_ROOT="$RESTORE_STATE_ROOT" \
  RESTORE_TARGET_ROOT="$RESTORE_TARGET_ROOT" \
  SECRETS_TEMPLATE_PATH="$SECRETS_TEMPLATE" \
  SECRETS_REAL_DIR="$SECRETS_REAL_DIR" \
  bash "$ROOT/restore/layers/50-secrets.sh" apply >"$TMP/out.txt" 2>&1; then
  echo 'secrets apply should fail when blocking secret is missing' >&2
  exit 1
fi

grep -Eq 'BLOCK|missing blocking secret|OPENCLAW_API_TOKEN' "$TMP/out.txt" || { echo 'blocking message missing' >&2; exit 1; }

echo 'PASS test_restore_secrets_blocking'
