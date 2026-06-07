# 生产环境接入清单

本清单用于在真实 104 环境上线新后台前的准备和验收。

## 前置条件

- [ ] 旧后台 `882` 仍在运行
- [ ] 旧后台可正常访问
- [ ] 有 104 数据库的 root 或管理权限用于创建只读账号
- [ ] 已确认当前 OpenClaw 实例路径：`/opt/fnos-media/services/openclaw/home/.openclaw`

## 第一步：创建只读数据库账号

在 104 MySQL 上执行：

```sql
CREATE USER 'dnf_readonly'@'%' IDENTIFIED BY 'YOUR_SECURE_PASSWORD';
GRANT SELECT ON d_taiwan.* TO 'dnf_readonly'@'%';
GRANT SELECT ON taiwan_cain.* TO 'dnf_readonly'@'%';
GRANT SELECT ON taiwan_billing.* TO 'dnf_readonly'@'%';
GRANT SELECT ON taiwan_login.* TO 'dnf_readonly'@'%';
FLUSH PRIVILEGES;
```

**禁止事项：**

- 禁止使用 root 作为只读账号
- 禁止授予 INSERT/UPDATE/DELETE 权限
- 禁止授予 DROP/ALTER/CREATE 权限

## 第二步：配置环境变量

在 `env/.env.local` 中添加：

```env
# 新后台适配模式
LLNUT_MODE=demo

# 只读数据库连接（生产环境填写真实值）
LLNUT_MYSQL_HOST=192.168.1.104
LLNUT_MYSQL_PORT=3306
LLNUT_MYSQL_READONLY_USER=dnf_readonly
LLNUT_MYSQL_READONLY_PASSWORD=YOUR_SECURE_PASSWORD
```

**重要：** `LLNUT_MODE` 初始保持 `demo`，待验证通过后再改为 `live-readonly`。

## 第三步：验证只读连接

```bash
source env/.env.local
scripts/check-readonly-db.sh
```

预期输出：

```
[ok] read-only database connection successful
```

## 第四步：运行 schema 管道

```bash
# 确保 demo 模式新后台已启动
docker compose -f compose/docker-compose.yaml up -d

# 运行 schema 校验
scripts/schema-pipeline.sh
```

预期输出：

```
[ok] schema pipeline passed
```

## 第五步：对比新旧后台数据

### 账号数量对比

```bash
# 旧后台
curl http://127.0.0.1:882/api/accounts/count

# 新后台（demo 模式先用假数据验证接口）
curl http://127.0.0.1:18882/api/v1/accounts?limit=1
```

### 角色数量对比

```bash
# 旧后台
curl http://127.0.0.1:882/api/characters/count

# 新后台
curl http://127.0.0.1:18882/api/v1/characters?limit=1
```

## 第六步：切换到 live-readonly 模式

确认以上验证通过后：

1. 修改 `env/.env.local`：

```env
LLNUT_MODE=live-readonly
```

2. 重启新后台：

```bash
docker compose -f compose/docker-compose.yaml restart
```

3. 再次验证数据对比

## 第七步：验收确认

- [ ] 只读账号已创建且权限正确
- [ ] schema 校验通过
- [ ] 新后台可连接真实数据库
- [ ] 账号数量与旧后台一致
- [ ] 角色数量与旧后台一致
- [ ] GM 写操作仍返回 403
- [ ] 活动开关仍为 dry-run
- [ ] PVF 发放仍为 dry-run
- [ ] 审计事件正常记录

## 红线提醒

1. **不覆盖旧后台 882**
2. **不创建第二套游戏数据源**
3. **不使用 root 作为只读账号**
4. **GM 写操作当前全部 403**
5. **活动开关当前只 dry-run**
6. **PVF 发放当前只 dry-run**

## 回滚方案

如发现问题：

1. 立即将 `LLNUT_MODE` 改回 `demo`
2. 重启新后台
3. 排查问题后再重新切换

## 下阶段：写操作灰度

写操作开放前必须完成：

- [ ] 持久化审计库
- [ ] JWT/RBAC 正式中间件
- [ ] 写操作二次确认机制
- [ ] 旧后台数据对比回归测试
- [ ] 备份/回滚脚本验证
- [ ] 灰度开关配置
