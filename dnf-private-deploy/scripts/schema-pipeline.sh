#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
API_URL="${DNF_PUBLIC_ADMIN_API_URL:-http://127.0.0.1:18882}"

echo "[step] schema inspect (--example-json)"
schema="$("$ROOT_DIR/scripts/schema-inspect.sh" --example-json)"
echo "[step] schema to json"
echo "$schema" | python3 -m json.tool >/dev/null

echo "[step] validate against new admin API"
resp="$(curl -sS --max-time 10 -H "Content-Type: application/json" -d "$schema" "$API_URL/api/v1/meta/llnut-schema/validate")"
echo "$resp"

if echo "$resp" | python3 -c "import json,sys; d=json.load(sys.stdin); sys.exit(0 if d.get('ok') else 1)"; then
  echo "[ok] schema pipeline passed"
else
  echo "[error] schema validation failed" >&2
  exit 1
fi
