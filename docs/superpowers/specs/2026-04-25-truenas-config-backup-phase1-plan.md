# TrueNAS 配置级快速恢复备份一期实施计划（2026-04-25）

关联设计稿：
- `docs/superpowers/specs/2026-04-25-truenas-config-backup-phase1-design.md`

## 1. 目标

将一期设计落地为一套可运行、可观察、可逐步扩展的自动备份链路，优先完成：
- OpenClaw 本地资产到 TrueNAS 的稳定备份
- latest / snapshots / shared 的目录与生成逻辑
- PVE / fnOS 的“未接入但可报告”框架
- 后续 SSH 接入的预留能力

本计划不覆盖：
- PVE / fnOS 最终生产 SSH 接入
- 整机镜像与大数据层备份
- GitHub 远端自动推送

---

## 2. 实施阶段划分

### Phase 1：骨架与标准目录
目标：先把脚手架和统一入口搭好。

交付物：
- 备份脚本目录
- 本地 staging 目录规范
- 输出目录映射配置
- 统一入口 orchestrator 脚本

建议目录：
- `scripts/backup/orchestrator.sh`
- `scripts/backup/lib/common.sh`
- `scripts/backup/tasks/collect_openclaw.sh`
- `scripts/backup/tasks/collect_pve.sh`
- `scripts/backup/tasks/collect_fnos.sh`
- `scripts/backup/tasks/publish_latest.sh`
- `scripts/backup/tasks/archive_snapshot.sh`
- `state/backup/`
- `docs/restore/`（如后续需要本地恢复文档模板）

完成标准：
- 有统一入口脚本
- 能生成本地 staging 目录
- 能检测 `/mnt/nas/backup` 是否可用
- 能输出统一日志

---

### Phase 2：OpenClaw 本地采集
目标：先让最确定的一段链路跑通。

交付物：
- `collect_openclaw.sh`
- OpenClaw 采集清单与排除规则
- OpenClaw 恢复说明模板

实现要点：
- 复用当前仓库已有 `.gitignore` 的排除思路
- 明确排除：dream 产物、运行态状态、临时文件、缓存
- 保留：workspace 文档、脚本、spec、baseline、治理材料
- 输出到 `staging/openclaw/`

完成标准：
- 本地能稳定生成 OpenClaw 备份内容
- 结果可人工检查
- 恢复说明文件一并生成

---

### Phase 3：发布 latest + shared
目标：把 staging 可靠发布到 TrueNAS，并生成共享索引。

交付物：
- `publish_latest.sh`
- `backup_target_manifest.yaml`
- `restore-order.md`
- `host-service-map.yaml`
- `change-summary-<timestamp>.md`

实现要点：
- 只更新成功采集的对象
- 发布前先写入临时目录，再原子替换 latest（尽量避免半成品）
- shared 索引要记录对象状态：success / skipped / not-configured / failed
- 发布失败不得破坏旧 latest

完成标准：
- `/mnt/nas/backup/services/openclaw/latest/` 可更新
- `/mnt/nas/backup/shared/...` 自动生成
- 失败场景不会清空旧数据

---

### Phase 4：归档快照与保留策略
目标：给当前 latest 增加可回退历史。

交付物：
- `archive_snapshot.sh`
- 快照命名规则
- 保留策略实现

实现要点：
- 快照路径：`snapshots/<timestamp>/`
- 初始保留策略：保留最近 8~12 份周级快照
- 快照生成后写入归档索引
- 清理逻辑要保守，先按数量删，不做复杂时间分层

完成标准：
- 能从 latest 生成 snapshots
- 能清理旧快照
- 能在 change-log 中看到快照动作

---

### Phase 5：PVE / fnOS 未接入报告框架
目标：即使远端还没接入，也把整体作业链路跑通。

交付物：
- `collect_pve.sh` 占位实现
- `collect_fnos.sh` 占位实现
- “未接入”状态报告模板

实现要点：
- 若未配置远端地址 / key / host alias，则显式输出 not-configured
- 输出报告到 staging/reports 或 shared/change-log
- 不应以退出失败的方式中断整个备份流程

完成标准：
- orchestrator 运行后能明确展示 PVE / fnOS 当前状态
- OpenClaw 备份链路不受其影响

---

### Phase 6：调度与运维化
目标：将脚本接入定时作业并形成日常运行机制。

交付物：
- 每日轻备份定时任务
- 每周快照归档定时任务
- 手动执行说明
- 故障排查说明

实现要点：
- 日备份：collect + publish
- 周归档：archive + rotate
- 日志落地到可检查位置
- cron 中命令保持简单，复杂逻辑留在脚本内部

完成标准：
- 可手工执行成功
- 可被 cron 稳定调用
- 失败时有日志可查

---

## 3. 文件与模块建议

### 3.1 配置文件
建议增加一个集中配置文件，例如：
- `state/backup/config.env`

建议字段：
- `BACKUP_ROOT=/mnt/nas/backup`
- `STAGING_ROOT=/opt/fnos-media/services/openclaw/home/.openclaw/workspace/state/backup/staging`
- `RETENTION_WEEKLY=12`
- `PVE_SSH_HOST=`
- `FNOS_SSH_HOST=`
- `PVE_ENABLED=0`
- `FNOS_ENABLED=0`

目的：
- 后续接入远端时，不必改脚本主体
- 可明确区分“未启用”和“执行失败”

### 3.2 公共库
`common.sh` 建议承担：
- 时间戳生成
- 日志输出
- 目录准备
- 健康检查
- 原子发布辅助函数
- 状态汇总写入

### 3.3 输出报告
建议统一报告格式：
- Markdown 给人读
- YAML/JSON 给后续机器消费

最少应有：
- 人类摘要报告
- 机器可解析 manifest

---

## 4. 执行顺序

推荐严格按以下顺序实施：
1. 建目录与 orchestrator
2. 实现 `collect_openclaw`
3. 实现 `publish_latest`
4. 实现 shared 生成物
5. 实现 `archive_snapshot`
6. 实现 PVE / fnOS 占位采集
7. 接入 cron
8. 最后再做 SSH 接入准备文档

原因：
- 先把最确定、最可验证的链路跑通
- 再扩展远端对象
- 避免一开始就被 SSH 接入和生产环境权限卡住

---

## 5. 测试与验收

### 5.1 手动验收
每一阶段至少验证：
- 脚本能单独运行
- 输出目录结构正确
- 失败时日志可读
- 不会误删 TrueNAS 上的既有 latest

### 5.2 集成验收
最少覆盖：
- `/mnt/nas/backup` 不存在时的失败提示
- OpenClaw 正常收集并发布
- PVE / fnOS 未配置时标记为 not-configured
- snapshots 正常生成
- shared 文件自动更新

### 5.3 通过标准
满足以下条件即可以进入下一轮：
- 当前机器可每日自动备份 OpenClaw 到 TrueNAS
- 共享索引与恢复说明存在且可读
- weekly snapshots 可用
- PVE / fnOS 状态明确可见

---

## 6. 风险与缓解

### 风险 1：NFS 短暂不可用
缓解：
- 先在 staging 生成结果
- 发布失败不覆盖旧 latest
- 日志明确提示挂载异常

### 风险 2：误把运行态/脏文件纳入备份
缓解：
- 维护清晰排除规则
- 先从 OpenClaw 本地链路验证
- 每次发布前输出采集摘要

### 风险 3：PVE / fnOS 长期未接入导致“假完成”
缓解：
- shared 索引显式标红/标注 not-configured
- change-log 中记录未接入状态

### 风险 4：清理快照时误删
缓解：
- 第一版按保留数量做最保守删除
- 删除前写日志
- 仅删除明确匹配命名规则的快照目录

---

## 7. 下一轮实现优先级

若开始编码，建议优先级如下：
1. `common.sh`
2. `orchestrator.sh`
3. `collect_openclaw.sh`
4. `publish_latest.sh`
5. shared 生成逻辑
6. `archive_snapshot.sh`
7. `collect_pve.sh` / `collect_fnos.sh` 占位版
8. cron 接入

---

## 8. 计划结论

第一轮实现不追求“大而全”，而是优先把：
**“当前机器 → OpenClaw 可恢复资产 → TrueNAS latest/shared/snapshots”**
这条链路做稳。

只要这条主链路跑通，后续再把 PVE / fnOS 通过 SSH 接入补上，就能平滑升级成完整的一期方案。
