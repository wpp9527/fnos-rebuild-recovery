#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

REPO="$TMP/recovery"
mkdir -p "$REPO/docs" "$REPO/restore/checks" "$REPO/restore"
cp "$ROOT/restore/checks/check-github-access.sh" "$REPO/restore/checks/check-github-access.sh"
chmod +x "$REPO/restore/checks/check-github-access.sh"

echo guide > "$REPO/docs/github-recovery-guide.md"
echo '#!/usr/bin/env bash' > "$REPO/restore/restore-all.sh"
chmod +x "$REPO/restore/restore-all.sh"

git init "$REPO" >/dev/null 2>&1
git -C "$REPO" remote add origin git@github.com:someone/else.git

if CHECK_ROOT="$REPO" bash "$REPO/restore/checks/check-github-access.sh" >/tmp/check-github-access.out 2>/tmp/check-github-access.err; then
  echo 'check-github-access unexpectedly passed with wrong remote' >&2
  exit 1
fi

grep -Fq 'unexpected origin remote' /tmp/check-github-access.err || { echo 'missing wrong-remote error' >&2; exit 1; }

echo 'PASS test_check_github_access_rejects_wrong_remote'
