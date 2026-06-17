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
