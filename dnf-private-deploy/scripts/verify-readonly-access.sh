#!/usr/bin/env bash
# 验证只读账号权限

set -euo pipefail

echo "=== 验证只读账号权限 ==="
echo ""

# 检查环境变量
if [ -z "${LLNUT_MYSQL_HOST:-}" ]; then
  echo "[error] 请设置 LLNUT_MYSQL_HOST"
  exit 1
fi

if [ -z "${LLNUT_MYSQL_READONLY_USER:-}" ]; then
  echo "[error] 请设置 LLNUT_MYSQL_READONLY_USER"
  exit 1
fi

HOST="${LLNUT_MYSQL_HOST}"
PORT="${LLNUT_MYSQL_PORT:-3306}"
USER="${LLNUT_MYSQL_READONLY_USER}"
PASS="${LLNUT_MYSQL_READONLY_PASSWORD:-}"

echo "连接信息:"
echo "  Host: $HOST:$PORT"
echo "  User: $USER"
echo ""

# 测试连接
echo "1. 测试连接..."
if mysql -h "$HOST" -P "$PORT" -u "$USER" -p"$PASS" -e "SELECT 1" >/dev/null 2>&1; then
  echo "  ✅ 连接成功"
else
  echo "  ❌ 连接失败"
  exit 1
fi

# 测试数据库访问
echo ""
echo "2. 测试数据库访问..."
for db in d_taiwan taiwan_cain taiwan_billing taiwan_login; do
  count=$(mysql -h "$HOST" -P "$PORT" -u "$USER" -p"$PASS" -N -e "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='$db'" 2>/dev/null || echo "0")
  if [ "$count" -gt 0 ]; then
    echo "  ✅ $db: $count 张表可访问"
  else
    echo "  ⚠️  $db: 无法访问或无表"
  fi
done

# 测试账号数量
echo ""
echo "3. 测试账号表..."
account_count=$(mysql -h "$HOST" -P "$PORT" -u "$USER" -p"$PASS" -N -e "SELECT COUNT(*) FROM d_taiwan.accounts" 2>/dev/null || echo "无法获取")
echo "  账号数量: $account_count"

# 测试角色数量
echo ""
echo "4. 测试角色表..."
char_count=$(mysql -h "$HOST" -P "$PORT" -u "$USER" -p"$PASS" -N -e "SELECT COUNT(*) FROM taiwan_cain.charac_info" 2>/dev/null || echo "无法获取")
echo "  角色数量: $char_count"

# 测试只读限制
echo ""
echo "5. 测试只读限制..."
if mysql -h "$HOST" -P "$PORT" -u "$USER" -p"$PASS" -e "INSERT INTO d_taiwan.accounts (UID) VALUES (999999999)" 2>&1 | grep -q "denied"; then
  echo "  ✅ 写操作被正确拒绝"
else
  echo "  ❌ 写操作未被拒绝（权限配置有问题）"
fi

echo ""
echo "=== 验证完成 ==="
