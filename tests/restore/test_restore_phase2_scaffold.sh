#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

for path in \
  "$ROOT/restore/manifests/restore-layers.yaml" \
  "$ROOT/restore/manifests/source-map.yaml" \
  "$ROOT/restore/manifests/path-policy.yaml" \
  "$ROOT/restore/manifests/secrets-policy.yaml" \
  "$ROOT/restore/manifests/service-catalog.yaml" \
  "$ROOT/restore/checks/check-host-prereqs.sh" \
  "$ROOT/restore/checks/check-nas-access.sh" \
  "$ROOT/restore/checks/check-github-access.sh" \
  "$ROOT/restore/checks/check-secrets.sh" \
  "$ROOT/restore/templates/fnos/README.md" \
  "$ROOT/restore/templates/openclaw/README.md" \
  "$ROOT/restore/templates/secrets/.env.example"
do
  [[ -f "$path" ]] || { echo "missing phase2 file: $path" >&2; exit 1; }
done

echo 'PASS test_restore_phase2_scaffold'
