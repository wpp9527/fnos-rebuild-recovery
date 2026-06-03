# TOOLS.md - 本地环境笔记

## GitHub

- 账号: wpp9527
- Token: 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
- 仓库: claude-code, claude-code-haha, claw-code, dnf-private-deploy, dnf-public-admin, fnos-rebuild-recovery(私有)

## 网络

- 主路由: 192.168.1.1 (Lucky 反代, 端口 5000)
- PVE: 192.168.1.190
- FNOS (本机): 192.168.1.212
- 代理容器: 192.168.1.213:7890

## SSH

- PVE: root@192.168.1.190
- 主路由: root@192.168.1.1

## Ollama

- 地址: http://127.0.0.1:11434
- 模型: qwen3:4b (8k ctx), qwen3-embedding:0.6b (4k ctx)
- 注意: 默认 context 过大导致响应超时，已手动限制

## Nginx

- TRIM 系统配置: /usr/trim/nginx/conf/
- OpenClaw 反代: /usr/trim/nginx/conf/conf.d/trim_openclaw.conf
- Lucky (主路由): 处理外网 5000 端口反代

## OpenClaw

- 配置文件: /root/.openclaw/openclaw.json
- Gateway 端口: 18789 (bind: lan)
- trustedProxies: 127.0.0.1, ::1, 192.168.1.0/24, 172.16.0.0/12
- 外网域名: https://openclaw.19930901.xyz:5000

## Auto-MDC 经验

- 首次执行被旧 MDC 容器阻塞，需先停止再执行脚本
- 代理在 192.168.1.213:7890，500 错误时会影响抓取
