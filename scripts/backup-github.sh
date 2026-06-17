#!/bin/bash
# ============================================================
# 轻量备份 → GitHub
# 备份内容：配置文件、脚本、记忆、技能、Docker Compose、Nginx
# 不备份：Docker 数据卷、数据库、大文件
# ============================================================
set -euo pipefail

WORKSPACE="/root/.openclaw/workspace"
LOG="/var/log/backup-github.log"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG"; }

log "========== GitHub 轻量备份开始 =========="

cd "$WORKSPACE"

# 同步 recovery 目录（Docker Compose、Nginx、Crontab、OpenClaw 配置模板）
log "同步 recovery 配置..."
mkdir -p recovery/{docker-compose,nginx,crontab,openclaw}

# Docker Compose（排除备份目录）
find /fs/1000/ftp/docker -name "docker-compose*.yml" -not -path "*/backups/*" 2>/dev/null | while read f; do
  dir=$(dirname "$f" | sed 's|/fs/1000/ftp/docker/||' | tr '/' '_')
  cp "$f" "recovery/docker-compose/${dir}.yml"
done

# Nginx
cp /usr/trim/nginx/conf/conf.d/*.conf recovery/nginx/ 2>/dev/null

# Crontab
crontab -l > recovery/crontab/root.txt 2>/dev/null

# OpenClaw 配置（脱敏）
if [ -f /root/.openclaw/openclaw.json ]; then
  cat /root/.openclaw/openclaw.json | \
    sed 's/"apiKey": "[^"]*"/"apiKey": "***"/g' | \
    sed 's/"token": "[^"]*"/"token": "***"/g' | \
    sed 's/"appSecret": "[^"]*"/"appSecret": "REDACTED"/g' \
    > recovery/openclaw/openclaw.json.template
fi

# Git 提交
log "Git 提交..."
git add -A
if git diff --cached --quiet; then
  log "没有变更，跳过提交"
else
  git commit -m "自动备份 $(date '+%Y-%m-%d %H:%M')"
  git push origin master 2>&1 | tee -a "$LOG"
  log "✅ 已推送到 GitHub"
fi

log "========== GitHub 轻量备份完成 =========="
