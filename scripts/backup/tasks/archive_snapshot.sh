#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/common.sh
source "$SCRIPT_DIR/../lib/common.sh"

WORKSPACE_ROOT="${WORKSPACE_ROOT:-$(cd "$SCRIPT_DIR/../../.." && pwd)}"
BACKUP_ROOT="${BACKUP_ROOT:-/mnt/nas/backup}"
TIMESTAMP="${TIMESTAMP:-$(now_ts)}"

OPENCLAW_LATEST="$BACKUP_ROOT/services/openclaw/latest"
OPENCLAW_SNAPSHOTS="$BACKUP_ROOT/services/openclaw/snapshots"
ARCHIVE_INDEX_DIR="$BACKUP_ROOT/shared/version-index/latest"
ARCHIVE_INDEX="$ARCHIVE_INDEX_DIR/archive-index.yaml"
TARGET="$OPENCLAW_SNAPSHOTS/$TIMESTAMP"

require_dir "$OPENCLAW_LATEST"
ensure_dir "$OPENCLAW_SNAPSHOTS"
ensure_dir "$ARCHIVE_INDEX_DIR"
rm -rf "$TARGET"
ensure_dir "$TARGET"
rsync -rltD --delete "$OPENCLAW_LATEST/" "$TARGET/"

if [[ ! -f "$ARCHIVE_INDEX" ]]; then
  cat > "$ARCHIVE_INDEX" <<EOF
version: 1
snapshots:
EOF
fi

printf '  - target: openclaw\n    timestamp: "%s"\n    path: "%s"\n' "$TIMESTAMP" "$TARGET" >> "$ARCHIVE_INDEX"
log "archive_snapshot complete: $TARGET"
