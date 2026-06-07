# 运维 Runbook

## 常用命令

- 初始化：`scripts/init.sh`
- 启动：`scripts/start.sh`
- 停止：`scripts/stop.sh`
- 重启：`scripts/restart.sh`
- 健康检查：`scripts/healthcheck.sh`
- 备份：`scripts/backup.sh`

## 变更规则

1. 修改端口前先确认旧后台入口是否仍依赖该端口。
2. 修改数据库参数前先确认 `dnf-public-admin` 的 llnut baseline 是否同步。
3. 任何涉及点券、邮件、活动开关的写操作，先备份，再灰度。
4. 新后台未完成验收前，不停用 `882` 旧后台。
