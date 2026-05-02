#!/usr/bin/env bash
set -euo pipefail

SCRIPT="/opt/fnos-media/services/openclaw/home/.openclaw/workspace/tools/sync-edict-governance.sh"

grep -Fq 'git clone --branch "$BRANCH" "$REMOTE" "$DST"' "$SCRIPT" || {
  echo 'sync script does not bootstrap from remote history' >&2
  exit 1
}

grep -Fq 'git -C "$DST" pull --ff-only origin "$BRANCH"' "$SCRIPT" || {
  echo 'sync script does not fast-forward from remote before push' >&2
  exit 1
}
