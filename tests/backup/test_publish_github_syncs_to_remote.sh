#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

WS="$TMP/workspace"
REMOTE="$TMP/remote.git"
EXPORT_DST="$TMP/export"

mkdir -p "$WS/docs" "$WS/restore/checks"
echo 'hello github backup' > "$WS/docs/spec.md"
cat > "$WS/restore/checks/check-github-access.sh" <<'SH'
#!/usr/bin/env bash
echo ok
SH
chmod +x "$WS/restore/checks/check-github-access.sh"

git init --bare "$REMOTE" >/dev/null 2>&1
seed="$TMP/seed"
git clone "$REMOTE" "$seed" >/dev/null 2>&1
cd "$seed"
git config user.name test
git config user.email test@example.com
echo '# recovery repo' > README.md
git add README.md
git commit -m 'seed' >/dev/null 2>&1
git push origin HEAD:main >/dev/null 2>&1

GITHUB_SYNC_REMOTE="$REMOTE" \
GITHUB_SYNC_DST="$EXPORT_DST" \
GITHUB_SYNC_BRANCH="main" \
GITHUB_SYNC_ENABLED=1 \
WORKSPACE_ROOT="$WS" \
bash "$ROOT/scripts/backup/tasks/publish_github.sh"

clone_check="$TMP/check"
git clone --branch main "$REMOTE" "$clone_check" >/dev/null 2>&1
[[ -f "$clone_check/docs/spec.md" ]] || { echo 'missing synced docs/spec.md on remote clone' >&2; exit 1; }
[[ -f "$clone_check/restore/checks/check-github-access.sh" ]] || { echo 'missing restore github check on remote clone' >&2; exit 1; }

echo 'PASS test_publish_github_syncs_to_remote'
