#!/bin/bash
# DNF 后台管理系统 - 定时任务设置
# 自动运行数据采集、自检、贴吧抓取

set -e

echo "=== 设置 DNF 后台管理系统定时任务 ==="
echo ""

# 1. 创建定时任务
cat > /tmp/dnf-crontab << 'EOF'
# DNF 后台管理系统定时任务
# 每小时运行数据采集
0 * * * * /root/.openclaw/workspace/scripts/dnf-data-collector.sh all >> /var/log/dnf-data-collector.log 2>&1

# 每天凌晨 2 点运行自检
0 2 * * * /root/.openclaw/workspace/scripts/dnf-self-check.sh >> /var/log/dnf-self-check.log 2>&1

# 每 6 小时抓取贴吧
0 */6 * * * cd /root/.openclaw/workspace && python3 scripts/tieba-scraper.py "台服dnf" --pages 5 --output /root/.openclaw/workspace/data/tieba/latest.json >> /var/log/dnf-tieba.log 2>&1

# 每天凌晨 3 点导入贴吧数据到数据库
0 3 * * * /root/.openclaw/workspace/scripts/dnf-tieba-import.sh >> /var/log/dnf-tieba-import.log 2>&1

# 每周日凌晨 4 点生成周报
0 4 * * 0 /root/.openclaw/workspace/scripts/dnf-weekly-report.sh >> /var/log/dnf-weekly-report.log 2>&1
EOF

# 2. 创建贴吧导入脚本
cat > /root/.openclaw/workspace/scripts/dnf-tieba-import.sh << 'SCRIPT'
#!/bin/bash
# 导入贴吧数据到数据库
cd /root/.openclaw/workspace

# 获取最新抓取的帖子
LATEST_FILE=$(ls -t data/tieba/*.json 2>/dev/null | head -1)
if [ -z "$LATEST_FILE" ]; then
    echo "[$(date)] 没有找到贴吧数据文件"
    exit 1
fi

echo "[$(date)] 导入贴吧数据: $LATEST_FILE"

# 通过 SSH 导入
python3 -c "
import json
import subprocess

with open('$LATEST_FILE') as f:
    posts = json.load(f)

imported = 0
for p in posts:
    title = p['title'].replace(\"'\", \"'\")
    url = p['url']
    sql = f\"INSERT IGNORE INTO dnf_tieba.tieba_posts (tieba_name, title, author, reply_count, view_count, url, post_time) VALUES ('台服dnf', '{title}', '', 0, 0, '{url}', NOW());\"
    cmd = f\"sshpass -p wp930803 ssh -o StrictHostKeyChecking=no root@192.168.1.204 \\\"docker exec dnf-llnut_dnf-1_1 mysql -u root -p88888888 dnf_tieba -e \\\\\\\"{sql}\\\\\\\"\\\"\"
    result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
    if result.returncode == 0:
        imported += 1

print(f'[$(date)] 导入完成: {imported}/{len(posts)}')
"
SCRIPT

# 3. 创建周报脚本
cat > /root/.openclaw/workspace/scripts/dnf-weekly-report.sh << 'SCRIPT'
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
SCRIPT

# 设置执行权限
chmod +x /root/.openclaw/workspace/scripts/dnf-tieba-import.sh
chmod +x /root/.openclaw/workspace/scripts/dnf-weekly-report.sh

# 4. 安装定时任务
crontab /tmp/dnf-crontab

echo "=== 定时任务设置完成 ==="
echo ""
echo "已设置的定时任务:"
echo "1. 每小时运行数据采集"
echo "2. 每天凌晨 2 点运行自检"
echo "3. 每 6 小时抓取贴吧"
echo "4. 每天凌晨 3 点导入贴吧数据"
echo "5. 每周日凌晨 4 点生成周报"
echo ""
echo "查看定时任务: crontab -l"
echo "查看日志: tail -f /var/log/dnf-*.log"
