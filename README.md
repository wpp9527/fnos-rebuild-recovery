# fnos-rebuild-recovery

fnOS 系统恢复与备份自动化框架

---

## 快速恢复

### 交互式恢复（推荐）

```bash
# 克隆仓库
git clone https://github.com/wpp9527/fnos-rebuild-recovery.git
cd fnos-rebuild-recovery

# 运行交互式恢复
bash restore/interactive-restore.sh
```

### 一键命令恢复

```bash
# 恢复到指定目录
RESTORE_TARGET_ROOT=/opt/restore \
  FNOS_LATEST_ROOT=/mnt/nas/backup/fnos/latest \
  OPENCLAW_LATEST_ROOT=/mnt/nas/backup/services/openclaw/latest \
  SECRETS_REAL_DIR=/mnt/nas/backup/shared/secrets/latest \
  bash restore/restore-all.sh apply --source nas
```

---

## 无代理/离线恢复

### 下载 ZIP 包

```bash
# ghproxy 代理（国内推荐）
wget https://ghproxy.com/https://github.com/wpp9527/fnos-rebuild-recovery/archive/refs/heads/main.zip
unzip main.zip && cd fnos-rebuild-recovery-main

# 或直接下载
wget https://github.com/wpp9527/fnos-rebuild-recovery/archive/refs/heads/main.zip
```

### 代理加速 Git Clone

```bash
# ghproxy
git clone https://ghproxy.com/https://github.com/wpp9527/fnos-rebuild-recovery.git

# fastgit
git clone https://hub.fastgit.xyz/wpp9527/fnos-rebuild-recovery.git
```

### 离线传输

```bash
# 有网络机器：打包
tar -czf recovery.tar.gz .

# U盘传输后，新机器：解压
tar -xzf recovery.tar.gz -C /opt/recovery
```

---

## 恢复选项

| 选项 | 说明 |
|------|------|
| 完整恢复 | 恢复所有配置、数据、secrets |
| 选择性恢复 | 选择要恢复的层（PVE/fnOS/OpenClaw/Services/Secrets） |
| 仅恢复配置 | 只恢复配置文件，不恢复数据 |
| 仅恢复数据 | 只恢复数据文件，不恢复配置 |

---

## 恢复后目录结构

```
<TARGET_ROOT>/
├── config/                    # 所有配置
│   ├── fnos-media-stack/     # 媒体栈配置 + docker-compose.yml
│   ├── channels/             # Feishu/QQ 频道配置
│   ├── cliproxyapi/          # AI 代理配置
│   └── openclaw/             # OpenClaw secrets
│
├── data/                      # 所有数据
│   ├── homarr-appdata/
│   ├── halo-content/
│   └── stash/
│
├── workspace/                 # OpenClaw workspace
│   ├── docs/
│   ├── scripts/
│   └── memory/
│
└── pve/                       # PVE 配置备份
    └── pve-config.tar.gz
```

---

## 部署到生产

```bash
# 恢复后部署到实际运行位置
cp -r <TARGET>/config/fnos-media-stack /opt/
cp -r <TARGET>/workspace /opt/fnos-media/services/openclaw/home/.openclaw/
cp -r <TARGET>/config/channels /opt/fnos-media/services/docker-stack/

# 启动服务
cd /opt/fnos-media-stack && docker compose up -d
```

---

## 自动备份

### 手动运行

```bash
# 每日备份
bash scripts/backup/run_daily.sh

# 每周备份 + 快照
bash scripts/backup/run_weekly.sh
```

### 定时任务

```bash
# 添加到 crontab
0 2 * * * /path/to/scripts/backup/run_daily.sh
0 3 * * 0 /path/to/scripts/backup/run_weekly.sh
```

---

## 备份内容

| 层 | 内容 |
|----|------|
| PVE | hostname, /etc/pve 配置, VM/CT 列表 |
| fnOS | fnos-media-stack, channels, hermes, cliproxyapi |
| OpenClaw | workspace, config, docs |
| Secrets | 从容器自动提取 secrets |
| Services | docker-compose.yml, .env |

---

## 文档

- [GitHub 恢复操作指南](docs/github-recovery-guide.md)
- [离线/无代理恢复指南](docs/offline-recovery-guide.md)
- [恢复演练指南](docs/recovery-drill-guide.md)
- [备份自动化说明](docs/backup-automation.md)

---

## 仓库结构

```
.
├── restore/                   # 恢复脚本
│   ├── interactive-restore.sh # 交互式恢复入口
│   ├── restore-all.sh         # 完整恢复入口
│   ├── layers/                # 分层恢复脚本
│   └── templates/             # 恢复模板
│
├── scripts/backup/            # 备份脚本
│   ├── run_daily.sh
│   ├── run_weekly.sh
│   └── tasks/
│
├── docs/                      # 文档
└── tests/                     # 测试
```

---

## 最近更新

| 提交 | 说明 |
|------|------|
| `9280eaa` | 离线/无代理恢复指南 |
| `50030ad` | 统一恢复目标结构 |
| `664c9c4` | 交互式恢复脚本 |
| `a1280d2` | PVE 配置导出增强 |

---

## License

MIT
