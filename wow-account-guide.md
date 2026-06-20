# 🎮 WoW 魔兽世界账号创建指南

## 📊 账号信息

### 已创建的账号
- **账号**: 1
- **密码**: 1
- **扩展包**: 经典版 (0)
- **状态**: 已创建

## 🔐 AzerothCore SRP6 认证说明

AzerothCore 使用 SRP6 (Secure Remote Password) 认证机制，这是一种安全的密码认证协议。密码不是以明文形式存储，而是使用 salt 和 verifier 字段。

### SRP6 认证特点
1. **安全性高**: 密码不以明文形式存储
2. **防重放攻击**: 每次登录都会生成新的会话密钥
3. **防中间人攻击**: 使用密码验证密钥交换

## 🛠️ 账号创建方法

### 方法 1：使用 SQL 直接创建（推荐）

```sql
-- 创建账号
INSERT INTO account (username, salt, verifier, email, reg_mail, expansion) 
VALUES (
    '用户名',
    UNHEX('00000000000000000000000000000000'),
    UNHEX('00000000000000000000000000000000'),
    'email@example.com',
    'email@example.com',
    0  -- 0=经典版, 1=燃烧的远征, 2=巫妖王之怒
);

-- 设置密码（需要使用 SRP6 工具）
UPDATE account 
SET 
    salt = UNHEX('SRP6_SALT'),
    verifier = UNHEX('SRP6_VERIFIER')
WHERE username = '用户名';
```

### 方法 2：使用 AzerothCore 工具

AzerothCore 提供了命令行工具来创建和管理账号：

```bash
# 启动 worldserver
/opt/wow-server/bin/worldserver

# 在 worldserver 命令行中执行
account create 用户名 密码
account set password 用户名 新密码 新密码
```

### 方法 3：使用神谕台

神谕台 (http://192.168.1.119:7860) 提供了 Web 界面来管理账号：

1. 访问 http://192.168.1.119:7860
2. 登录神谕台
3. 找到账号管理功能
4. 创建或修改账号

## 📝 账号管理命令

### 在 worldserver 命令行中使用

```bash
# 创建账号
account create 用户名 密码

# 设置密码
account set password 用户名 新密码 新密码

# 设置扩展包
account set addon 用户名 扩展包等级

# 设置 GM 级别
account set gmlevel 用户名 GM级别

# 查看账号信息
account info 用户名

# 锁定/解锁账号
account lock on 用户名
account lock off 用户名

# 封禁/解封账号
account ban 用户名 时间 原因
account unban 用户名
```

## 🎯 账号扩展包等级

- **0**: 经典版 (Classic)
- **1**: 燃烧的远征 (The Burning Crusade)
- **2**: 巫妖王之怒 (Wrath of the Lich King)

## 🔧 常见问题

### 问题 1：无法登录游戏
- 检查账号密码是否正确
- 确认游戏版本是否为 3.3.5a (12340)
- 检查服务器是否正常运行

### 问题 2：账号被锁定
- 使用 `account lock off 用户名` 解锁
- 检查是否有异常登录尝试

### 问题 3：忘记密码
- 使用 `account set password 用户名 新密码 新密码` 重置密码
- 或者使用 SQL 直接更新数据库

## 📞 技术支持

如需帮助，请联系管理员或查看 AzerothCore 官方文档：
- https://www.azerothcore.org/wiki/
- https://www.azerothcore.org/wiki/Account

## 🎮 游戏连接信息

- **服务器 Tailscale IP**: 100.115.4.113
- **游戏版本**: 3.3.5a (12340)
- **服务器名称**: AzerothCore
- **连接方式**: Tailscale VPN

## 📋 账号创建清单

1. ✅ 账号已创建：`1`
2. ✅ 密码已设置：`1`
3. ✅ 扩展包已设置：经典版 (0)
4. ✅ 服务器已配置：Tailscale IP 100.115.4.113
5. ✅ 游戏版本：3.3.5a (12340)

现在可以使用账号 `1` 和密码 `1` 登录游戏了！🎮
