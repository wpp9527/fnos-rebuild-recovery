#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

BACKUP_ROOT="$TMP/nas-backup"
mkdir -p \
  "$BACKUP_ROOT/services/openclaw/latest" \
  "$BACKUP_ROOT/services/openclaw/.tmp-latest-2026-04-27-021628-971948" \
  "$BACKUP_ROOT/services/openclaw/.prev-latest-2026-05-02-170046-504866" \
  "$BACKUP_ROOT/fnos/latest" \
  "$BACKUP_ROOT/fnos/.tmp-latest-2026-04-30-022237-2694183" \
  "$BACKUP_ROOT/fnos/.prev-latest-2026-05-02-170046-504866"

echo keep > "$BACKUP_ROOT/services/openclaw/latest/keep.txt"
echo stale > "$BACKUP_ROOT/services/openclaw/.tmp-latest-2026-04-27-021628-971948/stale.txt"
echo prev > "$BACKUP_ROOT/services/openclaw/.prev-latest-2026-05-02-170046-504866/prev.txt"
echo keep > "$BACKUP_ROOT/fnos/latest/keep.txt"
echo stale > "$BACKUP_ROOT/fnos/.tmp-latest-2026-04-30-022237-2694183/stale.txt"
echo prev > "$BACKUP_ROOT/fnos/.prev-latest-2026-05-02-170046-504866/prev.txt"

BACKUP_ROOT="$BACKUP_ROOT" bash "$ROOT/scripts/backup/prune_backup_rotations.sh"

[[ -f "$BACKUP_ROOT/services/openclaw/latest/keep.txt" ]] || { echo 'openclaw latest should be kept' >&2; exit 1; }
[[ -f "$BACKUP_ROOT/fnos/latest/keep.txt" ]] || { echo 'fnos latest should be kept' >&2; exit 1; }
[[ ! -e "$BACKUP_ROOT/services/openclaw/.tmp-latest-2026-04-27-021628-971948" ]] || { echo 'stale openclaw tmp rotation should be pruned' >&2; exit 1; }
[[ ! -e "$BACKUP_ROOT/services/openclaw/.prev-latest-2026-05-02-170046-504866" ]] || { echo 'stale openclaw prev rotation should be pruned' >&2; exit 1; }
[[ ! -e "$BACKUP_ROOT/fnos/.tmp-latest-2026-04-30-022237-2694183" ]] || { echo 'stale fnos tmp rotation should be pruned' >&2; exit 1; }
[[ ! -e "$BACKUP_ROOT/fnos/.prev-latest-2026-05-02-170046-504866" ]] || { echo 'stale fnos prev rotation should be pruned' >&2; exit 1; }

echo 'PASS test_prune_backup_rotations_keeps_latest'
