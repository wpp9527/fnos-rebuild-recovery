#!/usr/bin/env bash
set -euo pipefail
LEVEL="${1:-INFO}"
TITLE="${2:-alert}"
DETAIL="${3:-}"
ALERT_LOG="${ALERT_LOG:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/reports/alerts.log}"
mkdir -p "$(dirname "$ALERT_LOG")"
SANITIZED="$(printf '%s' "$DETAIL" | sed -E 's/([A-Z0-9_]+)=([^[:space:]]+)/\1=[REDACTED]/g')"
LINE="ALERT $LEVEL: $TITLE :: $SANITIZED"
printf '%s\n' "$LINE" | tee -a "$ALERT_LOG"
