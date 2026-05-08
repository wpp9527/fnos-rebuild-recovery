# 离线/无代理恢复指南

当新机器无法访问 GitHub 或没有网络代理时，使用本指南。

---

## 方案对比

| 方案 | 适用场景 | 优点 | 缺点 |
|------|---------|------|------|
| ZIP 下载 | 快速获取 | 不需要 git | 无版本控制 |
| 代理镜像 | 有网络但慢 | 速度快 | 镜像可能不同步 |
| 离线传输 | 完全无网络 | 可靠 | 需要介质 |
| 内网 Git | 企业环境 | 版本控制 | 需要内网 Git 服务器 |

---

## 方案 1：ZIP 包下载（最简单）

### 使用 GitHub 代理

```bash
# ghproxy（国内常用）
wget https://ghproxy.com/https://github.com/wpp9527/fnos-rebuild-recovery/archive/refs/heads/main.zip -O recovery.zip

# 解压
unzip recovery.zip
cd fnos-rebuild-recovery-main

# 运行恢复
bash restore/interactive-restore.sh
```

### 直接下载 ZIP

```bash
# 如果能访问 GitHub
wget https://github.com/wpp9527/fnos-rebuild-recovery/archive/refs/heads/main.zip -O recovery.zip
unzip recovery.zip
cd fnos-rebuild-recovery-main
```

---

## 方案 2：代理加速 Git Clone

```bash
# ghproxy 代理
git clone https://ghproxy.com/https://github.com/wpp9527/fnos-rebuild-recovery.git

# 或 fastgit 代理
git clone https://hub.fastgit.xyz/wpp9527/fnos-rebuild-recovery.git

# 或 gitclone 代理
git clone https://gitclone.com/github.com/wpp9527/fnos-rebuild-recovery.git
```

---

## 方案 3：离线传输（完全无网络）

### 步骤 1：在有网络的机器上准备

```bash
# 下载仓库
git clone https://github.com/wpp9527/fnos-rebuild-recovery.git
cd fnos-rebuild-recovery

# 打包
tar -czf ../fnos-rebuild-recovery.tar.gz .

# 同时打包 NAS 备份（如果需要）
tar -czf ../nas-backup.tar.gz -C /mnt/nas/backup .
```

### 步骤 2：传输到新机器

使用以下方式之一：
- U 盘
- 移动硬盘
- 内网 SCP/SFTP
- 光盘（小文件）

### 步骤 3：在新机器上解压

```bash
# 创建目标目录
mkdir -p /opt/recovery

# 解压仓库
tar -xzf fnos-rebuild-recovery.tar.gz -C /opt/recovery

# 解压 NAS 备份（如果有）
mkdir -p /mnt/nas/backup
tar -xzf nas-backup.tar.gz -C /mnt/nas/backup

# 进入目录
cd /opt/recovery
```

---

## 方案 4：最小恢复包

如果只需要恢复脚本，不需要完整仓库：

### 创建最小包

```bash
# 在有网络机器上
mkdir -p minimal-recovery
cp -r restore/ minimal-recovery/
cp -r scripts/backup/ minimal-recovery/scripts/
cp -r docs/github-recovery-guide.md minimal-recovery/
cp restore/interactive-restore.sh minimal-recovery/

# 打包
tar -czf minimal-recovery.tar.gz minimal-recovery/
```

### 使用最小包

```bash
# 在新机器上
tar -xzf minimal-recovery.tar.gz
cd minimal-recovery
bash restore/interactive-restore.sh
```

---

## 方案 5：内网 Git 服务器

如果有内网 Git 服务器：

```bash
# 1. 在有网络机器上 Fork 到内网 Git
git clone https://github.com/wpp9527/fnos-rebuild-recovery.git
cd fnos-rebuild-recovery
git remote add internal http://internal-git-server/repo.git
git push internal main

# 2. 在新机器上从内网克隆
git clone http://internal-git-server/repo.git fnos-rebuild-recovery
cd fnos-rebuild-recovery
```

---

## 验证下载完整性

```bash
# 检查关键文件是否存在
ls -la restore/interactive-restore.sh
ls -la restore/layers/*.sh
ls -la scripts/backup/tasks/publish_secrets.sh

# 检查文件数量
find . -name "*.sh" | wc -l  # 应该有 20+ 个脚本
```

---

## 恢复步骤（无代理环境）

```bash
# 1. 解压/进入目录
cd /opt/recovery  # 或你的解压位置

# 2. 检查 NAS 备份是否可访问
ls -la /mnt/nas/backup/  # 或你的备份位置

# 3. 运行恢复
bash restore/interactive-restore.sh

# 4. 或命令行恢复
RESTORE_TARGET_ROOT=/opt/restore \
  FNOS_LATEST_ROOT=/mnt/nas/backup/fnos/latest \
  OPENCLAW_LATEST_ROOT=/mnt/nas/backup/services/openclaw/latest \
  SECRETS_REAL_DIR=/mnt/nas/backup/shared/secrets/latest \
  bash restore/restore-all.sh apply --source nas
```

---

## 常用代理镜像列表

| 镜像 | 用途 | 地址 |
|------|------|------|
| ghproxy | GitHub 代理 | https://ghproxy.com/ |
| fastgit | Git 加速 | https://hub.fastgit.xyz/ |
| gitclone | Git 克隆加速 | https://gitclone.com/ |
| kgithub | GitHub 镜像 | https://github.com.cnpmjs.org/ |

---

## 注意事项

1. **镜像同步延迟** - 代理镜像可能有几分钟到几小时的延迟
2. **大文件** - ZIP 包约 1-2MB，完整备份可能几十 GB
3. **权限** - 解压后可能需要 `chmod +x *.sh`
4. **路径** - 确保恢复脚本能找到备份位置

---

## 完整示例：从 ZIP 恢复

```bash
# 1. 下载
wget https://ghproxy.com/https://github.com/wpp9527/fnos-rebuild-recovery/archive/refs/heads/main.zip -O recovery.zip

# 2. 解压
unzip recovery.zip
cd fnos-rebuild-recovery-main

# 3. 设置权限
chmod +x restore/*.sh restore/layers/*.sh restore/interactive-restore.sh
chmod +x scripts/backup/*.sh scripts/backup/tasks/*.sh

# 4. 检查备份
ls -la /mnt/nas/backup/

# 5. 运行恢复
bash restore/interactive-restore.sh
```
