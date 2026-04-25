#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TMP="$(mktemp -d)"
BACKUP_ROOT="$TMP/backup"
mkdir -p "$BACKUP_ROOT/shared/secrets/latest/channels"

# Create fake docker binary that mimics real container env format
# Note: no set -e, always returns 0
BIN_DIR="$TMP/bin"
mkdir -p "$BIN_DIR"
cat > "$BIN_DIR/docker" <<'DOCKEREOF'
#!/usr/bin/env bash
if [[ "$1" == "inspect" && "$2" == "homarr" ]]; then
  echo 'AUTH_PASSWORD=homarr-test-pass'
  echo 'SECRET_ENCRYPTION_KEY=test-enc-key'
elif [[ "$1" == "inspect" && "$2" == "halo-blog" ]]; then
  echo 'HALO_SECURITY_INITIALIZER_PASSWORD=halo-test-pass'
elif [[ "$1" == "inspect" && "$2" == "jellyfin" ]]; then
  echo 'JELLYFIN_API_KEY=jellyfin-test-key'
elif [[ "$1" == "inspect" && "$2" == "feishu-observe" ]]; then
  echo "OPENCLAW_GATEWAY_AUTH_TOKEN=shared-token"
  echo "FEISHU_APP_SECRET=feishu-secret"
  echo "OPENAI_API_KEY=openai-key"
elif [[ "$1" == "inspect" && "$2" == "qq-observe" ]]; then
  echo "OPENCLAW_GATEWAY_AUTH_TOKEN=shared-token"
  echo "QQ_APP_SECRET=qq-secret"
fi
exit 0
DOCKEREOF
chmod +x "$BIN_DIR/docker"

PATH="$BIN_DIR:$PATH" BACKUP_ROOT="$BACKUP_ROOT" bash "$ROOT/scripts/backup/tasks/publish_secrets.sh"

SECRETS_DEST="$BACKUP_ROOT/shared/secrets/latest"
[[ -f "$SECRETS_DEST/openclaw.env" ]] || { echo 'missing openclaw.env' >&2; exit 1; }
grep -Fq 'OPENCLAW_GATEWAY_AUTH_TOKEN=shared-token' "$SECRETS_DEST/openclaw.env" || { echo 'missing gateway token' >&2; exit 1; }
[[ -f "$SECRETS_DEST/fnos-media-stack.env" ]] || { echo 'missing fnos-media-stack.env' >&2; exit 1; }
grep -Fq 'HOMARR_AUTH_PASSWORD=homarr-test-pass' "$SECRETS_DEST/fnos-media-stack.env" || { echo 'missing homarr password' >&2; exit 1; }
grep -Fq 'HALO_INITIALIZER_PASSWORD=halo-test-pass' "$SECRETS_DEST/fnos-media-stack.env" || { echo 'missing halo password' >&2; exit 1; }
rm -rf "$TMP"
echo 'PASS test_publish_secrets_includes_fnos_media_stack'
