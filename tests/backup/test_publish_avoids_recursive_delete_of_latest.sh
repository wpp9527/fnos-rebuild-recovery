#!/usr/bin/env bash
set -euo pipefail

SCRIPT="/opt/fnos-media/services/openclaw/home/.openclaw/workspace/scripts/backup/tasks/publish_latest.sh"

if grep -Fq 'rm -rf "$target_latest"' "$SCRIPT"; then
  echo 'publish_latest should not recursively delete latest directory' >&2
  exit 1
fi

if ! grep -Fq 'mv "$target_latest" "$backup_latest"' "$SCRIPT"; then
  echo 'publish_latest missing latest rotation move' >&2
  exit 1
fi

echo 'PASS test_publish_avoids_recursive_delete_of_latest'
