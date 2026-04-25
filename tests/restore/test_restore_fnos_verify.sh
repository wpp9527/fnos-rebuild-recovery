#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

RESTORE_STATE_ROOT="$TMP/state/restore"
RESTORE_TARGET_ROOT="$TMP/target"
mkdir -p "$RESTORE_STATE_ROOT/reports" \
  "$RESTORE_TARGET_ROOT/opt/fnos-media/manifests" \
  "$RESTORE_TARGET_ROOT/opt/fnos-media/services/media-stack" \
  "$RESTORE_TARGET_ROOT/opt/fnos-media/services/openclaw"

echo 'compose: yes' > "$RESTORE_TARGET_ROOT/opt/fnos-media/services/media-stack/docker-compose.yml"
echo '{"ok":true}' > "$RESTORE_TARGET_ROOT/opt/fnos-media/services/openclaw/openclaw.json"

OUT="$(RESTORE_STATE_ROOT="$RESTORE_STATE_ROOT" RESTORE_TARGET_ROOT="$RESTORE_TARGET_ROOT" bash "$ROOT/restore/layers/20-fnos.sh" verify)"

printf '%s' "$OUT" | grep -Fq 'fnos verify PASS' || { echo 'verify did not pass' >&2; exit 1; }
REPORT="$(find "$RESTORE_STATE_ROOT/reports" -maxdepth 1 -name 'fnos-verify-*.md' | head -n 1)"
[[ -n "$REPORT" && -f "$REPORT" ]] || { echo 'missing fnos verify report' >&2; exit 1; }
grep -Fq 'PASS' "$REPORT" || { echo 'verify report missing PASS' >&2; exit 1; }

echo 'PASS test_restore_fnos_verify'
