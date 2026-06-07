#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
TARGET="$ROOT_DIR/backups/dnf-backup-$STAMP.tar.gz"
mkdir -p "$ROOT_DIR/backups"
tar -czf "$TARGET" -C "$ROOT_DIR" data mysql log 2>/dev/null || tar -czf "$TARGET" -C "$ROOT_DIR" .
echo "[ok] backup created: $TARGET"
