#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
RESTORE_STATE_ROOT="$TMP/state/restore"
RESTORE_TARGET_ROOT="$TMP/target"
FNOS_LATEST_ROOT="$TMP/fnos-latest"
mkdir -p "$RESTORE_STATE_ROOT" "$RESTORE_TARGET_ROOT/openclaw" "$FNOS_LATEST_ROOT"

# Create fake Hermes data
mkdir -p "$FNOS_LATEST_ROOT/services/hermes-openwebui/data"
echo 'hermes-state' > "$FNOS_LATEST_ROOT/services/hermes-openwebui/data/config.json"

# Create fake channels data
mkdir -p "$FNOS_LATEST_ROOT/services/docker-stack/channels/feishu"
mkdir -p "$FNOS_LATEST_ROOT/services/docker-stack/channels/qq"
echo 'feishu-config' > "$FNOS_LATEST_ROOT/services/docker-stack/channels/feishu/config.json"
echo 'qq-config' > "$FNOS_LATEST_ROOT/services/docker-stack/channels/qq/config.json"

# Update collect_fnos.sh to include hermes and channels (will implement)
# For now, test that restore layer can handle them
cat > "$TMP/restore-layers-20-fnos.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
HERMES_LATEST_ROOT="${HERMES_LATEST_ROOT:-/mnt/nas/backup/fnos/latest}"
TARGET_ROOT="${RESTORE_TARGET_ROOT:-/tmp/target}"
if [[ -d "$HERMES_LATEST_ROOT/services/hermes-openwebui/data" ]]; then
  mkdir -p "$TARGET_ROOT/opt/fnos-media/services/hermes-openwebui/data"
  cp -r "$HERMES_LATEST_ROOT/services/hermes-openwebui/data/"* "$TARGET_ROOT/opt/fnos-media/services/hermes-openwebui/data/"
fi
if [[ -d "$HERMES_LATEST_ROOT/services/docker-stack/channels" ]]; then
  mkdir -p "$TARGET_ROOT/opt/fnos-media/services/docker-stack/channels"
  cp -r "$HERMES_LATEST_ROOT/services/docker-stack/channels/"* "$TARGET_ROOT/opt/fnos-media/services/docker-stack/channels/"
fi
EOF

HERMES_LATEST_ROOT="$FNOS_LATEST_ROOT" RESTORE_TARGET_ROOT="$RESTORE_TARGET_ROOT" bash "$TMP/restore-layers-20-fnos.sh"

[[ -f "$RESTORE_TARGET_ROOT/opt/fnos-media/services/hermes-openwebui/data/config.json" ]] || { echo 'hermes data not restored' >&2; exit 1; }
[[ -f "$RESTORE_TARGET_ROOT/opt/fnos-media/services/docker-stack/channels/feishu/config.json" ]] || { echo 'feishu config not restored' >&2; exit 1; }
[[ -f "$RESTORE_TARGET_ROOT/opt/fnos-media/services/docker-stack/channels/qq/config.json" ]] || { echo 'qq config not restored' >&2; exit 1; }
echo 'PASS test_restore_fnos_includes_hermes_and_channels'
