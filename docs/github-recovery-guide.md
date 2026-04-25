# GitHub 恢复操作指南

本文档描述如何从 GitHub 仓库 `wpp9527/fnos-rebuild-recovery` 执行完整恢复。

---

## 前置条件

### 必须有
- 一台干净的 Linux 机器（推荐 Debian/Ubuntu）
- Git
- Docker 和 Docker Compose
- 网络访问 GitHub
- 网络访问 NAS（`/mnt/nas/backup`）

### 可选但推荐
- OpenClaw 已安装（如果恢复 OpenClaw 自身则需要）
- PVE SSH 访问权限（如果恢复 PVE 配置）

---

## 步骤 1：克隆仓库

```bash
# 克隆恢复仓库
git clone https://github.com/wpp9527/fnos-rebuild-recovery.git
cd fnos-rebuild-recovery

# 查看当前版本
git log --oneline -n 5
```

---

## 步骤 2：准备恢复环境

### 2.1 创建配置文件

```bash
# 复制配置模板
mkdir -p state/backup
cp scripts/backup/config.env.example state/backup/config.env

# 编辑配置（如果需要修改路径）
# vim state/backup/config.env
```

### 2.2 挂载 NAS 备份目录

```bash
# 确保 NAS 备份目录可访问
ls -la /mnt/nas/backup/

# 应该看到：
# - pve/latest/
# - fnos/latest/
# - services/openclaw/latest/
# - shared/secrets/latest/
```

---

## 步骤 3：执行恢复

### 3.1 查看恢复计划

```bash
# 生成恢复计划（不执行实际恢复）
bash restore/restore-all.sh plan --source hybrid
```

这会生成：
- `state/restore/restore-plan.md` — 恢复计划
- `state/restore/restore-context.yaml` — 上下文信息

### 3.2 执行恢复

```bash
# 执行完整恢复到目标目录
# 默认目标：state/restore/target

bash restore/restore-all.sh apply --source hybrid
```

### 3.3 恢复到真实路径（生产环境）

```bash
# 恢复到真实系统路径（需要 root 权限）
sudo RESTORE_TARGET_ROOT=/ \
  bash restore/restore-all.sh apply --source hybrid
```

**⚠️ 警告：** 这会覆盖现有文件。建议先在测试环境验证。

---

## 步骤 4：验证恢复

```bash
# 执行验证
bash restore/restore-all.sh verify --source hybrid
```

验证报告会生成在：
- `state/restore/reports/`

---

## 恢复内容说明

### 从 GitHub 获取的内容
- 恢复脚本和框架
- 服务模板（`restore/templates/`）
- 服务清单（`restore/manifests/`）
- 文档（`docs/`）

### 从 NAS 获取的内容
- PVE 配置和元数据
- fnOS 高价值本地状态
- OpenClaw workspace
- Secrets（openclaw.env, channels/*.env）
- 服务 compose 和 env 文件

---

## 各层恢复详解

### Layer 10 — PVE

**恢复内容：**
- hostname, IP 地址
- PVE 版本信息
- VM/CT 列表
- storage 配置
- network interfaces
- `/etc/pve` 配置（pve-config.tar.gz）

**恢复位置：**
- `$TARGET_ROOT/pve/`

**注意事项：**
- PVE 配置恢复需要手动应用到 PVE 主机
- VM/CT 需要单独恢复（从备份存储）

---

### Layer 20 — fnOS

**恢复内容：**
- `/opt/fnos-media/fnos-media-stack/` — 媒体栈配置
- `/opt/fnos-media/services/hermes-openwebui/data` — Hermes 数据
- `/opt/fnos-media/services/docker-stack/channels/` — Channels 配置
- `/opt/fnos-media/services/docker-stack/ai-proxy/cliproxyapi/` — AI 代理配置

**恢复位置：**
- `$TARGET_ROOT/opt/fnos-media/`

---

### Layer 30 — Services

**恢复内容：**
- fnos-media-stack 的 `docker-compose.yml`
- fnos-media-stack 的 `.env`（从 secrets 合并）

**恢复位置：**
- `$TARGET_ROOT/services/fnos-media-stack/`

---

### Layer 40 — OpenClaw

**恢复内容：**
- workspace 完整内容
- 配置文件
- 文档

**恢复位置：**
- `$TARGET_ROOT/openclaw/`

---

### Layer 50 — Secrets

**恢复内容：**
- `OPENCLAW_GATEWAY_AUTH_TOKEN`
- `FEISHU_APP_SECRET`
- `QQ_APP_SECRET`
- `OPENAI_API_KEY`
- Homarr/Halo/Jellyfin secrets（如果有值）

**恢复位置：**
- `$TARGET_ROOT/openclaw/.env`

---

## 灾难恢复场景

### 场景 1：OpenClaw 主机完全丢失

```bash
# 1. 新机器安装 OpenClaw
# 2. 克隆恢复仓库
git clone https://github.com/wpp9527/fnos-rebuild-recovery.git
cd fnos-rebuild-recovery

# 3. 恢复 OpenClaw workspace
sudo RESTORE_TARGET_ROOT=/opt/fnos-media/services/openclaw/home/.openclaw \
  OPENCLAW_LATEST_ROOT=/mnt/nas/backup/services/openclaw/latest \
  bash restore/layers/40-openclaw.sh apply

# 4. 恢复 secrets
sudo SECRETS_REAL_DIR=/mnt/nas/backup/shared/secrets/latest \
  RESTORE_TARGET_ROOT=/opt/fnos-media/services/openclaw/home/.openclaw \
  bash restore/layers/50-secrets.sh apply

# 5. 重启 OpenClaw
sudo systemctl restart openclaw
```

---

### 场景 2：fnos-media-stack 服务丢失

```bash
# 1. 恢复服务配置
sudo RESTORE_TARGET_ROOT=/ \
  FNOS_LATEST_ROOT=/mnt/nas/backup/fnos/latest \
  bash restore/layers/20-fnos.sh apply

# 2. 恢复 compose 和 env
sudo RESTORE_TARGET_ROOT=/ \
  SECRETS_REAL_DIR=/mnt/nas/backup/shared/secrets/latest \
  bash restore/layers/30-services.sh apply

# 3. 重启服务
cd /opt/fnos-media-stack
sudo docker compose up -d
```

---

### 场景 3：仅恢复特定服务

```bash
# 只恢复 homarr 配置
sudo cp -r /mnt/nas/backup/fnos/latest/fnos-media-stack/homarr /opt/fnos-media-stack/

# 只恢复 channels 配置
sudo cp -r /mnt/nas/backup/fnos/latest/services/docker-stack/channels /opt/fnos-media/services/docker-stack/
```

---

## 常见问题

### Q: 恢复后服务无法启动？

检查 secrets 是否正确注入：
```bash
cat /opt/fnos-media-stack/.env | grep -E 'PASSWORD|SECRET|KEY'
```

### Q: NAS 无法访问？

检查挂载点：
```bash
mount | grep nas
df -h | grep nas
```

### Q: 恢复过程中断？

恢复是幂等的，可以重新执行：
```bash
bash restore/restore-all.sh apply --source hybrid
```

### Q: 如何验证备份完整性？

```bash
# 检查所有备份源
ls -la /mnt/nas/backup/pve/latest/
ls -la /mnt/nas/backup/fnos/latest/
ls -la /mnt/nas/backup/services/openclaw/latest/
ls -la /mnt/nas/backup/shared/secrets/latest/
```

---

## 恢复后检查清单

- [ ] OpenClaw 服务正常运行
- [ ] fnos-media-stack 所有容器启动
- [ ] Homarr 可以访问
- [ ] Jellyfin 媒体库正常
- [ ] Channels (Feishu/QQ) 连接正常
- [ ] PVE VM/CT 列表正确

---

## 相关文档

- `docs/backup-automation.md` — 备份自动化说明
- `docs/recovery-drill-guide.md` — 恢复演练指南
- `docs/recovery-drill-report-2026-04-26.md` — 最近演练报告
- `restore/manifests/service-catalog.yaml` — 服务清单
- `restore/manifests/path-policy.yaml` — 路径策略

---

## 紧急联系

如果恢复过程中遇到问题：

1. 查看 `state/restore/reports/` 下的验证报告
2. 运行 `scripts/backup/audit_runtime_state.sh` 检查系统状态
3. 查看 GitHub Issues: https://github.com/wpp9527/fnos-rebuild-recovery/issues
