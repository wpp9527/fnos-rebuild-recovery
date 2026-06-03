# DNF Admin Pro - 整合设计文档

## 项目概述

基于现有 dnf-public-admin (Go) 扩展，整合 Zageku/DNF_pvf_python 的 PVF 解析能力，
构建一个完整的 DNF 游戏管理后台，支持 GM 管理、PVF 解析、PVE 控制。

## 技术架构

```
┌─────────────────────────────────────────────────────┐
│                   Docker Compose                    │
│  ┌─────────────────────────────────────────────┐   │
│  │              Nginx (反代 + 前端)              │   │
│  │              Port: 80/443                    │   │
│  └─────────────────┬───────────────────────────┘   │
│                    │                                │
│  ┌─────────────────▼───────────────────────────┐   │
│  │           Go 主服务 (Port: 8080)             │   │
│  │  ┌─────────┬──────────┬──────────┬────────┐ │   │
│  │  │  认证   │  账号    │  角色    │  审计  │ │   │
│  │  │  Auth   │ Account  │ Character│ Audit  │ │   │
│  │  └─────────┴──────────┴──────────┴────────┘ │   │
│  │  ┌─────────┬──────────┬──────────┬────────┐ │   │
│  │  │   GM    │  活动    │   PVF    │  PVE   │ │   │
│  │  │  操作   │  管理    │  解析    │  连接  │ │   │
│  │  └─────────┴──────────┴──────────┴────────┘ │   │
│  └─────────────────┬───────────────────────────┘   │
│                    │ HTTP                           │
│  ┌─────────────────▼───────────────────────────┐   │
│  │        Python PVF 服务 (Port: 5000)         │   │
│  │  ┌──────────┬──────────┬──────────────────┐ │   │
│  │  │ PVF解析  │ 缓存管理 │   物品搜索       │ │   │
│  │  └──────────┴──────────┴──────────────────┘ │   │
│  └─────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────┘
```

## 核心功能模块

### 1. 认证与权限 (auth)
- 用户名密码登录
- JWT Token 认证
- RBAC 权限控制
- 登录日志

### 2. 账号管理 (account)
- 账号查询（UID/用户名）
- 账号状态（在线/封禁）
- 充值记录查询
- 登录记录查询

### 3. 角色管理 (character)
- 角色列表查询
- 角色详细信息
- 角色属性查看
- 在线角色监控

### 4. GM 操作 (gm) - 核心
- **邮件系统**
  - 发送邮件（文字+物品+金币）
  - 群发邮件
  - 邮件模板
- **物品操作**
  - 发送物品（装备/消耗品/材料）
  - 物品搜索（从 PVF 缓存）
  - 批量发送
- **货币操作**
  - 充值金币
  - 充值点券/代币
  - 查询余额
- **角色操作**
  - 设置等级
  - 重置疲劳
  - 解锁背包
- **封号管理**
  - 封号/解封
  - 封号查询
  - 封号原因记录

### 5. 活动管理 (activity)
- 活动列表查询
- 启动/关闭活动
- 活动日志
- 定时活动

### 6. PVF 解析 (pvf) - 核心
- PVF 文件加载
- 物品数据解析
- 装备属性解析
- 技能数据解析
- Web 端搜索界面
- 实时解析（无需桌面环境）

### 7. PVE 连接 (pve)
- SSH 连接管理
- PVE API 连接
- 服务器状态查询
- 服务启停控制
- 文件管理

## API 设计

### 认证
```
POST /api/v1/auth/login     - 登录
POST /api/v1/auth/logout    - 登出
GET  /api/v1/auth/me        - 当前用户
```

### 账号
```
GET  /api/v1/accounts/search?q=xxx     - 搜索账号
GET  /api/v1/accounts/:uid             - 账号详情
GET  /api/v1/accounts/:uid/characters  - 账号下角色
```

### 角色
```
GET  /api/v1/characters/:cNo           - 角色详情
GET  /api/v1/characters/:cNo/items     - 角色物品
GET  /api/v1/characters/online         - 在线角色
```

### GM 操作
```
POST /api/v1/gm/mail                   - 发送邮件
POST /api/v1/gm/mail/group             - 群发邮件
POST /api/v1/gm/item                   - 发送物品
POST /api/v1/gm/gold                   - 充值金币
POST /api/v1/gm/cera                   - 充值点券
POST /api/v1/gm/character/level        - 设置等级
POST /api/v1/gm/character/fatigue      - 重置疲劳
POST /api/v1/gm/account/ban            - 封号
POST /api/v1/gm/account/unban          - 解封
```

### 活动管理
```
GET  /api/v1/activities                - 活动列表
POST /api/v1/activities/:id/start      - 启动活动
POST /api/v1/activities/:id/stop       - 关闭活动
GET  /api/v1/activities/logs           - 活动日志
```

### PVF 解析
```
GET  /api/v1/pvf/items?q=xxx           - 搜索物品
GET  /api/v1/pvf/items/:id             - 物品详情
GET  /api/v1/pvf/equipments?q=xxx      - 搜索装备
GET  /api/v1/pvf/skills?q=xxx          - 搜索技能
GET  /api/v1/pvf/stats                 - PVF 统计
POST /api/v1/pvf/reload                - 重新加载
```

### PVE 管理
```
GET  /api/v1/pve/status                - 服务器状态
POST /api/v1/pve/service/:name/start   - 启动服务
POST /api/v1/pve/service/:name/stop    - 停止服务
GET  /api/v1/pve/files?path=xxx        - 文件列表
POST /api/v1/pve/exec                  - 执行命令
```

## 部署架构

```yaml
# docker-compose.yml
version: '3.8'
services:
  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
    volumes:
      - ./frontend/dist:/usr/share/nginx/html
      - ./deploy/nginx.conf:/etc/nginx/conf.d/default.conf
    depends_on:
      - backend

  backend:
    build: ./backend
    environment:
      - DB_HOST=mysql
      - DB_PORT=3306
      - DB_NAME=dnf_service
      - DB_USER=readonly
      - DB_PASS=***
      - PVF_SERVICE=http://pvf:5000
      - JWT_SECRET=***
    depends_on:
      - mysql
      - pvf

  pvf:
    build: ./pvf-service
    volumes:
      - ./data/pvf:/data/pvf
    ports:
      - "5000:5000"

  mysql:
    image: mysql:5.7
    environment:
      - MYSQL_ROOT_PASSWORD=***
      - MYSQL_DATABASE=dnf_service
    volumes:
      - ./data/mysql:/var/lib/mysql
```

## 安全设计

1. **只读默认** - 查询操作走只读账号
2. **写操作审计** - 所有 GM 操作记录日志
3. **权限分级** - 查看/操作/管理三级权限
4. **操作确认** - 危险操作需二次确认
5. **IP 白名单** - 可选的 IP 限制

## 实现阶段

### Phase 1: 基础框架 (2小时)
- Go 项目结构
- 认证模块
- 数据库连接
- 基础路由

### Phase 2: 核心功能 (4小时)
- PVF 解析服务
- 账号/角色查询
- GM 操作 API
- 活动管理

### Phase 3: 前端界面 (3小时)
- 登录页面
- 仪表盘
- 账号管理页
- GM 操作页
- PVF 搜索页
- 活动管理页

### Phase 4: PVE 集成 (2小时)
- SSH 连接
- PVE API
- 服务管理

### Phase 5: 测试部署 (1小时)
- 单元测试
- 集成测试
- Docker 部署
