# DNF 新后台项目落地报告

## 项目概述

**项目目标**：创建新的公开后台系统，用于替代旧后台 `882` 的部分只读查询功能。

**核心原则**：
1. 不覆盖旧后台 882
2. 不创建第二套游戏数据源
3. 第一阶段只读 + dry-run
4. 写操作需灰度门禁

---

## 一、已完成内容

### 1. 代码仓库

| 仓库 | 地址 | 提交数 | 状态 |
|------|------|--------|------|
| dnf-public-admin | https://github.com/wpp9527/dnf-public-admin | 23 | ✅ 已推送 |
| dnf-private-deploy | https://github.com/wpp9527/dnf-private-deploy | 15 | ✅ 已推送 |

### 2. 功能模块

#### dnf-public-admin（公开后台）

| 模块 | 功能 | 状态 |
|------|------|------|
| 健康检查 | `/api/v1/health` | ✅ |
| 旧后台基线 | `/api/v1/meta/llnut-baseline` | ✅ |
| 账号查询 | 分页、只读 | ✅ |
| 角色查询 | 分页、只读 | ✅ |
| PVF 搜索 | 物品搜索 | ✅ |
| PVF 发放预案 | dry-run | ✅ |
| 活动列表 | 活动管理 | ✅ |
| 活动开关 | dry-run + RBAC | ✅ |
| 审计事件 | 内存记录 | ✅ |
| GM 写操作 | 全部 403 | ✅ |
| RBAC | MVP scope 检查 | ✅ |

#### dnf-private-deploy（私有部署）

| 脚本 | 功能 | 状态 |
|------|------|------|
| init.sh | 初始化 | ✅ |
| start.sh | 启动服务 | ✅ |
| stop.sh | 停止服务 | ✅ |
| restart.sh | 重启服务 | ✅ |
| backup.sh | 备份 | ✅ |
| healthcheck.sh | 健康检查 | ✅ |
| schema-inspect.sh | Schema 检查 | ✅ |
| schema-pipeline.sh | Schema 管道 | ✅ |
| check-readonly-db.sh | 只读连接检查 | ✅ |
| verify-readonly-access.sh | 权限验证 | ✅ |
| compare-old-admin.sh | 旧后台对比 | ✅ |
| final-check.sh | 最终集成检查 | ✅ |

### 3. 安全保护

| 保护项 | 实现 |
|--------|------|
| root 用户禁止 | ✅ 脚本拒绝 root 作为只读账号 |
| 写操作禁止 | ✅ GM 接口全部返回 403 |
| dry-run 保护 | ✅ 活动开关、PVF 发放只生成预案 |
| 分页保护 | ✅ 默认 50，最大 200 |
| RBAC | ✅ MVP scope 检查 |

### 4. 文档

| 文档 | 路径 |
|------|------|
| README | dnf-public-admin/README.md |
| API 文档 | dnf-public-admin/docs/api-contract.md |
| 验收清单 | dnf-public-admin/docs/acceptance-checklist.md |
| llnut 适配说明 | dnf-public-admin/docs/llnut-readonly-adapter.md |
| 生产接入清单 | dnf-private-deploy/docs/production-onboarding.md |
| 104 配置指南 | dnf-private-deploy/docs/104-setup-guide.md |
| admin 集成说明 | dnf-private-deploy/docs/admin-integration.md |

---

## 二、验证结果

### 本地验证

```
✅ Go 后端测试：全部通过
✅ 前端检查：结构正确
✅ Docker 构建：成功
✅ 容器运行：健康检查通过
✅ API 端点：全部响应
✅ GM 写保护：返回 403
✅ RBAC 检查：正确拒绝
✅ 分页功能：正确限制
✅ 脚本语法：全部正确
✅ root 保护：正确拒绝
```

### GitHub 推送

```
✅ dnf-public-admin：23 commits 已推送
✅ dnf-private-deploy：15 commits 已推送
```

---

## 三、104 环境状态

**当前状态**：104 虚拟机不可达

**可能原因**：
1. 104 为独立物理机/虚拟机，当前关机
2. 104 在不同网络段
3. 需要网络配置后才能访问

**解决方案**：
1. 确保 104 开机并接入网络
2. 或在 104 可达的服务器上执行部署

---

## 四、部署步骤（104 可达后执行）

### 步骤 1：在 104 创建只读账号

```sql
mysql -u root -p

CREATE USER 'dnf_readonly'@'%' IDENTIFIED BY '安全密码';
GRANT SELECT ON d_taiwan.* TO 'dnf_readonly'@'%';
GRANT SELECT ON taiwan_cain.* TO 'dnf_readonly'@'%';
GRANT SELECT ON taiwan_cain_2nd.* TO 'dnf_readonly'@'%';
GRANT SELECT ON taiwan_billing.* TO 'dnf_readonly'@'%';
GRANT SELECT ON taiwan_login.* TO 'dnf_readonly'@'%';
FLUSH PRIVILEGES;
```

### 步骤 2：Clone 仓库

```bash
git clone https://github.com/wpp9527/dnf-public-admin.git
git clone https://github.com/wpp9527/dnf-private-deploy.git
```

### 步骤 3：配置环境变量

```bash
export LLNUT_MODE=live-readonly
export LLNUT_MYSQL_HOST=192.168.1.104
export LLNUT_MYSQL_PORT=3306
export LLNUT_MYSQL_READONLY_USER=dnf_readonly
export LLNUT_MYSQL_READONLY_PASSWORD=安全密码
```

### 步骤 4：验证连接

```bash
cd dnf-private-deploy
scripts/check-readonly-db.sh
scripts/verify-readonly-access.sh
```

### 步骤 5：启动新后台

```bash
cd ../dnf-public-admin
docker compose -f deploy/examples/docker-compose.yaml up -d
```

### 步骤 6：验证运行

```bash
curl http://127.0.0.1:18882/api/v1/health
curl http://127.0.0.1:18882/api/v1/accounts?limit=5
curl http://127.0.0.1:18882/api/v1/characters?limit=5
```

---

## 五、红线提醒

| 红线 | 状态 |
|------|------|
| 不覆盖旧后台 882 | ✅ 已固化 |
| 不创建第二套数据源 | ✅ 只读连接 |
| 不使用 root 只读账号 | ✅ 脚本拒绝 |
| GM 写操作全部 403 | ✅ 已实现 |
| 活动开关只 dry-run | ✅ 已实现 |
| PVF 发放只 dry-run | ✅ 已实现 |

---

## 六、后续规划

### 第一阶段（当前）
- [x] 代码开发
- [x] 本地验证
- [x] GitHub 推送
- [ ] 104 环境配置
- [ ] 数据对比验证

### 第二阶段
- [ ] 持久化审计库
- [ ] JWT/RBAC 正式中间件
- [ ] 写操作灰度门禁

### 第三阶段
- [ ] 部分写操作开放
- [ ] 新旧后台并行运行
- [ ] 逐步迁移

---

## 七、联系和支持

- 仓库地址：https://github.com/wpp9527/
- 文档位置：各仓库 docs/ 目录
- 问题排查：参考 production-onboarding.md

---

**报告生成时间**：2026-05-04
**报告生成者**：OpenClaw Agent
