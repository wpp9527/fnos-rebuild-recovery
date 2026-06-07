#!/usr/bin/env bash
set -euo pipefail
OLD_ADMIN_URL="${OLD_ADMIN_URL:-http://127.0.0.1:882}"
NEW_ADMIN_API_URL="${DNF_PUBLIC_ADMIN_API_URL:-http://127.0.0.1:18882}"

echo "[info] old admin: $OLD_ADMIN_URL"
echo "[info] new admin api: $NEW_ADMIN_API_URL"

old_status="unreachable"
new_status="unreachable"
if curl -sS -I --max-time 5 "$OLD_ADMIN_URL" >/tmp/dnf-old-admin.headers 2>/dev/null; then
  old_status="reachable"
fi
if curl -sS --max-time 5 "$NEW_ADMIN_API_URL/api/v1/health" >/tmp/dnf-new-admin-health.json 2>/dev/null; then
  new_status="reachable"
fi

cat <<JSON
{
  "old_admin_url": "$OLD_ADMIN_URL",
  "old_admin_status": "$old_status",
  "new_admin_api_url": "$NEW_ADMIN_API_URL",
  "new_admin_status": "$new_status",
  "note": "This script checks endpoint reachability only. Data-count comparison runs after readonly DB credentials are configured."
}
JSON
