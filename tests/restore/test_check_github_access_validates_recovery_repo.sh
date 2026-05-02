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
git -C "$REPO" remote add origin git@github.com:wpp9527/fnos-rebuild-recovery.git

OUT="$(CHECK_ROOT="$REPO" bash "$REPO/restore/checks/check-github-access.sh")"
printf '%s' "$OUT" | grep -Fq 'PASS origin remote matches recovery repo' || { echo 'missing remote validation pass output' >&2; exit 1; }
printf '%s' "$OUT" | grep -Fq 'PASS github recovery guide present' || { echo 'missing guide validation pass output' >&2; exit 1; }
printf '%s' "$OUT" | grep -Fq 'PASS restore entrypoint present' || { echo 'missing restore entrypoint validation pass output' >&2; exit 1; }

echo 'PASS test_check_github_access_validates_recovery_repo'
