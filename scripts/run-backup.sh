#!/bin/bash
# ============================================================
# 主备份脚本 - 同时运行 GitHub 和 TrueNAS 备份
# 用法: ./run-backup.sh [--github|--truenas|--all]
# ============================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MODE="${1:---all}"

case "$MODE" in
  --github)
    echo ">>> 运行 GitHub 轻量备份..."
    bash "$SCRIPT_DIR/backup-github.sh"
    ;;
  --truenas)
    echo ">>> 运行 TrueNAS 全量备份..."
    bash "$SCRIPT_DIR/backup-truenas.sh"
    ;;
  --all)
    echo ">>> 运行完整备份（GitHub + TrueNAS）..."
    echo ""
    echo "===== 1/2: GitHub 轻量备份 ====="
    bash "$SCRIPT_DIR/backup-github.sh" || true
    echo ""
    echo "===== 2/2: TrueNAS 全量备份 ====="
    bash "$SCRIPT_DIR/backup-truenas.sh" || true
    echo ""
    echo "✅ 全部备份完成"
    ;;
  *)
    echo "用法: $0 [--github|--truenas|--all]"
    exit 1
    ;;
esac
