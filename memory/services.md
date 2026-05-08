# 🔧 服务清单

## OpenClaw

- 配置文件: `/root/.openclaw/openclaw.json`
- Gateway 端口: 18789 (bind: lan)
- systemd 服务: user 级别，enabled
- 日志: `/tmp/openclaw/openclaw-YYYY-MM-DD.log`
- 外网访问: https://openclaw.19930901.xyz:5000

## Nginx (TRIM 系统)

- 主配置: `/usr/trim/nginx/conf/nginx.conf`
- 监听端口: 80→5666, 443→5667 (HTTPS)
- OpenClaw 反代: `/usr/trim/nginx/conf/conf.d/trim_openclaw.conf`
  - 通过 unix socket: `/var/apps/trim.openclaw/target/trim.openclaw.sock`

## Ollama

- 地址: http://127.0.0.1:11434
- Docker 容器运行
- 模型:
  - qwen3:4b — 8k ctx, 4k max output
  - qwen3-embedding:0.6b — 4k ctx, 仅嵌入
- ⚠️ 默认 contextWindow=200k 过大，需手动限制

## Docker

- 多个 compose 项目: cliproxyapi, ollama, feishu, media-stack, qq, rsshub
- 关键容器:
  - cli-proxy-api: 192.168.1.212:8317
  - halo-blog: 0.0.0.0:8090
  - homarr: 0.0.0.0:7575
  - jellyfin: 无端口映射 (通过 TRIM nginx)
