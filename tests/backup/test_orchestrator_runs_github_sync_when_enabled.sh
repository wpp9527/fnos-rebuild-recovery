#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

WS="$TMP/workspace"
BACKUP_ROOT="$TMP/nas-backup"
STAGING_ROOT="$TMP/staging"
REMOTE="$TMP/remote.git"
EXPORT_DST="$TMP/export"

mkdir -p "$WS/docs" "$WS/restore/checks" "$BACKUP_ROOT"
echo 'github orchestrator check' > "$WS/docs/spec.md"
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
echo seed > README.md
git add README.md
git commit -m 'seed' >/dev/null 2>&1
git push origin HEAD:main >/dev/null 2>&1

WORKSPACE_ROOT="$WS" \
BACKUP_ROOT="$BACKUP_ROOT" \
STAGING_ROOT="$STAGING_ROOT" \
GITHUB_SYNC_ENABLED=1 \
GITHUB_SYNC_REMOTE="$REMOTE" \
GITHUB_SYNC_DST="$EXPORT_DST" \
GITHUB_SYNC_BRANCH=main \
RUN_ARCHIVE=0 \
bash "$ROOT/scripts/backup/orchestrator.sh"

clone_check="$TMP/check"
git clone --branch main "$REMOTE" "$clone_check" >/dev/null 2>&1
[[ -f "$clone_check/docs/spec.md" ]] || { echo 'missing synced file from orchestrator github sync' >&2; exit 1; }
find "$BACKUP_ROOT/shared/restore-guides/latest" -type f | grep -q 'github-verify-' || { echo 'missing github verify report from orchestrator' >&2; exit 1; }

echo 'PASS test_orchestrator_runs_github_sync_when_enabled'
