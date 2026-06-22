# 🐳 Docker 服务清单

## 媒体栈 (/vol1/media-stack/)

| 服务 | 端口 | 说明 |
|------|------|------|
| qBittorrent | 8086/52000 | 下载器 (host 网络) |
| Jackett | 9117 | 索引器 (host 网络) |
| Radarr | 7878 | 电影管理 (host 网络) |
| Sonarr | 8989 | 电视剧管理 (host 网络) |
| Prowlarr | 9696 | 索引聚合 (host 网络) |
| Bazarr | 6767 | 字幕 (host 网络) |
| Seerr | 5055 | 请求管理 (host 网络) |
| Jellyfin | 8096 | 媒体服务器 (host 网络) |
| Halo | 8090 | 博客 |
| Homarr | 7575 | 仪表盘 (basic auth: bandas/wp930803) |
| Stash | 9999 | JAV 管理 (host 网络) |
| RSSHub | 1200 | RSS 聚合 (access key: wp930803) |
| feishu | host | 飞书频道 (本地构建) |
| cliproxyapi | host | AI 代理 |

### 启动顺序
qbit+jackett+prowlarr → radarr+sonarr → bazarr+seerr+homarr+jellyfin+halo+stash → cliproxyapi+feishu

### 管理脚本
`/vol1/media-stack/stack.sh` (start/stop/restart/status/logs)

## MDC 刮削器 (/vol1/1000/docker/mdc/)

| 配置 | 值 |
|------|-----|
| 镜像 | ghcr.io/vergilgao/mdc:latest |
| 媒体库 | /mnt/nas/media/jav → /data |
| 代理 | http://192.168.1.213:7890 |
| 自动脚本 | /vol1/1000/docker/mdc/auto-mdc.sh |
| Cron | 每 2 小时（偶数整点） |

### MDC 优化配置
- nfo_skip_days: 7（原 30）
- proxy timeout: 15s（原 60s）
- storyline 站点已关闭（iqq2 返回 500）

## Seerr 配置

| 配置项 | 值 |
|--------|-----|
| TMDb API Key | 24a163ac3b9b0466e547a4b3ec874654 |
| 代理 | 192.168.1.213:7890 |
| 登录 | bandas / wp930803 |

## qBittorrent 优化

| 项目 | 优化前 | 优化后 |
|------|--------|--------|
| 下载速度 | 0.4 MB/s | 3.71 MB/s |
| DHT 节点 | 274 | 571 |
| BT 端口 | 52345 (不可达) | 52000 (IPv6 可达) |
| 并发下载 | 20 | 8 |

### 配置要点
- HTTP/HTTPS 走代理 (192.168.1.213:7890)
- BT/Tracker 直连
- 磁盘缓存 256MB
- 强制加密
- 26 个可靠公共 Tracker

## 其他服务

| 服务 | 地址 | 说明 |
|------|------|------|
| Tailscale | Docker 容器 | network_mode: host, privileged |
| 1Panel | 192.168.1.212:40015 | 面板管理 |

## Docker 配置

| 项目 | 值 |
|------|-----|
| Data Root | /vol1/1000/docker/ |
| daemon.json | /etc/docker/daemon.json |
| Compose 路径 | /vol1/1000/docker/media-stack/ |
| FNOS Compass | /vol1/1000/docker/ (管理的容器) |

### 教训
- Docker data-root 迁移必须停 containerd 再停 docker
- `docker info --format '{{.DockerRootDir}}'` 确认实际 data-root
- 清理旧目录前确认无容器依赖
