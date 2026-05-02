#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

REMOTE="$TMP/remote.git"
REPORT_ROOT="$TMP/reports"
mkdir -p "$REPORT_ROOT"

git init --bare "$REMOTE" >/dev/null 2>&1
seed="$TMP/seed"
git clone "$REMOTE" "$seed" >/dev/null 2>&1
cd "$seed"
git config user.name test
git config user.email test@example.com
mkdir -p restore/checks docs
printf '#!/usr/bin/env bash\necho ok\n' > restore/checks/check-github-access.sh
chmod +x restore/checks/check-github-access.sh
echo 'guide' > docs/github-recovery-guide.md
git add .
git commit -m 'seed' >/dev/null 2>&1
git push origin HEAD:main >/dev/null 2>&1

OUT="$(GITHUB_SYNC_REMOTE="$REMOTE" GITHUB_SYNC_BRANCH="main" GITHUB_VERIFY_REPORT_ROOT="$REPORT_ROOT" bash "$ROOT/scripts/backup/verify_github.sh")"
printf '%s' "$OUT" | grep -Fq 'github verify PASS' || { echo 'github verify did not pass' >&2; exit 1; }
find "$REPORT_ROOT" -type f | grep -q . || { echo 'expected github verify report' >&2; exit 1; }

echo 'PASS test_verify_github_fresh_clone'
