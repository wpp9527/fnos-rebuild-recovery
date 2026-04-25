#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

RESTORE_STATE_ROOT="$TMP/state/restore"
RESTORE_TARGET_ROOT="$TMP/target"
SECRETS_TEMPLATE="$TMP/templates/.env.example"
SECRETS_REAL_DIR="$TMP/real"
mkdir -p "$RESTORE_STATE_ROOT/reports" "$RESTORE_TARGET_ROOT/openclaw" "$TMP/templates" "$SECRETS_REAL_DIR"

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
bash "$ROOT/restore/layers/50-secrets.sh" verify

REPORT="$(find "$RESTORE_STATE_ROOT/reports" -maxdepth 1 -name 'secrets-verify-*.md' | head -n 1)"
[[ -n "$REPORT" && -f "$REPORT" ]] || { echo 'missing secrets verify report' >&2; exit 1; }
grep -Fq 'OPENCLAW_API_TOKEN: present' "$REPORT" || { echo 'report missing presence status' >&2; exit 1; }
! grep -Fq 'secret-token' "$REPORT" || { echo 'report leaked secret token' >&2; exit 1; }
! grep -Fq 'primary-secret' "$REPORT" || { echo 'report leaked channel token' >&2; exit 1; }

echo 'PASS test_restore_secrets_redaction'
