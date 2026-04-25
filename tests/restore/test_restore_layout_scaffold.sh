#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

for path in \
  "$ROOT/restore/bootstrap.sh" \
  "$ROOT/restore/restore-all.sh" \
  "$ROOT/restore/lib/common.sh" \
  "$ROOT/restore/layers/00-bootstrap.sh" \
  "$ROOT/restore/layers/10-pve.sh" \
  "$ROOT/restore/layers/20-fnos.sh" \
  "$ROOT/restore/layers/30-services.sh" \
  "$ROOT/restore/layers/40-openclaw.sh" \
  "$ROOT/restore/layers/50-secrets.sh" \
  "$ROOT/restore/layers/90-verify.sh"
do
  [[ -f "$path" ]] || { echo "missing scaffold file: $path" >&2; exit 1; }
done

echo 'PASS test_restore_layout_scaffold'
