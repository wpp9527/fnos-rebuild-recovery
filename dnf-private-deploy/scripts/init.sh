#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
mkdir -p "$ROOT_DIR/data" "$ROOT_DIR/mysql" "$ROOT_DIR/log" "$ROOT_DIR/backups"
echo "[ok] initialized directories under $ROOT_DIR"
