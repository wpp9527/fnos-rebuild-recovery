#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"

GITHUB_SYNC_ENABLED="${GITHUB_SYNC_ENABLED:-0}"
WORKSPACE_ROOT="${WORKSPACE_ROOT:-/root/.openclaw/.openclaw/workspace}"
REPO_ROOT="${WORKSPACE_ROOT:-/root/.openclaw/.openclaw/workspace}"
SYNC_SCRIPT="${GITHUB_SYNC_SCRIPT:-$REPO_ROOT/tools/sync-edict-governance.sh}"

if [[ "$GITHUB_SYNC_ENABLED" != "1" ]]; then
  log "publish_github: not enabled"
  exit 0
fi

[[ -x "$SYNC_SCRIPT" ]] || { echo "missing sync script: $SYNC_SCRIPT" >&2; exit 1; }

GITHUB_SYNC_SRC="${GITHUB_SYNC_SRC:-$WORKSPACE_ROOT}" GITHUB_SYNC_DST="${GITHUB_SYNC_DST:-/tmp/fnos-rebuild-recovery-export}" GITHUB_SYNC_REMOTE="${GITHUB_SYNC_REMOTE:-https://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@github.com/wpp9527/fnos-rebuild-recovery.git}" GITHUB_SYNC_BRANCH="${GITHUB_SYNC_BRANCH:-main}" GITHUB_SYNC_GIT_NAME="${GITHUB_SYNC_GIT_NAME:-wpp9527}" GITHUB_SYNC_GIT_EMAIL="${GITHUB_SYNC_GIT_EMAIL:-wangpengpeng9527@gmail.com}" bash "$SYNC_SCRIPT"

log "publish_github: synced to ${GITHUB_SYNC_REMOTE:-git@github.com:wpp9527/fnos-rebuild-recovery.git}"
