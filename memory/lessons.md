# 📝 踩坑记录

## OpenClaw 配置

- **gateway.controlUi.allowedOrigins** 是受保护字段，`config.patch` 无法修改，必须直接编辑 `openclaw.json`
- **Ollama 模型 contextWindow 默认 200k**，4b 小模型根本跑不动，必须手动限制到 8k
- **反代环境需配置 trustedProxies**，否则 WebSocket 连接被识别为远程，日志会报警告
- **设备配对请求**存储在 `/root/.openclaw/devices/pending.json`，可通过修改文件 + 重启来批准

## 网络架构

- TRIM 系统的 nginx 配置在 `/usr/trim/nginx/`，不是 `/etc/nginx/`
- TRIM nginx HTTPS 端口是 5666/5667，不是 443
- 外网 5000 端口由 Lucky (主路由) 反代到内网各服务

## 模型

- CPA 额度有限，gpt-5.5/gpt-5.4 经常限流
- Ollama qwen3:4b 在高负载（load>8）时容易超时，需等负载下降
- 飞书渠道使用 openclaw 模型可自动路由到主会话模型

## 飞书渠道

- 飞书 observer 容器使用 host 网络，可直接访问宿主机端口
- requests 库可能存在代理配置问题，需显式禁用代理
- Gateway 端点 (18789) 需要正确的 Token 认证
- openclaw 模型会自动路由到配置的 primary 模型

## Nginx 代理

- 静态文件优先：`location = /` 精确匹配根路径
- API 代理：`location /v0/` 优先匹配
- try_files 会先查找静态文件，找不到再代理到后端
- 管理面板 HTML 需要正确配置 __CPA_CONFIG__ 注入
