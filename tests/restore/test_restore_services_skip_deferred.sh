#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
RESTORE_STATE_ROOT="$TMP/state/restore"
RESTORE_TARGET_ROOT="$TMP/target"
BIN_DIR="$TMP/bin"
mkdir -p "$RESTORE_STATE_ROOT/reports" "$RESTORE_TARGET_ROOT/services/media-stack" "$BIN_DIR"
cat > "$BIN_DIR/docker" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
if [[ "$1" == "compose" && "$2" == "config" ]]; then
  echo 'services:'
  exit 0
fi
if [[ "$1" == "compose" && "$2" == "up" ]]; then
  echo 'up ok'
  exit 0
fi
exit 1
EOF
chmod +x "$BIN_DIR/docker"
PATH="$BIN_DIR:$PATH" RESTORE_STATE_ROOT="$RESTORE_STATE_ROOT" RESTORE_TARGET_ROOT="$RESTORE_TARGET_ROOT" bash "$ROOT/restore/layers/30-services.sh" apply
REPORT="$(find "$RESTORE_STATE_ROOT/reports" -maxdepth 1 -name 'services-apply-*.md' | head -n 1)"
[[ -f "$REPORT" ]] || { echo 'missing services apply report' >&2; exit 1; }
grep -Fq 'channels: skipped (deferred)' "$REPORT" || { echo 'deferred channels skip missing' >&2; exit 1; }
echo 'PASS test_restore_services_skip_deferred'
