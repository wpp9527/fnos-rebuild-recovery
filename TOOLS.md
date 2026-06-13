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
- DNF 服务器: root@192.168.1.204 (密码: wp930803)
- DNF 服务器: root@192.168.1.204 (密码: wp930803)

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
- 外网域名: https://openclaw.19930901.xyz:1234
- 代理端口: 1234（原 5000，已变更）

## Auto-MDC 经验

- 首次执行被旧 MDC 容器阻塞，需先停止再执行脚本
- 代理在 192.168.1.213:7890，500 错误时会影响抓取

## 飞书渠道修复记录 (2026-06-13)

### 最新修复
- **问题**: observer.py fallback 到 CPA 外网代理，但 CPA 没有 `openclaw` 模型
- **修复**: 修改 `load_model_proxy_defaults()` 始终走本地 Gateway
- **关键**: Gateway 的 `openclaw` 模型别名正常工作

### 之前修复 (2026-06-12)
- **问题**: 使用旧代理端口 5000，requests 库超时
- **修复**: 更新 observer.py 使用 Gateway 端点 (18789)

### 关键配置
- 飞书容器: `feishu-observe`
- Observer 文件: `/app/observer.py`
- Gateway 端点: `http://127.0.0.1:18789`（本地）
- Gateway Token: `8c96c8284dff43ca5c1b95fcfff2914a5e8a95838a5e7ba6`
- 模型: `openclaw`（Gateway 别名）

### 防止复发
- 定期检查飞书容器日志
- 确保 observer.py 配置正确
- 监控 Gateway 端点可用性
