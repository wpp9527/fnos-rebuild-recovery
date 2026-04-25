#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

RESTORE_STATE_ROOT="$TMP/state/restore"
RESTORE_TARGET_ROOT="$TMP/target"
OPENCLAW_LATEST_ROOT="$TMP/openclaw-latest"
mkdir -p "$RESTORE_STATE_ROOT" "$RESTORE_TARGET_ROOT" "$OPENCLAW_LATEST_ROOT/docs" "$OPENCLAW_LATEST_ROOT/scripts/backup"

echo '# docs ok' > "$OPENCLAW_LATEST_ROOT/docs/restore.md"
echo '#!/usr/bin/env bash' > "$OPENCLAW_LATEST_ROOT/scripts/backup/run.sh"

OUT="$(RESTORE_STATE_ROOT="$RESTORE_STATE_ROOT" RESTORE_TARGET_ROOT="$RESTORE_TARGET_ROOT" OPENCLAW_LATEST_ROOT="$OPENCLAW_LATEST_ROOT" bash "$ROOT/restore/layers/40-openclaw.sh" plan)"

printf '%s' "$OUT" | grep -Fq 'openclaw plan ready' || { echo 'missing openclaw plan output' >&2; exit 1; }
PLAN_MD="$(find "$RESTORE_STATE_ROOT/plans" -maxdepth 1 -name 'openclaw-plan-*.md' | head -n 1)"
[[ -n "$PLAN_MD" && -f "$PLAN_MD" ]] || { echo 'missing openclaw plan markdown' >&2; exit 1; }
grep -Fq 'scripts/backup' "$PLAN_MD" || { echo 'openclaw plan missing scripts/backup' >&2; exit 1; }

echo 'PASS test_restore_openclaw_plan'
