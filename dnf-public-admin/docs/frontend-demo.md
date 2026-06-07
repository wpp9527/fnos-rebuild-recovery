# Frontend Demo Notes

当前前端已升级为可演示后台雏形：

- 左侧导航
- 模块状态卡片
- 权限矩阵表
- 审计动作表
- 管理员摘要卡

## 数据来源

优先读取：
- `GET /api/v1/meta/modules`
- `GET /api/v1/meta/audit-actions`
- `GET /api/v1/auth/me`

若本地未接通后端，则自动使用 fallback 演示数据，保证页面可展示。
