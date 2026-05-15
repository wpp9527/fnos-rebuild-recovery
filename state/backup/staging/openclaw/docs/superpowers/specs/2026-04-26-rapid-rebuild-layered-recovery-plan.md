# 双入口分层快速重建恢复实施计划（2026-04-26）

关联设计稿：
- `docs/superpowers/specs/2026-04-26-rapid-rebuild-layered-recovery-design.md`

## 1. 目标

将“GitHub / NAS 双入口 + 分层快速重建恢复”设计，落地为一套可执行、可验证、可演练的恢复系统。

本计划优先完成：
- `restore/` 目录骨架与统一入口
- manifests / templates / checks 的最小可用版本
- PVE / fnOS / OpenClaw 三层恢复的 `plan/apply/verify`
- secrets 分级与本地 secrets 区规划
- backup verify / restore preflight / restore verify
- shared 索引与恢复结果报告闭环

本计划暂不覆盖：
- VM 磁盘数据恢复
- 媒体库 / 下载内容恢复
- 固件 / ISO / 镜像层恢复
- 所有外围服务一次性 100% 自动恢复

---

## 2. 实施策略

### 2.1 总体顺序
按“先恢复框架，再恢复层，再恢复校验”的顺序推进：
1. 建立 `restore/` 基础骨架
2. 固化 manifests / templates / checks
3. 打通 `bootstrap` + `restore-all`
4. 落地 PVE / fnOS / OpenClaw 三层 plan/apply/verify
5. 落地 secrets 分级与本地注入
6. 落地 backup verify / restore preflight / restore verify
7. 接入告警与恢复演练

### 2.2 验收原则
每阶段必须满足：
- 有明确可运行脚本入口
- 有对应测试或可重复验证步骤
- 有人类可读报告
- 有失败时不破坏上一版结果的保护逻辑

---

## 3. 阶段划分

## Phase 1：恢复系统骨架
目标：先把恢复系统的目录、入口、上下文和报告框架搭起来。

交付物：
- `restore/bootstrap.sh`
- `restore/restore-all.sh`
- `restore/lib/`
- `restore/layers/`
- `restore/checks/`
- `restore/templates/`
- `restore/manifests/`
- `restore/plans/`
- `restore/reports/`

实现要点：
- `bootstrap.sh` 只做探测、依赖准备、来源判定、上下文生成
- `restore-all.sh` 只做参数解析、顺序调度、汇总结果
- 所有 layer 都按 `plan / apply / verify` 统一接口预留
- 统一恢复上下文文件，如 `state/restore/context.env` 或 `state/restore/context.json`

完成标准：
- 能执行 `bash restore/bootstrap.sh plan`
- 能执行 `bash restore/restore-all.sh plan`
- 能生成空的或最小版 `restore-plan-*.md/json`
- 能生成最小版 `restore-summary-*.md/json`

建议测试：
- `test_restore_bootstrap_plan.sh`
- `test_restore_all_plan.sh`
- `test_restore_report_generation.sh`

---

## Phase 2：manifests / templates / checks 最小可用版
目标：把恢复规则从脚本硬编码中抽出来，形成最小策略层。

交付物：
- `restore/manifests/restore-layers.yaml`
- `restore/manifests/source-map.yaml`
- `restore/manifests/path-policy.yaml`
- `restore/manifests/secrets-policy.yaml`
- `restore/manifests/service-catalog.yaml`
- `restore/templates/...`
- `restore/checks/check-host-prereqs.sh`
- `restore/checks/check-nas-access.sh`
- `restore/checks/check-github-access.sh`
- `restore/checks/check-secrets.sh`

实现要点：
- source-map 定义 GitHub / NAS 优先级与 fallback
- path-policy 定义一级 / 二级 / 三级恢复目录
- secrets-policy 定义 blocking / deferred / optional
- service-catalog 先覆盖核心服务，不求一步到位
- templates 先提供空目录占位、env 模板、README 模板

完成标准：
- `restore-all plan` 能读 manifest 并输出层顺序
- 能区分 GitHub-only / NAS-only / Hybrid
- 能对缺失 secrets 给出分级结果

建议测试：
- `test_restore_source_selection.sh`
- `test_restore_path_policy.sh`
- `test_restore_secrets_policy.sh`

---

## Phase 3：Bootstrap 与来源选择打通
目标：让新机器能真正选择 GitHub / NAS / Hybrid 入口。

交付物：
- `bootstrap.sh` 的来源探测逻辑
- GitHub 源探测
- NAS 源探测
- hybrid 回退逻辑
- context 落盘

实现要点：
- 支持 `--source github|nas|hybrid`
- 未指定时自动探测
- 对 GitHub / NAS 不可达分别输出 WARN / BLOCK
- 将探测结果写入 context，避免后续 layer 再各自探测

完成标准：
- 三种来源模式都可生成计划
- 当其中一侧不可达时，系统能明确回退
- 都不可达时系统阻断

建议测试：
- `test_bootstrap_source_github_only.sh`
- `test_bootstrap_source_nas_only.sh`
- `test_bootstrap_source_hybrid_fallback.sh`

---

## Phase 4：PVE 恢复层落地
目标：先实现 PVE 的“定义与框架恢复”，而非数据恢复。

交付物：
- `restore/layers/10-pve.sh`
- `restore/checks/check-pve-assets.sh`
- PVE 恢复计划输出
- PVE verify 报告

实现要点：
- `plan`：检查 `pve/latest` 是否完整，输出宿主恢复计划
- `apply`：生成或落地网络/存储/VM-CT 配置恢复参考与命令草案
- `verify`：确认清单齐全、恢复参考文件就位
- 默认不直接强推高风险宿主变更，先以 plan / generate 为主

完成标准：
- `10-pve.sh plan` 可输出 PVE 恢复计划
- `10-pve.sh verify` 可判定 latest 是否可用于恢复
- 对缺失 VM/CT 配置导出时能给出清晰缺项

建议测试：
- `test_restore_pve_plan.sh`
- `test_restore_pve_verify.sh`

---

## Phase 5：fnOS 恢复层落地
目标：恢复 fnOS 的目录骨架、服务编排骨架与初始化能力。

交付物：
- `restore/layers/20-fnos.sh`
- `restore/checks/check-fnos-assets.sh`
- fnOS 路径恢复与权限修复逻辑
- 目录分级初始化模板

实现要点：
- 一级目录做模板初始化
- 二级目录只建空目录
- 三级目录只在报告中标记后补
- 读取 `path-policy.yaml` 驱动目录恢复
- 从 fnOS latest 与 templates 合并恢复骨架

完成标准：
- `20-fnos.sh plan` 给出目录与结构恢复计划
- `20-fnos.sh apply` 能在干净环境里创建骨架目录
- `20-fnos.sh verify` 能识别缺失模板、权限错误、路径漂移

建议测试：
- `test_restore_fnos_plan.sh`
- `test_restore_fnos_apply_path_policy.sh`
- `test_restore_fnos_verify.sh`

---

## Phase 6：Docker / 服务恢复层落地
目标：将服务恢复到“可启动架构”状态，而不是恢复数据。

交付物：
- `restore/layers/30-services.sh`
- `restore/checks/check-docker-runtime.sh`
- compose / Dockerfile / env 模板恢复逻辑
- 服务分级启动逻辑

实现要点：
- 核心服务：缺 blocking secrets 时阻断
- 辅助服务：缺失可跳过
- 重数据服务：只恢复结构，不要求启动成功
- 执行 `docker compose config` 作为核心 verify 项
- service-catalog 驱动恢复顺序

完成标准：
- `30-services.sh plan` 能输出服务恢复顺序
- `30-services.sh apply` 能生成可工作的 compose 骨架与目录
- `30-services.sh verify` 能跑 `docker compose config`

建议测试：
- `test_restore_services_plan.sh`
- `test_restore_services_compose_config.sh`
- `test_restore_services_skip_deferred.sh`

---

## Phase 7：OpenClaw 恢复层落地
目标：让 OpenClaw 恢复为控制中枢与自动化中枢。

交付物：
- `restore/layers/40-openclaw.sh`
- `restore/checks/check-openclaw-assets.sh`
- OpenClaw workspace / scripts / docs 恢复逻辑

实现要点：
- 恢复 workspace、docs、scripts、governance、memory
- 恢复 backup / restore 自动化入口
- 校验关键脚本是否可执行
- 确保恢复后能继续接手运维与备份任务

完成标准：
- `40-openclaw.sh plan` 能识别 OpenClaw latest 是否完整
- `40-openclaw.sh apply` 能恢复控制面骨架
- `40-openclaw.sh verify` 能确认关键脚本与目录齐全

建议测试：
- `test_restore_openclaw_plan.sh`
- `test_restore_openclaw_apply.sh`
- `test_restore_openclaw_verify.sh`

---

## Phase 8：Secrets 注入层落地
目标：让真实 secrets 只在 NAS / 本地注入，GitHub 只保模板。

交付物：
- `restore/layers/50-secrets.sh`
- 本地 secrets 区结构约定
- `.env.example -> real values -> target .env` 渲染逻辑
- secrets 报告输出

实现要点：
- 支持 blocking / deferred / optional 分级
- 支持模板 + 本地真实值 + 机器 override 合成目标 env
- 失败时输出字段级状态，不打印真实值
- 对必须依赖 secrets 的服务做阻断

完成标准：
- `50-secrets.sh plan` 能输出缺口
- `50-secrets.sh apply` 能安全生成目标 env
- `50-secrets.sh verify` 能输出脱敏的 secrets 状态报告

建议测试：
- `test_restore_secrets_render.sh`
- `test_restore_secrets_blocking.sh`
- `test_restore_secrets_redaction.sh`

---

## Phase 9：统一 Verify、报告与闭环
目标：把 backup verify / restore preflight / restore verify 连成闭环。

交付物：
- `restore/layers/90-verify.sh`
- `verification-result.json`
- `verification-summary.md`
- backup verify 脚本或现有链路增强

实现要点：
- 备份后自动检查 latest / shared 是否一致
- 恢复前 preflight 统一输出 PASS / WARN / BLOCK
- 恢复后 verify 统一汇总各 layer 结果
- 统一输出 JSON + Markdown

完成标准：
- daily / weekly 后可跑 backup verify
- restore plan 前可跑 preflight
- restore apply 后可跑 verify
- 结果能被人读，也能被后续告警逻辑消费

建议测试：
- `test_backup_verify_three_targets.sh`
- `test_restore_preflight_statuses.sh`
- `test_restore_verify_aggregation.sh`

---

## Phase 10：告警与演练
目标：让恢复能力变成长期可观测、可演练的运维机制。

交付物：
- 失败摘要输出
- 告警分级策略
- 可接 OpenClaw 渠道通知的告警入口
- 月度 / 双月恢复演练流程文档

实现要点：
- 失败分级：INFO / WARN / CRITICAL
- 至少先本地落盘，后续再推消息通道
- 将“恢复演练”纳入周期动作，而不是只在事故时使用
- 建议最少每月做一次 plan + verify 演练

完成标准：
- daily / weekly 失败可落盘摘要
- restore preflight / verify 失败可输出 CRITICAL
- 有恢复演练说明文档

建议测试：
- `test_alert_payload_redaction.sh`
- `test_restore_drill_report.sh`

---

## 4. 里程碑建议

### 里程碑 M1：恢复系统骨架成型
包含：Phase 1–3
结果：
- 可探测来源
- 可输出恢复计划
- 可生成统一报告

### 里程碑 M2：三层恢复最小可用
包含：Phase 4–7
结果：
- PVE / fnOS / OpenClaw 三层都有 plan/apply/verify
- fnOS 与 Docker 恢复开始具备“可运行架构”能力

### 里程碑 M3：secrets 与 verify 闭环成型
包含：Phase 8–9
结果：
- 真正具备可控恢复能力
- 缺 secrets 会明确阻断
- 备份后 / 恢复前 / 恢复后 都可验证

### 里程碑 M4：运维化与演练
包含：Phase 10
结果：
- 告警成型
- 恢复演练纳入周期机制

---

## 5. 风险与控制

### 风险 1：恢复脚本范围失控，滑向“全量数据迁移”
控制：
- 强制遵守 path-policy
- 对下载 / 媒体 / 固件 / cache 维持明确排除
- 所有新纳入项必须说明为什么属于“结构级恢复资产”

### 风险 2：PVE 恢复层误做高风险宿主变更
控制：
- PVE 默认以 plan / generate / verify 为主
- apply 默认保留确认点
- auto 模式只对已验证同构环境开启

### 风险 3：真实 secrets 泄露到 GitHub 或日志
控制：
- GitHub 永不存真实值
- 日志与报告只输出字段状态
- 渲染后立即修权限
- secrets 区单独规划，不混入普通 latest

### 风险 4：GitHub / NAS 双入口逻辑漂移
控制：
- 用 source-map 驱动，不写双套逻辑
- 两边保持同构目录
- 优先改 manifest / policy，而不是散改 shell

### 风险 5：恢复系统长期不演练，名义可恢复但实际不可恢复
控制：
- 建立 plan + verify 的周期演练
- 至少月度输出演练结果摘要

---

## 6. 推荐的首批实施顺序

如果按最短路径推进，建议先做：
1. Phase 1：恢复骨架
2. Phase 2：manifests / templates / checks
3. Phase 3：bootstrap 来源判定
4. Phase 5：fnOS 恢复层
5. Phase 7：OpenClaw 恢复层
6. Phase 8：secrets 注入层
7. Phase 9：verify 闭环
8. 最后再做 Phase 4：PVE 深化恢复层
9. Phase 10：告警与演练

原因：
- fnOS + OpenClaw 是当前最容易在本机验证的链路
- PVE 恢复风险更高，适合在恢复框架成熟后推进
- 这样更快得到一个可演示、可演练的最小恢复系统

---

## 7. 完成定义

本计划完成的标志不是“写了一堆脚本”，而是满足以下条件：
- 新机器可以通过 GitHub / NAS 任一入口启动恢复
- 恢复程序可以生成 plan / apply / verify 报告
- fnOS / OpenClaw 至少能恢复到“可运行架构”状态
- PVE 至少能恢复到“配置清单 + 重建参考”状态
- secrets 缺失会明确阻断，不会静默失败
- backup verify / restore preflight / restore verify 三环齐备
- 有演练机制证明这套系统不是纸面设计
