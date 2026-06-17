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
