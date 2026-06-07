# DNF Admin Pro - 多区服配置指南

## 配置文件说明

### servers.json

配置文件位于 `multi-server/servers.json`，用于配置多个区服的数据库连接。

**配置格式：**

```json
{
  "servers": [
    {
      "id": "server1",
      "name": "一区",
      "description": "主服务器",
      "db_host": "192.168.1.104",
      "db_port": 3300,
      "db_user": "dnf_readonly",
      "db_password": "YOUR_PASSWORD",
      "databases": {
        "accounts": "d_taiwan",
        "cain": "taiwan_cain",
        "cain_2nd": "taiwan_cain_2nd",
        "billing": "taiwan_billing",
        "login": "taiwan_login"
      }
    }
  ]
}
```

### 字段说明

| 字段 | 说明 |
|------|------|
| `id` | 区服唯一标识符 |
| `name` | 区服显示名称 |
| `description` | 区服描述 |
| `db_host` | 数据库主机地址 |
| `db_port` | 数据库端口 |
| `db_user` | 数据库用户名 |
| `db_password` | 数据库密码 |
| `databases` | 数据库名称映射 |

### 数据库名称映射

DNF 服务端使用多个数据库，需要正确配置映射关系：

| 键名 | 说明 | 默认值 |
|------|------|--------|
| `accounts` | 账号数据库 | `d_taiwan` |
| `cain` | 角色数据库 | `taiwan_cain` |
| `cain_2nd` | 扩展数据（邮件等） | `taiwan_cain_2nd` |
| `billing` | 计费数据库 | `taiwan_billing` |
| `login` | 登录数据库 | `taiwan_login` |

## 使用步骤

### 1. 配置区服

编辑 `multi-server/servers.json`，添加你的区服配置。

### 2. 启动服务

```bash
# 使用 Docker Compose
docker compose up -d

# 或直接运行
./dnf-admin-server
```

### 3. 切换区服

在前端界面右上角选择区服，所有操作将针对选中的区服执行。

## 数据库权限要求

### 只读账号（推荐）

```sql
CREATE USER 'dnf_readonly'@'%' IDENTIFIED BY 'YOUR_PASSWORD';
GRANT SELECT ON d_taiwan.* TO 'dnf_readonly'@'%';
GRANT SELECT ON taiwan_cain.* TO 'dnf_readonly'@'%';
GRANT SELECT ON taiwan_cain_2nd.* TO 'dnf_readonly'@'%';
GRANT SELECT ON taiwan_billing.* TO 'dnf_readonly'@'%';
GRANT SELECT ON taiwan_login.* TO 'dnf_readonly'@'%';
FLUSH PRIVILEGES;
```

### 读写账号（GM 操作需要）

```sql
CREATE USER 'dnf_admin'@'%' IDENTIFIED BY 'YOUR_PASSWORD';
GRANT SELECT, INSERT, UPDATE, DELETE ON d_taiwan.* TO 'dnf_admin'@'%';
GRANT SELECT, INSERT, UPDATE, DELETE ON taiwan_cain.* TO 'dnf_admin'@'%';
GRANT SELECT, INSERT, UPDATE, DELETE ON taiwan_cain_2nd.* TO 'dnf_admin'@'%';
GRANT SELECT, INSERT, UPDATE, DELETE ON taiwan_billing.* TO 'dnf_admin'@'%';
GRANT SELECT ON taiwan_login.* TO 'dnf_admin'@'%';
FLUSH PRIVILEGES;
```

## 安全建议

1. **不要使用 root 账号**
2. **限制数据库用户权限**
3. **使用强密码**
4. **限制 IP 访问**（可选）：
   ```sql
   CREATE USER 'dnf_readonly'@'192.168.1.%' IDENTIFIED BY 'YOUR_PASSWORD';
   ```

## 故障排查

### 连接失败

1. 检查数据库是否运行
2. 检查防火墙设置
3. 检查用户权限
4. 检查网络连通性

### 查询超时

1. 检查数据库负载
2. 优化查询语句
3. 增加连接超时时间
