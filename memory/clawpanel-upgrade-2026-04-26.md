# ClawPanel 升级报告

## 升级信息

| 项目 | 升级前 | 升级后 |
|------|--------|--------|
| **版本** | 0.13.4 | **0.14.0** |
| **发布日期** | - | 2026-04-25 |
| **部署方式** | Docker Compose | Docker Compose (静态模式) |

---

## 升级过程

### 1. 下载
- 使用 gh-proxy.com 代理加速下载
- 下载地址: `https://github.com/qingchencloud/clawpanel/releases/download/v0.14.0/web-0.14.0.zip`
- 文件大小: 2.4M

### 2. 部署方式
- 预编译包只包含 dist 目录
- 使用 nginx:alpine 提供静态文件服务
- 配置 SPA 路由支持

### 3. 配置文件
- `docker-compose.static.yml` - 静态部署配置
- `nginx.conf` - nginx 配置

---

## 服务状态

```
NAMES       STATUS    IMAGE
clawpanel   Up        nginx:alpine
```

### 访问测试
- URL: http://127.0.0.1:1420/
- HTTP 状态码: 200
- 响应时间: ~0.3ms

---

## 深度检测结果

### 发现的问题

#### 🔴 CRITICAL (1)
| 问题 | 说明 | 修复建议 |
|------|------|---------|
| 小模型安全风险 | ollama 小模型未启用沙箱且允许 web 工具 | 启用沙箱或禁用 web 工具 |

#### 🟡 WARN (8)
| 问题 | 说明 | 状态 |
|------|------|------|
| 无认证速率限制 | gateway 未配置 rateLimit | 待配置 |
| exec security=full | 多个 agent 启用完整 exec 信任 | 可接受（内网环境） |
| sessions.json 权限 | 6 个文件权限为 644 | ✅ 已修复为 600 |

#### ℹ️ INFO (2)
- 攻击面摘要
- HTTP API session-key override 已启用

---

## 已修复

1. ✅ sessions.json 权限修复
   - 批量修改为 600
   - 防止路由和元数据泄露

2. ✅ ClawPanel 升级完成
   - 版本 0.13.4 → 0.14.0
   - 服务正常运行

---

## 待处理建议

### 优先级高
```bash
# 配置认证速率限制
openclaw config set gateway.auth.rateLimit '{"maxAttempts":10,"windowMs":60000,"lockoutMs":300000}'
```

### 优先级中
```bash
# 为小模型启用沙箱（如果需要）
openclaw config set agents.defaults.sandbox.mode "all"
```

---

## 文件变更

| 文件 | 操作 |
|------|------|
| `dist/` | 更新为 v0.14.0 |
| `docker-compose.static.yml` | 新增 |
| `nginx.conf` | 新增 |
| `package.json` | 版本更新 |

---

## 时间戳
- 升级时间: 2026-04-26 03:50
- 报告生成: 2026-04-26 03:52
