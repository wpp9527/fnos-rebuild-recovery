#!/usr/bin/env bash
# 此脚本在 104 MySQL 服务器上执行
# 用于创建新后台只读账号

set -euo pipefail

echo "=== DNF 新后台只读账号创建脚本 ==="
echo ""

# 配置（请修改密码）
READONLY_USER="${READONLY_USER:-dnf_readonly}"
READONLY_PASS="${READONLY_PASS:-CHANGE_ME_TO_SECURE_PASSWORD}"
MYSQL_HOST="${MYSQL_HOST:-127.0.0.1}"
MYSQL_PORT="${MYSQL_PORT:-3306}"
MYSQL_ROOT_USER="${MYSQL_ROOT_USER:-root}"
MYSQL_ROOT_PASS="${MYSQL_ROOT_PASS:-}"

if [ "$READONLY_PASS" = "CHANGE_ME_TO_SECURE_PASSWORD" ]; then
  echo "[error] 请设置 READONLY_PASS 环境变量"
  echo "示例: READONLY_PASS=your_secure_password $0"
  exit 1
fi

if [ -z "$MYSQL_ROOT_PASS" ]; then
  echo "[error] 请设置 MYSQL_ROOT_PASS 环境变量"
  exit 1
fi

echo "将创建只读账号: $READONLY_USER"
echo ""

# SQL 语句
SQL=$(cat <<EOSQL
-- 创建只读用户
CREATE USER IF NOT EXISTS '${READONLY_USER}'@'%' IDENTIFIED BY '${READONLY_PASS}';

-- 授予只读权限
GRANT SELECT ON d_taiwan.* TO '${READONLY_USER}'@'%';
GRANT SELECT ON taiwan_cain.* TO '${READONLY_USER}'@'%';
GRANT SELECT ON taiwan_cain_2nd.* TO '${READONLY_USER}'@'%';
GRANT SELECT ON taiwan_billing.* TO '${READONLY_USER}'@'%';
GRANT SELECT ON taiwan_login.* TO '${READONLY_USER}'@'%';

-- 刷新权限
FLUSH PRIVILEGES;

-- 显示权限
SHOW GRANTS FOR '${READONLY_USER}'@'%';
EOSQL
)

echo "执行 SQL..."
mysql -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_ROOT_USER" -p"$MYSQL_ROOT_PASS" -e "$SQL"

echo ""
echo "✅ 只读账号创建完成"
echo ""
echo "请在新后台服务器上测试连接："
echo "  mysql -u $READONLY_USER -p -h <104_IP> -e 'SELECT COUNT(*) FROM d_taiwan.accounts'"
