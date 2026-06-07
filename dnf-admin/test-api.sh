#!/bin/bash
# DNF Admin Pro API 测试脚本

BASE_URL="http://localhost:18882"

echo "🧪 测试 DNF Admin Pro API"
echo ""

# 测试健康检查
echo "1. 测试健康检查..."
curl -s "$BASE_URL/api/v1/health" | jq . 2>/dev/null || echo "健康检查失败"
echo ""

# 测试登录
echo "2. 测试登录..."
TOKEN=$(curl -s -X POST "$BASE_URL/api/v1/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin123"}' | jq -r '.token')

if [ "$TOKEN" = "null" ] || [ -z "$TOKEN" ]; then
    echo "❌ 登录失败"
    exit 1
else
    echo "✅ 登录成功"
fi
echo ""

# 测试获取区服列表
echo "3. 测试获取区服列表..."
curl -s "$BASE_URL/api/v1/servers" \
  -H "Authorization: Bearer $TOKEN" | jq . 2>/dev/null || echo "获取区服列表失败"
echo ""

# 测试获取账号列表
echo "4. 测试获取账号列表..."
curl -s "$BASE_URL/api/v1/accounts?server_id=local&page=1&page_size=10" \
  -H "Authorization: Bearer $TOKEN" | jq . 2>/dev/null || echo "获取账号列表失败"
echo ""

echo "✅ API 测试完成"
