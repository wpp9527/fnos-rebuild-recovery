# 🎮 WoW 魔兽世界 Tailscale 连接指南

## 📊 当前配置

### 服务器信息
- **服务器名称**: wow-server (VM105)
- **Tailscale IP**: 100.115.4.113
- **服务端口**: 
  - Auth Server: 3724 (TCP)
  - World Server: 8085 (TCP)
- **游戏版本**: 3.3.5a (12340)
- **数据库**: MySQL 8.0 (root/123)

### Tailscale 网络
- **FNOS**: 100.90.163.108
- **VM105 (wow-server)**: 100.115.4.113
- **Windows 设备**: 100.113.63.109

## 🌍 国外连接步骤

### 步骤 1：在国外设备上安装 Tailscale

1. 访问 https://tailscale.com/download
2. 下载并安装 Tailscale（支持 Windows, macOS, Linux, Android, iOS）
3. 启动 Tailscale 并使用相同的账号登录
4. 确保设备已连接到 Tailscale 网络

### 步骤 2：获取 Tailscale IP

在国外设备上打开命令行，运行：
```bash
tailscale ip -4
```
这将显示你的 Tailscale IP（类似 100.x.x.x）

### 步骤 3：配置 WoW 客户端

1. 找到 WoW 客户端目录
2. 编辑 `realmlist.wtf` 文件，内容为：
   ```
   set realmlist 100.115.4.113
   ```
3. 保存文件

### 步骤 4：启动游戏

1. 启动 WoW 客户端
2. 使用你的账号密码登录
3. 选择服务器 "AzerothCore"
4. 开始游戏！

## 🔧 故障排除

### 问题 1：无法连接到服务器
- 检查 Tailscale 是否已连接
- 确认国外设备的 Tailscale IP 是否正确
- 验证 `realmlist.wtf` 文件内容是否正确

### 问题 2：连接超时
- 检查防火墙设置
- 尝试临时关闭防火墙测试
- 确认 Tailscale 网络状态

### 问题 3：无法登录游戏
- 检查账号密码是否正确
- 确认游戏版本是否为 3.3.5a (12340)
- 查看服务器日志获取更多信息

## 📝 账号创建

如需创建游戏账号，请在 VM105 上运行：
```bash
ssh root@192.168.1.119
docker exec mysql8 mysql -u root -p123 acore_auth -e "INSERT INTO account (username, password, expansion) VALUES ('你的账号名', SHA2('你的密码', 256), 0);"
```

## 🎯 优势

1. **无需端口转发** - 不受 ISP 封锁影响
2. **安全加密** - 所有流量通过 VPN 加密
3. **全球可用** - 在任何有网络的地方都能连接
4. **简单配置** - 无需复杂设置

## 📞 支持

如需帮助，请联系管理员或查看 Tailscale 官方文档：
- https://tailscale.com/kb/
