#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
ALERT_LOG="$TMP/alerts.log"
OUT="$(ALERT_LOG="$ALERT_LOG" bash "$ROOT/restore/report_alert.sh" WARN 'restore preflight warning' 'OPENCLAW_API_TOKEN=secret-token' 2>/dev/null)"
printf '%s' "$OUT" | grep -Fq 'ALERT WARN' || { echo 'missing alert output' >&2; exit 1; }
! printf '%s' "$OUT" | grep -Fq 'secret-token' || { echo 'alert output leaked secret' >&2; exit 1; }
! grep -Fq 'secret-token' "$ALERT_LOG" || { echo 'alert log leaked secret' >&2; exit 1; }
echo 'PASS test_alert_payload_redaction'
