#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

GITHUB_SYNC_ENABLED="${GITHUB_SYNC_ENABLED:-1}"
GITHUB_SYNC_REMOTE="${GITHUB_SYNC_REMOTE:-git@github.com:wpp9527/fnos-rebuild-recovery.git}"
GITHUB_SYNC_BRANCH="${GITHUB_SYNC_BRANCH:-main}"
GITHUB_VERIFY_REPORT_ROOT="${GITHUB_VERIFY_REPORT_ROOT:-/tmp/github-verify-report}"
TMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TMP_ROOT"' EXIT

if [[ "$GITHUB_SYNC_ENABLED" != "1" ]]; then
  log "verify_github: not enabled"
  exit 0
fi

ensure_dir "$GITHUB_VERIFY_REPORT_ROOT"
CLONE_DIR="$TMP_ROOT/clone"
REPORT="$GITHUB_VERIFY_REPORT_ROOT/github-verify-$(now_ts).md"

git clone --branch "$GITHUB_SYNC_BRANCH" "$GITHUB_SYNC_REMOTE" "$CLONE_DIR" >/dev/null 2>&1

[[ -d "$CLONE_DIR/.git" ]] || { echo 'missing git clone content' >&2; exit 1; }
[[ -f "$CLONE_DIR/restore/checks/check-github-access.sh" ]] || { echo 'missing restore/checks/check-github-access.sh' >&2; exit 1; }
if [[ -f "$CLONE_DIR/docs/github-recovery-guide.md" || -f "$CLONE_DIR/docs/spec.md" ]]; then
  :
elif ! find "$CLONE_DIR/docs" -maxdepth 1 -type f -name "*.md" | grep -q .; then
  echo 'missing github recovery docs' >&2
  exit 1
fi

CHECK_OUTPUT="$TMP_ROOT/check-github-access.log"
bash "$CLONE_DIR/restore/checks/check-github-access.sh" >"$CHECK_OUTPUT" 2>&1

HEAD_SHA="$(git -C "$CLONE_DIR" rev-parse HEAD)"
cat > "$REPORT" <<REPORT
# GitHub Verify Report

Generated: $(date -Is)
Remote: $GITHUB_SYNC_REMOTE
Branch: $GITHUB_SYNC_BRANCH
Head: $HEAD_SHA

Checks:
- fresh clone: PASS
- restore/checks/check-github-access.sh: PASS
- recovery docs present: PASS

check-github-access output:
$(sed 's/^/    /' "$CHECK_OUTPUT")
REPORT

echo 'github verify PASS'
