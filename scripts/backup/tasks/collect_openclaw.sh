#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/common.sh
source "$SCRIPT_DIR/../lib/common.sh"

WORKSPACE_ROOT="${WORKSPACE_ROOT:-/root/.openclaw/.openclaw/workspace}"
STAGING_ROOT="${STAGING_ROOT:-$WORKSPACE_ROOT/state/backup/staging}"
OPENCLAW_STAGE_DIR="$STAGING_ROOT/openclaw"

require_dir "$WORKSPACE_ROOT"
ensure_dir "$OPENCLAW_STAGE_DIR"
rm -rf "$OPENCLAW_STAGE_DIR"
ensure_dir "$OPENCLAW_STAGE_DIR"

log "collect_openclaw from $WORKSPACE_ROOT"

RSYNC_EXCLUDES=(
  '--exclude=.git/'
  '--exclude=.clawhub/'
  '--exclude=.openclaw/'
  '--exclude=state/'
  '--exclude=memory/.dreams/'
  '--exclude=memory/dreaming/'
  '--exclude=DREAMS.md'
  '--exclude=*.log'
  '--exclude=.tmp/'
  '--exclude=tmp/'
  '--exclude=.cache/'
  '--exclude=__pycache__/'
  '--exclude=*.pyc'
  '--exclude=node_modules/'
  # Installation packages / downloaded software are reproducible and break GitHub's 100MB file limit.
  '--exclude=1panel-v*-linux-*'
  '--exclude=*.tar.gz'
  '--exclude=*.tgz'
  '--exclude=*.zip'
  '--exclude=*.7z'
  '--exclude=*.rar'
  '--exclude=*.dmg'
  '--exclude=*.iso'
  '--exclude=*.deb'
  '--exclude=*.rpm'
  '--exclude=*.apk'
  '--exclude=*.exe'
  '--exclude=*.msi'
  '--exclude=*.AppImage'
)

RSYNC_MAX_SIZE="${OPENCLAW_BACKUP_RSYNC_MAX_SIZE:-95m}"

rsync -rltD --delete --max-size="$RSYNC_MAX_SIZE" "${RSYNC_EXCLUDES[@]}" "$WORKSPACE_ROOT/" "$OPENCLAW_STAGE_DIR/"

cat > "$OPENCLAW_STAGE_DIR/restore-notes.md" <<EOF
# OpenClaw Restore Notes

Generated: $(date -Is)
Source workspace: $WORKSPACE_ROOT

Contents in this directory are intended for configuration-level recovery.
Restore priority:
1. docs/
2. scripts/
3. workspace governance/baseline files
4. memory/ and references needed for operational context

Excluded from this backup:
- runtime state
- dream artifacts
- caches and temporary files
- installation packages / reproducible software archives
- files larger than ${RSYNC_MAX_SIZE} (override with OPENCLAW_BACKUP_RSYNC_MAX_SIZE)
EOF

log "collect_openclaw complete: $OPENCLAW_STAGE_DIR"
