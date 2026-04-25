#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
RESTORE_STATE_ROOT="$TMP/state/restore"
RESTORE_TARGET_ROOT="$TMP/target"
BIN_DIR="$TMP/bin"
mkdir -p "$RESTORE_STATE_ROOT" "$RESTORE_TARGET_ROOT/openclaw" "$RESTORE_TARGET_ROOT/services/media-stack" "$BIN_DIR"
cat > "$RESTORE_TARGET_ROOT/openclaw/.env" <<'EOF'
OPENCLAW_BASE_URL=https://example.local
OPENCLAW_API_TOKEN=secret-token
PRIMARY_CHANNEL_TOKEN=primary-secret
EOF
cat > "$BIN_DIR/docker" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
if [[ "$1" == "compose" && "$2" == "config" ]]; then
  echo 'services:'
  echo '  ok: true'
  exit 0
fi
if [[ "$1" == "compose" && "$2" == "up" ]]; then
  echo 'up ok'
  exit 0
fi
exit 1
EOF
chmod +x "$BIN_DIR/docker"
PATH="$BIN_DIR:$PATH" RESTORE_STATE_ROOT="$RESTORE_STATE_ROOT" RESTORE_TARGET_ROOT="$RESTORE_TARGET_ROOT" bash "$ROOT/restore/layers/30-services.sh" apply
OUT="$(PATH="$BIN_DIR:$PATH" RESTORE_STATE_ROOT="$RESTORE_STATE_ROOT" RESTORE_TARGET_ROOT="$RESTORE_TARGET_ROOT" bash "$ROOT/restore/layers/30-services.sh" verify)"
printf '%s' "$OUT" | grep -Fq 'services verify PASS' || { echo 'services verify did not pass' >&2; exit 1; }
[[ -f "$RESTORE_TARGET_ROOT/services/media-stack/docker-compose.yml" ]] || { echo 'compose file missing' >&2; exit 1; }
echo 'PASS test_restore_services_compose_config'
