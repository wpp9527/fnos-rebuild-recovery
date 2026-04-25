#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

RESTORE_STATE_ROOT="$TMP/state/restore"
RESTORE_TARGET_ROOT="$TMP/target"
FNOS_LATEST_ROOT="$TMP/fnos-latest"
mkdir -p "$RESTORE_STATE_ROOT" "$RESTORE_TARGET_ROOT" "$FNOS_LATEST_ROOT/services/media-stack" "$FNOS_LATEST_ROOT/manifests"

echo 'compose: yes' > "$FNOS_LATEST_ROOT/services/media-stack/docker-compose.yml"
echo 'layout: ok' > "$FNOS_LATEST_ROOT/manifests/managed_root_layout.yaml"

OUT="$(RESTORE_STATE_ROOT="$RESTORE_STATE_ROOT" RESTORE_TARGET_ROOT="$RESTORE_TARGET_ROOT" FNOS_LATEST_ROOT="$FNOS_LATEST_ROOT" bash "$ROOT/restore/layers/20-fnos.sh" plan)"

printf '%s' "$OUT" | grep -Fq 'fnos plan ready' || { echo 'missing fnos plan output' >&2; exit 1; }
PLAN_MD="$(find "$RESTORE_STATE_ROOT/plans" -maxdepth 1 -name 'fnos-plan-*.md' | head -n 1)"
[[ -n "$PLAN_MD" && -f "$PLAN_MD" ]] || { echo 'missing fnos plan markdown' >&2; exit 1; }
grep -Fq 'media-stack' "$PLAN_MD" || { echo 'fnos plan missing media-stack' >&2; exit 1; }

echo 'PASS test_restore_fnos_plan'
