# FNOS 系统盘扩容进度 (2026-06-19)

## 操作目标
将系统盘 sda2 从 63.9G 扩容到 200G

## 当前进度
### ✅ 全部完成
1. 卸载 /fs 存储池
2. 停止 LVM (deactivate VG)
3. 停止 RAID (mdadm --stop /dev/md0)
4. 备份分区表到 /tmp/sda-partition-backup.dump
5. 用 sfdisk 写入新分区表
6. 重启系统
7. 扩展 sda2 的 ext4 文件系统
8. 重建 sda3 的 RAID (raid1, 单盘)
9. 重建 LVM (VG + LV)
10. 创建 /fs ext4 文件系统
11. 挂载 /fs
12. 配置开机自动挂载 (fstab + mdadm.conf)

### 最终分区布局
```
/dev/sda1: 94M    (boot) - 不变
/dev/sda2: 200G   (系统盘 /) - 从 63.9G 扩到 200G (实际 197G)
/dev/sda3: 276.8G (存储池 /fs) - 从 412.9G 缩到 276.8G (实际 272G)
```

### 最终状态
- 系统盘 `/`: 197G 总量, 39G 已用, 150G 可用 (21%)
- 存储池 `/fs`: 272G 总量, 28K 已用, 258G 可用 (1%)
- RAID: md0, raid1, UUID=5d811aa7:e3d81e56:8e874730:d77b69c7
- LVM VG: trim_132a1d9d_25cd_40fe_860e_77dbc6caaafa
- 自动挂载: 已配置 fstab + mdadm.conf

## 关键信息
- 磁盘: /dev/sda (476.94G, Great Wall GW600)
- RAID 配置: raid1, 1/1 [U]
- LVM VG: trim_132a1d9d_25cd_40fe_860e_77dbc6caaafa
- LVM LV: 0
- /fs 数据已备份到 NAS

## 注意事项
- 分区表已写入但内核还在用旧表，必须重启
- 重启后先检查分区是否生效
- 然后按顺序完成剩余步骤
