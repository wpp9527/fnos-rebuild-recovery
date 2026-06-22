# 📝 踩坑记录 & 经验教训

## 系统 & Docker

| 问题 | 根因 | 解决方案 |
|------|------|----------|
| Docker data-root 迁移失败 | 停 docker 顺序错误 | 必须先停 containerd 再停 docker |
| 1Panel 数据丢失 | 清理旧目录时误删 | 重建，数据迁到 /vol1/1000/1panel/ |
| FNOS Compass 容器位置 | 与手动 compose 路径不同 | Compass: /vol1/1000/docker/，手动: /var/lib/docker/ |
| NFS rsync 超时 | 小文件写入慢 + --delete 扫描 | timeout 120s → 600s |
| `while read` 子 shell 计数器 | 子 shell 变量不传回父 shell | 用管道或临时文件 |
| 僵尸 rclone 进程 | cloud_storage_dav 未回收 | 重启服务回收 |

## 网络 & 反代

| 问题 | 根因 | 解决方案 |
|------|------|----------|
| 代理端口变更 | 5000 → 1234 | 更新所有 *.19930901.xyz 配置 |
| 飞书渠道失效 | observer.py 用旧端口/旧 CLI | 改用 Gateway API (18789) + openclaw 模型 |
| CPA 400 错误 | Gateway 不接受 provider/model 格式 | 必须用 `openclaw` 特殊路由名 |
| Stash 反代安全拦截 | 公网访问触发保护 | 添加认证 + 删除 tripwire |
| qBittorrent 下载慢 | 端口 52345 被封 | 换 52000 + 配置 Tracker + 代理分离 |

## Nginx

| 问题 | 根因 | 解决方案 |
|------|------|----------|
| CPA 面板 404 | location 匹配优先级 | `location = /` 精确匹配根路径 |

## 编码

| 字段 | 编码 | 解码方式 |
|------|------|----------|
| DNF 物品名称 | UTF-8 | `value.decode('utf-8')` |
| DNF 技能描述 | Big5 | `value.decode('big5')` |
| DNF 角色名称 | UTF-8 | `value.decode('utf-8')` |

## WoW 服务端

| 问题 | 根因 | 解决方案 |
|------|------|----------|
| 编译 OOM | 15GB RAM 不够 -j2/-j4 | 改用 -j1 |
| debug 构建太大 | 17GB+ | 改用 Release 构建 |
| libmodules.a ar 失败 | 链接命令问题 | 手动执行 link.txt |
| creature 表 schema 变更 | id→id1/id2/id3 | 重建 acore_world |
| MySQL 认证失败 | auth_socket 默认 | 改为 mysql_native_password |
| 配置路径硬编码 | /azerothcore/env/dist/etc/ | 创建符号链接 |
| MSI 安装失败 1603 | iphlpsvc 服务被禁用 | 启用后安装成功 |
| 天蓝端功能不可用 | C++ 实现，Linux 版不支持 | 只能用 Windows 天蓝 exe |
| 4GB/6GB 内存不足 | MySQL InnoDB 缓冲池 | 升级到 8GB |

## MDC/JAV 刮削

| 问题 | 根因 | 解决方案 |
|------|------|----------|
| storyline 500 错误 | iqq2.xyz 站点故障 | 关闭 storyline 站点 |
| JavDB 返回 403 | 站点反爬 | 更新配置添加域名过滤 |
| 视频文件损坏 | 下载未完成/写入失败 | 检测脚本 + 删除损坏文件 |
| 文件名特殊字符 | @、.com、.xyz 等 | 批量重命名提取番号 |

## OpenClaw

| 问题 | 根因 | 解决方案 |
|------|------|----------|
| 重复安装警告 | 残留目录 | 清理 /usr/lib/node_modules/.openclaw-update-stage-* |
| 反代配置 | trustedProxies 未配置 | 添加 192.168.1.0/24 等 |
| Gateway controlUi | allowedOrigins 受保护 | 需要在配置中正确设置 |

## 模型 & API

| 问题 | 根因 | 解决方案 |
|------|------|----------|
| CPA 限流 | 额度有限 | fallback 到其他模型 |
| Ollama qwen3 超时 | context 过大 | 限制 context 为 8k |
| MiMo 401 | 间歇性认证问题 | 重启 Hermes gateway |
