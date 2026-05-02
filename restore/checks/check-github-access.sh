#!/usr/bin/env bash
set -euo pipefail

CHECK_ROOT="${CHECK_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
EXPECTED_REMOTE="${EXPECTED_REMOTE:-git@github.com:wpp9527/fnos-rebuild-recovery.git}"

pass() {
  printf 'PASS %s\n' "$*"
}

fail() {
  printf 'FAIL %s\n' "$*" >&2
  exit 1
}

[[ -d "$CHECK_ROOT" ]] || fail "check root missing: $CHECK_ROOT"
[[ -d "$CHECK_ROOT/.git" ]] || fail "git metadata missing under $CHECK_ROOT"

origin_remote="$(git -C "$CHECK_ROOT" remote get-url origin 2>/dev/null || true)"
[[ -n "$origin_remote" ]] || fail 'origin remote missing'
[[ "$origin_remote" == "$EXPECTED_REMOTE" ]] || fail "unexpected origin remote: $origin_remote"
pass 'origin remote matches recovery repo'

[[ -f "$CHECK_ROOT/docs/github-recovery-guide.md" ]] || fail 'docs/github-recovery-guide.md missing'
pass 'github recovery guide present'

[[ -x "$CHECK_ROOT/restore/restore-all.sh" ]] || fail 'restore/restore-all.sh missing or not executable'
pass 'restore entrypoint present'
