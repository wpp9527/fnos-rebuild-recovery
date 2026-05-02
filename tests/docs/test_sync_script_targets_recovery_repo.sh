#!/usr/bin/env bash
set -euo pipefail

SCRIPT="/opt/fnos-media/services/openclaw/home/.openclaw/workspace/tools/sync-edict-governance.sh"

grep -Fq 'REMOTE="git@github.com:wpp9527/fnos-rebuild-recovery.git"' "$SCRIPT" || {
  echo 'sync script does not target fnos-rebuild-recovery repo' >&2
  exit 1
}

grep -Fq 'DST="/tmp/fnos-rebuild-recovery-export"' "$SCRIPT" || {
  echo 'sync script does not use fnos-rebuild-recovery export path' >&2
  exit 1
}
