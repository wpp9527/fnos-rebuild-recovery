# 🔧 FNOS 灾难恢复手册

> 最后更新: 2026-06-17

## 恢复前准备

### 1. 基础环境
- [ ] FNOS 系统安装完成
- [ ] Docker 已安装并运行
- [ ] PostgreSQL 15 已安装
- [ ] Nginx 已安装（TRIM 系统自带）
- [ ] Git 已安装

### 2. 恢复工作区
```bash
# 克隆工作区备份
cd /root
git clone https://github.com/wpp9527/fnos-rebuild-recovery.git .openclaw/workspace
cd .openclaw/workspace
```

---

## 恢复清单

### ✅ 第一层：OpenClaw（AI 助手）

**优先级：最高** — 这是你的 AI 侍从太子

```bash
# 1. 安装 OpenClaw
npm install -g @qingchencloud/openclaw-zh

# 2. 恢复配置
cp recovery/openclaw/openclaw.json.template ~/.openclaw/openclaw.json
# 编辑 openclaw.json，填入实际的 API Key：
#   - cpa 的 apiKey
#   - deepseek 的 apiKey
#   - xiaomimimo 的 apiKey
#   - feishu 的 appSecret
#   - gateway 的 token

# 3. 启动
openclaw gateway start
```

**配置文件位置**: `~/.openclaw/openclaw.json`

**需要填入的密钥**:
| 配置项 | 说明 | 获取方式 |
|--------|------|----------|
| cpa.apiKey | CPA 代理密钥 | cpi.19930901.xyz 管理面板 |
| deepseek.apiKey | DeepSeek 官方密钥 | platform.deepseek.com |
| xiaomimimo.apiKey | 小米密谋密钥 | token-plan-sgp.xiaomimimo.com |
| feishu.appSecret | 飞书应用密钥 | 飞书开放平台 |
| gateway.auth.token | Gateway 认证令牌 | 自行生成随机字符串 |

---

### ✅ 第二层：媒体服务栈（Docker）

**优先级：高** — Jellyfin、qBittorrent、*arr 全家桶

```bash
# 恢复所有 Docker Compose 文件
cd /root/.openclaw/workspace/recovery/docker-compose

# 按顺序启动核心服务
# 1. 基础服务
docker compose -f qbittorrent.yml up -d
docker compose -f jellyfin.yml up -d
docker compose -f tailscale.yml up -d

# 2. *arr 全家桶
docker compose -f prowlarr.yml up -d
docker compose -f sonarr.yml up -d
docker compose -f radarr.yml up -d
docker compose -f bazarr.yml up -d
docker compose -f jackett.yml up -d

# 3. 辅助服务
docker compose -f homarr.yml up -d
docker compose -f rsshub.yml up -d
docker compose -f cliproxyapi.yml up -d
docker compose -f seerr.yml up -d
docker compose -f stash.yml up -d

# 4. 博客
docker compose -f halo.yml up -d

# 5. IPTV
docker compose -f lunatv.yml up -d

# 6. 刮削
docker compose -f javsp.yml up -d
```

**⚠️ 注意**：
- 需要先恢复 Docker 数据卷（`/fs/1000/ftp/docker/` 目录）
- 部分服务需要配置代理：`192.168.1.213:7890`
- qBittorrent WebUI 密码需要重新设置

---

### ✅ 第三层：Nginx 反代配置

**优先级：高** — 外网访问入口

```bash
# 恢复 Nginx 配置
cp recovery/nginx/*.conf /usr/trim/nginx/conf/conf.d/

# 测试并重载
nginx -t && nginx -s reload
```

**配置文件位置**: `/usr/trim/nginx/conf/conf.d/`

---

### ✅ 第四层：定时任务

**优先级：中** — DNF 数据采集、自检等

```bash
# 恢复 crontab
crontab recovery/crontab/root.txt
```

**定时任务列表**:
| 时间 | 任务 | 说明 |
|------|------|------|
| 每小时 | dnf-data-collector.sh | DNF 数据采集 |
| 每天 02:00 | dnf-self-check.sh | 数据完整性自检 |
| 每 6 小时 | tieba-scraper.py | 贴吧帖子抓取 |
| 每天 03:00 | dnf-tieba-import.sh | 贴吧数据导入 |
| 每周日 04:00 | dnf-weekly-report.sh | 生成周报 |

---

### ✅ 第五层：DNF 后台（192.168.1.204）

**优先级：中** — 游戏后台管理

```bash
# SSH 到 DNF 服务器
ssh root@192.168.1.204

# 检查服务状态
systemctl status dnf-admin-v4

# 如果需要重新部署，参考 dnf-private-deploy 仓库
```

**DNF 后台**: http://192.168.1.204:18885 (v4.0)

---

### ✅ 第六层：数据库恢复

**优先级：中** — PostgreSQL 数据

```bash
# 恢复 PostgreSQL 数据库（如果有备份）
# 数据库列表：
#   - ai_manager
#   - appcenter
#   - dm
#   - open_gateway

# 恢复命令示例：
# pg_restore -U postgres -d dm /path/to/dm.dump
```

**⚠️ 当前没有自动备份数据库**，需要手动 `pg_dump` 定期备份。

---

## 网络架构

```
外网 → cpi.19930901.xyz:1234 (Lucky 反代)
    ↓
192.168.1.1 (主路由 Lucky)
    ↓
192.168.1.212 (FNOS 本机)
    ├── :18789  OpenClaw Gateway
    ├── :8096   Jellyfin
    ├── :8086   qBittorrent
    ├── :8090   Halo Blog
    ├── :7575   Homarr
    ├── :3000   LunaTV
    ├── :5666/5667 FNOS 系统
    └── :443    Nginx (所有反代)

192.168.1.213 (代理容器)
    └── :7890   HTTP 代理

192.168.1.190 (PVE)
    └── 虚拟化管理

192.168.1.204 (DNF 服务器)
    └── :18885  DNF 管理后台 v4.0
```

---

## 外网访问域名

| 域名 | 服务 | 端口 |
|------|------|------|
| openclaw.19930901.xyz | OpenClaw | 1234 |
| cpi.19930901.xyz | CPA 代理 | 1234 |
| clawpanel.19930901.xyz | OpenClaw 控制面板 | 1234 |

---

## 快速验证清单

恢复完成后，逐项检查：

- [ ] OpenClaw Gateway 运行正常（`curl http://localhost:18789/health`）
- [ ] 飞书通道连接正常（发送测试消息）
- [ ] Jellyfin 可访问（`http://192.168.1.212:8096`）
- [ ] qBittorrent 可访问（`http://192.168.1.212:8086`）
- [ ] Homarr 仪表板正常（`http://192.168.1.212:7575`）
- [ ] DNF 后台可访问（`http://192.168.1.204:18885`）
- [ ] 外网访问正常（`https://openclaw.19930901.xyz:1234`）
- [ ] 定时任务运行正常（`crontab -l`）
- [ ] 代理可用（`curl -x http://192.168.1.213:7890 https://httpbin.org/ip`）

---

## 缺失的备份（需要手动补充）

以下内容当前**未自动备份**：

| 内容 | 位置 | 重要性 | 备份方式 |
|------|------|--------|----------|
| Docker 数据卷 | `/var/lib/docker/volumes/` | 🔴 高 | 需要定期 rsync |
| PostgreSQL 数据 | `/var/lib/postgresql/` | 🔴 高 | `pg_dump` 定期导出 |
| SSL 证书 | Nginx 配置中引用 | 🟡 中 | 需要备份证书文件 |
| SSH 密钥 | `~/.ssh/` | 🟡 中 | 手动备份 |
| FNOS 系统配置 | 系统设置 | 🟡 中 | FNOS 自带备份功能 |
| qBittorrent 配置 | Docker 卷内 | 🟡 中 | 容器卷备份 |
| Jellyfin 媒体库 | Docker 卷内 | 🟡 中 | 容器卷备份 |
