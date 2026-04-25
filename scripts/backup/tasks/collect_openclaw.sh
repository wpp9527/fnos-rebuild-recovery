#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/common.sh
source "$SCRIPT_DIR/../lib/common.sh"

WORKSPACE_ROOT="${WORKSPACE_ROOT:-$(cd "$SCRIPT_DIR/../../.." && pwd)}"
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
)

rsync -rltD --delete "${RSYNC_EXCLUDES[@]}" "$WORKSPACE_ROOT/" "$OPENCLAW_STAGE_DIR/"

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
EOF

log "collect_openclaw complete: $OPENCLAW_STAGE_DIR"
