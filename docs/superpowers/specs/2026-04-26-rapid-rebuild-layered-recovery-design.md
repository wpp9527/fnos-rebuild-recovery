# 双入口分层快速重建恢复设计稿（2026-04-26）

## 1. 目标

本设计的目标不是做整机镜像式灾备，而是建立一套适用于 **PVE / fnOS / OpenClaw** 的“全新机器快速重建”恢复体系。

目标包括：
- 支持 **GitHub / NAS 双入口并列恢复**，任一入口可用时都能启动恢复
- GitHub 与 NAS **都保存同一套恢复脚本**
- 恢复目标默认是 **尽量全自动恢复到可运行架构**
- 以“结构、配置、脚本、清单、恢复程序”为核心资产
- 允许下载内容、媒体内容、固件本体、容器运行态重数据缺失
- 让恢复后的系统尽快回到“整体架构可运行、重数据可后补”的状态

本设计明确不追求：
- VM 整机镜像恢复
- 媒体库、下载历史、缓存、日志的全量恢复
- 固件、ISO、镜像层、历史归档的全量保留
- 将真实 secrets 暴露到 GitHub

设计原则：
- 保架构、保配置、保脚本、保清单、保恢复程序
- 不保可重新下载、可重新生成、体积过大的运行数据
- GitHub 只放模板与通用恢复逻辑，真实 secrets 仅保留在 NAS / 本地
- 每层可独立恢复，也可串联为全自动恢复流程
- 允许降级恢复，不允许静默失败

---

## 2. 总体架构

整套恢复体系拆成 6 层，每层只负责一个恢复目标。

### Layer 0 — Bootstrap
负责在新机器上拉起恢复工具链：
- 检测系统环境
- 安装基础依赖
- 拉取 GitHub 恢复仓库，或挂载/读取 NAS 恢复入口
- 判定恢复来源（GitHub / NAS / Hybrid）

### Layer 1 — PVE 配置恢复
负责恢复 PVE 宿主的配置骨架，而不是虚拟机磁盘数据：
- 宿主网络配置
- 存储定义
- VM/CT 清单
- VM/CT 配置参数
- 恢复顺序说明

### Layer 2 — fnOS 架构恢复
负责恢复 fnOS 的服务目录、Docker 运行骨架、路径与权限：
- compose / override / Dockerfile / requirements
- 服务目录结构
- 挂载点规划
- 权限与初始化逻辑

### Layer 3 — 服务编排恢复
负责把 Docker / compose 服务恢复到“能启动的架构状态”：
- 自动创建空目录 / 模板目录
- 执行初始化脚本
- 构建或拉起主要服务
- 校验关键依赖

### Layer 4 — OpenClaw 恢复
负责恢复 OpenClaw 的工作区、脚本、治理与自动化能力：
- workspace
- docs / specs / memory / governance
- backup / restore / automation scripts
- 必要运行配置模板

### Layer 5 — Secrets 注入
负责仅在 NAS / 本地注入真实敏感配置：
- GitHub 只保模板
- NAS / 本地保真实值
- 恢复程序自动检查缺失项
- 对必须依赖 secrets 的服务做阻断控制

总体原则：
- 恢复结构，不恢复重数据
- 每层可独立执行，也可全自动串行
- GitHub / NAS 双入口都能恢复
- secrets 与通用恢复程序彻底分离

---

## 3. 备份范围与排除规则

### 3.1 总原则
统一采用三条判定规则：

#### 规则 A：保“可重建架构”的东西
必须保：
- 配置文件
- 编排文件
- 构建脚本
- 初始化脚本
- 目录结构定义
- 服务清单
- 网络 / 存储 / 挂载关系
- 恢复说明
- 校验脚本

#### 规则 B：不保“大体积运行数据”
明确不保：
- 下载内容
- 媒体库
- 固件包
- 镜像缓存
- 容器运行态缓存
- 大型日志
- 可重新下载或重新生成的数据

#### 规则 C：保“如何恢复”，而不是保“恢复后的全部内容”
- 保 Dockerfile / compose / env 模板
- 不保容器卷里的重数据
- 保 VM 配置参数
- 不保 VM 磁盘内容
- 保目录骨架
- 不保目录里的下载物

### 3.2 PVE 备份范围
纳入：
- hostname / uname / version 信息
- `/etc/network/interfaces`
- 网桥 / bond / VLAN 关系
- `pvesm status`
- 存储池清单
- `qm list` / `pct list`
- 每台 VM/CT 的配置导出
- CPU / 内存 / 网卡 / 磁盘挂载参数
- 恢复顺序说明

排除：
- VM 磁盘镜像
- CT rootfs 重数据
- ISO 仓库
- 固件包
- 下载模板缓存
- 大体积日志

恢复目标：
- 能重建网络
- 能重建存储定义
- 能重新创建 VM/CT 壳子
- 能知道每台机器原本的资源、挂载、角色与网络关系

### 3.3 fnOS 备份范围
纳入：
- `manifests/`
- `bin/`
- 有恢复价值的 `reports/`
- `services/media-stack/`
- `services/docker-stack/`
- `services/easytier/`
- `services/openclaw-governance/`
- `services/openclaw-channels/`
- Docker 恢复资产：compose / Dockerfile / requirements / 初始化脚本 / 构建脚本 / override / config 模板
- 目录骨架定义
- 权限修复脚本
- 恢复说明

有条件纳入：
- 小而关键的本地状态文件
- service manifests
- 目录布局说明
- 渠道配置模板
- 恢复依赖清单

排除：
- 下载目录内容
- 媒体目录内容
- backup 大包
- cache
- logs
- runtime 临时文件
- 容器卷中的大体积业务数据
- 已拉取镜像层

恢复目标：
- 重建服务目录树
- 恢复 compose / Dockerfile / 初始化脚本
- 重新拉起容器架构
- 下载目录为空也不影响整体结构恢复

### 3.4 Docker / 服务层恢复规则
采用分级恢复：

#### 一级：关键架构目录
如配置目录、compose 挂载目录、脚本目录、secrets 占位目录、manifest 目录。
行为：
- 自动建目录
- 自动放 README / `.gitkeep` / 模板文件
- 自动修权限

#### 二级：普通运行目录
如 downloads / watch / temp / transcode / cache。
行为：
- 只确保路径存在
- 不灌内容
- 不复制旧数据

#### 三级：明确排除目录
如大型媒体库、固件仓、镜像缓存、历史归档。
行为：
- 在恢复报告中标记为后补项
- 不阻塞主系统恢复

### 3.5 OpenClaw 备份范围
纳入：
- workspace 中的文档、脚本、spec、memory、治理材料
- `scripts/backup/`
- `docs/`
- 恢复相关状态与模板
- 必要运行配置模板
- 恢复入口脚本

排除：
- cache
- 临时产物
- 运行态 staging
- 无恢复意义的中间文件
- 可再生成的日志 / 缓存

恢复目标：
- 快速还原 OpenClaw 的工作区、方法论、自动化脚本与治理上下文

### 3.6 Secrets 规则
GitHub 中只保留：
- `.env.example`
- 配置模板
- 缺失检查器
- secrets 清单说明
- 注入脚本框架

NAS / 本地可保留：
- 真实 `.env`
- 渠道 token
- API key
- 本地设备密钥
- SSH 凭据
- 恢复所需真实 secrets

判定标准：
- 决定结构能否重建
- 难以重新推导或重新编写
- 足够小，适合配置级快速恢复

---

## 4. 恢复入口与执行流程

### 4.1 双入口原则
支持三种模式：

#### GitHub-only
适用于 NAS 不可用时：
- 恢复通用脚本、目录、结构、模板
- 不能自动拿到本地真实 secrets
- 某些服务恢复到待注入状态

#### NAS-only
适用于 GitHub 不可用、局域网/NAS 可访问时：
- 恢复结构 + 本地专属配置 + secrets
- 更接近原环境快速重建

#### Hybrid（默认推荐）
行为：
1. 先从 GitHub 获取通用恢复程序
2. 再尝试挂载/读取 NAS
3. NAS 可用时用 NAS latest 覆盖或补足本地专属内容，并注入 secrets
4. NAS 不可用时退化为 GitHub-only，并输出缺失项清单

### 4.2 恢复入口文件结构
GitHub 和 NAS 都保存同一套入口：
- `restore/bootstrap.sh`
- `restore/restore-all.sh`
- `restore/lib/*.sh`
- `restore/layers/00-bootstrap.sh`
- `restore/layers/10-pve.sh`
- `restore/layers/20-fnos.sh`
- `restore/layers/30-services.sh`
- `restore/layers/40-openclaw.sh`
- `restore/layers/50-secrets.sh`
- `restore/checks/*.sh`
- `restore/templates/*`

### 4.3 自动判定逻辑
`bootstrap.sh` 负责：
- 探测系统类型、root 权限、网络、Git、NFS/NAS、目标目录可写性
- 根据用户参数或自动探测选择恢复来源
- 自动判定顺序：用户显式指定 > GitHub+NAS=hybrid > 仅 GitHub > 仅 NAS > 都不可用则阻断
- 先生成恢复计划，再在 `--yes` 模式下执行

### 4.4 分层执行流程
标准顺序：
1. bootstrap
2. restore-pve
3. restore-fnos
4. restore-services
5. restore-openclaw
6. restore-secrets
7. verify

### 4.5 执行模式
支持：
- `plan`：只探测并输出计划
- `apply`：按层执行恢复，但保留人工确认点
- `auto`：尽量全自动执行

### 4.6 阻断与降级规则
可降级：
- NAS 不可用
- 大数据目录缺失
- 非核心服务 secrets 缺失

必须阻断：
- 恢复脚本本体不可用
- 目标磁盘/目录不可写
- 关键宿主配置冲突
- 核心 secrets 缺失且服务无法安全启动
- 恢复来源完全不可访问

### 4.7 恢复完成输出
- 机器可读：`restore-result.json`
- 人类可读：`restore-summary.md`

---

## 5. 恢复脚本体系与目录设计

建议独立出 `restore/` 体系，而不是把恢复逻辑混入 backup 采集脚本。

### 5.1 顶层目录
- `restore/`
  - `bootstrap.sh`
  - `restore-all.sh`
  - `lib/`
  - `layers/`
  - `checks/`
  - `templates/`
  - `manifests/`
  - `plans/`
  - `reports/`

原则：
- 入口单一
- 层次分明
- GitHub / NAS 只是输入源差异，不是代码路径差异
- 检查与执行分离

### 5.2 入口脚本职责
`restore/bootstrap.sh`：
- 环境探测
- 恢复源判定
- 安装基础依赖
- 准备工作目录
- 下载或定位恢复包

`restore/restore-all.sh`：
- 解析参数
- 读取恢复上下文
- 串联各 layer
- 汇总结果并生成报告

### 5.3 `lib/` 公共能力
建议包含：
- `lib/log.sh`
- `lib/fs.sh`
- `lib/source.sh`
- `lib/check.sh`
- `lib/report.sh`
- `lib/secrets.sh`
- `lib/system.sh`

### 5.4 `layers/` 分层脚本
建议：
- `layers/00-bootstrap.sh`
- `layers/10-pve.sh`
- `layers/20-fnos.sh`
- `layers/30-services.sh`
- `layers/40-openclaw.sh`
- `layers/50-secrets.sh`
- `layers/90-verify.sh`

每层统一支持：
- `plan`
- `apply`
- `verify`

### 5.5 `checks/` 检查器体系
建议：
- `checks/check-host-prereqs.sh`
- `checks/check-nas-access.sh`
- `checks/check-github-access.sh`
- `checks/check-pve-assets.sh`
- `checks/check-fnos-assets.sh`
- `checks/check-openclaw-assets.sh`
- `checks/check-secrets.sh`
- `checks/check-docker-runtime.sh`

### 5.6 `templates/` 模板恢复资产
保存：
- 空目录占位模板
- `.env.example`
- compose 模板
- README / 目录说明
- 初始化占位文件
- 默认权限说明
- 目录分级规则模板

### 5.7 `manifests/` 机器可读恢复清单
建议至少有：
- `restore-layers.yaml`
- `source-map.yaml`
- `path-policy.yaml`
- `secrets-policy.yaml`
- `service-catalog.yaml`

### 5.8 `plans/` 与 `reports/`
恢复前：
- `plans/restore-plan-<timestamp>.md`
- `plans/restore-plan-<timestamp>.json`

恢复后：
- `reports/restore-summary-<timestamp>.md`
- `reports/restore-result-<timestamp>.json`
- `reports/verification-<timestamp>.md`

### 5.9 GitHub 与 NAS 同构原则
GitHub 保存：
- `restore/`
- `templates/`
- `manifests/`
- 示例配置
- 文档

NAS 保存：
- 同一套 `restore/` 镜像
- `shared/`
- `openclaw/latest`
- `pve/latest`
- `fnos/latest`
- 本地 secrets / 覆盖配置

原则：
- 脚本逻辑不因来源变化而变化
- source-map 决定输入优先级

---

## 6. PVE / fnOS / Docker / OpenClaw 的分层恢复细化

### 6.1 PVE 恢复目标
目标：
- 在全新 PVE 上恢复宿主配置、网络、存储定义、VM/CT 壳子与配置关系

自动恢复内容：
- 主机信息参考
- 网络配置模板与恢复脚本
- bridge / bond / VLAN 关系
- 存储池定义参考
- VM / CT 清单
- VM / CT 配置参数导出
- 重建命令草案
- 恢复顺序说明

不恢复：
- VM 磁盘数据
- CT 大体积 rootfs
- ISO / 固件仓库
- 下载缓存

风险边界：
- 改宿主网络、改存储定义属于高风险动作
- `plan` 必须先给预览
- `apply` 默认保留确认点
- `auto` 只对已验证的同构环境启用

### 6.2 fnOS 恢复目标
目标：
- 恢复 fnOS 的服务架构、目录骨架、编排方式、挂载关系与初始化能力

自动恢复内容：
- 根目录结构
- 服务目录结构
- compose / override / Dockerfile
- requirements / build scripts
- manifest / 配置模板
- 权限修复脚本
- 初始化脚本
- 目录级恢复说明

不恢复：
- 下载内容
- 媒体库
- 缓存
- 运行日志
- 历史容器卷大数据

### 6.3 Docker / 服务层恢复目标
目标：
- 把服务编排恢复到可启动状态，即使数据目录为空，也能形成完整运行架构

自动恢复内容：
- compose 项目
- Dockerfile 构建上下文
- 环境变量模板
- 初始化命令
- 服务顺序
- 挂载目录创建
- 空目录 / 模板目录生成
- 占位配置文件
- 容器启动前检查

服务分级：
- 核心服务：自动恢复结构，缺阻断级 secrets 时禁止启动
- 辅助服务：自动恢复结构，缺失可跳过
- 重数据服务：只恢复结构，不要求运行态完整

### 6.4 OpenClaw 恢复目标
目标：
- 作为恢复中枢、自动化中枢、治理中枢被优先恢复

自动恢复内容：
- workspace
- docs
- specs
- memory
- backup / restore scripts
- policy / governance 文档
- 运行配置模板
- 自动化入口

恢复后应达到：
- OpenClaw 能重新接管运维
- 文档与规则完整可追溯
- 备份 / 恢复 / 治理脚本可继续执行

### 6.5 分层依赖关系
固定顺序：
1. Bootstrap
2. PVE
3. fnOS
4. Docker / Services
5. OpenClaw
6. Secrets
7. Verify

### 6.6 自动化程度
- PVE：默认半自动
- fnOS：默认自动
- Docker / Services：默认自动 + 分级容错
- OpenClaw：默认自动
- Secrets：自动检查，按策略注入

### 6.7 “恢复成功”的定义
必须满足：
- PVE 配置清单完整
- fnOS 架构目录恢复完成
- compose / Dockerfile / 初始化脚本可用
- OpenClaw 控制面恢复完成
- 关键 secrets 检查结果明确
- 恢复报告生成完成

不要求立刻满足：
- 下载内容恢复
- 媒体库恢复
- 固件仓恢复
- 所有外围服务完全正常
- 所有历史缓存存在

---

## 7. Secrets / 模板 / 本地覆盖策略

### 7.1 总体原则
- GitHub 永不存真实 secrets
- NAS / 本地可存真实 secrets
- 恢复先落模板，再注入真实值
- 按服务分级，而不是一刀切

### 7.2 三层 secrets 模型
#### Layer S1：公开模板层
可放 GitHub / NAS：
- `.env.example`
- `.env.schema`
- 字段注释
- 默认占位值
- 示例配置
- 缺失检查规则

#### Layer S2：本地真实配置层
只放 NAS / 本地：
- 真实 `.env`
- API key
- token
- webhook secret
- SSH 凭据
- 设备绑定密钥

#### Layer S3：机器 / 环境覆盖层
只放 NAS / 本地：
- 机器专属路径
- 机器专属 IP / hostname
- 节点特定证书
- 环境特有 override

### 7.3 GitHub 应保存的内容
- 配置模板
- secrets 清单
- 检查脚本
- 注入框架
- `manifests/secrets-policy.yaml`

明确不保存：
- 真实 `.env`
- `auth.json`
- 渠道 token
- 实机 SSH key
- 设备配对密钥

### 7.4 NAS / 本地应保存的内容
建议单独规划受控 secrets 区：
- `shared/secrets/latest/`
- 或 `shared/local-overrides/latest/`

按角色分：
- `pve/`
- `fnos/`
- `openclaw/`
- `channels/`
- `shared/`

### 7.5 服务级分级策略
- 阻断级：缺失则禁止启动对应核心服务
- 延后级：不影响主架构恢复，但影响某些功能
- 可选级：只告警，不阻断

### 7.6 模板与真实值对应关系
- 模板：`.env.example`
- 本地真实值：`.env.local` 或 NAS secrets 文件
- 恢复目标：`.env`

恢复程序负责：
1. 读模板
2. 检查真实值是否存在
3. 合成目标配置
4. 校验必填项
5. 决定是否放行启动

### 7.7 本地覆盖优先级
优先级：
1. 模板默认值
2. 通用恢复模板
3. 服务级真实 secrets
4. 机器级 override
5. 本次恢复命令行显式参数

### 7.8 权限与暴露控制
- secrets 文件默认 `600`
- secrets 根目录不开放遍历
- 不和普通 latest 目录混在一起展示
- 日志与报告只显示字段状态，不显示真实值

### 7.9 Secrets 恢复流程
1. 落模板
2. 扫描真实 secrets 来源
3. 比对差异
4. 生成注入结果
5. 输出 `secrets-summary-<timestamp>.md` 与 `secrets-result-<timestamp>.json`

---

## 8. 校验、告警与运维闭环

### 8.1 三类校验
- 备份后校验（backup verify）
- 恢复前校验（restore preflight）
- 恢复后校验（restore verify）

### 8.2 备份后校验
检查：
- OpenClaw latest 是否完整
- PVE latest 是否包含关键清单
- fnOS latest 是否包含关键恢复资产且未误混入重数据
- shared 是否包含 manifest / restore guide / host-service-map / change summary

### 8.3 恢复前校验（Preflight）
检查项：
- 环境级：root、空间、可写性、依赖
- 来源级：GitHub / NAS 可访问性
- 资产级：PVE / fnOS / OpenClaw latest 与模板是否完整
- secrets 级：阻断级 / 延后级 / 可选级缺失情况

结果分级：
- `PASS`
- `WARN`
- `BLOCK`

### 8.4 恢复后校验（Verify）
- PVE：配置落位、重建命令草案、网络/存储恢复文档
- fnOS：关键目录、模板文件、权限、是否误复制重数据
- Docker：`docker compose config`、关键服务启动状态、缺 secrets 服务跳过逻辑
- OpenClaw：workspace、关键脚本、docs/spec/memory 完整性
- Secrets：阻断级满足情况、报告脱敏

### 8.5 校验输出格式
- 机器可读：`verification-result.json`
- 人类可读：`verification-summary.md`

### 8.6 告警机制
触发条件：
- latest 发布失败
- shared 索引未更新
- PVE / fnOS 关键清单缺失
- 混入大目录或运行态重数据
- snapshot 失败
- NFS 不可写
- preflight BLOCK
- 核心 layer apply 失败
- 核心服务启动失败

告警级别：
- `INFO`
- `WARN`
- `CRITICAL`

### 8.7 告警投递策略
一级：本地落盘
- `reports/`
- `change-log/`
- `verification-summary.md`
- 最近失败摘要

二级：渠道通知（后续接入）
- OpenClaw 消息通道
- Telegram / Discord / Feishu 等

### 8.8 运维闭环
日常闭环：
1. daily backup
2. backup verify
3. shared 状态更新
4. 异常告警

周期闭环：
1. weekly snapshot
2. snapshot verify
3. 抽样恢复演练
4. 更新恢复文档

演练闭环：
- 建议月度或双月恢复演练
- 至少跑到 `plan + verify`
- 理想情况下定期在干净环境中跑一次 `apply`

### 8.9 最低可接受标准
备份侧：
- latest 三目标齐
- shared 索引一致
- 无明显重数据混入
- weekly snapshot 可生成

恢复侧：
- bootstrap 能跑
- plan 能给出明确恢复路径
- PVE / fnOS / OpenClaw 三层能各自 verify
- secrets 缺失会明确阻断，不会静默失败

运维侧：
- 失败有报告
- 关键失败有告警
- 能看出当前是否具备恢复能力

---

## 9. 方案结论与下一步

本设计将现有备份体系从“导出一批文件”提升为“面向全新机器快速重建的恢复系统设计”。

一句话总结：
- **PVE 恢复定义与框架**
- **fnOS 恢复目录与编排骨架**
- **Docker 恢复可启动架构**
- **OpenClaw 恢复控制中枢**
- **Secrets 仅在 NAS / 本地注入**
- **GitHub / NAS 双入口并列，任一可恢复**
- **重数据后补，不阻塞主恢复**

推荐的下一阶段实施顺序：
1. 建立 `restore/` 目录骨架与 bootstrap / restore-all 入口
2. 落地 manifests / templates / checks 的最小可用版本
3. 实现 PVE / fnOS / OpenClaw 三层的 `plan/apply/verify`
4. 实现 secrets-policy 与本地 secrets 区规划
5. 接入 backup verify / restore preflight / restore verify
6. 增加渠道告警与定期恢复演练
