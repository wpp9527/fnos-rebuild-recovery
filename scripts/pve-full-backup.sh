#!/bin/bash
# ============================================================
# PVE 整机备份脚本 (存NAS版)
# 存储位置: NAS /vol2/1000/pve-backup/
# 保留最近2轮备份，每周日凌晨3:00自动清理旧备份
# ============================================================

set -euo pipefail

# ---- 配置 ----
NAS_IP="192.168.1.212"
NAS_USER="root"
NAS_BASE="/vol2/1000/pve-backup"

PVE_IP="192.168.1.190"
PVE_USER="root"
PVE_PASS="wp930803"

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="${NAS_BASE}/${TIMESTAMP}"
KEEP=2

LOG_FILE="/var/log/pve-backup.log"

# ---- 日志函数 ----
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# ---- SSH到PVE执行命令 ----
ssh_pve() {
    sshpass -p "$PVE_PASS" ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 \
        "${PVE_USER}@${PVE_IP}" "$1"
}

# ---- SCP从PVE下载文件 ----
scp_from_pve() {
    sshpass -p "$PVE_PASS" scp -o StrictHostKeyChecking=no -o ConnectTimeout=10 \
        "${PVE_USER}@${PVE_IP}:$1" "$2"
}

log "===== PVE 整机备份开始 ====="

# ---- 创建备份目录 ----
mkdir -p "$BACKUP_DIR"
mkdir -p "${BACKUP_DIR}/pve-config"
mkdir -p "${BACKUP_DIR}/vm-ct-configs"
mkdir -p "${BACKUP_DIR}/disks"
log "备份目录: ${BACKUP_DIR}"

# ---- 1. 备份PVE节点配置 ----
log "[1/4] 备份PVE节点配置..."

# /etc/pve (集群配置、VM/CT配置、存储、网络等)
ssh_pve "tar czf /tmp/pve-etc-pve.tar.gz -C / etc/pve" 2>/dev/null
scp_from_pve "/tmp/pve-etc-pve.tar.gz" "${BACKUP_DIR}/pve-config/"
ssh_pve "rm -f /tmp/pve-etc-pve.tar.gz"

# /etc/network/interfaces
ssh_pve "tar czf /tmp/pve-network.tar.gz -C / etc/network" 2>/dev/null
scp_from_pve "/tmp/pve-network.tar.gz" "${BACKUP_DIR}/pve-config/"
ssh_pve "rm -f /tmp/pve-network.tar.gz"

# /etc/hosts, /etc/hostname, /etc/resolv.conf
ssh_pve "tar czf /tmp/pve-hosts.tar.gz -C / etc/hosts etc/hostname etc/resolv.conf" 2>/dev/null
scp_from_pve "/tmp/pve-hosts.tar.gz" "${BACKUP_DIR}/pve-config/"
ssh_pve "rm -f /tmp/pve-hosts.tar.gz"

# /etc/lvm (LVM配置)
ssh_pve "tar czf /tmp/pve-lvm.tar.gz -C / etc/lvm" 2>/dev/null
scp_from_pve "/tmp/pve-lvm.tar.gz" "${BACKUP_DIR}/pve-config/"
ssh_pve "rm -f /tmp/pve-lvm.tar.gz"

# /etc/fstab
ssh_pve "cp /etc/fstab /tmp/pve-fstab" 2>/dev/null
scp_from_pve "/tmp/pve-fstab" "${BACKUP_DIR}/pve-config/"
ssh_pve "rm -f /tmp/pve-fstab"

# PVE版本和订阅信息
ssh_pve "pveversion -v > /tmp/pve-version.txt 2>&1" 2>/dev/null
scp_from_pve "/tmp/pve-version.txt" "${BACKUP_DIR}/pve-config/"
ssh_pve "rm -f /tmp/pve-version.txt"

log "[1/4] PVE节点配置备份完成"

# ---- 2. 备份VM/CT配置和磁盘 ----
log "[2/4] 备份VM/CT配置..."

# 导出所有VM/CT配置
ssh_pve "for vmid in \$(qm list 2>/dev/null | awk 'NR>1 {print \$1}'); do qm config \$vmid > /tmp/vm-\${vmid}.conf 2>/dev/null; done" 2>/dev/null
ssh_pve "for vmid in \$(pct list 2>/dev/null | awk 'NR>1 {print \$1}'); do pct config \$vmid > /tmp/ct-\${vmid}.conf 2>/dev/null; done" 2>/dev/null

# 打包所有配置文件
ssh_pve "tar czf /tmp/vm-ct-configs.tar.gz /tmp/vm-*.conf /tmp/ct-*.conf 2>/dev/null || true" 2>/dev/null
scp_from_pve "/tmp/vm-ct-configs.tar.gz" "${BACKUP_DIR}/vm-ct-configs/"
ssh_pve "rm -f /tmp/vm-ct-configs.tar.gz /tmp/vm-*.conf /tmp/ct-*.conf"

log "[2/4] VM/CT配置备份完成"

# ---- 3. 备份VM/CT磁盘镜像 (vzdump) ----
log "[3/4] 备份VM/CT磁盘镜像..."

# 获取所有VM和CT列表
VM_LIST=$(ssh_pve "qm list 2>/dev/null | awk 'NR>1 {print \$1}'" 2>/dev/null || true)
CT_LIST=$(ssh_pve "pct list 2>/dev/null | awk 'NR>1 {print \$1}'" 2>/dev/null || true)

# 备份每个VM
for vmid in $VM_LIST; do
    log "  备份VM ${vmid}..."
    BACKUP_NAME="vm-${vmid}-${TIMESTAMP}"
    
    # 使用vzdump备份到临时目录
    ssh_pve "vzdump ${vmid} --compress zstd --dumpdir /tmp --mode stop --notes 'Auto backup ${TIMESTAMP}'" 2>/dev/null || {
        log "  [WARNING] VM ${vmid} 备份失败，跳过"
        continue
    }
    
    # 下载备份文件
    VM_BACKUP_FILE=$(ssh_pve "ls -t /tmp/vzdump-qemu-${vmid}-*.vma.zst 2>/dev/null | head -1" 2>/dev/null || true)
    if [ -n "$VM_BACKUP_FILE" ]; then
        scp_from_pve "$VM_BACKUP_FILE" "${BACKUP_DIR}/disks/"
        ssh_pve "rm -f $VM_BACKUP_FILE"
        log "  VM ${vmid} 备份完成"
    else
        log "  [WARNING] VM ${vmid} 备份文件未找到"
    fi
done

# 备份每个CT
for ctid in $CT_LIST; do
    log "  备份CT ${ctid}..."
    BACKUP_NAME="ct-${ctid}-${TIMESTAMP}"
    
    # 使用vzdump备份到临时目录
    ssh_pve "vzdump ${ctid} --compress zstd --dumpdir /tmp --mode stop --notes 'Auto backup ${TIMESTAMP}'" 2>/dev/null || {
        log "  [WARNING] CT ${ctid} 备份失败，跳过"
        continue
    }
    
    # 下载备份文件
    CT_BACKUP_FILE=$(ssh_pve "ls -t /tmp/vzdump-lxc-${ctid}-*.tar.zst 2>/dev/null | head -1" 2>/dev/null || true)
    if [ -n "$CT_BACKUP_FILE" ]; then
        scp_from_pve "$CT_BACKUP_FILE" "${BACKUP_DIR}/disks/"
        ssh_pve "rm -f $CT_BACKUP_FILE"
        log "  CT ${ctid} 备份完成"
    else
        log "  [WARNING] CT ${ctid} 备份文件未找到"
    fi
done

log "[3/4] VM/CT磁盘镜像备份完成"

# ---- 4. 生成备份清单 ----
log "[4/4] 生成备份清单..."

cat > "${BACKUP_DIR}/manifest.txt" << EOF
====================================
PVE 整机备份清单
====================================
备份时间: $(date '+%Y-%m-%d %H:%M:%S')
PVE节点: ${PVE_IP}
备份目录: ${BACKUP_DIR}

包含内容:
1. PVE节点配置 (/etc/pve, /etc/network, /etc/lvm等)
2. VM/CT配置文件
3. VM/CT磁盘镜像 (vzdump格式)

备份大小: $(du -sh "$BACKUP_DIR" | cut -f1)

磁盘镜像列表:
$(ls -lh "${BACKUP_DIR}/disks/" 2>/dev/null | tail -n +2 || echo "无")

配置文件列表:
$(ls -lh "${BACKUP_DIR}/pve-config/" 2>/dev/null || echo "无")
====================================
EOF

log "[4/4] 备份清单生成完成"

# ---- 5. 清理旧备份（保留最近2轮）----
log "清理旧备份（保留最近${KEEP}轮）..."

# 按时间戳排序，删除旧备份
cd "$NAS_BASE"
OLD_BACKUPS=$(ls -dt */ 2>/dev/null | tail -n +$((KEEP + 1)))

if [ -n "$OLD_BACKUPS" ]; then
    for old in $OLD_BACKUPS; do
        log "  删除旧备份: ${old}"
        rm -rf "${NAS_BASE}/${old}"
    done
    log "  清理完成"
else
    log "  无需清理"
fi

# ---- 备份完成 ----
BACKUP_SIZE=$(du -sh "$BACKUP_DIR" | cut -f1)
log "===== PVE 整机备份完成 ====="
log "备份位置: ${BACKUP_DIR}"
log "备份大小: ${BACKUP_SIZE}"
log "保留轮数: ${KEEP}"
echo ""
echo "✅ PVE 整机备份完成"
echo "📁 备份位置: ${BACKUP_DIR}"
echo "💾 备份大小: ${BACKUP_SIZE}"
echo "🔄 保留轮数: ${KEEP}"
