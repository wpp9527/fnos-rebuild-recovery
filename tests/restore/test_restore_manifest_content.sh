#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

LAYERS="$ROOT/restore/manifests/restore-layers.yaml"
SOURCE_MAP="$ROOT/restore/manifests/source-map.yaml"
PATH_POLICY="$ROOT/restore/manifests/path-policy.yaml"
SECRETS_POLICY="$ROOT/restore/manifests/secrets-policy.yaml"
SERVICE_CATALOG="$ROOT/restore/manifests/service-catalog.yaml"

grep -Fq 'layers:' "$LAYERS" || { echo 'restore-layers missing layers key' >&2; exit 1; }
grep -Fq '00-bootstrap' "$LAYERS" || { echo 'restore-layers missing bootstrap layer' >&2; exit 1; }
grep -Fq 'hybrid:' "$SOURCE_MAP" || { echo 'source-map missing hybrid mode' >&2; exit 1; }
grep -Fq 'tier1:' "$PATH_POLICY" || { echo 'path-policy missing tier1' >&2; exit 1; }
grep -Fq 'blocking:' "$SECRETS_POLICY" || { echo 'secrets-policy missing blocking section' >&2; exit 1; }
grep -Fq 'services:' "$SERVICE_CATALOG" || { echo 'service-catalog missing services section' >&2; exit 1; }

echo 'PASS test_restore_manifest_content'
