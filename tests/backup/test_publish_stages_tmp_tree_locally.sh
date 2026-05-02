#!/usr/bin/env bash
set -euo pipefail

SCRIPT="/opt/fnos-media/services/openclaw/home/.openclaw/workspace/scripts/backup/tasks/publish_latest.sh"

grep -Fq 'LOCAL_TMP_ROOT="${LOCAL_TMP_ROOT:-/tmp/openclaw-backup-publish}"' "$SCRIPT" || {
  echo 'publish_latest missing LOCAL_TMP_ROOT' >&2
  exit 1
}

grep -Fq 'local_tmp_target="$LOCAL_TMP_ROOT/' "$SCRIPT" || {
  echo 'publish_latest missing local tmp target staging' >&2
  exit 1
}

grep -Fq 'rsync -rltD --delete "$source_dir/" "$local_tmp_target/"' "$SCRIPT" || {
  echo 'publish_latest should rsync into local tmp target first' >&2
  exit 1
}

echo 'PASS test_publish_stages_tmp_tree_locally'
