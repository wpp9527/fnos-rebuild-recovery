#!/usr/bin/env bash
# 收集所有容器的 docker-compose.yml 和 .env 文件（用于恢复构建）
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"

STAGING_ROOT="${STAGING_ROOT:-$(cd "$SCRIPT_DIR/../../../state" && pwd)/backup/staging}"
COMPOSE_STAGE_DIR="$STAGING_ROOT/compose-files"

ensure_dir "$COMPOSE_STAGE_DIR"
rm -rf "$COMPOSE_STAGE_DIR"
ensure_dir "$COMPOSE_STAGE_DIR"

FOUND=0

# 收集 /vol1/1000/docker/ 和 /vol1/1000/docker/media-stack/ 下所有 compose 文件
while IFS= read -r -d '' compose_file; do
  rel_dir="$(dirname "$compose_file")"
  rel="${rel_dir#/vol1/1000/docker/}"
  dst_dir="$COMPOSE_STAGE_DIR/$rel"
  ensure_dir "$dst_dir"
  cp "$compose_file" "$dst_dir/"

  # 复制同目录的 .env
  env_file="$(dirname "$compose_file")/.env"
  [[ -f "$env_file" ]] && cp "$env_file" "$dst_dir/"

  # 复制同目录的 *.sh 脚本
  for sh_file in "$(dirname "$compose_file")"/*.sh; do
    [[ -f "$sh_file" ]] && cp "$sh_file" "$dst_dir/"
  done

  FOUND=$((FOUND + 1))
done < <(find /vol1/1000/docker -maxdepth 3 -name "docker-compose*.yml" -print0 2>/dev/null)

# 也收集 MDC
if [[ -d "/vol1/1000/docker/mdc" ]]; then
  dst_dir="$COMPOSE_STAGE_DIR/mdc"
  ensure_dir "$dst_dir"
  for f in /vol1/1000/docker/mdc/docker-compose*.yml /vol1/1000/docker/mdc/.env /vol1/1000/docker/mdc/*.sh; do
    [[ -f "$f" ]] && cp "$f" "$dst_dir/" && FOUND=$((FOUND + 1))
  done
fi

cat > "$COMPOSE_STAGE_DIR/manifest.yaml" << EOF
# Compose Files Backup Manifest
generated: $(date -Is)
files_collected: $FOUND
purpose: 恢复容器构建所需的 docker-compose.yml 和配置文件
EOF

log "collect_compose_files: complete ($FOUND files)"
