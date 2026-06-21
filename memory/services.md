# 服务清单

## DNF Admin v4 (192.168.1.204)

| 服务 | 说明 | 端口 | 状态 |
|------|------|------|------|
| DNF Admin v4 | 单文件 Python 后端 + Vue3 前端 | 18885 | ⚠️ 需启动 |
| DNF 游戏服务器 | dnf-llnut_dnf-1_1 | 5505,7001,7300,30011 | ✅ 运行中 |

### 架构

- **后端**: `server.py` (Python http.server + pymysql，1328 行)
- **前端**: `dashboard.html` (Vue3 + Element Plus + ECharts，2508 行)
- **数据库**: MySQL 直连，端口 3307，库 taiwan_cain/taiwan_login
- **GitHub**: https://github.com/wpp9527/dnf-admin-v4

### 功能模块

- 仪表盘、账号管理、角色管理、物品查询、怪物查询
- GM 功能（公告/物品/等级/金币/封禁）
- PVF 文件管理、服务端监控、活动管理、统计分析

### 数据源

- **MySQL**: 端口 3307，用户 root/88888888
- **PVF 物品数据**: gold.txt (83977 个物品)

---

## FNOS 媒体栈 (192.168.1.212)

全部 19 个容器运行中，详见 memory/2026-06-05.md。

---

## WoW 服务端

### VM105 - Linux 标准端 (192.168.1.119)

| 服务 | 说明 | 端口 | 状态 |
|------|------|------|------|
| authserver | AzerothCore 认证服务 | 3724 | ✅ 运行中 |
| worldserver | AzerothCore 游戏服务 | 8085 | ✅ 运行中 |
| MySQL 8.0 | 数据库 (Docker) | 3306 | ✅ 运行中 |
| Oracle Forge | AI 模型服务 | 7860 | ✅ 运行中 |

**特色**: mod-playerbots (500 随机 bot), Beastmaster, AutoBalance

### VM106 - 天蓝定制版 (192.168.1.187)

| 服务 | 说明 | 端口 | 状态 |
|------|------|------|------|
| authserver | 天蓝端认证服务 | 3724 | ✅ 运行中 |
| worldserver | 天蓝端游戏服务 | 8085 | ✅ 运行中 |
| MySQL 5.7.32 | 数据库 | 3306 | ✅ 运行中 |
| Tailscale | 穿透服务 | - | ✅ 已连接 |
| 800 Bot | AI 玩家 | - | ✅ 在线 |

**特色**: 好感度系统, 记忆系统, 大秘境, 挑战模式, 装备升级, 幻化, 超级炉石

**硬件**: 2核 / 8GB / 64GB

**连接**: `100.124.221.63:8085` (Tailscale)

---

## OpenClaw (192.168.1.212)

| 服务 | 说明 | 端口 | 状态 |
|------|------|------|------|
| OpenClaw Gateway | AI 网关 | 18789 | ✅ 运行中 |
| CLIProxyAPI | 代理 API | 8317 | ✅ 运行中 |
| CPA 面板 | 管理面板 | 8320 | ✅ 运行中 |

---

*最后更新: 2026-06-22*
