#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
RESTORE_STATE_ROOT="$TMP/state/restore"
RESTORE_TARGET_ROOT="$TMP/target"
BIN_DIR="$TMP/bin"
mkdir -p "$RESTORE_STATE_ROOT" "$RESTORE_TARGET_ROOT/openclaw/docs" "$RESTORE_TARGET_ROOT/openclaw/scripts/backup" "$RESTORE_TARGET_ROOT/openclaw/memory" "$RESTORE_TARGET_ROOT/services/media-stack" "$RESTORE_TARGET_ROOT/opt/fnos-media/manifests" "$RESTORE_TARGET_ROOT/opt/fnos-media/services/media-stack" "$RESTORE_TARGET_ROOT/opt/fnos-media/services/openclaw" "$RESTORE_TARGET_ROOT/pve" "$BIN_DIR" "$TMP/real" "$TMP/templates"
echo '# docs ok' > "$RESTORE_TARGET_ROOT/openclaw/docs/restore.md"
echo '#!/usr/bin/env bash' > "$RESTORE_TARGET_ROOT/openclaw/scripts/backup/run.sh"
chmod +x "$RESTORE_TARGET_ROOT/openclaw/scripts/backup/run.sh"
echo '# memory ok' > "$RESTORE_TARGET_ROOT/openclaw/memory/notes.md"
echo 'compose: yes' > "$RESTORE_TARGET_ROOT/opt/fnos-media/services/media-stack/docker-compose.yml"
echo '{"ok":true}' > "$RESTORE_TARGET_ROOT/opt/fnos-media/services/openclaw/openclaw.json"
echo 'pvehost' > "$RESTORE_TARGET_ROOT/pve/hostname.txt"
echo 'Linux' > "$RESTORE_TARGET_ROOT/pve/uname.txt"
echo 'vmid name' > "$RESTORE_TARGET_ROOT/pve/vm-list.txt"
echo 'iface' > "$RESTORE_TARGET_ROOT/pve/network-interfaces.txt"
cat > "$RESTORE_TARGET_ROOT/openclaw/.env" <<'EOF'
OPENCLAW_BASE_URL=https://example.local
OPENCLAW_API_TOKEN=secret-token
PRIMARY_CHANNEL_TOKEN=primary-secret
EOF
cat > "$TMP/templates/.env.example" <<'EOF'
OPENCLAW_BASE_URL=
OPENCLAW_API_TOKEN=
PRIMARY_CHANNEL_TOKEN=
EOF
cat > "$TMP/real/openclaw.env" <<'EOF'
OPENCLAW_BASE_URL=https://example.local
OPENCLAW_API_TOKEN=secret-token
PRIMARY_CHANNEL_TOKEN=primary-secret
EOF
cat > "$BIN_DIR/docker" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
if [[ "$1" == "compose" && "$2" == "config" ]]; then
  echo 'services:'
  exit 0
fi
exit 1
EOF
chmod +x "$BIN_DIR/docker"
OUT="$(PATH="$BIN_DIR:$PATH" RESTORE_STATE_ROOT="$RESTORE_STATE_ROOT" RESTORE_TARGET_ROOT="$RESTORE_TARGET_ROOT" SECRETS_TEMPLATE_PATH="$TMP/templates/.env.example" SECRETS_REAL_DIR="$TMP/real" FORCE_GITHUB_ACCESS=1 FORCE_NAS_ACCESS=1 bash "$ROOT/restore/restore-all.sh" verify --source hybrid)"
printf '%s' "$OUT" | grep -Fq 'restore-all verify PASS' || { echo 'restore-all verify did not pass' >&2; exit 1; }
RESULT="$(find "$RESTORE_STATE_ROOT/reports" -maxdepth 1 -name 'restore-result-*.json' | head -n 1)"
[[ -f "$RESULT" ]] || { echo 'restore-all verify result missing' >&2; exit 1; }
grep -Fq '"status": "PASS"' "$RESULT" || { echo 'restore-all verify result missing PASS' >&2; exit 1; }
echo 'PASS test_restore_all_verify_flow'
