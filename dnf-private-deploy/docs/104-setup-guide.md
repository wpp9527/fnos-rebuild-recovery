# 104 环境配置指南

本指南用于在 104 服务器上创建只读数据库账号并验证连接。

## 前提条件

- 104 服务器已运行 MySQL
- 有 MySQL root 或管理权限
- 旧后台 882 正常运行

## 第一步：创建只读账号

在 104 上执行：

```bash
# 登录 MySQL
mysql -u root -p

# 创建只读账号
CREATE USER 'dnf_readonly'@'%' IDENTIFIED BY 'YOUR_SECURE_PASSWORD';

# 授予只读权限
GRANT SELECT ON d_taiwan.* TO 'dnf_readonly'@'%';
GRANT SELECT ON taiwan_cain.* TO 'dnf_readonly'@'%';
GRANT SELECT ON taiwan_cain_2nd.* TO 'dnf_readonly'@'%';
GRANT SELECT ON taiwan_billing.* TO 'dnf_readonly'@'%';
GRANT SELECT ON taiwan_login.* TO 'dnf_readonly'@'%';

# 刷新权限
FLUSH PRIVILEGES;

# 验证
SHOW GRANTS FOR 'dnf_readonly'@'%';
```

## 第二步：验证账号权限

```bash
# 测试只读账号登录
mysql -u dnf_readonly -p -h 127.0.0.1

# 测试 SELECT 权限
USE d_taiwan;
SELECT COUNT(*) FROM accounts;

# 测试无写权限（应该失败）
INSERT INTO accounts (UID, accountname) VALUES (999999, 'test');
-- 应该返回: ERROR 1142 (42000): INSERT command denied
```

## 第三步：检查防火墙

```bash
# 检查 MySQL 端口
netstat -tlnp | grep 3306

# 如果需要开放远程访问
firewall-cmd --add-port=3306/tcp --permanent
firewall-cmd --reload

# 或者修改 MySQL 配置允许远程连接
# /etc/mysql/my.cnf 或 /etc/my.cnf
# bind-address = 0.0.0.0
```

## 第四步：从新后台服务器测试连接

在新后台部署服务器上执行：

```bash
# 测试网络连通性
ping 192.168.1.104

# 测试 MySQL 连接
mysql -u dnf_readonly -p -h 192.168.1.104 -e "SELECT 1"

# 测试数据库访问
mysql -u dnf_readonly -p -h 192.168.1.104 -e "SELECT COUNT(*) as count FROM d_taiwan.accounts"
```

## 第五步：配置新后台环境变量

创建 `env/.env.local`：

```env
# 只读数据库连接
LLNUT_MODE=live-readonly
LLNUT_MYSQL_HOST=192.168.1.104
LLNUT_MYSQL_PORT=3306
LLNUT_MYSQL_READONLY_USER=dnf_readonly
LLNUT_MYSQL_READONLY_PASSWORD=YOUR_SECURE_PASSWORD
```

## 第六步：运行验证脚本

```bash
cd /path/to/dnf-private-deploy

# 加载环境变量
source env/.env.local

# 检查只读连接
scripts/check-readonly-db.sh

# 检查 schema
scripts/schema-pipeline.sh
```

## 安全提醒

1. **禁止使用 root 账号**
2. **只授予 SELECT 权限**
3. **定期轮换密码**
4. **限制 IP 访问（可选）**：
   ```sql
   CREATE USER 'dnf_readonly'@'192.168.1.%' IDENTIFIED BY 'YOUR_SECURE_PASSWORD';
   ```

## 故障排查

### 连接被拒绝

```bash
# 检查 MySQL 是否监听
netstat -tlnp | grep 3306

# 检查用户主机限制
SELECT User, Host FROM mysql.user WHERE User='dnf_readonly';
```

### 权限不足

```bash
# 重新授权
GRANT SELECT ON d_taiwan.* TO 'dnf_readonly'@'%';
FLUSH PRIVILEGES;
```

### 超时

```bash
# 检查防火墙
iptables -L -n | grep 3306
firewall-cmd --list-ports
```
