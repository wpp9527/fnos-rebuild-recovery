#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
DOC="$ROOT/docs/backup-automation.md"
grep -Fq 'fnos-media-stack classification' "$DOC" || { echo 'classification section missing' >&2; exit 1; }
grep -Fq 'must back up' "$DOC" || { echo 'must back up section missing' >&2; exit 1; }
grep -Fq 'recommended to back up' "$DOC" || { echo 'recommended to back up section missing' >&2; exit 1; }
grep -Fq 'safe to ignore or rebuild' "$DOC" || { echo 'safe to ignore or rebuild section missing' >&2; exit 1; }
echo 'PASS test_backup_automation_mentions_fnos_media_stack_tiers'
