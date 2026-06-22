# 🎮 DNF 服务端

## 服务架构

| 服务 | 地址 | 说明 |
|------|------|------|
| 游戏服务器 | 192.168.1.204 | Docker 容器 game_siroco11/52 |
| 管理后台 v4 | 192.168.1.204:18885 | Python 单文件架构 (server.py + dashboard.html) |
| Gate Server | 192.168.1.204:5505 | 登录网关 (Rust) |
| MySQL | 172.18.0.2:3306 | dnf-llnut_dnf-1_1 容器内 |

## 数据库

| 项目 | 值 |
|------|-----|
| Root 密码 | 88888888 |
| 只读用户 | dnf_readonly / dnf_readonly_2024 |
| 数据库 | d_taiwan, taiwan_cain, taiwan_login, taiwan_cain_2nd, taiwan_billing |

### 关键表
- `d_taiwan.accounts` - 账号表
- `taiwan_cain.charac_info` - 角色信息
- `taiwan_cain_2nd.postal` - 邮件系统
- `taiwan_billing.cash_cera` - 点券余额
- `d_taiwan.member_punish_info` - 封禁信息

## Admin Pro v4 功能

| 功能 | API 端点 | 说明 |
|------|----------|------|
| 角色查询 | `/api/v1/charac` | 支持筛选分页 |
| 账号查询 | `/api/v1/account` | |
| 物品查询 | `/api/v1/pvf/items` | 8.4 万物品 |
| 技能查询 | `/api/v2/skill/by-job` | Big5 编码 |
| 怪物图鉴 | `/api/v2/monster/search` | |
| GM 工具 | `/api/v2/gm/*` | 发物/等级/金币/封禁/充值 |
| 邮件系统 | `/api/v2/mail/stats` | |
| 公告管理 | `/api/v2/gm/notice` | |
| 统计分析 | `/api/v2/stats/*` | |
| 数据自检 | `/api/v2/check/*` | |

### 技术架构
- 后端: Python HTTPServer (stdlib only)
- 前端: 单 HTML 文件 (深色主题)
- 数据库: pymysql + SSH 隧道 (latin1 编码)
- 编码: UTF-8/Big5/CP950 自动解码

### 编码说明

| 字段 | 编码 | 解码方式 |
|------|------|----------|
| 物品名称 | UTF-8 | `value.decode('utf-8')` |
| 技能描述 | Big5 | `value.decode('big5')` |
| 角色名称 | UTF-8 | `value.decode('utf-8')` |

### 登录信息
- admin_member 表密码格式未知（16 字符十六进制），非标准 MD5
- 内置账号 admin/admin123 可用

### 版本历史
- v3.0: 基础功能 (15 个 API)
- v3.1: 技能描述 Big5 解码、PVF 翻页
- v3.2: GM 管理功能
- v3.3: Vue.js + Element UI 前端
- v4.0: 单文件架构重构 (参考 edict 项目)

### GitHub
- 私有部署: wpp9527/dnf-private-deploy
- 公开后台: wpp9527/dnf-public-admin
- Admin v4: wpp9527/dnf-admin-v4

## Gate Server 配置

| 变量 | 说明 |
|------|------|
| GATE_AES_KEY | AES 通讯密钥（32 字节） |
| GATE_BIND_ADDRESS | 0.0.0.0:5505 |
| RSA_PRIVATE_KEY_PATH | /data/privatekey.pem |
| INITIAL_CERA | 新账号初始点券 (1000) |
| GAME_SERVER_IP | 游戏服务器 IP |
