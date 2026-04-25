#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

RESTORE_STATE_ROOT="$TMP/state/restore"
RESTORE_TARGET_ROOT="$TMP/target"
OPENCLAW_LATEST_ROOT="$TMP/openclaw-latest"
mkdir -p "$RESTORE_STATE_ROOT" "$RESTORE_TARGET_ROOT" \
  "$OPENCLAW_LATEST_ROOT/docs" \
  "$OPENCLAW_LATEST_ROOT/scripts/backup" \
  "$OPENCLAW_LATEST_ROOT/memory"

echo '# docs ok' > "$OPENCLAW_LATEST_ROOT/docs/restore.md"
echo '#!/usr/bin/env bash' > "$OPENCLAW_LATEST_ROOT/scripts/backup/run.sh"
echo '# memory ok' > "$OPENCLAW_LATEST_ROOT/memory/notes.md"

RESTORE_STATE_ROOT="$RESTORE_STATE_ROOT" \
RESTORE_TARGET_ROOT="$RESTORE_TARGET_ROOT" \
OPENCLAW_LATEST_ROOT="$OPENCLAW_LATEST_ROOT" \
bash "$ROOT/restore/layers/40-openclaw.sh" apply

[[ -d "$RESTORE_TARGET_ROOT/openclaw/docs" ]] || { echo 'docs dir not restored' >&2; exit 1; }
[[ -d "$RESTORE_TARGET_ROOT/openclaw/scripts/backup" ]] || { echo 'scripts/backup dir not restored' >&2; exit 1; }
[[ -d "$RESTORE_TARGET_ROOT/openclaw/memory" ]] || { echo 'memory dir not restored' >&2; exit 1; }
[[ -f "$RESTORE_TARGET_ROOT/openclaw/docs/restore.md" ]] || { echo 'docs file not restored' >&2; exit 1; }
[[ -f "$RESTORE_TARGET_ROOT/openclaw/scripts/backup/run.sh" ]] || { echo 'backup script not restored' >&2; exit 1; }
[[ -f "$RESTORE_TARGET_ROOT/openclaw/memory/notes.md" ]] || { echo 'memory file not restored' >&2; exit 1; }

echo 'PASS test_restore_openclaw_apply'
