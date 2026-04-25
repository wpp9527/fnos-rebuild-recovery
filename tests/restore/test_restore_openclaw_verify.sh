#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

RESTORE_STATE_ROOT="$TMP/state/restore"
RESTORE_TARGET_ROOT="$TMP/target"
mkdir -p "$RESTORE_STATE_ROOT/reports" \
  "$RESTORE_TARGET_ROOT/openclaw/docs" \
  "$RESTORE_TARGET_ROOT/openclaw/scripts/backup" \
  "$RESTORE_TARGET_ROOT/openclaw/memory"

echo '# docs ok' > "$RESTORE_TARGET_ROOT/openclaw/docs/restore.md"
echo '#!/usr/bin/env bash' > "$RESTORE_TARGET_ROOT/openclaw/scripts/backup/run.sh"
echo '# memory ok' > "$RESTORE_TARGET_ROOT/openclaw/memory/notes.md"
chmod +x "$RESTORE_TARGET_ROOT/openclaw/scripts/backup/run.sh"

OUT="$(RESTORE_STATE_ROOT="$RESTORE_STATE_ROOT" RESTORE_TARGET_ROOT="$RESTORE_TARGET_ROOT" bash "$ROOT/restore/layers/40-openclaw.sh" verify)"

printf '%s' "$OUT" | grep -Fq 'openclaw verify PASS' || { echo 'verify did not pass' >&2; exit 1; }
REPORT="$(find "$RESTORE_STATE_ROOT/reports" -maxdepth 1 -name 'openclaw-verify-*.md' | head -n 1)"
[[ -n "$REPORT" && -f "$REPORT" ]] || { echo 'missing openclaw verify report' >&2; exit 1; }
grep -Fq 'PASS' "$REPORT" || { echo 'verify report missing PASS' >&2; exit 1; }

echo 'PASS test_restore_openclaw_verify'
