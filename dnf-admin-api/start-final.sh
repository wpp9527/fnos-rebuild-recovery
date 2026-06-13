#!/bin/bash
# DNF Admin API v3.0 最终启动脚本
# 确保所有服务稳定运行

cd "$(dirname "$0")"

echo "=== DNF Admin API v3.0 启动脚本 ==="

# 1. 检查 SSH 隧道
echo "[1/3] 检查 SSH 隧道..."
if ! nc -z 127.0.0.1 3307 2>/dev/null; then
    echo "  [*] 创建 SSH 隧道..."
    sshpass -p 'wp930803' ssh -o StrictHostKeyChecking=no -f -N -L 3307:172.18.0.2:3306 root@192.168.1.204
    sleep 2
fi
echo "  [OK] SSH 隧道就绪"

# 2. 停止旧进程
echo "[2/3] 停止旧进程..."
pkill -f "python3.*api_server.py" 2>/dev/null || true
pkill -f "python3.*web_server" 2>/dev/null || true
sleep 2

# 3. 启动服务
echo "[3/3] 启动服务..."

# 启动 API 服务器
echo "  [*] 启动 API 服务器 (端口 18883)..."
nohup python3 api_server.py > /tmp/dnf-admin-api.log 2>&1 &
API_PID=$!
sleep 3

# 验证 API 服务器
if curl -s http://localhost:18883/api/v2/health > /dev/null 2>&1; then
    echo "  [OK] API 服务器运行中 (PID: $API_PID)"
else
    echo "  [ERR] API 服务器启动失败"
    exit 1
fi

# 启动 Web 服务器
echo "  [*] 启动 Web 服务器 (端口 18884)..."
nohup python3 web_server_v3.py > /tmp/dnf-admin-web.log 2>&1 &
WEB_PID=$!
sleep 3

# 验证 Web 服务器
if curl -s http://localhost:18884/api/v2/health > /dev/null 2>&1; then
    echo "  [OK] Web 服务器运行中 (PID: $WEB_PID)"
else
    echo "  [ERR] Web 服务器启动失败"
fi

echo ""
echo "=== 启动完成 ==="
echo ""
echo "🎮 DNF 后台管理系统 v3.0"
echo ""
echo "访问地址:"
echo "  • Web 管理后台: http://192.168.1.212:18884"
echo "  • API 服务器:   http://192.168.1.212:18883/api/v2/"
echo ""
echo "功能列表:"
echo "  ✅ 角色查询  ✅ 账号查询  ✅ 物品查询  ✅ 怪物图鉴"
echo "  ✅ 技能查询  ✅ 公会管理  ✅ 封禁管理  ✅ 邮件系统"
echo "  ✅ 统计分析  ✅ 贴吧联动  ✅ 反馈追踪  ✅ 版本监控"
echo "  ✅ 数据自检  ✅ 服务器监控"
echo ""
