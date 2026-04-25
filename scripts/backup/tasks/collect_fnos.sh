#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/common.sh
source "$SCRIPT_DIR/../lib/common.sh"

WORKSPACE_ROOT="${WORKSPACE_ROOT:-$(cd "$SCRIPT_DIR/../../.." && pwd)}"
STAGING_ROOT="${STAGING_ROOT:-$WORKSPACE_ROOT/state/backup/staging}"
REPORT_DIR="$STAGING_ROOT/reports"
FNOS_ENABLED="${FNOS_ENABLED:-0}"
FNOS_SSH_HOST="${FNOS_SSH_HOST:-}"

ensure_dir "$REPORT_DIR"

if [[ "$FNOS_ENABLED" != "1" || -z "$FNOS_SSH_HOST" ]]; then
  cat > "$REPORT_DIR/fnos-not-configured.md" <<EOF
# fnOS Backup Status

fnOS backup is not configured yet.

Expected future inputs:
- FNOS_ENABLED=1
- FNOS_SSH_HOST=<ssh-host-or-alias>
EOF
  log "collect_fnos: not configured"
  exit 0
fi

cat > "$REPORT_DIR/fnos-configured-placeholder.md" <<EOF
# fnOS Backup Status

fnOS backup is configured but collection is not implemented in this phase.
Target: $FNOS_SSH_HOST
EOF
log "collect_fnos: configured placeholder"
