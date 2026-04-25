#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

LIVE_COMPOSE_PATH="${LIVE_COMPOSE_PATH:-/opt/fnos-media-stack/docker-compose.yml}"
TEMPLATE_COMPOSE_PATH="${TEMPLATE_COMPOSE_PATH:-$(cd "$SCRIPT_DIR/.." && pwd)/restore/templates/services/fnos-media-stack/docker-compose.yml}"
AUDIT_REPORT_ROOT="${AUDIT_REPORT_ROOT:-$(cd "$SCRIPT_DIR/.." && pwd)/state/backup/reports}"
TS="$(now_ts)"
REPORT="$AUDIT_REPORT_ROOT/runtime-state-audit-$TS.md"

ensure_dir "$AUDIT_REPORT_ROOT"

extract_host_paths() {
  local file="$1"
  python3 - "$file" <<'PY'
import sys
from pathlib import Path
p=Path(sys.argv[1])
text=p.read_text(encoding='utf-8', errors='ignore')
for line in text.splitlines():
    s=line.strip()
    if not s.startswith('- '):
        continue
    item=s[2:].strip().strip('"').strip("'")
    if ':' not in item:
        continue
    left=item.split(':',1)[0].strip()
    if left.startswith('/'):
        print(left)
PY
}

ANON_FOUND=0
DRIFT_FOUND=0
MISSING_FOUND=0
{
  echo "# Runtime State Audit"
  echo
  echo "Generated: $(date -Is)"
  echo "Live compose: $LIVE_COMPOSE_PATH"
  echo "Template compose: $TEMPLATE_COMPOSE_PATH"
  echo

  echo "## Findings"

  if [[ -f "$LIVE_COMPOSE_PATH" ]]; then
    if grep -Eq '/var/lib/docker/volumes/.+:/appdata' "$LIVE_COMPOSE_PATH"; then
      echo "- anonymous volume detected: live compose still mounts /var/lib/docker/volumes/... to /appdata"
      ANON_FOUND=1
    fi
  else
    echo "- live compose missing: $LIVE_COMPOSE_PATH"
    MISSING_FOUND=1
  fi

  if [[ -f "$LIVE_COMPOSE_PATH" && -f "$TEMPLATE_COMPOSE_PATH" ]]; then
    if ! diff -u "$TEMPLATE_COMPOSE_PATH" "$LIVE_COMPOSE_PATH" >/dev/null 2>&1; then
      echo "- compose drift detected: live compose differs from recovery template"
      DRIFT_FOUND=1
    fi
  else
    echo "- compose comparison skipped: one or both compose files missing"
    MISSING_FOUND=1
  fi

  if [[ -f "$LIVE_COMPOSE_PATH" ]]; then
    while IFS= read -r path; do
      [[ -n "$path" ]] || continue
      case "$path" in
        /mnt/nas/*|/etc/localtime) continue ;;
      esac
      if [[ ! -e "$path" ]]; then
        echo "- missing local state path: $path"
        MISSING_FOUND=1
      fi
    done < <(extract_host_paths "$LIVE_COMPOSE_PATH")
  fi

  echo
  echo "## Summary"
  if [[ "$ANON_FOUND" -eq 0 && "$DRIFT_FOUND" -eq 0 && "$MISSING_FOUND" -eq 0 ]]; then
    echo "Status: PASS"
  else
    echo "Status: WARN"
    echo "anonymous_volume: $ANON_FOUND"
    echo "compose_drift: $DRIFT_FOUND"
    echo "missing_paths: $MISSING_FOUND"
  fi
} > "$REPORT"

echo "audit report: $REPORT"
