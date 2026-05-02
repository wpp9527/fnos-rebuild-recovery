#!/usr/bin/env bash
set -euo pipefail

SCRIPT="/opt/fnos-media/services/openclaw/home/.openclaw/workspace/tools/sync-edict-governance.sh"

grep -Fq 'SRC="/opt/fnos-media/services/openclaw/home/.openclaw/workspace"' "$SCRIPT" || {
  echo 'sync script does not source current recovery workspace' >&2
  exit 1
}
