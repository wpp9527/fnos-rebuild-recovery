#!/usr/bin/env bash
set -euo pipefail
API_URL="${DNF_PUBLIC_ADMIN_API_URL:-http://127.0.0.1:18882}"
SCHEMA_JSON="${1:-}"
if [[ -z "$SCHEMA_JSON" || ! -f "$SCHEMA_JSON" ]]; then
  echo "usage: $0 <schema-json-file>" >&2
  exit 2
fi
curl -sS -f -H 'Content-Type: application/json' --data-binary "@$SCHEMA_JSON" "$API_URL/api/v1/meta/llnut-schema/validate"
echo
