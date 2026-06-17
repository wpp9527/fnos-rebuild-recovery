#!/bin/bash
# DNF 台服数据抓取 + 贴吧监控 一键脚本
set -e
OUTPUT_DIR="/root/.openclaw/workspace/data/dnf-$(date +%Y%m%d)"
mkdir -p $OUTPUT_DIR

echo "=== DNF 台服数据采集 ==="
echo "输出目录: $OUTPUT_DIR"
echo ""

# 1. 游戏数据采集
echo "[1/5] 采集账号数据..."
sshpass -p 'wp930803' ssh -o StrictHostKeyChecking=no root@192.168.1.204 \
  "docker exec dnf-llnut_dnf-1_1 mysql -u root -p88888888 -e 'SELECT UID, accountname, admin, VIP FROM d_taiwan.accounts;' 2>/dev/null" \
  > $OUTPUT_DIR/accounts.csv 2>&1

echo "[2/5] 采集角色数据..."
sshpass -p 'wp930803' ssh -o StrictHostKeyChecking=no root@192.168.1.204 \
  "docker exec dnf-llnut_dnf-1_1 mysql -u root -p88888888 -e 'SELECT m_id, charac_name, village, job, lev, fatigue, max_fatigue, create_time, last_play_time, guild_id FROM taiwan_cain.charac_info;' 2>/dev/null" \
  > $OUTPUT_DIR/characters.csv 2>&1

echo "[3/5] 采集物品数据..."
sshpass -p 'wp930803' ssh -o StrictHostKeyChecking=no root@192.168.1.204 \
  "docker exec dnf-llnut_dnf-1_1 mysql -u root -p88888888 -e 'SELECT ui_id, charac_no, slot, it_id, expire_date, obtain_from, reg_date FROM taiwan_cain_2nd.user_items;' 2>/dev/null" \
  > $OUTPUT_DIR/items.csv 2>&1

echo "[4/5] 采集邮件数据..."
sshpass -p 'wp930803' ssh -o StrictHostKeyChecking=no root@192.168.1.204 \
  "docker exec dnf-llnut_dnf-1_1 mysql -u root -p88888888 -e 'SELECT postal_id, occ_time, send_charac_name, receive_charac_no, item_id, gold, receive_time FROM taiwan_cain_2nd.postal;' 2>/dev/null" \
  > $OUTPUT_DIR/postal.csv 2>&1

echo "[5/5] 采集交易记录..."
sshpass -p 'wp930803' ssh -o StrictHostKeyChecking=no root@192.168.1.204 \
  "docker exec dnf-llnut_dnf-1_1 mysql -u root -p88888888 -e 'SELECT tran_id, tran_type, occ_date FROM taiwan_billing.log_transaction_history;' 2>/dev/null" \
  > $OUTPUT_DIR/transactions.csv 2>&1

echo "[OK] 游戏数据采集完成"

# 2. 贴吧数据采集
echo "[6/6] 抓取台服dnf吧帖子..."
cd /root/.openclaw/workspace && python3 scripts/tieba-scraper.py "台服dnf" --pages 3 --output $OUTPUT_DIR/tieba_posts.json

# 3. 生成统计报告
echo ""
echo "=== 数据统计 ==="
echo "账号数: $(grep -c '' $OUTPUT_DIR/accounts.csv 2>/dev/null || echo 0)"
echo "角色数: $(grep -c '' $OUTPUT_DIR/characters.csv 2>/dev/null || echo 0)"
echo "物品数: $(grep -c '' $OUTPUT_DIR/items.csv 2>/dev/null || echo 0)"
echo "邮件数: $(grep -c '' $OUTPUT_DIR/postal.csv 2>/dev/null || echo 0)"
echo "交易记录: $(grep -c '' $OUTPUT_DIR/transactions.csv 2>/dev/null || echo 0)"
echo "贴吧帖子: $(python3 -c "import json; print(len(json.load(open('$OUTPUT_DIR/tieba_posts.json'))))" 2>/dev/null || echo 0)"

echo ""
echo "=== 采集完成 ==="
echo "数据目录: $OUTPUT_DIR"
