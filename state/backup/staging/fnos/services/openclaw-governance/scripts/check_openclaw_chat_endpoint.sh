#!/usr/bin/env bash
set -euo pipefail
LOG=/opt/fnos-media/services/openclaw-governance/logs/chat-endpoint-health.log
URL=${OPENCLAW_HEALTH_URL:-http://127.0.0.1:18789/v1/chat/completions}
now(){ date '+%F %T %z'; }
tmp="/tmp/openclaw-chat-endpoint-health.$$"
code=$(curl -sS -o "$tmp" -w '%{http_code}' -X POST "$URL" \
  -H 'Content-Type: application/json' \
  -d '{"model":"ollama/qwen3:4b","messages":[{"role":"user","content":"ping"}],"max_tokens":1}' || true)
body=$(cat "$tmp" 2>/dev/null || true)
rm -f "$tmp"
case "$code" in
  200|400|401|403)
    echo "$(now) OK route-present http=$code" >> "$LOG"
    exit 0
    ;;
  404|000)
    echo "$(now) BAD route-missing-or-down http=$code body=${body:0:300}; restarting gateway" >> "$LOG"
    systemctl restart openclaw-governance-gateway.service
    exit 1
    ;;
  *)
    echo "$(now) WARN unexpected-http=$code body=${body:0:300}" >> "$LOG"
    exit 0
    ;;
esac
