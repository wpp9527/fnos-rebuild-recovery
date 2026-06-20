#!/bin/bash
# WoW 魔兽世界 Tailscale 连接测试脚本

echo "=== WoW 魔兽世界 Tailscale 连接测试 ==="
echo ""

# 检查 Tailscale 状态
echo "1. 检查 Tailscale 状态..."
tailscale status 2>&1 | head -10
echo ""

# 检查 Tailscale IP
echo "2. 检查 Tailscale IP..."
tailscale ip -4 2>&1
echo ""

# 测试连通性
echo "3. 测试连通性..."
echo "测试 100.115.4.113:3724..."
timeout 5 bash -c 'echo > /dev/tcp/100.115.4.113/3724' 2>/dev/null && echo "3724 端口可达 ✓" || echo "3724 端口不可达 ✗"

echo "测试 100.115.4.113:8085..."
timeout 5 bash -c 'echo > /dev/tcp/100.115.4.113/8085' 2>/dev/null && echo "8085 端口可达 ✓" || echo "8085 端口不可达 ✗"
echo ""

# 检查 WoW 服务端状态
echo "4. 检查 WoW 服务端状态..."
sshpass -p "wp930803" ssh -o StrictHostKeyChecking=no root@192.168.1.119 "
systemctl status wow-authserver.service --no-pager | grep -E '(Active|Loaded)' | head -2 && \
systemctl status wow-worldserver.service --no-pager | grep -E '(Active|Loaded)' | head -2
"
echo ""

# 检查 realmlist 配置
echo "5. 检查 realmlist 配置..."
sshpass -p "wp930803" ssh -o StrictHostKeyChecking=no root@192.168.1.119 "
docker exec mysql8 mysql -u root -p123 acore_auth -e 'SELECT * FROM realmlist;'
"
echo ""

echo "=== 测试完成 ==="
echo ""
echo "如果所有测试都通过，你可以在国外设备上安装 Tailscale 并连接到 WoW 服务器。"
echo "详细步骤请参考 wow-tailscale-guide.md 文件。"
