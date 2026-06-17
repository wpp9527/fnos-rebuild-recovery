#!/usr/bin/env bash
# Setup cron jobs for backup automation
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo "=== 设置定时备份任务 ==="
echo

# Check if crontab exists
if ! command -v crontab &>/dev/null; then
  echo "错误: crontab 未安装"
  exit 1
fi

# Get current crontab
CURRENT_CRON=$(crontab -l 2>/dev/null || true)

# Check if backup jobs already exist
if echo "$CURRENT_CRON" | grep -q "run_daily.sh\|run_weekly.sh"; then
  echo "定时备份任务已存在:"
  echo "$CURRENT_CRON" | grep -E "(run_daily|run_weekly)"
  echo
  read -p "是否更新? [y/N] " answer
  case "$answer" in
    y|Y) ;;
    *) echo "已取消"; exit 0 ;;
  esac
  # Remove existing backup jobs
  CURRENT_CRON=$(echo "$CURRENT_CRON" | grep -v "run_daily.sh" | grep -v "run_weekly.sh")
fi

# Add new backup jobs
NEW_CRON="${CURRENT_CRON}
# OpenClaw backup automation
0 2 * * * $WORKSPACE_ROOT/scripts/backup/run_daily.sh >> /var/log/backup-daily.log 2>&1
0 3 * * 0 $WORKSPACE_ROOT/scripts/backup/run_weekly.sh >> /var/log/backup-weekly.log 2>&1"

# Install new crontab
echo "$NEW_CRON" | crontab -

echo "✓ 定时任务已添加:"
echo "  每日备份: 02:00"
echo "  每周备份: 周日 03:00"
echo
echo "日志位置:"
echo "  /var/log/backup-daily.log"
echo "  /var/log/backup-weekly.log"
echo
echo "查看定时任务: crontab -l"
