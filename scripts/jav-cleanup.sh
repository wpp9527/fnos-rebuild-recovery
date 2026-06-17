#!/bin/bash
# JAV 媒体文件清理脚本
# 功能：删除重复文件夹、广告文件、空文件夹

set -euo pipefail

MEDIA_ROOT="/mnt/nas/media/jav"
TRASH_DIR="/tmp/jav-trash-$(date +%Y%m%d-%H%M%S)"

mkdir -p "$TRASH_DIR"

echo "=== JAV 媒体文件清理 ==="
echo "时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo "媒体目录: $MEDIA_ROOT"
echo ""

# 1. 删除广告文件
echo "=== 1. 删除广告文件 ==="
AD_FILES=$(find "$MEDIA_ROOT" -type f \( -name "*.txt" -o -name "*.url" -o -name "*.html" -o -name "*.htm" -o -name "*.torrent" \) 2>/dev/null)
if [ -n "$AD_FILES" ]; then
    echo "找到广告文件:"
    echo "$AD_FILES" | while read -r file; do
        echo "  $(basename "$file")"
        mv "$file" "$TRASH_DIR/" 2>/dev/null || true
    done
    echo "已移动到: $TRASH_DIR"
else
    echo "没有找到广告文件"
fi

echo ""

# 2. 删除重复文件夹（保留大写版本）
echo "=== 2. 删除重复文件夹 ==="
DUPLICATE_COUNT=0
for dir in "$MEDIA_ROOT"/*/; do
    if [ -d "$dir" ]; then
        dirname=$(basename "$dir")
        # 检查是否有大写版本
        if [[ "$dirname" =~ ^[a-z] ]]; then
            upper_dir="$MEDIA_ROOT/$(echo "$dirname" | tr '[:lower:]' '[:upper:]')"
            if [ -d "$upper_dir" ]; then
                # 大写版本存在，删除小写版本
                echo "  重复: $dirname -> $(basename "$upper_dir")"
                mv "$dir" "$TRASH_DIR/" 2>/dev/null || true
                DUPLICATE_COUNT=$((DUPLICATE_COUNT + 1))
            fi
        fi
    fi
done
echo "删除了 $DUPLICATE_COUNT 个重复文件夹"

echo ""

# 3. 删除空文件夹
echo "=== 3. 删除空文件夹 ==="
EMPTY_COUNT=$(find "$MEDIA_ROOT" -maxdepth 1 -type d -empty 2>/dev/null | wc -l)
if [ "$EMPTY_COUNT" -gt 0 ]; then
    find "$MEDIA_ROOT" -maxdepth 1 -type d -empty -delete 2>/dev/null || true
    echo "删除了 $EMPTY_COUNT 个空文件夹"
else
    echo "没有空文件夹"
fi

echo ""

# 4. 统计信息
echo "=== 4. 统计信息 ==="
TOTAL_DIRS=$(find "$MEDIA_ROOT" -maxdepth 1 -type d | wc -l)
TOTAL_FILES=$(find "$MEDIA_ROOT" -type f | wc -l)
TOTAL_SIZE=$(du -sh "$MEDIA_ROOT" 2>/dev/null | cut -f1)
echo "总文件夹数: $TOTAL_DIRS"
echo "总文件数: $TOTAL_FILES"
echo "总大小: $TOTAL_SIZE"

echo ""
echo "=== 清理完成 ==="
echo "垃圾目录: $TRASH_DIR"
echo "如需恢复文件，请从垃圾目录中找回"
