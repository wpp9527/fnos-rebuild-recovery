#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${ENV_FILE:-$ROOT_DIR/env/.env.example}"
if [[ -f "$ENV_FILE" ]]; then
  while IFS='=' read -r key value; do
    [[ -z "$key" || "$key" == \#* ]] && continue
    case "$key" in
      LLNUT_MYSQL_HOST|LLNUT_MYSQL_PORT|LLNUT_MYSQL_READONLY_USER|LLNUT_MYSQL_READONLY_PASSWORD)
        if [[ -z "${!key:-}" ]]; then
          export "$key=$value"
        fi
        ;;
    esac
  done < "$ENV_FILE"
fi

if [[ "${1:-}" == "--example-json" ]]; then
  cat <<'JSON'
{
  "tables": {
    "d_taiwan.accounts": ["UID", "accountname", "admin", "parent_uid"]
  }
}
JSON
  exit 0
fi
MYSQL_HOST="${LLNUT_MYSQL_HOST:-127.0.0.1}"
MYSQL_PORT="${LLNUT_MYSQL_PORT:-3306}"
MYSQL_USER="${LLNUT_MYSQL_READONLY_USER:-dnf_readonly}"
MYSQL_PASSWORD="${LLNUT_MYSQL_READONLY_PASSWORD:-}"

if [[ "$MYSQL_USER" == "root" ]]; then
  echo "[error] schema inspection must use read-only user, not root" >&2
  exit 2
fi

mysql -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" -N -e \
  "SELECT CONCAT(TABLE_SCHEMA,'.',TABLE_NAME) AS table_name, GROUP_CONCAT(COLUMN_NAME ORDER BY ORDINAL_POSITION) AS columns FROM information_schema.COLUMNS WHERE TABLE_SCHEMA IN ('d_taiwan','taiwan_login','taiwan_cain','taiwan_cain_2nd','taiwan_billing') GROUP BY TABLE_SCHEMA,TABLE_NAME ORDER BY TABLE_SCHEMA,TABLE_NAME;"
