#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
COMPOSE="$ROOT/restore/templates/services/fnos-media-stack/docker-compose.yml"
grep -Fq '/opt/fnos-media-stack/homarr/appdata:/appdata' "$COMPOSE" || { echo 'homarr appdata bind mount missing' >&2; exit 1; }
echo 'PASS test_restore_services_fnos_media_stack_homarr_bind_mount'
