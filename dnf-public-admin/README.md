# DNF Public Admin

新后台公开仓库，用于替代旧后台 `882` 的部分只读查询功能。

## 当前状态

**MVP 阶段：本地可验收，等待真实 104 只读环境接入。**

## 核心原则

1. **不覆盖旧后台 882** - 旧后台仍是生产入口
2. **不创建第二套游戏数据源** - 只读取现有数据库
3. **第一阶段只读 + dry-run** - 写操作需灰度门禁
4. **禁止 root 只读账号** - 必须创建专用只读账号

## 快速开始

### 本地预览（demo 模式）

```bash
cd deploy/examples
docker compose up -d
```

访问：

- 前端：http://127.0.0.1:18880
- API：http://127.0.0.1:18882/api/v1/health

### 生产接入（live-readonly 模式）

参考：`dnf-private-deploy/docs/production-onboarding.md`

## API 端点

### 健康检查

```
GET /api/v1/health
```

### 旧后台基线

```
GET /api/v1/meta/llnut-baseline
```

返回：

```json
{
  "ports": {
    "admin": 882,
    "supervisor": 2000,
    "game_login": 3000
  },
  "databases": {
    "accounts": "d_taiwan",
    "billing": "taiwan_billing",
    "cain": "taiwan_cain"
  }
}
```

### 账号查询（分页）

```
GET /api/v1/accounts?limit=50&offset=0
```

### 角色查询（分页）

```
GET /api/v1/characters?limit=50&offset=0
```

### PVF 搜索

```
GET /api/v1/pvf/items?q=礼盒
```

### PVF 发放预案（dry-run）

```
POST /api/v1/pvf/grant-plan
Content-Type: application/json

{
  "item_id": "10001",
  "character_id": "1",
  "quantity": 1
}
```

返回：

```json
{
  "dry_run": true,
  "plan": {...}
}
```

### 活动开关（dry-run + RBAC）

```
POST /api/v1/activities/native/toggle
Content-Type: application/json
X-Scopes: activity:write

{
  "code": "native-online-gift",
  "enabled": true
}
```

### 审计事件

```
GET /api/v1/audit/events
```

### GM 写操作（全部 403）

```
POST /api/v1/gm/mail/send      -> 403 Forbidden
POST /api/v1/gm/item/send      -> 403 Forbidden
POST /api/v1/gm/currency/grant -> 403 Forbidden
POST /api/v1/gm/account/ban    -> 403 Forbidden
```

## 环境变量

```env
# 应用
APP_NAME=dnf-public-admin
HTTP_ADDR=:8080

# 适配模式
LLNUT_MODE=demo  # demo | live-readonly

# 数据库（仅 live-readonly 模式需要）
LLNUT_MYSQL_HOST=192.168.1.104
LLNUT_MYSQL_PORT=3306
LLNUT_MYSQL_READONLY_USER=dnf_readonly
LLNUT_MYSQL_READONLY_PASSWORD=***
```

## 目录结构

```
backend/
  cmd/server/        # 入口
  internal/
    account/         # 账号服务
    character/       # 角色服务
    activity/        # 活动服务
    pvf/             # PVF 服务
    adapter/llnut/   # 数据库适配
    httpapi/         # HTTP 路由
    audit/           # 审计
    rbac/            # 权限
    config/          # 配置

frontend/
  src/               # 前端源码
  index.html         # 入口页面

deploy/examples/
  docker-compose.yaml
  .env.example
```

## 相关仓库

- `dnf-private-deploy` - 私有部署配置、运维脚本

## 验收清单

见：`docs/acceptance-checklist.md`

## 生产接入清单

见：`dnf-private-deploy/docs/production-onboarding.md`

## 下一阶段：生产环境接入

### 步骤 1：在 104 创建只读账号

```bash
# 在 104 服务器上执行
cd /path/to/dnf-private-deploy

# 设置密码并执行
READONLY_PASS=your_secure_password \
MYSQL_ROOT_PASS=your_root_password \
  scripts/setup-readonly-user.sh
```

### 步骤 2：配置新后台环境变量

```bash
# 创建 env/.env.local
cat > env/.env.local << 'ENV'
LLNUT_MODE=live-readonly
LLNUT_MYSQL_HOST=192.168.1.104
LLNUT_MYSQL_PORT=3306
LLNUT_MYSQL_READONLY_USER=dnf_readonly
LLNUT_MYSQL_READONLY_PASSWORD=your_secure_password
ENV
```

### 步骤 3：验证连接

```bash
source env/.env.local
scripts/verify-readonly-access.sh
```

### 步骤 4：启动新后台

```bash
docker compose -f compose/docker-compose.yaml up -d
```

### 步骤 5：对比数据

```bash
scripts/compare-old-admin.sh
```

详细文档：`docs/production-onboarding.md`
