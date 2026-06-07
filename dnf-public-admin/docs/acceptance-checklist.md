# Acceptance Checklist

## Legacy compatibility

- [x] Old admin port `882` remains the production baseline.
- [x] Supervisor port `2000` remains documented.
- [x] Game login port `3000` remains documented.
- [x] llnut game databases are fixed in backend baseline metadata.
- [x] New preview deployment uses `18882/18883`, not `882`.

## Safety gates

- [x] Read-only adapter rejects `root`.
- [x] Read-only adapter rejects non-legacy game databases.
- [x] Schema validation endpoint exists.
- [x] GM write endpoints return `403` during read-only phase.
- [x] Activity toggle endpoint is dry-run only and guarded by MVP RBAC scope.
- [x] PVF grant planning is dry-run only.

## Current modules

- [x] Auth/RBAC demo skeleton.
- [x] Audit metadata and in-memory dry-run event recorder.
- [x] Account and character read-only repository boundary.
- [x] Activity list/calendar/native sync/dry-run toggle.
- [x] PVF search and grant planning dry-run.
- [x] Docker preview build for backend and frontend.
- [x] MVP RBAC scope guard for activity dry-run writes.

## Before production write enablement

- [ ] Inspect live 104 schema with read-only account.
- [ ] Validate inspected schema through `/api/v1/meta/llnut-schema/validate`.
- [ ] Compare account/character reads against old `882` backend.
- [ ] Enable persistent admin DB for RBAC/audit.
- [ ] Add audited write implementation and gray release.

## 数据库接线准备

- [x] 数据库 DSN 环境变量配置
- [x] OpenDB 函数实现
- [x] Repository 初始化接线
- [x] 只读数据库连接检查脚本
- [x] Schema 管道脚本（inspect -> validate）
- [x] 生产环境接入清单

## 待真实环境验证

- [ ] 在 104 创建只读账号 dnf_readonly
- [ ] 配置 LLNUT_MODE=live-readonly
- [ ] 运行 check-readonly-db.sh 验证连接
- [ ] 运行 schema-pipeline.sh 验证 schema
- [ ] 对比新旧后台账号数量
- [ ] 对比新旧后台角色数量
- [ ] 确认 GM 写操作仍返回 403
- [ ] 确认活动开关仍为 dry-run
- [ ] 确认 PVF 发放仍为 dry-run
