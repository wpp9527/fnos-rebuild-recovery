#!/bin/bash
# DNF Admin API v3.0 完整启动脚本
# 启动 API 服务器 + Web 服务器

cd "$(dirname "$0")"

echo "=== 启动 DNF Admin API v3.0 完整服务 ==="

# 1. 检查并创建 SSH 隧道
if ! nc -z 127.0.0.1 3307 2>/dev/null; then
    echo "[*] 创建 SSH 隧道..."
    sshpass -p 'wp930803' ssh -o StrictHostKeyChecking=no -f -N -L 3307:172.18.0.2:3306 root@192.168.1.204
    sleep 2
fi

# 2. 停止旧进程
pkill -f "python3.*api_server.py" 2>/dev/null || true
pkill -f "python3.*web_server.py" 2>/dev/null || true
sleep 1

# 3. 启动 API 服务器 (端口 18883)
echo "[*] 启动 API 服务器 (端口 18883)..."
nohup python3 api_server.py > /tmp/dnf-admin-api.log 2>&1 &
API_PID=$!
sleep 2

# 4. 启动 Web 服务器 (端口 18884)
echo "[*] 启动 Web 服务器 (端口 18884)..."
nohup python3 web_server.py > /tmp/dnf-admin-web.log 2>&1 &
WEB_PID=$!
sleep 2

# 5. 验证
echo ""
echo "=== 服务状态 ==="

if curl -s http://localhost:18883/api/v2/health > /dev/null 2>&1; then
    echo "[OK] API 服务器运行中 (PID: $API_PID)"
else
    echo "[ERR] API 服务器启动失败"
fi

if curl -s http://localhost:18884/api/v2/health > /dev/null 2>&1; then
    echo "[OK] Web 服务器运行中 (PID: $WEB_PID)"
else
    echo "[ERR] Web 服务器启动失败"
fi

echo ""
echo "=== 访问地址 ==="
echo "API 服务器: http://192.168.1.212:18883/api/v2/"
echo "Web 管理后台: http://192.168.1.212:18884"
echo ""
echo "=== 启动完成 ==="
