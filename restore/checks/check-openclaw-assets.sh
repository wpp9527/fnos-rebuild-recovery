#!/usr/bin/env bash
set -euo pipefail
OPENCLAW_LATEST_ROOT="${OPENCLAW_LATEST_ROOT:-/mnt/nas/backup/services/openclaw/latest}"
if [[ -d "$OPENCLAW_LATEST_ROOT/docs" && -d "$OPENCLAW_LATEST_ROOT/scripts" ]]; then
  echo 'PASS openclaw-assets: minimal control-plane structure present'
else
  echo 'WARN openclaw-assets: minimal control-plane structure incomplete'
fi
