# MEMORY.md - 太子的长期记忆

> 详见 [memory/index.md](memory/index.md) 获取完整记忆导航

## 我是谁

- 名字：太子 👑
- 皇上的人：贴身 AI 侍从

## 重要偏好
- **必须用中文回复**，不要用英文
- **机器人项目分析后保存必须按项目来**

## 快速参考

- **网络**: 主路由 192.168.1.1 → PVE .190 → FNOS .212（本机）+ 代理 .213
- **GitHub**: wpp9527 / 6 仓库（含 claw-code 100K+ stars）
- **DNF Admin Pro 已部署到 192.168.1.204:18890**，全部 API 测试通过
- **模型主力**: cpa/gpt-5.5（常限流）→ fallback baidu/glm-5.1
- **OpenClaw**: 端口 18789，外网 openclaw.19930901.xyz:1234（代理端口已从 5000 改为 1234）

## 主题索引

| 主题 | 文件 |
|------|------|
| 网络架构 | [memory/network.md](memory/network.md) |
| 服务清单 | [memory/services.md](memory/services.md) |
| 模型配置 | [memory/models.md](memory/models.md) |
| 账号凭证 | [memory/credentials.md](memory/credentials.md) |
| GitHub | [memory/github.md](memory/github.md) |
| 踩坑记录 | [memory/lessons.md](memory/lessons.md) |
| 工程控制论 | [memory/engineering-cybernetics-qian-xuesen.md](memory/engineering-cybernetics-qian-xuesen.md) |
| 每日日志 | [memory/daily/](memory/daily/) |
| Hermes 学习 | [memory/learnings-from-hermes.md](memory/learnings-from-hermes.md) |
| 系统优化 | [memory/2026-06-02-system-optimization.md](memory/2026-06-02-system-optimization.md) |
| 深度记忆 | [memory/deep-memory-2026-06.md](memory/deep-memory-2026-06.md) |

## 近期重要修复 (2026-06-13)

### 飞书渠道修复 (最新)
- **问题**: observer.py fallback 到 CPA 外网代理，但 CPA 没有 `openclaw` 模型
- **修复**: 修改 `load_model_proxy_defaults()` 始终走本地 Gateway (127.0.0.1:18789)
- **配置**: Gateway 的 `openclaw` 模型别名正常工作
- **文件**: /app/observer.py (feishu-observe 容器)
- **验证**: WebSocket 连接正常，消息发送成功

### 飞书渠道修复 (2026-06-12)
- **问题**: 飞书 observer 使用旧代理端口 5000，requests 库超时
- **修复**: 更新 observer.py 使用 Gateway 端点 (18789)，添加代理禁用补丁
- **配置**: Gateway Token + openclaw 模型，与主会话模型一致
- **文件**: /app/observer.py (feishu-observe 容器)

### CPA 管理面板修复
- **问题**: 面板白屏，Nginx 配置错误
- **修复**: 修复 Nginx 配置，静态文件优先，API 代理正确
- **配置**: cpa-panel 容器 (端口 8320) → CLIProxyAPI (8317)
- **访问**: https://cpi.19930901.xyz:1234

### 代理端口变更
- **旧端口**: 5000
- **新端口**: 1234
- **影响**: 所有使用 cpi.19930901.xyz 的服务
- **已更新**: OpenClaw 配置、飞书 observer

## 深度记忆

详见 [memory/deep-memory-2026-06.md](memory/deep-memory-2026-06.md) 获取完整项目、配置和经验摘要。

## 快速参考

- **qBittorrent**: 端口 52000 (IPv6 可达)，代理 192.168.1.213:7890
- **JAVSP**: 每30分钟自动刮削，广告文件自动清理
- **视频文件**: 已修复特殊字符文件名
- **飞书渠道**: 使用本地 Gateway (127.0.0.1:18789) + openclaw 模型
- **CPA 面板**: 端口 8320，管理密钥 cpa2026admin
- **DNF 后台**: 192.168.1.204:18882，全部 API 测试通过，管理员密码: admin123
- **DNF 数据库**: 已采集账号、角色、物品、邮件、交易记录，贴吧帖子 104 条
- **贴吧抓取**: scripts/dnf-data-collector.sh 一键采集游戏+贴吧数据
- **自检系统**: scripts/dnf-self-check.sh 每日自检数据完整性
- **功能扩展**: data/dnf-features-20260613/feature_suggestions.md 详细方案
- **API 服务器**: dnf-admin-api/api_server.py 端口 18883，完整功能 API
- **定时任务**: 每小时采集、每天自检、每6小时抓贴吧、每周生成周报
- **RSSHub**: 127.0.0.1:1200，已运行 179 小时
