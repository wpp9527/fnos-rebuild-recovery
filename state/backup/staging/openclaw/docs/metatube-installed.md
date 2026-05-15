# MetaTube / 小姐姐刮削器安装记录

- 安装时间: 2026-05-09
- Compose 目录: `/vol1/1000/docker/metatube`
- 服务地址: `http://192.168.1.212:8081`
- 本机测试: `http://127.0.0.1:8081`
- 镜像: `ghcr.io/metatube-community/metatube-server:1.4.0`
- 数据库: `postgres:15-alpine`
- 数据目录: `/vol1/1000/docker/metatube/db`
- 配置文件: `/vol1/1000/docker/metatube/docker-compose.yml`
- 环境变量/Token: `/vol1/1000/docker/metatube/.env`（600 权限）

## 管理命令

```bash
cd /vol1/1000/docker/metatube
docker compose ps
docker compose logs -f metatube
docker compose restart
docker compose pull && docker compose up -d
```

## Jellyfin 使用提示

在 Jellyfin 安装对应 MetaTube 插件后，服务器地址填：

```text
http://192.168.1.212:8081
```

Token 查看：

```bash
grep METATUBE_TOKEN /vol1/1000/docker/metatube/.env
```
