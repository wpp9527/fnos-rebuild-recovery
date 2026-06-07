# dnf-private-deploy

私有部署仓，承载 `104 / dnf-llnut` 这套 DNF 服务端的脱敏部署工程、配置模板、运维脚本与新后台接线文档。

## 历史基线

- 现网主机：`104 / 192.168.1.204`
- Compose 项目：`dnf-llnut`
- 服务端镜像：`llnut/dnf:debian13-qf1031-latest`
- 旧后台：`dnf-console`
- 旧后台端口：`882`
- Supervisor 端口：`2000`
- 登录器/游戏入口端口：`3000`

## 目标

- 保持旧后台端口和旧游戏库一致，避免新旧后台数据分叉。
- 提供脱敏后的 compose / env / scripts 模板。
- 为 `dnf-public-admin` 提供明确接入边界。
- 先只读验证，再逐步开放受控写入。

## 目录

```text
compose/   docker compose 模板
env/       环境变量模板，真实密钥不要提交
scripts/   初始化、启停、备份、健康检查脚本
docs/      新后台接线与兼容性说明
ops/       运维 runbook
```

## 快速开始

1. 复制 `env/.env.example` 为实际环境文件，例如 `env/.env.local`。
2. 保持默认端口映射，除非有明确迁移计划。
3. 执行 `scripts/init.sh` 创建目录。
4. 执行 `scripts/healthcheck.sh` 校验 compose 模板。
5. 执行 `scripts/start.sh` 启动服务。

## 数据一致性原则

- 不创建新的游戏数据源作为事实来源。
- 不把 `d_taiwan` / `taiwan_*` / `taiwan_billing` 复制成另一套可写库。
- 新后台自己的管理员、RBAC、审计数据可以独立保存。
- 游戏账号、角色、点券、邮件、活动状态必须以现有 llnut 数据库为准。
