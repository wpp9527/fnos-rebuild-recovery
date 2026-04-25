#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
RESTORE_STATE_ROOT="$TMP/state/restore"
RESTORE_TARGET_ROOT="$TMP/target"
FNOS_LATEST_ROOT="$TMP/fnos-latest"
OPENCLAW_LATEST_ROOT="$TMP/openclaw-latest"
SECRETS_TEMPLATE="$TMP/templates/.env.example"
SECRETS_REAL_DIR="$TMP/real"
BIN_DIR="$TMP/bin"
PVE_LATEST_ROOT="$TMP/pve-latest"
mkdir -p "$RESTORE_STATE_ROOT" "$RESTORE_TARGET_ROOT" "$BIN_DIR" \
  "$PVE_LATEST_ROOT" \
  "$FNOS_LATEST_ROOT/services/media-stack" "$FNOS_LATEST_ROOT/services/openclaw" "$FNOS_LATEST_ROOT/manifests" \
  "$OPENCLAW_LATEST_ROOT/docs" "$OPENCLAW_LATEST_ROOT/scripts/backup" "$OPENCLAW_LATEST_ROOT/memory" \
  "$TMP/templates" "$SECRETS_REAL_DIR"
echo 'pvehost' > "$PVE_LATEST_ROOT/hostname.txt"
echo 'Linux' > "$PVE_LATEST_ROOT/uname.txt"
echo 'vmid name' > "$PVE_LATEST_ROOT/vm-list.txt"
echo 'iface' > "$PVE_LATEST_ROOT/network-interfaces.txt"
echo 'compose: yes' > "$FNOS_LATEST_ROOT/services/media-stack/docker-compose.yml"
echo '{"ok":true}' > "$FNOS_LATEST_ROOT/services/openclaw/openclaw.json"
echo 'layout: ok' > "$FNOS_LATEST_ROOT/manifests/managed_root_layout.yaml"
echo '# docs ok' > "$OPENCLAW_LATEST_ROOT/docs/restore.md"
echo '#!/usr/bin/env bash' > "$OPENCLAW_LATEST_ROOT/scripts/backup/run.sh"
echo '# memory ok' > "$OPENCLAW_LATEST_ROOT/memory/notes.md"
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
cat > "$SECRETS_REAL_DIR/fnos-media-stack.env" <<'EOF'
HOMARR_AUTH_PASSWORD=homarr-secret
HALO_INITIALIZER_PASSWORD=halo-secret
HOMARR_SECRET_ENCRYPTION_KEY=super-enc-key
EOF
cat > "$BIN_DIR/docker" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
if [[ "$1" == "compose" && "$2" == "config" ]]; then
  echo 'services:'
  exit 0
fi
if [[ "$1" == "compose" && "$2" == "up" ]]; then
  echo 'up ok'
  exit 0
fi
exit 1
EOF
chmod +x "$BIN_DIR/docker"
OUT="$(PATH="$BIN_DIR:$PATH" RESTORE_STATE_ROOT="$RESTORE_STATE_ROOT" RESTORE_TARGET_ROOT="$RESTORE_TARGET_ROOT" PVE_LATEST_ROOT="$PVE_LATEST_ROOT" FNOS_LATEST_ROOT="$FNOS_LATEST_ROOT" OPENCLAW_LATEST_ROOT="$OPENCLAW_LATEST_ROOT" SECRETS_TEMPLATE_PATH="$SECRETS_TEMPLATE" SECRETS_REAL_DIR="$SECRETS_REAL_DIR" FORCE_GITHUB_ACCESS=1 FORCE_NAS_ACCESS=1 bash "$ROOT/restore/restore-all.sh" apply --source hybrid)"
printf '%s' "$OUT" | grep -Fq 'restore-all apply complete' || { echo 'restore-all apply did not complete' >&2; exit 1; }
[[ -f "$RESTORE_TARGET_ROOT/services/fnos-media-stack/docker-compose.yml" ]] || { echo 'restore-all did not restore fnos-media-stack compose' >&2; exit 1; }
[[ -f "$RESTORE_TARGET_ROOT/services/fnos-media-stack/.env" ]] || { echo 'restore-all did not restore fnos-media-stack env' >&2; exit 1; }
echo 'PASS test_restore_all_apply_includes_fnos_media_stack'
