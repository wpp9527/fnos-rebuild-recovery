#!/bin/bash
# DNF Admin API v3.0 后台启动脚本

cd "$(dirname "$0")"

# 检查并创建 SSH 隧道
if ! nc -z 127.0.0.1 3307 2>/dev/null; then
    sshpass -p 'wp930803' ssh -o StrictHostKeyChecking=no -f -N -L 3307:172.18.0.2:3306 root@192.168.1.204
    sleep 2
fi

# 停止旧进程
pkill -f "python3.*api_server.py" 2>/dev/null || true
sleep 1

# 启动
nohup python3 api_server.py > /tmp/dnf-admin-api.log 2>&1 &

echo "DNF Admin API v3.0 已启动 (PID: $!)"
echo "访问: http://localhost:18883/api/v2/"
