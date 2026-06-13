#!/bin/bash
# DNF Admin API v3.0 一键启动脚本
# 功能：启动 API 服务器 + Web 服务器 + SSH 隧道

cd "$(dirname "$0")"

echo "=== DNF Admin API v3.0 启动脚本 ==="
echo ""

# 1. 检查并创建 SSH 隧道
echo "[1/4] 检查 SSH 隧道..."
if ! nc -z 127.0.0.1 3307 2>/dev/null; then
    echo "  [*] 创建 SSH 隧道到 192.168.1.204:3306..."
    sshpass -p 'wp930803' ssh -o StrictHostKeyChecking=no -f -N -L 3307:172.18.0.2:3306 root@192.168.1.204
    sleep 2
fi
echo "  [OK] SSH 隧道就绪"

# 2. 停止旧进程
echo "[2/4] 停止旧进程..."
pkill -f "python3.*api_server.py" 2>/dev/null || true
pkill -f "python3.*web_server" 2>/dev/null || true
sleep 1

# 3. 启动 API 服务器
echo "[3/4] 启动 API 服务器 (端口 18883)..."
nohup python3 api_server.py > /tmp/dnf-admin-api.log 2>&1 &
API_PID=$!
sleep 2

if curl -s http://localhost:18883/api/v2/health > /dev/null 2>&1; then
    echo "  [OK] API 服务器运行中 (PID: $API_PID)"
else
    echo "  [ERR] API 服务器启动失败"
    exit 1
fi

# 4. 启动 Web 服务器
echo "[4/4] 启动 Web 服务器 (端口 18884)..."
nohup python3 web_server_v3.py > /tmp/dnf-admin-web.log 2>&1 &
WEB_PID=$!
sleep 2

if curl -s http://localhost:18884/api/v2/health > /dev/null 2>&1; then
    echo "  [OK] Web 服务器运行中 (PID: $WEB_PID)"
else
    echo "  [ERR] Web 服务器启动失败"
fi

echo ""
echo "=== 启动完成 ==="
echo ""
echo "📊 DNF 后台管理系统 v3.0"
echo ""
echo "访问地址:"
echo "  • Web 管理后台: http://192.168.1.212:18884"
echo "  • API 服务器:   http://192.168.1.212:18883/api/v2/"
echo "  • 原后台:       http://192.168.1.204:18882"
echo ""
echo "功能列表:"
echo "  1. 角色查询  2. 物品查询  3. 怪物图鉴  4. 技能查询"
echo "  5. 服务器监控 6. 经济监控  7. 副本统计  8. PVP排行"
echo "  9. 封禁管理  10. 邮件系统 11. 活动管理  12. 贴吧联动"
echo "  13. 反馈追踪 14. 版本监控 15. 数据自检"
echo ""
echo "日志文件:"
echo "  • API: /tmp/dnf-admin-api.log"
echo "  • Web: /tmp/dnf-admin-web.log"
echo ""
