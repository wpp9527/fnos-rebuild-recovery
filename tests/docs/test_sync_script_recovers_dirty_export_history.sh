#!/usr/bin/env bash
set -euo pipefail

SCRIPT="/opt/fnos-media/services/openclaw/home/.openclaw/workspace/tools/sync-edict-governance.sh"

grep -Fq 'rm -rf "$DST"' "$SCRIPT" || {
  echo 'sync script does not rebuild export repo when history is invalid' >&2
  exit 1
}

grep -Fq 'git clone --branch "$BRANCH" "$REMOTE" "$DST"' "$SCRIPT" || {
  echo 'sync script cannot rebuild export repo from remote' >&2
  exit 1
}
