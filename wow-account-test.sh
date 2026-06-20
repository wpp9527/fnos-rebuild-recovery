#!/bin/bash
# WoW 魔兽世界账号测试脚本

echo "=== WoW 魔兽世界账号测试 ==="
echo ""

# 检查账号是否存在
echo "1. 检查账号是否存在..."
sshpass -p "wp930803" ssh -o StrictHostKeyChecking=no root@192.168.1.119 "
docker exec mysql8 mysql -u root -p123 acore_auth -e \"SELECT id, username, expansion FROM account WHERE username = '1';\"
"
echo ""

# 检查账号密码设置
echo "2. 检查账号密码设置..."
sshpass -p "wp930803" ssh -o StrictHostKeyChecking=no root@192.168.1.119 "
docker exec mysql8 mysql -u root -p123 acore_auth -e \"SELECT id, username, salt, verifier FROM account WHERE username = '1';\"
"
echo ""

# 检查服务器状态
echo "3. 检查服务器状态..."
sshpass -p "wp930803" ssh -o StrictHostKeyChecking=no root@192.168.1.119 "
systemctl status wow-authserver.service --no-pager | grep -E '(Active|Loaded)' | head -2 && \
systemctl status wow-worldserver.service --no-pager | grep -E '(Active|Loaded)' | head -2
"
echo ""

# 测试 Tailscale 连通性
echo "4. 测试 Tailscale 连通性..."
echo "测试 100.115.4.113:3724..."
timeout 5 bash -c 'echo > /dev/tcp/100.115.4.113/3724' 2>/dev/null && echo "3724 端口可达 ✓" || echo "3724 端口不可达 ✗"

echo "测试 100.115.4.113:8085..."
timeout 5 bash -c 'echo > /dev/tcp/100.115.4.113/8085' 2>/dev/null && echo "8085 端口可达 ✓" || echo "8085 端口不可达 ✗"
echo ""

echo "=== 测试完成 ==="
echo ""
echo "账号信息："
echo "- 账号: 1"
echo "- 密码: 1"
echo "- 服务器 Tailscale IP: 100.115.4.113"
echo "- 游戏版本: 3.3.5a (12340)"
echo ""
echo "请在 WoW 客户端中配置："
echo "1. 编辑 realmlist.wtf 文件"
echo "2. 设置为: set realmlist 100.115.4.113"
echo "3. 启动游戏并使用账号 1 密码 1 登录"
