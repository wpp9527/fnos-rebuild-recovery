#!/usr/bin/env bash
set -euo pipefail

SCRIPT="/opt/fnos-media/services/openclaw/home/.openclaw/workspace/scripts/backup/tasks/publish_latest.sh"

if grep -Fq 'rm -rf "$backup_latest"' "$SCRIPT"; then
  echo 'publish_latest should not delete previous latest in the main publish path' >&2
  exit 1
fi

grep -Fq '.prev-latest-' "$SCRIPT" || {
  echo 'publish_latest missing prev-latest rotation marker' >&2
  exit 1
}

echo 'PASS test_publish_keeps_prev_latest_for_later_cleanup'
