#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
DOC="$ROOT/docs/backup-automation.md"
grep -Fq 'live compose drift control' "$DOC" || { echo 'drift control section missing' >&2; exit 1; }
grep -Fq '/opt/fnos-media-stack/docker-compose.yml' "$DOC" || { echo 'live compose path missing' >&2; exit 1; }
grep -Fq 'restore/templates/services/fnos-media-stack/docker-compose.yml' "$DOC" || { echo 'template path missing' >&2; exit 1; }
echo 'PASS test_backup_automation_mentions_live_compose_drift_control'
