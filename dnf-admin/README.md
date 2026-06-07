# DNF Admin Pro

DNF 游戏后台管理系统 - 支持多区服配置

## 功能特性

- 🔐 JWT 认证
- 👥 账号管理（查询、封禁）
- 🎮 角色管理（查询、物品、在线状态）
- 📮 GM 功能（邮件、金币、解封）
- 🎯 活动管理
- 📦 PVF 管理
- 🖥️ PVE 状态监控
- 🌐 多区服支持

## 快速开始

### 1. 配置环境变量

```bash
cp .env.example .env
# 编辑 .env 文件，填入实际的数据库密码
```

### 2. 配置多区服

编辑 `multi-server/servers.json` 文件：

```json
{
  "servers": [
    {
      "id": "local",
      "name": "本地区",
      "description": "DNF 本地服务器",
      "db_host": "127.0.0.1",
      "db_port": 3306,
      "db_user": "root",
      "db_password": "${DNF_DB_ROOT_PASSWORD}",
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

支持环境变量替换，使用 `${VAR_NAME}` 格式。

### 3. 启动服务

#### 直接运行

```bash
# 编译
cd backend
go build -o ../dnf-admin-server ./cmd/server

# 启动
cd ..
./start.sh
```

#### Docker Compose

```bash
docker-compose up -d
```

### 4. 访问 API

- API 地址: http://localhost:18882
- 默认账号: admin / admin123

## API 接口

### 认证
- `POST /api/v1/auth/login` - 登录

### 区服管理
- `GET /api/v1/servers` - 获取区服列表

### 账号管理
- `GET /api/v1/accounts?server_id=local` - 账号列表
- `GET /api/v1/accounts/:id?server_id=local` - 账号详情

### 角色管理
- `GET /api/v1/characters?server_id=local` - 角色列表
- `GET /api/v1/characters/:id?server_id=local` - 角色详情
- `GET /api/v1/characters/:id/items?server_id=local` - 角色物品
- `GET /api/v1/characters/:id/online?server_id=local` - 在线状态

### GM 功能
- `POST /api/v1/gm/mail?server_id=local` - 发送邮件
- `POST /api/v1/gm/gold?server_id=local` - 发放金币
- `POST /api/v1/gm/ban?server_id=local` - 封禁账号
- `POST /api/v1/gm/unban?server_id=local` - 解封账号

### 活动管理
- `GET /api/v1/activities?server_id=local` - 活动列表
- `POST /api/v1/activities?server_id=local` - 创建活动

### PVF 管理
- `GET /api/v1/pvf/items?server_id=local` - 物品列表
- `POST /api/v1/pvf/import?server_id=local` - 导入 PVF

### PVE 状态
- `GET /api/v1/pve/status?server_id=local` - PVE 状态

## 数据库表

| 数据域 | 数据库 | 主要表 |
|--------|--------|--------|
| 账号 | d_taiwan | accounts |
| 登录 | taiwan_login | - |
| Cain | taiwan_cain | charac_info |
| Cain 二级 | taiwan_cain_2nd | postal |
| 计费 | taiwan_billing | cash_cera |

## 部署说明

### 端口规划

| 服务 | 端口 | 说明 |
|------|------|------|
| DNF Admin Pro | 18882 | 新后台 API |
| Supervisor | 2000 | 管理入口 |
| Game Login | 3000 | 登录器 |
| 旧后台 | 882 | 生产管理 |

### 多区服配置

在 `multi-server/servers.json` 中添加多个区服：

```json
{
  "servers": [
    {
      "id": "server1",
      "name": "一区",
      "db_host": "192.168.1.100",
      "db_port": 3306,
      "db_user": "root",
      "db_password": "password1",
      "databases": { ... }
    },
    {
      "id": "server2",
      "name": "二区",
      "db_host": "192.168.1.101",
      "db_port": 3306,
      "db_user": "root",
      "db_password": "password2",
      "databases": { ... }
    }
  ]
}
```

## 开发说明

### 项目结构

```
dnf-admin/
├── backend/           # Go 后端
│   ├── cmd/          # 入口
│   ├── internal/     # 内部包
│   │   ├── account/  # 账号服务
│   │   ├── character/# 角色服务
│   │   ├── config/   # 配置
│   │   ├── database/ # 数据库
│   │   ├── gm/       # GM 功能
│   │   ├── httpapi/  # HTTP API
│   │   └── pve/      # PVE 状态
│   └── go.mod
├── frontend/         # Vue 前端
├── multi-server/     # 多区服配置
├── deploy/           # 部署配置
└── docs/             # 文档
```

### 编译

```bash
cd backend
go build -o ../dnf-admin-server ./cmd/server
```

### 测试

```bash
./test-api.sh
```

## 环境变量

| 变量名 | 默认值 | 说明 |
|--------|--------|------|
| SERVER_PORT | 18882 | 服务器端口 |
| DB_HOST | 127.0.0.1 | 数据库主机 |
| DB_PORT | 3306 | 数据库端口 |
| DB_USER | root | 数据库用户 |
| DB_PASSWORD | - | 数据库密码 |
| DB_NAME | d_taiwan | 数据库名 |
| JWT_SECRET | dnf-admin-secret-key-change-me | JWT 密钥 |
| SERVER_ID | local | 区服 ID |
| SERVER_NAME | 本地区 | 区服名称 |
| SERVERS_CONFIG | multi-server/servers.json | 多区服配置文件 |

## 注意事项

1. **安全**: 生产环境请修改默认密码和 JWT 密钥
2. **权限**: GM 写操作需要 root 数据库账号
3. **网络**: 确保数据库可从后台服务器访问
4. **备份**: 定期备份数据库

## 许可证

MIT License
