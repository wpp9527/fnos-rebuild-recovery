# 深度记忆摘要 - 2026年6月

## 重要项目

### DNF Admin Pro (192.168.1.204)
- **状态**: ✅ 已部署并运行稳定
- **访问**: http://192.168.1.204:18882
- **账号**: admin / admin123
- **后端**: Go 服务，端口 18882
- **前端**: Vue 3，端口 18883
- **数据库**: MySQL (172.18.0.2:3306)
  - 用户: dnf_readonly / dnf_readonly_2024
  - 数据库: d_taiwan, taiwan_cain, taiwan_login 等

#### 核心功能
1. ✅ 角色列表查询（支持筛选）
2. ✅ 角色详情查看（基础/战斗属性）
3. ✅ 装备栏查看（9/12 槽位有装备）
4. ✅ 背包查看（31 个物品，分 4 类）
5. ✅ 角色编辑（等级、HP、MP、攻击、防御、疲劳）
6. ✅ 登录认证（JWT）
7. ✅ PVF 物品查询（83977 个物品）

#### 技术细节
- 装备栏解析: equipslot blob (61 字节/槽位, item_no offset 2-3)
- 背包解析: inventory blob (zlib 压缩, 8 字节/物品)
- 数据库编码: charset=latin1 避免双重编码
- Unicode 解码: latin1 编码的 UTF-8 字符处理

#### 部署流程
1. 本地修改 → npm run build
2. scp dist/* 到服务器 frontend/assets/
3. 复制 index.html 到 frontend/dist/
4. 重启 Go 二进制 (kill + nohup)

---

## 系统配置

### 网络架构
- **主路由**: 192.168.1.1 (Lucky 反代, 端口 5000 → 1234)
- **PVE**: 192.168.1.190
- **FNOS**: 192.168.1.212 (本机)
- **代理**: 192.168.1.213:7890

### OpenClaw 配置
- **Gateway 端口**: 18789
- **外网访问**: https://openclaw.19930901.xyz:1234
- **主会话模型**: xiaomimimo/mimo-v2.5-pro (MiMo v2.5 Pro)
- **飞书渠道**: 使用 Gateway 端点 + openclaw 模型

### 服务清单
| 服务 | 端口 | 状态 |
|------|------|------|
| OpenClaw Gateway | 18789 | ✅ |
| CLIProxyAPI | 8317 | ✅ |
| CPA 面板 | 8320 | ✅ |
| DNF 后端 | 18882 | ✅ |
| DNF 前端 | 18883 | ✅ |
| qBittorrent | 52000 | ✅ |

---

## 近期修复

### 飞书渠道修复 (2026-06-12)
**问题**: ConnectionError(MaxRetryError('HTTPSConnectionPool(host=\'cpi.19930901.xyz\', port=5000)'))

**原因**:
1. 飞书 observer 使用旧代理端口 5000
2. requests 库代理配置问题导致超时

**修复**:
1. 更新 observer.py 使用 Gateway 端点 (18789)
2. 添加代理禁用补丁
3. 使用 Gateway Token + openclaw 模型

**关键配置**:
- 容器: feishu-observe
- 文件: /app/observer.py
- Gateway: http://192.168.1.212:18789
- Token: 8c96c8284dff43ca5c1b95fcfff2914a5e8a95838a5e7ba6
- 模型: openclaw (自动路由到主会话模型)

---

### CPA 管理面板修复 (2026-06-11)
**问题**: 面板白屏，无法访问

**原因**:
1. Nginx 配置错误，静态文件无法正确返回
2. 管理面板 HTML 的 __CPA_CONFIG__ 配置问题

**修复**:
1. 修复 Nginx 配置 (location = / 精确匹配根路径)
2. 确保静态文件优先，API 代理正确
3. 验证管理密钥 cpa2026admin

**关键配置**:
- 容器: cpa-panel (nginx:alpine)
- 端口: 8320
- 配置: /vol1/1000/docker/media-stack/cliproxyapi/nginx/nginx.conf
- 面板: management.html (1MB)
- API: /v0/management/config

---

### 代理端口变更 (2026-06-11)
**变更**: 5000 → 1234

**影响**:
- https://cpi.19930901.xyz:1234 (CLIProxyAPI)
- https://openclaw.19930901.xyz:1234 (OpenClaw)
- https://clawpanel.19930901.xyz:1234 (CPA 面板)

**已更新**:
- OpenClaw 配置 (openclaw.json)
- 飞书 observer (observer.py)
- Nginx 代理配置

---

## 经验教训

### Nginx 配置
- 静态文件优先: `location = /` 精确匹配根路径
- API 代理: `location /v0/` 优先匹配
- try_files 会先查找静态文件，找不到再代理到后端
- 管理面板 HTML 需要正确配置 __CPA_CONFIG__ 注入

### 飞书渠道
- 飞书 observer 容器使用 host 网络，可直接访问宿主机端口
- requests 库可能存在代理配置问题，需显式禁用代理
- Gateway 端点 (18789) 需要正确的 Token 认证
- openclaw 模型会自动路由到配置的 primary 模型

### 模型配置
- CPA 额度有限，gpt-5.5/gpt-5.4 经常限流
- Ollama qwen3:4b 在高负载时容易超时，需限制 contextWindow
- 飞书渠道使用 openclaw 模型可自动路由到主会话模型

### OpenClaw 配置
- gateway.controlUi.allowedOrigins 是受保护字段，需直接编辑 openclaw.json
- 反代环境需配置 trustedProxies
- Gateway Token 用于 API 认证

---

## 待优化项

### DNF Admin Pro
- 部分装备（如 36192）在 dnf_item_info 中无定义
- 可添加装备强化、增幅功能
- 可添加物品修改、删除功能
- 可添加数据统计功能

### 系统优化
- 定期清理归档旧日志文件
- 监控飞书渠道连接状态
- 优化模型选择策略（限流时自动 fallback）

---

## 快速参考

### 服务地址
- OpenClaw: https://openclaw.19930901.xyz:1234
- CPA 面板: https://cpi.19930901.xyz:1234
- DNF 后端: http://192.168.1.204:18882
- DNF 前端: http://192.168.1.204:18883

### 账号信息
- DNF 后台: admin / admin123
- MySQL 只读: dnf_readonly / dnf_readonly_2024
- Gateway Token: 8c96c8284dff43ca5c1b95fcfff2914a5e8a95838a5e7ba6
- CPA 管理密钥: cpa2026admin

### 模型配置
- 主会话: xiaomimimo/mimo-v2.5-pro
- 飞书渠道: openclaw (自动路由)
- Fallback: deepseek/deepseek-v4-pro, xiaomimimo/mimo-v2.5

---

*最后更新: 2026-06-12 00:35*
