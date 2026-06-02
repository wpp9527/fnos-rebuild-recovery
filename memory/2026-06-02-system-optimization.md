# 2026-06-02 系统全面优化记录

## 🔧 系统检测与修复

### 1. 系统健康检查
- 系统运行 14 天，稳定
- CPU 负载正常，内存 32GB 充足
- 磁盘 SMART 通过
- NFS 挂载正常

### 2. 服务修复
- **easytier-managed**: 已禁用（文件不存在导致崩溃循环）
- **僵尸 rclone 进程**: 已清理（重启 cloud_storage_dav 回收）
- **OpenClaw Gateway**: 正常运行

## 🎬 JAVSP 自动化流程优化

### 问题
- config.yml 缺少 `check_update` 和 `auto_update` 字段
- 广告文件未自动清理
- preclean-trash 积累 912MB

### 修复
1. **config.yml**: 添加缺失字段，配置校验通过
2. **auto-javsp.sh**: 添加自动清理逻辑
   - 每次刮削前立即删除所有广告文件
   - 通过 qBittorrent 容器处理 NFS 锁定文件
   - 自动清理 .nfs 锁文件和空目录
3. **容器重启**: 应用新配置

## 📥 qBittorrent 速度优化

### 问题
- BT 端口 52345 外网不可达（IPv4 被封）
- Tracker 全部显示"未工作"
- 下载速度仅 0.4 MB/s

### 修复
1. **端口更换**: 52345 → 52000
   - IPv6 可达（✅）
   - IPv4 不可达（运营商封锁）
2. **Tracker 优化**: 
   - 配置 26 个可靠公共 Tracker
   - 禁用不可靠的 Tracker
3. **代理配置**: 
   - HTTP/HTTPS 走代理 (192.168.1.213:7890)
   - BT/Tracker 直连
4. **性能优化**:
   - 下载不限速
   - 磁盘缓存 256MB
   - 强制加密

### 结果
- 下载速度: 0.4 MB/s → **3.71 MB/s** (9x 提升)
- DHT 节点: 274 → 437
- IPv6 端口可达

## 🎬 视频文件名修复

### 问题
- 视频文件名包含特殊字符（@、.com、.xyz、空格）
- Jellyfin 无法正确识别和播放

### 修复
- 重命名 20+ 个文件，移除特殊字符
- 提取番号作为文件名（如 `420HHL-152.mp4`）
- 修复后 122 个文件正常，9 个待处理

## 📋 待办事项

### 端口转发（需手动）
- 登录 Lucky (http://192.168.1.1:16601)
- 添加端口转发规则：
  - 外网端口: 52000
  - 内网 IP: 192.168.1.212
  - 内网端口: 52000
  - 协议: TCP+UDP

### 优化建议
1. 定期清理 preclean-trash
2. 监控 Tracker 状态
3. 考虑添加更多可靠的公共 Tracker
4. 定期备份 qBittorrent 配置

## 🔗 相关配置文件
- qBittorrent: /vol1/1000/docker/qbittorrent/config/
- JAVSP: /vol1/1000/docker/javsp/
- auto-javsp.sh: /vol1/1000/docker/javsp/auto-javsp.sh
- config.yml: /vol1/1000/docker/javsp/config/config.yml

## 📊 性能指标
| 项目 | 优化前 | 优化后 |
|------|--------|--------|
| 下载速度 | 0.4 MB/s | 3.71 MB/s |
| DHT 节点 | 274 | 437 |
| 广告文件 | 912MB | 已清理 |
| 端口状态 | 不可达 | IPv6 可达 |

---
*记录时间: 2026-06-02 22:50*

## 🎬 视频文件完整性检测与修复

### 问题
- 大量视频文件损坏（文件头全零）
- Jellyfin 播放报错"文件损坏或不完整"
- 损坏原因：下载未完成或硬盘写入失败

### 检测结果
- 扫描 145 个视频文件
- 发现 66 个损坏文件（文件头全零）
- 已删除所有损坏文件

### 修复后状态
- 正常视频文件：74 个
- 损坏文件：0 个
- 创建检测脚本：/vol1/1000/docker/javsp/check_videos.sh

### 损坏文件特征
- 文件头全是零字节
- 文件类型显示为 "data" 而非 "ISO Media"
- 通常是因为下载未完成或硬盘写入失败

### 预防措施
1. 定期运行检测脚本
2. 检查 qBittorrent 下载状态
3. 监控硬盘健康状况

---
*更新时间: 2026-06-02 23:00*

## 📥 下载任务修复与优化

### 问题
- 88 个 missingFiles 任务（文件丢失）
- 237 个 queuedDL 任务（排队中）
- 视频文件损坏导致播放失败

### 修复措施
1. **重新校验 missingFiles 任务**
   - 触发 qBittorrent 重新校验文件完整性
   - 88 个任务已重新校验

2. **强制开始 queuedDL 任务**
   - 强制开始 305 个排队任务
   - 分批处理避免过载

3. **创建自动化脚本**
   - `fix_downloads.sh`: 自动修复下载任务
   - `monitor_downloads.sh`: 下载状态监控
   - `auto-javsp.sh`: 集成下载修复逻辑

### 当前状态
- 下载速度: 2.00 MB/s
- 上传速度: 10.86 MB/s
- DHT 节点: 571
- 活跃下载: 10 个任务
- 强制下载: 18 个任务

### 自动化流程
每次刮削时自动：
1. 清理 preclean-trash 广告文件
2. 修复 missingFiles 任务
3. 强制开始 queuedDL 任务
4. 执行 JAVSP 刮削
5. 生成 Jellyfin 兼容别名

### 监控建议
1. 定期运行 `bash /vol1/1000/docker/javsp/monitor_downloads.sh`
2. 检查 qBittorrent WebUI: http://localhost:8086
3. 监控下载速度和任务状态

---
*更新时间: 2026-06-02 23:10*
