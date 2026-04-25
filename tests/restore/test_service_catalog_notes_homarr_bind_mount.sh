#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
CATALOG="$ROOT/restore/manifests/service-catalog.yaml"
grep -Fq '/opt/fnos-media-stack/homarr/appdata' "$CATALOG" || { echo 'service catalog missing homarr appdata mapping' >&2; exit 1; }
grep -Fq 'runtime_detected: true' "$CATALOG" || { echo 'service catalog missing runtime_detected' >&2; exit 1; }
echo 'PASS test_service_catalog_notes_homarr_bind_mount'
