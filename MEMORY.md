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
- **VM105**: 192.168.1.119 (WoW Linux 标准端, Tailscale 100.115.4.113)
- **VM106**: 192.168.1.187 (天蓝端 Win10, Tailscale 100.124.221.63)
- **GitHub**: wpp9527 / 6 仓库（含 claw-code 100K+ stars）
- **DNF 后台 v4**: 单文件架构（server.py + dashboard.html），端口 18885
- **模型主力**: xiaomimimo/mimo-v2.5-pro
- **OpenClaw**: 端口 18789，外网 openclaw.19930901.xyz:1234

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

## WoW 魔兽世界服务端

### VM105 - Linux 标准端
- **地址**: 192.168.1.119 (Tailscale: 100.115.4.113)
- **版本**: AzerothCore rev. 8037e4c719d2
- **模块**: mod-playerbots (500 随机 bot), Beastmaster, AutoBalance
- **数据库**: MySQL 8.0 (Docker, 密码: 123)
- **GM**: admin / admin123
- **配置**: /opt/wow-server/etc/

### VM106 - 天蓝定制版
- **地址**: 192.168.1.187 (Tailscale: 100.124.221.63)
- **版本**: AzerothCore rev. 333ae4556ea6+ 2026-04-02
- **模块**: BotAffinity, Beastmaster, MythicPlus, ChallengeModes, ItemUpgrade, Transmog
- **数据库**: MySQL 5.7.32 (root/123)
- **Bot**: 800 个 AI 玩家
- **账号**: user1 / user2 (密码同名)
- **硬件**: 2核 / 8GB / 64GB
- **配置**: C:\azbotcore\configs\

### 天蓝端特色功能
1. **BotAffinity** - 好感度系统 (组队/副本/聊天提升)
2. **Beastmaster** - 宠物系统 (`.beastmaster`)
3. **MythicPlus** - 大秘境 (默认关闭)
4. **ChallengeModes** - 挑战模式 (Hardcore/IronMan等)
5. **ItemUpgrade** - 装备升级
6. **Transmog** - 幻化系统
7. **超级炉石** - 增强版炉石
8. **DeepSeek AI** - AI 聊天 (需 API Key)

### 关键发现
- **天蓝端高级功能需要天蓝 exe** - 好感度/记忆/大秘境是 C++ 实现
- **VM105 Linux 版不支持天蓝端功能** - 只有标准 mod-playerbots
- **8GB 内存稳定运行** - 4GB/6GB 不够

## Tailscale 网络

| 设备 | Tailscale IP | 系统 |
|------|-------------|------|
| FNOS | 100.90.163.108 | Linux |
| VM105 (WoW) | 100.115.4.113 | Linux |
| VM106 (天蓝端) | 100.124.221.63 | Windows |
| junkking | 100.113.63.109 | Windows |

## 近期重要修复

### 天蓝端迁移 (2026-06-22)
- NAS → VM106 完整迁移 (6.7GB)
- Tailscale 穿透配置 (iphlpsvc 服务问题)
- realmlist 修改为 Tailscale IP

### 飞书渠道修复 (2026-06-12)
- observer.py 使用 Gateway 端点 (18789)
- 代理禁用补丁 + Gateway Token

### CPA 管理面板修复 (2026-06-11)
- Nginx 配置修复
- 管理密钥: cpa2026admin

### 代理端口变更 (2026-06-11)
- 5000 → 1234
- 影响所有 *.19930901.xyz 域名

## SSH 连接

- PVE: root@192.168.1.190 (密码: wp930803)
- VM105: root@192.168.1.119 (密码: wp930803)
- VM106: Administrator@192.168.1.187 (密码: wp930803)
- DNF 服务器: root@192.168.1.204 (密码: wp930803)

## 快速参考

- **OpenClaw**: https://openclaw.19930901.xyz:1234
- **CPA 面板**: https://cpi.19930901.xyz:1234
- **DNF 后台**: http://192.168.1.204:18882
- **VM105 WoW**: 100.115.4.113:8085
- **VM106 天蓝端**: 100.124.221.63:8085
- **Gateway Token**: 8c96c8284dff43ca5c1b95fcfff2914a5e8a95838a5e7ba6

*最后更新: 2026-06-22*
