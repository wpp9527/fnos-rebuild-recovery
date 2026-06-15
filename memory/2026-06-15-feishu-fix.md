# 飞书渠道修复记录 (2026-06-15)

## 问题
OpenClaw 升级到 2026.6.5 后飞书渠道完全失效：
1. CLI 路径 `/root/.openclaw-bin/openclaw` 已删除 → FileNotFoundError
2. Gateway API fallback 使用 `model: "openclaw"` → 400 Bad Request

## 根因
1. 旧版 OpenClaw 二进制 `/root/.openclaw-bin/` 被移除（升级到 npm 全局安装）
2. Gateway 的 `/v1/chat/completions` 端点只接受特殊路由模型名 `openclaw`，不接受 `provider/model` 格式

## 修复方案
### 容器内 observer.py（即时生效）
- `load_model_proxy_defaults()` 返回 `"http://127.0.0.1:18789", token, "openclaw"`
- CLI 路径改为 `/usr/bin/openclaw`（备用，主要走 Gateway API）

### 源文件 /vol1/1000/docker/media-stack/feishu/app/observer.py（持久化）
- 同步容器内修改

### Compose 文件 /vol1/1000/docker/media-stack/feishu/docker-compose.yml（持久化）
- `OPENCLAW_API_BASE=http://127.0.0.1:18789`（本地 Gateway）
- `OPENCLAW_API_KEY=8c96c8…7ba6`（Gateway Token）
- `OPENCLAW_MODEL=openclaw`（Gateway 特殊路由模型名）
- 移除无用的 `/root/.openclaw-bin` 卷挂载

## Gateway 模型路由机制
- `model: "openclaw"` → 使用 agents.defaults.model.primary（当前为 xiaomimimo/mimo-v2.5-pro）
- `model: "openclaw/<agentId>"` → 使用指定 agent 的模型配置
- 不接受 `provider/model` 格式，返回 400 错误

## 验证
- 飞书 WebSocket 连接正常（ping/pong）
- 用户消息成功处理并回复
- 当前使用 CPA GPT-5.5 Pro 模型（通过 Gateway 路由）
