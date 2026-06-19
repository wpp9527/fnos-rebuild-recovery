#!/bin/bash
# ============================================================
# 全量备份 → TrueNAS
# 备份内容：PostgreSQL、Docker 配置卷、OpenClaw 配置、密钥
# 存储位置：/mnt/nas/backup/openclaw-backup/
# ============================================================
set -euo pipefail

NAS_BACKUP="/mnt/nas/backup/openclaw-backup"
LOG="/var/log/backup-truenas.log"
DATE=$(date '+%Y-%m-%d_%H%M')
RETENTION_DAYS=30

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG"; }

log "========== TrueNAS 全量备份开始 =========="

# 检查 NAS 挂载
if ! mountpoint -q /mnt/nas/backup; then
  log "❌ TrueNAS 未挂载，尝试重新挂载..."
  mount -t nfs4 192.168.1.133:/mnt/storage/backup /mnt/nas/backup 2>/dev/null || {
    log "❌ 挂载失败，退出"
    exit 1
  }
fi

# ============================================================
# 1. PostgreSQL 数据库备份
# ============================================================
log "备份 PostgreSQL 数据库..."
PG_BACKUP="$NAS_BACKUP/postgres"
mkdir -p "$PG_BACKUP"

for db in ai_manager appcenter dm open_gateway; do
  log "  导出 $db..."
  pg_dump -U postgres -Fc "$db" > "$PG_BACKUP/${db}_${DATE}.dump" 2>/dev/null && \
    log "  ✅ $db 已导出" || \
    log "  ⚠️ $db 导出失败"
done

find "$PG_BACKUP" -name "*.dump" -mtime +${RETENTION_DAYS} -delete 2>/dev/null

# ============================================================
# 2. Docker 配置卷备份（仅配置，不备份媒体数据）
# ============================================================
log "备份 Docker 配置卷..."
VOL_BACKUP="$NAS_BACKUP/docker-volumes"
mkdir -p "$VOL_BACKUP"

# 定义容器配置路径映射（只备份配置目录）
declare -A CONTAINER_CONFIGS=(
  ["qbittorrent"]="/vol1/1000/docker/media-stack/qbittorrent/config"
  ["sonarr"]="/vol1/1000/docker/media-stack/sonarr/config"
  ["radarr"]="/vol1/1000/docker/media-stack/radarr/config"
  ["prowlarr"]="/vol1/1000/docker/media-stack/prowlarr/config"
  ["bazarr"]="/vol1/1000/docker/media-stack/bazarr/config"
  ["jackett"]="/vol1/1000/docker/media-stack/jackett/config"
  ["homarr"]="/vol1/1000/docker/media-stack/homarr/config"
  ["stash"]="/vol1/1000/docker/media-stack/stash"
  ["jellyfin"]="/root/.openclaw/workspace/jellyfin-config"
)

for container in "${!CONTAINER_CONFIGS[@]}"; do
  src="${CONTAINER_CONFIGS[$container]}"
  if [ -d "$src" ]; then
    log "  备份 $container 配置..."
    mkdir -p "$VOL_BACKUP/$container"
    rsync -rlptD --no-owner --no-group --delete "$src/" "$VOL_BACKUP/$container/" 2>/dev/null || true
    log "  ✅ $container 已备份"
  else
    log "  ⚠️ $container 配置目录不存在: $src"
  fi
done

log "✅ Docker 配置卷已备份"

# ============================================================
# 3. OpenClaw 完整配置（含密钥）
# ============================================================
log "备份 OpenClaw 配置..."
CONFIG_BACKUP="$NAS_BACKUP/config"
mkdir -p "$CONFIG_BACKUP"

if [ -f /root/.openclaw/openclaw.json ]; then
  cp /root/.openclaw/openclaw.json "$CONFIG_BACKUP/openclaw_${DATE}.json"
  log "✅ OpenClaw 配置已备份"
fi

if [ -d /root/.ssh ]; then
  cp -r /root/.ssh "$CONFIG_BACKUP/ssh_${DATE}"
  log "✅ SSH 密钥已备份"
fi

find "$CONFIG_BACKUP" -name "openclaw_*.json" -mtime +${RETENTION_DAYS} -delete 2>/dev/null
find "$CONFIG_BACKUP" -name "ssh_*" -mtime +${RETENTION_DAYS} -type d -exec rm -rf {} + 2>/dev/null

# ============================================================
# 4. Nginx 配置
# ============================================================
log "备份 Nginx 配置..."
NGINX_BACKUP="$NAS_BACKUP/nginx"
mkdir -p "$NGINX_BACKUP"
cp /usr/trim/nginx/conf/conf.d/*.conf "$NGINX_BACKUP/" 2>/dev/null
log "✅ Nginx 配置已备份"

# ============================================================
# 5. Crontab
# ============================================================
log "备份 Crontab..."
mkdir -p "$NAS_BACKUP/crontab"
crontab -l > "$NAS_BACKUP/crontab/root_${DATE}.txt" 2>/dev/null
log "✅ Crontab 已备份"

# ============================================================
# 6. 工作区 Git 仓库备份
# ============================================================
log "备份工作区 Git 仓库..."
WORKSPACE_BACKUP="$NAS_BACKUP/workspace"
mkdir -p "$WORKSPACE_BACKUP"
cd /root/.openclaw/workspace
git bundle create "$WORKSPACE_BACKUP/workspace_${DATE}.bundle" --all 2>/dev/null && \
  log "✅ Git 仓库已打包" || \
  log "⚠️ Git bundle 创建失败"
find "$WORKSPACE_BACKUP" -name "*.bundle" -mtime +${RETENTION_DAYS} -delete 2>/dev/null

# ============================================================
# 7. Docker 镜像备份（增量：只保存新增/更新的镜像）
# ============================================================
log "备份 Docker 镜像..."
IMAGE_BACKUP="$NAS_BACKUP/docker-images"
mkdir -p "$IMAGE_BACKUP"

SAVED_COUNT=0
SKIPPED_COUNT=0
FAILED_COUNT=0

# 获取所有非 none 镜像
IMAGE_LIST=$(docker images --format "{{.Repository}}:{{.Tag}}" | grep -v "<none>")

for image in $IMAGE_LIST; do
  # 生成安全文件名
  safe_name=$(echo "$image" | tr '/:' '__')
  tar_file="$IMAGE_BACKUP/${safe_name}.tar"

  # 获取镜像 ID
  image_id=$(docker inspect --format='{{.Id}}' "$image" 2>/dev/null)

  # 如果 tar 已存在，检查是否同一镜像（通过 tar 内的 manifest）
  if [ -f "$tar_file" ]; then
    saved_id=$(tar -xf "$tar_file" manifest.json -O 2>/dev/null | grep -o '"Config":"[^"]*"' | head -1 | cut -d'"' -f4 | sed 's|.*sha256/||;s|.*sha256:||')
    current_id=$(echo "$image_id" | sed 's|.*sha256:||')
    if [ "$saved_id" = "$current_id" ] && [ -n "$saved_id" ]; then
      SKIPPED_COUNT=$((SKIPPED_COUNT + 1))
      continue
    fi
  fi

  log "  保存 $image ..."
  if docker save -o "$tar_file" "$image" 2>/dev/null; then
    size=$(du -sh "$tar_file" | cut -f1)
    log "  ✅ $image → $size"
    SAVED_COUNT=$((SAVED_COUNT + 1))
  else
    log "  ⚠️ $image 保存失败"
    FAILED_COUNT=$((FAILED_COUNT + 1))
  fi
done

# 清理已不存在的镜像对应的 tar（保留 30 天后删除）
for tar_file in "$IMAGE_BACKUP"/*.tar; do
  [ -f "$tar_file" ] || continue
  if [ $(find "$tar_file" -mtime +${RETENTION_DAYS} -print 2>/dev/null | wc -l) -gt 0 ]; then
    base=$(basename "$tar_file" .tar)
    orig=$(echo "$base" | sed 's|__|/|g; s|_|:|')
    if ! echo "$IMAGE_LIST" | grep -qx "$orig" 2>/dev/null; then
      log "  清理过期镜像备份: $base"
      rm -f "$tar_file"
    fi
  fi
done

log "✅ Docker 镜像备份完成（保存: $SAVED_COUNT, 跳过: $SKIPPED_COUNT, 失败: $FAILED_COUNT）"

# ============================================================
# 8. 生成备份清单
# ============================================================
log "生成备份清单..."
cat > "$NAS_BACKUP/backup_manifest_${DATE}.txt" << EOF
========== TrueNAS 备份清单 ==========
日期: $(date '+%Y-%m-%d %H:%M:%S')
主机: $(hostname)
IP: 192.168.1.212

## PostgreSQL 数据库
$(ls -lh "$PG_BACKUP/"*${DATE}* 2>/dev/null || echo "无")

## Docker 配置卷
$(du -sh "$VOL_BACKUP"/* 2>/dev/null || echo "无")

## OpenClaw 配置
$(ls -lh "$CONFIG_BACKUP/"*${DATE}* 2>/dev/null || echo "无")

## Nginx 配置
$(ls -lh "$NGINX_BACKUP/" 2>/dev/null | head -5)
... 共 $(ls "$NGINX_BACKUP/" 2>/dev/null | wc -l) 个文件

## Git 仓库
$(ls -lh "$WORKSPACE_BACKUP/"*${DATE}* 2>/dev/null || echo "无")

## Docker 镜像
$(ls -lh "$IMAGE_BACKUP/"*.tar 2>/dev/null | wc -l) 个镜像，共 $(du -sh "$IMAGE_BACKUP" 2>/dev/null | cut -f1)

## 备份总大小
$(du -sh "$NAS_BACKUP" 2>/dev/null)

## 保留策略
- 数据库: 最近 ${RETENTION_DAYS} 天
- 配置文件: 最新一份
- Git 仓库: 最近 ${RETENTION_DAYS} 天
- Docker 镜像: 增量保存，已删除镜像的 tar 保留 30 天
EOF

log "✅ 备份清单已生成"
log "========== TrueNAS 全量备份完成 =========="
log "备份位置: $NAS_BACKUP"
