#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
RESTORE_STATE_ROOT="$TMP/state/restore"
RESTORE_TARGET_ROOT="$TMP/target"
BIN_DIR="$TMP/bin"
SECRETS_REAL_DIR="$TMP/real"
mkdir -p "$RESTORE_STATE_ROOT" "$RESTORE_TARGET_ROOT/openclaw" "$BIN_DIR" "$SECRETS_REAL_DIR"
cat > "$RESTORE_TARGET_ROOT/openclaw/.env" <<'EOF'
OPENCLAW_BASE_URL=https://example.local
OPENCLAW_API_TOKEN=secret-token
PRIMARY_CHANNEL_TOKEN=primary-secret
EOF
cat > "$SECRETS_REAL_DIR/fnos-media-stack.env" <<'EOF'
HOMARR_AUTH_PASSWORD=homarr-secret
HALO_INITIALIZER_PASSWORD=halo-secret
HOMARR_SECRET_ENCRYPTION_KEY=super-enc-key
EOF
cat > "$BIN_DIR/docker" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
if [[ "$1" == "compose" && "$2" == "up" ]]; then
  exit 0
fi
if [[ "$1" == "compose" && "$2" == "config" ]]; then
  echo 'services:'
  exit 0
fi
exit 1
EOF
chmod +x "$BIN_DIR/docker"
PATH="$BIN_DIR:$PATH" RESTORE_STATE_ROOT="$RESTORE_STATE_ROOT" RESTORE_TARGET_ROOT="$RESTORE_TARGET_ROOT" SECRETS_REAL_DIR="$SECRETS_REAL_DIR" bash "$ROOT/restore/layers/30-services.sh" apply >/dev/null
STACK_DIR="$RESTORE_TARGET_ROOT/services/fnos-media-stack"
[[ -f "$STACK_DIR/docker-compose.yml" ]] || { echo 'missing fnos-media-stack compose' >&2; exit 1; }
[[ -f "$STACK_DIR/.env" ]] || { echo 'missing fnos-media-stack env' >&2; exit 1; }
grep -Fq 'HOMARR_AUTH_PASSWORD=homarr-secret' "$STACK_DIR/.env" || { echo 'missing homarr password' >&2; exit 1; }
grep -Fq 'HALO_INITIALIZER_PASSWORD=halo-secret' "$STACK_DIR/.env" || { echo 'missing halo password' >&2; exit 1; }
grep -Fq 'HOMARR_SECRET_ENCRYPTION_KEY=super-enc-key' "$STACK_DIR/.env" || { echo 'missing encryption key' >&2; exit 1; }
grep -Fq '' "$STACK_DIR/docker-compose.yml" && { echo 'unexpected binary compose file' >&2; exit 1; }
grep -Fq '' "$STACK_DIR/.env" && { echo 'unexpected binary env file' >&2; exit 1; }
if grep -Fq 'homarr-secret' "$STACK_DIR/docker-compose.yml"; then
  echo 'compose should not contain raw homarr secret' >&2
  exit 1
fi
grep -Fq '' "$STACK_DIR/.env" && exit 1
echo 'PASS test_restore_services_fnos_media_stack_apply'
