#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
BACKUP_ROOT="$TMP/backup"
OPENCLAW_CONFIG="$TMP/openclaw.json"
FNOS_ENV="$TMP/fnos-media-stack.env"
mkdir -p "$BACKUP_ROOT/shared/secrets/latest"
# Create fake OpenClaw config with secrets
cat > "$OPENCLAW_CONFIG" <<'EOF'
{
  "agents": {
    "defaults": {
      "primaryChannelToken": "test-primary-token-123",
      "baseUrl": "https://test.openclaw.local"
    }
  }
}
EOF
# Create fake fnos-media-stack env
cat > "$FNOS_ENV" <<'EOF'
HOMARR_AUTH_PASSWORD=homarr-pass
HOMARR_SECRET_ENCRYPTION_KEY=enc-key-xyz
HALO_INITIALIZER_PASSWORD=halo-pass
SOME_OTHER_VAR=ignore-me
EOF
OPENCLAW_CONFIG="$OPENCLAW_CONFIG" FNOS_MEDIA_ENV="$FNOS_ENV" BACKUP_ROOT="$BACKUP_ROOT" bash "$ROOT/scripts/backup/tasks/publish_secrets.sh"
SECRETS_DEST="$BACKUP_ROOT/shared/secrets/latest"
[[ -f "$SECRETS_DEST/openclaw.env" ]] || { echo 'missing openclaw.env' >&2; exit 1; }
grep -Fq 'PRIMARY_CHANNEL_TOKEN=test-primary-token-123' "$SECRETS_DEST/openclaw.env" || { echo 'missing primary token' >&2; exit 1; }
grep -Fq 'OPENCLAW_BASE_URL=https://test.openclaw.local' "$SECRETS_DEST/openclaw.env" || { echo 'missing base url' >&2; exit 1; }
[[ -f "$SECRETS_DEST/fnos-media-stack.env" ]] || { echo 'missing fnos-media-stack.env' >&2; exit 1; }
grep -Fq 'HOMARR_AUTH_PASSWORD=homarr-pass' "$SECRETS_DEST/fnos-media-stack.env" || { echo 'missing homarr password' >&2; exit 1; }
grep -Fq 'HALO_INITIALIZER_PASSWORD=halo-pass' "$SECRETS_DEST/fnos-media-stack.env" || { echo 'missing halo password' >&2; exit 1; }
grep -Fq 'SOME_OTHER_VAR' "$SECRETS_DEST/fnos-media-stack.env" && { echo 'should not include non-secret vars' >&2; exit 1; }
echo 'PASS test_publish_secrets_creates_recovery_secrets'
