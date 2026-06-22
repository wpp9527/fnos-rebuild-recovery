# 🎮 WoW 魔兽世界服务端

## VM105 - Linux 标准端

| 项目 | 值 |
|------|-----|
| IP | 192.168.1.119 |
| Tailscale | 100.115.4.113 |
| 版本 | AzerothCore rev. 8037e4c719d2 |
| 编译方式 | Docker + Clang (mod-playerbots Playerbot 分支) |
| 模块 | mod-playerbots (500 随机 bot), Beastmaster, AutoBalance |
| 数据库 | MySQL 8.0 Docker (mysql8, root/123) |
| GM 账号 | admin / admin123 |
| 配置 | /opt/wow-server/etc/ |
| 数据 | /opt/wow-server/data/ (dbc, maps, mmaps, vmaps) |
| 客户端 | realmlist → 100.115.4.113 |

### 编译踩坑
- `-j2`/`-j4` OOM → 只能 `-j1`（15GB RAM 不够）
- debug 构建占 17GB+ → 改用 Release
- libmodules.a ar 失败 → 手动执行 link.txt
- creature 表 schema 变更：id→id1/id2/id3 → 需重建 acore_world
- playerbots 数据库需单独创建 acore_playerbots
- VMap 文件版本不匹配 → 已禁用

---

## VM106 - 天蓝定制版

| 项目 | 值 |
|------|-----|
| IP | 192.168.1.187 |
| Tailscale | 100.124.221.63 |
| 版本 | AzerothCore rev. 333ae4556ea6+ 2026-04-02 |
| 系统 | Windows 10 |
| 数据库 | MySQL 5.7.32 (root/123) |
| Bot 数量 | 800 |
| 账号 | user1 / user2 (密码同名) |
| 硬件 | 2核 / 8GB / 64GB |
| 配置 | C:\azbotcore\configs\ |
| 客户端 | realmlist → 100.124.221.63 |

### 天蓝端模块
1. **BotAffinity** - 好感度系统 (组队/副本/聊天提升，等级：陌生→熟悉→亲密→挚友)
2. **Beastmaster** - 宠物系统 (`.beastmaster`)
3. **MythicPlus** - 大秘境 (默认关闭)
4. **ChallengeModes** - 挑战模式 (Hardcore/SemiHardcore/SelfCrafted/IronMan)
5. **ItemUpgrade** - 装备升级
6. **Transmog** - 幻化系统
7. **超级炉石** - 增强版炉石
8. **DeepSeek AI** - AI 聊天 (需 API Key)

### 关键发现
- 天蓝端高级功能需要天蓝 exe（好感度/记忆/大秘境是 C++ 实现）
- VM105 Linux 版不支持天蓝端功能
- 8GB 内存稳定运行（空闲约 5GB），4GB/6GB 不够
- 迁移：NAS → VM106，通过 SMB 挂载复制 6.7GB

---

## Tailscale 连接

| 设备 | Tailscale IP | 系统 |
|------|-------------|------|
| FNOS | 100.90.163.108 | Linux |
| VM105 (WoW) | 100.115.4.113 | Linux |
| VM106 (天蓝端) | 100.124.221.63 | Windows |
| junkking | 100.113.63.109 | Windows |

### Tailscale 踩坑
- MSI 安装需要 iphlpsvc 服务（IPv6 Helper）
- 可从 MSI 提取 exe 手动注册服务
- realmlist 表地址需改为 Tailscale IP
