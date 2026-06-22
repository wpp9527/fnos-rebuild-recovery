# 💾 备份系统

## 仓库
- GitHub: wpp9527/fnos-rebuild-recovery (私有)
- 路径: /root/.openclaw/workspace/fnos-rebuild-recovery/

## 备份架构

### NAS 备份 (/mnt/nas/backup/)
| 层级 | 内容 |
|------|------|
| container-volumes | 12+ 容器卷 |
| fnos | FNOS 配置 |
| pve | PVE 配置 |
| services | 服务数据 |
| openclaw | OpenClaw workspace |
| lxc-proxy | LXC 代理容器 |
| shared/secrets | 凭证文件 |

每层有 latest/ + .prev-latest-* 轮转 + snapshots/ 周归档

### 定时任务
| 任务 | 时间 | 说明 |
|------|------|------|
| 每日增量备份 | 02:00 | OpenClaw cron |
| 每周全量快照 | 周日 03:00 | |
| GitHub 备份 | 05:00 | backup-github.sh |
| TrueNAS 备份 | 周日 03:00 | backup-truenas.sh |

### 备份内容
- OpenClaw workspace
- PVE 配置 + VM 列表
- FNOS 本地配置
- 12+ Docker 容器卷
- Docker Compose 文件 (23 个)
- LXC 代理容器导出
- Secrets (fnos-media-stack.env, feishu.env)

## 踩坑记录
- rsync timeout 需要 600s（NFS 小文件写入慢）
- `git clone --depth 1` 避免代理超时
- 排除 state/backup/staging 临时文件
- `while read` 子 shell 计数器 bug
- FNOS_MEDIA_STACK 路径已更新为 /vol1/1000/docker/media-stack/

## 恢复方式
1. 完整恢复: bootstrap_fnos_stack.sh
2. 部分恢复: 按层级单独恢复
3. 离线恢复: README 中有说明
