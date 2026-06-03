#!/bin/bash
# DNF Admin Pro 启动脚本

echo "🚀 启动 DNF Admin Pro..."

# 检查 MySQL 是否运行
if ! docker ps | grep -q dnf-mysql; then
    echo "启动 MySQL..."
    docker run -d \
      --name dnf-mysql \
      -e MYSQL_ROOT_PASSWORD=dnf_root_2026 \
      -e MYSQL_DATABASE=dnf_service \
      -e MYSQL_USER=dnf_admin \
      -e MYSQL_PASSWORD=dnf_admin_2026 \
      -v $(pwd)/../deploy/init.sql:/docker-entrypoint-initdb.d/init.sql:ro \
      -v $(pwd)/../data/mysql:/var/lib/mysql \
      -p 3307:3306 \
      --restart unless-stopped \
      mysql:5.7
    echo "等待 MySQL 启动..."
    sleep 30
fi

# 检查 Redis 是否运行
if ! docker ps | grep -q dnf-redis; then
    echo "启动 Redis..."
    docker run -d \
      --name dnf-redis \
      -v $(pwd)/../data/redis:/data \
      -p 6380:6379 \
      --restart unless-stopped \
      redis:7-alpine
fi

# 启动 PVF 服务
echo "启动 PVF 服务..."
cd $(pwd)/../pvf-service
nohup python app.py > /tmp/pvf-service.log 2>&1 &

# 启动后端服务
echo "启动后端服务..."
cd $(pwd)/..
export DB_HOST=127.0.0.1
export DB_PORT=3307
export DB_NAME=dnf_service
export DB_USER=dnf_admin
export DB_PASSWORD=dnf_admin_2026
export JWT_SECRET=dnf-admin-jwt-secret-key-2026
export PVF_SERVICE=http://127.0.0.1:5000
nohup ./dnf-admin-server > /tmp/backend.log 2>&1 &

echo "✅ 服务启动完成"
echo ""
echo "访问地址:"
echo "  前端: http://localhost:882"
echo "  API: http://localhost:8080"
echo "  PVF: http://localhost:5000"
