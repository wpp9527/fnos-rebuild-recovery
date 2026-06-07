# API Contract (Phase 1 Draft)

## Base Path

- `/api/v1`

## Endpoints

### `GET /health`

返回服务存活状态。

响应示例：

```json
{
  "status": "ok",
  "service": "dnf-public-admin"
}
```

### `GET /meta/modules`

返回当前后台模块清单，用于前端首页展示与后续能力发现。

响应示例：

```json
{
  "modules": [
    { "key": "auth", "name": "认证与权限", "status": "planned" },
    { "key": "account", "name": "账号查询", "status": "planned" }
  ]
}
```


### `GET /meta/llnut-baseline`

返回旧后台/现网 llnut 兼容基线。该接口用于前端展示与自动化测试，防止新后台偏离旧端口和旧数据库。

响应示例：

```json
{
  "project_name": "dnf-llnut",
  "ports": {
    "admin": 882,
    "supervisor": 2000,
    "game_login": 3000
  },
  "databases": {
    "accounts": "d_taiwan",
    "login": "taiwan_login",
    "cain": "taiwan_cain",
    "cain_2nd": "taiwan_cain_2nd",
    "billing": "taiwan_billing"
  },
  "data_policy": "reuse legacy dnf-console ports and llnut game databases; do not fork or migrate game data by default"
}
```


### `GET /meta/llnut-readonly-plans`

返回 llnut 适配层的只读查询计划。该接口用于明确第一阶段只做账号、角色、计费相关数据的只读检查，不启用任何游戏写操作。

关键约束：

- `accounts` 读取 `d_taiwan.accounts`。
- `characters` 读取 `taiwan_cain` / `taiwan_cain_2nd` 的角色相关表。
- `billing` 第一阶段只读，点券/充值写入必须等审计和权限闭环完成后再开放。


### `POST /meta/llnut-schema/validate`

校验部署侧采集到的 llnut 表结构是否满足新后台只读适配要求。

请求示例：

```json
{
  "tables": {
    "d_taiwan.accounts": ["UID", "accountname", "admin", "parent_uid"]
  }
}
```

成功返回：

```json
{ "status": "ok" }
```

缺少必要字段时返回 `422`，新后台不得继续切到 live 只读模式。


## GM 写操作保护

以下接口已经预留，但在只读阶段固定返回 `403`：

- `POST /gm/mail/send`
- `POST /gm/item/send`
- `POST /gm/currency/grant`
- `POST /gm/account/ban`

启用条件：RBAC、审计日志、旧后台数据对比验证全部通过后，才允许进入灰度写入。


### `POST /activities/native/toggle`

原生活动开关预演接口。当前只返回 `dry-run`，不会写入游戏库或配置文件。

请求示例：

```json
{ "code": "native-online-gift", "enabled": true }
```

响应示例：

```json
{
  "mode": "dry-run",
  "status": "planned",
  "code": "native-online-gift",
  "target_status": "active"
}
```


## PVF 检索与发放预案

### `GET /pvf/items?q=<keyword>`

搜索 PVF 物品索引。当前为 demo 索引，后续接入实际 Script.pvf 解析结果。

### `POST /pvf/grant-plan`

生成 PVF 物品发放预案，固定 `dry-run`，不会实际发放。

请求示例：

```json
{ "item_id": "1001", "character_id": "char-1", "quantity": 1 }
```


### `GET /audit/events`

返回当前进程内审计事件。当前为 MVP 内存记录器，用于验证 dry-run、写保护和后续审计接入点；生产阶段会替换为持久化审计库。


## MVP RBAC Header

MVP 阶段支持 `X-Scopes` 请求头用于接口级权限验证。生产阶段会替换为 JWT/RBAC 中间件。

示例：

```text
X-Scopes: activity:write,audit:read
```

未提供 `X-Scopes` 时保持 demo 兼容；一旦提供，则必须包含目标接口所需 scope。


## 账号/角色分页

`GET /accounts` 与 `GET /characters` 支持 `limit` / `offset` 查询参数。

- 默认 `limit=50`
- 最大 `limit=200`
- `offset` 小于 0 时归零

分页规则与 llnut 只读 SQL 绑定，避免一次性扫全表影响 104。
