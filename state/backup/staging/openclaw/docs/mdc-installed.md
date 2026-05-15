# Movie Data Capture / MDC 安装记录

- 安装时间: 2026-05-09
- 用途: 自动扫描番号视频，匹配元数据，重命名/整理目录，下载 poster/thumb/extrafanart/NFO
- Compose 目录: `/vol1/1000/docker/mdc`
- 镜像: `ghcr.io/vergilgao/mdc:latest`
- 配置文件: `/vol1/1000/docker/mdc/config/mdc.ini`
- 媒体库挂载: `/mnt/nas/media/jav -> /data`
- 运行用户: `3000:3000`

## 当前关键配置

- `main_mode = 1`：刮削模式
- `auto_exit = 1`：跑完自动退出
- `jellyfin = 1`：Jellyfin 适配
- `success_output_folder = .`：成功输出到媒体库根目录 `/mnt/nas/media/jav` 下
- `failed_output_folder = failed`：失败输出到 `failed`
- `location_rule = number`
- `naming_rule = number+'-'+title`
- `image_naming_with_number = 1`
- 代理: `http://192.168.1.213:7890`

## 运行

注意：会对 `/mnt/nas/media/jav` 里的文件进行整理/移动/重命名，并写入图片和 NFO。

```bash
cd /vol1/1000/docker/mdc
./run-mdc.sh
```

或：

```bash
cd /vol1/1000/docker/mdc
docker compose run --rm mdc
```

## 测试

已用假文件 `MIFD-046.mp4` 跑通过，生成了：

- `mifd-046.mp4`
- `mifd-046-poster.jpg`
- `mifd-046-thumb.jpg`
- `mifd-046.nfo`

测试命令：

```bash
cd /vol1/1000/docker/mdc
./dry-run-test.sh
```

## 2026-05-09 调整

- `update_check = 0`：关闭启动时更新检查，减少代理/站点失败噪音
- `mapping_table_validity = 30`：映射表缓存 30 天
- 当前 cron: `*/30 * * * * /vol1/1000/docker/mdc/auto-mdc.sh >/dev/null 2>&1`，脚本会检测已有 MDC 在跑则跳过
