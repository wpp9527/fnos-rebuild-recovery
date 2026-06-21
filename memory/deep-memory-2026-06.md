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

---

## 系统配置

### 网络架构
- **主路由**: 192.168.1.1 (Lucky 反代, 端口 1234)
- **PVE**: 192.168.1.190
- **FNOS**: 192.168.1.212 (本机)
- **代理**: 192.168.1.213:7890
- **VM105**: 192.168.1.119 (WoW Linux 服务端)
- **VM106**: 192.168.1.187 (天蓝端 Win10)

### Tailscale 网络
- FNOS: 100.90.163.108
- VM105: 100.115.4.113
- VM106: 100.124.221.63
- junkking: 100.113.63.109

### OpenClaw 配置
- **Gateway 端口**: 18789
- **外网访问**: https://openclaw.19930901.xyz:1234
- **主会话模型**: xiaomimimo/mimo-v2.5-pro
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
| VM105 authserver | 3724 | ✅ |
| VM105 worldserver | 8085 | ✅ |
| VM106 authserver | 3724 | ✅ |
| VM106 worldserver | 8085 | ✅ |

---

## WoW 魔兽世界

### VM105 - Linux 标准端
- **编译方式**: Docker 容器 + Clang
- **版本**: AzerothCore rev. 8037e4c719d2
- **模块**: mod-playerbots (500 随机 bot), Beastmaster, AutoBalance
- **数据库**: MySQL 8.0 (Docker)
- **GM 账号**: admin / admin123

### VM106 - 天蓝定制版
- **版本**: AzerothCore rev. 333ae4556ea6+ 2026-04-02
- **模块**: BotAffinity, Beastmaster, MythicPlus, ChallengeModes, ItemUpgrade, Transmog
- **数据库**: MySQL 5.7.32
- **Bot 数量**: 800
- **特色功能**: 好感度/记忆/大秘境/挑战模式/装备升级/幻化
- **账号**: user1 / user2 (密码同名)
- **硬件**: 2核 / 8GB / 64GB

### 天蓝端模块详解
1. **BotAffinity** - 好感度系统
   - 提升方式: 组队/副本/聊天
   - 等级: 陌生→熟悉→亲密→挚友
   - 礼物系统: 好感度 ≥200 收到邮件礼物
2. **Beastmaster** - 宠物系统
   - 命令: `.beastmaster`
   - 默认猎人专用，可配置开放
3. **MythicPlus** - 大秘境
   - 默认关闭，需在配置中开启
   - 死亡扣 15 秒
4. **ChallengeModes** - 挑战模式
   - Hardcore (永久死亡)
   - SemiHardcore (死亡丢装备)
   - SelfCrafted (只能穿自制装备)
   - IronManMode (铁人模式)
5. **ItemUpgrade** - 装备升级
6. **Transmog** - 幻化系统
7. **超级炉石** - 增强版炉石
8. **DeepSeek AI** - AI 聊天 (需 API Key)

### 踩坑记录
1. **天蓝端高级功能需要天蓝 exe** - 好感度/记忆/大秘境是 C++ 实现
2. **VM105 Linux 版不支持天蓝端功能** - 只有标准 mod-playerbots
3. **4GB/6GB 内存不足** - MySQL InnoDB 缓冲池导致崩溃
4. **8GB 内存稳定运行** - 空闲约 5GB
5. **MSI 安装需要 iphlpsvc 服务** - IPv6 Helper Service
6. **Tailscale 手动安装** - 从 MSI 提取 exe 手动注册服务
7. **realmlist 需要修改** - 地址改为 Tailscale IP

---

## 近期修复

### 飞书渠道修复 (2026-06-12)
- 更新 observer.py 使用 Gateway 端点 (18789)
- 添加代理禁用补丁
- 使用 Gateway Token + openclaw 模型

### CPA 管理面板修复 (2026-06-11)
- 修复 Nginx 配置 (location = / 精确匹配根路径)
- 验证管理密钥 cpa2026admin

### 代理端口变更 (2026-06-11)
- 5000 → 1234
- 影响所有 *.19930901.xyz 域名

---

## 经验教训

### Nginx 配置
- 静态文件优先: `location = /` 精确匹配根路径
- API 代理: `location /v0/` 优先匹配

### 飞书渠道
- requests 库可能存在代理配置问题，需显式禁用代理
- Gateway 端点 (18789) 需要正确的 Token 认证

### 模型配置
- CPA 额度有限，gpt-5.5/gpt-5.4 经常限流
- Ollama qwen3:4b 在高负载时容易超时

### OpenClaw 配置
- gateway.controlUi.allowedOrigins 是受保护字段
- 反代环境需配置 trustedProxies

### Tailscale
- MSI 安装需要 iphlpsvc 服务 (IPv6 Helper)
- 可以从 MSI 提取 exe 手动注册服务
- realmlist 表地址需要改为 Tailscale IP

### Windows 服务
- `sc create` 语法: `binPath=` 后有空格
- 服务启动需要管理员权限
- SSH 会话可能没有完整权限

---

## 快速参考

### 服务地址
- OpenClaw: https://openclaw.19930901.xyz:1234
- CPA 面板: https://cpi.19930901.xyz:1234
- DNF 后台: http://192.168.1.204:18882
- VM105 WoW: 100.115.4.113:8085
- VM106 天蓝端: 100.124.221.63:8085

### 账号信息
- DNF 后台: admin / admin123
- MySQL 只读: dnf_readonly / dnf_readonly_2024
- Gateway Token: 8c96c8284dff43ca5c1b95fcfff2914a5e8a95838a5e7ba6
- CPA 管理密钥: cpa2026admin
- VM105 GM: admin / admin123
- VM106 天蓝端: user1 / user2

### SSH 连接
- PVE: root@192.168.1.190 (密码: wp930803)
- VM105: root@192.168.1.119 (密码: wp930803)
- VM106: Administrator@192.168.1.187 (密码: wp930803)

### 模型配置
- 主会话: xiaomimimo/mimo-v2.5-pro
- 飞书渠道: openclaw (自动路由)

---

*最后更新: 2026-06-22*
