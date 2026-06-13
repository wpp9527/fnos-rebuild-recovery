#!/bin/bash
# DNF 后台管理系统 - 数据自检 + 功能扩展脚本
# 用法: bash dnf-admin-features.sh [check|extend|all]

set -e
TOKEN=***
BASE_URL="http://192.168.1.204:18882"
OUTPUT_DIR="/root/.openclaw/workspace/data/dnf-features-$(date +%Y%m%d)"
mkdir -p $OUTPUT_DIR

echo "=== DNF 后台管理系统功能分析 ==="
echo ""

# 1. 数据自检
check_data_integrity() {
    echo "[1/6] 检查账号数据完整性..."
    sshpass -p 'wp930803' ssh -o StrictHostKeyChecking=no root@192.168.1.204 \
      "docker exec dnf-llnut_dnf-1_1 mysql -u root -p88888888 -e \"
        SELECT 
          COUNT(*) as total_accounts,
          SUM(CASE WHEN admin > 0 THEN 1 ELSE 0 END) as admin_accounts,
          SUM(CASE WHEN VIP != '' THEN 1 ELSE 0 END) as vip_accounts
        FROM d_taiwan.accounts;
      \" 2>/dev/null" > $OUTPUT_DIR/accounts_check.txt
    
    echo "[2/6] 检查角色数据完整性..."
    sshpass -p 'wp930803' ssh -o StrictHostKeyChecking=no root@192.168.1.204 \
      "docker exec dnf-llnut_dnf-1_1 mysql -u root -p88888888 -e \"
        SELECT 
          COUNT(*) as total_chars,
          COUNT(DISTINCT job) as job_types,
          AVG(lev) as avg_level,
          MAX(lev) as max_level,
          SUM(CASE WHEN guild_id > 0 THEN 1 ELSE 0 END) as in_guild,
          SUM(CASE WHEN last_play_time > DATE_SUB(NOW(), INTERVAL 7 DAY) THEN 1 ELSE 0 END) as active_7d,
          SUM(CASE WHEN last_play_time > DATE_SUB(NOW(), INTERVAL 30 DAY) THEN 1 ELSE 0 END) as active_30d
        FROM taiwan_cain.charac_info;
      \" 2>/dev/null" > $OUTPUT_DIR/characters_check.txt
    
    echo "[3/6] 检查物品数据完整性..."
    sshpass -p 'wp930803' ssh -o StrictHostKeyChecking=no root@192.168.1.204 \
      "docker exec dnf-llnut_dnf-1_1 mysql -u root -p88888888 -e \"
        SELECT 
          COUNT(*) as total_items,
          COUNT(DISTINCT charac_no) as chars_with_items,
          COUNT(DISTINCT it_id) as unique_items
        FROM taiwan_cain_2nd.user_items;
      \" 2>/dev/null" > $OUTPUT_DIR/items_check.txt
    
    echo "[4/6] 检查邮件数据完整性..."
    sshpass -p 'wp930803' ssh -o StrictHostKeyChecking=no root@192.168.1.204 \
      "docker exec dnf-llnut_dnf-1_1 mysql -u root -p88888888 -e \"
        SELECT 
          COUNT(*) as total_mail,
          SUM(CASE WHEN delete_flag = 0 THEN 1 ELSE 0 END) as unread,
          SUM(CASE WHEN gold > 0 THEN 1 ELSE 0 END) as with_gold,
          SUM(gold) as total_gold_in_mail
        FROM taiwan_cain_2nd.postal;
      \" 2>/dev/null" > $OUTPUT_DIR/postal_check.txt
    
    echo "[5/6] 检查交易记录完整性..."
    sshpass -p 'wp930803' ssh -o StrictHostKeyChecking=no root@192.168.1.204 \
      "docker exec dnf-llnut_dnf-1_1 mysql -u root -p88888888 -e \"
        SELECT 
          COUNT(*) as total_transactions,
          COUNT(DISTINCT tran_type) as transaction_types,
          MIN(occ_date) as earliest,
          MAX(occ_date) as latest
        FROM taiwan_billing.log_transaction_history;
      \" 2>/dev/null" > $OUTPUT_DIR/transactions_check.txt
    
    echo "[6/6] 检查贴吧数据完整性..."
    sshpass -p 'wp930803' ssh -o StrictHostKeyChecking=no root@192.168.1.204 \
      "docker exec dnf-llnut_dnf-1_1 mysql -u root -p88888888 -e \"
        SELECT 
          COUNT(*) as total_posts,
          COUNT(DISTINCT tieba_name) as forums,
          MIN(post_time) as earliest,
          MAX(post_time) as latest
        FROM dnf_tieba.tieba_posts;
      \" 2>/dev/null" > $OUTPUT_DIR/tieba_check.txt
    
    echo "[OK] 数据自检完成"
}

# 2. 生成扩展功能建议
generate_feature_suggestions() {
    echo ""
    echo "=== 可扩展功能分析 ==="
    echo ""
    
    # 基于现有数据库表生成功能建议
    cat > $OUTPUT_DIR/feature_suggestions.md << 'EOF'
# DNF 后台管理系统 - 功能扩展建议

## 一、数据查询类功能

### 1. 角色详情查询
- **数据源**: `taiwan_cain.charac_info`
- **功能**: 查询角色属性、装备、技能、疲劳值
- **API**: `/api/v1/character/:id/detail`
- **自检**: 对比游戏内实际数据

### 2. 物品查询系统
- **数据源**: `taiwan_cain_web.dnf_item_info` (8.4万条物品)
- **功能**: 物品名称、属性、获取方式、稀有度
- **API**: `/api/v1/item/search?q=xxx`
- **自检**: 随机抽取物品验证属性

### 3. 怪物图鉴
- **数据源**: `taiwan_cain_web.dnf_monster_info` (3148种怪物)
- **功能**: 怪物名称、属性、掉落
- **API**: `/api/v1/monster/search?q=xxx`

### 4. 技能查询
- **数据源**: `taiwan_cain_web.skill_info` (7076个技能)
- **功能**: 技能名称、效果、冷却、消耗
- **API**: `/api/v1/skill/search?q=xxx`

## 二、统计分析类功能

### 5. 服务器状态监控
- **数据源**: `taiwan_cain_log.concurrent_user_status` (2651条)
- **功能**: 实时在线人数、历史趋势
- **API**: `/api/v1/stats/online`
- **自检**: 对比游戏登录界面显示

### 6. 经济系统监控
- **数据源**: `taiwan_cain_2nd.gold` (8.4万条)
- **功能**: 金币流通、交易趋势
- **API**: `/api/v1/stats/economy`

### 7. 副本统计
- **数据源**: `taiwan_cain_log.log_dungeon_entrance_hour` (1.1万条)
- **功能**: 副本进入次数、通关率
- **API**: `/api/v1/stats/dungeon`

### 8. PVP 排行榜
- **数据源**: `d_taiwan.max_count_pvp` (53万条)
- **功能**: PVP 排名、胜率统计
- **API**: `/api/v1/stats/pvp`

## 三、GM 管理类功能

### 9. 封禁管理优化
- **数据源**: `d_taiwan.accounts` + `taiwan_cain.charac_info`
- **功能**: 批量封禁、自动封禁、封禁日志
- **API**: `/api/v1/punish/batch`

### 10. 邮件系统管理
- **数据源**: `taiwan_cain_2nd.postal`
- **功能**: 群发邮件、附件管理、邮件日志
- **API**: `/api/v1/mail/send`

### 11. 活动管理
- **数据源**: `d_taiwan` 活动相关表
- **功能**: 活动配置、奖励发放、活动统计
- **API**: `/api/v1/event/create`

## 四、贴吧 + 游戏联动功能

### 12. 贴吧帖子关联角色
- **数据源**: `dnf_tieba.tieba_posts` + `taiwan_cain.charac_info`
- **功能**: 帖子中提到的角色自动关联
- **API**: `/api/v1/tieba/link/:tid`

### 13. 玩家反馈追踪
- **数据源**: 贴吧帖子 + 游戏日志
- **功能**: 玩家反馈 → 问题定位 → 解决追踪
- **API**: `/api/v1/feedback/track`

### 14. 版本更新监控
- **数据源**: 贴吧帖子 + 游戏数据
- **功能**: 监控版本更新讨论、BUG 反馈
- **API**: `/api/v1/tieba/monitor`

## 五、数据自检方案

### 自动化自检流程
1. **定时采集**: 每小时采集游戏数据
2. **对比验证**: 对比贴吧反馈与实际数据
3. **异常检测**: 检测数据异常（如金币暴涨、等级异常）
4. **报告生成**: 生成自检报告

### 自检脚本
```bash
# 每小时运行
0 * * * * /root/.openclaw/workspace/scripts/dnf-data-collector.sh all
# 每天运行自检
0 0 * * * /root/.openclaw/workspace/scripts/dnf-self-check.sh
```
EOF
    
    echo "[OK] 功能建议已生成: $OUTPUT_DIR/feature_suggestions.md"
}

# 3. 测试现有 API
test_existing_apis() {
    echo ""
    echo "=== 测试现有 API ==="
    
    # 获取 token
    TOKEN=$(sshpass -p 'wp930803' ssh -o StrictHostKeyChecking=no root@192.168.1.204 \
      "curl -s -X POST $BASE_URL/api/v1/auth/login -H 'Content-Type: application/json' -d '{\"username\":\"admin\",\"password\":\"admin123\"}'" | python3 -c "import sys,json; print(json.load(sys.stdin)['token'])" 2>/dev/null)
    
    # 测试各个 API
    for endpoint in account guilds punish; do
        code=$(sshpass -p 'wp930803' ssh -o StrictHostKeyChecking=no root@192.168.1.204 \
          "curl -s -o /dev/null -w '%{http_code}' '$BASE_URL/api/v1/$endpoint' -H 'Authorization: Bearer $TOKEN'" 2>/dev/null)
        echo "  $endpoint: $code"
    done
}

# 主流程
case "${1:-all}" in
    check)
        check_data_integrity
        ;;
    extend)
        generate_feature_suggestions
        ;;
    all)
        check_data_integrity
        generate_feature_suggestions
        test_existing_apis
        ;;
    *)
        echo "用法: $0 [check|extend|all]"
        exit 1
        ;;
esac

echo ""
echo "=== 完成 ==="
echo "输出目录: $OUTPUT_DIR"
cat $OUTPUT_DIR/accounts_check.txt 2>/dev/null
cat $OUTPUT_DIR/characters_check.txt 2>/dev/null
cat $OUTPUT_DIR/items_check.txt 2>/dev/null
cat $OUTPUT_DIR/postal_check.txt 2>/dev/null
cat $OUTPUT_DIR/transactions_check.txt 2>/dev/null
cat $OUTPUT_DIR/tieba_check.txt 2>/dev/null
