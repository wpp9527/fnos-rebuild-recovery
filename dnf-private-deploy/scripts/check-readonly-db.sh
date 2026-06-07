#!/usr/bin/env bash
set -euo pipefail
if [[ -z "${LLNUT_MYSQL_READONLY_USER:-}" ]]; then
  echo "[error] LLNUT_MYSQL_READONLY_USER is not set" >&2
  exit 1
fi
if [[ "${LLNUT_MYSQL_READONLY_USER}" == "root" ]]; then
  echo "[error] schema inspection must use read-only user, not root" >&2
  exit 2
fi
host="${LLNUT_MYSQL_HOST:-127.0.0.1}"
port="${LLNUT_MYSQL_PORT:-3306}"
user="${LLNUT_MYSQL_READONLY_USER}"
pass="${LLNUT_MYSQL_READONLY_PASSWORD:-}"
if ! command -v mysql >/dev/null 2>&1; then
  echo "[warn] mysql client not found; skipping connection check"
  exit 0
fi
if mysql -h "$host" -P "$port" -u "$user" -p"$pass" -e "SELECT 1" >/dev/null 2>&1; then
  echo "[ok] read-only database connection successful"
else
  echo "[error] read-only database connection failed" >&2
  exit 1
fi
