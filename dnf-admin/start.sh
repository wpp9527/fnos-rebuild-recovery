#!/bin/bash
# DNF Admin Pro 启动脚本

set -e

# 检查 .env 文件
if [ ! -f .env ]; then
    echo "❌ .env 文件不存在，请先创建"
    exit 1
fi

# 加载环境变量
source .env

# 检查环境变量
if [ -z "$DNF_DB_ROOT_PASSWORD" ]; then
    echo "❌ 请设置 DNF_DB_ROOT_PASSWORD 环境变量"
    exit 1
fi

# 启动服务器
echo "🚀 启动 DNF Admin Pro..."
echo "   端口: $SERVER_PORT"
echo "   数据库: $DB_HOST:$DB_PORT"
echo ""

./dnf-admin-server
