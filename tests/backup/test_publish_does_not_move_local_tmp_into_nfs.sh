#!/usr/bin/env bash
set -euo pipefail

SCRIPT="/opt/fnos-media/services/openclaw/home/.openclaw/workspace/scripts/backup/tasks/publish_latest.sh"

if grep -Fq 'mv "$local_tmp_target" "$tmp_target"' "$SCRIPT"; then
  echo 'publish_latest should not move local tmp tree directly into NFS target' >&2
  exit 1
fi

grep -Fq 'cp -r "$local_tmp_target/". "$tmp_target/"' "$SCRIPT" || {
  echo 'publish_latest missing non-preserving copy from local tmp into NFS tmp target' >&2
  exit 1
}

echo 'PASS test_publish_does_not_move_local_tmp_into_nfs'
