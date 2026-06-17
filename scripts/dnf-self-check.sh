#!/bin/bash
# DNF 后台管理系统 - 数据自检脚本
# 确保数据真实可靠
set -e

OUTPUT_DIR="/root/.openclaw/workspace/data/dnf-selfcheck-$(date +%Y%m%d_%H%M)"
mkdir -p $OUTPUT_DIR

echo "=== DNF 数据自检系统 ==="
echo "时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo ""

# 1. 基础数据自检
echo "[1/8] 账号数据自检..."
sshpass -p 'wp930803' ssh -o StrictHostKeyChecking=no root@192.168.1.204 \
  "docker exec dnf-llnut_dnf-1_1 mysql -u root -p88888888 -e \"
    SELECT 
      '账号总数' as check_item,
      COUNT(*) as value,
      '正常' as status
    FROM d_taiwan.accounts
    UNION ALL
    SELECT 
      '管理员账号',
      COUNT(*),
      CASE WHEN COUNT(*) > 0 THEN '正常' ELSE '异常' END
    FROM d_taiwan.accounts WHERE admin > 0
    UNION ALL
    SELECT 
      'VIP账号',
      COUNT(*),
      '正常'
    FROM d_taiwan.accounts WHERE VIP != '';
  \" 2>/dev/null" > $OUTPUT_DIR/accounts.txt

echo "[2/8] 角色数据自检..."
sshpass -p 'wp930803' ssh -o StrictHostKeyChecking=no root@192.168.1.204 \
  "docker exec dnf-llnut_dnf-1_1 mysql -u root -p88888888 -e \"
    SELECT 
      '角色总数' as check_item,
      COUNT(*) as value,
      CASE WHEN COUNT(*) > 0 THEN '正常' ELSE '异常' END as status
    FROM taiwan_cain.charac_info
    UNION ALL
    SELECT 
      '最高等级',
      MAX(lev),
      CASE WHEN MAX(lev) BETWEEN 1 AND 100 THEN '正常' ELSE '异常' END
    FROM taiwan_cain.charac_info
    UNION ALL
    SELECT 
      '平均等级',
      ROUND(AVG(lev),1),
      '正常'
    FROM taiwan_cain.charac_info
    UNION ALL
    SELECT 
      '职业种类',
      COUNT(DISTINCT job),
      '正常'
    FROM taiwan_cain.charac_info;
  \" 2>/dev/null" > $OUTPUT_DIR/characters.txt

echo "[3/8] 物品数据自检..."
sshpass -p 'wp930803' ssh -o StrictHostKeyChecking=no root@192.168.1.204 \
  "docker exec dnf-llnut_dnf-1_1 mysql -u root -p88888888 -e \"
    SELECT 
      '物品总数' as check_item,
      COUNT(*) as value,
      CASE WHEN COUNT(*) > 0 THEN '正常' ELSE '异常' END as status
    FROM taiwan_cain_2nd.user_items
    UNION ALL
    SELECT 
      '物品种类',
      COUNT(DISTINCT it_id),
      '正常'
    FROM taiwan_cain_2nd.user_items
    UNION ALL
    SELECT 
      '装备物品数',
      COUNT(*),
      '正常'
    FROM taiwan_cain_2nd.user_items WHERE slot > 0;
  \" 2>/dev/null" > $OUTPUT_DIR/items.txt

echo "[4/8] 邮件数据自检..."
sshpass -p 'wp930803' ssh -o StrictHostKeyChecking=no root@192.168.1.204 \
  "docker exec dnf-llnut_dnf-1_1 mysql -u root -p88888888 -e \"
    SELECT 
      '邮件总数' as check_item,
      COUNT(*) as value,
      CASE WHEN COUNT(*) > 0 THEN '正常' ELSE '异常' END as status
    FROM taiwan_cain_2nd.postal
    UNION ALL
    SELECT 
      '未读邮件',
      SUM(CASE WHEN delete_flag = 0 THEN 1 ELSE 0 END),
      '正常'
    FROM taiwan_cain_2nd.postal
    UNION ALL
    SELECT 
      '含金币邮件',
      SUM(CASE WHEN gold > 0 THEN 1 ELSE 0 END),
      '正常'
    FROM taiwan_cain_2nd.postal
    UNION ALL
    SELECT 
      '邮件总金币',
      SUM(gold),
      '正常'
    FROM taiwan_cain_2nd.postal;
  \" 2>/dev/null" > $OUTPUT_DIR/postal.txt

echo "[5/8] 交易记录自检..."
sshpass -p 'wp930803' ssh -o StrictHostKeyChecking=no root@192.168.1.204 \
  "docker exec dnf-llnut_dnf-1_1 mysql -u root -p88888888 -e \"
    SELECT 
      '交易总数' as check_item,
      COUNT(*) as value,
      CASE WHEN COUNT(*) > 0 THEN '正常' ELSE '异常' END as status
    FROM taiwan_billing.log_transaction_history
    UNION ALL
    SELECT 
      '交易类型数',
      COUNT(DISTINCT tran_type),
      '正常'
    FROM taiwan_billing.log_transaction_history
    UNION ALL
    SELECT 
      '最早交易',
      MIN(occ_date),
      '正常'
    FROM taiwan_billing.log_transaction_history
    UNION ALL
    SELECT 
      '最新交易',
      MAX(occ_date),
      '正常'
    FROM taiwan_billing.log_transaction_history;
  \" 2>/dev/null" > $OUTPUT_DIR/transactions.txt

echo "[6/8] 贴吧数据自检..."
sshpass -p 'wp930803' ssh -o StrictHostKeyChecking=no root@192.168.1.204 \
  "docker exec dnf-llnut_dnf-1_1 mysql -u root -p88888888 -e \"
    SELECT 
      '帖子总数' as check_item,
      COUNT(*) as value,
      CASE WHEN COUNT(*) > 0 THEN '正常' ELSE '异常' END as status
    FROM dnf_tieba.tieba_posts
    UNION ALL
    SELECT 
      '贴吧种类',
      COUNT(DISTINCT tieba_name),
      '正常'
    FROM dnf_tieba.tieba_posts
    UNION ALL
    SELECT 
      '最新帖子时间',
      MAX(post_time),
      '正常'
    FROM dnf_tieba.tieba_posts;
  \" 2>/dev/null" > $OUTPUT_DIR/tieba.txt

echo "[7/8] 数据一致性检查..."
sshpass -p 'wp930803' ssh -o StrictHostKeyChecking=no root@192.168.1.204 \
  "docker exec dnf-llnut_dnf-1_1 mysql -u root -p88888888 -e \"
    SELECT 
      '角色-物品关联' as check_item,
      COUNT(DISTINCT ui.charac_no) as linked_chars,
      (SELECT COUNT(*) FROM taiwan_cain.charac_info) as total_chars,
      CASE 
        WHEN COUNT(DISTINCT ui.charac_no) > 0 THEN '正常' 
        ELSE '无关联' 
      END as status
    FROM taiwan_cain_2nd.user_items ui
    JOIN taiwan_cain.charac_info ci ON ui.charac_no = ci.m_id;
  \" 2>/dev/null" > $OUTPUT_DIR/consistency.txt

echo "[8/8] 数据库表空间检查..."
sshpass -p 'wp930803' ssh -o StrictHostKeyChecking=no root@192.168.1.204 \
  "docker exec dnf-llnut_dnf-1_1 mysql -u root -p88888888 -e \"
    SELECT 
      TABLE_NAME,
      TABLE_ROWS,
      ROUND(DATA_LENGTH/1024/1024, 2) as data_mb,
      ROUND(INDEX_LENGTH/1024/1024, 2) as index_mb
    FROM information_schema.TABLES 
    WHERE TABLE_SCHEMA IN ('d_taiwan','taiwan_cain','taiwan_cain_2nd','dnf_tieba')
    AND TABLE_ROWS > 0
    ORDER BY TABLE_ROWS DESC LIMIT 10;
  \" 2>/dev/null" > $OUTPUT_DIR/tablespace.txt

echo ""
echo "=== 自检报告 ==="
echo ""
echo "【账号数据】"
cat $OUTPUT_DIR/accounts.txt
echo ""
echo "【角色数据】"
cat $OUTPUT_DIR/characters.txt
echo ""
echo "【物品数据】"
cat $OUTPUT_DIR/items.txt
echo ""
echo "【邮件数据】"
cat $OUTPUT_DIR/postal.txt
echo ""
echo "【交易记录】"
cat $OUTPUT_DIR/transactions.txt
echo ""
echo "【贴吧数据】"
cat $OUTPUT_DIR/tieba.txt
echo ""
echo "【数据一致性】"
cat $OUTPUT_DIR/consistency.txt
echo ""
echo "【数据库表空间】"
cat $OUTPUT_DIR/tablespace.txt
echo ""
echo "=== 自检完成 ==="
echo "报告目录: $OUTPUT_DIR"
