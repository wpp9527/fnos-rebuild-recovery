#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

LIVE_COMPOSE_PATH="${LIVE_COMPOSE_PATH:-/opt/fnos-media-stack/docker-compose.yml}"
TEMPLATE_COMPOSE_PATH="${TEMPLATE_COMPOSE_PATH:-$(cd "$SCRIPT_DIR/.." && pwd)/restore/templates/services/fnos-media-stack/docker-compose.yml}"
SERVICE_CATALOG_PATH="${SERVICE_CATALOG_PATH:-$(cd "$SCRIPT_DIR/.." && pwd)/restore/manifests/service-catalog.yaml}"
AUDIT_REPORT_ROOT="${AUDIT_REPORT_ROOT:-$(cd "$SCRIPT_DIR/.." && pwd)/state/backup/reports}"
TS="$(now_ts)"
TIMESTAMPED_REPORT="$AUDIT_REPORT_ROOT/runtime-state-audit-$TS.md"
LATEST_REPORT="$AUDIT_REPORT_ROOT/runtime-state-audit.md"

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

extract_service_names() {
  local file="$1"
  python3 - "$file" <<'PY'
import sys
from pathlib import Path
p=Path(sys.argv[1])
text=p.read_text(encoding='utf-8', errors='ignore')
for line in text.splitlines():
    s=line.strip()
    if not s or s.startswith('#'):
        continue
    if s.endswith(':') and not s.startswith('-') and s not in {'services:'}:
        name=s[:-1].strip()
        if name:
            print(name)
PY
}

container_has_mapping() {
  local name="$1"
  local norm
  norm="$(printf '%s' "$name" | tr '[:upper:]' '[:lower:]')"
  grep -Fqi "$norm" "$SERVICE_CATALOG_PATH" && return 0
  case "$norm" in
    homarr|halo-blog|jellyfin|qbittorrent|jackett|radarr|sonarr|prowlarr|bazarr|seerr|stash)
      grep -Fqi 'fnos-media-stack' "$SERVICE_CATALOG_PATH" && return 0
      ;;
    hermes-open-webui)
      grep -Fqi 'hermes-openwebui' "$SERVICE_CATALOG_PATH" && return 0
      ;;
    cli-proxy-api)
      grep -Fqi 'cliproxyapi' "$SERVICE_CATALOG_PATH" && return 0
      ;;
    cliproxyapi-ui)
      grep -Fqi 'cliproxyapi-ui' "$SERVICE_CATALOG_PATH" && return 0
      ;;
    qq-observe)
      grep -Fqi 'channels-qq' "$SERVICE_CATALOG_PATH" && return 0
      ;;
    feishu-observe)
      grep -Fqi 'channels-feishu' "$SERVICE_CATALOG_PATH" && return 0
      ;;
  esac
  return 1
}

ANON_FOUND=0
DRIFT_FOUND=0
MISSING_FOUND=0
UNMAPPED_FOUND=0
RUNNING_UNMAPPED_FOUND=0
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

  if [[ -f "$LIVE_COMPOSE_PATH" && -f "$SERVICE_CATALOG_PATH" ]]; then
    first_service="$(extract_service_names "$LIVE_COMPOSE_PATH" | head -n 1)"
    if [[ -n "$first_service" ]] && ! grep -Fqi "$first_service" "$SERVICE_CATALOG_PATH"; then
      echo "- runtime service missing recovery mapping: $first_service"
      UNMAPPED_FOUND=1
    fi
  fi

  if [[ -f "$SERVICE_CATALOG_PATH" ]] && command -v docker >/dev/null 2>&1; then
    while IFS= read -r container; do
      [[ -n "$container" ]] || continue
      if ! container_has_mapping "$container"; then
        echo "- running container missing recovery mapping: $container"
        RUNNING_UNMAPPED_FOUND=1
      fi
    done < <(docker ps --format '{{.Names}}' 2>/dev/null || true)
  fi

  echo
  echo "## Summary"
  if [[ "$ANON_FOUND" -eq 0 && "$DRIFT_FOUND" -eq 0 && "$MISSING_FOUND" -eq 0 && "$UNMAPPED_FOUND" -eq 0 && "$RUNNING_UNMAPPED_FOUND" -eq 0 ]]; then
    echo "Status: PASS"
  else
    echo "Status: WARN"
    echo "anonymous_volume: $ANON_FOUND"
    echo "compose_drift: $DRIFT_FOUND"
    echo "missing_paths: $MISSING_FOUND"
    echo "unmapped_runtime: $UNMAPPED_FOUND"
    echo "running_unmapped_runtime: $RUNNING_UNMAPPED_FOUND"
  fi
} > "$TIMESTAMPED_REPORT"

if [[ "$AUDIT_REPORT_ROOT" == */shared/restore-guides/latest ]]; then
  cp "$TIMESTAMPED_REPORT" "$LATEST_REPORT"
fi

echo "audit report: $TIMESTAMPED_REPORT"
