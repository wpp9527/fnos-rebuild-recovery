# fnos-rebuild-recovery

FNOS 系统全自动备份与一键恢复框架。覆盖 PVE、FNOS、OpenClaw、媒体栈、AI 代理、容器卷、Secrets 全部层级。

> **最近更新 (2026-05)**：OpenClaw 重装后路径变更至 `/root/.openclaw/`，所有脚本已同步更新。

---

## 系统架构

```
┌─────────────────────────────────────────────────┐
│                   PVE (.190)                     │
│  ┌─────────────┐  ┌──────────────────────────┐  │
│  │  LXC 代理    │  │       FNOS VM (.212)      │  │
│  │  (.213)      │  │  ┌────────────────────┐  │  │
│  │  mihomo      │  │  │  OpenClaw          │  │  │
│  │  订阅+规则   │  │  │  /root/.openclaw/  │  │  │
│  └─────────────┘  │  ├────────────────────┤  │  │
│                    │  │  /opt/fnos-media/  │  │  │
│                    │  │  ├ docker-stack/   │  │  │
│                    │  │  │ ├ channels/     │  │  │
│                    │  │  │ └ ai-proxy/     │  │  │
│                    │  │  └ ollama/         │  │  │
│                    │  └────────────────────┘  │  │
│                    └──────────────────────────┘  │
└─────────────────────────────────────────────────┘
                         │
                    ┌────┴────┐
                    │  NAS    │
                    │ /mnt/nas│
                    │ /backup │
                    └─────────┘
```

---

## 备份了什么

| 层 | 内容 | 来源 |
|----|------|------|
| **PVE** | hostname、`/etc/pve` 配置、VM/CT 清单、网络、存储 | SSH → 192.168.1.190 |
| **FNOS** | docker-stack 配置（channels/ai-proxy）、manifests、bin | `/opt/fnos-media/` |
| **OpenClaw** | workspace 全量（memory/skills/docs/scripts）、openclaw.json、clawpanel 配置 | `/root/.openclaw/` |
| **容器卷** | homarr/halo/qbit/jackett/radarr/sonarr/prowlarr/bazarr/seerr 配置数据 | Docker volumes |
| **LXC 代理** | mihomo 配置+订阅、systemd 服务、容器配置 | SSH → VMID 213 |
| **Secrets** | OpenClaw token、飞书 app secret、cliproxyapi 配置 | 容器环境变量提取 |

---

## 快速恢复

### 方式一：交互式恢复（推荐）

```bash
# 1. 克隆仓库
git clone https://github.com/wpp9527/fnos-rebuild-recovery.git
cd fnos-rebuild-recovery

# 2. 运行交互式恢复（会引导选择恢复哪些层）
bash restore/interactive-restore.sh
```

交互式恢复会依次询问：
1. 恢复来源（GitHub / NAS / 两者）
2. 恢复目标目录
3. 要恢复的层级（PVE / FNOS / OpenClaw / Services / Secrets）
4. 是否仅恢复配置（跳过数据）

### 方式二：一键命令恢复

```bash
# 从 NAS 恢复全部
RESTORE_TARGET_ROOT=/opt/restore \
  FNOS_LATEST_ROOT=/mnt/nas/backup/fnos/latest \
  OPENCLAW_LATEST_ROOT=/mnt/nas/backup/services/openclaw/latest \
  SECRETS_REAL_DIR=/mnt/nas/backup/shared/secrets/latest \
  bash restore/restore-all.sh apply --source nas

# 从 GitHub 恢复 OpenClaw workspace
bash restore/restore-all.sh apply --source github --layers openclaw
```

### 方式三：手动恢复（精细控制）

```bash
# 恢复 OpenClaw workspace
cp -r state/backup/staging/openclaw/ /root/.openclaw/.openclaw/workspace/

# 恢复 OpenClaw 配置
cp state/backup/staging/fnos/services/openclaw/home/.openclaw/openclaw.json /root/.openclaw/
cp state/backup/staging/fnos/services/openclaw/home/.openclaw/clawpanel.json /root/.openclaw/
cp state/backup/staging/fnos/services/openclaw/home/.openclaw/clawpanel-device-key.json /root/.openclaw/

# 恢复 Docker 服务配置
cp -r state/backup/staging/fnos/services/docker-stack/ /opt/fnos-media/services/docker-stack/

# 恢复媒体栈容器卷
rsync -av state/backup/staging/container-volumes/ /opt/fnos-media-stack/

# 恢复 Secrets
cp /mnt/nas/backup/shared/secrets/latest/openclaw.env /root/.openclaw/
```

---

## 恢复后部署

恢复到临时目录后，需要部署到实际运行位置：

```bash
# OpenClaw 配置就位
cp <TARGET>/config/openclaw/openclaw.json /root/.openclaw/
cp <TARGET>/config/openclaw/clawpanel.json /root/.openclaw/

# 启动媒体栈
cd /opt/fnos-media-stack && docker compose up -d

# 启动飞书频道
cd /opt/fnos-media/services/docker-stack/channels/feishu && docker compose up -d

# 启动 AI 代理
cd /opt/fnos-media/services/docker-stack/ai-proxy/cliproxyapi && docker compose up -d

# 重启 OpenClaw
openclaw gateway restart
```

---

## 自动备份

### 手动触发

```bash
# 每日增量备份（收集 + 发布到 NAS + 同步 GitHub）
BACKUP_CONFIG=/root/.openclaw/.openclaw/workspace/state/backup/config.env \
  bash scripts/backup/run_daily.sh

# 每周全量备份（含快照归档）
BACKUP_CONFIG=/root/.openclaw/.openclaw/workspace/state/backup/config.env \
  RUN_ARCHIVE=1 bash scripts/backup/run_weekly.sh
```

### 定时调度

已通过 OpenClaw cron 配置自动执行：

| 任务 | 时间 | 内容 |
|------|------|------|
| fnos-daily-backup | 每天 02:00 CST | 增量收集 → NAS → GitHub |
| fnos-weekly-backup | 每周日 03:00 CST | 全量 + 快照归档 |

也可用系统 crontab：

```bash
0 2 * * * /root/.openclaw/.openclaw/workspace/scripts/backup/run_daily.sh
0 3 * * 0 /root/.openclaw/.openclaw/workspace/scripts/backup/run_weekly.sh
```

### 备份流程

```
run_daily.sh
  └─ orchestrator.sh
       ├─ collect_openclaw.sh     → staging/openclaw/
       ├─ collect_pve.sh          → staging/pve/
       ├─ collect_fnos.sh         → staging/fnos/
       ├─ collect_container_volumes.sh → staging/container-volumes/
       ├─ collect_lxc_proxy.sh    → staging/lxc-proxy/
       ├─ publish_latest.sh       → /mnt/nas/backup/*/latest/
       ├─ publish_github.sh       → GitHub repo sync
       └─ publish_secrets.sh      → /mnt/nas/backup/shared/secrets/
```

---

## 配置说明

编辑 `scripts/backup/config.env`（从 `config.env.example` 复制）：

```bash
# === 核心路径 ===
WORKSPACE_ROOT="/root/.openclaw/.openclaw/workspace"   # OpenClaw workspace
OPENCLAW_HOME="/root/.openclaw"                         # OpenClaw 安装目录
OPENCLAW_CONFIG="/root/.openclaw/openclaw.json"         # 主配置文件
BACKUP_ROOT="/mnt/nas/backup"                           # NAS 备份根目录
STAGING_ROOT="$WORKSPACE_ROOT/state/backup/staging"     # 本地暂存

# === PVE ===
PVE_ENABLED=1
PVE_SSH_HOST="192.168.1.190"

# === FNOS ===
FNOS_ENABLED=1
FNOS_LOCAL_ROOT="/opt/fnos-media"

# === GitHub 同步 ===
GITHUB_SYNC_ENABLED=1
GITHUB_SYNC_REMOTE="https://<token>@github.com/wpp9527/fnos-rebuild-recovery.git"
```

---

## 仓库结构

```
.
├── scripts/
│   └── backup/
│       ├── config.env.example    # 配置模板（复制为 config.env 使用）
│       ├── orchestrator.sh       # 备份编排主入口
│       ├── run_daily.sh          # 每日备份入口
│       ├── run_weekly.sh         # 每周备份入口
│       ├── setup-cron.sh         # crontab 安装脚本
│       ├── lib/common.sh         # 公共函数
│       └── tasks/
│           ├── collect_openclaw.sh       # OpenClaw workspace 收集
│           ├── collect_pve.sh            # PVE 配置收集
│           ├── collect_fnos.sh           # FNOS 服务配置收集
│           ├── collect_container_volumes.sh  # 容器卷备份
│           ├── collect_lxc_proxy.sh      # LXC 代理配置收集
│           ├── publish_latest.sh         # 发布到 NAS
│           ├── publish_github.sh         # 同步到 GitHub
│           ├── publish_secrets.sh        # Secrets 提取与发布
│           └── archive_snapshot.sh       # 快照归档
│
├── restore/
│   ├── interactive-restore.sh    # 交互式恢复入口
│   ├── restore-all.sh            # 一键恢复入口
│   ├── layers/                   # 分层恢复脚本
│   │   ├── 00-bootstrap.sh
│   │   ├── 10-pve.sh
│   │   ├── 20-fnos.sh
│   │   ├── 30-services.sh
│   │   ├── 40-openclaw.sh
│   │   ├── 50-secrets.sh
│   │   └── 90-verify.sh
│   ├── manifests/                # 恢复清单与策略
│   │   ├── restore-layers.yaml
│   │   ├── source-map.yaml
│   │   ├── target-layout.yaml
│   │   ├── path-policy.yaml
│   │   ├── service-catalog.yaml
│   │   └── secrets-policy.yaml
│   ├── checks/                   # 恢复前检查脚本
│   └── templates/                # 恢复模板
│
├── tools/
│   └── sync-edict-governance.sh  # workspace → GitHub 同步脚本
│
├── docs/                         # 文档
├── state/                        # 运行时状态（备份暂存、配置）
└── memory/                       # OpenClaw 记忆文件
```

---

## 无代理 / 离线恢复

```bash
# 下载 ZIP
wget https://github.com/wpp9527/fnos-rebuild-recovery/archive/refs/heads/main.zip
unzip main.zip && cd fnos-rebuild-recovery-main

# 或通过代理
wget https://ghproxy.com/https://github.com/wpp9527/fnos-rebuild-recovery/archive/refs/heads/main.zip

# 离线传输（U盘）
tar -czf recovery.tar.gz .
# 新机器上：
tar -xzf recovery.tar.gz -C /opt/recovery
```

---

## 恢复演练

```bash
# 运行恢复演练（不写入生产，只验证流程）
bash restore/run_restore_drill.sh
```

---

## 故障排除

| 问题 | 解决方案 |
|------|---------|
| NAS 不可达 | 检查 `/mnt/nas/backup` 挂载：`mount \| grep nas` |
| PVE SSH 失败 | 确认 `PVE_SSH_HOST` 和密钥/密码配置 |
| GitHub 同步失败 | 检查 token 是否过期，更新 `GITHUB_SYNC_REMOTE` |
| Docker 卷备份跳过 | 确认容器正在运行：`docker ps` |
| OpenClaw 路径不匹配 | 修改 `config.env` 中的 `WORKSPACE_ROOT` 和 `OPENCLAW_HOME` |

---

## 网络拓扑

```
主路由 (192.168.1.1) ── Lucky 反代 :5000
    │
    ├── PVE (192.168.1.190)
    │     ├── FNOS VM (192.168.1.212)
    │     │     ├── OpenClaw :18789
    │     │     └── /opt/fnos-media/
    │     └── LXC 代理 (192.168.1.213)
    │           └── mihomo :7890
    │
    └── NAS (/mnt/nas/backup)
```

## License

MIT
