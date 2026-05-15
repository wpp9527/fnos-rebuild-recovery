# TrueNAS 配置级快速恢复备份一期设计稿（2026-04-25）

## 1. 目标

本期目标不是整机灾备，而是围绕**硬件损坏后的快速恢复**建立一套可持续运行的自动备份方案。

目标包括：
- 快速重建 PVE 宿主关键配置
- 快速恢复 fnOS VM 的服务编排与关键配置
- 快速恢复 OpenClaw 工作区、脚本、治理文档
- 快速找回 Docker、反代、网络、VM 清单与恢复步骤
- 将上述内容统一沉淀到 TrueNAS 中，形成稳定的恢复入口

本期明确不做：
- VM 整机镜像备份
- 媒体文件、下载数据等大体量业务数据备份
- 大型数据库原始数据热备或整库备份
- GitHub 远端备份链路的落地实现

设计原则：
- 优先恢复配置与结构，而不是恢复大数据本体
- 优先保证目录统一、说明统一、入口统一
- 失败时不破坏上一次成功备份
- 允许后续平滑升级到整机级或数据级备份

---

## 2. 已知环境与约束

### 2.1 基础拓扑
- PVE 是主服务器
- fnOS 是 PVE 内的虚拟机
- TrueNAS 也是 PVE 内的虚拟机
- 当前 OpenClaw 所在机器作为第一期的统一控制机与调度机

### 2.2 TrueNAS 接入现状
当前机器已经具备稳定可用的 NFS 挂载，且 `/mnt/nas/backup` 已在实际使用中。

已发现的挂载与目录条件：
- `/mnt/nas/backup`
- `/mnt/nas/media`
- `/mnt/nas/share`

这意味着第一期无需再引入额外的 SSH 推送到 TrueNAS 的复杂链路，而应直接使用现成的 NFS 挂载目录作为主备份落点。

### 2.3 PVE / fnOS 接入现状
当前控制机尚未发现可直接复用的 PVE / fnOS 免密 SSH 通道：
- `~/.ssh/config` 当前仅配置 GitHub
- 未发现 PVE / fnOS 现成 Host 配置
- 未发现用于 PVE / fnOS 配置采集的成熟备份脚本

因此本期设计采用：
- 备份框架、目录、调度、报告先落地
- PVE / fnOS 的 SSH 免密采集能力先作为预留接入位
- 不在本期设计确认阶段直接改生产 SSH 接入

---

## 3. 总体方案选择

### 3.1 备选方案

#### 方案 A：集中式控制机拉取备份
由当前 OpenClaw 所在机器统一调度：
- 本地采集 OpenClaw 资产
- 未来通过 SSH 拉取 PVE / fnOS 配置
- 本地整理标准快照
- 通过已挂载的 NFS 目录写入 TrueNAS

#### 方案 B：各节点本地导出，控制机汇总
- PVE 自己导出
- fnOS 自己导出
- 控制机只负责汇总与归档

#### 方案 C：各节点直接写入 TrueNAS
- PVE / fnOS 直接把导出结果写入 TrueNAS
- 控制机不做统一编排

### 3.2 选型结论
本期采用**方案 A：集中式控制机拉取备份**。

原因：
- 当前机器已经挂好 TrueNAS NFS，天然适合做统一发布端
- 目录、日志、恢复文档、版本索引更容易统一管理
- 最符合“硬件损坏后的快速恢复”目标
- 第一版复杂度最低，可控性最高
- 后续若要演进到 B，也可以在不改变目录规范的情况下平滑迁移

---

## 4. 备份总体架构

### 4.1 角色划分

#### 控制机
当前 OpenClaw 所在机器，职责：
- 统一调度备份任务
- 统一生成标准备份中间产物
- 统一写入 TrueNAS NFS 目录
- 统一生成版本索引、恢复指引、变更摘要

#### PVE 宿主
职责：
- 作为被采集对象，提供宿主配置、网络配置、存储配置、VM/CT 清单等恢复所需信息

#### fnOS VM
职责：
- 作为被采集对象，提供服务编排、脚本、网络、反代、配置模板与关键目录清单

#### TrueNAS
职责：
- 保存最新可恢复版本（latest）
- 保存历史快照（snapshots）
- 保存共享恢复资料（shared）

### 4.2 数据流
1. 控制机收集本地 OpenClaw 恢复资产
2. 控制机尝试采集 PVE 配置级资产
3. 控制机尝试采集 fnOS 配置级资产
4. 所有采集结果先进入控制机本地标准暂存目录
5. 控制机将成功收集的结果同步到 `/mnt/nas/backup`
6. 控制机更新 shared 下的索引、恢复文档与变更摘要
7. 按计划生成历史 snapshots，并执行保留策略

### 4.3 故障原则
- 任一采集端失败，不清空已有 latest
- 任一任务失败，都写入报告与摘要
- TrueNAS NFS 不可用时，不破坏本地暂存结果
- PVE / fnOS 未接入前，OpenClaw 备份链路仍可独立运行

---

## 5. 目录结构与职责

本期明确沿用现有 TrueNAS 备份树，不重新推翻。

### 5.1 PVE
路径：`/mnt/nas/backup/pve/`

职责：
- `latest/`：当前最新 PVE 配置导出
- `snapshots/<timestamp>/`：历史快照
- 后续可扩展 `reports/`

建议内容：
- `host-export/`
- `vm-inventory/`
- `network/`
- `storage/`
- `restore-notes.md`

### 5.2 fnOS
路径：`/mnt/nas/backup/fnos/`

职责：
- `latest/`：当前最新 fnOS 配置导出
- `snapshots/<timestamp>/`：历史快照
- 后续可扩展 `reports/`

建议内容：
- `services/`
- `docker/`
- `network/`
- `proxy/`
- `restore-notes.md`

### 5.3 OpenClaw
路径：`/mnt/nas/backup/services/openclaw/`

职责：
- `latest/`：OpenClaw workspace、脚本、文档
- `reports/`：执行报告、校验结果、失败摘要

建议内容：
- `workspace/`
- `docs/`
- `scripts/`
- `restore-notes.md`
- `backup-report-<timestamp>.md`

### 5.4 Shared
路径：`/mnt/nas/backup/shared/`

职责：
- `version-index/latest/`：当前版本索引
- `restore-guides/latest/`：恢复说明
- `change-log/latest/`：每次作业摘要
- `network-map/latest/`：主机/服务/路径映射

建议生成物：
- `backup_target_manifest.yaml`
- `restore-order.md`
- `host-service-map.yaml`
- `change-summary-<timestamp>.md`

### 5.5 目录设计原则
- `latest` 是最快恢复入口
- `snapshots` 负责历史回退
- `shared` 负责让人能快速理解和执行恢复
- 所有生成内容都应以“恢复视角”组织，而不是以采集脚本内部结构组织

---

## 6. 备份范围定义

### 6.1 OpenClaw 备份范围
纳入：
- 当前 workspace 中的文档、脚本、设计稿、治理资料
- 恢复有价值的 baseline / architecture / memory 文档
- 关键目录结构说明

排除：
- 运行态缓存
- 生成型 dream / temporary 产物
- 无恢复意义的锁文件、临时文件、运行状态文件
- 可再生成的派生重资产

目标：
- 在重建环境后，可以快速恢复 OpenClaw 的工作上下文、维护方法、关键脚本与设计依据

### 6.2 PVE 备份范围
纳入：
- `/etc/pve` 及其关键配置
- PVE 宿主网络配置
- 存储配置
- VM / CT 列表
- VM 基础参数与映射信息
- 恢复宿主与 VM 编排所需的说明文档

排除：
- VM 磁盘镜像
- 整机 raw/qcow2 大文件
- 宿主缓存、日志、临时文件

目标：
- 在 PVE 宿主损坏后，可以快速重建宿主配置与虚拟机清单结构

### 6.3 fnOS 备份范围
纳入：
- `/opt/fnos-media` 下关键服务脚本、说明、compose、模板
- Docker / Stack 配置
- 非敏感 `.env` 模板
- 反向代理与网络相关配置
- 恢复路径与目录结构清单

排除：
- 媒体数据
- 下载数据
- 大型业务数据库原始数据
- 临时缓存与日志

目标：
- 在 fnOS VM 丢失后，可以快速把服务编排和基础系统布局重建起来

### 6.4 Shared 生成范围
自动生成：
- 版本索引
- 本次作业报告
- 恢复顺序说明
- 主机/服务/路径映射
- 采集成功/失败摘要

---

## 7. 自动化作业拆分

本期不采用单个巨型脚本，而是拆分成职责清晰的多个任务。

### 7.1 collect_openclaw
职责：
- 收集 OpenClaw 本地可恢复资产
- 应用明确排除规则
- 输出到标准暂存目录

输入：
- 当前 workspace

输出：
- `staging/openclaw/...`

### 7.2 collect_pve
职责：
- 预留 SSH 接入位
- 未来通过 SSH 拉取 PVE 配置与 VM 清单
- 在接入未完成时，输出明确的“未接入”报告而不是静默失败

输入：
- PVE 目标地址、认证方式（后续补齐）

输出：
- `staging/pve/...`
- 或 `reports/pve-not-configured.md`

### 7.3 collect_fnos
职责：
- 预留 SSH 接入位
- 未来通过 SSH 拉取 fnOS 配置与关键目录说明
- 在接入未完成时，输出明确的“未接入”报告

输入：
- fnOS 目标地址、认证方式（后续补齐）

输出：
- `staging/fnos/...`
- 或 `reports/fnos-not-configured.md`

### 7.4 publish_latest
职责：
- 将当前 staging 的成功结果同步到 TrueNAS 对应 latest 路径
- 生成 shared 下的 version-index / restore-guides / change-log / network-map
- 保证失败时不破坏上一次成功版本

输入：
- `staging/*`

输出：
- `/mnt/nas/backup/.../latest`
- `/mnt/nas/backup/shared/...`

### 7.5 archive_snapshot
职责：
- 基于 staging 或 latest 生成按时间切片的 snapshots
- 清理超过保留策略的旧快照

输入：
- `latest` 或当前成功 staging

输出：
- `snapshots/<timestamp>/`

### 7.6 orchestrator
职责：
- 串联以上任务
- 控制执行顺序
- 统一记录结果
- 对失败做非破坏性处理

---

## 8. 调度策略

### 8.1 每日轻备份
执行内容：
- 收集 OpenClaw
- 检查 PVE / fnOS 是否已配置接入
- 若已配置则执行采集，未配置则写入状态报告
- 更新 latest
- 更新 shared 索引与恢复文档

目标：
- 维持一份最新可恢复配置状态
- 让恢复资料始终与当前环境接近同步

### 8.2 每周归档快照
执行内容：
- 从当前成功版本生成一份 snapshots 快照
- 执行保留策略
- 更新归档索引

建议初始保留策略：
- 最近 8~12 份周级快照

### 8.3 失败处理
- 任意对象采集失败，不删除旧 latest
- 失败应写入报告并进入 change-log
- 只有完整成功写入的对象才更新对应 latest
- shared 索引必须标记对象状态：成功 / 跳过 / 未配置 / 失败

---

## 9. 安全与接入原则

### 9.1 TrueNAS
- 作为配置级恢复资料的主存储端
- 不额外引入 GitHub 作为本期主链路
- NFS 挂载作为第一期唯一主发布路径

### 9.2 SSH 接入
- 本期设计允许未来使用 SSH 免密采集 PVE / fnOS
- 但在设计批准阶段不直接改生产 SSH
- 接入步骤作为单独文档与后续任务

### 9.3 secrets 原则
- 不把 secrets 明文推送到 GitHub
- 对 TrueNAS 中保存的配置应做风险分类
- 优先保留恢复必要的信息，避免过度复制敏感运行态

### 9.4 审计性
- 每次作业都应留下可读报告
- 恢复文档与版本索引必须与备份同步更新
- 任何失败都要能从 change-log 与 report 中直接看出原因

---

## 10. 恢复路径设计

### 10.1 推荐恢复顺序
1. 重建 PVE 宿主基础系统与网络/存储配置
2. 恢复 fnOS VM 与其服务编排框架
3. 恢复 OpenClaw、Docker、反代、网络辅助配置
4. 最后再处理业务数据层与非本期覆盖对象

### 10.2 latest 的角色
`latest` 应该始终满足以下要求：
- 不需要先理解历史演进，就能直接拿来恢复
- 目录命名清楚
- 恢复说明与目录内容对应
- 人在紧急情况下可以直接按说明操作

### 10.3 snapshots 的角色
`snapshots` 用于：
- 回看历史配置状态
- 在 latest 被错误更新后进行回退参考
- 追踪配置演进而不依赖 Git 历史

---

## 11. 第一阶段交付边界

本设计批准后，第一阶段实现应交付：
- 标准备份脚本结构
- OpenClaw 本地备份采集能力
- TrueNAS latest 同步能力
- snapshots 归档能力
- shared 索引 / 恢复说明 / 变更摘要生成功能
- PVE / fnOS 的 SSH 接入预留与“未接入”显式报告机制

本阶段不要求交付：
- PVE / fnOS 的最终 SSH 生产接入
- 整机镜像或大数据层备份
- GitHub 远端备份自动推送

---

## 12. 实施顺序建议

建议按以下顺序推进：
1. 固化目录规范与 shared 生成物格式
2. 实现 OpenClaw 本地 collect + publish_latest
3. 实现 archive_snapshot 与保留策略
4. 加入 PVE / fnOS 的“未接入但可报告”框架
5. 补齐 SSH 接入文档
6. 后续再接入 PVE / fnOS 实际采集

这样可以先让整条备份链路跑起来，再逐步扩展远端采集能力。

---

## 13. 成功标准

满足以下条件时，本期设计视为达标：
- 控制机可定时生成最新 OpenClaw 恢复资产到 TrueNAS
- TrueNAS 中存在清晰的 latest / snapshots / shared 结构
- 恢复说明可指导人工完成基础恢复
- PVE / fnOS 即使尚未接入，也会在报告中被明确标记状态
- 整套设计不依赖整机镜像，仍能支撑配置级快速恢复

---

## 14. 设计结论

本期采用：
**“控制机集中调度 + TrueNAS NFS 统一落盘 + 配置级快速恢复优先”的自动备份方案。**

该方案最适合当前环境现状：
- TrueNAS NFS 已可用
- 现有目录骨架已经存在
- PVE / fnOS 需要后续逐步接入
- 目标明确是硬件损坏后的快速恢复，而非整机灾备

下一步应进入实现计划阶段，先完成本地 OpenClaw → TrueNAS 的稳定备份链路，再补齐 PVE / fnOS 采集能力。
