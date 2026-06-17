#!/bin/bash
# 生成 DNF 周报
OUTPUT_DIR="/root/.openclaw/workspace/data/reports/$(date +%Y%m%d)"
mkdir -p $OUTPUT_DIR

echo "=== DNF 周报 - $(date '+%Y-%m-%d') ===" > $OUTPUT_DIR/report.md

# 账号统计
sshpass -p 'wp930803' ssh -o StrictHostKeyChecking=no root@192.168.1.204 \
  "docker exec dnf-llnut_dnf-1_1 mysql -u root -p88888888 -e \"
    SELECT 
      '本周新增账号' as item,
      COUNT(*) as value
    FROM d_taiwan.accounts
    WHERE admin > 0
  \" 2>/dev/null" >> $OUTPUT_DIR/report.md

# 角色统计
sshpass -p 'wp930803' ssh -o StrictHostKeyChecking=no root@192.168.1.204 \
  "docker exec dnf-llnut_dnf-1_1 mysql -u root -p88888888 -e \"
    SELECT 
      '本周活跃角色' as item,
      COUNT(*) as value
    FROM taiwan_cain.charac_info
    WHERE last_play_time > DATE_SUB(NOW(), INTERVAL 7 DAY)
  \" 2>/dev/null" >> $OUTPUT_DIR/report.md

# 贴吧统计
sshpass -p 'wp930803' ssh -o StrictHostKeyChecking=no root@192.168.1.204 \
  "docker exec dnf-llnut_dnf-1_1 mysql -u root -p88888888 -e \"
    SELECT 
      '本周新增帖子' as item,
      COUNT(*) as value
    FROM dnf_tieba.tieba_posts
    WHERE post_time > DATE_SUB(NOW(), INTERVAL 7 DAY)
  \" 2>/dev/null" >> $OUTPUT_DIR/report.md

echo "[$(date)] 周报已生成: $OUTPUT_DIR/report.md"
