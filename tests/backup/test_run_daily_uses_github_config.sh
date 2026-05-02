#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

FAKE_WS="$TMP/workspace"
BACKUP_ROOT="$TMP/nas-backup"
STAGING_ROOT="$TMP/staging"
CONFIG_FILE="$TMP/config.env"
REMOTE="$TMP/remote.git"
EXPORT_DST="$TMP/export"

mkdir -p "$FAKE_WS/docs" "$FAKE_WS/restore/checks" "$BACKUP_ROOT"
echo 'hello daily github' > "$FAKE_WS/docs/daily.md"
printf '#!/usr/bin/env bash\necho ok\n' > "$FAKE_WS/restore/checks/check-github-access.sh"
chmod +x "$FAKE_WS/restore/checks/check-github-access.sh"

git init --bare "$REMOTE" >/dev/null 2>&1
seed="$TMP/seed"
git clone "$REMOTE" "$seed" >/dev/null 2>&1
cd "$seed"
git config user.name test
git config user.email test@example.com
echo seed > README.md
git add README.md
git commit -m 'seed' >/dev/null 2>&1
git push origin HEAD:main >/dev/null 2>&1

cat > "$CONFIG_FILE" <<CFG
WORKSPACE_ROOT="$FAKE_WS"
BACKUP_ROOT="$BACKUP_ROOT"
STAGING_ROOT="$STAGING_ROOT"
RUN_ARCHIVE=0
GITHUB_SYNC_ENABLED=1
GITHUB_SYNC_REMOTE="$REMOTE"
GITHUB_SYNC_DST="$EXPORT_DST"
GITHUB_SYNC_BRANCH="main"
CFG

BACKUP_CONFIG="$CONFIG_FILE" bash "$ROOT/scripts/backup/run_daily.sh"

clone_check="$TMP/check"
git clone --branch main "$REMOTE" "$clone_check" >/dev/null 2>&1
[[ -f "$clone_check/docs/daily.md" ]] || { echo 'run_daily did not push github content from config' >&2; exit 1; }

echo 'PASS test_run_daily_uses_github_config'
