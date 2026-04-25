#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
CATALOG="$ROOT/restore/manifests/service-catalog.yaml"
grep -Fq 'name: hermes-openwebui' "$CATALOG" || { echo 'hermes-openwebui service missing' >&2; exit 1; }
grep -Fq '/opt/fnos-media/services/hermes-openwebui/data' "$CATALOG" || { echo 'hermes-openwebui state path missing' >&2; exit 1; }
echo 'PASS test_service_catalog_mentions_hermes_openwebui_state'
