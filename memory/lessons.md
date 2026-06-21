# 踩坑记录

## Tailscale 安装 (2026-06-22)
- **问题**: MSI 安装失败 (错误 1603)
- **原因**: `iphlpsvc` 服务 (IPv6 Helper) 被禁用
- **解决**: 启用 `iphlpsvc` 服务: `sc config iphlpsvc start= demand && sc start iphlpsvc`
- **备选**: 从 MSI 提取 exe 手动注册服务

## Windows 服务创建 (2026-06-22)
- **问题**: `sc create` 命令语法错误
- **原因**: `binPath=` 后需要空格
- **正确**: `sc create 服务名 binPath= C:\path\to\exe start= auto`

## SSH 会话权限 (2026-06-22)
- **问题**: MSI 安装在 SSH 会话中失败
- **原因**: SSH 会话没有完整管理员权限
- **解决**: 使用 `cmd /c` 或 PowerShell 执行

## AzerothCore 编译 (2026-06-19)
- **问题**: GCC/Clang 段错误
- **原因**: VM105 内存不足
- **解决**: 使用 Docker 容器编译

## MySQL 认证 (2026-06-19)
- **问题**: MySQL 使用 auth_socket 无法远程连接
- **原因**: 默认认证方式不支持密码登录
- **解决**: 修改为 mysql_native_password

## 配置文件路径 (2026-06-19)
- **问题**: 二进制文件硬编码了 `/azerothcore/env/dist/etc/` 路径
- **原因**: 编译时路径固定
- **解决**: 创建符号链接

## 飞书渠道 (2026-06-12)
- **问题**: ConnectionError 超时
- **原因**: requests 库代理配置问题
- **解决**: 显式禁用代理 + 使用 Gateway 端点

## CPA 面板 (2026-06-11)
- **问题**: 面板白屏
- **原因**: Nginx 配置错误
- **解决**: `location = /` 精确匹配根路径

## 代理端口 (2026-06-11)
- **问题**: 端口 5000 不可用
- **原因**: 端口冲突
- **解决**: 改用 1234 端口

## VMap 版本不匹配 (2026-06-19)
- **问题**: VMap height checking disabled
- **原因**: VMap 数据版本与代码不匹配
- **解决**: 禁用 VMap 功能

---

*最后更新: 2026-06-22*
